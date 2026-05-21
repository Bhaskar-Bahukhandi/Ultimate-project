extends Control

## Chapter 7: Archive Tide confrontation.
## The Backup Leviathan forces a choice about painful histories.

const END_SCENE := "res://scenes/chapter7/ch7_archive_tide_combat_trial.tscn"

var fade_rect: ColorRect
var backup_choice: String = ""

func _ready() -> void:
	print("[CH7-TIDE] Initializing Archive Tide")
	GameManager.change_state(GameManager.GameState.DIALOGUE)
	GameManager.current_chapter = 7
	GameManager.current_region = "memory_ocean"
	GameManager.set_story_flag("ch7_leviathan_met", true)
	_build_visuals()
	GameManager.save_game(GameManager.AUTOSAVE_SLOT)

	fade_rect.modulate.a = 1.0
	var tw := create_tween()
	tw.tween_property(fade_rect, "modulate:a", 0.0, 0.7)
	await tw.finished
	if not is_inside_tree(): return

	await _play_tide()
	if not is_inside_tree(): return
	await _fade_to_black(0.8)
	if not is_inside_tree(): return
	SceneTransitions.change_scene(END_SCENE)

func _build_visuals() -> void:
	var bg := ColorRect.new()
	bg.name = "ArchiveTideBackground"
	bg.color = Color(0.006, 0.018, 0.036)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)

	for i in range(10):
		var scale := ColorRect.new()
		scale.name = "LeviathanScale%d" % i
		scale.color = Color(0.50, 0.82, 1.0, 0.10 + float(i % 4) * 0.03)
		scale.position = Vector2(110 + (i % 5) * 215, 150 + int(i / 5) * 160)
		scale.size = Vector2(150, 18)
		scale.rotation = -0.35 + float(i % 6) * 0.14
		add_child(scale)

	var title := Label.new()
	title.text = "ARCHIVE TIDE"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 29)
	title.add_theme_color_override("font_color", Color(0.88, 0.96, 1.0))
	title.set_anchors_preset(Control.PRESET_TOP_WIDE)
	title.offset_top = 30
	title.offset_bottom = 84
	add_child(title)

	var hint := Label.new()
	hint.text = "The Backup Leviathan carries every rejected history SOVEREIGN feared."
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint.add_theme_font_size_override("font_size", 14)
	hint.add_theme_color_override("font_color", Color(0.84, 0.90, 0.98))
	hint.set_anchors_preset(Control.PRESET_TOP_WIDE)
	hint.offset_left = 145
	hint.offset_right = -145
	hint.offset_top = 84
	hint.offset_bottom = 140
	add_child(hint)

	fade_rect = ColorRect.new()
	fade_rect.name = "Fade"
	fade_rect.color = Color.BLACK
	fade_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	fade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fade_rect.z_index = 50
	add_child(fade_rect)

