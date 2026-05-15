extends Control

## Chapter 2: The Administrator's Game
## Sequence 4: Meeting Seraphina — Cinematic encounter with the arena champion

@onready var camera: CinematicCamera = $CinematicCamera
@onready var cutscene_mgr: CutsceneManager = $CutsceneManager
@onready var characters_layer = $CharactersLayer
@onready var transition = $ScreenTransition
@onready var flash_overlay = $EffectsLayer/FlashOverlay

var choice_made: int = -1

func _ready() -> void:
	print("[CH2-SERAPHINA] Initializing Seraphina Encounter")
	GameManager.change_state(GameManager.GameState.DIALOGUE)

	# Play dialogue music for Seraphina encounter
	if has_node("/root/MusicManager"):
		MusicManager.play_track("dialogue")

	# Generate procedural background
	BackgroundManager.create_background("ironhold_arena", self)

	cutscene_mgr.camera = camera
	cutscene_mgr.characters_container = characters_layer
	cutscene_mgr.custom_effect.connect(_on_custom_effect)

	camera.smooth_enabled = true
	camera.make_current()

	await get_tree().create_timer(0.3).timeout
	if not is_inside_tree(): return
	transition.transition_in(ScreenTransition.TransitionType.FADE, 1.0)
	await transition.transition_finished
	if not is_inside_tree(): return

	await start_seraphina_sequence()
	if not is_inside_tree(): return

func start_seraphina_sequence() -> void:
	## Full Seraphina meeting sequence

	# Part 1: Seraphina enters the arena
	await play_seraphina_entrance()
	if not is_inside_tree(): return

	# Part 2: Recognition
	await play_recognition()
	if not is_inside_tree(): return

	# Part 3: Confrontation about Root Access
	await play_confrontation()
	if not is_inside_tree(): return

	# Part 4: Player choice
	await play_player_choice()
	if not is_inside_tree(): return

	# Part 5: Seraphina's response
	await play_seraphina_response()
	if not is_inside_tree(): return

	# Part 6: Underground hint
	await play_underground_hint()
	if not is_inside_tree(): return

	# Return to city
	await get_tree().create_timer(1.0).timeout
	if not is_inside_tree(): return
	await _return_to_city()

func play_seraphina_entrance() -> void:
	## Seraphina walks into the arena post-match

	var cutscene = {
		"name": "Seraphina Entrance",
		"beats": [
			{
				"type": "camera_move",
				"target": Vector2(640, 360),
				"duration": 0.5
			},
			{
				"type": "character_enter",
				"character": "Kaelen",
				"position": Vector2(400, 420),
				"from": "left",
				"duration": 0.5
			},
			{
				"type": "character_enter",
				"character": "Seraphina",
				"position": Vector2(800, 420),
				"from": "right",
				"duration": 2.0
			},
			{
				"type": "dialogue",
				"speaker": "Vex",
				"text": "Ladies and gentlemen, our reigning champion — SERAPHINA, the Flame of Flight 707!",
				"auto_advance": true
			}
		]
	}

	cutscene_mgr.play_cutscene(cutscene)
	await cutscene_mgr.cutscene_finished
	if not is_inside_tree(): return

