extends Control

## Chapter 2: The Administrator's Game
## Sequence 8: Seraphina's Choice — Major branching decision after the Administrator Proxy fight

var choice_made: int = -1
var _flicker_tweens: Array = []

func _exit_tree() -> void:
	for tw in _flicker_tweens:
		if tw and tw.is_valid():
			tw.kill()
	_flicker_tweens.clear()

func _ready() -> void:
	print("[CH2-SERAPHINA-CHOICE] Initializing Seraphina's Choice")
	GameManager.change_state(GameManager.GameState.DIALOGUE)

	# Play dialogue music for Seraphina's choice
	if has_node("/root/MusicManager"):
		MusicManager.play_track("dialogue")

	_build_background()

	await get_tree().create_timer(0.5).timeout
	if not is_inside_tree(): return
	await _start_sequence()
	if not is_inside_tree(): return

# --------------------------------------------------------------------------- #
#  Background — damaged city square at night, aftermath of proxy fight
# --------------------------------------------------------------------------- #

func _build_background() -> void:
	## Build the post-battle night scene with damaged city square
	# Dark night sky
	var sky = ColorRect.new()
	sky.color = Color(0.03, 0.02, 0.06)
	sky.size = Vector2(1280, 400)
	sky.position = Vector2(0, 0)
	sky.z_index = -10
	add_child(sky)

	# Orange-red glow on the horizon (aftermath of the proxy fight)
	var glow = ColorRect.new()
	glow.color = Color(0.55, 0.15, 0.05, 0.35)
	glow.size = Vector2(1280, 180)
	glow.position = Vector2(0, 220)
	glow.z_index = -9
	add_child(glow)

	var glow_pulse = create_tween().set_loops()
	glow_pulse.tween_property(glow, "modulate:a", 0.6, 2.5).set_trans(Tween.TRANS_SINE)
	glow_pulse.tween_property(glow, "modulate:a", 1.0, 2.5).set_trans(Tween.TRANS_SINE)
	_flicker_tweens.append(glow_pulse)

	# Ground — cracked city square
	var ground = ColorRect.new()
	ground.color = Color(0.12, 0.1, 0.08)
	ground.size = Vector2(1280, 320)
	ground.position = Vector2(0, 400)
	ground.z_index = -8
	add_child(ground)

	# Damage cracks / darker patches across the ground
	var crack_data = [
		Vector2(150, 430), Vector2(120, 18),
		Vector2(400, 460), Vector2(200, 12),
		Vector2(700, 420), Vector2(160, 15),
		Vector2(950, 470), Vector2(180, 10),
		Vector2(300, 510), Vector2(140, 14),
		Vector2(820, 530), Vector2(110, 12),
	]
	for i in range(0, crack_data.size(), 2):
		var crack = ColorRect.new()
		crack.color = Color(0.04, 0.03, 0.02, 0.8)
		crack.position = crack_data[i]
		crack.size = crack_data[i + 1]
		crack.rotation_degrees = randf_range(-12.0, 12.0)
		crack.z_index = -7
		add_child(crack)

	# Smoke / haze overlay
	var haze = ColorRect.new()
	haze.color = Color(0.2, 0.12, 0.08, 0.12)
	haze.size = Vector2(1280, 720)
	haze.position = Vector2(0, 0)
	haze.z_index = -1
	add_child(haze)

	var haze_tween = create_tween().set_loops()
	haze_tween.tween_property(haze, "modulate:a", 0.5, 4.0).set_trans(Tween.TRANS_SINE)
	haze_tween.tween_property(haze, "modulate:a", 1.0, 4.0).set_trans(Tween.TRANS_SINE)
	_flicker_tweens.append(haze_tween)

	# Flickering lights — damaged street lamps
	_create_flickering_light(Vector2(200, 350), Color(1, 0.7, 0.3, 0.5))
	_create_flickering_light(Vector2(580, 370), Color(1, 0.5, 0.2, 0.4))
	_create_flickering_light(Vector2(1020, 355), Color(1, 0.65, 0.25, 0.45))

	# Debris rectangles scattered around
	var debris_positions = [
		Vector2(100, 480), Vector2(340, 500), Vector2(560, 490),
		Vector2(760, 510), Vector2(1050, 485), Vector2(1180, 505),
	]
	for pos in debris_positions:
		var debris = ColorRect.new()
		var dw = randf_range(15.0, 40.0)
		var dh = randf_range(8.0, 20.0)
		debris.size = Vector2(dw, dh)
		debris.color = Color(0.18, 0.14, 0.1, 0.7)
		debris.position = pos
		debris.rotation_degrees = randf_range(-25.0, 25.0)
		debris.z_index = -6
		add_child(debris)

