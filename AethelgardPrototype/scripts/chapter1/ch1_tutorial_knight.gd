extends Node2D

## ==========================================================================
## Chapter 1 — Tutorial Knight Arena (Dynamic Combat)
## ==========================================================================
## Replaces the old QTE-based boss fight with a free-movement Hollow Knight-
## style arena.  The player has full control: move, jump, dash, attack, parry,
## cast spells, heal.  The boss (TutorialKnightBoss) runs its own multi-phase
## AI from EnemyBase.
##
## Arena is a single 1280×720 room built programmatically:
##   • Floor, walls, ceiling (StaticBody2D + CollisionShape2D)
##   • Three platforms for vertical play
##   • Player spawns left, Boss spawns right
##   • Static Camera2D centred on the arena
## ==========================================================================

# ─── ARENA CONSTANTS ─────────────────────────────────────────────────────
const ARENA_WIDTH = 1280.0
const ARENA_HEIGHT = 720.0
const FLOOR_Y = 590.0
const WALL_THICKNESS = 32.0
const PLATFORM_HEIGHT = 16.0

const PLAYER_SPAWN = Vector2(200, 540)
const BOSS_SPAWN = Vector2(1050, 480)
const ARENA_HAZARD_BASE_DAMAGE = 10.0
const ARENA_HAZARD_INTERVAL = 0.75
const PLATFORM_ONE_WAY_MARGIN = 4.0

# ─── NODE REFERENCES (built in code) ────────────────────────────────────
var player: CharacterBody2D = null
var boss: CharacterBody2D = null
var camera: Camera2D = null
var boss_hp_bar: ProgressBar = null
var boss_hp_label: Label = null
var boss_name_label: Label = null
var root_access_panel: PanelContainer = null
var ui_layer: CanvasLayer = null
var dialogue_box: PanelContainer = null
var dialogue_label: RichTextLabel = null

# ─── STATE ───────────────────────────────────────────────────────────────
var combat_started: bool = false
var combat_ended: bool = false
var _dialogue_queue: Array[Dictionary] = []
var _dialogue_active: bool = false
var _current_dialogue_timer: float = 0.0
var _transition_timer: float = -1.0
var _arena_hazard_visuals: Array[ColorRect] = []
var _arena_hazard_players: Array[Node] = []
var _arena_hazard_damage: float = ARENA_HAZARD_BASE_DAMAGE
var _arena_hazard_cooldown: float = 0.0
var _arena_hazard_enabled: bool = true
var _arena_hazard_active: bool = false
var _arena_hazard_cycle_timer: float = 0.0
var _arena_hazard_cycle_length: float = 3.2
var _arena_hazard_active_window: float = 0.9
var _retry_in_progress: bool = false
var _root_access_completing: bool = false

# ─── COMBAT TUTORIAL STATE ──────────────────────────────────────────────
var _tutorial_active: bool = true
var _tutorial_step: int = 0
var _tutorial_timer: float = 0.0
var _tutorial_delay: float = 2.0  # Time between tutorial prompts
var _tutorial_prompt_label: Label = null
var _tutorial_completed_actions: Dictionary = {}
var _tutorial_prompt_visible_timer: float = 0.0

## Prompts and hints use {action} tokens (InputService.fmt) so they name the
## player's actual keys or buttons.
const TUTORIAL_STEPS: Array = [
	{"action": "move", "prompt": "[{move_lr}] Move left and right", "check": "moved", "hint": "Hold a direction to move Kaelen."},
	{"action": "jump", "prompt": "[{jump}] Jump!  Hold for higher jumps", "check": "jumped", "hint": "Tap {jump} to jump. Hold {jump} longer to jump higher."},
	{"action": "attack", "prompt": "[{attack}] Attack!  Chain 3 hits for a combo", "check": "attacked", "hint": "Press {attack} repeatedly to chain a 3-hit combo."},
	{"action": "dash", "prompt": "[{sprint}] Dash through attacks — you have i-frames!", "check": "dashed", "hint": "Dash gives invincibility frames. Use it to dodge through attacks."},
	{"action": "parry", "prompt": "[{defend}] Parry just before an attack hits — counter window!", "check": "parried", "hint": "Time your parry right before impact. Success opens a counter window."},
	{"action": "pogo", "prompt": "[{move_down}]+[{attack}] in air — Pogo Strike! Bounce off enemies", "check": "pogoed", "hint": "While airborne, hold DOWN + ATTACK to pogo bounce. Resets dash!"},
	{"action": "spell", "prompt": "[{spell}] Vengeful Spirit  |  [{move_down}]+[{spell}] Desolate Dive  |  [{move_up}]+[{spell}] Howling Wraiths", "check": "spelled", "hint": "Spells cost 15 MP. MP refills slowly over time and with potions."},
	{"action": "heal", "prompt": "[{heal}] Focus Heal when safe — costs 20 MP", "check": "healed", "hint": "Hold {heal} to channel a heal. Find a safe moment — you're vulnerable while healing."},
]

const HUD_TUTORIAL_TEXT: String = "HUD Guide:\n[color=#ff4444]Red Bar[/color] = HP  |  [color=#33bbff]Cyan Bar[/color] = MP  |  [color=#4488ff]Blue Bar[/color] = Soul  |  [color=#aa44ff]Purple %%[/color] = Corruption\nMP pays for spells [{spell}] and healing [{heal}]. Earn Soul with parries, perfect dodges and kills."
var _hud_tutorial_shown: bool = false
var _tutorial_skip_requested: bool = false

# ─── DIALOGUE (dialogue/ch1/) ───────────────────────────────────────────
const ALDRIC_DLG := "res://dialogue/ch1/aldric.dlg"
const FRAGMENT_DLG := "res://dialogue/ch1/fragment_one.dlg"
const NORTH_FIELD_DLG := "res://dialogue/ch1/north_field.dlg"
var _card_layer: CanvasLayer = null

# ======================================================================
#  READY — Build the entire arena
# ======================================================================
func _ready() -> void:
	# Background
	_build_background()
	# Physics arena
	_build_arena_colliders()
	# Platforms
	_build_platforms()
	# Arena pressure for the combat vertical slice
	_build_arena_pressure()
	# Spawn entities
	_spawn_player()
	_spawn_boss()
	# Camera
	_build_camera()
	# UI
	_build_ui()
	# Root Access panel (hidden until Phase 4)
	_build_root_access_panel()
	# Start intro sequence
	_start_intro()

# ======================================================================
#  PROCESS
# ======================================================================
func _process(delta) -> void:
	_update_dialogue(delta)
	_update_boss_hp_bar()
	_update_combat_tutorial(delta)
	_update_arena_pressure(delta)

	# Scene transition countdown (one-shot — disable timer before calling change_scene)
	# BUG-21-17: Guard timer so it won't fire mid-dialogue
	if _transition_timer >= 0.0 and not _dialogue_active:
		_transition_timer -= delta
		if _transition_timer <= 0.0:
			_transition_timer = -1.0  # prevent re-entry on subsequent frames
			SceneTransitions.change_scene("res://scenes/chapter1/shatter_transition.tscn", SceneTransitions.TransitionStyle.SHATTER)

func _input(event) -> void:
	# Skip the tutorial (Tab / pad View)
	if event.is_action_pressed("skip"):
		if _tutorial_active and combat_started and not combat_ended:
			_tutorial_skip_requested = true
			get_viewport().set_input_as_handled()
			return
	# Root Access toggle
	if event.is_action_pressed("root_access") and not combat_ended and boss and boss.has_method("get_hackable_properties"):
		if "phase_4_locked" in boss and boss.phase_4_locked:
			root_access_panel.visible = not root_access_panel.visible
			get_viewport().set_input_as_handled()

