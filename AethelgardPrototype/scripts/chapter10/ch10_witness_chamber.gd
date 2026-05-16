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


func _fade_to_black(duration: float) -> void:
	fade_rect.z_index = 100
	var tw := create_tween()
	tw.tween_property(fade_rect, "modulate:a", 1.0, duration)
	await tw.finished
