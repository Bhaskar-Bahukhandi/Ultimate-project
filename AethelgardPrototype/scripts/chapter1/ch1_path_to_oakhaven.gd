extends Control

## Chapter 1: The Null Pointer Exception
## Sequence 3: Path to Oakhaven — Data Vision + Root Access Combat Tutorial
## Animatic cinematic that transitions into interactive Root Access tutorial

@onready var camera: CinematicCamera = $CinematicCamera
@onready var cutscene_mgr: CutsceneManager = $CutsceneManager
@onready var characters_layer = $CharactersLayer
@onready var particles_layer = $ParticlesLayer
@onready var glitch_particles = $ParticlesLayer/GlitchParticles
@onready var transition = $ScreenTransition
@onready var dialogue_box = $UILayer/DialogueBox
@onready var glitch_overlay = $EffectsLayer/GlitchOverlay
@onready var flash_overlay = $EffectsLayer/FlashOverlay
@onready var data_vision_overlay = $EffectsLayer/DataVisionOverlay
@onready var root_access_panel = $UILayer/RootAccessPanel
@onready var code_panel = $UILayer/RootAccessPanel/MarginContainer/VBox/CodePanel
@onready var elasticity_spinbox = $UILayer/RootAccessPanel/MarginContainer/VBox/PropertyList/ElasticityRow/SpinBox
@onready var apply_button = $UILayer/RootAccessPanel/MarginContainer/VBox/ApplyButton
@onready var tutorial_prompt = $UILayer/TutorialPrompt

var cinematic_active = true
var skip_requested = false
var root_access_tutorial_active = false
var slime_hacked = false
var _ambient_tweens: Array[Tween] = []

func _exit_tree() -> void:
	for tw in _ambient_tweens:
		if tw and tw.is_valid():
			tw.kill()
	_ambient_tweens.clear()

func _ready() -> void:
	print("[CH1-SEQ3] Initializing Path to Oakhaven — Combat Tutorial")
	GameManager.change_state(GameManager.GameState.PROLOGUE)
	
	cutscene_mgr.camera = camera
	cutscene_mgr.dialogue_box = dialogue_box
	cutscene_mgr.characters_container = characters_layer
	cutscene_mgr.custom_effect.connect(_on_custom_effect)
	
	camera.smooth_enabled = true
	camera.smooth_speed = 3.0
	camera.make_current()
	
	# Hide all overlay/UI initially
	dialogue_box.visible = false
	data_vision_overlay.visible = false
	root_access_panel.visible = false
	tutorial_prompt.visible = false

	# Build procedural forest path environment
	_build_environment()

	# Connect apply button
	if apply_button:
		apply_button.pressed.connect(_on_root_access_apply)
	
	await get_tree().create_timer(0.3).timeout
	if not is_inside_tree(): return
	transition.transition_in(ScreenTransition.TransitionType.FADE, 1.5)
	await transition.transition_finished
	if not is_inside_tree(): return

	# Cinematic letterbox bars
	camera.enable_letterbox(60.0, 0.8)

	await start_path_sequence()
	if not is_inside_tree(): return

