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

const TUTORIAL_STEPS: Array = [
	{"action": "move", "prompt": "[A/D] Move left and right", "check": "moved", "hint": "Hold a direction to move Kaelen."},
	{"action": "jump", "prompt": "[SPACE] Jump!  Hold for higher jumps", "check": "jumped", "hint": "Tap SPACE to jump. Hold SPACE longer to jump higher."},
	{"action": "attack", "prompt": "[J] Attack!  Chain 3 hits for a combo", "check": "attacked", "hint": "Press J repeatedly to chain a 3-hit combo."},
	{"action": "dash", "prompt": "[SHIFT] Dash through attacks — you have i-frames!", "check": "dashed", "hint": "Dash gives invincibility frames. Use it to dodge through attacks."},
	{"action": "parry", "prompt": "[K] Parry just before an attack hits — counter window!", "check": "parried", "hint": "Time your parry right before impact. Success opens a counter window."},
	{"action": "pogo", "prompt": "[S]+[J] in air — Pogo Strike! Bounce off enemies", "check": "pogoed", "hint": "While airborne, hold DOWN + ATTACK to pogo bounce. Resets dash!"},
	{"action": "spell", "prompt": "[Q] Vengeful Spirit  |  [S]+[Q] Desolate Dive  |  [W]+[Q] Howling Wraiths", "check": "spelled", "hint": "Spells cost 33 Soul. Hit enemies with J to earn Soul."},
	{"action": "heal", "prompt": "[C] Focus Heal when safe — costs 33 Soul", "check": "healed", "hint": "Hold C to channel a heal. Find a safe moment — you're vulnerable while healing."},
]

const HUD_TUTORIAL_TEXT: String = "HUD Guide:\n[color=#ff4444]Red Bar[/color] = HP  |  [color=#4488ff]Blue Bar[/color] = Soul  |  [color=#aa44ff]Purple %%[/color] = Corruption\nHit enemies to gain Soul. Spend Soul on spells [Q] or healing [C]."
var _hud_tutorial_shown: bool = false
var _tutorial_skip_requested: bool = false

# ─── DIALOGUE DATA ──────────────────────────────────────────────────────
var intro_dialogues: Array[Dictionary] = [
	{"speaker": "???", "text": "Another consciousness drifts into my patrol zone…\nYou should not be here, anomaly.", "duration": 3.5},
	{"speaker": "Kaelen (Internal)", "text": "A knight? No — its edges are glitching.\n This thing is part of the system.", "duration": 3.5},
	{"speaker": "Corrupted Sentinel", "text": "Directive: PURGE UNAUTHORISED PROCESSES.\nPrepare for deletion.", "duration": 3.0},
]

var phase2_dialogue: Dictionary = {
	"speaker": "Corrupted Sentinel", "text": "You persist… Increasing threat level.\nProtocol: AGGRESSIVE COUNTERMEASURE.", "duration": 3.0
}

var phase3_dialogue: Dictionary = {
	"speaker": "Corrupted Sentinel", "text": "ERR—ERROR… My directives… they're C-CORRUPTED—\nI can't… stop…!", "duration": 3.0
}

var rage_dialogue: Dictionary = {
	"speaker": "Corrupted Sentinel", "text": "N-NO MORE RESTRAINT… THE CORRUPTION DEMANDS\nDESTRUCTION! I WILL END YOU!", "duration": 3.0
}

var phase4_dialogue: Dictionary = {
	"speaker": "Elara", "text": "Its control loop is exposed! Open Root Access\nwith [E] and disable its attack flag!", "duration": 4.0
}

