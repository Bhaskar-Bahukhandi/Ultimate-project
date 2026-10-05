extends SceneTree
## Plays Chapter 2 end to end on the rewritten dialogue (dialogue/ch2):
## gate → region → Command Hall → Rem → convoy → Clock Tower → Underground →
## Administrator Proxy → Fragment Two / Seraphina decides → Act 1 end → Chapter 3.
## Combat itself is skipped (the arena bracket and boss deaths are called
## directly); everything around it is real. A fake player answers choices
## from a pick list (default: first option).
## Run: tests/run_phase0_tests.ps1 -Script res://tests/chapter2_route_test.gd

const GATE := "res://scenes/chapter2/ironhold_gate.tscn"
const REGION := "res://scenes/regions/ironhold_region.tscn"
const HALL := "res://scenes/chapter2/seraphina_encounter.tscn"
const TOWER := "res://scenes/chapter2/clock_tower.tscn"
const UNDER := "res://scenes/chapter2/underground_network.tscn"
const PROXY := "res://scenes/chapter2/administrator_boss.tscn"
const CHOICE := "res://scenes/chapter2/seraphina_choice.tscn"
const ENDING := "res://scenes/chapter2/ch2_ending.tscn"
const CH3 := "res://scenes/chapter3/ironhold_departure.tscn"

var _passes := 0
var _failures: Array[String] = []
var _driving := false
var _picks: Array = []
var _seen_text: Array[String] = []


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	await process_frame
	await process_frame
	if not OS.get_user_data_dir().contains("aeth_phase0_test"):
		push_error("Refusing to run: user data dir is not isolated. Use tests/run_phase0_tests.ps1.")
		quit(2)
		return
	Engine.time_scale = 4.0
	await _test_careful_route()
	await _test_reckless_route()
	Engine.time_scale = 1.0
	print("")
	print("CH2 RESULT: %d passed, %d failed" % [_passes, _failures.size()])
	for f in _failures:
		print("  FAIL: " + f)
	quit(0 if _failures.is_empty() else 1)


func _check(cond: bool, name: String) -> void:
	if cond:
		_passes += 1
		print("  PASS: " + name)
	else:
		_failures.append(name)
		print("  FAIL: " + name)


func _gm() -> Node: return get_root().get_node("GameManager")
func _dm() -> Node: return get_root().get_node("DialogueManager")


func _drive() -> void:
	var dm := _dm()
	while _driving:
		if dm._is_visible and dm._text_label and dm._text_label.text != "":
			var line: String = "%s: %s" % [dm._speaker_label.text, dm._text_label.text]
			if _seen_text.is_empty() or _seen_text.back() != line:
				_seen_text.append(line)
		if dm._awaiting_choice:
			if dm._choice_result == -1 and dm._choice_container != null:
				dm._on_choice_pressed(_picks.pop_front() if not _picks.is_empty() else 0)
		elif dm._is_visible:
			dm._skip_typing = true
			dm._advance_requested = true
		await process_frame


func _start(picks: Array) -> void:
	_picks = picks.duplicate()
	if not _driving:
		_driving = true
		_drive()


func _saw(fragment: String) -> bool:
	return _seen_text.any(func(l): return l.contains(fragment))


func _wait_for(path: String, timeout_sec: float = 90.0) -> bool:
	var deadline := Time.get_ticks_msec() + int(timeout_sec * 1000.0)
	while Time.get_ticks_msec() < deadline:
		var s := current_scene
		if s and s.scene_file_path == path and not get_root().get_node("SceneTransitions").is_transitioning:
			for i in 3:
				await process_frame
			return true
		# The chapter-end card waits for a key: press it.
		if s and s.scene_file_path == ENDING and s.get("end_card_visible"):
			s.skip_timer = true
		await process_frame
	return false


func _region_idle(region: Node, timeout_sec: float = 60.0) -> void:
	var deadline := Time.get_ticks_msec() + int(timeout_sec * 1000.0)
	await process_frame
	while region._city_busy and Time.get_ticks_msec() < deadline:
		await process_frame


func _talk(region: Node, npc_name: String) -> void:
	var npc := region.get_node_or_null(npc_name.replace(" ", ""))
	_check(npc != null, "%s is in Ironhold" % npc_name)
	if npc:
		region._interact_npc(npc)
		await _region_idle(region)


func _enter_gate(region: Node, gate_name: String) -> bool:
	var gate := region.get_node_or_null(gate_name)
	if gate == null:
		return false
	if gate_name == "AdminBossGate":
		region._interact_boss(gate)
	else:
		region._interact_story(gate)
	return true


