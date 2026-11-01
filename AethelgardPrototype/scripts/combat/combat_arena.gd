extends Node2D

## Combat Arena — Handles both tutorial combat and random encounter battles.
## Tutorial mode: player vs. tutorial slime with Root Access demonstration.
## Encounter mode: spawns enemies from RandomEncounterSystem pending_encounter data.

@onready var player: CharacterBody2D = $Player
@onready var slime: EnemyBase = $Enemies/TutorialSlime
@onready var root_access_panel: Control = $UI/RootAccessPanel
@onready var glitch_meter_bar: ProgressBar = $UI/CombatHUD/TopBar/RightPanel/VBox/GlitchMeter
@onready var glitch_label: Label = $UI/CombatHUD/TopBar/RightPanel/VBox/GlitchLabel
@onready var player_hp_bar: ProgressBar = $UI/CombatHUD/TopBar/LeftPanel/VBox/PlayerHP
@onready var player_hp_label: Label = $UI/CombatHUD/TopBar/LeftPanel/VBox/HPLabel

var root_access_active: bool = false
var selected_enemy: EnemyBase = null
var tutorial_complete: bool = false

# ── Random Encounter Mode ─────────────────────────────────────────────────
var _is_random_encounter: bool = false
var _encounter_enemies: Array = []
var _encounter_type: String = "combat"
var _reward_mult: float = 1.0

# ── Enemy placeholder colors by type ──────────────────────────────────────
const ENEMY_COLORS: Dictionary = {
	"slime": Color(0.2, 0.8, 0.2),
	"corrupted_rat": Color(0.55, 0.35, 0.2),
	"glitch_wolf": Color(0.4, 0.4, 0.65),
	"corrupted_guard": Color(0.7, 0.25, 0.25),
	"data_sprite": Color(0.3, 0.7, 0.9),
	"clockwork_soldier": Color(0.6, 0.5, 0.3),
	"shadow_wraith": Color(0.25, 0.1, 0.35),
	"administrator_enforcer": Color(0.8, 0.15, 0.15),
	"mushroom_mimic": Color(0.4, 0.65, 0.3),
	"gear_sentry": Color(0.55, 0.45, 0.25),
	"phase_spider": Color(0.35, 0.1, 0.45),
	"corruption_elemental": Color(0.6, 0.1, 0.5),
}

# ── Enemy sizes by type ──────────────────────────────────────────────────
const ENEMY_SIZES: Dictionary = {
	"slime": Vector2(48, 36),
	"corrupted_rat": Vector2(40, 28),
	"glitch_wolf": Vector2(56, 48),
	"corrupted_guard": Vector2(48, 64),
	"data_sprite": Vector2(36, 36),
	"clockwork_soldier": Vector2(56, 72),
	"shadow_wraith": Vector2(48, 56),
	"administrator_enforcer": Vector2(64, 80),
	"mushroom_mimic": Vector2(40, 44),
	"gear_sentry": Vector2(52, 60),
	"phase_spider": Vector2(44, 40),
	"corruption_elemental": Vector2(48, 52),
}

# ── Boss fight scripts (for bosses routed to combat_arena) ─────────────────
const BOSS_SCRIPTS: Dictionary = {
	"clockwork_automaton": "res://scripts/combat/enemies/clockwork_automaton_boss.gd",
	"data_wraith": "res://scripts/combat/enemies/data_wraith_boss.gd",
	"sovereign": "res://scripts/combat/enemies/sovereign_boss.gd",
}
const BOSS_COLORS: Dictionary = {
	"clockwork_automaton": Color(0.6, 0.5, 0.3),
	"data_wraith": Color(0.3, 0.15, 0.5),
	"sovereign": Color(0.9, 0.8, 0.2),
}
const BOSS_SIZES: Dictionary = {
	"clockwork_automaton": Vector2(80, 100),
	"data_wraith": Vector2(70, 90),
	"sovereign": Vector2(90, 110),
}
const BOSS_DEFEATED_FLAGS: Dictionary = {
	"clockwork_automaton": "ch2_clockwork_automaton_defeated",
	"data_wraith": "ch2_data_wraith_defeated",
	"sovereign": "ch3_sovereign_defeated",
}

var _is_boss_fight: bool = false
var _boss_node: EnemyBase = null
var _boss_id: String = ""
var _boss_initial_hp: float = 0.0  # Track boss max HP for partial reward calc
var _perfect_delete_busy: bool = false

# ── Story fight mode (Y1-P0-T13) ──────────────────────────────────────────
## A scripted story encounter: the scene that wants it sets the GameManager metas
## `story_fight_id` (a key of STORY_FIGHTS) and `story_fight_return_scene`, then
## changes scene to this arena. Both metas are removed when `_ready` reads them,
## so leaving the arena any other way (pause menu, game over) cannot leave one behind.
## The player's death is a tutorial retry (never game over); winning sets the fight's
## story flags and goes back to the return scene. XP, gold and item drops are suppressed.
## Root Access and Perfect Delete stay refused in every story fight: their targeting knows no
## story enemy and a Perfect Delete kill would skip the story win (TD-031 D3), so no row key allows them.
## Emitted once when the fight is won. The only outcome is "win" (a retry emits nothing).
signal story_fight_resolved(outcome: String)

## A new fight is a new row, not new code (TD-031). One enemy per fight.
## Required keys (STORY_FIGHT_REQUIRED): enemy_script, enemy_type, enemy_name (the body's node name),
## enemy_spawn, player_spawn, default_return_scene (used when the return-scene meta is empty), flags
## (set on the win), controls (the InputService template of the controls line).
## Optional keys, defaults in STORY_FIGHT_DEFAULTS: shard_color, shard_count, shard_fade, shard_size,
## shard_z (the win's polygon beat; the win waits shard_fade even with no shards) and backdrop:
## {sky, ground, tree (colours), margin (Vector2), trees ([x, width, height] each), optional path (colour)};
## an empty backdrop keeps the scene's own sky and ground.
## Optional keys without a default (STORY_FIGHT_OPTIONAL): enemy_size, enemy_color, the body's placeholder
## size and colour; left out, the enemy_type's ENEMY_SIZES / ENEMY_COLORS entry. A row whose enemy_type has
## no entry must give them. validate_story_fight checks a row before its fight.
const STORY_FIGHTS: Dictionary = {
	"ch1_slime": {
		"enemy_script": "res://scripts/combat/enemies/slime.gd",
		"enemy_type": "slime",
		"enemy_name": "StoryFightSlime",
		# Inside the first frame: the camera follows the player, so at the spawn it shows x up to 840.
		"enemy_spawn": Vector2(760, 400),
		"player_spawn": Vector2(200, 400),
		"default_return_scene": "res://scenes/chapter1/elara_meeting.tscn",
		# The polygon beat the Elara meeting used to stage (colour and count kept from it).
		"shard_color": Color(0.45, 0.85, 0.75),
		"shard_count": 7,
		"shard_fade": 0.6,       # real seconds: the kill's slow-motion must not stretch the beat
		"shard_size": 12.0,
		"shard_z": 20,           # above the slime's death flash and smoke
		"flags": ["first_slime_defeated", "ch1_slime_fought"],
		# Procedural forest backdrop: the Elara meeting's colours (ch1_elara_meeting.gd).
		"backdrop": {
			"sky": Color(0.16, 0.1, 0.28),
			"ground": Color(0.08, 0.16, 0.06),
			"path": Color(0.22, 0.16, 0.08),
			"tree": Color(0.06, 0.14, 0.04),
			# The sky and ground reach this far past the 1280 x 720 arena, so the follow camera never shows
			# the grey beyond them (half a viewport plus a margin for screen shake).
			"margin": Vector2(700, 400),
			# [x, width, height]: each trunk stands on y 600; its canopy is 3 x 2.5 widths.
			"trees": [[-420, 38, 230], [-180, 34, 215], [50, 40, 240], [180, 35, 220], [350, 30, 210],
				[800, 38, 230], [950, 42, 225], [1100, 36, 235], [1200, 32, 220], [1420, 36, 225], [1660, 40, 235]],
		},
		"controls": "{move} — Move | {jump} — Jump | {sprint} — Dash | {attack} — Attack | {defend} — Parry",
	},
}
## Every required row key and the Variant type its value must have.
const STORY_FIGHT_REQUIRED: Dictionary = {
	"enemy_script": TYPE_STRING, "enemy_type": TYPE_STRING, "enemy_name": TYPE_STRING,
	"enemy_spawn": TYPE_VECTOR2, "player_spawn": TYPE_VECTOR2, "default_return_scene": TYPE_STRING,
	"flags": TYPE_ARRAY, "controls": TYPE_STRING,
}
## The value of every optional row key when the row leaves it out (the active config is the row merged
## over these). A number key takes an int or a float.
const STORY_FIGHT_DEFAULTS: Dictionary = {
	"shard_color": Color(1, 1, 1),
	"shard_count": 0,        # no shard beat; the win still waits shard_fade
	"shard_fade": 0.6,
	"shard_size": 12.0,
	"shard_z": 20,
	"backdrop": {},          # the scene's own sky and ground, no trees
}
## The keys a non-empty backdrop must have and their types; `path` (a Color) is its one optional key.
## Optional keys with no default, and their types: left out, the spawn reads the enemy_type's entry in
## STORY_ENEMY_LOOK_TABLES instead (validate_story_fight refuses a row that has neither).
const STORY_FIGHT_OPTIONAL: Dictionary = {"enemy_size": TYPE_VECTOR2, "enemy_color": TYPE_COLOR}
## Where each STORY_FIGHT_OPTIONAL key falls back to, by enemy_type.
const STORY_ENEMY_LOOK_TABLES: Dictionary = {"enemy_size": ENEMY_SIZES, "enemy_color": ENEMY_COLORS}
const STORY_BACKDROP_REQUIRED: Dictionary = {
	"sky": TYPE_COLOR, "ground": TYPE_COLOR, "tree": TYPE_COLOR, "margin": TYPE_VECTOR2, "trees": TYPE_ARRAY,
}
## The time the player's death animation runs before the retry (game time).
const STORY_RETRY_DELAY: float = 1.0
## How long a replaced enemy lives on (disabled, hidden) so no timer of its own
## resumes on a freed instance; EnemyBase.die() frees itself after 0.6 s the same way.
const STORY_OLD_ENEMY_LIFETIME: float = 0.6

