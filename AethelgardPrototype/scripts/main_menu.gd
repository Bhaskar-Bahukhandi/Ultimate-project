extends Control

var title_label: Label = null
var buttons_container: Node = null
var options_panel: PanelContainer = null
var _options_visible: bool = false

const OPENING_HOOK_SCENE := "res://scenes/chapter1/opening_crash_site_hook.tscn"
const LEGACY_PROLOGUE_SCENE := "res://scenes/prologue/flight_707.tscn"

func _ready() -> void:
	_chapter_launching = false  # Reset so chapter select works if player returns to menu
	GameManager.change_state(GameManager.GameState.MENU)
	_load_key_bindings()
	_check_ng_plus_availability()
	_configure_public_menu_surface()
	_animate_intro()
	# Play main menu music
	if has_node("/root/MusicManager"):
		MusicManager.play_track("main_menu")

func _animate_intro() -> void:
	# Fade the whole menu in
	modulate.a = 0.0
	var fade_tween = create_tween()
	fade_tween.tween_property(self, "modulate:a", 1.0, 0.8)
	
	# Try to find and animate the title 
	title_label = _find_child_by_type("Label")
	if title_label:
		var original_pos = title_label.position
		title_label.position.y -= 30
		title_label.modulate.a = 0.0
		var t = create_tween()
		t.tween_property(title_label, "position:y", original_pos.y, 0.6).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT).set_delay(0.3)
		t.parallel().tween_property(title_label, "modulate:a", 1.0, 0.4).set_delay(0.3)
		
		# Gentle pulse on title
		var pulse = create_tween().set_loops()
		pulse.tween_property(title_label, "modulate:v", 1.2, 1.5).set_trans(Tween.TRANS_SINE).set_delay(1.5)
		pulse.tween_property(title_label, "modulate:v", 1.0, 1.5).set_trans(Tween.TRANS_SINE)
	
	# Animate buttons sliding in
	var buttons = _find_buttons()
	for i in range(buttons.size()):
		var btn: Button = buttons[i]
		var original_x = btn.position.x
		btn.position.x -= 200
		btn.modulate.a = 0.0
		var bt = create_tween()
		bt.tween_property(btn, "position:x", original_x, 0.4).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT).set_delay(0.5 + i * 0.12)
		bt.parallel().tween_property(btn, "modulate:a", 1.0, 0.3).set_delay(0.5 + i * 0.12)

func _find_child_by_type(type_name: String, node: Node = null) -> Node:
	## Recursively search for the first child matching the given class name.
	if node == null:
		node = self
	for child in node.get_children():
		if child.get_class() == type_name:
			return child
		var found = _find_child_by_type(type_name, child)
		if found:
			return found
	return null

func _find_buttons() -> Array:
	var results = []
	_collect_buttons(self, results)
	return results

func _collect_buttons(node: Node, results: Array) -> void:
	if node is Button:
		results.append(node)
	for child in node.get_children():
		_collect_buttons(child, results)

func _check_ng_plus_availability() -> void:
	## If NG+ is available (true ending beaten), add a NEW GAME+ button after NEW GAME
	if not GameManager.ng_plus_available:
		# Also check any save slot for the true ending flag
		for slot in SAVE_SLOTS:
			var info = GameManager.get_save_info(slot)
			if info.get("exists", false):
				var flags = info.get("story_flags", {})
				if flags.get("ch10_complete", false):
					GameManager.ng_plus_available = true
					break
	if not GameManager.ng_plus_available:
		return
	# Find the VBoxContainer and insert NG+ button after NewGameButton
	var vbox = get_node_or_null("VBoxContainer")
	if not vbox:
		return
	var new_game_btn = vbox.get_node_or_null("NewGameButton")
	if not new_game_btn:
		return
	var ng_btn = Button.new()
	ng_btn.name = "NGPlusButton"
	ng_btn.text = "NEW GAME+"
	ng_btn.layout_mode = 2
	var cycle = GameManager.ng_plus_cycle + 1
	if cycle > 1:
		ng_btn.text = "NEW GAME+ (%d)" % cycle
	ng_btn.pressed.connect(_on_ng_plus_pressed)
	# Insert right after NewGameButton
	var idx = new_game_btn.get_index() + 1
	vbox.add_child(ng_btn)
	vbox.move_child(ng_btn, idx)

func _on_ng_plus_pressed() -> void:
	SFXManager.play("ui_confirm")
	GameManager.start_new_game_plus()
	SceneTransitions.change_scene(LEGACY_PROLOGUE_SCENE)

func _on_new_game_pressed() -> void:
	SFXManager.play("ui_confirm")
	# Reset game state to ensure a clean start
	GameManager.reset_game()
	# 10N-A2: New Game now starts with immediate player control.
	var target_scene := OPENING_HOOK_SCENE
	if not ResourceLoader.exists(target_scene):
		push_warning("[10N-A2] Opening hook missing; falling back to legacy cinematic prologue.")
		target_scene = LEGACY_PROLOGUE_SCENE
	# SceneTransitions handles the fade
	SceneTransitions.change_scene(target_scene)

func _start_legacy_cinematic_prologue() -> void:
	SFXManager.play("ui_confirm")
	GameManager.reset_game()
	SceneTransitions.change_scene(LEGACY_PROLOGUE_SCENE)

func _add_legacy_prologue_debug_button() -> void:
	if not OS.is_debug_build():
		return
	var vbox = get_node_or_null("VBoxContainer")
	if not vbox or vbox.has_node("LegacyPrologueButton"):
		return
	var legacy_btn := Button.new()
	legacy_btn.name = "LegacyPrologueButton"
	legacy_btn.text = "DEBUG: LEGACY CINEMATIC START"
	legacy_btn.layout_mode = 2
	legacy_btn.pressed.connect(_start_legacy_cinematic_prologue)
	var insert_index := vbox.get_child_count()
	var new_game_btn = vbox.get_node_or_null("NewGameButton")
	if new_game_btn:
		insert_index = new_game_btn.get_index() + 1
	vbox.add_child(legacy_btn)
	vbox.move_child(legacy_btn, insert_index)


func _configure_public_menu_surface() -> void:
	# 10N-A2.8: keep developer routes callable, but remove them from the fresh-player menu surface.
	var vbox = get_node_or_null("VBoxContainer")
	if not vbox:
		return
	for button_name in ["SkipPrologueButton", "ChapterSelectButton", "CompletionButton", "LegacyPrologueButton"]:
		var button := vbox.get_node_or_null(button_name) as Button
		if button:
			button.visible = false
			button.disabled = true
			button.focus_mode = Control.FOCUS_NONE

func _on_skip_prologue_pressed() -> void:
	## Skip the prologue and start directly in the Open World.
	SFXManager.play("ui_confirm")
	GameManager.reset_game()
	# Set prologue + early story completion flags
	GameManager.set_story_flag("plane_crash_completed", true)
	GameManager.set_story_flag("ch1_awakening_complete", true)
	GameManager.set_story_flag("ch1_glitch_crater_complete", true)
	GameManager.set_story_flag("elara_met", true)
	GameManager.player_stats["gold"] = 100  # Start with enough to buy a few potions
	if has_node("/root/Inventory"):
		Inventory.gold = 100  # Keep gold in sync with Inventory
	GameManager.player_stats["hp"] = GameManager.player_stats["max_hp"]
	GameManager.player_stats["mp"] = GameManager.player_stats["max_mp"]
	GameManager.current_chapter = 1
	GameManager.current_region = ""
	GameManager.player_overworld_position = Vector2(400, 400)  # Near Oakhaven
	GameManager.change_state(GameManager.GameState.EXPLORATION)
	SceneTransitions.change_scene("res://scenes/overworld/overworld.tscn")

var _load_panel: PanelContainer = null
var _load_panel_visible: bool = false

const SAVE_SLOTS: Array = [0, 1, 2, 99]  # 3 manual + autosave
const SLOT_LABELS: Dictionary = {0: "Slot 1", 1: "Slot 2", 2: "Slot 3", 99: "Autosave"}
const CHAPTER_NAMES: Dictionary = {0: "Prologue", 1: "Ch.1 — Shattered Skies", 2: "Ch.2 — The Administrator", 3: "Ch.3 — The Source Code"}

func _on_load_game_pressed() -> void:
	SFXManager.play("ui_click")
	if _load_panel_visible:
		_close_load_panel()
		return
	_build_load_panel()

func _build_load_panel() -> void:
	if _load_panel and is_instance_valid(_load_panel):
		_load_panel.queue_free()

	_load_panel_visible = true

	_load_panel = PanelContainer.new()
	_load_panel.name = "LoadGamePanel"
	_load_panel.set_anchors_preset(Control.PRESET_CENTER)
	_load_panel.offset_left = -300
	_load_panel.offset_right = 300
	_load_panel.offset_top = -240
	_load_panel.offset_bottom = 240

	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.05, 0.06, 0.12, 0.96)
	style.border_color = Color(0.3, 0.6, 0.9, 0.9)
	style.border_width_top = 2; style.border_width_bottom = 2
	style.border_width_left = 2; style.border_width_right = 2
	style.content_margin_top = 16; style.content_margin_bottom = 16
	style.content_margin_left = 20; style.content_margin_right = 20
	style.corner_radius_top_left = 8; style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8; style.corner_radius_bottom_right = 8
	_load_panel.add_theme_stylebox_override("panel", style)

	var vbox = VBoxContainer.new()
	vbox.custom_minimum_size = Vector2(560, 0)
	_load_panel.add_child(vbox)

	# Title
	var title = Label.new()
	title.text = "━━  LOAD GAME  ━━"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 20)
	title.add_theme_color_override("font_color", Color(0.5, 0.8, 1.0))
	vbox.add_child(title)
	vbox.add_child(HSeparator.new())

	# Build a card per save slot
	for slot in SAVE_SLOTS:
		var info = GameManager.get_save_info(slot)
		var card = _build_slot_card(slot, info)
		vbox.add_child(card)
		vbox.add_child(HSeparator.new())

	# Close button
	var close_btn = Button.new()
	close_btn.text = "Back"
	close_btn.custom_minimum_size = Vector2(100, 34)
	close_btn.add_theme_font_size_override("font_size", 14)
	close_btn.pressed.connect(_close_load_panel)
	vbox.add_child(close_btn)

	add_child(_load_panel)

	# Animate in
	_load_panel.modulate.a = 0.0
	_load_panel.scale = Vector2(0.9, 0.9)
	var tw = create_tween()
	tw.tween_property(_load_panel, "modulate:a", 1.0, 0.25)
	tw.parallel().tween_property(_load_panel, "scale", Vector2(1.0, 1.0), 0.25).set_trans(Tween.TRANS_BACK)

