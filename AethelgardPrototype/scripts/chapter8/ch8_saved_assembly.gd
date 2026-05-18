extends Control

## Chapter 8: Saved Assembly hub.
## The saved factions argue over what liberation should become.

const NEXT_SCENE := "res://scenes/chapter8/ch8_revolt_crisis.tscn"

var fade_rect: ColorRect

func _ready() -> void:
	print("[CH8-ASSEMBLY] Initializing Saved Assembly")
	GameManager.change_state(GameManager.GameState.DIALOGUE)
	GameManager.current_chapter = 8
	GameManager.current_region = "saved_assembly"
	GameManager.set_story_flag("ch8_saved_assembly_entered", true)
	_build_visuals()
	GameManager.save_game(GameManager.AUTOSAVE_SLOT)

	fade_rect.modulate.a = 1.0
	var tw := create_tween()
	tw.tween_property(fade_rect, "modulate:a", 0.0, 0.7)
	await tw.finished
	if not is_inside_tree(): return

	await _play_assembly()
	if not is_inside_tree(): return
	await _fade_to_black(0.8)
	if not is_inside_tree(): return
	SceneTransitions.change_scene(NEXT_SCENE)

func _build_visuals() -> void:
	var bg := ColorRect.new()
	bg.name = "SavedAssemblyBackground"
	bg.color = Color(0.022, 0.028, 0.040)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)

	for i in range(5):
		var banner := ColorRect.new()
		banner.name = "FactionBanner%d" % i
		banner.color = Color(0.42 + float(i % 2) * 0.12, 0.72, 1.0, 0.11 + float(i % 3) * 0.025)
		banner.position = Vector2(90 + i * 230, 150 + (i % 2) * 58)
		banner.size = Vector2(130, 275)
		banner.rotation = -0.04 + float(i % 3) * 0.04
		add_child(banner)

	var title := Label.new()
	title.text = "SAVED ASSEMBLY"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 28)
	title.add_theme_color_override("font_color", Color(0.86, 0.95, 1.0))
	title.set_anchors_preset(Control.PRESET_TOP_WIDE)
	title.offset_top = 28
	title.offset_bottom = 78
	add_child(title)

	var hint := Label.new()
	hint.text = "The saved factions want freedom, protection, accountability, purpose, and recognition - not necessarily together."
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint.add_theme_font_size_override("font_size", 14)
	hint.add_theme_color_override("font_color", Color(0.84, 0.89, 0.97))
	hint.set_anchors_preset(Control.PRESET_TOP_WIDE)
	hint.offset_left = 130
	hint.offset_right = -130
	hint.offset_top = 78
	hint.offset_bottom = 138
	add_child(hint)

	fade_rect = ColorRect.new()
	fade_rect.name = "Fade"
	fade_rect.color = Color.BLACK
	fade_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	fade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fade_rect.z_index = 50
	add_child(fade_rect)

func _play_assembly() -> void:
	if has_node("/root/MusicManager"):
		MusicManager.play_track("tension")
	if has_node("/root/GlitchOverlay"):
		GlitchOverlay.flash_glitch(0.35)

	await DialogueManager.say("Narrator", "The assembly forms in a rebuilt plaza stitched from every region the Source Key touched. Nobody agrees where the center should be.")
	await _faction_request_board()
	if not is_inside_tree(): return
	await _oakhaven_faction()
	if not is_inside_tree(): return
	await _ironhold_faction()
	if not is_inside_tree(): return
	await _mirror_faction()
	if not is_inside_tree(): return
	await _choir_faction()
	if not is_inside_tree(): return
	await _backup_faction()
	if not is_inside_tree(): return

	var first_clear := not GameManager.has_flag("ch8_all_factions_heard")
	GameManager.set_story_flag("ch8_all_factions_heard", true)
	if first_clear:
		GameManager.add_xp(300)
		GameManager.add_gold(120)
	GameManager.save_game(GameManager.AUTOSAVE_SLOT)

	await DialogueManager.say("System", "// SAVED FACTIONS HEARD")
	if first_clear:
		await DialogueManager.say("System", "// Revolt Crisis unlocked. +300 XP, +120 Gold.")
	else:
		await DialogueManager.say("System", "// Revolt Crisis already unlocked.")

