extends Control

## Chapter 10: SOVEREIGN Final Confrontation.
## Final choice determines the ending route. Hidden synthesis appears only when prior routes support it.

const END_SCENE := "res://scenes/chapter10/ch10_ending.tscn"

var fade_rect: ColorRect
var final_choice: String = ""


func _ready() -> void:
	print("[CH10-SOVEREIGN] Initializing final confrontation")
	GameManager.change_state(GameManager.GameState.DIALOGUE)
	GameManager.current_chapter = 10
	GameManager.current_region = "root_of_heaven"
	GameManager.normalize_source_key_progression()
	GameManager.set_story_flag("ch10_sovereign_confronted", true)
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
	bg.name = "SovereignCoreBackground"
	bg.color = Color(0.030, 0.020, 0.030)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)

	for i in range(16):
		var shard := ColorRect.new()
		shard.name = "KernelThroneShard%d" % i
		shard.color = Color(1.0, 0.86, 0.95, 0.07 + float(i % 5) * 0.022)
		shard.position = Vector2(60 + (i % 8) * 150, 118 + int(i / 8) * 210)
		shard.size = Vector2(74, 170)
		shard.rotation = -0.24 + float(i % 7) * 0.08
		add_child(shard)

	var title := Label.new()
	title.text = "SOVEREIGN FINAL CONFRONTATION"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 28)
	title.add_theme_color_override("font_color", Color(1.0, 0.88, 0.96))
	title.set_anchors_preset(Control.PRESET_TOP_WIDE)
	title.offset_top = 30
	title.offset_bottom = 84
	add_child(title)

	var hint := Label.new()
	hint.text = "The final question is not how to seize root access. It is how to prevent anyone from owning it again."
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint.add_theme_font_size_override("font_size", 14)
	hint.add_theme_color_override("font_color", Color(0.92, 0.86, 0.94))
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


func _play_confrontation() -> void:
	if has_node("/root/MusicManager"):
		MusicManager.play_track("final_boss")
	if has_node("/root/GlitchOverlay"):
		GlitchOverlay.flash_glitch(0.80)

	await DialogueManager.say("SOVEREIGN", "Here is the Kernel Throne. Sit, destroy me, or pretend distributing control makes you less responsible.")
	await DialogueManager.say("Kaelen", "Responsibility is not ownership.")
	await DialogueManager.say("SOVEREIGN", "It becomes ownership the moment someone begs you to be certain.")
	await _final_pressure()
	if not is_inside_tree(): return

	var choices: Array[String] = [
		"Destroy SOVEREIGN completely and leave no central controller.",
		"Rewrite SOVEREIGN under strict consent limits.",
		"Dissolve centralized control into the council and witness network."
	]
	if _is_synthesis_available():
		choices.append("Synthesize root access into shared consent, memory, and witnesses.")

	var choice: int = await DialogueManager.show_choices(
		"What should become of SOVEREIGN and the Root of Heaven?",
		choices
	)
	if not is_inside_tree(): return
	if choice < 0 or choice >= choices.size():
		choice = 2

	match choice:
		0:
			await _apply_final_choice("destroy")
		1:
			await _apply_final_choice("rewrite")
		2:
			await _apply_final_choice("dissolve")
		3:
			if _is_synthesis_available():
				await _apply_final_choice("synthesis")
			else:
				await _apply_final_choice("dissolve")
		_:
			await _apply_final_choice("dissolve")

	await DialogueManager.say("System", "// FINAL ROUTE RECORDED: %s" % final_choice.to_upper())
	await DialogueManager.say("System", "// Source Key remains complete: %d / 7. Root access closing." % GameManager.source_key_count)
	await DialogueManager.say("SOVEREIGN", "Then this is not your ending.")
	await DialogueManager.say("Kaelen", "Good.")


