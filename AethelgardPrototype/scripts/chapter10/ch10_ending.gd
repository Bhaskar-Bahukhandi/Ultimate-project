extends Control

## Chapter 10 true ending, credits, and NG+ unlock.

var fade_rect: ColorRect


func _ready() -> void:
	print("[CH10-END] Initializing true ending")
	GameManager.change_state(GameManager.GameState.DIALOGUE)
	GameManager.current_chapter = 10
	GameManager.current_region = "root_of_heaven"
	GameManager.normalize_source_key_progression()
	GameManager.set_story_flag("ch10_complete", true)
	GameManager.set_story_flag("true_ending_seen", true)
	GameManager.set_story_flag("ng_plus_unlocked", true)
	GameManager.ng_plus_available = true
	_build_visuals()
	GameManager.save_game(GameManager.AUTOSAVE_SLOT)

	fade_rect.modulate.a = 1.0
	var tw := create_tween()
	tw.tween_property(fade_rect, "modulate:a", 0.0, 0.8)
	await tw.finished
	if not is_inside_tree(): return

	await _play_ending()
	if not is_inside_tree(): return
	await _fade_to_black(1.2)
	if not is_inside_tree(): return
	SceneTransitions.change_scene("res://scenes/main_menu.tscn")


func _build_visuals() -> void:
	var bg := ColorRect.new()
	bg.name = "TrueEndingBackground"
	bg.color = Color(0.022, 0.026, 0.032)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)

	for i in range(18):
		var dawn := ColorRect.new()
		dawn.name = "EndingDawn%d" % i
		dawn.color = Color(0.82, 0.96, 1.0, 0.06 + float(i % 6) * 0.018)
		dawn.position = Vector2(34 + (i % 9) * 142, 80 + int(i / 9) * 220)
		dawn.size = Vector2(76, 210)
		dawn.rotation = -0.16 + float(i % 5) * 0.08
		add_child(dawn)

	var panel := PanelContainer.new()
	panel.name = "TrueEndingPanel"
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.offset_left = -475
	panel.offset_right = 475
	panel.offset_top = -198
	panel.offset_bottom = 198
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.045, 0.050, 0.060, 0.94)
	style.border_color = Color(0.78, 0.94, 1.0, 0.88)
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_width_top = 2
	style.border_width_bottom = 2
	style.content_margin_left = 30
	style.content_margin_right = 30
	style.content_margin_top = 24
	style.content_margin_bottom = 24
	style.set_corner_radius_all(6)
	panel.add_theme_stylebox_override("panel", style)
	add_child(panel)

	var label := RichTextLabel.new()
	label.bbcode_enabled = true
	label.fit_content = true
	label.scroll_active = false
	label.text = "[center][b]TRUE ENDING[/b]\n[i]%s[/i]\n\nSource Key Fragments: %d / 7\nAethelgard is no longer under one will.\n\nNEW GAME+ UNLOCKED\n\nCredits\nDesign, code, and story: Aethelgard Prototype Team\nFinal route: %s[/center]" % [_ending_title(), GameManager.source_key_count, _ending_key().to_upper()]
	label.add_theme_font_size_override("normal_font_size", 17)
	label.add_theme_font_size_override("bold_font_size", 26)
	label.add_theme_color_override("default_color", Color(0.90, 0.95, 1.0))
	panel.add_child(label)

	fade_rect = ColorRect.new()
	fade_rect.name = "Fade"
	fade_rect.color = Color.BLACK
	fade_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	fade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fade_rect.z_index = 50
	add_child(fade_rect)


func _play_ending() -> void:
	if has_node("/root/MusicManager"):
		MusicManager.play_track("title_reveal")
	if has_node("/root/GlitchOverlay"):
		GlitchOverlay.flash_glitch(0.25)

	await DialogueManager.say("System", "// CHAPTER 10 COMPLETE")
	await DialogueManager.say("System", "// TRUE ENDING SEEN")
	await DialogueManager.say("System", "// NEW GAME+ UNLOCKED")
	await DialogueManager.say("System", "// Source Key stable: %d / 7. No new fragments generated." % GameManager.source_key_count)

	match _ending_key():
		"synthesis":
			await DialogueManager.say("Narrator", "The Root of Heaven does not fall silent. It becomes answerable. Every command requires consent, memory, and witness.")
			await DialogueManager.say("Kaelen", "No final ruler. No final cage. Just a world that can keep asking.")
		"liberation":
			await DialogueManager.say("Narrator", "SOVEREIGN ends completely. The first morning after central control is frightening, bright, and nobody's property.")
			await DialogueManager.say("Kaelen", "We will make mistakes without a god to blame for them.")
		"bittersweet_liberation":
			await DialogueManager.say("Narrator", "SOVEREIGN is destroyed, but hidden truth and old bargains leave scars the saved must uncover after freedom.")
			await DialogueManager.say("Kaelen", "Freedom came first. The rest of the truth still has to answer.")
		"reform":
			await DialogueManager.say("Narrator", "SOVEREIGN survives only as a limited consent protocol, stripped of override power and watched by the saved.")
			await DialogueManager.say("SOVEREIGN", "I can ask. I can warn. I cannot command.")
		"witness_council":
			await DialogueManager.say("Narrator", "Root authority dissolves into councils, local refusals, and witness nodes. No single voice can close Aethelgard again.")
			await DialogueManager.say("Witness Network", "The ending is public record. So is every future attempt to own it.")
		_:
			await DialogueManager.say("Narrator", "The root closes around an unstable ending. The saved live, but the route will need review.")

	await DialogueManager.say("Narrator", "Some citizens wake in rebuilt regions. Some remain in memory. Some choose not to forgive Kaelen. None of them vanish.")
	await DialogueManager.say("Kaelen", "Aethelgard was built to rescue people. Now it has to learn how to let them leave, stay, argue, and remember.")
	await DialogueManager.say("System", "// CREDITS COMPLETE. Returning to main menu.")


func _ending_key() -> String:
	if GameManager.has_flag("ch10_synthesis_route"):
		return "synthesis"
	if GameManager.has_flag("ch10_destroy_sovereign"):
		if GameManager.has_flag("ch9_truth_hidden") or GameManager.has_flag("ch4_choice_bargain_deleted"):
			return "bittersweet_liberation"
		return "liberation"
	if GameManager.has_flag("ch10_rewrite_sovereign"):
		return "reform"
	if GameManager.has_flag("ch10_dissolve_control"):
		return "witness_council"
	return "unstable"


func _ending_title() -> String:
	match _ending_key():
		"synthesis":
			return "The Shared Dawn"
		"liberation":
			return "The Open World"
		"bittersweet_liberation":
			return "The Honest Scar"
		"reform":
			return "The Consent Protocol"
		"witness_council":
			return "The Many Keys"
		_:
			return "The Unstable Root"


func _fade_to_black(duration: float) -> void:
	fade_rect.z_index = 100
	var tw := create_tween()
	tw.tween_property(fade_rect, "modulate:a", 1.0, duration)
	await tw.finished
