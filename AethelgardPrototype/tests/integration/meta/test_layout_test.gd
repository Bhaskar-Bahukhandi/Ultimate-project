extends SceneTree
## Guards the test layout (Y1-P0-T02): suites live in tests/unit/<system>/ or
## tests/integration/<system>/, never directly under tests/, and every suite is
## run by both tests/run_all_tests.ps1 and CI. Reads files only, so it needs no
## isolated user:// and finishes in about a second.
## Run: tests/run_phase0_tests.ps1 -Script res://tests/integration/meta/test_layout_test.gd

const TESTS_DIR := "res://tests"
const RUNNER := "res://tests/run_all_tests.ps1"
## The suites that exist on 2026-10-18; finding fewer means the walk broke.
const MIN_SUITES := 10

var _passes := 0
var _failures: Array[String] = []


func _initialize() -> void:
	var suites := _suites_in(TESTS_DIR.path_join("unit")) + _suites_in(TESTS_DIR.path_join("integration"))
	_check(suites.size() >= MIN_SUITES, "found %d suites (at least %d)" % [suites.size(), MIN_SUITES])

	var loose := Array(DirAccess.get_files_at(TESTS_DIR)).filter(func(f: String) -> bool: return f.ends_with("_test.gd"))
	_check(loose.is_empty(), "no *_test.gd directly under tests/ %s" % [loose])

	var upper := _dirs_with_uppercase(TESTS_DIR)
	_check(upper.is_empty(), "every folder under tests/ is lowercase (tests/Unit vs tests/unit) %s" % [upper])

	var no_uid := suites.filter(func(p: String) -> bool: return not FileAccess.file_exists(p + ".uid"))
	_check(no_uid.is_empty(), "every suite has its .uid beside it %s" % [no_uid])

	var runner := FileAccess.get_file_as_string(RUNNER)
	var not_run := suites.filter(func(p: String) -> bool: return not runner.contains(p))
	_check(not runner.is_empty() and not_run.is_empty(), "run_all_tests.ps1 runs every suite %s" % [not_run])

	# CI lives at the repo root, one level above the project.
	var ci_path := ProjectSettings.globalize_path("res://").path_join("../.github/workflows/ci.yml")
	var ci := FileAccess.get_file_as_string(ci_path)
	var default_suite := _runner_default_suite()
	var not_in_ci := suites.filter(func(p: String) -> bool: return not ci.contains(p) and p != default_suite)
	_check(not ci.is_empty() and not_in_ci.is_empty(), "ci.yml runs every suite %s" % [not_in_ci])

	print("")
	print("LAYOUT RESULT: %d passed, %d failed" % [_passes, _failures.size()])
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


## Every *_test.gd under dir, recursively, as res:// paths.
func _suites_in(dir: String) -> Array[String]:
	var out: Array[String] = []
	if not DirAccess.dir_exists_absolute(dir):
		return out
	for f in DirAccess.get_files_at(dir):
		if f.ends_with("_test.gd"):
			out.append(dir.path_join(f))
	for d in DirAccess.get_directories_at(dir):
		out.append_array(_suites_in(dir.path_join(d)))
	return out


func _dirs_with_uppercase(dir: String) -> Array[String]:
	var out: Array[String] = []
	for d in DirAccess.get_directories_at(dir):
		var path := dir.path_join(d)
		if d != d.to_lower():
			out.append(path)
		out.append_array(_dirs_with_uppercase(path))
	return out


## CI runs the phase0 suite through run_tests.sh's default, without naming it.
func _runner_default_suite() -> String:
	var sh := FileAccess.get_file_as_string("res://tests/run_tests.sh")
	var m := RegEx.create_from_string("\\$\\{1:-(res://[^}]+)\\}").search(sh)
	return m.get_string(1) if m else ""
