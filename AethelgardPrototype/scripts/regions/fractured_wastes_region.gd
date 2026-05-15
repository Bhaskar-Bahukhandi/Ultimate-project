extends Node2D
## ==========================================================================
## FRACTURED WASTES REGION — Endgame corrupted zone with environmental hazards
## ==========================================================================
## Sub-zones: fractured_wastes_outer, fractured_wastes_core,
##            fractured_wastes_shelter (safe)
## Features: Corruption storms, Lyra recruitment, survivor shelter
## Boss: Data Wraith (Corrupted Core boss, rec Lv 7)
## ==========================================================================

const REGION_ID: String = "fractured_wastes"
const MAP_SIZE: Vector2 = Vector2(3000, 2600)

## Corruption storm config
const STORM_INTERVAL_MIN: float = 20.0
const STORM_INTERVAL_MAX: float = 45.0
const STORM_DURATION: float = 8.0
const STORM_DPS: int = 3  # damage per second during storm

const SUB_ZONES: Array = [
	{"zone_id": "fractured_wastes_shelter", "rect": Rect2(1200, 1800, 400, 300), "name": "Survivor Shelter"},
	{"zone_id": "fractured_wastes_outer", "rect": Rect2(100, 100, 2800, 1200), "name": "Outer Wastes"},
	{"zone_id": "fractured_wastes_core", "rect": Rect2(600, 1300, 1800, 500), "name": "Corrupted Core"},
	{"zone_id": "fractured_wastes_outer", "rect": Rect2(100, 1300, 500, 1200), "name": "Western Wastes"},
	{"zone_id": "fractured_wastes_outer", "rect": Rect2(2400, 1300, 500, 1200), "name": "Eastern Wastes"},
]

const NPC_DATA: Array = [
	{"name": "Lyra", "pos": Vector2(1350, 1900), "color": Color(0.6, 0.2, 0.7),
	 "dialogue": [
		"You shouldn't be out here. Nobody comes to the Wastes on purpose.",
		"I was a system admin once. Before the Administrator rewrote my permissions.",
		"The data wraiths... they're corrupted memories. Echoes of what this place used to be.",
		"You use Root Access? Maybe you can fix what I couldn't. I'll join you — if you'll have me.",
	]},
	{"name": "Survivor Kael", "pos": Vector2(1250, 1850), "color": Color(0.5, 0.45, 0.4),
	 "dialogue": ["Shelter holds. For now. The corruption eats a little more each cycle.", "Stock up before going deeper. The core... it fights back."]},
	{"name": "Memory Fragment (NPC)", "pos": Vector2(800, 600), "color": Color(0.7, 0.5, 0.8),
	 "dialogue": ["I... was... someone. Before the corruption. My name... was... [DATA LOST]", "Help... me... remember..."]},
	{"name": "Vagrant 0xDEAD", "pos": Vector2(2100, 500), "color": Color(0.3, 0.3, 0.35),
	 "dialogue": ["DEAD BEEF DEAD BEEF DEAD BEEF.", "Just kidding. I'm fine. Totally fine. The corruption hasn't affected me at ALL. DEAD BEEF."]},
]

const LORE_DATA: Array = [
	{"id": "wastes_lore_1", "pos": Vector2(500, 400), "title": "Fractured Monument",
	 "text": "HERE STOOD THE GREAT LIBRARY OF AETHELGARD. Destroyed in the First Corruption Event. All knowledge, lost. All memories, scattered. Only fragments remain."},
	{"id": "wastes_lore_2", "pos": Vector2(1500, 1500), "title": "Corrupted Terminal",
	 "text": "SYSTEM LOG: Corruption levels at 87%. Automated defenses offline. Data Wraith manifestation rate: increasing. Recommendation: EVACUATE. Status: IGNORED."},
	{"id": "wastes_lore_3", "pos": Vector2(2300, 800), "title": "Broken Signpost",
	 "text": "← IRONHOLD: 3 days travel\n→ THE CORE: DO NOT ENTER\n↓ SHELTER: Last safe point\n↑ NOTHING: Literally nothing up here anymore"},
	{"id": "wastes_lore_4", "pos": Vector2(1000, 1400), "title": "Etched Warning",
	 "text": "If you're reading this, turn back. The core consumes everything. I went in at Level 10 and barely survived. Bring potions. Bring friends. Bring luck."},
	{"id": "dev_signature_3", "pos": Vector2(2700, 2200), "title": "Developer Signature #3",
	 "text": "// This zone was going to have a weather system. Scope creep killed it. Ironic that corruption storms are what we ended up with instead. — K.V., Sprint 71"},
	{"id": "wastes_lore_5", "pos": Vector2(1600, 700), "title": "Memory Echo",
	 "text": "MEMORY PLAYBACK [CORRUPTED]: ...the children used to play here... flowers everywhere... before he changed the source code... before everything broke..."},
]

