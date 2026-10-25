extends SceneTree
## Run once at HEAD (S08 day 1); kept so the golden can be re-derived and read by ch1_rooms_test.gd.
##
## Story: production/epics/y1-p0-stabilize/story-s08-elara-house-shrine-rooms.md (AC-11, AC-7).
## Writes, from the code at HEAD before any S08 edit:
##   tests/integration/story/ch1_s08_golden.json            (frozen, like breadcrumb_golden.json)
##   tests/fixtures/ch1_s08_save_pre_fragment.save
##   tests/fixtures/ch1_s08_save_mid_meeting.save
## Not a *_test.gd: tests/run_phase0_tests.ps1 gives it the default 600 s and no minimum. Run with:
##   (from AethelgardPrototype/)
##   powershell -File tests/run_phase0_tests.ps1 -Script res://tests/integration/story/ch1_s08_golden_capture.gd
##
## FROZEN OUTPUTS. A file that already exists is never overwritten. In that case the capture is
## re-derived into user:// and compared with the file on disk (the double-run determinism check,
## printed as "GOLDEN SAME: true|false"). To re-derive on purpose, delete the files first and
## record why in the story.
##
## How the saves are produced (AC-7, AC-11). Both come from ONE real run of the kill route at HEAD
## (_on_boss_defeated() in the arena, picks [0, 0, 0]). The driver watches the dialogue box; on the
## first frame it shows
##   - "SOURCE AUTHORIZATION" (first line of fragment_one.dlg `fragment`), it forces the game state
##     to DIALOGUE and calls GameManager.save_game(1); the file user://save_slot_1.save is then
##     copied to tests/fixtures/ch1_s08_save_pre_fragment.save
##   - "What was it down there?" (first line of `meeting`), the same, copied to
##     tests/fixtures/ch1_s08_save_mid_meeting.save
## save_game(1) is a manual slot (not 99) and writes the "_checksum" itself. At HEAD the arena never
## leaves the GameManager state at DIALOGUE during these lines, so the state is forced just before
## the call (the S08 altar and stair door will set it for real). The state seen before forcing is
## printed. Both saves carry current_scene = the arena and ch1_tutorial_knight_defeated.
## The timestamp / playtime / player position inside them are whatever the run produced: the saves
## are fixtures, not part of the determinism comparison (their game content is compared on rerun).
##
## Data Vision: it adds corruption after 10 s (player_topdown.gd:295-300). It is asserted OFF at
## every capture (no node in group "player" has data_vision_active == true).

const VILLAGE := "res://scenes/chapter1/oakhaven_village.tscn"
const KNIGHT := "res://scenes/chapter1/tutorial_knight_boss.tscn"
const GOLDEN_PATH := "res://tests/integration/story/ch1_s08_golden.json"
const SAVE_PRE_PATH := "res://tests/fixtures/ch1_s08_save_pre_fragment.save"
const SAVE_MID_PATH := "res://tests/fixtures/ch1_s08_save_mid_meeting.save"
const RERUN_GOLDEN := "user://ch1_s08_golden_rerun.json"
const SLOT_FILE := "user://save_slot_1.save"
const FRAGMENT_NEEDLE := "SOURCE AUTHORIZATION"
const MEETING_NEEDLE := "What was it down there?"

## ── Fixture data (explicit, so the golden never depends on what the game happens to set) ──
const STEW_PRESET_FLAGS: Array = [
	"ch1_oakhaven_entered", "ch1_northfall_registry_seen", "elara_arm_respected_silence", "ch1_elara_trusted",
]
## [0, 0, 0, 0, 0]: asked topics drop out of the list, so this asks where, fracture, magic, arm,
## then "(Just eat.)" (the only option left).
const STEW_PICKS: Array = [0, 0, 0, 0, 0]