func _arrive_from_chapter_1() -> void:
	var gm := _gm()
	gm.reset_game()
	_seen_text.clear()
	for f in ["ch1_complete", "ch1_elara_trusted", "elara_trust_high", "ch1_tutorial_knight_defeated", "ch1_bridge_saved", "root_access_unlocked"]:
		gm.set_story_flag(f, true)
	gm.collect_source_key(1)
	gm.player_stats["level"] = 12   # skip the soft level warnings at boss gates


func _test_careful_route() -> void:
	print("[Ironhold, carefully: the truth, the convoy first, rescue now, restore]")
	var gm := _gm()
	await _arrive_from_chapter_1()
	_start([])   # every choice: the first option
	change_scene_to_file(GATE)
	_check(await _wait_for(REGION, 120.0), "the gate scene leads into the Ironhold region")
	_check(_saw("We died together.") and _saw("That line works better without a sword") and gm.has_flag("ch2_seraphina_met"),
		"Seraphina recognises Kaelen at the convoy (ironhold_arrival.dlg)")
	_check(not _saw("72") and not _saw("Authorization Token"), "the old forged-token gate and 72-hour countdown are gone")
	var region := current_scene

	await _talk(region, "Rook")
	_check(_saw("Buy low.") and gm.has_flag("ch2_market_visited"), "Rook's market lesson")
	_check(_enter_gate(region, "CommandHallGate"), "the Command Hall gate is open after meeting Seraphina")
	_check(await _wait_for(HALL), "Command Hall scene")
	_check(await _wait_for(REGION), "back to the region after the Command Hall")
	_check(gm.has_flag("ch2_seraphina_truth") and gm.has_flag("ch2_command_hall_done") and _saw("I'm still holding a spear."),
		"the truth is told in the Command Hall; the arena trial is offered")
	region = current_scene

	await _talk(region, "Rem")
	_check(gm.has_flag("ch2_medicine_quest_active") and region.has_node("WestRoadGate"), "Rem's convoy job opens the west road right away")
	_enter_gate(region, "WestRoadGate")
	await _region_idle(region)
	_check(gm.has_flag("ch2_medicine_done") and gm.has_flag("ch2_medicine_early") and _saw("I stopped at one hundred and eighty-six."),
		"the convoy, delivered early; told the truth, Seraphina says 186")

	gm.set_story_flag("ch2_arena_bronze_complete", true)   # (arena combat not under test)
	region._place_story_gates()
	_check(_enter_gate(region, "ClockTowerGate"), "the Clock Tower opens after the arena's bronze bracket")
	_check(await _wait_for(TOWER, 120.0), "the bell rings thirteen times; up the tower")
	_check(gm.has_flag("ch2_tower_bell_stopped") and not gm.has_flag("ch2_medicine_late") and _saw("Thirteen."), "the bell, with the medicine already in")
	current_scene._on_automaton_defeated()
	_check(await _wait_for(REGION, 120.0), "the Minute Hand falls; back to the region")
	_check(gm.has_flag("ch2_shift_rescue_now") and gm.has_flag("ch2_underground_unlocked") and _saw("Forty people."),
		"the missing shift: rescue now; the tunnels open")
	region = current_scene

	_enter_gate(region, "UndergroundGate")
	_check(await _wait_for(UNDER, 60.0), "down into the Underground")
	var under := current_scene
	under._on_wraith_approach(under.player_node)
	var deadline := Time.get_ticks_msec() + 60000
	while not _saw("That sounded like you.") and Time.get_ticks_msec() < deadline:
		await process_frame
	_check(_saw("HANNA.") and not _saw("MARA."), "the Wraith speaks through the lights, with a worker's name, not Mara's")
	under._on_data_wraith_defeated()
	_check(await _wait_for(REGION, 120.0), "the Wraith choice, then back up")
	_check(gm.has_flag("ch2_data_wraith_restored") and gm.has_flag("ch2_data_wraith_defeated") and _saw("My name's Iven."),
		"restore: Iven wakes, and the legacy flags are set")
	_check(gm.source_key_count == 1, "Fragment Two isn't handed out by the Wraith any more")
	region = current_scene

	_check(_enter_gate(region, "AdminBossGate"), "the Administrator Proxy is reachable once the tunnels are clear")
	_check(await _wait_for(PROXY, 60.0), "the Proxy's chamber")
	deadline = Time.get_ticks_msec() + 60000
	while current_scene.get("boss_node") == null and Time.get_ticks_msec() < deadline:
		await process_frame
	_check(_saw("ACCEPTABLE CENTRALIZATION COST.") and _saw("Break it."), "C2-S14 plays before the fight")
	current_scene._on_boss_defeated()
	_check(await _wait_for(CHOICE, 120.0), "Proxy down → the source chamber")
	_check(await _wait_for(ENDING, 180.0), "Fragment Two, the wall, Seraphina decides → Act 1 end")
	_check(gm.has_flag("source_key_fragment_2") and gm.source_key_count == 2, "Fragment Two is awarded once (count = 2)")
	_check(_saw("Don't apologise for the crash unless you remember causing it."), "the Flight 707 wall scene plays")
	_check(gm.has_flag("ch2_city_stable") and gm.has_flag("ch2_seraphina_recruited") and gm.has_flag("ch2_seraphina_bond_marker"),
		"a stable city and a trusted Kaelen: Seraphina comes along (legacy marker set)")
	_check(await _wait_for(CH3, 120.0), "Act 1 end → Chapter 3")
	_check(gm.has_flag("act1_report_local") and gm.has_flag("act1_pace_early") and gm.has_flag("ch2_complete"),
		"the report and the road are recorded; Chapter 2 complete")
	_check(_saw("You say that like the sky's pointing.") and not gm.has_flag("ch2_sovereign_revealed"),
		"Act 1 ends on the sky seam, with no early SOVEREIGN reveal")
	_driving = false


