extends Node
## ==========================================================================
## SIDE QUEST MANAGER — Optional content, hidden areas, and completionist goals
## ==========================================================================
## Autoload singleton: SideQuestManager
## Provides optional objectives that reward exploration and engagement
## beyond the main story path. Quests are discovered through exploration,
## NPC interactions, and environmental clues.
## ==========================================================================

signal quest_discovered(quest_id: String)
signal quest_updated(quest_id: String, step: int)
signal quest_completed(quest_id: String)
signal secret_found(secret_id: String)

# ── Quest States ──────────────────────────────────────────────────────
enum QuestState { HIDDEN, DISCOVERED, ACTIVE, COMPLETED, FAILED }

# ── Active Quests ─────────────────────────────────────────────────────
var quests: Dictionary = {}  # quest_id → {state, current_step, data}
var secrets_found: Array[String] = []
var _notification_queue: Array[Dictionary] = []
var _processing_notification: bool = false

# ── Quest Definitions ─────────────────────────────────────────────────
const QUEST_DATABASE: Dictionary = {
	# ═══ Chapter 1: Oakhaven Side Quests ═══
	"oakhaven_lost_memories": {
		"name": "Lost Memories",
		"chapter": 1,
		"description": "Find 3 corrupted memory fragments scattered around Oakhaven to unlock a hidden NPC's backstory.",
		"steps": ["Find Memory Fragment 1 (near the well)", "Find Memory Fragment 2 (behind the apothecary)", "Find Memory Fragment 3 (in the auction house basement)", "Return to the flickering NPC"],
		"rewards": {"xp": 150, "gold": 75, "item": "memory_crystal"},
		"discovery_hint": "A flickering NPC near the village square seems stuck in a loop, murmuring about 'pieces of herself'...",
	},
	"oakhaven_corrupted_cellar": {
		"name": "The Corrupted Cellar",
		"chapter": 1,
		"description": "A hidden cellar beneath the blacksmith contains a mini-boss: a Corrupted Forge Golem.",
		"steps": ["Discover the cellar entrance", "Defeat the Corrupted Forge Golem", "Claim the Forge Heart"],
		"rewards": {"xp": 200, "gold": 100, "item": "forge_heart", "stat_boost": {"attack": 3}},
		"discovery_hint": "The blacksmith's hammer strikes create sparks that phase through the floor...",
	},
	"oakhaven_herbalist_favor": {
		"name": "The Herbalist's Favor",
		"chapter": 1,
		"description": "Gather 3 Glitch Herbs from the outskirts for the apothecary. Unlocks a new potion recipe.",
		"steps": ["Talk to the Apothecary about rare herbs", "Gather Glitch Herb (forest edge)", "Gather Glitch Herb (crater rim)", "Gather Glitch Herb (corrupted grove)", "Return to the Apothecary"],
		"rewards": {"xp": 100, "gold": 50, "unlock": "null_heal_potion"},
		"discovery_hint": "The apothecary sighs, staring at empty shelves where rare ingredients once sat.",
	},

	# ═══ Chapter 2: Ironhold Side Quests ═══
	"ironhold_arena_legend": {
		"name": "Arena Legend",
		"chapter": 2,
		"description": "Complete all 4 arena tiers and defeat the secret 5th challenger: The Phantom Champion.",
		"steps": ["Complete Bronze tier", "Complete Silver tier", "Complete Gold tier", "Complete Platinum tier", "Challenge the Phantom Champion"],
		"rewards": {"xp": 500, "gold": 300, "charm": "arena_veteran", "title": "Arena Legend"},
		"discovery_hint": "Arena regulars whisper about a fighter who appears only when all tiers are conquered...",
	},
	"ironhold_underground_data": {
		"name": "The Data Hoard",
		"chapter": 2,
		"description": "Discover 5 hidden data caches in the underground network, each containing corrupted archives.",
		"steps": ["Find Data Cache 1 (entry tunnel)", "Find Data Cache 2 (waterway junction)", "Find Data Cache 3 (collapsed sector)", "Find Data Cache 4 (server alcove)", "Find Data Cache 5 (deepest chamber)", "Decode all caches at the terminal"],
		"rewards": {"xp": 300, "gold": 200, "lore": "sovereign_origin_fragment"},
		"discovery_hint": "Faint data pulses echo from hidden alcoves in the underground tunnels...",
	},
	"ironhold_merchant_guild": {
		"name": "Merchant's Guild Troubles",
		"chapter": 2,
		"description": "Help the merchant guild investigate corrupted trade routes. Negotiate or fight.",
		"steps": ["Speak with the Guild Master", "Investigate the Eastern Route", "Confront the Corrupted Traders", "Report back to the Guild"],
		"rewards": {"xp": 200, "gold": 150, "shop_discount": 0.15},
		"discovery_hint": "A harried merchant near the gate mutters about shipments 'glitching out of existence'...",
	},

	# ═══ Chapter 3: Fractured Wastes Side Quests ═══
	"wastes_echo_hunter": {
		"name": "Echo Hunter",
		"chapter": 3,
		"description": "Track and defeat 3 Echo Wraiths — ghosts of failed processes that haunt the wastes.",
		"steps": ["Find Echo Wraith near the tower", "Find Echo Wraith in the recursive garden", "Find Echo Wraith in the data conduit", "Collect all Echo Cores"],
		"rewards": {"xp": 350, "gold": 150, "ability": "echo_sense"},
		"discovery_hint": "Translucent figures flicker at the edge of vision, disappearing when approached directly...",
	},
	"wastes_survivor_cache": {
		"name": "Survivor's Cache",
		"chapter": 3,
		"description": "Find the hidden cache of a previous explorer who tried to reach the server room.",
		"steps": ["Find the explorer's journal (in shelter)", "Follow the journal clues", "Locate the cache entrance", "Solve the lock puzzle", "Claim the survivor's gear"],
		"rewards": {"xp": 250, "gold": 200, "item": "stabilizer_mk2", "stat_boost": {"defense": 5, "max_hp": 20}},
		"discovery_hint": "Scratched marks on the shelter wall form a crude map pointing to something hidden...",
	},
	"wastes_lyra_past": {
		"name": "Lyra's Past",
		"chapter": 3,
		"description": "Help Lyra recover memories from her old shop in the marketplace ruins.",
		"requires_flag": "ch3_lyra_recruited",
		"steps": ["Ask Lyra about her past", "Find Lyra's old shop in the market", "Recover the memory crystal", "Watch Lyra's memories together"],
		"rewards": {"xp": 200, "gold": 0, "relationship": {"lyra": 15}, "ability": "lyra_power_shot"},
		"discovery_hint": "Lyra pauses near the marketplace, her eyes clouded with recognition...",
	},

	# ═══ Cross-Chapter Secrets ═══
	"oakhaven_memory_herb_delivery": {
		"name": "Memory Herb Delivery",
		"chapter": 1,
		"description": "Deliver Glitch Herbs to Apothecary Iris so Oakhaven can treat villagers whose memories keep desyncing.",
		"steps": ["Speak with Apothecary Iris", "Bring 2 Glitch Herbs", "Deliver the herbs"],
		"rewards": {"xp": 90, "gold": 35, "item": "mana_potion"},
		"discovery_hint": "Apothecary Iris can turn spare Glitch Herbs into medicine for Oakhaven survivors.",
	},
	"ironhold_blacksmith_material_request": {
		"name": "Forge Line Supply",
		"chapter": 2,
		"description": "Bring Data Ore to Ironhold's forge line so repair work can continue without Administrator rationing.",
		"steps": ["Speak with Merchant Garro", "Bring 2 Data Ore", "Deliver the ore"],
		"rewards": {"xp": 120, "gold": 90, "shop_discount": 0.05},
		"discovery_hint": "Merchant Garro knows a forge contact who can keep Ironhold's citizens armed and independent.",
	},
	"mirror_city_lost_reflection": {
		"name": "Lost Reflection",
		"chapter": 5,
		"description": "Recover an optional Mirror City reflection fragment before entering the trial.",
		"steps": ["Inspect the Mirror Plaza", "Read the optional mirrors", "Secure the lost reflection"],
		"rewards": {"xp": 120, "gold": 60, "item": "memory_shard"},
		"discovery_hint": "One reflection in Mirror Plaza keeps repeating a choice Kaelen has not fully understood.",
	},
	"memory_ocean_backup_salvage": {
		"name": "Backup Salvage",
		"chapter": 7,
		"description": "Stabilize a memory island and recover useful materials from a rejected timeline.",
		"steps": ["Enter the Memory Ocean", "Stabilize a backup island", "Claim safe salvage"],
		"rewards": {"xp": 150, "gold": 75, "item": "data_ore"},
		"discovery_hint": "The Memory Ocean hides salvage for players willing to cross unstable backup histories.",
	},
	"saved_assembly_supply_request": {
		"name": "Assembly Supply Pact",
		"chapter": 8,
		"description": "Help at least two saved factions with practical supplies before the revolt crisis peaks.",
		"steps": ["Read the Saved Assembly request board", "Fulfill two faction requests", "Record the supply pact"],
		"rewards": {"xp": 180, "gold": 80, "item": "glitch_stabilizer"},
		"discovery_hint": "The Saved Assembly needs medicine, repair stock, and witness records as much as speeches.",
	},

	"secret_debug_room": {
		"name": "The Debug Room",
		"chapter": 0,
		"description": "Find the hidden developer debug room — a glitch in the world's foundation.",
		"steps": ["Discover 3 developer signatures hidden in environments", "Find the hidden entrance", "Access the Debug Room"],
		"rewards": {"xp": 1000, "gold": 500, "charm": "developer_insight", "title": "Code Archaeologist"},
		"discovery_hint": "Sometimes, in quiet moments, you catch glimpses of text that doesn't belong: '// TODO: remove before production'...",
	},
}