func _create_flickering_light(pos: Vector2, col: Color) -> void:
	## Create a small flickering light at the given position
	var light = ColorRect.new()
	light.color = col
	light.size = Vector2(14, 22)
	light.position = pos
	light.z_index = -2
	add_child(light)

	var flicker = create_tween().set_loops()
	var _base_alpha = col.a
	flicker.tween_property(light, "modulate:a", randf_range(0.15, 0.4), randf_range(0.08, 0.2))
	flicker.tween_property(light, "modulate:a", 1.0, randf_range(0.05, 0.15))
	flicker.tween_property(light, "modulate:a", randf_range(0.3, 0.7), randf_range(0.1, 0.3))
	flicker.tween_property(light, "modulate:a", 1.0, randf_range(0.1, 0.25))
	_flicker_tweens.append(flicker)

# --------------------------------------------------------------------------- #
#  Main dialogue sequence
# --------------------------------------------------------------------------- #

func _has_elara() -> bool:
	return GameManager.has_elara()

func _has_flag(flag_name: String) -> bool:
	return GameManager.has_flag(flag_name)

func _start_sequence() -> void:
	## Full confrontation dialogue after the Administrator Proxy fight — expanded
	var has_elara = _has_elara()
	var knight_killed = GameManager.story_flags.get("ch1_knight_killed", false)
	var absorbed_wraith = GameManager.story_flags.get("ch2_data_wraith_absorbed", false)

	await DialogueManager.say("Seraphina", "*stepping through the smoke and debris* ...That's what you've been hiding.")
	if not is_inside_tree(): return

	await DialogueManager.say("Kaelen", "Seraphina—")
	if not is_inside_tree(): return

	await DialogueManager.say("Seraphina", "I watched you fight that thing. I watched you rewrite reality itself. You didn't just defeat it — you hacked the world's own security system.")
	if not is_inside_tree(): return

	await DialogueManager.say("Seraphina", "When I first arrived in this world, I thought it was a nightmare. A glitch. Something that would fix itself. But it's been months, Kaelen. Months of surviving, fighting, adapting.")
	if not is_inside_tree(): return

	await DialogueManager.say("Seraphina", "And now you show up with the power to literally edit this world's code. Do you understand what that means? Do you understand what people would do for that kind of power?")
	if not is_inside_tree(): return

	await DialogueManager.say("Kaelen", "I didn't ask for this ability, Seraphina. It comes with a cost — every time I use Root Access, the corruption grows. The world fights back.")
	if not is_inside_tree(): return

	await DialogueManager.say("Seraphina", "I know. I can see it. The glitching around your hands, the way reality warps when you concentrate. You're becoming part of the corruption.")
	if not is_inside_tree(): return

	if absorbed_wraith:
		await DialogueManager.say("Seraphina", "And the Data Wraith's core... I heard what you did down there. You ABSORBED it. Pulled an entire corrupted process into yourself. Your data signature is practically screaming with stolen power.")
		if not is_inside_tree(): return
		await DialogueManager.say("Kaelen", "I did what I had to do to survive—")
		if not is_inside_tree(): return
		await DialogueManager.say("Seraphina", "Did you? Or did you do it because you COULD?")
		if not is_inside_tree(): return

	if knight_killed and absorbed_wraith:
		await DialogueManager.say("Seraphina", "First the guardian at Oakhaven. Then the Data Wraith. You're not just using power — you're accumulating it. Consuming everything in your path. At what point do YOU become the thing we should all be afraid of?")
		if not is_inside_tree(): return

	if has_elara:
		await DialogueManager.say("Elara", "Seraphina, please. Kaelen is trying to find the Source Key Fragments — seven pieces of the world's master key. If we can assemble them, we might be able to fix everything. Or find a way home.")
		if not is_inside_tree(): return
	else:
		await DialogueManager.say("Kaelen", "I'm looking for the Source Key Fragments. Seven pieces of a master key. If I can assemble them, there might be a way to fix this world — or find a way home for all of us.")
		if not is_inside_tree(): return

	await DialogueManager.say("Seraphina", "Home... *voice breaking slightly* I'd almost forgotten what that word meant.")
	if not is_inside_tree(): return

	await DialogueManager.say("Seraphina", "*composing herself* Fine. Then here's the question, Kaelen. What happens now? Because I'm not going to stand on the sidelines while the world falls apart around us.")
	if not is_inside_tree(): return

	DialogueManager.hide_dialogue()
	await get_tree().create_timer(0.4).timeout
	if not is_inside_tree(): return

	await _show_choice()
	if not is_inside_tree(): return

# --------------------------------------------------------------------------- #
#  Player choice — three-way branch
# --------------------------------------------------------------------------- #

