extends SceneTree
## Tests for story Y1-P0-T08, Work Package C (production/epics/y1-p0-stabilize/story-t08-flashes-fragment4-nullpotion.md,
## AC-8..AC-11, QA cases N1, N2, N3, N5, N6, N7 plus a corruption parity sweep and a check-order case).
## The Null Potion must be ONE definition (Inventory.ITEMS), heal to max HP, cost corruption through
## GameManager.add_glitch_corruption, and be refused (not consumed) when there is nobody to heal, HP is
## already full, or the corruption cost would reach 100 %.
## A real player_combat instance is used for the heal. Expected values are literals from the story,
## never computed with the code under test. Cases marked [REGRESSION GUARD] pass on the unfixed code too.
## Run: tests/run_phase0_tests.ps1 -Script res://tests/unit/items/null_potion_test.gd

const PLAYER_SCRIPT := "res://scripts/combat/player_combat.gd"
const ITEM := "null_potion"
const CHARM := "corruption_resist"
const MAX_HP := 170
const START_HP := 10
const START_COUNT := 3

const REASON_CORRUPTION := "Corruption would reach 100%."
const REASON_FULL := "HP is already full."
const REASON_NO_PLAYER := "No one to heal."

var _passes := 0
var _failures: Array[String] = []
var _refusals: Array = []
var _orig_stats: Dictionary = {}


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	await process_frame
	await process_frame
	if not OS.get_user_data_dir().contains("aeth_phase0_test"):
		push_error("Refusing to run: user data dir is not isolated. Use tests/run_phase0_tests.ps1.")
		quit(2)
		return
	_orig_stats = {"max_hp": _gm().player_stats.get("max_hp"), "hp": _gm().player_stats.get("hp"), "gold": _gm().player_stats.get("gold")}
	if _inv().has_signal("item_use_refused"):
		_inv().connect("item_use_refused", _on_refused)
	else:
		print("  NOTE: Inventory has no item_use_refused signal")
	_test_n1_one_definition()
	_test_n1_static_scans()
	_test_n2_effect()
	_test_n3_boundaries()
	_test_n3_parity_sweep()
	_test_n5_no_player()
	_test_n6_full_hp()
	_test_check_order()
	_test_n7_shop_buy()
	_reset_all()
	print("")
	print("NULL POTION UNIT RESULT: %d passed, %d failed" % [_passes, _failures.size()])
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
func _inv() -> Node: return get_root().get_node("Inventory")
func _shop() -> Node: return get_root().get_node("ShopSystem")


func _on_refused(item_id: String, reason: String) -> void:
	_refusals.append([item_id, reason])


## Fresh state for every case: players freed, charms/meter/discount/items/gold reset.
func _reset_all() -> void:
	for p in get_nodes_in_group("player"):
		if p.get_parent():
			p.get_parent().remove_child(p)
		p.free()
	_gm().reset_game()
	_gm().current_state = _gm().GameState.MENU
	_inv().items.clear()
	_inv().gold = 0
	_gm().player_stats["gold"] = 0
	_gm().player_stats["max_hp"] = _orig_stats["max_hp"]
	_gm().player_stats["hp"] = _orig_stats["hp"]
	_refusals.clear()


## A real player_combat instance in group "player" (its _ready adds the group).
func _spawn_player(max_hp: int, hp: int) -> Node:
	_gm().player_stats["max_hp"] = max_hp
	_gm().player_stats["hp"] = hp
	var p: Node = load(PLAYER_SCRIPT).new()
	get_root().add_child(p)
	p.max_health = float(max_hp)
	p.current_health = float(hp)
	_gm().player_stats["hp"] = hp
	return p


func _equip_charm(on: bool) -> void:
	_gm().equipped_charms = [CHARM] if on else []