var _player: CharacterBody2D = null
var _camera: Camera2D = null
var _zone_label: Label = null
var _stats_hud: Label = null
var _storm_overlay: ColorRect = null
var _storm_timer: float = 0.0
var _storm_active: bool = false
var _storm_elapsed: float = 0.0
var _next_storm_delay: float = 30.0
var _corruption_particles: Array = []

var _current_interact: Dictionary = {}


func _ready() -> void:
	GameManager.change_state(GameManager.GameState.EXPLORATION)
	_next_storm_delay = randf_range(STORM_INTERVAL_MIN, STORM_INTERVAL_MAX)
	_build_environment()
	_spawn_player()
	_place_npcs()
	_place_lore_items()
	_place_boss_gate()
	_place_shops()
	_place_secrets()
	_create_overworld_exit()
	_create_ui()
	_create_storm_overlay()
	_spawn_ambient_corruption()

	if GameManager.has_meta("return_position") and _player:
		_player.global_position = GameManager.get_meta("return_position")
		GameManager.remove_meta("return_position")


func _process(delta: float) -> void:
	if not _player:
		return
	_update_zone(_player.global_position)
	_clamp_player()
	_update_ui()
	_process_storms(delta)
	_animate_corruption(delta)


## ═══════════════════════════════════════════════════════════════════════════
## ENVIRONMENT — Purple corrupted wasteland
## ═══════════════════════════════════════════════════════════════════════════

func _build_environment() -> void:
	# Ground — dark corrupted purple
	var bg = ColorRect.new()
	bg.color = Color(0.12, 0.08, 0.15)
	bg.size = MAP_SIZE
	bg.z_index = -20
	add_child(bg)

	# ── Outer Wastes — cracked ground, floating debris ──
	# Cracks
	for i in range(60):
		var crack = ColorRect.new()
		crack.color = Color(0.2, 0.1, 0.25, 0.6)
		var w = randi_range(2, 4)
		var h = randi_range(20, 80)
		if randi() % 2 == 0:
			crack.size = Vector2(h, w)
		else:
			crack.size = Vector2(w, h)
		crack.position = Vector2(randf_range(100, 2900), randf_range(100, 2500))
		crack.z_index = -19
		add_child(crack)

	# Corrupted crystal formations
	for i in range(25):
		var crystal = ColorRect.new()
		crystal.color = Color(0.5 + randf() * 0.2, 0.15, 0.6 + randf() * 0.2, 0.7)
		crystal.size = Vector2(randi_range(8, 20), randi_range(15, 40))
		crystal.position = Vector2(randf_range(150, 2850), randf_range(150, 2450))
		crystal.rotation = randf_range(-0.3, 0.3)
		crystal.z_index = -14
		add_child(crystal)

	# ── Corrupted Core (Center-lower) — pulsing purple ──
	var core_base = ColorRect.new()
	core_base.color = Color(0.18, 0.05, 0.22)
	core_base.size = Vector2(1800, 500)
	core_base.position = Vector2(600, 1300)
	core_base.z_index = -18
	add_child(core_base)
	# Core energy veins
	for i in range(30):
		var vein = ColorRect.new()
		vein.color = Color(0.6, 0.1, 0.8, 0.4 + randf() * 0.3)
		vein.size = Vector2(randi_range(30, 100), 2)
		vein.position = Vector2(randf_range(650, 2300), randf_range(1320, 1750))
		vein.z_index = -16
		add_child(vein)
		_corruption_particles.append(vein)

	# ── Survivor Shelter ──
	var shelter = ColorRect.new()
	shelter.color = Color(0.25, 0.2, 0.18)
	shelter.size = Vector2(400, 300)
	shelter.position = Vector2(1200, 1800)
	shelter.z_index = -18
	add_child(shelter)
	# Shelter walls
	var wall_left = ColorRect.new()
	wall_left.color = Color(0.35, 0.3, 0.25)
	wall_left.size = Vector2(10, 280)
	wall_left.position = Vector2(1200, 1810)
	wall_left.z_index = -15
	add_child(wall_left)
	var wall_right = ColorRect.new()
	wall_right.color = Color(0.35, 0.3, 0.25)
	wall_right.size = Vector2(10, 280)
	wall_right.position = Vector2(1590, 1810)
	wall_right.z_index = -15
	add_child(wall_right)
	var roof = ColorRect.new()
	roof.color = Color(0.3, 0.28, 0.22)
	roof.size = Vector2(420, 12)
	roof.position = Vector2(1190, 1798)
	roof.z_index = -14
	add_child(roof)
	# Campfire
	var fire = ColorRect.new()
	fire.color = Color(0.9, 0.5, 0.1)
	fire.size = Vector2(12, 12)
	fire.position = Vector2(1390, 1920)
	fire.z_index = -13
	add_child(fire)

	# ── Ruined structures in the wastes ──
	var ruins = [
		Vector2(400, 300), Vector2(2500, 400), Vector2(700, 800),
		Vector2(2200, 1100), Vector2(300, 1600), Vector2(2600, 1700),
	]
	for r_pos in ruins:
		_create_ruin(r_pos)

	# ── Connecting paths ──
	_create_path(Vector2(1400, 1300), Vector2(1400, 1800), 20)  # Core → Shelter
	_create_path(Vector2(600, 700), Vector2(600, 1300), 25)      # North → Core west


