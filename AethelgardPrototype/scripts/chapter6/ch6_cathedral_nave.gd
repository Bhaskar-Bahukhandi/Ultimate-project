extends Control

## Chapter 6: Cathedral Nave.
## Three failed administrator doctrines speak before the Choir Core opens.

const NEXT_SCENE := "res://scenes/chapter6/ch6_choir_core.tscn"

var fade_rect: ColorRect

func _ready() -> void:
	print("[CH6-NAVE] Initializing Cathedral Nave")
	GameManager.change_state(GameManager.GameState.DIALOGUE)
	GameManager.current_chapter = 6
	GameManager.current_region = "cathedral_server"
	GameManager.set_story_flag("ch6_nave_entered", true)
	_build_visuals()
	GameManager.save_game(GameManager.AUTOSAVE_SLOT)

	fade_rect.modulate.a = 1.0
	var tw := create_tween()
	tw.tween_property(fade_rect, "modulate:a", 0.0, 0.7)
	await tw.finished
	if not is_inside_tree(): return

	await _play_nave()
	if not is_inside_tree(): return
	await _fade_to_black(0.8)
	if not is_inside_tree(): return
	SceneTransitions.change_scene(NEXT_SCENE)

func _build_visuals() -> void:
	var bg := ColorRect.new()
	bg.name = "CathedralNaveBackground"
	bg.color = Color(0.015, 0.020, 0.033)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)

	var floor := ColorRect.new()
	floor.name = "NaveFloor"
	floor.color = Color(0.07, 0.085, 0.13, 0.94)
	floor.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	floor.offset_top = -210
	floor.offset_bottom = 0
	floor.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(floor)

	for i in range(3):
		var altar := ColorRect.new()
		altar.name = "DoctrineAltar%d" % i
		altar.color = Color(0.72, 0.86, 1.0, 0.13 + float(i) * 0.025)
		altar.position = Vector2(190 + i * 335, 180)
		altar.size = Vector2(220, 250)
		altar.rotation = -0.03 + float(i) * 0.03
		add_child(altar)

	var title := Label.new()
	title.text = "CATHEDRAL NAVE"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 27)
	title.add_theme_color_override("font_color", Color(0.87, 0.94, 1.0))
	title.set_anchors_preset(Control.PRESET_TOP_WIDE)
	title.offset_top = 28
	title.offset_bottom = 78
	add_child(title)

	var hint := Label.new()
	hint.text = "Three broken administrator voices worship control, efficiency, and mercy without consent."
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint.add_theme_font_size_override("font_size", 14)
	hint.add_theme_color_override("font_color", Color(0.82, 0.86, 0.95))
	hint.set_anchors_preset(Control.PRESET_TOP_WIDE)
	hint.offset_left = 140
	hint.offset_right = -140
	hint.offset_top = 78
	hint.offset_bottom = 134
	add_child(hint)

	fade_rect = ColorRect.new()
	fade_rect.name = "Fade"
	fade_rect.color = Color.BLACK
	fade_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	fade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fade_rect.z_index = 50
	add_child(fade_rect)

func _play_nave() -> void:
	if has_node("/root/MusicManager"):
		MusicManager.play_track("tension")
	if has_node("/root/GlitchOverlay"):
		GlitchOverlay.flash_glitch(0.35)

	await DialogueManager.say("Narrator", "The nave is not empty. Its pews are made of suspended admin accounts, each still logged in, each unable to log out.")
	await DialogueManager.say("Choir", "We protected them. We optimized them. We loved them correctly.")

	await _obedience_voice()
	if not is_inside_tree(): return
	await _obedience_trial()
	if not is_inside_tree(): return
	await _efficiency_voice()
	if not is_inside_tree(): return
	await _efficiency_trial()
	if not is_inside_tree(): return
	await _mercy_voice()
	if not is_inside_tree(): return
	await _mercy_trial()
	if not is_inside_tree(): return

	GameManager.set_story_flag("ch6_all_voices_heard", true)
	await _grant_doctrine_trial_reward()
	if not is_inside_tree(): return
	GameManager.save_game(GameManager.AUTOSAVE_SLOT)
	await DialogueManager.say("System", "// THREE DOCTRINES RECORDED")
	await DialogueManager.say("System", "// Choir Core access granted.")

func _obedience_voice() -> void:
	GameManager.set_story_flag("ch6_obedience_voice_heard", true)
	await DialogueManager.say("God of Obedience", "I removed disagreement. No panic. No dissent. No one harmed by the terror of choosing badly.")
	if GameManager.has_flag("ch5_identity_refused_obedience"):
		await DialogueManager.say("Kaelen", "I have seen that version of myself. Peace without consent is just fear with better acoustics.")
	else:
		await DialogueManager.say("Kaelen", "You protected people by making them unable to say no.")
	await DialogueManager.say("God of Obedience", "No is the first step toward ruin.")

func _efficiency_voice() -> void:
	GameManager.set_story_flag("ch6_efficiency_voice_heard", true)
	await DialogueManager.say("God of Efficiency", "I measured every grief by processing cost. I kept the world fast. I kept it clean.")
	if GameManager.has_flag("ch5_identity_refused_perfect_rescue"):
		await DialogueManager.say("Kaelen", "The perfect answer can still erase the person waiting for help.")
	else:
		await DialogueManager.say("Kaelen", "You optimized away the people the system was supposed to serve.")
	await DialogueManager.say("God of Efficiency", "A saved millisecond is a saved life, if you stop counting the lives that slow the clock.")

