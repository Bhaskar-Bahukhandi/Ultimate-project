extends Node
## ==========================================================================
## GAME MANAGER — Central game state, progression, save/load, and systems hub
## ==========================================================================
## Autoload singleton: GameManager
## ==========================================================================

# ── Signals ───────────────────────────────────────────────────────────────
signal state_changed(new_state: GameState)
signal glitch_meter_changed(value: float)
signal corruption_level_changed(level: int)
signal corruption_effects_updated(level: int)
signal story_flag_updated(flag_name: String, value: bool)
signal player_leveled_up(new_level: int)
signal charm_unlocked(charm_id: String)
signal charm_equipped(charm_id: String)
signal charm_unequipped(charm_id: String)
signal difficulty_adjusted(multiplier: float)
signal accessibility_setting_changed(key: String, value: Variant)

# ── Enums ─────────────────────────────────────────────────────────────────
enum GameState {
	MENU,
	PROLOGUE,
	EXPLORATION,
	COMBAT,
	DIALOGUE,
	CUTSCENE,
	ROOT_ACCESS_MODE,
	GAME_OVER,
}

# ── Constants ─────────────────────────────────────────────────────────────
const DEMO_MODE := false  ## Set to true for itch.io demo builds (locks after Ch1)
const SAVE_VERSION = "1.2.0"
const MAX_SAVE_SLOT = 99
const AUTOSAVE_SLOT = 99
const VALID_SAVE_SLOTS: Array[int] = [0, 1, 2, 99]  # 0-2 manual, 99 autosave
const MAX_CHARM_SLOTS = 3
const REQUIRED_SAVE_KEYS: Array[String] = ["version", "player_stats", "story_flags", "current_chapter"]
const COMPATIBLE_SAVE_VERSIONS: Array[String] = ["1.0.0", "1.1.0", "1.2.0"]

const XP_THRESHOLDS: Array[int] = [0, 100, 300, 600, 1000, 1500, 2200, 3000, 4000, 5500, 7500, 10000, 13000, 16500, 20500, 25000, 30000, 36000, 43000, 51000]
const HP_PER_LEVEL = 20
const MP_PER_LEVEL = 10
const DAMAGE_PER_LEVEL = 3
const DEF_PER_LEVEL = 1  # New: defense per level
const TIER_ORDER: Array[String] = ["bronze", "silver", "gold", "platinum"]
const DDA_WINDOW_SECONDS = 120.0
const DDA_SCORE_FLOOR = 20.0
const DDA_SCORE_CEILING = 85.0
const ADMIN_SPAWN_COOLDOWN = 60.0
const ADMIN_SPAWN_COUNT = 2

const CHARM_INFO: Dictionary = {
	"extended_parry": {"name": "Extended Parry", "desc": "Parry window +40%.", "icon": "[P]"},
	"soul_hoarder": {"name": "Soul Hoarder", "desc": "Soul gain +50%. Spell cost -20%.", "icon": "[S]"},
	"corruption_resist": {"name": "Firewall", "desc": "Corruption gain reduced by 40%.", "icon": "[F]"},
	"pogo_master": {"name": "Pogo Master", "desc": "Pogo damage +80%. Bounce height +30%.", "icon": "[G]"},
	"dash_master": {"name": "Shadow Dash", "desc": "Dash cooldown -50%. Dash deals 10 damage.", "icon": "[D]"},
	"thorns": {"name": "Thorns of Pain", "desc": "Reflect 15 damage to attackers when hit.", "icon": "[T]"},
	"null_cloak": {"name": "Null Cloak", "desc": "Halves random encounter rate while equipped.", "icon": "[N]"},
}

const CHARM_VALUES: Dictionary = {
	"extended_parry": 1.4, "soul_hoarder": 1.5, "corruption_resist": 0.6,
	"pogo_master": 1.8, "dash_master": 0.5, "thorns": 15.0,
	"null_cloak": 2.0,  # Encounter rate multiplier (2x steps needed = half encounters)
}

const DEFAULT_PLAYER_STATS: Dictionary = {
	"name": "Kaelen", "class_fake": "Systems Architect", "class_true": "ROOT_ACCESS",
	"level": 1, "hp": 100, "max_hp": 100, "mp": 50, "max_mp": 50,
	"gold": 0, "xp": 0, "base_attack": 15, "attack": 15,
	"base_defense": 0, "defense": 0, "ram_gb": 12, "ram_max_gb": 16,
	"corruption_pct": 0.05, "integrity_pct": 84.0, "soul": 0,
}

const DEFAULT_RELATIONSHIPS: Dictionary = {
	"elara": 0, "seraphina": 0, "lyra": 0, "kaelthas": 0, "aria": 0,
}

const DEFAULT_STORY_FLAGS: Dictionary = {
	"plane_crash_completed": false, "tutorial_completed": false,
	"first_slime_defeated": false, "root_access_unlocked": false, "elara_met": false,
	"ch1_awakening_complete": false, "ch1_elara_glitch_witch_met": false,
	"ch1_glitch_magic_shown": false, "ch1_data_vision_unlocked": false,
	"ch1_slime_root_access_tutorial": false, "ch1_oakhaven_entered": false,
	"ch1_apothecary_visited": false, "ch1_auction_house_visited": false,
	"ch1_corrupted_boar_defeated": false, "ch1_tutorial_knight_defeated": false,
	"ch1_shatter_witnessed": false, "ch1_complete": false,
	"source_key_fragment_1": false,
	"ch1_elara_trusted": false, "ch1_elara_distrusted": false, "ch1_elara_cautious": false,
	"ch1_knight_spared": false, "ch1_knight_killed": false,
	"ch1_oakhaven_warned_villagers": false, "ch1_oakhaven_left_quietly": false,
	"ch2_ironhold_entered": false, "ch2_market_visited": false,
	"ch2_arena_unlocked": false, "ch2_arena_bronze_complete": false,
	"ch2_arena_silver_complete": false, "ch2_arena_gold_complete": false,
	"ch2_arena_platinum_complete": false, "ch2_arena_complete": false,
	"ch2_seraphina_met": false, "ch2_seraphina_truth": false,
	"ch2_seraphina_cautious": false, "ch2_seraphina_showoff": false,
	"ch2_underground_unlocked": false, "ch2_underground_complete": false,
	"ch2_data_wraith_defeated": false, "ch2_data_wraith_restored": false,
	"ch2_data_wraith_destroyed": false, "ch2_data_wraith_absorbed": false,
	"source_key_fragment_2": false,
	"ch2_clock_tower_unlocked": false, "ch2_clock_tower_complete": false,
	"ch2_clockwork_automaton_defeated": false, "ch2_administrator_proxy_defeated": false,
	"ch2_seraphina_recruited": false, "ch2_seraphina_stayed": false,
	"ch2_seraphina_rejected": false, "ch2_sovereign_revealed": false,
	"ch2_complete": false, "player_died": false,
	"ch1_glitch_crater_complete": false, "ch1_root_purge": false,
	"prologue_skipped": false,
	# ── Chapter 3 flags ──
	"ch3_fractured_wastes_entered": false,
	"ch3_data_paths_discovered": false, "ch3_lyra_met": false,
	"ch3_corruption_storm_survived": false,
	"ch3_fragment_3_collected": false, "source_key_fragment_3": false,
	"ch3_elara_powers_amplified": false,
	"ch3_ironhold_departed": false, "ch3_kaelthas_betrayed": false,
	"ch3_kaelthas_met": false, "ch3_archivist_met": false,
	"ch3_archive_entered": false,
	"ch3_archive_floor1_complete": false, "ch3_archive_floor2_complete": false,
	"ch3_archive_floor3_complete": false, "ch3_archive_floor4_complete": false,
	"ch3_sovereign_origin_discovered": false,
	"ch3_fragment_4_collected": false, "source_key_fragment_4": false,
	"ch3_data_stream_entered": false, "ch3_data_stream_complete": false,
	"ch3_lyra_recruited": false, "ch3_lyra_left_alone": false,
	"ch3_kaelthas_allied": false, "ch3_kaelthas_refused": false,
	"ch3_kaelthas_challenged": false, "ch3_kaelthas_defeated": false,
	"ch3_sovereign_defiant": false, "ch3_sovereign_regretful": false,
	"ch3_sovereign_doubting": false, "ch3_reality_shatter": false,
	"ch3_sovereign_defeated": false,
	"ch3_complete": false,
	# Chapter 4 flags
	"ch4_unlocked": false, "ch4_forgotten_sectors_entered": false,
	"ch4_null_court_entered": false, "ch4_echo_mirror_met": false,
	"ch4_choice_preserve_deleted": false, "ch4_choice_release_deleted": false,
	"ch4_choice_bargain_deleted": false,
	"ch4_fragment_5_collected": false, "source_key_fragment_5": false,
	"ch4_complete": false, "ch5_path_revealed": false,
	# Chapter 5 flags
	"ch5_unlocked": false, "ch5_mirror_city_entered": false,
	"ch5_mirror_plaza_entered": false,
	"ch5_echo_ch4_preserve_seen": false, "ch5_echo_ch4_release_seen": false,
	"ch5_echo_ch4_bargain_seen": false,
	"ch5_echo_obedient_met": false, "ch5_echo_savior_met": false,
	"ch5_echo_coward_met": false, "ch5_all_echoes_resolved": false,
	"ch5_identity_choice_made": false,
	"ch5_identity_refused_obedience": false,
	"ch5_identity_refused_perfect_rescue": false,
	"ch5_identity_refused_abandonment": false,
	"ch5_reflection_trial_started": false, "ch5_mirror_kaelen_met": false,
	"ch5_choice_echo_resolved": false,
	"ch5_echo_control_rejected": false, "ch5_echo_guilt_named": false,
	"ch5_echo_witnesses_promised": false,
	"ch5_mirror_kaelen_confronted": false, "ch5_fragment_6_trail_found": false,
	"ch5_complete": false, "ch6_path_revealed": false,
	# Future final-story flag. NG+ should unlock only after the true ending.
	"ch10_complete": false,
}

