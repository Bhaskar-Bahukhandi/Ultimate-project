extends Node
## ==========================================================================
## RANDOM ENCOUNTER SYSTEM — JRPG-style random battles on overworld/regions
## ==========================================================================
## Autoload singleton: RandomEncounterSystem
##
## Triggers random combat encounters while the player moves in explorable
## areas. Each zone has its own encounter table with level-scaled enemies.
## Safe zones (villages, shops) suppress encounters.
## ==========================================================================

signal encounter_triggered(zone_id: String, enemy_list: Array[Dictionary])
signal encounter_finished(victory: bool, xp_gained: int, gold_gained: int)
signal encounter_won
signal fled_encounter(success: bool)
signal encounter_warning(danger_level: float)  # 0.0–1.0, fires when near trigger

# ── Zone Definitions ──────────────────────────────────────────────────────
# Each zone has: enemy_level_min, enemy_level_max, encounter_table, step_range
const ZONE_DATA: Dictionary = {
	# ── Overworld (fallback for unmapped areas) ──
	"overworld_wilderness": {
		"name": "Overworld Wilderness",
		"enemy_level_min": 0, "enemy_level_max": 0,
		"recommended_level": 1,
		"step_range": Vector2i(999, 999),
		"encounter_table": [],
		"safe": true,
	},
	# ── Oakhaven Region ──
	"oakhaven_fields": {
		"name": "Oakhaven Fields",
		"enemy_level_min": 1, "enemy_level_max": 3,
		"recommended_level": 1,
		"step_range": Vector2i(50, 100),  # steps between encounters (~2.5x increase)
		"encounter_table": [
			{"enemy_type": "slime", "weight": 40, "count_min": 1, "count_max": 3},
			{"enemy_type": "corrupted_rat", "weight": 30, "count_min": 1, "count_max": 2},
			{"enemy_type": "mushroom_mimic", "weight": 15, "count_min": 1, "count_max": 1},
			{"enemy_type": "glitch_wolf", "weight": 15, "count_min": 1, "count_max": 1},
		],
		"safe": false,
	},
	"oakhaven_forest": {
		"name": "Oakhaven Forest",
		"enemy_level_min": 3, "enemy_level_max": 5,
		"recommended_level": 3,
		"step_range": Vector2i(40, 90),
		"encounter_table": [
			{"enemy_type": "glitch_wolf", "weight": 30, "count_min": 1, "count_max": 2},
			{"enemy_type": "corrupted_rat", "weight": 25, "count_min": 2, "count_max": 3},
			{"enemy_type": "mushroom_mimic", "weight": 20, "count_min": 1, "count_max": 2},
			{"enemy_type": "slime", "weight": 15, "count_min": 2, "count_max": 4},
			{"enemy_type": "corrupted_guard", "weight": 10, "count_min": 1, "count_max": 1},
		],
		"safe": false,
	},
	"oakhaven_village": {
		"name": "Oakhaven Village",
		"enemy_level_min": 0, "enemy_level_max": 0,
		"recommended_level": 1,
		"step_range": Vector2i(999, 999),
		"encounter_table": [],
		"safe": true,
	},
	# ── Overworld Roads ──
	"road_oakhaven_ironhold": {
		"name": "Road to Ironhold",
		"enemy_level_min": 4, "enemy_level_max": 6,
		"recommended_level": 4,
		"step_range": Vector2i(45, 90),
		"encounter_table": [
			{"enemy_type": "glitch_wolf", "weight": 30, "count_min": 1, "count_max": 2},
			{"enemy_type": "corrupted_guard", "weight": 35, "count_min": 1, "count_max": 2},
			{"enemy_type": "data_sprite", "weight": 20, "count_min": 1, "count_max": 2},
			{"enemy_type": "clockwork_soldier", "weight": 15, "count_min": 1, "count_max": 1},
		],
		"safe": false,
	},
	"road_ironhold_wastes": {
		"name": "Road to the Wastes",
		"enemy_level_min": 8, "enemy_level_max": 10,
		"recommended_level": 8,
		"step_range": Vector2i(35, 75),
		"encounter_table": [
			{"enemy_type": "shadow_wraith", "weight": 30, "count_min": 1, "count_max": 2},
			{"enemy_type": "clockwork_soldier", "weight": 30, "count_min": 1, "count_max": 2},
			{"enemy_type": "corrupted_guard", "weight": 20, "count_min": 2, "count_max": 3},
			{"enemy_type": "administrator_enforcer", "weight": 20, "count_min": 1, "count_max": 1},
		],
		"safe": false,
	},
	# ── Ironhold Region ──
	"ironhold_outskirts": {
		"name": "Ironhold Outskirts",
		"enemy_level_min": 5, "enemy_level_max": 7,
		"recommended_level": 5,
		"step_range": Vector2i(45, 90),
		"encounter_table": [
			{"enemy_type": "corrupted_guard", "weight": 25, "count_min": 1, "count_max": 2},
			{"enemy_type": "gear_sentry", "weight": 20, "count_min": 1, "count_max": 1},
			{"enemy_type": "data_sprite", "weight": 20, "count_min": 1, "count_max": 2},
			{"enemy_type": "clockwork_soldier", "weight": 20, "count_min": 1, "count_max": 1},
			{"enemy_type": "glitch_wolf", "weight": 15, "count_min": 1, "count_max": 2},
		],
		"safe": false,
	},
	"ironhold_city": {
		"name": "Ironhold City",
		"enemy_level_min": 0, "enemy_level_max": 0,
		"recommended_level": 5,
		"step_range": Vector2i(999, 999),
		"encounter_table": [],
		"safe": true,
	},
	"ironhold_underground": {
		"name": "Ironhold Underground",
		"enemy_level_min": 7, "enemy_level_max": 9,
		"recommended_level": 7,
		"step_range": Vector2i(30, 70),
		"encounter_table": [
			{"enemy_type": "clockwork_soldier", "weight": 25, "count_min": 1, "count_max": 2},
			{"enemy_type": "shadow_wraith", "weight": 20, "count_min": 1, "count_max": 2},
			{"enemy_type": "phase_spider", "weight": 20, "count_min": 1, "count_max": 2},
			{"enemy_type": "data_sprite", "weight": 20, "count_min": 2, "count_max": 3},
			{"enemy_type": "corrupted_guard", "weight": 15, "count_min": 1, "count_max": 2},
		],
		"safe": false,
	},
	"ironhold_clock_tower": {
		"name": "Ironhold Clock Tower",
		"enemy_level_min": 7, "enemy_level_max": 9,
		"recommended_level": 7,
		"step_range": Vector2i(25, 65),
		"encounter_table": [
			{"enemy_type": "clockwork_soldier", "weight": 30, "count_min": 1, "count_max": 2},
			{"enemy_type": "gear_sentry", "weight": 25, "count_min": 1, "count_max": 1},
			{"enemy_type": "shadow_wraith", "weight": 25, "count_min": 1, "count_max": 1},
			{"enemy_type": "data_sprite", "weight": 20, "count_min": 1, "count_max": 2},
		],
		"safe": false,
	},
	# ── Fractured Wastes ──
	"fractured_wastes_outer": {
		"name": "Fractured Wastes — Outer Rim",
		"enemy_level_min": 9, "enemy_level_max": 11,
		"recommended_level": 9,
		"step_range": Vector2i(30, 65),
		"encounter_table": [
			{"enemy_type": "shadow_wraith", "weight": 22, "count_min": 1, "count_max": 2},
			{"enemy_type": "corruption_elemental", "weight": 20, "count_min": 1, "count_max": 1},
			{"enemy_type": "phase_spider", "weight": 18, "count_min": 1, "count_max": 2},
			{"enemy_type": "clockwork_soldier", "weight": 15, "count_min": 1, "count_max": 2},
			{"enemy_type": "administrator_enforcer", "weight": 15, "count_min": 1, "count_max": 1},
			{"enemy_type": "data_sprite", "weight": 10, "count_min": 2, "count_max": 3},
		],
		"safe": false,
	},
	"fractured_wastes_core": {
		"name": "Fractured Wastes — Core",
		"enemy_level_min": 11, "enemy_level_max": 13,
		"recommended_level": 11,
		"step_range": Vector2i(25, 55),
		"encounter_table": [
			{"enemy_type": "administrator_enforcer", "weight": 25, "count_min": 1, "count_max": 2},
			{"enemy_type": "corruption_elemental", "weight": 22, "count_min": 1, "count_max": 2},
			{"enemy_type": "shadow_wraith", "weight": 20, "count_min": 1, "count_max": 2},
			{"enemy_type": "phase_spider", "weight": 18, "count_min": 1, "count_max": 2},
			{"enemy_type": "data_sprite", "weight": 15, "count_min": 2, "count_max": 4},
		],
		"safe": false,
	},
	"fractured_wastes_shelter": {
		"name": "Survivor's Shelter",
		"enemy_level_min": 0, "enemy_level_max": 0,
		"recommended_level": 9,
		"step_range": Vector2i(999, 999),
		"encounter_table": [],
		"safe": true,
	},
}

