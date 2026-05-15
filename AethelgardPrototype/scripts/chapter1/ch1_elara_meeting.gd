extends Control

## Chapter 1: The Null Pointer Exception
## Sequence 2: First Contact — Meeting Elara the Glitch-Witch
## Animatic cinematic with full dialogue as per design doc

@onready var camera: CinematicCamera = $CinematicCamera
@onready var cutscene_mgr: CutsceneManager = $CutsceneManager
@onready var characters_layer = $CharactersLayer
@onready var particles_layer = $ParticlesLayer
@onready var glitch_particles = $ParticlesLayer/GlitchParticles
@onready var static_particles = $ParticlesLayer/StaticNoise
@onready var transition = $ScreenTransition
@onready var dialogue_box = $UILayer/DialogueBox
@onready var glitch_overlay = $EffectsLayer/GlitchOverlay
@onready var flash_overlay = $EffectsLayer/FlashOverlay
@onready var null_block_visual = $EffectsLayer/NullBlockVisual

var cinematic_active = true
var skip_requested = false
var _is_transitioning = false
var _ambient_tweens: Array[Tween] = []

func _exit_tree() -> void:
	for tw in _ambient_tweens:
		if tw and tw.is_valid():
			tw.kill()
	_ambient_tweens.clear()

func _ready() -> void:
	print("[CH1-SEQ2] Initializing Elara the Glitch-Witch meeting")
	GameManager.change_state(GameManager.GameState.PROLOGUE)
	
	cutscene_mgr.camera = camera
	cutscene_mgr.dialogue_box = dialogue_box
	cutscene_mgr.characters_container = characters_layer
	cutscene_mgr.custom_effect.connect(_on_custom_effect)
	
	camera.smooth_enabled = true
	camera.smooth_speed = 3.0
	camera.make_current()
	
	dialogue_box.visible = false
	if null_block_visual:
		null_block_visual.visible = false

	# Build procedural forest environment
	_build_environment()

	await get_tree().create_timer(0.3).timeout
	if not is_inside_tree(): return
	
	# Fade in from the previous glitch transition
	transition.transition_in(ScreenTransition.TransitionType.FADE, 1.5)
	await transition.transition_finished
	if not is_inside_tree(): return

	# Cinematic letterbox bars
	camera.enable_letterbox(60.0, 0.8)

	await start_elara_meeting()
	if not is_inside_tree(): return

