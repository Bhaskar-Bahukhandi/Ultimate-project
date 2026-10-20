extends SceneTree
## Tests for story Y1-P0-T08, work package A (production/epics/y1-p0-stabilize/story-t08-flashes-fragment4-nullpotion.md,
## "QA Test Cases" F1, F2, F2b, F3; ACs AC-1..AC-4): the chapter 3 and Oakhaven screen flashes must go through
## SceneTransitions.flash() (the only flash overlay that is sized, layered and visible) and be soft (decision 7A).
## Expected values are literals from the story and from the call sites at HEAD, never computed by the code under test.
##
## Case status on the UNFIXED code:
##   F1  routing scan                       WATCH-FAIL (the calls still go to _screen_flash / _flash)
##   F2  Oakhaven renders (real scene)      WATCH-FAIL on alpha and colour; the rect-covers-viewport checks are regression guards
##   F2b paused / hitstop                   WATCH-FAIL on the "flash started" precondition; the end-state checks are characterization
##   F3  neighbour lines untouched          REGRESSION GUARD (passes on HEAD, must keep passing): frozen lines in
##                                          order, flash tokens match only uncommented calls, and no extra
##                                          flag / save / Source Key / corruption line between two frozen lines
## Run: tests/run_phase0_tests.ps1 -Script res://tests/integration/vfx/screen_flash_test.gd

const OAKHAVEN_SCENE := "res://scenes/chapter1/oakhaven_village.tscn"
const ARCHIVE := "res://scripts/chapter3/ch3_archive_depths.gd"
const WASTES := "res://scripts/chapter3/ch3_fractured_wastes.gd"
const IRONHOLD := "res://scripts/chapter3/ch3_ironhold_departure.gd"
const KAELTHAS := "res://scripts/chapter3/ch3_kaelthas_betrayal.gd"
const OAKHAVEN := "res://scripts/chapter1/ch1_oakhaven_village.gd"

const GUARD_LINE := "if has_node(\"/root/SceneTransitions\"):"
const TODO_LINE := "# TODO(bhaskar): Y1-P1 reduce-flash option"
## Token in a frozen list: any flash call line, old (_screen_flash / _flash) or new (SceneTransitions.flash).
const FLASH := "<FLASH>"

## Literal table of every live flash call site (AC-1 / AC-2), in file order:
## [file, colour (r, g, b, a), duration in seconds, awaited]. Colours and the unchanged durations are
## the values at HEAD; Ironhold 0.3 -> 0.5 and Oakhaven 0.35 -> 0.5 are decision 2.
const SITES: Array = [
	[ARCHIVE, Color(0.3, 0.5, 0.8, 0.3), 0.5, true],
	[ARCHIVE, Color(0.5, 0.3, 0.1, 0.3), 0.5, true],
	[ARCHIVE, Color(0.8, 0.2, 0.2, 0.3), 0.5, true],
	[ARCHIVE, Color(0.2, 0.6, 1.0, 0.4), 0.8, true],
	[ARCHIVE, Color(0.3, 0.7, 1.0, 0.5), 1.0, true],
	[WASTES, Color(0.2, 0.6, 1.0, 0.5), 0.8, true],
	[IRONHOLD, Color(0.2, 0.8, 0.2, 0.4), 0.5, true],
	[OAKHAVEN, Color(0.55, 0.0, 0.7, 0.35), 0.5, false],
	[OAKHAVEN, Color(0.0, 1.0, 0.5, 0.3), 0.5, false],
]
const SOFT_MAX_ALPHA := 0.625   # visible peak is 0.8 * a, so a <= 0.625 keeps it <= 0.5
const MIN_DURATION := 0.5
const TODO_FILES: Array = [ARCHIVE, WASTES, IRONHOLD, OAKHAVEN]

