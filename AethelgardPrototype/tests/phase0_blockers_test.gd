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
	await _test_skip_never_answers_choices()
	await _test_pause_blocked_during_cutscene()
	await _test_region_npc_does_not_freeze_player()
	await _test_save_state_rules()
	await _test_corrupt_save_recovery()
	await _test_save_queued_during_transition()
	await _test_reset_drops_queued_save()
	await _test_ending_is_persisted()
	await _test_new_game_route_reaches_elara_and_oakhaven()
	await _test_stale_handoffs_are_discarded()
	await _test_clock_tower_floors_are_climbable()
	await _test_underground_boss_chamber_is_enterable()
	await _test_ch3_server_room_gate_visibility()
	await _test_ch3_exit_reaches_chapter4()
	await _test_combat_softlocks()

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


func _test_skip_never_answers_choices() -> void:
	print("[C13] skipping dialogue never answers a choice")
	var dm := _dm()
	var state := {"result": -2}
	var scene := func():
		await dm.say("System", "a line the player skips")
		await dm.say("System", "another skipped line")
		state["result"] = await dm.show_choices("…and then a story choice", ["a", "b", "c"])
	scene.call()
	await _wait(0.3)  # first line is on screen
	dm.skip_all()     # the player skips the conversation (ESC ESC / hold TAB)
	await _wait(1.2)
	_check(state["result"] == -2 and dm._awaiting_choice, "C13: choice is shown and waits after a skip")
	dm.skip_all()  # skipping again while the choice is open (TAB hold / ESC)
	await _wait(0.5)
	_check(state["result"] == -2 and dm._awaiting_choice, "C13: a skip during an open choice does not pick for the player")
	dm._on_choice_pressed(2)
	await _wait(0.3)
	_check(state["result"] == 2, "the player's own pick is returned")
	await _wait(0.5)
	_check(not dm.is_active, "dialogue closes after the choice")


func _press_pause(pause: Node) -> void:
	var ev := InputEventAction.new()
	ev.action = "pause_menu"
	ev.pressed = true
	pause._input(ev)


func _test_pause_blocked_during_cutscene() -> void:
	print("[C12] pause menu stays closed while a cutscene plays")
	var pause := get_root().get_node("PauseScreen")
	_dm().force_reset()
	# Minimal scene with a CutsceneManager child, like every cutscene scene.
	var fake_cm_script := GDScript.new()
	fake_cm_script.source_code = "extends Node\nvar is_playing := true\n"
	fake_cm_script.reload()
	var scene := Node2D.new()
	var cm := Node.new()
	cm.set_script(fake_cm_script)
	cm.name = "CutsceneManager"
	scene.add_child(cm)
	get_root().add_child(scene)
	current_scene = scene
	pause.set_meta("cutscene_blocked", true)
	_press_pause(pause)
	_check(not pause.is_paused, "C12: ESC does not open pause while the scene's cutscene is playing")
	cm.set("is_playing", false)
	_press_pause(pause)
	_check(pause.is_paused, "pause opens once the cutscene has finished (stale block cleared)")
	if pause.is_paused:
		pause.toggle_pause()
	paused = false


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


func _write_text(path: String, text: String) -> void:
	var f := FileAccess.open(path, FileAccess.WRITE)
	f.store_string(text)
	f.close()