func _build_environment() -> void:
	## Build the forest path environment — warmer woods approaching Oakhaven
	var env = Control.new()
	env.name = "Environment"
	env.set_anchors_preset(Control.PRESET_FULL_RECT)
	env.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(env)
	move_child(env, 0)

	# Warm twilight sky (slightly brighter than previous scene)
	var sky = ColorRect.new()
	sky.color = Color(0.1, 0.07, 0.14)
	sky.set_anchors_preset(Control.PRESET_FULL_RECT)
	sky.mouse_filter = Control.MOUSE_FILTER_IGNORE
	env.add_child(sky)

	# Warm sky gradient (sunset hint)
	var sky_warm = ColorRect.new()
	sky_warm.color = Color(0.18, 0.08, 0.06, 0.3)
	sky_warm.size = Vector2(1280, 150)
	sky_warm.position = Vector2(0, 0)
	sky_warm.mouse_filter = Control.MOUSE_FILTER_IGNORE
	env.add_child(sky_warm)

	# Distant treeline silhouette (far background layer)
	var far_trees = ColorRect.new()
	far_trees.color = Color(0.04, 0.07, 0.04, 0.7)
	far_trees.size = Vector2(1280, 120)
	far_trees.position = Vector2(0, 250)
	far_trees.mouse_filter = Control.MOUSE_FILTER_IGNORE
	env.add_child(far_trees)

	# Forest ground
	var ground = ColorRect.new()
	ground.color = Color(0.05, 0.09, 0.04)
	ground.size = Vector2(1280, 300)
	ground.position = Vector2(0, 420)
	ground.mouse_filter = Control.MOUSE_FILTER_IGNORE
	env.add_child(ground)

	# Dirt path
	var path = ColorRect.new()
	path.color = Color(0.14, 0.1, 0.06)
	path.size = Vector2(1280, 50)
	path.position = Vector2(0, 430)
	path.mouse_filter = Control.MOUSE_FILTER_IGNORE
	env.add_child(path)

	# Golden trail
	var golden = ColorRect.new()
	golden.name = "GoldenTrail"
	golden.color = Color(1.0, 0.85, 0.2, 0.2)
	golden.size = Vector2(1280, 6)
	golden.position = Vector2(0, 448)
	golden.mouse_filter = Control.MOUSE_FILTER_IGNORE
	env.add_child(golden)
	var gp = create_tween().set_loops()
	_ambient_tweens.append(gp)
	gp.tween_property(golden, "modulate:a", 0.3, 2.5).set_trans(Tween.TRANS_SINE)
	gp.tween_property(golden, "modulate:a", 1.0, 2.5).set_trans(Tween.TRANS_SINE)

	# Tree silhouettes (denser forest, approaching village)
	var tree_data = [
		[Vector2(30, 170), Vector2(45, 260)],
		[Vector2(120, 190), Vector2(38, 235)],
		[Vector2(280, 210), Vector2(32, 215)],
		[Vector2(430, 220), Vector2(28, 200)],
		[Vector2(750, 195), Vector2(35, 230)],
		[Vector2(900, 200), Vector2(40, 225)],
		[Vector2(1050, 185), Vector2(38, 240)],
		[Vector2(1180, 195), Vector2(35, 230)],
	]
	for td in tree_data:
		var green = Color(0.035, 0.065, 0.025)
		var trunk = ColorRect.new()
		trunk.color = green
		trunk.position = td[0]
		trunk.size = td[1]
		trunk.mouse_filter = Control.MOUSE_FILTER_IGNORE
		env.add_child(trunk)
		var canopy = ColorRect.new()
		canopy.color = Color(green.r + 0.025, green.g + 0.035, green.b + 0.015, 0.9)
		canopy.size = Vector2(td[1].x * 3.2, td[1].x * 2.8)
		canopy.position = Vector2(td[0].x - td[1].x * 1.1, td[0].y - td[1].x * 1.8)
		canopy.mouse_filter = Control.MOUSE_FILTER_IGNORE
		env.add_child(canopy)
		var sway = create_tween().set_loops()
		_ambient_tweens.append(sway)
		var cx = canopy.position.x
		sway.tween_property(canopy, "position:x", cx + randf_range(2, 6), randf_range(3.0, 5.5)).set_trans(Tween.TRANS_SINE).set_delay(randf_range(0, 2.5))
		sway.tween_property(canopy, "position:x", cx - randf_range(2, 6), randf_range(3.0, 5.5)).set_trans(Tween.TRANS_SINE)

	# Fireflies (warmer color, more of them near village)
	for i in range(10):
		var fly = ColorRect.new()
		fly.color = Color(1.0, 0.9, 0.3, randf_range(0.15, 0.45))
		fly.size = Vector2(3, 3)
		var fy = randf_range(180, 410)
		var fx = randf_range(60, 1220)
		fly.position = Vector2(fx, fy)
		fly.mouse_filter = Control.MOUSE_FILTER_IGNORE
		env.add_child(fly)
		var ff = create_tween().set_loops()
		_ambient_tweens.append(ff)
		ff.tween_property(fly, "position", Vector2(fx + randf_range(-35, 35), fy + randf_range(-25, 25)), randf_range(3, 6)).set_trans(Tween.TRANS_SINE).set_delay(randf_range(0, 3))
		ff.tween_property(fly, "modulate:a", randf_range(0.1, 0.3), randf_range(1, 2.5))
		ff.tween_property(fly, "position", Vector2(fx + randf_range(-35, 35), fy + randf_range(-25, 25)), randf_range(3, 6)).set_trans(Tween.TRANS_SINE)
		ff.tween_property(fly, "modulate:a", 1.0, randf_range(1, 2.5))

	# Distant village glow (warm light on the right horizon)
	var village_glow = ColorRect.new()
	village_glow.color = Color(0.25, 0.15, 0.05, 0.2)
	village_glow.size = Vector2(300, 150)
	village_glow.position = Vector2(980, 280)
	village_glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	env.add_child(village_glow)
	var vg = create_tween().set_loops()
	_ambient_tweens.append(vg)
	vg.tween_property(village_glow, "modulate:a", 0.5, 3.5).set_trans(Tween.TRANS_SINE)
	vg.tween_property(village_glow, "modulate:a", 1.0, 3.5).set_trans(Tween.TRANS_SINE)

	# Vignette
	var vig_top = ColorRect.new()
	vig_top.color = Color(0, 0, 0.01, 0.45)
	vig_top.size = Vector2(1280, 100)
	vig_top.position = Vector2(0, 0)
	vig_top.mouse_filter = Control.MOUSE_FILTER_IGNORE
	env.add_child(vig_top)
	var vig_bot = ColorRect.new()
	vig_bot.color = Color(0, 0, 0, 0.45)
	vig_bot.size = Vector2(1280, 100)
	vig_bot.position = Vector2(0, 620)
	vig_bot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	env.add_child(vig_bot)