## Flags every post-Aldric route starts from (after the stew, Elara trusted).
const ARENA_BASE_FLAGS: Array = [
	"ch1_oakhaven_entered", "ch1_northfall_registry_seen", "ch1_stew_done", "ch1_elara_trusted",
]
## Meeting choice index (fragment_one.dlg `meeting`): 0 = public, 1 = limited, 2 = silent.
## Picks are consumed in order: aldric.dlg `decision` (0 kill, 1 spare, 2 purge), then the
## route's follow-up choice (kill: kill_owned 0; purge: confirm 0), then the meeting.
const ROUTES: Array = [
	{"name": "kill", "extra_flags": ["ch1_bridge_repair_accepted", "ch1_bridge_saved"],
		"picks": [0, 0, 0], "meeting_choice": 0, "note": "kill, own it, public warning, bridge fixed"},
	{"name": "spare", "extra_flags": ["ch1_bridge_repair_accepted", "ch1_bridge_saved"],
		"picks": [1, 0], "meeting_choice": 0, "note": "spare, public warning, bridge fixed"},
	{"name": "purge", "extra_flags": ["ch1_bridge_evacuated"],
		"picks": [2, 0, 2], "meeting_choice": 2, "note": "purge confirmed, silent meeting, bridge evacuated and falls"},
	{"name": "kill_bridge_fell", "extra_flags": ["ch1_bridge_repair_accepted"],
		"picks": [0, 0, 0], "meeting_choice": 0, "note": "kill, own it, public warning, repair accepted but not saved: bridge falls"},
	{"name": "kill_no_bridge_choice", "extra_flags": [],
		"picks": [0, 0, 0], "meeting_choice": 0, "note": "kill, own it, public warning, no bridge choice made"},
]
## The route the two saves are cut from.
const SAVE_ROUTE := "kill"

var _passes := 0
var _failures: Array[String] = []
var _driving := false
var _drive_gen := 0
var _picks: Array = []
var _seen_text: Array[String] = []
## Frame hooks: {"needle": String, "call": Callable}; fired once, on the first frame a shown line
## contains the needle.
var _hooks: Array[Dictionary] = []
var _capture_armed := false
var _captured := {}
var _scene_at_capture := ""
var _state_name_at_save := {}
var _saved_files := {}


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

	var golden := {
		"_note": "Frozen S08 golden, captured from HEAD before any S08 edit by tests/integration/story/ch1_s08_golden_capture.gd (story AC-11). Do not regenerate: ch1_rooms_test replays each segment through the S08 placement (house, shrine) and compares. Fields per capture: story_flags_true (sorted), source_key_count, glitch_meter, gold (= GameManager.player_stats.gold), relationships, active_buff_flags (sorted `source_flag` of ChoiceConsequences.active_buffs; that field is named source_flag in the autoload, not flag).",
		"head_commit": _git(["rev-parse", "HEAD"]),
		"code_tree_clean_at_capture": _git(["status", "--porcelain", "--", "scripts", "scenes", "dialogue"]) == "",
		"godot_version": Engine.get_version_info().get("string", ""),
		"engine_time_scale": Engine.time_scale,
		"stew": await _capture_stew(),
		"post_aldric": {},
		"saves": {},
	}
	var routes_out := {}
	for route in ROUTES:
		routes_out[route["name"]] = await _capture_route(route)
	golden["post_aldric"] = {
		"capture_trigger": "first SceneTransitions.transition_started while current_scene is the arena and ch1_elara_joined is set",
		"base_flags": ARENA_BASE_FLAGS,
		"routes": routes_out,
	}
	golden["saves"] = _saves_description()

	_write_outputs(golden)
	Engine.time_scale = 1.0
	print("")
	print("S08CAPTURE RESULT: %d passed, %d failed" % [_passes, _failures.size()])
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
func _st() -> Node: return get_root().get_node("SceneTransitions")


## `git <args>` in the repo that holds the project, output trimmed; "" on failure.
func _git(args: Array) -> String:
	var root := ProjectSettings.globalize_path("res://")
	var out: Array = []
	var full: Array = ["-C", root]
	full.append_array(args)
	var code := OS.execute("git", full, out, true)
	if code != 0 or out.is_empty():
		return ""
	return String(out[0]).strip_edges()


# ── Driver (same approach as chapter1_route_test.gd _drive/_start) ───────────

func _drive(gen: int) -> void:
	var dm := _dm()
	while _driving and gen == _drive_gen:
		if dm._is_visible and dm._text_label and dm._text_label.text != "":
			var line: String = "%s: %s" % [dm._speaker_label.text, dm._text_label.text]
			if _seen_text.is_empty() or _seen_text.back() != line:
				_seen_text.append(line)
			for h in _hooks.duplicate():
				if line.contains(h["needle"]):
					_hooks.erase(h)
					h["call"].call()
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
		_drive_gen += 1
		_drive(_drive_gen)


func _end_scene() -> void:
	_driving = false
	_hooks.clear()
	await process_frame
	_dm().force_reset()
	if current_scene:
		current_scene.queue_free()
	await process_frame


# ── Capture of the game state ────────────────────────────────────────────────

func _data_vision_off() -> bool:
	for p in get_nodes_in_group("player"):
		if p.get("data_vision_active") == true:
			return false
	return true


