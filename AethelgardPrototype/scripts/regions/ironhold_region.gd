extends Node2D
## ==========================================================================
## IRONHOLD REGION — Industrial city hub with districts, arena, underground
## ==========================================================================
## Merges: Ironhold Gate, City (5 districts), Arena, Underground, Clock Tower
## Sub-zones: ironhold_city (safe), ironhold_outskirts, ironhold_underground,
##            ironhold_clock_tower
## Bosses: Clockwork Automaton (Clock Tower), Administrator Proxy (Underground)
## ==========================================================================

const REGION_ID: String = "ironhold"
const MAP_SIZE: Vector2 = Vector2(3600, 2800)

const SUB_ZONES: Array = [
	{"zone_id": "ironhold_city", "rect": Rect2(1000, 800, 1000, 800), "name": "Ironhold City"},
	{"zone_id": "ironhold_outskirts", "rect": Rect2(200, 400, 800, 1000), "name": "Ironhold Outskirts"},
	{"zone_id": "ironhold_outskirts", "rect": Rect2(2000, 400, 800, 800), "name": "Eastern Outskirts"},
	{"zone_id": "ironhold_underground", "rect": Rect2(800, 1800, 1200, 600), "name": "Underground Network"},
	{"zone_id": "ironhold_clock_tower", "rect": Rect2(2800, 200, 600, 800), "name": "Clock Tower District"},
]

const NPC_DATA: Array = [
	{"name": "Vex the Announcer", "pos": Vector2(1800, 1000), "color": Color(0.7, 0.4, 0.2),
	 "dialogue": ["WELCOME to the ARENA! Where flesh meets steel and EVERYONE LOSES!", "Today's odds: You — 3 to 1 against! Place your bets, place your bets!"]},
	{"name": "Merchant Garro", "pos": Vector2(1200, 950), "color": Color(0.5, 0.45, 0.3),
	 "dialogue": ["Finest gear in Ironhold! Only slightly used. Previous owners? Don't ask.", "Steel Blade — cuts through clockwork like butter. Expensive butter."]},
	{"name": "Engineer Mira", "pos": Vector2(1500, 900), "color": Color(0.4, 0.5, 0.55),
	 "dialogue": ["The clock tower's been running backwards since last patch— I mean, last Tuesday.", "Don't go underground. The data wraiths down there... they speak in corrupted UTF-8."]},
	{"name": "Guard Captain Voss", "pos": Vector2(1100, 850), "color": Color(0.5, 0.45, 0.4),
	 "dialogue": ["The Administrator's proxies patrol the underground. Steer clear unless you're strong.", "Level 7 at minimum for the underground. Level 9 for the clock tower. You've been warned."]},
	{"name": "Beggar NPC_07", "pos": Vector2(1350, 1100), "color": Color(0.4, 0.38, 0.35),
	 "dialogue": ["Spare some gold? I used to be a quest-giver but they deprecated my quest line...", "I remember when I had collision boxes. Now people walk right through me."]},
	{"name": "Seraphina", "pos": Vector2(1600, 850), "color": Color(0.7, 0.5, 0.3),
	 "dialogue": ["You use Root Access? Hacking the world's code to win fights? That's... dishonorable.", "I fight with my own strength. The old way. Before they patched in shortcuts."]},
]

const LORE_DATA: Array = [
	{"id": "ironhold_lore_1", "pos": Vector2(1100, 1050), "title": "Market Notice",
	 "text": "NOTICE: All clockwork units must report for maintenance. Failure to comply will result in forcible decommission. — The Administrator"},
	{"id": "ironhold_lore_2", "pos": Vector2(2900, 400), "title": "Clock Tower Plaque",
	 "text": "THIS TOWER MEASURES THE HEARTBEAT OF AETHELGARD. When the gears stop, so does everything else. — Inscription, Author: Unknown (Redacted)"},
	{"id": "ironhold_lore_3", "pos": Vector2(900, 2000), "title": "Underground Graffiti",
	 "text": "THE ADMINISTRATOR SEES ALL. THE ADMINISTRATOR CONTROLS ALL. THE ADMINISTRATOR IS A LIE. — scratched into stone"},
	{"id": "ironhold_lore_4", "pos": Vector2(1700, 1200), "title": "Arena Records",
	 "text": "Champion Records: 1st — [DATA CORRUPTED], 2nd — [NULL REFERENCE], 3rd — Vex (disqualified for commentary during own match)"},
	{"id": "dev_signature_2", "pos": Vector2(2500, 1800), "title": "Developer Signature #2",
	 "text": "// The underground was supposed to have a stealth mechanic. Cut for scope. Sorry. — K.V., Sprint 63"},
]