# ── Secret Collectibles ──────────────────────────────────────────────
const SECRETS_DATABASE: Dictionary = {
	"dev_signature_1": {"location": "Oakhaven well", "text": "// J.Chen was here — build 0.7.3", "chapter": 1},
	"dev_signature_2": {"location": "Ironhold clock tower", "text": "// TODO: fix NPC pathing — it's been 3 patches", "chapter": 2},
	"dev_signature_3": {"location": "Fractured Wastes garden", "text": "// This tree asset took 6 hours. Worth it? No.", "chapter": 3},
	"lore_fragment_1": {"location": "Oakhaven", "text": "A fragment of the original Sanctuary design document.", "chapter": 1},
	"lore_fragment_2": {"location": "Ironhold", "text": "AetherCorp internal memo: 'Monetize consciousness transfer.'", "chapter": 2},
	"lore_fragment_3": {"location": "Wastes", "text": "safety_protocol_v0.1 — before SOVEREIGN existed.", "chapter": 3},
}


# ══════════════════════════════════════════════════════════════════════
# LIFECYCLE
# ══════════════════════════════════════════════════════════════════════

func _ready() -> void:
	# Initialize all quests as hidden
	reset()

func reset() -> void:
	## Reset all quest and secret state (used by reset_game and NG+).
	quests.clear()
	secrets_found.clear()
	for quest_id in QUEST_DATABASE:
		quests[quest_id] = {
			"state": QuestState.HIDDEN,
			"current_step": 0,
			"data": {},
		}
	# Without this, New Game after quitting to the menu kept showing the old
	# "ACTIVE QUESTS" panel (found by tests/screenshot_tour.gd).
	if _hud_tracker:
		_update_hud_tracker()