const DEFAULT_ARENA_STATS: Dictionary = {
	"total_wins": 0, "total_losses": 0, "current_tier": "bronze",
	"win_streak": 0, "best_streak": 0, "highest_tier_reached": "bronze",
}

const DEFAULT_SESSION_STATS: Dictionary = {
	"death_count": 0, "enemies_killed": 0, "bosses_killed": 0,
	"total_damage_dealt": 0, "total_damage_taken": 0,
	"items_found": 0, "hacks_used": 0, "parries_landed": 0,
	"perfect_deletes_used": 0, "highest_combo": 0, "speedrun_seconds": 0.0,
}

# ── Accessibility Defaults ────────────────────────────────────────────────
const DEFAULT_ACCESSIBILITY_SETTINGS: Dictionary = {
	# Visual
	"screen_shake_enabled": true,
	"screen_shake_intensity": 1.0,      # 0.0–1.0 slider
	"colorblind_mode": "none",           # "none","protanopia","deuteranopia","tritanopia"
	"high_contrast": false,
	"reduced_motion": false,             # Disables non-essential particles, screen effects
	"text_size_scale": 1.0,              # 0.8–2.0
	# Audio
	"subtitle_enabled": true,
	"subtitle_size": "medium",           # "small","medium","large"
	"subtitle_speaker_colors": true,     # Color-code speaker names
	# Input
	"one_handed_mode": false,            # Remaps combat to single-hand layout
	"input_remap_enabled": false,
	# Gameplay assists
	"tutorial_hints_enabled": true,      # Show contextual mechanic hints
	"extended_parry_window": false,      # +100 ms parry window (assist)
	"auto_pogo": false,                  # Auto-pogo when holding down+attack in air
	"invincibility_mode": false,         # Pass 57: God mode assist for accessibility
	"show_damage_numbers": true,         # Pass 57: Toggle damage number display
}

# ── Runtime State ─────────────────────────────────────────────────────────
var current_state: GameState = GameState.MENU
var current_chapter: int = 1
var glitch_meter: float = 0.0
var corruption_level: int = 0
var perfect_delete_charges: int = 3
var perfect_delete_used: bool = false
var playtime_seconds: float = 0.0
var source_key_count: int = 0
var speedrun_active: bool = false

## Region tracking for open-world travel
var current_region: String = ""  # "oakhaven", "ironhold", "fractured_wastes", "overworld"
var player_overworld_position: Vector2 = Vector2(1500, 1100)  # Default overworld spawn

var player_stats: Dictionary = DEFAULT_PLAYER_STATS.duplicate(true)
var relationships: Dictionary = DEFAULT_RELATIONSHIPS.duplicate(true)
var story_flags: Dictionary = DEFAULT_STORY_FLAGS.duplicate(true)
var arena_stats: Dictionary = DEFAULT_ARENA_STATS.duplicate(true)
var stats: Dictionary = DEFAULT_SESSION_STATS.duplicate(true)

var unlocked_charms: Dictionary = {}
var equipped_charms: Array = []
var accessibility_settings: Dictionary = DEFAULT_ACCESSIBILITY_SETTINGS.duplicate(true)

# ── Pass 57: Difficulty System ───────────────────────────────────────────
enum Difficulty { STORY, EASY, NORMAL, HARD }
var selected_difficulty: Difficulty = Difficulty.NORMAL
const DIFFICULTY_MULTS: Dictionary = {
	Difficulty.STORY: {"enemy_dmg": 0.5, "player_dmg": 1.5, "dda_floor": 0.5, "dda_ceil": 0.85},
	Difficulty.EASY:  {"enemy_dmg": 0.75, "player_dmg": 1.25, "dda_floor": 0.6, "dda_ceil": 1.0},
	Difficulty.NORMAL:{"enemy_dmg": 1.0, "player_dmg": 1.0, "dda_floor": 0.75, "dda_ceil": 1.25},
	Difficulty.HARD:  {"enemy_dmg": 1.3, "player_dmg": 0.85, "dda_floor": 1.0, "dda_ceil": 1.5},
}
const DIFFICULTY_NAMES: Array = ["Story", "Easy", "Normal", "Hard"]

var _corruption_stat_penalty: float = 0.0
var _corruption_gravity_variance: float = 0.0
var _corruption_input_delay: float = 0.0
var _dda_performance_score: float = 50.0
var _dda_recent_deaths: float = 0.0
var _dda_recent_kills: int = 0
var _dda_window_timer: float = 0.0
var _admin_spawn_cooldown: float = 0.0
var _admin_enforcer_script: GDScript = null
var _load_in_progress: bool = false
var _is_saving: bool = false

# ── New Game Plus ─────────────────────────────────────────────────────
var ng_plus_cycle: int = 0  # 0 = first playthrough, 1 = NG+, 2 = NG++, etc.
var ng_plus_available: bool = false  # True after ch10_complete / true ending
var titles_earned: Array = []  # Quest reward titles (e.g. "Arena Legend")
var shop_discount: float = 0.0  # Quest reward shop discount (0.0–1.0)
const NG_PLUS_ENEMY_SCALE: float = 0.25  # +25% enemy HP/DMG per cycle
const NG_PLUS_CARRY_ITEMS: bool = true
const NG_PLUS_CARRY_CHARMS: bool = true
const NG_PLUS_CARRY_LORE: bool = true
const NG_PLUS_CARRY_ACHIEVEMENTS: bool = true  # Achievements already persist independently

func start_new_game_plus() -> void:
	## Begin NG+ — carries over key progression, resets story, scales enemies.
	var carry_level: int = player_stats.get("level", 1)
	var carry_hp: int = player_stats.get("max_hp", 100)
	var carry_mp: int = player_stats.get("max_mp", 50)
	var carry_attack: int = player_stats.get("base_attack", 15)
	var carry_defense: int = player_stats.get("base_defense", 0)
	var carry_gold: int = int(player_stats.get("gold", 0) * 0.5)  # Keep half gold
	var carry_charms: Dictionary = unlocked_charms.duplicate(true) if NG_PLUS_CARRY_CHARMS else {}
	var carry_equipped: Array = equipped_charms.duplicate() if NG_PLUS_CARRY_CHARMS else []
	var carry_cycle: int = ng_plus_cycle + 1
	var carry_arena: Dictionary = arena_stats.duplicate(true)
	var carry_stats: Dictionary = stats.duplicate(true)  # Lifetime stats carry over

	# Save inventory items and equipment before reset
	var carry_items: Dictionary = {}
	var carry_equipment: Dictionary = {"weapon": null, "armor": null, "accessory": null}
	if NG_PLUS_CARRY_ITEMS and has_node("/root/Inventory"):
		carry_items = Inventory.items.duplicate(true)
		carry_equipment = Inventory.equipment.duplicate(true)

	# Save lore before reset (LoreJournal persists independently like Achievements)

	# Full reset
	reset_game()

	# Restore carried-over data
	ng_plus_cycle = carry_cycle
	ng_plus_available = false  # Must beat the game again
	player_stats["level"] = carry_level
	player_stats["max_hp"] = carry_hp
	player_stats["hp"] = carry_hp
	player_stats["max_mp"] = carry_mp
	player_stats["mp"] = carry_mp
	player_stats["base_attack"] = carry_attack
	player_stats["attack"] = carry_attack
	player_stats["base_defense"] = carry_defense
	player_stats["defense"] = carry_defense
	player_stats["gold"] = carry_gold
	unlocked_charms = carry_charms
	equipped_charms = carry_equipped
	arena_stats = carry_arena
	stats = carry_stats
	stats["death_count"] = 0  # Reset per-cycle deaths

	# Carry inventory items (equipment + consumables)
	if NG_PLUS_CARRY_ITEMS and has_node("/root/Inventory"):
		Inventory.items = carry_items
		Inventory.equipment = carry_equipment
		Inventory.gold = carry_gold
		Inventory._apply_equipment_bonuses()

	if OS.is_debug_build():
		print("[NG+] Started cycle %d — Level %d, %d gold, %d charms, %d items" % [
			ng_plus_cycle, carry_level, carry_gold, carry_charms.size(), carry_items.size()])

func get_ng_plus_enemy_multiplier() -> float:
	## Returns the enemy stat multiplier for the current NG+ cycle.
	return 1.0 + (ng_plus_cycle * NG_PLUS_ENEMY_SCALE)


# ══════════════════════════════════════════════════════════════════════════
# LIFECYCLE
# ══════════════════════════════════════════════════════════════════════════

func _ready() -> void:
	_load_accessibility_settings()
	_load_difficulty_setting()
	_setup_custom_cursor()
	_add_gamepad_bindings()
	_build_autosave_indicator()

func _process(delta: float) -> void:
	if current_state != GameState.MENU and not get_tree().paused:
		playtime_seconds += delta
	if speedrun_active and current_state in [GameState.COMBAT, GameState.EXPLORATION]:
		stats["speedrun_seconds"] = stats.get("speedrun_seconds", 0.0) + delta
	_tick_admin_cooldown(delta)
	_tick_dda_window(delta)


# ══════════════════════════════════════════════════════════════════════════
# STATE MANAGEMENT
# ══════════════════════════════════════════════════════════════════════════

func change_state(new_state: GameState) -> void:
	current_state = new_state
	state_changed.emit(new_state)

# Mutually exclusive flag groups — only one flag per group can be true
const EXCLUSIVE_FLAG_GROUPS: Array = [
	["ch1_elara_trusted", "ch1_elara_cautious", "ch1_elara_distrusted"],
	["ch1_knight_spared", "ch1_knight_killed"],
	["ch2_seraphina_recruited", "ch2_seraphina_stayed", "ch2_seraphina_rejected"],
	["ch2_data_wraith_absorbed", "ch2_data_wraith_restored", "ch2_data_wraith_destroyed"],
	["ch3_kaelthas_allied", "ch3_kaelthas_refused", "ch3_kaelthas_challenged"],
	["ch3_sovereign_defiant", "ch3_sovereign_regretful", "ch3_sovereign_doubting"],
	["ch3_lyra_recruited", "ch3_lyra_left_alone"],
	["ch1_oakhaven_warned_villagers", "ch1_oakhaven_left_quietly"],
]

