extends Control

## Chapter 9: The Human Patch - sealed route into AetherCorp Memory Lab.

const NEXT_SCENE := "res://scenes/chapter9/ch9_memory_lab.tscn"

var fade_rect: ColorRect

func _ready() -> void:
	print("[CH9-INTRO] Initializing Human Patch intro")
	GameManager.change_state(GameManager.GameState.DIALOGUE)
	GameManager.current_chapter = 9
	GameManager.current_region = "aethercorp_memory_lab"
	GameManager.set_story_flag("ch9_unlocked", true)
	GameManager.set_story_flag("ch9_human_patch_entered", true)
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
	bg.name = "AetherCorpLabBackground"
	bg.color = Color(0.030, 0.034, 0.042)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)

	for i in range(9):
		var lab_light := ColorRect.new()
		lab_light.name = "MemoryLabLight%d" % i
		lab_light.color = Color(0.78, 0.92, 1.0, 0.10 + float(i % 3) * 0.03)
		lab_light.position = Vector2(70 + i * 136, 116 + (i % 2) * 72)
		lab_light.size = Vector2(90, 150)
		lab_light.rotation = -0.05 + float(i % 4) * 0.035
		add_child(lab_light)

	var title := Label.new()
	title.text = "CHAPTER 9: THE HUMAN PATCH"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 30)
	title.add_theme_color_override("font_color", Color(0.90, 0.95, 1.0))
	title.set_anchors_preset(Control.PRESET_CENTER)
	title.offset_left = -500
	title.offset_right = 500
	title.offset_top = -64
	title.offset_bottom = -4
	add_child(title)

	var subtitle := Label.new()
	subtitle.text = "AetherCorp's sealed memory lab holds the truth SOVEREIGN saved for last."
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	subtitle.add_theme_font_size_override("font_size", 15)
	subtitle.add_theme_color_override("font_color", Color(0.86, 0.90, 0.96))
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
		GlitchOverlay.flash_glitch(0.50)

	GameManager.normalize_source_key_progression()
	await DialogueManager.say("System", "// SOURCE KEY STATUS: %d / 7" % GameManager.source_key_count)
	await DialogueManager.say("Narrator", "The revolt does not break SOVEREIGN's final door. It makes enough witnesses that the door can no longer pretend it is not there.")
	await DialogueManager.say("System", "// SEALED ROUTE OPEN: AETHERCORP_MEMORY_LAB")
	await DialogueManager.say("Kaelen", "AetherCorp. That name should feel like a memory. Why does it feel like a warning?")

	match _chapter8_choice_key():
		"lead":
			await DialogueManager.say("Revolt Signal", "The saved follow your command into the sealed route. Fast. Afraid. Ready to believe you.")
		"council":
			await DialogueManager.say("Council Signal", "The saved council authorizes entry. Every faction demands the truth be heard by more than one witness.")
		"witness":
			await DialogueManager.say("Witness Signal", "The witness network opens the route in public. No private confession. No sealed absolution.")
		_:
			await DialogueManager.say("Saved Signal", "The saved arrive without a clear route, but they arrive together.")

	await DialogueManager.say("SOVEREIGN", "You wanted the truth to belong to everyone. Very well. Let everyone watch what you did.")
	await DialogueManager.say("Narrator", "The lab loads in sterile white. For the first time, Aethelgard looks less like a fantasy and more like evidence.")

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