func _create_ruin(pos: Vector2) -> void:
	var base = ColorRect.new()
	base.color = Color(0.2, 0.15, 0.18)
	base.size = Vector2(randi_range(40, 80), randi_range(30, 50))
	base.position = pos
	base.z_index = -14
	add_child(base)
	# Broken wall
	var wall = ColorRect.new()
	wall.color = Color(0.25, 0.18, 0.22)
	wall.size = Vector2(randi_range(8, 15), randi_range(20, 40))
	wall.position = Vector2(randf_range(0, base.size.x - 15), -wall.size.y + 5)
	base.add_child(wall)


func _create_path(from: Vector2, to: Vector2, segments: int) -> void:
	for i in range(segments):
		var t = float(i) / float(segments)
		var pos = from.lerp(to, t)
		var stone = ColorRect.new()
		stone.color = Color(0.18, 0.12, 0.2)
		stone.size = Vector2(randi_range(8, 14), randi_range(8, 14))
		stone.position = pos + Vector2(randf_range(-5, 5), randf_range(-5, 5))
		stone.z_index = -17
		add_child(stone)


## ═══════════════════════════════════════════════════════════════════════════
## CORRUPTION STORMS — Environmental hazard
## ═══════════════════════════════════════════════════════════════════════════

func _create_storm_overlay() -> void:
	var layer = CanvasLayer.new()
	layer.name = "StormLayer"
	layer.layer = 45
	add_child(layer)
	_storm_overlay = ColorRect.new()
	_storm_overlay.color = Color(0.4, 0.05, 0.5, 0.0)
	_storm_overlay.size = Vector2(1280, 720)
	_storm_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(_storm_overlay)

func _process_storms(delta: float) -> void:
	if _storm_active:
		_storm_elapsed += delta
		# Pulse the overlay
		var pulse = 0.2 + sin(_storm_elapsed * 4.0) * 0.08
		_storm_overlay.color.a = pulse
		# Deal damage if outside shelter
		var in_shelter = _is_in_shelter()
		if not in_shelter and fmod(_storm_elapsed, 1.0) < delta:
			var ps = GameManager.player_stats
			var hp = ps.get("hp", 100)
			hp = max(1, hp - STORM_DPS)
			GameManager.player_stats["hp"] = hp
		# End storm
		if _storm_elapsed >= STORM_DURATION:
			_storm_active = false
			_storm_elapsed = 0.0
			_storm_overlay.color.a = 0.0
			_next_storm_delay = randf_range(STORM_INTERVAL_MIN, STORM_INTERVAL_MAX)
	else:
		_storm_timer += delta
		if _storm_timer >= _next_storm_delay:
			_storm_timer = 0.0
			_storm_active = true
			if has_node("/root/DialogueManager") and not _is_in_shelter():
				# Flash warning
				DialogueManager.say("ENVIRONMENT", "⚠ CORRUPTION STORM INCOMING — Seek shelter! ⚠")

func _is_in_shelter() -> bool:
	if not _player:
		return false
	var shelter_rect = Rect2(1200, 1800, 400, 300)
	return shelter_rect.has_point(_player.global_position)

func _spawn_ambient_corruption() -> void:
	# Floating corruption particles
	for i in range(20):
		var p = ColorRect.new()
		p.color = Color(0.5, 0.1, 0.6, 0.3 + randf() * 0.2)
		p.size = Vector2(randi_range(3, 7), randi_range(3, 7))
		p.position = Vector2(randf_range(100, 2900), randf_range(100, 2500))
		p.z_index = 5
		add_child(p)
		_corruption_particles.append(p)

func _animate_corruption(delta: float) -> void:
	for p in _corruption_particles:
		if is_instance_valid(p):
			p.position.y += sin(Time.get_ticks_msec() * 0.001 + p.position.x * 0.01) * delta * 8
			p.modulate.a = 0.3 + sin(Time.get_ticks_msec() * 0.002 + p.position.y * 0.01) * 0.15


