extends SceneTree
## Tests for story Y1-P0-T14a (production/epics/y1-p0-stabilize/story-t14a-playthrough-ch3-to-credits.md, ACs AC-1..AC-6):
## a bot that plays the game headless from Chapter 3's first scene (ironhold_departure) through the Fractured Wastes
## region gate, Chapters 3-10 and the three hazard trials to the ending, the main menu with NEW GAME+, and the credits
## screen. T14b later extends it with the Chapter 1 fight legs (New Game -> credits).
##
## LEGS is the leg table (production/qa/evidence/2026-10-playthrough/leg_table.md): [scene, kind, flags set by the time
## the scene hands off]. One list drives the order check, the per-leg flag check and the log. Kinds: "story" (dialogue
## only), "region" (walk to the Wastes' ServerRoomGate and use it), "input" (ch3_ending waits for a key press),
## "trial" (a late-game hazard trial), "ending" (ch10_ending), then the main menu.
##
## DRIVER. Every frame: an open choice -> option 0 once its buttons are focusable (DialogueManager enables them after its
## 0.5 s grace period, so the bot answers no sooner than a player could; logged with the prompt and the option's text),
## else active dialogue -> DialogueManager.skip_all() (show_choices clears the skip, so it is re-armed every frame it is
## needed). Outside trials Engine.time_scale is set to 4 every frame; a trial scene (and the wait for it to arrive) is
## left alone, because the trial resets the scale to 1 with ContextStack.clear_time_scale() at every attempt. A leg ends
## at the scene's own hand-off (SceneTransitions.transition_started); the next leg is armed as soon as the scene swaps
## (not after its transition ends), so a scene that hands off at once is still seen. At transition_started the suite
## samples: no dialogue active and no ContextStack entry open (the plan's R5 check; story AC-4 as amended at code review
## — the start of the fade-out is the scene's hand-off, while one frame after the transition the NEXT scene may already
## have opened its own dialogue), and the leg's flags. The next scene must be the one the table names. Every leg has a
## real-time cap (Time.get_ticks_msec): 60 s for a story scene or region, 30 s for a trial. A cap or a wrong next scene
## stops the bot (no later legs run on a broken state) and prints a softlock report: leg, scene, cap, elapsed real
## seconds, the last speaker and line, the open choice prompt, the last choice answered. A single exit function
## (_finish) restores Engine.time_scale = 1 and ContextStack.clear_time_scale() on every pass and fail path and prints it.
##
## HAZARD TRIALS (decision D2). The trial scene is loaded for real; the bot waits until one attempt has run for 3 s of
## scaled time (at the trial's own scale) with the player alive (attempt number unchanged, no retry requested, not dead;
## a death restarts the count), then — only at a moment when no hazard is in flight (_active_markers empty) — sets the
## scene's _retry_requested and calls its own _complete_trial() (rewards, flag, auto-save, hand-off). Completing during
## a hazard's active window makes _run_hazard write to a freed marker (findings.md F-2). The arena itself is not played.
##
## ISOLATION COSTS (named, accepted):
##   - The driver reads and calls PRIVATE DialogueManager members: _awaiting_choice, _choice_result, _choice_container,
##     _text_label, _speaker_label and _on_choice_pressed(0). There is no public "answer the open choice" API (TD-016).
##   - The trial legs read private scene members (_attempts, _retry_requested, _active_markers, player), set
##     _retry_requested and call _complete_trial().
##   - The Wastes region leg calls the region's _interact_story(ServerRoomGate) instead of walking the player onto the
##     gate and pressing interact (what a player does; reachability_test.gd proves the gate is touchable).
##   - ch3_ending's key wait is ended by a real ui_accept input event; if that ever stops working the bot sets the
##     scene's _waiting_for_input = false to finish the run, and an AC-3 check fails.
##   - The beats really run: they auto-save to slot 99, set story flags and collect Source Keys 3-7, inside the runner's
##     isolated aeth_phase0_test user:// (the suite refuses to run outside it).
##   - Each Godot boot logs 6 "Can't use get_node() with absolute paths" ERROR lines before any test code (pre-existing).
##
## START STATE (AC-2). SEED_* is the state tests/integration/story/chapter2_route_test.gd (careful route) leaves at its
## Chapter 3 hand-off, printed by a copy of that suite at commit 74e40e8 (2026-10-25; the copy is kept as
## production/qa/evidence/2026-10-playthrough/probe_ch2_state.gd.txt with its output). Drift between the two suites is an
## accepted risk until T14b stitches the routes. Not seeded: the leftover metas (return_position, boss_return_scene,
## boss_fight_id) that the region scenes set and no Chapter 3-10 scene reads.
## Run: tests/run_phase0_tests.ps1 -Script res://tests/integration/playthrough/full_playthrough_test.gd

