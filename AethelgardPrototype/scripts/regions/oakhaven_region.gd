extends Node2D
## ==========================================================================
## OAKHAVEN REGION — Explorable top-down area with sub-zones
## ==========================================================================
## Merges: Glitch Crater, Path to Oakhaven, Village, Forest, Tutorial Arena
## Sub-zones: oakhaven_village (safe), oakhaven_fields, oakhaven_forest
## Boss: Tutorial Knight (in the Knight's Arena at the forest edge)
## ==========================================================================

const REGION_ID: String = "oakhaven"
const MAP_SIZE: Vector2 = Vector2(3200, 2400)

# Sub-zone boundaries for encounter zone switching
const SUB_ZONES: Array = [
	{"zone_id": "oakhaven_village", "rect": Rect2(800, 800, 600, 500), "name": "Oakhaven Village"},
	{"zone_id": "oakhaven_fields", "rect": Rect2(200, 400, 600, 800), "name": "Oakhaven Fields"},
	{"zone_id": "oakhaven_fields", "rect": Rect2(1500, 600, 700, 600), "name": "Eastern Fields"},
	{"zone_id": "oakhaven_forest", "rect": Rect2(2200, 200, 800, 1200), "name": "Dark Forest"},
	{"zone_id": "oakhaven_forest", "rect": Rect2(400, 1400, 1200, 600), "name": "Southern Woods"},
]

var _player: CharacterBody2D = null
var _camera: Camera2D = null
var _zone_label: Label = null
var _stats_hud: Label = null
var _lore_items_placed: Array[Node2D] = []
var _npcs: Array[Node2D] = []
var _near_boss_gate: bool = false

# ── NPC Data ────────────────────────────────────────────────────────────
const NPC_DATA: Array = [
	{"name": "Elder Rowan", "pos": Vector2(1050, 950), "color": Color(0.6, 0.5, 0.3),
	 "dialogue": ["The Administrator watches all...", "Once this village was peaceful. Now the sky flickers.", "You're not from here, are you? Your code is... different."]},
	{"name": "Farmer Thom", "pos": Vector2(900, 1100), "color": Color(0.5, 0.4, 0.2),
	 "dialogue": ["The crops grow... then undownload... then grow again.", "I planted wheat yesterday. Today it's carrots. Tomorrow, who knows?"]},
	{"name": "Child Pip", "pos": Vector2(1150, 1050), "color": Color(0.7, 0.5, 0.6),
	 "dialogue": ["Mister, why does the sun sometimes go SQUARE?", "I tried to climb the big tree but my legs stopped working at the invisible wall!"]},
	{"name": "Guard Alaric", "pos": Vector2(1100, 850), "color": Color(0.4, 0.4, 0.5),
	 "dialogue": ["Halt! ...actually, carry on. My patrol loop only covers this 50-pixel stretch.", "The knight at the bridge has been... acting strange. Saying things about 'loops'."]},
	{"name": "Apothecary Iris", "pos": Vector2(950, 900), "color": Color(0.3, 0.6, 0.4),
	 "dialogue": ["Welcome! I sell potions that definitely exist and aren't just variable assignments.", "Health Potion: restores HP. Side effects: brief floating-point rounding on your hit counter."]},
]

# ── Lore Fragment Data ────────────────────────────────────────────────────
const LORE_DATA: Array = [
	{"id": "crater_memory_1", "pos": Vector2(300, 300), "title": "Memory Fragment: The Crash",
	 "text": "The last thing Kaelen remembers: the oxygen masks dropping. Then wireframe. Then nothing."},
	{"id": "crater_memory_2", "pos": Vector2(180, 500), "title": "Memory Fragment: System Boot",
	 "text": "BOOT SEQUENCE v3.7.1... Loading personality matrix... WARNING: Host consciousness detected. Attempting integration..."},
	{"id": "village_lore_1", "pos": Vector2(1200, 1150), "title": "Village Notice Board",
	 "text": "WANTED: The entity responsible for Tuesday loading as Wednesday. Reward: 50 gold (subject to integer overflow)."},
	{"id": "forest_lore_1", "pos": Vector2(2400, 600), "title": "Carved Tree Message",
	 "text": "IF YOU CAN READ THIS, YOU ARE TOO FAR FROM THE INTENDED PLAY AREA. RETURN TO DESIGNATED ZONE. — The Administrator"},
	{"id": "forest_lore_2", "pos": Vector2(2600, 900), "title": "Glitched Signpost",
	 "text": "← OAKHAVEN    IRONHOLD → \n← IRKHAVEN    OAKHELD →\n← ÖÄK̶̡H̷̢AV̵EN    I̸̧R̶̡O̵̧NH̶̢O̸̧LD̵ →"},
	{"id": "field_lore_1", "pos": Vector2(500, 700), "title": "Abandoned Picnic",
	 "text": "A half-eaten meal, frozen mid-bite. The NPCs here sometimes freeze like this. Kaelen's inner monologue: 'Garbage collection pause. I wrote this bug.'"},
	{"id": "dev_signature_1", "pos": Vector2(150, 1800), "title": "Developer Signature #1",
	 "text": "// TODO: Fix pathfinding for southern forest zone. NPCs keep walking into trees. — K.V., Sprint 47"},
	{"id": "elara_notes", "pos": Vector2(700, 950), "title": "Elara's Research Notes",
	 "text": "The wireframe in my arm... it's not damage. It's the original render layer showing through. We're all wireframes underneath."},
]


