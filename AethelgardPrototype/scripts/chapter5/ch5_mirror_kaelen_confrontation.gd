extends Control

## Chapter 5: Mirror Kaelen confrontation.
## Deepens the Mirror Kaelen scene after the Reflection Trial.

const END_SCENE := "res://scenes/chapter5/ch5_ending.tscn"

var fade_rect: ColorRect

func _ready() -> void:
	print("[CH5-MIRROR] Initializing Mirror Kaelen confrontation")
	GameManager.change_state(GameManager.GameState.DIALOGUE)
	GameManager.current_chapter = 5
	GameManager.current_region = "mirror_city"
	GameManager.set_story_flag("ch5_mirror_kaelen_confronted", true)
	_build_visuals()
	GameManager.save_game(GameManager.AUTOSAVE_SLOT)

	fade_rect.modulate.a = 1.0
	var tw := create_tween()
	tw.tween_property(fade_rect, "modulate:a", 0.0, 0.7)
	await tw.finished
	if not is_inside_tree(): return

	await _play_confrontation()
	if not is_inside_tree(): return
	await _fade_to_black(0.8)
	if not is_inside_tree(): return
	SceneTransitions.change_scene(END_SCENE)

func _build_visuals() -> void:
	var bg := ColorRect.new()
	bg.name = "MirrorKaelenBackground"
	bg.color = Color(0.015, 0.020, 0.035)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)

	for i in range(8):
		var crack := ColorRect.new()
		crack.name = "IdentityCrack%d" % i
		crack.color = Color(0.75, 0.95, 1.0, 0.13)
		crack.position = Vector2(130 + i * 140, 120 + (i % 4) * 86)
		crack.size = Vector2(120, 8)
		crack.rotation = -0.55 + float(i % 5) * 0.25
		add_child(crack)

	var title := Label.new()
	title.text = "MIRROR KAELEN"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 28)
	title.add_theme_color_override("font_color", Color(0.90, 0.96, 1.0))
	title.set_anchors_preset(Control.PRESET_TOP_WIDE)
	title.offset_top = 30
	title.offset_bottom = 84
	add_child(title)

	var hint := Label.new()
	hint.text = "The reflection stops accusing and starts asking what Kaelen will do with the truth."
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint.add_theme_font_size_override("font_size", 14)
	hint.add_theme_color_override("font_color", Color(0.84, 0.88, 0.96))
	hint.set_anchors_preset(Control.PRESET_TOP_WIDE)
	hint.offset_left = 150
	hint.offset_right = -150
	hint.offset_top = 82
	hint.offset_bottom = 136
	add_child(hint)

	fade_rect = ColorRect.new()
	fade_rect.name = "Fade"
	fade_rect.color = Color.BLACK
	fade_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	fade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fade_rect.z_index = 50
	add_child(fade_rect)

