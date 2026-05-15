extends Control

## Chapter 5: Reflection Trial.
## Mirror Kaelen uses past choices as evidence. Fragment 6 is located, not collected.

const END_SCENE := "res://scenes/chapter5/ch5_mirror_kaelen_confrontation.tscn"

var fade_rect: ColorRect
var trial_result: String = ""

func _ready() -> void:
	print("[CH5-TRIAL] Initializing Reflection Trial")
	GameManager.change_state(GameManager.GameState.DIALOGUE)
	GameManager.current_chapter = 5
	GameManager.current_region = "mirror_city"
	GameManager.set_story_flag("ch5_reflection_trial_started", true)
	_build_visuals()
	GameManager.save_game(GameManager.AUTOSAVE_SLOT)

	fade_rect.modulate.a = 1.0
	var tw := create_tween()
	tw.tween_property(fade_rect, "modulate:a", 0.0, 0.7)
	await tw.finished
	if not is_inside_tree(): return

	await _play_trial()
	if not is_inside_tree(): return
	await _fade_to_black(0.8)
	if not is_inside_tree(): return
	SceneTransitions.change_scene(END_SCENE)

func _build_visuals() -> void:
	var bg := ColorRect.new()
	bg.name = "ReflectionTrialBackground"
	bg.color = Color(0.018, 0.024, 0.038)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)

	var floor := ColorRect.new()
	floor.name = "ReflectiveFloor"
	floor.color = Color(0.08, 0.11, 0.16, 0.92)
	floor.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	floor.offset_top = -210
	floor.offset_bottom = 0
	floor.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(floor)

	for i in range(6):
		var witness := ColorRect.new()
		witness.name = "ChoiceWitness%d" % i
		witness.color = Color(0.65, 0.95, 1.0, 0.11)
		witness.size = Vector2(95, 240)
		witness.position = Vector2(105 + i * 205, 150 + (i % 2) * 32)
		add_child(witness)

	var title := Label.new()
	title.text = "REFLECTION TRIAL"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 26)
	title.add_theme_color_override("font_color", Color(0.82, 0.94, 1.0))
	title.set_anchors_preset(Control.PRESET_TOP_WIDE)
	title.offset_top = 28
	title.offset_bottom = 78
	add_child(title)

	var hint := Label.new()
	hint.text = "Mirror Kaelen asks whether your mercy, urgency, or compromise is only another form of control."
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint.add_theme_font_size_override("font_size", 14)
	hint.add_theme_color_override("font_color", Color(0.82, 0.85, 0.94))
	hint.set_anchors_preset(Control.PRESET_TOP_WIDE)
	hint.offset_left = 140
	hint.offset_right = -140
	hint.offset_top = 76
	hint.offset_bottom = 130
	add_child(hint)

	fade_rect = ColorRect.new()
	fade_rect.name = "Fade"
	fade_rect.color = Color.BLACK
	fade_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	fade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fade_rect.z_index = 50
	add_child(fade_rect)