func _test_corrupt_save_recovery() -> void:
	print("[C11] corrupt saves are reported and recovered, never spread to the backup")
	var gm := _gm()
	const SLOT1 := "user://save_slot_1.save"
	_clear_saves()
	await _change_scene(REGION_SCENE)
	gm.change_state(gm.GameState.EXPLORATION)
	_check(gm.save_game(1), "save to slot 1")
	_check(gm._read_valid_save(SLOT1) != null, "a fresh save validates (checksum round-trip)")
	gm.save_game(1)  # second save → first becomes the backup
	_check(gm._read_valid_save(SLOT1 + ".bak") != null, "backup is a valid save")
	var good_backup := FileAccess.get_file_as_string(SLOT1 + ".bak")

	_write_text(SLOT1, "{ \"version\": \"1.2.0\", \"player_st")  # truncated write
	var info: Dictionary = gm.get_save_info(1)
	_check(info.get("exists", false) and info.get("corrupt", false) and info.get("backup_valid", false),
		"C11: damaged save is reported as corrupt (backup available), not as Empty")
	gm.save_game(1)
	_check(FileAccess.get_file_as_string(SLOT1 + ".bak") == good_backup,
		"C11: saving over a damaged file does not overwrite the good backup")

	_write_text(SLOT1, "{ truncated")
	var loaded: bool = await gm.load_game(1)
	_check(loaded, "C11: load recovers from the backup when the main file is damaged")
	_check(gm._read_valid_save(SLOT1) != null and FileAccess.file_exists(SLOT1 + ".corrupted"),
		"restored file is valid; damaged copy kept as .corrupted")

	var tampered: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(SLOT1))
	tampered["current_chapter"] = int(tampered.get("current_chapter", 1)) + 5  # edited without updating the checksum
	_write_text(SLOT1, JSON.stringify(tampered, "\t"))
	_check(gm._read_valid_save(SLOT1) == null, "checksum mismatch marks the save invalid")

	DirAccess.remove_absolute(ProjectSettings.globalize_path(SLOT1 + ".bak"))
	_write_text(SLOT1, "{ truncated")
	info = gm.get_save_info(1)
	_check(info.get("corrupt", false) and not info.get("backup_valid", true), "corrupt save without backup is reported as such")
	loaded = await gm.load_game(1)
	_check(not loaded, "load of an unrecoverable save fails (no silent fresh start)")
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


# ── C3: New Game route ────────────────────────────────────────────────────

const HOOK_SCENE := "res://scenes/chapter1/opening_crash_site_hook.tscn"
const ELARA_SCENE := "res://scenes/chapter1/elara_meeting.tscn"
const PATH_SCENE := "res://scenes/chapter1/path_to_oakhaven.tscn"
const VILLAGE_SCENE := "res://scenes/chapter1/oakhaven_village.tscn"
const OAKHAVEN_REGION_SCENE := "res://scenes/regions/oakhaven_region.tscn"

var _next_bridge_poke_ms: int = 0

## Does what a player would do in scenes that wait on non-dialogue input.
func _ch1_poke() -> void:
	var s := current_scene
	if s == null or _st().is_transitioning:
		return
	var p := s.scene_file_path
	if p == PATH_SCENE and s.get("root_access_tutorial_active") and not s.get("slime_hacked"):
		var spin = s.get("elasticity_spinbox")
		if spin:
			spin.value = 0.0  # the tutorial's intended answer
		s._on_root_access_apply()
	elif p == VILLAGE_SCENE and not s.get("in_dialogue") and Time.get_ticks_msec() >= _next_bridge_poke_ms:
		_next_bridge_poke_ms = Time.get_ticks_msec() + 1000
		var player := s.get_node_or_null("Player")
		if player:
			s._on_bridge_trigger(player)  # walk onto the bridge


func _wait_for_scene_poking(path: String, timeout_sec: float) -> bool:
	var deadline := Time.get_ticks_msec() + int(timeout_sec * 1000.0)
	while Time.get_ticks_msec() < deadline:
		if current_scene and current_scene.scene_file_path == path and not _st().is_transitioning:
			return true
		_ch1_poke()
		await process_frame
	return false


