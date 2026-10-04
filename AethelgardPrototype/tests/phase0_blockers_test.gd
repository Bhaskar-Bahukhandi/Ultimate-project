extends SceneTree
## Phase 0 regression tests — the three playthrough blockers from
## CODE_REVIEW_2026-10-04.md:
##   C1/C2   dialogue never closed → player frozen after any region conversation
##   C9/C10  saves silently rejected during transitions / dialogue checkpoints
##   C4      Chapter 3 had no exit, so Chapter 4 could never unlock
##
## Run through tests/run_phase0_tests.ps1, which points user:// at a temp
## directory. The script refuses to run against the real user data dir, so it
## can never overwrite a player's saves (review finding C19).

const USER_DIR_MARKER := "aeth_phase0_test"
const AUTOSAVE_PATH := "user://save_slot_99.save"
const REGION_SCENE := "res://scenes/regions/fractured_wastes_region.tscn"
const ENDING_SCENE := "res://scenes/chapter10/ch10_ending.tscn"
const DATA_STREAM_SCENE := "res://scenes/chapter3/data_stream.tscn"
const CH4_INTRO_SCENE := "res://scenes/chapter4/ch4_forgotten_sectors_intro.tscn"

var _passes: int = 0
var _failures: Array[String] = []
var _driving: bool = false
var _driver_choice: int = 0


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	await process_frame
	await process_frame
	if not OS.get_user_data_dir().contains(USER_DIR_MARKER):
		push_error("Refusing to run: user data dir is not isolated (%s). Use tests/run_phase0_tests.ps1." % OS.get_user_data_dir())
		quit(2)
		return
	_clear_saves()

	await _test_dialogue_sequence_closes()
	await _test_dialogue_choice_closes()
	await _test_explicit_hide_still_single_event()
	await _test_region_npc_does_not_freeze_player()
	await _test_save_state_rules()
	await _test_save_queued_during_transition()
	await _test_reset_drops_queued_save()
	await _test_ending_is_persisted()
	await _test_ch3_server_room_gate_visibility()
	await _test_ch3_exit_reaches_chapter4()

	print("")
	print("PHASE0 RESULT: %d passed, %d failed" % [_passes, _failures.size()])
	for f in _failures:
		print("  FAIL: " + f)
	quit(0 if _failures.is_empty() else 1)


# ── helpers ───────────────────────────────────────────────────────────────

func _gm() -> Node: return get_root().get_node("GameManager")
func _dm() -> Node: return get_root().get_node("DialogueManager")
func _st() -> Node: return get_root().get_node("SceneTransitions")


func _check(cond: bool, name: String) -> void:
	if cond:
		_passes += 1
		print("  PASS: " + name)
	else:
		_failures.append(name)
		print("  FAIL: " + name)


func _wait(seconds: float) -> void:
	await create_timer(seconds).timeout


func _clear_saves() -> void:
	for slot in [0, 1, 2, 99]:
		for suffix in ["", ".bak", ".tmp"]:
			var path := "user://save_slot_%d.save%s" % [slot, suffix]
			if FileAccess.file_exists(path):
				DirAccess.remove_absolute(ProjectSettings.globalize_path(path))


func _change_scene(path: String) -> Node:
	change_scene_to_file(path)
	for i in 4:
		await process_frame
	return current_scene


## Waits (real time) until `path` is the settled current scene.
func _wait_for_scene(path: String, timeout_sec: float) -> bool:
	var deadline := Time.get_ticks_msec() + int(timeout_sec * 1000.0)
	while Time.get_ticks_msec() < deadline:
		if current_scene and current_scene.scene_file_path == path and not _st().is_transitioning:
			return true
		await process_frame
	return false


## Plays the "player": advances every line and picks _driver_choice.
func _drive_dialogue() -> void:
	while _driving:
		var dm := _dm()
		if dm._awaiting_choice:
			if dm._choice_result == -1 and dm._choice_container != null:
				dm._on_choice_pressed(_driver_choice)
		elif dm._is_visible:
			dm._skip_typing = true
			dm._advance_requested = true
		await process_frame


