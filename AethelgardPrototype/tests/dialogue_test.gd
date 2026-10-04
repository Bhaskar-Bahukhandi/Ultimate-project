extends SceneTree
## Tests for the .dlg dialogue format: parser, validator, DialogueManager.run(),
## and that every .dlg file in res://dialogue parses cleanly.
## Run: tests/run_phase0_tests.ps1 -Script res://tests/dialogue_test.gd

const FIXTURE := "res://tests/fixtures/sample.dlg"

var _passes := 0
var _failures: Array[String] = []
var _picks: Array = []   # indexes the fake player picks, in order
var _driving := false


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	await process_frame
	await process_frame
	if not OS.get_user_data_dir().contains("aeth_phase0_test"):
		push_error("Refusing to run: user data dir is not isolated. Use tests/run_phase0_tests.ps1.")
		quit(2)
		return
	_test_parser()
	_test_validation_errors()
	await _test_runner()
	_test_all_dialogue_files_parse()
	print("")
	print("DIALOGUE RESULT: %d passed, %d failed" % [_passes, _failures.size()])
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


func _parse(src: String) -> RefCounted:
	var s = load("res://scripts/dialogue/dialogue_script.gd").new()
	s.parse(src)
	return s


func _test_parser() -> void:
	print("[parser]")
	var s = load("res://scripts/dialogue/dialogue_script.gd").load_file(FIXTURE, false)
	_check(s.errors.is_empty(), "fixture parses without errors %s" % str(s.errors))
	_check(s.node_order == ["start", "left", "secret", "after"], "nodes in order")
	var start: Array = s.nodes["start"]
	_check(start[0]["type"] == "line" and start[0]["speaker"] == "Kaelen" and start[0]["id"] == "t_001", "line with speaker and id")
	_check(start[1]["cond"] == [{"flag": "test_flag_a", "negate": false}], "[if flag] condition")
	_check(start[2]["type"] == "do" and start[2]["event"] == "wave", "do event")
	var choice: Dictionary = start[3]
	_check(choice["type"] == "choice" and choice["prompt"]["speaker"] == "Elara" and choice["options"].size() == 3, "choice block with prompt and 3 options")
	_check(choice["options"][2]["target"] == "END", "=> END option")
	_check(choice["options"][1]["cond"] == [{"flag": "test_flag_a", "negate": false}] and choice["options"][1]["text"] == "Secret option.",
		"'- [if flag] text' puts the condition on the option, not in its text")
	var left: Array = s.nodes["left"]
	_check(left[0]["type"] == "set" and left[0]["value"] == true and left[1]["value"] == false, "set flag / set flag = false")
	_check(left[2]["type"] == "jump" and left[2]["cond"][0]["negate"], "[if not flag] jump")
	_check(s.missing_ids().size() == 1, "missing_ids() finds the one line without [#id] (%d)" % s.missing_ids().size())
	var two_blocks = _parse("~ a\n? K: one\n- x => END\n? K: two\n- y => END\n")
	_check(two_blocks.nodes["a"].size() == 2, "a new '?' prompt starts a separate choice block")
	_check(_parse("~ a\nK: line one\\nline two\n").nodes["a"][0]["text"] == "line one\nline two", "\\n becomes a line break")


func _test_validation_errors() -> void:
	print("[validation]")
	_check(not _parse("K: before any node\n").errors.is_empty(), "text before first node is an error")
	_check(not _parse("~ a\n=> nowhere\n").errors.is_empty(), "jump to unknown node is an error")
	_check(not _parse("~ a\n- option without target\n").errors.is_empty(), "option without => is an error")
	_check(not _parse("~ a\n~ a\n").errors.is_empty(), "duplicate node is an error")
	_check(not _parse("~ a\njust words\n").errors.is_empty(), "line without 'Speaker: ' is an error")
	_check(not _parse("~ a\n? K: prompt\nK: no options\n").errors.is_empty(), "prompt without options is an error")
	_check(not _parse("~ a\nset x = maybe\n").errors.is_empty(), "set value must be true/false")
	var e: String = _parse("~ a\n=> nowhere\n").errors[0]
	_check(e.contains(":2:"), "errors carry the line number (%s)" % e)


func _drive() -> void:
	var dm := get_root().get_node("DialogueManager")
	while _driving:
		if dm._awaiting_choice:
			if dm._choice_result == -1 and dm._choice_container != null and not _picks.is_empty():
				dm._on_choice_pressed(_picks.pop_front())
		elif dm._is_visible:
			dm._skip_typing = true
			dm._advance_requested = true
		await process_frame


func _test_runner() -> void:
	print("[runner]")
	var gm := get_root().get_node("GameManager")
	var dm := get_root().get_node("DialogueManager")
	gm.reset_game()
	for f in ["test_flag_a", "test_flag_b", "test_went_left", "test_found_secret"]:
		gm.set_story_flag(f, false)
	var events: Array = []
	var on_event := func(name: String): events.append(name)
	_driving = true
	_drive()

	gm.set_story_flag("test_flag_b", true)
	_picks = [0]  # "Go left."
	var r: Dictionary = await dm.run(FIXTURE, "start", on_event)
	_check(r["ok"], "run() completes")
	_check(events == ["wave"], "do event reached the scene handler")
	_check(gm.has_flag("test_went_left") and not gm.has_flag("test_flag_b"), "set / set = false applied")
	_check(r["end_node"] == "after", "conditional jump followed (ended at '%s')" % r["end_node"])
	_check(r["choices"].size() == 1 and r["choices"][0]["target"] == "left", "choice recorded")

	# Conditional option only appears when its flag is set: with test_flag_a,
	# the visible options are [left, secret, END] -> index 1 is "secret".
	gm.set_story_flag("test_flag_a", true)
	_picks = [1]
	r = await dm.run(FIXTURE, "start", on_event)
	_check(gm.has_flag("test_found_secret"), "[if flag] option shown and picked")

	gm.set_story_flag("test_flag_a", false)
	gm.set_story_flag("test_found_secret", false)
	_picks = [1]  # without the flag, index 1 is "Stop here." (END)
	r = await dm.run(FIXTURE, "start", on_event)
	_check(not gm.has_flag("test_found_secret") and r["ok"],
		"hidden option is skipped; index maps to visible options (ok=%s secret=%s choices=%s end=%s)" % [r["ok"], gm.has_flag("test_found_secret"), str(r["choices"]), r["end_node"]])

	r = await dm.run(FIXTURE, "no_such_node")
	_check(not r["ok"], "unknown start node fails cleanly")
	_driving = false
	await create_timer(0.4).timeout
	_check(not dm.is_active, "dialogue box closes after run()")


func _test_all_dialogue_files_parse() -> void:
	print("[all .dlg files]")
	var bad: Array[String] = []
	var count := _walk("res://dialogue", bad)
	_check(count > 0, "found %d .dlg files" % count)
	_check(bad.is_empty(), "every .dlg file parses (%d with errors)" % bad.size())
	for b in bad.slice(0, 10):
		print("    " + b)


func _walk(dir_path: String, bad: Array[String]) -> int:
	var dir := DirAccess.open(dir_path)
	if dir == null:
		return 0
	var n := 0
	for sub in dir.get_directories():
		n += _walk(dir_path.path_join(sub), bad)
	for file in dir.get_files():
		if file.ends_with(".dlg"):
			n += 1
			var s = load("res://scripts/dialogue/dialogue_script.gd").load_file(dir_path.path_join(file), false)
			if not s.errors.is_empty():
				bad.append(s.errors[0])
	return n