func set_story_flag(flag_name: String, value: bool = true) -> void:
	# Enforce mutual exclusivity — clear conflicting flags in the same group
	if value:
		for group in EXCLUSIVE_FLAG_GROUPS:
			if flag_name in group:
				for other_flag in group:
					if other_flag != flag_name and story_flags.get(other_flag, false):
						push_warning("[STORY] Clearing mutually exclusive flag '%s' (new: '%s')" % [other_flag, flag_name])
						story_flags[other_flag] = false
						story_flag_updated.emit(other_flag, false)
				break
	story_flags[flag_name] = value
	story_flag_updated.emit(flag_name, value)

func get_flag(flag_name: String) -> bool:
	return story_flags.get(flag_name, false)

func get_story_flag(flag_name: String) -> bool:
	## Compatibility alias for older UI/region scripts.
	return get_flag(flag_name)

func has_flag(flag_name: String) -> bool:
	## Alias for get_flag — matches the helper every chapter script uses.
	return story_flags.get(flag_name, false)

func has_elara() -> bool:
	## Centralised Elara-present check used by many chapter scripts.
	return story_flags.get("ch1_elara_trusted", false) or story_flags.get("ch1_elara_cautious", false)


# ══════════════════════════════════════════════════════════════════════════
# CORRUPTION SYSTEM
# ══════════════════════════════════════════════════════════════════════════

func add_glitch_corruption(amount: float) -> void:
	if amount > 0.0 and has_charm("corruption_resist"):
		amount *= get_charm_value("corruption_resist")
	glitch_meter += amount
	if glitch_meter >= 100.0:
		glitch_meter = 100.0
		glitch_meter_changed.emit(glitch_meter)
		trigger_corruption_game_over()
		return
	glitch_meter = clampf(glitch_meter, 0.0, 100.0)
	glitch_meter_changed.emit(glitch_meter)
	_update_corruption_level()

func _update_corruption_level() -> void:
	var new_level = 0
	if glitch_meter >= 75.0:
		new_level = 3
	elif glitch_meter >= 50.0:
		new_level = 2
	elif glitch_meter >= 25.0:
		new_level = 1
	if new_level != corruption_level:
		corruption_level = new_level
		corruption_level_changed.emit(corruption_level)
		_apply_corruption_effects()

func add_root_access_corruption_boss() -> void:
	add_glitch_corruption(5.0)

func add_root_access_corruption_mob() -> void:
	add_glitch_corruption(1.0)

func add_death_corruption() -> void:
	stats["death_count"] = stats.get("death_count", 0) + 1
	record_dda_death()
	var corr_amount = 1.0 * get_difficulty_multiplier()  # 0.8 if struggling = less corruption
	add_glitch_corruption(corr_amount)

var _corruption_game_over_in_progress: bool = false

func trigger_corruption_game_over() -> void:
	if current_state == GameState.GAME_OVER or _corruption_game_over_in_progress:
		return
	_corruption_game_over_in_progress = true
	change_state(GameState.GAME_OVER)
	if has_node("/root/DialogueManager"):
		DialogueManager.hide_dialogue()
	await get_tree().create_timer(2.0).timeout
	if not is_inside_tree():
		return
	if has_node("/root/SceneTransitions"):
		await SceneTransitions.change_scene("res://scenes/game_over.tscn", SceneTransitions.TransitionStyle.GLITCH)
	else:
		get_tree().change_scene_to_file("res://scenes/game_over.tscn")
	_corruption_game_over_in_progress = false  # Reset so future corruption game-overs still work

func _apply_corruption_effects() -> void:
	match corruption_level:
		0, 1:
			_corruption_stat_penalty = 0.0
			_corruption_gravity_variance = 0.0
			_corruption_input_delay = 0.0
		2:
			_corruption_stat_penalty = 0.05
			_corruption_gravity_variance = 0.15
			_corruption_input_delay = 0.0
		3:
			_corruption_stat_penalty = 0.12
			_corruption_gravity_variance = 0.25
			_corruption_input_delay = 0.03
			_try_spawn_enforcers()
	var penalty_mult = 1.0 - _corruption_stat_penalty
	player_stats["attack"] = int(player_stats.get("base_attack", 15) * penalty_mult)
	player_stats["defense"] = int(player_stats.get("base_defense", 0) * penalty_mult)
	if has_node("/root/Inventory"):
		Inventory._apply_equipment_bonuses()
	corruption_effects_updated.emit(corruption_level)

## Public alias for backward compatibility
func apply_corruption_effects() -> void:
	_apply_corruption_effects()

func get_corruption_gravity_multiplier() -> float:
	if _corruption_gravity_variance <= 0.0:
		return 1.0
	var t_val = Time.get_ticks_msec() / 1000.0
	return 1.0 + sin(t_val * 5.0) * _corruption_gravity_variance + sin(t_val * 13.0) * _corruption_gravity_variance * 0.3

func get_corruption_input_delay() -> float:
	return _corruption_input_delay

func get_corruption_damage_multiplier() -> float:
	return 1.0 - _corruption_stat_penalty


# ══════════════════════════════════════════════════════════════════════════
# ADMINISTRATOR ENFORCER SPAWNING (Corruption 75%+ punishment)
# ══════════════════════════════════════════════════════════════════════════

func _tick_admin_cooldown(delta: float) -> void:
	if _admin_spawn_cooldown > 0.0:
		_admin_spawn_cooldown -= delta

## Legacy alias
func _check_admin_spawn_cooldown(delta: float) -> void:
	_tick_admin_cooldown(delta)

func _try_spawn_enforcers() -> void:
	if current_state not in [GameState.EXPLORATION, GameState.COMBAT]:
		return
	if _admin_spawn_cooldown > 0.0:
		return
	_admin_spawn_cooldown = ADMIN_SPAWN_COOLDOWN
	var players = get_tree().get_nodes_in_group("player")
	if players.is_empty():
		return
	var player: Node2D = players[0] as Node2D
	if not player or not player.get_parent():
		return
	var existing = get_tree().get_nodes_in_group("administrator_enforcers")
	if existing.size() >= ADMIN_SPAWN_COUNT:
		return
	if has_node("/root/VFXLibrary"):
		VFXLibrary.spawn_status_indicator("[ALERT] Administrators Dispatched!", player.global_position + Vector2(0, -80), player.get_parent(), false)
	if _admin_enforcer_script == null:
		var script_path = "res://scripts/combat/enemies/administrator_enforcer.gd"
		if ResourceLoader.exists(script_path):
			_admin_enforcer_script = load(script_path) as GDScript
	if _admin_enforcer_script == null:
		push_error("[ADMIN] Failed to load administrator_enforcer.gd")
		return
	var spawn_count = ADMIN_SPAWN_COUNT - existing.size()
	# BUG 15 FIX: Store weakref to parent to guard against scene-race orphan
	var parent_ref = weakref(player.get_parent())
	for i in range(spawn_count):
		var parent_node = parent_ref.get_ref()
		if not is_instance_valid(parent_node):
			break  # Parent freed during spawn loop — abort
		var enforcer = CharacterBody2D.new()
		enforcer.name = "AdminEnforcer_%d" % (i + randi() % 1000)
		enforcer.set_script(_admin_enforcer_script)
		enforcer.add_to_group("administrator_enforcers")
		var offset_x = 200.0 + i * 120.0
		if i % 2 == 1:
			offset_x = -offset_x
		enforcer.global_position = player.global_position + Vector2(offset_x, -50)
		parent_node.call_deferred("add_child", enforcer)

## Legacy alias
func _spawn_administrator_enforcers() -> void:
	_try_spawn_enforcers()


# ══════════════════════════════════════════════════════════════════════════
# CHARM SYSTEM
# ══════════════════════════════════════════════════════════════════════════

func unlock_charm(charm_id: String) -> void:
	if unlocked_charms.has(charm_id):
		push_warning("[CHARM] Already unlocked: %s" % charm_id)
		return
	unlocked_charms[charm_id] = true
	charm_unlocked.emit(charm_id)
	# PASS 36 FIX: Don't auto-equip — let player choose loadout deliberately
	if OS.is_debug_build():
		print("[CHARM] Unlocked: %s (equip via pause menu)" % charm_id)

func is_charm_unlocked(charm_id: String) -> bool:
	return unlocked_charms.get(charm_id, false)

func has_charm(charm_id: String) -> bool:
	return charm_id in equipped_charms

func equip_charm(charm_id: String) -> bool:
	if not is_charm_unlocked(charm_id):
		return false
	if charm_id in equipped_charms:
		return false
	if equipped_charms.size() >= MAX_CHARM_SLOTS:
		return false
	# PASS 36 FIX: Block charm changes during active combat
	if current_state == GameState.COMBAT:
		push_warning("[CHARM] Cannot equip charms during combat")
		return false
	equipped_charms.append(charm_id)
	charm_equipped.emit(charm_id)
	# Apply null_cloak encounter rate modifier immediately on equip
	if charm_id == "null_cloak" and has_node("/root/RandomEncounterSystem"):
		RandomEncounterSystem.apply_encounter_rate_modifier(2.0)
	if OS.is_debug_build():
		print("[CHARM] Equipped: %s (%d/%d slots)" % [charm_id, equipped_charms.size(), MAX_CHARM_SLOTS])
	return true

func unequip_charm(charm_id: String) -> bool:
	var idx = equipped_charms.find(charm_id)
	if idx == -1:
		return false
	# PASS 36 FIX: Block charm changes during active combat
	if current_state == GameState.COMBAT:
		push_warning("[CHARM] Cannot unequip charms during combat")
		return false
	equipped_charms.remove_at(idx)
	charm_unequipped.emit(charm_id)
	# Remove null_cloak encounter rate modifier on unequip
	if charm_id == "null_cloak" and has_node("/root/RandomEncounterSystem"):
		RandomEncounterSystem.apply_encounter_rate_modifier(1.0)
	if OS.is_debug_build():
		print("[CHARM] Unequipped: %s (%d/%d slots)" % [charm_id, equipped_charms.size(), MAX_CHARM_SLOTS])
	return true