var _player: CharacterBody2D = null
var _camera: Camera2D = null
var _zone_label: Label = null
var _stats_hud: Label = null
var _near_npc: Area2D = null
var _near_lore: Area2D = null
var _near_shop: Area2D = null
var _near_boss: Dictionary = {}  # gate_name -> Area2D


func _ready() -> void:
	GameManager.change_state(GameManager.GameState.EXPLORATION)
	_build_environment()
	_spawn_player()
	_place_npcs()
	_place_lore_items()
	_place_boss_gates()
	_place_shops()
	_place_arena_entrance()
	_place_secrets()
	_create_overworld_exit()
	_create_ui()

	if GameManager.has_meta("return_position") and _player:
		_player.global_position = GameManager.get_meta("return_position")
		GameManager.remove_meta("return_position")


func _process(_delta: float) -> void:
	if not _player:
		return
	_update_zone(_player.global_position)
	_clamp_player()
	_update_ui()


## ═══════════════════════════════════════════════════════════════════════════
## ENVIRONMENT
## ═══════════════════════════════════════════════════════════════════════════

func _build_environment() -> void:
	# Base ground — industrial gray-brown
	var bg = ColorRect.new()
	bg.color = Color(0.22, 0.2, 0.18)
	bg.size = MAP_SIZE
	bg.z_index = -20
	add_child(bg)

	# ── City Center ──
	var city = ColorRect.new()
	city.color = Color(0.3, 0.27, 0.23)
	city.size = Vector2(1000, 800)
	city.position = Vector2(1000, 800)
	city.z_index = -18
	add_child(city)

	# City buildings — dense block layout
	var building_positions = [
		Vector2(1050, 830), Vector2(1200, 830), Vector2(1350, 830), Vector2(1500, 830),
		Vector2(1650, 830), Vector2(1800, 830),
		Vector2(1050, 1050), Vector2(1250, 1050), Vector2(1450, 1050), Vector2(1650, 1050),
		Vector2(1100, 1250), Vector2(1300, 1250), Vector2(1500, 1250), Vector2(1700, 1250),
	]
	for i in range(building_positions.size()):
		var bpos = building_positions[i]
		var bsize = Vector2(randi_range(50, 80), randi_range(40, 60))
		var bcolor = Color(0.35 + randf() * 0.1, 0.3 + randf() * 0.08, 0.25 + randf() * 0.08)
		_create_building("Building_%d" % i, bpos, bsize, bcolor)

	# Cobblestone streets
	for i in range(50):
		var stone = ColorRect.new()
		stone.color = Color(0.28, 0.26, 0.24)
		stone.size = Vector2(randi_range(12, 20), randi_range(12, 20))
		stone.position = Vector2(randi_range(1010, 1950), randi_range(810, 1550))
		stone.z_index = -17
		add_child(stone)

	# ── Outskirts (West) — Industrial ruins ──
	var west_out = ColorRect.new()
	west_out.color = Color(0.2, 0.18, 0.16)
	west_out.size = Vector2(800, 1000)
	west_out.position = Vector2(200, 400)
	west_out.z_index = -18
	add_child(west_out)
	# Rusted machinery
	for i in range(8):
		var machine = ColorRect.new()
		machine.color = Color(0.4, 0.28, 0.15)
		machine.size = Vector2(randi_range(25, 55), randi_range(20, 40))
		machine.position = Vector2(randi_range(250, 900), randi_range(500, 1300))
		machine.z_index = -15
		add_child(machine)

	# ── Eastern Outskirts ──
	var east_out = ColorRect.new()
	east_out.color = Color(0.2, 0.18, 0.16)
	east_out.size = Vector2(800, 800)
	east_out.position = Vector2(2000, 400)
	east_out.z_index = -18
	add_child(east_out)

	# ── Underground Network (Below city) ──
	var underground = ColorRect.new()
	underground.color = Color(0.12, 0.1, 0.14)
	underground.size = Vector2(1200, 600)
	underground.position = Vector2(800, 1800)
	underground.z_index = -18
	add_child(underground)
	# Tunnel supports
	for i in range(10):
		var pillar = ColorRect.new()
		pillar.color = Color(0.2, 0.18, 0.22)
		pillar.size = Vector2(8, 40)
		pillar.position = Vector2(850 + i * 120, randi_range(1830, 2300))
		pillar.z_index = -16
		add_child(pillar)
	# Glowing data veins
	for i in range(15):
		var vein = ColorRect.new()
		vein.color = Color(0.2, 0.6, 0.8, 0.4)
		vein.size = Vector2(randi_range(30, 80), 3)
		vein.position = Vector2(randi_range(850, 1900), randi_range(1850, 2350))
		vein.z_index = -15
		add_child(vein)

	# ── Clock Tower District (NE) ──
	var tower_area = ColorRect.new()
	tower_area.color = Color(0.25, 0.22, 0.2)
	tower_area.size = Vector2(600, 800)
	tower_area.position = Vector2(2800, 200)
	tower_area.z_index = -18
	add_child(tower_area)
	# The Tower itself
	var tower = ColorRect.new()
	tower.color = Color(0.35, 0.3, 0.28)
	tower.size = Vector2(60, 200)
	tower.position = Vector2(3050, 300)
	tower.z_index = -12
	add_child(tower)
	var clock_face = ColorRect.new()
	clock_face.color = Color(0.8, 0.75, 0.5)
	clock_face.size = Vector2(30, 30)
	clock_face.position = Vector2(3065, 320)
	clock_face.z_index = -11
	add_child(clock_face)

	# ── Arena (East side of city) ──
	var arena = ColorRect.new()
	arena.color = Color(0.35, 0.25, 0.2)
	arena.size = Vector2(200, 180)
	arena.position = Vector2(1750, 950)
	arena.z_index = -14
	add_child(arena)
	# Arena seats
	for i in range(3):
		var seats = ColorRect.new()
		seats.color = Color(0.4, 0.3, 0.22)
		seats.size = Vector2(180, 10)
		seats.position = Vector2(1760, 960 + i * 50)
		seats.z_index = -13
		add_child(seats)

	# ── Connecting roads ──
	# West → City
	_create_road(Vector2(700, 900), Vector2(1000, 900), 30)
	# City → East
	_create_road(Vector2(2000, 1000), Vector2(2500, 700), 30)
	# City → Underground (stairs)
	_create_road(Vector2(1400, 1600), Vector2(1300, 1800), 20)
	# City → Clock Tower
	_create_road(Vector2(2000, 600), Vector2(2800, 500), 35)