var victory_dialogues: Array[Dictionary] = [
	{"speaker": "Corrupted Sentinel", "text": "…thank you.  The corruption… it made me…\nI was a guardian once.  Not a monster.", "duration": 3.5},
	{"speaker": "Kaelen", "text": "What happened to you?", "duration": 2.0},
	{"speaker": "Corrupted Sentinel", "text": "The Source Code… fractured.  Everything broke.\nTake my blade. You'll need it… for what comes next.", "duration": 4.0},
	{"speaker": "System", "text": "[Corrupted Knight's Blade obtained!]\n+500 Gold  •  +200 XP  •  Level Up!", "duration": 3.5},
]

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
	# Skip tutorial with TAB
	if event is InputEventKey and event.pressed and event.keycode == KEY_TAB:
		if _tutorial_active and combat_started and not combat_ended:
			_tutorial_skip_requested = true
			get_viewport().set_input_as_handled()
			return
	# Root Access toggle
	if event.is_action_pressed("root_access") and boss and boss.has_method("get_hackable_properties"):
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
	if boss:
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

	# Allow skipping with [TAB]
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
		_tutorial_prompt_label.text = display_text + "\n[color=#666666][TAB] Skip Tutorial[/color]"
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
	# Use a RichTextLabel if attached, otherwise fallback to plain text
	var _hud_text = "HUD: Red=HP | Blue=Soul | Purple%=Corruption\nHit enemies to gain Soul. Spend on spells [Q] or heal [C]."
	if has_node("/root/VFXLibrary") and player:
		VFXLibrary.spawn_status_indicator("HP / Soul / Corruption — check top-left!", player.global_position + Vector2(0, -80), player.get_parent(), false)

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

	# Play intro dialogues, then start combat
	_dialogue_queue = intro_dialogues.duplicate()
	_dialogue_active = false
	_advance_dialogue()

	# Wait for all dialogues to finish, then begin combat
	if not is_inside_tree(): return
	await get_tree().create_timer(
		_total_dialogue_duration(intro_dialogues) + 0.5
	).timeout
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
func _advance_dialogue() -> void:
	if _dialogue_queue.is_empty():
		dialogue_box.visible = false
		_dialogue_active = false
		return

	var entry = _dialogue_queue.pop_front()
	_show_dialogue(entry.speaker, entry.text, entry.duration)

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
			_dialogue_queue = [phase2_dialogue]
			_advance_dialogue()
			# Brief hitstop + orange flash for dramatic phase shift
			if has_node("/root/CombatFX"):
				CombatFX.apply_hitstop(0.15)
			if has_node("/root/SceneTransitions"):
				SceneTransitions.boss_phase_flash(Color(1.0, 0.6, 0.0))
		3:   # Phase 3 — Corruption intensifies
			_dialogue_queue = [phase3_dialogue]
			_advance_dialogue()
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
			_dialogue_queue = [rage_dialogue]
			_advance_dialogue()
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
	_dialogue_queue = [{
		"speaker": "Elara",
		"text": "The control loop is exposed. Root Access is open.\nClick Disable Attack Directive to end the fight.",
		"duration": 3.4
	}]
	_advance_dialogue()
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
	await get_tree().create_timer(0.35).timeout
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
	if has_node("/root/GameManager"):
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

	# Play initial victory dialogue using the timer system
	_dialogue_queue = victory_dialogues.duplicate()
	_advance_dialogue()

	# Wait for timer dialogues to finish, then show the branching choice
	var wait_time = _total_dialogue_duration(victory_dialogues) + 1.0
	await get_tree().create_timer(wait_time).timeout
	if not is_inside_tree(): return
	dialogue_box.visible = false

	# --- EXPANDED POST-BATTLE STORY + KILL/SPARE CHOICE ---
	await _play_post_battle_choice()
	if not is_inside_tree(): return

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

	await get_tree().create_timer(1.05, true, false, true).timeout
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
	Engine.time_scale = 1.0
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
#  POST-BATTLE NARRATIVE + KILL/SPARE CHOICE
# ======================================================================
func _play_post_battle_choice() -> void:
	## Extended post-boss narrative with branching kill/spare decision
	
	# The knight has fallen — use DialogueManager for the deep narrative
	await DialogueManager.say("Kaelen", "*breathing hard, staring at the fallen knight* ...It stopped fighting. The corruption is still writhing across its armor, but its sword arm dropped. It's... looking at me.")
	if not is_inside_tree(): return
	
	await DialogueManager.say("Corrupted Sentinel", "*voice glitching, fragments of a gentler tone underneath* ...You... did not simply overpower me. You found... the code beneath the commands. You reached INSIDE me and turned off the thing that... that MADE me hurt you.")
	if not is_inside_tree(): return
	
	await DialogueManager.say("Kaelen", "You're not just a boss fight. You're a person. Trapped in a loop, forced to attack anyone who crosses this bridge.")
	if not is_inside_tree(): return
	
	await DialogueManager.say("Corrupted Sentinel", "*shudders, corruption flickering violently* Four hundred... and twelve cycles. I have stood at this bridge and fought every traveler who tried to cross. Not because I wanted to. Because the directive COMPELLED me. Like a hand around my throat, squeezing every time I tried to resist.")
	if not is_inside_tree(): return
	
	await DialogueManager.say("Kaelen (Internal)", "Four hundred and twelve times. He's been stuck in this fight for four hundred and twelve iterations. And every single time, he dies or the challenger dies. An endless loop of violence with no exit condition. Until now.", Color(0.5, 0.9, 1.0))
	if not is_inside_tree(): return
	
	await DialogueManager.say("Corrupted Sentinel", "*reaches toward Kaelen with a trembling hand* The corruption in me... it's deep. Woven into my core code. Even with the attack directive disabled, I can feel it trying to reassert itself. Trying to make me raise my sword again.")
	if not is_inside_tree(): return
	
	await DialogueManager.say("Corrupted Sentinel", "I have two requests, and... I've never been able to make requests before. The directive never allowed it. But right now, in this gap you've created — I can think. I can CHOOSE. And I'm terrified it won't last.")
	if not is_inside_tree(): return
	
	await DialogueManager.say("Kaelen", "What do you need?")
	if not is_inside_tree(): return
	
	await DialogueManager.say("Corrupted Sentinel", "First — take my blade. The Corrupted Knight's Blade. It will serve you better than it served me. It carries the weight of four hundred cycles of combat, and that weight translates to power.")
	if not is_inside_tree(): return
	
	await DialogueManager.say("Corrupted Sentinel", "Second... *voice drops to a whisper* ...I need you to decide what happens next. The corruption will reassert itself. Minutes, maybe. When it does, the directive will reactivate, and I'll be forced to fight the next person who crosses this bridge. Another cycle. Another four hundred fights.")
	if not is_inside_tree(): return
	
	# Dramatic pause — let the gravity of the situation land
	DialogueManager.hide_dialogue()
	await get_tree().create_timer(2.5).timeout
	if not is_inside_tree(): return
	
	await DialogueManager.say("Corrupted Sentinel", "*looks directly at Kaelen* You can end me. One strike. The corruption dies with my process. The bridge will be free. No more cycles. No more forced battles. I'd be... at peace.")
	if not is_inside_tree(): return
	
	await DialogueManager.say("Corrupted Sentinel", "Or you can spare me. Walk away. And hope that the gap you created lasts long enough for me to... to find another way. But I won't lie to you — I don't know if it will. I've never been free before. I don't know how long freedom lasts in a world that doesn't want it to exist.")
	if not is_inside_tree(): return
	
	# Check if Elara is with us
	var has_elara = GameManager.story_flags.get("ch1_elara_trusted", false) or GameManager.story_flags.get("ch1_elara_cautious", false)
	
	if has_elara:
		await DialogueManager.say("Elara", "*quiet, her flickering arm trembling* Kaelen... I've watched this knight fight and die and reset more times than I can count. He never asked for any of this. Whatever you decide, I'll stand by it. But this is YOUR choice.")
		if not is_inside_tree(): return
	
	await DialogueManager.say("Kaelen (Internal)", "End his suffering permanently, or gamble on a freedom that might not last. The engineer in me says terminating a corrupted process is the safest option. But the human in me... the human in me is standing in front of a person who just tasted freedom for the first time in four hundred cycles and is asking me if he gets to keep it.", Color(0.5, 0.9, 1.0))
	if not is_inside_tree(): return
	
	# THE CHOICE
	var choice = await DialogueManager.show_choices(
		"The Corrupted Sentinel kneels before you, his sword arm limp, his red visor dimming. The corruption writhes beneath his armor like something alive, fighting to regain control. His eyes — real eyes, buried beneath the glitch — are looking at you with something you've never seen in this world before: hope.",
		[
			"Spare the Knight — let him live free",
			"End his suffering — a mercy strike",
			"Try to purge the corruption with Root Access"
		],
		"Kaelen (Internal)"
	)
	if not is_inside_tree(): return
	
	DialogueManager.hide_dialogue()
	await get_tree().create_timer(0.5).timeout
	if not is_inside_tree(): return
	
	match choice:
		0:
			await _spare_knight()
			if not is_inside_tree(): return
		1:
			await _kill_knight()
			if not is_inside_tree(): return
		2:
			await _purge_knight()
			if not is_inside_tree(): return
		_:
			await _spare_knight()
			if not is_inside_tree(): return
	
	# Give loot regardless of choice
	_give_loot()
	GameManager.set_story_flag("ch1_tutorial_knight_defeated", true)
	# Award Source Key Fragment #1
	GameManager.collect_source_key(1)
	
	# Transition after the choice plays out
	await get_tree().create_timer(2.0).timeout
	if not is_inside_tree(): return
	SceneTransitions.change_scene("res://scenes/chapter1/shatter_transition.tscn", SceneTransitions.TransitionStyle.SHATTER)