## ═══════════════════════════════════════════════════════════════════════════
## PLAYER
## ═══════════════════════════════════════════════════════════════════════════

func _spawn_player() -> void:
	var player_script = load("res://scripts/exploration/player_topdown.gd")
	if not player_script:
		push_error("[WASTES] Failed to load player_topdown.gd")
		return
	_player = CharacterBody2D.new()
	_player.name = "Player"
	_player.set_script(player_script)

	var body = ColorRect.new()
	body.name = "BodySprite"
	body.color = Color(0.2, 0.7, 0.9)
	body.size = Vector2(20, 28)
	body.position = Vector2(-10, -28)
	_player.add_child(body)

	var indicator = ColorRect.new()
	indicator.name = "DirectionIndicator"
	indicator.color = Color(0.9, 0.9, 0.2)
	indicator.size = Vector2(6, 6)
	indicator.position = Vector2(-3, -32)
	_player.add_child(indicator)

	_player.global_position = Vector2(1400, 1900)  # Start at shelter
	add_child(_player)

	_camera = Camera2D.new()
	_camera.name = "RegionCamera"
	_camera.zoom = Vector2(2.2, 2.2)
	_camera.position_smoothing_enabled = true
	_camera.position_smoothing_speed = 5.0
	_camera.limit_left = 0
	_camera.limit_top = 0
	_camera.limit_right = int(MAP_SIZE.x)
	_camera.limit_bottom = int(MAP_SIZE.y)
	_player.add_child(_camera)


## ═══════════════════════════════════════════════════════════════════════════
## NPCs, LORE, SHOPS, BOSS GATE
## ═══════════════════════════════════════════════════════════════════════════

func _place_npcs() -> void:
	for data in NPC_DATA:
		add_child(_create_interactable_npc(data))

func _create_interactable_npc(data: Dictionary) -> Area2D:
	var npc = Area2D.new()
	npc.name = data["name"].replace(" ", "").replace("(", "").replace(")", "")
	npc.position = data["pos"]
	var body = ColorRect.new()
	body.color = data["color"]
	body.size = Vector2(16, 22)
	body.position = Vector2(-8, -22)
	npc.add_child(body)
	var name_label = Label.new()
	name_label.text = data["name"]
	name_label.add_theme_font_size_override("font_size", 8)
	name_label.add_theme_color_override("font_color", Color.WHITE)
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.position = Vector2(-30, -34)
	npc.add_child(name_label)
	var prompt = Label.new()
	prompt.name = "Prompt"
	prompt.text = "[F] Talk"
	prompt.add_theme_font_size_override("font_size", 7)
	prompt.add_theme_color_override("font_color", Color(1, 1, 0.7))
	prompt.position = Vector2(-15, 5)
	prompt.visible = false
	npc.add_child(prompt)
	var shape = CollisionShape2D.new()
	var circle = CircleShape2D.new()
	circle.radius = 45.0
	shape.shape = circle
	npc.add_child(shape)
	npc.set_meta("npc_name", data["name"])
	npc.set_meta("dialogue", data["dialogue"])
	npc.set_meta("dialogue_index", 0)
	# Special handling for Lyra recruitment
	if data["name"] == "Lyra":
		npc.set_meta("is_recruitable", true)
	npc.body_entered.connect(func(b): _on_interact_entered(b, npc, "npc"))
	npc.body_exited.connect(func(b): _on_interact_exited(b, npc, "npc"))
	return npc

func _place_lore_items() -> void:
	for data in LORE_DATA:
		add_child(_create_lore_marker(data))

func _create_lore_marker(data: Dictionary) -> Area2D:
	var lore = Area2D.new()
	lore.name = data["id"]
	lore.position = data["pos"]
	var glow = ColorRect.new()
	glow.color = Color(0.5, 0.15, 0.7, 0.5)
	glow.size = Vector2(10, 10)
	glow.position = Vector2(-5, -5)
	lore.add_child(glow)
	var icon = ColorRect.new()
	icon.color = Color(0.6, 0.2, 0.9)
	icon.size = Vector2(6, 6)
	icon.position = Vector2(-3, -3)
	lore.add_child(icon)
	var prompt = Label.new()
	prompt.name = "Prompt"
	prompt.text = "[F] Inspect"
	prompt.add_theme_font_size_override("font_size", 7)
	prompt.add_theme_color_override("font_color", Color(0.6, 0.3, 0.9))
	prompt.position = Vector2(-20, 10)
	prompt.visible = false
	lore.add_child(prompt)
	var shape = CollisionShape2D.new()
	var circle = CircleShape2D.new()
	circle.radius = 30.0
	shape.shape = circle
	lore.add_child(shape)
	lore.set_meta("lore_id", data["id"])
	lore.set_meta("lore_title", data["title"])
	lore.set_meta("lore_text", data["text"])
	lore.body_entered.connect(func(b): _on_interact_entered(b, lore, "lore"))
	lore.body_exited.connect(func(b): _on_interact_exited(b, lore, "lore"))
	return lore