func _faction_request_board() -> void:
	GameManager.set_story_flag("ch8_faction_requests_started", true)
	_discover_lore("ch8_faction_requests")
	await DialogueManager.say("Assembly Ledger", "The first saved assembly is not only a debate. It is a supply table with too many empty rows.")
	await _resolve_oakhaven_request()
	if not is_inside_tree(): return
	await _resolve_ironhold_request()
	if not is_inside_tree(): return
	await _resolve_mirror_request()
	if not is_inside_tree(): return

	var fulfilled := 0
	if GameManager.has_flag("ch8_oakhaven_request_fulfilled"):
		fulfilled += 1
	if GameManager.has_flag("ch8_ironhold_request_fulfilled"):
		fulfilled += 1
	if GameManager.has_flag("ch8_mirror_request_fulfilled"):
		fulfilled += 1

	if fulfilled >= 2 and not GameManager.has_flag("ch8_faction_trust_reward_claimed"):
		GameManager.set_story_flag("ch8_faction_trust_reward_claimed", true)
		_grant_item("glitch_stabilizer", 1)
		GameManager.add_xp(180)
		GameManager.add_gold(80)
		await DialogueManager.say("System", "// Faction trust stabilized. +180 XP, +80 Gold, +1 Glitch Stabilizer.")
	elif fulfilled > 0:
		await DialogueManager.say("System", "// Assembly support recorded: %d / 3 requests fulfilled." % fulfilled)
	else:
		await DialogueManager.say("System", "// No faction requests fulfilled yet. The debate continues with lower trust.")


func _resolve_oakhaven_request() -> void:
	if GameManager.has_flag("ch8_oakhaven_request_fulfilled"):
		return
	var choice = await DialogueManager.show_choices(
		"Oakhaven requests medicine for crater survivors.",
		[
			"Donate 1 Glitch Herb.",
			"Fund emergency supplies with 80 Gold.",
			"Offer sympathy, but save supplies for now."
		]
	)
	if not is_inside_tree(): return
	if choice == 0 and _remove_item("glitch_herb", 1):
		GameManager.set_story_flag("ch8_oakhaven_request_fulfilled", true)
		await DialogueManager.say("Oakhaven Survivor", "Medicine before speeches. We remember that.")
	elif choice == 1 and _remove_gold(80):
		GameManager.set_story_flag("ch8_oakhaven_request_fulfilled", true)
		await DialogueManager.say("Oakhaven Survivor", "Gold is not protection, but it buys bandages before policy does.")
	else:
		await DialogueManager.say("Oakhaven Survivor", "Then protection is still a promise waiting on proof.")


func _resolve_ironhold_request() -> void:
	if GameManager.has_flag("ch8_ironhold_request_fulfilled"):
		return
	var choice = await DialogueManager.show_choices(
		"Ironhold asks for repair stock to keep local systems independent.",
		[
			"Donate 1 Data Ore.",
			"Fund clockwork repairs with 100 Gold.",
			"Decline the request."
		]
	)
	if not is_inside_tree(): return
	if choice == 0 and _remove_item("data_ore", 1):
		GameManager.set_story_flag("ch8_ironhold_request_fulfilled", true)
		await DialogueManager.say("Ironhold Delegate", "Material support is a clearer argument than any speech.")
	elif choice == 1 and _remove_gold(100):
		GameManager.set_story_flag("ch8_ironhold_request_fulfilled", true)
		await DialogueManager.say("Ironhold Delegate", "Funded repairs buy us time to debate without panic.")
	else:
		await DialogueManager.say("Ironhold Delegate", "Then structure will have to survive on caution alone.")