# ══════════════════════════════════════════════════════════════════════
# QUEST MANAGEMENT
# ══════════════════════════════════════════════════════════════════════

func discover_quest(quest_id: String) -> void:
	if not QUEST_DATABASE.has(quest_id):
		return
	if quests[quest_id]["state"] != QuestState.HIDDEN:
		return  # Already discovered

	# Check requirements
	var quest_data: Dictionary = QUEST_DATABASE[quest_id]
	if quest_data.has("requires_flag"):
		if not GameManager.has_flag(quest_data["requires_flag"]):
			return  # Requirement not met

	quests[quest_id]["state"] = QuestState.DISCOVERED
	print("[SIDE QUEST] Discovered: %s" % quest_data["name"])
	quest_discovered.emit(quest_id)
	# PASS-35 FIX: Show discovery hint so player knows what to do
	var hint: String = quest_data.get("discovery_hint", "")
	if hint != "":
		_queue_notification("QUEST DISCOVERED: %s" % quest_data["name"], Color(1.0, 0.85, 0.3))
		_queue_notification(hint, Color(0.9, 0.8, 0.6))
	else:
		_queue_notification("QUEST DISCOVERED: %s" % quest_data["name"], Color(1.0, 0.85, 0.3))
	_update_hud_tracker()

func start_quest(quest_id: String) -> void:
	if not QUEST_DATABASE.has(quest_id):
		return
	if quests[quest_id]["state"] == QuestState.HIDDEN:
		discover_quest(quest_id)
	if quests[quest_id]["state"] == QuestState.COMPLETED:
		return  # PASS-35 FIX: Don't restart completed quests
	quests[quest_id]["state"] = QuestState.ACTIVE
	quests[quest_id]["current_step"] = 0
	print("[SIDE QUEST] Started: %s" % QUEST_DATABASE[quest_id]["name"])
	var step_text: String = QUEST_DATABASE[quest_id]["steps"][0] if QUEST_DATABASE[quest_id]["steps"].size() > 0 else ""
	_queue_notification("QUEST STARTED: %s" % QUEST_DATABASE[quest_id]["name"], Color(0.3, 1.0, 0.7))
	if step_text != "":
		_queue_notification("Objective: %s" % step_text, Color(0.8, 0.9, 1.0))
	_update_hud_tracker()

