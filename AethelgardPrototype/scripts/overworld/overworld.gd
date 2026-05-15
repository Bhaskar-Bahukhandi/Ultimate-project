extends Node2D
## ==========================================================================
## OVERWORLD — Top-down world map connecting all three regions
## ==========================================================================
## The player walks freely across the overworld to travel between regions.
## Random encounters trigger while walking through non-safe zones.
## Region entrances are Area2D triggers that load the full region scene.
## ==========================================================================

const REGION_SCENES: Dictionary = {
	"oakhaven": "res://scenes/regions/oakhaven_region.tscn",
	"ironhold": "res://scenes/regions/ironhold_region.tscn",
	"fractured_wastes": "res://scenes/regions/fractured_wastes_region.tscn",
}

# ── Region Gate Positions (where the player spawns when exiting a region) ──
const REGION_RETURN_POINTS: Dictionary = {
	"oakhaven": Vector2(400, 500),
	"ironhold": Vector2(2200, 400),
	"fractured_wastes": Vector2(1300, 1600),
}

# ── Zone boundaries on the overworld ──────────────────────────────────────
# Rect2 areas that map to encounter zones
const ZONE_RECTS: Array = [
	{"zone_id": "oakhaven_fields", "rect": Rect2(100, 300, 600, 500)},
	{"zone_id": "road_oakhaven_ironhold", "rect": Rect2(700, 200, 1200, 400)},
	{"zone_id": "ironhold_outskirts", "rect": Rect2(1900, 100, 600, 600)},
	{"zone_id": "road_ironhold_wastes", "rect": Rect2(900, 700, 800, 800)},
	{"zone_id": "fractured_wastes_outer", "rect": Rect2(800, 1300, 1000, 600)},
]

var _player: CharacterBody2D = null
var _camera: Camera2D = null
var _zone_label: Label = null
var _level_warning: Label = null
var _minimap_indicator: ColorRect = null

# Map boundaries
const MAP_SIZE: Vector2 = Vector2(3000, 2200)
const MAP_BOUNDARY_MARGIN: float = 40.0


func _ready() -> void:
	GameManager.change_state(GameManager.GameState.EXPLORATION)

	_build_overworld_environment()
	_spawn_player()
	_create_region_gates()
	_create_zone_label_ui()
	_create_landmarks()

	# Check if returning from a region
	if GameManager.has_meta("return_to_overworld_from"):
		var from_region: String = GameManager.get_meta("return_to_overworld_from")
		GameManager.remove_meta("return_to_overworld_from")
		if REGION_RETURN_POINTS.has(from_region) and _player:
			_player.global_position = REGION_RETURN_POINTS[from_region]

	# Check if returning from combat encounter
	if GameManager.has_meta("return_position") and _player:
		_player.global_position = GameManager.get_meta("return_position")
		GameManager.remove_meta("return_position")


func _process(_delta: float) -> void:
	if not _player:
		return
	_update_zone_from_position(_player.global_position)
	_clamp_player_to_bounds()
	_update_zone_label()


## ═══════════════════════════════════════════════════════════════════════════
## ENVIRONMENT BUILDING — Procedural overworld map
## ═══════════════════════════════════════════════════════════════════════════