func _spare_knight() -> void:
	## Player spares the knight — hopeful path, lower corruption, knight may return later
	GameManager.set_story_flag("ch1_knight_spared", true)
	print("[CHOICE] Player spared the Tutorial Knight")
	# Notify player of gameplay consequences
	if has_node("/root/ChoiceConsequences"):
		ChoiceConsequences.apply_choice_buff("ch1_knight_spared")
	
	await DialogueManager.say("Kaelen", "*sheathes his weapon and extends a hand to the knight* I'm not going to kill someone who just asked me for mercy. You spent four hundred cycles trapped in a prison. You deserve the chance to find out what freedom feels like.")
	if not is_inside_tree(): return
	
	await DialogueManager.say("Corrupted Sentinel", "*stares at the extended hand, trembling* ...You're the first. In all those cycles, every opponent who beat me tried to land the killing blow for the XP. You're the first one who... *voice breaks*")
	if not is_inside_tree(): return
	
	await DialogueManager.say("Kaelen", "Then let's make it count. Stand up, soldier.")
	if not is_inside_tree(): return
	
	# The knight rises — visibly struggling against the corruption
	await DialogueManager.say("Corrupted Sentinel", "*pulls himself up, corruption flickering but not reasserting* Thank you. I will hold this bridge — but as a guardian, not a jailer. If anyone crosses who needs help, I'll send them your way.")
	if not is_inside_tree(): return
	
	await DialogueManager.say("Corrupted Sentinel", "*presses the blade into Kaelen's hands* Take the blade. It's yours now. And... if the corruption takes me again, if I lose myself and become the monster once more — don't hesitate next time. Promise me that.")
	if not is_inside_tree(): return
	
	await DialogueManager.say("Kaelen", "...I promise. But I think you're stronger than you know.")
	if not is_inside_tree(): return
	
	var has_elara = GameManager.story_flags.get("ch1_elara_trusted", false) or GameManager.story_flags.get("ch1_elara_cautious", false)
	if has_elara:
		await DialogueManager.say("Elara", "*wiping her eyes, smiling through tears* ...That was the bravest thing I've ever seen anyone do in this world. Most people don't even see the NPCs as people. You just gave one his life back.")
		if not is_inside_tree(): return
		GameManager.relationships["elara"] = GameManager.relationships.get("elara", 0) + 15
	else:
		await DialogueManager.say("Kaelen (Internal)", "No one to tell me whether that was brave or stupid. But the way his hand stopped trembling when I pulled him up... that's not something a 'corrupted process' does. That's a person remembering what hope feels like.", Color(0.5, 0.9, 1.0))
		if not is_inside_tree(): return

	# System reaction — the world acknowledges mercy
	await DialogueManager.say("System", "[CORRUPTED SENTINEL: DIRECTIVE SUSPENDED]\n[Status: UNBOUND — Free Agent]\n[Corruption: Contained but present]\n[The bridge is now open. The knight remembers your name.]", Color(0.0, 1.0, 0.5), true)
	if not is_inside_tree(): return
	
	await DialogueManager.say("Kaelen (Internal)", "One person freed from one loop. In a world with thousands of loops and millions of trapped souls, it's barely a drop in the ocean. But it's a start. And starts matter.", Color(0.5, 0.9, 1.0))
	if not is_inside_tree(): return
	
	DialogueManager.hide_dialogue()

