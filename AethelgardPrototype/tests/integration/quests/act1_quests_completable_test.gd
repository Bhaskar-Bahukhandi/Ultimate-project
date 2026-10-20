extends SceneTree
## Y1-P0-T06 scene-level checks: the reachable side quests complete through
## their real hooks, and the Forge Line Supply discount reaches the real shop.
## Story: production/epics/y1-p0-stabilize/story-t06-side-quests.md (QA Test Cases
## AC-3b/3d, AC-4 4a-4d/4i/4k/4m, AC-5 5a-5d, AC-7, A6-1).
## Real scenes: arena district (_show_tier_selection), Underground (entry /
## junction / Data Wraith hooks), Oakhaven region (Iris), Ironhold region (Garro),
## ShopSystem rows and _buy_item. The arena fight itself is not played: the real
## ArenaManager._arena_win is called on a standalone ArenaManager.
## Manager-level rules (reward resolution, saves, sync vectors) live in
## tests/unit/quests/side_quest_rewards_test.gd.
## Run: tests/run_phase0_tests.ps1 -Script res://tests/integration/quests/act1_quests_completable_test.gd

const ARENA := "res://scenes/chapter2/arena_district.tscn"
const UNDER := "res://scenes/chapter2/underground_network.tscn"
const IRONHOLD := "res://scenes/regions/ironhold_region.tscn"
const OAKHAVEN := "res://scenes/regions/oakhaven_region.tscn"
const ARENA_MANAGER_SCRIPT := "res://scripts/combat/arena_manager.gd"

const ARENA_ID := "ironhold_arena_legend"
const HOARD_ID := "ironhold_underground_data"
const IRIS_ID := "oakhaven_memory_herb_delivery"
const GARRO_ID := "ironhold_blacksmith_material_request"
## Dead quests (AC-6) and their step counts before T06 (pinned).
const DEAD_QUESTS := {
	"oakhaven_lost_memories": 4,
	"oakhaven_corrupted_cellar": 3,
	"oakhaven_herbalist_favor": 5,
	"ironhold_merchant_guild": 4,
}
## The arena district's _ready discovers this one (ch2_arena_district.gd ~36,
## pre-existing, untouched by T06): DISCOVERED is allowed after a visit, never more.
const GUILD_ID := "ironhold_merchant_guild"
const DISCOUNTS: Array[float] = [0.0, 0.05, 1.0]
const RICH := 1000000
const IRIS_HERB := "glitch_herb"
const GARRO_ORE := "data_ore"
const DEAD_STEP_LIMIT := 0

var _passes := 0
var _failures: Array[String] = []
var _driving := false
var _picks: Array = []
var _seen_text: Array[String] = []
var _completed: Array[String] = []
var _visited_arena := false
var _park_scene: PackedScene


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	await process_frame
	await process_frame
	if not OS.get_user_data_dir().contains("aeth_phase0_test"):
		push_error("Refusing to run: user data dir is not isolated. Use tests/run_phase0_tests.ps1.")
		quit(2)
		return
	var park := Node.new()
	park.name = "Park"
	_park_scene = PackedScene.new()
	_park_scene.pack(park)
	park.free()
	_sqm().quest_completed.connect(func(id: String) -> void: _completed.append(id))
	Engine.time_scale = 4.0
	_driving = true
	_drive()
	await _test_arena_visits()
	await _test_arena_wins()
	await _test_underground()
	await _test_iris_and_garro()
	await _test_shop_affordability()
	await _test_shop_price_consistency()
	_driving = false
	Engine.time_scale = 1.0
	print("")
	print("QUESTS ACT1 RESULT: %d passed, %d failed" % [_passes, _failures.size()])
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
func _dm() -> Node: return get_root().get_node("DialogueManager")
func _sqm() -> Node: return get_root().get_node("SideQuestManager")
func _inv() -> Node: return get_root().get_node("Inventory")
func _shop() -> Node: return get_root().get_node("ShopSystem")
func _st() -> Node: return get_root().get_node("SceneTransitions")


# ── helpers ─────────────────────────────────────────────────────────────