## Explicit repeatable farming access points. These reuse ordinary encounter
## combat, but put a small resource-node loop and result summary around it.
const FARMING_ZONE_DATA: Dictionary = {
	"oakhaven_outskirts": {
		"name": "Oakhaven Outskirts",
		"difficulty_tier": "Beginner forage",
		"resource_node": "Herb Patch",
		"objective": "Gather a herb sample while clearing the pests drawn to the patch.",
		"result_text": "The outskirts patch settles after the threat is cleared.",
		"cooldown_msec": 12000,
		"encounter_zone_id": "oakhaven_fields",
		"encounter_table": [
			{"enemy_type": "slime", "weight": 55, "count_min": 1, "count_max": 2},
			{"enemy_type": "corrupted_rat", "weight": 35, "count_min": 1, "count_max": 2},
			{"enemy_type": "glitch_wolf", "weight": 10, "count_min": 1, "count_max": 1},
		],
		"resource_rewards": [
			{"item_id": "glitch_herb", "chance": 0.30},
			{"item_id": "slime_core", "chance": 0.18},
		],
	},
	"ironhold_training_yard": {
		"name": "Ironhold Training Yard",
		"difficulty_tier": "Midgame drill",
		"resource_node": "Ore Drill",
		"objective": "Prime the ore drill, then hold the yard while its noise draws patrols.",
		"result_text": "The yard drill cools after the training run.",
		"cooldown_msec": 18000,
		"encounter_zone_id": "ironhold_outskirts",
		"encounter_table": [
			{"enemy_type": "data_sprite", "weight": 45, "count_min": 1, "count_max": 1},
			{"enemy_type": "clockwork_soldier", "weight": 35, "count_min": 1, "count_max": 1},
			{"enemy_type": "corrupted_guard", "weight": 20, "count_min": 1, "count_max": 1},
		],
		"resource_rewards": [
			{"item_id": "data_ore", "chance": 0.34},
		],
	},
	"fractured_wastes_shard_fields": {
		"name": "Shard Fields",
		"difficulty_tier": "Danger field",
		"resource_node": "Shard Deposit",
		"objective": "Disturb the shard deposit and survive the signatures it attracts.",
		"result_text": "The shard field quiets, but only until the next surge.",
		"cooldown_msec": 24000,
		"encounter_zone_id": "fractured_wastes_outer",
		"encounter_table": [
			{"enemy_type": "data_sprite", "weight": 45, "count_min": 1, "count_max": 1},
			{"enemy_type": "shadow_wraith", "weight": 45, "count_min": 1, "count_max": 1},
			{"enemy_type": "clockwork_soldier", "weight": 10, "count_min": 1, "count_max": 1},
		],
		"resource_rewards": [
			{"item_id": "memory_shard", "chance": 0.38},
			{"item_id": "glitch_stabilizer", "chance": 0.06},
		],
	},
	"forgotten_sectors_cleanup": {
		"name": "Memory Fracture Cleanup",
		"difficulty_tier": "Late archive cleanup",
		"resource_node": "Null Archive Fracture",
		"objective": "Seal a deleted-case fracture before its residue pulls hostile signatures into the buffer.",
		"result_text": "The null archive closes for now. Nothing from the court route is rewritten.",
		"cooldown_msec": 26000,
		"encounter_zone_id": "fractured_wastes_outer",
		"encounter_table": [
			{"enemy_type": "data_sprite", "weight": 40, "count_min": 1, "count_max": 2},
			{"enemy_type": "shadow_wraith", "weight": 34, "count_min": 1, "count_max": 1},
			{"enemy_type": "phase_spider", "weight": 26, "count_min": 1, "count_max": 1},
		],
		"resource_rewards": [
			{"item_id": "memory_shard", "chance": 0.30},
			{"item_id": "data_ore", "chance": 0.16},
			{"item_id": "glitch_herb", "chance": 0.10},
		],
	},
	"cathedral_firewall_drill": {
		"name": "Firewall Drill",
		"difficulty_tier": "Late doctrine drill",
		"resource_node": "Firewall Node",
		"objective": "Trigger a controlled purge pulse and clear the admin pressure it calls into the nave buffer.",
		"result_text": "The node cools without touching the Choir Core route.",
		"cooldown_msec": 30000,
		"encounter_zone_id": "fractured_wastes_core",
		"encounter_table": [
			{"enemy_type": "administrator_enforcer", "weight": 38, "count_min": 1, "count_max": 1},
			{"enemy_type": "clockwork_soldier", "weight": 30, "count_min": 1, "count_max": 2},
			{"enemy_type": "data_sprite", "weight": 20, "count_min": 1, "count_max": 2},
			{"enemy_type": "shadow_wraith", "weight": 12, "count_min": 1, "count_max": 1},
		],
		"resource_rewards": [
			{"item_id": "data_ore", "chance": 0.34},
			{"item_id": "glitch_stabilizer", "chance": 0.08},
		],
	},
	"memory_ocean_salvage_run": {
		"name": "Backup Salvage Run",
		"difficulty_tier": "Late tide salvage",
		"resource_node": "Tide Fragment",
		"objective": "Pull a backup fragment from the tide and survive the unstable histories that surface with it.",
		"result_text": "The shoreline calms. The Archive Tide route remains untouched.",
		"cooldown_msec": 34000,
		"encounter_zone_id": "fractured_wastes_core",
		"encounter_table": [
			{"enemy_type": "shadow_wraith", "weight": 34, "count_min": 1, "count_max": 2},
			{"enemy_type": "corruption_elemental", "weight": 32, "count_min": 1, "count_max": 1},
			{"enemy_type": "data_sprite", "weight": 22, "count_min": 1, "count_max": 2},
			{"enemy_type": "phase_spider", "weight": 12, "count_min": 1, "count_max": 1},
		],
		"resource_rewards": [
			{"item_id": "memory_shard", "chance": 0.40},
			{"item_id": "glitch_stabilizer", "chance": 0.10},
		],
	},
}