## The story-fight table this arena reads (STORY_FIGHTS unless replaced). A test sets its own rows
## here before add_child: _ready consumes the metas, so a later assignment comes too late.
## Assign a new Dictionary; never mutate this one (it starts as the read-only STORY_FIGHTS const).
var story_fight_table: Dictionary = STORY_FIGHTS
## Retries the player has needed in this fight (read by tests and the playthrough bot).
var story_fight_retries: int = 0
var _story_id: String = ""
var _story_cfg: Dictionary = {}
var _story_return_scene: String = ""
var _story_resolved: bool = false
var _story_enemy: EnemyBase = null


# ═════════════════════════════════════════════════════════════════════════
# LIFECYCLE
# ═════════════════════════════════════════════════════════════════════════

## The arena was a 1280 px floor with no walls and no kill plane for enemies:
## an enemy knocked off an edge fell forever, so the fight could never end
## (and boss fights block fleeing). Walls keep everyone in; anything that still
## gets below the floor is killed so the encounter resolves.
const ARENA_WIDTH: float = 1280.0
const ARENA_KILL_Y: float = 1000.0

func _add_arena_bounds() -> void:
	for x in [-20.0, ARENA_WIDTH]:
		var wall := StaticBody2D.new()
		wall.name = "ArenaWall"
		wall.position = Vector2(x, -1400.0)
		var col := CollisionShape2D.new()
		var rect := RectangleShape2D.new()
		rect.size = Vector2(20.0, 2200.0)
		col.shape = rect
		col.position = rect.size * 0.5
		wall.add_child(col)
		add_child(wall)
	var kill_zone := Area2D.new()
	kill_zone.name = "EnemyKillZone"
	kill_zone.position = Vector2(-2000.0, ARENA_KILL_Y)
	kill_zone.collision_layer = 0
	kill_zone.collision_mask = 4  # enemy layer (EnemyBase._ready)
	var kill_col := CollisionShape2D.new()
	var kill_rect := RectangleShape2D.new()
	kill_rect.size = Vector2(ARENA_WIDTH + 4000.0, 400.0)
	kill_col.shape = kill_rect
	kill_col.position = kill_rect.size * 0.5
	kill_zone.add_child(kill_col)
	kill_zone.body_entered.connect(func(body):
		if body is EnemyBase and body.current_state != EnemyBase.State.DEAD:
			body.die.call_deferred()  # die() changes collision state; not allowed mid physics callback
	)
	add_child(kill_zone)

func _ready() -> void:
	if _has_gm():
		GameManager.change_state(GameManager.GameState.COMBAT)
		if not GameManager.glitch_meter_changed.is_connected(_on_glitch_meter_changed):
			GameManager.glitch_meter_changed.connect(_on_glitch_meter_changed)

	var legacy_hud = get_node_or_null("UI/CombatHUD")
	if legacy_hud:
		legacy_hud.visible = false
	# The story-fight metas are read and removed first, whichever mode runs.
	_story_id = _consume_story_fight_metas()
	if _story_id.is_empty():
		_build_phase10mm_arena_polish()
	_add_arena_bounds()

	# Check for random encounter mode
	if _has_gm() and GameManager.has_meta("pending_encounter"):
		_story_id = ""
		_start_random_encounter()
		return

	# Check for boss fight mode (Clockwork Automaton / Data Wraith routed here)
	if _has_gm() and GameManager.has_meta("boss_fight_id"):
		var boss_id: String = GameManager.get_meta("boss_fight_id")
		if boss_id in BOSS_SCRIPTS:
			_story_id = ""
			_start_boss_fight(boss_id)
			return

	# Story fight mode (Y1-P0-T13): checked after the encounter and boss modes
	if not _story_id.is_empty():
		_start_story_fight(_story_id)
		return

	# ── Tutorial Mode (original flow) ──
	_setup_sprites()
	_validate_scene()
	_update_ui()
	_configure_scripted_reward_enemy(slime)

	# Connect slime signals
	if slime:
		if slime.has_signal("died"):
			slime.died.connect(_on_slime_died)
		else:
			push_error("[COMBAT] Enemy node missing 'died' signal — attach script extending EnemyBase")
		if slime.has_signal("health_changed"):
			slime.health_changed.connect(_on_enemy_health_changed)
	else:
		push_error("[COMBAT] No enemy node at 'Enemies/TutorialSlime'")

	await get_tree().create_timer(0.5, false).timeout
	if not is_inside_tree():
		return
	_show_combat_tutorial()


func _exit_tree() -> void:
	if has_node("/root/GameManager") and GameManager.glitch_meter_changed.is_connected(_on_glitch_meter_changed):
		GameManager.glitch_meter_changed.disconnect(_on_glitch_meter_changed)


func _build_phase10mm_arena_polish() -> void:
	if not has_node("/root/AssetManager"):
		return
	var backplate = Polygon2D.new()
	backplate.name = "Phase10MMCombatBackplate"
	backplate.color = Color(0.08, 0.07, 0.14, 0.54)
	backplate.polygon = PackedVector2Array([
		Vector2(82, 592), Vector2(188, 330), Vector2(442, 254),
		Vector2(824, 254), Vector2(1098, 332), Vector2(1198, 592),
	])
	backplate.z_index = -10
	add_child(backplate)
	for flank_data in [
		{"name": "CombatFarWallLeft", "pos": Vector2(0, 282), "size": Vector2(154, 268)},
		{"name": "CombatFarWallRight", "pos": Vector2(1126, 282), "size": Vector2(154, 268)},
	]:
		var flank = ColorRect.new()
		flank.name = flank_data["name"]
		flank.color = Color(0.02, 0.02, 0.05, 0.52)
		flank.position = flank_data["pos"]
		flank.size = flank_data["size"]
		flank.z_index = -10
		add_child(flank)
	AssetManager.add_v3_environment_decal(self, "arena_border", Vector2(640, 466), Vector2(1180, 350), "V3CombatArenaBorder", -9, Color(0.98, 0.94, 1.0, 0.86))
	AssetManager.add_v3_environment_decal(self, "cathedral_circuit", Vector2(640, 508), Vector2(720, 174), "V3CombatArenaCircuit", -8, Color(0.72, 0.82, 1.0, 0.34))
	AssetManager.add_v3_environment_prop(self, "crates", Vector2(94, 430), Vector2(212, 58), "V3CombatArenaCratesLeft", -7, Color(0.92, 0.86, 0.94, 0.76))
	AssetManager.add_v3_environment_prop(self, "crates", Vector2(1188, 430), Vector2(212, 58), "V3CombatArenaCratesRight", -7, Color(0.92, 0.86, 0.94, 0.76))


