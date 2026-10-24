extends SceneTree
## Tests for story TD-002 (production/epics/y1-p0-stabilize/story-td002-ngplus-save-roundtrip.md,
## "QA Test Cases" R1-R9): a v1.2 save made after choice buffs were applied must survive
## save -> load -> New Game+ without stacking the buffs (T07 fix, decision 6A).
## Autoloads only, no scene is loaded: the save is written under a dummy current scene whose
## path never exists, so load_game() restores everything but changes no scene.
## Choice buffs are applied the real way, through GameManager.set_story_flag().
## Expected values are literals read by hand from CHOICE_BUFFS in scripts/choice_consequences.gd,
## never computed with the code under test. Numbers come back from a JSON load as floats, so
## every comparison across a load is made field by field (never _snap() dictionaries or
## _trio() arrays); _trio() is only compared on the NG+ side, where the values are ints again.
## Test-only: no production code, save format or save file is changed.
## Run: tests/run_phase0_tests.ps1 -Script res://tests/unit/ngplus/ngplus_save_roundtrip_test.gd

## Must never exist as a file: load_game() then changes no scene (story, Implementation Notes).
const DUMMY_SCENE := "res://tests/unit/ngplus/__td002_no_such_scene.tscn"
const SAVE_SLOT := 1
const SAVE_PATH := "user://save_slot_1.save"
const SAVE_SUFFIXES: Array[String] = ["", ".bak", ".bak.tmp", ".tmp", ".corrupted"]
const ACH_FILE := "f:achievements.save"
const MARKER := "td002_marker"

## Baseline B = DEFAULT_PLAYER_STATS.
const B_ATTACK := 15
const B_DEFENSE := 0
const B_MAX_HP := 100

## Flag sets. Totals from CHOICE_BUFFS, summed by hand:
## kill:  attack +36 (8+3+6+10+3+6), max_hp -5 (-15 wraith, +10 kaelthas), soul_gain_bonus +0.35
##        (0.2+0.15); no kill buff touches defense, so the key is absent from the totals.
## spare: attack +3 (kaelthas_refused), defense +31 (5+3+8+5+5+5), max_hp +35 (15+10+10).
const KILL_FLAGS: Array[String] = [
	"ch1_knight_killed", "ch1_elara_cautious", "ch2_seraphina_rejected",
	"ch2_data_wraith_absorbed", "ch3_lyra_recruited", "ch3_kaelthas_challenged",
]
const SPARE_FLAGS: Array[String] = [
	"ch1_knight_spared", "ch1_elara_trusted", "ch2_seraphina_stayed",
	"ch2_data_wraith_restored", "ch3_lyra_left_alone", "ch3_kaelthas_refused",
]
const PURGE_FLAG := "ch1_root_purge_used"
const FLIP_FLAGS: Array[String] = ["ch1_knight_killed", "ch1_knight_spared"]

const KILL_TOTALS := {"attack": 36.0, "max_hp": -5.0, "soul_gain_bonus": 0.35}
const SPARE_TOTALS := {"attack": 3.0, "defense": 31.0, "max_hp": 35.0}
const PURGE_TOTALS := {"max_hp": -10.0}
const FLIP_TOTALS := {"defense": 5.0, "max_hp": 15.0}

## Buff ids in the order the flags are set (CHOICE_BUFFS "id" values).
const KILL_IDS: Array = [
	"executioner_edge", "elara_bond_wary", "hardened_heart", "wraith_power", "ranger_ally", "battle_tested",
]
const SPARE_IDS: Array = [
	"guardian_blessing", "elara_bond_strong", "ironhold_defender", "wraith_gratitude", "storm_navigator",
	"independent_mind",
]
const PURGE_IDS: Array = ["root_mastery"]
const FLIP_IDS: Array = ["guardian_blessing"]