# ======================================================================
#  ARENA CONSTRUCTION
# ======================================================================
func _build_background() -> void:
	var bg = ColorRect.new()
	bg.color = Color(0.08, 0.06, 0.12)
	bg.size = Vector2(ARENA_WIDTH, ARENA_HEIGHT)
	bg.z_index = -10
	add_child(bg)

	# Subtle grid pattern overlay
	var grid = ColorRect.new()
	grid.color = Color(0.12, 0.10, 0.18, 0.35)
	grid.size = Vector2(ARENA_WIDTH, ARENA_HEIGHT)
	grid.z_index = -9
	add_child(grid)
	for rib_data in [
		{"name": "FarArchLeft", "pos": Vector2(44, 74), "size": Vector2(310, 350), "color": Color(0.03, 0.02, 0.07, 0.72)},
		{"name": "FarArchRight", "pos": Vector2(928, 74), "size": Vector2(310, 350), "color": Color(0.03, 0.02, 0.07, 0.72)},
		{"name": "UpperVault", "pos": Vector2(170, 64), "size": Vector2(940, 72), "color": Color(0.16, 0.10, 0.24, 0.32)},
	]:
		var rib = ColorRect.new()
		rib.name = rib_data["name"]
		rib.color = rib_data["color"]
		rib.position = rib_data["pos"]
		rib.size = rib_data["size"]
		rib.z_index = -8
		add_child(rib)
	var back_depth = Polygon2D.new()
	back_depth.name = "ArenaBackDepth"
	back_depth.color = Color(0.20, 0.11, 0.30, 0.22)
	back_depth.polygon = PackedVector2Array([
		Vector2(106, 512), Vector2(244, 248), Vector2(540, 186),
		Vector2(836, 198), Vector2(1084, 254), Vector2(1188, 512),
	])
	back_depth.z_index = -8
	add_child(back_depth)
	for banner_data in [
		{"name": "LeftVaultBanner", "points": PackedVector2Array([Vector2(318, 106), Vector2(362, 112), Vector2(358, 284), Vector2(340, 252), Vector2(324, 292)]), "color": Color(0.18, 0.10, 0.27, 0.46)},
		{"name": "CenterVaultBanner", "points": PackedVector2Array([Vector2(604, 84), Vector2(676, 84), Vector2(668, 232), Vector2(640, 202), Vector2(614, 238)]), "color": Color(0.24, 0.14, 0.34, 0.40)},
		{"name": "RightVaultBanner", "points": PackedVector2Array([Vector2(914, 112), Vector2(958, 106), Vector2(960, 292), Vector2(938, 250), Vector2(920, 282)]), "color": Color(0.18, 0.10, 0.27, 0.46)},
	]:
		var banner = Polygon2D.new()
		banner.name = banner_data["name"]
		banner.color = banner_data["color"]
		banner.polygon = banner_data["points"]
		banner.z_index = -7
		add_child(banner)
	if has_node("/root/AssetManager"):
		AssetManager.add_v3_environment_decal(self, "arena_border", Vector2(ARENA_WIDTH * 0.5, 470), Vector2(1174, 356), "V3TutorialArenaBorder", -8, Color(0.98, 0.92, 1.0, 0.92))
		AssetManager.add_v3_environment_decal(self, "root_veins", Vector2(ARENA_WIDTH * 0.5, 540), Vector2(510, 178), "V3TutorialArenaRootVeins", -7, Color(0.94, 0.72, 1.0, 0.34))

func _build_arena_colliders() -> void:
	# Floor
	_add_static_rect(Vector2(ARENA_WIDTH / 2, FLOOR_Y + WALL_THICKNESS / 2),
		Vector2(ARENA_WIDTH, WALL_THICKNESS), "Floor")

	# Left wall
	_add_static_rect(Vector2(-WALL_THICKNESS / 2, ARENA_HEIGHT / 2),
		Vector2(WALL_THICKNESS, ARENA_HEIGHT), "WallLeft")

	# Right wall
	_add_static_rect(Vector2(ARENA_WIDTH + WALL_THICKNESS / 2, ARENA_HEIGHT / 2),
		Vector2(WALL_THICKNESS, ARENA_HEIGHT), "WallRight")

	# Ceiling
	_add_static_rect(Vector2(ARENA_WIDTH / 2, -WALL_THICKNESS / 2),
		Vector2(ARENA_WIDTH, WALL_THICKNESS), "Ceiling")

	# Visual floor line
	var floor_line = ColorRect.new()
	floor_line.color = Color(0.25, 0.22, 0.35)
	floor_line.size = Vector2(ARENA_WIDTH, 4)
	floor_line.position = Vector2(0, FLOOR_Y - 2)
	floor_line.z_index = -5
	add_child(floor_line)

func _add_static_rect(center: Vector2, size: Vector2, node_name: String, one_way: bool = false) -> void:
	var body = StaticBody2D.new()
	body.name = node_name
	body.position = center
	body.collision_layer = 1   # World geometry layer
	body.collision_mask = 0
	var shape = CollisionShape2D.new()
	var rect = RectangleShape2D.new()
	rect.size = size
	shape.shape = rect
	shape.one_way_collision = one_way
	if one_way:
		shape.one_way_collision_margin = PLATFORM_ONE_WAY_MARGIN
	body.add_child(shape)
	add_child(body)

func _build_platforms() -> void:
	var platform_data = [
		{"pos": Vector2(180, 405), "width": 150.0, "name": "PlatformLeft"},
		{"pos": Vector2(1100, 405), "width": 150.0, "name": "PlatformRight"},
		{"pos": Vector2(640, 285), "width": 170.0, "name": "PlatformCenter"},
	]
	for p in platform_data:
		# Collision
		_add_static_rect(p.pos, Vector2(p.width, PLATFORM_HEIGHT), p.name, true)
		# Visual
		var vis = ColorRect.new()
		vis.color = Color(0.2, 0.18, 0.28)
		vis.size = Vector2(p.width, PLATFORM_HEIGHT)
		vis.position = p.pos - vis.size / 2
		vis.z_index = -4
		add_child(vis)
		# Edge highlight
		var edge = ColorRect.new()
		edge.color = Color(0.45, 0.35, 0.7, 0.6)
		edge.size = Vector2(p.width, 2)
		edge.position = Vector2(p.pos.x - p.width / 2, p.pos.y - PLATFORM_HEIGHT / 2)
		edge.z_index = -3
		add_child(edge)

func _build_arena_pressure() -> void:
	# A pulsing corruption lane forces jumps, dash routes, and platform repositioning without punishing Phase 1 learning.
	_add_arena_hazard(Vector2(ARENA_WIDTH / 2.0, FLOOR_Y - 38.0), Vector2(300, 76), "CentralCorruptionLane")
	_add_arena_marker(Vector2(ARENA_WIDTH / 2.0, 317), Vector2(130, 8), Color(0.25, 0.95, 1.0, 0.55), "FocusHealSigil", -2)
	_add_arena_marker(Vector2(270, FLOOR_Y - 5), Vector2(180, 5), Color(0.35, 0.95, 0.45, 0.5), "LeftSafeLane", -3)
	_add_arena_marker(Vector2(1010, FLOOR_Y - 5), Vector2(180, 5), Color(0.35, 0.95, 0.45, 0.5), "RightSafeLane", -3)
	_set_arena_pressure_phase(1)

func _add_arena_hazard(center: Vector2, area_size: Vector2, node_name: String) -> void:
	var visual = ColorRect.new()
	visual.name = "%sVisual" % node_name
	visual.color = Color(0.85, 0.12, 0.45, 0.45)
	visual.size = Vector2(area_size.x, 20)
	visual.position = Vector2(center.x - visual.size.x / 2.0, FLOOR_Y - 16.0)
	visual.z_index = -2
	add_child(visual)
	_arena_hazard_visuals.append(visual)

	var area = Area2D.new()
	area.name = node_name
	area.position = center
	area.collision_layer = 0
	area.collision_mask = 2
	area.monitoring = true
	area.monitorable = false
	var shape = CollisionShape2D.new()
	var rect = RectangleShape2D.new()
	rect.size = area_size
	shape.shape = rect
	area.add_child(shape)
	area.body_entered.connect(_on_arena_hazard_body_entered.bind(area))
	area.body_exited.connect(_on_arena_hazard_body_exited)
	add_child(area)

