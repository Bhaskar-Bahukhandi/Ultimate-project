#!/usr/bin/env python3
"""Rewrite all game scripts with proper indentation using tabs."""
import os

BASE = os.path.dirname(os.path.abspath(__file__))
SCRIPTS = os.path.join(BASE, "scripts")

def write(rel_path, content):
    full = os.path.join(SCRIPTS, rel_path)
    os.makedirs(os.path.dirname(full), exist_ok=True)
    with open(full, 'w', encoding='utf-8', newline='\n') as f:
        f.write(content)
    lines = content.count('\n')
    print(f"  Written: {rel_path} ({lines} lines)")

def t(n=1):
    """Return n tabs"""
    return '\t' * n

# ============================================================================
# GAME MANAGER
# ============================================================================
def write_game_manager():
    print("Writing game_manager.gd...")
    content = f'''extends Node
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

# ── Enums ─────────────────────────────────────────────────────────────────
enum GameState {{
{t()}MENU,
{t()}PROLOGUE,
{t()}EXPLORATION,
{t()}COMBAT,
{t()}DIALOGUE,
{t()}CUTSCENE,
{t()}ROOT_ACCESS_MODE,
{t()}GAME_OVER,
}}

# ── Constants ─────────────────────────────────────────────────────────────
const SAVE_VERSION := "1.1.0"
const MAX_SAVE_SLOT := 99
const AUTOSAVE_SLOT := 99
const MAX_CHARM_SLOTS := 3

const XP_THRESHOLDS: Array[int] = [0, 100, 300, 600, 1000, 1500, 2200, 3000, 4000, 5500, 7500]
const HP_PER_LEVEL := 20
const MP_PER_LEVEL := 10
const DAMAGE_PER_LEVEL := 3
const TIER_ORDER: Array[String] = ["bronze", "silver", "gold", "platinum"]
const DDA_WINDOW_SECONDS := 120.0
const DDA_SCORE_FLOOR := 20.0
const DDA_SCORE_CEILING := 85.0
const ADMIN_SPAWN_COOLDOWN := 60.0
const ADMIN_SPAWN_COUNT := 2

const CHARM_INFO: Dictionary = {{
{t()}"extended_parry": {{"name": "Extended Parry", "desc": "Parry window +40%.", "icon": "[P]"}},
{t()}"soul_hoarder": {{"name": "Soul Hoarder", "desc": "Soul gain +50%. Spell cost -20%.", "icon": "[S]"}},
{t()}"corruption_resist": {{"name": "Firewall", "desc": "Corruption gain reduced by 40%.", "icon": "[F]"}},
{t()}"pogo_master": {{"name": "Pogo Master", "desc": "Pogo damage +80%. Bounce height +30%.", "icon": "[G]"}},
{t()}"dash_master": {{"name": "Shadow Dash", "desc": "Dash cooldown -50%. Dash deals 10 damage.", "icon": "[D]"}},
{t()}"thorns": {{"name": "Thorns of Pain", "desc": "Reflect 15 damage to attackers when hit.", "icon": "[T]"}},
}}

const CHARM_VALUES: Dictionary = {{
{t()}"extended_parry": 1.4, "soul_hoarder": 1.5, "corruption_resist": 0.6,
{t()}"pogo_master": 1.8, "dash_master": 0.5, "thorns": 15.0,
}}

const DEFAULT_PLAYER_STATS: Dictionary = {{
{t()}"name": "Kaelen", "class_fake": "Systems Architect", "class_true": "ROOT_ACCESS",
{t()}"level": 1, "hp": 100, "max_hp": 100, "mp": 50, "max_mp": 50,
{t()}"gold": 0, "xp": 0, "base_attack": 15, "attack": 15,
{t()}"base_defense": 0, "defense": 0, "ram_gb": 12, "ram_max_gb": 16,
{t()}"corruption_pct": 0.05, "integrity_pct": 84.0, "soul": 0,
}}

const DEFAULT_RELATIONSHIPS: Dictionary = {{
{t()}"elara": 0, "seraphina": 0, "lyra": 0, "kaelthas": 0, "aria": 0,
}}

const DEFAULT_STORY_FLAGS: Dictionary = {{
{t()}"plane_crash_completed": false, "tutorial_completed": false,
{t()}"first_slime_defeated": false, "root_access_unlocked": false, "elara_met": false,
{t()}"ch1_awakening_complete": false, "ch1_elara_glitch_witch_met": false,
{t()}"ch1_glitch_magic_shown": false, "ch1_data_vision_unlocked": false,
{t()}"ch1_slime_root_access_tutorial": false, "ch1_oakhaven_entered": false,
{t()}"ch1_apothecary_visited": false, "ch1_auction_house_visited": false,
{t()}"ch1_corrupted_boar_defeated": false, "ch1_tutorial_knight_defeated": false,
{t()}"ch1_shatter_witnessed": false, "ch1_complete": false,
{t()}"source_key_fragment_1": false,
{t()}"ch1_elara_trusted": false, "ch1_elara_distrusted": false, "ch1_elara_cautious": false,
{t()}"ch1_knight_spared": false, "ch1_knight_killed": false,
{t()}"ch1_oakhaven_warned_villagers": false, "ch1_oakhaven_left_quietly": false,
{t()}"ch2_ironhold_entered": false, "ch2_market_visited": false,
{t()}"ch2_arena_unlocked": false, "ch2_arena_bronze_complete": false,
{t()}"ch2_arena_silver_complete": false, "ch2_arena_gold_complete": false,
{t()}"ch2_arena_platinum_complete": false,
{t()}"ch2_seraphina_met": false, "ch2_seraphina_truth": false,
{t()}"ch2_seraphina_cautious": false, "ch2_seraphina_showoff": false,
{t()}"ch2_underground_unlocked": false, "ch2_underground_complete": false,
{t()}"ch2_data_wraith_defeated": false, "ch2_data_wraith_restored": false,
{t()}"ch2_data_wraith_destroyed": false, "ch2_data_wraith_absorbed": false,
{t()}"source_key_fragment_2": false,
{t()}"ch2_clock_tower_unlocked": false, "ch2_clock_tower_complete": false,
{t()}"ch2_clockwork_automaton_defeated": false, "ch2_administrator_proxy_defeated": false,
{t()}"ch2_seraphina_recruited": false, "ch2_seraphina_stayed": false,
{t()}"ch2_seraphina_rejected": false, "ch2_sovereign_revealed": false,
{t()}"ch2_complete": false, "player_died": false,
}}

const DEFAULT_ARENA_STATS: Dictionary = {{
{t()}"total_wins": 0, "total_losses": 0, "current_tier": "bronze",
{t()}"win_streak": 0, "best_streak": 0, "highest_tier_reached": "bronze",
}}

const DEFAULT_SESSION_STATS: Dictionary = {{
{t()}"death_count": 0, "enemies_killed": 0, "bosses_killed": 0,
{t()}"total_damage_dealt": 0, "total_damage_taken": 0,
{t()}"items_found": 0, "hacks_used": 0, "parries_landed": 0,
{t()}"perfect_deletes_used": 0, "highest_combo": 0, "speedrun_seconds": 0.0,
}}

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

var player_stats: Dictionary = DEFAULT_PLAYER_STATS.duplicate(true)
var relationships: Dictionary = DEFAULT_RELATIONSHIPS.duplicate(true)
var story_flags: Dictionary = DEFAULT_STORY_FLAGS.duplicate(true)
var arena_stats: Dictionary = DEFAULT_ARENA_STATS.duplicate(true)
var stats: Dictionary = DEFAULT_SESSION_STATS.duplicate(true)

var unlocked_charms: Dictionary = {{}}
var equipped_charms: Array = []

var _corruption_stat_penalty: float = 0.0
var _corruption_gravity_variance: float = 0.0
var _corruption_input_delay: float = 0.0
var _dda_performance_score: float = 50.0
var _dda_recent_deaths: int = 0
var _dda_recent_kills: int = 0
var _dda_window_timer: float = 0.0
var _admin_spawn_cooldown: float = 0.0
var _admin_enforcer_script: GDScript = null


# ══════════════════════════════════════════════════════════════════════════
# LIFECYCLE
# ══════════════════════════════════════════════════════════════════════════

func _ready() -> void:
{t()}_setup_custom_cursor()

func _process(delta: float) -> void:
{t()}if current_state != GameState.MENU and not get_tree().paused:
{t(2)}playtime_seconds += delta
{t()}if speedrun_active and current_state in [GameState.COMBAT, GameState.EXPLORATION]:
{t(2)}stats["speedrun_seconds"] = stats.get("speedrun_seconds", 0.0) + delta
{t()}_tick_admin_cooldown(delta)
{t()}_tick_dda_window(delta)


# ══════════════════════════════════════════════════════════════════════════
# STATE MANAGEMENT
# ══════════════════════════════════════════════════════════════════════════

func change_state(new_state: GameState) -> void:
{t()}current_state = new_state
{t()}state_changed.emit(new_state)

func set_story_flag(flag_name: String, value: bool = true) -> void:
{t()}story_flags[flag_name] = value
{t()}story_flag_updated.emit(flag_name, value)

func get_flag(flag_name: String) -> bool:
{t()}return story_flags.get(flag_name, false)


# ══════════════════════════════════════════════════════════════════════════
# CORRUPTION SYSTEM
# ══════════════════════════════════════════════════════════════════════════

func add_glitch_corruption(amount: float) -> void:
{t()}if amount > 0.0 and has_charm("corruption_resist"):
{t(2)}amount *= get_charm_value("corruption_resist")
{t()}glitch_meter += amount
{t()}if glitch_meter >= 100.0:
{t(2)}glitch_meter = 100.0
{t(2)}glitch_meter_changed.emit(glitch_meter)
{t(2)}trigger_corruption_game_over()
{t(2)}return
{t()}glitch_meter = clampf(glitch_meter, 0.0, 100.0)
{t()}glitch_meter_changed.emit(glitch_meter)
{t()}_update_corruption_level()

func _update_corruption_level() -> void:
{t()}var new_level := 0
{t()}if glitch_meter >= 75.0:
{t(2)}new_level = 3
{t()}elif glitch_meter >= 50.0:
{t(2)}new_level = 2
{t()}elif glitch_meter >= 25.0:
{t(2)}new_level = 1
{t()}if new_level != corruption_level:
{t(2)}corruption_level = new_level
{t(2)}corruption_level_changed.emit(corruption_level)
{t(2)}_apply_corruption_effects()

func add_root_access_corruption_boss() -> void:
{t()}add_glitch_corruption(5.0)

func add_root_access_corruption_mob() -> void:
{t()}add_glitch_corruption(1.0)

func add_death_corruption() -> void:
{t()}stats["death_count"] = stats.get("death_count", 0) + 1
{t()}record_dda_death()
{t()}add_glitch_corruption(1.0)

func trigger_corruption_game_over() -> void:
{t()}if current_state == GameState.GAME_OVER:
{t(2)}return
{t()}change_state(GameState.GAME_OVER)
{t()}if has_node("/root/DialogueManager"):
{t(2)}DialogueManager.hide_dialogue()
{t()}await get_tree().create_timer(2.0).timeout
{t()}if not is_inside_tree():
{t(2)}return
{t()}if has_node("/root/SceneTransitions"):
{t(2)}SceneTransitions.change_scene("res://scenes/game_over.tscn", SceneTransitions.TransitionStyle.GLITCH)
{t()}else:
{t(2)}get_tree().change_scene_to_file("res://scenes/game_over.tscn")

func _apply_corruption_effects() -> void:
{t()}match corruption_level:
{t(2)}0, 1:
{t(3)}_corruption_stat_penalty = 0.0
{t(3)}_corruption_gravity_variance = 0.0
{t(3)}_corruption_input_delay = 0.0
{t(2)}2:
{t(3)}_corruption_stat_penalty = 0.05
{t(3)}_corruption_gravity_variance = 0.15
{t(3)}_corruption_input_delay = 0.0
{t(2)}3:
{t(3)}_corruption_stat_penalty = 0.12
{t(3)}_corruption_gravity_variance = 0.25
{t(3)}_corruption_input_delay = 0.03
{t(3)}_try_spawn_enforcers()
{t()}var penalty_mult := 1.0 - _corruption_stat_penalty
{t()}player_stats["attack"] = int(player_stats.get("base_attack", 15) * penalty_mult)
{t()}player_stats["defense"] = int(player_stats.get("base_defense", 0) * penalty_mult)
{t()}if has_node("/root/Inventory"):
{t(2)}Inventory._apply_equipment_bonuses()
{t()}corruption_effects_updated.emit(corruption_level)

## Public alias for backward compatibility
func apply_corruption_effects() -> void:
{t()}_apply_corruption_effects()

func get_corruption_gravity_multiplier() -> float:
{t()}if _corruption_gravity_variance <= 0.0:
{t(2)}return 1.0
{t()}var t_val := Time.get_ticks_msec() / 1000.0
{t()}return 1.0 + sin(t_val * 5.0) * _corruption_gravity_variance + sin(t_val * 13.0) * _corruption_gravity_variance * 0.3

func get_corruption_input_delay() -> float:
{t()}return _corruption_input_delay

func get_corruption_damage_multiplier() -> float:
{t()}return 1.0 - _corruption_stat_penalty


# ══════════════════════════════════════════════════════════════════════════
# ADMINISTRATOR ENFORCER SPAWNING (Corruption 75%+ punishment)
# ══════════════════════════════════════════════════════════════════════════

func _tick_admin_cooldown(delta: float) -> void:
{t()}if _admin_spawn_cooldown > 0.0:
{t(2)}_admin_spawn_cooldown -= delta

## Legacy alias
func _check_admin_spawn_cooldown(delta: float) -> void:
{t()}_tick_admin_cooldown(delta)

func _try_spawn_enforcers() -> void:
{t()}if current_state not in [GameState.EXPLORATION, GameState.COMBAT]:
{t(2)}return
{t()}if _admin_spawn_cooldown > 0.0:
{t(2)}return
{t()}_admin_spawn_cooldown = ADMIN_SPAWN_COOLDOWN
{t()}var players := get_tree().get_nodes_in_group("player")
{t()}if players.is_empty():
{t(2)}return
{t()}var player: Node2D = players[0] as Node2D
{t()}if not player or not player.get_parent():
{t(2)}return
{t()}var existing := get_tree().get_nodes_in_group("administrator_enforcers")
{t()}if existing.size() >= ADMIN_SPAWN_COUNT:
{t(2)}return
{t()}if has_node("/root/VFXLibrary"):
{t(2)}VFXLibrary.spawn_status_indicator("[ALERT] Administrators Dispatched!", player.global_position + Vector2(0, -80), player.get_parent(), false)
{t()}if _admin_enforcer_script == null:
{t(2)}var script_path := "res://scripts/combat/enemies/administrator_enforcer.gd"
{t(2)}if ResourceLoader.exists(script_path):
{t(3)}_admin_enforcer_script = load(script_path) as GDScript
{t()}if _admin_enforcer_script == null:
{t(2)}push_error("[ADMIN] Failed to load administrator_enforcer.gd")
{t(2)}return
{t()}var spawn_count := ADMIN_SPAWN_COUNT - existing.size()
{t()}for i in range(spawn_count):
{t(2)}var enforcer := CharacterBody2D.new()
{t(2)}enforcer.name = "AdminEnforcer_%d" % (i + randi() % 1000)
{t(2)}enforcer.set_script(_admin_enforcer_script)
{t(2)}enforcer.add_to_group("administrator_enforcers")
{t(2)}var offset_x := 200.0 + i * 120.0
{t(2)}if i % 2 == 1:
{t(3)}offset_x = -offset_x
{t(2)}enforcer.global_position = player.global_position + Vector2(offset_x, -50)
{t(2)}player.get_parent().call_deferred("add_child", enforcer)

## Legacy alias
func _spawn_administrator_enforcers() -> void:
{t()}_try_spawn_enforcers()


# ══════════════════════════════════════════════════════════════════════════
# CHARM SYSTEM
# ══════════════════════════════════════════════════════════════════════════

func unlock_charm(charm_id: String) -> void:
{t()}if unlocked_charms.has(charm_id):
{t(2)}return
{t()}unlocked_charms[charm_id] = true
{t()}charm_unlocked.emit(charm_id)
{t()}if equipped_charms.size() < MAX_CHARM_SLOTS:
{t(2)}equip_charm(charm_id)

func is_charm_unlocked(charm_id: String) -> bool:
{t()}return unlocked_charms.get(charm_id, false)

func has_charm(charm_id: String) -> bool:
{t()}return charm_id in equipped_charms

func equip_charm(charm_id: String) -> bool:
{t()}if not is_charm_unlocked(charm_id):
{t(2)}return false
{t()}if charm_id in equipped_charms:
{t(2)}return false
{t()}if equipped_charms.size() >= MAX_CHARM_SLOTS:
{t(2)}return false
{t()}equipped_charms.append(charm_id)
{t()}charm_equipped.emit(charm_id)
{t()}return true

func unequip_charm(charm_id: String) -> bool:
{t()}var idx := equipped_charms.find(charm_id)
{t()}if idx == -1:
{t(2)}return false
{t()}equipped_charms.remove_at(idx)
{t()}charm_unequipped.emit(charm_id)
{t()}return true

func get_charm_value(charm_id: String, default_val: float = 1.0) -> float:
{t()}if not has_charm(charm_id):
{t(2)}return default_val
{t()}return CHARM_VALUES.get(charm_id, default_val)


# ══════════════════════════════════════════════════════════════════════════
# LEVELING SYSTEM
# ══════════════════════════════════════════════════════════════════════════

func add_xp(amount: int) -> void:
{t()}player_stats["xp"] = player_stats.get("xp", 0) + amount
{t()}if has_node("/root/LevelUpUI"):
{t(2)}LevelUpUI.on_xp_gained(amount)
{t()}_check_level_up()

## Public alias for backward compat
func check_level_up() -> void:
{t()}_check_level_up()

func _check_level_up() -> void:
{t()}var current_level: int = player_stats.get("level", 1)
{t()}if current_level >= XP_THRESHOLDS.size():
{t(2)}return
{t()}while current_level < XP_THRESHOLDS.size() - 1 and player_stats["xp"] >= XP_THRESHOLDS[current_level]:
{t(2)}current_level += 1
{t(2)}_apply_level_up(current_level)

func _apply_level_up(new_level: int) -> void:
{t()}player_stats["level"] = new_level
{t()}var hp_gain := HP_PER_LEVEL
{t()}var mp_gain := MP_PER_LEVEL
{t()}var atk_gain := DAMAGE_PER_LEVEL
{t()}if has_node("/root/LevelUpUI"):
{t(2)}hp_gain = LevelUpUI.get_hp_for_level(new_level)
{t(2)}mp_gain = LevelUpUI.get_mp_for_level(new_level)
{t(2)}atk_gain = LevelUpUI.get_atk_for_level(new_level)
{t()}player_stats["max_hp"] += hp_gain
{t()}player_stats["hp"] = player_stats["max_hp"]
{t()}player_stats["max_mp"] += mp_gain
{t()}player_stats["mp"] = player_stats["max_mp"]
{t()}player_stats["base_attack"] += atk_gain
{t()}player_stats["attack"] = player_stats["base_attack"]
{t()}if has_node("/root/Inventory"):
{t(2)}Inventory._apply_equipment_bonuses()
{t()}if _corruption_stat_penalty > 0.0:
{t(2)}_apply_corruption_effects()
{t()}player_leveled_up.emit(new_level)

func get_xp_for_next_level() -> int:
{t()}var level: int = player_stats.get("level", 1)
{t()}if level >= XP_THRESHOLDS.size() - 1:
{t(2)}return -1
{t()}return XP_THRESHOLDS[level]

func get_xp_progress() -> float:
{t()}var level: int = player_stats.get("level", 1)
{t()}if level >= XP_THRESHOLDS.size() - 1:
{t(2)}return 1.0
{t()}var prev := XP_THRESHOLDS[level - 1] if level > 1 else 0
{t()}var next := XP_THRESHOLDS[level]
{t()}var range_size := next - prev
{t()}if range_size <= 0:
{t(2)}return 1.0
{t()}return clampf(float(player_stats["xp"] - prev) / float(range_size), 0.0, 1.0)

func get_player_attack_damage() -> float:
{t()}var base := 15.0 + (player_stats.get("level", 1) - 1) * DAMAGE_PER_LEVEL
{t()}return maxf(base, float(player_stats.get("attack", base)))

func add_gold(amount: int) -> void:
{t()}player_stats["gold"] = player_stats.get("gold", 0) + amount
{t()}if has_node("/root/Inventory"):
{t(2)}Inventory.gold = player_stats["gold"]

func use_perfect_delete() -> bool:
{t()}if perfect_delete_charges <= 0:
{t(2)}return false
{t()}perfect_delete_charges -= 1
{t()}perfect_delete_used = true
{t()}stats["perfect_deletes_used"] = stats.get("perfect_deletes_used", 0) + 1
{t()}return true


# ══════════════════════════════════════════════════════════════════════════
# DDA (Dynamic Difficulty Adjustment)
# ══════════════════════════════════════════════════════════════════════════

func get_difficulty_multiplier() -> float:
{t()}if _dda_performance_score <= 30.0:
{t(2)}return 0.8
{t()}elif _dda_performance_score <= 45.0:
{t(2)}return 0.9
{t()}elif _dda_performance_score <= 60.0:
{t(2)}return 1.0
{t()}elif _dda_performance_score <= 75.0:
{t(2)}return 1.1
{t()}return 1.2

func record_dda_kill() -> void:
{t()}_dda_recent_kills += 1
{t()}_recalc_dda()

func record_dda_death() -> void:
{t()}_dda_recent_deaths += 1
{t()}_recalc_dda()

func _recalc_dda() -> void:
{t()}var old_score := _dda_performance_score
{t()}if _dda_recent_deaths == 0 and _dda_recent_kills == 0:
{t(2)}_dda_performance_score = 50.0
{t()}elif _dda_recent_deaths == 0:
{t(2)}_dda_performance_score = minf(DDA_SCORE_CEILING, 50.0 + _dda_recent_kills * 3.0)
{t()}else:
{t(2)}var ratio := float(_dda_recent_kills) / float(_dda_recent_deaths)
{t(2)}_dda_performance_score = clampf(ratio * 15.0 + 10.0, DDA_SCORE_FLOOR, DDA_SCORE_CEILING)
{t()}if absf(old_score - _dda_performance_score) > 5.0:
{t(2)}difficulty_adjusted.emit(get_difficulty_multiplier())

func _tick_dda_window(delta: float) -> void:
{t()}_dda_window_timer += delta
{t()}if _dda_window_timer >= DDA_WINDOW_SECONDS:
{t(2)}_dda_window_timer = 0.0
{t(2)}_dda_recent_kills = int(_dda_recent_kills * 0.5)
{t(2)}_dda_recent_deaths = int(_dda_recent_deaths * 0.5)
{t(2)}_recalc_dda()

## Legacy alias
func _update_dda_score() -> void:
{t()}_recalc_dda()


# ══════════════════════════════════════════════════════════════════════════
# ARENA SYSTEM
# ══════════════════════════════════════════════════════════════════════════

func record_arena_win() -> void:
{t()}arena_stats["total_wins"] = arena_stats.get("total_wins", 0) + 1
{t()}arena_stats["win_streak"] = arena_stats.get("win_streak", 0) + 1
{t()}if arena_stats["win_streak"] > arena_stats.get("best_streak", 0):
{t(2)}arena_stats["best_streak"] = arena_stats["win_streak"]

func record_arena_loss() -> void:
{t()}arena_stats["total_losses"] = arena_stats.get("total_losses", 0) + 1
{t()}arena_stats["win_streak"] = 0

func get_arena_streak_multiplier() -> float:
{t()}var streak: int = arena_stats.get("win_streak", 0)
{t()}if streak >= 10: return 2.5
{t()}if streak >= 7: return 2.0
{t()}if streak >= 5: return 1.75
{t()}if streak >= 3: return 1.5
{t()}return 1.0

func advance_arena_tier() -> void:
{t()}var idx := TIER_ORDER.find(arena_stats.get("current_tier", "bronze"))
{t()}if idx >= 0 and idx < TIER_ORDER.size() - 1:
{t(2)}arena_stats["current_tier"] = TIER_ORDER[idx + 1]
{t(2)}arena_stats["highest_tier_reached"] = arena_stats["current_tier"]


# ══════════════════════════════════════════════════════════════════════════
# SOURCE KEY & COMPLETION
# ══════════════════════════════════════════════════════════════════════════

func collect_source_key(fragment_number: int) -> void:
{t()}var flag := "source_key_fragment_%d" % fragment_number
{t()}if not story_flags.get(flag, false):
{t(2)}set_story_flag(flag, true)
{t(2)}source_key_count += 1

func get_completion_percentage() -> float:
{t()}var total := 0.0
{t()}var found := 0.0
{t()}total += 3.0
{t()}for ch in ["ch1_complete", "ch2_complete", "ch3_complete"]:
{t(2)}if get_flag(ch): found += 1.0
{t()}total += 7.0
{t()}found += float(source_key_count)
{t()}var key_flags := ["root_access_unlocked", "ch1_elara_trusted", "ch1_elara_cautious", "ch2_seraphina_recruited", "ch3_lyra_recruited", "ch3_kaelthas_defeated"]
{t()}total += float(key_flags.size())
{t()}for f in key_flags:
{t(2)}if get_flag(f): found += 1.0
{t()}return (found / total) * 100.0 if total > 0.0 else 0.0

func format_speedrun_time() -> String:
{t()}var secs: float = stats.get("speedrun_seconds", 0.0)
{t()}var hours := int(secs) / 3600
{t()}var minutes := (int(secs) % 3600) / 60
{t()}var seconds := int(secs) % 60
{t()}var ms := int(fmod(secs, 1.0) * 100)
{t()}if hours > 0:
{t(2)}return "%d:%02d:%02d.%02d" % [hours, minutes, seconds, ms]
{t()}return "%02d:%02d.%02d" % [minutes, seconds, ms]

func get_revival_scene() -> String:
{t()}if get_flag("ch2_ironhold_entered"):
{t(2)}return "res://scenes/chapter2/ironhold_gate.tscn"
{t()}if get_flag("ch1_oakhaven_entered"):
{t(2)}return "res://scenes/chapter1/oakhaven_village.tscn"
{t()}if get_flag("ch1_awakening_complete"):
{t(2)}return "res://scenes/chapter1/elara_meeting.tscn"
{t()}return "res://scenes/chapter1/glitch_crater_awakening.tscn"


# ══════════════════════════════════════════════════════════════════════════
# SAVE / LOAD
# ══════════════════════════════════════════════════════════════════════════

func save_game(slot: int = 0) -> bool:
{t()}if slot < 0 or slot > MAX_SAVE_SLOT:
{t(2)}push_error("[SAVE] Invalid slot: %d" % slot)
{t(2)}return false
{t()}var save_data := {{
{t(2)}"version": SAVE_VERSION,
{t(2)}"timestamp": Time.get_datetime_string_from_system(),
{t(2)}"player_stats": player_stats.duplicate(true),
{t(2)}"relationships": relationships.duplicate(true),
{t(2)}"story_flags": story_flags.duplicate(true),
{t(2)}"glitch_meter": glitch_meter,
{t(2)}"corruption_level": corruption_level,
{t(2)}"perfect_delete_charges": perfect_delete_charges,
{t(2)}"perfect_delete_used": perfect_delete_used,
{t(2)}"current_scene": get_tree().current_scene.scene_file_path if get_tree().current_scene else "",
{t(2)}"current_chapter": current_chapter,
{t(2)}"playtime_seconds": playtime_seconds,
{t(2)}"source_key_count": source_key_count,
{t(2)}"arena_stats": arena_stats.duplicate(true),
{t(2)}"unlocked_charms": unlocked_charms.duplicate(true),
{t(2)}"equipped_charms": equipped_charms.duplicate(),
{t(2)}"stats": stats.duplicate(true),
{t()}}}
{t()}if has_node("/root/Inventory"):
{t(2)}save_data["inventory_items"] = Inventory.items.duplicate(true)
{t(2)}save_data["inventory_gold"] = Inventory.gold
{t(2)}save_data["inventory_equipment"] = Inventory.equipment.duplicate(true)
{t()}if has_node("/root/Achievements"):
{t(2)}save_data["achievements"] = Achievements.get_save_data()
{t()}var players := get_tree().get_nodes_in_group("player")
{t()}if not players.is_empty():
{t(2)}var pos: Vector2 = players[0].global_position
{t(2)}save_data["player_position"] = {{"x": pos.x, "y": pos.y}}
{t()}var save_path := "user://save_slot_%d.save" % slot
{t()}var file := FileAccess.open(save_path, FileAccess.WRITE)
{t()}if not file:
{t(2)}push_error("[SAVE] Failed to write slot %d" % slot)
{t(2)}return false
{t()}file.store_string(JSON.stringify(save_data, "\\t"))
{t()}file.close()
{t()}return true

func load_game(slot: int = 0) -> bool:
{t()}if slot < 0 or slot > MAX_SAVE_SLOT:
{t(2)}push_error("[LOAD] Invalid slot: %d" % slot)
{t(2)}return false
{t()}var save_path := "user://save_slot_%d.save" % slot
{t()}if not FileAccess.file_exists(save_path):
{t(2)}push_error("[LOAD] No save at slot %d" % slot)
{t(2)}return false
{t()}var file := FileAccess.open(save_path, FileAccess.READ)
{t()}if not file:
{t(2)}push_error("[LOAD] Cannot open slot %d" % slot)
{t(2)}return false
{t()}var json_text := file.get_as_text()
{t()}file.close()
{t()}var json := JSON.new()
{t()}if json.parse(json_text) != OK:
{t(2)}push_error("[LOAD] Parse error slot %d" % slot)
{t(2)}return false
{t()}var data: Dictionary = json.data
{t()}if not data is Dictionary:
{t(2)}push_error("[LOAD] Invalid data slot %d" % slot)
{t(2)}return false
{t()}# Restore with safe merging
{t()}player_stats = _merge_dict(DEFAULT_PLAYER_STATS.duplicate(true), data.get("player_stats", {{}}))
{t()}relationships = _merge_dict(DEFAULT_RELATIONSHIPS.duplicate(true), data.get("relationships", {{}}))
{t()}story_flags = _merge_dict(DEFAULT_STORY_FLAGS.duplicate(true), data.get("story_flags", {{}}))
{t()}arena_stats = _merge_dict(DEFAULT_ARENA_STATS.duplicate(true), data.get("arena_stats", {{}}))
{t()}stats = _merge_dict(DEFAULT_SESSION_STATS.duplicate(true), data.get("stats", {{}}))
{t()}glitch_meter = data.get("glitch_meter", 0.0)
{t()}corruption_level = data.get("corruption_level", 0)
{t()}perfect_delete_charges = data.get("perfect_delete_charges", 3)
{t()}perfect_delete_used = data.get("perfect_delete_used", false)
{t()}playtime_seconds = data.get("playtime_seconds", 0.0)
{t()}current_chapter = data.get("current_chapter", 1)
{t()}source_key_count = data.get("source_key_count", 0)
{t()}# Restore charms
{t()}unlocked_charms.clear()
{t()}var saved_charms = data.get("unlocked_charms", {{}})
{t()}if saved_charms is Dictionary:
{t(2)}for key in saved_charms:
{t(3)}unlocked_charms[key] = saved_charms[key]
{t()}equipped_charms.clear()
{t()}var saved_equipped = data.get("equipped_charms", [])
{t()}if saved_equipped is Array:
{t(2)}for charm_id in saved_equipped:
{t(3)}if charm_id is String and is_charm_unlocked(charm_id):
{t(4)}equipped_charms.append(charm_id)
{t()}# Restore inventory
{t()}if has_node("/root/Inventory"):
{t(2)}Inventory.items = data.get("inventory_items", {{}})
{t(2)}Inventory.gold = data.get("inventory_gold", 0)
{t(2)}Inventory.equipment = data.get("inventory_equipment", {{"weapon": "", "armor": "", "accessory": ""}})
{t()}if has_node("/root/Achievements"):
{t(2)}var saved_ach = data.get("achievements", {{}})
{t(2)}if saved_ach is Dictionary:
{t(3)}Achievements.load_save_data(saved_ach)
{t()}_apply_corruption_effects()
{t()}glitch_meter_changed.emit(glitch_meter)
{t()}corruption_level_changed.emit(corruption_level)
{t()}var saved_scene: String = data.get("current_scene", "")
{t()}if saved_scene and ResourceLoader.exists(saved_scene):
{t(2)}if has_node("/root/SceneTransitions"):
{t(3)}SceneTransitions.change_scene(saved_scene)
{t(2)}else:
{t(3)}get_tree().change_scene_to_file(saved_scene)
{t(2)}var saved_pos = data.get("player_position", {{}})
{t(2)}if saved_pos is Dictionary and not saved_pos.is_empty():
{t(3)}await get_tree().process_frame
{t(3)}if not is_inside_tree(): return true
{t(3)}await get_tree().process_frame
{t(3)}if not is_inside_tree(): return true
{t(3)}var restore_players := get_tree().get_nodes_in_group("player")
{t(3)}if not restore_players.is_empty():
{t(4)}restore_players[0].global_position = Vector2(saved_pos.get("x", 0.0), saved_pos.get("y", 0.0))
{t()}return true

func save_exists(slot: int = 0) -> bool:
{t()}return FileAccess.file_exists("user://save_slot_%d.save" % slot)

func delete_save(slot: int = 0) -> void:
{t()}var path := "user://save_slot_%d.save" % slot
{t()}if FileAccess.file_exists(path):
{t(2)}DirAccess.remove_absolute(path)

func get_save_info(slot: int = 0) -> Dictionary:
{t()}var save_path := "user://save_slot_%d.save" % slot
{t()}if not FileAccess.file_exists(save_path):
{t(2)}return {{"exists": false}}
{t()}var file := FileAccess.open(save_path, FileAccess.READ)
{t()}if not file:
{t(2)}return {{"exists": false}}
{t()}var json := JSON.new()
{t()}if json.parse(file.get_as_text()) != OK:
{t(2)}return {{"exists": false}}
{t()}file.close()
{t()}var data: Dictionary = json.data
{t()}var ps: Dictionary = data.get("player_stats", {{}})
{t()}return {{
{t(2)}"exists": true,
{t(2)}"timestamp": data.get("timestamp", "Unknown"),
{t(2)}"playtime": data.get("playtime_seconds", 0.0),
{t(2)}"glitch_meter": data.get("glitch_meter", 0.0),
{t(2)}"corruption_level": data.get("corruption_level", 0),
{t(2)}"current_chapter": data.get("current_chapter", 1),
{t(2)}"player_level": ps.get("level", 1) if ps is Dictionary else 1,
{t(2)}"player_hp": ps.get("hp", 0) if ps is Dictionary else 0,
{t(2)}"player_max_hp": ps.get("max_hp", 100) if ps is Dictionary else 100,
{t(2)}"current_scene": data.get("current_scene", ""),
{t(2)}"perfect_delete_used": data.get("perfect_delete_used", false),
{t()}}}

func auto_save() -> void:
{t()}save_game(AUTOSAVE_SLOT)


# ══════════════════════════════════════════════════════════════════════════
# RESET
# ══════════════════════════════════════════════════════════════════════════

func reset_game() -> void:
{t()}glitch_meter = 0.0
{t()}corruption_level = 0
{t()}_corruption_stat_penalty = 0.0
{t()}_corruption_gravity_variance = 0.0
{t()}_corruption_input_delay = 0.0
{t()}unlocked_charms.clear()
{t()}equipped_charms.clear()
{t()}perfect_delete_charges = 3
{t()}perfect_delete_used = false
{t()}current_chapter = 1
{t()}playtime_seconds = 0.0
{t()}source_key_count = 0
{t()}speedrun_active = false
{t()}_dda_performance_score = 50.0
{t()}_dda_recent_deaths = 0
{t()}_dda_recent_kills = 0
{t()}player_stats = DEFAULT_PLAYER_STATS.duplicate(true)
{t()}relationships = DEFAULT_RELATIONSHIPS.duplicate(true)
{t()}story_flags = DEFAULT_STORY_FLAGS.duplicate(true)
{t()}arena_stats = DEFAULT_ARENA_STATS.duplicate(true)
{t()}stats = DEFAULT_SESSION_STATS.duplicate(true)
{t()}if has_node("/root/Inventory"):
{t(2)}Inventory.items.clear()
{t(2)}Inventory.equipment = {{"weapon": "", "armor": "", "accessory": ""}}
{t(2)}Inventory.gold = 0
{t()}if has_node("/root/PauseScreen"):
{t(2)}PauseScreen.set_meta("cutscene_blocked", false)
{t(2)}if PauseScreen.is_paused:
{t(3)}PauseScreen.is_paused = false
{t(3)}PauseScreen.visible = false
{t()}change_state(GameState.MENU)


# ══════════════════════════════════════════════════════════════════════════
# UTILITY
# ══════════════════════════════════════════════════════════════════════════

func _merge_dict(base: Dictionary, overlay: Dictionary) -> Dictionary:
{t()}if not overlay is Dictionary:
{t(2)}return base
{t()}for key in overlay:
{t(2)}base[key] = overlay[key]
{t()}return base

func _setup_custom_cursor() -> void:
{t()}var size := 24
{t()}var img := Image.create(size, size, false, Image.FORMAT_RGBA8)
{t()}img.fill(Color(0, 0, 0, 0))
{t()}var center := size / 2
{t()}var primary := Color(0.3, 1.0, 0.4, 0.9)
{t()}var outline_c := Color(0.0, 0.2, 0.05, 0.8)
{t()}for i in range(4, center):
{t(2)}img.set_pixel(center + i, center, primary)
{t(2)}if center - 1 >= 0:
{t(3)}img.set_pixel(center + i, center - 1, outline_c)
{t(2)}img.set_pixel(center - i, center, primary)
{t(2)}img.set_pixel(center, center + i, primary)
{t(2)}img.set_pixel(center, center - i, primary)
{t()}for dx in range(-1, 2):
{t(2)}for dy in range(-1, 2):
{t(3)}var px := center + dx
{t(3)}var py := center + dy
{t(3)}if px >= 0 and px < size and py >= 0 and py < size:
{t(4)}if dx == 0 and dy == 0:
{t(5)}img.set_pixel(px, py, Color(0.8, 1.0, 0.9, 1.0))
{t(4)}else:
{t(5)}img.set_pixel(px, py, primary)
{t()}for sx in [-1, 1]:
{t(2)}for sy in [-1, 1]:
{t(3)}for t_i in range(3):
{t(4)}var cx := center + sx * 3
{t(4)}var cy := center + sy * 3
{t(4)}if cx + sx * t_i >= 0 and cx + sx * t_i < size and cy >= 0 and cy < size:
{t(5)}img.set_pixel(cx + sx * t_i, cy, outline_c)
{t(4)}if cx >= 0 and cx < size and cy + sy * t_i >= 0 and cy + sy * t_i < size:
{t(5)}img.set_pixel(cx, cy + sy * t_i, outline_c)
{t()}var tex := ImageTexture.create_from_image(img)
{t()}Input.set_custom_mouse_cursor(tex, Input.CURSOR_ARROW, Vector2(center, center))
'''
    write("game_manager.gd", content)


if __name__ == "__main__":
    write_game_manager()
    print("Done!")
