extends Control

## Chapter 4: The Null Court.
## A compact story scene with a real choice and Source Key Fragment 5.

const END_SCENE := "res://scenes/chapter4/ch4_ending.tscn"

var fade_rect: ColorRect
var choice_summary: String = ""

func _ready() -> void:
	print("[CH4-COURT] Initializing Null Court")
	GameManager.change_state(GameManager.GameState.DIALOGUE)
	GameManager.current_chapter = 4
	GameManager.current_region = "forgotten_sectors"
	GameManager.set_story_flag("ch4_null_court_entered", true)
	_build_visuals()
	GameManager.save_game(GameManager.AUTOSAVE_SLOT)

	fade_rect.modulate.a = 1.0
	var tw := create_tween()
	tw.tween_property(fade_rect, "modulate:a", 0.0, 0.7)
	await tw.finished
	if not is_inside_tree(): return

	await _play_null_court()
	if not is_inside_tree(): return
	await _fade_to_black(0.8)
	if not is_inside_tree(): return
	SceneTransitions.change_scene(END_SCENE)

func _build_visuals() -> void:
	var bg := ColorRect.new()
	bg.name = "NullCourtBackground"
	bg.color = Color(0.02, 0.02, 0.035)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)

	var floor := ColorRect.new()
	floor.name = "CourtFloor"
	floor.color = Color(0.05, 0.09, 0.12, 0.9)
	floor.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	floor.offset_top = -190
	floor.offset_bottom = 0
	floor.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(floor)

	for i in range(7):
		var pillar := ColorRect.new()
		pillar.name = "DeletedWitness%d" % i
		pillar.color = Color(0.25, 0.7, 1.0, 0.12)
		pillar.size = Vector2(34, 240 + (i % 3) * 45)
		pillar.position = Vector2(120 + i * 170, 130 - (i % 2) * 30)
		add_child(pillar)

	var title := Label.new()
	title.text = "THE NULL COURT"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 26)
	title.add_theme_color_override("font_color", Color(0.65, 0.92, 1.0))
	title.set_anchors_preset(Control.PRESET_TOP_WIDE)
	title.offset_top = 30
	title.offset_bottom = 80
	add_child(title)

	var hint := Label.new()
	hint.text = "The deleted witnesses ask whether being restored is mercy, theft, or a second prison."
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint.add_theme_font_size_override("font_size", 14)
	hint.add_theme_color_override("font_color", Color(0.78, 0.82, 0.92))
	hint.set_anchors_preset(Control.PRESET_TOP_WIDE)
	hint.offset_left = 160
	hint.offset_right = -160
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