func _build_overworld_environment() -> void:
	# Sky/background
	var bg = ColorRect.new()
	bg.name = "Background"
	bg.color = Color(0.18, 0.25, 0.15)  # Dark green grass base
	bg.size = MAP_SIZE
	bg.position = Vector2.ZERO
	bg.z_index = -10
	add_child(bg)

	# ── Oakhaven Region Area (NW) — Pastoral greens ──
	var oakhaven_area = ColorRect.new()
	oakhaven_area.name = "OakhavenArea"
	oakhaven_area.color = Color(0.25, 0.45, 0.18)  # Bright green fields
	oakhaven_area.size = Vector2(700, 600)
	oakhaven_area.position = Vector2(50, 200)
	oakhaven_area.z_index = -9
	add_child(oakhaven_area)

	# Add some field detail
	for i in range(8):
		var field = ColorRect.new()
		field.color = Color(0.3, 0.5, 0.2, 0.4)
		field.size = Vector2(randi_range(40, 100), randi_range(30, 60))
		field.position = Vector2(randi_range(80, 650), randi_range(250, 700))
		field.z_index = -8
		add_child(field)

	# ── Road from Oakhaven to Ironhold (horizontal) ──
	var road_oi = ColorRect.new()
	road_oi.name = "RoadOakhavenIronhold"
	road_oi.color = Color(0.35, 0.28, 0.2)  # Dirt path
	road_oi.size = Vector2(1300, 60)
	road_oi.position = Vector2(700, 380)
	road_oi.z_index = -7
	add_child(road_oi)

	# Road markers / path stones
	for i in range(12):
		var stone = ColorRect.new()
		stone.color = Color(0.4, 0.35, 0.28)
		stone.size = Vector2(8, 8)
		stone.position = Vector2(750 + i * 100, 405)
		stone.z_index = -6
		add_child(stone)

	# ── Ironhold Region Area (E) — Industrial browns/grays ──
	var ironhold_area = ColorRect.new()
	ironhold_area.name = "IronholdArea"
	ironhold_area.color = Color(0.3, 0.25, 0.22)  # Industrial brown
	ironhold_area.size = Vector2(700, 600)
	ironhold_area.position = Vector2(2000, 50)
	ironhold_area.z_index = -9
	add_child(ironhold_area)

	# Gear/industrial detail
	for i in range(5):
		var gear = ColorRect.new()
		gear.color = Color(0.4, 0.35, 0.3, 0.5)
		gear.size = Vector2(randi_range(20, 50), randi_range(20, 50))
		gear.position = Vector2(randi_range(2050, 2600), randi_range(100, 550))
		gear.z_index = -8
		add_child(gear)

	# ── Road from Ironhold to Wastes (diagonal/vertical) ──
	var road_iw = ColorRect.new()
	road_iw.name = "RoadIronholdWastes"
	road_iw.color = Color(0.3, 0.22, 0.18)  # Darker dirt
	road_iw.size = Vector2(60, 900)
	road_iw.position = Vector2(1280, 600)
	road_iw.z_index = -7
	add_child(road_iw)

	# ── Fractured Wastes Area (S) — Purple/corrupted ──
	var wastes_area = ColorRect.new()
	wastes_area.name = "WastesArea"
	wastes_area.color = Color(0.25, 0.12, 0.3)  # Corrupted purple
	wastes_area.size = Vector2(1100, 700)
	wastes_area.position = Vector2(750, 1300)
	wastes_area.z_index = -9
	add_child(wastes_area)

	# Corruption veins / glitch patches
	for i in range(10):
		var vein = ColorRect.new()
		vein.color = Color(0.5, 0.1, 0.6, 0.6)
		vein.size = Vector2(randi_range(15, 80), randi_range(3, 12))
		vein.rotation = randf_range(-0.5, 0.5)
		vein.position = Vector2(randi_range(800, 1700), randi_range(1350, 1900))
		vein.z_index = -8
		add_child(vein)

	# ── Trees & Forest (along roads and area borders) ──
	_spawn_trees(Vector2(300, 150), Vector2(600, 200), 15, Color(0.15, 0.35, 0.12))  # Oakhaven north
	_spawn_trees(Vector2(650, 250), Vector2(400, 120), 10, Color(0.18, 0.32, 0.14))  # Before road
	_spawn_trees(Vector2(1800, 100), Vector2(200, 500), 12, Color(0.2, 0.28, 0.15))  # Mid map
	_spawn_trees(Vector2(700, 1200), Vector2(1000, 100), 8, Color(0.2, 0.15, 0.25))  # Wastes border

	# ── Water Features ──
	var river = ColorRect.new()
	river.name = "River"
	river.color = Color(0.15, 0.3, 0.55, 0.8)
	river.size = Vector2(25, 600)
	river.position = Vector2(1600, 0)
	river.z_index = -6
	add_child(river)

	# Bridge over river on the road
	var bridge = ColorRect.new()
	bridge.name = "Bridge"
	bridge.color = Color(0.45, 0.35, 0.25)
	bridge.size = Vector2(80, 70)
	bridge.position = Vector2(1570, 370)
	bridge.z_index = -5
	add_child(bridge)


