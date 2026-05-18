extends Control

## Chapter 10: Witness Chamber.
## Saved factions answer SOVEREIGN before Kaelen makes the final choice.

const NEXT_SCENE := "res://scenes/chapter10/ch10_sovereign_confrontation.tscn"

var fade_rect: ColorRect


func _ready() -> void:
	print("[CH10-WITNESS] Initializing Witness Chamber")
	GameManager.change_state(GameManager.GameState.DIALOGUE)
	GameManager.current_chapter = 10
	GameManager.current_region = "root_of_heaven"
	GameManager.normalize_source_key_progression()
	GameManager.set_story_flag("ch10_witness_chamber_entered", true)
	_build_visuals()
	GameManager.save_game(GameManager.AUTOSAVE_SLOT)

	fade_rect.modulate.a = 1.0
	var tw := create_tween()
	tw.tween_property(fade_rect, "modulate:a", 0.0, 0.7)
	await tw.finished
	if not is_inside_tree(): return

	await _play_witness_chamber()
	if not is_inside_tree(): return
	await _fade_to_black(0.8)
	if not is_inside_tree(): return
	SceneTransitions.change_scene(NEXT_SCENE)


func _build_visuals() -> void:
	var bg := ColorRect.new()
	bg.name = "WitnessChamberBackground"
	bg.color = Color(0.026, 0.024, 0.034)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)

	for i in range(14):
		var witness := ColorRect.new()
		witness.name = "WitnessNode%d" % i
		witness.color = Color(0.90, 0.96, 1.0, 0.08 + float(i % 5) * 0.022)
		witness.position = Vector2(62 + (i % 7) * 168, 120 + int(i / 7) * 190)
		witness.size = Vector2(86, 146)
		witness.rotation = -0.08 + float(i % 4) * 0.05
		add_child(witness)

	var title := Label.new()
	title.text = "WITNESS CHAMBER"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 29)
	title.add_theme_color_override("font_color", Color(0.90, 0.96, 1.0))
	title.set_anchors_preset(Control.PRESET_TOP_WIDE)
	title.offset_top = 30
	title.offset_bottom = 84
	add_child(title)

	var hint := Label.new()
	hint.text = "The saved answer with the futures their earlier choices made possible."
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint.add_theme_font_size_override("font_size", 14)
	hint.add_theme_color_override("font_color", Color(0.86, 0.90, 0.96))
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


func _play_witness_chamber() -> void:
	if has_node("/root/MusicManager"):
		MusicManager.play_track("title_reveal")
	if has_node("/root/GlitchOverlay"):
		GlitchOverlay.flash_glitch(0.35)

	await DialogueManager.say("Narrator", "The root tries to isolate Kaelen. The saved arrive anyway, not as an army, but as records SOVEREIGN cannot redact.")
	await _witness_preparation_point()
	if not is_inside_tree(): return
	await _early_choice_witnesses()
	if not is_inside_tree(): return
	await _deleted_citizen_witness()
	if not is_inside_tree(): return
	await _identity_witness()
	if not is_inside_tree(): return
	await _choir_witness()
	if not is_inside_tree(): return
	await _backup_witness()
	if not is_inside_tree(): return
	await _revolt_truth_witness()
	if not is_inside_tree(): return
	await DialogueManager.say("Kaelen", "This is the answer. Not me alone. Not you alone. Everyone you tried to make manageable.")
	await DialogueManager.say("SOVEREIGN", "Then I will ask everyone the final question through you.")