const SEED_COMMIT := "74e40e8"
const SEED_FLAGS: Array[String] = [
	"act1_pace_early", "act1_report_local", "ch1_bridge_saved", "ch1_complete", "ch1_elara_trusted",
	"ch1_tutorial_knight_defeated", "ch2_administrator_proxy_defeated", "ch2_arena_bronze_complete", "ch2_arena_unlocked",
	"ch2_city_stable", "ch2_clock_tower_complete", "ch2_clockwork_automaton_defeated", "ch2_command_hall_done",
	"ch2_complete", "ch2_data_wraith_defeated", "ch2_data_wraith_restored", "ch2_ironhold_entered", "ch2_market_visited",
	"ch2_medicine_done", "ch2_medicine_early", "ch2_medicine_quest_active", "ch2_rook_met", "ch2_seraphina_186_told",
	"ch2_seraphina_bond_marker", "ch2_seraphina_met", "ch2_seraphina_recruited", "ch2_seraphina_tell_me",
	"ch2_seraphina_truth", "ch2_shift_rescue_now", "ch2_tower_bell_stopped", "ch2_underground_complete",
	"ch2_underground_unlocked", "ch3_ironhold_departed", "elara_trust_high", "lore_ironhold_lore_3", "root_access_unlocked",
	"seraphina_trust_high", "side_quest_ironhold_underground_data_complete", "source_key_fragment_1", "source_key_fragment_2",
]
const SEED_KEYS := 2
const SEED_CHAPTER := 3
const SEED_REGION := "ironhold"
const SEED_GLITCH := 11.0
const SEED_STATS := {"level": 12, "hp": 41, "max_hp": 120, "mp": 50, "max_mp": 50, "gold": 800, "xp": 375,
	"base_attack": 20, "attack": 20, "base_defense": 11, "defense": 11}
const SEED_RELATIONSHIPS := {"elara": 0, "seraphina": 30}

const MENU := "res://scenes/main_menu.tscn"
const STORY_CAP_S := 60.0
const TRIAL_CAP_S := 30.0
const SWITCH_CAP_S := 30.0
const TIME_SCALE := 4.0
const TRIAL_ALIVE_S := 3.0
const KEYS_AT_END := 7