func get_charm_value(charm_id: String, default_val: float = 1.0) -> float:
	if not has_charm(charm_id):
		return default_val
	return CHARM_VALUES.get(charm_id, default_val)


# ══════════════════════════════════════════════════════════════════════════
# LEVELING SYSTEM
# ══════════════════════════════════════════════════════════════════════════

func add_xp(amount: int) -> void:
	# DDA bonus: struggling players gain up to 25% more XP
	amount = int(amount * get_player_dda_bonus())
	player_stats["xp"] = player_stats.get("xp", 0) + amount
	if has_node("/root/LevelUpUI"):
		LevelUpUI.on_xp_gained(amount)
	_check_level_up()

## Public alias for backward compat
func check_level_up() -> void:
	_check_level_up()

func _check_level_up() -> void:
	var current_level: int = player_stats.get("level", 1)
	if current_level >= XP_THRESHOLDS.size():
		return
	while current_level < XP_THRESHOLDS.size() - 1 and player_stats["xp"] >= XP_THRESHOLDS[current_level]:
		current_level += 1
		_apply_level_up(current_level)

func _apply_level_up(new_level: int) -> void:
	player_stats["level"] = new_level
	var hp_gain = HP_PER_LEVEL
	var mp_gain = MP_PER_LEVEL
	var atk_gain = DAMAGE_PER_LEVEL
	if has_node("/root/LevelUpUI"):
		hp_gain = LevelUpUI.get_hp_for_level(new_level)
		mp_gain = LevelUpUI.get_mp_for_level(new_level)
		atk_gain = LevelUpUI.get_atk_for_level(new_level)
	player_stats["max_hp"] += hp_gain
	player_stats["hp"] = player_stats["max_hp"]
	player_stats["max_mp"] += mp_gain
	player_stats["mp"] = player_stats["max_mp"]
	player_stats["base_attack"] += atk_gain
	player_stats["attack"] = player_stats["base_attack"]
	player_stats["defense"] = player_stats.get("defense", 0) + DEF_PER_LEVEL
	if has_node("/root/Inventory"):
		Inventory._apply_equipment_bonuses()
	if _corruption_stat_penalty > 0.0:
		_apply_corruption_effects()
	player_leveled_up.emit(new_level)

func get_xp_for_next_level() -> int:
	var level: int = player_stats.get("level", 1)
	if level >= XP_THRESHOLDS.size() - 1:
		return -1
	return XP_THRESHOLDS[level]

func get_xp_progress() -> float:
	var level: int = player_stats.get("level", 1)
	if level >= XP_THRESHOLDS.size() - 1:
		return 1.0
	var prev = XP_THRESHOLDS[level - 1] if level > 1 else 0
	var next = XP_THRESHOLDS[level]
	var range_size = next - prev
	if range_size <= 0:
		return 1.0
	return clampf(float(player_stats["xp"] - prev) / float(range_size), 0.0, 1.0)

func get_player_attack_damage() -> float:
	var base = 15.0 + (player_stats.get("level", 1) - 1) * DAMAGE_PER_LEVEL
	return maxf(base, float(player_stats.get("attack", base)))

func add_gold(amount: int) -> void:
	player_stats["gold"] = maxi(player_stats.get("gold", 0) + amount, 0)
	if has_node("/root/Inventory"):
		Inventory.gold = player_stats["gold"]


## Rest at a rest point — fully heal HP/MP, autosave, show feedback
func rest_at_point(point_name: String = "Rest Point") -> void:
	player_stats["hp"] = player_stats.get("max_hp", 100)
	player_stats["mp"] = player_stats.get("max_mp", 50)
	# Apply null_cloak charm encounter rate reduction if equipped
	if has_node("/root/RandomEncounterSystem"):
		if "null_cloak" in equipped_charms:
			RandomEncounterSystem.apply_encounter_rate_modifier(2.0)  # 2x steps = half encounters
		else:
			RandomEncounterSystem.apply_encounter_rate_modifier(1.0)
	# Autosave at rest point (routes through auto_save for state guards)
	auto_save()
	if OS.is_debug_build():
		print("[REST] Rested at %s — HP/MP fully restored, game saved" % point_name)

func use_perfect_delete() -> bool:
	if perfect_delete_charges <= 0:
		return false
	perfect_delete_charges -= 1
	perfect_delete_used = true
	stats["perfect_deletes_used"] = stats.get("perfect_deletes_used", 0) + 1
	return true


# ══════════════════════════════════════════════════════════════════════════
# DDA (Dynamic Difficulty Adjustment)
# ══════════════════════════════════════════════════════════════════════════

func get_difficulty_multiplier() -> float:
	return remap(_dda_performance_score, DDA_SCORE_FLOOR, DDA_SCORE_CEILING, 0.75, 1.25)

func get_player_dda_bonus() -> float:
	## Returns a bonus multiplier for player damage/soul/heal when struggling.
	## High performance → 1.0 (no bonus), low performance → up to 1.25.
	if _dda_performance_score >= 60.0:
		return 1.0
	return remap(_dda_performance_score, DDA_SCORE_FLOOR, 60.0, 1.35, 1.0)

func get_dda_score() -> float:
	return _dda_performance_score

func get_dda_debug_string() -> String:
	return "DDA: %.1f (mult=%.2f) K:%d D:%.1f" % [
		_dda_performance_score, get_difficulty_multiplier(),
		_dda_recent_kills, _dda_recent_deaths]

# ── Boss fight tracking ────────────────────────────────────────────────
var boss_fight_active: bool = false
var boss_fight_hits_taken: int = 0

## Boss checkpoint system — tracks progress across attempts
## { "boss_id": { "best_phase": int, "best_hp_pct_removed": float, "attempts": int } }
var boss_checkpoints: Dictionary = {}

## Full XP/gold tables for boss partial reward calculation
const BOSS_FULL_REWARDS: Dictionary = {
	"clockwork_automaton": {"xp": 300, "gold": 200},
	"data_wraith": {"xp": 200, "gold": 150},
	"sovereign": {"xp": 2500, "gold": 1500},
}

func start_boss_fight() -> void:
	## Call when a boss fight begins to track flawless achievement.
	boss_fight_active = true
	boss_fight_hits_taken = 0

func record_boss_hit_taken() -> void:
	## Call when player takes damage during a boss fight.
	if boss_fight_active:
		boss_fight_hits_taken += 1

func end_boss_fight() -> void:
	## Call when a boss is defeated. Checks for flawless achievement.
	stats["bosses_killed"] = stats.get("bosses_killed", 0) + 1
	if boss_fight_active and boss_fight_hits_taken == 0:
		if has_node("/root/Achievements"):
			Achievements.try_unlock("no_damage_boss")
	boss_fight_active = false

func record_boss_progress(boss_id: String, hp_pct_removed: float, phase_reached: int) -> void:
	## Record checkpoint data when player dies during a boss fight.
	## hp_pct_removed: fraction of boss max HP removed (0.0 - 1.0).
	if boss_id.is_empty():
		return
	if boss_id not in boss_checkpoints:
		boss_checkpoints[boss_id] = {"best_phase": 0, "best_hp_pct_removed": 0.0, "attempts": 0}
	var data: Dictionary = boss_checkpoints[boss_id]
	data["attempts"] = data.get("attempts", 0) + 1
	data["best_phase"] = maxi(data.get("best_phase", 0), phase_reached)
	data["best_hp_pct_removed"] = maxf(data.get("best_hp_pct_removed", 0.0), hp_pct_removed)

func get_boss_checkpoint(boss_id: String) -> Dictionary:
	## Returns checkpoint data for a boss or empty dict if none.
	return boss_checkpoints.get(boss_id, {})

func clear_boss_checkpoint(boss_id: String) -> void:
	## Clear checkpoint after boss is fully defeated (no more mercy).
	boss_checkpoints.erase(boss_id)

func award_partial_boss_rewards(boss_id: String, hp_pct_removed: float) -> Dictionary:
	## Award XP/gold proportional to boss damage dealt. Returns amounts.
	## Only awards up to 30% of full rewards on death (to keep full kill rewarding).
	var full = BOSS_FULL_REWARDS.get(boss_id, {"xp": 100, "gold": 50})
	var fraction = clampf(hp_pct_removed, 0.0, 1.0) * 0.3  # max 30% partial
	var xp_award: int = int(full["xp"] * fraction)
	var gold_award: int = int(full["gold"] * fraction)
	if xp_award > 0:
		add_xp(xp_award)
	if gold_award > 0:
		add_gold(gold_award)
	return {"xp": xp_award, "gold": gold_award}

func get_boss_retry_hp_fraction(boss_id: String) -> float:
	## On retry, if player reached phase 3+ in a multi-phase boss (3+ attempts),
	## boss starts with reduced HP to acknowledge progress. Returns 1.0 = full HP.
	var data = get_boss_checkpoint(boss_id)
	if data.is_empty():
		return 1.0
	var attempts: int = data.get("attempts", 0)
	var best_phase: int = data.get("best_phase", 0)
	# After 3+ attempts AND reaching phase 3+, skip to phase 2 HP (~80%)
	if attempts >= 3 and best_phase >= 3:
		return 0.8
	# After 5+ attempts AND reaching phase 2+, start at 90%
	if attempts >= 5 and best_phase >= 2:
		return 0.9
	return 1.0

func record_dda_kill() -> void:
	_dda_recent_kills += 1
	_recalc_dda()

func record_dda_death() -> void:
	_dda_recent_deaths += 1
	_recalc_dda()

func record_dda_hit_taken(_damage: float = 0.0) -> void:
	## Softer signal than death: 3 hits ≈ 1 death for DDA weighting.
	_dda_recent_deaths += 0.3
	_recalc_dda()