func advance_quest(quest_id: String) -> void:
	if not QUEST_DATABASE.has(quest_id):
		return
	var quest = quests[quest_id]
	if quest["state"] != QuestState.ACTIVE:
		return

	quest["current_step"] += 1
	var total_steps: int = QUEST_DATABASE[quest_id]["steps"].size()
	var step_name: String = ""
	if quest["current_step"] < total_steps:
		step_name = QUEST_DATABASE[quest_id]["steps"][quest["current_step"]]

	quest_updated.emit(quest_id, quest["current_step"])
	print("[SIDE QUEST] %s — Step %d/%d: %s" % [QUEST_DATABASE[quest_id]["name"], quest["current_step"], total_steps, step_name])
	if step_name != "":
		_queue_notification("Objective: %s" % step_name, Color(0.8, 0.9, 1.0))
	_update_hud_tracker()

	if quest["current_step"] >= total_steps:
		complete_quest(quest_id)

func complete_quest(quest_id: String) -> void:
	if not QUEST_DATABASE.has(quest_id):
		return
	if quests[quest_id]["state"] == QuestState.COMPLETED:
		return  # Prevent double-completion and duplicate rewards
	quests[quest_id]["state"] = QuestState.COMPLETED
	var quest_data: Dictionary = QUEST_DATABASE[quest_id]

	# Grant rewards
	var rewards: Dictionary = quest_data.get("rewards", {})
	if rewards.has("xp") and GameManager:
		GameManager.add_xp(rewards["xp"])
	if rewards.has("gold") and GameManager:
		GameManager.add_gold(rewards["gold"])
	if rewards.has("item") and has_node("/root/Inventory"):
		Inventory.add_item(rewards["item"], int(rewards.get("item_quantity", 1)))
	if rewards.has("stat_boost") and GameManager:
		var boosts: Dictionary = rewards["stat_boost"]
		for s in boosts:
			GameManager.player_stats[s] = GameManager.player_stats.get(s, 0) + boosts[s]
	if rewards.has("relationship") and GameManager:
		var rels: Dictionary = rewards["relationship"]
		for r in rels:
			GameManager.relationships[r] = GameManager.relationships.get(r, 0) + rels[r]
	if rewards.has("charm") and GameManager:
		GameManager.unlock_charm(rewards["charm"])
	# PASS-35 FIX: Handle remaining reward types
	if rewards.has("title") and GameManager:
		GameManager.titles_earned.append(rewards["title"])
		print("[SIDE QUEST] Title earned: %s" % rewards["title"])
	if rewards.has("shop_discount") and GameManager:
		GameManager.shop_discount = maxf(GameManager.shop_discount, rewards["shop_discount"])
		print("[SIDE QUEST] Shop discount: %d%%" % int(rewards["shop_discount"] * 100))
	if rewards.has("unlock") and GameManager:
		GameManager.set_story_flag("unlocked_" + rewards["unlock"], true)
		print("[SIDE QUEST] Unlocked: %s" % rewards["unlock"])
	if rewards.has("ability") and GameManager:
		GameManager.set_story_flag("ability_" + rewards["ability"], true)
		print("[SIDE QUEST] Ability unlocked: %s" % rewards["ability"])
	if rewards.has("lore") and GameManager:
		GameManager.set_story_flag("lore_" + rewards["lore"], true)
		if has_node("/root/LoreJournal") and LoreJournal.has_method("discover"):
			LoreJournal.discover(str(rewards["lore"]))
	if GameManager:
		GameManager.set_story_flag("side_quest_%s_complete" % quest_id, true)

	print("[SIDE QUEST] Completed: %s!" % quest_data["name"])
	quest_completed.emit(quest_id)
	_queue_notification("QUEST COMPLETE: %s" % quest_data["name"], Color(0.3, 1.0, 0.5))
	_update_hud_tracker()