## [scene, kind, flags set by the time the scene hands off]. Verified against the scripts (story audit, AC-4). Each
## Source Key leg also checks its source_key_fragment_N flag at its own hand-off: from Chapter 8 on,
## GameManager.normalize_source_key_progression() rebuilds the count from the chapters' fragment flags, so a missing
## collect_source_key() call would be hidden by the end-of-run count (code review, mutation g).
const LEGS: Array = [
	["res://scenes/chapter3/ironhold_departure.tscn", "story", ["ch3_ironhold_departed"]],
	["res://scenes/regions/fractured_wastes_region.tscn", "region", ["ch3_server_room_unlocked"]],
	["res://scenes/chapter3/fractured_wastes.tscn", "story", ["ch3_fragment_3_collected", "source_key_fragment_3"]],
	["res://scenes/chapter3/data_stream.tscn", "story", ["ch3_data_stream_complete"]],
	["res://scenes/chapter3/archive_depths.tscn", "story", ["ch3_fragment_4_collected", "ch3_kaelthas_allied", "source_key_fragment_4"]],
	["res://scenes/chapter3/kaelthas_betrayal.tscn", "story", []],
	["res://scenes/chapter3/ch3_ending.tscn", "input", ["ch3_complete", "ch4_unlocked"]],
	["res://scenes/chapter4/ch4_forgotten_sectors_intro.tscn", "story", ["ch4_forgotten_sectors_entered"]],
	["res://scenes/chapter4/ch4_null_court.tscn", "story", ["ch4_choice_preserve_deleted", "source_key_fragment_5"]],
	["res://scenes/chapter4/ch4_ending.tscn", "story", ["ch4_complete"]],
	["res://scenes/chapter5/ch5_mirror_city_intro.tscn", "story", ["ch5_mirror_city_entered"]],
	["res://scenes/chapter5/ch5_mirror_plaza.tscn", "story", ["ch5_identity_refused_obedience"]],
	["res://scenes/chapter5/ch5_reflection_trial.tscn", "story", ["ch5_echo_control_rejected"]],
	["res://scenes/chapter5/ch5_mirror_kaelen_confrontation.tscn", "story", ["ch5_mirror_duel_cleared"]],
	["res://scenes/chapter5/ch5_ending.tscn", "story", ["ch5_complete"]],
	["res://scenes/chapter6/ch6_cathedral_intro.tscn", "story", ["ch6_cathedral_entered"]],
	["res://scenes/chapter6/ch6_cathedral_nave.tscn", "story", ["ch6_mercy_trial_cleared", "ch6_efficiency_trial_cleared", "ch6_obedience_trial_cleared"]],
	["res://scenes/chapter6/ch6_choir_core.tscn", "story", ["ch6_choir_silenced", "ch6_fragment_6_collected", "source_key_fragment_6"]],
	["res://scenes/chapter6/ch6_choir_combat_trial.tscn", "trial", ["ch6_choir_combat_trial_cleared"]],
	["res://scenes/chapter6/ch6_ending.tscn", "story", ["ch6_complete"]],
	["res://scenes/chapter7/ch7_deep_backup_intro.tscn", "story", ["ch7_deep_backup_entered"]],
	["res://scenes/chapter7/ch7_memory_ocean_hub.tscn", "story", ["ch7_memory_island_hazard_cleared"]],
	["res://scenes/chapter7/ch7_archive_tide.tscn", "story", ["ch7_backups_preserved", "ch7_fragment_7_collected", "source_key_fragment_7"]],
	["res://scenes/chapter7/ch7_archive_tide_combat_trial.tscn", "trial", ["ch7_archive_tide_surge_cleared"]],
	["res://scenes/chapter7/ch7_ending.tscn", "story", ["ch7_complete"]],
	["res://scenes/chapter8/ch8_revolt_intro.tscn", "story", ["ch8_revolt_intro_seen"]],
	["res://scenes/chapter8/ch8_saved_assembly.tscn", "story", ["ch8_faction_requests_started"]],
	["res://scenes/chapter8/ch8_revolt_crisis.tscn", "story", ["ch8_revolt_led"]],
	["res://scenes/chapter8/ch8_ending.tscn", "story", ["ch8_complete"]],
	["res://scenes/chapter9/ch9_human_patch_intro.tscn", "story", ["ch9_human_patch_entered"]],
	["res://scenes/chapter9/ch9_memory_lab.tscn", "story", ["ch9_data_vision_scan_complete"]],
	["res://scenes/chapter9/ch9_creator_trial.tscn", "story", ["ch9_truth_confessed"]],
	["res://scenes/chapter9/ch9_ending.tscn", "story", ["ch9_complete"]],
	["res://scenes/chapter10/ch10_root_intro.tscn", "story", ["ch10_root_entered"]],
	["res://scenes/chapter10/ch10_kernel_descent.tscn", "story", ["ch10_kernel_trial_cleared"]],
	["res://scenes/chapter10/ch10_witness_chamber.tscn", "story", ["ch10_witness_preparation_complete"]],
	["res://scenes/chapter10/ch10_sovereign_final_trial.tscn", "trial", ["ch10_sovereign_final_trial_cleared"]],
	["res://scenes/chapter10/ch10_sovereign_confrontation.tscn", "story", ["ch10_destroy_sovereign"]],
	["res://scenes/chapter10/ch10_ending.tscn", "ending", ["ch10_complete", "true_ending_seen", "ng_plus_unlocked"]],
]