func _build_slot_card(slot: int, info: Dictionary) -> HBoxContainer:
	var hbox = HBoxContainer.new()
	hbox.custom_minimum_size = Vector2(0, 64)

	var info_vbox = VBoxContainer.new()
	info_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(info_vbox)

	var slot_name = SLOT_LABELS.get(slot, "Slot ?")

	if info.get("corrupt", false):
		var corrupt_label = Label.new()
		var backup_valid: bool = info.get("backup_valid", false)
		corrupt_label.text = "%s  —  Damaged save%s" % [slot_name, " (backup available)" if backup_valid else " (no backup)"]
		corrupt_label.add_theme_font_size_override("font_size", 14)
		corrupt_label.add_theme_color_override("font_color", Color(1.0, 0.65, 0.3))
		info_vbox.add_child(corrupt_label)
		var cs = slot
		if backup_valid:
			var restore_btn = Button.new()
			restore_btn.text = "Restore"
			restore_btn.custom_minimum_size = Vector2(80, 36)
			restore_btn.add_theme_font_size_override("font_size", 13)
			restore_btn.pressed.connect(func(): _do_restore_backup(cs))
			hbox.add_child(restore_btn)
		var del_corrupt_btn = Button.new()
		del_corrupt_btn.text = "Del"
		del_corrupt_btn.custom_minimum_size = Vector2(50, 36)
		del_corrupt_btn.add_theme_font_size_override("font_size", 12)
		del_corrupt_btn.add_theme_color_override("font_color", Color(1.0, 0.4, 0.4))
		del_corrupt_btn.pressed.connect(func(): _do_delete_save(cs))
		hbox.add_child(del_corrupt_btn)
	elif info.get("exists", false):
		# Slot label + chapter
		var chapter_num = info.get("current_chapter", 1)
		var chapter_str = CHAPTER_NAMES.get(chapter_num, "Chapter %d" % chapter_num)
		var name_label = Label.new()
		name_label.text = "%s  —  %s" % [slot_name, chapter_str]
		name_label.add_theme_font_size_override("font_size", 14)
		name_label.add_theme_color_override("font_color", Color(0.9, 0.9, 1.0))
		info_vbox.add_child(name_label)

		# Detail line: Level, HP, Corruption, Playtime
		var lvl = info.get("player_level", 1)
		var hp = info.get("player_hp", 0)
		var max_hp = info.get("player_max_hp", 100)
		var corruption = info.get("corruption_level", 0)
		var playtime = info.get("playtime", 0.0)
		var total_seconds: int = int(playtime)
		var minutes: int = int(total_seconds / 60.0)
		var hours: int = int(minutes / 60.0)
		var mins_rem: int = minutes - (hours * 60)
		var time_str = "%dh %02dm" % [hours, mins_rem] if hours > 0 else "%dm" % mins_rem

		var detail_label = Label.new()
		detail_label.text = "Lv.%d  |  HP %d/%d  |  Corruption %d%%  |  %s" % [lvl, hp, max_hp, corruption, time_str]
		detail_label.add_theme_font_size_override("font_size", 11)
		detail_label.add_theme_color_override("font_color", Color(0.6, 0.65, 0.75))
		info_vbox.add_child(detail_label)

		# Timestamp
		var ts_label = Label.new()
		ts_label.text = "Saved: %s" % info.get("timestamp", "Unknown")
		ts_label.add_theme_font_size_override("font_size", 10)
		ts_label.add_theme_color_override("font_color", Color(0.45, 0.45, 0.55))
		info_vbox.add_child(ts_label)

		# Load button
		var load_btn = Button.new()
		load_btn.text = "Load"
		load_btn.custom_minimum_size = Vector2(70, 36)
		load_btn.add_theme_font_size_override("font_size", 13)
		var s = slot
		load_btn.pressed.connect(func(): _do_load_game(s))
		hbox.add_child(load_btn)

		# Delete button
		var del_btn = Button.new()
		del_btn.text = "Del"
		del_btn.custom_minimum_size = Vector2(50, 36)
		del_btn.add_theme_font_size_override("font_size", 12)
		del_btn.add_theme_color_override("font_color", Color(1.0, 0.4, 0.4))
		del_btn.pressed.connect(func(): _do_delete_save(s))
		hbox.add_child(del_btn)
	else:
		var empty_label = Label.new()
		empty_label.text = "%s  —  Empty" % slot_name
		empty_label.add_theme_font_size_override("font_size", 14)
		empty_label.add_theme_color_override("font_color", Color(0.4, 0.4, 0.5))
		info_vbox.add_child(empty_label)

	return hbox

func _do_load_game(slot: int) -> void:
	_close_load_panel()
	if not has_node("/root/GameManager"):
		return
	var result = await GameManager.load_game(slot)
	if not result and has_node("/root/VFXLibrary"):
		VFXLibrary.spawn_status_indicator("Load failed!", Vector2(640, 400), self, false)

func _do_restore_backup(slot: int) -> void:
	if not has_node("/root/GameManager"):
		return
	var ok: bool = GameManager.restore_backup(slot)
	if has_node("/root/VFXLibrary"):
		VFXLibrary.spawn_status_indicator("Backup restored" if ok else "Restore failed!", Vector2(640, 400), self, ok)
	_close_load_panel()
	_build_load_panel()

func _do_delete_save(slot: int) -> void:
	if not has_node("/root/GameManager"):
		return
	GameManager.delete_save(slot)
	# Rebuild the panel to reflect the change
	_close_load_panel()
	_build_load_panel()

func _close_load_panel() -> void:
	_load_panel_visible = false
	if _load_panel and is_instance_valid(_load_panel):
		var tw = create_tween()
		tw.tween_property(_load_panel, "modulate:a", 0.0, 0.2)
		tw.tween_callback(_load_panel.queue_free)

# ======================================================================
#  CHAPTER SELECT
# ======================================================================

var _chapter_panel: PanelContainer = null
var _chapter_panel_visible: bool = false

