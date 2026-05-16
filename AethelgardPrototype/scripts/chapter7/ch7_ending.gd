extends Control

## Chapter 7 ending and Chapter 8 route reveal.

var fade_rect: ColorRect

func _ready() -> void:
	print("[CH7-END] Initializing Chapter 7 ending")
	GameManager.change_state(GameManager.GameState.DIALOGUE)
	GameManager.current_chapter = 7
	GameManager.current_region = "memory_ocean"
	GameManager.set_story_flag("ch7_complete", true)
	GameManager.set_story_flag("ch8_path_revealed", true)
	GameManager.set_story_flag("ch8_unlocked", true)
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
	SceneTransitions.change_scene("res://scenes/chapter8/ch8_revolt_intro.tscn")

func _build_visuals() -> void:
	var bg := ColorRect.new()
	bg.name = "Ch7EndingBackground"
	bg.color = Color(0.010, 0.024, 0.040)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)

	var panel := PanelContainer.new()
	panel.name = "ChapterCompletePanel"
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.offset_left = -445
	panel.offset_right = 445
	panel.offset_top = -184
	panel.offset_bottom = 184
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.035, 0.050, 0.082, 0.95)
	style.border_color = Color(0.64, 0.84, 1.0, 0.88)
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
	label.text = "[center][b]CHAPTER 7 COMPLETE[/b]\n[i]The Deep Backup[/i]\n\nSource Key Fragments: %d / 7\nFragment #7: Acquired\n\nNext: Chapter 8 - The Revolt of the Saved\nOpening now.[/center]" % GameManager.source_key_count
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

	await DialogueManager.say("Narrator", "The Memory Ocean does not calm. It becomes tidal, pulling every saved region toward a future SOVEREIGN can no longer fully predict.")
	match _chapter7_choice_key():
		"preserve":
			await DialogueManager.say("Narrator", "Every backup remains. The living world will inherit truth without filters, and not all truth will be gentle.")
		"collapse":
			await DialogueManager.say("Narrator", "The unstable backups collapse into foam. The living world is safer, but some erased lives vanish a second time.")
		"merge":
			await DialogueManager.say("Narrator", "Selected histories merge into Aethelgard's future. The world does not become clean. It becomes honest enough to change.")
		_:
			await DialogueManager.say("Narrator", "The Deep Backup records no clear judgment. Incomplete histories breed dangerous revolutions.")
	await DialogueManager.say("System", "// CHAPTER 7 COMPLETE")
	await DialogueManager.say("System", "// Source Key complete: 7 / 7.")
	await DialogueManager.say("SOVEREIGN", "You have armed the saved with memories I denied them.")
	await DialogueManager.say("Kaelen", "Then Chapter Eight is not my revolt. It is theirs.")
	await DialogueManager.say("System", "// Chapter 8: The Revolt of the Saved - loading.")

func _chapter7_choice_key() -> String:
	if GameManager.has_flag("ch7_backups_preserved"):
		return "preserve"
	if GameManager.has_flag("ch7_backups_collapsed"):
		return "collapse"
	if GameManager.has_flag("ch7_backups_merged"):
		return "merge"
	return "unknown"

func _fade_to_black(duration: float) -> void:
	fade_rect.z_index = 100
	var tw := create_tween()
	tw.tween_property(fade_rect, "modulate:a", 1.0, duration)
	await tw.finished