func _spawn_trees(origin: Vector2, area: Vector2, count: int, color: Color) -> void:
	for i in range(count):
		var tree = ColorRect.new()
		tree.color = color
		tree.size = Vector2(randi_range(16, 28), randi_range(16, 28))
		tree.position = origin + Vector2(randf() * area.x, randf() * area.y)
		tree.z_index = -4
		# Tree trunk
		var trunk = ColorRect.new()
		trunk.color = Color(0.35, 0.22, 0.12)
		trunk.size = Vector2(4, 8)
		trunk.position = Vector2(tree.size.x / 2 - 2, tree.size.y)
		tree.add_child(trunk)
		add_child(tree)


## ═══════════════════════════════════════════════════════════════════════════
## PLAYER SPAWNING
## ═══════════════════════════════════════════════════════════════════════════

func _spawn_player() -> void:
	# Use the top-down player controller
	var player_script = load("res://scripts/exploration/player_topdown.gd")
	if not player_script:
		push_error("[OVERWORLD] Failed to load player_topdown.gd")
		return

	_player = CharacterBody2D.new()
	_player.name = "Player"
	_player.set_script(player_script)

	# Procedural player sprite
	var body = ColorRect.new()
	body.name = "BodySprite"
	body.color = Color(0.2, 0.7, 0.9)  # Kaelen's cyan
	body.size = Vector2(20, 28)
	body.position = Vector2(-10, -28)
	_player.add_child(body)

	# Direction indicator
	var indicator = ColorRect.new()
	indicator.name = "DirectionIndicator"
	indicator.color = Color(0.9, 0.9, 0.2)
	indicator.size = Vector2(6, 6)
	indicator.position = Vector2(-3, -32)
	_player.add_child(indicator)

	_player.global_position = GameManager.player_overworld_position if GameManager.player_overworld_position != Vector2.ZERO else REGION_RETURN_POINTS.get("oakhaven", Vector2(400, 500))
	add_child(_player)

	# Camera follow
	_camera = Camera2D.new()
	_camera.name = "OverworldCamera"
	_camera.zoom = Vector2(1.8, 1.8)
	_camera.position_smoothing_enabled = true
	_camera.position_smoothing_speed = 5.0
	_camera.limit_left = 0
	_camera.limit_top = 0
	_camera.limit_right = int(MAP_SIZE.x)
	_camera.limit_bottom = int(MAP_SIZE.y)
	_player.add_child(_camera)


## ═══════════════════════════════════════════════════════════════════════════
## REGION GATES — Walk into these to enter a full region
## ═══════════════════════════════════════════════════════════════════════════

func _create_region_gates() -> void:
	_create_gate("OakhavenGate", Vector2(350, 480), Vector2(80, 50), "oakhaven",
		Color(0.3, 0.6, 0.2), "OAKHAVEN\n[F] Enter")
	_create_gate("IronholdGate", Vector2(2300, 320), Vector2(80, 50), "ironhold",
		Color(0.5, 0.35, 0.2), "IRONHOLD\n[F] Enter")
	_create_gate("WastesGate", Vector2(1280, 1500), Vector2(80, 50), "fractured_wastes",
		Color(0.45, 0.15, 0.55), "FRACTURED WASTES\n[F] Enter")


func _create_gate(gate_name: String, pos: Vector2, gate_size: Vector2, region_id: String,
		color: Color, label_text: String) -> void:
	var gate = Area2D.new()
	gate.name = gate_name
	gate.global_position = pos

	# Visual marker
	var marker = ColorRect.new()
	marker.name = "Marker"
	marker.color = color
	marker.size = gate_size
	marker.position = -gate_size / 2
	gate.add_child(marker)

	# Border/outline
	var border = ColorRect.new()
	border.name = "Border"
	border.color = Color(1, 1, 1, 0.6)
	border.size = gate_size + Vector2(4, 4)
	border.position = -(gate_size + Vector2(4, 4)) / 2
	border.z_index = -1
	gate.add_child(border)

	# Label
	var label = Label.new()
	label.name = "GateLabel"
	label.text = label_text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 10)
	label.add_theme_color_override("font_color", Color.WHITE)
	label.position = Vector2(-40, -gate_size.y / 2 - 30)
	gate.add_child(label)

	# Collision
	var shape = CollisionShape2D.new()
	var rect = RectangleShape2D.new()
	rect.size = gate_size + Vector2(20, 20)
	shape.shape = rect
	gate.add_child(shape)

	gate.set_meta("region_id", region_id)
	gate.body_entered.connect(_on_region_gate_entered.bind(gate))
	gate.body_entered.connect(_on_gate_body_entered.bind(gate))
	gate.body_exited.connect(_on_gate_body_exited.bind(gate))
	add_child(gate)

	# Recommended level indicator
	var rec_level = _get_recommended_level(region_id)
	if rec_level > 0:
		var rec_label = Label.new()
		rec_label.text = "Rec. Lv %d" % rec_level
		rec_label.add_theme_font_size_override("font_size", 8)
		rec_label.add_theme_color_override("font_color", Color(1, 1, 0.6))
		rec_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		rec_label.position = Vector2(-30, gate_size.y / 2 + 5)
		gate.add_child(rec_label)