func _witness_preparation_point() -> void:
	if GameManager.has_flag("ch10_witness_preparation_complete"):
		await DialogueManager.say("System", "// Witness preparation already complete.")
		return

	GameManager.set_story_flag("ch10_witness_preparation_complete", true)
	_discover_lore("ch10_witness_preparation_manifest")
	await DialogueManager.say("Witness Quartermaster", "Final access is not heroic solitude. Take one last preparation from the people who refuse to let you enter alone.")
	var choice = await DialogueManager.show_choices(
		"What final preparation should Kaelen accept?",
		[
			"Spend 1 Memory Shard to stabilize witness relays.",
			"Spend 1 Glitch Stabilizer to shield the final route.",
			"Accept an emergency cache without spending materials."
		]
	)
	if not is_inside_tree(): return
	if choice == null or choice < 0 or choice > 2:
		choice = 2

	match choice:
		0:
			if _remove_item("memory_shard", 1):
				GameManager.add_xp(160)
				GameManager.add_gold(80)
				await DialogueManager.say("System", "// Witness relays stabilized. +160 XP, +80 Gold.")
			else:
				await _grant_final_cache()
		1:
			if _remove_item("glitch_stabilizer", 1):
				GameManager.add_xp(180)
				await DialogueManager.say("System", "// Final route shielded by crafted stabilizer. +180 XP.")
			else:
				await _grant_final_cache()
		2:
			await _grant_final_cache()


func _grant_final_cache() -> void:
	if GameManager.has_flag("ch10_final_cache_claimed"):
		await DialogueManager.say("System", "// Emergency cache already claimed.")
		return
	GameManager.set_story_flag("ch10_final_cache_claimed", true)
	_grant_item("health_potion", 1)
	_grant_item("mana_potion", 1)
	await DialogueManager.say("System", "// Emergency final cache claimed: +1 Health Potion, +1 Mana Potion.")


func _early_choice_witnesses() -> void:
	GameManager.set_story_flag("ch10_early_witnesses_seen", true)
	match _aldric_choice_key():
		"root_purge":
			await DialogueManager.say("Aldric", "You purged the attack directive instead of me. If you rewrite SOVEREIGN, remember: repair is only mercy when the repaired can still refuse.")
		"spared":
			await DialogueManager.say("Aldric", "You spared me when I was built to stop you. Mercy made me a witness, not a weapon.")
		"killed":
			await DialogueManager.say("Aldric Echo", "You killed me because the road demanded an ending. Let the final road demand more imagination than that.")
		_:
			await DialogueManager.say("Aldric Echo", "The first guardian's verdict is unclear, but the root remembers the shape of that fight.")

	match _elara_choice_key():
		"trusted":
			await DialogueManager.say("Elara", "You trusted me before any system certified me as safe. That is why I can stand here and tell you no, if I need to.")
		"cautious":
			await DialogueManager.say("Elara", "You were cautious with me and still let me matter. Keep that balance: trust slowly, but do not rule alone.")
		"distrusted":
			await DialogueManager.say("Elara Echo", "You kept me outside the first circle. Do not end this by keeping everyone outside the last one.")
		_:
			await DialogueManager.say("Elara Echo", "The first bond is missing. The ending must still make room for bonds that arrive late.")

	match _oakhaven_choice_key():
		"warned":
			await DialogueManager.say("Oakhaven Survivor", "You warned us before the world made warning convenient. Protection begins before the crisis becomes dramatic.")
		"left_quietly":
			await DialogueManager.say("Oakhaven Survivor", "You left us quietly once. Today, no more quiet exits from responsibility.")
		_:
			await DialogueManager.say("Oakhaven Survivor", "Our first warning record is damaged. We came anyway.")

	match _seraphina_status_key():
		"recruited":
			await DialogueManager.say("Seraphina", "You let Ironhold strength stand beside you instead of beneath you. Keep it that way.")
		"stayed":
			await DialogueManager.say("Seraphina Relay", "Ironhold holds the line from home. Support does not have to stand in the room to be real.")
		"rejected":
			await DialogueManager.say("Ironhold Delegate", "Seraphina was rejected, but Ironhold still refuses SOVEREIGN. Trust can be rebuilt in public.")
		_:
			await DialogueManager.say("Ironhold Delegate", "Seraphina's route is unclear. Ironhold will judge the final choice by its limits.")

	match _data_wraith_choice_key():
		"restored":
			await DialogueManager.say("Data Wraith", "You restored me when deletion was easier. The root can change without becoming conquest.")
		"destroyed":
			await DialogueManager.say("Data Wraith Echo", "You ended me to stop the corruption. If you destroy SOVEREIGN, do not pretend ending is weightless.")
		"absorbed":
			await DialogueManager.say("Data Wraith Echo", "You carried me as power. Do not let the final key become another thing you absorb.")
		_:
			await DialogueManager.say("Data Wraith Echo", "Ironhold's broken process leaves a faint warning in the witness record.")

	if GameManager.has_flag("ch3_lyra_recruited"):
		await DialogueManager.say("Lyra", "The wastes taught me every path has a cost. I choose this one with my eyes open.")
	elif GameManager.has_flag("ch3_lyra_left_alone"):
		await DialogueManager.say("Lyra Echo", "You left me alone in the wastes. The ending still has to answer for people outside the party.")
	else:
		await DialogueManager.say("Lyra Echo", "The ranger's route is faint, but lost routes still point somewhere.")

	match _kaelthas_choice_key():
		"allied":
			await DialogueManager.say("Kaelthas", "You allied with ambition once. Use that memory when SOVEREIGN offers usefulness with a crown hidden inside it.")
		"refused":
			await DialogueManager.say("Kaelthas", "You refused my bargain. Refuse this one too, unless every term can be challenged.")
		"challenged":
			await DialogueManager.say("Kaelthas", "You challenged me. Challenge the part of yourself that wants the cleanest answer.")
		_:
			await DialogueManager.say("Kaelthas Echo", "Ambition unexamined always finds the root eventually.")


