extends Node2D

## Chapter 2: The Administrator's Game
## Sequence 2: Ironhold City — Exploration Hub
## Massive top-down exploration with 5 districts and 7+ NPCs

@onready var player = $Player
@onready var camera = $Camera2D

# NPC interaction tracking
var _npc_dialogues_done: Dictionary = {}
var _market_visited: bool = false
var _arena_hint_given: bool = false
var _is_talking: bool = false  # BUG-21-26: Guard against simultaneous NPC dialogues

# Story progression gates
var _seraphina_encounter_ready: bool = false
var _underground_unlocked: bool = false
var _clock_tower_unlocked: bool = false
var _admin_boss_triggered: bool = false
var _seraphina_triggered: bool = false   # BUG-21-16: one-shot guard
var _admin_triggered: bool = false        # BUG-21-16: one-shot guard

func _ready() -> void:
	print("[CH2-CITY] Initializing Ironhold City exploration hub")
	GameManager.change_state(GameManager.GameState.EXPLORATION)

	# Play exploration music for the city hub
	if has_node("/root/MusicManager"):
		MusicManager.play_track("ironhold")  # Pass 53: Use dedicated ironhold track

	# Replace placeholder sprite with real player art
	if player:
		AssetManager.replace_player_sprite(player, "exploration")

	# Setup camera
	if camera:
		camera.make_current()
		if camera.has_method("set_target"):
			camera.set_target(player)

	# Build the city programmatically
	_build_city_environment()
	_spawn_npcs()
	_create_district_triggers()
	_setup_hud()

	# PASS-35 FIX: Discover chapter 2 side quests through exploration
	if has_node("/root/SideQuestManager"):
		SideQuestManager.discover_quest("ironhold_arena_legend")
		SideQuestManager.discover_quest("ironhold_merchant_guild")

	# Check story progression
	await _check_story_state()
	if not is_inside_tree(): return

	# Opening dialogue on first visit
	if not GameManager.has_flag("ch2_market_visited"):
		await get_tree().create_timer(0.5).timeout
		if not is_inside_tree(): return
		await _first_visit_dialogue()
		if not is_inside_tree(): return

# BUG-21-16: Re-check story triggers each frame so late-arriving flags fire
func _process(_delta: float) -> void:
	if not _seraphina_triggered and not _admin_triggered:
		var sera_ready = GameManager.has_flag("ch2_arena_bronze_complete") and not GameManager.has_flag("ch2_seraphina_met")
		var admin_ready = GameManager.has_flag("ch2_clock_tower_complete") and not GameManager.has_flag("ch2_administrator_proxy_defeated")
		if admin_ready and not _admin_triggered:
			_admin_triggered = true
			_trigger_administrator_arrival()
		elif sera_ready and not _seraphina_triggered:
			_seraphina_triggered = true
			_trigger_seraphina_encounter()

func _check_story_state() -> void:
	## Check flags to determine what's available
	_seraphina_encounter_ready = GameManager.has_flag("ch2_arena_bronze_complete") and not GameManager.has_flag("ch2_seraphina_met")
	_underground_unlocked = GameManager.has_flag("ch2_seraphina_met")
	_clock_tower_unlocked = GameManager.has_flag("ch2_underground_complete")
	if _clock_tower_unlocked and not GameManager.has_flag("ch2_clock_tower_unlocked"):
		GameManager.set_story_flag("ch2_clock_tower_unlocked", true)
	_admin_boss_triggered = GameManager.has_flag("ch2_clock_tower_complete") and not GameManager.has_flag("ch2_administrator_proxy_defeated")

	# Trigger admin boss event if conditions met (takes priority over seraphina)
	if _admin_boss_triggered:
		_admin_triggered = true  # BUG-21-16: mark as fired
		await get_tree().create_timer(1.5).timeout
		if not is_inside_tree(): return
		_trigger_administrator_arrival()
		return

	# Trigger Seraphina encounter
	if _seraphina_encounter_ready:
		_seraphina_triggered = true  # BUG-21-16: mark as fired
		await get_tree().create_timer(1.0).timeout
		if not is_inside_tree(): return
		_trigger_seraphina_encounter()
		return

func _has_elara() -> bool:
	return GameManager.has_elara()

