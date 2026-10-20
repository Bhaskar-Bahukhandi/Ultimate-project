extends SceneTree
## Tests for story Y1-P0-T07 (production/epics/y1-p0-stabilize/story-t07-ngplus-buffs.md,
## "QA Test Cases" T1-T11, plus T12 from code review): New Game+ must not carry the finishing run's choice
## buffs into the next cycle (decision 6A), and must change nothing else it carries.
## Autoloads only, no scene is loaded. Choice buffs are applied the real way, through
## GameManager.set_story_flag(). Expected values come from the story and from the
## literal CHOICE_BUFFS table, never from computing with the code under test.
## Run: tests/run_phase0_tests.ps1 -Script res://tests/unit/ngplus/ngplus_buff_stacking_test.gd

const OVERWORLD_SCENE := "res://scenes/overworld/overworld.tscn"
const SAVE_SLOT := 1
const SAVE_PATH := "user://save_slot_1.save"

## Baseline B = DEFAULT_PLAYER_STATS (story, "Helper _run").
const B_ATTACK := 15
const B_DEFENSE := 0
const B_MAX_HP := 100

## Flag sets (story T1 / T2). Totals from CHOICE_BUFFS:
## kill:  ATK +36 (8+3+6+10+3+6), DEF 0,  MaxHP -5 (-15 wraith, +10 kaelthas), soul +0.35
## spare: ATK +3,  DEF +31 (5+3+8+5+5+5), MaxHP +35 (15+10+10)
const KILL_FLAGS: Array[String] = [
	"ch1_knight_killed", "ch1_elara_cautious", "ch2_seraphina_rejected",
	"ch2_data_wraith_absorbed", "ch3_lyra_recruited", "ch3_kaelthas_challenged",
]
const SPARE_FLAGS: Array[String] = [
	"ch1_knight_spared", "ch1_elara_trusted", "ch2_seraphina_stayed",
	"ch2_data_wraith_restored", "ch3_lyra_left_alone", "ch3_kaelthas_refused",
]
const PURGE_FLAG := "ch1_root_purge_used"

const LEVEL_XP := 700  # >= 600 XP is level 4 (XP_THRESHOLDS), so level >= 3 holds
const CARRY_CHARM := "extended_parry"
const CARRY_ITEM := "mana_potion"
const CARRY_WEAPON := "iron_sword"  # attack_bonus 10 in Inventory.ITEMS
const CARRY_ARMOR := "leather_armor"  # defense_bonus 5 in Inventory.ITEMS

## AC-5: literal key lists frozen from HEAD (before any T07 change) by a one-off run
## of GameManager.save_game(1) into the isolated user:// dir. GameManager has no
## get_save_data(); save_game() builds the dictionary inline, so the saved file is read.
const FROZEN_SAVE_KEYS: Array = [
	"_checksum", "achievements", "arena_stats", "boss_checkpoints", "choice_consequences",
	"corruption_level", "current_chapter", "current_region", "current_scene", "current_state",
	"dda_performance_score", "dda_recent_deaths", "dda_recent_kills", "equipped_charms",
	"free_travel_story_scene", "glitch_meter", "inventory_equipment", "inventory_gold",
	"inventory_items", "lore_journal", "ng_plus_cycle", "perfect_delete_charges",
	"perfect_delete_used", "player_overworld_position", "player_stats", "playtime_seconds",
	"relationships", "shop_discount", "side_quests", "source_key_count", "speedrun_active",
	"stats", "story_flags", "timestamp", "titles_earned", "unlocked_charms", "version",
]
const FROZEN_CC_KEYS: Array = ["active_buffs", "party_combat_members"]

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
	_test_t1_kill_route_three_cycles()
	_test_t2_spare_and_purge()
	_test_t3_negative_max_hp_total()
	_test_t4_level_up()
	_test_t5_exclusive_flip()
	_test_t6_duplicate_set()
	_test_t7_max_hp_floor()
	_test_t8_carry()
	_test_t9_no_buffs_and_save_keys()
	_test_t10_data_guard()
	_test_t11_soul_gain_not_carried()
	_test_t12_ngplus_twice()
	_reset_all()
	print("")
	print("NGPLUS UNIT RESULT: %d passed, %d failed" % [_passes, _failures.size()])
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


