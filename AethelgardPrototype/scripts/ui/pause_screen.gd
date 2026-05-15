extends CanvasLayer

## Pause Screen — IDE-Style Interface
## Tabs: Assets (Inventory) | Functions (Abilities) | Ticket Backlog (Quests) | Map
## Themed as a developer IDE — because Kaelen IS a developer trapped in a game
## Toggle with Escape / pause_menu input action

# Tab containers
var tab_container: TabContainer = null
var header_label: Label = null
var corruption_bar: ProgressBar = null
var corruption_label: Label = null

# Tab panels
var assets_panel = null
var functions_panel = null
var charms_panel = null
var tickets_panel = null
var map_panel = null

# Assets tab elements
var inventory_list = null
var item_detail_label: Label = null

# Functions tab elements
var ability_list = null
var ability_detail: Label = null

# Charms tab elements
var charms_slots_container = null
var charms_unlocked_container = null
var charms_detail_label: Label = null

# Ticket Backlog elements
var active_tickets = null
var completed_tickets = null

# Map elements
var map_display: Label = null

var is_paused: bool = false
var pause_blocked: bool = false  # Block pausing during cutscenes

# ===========================
# Ability/Function definitions
# ===========================
var abilities = {
	"root_access": {
		"name": "Root Access [E]",
		"type": "CORE_FUNCTION",
		"desc": "Open an Inspector panel on a targeted HACKABLE entity. View and modify exposed variables.\nCost: +10-15% CORRUPTION per edit\nCooldown: None (but corruption is the real limiter)",
		"unlocked": true
	},
	"data_vision": {
		"name": "Data Vision [TAB]",
		"type": "UTILITY",
		"desc": "Toggle overlay revealing hidden object metadata, wireframe schematics, enemy parameters, and secret passages.\nCost: System Monitor attention increases while active\nDuration: Toggle on/off",
		"unlocked": false
	},
	"perfect_delete": {
		"name": "Perfect Delete [X]",
		"type": "COMBAT",
		"desc": "Execute a perfectly-timed strike that instantly removes a weakened entity from the scene graph.\nCost: 1 Perfect Delete charge (limited resource)\nCondition: Enemy must be below 20% HP",
		"unlocked": false
	},
	"garbage_collection": {
		"name": "Garbage Collection [K]",
		"type": "DEFENSE",
		"desc": "Defensive parry technique. 2-frame perfect parry window reflects projectiles and staggers melee attackers.\nCost: Stamina\nTiming: Must activate within 2 frames of incoming attack",
		"unlocked": false
	},
	"pogo_strike": {
		"name": "Pogo Strike [S in air]",
		"type": "COMBAT",
		"desc": "Downward aerial strike that bounces off enemies and certain surfaces. Resets dash and double-jump on successful hit.\nCost: None\nCondition: Must be airborne",
		"unlocked": false
	},
	"sprint_dash": {
		"name": "Sprint / Dash [SHIFT]",
		"type": "MOBILITY",
		"desc": "Hold to sprint (1.8x speed) in exploration. Tap in combat for a dash with 6 i-frames.\nCost: Stamina drain while sprinting\nCooldown: 0.5s between dashes",
		"unlocked": true
	},
}

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	layer = 110  # Above dialogue (100) but below scene transitions
	
	# Build UI programmatically (autoloaded .gd has no .tscn scene)
	_build_pause_ui()
	
	if OS.is_debug_build():
		print("[PAUSE] Pause screen system initialized")

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("pause_menu") and not pause_blocked:
		# Don't open pause while dialogue is active — ESC is used for dialogue skip
		if has_node("/root/DialogueManager") and DialogueManager.is_active:
			return
		# Safety: clear stale cutscene block if no cutscene is actually playing
		if get_meta("cutscene_blocked", false):
			var cm = get_node_or_null("/root/CutsceneManager")
			if cm == null or not cm.is_playing:
				set_meta("cutscene_blocked", false)
		if not get_meta("cutscene_blocked", false):
			toggle_pause()
			get_viewport().set_input_as_handled()

