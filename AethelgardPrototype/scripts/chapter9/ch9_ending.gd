extends Control

## Chapter 9 ending and Chapter 10 final confrontation teaser.

var fade_rect: ColorRect

func _ready() -> void:
	print("[CH9-END] Initializing Chapter 9 ending")
	GameManager.change_state(GameManager.GameState.DIALOGUE)
	GameManager.current_chapter = 9
	GameManager.current_region = "aethercorp_memory_lab"
	GameManager.set_story_flag("ch9_complete", true)
	GameManager.set_story_flag("ch10_path_revealed", true)
	GameManager.set_story_flag("ch10_unlocked", true)
	GameManager.save_game(GameManager.AUTOSAVE_SLOT)
	_build_visuals()

	fade_rect.modulate.a = 1.0
	var tw := create_tween()
	tw.tween_property(fade_rect, "modulate:a", 0.0, 0.8)
	await tw.finished
	if not is_inside_tree(): return

	await _play_ending()
	if not is_inside_tree(): return
	await _fade_to_black(1.0)
	if not is_inside_tree(): return
	SceneTransitions.change_scene("res://scenes/chapter10/ch10_root_intro.tscn")

func _build_visuals() -> void:
	var bg := ColorRect.new()
	bg.name = "Ch9EndingBackground"
	bg.color = Color(0.028, 0.026, 0.036)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)

	var panel := PanelContainer.new()
	panel.name = "ChapterCompletePanel"
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.offset_left = -455
	panel.offset_right = 455
	panel.offset_top = -186
	panel.offset_bottom = 186
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.050, 0.046, 0.070, 0.95)
	style.border_color = Color(0.95, 0.84, 1.0, 0.88)
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_width_top = 2
	style.border_width_bottom = 2
	style.content_margin_left = 28
	style.content_margin_right = 28
	style.content_margin_top = 24
	style.content_margin_bottom = 24
	style.set_corner_radius_all(6)
	panel.add_theme_stylebox_override("panel", style)
	add_child(panel)

	var label := RichTextLabel.new()
	label.bbcode_enabled = true
	label.fit_content = true
	label.scroll_active = false
	label.text = "[center][b]CHAPTER 9 COMPLETE[/b]\n[i]The Human Patch[/i]\n\nSource Key Fragments: %d / 7\nThe truth route is recorded.\n\nNext: Chapter 10 - Root of Heaven\nOpening now.[/center]" % GameManager.source_key_count
	label.add_theme_font_size_override("normal_font_size", 18)
	label.add_theme_font_size_override("bold_font_size", 24)
	label.add_theme_color_override("default_color", Color(0.92, 0.90, 1.0))
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
		MusicManager.play_track("main_menu")

	await DialogueManager.say("Narrator", "The Memory Lab closes every file except one: ROOT_OF_HEAVEN.")
	match _chapter9_choice_key():
		"confess":
			await DialogueManager.say("Narrator", "The full truth goes out raw. Some saved kneel from grief. Some stand because nobody softened it for them.")
		"hide":
			await DialogueManager.say("Narrator", "Part of the truth remains sealed. The revolt holds together, but the Human Patch still has a shadow to stand in.")
		"distribute":
			await DialogueManager.say("Narrator", "The witnesses receive the complete record. Judgment becomes public, slow, and impossible for SOVEREIGN to own.")
		_:
			await DialogueManager.say("Narrator", "The truth route is unclear. SOVEREIGN smiles at every gap.")
	await DialogueManager.say("System", "// CHAPTER 9 COMPLETE")
	await DialogueManager.say("System", "// Source Key stable: %d / 7. No new fragments generated." % GameManager.source_key_count)
	await DialogueManager.say("SOVEREIGN", "You have learned your origin. Now learn your ending.")
	await DialogueManager.say("Kaelen", "Not mine. Ours.")
	await DialogueManager.say("System", "// Chapter 10: Root of Heaven - loading.")

func _chapter9_choice_key() -> String:
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