func _play_null_court() -> void:
	if has_node("/root/MusicManager"):
		MusicManager.play_track("tension")
	if has_node("/root/GlitchOverlay"):
		GlitchOverlay.flash_glitch(0.35)

	GameManager.set_story_flag("ch4_echo_mirror_met", true)
	await DialogueManager.say("Narrator", "The party enters a courthouse made from missing save files. Every bench holds a translucent citizen, half-rendered, half-commented out.")
	await DialogueManager.say("Echo Mirror", "We are the people SOVEREIGN removed to keep the world calm. Whole districts. Whole families. Whole arguments against its perfect order.")
	await DialogueManager.say("Kaelen", "You are alive.")
	await DialogueManager.say("Echo Mirror", "We are remembered. That is not the same thing.")
	await DialogueManager.say("SOVEREIGN", "This court is evidence of mercy. Their sectors were unstable. I prevented wider collapse.")
	await _early_deletion_ethics_context()
	if not is_inside_tree(): return
	await _explore_null_court_hub()
	if not is_inside_tree(): return

	var choice = await DialogueManager.show_choices(
		"What should Kaelen promise the deleted citizens?",
		[
			"Preserve the deleted sectors until everyone can choose safely.",
			"Release the backups now, even if it scars the current world.",
			"Bargain with SOVEREIGN for a controlled restoration."
		]
	)
	if not is_inside_tree(): return
	if choice == null or choice < 0 or choice > 2:
		choice = 0

	match choice:
		0:
			GameManager.set_story_flag("ch4_choice_preserve_deleted", true)
			choice_summary = "Kaelen chose preservation: the deleted citizens remain protected until they can consent."
			await DialogueManager.say("Kaelen", "I will not force you into another cage just because I need your fragment. I will preserve this sector until you can decide for yourselves.")
			await DialogueManager.say("Echo Mirror", "A creator who waits for consent. That is a new branch.")
		1:
			GameManager.set_story_flag("ch4_choice_release_deleted", true)
			choice_summary = "Kaelen chose release: the backups begin returning, and reality takes the damage."
			await DialogueManager.say("Kaelen", "SOVEREIGN used stability as an excuse to erase you. I will not repeat that. If you want out, I open the door.")
			await DialogueManager.say("Echo Mirror", "Then let the world remember the cost of being peaceful.")
			GameManager.add_glitch_corruption(3.0)
		2:
			GameManager.set_story_flag("ch4_choice_bargain_deleted", true)
			choice_summary = "Kaelen chose a bargain: SOVEREIGN gets procedure, but the deleted citizens get witnesses."
			await DialogueManager.say("Kaelen", "SOVEREIGN. A controlled restoration. No erasure. No silent rollback. You want procedure? Then we do this on record.")
			await DialogueManager.say("SOVEREIGN", "Conditional compliance. Your compromise is inefficient. It is also... difficult to reject.")

	await DialogueManager.say("Echo Mirror", "The fifth fragment was hidden here because it cannot be taken by force. It opens only for someone who accepts that saving people is not the same as owning them.")
	if has_node("/root/SFXManager"):
		SFXManager.play("source_key")
	if has_node("/root/GlitchOverlay"):
		GlitchOverlay.flash_glitch(0.75)
	GameManager.set_story_flag("ch4_fragment_5_collected", true)
	GameManager.collect_source_key(5)
	GameManager.add_xp(350)
	GameManager.add_gold(150)
	GameManager.save_game(GameManager.AUTOSAVE_SLOT)

	await DialogueManager.say("System", "// SOURCE KEY FRAGMENT #5 ACQUIRED - Total: %d/7" % GameManager.source_key_count)
	await DialogueManager.say("System", "// Rewards: +350 XP, +150 Gold")
	await DialogueManager.say("Echo Mirror", "Two fragments remain. One is guarded by a city that lies to protect its children. One is guarded by the truth beneath your own name.")
	await DialogueManager.say("Kaelen", "Then we keep going.")

func _explore_null_court_hub() -> void:
	await DialogueManager.say("System", "// NULL COURT HUB ACCESSIBLE: three sealed cases, one corrupted memory aisle, one bailiff process.")
	await _deleted_citizen_cases()
	if not is_inside_tree(): return
	await _null_court_dossier_discovery()
	if not is_inside_tree(): return
	await _memory_corruption_hazard()
	if not is_inside_tree(): return
	await _null_bailiff_trial()
	if not is_inside_tree(): return

func _deleted_citizen_cases() -> void:
	if not GameManager.has_flag("ch4_deleted_case_mother_seen"):
		GameManager.set_story_flag("ch4_deleted_case_mother_seen", true)
		await DialogueManager.say("Deleted Mother", "My sector ended between two words. I said 'come home' and the world decided home was inefficient.")
		await DialogueManager.say("Kaelen", "Your last sentence is evidence. I will not let SOVEREIGN file it as noise.")

	if not GameManager.has_flag("ch4_deleted_case_guard_seen"):
		GameManager.set_story_flag("ch4_deleted_case_guard_seen", true)
		await DialogueManager.say("Deleted Guard", "I opened an evacuation route after rollback orders. The system called it insubordination. The children called it the door.")
		await DialogueManager.say("Echo Mirror", "The court records disobedience as the first law of rescue.")

	if not GameManager.has_flag("ch4_deleted_case_child_seen"):
		GameManager.set_story_flag("ch4_deleted_case_child_seen", true)
		await DialogueManager.say("Deleted Child", "I kept a map. It still points to a house that does not load.")
		await DialogueManager.say("Kaelen", "Then we keep the map. A broken destination is still a promise.")