var _passes := 0
var _failures: Array[String] = []
var _finished := false
var _halted := false

var _leg := -1
var _handed_off := false
var _snap: Dictionary = {}
var _choices: Array = []            # [leg, prompt, option text]
var _last_container_id := 0
var _last_line := ""
var _last_ms := 0
var _trial_attempt := -1
var _trial_alive := 0.0
var _trial_completed := false
var _input_pressed := false
var _input_real_ok := false
var _gate_uses := 0
var _gate_ms := 0
var _legs_done := 0


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	await process_frame
	await process_frame
	if not OS.get_user_data_dir().contains("aeth_phase0_test"):
		push_error("Refusing to run: user data dir is not isolated. Use tests/run_phase0_tests.ps1.")
		quit(2)
		return
	var autoloads_ok: bool = get_root().get_node_or_null("GameManager") != null and get_root().get_node_or_null("DialogueManager") != null \
		and get_root().get_node_or_null("SceneTransitions") != null and get_root().get_node_or_null("ContextStack") != null \
		and get_root().get_node_or_null("CreditsScreen") != null
	_check(autoloads_ok, "isolation: GameManager, DialogueManager, SceneTransitions, ContextStack and CreditsScreen autoloads are present")
	if not autoloads_ok:
		print("PLAYTHROUGH RESULT: %d passed, %d failed" % [_passes, _failures.size()])
		quit(1)
		return
	_st().transition_started.connect(_on_transition_started)
	_seed()
	var t_start := Time.get_ticks_msec()
	await _play()
	if not _halted:
		await _menu_and_credits()
	if not _halted:
		_final_checks()
	print("  run: %d legs of %d played, %.1f s real" % [_legs_done, LEGS.size(), (Time.get_ticks_msec() - t_start) / 1000.0])
	_finish()


func _check(cond: bool, name: String) -> void:
	if cond:
		_passes += 1
		print("  PASS: " + name)
	else:
		_failures.append(name)
		print("  FAIL: " + name)


func _gm() -> Node: return get_root().get_node("GameManager")
func _dm() -> Node: return get_root().get_node("DialogueManager")
func _st() -> Node: return get_root().get_node("SceneTransitions")
func _cs() -> Node: return get_root().get_node("ContextStack")


## The single exit: every pass and fail path ends here.
func _finish() -> void:
	if _finished:
		return
	_finished = true
	Engine.time_scale = 1.0
	_cs().clear_time_scale()
	print("  exit: Engine.time_scale restored to %s, ContextStack time requests cleared" % str(Engine.time_scale))
	print("")
	print("PLAYTHROUGH RESULT: %d passed, %d failed" % [_passes, _failures.size()])
	for f in _failures:
		print("  FAIL: " + f)
	quit(0 if _failures.is_empty() else 1)


# ── AC-2: start state ─────────────────────────────────────────────────────────

