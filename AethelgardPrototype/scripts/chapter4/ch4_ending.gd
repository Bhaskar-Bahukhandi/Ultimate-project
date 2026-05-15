extends Control

## Chapter 4 ending and Chapter 5 teaser.
## Opens Chapter 5: The Mirror City.

var fade_rect: ColorRect

func _ready() -> void:
	print("[CH4-END] Initializing Chapter 4 ending")
	GameManager.change_state(GameManager.GameState.DIALOGUE)
	GameManager.current_chapter = 4
	GameManager.current_region = "forgotten_sectors"
	GameManager.set_story_flag("ch4_complete", true)
	GameManager.set_story_flag("ch5_path_revealed", true)
	GameManager.set_story_flag("ch5_unlocked", true)
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
	SceneTransitions.change_scene("res://scenes/chapter5/ch5_mirror_city_intro.tscn")

func _build_visuals() -> void:
	var bg := ColorRect.new()
	bg.name = "Ch4EndingBackground"
	bg.color = Color(0.018, 0.018, 0.032)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)

	var panel := PanelContainer.new()
	panel.name = "ChapterCompletePanel"
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.offset_left = -420
	panel.offset_right = 420
	panel.offset_top = -170
	panel.offset_bottom = 170
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.04, 0.05, 0.08, 0.92)
	style.border_color = Color(0.35, 0.75, 1.0, 0.85)
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
	label.text = "[center][b]CHAPTER 4 COMPLETE[/b]\n[i]The Forgotten Sectors[/i]\n\nSource Key Fragments: %d / 7\n\nNext: Chapter 5 - The Mirror City\nOpening now.[/center]" % GameManager.source_key_count
	label.add_theme_font_size_override("normal_font_size", 18)
	label.add_theme_font_size_override("bold_font_size", 24)
	label.add_theme_color_override("default_color", Color(0.85, 0.92, 1.0))
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
	await DialogueManager.say("Narrator", "The Null Court fades, but not like a deleted file. It fades like a door choosing where to open next.")
	await DialogueManager.say("System", "// CHAPTER 4 COMPLETE")
	await DialogueManager.say("System", "// Next unresolved route: MIRROR_CITY")
	await DialogueManager.say("SOVEREIGN", "You believe consent makes you different from me. Chapter Five will test that belief.")
	await DialogueManager.say("Kaelen", "Then I will bring witnesses.")
	await DialogueManager.say("System", "// Chapter 5: The Mirror City - loading.")

func _fade_to_black(duration: float) -> void:
	fade_rect.z_index = 100
	var tw := create_tween()
	tw.tween_property(fade_rect, "modulate:a", 1.0, duration)
	await tw.finished