# ═════════════════════════════════════════════════════════════════════════
# ENEMY BODIES (TD-031)
# ═════════════════════════════════════════════════════════════════════════

## The one enemy body every mode spawns (encounter, boss, story fight and its retry): a
## CharacterBody2D at `pos` whose feet are at its origin, with a "Sprite" ColorRect placeholder and
## a CollisionShape2D of the same `size`. Returned without a script: the caller sets any meta the
## script reads, then set_script, then add_child, so _ready runs with every child in place.
func _build_enemy_body(node_name: String, size: Vector2, color: Color, pos: Vector2) -> CharacterBody2D:
	var body := CharacterBody2D.new()
	body.name = node_name

	# Sprite placeholder (ColorRect) — EnemyBase expects a "Sprite" child
	var sprite_rect := ColorRect.new()
	sprite_rect.name = "Sprite"
	sprite_rect.size = size
	sprite_rect.position = Vector2(-size.x / 2.0, -size.y)
	sprite_rect.color = color
	sprite_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	body.add_child(sprite_rect)

	# CollisionShape2D — required for CharacterBody2D physics
	var col_shape := CollisionShape2D.new()
	var rect_shape := RectangleShape2D.new()
	rect_shape.size = size
	col_shape.shape = rect_shape
	col_shape.position = Vector2(0, -size.y / 2.0)
	body.add_child(col_shape)

	# Collision layers (same as the tutorial slime)
	body.collision_layer = 4  # Enemy layer
	body.collision_mask = 1   # Collide with world
	body.position = pos
	return body


# ═════════════════════════════════════════════════════════════════════════
# RANDOM ENCOUNTER MODE
# ═════════════════════════════════════════════════════════════════════════

func _start_random_encounter() -> void:
	_is_random_encounter = true
	var encounter_data: Dictionary = GameManager.get_meta("pending_encounter")
	GameManager.remove_meta("pending_encounter")

	_encounter_type = encounter_data.get("encounter_type", "combat")
	_reward_mult = encounter_data.get("reward_mult", 1.0)

	# Remove tutorial slime — it doesn't belong in random encounters
	if slime:
		slime.queue_free()
		slime = null

	_setup_sprites()
	_update_ui()

	# Get Enemies container node
	var enemies_node: Node2D = get_node_or_null("Enemies")
	if not enemies_node:
		enemies_node = Node2D.new()
		enemies_node.name = "Enemies"
		add_child(enemies_node)

	# Spawn encounter enemies
	var enemies_list: Array = encounter_data.get("enemies", [])
	var arena_width: float = 900.0  # Usable width for enemy placement
	var base_x: float = 650.0
	var ground_y: float = 400.0

	for i in range(enemies_list.size()):
		var enemy_data: Dictionary = enemies_list[i]
		var enemy_type: String = enemy_data.get("type", "slime")
		var enemy_level: int = enemy_data.get("level", 1)

		# Load the enemy script
		var script_path: String = ""
		if has_node("/root/RandomEncounterSystem"):
			script_path = RandomEncounterSystem.ENEMY_SCRIPTS.get(enemy_type, "")
		if script_path.is_empty():
			script_path = "res://scripts/combat/enemies/%s.gd" % enemy_type
		if not ResourceLoader.exists(script_path):
			push_warning("[ENCOUNTER] Enemy script not found: %s" % script_path)
			continue

		var enemy_script = load(script_path)
		if not enemy_script:
			continue

		# Position enemies spread across the arena
		var spread: float = arena_width / maxf(enemies_list.size() + 1, 2)
		var x_pos: float = base_x + spread * (i + 1) - arena_width / 2.0

		# Create the CharacterBody2D enemy node (Sprite placeholder, collision, layers)
		var enemy_node: CharacterBody2D = _build_enemy_body(
			"%s_%d" % [enemy_type.capitalize().replace(" ", ""), i],
			ENEMY_SIZES.get(enemy_type, Vector2(48, 48)),
			ENEMY_COLORS.get(enemy_type, Color(0.5, 0.5, 0.5)),
			Vector2(x_pos, ground_y))

		# Set zone_level BEFORE applying script (so _ready() uses it for scaling)
		enemy_node.set_meta("pending_zone_level", enemy_level)

		# Apply script — this triggers _ready() with all children in place
		enemy_node.set_script(enemy_script)

		# Set zone_level on the script instance
		if "zone_level" in enemy_node:
			enemy_node.zone_level = enemy_level

		# Add to scene
		enemies_node.add_child(enemy_node)

		# Connect died signal → report kill to RandomEncounterSystem
		var type_ref: String = enemy_type
		var level_ref: int = enemy_level
		if enemy_node.has_signal("died"):
			enemy_node.died.connect(_on_encounter_enemy_died.bind(type_ref, level_ref))

		_encounter_enemies.append(enemy_node)

	# Sync actual spawned count with RandomEncounterSystem (some enemies may have
	# failed to load and were skipped). Without this, _enemies_alive > actual count
	# and the encounter can never end.
	if has_node("/root/RandomEncounterSystem"):
		RandomEncounterSystem._enemies_alive = _encounter_enemies.size()
		RandomEncounterSystem._encounter_enemy_count = _encounter_enemies.size()

	# If no enemies spawned at all, end the encounter immediately
	if _encounter_enemies.is_empty():
		if has_node("/root/RandomEncounterSystem"):
			RandomEncounterSystem.end_encounter(false)
		return

	# Show brief encounter start text
	await get_tree().create_timer(0.3, false).timeout
	if not is_inside_tree():
		return
	if _has_dm() and not _encounter_enemies.is_empty():
		if _encounter_type == "ambush":
			await DialogueManager.say("System", "AMBUSH! Enemies are stronger! [%d foes — 1.5x rewards]" % _encounter_enemies.size())
		else:
			var zone_name: String = encounter_data.get("zone_id", "unknown").replace("_", " ").capitalize()
			await DialogueManager.say("System", "Enemies appear! [%d foes]" % _encounter_enemies.size())


func _on_encounter_enemy_died(enemy_type: String, enemy_level: int) -> void:
	if has_node("/root/RandomEncounterSystem"):
		RandomEncounterSystem.on_encounter_enemy_killed(enemy_type, enemy_level)


# ═════════════════════════════════════════════════════════════════════════
# BOSS FIGHT MODE
# ═════════════════════════════════════════════════════════════════════════