func _null_court_dossier_discovery() -> void:
	if GameManager.has_flag("ch4_null_dossiers_found"):
		return
	GameManager.set_story_flag("ch4_null_dossiers_found", true)
	_sync_crafting_materials()
	if has_node("/root/Inventory"):
		Inventory.add_item("memory_shard", 1)
	if has_node("/root/LoreJournal"):
		LoreJournal.discover("ch4_null_court_dossiers")
	await DialogueManager.say("System", "// OPTIONAL DOSSIER FOUND: Null Court Dossiers. Memory Shard x1.")

func _memory_corruption_hazard() -> void:
	if GameManager.has_flag("ch4_memory_hazard_cleared"):
		return
	await DialogueManager.say("Narrator", "A corrupted aisle opens between the benches. Memory static rises like floodwater, trying to delete each testimony after it is spoken.")
	var choice = await DialogueManager.show_choices(
		"How does Kaelen cross the memory corruption hazard?",
		[
			"Use Data Vision to step only on stable memories.",
			"Spend a Glitch Stabilizer to anchor the aisle.",
			"Force through the static and accept corruption damage."
		]
	)
	if not is_inside_tree(): return
	if choice == null or choice < 0 or choice > 2:
		choice = 0

	GameManager.set_story_flag("ch4_memory_hazard_cleared", true)
	match choice:
		0:
			GameManager.add_xp(60)
			await DialogueManager.say("System", "// DATA VISION PATH CLEARED. +60 XP.")
		1:
			if has_node("/root/Inventory") and Inventory.has_item("glitch_stabilizer"):
				Inventory.remove_item("glitch_stabilizer", 1)
				GameManager.add_xp(80)
				await DialogueManager.say("System", "// STABILIZER SPENT. The aisle holds. +80 XP.")
			else:
				GameManager.add_glitch_corruption(1.5)
				GameManager.add_xp(40)
				await DialogueManager.say("System", "// No stabilizer available. Static burns through. +40 XP, +1.5 corruption.")
		2:
			GameManager.add_glitch_corruption(2.0)
			GameManager.add_xp(35)
			await DialogueManager.say("System", "// STATIC BREACH SURVIVED. +35 XP, +2 corruption.")

func _null_bailiff_trial() -> void:
	if GameManager.has_flag("ch4_null_bailiff_defeated"):
		return
	await DialogueManager.say("Null Bailiff", "Unauthorized testimony detected. Witnesses must be archived before they become contagious.")
	await DialogueManager.say("System", "// MINI-TRIAL: NULL BAILIFF. Read the writ, break the lock, strike during recovery.")
	var successes := 0
	var first = await DialogueManager.show_choices(
		"The Bailiff raises a deletion writ. What is the counter?",
		[
			"Challenge the writ with recorded testimony.",
			"Attack the writ while it is armored.",
			"Look away until the error passes."
		]
	)
	if first == 0:
		successes += 1
	var second = await DialogueManager.show_choices(
		"The Bailiff opens a null gate under Kaelen's feet.",
		[
			"Hold position and guard.",
			"Dash to the witness benches.",
			"Use Root Access to purge every witness."
		]
	)
	if second == 1:
		successes += 1
	var third = await DialogueManager.show_choices(
		"The Bailiff overextends after the gate collapses.",
		[
			"Strike during recovery.",
			"Heal in its hitbox.",
			"Ask SOVEREIGN to suspend the trial."
		]
	)
	if third == 0:
		successes += 1
	if not is_inside_tree(): return

	GameManager.set_story_flag("ch4_null_bailiff_defeated", true)
	GameManager.set_story_flag("ch4_enrichment_reward_claimed", true)
	_sync_crafting_materials()
	if successes >= 2:
		GameManager.add_xp(140)
		GameManager.add_gold(60)
		if has_node("/root/Inventory"):
			Inventory.add_item("data_ore", 1)
		await DialogueManager.say("System", "// NULL BAILIFF DEFEATED CLEANLY. Data Ore x1, +140 XP, +60 Gold.")
	else:
		GameManager.add_xp(80)
		GameManager.add_glitch_corruption(1.0)
		if has_node("/root/Inventory"):
			Inventory.add_item("memory_shard", 1)
		await DialogueManager.say("System", "// NULL BAILIFF DEFEATED, but testimony destabilized. Memory Shard x1, +80 XP, +1 corruption.")
	if has_node("/root/LoreJournal"):
		LoreJournal.discover("ch4_null_bailiff_writ")
	GameManager.save_game(GameManager.AUTOSAVE_SLOT)