func _recalc_dda() -> void:
	var old_score = _dda_performance_score
	if _dda_recent_deaths == 0 and _dda_recent_kills == 0:
		_dda_performance_score = lerpf(_dda_performance_score, 50.0, 0.3)
	elif _dda_recent_deaths == 0:
		_dda_performance_score = minf(DDA_SCORE_CEILING, 50.0 + _dda_recent_kills * 3.0)
	else:
		var ratio = float(_dda_recent_kills) / float(_dda_recent_deaths)
		_dda_performance_score = clampf(ratio * 15.0 + 10.0, DDA_SCORE_FLOOR, DDA_SCORE_CEILING)
	if absf(old_score - _dda_performance_score) > 5.0:
		difficulty_adjusted.emit(get_difficulty_multiplier())
	if OS.is_debug_build():
		print(get_dda_debug_string())

func _tick_dda_window(delta: float) -> void:
	_dda_window_timer += delta
	if _dda_window_timer >= DDA_WINDOW_SECONDS:
		_dda_window_timer = 0.0
		_dda_recent_kills = int(_dda_recent_kills * 0.5)
		_dda_recent_deaths = floorf(_dda_recent_deaths * 0.5)
		_recalc_dda()

## Legacy alias
func _update_dda_score() -> void:
	_recalc_dda()


# ══════════════════════════════════════════════════════════════════════════
# ARENA SYSTEM
# ══════════════════════════════════════════════════════════════════════════

func record_arena_win() -> void:
	arena_stats["total_wins"] = arena_stats.get("total_wins", 0) + 1
	arena_stats["win_streak"] = arena_stats.get("win_streak", 0) + 1
	if arena_stats["win_streak"] > arena_stats.get("best_streak", 0):
		arena_stats["best_streak"] = arena_stats["win_streak"]

func record_arena_loss() -> void:
	arena_stats["total_losses"] = arena_stats.get("total_losses", 0) + 1
	arena_stats["win_streak"] = 0

func get_arena_streak_multiplier() -> float:
	var streak: int = arena_stats.get("win_streak", 0)
	if streak >= 10: return 2.5
	if streak >= 7: return 2.0
	if streak >= 5: return 1.75
	if streak >= 3: return 1.5
	return 1.0

func advance_arena_tier() -> void:
	var idx = TIER_ORDER.find(arena_stats.get("current_tier", "bronze"))
	if idx >= 0 and idx < TIER_ORDER.size() - 1:
		arena_stats["current_tier"] = TIER_ORDER[idx + 1]
		arena_stats["highest_tier_reached"] = arena_stats["current_tier"]


# ══════════════════════════════════════════════════════════════════════════
# SOURCE KEY & COMPLETION
# ══════════════════════════════════════════════════════════════════════════

func collect_source_key(fragment_number: int) -> void:
	if fragment_number < 1 or fragment_number > 7:
		push_warning("[PROGRESSION] Ignoring invalid Source Key fragment: %d" % fragment_number)
		return
	var flag = "source_key_fragment_%d" % fragment_number
	if not story_flags.get(flag, false):
		set_story_flag(flag, true)
		source_key_count += 1

func normalize_source_key_progression() -> void:
	# Keep legacy chapter-specific fragment flags aligned with generic Source Key flags.
	if story_flags.get("ch3_fragment_3_collected", false):
		story_flags["source_key_fragment_3"] = true
	if story_flags.get("ch3_fragment_4_collected", false):
		story_flags["source_key_fragment_4"] = true
	if story_flags.get("ch4_fragment_5_collected", false):
		story_flags["source_key_fragment_5"] = true
	var counted_fragments: int = 0
	for i in range(1, 8):
		if story_flags.get("source_key_fragment_%d" % i, false):
			counted_fragments += 1
	source_key_count = counted_fragments

func get_completion_percentage() -> float:
	## Unified completion formula — matches CompletionTracker categories.
	var total_done: float = 0.0
	var total_all: float = 0.0

	# Story chapters currently implemented
	var implemented_chapters: Array[String] = ["ch1_complete", "ch2_complete", "ch3_complete", "ch4_complete", "ch5_complete"]
	total_all += float(implemented_chapters.size())
	for ch in implemented_chapters:
		if get_flag(ch): total_done += 1.0

	# Source key fragments — count only implemented ones (2 currently)
	var implemented_fragments: int = 0
	for i in range(1, 8):
		if DEFAULT_STORY_FLAGS.has("source_key_fragment_%d" % i):
			implemented_fragments += 1
	total_all += float(implemented_fragments)
	total_done += float(clampi(source_key_count, 0, implemented_fragments))

	# Key progression flags — mutually exclusive groups count as 1 slot each
	# Elara trust: 1 of (trusted, cautious, distrusted)
	total_all += 1.0
	if get_flag("ch1_elara_trusted") or get_flag("ch1_elara_cautious") or get_flag("ch1_elara_distrusted"): total_done += 1.0
	# Individual flags
	var individual_flags = ["root_access_unlocked", "ch2_seraphina_recruited", "ch3_lyra_recruited", "ch3_kaelthas_defeated"]
	total_all += float(individual_flags.size())
	for f in individual_flags:
		if get_flag(f): total_done += 1.0

	# Side quests
	if has_node("/root/SideQuestManager"):
		total_all += float(SideQuestManager.QUEST_DATABASE.size())
		for qid in SideQuestManager.quests:
			if SideQuestManager.quests[qid].get("state", 0) == SideQuestManager.QuestState.COMPLETED:
				total_done += 1.0

	# Secrets
	if has_node("/root/SideQuestManager"):
		total_all += float(SideQuestManager.SECRETS_DATABASE.size())
		total_done += float(SideQuestManager.secrets_found.size())

	# Lore
	if has_node("/root/LoreJournal"):
		var lore_prog: Dictionary = LoreJournal.get_progress()
		total_all += float(lore_prog.get("total", 0))
		total_done += float(lore_prog.get("discovered", 0))

	# Achievements
	if has_node("/root/Achievements"):
		total_all += float(Achievements.ACHIEVEMENTS.size())
		total_done += float(Achievements.unlocked.size())

	return clampf((total_done / total_all) * 100.0, 0.0, 100.0) if total_all > 0.0 else 0.0

func format_speedrun_time() -> String:
	var secs: float = stats.get("speedrun_seconds", 0.0)
	@warning_ignore("integer_division")
	var hours = int(secs) / 3600
	@warning_ignore("integer_division")
	var minutes = (int(secs) % 3600) / 60
	var seconds = int(secs) % 60
	var ms = int(fmod(secs, 1.0) * 100)
	if hours > 0:
		return "%d:%02d:%02d.%02d" % [hours, minutes, seconds, ms]
	return "%02d:%02d.%02d" % [minutes, seconds, ms]

func get_revival_scene() -> String:
	if get_flag("ch3_fractured_wastes_entered"):
		return "res://scenes/regions/fractured_wastes_region.tscn"
	if get_flag("ch2_ironhold_entered"):
		return "res://scenes/regions/ironhold_region.tscn"
	if get_flag("ch1_oakhaven_entered"):
		return "res://scenes/regions/oakhaven_region.tscn"
	if get_flag("ch1_awakening_complete"):
		return "res://scenes/overworld/overworld.tscn"
	return "res://scenes/chapter1/glitch_crater_awakening.tscn"


# ══════════════════════════════════════════════════════════════════════════
# SAVE / LOAD
# ══════════════════════════════════════════════════════════════════════════

func save_game(slot: int = 0) -> bool:
	if slot not in VALID_SAVE_SLOTS:
		push_error("[SAVE] Invalid slot: %d (valid: %s)" % [slot, str(VALID_SAVE_SLOTS)])
		return false
	if _is_saving:
		push_warning("[SAVE] Save already in progress, ignoring")
		return false
	_is_saving = true
	# Block manual saves during unsafe states (autosave is more permissive)
	if slot != AUTOSAVE_SLOT:
		if current_state in [GameState.COMBAT, GameState.CUTSCENE, GameState.GAME_OVER]:
			push_warning("[SAVE] Cannot manual save during %s" % GameState.keys()[current_state])
			_is_saving = false
			return false
	# Block ALL saves during scene transitions
	if has_node("/root/SceneTransitions") and SceneTransitions.is_transitioning:
		push_warning("[SAVE] Cannot save during scene transition")
		_is_saving = false
		return false
	var save_data = {
		"version": SAVE_VERSION,
		"timestamp": Time.get_datetime_string_from_system(),
		"player_stats": player_stats.duplicate(true),
		"relationships": relationships.duplicate(true),
		"story_flags": story_flags.duplicate(true),
		"glitch_meter": glitch_meter,
		"corruption_level": corruption_level,
		"perfect_delete_charges": perfect_delete_charges,
		"perfect_delete_used": perfect_delete_used,
		"current_scene": get_tree().current_scene.scene_file_path if is_instance_valid(get_tree().current_scene) else "",
		"current_chapter": current_chapter,
		"current_state": current_state,
		"playtime_seconds": playtime_seconds,
		"source_key_count": source_key_count,
		"speedrun_active": speedrun_active,
		"arena_stats": arena_stats.duplicate(true),
		"unlocked_charms": unlocked_charms.duplicate(true),
		"equipped_charms": equipped_charms.duplicate(),
		"stats": stats.duplicate(true),
		"dda_performance_score": _dda_performance_score,
		"dda_recent_deaths": _dda_recent_deaths,
		"dda_recent_kills": _dda_recent_kills,
		"current_region": current_region,
		"player_overworld_position": {"x": player_overworld_position.x, "y": player_overworld_position.y},
		"ng_plus_cycle": ng_plus_cycle,
		"boss_checkpoints": boss_checkpoints.duplicate(true),
		"titles_earned": titles_earned.duplicate(),
		"shop_discount": shop_discount,
	}
	if has_node("/root/Inventory"):
		save_data["inventory_items"] = Inventory.items.duplicate(true)
		save_data["inventory_gold"] = Inventory.gold
		save_data["inventory_equipment"] = Inventory.equipment.duplicate(true)
	if has_node("/root/Achievements"):
		save_data["achievements"] = Achievements.get_save_data()
	if has_node("/root/ChoiceConsequences"):
		save_data["choice_consequences"] = ChoiceConsequences.get_save_data()
	if has_node("/root/SideQuestManager"):
		save_data["side_quests"] = SideQuestManager.get_save_data()
	if has_node("/root/LoreJournal"):
		save_data["lore_journal"] = LoreJournal.get_save_data()
	var players = get_tree().get_nodes_in_group("player")
	if not players.is_empty():
		var pos: Vector2 = players[0].global_position
		save_data["player_position"] = {"x": pos.x, "y": pos.y}
	var save_path = "user://save_slot_%d.save" % slot
	# Create backup of existing save before overwriting
	_backup_save_file(save_path)
	save_data["_checksum"] = _calculate_save_checksum(save_data)
	# Pass 55: Atomic save — write to temp then rename
	var tmp_path = save_path + ".tmp"
	var file = FileAccess.open(tmp_path, FileAccess.WRITE)
	if not file:
		push_error("[SAVE] Failed to write slot %d" % slot)
		_is_saving = false
		return false
	file.store_string(JSON.stringify(save_data, "\t"))
	file.close()
	# Atomic rename — prevents partial file on crash
	if DirAccess.rename_absolute(tmp_path, save_path) != OK:
		push_error("[SAVE] Atomic rename failed for slot %d" % slot)
		DirAccess.remove_absolute(tmp_path)  # Clean up orphaned .tmp
		_is_saving = false
		return false
	if OS.is_debug_build():
		print("[SAVE] Slot %d saved successfully (v%s)" % [slot, SAVE_VERSION])
	_is_saving = false
	return true

