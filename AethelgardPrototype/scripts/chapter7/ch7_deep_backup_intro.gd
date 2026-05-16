extends Control

## Chapter 7: The Deep Backup - descent into the Memory Ocean.

const NEXT_SCENE := "res://scenes/chapter7/ch7_memory_ocean_hub.tscn"

var fade_rect: ColorRect

func _ready() -> void:
	print("[CH7-INTRO] Initializing Deep Backup intro")
	GameManager.change_state(GameManager.GameState.DIALOGUE)
	GameManager.current_chapter = 7
	GameManager.current_region = "memory_ocean"
	GameManager.set_story_flag("ch7_unlocked", true)
	GameManager.set_story_flag("ch7_deep_backup_entered", true)
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
	bg.name = "MemoryOceanBackground"
	bg.color = Color(0.010, 0.028, 0.050)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)

	for i in range(12):
		var wave := ColorRect.new()
		wave.name = "BackupWave%d" % i
		wave.color = Color(0.30, 0.68, 1.0, 0.08 + float(i % 4) * 0.025)
		wave.position = Vector2(40 + (i % 6) * 210, 120 + int(i / 6) * 180)
		wave.size = Vector2(150, 8)
		wave.rotation = -0.18 + float(i % 5) * 0.09
		add_child(wave)

	var title := Label.new()
	title.text = "CHAPTER 7: THE DEEP BACKUP"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 30)
	title.add_theme_color_override("font_color", Color(0.78, 0.91, 1.0))
	title.set_anchors_preset(Control.PRESET_CENTER)
	title.offset_left = -500
	title.offset_right = 500
	title.offset_top = -62
	title.offset_bottom = -4
	add_child(title)

	var subtitle := Label.new()
	subtitle.text = "Rejected timelines surface like islands in a sea of erased history."
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	subtitle.add_theme_font_size_override("font_size", 15)
	subtitle.add_theme_color_override("font_color", Color(0.84, 0.90, 0.98))
	subtitle.set_anchors_preset(Control.PRESET_CENTER)
	subtitle.offset_left = -440
	subtitle.offset_right = 440
	subtitle.offset_top = 10
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
		GlitchOverlay.flash_glitch(0.45)

	await DialogueManager.say("Narrator", "Below the Cathedral Server is an ocean with no water. It is made of saves that were never allowed to load.")
	await DialogueManager.say("System", "// REGION LOAD: DEEP_BACKUP")
	await DialogueManager.say("System", "// WARNING: rejected histories may contest current reality.")
	await DialogueManager.say("Kaelen", "SOVEREIGN did not delete them. It buried them.")
	await DialogueManager.say("SOVEREIGN", "A failed history can still infect a stable one.")

	match _chapter6_choice_key():
		"silence":
			await DialogueManager.say("Memory Tide", "The Choir went quiet. The backups wonder whether you will silence them too.")
		"preserve":
			await DialogueManager.say("Memory Tide", "The Choir became witnesses. The backups rise because witnesses teach buried things to speak.")
		"rewrite":
			await DialogueManager.say("Memory Tide", "The Choir learned service. The backups ask whether histories can be rewritten without becoming lies.")
		_:
			await DialogueManager.say("Memory Tide", "The Cathedral left no clear doctrine. The backups will test the blank space.")

	await DialogueManager.say("Narrator", "Three islands breach the dark: Oakhaven saved too late, Ironhold without freedom, and the Mirror City without witnesses.")
	await DialogueManager.say("System", "// Source Key Fragment #7 signal detected under Archive Tide.")

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