func _get_recommended_level(region_id: String) -> int:
	match region_id:
		"oakhaven": return 1
		"ironhold": return 5
		"fractured_wastes": return 9
	return 1


func _on_region_gate_entered(body: Node2D, gate: Area2D) -> void:
	if not body.is_in_group("player"):
		return
	# Only enter if player presses interact
	if not Input.is_action_just_pressed("interact"):
		return
	var region_id: String = gate.get_meta("region_id", "")
	_enter_region(region_id)


## Actually called each frame while player overlaps gate — we check interact input
var _gate_overlap: Dictionary = {}

func _on_gate_body_entered(body: Node2D, gate: Area2D) -> void:
	if body.is_in_group("player"):
		_gate_overlap[gate.name] = gate

func _on_gate_body_exited(body: Node2D, gate: Area2D) -> void:
	if body.is_in_group("player"):
		_gate_overlap.erase(gate.name)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("interact"):
		# Check if player is near a rest point first
		if _near_rest_point and is_instance_valid(_near_rest_point):
			_rest_at_point()
			return
		# Check if player is near any region gate
		if _player and is_instance_valid(_player):
			for gate_name in _gate_overlap:
				var gate: Area2D = _gate_overlap[gate_name]
				if is_instance_valid(gate):
					var region_id: String = gate.get_meta("region_id", "")
					if not region_id.is_empty():
						_enter_region(region_id)
						return


func _rest_at_point() -> void:
	var point_name: String = _near_rest_point.get_meta("rest_name", "Rest Point")
	GameManager.rest_at_point(point_name)
	# Show visual feedback
	if has_node("/root/DialogueManager"):
		await DialogueManager.say("SYSTEM",
			"[SYSTEM RESTORE] Resting at %s...\nIntegrity and RAM fully restored.\nProgress saved." % point_name)
	# Heal VFX flash
	if _player and is_instance_valid(_player):
		var flash = ColorRect.new()
		flash.color = Color(0.3, 1.0, 0.5, 0.3)
		flash.size = Vector2(1280, 720)
		flash.position = _player.global_position - Vector2(640, 360)
		flash.z_index = 100
		add_child(flash)
		var tw = create_tween()
		tw.tween_property(flash, "modulate:a", 0.0, 0.8)
		tw.tween_callback(flash.queue_free)


func _enter_region(region_id: String) -> void:
	if not REGION_SCENES.has(region_id):
		push_error("[OVERWORLD] Unknown region: %s" % region_id)
		return

	# Save player overworld position before leaving
	if _player and is_instance_valid(_player):
		GameManager.player_overworld_position = _player.global_position

	var scene_path = REGION_SCENES[region_id]
	if not ResourceLoader.exists(scene_path):
		push_error("[OVERWORLD] Region scene not found: %s — aborting transition" % scene_path)
		return

	# Store where we came from so region can return us here
	GameManager.set_meta("entered_from_overworld", true)
	GameManager.set_meta("overworld_return_region", region_id)

	# Level warning for underleveled players
	var rec_level = _get_recommended_level(region_id)
	var player_level = GameManager.player_stats.get("level", 1)
	if player_level < rec_level - 2:
		# Show warning but don't block
		if has_node("/root/DialogueManager"):
			await DialogueManager.say("SYSTEM",
				"[WARNING] Area threat level exceeds current parameters.\nRecommended INTEGRITY level: %d | Current: %d\nProceeding may result in rapid system failure." % [rec_level, player_level])
			if not is_inside_tree(): return

	if has_node("/root/SceneTransitions"):
		SceneTransitions.change_scene(scene_path)
	else:
		get_tree().change_scene_to_file(scene_path)