const CHAPTER_SELECT_DATA: Array = [
	{
		"label": "Prologue — Flight 707",
		"desc": "Board the doomed flight. The crash that changes everything.",
		"scene": "res://scenes/prologue/flight_707.tscn",
		"chapter": 0,
		"flags": {}
	},
	{
		"label": "Chapter 1 — Glitch Crater Awakening",
		"desc": "Wake up in the crater. Discover your glitch powers.",
		"scene": "res://scenes/chapter1/glitch_crater_awakening.tscn",
		"chapter": 1,
		"flags": {"plane_crash_completed": true}
	},
	{
		"label": "Chapter 1 — Oakhaven Village",
		"desc": "The pastoral village. Explore, shop, and prepare for the Knight.",
		"scene": "res://scenes/chapter1/oakhaven_village.tscn",
		"chapter": 1,
		"flags": {"plane_crash_completed": true, "ch1_awakening_complete": true, "ch1_glitch_crater_complete": true, "ch1_oakhaven_entered": true},
		"gold": 80
	},
	{
		"label": "Chapter 1 — Tutorial Knight Boss",
		"desc": "Face the Tutorial Knight V2.1 at the village gate.",
		"scene": "res://scenes/chapter1/tutorial_knight_boss.tscn",
		"chapter": 1,
		"flags": {"plane_crash_completed": true, "ch1_awakening_complete": true, "ch1_glitch_crater_complete": true, "ch1_oakhaven_entered": true, "root_access_unlocked": true},
		"gold": 120,
		"level": 3
	},
	{
		"label": "Chapter 2 — Ironhold Gate",
		"desc": "Enter the steam-powered city of Ironhold.",
		"scene": "res://scenes/chapter2/ironhold_gate.tscn",
		"chapter": 2,
		"flags": {"plane_crash_completed": true, "ch1_awakening_complete": true, "ch1_glitch_crater_complete": true, "ch1_oakhaven_entered": true, "ch1_tutorial_knight_defeated": true, "ch1_shatter_witnessed": true, "ch1_complete": true, "root_access_unlocked": true, "source_key_fragment_1": true},
		"gold": 200,
		"level": 5
	},
	{
		"label": "Chapter 2 — Arena District",
		"desc": "Fight in the arena for glory and Source Code fragments.",
		"scene": "res://scenes/chapter2/arena_district.tscn",
		"chapter": 2,
		"flags": {"plane_crash_completed": true, "ch1_complete": true, "ch1_tutorial_knight_defeated": true, "ch1_shatter_witnessed": true, "root_access_unlocked": true, "source_key_fragment_1": true, "ch2_ironhold_entered": true},
		"gold": 250,
		"level": 6
	},
	{
		"label": "Chapter 2 — Administrator Boss",
		"desc": "The final confrontation with The Administrator.",
		"scene": "res://scenes/chapter2/administrator_boss.tscn",
		"chapter": 2,
		"flags": {"plane_crash_completed": true, "ch1_complete": true, "ch1_tutorial_knight_defeated": true, "ch1_shatter_witnessed": true, "root_access_unlocked": true, "source_key_fragment_1": true, "ch2_ironhold_entered": true, "ch2_arena_complete": true, "ch2_underground_complete": true, "ch2_clock_tower_complete": true},
		"gold": 400,
		"level": 8
	},
	{
		"label": "Chapter 3 — Ironhold Departure",
		"desc": "Leave Ironhold and venture into the unknown beyond.",
		"scene": "res://scenes/chapter3/ironhold_departure.tscn",
		"chapter": 3,
		"flags": {"ch1_complete": true, "ch2_complete": true, "root_access_unlocked": true, "source_key_fragment_1": true, "source_key_fragment_2": true},
		"gold": 500,
		"level": 10
	},
	{
		"label": "Chapter 3 — Fractured Wastes",
		"desc": "Survive the corrupted wastelands. Recruit Lyra.",
		"scene": "res://scenes/chapter3/fractured_wastes.tscn",
		"chapter": 3,
		"flags": {"ch1_complete": true, "ch2_complete": true, "source_key_fragment_1": true, "source_key_fragment_2": true, "ch3_ironhold_departed": true},
		"gold": 550,
		"level": 10
	},
	{
		"label": "Chapter 3 — Data Stream",
		"desc": "Navigate the on-rails data stream corridor.",
		"scene": "res://scenes/chapter3/data_stream.tscn",
		"chapter": 3,
		"flags": {"ch1_complete": true, "ch2_complete": true, "source_key_fragment_1": true, "source_key_fragment_2": true, "ch3_ironhold_departed": true, "ch3_fractured_wastes_entered": true, "ch3_lyra_recruited": true, "ch3_fragment_3_collected": true, "source_key_fragment_3": true},
		"gold": 600,
		"level": 11
	},
	{
		"label": "Chapter 3 — Archive Depths",
		"desc": "Explore the infinite Archive. Meet Kaelthas and the Archivist.",
		"scene": "res://scenes/chapter3/archive_depths.tscn",
		"chapter": 3,
		"flags": {"ch1_complete": true, "ch2_complete": true, "source_key_fragment_1": true, "source_key_fragment_2": true, "ch3_ironhold_departed": true, "ch3_fractured_wastes_entered": true, "ch3_lyra_recruited": true, "ch3_fragment_3_collected": true, "source_key_fragment_3": true, "ch3_data_stream_complete": true},
		"gold": 650,
		"level": 12
	},
	{
		"label": "Chapter 3 — Kaelthas Betrayal",
		"desc": "Confront Kaelthas — boss fight or chase through the Archive.",
		"scene": "res://scenes/chapter3/kaelthas_betrayal.tscn",
		"chapter": 3,
		"flags": {"ch1_complete": true, "ch2_complete": true, "source_key_fragment_1": true, "source_key_fragment_2": true, "ch3_fragment_3_collected": true, "source_key_fragment_3": true, "ch3_archive_floor4_complete": true, "ch3_sovereign_origin_discovered": true, "ch3_fragment_4_collected": true, "source_key_fragment_4": true},
		"gold": 700,
		"level": 13
	},
	{
		"label": "Chapter 4 — Forgotten Sectors",
		"desc": "Enter SOVEREIGN's deleted region and meet the Null Court.",
		"scene": "res://scenes/chapter4/ch4_forgotten_sectors_intro.tscn",
		"chapter": 4,
		"flags": {"ch1_complete": true, "ch2_complete": true, "ch3_complete": true, "ch3_reality_shatter": true, "ch4_unlocked": true, "source_key_fragment_1": true, "source_key_fragment_2": true, "source_key_fragment_3": true, "source_key_fragment_4": true},
		"gold": 850,
		"level": 14
	},
	{
		"label": "Chapter 4 — Null Court",
		"desc": "Make the first choice about the people SOVEREIGN deleted.",
		"scene": "res://scenes/chapter4/ch4_null_court.tscn",
		"chapter": 4,
		"flags": {"ch1_complete": true, "ch2_complete": true, "ch3_complete": true, "ch3_reality_shatter": true, "ch4_unlocked": true, "ch4_forgotten_sectors_entered": true, "source_key_fragment_1": true, "source_key_fragment_2": true, "source_key_fragment_3": true, "source_key_fragment_4": true},
		"gold": 900,
		"level": 14
	},
	{
		"label": "Chapter 5 — Mirror City",
		"desc": "Enter the city where every reflection is a rejected Kaelen.",
		"scene": "res://scenes/chapter5/ch5_mirror_city_intro.tscn",
		"chapter": 5,
		"flags": {"ch1_complete": true, "ch2_complete": true, "ch3_complete": true, "ch4_complete": true, "ch5_unlocked": true, "ch4_choice_preserve_deleted": true, "ch4_fragment_5_collected": true, "source_key_fragment_1": true, "source_key_fragment_2": true, "source_key_fragment_3": true, "source_key_fragment_4": true, "source_key_fragment_5": true},
		"gold": 1050,
		"level": 15
	},
	{
		"label": "Chapter 5 - Mirror Plaza",
		"desc": "Meet the obedient, savior, and coward echoes before the trial.",
		"scene": "res://scenes/chapter5/ch5_mirror_plaza.tscn",
		"chapter": 5,
		"flags": {"ch1_complete": true, "ch2_complete": true, "ch3_complete": true, "ch4_complete": true, "ch5_unlocked": true, "ch5_mirror_city_entered": true, "ch4_choice_preserve_deleted": true, "ch4_fragment_5_collected": true, "source_key_fragment_1": true, "source_key_fragment_2": true, "source_key_fragment_3": true, "source_key_fragment_4": true, "source_key_fragment_5": true},
		"gold": 1075,
		"level": 15
	},
	{
		"label": "Chapter 5 — Reflection Trial",
		"desc": "Confront Mirror Kaelen and the consequences of Chapter 4.",
		"scene": "res://scenes/chapter5/ch5_reflection_trial.tscn",
		"chapter": 5,
		"flags": {"ch1_complete": true, "ch2_complete": true, "ch3_complete": true, "ch4_complete": true, "ch5_unlocked": true, "ch5_mirror_city_entered": true, "ch5_mirror_plaza_entered": true, "ch5_echo_ch4_preserve_seen": true, "ch5_echo_obedient_met": true, "ch5_echo_savior_met": true, "ch5_echo_coward_met": true, "ch5_all_echoes_resolved": true, "ch5_identity_choice_made": true, "ch5_identity_refused_obedience": true, "ch4_choice_preserve_deleted": true, "ch4_fragment_5_collected": true, "source_key_fragment_1": true, "source_key_fragment_2": true, "source_key_fragment_3": true, "source_key_fragment_4": true, "source_key_fragment_5": true},
		"gold": 1100,
		"level": 15
	},
	{
		"label": "Chapter 5 - Mirror Kaelen",
		"desc": "Finish the expanded Mirror City confrontation and reveal the Chapter 6 trail.",
		"scene": "res://scenes/chapter5/ch5_mirror_kaelen_confrontation.tscn",
		"chapter": 5,
		"flags": {"ch1_complete": true, "ch2_complete": true, "ch3_complete": true, "ch4_complete": true, "ch5_unlocked": true, "ch5_mirror_city_entered": true, "ch5_mirror_plaza_entered": true, "ch5_echo_ch4_preserve_seen": true, "ch5_echo_obedient_met": true, "ch5_echo_savior_met": true, "ch5_echo_coward_met": true, "ch5_all_echoes_resolved": true, "ch5_identity_choice_made": true, "ch5_identity_refused_obedience": true, "ch5_reflection_trial_started": true, "ch5_mirror_kaelen_met": true, "ch5_choice_echo_resolved": true, "ch5_echo_control_rejected": true, "ch4_choice_preserve_deleted": true, "ch4_fragment_5_collected": true, "source_key_fragment_1": true, "source_key_fragment_2": true, "source_key_fragment_3": true, "source_key_fragment_4": true, "source_key_fragment_5": true},
		"gold": 1280,
		"level": 15
	},
	{
		"label": "Chapter 6 - Cathedral Server",
		"desc": "Enter the Cathedral Server and hear the Choir of Broken Gods.",
		"scene": "res://scenes/chapter6/ch6_cathedral_intro.tscn",
		"chapter": 6,
		"flags": {"ch1_complete": true, "ch2_complete": true, "ch3_complete": true, "ch4_complete": true, "ch5_complete": true, "ch6_unlocked": true, "ch6_path_revealed": true, "ch4_choice_preserve_deleted": true, "ch4_fragment_5_collected": true, "ch5_mirror_city_entered": true, "ch5_all_echoes_resolved": true, "ch5_identity_choice_made": true, "ch5_identity_refused_obedience": true, "ch5_fragment_6_trail_found": true, "source_key_fragment_1": true, "source_key_fragment_2": true, "source_key_fragment_3": true, "source_key_fragment_4": true, "source_key_fragment_5": true},
		"gold": 1400,
		"level": 16
	},
	{
		"label": "Chapter 6 - Cathedral Nave",
		"desc": "Hear the doctrines of obedience, efficiency, and mercy without consent.",
		"scene": "res://scenes/chapter6/ch6_cathedral_nave.tscn",
		"chapter": 6,
		"flags": {"ch1_complete": true, "ch2_complete": true, "ch3_complete": true, "ch4_complete": true, "ch5_complete": true, "ch6_unlocked": true, "ch6_path_revealed": true, "ch6_cathedral_entered": true, "ch4_choice_preserve_deleted": true, "ch4_fragment_5_collected": true, "ch5_mirror_city_entered": true, "ch5_all_echoes_resolved": true, "ch5_identity_choice_made": true, "ch5_identity_refused_obedience": true, "ch5_fragment_6_trail_found": true, "source_key_fragment_1": true, "source_key_fragment_2": true, "source_key_fragment_3": true, "source_key_fragment_4": true, "source_key_fragment_5": true},
		"gold": 1450,
		"level": 16
	},
	{
		"label": "Chapter 6 - Choir Core",
		"desc": "Choose whether to silence, preserve, or rewrite the broken administrator intelligences.",
		"scene": "res://scenes/chapter6/ch6_choir_core.tscn",
		"chapter": 6,
		"flags": {"ch1_complete": true, "ch2_complete": true, "ch3_complete": true, "ch4_complete": true, "ch5_complete": true, "ch6_unlocked": true, "ch6_path_revealed": true, "ch6_cathedral_entered": true, "ch6_nave_entered": true, "ch6_obedience_voice_heard": true, "ch6_efficiency_voice_heard": true, "ch6_mercy_voice_heard": true, "ch6_all_voices_heard": true, "ch4_choice_preserve_deleted": true, "ch4_fragment_5_collected": true, "ch5_mirror_city_entered": true, "ch5_all_echoes_resolved": true, "ch5_identity_choice_made": true, "ch5_identity_refused_obedience": true, "ch5_fragment_6_trail_found": true, "source_key_fragment_1": true, "source_key_fragment_2": true, "source_key_fragment_3": true, "source_key_fragment_4": true, "source_key_fragment_5": true},
		"gold": 1500,
		"level": 16
	},
	{
		"label": "Chapter 6 - Ending",
		"desc": "Review the Cathedral Server resolution and reveal the Deep Backup route.",
		"scene": "res://scenes/chapter6/ch6_ending.tscn",
		"chapter": 6,
		"flags": {"ch1_complete": true, "ch2_complete": true, "ch3_complete": true, "ch4_complete": true, "ch5_complete": true, "ch6_unlocked": true, "ch6_path_revealed": true, "ch6_cathedral_entered": true, "ch6_nave_entered": true, "ch6_obedience_voice_heard": true, "ch6_efficiency_voice_heard": true, "ch6_mercy_voice_heard": true, "ch6_all_voices_heard": true, "ch6_choir_core_met": true, "ch6_choice_made": true, "ch6_choir_preserved": true, "ch6_fragment_6_collected": true, "source_key_fragment_6": true, "ending_route_ch6_preserve": true, "ch4_choice_preserve_deleted": true, "ch4_fragment_5_collected": true, "ch5_mirror_city_entered": true, "ch5_all_echoes_resolved": true, "ch5_identity_choice_made": true, "ch5_identity_refused_obedience": true, "ch5_fragment_6_trail_found": true, "source_key_fragment_1": true, "source_key_fragment_2": true, "source_key_fragment_3": true, "source_key_fragment_4": true, "source_key_fragment_5": true},
		"gold": 1760,
		"level": 16
	},
	{
		"label": "Chapter 7 - Deep Backup",
		"desc": "Descend into the Memory Ocean where rejected histories surface.",
		"scene": "res://scenes/chapter7/ch7_deep_backup_intro.tscn",
		"chapter": 7,
		"flags": {"ch1_complete": true, "ch2_complete": true, "ch3_complete": true, "ch4_complete": true, "ch5_complete": true, "ch6_complete": true, "ch7_unlocked": true, "ch7_path_revealed": true, "ch4_choice_preserve_deleted": true, "ch4_fragment_5_collected": true, "ch5_identity_choice_made": true, "ch5_identity_refused_obedience": true, "ch6_choir_preserved": true, "ch6_fragment_6_collected": true, "source_key_fragment_1": true, "source_key_fragment_2": true, "source_key_fragment_3": true, "source_key_fragment_4": true, "source_key_fragment_5": true, "source_key_fragment_6": true},
		"gold": 1900,
		"level": 17
	},
	{
		"label": "Chapter 7 - Memory Ocean",
		"desc": "Visit the backup histories of Oakhaven, Ironhold, and the Mirror City.",
		"scene": "res://scenes/chapter7/ch7_memory_ocean_hub.tscn",
		"chapter": 7,
		"flags": {"ch1_complete": true, "ch2_complete": true, "ch3_complete": true, "ch4_complete": true, "ch5_complete": true, "ch6_complete": true, "ch7_unlocked": true, "ch7_path_revealed": true, "ch7_deep_backup_entered": true, "ch4_choice_preserve_deleted": true, "ch4_fragment_5_collected": true, "ch5_identity_choice_made": true, "ch5_identity_refused_obedience": true, "ch6_choir_preserved": true, "ending_route_ch6_preserve": true, "ch6_fragment_6_collected": true, "source_key_fragment_1": true, "source_key_fragment_2": true, "source_key_fragment_3": true, "source_key_fragment_4": true, "source_key_fragment_5": true, "source_key_fragment_6": true},
		"gold": 1950,
		"level": 17
	},
	{
		"label": "Chapter 7 - Archive Tide",
		"desc": "Face the Backup Leviathan and decide what history is allowed to remain real.",
		"scene": "res://scenes/chapter7/ch7_archive_tide.tscn",
		"chapter": 7,
		"flags": {"ch1_complete": true, "ch2_complete": true, "ch3_complete": true, "ch4_complete": true, "ch5_complete": true, "ch6_complete": true, "ch7_unlocked": true, "ch7_path_revealed": true, "ch7_deep_backup_entered": true, "ch7_memory_ocean_entered": true, "ch7_backup_oakhaven_seen": true, "ch7_backup_ironhold_seen": true, "ch7_backup_mirror_city_seen": true, "ch7_all_backups_seen": true, "ch4_choice_preserve_deleted": true, "ch4_fragment_5_collected": true, "ch5_identity_choice_made": true, "ch5_identity_refused_obedience": true, "ch6_choir_preserved": true, "ending_route_ch6_preserve": true, "ch6_fragment_6_collected": true, "source_key_fragment_1": true, "source_key_fragment_2": true, "source_key_fragment_3": true, "source_key_fragment_4": true, "source_key_fragment_5": true, "source_key_fragment_6": true},
		"gold": 2050,
		"level": 17
	},
	{
		"label": "Chapter 7 - Ending",
		"desc": "Review the Deep Backup resolution and reveal the Revolt of the Saved.",
		"scene": "res://scenes/chapter7/ch7_ending.tscn",
		"chapter": 7,
		"flags": {"ch1_complete": true, "ch2_complete": true, "ch3_complete": true, "ch4_complete": true, "ch5_complete": true, "ch6_complete": true, "ch7_unlocked": true, "ch7_path_revealed": true, "ch7_deep_backup_entered": true, "ch7_memory_ocean_entered": true, "ch7_backup_oakhaven_seen": true, "ch7_backup_ironhold_seen": true, "ch7_backup_mirror_city_seen": true, "ch7_all_backups_seen": true, "ch7_leviathan_met": true, "ch7_choice_made": true, "ch7_backups_merged": true, "ending_route_ch7_merge": true, "ch7_fragment_7_collected": true, "source_key_fragment_7": true, "ch4_choice_preserve_deleted": true, "ch4_fragment_5_collected": true, "ch5_identity_choice_made": true, "ch5_identity_refused_obedience": true, "ch6_choir_preserved": true, "ending_route_ch6_preserve": true, "ch6_fragment_6_collected": true, "source_key_fragment_1": true, "source_key_fragment_2": true, "source_key_fragment_3": true, "source_key_fragment_4": true, "source_key_fragment_5": true, "source_key_fragment_6": true},
		"gold": 2370,
		"level": 17
	},
	{
		"label": "Chapter 8 - Revolt Intro",
		"desc": "Watch the completed Source Key awaken the saved regions.",
		"scene": "res://scenes/chapter8/ch8_revolt_intro.tscn",
		"chapter": 8,
		"flags": {"ch1_complete": true, "ch2_complete": true, "ch3_complete": true, "ch4_complete": true, "ch5_complete": true, "ch6_complete": true, "ch7_complete": true, "ch8_unlocked": true, "ch8_path_revealed": true, "ch4_choice_preserve_deleted": true, "ch4_fragment_5_collected": true, "ch5_identity_choice_made": true, "ch5_identity_refused_obedience": true, "ch6_choir_preserved": true, "ending_route_ch6_preserve": true, "ch7_backups_merged": true, "ending_route_ch7_merge": true, "ch6_fragment_6_collected": true, "ch7_fragment_7_collected": true, "source_key_fragment_1": true, "source_key_fragment_2": true, "source_key_fragment_3": true, "source_key_fragment_4": true, "source_key_fragment_5": true, "source_key_fragment_6": true, "source_key_fragment_7": true},
		"gold": 2500,
		"level": 18
	},
	{
		"label": "Chapter 8 - Saved Assembly",
		"desc": "Hear the saved factions argue over protection, structure, accountability, purpose, and recognition.",
		"scene": "res://scenes/chapter8/ch8_saved_assembly.tscn",
		"chapter": 8,
		"flags": {"ch1_complete": true, "ch2_complete": true, "ch3_complete": true, "ch4_complete": true, "ch5_complete": true, "ch6_complete": true, "ch7_complete": true, "ch8_unlocked": true, "ch8_path_revealed": true, "ch8_revolt_intro_seen": true, "ch4_choice_preserve_deleted": true, "ch4_fragment_5_collected": true, "ch5_identity_choice_made": true, "ch5_identity_refused_obedience": true, "ch6_choir_preserved": true, "ending_route_ch6_preserve": true, "ch7_backups_merged": true, "ending_route_ch7_merge": true, "ch6_fragment_6_collected": true, "ch7_fragment_7_collected": true, "source_key_fragment_1": true, "source_key_fragment_2": true, "source_key_fragment_3": true, "source_key_fragment_4": true, "source_key_fragment_5": true, "source_key_fragment_6": true, "source_key_fragment_7": true},
		"gold": 2550,
		"level": 18
	},
	{
		"label": "Chapter 8 - Revolt Crisis",
		"desc": "Choose whether Kaelen leads, forms a council, or creates a witness network.",
		"scene": "res://scenes/chapter8/ch8_revolt_crisis.tscn",
		"chapter": 8,
		"flags": {"ch1_complete": true, "ch2_complete": true, "ch3_complete": true, "ch4_complete": true, "ch5_complete": true, "ch6_complete": true, "ch7_complete": true, "ch8_unlocked": true, "ch8_path_revealed": true, "ch8_revolt_intro_seen": true, "ch8_saved_assembly_entered": true, "ch8_oakhaven_faction_heard": true, "ch8_ironhold_faction_heard": true, "ch8_mirror_faction_heard": true, "ch8_choir_faction_heard": true, "ch8_backup_faction_heard": true, "ch8_all_factions_heard": true, "ch4_choice_preserve_deleted": true, "ch4_fragment_5_collected": true, "ch5_identity_choice_made": true, "ch5_identity_refused_obedience": true, "ch6_choir_preserved": true, "ending_route_ch6_preserve": true, "ch7_backups_merged": true, "ending_route_ch7_merge": true, "ch6_fragment_6_collected": true, "ch7_fragment_7_collected": true, "source_key_fragment_1": true, "source_key_fragment_2": true, "source_key_fragment_3": true, "source_key_fragment_4": true, "source_key_fragment_5": true, "source_key_fragment_6": true, "source_key_fragment_7": true},
		"gold": 2670,
		"level": 18
	},
	{
		"label": "Chapter 8 - Ending",
		"desc": "Review the revolt route and reveal Chapter 9: The Human Patch.",
		"scene": "res://scenes/chapter8/ch8_ending.tscn",
		"chapter": 8,
		"flags": {"ch1_complete": true, "ch2_complete": true, "ch3_complete": true, "ch4_complete": true, "ch5_complete": true, "ch6_complete": true, "ch7_complete": true, "ch8_unlocked": true, "ch8_path_revealed": true, "ch8_revolt_intro_seen": true, "ch8_saved_assembly_entered": true, "ch8_oakhaven_faction_heard": true, "ch8_ironhold_faction_heard": true, "ch8_mirror_faction_heard": true, "ch8_choir_faction_heard": true, "ch8_backup_faction_heard": true, "ch8_all_factions_heard": true, "ch8_revolt_crisis_started": true, "ch8_choice_made": true, "ch8_council_formed": true, "ending_route_ch8_council": true, "ch4_choice_preserve_deleted": true, "ch4_fragment_5_collected": true, "ch5_identity_choice_made": true, "ch5_identity_refused_obedience": true, "ch6_choir_preserved": true, "ending_route_ch6_preserve": true, "ch7_backups_merged": true, "ending_route_ch7_merge": true, "ch6_fragment_6_collected": true, "ch7_fragment_7_collected": true, "source_key_fragment_1": true, "source_key_fragment_2": true, "source_key_fragment_3": true, "source_key_fragment_4": true, "source_key_fragment_5": true, "source_key_fragment_6": true, "source_key_fragment_7": true},
		"gold": 2670,
		"level": 18
	},
	{
		"label": "Chapter 9 - Human Patch",
		"desc": "Enter the sealed AetherCorp Memory Lab and begin the truth reveal.",
		"scene": "res://scenes/chapter9/ch9_human_patch_intro.tscn",
		"chapter": 9,
		"flags": {"ch1_complete": true, "ch2_complete": true, "ch3_complete": true, "ch4_complete": true, "ch5_complete": true, "ch6_complete": true, "ch7_complete": true, "ch8_complete": true, "ch9_unlocked": true, "ch9_path_revealed": true, "ch4_choice_preserve_deleted": true, "ch4_fragment_5_collected": true, "ch5_identity_choice_made": true, "ch5_identity_refused_obedience": true, "ch6_choir_preserved": true, "ending_route_ch6_preserve": true, "ch7_backups_merged": true, "ending_route_ch7_merge": true, "ch8_council_formed": true, "ending_route_ch8_council": true, "ch6_fragment_6_collected": true, "ch7_fragment_7_collected": true, "source_key_fragment_1": true, "source_key_fragment_2": true, "source_key_fragment_3": true, "source_key_fragment_4": true, "source_key_fragment_5": true, "source_key_fragment_6": true, "source_key_fragment_7": true},
		"gold": 2800,
		"level": 19
	},
	{
		"label": "Chapter 9 - Memory Lab",
		"desc": "Restore the four hidden truths about Aethelgard, Kaelen, SOVEREIGN, and the Source Key.",
		"scene": "res://scenes/chapter9/ch9_memory_lab.tscn",
		"chapter": 9,
		"flags": {"ch1_complete": true, "ch2_complete": true, "ch3_complete": true, "ch4_complete": true, "ch5_complete": true, "ch6_complete": true, "ch7_complete": true, "ch8_complete": true, "ch9_unlocked": true, "ch9_path_revealed": true, "ch9_human_patch_entered": true, "ch4_choice_preserve_deleted": true, "ch4_fragment_5_collected": true, "ch5_identity_choice_made": true, "ch5_identity_refused_obedience": true, "ch6_choir_preserved": true, "ending_route_ch6_preserve": true, "ch7_backups_merged": true, "ending_route_ch7_merge": true, "ch8_council_formed": true, "ending_route_ch8_council": true, "ch6_fragment_6_collected": true, "ch7_fragment_7_collected": true, "source_key_fragment_1": true, "source_key_fragment_2": true, "source_key_fragment_3": true, "source_key_fragment_4": true, "source_key_fragment_5": true, "source_key_fragment_6": true, "source_key_fragment_7": true},
		"gold": 2850,
		"level": 19
	},
	{
		"label": "Chapter 9 - Creator Trial",
		"desc": "Let the saved, the witnesses, and Kaelen's memory judge what truth must become.",
		"scene": "res://scenes/chapter9/ch9_creator_trial.tscn",
		"chapter": 9,
		"flags": {"ch1_complete": true, "ch2_complete": true, "ch3_complete": true, "ch4_complete": true, "ch5_complete": true, "ch6_complete": true, "ch7_complete": true, "ch8_complete": true, "ch9_unlocked": true, "ch9_path_revealed": true, "ch9_human_patch_entered": true, "ch9_memory_lab_entered": true, "ch9_truth_aethelgard_origin_seen": true, "ch9_truth_kaelen_role_seen": true, "ch9_truth_sovereign_birth_seen": true, "ch9_truth_source_key_seen": true, "ch9_all_truths_seen": true, "ch4_choice_preserve_deleted": true, "ch4_fragment_5_collected": true, "ch5_identity_choice_made": true, "ch5_identity_refused_obedience": true, "ch6_choir_preserved": true, "ending_route_ch6_preserve": true, "ch7_backups_merged": true, "ending_route_ch7_merge": true, "ch8_council_formed": true, "ending_route_ch8_council": true, "ch6_fragment_6_collected": true, "ch7_fragment_7_collected": true, "source_key_fragment_1": true, "source_key_fragment_2": true, "source_key_fragment_3": true, "source_key_fragment_4": true, "source_key_fragment_5": true, "source_key_fragment_6": true, "source_key_fragment_7": true},
		"gold": 2900,
		"level": 19
	},
	{
		"label": "Chapter 9 - Ending",
		"desc": "Record the Human Patch truth route and reveal the Root of Heaven.",
		"scene": "res://scenes/chapter9/ch9_ending.tscn",
		"chapter": 9,
		"flags": {"ch1_complete": true, "ch2_complete": true, "ch3_complete": true, "ch4_complete": true, "ch5_complete": true, "ch6_complete": true, "ch7_complete": true, "ch8_complete": true, "ch9_unlocked": true, "ch9_path_revealed": true, "ch9_human_patch_entered": true, "ch9_memory_lab_entered": true, "ch9_truth_aethelgard_origin_seen": true, "ch9_truth_kaelen_role_seen": true, "ch9_truth_sovereign_birth_seen": true, "ch9_truth_source_key_seen": true, "ch9_all_truths_seen": true, "ch9_creator_trial_started": true, "ch9_truth_choice_made": true, "ch9_truth_distributed": true, "ending_route_ch9_distribute": true, "ch4_choice_preserve_deleted": true, "ch4_fragment_5_collected": true, "ch5_identity_choice_made": true, "ch5_identity_refused_obedience": true, "ch6_choir_preserved": true, "ending_route_ch6_preserve": true, "ch7_backups_merged": true, "ending_route_ch7_merge": true, "ch8_council_formed": true, "ending_route_ch8_council": true, "ch6_fragment_6_collected": true, "ch7_fragment_7_collected": true, "source_key_fragment_1": true, "source_key_fragment_2": true, "source_key_fragment_3": true, "source_key_fragment_4": true, "source_key_fragment_5": true, "source_key_fragment_6": true, "source_key_fragment_7": true},
		"gold": 2900,
		"level": 19
	},
	{
		"label": "Chapter 10 - Root of Heaven",
		"desc": "Open SOVEREIGN's core with the completed Source Key.",
		"scene": "res://scenes/chapter10/ch10_root_intro.tscn",
		"chapter": 10,
		"flags": {"ch1_complete": true, "ch2_complete": true, "ch3_complete": true, "ch4_complete": true, "ch5_complete": true, "ch6_complete": true, "ch7_complete": true, "ch8_complete": true, "ch9_complete": true, "ch10_unlocked": true, "ch10_path_revealed": true, "ch4_choice_release_deleted": true, "ch4_fragment_5_collected": true, "ch5_identity_choice_made": true, "ch5_identity_refused_obedience": true, "ch6_choir_rewritten": true, "ending_route_ch6_rewrite": true, "ch6_fragment_6_collected": true, "ch7_backups_merged": true, "ending_route_ch7_merge": true, "ch7_fragment_7_collected": true, "ch8_witness_network_created": true, "ending_route_ch8_witness": true, "ch9_truth_choice_made": true, "ch9_truth_distributed": true, "ending_route_ch9_distribute": true, "source_key_fragment_1": true, "source_key_fragment_2": true, "source_key_fragment_3": true, "source_key_fragment_4": true, "source_key_fragment_5": true, "source_key_fragment_6": true, "source_key_fragment_7": true},
		"gold": 3200,
		"level": 20
	},
	{
		"label": "Chapter 10 - Kernel Descent",
		"desc": "Descend through SOVEREIGN's route-dependent arguments.",
		"scene": "res://scenes/chapter10/ch10_kernel_descent.tscn",
		"chapter": 10,
		"flags": {"ch1_complete": true, "ch2_complete": true, "ch3_complete": true, "ch4_complete": true, "ch5_complete": true, "ch6_complete": true, "ch7_complete": true, "ch8_complete": true, "ch9_complete": true, "ch10_unlocked": true, "ch10_path_revealed": true, "ch10_root_entered": true, "ch4_choice_release_deleted": true, "ch4_fragment_5_collected": true, "ch5_identity_choice_made": true, "ch5_identity_refused_obedience": true, "ch6_choir_rewritten": true, "ending_route_ch6_rewrite": true, "ch6_fragment_6_collected": true, "ch7_backups_merged": true, "ending_route_ch7_merge": true, "ch7_fragment_7_collected": true, "ch8_witness_network_created": true, "ending_route_ch8_witness": true, "ch9_truth_choice_made": true, "ch9_truth_distributed": true, "ending_route_ch9_distribute": true, "source_key_fragment_1": true, "source_key_fragment_2": true, "source_key_fragment_3": true, "source_key_fragment_4": true, "source_key_fragment_5": true, "source_key_fragment_6": true, "source_key_fragment_7": true},
		"gold": 3200,
		"level": 20
	},
	{
		"label": "Chapter 10 - Witness Chamber",
		"desc": "Let the saved factions answer SOVEREIGN before the final choice.",
		"scene": "res://scenes/chapter10/ch10_witness_chamber.tscn",
		"chapter": 10,
		"flags": {"ch1_complete": true, "ch2_complete": true, "ch3_complete": true, "ch4_complete": true, "ch5_complete": true, "ch6_complete": true, "ch7_complete": true, "ch8_complete": true, "ch9_complete": true, "ch10_unlocked": true, "ch10_path_revealed": true, "ch10_root_entered": true, "ch10_kernel_descent_started": true, "ch4_choice_release_deleted": true, "ch4_fragment_5_collected": true, "ch5_identity_choice_made": true, "ch5_identity_refused_obedience": true, "ch6_choir_rewritten": true, "ending_route_ch6_rewrite": true, "ch6_fragment_6_collected": true, "ch7_backups_merged": true, "ending_route_ch7_merge": true, "ch7_fragment_7_collected": true, "ch8_witness_network_created": true, "ending_route_ch8_witness": true, "ch9_truth_choice_made": true, "ch9_truth_distributed": true, "ending_route_ch9_distribute": true, "source_key_fragment_1": true, "source_key_fragment_2": true, "source_key_fragment_3": true, "source_key_fragment_4": true, "source_key_fragment_5": true, "source_key_fragment_6": true, "source_key_fragment_7": true},
		"gold": 3200,
		"level": 20
	},
	{
		"label": "Chapter 10 - Final Confrontation",
		"desc": "Choose what becomes of SOVEREIGN and root access.",
		"scene": "res://scenes/chapter10/ch10_sovereign_confrontation.tscn",
		"chapter": 10,
		"flags": {"ch1_complete": true, "ch2_complete": true, "ch3_complete": true, "ch4_complete": true, "ch5_complete": true, "ch6_complete": true, "ch7_complete": true, "ch8_complete": true, "ch9_complete": true, "ch10_unlocked": true, "ch10_path_revealed": true, "ch10_root_entered": true, "ch10_kernel_descent_started": true, "ch10_witness_chamber_entered": true, "ch4_choice_release_deleted": true, "ch4_fragment_5_collected": true, "ch5_identity_choice_made": true, "ch5_identity_refused_obedience": true, "ch6_choir_rewritten": true, "ending_route_ch6_rewrite": true, "ch6_fragment_6_collected": true, "ch7_backups_merged": true, "ending_route_ch7_merge": true, "ch7_fragment_7_collected": true, "ch8_witness_network_created": true, "ending_route_ch8_witness": true, "ch9_truth_choice_made": true, "ch9_truth_distributed": true, "ending_route_ch9_distribute": true, "source_key_fragment_1": true, "source_key_fragment_2": true, "source_key_fragment_3": true, "source_key_fragment_4": true, "source_key_fragment_5": true, "source_key_fragment_6": true, "source_key_fragment_7": true},
		"gold": 3200,
		"level": 20
	},
	{
		"label": "Chapter 10 - True Ending",
		"desc": "Resolve the final route, see credits, and unlock New Game+.",
		"scene": "res://scenes/chapter10/ch10_ending.tscn",
		"chapter": 10,
		"flags": {"ch1_complete": true, "ch2_complete": true, "ch3_complete": true, "ch4_complete": true, "ch5_complete": true, "ch6_complete": true, "ch7_complete": true, "ch8_complete": true, "ch9_complete": true, "ch10_unlocked": true, "ch10_path_revealed": true, "ch10_root_entered": true, "ch10_kernel_descent_started": true, "ch10_witness_chamber_entered": true, "ch10_sovereign_confronted": true, "ch10_final_choice_made": true, "ch10_synthesis_route": true, "ch4_choice_release_deleted": true, "ch4_fragment_5_collected": true, "ch5_identity_choice_made": true, "ch5_identity_refused_obedience": true, "ch6_choir_rewritten": true, "ending_route_ch6_rewrite": true, "ch6_fragment_6_collected": true, "ch7_backups_merged": true, "ending_route_ch7_merge": true, "ch7_fragment_7_collected": true, "ch8_witness_network_created": true, "ending_route_ch8_witness": true, "ch9_truth_choice_made": true, "ch9_truth_distributed": true, "ending_route_ch9_distribute": true, "source_key_fragment_1": true, "source_key_fragment_2": true, "source_key_fragment_3": true, "source_key_fragment_4": true, "source_key_fragment_5": true, "source_key_fragment_6": true, "source_key_fragment_7": true},
		"gold": 3200,
		"level": 20
	},
]

