extends SceneTree
## Tests for story Y1-P0-TD-004 (production/epics/y1-p0-stabilize/story-td004-ch3-flash-runtime.md, ACs AC-1..AC-6):
## the Chapter 3 scenes' OWN flash lines run, headless, in the real scenes. screen_flash_test.gd (T08) proves the
## call sites by a static scan; this suite runs them. Expected values are literals from the story and from the call
## sites at HEAD, never computed by the code under test.
##
## What is observed: SceneTransitions.flash_started (the test seam, emitted by flash() once the overlay is set and
## before the fade starts, with the colour and duration it was called with). Per scene the suite loads the real
## scene, drives its dialogue until the scene's own hand-off (SceneTransitions.transition_started) and asserts the
## ordered, complete list of emissions:
##   AC-2  archive_depths       5 flashes, 6 choices answered, kaelthas_allied == true afterwards
##   AC-3  fractured_wastes     1 flash with ch3_server_room_unlocked set; 0 flashes from a fresh game (the gate)
##   AC-4  ironhold_departure   1 flash, 0 choices
##   AC-5  first flash per scene: the overlay's colour, modulate.a and rect, read synchronously in the
##         flash_started handler. flash() emits the signal right after it sets the overlay (colour, a = 0.8) and
##         before the fade tween exists, so the handler sees exactly 0.8 (a deferred read saw 0.71-0.75, because the
##         tween's first step runs before it when flash() is called from a resumed timer await).
##   AC-6  driver and isolation (the checks named "driver" and "isolation")
##
## DRIVER (AC-6). Each frame: if a choice prompt is open, answer option 0 and record it; otherwise if dialogue is
## active and skip is not requested, DialogueManager.skip_all() (it does not persist: show_choices and hide_dialogue
## clear it). It stops on transition_started or a 20 s real-time cap (a cap fails the case with the emissions seen so
## far). The recorders are disconnected on transition_started and the counts are asserted then, so "exactly" covers
## the whole scene. The six archive choices are, in order: the entry puzzle, Kaelthas (option 0 = ally; the 3-round
## betrayal fight is NOT exercised), the consent clause, and the floor 1, 2 and 3 puzzles. Wastes and Ironhold have none.
##
## ISOLATION COSTS (named, accepted):
##   - The driver reads and calls PRIVATE DialogueManager members: _awaiting_choice, _choice_result, _choice_container,
##     _text_label and _on_choice_pressed(0). There is no public "answer the open choice" API.
##   - Between cases the previous scene is freed while its beat may still be awaiting, so the log may show
##     "Resumed function ... after await, but class instance is gone". That is not a SCRIPT ERROR, so the runner does
##     not fail on it, and this suite does not rely on the runner for it.
##   - The beats really run: they auto-save (into the isolated aeth_phase0_test user://), set Chapter 3 story flags
##     and collect Source Keys 3 and 4. GameManager.reset_game() between cases clears flags, keys and save slots.
##   - Each Godot boot logs 6 "Can't use get_node() with absolute paths" ERROR lines before any test code (pre-existing).
## Run: tests/run_phase0_tests.ps1 -Script res://tests/integration/vfx/ch3_flash_runtime_test.gd

const ARCHIVE_SCENE := "res://scenes/chapter3/archive_depths.tscn"
const WASTES_SCENE := "res://scenes/chapter3/fractured_wastes.tscn"
const IRONHOLD_SCENE := "res://scenes/chapter3/ironhold_departure.tscn"

## Literal flash tables [colour, duration in seconds], in the order the scenes call them (story audit facts).
const ARCHIVE_FLASHES: Array = [
	[Color(0.3, 0.5, 0.8, 0.3), 0.5],
	[Color(0.5, 0.3, 0.1, 0.3), 0.5],
	[Color(0.8, 0.2, 0.2, 0.3), 0.5],
	[Color(0.2, 0.6, 1.0, 0.4), 0.8],
	[Color(0.3, 0.7, 1.0, 0.5), 1.0],
]
const WASTES_FLASHES: Array = [[Color(0.2, 0.6, 1.0, 0.5), 0.8]]
const IRONHOLD_FLASHES: Array = [[Color(0.2, 0.8, 0.2, 0.4), 0.5]]
const ARCHIVE_CHOICES := 6