func toggle_pause() -> void:
	if not is_paused:
		# Trying to open — check UIStack
		if has_node("/root/UIStack") and not UIStack.try_open("pause_screen"):
			return
	else:
		# Closing
		if has_node("/root/UIStack"):
			UIStack.close("pause_screen")

	is_paused = !is_paused
	visible = is_paused
	get_tree().paused = is_paused
	
	if is_paused:
		_refresh_all_tabs()
		# Animate panel open — scale + fade for polish
		var panel_node = get_node_or_null("PanelContainer")
		if panel_node:
			panel_node.modulate.a = 0.0
			panel_node.scale = Vector2(0.95, 0.95)
			panel_node.pivot_offset = panel_node.size * 0.5
			var tween = create_tween().set_parallel(true)
			tween.tween_property(panel_node, "modulate:a", 1.0, 0.15).set_ease(Tween.EASE_OUT)
			tween.tween_property(panel_node, "scale", Vector2(1.0, 1.0), 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		# Grab focus on first tab for keyboard/gamepad navigation
		if tab_container:
			tab_container.focus_mode = Control.FOCUS_ALL
			tab_container.grab_focus()
		if has_node("/root/SFXManager"):
			SFXManager.play("ui_open")
		if OS.is_debug_build():
			print("[PAUSE] Game paused \u2014 IDE interface open")
	else:
		if has_node("/root/SFXManager"):
			SFXManager.play("ui_close")
		if OS.is_debug_build():
			print("[PAUSE] Game resumed")

func _refresh_all_tabs() -> void:
	## Refresh all tab contents with current game state
	_refresh_assets_tab()
	_refresh_functions_tab()
	_refresh_charms_tab()
	_refresh_tickets_tab()
	_refresh_map_tab()
	_refresh_header()

func _refresh_header() -> void:
	## Update the header bar with current corruption and location
	if header_label:
		var chapter = GameManager.current_chapter if GameManager.current_chapter else 1
		header_label.text = "AETHELGARD IDE v0.1.%d — Chapter %d" % [chapter, chapter]
	if corruption_bar:
		corruption_bar.value = GameManager.glitch_meter
	if corruption_label:
		corruption_label.text = "CORRUPTION: %.0f%%" % GameManager.glitch_meter

func _refresh_assets_tab() -> void:
	## Populate inventory/assets list with Use/Equip/Unequip buttons
	if not inventory_list:
		return
	
	# Clear existing
	for child in inventory_list.get_children():
		child.queue_free()
	
	# ── Equipped Items Section ──
	if has_node("/root/Inventory"):
		var has_equipped = false
		for slot_name in Inventory.equipment.keys():
			var eq_id = Inventory.equipment[slot_name]
			if eq_id and Inventory.ITEMS.has(eq_id):
				if not has_equipped:
					var eq_header = Label.new()
					eq_header.text = "─── EQUIPPED ───"
					eq_header.add_theme_font_size_override("font_size", 13)
					eq_header.add_theme_color_override("font_color", Color(0.3, 1.0, 0.5))
					inventory_list.add_child(eq_header)
					has_equipped = true
				
				var eq_data = Inventory.ITEMS[eq_id]
				var row = HBoxContainer.new()
				row.custom_minimum_size = Vector2(0, 32)
				inventory_list.add_child(row)
				
				var lbl = Button.new()
				lbl.text = "[%s] %s" % [slot_name.to_upper(), eq_data["name"]]
				lbl.alignment = HORIZONTAL_ALIGNMENT_LEFT
				lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
				lbl.pressed.connect(_on_item_selected.bind({
					"name": eq_data["name"],
					"type": "EQUIPPED (%s)" % slot_name.to_upper(),
					"desc": eq_data.get("description", "")
				}))
				row.add_child(lbl)
				
				var unequip_btn = Button.new()
				unequip_btn.text = "Unequip"
				unequip_btn.custom_minimum_size = Vector2(80, 28)
				unequip_btn.add_theme_font_size_override("font_size", 12)
				unequip_btn.add_theme_color_override("font_color", Color(1.0, 0.5, 0.5))
				var s_name = slot_name
				unequip_btn.pressed.connect(func(): Inventory.unequip_item(s_name); _refresh_assets_tab())
				row.add_child(unequip_btn)
	
	# ── Inventory Items Section ──
	if has_node("/root/Inventory"):
		var inv_summary = Inventory.get_inventory_summary()
		if inv_summary.size() > 0:
			var inv_header = Label.new()
			inv_header.text = "─── INVENTORY ───"
			inv_header.add_theme_font_size_override("font_size", 13)
			inv_header.add_theme_color_override("font_color", Color(0.7, 0.9, 1.0))
			inventory_list.add_child(inv_header)
		
		for inv_item in inv_summary:
			var row = HBoxContainer.new()
			row.custom_minimum_size = Vector2(0, 32)
			inventory_list.add_child(row)
			
			var btn = Button.new()
			btn.text = "[%s] %s x%d" % [inv_item["type"].to_upper(), inv_item["name"], inv_item["quantity"]]
			btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
			btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			btn.pressed.connect(_on_item_selected.bind({
				"name": inv_item["name"],
				"type": inv_item["type"].to_upper(),
				"desc": inv_item.get("description", ""),
				"id": inv_item.get("id", ""),
				"item_type": inv_item.get("type", "")
			}))
			row.add_child(btn)
			
			var item_type = inv_item.get("type", "")
			var item_id = inv_item.get("id", "")
			
			if item_type == "consumable":
				var use_btn = Button.new()
				use_btn.text = "Use"
				use_btn.custom_minimum_size = Vector2(60, 28)
				use_btn.add_theme_font_size_override("font_size", 12)
				use_btn.add_theme_color_override("font_color", Color(0.3, 1.0, 0.6))
				var use_id = item_id
				use_btn.pressed.connect(func():
					var ok = Inventory.use_item(use_id)
					if ok:
						_refresh_assets_tab()
						if item_detail_label:
							item_detail_label.text = "Used %s!" % inv_item["name"]
					else:
						if item_detail_label:
							item_detail_label.text = "Cannot use that now."
				)
				row.add_child(use_btn)
			
			elif item_type in ["weapon", "armor", "accessory"]:
				var equip_btn = Button.new()
				equip_btn.text = "Equip"
				equip_btn.custom_minimum_size = Vector2(60, 28)
				equip_btn.add_theme_font_size_override("font_size", 12)
				equip_btn.add_theme_color_override("font_color", Color(0.5, 0.8, 1.0))
				var eq_id = item_id
				var eq_slot = item_type
				equip_btn.pressed.connect(func():
					Inventory.equip_item(eq_id, eq_slot)
					_refresh_assets_tab()
				)
				row.add_child(equip_btn)
	
	# ── Stats Section ──
	var stats_header = Label.new()
	stats_header.text = "─── STATS ───"
	stats_header.add_theme_font_size_override("font_size", 13)
	stats_header.add_theme_color_override("font_color", Color(1.0, 0.85, 0.5))
	inventory_list.add_child(stats_header)
	
	# Story items
	if GameManager.story_flags.get("source_key_fragment_1", false):
		var frag_btn = Button.new()
		frag_btn.text = "[QUEST] Source_Key_Fragment_01"
		frag_btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		frag_btn.custom_minimum_size = Vector2(0, 28)
		frag_btn.pressed.connect(_on_item_selected.bind({"name": "Source_Key_Fragment_01", "type": "QUEST", "desc": "Fragment 1 of 7. Dropped by Tutorial Knight V2.1. Connects to... something."}))
		inventory_list.add_child(frag_btn)
	
	var gold = GameManager.player_stats.get("gold", 0)
	var level = GameManager.player_stats.get("level", 1)
	var xp = GameManager.player_stats.get("xp", 0)
	var mem_frags = GameManager.player_stats.get("memory_fragments", 0)
	var pd_charges = GameManager.perfect_delete_charges
	
	var stats_text = "Gold: %d  |  Level: %d  |  XP: %d\nMemory Fragments: %d  |  Perfect Deletes: %d" % [gold, level, xp, mem_frags, pd_charges]
	var stats_lbl = Label.new()
	stats_lbl.text = stats_text
	stats_lbl.add_theme_font_size_override("font_size", 12)
	stats_lbl.add_theme_color_override("font_color", Color(0.65, 0.65, 0.75))
	inventory_list.add_child(stats_lbl)

func _on_item_selected(item: Dictionary) -> void:
	if item_detail_label:
		item_detail_label.text = "%s\nType: %s\n\n%s" % [item["name"], item["type"], item["desc"]]

func _refresh_functions_tab() -> void:
	## Populate abilities/functions list
	if not ability_list:
		return
	
	for child in ability_list.get_children():
		child.queue_free()
	
	# Check unlock status from GameManager flags
	if GameManager.story_flags.get("ch1_data_vision_unlocked", false):
		abilities["data_vision"]["unlocked"] = true
	if GameManager.story_flags.get("root_access_unlocked", false):
		abilities["root_access"]["unlocked"] = true
		abilities["perfect_delete"]["unlocked"] = true
	if GameManager.story_flags.get("ch1_tutorial_knight_defeated", false):
		abilities["garbage_collection"]["unlocked"] = true
		abilities["pogo_strike"]["unlocked"] = true
	
	for key in abilities:
		var ability = abilities[key]
		var btn = Button.new()
		var status = "UNLOCKED" if ability["unlocked"] else "LOCKED"
		btn.text = "[%s] %s — %s" % [ability["type"], ability["name"], status]
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		btn.custom_minimum_size = Vector2(0, 32)
		btn.disabled = not ability["unlocked"]
		btn.pressed.connect(_on_ability_selected.bind(ability))
		ability_list.add_child(btn)

func _on_ability_selected(ability: Dictionary) -> void:
	if ability_detail:
		ability_detail.text = "%s\nType: %s\n\n%s" % [ability["name"], ability["type"], ability["desc"]]

# ==========================================================================
# CHARMS TAB — Equip / Unequip System (max 3 slots)
# ==========================================================================

func _refresh_charms_tab() -> void:
	## Populate charm equip UI: shows equipped slots + unlocked charms list
	if not charms_slots_container or not charms_unlocked_container:
		return
	
	# Clear existing UI
	for child in charms_slots_container.get_children():
		child.queue_free()
	for child in charms_unlocked_container.get_children():
		child.queue_free()
	
	# ── Equipped Slots ──
	var slots_header = Label.new()
	slots_header.text = "EQUIPPED CHARMS (%d / %d)" % [GameManager.equipped_charms.size(), GameManager.MAX_CHARM_SLOTS]
	slots_header.add_theme_font_size_override("font_size", 14)
	slots_header.add_theme_color_override("font_color", Color(1.0, 0.85, 0.2))
	charms_slots_container.add_child(slots_header)
	
	for i in range(GameManager.MAX_CHARM_SLOTS):
		var slot_row = HBoxContainer.new()
		slot_row.add_theme_constant_override("separation", 8)
		charms_slots_container.add_child(slot_row)
		
		var slot_label = Label.new()
		slot_label.custom_minimum_size = Vector2(300, 0)
		
		if i < GameManager.equipped_charms.size():
			var charm_id = GameManager.equipped_charms[i]
			var info = GameManager.CHARM_INFO.get(charm_id, {})
			var charm_name = info.get("name", charm_id)
			var icon = info.get("icon", "[?]")
			slot_label.text = "  Slot %d: %s %s" % [i + 1, icon, charm_name]
			slot_label.add_theme_color_override("font_color", Color(0.3, 1.0, 0.3))
			slot_label.add_theme_font_size_override("font_size", 13)
			slot_row.add_child(slot_label)
			
			# Unequip button
			var unequip_btn = Button.new()
			unequip_btn.text = "UNEQUIP"
			unequip_btn.custom_minimum_size = Vector2(90, 28)
			unequip_btn.add_theme_font_size_override("font_size", 12)
			unequip_btn.add_theme_color_override("font_color", Color(1.0, 0.5, 0.5))
			var btn_style = StyleBoxFlat.new()
			btn_style.bg_color = Color(0.15, 0.06, 0.06, 0.9)
			btn_style.border_color = Color(0.6, 0.2, 0.2, 0.6)
			btn_style.set_border_width_all(1)
			btn_style.set_corner_radius_all(3)
			btn_style.content_margin_left = 6
			btn_style.content_margin_right = 6
			unequip_btn.add_theme_stylebox_override("normal", btn_style)
			unequip_btn.pressed.connect(_on_charm_unequip.bind(charm_id))
			slot_row.add_child(unequip_btn)
		else:
			slot_label.text = "  Slot %d: [ EMPTY ]" % (i + 1)
			slot_label.add_theme_color_override("font_color", Color(0.4, 0.4, 0.4))
			slot_label.add_theme_font_size_override("font_size", 13)
			slot_row.add_child(slot_label)
	
	# Separator
	var sep = HSeparator.new()
	sep.add_theme_constant_override("separation", 8)
	charms_slots_container.add_child(sep)
	
	# ── Unlocked Charms List ──
	var unlocked_header = Label.new()
	unlocked_header.text = "UNLOCKED CHARMS"
	unlocked_header.add_theme_font_size_override("font_size", 14)
	unlocked_header.add_theme_color_override("font_color", Color(0.8, 0.65, 0.1))
	charms_unlocked_container.add_child(unlocked_header)
	
	var has_any = false
	for charm_id in GameManager.CHARM_INFO.keys():
		if not GameManager.is_charm_unlocked(charm_id):
			continue
		has_any = true
		
		var row = HBoxContainer.new()
		row.add_theme_constant_override("separation", 8)
		charms_unlocked_container.add_child(row)
		
		var info = GameManager.CHARM_INFO[charm_id]
		var is_equipped = GameManager.has_charm(charm_id)
		
		# Info column
		var info_vbox = VBoxContainer.new()
		info_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(info_vbox)
		
		var name_lbl = Label.new()
		name_lbl.text = "%s %s" % [info.get("icon", ""), info["name"]]
		name_lbl.add_theme_font_size_override("font_size", 13)
		if is_equipped:
			name_lbl.add_theme_color_override("font_color", Color(0.3, 1.0, 0.3))
		else:
			name_lbl.add_theme_color_override("font_color", Color(0.9, 0.8, 0.4))
		info_vbox.add_child(name_lbl)
		
		var desc_lbl = Label.new()
		desc_lbl.text = info["desc"]
		desc_lbl.add_theme_font_size_override("font_size", 12)
		desc_lbl.add_theme_color_override("font_color", Color(0.6, 0.6, 0.65))
		info_vbox.add_child(desc_lbl)
		
		# Stat preview — show concrete numbers
		var stat_text = _get_charm_stat_preview(charm_id)
		if stat_text != "":
			var stat_lbl = Label.new()
			stat_lbl.text = stat_text
			stat_lbl.add_theme_font_size_override("font_size", 12)
			if is_equipped:
				stat_lbl.add_theme_color_override("font_color", Color(0.4, 0.9, 0.5))
			else:
				stat_lbl.add_theme_color_override("font_color", Color(0.7, 0.7, 0.3))
			info_vbox.add_child(stat_lbl)
		
		# Action button
		if is_equipped:
			var equipped_lbl = Label.new()
			equipped_lbl.text = "EQUIPPED"
			equipped_lbl.add_theme_font_size_override("font_size", 12)
			equipped_lbl.add_theme_color_override("font_color", Color(0.3, 0.8, 0.3))
			equipped_lbl.custom_minimum_size = Vector2(90, 28)
			equipped_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			equipped_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			row.add_child(equipped_lbl)
		else:
			var equip_btn = Button.new()
			var slots_full = GameManager.equipped_charms.size() >= GameManager.MAX_CHARM_SLOTS
			equip_btn.text = "EQUIP" if not slots_full else "FULL"
			equip_btn.disabled = slots_full
			equip_btn.custom_minimum_size = Vector2(90, 28)
			equip_btn.add_theme_font_size_override("font_size", 12)
			if slots_full:
				equip_btn.add_theme_color_override("font_color", Color(0.5, 0.4, 0.4))
			else:
				equip_btn.add_theme_color_override("font_color", Color(0.3, 1.0, 0.5))
			var btn_style2 = StyleBoxFlat.new()
			btn_style2.bg_color = Color(0.06, 0.12, 0.06, 0.9)
			btn_style2.border_color = Color(0.2, 0.6, 0.3, 0.6)
			btn_style2.set_border_width_all(1)
			btn_style2.set_corner_radius_all(3)
			btn_style2.content_margin_left = 6
			btn_style2.content_margin_right = 6
			equip_btn.add_theme_stylebox_override("normal", btn_style2)
			equip_btn.pressed.connect(_on_charm_equip.bind(charm_id))
			row.add_child(equip_btn)
	
	if not has_any:
		var empty_lbl = Label.new()
		empty_lbl.text = "  No charms unlocked yet.\n  Purchase charms from Nyx the Charm Dealer."
		empty_lbl.add_theme_font_size_override("font_size", 12)
		empty_lbl.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
		charms_unlocked_container.add_child(empty_lbl)
	
	# Detail hint
	if charms_detail_label:
		charms_detail_label.text = "Equip up to %d charms at a time. Effects apply in combat.\nBuy more charms from Nyx the Charm Dealer in town." % GameManager.MAX_CHARM_SLOTS

func _on_charm_equip(charm_id: String) -> void:
	## Handle equip button pressed
	var success = GameManager.equip_charm(charm_id)
	if success:
		if has_node("/root/SFXManager"):
			SFXManager.play("item_equip")
		if charms_detail_label:
			var info = GameManager.CHARM_INFO.get(charm_id, {})
			charms_detail_label.text = "Equipped: %s" % info.get("name", charm_id)
	else:
		# PASS 36 FIX: Feedback when equip fails (combat state, full slots)
		if GameManager.current_state == GameManager.GameState.COMBAT:
			if charms_detail_label:
				charms_detail_label.text = "Cannot change charms during combat!"
		elif GameManager.equipped_charms.size() >= GameManager.MAX_CHARM_SLOTS:
			if charms_detail_label:
				charms_detail_label.text = "All charm slots full! Unequip one first."
		if has_node("/root/SFXManager"):
			SFXManager.play("ui_error")
	_refresh_charms_tab()

func _on_charm_unequip(charm_id: String) -> void:
	## Handle unequip button pressed
	var success = GameManager.unequip_charm(charm_id)
	if success:
		if has_node("/root/SFXManager"):
			SFXManager.play("item_equip")
		if charms_detail_label:
			var info = GameManager.CHARM_INFO.get(charm_id, {})
			charms_detail_label.text = "Unequipped: %s" % info.get("name", charm_id)
	else:
		if GameManager.current_state == GameManager.GameState.COMBAT:
			if charms_detail_label:
				charms_detail_label.text = "Cannot change charms during combat!"
		if has_node("/root/SFXManager"):
			SFXManager.play("ui_error")
	_refresh_charms_tab()

func _get_charm_stat_preview(charm_id: String) -> String:
	## Return a concrete stat comparison string for a charm.
	match charm_id:
		"extended_parry":
			return "  Parry window: 0.15s → 0.21s (+40%)"
		"soul_hoarder":
			return "  Soul gain: ×1.0 → ×1.5 | Spell cost: ×1.0 → ×0.8"
		"corruption_resist":
			return "  Corruption gain: ×1.0 → ×0.6 (-40%)"
		"pogo_master":
			var base_dmg = int(GameManager.player_stats.get("attack", 15) * 1.8)
			var boosted = int(base_dmg * 1.8)
			return "  Pogo damage: %d → %d (+80%%)" % [base_dmg, boosted]
		"dash_master":
			return "  Dash CD: 0.4s → 0.2s | Dash damage: 0 → 10"
		"thorns":
			return "  Counter damage: 0 → 15 (on-hit reflect)"
	return ""

func _refresh_tickets_tab() -> void:
	## Populate quest/ticket backlog — integrates both story tickets and SideQuestManager
	if not active_tickets:
		return
	
	for child in active_tickets.get_children():
		child.queue_free()
	if completed_tickets:
		for child in completed_tickets.get_children():
			child.queue_free()
	
	# ── MAIN STORY TICKETS ─────────────────────────────────────────
	var tickets_active = []
	var tickets_done = []
	
	# Story progression tickets
	if not GameManager.story_flags.get("ch1_complete", false):
		if not GameManager.story_flags.get("ch1_oakhaven_entered", false):
			tickets_active.append({"id": "TKT-001", "title": "Reach Oakhaven Village", "priority": "HIGH", "status": "IN_PROGRESS"})
		else:
			tickets_done.append({"id": "TKT-001", "title": "Reach Oakhaven Village", "priority": "HIGH", "status": "CLOSED"})
		
		if GameManager.story_flags.get("ch1_oakhaven_entered", false) and not GameManager.story_flags.get("ch1_tutorial_knight_defeated", false):
			tickets_active.append({"id": "TKT-002", "title": "Defeat the Tutorial Knight", "priority": "HIGH", "status": "IN_PROGRESS"})
		elif GameManager.story_flags.get("ch1_tutorial_knight_defeated", false):
			tickets_done.append({"id": "TKT-002", "title": "Defeat the Tutorial Knight", "priority": "HIGH", "status": "CLOSED"})
		
		tickets_active.append({"id": "TKT-003", "title": "Collect all Source Key Fragments (%d/7)" % GameManager.source_key_count, "priority": "EPIC", "status": "IN_PROGRESS"})
	else:
		tickets_done.append({"id": "TKT-001", "title": "Reach Oakhaven Village", "priority": "HIGH", "status": "CLOSED"})
		tickets_done.append({"id": "TKT-002", "title": "Defeat the Tutorial Knight", "priority": "HIGH", "status": "CLOSED"})
		tickets_active.append({"id": "TKT-003", "title": "Collect all Source Key Fragments (%d/7)" % GameManager.source_key_count, "priority": "EPIC", "status": "IN_PROGRESS"})
	
	# Optional story tickets
	if GameManager.story_flags.get("ch1_oakhaven_entered", false):
		var apothecary_done = GameManager.story_flags.get("ch1_apothecary_visited", false)
		var auction_done = GameManager.story_flags.get("ch1_auction_house_visited", false)
		if not apothecary_done:
			tickets_active.append({"id": "TKT-OPT-01", "title": "[Optional] Visit the Apothecary", "priority": "LOW", "status": "OPEN"})
		else:
			tickets_done.append({"id": "TKT-OPT-01", "title": "[Optional] Visit the Apothecary", "priority": "LOW", "status": "CLOSED"})
		if not auction_done:
			tickets_active.append({"id": "TKT-OPT-02", "title": "[Optional] Investigate Auction Terminal", "priority": "LOW", "status": "OPEN"})
		else:
			tickets_done.append({"id": "TKT-OPT-02", "title": "[Optional] Investigate Auction Terminal", "priority": "LOW", "status": "CLOSED"})
	
	# ── SIDE QUESTS FROM SideQuestManager (PASS 35 FIX) ─────────
	var _has_sqm = has_node("/root/SideQuestManager")
	if _has_sqm:
		for quest_id in SideQuestManager.quests:
			var qstate: int = SideQuestManager.quests[quest_id]["state"]
			var qdata: Dictionary = SideQuestManager.QUEST_DATABASE.get(quest_id, {})
			if qdata.is_empty():
				continue
			var step: int = SideQuestManager.quests[quest_id]["current_step"]
			var total: int = qdata["steps"].size()
			
			if qstate == SideQuestManager.QuestState.ACTIVE:
				var step_text: String = qdata["steps"][step] if step < total else "Return"
				tickets_active.append({"id": "SQ-%s" % quest_id.substr(0, 8).to_upper(), "title": "[Side Quest] %s (%d/%d) — %s" % [qdata["name"], step, total, step_text], "priority": "MEDIUM", "status": "IN_PROGRESS"})
			elif qstate == SideQuestManager.QuestState.DISCOVERED:
				tickets_active.append({"id": "SQ-%s" % quest_id.substr(0, 8).to_upper(), "title": "[Side Quest] %s — %s" % [qdata["name"], qdata.get("discovery_hint", "Investigate...")], "priority": "LOW", "status": "DISCOVERED"})
			elif qstate == SideQuestManager.QuestState.COMPLETED:
				tickets_done.append({"id": "SQ-%s" % quest_id.substr(0, 8).to_upper(), "title": "[Side Quest] %s" % qdata["name"], "priority": "MEDIUM", "status": "CLOSED"})
	
	# Render active
	for ticket in tickets_active:
		var lbl = Label.new()
		var priority_color = Color.WHITE
		match ticket["priority"]:
			"EPIC": priority_color = Color(1, 0.5, 0.2)
			"HIGH": priority_color = Color(1, 0.3, 0.3)
			"MEDIUM": priority_color = Color(1, 0.85, 0.3)
			"LOW": priority_color = Color(0.6, 0.8, 1.0)
		lbl.text = "[%s] %s — Priority: %s — %s" % [ticket["id"], ticket["title"], ticket["priority"], ticket["status"]]
		lbl.add_theme_color_override("font_color", priority_color)
		lbl.custom_minimum_size = Vector2(0, 24)
		active_tickets.add_child(lbl)
	
	# Render completed
	if completed_tickets:
		for ticket in tickets_done:
			var lbl = Label.new()
			lbl.text = "✓ [%s] %s — CLOSED" % [ticket["id"], ticket["title"]]
			lbl.modulate = Color(0.5, 0.5, 0.5)
			lbl.custom_minimum_size = Vector2(0, 24)
			completed_tickets.add_child(lbl)
	
	# ── COMPLETIONIST TRACKER (PASS 35 FIX) ─────────────────────
	if _has_sqm:
		var total_quests: int = SideQuestManager.QUEST_DATABASE.size()
		var completed_count: int = 0
		for qid in SideQuestManager.quests:
			if SideQuestManager.quests[qid]["state"] == SideQuestManager.QuestState.COMPLETED:
				completed_count += 1
		var secrets_total: int = SideQuestManager.SECRETS_DATABASE.size()
		var secrets_count: int = SideQuestManager.secrets_found.size()
		
		var tracker_lbl = Label.new()
		tracker_lbl.text = "\n── COMPLETIONIST ──\nSide Quests: %d/%d | Secrets: %d/%d | Completion: %d%%" % [
			completed_count, total_quests, secrets_count, secrets_total,
			int((float(completed_count + secrets_count) / maxf(float(total_quests + secrets_total), 1.0)) * 100.0)
		]
		tracker_lbl.add_theme_color_override("font_color", Color(0.8, 0.5, 1.0))
		tracker_lbl.custom_minimum_size = Vector2(0, 40)
		active_tickets.add_child(tracker_lbl)

func _refresh_map_tab() -> void:
	## Show simple map info — placeholder for full map
	if not map_display:
		return
	
	var chapter = GameManager.current_chapter if GameManager.current_chapter else 1
	var location = "Unknown"
	
	if GameManager.story_flags.get("ch1_shatter_witnessed", false):
		location = "Ironhold Approach (Post-Shatter)"
	elif GameManager.story_flags.get("ch1_oakhaven_entered", false):
		location = "Oakhaven Village — The Pastoral Realm"
	elif GameManager.story_flags.get("ch1_glitch_crater_complete", false):
		location = "Path to Oakhaven"
	else:
		location = "Glitch Crater — Awakening Point"
	
	map_display.text = "═══════════════════════════════\n"
	map_display.text += "  AETHELGARD WORLD MAP\n"
	map_display.text += "  Chapter %d\n" % chapter
	map_display.text += "═══════════════════════════════\n\n"
	map_display.text += "  Current Location: %s\n\n" % location
	map_display.text += "  REGIONS:\n"
	map_display.text += "  [✓] Glitch Crater (Starting Zone)\n"
	map_display.text += "  [%s] Oakhaven Village (Pastoral Realm)\n" % ("✓" if GameManager.story_flags.get("ch1_oakhaven_entered", false) else "?")
	map_display.text += "  [%s] Ironhold (Steam Realm)\n" % ("✓" if GameManager.story_flags.get("ch1_shatter_witnessed", false) else "?")
	map_display.text += "  [?] Luminara (Crystal Caverns)\n"
	map_display.text += "  [?] Neon Necropolis (Digital Afterlife)\n"
	map_display.text += "  [?] The Void (System Core)\n"
	map_display.text += "  [?] Server Room (Final Zone)\n\n"
	map_display.text += "  Source Key Fragments: %d / 7\n" % GameManager.source_key_count

func _build_pause_ui() -> void:
	## Runtime construction of pause UI if scene nodes don't exist
	# This creates the pause menu entirely in code as a fallback
	var panel = PanelContainer.new()
	panel.name = "PanelContainer"
	panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	panel.add_theme_stylebox_override("panel", _create_dark_panel())
	add_child(panel)
	
	var margin = MarginContainer.new()
	margin.name = "MarginContainer"
	margin.add_theme_constant_override("margin_left", 40)
	margin.add_theme_constant_override("margin_right", 40)
	margin.add_theme_constant_override("margin_top", 30)
	margin.add_theme_constant_override("margin_bottom", 30)
	panel.add_child(margin)
	
	var vbox = VBoxContainer.new()
	vbox.name = "VBox"
	margin.add_child(vbox)
	
	# Header bar
	var header_bar = HBoxContainer.new()
	header_bar.name = "HeaderBar"
	vbox.add_child(header_bar)
	
	header_label = Label.new()
	header_label.name = "TitleLabel"
	header_label.text = "AETHELGARD IDE v0.1.1 — PAUSED"
	header_label.add_theme_font_size_override("font_size", 20)
	header_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header_bar.add_child(header_label)
	
	corruption_label = Label.new()
	corruption_label.name = "CorruptionLabel"
	corruption_label.text = "CORRUPTION: 0%"
	corruption_label.add_theme_color_override("font_color", Color(1, 0.3, 0.3))
	header_bar.add_child(corruption_label)
	
	# Separator
	var sep = HSeparator.new()
	vbox.add_child(sep)
	
	# Tab container
	tab_container = TabContainer.new()
	tab_container.name = "TabContainer"
	tab_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(tab_container)
	
	# == ASSETS TAB ==
	var assets_scroll = ScrollContainer.new()
	assets_scroll.name = "Assets"
	tab_container.add_child(assets_scroll)
	
	var assets_vbox = VBoxContainer.new()
	assets_vbox.name = "VBox"
	assets_scroll.add_child(assets_vbox)
	
	var inv_header = Label.new()
	inv_header.text = "=== INVENTORY / ASSETS ==="
	inv_header.add_theme_font_size_override("font_size", 16)
	assets_vbox.add_child(inv_header)
	
	inventory_list = VBoxContainer.new()
	inventory_list.name = "ItemList"
	assets_vbox.add_child(inventory_list)
	
	var detail_panel = PanelContainer.new()
	detail_panel.name = "DetailPanel"
	detail_panel.custom_minimum_size = Vector2(0, 100)
	assets_vbox.add_child(detail_panel)
	
	item_detail_label = Label.new()
	item_detail_label.name = "DetailText"
	item_detail_label.text = "Select an item to view details."
	item_detail_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	detail_panel.add_child(item_detail_label)
	assets_panel = assets_scroll
	
	# == FUNCTIONS TAB ==
	var func_scroll = ScrollContainer.new()
	func_scroll.name = "Functions"
	tab_container.add_child(func_scroll)
	
	var func_vbox = VBoxContainer.new()
	func_vbox.name = "VBox"
	func_scroll.add_child(func_vbox)
	
	var func_header = Label.new()
	func_header.text = "=== FUNCTIONS / ABILITIES ==="
	func_header.add_theme_font_size_override("font_size", 16)
	func_vbox.add_child(func_header)
	
	ability_list = VBoxContainer.new()
	ability_list.name = "AbilityList"
	func_vbox.add_child(ability_list)
	
	var ability_detail_panel = PanelContainer.new()
	ability_detail_panel.name = "DetailPanel"
	ability_detail_panel.custom_minimum_size = Vector2(0, 120)
	func_vbox.add_child(ability_detail_panel)
	
	ability_detail = Label.new()
	ability_detail.name = "AbilityDetail"
	ability_detail.text = "Select an ability to view details."
	ability_detail.autowrap_mode = TextServer.AUTOWRAP_WORD
	ability_detail_panel.add_child(ability_detail)
	functions_panel = func_scroll
	
	# == CHARMS TAB ==
	var charms_scroll = ScrollContainer.new()
	charms_scroll.name = "Charms"
	tab_container.add_child(charms_scroll)
	
	var charms_vbox = VBoxContainer.new()
	charms_vbox.name = "VBox"
	charms_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	charms_scroll.add_child(charms_vbox)
	
	var charms_header = Label.new()
	charms_header.text = "=== CHARM LOADOUT ==="
	charms_header.add_theme_font_size_override("font_size", 16)
	charms_header.add_theme_color_override("font_color", Color(1.0, 0.85, 0.2))
	charms_vbox.add_child(charms_header)
	
	charms_slots_container = VBoxContainer.new()
	charms_slots_container.name = "SlotsContainer"
	charms_vbox.add_child(charms_slots_container)
	
	charms_unlocked_container = VBoxContainer.new()
	charms_unlocked_container.name = "UnlockedContainer"
	charms_vbox.add_child(charms_unlocked_container)
	
	var charms_detail_panel = PanelContainer.new()
	charms_detail_panel.name = "CharmDetailPanel"
	charms_detail_panel.custom_minimum_size = Vector2(0, 60)
	charms_vbox.add_child(charms_detail_panel)
	
	charms_detail_label = Label.new()
	charms_detail_label.name = "CharmDetailText"
	charms_detail_label.text = "Equip up to 3 charms. Effects apply in combat."
	charms_detail_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	charms_detail_label.add_theme_font_size_override("font_size", 12)
	charms_detail_label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.55))
	charms_detail_panel.add_child(charms_detail_label)
	charms_panel = charms_scroll
	
	# == TICKET BACKLOG TAB ==
	var ticket_scroll = ScrollContainer.new()
	ticket_scroll.name = "TicketBacklog"
	tab_container.add_child(ticket_scroll)
	
	var ticket_vbox = VBoxContainer.new()
	ticket_vbox.name = "VBox"
	ticket_scroll.add_child(ticket_vbox)
	
	var active_header = Label.new()
	active_header.text = "=== ACTIVE TICKETS ==="
	active_header.add_theme_font_size_override("font_size", 16)
	ticket_vbox.add_child(active_header)
	
	active_tickets = VBoxContainer.new()
	active_tickets.name = "ActiveTickets"
	ticket_vbox.add_child(active_tickets)
	
	var done_header = Label.new()
	done_header.text = "\n=== COMPLETED TICKETS ==="
	done_header.add_theme_font_size_override("font_size", 16)
	ticket_vbox.add_child(done_header)
	
	completed_tickets = VBoxContainer.new()
	completed_tickets.name = "CompletedTickets"
	ticket_vbox.add_child(completed_tickets)
	tickets_panel = ticket_scroll
	
	# == MAP TAB ==
	var map_scroll = ScrollContainer.new()
	map_scroll.name = "Map"
	tab_container.add_child(map_scroll)
	
	map_display = Label.new()
	map_display.name = "MapDisplay"
	map_display.text = "Loading map data..."
	map_display.add_theme_font_size_override("font_size", 14)
	map_scroll.add_child(map_display)
	map_panel = map_scroll
	
	# ── Footer Row 1: Save Slots ──
	var save_header = Label.new()
	save_header.text = "── SAVE ──"
	save_header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	save_header.add_theme_font_size_override("font_size", 13)
	save_header.add_theme_color_override("font_color", Color(0.4, 0.7, 1.0))
	vbox.add_child(save_header)

	var save_row = HBoxContainer.new()
	save_row.alignment = BoxContainer.ALIGNMENT_CENTER
	save_row.add_theme_constant_override("separation", 12)
	vbox.add_child(save_row)

	for slot_idx in [0, 1, 2]:
		var slot_btn = Button.new()
		slot_btn.text = "  Slot %d  " % (slot_idx + 1)
		slot_btn.add_theme_font_size_override("font_size", 12)
		var s = slot_idx
		slot_btn.pressed.connect(func():
			if has_node("/root/GameManager"):
				var success = GameManager.save_game(s)
				if has_node("/root/SFXManager"):
					SFXManager.play("ui_confirm" if success else "ui_cancel")
				if has_node("/root/VFXLibrary") and success:
					VFXLibrary.spawn_status_indicator("Saved to Slot %d!" % (s + 1), Vector2(640, 400), self, true)
				elif has_node("/root/VFXLibrary") and not success:
					VFXLibrary.spawn_status_indicator("Cannot save now!", Vector2(640, 400), self, false)
		)
		save_row.add_child(slot_btn)

	var autosave_btn = Button.new()
	autosave_btn.text = "  Quick Save  "
	autosave_btn.add_theme_font_size_override("font_size", 12)
	autosave_btn.add_theme_color_override("font_color", Color(0.3, 0.9, 0.5))
	autosave_btn.pressed.connect(func():
		if has_node("/root/GameManager"):
			GameManager.auto_save()
			if has_node("/root/SFXManager"):
				SFXManager.play("ui_confirm")
			if has_node("/root/VFXLibrary"):
				VFXLibrary.spawn_status_indicator("Quick Saved!", Vector2(640, 400), self, true)
	)
	save_row.add_child(autosave_btn)

	# ── Footer Row 2: Actions ──
	var action_row = HBoxContainer.new()
	action_row.alignment = BoxContainer.ALIGNMENT_CENTER
	action_row.add_theme_constant_override("separation", 16)
	vbox.add_child(action_row)

	var options_btn = Button.new()
	options_btn.text = "  Options  "
	options_btn.add_theme_font_size_override("font_size", 12)
	options_btn.pressed.connect(_open_pause_options)
	action_row.add_child(options_btn)

	var feedback_btn = Button.new()
	feedback_btn.text = "  Feedback  "
	feedback_btn.add_theme_font_size_override("font_size", 12)
	feedback_btn.add_theme_color_override("font_color", Color(0.5, 0.9, 1.0))
	feedback_btn.pressed.connect(_open_feedback)
	action_row.add_child(feedback_btn)

	var completion_btn = Button.new()
	completion_btn.text = "  Completion  "
	completion_btn.add_theme_font_size_override("font_size", 12)
	completion_btn.add_theme_color_override("font_color", Color(0.0, 1.0, 0.6))
	completion_btn.pressed.connect(_open_completion_from_pause)
	action_row.add_child(completion_btn)

	var menu_btn = Button.new()
	menu_btn.text = "  Main Menu  "
	menu_btn.add_theme_font_size_override("font_size", 12)
	menu_btn.add_theme_color_override("font_color", Color(1.0, 0.6, 0.3))
	menu_btn.pressed.connect(_return_to_main_menu)
	action_row.add_child(menu_btn)

	var footer = Label.new()
	footer.text = "[ESC] Resume  |  [←→] Switch Tabs  |  [ENTER] Select"
	footer.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	footer.add_theme_color_override("font_color", Color(0.4, 0.4, 0.45))
	footer.add_theme_font_size_override("font_size", 11)
	vbox.add_child(footer)