## One use attempt from a clean state. glitch/charm/player/hp/count are the arrange step.
func _attempt(glitch: float, charm: bool, with_player: bool, hp: int, count: int) -> Dictionary:
	_reset_all()
	_equip_charm(charm)
	_gm().glitch_meter = glitch
	_inv().items[ITEM] = count
	var player: Node = null
	if with_player:
		player = _spawn_player(MAX_HP, hp)
	var health_events: Array = []
	if player:
		player.health_changed.connect(func(cur: float, mx: float) -> void: health_events.append([cur, mx]))
	var ok: bool = _inv().use_item(ITEM)
	var r := {
		"ok": ok, "count": int(_inv().items.get(ITEM, 0)), "glitch": float(_gm().glitch_meter),
		"hp": (player.current_health if player else -1.0), "stats_hp": int(_gm().player_stats["hp"]),
		"refusals": _refusals.duplicate(true), "state": _gm().current_state, "events": health_events,
		"max_health": (player.max_health if player else -1.0),
	}
	_reset_all()
	return r


# ── N1 one definition (AC-8) ────────────────────────────────────────────

func _test_n1_one_definition() -> void:
	print("-- N1 one definition")
	_reset_all()
	var inv: Dictionary = _inv().ITEMS[ITEM]
	_check(inv.get("name") == "Null Potion", "N1 Inventory name == 'Null Potion'")
	_check(inv.get("description") == "Full heal. Adds 3% corruption.", "N1 Inventory description == 'Full heal. Adds 3%% corruption.' (got %s)" % [inv.get("description")])
	_check(inv.get("buy_price") == 500 and inv.get("sell_price") == 200, "[REGRESSION GUARD] N1 Inventory buy 500 / sell 200")
	_check(inv.get("type") == "consumable" and inv.get("max_stack") == 99, "[REGRESSION GUARD] N1 Inventory type consumable, max_stack 99")
	_check(inv.has("corruption_cost") and is_equal_approx(float(inv.get("corruption_cost", -1.0)), 3.0), "N1 Inventory corruption_cost == 3.0 (got %s)" % [inv.get("corruption_cost", "<missing>")])

	var items: Dictionary = _shop().SHOP_ITEMS
	var shop: Dictionary = items[ITEM]
	_check(shop.get("name") == inv.get("name") and shop.get("name") == "Null Potion", "N1 shop name equals Inventory name")
	_check(shop.get("description") == inv.get("description") and shop.get("description") == "Full heal. Adds 3% corruption.", "N1 shop description equals Inventory description (got %s)" % [shop.get("description")])
	_check(shop.get("buy_price") == 500 and inv.get("buy_price") == 500, "N1 shop buy_price == 500 (got %s)" % [shop.get("buy_price")])
	_check(shop.get("sell_price") == 200 and inv.get("sell_price") == 200, "N1 shop sell_price == 200 (got %s)" % [shop.get("sell_price")])
	_check(not is_same(shop, inv), "N1 shop entry is a different Dictionary object than the Inventory entry")
	_check(not items.is_read_only(), "N1 SHOP_ITEMS is a mutable var, not a const")
	if not items.is_read_only():
		shop["t08_marker"] = true
		_check(not inv.has("t08_marker"), "N1 copy: mutating the shop entry does not touch the Inventory entry")
		shop.erase("t08_marker")
		inv["t08_marker"] = true
		_check(not shop.has("t08_marker"), "N1 copy: mutating the Inventory entry does not touch the shop entry")
		inv.erase("t08_marker")

	_check(ITEM in _shop().SHOP_CATALOGS["apothecary"], "[REGRESSION GUARD] N1 apothecary catalog lists null_potion")
	_gm().shop_discount = 0.0
	_check(_shop().get_buy_price(ITEM) == 500, "N1 get_buy_price == 500 with no discount (got %d)" % _shop().get_buy_price(ITEM))
	# 10 %: pct = 10, price = (500 * 90 + 50) / 100 = 45050 / 100 = 450 (integer division).
	_gm().shop_discount = 0.10
	_check(_shop().get_buy_price(ITEM) == 450, "N1 get_buy_price == 450 with shop_discount 0.10 (got %d)" % _shop().get_buy_price(ITEM))
	_gm().shop_discount = 0.0