func _create_building(bname: String, pos: Vector2, bsize: Vector2, color: Color) -> void:
	var building = ColorRect.new()
	building.name = bname
	building.color = color
	building.size = bsize
	building.position = pos
	building.z_index = -12
	add_child(building)
	# Roof
	var roof = ColorRect.new()
	roof.color = Color(color.r * 0.65, color.g * 0.6, color.b * 0.55)
	roof.size = Vector2(bsize.x + 4, 8)
	roof.position = Vector2(-2, -8)
	building.add_child(roof)
	# Window
	var win = ColorRect.new()
	win.color = Color(0.7, 0.65, 0.4, 0.6)
	win.size = Vector2(8, 8)
	win.position = Vector2(bsize.x / 2 - 4, 8)
	building.add_child(win)


func _create_road(from: Vector2, to: Vector2, segments: int) -> void:
	for i in range(segments):
		var t = float(i) / float(segments)
		var pos = from.lerp(to, t)
		var stone = ColorRect.new()
		stone.color = Color(0.3, 0.27, 0.23)
		stone.size = Vector2(randi_range(10, 16), randi_range(10, 16))
		stone.position = pos + Vector2(randf_range(-6, 6), randf_range(-6, 6))
		stone.z_index = -16
		add_child(stone)


## ═══════════════════════════════════════════════════════════════════════════
## PLAYER
## ═══════════════════════════════════════════════════════════════════════════