func complete_optional_objective(quest_id: String) -> void:
	## Phase 10J helper for short optional objectives wired from chapter scenes.
	if not QUEST_DATABASE.has(quest_id):
		return
	if not quests.has(quest_id):
		quests[quest_id] = {"state": QuestState.HIDDEN, "current_step": 0, "data": {}}
	if quests[quest_id]["state"] == QuestState.COMPLETED:
		return
	if quests[quest_id]["state"] == QuestState.HIDDEN:
		discover_quest(quest_id)
	quests[quest_id]["state"] = QuestState.ACTIVE
	quests[quest_id]["current_step"] = QUEST_DATABASE[quest_id].get("steps", []).size()
	complete_quest(quest_id)

func get_quest_state(quest_id: String) -> int:
	if quests.has(quest_id):
		return quests[quest_id]["state"]
	return QuestState.HIDDEN

func is_quest_active(quest_id: String) -> bool:
	return get_quest_state(quest_id) == QuestState.ACTIVE

func is_quest_complete(quest_id: String) -> bool:
	return get_quest_state(quest_id) == QuestState.COMPLETED

func get_active_quests() -> Array[String]:
	var result: Array[String] = []
	for quest_id in quests:
		if quests[quest_id]["state"] == QuestState.ACTIVE:
			result.append(quest_id)
	return result

func get_discovered_quests() -> Array[String]:
	var result: Array[String] = []
	for quest_id in quests:
		if quests[quest_id]["state"] in [QuestState.DISCOVERED, QuestState.ACTIVE]:
			result.append(quest_id)
	return result


# ══════════════════════════════════════════════════════════════════════
# SECRETS
# ══════════════════════════════════════════════════════════════════════