const LEVEL_XP := 700  # >= 600 XP is level 4 (XP_THRESHOLDS), so level >= 3 holds
const HURT_HP := 40
const HURT_MP := 20

## The nine numbers snapshotted before and after a load (E / L), and the eight read after NG+ (P).
const NINE: Array[String] = ["base_attack", "base_defense", "max_hp", "attack", "defense", "hp", "mp", "max_mp", "level"]
const EIGHT: Array[String] = ["base_attack", "base_defense", "max_hp", "attack", "defense", "hp", "max_mp", "level"]
const FIVE: Array[String] = ["level", "base_attack", "base_defense", "max_hp", "max_mp"]

var _passes := 0
var _failures: Array[String] = []
## One entry per load_game() call: the AC-5a / AC-5b observations, checked together in R6.
var _load_log: Array[Dictionary] = []
var _initial_state: int = 0


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
	_initial_state = _gm().current_state
	var listing_before := _listing()
	_remove_save_files()

	# Every round trip runs first; the case functions only check what they recorded.
	var kill: Dictionary = await _roundtrip(KILL_FLAGS, 0, 0, true)
	var spare: Dictionary = await _roundtrip(SPARE_FLAGS, 0, 2)
	var control: Dictionary = await _roundtrip([], LEVEL_XP, 0)
	var kill_lv: Dictionary = await _roundtrip(KILL_FLAGS, LEVEL_XP, 0)
	var purge: Dictionary = await _roundtrip([PURGE_FLAG], 0, 0)
	var flip: Dictionary = await _roundtrip(FLIP_FLAGS, 0, 0)
	var second_gen: Dictionary = await _roundtrip(KILL_FLAGS, 0, 0, false, 2)

	_test_r1_kill_route(kill)
	_test_r2_spare_route_cycle_two(spare)
	_test_r3_levelled_vs_control(control, kill_lv)
	_test_r4_save_vs_no_save(kill, spare, kill_lv)
	_test_r5_load_save_data_path(kill, spare)
	_test_r7_purge_only(purge)
	_test_r8_flip_before_save(flip)
	_test_r9_second_generation(second_gen)
	_test_r6_hygiene(listing_before)

	_reset_all()
	current_scene = null
	_gm().current_state = _initial_state
	print("")
	print("NGPLUS ROUNDTRIP RESULT: %d passed, %d failed" % [_passes, _failures.size()])
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
func _cc() -> Node: return get_root().get_node("ChoiceConsequences")
func _inv() -> Node: return get_root().get_node("Inventory")


## Fresh run state for every case: reset every touched autoload.
func _reset_all() -> void:
	_cc().reset()
	_gm().reset_game()
	_inv().items.clear()
	_inv().equipment = {"weapon": null, "armor": null, "accessory": null}
	_inv().gold = 0
	_gm().player_stats["gold"] = 0
	_gm().ng_plus_cycle = 0
	_gm().ng_plus_available = false


func _set_flags(flags: Array) -> void:
	for f in flags:
		_gm().set_story_flag(f, true)


## The nine numbers the story snapshots (E / L / P). Values keep their stored type.
func _snap() -> Dictionary:
	var ps: Dictionary = _gm().player_stats
	var out := {}
	for k in NINE:
		out[k] = ps.get(k)
	return out


func _trio(d: Dictionary) -> Array:
	return [d["base_attack"], d["base_defense"], d["max_hp"]]


func _base_trio() -> Array:
	return [B_ATTACK, B_DEFENSE, B_MAX_HP]


## Field-by-field comparison with scalar ==, so 51 == 51.0 holds across a JSON load.
## Returns the names of the fields that differ (empty = all equal).
func _diff_fields(a: Dictionary, b: Dictionary, keys: Array) -> Array:
	var diff: Array = []
	for k in keys:
		if not (a.has(k) and b.has(k)) or a[k] != b[k]:
			diff.append("%s: %s vs %s" % [k, a.get(k), b.get(k)])
	return diff