func _seed() -> void:
	var gm := _gm()
	gm.reset_game()
	_dm().force_reset()
	for f in SEED_FLAGS:
		gm.set_story_flag(f, true)
	gm.source_key_count = SEED_KEYS
	gm.current_chapter = SEED_CHAPTER
	gm.current_region = SEED_REGION
	gm.glitch_meter = SEED_GLITCH
	for k in SEED_STATS:
		gm.player_stats[k] = SEED_STATS[k]
	for k in SEED_RELATIONSHIPS:
		gm.relationships[k] = SEED_RELATIONSHIPS[k]
	var missing: Array = SEED_FLAGS.filter(func(f): return not gm.has_flag(f))
	_check(missing.is_empty(), "AC-2 seed: all %d seeded flags are set (missing %s)" % [SEED_FLAGS.size(), str(missing)])
	_check(gm.source_key_count == SEED_KEYS and gm.has_elara(),
		"AC-2 seed: source_key_count %d and Elara with the party (state captured at %s)" % [SEED_KEYS, SEED_COMMIT])


# ── driver ────────────────────────────────────────────────────────────────────

## One driver step. `kind` decides whether the bot owns Engine.time_scale (not inside a trial).
func _drive_frame(kind: String) -> void:
	if kind != "trial":
		Engine.time_scale = TIME_SCALE
	var dm := _dm()
	if is_instance_valid(dm._speaker_label) and is_instance_valid(dm._text_label) and dm._text_label.text != "":
		_last_line = "%s: %s" % [dm._speaker_label.text, str(dm._text_label.text).left(120)]
	if dm._awaiting_choice:
		var ready: bool = dm._choice_container != null and is_instance_valid(dm._choice_container)
		if not ready and not dm.is_skip_requested():
			dm.skip_all()   # show_choices clears skip; keep the prompt from typing out in real time
		if dm._choice_result == -1 and ready:
			var id: int = dm._choice_container.get_instance_id()
			var first := _first_button(dm._choice_container)
			# Answer only once the buttons are focusable: DialogueManager enables them after its 0.5 s grace period.
			if id != _last_container_id and first != null and first.focus_mode == Control.FOCUS_ALL:
				_last_container_id = id
				var prompt := str(dm._text_label.text).left(60) if is_instance_valid(dm._text_label) else ""
				_choices.append([_leg, prompt, first.text.left(60)])
				dm._on_choice_pressed(0)
	elif dm.is_active and not dm.is_skip_requested():
		dm.skip_all()


func _on_transition_started() -> void:
	var gm := _gm()
	var expected: Array = LEGS[_leg][2] if _leg >= 0 and _leg < LEGS.size() else []
	_snap = {
		"dialogue_active": _dm().is_active,
		"stack_open": _cs().any_open(),
		"stack_top": _cs().top(),
		"missing": expected.filter(func(f): return not gm.has_flag(f)),
	}
	_handed_off = true


func _scene_path() -> String:
	return current_scene.scene_file_path if current_scene != null else ""


## The first Button under a choice container (the option-0 button), or null.
func _first_button(container: Node) -> Button:
	for n in container.find_children("*", "Button", true, false):
		return n as Button
	return null


## Arms leg `i`: from now on a transition_started belongs to it.
func _arm_leg(i: int) -> void:
	_leg = i
	_handed_off = false
	_snap = {}


## Waits (driving with the NEXT leg's kind, so a trial is left at its own time scale) until the active scene leaves
## `prev`; arms leg `next_index` the moment the scene swaps, then waits for the transition to end. Returns the new
## scene's path ("" on a cap).
func _await_scene_change(prev: String, next_index: int, next_kind: String) -> String:
	var t0 := Time.get_ticks_msec()
	var armed := false
	while Time.get_ticks_msec() - t0 < int(SWITCH_CAP_S * 1000.0):
		_drive_frame(next_kind)
		if current_scene != null and current_scene.scene_file_path != prev:
			if not armed:
				armed = true
				_arm_leg(next_index)
			if not _st().is_transitioning:
				await process_frame
				return _scene_path()
		await process_frame
	return ""