func _create_dark_panel() -> StyleBoxFlat:
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.08, 0.12, 0.95)
	style.border_color = Color(0.2, 0.6, 0.3, 0.8)
	style.set_border_width_all(2)
	style.set_corner_radius_all(4)
	return style

# ======================================================================
#  IN-GAME OPTIONS PANEL (mirrors main menu options)
# ======================================================================

var _pause_options_panel: PanelContainer = null
var _pause_options_visible: bool = false

func _open_pause_options() -> void:
	if _pause_options_visible:
		_close_pause_options()
		return
	_pause_options_visible = true
	if has_node("/root/SFXManager"):
		SFXManager.play("ui_click")
	_build_pause_options()

func _build_pause_options() -> void:
	if _pause_options_panel and is_instance_valid(_pause_options_panel):
		_pause_options_panel.queue_free()

	_pause_options_panel = PanelContainer.new()
	_pause_options_panel.name = "PauseOptionsPanel"
	_pause_options_panel.set_anchors_preset(Control.PRESET_CENTER)
	_pause_options_panel.offset_left = -280
	_pause_options_panel.offset_right = 280
	_pause_options_panel.offset_top = -250
	_pause_options_panel.offset_bottom = 250

	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.06, 0.05, 0.1, 0.98)
	style.border_color = Color(0.4, 0.3, 0.7, 0.9)
	style.set_border_width_all(2)
	style.set_corner_radius_all(8)
	style.set_content_margin_all(16)
	_pause_options_panel.add_theme_stylebox_override("panel", style)

	var scroll = ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(520, 460)
	_pause_options_panel.add_child(scroll)

	var vbox = VBoxContainer.new()
	vbox.custom_minimum_size = Vector2(500, 0)
	scroll.add_child(vbox)

	# Title
	var title = Label.new()
	title.text = "━━  OPTIONS  ━━"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 18)
	title.add_theme_color_override("font_color", Color(0.8, 0.7, 1.0))
	vbox.add_child(title)
	vbox.add_child(HSeparator.new())

	# Music Volume
	var mv_label = Label.new()
	mv_label.text = "Music Volume"
	mv_label.add_theme_font_size_override("font_size", 13)
	mv_label.add_theme_color_override("font_color", Color(0.7, 0.9, 1.0))
	vbox.add_child(mv_label)

	var mv_slider = HSlider.new()
	mv_slider.min_value = 0.0
	mv_slider.max_value = 1.0
	mv_slider.step = 0.05
	mv_slider.value = MusicManager.get_music_volume() if has_node("/root/MusicManager") else 0.7
	mv_slider.custom_minimum_size = Vector2(400, 20)
	mv_slider.value_changed.connect(func(val: float):
		if has_node("/root/MusicManager"): MusicManager.set_music_volume(val))
	vbox.add_child(mv_slider)

	# SFX Volume
	var sfx_label = Label.new()
	sfx_label.text = "SFX Volume"
	sfx_label.add_theme_font_size_override("font_size", 13)
	sfx_label.add_theme_color_override("font_color", Color(0.7, 0.9, 1.0))
	vbox.add_child(sfx_label)

	var sfx_slider = HSlider.new()
	sfx_slider.min_value = 0.0
	sfx_slider.max_value = 1.0
	sfx_slider.step = 0.05
	sfx_slider.value = MusicManager.get_sfx_volume() if has_node("/root/MusicManager") else 0.8
	sfx_slider.custom_minimum_size = Vector2(400, 20)
	sfx_slider.value_changed.connect(func(val: float):
		if has_node("/root/MusicManager"): MusicManager.set_sfx_volume(val))
	vbox.add_child(sfx_slider)

	vbox.add_child(HSeparator.new())

	# Difficulty
	var diff_label = Label.new()
	diff_label.text = "Difficulty"
	diff_label.add_theme_font_size_override("font_size", 13)
	diff_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.5))
	vbox.add_child(diff_label)

	var diff_opt = OptionButton.new()
	diff_opt.add_theme_font_size_override("font_size", 13)
	diff_opt.custom_minimum_size = Vector2(200, 28)
	for i in range(GameManager.DIFFICULTY_NAMES.size()):
		diff_opt.add_item(GameManager.DIFFICULTY_NAMES[i], i)
	diff_opt.selected = GameManager.selected_difficulty
	diff_opt.item_selected.connect(func(idx: int): GameManager.set_difficulty(idx as GameManager.Difficulty))
	vbox.add_child(diff_opt)

	vbox.add_child(HSeparator.new())

	# Screen Shake
	var shake_cb = CheckButton.new()
	shake_cb.text = "  Screen Shake"
	shake_cb.add_theme_font_size_override("font_size", 13)
	shake_cb.button_pressed = GameManager.get_accessibility("screen_shake_enabled", true)
	shake_cb.toggled.connect(func(on: bool): GameManager.set_accessibility("screen_shake_enabled", on))
	vbox.add_child(shake_cb)

	# Reduced Motion
	var rm_cb = CheckButton.new()
	rm_cb.text = "  Reduced Motion"
	rm_cb.add_theme_font_size_override("font_size", 13)
	rm_cb.button_pressed = GameManager.get_accessibility("reduced_motion", false)
	rm_cb.toggled.connect(func(on: bool): GameManager.set_accessibility("reduced_motion", on))
	vbox.add_child(rm_cb)

	# Tutorial Hints
	var th_cb = CheckButton.new()
	th_cb.text = "  Tutorial Hints"
	th_cb.add_theme_font_size_override("font_size", 13)
	th_cb.button_pressed = GameManager.get_accessibility("tutorial_hints_enabled", true)
	th_cb.toggled.connect(func(on: bool): GameManager.set_accessibility("tutorial_hints_enabled", on))
	vbox.add_child(th_cb)

	vbox.add_child(HSeparator.new())

	# Close button
	var close_btn = Button.new()
	close_btn.text = "Close"
	close_btn.custom_minimum_size = Vector2(100, 34)
	close_btn.add_theme_font_size_override("font_size", 14)
	close_btn.pressed.connect(_close_pause_options)
	vbox.add_child(close_btn)

	add_child(_pause_options_panel)

	# Animate in
	_pause_options_panel.modulate.a = 0.0
	_pause_options_panel.scale = Vector2(0.92, 0.92)
	var tw = create_tween()
	tw.tween_property(_pause_options_panel, "modulate:a", 1.0, 0.2)
	tw.parallel().tween_property(_pause_options_panel, "scale", Vector2(1.0, 1.0), 0.2).set_trans(Tween.TRANS_BACK)