## Fake player: advances every line and answers choices from _picks (default 0).
func _drive() -> void:
	var dm := _dm()
	while _driving:
		if dm._is_visible and dm._text_label and dm._text_label.text != "":
			var line: String = "%s: %s" % [dm._speaker_label.text, dm._text_label.text]
			if _seen_text.is_empty() or _seen_text.back() != line:
				_seen_text.append(line)
		if dm._awaiting_choice:
			if dm._choice_result == -1 and dm._choice_container != null:
				dm._on_choice_pressed(_picks.pop_front() if not _picks.is_empty() else 0)
		elif dm._is_visible:
			dm._skip_typing = true
			dm._advance_requested = true
		await process_frame


func _saw(fragment: String) -> bool:
	return _seen_text.any(func(l): return l.contains(fragment))


func _wait_for(path: String, timeout_sec: float = 90.0) -> bool:
	var deadline := Time.get_ticks_msec() + int(timeout_sec * 1000.0)
	while Time.get_ticks_msec() < deadline:
		var s := current_scene
		if s and s.scene_file_path == path and not _st().is_transitioning:
			for i in 3:
				await process_frame
			return true
		await process_frame
	return false


func _wait_until(cond: Callable, timeout_sec: float) -> bool:
	var deadline := Time.get_ticks_msec() + int(timeout_sec * 1000.0)
	while Time.get_ticks_msec() < deadline:
		if cond.call():
			return true
		await process_frame
	return cond.call()


func _dialogue_idle(timeout_sec: float = 60.0) -> void:
	await process_frame
	await _wait_until(func(): return not _dm().is_active, timeout_sec)
	for i in 3:
		await process_frame


## Swap to an empty scene so nothing from the previous scene keeps running.
func _park() -> void:
	await _wait_until(func(): return not _st().is_transitioning, 30.0)
	change_scene_to_packed(_park_scene)
	await _wait_until(func(): return current_scene != null and current_scene.name == "Park", 10.0)
	for i in 3:
		await process_frame


func _new_game(level: int) -> void:
	_gm().reset_game()
	_gm().player_stats["level"] = level
	_seen_text.clear()
	_completed.clear()
	_visited_arena = false


func _set_gold(amount: int) -> void:
	# Inventory.gold and GameManager.player_stats["gold"] are separate fields.
	_gm().player_stats["gold"] = amount
	_inv().gold = amount


func _gold() -> int:
	return int(_gm().player_stats.get("gold", 0))


func _state(id: String) -> int:
	return _sqm().get_quest_state(id)


func _step(id: String) -> int:
	return int(_sqm().quests[id]["current_step"])


func _reward(id: String, key: String) -> Variant:
	return _sqm().QUEST_DATABASE[id]["rewards"].get(key)


func _check_dead_quests(label: String) -> void:
	var qs = _sqm().QuestState
	for id in DEAD_QUESTS:
		_check(_sqm().QUEST_DATABASE[id]["steps"].size() == DEAD_QUESTS[id], "%s: %s keeps %d steps" % [label, id, DEAD_QUESTS[id]])
		var st := _state(id)
		var ok: bool = st == qs.HIDDEN
		if id == GUILD_ID and _visited_arena:
			ok = st == qs.HIDDEN or st == qs.DISCOVERED
		_check(ok and _step(id) == DEAD_STEP_LIMIT, "%s: %s not started (state %d, step %d)" % [label, id, st, _step(id)])


## Visit the arena district. Waits for the fight to begin (tier available) or for
## the "no bracket" return to Ironhold (level 0), then parks.
func _visit_arena(label: String) -> void:
	_seen_text.clear()
	_visited_arena = true
	var no_tier := int(_gm().player_stats["level"]) < 1
	change_scene_to_file(ARENA)
	_check(await _wait_for(ARENA, 60.0), "%s: arena district loads" % label)
	var scene := current_scene
	if no_tier:
		_check(await _wait_for(IRONHOLD, 90.0) and _saw("No bracket"), "%s: no tier available, Vex sends the player back to Ironhold" % label)
	else:
		_check(await _wait_until(func(): return is_instance_valid(scene) and scene.get("arena_running") == true, 30.0),
			"%s: the tier selection reaches the fight" % label)
	await _park()


func _arena_win(tier: String, time_attack: bool = false) -> void:
	# Loaded at run time: a static `ArenaManager` reference compiles arena_manager.gd
	# before the autoloads exist ("Identifier not found: GameManager") and breaks the
	# class for the whole run, the arena district's ArenaManager included.
	var am: Node = load(ARENA_MANAGER_SCRIPT).new()
	get_root().add_child(am)
	am.current_tier = tier
	if time_attack:
		am.current_mode = am.ArenaMode.TIME_ATTACK
		am._time_attack_remaining = 10.0
	await am._arena_win()
	await _dialogue_idle()
	am.queue_free()
	await process_frame