## True when `totals` has exactly the keys of `expected` and every value is_equal_approx.
func _totals_match(totals: Dictionary, expected: Dictionary) -> bool:
	if totals.size() != expected.size():
		return false
	for k in expected:
		if not totals.has(k) or not is_equal_approx(float(totals[k]), float(expected[k])):
			return false
	return true


func _buff_ids() -> Array:
	var ids: Array = []
	for b in _cc().active_buffs:
		ids.append(b.get("id", ""))
	return ids


## True when every listed field of `d` is a TYPE_INT.
func _all_int(d: Dictionary, keys: Array) -> bool:
	for k in keys:
		if typeof(d.get(k)) != TYPE_INT:
			return false
	return true


func _listing() -> Array:
	var out: Array = []
	var dir := DirAccess.open("user://")
	if dir == null:
		return ["<user:// unreadable>"]
	for f in dir.get_files():
		out.append("f:" + f)
	for d in dir.get_directories():
		out.append("d:" + d)
	out.sort()
	return out


## Removes save_slot_1.save and its .bak, .bak.tmp, .tmp and .corrupted siblings.
func _remove_save_files() -> void:
	for suffix in SAVE_SUFFIXES:
		if FileAccess.file_exists(SAVE_PATH + suffix):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_PATH + suffix))


## Names of the save_slot_1.save* files currently in user://.
func _leftover_saves() -> Array:
	var left: Array = []
	for suffix in SAVE_SUFFIXES:
		if FileAccess.file_exists(SAVE_PATH + suffix):
			left.append("save_slot_1.save" + suffix)
	return left


## Writes the save through the real save_game() with a dummy current scene (path DUMMY_SCENE,
## which never exists) in EXPLORATION state, then removes and frees the dummy and clears
## current_scene. Returns whether save_game() succeeded.
func _save_under_dummy() -> bool:
	var gm := _gm()
	var scene := Node.new()
	scene.name = "Td002SaveScene"
	scene.scene_file_path = DUMMY_SCENE
	get_root().add_child(scene)
	current_scene = scene
	gm.current_state = gm.GameState.EXPLORATION
	var ok: bool = gm.save_game(SAVE_SLOT)
	current_scene = null
	get_root().remove_child(scene)
	scene.free()
	return ok


## Reads the slot-1 JSON back as a Dictionary ({} when missing or unparseable).
func _read_save_json() -> Dictionary:
	if not FileAccess.file_exists(SAVE_PATH):
		return {}
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(SAVE_PATH))
	return parsed if parsed is Dictionary else {}


## Buff ids and the marker flag of the first buff in a parsed save's choice_consequences.
func _json_buffs(data: Dictionary) -> Dictionary:
	var ids: Array = []
	var marker := false
	var non_empty := false
	var cc: Variant = data.get("choice_consequences")
	if cc is Dictionary:
		non_empty = not cc.is_empty()
		var buffs: Variant = cc.get("active_buffs")
		if buffs is Array:
			for b in buffs:
				ids.append(b.get("id", "") if b is Dictionary else "")
			if not buffs.is_empty() and buffs[0] is Dictionary:
				marker = buffs[0].get(MARKER, false) == true
	return {"ids": ids, "marker": marker, "non_empty": non_empty}