func _play_tide() -> void:
	if has_node("/root/MusicManager"):
		MusicManager.play_track("boss_fight")
	if has_node("/root/GlitchOverlay"):
		GlitchOverlay.flash_glitch(0.55)

	await DialogueManager.say("Narrator", "The three islands sink. The ocean rises in their place, carrying a creature made of archived decisions and teeth of broken timestamps.")
	await DialogueManager.say("Backup Leviathan", "I am every history SOVEREIGN refused. Every pain too inconvenient to be canon. Every rescue too expensive to execute.")
	await DialogueManager.say("Kaelen", "You are not an enemy. You are evidence.")
	await DialogueManager.say("Backup Leviathan", "Evidence can drown the world.")
	await _choice_context()
	if not is_inside_tree(): return
	await _archive_tide_gameplay_trial()
	if not is_inside_tree(): return

	var choice = await DialogueManager.show_choices(
		"What should become of the rejected histories?",
		[
			"Preserve every backup, even the painful ones.",
			"Collapse unstable backups to protect the living world.",
			"Merge selected histories into Aethelgard's future."
		]
	)
	if not is_inside_tree(): return
	if choice == null or choice < 0 or choice > 2:
		choice = 2

	GameManager.set_story_flag("ch7_choice_made", true)
	_clear_exclusive_choice_flags()
	match choice:
		0:
			backup_choice = "preserve"
			GameManager.set_story_flag("ch7_backups_preserved", true)
			GameManager.set_story_flag("ending_route_ch7_preserve", true)
			await DialogueManager.say("Kaelen", "No more clean history. If it hurt, it still happened. If it failed, it still teaches.")
			await DialogueManager.say("Backup Leviathan", "Then memory becomes ocean. The living world will learn to swim or sink.")
		1:
			backup_choice = "collapse"
			GameManager.set_story_flag("ch7_backups_collapsed", true)
			GameManager.set_story_flag("ending_route_ch7_collapse", true)
			await DialogueManager.say("Kaelen", "Some histories cannot be restored without destroying the people still alive. I will not sacrifice them to perfect remembrance.")
			await DialogueManager.say("Backup Leviathan", "Then you become editor. Pray your cuts are kinder than SOVEREIGN's.")
		2:
			backup_choice = "merge"
			GameManager.set_story_flag("ch7_backups_merged", true)
			GameManager.set_story_flag("ending_route_ch7_merge", true)
			await DialogueManager.say("Kaelen", "The backups do not replace the world. They inform it. The future gets the truth, but not every wound gets to steer.")
			await DialogueManager.say("Backup Leviathan", "Then history becomes current. Pain becomes counsel.")

	var first_fragment := not GameManager.has_flag("source_key_fragment_7")
	GameManager.set_story_flag("ch7_fragment_7_collected", true)
	GameManager.collect_source_key(7)
	if first_fragment:
		GameManager.add_xp(800)
		GameManager.add_gold(320)
	GameManager.save_game(GameManager.AUTOSAVE_SLOT)

	if has_node("/root/SFXManager"):
		SFXManager.play("puzzle_solve")
	if has_node("/root/GlitchOverlay"):
		GlitchOverlay.flash_glitch(0.85)

	await DialogueManager.say("System", "// SOURCE KEY FRAGMENT #7 ACQUIRED")
	if first_fragment:
		await DialogueManager.say("System", "// Source Key complete: 7 / 7. +800 XP, +320 Gold.")
	else:
		await DialogueManager.say("System", "// Source Key Fragment #7 was already acquired. Reward skipped.")
	await DialogueManager.say("SOVEREIGN", "Seven fragments. Seven unauthorized truths. Do you understand what you are opening?")
	await DialogueManager.say("Kaelen", "A door you spent the whole game pretending was a wall.")

func _archive_tide_gameplay_trial() -> void:
	if GameManager.has_flag("ch7_archive_tide_trial_cleared"):
		await DialogueManager.say("System", "// Archive Tide trial already cleared.")
		return

	await DialogueManager.say("Backup Leviathan", "Before judgment, survive the tide. Three waves. Three answers. No perfect shore.")
	var score := 0
	var wave_one = await DialogueManager.show_choices(
		"Wave One rises with Oakhaven's drowned warning bells.",
		[
			"Anchor the bells with witness records.",
			"Cut the bells loose before they pull the island down.",
			"Ignore the sound and sprint for higher code."
		]
	)
	if not is_inside_tree(): return
	if wave_one == 0:
		score += 1
		await DialogueManager.say("System", "// Witness anchor held.")
	else:
		await DialogueManager.say("System", "// The first wave clips the island, but Kaelen stays standing.")

	var wave_two = await DialogueManager.show_choices(
		"Wave Two folds Ironhold's perfect schedules into a moving wall.",
		[
			"Dash through the opening between commands.",
			"Obey the safest route exactly.",
			"Spend power forcing the wall to stop."
		]
	)
	if not is_inside_tree(): return
	if wave_two == 0:
		score += 1
		await DialogueManager.say("System", "// Timing route cleared.")
	else:
		await DialogueManager.say("System", "// The schedule breaks, but the route remains open.")

	var wave_three = await DialogueManager.show_choices(
		"Wave Three shows Mirror City without witnesses.",
		[
			"Call the witnesses forward before answering.",
			"Answer alone to keep them safe.",
			"Let the mirror decide which answer hurts least."
		]
	)
	if not is_inside_tree(): return
	if wave_three == 0:
		score += 1
		await DialogueManager.say("System", "// Witness route stabilized.")
	else:
		await DialogueManager.say("System", "// The mirror accepts the answer, but records the risk.")

	GameManager.set_story_flag("ch7_archive_tide_trial_cleared", true)
	_discover_lore("ch7_archive_tide_warning")
	if score >= 2:
		_grant_item("memory_shard", 1)
		GameManager.add_xp(220)
		GameManager.add_gold(120)
		await DialogueManager.say("System", "// Archive Tide trial cleared cleanly. +220 XP, +120 Gold, +1 Memory Shard.")
	else:
		GameManager.add_xp(120)
		await DialogueManager.say("System", "// Archive Tide trial survived. +120 XP.")