func _find_npc(region: Node, npc_name: String) -> Area2D:
	for n in region.find_children("*", "Area2D", true, false):
		if n.get_meta("npc_name", "") == npc_name:
			return n
	return null


## The live buy button of `id` in the open shop (rows are rebuilt after a trade).
func _buy_button(id: String) -> Button:
	var want: String = _shop().SHOP_ITEMS[id]["name"]
	for row in _shop()._item_container.get_children():
		if row.is_queued_for_deletion() or not row is PanelContainer:
			continue
		var labels: Array = row.find_children("*", "Label", true, false)
		if labels.is_empty() or labels[0].text != want:
			continue
		var buttons: Array = row.find_children("*", "Button", true, false)
		if not buttons.is_empty():
			return buttons[0]
	return null


func _shown_price(btn: Button) -> int:
	return int(btn.text.trim_prefix("BUY ").trim_suffix("G"))


func _open_shop(kind: String) -> bool:
	_shop().open_shop(kind)
	for i in 3:
		await process_frame
	return _shop()._is_open


func _close_shop() -> void:
	_shop().close_shop()
	for i in 10:
		await process_frame


func _toast_shown(text: String) -> bool:
	return _shop()._ui_layer.find_children("*", "Label", true, false).any(func(l): return l.text == text)


# ── AC-4: Arena Legend through the real arena district ──────────────────

func _test_arena_visits() -> void:
	print("[AC-4 arena district visits]")
	var qs = _sqm().QuestState
	_new_game(1)
	_check(_state(ARENA_ID) == qs.HIDDEN, "4a setup: Arena Legend HIDDEN in a new game")
	await _visit_arena("4a")
	_check(_state(ARENA_ID) == qs.ACTIVE and _step(ARENA_ID) == 0, "4a first visit starts Arena Legend ACTIVE at step 0")
	_check(_gm().has_flag("ch2_arena_entered"), "4a the first-visit branch ran")
	_check_dead_quests("4a")

	_new_game(1)
	_gm().set_story_flag("ch2_arena_entered", true)
	await _visit_arena("4b")
	_check(_state(ARENA_ID) == qs.ACTIVE and _step(ARENA_ID) == 0, "4b a visit with ch2_arena_entered already set also starts it")

	_new_game(0)
	await _visit_arena("4c")
	_check(_state(ARENA_ID) == qs.ACTIVE and _step(ARENA_ID) == 0, "4c a visit with no tier available still starts it")

	# 4d: progress made since the first visit survives the next visit.
	await _arena_win("bronze")
	_check(_step(ARENA_ID) == 1, "4d setup: a real Bronze win moves the quest to step 1")
	_gm().player_stats["level"] = 1
	await _visit_arena("4d")
	_check(_state(ARENA_ID) == qs.ACTIVE and _step(ARENA_ID) == 1, "4d a second visit neither restarts nor resets it (step 1)")

	_new_game(1)
	_gm().set_story_flag("ch2_arena_silver_complete", true)
	_gm().set_story_flag("ch2_arena_gold_complete", true)
	await _visit_arena("4i")
	_check(_state(ARENA_ID) == qs.ACTIVE and _step(ARENA_ID) == 3, "4i Silver+Gold already cleared: the visit catches up to step 3")
	_check(_completed.is_empty(), "4i catch-up completes nothing early")
	_check_dead_quests("4i")