func _read_text(path: String) -> String:
	var f := FileAccess.open(path, FileAccess.READ)
	return f.get_as_text() if f else ""


func _gd_files(dir_path: String, out: Array) -> void:
	var d := DirAccess.open(dir_path)
	if d == null:
		return
	for sub in d.get_directories():
		_gd_files(dir_path.path_join(sub), out)
	for f in d.get_files():
		if f.ends_with(".gd"):
			out.append(dir_path.path_join(f))


func _test_n1_static_scans() -> void:
	print("-- N1 static scans")
	var files: Array = []
	_gd_files("res://scripts", files)
	_check(files.size() > 100, "N1 scan control: read %d scripts under res://scripts" % files.size())
	var blinds: Array = []
	for p in files:
		if _read_text(p).contains("Blinds"):
			blinds.append(p)
	_check(blinds.is_empty(), "N1 no 'Blinds' text left in scripts/ %s" % [blinds])

	var village := _read_text("res://scripts/chapter1/ch1_oakhaven_village.gd")
	_check(village.contains('"id": "red_potion"'), "N1 scan control: village fallback list still read (red_potion present)")
	_check(not village.contains('"id": "null_potion"'), "N1 village fallback list has no null_potion line")
	var shop_src := _read_text("res://scripts/shop_system.gd")
	_check(shop_src.contains('"reduce_glitch"'), "N1 scan control: shop_system.gd read (reduce_glitch branch present)")
	_check(not shop_src.contains("null_heal"), "N1 no null_heal branch left in shop_system.gd")


# ── N2 effect (AC-9) ────────────────────────────────────────────────────

func _test_n2_effect() -> void:
	print("-- N2 effect")
	var r := _attempt(20.0, false, true, START_HP, START_COUNT)
	_check(r["max_health"] == 170.0, "N2 precondition: player.max_health == 170 (agrees with player_stats.max_hp 170)")
	_check(r["ok"] == true, "N2 use_item returns true")
	_check(r["hp"] == 170.0, "N2 current_health 10 -> 170 (got %s)" % [r["hp"]])
	_check(r["stats_hp"] == 170, "N2 player_stats.hp 10 -> 170 (got %s)" % [r["stats_hp"]])
	_check(r["events"].size() >= 1 and r["events"].back() == [170.0, 170.0], "N2 health_changed emitted with (170, 170) (got %s)" % [r["events"]])
	_check(is_equal_approx(r["glitch"], 23.0), "N2 glitch 20.0 -> 23.0 (got %s)" % [r["glitch"]])
	_check(r["count"] == 2, "N2 potion count 3 -> 2 (got %d)" % r["count"])
	_check(r["refusals"].is_empty(), "N2 no refusal signal on a successful use")
	_check(r["state"] != _gm().GameState.GAME_OVER, "N2 no game over")

	var c := _attempt(20.0, true, true, START_HP, START_COUNT)
	_check(c["ok"] == true and c["hp"] == 170.0, "N2 charm: use succeeds, hp 10 -> 170")
	_check(is_equal_approx(c["glitch"], 21.8) and not is_equal_approx(c["glitch"], 23.0), "N2 charm: glitch 20.0 -> 21.8, not 23.0 (got %s)" % [c["glitch"]])
	_check(c["count"] == 2, "N2 charm: potion count 3 -> 2")


# ── N3 corruption refusal (AC-10a) ──────────────────────────────────────

