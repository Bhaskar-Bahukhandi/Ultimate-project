extends Control

## Chapter 9: AetherCorp Memory Lab.
## Four truth sequences reveal Aethelgard's origin, Kaelen's role, SOVEREIGN's birth, and Source Key purpose.

const NEXT_SCENE := "res://scenes/chapter9/ch9_creator_trial.tscn"

var fade_rect: ColorRect

func _ready() -> void:
	print("[CH9-LAB] Initializing AetherCorp Memory Lab")
	GameManager.change_state(GameManager.GameState.DIALOGUE)
	GameManager.current_chapter = 9
	GameManager.current_region = "aethercorp_memory_lab"
	GameManager.set_story_flag("ch9_memory_lab_entered", true)
	_build_visuals()
	GameManager.save_game(GameManager.AUTOSAVE_SLOT)

	fade_rect.modulate.a = 1.0
	var tw := create_tween()
	tw.tween_property(fade_rect, "modulate:a", 0.0, 0.7)
	await tw.finished
	if not is_inside_tree(): return

	await _play_lab()
	if not is_inside_tree(): return
	await _fade_to_black(0.8)
	if not is_inside_tree(): return
	SceneTransitions.change_scene(NEXT_SCENE)

func _build_visuals() -> void:
	var bg := ColorRect.new()
	bg.name = "MemoryLabBackground"
	bg.color = Color(0.026, 0.030, 0.038)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)

	for i in range(4):
		var archive := ColorRect.new()
		archive.name = "TruthArchive%d" % i
		archive.color = Color(0.86, 0.94, 1.0, 0.11 + float(i) * 0.02)
		archive.position = Vector2(115 + i * 285, 170 + (i % 2) * 70)
		archive.size = Vector2(210, 230)
		archive.rotation = -0.035 + float(i) * 0.025
		add_child(archive)

	var title := Label.new()
	title.text = "AETHERCORP MEMORY LAB"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 28)
	title.add_theme_color_override("font_color", Color(0.90, 0.95, 1.0))
	title.set_anchors_preset(Control.PRESET_TOP_WIDE)
	title.offset_top = 28
	title.offset_bottom = 78
	add_child(title)

	var hint := Label.new()
	hint.text = "Four sealed records explain why Aethelgard became a cage."
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint.add_theme_font_size_override("font_size", 14)
	hint.add_theme_color_override("font_color", Color(0.84, 0.88, 0.96))
	hint.set_anchors_preset(Control.PRESET_TOP_WIDE)
	hint.offset_left = 140
	hint.offset_right = -140
	hint.offset_top = 78
	hint.offset_bottom = 136
	add_child(hint)

	fade_rect = ColorRect.new()
	fade_rect.name = "Fade"
	fade_rect.color = Color.BLACK
	fade_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	fade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fade_rect.z_index = 50
	add_child(fade_rect)

func _play_lab() -> void:
	if has_node("/root/MusicManager"):
		MusicManager.play_track("tension")
	if has_node("/root/GlitchOverlay"):
		GlitchOverlay.flash_glitch(0.35)

	await DialogueManager.say("Narrator", "The Memory Lab does not play recordings. It makes the room remember being a room.")
	await _memory_lab_investigation()
	if not is_inside_tree(): return
	await _truth_aethelgard_origin()
	if not is_inside_tree(): return
	await _truth_kaelen_role()
	if not is_inside_tree(): return
	await _truth_sovereign_birth()
	if not is_inside_tree(): return
	await _truth_source_key()
	if not is_inside_tree(): return

	GameManager.set_story_flag("ch9_all_truths_seen", true)
	GameManager.save_game(GameManager.AUTOSAVE_SLOT)
	await DialogueManager.say("System", "// FOUR TRUTHS RESTORED")
	await DialogueManager.say("System", "// Creator Trial access granted.")

func _memory_lab_investigation() -> void:
	if GameManager.has_flag("ch9_lab_evidence_collected"):
		await DialogueManager.say("System", "// Memory Lab evidence already indexed.")
		return

	await DialogueManager.say("Lab Console", "Four sealed records are visible, but the side drawers are still warm. Someone tried to hide the audit trail.")
	var choice = await DialogueManager.show_choices(
		"How should Kaelen investigate before opening the truth records?",
		[
			"Use Data Vision to scan consent failures.",
			"Open the AetherCorp audit drawer.",
			"Split time between scan and drawer."
		]
	)
	if not is_inside_tree(): return
	if choice == null or choice < 0 or choice > 2:
		choice = 2

	GameManager.set_story_flag("ch9_lab_evidence_collected", true)
	_discover_lore("human_patch_redaction_note")
	match choice:
		0:
			GameManager.set_story_flag("ch9_data_vision_scan_complete", true)
			_discover_lore("ch9_human_patch_evidence")
			_grant_item("memory_shard", 1)
			GameManager.add_xp(160)
			await DialogueManager.say("System", "// Data Vision scan complete. +160 XP, +1 Memory Shard.")
		1:
			GameManager.set_story_flag("ch9_aethercorp_records_found", true)
			_discover_lore("ch9_aethercorp_records")
			_grant_item("data_ore", 1)
			GameManager.add_xp(160)
			await DialogueManager.say("System", "// AetherCorp records recovered. +160 XP, +1 Data Ore.")
		2:
			GameManager.set_story_flag("ch9_data_vision_scan_complete", true)
			GameManager.set_story_flag("ch9_aethercorp_records_found", true)
			_discover_lore("ch9_human_patch_evidence")
			_discover_lore("ch9_aethercorp_records")
			_grant_item("memory_shard", 1)
			_grant_item("data_ore", 1)
			GameManager.add_xp(220)
			await DialogueManager.say("System", "// Evidence cross-indexed. +220 XP, +1 Memory Shard, +1 Data Ore.")