func _test_arena_wins() -> void:
	print("[AC-4 real ArenaManager._arena_win]")
	var qs = _sqm().QuestState
	_new_game(7)
	_sqm().start_arena_legend()
	_check(_state(ARENA_ID) == qs.ACTIVE and _step(ARENA_ID) == 0, "4k setup: quest ACTIVE at step 0")
	await _arena_win("gold")
	_check(_gm().has_flag("ch2_arena_gold_complete"), "4k _arena_win sets the Gold tier flag")
	_check(_step(ARENA_ID) == 3 and _state(ARENA_ID) == qs.ACTIVE, "4k a Gold win counts Bronze, Silver and Gold (step 3)")
	await _arena_win("gold")
	_check(_step(ARENA_ID) == 3, "4k a repeat Gold win does not advance")
	await _arena_win("silver")
	_check(_step(ARENA_ID) == 3, "4e a later Silver win does not advance")
	var charm: String = _reward(ARENA_ID, "charm")
	_check(not _gm().is_charm_unlocked(charm), "4g setup: %s not unlocked before completion" % charm)
	await _arena_win("platinum", true)
	_check(_gm().has_flag("ch2_arena_platinum_complete"), "4m a Time Attack Platinum win sets the tier flag")
	_check(_state(ARENA_ID) == qs.COMPLETED, "4m the Time Attack win completes Arena Legend")
	_check(_gm().is_charm_unlocked(charm) and _completed.count(ARENA_ID) == 1, "4g %s unlocked, quest_completed once" % charm)
	var titles: int = _gm().titles_earned.size()
	await _arena_win("platinum")
	_check(_state(ARENA_ID) == qs.COMPLETED and _completed.count(ARENA_ID) == 1 and _gm().titles_earned.size() == titles,
		"4g a repeat Platinum win grants nothing more")


# ── AC-5: The Data Hoard through the real Underground ───────────────────

func _enter_underground(label: String) -> Node:
	_seen_text.clear()
	change_scene_to_file(UNDER)
	_check(await _wait_for(UNDER, 60.0), "%s: Underground loads" % label)
	var under := current_scene
	# The entry hook runs 0.5 s after _ready, before the entry dialogue.
	await _wait_until(func(): return _saw(":"), 15.0)
	await _dialogue_idle()
	return under


func _test_underground() -> void:
	print("[AC-5 Underground hooks]")
	var qs = _sqm().QuestState
	_new_game(12)
	var lj := get_root().get_node("LoreJournal")
	var lore: String = _reward(HOARD_ID, "lore")
	_check(not lj.is_discovered(lore), "5b setup: %s not discovered yet" % lore)
	var under := await _enter_underground("5a")
	_check(_state(HOARD_ID) == qs.ACTIVE and _step(HOARD_ID) == 1, "5a first entry: ACTIVE, step 1 (Enter the Underground done)")
	for i in 2:
		under = await _enter_underground("5c re-entry %d" % (i + 1))
	_check(_state(HOARD_ID) == qs.ACTIVE and _step(HOARD_ID) == 1, "5c three entries: still step 1")

	under._on_puzzle_trigger(under.player_node)
	await _dialogue_idle()
	_check(_step(HOARD_ID) == 2, "5b the routing junction: step 2")
	under._puzzle_solved = false   # as after a reload
	under._on_puzzle_trigger(under.player_node)
	await _dialogue_idle()
	_check(_step(HOARD_ID) == 2 and _state(HOARD_ID) == qs.ACTIVE, "5c re-solving with _puzzle_solved reset: still step 2")

	var gold_before := _gold()
	under._on_data_wraith_defeated()
	_check(_state(HOARD_ID) == qs.COMPLETED, "5b the Data Wraith completes The Data Hoard")
	_check(lj.is_discovered(lore) and _completed.count(HOARD_ID) == 1, "5b %s discovered, quest_completed once" % lore)
	_check(_gold() == gold_before + int(_reward(HOARD_ID, "gold")), "5b the gold reward lands")
	_check(await _wait_for(IRONHOLD, 120.0), "5b the Wraith choice, then back up to Ironhold")

	var gold_done := _gold()
	var xp_done: int = int(_gm().player_stats.get("xp", 0))
	under = await _enter_underground("5d")
	under._on_puzzle_trigger(under.player_node)
	await _dialogue_idle()
	_check(_state(HOARD_ID) == qs.COMPLETED and _completed.count(HOARD_ID) == 1, "5d after COMPLETED: re-entry and re-solving restart nothing")
	_check(_gold() == gold_done and int(_gm().player_stats.get("xp", 0)) == xp_done, "5d nothing re-granted (gold, XP)")
	await _park()
	_check_dead_quests("after Underground")

	# Old save: the Wraith is dead (the Underground is closed for good) but the
	# quest is still ACTIVE. Loading the Ironhold region completes it once.
	_new_game(12)
	_sqm().reset()
	_sqm().start_quest(HOARD_ID)
	_sqm().quests[HOARD_ID]["current_step"] = 1
	_gm().set_story_flag("ch2_data_wraith_defeated", true)
	var parsed: Variant = JSON.parse_string(JSON.stringify(_sqm().get_save_data()))
	_sqm().reset()
	_sqm().load_save_data(parsed if parsed is Dictionary else {})
	_completed.clear()
	var gold_old := _gold()
	_check(_state(HOARD_ID) == qs.ACTIVE, "old save loaded: Data Hoard still ACTIVE (load grants nothing)")
	change_scene_to_file(IRONHOLD)
	_check(await _wait_for(IRONHOLD, 90.0), "old save: the Ironhold region loads")
	_check(_state(HOARD_ID) == qs.COMPLETED and _completed.count(HOARD_ID) == 1, "old save: loading Ironhold completes The Data Hoard once")
	_check(_gold() == gold_old + int(_reward(HOARD_ID, "gold")), "old save: the gold reward lands once")
	await _park()
	change_scene_to_file(IRONHOLD)
	await _wait_for(IRONHOLD, 90.0)
	_check(_completed.count(HOARD_ID) == 1 and _gold() == gold_old + int(_reward(HOARD_ID, "gold")), "old save: a second Ironhold load grants nothing")
	await _park()


