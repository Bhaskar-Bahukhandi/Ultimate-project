extends SceneTree
## Tests for story Y1-P0-T08 work package B (production/epics/y1-p0-stabilize/story-t08-flashes-fragment4-nullpotion.md,
## AC-6, AC-7 and QA cases A1, A2): fragment_4 unlocks at Source Key count >= 4 (decision 8A),
## is named "Halfway to Root", and a player who already holds fragment_4 keeps it.
## Autoloads only, no scene is loaded. The stat check is called directly (no 1 s timer wait).
## Expected values are literals from the story, never computed from the code under test.
## Run: tests/run_phase0_tests.ps1 -Script res://tests/unit/achievements/fragment_achievement_test.gd

const SAVE_PATH := "user://achievements.save"
const WATCHED: Array[String] = ["fragment_4", "fragment_1", "source_key_complete"]

var _passes := 0
var _failures: Array[String] = []


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	await process_frame
	await process_frame
	if not OS.get_user_data_dir().contains("aeth_phase0_test"):
		push_error("Refusing to run: user data dir is not isolated. Use tests/run_phase0_tests.ps1.")
		quit(2)
		return
	var saved_unlocked: Dictionary = _ach().unlocked.duplicate(true)
	var saved_progress: Dictionary = _ach().progress.duplicate(true)
	var saved_count: int = _gm().source_key_count

	_test_a1_threshold()
	_test_a1_definition()
	_test_a1_neighbours()
	_test_a2_already_unlocked_is_kept()

	# Restore the singletons this test touched and drop the fixture file.
	_ach().unlocked = saved_unlocked
	_ach().progress = saved_progress
	_gm().source_key_count = saved_count
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_PATH))
	print("")
	print("FRAGMENT ACHIEVEMENT UNIT RESULT: %d passed, %d failed" % [_passes, _failures.size()])
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


func _ach() -> Node: return get_root().get_node("Achievements")
func _gm() -> Node: return get_root().get_node("GameManager")


## Clean slate for the three Source Key achievements; other ids are left alone (the stat
## check may unlock unrelated ones, which this test never asserts on).
func _clean() -> void:
	for id in WATCHED:
		_ach().unlocked.erase(id)


## Sets the Source Key count and runs the real stat check synchronously.
func _at_count(n: int) -> void:
	_gm().source_key_count = n
	_ach()._check_stat_achievements()


func _has(id: String) -> bool:
	return _ach().unlocked.has(id)


# ── A1 ──────────────────────────────────────────────────────────────────

func _test_a1_threshold() -> void:
	print("-- A1 fragment_4 threshold (AC-6)")
	_clean()
	_at_count(2)
	_check(not _has("fragment_4"), "A1 count 2: fragment_4 absent")
	_at_count(3)
	_check(not _has("fragment_4"), "A1 count 3: fragment_4 absent")
	_at_count(4)
	_check(_has("fragment_4"), "A1 count 4: fragment_4 present")


func _test_a1_definition() -> void:
	print("-- A1 fragment_4 definition (AC-6)")
	var all: Dictionary = _ach().get_script().get_script_constant_map().get("ACHIEVEMENTS", {})
	_check(all.has("fragment_4"), "A1 ACHIEVEMENTS has fragment_4")
	var d: Dictionary = all.get("fragment_4", {})
	_check(d.get("name") == "Halfway to Root", "A1 name == \"Halfway to Root\" (got %s)" % [d.get("name")])
	_check(d.get("desc") == "Collect four Source Key fragments.", "A1 desc == \"Collect four Source Key fragments.\" (got %s)" % [d.get("desc")])
	_check(d.get("icon") == "🔑", "A1 icon unchanged (key)")
	_check(d.get("category") == "story", "A1 category == \"story\"")


func _test_a1_neighbours() -> void:
	print("-- A1 fragment_1 and source_key_complete unchanged (AC-6)")
	_clean()
	_at_count(0)
	_check(not _has("fragment_1"), "A1 count 0: fragment_1 absent")
	_at_count(1)
	_check(_has("fragment_1"), "A1 count 1: fragment_1 present")
	_check(not _has("fragment_4") and not _has("source_key_complete"), "A1 count 1: fragment_4 and source_key_complete absent")
	_at_count(6)
	_check(not _has("source_key_complete"), "A1 count 6: source_key_complete absent")
	_check(_has("fragment_4"), "A1 count 6: fragment_4 present")
	_at_count(7)
	_check(_has("source_key_complete"), "A1 count 7: source_key_complete present")


# ── A2 ──────────────────────────────────────────────────────────────────

## Regression guard (passes on unfixed code): an achievements.save written when
## fragment_4 unlocked at count 2 must still hold it after the real load, at counts 2 and 3.
func _test_a2_already_unlocked_is_kept() -> void:
	print("-- A2 already-unlocked fragment_4 is kept (AC-7) [REGRESSION GUARD: passes on unfixed code]")
	# Fixture in the file's own format (see Achievements._save_to_disk): {"unlocked": {...}, "progress": {...}}.
	var fixture := {"unlocked": {"fragment_4": "2026-01-01T00:00:00"}, "progress": {}}
	var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	_check(f != null, "A2 fixture file opened for writing")
	if f == null:
		return
	f.store_string(JSON.stringify(fixture, "\t"))
	f.close()
	_ach().unlocked = {}
	_ach().progress = {}
	_ach()._load_from_disk()
	_check(_has("fragment_4"), "A2 after real load: fragment_4 present")
	_at_count(2)
	_check(_has("fragment_4"), "A2 count 2 after load: fragment_4 still present")
	_at_count(3)
	_check(_has("fragment_4"), "A2 count 3 after load: fragment_4 still present")
	# Negative control (watch-fail on unfixed code): a save WITHOUT fragment_4 loads, and count 2
	# must not unlock it; fragment_1 from the same file proves the load ran.
	var control := {"unlocked": {"fragment_1": "2026-01-01T00:00:00"}, "progress": {}}
	var g := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	_check(g != null, "A2 control fixture file opened for writing")
	if g == null:
		return
	g.store_string(JSON.stringify(control, "\t"))
	g.close()
	_ach().unlocked = {}
	_ach().progress = {}
	_ach()._load_from_disk()
	_check(_has("fragment_1") and not _has("fragment_4"), "A2 control after real load: fragment_1 present, fragment_4 absent")
	_at_count(2)
	_check(not _has("fragment_4"), "A2 control count 2 after load: fragment_4 still locked")