func _add_arena_marker(center: Vector2, size: Vector2, color: Color, node_name: String, z: int) -> void:
	var marker = ColorRect.new()
	marker.name = node_name
	marker.color = color
	marker.size = size
	marker.position = center - size / 2.0
	marker.z_index = z
	add_child(marker)

func _update_arena_pressure(delta: float) -> void:
	if _arena_hazard_enabled and combat_started and not combat_ended:
		_arena_hazard_cycle_timer = fmod(_arena_hazard_cycle_timer + delta, _arena_hazard_cycle_length)
		_arena_hazard_active = _arena_hazard_cycle_timer >= _arena_hazard_cycle_length - _arena_hazard_active_window
	else:
		_arena_hazard_active = false

	var warning_window := minf(_arena_hazard_active_window + 0.60, _arena_hazard_cycle_length)
	var warning_active := _arena_hazard_enabled and _arena_hazard_cycle_timer >= _arena_hazard_cycle_length - warning_window
	var pulse = 0.18
	if warning_active:
		pulse = 0.38 + 0.2 * sin(Time.get_ticks_msec() / 90.0)
	if _arena_hazard_active:
		pulse = 0.72 + 0.18 * sin(Time.get_ticks_msec() / 55.0)
	for visual in _arena_hazard_visuals:
		if is_instance_valid(visual):
			var c = visual.color
			c.a = pulse if _arena_hazard_enabled else 0.12
			visual.color = c

	if not _arena_hazard_enabled or not _arena_hazard_active or combat_ended or not combat_started:
		return
	if _arena_hazard_cooldown > 0.0:
		_arena_hazard_cooldown -= delta
		return
	for body in _arena_hazard_players.duplicate():
		if not is_instance_valid(body):
			_arena_hazard_players.erase(body)
			continue
		_damage_arena_hazard_player(body)
		break

func _on_arena_hazard_body_entered(body: Node, hazard: Area2D) -> void:
	if body and body.is_in_group("player") and body not in _arena_hazard_players:
		_arena_hazard_players.append(body)
		_damage_arena_hazard_player(body, hazard)

func _on_arena_hazard_body_exited(body: Node) -> void:
	_arena_hazard_players.erase(body)

func _damage_arena_hazard_player(body: Node, hazard: Area2D = null) -> void:
	if not _arena_hazard_enabled or not _arena_hazard_active or _arena_hazard_cooldown > 0.0:
		return
	if not is_instance_valid(body) or not body.has_method("take_damage"):
		return
	if "is_dead" in body and body.is_dead:
		return
	var source = hazard.global_position if hazard else Vector2(ARENA_WIDTH / 2.0, FLOOR_Y)
	body.take_damage(_arena_hazard_damage, source, "Corruption Floor", "arena_hazard")
	if has_node("/root/CombatFX"):
		CombatFX.apply_screen_shake(4.0, 0.12)
	_arena_hazard_cooldown = ARENA_HAZARD_INTERVAL

func _set_arena_pressure_phase(phase_id: int) -> void:
	_arena_hazard_enabled = phase_id >= 2 and phase_id != 4
	_arena_hazard_cycle_timer = 0.0
	_arena_hazard_active = false
	match phase_id:
		2:
			_arena_hazard_damage = 8.0
			_arena_hazard_cycle_length = 3.2
			_arena_hazard_active_window = 0.85
			_set_hazard_color(Color(1.0, 0.35, 0.12, 0.5))
		3:
			_arena_hazard_damage = 12.0
			_arena_hazard_cycle_length = 2.65
			_arena_hazard_active_window = 1.0
			_set_hazard_color(Color(0.85, 0.12, 0.85, 0.55))
		35:
			_arena_hazard_damage = 14.0
			_arena_hazard_cycle_length = 2.25
			_arena_hazard_active_window = 1.08
			_set_hazard_color(Color(1.0, 0.05, 0.05, 0.6))
		4:
			_arena_hazard_damage = 0.0
			_arena_hazard_cycle_length = 3.2
			_arena_hazard_active_window = 0.9
			_set_hazard_color(Color(0.1, 0.9, 0.45, 0.18))
		_:
			_arena_hazard_damage = ARENA_HAZARD_BASE_DAMAGE
			_arena_hazard_cycle_length = 3.2
			_arena_hazard_active_window = 0.9
			_set_hazard_color(Color(0.85, 0.12, 0.45, 0.45))
	if _arena_hazard_enabled:
		_arena_hazard_cycle_timer = maxf(0.0, _arena_hazard_cycle_length - _arena_hazard_active_window - 0.35)

func _set_hazard_color(color: Color) -> void:
	for visual in _arena_hazard_visuals:
		if is_instance_valid(visual):
			visual.color = color

# ======================================================================
#  ENTITY SPAWNING
# ======================================================================
func _spawn_player() -> void:
	player = CharacterBody2D.new()
	player.name = "Player"
	player.position = PLAYER_SPAWN
	player.collision_layer = 2   # Player layer
	player.collision_mask = 1    # Collide with world

	# Collision shape — capsule
	var col = CollisionShape2D.new()
	var capsule = CapsuleShape2D.new()
	capsule.radius = 12.0
	capsule.height = 48.0
	col.shape = capsule
	player.add_child(col)

	# Try to use actual player sprite, fall back to ColorRect placeholder
	var player_texture = null
	if has_node("/root/AssetManager"):
		player_texture = AssetManager.get_sprite("player_after_ch1")
	if not player_texture:
		player_texture = load("res://P after ch 1.png") if ResourceLoader.exists("res://P after ch 1.png") else null

	if player_texture:
		var sprite2d = Sprite2D.new()
		sprite2d.name = "Sprite"
		sprite2d.texture = player_texture
		sprite2d.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		# Uniform scale — fit to 48px tall, preserve aspect ratio
		var tex_size = player_texture.get_size()
		if tex_size.x > 0 and tex_size.y > 0:
			var uniform_scale = 48.0 / max(tex_size.x, tex_size.y)
			sprite2d.scale = Vector2(uniform_scale, uniform_scale)
			# Feet at origin — shift texture center up by half texture height
			sprite2d.offset = Vector2(0, -tex_size.y / 2.0)
		player.add_child(sprite2d)
	else:
		# Fallback: Temporary visual — blue character
		var sprite = ColorRect.new()
		sprite.name = "Sprite"
		sprite.color = Color(0.3, 0.5, 1.0)
		sprite.size = Vector2(24, 48)
		sprite.position = Vector2(-12, -24)
		player.add_child(sprite)

		# Visor / eye
		var visor = ColorRect.new()
		visor.color = Color(0.6, 0.9, 1.0)
		visor.size = Vector2(10, 4)
		visor.position = Vector2(2, -18)
		sprite.add_child(visor)

	# Attach the real combat script
	var combat_script = load("res://scripts/combat/player_combat.gd")
	player.set_script(combat_script)

	add_child(player)
	player.add_to_group("player")
	player.set_meta("local_boss_retry_enabled", true)
	var died_callback = Callable(self, "_on_player_died")
	if player.has_signal("died") and not player.is_connected("died", died_callback):
		player.connect("died", died_callback)
	AssetManager.replace_player_sprite(player, "combat")
	if player.has_method("refresh_visual_references"):
		player.refresh_visual_references()
	_remember_player_visual_baseline()

func _remember_player_visual_baseline() -> void:
	if not player:
		return
	var sprite = player.get_node_or_null("Sprite")
	if sprite and sprite is CanvasItem:
		sprite.set_meta("retry_base_position", sprite.position)
		sprite.set_meta("retry_base_rotation", sprite.rotation)
		sprite.set_meta("retry_base_scale", sprite.scale)