func _place_shops() -> void:
	_create_shop("SurvivorShop", Vector2(1300, 1860), "general")

func _create_shop(shop_name: String, pos: Vector2, shop_type: String) -> void:
	var trigger = Area2D.new()
	trigger.name = shop_name
	trigger.position = pos
	var shape = CollisionShape2D.new()
	var rect = RectangleShape2D.new()
	rect.size = Vector2(40, 30)
	shape.shape = rect
	trigger.add_child(shape)
	trigger.set_meta("shop_type", shop_type)
	trigger.body_entered.connect(func(b): _on_interact_entered(b, trigger, "shop"))
	trigger.body_exited.connect(func(b): _on_interact_exited(b, trigger, "shop"))
	add_child(trigger)

func _place_boss_gate() -> void:
	var gate = Area2D.new()
	gate.name = "DataWraithBossGate"
	gate.position = Vector2(1500, 1450)
	var marker = ColorRect.new()
	marker.color = Color(0.5, 0.1, 0.6)
	marker.size = Vector2(50, 50)
	marker.position = Vector2(-25, -25)
	gate.add_child(marker)
	var border = ColorRect.new()
	border.color = Color(0.7, 0.2, 0.9, 0.5)
	border.size = Vector2(56, 56)
	border.position = Vector2(-28, -28)
	border.z_index = -1
	gate.add_child(border)
	var label = Label.new()
	label.text = "Data Wraith\n[F] Challenge\nRec. Lv 7"
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 9)
	label.add_theme_color_override("font_color", Color(0.8, 0.5, 1.0))
	label.position = Vector2(-40, -55)
	gate.add_child(label)
	var shape = CollisionShape2D.new()
	var rect = RectangleShape2D.new()
	rect.size = Vector2(60, 60)
	shape.shape = rect
	gate.add_child(shape)
	gate.set_meta("boss_id", "data_wraith")
	gate.set_meta("rec_level", 7)
	gate.set_meta("scene_path", "res://scenes/combat/combat_arena.tscn")
	gate.body_entered.connect(func(b): _on_interact_entered(b, gate, "boss"))
	gate.body_exited.connect(func(b): _on_interact_exited(b, gate, "boss"))
	add_child(gate)

	# ── SOVEREIGN boss gate (unlocks after Data Wraith defeat) ──
	if GameManager.get_story_flag("ch2_data_wraith_defeated"):
		var sov_gate = Area2D.new()
		sov_gate.name = "SovereignBossGate"
		sov_gate.position = Vector2(1800, 900)
		var sov_marker = ColorRect.new()
		sov_marker.color = Color(0.9, 0.8, 0.2)
		sov_marker.size = Vector2(64, 64)
		sov_marker.position = Vector2(-32, -32)
		sov_gate.add_child(sov_marker)
		var sov_border = ColorRect.new()
		sov_border.color = Color(1.0, 0.9, 0.4, 0.5)
		sov_border.size = Vector2(72, 72)
		sov_border.position = Vector2(-36, -36)
		sov_border.z_index = -1
		sov_gate.add_child(sov_border)
		var sov_label = Label.new()
		sov_label.text = "The Sovereign\n[F] Challenge\nRec. Lv 15"
		sov_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		sov_label.add_theme_font_size_override("font_size", 9)
		sov_label.add_theme_color_override("font_color", Color(1.0, 0.9, 0.3))
		sov_label.position = Vector2(-45, -65)
		sov_gate.add_child(sov_label)
		var sov_shape = CollisionShape2D.new()
		var sov_rect = RectangleShape2D.new()
		sov_rect.size = Vector2(70, 70)
		sov_shape.shape = sov_rect
		sov_gate.add_child(sov_shape)
		sov_gate.set_meta("boss_id", "sovereign")
		sov_gate.set_meta("rec_level", 15)
		sov_gate.set_meta("scene_path", "res://scenes/combat/combat_arena.tscn")
		sov_gate.body_entered.connect(func(b): _on_interact_entered(b, sov_gate, "boss"))
		sov_gate.body_exited.connect(func(b): _on_interact_exited(b, sov_gate, "boss"))
		add_child(sov_gate)


## ═══════════════════════════════════════════════════════════════════════════
## HIDDEN SECRETS — Discoverable pickups rewarding exploration
## ═══════════════════════════════════════════════════════════════════════════