func _snapshot() -> Dictionary:
	var gm := _gm()
	var flags: Array = []
	for k in gm.story_flags:
		if gm.story_flags[k] == true:
			flags.append(String(k))
	flags.sort()
	var buffs: Array = []
	for b in get_root().get_node("ChoiceConsequences").active_buffs:
		buffs.append(String(b.get("source_flag", "")))
	buffs.sort()
	return {
		"story_flags_true": flags,
		"story_flag_count": flags.size(),
		"source_key_count": gm.source_key_count,
		"glitch_meter": gm.glitch_meter,
		"gold": gm.player_stats.get("gold", 0),
		"relationships": gm.relationships.duplicate(true),
		"active_buff_flags": buffs,
	}


func _preset(flags: Array) -> void:
	var gm := _gm()
	gm.reset_game()
	_seen_text.clear()
	_captured = {}
	_scene_at_capture = ""
	for f in flags:
		gm.set_story_flag(f, true)


# ── Stew segment ─────────────────────────────────────────────────────────────

func _on_flag_for_stew(flag_name: String, value: bool) -> void:
	if _capture_armed and flag_name == "ch1_stew_done" and value and _captured.is_empty():
		_captured = _snapshot()
		_captured["data_vision_off"] = _data_vision_off()
		_scene_at_capture = current_scene.scene_file_path if current_scene else ""


func _capture_stew() -> Dictionary:
	print("[Stew segment]")
	var gm := _gm()
	_preset(STEW_PRESET_FLAGS)
	gm.story_flag_updated.connect(_on_flag_for_stew)
	_capture_armed = true
	_start(STEW_PICKS)
	change_scene_to_file(VILLAGE)
	var deadline := Time.get_ticks_msec() + 90000
	while _captured.is_empty() and Time.get_ticks_msec() < deadline:
		await process_frame
	_capture_armed = false
	gm.story_flag_updated.disconnect(_on_flag_for_stew)
	_check(not _captured.is_empty(), "stew: ch1_stew_done emitted and captured")
	_check(_captured.get("data_vision_off", false), "stew: Data Vision off at capture")
	_check(_scene_at_capture == VILLAGE, "stew: captured in the village (at %s)" % _scene_at_capture)
	for t in ["Today it's both.", "Aethelgard. You asked me that on the road."]:
		_check(_seen_text.any(func(l): return l.contains(t)), "stew: line seen: %s" % t)
	_print_capture("stew", _captured)
	_captured.erase("data_vision_off")
	var result := {
		"capture_trigger": "GameManager.story_flag_updated(\"ch1_stew_done\", true)",
		"scene_at_head": VILLAGE,
		"preset_flags": STEW_PRESET_FLAGS,
		"picks": STEW_PICKS,
		"capture": _captured.duplicate(true),
	}
	await _end_scene()
	return result


# ── Post-Aldric segment ──────────────────────────────────────────────────────

func _on_transition_started() -> void:
	if not _capture_armed or not _captured.is_empty():
		return
	var gm := _gm()
	if current_scene and current_scene.scene_file_path == KNIGHT and gm.has_flag("ch1_elara_joined"):
		_captured = _snapshot()
		_captured["data_vision_off"] = _data_vision_off()
		_scene_at_capture = current_scene.scene_file_path


func _knight_scene() -> Node:
	change_scene_to_file(KNIGHT)
	for i in 4:
		await process_frame
	var k := current_scene
	var deadline := Time.get_ticks_msec() + 60000
	while not k.combat_started and Time.get_ticks_msec() < deadline:
		await process_frame
	return k