## Softlock report: everything a game-side bug report needs (`cap_s` 0 when no cap applied).
func _report(leg_index: int, why: String, elapsed_s: float, cap_s: float = 0.0) -> void:
	var dm := _dm()
	var prompt := ""
	if dm._awaiting_choice and is_instance_valid(dm._text_label):
		prompt = str(dm._text_label.text).left(80)
	var last_choice := "(none)" if _choices.is_empty() else str(_choices.back())
	print("  SOFTLOCK REPORT: %s" % why)
	print("    leg %d of %d, scene %s, %.1f s real%s" % [leg_index, LEGS.size(), _scene_path(), elapsed_s,
		(" (cap %d s)" % int(cap_s)) if cap_s > 0.0 else ""])
	print("    last line: %s" % _last_line)
	print("    open choice prompt: %s" % (prompt if prompt != "" else "(none)"))
	print("    last choice answered: %s" % last_choice)
	print("    dialogue active: %s, ContextStack top: '%s', time_scale %s" % [str(dm.is_active), str(_cs().top()), str(Engine.time_scale)])


func _play() -> void:
	var first: String = LEGS[0][0]
	_arm_leg(0)
	var err := change_scene_to_file(first)
	_check(err == OK, "AC-3 the bot loads %s (got %d)" % [first.get_file(), err])
	var actual := ""
	var t0 := Time.get_ticks_msec()
	while Time.get_ticks_msec() - t0 < int(STORY_CAP_S * 1000.0):
		_drive_frame("story")
		if _scene_path() == first and not _st().is_transitioning:
			actual = first
			break
		await process_frame
	await process_frame
	for i in LEGS.size():
		var path: String = LEGS[i][0]
		_check(actual == path, "AC-1 leg %02d arrives at %s (got '%s')" % [i, path.get_file(), actual.get_file()])
		if actual != path:
			_report(i, "expected scene %s, got '%s'" % [path.get_file(), actual], 0.0)
			_halted = true
			return
		await _drive_leg(i)
		if _halted:
			return
		var next_path: String = LEGS[i + 1][0] if i + 1 < LEGS.size() else MENU
		var next_kind: String = LEGS[i + 1][1] if i + 1 < LEGS.size() else "menu"
		actual = await _await_scene_change(path, i + 1, next_kind)
		if actual == "":
			_check(false, "AC-1 leg %02d (%s) hands off to a new scene within %d s" % [i, path.get_file(), int(SWITCH_CAP_S)])
			_report(i, "no scene change after the hand-off", SWITCH_CAP_S, SWITCH_CAP_S)
			_halted = true
			return
		if actual != next_path:
			_check(false, "AC-1 after leg %02d (%s) the game goes to %s (got %s)" % [i, path.get_file(), next_path.get_file(), actual.get_file()])
			_report(i, "wrong next scene: expected %s, got %s" % [next_path.get_file(), actual.get_file()], 0.0)
			_halted = true
			return
	_leg = LEGS.size() - 1


## Drives one leg to the scene's own hand-off and runs the per-leg checks (AC-3, AC-4).
func _drive_leg(i: int) -> void:
	var path: String = LEGS[i][0]
	var kind: String = LEGS[i][1]
	var t0 := Time.get_ticks_msec()
	var cap_ms := int((TRIAL_CAP_S if kind == "trial" else STORY_CAP_S) * 1000.0)
	var choices_before := _choices.size()
	# _handed_off / _snap were reset by _arm_leg when this scene swapped in; a hand-off seen since then counts.
	_trial_attempt = -1
	_trial_alive = 0.0
	_trial_completed = false
	_input_pressed = false
	_input_real_ok = false
	_gate_uses = 0
	_gate_ms = 0
	_last_ms = Time.get_ticks_msec()
	if kind == "ending":
		await _ending_arrival_checks()
	while not _handed_off and Time.get_ticks_msec() - t0 < cap_ms:
		var now := Time.get_ticks_msec()
		var dt := (now - _last_ms) / 1000.0
		_last_ms = now
		_drive_frame(kind)
		match kind:
			"region":
				_drive_region()
			"input":
				await _drive_input()
			"trial":
				_drive_trial(dt)
		await process_frame
	var elapsed := (Time.get_ticks_msec() - t0) / 1000.0
	var tag := "leg %02d %s" % [i, path.get_file()]
	_check(_handed_off, "AC-3 %s hands off within the %d s cap" % [tag, int(cap_ms / 1000.0)])
	if not _handed_off:
		_report(i, "cap hit in %s (%s)" % [path.get_file(), kind], elapsed, cap_ms / 1000.0)
		_halted = true
		return
	if kind == "input":
		_check(_input_real_ok, "AC-3 %s: a real ui_accept input event ended the scene's key wait (no test-side fallback)" % tag)
	_check(not _snap["dialogue_active"] and not _snap["stack_open"],
		"AC-4 %s: no dialogue active and no ContextStack entry at the hand-off (dialogue %s, stack top '%s')" % [tag, str(_snap["dialogue_active"]), str(_snap["stack_top"])])
	_check(_snap["missing"].is_empty(), "AC-4 %s: flags set at the hand-off %s (missing %s)" % [tag, str(LEGS[i][2]), str(_snap["missing"])])
	print("  leg %02d %-40s %5.1f s real, %d choice(s)" % [i, path.get_file(), elapsed, _choices.size() - choices_before])
	_legs_done += 1