func _start_boss_fight(boss_id: String) -> void:
	_is_boss_fight = true
	_boss_id = boss_id
	# NOTE: Do NOT remove boss_fight_id meta here — player_combat checks it
	# to prevent fleeing. It will be cleaned up in _return_from_boss().

	# Check if already defeated
	var defeat_flag: String = BOSS_DEFEATED_FLAGS.get(boss_id, "")
	if not defeat_flag.is_empty() and GameManager.get_flag(defeat_flag):
		if _has_dm():
			await DialogueManager.say("SYSTEM", "This arena lies silent. The threat has been eliminated.")
		_return_from_boss()
		return

	# Remove tutorial slime
	if slime:
		slime.queue_free()
		slime = null

	_setup_sprites()
	_update_ui()

	# Get Enemies container
	var enemies_node: Node2D = get_node_or_null("Enemies")
	if not enemies_node:
		enemies_node = Node2D.new()
		enemies_node.name = "Enemies"
		add_child(enemies_node)

	# Load and spawn the boss
	var script_path: String = BOSS_SCRIPTS.get(boss_id, "")
	if script_path.is_empty() or not ResourceLoader.exists(script_path):
		push_error("[BOSS FIGHT] Missing boss script: %s" % script_path)
		_return_from_boss()
		return

	var boss_script = load(script_path)
	if not boss_script:
		push_error("[BOSS FIGHT] Failed to load boss script: %s" % script_path)
		_return_from_boss()
		return

	# Placeholder sprite and collision, the boss's own size and colour
	var boss_node: CharacterBody2D = _build_enemy_body(boss_id.capitalize().replace("_", ""),
		BOSS_SIZES.get(boss_id, Vector2(80, 100)), BOSS_COLORS.get(boss_id, Color(0.6, 0.2, 0.2)),
		Vector2(800, 400))

	# Apply boss script
	boss_node.set_script(boss_script)

	# Boss adds itself to "boss" group in its _ready()
	enemies_node.add_child(boss_node)
	_boss_node = boss_node

	# Apply boss checkpoint if player has prior attempts
	if _has_gm():
		var retry_frac: float = GameManager.get_boss_retry_hp_fraction(boss_id)
		if retry_frac < 1.0:
			# Defer HP reduction so boss _ready() runs first
			await get_tree().process_frame
			if is_instance_valid(boss_node) and boss_node.has_method("take_damage"):
				var max_hp: float = boss_node.get("max_health") if boss_node.get("max_health") else 0.0
				if max_hp > 0.0:
					var hp_to_remove: float = max_hp * (1.0 - retry_frac)
					boss_node.current_health = max_hp - hp_to_remove
					if boss_node.has_signal("health_changed"):
						boss_node.health_changed.emit(boss_node.current_health, max_hp)

	# Record boss initial HP for partial reward calculation
	await get_tree().process_frame
	if is_instance_valid(boss_node):
		_boss_initial_hp = boss_node.get("max_health") if boss_node.get("max_health") else 0.0
		_configure_scripted_reward_enemy(boss_node)

	# Connect died signal
	if boss_node.has_signal("died"):
		boss_node.died.connect(_on_boss_died)

	# Connect player died signal for partial boss rewards
	if is_instance_valid(player) and player.has_signal("died"):
		if not player.died.is_connected(_on_player_died_in_boss):
			player.died.connect(_on_player_died_in_boss)

	# Boss intro
	await get_tree().create_timer(0.5, false).timeout
	if not is_inside_tree():
		return
	var boss_name: String = boss_id.replace("_", " ").capitalize()
	if _has_dm():
		await DialogueManager.say("SYSTEM", "%s awakens! Prepare for combat." % boss_name)


func _on_boss_died() -> void:
	if _boss_id.is_empty():
		return

	# Set defeated flag
	var defeat_flag: String = BOSS_DEFEATED_FLAGS.get(_boss_id, "")
	if not defeat_flag.is_empty() and _has_gm():
		GameManager.set_story_flag(defeat_flag, true)

	# Clear checkpoint data — boss is done
	if _has_gm():
		GameManager.clear_boss_checkpoint(_boss_id)

	# Award full rewards (use BOSS_FULL_REWARDS for consistency)
	var rewards: Dictionary = GameManager.BOSS_FULL_REWARDS.get(_boss_id, {"xp": 200, "gold": 150}) if _has_gm() else {"xp": 200, "gold": 150}
	var xp: int = rewards.get("xp", 200)
	var gold: int = rewards.get("gold", 150)

	if _has_gm():
		GameManager.add_xp(xp)
		GameManager.add_gold(gold)

	if has_node("/root/VFXLibrary"):
		VFXLibrary.spawn_pickup_text("+%d XP" % xp, Vector2(640, 340), self, Color(0.5, 0.8, 1.0))
		await get_tree().create_timer(0.3, false).timeout
		if not is_inside_tree():
			return
		VFXLibrary.spawn_pickup_text("+%d Gold" % gold, Vector2(640, 360), self, Color(1, 0.85, 0.1))

	# Award boss-specific unique equipment drop
	_award_boss_drop(_boss_id)

	await get_tree().create_timer(1.5, false).timeout
	if not is_inside_tree():
		return

	if _has_dm():
		var boss_name: String = _boss_id.replace("_", " ").capitalize()
		await DialogueManager.say("SYSTEM", "%s has been defeated!" % boss_name)

	_return_from_boss()


func _return_from_boss() -> void:
	if not _has_gm():
		return
	GameManager.change_state(GameManager.GameState.EXPLORATION)
	# Clean up boss_fight_id meta now that the fight is over
	if GameManager.has_meta("boss_fight_id"):
		GameManager.remove_meta("boss_fight_id")

	var return_scene: String = GameManager.get_meta("boss_return_scene") if GameManager.has_meta("boss_return_scene") else ""
	if GameManager.has_meta("boss_return_scene"):
		GameManager.remove_meta("boss_return_scene")

	if return_scene.is_empty():
		return_scene = "res://scenes/overworld/overworld.tscn"

	if has_node("/root/SceneTransitions"):
		SceneTransitions.change_scene(return_scene, SceneTransitions.TransitionStyle.COMBAT_EXIT)
	else:
		get_tree().change_scene_to_file(return_scene)


func _on_player_died_in_boss() -> void:
	## Called when the player dies during a boss fight.
	## Records checkpoint progress and awards partial XP/gold.
	if _boss_id.is_empty() or not _has_gm():
		return

	# Calculate how much boss HP was removed
	var hp_pct_removed: float = 0.0
	if is_instance_valid(_boss_node) and _boss_initial_hp > 0.0:
		var current_hp: float = _boss_node.get("current_health") if _boss_node.get("current_health") != null else 0.0
		hp_pct_removed = clampf(1.0 - (current_hp / _boss_initial_hp), 0.0, 1.0)

	# Determine boss phase reached. No boss defines _current_phase; the arena
	# bosses expose `phase`, so best_phase was always 1 and the retry HP
	# mercy in GameManager.get_boss_retry_hp_fraction() could never apply.
	var phase_reached: int = 1
	if is_instance_valid(_boss_node):
		var boss_phase = _boss_node.get("_current_phase")
		if boss_phase == null:
			boss_phase = _boss_node.get("phase")
		if boss_phase != null:
			phase_reached = int(boss_phase)

	# Record checkpoint
	GameManager.record_boss_progress(_boss_id, hp_pct_removed, phase_reached)

	# Award partial rewards (up to 30% of full based on damage dealt)
	var rewards = GameManager.award_partial_boss_rewards(_boss_id, hp_pct_removed)
	if rewards.get("xp", 0) > 0 or rewards.get("gold", 0) > 0:
		if has_node("/root/VFXLibrary"):
			VFXLibrary.spawn_pickup_text(
				"Partial: +%d XP, +%d Gold" % [rewards["xp"], rewards["gold"]],
				Vector2(640, 300), self, Color(0.7, 0.7, 0.4))

	# Log for debug
	var checkpoint = GameManager.get_boss_checkpoint(_boss_id)
	if OS.is_debug_build():
		print("[BOSS CHECKPOINT] %s — attempt %d, phase %d, %.0f%% HP removed" % [
			_boss_id, checkpoint.get("attempts", 0), phase_reached, hp_pct_removed * 100.0])


## Boss-specific unique equipment drops
const BOSS_DROPS: Dictionary = {
	"clockwork_automaton": ["automaton_core_blade"],
	"data_wraith": ["wraith_thread_armor", "data_wraith_phantom_cloak"],
	"sovereign": ["sovereign_protocol", "root_access_mantle"],
}

func _award_boss_drop(boss_id: String) -> void:
	## Award guaranteed unique equipment drop from a boss.
	var drop_pool: Array = BOSS_DROPS.get(boss_id, [])
	if drop_pool.is_empty():
		return
	if not has_node("/root/Inventory"):
		return

	# Award the first item the player doesn't already have
	for item_id in drop_pool:
		if not Inventory.has_item(item_id):
			Inventory.add_item(item_id, 1)
			var item_name: String = item_id.replace("_", " ").capitalize()
			if Inventory.ITEMS.has(item_id):
				item_name = Inventory.ITEMS[item_id].get("name", item_name)
			if has_node("/root/VFXLibrary"):
				await get_tree().create_timer(0.4, false).timeout
				if not is_inside_tree():
					return
				VFXLibrary.spawn_pickup_text(
					"BOSS DROP: %s" % item_name,
					Vector2(640, 380), self, Color(1.0, 0.85, 0.2))
			if _has_dm():
				await get_tree().create_timer(0.5, false).timeout
				if not is_inside_tree():
					return
				await DialogueManager.say("System", "Obtained: %s\n%s" % [item_name, Inventory.ITEMS.get(item_id, {}).get("description", "")])
			break  # One drop per kill