func _has_flag(flag_name: String) -> bool:
	return GameManager.has_flag(flag_name)

func _first_visit_dialogue() -> void:
	## Dialogue on first entering the city
	var has_elara = _has_elara()

	if has_elara:
		await DialogueManager.say("Elara", "Welcome to Ironhold proper. The Market District is straight ahead — we should stock up. The Arena District is to the east.")
		if not is_inside_tree(): return
		await DialogueManager.say("Kaelen", "And that massive clock tower in the center?")
		if not is_inside_tree(): return
		await DialogueManager.say("Elara", "Off-limits for now. The Administration controls it. But there are ways around their locks... if we find the right people.")
		if not is_inside_tree(): return
	else:
		await DialogueManager.say("Kaelen (Internal)", "Ironhold proper. Market stalls to the west, an arena to the east, and that massive clock tower looming over everything. I need allies — information — anything to make up for walking in here alone.")
		if not is_inside_tree(): return
		await DialogueManager.say("Kaelen", "The clock tower... it's humming. I can feel the vibrations through the cobblestones. That's not just decoration — it's the city's heartbeat.")
		if not is_inside_tree(): return
		await DialogueManager.say("Kaelen (Internal)", "If Elara were here, she'd probably know every shortcut and hidden path. But she's not. I made my choice. Now I live with it.")
		if not is_inside_tree(): return

	await DialogueManager.say("Kaelen (Internal)", "A city full of NPCs, each running their own routines. But unlike Oakhaven, these routines are more complex — more alive. Or at least, better simulated.")
	if not is_inside_tree(): return

	GameManager.set_story_flag("ch2_market_visited", true)
	DialogueManager.hide_dialogue()

func _build_city_environment() -> void:
	## Create the Ironhold city environment programmatically
	# Rich procedural background from BackgroundManager
	if has_node("/root/BackgroundManager"):
		BackgroundManager.create_background("ironhold_city", self)

	# Ground
	var ground = ColorRect.new()
	ground.color = Color(0.25, 0.22, 0.18)
	ground.size = Vector2(3000, 2500)
	ground.position = Vector2(-500, -500)
	ground.z_index = -10
	add_child(ground)

	# Main streets (lighter paths)
	var streets = [
		Rect2(200, 500, 2600, 80),   # Main east-west
		Rect2(1200, 100, 80, 2200),  # Main north-south
		Rect2(600, 800, 80, 800),    # Market side street
		Rect2(1800, 400, 80, 600),   # Arena approach
	]

	for street_rect in streets:
		var street = ColorRect.new()
		street.color = Color(0.35, 0.32, 0.25)
		street.size = street_rect.size
		street.position = street_rect.position
		street.z_index = -9
		add_child(street)

	# Building blocks by district
	_build_market_district()
	_build_arena_district()
	_build_residential_district()
	_build_clock_tower_district()

	# Steam vents (decorative)
	for i in range(8):
		var vent = ColorRect.new()
		vent.color = Color(0.6, 0.6, 0.6, 0.3)
		vent.size = Vector2(15, 15)
		vent.position = Vector2(randf_range(100, 2600), randf_range(100, 2200))
		add_child(vent)

	# Boundary walls
	_add_boundary_wall(Vector2(-500, -500), Vector2(3500, 20))  # Top
	_add_boundary_wall(Vector2(-500, 2000), Vector2(3500, 20))  # Bottom
	_add_boundary_wall(Vector2(-500, -500), Vector2(20, 2520))  # Left
	_add_boundary_wall(Vector2(3000, -500), Vector2(20, 2520))  # Right

func _build_market_district() -> void:
	## Market district — shops and vendors
	var buildings = [
		{"pos": Vector2(400, 300), "size": Vector2(120, 100), "color": Color(0.5, 0.35, 0.2), "label": "Blacksmith"},
		{"pos": Vector2(600, 300), "size": Vector2(100, 80), "color": Color(0.3, 0.5, 0.3), "label": "Potion Shop"},
		{"pos": Vector2(400, 600), "size": Vector2(110, 90), "color": Color(0.4, 0.4, 0.3), "label": "General Store"},
		{"pos": Vector2(600, 600), "size": Vector2(90, 90), "color": Color(0.4, 0.3, 0.4), "label": "Tavern"},
	]

	for b in buildings:
		_create_building(b["pos"], b["size"], b["color"], b["label"])

