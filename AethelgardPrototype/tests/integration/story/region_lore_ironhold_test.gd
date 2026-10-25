extends SceneTree
## Tests for story Y1-P0-T12 (production/epics/y1-p0-stabilize/story-t12-ui-region-leftovers.md), AC-3 and AC-5:
## lore and secret pickups speak as "Journal" with the title as the first line of the text (decision D2), Fractured
## Wastes records its lore in the LoreJournal, and Ironhold's _interact_boss stops on an empty scene_path before it
## sets anything (decision D5). Titles, ids and region names are literals from the regions' LORE_DATA / *_SECRETS at
## HEAD; the body text is read from the pickup's own meta (it is the input, not a computed value).
##
## What is driven, per region (Oakhaven, Ironhold, Fractured Wastes; the real region scene via change_scene_to_file):
##   - one plain lore pickup and the dev_signature lore pickup (the Area2D the region named after the LORE_DATA id),
##     through the region's own interact function (_interact_with_lore / _interact_lore);
##   - one secret pickup from the *_SECRETS array (_collect_secret / _interact_secret);
##   - one untitled secret (an Area2D the test adds with secret_data lacking "title"): the first line is SECRET.
## Per pickup it observes DialogueManager while the line waits for the advance: the name plate reads "Journal", the raw
## text starts with "[b]<title>[/b]\n", get_parsed_text() starts with "<title>\n<body>", visible_characters == -1 and
## visible_ratio == 1 (the typewriter finished and shows the whole text), and the interact call returns after the advance.
## Lore: LoreJournal.is_discovered(id) afterwards; dev_signature_N_found set for the dev_signature pickup only.
## AC-3 save: the Wastes entry is saved (GameManager.save_game to slot 1 under a dummy current scene whose path never
## exists, the ngplus_save_roundtrip_test.gd approach), the JSON's version is "1.2.0" and lists the id, the journal is
## cleared (control: not discovered), load_game(1) brings it back.
## AC-5: _interact_boss on an Area2D the test builds with scene_path "" (rec_level 1, then rec_level 99 so the soft-level
## warning WOULD open a dialogue if the check were not first): returns at once, no transition_started, no boss_fight_id,
## boss_return_scene or return_position meta, no dialogue. Each call logs one EXPECTED line
## "ERROR: [Ironhold] Boss gate 'T12EmptyGate' has no scene_path; not entering." (push_error prints ERROR:, not
## SCRIPT ERROR:, so the runner does not fail on it; that is the behaviour under test, not a failure).
##
## DRIVER. After the interact call starts (say() runs synchronously up to its first typewriter await) the driver sets
## DialogueManager._skip_typing (ends the typewriter, as pressing accept does), waits until _is_typing is false, reads,
## then sets _advance_requested (the advance press) and waits for the call to return (5 s real-time cap).
##
## ISOLATION COSTS (named, accepted):
##   - The driver reads and writes PRIVATE DialogueManager members: _speaker_label, _text_label, _is_typing,
##     _skip_typing, _advance_requested. There is no public "finish typing" / "advance" API.
##   - GameManager.reset_game() does not clear the LoreJournal, so before each lore case the suite clears PRIVATE
##     LoreJournal state (_discovered_ids and each _entries[id].discovered); otherwise a discovery from an earlier case
##     would make "discovered" true whatever the code under test does.
##   - Region _process is turned off after load (Fractured Wastes' random corruption storm opens its own dialogue after
##     20-45 s; nothing under test runs in _process).
##   - Pickups really run: they set flags, add items, XP and gold, and write slot 1 in the isolated aeth_phase0_test
##     user://; reset_game() between regions clears flags and items, the save files are removed after the round trip.
## Run: tests/run_phase0_tests.ps1 -Script res://tests/integration/story/region_lore_ironhold_test.gd

const OAKHAVEN := "res://scenes/regions/oakhaven_region.tscn"
const IRONHOLD := "res://scenes/regions/ironhold_region.tscn"
const WASTES := "res://scenes/regions/fractured_wastes_region.tscn"

## [region label, scene, lore method, secret method, plain lore [id, title], dev lore [id, title], secret [id, title]]
const REGIONS: Array = [
	["oakhaven", OAKHAVEN, "_interact_with_lore", "_collect_secret",
		["crater_memory_1", "Memory Fragment: The Crash"], ["dev_signature_1", "Developer Signature #1"],
		["secret_oak_well_lore", "FORGOTTEN JOURNAL"]],
	["ironhold", IRONHOLD, "_interact_lore", "_interact_secret",
		["ironhold_lore_1", "Market Notice"], ["dev_signature_2", "Developer Signature #2"],
		["secret_iron_market_gold", "MERCHANT'S HIDDEN VAULT"]],
	["fractured_wastes", WASTES, "_interact_lore", "_interact_secret",
		["wastes_lore_1", "Fractured Monument"], ["dev_signature_3", "Developer Signature #3"],
		["secret_wastes_null_edge", "VOID CACHE"]],
]