func _ready() -> void:
	GameManager.change_state(GameManager.GameState.EXPLORATION)
	_build_region_environment()
	_spawn_player()
	_place_npcs()
	_place_lore_items()
	_place_boss_gate()
	_place_shops()
	_place_secrets()
	_create_overworld_exit()
	_create_ui()

	# Handle return from encounter
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
## ENVIRONMENT — Large explorable area with distinct sub-zones
## ═══════════════════════════════════════════════════════════════════════════

func _build_region_environment() -> void:
	# Base grass
	var bg = ColorRect.new()
	bg.color = Color(0.2, 0.32, 0.15)
	bg.size = MAP_SIZE
	bg.z_index = -20
	add_child(bg)

	# ── Glitch Crater (NW corner) ──
	var crater = ColorRect.new()
	crater.color = Color(0.15, 0.1, 0.2)
	crater.size = Vector2(350, 300)
	crater.position = Vector2(100, 200)
	crater.z_index = -18
	add_child(crater)
	# Crater rim
	var rim = ColorRect.new()
	rim.color = Color(0.25, 0.15, 0.3)
	rim.size = Vector2(370, 320)
	rim.position = Vector2(90, 190)
	rim.z_index = -19
	add_child(rim)
	# Corruption sparkles in crater
	for i in range(6):
		var spark = ColorRect.new()
		spark.color = Color(0.6, 0.1, 0.8, 0.7)
		spark.size = Vector2(4, 4)
		spark.position = Vector2(randi_range(120, 420), randi_range(220, 480))
		spark.z_index = -17
		add_child(spark)

	# ── Oakhaven Fields (middle-left) ──
	var fields = ColorRect.new()
	fields.color = Color(0.28, 0.45, 0.18)
	fields.size = Vector2(700, 800)
	fields.position = Vector2(150, 450)
	fields.z_index = -18
	add_child(fields)
	# Wheat rows
	for i in range(12):
		var wheat = ColorRect.new()
		wheat.color = Color(0.65, 0.55, 0.2, 0.5)
		wheat.size = Vector2(randi_range(60, 150), 6)
		wheat.position = Vector2(randi_range(200, 750), 500 + i * 55)
		wheat.z_index = -16
		add_child(wheat)

	# ── Village Area (center) ──
	var village_ground = ColorRect.new()
	village_ground.color = Color(0.35, 0.3, 0.22)  # Packed earth
	village_ground.size = Vector2(600, 500)
	village_ground.position = Vector2(800, 800)
	village_ground.z_index = -18
	add_child(village_ground)
	# Buildings
	_create_building("Elder's House", Vector2(1000, 880), Vector2(60, 50), Color(0.4, 0.3, 0.2))
	_create_building("Apothecary", Vector2(920, 870), Vector2(50, 40), Color(0.3, 0.5, 0.3))
	_create_building("Inn", Vector2(1100, 900), Vector2(70, 55), Color(0.45, 0.35, 0.25))
	_create_building("Blacksmith", Vector2(850, 1000), Vector2(55, 45), Color(0.35, 0.3, 0.3))
	_create_building("Farm House", Vector2(900, 1120), Vector2(55, 45), Color(0.4, 0.35, 0.2))

	# Village well
	var well = ColorRect.new()
	well.color = Color(0.3, 0.3, 0.35)
	well.size = Vector2(18, 18)
	well.position = Vector2(1040, 1000)
	well.z_index = -10
	add_child(well)

	# ── Eastern Fields ──
	var east_fields = ColorRect.new()
	east_fields.color = Color(0.25, 0.4, 0.16)
	east_fields.size = Vector2(700, 600)
	east_fields.position = Vector2(1500, 600)
	east_fields.z_index = -18
	add_child(east_fields)

	# ── Dark Forest (east side) ──
	var forest_bg = ColorRect.new()
	forest_bg.color = Color(0.1, 0.2, 0.08)
	forest_bg.size = Vector2(900, 1200)
	forest_bg.position = Vector2(2200, 200)
	forest_bg.z_index = -18
	add_child(forest_bg)
	# Dense tree canopy
	for i in range(40):
		var tree = ColorRect.new()
		tree.color = Color(0.08 + randf() * 0.1, 0.18 + randf() * 0.15, 0.05 + randf() * 0.08)
		tree.size = Vector2(randi_range(20, 40), randi_range(20, 40))
		tree.position = Vector2(randi_range(2220, 3050), randi_range(220, 1350))
		tree.z_index = -15
		add_child(tree)

	# ── Southern Woods ──
	var south_woods = ColorRect.new()
	south_woods.color = Color(0.12, 0.22, 0.1)
	south_woods.size = Vector2(1200, 600)
	south_woods.position = Vector2(400, 1400)
	south_woods.z_index = -18
	add_child(south_woods)
	for i in range(25):
		var tree = ColorRect.new()
		tree.color = Color(0.1 + randf() * 0.08, 0.2 + randf() * 0.12, 0.07 + randf() * 0.06)
		tree.size = Vector2(randi_range(18, 35), randi_range(18, 35))
		tree.position = Vector2(randi_range(420, 1550), randi_range(1420, 1950))
		tree.z_index = -15
		add_child(tree)

	# ── Paths connecting areas ──
	# Village → Fields path
	_create_path(Vector2(800, 1000), Vector2(400, 800), 30, Color(0.38, 0.3, 0.2))
	# Village → East Fields
	_create_path(Vector2(1400, 1000), Vector2(1500, 800), 25, Color(0.38, 0.3, 0.2))
	# East Fields → Forest
	_create_path(Vector2(2200, 750), Vector2(2250, 700), 20, Color(0.32, 0.25, 0.18))
	# Village → South
	_create_path(Vector2(1050, 1300), Vector2(900, 1400), 20, Color(0.35, 0.28, 0.2))