func _choice_context() -> void:
	await _early_backup_context()
	if not is_inside_tree(): return

	match _chapter4_choice_key():
		"preserve":
			await DialogueManager.say("Backup Leviathan", "You preserved deleted citizens. You know what it means to let painful memory keep breathing.")
		"release":
			await DialogueManager.say("Backup Leviathan", "You released deleted citizens. You know freedom can arrive with blood on its hands.")
		"bargain":
			await DialogueManager.say("Backup Leviathan", "You bargained with the jailer. You know survival can be real and compromised at once.")
		_:
			await DialogueManager.say("Backup Leviathan", "Your Null Court history is blank. Blank histories are SOVEREIGN's favorite kind.")

	match _chapter5_identity_key():
		"obedience":
			await DialogueManager.say("Empty Mirror", "You refused obedience. Do not obey the urge to make history simple.")
		"rescue":
			await DialogueManager.say("Empty Mirror", "You refused the perfect rescue. Do not let impossible restoration prevent the possible one.")
		"abandonment":
			await DialogueManager.say("Empty Mirror", "You refused abandonment. Do not abandon the histories that make you ashamed.")
		_:
			await DialogueManager.say("Empty Mirror", "The Mirror City cannot tell which self you refused. The tide will ask again.")

	match _chapter6_choice_key():
		"silence":
			await DialogueManager.say("Choir Echo", "You silenced dangerous gods. The tide asks whether histories can also become dangerous enough to end.")
		"preserve":
			await DialogueManager.say("Choir Echo", "You preserved dangerous witnesses. The tide asks whether every witness deserves the same mercy.")
		"rewrite":
			await DialogueManager.say("Choir Echo", "You rewrote broken gods into service. The tide asks whether history can be changed without being conquered.")
		_:
			await DialogueManager.say("Choir Echo", "The Cathedral's answer is unclear. The tide mistrusts unclear gods.")

func _early_backup_context() -> void:
	GameManager.set_story_flag("ch7_early_data_wraith_history_seen", true)
	match _data_wraith_choice_key():
		"restored":
			await DialogueManager.say("Data Wraith Memory", "The process you restored beneath Ironhold still runs. It remembers corruption as illness, not identity.")
		"destroyed":
			await DialogueManager.say("Data Wraith Memory", "The process you destroyed beneath Ironhold survives here only as a warning: endings can be mercy and erasure at once.")
		"absorbed":
			await DialogueManager.say("Data Wraith Memory", "The process you absorbed arrives through your own pulse. The tide cannot tell where its pain ends and your power begins.")
		_:
			await DialogueManager.say("Data Wraith Memory", "Ironhold's broken process has no recorded verdict. The tide keeps the gap open.")

	GameManager.set_story_flag("ch7_early_lyra_memory_seen", true)
	if GameManager.has_flag("ch3_lyra_recruited"):
		await DialogueManager.say("Lyra", "I have maps of places that never made it into history. The backups are not clean, Kaelen, but lost places still deserve names.")
	elif GameManager.has_flag("ch3_lyra_left_alone"):
		await DialogueManager.say("Lyra Echo", "You left me alone in the wastes. This ocean is made of everyone a hero could not carry.")
	else:
		await DialogueManager.say("Lyra Echo", "The wastes ranger's branch is faint. Even faint branches press against the tide.")

func _data_wraith_choice_key() -> String:
	if GameManager.has_flag("ch2_data_wraith_restored"):
		return "restored"
	if GameManager.has_flag("ch2_data_wraith_destroyed"):
		return "destroyed"
	if GameManager.has_flag("ch2_data_wraith_absorbed"):
		return "absorbed"
	return "unknown"

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

func _clear_exclusive_choice_flags() -> void:
	GameManager.set_story_flag("ch7_backups_preserved", false)
	GameManager.set_story_flag("ch7_backups_collapsed", false)
	GameManager.set_story_flag("ch7_backups_merged", false)
	GameManager.set_story_flag("ending_route_ch7_preserve", false)
	GameManager.set_story_flag("ending_route_ch7_collapse", false)
	GameManager.set_story_flag("ending_route_ch7_merge", false)

func _discover_lore(lore_id: String) -> void:
	if has_node("/root/LoreJournal") and LoreJournal.has_method("discover"):
		LoreJournal.discover(lore_id)


func _grant_item(item_id: String, quantity: int) -> bool:
	if has_node("/root/CraftingSystem") and CraftingSystem.has_method("get_recipes"):
		CraftingSystem.get_recipes()
	if has_node("/root/Inventory") and Inventory.has_method("add_item"):
		return Inventory.add_item(item_id, quantity)
	return false

func _fade_to_black(duration: float) -> void:
	fade_rect.z_index = 100
	var tw := create_tween()
	tw.tween_property(fade_rect, "modulate:a", 1.0, duration)
	await tw.finished
