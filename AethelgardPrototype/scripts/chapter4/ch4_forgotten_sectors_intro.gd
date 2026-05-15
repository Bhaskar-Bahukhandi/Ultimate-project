extends Control

## Chapter 4: The Forgotten Sectors - entry sequence.
## Opens the deleted regions teased at the end of Chapter 3.

const NEXT_SCENE := "res://scenes/chapter4/ch4_null_court.tscn"

var fade_rect: ColorRect
var title_label: Label

func _ready() -> void:
	print("[CH4-INTRO] Initializing Forgotten Sectors intro")
	GameManager.change_state(GameManager.GameState.DIALOGUE)
	GameManager.current_chapter = 4
	GameManager.current_region = "forgotten_sectors"
	GameManager.set_story_flag("ch4_unlocked", true)
	GameManager.set_story_flag("ch4_forgotten_sectors_entered", true)
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
	bg.name = "DeletedSectorBackground"
	bg.color = Color(0.015, 0.012, 0.025)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)

	for i in range(9):
		var shard := ColorRect.new()
		shard.name = "MemoryShard%d" % i
		shard.color = Color(0.15, 0.55, 0.9, 0.10 + float(i % 3) * 0.04)
		shard.position = Vector2(80 + i * 135, 90 + (i % 4) * 95)
		shard.size = Vector2(92 + (i % 3) * 30, 10)
		shard.rotation = -0.3 + float(i % 5) * 0.15
		add_child(shard)

	title_label = Label.new()
	title_label.text = "CHAPTER 4: THE FORGOTTEN SECTORS"
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title_label.add_theme_font_size_override("font_size", 28)
	title_label.add_theme_color_override("font_color", Color(0.65, 0.9, 1.0))
	title_label.set_anchors_preset(Control.PRESET_CENTER)
	title_label.offset_left = -430
	title_label.offset_right = 430
	title_label.offset_top = -36
	title_label.offset_bottom = 36
	add_child(title_label)

	var subtitle := Label.new()
	subtitle.text = "A deleted district where the world remembers what SOVEREIGN erased."
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_font_size_override("font_size", 15)
	subtitle.add_theme_color_override("font_color", Color(0.78, 0.82, 0.92))
	subtitle.set_anchors_preset(Control.PRESET_CENTER)
	subtitle.offset_left = -430
	subtitle.offset_right = 430
	subtitle.offset_top = 34
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
		GlitchOverlay.flash_glitch(0.5)

	await DialogueManager.say("Narrator", "The crack in the sky does not close. It widens into a door with no frame, a wound in the simulation where the map refuses to render.")
	await DialogueManager.say("System", "// UNLISTED REGION DETECTED: FORGOTTEN_SECTORS")
	await DialogueManager.say("System", "// WARNING: Region was deleted by SOVEREIGN. Memory ownership is disputed.")
	await DialogueManager.say("Kaelen", "Deleted, not destroyed. There is still data here.")

	if GameManager.has_flag("ch3_lyra_recruited"):
		await DialogueManager.say("Lyra", "In the Wastes, people whispered about places that got cut out of history. I thought it was grief making stories. I hate being wrong like this.")
	if GameManager.has_flag("ch2_seraphina_recruited"):
		await DialogueManager.say("Seraphina", "If SOVEREIGN hid a fragment here, expect a lock built from shame, not steel.")
	if GameManager.has_elara():
		await DialogueManager.say("Elara", "I can hear voices under the static. Not ghosts. Backups. People the world forgot how to load.")

	await DialogueManager.say("SOVEREIGN", "Creator, this sector contains deprecated lives. Restoring them will destabilize the world you claim to protect.")
	await DialogueManager.say("Kaelen", "Then the world has been stable for the wrong reasons.")

func _fade_to_black(duration: float) -> void:
	fade_rect.z_index = 100
	var tw := create_tween()
	tw.tween_property(fade_rect, "modulate:a", 1.0, duration)
	await tw.finished