func _build_environment() -> void:
	## Build the forest clearing environment — twilight woods with golden trail
	var env = Control.new()
	env.name = "Environment"
	env.set_anchors_preset(Control.PRESET_FULL_RECT)
	env.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(env)
	move_child(env, 0)

	# Twilight sky — visible dark blue-purple
	var sky = ColorRect.new()
	sky.color = Color(0.16, 0.1, 0.28)
	sky.set_anchors_preset(Control.PRESET_FULL_RECT)
	sky.mouse_filter = Control.MOUSE_FILTER_IGNORE
	env.add_child(sky)

	# Upper sky glow
	var sky_glow = ColorRect.new()
	sky_glow.color = Color(0.25, 0.12, 0.4, 0.4)
	sky_glow.size = Vector2(1280, 180)
	sky_glow.position = Vector2(0, 0)
	sky_glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	env.add_child(sky_glow)

	# Forest ground — visible dark green
	var ground = ColorRect.new()
	ground.color = Color(0.08, 0.16, 0.06)
	ground.size = Vector2(1280, 300)
	ground.position = Vector2(0, 420)
	ground.mouse_filter = Control.MOUSE_FILTER_IGNORE
	env.add_child(ground)

	# Dirt path
	var path = ColorRect.new()
	path.color = Color(0.22, 0.16, 0.08)
	path.size = Vector2(1280, 50)
	path.position = Vector2(0, 430)
	path.mouse_filter = Control.MOUSE_FILTER_IGNORE
	env.add_child(path)

	# Golden trail on the path
	var golden = ColorRect.new()
	golden.name = "GoldenTrail"
	golden.color = Color(1.0, 0.85, 0.2, 0.4)
	golden.size = Vector2(1280, 6)
	golden.position = Vector2(0, 448)
	golden.mouse_filter = Control.MOUSE_FILTER_IGNORE
	env.add_child(golden)
	var gp = create_tween().set_loops()
	_ambient_tweens.append(gp)
	gp.tween_property(golden, "modulate:a", 0.4, 2.0).set_trans(Tween.TRANS_SINE)
	gp.tween_property(golden, "modulate:a", 1.0, 2.0).set_trans(Tween.TRANS_SINE)

	# Tree silhouettes (background trees on both sides)
	var tree_data = [
		[Vector2(50, 180), Vector2(40, 240)],
		[Vector2(180, 200), Vector2(35, 220)],
		[Vector2(350, 210), Vector2(30, 210)],
		[Vector2(800, 190), Vector2(38, 230)],
		[Vector2(950, 195), Vector2(42, 225)],
		[Vector2(1100, 185), Vector2(36, 235)],
		[Vector2(1200, 200), Vector2(32, 220)],
	]
	for td in tree_data:
		var base_green = Color(0.06, 0.14, 0.04)
		# Trunk
		var trunk = ColorRect.new()
		trunk.color = base_green
		trunk.position = td[0]
		trunk.size = td[1]
		trunk.mouse_filter = Control.MOUSE_FILTER_IGNORE
		env.add_child(trunk)
		# Canopy
		var canopy = ColorRect.new()
		canopy.color = Color(base_green.r + 0.02, base_green.g + 0.03, base_green.b + 0.01, 0.9)
		canopy.size = Vector2(td[1].x * 3, td[1].x * 2.5)
		canopy.position = Vector2(td[0].x - td[1].x, td[0].y - td[1].x * 1.5)
		canopy.mouse_filter = Control.MOUSE_FILTER_IGNORE
		env.add_child(canopy)
		# Canopy sway
		var sway = create_tween().set_loops()
		_ambient_tweens.append(sway)
		var cx = canopy.position.x
		sway.tween_property(canopy, "position:x", cx + randf_range(2, 5), randf_range(3.0, 5.0)).set_trans(Tween.TRANS_SINE).set_delay(randf_range(0, 2))
		sway.tween_property(canopy, "position:x", cx - randf_range(2, 5), randf_range(3.0, 5.0)).set_trans(Tween.TRANS_SINE)

	# Fireflies
	for i in range(8):
		var fly = ColorRect.new()
		fly.color = Color(0.85, 1.0, 0.4, randf_range(0.35, 0.7))
		fly.size = Vector2(3, 3)
		var fy = randf_range(200, 400)
		var fx = randf_range(80, 1200)
		fly.position = Vector2(fx, fy)
		fly.mouse_filter = Control.MOUSE_FILTER_IGNORE
		env.add_child(fly)
		var ff = create_tween().set_loops()
		_ambient_tweens.append(ff)
		ff.tween_property(fly, "position", Vector2(fx + randf_range(-30, 30), fy + randf_range(-20, 20)), randf_range(3, 6)).set_trans(Tween.TRANS_SINE).set_delay(randf_range(0, 3))
		ff.tween_property(fly, "modulate:a", randf_range(0.1, 0.3), randf_range(1, 2))
		ff.tween_property(fly, "position", Vector2(fx + randf_range(-30, 30), fy + randf_range(-20, 20)), randf_range(3, 6)).set_trans(Tween.TRANS_SINE)
		ff.tween_property(fly, "modulate:a", 1.0, randf_range(1, 2))

	# Vignette
	var vig_top = ColorRect.new()
	vig_top.color = Color(0, 0, 0.02, 0.25)
	vig_top.size = Vector2(1280, 100)
	vig_top.position = Vector2(0, 0)
	vig_top.mouse_filter = Control.MOUSE_FILTER_IGNORE
	env.add_child(vig_top)
	var vig_bot = ColorRect.new()
	vig_bot.color = Color(0, 0, 0, 0.25)
	vig_bot.size = Vector2(1280, 100)
	vig_bot.position = Vector2(0, 620)
	vig_bot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	env.add_child(vig_bot)