func _capture_route(route: Dictionary) -> Dictionary:
	var name: String = route["name"]
	print("[Post-Aldric: %s]" % name)
	var preset: Array = ARENA_BASE_FLAGS.duplicate()
	preset.append_array(route["extra_flags"])
	_preset(preset)
	# A real arrival comes from a scene that left the game in EXPLORATION; reset_game() leaves MENU,
	# which makes the boss-defeat autosave refuse. (The arena never sets a state itself.)
	_gm().change_state(_gm().GameState.EXPLORATION)
	var is_save_route: bool = name == SAVE_ROUTE
	if is_save_route:
		_saved_files = {}
		_hooks.append({"needle": FRAGMENT_NEEDLE, "call": _save_hook.bind("pre_fragment")})
		_hooks.append({"needle": MEETING_NEEDLE, "call": _save_hook.bind("mid_meeting")})
	_start(route["picks"])
	var knight = await _knight_scene()
	_check(knight.combat_started, "%s: arena fight started" % name)
	_st().transition_started.connect(_on_transition_started)
	_capture_armed = true
	knight._on_boss_defeated()
	var deadline := Time.get_ticks_msec() + 240000
	while _captured.is_empty() and Time.get_ticks_msec() < deadline:
		await process_frame
	_capture_armed = false
	_st().transition_started.disconnect(_on_transition_started)
	_check(not _captured.is_empty(), "%s: transition_started captured with ch1_elara_joined set" % name)
	_check(_captured.get("data_vision_off", false), "%s: Data Vision off at capture" % name)
	_check(_scene_at_capture == KNIGHT, "%s: captured in the arena (at %s)" % [name, _scene_at_capture])
	_check(_captured.get("source_key_count", -1) == 1, "%s: source_key_count is 1" % name)
	if is_save_route:
		_check(_saved_files.has("pre_fragment") and _saved_files.has("mid_meeting"), "%s: both saves were written" % name)
	_print_capture(name, _captured)
	_captured.erase("data_vision_off")
	# The shatter transition that fired the capture is still running: let it finish, or it swaps
	# the next route's scene under it (seen on the first run).
	var settle := Time.get_ticks_msec() + 60000
	while _st().is_transitioning and Time.get_ticks_msec() < settle:
		await process_frame
	var result := {
		"preset_flags": preset,
		"picks": route["picks"],
		"meeting_choice": route["meeting_choice"],
		"note": route["note"],
		"capture": _captured.duplicate(true),
	}
	await _end_scene()
	return result


func _print_capture(label: String, c: Dictionary) -> void:
	print("  CAPTURE %s: flags=%d source_key_count=%s glitch_meter=%s gold=%s player_stats_vs_inventory_gold=%s/%s buffs=%s" % [
		label, c["story_flag_count"], c["source_key_count"], c["glitch_meter"], c["gold"],
		_gm().player_stats.get("gold", "?"), get_root().get_node("Inventory").gold, c["active_buff_flags"]])


# ── The two saves ────────────────────────────────────────────────────────────

func _save_hook(which: String) -> void:
	var gm := _gm()
	var state_before: String = gm.GameState.keys()[gm.current_state]
	gm.change_state(gm.GameState.DIALOGUE)
	if FileAccess.file_exists(SLOT_FILE):
		DirAccess.remove_absolute(SLOT_FILE)
	var ok: bool = gm.save_game(1)
	var info := {"ok": ok, "state_before_forcing": state_before, "frame": Engine.get_process_frames(),
		"source_key_fragment_1": gm.has_flag("source_key_fragment_1"), "source_key_count": gm.source_key_count}
	print("  SAVE %s: save_game(1)=%s state_before_forcing=%s fragment_flag=%s source_key_count=%d" % [
		which, ok, state_before, info["source_key_fragment_1"], info["source_key_count"]])
	_check(ok, "save %s: save_game(1) returned true" % which)
	_state_name_at_save[which] = state_before
	if ok:
		_saved_files[which] = FileAccess.get_file_as_bytes(SLOT_FILE)


func _saves_description() -> Dictionary:
	return {
		"how": "save_game(1) (manual slot) in the DIALOGUE state during one kill-route run at HEAD; user://save_slot_1.save copied out. Written by the capture script; see its header.",
		"route": SAVE_ROUTE,
		"preset_flags": ARENA_BASE_FLAGS + (ROUTES[0]["extra_flags"] as Array),
		"picks": ROUTES[0]["picks"],
		"pre_fragment": {
			"file": "tests/fixtures/ch1_s08_save_pre_fragment.save",
			"cut_when": "the first line of fragment_one.dlg `fragment` is on screen",
			"expect": {"current_scene": KNIGHT, "current_state": "DIALOGUE", "ch1_tutorial_knight_defeated": true, "source_key_fragment_1": false, "source_key_count": 0},
		},
		"mid_meeting": {
			"file": "tests/fixtures/ch1_s08_save_mid_meeting.save",
			"cut_when": "the first line of fragment_one.dlg `meeting` is on screen",
			"expect": {"current_scene": KNIGHT, "current_state": "DIALOGUE", "ch1_tutorial_knight_defeated": true, "source_key_fragment_1": true, "source_key_count": 1},
		},
	}


## Parses a save file's bytes; {} when it is not a JSON object.
func _parse_save(bytes: PackedByteArray) -> Dictionary:
	var v: Variant = JSON.parse_string(bytes.get_string_from_utf8())
	return v if v is Dictionary else {}