## ═══════════════════════════════════════════════════════════════════════════
## ZONE TRACKING — Update encounter zone based on player position
## ═══════════════════════════════════════════════════════════════════════════

func _update_zone_from_position(pos: Vector2) -> void:
	if not has_node("/root/RandomEncounterSystem"):
		return

	var new_zone = ""
	for zone_def in ZONE_RECTS:
		var rect: Rect2 = zone_def["rect"]
		if rect.has_point(pos):
			new_zone = zone_def["zone_id"]
			break

	if new_zone.is_empty():
		new_zone = "overworld_wilderness"  # Default zone for unmapped areas

	if new_zone != RandomEncounterSystem.current_zone_id:
		RandomEncounterSystem.set_zone(new_zone)


func _clamp_player_to_bounds() -> void:
	if _player:
		_player.global_position.x = clampf(_player.global_position.x, MAP_BOUNDARY_MARGIN, MAP_SIZE.x - MAP_BOUNDARY_MARGIN)
		_player.global_position.y = clampf(_player.global_position.y, MAP_BOUNDARY_MARGIN, MAP_SIZE.y - MAP_BOUNDARY_MARGIN)


## ═══════════════════════════════════════════════════════════════════════════
## UI — Zone label and level recommendations
## ═══════════════════════════════════════════════════════════════════════════

func _create_zone_label_ui() -> void:
	var ui_layer = CanvasLayer.new()
	ui_layer.name = "OverworldUI"
	ui_layer.layer = 50
	add_child(ui_layer)

	# Zone name display
	_zone_label = Label.new()
	_zone_label.name = "ZoneLabel"
	_zone_label.text = ""
	_zone_label.add_theme_font_size_override("font_size", 14)
	_zone_label.add_theme_color_override("font_color", Color(0.9, 0.9, 0.8))
	_zone_label.position = Vector2(20, 60)
	ui_layer.add_child(_zone_label)

	# Level recommendation / warning
	_level_warning = Label.new()
	_level_warning.name = "LevelWarning"
	_level_warning.text = ""
	_level_warning.add_theme_font_size_override("font_size", 11)
	_level_warning.position = Vector2(20, 82)
	ui_layer.add_child(_level_warning)

	# Player stats HUD
	var stats_label = Label.new()
	stats_label.name = "StatsHUD"
	stats_label.add_theme_font_size_override("font_size", 11)
	stats_label.add_theme_color_override("font_color", Color(0.7, 0.9, 1.0))
	stats_label.position = Vector2(20, 10)
	ui_layer.add_child(stats_label)

	# Instructions
	var instructions = Label.new()
	instructions.name = "Instructions"
	instructions.text = "[WASD] Move  |  [Shift] Sprint  |  [F] Interact  |  [M] Map  |  [I] Status  |  [TAB] Data Vision"
	instructions.add_theme_font_size_override("font_size", 9)
	instructions.add_theme_color_override("font_color", Color(0.6, 0.6, 0.5))
	instructions.position = Vector2(250, 690)
	ui_layer.add_child(instructions)


func _update_zone_label() -> void:
	if not _zone_label or not has_node("/root/RandomEncounterSystem"):
		return

	var zone_name = RandomEncounterSystem.get_zone_name()
	_zone_label.text = zone_name

	var rec_level = RandomEncounterSystem.get_zone_recommended_level()
	var player_level = GameManager.player_stats.get("level", 1)

	if RandomEncounterSystem.is_safe_zone():
		_level_warning.text = "~ Safe Zone ~"
		_level_warning.add_theme_color_override("font_color", Color(0.4, 0.8, 0.4))
	elif player_level < rec_level - 2:
		_level_warning.text = "!! DANGER — Rec. Lv %d (You: Lv %d) !!" % [rec_level, player_level]
		_level_warning.add_theme_color_override("font_color", Color(1.0, 0.2, 0.2))
	elif player_level < rec_level:
		_level_warning.text = "Challenging — Rec. Lv %d" % rec_level
		_level_warning.add_theme_color_override("font_color", Color(1.0, 0.8, 0.2))
	else:
		_level_warning.text = "Rec. Lv %d" % rec_level
		_level_warning.add_theme_color_override("font_color", Color(0.6, 0.8, 0.6))

	# Update stats HUD
	var stats_hud = get_node_or_null("OverworldUI/StatsHUD")
	if stats_hud:
		stats_hud.text = "Lv %d  |  HP %d/%d  |  Gold %d  |  XP %d/%s" % [
			player_level,
			GameManager.player_stats.get("hp", 100),
			GameManager.player_stats.get("max_hp", 100),
			GameManager.player_stats.get("gold", 0),
			GameManager.player_stats.get("xp", 0),
			str(GameManager.get_xp_for_next_level()) if GameManager.get_xp_for_next_level() > 0 else "MAX",
		]