func find_secret(secret_id: String) -> void:
	if secret_id in secrets_found:
		return
	if not SECRETS_DATABASE.has(secret_id):
		return

	secrets_found.append(secret_id)
	var data: Dictionary = SECRETS_DATABASE[secret_id]

	if has_node("/root/SFXManager"):
		SFXManager.play("source_key")  # Reuse the discovery sound

	print("[SECRET] Found: %s — %s" % [secret_id, data.get("text", "")])
	secret_found.emit(secret_id)
	_queue_notification("SECRET FOUND: %s" % data.get("text", "???"), Color(0.8, 0.5, 1.0))

	# XP for finding secrets
	if GameManager:
		GameManager.add_xp(50)

	# Check debug room quest progress
	var dev_sigs = secrets_found.filter(func(s): return s.begins_with("dev_signature_"))
	if dev_sigs.size() >= 3:
		discover_quest("secret_debug_room")


# ══════════════════════════════════════════════════════════════════════
# QUEST LOG UI — Summary for pause screen
# ══════════════════════════════════════════════════════════════════════

func get_quest_log_text() -> String:
	var lines: Array[String] = []
	lines.append("[b]═══ QUEST LOG ═══[/b]")

	var active = get_active_quests()
	if active.is_empty():
		lines.append("\n[color=#888]No active quests. Explore to discover hidden objectives.[/color]")
	else:
		lines.append("\n[color=#FFD700]ACTIVE QUESTS:[/color]")
		for qid in active:
			var qdata: Dictionary = QUEST_DATABASE[qid]
			var step: int = quests[qid]["current_step"]
			var total: int = qdata["steps"].size()
			var current_step_text: String = qdata["steps"][step] if step < total else "Complete!"
			lines.append("  • [b]%s[/b] (%d/%d)" % [qdata["name"], step, total])
			lines.append("    → %s" % current_step_text)

	var discovered = get_discovered_quests()
	var undiscovered_active = discovered.filter(func(qid): return quests[qid]["state"] == QuestState.DISCOVERED)
	if not undiscovered_active.is_empty():
		lines.append("\n[color=#AAA]AVAILABLE QUESTS:[/color]")
		for qid in undiscovered_active:
			lines.append("  • %s" % QUEST_DATABASE[qid]["name"])

	if not secrets_found.is_empty():
		lines.append("\n[color=#B080FF]SECRETS: %d/%d[/color]" % [secrets_found.size(), SECRETS_DATABASE.size()])

	return "\n".join(lines)


# ══════════════════════════════════════════════════════════════════════
# HUD QUEST TRACKER — Persistent on-screen objective display (PASS 35)
# ══════════════════════════════════════════════════════════════════════

var _hud_tracker: CanvasLayer = null
var _tracker_label: RichTextLabel = null

func _create_hud_tracker() -> void:
	## Build a persistent on-screen quest tracker (top-right corner)
	if _hud_tracker:
		return
	_hud_tracker = CanvasLayer.new()
	_hud_tracker.name = "QuestTrackerHUD"
	_hud_tracker.layer = 90  # Below dialogue (100) but above gameplay
	
	var vp_size := get_viewport().get_visible_rect().size if get_viewport() else Vector2(1280, 720)
	var panel_width: float = clampf(vp_size.x * 0.30, 320.0, 430.0)
	var panel_height: float = 168.0
	var panel = PanelContainer.new()
	panel.name = "TrackerPanel"
	panel.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	panel.offset_left = -panel_width - 18.0
	panel.offset_right = -18.0
	panel.offset_top = 46.0
	panel.offset_bottom = 46.0 + panel_height
	panel.custom_minimum_size = Vector2(panel_width, panel_height)
	# Semi-transparent background
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.05, 0.05, 0.1, 0.7)
	style.border_color = Color(0.3, 0.5, 0.8, 0.5)
	style.set_border_width_all(1)
	style.set_corner_radius_all(4)
	style.set_content_margin_all(8)
	panel.add_theme_stylebox_override("panel", style)
	_hud_tracker.add_child(panel)
	
	_tracker_label = RichTextLabel.new()
	_tracker_label.bbcode_enabled = true
	_tracker_label.fit_content = false
	_tracker_label.scroll_active = false
	_tracker_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_tracker_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_tracker_label.custom_minimum_size = Vector2(panel_width - 20.0, panel_height - 20.0)
	panel.add_child(_tracker_label)
	
	add_child(_hud_tracker)