func start_path_sequence() -> void:
	## Play Data Vision tutorial + Slime encounter with Root Access
	
	var has_elara = GameManager.story_flags.get("ch1_elara_trusted", false) or GameManager.story_flags.get("ch1_elara_cautious", false)
	
	# Part 1: Walking + Data Vision demonstration
	var cutscene
	if has_elara:
		cutscene = create_path_cutscene()
	else:
		cutscene = create_solo_path_cutscene()
	cutscene_mgr.play_cutscene(cutscene)
	await cutscene_mgr.cutscene_finished
	if not is_inside_tree(): return
	
	if skip_requested:
		await transition_to_oakhaven()
		return
	
	# Part 2: Data Vision activation
	await play_data_vision_sequence()
	if not is_inside_tree(): return
	
	# Part 3: Slime encounter + Root Access tutorial
	await play_slime_encounter()
	if not is_inside_tree(): return
	
	# Part 4: Root Access interactive tutorial
	await play_root_access_tutorial()
	if not is_inside_tree(): return
	
	# Part 5: Post-hack dialogue
	await play_post_hack_dialogue()
	if not is_inside_tree(): return
	
	# Transition to Oakhaven Village
	transition_to_oakhaven()

func create_path_cutscene() -> Dictionary:
	## Walking dialogue between Kaelen and Elara on the path — expanded
	return {
		"name": "Chapter 1 - Path to Oakhaven",
		"beats": [
			# Beat 1: Wide shot — establishing the forest path
			{
				"type": "camera_move",
				"target": Vector2(640, 360),
				"duration": 0.5
			},
			
			# Beat 2: Kaelen and Elara enter walking together
			{
				"type": "parallel",
				"beats": [
					{
						"type": "character_enter",
						"character": "Kaelen",
						"position": Vector2(300, 420),
						"from": "left",
						"duration": 2.0
					},
					{
						"type": "character_enter",
						"character": "Elara",
						"position": Vector2(380, 420),
						"from": "left",
						"duration": 2.5
					}
				]
			},
			
			# Beat 3: Walk forward together
			{
				"type": "parallel",
				"beats": [
					{
						"type": "character_move",
						"character": "Kaelen",
						"target": Vector2(500, 420),
						"duration": 3.0
					},
					{
						"type": "character_move",
						"character": "Elara",
						"target": Vector2(580, 420),
						"duration": 3.0
					},
					{
						"type": "camera_move",
						"target": Vector2(540, 360),
						"duration": 3.0
					}
				]
			},
			
			# Beat 4: Kaelen's observation about the world
			{
				"type": "dialogue",
				"speaker": "Kaelen",
				"text": "Some of these rocks are see-through from certain angles. Like only the front side was finished and nobody bothered with the back.",
				"auto_advance": false
			},
			
			# Beat 5: Kaelen notices things shifting
			{
				"type": "dialogue",
				"speaker": "Kaelen",
				"text": "And that boulder — it was a blurry blob two seconds ago, and when I looked at it, it just SNAPPED into sharp detail. No gradual change. Just... pop.",
				"auto_advance": false
			},
			
			# Beat 6: Elara's warning about the environment
			{
				"type": "dialogue",
				"speaker": "Elara",
				"text": "The trees have ears here, Kaelen. And some of the rocks... they listen. Be careful what you say out loud — not everything that looks like scenery IS just scenery.",
				"auto_advance": false
			},
			
			# Beat 7: Kaelen's reaction
			{
				"type": "dialogue",
				"speaker": "Kaelen",
				"text": "The scenery is eavesdropping? That's... actually terrifying. Back home, we could barely get our phones to understand us, and here the ROCKS are spying on people.",
				"auto_advance": false
			},
			
			# Beat 8: Elara elaborates on the System
			{
				"type": "dialogue",
				"speaker": "Elara",
				"text": "The System Administrator doesn't just run this world. It WATCHES. Every change you make, every ability you use — there's something recording all of it. Always.",
				"auto_advance": false
			},
			
			# Weight of surveillance
			{
				"type": "camera_shake",
				"intensity": 3.0,
				"duration": 0.3
			},
			{
				"type": "wait",
				"duration": 1.5
			},
			
			# Beat 9: Kaelen notices the repetition
			{
				"type": "dialogue",
				"speaker": "Kaelen (Internal)",
				"text": "Fourteen identical bushes, just rotated so they don't look the same. They do, though. *half-smile* ...Reminds me of every project I ever crunched on. Cutting corners to meet a deadline.",
				"auto_advance": false
			},
			
			# Beat 10: Continue walking — camera tracks
			{
				"type": "parallel",
				"beats": [
					{
						"type": "character_move",
						"character": "Kaelen",
						"target": Vector2(600, 420),
						"duration": 2.5
					},
					{
						"type": "character_move",
						"character": "Elara",
						"target": Vector2(680, 420),
						"duration": 2.5
					},
					{
						"type": "camera_move",
						"target": Vector2(640, 360),
						"duration": 2.5
					}
				]
			},
			
			# Beat 11: Elara asks about Kaelen's world
			{
				"type": "dialogue",
				"speaker": "Elara",
				"text": "What was YOUR world like? Before the crash, I mean. Were there... limits? Edges? Places where the world just... stopped?",
				"auto_advance": false
			},
			
			# Beat 12: Kaelen answers thoughtfully
			{
				"type": "dialogue",
				"speaker": "Kaelen",
				"text": "No edges you could see. But we had our own kind of limits — deadlines that crushed people, jobs that asked you to do the same thing every day and call it progress. Our world had its own kind of broken. It just hid it better.",
				"auto_advance": false
			},
			
			# Beat 13: Elara's fascination
			{
				"type": "dialogue",
				"speaker": "Elara",
				"text": "A world without rules written underneath everything... I can't imagine it. How do you fix things when you can't see what's broken underneath?",
				"auto_advance": false
			},
			
			# Beat 14: Kaelen — bittersweet answer
			{
				"type": "dialogue",
				"speaker": "Kaelen",
				"text": "Badly. We argue about whose fault it is, write reports nobody reads, and rebrand the chaos every few years so it sounds like we're doing it on purpose.",
				"auto_advance": false
			},
			
			# Bittersweet humor settling + tone shift
			{
				"type": "wait",
				"duration": 1.5
			},
			{
				"type": "camera_zoom",
				"zoom": Vector2(1.1, 1.1),
				"duration": 1.0
			},
			
			# Beat 15: Elara stops — senses something
			{
				"type": "dialogue",
				"speaker": "Elara",
				"text": "*stops walking* Hold on. Something's changing in you. I can feel it — like a door just opened somewhere inside your mind. A new ability is waking up.",
				"auto_advance": false
			},
			
			# Beat 16: Camera focuses on Kaelen as HUD element appears
			{
				"type": "camera_move",
				"target": Vector2(600, 340),
				"duration": 0.8
			},
			
			# Beat 17: System prompt — Data Vision unlock
			{
				"type": "dialogue",
				"speaker": "System",
				"text": "[DATA VISION — UNLOCKED]\n[Toggle: L3 / TAB]\n[See the truth beneath the surface — hidden paths, enemy weaknesses, and secrets the world tries to keep from you.]",
				"auto_advance": true,
				"duration": 3.5
			},
			
			# Beat 18: Elara explains Data Vision
			{
				"type": "dialogue",
				"speaker": "Elara",
				"text": "Data Vision! It's like... you know how I can sometimes see beneath the surface of things? This is the stable version of that. Hidden doors, enemy weaknesses, traps — everything the world doesn't want you to see.",
				"auto_advance": false
			},
			
			# Beat 19: Kaelen's reaction
			{
				"type": "dialogue",
				"speaker": "Kaelen",
				"text": "A way to see the truth underneath everything. That's... actually the first thing in this world that makes me feel like I have some control. Like I can finally understand what's really happening around me.",
				"auto_advance": false
			},
			
			# Beat 20: Elara's warning about overuse
			{
				"type": "dialogue",
				"speaker": "Elara",
				"text": "Just don't use it for too long. The more you look beneath the surface, the more the System Administrator notices you looking. And you don't want its full attention.",
				"auto_advance": false
			},
		]
	}

