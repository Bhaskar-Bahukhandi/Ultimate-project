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
	await _memory_island_interactions()
	if not is_inside_tree(): return
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

func _memory_island_interactions() -> void:
	await DialogueManager.say("System", "// Three unstable backup islands are reachable. Salvage is possible, but every island rewrites the safest path as the only path.")
	if not GameManager.has_flag("ch7_backup_logs_found"):
		GameManager.set_story_flag("ch7_backup_logs_found", true)
		_discover_lore("ch7_backup_logs")
		_grant_item("memory_shard", 1)
		await DialogueManager.say("Kaelen", "These logs are not side notes. They are the parts of history SOVEREIGN could not make useful.")
		await DialogueManager.say("System", "// Optional discovery: Deep Backup Logs. +1 Memory Shard.")

	await _backup_history_hazard()
	if not is_inside_tree(): return

	if not GameManager.has_flag("ch7_backup_salvage_claimed"):
		GameManager.set_story_flag("ch7_backup_salvage_claimed", true)
		_grant_item("data_ore", 1)
		_grant_item("glitch_herb", 1)
		_discover_lore("memory_ocean_salvage_manifest")
		if has_node("/root/SideQuestManager"):
			SideQuestManager.complete_optional_objective("memory_ocean_backup_salvage")
		GameManager.add_gold(90)
		await DialogueManager.say("System", "// Backup salvage secured: +1 Data Ore, +1 Glitch Herb, +90 Gold.")


func _backup_history_hazard() -> void:
	if GameManager.has_flag("ch7_memory_island_hazard_cleared"):
		await DialogueManager.say("System", "// Memory island hazard already stabilized.")
		return

	var choice = await DialogueManager.show_choices(
		"The nearest island fractures into three moving timestamps. How should Kaelen cross?",
		[
			"Spend a Memory Shard to anchor the safest timestamp.",
			"Dash between stable frames and accept the risk.",
			"Follow Lyra's old storm-map logic through the broken route."
		]
	)
	if not is_inside_tree(): return
	if choice == null or choice < 0 or choice > 2:
		choice = 1

	GameManager.set_story_flag("ch7_memory_island_hazard_cleared", true)
	match choice:
		0:
			if _remove_item("memory_shard", 1):
				GameManager.add_xp(160)
				await DialogueManager.say("System", "// Memory anchor held. +160 XP.")
			else:
				GameManager.add_xp(80)
				await DialogueManager.say("System", "// No Memory Shard available. Kaelen crossed on unstable timing. +80 XP.")
		1:
			GameManager.add_xp(120)
			await DialogueManager.say("Kaelen", "The safe path kept moving. So did I.")
			await DialogueManager.say("System", "// Traversal hazard cleared. +120 XP.")
		2:
			if GameManager.has_flag("ch3_lyra_recruited"):
				GameManager.add_xp(150)
				_grant_item("glitch_herb", 1)
				await DialogueManager.say("Lyra", "Storms and backups both lie about where the ground ends. Step where the lie hesitates.")
				await DialogueManager.say("System", "// Lyra's route read the hazard cleanly. +150 XP, +1 Glitch Herb.")
			else:
				GameManager.add_xp(95)
				await DialogueManager.say("Lyra Echo", "Even without the ranger beside you, her old marks keep one island from sinking.")
				await DialogueManager.say("System", "// Storm-map logic partially recovered. +95 XP.")


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

func _discover_lore(lore_id: String) -> void:
	if has_node("/root/LoreJournal") and LoreJournal.has_method("discover"):
		LoreJournal.discover(lore_id)


func _grant_item(item_id: String, quantity: int) -> bool:
	if has_node("/root/CraftingSystem") and CraftingSystem.has_method("get_recipes"):
		CraftingSystem.get_recipes()
	if has_node("/root/Inventory") and Inventory.has_method("add_item"):
		return Inventory.add_item(item_id, quantity)
	return false


func _remove_item(item_id: String, quantity: int) -> bool:
	if has_node("/root/CraftingSystem") and CraftingSystem.has_method("get_recipes"):
		CraftingSystem.get_recipes()
	if has_node("/root/Inventory") and Inventory.has_method("remove_item") and Inventory.has_method("has_item"):
		if Inventory.has_item(item_id, quantity):
			return Inventory.remove_item(item_id, quantity)
	return false

func _fade_to_black(duration: float) -> void:
	fade_rect.z_index = 100
	var tw := create_tween()
	tw.tween_property(fade_rect, "modulate:a", 1.0, duration)
	await tw.finished