# ── AC-7: Iris and Garro through their region hooks ─────────────────────

func _test_iris_and_garro() -> void:
	print("[AC-7 Iris (Oakhaven) and Garro (Ironhold)]")
	var qs = _sqm().QuestState
	# No reset: continues from the Underground run, so A6-1 sees every hook.
	change_scene_to_file(OAKHAVEN)
	_check(await _wait_for(OAKHAVEN, 90.0), "Oakhaven region loads")
	await _dialogue_idle()
	var oak := current_scene
	var iris := _find_npc(oak, "Apothecary Iris")
	_check(iris != null, "Apothecary Iris is in the Oakhaven region")
	if iris:
		var g0 := _gold()
		await oak._interact_with_npc(iris)
		await _dialogue_idle()
		_check(_state(IRIS_ID) == qs.ACTIVE and _gold() == g0, "7 Iris without herbs: quest ACTIVE, nothing granted")
		_check(_inv().add_item(IRIS_HERB, 2), "7 setup: two Glitch Herbs in the bag")
		var potion: String = _reward(IRIS_ID, "item")
		var potions: int = _inv().items.get(potion, 0)
		await oak._interact_with_npc(iris)
		await _dialogue_idle()
		_check(_state(IRIS_ID) == qs.COMPLETED and _completed.count(IRIS_ID) == 1, "7 Iris: Memory Herb Delivery completes once")
		_check(_gold() == g0 + int(_reward(IRIS_ID, "gold")) and _inv().items.get(potion, 0) == potions + 1 and not _inv().has_item(IRIS_HERB, 1),
			"7 Iris: herbs taken, gold and %s granted" % potion)
		_inv().add_item(IRIS_HERB, 2)
		var g1 := _gold()
		var bag: Dictionary = _inv().items.duplicate()
		await oak._interact_with_npc(iris)
		await _dialogue_idle()
		_check(_gold() == g1 and _inv().items == bag and _completed.count(IRIS_ID) == 1, "7 Iris again: no gold or inventory change")

	change_scene_to_file(IRONHOLD)
	_check(await _wait_for(IRONHOLD, 90.0), "Ironhold region loads")
	await _dialogue_idle()
	var region := current_scene
	await _wait_until(func(): return not region._city_busy, 60.0)
	var garro := _find_npc(region, "Garro")
	_check(garro != null, "Garro is in the Ironhold region")
	if garro:
		_check(_inv().add_item(GARRO_ORE, 2), "7 setup: two Data Ore in the bag")
		var g0 := _gold()
		await region._interact_npc(garro)
		await _dialogue_idle()
		_check(_state(GARRO_ID) == qs.COMPLETED and _completed.count(GARRO_ID) == 1, "7 Garro: Forge Line Supply completes once")
		_check(_gold() == g0 + int(_reward(GARRO_ID, "gold")) and not _inv().has_item(GARRO_ORE, 1), "7 Garro: ore taken, gold granted")
		_check(is_equal_approx(_gm().shop_discount, float(_reward(GARRO_ID, "shop_discount"))), "7 Garro: shop discount is %.2f" % float(_reward(GARRO_ID, "shop_discount")))
		_inv().add_item(GARRO_ORE, 2)
		var g1 := _gold()
		var bag: Dictionary = _inv().items.duplicate()
		await region._interact_npc(garro)
		await _dialogue_idle()
		_check(_gold() == g1 and _inv().items == bag and _completed.count(GARRO_ID) == 1, "7 Garro again: no gold or inventory change")
	await _park()
	_check_dead_quests("A6-1 after Underground, Iris and Garro")

	# The discount reaches the real shop row; a lower later discount never reduces it.
	var item := "health_potion"
	var base: int = int(_shop().SHOP_ITEMS[item]["buy_price"])
	_set_gold(RICH)
	_check(await _open_shop("apothecary"), "7 the apothecary opens")
	var btn := _buy_button(item)
	var at_garro: int = _shop().get_buy_price(item)
	_check(btn != null and _shown_price(btn) == at_garro and at_garro < base,
		"7 after Garro the %s row shows get_buy_price at 5%% (%d, raw %d)" % [item, at_garro, base])
	await _close_shop()
	_sqm().grant_rewards("act1_probe", {"shop_discount": 0.01})
	_check(await _open_shop("apothecary"), "7 the apothecary reopens")
	btn = _buy_button(item)
	_check(btn != null and _shown_price(btn) == at_garro and is_equal_approx(_gm().shop_discount, 0.05),
		"7 a lower later discount (1%) does not reduce it")
	await _close_shop()