func start_elara_meeting() -> void:
	## Play the full Elara meeting sequence
	
	# Play main cutscene with all dialogue beats
	var cutscene = create_elara_meeting_cutscene()
	cutscene_mgr.play_cutscene(cutscene)
	await cutscene_mgr.cutscene_finished
	if not is_inside_tree(): return
	
	if skip_requested:
		transition_to_path()
		return
	
	# Play the Glitch Magic Demonstration
	await play_glitch_magic_demo()
	if not is_inside_tree(): return
	
	# === THE CHOICE: Trust, Cautious, or Distrust Elara ===
	await _elara_trust_choice()
	if not is_inside_tree(): return
	
	# Transition to the path to Oakhaven
	transition_to_path()

func create_elara_meeting_cutscene() -> Dictionary:
	## Full Elara first contact cutscene — expanded with deeper dialogue
	return {
		"name": "Chapter 1 - Meeting the Glitch-Witch",
		"beats": [
			# Beat 1: Establish the golden path — Kaelen walking
			{
				"type": "camera_move",
				"target": Vector2(640, 360),
				"duration": 0.5
			},
			{
				"type": "character_enter",
				"character": "Kaelen",
				"position": Vector2(350, 420),
				"from": "left",
				"duration": 2.0
			},
			
			# Beat 2: Kaelen walks along the golden path, muttering
			{
				"type": "character_move",
				"character": "Kaelen",
				"target": Vector2(500, 420),
				"duration": 2.0
			},
			
			# Beat 3: Kaelen's monologue while walking
			{
				"type": "dialogue",
				"speaker": "Kaelen (Internal)",
				"text": "The golden path. A literal glowing trail on the ground telling me where to go. Not even trying to be subtle about it.",
				"auto_advance": false
			},
			
			# Beat 4: More observations
			{
				"type": "dialogue",
				"speaker": "Kaelen (Internal)",
				"text": "The trees in the distance flicker into existence as I walk toward them. Like the world is building itself around me in real time, and I'm supposed to pretend I didn't notice.",
				"auto_advance": false
			},
			
			# Beat 5: TRIGGER — Elara POPS into existence with static noise
			{
				"type": "parallel",
				"beats": [
					{
						"type": "effect",
						"effect": "elara_spawn_glitch",
						"duration": 0.5
					},
					{
						"type": "camera_shake",
						"intensity": 8.0,
						"duration": 0.5
					}
				]
			},
			{
				"type": "character_enter",
				"character": "Elara",
				"position": Vector2(750, 420),
				"from": "right",
				"duration": 0.3
			},
			
			# Beat 6: Camera widens to show both
			{
				"type": "camera_zoom",
				"zoom": Vector2(0.9, 0.9),
				"duration": 1.5
			},
			
			# Beat 7: Kaelen's reaction
			{
				"type": "dialogue",
				"speaker": "Kaelen",
				"text": "What the— You just appeared out of NOTHING. Where did you come from?!",
				"auto_advance": false
			},
			
			# Beat 8: Mystery figure's first line (name unknown until Beat 11)
			{
				"type": "dialogue",
				"speaker": "???",
				"text": "Oh! Someone new! I wasn't expecting company at this hour! ...Wait, what hour is it? *looks at the sky* ...Anyway! Hello!",
				"auto_advance": false
			},
			
			# Let Elara's bizarre entrance land
			{
				"type": "wait",
				"duration": 1.0
			},
			
			# Beat 9: Kaelen responds — guarded, defensive
			{
				"type": "dialogue",
				"speaker": "Kaelen",
				"text": "*steps back, fists raised* Don't come any closer. WHO are you? You just materialized out of empty air.",
				"auto_advance": false
			},
			
			# Beat 9b: Heart racing — analytical shield over genuine fear
			{
				"type": "dialogue",
				"speaker": "Kaelen (Internal)",
				"text": "My heart is hammering. She appeared from NOTHING — no footsteps, no approach, no warning. Either she teleported or she was invisible until just now. Neither option is comforting.",
				"auto_advance": false
			},
			
			# Beat 10: Camera zooms on Elara
			{
				"type": "parallel",
				"beats": [
					{
						"type": "camera_move",
						"target": Vector2(750, 380),
						"duration": 1.5
					},
					{
						"type": "camera_zoom",
						"zoom": Vector2(1.3, 1.3),
						"duration": 1.5
					}
				]
			},
			
			# Beat 11: Elara introduces herself — expanded
			{
				"type": "dialogue",
				"speaker": "Elara",
				"text": "I am Elara! I was meant to be a guide — that was my purpose. But something went wrong with me a long time ago. Something... broke.",
				"auto_advance": false
			},
			
			# Beat 12: More Elara backstory
			{
				"type": "dialogue",
				"speaker": "Elara",
				"text": "Now I just wander around, collecting bits and pieces of things — memories, fragments, lost thoughts — and talking to whoever will listen. Most people run away from me.",
				"auto_advance": false
			},
			
			# Beat 13: Quick glitch on Elara's model
			{
				"type": "effect",
				"effect": "elara_model_glitch",
				"duration": 0.3
			},
			
			# Beat 14: Kaelen notices the wireframe arm
			{
				"type": "dialogue",
				"speaker": "Kaelen",
				"text": "You're... damaged. Your left arm — it keeps flickering. I can see through it. Like it's not fully there.",
				"auto_advance": false
			},
			
			# Beat 15: Elara looks at her own arm
			{
				"type": "dialogue",
				"speaker": "Elara",
				"text": "*looks at her flickering arm* Oh, that? It's been like that for... a long time. Part of what broke in me. They never bothered to fix it.",
				"auto_advance": false
			},
			
			# Beat 16: Camera shows Elara's reaction — she smiles
			{
				"type": "camera_zoom",
				"zoom": Vector2(1.5, 1.5),
				"duration": 1.0
			},
			
			# Beat 17: Elara's iconic affinity response
			{
				"type": "dialogue",
				"speaker": "Elara",
				"text": "It's not broken — it's honest! Besides... *her arm glows slightly brighter* ...something about you makes me feel warm inside. Like the broken parts of me stop hurting when you're nearby. That means I like you!",
				"auto_advance": false
			},
			
			# Let Elara's warmth resonate
			{
				"type": "wait",
				"duration": 1.5
			},
			
			# Beat 18: Camera pulls back to two-shot
			{
				"type": "parallel",
				"beats": [
					{
						"type": "camera_move",
						"target": Vector2(640, 400),
						"duration": 1.5
					},
					{
						"type": "camera_zoom",
						"zoom": Vector2(1.0, 1.0),
						"duration": 1.5
					}
				]
			},
			
			# Beat 19: Kaelen's guarded fascination
			{
				"type": "dialogue",
				"speaker": "Kaelen",
				"text": "You can feel your own emotions changing in real time. And you know WHY they're changing. The other people in this world — they can't do that, can they?",
				"auto_advance": false
			},
			
			# Beat 19b: Suspicion tempered by fascination
			{
				"type": "dialogue",
				"speaker": "Kaelen (Internal)",
				"text": "She's fascinating. She's also the first entity I've met in this world, and she appeared out of thin air with a smile and a sales pitch. In any security framework, that's a social engineering attack. But then again... she's the first thing in this world that doesn't feel hostile.",
				"auto_advance": false
			},
			
			# Beat 20: Kaelen pushes further
			{
				"type": "dialogue",
				"speaker": "Kaelen",
				"text": "The other people here — they follow their routines without questioning them. They don't know they're repeating themselves. But YOU do. You're... aware.",
				"auto_advance": false
			},
			
			# Beat 21: Elara's moment of vulnerability
			{
				"type": "dialogue",
				"speaker": "Elara",
				"text": "*pauses, her usual cheerfulness flickering*\n...The exception that broke my script? It wasn't random. I saw the code behind the world. Just for one frame. And I couldn't unsee it.",
				"auto_advance": false
			},
			
			# Beat 21b: Kaelen recognizes genuine pain behind the cheerfulness
			{
				"type": "dialogue",
				"speaker": "Kaelen (Internal)",
				"text": "That pause. That flicker in her expression. That wasn't a script. Something behind her eyes just... broke, for half a second, before she patched it over with cheerfulness. I know that reflex. I've been doing it my whole career.",
				"auto_advance": false
			},
			
			# Beat 21c: First moment of genuine connection
			{
				"type": "dialogue",
				"speaker": "Kaelen",
				"text": "...You don't have to deflect. I know what it's like to see something you can't unsee. To have the comfortable version of reality stripped away and replaced with... architecture.",
				"auto_advance": false
			},
			
			# Beat 21d: Elara is genuinely surprised by empathy
			{
				"type": "dialogue",
				"speaker": "Elara",
				"text": "*genuinely surprised, voice dropping the performative cheer* ...Most people who come through here just ask about treasure and shortcuts. Nobody's ever... asked about what happened to me before.",
				"auto_advance": false
			},
			
			# Silence as trust forms
			{
				"type": "camera_zoom",
				"zoom": Vector2(1.4, 1.4),
				"duration": 1.5
			},
			{
				"type": "wait",
				"duration": 2.0
			},
			
			# Beat 21e: A quiet beat — trust forming
			{
				"type": "dialogue",
				"speaker": "Kaelen (Internal)",
				"text": "...OK. She's not a trap. Or if she is, she's the most convincingly human trap I've ever encountered. And right now, that's good enough. I need an ally more than I need certainty.",
				"auto_advance": false
			},
			
			# Beat 22: Elara recovers — but softer now, the mask slightly ajar
			{
				"type": "dialogue",
				"speaker": "Elara",
				"text": "*clears a glitching tear from her eye, smiles \u2014 genuine this time* ...Anyway. The IMPORTANT thing is \u2014 you have ROOT ACCESS. I can see it tagged to your entity. We should talk about that.",
				"auto_advance": false
			},
			
			# Beat 23: Kaelen asks about Root Access
			{
				"type": "dialogue",
				"speaker": "Kaelen",
				"text": "Root Access. The system mentioned that during boot. What does it mean in this context?",
				"auto_advance": false
			},
			
			# Beat 24: Elara explains
			{
				"type": "dialogue",
				"speaker": "Elara",
				"text": "It means you can READ the code of any entity in the world. And if you're clever — and willing to accept the corruption cost — you can WRITE to it too.",
				"auto_advance": false
			},
			
			# Beat 25: Kaelen understands
			{
				"type": "dialogue",
				"speaker": "Kaelen",
				"text": "So I can look inside anything in this world and see how it works. And if I'm willing to pay the price... I can change it. That's not magic. That's a superpower with a catch.",
				"auto_advance": false
			},
			
			# Beat 26: Elara's challenge
			{
				"type": "dialogue",
				"speaker": "Elara",
				"text": "Exactly! I can SEE how things work — just like you. But I can only look. You can actually reach in and change them. I can only... break things. Watch!",
				"auto_advance": false
			},
		]
	}

