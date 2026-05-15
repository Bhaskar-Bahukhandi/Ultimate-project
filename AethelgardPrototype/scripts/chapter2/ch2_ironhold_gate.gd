extends Control

## Chapter 2: The Administrator's Game
## Sequence 1: The Iron Gate — Cinematic entry to Ironhold

@onready var camera: CinematicCamera = $CinematicCamera
@onready var cutscene_mgr: CutsceneManager = $CutsceneManager
@onready var characters_layer = $CharactersLayer
@onready var transition = $ScreenTransition
@onready var glitch_overlay = $EffectsLayer/GlitchOverlay
@onready var flash_overlay = $EffectsLayer/FlashOverlay

var cinematic_active = true

func _ready() -> void:
	print("[CH2-GATE] Initializing Ironhold Gate sequence")
	GameManager.change_state(GameManager.GameState.DIALOGUE)
	GameManager.set_story_flag("ch2_ironhold_entered", true)
	GameManager.current_chapter = 2

	# Play exploration music for gate approach
	if has_node("/root/MusicManager"):
		MusicManager.play_track("exploration")

	# Generate procedural background
	BackgroundManager.create_background("ironhold_city", self)

	cutscene_mgr.camera = camera
	cutscene_mgr.characters_container = characters_layer
	cutscene_mgr.custom_effect.connect(_on_custom_effect)

	camera.smooth_enabled = true
	camera.smooth_speed = 3.0
	camera.make_current()

	# Fade in
	await get_tree().create_timer(0.3).timeout
	if not is_inside_tree(): return
	transition.transition_in(ScreenTransition.TransitionType.FADE, 1.5)
	await transition.transition_finished
	if not is_inside_tree(): return

	await start_gate_sequence()
	if not is_inside_tree(): return

func start_gate_sequence() -> void:
	## Full Ironhold Gate entry sequence

	# Part 1: Approach the gates
	await play_approach()
	if not is_inside_tree(): return

	# Part 2: Gate guard confrontation
	await play_guard_confrontation()
	if not is_inside_tree(): return

	# Part 3: Hacking the gate
	await play_gate_hack()
	if not is_inside_tree(): return

	# Part 4: Entering Ironhold
	await play_ironhold_reveal()
	if not is_inside_tree(): return

	# Transition to city
	await get_tree().create_timer(1.0).timeout
	if not is_inside_tree(): return
	await _transition_to_city()
	if not is_inside_tree(): return

func _has_elara() -> bool:
	return GameManager.has_elara()

func _has_flag(flag_name: String) -> bool:
	return GameManager.has_flag(flag_name)

func play_approach() -> void:
	## Kaelen (and possibly Elara) approach the massive industrial gates
	var has_elara = _has_elara()
	
	var beats = [
		{
			"type": "camera_move",
			"target": Vector2(640, 360),
			"duration": 0.5
		},
	]
	
	if has_elara:
		beats.append({
			"type": "parallel",
			"beats": [
				{
					"type": "character_enter",
					"character": "Kaelen",
					"position": Vector2(400, 450),
					"from": "left",
					"duration": 2.0
				},
				{
					"type": "character_enter",
					"character": "Elara",
					"position": Vector2(330, 450),
					"from": "left",
					"duration": 2.5
				}
			]
		})
	else:
		beats.append({
			"type": "character_enter",
			"character": "Kaelen",
			"position": Vector2(400, 450),
			"from": "left",
			"duration": 2.0
		})
	
	beats.append({
		"type": "dialogue",
		"speaker": "Kaelen",
		"text": "So this is Ironhold. I can hear the gears from here — the whole city sounds like the inside of a clock.",
		"auto_advance": false
	})
	
	if has_elara:
		beats.append({
			"type": "dialogue",
			"speaker": "Elara",
			"text": "The Steam Realm. Everything here runs on clockwork and process threads — visible mechanisms that keep reality stable. Or at least, they used to.",
			"auto_advance": false
		})
	else:
		beats.append({
			"type": "dialogue",
			"speaker": "Kaelen (Internal)",
			"text": "The Shatter changed everything. The world rebuilt itself with gears and steam pipes — visible mechanisms everywhere. Clockwork and process threads. A Steam Realm. The architecture of code made literal.",
			"auto_advance": false
		})
	
	beats.append({
		"type": "dialogue",
		"speaker": "Kaelen (Internal)",
		"text": "The scale of this place... Oakhaven was a village — a tutorial zone. This is a CITY. Smokestacks, gear towers, steam vents. The draw distance alone would melt a GPU.",
		"auto_advance": false
	})
	
	if not has_elara:
		beats.append({
			"type": "dialogue",
			"speaker": "Kaelen (Internal)",
			"text": "And I'm walking into it alone. No guide. No one to explain the rules of this new region. Just me and whatever instincts Root Access gives me.",
			"auto_advance": false
		})
	
	var cutscene = {
		"name": "Gate Approach",
		"beats": beats
	}
	
	cutscene_mgr.play_cutscene(cutscene)
	await cutscene_mgr.cutscene_finished
	if not is_inside_tree(): return