func _spawn_boss() -> void:
	boss = CharacterBody2D.new()
	boss.name = "Boss"
	boss.position = BOSS_SPAWN
	boss.collision_layer = 4   # Enemy layer
	boss.collision_mask = 1    # Collide with world

	# Collision shape — larger capsule
	var col = CollisionShape2D.new()
	var capsule = CapsuleShape2D.new()
	capsule.radius = 22.0
	capsule.height = 80.0
	col.shape = capsule
	boss.add_child(col)

	# Temporary visual — gold knight body
	var body_rect = ColorRect.new()
	body_rect.name = "Sprite"
	body_rect.color = Color(0.85, 0.72, 0.25)
	body_rect.size = Vector2(44, 80)
	body_rect.position = Vector2(-22, -40)
	boss.add_child(body_rect)

	# Armor overlay (darker centre stripe)
	var armor = ColorRect.new()
	armor.color = Color(0.55, 0.45, 0.15)
	armor.size = Vector2(20, 60)
	armor.position = Vector2(12, 10)
	body_rect.add_child(armor)

	# Sword visual (right side)
	var sword = ColorRect.new()
	sword.color = Color(0.75, 0.75, 0.85)
	sword.size = Vector2(6, 50)
	sword.position = Vector2(40, 5)
	body_rect.add_child(sword)

	# Eye / visor (red)
	var eye = ColorRect.new()
	eye.color = Color(1.0, 0.2, 0.2)
	eye.size = Vector2(14, 5)
	eye.position = Vector2(15, 6)
	body_rect.add_child(eye)

	# Attach boss AI script
	var boss_script = load("res://scripts/combat/enemies/tutorial_knight_boss_enemy.gd")
	boss.set_script(boss_script)

	add_child(boss)
	_configure_scripted_reward_enemy(boss)

	# Connect signals
	if not boss.phase_changed.is_connected(_on_boss_phase_changed):
		boss.phase_changed.connect(_on_boss_phase_changed)
	if not boss.root_access_triggered.is_connected(_on_root_access_triggered):
		boss.root_access_triggered.connect(_on_root_access_triggered)
	if not boss.boss_defeated.is_connected(_on_boss_defeated):
		boss.boss_defeated.connect(_on_boss_defeated)
	if not boss.health_changed.is_connected(_on_boss_health_changed):
		boss.health_changed.connect(_on_boss_health_changed)

	# Track boss fight for flawless achievement
	if has_node("/root/GameManager"):
		GameManager.start_boss_fight()

# ======================================================================
#  CAMERA
# ======================================================================
func _build_camera() -> void:
	camera = Camera2D.new()
	camera.name = "ArenaCamera"
	camera.position = Vector2(ARENA_WIDTH / 2, ARENA_HEIGHT / 2)
	camera.zoom = Vector2(1, 1)
	camera.position_smoothing_enabled = true
	camera.position_smoothing_speed = 4.0
	add_child(camera)
	camera.make_current()

# ======================================================================
#  UI — Boss HP Bar + Dialogue Box
# ======================================================================
func _build_ui() -> void:
	ui_layer = CanvasLayer.new()
	ui_layer.layer = 110
	add_child(ui_layer)

	# ── Boss HP Bar ──────────────────────────────────────────
	var hp_container = VBoxContainer.new()
	hp_container.name = "BossHPContainer"
	hp_container.set_anchors_preset(Control.PRESET_TOP_WIDE)
	hp_container.offset_top = 16
	hp_container.offset_left = 340
	hp_container.offset_right = -340
	ui_layer.add_child(hp_container)

	boss_name_label = Label.new()
	boss_name_label.text = "CORRUPTED SENTINEL"
	boss_name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	boss_name_label.add_theme_font_size_override("font_size", 14)
	boss_name_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.3))
	hp_container.add_child(boss_name_label)

	boss_hp_bar = ProgressBar.new()
	boss_hp_bar.name = "BossHPBar"
	boss_hp_bar.min_value = 0
	boss_hp_bar.max_value = 700
	boss_hp_bar.value = 700
	boss_hp_bar.custom_minimum_size = Vector2(600, 18)
	boss_hp_bar.show_percentage = false

	# Style the HP bar
	var fill_style = StyleBoxFlat.new()
	fill_style.bg_color = Color(0.85, 0.2, 0.2)
	fill_style.corner_radius_top_left = 3
	fill_style.corner_radius_top_right = 3
	fill_style.corner_radius_bottom_left = 3
	fill_style.corner_radius_bottom_right = 3
	boss_hp_bar.add_theme_stylebox_override("fill", fill_style)

	var bg_style = StyleBoxFlat.new()
	bg_style.bg_color = Color(0.15, 0.12, 0.12)
	bg_style.corner_radius_top_left = 3
	bg_style.corner_radius_top_right = 3
	bg_style.corner_radius_bottom_left = 3
	bg_style.corner_radius_bottom_right = 3
	boss_hp_bar.add_theme_stylebox_override("background", bg_style)

	hp_container.add_child(boss_hp_bar)
	hp_container.visible = false   # Hidden until combat starts

	# ── Dialogue Box ─────────────────────────────────────────
	dialogue_box = PanelContainer.new()
	dialogue_box.name = "DialogueBox"
	dialogue_box.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	dialogue_box.offset_bottom = -12
	dialogue_box.offset_top = -120
	dialogue_box.offset_left = 80
	dialogue_box.offset_right = -80
	dialogue_box.visible = false

	var panel_style = StyleBoxFlat.new()
	panel_style.bg_color = Color(0.05, 0.04, 0.08, 0.98)
	panel_style.border_color = Color(0.4, 0.3, 0.6, 0.8)
	panel_style.border_width_top = 2
	panel_style.border_width_bottom = 2
	panel_style.border_width_left = 2
	panel_style.border_width_right = 2
	panel_style.content_margin_top = 12
	panel_style.content_margin_bottom = 12
	panel_style.content_margin_left = 16
	panel_style.content_margin_right = 16
	panel_style.corner_radius_top_left = 6
	panel_style.corner_radius_top_right = 6
	panel_style.corner_radius_bottom_left = 6
	panel_style.corner_radius_bottom_right = 6
	dialogue_box.add_theme_stylebox_override("panel", panel_style)

	var vbox = VBoxContainer.new()
	vbox.name = "VBoxContainer"   # _show_dialogue finds the speaker label by path
	dialogue_box.add_child(vbox)

	var speaker_label = Label.new()
	speaker_label.name = "SpeakerLabel"
	speaker_label.add_theme_font_size_override("font_size", 12)
	speaker_label.add_theme_color_override("font_color", Color(0.6, 0.9, 1.0))
	vbox.add_child(speaker_label)

	dialogue_label = RichTextLabel.new()
	dialogue_label.name = "DialogueText"
	dialogue_label.bbcode_enabled = true
	dialogue_label.fit_content = true
	dialogue_label.scroll_active = false
	dialogue_label.add_theme_font_size_override("normal_font_size", 16)
	dialogue_label.add_theme_color_override("default_color", Color(0.9, 0.88, 0.95))
	vbox.add_child(dialogue_label)

	ui_layer.add_child(dialogue_box)

	# ── Tutorial Prompt ──────────────────────────────────────
	_tutorial_prompt_label = Label.new()
	_tutorial_prompt_label.name = "TutorialPrompt"
	_tutorial_prompt_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_tutorial_prompt_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_tutorial_prompt_label.add_theme_font_size_override("font_size", 18)
	_tutorial_prompt_label.add_theme_color_override("font_color", Color(0.9, 0.95, 1.0))
	_tutorial_prompt_label.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.8))
	_tutorial_prompt_label.add_theme_constant_override("shadow_offset_x", 2)
	_tutorial_prompt_label.add_theme_constant_override("shadow_offset_y", 2)
	_tutorial_prompt_label.set_anchors_preset(Control.PRESET_TOP_WIDE)
	_tutorial_prompt_label.offset_top = 70
	_tutorial_prompt_label.offset_left = 200
	_tutorial_prompt_label.offset_right = -200
	_tutorial_prompt_label.text = ""
	_tutorial_prompt_label.visible = false
	ui_layer.add_child(_tutorial_prompt_label)