## ═══════════════════════════════════════════════════════════════════════════
## LANDMARKS — Visual points of interest on the overworld
## ═══════════════════════════════════════════════════════════════════════════

func _create_landmarks() -> void:
	# Oakhaven landmark — village icon
	_create_landmark("Oakhaven", Vector2(350, 450), Color(0.3, 0.7, 0.2), "Village")

	# Ironhold landmark — city icon
	_create_landmark("Ironhold", Vector2(2300, 280), Color(0.6, 0.4, 0.2), "City")

	# Fractured Wastes landmark — corrupted icon
	_create_landmark("Wastes", Vector2(1280, 1460), Color(0.6, 0.15, 0.7), "Corrupted")

	# Rest points along roads
	_create_rest_point("Roadside Camp", Vector2(1100, 380))
	_create_rest_point("Riverbank Rest", Vector2(1580, 350))
	_create_rest_point("Wasteland Outpost", Vector2(1260, 1050))


func _create_landmark(landmark_name: String, pos: Vector2, color: Color, subtext: String) -> void:
	var lm = Node2D.new()
	lm.name = landmark_name.replace(" ", "")
	lm.position = pos

	var icon = ColorRect.new()
	icon.color = color
	icon.size = Vector2(12, 12)
	icon.position = Vector2(-6, -6)
	lm.add_child(icon)

	var label = Label.new()
	label.text = landmark_name
	label.add_theme_font_size_override("font_size", 8)
	label.add_theme_color_override("font_color", Color.WHITE)
	label.position = Vector2(-20, -22)
	lm.add_child(label)

	add_child(lm)


func _create_rest_point(point_name: String, pos: Vector2) -> void:
	var rp = Area2D.new()
	rp.name = point_name.replace(" ", "")
	rp.position = pos

	# Campfire visual
	var fire = ColorRect.new()
	fire.color = Color(0.9, 0.5, 0.1)
	fire.size = Vector2(10, 10)
	fire.position = Vector2(-5, -5)
	rp.add_child(fire)

	var glow = ColorRect.new()
	glow.color = Color(1.0, 0.7, 0.2, 0.3)
	glow.size = Vector2(24, 24)
	glow.position = Vector2(-12, -12)
	glow.z_index = -1
	rp.add_child(glow)

	var label = Label.new()
	label.text = point_name + "\n[F] Rest"
	label.add_theme_font_size_override("font_size", 8)
	label.add_theme_color_override("font_color", Color(1.0, 0.9, 0.6))
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.position = Vector2(-30, -25)
	rp.add_child(label)

	var shape = CollisionShape2D.new()
	var circle = CircleShape2D.new()
	circle.radius = 30.0
	shape.shape = circle
	rp.add_child(shape)

	rp.set_meta("is_rest_point", true)
	rp.set_meta("rest_name", point_name)
	rp.body_entered.connect(_on_rest_point_entered.bind(rp))
	rp.body_exited.connect(_on_rest_point_exited.bind(rp))
	add_child(rp)

var _near_rest_point: Area2D = null

func _on_rest_point_entered(body: Node2D, rp: Area2D) -> void:
	if body.is_in_group("player"):
		_near_rest_point = rp

func _on_rest_point_exited(body: Node2D, rp: Area2D) -> void:
	if body.is_in_group("player") and _near_rest_point == rp:
		_near_rest_point = null
