extends Control

## Chapter 7: Memory Ocean hub.
## Three rejected histories reflect choices from Chapters 4, 5, and 6.

const NEXT_SCENE := "res://scenes/chapter7/ch7_archive_tide.tscn"

var fade_rect: ColorRect

func _ready() -> void:
	print("[CH7-HUB] Initializing Memory Ocean hub")
	GameManager.change_state(GameManager.GameState.DIALOGUE)
	GameManager.current_chapter = 7
	GameManager.current_region = "memory_ocean"
	GameManager.set_story_flag("ch7_memory_ocean_entered", true)
	_build_visuals()
	GameManager.save_game(GameManager.AUTOSAVE_SLOT)

	fade_rect.modulate.a = 1.0
	var tw := create_tween()
	tw.tween_property(fade_rect, "modulate:a", 0.0, 0.7)
	await tw.finished
	if not is_inside_tree(): return

	await _play_hub()
	if not is_inside_tree(): return
	await _fade_to_black(0.8)
	if not is_inside_tree(): return
	SceneTransitions.change_scene(NEXT_SCENE)

func _build_visuals() -> void:
	var bg := ColorRect.new()
	bg.name = "MemoryOceanHubBackground"
	bg.color = Color(0.008, 0.024, 0.045)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)

	for i in range(3):
		var island := ColorRect.new()
		island.name = "BackupIsland%d" % i
		island.color = Color(0.35, 0.74, 1.0, 0.12 + float(i) * 0.035)
		island.position = Vector2(155 + i * 340, 210 + (i % 2) * 46)
		island.size = Vector2(250, 135)
		island.rotation = -0.06 + float(i) * 0.05
		add_child(island)

	var tide := ColorRect.new()
	tide.name = "ArchiveTideLine"
	tide.color = Color(0.70, 0.90, 1.0, 0.18)
	tide.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	tide.offset_top = -180
	tide.offset_bottom = -172
	tide.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(tide)

	var title := Label.new()
	title.text = "MEMORY OCEAN"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 28)
	title.add_theme_color_override("font_color", Color(0.82, 0.94, 1.0))
	title.set_anchors_preset(Control.PRESET_TOP_WIDE)
	title.offset_top = 28
	title.offset_bottom = 78
	add_child(title)

	var hint := Label.new()
	hint.text = "Backup islands replay histories SOVEREIGN refused to execute."
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint.add_theme_font_size_override("font_size", 14)
	hint.add_theme_color_override("font_color", Color(0.84, 0.89, 0.97))
	hint.set_anchors_preset(Control.PRESET_TOP_WIDE)
	hint.offset_left = 140
	hint.offset_right = -140
	hint.offset_top = 78
	hint.offset_bottom = 132
	add_child(hint)

	fade_rect = ColorRect.new()
	fade_rect.name = "Fade"
	fade_rect.color = Color.BLACK
	fade_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	fade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fade_rect.z_index = 50
	add_child(fade_rect)

func _play_hub() -> void:
	if has_node("/root/MusicManager"):
		MusicManager.play_track("tension")
	if has_node("/root/GlitchOverlay"):
		GlitchOverlay.flash_glitch(0.35)

	await DialogueManager.say("Narrator", "The Memory Ocean does not ask Kaelen where he wants to go. It shows him where other Kaelens failed.")
	await _oakhaven_backup()
	if not is_inside_tree(): return
	await _ironhold_backup()
	if not is_inside_tree(): return
	await _mirror_city_backup()
	if not is_inside_tree(): return

	var first_clear := not GameManager.has_flag("ch7_all_backups_seen")
	GameManager.set_story_flag("ch7_all_backups_seen", true)
	if first_clear:
		GameManager.add_xp(280)
		GameManager.add_gold(100)
	GameManager.save_game(GameManager.AUTOSAVE_SLOT)

	await DialogueManager.say("System", "// BACKUP HISTORIES INDEXED")
	if first_clear:
		await DialogueManager.say("System", "// Archive Tide access granted. +280 XP, +100 Gold.")
	else:
		await DialogueManager.say("System", "// Archive Tide access already granted.")