func _build_arena_district() -> void:
	## Arena district — combat area entrance
	_create_building(Vector2(1900, 300), Vector2(200, 180), Color(0.6, 0.3, 0.2), "Battle Arena")
	_create_building(Vector2(2150, 350), Vector2(80, 80), Color(0.5, 0.4, 0.25), "Arena Gear Shop")

func _build_residential_district() -> void:
	## Residential area — NPC homes
	for i in range(6):
		var x = 800 + (i % 3) * 140
		@warning_ignore("integer_division")
		var y = 1200 + (i / 3) * 160
		_create_building(Vector2(x, y), Vector2(100, 80), Color(0.35, 0.3, 0.25), "")

func _build_clock_tower_district() -> void:
	## Clock Tower — central landmark
	_create_building(Vector2(1150, 100), Vector2(180, 250), Color(0.45, 0.35, 0.25), "Clock Tower")
	# Clock face decoration
	var clock_face = ColorRect.new()
	clock_face.color = Color(0.8, 0.7, 0.5)
	clock_face.size = Vector2(40, 40)
	clock_face.position = Vector2(1220, 120)
	add_child(clock_face)

func _create_building(pos: Vector2, bsize: Vector2, color: Color, label_text: String) -> void:
	## Create a building with collision and optional label
	var building = StaticBody2D.new()
	building.position = pos

	var rect = ColorRect.new()
	rect.color = color
	rect.size = bsize
	building.add_child(rect)

	var collision = CollisionShape2D.new()
	var shape = RectangleShape2D.new()
	shape.size = bsize
	collision.shape = shape
	collision.position = bsize * 0.5
	building.add_child(collision)

	if label_text != "":
		var label = Label.new()
		label.text = label_text
		label.position = Vector2(5, -18)
		label.add_theme_font_size_override("font_size", 11)
		label.add_theme_color_override("font_color", Color(0.9, 0.85, 0.7))
		building.add_child(label)

	add_child(building)

func _add_boundary_wall(pos: Vector2, wall_size: Vector2) -> void:
	var wall = StaticBody2D.new()
	wall.position = pos
	var col = CollisionShape2D.new()
	var shape = RectangleShape2D.new()
	shape.size = wall_size
	col.shape = shape
	col.position = wall_size * 0.5
	wall.add_child(col)
	add_child(wall)

func _spawn_npcs() -> void:
	## Create all city NPCs with interaction areas
	var npc_data = [
		{"name": "Blacksmith Torval", "pos": Vector2(460, 430), "color": Color(0.7, 0.45, 0.2), "group": "npc"},
		{"name": "Nyx", "pos": Vector2(850, 550), "color": Color(0.5, 0.8, 0.7), "group": "npc"},
		{"name": "Pip", "pos": Vector2(650, 800), "color": Color(0.9, 0.75, 0.3), "group": "npc"},
		{"name": "Marcus", "pos": Vector2(660, 680), "color": Color(0.5, 0.45, 0.4), "group": "npc"},
		{"name": "Vex", "pos": Vector2(1950, 520), "color": Color(0.9, 0.35, 0.5), "group": "npc"},
		{"name": "Crash", "pos": Vector2(2200, 420), "color": Color(0.9, 0.7, 0.1), "group": "npc"},
		{"name": "Null", "pos": Vector2(1100, 1500), "color": Color(0.25, 0.25, 0.25), "group": "npc"},
	]

	for data in npc_data:
		_create_npc(data["name"], data["pos"], data["color"])