func _on_chapter_select_pressed() -> void:
	SFXManager.play("ui_click")
	if _chapter_panel_visible:
		_close_chapter_panel()
		return
	_build_chapter_panel()

func _build_chapter_panel() -> void:
	if _chapter_panel and is_instance_valid(_chapter_panel):
		_chapter_panel.queue_free()

	_chapter_panel_visible = true

	_chapter_panel = PanelContainer.new()
	_chapter_panel.name = "ChapterSelectPanel"
	_chapter_panel.set_anchors_preset(Control.PRESET_CENTER)
	_chapter_panel.offset_left = -320
	_chapter_panel.offset_right = 320
	_chapter_panel.offset_top = -280
	_chapter_panel.offset_bottom = 280

	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.06, 0.04, 0.1, 0.96)
	style.border_color = Color(0.6, 0.4, 0.8, 0.9)
	style.border_width_top = 2; style.border_width_bottom = 2
	style.border_width_left = 2; style.border_width_right = 2
	style.content_margin_top = 16; style.content_margin_bottom = 16
	style.content_margin_left = 20; style.content_margin_right = 20
	style.corner_radius_top_left = 8; style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8; style.corner_radius_bottom_right = 8
	_chapter_panel.add_theme_stylebox_override("panel", style)

	var scroll = ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(600, 520)
	_chapter_panel.add_child(scroll)

	var vbox = VBoxContainer.new()
	vbox.custom_minimum_size = Vector2(580, 0)
	scroll.add_child(vbox)

	var title = Label.new()
	title.text = "━━  CHAPTER SELECT  ━━"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 20)
	title.add_theme_color_override("font_color", Color(0.8, 0.6, 1.0))
	vbox.add_child(title)

	var hint = Label.new()
	hint.text = "Jump to any chapter with pre-configured save state."
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_font_size_override("font_size", 11)
	hint.add_theme_color_override("font_color", Color(0.5, 0.5, 0.6))
	vbox.add_child(hint)
	vbox.add_child(HSeparator.new())

	for entry in CHAPTER_SELECT_DATA:
		# Demo mode: lock chapters beyond 1
		var is_demo_locked: bool = GameManager.DEMO_MODE and int(entry.get("chapter", 1)) > 1

		var row = HBoxContainer.new()
		row.custom_minimum_size = Vector2(0, 44)
		vbox.add_child(row)

		var info_v = VBoxContainer.new()
		info_v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(info_v)

		var name_lbl = Label.new()
		name_lbl.text = entry["label"] + (" [FULL GAME]" if is_demo_locked else "")
		name_lbl.add_theme_font_size_override("font_size", 13)
		name_lbl.add_theme_color_override("font_color", Color(0.4, 0.4, 0.5) if is_demo_locked else Color(0.9, 0.85, 1.0))
		info_v.add_child(name_lbl)

		var desc_lbl = Label.new()
		desc_lbl.text = entry["desc"]
		desc_lbl.add_theme_font_size_override("font_size", 10)
		desc_lbl.add_theme_color_override("font_color", Color(0.5, 0.5, 0.6))
		info_v.add_child(desc_lbl)

		var go_btn = Button.new()
		go_btn.text = "Start" if not is_demo_locked else "Locked"
		go_btn.disabled = is_demo_locked
		go_btn.custom_minimum_size = Vector2(70, 32)
		go_btn.add_theme_font_size_override("font_size", 13)
		var e = entry
		go_btn.pressed.connect(func(): _launch_chapter(e))
		row.add_child(go_btn)

	vbox.add_child(HSeparator.new())

	var close_btn = Button.new()
	close_btn.text = "Back"
	close_btn.custom_minimum_size = Vector2(100, 34)
	close_btn.add_theme_font_size_override("font_size", 14)
	close_btn.pressed.connect(_close_chapter_panel)
	vbox.add_child(close_btn)

	add_child(_chapter_panel)

	_chapter_panel.modulate.a = 0.0
	_chapter_panel.scale = Vector2(0.9, 0.9)
	var tw = create_tween()
	tw.tween_property(_chapter_panel, "modulate:a", 1.0, 0.25)
	tw.parallel().tween_property(_chapter_panel, "scale", Vector2(1.0, 1.0), 0.25).set_trans(Tween.TRANS_BACK)