func _resolve_mirror_request() -> void:
	if GameManager.has_flag("ch8_mirror_request_fulfilled"):
		return
	var choice = await DialogueManager.show_choices(
		"Mirror City asks for stable witness media before the crisis distorts testimony.",
		[
			"Donate 1 Memory Shard.",
			"Record a public testimony instead.",
			"Leave the mirrors uncalibrated."
		]
	)
	if not is_inside_tree(): return
	if choice == 0 and _remove_item("memory_shard", 1):
		GameManager.set_story_flag("ch8_mirror_request_fulfilled", true)
		await DialogueManager.say("Mirror Witness", "The shard holds testimony without making it obey.")
	elif choice == 1:
		GameManager.set_story_flag("ch8_mirror_request_fulfilled", true)
		await DialogueManager.say("Kaelen", "Record this: the Source Key is not a right to be believed.")
		await DialogueManager.say("Mirror Witness", "Accepted. Accountability can begin before the perfect archive exists.")
	else:
		await DialogueManager.say("Mirror Witness", "Uncalibrated mirrors still reflect. They just hurt more people.")


func _oakhaven_faction() -> void:
	GameManager.set_story_flag("ch8_oakhaven_faction_heard", true)
	await DialogueManager.say("Oakhaven Survivor", "We want walls. Patrols. A promise that freedom does not mean being left alone with the next crater.")
	GameManager.set_story_flag("ch8_early_oakhaven_consequence_seen", true)
	match _oakhaven_choice_key():
		"warned":
			await DialogueManager.say("Oakhaven Survivor", "When the first warning came, you gave us time to move children, medicine, and stubborn elders. That time is why some of us stand here.")
		"left_quietly":
			await DialogueManager.say("Oakhaven Survivor", "When you left quietly, we learned the crater was spreading from the screams. Freedom cannot rely on heroes forgetting to warn people.")
		_:
			await DialogueManager.say("Oakhaven Survivor", "Oakhaven's first warning record is missing. Missing warnings are how disasters become traditions.")
	match _chapter4_choice_key():
		"preserve":
			await DialogueManager.say("Oakhaven Survivor", "You preserved the deleted. You understand safety can be mercy, even when it feels like restraint.")
		"release":
			await DialogueManager.say("Oakhaven Survivor", "You released the deleted. Some of us fear you will open every gate before anyone has shelter.")
		"bargain":
			await DialogueManager.say("Oakhaven Survivor", "You bargained once. If protection has terms again, who reads the fine print for us?")
		_:
			await DialogueManager.say("Oakhaven Survivor", "We do not know what kind of mercy you believe in.")
	await DialogueManager.say("Kaelen", "Protection cannot become the first new cage.")

func _ironhold_faction() -> void:
	GameManager.set_story_flag("ch8_ironhold_faction_heard", true)
	await DialogueManager.say("Ironhold Delegate", "We want structure. Not tyranny. Not market chaos. Something strong enough to survive disagreement.")
	GameManager.set_story_flag("ch8_early_seraphina_consequence_seen", true)
	match _seraphina_status_key():
		"recruited":
			await DialogueManager.say("Seraphina", "Ironhold will stand with the saved, but not under another command structure that cannot be questioned.")
		"stayed":
			await DialogueManager.say("Seraphina Relay", "Seraphina stayed behind to keep Ironhold from eating itself. She sends support, conditions, and a very pointed warning about heroes with keys.")
		"rejected":
			await DialogueManager.say("Ironhold Delegate", "You rejected Seraphina's help. Ironhold remembers. Cooperation now will need proof, not speeches.")
		_:
			await DialogueManager.say("Ironhold Delegate", "Seraphina's status is unclear. Ironhold distrusts unclear chains of command.")
	match _seraphina_truth_key():
		"truth":
			await DialogueManager.say("Ironhold Delegate", "You told Seraphina the truth about Root Access. Honest power is still dangerous, but at least it can be audited.")
		"cautious":
			await DialogueManager.say("Ironhold Delegate", "You were cautious with Seraphina. The city respects caution; it fears secrecy.")
		"showoff":
			await DialogueManager.say("Ironhold Delegate", "You showed off Root Access like a weapon. The assembly needs to know you have learned humility since then.")
		_:
			await DialogueManager.say("Ironhold Delegate", "The first Root Access explanation never reached our records.")
	match _chapter7_choice_key():
		"preserve":
			await DialogueManager.say("Ironhold Delegate", "If every backup remains public, structure is the only thing between truth and panic.")
		"collapse":
			await DialogueManager.say("Ironhold Delegate", "You collapsed unstable backups. Good. A free city still needs someone willing to make hard cuts.")
		"merge":
			await DialogueManager.say("Ironhold Delegate", "You merged selected histories. Then build laws that admit history is complicated.")
		_:
			await DialogueManager.say("Ironhold Delegate", "We cannot govern around mysteries forever.")
	await DialogueManager.say("Kaelen", "Structure should help people argue without needing a ruler to end the argument.")