func _create_npc(npc_name: String, pos: Vector2, color: Color) -> void:
	## Create an NPC with visual, collision, and interaction area
	var npc = CharacterBody2D.new()
	npc.name = npc_name.replace(" ", "_")
	npc.position = pos
	npc.add_to_group("npc")

	# Visual — try Kenney alien sprite first, fall back to ColorRect
	var used_kenney := false
	if has_node("/root/AssetManager"):
		var kenney_node = AssetManager.create_character_sprite(npc_name, Vector2(30, 40))
		if kenney_node and kenney_node.get_child_count() > 0:
			var child = kenney_node.get_child(0)
			if child is Sprite2D:
				# Has a real sprite, use it
				kenney_node.position = Vector2(0, 0)
				npc.add_child(kenney_node)
				used_kenney = true
			else:
				kenney_node.queue_free()

	if not used_kenney:
		var sprite = ColorRect.new()
		sprite.color = color
		sprite.size = Vector2(30, 40)
		sprite.position = Vector2(-15, -40)
		npc.add_child(sprite)

	# Collision
	var col = CollisionShape2D.new()
	var shape = RectangleShape2D.new()
	shape.size = Vector2(30, 40)
	col.shape = shape
	col.position = Vector2(0, -20)
	npc.add_child(col)

	# Name label (only if not already added by Kenney sprite system)
	if not used_kenney:
		var label = Label.new()
		label.text = npc_name
		label.position = Vector2(-30, -55)
		label.add_theme_font_size_override("font_size", 10)
		label.add_theme_color_override("font_color", color.lightened(0.3))
		npc.add_child(label)

	# Interaction area
	var area = Area2D.new()
	area.name = "InteractionArea"
	var area_col = CollisionShape2D.new()
	var area_shape = CircleShape2D.new()
	area_shape.radius = 50.0
	area_col.shape = area_shape
	area.add_child(area_col)
	npc.add_child(area)

	area.body_entered.connect(_on_npc_area_entered.bind(npc_name))

	add_child(npc)

func _create_district_triggers() -> void:
	## Create trigger areas for district transitions
	# Arena entrance trigger
	_create_trigger_area("arena_entrance", Vector2(1950, 280), 60.0)
	# Clock Tower entrance
	_create_trigger_area("clock_tower_entrance", Vector2(1240, 350), 50.0)
	# Underground entrance (hidden)
	if _underground_unlocked:
		_create_trigger_area("underground_entrance", Vector2(900, 1400), 40.0)

func _create_trigger_area(trigger_name: String, pos: Vector2, radius: float) -> void:
	var area = Area2D.new()
	area.name = trigger_name
	area.position = pos

	var col = CollisionShape2D.new()
	var shape = CircleShape2D.new()
	shape.radius = radius
	col.shape = shape
	area.add_child(col)

	area.body_entered.connect(_on_trigger_entered.bind(trigger_name))
	add_child(area)

	# Visual indicator
	var indicator = ColorRect.new()
	indicator.color = Color(1, 1, 0, 0.2)
	indicator.size = Vector2(radius * 2, radius * 2)
	indicator.position = Vector2(-radius, -radius)
	area.add_child(indicator)

func _on_trigger_entered(body, trigger_name: String) -> void:
	if not body.is_in_group("player"):
		return

	match trigger_name:
		"arena_entrance":
			_enter_arena()
		"clock_tower_entrance":
			_enter_clock_tower()
		"underground_entrance":
			_enter_underground()

func _on_npc_area_entered(_body, _npc_name: String) -> void:
	# This is triggered by proximity — actual interaction uses player's input
	pass

func _input(event) -> void:
	if DialogueManager.is_active:
		return

	if event.is_action_pressed("interact") or event.is_action_pressed("ui_accept"):
		_try_npc_interaction()

func _try_npc_interaction() -> void:
	## Check if player is near an NPC and trigger dialogue
	if not player:
		return

	var closest_npc = ""
	var closest_dist = 60.0

	for npc_name in ["Blacksmith_Torval", "Nyx", "Pip", "Marcus", "Vex", "Crash", "Null"]:
		var npc = get_node_or_null(npc_name)
		if npc and player.global_position.distance_to(npc.global_position) < closest_dist:
			closest_dist = player.global_position.distance_to(npc.global_position)
			closest_npc = npc_name

	if closest_npc != "":
		_trigger_npc_dialogue(closest_npc)