# ======================================================================
#  ROOT ACCESS PANEL
# ======================================================================
func _build_root_access_panel() -> void:
	root_access_panel = PanelContainer.new()
	root_access_panel.name = "RootAccessPanel"
	root_access_panel.set_anchors_preset(Control.PRESET_CENTER)
	root_access_panel.offset_left = -200
	root_access_panel.offset_right = 200
	root_access_panel.offset_top = -120
	root_access_panel.offset_bottom = 120
	root_access_panel.visible = false

	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.02, 0.05, 0.02, 0.95)
	style.border_color = Color(0.0, 1.0, 0.0, 0.8)
	style.border_width_top = 2
	style.border_width_bottom = 2
	style.border_width_left = 2
	style.border_width_right = 2
	style.content_margin_top = 16
	style.content_margin_bottom = 16
	style.content_margin_left = 16
	style.content_margin_right = 16
	root_access_panel.add_theme_stylebox_override("panel", style)

	var vbox = VBoxContainer.new()
	root_access_panel.add_child(vbox)

	var title = Label.new()
	title.text = "[ ROOT ACCESS - CORRUPTED SENTINEL ]"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 14)
	title.add_theme_color_override("font_color", Color(0.0, 1.0, 0.0))
	vbox.add_child(title)

	var separator = HSeparator.new()
	vbox.add_child(separator)

	var desc = Label.new()
	desc.text = "Hackable Properties:"
	desc.add_theme_font_size_override("font_size", 12)
	desc.add_theme_color_override("font_color", Color(0.5, 1.0, 0.5))
	vbox.add_child(desc)

	# Checkbox: is_attacking
	var cb_attack = CheckBox.new()
	cb_attack.name = "CB_IsAttacking"
	cb_attack.text = "is_attacking = true"
	cb_attack.button_pressed = true
	cb_attack.add_theme_font_size_override("font_size", 14)
	cb_attack.add_theme_color_override("font_color", Color(0.0, 1.0, 0.0))
	cb_attack.toggled.connect(_on_hack_attacking_toggled)
	vbox.add_child(cb_attack)

	# Checkbox: is_hostile
	var cb_hostile = CheckBox.new()
	cb_hostile.name = "CB_IsHostile"
	cb_hostile.text = "is_hostile = true"
	cb_hostile.button_pressed = true
	cb_hostile.add_theme_font_size_override("font_size", 14)
	cb_hostile.add_theme_color_override("font_color", Color(0.0, 1.0, 0.0))
	cb_hostile.toggled.connect(_on_hack_hostile_toggled)
	vbox.add_child(cb_hostile)

	var hint = Label.new()
	hint.text = "\nDisable the attack directive to end the loop."
	hint.add_theme_font_size_override("font_size", 11)
	hint.add_theme_color_override("font_color", Color(0.4, 0.8, 0.4))
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD
	vbox.add_child(hint)

	var disable_btn = Button.new()
	disable_btn.name = "DisableAttackDirectiveButton"
	disable_btn.text = "Disable Attack Directive"
	disable_btn.add_theme_font_size_override("font_size", 14)
	disable_btn.add_theme_color_override("font_color", Color(0.0, 1.0, 0.0))
	disable_btn.pressed.connect(_on_disable_attack_directive_pressed)
	vbox.add_child(disable_btn)

	ui_layer.add_child(root_access_panel)

func _on_hack_attacking_toggled(enabled: bool) -> void:
	if boss and boss.has_method("hack_disable_attacking") and not enabled:
		_complete_root_access_shutdown()

func _on_disable_attack_directive_pressed() -> void:
	_complete_root_access_shutdown()

func _on_hack_hostile_toggled(enabled: bool) -> void:
	if boss and boss.has_method("apply_hack"):
		boss.apply_hack("is_hostile", enabled)   # the hack path shows the HACKED feedback
	elif boss:
		boss.is_hostile = enabled

# ======================================================================
#  INTRO SEQUENCE
# ======================================================================
# ======================================================================
#  COMBAT TUTORIAL — contextual prompts during Phase 1
# ======================================================================
func _update_combat_tutorial(delta: float) -> void:
	if not _tutorial_active or not combat_started or combat_ended:
		return

	# Check if tutorial hints are disabled in accessibility settings
	if has_node("/root/GameManager") and not GameManager.is_tutorial_hints_enabled():
		_end_tutorial()
		return

	# Skipped with the skip action (Tab / pad View)
	if _tutorial_skip_requested:
		_end_tutorial()
		return

	# Show HUD tutorial on first combat frame
	if not _hud_tutorial_shown:
		_hud_tutorial_shown = true
		_show_hud_tutorial()

	# Disable tutorial after Phase 1
	if boss and boss.has_method("get_hackable_properties"):
		if "current_boss_phase" in boss and boss.current_boss_phase != boss.BossPhase.PHASE_1:
			_end_tutorial()
			return

	# Check if current step's action was completed
	if _tutorial_step < TUTORIAL_STEPS.size():
		var step = TUTORIAL_STEPS[_tutorial_step]
		if _check_tutorial_action(step.check):
			_tutorial_completed_actions[step.check] = true
			_show_tutorial_completion(step)
			_tutorial_step += 1
			_tutorial_timer = 0.0
			_tutorial_prompt_visible_timer = 0.0
			if _tutorial_step >= TUTORIAL_STEPS.size():
				_end_tutorial()
				return

	# Show prompt with delay between steps
	_tutorial_timer += delta
	if _tutorial_timer >= _tutorial_delay and _tutorial_step < TUTORIAL_STEPS.size():
		var step = TUTORIAL_STEPS[_tutorial_step]
		# Show the prompt + contextual hint after 5 seconds of no progress
		var display_text = step.prompt
		if _tutorial_timer >= _tutorial_delay + 5.0 and step.has("hint"):
			display_text += "\n" + step.hint
		_tutorial_prompt_label.text = InputService.fmt(display_text + "\n[{skip}] Skip Tutorial")
		_tutorial_prompt_label.visible = true
		# Pulse the prompt opacity
		_tutorial_prompt_visible_timer += delta
		var alpha = 0.7 + 0.3 * sin(_tutorial_prompt_visible_timer * 3.0)
		_tutorial_prompt_label.modulate.a = alpha
	else:
		_tutorial_prompt_label.visible = false

func _check_tutorial_action(check_name: String) -> bool:
	if not player:
		return false
	match check_name:
		"moved":
			return abs(player.velocity.x) > 10
		"jumped":
			return not player.is_on_floor() and player.velocity.y < -100
		"attacked":
			return player.get("is_attacking") == true if player.get("is_attacking") != null else false
		"dashed":
			return player.get("is_dashing") == true if player.get("is_dashing") != null else false
		"parried":
			# Check for active parry or successful parry (defending state)
			var is_def = player.get("is_defending")
			var parry_act = player.get("parry_active")
			return (is_def == true) or (parry_act == true)
		"pogoed":
			# Check if player has performed a pogo strike
			var is_pogo = player.get("is_pogoing")
			return is_pogo == true if is_pogo != null else false
		"spelled":
			# Check if player is casting a spell
			var is_cast = player.get("is_casting")
			if is_cast == true:
				return true
			# Auto-complete after 25 seconds of this step to avoid hard-blocking
			if _tutorial_timer >= _tutorial_delay + 25.0:
				return true
			return false
		"healed":
			# Check if player is actively healing
			var is_heal = player.get("is_healing")
			if is_heal == true:
				return true
			# Auto-complete after 25 seconds to avoid hard-blocking on full HP
			if _tutorial_timer >= _tutorial_delay + 25.0:
				return true
			return false
	return false