func _test_new_game_route_reaches_elara_and_oakhaven() -> void:
	print("[C3] New Game: opening hook → Elara → path → village → Oakhaven (bot picks 'trust')")
	var gm := _gm()
	gm.reset_game()
	var hook := await _change_scene(HOOK_SCENE)
	_check(hook != null and hook.scene_file_path == HOOK_SCENE, "opening hook loads")
	Engine.time_scale = 4.0
	_start_driver(0)
	hook._complete_opening_hook()  # the player reached the road east
	_check(await _wait_for_scene_poking(ELARA_SCENE, 30.0), "C3: opening hook continues into the Elara meeting")
	_check(await _wait_for_scene_poking(PATH_SCENE, 240.0), "Elara meeting continues to the path to Oakhaven")
	_check(gm.has_flag("ch1_elara_trusted"), "C3: Elara choice recorded (ch1_elara_trusted)")
	_check(await _wait_for_scene_poking(VILLAGE_SCENE, 300.0), "path continues to Oakhaven village")
	_check(gm.has_flag("ch1_data_vision_unlocked"), "C3: Data Vision unlocked on the New Game route")
	_check(gm.has_flag("root_access_unlocked"), "C3: Root Access unlocked on the New Game route")
	var reached := await _wait_for_scene_poking(OAKHAVEN_REGION_SCENE, 300.0)
	var where: String = current_scene.scene_file_path if current_scene else "<none>"
	_check(reached, "village continues to the Oakhaven region (stopped at %s)" % where)
	_check(gm.has_flag("ch1_oakhaven_entered"), "C3: ch1_oakhaven_entered set (objective tracker can advance)")
	_stop_driver()
	Engine.time_scale = 1.0


# ── Scene hand-off leaks (return_position / boss_fight_id) ───────────────

const IRONHOLD_REGION_SCENE := "res://scenes/regions/ironhold_region.tscn"

func _test_stale_handoffs_are_discarded() -> void:
	print("[META] stale return points and boss context don't leak into other scenes")
	var gm := _gm()
	gm.reset_game()
	# Oakhaven's Tutorial Knight gate leaves these behind; the story then goes
	# knight → shatter → Ironhold and never returns to Oakhaven.
	gm.set_return_point(OAKHAVEN_REGION_SCENE, Vector2(2800, 500))
	gm.set_meta("boss_fight_id", "tutorial_knight")
	gm.set_meta("boss_return_scene", OAKHAVEN_REGION_SCENE)
	var region := await _change_scene(IRONHOLD_REGION_SCENE)
	var player: Node2D = region.get("_player")
	_check(player != null and player.global_position.distance_to(Vector2(2800, 500)) > 1.0,
		"first Ironhold arrival ignores Oakhaven's return point")
	_check(not gm.has_meta("return_position") and not gm.has_meta("boss_fight_id"),
		"stale return point and boss_fight_id are cleared on arrival (fleeing works again)")
	gm.set_return_point(IRONHOLD_REGION_SCENE, Vector2(1234, 1111))
	region = await _change_scene(IRONHOLD_REGION_SCENE)
	player = region.get("_player")
	_check(player != null and player.global_position.distance_to(Vector2(1234, 1111)) < 1.0,
		"a return point meant for this scene is still applied")
	gm.set_meta("boss_fight_id", "x")
	gm.reset_game()
	_check(not gm.has_meta("boss_fight_id"), "New Game clears hand-off metas")


# ── C5/C6: Chapter 2 dungeons are traversable ─────────────────────────────

const CLOCK_TOWER_SCENE := "res://scenes/chapter2/clock_tower.tscn"
const UNDERGROUND_SCENE := "res://scenes/chapter2/underground_network.tscn"

func _physics_frames(n: int) -> void:
	for i in n:
		await physics_frame


func _test_clock_tower_floors_are_climbable() -> void:
	print("[C5] Clock Tower: jump from the floor-1 step up through floor 2")
	_gm().reset_game()
	var tower := await _change_scene(CLOCK_TOWER_SCENE)
	_start_driver()
	await _wait(6.0)  # entry dialogue + boss-intro input lock
	_stop_driver()
	var player: CharacterBody2D = tower.get_node("Player")
	var floor2_top: float = tower.FLOOR_Y[2]
	# Stand on the upper step below floor 2 (top at FLOOR_Y[2] + 60), then jump.
	player.global_position = Vector2(300, floor2_top + 60 - 17)
	player.velocity = Vector2.ZERO
	await _physics_frames(10)
	player.velocity = Vector2(0, -560)  # player_combat JUMP_VELOCITY
	await _physics_frames(90)
	_check(player.global_position.y < floor2_top and player.is_on_floor(),
		"C5: player passes up through floor 2 and stands on it (y=%.0f, floor top %.0f)" % [player.global_position.y, floor2_top])
	var cam := player.get_node_or_null("Camera2D")
	_check(cam != null, "camera follows the player in the Clock Tower")