## F3: lines frozen from HEAD (git show HEAD:<path>) around each call site: flag writes, auto-saves,
## Source Key collection and corruption lines, in file order, with each flash call as FLASH.
const FROZEN: Dictionary = {
	ARCHIVE: [
		"\tGameManager.set_story_flag(\"ch3_archive_floor1_complete\", true)",
		"\tGameManager.auto_save()  # PASS-34 FIX: Checkpoint between floors",
		FLASH,
		"\tGameManager.set_story_flag(\"ch3_archive_consent_clause_found\", true)",
		"\tGameManager.set_story_flag(\"ch3_archive_floor2_complete\", true)",
		"\tGameManager.auto_save()  # PASS-34 FIX: Checkpoint between floors",
		FLASH,
		"\tGameManager.set_story_flag(\"ch3_archive_floor3_complete\", true)",
		"\tGameManager.auto_save()  # PASS-34 FIX: Checkpoint between floors",
		FLASH,
		"\t\tGlitchOverlay.flash_glitch(0.3)",
		"\tGameManager.set_story_flag(\"ch3_sovereign_origin_discovered\", true)",
		"\tGameManager.set_story_flag(\"ch3_archive_floor4_complete\", true)",
		"\tGameManager.auto_save()  # PASS-34 FIX: Checkpoint at Source Key floor",
		FLASH,
		"\t\tGlitchOverlay.flash_glitch(0.8)",
		"\t\tSFXManager.play(\"source_key\")",
		FLASH,
		"\tGameManager.set_story_flag(\"ch3_fragment_4_collected\", true)",
		"\tGameManager.collect_source_key(4)",
	],
	WASTES: [
		"\t\tGlitchOverlay.flash_glitch(0.6)",
		"\t\tSFXManager.play(\"source_key\")",
		FLASH,
		"\tGameManager.set_story_flag(\"ch3_fragment_3_collected\", true)",
		"\tGameManager.collect_source_key(3)",
		"\tfragment_collected = true",
	],
	IRONHOLD: [
		FLASH,
		"\tawait _show_dialogue(\"SYSTEM\", \"// WARNING: Entering deprecated region. Stability not guaranteed. Proceed at own risk.\")",
	],
	OAKHAVEN: [
		"\t\t\"fracture_spreads\":",
		FLASH,
		"\t\t\"root_edit\":",
		"\t\t\tGameManager.add_glitch_corruption(5.0)",
		FLASH,
	],
}

const SENTINEL := Color.WHITE
const FLASH_PEAK := 0.8          # SceneTransitions.flash() sets modulate.a to this synchronously
const FADE_IN_WAIT := 1.8        # the scene's own fade-in is 1.5 s
const MARGIN := 0.4

var _passes := 0
var _failures: Array[String] = []
var _probe: Node = null


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	await process_frame
	await process_frame
	if not OS.get_user_data_dir().contains("aeth_phase0_test"):
		push_error("Refusing to run: user data dir is not isolated. Use tests/run_phase0_tests.ps1.")
		quit(2)
		return
	_probe = Node.new()
	_probe.name = "ScreenFlashProbe"
	_probe.process_mode = Node.PROCESS_MODE_ALWAYS
	get_root().add_child(_probe)
	_test_f1_routing()
	_test_f3_neighbours()
	await _test_f2_oakhaven_renders()
	await _test_f2b_paused_and_hitstop()
	_restore_globals()
	print("")
	print("SCREEN FLASH RESULT: %d passed, %d failed" % [_passes, _failures.size()])
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


## Always leave the engine as the next suite expects it.
func _restore_globals() -> void:
	Engine.time_scale = 1.0
	paused = false


## Real-time wait (wall clock, immune to time_scale and to pause): one process_frame at a time.
func _real_wait(seconds: float) -> void:
	var until := Time.get_ticks_msec() + int(seconds * 1000.0)
	while Time.get_ticks_msec() < until:
		await process_frame


func _lines(path: String) -> PackedStringArray:
	var text := FileAccess.get_file_as_string(path)
	var out := PackedStringArray()
	for l in text.split("\n"):
		out.append(l.trim_suffix("\r"))
	return out