func _update_hud_tracker() -> void:
	## Refresh the on-screen quest tracker with current active objectives
	if not _hud_tracker:
		_create_hud_tracker()
	if not _tracker_label:
		return
	
	var active = get_active_quests()
	if active.is_empty():
		_hud_tracker.visible = false
		return
	
	_hud_tracker.visible = true
	var lines: Array[String] = []
	lines.append("[color=#6699CC][b]ACTIVE QUESTS[/b][/color]")
	
	var shown: int = 0
	for qid in active:
		if shown >= 3:  # Cap at 3 visible quests
			lines.append("[color=#888]  + %d more...[/color]" % (active.size() - 3))
			break
		var qdata: Dictionary = QUEST_DATABASE[qid]
		var step: int = quests[qid]["current_step"]
		var total: int = qdata["steps"].size()
		var step_text: String = qdata["steps"][step] if step < total else "Complete!"
		lines.append("[color=#FFD700]• %s[/color] [color=#888](%d/%d)[/color]" % [qdata["name"], step, total])
		lines.append("  [color=#AAD4FF]→ %s[/color]" % step_text)
		shown += 1
	
	_tracker_label.text = "\n".join(lines)


# ══════════════════════════════════════════════════════════════════════
# NOTIFICATIONS
# ══════════════════════════════════════════════════════════════════════

func _queue_notification(text: String, color: Color) -> void:
	_notification_queue.append({"text": text, "color": color})
	if not _processing_notification:
		_processing_notification = true
		call_deferred("_process_notification_queue")

func _process_notification_queue() -> void:
	if _notification_queue.is_empty():
		_processing_notification = false
		return
	_processing_notification = true

	var data: Dictionary = _notification_queue.pop_front()
	var vp_size := get_viewport().get_visible_rect().size if get_viewport() else Vector2(1280, 720)
	var panel_width: float = clampf(vp_size.x * 0.46, 420.0, 660.0)
	var notif = PanelContainer.new()
	notif.name = "QuestNotification"
	notif.position = Vector2((vp_size.x - panel_width) * 0.5, 52.0)
	notif.size = Vector2(panel_width, 72.0)
	notif.z_index = 200
	notif.modulate.a = 0.0

	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.03, 0.035, 0.06, 0.92)
	style.border_color = data["color"].lightened(0.15)
	style.set_border_width_all(2)
	style.set_corner_radius_all(6)
	style.set_content_margin_all(12)
	style.shadow_color = Color(0.0, 0.0, 0.0, 0.25)
	style.shadow_size = 8
	notif.add_theme_stylebox_override("panel", style)

	var label := Label.new()
	label.text = data["text"]
	label.add_theme_font_size_override("font_size", 16)
	label.add_theme_color_override("font_color", data["color"])
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	notif.add_child(label)

	get_tree().root.add_child(notif)
	if has_node("/root/SFXManager"):
		SFXManager.play("ui_select")
	var tw = create_tween()
	tw.parallel().tween_property(notif, "position:y", 68.0, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(notif, "modulate:a", 1.0, 0.22)
	tw.tween_interval(3.0)
	tw.tween_property(notif, "modulate:a", 0.0, 1.0)
	tw.tween_callback(notif.queue_free)
	tw.tween_callback(_process_notification_queue)


# ══════════════════════════════════════════════════════════════════════
# SAVE / LOAD
# ══════════════════════════════════════════════════════════════════════

func get_save_data() -> Dictionary:
	return {
		"quests": quests.duplicate(true),
		"secrets_found": secrets_found.duplicate(),
	}

func load_save_data(data: Dictionary) -> void:
	if data.has("quests"):
		quests = data["quests"]
	# Merge any new quests from QUEST_DATABASE that didn't exist in the save
	for quest_id in QUEST_DATABASE:
		if quest_id not in quests:
			quests[quest_id] = {"state": QuestState.HIDDEN, "current_step": 0, "data": {}}
	if data.has("secrets_found"):
		secrets_found.assign(data["secrets_found"])