func _test_underground_boss_chamber_is_enterable() -> void:
	print("[C6] Underground: walk from the final corridor into the boss chamber")
	_gm().reset_game()
	var dungeon := await _change_scene(UNDERGROUND_SCENE)
	_start_driver()
	await _wait(4.0)  # entry dialogue
	_stop_driver()
	var player: CharacterBody2D = dungeon.get_node("Player")
	player.global_position = Vector2(2300, 400 - 17)  # on the corridor floor
	player.velocity = Vector2.ZERO
	await _physics_frames(10)
	Input.action_press("move_right")
	await _physics_frames(120)
	Input.action_release("move_right")
	_check(player.global_position.x > 2440, "C6: corridor leads into the boss chamber (x=%.0f)" % player.global_position.x)
	player.global_position = Vector2(500, 500 - 17)  # entry corridor
	await _physics_frames(10)
	Input.action_press("move_right")
	await _physics_frames(90)
	Input.action_release("move_right")
	_check(player.global_position.x > 640, "entry corridor leads into the first chamber (x=%.0f)" % player.global_position.x)
	_check(player.get_node_or_null("Camera2D") != null, "camera follows the player in the Underground")

	print("[C18] player can still move with the ColorRect fallback (no art)")
	var art := player.get_node_or_null("Sprite")
	if art:
		player.remove_child(art)
		art.queue_free()
	var fallback := ColorRect.new()
	fallback.name = "Sprite"
	fallback.size = Vector2(32, 48)
	player.add_child(fallback)
	player.set("_sprite", fallback)
	player.global_position = Vector2(150, 500 - 17)
	await _physics_frames(10)
	var start_x := player.global_position.x
	Input.action_press("move_left")
	await _physics_frames(30)
	Input.action_release("move_left")
	_check(player.global_position.x < start_x - 20.0,
		"C18: moving left works when the Sprite is a ColorRect (dx=%.0f)" % (player.global_position.x - start_x))

	print("[P1-1] DEF reduces incoming damage")
	var pc_script = load("res://scripts/combat/player_combat.gd")
	_check(is_equal_approx(pc_script.mitigate_by_defense(100.0, 0.0), 100.0)
		and is_equal_approx(pc_script.mitigate_by_defense(100.0, 100.0), 50.0),
		"P1-1: formula — 0 DEF full damage, 100 DEF half")
	var gm := _gm()
	gm.player_stats["defense"] = 100
	player.set("invulnerable", false)
	player.set("parry_active", false)
	player.set("is_defending", false)
	var hp_before: float = player.get("current_health")
	player.take_damage(40.0)
	var expected: float = 40.0 * gm.get_enemy_damage_mult() * 0.5
	var taken: float = hp_before - float(player.get("current_health"))
	_check(absf(taken - expected) < 0.01, "P1-1: a hit at 100 DEF deals half damage (took %.2f, expected %.2f)" % [taken, expected])
	gm.player_stats["defense"] = 0

	print("[ECON] MP for spells/heal, Soul from parries / perfect dodges / kills")
	_check(not pc_script.get_script_constant_map().has("SOUL_PER_HIT"), "Soul is no longer gained per hit")
	gm.player_stats["max_mp"] = 50
	gm.player_stats["mp"] = 0
	await _physics_frames(60)
	var regen: float = float(gm.player_stats["mp"])
	_check(regen > 1.0 and regen < 3.0, "MP regenerates ~2/s (got %.2f after 1 s)" % regen)
	gm.player_stats["mp"] = 50
	player.set("cast_lock_timer", 0.0)
	Input.action_press("spell")
	await _physics_frames(2)
	Input.action_release("spell")
	await _physics_frames(2)
	var after_cast: float = float(gm.player_stats["mp"])
	_check(after_cast <= 50.0 - 15.0 + 0.5, "a spell costs 15 MP (MP now %.1f)" % after_cast)
	var soul0: float = player.get("current_soul")
	player.on_enemy_killed()
	_check(float(player.get("current_soul")) >= soul0 + 10.0 - 0.01, "a kill earns Soul")
	var soul1: float = player.get("current_soul")
	var hp1: float = player.get("current_health")
	player.set("is_dashing", true)
	player.set("invulnerable", true)
	player.set("_perfect_dodge_awarded", false)
	player.take_damage(25.0)
	player.take_damage(25.0)
	_check(float(player.get("current_soul")) >= soul1 + 15.0 - 0.01 and float(player.get("current_soul")) < soul1 + 30.0 - 0.01,
		"a hit during dash i-frames is a perfect dodge: Soul once per dash")
	_check(float(player.get("current_health")) == hp1, "perfect dodge takes no damage")
	player.set("is_dashing", false)