func _create_building(bname: String, pos: Vector2, bsize: Vector2, color: Color) -> void:
	var building = ColorRect.new()
	building.name = bname.replace(" ", "").replace("'", "")
	building.color = color
	building.size = bsize
	building.position = pos
	building.z_index = -12
	add_child(building)
	# Roof
	var roof = ColorRect.new()
	roof.color = Color(color.r * 0.7, color.g * 0.6, color.b * 0.5)
	roof.size = Vector2(bsize.x + 6, 10)
	roof.position = Vector2(-3, -10)
	building.add_child(roof)
	# Door
	var door = ColorRect.new()
	door.color = Color(0.25, 0.18, 0.1)
	door.size = Vector2(10, 14)
	door.position = Vector2(bsize.x / 2 - 5, bsize.y - 14)
	building.add_child(door)


func _create_path(from: Vector2, to: Vector2, segments: int, color: Color) -> void:
	for i in range(segments):
		var t = float(i) / float(segments)
		var pos = from.lerp(to, t)
		var stone = ColorRect.new()
		stone.color = color
		stone.size = Vector2(randi_range(8, 14), randi_range(8, 14))
		stone.position = pos + Vector2(randf_range(-5, 5), randf_range(-5, 5))
		stone.z_index = -14
		add_child(stone)


## ═══════════════════════════════════════════════════════════════════════════
## PLAYER
## ═══════════════════════════════════════════════════════════════════════════

func _spawn_player() -> void:
	var player_script = load("res://scripts/exploration/player_topdown.gd")
	if not player_script:
		push_error("[OAKHAVEN] Failed to load player_topdown.gd")
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

	# Default spawn near village entrance
	_player.global_position = Vector2(1050, 1250)
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
## NPCs — Walk-near dialogue via barks, interact for full conversation
## ═══════════════════════════════════════════════════════════════════════════

func _place_npcs() -> void:
	for data in NPC_DATA:
		var npc = _create_npc(data)
		_npcs.append(npc)
		add_child(npc)


