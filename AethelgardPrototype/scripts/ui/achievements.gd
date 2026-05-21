extends Node

## Achievements / Milestones — Tracks player accomplishments and shows unlock popups
## Autoload: Achievements

signal achievement_unlocked(id: String, data: Dictionary)

# ── Achievement Definitions ──────────────────────────────────────────
const ACHIEVEMENTS: Dictionary = {
	# Combat milestones
	"first_blood": {"name": "First Blood", "desc": "Defeat your first enemy.", "icon": "⚔️", "category": "combat"},
	"combo_5": {"name": "Combo Starter", "desc": "Reach a 5-hit combo.", "icon": "🔥", "category": "combat"},
	"combo_15": {"name": "Unstoppable", "desc": "Reach a 15-hit combo.", "icon": "💥", "category": "combat"},
	"perfect_parry": {"name": "Perfect Timing", "desc": "Land your first parry.", "icon": "🛡️", "category": "combat"},
	"ten_parries": {"name": "Shield Wall", "desc": "Land 10 parries total.", "icon": "🛡️", "category": "combat"},
	"pogo_kill": {"name": "Death From Above", "desc": "Kill an enemy with a pogo attack.", "icon": "⬇️", "category": "combat"},
	"no_damage_boss": {"name": "Flawless Victory", "desc": "Defeat a boss without taking damage.", "icon": "✨", "category": "combat"},
	"kill_50": {"name": "Exterminator", "desc": "Defeat 50 enemies total.", "icon": "💀", "category": "combat"},
	"kill_100": {"name": "Genocide Protocol", "desc": "Defeat 100 enemies total.", "icon": "☠️", "category": "combat"},
	"all_bosses": {"name": "Boss Slayer", "desc": "Defeat all major bosses.", "icon": "👑", "category": "combat"},

	# Story milestones
	"prologue_complete": {"name": "Crash Landing", "desc": "Survive Flight 707.", "icon": "✈️", "category": "story"},
	"ch1_complete": {"name": "The Awakening", "desc": "Complete Chapter 1.", "icon": "📖", "category": "story"},
	"ch2_complete": {"name": "The Administrator's Game", "desc": "Complete Chapter 2.", "icon": "📖", "category": "story"},
	"ch3_complete": {"name": "The Source Code", "desc": "Complete Chapter 3.", "icon": "📖", "category": "story"},
	"root_access": {"name": "Sudo Mode", "desc": "Unlock Root Access.", "icon": "💻", "category": "story"},
	"fragment_1": {"name": "First Fragment", "desc": "Collect your first Source Key Fragment.", "icon": "🔑", "category": "story"},
	"fragment_4": {"name": "Key Collector", "desc": "Collect all available Source Key Fragments.", "icon": "🔑", "category": "story"},

	"source_key_complete": {"name": "Source Key Complete", "desc": "Collect all seven Source Key fragments.", "icon": "*", "category": "story"},
	"true_ending": {"name": "True Ending", "desc": "Reach a true ending of Aethelgard.", "icon": "*", "category": "story"},
	"ng_plus_unlocked": {"name": "Again, With Memory", "desc": "Unlock New Game Plus.", "icon": "*", "category": "story"},

	# Exploration
	"first_shop": {"name": "Window Shopping", "desc": "Visit a shop for the first time.", "icon": "🛒", "category": "explore"},
	"full_party": {"name": "Band Together", "desc": "Recruit all available party members.", "icon": "👥", "category": "explore"},
	"charm_3": {"name": "Fully Loaded", "desc": "Equip 3 charms at once.", "icon": "💎", "category": "explore"},
	"level_10": {"name": "Double Digits", "desc": "Reach level 10.", "icon": "📈", "category": "explore"},
	"rich": {"name": "Digital Fortune", "desc": "Accumulate 1000 gold.", "icon": "💰", "category": "explore"},
	"all_areas": {"name": "World Walker", "desc": "Visit Oakhaven, Ironhold, and the Fractured Wastes.", "icon": "🗺️", "category": "explore"},

	"first_craft": {"name": "First Craft", "desc": "Craft your first item.", "icon": "*", "category": "explore"},
	"first_lore_discovery": {"name": "Lore Seeker", "desc": "Discover your first optional lore entry.", "icon": "*", "category": "explore"},

	# Arena
	"arena_bronze": {"name": "Pit Fighter", "desc": "Complete the Bronze arena tier.", "icon": "🥉", "category": "arena"},
	"arena_silver": {"name": "Silver Warrior", "desc": "Complete the Silver arena tier.", "icon": "🥈", "category": "arena"},
	"arena_gold": {"name": "Gold Champion", "desc": "Complete the Gold arena tier.", "icon": "🥇", "category": "arena"},
	"arena_platinum": {"name": "Platinum Legend", "desc": "Complete the Platinum arena tier.", "icon": "🏆", "category": "arena"},
	"arena_streak_5": {"name": "On Fire", "desc": "Win 5 arena matches in a row.", "icon": "🔥", "category": "arena"},

	# Quests
	"first_quest": {"name": "Side Tracked", "desc": "Complete your first side quest.", "icon": "📜", "category": "quest"},
	"all_quests": {"name": "Completionist", "desc": "Complete all side quests.", "icon": "📋", "category": "quest"},
	"all_secrets": {"name": "Code Archaeologist", "desc": "Find all hidden secrets.", "icon": "🔍", "category": "quest"},

	"optional_objective": {"name": "Helpful Variables", "desc": "Complete an optional objective.", "icon": "*", "category": "quest"},

	# Meta
	"die_5": {"name": "Persistent", "desc": "Die 5 times. Keep going.", "icon": "💪", "category": "meta"},
	"die_20": {"name": "Stubborn", "desc": "Die 20 times. You're dedicated.", "icon": "🪦", "category": "meta"},
	"corruption_50": {"name": "Corrupted Soul", "desc": "Reach 50% corruption.", "icon": "⚠️", "category": "meta"},
	"corruption_75": {"name": "System Hostile", "desc": "Reach 75% corruption.", "icon": "🔴", "category": "meta"},
	"speedrun_30": {"name": "Speed Demon", "desc": "Complete a chapter in under 30 minutes.", "icon": "⏱️", "category": "meta"},
	"first_hack": {"name": "Script Kiddie", "desc": "Use Root Access for the first time.", "icon": "🔧", "category": "meta"},
	"completion_100": {"name": "True Architect", "desc": "Reach 100% game completion.", "icon": "🌟", "category": "meta"},
}