## The nine numbers the story snapshots (E / P).
func _snap() -> Dictionary:
	var ps: Dictionary = _gm().player_stats
	return {
		"base_attack": ps.get("base_attack"), "base_defense": ps.get("base_defense"),
		"max_hp": ps.get("max_hp"), "attack": ps.get("attack"), "defense": ps.get("defense"),
		"hp": ps.get("hp"), "mp": ps.get("mp"), "max_mp": ps.get("max_mp"), "level": ps.get("level"),
	}


func _trio(d: Dictionary) -> Array:
	return [d["base_attack"], d["base_defense"], d["max_hp"]]


func _base_trio() -> Array:
	return [B_ATTACK, B_DEFENSE, B_MAX_HP]


## Story helper _run(flags, xp): reset -> optional add_xp -> flags -> E -> NG+ -> P.
## `flags_first` swaps the order of the XP and the flags (T4).
func _run_case(flags: Array, xp: int = 0, flags_first: bool = false) -> Dictionary:
	_reset_all()
	if flags_first:
		_set_flags(flags)
	if xp > 0:
		_gm().add_xp(xp)
	if not flags_first:
		_set_flags(flags)
	var e := _snap()
	_gm().start_new_game_plus()
	return {"E": e, "P": _snap()}


func _buff_ids() -> Array:
	var ids: Array = []
	for b in _cc().active_buffs:
		ids.append(b.get("id", ""))
	return ids


func _all_int(d: Dictionary, keys: Array) -> bool:
	for k in keys:
		if typeof(d.get(k)) != TYPE_INT:
			return false
	return true


# ── T1 ──────────────────────────────────────────────────────────────────

func _test_t1_kill_route_three_cycles() -> void:
	print("-- T1 kill route, three cycles")
	_reset_all()
	var es: Array = []
	for n in range(1, 4):
		_set_flags(KILL_FLAGS)
		var e := _snap()
		es.append(e)
		_gm().start_new_game_plus()
		var p := _snap()
		print("  T1 E_%d=%s" % [n, e])
		print("  T1 P_%d=%s" % [n, p])
		_check(e["base_attack"] != B_ATTACK and e["max_hp"] != B_MAX_HP, "T1 cycle %d: E_%d differs from B (buffs applied)" % [n, n])
		_check(e["base_attack"] == 51 and e["max_hp"] == 95 and e["base_defense"] == 0, "T1 cycle %d: E_%d is ATK 51 / DEF 0 / HP 95 (literal)" % [n, n])
		_check(_trio(p) == _base_trio(), "T1 cycle %d: P_%d base_attack/base_defense/max_hp == B (got %s)" % [n, n, _trio(p)])
		_check(_gm().ng_plus_cycle == n, "T1 cycle %d: ng_plus_cycle == %d (got %d)" % [n, n, _gm().ng_plus_cycle])
		_check(_cc().active_buffs.is_empty(), "T1 cycle %d: active_buffs empty after NG+" % n)
		_check(p["hp"] == p["max_hp"] and p["mp"] == p["max_mp"], "T1 cycle %d: hp == max_hp and mp == max_mp" % n)
		_check(_all_int(p, ["base_attack", "base_defense", "max_hp", "attack", "defense", "hp"]), "T1 cycle %d: carried stats are TYPE_INT" % n)
	_check(es.size() == 3 and es[0] == es[1] and es[1] == es[2], "T1 E_1 == E_2 == E_3 (no stacking)")


# ── T2 ──────────────────────────────────────────────────────────────────

func _test_t2_spare_and_purge() -> void:
	print("-- T2 spare and purge")
	var spare := _run_case(SPARE_FLAGS)
	var purge := _run_case(SPARE_FLAGS + [PURGE_FLAG])
	var es: Dictionary = spare["E"]
	var ep: Dictionary = purge["E"]
	_check(es["max_hp"] != B_MAX_HP and es["base_defense"] != B_DEFENSE, "T2 spare: E differs from B (buffs applied)")
	_check(es["base_attack"] == 18 and es["base_defense"] == 31 and es["max_hp"] == 135, "T2 spare: E is ATK 18 / DEF 31 / HP 135 (literal)")
	_check(ep["max_hp"] == es["max_hp"] - 10 and ep["max_hp"] == 125, "T2 purge: E.max_hp == spare E.max_hp - 10 (125)")
	_check(_trio(spare["P"]) == _base_trio(), "T2 spare: P == B (got %s)" % [_trio(spare["P"])])
	_check(_trio(purge["P"]) == _base_trio(), "T2 purge: P == B (got %s)" % [_trio(purge["P"])])