## A flash call line (old or new form); a commented-out call does not count.
func _is_flash_line(line: String) -> bool:
	var t := line.strip_edges()
	return not t.begins_with("#") and t.contains("flash(Color(")


## State-changing calls AC-4 protects: none may appear between two frozen lines unless frozen itself.
const STATE_CALLS: Array = ["set_story_flag(", "auto_save(", "collect_source_key(", "add_glitch_corruption("]

func _is_state_line(line: String) -> bool:
	var t := line.strip_edges()
	if t.begins_with("#"):
		return false
	for c in STATE_CALLS:
		if t.contains(c):
			return true
	return false


# ── F1: routing scan (AC-1, AC-2) -- WATCH-FAIL ─────────────────────────────

func _test_f1_routing() -> void:
	print("-- F1 routing scan (AC-1 / AC-2)")
	var re := RegEx.new()
	re.compile("^(await )?SceneTransitions\\.flash\\(Color\\(([0-9.]+), ([0-9.]+), ([0-9.]+), ([0-9.]+)\\), ([0-9.]+)\\)$")
	var by_file: Dictionary = {}
	for s in SITES:
		if not by_file.has(s[0]):
			by_file[s[0]] = []
		by_file[s[0]].append(s)
	for path in by_file:
		var want: Array = by_file[path]
		var lines := _lines(path)
		var found: Array[int] = []
		for i in lines.size():
			if lines[i].contains("SceneTransitions.flash("):
				found.append(i)
		var tag: String = path.get_file()
		_check(found.size() == want.size(), "F1 %s: %d SceneTransitions.flash call(s) (found %d)" % [tag, want.size(), found.size()])
		for k in mini(found.size(), want.size()):
			var line := lines[found[k]].strip_edges()
			var m := re.search(line)
			var label := "F1 %s call %d" % [tag, k + 1]
			_check(m != null, "%s has literal Color(...) and duration arguments (`%s`)" % [label, line])
			if m == null:
				continue
			var col := Color(float(m.get_string(2)), float(m.get_string(3)), float(m.get_string(4)), float(m.get_string(5)))
			var dur := float(m.get_string(6))
			var w: Array = want[k]
			_check(col.is_equal_approx(w[1]), "%s colour is the literal %s (got %s)" % [label, w[1], col])
			_check(is_equal_approx(dur, w[2]), "%s duration is %s s (got %s)" % [label, w[2], dur])
			_check((m.get_string(1) == "await ") == w[3], "%s is %s" % [label, "awaited" if w[3] else "fire-and-forget (no await)"])
			_check(col.a <= SOFT_MAX_ALPHA, "%s colour.a %s <= %s" % [label, col.a, SOFT_MAX_ALPHA])
			_check(dur >= MIN_DURATION, "%s duration %s >= %s" % [label, dur, MIN_DURATION])
			var prev := ""
			var j := found[k] - 1
			while j >= 0 and prev == "":
				prev = lines[j].strip_edges()
				j -= 1
			_check(prev == GUARD_LINE, "%s is guarded by `%s` (previous line `%s`)" % [label, GUARD_LINE, prev])
	# The per-scene helpers are gone: nothing in scripts/chapter*/ defines _screen_flash.
	var leftovers: Array[String] = []
	var scripts_dir := DirAccess.open("res://scripts")
	var chapter_dirs: Array[String] = []
	for d in scripts_dir.get_directories():
		if d.begins_with("chapter"):
			chapter_dirs.append(d)
	_check(chapter_dirs.size() >= 3, "F1 control: found the chapter script folders (%s)" % [chapter_dirs])
	var scanned := 0
	for d in chapter_dirs:
		var dir := DirAccess.open("res://scripts/" + d)
		for f in dir.get_files():
			if f.ends_with(".gd"):
				scanned += 1
				for l in _lines("res://scripts/%s/%s" % [d, f]):
					if l.begins_with("func _screen_flash"):
						leftovers.append("%s/%s" % [d, f])
						break
	_check(scanned >= 20, "F1 control: scanned %d chapter scripts" % scanned)
	_check(leftovers.is_empty(), "F1 no `func _screen_flash` remains in scripts/chapter*/ %s" % [leftovers])
	var kael_has := false
	for l in _lines(KAELTHAS):
		if l.begins_with("func _screen_flash"):
			kael_has = true
	_check(not kael_has, "F1 Kaelthas dead copy of _screen_flash is deleted")
	var oak_has_flash_func := false
	for l in _lines(OAKHAVEN):
		if l.begins_with("func _flash("):
			oak_has_flash_func = true
	_check(not oak_has_flash_func, "F1 Oakhaven `func _flash(` is gone")
	# AC-2 review item, cheap to automate: one TODO per touched scene file.
	for path in TODO_FILES:
		var n := 0
		for l in _lines(path):
			if l.strip_edges() == TODO_LINE:
				n += 1
		_check(n == 1, "F1 %s has exactly one `%s` (found %d)" % [path.get_file(), TODO_LINE, n])