# ── Enemy Script Paths ────────────────────────────────────────────────────
const ENEMY_SCRIPTS: Dictionary = {
	"slime": "res://scripts/combat/enemies/slime.gd",
	"corrupted_rat": "res://scripts/combat/enemies/corrupted_rat.gd",
	"glitch_wolf": "res://scripts/combat/enemies/glitch_wolf.gd",
	"corrupted_guard": "res://scripts/combat/enemies/corrupted_guard.gd",
	"data_sprite": "res://scripts/combat/enemies/data_sprite.gd",
	"clockwork_soldier": "res://scripts/combat/enemies/clockwork_soldier.gd",
	"shadow_wraith": "res://scripts/combat/enemies/shadow_wraith.gd",
	"administrator_enforcer": "res://scripts/combat/enemies/administrator_enforcer.gd",
	"mushroom_mimic": "res://scripts/combat/enemies/mushroom_mimic.gd",
	"gear_sentry": "res://scripts/combat/enemies/gear_sentry.gd",
	"phase_spider": "res://scripts/combat/enemies/phase_spider.gd",
	"corruption_elemental": "res://scripts/combat/enemies/corruption_elemental.gd",
}

# ── Enemy Base Stats (used for zone-level scaling) ─────────────────────────
# These are the stats at enemy_level = 1. They scale with zone level.
const ENEMY_BASE_STATS: Dictionary = {
	"slime":                {"hp": 30,  "damage": 8,  "speed": 60,  "xp": 8,   "gold": 5},
	"corrupted_rat":        {"hp": 25,  "damage": 10, "speed": 90,  "xp": 12,  "gold": 8},
	"glitch_wolf":          {"hp": 45,  "damage": 14, "speed": 120, "xp": 20,  "gold": 14},
	"corrupted_guard":      {"hp": 70,  "damage": 18, "speed": 80,  "xp": 35,  "gold": 22},
	"data_sprite":          {"hp": 40,  "damage": 16, "speed": 100, "xp": 30,  "gold": 18},
	"clockwork_soldier":    {"hp": 90,  "damage": 22, "speed": 70,  "xp": 50,  "gold": 35},
	"shadow_wraith":        {"hp": 75,  "damage": 25, "speed": 110, "xp": 60,  "gold": 42},
	"administrator_enforcer": {"hp": 120, "damage": 30, "speed": 95, "xp": 80, "gold": 55},
	"mushroom_mimic":       {"hp": 55,  "damage": 14, "speed": 70,  "xp": 40,  "gold": 25},
	"gear_sentry":          {"hp": 100, "damage": 20, "speed": 0,   "xp": 55,  "gold": 30},
	"phase_spider":         {"hp": 45,  "damage": 16, "speed": 160, "xp": 50,  "gold": 28},
	"corruption_elemental": {"hp": 70,  "damage": 18, "speed": 85,  "xp": 65,  "gold": 40},
}

# ── Encounter Types ───────────────────────────────────────────────────────
enum EncounterType { COMBAT, TREASURE, AMBUSH, NPC_EVENT }

## Weights for encounter type rolls (must sum to 100)
const ENCOUNTER_TYPE_WEIGHTS: Dictionary = {
	EncounterType.COMBAT: 65,
	EncounterType.TREASURE: 15,
	EncounterType.AMBUSH: 12,
	EncounterType.NPC_EVENT: 8,
}

## Treasure encounter loot tables by zone difficulty tier
const TREASURE_LOOT: Dictionary = {
	"low": [  # Oakhaven zones
		{"type": "gold", "amount_min": 15, "amount_max": 40},
		{"type": "health_potion", "amount_min": 1, "amount_max": 2},
		{"type": "xp", "amount_min": 20, "amount_max": 50},
	],
	"mid": [  # Ironhold zones
		{"type": "gold", "amount_min": 30, "amount_max": 80},
		{"type": "health_potion", "amount_min": 1, "amount_max": 3},
		{"type": "mana_potion", "amount_min": 1, "amount_max": 2},
		{"type": "xp", "amount_min": 50, "amount_max": 120},
		{"type": "rare_material", "amount_min": 1, "amount_max": 1},
	],
	"high": [  # Fractured Wastes zones
		{"type": "gold", "amount_min": 60, "amount_max": 150},
		{"type": "health_potion", "amount_min": 2, "amount_max": 4},
		{"type": "mana_potion", "amount_min": 1, "amount_max": 3},
		{"type": "xp", "amount_min": 100, "amount_max": 250},
		{"type": "rare_material", "amount_min": 1, "amount_max": 2},
		{"type": "charm_stone", "amount_min": 1, "amount_max": 1},
	],
}

## NPC event pool — random helpful/flavor encounters
const NPC_EVENTS: Array = [
	{"id": "wandering_merchant", "text": "A wandering merchant offers supplies at a discount.", "effect": "shop_discount"},
	{"id": "lost_traveler", "text": "A lost traveler shares knowledge of the area.", "effect": "xp_bonus"},
	{"id": "wounded_soldier", "text": "A wounded soldier offers a health potion in thanks.", "effect": "free_potion"},
	{"id": "data_fragment", "text": "You discover a floating data fragment. It hums with energy.", "effect": "lore_hint"},
	{"id": "old_hermit", "text": "An old hermit warns of danger ahead, boosting your guard.", "effect": "temp_defense"},
	{"id": "glitch_echo", "text": "A glitch echo replays a memory from before the Shattering.", "effect": "corruption_reduce"},
]