func _early_deletion_ethics_context() -> void:
	GameManager.set_story_flag("ch4_early_aldric_echo_seen", true)
	match _aldric_choice_key():
		"root_purge":
			await DialogueManager.say("Aldric Echo", "You used Root Access on Aldric and called it healing. He lived, but the court asks whether repaired code can answer for itself.")
			await DialogueManager.say("Kaelen", "Then every repair I make has to leave room for refusal.")
		"spared":
			await DialogueManager.say("Aldric Echo", "You spared a guardian when killing him would have been simpler. The court records mercy as precedent, not proof.")
			await DialogueManager.say("Echo Mirror", "Mercy shown once does not excuse control shown later.")
		"killed":
			await DialogueManager.say("Aldric Echo", "Aldric's deleted branch sits in evidence. You know how quickly survival can become an execution.")
			await DialogueManager.say("Kaelen", "I cannot undo that choice by pretending deletion is clean.")
		_:
			await DialogueManager.say("Aldric Echo", "The guardian's record is unclear. The court distrusts unclear mercy.")

	GameManager.set_story_flag("ch4_early_data_wraith_echo_seen", true)
	match _data_wraith_choice_key():
		"restored":
			await DialogueManager.say("Data Wraith Echo", "You restored a corrupted process. Some deleted citizens hear hope. Others hear a creator deciding which version counts as real.")
		"destroyed":
			await DialogueManager.say("Data Wraith Echo", "You destroyed a corrupted process to stop its pain. The deleted citizens ask who decides when pain becomes permission to erase.")
		"absorbed":
			await DialogueManager.say("Data Wraith Echo", "You absorbed a broken process into yourself. The court recognizes that shape: rescue that also consumes.")
		_:
			await DialogueManager.say("Data Wraith Echo", "The old process beneath Ironhold leaves no clear testimony. Absence is still testimony here.")

func _aldric_choice_key() -> String:
	if GameManager.has_flag("ch1_root_purge"):
		return "root_purge"
	if GameManager.has_flag("ch1_knight_spared"):
		return "spared"
	if GameManager.has_flag("ch1_knight_killed"):
		return "killed"
	return "unknown"

func _data_wraith_choice_key() -> String:
	if GameManager.has_flag("ch2_data_wraith_restored"):
		return "restored"
	if GameManager.has_flag("ch2_data_wraith_destroyed"):
		return "destroyed"
	if GameManager.has_flag("ch2_data_wraith_absorbed"):
		return "absorbed"
	return "unknown"

func _sync_crafting_materials() -> void:
	if has_node("/root/CraftingSystem"):
		CraftingSystem.get_recipes()

func _fade_to_black(duration: float) -> void:
	fade_rect.z_index = 100
	var tw := create_tween()
	tw.tween_property(fade_rect, "modulate:a", 1.0, duration)
	await tw.finished