func _create_npc(data: Dictionary) -> Node2D:
	var npc = Area2D.new()
	npc.name = data["name"].replace(" ", "")
	npc.position = data["pos"]

	# NPC body
	var body = ColorRect.new()
	body.color = data["color"]
	body.size = Vector2(16, 22)
	body.position = Vector2(-8, -22)
	npc.add_child(body)

	# Name plate
	var name_label = Label.new()
	name_label.text = data["name"]
	name_label.add_theme_font_size_override("font_size", 8)
	name_label.add_theme_color_override("font_color", Color.WHITE)
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.position = Vector2(-30, -34)
	npc.add_child(name_label)

	# Interaction prompt (hidden until close)
	var prompt = Label.new()
	prompt.name = "Prompt"
	prompt.text = "[F] Talk"
	prompt.add_theme_font_size_override("font_size", 7)
	prompt.add_theme_color_override("font_color", Color(1, 1, 0.7))
	prompt.position = Vector2(-15, 5)
	prompt.visible = false
	npc.add_child(prompt)

	# Detection area
	var shape = CollisionShape2D.new()
	var circle = CircleShape2D.new()
	circle.radius = 45.0
	shape.shape = circle
	npc.add_child(shape)

	npc.set_meta("npc_name", data["name"])
	npc.set_meta("dialogue", data["dialogue"])
	npc.set_meta("dialogue_index", 0)
	npc.body_entered.connect(_on_npc_body_entered.bind(npc))
	npc.body_exited.connect(_on_npc_body_exited.bind(npc))

	return npc

var _near_npc: Area2D = null

func _on_npc_body_entered(body: Node2D, npc: Area2D) -> void:
	if body.is_in_group("player"):
		_near_npc = npc
		var prompt = npc.get_node_or_null("Prompt")
		if prompt:
			prompt.visible = true

func _on_npc_body_exited(body: Node2D, npc: Area2D) -> void:
	if body.is_in_group("player") and _near_npc == npc:
		_near_npc = null
		var prompt = npc.get_node_or_null("Prompt")
		if prompt:
			prompt.visible = false


## ═══════════════════════════════════════════════════════════════════════════
## LORE ITEMS — Environmental storytelling fragments
## ═══════════════════════════════════════════════════════════════════════════

func _place_lore_items() -> void:
	for data in LORE_DATA:
		var lore = _create_lore_item(data)
		_lore_items_placed.append(lore)
		add_child(lore)


func _create_lore_item(data: Dictionary) -> Node2D:
	var lore = Area2D.new()
	lore.name = data["id"]
	lore.position = data["pos"]

	# Glowing marker
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

	# Interact prompt
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
	lore.body_entered.connect(_on_lore_nearby.bind(lore))
	lore.body_exited.connect(_on_lore_left.bind(lore))

	return lore

var _near_lore: Area2D = null

func _on_lore_nearby(body: Node2D, lore: Area2D) -> void:
	if body.is_in_group("player"):
		_near_lore = lore
		var prompt = lore.get_node_or_null("Prompt")
		if prompt:
			prompt.visible = true

func _on_lore_left(body: Node2D, lore: Area2D) -> void:
	if body.is_in_group("player") and _near_lore == lore:
		_near_lore = null
		var prompt = lore.get_node_or_null("Prompt")
		if prompt:
			prompt.visible = false


## ═══════════════════════════════════════════════════════════════════════════
## BOSS GATE — Tutorial Knight arena entrance in the forest
## ═══════════════════════════════════════════════════════════════════════════