## Story helper _roundtrip(flags, xp, cycle): _reset_all() -> optional add_xp(xp) -> flags ->
## optional ng_plus_cycle = cycle -> snapshot E, buff ids, totals -> marker on buff 0 -> save under
## the dummy scene -> read the JSON -> _reset_all() and snapshot the reset -> await load_game(1)
## -> snapshot L -> start_new_game_plus() -> snapshot P -> a second start_new_game_plus() -> P2
## -> remove the save files. `hurt` lowers hp and mp before the save (R1); `generations` > 1
## repeats save -> reset -> load that many times before NG+ (R9). It records everything in the
## returned dictionary and asserts nothing, so the number of checks cannot depend on the data.
func _roundtrip(flags: Array, xp: int, cycle: int, hurt: bool = false, generations: int = 1) -> Dictionary:
	var gm := _gm()
	_remove_save_files()
	_reset_all()
	if xp > 0:
		gm.add_xp(xp)
	_set_flags(flags)
	if cycle > 0:
		gm.ng_plus_cycle = cycle
	if hurt:
		gm.player_stats["hp"] = HURT_HP
		gm.player_stats["mp"] = HURT_MP
	var r := {"cycle_in": cycle}
	r["E"] = _snap()
	r["ids_pre"] = _buff_ids()
	r["totals_pre"] = _cc().get_total_stat_mods()
	if not _cc().active_buffs.is_empty():
		_cc().active_buffs[0][MARKER] = true

	var save_ok := true
	var bak_after_save := false
	for _g in generations:
		save_ok = _save_under_dummy() and save_ok
		bak_after_save = FileAccess.file_exists(SAVE_PATH + ".bak")
		var temp_after_save := _temp_leftovers()
		var data := _read_save_json()
		var jb := _json_buffs(data)
		r["json_version"] = str(data.get("version", ""))
		r["json_scene"] = str(data.get("current_scene", ""))
		r["json_ids"] = jb["ids"]
		r["json_marker"] = jb["marker"]
		r["json_cc_non_empty"] = jb["non_empty"]
		_reset_all()
		r["R"] = _snap()
		r["reset_buffs_empty"] = _cc().active_buffs.is_empty()
		r["reset_cycle"] = gm.ng_plus_cycle
		var transitioning_ok := _transition_idle()
		var load_ok: bool = await gm.load_game(SAVE_SLOT)
		_load_log.append({
			"dummy_missing": not ResourceLoader.exists(DUMMY_SCENE),
			"free_travel_empty": gm.get_free_travel_region_id_for_scene(DUMMY_SCENE) == "",
			"transition_idle": transitioning_ok,
			"load_ok": load_ok,
			"scene_null": current_scene == null,
			"json_scene_dummy": str(data.get("current_scene", "")) == DUMMY_SCENE,
			"corrupted": FileAccess.file_exists(SAVE_PATH + ".corrupted"),
			"temp_left": temp_after_save + _temp_leftovers(),
		})
		r["load_ok"] = load_ok
	r["bak_after_save"] = bak_after_save
	r["save_ok"] = save_ok
	r["L"] = _snap()
	r["ids_L"] = _buff_ids()
	r["totals_L"] = _cc().get_total_stat_mods()
	r["marker_L"] = (not _cc().active_buffs.is_empty()) and _cc().active_buffs[0].get(MARKER, false) == true
	r["cycle_L"] = gm.ng_plus_cycle
	print("  NOTE: after the load base_attack is typeof %d (TYPE_INT=%d, TYPE_FLOAT=%d), level typeof %d" % [
		typeof(gm.player_stats.get("base_attack")), TYPE_INT, TYPE_FLOAT, typeof(gm.player_stats.get("level"))])

	gm.start_new_game_plus()
	r["P"] = _snap()
	r["P_buffs_empty"] = _cc().active_buffs.is_empty()
	r["cycle_P"] = gm.ng_plus_cycle
	gm.start_new_game_plus()
	r["P2"] = _snap()
	r["cycle_P2"] = gm.ng_plus_cycle
	_remove_save_files()
	_reset_all()
	gm.current_state = _initial_state
	return r


## True when the SceneTransitions autoload exists and no scene transition is in flight (the
## precondition for a load; asserted, not changed). A missing autoload counts as not idle.
func _transition_idle() -> bool:
	var st: Node = get_root().get_node_or_null("SceneTransitions")
	return st != null and not st.is_transitioning