signal encounter_type_rolled(type: EncounterType)
signal treasure_found(loot: Array)
signal npc_event_triggered(event_id: String)

# ── Runtime State ─────────────────────────────────────────────────────────
var current_zone_id: String = ""
var steps_since_last_encounter: int = 0
var steps_until_next_encounter: int = 30
var encounter_enabled: bool = true
var _in_encounter: bool = false
var _current_encounter_type: int = EncounterType.COMBAT
var _player_return_position: Vector2 = Vector2.ZERO
var _player_return_scene: String = ""
var _encounter_xp_total: int = 0
var _encounter_gold_total: int = 0
var _enemies_alive: int = 0
var _encounter_enemy_count: int = 0  # Total enemies in this encounter (for combo scaling)
var _pending_farming_zone: Dictionary = {}
var _farming_cooldown_until_msec: Dictionary = {}
const DEFAULT_FARMING_REENTRY_COOLDOWN_MSEC: int = 12000

# ── Encounter Rate Modifiers ──────────────────────────────────────────────
var encounter_rate_mult: float = 1.0  # Affected by charms/items
const FLEE_BASE_CHANCE: float = 0.70
const FLEE_LEVEL_PENALTY: float = 0.10  # Per enemy level above player
const FLEE_HOLD_TIME: float = 2.0

# ── Step tracking ─────────────────────────────────────────────────────────
var _last_player_pos: Vector2 = Vector2.ZERO
const STEP_DISTANCE: float = 32.0  # Pixels per "step"
var _distance_accumulator: float = 0.0

# ── Encounter Warning HUD ────────────────────────────────────────────────
var _warning_overlay: ColorRect = null
var _warning_label: Label = null
var _warning_canvas: CanvasLayer = null

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_setup_warning_hud()


func _process(delta: float) -> void:
	if not encounter_enabled or _in_encounter:
		# Safety recovery: if we're somehow flagged as in-encounter but the game
		# state has returned to EXPLORATION, force-reset to prevent permanent lockout.
		if _in_encounter and has_node("/root/GameManager") and GameManager.current_state == GameManager.GameState.EXPLORATION:
			push_warning("[ENCOUNTER] Safety reset: _in_encounter was stuck true while in EXPLORATION state")
			_in_encounter = false
			# e.g. the player died mid-run: a leftover farming zone would turn the
			# next ordinary random encounter into a "farming" run.
			_pending_farming_zone.clear()
		return
	if not has_node("/root/GameManager"):
		return
	if GameManager.current_state != GameManager.GameState.EXPLORATION:
		return

	var zone = ZONE_DATA.get(current_zone_id, {})
	if zone.get("safe", true):
		return

	# Track player movement as "steps"
	var players = get_tree().get_nodes_in_group("player")
	if players.is_empty():
		return
	var player = players[0] as Node2D
	if not is_instance_valid(player):
		return

	var dist = player.global_position.distance_to(_last_player_pos)
	_last_player_pos = player.global_position

	# Ignore teleports / large position changes
	if dist > 200.0:
		return
	# No steps while a menu blocks gameplay (ContextStack.gameplay_blocked()
	# covers random encounters), during dialogue, or mid scene transition:
	# a cutscene moving the player could otherwise start a fight, and
	# SceneTransitions drops a second change_scene, which left the encounter
	# flagged with no arena loaded.
	if ContextStack.gameplay_blocked() \
			or (has_node("/root/DialogueManager") and DialogueManager.is_active) \
			or (has_node("/root/SceneTransitions") and SceneTransitions.is_transitioning):
		return

	_distance_accumulator += dist
	while _distance_accumulator >= STEP_DISTANCE:
		_distance_accumulator -= STEP_DISTANCE
		steps_since_last_encounter += 1

	# Emit encounter warning as player approaches threshold (0.0 = safe, 1.0 = imminent)
	if steps_until_next_encounter > 0:
		var danger = clampf(float(steps_since_last_encounter) / float(steps_until_next_encounter), 0.0, 1.0)
		if danger >= 0.5:
			encounter_warning.emit(danger)

	if steps_since_last_encounter >= steps_until_next_encounter:
		_trigger_encounter()


## Set the current zone. Called by region scripts when player enters a sub-zone.
func set_zone(zone_id: String) -> void:
	if zone_id == current_zone_id:
		return
	current_zone_id = zone_id
	steps_since_last_encounter = 0
	_roll_next_encounter_distance()
	_update_warning_hud(0.0)  # steps were reset; don't carry a lit warning into a safe zone
	if OS.is_debug_build():
		var zone_name = ZONE_DATA.get(zone_id, {}).get("name", zone_id)
		print("[ENCOUNTER] Zone changed: %s" % zone_name)


## Roll how many steps until the next encounter
func _roll_next_encounter_distance() -> void:
	var zone = ZONE_DATA.get(current_zone_id, {})
	var step_range: Vector2i = zone.get("step_range", Vector2i(20, 40))
	var base_steps = randi_range(step_range.x, step_range.y)
	steps_until_next_encounter = int(base_steps * encounter_rate_mult)
	steps_until_next_encounter = maxi(steps_until_next_encounter, 5)


## Generate and trigger a random encounter from the current zone's table
func _trigger_encounter() -> void:
	if _in_encounter:
		return
	var zone = ZONE_DATA.get(current_zone_id, {})
	if zone.is_empty() or zone.get("safe", true):
		return

	var table: Array = zone.get("encounter_table", [])
	if table.is_empty():
		return

	_in_encounter = true
	steps_since_last_encounter = 0
	_roll_next_encounter_distance()
	# The warning only ever emits at >= 50 % danger, so nothing cleared it after
	# the fight started: "!!! DANGER !!!" stayed on screen (layer 90) through
	# combat and back in the region.
	_update_warning_hud(0.0)
	# Random encounters are never farming runs.
	_pending_farming_zone.clear()

	# Save player position for return
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		_player_return_position = (players[0] as Node2D).global_position
	_player_return_scene = get_tree().current_scene.scene_file_path

	# Roll encounter type
	_current_encounter_type = _roll_encounter_type()
	encounter_type_rolled.emit(_current_encounter_type)

	match _current_encounter_type:
		EncounterType.COMBAT:
			_trigger_combat_encounter(table, zone)
		EncounterType.TREASURE:
			_trigger_treasure_encounter(zone)
		EncounterType.AMBUSH:
			_trigger_ambush_encounter(table, zone)
		EncounterType.NPC_EVENT:
			_trigger_npc_encounter()