func _end_tutorial() -> void:
	_tutorial_active = false
	if _tutorial_prompt_label:
		_tutorial_prompt_label.visible = false
		# Show completion message briefly
		var completed_count = _tutorial_completed_actions.size()
		var total_steps = TUTORIAL_STEPS.size()
		var msg = "Tutorial complete! (%d/%d moves learned) Fight on!" % [completed_count, total_steps]
		if _tutorial_skip_requested:
			msg = "Tutorial skipped. Good luck!"
		_tutorial_prompt_label.text = msg
		_tutorial_prompt_label.visible = true
		_tutorial_prompt_label.modulate.a = 1.0
		var tw = create_tween()
		tw.tween_interval(2.5)
		tw.tween_property(_tutorial_prompt_label, "modulate:a", 0.0, 1.0)
		tw.tween_callback(func(): _tutorial_prompt_label.visible = false)
	# Mark tutorial completed in GameManager
	if has_node("/root/GameManager"):
		GameManager.set_story_flag("tutorial_completed", true)

func _show_tutorial_completion(step: Dictionary) -> void:
	## Brief flash confirming the player completed a tutorial step
	if has_node("/root/SFXManager"):
		SFXManager.play("ui_confirm")
	if player and has_node("/root/VFXLibrary"):
		VFXLibrary.spawn_status_indicator("✓ %s" % step.action.to_upper(), player.global_position + Vector2(0, -60), player.get_parent(), false)

func _show_hud_tutorial() -> void:
	## Show a brief HUD legend at the start of combat
	if not _tutorial_prompt_label:
		return
	if has_node("/root/VFXLibrary") and player:
		VFXLibrary.spawn_status_indicator("HP / MP / Soul / Corruption — check top-left!", player.global_position + Vector2(0, -80), player.get_parent(), false)

# ======================================================================
#  INTRO SEQUENCE
# ======================================================================
func _start_intro() -> void:
	# Disable player input during intro
	if player:
		player.set_physics_process(false)
		player.set_process_input(false)
	if boss:
		boss.set_physics_process(false)

	# Play dialogue music
	if has_node("/root/MusicManager"):
		MusicManager.play_track("dialogue")

	# C1-S08 — Aldric Returns (aldric.dlg), then the fight.
	await DialogueManager.run(ALDRIC_DLG, "start", _on_dlg_event)
	if not is_inside_tree(): return
	_begin_combat()

func _total_dialogue_duration(dialogues: Array) -> float:
	var total = 0.0
	for d in dialogues:
		total += d.duration + 0.3   # 0.3s gap between lines
	return total

func _begin_combat() -> void:
	combat_started = true

	# Play arena bell SFX at fight start
	if has_node("/root/SFXManager"):
		SFXManager.play("arena_bell")

	# Enable physics
	if player:
		player.set_physics_process(true)
		player.set_process_input(true)
	if boss:
		boss.set_physics_process(true)

	# Start boss fight music
	if has_node("/root/MusicManager"):
		MusicManager.play_track("boss_fight")

	# Show boss HP bar with slide-in animation
	if ui_layer.has_node("BossHPContainer"):
		var hp_container = ui_layer.get_node("BossHPContainer")
		hp_container.visible = true
		hp_container.modulate.a = 0.0
		var original_y = hp_container.position.y
		hp_container.position.y -= 30
		var tween = create_tween()
		tween.tween_property(hp_container, "modulate:a", 1.0, 0.5).set_trans(Tween.TRANS_SINE)
		tween.parallel().tween_property(hp_container, "position:y", original_y, 0.5).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	# Brief combat-start flash
	if has_node("/root/SceneTransitions"):
		SceneTransitions.flash(Color(1.0, 1.0, 1.0, 0.5), 0.25)

# ======================================================================
#  DIALOGUE SYSTEM (lightweight, non-blocking during combat)
# ======================================================================
## A one-line bubble from aldric.dlg that doesn't pause the fight.
func _bark(node: String, duration: float = 3.0) -> void:
	var line: Dictionary = DialogueManager.line_of(ALDRIC_DLG, node)
	if line.is_empty():
		return
	_dialogue_queue = [{"speaker": line["speaker"], "text": line["text"], "duration": duration}]
	_advance_dialogue()

func _advance_dialogue() -> void:
	if _dialogue_queue.is_empty():
		dialogue_box.visible = false
		_dialogue_active = false
		return

	var entry = _dialogue_queue.pop_front()
	_show_dialogue(entry.speaker, InputService.fmt(entry.text), entry.duration)

func _show_dialogue(speaker: String, text: String, duration: float) -> void:
	_dialogue_active = true
	_current_dialogue_timer = duration

	dialogue_box.visible = true
	var speaker_label = dialogue_box.get_node("VBoxContainer/SpeakerLabel") if dialogue_box.has_node("VBoxContainer/SpeakerLabel") else null
	if speaker_label:
		speaker_label.text = speaker
	dialogue_label.text = text

func _update_dialogue(delta) -> void:
	if not _dialogue_active:
		return
	_current_dialogue_timer -= delta
	if _current_dialogue_timer <= 0.0:
		_advance_dialogue()

# ======================================================================
#  BOSS EVENT HANDLERS
# ======================================================================
func _on_boss_phase_changed(new_phase: int) -> void:
	_set_arena_pressure_phase(new_phase)
	match new_phase:
		2:   # Phase 2 — Aggression ramps up
			_bark("bark_stay_back")
			# Brief hitstop + orange flash for dramatic phase shift
			if has_node("/root/CombatFX"):
				CombatFX.apply_hitstop(0.15)
			if has_node("/root/SceneTransitions"):
				SceneTransitions.boss_phase_flash(Color(1.0, 0.6, 0.0))
		3:   # Phase 3 — Corruption intensifies
			_bark("bark_human_run")
			# Dramatic slowdown + purple corruption flash
			if has_node("/root/CombatFX"):
				CombatFX.apply_hitstop(0.2)
				CombatFX.apply_screen_shake(12.0, 0.5)
			if has_node("/root/SceneTransitions"):
				SceneTransitions.boss_phase_flash(Color(0.6, 0.0, 0.8))
			# Intensify background colour
			if get_child(0) is ColorRect:
				var tween = create_tween()
				tween.tween_property(get_child(0), "color",
					Color(0.14, 0.04, 0.08), 2.0).set_trans(Tween.TRANS_SINE)
		35:  # RAGE PHASE — Maximum intensity
			_bark("bark_gate")
			# Heavy hitstop + massive shake for the rage entrance
			if has_node("/root/CombatFX"):
				CombatFX.apply_hitstop(0.25)
				CombatFX.apply_screen_shake(20.0, 0.8)
			# Blood-red flash via SceneTransitions
			if has_node("/root/SceneTransitions"):
				SceneTransitions.boss_phase_flash(Color(1.0, 0.0, 0.0))
			# Switch to rage music
			if has_node("/root/MusicManager"):
				MusicManager.play_track("boss_rage")
			# Blood-red background transition
			if get_child(0) is ColorRect:
				var rage_tween = create_tween()
				rage_tween.tween_property(get_child(0), "color",
					Color(0.25, 0.02, 0.02), 1.5).set_trans(Tween.TRANS_EXPO)
		4:   # Phase 4 — Broken Loop (hackable)
			if has_node("/root/CombatFX"):
				CombatFX.apply_hitstop(0.3)
				CombatFX.apply_screen_shake(8.0, 0.6)
			if has_node("/root/SceneTransitions"):
				SceneTransitions.boss_phase_flash(Color(0.0, 1.0, 0.5))

func _on_root_access_triggered() -> void:
	# Phase 4 — show hint with green hack flash
	_arena_hazard_enabled = false
	_arena_hazard_active = false
	_arena_hazard_players.clear()
	if boss:
		boss.velocity = Vector2.ZERO
		boss.set_physics_process(false)
	_bark("bark_root_hint", 3.4)
	_show_root_access_panel()
	if has_node("/root/SceneTransitions"):
		SceneTransitions.flash(Color(0.0, 1.0, 0.0, 0.8), 0.5)