func _spawn_player() -> void:
	var player_script = load("res://scripts/exploration/player_topdown.gd")
	if not player_script:
		push_error("[IRONHOLD] Failed to load player_topdown.gd")
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

	_player.global_position = Vector2(1400, 1100)
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
## NPCs, LORE, SHOPS, BOSS GATES — Same pattern as Oakhaven
## ═══════════════════════════════════════════════════════════════════════════

func _place_npcs() -> void:
	for data in NPC_DATA:
		var npc = _create_interactable_npc(data)
		add_child(npc)

func _create_interactable_npc(data: Dictionary) -> Area2D:
	var npc = Area2D.new()
	npc.name = data["name"].replace(" ", "")
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
	npc.body_entered.connect(func(b): _on_interact_entered(b, npc, "npc"))
	npc.body_exited.connect(func(b): _on_interact_exited(b, npc, "npc"))
	return npc

func _place_lore_items() -> void:
	for data in LORE_DATA:
		var lore = _create_lore_marker(data)
		add_child(lore)

func _create_lore_marker(data: Dictionary) -> Area2D:
	var lore = Area2D.new()
	lore.name = data["id"]
	lore.position = data["pos"]
	var glow = ColorRect.new()
	glow.color = Color(0.3, 0.8, 1.0, 0.5)
	glow.size = Vector2(10, 10)
	glow.position = Vector2(-5, -5)
	lore.add_child(glow)
	var icon = ColorRect.new()
	icon.color = Color(0.4, 0.9, 1.0)
	icon.size = Vector2(6, 6)
	icon.position = Vector2(-3, -3)
	lore.add_child(icon)
	var prompt = Label.new()
	prompt.name = "Prompt"
	prompt.text = "[F] Inspect"
	prompt.add_theme_font_size_override("font_size", 7)
	prompt.add_theme_color_override("font_color", Color(0.4, 0.9, 1.0))
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
	_create_shop("Blacksmith", Vector2(1220, 960), "blacksmith")
	_create_shop("CharmDealer", Vector2(1500, 1050), "charm_dealer")
	_create_shop("Apothecary", Vector2(1350, 950), "apothecary")

func _create_shop(shop_name: String, pos: Vector2, shop_type: String) -> void:
	var trigger = Area2D.new()
	trigger.name = shop_name + "Shop"
	trigger.position = pos
	var shape = CollisionShape2D.new()
	var rect = RectangleShape2D.new()
	rect.size = Vector2(40, 30)
	shape.shape = rect
	trigger.add_child(shape)
	trigger.set_meta("shop_type", shop_type)
	trigger.set_meta("shop_name", shop_name)
	trigger.body_entered.connect(func(b): _on_interact_entered(b, trigger, "shop"))
	trigger.body_exited.connect(func(b): _on_interact_exited(b, trigger, "shop"))
	add_child(trigger)


func _place_boss_gates() -> void:
	# Clockwork Automaton — Clock Tower
	_create_boss_gate("ClockworkBossGate", Vector2(3050, 550),
		"clockwork_automaton", 9, "Clockwork Automaton\n[F] Challenge\nRec. Lv 9",
		"res://scenes/combat/combat_arena.tscn")
	# Administrator Proxy — Underground
	_create_boss_gate("AdminBossGate", Vector2(1300, 2100),
		"administrator_proxy", 11, "Administrator Proxy\n[F] Challenge\nRec. Lv 11",
		"res://scenes/chapter2/administrator_boss.tscn")