const FLASH_PEAK := 0.8        # SceneTransitions.flash() sets modulate.a to this synchronously
const CAP_MS := 20000          # real-time cap per case
const SETTLE_CAP_MS := 10000   # real-time cap for waiting out a transition
const TOLERANCE := 0.001

var _passes := 0
var _failures: Array[String] = []

# Per-case state (reset by _begin_case).
var _flashes: Array = []
var _choices: Array = []
var _stop := false
var _snap: Dictionary = {}
var _end: Dictionary = {}
var _last_container_id := 0


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	await process_frame
	await process_frame
	if not OS.get_user_data_dir().contains("aeth_phase0_test"):
		push_error("Refusing to run: user data dir is not isolated. Use tests/run_phase0_tests.ps1.")
		quit(2)
		return
	_check(OS.get_user_data_dir().contains("aeth_phase0_test"), "isolation: user:// is the aeth_phase0_test directory (%s)" % OS.get_user_data_dir())
	_check(get_root().get_node_or_null("SceneTransitions") != null and get_root().get_node_or_null("DialogueManager") != null \
		and get_root().get_node_or_null("GameManager") != null, "isolation: SceneTransitions, DialogueManager and GameManager autoloads present")
	_check(get_root().get_node("SceneTransitions").has_signal("flash_started"), "AC-1 seam: SceneTransitions declares flash_started")
	await _settle_and_reset()
	await _test_archive()
	await _test_wastes_unlocked()
	await _test_wastes_gate_control()
	await _test_ironhold()
	await _settle_and_reset()
	print("")
	print("CH3 FLASH RESULT: %d passed, %d failed" % [_passes, _failures.size()])
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


# ── Cases ────────────────────────────────────────────────────────────────────

func _test_archive() -> void:
	var r: Dictionary = await _run_case("archive", ARCHIVE_SCENE, [])
	_assert_flashes("AC-2 archive", r, ARCHIVE_FLASHES)
	_check(r["choices"].size() == ARCHIVE_CHOICES, "AC-6 driver archive: exactly %d choices answered (got %d: %s)" % [ARCHIVE_CHOICES, r["choices"].size(), r["choices"]])
	_check(r["allied"] == true, "AC-6 driver archive: kaelthas_allied == true at the hand-off (option 0 is the ally branch)")
	_check(r["flag_allied"] == true, "AC-6 driver archive: story flag ch3_kaelthas_allied set at the hand-off")
	_assert_visible_path("AC-5 archive", r, ARCHIVE_FLASHES[0][0] if r["flashes"].size() > 0 else Color.WHITE)
	await _settle_and_reset()


func _test_wastes_unlocked() -> void:
	var r: Dictionary = await _run_case("wastes", WASTES_SCENE, ["ch3_server_room_unlocked"])
	_assert_flashes("AC-3 wastes (ch3_server_room_unlocked set)", r, WASTES_FLASHES)
	_check(r["choices"].size() == 0, "AC-6 driver wastes: 0 choices (got %d)" % r["choices"].size())
	_assert_visible_path("AC-5 wastes", r, WASTES_FLASHES[0][0])
	await _settle_and_reset()


func _test_wastes_gate_control() -> void:
	var r: Dictionary = await _run_case("wastes control", WASTES_SCENE, [])
	_assert_flashes("AC-3 wastes control (no flags)", r, [])
	_check(r["choices"].size() == 0, "AC-6 driver wastes control: 0 choices (got %d)" % r["choices"].size())
	await _settle_and_reset()