func _show_root_access_panel() -> void:
	if not root_access_panel:
		return
	root_access_panel.visible = true
	root_access_panel.modulate.a = 1.0
	var disable_btn = root_access_panel.find_child("DisableAttackDirectiveButton", true, false)
	if disable_btn and disable_btn is Control:
		disable_btn.grab_focus()

func _complete_root_access_shutdown() -> void:
	if _root_access_completing or combat_ended:
		return
	_root_access_completing = true
	_arena_hazard_enabled = false
	_arena_hazard_active = false
	_arena_hazard_players.clear()
	if root_access_panel:
		var disable_btn = root_access_panel.find_child("DisableAttackDirectiveButton", true, false)
		if disable_btn and disable_btn is Button:
			disable_btn.disabled = true
			disable_btn.text = "Directive Disabled"
	if boss:
		boss.velocity = Vector2.ZERO
		boss.set_physics_process(false)
	if has_node("/root/VFXLibrary") and boss:
		VFXLibrary.spawn_status_indicator("DIRECTIVE DISABLED", boss.global_position + Vector2(0, -96), self, true)
	if has_node("/root/CombatFX"):
		CombatFX.apply_hitstop(0.10)
	await get_tree().create_timer(0.35, false).timeout
	if not is_inside_tree():
		return
	if boss and boss.has_method("hack_disable_attacking"):
		boss.hack_disable_attacking()
	if root_access_panel:
		root_access_panel.visible = false
	_on_boss_defeated()

func _on_boss_defeated() -> void:
	if combat_ended:
		return
	combat_ended = true
	# The knight's die() already ends the fight (and counts the kill); only a
	# defeat that skipped die(), like the Root Access shutdown, still needs it.
	if has_node("/root/GameManager") and GameManager.boss_fight_active:
		GameManager.end_boss_fight()
	GameManager.auto_save()  # Autosave on boss defeat

	# Freeze boss
	if boss:
		boss.set_physics_process(false)
	# Freeze player
	if player:
		player.set_physics_process(false)
		player.set_process_input(false)
	# Hide HP bar & root access
	if ui_layer.has_node("BossHPContainer"):
		ui_layer.get_node("BossHPContainer").visible = false
	root_access_panel.visible = false

	# Victory music
	if has_node("/root/MusicManager"):
		MusicManager.play_track("victory")
	if has_node("/root/CombatFX"):
		CombatFX.apply_hitstop(0.12)
		CombatFX.apply_screen_shake(11.0, 0.32)
	if has_node("/root/SceneTransitions"):
		SceneTransitions.boss_phase_flash(Color(1.0, 0.85, 0.35))
	if has_node("/root/VFXLibrary") and player:
		VFXLibrary.spawn_status_indicator("VICTORY", player.global_position + Vector2(0, -84), self, true)

	# C1-S09 onward: the decision, Fragment One, the meeting, Elara joins.
	await _play_aldric_decision()

func _on_boss_health_changed(new_health: float, max_hp: float) -> void:
	if boss_hp_bar:
		boss_hp_bar.max_value = max_hp
		boss_hp_bar.value = new_health

func _update_boss_hp_bar() -> void:
	if not boss or not boss_hp_bar:
		return
	if "current_health" in boss:
		boss_hp_bar.value = boss.current_health

func _on_player_died() -> void:
	if combat_ended or _retry_in_progress:
		return
	_retry_in_progress = true
	combat_started = false
	if boss:
		boss.set_physics_process(false)
		boss.velocity = Vector2.ZERO

	if has_node("/root/GameManager"):
		GameManager.set_story_flag("player_died", true)
		GameManager.add_death_corruption()
		var hp_removed := 0.0
		if boss and "current_health" in boss and "max_health" in boss and boss.max_health > 0.0:
			hp_removed = clampf(1.0 - (boss.current_health / boss.max_health), 0.0, 1.0)
		GameManager.record_boss_progress("tutorial_knight", hp_removed, _get_boss_phase_number())

	if has_node("/root/VFXLibrary") and player:
		VFXLibrary.spawn_status_indicator("RETRY", player.global_position + Vector2(0, -70), self, false)

	await get_tree().create_timer(1.05, false, false, true).timeout
	if not is_inside_tree():
		return

	_arena_hazard_players.clear()
	_arena_hazard_cooldown = 0.0
	_reset_player_for_retry("primary")
	_reset_boss_for_retry()
	_set_arena_pressure_phase(1)
	if root_access_panel:
		root_access_panel.visible = false
	combat_started = true
	await get_tree().process_frame
	if is_inside_tree():
		_reset_player_for_retry("late-frame")
	_retry_in_progress = false

func _get_boss_phase_number() -> int:
	if not boss or not "current_boss_phase" in boss:
		return 1
	match int(boss.current_boss_phase):
		0:
			return 1
		1:
			return 2
		2:
			return 3
		3:
			return 35
		4:
			return 4
	return 1

func _reset_player_for_retry(label: String = "retry") -> void:
	if not player:
		return
	if player.has_method("force_restore_after_death_retry"):
		var state: Dictionary = player.force_restore_after_death_retry(PLAYER_SPAWN)
		_log_retry_restore_state(label, state)
		return
	ContextStack.clear_time_scale()  # drop any hitstop/slow-mo
	player.global_position = PLAYER_SPAWN
	player.velocity = Vector2.ZERO
	player.visible = true
	player.modulate = Color.WHITE
	player.self_modulate = Color.WHITE
	player.scale = Vector2.ONE
	player.rotation = 0.0
	player.collision_layer = 2
	player.collision_mask = 1
	for child in player.get_children():
		if child is CollisionShape2D:
			child.disabled = false
	if "is_dead" in player:
		player.is_dead = false
	if "max_health" in player and "current_health" in player:
		player.current_health = player.max_health
		GameManager.player_stats["hp"] = int(player.current_health)
	player.set_process(true)
	player.set_physics_process(true)
	player.set_process_input(true)
	_log_retry_restore_state(label, {"player_visible": player.visible, "sprite_visible": false, "player_alpha": player.modulate.a, "sprite_alpha": -1.0, "collision_enabled": true, "input_enabled": player.is_processing_input(), "process_enabled": player.is_processing(), "physics_enabled": player.is_physics_processing(), "is_dead": player.get("is_dead"), "hp": player.get("current_health"), "time_scale": Engine.time_scale})

func _log_retry_restore_state(label: String, state: Dictionary) -> void:
	print("[TK-RETRY:%s] player_visible=%s sprite_visible=%s player_alpha=%.2f sprite_alpha=%.2f collision=%s input=%s process=%s physics=%s is_dead=%s hp=%.1f time_scale=%.2f" % [
		label,
		str(state.get("player_visible", false)),
		str(state.get("sprite_visible", false)),
		float(state.get("player_alpha", -1.0)),
		float(state.get("sprite_alpha", -1.0)),
		str(state.get("collision_enabled", false)),
		str(state.get("input_enabled", false)),
		str(state.get("process_enabled", false)),
		str(state.get("physics_enabled", false)),
		str(state.get("is_dead", true)),
		float(state.get("hp", -1.0)),
		float(state.get("time_scale", -1.0))
	])

func _reset_boss_for_retry() -> void:
	if not boss:
		return
	boss.global_position = BOSS_SPAWN
	boss.velocity = Vector2.ZERO
	if boss.has_method("reset_for_retry"):
		boss.reset_for_retry()
	else:
		boss.set_physics_process(true)