const SPEAKER := "Journal"
const UNTITLED_ID := "t12_untitled_secret"
const UNTITLED_TEXT := "T12 untitled secret probe."
const FALLBACK_TITLE := "SECRET"
const WASTES_SAVE_ID := "wastes_lore_1"
const SAVE_VERSION := "1.2.0"

const DUMMY_SCENE := "res://tests/integration/story/__t12_no_such_scene.tscn"
const SAVE_SLOT := 1
const SAVE_PATH := "user://save_slot_1.save"
const SAVE_SUFFIXES: Array[String] = ["", ".bak", ".bak.tmp", ".tmp", ".corrupted"]

const CALL_CAP_MS := 5000
const LOAD_FRAMES := 5

var _passes := 0
var _failures: Array[String] = []
var _transitions := 0


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	await process_frame
	await process_frame
	if not OS.get_user_data_dir().contains("aeth_phase0_test"):
		push_error("Refusing to run: user data dir is not isolated. Use tests/run_phase0_tests.ps1.")
		quit(2)
		return
	if ResourceLoader.exists(DUMMY_SCENE):
		push_error("Refusing to run: %s exists, so load_game() would change scene." % DUMMY_SCENE)
		quit(2)
		return
	_check(OS.get_user_data_dir().contains("aeth_phase0_test"), "isolation: user:// is the aeth_phase0_test directory")
	_check(_dm() != null and _gm() != null and _lj() != null and _st() != null,
		"isolation: DialogueManager, GameManager, LoreJournal and SceneTransitions autoloads present")
	_check(_dm().SPEAKER_COLORS.has(SPEAKER), "AC-3: SPEAKER_COLORS has \"Journal\"")
	_remove_save_files()
	_st().transition_started.connect(_on_transition_started)
	for r in REGIONS:
		await _test_region(r)
		if r[0] == "fractured_wastes":
			await _test_wastes_save_roundtrip()
	await _test_ironhold_empty_scene_path()
	await _swap_to_empty()
	_remove_save_files()
	_gm().reset_game()
	print("")
	print("REGION LORE IRONHOLD RESULT: %d passed, %d failed" % [_passes, _failures.size()])
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


func _gm() -> Node: return get_root().get_node_or_null("GameManager")
func _dm() -> Node: return get_root().get_node_or_null("DialogueManager")
func _lj() -> Node: return get_root().get_node_or_null("LoreJournal")
func _st() -> Node: return get_root().get_node_or_null("SceneTransitions")


func _on_transition_started() -> void:
	_transitions += 1


# ── AC-3: pickups ────────────────────────────────────────────────────────────

func _test_region(r: Array) -> void:
	var label: String = r[0]
	print("-- %s" % label)
	var region: Node = await _load_region(label, r[1])
	if region == null:
		return
	await _lore_case(region, label, r[2], r[4], false)
	await _lore_case(region, label, r[2], r[5], true)
	await _secret_case(region, label, r[3], r[6][0], r[6][1])
	await _untitled_secret_case(region, label, r[3])


func _load_region(label: String, path: String) -> Node:
	await _swap_to_empty()
	_gm().reset_game()
	var err := change_scene_to_file(path)
	for i in LOAD_FRAMES:
		await process_frame
	var ok := err == OK and current_scene != null and current_scene.scene_file_path == path
	_check(ok, "%s: region scene %s loaded (err %d)" % [label, path, err])
	if not ok:
		return null
	current_scene.set_process(false)
	_check(not _dm().is_active, "%s: no dialogue is open after the region loads" % label)
	return current_scene


func _lore_case(region: Node, label: String, method: String, lore: Array, dev: bool) -> void:
	var id: String = lore[0]
	var title: String = lore[1]
	var case := "%s lore %s" % [label, id]
	var area := region.get_node_or_null(id) as Area2D
	_check(area != null and area.get_meta("lore_title", "") == title, "%s: pickup Area2D found with lore_title \"%s\"" % [case, title])
	if area == null:
		return
	var body: String = area.get_meta("lore_text", "")
	_clear_journal()
	_check(not _lj().is_discovered(id), "%s: precondition, not in the journal" % case)
	var obs: Dictionary = await _drive(region, method, area)
	_assert_line(case, obs, title, body)
	_check(_lj().is_discovered(id), "%s: LoreJournal holds the entry afterwards" % case)
	var flag := id + "_found"
	if dev:
		_check(_gm().has_flag(flag), "%s: story flag %s set (as today)" % [case, flag])
	else:
		var any_dev := false
		for n in [1, 2, 3]:
			any_dev = any_dev or _gm().has_flag("dev_signature_%d_found" % n)
		_check(not any_dev, "%s: no dev_signature_*_found flag set by a plain lore pickup" % case)