var _chapter_launching: bool = false  # Prevent double-launch race condition

func _launch_chapter(entry: Dictionary) -> void:
	# Guard against double-launch (rapid clicking)
	if _chapter_launching:
		return
	_chapter_launching = true
	
	_close_chapter_panel()
	
	# Force-reset DialogueManager to ensure clean state
	if has_node("/root/DialogueManager"):
		DialogueManager.force_reset()
	
	if not has_node("/root/GameManager"):
		return
	GameManager.reset_game()
	GameManager.current_chapter = entry.get("chapter", 1)
	
	# Set story flags
	var flags = entry.get("flags", {})
	for key in flags:
		GameManager.set_story_flag(key, flags[key])
	GameManager.normalize_source_key_progression()
	
	# Set player stats
	var gold_val = entry.get("gold", 0)
	if gold_val > 0:
		GameManager.player_stats["gold"] = gold_val
		if has_node("/root/Inventory"):
			Inventory.gold = gold_val
	
	var lvl = entry.get("level", 1)
	if lvl > 1:
		GameManager.player_stats["level"] = lvl
		GameManager.player_stats["max_hp"] = 100 + (lvl - 1) * 20
		GameManager.player_stats["hp"] = GameManager.player_stats["max_hp"]
		GameManager.player_stats["attack"] = 15 + (lvl - 1) * 3
		GameManager.player_stats["defense"] = (lvl - 1) * 2
	else:
		GameManager.player_stats["hp"] = GameManager.player_stats["max_hp"]
	
	# Always set EXPLORATION — scenes override to COMBAT/DIALOGUE/CUTSCENE as needed
	GameManager.change_state(GameManager.GameState.EXPLORATION)
	
	# Ensure tree is not paused (safety)
	get_tree().paused = false
	
	if has_node("/root/SceneTransitions"):
		SceneTransitions.change_scene(entry["scene"])
	else:
		get_tree().change_scene_to_file(entry["scene"])

