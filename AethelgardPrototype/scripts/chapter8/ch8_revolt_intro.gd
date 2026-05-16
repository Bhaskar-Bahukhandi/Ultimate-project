extends Control

## Chapter 8: The Revolt of the Saved - Source Key awakening.

const NEXT_SCENE := "res://scenes/chapter8/ch8_saved_assembly.tscn"

var fade_rect: ColorRect

func _ready() -> void:
	print("[CH8-INTRO] Initializing Revolt of the Saved intro")
	GameManager.change_state(GameManager.GameState.DIALOGUE)
	GameManager.current_chapter = 8
	GameManager.current_region = "saved_assembly"
	GameManager.set_story_flag("ch8_unlocked", true)
	GameManager.set_story_flag("ch8_revolt_intro_seen", true)
	_build_visuals()
	GameManager.save_game(GameManager.AUTOSAVE_SLOT)

	fade_rect.modulate.a = 1.0
	var tw := create_tween()
	tw.tween_property(fade_rect, "modulate:a", 0.0, 0.8)
	await tw.finished
	if not is_inside_tree(): return

	await _play_intro()
	if not is_inside_tree(): return
	await _fade_to_black(0.8)
	if not is_inside_tree(): return
	SceneTransitions.change_scene(NEXT_SCENE)

func _build_visuals() -> void:
	var bg := ColorRect.new()
	bg.name = "SourceKeyAwakeningBackground"
	bg.color = Color(0.020, 0.030, 0.045)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)

	for i in range(7):
		var shard := ColorRect.new()
		shard.name = "SourceKeyShard%d" % i
		shard.color = Color(0.50, 0.92, 1.0, 0.15 + float(i % 3) * 0.035)
		shard.position = Vector2(185 + i * 130, 150 + (i % 2) * 95)
		shard.size = Vector2(72, 160)
		shard.rotation = -0.18 + float(i % 5) * 0.09
		add_child(shard)

	var title := Label.new()
	title.text = "CHAPTER 8: THE REVOLT OF THE SAVED"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 29)
	title.add_theme_color_override("font_color", Color(0.84, 0.95, 1.0))
	title.set_anchors_preset(Control.PRESET_CENTER)
	title.offset_left = -540
	title.offset_right = 540
	title.offset_top = -64
	title.offset_bottom = -4
	add_child(title)

	var subtitle := Label.new()
	subtitle.text = "The Source Key is complete. Now the saved argue over what freedom means."
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	subtitle.add_theme_font_size_override("font_size", 15)
	subtitle.add_theme_color_override("font_color", Color(0.86, 0.90, 0.98))
	subtitle.set_anchors_preset(Control.PRESET_CENTER)
	subtitle.offset_left = -455
	subtitle.offset_right = 455
	subtitle.offset_top = 8
	subtitle.offset_bottom = 78
	add_child(subtitle)

	fade_rect = ColorRect.new()
	fade_rect.name = "Fade"
	fade_rect.color = Color.BLACK
	fade_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	fade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fade_rect.z_index = 50
	add_child(fade_rect)

func _play_intro() -> void:
	if has_node("/root/MusicManager"):
		MusicManager.play_track("data_stream")
	if has_node("/root/GlitchOverlay"):
		GlitchOverlay.flash_glitch(0.55)

	GameManager.normalize_source_key_progression()
	await DialogueManager.say("System", "// SOURCE KEY STATUS: %d / 7" % GameManager.source_key_count)
	await DialogueManager.say("Narrator", "The seventh fragment locks into place without ceremony. Across Aethelgard, doors that were never meant to open begin choosing sides.")
	await DialogueManager.say("SOVEREIGN", "A complete key is not freedom. It is a loaded weapon with public access.")
	await DialogueManager.say("Kaelen", "Then I should hear the people it was supposed to save.")

	match _chapter7_choice_key():
		"preserve":
			await DialogueManager.say("Memory Tide", "Every backup arrives with the living. Truth floods the assembly before anyone learns to breathe it.")
		"collapse":
			await DialogueManager.say("Memory Tide", "The unstable backups are gone. Some citizens call it mercy. Some call it a second deletion.")
		"merge":
			await DialogueManager.say("Memory Tide", "Merged histories surface as scars and instincts. The saved know things they never personally lived.")
		_:
			await DialogueManager.say("Memory Tide", "The Deep Backup left no clear route. The saved inherit uncertainty.")

	await DialogueManager.say("System", "// SAVED_ASSEMBLY convoked. Oakhaven, Ironhold, Mirror City, Cathedral Server, Deep Backup.")
	await DialogueManager.say("Narrator", "For the first time, Aethelgard's saved do not wait for Kaelen to choose. They call him to answer.")

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