func create_solo_path_cutscene() -> Dictionary:
	## Solo walking cutscene when player distrusted Elara — lonelier, introspective
	return {
		"name": "Chapter 1 - Solo Path to Oakhaven",
		"beats": [
			{
				"type": "camera_move",
				"target": Vector2(640, 360),
				"duration": 0.5
			},
			{
				"type": "character_enter",
				"character": "Kaelen",
				"position": Vector2(300, 420),
				"from": "left",
				"duration": 2.0
			},
			{
				"type": "character_move",
				"character": "Kaelen",
				"target": Vector2(500, 420),
				"duration": 3.0
			},
			{
				"type": "dialogue",
				"speaker": "Kaelen (Internal)",
				"text": "Alone. The forest is quiet — too quiet. Without Elara filling the silence, every snap of a twig and every rustle of leaves sounds like something following me.",
				"auto_advance": false
			},
			{
				"type": "dialogue",
				"speaker": "Kaelen (Internal)",
				"text": "Did I make the right call? She seemed genuine. But genuine is easy to fake when someone needs something from you. In my line of work, the most convincing voices were always the ones with hidden agendas.",
				"auto_advance": false
			},
			{
				"type": "dialogue",
				"speaker": "Kaelen (Internal)",
				"text": "The rocks here are see-through from the back. Fourteen identical bushes. The trees pop into detail when I look at them. This world is a rush job held together with duct tape and good intentions.",
				"auto_advance": false
			},
			{
				"type": "character_move",
				"character": "Kaelen",
				"target": Vector2(600, 420),
				"duration": 2.5
			},
			{
				"type": "dialogue",
				"speaker": "Kaelen (Internal)",
				"text": "Elara said the trees have ears. That the System Administrator watches everything. If she was telling the truth about THAT, then going solo means I'm harder to track but I have no one covering my blind spots.",
				"auto_advance": false
			},
			{
				"type": "dialogue",
				"speaker": "Kaelen (Internal)",
				"text": "If she was lying... well, then I'm exactly where I should be. On my own, trusting my own instincts, not relying on someone I met twenty minutes ago in a world where nothing is what it seems.",
				"auto_advance": false
			},
			{
				"type": "camera_shake",
				"intensity": 3.0,
				"duration": 0.3
			},
			{
				"type": "wait",
				"duration": 1.5
			},
			{
				"type": "camera_zoom",
				"zoom": Vector2(1.1, 1.1),
				"duration": 1.0
			},
			{
				"type": "dialogue",
				"speaker": "System",
				"text": "[ANOMALY SCAN: New ability detected in user process]\n[DATA VISION — UNLOCKED]\n[Toggle: L3 / TAB]\n[See the truth beneath the surface]",
				"auto_advance": true,
				"duration": 3.5
			},
			{
				"type": "dialogue",
				"speaker": "Kaelen",
				"text": "A new ability? Data Vision... the system just handed me the ability to see beneath the surface. Either this is a standard progression reward, or someone wants me to see what's really happening here.",
				"auto_advance": false
			},
			{
				"type": "dialogue",
				"speaker": "Kaelen (Internal)",
				"text": "No guide to explain it. No friendly voice walking me through. Just me and a new set of eyes. ...Fine. I've learned harder things on my own. Let's see what this world is hiding.",
				"auto_advance": false
			},
		]
	}