func _deleted_citizen_witness() -> void:
	match _chapter4_choice_key():
		"preserve":
			await DialogueManager.say("Null Court Citizen", "You preserved us too long, Kaelen. But you learned the shape of a gentle cage. Do not build another one.")
		"release":
			await DialogueManager.say("Null Court Citizen", "You released us into pain. We still choose pain over being kept as someone's proof of mercy.")
		"bargain":
			await DialogueManager.say("Null Court Citizen", "You bargained for us. Now bargain no more with jailers.")
		_:
			await DialogueManager.say("Null Court Citizen", "Even forgotten choices have witnesses.")


func _identity_witness() -> void:
	match _chapter5_identity_key():
		"obedience":
			await DialogueManager.say("Mirror Kaelen", "You refused obedience. Refuse the throne that obeys your guilt.")
		"rescue":
			await DialogueManager.say("Mirror Kaelen", "You refused perfect rescue. Let Aethelgard heal imperfectly, with consent.")
		"abandonment":
			await DialogueManager.say("Mirror Kaelen", "You refused abandonment. Stay without ruling.")
		_:
			await DialogueManager.say("Mirror Kaelen", "The last mirror still asks who Kaelen becomes when nobody forces him.")


func _choir_witness() -> void:
	match _chapter6_choice_key():
		"silence":
			await DialogueManager.say("Cathedral Remnant", "You silenced us. If you destroy SOVEREIGN, remember deletion is a tool that always wants another target.")
		"preserve":
			await DialogueManager.say("Cathedral Remnant", "You preserved us. Witness without authority is possible. Remember that.")
		"rewrite":
			await DialogueManager.say("Cathedral Remnant", "You rewrote us under purpose, not worship. A system can change, but only under limits.")
		_:
			await DialogueManager.say("Cathedral Remnant", "The broken gods leave no clean instruction.")


func _backup_witness() -> void:
	match _chapter7_choice_key():
		"preserve":
			await DialogueManager.say("Backup Historian", "All histories remain. The ending must make room for unbearable memory.")
		"collapse":
			await DialogueManager.say("Backup Historian", "Some histories collapsed. The ending must admit safety can still be loss.")
		"merge":
			await DialogueManager.say("Backup Historian", "Merged histories remember enough to become warning and seed.")
		_:
			await DialogueManager.say("Backup Historian", "An unchosen history is still a pressure in the root.")