func _secret_case(region: Node, label: String, method: String, id: String, title: String) -> void:
	var case := "%s secret %s" % [label, id]
	var area := region.get_node_or_null(id) as Area2D
	var data: Dictionary = area.get_meta("secret_data", {}) if area else {}
	_check(area != null and data.get("title", "") == title, "%s: pickup Area2D found with title \"%s\"" % [case, title])
	if area == null:
		return
	var obs: Dictionary = await _drive(region, method, area)
	_assert_line(case, obs, title, str(data.get("text", "")))


func _untitled_secret_case(region: Node, label: String, method: String) -> void:
	var case := "%s untitled secret" % label
	var area := Area2D.new()
	area.name = "T12UntitledSecret"
	area.set_meta("secret_data", {"id": UNTITLED_ID, "flag": UNTITLED_ID + "_found", "item": "", "text": UNTITLED_TEXT})
	region.add_child(area)
	var obs: Dictionary = await _drive(region, method, area)
	_assert_line(case, obs, FALLBACK_TITLE, UNTITLED_TEXT)


## The checks every pickup line gets (6).
func _assert_line(case: String, obs: Dictionary, title: String, body: String) -> void:
	_check(obs["started"], "%s: a dialogue line was typing right after the interact call" % case)
	_check(obs["speaker"] == SPEAKER, "%s: name plate reads \"Journal\" (got \"%s\")" % [case, obs["speaker"]])
	_check(str(obs["raw"]).begins_with("[b]%s[/b]\n" % title), "%s: raw text starts with the bold title line (got \"%s\")" % [case, str(obs["raw"]).left(60)])
	_check(str(obs["parsed"]).begins_with(title + "\n" + body), "%s: parsed text starts with the title, a newline, then the body (got \"%s\")" % [case, str(obs["parsed"]).left(60)])
	_check(obs["typed_out"] and obs["visible_chars"] == -1 and is_equal_approx(float(obs["ratio"]), 1.0),
		"%s: typing finished with the whole text shown (visible_characters %s, visible_ratio %s)" % [case, obs["visible_chars"], obs["ratio"]])
	_check(obs["returned"], "%s: the interact call returned after the advance within %d s" % [case, CALL_CAP_MS / 1000])


## Starts region.<method>(area), finishes the typewriter, reads the dialogue, advances, waits for the call to return.
func _drive(region: Node, method: String, area: Area2D) -> Dictionary:
	var dm := _dm()
	dm.force_reset()
	await process_frame
	var done := [false]
	var runner := func() -> void:
		await region.call(method, area)
		done[0] = true
	runner.call()
	var obs := {"started": bool(dm._is_typing), "typed_out": false, "returned": false,
		"speaker": "", "raw": "", "parsed": "", "visible_chars": 0, "ratio": 0.0}
	dm._skip_typing = true
	var t0 := Time.get_ticks_msec()
	while dm._is_typing and Time.get_ticks_msec() - t0 < CALL_CAP_MS:
		await process_frame
	obs["typed_out"] = not dm._is_typing
	obs["speaker"] = dm._speaker_label.text
	obs["raw"] = dm._text_label.text
	obs["parsed"] = dm._text_label.get_parsed_text()
	obs["visible_chars"] = dm._text_label.visible_characters
	obs["ratio"] = dm._text_label.visible_ratio
	dm._advance_requested = true
	while not done[0] and Time.get_ticks_msec() - t0 < CALL_CAP_MS:
		await process_frame
	obs["returned"] = done[0]
	if not done[0]:
		dm.force_reset()
	await process_frame
	return obs


## GameManager.reset_game() leaves the journal alone: clear its private discovery state.
func _clear_journal() -> void:
	var lj := _lj()
	lj._discovered_ids.clear()
	for e in lj._entries.values():
		e.discovered = false


# ── AC-3: the Wastes entry survives a save and load ─────────────────────────