# ── C15/C16/C17: combat softlocks ─────────────────────────────────────────

const ARENA_SCENE := "res://scenes/combat/combat_arena.tscn"

func _test_combat_softlocks() -> void:
	var gm := _gm()
	gm.reset_game()
	var arena := await _change_scene(ARENA_SCENE)
	_start_driver()  # tutorial/ambush lines

	print("[C17] Root Access limits")
	var probe = load("res://scripts/combat/enemies/slime.gd").new()
	probe.position = Vector2(640, 500)
	var probe_shape := CollisionShape2D.new()  # spawners add one; a bare script instance has none
	var probe_rect := RectangleShape2D.new()
	probe_rect.size = Vector2(28, 24)
	probe_shape.shape = probe_rect
	probe.add_child(probe_shape)
	arena.add_child(probe)
	await _physics_frames(2)
	probe.apply_hack("gravity_scale", 0.0)
	_check(probe.gravity_scale >= 0.2, "C17: gravity hack can't go to 0 (got %.2f)" % probe.gravity_scale)
	probe.add_to_group("boss")
	_check(not probe.get_hackable_properties().has("current_health"), "C17: bosses don't expose HP to Root Access")
	var hp_before: float = probe.current_health
	probe.apply_hack("current_health", 0.0)
	_check(probe.current_health == hp_before, "C17: boss HP can't be set by a hack")
	probe.remove_from_group("boss")

	print("[C15] phase spider comes down from the ceiling")
	var spider = load("res://scripts/combat/enemies/phase_spider.gd").new()
	spider.position = Vector2(900, 500)
	arena.add_child(spider)
	await _physics_frames(2)
	spider.set("_is_on_ceiling", true)
	spider.set("_phase_timer", 1.0)
	spider._ai_behavior(1.0 / 60.0)
	_check(spider.get("_is_dropping"), "C15: a spider on the ceiling starts its drop attack")

	print("[C16] arena walls and enemy kill zone")
	_check(arena.get_node_or_null("EnemyKillZone") != null and arena.get_node_or_null("ArenaWall") != null,
		"C16: arena has walls and an enemy kill zone")
	probe.global_position = Vector2(640, 1150)
	probe.velocity = Vector2.ZERO
	await _physics_frames(20)
	# Look the enum up at runtime: naming EnemyBase here would compile enemy_base.gd
	# before the autoloads exist (--script mode) and break every enemy in the run.
	var dead_state: int = load("res://scripts/combat/enemy_base.gd").State.DEAD
	_check(not is_instance_valid(probe) or probe.current_state == dead_state,
		"C16: an enemy that falls out of the arena dies (the fight can end)")
	_stop_driver()


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