const WASTES_SECRETS: Array = [
	{
		"id": "secret_wastes_null_edge", "pos": Vector2(400, 500),
		"flag": "secret_wastes_null_edge_found",
		"item": "null_edge", "xp_bonus": 120,
		"title": "VOID CACHE",
		"text": "A blade that severs data streams, abandoned where reality is thinnest. Its edge hums with null energy."
	},
	{
		"id": "secret_wastes_memory_mail", "pos": Vector2(2600, 1800),
		"flag": "secret_wastes_memory_mail_found",
		"item": "memory_weave_mail", "xp_bonus": 100,
		"title": "PURIFIED REMNANT",
		"text": "Behind the crumbling ruin, armor woven from purified memory fragments pulses with a calm light amid the chaos."
	},
	{
		"id": "secret_wastes_storm_cache", "pos": Vector2(1500, 300),
		"flag": "secret_wastes_storm_cache_found",
		"item": "glitch_stabilizer", "item_qty": 5, "xp_bonus": 80, "gold_bonus": 100,
		"title": "STORM SURVIVOR'S KIT",
		"text": "A reinforced container sealed against the corruption storms. Inside: stabilizers and emergency funds from a research team that never returned."
	},
]

func _place_secrets() -> void:
	for data in WASTES_SECRETS:
		if GameManager.get_story_flag(data["flag"]):
			continue
		var secret = _create_secret_pickup(data)
		add_child(secret)


func _create_secret_pickup(data: Dictionary) -> Area2D:
	var secret = Area2D.new()
	secret.name = data["id"]
	secret.position = data["pos"]

	var shimmer = ColorRect.new()
	shimmer.color = Color(0.7, 0.4, 0.9, 0.12)
	shimmer.size = Vector2(8, 8)
	shimmer.position = Vector2(-4, -4)
	secret.add_child(shimmer)

	var sparkle = ColorRect.new()
	sparkle.color = Color(0.8, 0.5, 1.0, 0.25)
	sparkle.size = Vector2(3, 3)
	sparkle.position = Vector2(-1.5, -1.5)
	secret.add_child(sparkle)

	var tween = secret.create_tween().set_loops()
	tween.tween_property(shimmer, "modulate:a", 0.4, 1.5).set_trans(Tween.TRANS_SINE)
	tween.tween_property(shimmer, "modulate:a", 0.1, 1.5).set_trans(Tween.TRANS_SINE)

	var shape = CollisionShape2D.new()
	var circle = CircleShape2D.new()
	circle.radius = 25.0
	shape.shape = circle
	secret.add_child(shape)

	secret.set_meta("secret_data", data)
	secret.body_entered.connect(func(b): _on_interact_entered(b, secret, "secret"))
	secret.body_exited.connect(func(b): _on_interact_exited(b, secret, "secret"))
	return secret


func _interact_secret(secret: Area2D) -> void:
	var data: Dictionary = secret.get_meta("secret_data", {})
	if data.is_empty():
		return

	GameManager.set_story_flag(data["flag"], true)

	var item_id: String = data.get("item", "")
	var item_qty: int = data.get("item_qty", 1)
	if not item_id.is_empty() and has_node("/root/Inventory"):
		Inventory.add_item(item_id, item_qty)

	var xp_bonus: int = data.get("xp_bonus", 0)
	var gold_bonus: int = data.get("gold_bonus", 0)
	if xp_bonus > 0:
		GameManager.add_xp(xp_bonus)
	if gold_bonus > 0:
		GameManager.add_gold(gold_bonus)

	if has_node("/root/VFXLibrary"):
		VFXLibrary.spawn("vfx_pickup_burst", secret.global_position, self)
	if has_node("/root/SFXManager"):
		SFXManager.play("secret_found")

	if has_node("/root/DialogueManager"):
		GameManager.change_state(GameManager.GameState.DIALOGUE)
		var msg: String = data.get("text", "You found a hidden secret!")
		if not item_id.is_empty():
			var iname = item_id.replace("_", " ").capitalize()
			if has_node("/root/Inventory") and Inventory.ITEMS.has(item_id):
				iname = Inventory.ITEMS[item_id]["name"]
			msg += "\n\n[Obtained: %s x%d]" % [iname, item_qty]
		if xp_bonus > 0:
			msg += "\n[+%d XP]" % xp_bonus
		if gold_bonus > 0:
			msg += "\n[+%d Gold]" % gold_bonus
		await DialogueManager.say(data.get("title", "SECRET"), msg)
		GameManager.change_state(GameManager.GameState.EXPLORATION)

	if has_node("/root/LoreJournal"):
		LoreJournal.record_find(data["id"], data.get("title", "Secret"), data.get("text", ""))

	_current_interact.erase("secret")
	secret.queue_free()


## ═══════════════════════════════════════════════════════════════════════════
## OVERWORLD EXIT
## ═══════════════════════════════════════════════════════════════════════════