func _close_pause_options() -> void:
	_pause_options_visible = false
	if _pause_options_panel and is_instance_valid(_pause_options_panel):
		var tw = create_tween()
		tw.tween_property(_pause_options_panel, "modulate:a", 0.0, 0.15)
		tw.tween_callback(_pause_options_panel.queue_free)

# ======================================================================
#  RETURN TO MAIN MENU
# ======================================================================

var _confirm_menu_panel: PanelContainer = null

func _return_to_main_menu() -> void:
	if has_node("/root/SFXManager"):
		SFXManager.play("ui_click")
	# Show confirmation dialog
	if _confirm_menu_panel and is_instance_valid(_confirm_menu_panel):
		_confirm_menu_panel.queue_free()

	_confirm_menu_panel = PanelContainer.new()
	_confirm_menu_panel.set_anchors_preset(Control.PRESET_CENTER)
	_confirm_menu_panel.offset_left = -200
	_confirm_menu_panel.offset_right = 200
	_confirm_menu_panel.offset_top = -80
	_confirm_menu_panel.offset_bottom = 80

	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.1, 0.05, 0.05, 0.98)
	style.border_color = Color(1.0, 0.4, 0.3, 0.9)
	style.set_border_width_all(2)
	style.set_corner_radius_all(8)
	style.set_content_margin_all(20)
	_confirm_menu_panel.add_theme_stylebox_override("panel", style)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 12)
	_confirm_menu_panel.add_child(vbox)

	var warn_label = Label.new()
	warn_label.text = "Return to Main Menu?"
	warn_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	warn_label.add_theme_font_size_override("font_size", 16)
	warn_label.add_theme_color_override("font_color", Color(1.0, 0.6, 0.3))
	vbox.add_child(warn_label)

	var hint_label = Label.new()
	hint_label.text = "Unsaved progress will be lost."
	hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint_label.add_theme_font_size_override("font_size", 12)
	hint_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.65))
	vbox.add_child(hint_label)

	var btn_row = HBoxContainer.new()
	btn_row.alignment = BoxContainer.ALIGNMENT_CENTER
	btn_row.add_theme_constant_override("separation", 20)
	vbox.add_child(btn_row)

	var yes_btn = Button.new()
	yes_btn.text = "  Yes, Leave  "
	yes_btn.add_theme_font_size_override("font_size", 13)
	yes_btn.add_theme_color_override("font_color", Color(1.0, 0.4, 0.4))
	yes_btn.pressed.connect(func():
		# Resume tree, close pause, go to menu
		is_paused = false
		visible = false
		get_tree().paused = false
		if has_node("/root/UIStack"):
			UIStack.close("pause_screen")
		if _confirm_menu_panel and is_instance_valid(_confirm_menu_panel):
			_confirm_menu_panel.queue_free()
		if has_node("/root/SceneTransitions"):
			SceneTransitions.change_scene("res://scenes/main_menu.tscn")
		else:
			get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
	)
	btn_row.add_child(yes_btn)

	var no_btn = Button.new()
	no_btn.text = "  Cancel  "
	no_btn.add_theme_font_size_override("font_size", 13)
	no_btn.pressed.connect(func():
		if _confirm_menu_panel and is_instance_valid(_confirm_menu_panel):
			_confirm_menu_panel.queue_free()
	)
	btn_row.add_child(no_btn)

	add_child(_confirm_menu_panel)

	_confirm_menu_panel.modulate.a = 0.0
	var tw = create_tween()
	tw.tween_property(_confirm_menu_panel, "modulate:a", 1.0, 0.2)

func block_pause() -> void:
	## Call during cutscenes to prevent pausing
	pause_blocked = true

func unblock_pause() -> void:
	## Call after cutscenes to allow pausing again
	pause_blocked = false

# ======================================================================
#  FEEDBACK / BUG REPORT
# ======================================================================
func _open_feedback() -> void:
	# Opens the user's browser to a feedback form / itch.io page
	OS.shell_open("https://itch.io")  # Replace with your real itch.io feedback URL
	if has_node("/root/SFXManager"):
		SFXManager.play("ui_confirm")

# ======================================================================
#  COMPLETION TRACKER (from pause)
# ======================================================================
func _open_completion_from_pause() -> void:
	if has_node("/root/CompletionTracker"):
		CompletionTracker.show_tracker()
