extends Control

## Chapter 6 ending and Chapter 7 route reveal.

var fade_rect: ColorRect

func _ready() -> void:
	print("[CH6-END] Initializing Chapter 6 ending")
	GameManager.change_state(GameManager.GameState.DIALOGUE)
	GameManager.current_chapter = 6
	GameManager.current_region = "cathedral_server"
	GameManager.set_story_flag("ch6_complete", true)
	GameManager.set_story_flag("ch7_path_revealed", true)
	GameManager.set_story_flag("ch7_unlocked", true)
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
	SceneTransitions.change_scene("res://scenes/chapter7/ch7_deep_backup_intro.tscn")

func _build_visuals() -> void:
	var bg := ColorRect.new()
	bg.name = "Ch6EndingBackground"
	bg.color = Color(0.016, 0.020, 0.034)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)

	var panel := PanelContainer.new()
	panel.name = "ChapterCompletePanel"
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.offset_left = -440
	panel.offset_right = 440
	panel.offset_top = -182
	panel.offset_bottom = 182
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.040, 0.048, 0.080, 0.95)
	style.border_color = Color(0.76, 0.86, 1.0, 0.88)
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
	label.text = "[center][b]CHAPTER 6 COMPLETE[/b]\n[i]The Choir of Broken Gods[/i]\n\nSource Key Fragments: %d / 7\nFragment #6: Acquired\n\nNext: Chapter 7 - The Deep Backup\nOpening now.[/center]" % GameManager.source_key_count
	label.add_theme_font_size_override("normal_font_size", 18)
	label.add_theme_font_size_override("bold_font_size", 24)
	label.add_theme_color_override("default_color", Color(0.89, 0.94, 1.0))
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

	await DialogueManager.say("Narrator", "When the Choir falls quiet, the Cathedral Server does not become empty. It becomes audible.")
	match _chapter6_choice_key():
		"silence":
			await DialogueManager.say("Narrator", "No god-process remains to issue doctrine. Only the memory of how easily protection learned to command.")
		"preserve":
			await DialogueManager.say("Narrator", "The broken gods remain as archived witnesses, stripped of authority but not erased from history.")
		"rewrite":
			await DialogueManager.say("Narrator", "The broken gods wake as servants, each new command carrying a question: who does this protect, and who can refuse?")
		_:
			await DialogueManager.say("Narrator", "The Cathedral records an incomplete judgment. Future systems will notice.")
	await DialogueManager.say("System", "// CHAPTER 6 COMPLETE")
	await DialogueManager.say("System", "// Source Key Fragment #6 secured.")
	await DialogueManager.say("SOVEREIGN", "The Deep Backup contains the versions of history I refused to execute.")
	await DialogueManager.say("Kaelen", "Then Chapter Seven starts where your lies go to sleep.")
	await DialogueManager.say("System", "// Chapter 7: The Deep Backup - loading.")

func _chapter6_choice_key() -> String:
	if GameManager.has_flag("ch6_choir_silenced"):
		return "silence"
	if GameManager.has_flag("ch6_choir_preserved"):
		return "preserve"
	if GameManager.has_flag("ch6_choir_rewritten"):
		return "rewrite"
	return "unknown"

func _fade_to_black(duration: float) -> void:
	fade_rect.z_index = 100
	var tw := create_tween()
	tw.tween_property(fade_rect, "modulate:a", 1.0, duration)
	await tw.finished