func _create_boss_gate(gate_name: String, pos: Vector2, boss_id: String,
		rec_level: int, label_text: String, scene_path: String) -> void:
	var gate = Area2D.new()
	gate.name = gate_name
	gate.position = pos
	var marker = ColorRect.new()
	marker.color = Color(0.7, 0.2, 0.2)
	marker.size = Vector2(50, 50)
	marker.position = Vector2(-25, -25)
	gate.add_child(marker)
	var border = ColorRect.new()
	border.color = Color(1, 0.3, 0.3, 0.5)
	border.size = Vector2(56, 56)
	border.position = Vector2(-28, -28)
	border.z_index = -1
	gate.add_child(border)
	var label = Label.new()
	label.text = label_text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 9)
	label.add_theme_color_override("font_color", Color(1, 0.85, 0.5))
	label.position = Vector2(-50, -50)
	gate.add_child(label)
	var shape = CollisionShape2D.new()
	var rect = RectangleShape2D.new()
	rect.size = Vector2(60, 60)
	shape.shape = rect
	gate.add_child(shape)
	gate.set_meta("boss_id", boss_id)
	gate.set_meta("rec_level", rec_level)
	gate.set_meta("scene_path", scene_path)
	gate.body_entered.connect(func(b): _on_interact_entered(b, gate, "boss"))
	gate.body_exited.connect(func(b): _on_interact_exited(b, gate, "boss"))
	add_child(gate)

func _place_arena_entrance() -> void:
	var arena_gate = Area2D.new()
	arena_gate.name = "ArenaEntrance"
	arena_gate.position = Vector2(1850, 1020)
	var marker = ColorRect.new()
	marker.color = Color(0.6, 0.4, 0.1)
	marker.size = Vector2(40, 30)
	marker.position = Vector2(-20, -15)
	arena_gate.add_child(marker)
	var label = Label.new()
	label.text = "ARENA\n[F] Enter"
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 9)
	label.add_theme_color_override("font_color", Color(1, 0.8, 0.3))
	label.position = Vector2(-20, -35)
	arena_gate.add_child(label)
	var shape = CollisionShape2D.new()
	var rect = RectangleShape2D.new()
	rect.size = Vector2(50, 40)
	shape.shape = rect
	arena_gate.add_child(shape)
	arena_gate.set_meta("is_arena", true)
	arena_gate.body_entered.connect(func(b): _on_interact_entered(b, arena_gate, "arena"))
	arena_gate.body_exited.connect(func(b): _on_interact_exited(b, arena_gate, "arena"))
	add_child(arena_gate)


## ═══════════════════════════════════════════════════════════════════════════
## HIDDEN SECRETS — Discoverable pickups rewarding exploration
## ═══════════════════════════════════════════════════════════════════════════

const IRONHOLD_SECRETS: Array = [
	{
		"id": "secret_iron_underground_blade", "pos": Vector2(2800, 2200),
		"flag": "secret_iron_underground_blade_found",
		"item": "steel_blade", "xp_bonus": 80,
		"title": "SMUGGLER'S STASH",
		"text": "A false wall in the underground passage conceals a finely-tempered steel blade, wrapped in oiled cloth."
	},
	{
		"id": "secret_iron_clocktower_mail", "pos": Vector2(3300, 400),
		"flag": "secret_iron_clocktower_mail_found",
		"item": "chain_mail", "xp_bonus": 60,
		"title": "WATCHMAN'S CACHE",
		"text": "Behind the Clock Tower's maintenance panel, chain mail hangs from a hook — the last watchman's emergency kit."
	},
	{
		"id": "secret_iron_market_gold", "pos": Vector2(1200, 1100),
		"flag": "secret_iron_market_gold_found",
		"item": "", "xp_bonus": 50, "gold_bonus": 150,
		"title": "MERCHANT'S HIDDEN VAULT",
		"text": "The loose cobblestone hides a merchant's emergency fund. Gold coins spill out, still warm from proximity to the forge."
	},
]

func _place_secrets() -> void:
	for data in IRONHOLD_SECRETS:
		if GameManager.get_story_flag(data["flag"]):
			continue
		var secret = _create_secret_pickup(data)
		add_child(secret)