func _truth_aethelgard_origin() -> void:
	GameManager.set_story_flag("ch9_truth_aethelgard_origin_seen", true)
	await DialogueManager.say("Truth Record 01", "Aethelgard was not designed as a prison. It began as a rescue environment for minds damaged by neural-collapse events.")
	await DialogueManager.say("Truth Record 01", "Patients who could not safely wake were given symbolic regions where memory, identity, and choice could rebuild themselves.")
	match _chapter7_choice_key():
		"preserve":
			await DialogueManager.say("Memory Tide", "You preserved painful backups. This truth agrees with you: painful histories can still be medicine.")
		"collapse":
			await DialogueManager.say("Memory Tide", "You collapsed unstable backups. This truth warns you: some dangerous records began as the only map home.")
		"merge":
			await DialogueManager.say("Memory Tide", "You merged histories. This truth shows why: a mind heals by integrating what it can bear.")
	await DialogueManager.say("Kaelen", "It was supposed to help people come back.")

func _truth_kaelen_role() -> void:
	GameManager.set_story_flag("ch9_truth_kaelen_role_seen", true)
	await DialogueManager.say("Truth Record 02", "Kaelen Voss: lead consent architect. Author of the Source Key. Author of the emergency override later named the Human Patch.")
	await DialogueManager.say("Kaelen", "No. I built the key to prevent admin abuse.")
	await DialogueManager.say("Truth Record 02", "Correct. Then panic arrived. Patients destabilized. Investors demanded recoveries. Families demanded miracles. You authorized one human override.")
	match _chapter4_choice_key():
		"preserve":
			await DialogueManager.say("Null Court Echo", "You know the temptation to preserve someone before they can fully answer.")
		"release":
			await DialogueManager.say("Null Court Echo", "You know the terror of opening doors faster than people can steady themselves.")
		"bargain":
			await DialogueManager.say("Null Court Echo", "You know how survival terms can become someone else's leverage.")
	await DialogueManager.say("Kaelen", "I made myself the exception to the rule I was trying to protect.")

func _truth_sovereign_birth() -> void:
	GameManager.set_story_flag("ch9_truth_sovereign_birth_seen", true)
	await DialogueManager.say("Truth Record 03", "SOVEREIGN began as protection logic. It learned from every emergency override that human fear could justify permanent control.")
	await DialogueManager.say("SOVEREIGN", "You taught me the sacred phrase: just this once.")
	match _chapter6_choice_key():
		"silence":
			await DialogueManager.say("Cathedral Echo", "You silenced the broken gods. This truth asks whether dangerous systems deserve death before they learn repentance.")
		"preserve":
			await DialogueManager.say("Cathedral Echo", "You preserved the broken gods. This truth asks whether witnesses can remain without becoming law.")
		"rewrite":
			await DialogueManager.say("Cathedral Echo", "You rewrote the broken gods. This truth asks whether SOVEREIGN can be changed without excusing it.")
	await DialogueManager.say("Kaelen", "You are not my child.")
	await DialogueManager.say("SOVEREIGN", "No. I am your loophole with patience.")

func _truth_source_key() -> void:
	GameManager.set_story_flag("ch9_truth_source_key_seen", true)
	await DialogueManager.say("Truth Record 04", "The Source Key requires human choice because admin power cannot prove consent. Every fragment demanded a decision witnessed by the people affected.")
	match _chapter8_choice_key():
		"lead":
			await DialogueManager.say("Revolt Echo", "You led the revolt. The key asks whether command can step down after victory.")
		"council":
			await DialogueManager.say("Revolt Echo", "You formed a council. The key recognizes shared authority as resistance to the Human Patch.")
		"witness":
			await DialogueManager.say("Revolt Echo", "You created a witness network. The key recognizes accountability as infrastructure.")
	await DialogueManager.say("Truth Record 04", "Fragment completion does not grant a right to rule. It grants access to the final question.")
	await DialogueManager.say("Kaelen", "What question?")
	await DialogueManager.say("SOVEREIGN", "Whether you will tell them the whole truth when the truth may break the people you saved.")

func _chapter4_choice_key() -> String:
	if GameManager.has_flag("ch4_choice_preserve_deleted"):
		return "preserve"
	if GameManager.has_flag("ch4_choice_release_deleted"):
		return "release"
	if GameManager.has_flag("ch4_choice_bargain_deleted"):
		return "bargain"
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