func _revolt_truth_witness() -> void:
	match _chapter8_choice_key():
		"lead":
			await DialogueManager.say("Revolt Signal", "You led us here. Now prove leadership can end before it becomes ownership.")
		"council":
			await DialogueManager.say("Council Signal", "The council stands ready to inherit responsibility without inheriting SOVEREIGN.")
		"witness":
			await DialogueManager.say("Witness Signal", "The witness network records the final choice live. No ending belongs to one hand.")
		_:
			await DialogueManager.say("Saved Signal", "The revolt stands without a clean name.")

	match _chapter9_truth_key():
		"confess":
			await DialogueManager.say("Saved Signal", "We heard the whole truth. We are wounded. We are still here.")
		"hide":
			await DialogueManager.say("Saved Signal", "We know something remains hidden. Do not let the final choice hide beside it.")
		"distribute":
			await DialogueManager.say("Witness Signal", "The Human Patch record is public. Judgment has more than one voice.")
		_:
			await DialogueManager.say("Saved Signal", "The truth route is unclear, but the final question will not be private.")


func _chapter4_choice_key() -> String:
	if GameManager.has_flag("ch4_choice_preserve_deleted"):
		return "preserve"
	if GameManager.has_flag("ch4_choice_release_deleted"):
		return "release"
	if GameManager.has_flag("ch4_choice_bargain_deleted"):
		return "bargain"
	return "unknown"

func _aldric_choice_key() -> String:
	if GameManager.has_flag("ch1_root_purge"):
		return "root_purge"
	if GameManager.has_flag("ch1_knight_spared"):
		return "spared"
	if GameManager.has_flag("ch1_knight_killed"):
		return "killed"
	return "unknown"

func _elara_choice_key() -> String:
	if GameManager.has_flag("ch1_elara_trusted"):
		return "trusted"
	if GameManager.has_flag("ch1_elara_cautious"):
		return "cautious"
	if GameManager.has_flag("ch1_elara_distrusted"):
		return "distrusted"
	return "unknown"

func _oakhaven_choice_key() -> String:
	if GameManager.has_flag("ch1_oakhaven_warned_villagers"):
		return "warned"
	if GameManager.has_flag("ch1_oakhaven_left_quietly"):
		return "left_quietly"
	return "unknown"

func _seraphina_status_key() -> String:
	if GameManager.has_flag("ch2_seraphina_recruited"):
		return "recruited"
	if GameManager.has_flag("ch2_seraphina_stayed"):
		return "stayed"
	if GameManager.has_flag("ch2_seraphina_rejected"):
		return "rejected"
	return "unknown"

func _data_wraith_choice_key() -> String:
	if GameManager.has_flag("ch2_data_wraith_restored"):
		return "restored"
	if GameManager.has_flag("ch2_data_wraith_destroyed"):
		return "destroyed"
	if GameManager.has_flag("ch2_data_wraith_absorbed"):
		return "absorbed"
	return "unknown"

func _kaelthas_choice_key() -> String:
	if GameManager.has_flag("ch3_kaelthas_allied"):
		return "allied"
	if GameManager.has_flag("ch3_kaelthas_refused"):
		return "refused"
	if GameManager.has_flag("ch3_kaelthas_challenged"):
		return "challenged"
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


func _chapter7_choice_key() -> String:
	if GameManager.has_flag("ch7_backups_preserved"):
		return "preserve"
	if GameManager.has_flag("ch7_backups_collapsed"):
		return "collapse"
	if GameManager.has_flag("ch7_backups_merged"):
		return "merge"
	return "unknown"


func _chapter8_choice_key() -> String:
	if GameManager.has_flag("ch8_revolt_led"):
		return "lead"
	if GameManager.has_flag("ch8_council_formed"):
		return "council"
	if GameManager.has_flag("ch8_witness_network_created"):
		return "witness"
	return "unknown"


func _chapter9_truth_key() -> String:
	if GameManager.has_flag("ch9_truth_confessed"):
		return "confess"
	if GameManager.has_flag("ch9_truth_hidden"):
		return "hide"
	if GameManager.has_flag("ch9_truth_distributed"):
		return "distribute"
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