func _place_boss_gate() -> void:
	var gate = Area2D.new()
	gate.name = "TutorialKnightGate"
	gate.position = Vector2(2800, 500)

	# Dramatic gate visual
	var left_pillar = ColorRect.new()
	left_pillar.color = Color(0.4, 0.35, 0.3)
	left_pillar.size = Vector2(12, 50)
	left_pillar.position = Vector2(-30, -50)
	gate.add_child(left_pillar)

	var right_pillar = ColorRect.new()
	right_pillar.color = Color(0.4, 0.35, 0.3)
	right_pillar.size = Vector2(12, 50)
	right_pillar.position = Vector2(18, -50)
	gate.add_child(right_pillar)

	var arch = ColorRect.new()
	arch.color = Color(0.45, 0.38, 0.3)
	arch.size = Vector2(60, 8)
	arch.position = Vector2(-30, -55)
	gate.add_child(arch)

	var label = Label.new()
	label.text = "Knight's Arena\n[F] Enter\nRec. Lv 5"
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 9)
	label.add_theme_color_override("font_color", Color(1, 0.85, 0.5))
	label.position = Vector2(-35, -75)
	gate.add_child(label)

	# Warning for underleveled
	var warning = Label.new()
	warning.name = "BossWarning"
	warning.text = ""
	warning.add_theme_font_size_override("font_size", 8)
	warning.add_theme_color_override("font_color", Color(1, 0.3, 0.3))
	warning.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	warning.position = Vector2(-40, 12)
	gate.add_child(warning)

	var shape = CollisionShape2D.new()
	var rect = RectangleShape2D.new()
	rect.size = Vector2(50, 50)
	shape.shape = rect
	gate.add_child(shape)

	gate.body_entered.connect(_on_boss_gate_entered)
	gate.body_exited.connect(_on_boss_gate_exited)
	add_child(gate)


func _on_boss_gate_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		_near_boss_gate = true
		# Show level warning
		var warning = get_node_or_null("TutorialKnightGate/BossWarning")
		var player_level = GameManager.player_stats.get("level", 1)
		if warning and player_level < 3:
			warning.text = "!! Your Lv %d — Boss Lv 5 !!" % player_level

func _on_boss_gate_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		_near_boss_gate = false


## ═══════════════════════════════════════════════════════════════════════════
## SHOPS — Buy equipment, potions, charms
## ═══════════════════════════════════════════════════════════════════════════

func _place_shops() -> void:
	_create_shop_trigger("Apothecary", Vector2(935, 880), "apothecary")
	_create_shop_trigger("Blacksmith", Vector2(865, 985), "blacksmith")


func _create_shop_trigger(shop_name: String, pos: Vector2, shop_type: String) -> void:
	var trigger = Area2D.new()
	trigger.name = shop_name + "Trigger"
	trigger.position = pos

	var shape = CollisionShape2D.new()
	var rect = RectangleShape2D.new()
	rect.size = Vector2(40, 30)
	shape.shape = rect
	trigger.add_child(shape)

	trigger.set_meta("shop_type", shop_type)
	trigger.set_meta("shop_name", shop_name)
	trigger.body_entered.connect(_on_shop_entered.bind(trigger))
	trigger.body_exited.connect(_on_shop_exited.bind(trigger))
	add_child(trigger)

var _near_shop: Area2D = null

func _on_shop_entered(body: Node2D, trigger: Area2D) -> void:
	if body.is_in_group("player"):
		_near_shop = trigger

func _on_shop_exited(body: Node2D, trigger: Area2D) -> void:
	if body.is_in_group("player") and _near_shop == trigger:
		_near_shop = null


## ═══════════════════════════════════════════════════════════════════════════
## HIDDEN SECRETS — Discoverable pickups rewarding exploration
## ═══════════════════════════════════════════════════════════════════════════

const OAKHAVEN_SECRETS: Array = [
	{
		"id": "secret_oak_forest_blade", "pos": Vector2(240, 350),
		"flag": "secret_oak_forest_blade_found",
		"item": "corrupted_knight_blade", "xp_bonus": 75,
		"title": "HIDDEN CACHE",
		"text": "A blade wedged in a corrupted tree stump. Unstable energy crackles along the edge."
	},
	{
		"id": "secret_oak_meadow_potion", "pos": Vector2(2950, 600),
		"flag": "secret_oak_meadow_potion_found",
		"item": "health_potion", "item_qty": 5, "xp_bonus": 40,
		"title": "EMERGENCY SUPPLY",
		"text": "A stash of healing supplies hidden in the tall grass near the glitch meadow."
	},
	{
		"id": "secret_oak_well_lore", "pos": Vector2(1100, 1400),
		"flag": "secret_oak_well_lore_found",
		"item": "", "xp_bonus": 100, "gold_bonus": 50,
		"title": "FORGOTTEN JOURNAL",
		"text": "A developer's debug log wedged behind the village well:\n'The forest entities were supposed to be friendly. Something in the root branch corrupted their behavior trees.'"
	},
]

var _near_secret: Area2D = null

func _place_secrets() -> void:
	for data in OAKHAVEN_SECRETS:
		if GameManager.get_story_flag(data["flag"]):
			continue  # Already found
		var secret = _create_secret(data)
		add_child(secret)