func play_recognition() -> void:
	## Kaelen and Seraphina recognize each other — expanded

	await DialogueManager.say("Kaelen", "Wait... I know you. You were on the plane. Flight 707. You were the—")
	if not is_inside_tree(): return

	await DialogueManager.say("Seraphina", "The stewardess. Yes. And you were the passenger in 14C who ordered three coffees and spent the whole flight staring at code on your laptop.")
	if not is_inside_tree(): return

	await DialogueManager.say("Kaelen", "You remember that?")
	if not is_inside_tree(): return

	await DialogueManager.say("Seraphina", "I remember everything about that flight. Because it was the last real thing that happened to me before... this.")
	if not is_inside_tree(): return

	await DialogueManager.say("Seraphina", "The turbulence. The flash. And then... silence. I woke up in a world made of pixels and logic gates, with nothing but the uniform on my back and a fight schedule I never signed up for.")
	if not is_inside_tree(): return

	await DialogueManager.say("Kaelen", "How long have you been here?")
	if not is_inside_tree(): return

	await DialogueManager.say("Seraphina", "*pauses* Longer than you. Much longer. Time moves differently between regions. What felt like days for you was weeks for me. I woke up in the arena, and I had two choices — fight or die.")
	if not is_inside_tree(): return

	await DialogueManager.say("Seraphina", "I chose to fight. And I got very, very good at it.")
	if not is_inside_tree(): return

	await DialogueManager.say("Seraphina", "But the worst part isn't the fighting. It's the waiting. Every night, lying in this little room above the arena, I wonder — is anyone looking for us? Does the real world even know we're gone? Or are we just... data now? Ghosts in someone else's machine?")
	if not is_inside_tree(): return

	await DialogueManager.say("Kaelen", "I've wondered the same thing. Every time I use Root Access, I feel less like a person and more like a process. A function being called.")
	if not is_inside_tree(): return

	await DialogueManager.say("Seraphina", "*studying him* You feel it too. Good. That means you haven't lost yourself completely. Not yet.")
	if not is_inside_tree(): return

	DialogueManager.hide_dialogue()

func play_confrontation() -> void:
	## Seraphina confronts Kaelen about his abilities

	await DialogueManager.say("Seraphina", "But that's not why I wanted to talk to you, Kaelen.")
	if not is_inside_tree(): return

	await DialogueManager.say("Seraphina", "I saw what you did in the arena. Or rather, I saw what you DIDN'T do. You didn't just fight those enemies — you CHANGED them. Mid-combat. Their properties shifted. Their behavior broke pattern.")
	if not is_inside_tree(): return

	await DialogueManager.say("Seraphina", "Nobody can do that. Nobody in this world has that kind of access. So either you're cheating, you're an Administrator, or you're something I haven't seen before.")
	if not is_inside_tree(): return

	await DialogueManager.say("Kaelen (Internal)", "She's perceptive. More perceptive than any NPC I've met. But then... she's not an NPC. She's a real person, trapped here like me.")
	if not is_inside_tree(): return

	await DialogueManager.say("Seraphina", "So which is it? What are you, Kaelen?")
	if not is_inside_tree(): return

	DialogueManager.hide_dialogue()

func play_player_choice() -> void:
	## Player chooses how to explain Root Access — using show_choices() API
	if not is_inside_tree(): return
	choice_made = await DialogueManager.show_choices(
		"How do you explain Root Access to Seraphina?",
		[
			"Tell the truth — explain Root Access and your past at AetherCorp",
			"Downplay it — say you don't fully understand your ability",
			"Show off — demonstrate Root Access to impress her"
		],
		"Seraphina"
	)
	if not is_inside_tree(): return