# ======================================================================
#  ALDRIC: THE DECISION, FRAGMENT ONE, THE VILLAGE MEETING (C1-S09 to S12)
# ======================================================================
## After the fight: kill / spare / purge (aldric.dlg), then the shrine and
## Fragment One, the bridge news if it fell, Oakhaven's meeting, and Elara
## packing (fragment_one.dlg). Then the Chapter 1 ending (shatter_transition).
func _play_aldric_decision() -> void:
	_dialogue_queue.clear()
	if dialogue_box:
		dialogue_box.visible = false
	_dialogue_active = false
	await DialogueManager.run(ALDRIC_DLG, "decision", _on_dlg_event)
	if not is_inside_tree(): return
	_apply_aldric_consequences()
	_give_loot()
	GameManager.set_story_flag("ch1_tutorial_knight_defeated", true)

	await _location_card("Under the old gate")
	if not is_inside_tree(): return
	await DialogueManager.run(FRAGMENT_DLG, "fragment", _on_dlg_event)
	if not is_inside_tree(): return

	# The bridge deadline was "until dark". If it wasn't fixed, it's gone now.
	var bridge_seen := GameManager.has_flag("ch1_bridge_repair_accepted") or GameManager.has_flag("ch1_bridge_evacuated") \
		or GameManager.has_flag("ch1_bridge_ignored")
	if bridge_seen and not GameManager.has_flag("ch1_bridge_saved"):
		GameManager.set_story_flag("ch1_bridge_fell", true)
		await _location_card("Oakhaven, after dark")
		if not is_inside_tree(): return
		await DialogueManager.run(NORTH_FIELD_DLG, "bridge_fell", _on_dlg_event)
		if not is_inside_tree(): return
	else:
		await _location_card("Oakhaven, after dark")
		if not is_inside_tree(): return

	await DialogueManager.run(FRAGMENT_DLG, "meeting", _on_dlg_event)
	if not is_inside_tree(): return
	await DialogueManager.run(FRAGMENT_DLG, "joins", _on_dlg_event)
	if not is_inside_tree(): return
	await get_tree().create_timer(1.0, false).timeout
	if not is_inside_tree(): return
	SceneTransitions.change_scene("res://scenes/chapter1/shatter_transition.tscn", SceneTransitions.TransitionStyle.SHATTER)

## Mechanical consequences of the choice (story consequences are flags the
## .dlg already set).
func _apply_aldric_consequences() -> void:
	var buff := ""
	if GameManager.has_flag("ch1_knight_killed"):
		GameManager.add_glitch_corruption(5.0)
		buff = "ch1_knight_killed"
	elif GameManager.has_flag("ch1_root_purge"):
		GameManager.add_glitch_corruption(8.0)
		buff = "ch1_root_purge_used"
	elif GameManager.has_flag("ch1_knight_spared"):
		buff = "ch1_knight_spared"
	if buff != "" and has_node("/root/ChoiceConsequences"):
		ChoiceConsequences.apply_choice_buff(buff)

func _on_dlg_event(event: String) -> void:
	var parts := event.split(" ", false, 1)
	match parts[0]:
		"elara_goes_still", "child_runs_inside", "kaelen_freezes", "kaelen_raises_weapon", "elara_packs", "village_gathers", "elara_watches", "kaelen_recoils", "flash_ends":
			await get_tree().create_timer(0.4, false).timeout
		"aldric_approaches":
			if boss:
				var t := create_tween()
				t.tween_property(boss, "global_position:x", BOSS_SPAWN.x - 120.0, 1.2)
				await t.finished
		"aldric_visor_glitch", "aldric_eye_clears", "memory_flash", "touch_fragment":
			if has_node("/root/SceneTransitions"):
				SceneTransitions.flash(Color(1, 1, 1, 0.6), 0.25)
			await get_tree().create_timer(0.3, false).timeout
		"directive_surge", "directive_returns", "villagers_panic":
			if has_node("/root/CombatFX"):
				CombatFX.apply_screen_shake(9.0, 0.35)
			await get_tree().create_timer(0.35, false).timeout
		"start_boss":
			pass   # _start_intro starts combat when the run ends
		"aldric_kneels":
			if boss:
				boss.modulate = Color(0.7, 0.7, 0.75)
		"show_directive_tree", "root_purge":
			if root_access_panel:
				root_access_panel.visible = true
			if has_node("/root/CombatFX"):
				CombatFX.apply_screen_shake(6.0, 0.4)
			await get_tree().create_timer(0.8, false).timeout
			if root_access_panel:
				root_access_panel.visible = false
		"kaelen_strikes":
			if has_node("/root/CombatFX"):
				CombatFX.apply_screen_shake(14.0, 0.3)
			if boss:
				var t := create_tween()
				t.tween_property(boss, "modulate:a", 0.0, 1.5)
				await t.finished
		"aldric_restrained":
			if boss:
				boss.modulate = Color(0.55, 0.55, 0.6)
		"open_shrine_gate":
			if has_node("/root/SceneTransitions"):
				SceneTransitions.flash(Color(0.9, 0.85, 0.5, 0.5), 0.4)
		"fragment_acquired":
			GameManager.collect_source_key(int(parts[1]) if parts.size() > 1 else 1)
			if has_node("/root/VFXLibrary") and player:
				VFXLibrary.spawn_status_indicator("SOURCE KEY 1/7", player.global_position + Vector2(0, -90), self, true)
		"elara_joins_party":
			pass   # Elara is already travelling with Kaelen; ch1_elara_joined marks it
		_:
			print("[TUTORIAL KNIGHT] unhandled dialogue event: %s" % event)

## A black card with a place name, for scenes there's no set for yet. Sits
## under the dialogue box (layer 100), over the arena.
func _location_card(text: String) -> void:
	if _card_layer == null:
		_card_layer = CanvasLayer.new()
		_card_layer.layer = 95
		add_child(_card_layer)
		var black := ColorRect.new()
		black.name = "Black"
		black.color = Color.BLACK
		black.set_anchors_preset(Control.PRESET_FULL_RECT)
		black.mouse_filter = Control.MOUSE_FILTER_IGNORE
		black.modulate.a = 0.0
		_card_layer.add_child(black)
		var label := Label.new()
		label.name = "Place"
		label.set_anchors_preset(Control.PRESET_CENTER_TOP)
		label.position = Vector2(0, 200)
		label.size = Vector2(ARENA_WIDTH, 40)
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.add_theme_font_size_override("font_size", 22)
		label.add_theme_color_override("font_color", Color(0.85, 0.85, 0.9))
		_card_layer.add_child(label)
	var black_rect := _card_layer.get_node("Black") as ColorRect
	var place := _card_layer.get_node("Place") as Label
	place.text = text
	place.modulate.a = 0.0
	var t := create_tween()
	t.tween_property(black_rect, "modulate:a", 1.0, 0.6)
	t.tween_property(place, "modulate:a", 1.0, 0.4)
	t.tween_interval(1.0)
	t.tween_property(place, "modulate:a", 0.0, 0.4)
	await t.finished

# ======================================================================
#  LOOT
# ======================================================================
func _give_loot() -> void:
	# Give weapon
	if has_node("/root/Inventory") and Inventory.has_method("add_item"):
		Inventory.add_item("corrupted_knight_blade", 1)
		Inventory.add_gold(500)

	# XP + Level (add_xp handles level up automatically)
	if GameManager:
		GameManager.add_xp(200)
		GameManager.set_story_flag("ch1_tutorial_knight_defeated", true)
	if has_node("/root/VFXLibrary") and player:
		VFXLibrary.spawn_status_indicator("BLADE +500G +200XP", player.global_position + Vector2(0, -96), self, true)

# ======================================================================
#  UTILITIES
# ======================================================================
func _configure_scripted_reward_enemy(enemy: Node) -> void:
	## Tutorial knight rewards are granted by this scene after the story choice.
	if not is_instance_valid(enemy):
		return
	enemy.set_meta("suppress_base_rewards", true)
	var table = enemy.get("loot_table")
	if table:
		table.gold_min = 0
		table.gold_max = 0
		table.xp_min = 0
		table.xp_max = 0

func _notification(what) -> void:
	if what == NOTIFICATION_PREDELETE:
		# Cleanup
		pass