# ── T3 ──────────────────────────────────────────────────────────────────

func _test_t3_negative_max_hp_total() -> void:
	print("-- T3 negative max_hp total")
	var r := _run_case(["ch2_data_wraith_absorbed"])
	_check(r["E"]["max_hp"] == 85 and r["E"]["base_attack"] == 25, "T3 E.max_hp == 85 and base_attack == 25 (buff applied)")
	_check(r["P"]["max_hp"] == 100, "T3 P.max_hp == 100 (got %s)" % [r["P"]["max_hp"]])
	_check(r["P"]["base_attack"] == 15, "T3 P.base_attack == 15 (got %s)" % [r["P"]["base_attack"]])


# ── T4 ──────────────────────────────────────────────────────────────────

func _five(d: Dictionary) -> Array:
	return [d["level"], d["base_attack"], d["base_defense"], d["max_hp"], d["max_mp"]]


func _test_t4_level_up() -> void:
	print("-- T4 level-up vs a no-buff control")
	_reset_all()
	_gm().add_xp(LEVEL_XP)
	var c := _snap()
	_check(c["level"] >= 3, "T4 precondition: control level >= 3 (got %s)" % [c["level"]])
	_check(c["max_hp"] > B_MAX_HP and c["base_attack"] > B_ATTACK and c["max_mp"] > 50, "T4 precondition: the level-up grew hp, attack and mp")
	var cases := [["kill", KILL_FLAGS], ["spare", SPARE_FLAGS]]
	for case in cases:
		for flags_first in [false, true]:
			var label := "T4 %s, flags %s XP" % [case[0], "before" if flags_first else "after"]
			var r := _run_case(case[1], LEVEL_XP, flags_first)
			_check(r["E"]["level"] == c["level"], "%s: same level as control (%s)" % [label, r["E"]["level"]])
			_check(_trio(r["E"]) != _trio(c), "%s: E differs from the control (buffs applied)" % label)
			_check(_five(r["P"]) == _five(c), "%s: P level/ATK/DEF/HP/MP == control %s (got %s)" % [label, _five(c), _five(r["P"])])


# ── T5 ──────────────────────────────────────────────────────────────────

func _test_t5_exclusive_flip() -> void:
	print("-- T5 exclusive-group flip")
	_reset_all()
	_gm().set_story_flag("ch1_knight_killed", true)
	_gm().set_story_flag("ch1_knight_spared", true)
	_check(_buff_ids() == ["guardian_blessing"], "T5 knight: active_buffs holds only guardian_blessing (got %s)" % [_buff_ids()])
	var e := _snap()
	_check(e["base_attack"] == 15 and e["base_defense"] == 5 and e["max_hp"] == 115, "T5 knight: E is ATK 15 / DEF 5 / HP 115 (only the spared buff)")
	_gm().start_new_game_plus()
	_check(_trio(_snap()) == _base_trio(), "T5 knight: P == B (got %s)" % [_trio(_snap())])

	_reset_all()
	_gm().set_story_flag("ch2_data_wraith_absorbed", true)
	_gm().set_story_flag("ch2_data_wraith_restored", true)
	_check(_buff_ids() == ["wraith_gratitude"], "T5 wraith: active_buffs holds only wraith_gratitude (got %s)" % [_buff_ids()])
	e = _snap()
	_check(e["base_attack"] == 15 and e["base_defense"] == 5 and e["max_hp"] == 110, "T5 wraith: E is ATK 15 / DEF 5 / HP 110 (only the restored buff)")
	_gm().start_new_game_plus()
	_check(_trio(_snap()) == _base_trio(), "T5 wraith: P == B (got %s)" % [_trio(_snap())])


# ── T6 ──────────────────────────────────────────────────────────────────