func play_seraphina_response() -> void:
	## Seraphina responds based on player choice — expanded with CH1 references
	var knight_killed = GameManager.story_flags.get("ch1_knight_killed", false)
	var knight_spared = GameManager.story_flags.get("ch1_knight_spared", false)
	var has_elara = GameManager.story_flags.get("ch1_elara_trusted", false) or GameManager.story_flags.get("ch1_elara_cautious", false)

	match choice_made:
		0:  # Tell the truth
			GameManager.relationships["seraphina"] = GameManager.relationships.get("seraphina", 0) + 5
			GameManager.set_story_flag("ch2_seraphina_truth", true)

			await DialogueManager.say("Kaelen", "It's called Root Access. I can see the code that makes up this world and modify it. Properties, values, behaviors — I can change them at the source level.")
			if not is_inside_tree(): return

			await DialogueManager.say("Kaelen", "I used to be a software developer. At AetherCorp — the company that built this world. I think that's why I have this ability. I recognize the architecture because I helped build it.")
			if not is_inside_tree(): return

			await DialogueManager.say("Seraphina", "*long silence*")
			if not is_inside_tree(): return

			await DialogueManager.say("Seraphina", "You BUILT this? The world that's keeping us prisoner — you helped CREATE it?")
			if not is_inside_tree(): return

			await DialogueManager.say("Kaelen", "Parts of it. The engine, the framework. I didn't know it would be used for this. I didn't know people would get TRAPPED in it.")
			if not is_inside_tree(): return

			await DialogueManager.say("Seraphina", "*exhales slowly* ...Thank you for being honest. That took guts. And it explains a lot.")
			if not is_inside_tree(): return

			if knight_killed:
				await DialogueManager.say("Seraphina", "I've heard things from the data streams, Kaelen. About a guardian entity you killed on the way here. 'Aldric' — that was his name?")
				if not is_inside_tree(): return
				await DialogueManager.say("Seraphina", "If you built this world and you're destroying its inhabitants... that's a god playing executioner. That scares me more than the corruption does.")
				if not is_inside_tree(): return
				await DialogueManager.say("Kaelen", "I didn't— it wasn't that simple. He begged me to end it. But... you're right. It should scare me too.")
				if not is_inside_tree(): return
				GameManager.relationships["seraphina"] = GameManager.relationships.get("seraphina", 0) - 2
			elif knight_spared:
				await DialogueManager.say("Seraphina", "I've heard something else, though. About a guardian entity near Oakhaven — one you could have destroyed but chose to spare. Data echoes carry far in this world.")
				if not is_inside_tree(): return
				await DialogueManager.say("Seraphina", "That tells me more about you than Root Access ever could. Someone with that much power who chooses mercy... that's rare.")
				if not is_inside_tree(): return
				GameManager.relationships["seraphina"] = GameManager.relationships.get("seraphina", 0) + 3

			await DialogueManager.say("Seraphina", "Most people with power in this world try to hide it. The fact that you chose to tell the truth... that matters.")
			if not is_inside_tree(): return

		1:  # Downplay
			GameManager.set_story_flag("ch2_seraphina_cautious", true)

			await DialogueManager.say("Kaelen", "I'm not entirely sure what it is. I have this... ability. I can see things in the world that others can't — data, code structures. And sometimes I can change them.")
			if not is_inside_tree(): return

			await DialogueManager.say("Kaelen", "I didn't ask for it. I just woke up with it after the crash.")
			if not is_inside_tree(): return

			await DialogueManager.say("Seraphina", "Hmm. Convenient. A power you don't understand that just happened to manifest in a world made of code.")
			if not is_inside_tree(): return

			await DialogueManager.say("Seraphina", "I don't buy the 'I don't know' angle, but I've been around long enough to know that pushing someone for answers before they're ready just makes them lie better.")
			if not is_inside_tree(): return

			await DialogueManager.say("Seraphina", "Keep your secrets for now. But know this — in the arena, I've learned to read people. And right now, your data signature is practically screaming.")
			if not is_inside_tree(): return

		2:  # Show off
			GameManager.relationships["seraphina"] = GameManager.relationships.get("seraphina", 0) - 3
			GameManager.set_story_flag("ch2_seraphina_showoff", true)

			await DialogueManager.say("Kaelen", "You want to know what I am? Watch this.")
			if not is_inside_tree(): return

			await DialogueManager.say("System", "[ROOT ACCESS ACTIVATED]\n[Demonstrating capability...]", Color(0, 1, 0.5), true)
			if not is_inside_tree(): return

			GameManager.add_glitch_corruption(1.0)

			await DialogueManager.say("Kaelen", "I can rewrite the rules. Change enemy stats. Forge credentials. I'm Root Access — I have administrator-level permissions in a world that doesn't know what to do with me.")
			if not is_inside_tree(): return

			await DialogueManager.say("Seraphina", "*steps back*")
			if not is_inside_tree(): return

			await DialogueManager.say("Seraphina", "You sound like THEM. The Administrators. Treating this world like it's a toy, like the people in it don't matter.")
			if not is_inside_tree(): return

			if knight_killed:
				await DialogueManager.say("Seraphina", "And from what I've heard, you've already used that power to kill. A guardian entity, deleted permanently. Is that what power means to you? Destruction?")
				if not is_inside_tree(): return
				GameManager.relationships["seraphina"] = GameManager.relationships.get("seraphina", 0) - 3

			await DialogueManager.say("Seraphina", "I've spent weeks fighting to survive here, to protect the people I've come to care about. And you're showing off your ability to BREAK things?")
			if not is_inside_tree(): return

			await DialogueManager.say("Seraphina", "We're done here. For now.")
			if not is_inside_tree(): return

		_:
			choice_made = 1
			GameManager.set_story_flag("ch2_seraphina_cautious", true)
			await DialogueManager.say("Seraphina", "Let's keep moving. We can revisit this once we both have clearer answers.")
			if not is_inside_tree(): return

	DialogueManager.hide_dialogue()