func _create_overworld_exit() -> void:
	var exit = Area2D.new()
	exit.name = "OverworldExitSouth"
	exit.position = Vector2(1400, MAP_SIZE.y - 30)
	var marker = ColorRect.new()
	marker.color = Color(0.8, 0.7, 0.3, 0.6)
	marker.size = Vector2(200, 20)
	marker.position = Vector2(-100, -10)
	exit.add_child(marker)
	var label = Label.new()
	label.text = "↓ Overworld ↓"
	label.add_theme_font_size_override("font_size", 10)
	label.add_theme_color_override("font_color", Color(1, 1, 0.7))
	label.position = Vector2(-40, -25)
	exit.add_child(label)
	var shape = CollisionShape2D.new()
	var rect = RectangleShape2D.new()
	rect.size = Vector2(220, 40)
	shape.shape = rect
	exit.add_child(shape)
	exit.body_entered.connect(func(b): _on_overworld_exit(b))
	add_child(exit)

func _on_overworld_exit(body: Node2D) -> void:
	if body.is_in_group("player"):
		GameManager.set_meta("return_to_overworld_from", REGION_ID)
		if has_node("/root/SceneTransitions"):
			SceneTransitions.change_scene("res://scenes/overworld/overworld.tscn")


## ═══════════════════════════════════════════════════════════════════════════
## INTERACTION SYSTEM
## ═══════════════════════════════════════════════════════════════════════════

func _on_interact_entered(body: Node2D, target: Area2D, type: String) -> void:
	if body.is_in_group("player"):
		_current_interact[type] = target
		var prompt = target.get_node_or_null("Prompt")
		if prompt:
			prompt.visible = true

func _on_interact_exited(body: Node2D, target: Area2D, type: String) -> void:
	if body.is_in_group("player") and _current_interact.get(type) == target:
		_current_interact.erase(type)
		var prompt = target.get_node_or_null("Prompt")
		if prompt:
			prompt.visible = false


func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed("interact"):
		return
	if _current_interact.has("boss"):
		_interact_boss(_current_interact["boss"])
	elif _current_interact.has("npc"):
		_interact_npc(_current_interact["npc"])
	elif _current_interact.has("lore"):
		_interact_lore(_current_interact["lore"])
	elif _current_interact.has("shop"):
		_interact_shop(_current_interact["shop"])
	elif _current_interact.has("secret"):
		_interact_secret(_current_interact["secret"])


func _interact_npc(npc: Area2D) -> void:
	var npc_name: String = npc.get_meta("npc_name", "NPC")
	var dialogue: Array = npc.get_meta("dialogue", [])
	var idx: int = npc.get_meta("dialogue_index", 0)
	if dialogue.is_empty():
		return
	if has_node("/root/DialogueManager"):
		GameManager.change_state(GameManager.GameState.DIALOGUE)
		await DialogueManager.say(npc_name, dialogue[idx % dialogue.size()])
		npc.set_meta("dialogue_index", (idx + 1) % dialogue.size())
		# Lyra recruitment at end of dialogue
		if npc.get_meta("is_recruitable", false) and idx >= dialogue.size() - 1:
			var choice = await DialogueManager.show_choices("Lyra offers to join your party.", ["Accept", "Not yet"])
			if choice == 0:
				GameManager.set_story_flag("ch3_lyra_recruited", true)
				await DialogueManager.say("Lyra", "Then let's fix this broken world. Together.")
		GameManager.change_state(GameManager.GameState.EXPLORATION)

func _interact_lore(lore: Area2D) -> void:
	var title: String = lore.get_meta("lore_title", "Unknown")
	var text: String = lore.get_meta("lore_text", "")
	var lore_id: String = lore.get_meta("lore_id", "")
	if has_node("/root/DialogueManager"):
		GameManager.change_state(GameManager.GameState.DIALOGUE)
		await DialogueManager.say(title, text)
		GameManager.change_state(GameManager.GameState.EXPLORATION)
	if lore_id.begins_with("dev_signature"):
		GameManager.set_story_flag(lore_id + "_found", true)

func _interact_shop(trigger: Area2D) -> void:
	var shop_type: String = trigger.get_meta("shop_type", "general")
	if has_node("/root/ShopSystem"):
		ShopSystem.open_shop(shop_type)