func _start_driver(choice: int = 0) -> void:
	_driver_choice = choice
	if not _driving:
		_driving = true
		_drive_dialogue()


func _stop_driver() -> void:
	_driving = false


func _say_lines(lines: Array) -> void:
	for line in lines:
		await _dm().say("System", line)


# ── C1/C2: dialogue closes itself ─────────────────────────────────────────

func _test_dialogue_sequence_closes() -> void:
	print("[C1] dialogue sequence closes")
	var dm := _dm()
	var finished := [0]
	var on_finished := func(): finished[0] += 1
	dm.dialogue_finished.connect(on_finished)
	_start_driver()
	await _say_lines(["first", "second", "third"])
	_check(finished[0] == 0, "box stays open between consecutive lines")
	await _wait(0.5)
	_check(not dm.is_active, "C1: is_active clears after the sequence ends")
	_check(finished[0] == 1, "exactly one dialogue_finished per sequence")
	_stop_driver()
	dm.dialogue_finished.disconnect(on_finished)


func _test_dialogue_choice_closes() -> void:
	print("[C1] choice closes")
	var dm := _dm()
	_start_driver(1)
	var result: int = await dm.show_choices("Pick one", ["a", "b", "c"])
	_check(result == 1, "show_choices returns the picked option")
	await _wait(0.5)
	_check(not dm.is_active, "dialogue closes after a choice")
	_stop_driver()


func _test_explicit_hide_still_single_event() -> void:
	print("[C1] explicit hide_dialogue() still works")
	var dm := _dm()
	var finished := [0]
	var on_finished := func(): finished[0] += 1
	dm.dialogue_finished.connect(on_finished)
	_start_driver()
	await dm.say("System", "line")
	dm.hide_dialogue()
	await _wait(0.5)
	_check(not dm.is_active and finished[0] == 1, "manual hide + auto-hide emit dialogue_finished once")
	_stop_driver()
	dm.dialogue_finished.disconnect(on_finished)


func _test_region_npc_does_not_freeze_player() -> void:
	print("[C1] region NPC conversation (the real softlock)")
	var region := await _change_scene(REGION_SCENE)
	var npc := region.get_node_or_null("SurvivorKael")
	_check(npc != null, "Fractured Wastes NPC exists")
	if npc == null:
		return
	_start_driver()
	await region._interact_npc(npc)
	await _wait(0.5)
	_check(not _dm().is_active, "C1: talking to a region NPC no longer freezes the player")
	_check(_gm().current_state == _gm().GameState.EXPLORATION, "state returns to EXPLORATION")
	_stop_driver()


# ── C9/C10/C12: saves ─────────────────────────────────────────────────────

func _test_save_state_rules() -> void:
	print("[C10/C12] save state rules")
	var gm := _gm()
	_clear_saves()
	await _change_scene(REGION_SCENE)
	gm.change_state(gm.GameState.MENU)
	_check(not gm.save_game(0), "C12: refuses to save when no game is running (MENU)")
	_check(not FileAccess.file_exists("user://save_slot_0.save"), "C12: nothing written in MENU")
	gm.change_state(gm.GameState.GAME_OVER)
	_check(not gm.save_game(99), "refuses to save in GAME_OVER")
	gm.change_state(gm.GameState.DIALOGUE)
	_check(gm.auto_save(), "C10: autosave checkpoint works mid-dialogue")
	_check(FileAccess.file_exists(AUTOSAVE_PATH), "C10: checkpoint file written")
	gm.change_state(gm.GameState.COMBAT)
	_check(not gm.quick_save(), "player quick-save still refused mid-combat")
	gm.change_state(gm.GameState.EXPLORATION)


func _test_save_queued_during_transition() -> void:
	print("[C9] save requested during a transition is queued, not dropped")
	var gm := _gm()
	var st := _st()
	_clear_saves()
	gm.change_state(gm.GameState.EXPLORATION)
	st.is_transitioning = true
	_check(not gm.save_game(99), "save is not written mid-transition")
	_check(not FileAccess.file_exists(AUTOSAVE_PATH), "no file yet")
	st.is_transitioning = false
	st.transition_completed.emit()
	_check(FileAccess.file_exists(AUTOSAVE_PATH), "C9: queued save written when the transition completes")