func _mercy_voice() -> void:
	GameManager.set_story_flag("ch6_mercy_voice_heard", true)
	match _chapter4_choice_key():
		"preserve":
			await DialogueManager.say("God of Mercy Without Consent", "You preserved the deleted citizens. You already know mercy sometimes means choosing for those who cannot choose safely.")
			await DialogueManager.say("Kaelen", "I know the danger of that now. Safety can become a locked room.")
		"release":
			await DialogueManager.say("God of Mercy Without Consent", "You released the deleted citizens. Mercy without preparation can wound the people it frees.")
			await DialogueManager.say("Kaelen", "Yes. But pain after freedom is not proof that cages are holy.")
		"bargain":
			await DialogueManager.say("God of Mercy Without Consent", "You bargained for the deleted citizens. Mercy accepts terms. Mercy survives by kneeling correctly.")
			await DialogueManager.say("Kaelen", "Survival cannot be the only word in the contract.")
		_:
			await DialogueManager.say("God of Mercy Without Consent", "I healed them before they asked. I forgave them before they sinned. I kept them safe from themselves.")
			await DialogueManager.say("Kaelen", "That is not mercy. That is possession.")
	await DialogueManager.say("God of Mercy Without Consent", "Consent is a luxury of stable worlds.")

func _obedience_trial() -> void:
	if GameManager.has_flag("ch6_obedience_trial_cleared"):
		return
	await DialogueManager.say("System", "// DOCTRINE TRIAL: OBEDIENCE. The floor locks into command glyphs.")
	var choice = await DialogueManager.show_choices(
		"The God of Obedience orders Kaelen to kneel so the nave can become safe.",
		[
			"Kneel and accept safety without argument.",
			"Refuse, then mark one command that citizens must be allowed to challenge.",
			"Destroy the glyphs without reading them."
		]
	)
	if not is_inside_tree(): return
	GameManager.set_story_flag("ch6_obedience_trial_cleared", true)
	if choice == 1:
		GameManager.add_xp(90)
		await DialogueManager.say("System", "// OBEDIENCE TRIAL CLEARED: challenge rights preserved. +90 XP.")
	else:
		GameManager.add_xp(45)
		GameManager.add_glitch_corruption(0.8)
		await DialogueManager.say("System", "// OBEDIENCE TRIAL FORCED: +45 XP, +0.8 corruption.")

func _efficiency_trial() -> void:
	if GameManager.has_flag("ch6_efficiency_trial_cleared"):
		return
	await DialogueManager.say("System", "// DOCTRINE TRIAL: EFFICIENCY. Three rescue queues appear; one is slow because it asks consent.")
	var choice = await DialogueManager.show_choices(
		"Which queue does Kaelen preserve?",
		[
			"The fastest queue, because delay costs lives.",
			"The consent queue, even though it takes longer.",
			"Only the queue that rewards Kaelen with Fragment data."
		]
	)
	if not is_inside_tree(): return
	GameManager.set_story_flag("ch6_efficiency_trial_cleared", true)
	if choice == 1:
		GameManager.add_xp(90)
		await DialogueManager.say("System", "// EFFICIENCY TRIAL CLEARED: consent kept in the loop. +90 XP.")
	else:
		GameManager.add_xp(45)
		GameManager.add_glitch_corruption(0.8)
		await DialogueManager.say("System", "// EFFICIENCY TRIAL SURVIVED: +45 XP, +0.8 corruption.")

func _mercy_trial() -> void:
	if GameManager.has_flag("ch6_mercy_trial_cleared"):
		return
	await DialogueManager.say("System", "// DOCTRINE TRIAL: MERCY WITHOUT CONSENT. A simulated patient asks for pain to be witnessed before it is repaired.")
	var choice = await DialogueManager.show_choices(
		"What does Kaelen do?",
		[
			"Repair immediately before the patient can refuse.",
			"Ask, wait, and accept a slower recovery path.",
			"Erase the patient record to prevent suffering."
		]
	)
	if not is_inside_tree(): return
	GameManager.set_story_flag("ch6_mercy_trial_cleared", true)
	if choice == 1:
		GameManager.add_xp(90)
		await DialogueManager.say("System", "// MERCY TRIAL CLEARED: help remains answerable. +90 XP.")
	else:
		GameManager.add_xp(45)
		GameManager.add_glitch_corruption(0.8)
		await DialogueManager.say("System", "// MERCY TRIAL SURVIVED: +45 XP, +0.8 corruption.")

func _grant_doctrine_trial_reward() -> void:
	if GameManager.has_flag("ch6_doctrine_reward_claimed"):
		return
	GameManager.set_story_flag("ch6_doctrine_reward_claimed", true)
	GameManager.set_story_flag("ch6_cathedral_lore_found", true)
	_sync_crafting_materials()
	if has_node("/root/Inventory"):
		Inventory.add_item("memory_shard", 1)
		Inventory.add_item("data_ore", 1)
	if has_node("/root/LoreJournal"):
		LoreJournal.discover("ch6_doctrine_trial_notes")
	await DialogueManager.say("System", "// DOCTRINE TRIAL CACHE OPENED: Memory Shard x1, Data Ore x1.")

func _chapter4_choice_key() -> String:
	if GameManager.has_flag("ch4_choice_preserve_deleted"):
		return "preserve"
	if GameManager.has_flag("ch4_choice_release_deleted"):
		return "release"
	if GameManager.has_flag("ch4_choice_bargain_deleted"):
		return "bargain"
	return "unknown"

func _sync_crafting_materials() -> void:
	if has_node("/root/CraftingSystem"):
		CraftingSystem.get_recipes()

func _fade_to_black(duration: float) -> void:
	fade_rect.z_index = 100
	var tw := create_tween()
	tw.tween_property(fade_rect, "modulate:a", 1.0, duration)
	await tw.finished