func play_underground_hint() -> void:
	## Seraphina hints about the underground network — expanded
	var has_elara = GameManager.story_flags.get("ch1_elara_trusted", false) or GameManager.story_flags.get("ch1_elara_cautious", false)

	await get_tree().create_timer(1.0).timeout
	if not is_inside_tree(): return

	await DialogueManager.say("Seraphina", "...One more thing.")
	if not is_inside_tree(): return

	if choice_made == 2:
		await DialogueManager.say("Seraphina", "Despite your... questionable attitude, you might be useful. There's something beneath this city.")
		if not is_inside_tree(): return
	else:
		await DialogueManager.say("Seraphina", "Since we're being honest — there's something you should know about.")
		if not is_inside_tree(): return

	await DialogueManager.say("Seraphina", "Beneath Ironhold, there's a network of old process threads. Abandoned during a system refactor. The Administration sealed them, but there are cracks.")
	if not is_inside_tree(): return

	await DialogueManager.say("Seraphina", "I've heard rumors of a Source Key Fragment down there. If you're looking for a way out of this world, that's where you need to go.")
	if not is_inside_tree(): return

	await DialogueManager.say("Seraphina", "The entrance is in the residential district. Talk to Pip — the kid knows every secret passage in Ironhold.")
	if not is_inside_tree(): return

	if not has_elara:
		await DialogueManager.say("Seraphina", "And Kaelen... I notice you're traveling alone. No companions. No backup. That's either incredibly brave or incredibly stupid.")
		if not is_inside_tree(): return
		await DialogueManager.say("Seraphina", "The underground is dangerous. If you're going down there solo, be careful. The corrupted processes don't care if you have Root Access — they'll eat you alive.")
		if not is_inside_tree(): return
		await DialogueManager.say("Kaelen", "I'll manage. I've survived this far on my own.")
		if not is_inside_tree(): return
		await DialogueManager.say("Seraphina", "*arms crossed* We'll see about that.")
		if not is_inside_tree(): return

	GameManager.set_story_flag("ch2_seraphina_met", true)
	GameManager.set_story_flag("ch2_underground_unlocked", true)

	await DialogueManager.say("Kaelen (Internal)", "An underground network. Abandoned process threads beneath the city. And another Source Key Fragment. If I can get two of seven, that's a start.")
	if not is_inside_tree(): return

	DialogueManager.hide_dialogue()

func _return_to_city() -> void:
	DialogueManager.hide_dialogue()
	await transition.transition_out(ScreenTransition.TransitionType.FADE, 1.0) if transition else await get_tree().create_timer(1.0).timeout
	if not is_inside_tree(): return
	SceneTransitions.change_scene("res://scenes/regions/ironhold_region.tscn")

func _on_custom_effect(effect_name: String, _parameters: Dictionary) -> void:
	print("[CH2-SERAPHINA EFFECT] %s" % effect_name)