func load_game(slot: int = 0) -> bool:
	if _load_in_progress:
		push_warning("[LOAD] Load already in progress, ignoring")
		return false
	_load_in_progress = true
	if slot not in VALID_SAVE_SLOTS:
		push_error("[LOAD] Invalid slot: %d (valid: %s)" % [slot, str(VALID_SAVE_SLOTS)])
		_load_in_progress = false
		return false
	# Block loads during scene transitions (prevents racing transitions)
	if has_node("/root/SceneTransitions") and SceneTransitions.is_transitioning:
		push_warning("[LOAD] Cannot load during scene transition")
		_load_in_progress = false
		return false
	var save_path = "user://save_slot_%d.save" % slot
	if not FileAccess.file_exists(save_path):
		push_error("[LOAD] No save at slot %d" % slot)
		_load_in_progress = false
		return false
	var file = FileAccess.open(save_path, FileAccess.READ)
	if not file:
		push_error("[LOAD] Cannot open slot %d" % slot)
		_load_in_progress = false
		return false
	var json_text = file.get_as_text()
	file.close()
	var json = JSON.new()
	if json.parse(json_text) != OK:
		push_error("[LOAD] Parse error slot %d — attempting backup recovery" % slot)
		if _try_load_backup(save_path):
			_load_in_progress = false
			return await load_game(slot)  # Recursive call — load_game is async
		_load_in_progress = false
		return false
	if not json.data is Dictionary:
		push_error("[LOAD] Invalid data slot %d" % slot)
		_load_in_progress = false
		return false
	var data: Dictionary = json.data
	# ── Checksum verification ──
	var saved_checksum = data.get("_checksum", -1)
	if saved_checksum != -1:
		if _calculate_save_checksum(data) != int(saved_checksum):
			push_warning("[LOAD] Checksum mismatch in slot %d — save may be tampered/corrupted" % slot)
			# Continue loading (warn-only) — the backup system handles actual corruption
	data.erase("_checksum")  # Strip internal field before restoring
	# Validate required keys
	for key in REQUIRED_SAVE_KEYS:
		if not data.has(key):
			push_error("[LOAD] Missing required key '%s' in slot %d" % [key, slot])
			_load_in_progress = false
			return false
	# Version check and migration
	var save_version: String = data.get("version", "0.0.0")
	if save_version != SAVE_VERSION:
		if save_version in COMPATIBLE_SAVE_VERSIONS:
			push_warning("[LOAD] Migrating save from v%s to v%s" % [save_version, SAVE_VERSION])
			data = _migrate_save_data(data, save_version)
		else:
			push_error("[LOAD] Incompatible save version: %s (need %s)" % [save_version, SAVE_VERSION])
			_load_in_progress = false
			return false
	# Restore with safe merging
	player_stats = _merge_dict(DEFAULT_PLAYER_STATS.duplicate(true), data.get("player_stats", {}))
	relationships = _merge_dict(DEFAULT_RELATIONSHIPS.duplicate(true), data.get("relationships", {}))
	story_flags = _merge_dict(DEFAULT_STORY_FLAGS.duplicate(true), data.get("story_flags", {}), true)
	arena_stats = _merge_dict(DEFAULT_ARENA_STATS.duplicate(true), data.get("arena_stats", {}))
	stats = _merge_dict(DEFAULT_SESSION_STATS.duplicate(true), data.get("stats", {}))
	glitch_meter = float(data.get("glitch_meter", 0.0))
	corruption_level = int(data.get("corruption_level", 0))
	perfect_delete_charges = int(data.get("perfect_delete_charges", 3))
	perfect_delete_used = data.get("perfect_delete_used", false)
	playtime_seconds = float(data.get("playtime_seconds", 0.0))
	current_chapter = int(data.get("current_chapter", 1))
	source_key_count = int(data.get("source_key_count", 0))
	normalize_source_key_progression()
	speedrun_active = data.get("speedrun_active", false)
	_dda_performance_score = float(data.get("dda_performance_score", 50.0))
	_dda_recent_deaths = float(data.get("dda_recent_deaths", 0.0))
	_dda_recent_kills = int(data.get("dda_recent_kills", 0))
	_dda_window_timer = 0.0
	_admin_spawn_cooldown = 0.0
	# Restore region/overworld data
	current_region = data.get("current_region", "")
	ng_plus_cycle = int(data.get("ng_plus_cycle", 0))
	ng_plus_available = story_flags.get("ch10_complete", false)
	var saved_ow_pos = data.get("player_overworld_position", {})
	if saved_ow_pos is Dictionary and not saved_ow_pos.is_empty():
		player_overworld_position = Vector2(saved_ow_pos.get("x", 1500.0), saved_ow_pos.get("y", 1100.0))
	# Reset boss fight state (stale from previous session)
	boss_fight_active = false
	boss_fight_hits_taken = 0
	# Restore boss checkpoints (mercy system progress)
	var saved_boss_cp = data.get("boss_checkpoints", {})
	if saved_boss_cp is Dictionary:
		boss_checkpoints = saved_boss_cp.duplicate(true)
	else:
		boss_checkpoints = {}
	# Restore quest reward properties
	titles_earned.clear()
	var saved_titles = data.get("titles_earned", [])
	if saved_titles is Array:
		titles_earned.assign(saved_titles)
	shop_discount = clampf(float(data.get("shop_discount", 0.0)), 0.0, 1.0)
	# Restore charms
	unlocked_charms.clear()
	var saved_charms = data.get("unlocked_charms", {})
	if saved_charms is Dictionary:
		for key in saved_charms:
			unlocked_charms[key] = saved_charms[key]
	equipped_charms.clear()
	var saved_equipped = data.get("equipped_charms", [])
	if saved_equipped is Array:
		for charm_id in saved_equipped:
			if charm_id is String and is_charm_unlocked(charm_id):
				equipped_charms.append(charm_id)
	# Restore inventory with validation
	if has_node("/root/Inventory"):
		var saved_items = data.get("inventory_items", {})
		Inventory.items.clear()
		if saved_items is Dictionary:
			for item_id in saved_items:
				var qty = saved_items[item_id]
				if item_id is String and Inventory.ITEMS.has(item_id) and (qty is float or qty is int) and int(qty) > 0:  # Pass 55: Fix operator precedence
					Inventory.items[item_id] = int(qty)
				else:
					push_warning("[LOAD] Skipping invalid inventory entry: %s" % str(item_id))
		Inventory.gold = maxi(0, int(data.get("inventory_gold", 0)))
		var saved_eq = data.get("inventory_equipment", {})
		if saved_eq is Dictionary:
			Inventory.equipment = {"weapon": null, "armor": null, "accessory": null}
			for slot_key in ["weapon", "armor", "accessory"]:
				var eq_val = saved_eq.get(slot_key, null)
				if eq_val is String and eq_val != "" and Inventory.ITEMS.has(eq_val):
					Inventory.equipment[slot_key] = eq_val
				elif eq_val is String and eq_val != "":
					push_warning("[LOAD] Equipped item '%s' not in ITEMS database — clearing slot '%s'" % [eq_val, slot_key])
		else:
			Inventory.equipment = {"weapon": null, "armor": null, "accessory": null}
		# Force gold sync — Inventory.gold is source of truth after load
		player_stats["gold"] = Inventory.gold
	if has_node("/root/Achievements"):
		var saved_ach = data.get("achievements", {})
		if saved_ach is Dictionary:
			Achievements.load_save_data(saved_ach)
	# Restore ChoiceConsequences (buffs, party members)
	if has_node("/root/ChoiceConsequences"):
		var saved_cc = data.get("choice_consequences", {})
		if saved_cc is Dictionary and not saved_cc.is_empty():
			ChoiceConsequences.load_save_data(saved_cc)
		else:
			# Older save without choice_consequences data — rebuild from flags
			ChoiceConsequences.rebuild_from_flags()
	# Restore SideQuestManager (quest progress, secrets)
	if has_node("/root/SideQuestManager"):
		var saved_sq = data.get("side_quests", {})
		if saved_sq is Dictionary and not saved_sq.is_empty():
			SideQuestManager.load_save_data(saved_sq)
		# Older saves without side quest data — quests stay hidden (no migration needed)
	# Restore LoreJournal (discovered lore entries)
	if has_node("/root/LoreJournal"):
		var saved_lore = data.get("lore_journal", {})
		if saved_lore is Dictionary and not saved_lore.is_empty():
			LoreJournal.load_save_data(saved_lore)
	_apply_corruption_effects()
	glitch_meter_changed.emit(glitch_meter)
	corruption_level_changed.emit(corruption_level)
	var saved_scene: String = data.get("current_scene", "")
	if saved_scene and ResourceLoader.exists(saved_scene):
		if has_node("/root/SceneTransitions"):
			await SceneTransitions.change_scene(saved_scene)
		else:
			get_tree().change_scene_to_file(saved_scene)
		var saved_pos = data.get("player_position", {})
		if saved_pos is Dictionary and not saved_pos.is_empty():
			await get_tree().process_frame
			if not is_inside_tree(): return true
			await get_tree().process_frame
			if not is_inside_tree(): return true
			var restore_players = get_tree().get_nodes_in_group("player")
			if not restore_players.is_empty():
				restore_players[0].global_position = Vector2(saved_pos.get("x", 0.0), saved_pos.get("y", 0.0))
	# Restore game state — force safe states only after load
	var saved_state: int = int(data.get("current_state", GameState.EXPLORATION))
	if saved_state in [GameState.MENU, GameState.COMBAT, GameState.CUTSCENE, GameState.GAME_OVER]:
		saved_state = GameState.EXPLORATION
	change_state(saved_state)
	if OS.is_debug_build():
		print("[LOAD] Slot %d loaded successfully (v%s)" % [slot, save_version])
	_load_in_progress = false
	return true