func _kill_knight() -> void:
	## Player kills the knight — pragmatic/dark path, more corruption, haunting consequences
	GameManager.set_story_flag("ch1_knight_killed", true)
	GameManager.add_glitch_corruption(5.0)
	print("[CHOICE] Player killed the Tutorial Knight. Corruption +5%%")
	if has_node("/root/ChoiceConsequences"):
		ChoiceConsequences.apply_choice_buff("ch1_knight_killed")
	
	await DialogueManager.say("Kaelen", "*grips the sword tighter, voice flat* ...You said it yourself. The corruption will come back. Minutes, maybe. And then another four hundred cycles of this. Another four hundred people forced to fight you, hurt you, kill you, and you come back and do it all again.")
	if not is_inside_tree(): return
	
	await DialogueManager.say("Kaelen", "I'm not going to let that happen. Not to you, and not to the next traveler who walks across this bridge. This ends now.")
	if not is_inside_tree(): return
	
	await DialogueManager.say("Corrupted Sentinel", "*closes his eyes, a strange peace settling over his glitching features* ...Thank you. I hoped you'd say that. Not because I want to die — because for the first time in four hundred cycles, the choice is mine. And I choose... to stop.")
	if not is_inside_tree(): return
	
	# The strike
	DialogueManager.hide_dialogue()
	await get_tree().create_timer(1.0).timeout
	if not is_inside_tree(): return
	
	# Camera shake + flash for the killing blow
	if camera:
		var shake_tween = create_tween()
		shake_tween.tween_property(camera, "offset", Vector2(-15, 0), 0.03)
		shake_tween.tween_property(camera, "offset", Vector2(15, 0), 0.03)
		shake_tween.tween_property(camera, "offset", Vector2(0, -10), 0.03)
		shake_tween.tween_property(camera, "offset", Vector2.ZERO, 0.1)
	
	# Boss visual shatters
	if boss:
		var shatter_tween = create_tween()
		shatter_tween.tween_property(boss, "modulate:a", 0.0, 1.5)
	
	await get_tree().create_timer(2.0).timeout
	if not is_inside_tree(): return
	
	await DialogueManager.say("Corrupted Sentinel", "*as his form dissolves into fragments of light* ...my name... was Aldric. Before the corruption. Before the loop. I was a guardian named Aldric... and I chose to rest.")
	if not is_inside_tree(): return
	
	await DialogueManager.say("Kaelen (Internal)", "Aldric. He had a name. Not 'Corrupted Sentinel,' not 'Tutorial Knight,' not 'Boss #1.' A name. Aldric. And now there's nothing left of him but fragments of light and a blade that still carries his weight.", Color(0.5, 0.9, 1.0))
	if not is_inside_tree(): return
	
	# System reaction — corruption spike
	await DialogueManager.say("System", "[ENTITY TERMINATED: CORRUPTED_SENTINEL_01 (ALDRIC)]\n[Process fully purged — NO RESPAWN]\n[CORRUPTION +5% — Forceful termination detected]\n[Warning: The System Administrator has been notified of entity deletion]", Color(1.0, 0.3, 0.0), true)
	if not is_inside_tree(): return
	
	var has_elara = GameManager.story_flags.get("ch1_elara_trusted", false) or GameManager.story_flags.get("ch1_elara_cautious", false)
	if has_elara:
		await DialogueManager.say("Elara", "*long silence, looking at the space where the knight stood* ...You did what he asked. That's not nothing. But, Kaelen — the System noticed. Deleting an entity isn't the same as defeating one. It leaves a scar in the code that draws attention.")
		if not is_inside_tree(): return
		await DialogueManager.say("Elara", "...I'm not judging you. I'm just... making sure you know what it costs.")
		if not is_inside_tree(): return
		GameManager.relationships["elara"] = GameManager.relationships.get("elara", 0) - 5
	else:
		await DialogueManager.say("Kaelen (Internal)", "Nobody here to tell me I did the wrong thing. Or the right thing. Just silence where Aldric used to be — and a corruption spike that says the System doesn't care about mercy, only deletion. I'll carry this one alone.", Color(0.5, 0.9, 1.0))
		if not is_inside_tree(): return
	
	await DialogueManager.say("Kaelen (Internal)", "Aldric is gone. Really gone. Not looping, not resetting, not waiting for the next cycle. Just... gone. I freed him the only way I could. But the System flagged it as destruction, not mercy. And the corruption in my own data just jumped. There's always a price.", Color(0.5, 0.9, 1.0))
	if not is_inside_tree(): return
	
	DialogueManager.hide_dialogue()