func _trigger_npc_dialogue(npc_id: String) -> void:
	## Play NPC dialogue based on story state
	# BUG-21-26: Prevent overlapping NPC dialogues
	if _is_talking: return
	_is_talking = true
	var visit_count = _npc_dialogues_done.get(npc_id, 0)
	_npc_dialogues_done[npc_id] = visit_count + 1

	match npc_id:
		"Blacksmith_Torval":
			await _dialogue_blacksmith(visit_count)
			if not is_inside_tree(): return
		"Nyx":
			await _dialogue_nyx(visit_count)
			if not is_inside_tree(): return
		"Pip":
			await _dialogue_pip(visit_count)
			if not is_inside_tree(): return
		"Marcus":
			await _dialogue_marcus(visit_count)
			if not is_inside_tree(): return
		"Vex":
			await _dialogue_vex(visit_count)
			if not is_inside_tree(): return
		"Crash":
			await _dialogue_crash(visit_count)
			if not is_inside_tree(): return
		"Null":
			await _dialogue_null(visit_count)
			if not is_inside_tree(): return
	_is_talking = false  # BUG-21-26: Release dialogue lock

# === NPC DIALOGUES ===

func _dialogue_blacksmith(visit: int) -> void:
	if visit == 0:
		await DialogueManager.say("Blacksmith Torval", "Hmph. Another outlander. You look like you've been through The Shatter recently — your edges are still fuzzy.")
		if not is_inside_tree(): return
		await DialogueManager.say("Blacksmith Torval", "I'm Torval. I forge weapons from the raw data-ore beneath Ironhold. Each blade carries a fragment of the city's source code.")
		if not is_inside_tree(): return
		await DialogueManager.say("Blacksmith Torval", "If you've got gold, I've got steel. If you've got questions, talk to Nyx — she trades in information.")
		if not is_inside_tree(): return
		await DialogueManager.say("Kaelen (Internal)", "Data-ore. Source code in the steel. Every item in this world has metadata. Of course the weapons do too.")
		if not is_inside_tree(): return
	else:
		await DialogueManager.say("Blacksmith Torval", "Back again? The arena chews through gear fast. Best be prepared before you step into the ring.")
		if not is_inside_tree(): return
	DialogueManager.hide_dialogue()

func _dialogue_nyx(visit: int) -> void:
	var knight_killed = GameManager.has_flag("ch1_knight_killed")
	var knight_spared = GameManager.has_flag("ch1_knight_spared")
	var warned_village = GameManager.has_flag("ch1_oakhaven_warned_villagers")

	if visit == 0:
		await DialogueManager.say("Nyx", "Well, well. A new thread in the weave. You smell like uncorrupted data — rare, these days.")
		if not is_inside_tree(): return
		await DialogueManager.say("Nyx", "I'm Nyx. Information broker, pattern seer, professional eavesdropper. The city's secrets flow through me.")
		if not is_inside_tree(): return

		if knight_killed:
			await DialogueManager.say("Nyx", "*tilting her head* Interesting. Your data signature carries a deletion marker. You've erased something — no, someone. A guardian entity? Bold move. The system logs don't forget, you know.")
			if not is_inside_tree(): return
			await DialogueManager.say("Kaelen (Internal)", "She can read deletion markers in my data? Aldric's death left a stain on me that others can detect. That's... unsettling.")
			if not is_inside_tree(): return
		elif knight_spared:
			await DialogueManager.say("Nyx", "*tilting her head* Interesting. Your data signature has a mercy flag attached to it. You spared something the system wanted dead? Rare behavior for someone with your level of access.")
			if not is_inside_tree(): return

		if warned_village:
			await DialogueManager.say("Nyx", "Oh, and word travels through the data streams — apparently a village called Oakhaven has been fortifying its borders. Something about a warning from a traveler. Your handiwork, I presume?")
			if not is_inside_tree(): return

		await DialogueManager.say("Nyx", "Word of advice? The Administration has been tightening its grip. New checkpoints. New patrols. Something has them spooked.")
		if not is_inside_tree(): return
		await DialogueManager.say("Nyx", "And there are whispers about something... underground. Old process threads, abandoned when the city was refactored. Nobody goes down there. Nobody comes back up.")
		if not is_inside_tree(): return
	elif visit == 1:
		await DialogueManager.say("Nyx", "You've been asking questions. Good. The arena's champion — Seraphina — she knows more than she lets on. Win a few rounds, get her attention.")
		if not is_inside_tree(): return
	else:
		await DialogueManager.say("Nyx", "The corruption is spreading faster. Can you feel it? The edges of things are getting... blurry. That's never a good sign.")
		if not is_inside_tree(): return
	DialogueManager.hide_dialogue()