func play_data_vision_sequence() -> void:
	## Activate Data Vision mode — expanded visual/dialogue shift
	print("[CH1-SEQ3] Activating Data Vision")
	
	var has_elara = GameManager.story_flags.get("ch1_elara_trusted", false) or GameManager.story_flags.get("ch1_elara_cautious", false)
	
	GameManager.set_story_flag("ch1_data_vision_unlocked", true)
	
	# Flash to indicate mode change
	flash_overlay.color = Color(0.0, 0.8, 0.0, 0.3)
	flash_overlay.modulate.a = 0.5
	await get_tree().create_timer(0.2).timeout
	if not is_inside_tree(): return
	
	# Enable Data Vision overlay (green wireframe schematic)
	data_vision_overlay.visible = true
	var tween = create_tween()
	tween.tween_property(data_vision_overlay, "modulate:a", 0.6, 1.0)
	await tween.finished
	if not is_inside_tree(): return
	
	flash_overlay.modulate.a = 0.0
	
	# Kaelen's first impression
	await DialogueManager.say("Kaelen", "Oh. Oh, that's... I can see everything. The hidden barriers, the danger zones, the traps waiting to spring. This world has been hiding SO much from me.")
	if not is_inside_tree(): return
	
	# Let the player absorb Data Vision's impact
	camera.shake(3.0, 0.2)
	await get_tree().create_timer(1.5).timeout
	if not is_inside_tree(): return
	
	# Show floating object tags
	await DialogueManager.say("Data Vision", "[Rock — Solid, harmless]\n[Tree — LISTENING — reports to System Administrator]\n[Hidden Door detected — locked — requires a KEY FRAGMENT to open]", Color(0.0, 1.0, 0.0))
	if not is_inside_tree(): return
	
	# Kaelen spots the hidden door
	await DialogueManager.say("Kaelen", "There's a hidden door here. Locked — needs some kind of key. I'll remember that. This vision is already worth more than any weapon.")
	if not is_inside_tree(): return
	
	# More Data Vision tags — enemy detection
	await DialogueManager.say("Data Vision", "[HOSTILE DETECTED — 40 meters ahead]\n[Green Slime — Health: 30 — Weak, bouncy]\n[Weakness: Its bounce can be CHANGED through Root Access]", Color(0.0, 1.0, 0.0))
	if not is_inside_tree(): return
	
	# Elara's guidance (or solo deduction)
	if has_elara:
		await DialogueManager.say("Elara", "See that marker on the slime? 'Root Access compatible' — that means you can reach inside it and change what makes it tick. Most simple creatures have at least one thing you can alter.")
		if not is_inside_tree(): return
	else:
		await DialogueManager.say("Kaelen (Internal)", "'Root Access compatible.' That marker on the slime — it means I can reach inside it and change its properties. The system WANTS me to experiment with this. Why? What's it grooming me for?", Color(0.5, 0.9, 1.0))
		if not is_inside_tree(): return
	
	# System Monitor notice
	await DialogueManager.say("System", "[Data Vision has been active for a while]\n[System Administrator awareness: LOW]\n[Consider turning it off to stay under the radar]", Color(1.0, 0.5, 0.0), true)
	if not is_inside_tree(): return
	
	# Kaelen deactivates
	await DialogueManager.say("Kaelen", "Right. The longer I look, the more attention I draw. I'll save this for when I really need it.")
	if not is_inside_tree(): return
	
	# Disable Data Vision
	DialogueManager.hide_dialogue()
	tween = create_tween()
	tween.tween_property(data_vision_overlay, "modulate:a", 0.0, 0.8)
	await tween.finished
	if not is_inside_tree(): return
	data_vision_overlay.visible = false

