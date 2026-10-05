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
	await _test_builtin_events()
	_test_all_dialogue_files_parse()
	_test_voice_lint()
	await _test_opening_scene_wiring()
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


func _test_builtin_events() -> void:
	print("[built-in do events]")
	var gm := get_root().get_node("GameManager")
	var dm := get_root().get_node("DialogueManager")
	var path := "user://builtin_events_test.dlg"
	var f := FileAccess.open(path, FileAccess.WRITE)
	f.store_string("~ start\ndo trust elara 10\ndo trust elara 10\ndo pause 0.05\ndo trust elara 10\ndo scene_thing\n")
	f.close()
	gm.relationships["elara"] = 0
	gm.set_story_flag("elara_trust_high", false)
	var events: Array = []
	var r: Dictionary = await dm.run(path, "start", func(name: String): events.append(name))
	_check(r["ok"] and int(gm.relationships["elara"]) == 30, "do trust changes the relationship (%s)" % gm.relationships["elara"])
	_check(gm.has_flag("elara_trust_high"), "reaching %d sets <name>_trust_high" % dm.TRUST_HIGH)
	_check(events == ["scene_thing"], "built-ins aren't passed to the scene; other events are (%s)" % [events])
	gm.relationships["elara"] = 0
	DirAccess.remove_absolute(path)


## The New Game crash site plays dialogue/prologue + dialogue/ch1/crash_site.dlg.
func _test_opening_scene_wiring() -> void:
	print("[opening scene wiring]")
	var gm := get_root().get_node("GameManager")
	var dm := get_root().get_node("DialogueManager")
	gm.reset_game()
	dm.force_reset()
	change_scene_to_file("res://scenes/chapter1/opening_crash_site_hook.tscn")
	for i in 4:
		await process_frame
	var hook := current_scene
	_driving = true
	_drive()
	var seen_speakers: Array = []
	var deadline := Time.get_ticks_msec() + 20000
	while Time.get_ticks_msec() < deadline:
		if dm._is_visible and dm._speaker_label and not dm._speaker_label.text in seen_speakers:
			seen_speakers.append(dm._speaker_label.text)
		if not hook._dialogue_busy and "Kaelen" in seen_speakers:
			break
		await process_frame
	_check("Flight Attendant" in seen_speakers and "Kaelen" in seen_speakers,
		"New Game opens with the prologue, then Kaelen at the crash site %s" % [seen_speakers])
	_check(not hook._dialogue_busy, "opening dialogue finishes and hands control back")
	hook._on_signalfragment_interaction(hook._player)   # the fused metal
	deadline = Time.get_ticks_msec() + 15000
	while hook._dialogue_busy and Time.get_ticks_msec() < deadline:
		await process_frame
	_check(gm.has_flag("ch1_crash_trace_seen") and gm.has_flag("ch1_opening_hook_signal_found"),
		"the fused metal plays its .dlg node and opens the road east")
	_check(hook._objective_label.text.contains("Find people"), "the .dlg's 'do objective' updates the HUD (%s)" % hook._objective_label.text)
	_driving = false
	dm.force_reset()


func _test_all_dialogue_files_parse() -> void:
	print("[all .dlg files]")
	var bad: Array[String] = []
	var count := _walk("res://dialogue", bad)
	_check(count > 0, "found %d .dlg files" % count)
	_check(bad.is_empty(), "every .dlg file parses (%d with errors)" % bad.size())
	for b in bad.slice(0, 10):
		print("    " + b)


## story/VOICE_GUIDE.md §5. Authored dialogue only: dialogue/_extracted is old
## source material and is exempt.
const QUESTION_OPENER := "^(What|Why|Where|Who|Whose|How|When|Which|Did|Does|Is|Are|Was|Were|Can|Could|Would|Should|Have you|Has)\\b"
## Regexes, case-insensitive. "Better answer." grades Kaelen; "until there's a
## better answer" doesn't, so the grading forms only count at the start of a line.
const BANNED_TICS := ["^(better|good) answer\b", "\bboth (are|can be) true\b", "\bthat sentence\b"]
const FLAT_REGISTER_MIN_LINES := 15   # a file this long with no contractions reads robotic
## Rhythm (VOICE_GUIDE §5): short lines are a spice, not the diet. A line of
## RHYTHM_SHORT_WORDS words or fewer is "short". Machine speakers bark by design,
## and a node listed in a "# rhythm: clipped node …" comment is a deliberate beat.
const RHYTHM_SHORT_WORDS := 3
const RHYTHM_MAX_SHORT_SHARE := 0.30
const RHYTHM_MIN_LINES := 12          # below this, one quip swings the share too much
const RHYTHM_MAX_SHORT_RUN := 4
const RHYTHM_EXEMPT_SPEAKERS := ["System", "The Minute Hand", "Data Wraith", "Administrator Proxy"]

