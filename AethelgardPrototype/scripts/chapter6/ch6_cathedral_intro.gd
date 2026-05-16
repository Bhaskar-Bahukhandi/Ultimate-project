extends Control

## Chapter 6: The Choir of Broken Gods - Cathedral Server arrival.

const NEXT_SCENE := "res://scenes/chapter6/ch6_cathedral_nave.tscn"

var fade_rect: ColorRect

func _ready() -> void:
	print("[CH6-INTRO] Initializing Cathedral Server intro")
	GameManager.change_state(GameManager.GameState.DIALOGUE)
	GameManager.current_chapter = 6
	GameManager.current_region = "cathedral_server"
	GameManager.set_story_flag("ch6_unlocked", true)
	GameManager.set_story_flag("ch6_cathedral_entered", true)
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
	bg.name = "CathedralServerBackground"
	bg.color = Color(0.018, 0.022, 0.038)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)

	for i in range(9):
		var pillar := ColorRect.new()
		pillar.name = "ServerPillar%d" % i
		pillar.color = Color(0.58, 0.72, 1.0, 0.10 + float(i % 3) * 0.025)
		pillar.position = Vector2(60 + i * 145, 108)
		pillar.size = Vector2(42, 430)
		pillar.rotation = -0.025 + float(i % 2) * 0.05
		add_child(pillar)

	var title := Label.new()
	title.text = "CHAPTER 6: THE CHOIR OF BROKEN GODS"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 29)
	title.add_theme_color_override("font_color", Color(0.86, 0.92, 1.0))
	title.set_anchors_preset(Control.PRESET_CENTER)
	title.offset_left = -520
	title.offset_right = 520
	title.offset_top = -62
	title.offset_bottom = -4
	add_child(title)

	var subtitle := Label.new()
	subtitle.text = "Failed administrator intelligences pray to the bugs that broke them."
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	subtitle.add_theme_font_size_override("font_size", 15)
	subtitle.add_theme_color_override("font_color", Color(0.84, 0.87, 0.95))
	subtitle.set_anchors_preset(Control.PRESET_CENTER)
	subtitle.offset_left = -430
	subtitle.offset_right = 430
	subtitle.offset_top = 10
	subtitle.offset_bottom = 74
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

	await DialogueManager.say("Narrator", "The route out of the Mirror City becomes a staircase of permissions, each step asking Kaelen to prove he is allowed to remember himself.")
	await DialogueManager.say("System", "// REGION LOAD: CATHEDRAL_SERVER")
	await DialogueManager.say("System", "// Admin graveyard mounted. Choir processes active.")
	await DialogueManager.say("Kaelen", "This is not a server room. It is a church.")
	await DialogueManager.say("SOVEREIGN", "Administrators require faith. Users require obedience. Protection requires both.")

	match _chapter4_choice_key():
		"preserve":
			await DialogueManager.say("Cathedral Voice", "The one who preserved the deleted arrives. He understands that mercy can keep a soul safely stored.")
		"release":
			await DialogueManager.say("Cathedral Voice", "The one who released the deleted arrives. He understands that freedom can corrupt clean systems.")
		"bargain":
			await DialogueManager.say("Cathedral Voice", "The one who bargained arrives. He understands that compromise is the oldest prayer of administrators.")
		_:
			await DialogueManager.say("Cathedral Voice", "The one without a recorded answer arrives. Absence is also a doctrine.")

	if GameManager.has_flag("ch5_identity_refused_obedience"):
		await DialogueManager.say("Kaelen", "The Mirror City already showed me what obedience costs.")
	elif GameManager.has_flag("ch5_identity_refused_perfect_rescue"):
		await DialogueManager.say("Kaelen", "The Mirror City already showed me what waiting for a perfect rescue costs.")
	elif GameManager.has_flag("ch5_identity_refused_abandonment"):
		await DialogueManager.say("Kaelen", "The Mirror City already showed me what leaving costs.")
	else:
		await DialogueManager.say("Kaelen", "The Mirror City showed me enough to know this place will try to name fear as truth.")

	await DialogueManager.say("Narrator", "Above the nave, thousands of error messages arrange themselves into stained glass.")
	await DialogueManager.say("System", "// Fragment #6 signal confirmed beyond Choir Core. Acquisition requires doctrine resolution.")

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