func _show_choice() -> void:
	## Present the player with three options using show_choices() API
	if not is_inside_tree(): return
	choice_made = await DialogueManager.show_choices(
		"What do you say to Seraphina?",
		[
			"\"Join us. We're stronger together.\"",
			"\"This is my fight. You should stay in Ironhold where it's safe.\"",
			"\"I don't trust you enough. How do I know you're not compromised?\""
		],
		"Seraphina"
	)
	if not is_inside_tree(): return

	# Branch based on selection
	match choice_made:
		0:
			await _choice_recruit()
			if not is_inside_tree(): return
		1:
			await _choice_stay()
			if not is_inside_tree(): return
		2:
			await _choice_reject()
			if not is_inside_tree(): return
		_:
			await _choice_stay()
			if not is_inside_tree(): return

	# Wrap-up
	await _sequence_complete()
	if not is_inside_tree(): return

# --------------------------------------------------------------------------- #
#  Choice branches
# --------------------------------------------------------------------------- #

func _choice_recruit() -> void:
	## Option 1 — Recruit Seraphina to the party — expanded
	var has_elara = _has_elara()
	GameManager.set_story_flag("ch2_seraphina_recruited", true)
	GameManager.relationships["seraphina"] = GameManager.relationships.get("seraphina", 0) + 10
	if has_node("/root/ChoiceConsequences"):
		ChoiceConsequences.apply_choice_buff("ch2_seraphina_recruited")

	await DialogueManager.say("Seraphina", "*long pause* ...You know what? You're right. I've been surviving alone for too long. If there's even a chance we can fix this world — or get home — I want in.")
	if not is_inside_tree(): return

	await DialogueManager.say("Kaelen", "Welcome to the team, Seraphina.")
	if not is_inside_tree(): return

	await DialogueManager.say("Seraphina", "Don't make me regret this, Systems Architect. And for the record — if your powers ever threaten this world more than they help it, I WILL stop you. That's not a threat. It's a promise.")
	if not is_inside_tree(): return

	if has_elara:
		await DialogueManager.say("Elara", "*smiling* It's good to have another fighter with us. The road ahead won't be easy.")
		if not is_inside_tree(): return
		await DialogueManager.say("Seraphina", "Easy? I spent three months as an arena champion. I don't DO easy.")
		if not is_inside_tree(): return
		await DialogueManager.say("Seraphina", "*glancing between Kaelen and Elara* So. A glitch mage, a systems architect, and a flight attendant turned arena champion. We're quite the party.")
		if not is_inside_tree(): return
		await DialogueManager.say("Elara", "*laughing softly* When you put it that way... we sound like the worst rescue team in any world's history.")
		if not is_inside_tree(): return
	else:
		await DialogueManager.say("Seraphina", "I notice you're traveling alone. No companions. That changes now. You'll need someone watching your back who isn't a corrupted process.")
		if not is_inside_tree(): return
		await DialogueManager.say("Kaelen", "I... had the option to travel with someone. I chose not to. I'm starting to wonder if that was a mistake.")
		if not is_inside_tree(): return
		await DialogueManager.say("Seraphina", "*raising an eyebrow* Well, whatever you decided, you've got me now. And I don't abandon my crew. Flight attendant oath. ...Okay, that's not a real oath, but you get the idea.")
		if not is_inside_tree(): return

	await _mark_seraphina_route("recruited")
	if not is_inside_tree(): return
	DialogueManager.hide_dialogue()

func _choice_stay() -> void:
	## Option 2 — Ask Seraphina to stay and protect Ironhold — expanded
	var has_elara = _has_elara()
	GameManager.set_story_flag("ch2_seraphina_stayed", true)
	GameManager.relationships["seraphina"] = GameManager.relationships.get("seraphina", 0) + 2
	if has_node("/root/ChoiceConsequences"):
		ChoiceConsequences.apply_choice_buff("ch2_seraphina_stayed")

	await DialogueManager.say("Seraphina", "*scoffs* Safe? You just fought an Administrator in the middle of the city. Nowhere is safe anymore.")
	if not is_inside_tree(): return

	await DialogueManager.say("Seraphina", "But... I understand. You don't want more people in the crossfire. I respect that.")
	if not is_inside_tree(): return

	await DialogueManager.say("Seraphina", "I'll stay in Ironhold and protect the people here. Someone has to. But Kaelen — if you need me, I'll come running. You have my word.")
	if not is_inside_tree(): return

	await DialogueManager.say("Kaelen", "Thank you, Seraphina. Watch over Ironhold for us.")
	if not is_inside_tree(): return

	await DialogueManager.say("Seraphina", "I will. And Kaelen? Don't die out there. That's an order from your former flight stewardess.")
	if not is_inside_tree(): return

	if has_elara:
		await DialogueManager.say("Elara", "*nodding* She'll keep the city standing. And we'll keep moving forward.")
		if not is_inside_tree(): return
	else:
		await DialogueManager.say("Kaelen (Internal)", "At least someone will be watching over this place. And she said she'd come if I called. That's... something. More than I deserve, after the bridges I've burned.")
		if not is_inside_tree(): return

	await _mark_seraphina_route("stayed")
	if not is_inside_tree(): return
	DialogueManager.hide_dialogue()