func play_slime_encounter() -> void:
	## Green Slime appears blocking the path — expanded encounter
	print("[CH1-SEQ3] Slime encounter begins")
	
	# Camera shakes as slime appears
	camera.shake(5.0, 0.3)
	
	# Slime enters from right
	var slime_node = characters_layer.get_node_or_null("GreenSlime")
	if not slime_node:
		# Create placeholder slime
		slime_node = ColorRect.new()
		slime_node.name = "GreenSlime"
		slime_node.color = Color(0.2, 0.8, 0.2)
		slime_node.size = Vector2(60, 40)
		slime_node.position = Vector2(900, 410)
		characters_layer.add_child(slime_node)
	
	slime_node.visible = true
	var tween = create_tween()
	tween.tween_property(slime_node, "position", Vector2(700, 410), 1.5)
	await tween.finished
	if not is_inside_tree(): return
	
	# Camera focuses on slime
	camera.move_to(Vector2(700, 380), 1.0)
	await get_tree().create_timer(1.5).timeout
	if not is_inside_tree(): return
	
	# Kaelen's initial reaction
	await DialogueManager.say("Kaelen", "It hasn't noticed me yet. It's just... bouncing there. Going nowhere. Doesn't look dangerous, but nothing in this world is what it seems.")
	if not is_inside_tree(): return
	
	# Slime hop animation
	var hop_tween = create_tween()
	hop_tween.tween_property(slime_node, "position:y", 380.0, 0.3)
	hop_tween.tween_property(slime_node, "position:y", 410.0, 0.3)
	await hop_tween.finished
	if not is_inside_tree(): return
	
	# Elara's comment (or solo observation)
	var has_elara_slime = GameManager.story_flags.get("ch1_elara_trusted", false) or GameManager.story_flags.get("ch1_elara_cautious", false)
	if has_elara_slime:
		await DialogueManager.say("Elara", "Don't underestimate them. The deeper the corruption runs in an area, the stronger they get. And you stirred things up just by crossing that bridge.")
		if not is_inside_tree(): return
	else:
		await DialogueManager.say("Kaelen (Internal)", "It doesn't look threatening, but I've been a game designer long enough to know that the tutorial enemies exist to teach you something. The question is: what lesson is this slime supposed to teach?", Color(0.5, 0.9, 1.0))
		if not is_inside_tree(): return
	
	# Kaelen considers options
	await DialogueManager.say("Kaelen (Internal)", "I could fight this thing head-on — hit it until it stops moving. The classic approach. But Root Access lets me look inside it and change the rules. Why fight fair when I can fight smart?")
	if not is_inside_tree(): return
	
	# Elara encourages Root Access (or solo approach)
	if has_elara_slime:
		await DialogueManager.say("Elara", "This is a good time to practice Root Access. Focus on the slime and you should be able to see what makes it work. Look for something you can change.")
		if not is_inside_tree(): return
	else:
		await DialogueManager.say("System", "[SUGGESTION: Use ROOT ACCESS on the target]\n[Focus on the entity to view modifiable properties]\n[Modify a core property to neutralize the threat]", Color(0.0, 1.0, 1.0), true)
		if not is_inside_tree(): return
	
	# Kaelen prepares
	await DialogueManager.say("Kaelen", "Alright. Let me concentrate... I can feel it — like pulling back a curtain. I can see what this thing is made of.")
	if not is_inside_tree(): return
	
	# Another slime hop
	DialogueManager.hide_dialogue()
	hop_tween = create_tween()
	hop_tween.tween_property(slime_node, "position:y", 385.0, 0.25)
	hop_tween.tween_property(slime_node, "position:y", 410.0, 0.25)
	await hop_tween.finished
	if not is_inside_tree(): return
	
	await get_tree().create_timer(0.5).timeout
	if not is_inside_tree(): return