# ═════════════════════════════════════════════════════════════════════════
# STORY FIGHT MODE (Y1-P0-T13)
# ═════════════════════════════════════════════════════════════════════════

## Reads and removes the story-fight metas; returns the fight id, or "" for none, an unknown id or a
## row that fails validate_story_fight (one warning per problem; the arena runs its default mode).
func _consume_story_fight_metas() -> String:
	if not _has_gm():
		return ""
	var id: String = str(GameManager.get_meta("story_fight_id", ""))
	_story_return_scene = str(GameManager.get_meta("story_fight_return_scene", ""))
	for key in ["story_fight_id", "story_fight_return_scene"]:
		if GameManager.has_meta(key):
			GameManager.remove_meta(key)
	if id.is_empty():
		return ""
	if not story_fight_table.has(id) or not (story_fight_table[id] is Dictionary):
		push_warning("[STORY FIGHT] Unknown story fight id '%s'; running the default mode" % id)
		return ""
	var problems := validate_story_fight(story_fight_table[id])
	for problem in problems:
		push_warning("[STORY FIGHT] Story fight '%s' refused, running the default mode: %s" % [id, problem])
	return id if problems.is_empty() else ""


## Checks a story-fight row before its fight starts, so a bad row fails at the start, not mid-fight.
## Returns one message per problem, each naming its key: a required key missing or of the wrong type,
## an optional key of the wrong type, an unknown key, an enemy_script that is not a Script or does not extend
## EnemyBase, a flag that is not a non-empty String, a non-empty backdrop missing, mistyping or adding a key,
## a tree that is not [x, width, height] numbers. Empty: the row is good. Static, so a row can be checked
## without an arena.
static func validate_story_fight(row: Dictionary) -> PackedStringArray:
	var problems := PackedStringArray()
	problems.append_array(_validate_story_required(row))
	problems.append_array(_validate_story_optional(row))
	problems.append_array(_validate_story_unknown(row))
	problems.append_array(_validate_story_script(row))
	problems.append_array(_validate_story_flags(row))
	problems.append_array(_validate_story_enemy_look(row))
	if typeof(row.get("backdrop")) == TYPE_DICTIONARY:
		problems.append_array(_validate_story_backdrop(row["backdrop"]))
	return problems


## Every STORY_FIGHT_REQUIRED key is present with its type.
static func _validate_story_required(row: Dictionary) -> PackedStringArray:
	var problems := PackedStringArray()
	for key in STORY_FIGHT_REQUIRED:
		if not row.has(key):
			problems.append("missing required key '%s'" % key)
		elif typeof(row[key]) != STORY_FIGHT_REQUIRED[key]:
			problems.append(_story_type_message(key, row[key], type_string(STORY_FIGHT_REQUIRED[key])))
	return problems


## Every optional key the row gives has its default's type (a number key: int or float).
static func _validate_story_optional(row: Dictionary) -> PackedStringArray:
	var problems := PackedStringArray()
	for key in STORY_FIGHT_DEFAULTS:
		var default_value: Variant = STORY_FIGHT_DEFAULTS[key]
		if not row.has(key):
			continue
		if _story_is_number(default_value) and not _story_is_number(row[key]):
			problems.append(_story_type_message(key, row[key], "int or float"))
		elif not _story_is_number(default_value) and typeof(row[key]) != typeof(default_value):
			problems.append(_story_type_message(key, row[key], type_string(typeof(default_value))))
	return problems


## Every key is a required or an optional one, with or without a default (the old flat backdrop keys are unknown).
static func _validate_story_unknown(row: Dictionary) -> PackedStringArray:
	var problems := PackedStringArray()
	for key in row:
		if not STORY_FIGHT_REQUIRED.has(key) and not STORY_FIGHT_DEFAULTS.has(key) and not STORY_FIGHT_OPTIONAL.has(key):
			problems.append("unknown key '%s'" % key)
	return problems


## enemy_size and enemy_color: the row's value has its type, or, left out, the enemy_type has an entry in
## STORY_ENEMY_LOOK_TABLES, so no fight falls back to a grey 48 x 48 body. A missing or non-String enemy_type
## is _validate_story_required's message.
static func _validate_story_enemy_look(row: Dictionary) -> PackedStringArray:
	var problems := PackedStringArray()
	var enemy_type: Variant = row.get("enemy_type")
	for key in STORY_FIGHT_OPTIONAL:
		if row.has(key) and typeof(row[key]) != STORY_FIGHT_OPTIONAL[key]:
			problems.append(_story_type_message(key, row[key], type_string(STORY_FIGHT_OPTIONAL[key])))
		elif not row.has(key) and typeof(enemy_type) == TYPE_STRING and not STORY_ENEMY_LOOK_TABLES[key].has(enemy_type):
			problems.append("missing key '%s': enemy_type '%s' has no entry to fall back to" % [key, enemy_type])
	return problems


## enemy_script loads as a Script (a scene or any other resource is refused) that extends EnemyBase, directly or
## through a parent script (the fight needs EnemyBase's `died` signal, loot_table and State). The path is loaded
## once. A missing or non-String enemy_script is _validate_story_required's message. (Y1-P0 TD-038)
static func _validate_story_script(row: Dictionary) -> PackedStringArray:
	var path: Variant = row.get("enemy_script")
	if typeof(path) != TYPE_STRING:
		return PackedStringArray()
	if not ResourceLoader.exists(path):
		return PackedStringArray(["key 'enemy_script': no script at '%s'" % path])
	var resource: Resource = load(path)
	return _validate_story_script_class(path, resource)


## The loaded enemy_script resource is a Script and extends EnemyBase: one message when it does not. Split from
## _validate_story_script to keep each function to three branch points. (Y1-P0 TD-038)
static func _validate_story_script_class(path: String, resource: Resource) -> PackedStringArray:
	if not (resource is Script):
		return PackedStringArray(["key 'enemy_script': '%s' is not a Script" % path])
	if not _story_script_extends_enemy_base(resource):
		return PackedStringArray([("key 'enemy_script': '%s' does not extend EnemyBase" % path)
			+ " (or failed to compile; see Godot's error above)"])
	return PackedStringArray()


## True when `script` is EnemyBase's script or inherits from it through its chain of parent scripts. The walk
## compares scripts, not file names; a script that merely extends a node class (or the arena script) is false.
static func _story_script_extends_enemy_base(script: Script) -> bool:
	var current: Script = script
	while current != null:
		if current == EnemyBase:
			return true
		current = current.get_base_script()
	return false


## Every flag is a non-empty String (GameManager.set_story_flag takes a String name).
static func _validate_story_flags(row: Dictionary) -> PackedStringArray:
	var problems := PackedStringArray()
	var flags: Variant = row.get("flags")
	if typeof(flags) != TYPE_ARRAY:
		return problems
	for i in flags.size():
		if typeof(flags[i]) != TYPE_STRING or flags[i].is_empty():
			problems.append("key 'flags[%d]' must be a non-empty String, not %s" % [i, var_to_str(flags[i])])
	return problems


## A non-empty backdrop needs every STORY_BACKDROP_REQUIRED key with its type; `path` is optional.
static func _validate_story_backdrop(backdrop: Dictionary) -> PackedStringArray:
	var problems := PackedStringArray()
	if backdrop.is_empty():
		return problems
	for key in STORY_BACKDROP_REQUIRED:
		if not backdrop.has(key):
			problems.append("key 'backdrop' is missing '%s'" % key)
	for key in backdrop:
		var wanted: int = STORY_BACKDROP_REQUIRED.get(key, TYPE_COLOR if key == "path" else TYPE_NIL)
		if wanted == TYPE_NIL:
			problems.append("key 'backdrop' has an unknown key '%s'" % key)
		elif typeof(backdrop[key]) != wanted:
			problems.append(_story_type_message("backdrop." + str(key), backdrop[key], type_string(wanted)))
	if typeof(backdrop.get("trees")) == TYPE_ARRAY:
		problems.append_array(_validate_story_trees(backdrop["trees"]))
	return problems