func _dialogue_pip(visit: int) -> void:
	if visit == 0:
		await DialogueManager.say("Pip", "Hey! HEY! You're new! I can tell because you look around at everything like it's WEIRD!")
		if not is_inside_tree(): return
		await DialogueManager.say("Pip", "I'm Pip! I know all the shortcuts in Ironhold! Every alley, every rooftop, every loose grate!")
		if not is_inside_tree(): return
		await DialogueManager.say("Pip", "*whispering* Don't tell anyone, but I found a way into the underground tunnels. Behind the old gear factory in the residential district. But it's SCARY down there.")
		if not is_inside_tree(): return
		await DialogueManager.say("Kaelen", "Tunnels? What's down there?")
		if not is_inside_tree(): return
		await DialogueManager.say("Pip", "*shrugs* Old stuff. Broken stuff. Things that move when they shouldn't. And sometimes... lights. Like someone's still working down there.")
		if not is_inside_tree(): return
	else:
		await DialogueManager.say("Pip", "You going to the arena? The champion is AMAZING. She fights like she was born here, but she wasn't — she came from Outside, like you!")
		if not is_inside_tree(): return
	DialogueManager.hide_dialogue()

func _dialogue_marcus(visit: int) -> void:
	if visit == 0:
		await DialogueManager.say("Marcus", "Welcome to The Corroded Gear. Best ale in Ironhold, worst view. What'll it be?")
		if not is_inside_tree(): return
		await DialogueManager.say("Kaelen", "Information, if you have it. What's the situation in Ironhold?")
		if not is_inside_tree(): return
		await DialogueManager.say("Marcus", "*leans in* The Administration is running scared. Their patrols doubled last week. The clock tower's been making strange sounds. And the arena... it's the only place in the city where people still feel alive.")
		if not is_inside_tree(): return
		await DialogueManager.say("Marcus", "If you want to make a name, start there. If you want to disappear... well, I can't help you. Nobody disappears in Ironhold unless the Administration wants them to.")
		if not is_inside_tree(): return
	else:
		await DialogueManager.say("Marcus", "Another round? The ale helps with the existential dread of living in a simulated reality. ...Or so I'm told.")
		if not is_inside_tree(): return
	DialogueManager.hide_dialogue()

func _dialogue_vex(visit: int) -> void:
	if visit == 0:
		await DialogueManager.say("Vex", "Well HELLO there, fresh meat! Welcome to the Battle Arena — Ironhold's premier entertainment destination!")
		if not is_inside_tree(): return
		await DialogueManager.say("Vex", "I'm Vex, your Arena Master and tireless promoter of gratuitous violence! We've got tiers from Bronze to Platinum!")
		if not is_inside_tree(): return
		await DialogueManager.say("Vex", "Bronze for beginners — Corrupted Rats and Glitch Wolves. Silver steps it up with Guards and Sprites. Gold is where it gets REAL. And Platinum... well, let's just say nobody's beaten Platinum yet.")
		if not is_inside_tree(): return
		await DialogueManager.say("Vex", "What do you say? Ready to fight for glory, gold, and the adoration of the masses?")
		if not is_inside_tree(): return
		GameManager.set_story_flag("ch2_arena_unlocked", true)
		_arena_hint_given = true
		# PASS-35 FIX: Start arena legend quest when Vex introduces the arena
		if has_node("/root/SideQuestManager"):
			SideQuestManager.start_quest("ironhold_arena_legend")
	else:
		await DialogueManager.say("Vex", "Back for more? The crowd's been chanting your name! Pick a tier and let's FIGHT!")
		if not is_inside_tree(): return
	DialogueManager.hide_dialogue()