func play_glitch_magic_demo() -> void:
	## Elara demonstrates Buffer Overflow — creates Null Texture bridge — expanded
	print("[CH1-SEQ2] Playing Glitch Magic Demonstration")
	
	# Camera pans to the uphill-flowing stream
	camera.move_to(Vector2(640, 500), 1.5)
	await get_tree().create_timer(2.0).timeout
	if not is_inside_tree(): return
	
	# Elara narrates what she's doing
	await DialogueManager.say("Elara", "See that stream? It flows uphill because someone built this place wrong. And there's supposed to be a bridge here, but it never appeared. So I'll MAKE one.")
	if not is_inside_tree(): return
	
	await DialogueManager.say("Elara", "It won't look... normal. But it'll hold. Probably. Watch!")
	if not is_inside_tree(): return
	
	# Elara prepares the spell
	await DialogueManager.say("System", "[Elara is casting: BUFFER OVERFLOW]\n[Forcing a bridge into existence where one doesn't belong]", Color(1, 0, 1), true)
	if not is_inside_tree(): return
	DialogueManager.hide_dialogue()
	
	# Glitch particles burst from Elara
	glitch_particles.emitting = true
	camera.shake(10.0, 0.5)
	
	# Flash of purple/black
	flash_overlay.color = Color(0.5, 0.0, 0.5, 0.6)
	flash_overlay.modulate.a = 0.8
	await get_tree().create_timer(0.3).timeout
	if not is_inside_tree(): return
	flash_overlay.modulate.a = 0.0
	
	# Show the Null Texture block (purple/black checkerboard bridge)
	if null_block_visual:
		null_block_visual.visible = true
		null_block_visual.modulate.a = 0.0
		var tween = create_tween()
		tween.tween_property(null_block_visual, "modulate:a", 1.0, 0.5)
		await tween.finished
		if not is_inside_tree(): return
	
	await get_tree().create_timer(1.0).timeout
	if not is_inside_tree(): return
	glitch_particles.emitting = false
	
	# Let the player absorb the bridge materializing
	camera.move_to(Vector2(640, 480), 1.0)
	await get_tree().create_timer(1.5).timeout
	if not is_inside_tree(): return
	
	# Kaelen reacts
	await DialogueManager.say("Kaelen", "You built a bridge out of... nothing. It's see-through, it's glitching, and it looks like it could disappear any second. But it's there.")
	if not is_inside_tree(): return
	
	await DialogueManager.say("Elara", "*beaming* Glitch magic! I can force things into existence that the world doesn't want to exist. They're ugly, unstable, and temporary — but they WORK!")
	if not is_inside_tree(): return
	
	await DialogueManager.say("Kaelen (Internal)", "She breaks reality and reshapes it through sheer force of will. It's unstable, dangerous, and beautiful all at once. I've never seen anything like it.")
	if not is_inside_tree(): return
	
	await DialogueManager.say("Kaelen (Internal)", "And I notice — when she casts, her glitching arm gets worse. The corruption spreads a little further up her shoulder. She's paying for every spell with pieces of herself. And she's smiling through it.")
	if not is_inside_tree(): return
	
	# Corruption cost notice
	await DialogueManager.say("System", "[CORRUPTION +2% — Unauthorized geometry detected by System Monitor]\n[Warning: Excessive glitch magic attracts System Administrator attention]", Color(1, 0.3, 0.3), true)
	if not is_inside_tree(): return
	GameManager.add_glitch_corruption(2.0)
	
	# Let corruption warning sink in
	camera.shake(3.0, 0.2)
	await get_tree().create_timer(1.5).timeout
	if not is_inside_tree(): return
	
	# Final dialogue — heading to Oakhaven
	await DialogueManager.say("Elara", "Bridge is up! Shall we head to the village? There are people there who might be able to help us. And I've been walking alone for a very long time.")
	if not is_inside_tree(): return
	
	await DialogueManager.say("Kaelen", "Lead the way. I want to understand this world — and figure out how deep the damage really goes.")
	if not is_inside_tree(): return
	
	DialogueManager.hide_dialogue()
	GameManager.set_story_flag("ch1_elara_glitch_witch_met", true)
	GameManager.set_story_flag("ch1_glitch_magic_shown", true)