# ── F3: neighbours untouched (AC-4) -- REGRESSION GUARD ─────────────────────

func _test_f3_neighbours() -> void:
	print("-- F3 flag / auto-save / Source Key / corruption lines unchanged and in order (AC-4)")
	for path in FROZEN:
		var lines := _lines(path)
		var frozen: Array = FROZEN[path]
		var at := 0
		var missing := ""
		var inserted: Array[String] = []
		var prev_hit := -1
		for entry in frozen:
			var hit := -1
			for i in range(at, lines.size()):
				if (_is_flash_line(lines[i]) if entry == FLASH else lines[i] == entry):
					hit = i
					break
			if hit == -1:
				missing = str(entry)
				break
			if prev_hit >= 0:
				for j in range(prev_hit + 1, hit):
					if _is_state_line(lines[j]):
						inserted.append("%d: %s" % [j + 1, lines[j].strip_edges()])
			prev_hit = hit
			at = hit + 1
		_check(missing == "", "F3 %s: all %d frozen lines present in order (first missing: `%s`)" % [path.get_file(), frozen.size(), missing])
		_check(missing == "" and inserted.is_empty(), "F3 %s: no extra flag / save / Source Key / corruption line between frozen lines %s" % [path.get_file(), inserted])


# ── F2: Oakhaven renders (AC-3) -- WATCH-FAIL on alpha and colour ───────────

func _overlay() -> ColorRect:
	return get_root().get_node("SceneTransitions/FlashOverlay") as ColorRect


func _covers_viewport(c: ColorRect) -> bool:
	var vis: Rect2 = get_root().get_visible_rect()
	var r: Rect2 = c.get_global_rect()
	return vis.size.x > 0.0 and vis.size.y > 0.0 and r.encloses(vis)


func _load_oakhaven() -> Node:
	_gm().reset_game()
	var scene: Node = (load(OAKHAVEN_SCENE) as PackedScene).instantiate()
	get_root().add_child(scene)
	current_scene = scene
	await _real_wait(FADE_IN_WAIT)
	return scene


func _unload(scene: Node) -> void:
	var dm := get_root().get_node_or_null("DialogueManager")
	if dm and dm.has_method("force_reset"):
		dm.force_reset()
	current_scene = null
	if is_instance_valid(scene):
		get_root().remove_child(scene)
		scene.free()


