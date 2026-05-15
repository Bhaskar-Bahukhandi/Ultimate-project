extends Control

## Chapter 5: The Mirror City - entry sequence.
## Every reflection in this city responds to choices Kaelen already made.

const NEXT_SCENE := "res://scenes/chapter5/ch5_mirror_plaza.tscn"

var fade_rect: ColorRect

func _ready() -> void:
	print("[CH5-INTRO] Initializing Mirror City intro")
	GameManager.change_state(GameManager.GameState.DIALOGUE)
	GameManager.current_chapter = 5
	GameManager.current_region = "mirror_city"
	GameManager.set_story_flag("ch5_unlocked", true)
	GameManager.set_story_flag("ch5_mirror_city_entered", true)
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
	bg.name = "MirrorCityBackground"
	bg.color = Color(0.025, 0.028, 0.045)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)

	for i in range(10):
		var pane := ColorRect.new()
		pane.name = "MirrorPane%d" % i
		pane.color = Color(0.55, 0.85, 1.0, 0.10 + float(i % 3) * 0.035)
		pane.position = Vector2(45 + i * 124, 115 + (i % 5) * 74)
		pane.size = Vector2(72, 176)
		pane.rotation = -0.08 + float(i % 4) * 0.05
		add_child(pane)

	var title := Label.new()
	title.text = "CHAPTER 5: THE MIRROR CITY"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 29)
	title.add_theme_color_override("font_color", Color(0.80, 0.93, 1.0))
	title.set_anchors_preset(Control.PRESET_CENTER)
	title.offset_left = -430
	title.offset_right = 430
	title.offset_top = -48
	title.offset_bottom = 8
	add_child(title)

	var subtitle := Label.new()
	subtitle.text = "Every street reflects a version of Kaelen who chose differently."
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	subtitle.add_theme_font_size_override("font_size", 15)
	subtitle.add_theme_color_override("font_color", Color(0.86, 0.88, 0.96))
	subtitle.set_anchors_preset(Control.PRESET_CENTER)
	subtitle.offset_left = -420
	subtitle.offset_right = 420
	subtitle.offset_top = 14
	subtitle.offset_bottom = 72
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
		GlitchOverlay.flash_glitch(0.45)

	await DialogueManager.say("Narrator", "The path out of the Forgotten Sectors folds inward. The deleted courthouse becomes a boulevard of glass, and every window shows Kaelen walking beside himself.")
	await DialogueManager.say("System", "// UNLISTED REGION RESOLVED: MIRROR_CITY")
	await DialogueManager.say("System", "// Identity cache active. Choice echoes detected.")
	await DialogueManager.say("Kaelen", "Those are not reflections. They are branches.")

	match _chapter4_choice_key():
		"preserve":
			await DialogueManager.say("Echo Mirror", "You preserved the deleted citizens. The city has built you a thousand monuments to hesitation.")
			await DialogueManager.say("Mirror Citizen", "He waits before saving us. He calls it consent. Does waiting feel different from erasure?")
		"release":
			await DialogueManager.say("Echo Mirror", "You released the deleted citizens. The city has built you a thousand monuments to impact.")
			await DialogueManager.say("Mirror Citizen", "He opens doors quickly. Ask the walls what happens when every locked room becomes a wound.")
		"bargain":
			await DialogueManager.say("Echo Mirror", "You bargained with SOVEREIGN. The city has built you a thousand monuments to compromise.")
			await DialogueManager.say("Mirror Citizen", "He makes contracts with cages and wonders why the bars remember his name.")
		_:
			await DialogueManager.say("Echo Mirror", "The city cannot find your Chapter Four answer. So it will test the shape of your silence.")

	if GameManager.has_elara():
		await DialogueManager.say("Elara", "Every reflection is watching you like it knows the ending already.")
	if GameManager.has_flag("ch3_lyra_recruited"):
		await DialogueManager.say("Lyra", "Great. A whole city made of judgmental glass. Very subtle.")

	await DialogueManager.say("SOVEREIGN", "Identity is a function of prior decisions, Creator. You cannot debug yourself by denying the branches you cut.")
	await DialogueManager.say("Kaelen", "Then I will look at them.")

func _chapter4_choice_key() -> String:
	if GameManager.has_flag("ch4_choice_preserve_deleted"):
		return "preserve"
	if GameManager.has_flag("ch4_choice_release_deleted"):
		return "release"
	if GameManager.has_flag("ch4_choice_bargain_deleted"):
		return "bargain"
	return "unknown"

func _fade_to_black(duration: float) -> void:
	fade_rect.z_index = 100
	var tw := create_tween()
	tw.tween_property(fade_rect, "modulate:a", 1.0, duration)
	await tw.finished