func _play_trial() -> void:
	if has_node("/root/MusicManager"):
		MusicManager.play_track("tension")
	if has_node("/root/GlitchOverlay"):
		GlitchOverlay.flash_glitch(0.35)

	GameManager.set_story_flag("ch5_mirror_kaelen_met", true)
	await DialogueManager.say("Narrator", "At the center of the city, the mirrors stop reflecting buildings. They reflect a courtroom, a battlefield, a village gate, an archive, and a plane falling through impossible blue.")
	await DialogueManager.say("Mirror Kaelen", "Welcome back, me.")
	await DialogueManager.say("Kaelen", "You are not me.")
	await DialogueManager.say("Mirror Kaelen", "Incorrect. I am every clean version of you that never had to live with the aftermath.")

	await _chapter4_consequence_dialogue()
	if not is_inside_tree(): return

	await DialogueManager.say("Mirror Kaelen", "You keep saying SOVEREIGN removes choice. But you also choose for people. Mercy. Release. Compromise. Different masks. Same hand on the lever.")
	await DialogueManager.say("Kaelen", "The difference is that I can be challenged.")
	await DialogueManager.say("Mirror Kaelen", "Then answer without hiding behind the player.")

	var first_clear := not GameManager.has_flag("ch5_choice_echo_resolved")
	var choice = await DialogueManager.show_choices(
		"What truth does Kaelen accept about himself?",
		[
			"I cannot undo control by becoming another controller.",
			"My guilt is real, but it does not get to make every decision.",
			"The branches I rejected still deserve witnesses."
		]
	)
	if not is_inside_tree(): return
	if choice == null or choice < 0 or choice > 2:
		choice = 0

	match choice:
		0:
			GameManager.set_story_flag("ch5_choice_echo_resolved", true)
			GameManager.set_story_flag("ch5_echo_control_rejected", true)
			trial_result = "control_rejected"
			await DialogueManager.say("Kaelen", "If I decide everything alone, I become a kinder SOVEREIGN. That is still SOVEREIGN.")
			await DialogueManager.say("Mirror Kaelen", "A useful fear. Keep it sharp.")
		1:
			GameManager.set_story_flag("ch5_choice_echo_resolved", true)
			GameManager.set_story_flag("ch5_echo_guilt_named", true)
			trial_result = "guilt_named"
			await DialogueManager.say("Kaelen", "My guilt is data. It tells me where the bug lives. It does not get root access.")
			await DialogueManager.say("Mirror Kaelen", "You are learning to stop worshipping your wounds.")
		2:
			GameManager.set_story_flag("ch5_choice_echo_resolved", true)
			GameManager.set_story_flag("ch5_echo_witnesses_promised", true)
			trial_result = "witnesses_promised"
			await DialogueManager.say("Kaelen", "Every branch I cut still happened to someone. I cannot restore them all today. But I can stop pretending they were nothing.")
			await DialogueManager.say("Mirror Kaelen", "Then the city will remember with you.")

	if has_node("/root/SFXManager"):
		SFXManager.play("puzzle_solve")
	if has_node("/root/GlitchOverlay"):
		GlitchOverlay.flash_glitch(0.7)

	GameManager.set_story_flag("ch5_fragment_6_trail_found", true)
	if first_clear:
		GameManager.add_xp(450)
		GameManager.add_gold(180)
	GameManager.save_game(GameManager.AUTOSAVE_SLOT)

	await DialogueManager.say("System", "// MIRROR TRIAL RESOLVED")
	if first_clear:
		await DialogueManager.say("System", "// Fragment #6 location trace acquired. +450 XP, +180 Gold. Source Key fragment not yet collected.")
	else:
		await DialogueManager.say("System", "// Fragment #6 location trace already acquired. Source Key fragment not yet collected.")
	await DialogueManager.say("Mirror Kaelen", "Fragment Six is not in this city. It is in the Cathedral Server, where failed gods sing their own error logs.")
	await DialogueManager.say("Kaelen", "Then that is where Chapter Six begins.")

func _chapter4_consequence_dialogue() -> void:
	match _chapter4_choice_key():
		"preserve":
			await DialogueManager.say("Mirror Kaelen", "In the Null Court, you preserved deleted lives. Noble. Also convenient. Nobody suffers from a decision you postpone.")
			await DialogueManager.say("Echo Mirror", "Some of us were grateful for time. Some of us heard another locked door.")
		"release":
			await DialogueManager.say("Mirror Kaelen", "In the Null Court, you released deleted lives. Brave. Also violent. You called the scar freedom because you held the knife.")
			await DialogueManager.say("Echo Mirror", "Some of us stepped into sunlight. Some of us woke inside broken walls.")
		"bargain":
			await DialogueManager.say("Mirror Kaelen", "In the Null Court, you bargained with SOVEREIGN. Wise. Also familiar. You let the jailer write terms for the jailbreak.")
			await DialogueManager.say("Echo Mirror", "Some of us survived because of the terms. Some of us now wonder who owns the fine print.")
		_:
			await DialogueManager.say("Mirror Kaelen", "The Null Court left no clear answer. The city will test the hole where your conviction should be.")

func _chapter4_choice_key() -> String:
	if GameManager.has_flag("ch4_choice_preserve_deleted"):
		return "preserve"
	if GameManager.has_flag("ch4_choice_release_deleted"):
		return "release"
	if GameManager.has_flag("ch4_choice_bargain_deleted"):
		return "bargain"
	return "unknown"

func _fade_to_black(duration: float) -> void:
	fade_rect.z_index = 100
	var tw := create_tween()
	tw.tween_property(fade_rect, "modulate:a", 1.0, duration)
	await tw.finished