# ── Persistence path (independent of game saves) ─────────────────────
const ACHIEVEMENT_SAVE_PATH = "user://achievements.save"

# ── Unlocked achievements ────────────────────────────────────────────
var unlocked: Dictionary = {}  # id → timestamp
var progress: Dictionary = {}  # id → int (for multi-step tracking)

# ── UI ────────────────────────────────────────────────────────────────
var _popup_layer: CanvasLayer = null
var _popup_queue: Array[String] = []
var _popup_active: bool = false
var _stat_check_timer: Timer = null

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_popup_layer = CanvasLayer.new()
	_popup_layer.layer = 98
	add_child(_popup_layer)

	# Load persistent achievements from disk (independent of game saves)
	_load_from_disk()

	# Connect to GameJuice combo signal
	if has_node("/root/GameJuice"):
		if not GameJuice.combo_updated.is_connected(_on_combo_updated):
			GameJuice.combo_updated.connect(_on_combo_updated)

	# Connect to SideQuestManager signals (deferred — SideQuestManager loads after Achievements)
	_connect_side_quest_manager.call_deferred()
	_connect_optional_systems.call_deferred()

	# Use a timer instead of polling in _process every frame
	_stat_check_timer = Timer.new()
	_stat_check_timer.wait_time = 1.0
	_stat_check_timer.autostart = true
	_stat_check_timer.timeout.connect(_check_stat_achievements)
	add_child(_stat_check_timer)

func _connect_side_quest_manager() -> void:
	## Deferred connection — SideQuestManager autoloads after Achievements.
	if has_node("/root/SideQuestManager"):
		if not SideQuestManager.quest_completed.is_connected(_on_quest_completed):
			SideQuestManager.quest_completed.connect(_on_quest_completed)