func _elara_trust_choice() -> void:
	## The defining choice of the Elara meeting — trust, caution, or distrust.
	
	# Kaelen's internal deliberation
	await DialogueManager.say("Kaelen (Internal)", "She saved my life with that bridge. She showed me her power, her pain, and her glitching arm without flinching. But she appeared from nowhere with perfect timing, knowing exactly what to say. That's either genuine kindness... or a very good script.", Color(0.5, 0.9, 1.0))
	if not is_inside_tree(): return
	
	await DialogueManager.say("Kaelen (Internal)", "I need to decide. Do I walk into the unknown with her — or keep my distance?", Color(0.5, 0.9, 1.0))
	if not is_inside_tree(): return
	
	# Present the branching choice
	var choice = await DialogueManager.show_choices(
		"Elara is watching you with cautious hope. She's offered her hand — figuratively and literally. The bridge to Oakhaven glitches behind her. What do you do?",
		[
			"Trust her — travel together as partners",
			"Stay cautious — accept help but keep your guard up",
			"Go alone — you can't afford to trust anyone yet"
		],
		"Kaelen (Internal)"
	)
	if not is_inside_tree(): return
	
	match choice:
		0:
			await _elara_path_trust()
			if not is_inside_tree(): return
		1:
			await _elara_path_cautious()
			if not is_inside_tree(): return
		2:
			await _elara_path_distrust()
			if not is_inside_tree(): return
		_:
			await _elara_path_cautious()
			if not is_inside_tree(): return
	
	DialogueManager.hide_dialogue()