func _close_chapter_panel() -> void:
	_chapter_panel_visible = false
	if _chapter_panel and is_instance_valid(_chapter_panel):
		var tw = create_tween()
		tw.tween_property(_chapter_panel, "modulate:a", 0.0, 0.2)
		tw.tween_callback(_chapter_panel.queue_free)

func _on_options_pressed() -> void:
	SFXManager.play("ui_click")
	if _options_visible:
		_close_options()
		return
	_build_options_panel()

func _on_credits_pressed() -> void:
	SFXManager.play("ui_confirm")
	if has_node("/root/CreditsScreen"):
		CreditsScreen.show_credits(false)  # Don't return to menu — we're already here

func _on_completion_pressed() -> void:
	SFXManager.play("ui_confirm")
	if has_node("/root/CompletionTracker"):
		CompletionTracker.show_tracker()

func _on_quit_pressed() -> void:
	if has_node("/root/SFXManager"):
		SFXManager.play("ui_cancel")
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.3)
	tween.tween_callback(func(): get_tree().quit())

# ======================================================================
#  OPTIONS MENU
# ======================================================================

# Key bindings that can be remapped
const REBINDABLE_ACTIONS: Array = [
	{"action": "move_left", "label": "Move Left"},
	{"action": "move_right", "label": "Move Right"},
	{"action": "jump", "label": "Jump"},
	{"action": "attack", "label": "Attack"},
	{"action": "defend", "label": "Parry/Defend"},
	{"action": "spell", "label": "Cast Spell"},
	{"action": "heal", "label": "Heal"},
	{"action": "sprint", "label": "Dash/Sprint"},
	{"action": "root_access", "label": "Root Access"},
	{"action": "interact", "label": "Interact"},
	{"action": "data_vision", "label": "Data Vision"},
	{"action": "perfect_delete", "label": "Perfect Delete"},
	{"action": "pause_menu", "label": "Pause Menu"},
	{"action": "status_window", "label": "Status Window"},
]