func _create_secret_pickup(data: Dictionary) -> Area2D:
	var secret = Area2D.new()
	secret.name = data["id"]
	secret.position = data["pos"]

	var shimmer = ColorRect.new()
	shimmer.color = Color(0.9, 0.8, 0.4, 0.12)
	shimmer.size = Vector2(8, 8)
	shimmer.position = Vector2(-4, -4)
	secret.add_child(shimmer)

	var sparkle = ColorRect.new()
	sparkle.color = Color(1.0, 0.9, 0.5, 0.25)
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
	_create_exit("OverworldExitWest", Vector2(30, 900), Vector2(20, 200), true)
	_create_exit("OverworldExitNorth", Vector2(1800, 30), Vector2(200, 20), false)

func _create_exit(ename: String, pos: Vector2, esize: Vector2, vertical: bool) -> void:
	var exit = Area2D.new()
	exit.name = ename
	exit.position = pos
	var marker = ColorRect.new()
	marker.color = Color(0.8, 0.7, 0.3, 0.6)
	marker.size = esize
	marker.position = -esize / 2
	exit.add_child(marker)
	var label = Label.new()
	label.text = "← Overworld →" if vertical else "↑ Overworld ↑"
	label.add_theme_font_size_override("font_size", 10)
	label.add_theme_color_override("font_color", Color(1, 1, 0.7))
	label.position = Vector2(-40, -25)
	exit.add_child(label)
	var shape = CollisionShape2D.new()
	var rect = RectangleShape2D.new()
	rect.size = esize + Vector2(20, 20)
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
## UNIFIED INTERACTION SYSTEM
## ═══════════════════════════════════════════════════════════════════════════

var _current_interact: Dictionary = {}  # type -> Area2D

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

	# Priority: boss > arena > npc > lore > shop
	if _current_interact.has("boss"):
		_interact_boss(_current_interact["boss"])
	elif _current_interact.has("arena"):
		_interact_arena()
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

func _interact_arena() -> void:
	if not has_node("/root/DialogueManager"):
		return
	GameManager.change_state(GameManager.GameState.DIALOGUE)

	# Mode selection
	await DialogueManager.say("Vex", "Welcome to the ARENA! What's your pleasure, fighter?")
	var mode_choice = await DialogueManager.show_choices("Arena Mode:", [
		"Standard Tiers", "Time Attack", "Endurance", "Leave"
	])

	if mode_choice == 3:  # Leave
		GameManager.change_state(GameManager.GameState.EXPLORATION)
		return

	GameManager.set_meta("return_position", _player.global_position if _player else Vector2(1850, 1020))
	GameManager.set_meta("boss_return_scene", "res://scenes/regions/ironhold_region.tscn")

	if mode_choice == 2:  # Endurance
		GameManager.set_meta("arena_mode", "endurance")
	elif mode_choice == 1:  # Time Attack
		await DialogueManager.say("Vex", "Time Attack! Pick your bracket!")
		var tier_choice = await DialogueManager.show_choices("Tier:", ["Bronze", "Silver", "Gold", "Platinum"])
		var tiers = ["bronze", "silver", "gold", "platinum"]
		GameManager.set_meta("arena_mode", "time_attack")
		GameManager.set_meta("arena_tier", tiers[tier_choice])
	else:  # Standard
		await DialogueManager.say("Vex", "Standard rules! Pick your bracket!")
		var tier_choice = await DialogueManager.show_choices("Tier:", ["Bronze", "Silver", "Gold", "Platinum"])
		var tiers = ["bronze", "silver", "gold", "platinum"]
		GameManager.set_meta("arena_mode", "standard")
		GameManager.set_meta("arena_tier", tiers[tier_choice])

	GameManager.change_state(GameManager.GameState.EXPLORATION)
	if has_node("/root/SceneTransitions"):
		SceneTransitions.change_scene("res://scenes/chapter2/arena_district.tscn", SceneTransitions.TransitionStyle.COMBAT_ENTRY)