## Temporary save files that save_game() should have renamed away (.tmp, .bak.tmp) and a
## .corrupted copy, as seen at that moment, before any cleanup.
func _temp_leftovers() -> Array:
	var left: Array = []
	for suffix in [".tmp", ".bak.tmp", ".corrupted"]:
		if FileAccess.file_exists(SAVE_PATH + suffix):
			left.append("save_slot_1.save" + suffix)
	return left


## The checks shared by the five routes that go through the full pipeline (R1, R2, R7, R8, R9):
## AC-1 (current v1.2 save on the load_save_data path), AC-2 (load restores both halves) and
## AC-3 (NG+ after the load does not stack). 19 checks per call, whatever the data.
func _check_pipeline(label: String, r: Dictionary, totals: Dictionary, ids: Array, e_trio: Array, cycle: int) -> void:
	var e: Dictionary = r["E"]
	var l: Dictionary = r["L"]
	var p: Dictionary = r["P"]
	# Preconditions: the run is buffed and differs from every expected result below.
	_check(_trio(e) == e_trio and _trio(e) != _base_trio(), "%s: E base_attack/base_defense/max_hp is the literal %s, not B (got %s)" % [label, e_trio, _trio(e)])
	_check(_totals_match(r["totals_pre"], totals), "%s: totals before the save equal the CHOICE_BUFFS literals %s (got %s)" % [label, totals, r["totals_pre"]])
	_check(r["ids_pre"] == ids, "%s: buff ids before the save are %s (got %s)" % [label, ids, r["ids_pre"]])
	# AC-1: the save.
	_check(r["save_ok"], "%s: save_game(1) returned true" % label)
	_check(r["json_version"] == "1.2.0" and r["json_scene"] == DUMMY_SCENE, "%s: saved JSON is version 1.2.0 with current_scene the dummy (got %s, %s)" % [label, r["json_version"], r["json_scene"]])
	_check(r["json_cc_non_empty"] and r["json_ids"] == r["ids_pre"], "%s: saved choice_consequences is non-empty and its buff ids equal the pre-save ids (got %s)" % [label, r["json_ids"]])
	_check(r["json_marker"], "%s: the marker is on buff 0 in the saved JSON" % label)
	# AC-2: the reset took, so only the load can restore.
	_check(_trio(r["R"]) == _base_trio() and r["reset_buffs_empty"] and r["reset_cycle"] == 0, "%s: after the reset base trio is 15/0/100, no buffs, cycle 0 (got %s, cycle %s)" % [label, _trio(r["R"]), r["reset_cycle"]])
	_check(r["load_ok"], "%s: await load_game(1) returned true" % label)
	_check(_diff_fields(e, l, NINE).is_empty(), "%s: the nine stats after the load equal the pre-save values %s" % [label, _diff_fields(e, l, NINE)])
	_check(r["ids_L"] == r["ids_pre"], "%s: buff ids after the load equal the pre-save ids (got %s)" % [label, r["ids_L"]])
	_check(_totals_match(r["totals_L"], r["totals_pre"]), "%s: totals after the load have the same keys and values as before the save (got %s)" % [label, r["totals_L"]])
	_check(r["marker_L"], "%s: the marker survived the load on buff 0 (load_save_data path, not rebuild_from_flags)" % label)
	_check(r["cycle_L"] == cycle, "%s: ng_plus_cycle is %d after the load (got %s)" % [label, cycle, r["cycle_L"]])
	# AC-3: NG+ straight after the load.
	_check(_trio(p) == _base_trio(), "%s: NG+ after the load gives base_attack/base_defense/max_hp 15/0/100 (got %s)" % [label, _trio(p)])
	_check(r["P_buffs_empty"] and r["cycle_P"] == cycle + 1, "%s: NG+ empties active_buffs and sets ng_plus_cycle %d (got %s)" % [label, cycle + 1, r["cycle_P"]])
	_check(p["hp"] == p["max_hp"] and p["mp"] == p["max_mp"], "%s: NG+ hp == max_hp and mp == max_mp (got %s/%s, %s/%s)" % [label, p["hp"], p["max_hp"], p["mp"], p["max_mp"]])
	_check(_all_int(p, EIGHT), "%s: the eight NG+ stats are TYPE_INT" % label)
	_check(_diff_fields(p, r["P2"], EIGHT).is_empty() and r["cycle_P2"] == cycle + 2, "%s: a second NG+ changes only the cycle (to %d) %s" % [label, cycle + 2, _diff_fields(p, r["P2"], EIGHT)])