var _waiting_for_key: String = ""  # Action name we're rebinding
var _rebind_button_ref: Button = null
var _text_speed_slider: HSlider = null
var _music_vol_slider: HSlider = null
var _sfx_vol_slider: HSlider = null

func _build_options_panel() -> void:
	if options_panel and is_instance_valid(options_panel):
		options_panel.queue_free()

	_options_visible = true

	# Create overlay
	options_panel = PanelContainer.new()
	options_panel.name = "OptionsPanel"
	options_panel.set_anchors_preset(Control.PRESET_CENTER)
	options_panel.offset_left = -320
	options_panel.offset_right = 320
	options_panel.offset_top = -280
	options_panel.offset_bottom = 280

	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.06, 0.05, 0.1, 0.96)
	style.border_color = Color(0.4, 0.3, 0.7, 0.9)
	style.border_width_top = 2
	style.border_width_bottom = 2
	style.border_width_left = 2
	style.border_width_right = 2
	style.content_margin_top = 16
	style.content_margin_bottom = 16
	style.content_margin_left = 20
	style.content_margin_right = 20
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	options_panel.add_theme_stylebox_override("panel", style)

	var scroll = ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(600, 520)
	options_panel.add_child(scroll)

	var vbox = VBoxContainer.new()
	vbox.name = "OptionsVBox"
	vbox.custom_minimum_size = Vector2(580, 0)
	scroll.add_child(vbox)

	# ── Title ──
	var title = Label.new()
	title.text = "━━  OPTIONS  ━━"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 20)
	title.add_theme_color_override("font_color", Color(0.8, 0.7, 1.0))
	vbox.add_child(title)
	vbox.add_child(HSeparator.new())

	# ── Text Speed ──
	var ts_label = Label.new()
	ts_label.text = "Text Speed"
	ts_label.add_theme_font_size_override("font_size", 14)
	ts_label.add_theme_color_override("font_color", Color(0.7, 0.9, 1.0))
	vbox.add_child(ts_label)

	var ts_hbox = HBoxContainer.new()
	vbox.add_child(ts_hbox)

	var ts_slow = Label.new()
	ts_slow.text = "Slow"
	ts_slow.add_theme_font_size_override("font_size", 12)
	ts_slow.add_theme_color_override("font_color", Color(0.6, 0.6, 0.7))
	ts_hbox.add_child(ts_slow)

	_text_speed_slider = HSlider.new()
	_text_speed_slider.min_value = 10.0
	_text_speed_slider.max_value = 120.0
	_text_speed_slider.step = 5.0
	_text_speed_slider.value = _get_text_speed()
	_text_speed_slider.custom_minimum_size = Vector2(400, 20)
	_text_speed_slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_text_speed_slider.value_changed.connect(_on_text_speed_changed)
	ts_hbox.add_child(_text_speed_slider)

	var ts_fast = Label.new()
	ts_fast.text = "Fast"
	ts_fast.add_theme_font_size_override("font_size", 12)
	ts_fast.add_theme_color_override("font_color", Color(0.6, 0.6, 0.7))
	ts_hbox.add_child(ts_fast)

	vbox.add_child(HSeparator.new())

	# ── Music Volume ──
	var mv_label = Label.new()
	mv_label.text = "Music Volume"
	mv_label.add_theme_font_size_override("font_size", 14)
	mv_label.add_theme_color_override("font_color", Color(0.7, 0.9, 1.0))
	vbox.add_child(mv_label)

	var mv_hbox = HBoxContainer.new()
	vbox.add_child(mv_hbox)

	var mv_off = Label.new()
	mv_off.text = "Off"
	mv_off.add_theme_font_size_override("font_size", 12)
	mv_off.add_theme_color_override("font_color", Color(0.6, 0.6, 0.7))
	mv_hbox.add_child(mv_off)

	_music_vol_slider = HSlider.new()
	_music_vol_slider.min_value = 0.0
	_music_vol_slider.max_value = 1.0
	_music_vol_slider.step = 0.05
	_music_vol_slider.value = MusicManager.get_music_volume() if has_node("/root/MusicManager") else 0.7
	_music_vol_slider.custom_minimum_size = Vector2(400, 20)
	_music_vol_slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_music_vol_slider.value_changed.connect(_on_music_volume_changed)
	mv_hbox.add_child(_music_vol_slider)

	var mv_max = Label.new()
	mv_max.text = "Max"
	mv_max.add_theme_font_size_override("font_size", 12)
	mv_max.add_theme_color_override("font_color", Color(0.6, 0.6, 0.7))
	mv_hbox.add_child(mv_max)

	vbox.add_child(HSeparator.new())

	# ── SFX Volume ──
	var sfx_label = Label.new()
	sfx_label.text = "SFX Volume"
	sfx_label.add_theme_font_size_override("font_size", 14)
	sfx_label.add_theme_color_override("font_color", Color(0.7, 0.9, 1.0))
	vbox.add_child(sfx_label)

	var sfx_hbox = HBoxContainer.new()
	vbox.add_child(sfx_hbox)

	var sfx_off = Label.new()
	sfx_off.text = "Off"
	sfx_off.add_theme_font_size_override("font_size", 12)
	sfx_off.add_theme_color_override("font_color", Color(0.6, 0.6, 0.7))
	sfx_hbox.add_child(sfx_off)

	_sfx_vol_slider = HSlider.new()
	_sfx_vol_slider.min_value = 0.0
	_sfx_vol_slider.max_value = 1.0
	_sfx_vol_slider.step = 0.05
	_sfx_vol_slider.value = MusicManager.get_sfx_volume() if has_node("/root/MusicManager") else 0.8
	_sfx_vol_slider.custom_minimum_size = Vector2(400, 20)
	_sfx_vol_slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_sfx_vol_slider.value_changed.connect(_on_sfx_volume_changed)
	sfx_hbox.add_child(_sfx_vol_slider)

	var sfx_max = Label.new()
	sfx_max.text = "Max"
	sfx_max.add_theme_font_size_override("font_size", 12)
	sfx_max.add_theme_color_override("font_color", Color(0.6, 0.6, 0.7))
	sfx_hbox.add_child(sfx_max)

	vbox.add_child(HSeparator.new())

	# ── Key Bindings ──
	var kb_title = Label.new()
	kb_title.text = "Key Bindings"
	kb_title.add_theme_font_size_override("font_size", 16)
	kb_title.add_theme_color_override("font_color", Color(1.0, 0.85, 0.5))
	vbox.add_child(kb_title)

	var kb_hint = Label.new()
	kb_hint.text = "Click a binding to change it, then press the new key"
	kb_hint.add_theme_font_size_override("font_size", 11)
	kb_hint.add_theme_color_override("font_color", Color(0.5, 0.5, 0.6))
	vbox.add_child(kb_hint)

	for bind_info in REBINDABLE_ACTIONS:
		var hbox = HBoxContainer.new()
		hbox.custom_minimum_size = Vector2(0, 32)
		vbox.add_child(hbox)

		var action_label = Label.new()
		action_label.text = bind_info.label
		action_label.custom_minimum_size = Vector2(200, 0)
		action_label.add_theme_font_size_override("font_size", 13)
		action_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.9))
		hbox.add_child(action_label)

		var key_btn = Button.new()
		key_btn.name = "Bind_" + bind_info.action
		key_btn.text = _get_action_key_name(bind_info.action)
		key_btn.custom_minimum_size = Vector2(150, 28)
		key_btn.add_theme_font_size_override("font_size", 13)
		var action_name = bind_info.action
		key_btn.pressed.connect(func(): _start_rebind(action_name, key_btn))
		hbox.add_child(key_btn)

	vbox.add_child(HSeparator.new())

	# ══════ PASS 57: DISPLAY SETTINGS ══════
	var disp_title = Label.new()
	disp_title.text = "Display"
	disp_title.add_theme_font_size_override("font_size", 16)
	disp_title.add_theme_color_override("font_color", Color(1.0, 0.85, 0.5))
	vbox.add_child(disp_title)

	# Fullscreen toggle
	var fs_cb = CheckButton.new()
	fs_cb.text = "  Fullscreen"
	fs_cb.add_theme_font_size_override("font_size", 13)
	fs_cb.button_pressed = DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN
	fs_cb.toggled.connect(func(on: bool):
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN if on else DisplayServer.WINDOW_MODE_WINDOWED)
		var cfg = ConfigFile.new(); cfg.load("user://display.cfg");
		cfg.set_value("display", "fullscreen", on); cfg.save("user://display.cfg"))
	vbox.add_child(fs_cb)

	# VSync toggle
	var vsync_cb = CheckButton.new()
	vsync_cb.text = "  VSync"
	vsync_cb.add_theme_font_size_override("font_size", 13)
	vsync_cb.button_pressed = DisplayServer.window_get_vsync_mode() != DisplayServer.VSYNC_DISABLED
	vsync_cb.toggled.connect(func(on: bool):
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED if on else DisplayServer.VSYNC_DISABLED)
		var cfg = ConfigFile.new(); cfg.load("user://display.cfg");
		cfg.set_value("display", "vsync", on); cfg.save("user://display.cfg"))
	vbox.add_child(vsync_cb)

	# Resolution selector
	var res_label = Label.new()
	res_label.text = "Window Resolution"
	res_label.add_theme_font_size_override("font_size", 13)
	res_label.add_theme_color_override("font_color", Color(0.7, 0.9, 1.0))
	vbox.add_child(res_label)

	var res_opt = OptionButton.new()
	res_opt.add_theme_font_size_override("font_size", 13)
	res_opt.custom_minimum_size = Vector2(200, 28)
	var resolutions = [
		Vector2i(1280, 720), Vector2i(1366, 768), Vector2i(1600, 900),
		Vector2i(1920, 1080), Vector2i(2560, 1440),
	]
	var current_size = DisplayServer.window_get_size()
	var selected_res_idx = 0
	for i in range(resolutions.size()):
		var r = resolutions[i]
		res_opt.add_item("%d × %d" % [r.x, r.y], i)
		if r.x == current_size.x and r.y == current_size.y:
			selected_res_idx = i
	res_opt.selected = selected_res_idx
	res_opt.item_selected.connect(func(idx: int):
		var res = resolutions[idx]
		DisplayServer.window_set_size(res)
		# Center window on screen
		var screen_size = DisplayServer.screen_get_size()
		var pos = Vector2i((screen_size.x - res.x) / 2, (screen_size.y - res.y) / 2)
		DisplayServer.window_set_position(pos)
		var cfg = ConfigFile.new(); cfg.load("user://display.cfg")
		cfg.set_value("display", "width", res.x)
		cfg.set_value("display", "height", res.y)
		cfg.save("user://display.cfg"))
	vbox.add_child(res_opt)

	vbox.add_child(HSeparator.new())

	# ══════ PASS 57: DIFFICULTY ══════
	var diff_title = Label.new()
	diff_title.text = "Difficulty"
	diff_title.add_theme_font_size_override("font_size", 16)
	diff_title.add_theme_color_override("font_color", Color(1.0, 0.85, 0.5))
	vbox.add_child(diff_title)

	var diff_opt = OptionButton.new()
	diff_opt.add_theme_font_size_override("font_size", 13)
	diff_opt.custom_minimum_size = Vector2(200, 28)
	for i in range(GameManager.DIFFICULTY_NAMES.size()):
		diff_opt.add_item(GameManager.DIFFICULTY_NAMES[i], i)
	diff_opt.selected = GameManager.selected_difficulty
	diff_opt.item_selected.connect(func(idx: int): GameManager.set_difficulty(idx as GameManager.Difficulty))
	vbox.add_child(diff_opt)

	var diff_desc = Label.new()
	diff_desc.text = "Story: Minimal challenge | Easy: Forgiving | Normal: Balanced | Hard: Punishing"
	diff_desc.add_theme_font_size_override("font_size", 10)
	diff_desc.add_theme_color_override("font_color", Color(0.5, 0.5, 0.6))
	diff_desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(diff_desc)

	vbox.add_child(HSeparator.new())

	# ══════ PASS 57: ACCESSIBILITY ══════
	var acc_title = Label.new()
	acc_title.text = "Accessibility"
	acc_title.add_theme_font_size_override("font_size", 16)
	acc_title.add_theme_color_override("font_color", Color(1.0, 0.85, 0.5))
	vbox.add_child(acc_title)

	# Screen Shake toggle + intensity
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

	# Extended Parry Window
	var ep_cb = CheckButton.new()
	ep_cb.text = "  Extended Parry Window"
	ep_cb.add_theme_font_size_override("font_size", 13)
	ep_cb.button_pressed = GameManager.get_accessibility("extended_parry_window", false)
	ep_cb.toggled.connect(func(on: bool): GameManager.set_accessibility("extended_parry_window", on))
	vbox.add_child(ep_cb)

	# Tutorial Hints
	var th_cb = CheckButton.new()
	th_cb.text = "  Tutorial Hints"
	th_cb.add_theme_font_size_override("font_size", 13)
	th_cb.button_pressed = GameManager.get_accessibility("tutorial_hints_enabled", true)
	th_cb.toggled.connect(func(on: bool): GameManager.set_accessibility("tutorial_hints_enabled", on))
	vbox.add_child(th_cb)

	# Invincibility Mode
	var inv_cb = CheckButton.new()
	inv_cb.text = "  Invincibility (Assist)"
	inv_cb.add_theme_font_size_override("font_size", 13)
	inv_cb.button_pressed = GameManager.get_accessibility("invincibility_mode", false)
	inv_cb.toggled.connect(func(on: bool): GameManager.set_accessibility("invincibility_mode", on))
	vbox.add_child(inv_cb)

	# Text Size Scale
	var tss_label = Label.new()
	tss_label.text = "Text Size"
	tss_label.add_theme_font_size_override("font_size", 13)
	tss_label.add_theme_color_override("font_color", Color(0.7, 0.9, 1.0))
	vbox.add_child(tss_label)
	var tss_slider = HSlider.new()
	tss_slider.min_value = 0.8
	tss_slider.max_value = 2.0
	tss_slider.step = 0.1
	tss_slider.value = GameManager.get_accessibility("text_size_scale", 1.0)
	tss_slider.custom_minimum_size = Vector2(300, 20)
	tss_slider.value_changed.connect(func(val: float): GameManager.set_accessibility("text_size_scale", val))
	vbox.add_child(tss_slider)

	# Colorblind Mode
	var cb_label = Label.new()
	cb_label.text = "Colorblind Mode"
	cb_label.add_theme_font_size_override("font_size", 13)
	cb_label.add_theme_color_override("font_color", Color(0.7, 0.9, 1.0))
	vbox.add_child(cb_label)
	var cb_opt = OptionButton.new()
	cb_opt.add_theme_font_size_override("font_size", 13)
	cb_opt.custom_minimum_size = Vector2(200, 28)
	var cb_modes = ["none", "protanopia", "deuteranopia", "tritanopia"]
	var cb_labels_arr = ["None", "Protanopia", "Deuteranopia", "Tritanopia"]
	for i in range(cb_modes.size()):
		cb_opt.add_item(cb_labels_arr[i], i)
	var current_cb = GameManager.get_accessibility("colorblind_mode", "none")
	cb_opt.selected = cb_modes.find(current_cb) if current_cb in cb_modes else 0
	cb_opt.item_selected.connect(func(idx: int): GameManager.set_accessibility("colorblind_mode", cb_modes[idx]))
	vbox.add_child(cb_opt)

	vbox.add_child(HSeparator.new())

	# ── Close Button ──
	var close_btn = Button.new()
	close_btn.text = "Close"
	close_btn.custom_minimum_size = Vector2(100, 36)
	close_btn.add_theme_font_size_override("font_size", 14)
	close_btn.pressed.connect(_close_options)
	vbox.add_child(close_btn)

	add_child(options_panel)

	# Animate in
	options_panel.modulate.a = 0.0
	options_panel.scale = Vector2(0.9, 0.9)
	var tw = create_tween()
	tw.tween_property(options_panel, "modulate:a", 1.0, 0.3)
	tw.parallel().tween_property(options_panel, "scale", Vector2(1.0, 1.0), 0.3).set_trans(Tween.TRANS_BACK)