func _create_secret(data: Dictionary) -> Area2D:
	var secret = Area2D.new()
	secret.name = data["id"]
	secret.position = data["pos"]

	# Barely visible shimmer (hidden pickup)
	var shimmer = ColorRect.new()
	shimmer.color = Color(1.0, 1.0, 0.8, 0.12)
	shimmer.size = Vector2(8, 8)
	shimmer.position = Vector2(-4, -4)
	secret.add_child(shimmer)

	# Tiny sparkle
	var sparkle = ColorRect.new()
	sparkle.color = Color(1.0, 1.0, 0.6, 0.25)
	sparkle.size = Vector2(3, 3)
	sparkle.position = Vector2(-1.5, -1.5)
	secret.add_child(sparkle)

	# Pulse animation (bound to secret node so it's auto-killed on free)
	var tween = secret.create_tween().set_loops()
	tween.tween_property(shimmer, "modulate:a", 0.4, 1.5).set_trans(Tween.TRANS_SINE)
	tween.tween_property(shimmer, "modulate:a", 0.1, 1.5).set_trans(Tween.TRANS_SINE)

	var shape = CollisionShape2D.new()
	var circle = CircleShape2D.new()
	circle.radius = 25.0
	shape.shape = circle
	secret.add_child(shape)

	secret.set_meta("secret_data", data)
	secret.body_entered.connect(func(b):
		if b.is_in_group("player"):
			_near_secret = secret
	)
	secret.body_exited.connect(func(b):
		if b.is_in_group("player") and _near_secret == secret:
			_near_secret = null
	)
	return secret


func _collect_secret(secret: Area2D) -> void:
	var data: Dictionary = secret.get_meta("secret_data", {})
	if data.is_empty():
		return

	GameManager.set_story_flag(data["flag"], true)

	# Award item
	var item_id: String = data.get("item", "")
	var item_qty: int = data.get("item_qty", 1)
	if not item_id.is_empty() and has_node("/root/Inventory"):
		Inventory.add_item(item_id, item_qty)

	# Award XP/gold bonuses
	var xp_bonus: int = data.get("xp_bonus", 0)
	var gold_bonus: int = data.get("gold_bonus", 0)
	if xp_bonus > 0:
		GameManager.add_xp(xp_bonus)
	if gold_bonus > 0:
		GameManager.add_gold(gold_bonus)

	# VFX
	if has_node("/root/VFXLibrary"):
		VFXLibrary.spawn("vfx_pickup_burst", secret.global_position, self)
	if has_node("/root/SFXManager"):
		SFXManager.play("secret_found")
	if has_node("/root/CombatFX"):
		CombatFX.apply_screen_shake(8.0, 0.3)

	# Show discovery dialogue
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

	# Record in lore journal
	if has_node("/root/LoreJournal"):
		LoreJournal.record_find(data["id"], data.get("title", "Secret"), data.get("text", ""))

	# Remove the secret pickup
	_near_secret = null
	secret.queue_free()


## ═══════════════════════════════════════════════════════════════════════════
## OVERWORLD EXIT — Return to the overworld map
## ═══════════════════════════════════════════════════════════════════════════

func _create_overworld_exit() -> void:
	# South exit back to overworld
	var exit = Area2D.new()
	exit.name = "OverworldExit"
	exit.position = Vector2(1600, MAP_SIZE.y - 30)

	var marker = ColorRect.new()
	marker.color = Color(0.8, 0.7, 0.3, 0.6)
	marker.size = Vector2(200, 20)
	marker.position = Vector2(-100, -10)
	exit.add_child(marker)

	var label = Label.new()
	label.text = "← To Overworld →"
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 10)
	label.add_theme_color_override("font_color", Color(1, 1, 0.7))
	label.position = Vector2(-50, -25)
	exit.add_child(label)

	var shape = CollisionShape2D.new()
	var rect = RectangleShape2D.new()
	rect.size = Vector2(200, 40)
	shape.shape = rect
	exit.add_child(shape)

	exit.body_entered.connect(_on_overworld_exit_entered)
	add_child(exit)

	# East exit too
	var east_exit = Area2D.new()
	east_exit.name = "OverworldExitEast"
	east_exit.position = Vector2(MAP_SIZE.x - 30, 1000)

	var emarker = ColorRect.new()
	emarker.color = Color(0.8, 0.7, 0.3, 0.6)
	emarker.size = Vector2(20, 200)
	emarker.position = Vector2(-10, -100)
	east_exit.add_child(emarker)

	var elabel = Label.new()
	elabel.text = "To Overworld →"
	elabel.add_theme_font_size_override("font_size", 10)
	elabel.add_theme_color_override("font_color", Color(1, 1, 0.7))
	elabel.position = Vector2(-40, -120)
	east_exit.add_child(elabel)

	var eshape = CollisionShape2D.new()
	var erect = RectangleShape2D.new()
	erect.size = Vector2(40, 200)
	eshape.shape = erect
	east_exit.add_child(eshape)

	east_exit.body_entered.connect(_on_overworld_exit_entered)
	add_child(east_exit)


