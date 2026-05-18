extends Control

## Chapter 8: Revolt Crisis.
## The saved factions fracture unless Kaelen defines his role.

const END_SCENE := "res://scenes/chapter8/ch8_ending.tscn"

var fade_rect: ColorRect
var revolt_choice: String = ""

func _ready() -> void:
	print("[CH8-CRISIS] Initializing Revolt Crisis")
	GameManager.change_state(GameManager.GameState.DIALOGUE)
	GameManager.current_chapter = 8
	GameManager.current_region = "saved_assembly"
	GameManager.set_story_flag("ch8_revolt_crisis_started", true)
	_build_visuals()
	GameManager.save_game(GameManager.AUTOSAVE_SLOT)

	fade_rect.modulate.a = 1.0
	var tw := create_tween()
	tw.tween_property(fade_rect, "modulate:a", 0.0, 0.7)
	await tw.finished
	if not is_inside_tree(): return

	await _play_crisis()
	if not is_inside_tree(): return
	await _fade_to_black(0.8)
	if not is_inside_tree(): return
	SceneTransitions.change_scene(END_SCENE)

func _build_visuals() -> void:
	var bg := ColorRect.new()
	bg.name = "RevoltCrisisBackground"
	bg.color = Color(0.035, 0.026, 0.035)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)

	for i in range(11):
		var fracture := ColorRect.new()
		fracture.name = "AssemblyFracture%d" % i
		fracture.color = Color(0.95, 0.82, 0.56, 0.10 + float(i % 4) * 0.03)
		fracture.position = Vector2(95 + (i % 6) * 190, 120 + int(i / 6) * 185)
		fracture.size = Vector2(130, 10)
		fracture.rotation = -0.62 + float(i % 5) * 0.25
		add_child(fracture)

	var title := Label.new()
	title.text = "REVOLT CRISIS"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 29)
	title.add_theme_color_override("font_color", Color(1.0, 0.90, 0.72))
	title.set_anchors_preset(Control.PRESET_TOP_WIDE)
	title.offset_top = 30
	title.offset_bottom = 84
	add_child(title)

	var hint := Label.new()
	hint.text = "The saved factions agree SOVEREIGN must fall. They do not agree what replaces it."
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint.add_theme_font_size_override("font_size", 14)
	hint.add_theme_color_override("font_color", Color(0.92, 0.88, 0.82))
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

func _play_crisis() -> void:
	if has_node("/root/MusicManager"):
		MusicManager.play_track("boss_fight")
	if has_node("/root/GlitchOverlay"):
		GlitchOverlay.flash_glitch(0.65)

	await DialogueManager.say("Narrator", "The assembly does not explode all at once. It fractures in reasonable voices.")
	await DialogueManager.say("Oakhaven Survivor", "Protection first.")
	await DialogueManager.say("Ironhold Delegate", "Structure first.")
	await DialogueManager.say("Mirror Witness", "Accountability first.")
	await DialogueManager.say("Backup Historian", "Recognition first.")
	await DialogueManager.say("SOVEREIGN", "Observe: liberation becomes governance, governance becomes conflict, conflict becomes my return.")
	await _route_pressure()
	if not is_inside_tree(): return
	await _revolt_stabilization_trial()
	if not is_inside_tree(): return

	var choice = await DialogueManager.show_choices(
		"What role should Kaelen take in the revolt?",
		[
			"Lead the revolt directly before SOVEREIGN exploits the fracture.",
			"Refuse to rule and form a council of saved factions.",
			"Reshape the revolt into a witness network that can challenge any leader."
		]
	)
	if not is_inside_tree(): return
	if choice == null or choice < 0 or choice > 2:
		choice = 1

	GameManager.set_story_flag("ch8_choice_made", true)
	_clear_exclusive_choice_flags()
	match choice:
		0:
			revolt_choice = "lead"
			GameManager.set_story_flag("ch8_revolt_led", true)
			GameManager.set_story_flag("ending_route_ch8_lead", true)
			await DialogueManager.say("Kaelen", "I will lead the strike. Not forever. Not as a crown. But SOVEREIGN will not use our debate as a weapon.")
			await DialogueManager.say("Mirror Witness", "Then your first order should name who can remove you.")
		1:
			revolt_choice = "council"
			GameManager.set_story_flag("ch8_council_formed", true)
			GameManager.set_story_flag("ending_route_ch8_council", true)
			await DialogueManager.say("Kaelen", "No single hand holds the Source Key's future. Oakhaven, Ironhold, Mirror City, Cathedral, Deep Backup - all of you get a seat.")
			await DialogueManager.say("Ironhold Delegate", "A council will be slower.")
			await DialogueManager.say("Kaelen", "Good. Tyranny is fast.")
		2:
			revolt_choice = "witness"
			GameManager.set_story_flag("ch8_witness_network_created", true)
			GameManager.set_story_flag("ending_route_ch8_witness", true)
			await DialogueManager.say("Kaelen", "We build witnesses, not rulers. Every faction records, challenges, and can call emergency refusal.")
			await DialogueManager.say("Backup Historian", "A revolt with memory as infrastructure. Dangerous. Necessary.")

	GameManager.save_game(GameManager.AUTOSAVE_SLOT)
	await DialogueManager.say("System", "// REVOLT ROUTE RECORDED: %s" % revolt_choice.to_upper())
	await DialogueManager.say("System", "// No Source Key fragments awarded. Source Key remains complete: %d / 7." % GameManager.source_key_count)
	await DialogueManager.say("SOVEREIGN", "You still believe the truth is outside you.")
	await DialogueManager.say("Kaelen", "Chapter Nine is where you finally explain why that scares you.")