func _dialogue_crash(visit: int) -> void:
	if visit == 0:
		await DialogueManager.say("Crash", "*sparks flying* Oh! Didn't see you— WATCH THE GEAR SHAFT— okay, hi!")
		if not is_inside_tree(): return
		await DialogueManager.say("Crash", "I'm Crash! Mechanic, tinkerer, professional explosion-haver! I keep the arena's clockwork enemies running!")
		if not is_inside_tree(): return
		await DialogueManager.say("Crash", "Fun fact — the enemies in the arena? They're not really alive. They're compiled constructs — programmatic entities spawned from templates. Each one is a fresh instance.")
		if not is_inside_tree(): return
		await DialogueManager.say("Kaelen", "You understand how they're made?")
		if not is_inside_tree(): return
		await DialogueManager.say("Crash", "Sure! I mean, I don't know what 'compiled' MEANS exactly, but I know if you hit THIS gear with THIS wrench, a new Clockwork Soldier pops out!")
		if not is_inside_tree(): return
	else:
		await DialogueManager.say("Crash", "*covered in oil* Just finished tuning the Silver tier enemies! They should be... 15% angrier!")
		if not is_inside_tree(): return
	DialogueManager.hide_dialogue()

func _dialogue_null(visit: int) -> void:
	var knight_killed = GameManager.has_flag("ch1_knight_killed")
	var knight_spared = GameManager.has_flag("ch1_knight_spared")
	var has_elara = _has_elara()

	if visit == 0:
		await DialogueManager.say("Null", "...")
		if not is_inside_tree(): return
		await DialogueManager.say("Kaelen", "Hello? Are you—")
		if not is_inside_tree(): return
		await DialogueManager.say("Null", "You shouldn't be here. None of us should.")
		if not is_inside_tree(): return
		await DialogueManager.say("Null", "I remember... fragments. A life before this one. Or was it a previous build? Hard to tell when your memory is a corrupted cache.")
		if not is_inside_tree(): return
		await DialogueManager.say("Null", "The Source Keys. You're looking for them. I can see it in your data signature.")
		if not is_inside_tree(): return

		if knight_killed:
			await DialogueManager.say("Null", "*flinching* And I can see the shadow of something else. A deletion. A name — Aldric. You erased him. His threads are tangled in yours now... screaming silently in your data.")
			if not is_inside_tree(): return
			await DialogueManager.say("Kaelen (Internal)", "How does an NPC in a completely different region know the name of the knight I killed? Is the system propagating that data everywhere?")
			if not is_inside_tree(): return
		elif knight_spared:
			await DialogueManager.say("Null", "And something warm, too. A mercy. A name — Aldric — still running because of you. His gratitude echoes through the data streams. I can hear it from here.")
			if not is_inside_tree(): return

		if not has_elara:
			await DialogueManager.say("Null", "You walk alone. There was someone meant to walk beside you — a glitch mage. But her thread diverged from yours at the crater. She's... still out there, you know. Following at a distance. Watching.")
			if not is_inside_tree(): return
			await DialogueManager.say("Kaelen (Internal)", "Elara is following me? No. That's impossible. I turned her away. She dissolved into glitch particles and vanished. ...Didn't she?")
			if not is_inside_tree(): return

		await DialogueManager.say("Null", "There's one deep beneath us. In the place where the old processes go to die.")
		if not is_inside_tree(): return
		await DialogueManager.say("Kaelen (Internal)", "This NPC... they're different. Self-aware? Corrupted? Or something else entirely?")
		if not is_inside_tree(): return
	elif visit == 1:
		await DialogueManager.say("Null", "The Administration thinks they control everything. They don't. There are cracks in the system. Places where the code was written by a different hand.")
		if not is_inside_tree(): return
		await DialogueManager.say("Null", "You were one of the hands that wrote it, weren't you? I can taste it in your permissions.")
		if not is_inside_tree(): return
	else:
		await DialogueManager.say("Null", "The clock tower counts down to something. Not time. Events. And the next one is almost here.")
		if not is_inside_tree(): return
	DialogueManager.hide_dialogue()

# === DISTRICT TRANSITIONS ===

func _enter_arena() -> void:
	if GameManager.has_flag("ch2_arena_unlocked"):
		DialogueManager.hide_dialogue()
		SceneTransitions.change_scene("res://scenes/chapter2/arena_district.tscn")
	else:
		await DialogueManager.say("Kaelen", "The arena entrance. I should talk to the promoter first — the person in red near the gate.")
		if not is_inside_tree(): return
		DialogueManager.hide_dialogue()