func _check_save(which: String, bytes: PackedByteArray, want_fragment: bool) -> void:
	var gm := _gm()
	var d := _parse_save(bytes)
	var flags: Dictionary = d.get("story_flags", {})
	_check(not d.is_empty(), "save %s parses as JSON" % which)
	_check(d.has("_checksum") and gm._save_checksum_ok(d), "save %s carries a valid _checksum" % which)
	_check(d.get("current_scene", "") == KNIGHT, "save %s: current_scene is the arena" % which)
	_check(int(d.get("current_state", -1)) == gm.GameState.DIALOGUE, "save %s: current_state is DIALOGUE" % which)
	_check(flags.get("ch1_tutorial_knight_defeated", false) == true, "save %s: ch1_tutorial_knight_defeated set" % which)
	_check(bool(flags.get("source_key_fragment_1", false)) == want_fragment, "save %s: source_key_fragment_1 is %s" % [which, want_fragment])
	_check(int(d.get("source_key_count", -1)) == (1 if want_fragment else 0), "save %s: source_key_count is %d" % [which, 1 if want_fragment else 0])


# ── Outputs (frozen: never overwritten) ──────────────────────────────────────

func _write_text(path: String, text: String) -> bool:
	var f := FileAccess.open(path, FileAccess.WRITE)
	if f == null:
		return false
	f.store_string(text)
	f.close()
	return true


func _write_bytes(path: String, bytes: PackedByteArray) -> bool:
	var f := FileAccess.open(path, FileAccess.WRITE)
	if f == null:
		return false
	f.store_buffer(bytes)
	f.close()
	return true


func _write_outputs(golden: Dictionary) -> void:
	print("")
	print("[Outputs]")
	var text := JSON.stringify(golden, "  ", true) + "\n"
	print("GOLDEN JSON BEGIN")
	print(text)
	print("GOLDEN JSON END")
	_check(golden["code_tree_clean_at_capture"], "no uncommitted change under scripts/, scenes/, dialogue/ at capture")
	_check(String(golden["head_commit"]).length() == 40, "HEAD commit hash recorded (%s)" % golden["head_commit"])
	if _saved_files.has("pre_fragment"):
		_check_save("pre_fragment", _saved_files["pre_fragment"], false)
	if _saved_files.has("mid_meeting"):
		_check_save("mid_meeting", _saved_files["mid_meeting"], true)

	if not FileAccess.file_exists(GOLDEN_PATH):
		_check(_write_text(GOLDEN_PATH, text), "golden written to %s" % GOLDEN_PATH)
		print("GOLDEN WRITTEN: %s" % GOLDEN_PATH)
	else:
		_write_text(RERUN_GOLDEN, text)
		var disk := FileAccess.get_file_as_string(GOLDEN_PATH)
		var same := disk == text
		print("GOLDEN SAME: %s (byte comparison with the frozen %s)" % [str(same).to_lower(), GOLDEN_PATH])
		_check(same, "re-derived golden is byte-identical to the frozen file")
		if not same:
			var a := disk.split("\n")
			var b := text.split("\n")
			for i in mini(a.size(), b.size()):
				if a[i] != b[i]:
					print("  first differing line %d:\n    disk : %s\n    rerun: %s" % [i + 1, a[i], b[i]])
					break
	for pair in [["pre_fragment", SAVE_PRE_PATH, false], ["mid_meeting", SAVE_MID_PATH, true]]:
		var which: String = pair[0]
		var path: String = pair[1]
		if not _saved_files.has(which):
			continue
		if not FileAccess.file_exists(path):
			_check(_write_bytes(path, _saved_files[which]), "save fixture written: %s" % path)
			print("SAVE WRITTEN: %s" % path)
		else:
			# Frozen: the timestamp / playtime inside differ per run, so compare the game content.
			var old := _parse_save(FileAccess.get_file_as_bytes(path))
			var fresh := _parse_save(_saved_files[which])
			var same_content := true
			for k in ["story_flags", "source_key_count", "glitch_meter", "relationships", "current_scene", "current_state", "player_stats", "choice_consequences"]:
				if JSON.stringify(old.get(k), "", true) != JSON.stringify(fresh.get(k), "", true):
					same_content = false
					print("  save %s differs in %s" % [which, k])
			print("SAVE SAME CONTENT %s: %s" % [which, str(same_content).to_lower()])
			_check(same_content, "re-derived save %s has the same game content as the frozen fixture" % which)
			_check_save(which + " (frozen file)", FileAccess.get_file_as_bytes(path), pair[2])