func _test_t6_duplicate_set() -> void:
	print("-- T6 duplicate set")
	_reset_all()
	_gm().set_story_flag("ch1_knight_killed", true)
	_gm().set_story_flag("ch1_knight_killed", true)
	_check(_cc().active_buffs.size() == 1, "T6 same flag twice: one active_buffs entry (got %d)" % _cc().active_buffs.size())
	var e := _snap()
	_check(e["base_attack"] == 23, "T6 E.base_attack == 23 (+8 once)")
	_gm().start_new_game_plus()
	_check(_trio(_snap()) == _base_trio(), "T6 P == B (got %s)" % [_trio(_snap())])


# ── T7 ──────────────────────────────────────────────────────────────────

func _test_t7_max_hp_floor() -> void:
	print("-- T7 max_hp floor")
	_reset_all()
	_set_flags(SPARE_FLAGS)
	var total: Dictionary = _cc().get_total_stat_mods()
	var t := int(total.get("max_hp", 0))
	_check(t == 35, "T7 precondition: spare max_hp total T == 35 (got %d)" % t)
	var inputs := [t + 2, t + 1, t, 1]
	var expected := [2, 1, 1, 1]
	for i in inputs.size():
		_reset_all()
		_set_flags(SPARE_FLAGS)
		_gm().player_stats["max_hp"] = inputs[i]
		_gm().start_new_game_plus()
		var p := _snap()
		_check(p["max_hp"] == expected[i], "T7 max_hp %d before NG+ -> %d (got %s)" % [inputs[i], expected[i], p["max_hp"]])
		_check(p["max_hp"] > 0 and p["hp"] == p["max_hp"], "T7 max_hp %d: max_hp > 0 and hp == max_hp" % inputs[i])
		_check(typeof(p["max_hp"]) == TYPE_INT, "T7 max_hp %d: result is TYPE_INT" % inputs[i])


# ── T8 ──────────────────────────────────────────────────────────────────

## Builds a run with every AC-3 carried field populated, snapshots it, calls NG+.
func _carry_run(flags: Array, cycle: int) -> Dictionary:
	_reset_all()
	_set_flags(flags)
	_gm().add_xp(LEVEL_XP)
	_gm().ng_plus_cycle = cycle
	_gm().ng_plus_available = true
	_gm().player_stats["gold"] = 101
	_inv().gold = 101
	_gm().unlock_charm(CARRY_CHARM)
	_gm().equip_charm(CARRY_CHARM)
	_inv().add_item(CARRY_ITEM, 1)
	_inv().add_item(CARRY_WEAPON, 1)
	_inv().equip_item(CARRY_WEAPON, "weapon")
	_inv().add_item(CARRY_ARMOR, 1)
	_inv().equip_item(CARRY_ARMOR, "armor")
	_gm().arena_stats["total_wins"] = 7
	_gm().arena_stats["best_streak"] = 3
	_gm().stats["enemies_killed"] = 12
	_gm().stats["bosses_killed"] = 2
	_gm().stats["death_count"] = 4
	_gm().stats["speedrun_seconds"] = 12.5
	_gm().player_stats["hp"] = 3
	_gm().player_stats["mp"] = 2
	var pre := {
		"level": _gm().player_stats["level"], "max_mp": _gm().player_stats["max_mp"],
		"charms": _gm().unlocked_charms.duplicate(true), "equipped": _gm().equipped_charms.duplicate(),
		"arena": _gm().arena_stats.duplicate(true), "equipment": _inv().equipment.duplicate(true),
		"items": _inv().items.duplicate(true), "stats": _gm().stats.duplicate(true),
	}
	_gm().start_new_game_plus()
	var ps: Dictionary = _gm().player_stats
	var post := {
		"level": ps["level"], "max_mp": ps["max_mp"], "gold_gm": ps["gold"], "gold_inv": _inv().gold,
		"charms": _gm().unlocked_charms.duplicate(true), "equipped": _gm().equipped_charms.duplicate(),
		"arena": _gm().arena_stats.duplicate(true), "equipment": _inv().equipment.duplicate(true),
		"items": _inv().items.duplicate(true), "stats": _gm().stats.duplicate(true),
		"cycle": _gm().ng_plus_cycle, "available": _gm().ng_plus_available,
		"recap": _gm().story_flags.get("ng_plus_route_recap_available", false),
		"hp": ps["hp"], "max_hp": ps["max_hp"], "mp": ps["mp"], "attack": ps["attack"],
		"base_attack": ps["base_attack"], "defense": ps["defense"], "base_defense": ps["base_defense"],
	}
	return {"pre": pre, "post": post}