func _test_reckless_route() -> void:
	print("[Ironhold, recklessly: show off, skip the convoy, seal the tunnels, destroy]")
	var gm := _gm()
	await _arrive_from_chapter_1()
	# Command Hall: show off (2). Tower warning: go up anyway (1). Missing
	# shift: seal it (2). Wraith: destroy (1). Report: archive (1). Road: safe (1).
	_start([2, 1, 2, 1, 1, 1])
	change_scene_to_file(GATE)
	_check(await _wait_for(REGION, 120.0), "reckless: into the region")
	var region := current_scene
	_enter_gate(region, "CommandHallGate")
	_check(await _wait_for(REGION, 90.0), "reckless: through the Command Hall")
	_check(gm.has_flag("ch2_seraphina_showoff") and _saw("It sounds similar from the outside."), "showing off worries Seraphina")
	region = current_scene
	gm.set_story_flag("ch2_arena_bronze_complete", true)
	region._place_story_gates()
	_enter_gate(region, "ClockTowerGate")
	_check(await _wait_for(TOWER, 120.0), "warned about the convoy, goes up anyway")
	_check(_saw("When that tower rings again, the gates close behind it.") and gm.has_flag("ch2_medicine_late"),
		"the deadline was signposted, and missing it makes the medicine late")
	current_scene._on_automaton_defeated()
	_check(await _wait_for(REGION, 120.0), "reckless: back from the tower")
	_check(gm.has_flag("ch2_shift_sealed") and _saw("a whole night to get worse"), "sealing the tunnels costs Seraphina's trust")
	_enter_gate(current_scene, "UndergroundGate")
	_check(await _wait_for(UNDER, 60.0), "reckless: the Underground")
	current_scene._on_data_wraith_defeated()
	_check(await _wait_for(REGION, 120.0), "reckless: the Wraith ended")
	_check(gm.has_flag("ch2_data_wraith_destroyed") and _saw("It's still the answer."), "destroy")
	_enter_gate(current_scene, "AdminBossGate")
	_check(await _wait_for(PROXY, 60.0), "reckless: the Proxy")
	var deadline := Time.get_ticks_msec() + 60000
	while current_scene.get("boss_node") == null and Time.get_ticks_msec() < deadline:
		await process_frame
	_check(_saw("The arena medics came instead."), "a late convoy changes who's in the Proxy fight")
	current_scene._on_boss_defeated()
	_check(await _wait_for(ENDING, 240.0), "reckless: to the Act 1 end")
	_check(gm.has_flag("seraphina_trust_low") and gm.has_flag("ch2_seraphina_rejected") and _saw("I don't believe following you is the same thing as solving it."),
		"lost trust: Seraphina refuses to follow Kaelen")
	_check(await _wait_for(CH3, 120.0), "reckless: on to Chapter 3")
	_check(gm.has_flag("act1_report_archive") and gm.has_flag("act1_pace_on_time") and _saw("I hope I'm wrong about you."),
		"the archive report, the safe road, and Seraphina's parting line")
	_driving = false