func _test_n3_boundaries() -> void:
	print("-- N3 corruption boundaries")
	# [glitch, charm, refused, expected glitch after]
	var table := [
		[97.0, false, true, 97.0],
		[96.9, false, false, 99.9],
		[96.0, false, false, 99.0],
		[98.5, true, true, 98.5],
		[98.0, true, false, 99.8],
	]
	for row in table:
		var label := "N3 glitch %s%s" % [row[0], " + charm" if row[1] else ""]
		var r := _attempt(row[0], row[1], true, START_HP, START_COUNT)
		_check(r["state"] != _gm().GameState.GAME_OVER, "%s: current_state is not GAME_OVER" % label)
		if row[2]:
			_check(r["ok"] == false, "%s: refused (use_item false)" % label)
			_check(r["count"] == START_COUNT, "%s: not consumed (count stays 3, got %d)" % [label, r["count"]])
			_check(r["hp"] == float(START_HP) and r["stats_hp"] == START_HP, "%s: HP unchanged at 10 (below max 170, so not the full-HP refusal)" % label)
			_check(is_equal_approx(r["glitch"], row[3]), "%s: corruption unchanged at %s (got %s)" % [label, row[3], r["glitch"]])
			_check(r["refusals"] == [[ITEM, REASON_CORRUPTION]], "%s: item_use_refused('null_potion', 'Corruption would reach 100%%.') (got %s)" % [label, r["refusals"]])
		else:
			_check(r["ok"] == true, "%s: allowed (use_item true)" % label)
			_check(is_equal_approx(r["glitch"], row[3]) and not is_equal_approx(row[0], row[3]), "%s: corruption %s -> %s (got %s)" % [label, row[0], row[3], r["glitch"]])
			_check(r["hp"] == 170.0 and r["count"] == START_COUNT - 1, "%s: healed to 170 and one consumed" % label)
			_check(r["refusals"].is_empty(), "%s: no refusal signal" % label)


## Parity (decision 8): "refused" must equal "a real add_glitch_corruption(3.0) would reach game over".
## The real add runs with current_state == GAME_OVER, which makes trigger_corruption_game_over return
## at once (it never changes scene); "reached" is the meter being clamped to 100.0. State is restored.
func _real_add_reaches_game_over(glitch: float, charm: bool) -> bool:
	_reset_all()
	_equip_charm(charm)
	_gm().current_state = _gm().GameState.GAME_OVER
	_gm().glitch_meter = glitch
	_gm().add_glitch_corruption(3.0)
	var reached: bool = _gm().glitch_meter >= 100.0
	_reset_all()
	return reached


func _test_n3_parity_sweep() -> void:
	print("-- N3 parity sweep (real add_glitch_corruption vs refusal)")
	for charm in [false, true]:
		var mismatches: Array[String] = []
		var seen_refused := 0
		var seen_allowed := 0
		for i in range(0, 51):
			var g: float = 95.0 + 0.1 * i
			var real_reaches := _real_add_reaches_game_over(g, charm)
			var r := _attempt(g, charm, true, START_HP, START_COUNT)
			var refused: bool = not r["ok"]
			if real_reaches:
				seen_refused += 1
			else:
				seen_allowed += 1
			if refused != real_reaches or (refused and r["refusals"] != [[ITEM, REASON_CORRUPTION]]) or r["state"] == _gm().GameState.GAME_OVER:
				mismatches.append("glitch %s: refused=%s real_game_over=%s" % [g, refused, real_reaches])
		var label := "charm" if charm else "no charm"
		_check(seen_refused > 0 and seen_allowed > 0, "N3 sweep %s: covers both outcomes (%d refused, %d allowed)" % [label, seen_refused, seen_allowed])
		_check(mismatches.is_empty(), "N3 sweep %s: refusal == real game-over path for 95.0..100.0 step 0.1 %s" % [label, mismatches])


# ── N5 / N6 / order (AC-10 b, c) ────────────────────────────────────────