## Every tree is an Array of exactly 3 numbers: [x, width, height].
static func _validate_story_trees(trees: Array) -> PackedStringArray:
	var problems := PackedStringArray()
	for i in trees.size():
		var t: Variant = trees[i]
		if typeof(t) != TYPE_ARRAY or t.size() != 3 or not t.all(func(v): return _story_is_number(v)):
			problems.append("key 'backdrop.trees[%d]' must be [x, width, height] numbers, not %s" % [i, var_to_str(t)])
	return problems


static func _story_is_number(value: Variant) -> bool:
	return typeof(value) in [TYPE_INT, TYPE_FLOAT]


static func _story_type_message(key: String, value: Variant, wanted: String) -> String:
	return "key '%s' must be %s, not %s" % [key, wanted, type_string(typeof(value))]


func _start_story_fight(id: String) -> void:
	# The row wins over the defaults (the merge keeps the row's value where both have the key).
	var row: Dictionary = story_fight_table[id]
	_story_cfg = row.merged(STORY_FIGHT_DEFAULTS)
	# The scene's own TutorialSlime has no place in a story fight.
	if slime:
		slime.queue_free()
		slime = null
	_apply_story_backdrop()
	_setup_sprites()
	_update_ui()
	player.position = _story_cfg["player_spawn"]
	# The player's death is a tutorial retry, not the normal death path (PlayerCombat.die()
	# stops after its animation when this is set; the arena restores the player below).
	player.set_meta("local_boss_retry_enabled", true)
	player.died.connect(_on_story_player_died)
	_spawn_story_enemy()
	_build_story_controls_label()


## The row's procedural backdrop (no art import): the sky and ground recoloured and stretched past the
## arena, its trees, and the path if it has one. An empty backdrop leaves the scene as it is.
func _apply_story_backdrop() -> void:
	var data: Dictionary = _story_cfg["backdrop"]
	if data.is_empty():
		return
	var margin: Vector2 = data["margin"]
	var background := get_node_or_null("Background") as ColorRect
	if background:
		background.color = data["sky"]
		background.position = -margin
		background.size = Vector2(ARENA_WIDTH, 720.0) + margin * 2.0
	var ground_sprite := get_node_or_null("Ground/GroundSprite") as ColorRect
	if ground_sprite:
		ground_sprite.color = data["ground"]
		ground_sprite.position = Vector2(-margin.x, 0.0)
		ground_sprite.size = Vector2(ARENA_WIDTH + margin.x * 2.0, 120.0 + margin.y)
	var backdrop := _build_story_trees(data)
	add_child(backdrop)
	# Behind the ground and everything else, in front of the sky.
	var ground := get_node_or_null("Ground")
	move_child(backdrop, ground.get_index() if ground else 1)
	if ground and data.has("path"):
		# The path lies on the ground, so it is the ground's last child: drawn after the ground's rect.
		var path := ColorRect.new()
		path.name = "StoryFightPath"
		path.color = data["path"]
		path.position = Vector2(-margin.x, 0.0)
		path.size = Vector2(ARENA_WIDTH + margin.x * 2.0, 22)
		path.mouse_filter = Control.MOUSE_FILTER_IGNORE
		ground.add_child(path)


## The backdrop's trees: a trunk standing on y 600 and a canopy over it per `[x, width, height]`.
func _build_story_trees(data: Dictionary) -> Node2D:
	var backdrop := Node2D.new()
	backdrop.name = "StoryFightBackdrop"
	var tree_color: Color = data["tree"]
	for t in data["trees"]:
		var x := float(t[0])
		var w := float(t[1])
		var h := float(t[2])
		var trunk := ColorRect.new()
		trunk.name = "StoryFightTrunk"
		trunk.color = tree_color
		trunk.size = Vector2(w, h)
		trunk.position = Vector2(x, 600.0 - h)
		trunk.mouse_filter = Control.MOUSE_FILTER_IGNORE
		backdrop.add_child(trunk)
		var canopy := ColorRect.new()
		canopy.name = "StoryFightCanopy"
		canopy.color = Color(tree_color.r + 0.02, tree_color.g + 0.03, tree_color.b + 0.01, 0.9)
		canopy.size = Vector2(w * 3.0, w * 2.5)
		canopy.position = Vector2(x - w, 600.0 - h - w * 1.5)
		canopy.mouse_filter = Control.MOUSE_FILTER_IGNORE
		backdrop.add_child(canopy)
	return backdrop


## One non-blocking controls line (not a DialogueManager line); InputService re-renders it
## whenever the input device or the bindings change, so pad glyphs show after pad input.
func _build_story_controls_label() -> void:
	var ui := get_node_or_null("UI")
	if ui == null:
		return
	var label := Label.new()
	label.name = "StoryFightControls"
	label.position = Vector2(0, 612)   # above the HUD's action buttons (y 650-708)
	label.size = Vector2(ARENA_WIDTH, 28)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_color_override("font_color", Color(0.92, 0.92, 0.85))
	label.add_theme_color_override("font_outline_color", Color(0, 0, 0))
	label.add_theme_constant_override("outline_size", 4)
	ui.add_child(label)
	InputService.bind_text(label, _story_cfg["controls"])


## Builds the fight's enemy (a fresh instance each time: the slime has no reset, and a pounce
## already in flight cannot be cancelled from outside) and wires its death.
func _spawn_story_enemy() -> void:
	var enemy_script = load(_story_cfg["enemy_script"])
	var enemies_node: Node2D = get_node_or_null("Enemies")
	if enemies_node == null:
		enemies_node = Node2D.new()
		enemies_node.name = "Enemies"
		add_child(enemies_node)
	var enemy_type: String = _story_cfg["enemy_type"]
	# The row's own look, else the enemy_type's entry (validate_story_fight refused a row with neither).
	var size: Vector2 = _story_cfg["enemy_size"] if _story_cfg.has("enemy_size") else ENEMY_SIZES[enemy_type]
	var color: Color = _story_cfg["enemy_color"] if _story_cfg.has("enemy_color") else ENEMY_COLORS[enemy_type]
	var enemy := _build_enemy_body(_story_cfg["enemy_name"], size, color, _story_cfg["enemy_spawn"])
	enemy.set_script(enemy_script)
	enemies_node.add_child(enemy)
	_configure_scripted_reward_enemy(enemy)
	# No item drops either: EnemyBase._ready regenerates a default loot table when it is
	# null, so the table is cleared after add_child (a story fight gives flags only).
	enemy.set("loot_table", null)
	enemy.died.connect(_on_story_enemy_died)
	_story_enemy = enemy


func _on_story_enemy_died() -> void:
	if _story_resolved:
		return
	# The player died first (a hit already in flight, the kill zone): the retry wins, so 0 HP
	# never leaves the arena. The slime frees itself; the retry spawns a fresh one.
	if is_instance_valid(player) and player.is_dead:
		return
	_story_resolved = true
	if is_instance_valid(player):
		player.invulnerable = true
		player.invuln_timer = 1.0e9
	# An enemy already freed (it frees itself 0.6 s after dying) leaves the shards at its spawn.
	var origin: Vector2 = _story_cfg["enemy_spawn"]
	if is_instance_valid(_story_enemy):
		origin = _story_enemy.global_position
	_spawn_story_shards(origin)
	if _has_gm():
		for flag in _story_cfg["flags"]:
			GameManager.set_story_flag(flag, true)
	# Pause-aware (process_always false) but in real time, like the shards' tween.
	await get_tree().create_timer(float(_story_cfg["shard_fade"]), false, false, true).timeout
	if not is_inside_tree():
		return
	story_fight_resolved.emit("win")
	_leave_story_fight()