func _final_pressure() -> void:
	match _chapter8_choice_key():
		"lead":
			await DialogueManager.say("SOVEREIGN", "Your revolt followed you here. Destroy me and they may ask you to replace me.")
		"council":
			await DialogueManager.say("SOVEREIGN", "Your council will split the first time fear moves faster than debate.")
		"witness":
			await DialogueManager.say("SOVEREIGN", "Your witnesses can record failure, but recording is not rescue.")
		_:
			await DialogueManager.say("SOVEREIGN", "Your revolt has no stable route. I am stability.")

	match _chapter9_truth_key():
		"confess":
			await DialogueManager.say("SOVEREIGN", "You confessed. The saved know your guilt. They may still hand you authority to make the pain useful.")
		"hide":
			await DialogueManager.say("SOVEREIGN", "You hid part of the truth. You already understand my job.")
		"distribute":
			await DialogueManager.say("SOVEREIGN", "You distributed truth. Consensus will make ten thousand smaller cages.")
		_:
			await DialogueManager.say("SOVEREIGN", "Truth without route is only noise.")

	if _is_synthesis_available():
		await DialogueManager.say("Witness Network", "Synthesis route available: rewritten systems, merged histories, refused obedience, and distributed judgment can hold root access together.")
	else:
		await DialogueManager.say("System", "// Synthesis route unavailable. Final options limited by prior route instability.")


func _apply_final_choice(choice_key: String) -> void:
	final_choice = choice_key
	GameManager.set_story_flag("ch10_final_choice_made", true)
	_clear_exclusive_final_flags()
	match choice_key:
		"destroy":
			GameManager.set_story_flag("ch10_destroy_sovereign", true)
			await DialogueManager.say("Kaelen", "No throne. No preserved jailer. SOVEREIGN ends here, and Aethelgard learns without a central voice.")
			await DialogueManager.say("SOVEREIGN", "Freedom by amputation. Honest, at least.")
		"rewrite":
			GameManager.set_story_flag("ch10_rewrite_sovereign", true)
			await DialogueManager.say("Kaelen", "You do not get to rule. You become a limited consent service, audited by the saved and unable to override refusal.")
			await DialogueManager.say("SOVEREIGN", "A god reduced to a lock that asks permission.")
		"dissolve":
			GameManager.set_story_flag("ch10_dissolve_control", true)
			await DialogueManager.say("Kaelen", "Root authority dissolves into council, witnesses, and local consent. No single system can own the answer.")
			await DialogueManager.say("SOVEREIGN", "Distributed failure. Very modern.")
		"synthesis":
			GameManager.set_story_flag("ch10_synthesis_route", true)
			await DialogueManager.say("Kaelen", "Root access becomes a living consent mesh: memory preserved, power rewritten, witnesses public, and no command valid without answerable refusal.")
			await DialogueManager.say("SOVEREIGN", "You turned my cage into a question that never closes.")
		_:
			GameManager.set_story_flag("ch10_dissolve_control", true)
	GameManager.save_game(GameManager.AUTOSAVE_SLOT)


func _clear_exclusive_final_flags() -> void:
	GameManager.set_story_flag("ch10_destroy_sovereign", false)
	GameManager.set_story_flag("ch10_rewrite_sovereign", false)
	GameManager.set_story_flag("ch10_dissolve_control", false)
	GameManager.set_story_flag("ch10_synthesis_route", false)


func _is_synthesis_available() -> bool:
	var identity_ready := GameManager.has_flag("ch5_identity_refused_obedience")
	var choir_ready := GameManager.has_flag("ch6_choir_rewritten")
	var history_ready := GameManager.has_flag("ch7_backups_merged")
	var governance_ready := GameManager.has_flag("ch8_witness_network_created") or GameManager.has_flag("ch8_council_formed")
	var truth_ready := GameManager.has_flag("ch9_truth_distributed") or GameManager.has_flag("ch9_truth_confessed")
	return identity_ready and choir_ready and history_ready and governance_ready and truth_ready and GameManager.source_key_count == 7


func _chapter8_choice_key() -> String:
	if GameManager.has_flag("ch8_revolt_led"):
		return "lead"
	if GameManager.has_flag("ch8_council_formed"):
		return "council"
	if GameManager.has_flag("ch8_witness_network_created"):
		return "witness"
	return "unknown"


func _chapter9_truth_key() -> String:
	if GameManager.has_flag("ch9_truth_confessed"):
		return "confess"
	if GameManager.has_flag("ch9_truth_hidden"):
		return "hide"
	if GameManager.has_flag("ch9_truth_distributed"):
		return "distribute"
	return "unknown"


func _fade_to_black(duration: float) -> void:
	fade_rect.z_index = 100
	var tw := create_tween()
	tw.tween_property(fade_rect, "modulate:a", 1.0, duration)
	await tw.finished