func _interact_boss(gate: Area2D) -> void:
	var boss_id: String = gate.get_meta("boss_id", "")
	var rec_level: int = gate.get_meta("rec_level", 1)
	var player_level = GameManager.player_stats.get("level", 1)

	if player_level < rec_level - 2:
		if has_node("/root/DialogueManager"):
			GameManager.change_state(GameManager.GameState.DIALOGUE)
			await DialogueManager.say("SYSTEM",
				"[CORRUPTION WARNING] Entity threat level extreme.\nThreat: Lv %d | You: Lv %d\nCorruption will likely overwhelm your systems." % [rec_level, player_level])
			var choice = await DialogueManager.show_choices("Proceed?", ["Enter (Death likely)", "Retreat"])
			GameManager.change_state(GameManager.GameState.EXPLORATION)
			if choice == 1:
				return

	GameManager.set_meta("return_position", _player.global_position if _player else Vector2(1400, 1900))
	GameManager.set_meta("boss_return_scene", "res://scenes/regions/fractured_wastes_region.tscn")
	GameManager.set_meta("boss_fight_id", boss_id)

	var scene_path: String = gate.get_meta("scene_path", "res://scenes/combat/combat_arena.tscn")
	if has_node("/root/SceneTransitions"):
		SceneTransitions.change_scene(scene_path, SceneTransitions.TransitionStyle.COMBAT_ENTRY)


## ═══════════════════════════════════════════════════════════════════════════
## ZONE TRACKING & UI
## ═══════════════════════════════════════════════════════════════════════════

func _update_zone(pos: Vector2) -> void:
	if not has_node("/root/RandomEncounterSystem"):
		return
	var new_zone = "fractured_wastes_outer"
	for zone_def in SUB_ZONES:
		if (zone_def["rect"] as Rect2).has_point(pos):
			new_zone = zone_def["zone_id"]
			break
	if new_zone != RandomEncounterSystem.current_zone_id:
		RandomEncounterSystem.set_zone(new_zone)

func _clamp_player() -> void:
	if _player:
		_player.global_position.x = clampf(_player.global_position.x, 20, MAP_SIZE.x - 20)
		_player.global_position.y = clampf(_player.global_position.y, 20, MAP_SIZE.y - 20)

func _create_ui() -> void:
	var ui_layer = CanvasLayer.new()
	ui_layer.name = "RegionUI"
	ui_layer.layer = 50
	add_child(ui_layer)
	_zone_label = Label.new()
	_zone_label.add_theme_font_size_override("font_size", 13)
	_zone_label.add_theme_color_override("font_color", Color(0.7, 0.4, 0.9))
	_zone_label.position = Vector2(20, 55)
	ui_layer.add_child(_zone_label)
	_stats_hud = Label.new()
	_stats_hud.add_theme_font_size_override("font_size", 11)
	_stats_hud.add_theme_color_override("font_color", Color(0.7, 0.9, 1.0))
	_stats_hud.position = Vector2(20, 10)
	ui_layer.add_child(_stats_hud)
	var title = Label.new()
	title.text = "~ THE FRACTURED WASTES ~"
	title.add_theme_font_size_override("font_size", 16)
	title.add_theme_color_override("font_color", Color(0.6, 0.2, 0.7))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.position = Vector2(540, 10)
	ui_layer.add_child(title)
	var instructions = Label.new()
	instructions.text = "[WASD] Move  [Shift] Sprint  [F] Interact  [M] Map  [I] Status"
	instructions.add_theme_font_size_override("font_size", 9)
	instructions.add_theme_color_override("font_color", Color(0.5, 0.4, 0.55))
	instructions.position = Vector2(250, 690)
	ui_layer.add_child(instructions)

func _update_ui() -> void:
	if _stats_hud:
		var ps = GameManager.player_stats
		_stats_hud.text = "Lv %d  |  HP %d/%d  |  Gold %d  |  XP %d/%s" % [
			ps.get("level", 1), ps.get("hp", 100), ps.get("max_hp", 100),
			ps.get("gold", 0), ps.get("xp", 0),
			str(GameManager.get_xp_for_next_level()) if GameManager.get_xp_for_next_level() > 0 else "MAX"
		]
		# Storm warning
		if _storm_active:
			_stats_hud.text += "  ⚡STORM⚡"
			if _is_in_shelter():
				_stats_hud.text += " (SHELTERED)"
	if _zone_label and has_node("/root/RandomEncounterSystem"):
		var zone_name = RandomEncounterSystem.get_zone_name()
		var rec = RandomEncounterSystem.get_zone_recommended_level()
		var plvl = GameManager.player_stats.get("level", 1)
		if RandomEncounterSystem.is_safe_zone():
			_zone_label.text = "%s  ☆ Safe Zone ☆" % zone_name
			_zone_label.add_theme_color_override("font_color", Color(0.4, 0.8, 0.4))
		elif plvl < rec - 2:
			_zone_label.text = "%s  ☠ LETHAL Lv %d ☠" % [zone_name, rec]
			_zone_label.add_theme_color_override("font_color", Color(1, 0.15, 0.3))
		else:
			_zone_label.text = "%s  (Lv %d)" % [zone_name, rec]
			_zone_label.add_theme_color_override("font_color", Color(0.7, 0.4, 0.9))