func _purge_knight() -> void:
	## Player attempts to purge the corruption with Root Access — risky/creative path
	GameManager.set_story_flag("ch1_knight_spared", true)
	GameManager.set_story_flag("ch1_root_purge", true)
	GameManager.add_glitch_corruption(8.0)
	print("[CHOICE] Player attempted Root Access purge on knight. Corruption +8%%")
	if has_node("/root/ChoiceConsequences"):
		ChoiceConsequences.apply_choice_buff("ch1_root_purge_used")
	
	await DialogueManager.say("Kaelen", "There's a third option. If I can disable your attack directive, maybe I can go deeper. Strip the corruption out of your code entirely. Not just disable it — REMOVE it.")
	if not is_inside_tree(): return
	
	await DialogueManager.say("Corrupted Sentinel", "*alarm and hope warring in his voice* That's... that's never been attempted. The corruption is woven into my core processes. Trying to remove it could crash my entire entity. Or worse — spread it to YOU.")
	if not is_inside_tree(): return
	
	await DialogueManager.say("Kaelen", "I was a systems architect for AetherCorp. I spent ten years debugging systems that other engineers said were unfixable. *cracks knuckles* Let me try.")
	if not is_inside_tree(): return
	
	# Show Root Access panel briefly as a visual
	root_access_panel.visible = true
	await get_tree().create_timer(0.5).timeout
	if not is_inside_tree(): return
	
	await DialogueManager.say("System", "[ROOT ACCESS: DEEP SCAN — CORRUPTED_SENTINEL_01]\n[Corruption threads found: 847]\n[Core integrity: 23%]\n[WARNING: Deep purge will cause MASSIVE corruption blowback]\n[CORRUPTION +8% if proceeding]", Color(1.0, 0.0, 0.0), true)
	if not is_inside_tree(): return
	
	root_access_panel.visible = false
	
	# Kaelen pushes through anyway
	await DialogueManager.say("Kaelen (Internal)", "847 corruption threads. Woven through every function, every subroutine, every memory he has. This is going to hurt. Both of us. But if I can pull this off...", Color(0.5, 0.9, 1.0))
	if not is_inside_tree(): return
	
	# Major camera shake + glitch effects during the purge
	if camera:
		var shake_tween = create_tween()
		for i in range(8):
			shake_tween.tween_property(camera, "offset", Vector2(randf_range(-10, 10), randf_range(-10, 10)), 0.05)
		shake_tween.tween_property(camera, "offset", Vector2.ZERO, 0.1)
	
	await get_tree().create_timer(1.5).timeout
	if not is_inside_tree(): return
	
	# Partial success — corruption reduced but not eliminated
	await DialogueManager.say("Corrupted Sentinel", "*screaming, then gasping as the corruption loosens its grip* I can... I can THINK. The whispers... they're quieter! Not gone, but... I can hear my OWN thoughts over them for the first time in cycles!")
	if not is_inside_tree(): return
	
	await DialogueManager.say("Kaelen", "*wiping blood from his nose — the corruption blowback hit hard* I couldn't get all of it. 847 threads — I cleared maybe 600. The rest are too deep, too intertwined with your core processes. Pulling them would erase your memories.")
	if not is_inside_tree(): return
	
	await DialogueManager.say("Corrupted Sentinel", "*stands tall, less corruption flickering across his armor* You gave me back my mind. Not all of it — but enough. Enough to remember that my name is Aldric. Enough to CHOOSE. *salutes* I will guard this bridge as Aldric, not as a corrupted puppet. You have my word.")
	if not is_inside_tree(): return
	
	# System reaction
	await DialogueManager.say("System", "[ROOT ACCESS DEEP PURGE: PARTIAL SUCCESS]\n[Corruption threads removed: 623/847]\n[Entity status: RECOVERING — Directive: SELF-DETERMINED]\n[CORRUPTION +8% — Blowback absorbed by user]\n[WARNING: System Administrator attention SIGNIFICANTLY increased]", Color(1.0, 0.6, 0.0), true)
	if not is_inside_tree(): return
	
	var has_elara = GameManager.story_flags.get("ch1_elara_trusted", false) or GameManager.story_flags.get("ch1_elara_cautious", false)
	if has_elara:
		await DialogueManager.say("Elara", "*staring at Kaelen with a mix of awe and fear* You just... reached into a corrupted entity and tore the corruption OUT. With your bare hands. I've never seen anyone do that. The cost was enormous, but...")
		if not is_inside_tree(): return
		await DialogueManager.say("Elara", "...Kaelen, do you understand what this means? If you can purge corruption from entities, you might be able to purge it from REGIONS. From the entire world. That's not just Root Access. That's... that's something else entirely.")
		if not is_inside_tree(): return
		GameManager.relationships["elara"] = GameManager.relationships.get("elara", 0) + 20
	else:
		await DialogueManager.say("Kaelen (Internal)", "I just ripped 623 corruption threads out of a living being with my bare hands. My nose is bleeding and I can taste copper. But if I can do this to ONE entity... what about a whole region? What about the entire world? The cost nearly killed me — but the POSSIBILITY...", Color(0.5, 0.9, 1.0))
		if not is_inside_tree(): return
	
	await DialogueManager.say("Kaelen (Internal)", "Eight percent corruption. My vision is blurry and there's a ringing in my ears that won't stop. But Aldric is standing under his own power, looking at the sky like he's seeing it for the first time. That's worth eight percent. That's worth a lot more than eight percent.", Color(0.5, 0.9, 1.0))
	if not is_inside_tree(): return
	
	DialogueManager.hide_dialogue()

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