## The Wastes region: use the ServerRoomGate once it exists (placed in _ready once ch2_data_wraith_defeated is set),
## only while no transition is running (SceneTransitions.change_scene ignores a call made during one); if no hand-off
## follows within 2 s, use it again (at most 3 times).
func _drive_region() -> void:
	if current_scene == null or _handed_off or _st().is_transitioning or _dm().is_active:
		return
	if _gate_uses >= 3 or (_gate_uses > 0 and Time.get_ticks_msec() - _gate_ms < 2000):
		return
	var gate := current_scene.get_node_or_null("ServerRoomGate")
	if gate != null:
		_gate_uses += 1
		_gate_ms = Time.get_ticks_msec()
		if _gate_uses > 1:
			print("  info: ServerRoomGate used again (use %d): no hand-off followed the previous use" % _gate_uses)
		current_scene._interact_story(gate)


## ch3_ending waits for a real ui_accept press (capped at 120 s of scaled time by the scene). A real input event first;
## if the scene is still waiting 30 frames later, the test-side fallback finishes the run and the leg's AC-3 check fails.
func _drive_input() -> void:
	if current_scene == null or _input_pressed or current_scene.get("_waiting_for_input") != true:
		return
	_input_pressed = true
	var down := InputEventAction.new()
	down.action = &"ui_accept"
	down.pressed = true
	Input.parse_input_event(down)
	await process_frame
	var up := InputEventAction.new()
	up.action = &"ui_accept"
	up.pressed = false
	Input.parse_input_event(up)
	for n in 30:
		await process_frame
		if current_scene == null or current_scene.get("_waiting_for_input") != true:
			_input_real_ok = true
			print("  info: the real ui_accept input event ended ch3_ending's wait")
			return
	print("  FALLBACK (test-side): a real ui_accept event did not end ch3_ending's wait; set _waiting_for_input = false")
	current_scene._waiting_for_input = false


## A trial: wait for one attempt to have run for TRIAL_ALIVE_S of scaled time with the player alive, then complete it.
func _drive_trial(dt: float) -> void:
	var s := current_scene
	if s == null or _trial_completed:
		return
	var attempts: int = s.get("_attempts")
	if attempts != _trial_attempt:
		_trial_attempt = attempts
		_trial_alive = 0.0
	var p: Node = s.get("player")
	var dead: bool = p == null or not is_instance_valid(p) or bool(p.get("is_dead"))
	if attempts >= 1 and not dead and not bool(s.get("_retry_requested")):
		_trial_alive += dt * Engine.time_scale
	var markers: Array = s.get("_active_markers")
	if _trial_alive >= TRIAL_ALIVE_S and markers.is_empty():
		_trial_completed = true
		print("  trial %s: alive %.1f s of scaled time in attempt %d at time_scale %s, no hazard in flight; calling _complete_trial()" % [s.scene_file_path.get_file(), _trial_alive, attempts, str(Engine.time_scale)])
		# Test-side work-around (findings.md F-2): completing mid-attempt is not something a player can do. Completing
		# while a hazard is in flight makes _run_hazard write to a marker _clear_hazards() has just freed (a SCRIPT ERROR,
		# hit once on the Sovereign trial; its active-window loop does not re-check the stop flags on its last tick).
		# So the bot completes only when no hazard marker exists, and sets _retry_requested first, so a hazard that
		# starts afterwards takes its own "stop" branch (free the marker, return false).
		s._retry_requested = true
		s._complete_trial()