func _on_overworld_exit_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		GameManager.set_meta("return_to_overworld_from", REGION_ID)
		if has_node("/root/SceneTransitions"):
			SceneTransitions.change_scene("res://scenes/overworld/overworld.tscn")


## ═══════════════════════════════════════════════════════════════════════════
## INPUT — Interact with NPCs, lore, shops, boss gate
## ═══════════════════════════════════════════════════════════════════════════

func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed("interact"):
		return

	# Boss gate
	if _near_boss_gate:
		_enter_boss_arena()
		return

	# NPC interaction
	if _near_npc and is_instance_valid(_near_npc):
		_interact_with_npc(_near_npc)
		return

	# Lore item
	if _near_lore and is_instance_valid(_near_lore):
		_interact_with_lore(_near_lore)
		return

	# Shop
	if _near_shop and is_instance_valid(_near_shop):
		_interact_with_shop(_near_shop)
		return

	# Hidden secret
	if _near_secret and is_instance_valid(_near_secret):
		_collect_secret(_near_secret)
		return


func _interact_with_npc(npc: Area2D) -> void:
	var npc_name: String = npc.get_meta("npc_name", "NPC")
	var dialogue: Array = npc.get_meta("dialogue", [])
	var idx: int = npc.get_meta("dialogue_index", 0)

	if dialogue.is_empty():
		return

	if has_node("/root/DialogueManager"):
		GameManager.change_state(GameManager.GameState.DIALOGUE)
		var line = dialogue[idx % dialogue.size()]
		await DialogueManager.say(npc_name, line)
		npc.set_meta("dialogue_index", (idx + 1) % dialogue.size())
		GameManager.change_state(GameManager.GameState.EXPLORATION)

		# Record in lore journal
		if has_node("/root/LoreJournal"):
			LoreJournal.record_dialogue(npc_name, line)
		await _handle_oakhaven_side_objective(npc_name)


func _handle_oakhaven_side_objective(npc_name: String) -> void:
	if npc_name != "Apothecary Iris" or not has_node("/root/SideQuestManager"):
		return
	if SideQuestManager.is_quest_complete("oakhaven_memory_herb_delivery"):
		return

	GameManager.change_state(GameManager.GameState.DIALOGUE)
	SideQuestManager.start_quest("oakhaven_memory_herb_delivery")
	if not has_node("/root/Inventory") or not Inventory.has_item("glitch_herb", 2):
		if has_node("/root/DialogueManager"):
			await DialogueManager.say("Apothecary Iris", "If you find two Glitch Herbs, I can brew medicine for people whose memories keep desyncing.")
		GameManager.change_state(GameManager.GameState.EXPLORATION)
		return

	var choice := 1
	if has_node("/root/DialogueManager"):
		choice = await DialogueManager.show_choices("Deliver two Glitch Herbs to Iris?", ["Deliver the herbs.", "Not now."])
	if choice == 0 and Inventory.remove_item("glitch_herb", 2):
		SideQuestManager.complete_optional_objective("oakhaven_memory_herb_delivery")
		if has_node("/root/LoreJournal"):
			LoreJournal.discover("oakhaven_memory_herb_label")
		GameManager.save_game(GameManager.AUTOSAVE_SLOT)
	GameManager.change_state(GameManager.GameState.EXPLORATION)


func _interact_with_lore(lore: Area2D) -> void:
	var title: String = lore.get_meta("lore_title", "Unknown")
	var text: String = lore.get_meta("lore_text", "")
	var lore_id: String = lore.get_meta("lore_id", "")

	if has_node("/root/DialogueManager"):
		GameManager.change_state(GameManager.GameState.DIALOGUE)
		await DialogueManager.say(title, text)
		GameManager.change_state(GameManager.GameState.EXPLORATION)

	# Record discovery
	if has_node("/root/LoreJournal"):
		LoreJournal.discover_lore(lore_id, title, text)

	# Dev signature tracking
	if lore_id.begins_with("dev_signature"):
		GameManager.set_story_flag(lore_id + "_found", true)