func _play_confrontation() -> void:
	if has_node("/root/MusicManager"):
		MusicManager.play_track("boss_fight")
	if has_node("/root/GlitchOverlay"):
		GlitchOverlay.flash_glitch(0.55)

	await DialogueManager.say("Narrator", "The trial chamber empties until only one reflection remains. It has Kaelen's face, Kaelen's posture, and none of Kaelen's exhaustion.")
	await DialogueManager.say("Mirror Kaelen", "You passed the easy part. You admitted you are dangerous. Now comes the harder question.")
	await DialogueManager.say("Kaelen", "What do I do with that?")
	await DialogueManager.say("Mirror Kaelen", "No. Who gets to stop you when you are sure you are right?")

	if GameManager.has_flag("ch5_identity_refused_obedience"):
		await DialogueManager.say("Mirror Kaelen", "You rejected obedience. Good. But defiance can become vanity if nobody can correct it.")
	elif GameManager.has_flag("ch5_identity_refused_perfect_rescue"):
		await DialogueManager.say("Mirror Kaelen", "You rejected the perfect rescue. Good. But urgency can become cruelty if nobody can slow it.")
	elif GameManager.has_flag("ch5_identity_refused_abandonment"):
		await DialogueManager.say("Mirror Kaelen", "You rejected abandonment. Good. But commitment can become possession if nobody can name the difference.")
	else:
		await DialogueManager.say("Mirror Kaelen", "You reached this place without naming the self you fear most. That is an answer too.")

	await DialogueManager.say("Kaelen", "Then I need witnesses. Not followers. Not worshippers. People who can tell me no.")

	if GameManager.has_elara():
		await DialogueManager.say("Elara", "Finally. For the record, I have been ready to tell you no since the crater.")
	if GameManager.has_flag("ch2_seraphina_recruited"):
		await DialogueManager.say("Seraphina", "A commander who asks to be challenged may yet deserve command.")
	if GameManager.has_flag("ch3_lyra_recruited"):
		await DialogueManager.say("Lyra", "I can do no. I am spectacular at no.")

	await _mirror_duel_trial()
	if not is_inside_tree(): return

	await DialogueManager.say("Mirror Kaelen", "Then take the only useful gift a reflection can give.")
	await DialogueManager.say("Mirror Kaelen", "Fragment Six is not a prize. It is a choir. Failed admin intelligences, abandoned by SOVEREIGN, repeating prayers made of broken permissions.")
	await DialogueManager.say("System", "// FRAGMENT #6 TRAIL REFINED: CATHEDRAL_SERVER / CHOIR_OF_BROKEN_GODS")
	var first_route_reveal := not GameManager.has_flag("ch6_path_revealed")
	GameManager.set_story_flag("ch5_fragment_6_trail_found", true)
	GameManager.set_story_flag("ch6_path_revealed", true)
	if first_route_reveal:
		GameManager.add_xp(180)
	GameManager.save_game(GameManager.AUTOSAVE_SLOT)

	await DialogueManager.say("Mirror Kaelen", "Go listen to the gods your code left behind.")
	await DialogueManager.say("Kaelen", "And if they ask me to kneel?")
	await DialogueManager.say("Mirror Kaelen", "Then remember what obedience sounded like in the plaza.")

func _mirror_duel_trial() -> void:
	if GameManager.has_flag("ch5_mirror_duel_cleared"):
		return
	await DialogueManager.say("System", "// MIRROR DUEL: three reflections attack with Kaelen's habits. Win by answering the pattern, not by mashing.")
	var score := 0
	var first = await DialogueManager.show_choices(
		"Mirror Kaelen opens with a reckless rush, copying early button-mash aggression.",
		[
			"Backstep, wait for recovery, then punish.",
			"Trade hits until the mirror breaks.",
			"Heal while the rush is active."
		]
	)
	if first == 0:
		score += 1
	var second = await DialogueManager.show_choices(
		"The reflection raises a perfect rescue barrier that punishes impatience.",
		[
			"Keep attacking the barrier.",
			"Stop, let the barrier expire, then strike the exposed core.",
			"Ask SOVEREIGN to disable the reflection."
		]
	)
	if second == 1:
		score += 1
	var third = await DialogueManager.show_choices(
		"The final reflection abandons the arena, leaving only a delayed counter-image.",
		[
			"Chase the empty image.",
			"Stand still inside the warning flash.",
			"Dash through the delayed slash and counter from behind."
		]
	)
	if third == 2:
		score += 1
	if not is_inside_tree(): return

	GameManager.set_story_flag("ch5_mirror_duel_cleared", true)
	_sync_crafting_materials()
	if score >= 2:
		GameManager.add_xp(180)
		GameManager.add_gold(70)
		if has_node("/root/Inventory"):
			Inventory.add_item("memory_shard", 1)
		await DialogueManager.say("System", "// MIRROR DUEL CLEARED. Memory Shard x1, +180 XP, +70 Gold.")
	else:
		GameManager.add_xp(90)
		GameManager.add_glitch_corruption(1.0)
		if has_node("/root/Inventory"):
			Inventory.add_item("glitch_herb", 1)
		await DialogueManager.say("System", "// MIRROR DUEL SURVIVED. Glitch Herb x1, +90 XP, +1 corruption.")
	GameManager.save_game(GameManager.AUTOSAVE_SLOT)

func _sync_crafting_materials() -> void:
	if has_node("/root/CraftingSystem"):
		CraftingSystem.get_recipes()

func _fade_to_black(duration: float) -> void:
	fade_rect.z_index = 100
	var tw := create_tween()
	tw.tween_property(fade_rect, "modulate:a", 1.0, duration)
	await tw.finished