func _connect_optional_systems() -> void:
	## Deferred connections for Phase 10J optional replay hooks.
	if has_node("/root/CraftingSystem"):
		if not CraftingSystem.craft_succeeded.is_connected(_on_craft_succeeded):
			CraftingSystem.craft_succeeded.connect(_on_craft_succeeded)
	if has_node("/root/LoreJournal"):
		if not LoreJournal.lore_discovered.is_connected(_on_lore_discovered):
			LoreJournal.lore_discovered.connect(_on_lore_discovered)

func _check_stat_achievements() -> void:
	## Periodic check for stat-based achievements. Fires every 1s via Timer.
	if not has_node("/root/GameManager"):
		return

	var s = GameManager.stats

	# Kill milestones
	var kills = s.get("enemies_killed", 0)
	if kills >= 1: _try_unlock("first_blood")
	if kills >= 50: _try_unlock("kill_50")
	if kills >= 100: _try_unlock("kill_100")

	# Death milestones
	var deaths = s.get("death_count", 0)
	if deaths >= 5: _try_unlock("die_5")
	if deaths >= 20: _try_unlock("die_20")

	# Parry milestones
	var parries = s.get("parries_landed", 0)
	if parries >= 1: _try_unlock("perfect_parry")
	if parries >= 10: _try_unlock("ten_parries")

	# Hack milestone
	if s.get("hacks_used", 0) >= 1: _try_unlock("first_hack")

	# Corruption
	var corruption = GameManager.glitch_meter
	if corruption >= 50: _try_unlock("corruption_50")
	if corruption >= 75: _try_unlock("corruption_75")

	# Level + Gold
	var level = GameManager.player_stats.get("level", 1)
	if level >= 10: _try_unlock("level_10")
	var gold = GameManager.player_stats.get("gold", 0)
	if gold >= 1000: _try_unlock("rich")

	# Story flags
	if GameManager.story_flags.get("plane_crash_completed", false): _try_unlock("prologue_complete")
	if GameManager.story_flags.get("ch1_complete", false): _try_unlock("ch1_complete")
	if GameManager.story_flags.get("ch2_complete", false): _try_unlock("ch2_complete")
	if GameManager.story_flags.get("ch3_complete", false): _try_unlock("ch3_complete")
	if GameManager.story_flags.get("root_access_unlocked", false): _try_unlock("root_access")

	# Source Key fragments
	if GameManager.source_key_count >= 1: _try_unlock("fragment_1")
	if GameManager.source_key_count >= 2: _try_unlock("fragment_4")
	if GameManager.source_key_count >= 7: _try_unlock("source_key_complete")
	if GameManager.story_flags.get("true_ending_seen", false): _try_unlock("true_ending")
	if GameManager.story_flags.get("ng_plus_unlocked", false): _try_unlock("ng_plus_unlocked")

	# Charms
	if GameManager.equipped_charms.size() >= 3: _try_unlock("charm_3")

	# Full party
	var party_count = 0
	if GameManager.story_flags.get("ch1_elara_trusted", false) or GameManager.story_flags.get("ch1_elara_cautious", false): party_count += 1
	if GameManager.story_flags.get("ch2_seraphina_recruited", false): party_count += 1
	if GameManager.story_flags.get("ch3_lyra_recruited", false): party_count += 1
	if party_count >= 3: _try_unlock("full_party")

	# Arena tiers
	if GameManager.story_flags.get("ch2_arena_bronze_complete", false): _try_unlock("arena_bronze")
	if GameManager.story_flags.get("ch2_arena_silver_complete", false): _try_unlock("arena_silver")
	if GameManager.story_flags.get("ch2_arena_gold_complete", false): _try_unlock("arena_gold")
	if GameManager.story_flags.get("ch2_arena_platinum_complete", false): _try_unlock("arena_platinum")

	# Arena win streak
	if GameManager.arena_stats.get("best_streak", 0) >= 5: _try_unlock("arena_streak_5")

	# All areas visited
	if GameManager.story_flags.get("ch1_oakhaven_entered", false) \
		and GameManager.story_flags.get("ch2_ironhold_entered", false) \
		and GameManager.story_flags.get("ch3_fractured_wastes_entered", false):
		_try_unlock("all_areas")

	# All bosses — check all major boss flags (Ch1 + Ch2 + Ch3)
	var bosses_defeated: int = 0
	if GameManager.story_flags.get("ch1_tutorial_knight_defeated", false): bosses_defeated += 1
	if GameManager.story_flags.get("ch2_data_wraith_defeated", false): bosses_defeated += 1
	if GameManager.story_flags.get("ch2_clockwork_automaton_defeated", false): bosses_defeated += 1
	if GameManager.story_flags.get("ch2_administrator_proxy_defeated", false): bosses_defeated += 1
	if GameManager.story_flags.get("ch3_sovereign_defeated", false): bosses_defeated += 1
	if GameManager.story_flags.get("ch3_kaelthas_defeated", false): bosses_defeated += 1
	if bosses_defeated >= 6: _try_unlock("all_bosses")

	# 100% completion
	if has_node("/root/GameManager") and GameManager.get_completion_percentage() >= 100.0:
		_try_unlock("completion_100")

	# All secrets
	if has_node("/root/SideQuestManager"):
		var total_secrets = SideQuestManager.SECRETS_DATABASE.size()
		if total_secrets > 0 and SideQuestManager.secrets_found.size() >= total_secrets:
			_try_unlock("all_secrets")

	# All quests complete
	if has_node("/root/SideQuestManager"):
		var all_done = true
		for quest_id in SideQuestManager.QUEST_DATABASE:
			if not SideQuestManager.is_quest_complete(quest_id):
				all_done = false
				break
		if all_done and not SideQuestManager.QUEST_DATABASE.is_empty():
			_try_unlock("all_quests")