func _interact_with_shop(trigger: Area2D) -> void:
	var shop_type: String = trigger.get_meta("shop_type", "general")
	if has_node("/root/ShopSystem"):
		ShopSystem.open_shop(shop_type)


func _enter_boss_arena() -> void:
	if GameManager.get_flag("ch1_tutorial_knight_defeated"):
		if has_node("/root/DialogueManager"):
			await DialogueManager.say("SYSTEM", "The Guardian has been defeated. The arena lies silent.")
		return

	# Level warning
	var player_level = GameManager.player_stats.get("level", 1)
	if player_level < 3:
		if has_node("/root/DialogueManager"):
			GameManager.change_state(GameManager.GameState.DIALOGUE)
			await DialogueManager.say("SYSTEM",
				"[WARNING] Hostile entity detected — TUTORIAL KNIGHT.\nThreat level: 5 | Your level: %d\nThis encounter may result in system failure." % player_level)
			var choice = await DialogueManager.show_choices("Proceed anyway?", ["Enter the Arena", "Turn Back"])
			GameManager.change_state(GameManager.GameState.EXPLORATION)
			if choice == 1:
				return

	# Store return info
	GameManager.set_meta("return_position", _player.global_position if _player else Vector2(2700, 500))
	GameManager.set_meta("boss_return_scene", "res://scenes/regions/oakhaven_region.tscn")

	if has_node("/root/SceneTransitions"):
		SceneTransitions.change_scene("res://scenes/chapter1/tutorial_knight_boss.tscn", SceneTransitions.TransitionStyle.COMBAT_ENTRY)


## ═══════════════════════════════════════════════════════════════════════════
## ZONE TRACKING
## ═══════════════════════════════════════════════════════════════════════════

func _update_zone(pos: Vector2) -> void:
	if not has_node("/root/RandomEncounterSystem"):
		return
	var new_zone = "oakhaven_fields"  # default
	for zone_def in SUB_ZONES:
		var rect: Rect2 = zone_def["rect"]
		if rect.has_point(pos):
			new_zone = zone_def["zone_id"]
			break
	if new_zone != RandomEncounterSystem.current_zone_id:
		RandomEncounterSystem.set_zone(new_zone)


func _clamp_player() -> void:
	if _player:
		_player.global_position.x = clampf(_player.global_position.x, 20, MAP_SIZE.x - 20)
		_player.global_position.y = clampf(_player.global_position.y, 20, MAP_SIZE.y - 20)


## ═══════════════════════════════════════════════════════════════════════════
## UI
## ═══════════════════════════════════════════════════════════════════════════

func _create_ui() -> void:
	var ui_layer = CanvasLayer.new()
	ui_layer.name = "RegionUI"
	ui_layer.layer = 50
	add_child(ui_layer)

	_zone_label = Label.new()
	_zone_label.name = "ZoneLabel"
	_zone_label.add_theme_font_size_override("font_size", 13)
	_zone_label.add_theme_color_override("font_color", Color(0.9, 0.9, 0.8))
	_zone_label.position = Vector2(20, 55)
	ui_layer.add_child(_zone_label)

	_stats_hud = Label.new()
	_stats_hud.name = "StatsHUD"
	_stats_hud.add_theme_font_size_override("font_size", 11)
	_stats_hud.add_theme_color_override("font_color", Color(0.7, 0.9, 1.0))
	_stats_hud.position = Vector2(20, 10)
	ui_layer.add_child(_stats_hud)

	var region_title = Label.new()
	region_title.text = "~ OAKHAVEN REGION ~"
	region_title.add_theme_font_size_override("font_size", 16)
	region_title.add_theme_color_override("font_color", Color(0.4, 0.7, 0.3))
	region_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	region_title.position = Vector2(540, 10)
	ui_layer.add_child(region_title)

	var instructions = Label.new()
	instructions.text = "[WASD] Move  [Shift] Sprint  [F] Interact  [M] Map  [I] Status"
	instructions.add_theme_font_size_override("font_size", 9)
	instructions.add_theme_color_override("font_color", Color(0.6, 0.6, 0.5))
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
			_zone_label.add_theme_color_override("font_color", Color(0.9, 0.9, 0.8))