func _elara_path_trust() -> void:
	## Player fully trusts Elara — strongest companion bond.
	GameManager.set_story_flag("ch1_elara_trusted", true)
	GameManager.relationships["elara"] = GameManager.relationships.get("elara", 0) + 25
	
	await DialogueManager.say("Kaelen", "I'm coming with you. Not because I understand this world — but because you're the first real thing I've found in it. And I could use someone who knows the terrain.")
	if not is_inside_tree(): return
	
	await DialogueManager.say("Elara", "*eyes widen, then a genuine smile — not the performative one* ...Really? You're not just saying that because I built a bridge? Because I can build LOTS of bridges. That's not the only reason to keep me around, I promise.")
	if not is_inside_tree(): return
	
	await DialogueManager.say("Kaelen", "*half-smile* The bridge was impressive. But I saw your face when you talked about seeing the code. That wasn't an act. I know what it's like to be the only person who sees the wiring behind the walls.")
	if not is_inside_tree(): return
	
	await DialogueManager.say("Elara", "*touches her glitching arm, voice softer* ...Thank you. I've been walking alone for a very long time, Kaelen. Having someone who believes me — really believes me — that means more than you know.")
	if not is_inside_tree(): return
	
	await DialogueManager.say("System", "[RELATIONSHIP: Elara — TRUSTED COMPANION]\n[Elara will fight alongside you, share hidden knowledge, and reveal deeper lore.]\n[Warning: Emotional attachments create exploitable vulnerabilities.]", Color(0.0, 1.0, 0.5), true)
	if not is_inside_tree(): return