func _test_f2_oakhaven_renders() -> void:
	print("-- F2 Oakhaven flashes show in the real scene (AC-3)")
	var scene := await _load_oakhaven()
	var ov := _overlay()
	_check(ov != null and scene.has_method("_on_dlg_event"), "F2 setup: real scene loaded and SceneTransitions/FlashOverlay found")
	if ov == null or not scene.has_method("_on_dlg_event"):
		_unload(scene)
		return
	var cases := [
		["fracture_spreads", Color(0.55, 0.0, 0.7, 0.35), 0.0],
		["root_edit", Color(0.0, 1.0, 0.5, 0.3), 5.0],
	]
	for c in cases:
		var label := "F2 %s" % c[0]
		ov.color = SENTINEL
		ov.modulate.a = 0.0
		_check(is_zero_approx(ov.modulate.a) and ov.color.is_equal_approx(SENTINEL), "%s precondition: overlay idle (a == 0) and colour is the white sentinel" % label)
		_check(not c[1].is_equal_approx(SENTINEL), "%s precondition: the expected colour differs from the sentinel" % label)
		var glitch_before: float = _gm().glitch_meter
		scene._on_dlg_event(c[0])
		_check(is_equal_approx(ov.modulate.a, FLASH_PEAK), "%s: right after the call overlay modulate.a == %s (got %s)" % [label, FLASH_PEAK, ov.modulate.a])
		_check(ov.color.is_equal_approx(c[1]), "%s: overlay colour is the literal %s (got %s)" % [label, c[1], ov.color])
		_check(_covers_viewport(ov), "%s: overlay rect %s covers the visible rect %s (regression guard)" % [label, ov.get_global_rect(), get_root().get_visible_rect()])
		await process_frame
		_check(ov.modulate.a > 0.0 and ov.modulate.a <= FLASH_PEAK, "%s: one frame later 0 < a <= %s (got %s)" % [label, FLASH_PEAK, ov.modulate.a])
		await _real_wait(0.5 + MARGIN)
		_check(is_zero_approx(ov.modulate.a), "%s: after 0.5 s + margin the overlay is back to a == 0 (got %s)" % [label, ov.modulate.a])
		var delta: float = _gm().glitch_meter - glitch_before
		_check(is_equal_approx(delta, c[2]), "%s: glitch_meter rose by %s (got %s)" % [label, c[2], delta])
	_unload(scene)


# ── F2b: paused / hitstop (AC-3 characterization) ───────────────────────────

func _test_f2b_paused_and_hitstop() -> void:
	print("-- F2b flash while paused and under hitstop (characterization)")
	var scene := await _load_oakhaven()
	var ov := _overlay()
	if ov == null or not scene.has_method("_on_dlg_event"):
		_check(false, "F2b setup: scene and overlay available")
		_unload(scene)
		return
	# Paused tree: the overlay lives under an ALWAYS autoload, so the flash must still run out.
	ov.color = SENTINEL
	ov.modulate.a = 0.0
	paused = true
	scene._on_dlg_event("fracture_spreads")
	_check(is_equal_approx(ov.modulate.a, FLASH_PEAK), "F2b paused: the flash started (a == %s, got %s)" % [FLASH_PEAK, ov.modulate.a])
	await _real_wait(0.5 + MARGIN)
	_check(is_zero_approx(ov.modulate.a), "F2b paused: the flash still ends while the tree is paused (a == 0, got %s)" % ov.modulate.a)
	paused = false
	# Hitstop: time_scale 0 holds the flash, restoring time_scale lets it end.
	ov.color = SENTINEL
	ov.modulate.a = 0.0
	scene._on_dlg_event("fracture_spreads")
	_check(is_equal_approx(ov.modulate.a, FLASH_PEAK), "F2b hitstop: the flash started (a == %s, got %s)" % [FLASH_PEAK, ov.modulate.a])
	Engine.time_scale = 0.0
	# The frame already in flight still steps the tween with the old delta, so let two frames pass first.
	await process_frame
	await process_frame
	var held_at := ov.modulate.a
	_check(held_at > 0.0, "F2b hitstop precondition: the flash is still showing (a == %s)" % held_at)
	await _real_wait(0.5 + MARGIN)
	_check(is_equal_approx(ov.modulate.a, held_at), "F2b hitstop: time_scale 0 holds the flash (a still %s, got %s)" % [held_at, ov.modulate.a])
	Engine.time_scale = 1.0
	await _real_wait(0.5 + MARGIN)
	_check(is_zero_approx(ov.modulate.a), "F2b hitstop: after time_scale is restored the flash ends (a == 0, got %s)" % ov.modulate.a)
	_restore_globals()
	_unload(scene)