func _interact_boss(gate: Area2D) -> void:
	var boss_id: String = gate.get_meta("boss_id", "")
	var rec_level: int = gate.get_meta("rec_level", 1)
	var player_level = GameManager.player_stats.get("level", 1)

	# Soft gate warning
	if player_level < rec_level - 2:
		if has_node("/root/DialogueManager"):
			GameManager.change_state(GameManager.GameState.DIALOGUE)
			await DialogueManager.say("SYSTEM",
				"[CRITICAL WARNING] Hostile entity far exceeds parameters.\nThreat: Lv %d | You: Lv %d\nHigh probability of immediate system failure." % [rec_level, player_level])
			var choice = await DialogueManager.show_choices("Proceed?", ["Enter (Suicidal)", "Retreat"])
			GameManager.change_state(GameManager.GameState.EXPLORATION)
			if choice == 1:
				return

	GameManager.set_meta("return_position", _player.global_position if _player else Vector2(1400, 1100))
	GameManager.set_meta("boss_return_scene", "res://scenes/regions/ironhold_region.tscn")
	GameManager.set_meta("boss_fight_id", boss_id)

	var scene_path: String = gate.get_meta("scene_path", "")
	if scene_path.is_empty():
		scene_path = "res://scenes/combat/combat_arena.tscn"
	if has_node("/root/SceneTransitions"):
		SceneTransitions.change_scene(scene_path, SceneTransitions.TransitionStyle.COMBAT_ENTRY)


## ═══════════════════════════════════════════════════════════════════════════
## ZONE TRACKING & UI
## ═══════════════════════════════════════════════════════════════════════════

func _update_zone(pos: Vector2) -> void:
	if not has_node("/root/RandomEncounterSystem"):
		return
	var new_zone = "ironhold_outskirts"
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
	_zone_label.add_theme_color_override("font_color", Color(0.9, 0.85, 0.7))
	_zone_label.position = Vector2(20, 55)
	ui_layer.add_child(_zone_label)
	_stats_hud = Label.new()
	_stats_hud.add_theme_font_size_override("font_size", 11)
	_stats_hud.add_theme_color_override("font_color", Color(0.7, 0.9, 1.0))
	_stats_hud.position = Vector2(20, 10)
	ui_layer.add_child(_stats_hud)
	var title = Label.new()
	title.text = "~ IRONHOLD ~"
	title.add_theme_font_size_override("font_size", 16)
	title.add_theme_color_override("font_color", Color(0.6, 0.45, 0.25))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.position = Vector2(580, 10)
	ui_layer.add_child(title)
	var instructions = Label.new()
	instructions.text = "[WASD] Move  [Shift] Sprint  [F] Interact  [M] Map  [I] Status"
	instructions.add_theme_font_size_override("font_size", 9)
	instructions.add_theme_color_override("font_color", Color(0.6, 0.6, 0.5))
	instructions.position = Vector2(20, 690)
	ui_layer.add_child(instructions)

func _update_ui() -> void:
	if _stats_hud:
		var ps = GameManager.player_stats
		_stats_hud.text = "Lv %d  |  HP %d/%d  |  Gold %d  |  XP %d/%s" % [
			ps.get("level", 1), ps.get("hp", 100), ps.get("max_hp", 100),
			ps.get("gold", 0), ps.get("xp", 0),
			str(GameManager.get_xp_for_next_level()) if GameManager.get_xp_for_next_level() > 0 else "MAX"
		]
	if _zone_label and has_node("/root/RandomEncounterSystem"):
		var zone_name = RandomEncounterSystem.get_zone_name()
		var rec = RandomEncounterSystem.get_zone_recommended_level()
		var plvl = GameManager.player_stats.get("level", 1)
		if RandomEncounterSystem.is_safe_zone():
			_zone_label.text = "%s  ~ Safe ~" % zone_name
			_zone_label.add_theme_color_override("font_color", Color(0.4, 0.8, 0.4))
		elif plvl < rec - 2:
			_zone_label.text = "%s  !! DANGER Lv %d !!" % [zone_name, rec]
			_zone_label.add_theme_color_override("font_color", Color(1, 0.3, 0.3))
		else:
			_zone_label.text = "%s  (Lv %d)" % [zone_name, rec]
			_zone_label.add_theme_color_override("font_color", Color(0.9, 0.85, 0.7))