func _choice_reject() -> void:
	## Option 3 — Reject Seraphina outright — expanded
	var has_elara = _has_elara()
	GameManager.set_story_flag("ch2_seraphina_rejected", true)
	GameManager.relationships["seraphina"] = GameManager.relationships.get("seraphina", 0) - 8
	if has_node("/root/ChoiceConsequences"):
		ChoiceConsequences.apply_choice_buff("ch2_seraphina_rejected")

	await DialogueManager.say("Seraphina", "*stunned silence, then cold anger* ...Compromised? You think I'm working for them?")
	if not is_inside_tree(): return

	await DialogueManager.say("Seraphina", "I have been SURVIVING in this hellscape for months while you've had your fancy Root Access powers for what, a few days? And YOU don't trust ME?")
	if not is_inside_tree(): return

	await DialogueManager.say("Kaelen", "I just—")
	if not is_inside_tree(): return

	await DialogueManager.say("Seraphina", "*cutting him off* No. You've made yourself clear. Fine. I'll survive on my own, just like I always have.")
	if not is_inside_tree(): return

	await DialogueManager.say("Seraphina", "*turning away* But mark my words, Kaelen. When your corruption catches up to you — and it will — don't come looking for me.")
	if not is_inside_tree(): return

	if has_elara:
		await DialogueManager.say("Elara", "*quietly to Kaelen* ...That was harsh. I hope you know what you're doing.")
		if not is_inside_tree(): return
		await DialogueManager.say("Elara", "She's the only other real person we've found in this world. Pushing her away... we might not get another chance.")
		if not is_inside_tree(): return
	else:
		await DialogueManager.say("Kaelen (Internal)", "First Elara. Now Seraphina. I'm pushing away every ally this world offers me. Am I being cautious... or am I afraid of letting people close because I know this world might take them away?")
		if not is_inside_tree(): return
		await DialogueManager.say("Kaelen (Internal)", "Two real people. Two outstretched hands. Both rejected. If I keep this up, I'll find the Source Keys alone — or I'll die alone. Maybe both.")
		if not is_inside_tree(): return

	await _mark_seraphina_route("rejected")
	if not is_inside_tree(): return
	DialogueManager.hide_dialogue()

# --------------------------------------------------------------------------- #
#  Sequence wrap-up and transition
# --------------------------------------------------------------------------- #

func _mark_seraphina_route(route: String) -> void:
	match route:
		"recruited":
			GameManager.set_story_flag("ch2_seraphina_bond_marker", true)
			await DialogueManager.say("System", "[ROUTE MARKER]\nSeraphina will be remembered as a traveling witness in later chapters.", Color(0.3, 0.9, 1.0), true)
		"stayed":
			GameManager.set_story_flag("ch2_seraphina_ironhold_marker", true)
			await DialogueManager.say("System", "[ROUTE MARKER]\nSeraphina's protection of Ironhold is now recorded for later faction reactions.", Color(0.3, 0.9, 1.0), true)
		"rejected":
			GameManager.set_story_flag("ch2_seraphina_rift_marker", true)
			await DialogueManager.say("System", "[ROUTE MARKER]\nSeraphina's rejection is now recorded. Late-game witnesses may question Kaelen's trust.", Color(1.0, 0.75, 0.25), true)

	if has_node("/root/LoreJournal"):
		LoreJournal.discover("ironhold_seraphina_route_marker")

func _sequence_complete() -> void:
	## Show completion message and transition to chapter ending
	await get_tree().create_timer(1.0).timeout
	if not is_inside_tree(): return

	await DialogueManager.say("System", "[CHAPTER 2 SEQUENCE 8 COMPLETE]\n[Relationship updated: Seraphina]", Color(0, 1, 1), true)
	if not is_inside_tree(): return

	DialogueManager.hide_dialogue()

	# Fade to black before transitioning
	var fade = ColorRect.new()
	fade.color = Color(0, 0, 0, 0)
	fade.size = get_viewport_rect().size
	fade.z_index = 100
	add_child(fade)
	var tween = create_tween()
	tween.tween_property(fade, "color:a", 1.0, 1.5)
	await tween.finished
	if not is_inside_tree(): return
	SceneTransitions.change_scene("res://scenes/chapter2/ch2_ending.tscn")
	# NOTE: ch2_ending.tscn is the correct filename (it DOES have the ch2_ prefix)