func _test_voice_lint() -> void:
	print("[voice lint — authored .dlg files]")
	var question := RegEx.create_from_string(QUESTION_OPENER)
	var key_hint := RegEx.create_from_string("\\[(F|E|J|K|Q|C|X|R|M|I|L|TAB|Tab|ESC|Esc|SPACE|Space|Shift|SHIFT|ENTER|Enter|WASD|A/D|F/E)\\]|Press (SPACE|Space|ESC|Esc|TAB|Tab|ENTER|Enter)\\b")
	var contraction := RegEx.create_from_string("[A-Za-z](n't|'s|'re|'ll|'m|'ve|'d)\\b")
	var speakers: Dictionary = get_root().get_node("DialogueManager").SPEAKER_COLORS
	var tic_res: Array = BANNED_TICS.map(func(p): return RegEx.create_from_string(p))
	var unasked: Array[String] = []
	var tics: Array[String] = []
	var keys: Array[String] = []
	var unknown_speakers: Array[String] = []
	var flat_files: Array[String] = []
	var word := RegEx.create_from_string("[A-Za-z0-9']+")
	var clipped_re := RegEx.create_from_string("(?m)^#\\s*rhythm:\\s*clipped\\s+(.+)$")
	var choppy_files: Array[String] = []
	var choppy_runs: Array[String] = []
	var files := _authored_dlg_files("res://dialogue")
	for path in files:
		var s = load("res://scripts/dialogue/dialogue_script.gd").load_file(path, false)
		var spoken := 0
		var contracted := 0
		var clipped: Array = []
		for m in clipped_re.search_all(FileAccess.get_file_as_string(path)):
			clipped.append_array(m.get_string(1).split(" ", false))
		var counted := 0
		var short := 0
		for node_name in s.nodes:
			var run := 0
			for step in s.nodes[node_name]:
				if step["type"] == "line" and not node_name in clipped and not step["speaker"] in RHYTHM_EXEMPT_SPEAKERS:
					var n := word.search_all(step["text"]).size()
					if n > 0:   # "..." is a pause, not a line
						counted += 1
						if n <= RHYTHM_SHORT_WORDS:
							short += 1
							run += 1
							if run == RHYTHM_MAX_SHORT_RUN + 1:
								choppy_runs.append("%s:%d (%s)" % [path.get_file(), step["line"], node_name])
						else:
							run = 0
				var texts: Array = []
				var who: Array = []
				if step["type"] == "line":
					texts.append(step["text"])
					who.append(step["speaker"])
				elif step["type"] == "choice":
					if step["prompt"] != null:
						texts.append(step["prompt"]["text"])
						who.append(step["prompt"]["speaker"])
					for opt in step["options"]:
						texts.append(opt["text"])
				for sp in who:
					if not speakers.has(sp) and not "%s (%s)" % [path.get_file(), sp] in unknown_speakers:
						unknown_speakers.append("%s (%s)" % [path.get_file(), sp])
				for t in texts:
					var text: String = t.strip_edges()
					var at := "%s:%d" % [path.get_file(), step["line"]]
					if step["type"] == "line":
						spoken += 1
						if contraction.search(text):
							contracted += 1
					# "Have you seen my sword? It's wood." is fine: the question is marked.
					if question.search(text) and not ("?" in text or text.ends_with("!") or text.ends_with("—") or text.ends_with("…") or text.ends_with("...")):
						unasked.append(at)
					for tic in tic_res:
						if tic.search(text.to_lower()):
							tics.append("%s \"%s\"" % [at, tic.get_pattern()])
					if key_hint.search(text):
						keys.append(at)
		if spoken >= FLAT_REGISTER_MIN_LINES and contracted == 0:
			flat_files.append(path.get_file())
		if counted >= RHYTHM_MIN_LINES and float(short) / counted > RHYTHM_MAX_SHORT_SHARE:
			choppy_files.append("%s %d%%" % [path.get_file(), roundi(100.0 * short / counted)])
		for clipped_node in clipped:
			if not s.nodes.has(clipped_node):
				choppy_runs.append("%s: '# rhythm: clipped %s' names no node" % [path.get_file(), clipped_node])
	_check(files.size() > 0, "found %d authored .dlg files" % files.size())
	_check(unasked.is_empty(), "questions end in a question mark %s" % [unasked.slice(0, 8)])
	_check(tics.is_empty(), "no banned tics %s" % [tics.slice(0, 8)])
	_check(keys.is_empty(), "no hardcoded key names — use {action} tokens %s" % [keys.slice(0, 8)])
	_check(unknown_speakers.is_empty(), "every speaker is registered in SPEAKER_COLORS %s" % [unknown_speakers.slice(0, 8)])
	_check(flat_files.is_empty(), "no long file without a single contraction %s" % [flat_files])
	_check(choppy_files.is_empty(), "no file is more than %d%% lines of %d words or fewer %s" % [roundi(RHYTHM_MAX_SHORT_SHARE * 100), RHYTHM_SHORT_WORDS, choppy_files])
	_check(choppy_runs.is_empty(), "no more than %d short lines in a row outside '# rhythm: clipped' nodes %s" % [RHYTHM_MAX_SHORT_RUN, choppy_runs.slice(0, 8)])


func _authored_dlg_files(dir_path: String) -> Array[String]:
	var out: Array[String] = []
	for sub in DirAccess.get_directories_at(dir_path):
		if sub != "_extracted":
			out.append_array(_authored_dlg_files(dir_path.path_join(sub)))
	for file in DirAccess.get_files_at(dir_path):
		if file.ends_with(".dlg"):
			out.append(dir_path.path_join(file))
	return out


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
