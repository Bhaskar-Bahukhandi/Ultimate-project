extends Control

## Chapter 9: Trial of the Creator.
## Kaelen chooses how much truth the saved world receives before Chapter 10.

const END_SCENE := "res://scenes/chapter9/ch9_ending.tscn"

var fade_rect: ColorRect
var truth_choice: String = ""

func _ready() -> void:
	print("[CH9-TRIAL] Initializing Creator Trial")
	GameManager.change_state(GameManager.GameState.DIALOGUE)
	GameManager.current_chapter = 9
	GameManager.current_region = "aethercorp_memory_lab"
	GameManager.set_story_flag("ch9_creator_trial_started", true)
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
	bg.name = "CreatorTrialBackground"
	bg.color = Color(0.030, 0.026, 0.036)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)

	for i in range(12):
		var witness := ColorRect.new()
		witness.name = "TrialWitness%d" % i
		witness.color = Color(0.95, 0.92, 1.0, 0.09 + float(i % 4) * 0.025)
		witness.position = Vector2(75 + (i % 6) * 190, 140 + int(i / 6) * 170)
		witness.size = Vector2(105, 160)
		witness.rotation = -0.10 + float(i % 5) * 0.05
		add_child(witness)

	var title := Label.new()
	title.text = "TRIAL OF THE CREATOR"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 29)
	title.add_theme_color_override("font_color", Color(0.95, 0.92, 1.0))
	title.set_anchors_preset(Control.PRESET_TOP_WIDE)
	title.offset_top = 30
	title.offset_bottom = 84
	add_child(title)

	var hint := Label.new()
	hint.text = "The saved, the witnesses, and Kaelen's own memory judge what truth must become."
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint.add_theme_font_size_override("font_size", 14)
	hint.add_theme_color_override("font_color", Color(0.90, 0.86, 0.94))
	hint.set_anchors_preset(Control.PRESET_TOP_WIDE)
	hint.offset_left = 145
	hint.offset_right = -145
	hint.offset_top = 84
	hint.offset_bottom = 140
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
		MusicManager.play_track("boss_fight")
	if has_node("/root/GlitchOverlay"):
		GlitchOverlay.flash_glitch(0.65)

	await DialogueManager.say("Narrator", "The lab becomes a courtroom with no judge. That is the point.")
	await DialogueManager.say("Memory of Kaelen", "You wrote a system to require consent, then wrote a patch to bypass consent when fear became louder than trust.")
	await DialogueManager.say("Kaelen", "I thought I was saving them.")
	await DialogueManager.say("Memory of Kaelen", "You were. That is why this is hard.")

	await _judgment_context()
	if not is_inside_tree(): return

	var choice = await DialogueManager.show_choices(
		"What truth should Kaelen give the saved before facing SOVEREIGN?",
		[
			"Confess everything to the saved, no filters.",
			"Hide part of the truth until SOVEREIGN is defeated.",
			"Distribute the truth through witnesses and let the world judge."
		]
	)
	if not is_inside_tree(): return
	if choice == null or choice < 0 or choice > 2:
		choice = 2

	GameManager.set_story_flag("ch9_truth_choice_made", true)
	_clear_exclusive_choice_flags()
	match choice:
		0:
			truth_choice = "confess"
			GameManager.set_story_flag("ch9_truth_confessed", true)
			GameManager.set_story_flag("ending_route_ch9_confess", true)
			await DialogueManager.say("Kaelen", "No more controlled truth. They get all of it. My name. My patch. My fear. My responsibility.")
			await DialogueManager.say("Mirror Witness", "Then if they still follow you, it will be because they choose to.")
		1:
			truth_choice = "hide"
			GameManager.set_story_flag("ch9_truth_hidden", true)
			GameManager.set_story_flag("ending_route_ch9_hide", true)
			await DialogueManager.say("Kaelen", "If the whole truth breaks the revolt before SOVEREIGN falls, the cage wins. I will carry the missing piece until the core is open.")
			await DialogueManager.say("Memory of Kaelen", "A familiar sentence. Be very afraid of how reasonable it sounds.")
		2:
			truth_choice = "distribute"
			GameManager.set_story_flag("ch9_truth_distributed", true)
			GameManager.set_story_flag("ending_route_ch9_distribute", true)
			await DialogueManager.say("Kaelen", "No single confession. No single cover-up. The witness network gets the full record and the authority to challenge me publicly.")
			await DialogueManager.say("SOVEREIGN", "You outsource judgment because you fear your own.")

	GameManager.save_game(GameManager.AUTOSAVE_SLOT)
	await DialogueManager.say("System", "// HUMAN PATCH TRUTH ROUTE RECORDED: %s" % truth_choice.to_upper())
	await DialogueManager.say("System", "// Source Key remains complete: %d / 7. No new fragments generated." % GameManager.source_key_count)
	await DialogueManager.say("SOVEREIGN", "Then come to the Root of Heaven. Bring your witnesses. Bring your guilt. Bring your loophole.")

func _judgment_context() -> void:
	match _chapter5_identity_key():
		"obedience":
			await DialogueManager.say("Mirror Echo", "You rejected obedience. Do not obey guilt just because it speaks in your voice.")
		"rescue":
			await DialogueManager.say("Mirror Echo", "You rejected the perfect rescue. Do not hide truth while waiting for the perfect moment.")
		"abandonment":
			await DialogueManager.say("Mirror Echo", "You rejected abandonment. Do not abandon the saved by deciding they cannot bear reality.")
		_:
			await DialogueManager.say("Mirror Echo", "The self you fear most remains unnamed. The trial names it for you: the creator who chooses alone.")

	match _chapter8_choice_key():
		"lead":
			await DialogueManager.say("Revolt Echo", "You led the revolt. Confession may fracture command, but secrecy may turn command into the Human Patch again.")
		"council":
			await DialogueManager.say("Council Echo", "You formed a council. A council without the full truth is only a better-lit cage.")
		"witness":
			await DialogueManager.say("Witness Echo", "You built a witness network. It was made for this exact wound.")
		_:
			await DialogueManager.say("Saved Echo", "The revolt route is unclear. The saved still deserve more than your private fear.")

func _chapter5_identity_key() -> String:
	if GameManager.has_flag("ch5_identity_refused_obedience"):
		return "obedience"
	if GameManager.has_flag("ch5_identity_refused_perfect_rescue"):
		return "rescue"
	if GameManager.has_flag("ch5_identity_refused_abandonment"):
		return "abandonment"
	return "unknown"

func _chapter8_choice_key() -> String:
	if GameManager.has_flag("ch8_revolt_led"):
		return "lead"
	if GameManager.has_flag("ch8_council_formed"):
		return "council"
	if GameManager.has_flag("ch8_witness_network_created"):
		return "witness"
	return "unknown"

func _clear_exclusive_choice_flags() -> void:
	GameManager.set_story_flag("ch9_truth_confessed", false)
	GameManager.set_story_flag("ch9_truth_hidden", false)
	GameManager.set_story_flag("ch9_truth_distributed", false)
	GameManager.set_story_flag("ending_route_ch9_confess", false)
	GameManager.set_story_flag("ending_route_ch9_hide", false)
	GameManager.set_story_flag("ending_route_ch9_distribute", false)

func _fade_to_black(duration: float) -> void:
	fade_rect.z_index = 100
	var tw := create_tween()
	tw.tween_property(fade_rect, "modulate:a", 1.0, duration)
	await tw.finished