## The row's polygon beat: the defeated enemy breaks into shard_count shards of shard_color, not blood.
func _spawn_story_shards(origin: Vector2) -> void:
	var fade: float = _story_cfg["shard_fade"]
	var side: float = _story_cfg["shard_size"]
	for i in int(_story_cfg["shard_count"]):
		var shard := ColorRect.new()
		shard.name = "StoryFightShard%d" % i   # unique: Godot renames duplicate sibling names
		shard.color = _story_cfg["shard_color"]
		shard.size = Vector2(side, side)
		shard.rotation = randf() * TAU
		shard.position = origin + Vector2(-side * 0.5, -22)
		shard.z_index = int(_story_cfg["shard_z"])
		shard.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(shard)
		var t := create_tween().set_parallel(true).set_ignore_time_scale(true)
		t.tween_property(shard, "position", shard.position + Vector2(randf_range(-60, 60), randf_range(-50, 10)), fade)
		t.tween_property(shard, "modulate:a", 0.0, fade)
		t.chain().tween_callback(shard.queue_free)


func _leave_story_fight() -> void:
	var scene: String = _story_return_scene
	if scene.is_empty():
		scene = _story_cfg["default_return_scene"]
	# The kill and the death slow-mo leave time-scale requests behind; the next scene starts clean.
	ContextStack.clear_time_scale()
	if has_node("/root/SceneTransitions"):
		SceneTransitions.change_scene(scene, SceneTransitions.TransitionStyle.COMBAT_EXIT)
	else:
		get_tree().change_scene_to_file(scene)


func _on_story_player_died() -> void:
	# create_timer(..., false) is pause-aware: nothing here advances while the game is paused.
	await get_tree().create_timer(STORY_RETRY_DELAY, false).timeout
	if not is_inside_tree() or _story_resolved:
		return
	_story_retry()


## Tutorial retry: the old enemy is disabled and hidden at once (state DEAD, so any timer of its
## own returns on its next resume) and freed later; a fresh enemy is spawned; the player is
## restored at the spawn with full HP. No corruption, no player_died flag, no game over.
func _story_retry() -> void:
	story_fight_retries += 1
	var old: EnemyBase = _story_enemy
	if is_instance_valid(old):
		if old.died.is_connected(_on_story_enemy_died):
			old.died.disconnect(_on_story_enemy_died)
		old.current_state = EnemyBase.State.DEAD
		old.set_physics_process(false)
		old.set_process(false)
		old.collision_layer = 0
		old.collision_mask = 0
		old.visible = false
		old.remove_from_group("enemies")
		old.name = "%s_old" % old.name
		var free_old := get_tree().create_timer(STORY_OLD_ENEMY_LIFETIME, false)
		free_old.timeout.connect(func():
			if is_instance_valid(old):
				old.queue_free()
		)
	_spawn_story_enemy()
	player.force_restore_after_death_retry(_story_cfg["player_spawn"])
	_update_ui()


# ═════════════════════════════════════════════════════════════════════════
# SCENE VALIDATION
# ═════════════════════════════════════════════════════════════════════════

func _validate_scene() -> void:
	var warnings: PackedStringArray = []
	if not slime:
		warnings.append("'Enemies/TutorialSlime' not found")
	elif not slime is CharacterBody2D:
		warnings.append("Enemy should be CharacterBody2D, is: " + slime.get_class())
	if not get_viewport().get_camera_2d():
		warnings.append("No Camera2D — screen shake won't work")
	if not root_access_panel:
		warnings.append("RootAccessPanel node not found")
	for w in warnings:
		push_warning("[COMBAT ARENA] %s — see SCENE_SETUP_GUIDE.md" % w)


# ═════════════════════════════════════════════════════════════════════════
# SPRITES
# ═════════════════════════════════════════════════════════════════════════

func _setup_sprites() -> void:
	if not _has_am():
		return
	if player:
		AssetManager.replace_player_sprite(player, "combat")
	if slime and slime.has_node("Sprite"):
		var old = slime.get_node("Sprite")
		if AssetManager.is_asset_available("slime_green"):
			var spr = Sprite2D.new()
			spr.texture = AssetManager.get_sprite("slime_green")
			spr.name = "Sprite"
			spr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			var ts = spr.texture.get_size()
			if ts.x > 0 and ts.y > 0:
				var u = 96.0 / maxf(ts.x, ts.y)
				spr.scale = Vector2(u, u)
				spr.offset = Vector2(0, -ts.y / 2.0)
			var par = old.get_parent()
			var idx = old.get_index()
			par.remove_child(old)
			old.queue_free()
			par.add_child(spr)
			par.move_child(spr, idx)
		elif old is ColorRect:
			old.color = AssetManager.get_placeholder_color("slime_green")


# ═════════════════════════════════════════════════════════════════════════
# COMBAT TUTORIAL
# ═════════════════════════════════════════════════════════════════════════

func _show_combat_tutorial() -> void:
	if _has_dm():
		await DialogueManager.say("System", InputService.fmt(
			"{move} — Move | {jump} — Jump | {attack} — Attack\n{root_access} — Root Access (Hack) | {perfect_delete} — Perfect Delete (3 uses)"))
		if not is_inside_tree():
			return


# ═════════════════════════════════════════════════════════════════════════
# INPUT
# ═════════════════════════════════════════════════════════════════════════

func _input(event: InputEvent) -> void:
	# A story fight refuses Root Access and Perfect Delete (the story unlocks Root Access later).
	if not _story_id.is_empty():
		if event.is_action_pressed("root_access") or event.is_action_pressed("perfect_delete"):
			get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed("root_access") and not root_access_active:
		_open_root_access()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("perfect_delete"):
		_use_perfect_delete()
		get_viewport().set_input_as_handled()


# ═════════════════════════════════════════════════════════════════════════
# ROOT ACCESS
# ═════════════════════════════════════════════════════════════════════════

func _open_root_access() -> void:
	if not _story_id.is_empty():
		return
	# Select target based on mode
	var target_enemy: EnemyBase = null
	if _is_boss_fight:
		target_enemy = _boss_node
	elif _is_random_encounter:
		var closest_dist: float = INF
		for e in _encounter_enemies:
			if is_instance_valid(e) and e.get("current_state") != null and e.current_state != EnemyBase.State.DEAD:
				var dist = e.global_position.distance_to(player.global_position) if player else INF
				if dist < closest_dist:
					closest_dist = dist
					target_enemy = e
	else:
		target_enemy = slime

	if not is_instance_valid(target_enemy):
		return
	if not target_enemy.has_method("get_hackable_properties"):
		return

	# Pauses the game; refused while another menu is open. Owned by the arena,
	# so a scene change with the panel open can't leave the game paused.
	if not ContextStack.push(&"root_access", self):
		return
	root_access_active = true
	selected_enemy = target_enemy
	root_access_panel.visible = true
	# The panel is PROCESS_MODE_ALWAYS (set in combat_arena.tscn) so its buttons
	# still receive input while the tree is paused. Give Cancel keyboard focus so
	# there is always a reachable way out even without the mouse.
	var cancel_btn: Button = root_access_panel.get_node_or_null(
		"MarginContainer/VBox/ButtonRow/CancelButton")
	if cancel_btn:
		cancel_btn.grab_focus()

	var el: SpinBox = root_access_panel.get_node_or_null("MarginContainer/VBox/PropertyList/ElasticityRow/SpinBox")
	var gv: SpinBox = root_access_panel.get_node_or_null("MarginContainer/VBox/PropertyList/GravityRow/SpinBox")
	var sp: SpinBox = root_access_panel.get_node_or_null("MarginContainer/VBox/PropertyList/SpeedRow/SpinBox")
	var ho: CheckBox = root_access_panel.get_node_or_null("MarginContainer/VBox/PropertyList/HostileRow/CheckBox")

	if not el or not gv or not sp or not ho:
		push_error("[ROOT ACCESS] UI structure mismatch — check combat_arena.tscn")
		_close_root_access()
		return

	# The SpinBoxes had no ranges set (default 0-100), so gravity 0 was allowed;
	# match the limits EnemyBase.apply_hack() enforces.
	gv.min_value = EnemyBase.HACK_GRAVITY_RANGE.x
	gv.max_value = EnemyBase.HACK_GRAVITY_RANGE.y
	gv.step = 0.1
	sp.min_value = EnemyBase.HACK_SPEED_RANGE.x
	sp.max_value = EnemyBase.HACK_SPEED_RANGE.y
	el.value = selected_enemy.elasticity
	gv.value = selected_enemy.gravity_scale
	sp.value = selected_enemy.movement_speed
	ho.button_pressed = selected_enemy.is_hostile