func play_root_access_tutorial() -> void:
	## Interactive Root Access tutorial — player modifies slime's elasticity
	print("[CH1-SEQ3] Root Access Tutorial begins")
	
	# System pause — freeze frame effect
	await DialogueManager.say("System", "[ROOT ACCESS — ENABLED]\n[TARGET: Green Slime]\n[You can see its inner workings. Find what makes it bounce — and take it away.]", Color.RED, true)
	if not is_inside_tree(): return
	
	# Elara coaching (or system guide)
	var has_elara_ra = GameManager.story_flags.get("ch1_elara_trusted", false) or GameManager.story_flags.get("ch1_elara_cautious", false)
	if has_elara_ra:
		await DialogueManager.say("Elara", "See that panel? When you focus on a creature with Root Access, you can see what drives it. This slime's whole existence is built around bouncing — its 'elasticity.' Set that to zero and...")
		if not is_inside_tree(): return
	
	# Kaelen understands
	await DialogueManager.say("Kaelen", "Take away its ability to bounce. No spring, no jump, no attack. It just... collapses. That's almost too clean.")
	if not is_inside_tree(): return
	
	# System warning about corruption cost
	await DialogueManager.say("System", "[WARNING: Every change you make through Root Access has a cost]\n[Each edit adds CORRUPTION to your body]\n[Too much corruption, and you won't survive]", Color(1.0, 0.5, 0.0), true)
	if not is_inside_tree(): return
	
	# Kaelen acknowledges the risk
	await DialogueManager.say("Kaelen (Internal)", "So every time I rewrite something in this world, it rewrites something in me. Power with a price tag. Nothing is free — not here, not anywhere.")
	if not is_inside_tree(): return
	
	DialogueManager.hide_dialogue()
	
	# Check if UI elements exist — if not, auto-complete the tutorial
	if not root_access_panel or not apply_button:
		print("[CH1-SEQ3] Root Access UI not found — auto-completing tutorial")
		await get_tree().create_timer(1.0).timeout
		if not is_inside_tree(): return
		await DialogueManager.say("System", "[Elasticity set to 0.0 — Slime neutralized]", Color(0.0, 1.0, 0.5), true)
		if not is_inside_tree(): return
		DialogueManager.hide_dialogue()
		slime_hacked = true
		GameManager.add_glitch_corruption(10.0)
		return
	
	# Show the tutorial prompt
	if tutorial_prompt:
		tutorial_prompt.visible = true
		tutorial_prompt.text = "ROOT ACCESS TUTORIAL:\nOpen the Inspector panel below.\nSet 'elasticity' to 0.0 to remove the slime's bounce.\nPress [APPLY] to make the change."
	
	# Show Inspector Window (Root Access Panel)
	root_access_panel.visible = true
	root_access_tutorial_active = true
	
	# Set code panel text
	if code_panel:
		code_panel.text = "Green Slime — Properties:\n\n  [Changeable] elasticity = 1.0\n  [Changeable] is_hostile = true\n\n  (Read-only)\n  health = 30\n  awareness_range = 5.0\n  behavior = bounce"
	
	# Set spinbox defaults
	if elasticity_spinbox:
		elasticity_spinbox.value = 1.0
		elasticity_spinbox.min_value = 0.0
		elasticity_spinbox.max_value = 5.0
		elasticity_spinbox.step = 0.1
	
	# Wait for player to apply the hack — with safety timeout
	var wait_time = 0.0
	while not slime_hacked:
		await get_tree().create_timer(0.1).timeout
		if not is_inside_tree(): return
		wait_time += 0.1
		if wait_time > 120.0:  # 2-minute safety timeout
			print("[CH1-SEQ3] Root Access tutorial timed out — auto-completing")
			slime_hacked = true
			GameManager.add_glitch_corruption(10.0)
			break
	
	# Tutorial complete
	if root_access_panel:
		root_access_panel.visible = false
	if tutorial_prompt:
		tutorial_prompt.visible = false
	root_access_tutorial_active = false

func _on_root_access_apply() -> void:
	## Player applied the root access hack
	if not root_access_tutorial_active:
		return
	
	var new_elasticity = 1.0
	if elasticity_spinbox:
		new_elasticity = elasticity_spinbox.value
	
	# Check if player set elasticity to 0
	if new_elasticity <= 0.1:
		slime_hacked = true
		print("[CH1-SEQ3] Root Access: Elasticity set to %.1f — CORRECT!" % new_elasticity)
		
		# Corruption cost
		GameManager.add_glitch_corruption(10.0)
	else:
		# Give hint
		if tutorial_prompt:
			tutorial_prompt.text = "HINT: Set elasticity to 0.0 to prevent the slime from bouncing back."