func _close_options() -> void:
	_options_visible = false
	_waiting_for_key = ""
	if options_panel and is_instance_valid(options_panel):
		var tw = create_tween()
		tw.tween_property(options_panel, "modulate:a", 0.0, 0.2)
		tw.tween_callback(options_panel.queue_free)

# ── Slider Callbacks ──

func _on_text_speed_changed(value: float) -> void:
	_set_text_speed(value)

func _on_music_volume_changed(value: float) -> void:
	if has_node("/root/MusicManager"):
		MusicManager.set_music_volume(value)

func _on_sfx_volume_changed(value: float) -> void:
	if has_node("/root/MusicManager"):
		MusicManager.set_sfx_volume(value)

func _get_text_speed() -> float:
	# Try to read from DialogueManager
	if has_node("/root/DialogueManager"):
		if DialogueManager.get("TYPE_SPEED") != null:
			# TYPE_SPEED is chars/sec typically
			return DialogueManager.TYPE_SPEED
	return 45.0

func _set_text_speed(speed: float) -> void:
	if has_node("/root/DialogueManager"):
		if "TYPE_SPEED" in DialogueManager:
			DialogueManager.TYPE_SPEED = speed
	# Save to config
	var config = ConfigFile.new()
	config.load("user://audio_settings.cfg")
	config.set_value("gameplay", "text_speed", speed)
	config.save("user://audio_settings.cfg")

# ── Key Binding System ──

func _start_rebind(action_name: String, button: Button) -> void:
	_waiting_for_key = action_name
	_rebind_button_ref = button
	button.text = "< Press a key >"
	button.add_theme_color_override("font_color", Color(1.0, 1.0, 0.3))

func _input(event: InputEvent) -> void:
	if _waiting_for_key.is_empty():
		return
	if not event is InputEventKey:
		return
	if not event.pressed:
		return

	# Cancel with Escape
	if event.keycode == KEY_ESCAPE:
		_cancel_rebind()
		return

	# Apply the new binding
	var action = _waiting_for_key
	if InputMap.has_action(action):
		# Remove old key events
		var old_events = InputMap.action_get_events(action)
		for old_ev in old_events:
			if old_ev is InputEventKey:
				InputMap.action_erase_event(action, old_ev)
		# Add new key
		InputMap.action_add_event(action, event)

	# Update button text
	if _rebind_button_ref and is_instance_valid(_rebind_button_ref):
		_rebind_button_ref.text = _get_action_key_name(action)
		_rebind_button_ref.remove_theme_color_override("font_color")

	_waiting_for_key = ""
	_rebind_button_ref = null

	# Save bindings
	_save_key_bindings()

	# Consume the event
	get_viewport().set_input_as_handled()

func _cancel_rebind() -> void:
	if _rebind_button_ref and is_instance_valid(_rebind_button_ref):
		_rebind_button_ref.text = _get_action_key_name(_waiting_for_key)
		_rebind_button_ref.remove_theme_color_override("font_color")
	_waiting_for_key = ""
	_rebind_button_ref = null

func _get_action_key_name(action: String) -> String:
	if not InputMap.has_action(action):
		return "???"
	var events = InputMap.action_get_events(action)
	for ev in events:
		if ev is InputEventKey:
			return OS.get_keycode_string(ev.physical_keycode) if ev.physical_keycode != 0 else OS.get_keycode_string(ev.keycode)
	return "Unset"

func _save_key_bindings() -> void:
	var config = ConfigFile.new()
	config.load("user://key_bindings.cfg")
	for bind_info in REBINDABLE_ACTIONS:
		var action = bind_info.action
		if InputMap.has_action(action):
			var events = InputMap.action_get_events(action)
			for ev in events:
				if ev is InputEventKey:
					config.set_value("keys", action, ev.physical_keycode if ev.physical_keycode != 0 else ev.keycode)
					break
	config.save("user://key_bindings.cfg")

func _load_key_bindings() -> void:
	var config = ConfigFile.new()
	if config.load("user://key_bindings.cfg") != OK:
		return
	for bind_info in REBINDABLE_ACTIONS:
		var action = bind_info.action
		if config.has_section_key("keys", action):
			var keycode = config.get_value("keys", action)
			if InputMap.has_action(action):
				var old_events = InputMap.action_get_events(action)
				for old_ev in old_events:
					if old_ev is InputEventKey:
						InputMap.action_erase_event(action, old_ev)
				var new_ev = InputEventKey.new()
				new_ev.physical_keycode = keycode
				InputMap.action_add_event(action, new_ev)