## Start one deliberate repeatable farming encounter from a region marker.
## The marker press is opt-in; this short cooldown only prevents immediate
## retriggering after the player returns to the same region spot.
func start_farming_encounter(
	farming_zone_id: String,
	return_position: Vector2,
	return_scene: String = "",
	run_context: Dictionary = {}
) -> bool:
	if _in_encounter or get_farming_cooldown_seconds(farming_zone_id) > 0:
		return false
	if not has_node("/root/GameManager"):
		return false

	var farming_zone: Dictionary = FARMING_ZONE_DATA.get(farming_zone_id, {})
	if farming_zone.is_empty():
		push_warning("[ENCOUNTER] Unknown farming zone: %s" % farming_zone_id)
		return false

	var encounter_zone_id: String = farming_zone.get("encounter_zone_id", "")
	var zone: Dictionary = ZONE_DATA.get(encounter_zone_id, {})
	var table: Array = farming_zone.get("encounter_table", [])
	if encounter_zone_id.is_empty() or zone.is_empty() or table.is_empty():
		push_warning("[ENCOUNTER] Farming zone is missing encounter data: %s" % farming_zone_id)
		return false

	set_zone(encounter_zone_id)
	_in_encounter = true
	steps_since_last_encounter = 0
	_roll_next_encounter_distance()
	_update_warning_hud(0.0)
	_current_encounter_type = EncounterType.COMBAT
	encounter_type_rolled.emit(_current_encounter_type)
	_player_return_position = return_position
	_player_return_scene = return_scene
	if _player_return_scene.is_empty() and get_tree().current_scene:
		_player_return_scene = get_tree().current_scene.scene_file_path
	_pending_farming_zone = farming_zone.duplicate(true)
	_pending_farming_zone["id"] = farming_zone_id
	for context_key in ["run_label", "result_text", "resource_node"]:
		if run_context.has(context_key):
			_pending_farming_zone[context_key] = run_context[context_key]
	var cooldown_msec: int = int(farming_zone.get("cooldown_msec", DEFAULT_FARMING_REENTRY_COOLDOWN_MSEC))
	_farming_cooldown_until_msec[farming_zone_id] = Time.get_ticks_msec() + cooldown_msec
	_trigger_combat_encounter(table, zone)
	return true


func get_farming_zone_data(farming_zone_id: String) -> Dictionary:
	return FARMING_ZONE_DATA.get(farming_zone_id, {}).duplicate(true)


func get_farming_cooldown_seconds(farming_zone_id: String) -> int:
	var cooldown_until: int = int(_farming_cooldown_until_msec.get(farming_zone_id, 0))
	var remaining_msec := maxi(0, cooldown_until - Time.get_ticks_msec())
	return ceili(float(remaining_msec) / 1000.0)


## Roll which type of encounter happens
func _roll_encounter_type() -> int:
	var total_weight: int = 0
	for w in ENCOUNTER_TYPE_WEIGHTS.values():
		total_weight += w
	var roll: int = randi() % total_weight
	var accum: int = 0
	for type_id in ENCOUNTER_TYPE_WEIGHTS:
		accum += ENCOUNTER_TYPE_WEIGHTS[type_id]
		if roll < accum:
			return type_id
	return EncounterType.COMBAT


## Standard combat encounter — sends player to combat arena
func _trigger_combat_encounter(table: Array, zone: Dictionary) -> void:
	var enemies_to_spawn: Array[Dictionary] = _roll_encounter(table, zone)

	_encounter_xp_total = 0
	_encounter_gold_total = 0
	_enemies_alive = enemies_to_spawn.size()
	_encounter_enemy_count = enemies_to_spawn.size()

	encounter_triggered.emit(current_zone_id, enemies_to_spawn)

	var pending_encounter := {
		"zone_id": current_zone_id,
		"enemies": enemies_to_spawn,
		"return_scene": _player_return_scene,
		"return_position": _player_return_position,
		"encounter_type": "combat",
	}
	if not _pending_farming_zone.is_empty():
		pending_encounter["encounter_type"] = "farming"
		pending_encounter["farming_zone_id"] = _pending_farming_zone.get("id", "")
		pending_encounter["farming_zone_name"] = _pending_farming_zone.get("name", "")
	GameManager.set_meta("pending_encounter", pending_encounter)

	# Before either branch: left in EXPLORATION, _process's safety reset would
	# clear _in_encounter before the arena loads.
	GameManager.change_state(GameManager.GameState.COMBAT)
	if has_node("/root/SceneTransitions"):
		SceneTransitions.change_scene("res://scenes/combat/combat_arena.tscn", SceneTransitions.TransitionStyle.COMBAT_ENTRY)
	else:
		get_tree().change_scene_to_file("res://scenes/combat/combat_arena.tscn")


## Ambush encounter — enemies are stronger, more numerous, but better rewards
func _trigger_ambush_encounter(table: Array, zone: Dictionary) -> void:
	var enemies_to_spawn: Array[Dictionary] = _roll_encounter(table, zone)

	# Ambush: add 1-2 extra enemies and boost levels by 1
	var extra_count = randi_range(1, 2)
	for _i in range(extra_count):
		if enemies_to_spawn.size() >= 6:
			break
		var bonus_enemy = enemies_to_spawn[randi() % enemies_to_spawn.size()].duplicate()
		bonus_enemy["level"] = mini(bonus_enemy["level"] + 1, 20)
		enemies_to_spawn.append(bonus_enemy)

	# Boost all enemy levels by 1 for ambush
	for enemy in enemies_to_spawn:
		enemy["level"] = mini(enemy["level"] + 1, 20)

	_encounter_xp_total = 0
	_encounter_gold_total = 0
	_enemies_alive = enemies_to_spawn.size()
	_encounter_enemy_count = enemies_to_spawn.size()

	encounter_triggered.emit(current_zone_id, enemies_to_spawn)

	GameManager.set_meta("pending_encounter", {
		"zone_id": current_zone_id,
		"enemies": enemies_to_spawn,
		"return_scene": _player_return_scene,
		"return_position": _player_return_position,
		"encounter_type": "ambush",
		"reward_mult": 1.5,  # 50% bonus rewards for surviving an ambush
	})

	GameManager.change_state(GameManager.GameState.COMBAT)
	if has_node("/root/SceneTransitions"):
		SceneTransitions.change_scene("res://scenes/combat/combat_arena.tscn", SceneTransitions.TransitionStyle.COMBAT_ENTRY)
	else:
		get_tree().change_scene_to_file("res://scenes/combat/combat_arena.tscn")