func play_post_hack_dialogue() -> void:
	## Post-hack sequence — slime splats flat — expanded aftermath
	
	# Animate slime flattening (splatting)
	var slime_node = characters_layer.get_node_or_null("GreenSlime")
	if slime_node:
		# Slime tries to hop but splats flat
		var tween = create_tween()
		tween.tween_property(slime_node, "position:y", 395.0, 0.2)
		tween.tween_property(slime_node, "position:y", 430.0, 0.1)
		# Flatten it
		tween.tween_property(slime_node, "scale", Vector2(2.5, 0.1), 0.2)
		await tween.finished
		if not is_inside_tree(): return
	
	# Camera slight shake on impact
	camera.shake(3.0, 0.2)
	
	await get_tree().create_timer(0.5).timeout
	if not is_inside_tree(): return
	
	# Kaelen's reaction line
	await DialogueManager.say("Kaelen", "It tried to bounce back up and just... collapsed. Without that spring, it's nothing. It couldn't even move toward me.")
	if not is_inside_tree(): return
	
	# Slime dissolution VFX
	if slime_node:
		var dissolve_tween = create_tween()
		dissolve_tween.tween_property(slime_node, "modulate:a", 0.0, 1.5)
		# Don't await — let it dissolve during dialogue
	
	# Elara impressed (or solo reflection)
	var has_elara_post = GameManager.story_flags.get("ch1_elara_trusted", false) or GameManager.story_flags.get("ch1_elara_cautious", false)
	if has_elara_post:
		await DialogueManager.say("Elara", "Not bad for your first time! Most people just hit things until they stop moving. You're already thinking differently!")
		if not is_inside_tree(): return
	else:
		await DialogueManager.say("Kaelen (Internal)", "First Root Access hack — successful. The system rewarded me for doing it, which means this is the INTENDED path. They want anomalies to learn this ability. But why?", Color(0.5, 0.9, 1.0))
		if not is_inside_tree(): return
	
	# Kaelen reflects on the ethical dimension
	await DialogueManager.say("Kaelen (Internal)", "I just reached inside a living creature and took away the one thing that defined it. In my old job, we'd call that a 'feature removal.' Here, it felt more like surgery without anesthesia.")
	if not is_inside_tree(): return
	
	# The question that will echo later
	await DialogueManager.say("Kaelen (Internal)", "The slime dissolved. No cry, no struggle. It just... stopped existing. I wonder if it felt anything. I wonder if that should bother me more than it does.")
	if not is_inside_tree(): return
	
	# Ethical weight of Root Access — let it breathe
	DialogueManager.hide_dialogue()
	await get_tree().create_timer(2.0).timeout
	if not is_inside_tree(): return
	
	# Corruption system notice
	await DialogueManager.say("System", "[ROOT ACCESS TUTORIAL — COMPLETE]\n[Variables modified: 1 (elasticity: 1.0 → 0.0)]\n[CORRUPTION: +10%%]\n[Total CORRUPTION: %.0f%%]" % GameManager.glitch_meter, Color(1.0, 0.3, 0.3), true)
	if not is_inside_tree(): return
	
	# Loot / reward
	await DialogueManager.say("System", "[LOOT: +15 MEMORY FRAGMENTS]\n[ITEM ACQUIRED: Slime Core (crafting material)]\n[Root Access proficiency: NOVICE]", Color(0.0, 1.0, 0.5), true)
	if not is_inside_tree(): return
	
	GameManager.set_story_flag("ch1_slime_root_access_tutorial", true)
	GameManager.set_story_flag("root_access_unlocked", true)
	
	# Elara points ahead (or solo observation)
	if has_elara_post:
		await DialogueManager.say("Elara", "Oakhaven is just ahead. Don't let the cozy village look fool you — the people there have their own stories. And the shopkeeper drives a hard bargain.")
		if not is_inside_tree(): return
		await DialogueManager.say("Kaelen", "A village full of people living in a world that's falling apart, and they don't even know it. ...Lead the way, Elara.")
		if not is_inside_tree(): return
	else:
		await DialogueManager.say("Kaelen (Internal)", "A warm glow through the trees. The path widens, the air shifts from wild to settled. Village ahead. People — trapped in their loops, oblivious to the cracks in their reality. But people nonetheless. And right now, I need supplies more than I need solitude.", Color(0.5, 0.9, 1.0))
		if not is_inside_tree(): return
	
	DialogueManager.hide_dialogue()

var _is_transitioning_to_oakhaven: bool = false

func transition_to_oakhaven() -> void:
	## Transition to Sequence 4: Oakhaven Village
	if _is_transitioning_to_oakhaven:
		return
	_is_transitioning_to_oakhaven = true
	print("[CH1-SEQ3] Transitioning to Oakhaven Village")

	DialogueManager.hide_dialogue()
	if transition:
		camera.disable_letterbox(0.4)
		await transition.transition_out(ScreenTransition.TransitionType.FADE, 1.5)
		if not is_inside_tree(): return
		await get_tree().create_timer(0.3).timeout
		if not is_inside_tree(): return
	else:
		# Fallback fade if transition node doesn't exist
		var fallback_fade = ColorRect.new()
		fallback_fade.color = Color.BLACK
		fallback_fade.modulate.a = 0.0
		fallback_fade.size = get_viewport_rect().size
		add_child(fallback_fade)
		var tween = create_tween()
		tween.tween_property(fallback_fade, "modulate:a", 1.0, 1.5)
		await tween.finished
		if not is_inside_tree(): return
	
	SceneTransitions.change_scene("res://scenes/chapter1/oakhaven_village.tscn")

func _on_custom_effect(effect_name: String, parameters: Dictionary) -> void:
	match effect_name:
		"glitch_screen":
			glitch_overlay.visible = true
			glitch_overlay.color = Color(0.5, 1.0, 0.5, 0.4)
			await get_tree().create_timer(parameters.get("duration", 0.3)).timeout
			if not is_inside_tree(): return
			glitch_overlay.visible = false
		_:
			print("[CH1-SEQ3 EFFECT] Unhandled: %s" % effect_name)

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"):
		if root_access_tutorial_active:
			return  # Don't skip during tutorial