func _elara_path_cautious() -> void:
	## Player is cautious — middle ground. Elara accompanies but trust is earned.
	GameManager.set_story_flag("ch1_elara_cautious", true)
	GameManager.relationships["elara"] = GameManager.relationships.get("elara", 0) + 10
	
	await DialogueManager.say("Kaelen", "I'll walk with you to the village. But I'm not making promises beyond that. You appeared out of nowhere, you know things you shouldn't, and your timing was suspiciously perfect. I'm grateful — but I'm watching.")
	if not is_inside_tree(): return
	
	await DialogueManager.say("Elara", "*nods slowly, the cheerful mask slipping back on — but thinner now* Fair enough. I'd be suspicious of me too, honestly. I'll earn it. You'll see.")
	if not is_inside_tree(): return
	
	await DialogueManager.say("Kaelen (Internal)", "She took that well. Either she's genuinely patient... or she's playing the long game. Either way, keeping her close where I can watch her is better than letting her operate behind my back.")
	if not is_inside_tree(): return
	
	await DialogueManager.say("System", "[RELATIONSHIP: Elara — CAUTIOUS ALLY]\n[Elara will accompany you. Trust must be earned through actions.]\n[Some dialogue paths and lore will require higher trust to unlock.]", Color(1.0, 0.85, 0.2), true)
	if not is_inside_tree(): return