func _check_carry(label: String, r: Dictionary, cycle: int) -> void:
	var pre: Dictionary = r["pre"]
	var post: Dictionary = r["post"]
	_check(pre["level"] >= 3 and pre["stats"]["death_count"] == 4 and pre["items"].has(CARRY_ITEM) and pre["equipment"]["weapon"] == CARRY_WEAPON 			and pre["equipment"]["armor"] == CARRY_ARMOR \
			and pre["charms"].has(CARRY_CHARM) and pre["equipped"] == [CARRY_CHARM] and pre["arena"]["total_wins"] == 7,
			"%s: setup populated every carried field" % label)
	_check(post["level"] == pre["level"], "%s: level carried (%s)" % [label, post["level"]])
	_check(post["max_mp"] == pre["max_mp"], "%s: max_mp carried (%s)" % [label, post["max_mp"]])
	_check(post["gold_gm"] == 50 and post["gold_inv"] == 50, "%s: both gold fields 101 -> 50 (got %s / %s)" % [label, post["gold_gm"], post["gold_inv"]])
	_check(post["charms"] == pre["charms"], "%s: unlocked_charms carried" % label)
	_check(post["equipped"] == pre["equipped"], "%s: equipped_charms carried" % label)
	_check(post["arena"] == pre["arena"], "%s: arena_stats carried" % label)
	_check(post["equipment"] == pre["equipment"], "%s: Inventory.equipment carried" % label)
	var want_items: Dictionary = pre["items"].duplicate(true)
	want_items["glitch_stabilizer"] = int(want_items.get("glitch_stabilizer", 0)) + 1
	_check(post["items"] == want_items, "%s: Inventory.items carried plus exactly one glitch_stabilizer" % label)
	var want_stats: Dictionary = pre["stats"].duplicate(true)
	want_stats["death_count"] = 0
	_check(post["stats"] == want_stats and post["stats"]["death_count"] == 0, "%s: lifetime stats carried, death_count 0" % label)
	_check(post["cycle"] == cycle + 1, "%s: ng_plus_cycle %d -> %d (got %s)" % [label, cycle, cycle + 1, post["cycle"]])
	_check(post["available"] == false, "%s: ng_plus_available false" % label)
	_check(post["recap"] == true, "%s: ng_plus_route_recap_available true" % label)
	_check(post["hp"] == post["max_hp"] and post["mp"] == post["max_mp"], "%s: hp == max_hp and mp == max_mp" % label)
	_check(post["attack"] == post["base_attack"] + 10, "%s: equipped weapon bonus re-applied (+10 attack)" % label)
	_check(post["defense"] == post["base_defense"] + 5, "%s: equipped armor bonus re-applied (+5 defense, got %s on base %s)" % [label, post["defense"], post["base_defense"]])


func _test_t8_carry() -> void:
	print("-- T8 carry (AC-3)")
	var non_buff_keys := ["level", "max_mp", "gold_gm", "gold_inv", "charms", "equipped", "arena",
			"equipment", "items", "stats", "cycle", "available", "recap"]
	# After NG+ the buffed stats must also match the no-buff run, equipment bonuses included.
	var stat_keys := ["base_attack", "base_defense", "max_hp", "attack", "defense"]
	for cycle in [0, 5]:
		var control := _carry_run([], cycle)
		_check_carry("T8 no-buff cycle %d" % cycle, control, cycle)
		for route in [["kill", KILL_FLAGS], ["spare", SPARE_FLAGS]]:
			var buffed := _carry_run(route[1], cycle)
			_check_carry("T8 %s-route cycle %d" % [route[0], cycle], buffed, cycle)
			var diff: Array[String] = []
			for k in non_buff_keys + stat_keys:
				if control["post"][k] != buffed["post"][k]:
					diff.append("%s: %s vs %s" % [k, control["post"][k], buffed["post"][k]])
			_check(diff.is_empty(), "T8 cycle %d: %s route equals the no-buff run on every carried field and stat %s" % [cycle, route[0], diff])


# ── T9 ──────────────────────────────────────────────────────────────────

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