# -- R1 ---------------------------------------------------------------------

func _test_r1_kill_route(r: Dictionary) -> void:
	print("-- R1 kill route, hurt before the save, two NG+")
	_check_pipeline("R1", r, KILL_TOTALS, KILL_IDS, [51, 0, 95], 0)
	var e: Dictionary = r["E"]
	_check(e["hp"] == HURT_HP and e["mp"] == HURT_MP and e["mp"] < e["max_mp"] and r["R"]["hp"] != HURT_HP, "R1 precondition: hp 40 and mp 20 (below max) before the save, and the reset puts hp elsewhere")
	_check(r["L"]["hp"] == HURT_HP and r["L"]["mp"] == HURT_MP, "R1: hp 40 and mp 20 survive the load (got %s, %s)" % [r["L"]["hp"], r["L"]["mp"]])


# -- R2 ---------------------------------------------------------------------

func _test_r2_spare_route_cycle_two(r: Dictionary) -> void:
	print("-- R2 spare route, ng_plus_cycle 2")
	_check_pipeline("R2", r, SPARE_TOTALS, SPARE_IDS, [18, 31, 135], 2)
	_check(r["reset_cycle"] == 0 and r["cycle_L"] == 2 and r["cycle_P"] == 3, "R2: ng_plus_cycle is 0 after the reset, 2 after the load, 3 after NG+ (got %s, %s, %s)" % [r["reset_cycle"], r["cycle_L"], r["cycle_P"]])


# -- R3 ---------------------------------------------------------------------

func _test_r3_levelled_vs_control(c: Dictionary, k: Dictionary) -> void:
	print("-- R3 levelled kill run vs a no-buff control, both saved and loaded")
	_check(c["E"]["level"] >= 3 and c["E"]["base_attack"] > B_ATTACK and c["E"]["max_hp"] > B_MAX_HP, "R3 precondition: the control levelled up (level >= 3, got %s)" % [c["E"]["level"]])
	_check(c["totals_pre"].is_empty() and _trio(k["E"]) != _trio(c["E"]), "R3 precondition: the control has no buffs and the kill run's E trio differs from it (buffs applied)")
	_check(c["load_ok"] and k["load_ok"] and c["save_ok"] and k["save_ok"], "R3: both the control and the kill run saved and loaded")
	_check(k["E"]["level"] == c["E"]["level"] and k["P"]["level"] == c["P"]["level"], "R3: kill run level equals the control's before and after NG+ (%s, %s)" % [k["P"]["level"], c["P"]["level"]])
	_check(_diff_fields(k["P"], c["P"], FIVE).is_empty(), "R3: kill run P level/base_attack/base_defense/max_hp/max_mp equal the control's %s" % [_diff_fields(k["P"], c["P"], FIVE)])
	_check(_diff_fields(c["E"], c["L"], NINE).is_empty() and _diff_fields(k["E"], k["L"], NINE).is_empty(), "R3: the nine stats survive the load for both runs")


# -- R4 ---------------------------------------------------------------------

## Story helper _run(flags, xp): reset -> optional add_xp -> flags -> E -> NG+ -> P, in memory, no save.
func _run_case(flags: Array, xp: int = 0) -> Dictionary:
	_reset_all()
	if xp > 0:
		_gm().add_xp(xp)
	_set_flags(flags)
	var e := _snap()
	_gm().start_new_game_plus()
	var p := _snap()
	_reset_all()
	return {"E": e, "P": p}