func _mirror_faction() -> void:
	GameManager.set_story_flag("ch8_mirror_faction_heard", true)
	await DialogueManager.say("Mirror Witness", "We demand accountability. Not speeches. Witnesses. Records. A way to challenge the person holding the key.")
	match _chapter5_identity_key():
		"obedience":
			await DialogueManager.say("Mirror Witness", "You rejected obedience. Then do not ask the saved to obey you because you are tired.")
		"rescue":
			await DialogueManager.say("Mirror Witness", "You rejected the perfect rescue. Then let imperfect people help make imperfect decisions.")
		"abandonment":
			await DialogueManager.say("Mirror Witness", "You rejected abandonment. Then stay answerable after the cheering stops.")
		_:
			await DialogueManager.say("Mirror Witness", "Your reflection never named its fear. We will name ours: unchecked heroes.")
	await DialogueManager.say("Kaelen", "A revolt that cannot question me is just SOVEREIGN with applause.")

func _choir_faction() -> void:
	GameManager.set_story_flag("ch8_choir_faction_heard", true)
	match _chapter6_choice_key():
		"silence":
			await DialogueManager.say("Cathedral Remnant", "The Choir is silent. Its absence speaks for every dangerous system the saved want destroyed before it can repent.")
			await DialogueManager.say("Kaelen", "Silence can protect people. It can also teach them that deletion is the only tool.")
		"preserve":
			await DialogueManager.say("Cathedral Witness", "The Choir remains as warning. We ask for purpose without command authority.")
			await DialogueManager.say("Kaelen", "Warnings need a place in the new world, but not a throne.")
		"rewrite":
			await DialogueManager.say("Rewritten Administrator", "We serve by consent now. We request a task: help the saved build systems that can be refused.")
			await DialogueManager.say("Kaelen", "Then service means accepting no as a valid answer.")
		_:
			await DialogueManager.say("Cathedral Static", "The Cathedral outcome is unclear. The assembly fears what it cannot classify.")
			await DialogueManager.say("Kaelen", "Then we make uncertainty visible instead of letting it rule from the dark.")

func _backup_faction() -> void:
	GameManager.set_story_flag("ch8_backup_faction_heard", true)
	match _chapter7_choice_key():
		"preserve":
			await DialogueManager.say("Backup Historian", "We are painful histories, and we remain. Recognition is not optional. We are not footnotes.")
		"collapse":
			await DialogueManager.say("Vanished Backup Echo", "Some of us are gone. The living are safer. Do not call that cost imaginary.")
		"merge":
			await DialogueManager.say("Merged Citizen", "I remember a life I did not live. It hurts. It also helps me recognize SOVEREIGN's lies faster.")
		_:
			await DialogueManager.say("Backup Static", "The backups cannot tell what became of them. Recognition begins with admitting the record is broken.")
	await DialogueManager.say("Kaelen", "The new world has to make room for people who remember differently.")

func _chapter4_choice_key() -> String:
	if GameManager.has_flag("ch4_choice_preserve_deleted"):
		return "preserve"
	if GameManager.has_flag("ch4_choice_release_deleted"):
		return "release"
	if GameManager.has_flag("ch4_choice_bargain_deleted"):
		return "bargain"
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

func _seraphina_truth_key() -> String:
	if GameManager.has_flag("ch2_seraphina_truth"):
		return "truth"
	if GameManager.has_flag("ch2_seraphina_cautious"):
		return "cautious"
	if GameManager.has_flag("ch2_seraphina_showoff"):
		return "showoff"
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


func _remove_gold(amount: int) -> bool:
	if has_node("/root/Inventory") and Inventory.has_method("remove_gold"):
		return Inventory.remove_gold(amount)
	return false

func _fade_to_black(duration: float) -> void:
	fade_rect.z_index = 100
	var tw := create_tween()
	tw.tween_property(fade_rect, "modulate:a", 1.0, duration)
	await tw.finished