func _remove_save_files() -> void:
	for suffix in ["", ".bak", ".tmp"]:
		if FileAccess.file_exists(SAVE_PATH + suffix):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_PATH + suffix))


## GameManager has no get_save_data(): build the real save through save_game() under a
## dummy current scene and EXPLORATION state, read the JSON back, delete the files.
func _capture_save() -> Dictionary:
	var gm := _gm()
	var prev_state: int = gm.current_state
	var scene := Node.new()
	scene.name = "T07SaveScene"
	scene.scene_file_path = OVERWORLD_SCENE
	get_root().add_child(scene)
	current_scene = scene
	gm.current_state = gm.GameState.EXPLORATION
	var ok: bool = gm.save_game(SAVE_SLOT)
	var parsed: Variant = null
	if ok:
		parsed = JSON.parse_string(FileAccess.get_file_as_string(SAVE_PATH))
	current_scene = null
	get_root().remove_child(scene)
	scene.free()
	gm.current_state = prev_state
	_remove_save_files()
	var data: Dictionary = parsed if parsed is Dictionary else {}
	var top: Array = data.keys()
	top.sort()
	var cc_keys: Array = []
	if data.get("choice_consequences") is Dictionary:
		cc_keys = data["choice_consequences"].keys()
		cc_keys.sort()
	return {"ok": ok, "top": top, "cc": cc_keys}


func _test_t9_no_buffs_and_save_keys() -> void:
	print("-- T9 no buffs, partial keys, save keys (AC-5)")
	# Positive control: the directory listing really notices a new file.
	var before_control := _listing()
	var probe := FileAccess.open("user://t07_probe.tmp", FileAccess.WRITE)
	probe.store_string("x")
	probe.close()
	_check(_listing() != before_control, "T9 control: the user:// listing detects a new file")
	DirAccess.remove_absolute(ProjectSettings.globalize_path("user://t07_probe.tmp"))
	_check(_listing() == before_control, "T9 control: the listing is stable once the probe file is removed")

	# No buffs: totals are {}, NG+ leaves the run's stats alone, saves unchanged.
	_reset_all()
	_gm().add_xp(LEVEL_XP)
	_check(_cc().get_total_stat_mods().is_empty(), "T9 no flags: get_total_stat_mods() is {}")
	var e := _snap()
	_check(e["level"] >= 3 and _trio(e) != _base_trio(), "T9 no flags: run is above B (level-up applied)")
	var listing_before := _listing()
	var save_before := _capture_save()
	_check(save_before["ok"] and not save_before["top"].is_empty(), "T9 save captured before NG+")
	_gm().start_new_game_plus()
	var listing_after := _listing()
	var save_after := _capture_save()
	var p := _snap()
	_check(_trio(p) == _trio(e), "T9 no flags: P base_attack/base_defense/max_hp == E (got %s, want %s)" % [_trio(p), _trio(e)])
	_check(save_before["top"] == FROZEN_SAVE_KEYS, "T9 save top-level keys before NG+ equal the frozen HEAD list %s" % [save_before["top"]])
	_check(save_before["cc"] == FROZEN_CC_KEYS, "T9 choice_consequences keys before NG+ equal the frozen list %s" % [save_before["cc"]])
	_check(save_after["ok"] and save_after["top"] == FROZEN_SAVE_KEYS, "T9 save top-level keys after NG+ equal the frozen list %s" % [save_after["top"]])
	_check(save_after["cc"] == FROZEN_CC_KEYS, "T9 choice_consequences keys after NG+ equal the frozen list %s" % [save_after["cc"]])
	_check(save_before["top"] == save_after["top"] and save_before["cc"] == save_after["cc"], "T9 save keys equal before and after NG+")
	_check(listing_before == listing_after, "T9 NG+ wrote no file in the user:// save directory (%s vs %s)" % [listing_before, listing_after])

	# Only the unexclusive max_hp buff: partial keys in the totals dictionary.
	_reset_all()
	_gm().set_story_flag(PURGE_FLAG, true)
	var totals: Dictionary = _cc().get_total_stat_mods()
	_check(totals.keys() == ["max_hp"] and is_equal_approx(float(totals["max_hp"]), -10.0), "T9 purge only: totals hold only max_hp -10 (got %s)" % [totals])
	e = _snap()
	_check(e["max_hp"] == 90 and e["base_attack"] == B_ATTACK and e["base_defense"] == B_DEFENSE, "T9 purge only: E is ATK 15 / DEF 0 / HP 90 (buff applied)")
	_gm().start_new_game_plus()
	p = _snap()
	_check(p["base_attack"] == B_ATTACK and p["base_defense"] == B_DEFENSE, "T9 purge only: attack and defense stay at B (missing keys count as 0)")
	# AC-1: a missing key counts as 0 but max_hp is still corrected. Fails on HEAD (stacks -10).
	_check(p["max_hp"] == B_MAX_HP, "T9b purge only: P.max_hp == 100 (got %s)" % [p["max_hp"]])