func _on_combo_updated(count: int, _mult: float) -> void:
	if count >= 5: _try_unlock("combo_5")
	if count >= 15: _try_unlock("combo_15")

func _on_quest_completed(_quest_id: String) -> void:
	_try_unlock("first_quest")
	_try_unlock("optional_objective")

func _on_craft_succeeded(_recipe_id: String, _output_id: String, _quantity: int) -> void:
	_try_unlock("first_craft")

func _on_lore_discovered(_lore_id: String) -> void:
	_try_unlock("first_lore_discovery")

func _try_unlock(id: String) -> void:
	## Unlock an achievement if not already unlocked.
	if id in unlocked:
		return
	if id not in ACHIEVEMENTS:
		return
	unlocked[id] = Time.get_datetime_string_from_system()
	var data = ACHIEVEMENTS[id]
	print("[ACHIEVEMENT] Unlocked: %s — %s" % [data["name"], data["desc"]])
	achievement_unlocked.emit(id, data)
	_queue_popup(id)
	# Trigger GameJuice celebration VFX
	if has_node("/root/GameJuice"):
		GameJuice.on_achievement_unlocked(data.get("name", id))
	# Auto-save to disk immediately (independent of game save)
	_save_to_disk()

func try_unlock(id: String) -> void:
	## Public wrapper for external callers (combat, shop, etc.)
	_try_unlock(id)

func _queue_popup(id: String) -> void:
	## Queue an achievement popup notification.
	_popup_queue.append(id)
	if not _popup_active:
		_show_next_popup()