## Treasure encounter — find loot without combat
func _trigger_treasure_encounter(zone: Dictionary) -> void:
	var zone_level_avg = (zone.get("enemy_level_min", 1) + zone.get("enemy_level_max", 1)) / 2
	var tier: String = "low"
	if zone_level_avg >= 9:
		tier = "high"
	elif zone_level_avg >= 5:
		tier = "mid"

	var loot_pool: Array = TREASURE_LOOT.get(tier, TREASURE_LOOT["low"])
	# Pick 1-2 random loot items
	var num_items = randi_range(1, 2)
	var found_loot: Array = []

	for _i in range(num_items):
		var loot_entry = loot_pool[randi() % loot_pool.size()]
		var amount = randi_range(loot_entry["amount_min"], loot_entry["amount_max"])
		found_loot.append({"type": loot_entry["type"], "amount": amount})

	# Apply rewards immediately
	_apply_treasure_rewards(found_loot)
	treasure_found.emit(found_loot)

	# Show reward text to player
	if has_node("/root/VFXLibrary"):
		var players = get_tree().get_nodes_in_group("player")
		var pos: Vector2 = _player_return_position + Vector2(0, -60)
		if players.size() > 0:
			pos = (players[0] as Node2D).global_position + Vector2(0, -60)
		VFXLibrary.spawn_status_indicator("TREASURE FOUND!", pos, get_tree().current_scene, false)
		for item in found_loot:
			pos.y -= 25
			var text = _format_loot_text(item)
			await get_tree().create_timer(0.3).timeout
			if not is_inside_tree():
				return
			VFXLibrary.spawn_pickup_text(text, pos, get_tree().current_scene, Color(1.0, 0.85, 0.1))

	# Brief delay then end encounter (no scene transition needed)
	await get_tree().create_timer(1.5).timeout
	if not is_inside_tree():
		return
	_in_encounter = false


## Apply treasure loot to player stats
func _apply_treasure_rewards(loot: Array) -> void:
	if not has_node("/root/GameManager"):
		return
	for item in loot:
		match item["type"]:
			"gold":
				GameManager.add_gold(item["amount"])
			"xp":
				GameManager.add_xp(item["amount"])
			"health_potion":
				# Heal player directly
				var heal_amount: int = item["amount"] * 30
				GameManager.player_stats["hp"] = mini(
					GameManager.player_stats.get("hp", 100) + heal_amount,
					GameManager.player_stats.get("max_hp", 100)
				)
			"mana_potion":
				var mp_amount: int = item["amount"] * 20
				GameManager.player_stats["mp"] = mini(
					GameManager.player_stats.get("mp", 50) + mp_amount,
					GameManager.player_stats.get("max_mp", 50)
				)
			"rare_material":
				GameManager.add_gold(item["amount"] * 50)  # Convert to gold value
			"charm_stone":
				GameManager.add_gold(item["amount"] * 100)


## Format loot text for display
func _format_loot_text(item: Dictionary) -> String:
	match item["type"]:
		"gold": return "+%d Gold" % item["amount"]
		"xp": return "+%d XP" % item["amount"]
		"health_potion": return "+%d HP Restored" % (item["amount"] * 30)
		"mana_potion": return "+%d MP Restored" % (item["amount"] * 20)
		"rare_material": return "+%d Rare Material" % item["amount"]
		"charm_stone": return "+%d Charm Stone" % item["amount"]
	return "+%d %s" % [item["amount"], item["type"]]


## NPC event encounter — random helpful/flavor event
func _trigger_npc_encounter() -> void:
	var event = NPC_EVENTS[randi() % NPC_EVENTS.size()]
	npc_event_triggered.emit(event["id"])

	# Show event text
	if has_node("/root/DialogueManager"):
		await DialogueManager.say("???", event["text"])
		if not is_inside_tree():
			return

	# Apply event effect
	_apply_npc_event_effect(event["effect"])

	await get_tree().create_timer(1.0).timeout
	if not is_inside_tree():
		return
	_in_encounter = false


## Apply NPC event effects to player
func _apply_npc_event_effect(effect: String) -> void:
	if not has_node("/root/GameManager"):
		return
	match effect:
		"shop_discount":
			GameManager.add_gold(25)  # Small gold bonus as "discount"
		"xp_bonus":
			GameManager.add_xp(30)
		"free_potion":
			GameManager.player_stats["hp"] = mini(
				GameManager.player_stats.get("hp", 100) + 40,
				GameManager.player_stats.get("max_hp", 100)
			)
		"lore_hint":
			GameManager.add_xp(15)
			# Could unlock a lore journal entry in the future
		"temp_defense":
			# Cap NPC defense bonus at +6 total to prevent infinite stacking
			var npc_def_bonus: int = GameManager.get_meta("npc_defense_bonus") if GameManager.has_meta("npc_defense_bonus") else 0
			if npc_def_bonus < 6:
				GameManager.player_stats["defense"] = GameManager.player_stats.get("defense", 0) + 3
				GameManager.set_meta("npc_defense_bonus", npc_def_bonus + 3)
		"corruption_reduce":
			GameManager.add_glitch_corruption(-5.0)


## Roll enemies from a weighted encounter table
func _roll_encounter(table: Array, zone: Dictionary) -> Array[Dictionary]:
	var total_weight: float = 0.0
	for entry in table:
		total_weight += entry.get("weight", 1.0)

	# Roll 1-2 entries from the table
	var num_rolls = randi_range(1, 2)
	var result: Array[Dictionary] = []

	for _i in range(num_rolls):
		var roll = randf() * total_weight
		var accum: float = 0.0
		for entry in table:
			accum += entry.get("weight", 1.0)
			if roll <= accum:
				var count = randi_range(entry.get("count_min", 1), entry.get("count_max", 1))
				for _j in range(count):
					var enemy_level = randi_range(
						zone.get("enemy_level_min", 1),
						zone.get("enemy_level_max", 1)
					)
					result.append({
						"type": entry["enemy_type"],
						"level": enemy_level,
					})
				break

	# Cap at 5 enemies max per encounter
	if result.size() > 5:
		result.resize(5)

	return result


## Called by combat arena when an enemy dies during a random encounter
func on_encounter_enemy_killed(enemy_type: String, enemy_level: int) -> void:
	if not _in_encounter:
		return
	# Victory already triggered: a late or duplicate kill report would run
	# _on_encounter_victory() again, paying out and changing scene twice.
	if _enemies_alive <= 0:
		return

	var base = ENEMY_BASE_STATS.get(enemy_type, {"xp": 10, "gold": 5})
	var level_mult = 1.0 + (enemy_level - 1) * 0.15

	# XP scaling: bonus for killing higher-level enemies, penalty for lower
	var player_level: int = GameManager.player_stats.get("level", 1)
	var level_diff = enemy_level - player_level
	var xp_scale: float = 1.0
	if level_diff > 0:
		xp_scale = 1.0 + level_diff * 0.20  # 20% bonus per level above player
	elif level_diff < 0:
		xp_scale = maxf(0.1, 1.0 + level_diff * 0.15)  # -15% per level below, min 10%

	# Ambush encounters grant 50% bonus rewards
	var type_mult: float = 1.5 if _current_encounter_type == EncounterType.AMBUSH else 1.0

	var xp = int(base["xp"] * level_mult * xp_scale * type_mult)
	var gold = int(base["gold"] * level_mult * type_mult)

	_encounter_xp_total += xp
	_encounter_gold_total += gold
	_enemies_alive -= 1

	if _enemies_alive <= 0:
		_on_encounter_victory()