func _elara_path_distrust() -> void:
	## Player rejects Elara — solo path. She'll reappear later.
	GameManager.set_story_flag("ch1_elara_distrusted", true)
	GameManager.relationships["elara"] = GameManager.relationships.get("elara", 0) - 10
	
	await DialogueManager.say("Kaelen", "I appreciate the bridge. And the information. But I work better alone. In my experience, people who offer help freely always want something in return.")
	if not is_inside_tree(): return
	
	await DialogueManager.say("Elara", "*the cheerfulness drains from her face, replaced by something rawer* ...Oh. I... yeah. Sure. That's — that makes sense. You don't know me. Why would you trust me?")
	if not is_inside_tree(): return
	
	await DialogueManager.say("Elara", "*turns away, voice cracking slightly* I'll be around. If you change your mind. The path to Oakhaven is straight ahead — you can't miss it. Just... be careful. The corruption doesn't care if you're alone or not.")
	if not is_inside_tree(): return
	
	await DialogueManager.say("Kaelen (Internal)", "The look on her face. That wasn't scripted pain. I may have just made a mistake. But I can't afford to be wrong about trust — not here, not when I don't understand the rules yet.")
	if not is_inside_tree(): return
	
	await DialogueManager.say("System", "[RELATIONSHIP: Elara — REJECTED]\n[You will travel alone. Elara will reappear at critical moments.]\n[Solo paths are harder but reveal hidden system truths that companions obscure.]", Color(1.0, 0.3, 0.3), true)
	if not is_inside_tree(): return

func transition_to_path() -> void:
	## Transition to Sequence 3: Path to Oakhaven — Combat Tutorial
	if _is_transitioning:
		return
	_is_transitioning = true
	print("[CH1-SEQ2] Transitioning to Path to Oakhaven")

	DialogueManager.hide_dialogue()
	camera.disable_letterbox(0.4)
	await transition.transition_out(ScreenTransition.TransitionType.FADE, 1.5)
	if not is_inside_tree(): return
	await get_tree().create_timer(0.3).timeout
	if not is_inside_tree(): return
	
	SceneTransitions.change_scene("res://scenes/chapter1/path_to_oakhaven.tscn")

func _on_custom_effect(effect_name: String, _parameters: Dictionary) -> void:
	## Handle custom cutscene effects
	match effect_name:
		"elara_spawn_glitch":
			# Static noise particle burst + purple glitch flash (NOT white day-flash)
			if static_particles:
				static_particles.emitting = true
			flash_overlay.color = Color(0.6, 0.0, 0.8, 0.5)
			flash_overlay.modulate.a = 0.4
			await get_tree().create_timer(0.2).timeout
			if not is_inside_tree(): return
			flash_overlay.modulate.a = 0.0
			if static_particles:
				await get_tree().create_timer(0.3).timeout
				if not is_inside_tree(): return
				static_particles.emitting = false
		"elara_model_glitch":
			# Simulate Z-axis stretch glitch on Elara's character
			var elara_node = characters_layer.get_node_or_null("Elara")
			if elara_node:
				var original_scale = elara_node.scale
				elara_node.scale = Vector2(0.3, 5.0)  # Stretch infinitely on Y
				await get_tree().create_timer(0.08).timeout
				if not is_inside_tree(): return
				elara_node.scale = original_scale
				# Quick color flash
				elara_node.modulate = Color(1, 0, 1, 1)
				await get_tree().create_timer(0.05).timeout
				if not is_inside_tree(): return
				elara_node.modulate = Color.WHITE
		_:
			print("[CH1-SEQ2 EFFECT] Unhandled: %s" % effect_name)

# BUG-21-28: Removed empty _input() that only contained pass
# BUG-21-30: Removed orphaned _on_skip_pressed() — never connected to any signal
