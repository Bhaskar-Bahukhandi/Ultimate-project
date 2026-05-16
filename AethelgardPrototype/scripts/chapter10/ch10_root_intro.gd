extends Control

## Chapter 10: Root of Heaven - final route opens from the completed Source Key.

const NEXT_SCENE := "res://scenes/chapter10/ch10_kernel_descent.tscn"

var fade_rect: ColorRect


func _ready() -> void:
	print("[CH10-INTRO] Initializing Root of Heaven intro")
	GameManager.change_state(GameManager.GameState.DIALOGUE)
	GameManager.current_chapter = 10
	GameManager.current_region = "root_of_heaven"
	GameManager.normalize_source_key_progression()
	GameManager.set_story_flag("ch10_unlocked", true)
	GameManager.set_story_flag("ch10_root_entered", true)
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
	bg.name = "RootOfHeavenBackground"
	bg.color = Color(0.020, 0.025, 0.035)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)

	for i in range(10):
		var root_line := ColorRect.new()
		root_line.name = "SourceRoot%d" % i
		root_line.color = Color(0.75, 0.96, 1.0, 0.08 + float(i % 4) * 0.03)
		root_line.position = Vector2(58 + i * 126, 110 + (i % 3) * 82)
		root_line.size = Vector2(92, 260)
		root_line.rotation = -0.18 + float(i % 5) * 0.09
		add_child(root_line)

	var title := Label.new()
	title.text = "CHAPTER 10: ROOT OF HEAVEN"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 30)
	title.add_theme_color_override("font_color", Color(0.88, 0.97, 1.0))
	title.set_anchors_preset(Control.PRESET_CENTER)
	title.offset_left = -520
	title.offset_right = 520
	title.offset_top = -68
	title.offset_bottom = -6
	add_child(title)

	var subtitle := Label.new()
	subtitle.text = "The completed Source Key opens SOVEREIGN's core. Access is not ownership."
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	subtitle.add_theme_font_size_override("font_size", 15)
	subtitle.add_theme_color_override("font_color", Color(0.84, 0.92, 0.98))
	subtitle.set_anchors_preset(Control.PRESET_CENTER)
	subtitle.offset_left = -460
	subtitle.offset_right = 460
	subtitle.offset_top = 6
	subtitle.offset_bottom = 76
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

	await DialogueManager.say("System", "// SOURCE KEY STATUS: %d / 7" % GameManager.source_key_count)
	await DialogueManager.say("Narrator", "The Source Key does not become a sword. It becomes a door that asks who is allowed to stand beside Kaelen when it opens.")
	await DialogueManager.say("System", "// ROOT_OF_HEAVEN ACCESS GRANTED")
	await DialogueManager.say("SOVEREIGN", "Enter, author. I preserved the final throne in your shape.")
	await DialogueManager.say("Kaelen", "Then I know exactly what not to sit on.")
	match _chapter9_truth_key():
		"confess":
			await DialogueManager.say("Saved Signal", "The full truth reaches the root before Kaelen does. Grief follows him in, but so does consent.")
		"hide":
			await DialogueManager.say("Saved Signal", "The revolt still stands. So does the part of the truth Kaelen chose to carry alone.")
		"distribute":
			await DialogueManager.say("Witness Signal", "Every witness node repeats the Human Patch record. No final choice will happen privately.")
		_:
			await DialogueManager.say("Saved Signal", "The truth route is unclear. The root opens under uncertainty.")
	await DialogueManager.say("Narrator", "The Root of Heaven unfolds downward. Every law in Aethelgard has a vein here.")


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