func _test_reset_drops_queued_save() -> void:
	print("[C9] New Game drops saves queued by the previous run")
	var gm := _gm()
	var st := _st()
	_clear_saves()
	gm.change_state(gm.GameState.EXPLORATION)
	st.is_transitioning = true
	gm.save_game(99)
	st.is_transitioning = false
	gm.reset_game()
	gm.change_state(gm.GameState.EXPLORATION)
	st.transition_completed.emit()
	_check(not FileAccess.file_exists(AUTOSAVE_PATH), "reset_game() clears the save queue")


func _test_ending_is_persisted() -> void:
	print("[C9] the true ending is written to disk (real scene transition)")
	var gm := _gm()
	_clear_saves()
	gm.change_state(gm.GameState.EXPLORATION)
	_st().change_scene(ENDING_SCENE)
	var arrived := await _wait_for_scene(ENDING_SCENE, 15.0)
	await _wait(0.3)
	_check(arrived, "ending scene loaded")
	_check(FileAccess.file_exists(AUTOSAVE_PATH), "C9: ending autosave exists")
	if FileAccess.file_exists(AUTOSAVE_PATH):
		var data = JSON.parse_string(FileAccess.get_file_as_string(AUTOSAVE_PATH))
		var flags: Dictionary = data.get("story_flags", {}) if data is Dictionary else {}
		_check(flags.get("ch10_complete", false), "C9: ch10_complete persisted")
		_check(flags.get("ng_plus_unlocked", false), "C9: NG+ unlock persisted")
		_check(data.get("current_scene", "") == ENDING_SCENE, "save points at the ending scene")


# ── C4: Chapter 3 → Chapter 4 ─────────────────────────────────────────────

func _test_ch3_server_room_gate_visibility() -> void:
	print("[C4] Server Room gate visibility")
	var gm := _gm()
	gm.reset_game()
	gm.set_story_flag("ch2_data_wraith_defeated", false)
	var region := await _change_scene(REGION_SCENE)
	_check(region.get_node_or_null("ServerRoomGate") == null, "gate hidden before the Data Wraith is defeated")
	gm.set_story_flag("ch2_data_wraith_defeated", true)
	gm.set_story_flag("ch3_fragment_3_collected", true)
	region = await _change_scene(REGION_SCENE)
	_check(region.get_node_or_null("ServerRoomGate") == null, "gate hidden once fragment #3 is taken")
	gm.set_story_flag("ch3_fragment_3_collected", false)
	region = await _change_scene(REGION_SCENE)
	_check(region.get_node_or_null("ServerRoomGate") != null, "gate shown after the Data Wraith, before fragment #3")


func _test_ch3_exit_reaches_chapter4() -> void:
	print("[C4] Chapter 3 exit → Chapter 4 (bot drives dialogue, picks option 0)")
	var gm := _gm()
	var region := current_scene
	var gate := region.get_node_or_null("ServerRoomGate")
	if gate == null:
		_check(false, "gate available for the end-to-end run")
		return
	Engine.time_scale = 4.0  # The data stream is a 45 s timed ride
	_start_driver(0)
	region._interact_story(gate)
	_check(gm.has_flag("ch3_server_room_unlocked"), "entering the gate records ch3_server_room_unlocked")
	var reached_stream := await _wait_for_scene(DATA_STREAM_SCENE, 60.0)
	_check(gm.has_flag("ch3_fragment_3_collected") and gm.has_flag("source_key_fragment_3"), "fragment #3 / Source Key 3 granted")
	_check(reached_stream, "chapter continues into the Data Stream")
	var reached_ch4 := false
	if reached_stream:
		reached_ch4 = await _wait_for_scene(CH4_INTRO_SCENE, 600.0)
	var where: String = current_scene.scene_file_path if current_scene else "<none>"
	_check(reached_ch4, "C4: chain reaches Chapter 4 (stopped at %s)" % where)
	_check(gm.has_flag("ch4_unlocked") and gm.current_chapter == 4, "C4: ch4_unlocked set and current_chapter == 4")
	_stop_driver()
	Engine.time_scale = 1.0