func play_guard_confrontation() -> void:
	## Gate Guards demand authorization
	var has_elara = _has_elara()
	var has_knight_rep = GameManager.story_flags.get("ch1_knight_killed", false)

	await DialogueManager.say("Gate Guard", "HALT! State your business and present your Authorization Token.")
	if not is_inside_tree(): return

	await DialogueManager.say("Kaelen", "Authorization Token? We're travelers from Oakhaven—")
	if not is_inside_tree(): return

	await DialogueManager.say("Gate Guard", "No token, no entry. Ironhold is under Tier 2 lockdown by order of the Administration. All unregistered entities are to be reported and detained.")
	if not is_inside_tree(): return

	if has_knight_rep:
		await DialogueManager.say("Gate Guard", "...Wait. *checking data logs* You. Entity 'Kaelen'. We have a flag on your signature. The Sentinel patrol at Oakhaven logged an entity deletion — a bound guardian. Your doing?")
		if not is_inside_tree(): return
		await DialogueManager.say("Kaelen (Internal)", "Word travels fast in a world made of data. The knight... Aldric. His deletion is already in the system logs.")
		if not is_inside_tree(): return
		await DialogueManager.say("Gate Guard", "*to partner* Careful with this one. He's flagged for unauthorized entity termination. Keep your hand on the beacon.")
		if not is_inside_tree(): return

	if has_elara:
		await DialogueManager.say("Elara", "*whispering* Kaelen, they'll flag us in the system if we don't get through. The Administration monitors all entry logs.")
		if not is_inside_tree(): return
		await DialogueManager.say("Kaelen (Internal)", "An authorization token. It's just data — a string of validated credentials. If this world runs on code, then I can write my own credentials.")
		if not is_inside_tree(): return
		await DialogueManager.say("Elara", "*whispering urgently* Whatever you're thinking, think fast. The guard's already reaching for the alert beacon.")
		if not is_inside_tree(): return
	else:
		await DialogueManager.say("Kaelen (Internal)", "An authorization token. It's just data — a string of validated credentials. If this world runs on code, I can write my own. No Elara to guide me this time... but I don't need a guide. I need Root Access.")
		if not is_inside_tree(): return
		await DialogueManager.say("Kaelen (Internal)", "The guard's hand is drifting toward the alert beacon. I have maybe ten seconds before this gets ugly.")
		if not is_inside_tree(): return

	DialogueManager.hide_dialogue()

func play_gate_hack() -> void:
	## Kaelen uses Root Access to forge authorization
	var has_elara = _has_elara()

	await DialogueManager.say("System", "[ROOT ACCESS DETECTED]\n[Kaelen is attempting to forge an Authorization Token]\n[WARNING: This action will increase corruption by 3%]", Color(1, 0.5, 0), true)
	if not is_inside_tree(): return

	# Glitch effect
	if glitch_overlay:
		glitch_overlay.visible = true
		glitch_overlay.color = Color(0, 1, 0.5, 0.3)
		var tween = create_tween()
		tween.tween_property(glitch_overlay, "color:a", 0.0, 1.5)

	camera.shake(5.0, 0.5)

	await DialogueManager.say("Kaelen", "*concentrating* ...Accessing local credential store... duplicating schema... injecting forged token...")
	if not is_inside_tree(): return

	# Corruption increase
	GameManager.add_glitch_corruption(3.0)

	await DialogueManager.say("System", "[AUTHORIZATION TOKEN GENERATED]\n[Token ID: 0xDEAD_BEEF_7707]\n[Status: VALID (forged)]\n[Corruption: +3.0%]", Color(0, 1, 0), true)
	if not is_inside_tree(): return

	if glitch_overlay:
		glitch_overlay.visible = false

	await DialogueManager.say("Kaelen", "*presenting token* Here. Authorization Token — verified.")
	if not is_inside_tree(): return

	await DialogueManager.say("Gate Guard", "...Token checks out. Proceed. But know this — the Administration has eyes everywhere in Ironhold. Don't cause trouble.")
	if not is_inside_tree(): return

	if has_elara:
		await DialogueManager.say("Elara", "*as they walk through* That was... terrifyingly smooth. How did you learn to do that so quickly?")
		if not is_inside_tree(): return
		await DialogueManager.say("Kaelen", "I didn't learn it. I just... understood the data structure. Like reading a file format I wrote years ago.")
		if not is_inside_tree(): return
		await DialogueManager.say("Elara", "That's what worries me.")
		if not is_inside_tree(): return
	else:
		await DialogueManager.say("Kaelen (Internal)", "That was... terrifyingly smooth. I barely had to think about it. The credential schema, the validation chain — I just SAW it. Like reading code I wrote in a past life.")
		if not is_inside_tree(): return
		await DialogueManager.say("Kaelen (Internal)", "The corruption cost was 3%. Worth it. But every hack pulls me deeper into the system. How much of me will be left when the meter hits 100?")
		if not is_inside_tree(): return

	DialogueManager.hide_dialogue()

