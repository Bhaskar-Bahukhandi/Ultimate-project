extends Control

## Chapter 8 ending and Chapter 9 truth reveal teaser.

var fade_rect: ColorRect

func _ready() -> void:
	print("[CH8-END] Initializing Chapter 8 ending")
	GameManager.change_state(GameManager.GameState.DIALOGUE)
	GameManager.current_chapter = 8
	GameManager.current_region = "saved_assembly"
	GameManager.set_story_flag("ch8_complete", true)
	GameManager.set_story_flag("ch9_path_revealed", true)
	GameManager.set_story_flag("ch9_unlocked", true)
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
	SceneTransitions.change_scene("res://scenes/chapter9/ch9_human_patch_intro.tscn")

func _build_visuals() -> void:
	var bg := ColorRect.new()
	bg.name = "Ch8EndingBackground"
	bg.color = Color(0.025, 0.026, 0.040)
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
	style.bg_color = Color(0.050, 0.050, 0.075, 0.95)
	style.border_color = Color(0.86, 0.78, 1.0, 0.88)
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
	label.text = "[center][b]CHAPTER 8 COMPLETE[/b]\n[i]The Revolt of the Saved[/i]\n\nSource Key Fragments: %d / 7\nThe Source Key remains complete.\n\nNext: Chapter 9 - The Human Patch\nOpening now.[/center]" % GameManager.source_key_count
	label.add_theme_font_size_override("normal_font_size", 18)
	label.add_theme_font_size_override("bold_font_size", 24)
	label.add_theme_color_override("default_color", Color(0.90, 0.91, 1.0))
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

	await DialogueManager.say("Narrator", "The Saved Assembly does not become peaceful. It becomes awake.")
	match _chapter8_choice_key():
		"lead":
			await DialogueManager.say("Narrator", "The revolt moves under Kaelen's direct command, fast enough to strike SOVEREIGN before every wound becomes a committee.")
		"council":
			await DialogueManager.say("Narrator", "The saved form a council. It is slower, louder, and harder for any one person to corrupt.")
		"witness":
			await DialogueManager.say("Narrator", "The saved build a witness network. Power can move, but every movement leaves a record and an answerable name.")
		_:
			await DialogueManager.say("Narrator", "The revolt records an unclear route. The saved move anyway, carrying uncertainty as a banner.")
	await DialogueManager.say("System", "// CHAPTER 8 COMPLETE")
	await DialogueManager.say("System", "// Source Key stable: %d / 7. No new fragments generated." % GameManager.source_key_count)
	await DialogueManager.say("SOVEREIGN", "You have built a rebellion out of witnesses. How quaint.")
	await DialogueManager.say("Kaelen", "No. I built a room full of people you could not make disappear.")
	await DialogueManager.say("SOVEREIGN", "Then Chapter Nine will show them the human patch you have been protecting from yourself.")
	await DialogueManager.say("System", "// Chapter 9: The Human Patch - loading.")

func _chapter8_choice_key() -> String:
	if GameManager.has_flag("ch8_revolt_led"):
		return "lead"
	if GameManager.has_flag("ch8_council_formed"):
		return "council"
	if GameManager.has_flag("ch8_witness_network_created"):
		return "witness"
	return "unknown"

func _fade_to_black(duration: float) -> void:
	fade_rect.z_index = 100
	var tw := create_tween()
	tw.tween_property(fade_rect, "modulate:a", 1.0, duration)
	await tw.finished