func save_exists(slot: int = 0) -> bool:
	return FileAccess.file_exists("user://save_slot_%d.save" % slot)

func delete_save(slot: int = 0) -> void:
	if slot not in VALID_SAVE_SLOTS:
		push_error("[SAVE] Invalid delete slot: %d" % slot)
		return
	var path = "user://save_slot_%d.save" % slot
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(path)
	# Clean up backup and temp files to prevent stale data resurrection
	var bak_path = path + ".bak"
	var tmp_path = path + ".tmp"
	if FileAccess.file_exists(bak_path):
		DirAccess.remove_absolute(bak_path)
	if FileAccess.file_exists(tmp_path):
		DirAccess.remove_absolute(tmp_path)

func get_save_info(slot: int = 0) -> Dictionary:
	if slot not in VALID_SAVE_SLOTS:
		return {"exists": false}
	var save_path = "user://save_slot_%d.save" % slot
	if not FileAccess.file_exists(save_path):
		return {"exists": false}
	var file = FileAccess.open(save_path, FileAccess.READ)
	if not file:
		return {"exists": false}
	var json = JSON.new()
	var json_text = file.get_as_text()
	file.close()
	if json.parse(json_text) != OK:
		return {"exists": false}
	if not json.data is Dictionary:
		return {"exists": false}
	var data: Dictionary = json.data
	var ps_data = data.get("player_stats", {})
	var ps: Dictionary = ps_data if ps_data is Dictionary else {}
	return {
		"exists": true,
		"timestamp": data.get("timestamp", "Unknown"),
		"playtime": data.get("playtime_seconds", 0.0),
		"glitch_meter": data.get("glitch_meter", 0.0),
		"corruption_level": data.get("corruption_level", 0),
		"current_chapter": data.get("current_chapter", 1),
		"player_level": ps.get("level", 1) if ps is Dictionary else 1,
		"player_hp": ps.get("hp", 0) if ps is Dictionary else 0,
		"player_max_hp": ps.get("max_hp", 100) if ps is Dictionary else 100,
		"current_scene": data.get("current_scene", ""),
		"perfect_delete_used": data.get("perfect_delete_used", false),
		"story_flags": data.get("story_flags", {}),
		"ng_plus_cycle": data.get("ng_plus_cycle", 0),
	}

func auto_save() -> void:
	if current_state in [GameState.GAME_OVER, GameState.MENU, GameState.COMBAT, GameState.CUTSCENE, GameState.DIALOGUE]:
		return
	if has_node("/root/SceneTransitions") and SceneTransitions.is_transitioning:
		return
	show_save_indicator()  # Pass 57: Visual feedback
	save_game(AUTOSAVE_SLOT)
	# Pass 53: Play save complete SFX
	if has_node("/root/SFXManager"):
		SFXManager.play("save_complete")


# ══════════════════════════════════════════════════════════════════════════
# RESET
# ══════════════════════════════════════════════════════════════════════════

func reset_game() -> void:
	glitch_meter = 0.0
	corruption_level = 0
	_corruption_game_over_in_progress = false
	_corruption_stat_penalty = 0.0
	_corruption_gravity_variance = 0.0
	_corruption_input_delay = 0.0
	unlocked_charms.clear()
	equipped_charms.clear()
	perfect_delete_charges = 3
	perfect_delete_used = false
	current_chapter = 1
	playtime_seconds = 0.0
	source_key_count = 0
	speedrun_active = false
	_dda_performance_score = 50.0
	_dda_recent_deaths = 0.0
	_dda_recent_kills = 0
	_dda_window_timer = 0.0
	_admin_spawn_cooldown = 0.0
	_load_in_progress = false
	ng_plus_cycle = 0
	ng_plus_available = false
	titles_earned.clear()
	shop_discount = 0.0
	player_stats = DEFAULT_PLAYER_STATS.duplicate(true)
	relationships = DEFAULT_RELATIONSHIPS.duplicate(true)
	story_flags = DEFAULT_STORY_FLAGS.duplicate(true)
	arena_stats = DEFAULT_ARENA_STATS.duplicate(true)
	stats = DEFAULT_SESSION_STATS.duplicate(true)
	if has_node("/root/Inventory"):
		Inventory.items.clear()
		Inventory.equipment = {"weapon": null, "armor": null, "accessory": null}
		Inventory.gold = 0
		if Inventory.has_method("add_starting_items"):
			Inventory.add_starting_items()
	if has_node("/root/SideQuestManager"):
		SideQuestManager.reset()
	if has_node("/root/PauseScreen"):
		PauseScreen.set_meta("cutscene_blocked", false)
		if PauseScreen.is_paused:
			PauseScreen.is_paused = false
			PauseScreen.visible = false
	change_state(GameState.MENU)


# ══════════════════════════════════════════════════════════════════════════
# UTILITY
# ══════════════════════════════════════════════════════════════════════════

func _merge_dict(base: Dictionary, overlay: Dictionary, preserve_extra_keys: bool = false) -> Dictionary:
	if not overlay is Dictionary:
		return base
	for key in overlay:
		if base.has(key) or preserve_extra_keys:
			base[key] = overlay[key]
	return base

func _calculate_save_checksum(data: Dictionary) -> int:
	## Hash a canonical save payload so JSON parse numeric/order changes do not false-fail.
	var canonical_payload = _canonicalize_save_value(data)
	return JSON.stringify(canonical_payload).hash()

func _canonicalize_save_value(value: Variant) -> Variant:
	if value is Dictionary:
		var output: Dictionary = {}
		var keys: Array = value.keys()
		keys.sort_custom(func(a, b): return str(a) < str(b))
		for key in keys:
			if str(key) == "_checksum":
				continue
			output[str(key)] = _canonicalize_save_value(value[key])
		return output
	if value is Array:
		var output_array: Array = []
		for entry in value:
			output_array.append(_canonicalize_save_value(entry))
		return output_array
	if value is bool:
		return value
	if value is int or value is float:
		return _canonical_number_string(value)
	return value

func _canonical_number_string(value: Variant) -> String:
	var number: float = float(value)
	var rounded: float = roundf(number)
	if absf(number - rounded) <= 0.000001:
		return str(int(rounded))
	var text: String = "%.8f" % number
	while text.ends_with("0"):
		text = text.left(text.length() - 1)
	if text.ends_with("."):
		text = text.left(text.length() - 1)
	return text

func _backup_save_file(save_path: String) -> void:
	## Create a .bak copy of an existing save before overwriting (atomic).
	if not FileAccess.file_exists(save_path):
		return
	var old_file = FileAccess.open(save_path, FileAccess.READ)
	if not old_file:
		return
	var backup_path = save_path + ".bak"
	var tmp_bak_path = backup_path + ".tmp"
	var bak_file = FileAccess.open(tmp_bak_path, FileAccess.WRITE)
	if bak_file:
		bak_file.store_string(old_file.get_as_text())
		bak_file.close()
		# Atomic rename — prevents truncated .bak on crash
		if DirAccess.rename_absolute(tmp_bak_path, backup_path) != OK:
			DirAccess.remove_absolute(tmp_bak_path)
	old_file.close()

func _try_load_backup(save_path: String) -> bool:
	## Attempt to restore a .bak file when the primary save is corrupted.
	var backup_path = save_path + ".bak"
	if not FileAccess.file_exists(backup_path):
		return false
	var bak_file = FileAccess.open(backup_path, FileAccess.READ)
	if not bak_file:
		return false
	var bak_text = bak_file.get_as_text()
	bak_file.close()
	# Verify backup is valid JSON
	var json = JSON.new()
	if json.parse(bak_text) != OK or not json.data is Dictionary:
		push_error("[LOAD] Backup also corrupted: %s" % backup_path)
		return false
	# Validate backup has required save keys before trusting it
	var bak_data: Dictionary = json.data
	for key in REQUIRED_SAVE_KEYS:
		if not bak_data.has(key):
			push_error("[LOAD] Backup missing required key '%s': %s" % [key, backup_path])
			return false
	# Preserve the corrupted file for inspection before overwriting
	var corrupted_path = save_path + ".corrupted"
	if FileAccess.file_exists(save_path):
		DirAccess.rename_absolute(save_path, corrupted_path)
	# Restore backup over corrupted save
	var restore_file = FileAccess.open(save_path, FileAccess.WRITE)
	if not restore_file:
		return false
	restore_file.store_string(bak_text)
	restore_file.close()
	push_warning("[LOAD] Restored save from backup: %s (corrupt file saved as %s)" % [backup_path, corrupted_path])
	return true