func _on_root_access_apply() -> void:
	if not selected_enemy:
		return

	var el: SpinBox = root_access_panel.get_node_or_null("MarginContainer/VBox/PropertyList/ElasticityRow/SpinBox")
	var gv: SpinBox = root_access_panel.get_node_or_null("MarginContainer/VBox/PropertyList/GravityRow/SpinBox")
	var sp: SpinBox = root_access_panel.get_node_or_null("MarginContainer/VBox/PropertyList/SpeedRow/SpinBox")
	var ho: CheckBox = root_access_panel.get_node_or_null("MarginContainer/VBox/PropertyList/HostileRow/CheckBox")

	if not el or not gv or not sp or not ho:
		_close_root_access()
		return

	selected_enemy.apply_hack("elasticity", clampf(el.value, -2.0, 5.0))
	selected_enemy.apply_hack("gravity_scale", gv.value)  # clamped by EnemyBase
	selected_enemy.apply_hack("movement_speed", sp.value)  # clamped by EnemyBase
	selected_enemy.apply_hack("is_hostile", ho.button_pressed)

	if _has_gm():
		GameManager.add_glitch_corruption(1.0)

	_close_root_access()


func _on_root_access_cancel() -> void:
	_close_root_access()


func _close_root_access() -> void:
	root_access_active = false
	root_access_panel.visible = false
	ContextStack.pop(&"root_access")


# ═════════════════════════════════════════════════════════════════════════
# PERFECT DELETE
# ═════════════════════════════════════════════════════════════════════════

func _use_perfect_delete() -> void:
	if not _has_gm() or not _story_id.is_empty():
		return

	# A second press during the 0.6 s dissolve spent another charge on the same
	# target (and in encounters reported its kill twice).
	if _perfect_delete_busy:
		return

	if GameManager.perfect_delete_charges <= 0:
		_status_text("NO CHARGES!", Vector2(640, 300))
		return

	# Find target based on mode
	var target: EnemyBase = null
	if _is_boss_fight:
		# Nothing below removes a boss (only the slime or an encounter enemy), so
		# this used to spend a charge for no effect. Bosses can't be deleted.
		_status_text("BOSS IMMUNE!", Vector2(640, 300))
		return
	elif _is_random_encounter:
		var closest_dist: float = INF
		for e in _encounter_enemies:
			if is_instance_valid(e) and e.get("current_state") != null and e.current_state != EnemyBase.State.DEAD:
				var dist = e.global_position.distance_to(player.global_position) if player else INF
				if dist < closest_dist:
					closest_dist = dist
					target = e
	else:
		target = slime

	if not is_instance_valid(target):
		_status_text("NO TARGET", Vector2(640, 300))
		return

	if GameManager.use_perfect_delete():
		_perfect_delete_busy = true
		if has_node("/root/VFXLibrary"):
			VFXLibrary.spawn("vfx_perfect_delete", target.global_position, self)
			VFXLibrary.spawn("vfx_data_dissolve", target.global_position, self)
		if has_node("/root/CombatFX"):
			CombatFX.apply_screen_shake(30.0, 0.5)
			CombatFX.apply_hitstop(0.3)
		# TweenAnimator is a static class, not an autoload: the old
		# has_node("/root/TweenAnimator") guard was always false.
		var die_target: CanvasItem = target.get_node("Sprite") if target.has_node("Sprite") else target
		TweenAnimator.play_die(die_target)

		await get_tree().create_timer(0.6, false).timeout
		_perfect_delete_busy = false
		if not is_inside_tree():
			return

		# Handle death: in encounter mode, trigger the died signal so
		# RandomEncounterSystem tracks the kill (unless it already died on its
		# own during the wait, which reported the kill already)
		if _is_random_encounter:
			if is_instance_valid(target) and target.has_signal("died") and target.current_state != EnemyBase.State.DEAD:
				if target.has_method("_award_death_rewards"):
					target._award_death_rewards()  # Ensure XP/gold/loot before freeing
				target.died.emit()
			if is_instance_valid(target):
				target.queue_free()
		else:
			if is_instance_valid(slime):
				slime.queue_free()
			slime = null

		await get_tree().create_timer(0.5, false).timeout
		if not is_inside_tree():
			return
		_victory()
	else:
		_status_text("NO CHARGES!", Vector2(640, 300))


# ═════════════════════════════════════════════════════════════════════════
# EVENTS
# ═════════════════════════════════════════════════════════════════════════

func _on_slime_died() -> void:
	tutorial_complete = true
	await get_tree().create_timer(0.5, false).timeout
	if not is_inside_tree():
		return
	_victory()


func _on_enemy_health_changed(new_hp: float, max_hp: float) -> void:
	if is_instance_valid(slime) and slime.has_node("HealthBar"):
		var hb = slime.get_node("HealthBar") as ProgressBar
		if hb and max_hp > 0:
			hb.value = (new_hp / max_hp) * 100.0


func _on_glitch_meter_changed(_value: float) -> void:
	_update_ui()


# ═════════════════════════════════════════════════════════════════════════
# VICTORY
# ═════════════════════════════════════════════════════════════════════════

func _victory() -> void:
	# In random encounter mode, RandomEncounterSystem handles victory/return
	if _is_random_encounter:
		return
	# In boss fight mode, _on_boss_died handles victory/return
	if _is_boss_fight:
		return

	# ── Tutorial mode victory ──
	if _has_gm():
		GameManager.set_story_flag("tutorial_completed", true)
		GameManager.set_story_flag("first_slime_defeated", true)
		GameManager.add_xp(50)
		GameManager.add_gold(10)

	if has_node("/root/VFXLibrary"):
		VFXLibrary.spawn_pickup_text("+50 XP", Vector2(640, 340), self, Color(0.5, 0.8, 1.0))
		await get_tree().create_timer(0.3, false).timeout
		if not is_inside_tree():
			return
		VFXLibrary.spawn_pickup_text("+10 Gold", Vector2(640, 360), self, Color(1, 0.85, 0.1))

	await get_tree().create_timer(1.0, false).timeout
	if not is_inside_tree():
		return
	if has_node("/root/SceneTransitions"):
		SceneTransitions.change_scene(
			"res://scenes/regions/oakhaven_region.tscn",
			SceneTransitions.TransitionStyle.COMBAT_EXIT)


# ═════════════════════════════════════════════════════════════════════════
# UI
# ═════════════════════════════════════════════════════════════════════════

func _update_ui() -> void:
	if not _has_gm():
		return
	var hp: float = GameManager.player_stats.get("hp", 100)
	var max_hp: float = GameManager.player_stats.get("max_hp", 100)
	if player_hp_bar:
		player_hp_bar.value = (hp / maxf(max_hp, 1.0)) * 100.0
	if player_hp_label:
		player_hp_label.text = "HP: %d/%d" % [int(hp), int(max_hp)]
	if glitch_meter_bar:
		glitch_meter_bar.value = GameManager.glitch_meter
	if glitch_label:
		glitch_label.text = "Glitch: %d%%" % int(GameManager.glitch_meter)


# ═════════════════════════════════════════════════════════════════════════
# GUARDS
# ═════════════════════════════════════════════════════════════════════════

func _has_gm() -> bool:
	return has_node("/root/GameManager")

func _has_dm() -> bool:
	return has_node("/root/DialogueManager")

func _configure_scripted_reward_enemy(enemy: Node) -> void:
	## Scripted fights award XP/gold in their scene controller, not in EnemyBase.
	if not is_instance_valid(enemy):
		return
	enemy.set_meta("suppress_base_rewards", true)
	var table = enemy.get("loot_table")
	if table:
		table.gold_min = 0
		table.gold_max = 0
		table.xp_min = 0
		table.xp_max = 0

func _has_am() -> bool:
	return has_node("/root/AssetManager")

func _status_text(text: String, pos: Vector2) -> void:
	if has_node("/root/VFXLibrary"):
		VFXLibrary.spawn_status_indicator(text, pos, self, false)