## Handle encounter victory — award XP/gold, return to exploration
func _on_encounter_victory() -> void:
	# Combo bonus: reward maintained combo during larger encounters
	var combo_bonus_xp: int = 0
	var combo_bonus_gold: int = 0
	if has_node("/root/GameJuice") and _encounter_enemy_count >= 2:
		var combo = GameJuice.get_combo_count()
		var combo_mult = GameJuice.get_combo_multiplier()
		if combo >= 5:  # Only award bonus for decent combos
			# Bonus scales with enemy count and combo multiplier
			var size_factor: float = minf(_encounter_enemy_count / 3.0, 2.0)  # Max 2x for 6+ enemies
			combo_bonus_xp = int(_encounter_xp_total * (combo_mult - 1.0) * size_factor * 0.5)
			combo_bonus_gold = int(_encounter_gold_total * (combo_mult - 1.0) * size_factor * 0.3)

	# Award rewards
	var total_xp: int = _encounter_xp_total + combo_bonus_xp
	var total_gold: int = _encounter_gold_total + combo_bonus_gold

	if has_node("/root/GameManager"):
		GameManager.add_xp(total_xp)
		GameManager.add_gold(total_gold)
		GameManager.stats["enemies_killed"] = GameManager.stats.get("enemies_killed", 0) + _encounter_enemy_count
		var farming_materials: Array[Dictionary] = _award_farming_materials()
		_record_farming_result(total_xp, total_gold, farming_materials)

	# Show combo bonus if earned
	if combo_bonus_xp > 0 and has_node("/root/VFXLibrary"):
		VFXLibrary.spawn_pickup_text(
			"COMBO BONUS! +%d XP +%d G" % [combo_bonus_xp, combo_bonus_gold],
			Vector2(640, 280), get_tree().current_scene, Color(1.0, 0.9, 0.2))

	encounter_finished.emit(true, total_xp, total_gold)

	# Brief delay then return to exploration (pausable: this autoload is
	# PROCESS_MODE_ALWAYS, and a pause menu opened here must hold the return)
	await get_tree().create_timer(1.5, false).timeout
	if not is_inside_tree():
		return
	# A successful flee in the meantime already ended the encounter and left.
	if not _in_encounter:
		return

	_return_to_exploration()


## Attempt to flee from a random encounter
func attempt_flee() -> bool:
	if not _in_encounter:
		return false

	var zone = ZONE_DATA.get(current_zone_id, {})
	var avg_enemy_level = (zone.get("enemy_level_min", 1) + zone.get("enemy_level_max", 1)) / 2.0
	var player_level = float(GameManager.player_stats.get("level", 1))
	var level_diff = maxf(0.0, avg_enemy_level - player_level)

	var flee_chance = FLEE_BASE_CHANCE - level_diff * FLEE_LEVEL_PENALTY
	flee_chance = clampf(flee_chance, 0.1, 0.95)

	var success = randf() < flee_chance
	fled_encounter.emit(success)

	# NOTE: Do NOT call _return_to_exploration() here. The caller
	# (player_combat._handle_flee_combat) shows visual feedback first,
	# then calls end_encounter(false) which handles the transition.
	return success


## End the encounter manually (called by flee mechanic in player_combat)
## @param victory: true if enemies were all killed, false if fled
func end_encounter(victory: bool) -> void:
	if not _in_encounter:
		return
	_in_encounter = false
	if victory:
		encounter_won.emit()
	else:
		_pending_farming_zone.clear()
	_return_to_exploration()


## Return player to overworld/region after combat
func _return_to_exploration() -> void:
	_in_encounter = false
	_pending_farming_zone.clear()
	GameManager.change_state(GameManager.GameState.EXPLORATION)

	# Restore to return scene with position
	GameManager.set_return_point(_player_return_scene, _player_return_position)

	if has_node("/root/SceneTransitions") and not _player_return_scene.is_empty():
		SceneTransitions.change_scene(_player_return_scene, SceneTransitions.TransitionStyle.COMBAT_EXIT)
	elif not _player_return_scene.is_empty():
		get_tree().change_scene_to_file(_player_return_scene)
	else:
		# Fallback: return to overworld if return scene is unknown
		push_warning("[ENCOUNTER] No return scene set — defaulting to overworld")
		if has_node("/root/SceneTransitions"):
			SceneTransitions.change_scene("res://scenes/overworld/overworld.tscn")
		else:
			get_tree().change_scene_to_file("res://scenes/overworld/overworld.tscn")


## Check if player is currently in a random encounter
func is_in_encounter() -> bool:
	return _in_encounter


## Register additional enemies spawned mid-encounter (e.g., DataSprite clones)
func register_additional_enemies(count: int) -> void:
	if _in_encounter:
		_enemies_alive += count


## Get the recommended level for the current zone
func get_zone_recommended_level() -> int:
	var zone = ZONE_DATA.get(current_zone_id, {})
	return zone.get("recommended_level", 1)


## Get the zone display name
func get_zone_name() -> String:
	var zone = ZONE_DATA.get(current_zone_id, {})
	return zone.get("name", current_zone_id)


## Check if current zone is safe (no encounters)
func is_safe_zone() -> bool:
	var zone = ZONE_DATA.get(current_zone_id, {})
	return zone.get("safe", true)


## Get level scaling factors for enemies in a given zone
func get_zone_enemy_scaling(zone_id: String, enemy_type: String, enemy_level: int) -> Dictionary:
	var base = ENEMY_BASE_STATS.get(enemy_type, {"hp": 50, "damage": 10, "speed": 80, "xp": 10, "gold": 5})
	var level_mult = 1.0 + (enemy_level - 1) * 0.18  # 18% per level

	return {
		"hp": int(base["hp"] * level_mult),
		"damage": int(base["damage"] * level_mult),
		"speed": int(base["speed"] * (1.0 + (enemy_level - 1) * 0.05)),
		"xp": int(base["xp"] * (1.0 + (enemy_level - 1) * 0.15)),
		"gold": int(base["gold"] * (1.0 + (enemy_level - 1) * 0.12)),
		"level": enemy_level,
	}


## Apply null cloak charm effect (reduces encounter rate)
func apply_encounter_rate_modifier(mult: float) -> void:
	encounter_rate_mult = maxf(0.1, mult)
	_roll_next_encounter_distance()


## Reset encounter state (e.g. on game load)
func reset() -> void:
	current_zone_id = ""
	steps_since_last_encounter = 0
	steps_until_next_encounter = 30
	encounter_enabled = true
	_in_encounter = false
	encounter_rate_mult = 1.0
	_distance_accumulator = 0.0
	_pending_farming_zone.clear()
	_farming_cooldown_until_msec.clear()
	_update_warning_hud(0.0)