func _test_n5_no_player() -> void:
	print("-- N5 no player")
	_reset_all()
	_check(get_nodes_in_group("player").is_empty(), "N5 precondition: no node in group 'player'")
	var r := _attempt(20.0, false, false, 0, START_COUNT)
	_check(r["ok"] == false, "N5 refused (use_item false) with nobody to heal")
	_check(r["count"] == START_COUNT, "N5 not consumed (count stays 3, got %d)" % r["count"])
	_check(is_equal_approx(r["glitch"], 20.0), "N5 corruption unchanged at 20.0 (got %s)" % [r["glitch"]])
	_check(r["refusals"] == [[ITEM, REASON_NO_PLAYER]], "N5 item_use_refused('null_potion', 'No one to heal.') (got %s)" % [r["refusals"]])


func _test_n6_full_hp() -> void:
	print("-- N6 full HP")
	var r := _attempt(20.0, false, true, MAX_HP, START_COUNT)
	_check(r["max_health"] == 170.0 and r["hp"] == r["max_health"], "N6 precondition: hp == max_health == 170")
	_check(r["ok"] == false, "N6 refused (use_item false) at full HP")
	_check(r["count"] == START_COUNT, "N6 not consumed (count stays 3, got %d)" % r["count"])
	_check(is_equal_approx(r["glitch"], 20.0), "N6 corruption unchanged at 20.0 (got %s)" % [r["glitch"]])
	_check(r["refusals"] == [[ITEM, REASON_FULL]], "N6 item_use_refused('null_potion', 'HP is already full.') (got %s)" % [r["refusals"]])


## Order of checks: no player, then full HP, then corruption.
func _test_check_order() -> void:
	print("-- check order")
	var a := _attempt(99.0, false, false, 0, START_COUNT)
	_check(a["ok"] == false and a["refusals"] == [[ITEM, REASON_NO_PLAYER]], "ORDER no player + glitch 99.0 -> 'No one to heal.' (got %s)" % [a["refusals"]])
	var b := _attempt(99.0, false, true, MAX_HP, START_COUNT)
	_check(b["ok"] == false and b["refusals"] == [[ITEM, REASON_FULL]], "ORDER full HP + glitch 99.0 -> 'HP is already full.' (got %s)" % [b["refusals"]])
	var c := _attempt(99.0, false, true, START_HP, START_COUNT)
	_check(c["ok"] == false and c["refusals"] == [[ITEM, REASON_CORRUPTION]], "ORDER hurt + glitch 99.0 -> 'Corruption would reach 100%%.' (got %s)" % [c["refusals"]])


# ── N7 shop buy (AC-9) ──────────────────────────────────────────────────

func _buy_with(discount: float) -> Dictionary:
	_reset_all()
	_gm().shop_discount = discount
	_inv().gold = 1000
	_gm().player_stats["gold"] = 1000
	var count_before := int(_inv().items.get(ITEM, 0))
	var gold_before := int(_inv().gold)
	_shop()._buy_item(ITEM)
	var r := {"before": count_before, "gold_before": gold_before, "gold": int(_inv().gold), "stats_gold": int(_gm().player_stats["gold"]), "count": int(_inv().items.get(ITEM, 0))}
	_reset_all()
	return r


func _test_n7_shop_buy() -> void:
	print("-- N7 shop buy")
	var r := _buy_with(0.0)
	_check(r["before"] == 0 and r["gold_before"] == 1000, "N7 precondition (before buying): no potion, gold 1000 (got %d / %d)" % [r["before"], r["gold_before"]])
	_check(r["gold"] == 500 and r["stats_gold"] == 500, "N7 gold 1000 -> 500 (got %d / %d)" % [r["gold"], r["stats_gold"]])
	_check(r["count"] == 1, "N7 one null_potion added (got %d)" % r["count"])
	# 10 %: price 450 (see N1), 1000 - 450 = 550.
	var d := _buy_with(0.10)
	_check(d["gold"] == 550 and d["stats_gold"] == 550, "N7 with shop_discount 0.10: gold 1000 -> 550 (got %d / %d)" % [d["gold"], d["stats_gold"]])
	_check(d["count"] == 1, "N7 discounted: one null_potion added (got %d)" % d["count"])