func _migrate_save_data(data: Dictionary, from_version: String) -> Dictionary:
	## Migrate save data from older versions to current format.
	if from_version == "1.0.0":
		# v1.0.0 → v1.1.0: Added arena_stats, speedrun_active, DDA fields
		if not data.has("arena_stats"):
			data["arena_stats"] = DEFAULT_ARENA_STATS.duplicate(true)
		if not data.has("speedrun_active"):
			data["speedrun_active"] = false
		if not data.has("dda_performance_score"):
			data["dda_performance_score"] = 50.0
		if not data.has("dda_recent_deaths"):
			data["dda_recent_deaths"] = 0.0
		if not data.has("dda_recent_kills"):
			data["dda_recent_kills"] = 0
		from_version = "1.1.0"
	if from_version == "1.1.0":
		# v1.1.0 → v1.2.0: Added choice_consequences, checksum
		if not data.has("choice_consequences"):
			data["choice_consequences"] = {}
		from_version = "1.2.0"
	data["version"] = SAVE_VERSION
	return data

# ══════════════════════════════════════════════════════════════════════════
# ACCESSIBILITY SETTINGS
# ══════════════════════════════════════════════════════════════════════════

func set_accessibility(key: String, value: Variant) -> void:
	## Set an accessibility option and persist it.
	if not DEFAULT_ACCESSIBILITY_SETTINGS.has(key):
		push_warning("[ACCESS] Unknown accessibility key: %s" % key)
		return
	accessibility_settings[key] = value
	accessibility_setting_changed.emit(key, value)
	_save_accessibility_settings()
	if OS.is_debug_build():
		print("[ACCESS] %s = %s" % [key, str(value)])

func get_accessibility(key: String, default: Variant = null) -> Variant:
	## Read an accessibility option.
	return accessibility_settings.get(key, DEFAULT_ACCESSIBILITY_SETTINGS.get(key, default))

func get_screen_shake_multiplier() -> float:
	## Returns 0.0–1.0 multiplier for screen shake intensity.
	if not accessibility_settings.get("screen_shake_enabled", true):
		return 0.0
	return clampf(float(accessibility_settings.get("screen_shake_intensity", 1.0)), 0.0, 1.0)

func get_text_size_scale() -> float:
	return clampf(float(accessibility_settings.get("text_size_scale", 1.0)), 0.8, 2.0)

func is_reduced_motion() -> bool:
	return accessibility_settings.get("reduced_motion", false)

func is_high_contrast() -> bool:
	return accessibility_settings.get("high_contrast", false)

func is_tutorial_hints_enabled() -> bool:
	return accessibility_settings.get("tutorial_hints_enabled", true)

func get_subtitle_size_px() -> int:
	match accessibility_settings.get("subtitle_size", "medium"):
		"small": return 14
		"large": return 22
		_: return 18  # medium

func _save_accessibility_settings() -> void:
	var path = "user://accessibility.cfg"
	var file = FileAccess.open(path, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(accessibility_settings, "\t"))
		file.close()

func _load_accessibility_settings() -> void:
	var path = "user://accessibility.cfg"
	if not FileAccess.file_exists(path):
		return
	var file = FileAccess.open(path, FileAccess.READ)
	if not file:
		return
	var json = JSON.new()
	if json.parse(file.get_as_text()) == OK and json.data is Dictionary:
		for key in json.data:
			if DEFAULT_ACCESSIBILITY_SETTINGS.has(key):
				accessibility_settings[key] = json.data[key]
	file.close()
	if OS.is_debug_build():
		print("[ACCESS] Loaded accessibility settings from %s" % path)


func _setup_custom_cursor() -> void:
	var size = 24
	var img = Image.create(size, size, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	@warning_ignore("integer_division")
	var center = size / 2
	var primary = Color(0.3, 1.0, 0.4, 0.9)
	var outline_c = Color(0.0, 0.2, 0.05, 0.8)
	for i in range(4, center):
		img.set_pixel(center + i, center, primary)
		if center - 1 >= 0:
			img.set_pixel(center + i, center - 1, outline_c)
		img.set_pixel(center - i, center, primary)
		img.set_pixel(center, center + i, primary)
		img.set_pixel(center, center - i, primary)
	for dx in range(-1, 2):
		for dy in range(-1, 2):
			var px = center + dx
			var py = center + dy
			if px >= 0 and px < size and py >= 0 and py < size:
				if dx == 0 and dy == 0:
					img.set_pixel(px, py, Color(0.8, 1.0, 0.9, 1.0))
				else:
					img.set_pixel(px, py, primary)
	for sx in [-1, 1]:
		for sy in [-1, 1]:
			for t_i in range(3):
				var cx = center + sx * 3
				var cy = center + sy * 3
				if cx + sx * t_i >= 0 and cx + sx * t_i < size and cy >= 0 and cy < size:
					img.set_pixel(cx + sx * t_i, cy, outline_c)
				if cx >= 0 and cx < size and cy + sy * t_i >= 0 and cy + sy * t_i < size:
					img.set_pixel(cx, cy + sy * t_i, outline_c)
	var tex = ImageTexture.create_from_image(img)
	Input.set_custom_mouse_cursor(tex, Input.CURSOR_ARROW, Vector2(center, center))


# ══════════════════════════════════════════════════════════════════════════
# PASS 57 — GAMEPAD BINDINGS (RUNTIME)
# ══════════════════════════════════════════════════════════════════════════

func _add_gamepad_bindings() -> void:
	## Add controller bindings for all input actions at runtime.
	var mappings: Dictionary = {
		"jump":           [{"btn": JOY_BUTTON_A}],
		"attack":         [{"btn": JOY_BUTTON_X}],
		"spell":          [{"btn": JOY_BUTTON_Y}],
		"heal":           [{"btn": JOY_BUTTON_B}],
		"defend":         [{"btn": JOY_BUTTON_RIGHT_SHOULDER}],
		"sprint":         [{"axis": JOY_AXIS_TRIGGER_RIGHT, "val": 1.0}],
		"root_access":    [{"axis": JOY_AXIS_TRIGGER_LEFT, "val": 1.0}],
		"interact":       [{"btn": JOY_BUTTON_A}],
		"pause_menu":     [{"btn": JOY_BUTTON_START}],
		"status_window":  [{"btn": JOY_BUTTON_BACK}],
		"data_vision":    [{"btn": JOY_BUTTON_LEFT_STICK}],
		"perfect_delete": [{"btn": JOY_BUTTON_RIGHT_STICK}],
		"move_left":      [{"axis": JOY_AXIS_LEFT_X, "val": -1.0}, {"btn": JOY_BUTTON_DPAD_LEFT}],
		"move_right":     [{"axis": JOY_AXIS_LEFT_X, "val": 1.0}, {"btn": JOY_BUTTON_DPAD_RIGHT}],
		"move_up":        [{"axis": JOY_AXIS_LEFT_Y, "val": -1.0}, {"btn": JOY_BUTTON_DPAD_UP}],
		"move_down":      [{"axis": JOY_AXIS_LEFT_Y, "val": 1.0}, {"btn": JOY_BUTTON_DPAD_DOWN}],
	}
	for action_name in mappings:
		if not InputMap.has_action(action_name):
			continue
		for entry in mappings[action_name]:
			if entry.has("btn"):
				var ev = InputEventJoypadButton.new()
				ev.button_index = entry.btn
				ev.device = -1  # All gamepads
				InputMap.action_add_event(action_name, ev)
			elif entry.has("axis"):
				var ev = InputEventJoypadMotion.new()
				ev.axis = entry.axis
				ev.axis_value = entry.val
				ev.device = -1
				InputMap.action_add_event(action_name, ev)
	if OS.is_debug_build():
		print("[GAMEPAD] Controller bindings added for %d actions" % mappings.size())


# ══════════════════════════════════════════════════════════════════════════
# PASS 57 — DIFFICULTY SYSTEM
# ══════════════════════════════════════════════════════════════════════════

func set_difficulty(diff: Difficulty) -> void:
	selected_difficulty = diff
	_save_difficulty_setting()

func get_difficulty_name() -> String:
	return DIFFICULTY_NAMES[selected_difficulty]

func get_enemy_damage_mult() -> float:
	return DIFFICULTY_MULTS[selected_difficulty].get("enemy_dmg", 1.0)

func get_player_damage_mult() -> float:
	return DIFFICULTY_MULTS[selected_difficulty].get("player_dmg", 1.0)

func _save_difficulty_setting() -> void:
	var config = ConfigFile.new()
	var _err = config.load("user://game_settings.cfg")
	config.set_value("gameplay", "difficulty", selected_difficulty)
	config.save("user://game_settings.cfg")

func _load_difficulty_setting() -> void:
	var config = ConfigFile.new()
	if config.load("user://game_settings.cfg") == OK:
		selected_difficulty = config.get_value("gameplay", "difficulty", Difficulty.NORMAL) as Difficulty


# ══════════════════════════════════════════════════════════════════════════
# PASS 57 — AUTO-SAVE VISUAL INDICATOR
# ══════════════════════════════════════════════════════════════════════════

var _save_indicator: Label = null
var _save_indicator_layer: CanvasLayer = null

func _build_autosave_indicator() -> void:
	_save_indicator_layer = CanvasLayer.new()
	_save_indicator_layer.layer = 100
	add_child(_save_indicator_layer)
	_save_indicator = Label.new()
	_save_indicator.text = "  Saving...  "
	_save_indicator.add_theme_font_size_override("font_size", 14)
	_save_indicator.add_theme_color_override("font_color", Color(0.6, 1.0, 0.7, 0.9))
	_save_indicator.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	_save_indicator.offset_left = -120
	_save_indicator.offset_top = -40
	_save_indicator.modulate.a = 0.0
	_save_indicator_layer.add_child(_save_indicator)

func show_save_indicator() -> void:
	if not is_instance_valid(_save_indicator):
		return
	_save_indicator.modulate.a = 1.0
	var tw = _save_indicator.create_tween()
	tw.tween_interval(1.0)
	tw.tween_property(_save_indicator, "modulate:a", 0.0, 0.5)