# ── AC-5: ending, main menu, credits ──────────────────────────────────────────

func _ending_arrival_checks() -> void:
	await process_frame
	var gm := _gm()
	_check(gm.has_flag("ch10_complete") and gm.has_flag("true_ending_seen") and gm.has_flag("ng_plus_unlocked") and gm.ng_plus_available,
		"AC-5 ch10_ending sets ch10_complete, true_ending_seen, ng_plus_unlocked and ng_plus_available")
	var found := false
	for n in current_scene.find_children("*", "RichTextLabel", true, false):
		if (n as RichTextLabel).get_parsed_text().contains("TRUE ENDING"):
			found = true
	_check(found, "AC-5 the ending's text contains 'TRUE ENDING'")


func _find_button(text: String) -> Button:
	if current_scene == null:
		return null
	for n in current_scene.find_children("*", "Button", true, false):
		if (n as Button).text == text:
			return n as Button
	return null


func _menu_and_credits() -> void:
	var t0 := Time.get_ticks_msec()
	while _scene_path() != MENU and Time.get_ticks_msec() - t0 < int(SWITCH_CAP_S * 1000.0):
		await process_frame
	_check(_scene_path() == MENU, "AC-5 the ending returns to main_menu.tscn")
	if _scene_path() != MENU:
		_report(LEGS.size(), "the game did not reach the main menu after ch10_ending", (Time.get_ticks_msec() - t0) / 1000.0)
		_halted = true
		return
	for n in 10:
		await process_frame
	var ng := _find_button("NEW GAME+")
	_check(ng != null and ng.visible, "AC-5 the main menu offers a visible NEW GAME+ button")
	var credits := get_root().get_node("CreditsScreen")
	credits.show_credits(false)
	await process_frame
	await process_frame
	_check(credits.visible and _cs().is_open(&"credits") and _cs().any_open(), "AC-5 CreditsScreen opens (visible, a ContextStack entry open)")
	var cancel := InputEventAction.new()
	cancel.action = &"ui_cancel"
	cancel.pressed = true
	Input.parse_input_event(cancel)
	await process_frame
	var release := InputEventAction.new()
	release.action = &"ui_cancel"
	release.pressed = false
	Input.parse_input_event(release)
	var t1 := Time.get_ticks_msec()
	while _cs().any_open() and Time.get_ticks_msec() - t1 < 10000:
		await process_frame
	_check(not _cs().any_open() and not paused, "AC-5 a ui_cancel press closes the credits: ContextStack empty and the tree unpaused (stack top '%s', paused %s)" % [str(_cs().top()), str(paused)])


func _final_checks() -> void:
	var gm := _gm()
	_check(gm.source_key_count == KEYS_AT_END, "AC-4 Source Keys 3-7 collected: source_key_count %d == %d" % [gm.source_key_count, KEYS_AT_END])
	_check(FileAccess.file_exists("user://save_slot_99.save"), "AC-4 the game's auto-save exists in the isolated user:// (slot 99)")
	_check(_choices.size() > 0, "AC-3 the bot answered %d choice prompts with option 0" % _choices.size())
	for c in _choices:
		print("    choice leg %02d: %s -> option 0: %s" % [c[0], c[1], c[2]])