func _revolt_stabilization_trial() -> void:
	if GameManager.has_flag("ch8_revolt_stabilization_cleared"):
		await DialogueManager.say("System", "// Revolt stabilization already cleared.")
		return

	var support := 0
	if GameManager.has_flag("ch8_oakhaven_request_fulfilled"):
		support += 1
	if GameManager.has_flag("ch8_ironhold_request_fulfilled"):
		support += 1
	if GameManager.has_flag("ch8_mirror_request_fulfilled"):
		support += 1

	await DialogueManager.say("Assembly Ledger", "Before Kaelen can answer leadership, three fires need triage: panic, sabotage, and competing testimony.")
	var choice = await DialogueManager.show_choices(
		"Which crisis should Kaelen personally stabilize first?",
		[
			"Set up evacuation lanes for Oakhaven's frightened families.",
			"Secure Ironhold's repair grid before it fails.",
			"Broadcast Mirror testimony so no faction controls the record."
		]
	)
	if not is_inside_tree(): return
	if choice == null or choice < 0 or choice > 2:
		choice = 2

	GameManager.set_story_flag("ch8_revolt_stabilization_cleared", true)
	_discover_lore("ch8_revolt_supply_record")
	if support >= 2:
		GameManager.add_xp(240)
		GameManager.add_gold(120)
		await DialogueManager.say("System", "// Prior faction support turns crisis into coordination. +240 XP, +120 Gold.")
	else:
		GameManager.add_xp(130)
		await DialogueManager.say("System", "// Revolt crisis contained, but low faction support leaves visible strain. +130 XP.")

	match choice:
		0:
			await DialogueManager.say("Oakhaven Survivor", "Protection first, but this time the warning comes before the screams.")
		1:
			await DialogueManager.say("Ironhold Delegate", "Structure first, but audited. We can work with that.")
		2:
			await DialogueManager.say("Mirror Witness", "Accountability first. Now no one gets to narrate the revolt alone.")


func _route_pressure() -> void:
	match _chapter4_choice_key():
		"preserve":
			await DialogueManager.say("Null Court Echo", "Preservation taught them to ask who decides when safety becomes imprisonment.")
		"release":
			await DialogueManager.say("Null Court Echo", "Release taught them freedom without preparation can still break bones.")
		"bargain":
			await DialogueManager.say("Null Court Echo", "The bargain taught them every compromise must name who benefits.")
		_:
			await DialogueManager.say("Null Court Echo", "The missing Null Court answer makes the assembly mistrust your mercy.")

	match _chapter6_choice_key():
		"silence":
			await DialogueManager.say("Cathedral Echo", "Because the Choir was silenced, some factions now demand preemptive deletion of dangerous systems.")
		"preserve":
			await DialogueManager.say("Cathedral Echo", "Because the Choir was preserved, some factions demand archives before punishment.")
		"rewrite":
			await DialogueManager.say("Cathedral Echo", "Because the Choir was rewritten, some factions believe even broken power can be repurposed.")
		_:
			await DialogueManager.say("Cathedral Echo", "Because the Cathedral outcome is unclear, factions invent their own version of it.")

	match _chapter7_choice_key():
		"preserve":
			await DialogueManager.say("Memory Tide", "Because all backups remain, the saved arrive carrying more truth than any government can easily survive.")
		"collapse":
			await DialogueManager.say("Memory Tide", "Because unstable backups collapsed, the saved argue whether safety has already become erasure.")
		"merge":
			await DialogueManager.say("Memory Tide", "Because selected histories merged, people remember enough to distrust simple slogans.")
		_:
			await DialogueManager.say("Memory Tide", "Because the backup route is unclear, rumor becomes its own faction.")

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

func _clear_exclusive_choice_flags() -> void:
	GameManager.set_story_flag("ch8_revolt_led", false)
	GameManager.set_story_flag("ch8_council_formed", false)
	GameManager.set_story_flag("ch8_witness_network_created", false)
	GameManager.set_story_flag("ending_route_ch8_lead", false)
	GameManager.set_story_flag("ending_route_ch8_council", false)
	GameManager.set_story_flag("ending_route_ch8_witness", false)

func _discover_lore(lore_id: String) -> void:
	if has_node("/root/LoreJournal") and LoreJournal.has_method("discover"):
		LoreJournal.discover(lore_id)

func _fade_to_black(duration: float) -> void:
	fade_rect.z_index = 100
	var tw := create_tween()
	tw.tween_property(fade_rect, "modulate:a", 1.0, duration)
	await tw.finished