func _test_r4_save_vs_no_save(kill: Dictionary, spare: Dictionary, kill_lv: Dictionary) -> void:
	print("-- R4 save -> load -> NG+ vs NG+ with no save")
	var m_kill := _run_case(KILL_FLAGS)
	var m_spare := _run_case(SPARE_FLAGS)
	var m_lv := _run_case(KILL_FLAGS, LEVEL_XP)
	_check(_trio(m_kill["E"]) == [51, 0, 95] and _trio(m_spare["E"]) == [18, 31, 135] and m_lv["E"]["level"] >= 3, "R4 precondition: the in-memory runs are buffed (kill 51/0/95, spare 18/31/135, levelled level >= 3)")
	_check(_trio(m_kill["P"]) == _base_trio(), "R4 anchor: in-memory kill NG+ trio is the literal 15/0/100 (got %s)" % [_trio(m_kill["P"])])
	_check(_trio(m_spare["P"]) == _base_trio(), "R4 anchor: in-memory spare NG+ trio is the literal 15/0/100 (got %s)" % [_trio(m_spare["P"])])
	_check(_diff_fields(kill["P"], m_kill["P"], EIGHT).is_empty(), "R4 kill: save->load->NG+ equals NG+ with no save on the eight fields %s" % [_diff_fields(kill["P"], m_kill["P"], EIGHT)])
	_check(_diff_fields(spare["P"], m_spare["P"], EIGHT).is_empty(), "R4 spare: save->load->NG+ equals NG+ with no save on the eight fields %s" % [_diff_fields(spare["P"], m_spare["P"], EIGHT)])
	_check(_diff_fields(kill_lv["P"], m_lv["P"], EIGHT).is_empty(), "R4 levelled kill: save->load->NG+ equals NG+ with no save on the eight fields %s" % [_diff_fields(kill_lv["P"], m_lv["P"], EIGHT)])


# -- R5 ---------------------------------------------------------------------

func _test_r5_load_save_data_path(kill: Dictionary, spare: Dictionary) -> void:
	print("-- R5 the load_save_data path (not rebuild_from_flags)")
	for pair in [["kill", kill, KILL_IDS], ["spare", spare, SPARE_IDS]]:
		var r: Dictionary = pair[1]
		_check(r["json_cc_non_empty"] and r["json_ids"] == pair[2] and r["json_ids"] == r["ids_pre"], "R5 %s: saved choice_consequences is non-empty with the pre-save buff ids %s" % [pair[0], pair[2]])
		_check(r["json_marker"] and r["marker_L"], "R5 %s: the marker on buff 0 is in the save and survives the load" % pair[0])


# -- R7 ---------------------------------------------------------------------

func _test_r7_purge_only(r: Dictionary) -> void:
	print("-- R7 purge only (totals hold only max_hp)")
	_check_pipeline("R7", r, PURGE_TOTALS, PURGE_IDS, [15, 0, 90], 0)
	_check(r["totals_pre"].keys() == ["max_hp"] and r["totals_L"].keys() == ["max_hp"], "R7: the totals key set is exactly {max_hp} before and after the load (got %s, %s)" % [r["totals_pre"], r["totals_L"]])
	_check(is_equal_approx(float(r["totals_pre"].get("max_hp", 0.0)), -10.0) and is_equal_approx(float(r["totals_L"].get("max_hp", 0.0)), -10.0), "R7: max_hp total is -10.0 before and after the load")


# -- R8 ---------------------------------------------------------------------

func _test_r8_flip_before_save(r: Dictionary) -> void:
	print("-- R8 knight killed then spared before the save")
	_check_pipeline("R8", r, FLIP_TOTALS, FLIP_IDS, [15, 5, 115], 0)
	_check(r["json_ids"] == ["guardian_blessing"] and r["ids_L"] == ["guardian_blessing"], "R8: the save and the loaded run hold only guardian_blessing (got %s, %s)" % [r["json_ids"], r["ids_L"]])