func _test_wastes_save_roundtrip() -> void:
	print("-- fractured_wastes save round trip")
	var gm := _gm()
	var lj := _lj()
	# Fresh discovery through the real pickup, so the save holds what the region recorded.
	await _swap_to_empty()
	gm.reset_game()
	change_scene_to_file(WASTES)
	for i in LOAD_FRAMES:
		await process_frame
	current_scene.set_process(false)
	_clear_journal()
	var area := current_scene.get_node_or_null(WASTES_SAVE_ID) as Area2D
	if area:
		await _drive(current_scene, "_interact_lore", area)
	_check(lj.is_discovered(WASTES_SAVE_ID), "save: %s discovered through the Wastes pickup before the save" % WASTES_SAVE_ID)
	await _swap_to_empty()
	var initial_state: int = gm.current_state
	_remove_save_files()
	var save_ok := _save_under_dummy()
	_check(save_ok, "save: save_game(%d) returned true" % SAVE_SLOT)
	var data := _read_save_json()
	_check(str(data.get("version", "")) == SAVE_VERSION, "save: the saved JSON's version is still %s (got %s)" % [SAVE_VERSION, data.get("version", "")])
	var saved_ids: Variant = data.get("lore_journal", {}).get("discovered_lore", []) if data.get("lore_journal") is Dictionary else []
	_check(saved_ids is Array and WASTES_SAVE_ID in saved_ids, "save: lore_journal.discovered_lore in the JSON lists %s" % WASTES_SAVE_ID)
	_clear_journal()
	_check(not lj.is_discovered(WASTES_SAVE_ID), "save control: the cleared journal no longer holds %s" % WASTES_SAVE_ID)
	var empty := current_scene
	current_scene = null
	var load_ok: bool = await gm.load_game(SAVE_SLOT)
	_check(load_ok, "save: load_game(%d) returned true" % SAVE_SLOT)
	_check(lj.is_discovered(WASTES_SAVE_ID), "save: %s is in the journal after the load" % WASTES_SAVE_ID)
	if is_instance_valid(empty):
		current_scene = empty
	gm.current_state = initial_state
	_remove_save_files()


## save_game() with a dummy current scene whose path never exists (load_game() then changes no scene).
func _save_under_dummy() -> bool:
	var gm := _gm()
	var prev := current_scene
	var scene := Node.new()
	scene.name = "T12SaveScene"
	scene.scene_file_path = DUMMY_SCENE
	get_root().add_child(scene)
	current_scene = scene
	gm.current_state = gm.GameState.EXPLORATION
	var ok: bool = gm.save_game(SAVE_SLOT)
	current_scene = prev
	get_root().remove_child(scene)
	scene.free()
	return ok


func _read_save_json() -> Dictionary:
	if not FileAccess.file_exists(SAVE_PATH):
		return {}
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(SAVE_PATH))
	return parsed if parsed is Dictionary else {}


func _remove_save_files() -> void:
	for suffix in SAVE_SUFFIXES:
		if FileAccess.file_exists(SAVE_PATH + suffix):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_PATH + suffix))


# ── AC-5: Ironhold empty scene_path ─────────────────────────────────────────

func _test_ironhold_empty_scene_path() -> void:
	print("-- ironhold _interact_boss with an empty scene_path")
	var region: Node = await _load_region("ironhold (AC-5)", IRONHOLD)
	if region == null:
		return
	for rec_level in [1, 99]:
		await _empty_gate_case(region, rec_level)


func _empty_gate_case(region: Node, rec_level: int) -> void:
	var gm := _gm()
	var dm := _dm()
	var case := "AC-5 empty scene_path, rec_level %d" % rec_level
	dm.force_reset()
	gm.clear_transient_metas()
	await process_frame
	var gate := Area2D.new()
	gate.name = "T12EmptyGate"
	gate.set_meta("boss_id", "t12_probe_boss")
	gate.set_meta("rec_level", rec_level)
	gate.set_meta("scene_path", "")
	_transitions = 0
	var done := [false]
	var runner := func() -> void:
		await region._interact_boss(gate)
		done[0] = true
	print("  (expected next: one ERROR line from _interact_boss — the behaviour under test)")
	runner.call()
	var returned_at_once: bool = done[0]
	var dialogue_opened: bool = dm.is_active
	for i in 10:
		await process_frame
	_check(returned_at_once, "%s: the call returned at once (no await before the check)" % case)
	_check(not dialogue_opened and not dm.is_active, "%s: no soft-level warning dialogue opened" % case)
	_check(_transitions == 0 and not _st().is_transitioning, "%s: no SceneTransitions.transition_started (got %d)" % [case, _transitions])
	_check(not gm.has_meta("boss_fight_id"), "%s: GameManager meta boss_fight_id not set" % case)
	_check(not gm.has_meta("boss_return_scene") and not gm.has_meta("return_position"),
		"%s: boss_return_scene and return_position metas not set" % case)
	if not done[0]:
		dm.force_reset()
	gate.free()


# ── Teardown ─────────────────────────────────────────────────────────────────

## Waits out any transition, swaps in an empty scene and frees the old one, resets the dialogue box.
func _swap_to_empty() -> void:
	var t0 := Time.get_ticks_msec()
	await process_frame
	while _st().is_transitioning and Time.get_ticks_msec() - t0 < 10000:
		await process_frame
	var empty := Node.new()
	empty.name = "EmptyScene"
	var old := current_scene
	get_root().add_child(empty)
	current_scene = empty
	if old != null and is_instance_valid(old):
		get_root().remove_child(old)
		old.free()
	_dm().force_reset()
	await process_frame