func _enter_clock_tower() -> void:
	if _clock_tower_unlocked:
		DialogueManager.hide_dialogue()
		SceneTransitions.change_scene("res://scenes/chapter2/clock_tower.tscn")
	else:
		await DialogueManager.say("Kaelen", "The Clock Tower. It's locked — heavy Administration seals on the door. I need to find another way in.")
		if not is_inside_tree(): return
		DialogueManager.hide_dialogue()

func _enter_underground() -> void:
	DialogueManager.hide_dialogue()
	SceneTransitions.change_scene("res://scenes/chapter2/underground_network.tscn")

func _trigger_seraphina_encounter() -> void:
	## After beating bronze arena, Seraphina appears
	await DialogueManager.say("Vex", "Wait wait wait! Before you go anywhere — there's someone who wants to meet our newest arena star!", Color(-1, -1, -1), true)
	if not is_inside_tree(): return
	DialogueManager.hide_dialogue()
	await get_tree().create_timer(0.5).timeout
	if not is_inside_tree(): return
	SceneTransitions.change_scene("res://scenes/chapter2/seraphina_encounter.tscn")

func _trigger_administrator_arrival() -> void:
	## Administrator Proxy materializes — mandatory boss fight
	await DialogueManager.say("System", "[CRITICAL ALERT]\n[72-HOUR COUNTDOWN EXPIRED]\n[ADMINISTRATOR PROXY DEPLOYING TO IRONHOLD]\n[ALL UNAUTHORIZED ENTITIES: PREPARE FOR JUDGMENT]", Color(1, 0, 0))
	if not is_inside_tree(): return
	if camera and camera.has_method("shake"):
		camera.shake(15.0, 1.0)
	await get_tree().create_timer(2.0).timeout
	if not is_inside_tree(): return
	DialogueManager.hide_dialogue()
	SceneTransitions.change_scene("res://scenes/chapter2/administrator_boss.tscn", SceneTransitions.TransitionStyle.COMBAT_ENTRY)

func _setup_hud() -> void:
	## Create exploration HUD showing level, XP, gold
	var hud_layer = CanvasLayer.new()
	hud_layer.layer = 50
	add_child(hud_layer)

	# Top bar background
	var top_bar = ColorRect.new()
	top_bar.color = Color(0.05, 0.05, 0.1, 0.8)
	top_bar.size = Vector2(1280, 40)
	hud_layer.add_child(top_bar)

	# Level display
	var level_label = Label.new()
	level_label.name = "LevelLabel"
	level_label.text = "Lv.%d" % GameManager.player_stats["level"]
	level_label.position = Vector2(15, 8)
	level_label.add_theme_font_size_override("font_size", 16)
	level_label.add_theme_color_override("font_color", Color(0.5, 0.8, 1))
	hud_layer.add_child(level_label)

	# XP bar
	var xp_bar = ProgressBar.new()
	xp_bar.name = "XPBar"
	xp_bar.size = Vector2(150, 12)
	xp_bar.position = Vector2(80, 14)
	xp_bar.value = GameManager.get_xp_progress() * 100.0
	xp_bar.show_percentage = false
	hud_layer.add_child(xp_bar)

	# Gold display
	var gold_label = Label.new()
	gold_label.name = "GoldLabel"
	gold_label.text = "Gold: %d" % GameManager.player_stats["gold"]
	gold_label.position = Vector2(250, 8)
	gold_label.add_theme_font_size_override("font_size", 14)
	gold_label.add_theme_color_override("font_color", Color(1, 0.85, 0.1))
	hud_layer.add_child(gold_label)

	# Corruption display
	var corrupt_label = Label.new()
	corrupt_label.name = "CorruptionLabel"
	corrupt_label.text = "Corruption: %d%%" % int(GameManager.glitch_meter)
	corrupt_label.position = Vector2(400, 8)
	corrupt_label.add_theme_font_size_override("font_size", 14)
	corrupt_label.add_theme_color_override("font_color", Color(1, 0.3, 0.3))
	hud_layer.add_child(corrupt_label)

	# Location
	var location_label = Label.new()
	location_label.text = "IRONHOLD — The Steam Realm"
	location_label.position = Vector2(900, 8)
	location_label.add_theme_font_size_override("font_size", 14)
	location_label.add_theme_color_override("font_color", Color(0.6, 0.55, 0.45))
	hud_layer.add_child(location_label)