# -- R9 ---------------------------------------------------------------------

func _test_r9_second_generation(r: Dictionary) -> void:
	print("-- R9 second generation: save, reset, load, save again, reset, load, NG+")
	_check_pipeline("R9", r, KILL_TOTALS, KILL_IDS, [51, 0, 95], 0)
	_check(r["bak_after_save"], "R9: the second save backed up the first (a .bak exists after it)")


# -- R6 ---------------------------------------------------------------------

func _test_r6_hygiene(listing_before: Array) -> void:
	print("-- R6 hygiene (AC-5a, AC-5b)")
	# Positive control: the directory listing really notices a new file.
	var before_control := _listing()
	var probe := FileAccess.open("user://td002_probe.tmp", FileAccess.WRITE)
	probe.store_string("x")
	probe.close()
	_check(_listing() != before_control, "R6 control: the user:// listing detects a new file")
	DirAccess.remove_absolute(ProjectSettings.globalize_path("user://td002_probe.tmp"))
	_check(_listing() == before_control, "R6 control: the listing is stable once the probe file is removed")

	# AC-5a: every load saw the preconditions, changed no scene, and found no corrupt save.
	var n := _load_log.size()
	var dummy_missing := true
	var free_empty := true
	var idle := true
	var all_ok := true
	var scene_null := true
	var json_dummy := true
	var corrupted := false
	var temp_left: Array = []
	for entry in _load_log:
		dummy_missing = dummy_missing and entry["dummy_missing"]
		free_empty = free_empty and entry["free_travel_empty"]
		idle = idle and entry["transition_idle"]
		all_ok = all_ok and entry["load_ok"]
		scene_null = scene_null and entry["scene_null"]
		json_dummy = json_dummy and entry["json_scene_dummy"]
		corrupted = corrupted or entry["corrupted"]
		temp_left.append_array(entry["temp_left"])
	_check(n == 8, "R6: eight load_game() calls were logged (7 round trips, one with two generations) (got %d)" % n)
	_check(dummy_missing and not ResourceLoader.exists(DUMMY_SCENE), "R6 AC-5a: the dummy scene path does not exist before any load")
	_check(free_empty, "R6 AC-5a: the dummy path is not a free-travel region path before any load")
	_check(idle, "R6 AC-5a: SceneTransitions exists and is_transitioning was false before every load")
	_check(all_ok and scene_null and json_dummy, "R6 AC-5a: every load returned true, left current_scene null, and its saved current_scene was the dummy")
	_check(not corrupted and temp_left.is_empty(), "R6 AC-5b: no .corrupted, .tmp or .bak.tmp file right after any save or load, before cleanup (got %s)" % [temp_left])

	# AC-5b: no leftovers. achievements.save is written by every load; remove it if it is new.
	_remove_save_files()
	var created := _diff(_listing(), listing_before)
	_check(created.is_empty() or created == [ACH_FILE], "R6 AC-5b: the user:// listing grew by nothing or exactly achievements.save (got %s)" % [created])
	if not listing_before.has(ACH_FILE) and FileAccess.file_exists("user://achievements.save"):
		DirAccess.remove_absolute(ProjectSettings.globalize_path("user://achievements.save"))
	_check(_listing() == listing_before, "R6 AC-5b: after cleanup the user:// listing equals the pre-suite listing (got %s)" % [_diff(_listing(), listing_before)])
	_check(_leftover_saves().is_empty(), "R6 AC-5b: no save_slot_1.save* file remains (got %s)" % [_leftover_saves()])


## Entries of `a` that are not in `b`.
func _diff(a: Array, b: Array) -> Array:
	var out: Array = []
	for x in a:
		if not b.has(x):
			out.append(x)
	return out