func play_ironhold_reveal() -> void:
	## First glimpse of Ironhold's industrial grandeur
	var has_elara = _has_elara()
	var warned_village = GameManager.story_flags.get("ch1_oakhaven_warned_villagers", false)

	# Camera pan to reveal the city
	camera.move_to(Vector2(640, 300), 2.0)
	await get_tree().create_timer(2.5).timeout
	if not is_inside_tree(): return

	await DialogueManager.say("Kaelen", "...*speechless for a moment*")
	if not is_inside_tree(): return

	await DialogueManager.say("Kaelen", "It's... enormous. The gears at the center of the city must be a hundred meters tall. And look — you can see the process threads. Actual physical threads of data running between the buildings like power lines.")
	if not is_inside_tree(): return

	if has_elara:
		await DialogueManager.say("Elara", "Those process threads keep the region's tick rate stable. If they break, time itself stutters — objects freeze mid-air, NPCs loop their last action, physics just... stops.")
		if not is_inside_tree(): return

		await DialogueManager.say("Kaelen (Internal)", "Process threads. Tick rate. She's describing a game engine's internal loop, but as physical infrastructure. This world doesn't just RUN on code — the code is built into the ARCHITECTURE.")
		if not is_inside_tree(): return

		await DialogueManager.say("Elara", "Ironhold has districts — Market, Arena, Clock Tower, residential areas. We should explore, talk to the locals. Someone here might know about the Source Key Fragments.")
		if not is_inside_tree(): return
	else:
		await DialogueManager.say("Kaelen (Internal)", "Process threads. Tick rate signals. I can SEE them now, thanks to Data Vision. The engine's internal loop made physical — power lines of pure code strung between buildings. This world doesn't RUN on code. The code IS the architecture.")
		if not is_inside_tree(): return

		await DialogueManager.say("Kaelen (Internal)", "I can make out districts from here. Market stalls to the west, some kind of arena to the east, and that massive clock tower in the center. I need information. Source Key Fragments. Allies. Anything.")
		if not is_inside_tree(): return

	if warned_village:
		await DialogueManager.say("Kaelen (Internal)", "Oakhaven. I warned them about the corruption. I wonder... will they make it? Will the villagers have the time to prepare? Or is the corruption already eating through the bridge we crossed?")
		if not is_inside_tree(): return

	await DialogueManager.say("System", "[NEW OBJECTIVE: Explore Ironhold]\n[WARNING: System instability detected — estimated time to critical failure: 72 HOURS]\n[Countdown initiated — Time remaining: 68:42:11]", Color(0, 1, 1), true)
	if not is_inside_tree(): return

	await DialogueManager.say("Kaelen", "Sixty-eight hours... before everything falls apart? Then we'd better move fast.")
	if not is_inside_tree(): return

	DialogueManager.hide_dialogue()

func _transition_to_city() -> void:
	## Transition to the explorable Ironhold region
	print("[CH2-GATE] Transitioning to Ironhold Region (open-world)")
	DialogueManager.hide_dialogue()

	await transition.transition_out(ScreenTransition.TransitionType.WIPE_RIGHT, 1.0)
	if not is_inside_tree(): return
	GameManager.current_region = "ironhold"
	GameManager.change_state(GameManager.GameState.EXPLORATION)
	SceneTransitions.change_scene("res://scenes/regions/ironhold_region.tscn")

func _on_custom_effect(effect_name: String, _parameters: Dictionary) -> void:
	print("[CH2-GATE EFFECT] %s" % effect_name)

# BUG-21-28: Removed empty _input() that only contained pass