func _award_farming_materials() -> Array[Dictionary]:
	if _pending_farming_zone.is_empty() or not has_node("/root/Inventory"):
		return []

	var awarded: Array[Dictionary] = []
	for reward in _pending_farming_zone.get("resource_rewards", []):
		var item_id: String = reward.get("item_id", "")
		var chance: float = reward.get("chance", 0.0)
		if item_id.is_empty() or randf() > chance:
			continue
		var amount := maxi(1, int(reward.get("amount", 1)))
		if Inventory.add_item(item_id, amount):
			awarded.append({
				"item_id": item_id,
				"amount": amount,
				"name": _get_farming_item_name(item_id),
			})

	if awarded.is_empty() or not has_node("/root/VFXLibrary"):
		return awarded

	VFXLibrary.spawn_pickup_text(
		"Resource find: %s" % _format_farming_materials(awarded),
		Vector2(640, 315),
		get_tree().current_scene,
		Color(0.5, 1.0, 0.7)
	)
	return awarded


func _record_farming_result(total_xp: int, total_gold: int, materials: Array[Dictionary]) -> void:
	if _pending_farming_zone.is_empty() or not has_node("/root/GameManager"):
		return
	var zone_id: String = _pending_farming_zone.get("id", "")
	GameManager.set_meta("farming_run_result", {
		"zone_id": zone_id,
		"zone_name": _pending_farming_zone.get("name", zone_id),
		"difficulty_tier": _pending_farming_zone.get("difficulty_tier", "Farming run"),
		"resource_node": _pending_farming_zone.get("resource_node", "Resource Node"),
		"run_label": _pending_farming_zone.get("run_label", ""),
		"result_text": _pending_farming_zone.get("result_text", "The route settles."),
		"xp": total_xp,
		"gold": total_gold,
		"materials": materials,
		"cooldown_seconds": get_farming_cooldown_seconds(zone_id),
	})


func show_pending_farming_result(expected_zone_id: String, host: Node) -> Dictionary:
	if not has_node("/root/GameManager") or not GameManager.has_meta("farming_run_result"):
		return {}
	var result: Dictionary = GameManager.get_meta("farming_run_result", {})
	if result.get("zone_id", "") != expected_zone_id:
		return {}
	GameManager.remove_meta("farming_run_result")
	if host and host.is_inside_tree():
		_spawn_farming_result_panel(host, result)
	return result


func _spawn_farming_result_panel(host: Node, result: Dictionary) -> void:
	var layer := CanvasLayer.new()
	layer.name = "FarmingRunResult"
	layer.layer = 85
	host.add_child(layer)

	var panel := ColorRect.new()
	panel.color = Color(0.08, 0.09, 0.12, 0.92)
	panel.size = Vector2(430, 118)
	panel.position = Vector2(24, 88)
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(panel)

	var border := ColorRect.new()
	border.color = Color(0.42, 0.75, 0.45, 0.9)
	border.size = Vector2(430, 3)
	border.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(border)

	var text := Label.new()
	var heading := "%s complete - %s" % [
		result.get("zone_name", "Farming Run"),
		result.get("resource_node", "Resource Node"),
	]
	var run_label: String = result.get("run_label", "")
	if not run_label.is_empty():
		heading += " [%s]" % run_label
	text.text = "%s\n+%d XP   +%d Gold\nMaterials: %s\n%s  Re-entry: %ds" % [
		heading,
		int(result.get("xp", 0)),
		int(result.get("gold", 0)),
		_format_farming_materials(result.get("materials", [])),
		result.get("result_text", "The route settles."),
		int(result.get("cooldown_seconds", 0)),
	]
	text.add_theme_font_size_override("font_size", 10)
	text.add_theme_color_override("font_color", Color(0.92, 0.98, 0.9))
	text.position = Vector2(14, 12)
	text.size = Vector2(400, 96)
	text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	text.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(text)

	var tween := layer.create_tween()
	tween.tween_interval(4.5)
	tween.tween_property(panel, "modulate:a", 0.0, 0.5)
	tween.tween_callback(layer.queue_free)


func _format_farming_materials(materials: Array) -> String:
	if materials.is_empty():
		return "none this run"
	var parts: Array[String] = []
	for material in materials:
		parts.append("%s x%d" % [
			material.get("name", _get_farming_item_name(material.get("item_id", ""))),
			int(material.get("amount", 1)),
		])
	return ", ".join(parts)


func _get_farming_item_name(item_id: String) -> String:
	if has_node("/root/Inventory") and Inventory.ITEMS.has(item_id):
		return Inventory.ITEMS[item_id].get("name", item_id.replace("_", " ").capitalize())
	return item_id.replace("_", " ").capitalize()


## ═══════════════════════════════════════════════════════════════════════════
## ENCOUNTER WARNING HUD — Edge-of-screen danger indicator
## ═══════════════════════════════════════════════════════════════════════════

func _setup_warning_hud() -> void:
	_warning_canvas = CanvasLayer.new()
	_warning_canvas.name = "EncounterWarningLayer"
	_warning_canvas.layer = 90
	add_child(_warning_canvas)

	# Screen-edge red vignette overlay
	_warning_overlay = ColorRect.new()
	_warning_overlay.name = "DangerVignette"
	_warning_overlay.color = Color(0.8, 0.1, 0.1, 0.0)
	_warning_overlay.size = Vector2(1280, 720)
	_warning_overlay.position = Vector2.ZERO
	_warning_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_warning_canvas.add_child(_warning_overlay)

	# Danger text indicator
	_warning_label = Label.new()
	_warning_label.name = "DangerLabel"
	_warning_label.text = ""
	_warning_label.add_theme_font_size_override("font_size", 10)
	_warning_label.add_theme_color_override("font_color", Color(1.0, 0.5, 0.3, 0.0))
	_warning_label.position = Vector2(1100, 75)
	_warning_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_warning_canvas.add_child(_warning_label)

	encounter_warning.connect(_update_warning_hud)


func _update_warning_hud(danger: float) -> void:
	if not is_instance_valid(_warning_overlay):
		return

	if danger < 0.5:
		_warning_overlay.color.a = 0.0
		_warning_label.text = ""
		_warning_label.add_theme_color_override("font_color", Color(1, 1, 1, 0))
		return

	# Scale from 0 at 50% to max at 100%
	var intensity: float = (danger - 0.5) * 2.0  # 0.0–1.0

	# Red vignette — very subtle
	_warning_overlay.color.a = intensity * 0.08

	# Warning text
	if intensity < 0.4:
		_warning_label.text = "~ rustling ~"
		_warning_label.add_theme_color_override("font_color", Color(0.9, 0.8, 0.3, 0.5))
	elif intensity < 0.75:
		_warning_label.text = "!! movement nearby !!"
		_warning_label.add_theme_color_override("font_color", Color(1.0, 0.6, 0.2, 0.7))
	else:
		_warning_label.text = "!!! DANGER !!!"
		_warning_label.add_theme_color_override("font_color", Color(1.0, 0.3, 0.2, 0.9))