# ── T10 ─────────────────────────────────────────────────────────────────

func _is_integral(v: Variant) -> bool:
	return (typeof(v) == TYPE_INT) or (typeof(v) == TYPE_FLOAT and is_equal_approx(float(v), roundf(float(v))))


func _test_t10_data_guard() -> void:
	print("-- T10 CHOICE_BUFFS integral guard")
	_check(not _is_integral(2.5) and _is_integral(-15) and _is_integral(8.0), "T10 control: the predicate rejects 2.5 and accepts -15 and 8.0")
	var buffs: Dictionary = _cc().get_script().get_script_constant_map().get("CHOICE_BUFFS", {})
	_check(buffs.size() >= 15, "T10 CHOICE_BUFFS read (%d entries)" % buffs.size())
	var checked := 0
	var bad: Array[String] = []
	var seen := {}
	for flag in buffs:
		var mods: Dictionary = buffs[flag].get("stat_mods", {})
		for stat in ["attack", "defense", "max_hp"]:
			if mods.has(stat):
				checked += 1
				seen[stat] = true
				if not _is_integral(mods[stat]):
					bad.append("%s.%s=%s" % [flag, stat, mods[stat]])
	_check(checked >= 20 and seen.size() == 3, "T10 checked %d attack/defense/max_hp values covering all three stats" % checked)
	_check(bad.is_empty(), "T10 every attack/defense/max_hp buff value is integral %s" % [bad])
	# start_new_game_plus() subtracts only attack/defense/max_hp; a max_mp buff would stack.
	var mp_buffs: Array[String] = []
	for flag in buffs:
		if buffs[flag].get("stat_mods", {}).has("max_mp"):
			mp_buffs.append(flag)
	_check(mp_buffs.is_empty(), "T10 no CHOICE_BUFFS entry modifies max_mp (NG+ does not subtract it) %s" % [mp_buffs])


# ── T11 ─────────────────────────────────────────────────────────────────

func _test_t11_soul_gain_not_carried() -> void:
	print("-- T11 soul_gain_bonus not carried")
	_reset_all()
	_set_flags(KILL_FLAGS)
	var before := float(_gm().player_stats.get("soul_gain_bonus", 0.0))
	_check(is_equal_approx(before, 0.35), "T11 precondition: the kill route set soul_gain_bonus 0.35 (got %s)" % before)
	_gm().start_new_game_plus()
	var after := float(_gm().player_stats.get("soul_gain_bonus", 0.0))
	_check(is_zero_approx(after), "T11 soul_gain_bonus is absent or 0.0 after NG+ (got %s)" % after)


# ── T12 ─────────────────────────────────────────────────────────────────

## Characterization: a second NG+ straight after the first (no run in between) has no
## buffs left to subtract, so it must change nothing but the cycle.
func _test_t12_ngplus_twice() -> void:
	print("-- T12 NG+ twice in a row")
	_reset_all()
	_gm().add_xp(LEVEL_XP)
	_set_flags(KILL_FLAGS)
	_gm().start_new_game_plus()
	var p1 := _snap()
	_gm().start_new_game_plus()
	var p2 := _snap()
	_check(_trio(p1) != _base_trio() and p1["level"] >= 3, "T12 precondition: the level-up carried (P1 above B)")
	_check(_trio(p2) == _trio(p1) and p2["level"] == p1["level"], "T12 P2 base_attack/base_defense/max_hp/level == P1 (got %s, want %s)" % [_trio(p2), _trio(p1)])
	_check(_gm().ng_plus_cycle == 2, "T12 ng_plus_cycle == 2 (got %d)" % _gm().ng_plus_cycle)
