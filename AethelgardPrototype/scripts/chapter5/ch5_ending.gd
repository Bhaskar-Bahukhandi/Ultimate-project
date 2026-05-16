extends Control

## Chapter 5 ending and Chapter 6 route reveal.
## This ends the Mirror City slice without awarding Source Key Fragment 6.

var fade_rect: ColorRect

func _ready() -> void:
	print("[CH5-END] Initializing Chapter 5 ending")
	GameManager.change_state(GameManager.GameState.DIALOGUE)
	GameManager.current_chapter = 5
	GameManager.current_region = "mirror_city"
	GameManager.set_story_flag("ch5_complete", true)
	GameManager.set_story_flag("ch6_path_revealed", true)
	GameManager.set_story_flag("ch6_unlocked", true)
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
	SceneTransitions.change_scene("res://scenes/chapter6/ch6_cathedral_intro.tscn")

func _build_visuals() -> void:
	var bg := ColorRect.new()
	bg.name = "Ch5EndingBackground"
	bg.color = Color(0.018, 0.024, 0.036)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)

	var panel := PanelContainer.new()
	panel.name = "ChapterCompletePanel"
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.offset_left = -430
	panel.offset_right = 430
	panel.offset_top = -175
	panel.offset_bottom = 175
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.045, 0.055, 0.085, 0.94)
	style.border_color = Color(0.68, 0.88, 1.0, 0.86)
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
	label.text = "[center][b]CHAPTER 5 COMPLETE[/b]\n[i]The Mirror City[/i]\n\nSource Key Fragments: %d / 7\nFragment #6: Location Trace Found\n\nNext: Chapter 6 - The Choir of Broken Gods\nOpening now.[/center]" % GameManager.source_key_count
	label.add_theme_font_size_override("normal_font_size", 18)
	label.add_theme_font_size_override("bold_font_size", 24)
	label.add_theme_color_override("default_color", Color(0.88, 0.94, 1.0))
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

	await DialogueManager.say("Narrator", "The Mirror City does not vanish when the trial ends. It simply stops pretending the reflections are separate from Kaelen.")
	await DialogueManager.say("System", "// CHAPTER 5 COMPLETE")
	await DialogueManager.say("System", "// Fragment #6 trace: CATHEDRAL_SERVER")
	await DialogueManager.say("SOVEREIGN", "The Choir will show you what happens when abandoned systems learn to pray.")
	await DialogueManager.say("Kaelen", "Then I will listen before I cut the power.")
	await DialogueManager.say("System", "// Chapter 6: The Choir of Broken Gods - loading.")

func _fade_to_black(duration: float) -> void:
	fade_rect.z_index = 100
	var tw := create_tween()
	tw.tween_property(fade_rect, "modulate:a", 1.0, duration)
	await tw.finished