func _test_ironhold() -> void:
	var r: Dictionary = await _run_case("ironhold", IRONHOLD_SCENE, [])
	_assert_flashes("AC-4 ironhold", r, IRONHOLD_FLASHES)
	_check(r["choices"].size() == 0, "AC-6 driver ironhold: 0 choices (got %d)" % r["choices"].size())
	_assert_visible_path("AC-5 ironhold", r, IRONHOLD_FLASHES[0][0])
	await _settle_and_reset()


# ── Assertions ───────────────────────────────────────────────────────────────

## Exactly the expected emissions, in order, with the scene having reached its own hand-off (not the cap).
func _assert_flashes(label: String, r: Dictionary, expected: Array) -> void:
	var got: Array = r["flashes"]
	_check(r["handed_off"], "%s: scene reached its own hand-off (transition_started) within %d s (emissions seen: %d)" % [label, CAP_MS / 1000, got.size()])
	_check(got.size() == expected.size(), "%s: exactly %d flash_started emission(s) (got %d)" % [label, expected.size(), got.size()])
	for i in expected.size():
		if i >= got.size():
			_check(false, "%s: flash #%d missing" % [label, i + 1])
			continue
		var exp_c: Color = expected[i][0]
		var exp_d: float = expected[i][1]
		var got_c: Color = got[i][0]
		var got_d: float = got[i][1]
		_check(got_c.is_equal_approx(exp_c), "%s: flash #%d colour %s (got %s)" % [label, i + 1, exp_c, got_c])
		_check(absf(got_d - exp_d) <= TOLERANCE, "%s: flash #%d duration %s s (got %s)" % [label, i + 1, exp_d, got_d])


## The overlay as the flash_started handler saw it: flash() has set colour and alpha, the fade has not started.
func _assert_visible_path(label: String, r: Dictionary, expected_colour: Color) -> void:
	var s: Dictionary = r["snap"]
	_check(not s.is_empty() and s["found"], "%s: SceneTransitions/FlashOverlay read after the first flash" % label)
	if s.is_empty() or not s["found"]:
		return
	var c: Color = s["color"]
	_check(c.is_equal_approx(expected_colour), "%s: overlay colour %s ~ emitted %s" % [label, c, expected_colour])
	_check(absf(float(s["alpha"]) - FLASH_PEAK) <= TOLERANCE, "%s: overlay modulate.a == %s (+/- %s) when flash_started fires (got %s)" % [label, FLASH_PEAK, TOLERANCE, s["alpha"]])
	_check(s["covers"], "%s: overlay global rect %s covers the viewport %s" % [label, s["rect"], s["vis"]])


# ── Driver ───────────────────────────────────────────────────────────────────

## Resets, sets flags, loads the scene and drives it to its hand-off. Returns the frozen observations.
func _run_case(label: String, scene_path: String, flags: Array) -> Dictionary:
	# Typed as Node: the driver reaches private DialogueManager members, so these stay dynamically dispatched.
	var gm: Node = get_root().get_node("GameManager")
	var dm: Node = get_root().get_node("DialogueManager")
	var st: Node = get_root().get_node("SceneTransitions")
	gm.reset_game()
	for f in flags:
		gm.set_story_flag(f, true)
	_flashes = []
	_choices = []
	_stop = false
	_snap = {}
	_end = {}
	_last_container_id = 0
	st.flash_started.connect(_on_flash_started)
	st.transition_started.connect(_on_transition_started)
	print("  case %s: loading %s" % [label, scene_path])
	var t0 := Time.get_ticks_msec()
	var err := change_scene_to_file(scene_path)
	_check(err == OK, "%s: change_scene_to_file(%s) returned OK (got %d)" % [label, scene_path, err])
	if err != OK:
		_stop = true   # nothing to drive; the hand-off check below fails the case at once
	while not _stop and Time.get_ticks_msec() - t0 < CAP_MS:
		await process_frame
		if _stop:
			break
		_drive(dm)
	var handed_off := _stop
	if not handed_off:
		# Cap: freeze what we saw and detach the recorders ourselves.
		_on_transition_started()
		_end["handed_off"] = false
	print("  case %s: %s after %d ms, %d flash(es), %d choice(s)" % [label, "hand-off" if handed_off else "CAP HIT", Time.get_ticks_msec() - t0, _end["flashes"].size(), _end["choices"].size()])
	var out := _end.duplicate()
	out["snap"] = _snap
	return out