func _oakhaven_backup() -> void:
	GameManager.set_story_flag("ch7_backup_oakhaven_seen", true)
	await DialogueManager.say("Backup: Oakhaven Saved Too Late", "The village survives in this history. The crater does not. The people rebuild around a hole that keeps asking for names.")
	match _chapter4_choice_key():
		"preserve":
			await DialogueManager.say("Memory Villager", "You would preserve us, even when the pain keeps running. Is a saved wound still a saved life?")
		"release":
			await DialogueManager.say("Memory Villager", "You would release us quickly. But some histories need someone to stand nearby when the door opens.")
		"bargain":
			await DialogueManager.say("Memory Villager", "You would bargain for us. We learned what it costs when safety arrives with terms.")
		_:
			await DialogueManager.say("Memory Villager", "No record says what you do with people history hurts.")
	await DialogueManager.say("Kaelen", "A clean timeline can still leave dirty grief.")

func _ironhold_backup() -> void:
	GameManager.set_story_flag("ch7_backup_ironhold_seen", true)
	await DialogueManager.say("Backup: Ironhold Without Freedom", "Ironhold thrives here. Markets run perfectly. No one starves. No one votes. No one leaves.")
	match _chapter6_choice_key():
		"silence":
			await DialogueManager.say("Ironhold Clerk", "You silenced the Choir. Would you silence this city if freedom could only return through collapse?")
		"preserve":
			await DialogueManager.say("Ironhold Clerk", "You preserved the Choir as warning. Would you preserve this city as evidence, even while it keeps obeying?")
		"rewrite":
			await DialogueManager.say("Ironhold Clerk", "You rewrote the Choir. Would you rewrite Ironhold too, or admit some citizens may refuse your improved future?")
		_:
			await DialogueManager.say("Ironhold Clerk", "Order feeds us. Freedom is a rumor with empty hands.")
	await DialogueManager.say("Kaelen", "A world can function and still fail everyone inside it.")

func _mirror_city_backup() -> void:
	GameManager.set_story_flag("ch7_backup_mirror_city_seen", true)
	await DialogueManager.say("Backup: Mirror City Without Witnesses", "The city reflects every choice, but nobody remains to answer back. Kaelen won every argument because he was the only voice left.")
	match _chapter5_identity_key():
		"obedience":
			await DialogueManager.say("Empty Mirror", "You refused obedience. Good. But defiance without witnesses can become a private throne.")
		"rescue":
			await DialogueManager.say("Empty Mirror", "You refused the perfect rescue. Good. But urgency without witnesses can become damage called progress.")
		"abandonment":
			await DialogueManager.say("Empty Mirror", "You refused abandonment. Good. But staying without witnesses can become ownership.")
		_:
			await DialogueManager.say("Empty Mirror", "No witness names the self you fear most. The mirror cannot cross-examine silence.")
	await DialogueManager.say("Kaelen", "If I am the only person allowed to interpret history, I become SOVEREIGN with a different voice.")

func _chapter4_choice_key() -> String:
	if GameManager.has_flag("ch4_choice_preserve_deleted"):
		return "preserve"
	if GameManager.has_flag("ch4_choice_release_deleted"):
		return "release"
	if GameManager.has_flag("ch4_choice_bargain_deleted"):
		return "bargain"
	return "unknown"

func _chapter5_identity_key() -> String:
	if GameManager.has_flag("ch5_identity_refused_obedience"):
		return "obedience"
	if GameManager.has_flag("ch5_identity_refused_perfect_rescue"):
		return "rescue"
	if GameManager.has_flag("ch5_identity_refused_abandonment"):
		return "abandonment"
	return "unknown"

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