func _show_next_popup() -> void:
	## Show the next achievement popup from the queue.
	if _popup_queue.is_empty():
		_popup_active = false
		return
	_popup_active = true
	var id = _popup_queue.pop_front()
	var data = ACHIEVEMENTS.get(id, {})

	# Build popup panel
	var panel = PanelContainer.new()
	var vp_size = get_viewport().get_visible_rect().size if get_viewport() else Vector2(1280, 720)
	var panel_width: float = clampf(vp_size.x * 0.42, 420.0, 560.0)
	var panel_height: float = 88.0
	panel.position = Vector2((vp_size.x - panel_width) / 2.0, -panel_height - 12.0)
	panel.size = Vector2(panel_width, panel_height)
	panel.custom_minimum_size = Vector2(panel_width, panel_height)

	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.05, 0.05, 0.15, 0.95)
	style.border_color = Color(1.0, 0.85, 0.2, 0.9)
	style.border_width_top = 2
	style.border_width_bottom = 2
	style.border_width_left = 2
	style.border_width_right = 2
	style.corner_radius_top_left = 6
	style.corner_radius_top_right = 6
	style.corner_radius_bottom_left = 6
	style.corner_radius_bottom_right = 6
	style.content_margin_left = 16
	style.content_margin_right = 16
	style.content_margin_top = 8
	style.content_margin_bottom = 8
	style.shadow_color = Color(1.0, 0.8, 0.0, 0.2)
	style.shadow_size = 6
	panel.add_theme_stylebox_override("panel", style)

	var hbox = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 12)
	panel.add_child(hbox)

	# Icon
	var icon_lbl = Label.new()
	icon_lbl.text = data.get("icon", "🏆")
	icon_lbl.add_theme_font_size_override("font_size", 28)
	hbox.add_child(icon_lbl)

	# Text
	var vbox = VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(vbox)

	var title_lbl = Label.new()
	title_lbl.text = "ACHIEVEMENT UNLOCKED"
	title_lbl.add_theme_font_size_override("font_size", 10)
	title_lbl.add_theme_color_override("font_color", Color(1.0, 0.85, 0.2))
	vbox.add_child(title_lbl)

	var name_lbl = Label.new()
	name_lbl.text = data.get("name", id)
	name_lbl.add_theme_font_size_override("font_size", 16)
	name_lbl.add_theme_color_override("font_color", Color(1, 1, 1))
	name_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(name_lbl)

	var desc_lbl = Label.new()
	desc_lbl.text = data.get("desc", "")
	desc_lbl.add_theme_font_size_override("font_size", 11)
	desc_lbl.add_theme_color_override("font_color", Color(0.7, 0.7, 0.8))
	desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc_lbl.custom_minimum_size = Vector2(panel_width - 92.0, 24.0)
	vbox.add_child(desc_lbl)

	_popup_layer.add_child(panel)

	# SFX
	if has_node("/root/SFXManager"):
		SFXManager.play("achievement_unlock")

	# Animate: slide down, hold, slide up
	var tw = create_tween()
	tw.tween_property(panel, "position:y", 20.0, 0.4).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_interval(3.0)
	tw.tween_property(panel, "position:y", -panel_height - 12.0, 0.3).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	tw.tween_callback(panel.queue_free)
	tw.tween_callback(_show_next_popup)

# ── Independent Persistence (separate from game saves) ───────────────

func _save_to_disk() -> void:
	## Save achievements to their own file, independent of game save slots.
	var data = {
		"unlocked": unlocked.duplicate(),
		"progress": progress.duplicate(),
	}
	var file = FileAccess.open(ACHIEVEMENT_SAVE_PATH, FileAccess.WRITE)
	if not file:
		push_error("[ACHIEVEMENTS] Failed to write achievement save")
		return
	file.store_string(JSON.stringify(data, "\t"))
	file.close()

func _load_from_disk() -> void:
	## Load achievements from their own file on startup.
	if not FileAccess.file_exists(ACHIEVEMENT_SAVE_PATH):
		return
	var file = FileAccess.open(ACHIEVEMENT_SAVE_PATH, FileAccess.READ)
	if not file:
		return
	var json = JSON.new()
	var json_text = file.get_as_text()
	file.close()
	if json.parse(json_text) != OK:
		push_warning("[ACHIEVEMENTS] Failed to parse achievement save")
		return
	if not json.data is Dictionary:
		return
	var data: Dictionary = json.data
	if data.has("unlocked") and data["unlocked"] is Dictionary:
		unlocked = data["unlocked"]
	if data.has("progress") and data["progress"] is Dictionary:
		progress = data["progress"]
	if OS.is_debug_build():
		print("[ACHIEVEMENTS] Loaded %d/%d from disk" % [unlocked.size(), ACHIEVEMENTS.size()])

# ── Game-save integration (still works, merges with disk data) ────────

func get_save_data() -> Dictionary:
	return unlocked.duplicate()

func load_save_data(data: Dictionary) -> void:
	## Merge save-slot achievements with disk achievements (union — never lose progress).
	if not data is Dictionary:
		return
	for id in data:
		if id not in unlocked:
			unlocked[id] = data[id]
	# Persist the merged result
	_save_to_disk()

func get_unlocked_count() -> int:
	return unlocked.size()

func get_total_count() -> int:
	return ACHIEVEMENTS.size()

func get_completion_string() -> String:
	return "%d / %d" % [get_unlocked_count(), get_total_count()]