## One driver step: answer the open choice with option 0, else keep skip requested while dialogue is active.
func _drive(dm: Node) -> void:
	if dm._awaiting_choice:
		var container_ready: bool = dm._choice_container != null and is_instance_valid(dm._choice_container)
		if not container_ready and not dm.is_skip_requested():
			dm.skip_all()   # show_choices clears skip; keep the prompt from typing out in real time
		if dm._choice_result == -1 and container_ready:
			var id: int = dm._choice_container.get_instance_id()
			if id != _last_container_id:
				_last_container_id = id
				var prompt := ""
				if dm._text_label != null:
					prompt = str(dm._text_label.text).left(50)
				_choices.append(prompt)
				dm._on_choice_pressed(0)
	elif dm.is_active and not dm.is_skip_requested():
		dm.skip_all()


func _on_flash_started(color: Color, duration: float) -> void:
	_flashes.append([color, duration])
	if _flashes.size() == 1:
		_read_overlay()   # synchronous: flash() emits after setting the overlay and before creating the tween


## Reads the overlay inside the flash_started handler (colour and alpha already set, no tween step yet).
func _read_overlay() -> void:
	var ov := get_root().get_node_or_null("SceneTransitions/FlashOverlay") as ColorRect
	if ov == null:
		_snap = {"found": false}
		return
	var vis: Rect2 = get_root().get_visible_rect()
	var rect: Rect2 = ov.get_global_rect()
	_snap = {"found": true, "color": ov.color, "alpha": ov.modulate.a, "rect": rect, "vis": vis,
		"covers": vis.size.x > 0.0 and vis.size.y > 0.0 and rect.encloses(vis)}


## The scene's own hand-off: freeze the observations and detach the recorders.
func _on_transition_started() -> void:
	var gm: Node = get_root().get_node("GameManager")
	var st: Node = get_root().get_node("SceneTransitions")
	if st.flash_started.is_connected(_on_flash_started):
		st.flash_started.disconnect(_on_flash_started)
	if st.transition_started.is_connected(_on_transition_started):
		st.transition_started.disconnect(_on_transition_started)
	var scene_allied = null
	if current_scene != null:
		scene_allied = current_scene.get("kaelthas_allied")
	_end = {
		"handed_off": true,
		"flashes": _flashes.duplicate(true),
		"choices": _choices.duplicate(),
		"allied": scene_allied,
		"flag_allied": gm.has_flag("ch3_kaelthas_allied"),
	}
	_stop = true


## Waits for the hand-off transition to finish, swaps in an empty scene, then resets dialogue and game state.
func _settle_and_reset() -> void:
	var st: Node = get_root().get_node("SceneTransitions")
	var t0 := Time.get_ticks_msec()
	await process_frame
	while st.is_transitioning and Time.get_ticks_msec() - t0 < SETTLE_CAP_MS:
		await process_frame
	_check(not st.is_transitioning, "isolation: the scene's hand-off transition finished within %d s before the reset" % (SETTLE_CAP_MS / 1000))
	await process_frame
	var empty := Node.new()
	empty.name = "EmptyScene"
	var old := current_scene
	get_root().add_child(empty)
	current_scene = empty
	if old != null and is_instance_valid(old):
		get_root().remove_child(old)
		old.free()
	get_root().get_node("DialogueManager").force_reset()
	get_root().get_node("GameManager").reset_game()
	await process_frame