# ── AC-3b/3d: the real shop uses get_buy_price everywhere ───────────────

func _test_shop_affordability() -> void:
	print("[AC-3b affordability at the discounted price]")
	_new_game(1)
	_gm().shop_discount = 0.05
	var item := "health_potion"
	var base: int = int(_shop().SHOP_ITEMS[item]["buy_price"])
	var price: int = _shop().get_buy_price(item)
	_check(price < base, "3b setup: discounted %d < raw %d" % [price, base])
	_set_gold(price)
	_check(await _open_shop("apothecary"), "3b the apothecary opens")
	var btn := _buy_button(item)
	_check(btn != null and _shown_price(btn) == price and not btn.disabled, "3b gold == %d: the row shows %dG and is enabled" % [price, price])
	var owned: int = _inv().items.get(item, 0)
	if btn and not btn.disabled:
		btn.pressed.emit()
	await process_frame
	_check(_gold() == 0 and _inv().items.get(item, 0) == owned + 1, "3b the purchase succeeds and takes %dG" % price)
	await _close_shop()

	_set_gold(price - 1)
	_check(await _open_shop("apothecary"), "3b the apothecary reopens")
	btn = _buy_button(item)
	_check(btn != null and btn.disabled, "3b gold == %d: the buy button is disabled" % (price - 1))
	_shop()._buy_item(item)
	_check(_toast_shown("Not enough gold! Need %dG" % price), "3b the refusal toast names the discounted %dG" % price)
	_check(_gold() == price - 1 and _inv().items.get(item, 0) == owned + 1, "3b the refused purchase takes nothing")
	await _close_shop()


func _test_shop_price_consistency() -> void:
	print("[AC-3d displayed price == gold deducted, every SHOP_ITEMS item]")
	var names := {}
	for id in _shop().SHOP_ITEMS:
		names[_shop().SHOP_ITEMS[id]["name"]] = true
	_check(names.size() == _shop().SHOP_ITEMS.size(), "3d setup: item names are unique (rows are found by name)")
	for d in DISCOUNTS:
		_new_game(1)   # clears charms and the bag, so every row is buyable
		_gm().shop_discount = d
		_set_gold(RICH)
		_check(await _open_shop("all"), "3d @%.2f the full shop opens" % d)
		var bad: Array[String] = []
		for id in _shop().SHOP_ITEMS:
			var btn := _buy_button(id)
			if btn == null or btn.disabled:
				bad.append("%s: no enabled row" % id)
				continue
			var shown := _shown_price(btn)
			var before := _gold()
			btn.pressed.emit()
			await process_frame
			var paid := before - _gold()
			if shown != paid or shown != _shop().get_buy_price(id):
				bad.append("%s shown %d paid %d helper %d" % [id, shown, paid, _shop().get_buy_price(id)])
		_check(bad.is_empty(), "3d @%.2f every item's shown price == gold deducted == get_buy_price %s" % [d, str(bad)])
		await _close_shop()
