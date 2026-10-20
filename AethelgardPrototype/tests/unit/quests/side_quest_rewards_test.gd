extends SceneTree
## Manager-level tests for story Y1-P0-T06 (production/epics/y1-p0-stabilize/
## story-t06-side-quests.md, "QA Test Cases"): quest reward data (A1-1..A1-3),
## SideQuestManager.grant_rewards (AC-2), ShopSystem.get_buy_price (AC-3a/3c),
## Arena Legend sync (AC-4), Data Hoard hooks (AC-5), dead quests (A6-1/A6-2)
## and the save-load step clamp (AC-8). No scene is loaded; autoloads only.
## Expected values come from the story, not from the code under test.
## Run: tests/run_phase0_tests.ps1 -Script res://tests/unit/quests/side_quest_rewards_test.gd

const SCRIPTS_DIR := "res://scripts"
const INVENTORY_SCRIPT := "res://scripts/inventory_system.gd"

const QUEST_COUNT := 15
const ALLOWED_REWARD_KEYS: Array[String] = [
	"xp", "gold", "item", "item_quantity", "stat_boost", "relationship",
	"charm", "title", "shop_discount", "lore",
]
## Merge probes: in SHOP_ITEMS / CraftingSystem.MATERIAL_ITEMS and NOT in the
## base Inventory.ITEMS, so they only resolve once the runtime merge has run.
const SHOP_ONLY_ID := "charm_extended_parry"
const CRAFT_ONLY_ID := "data_ore"

## Story table "Reward mapping" (decision 5): new reward keys per quest.
const MAPPED_REWARDS: Dictionary = {
	"oakhaven_lost_memories": {"item": "memory_shard", "item_quantity": 1},
	"oakhaven_corrupted_cellar": {"item": "data_ore", "item_quantity": 2},
	"oakhaven_herbalist_favor": {"item": "null_potion", "item_quantity": 1},
	"ironhold_arena_legend": {"charm": "extended_parry"},
	"secret_debug_room": {"charm": "null_cloak"},
	"wastes_echo_hunter": {"item": "glitch_stabilizer", "item_quantity": 2},
	"wastes_survivor_cache": {"item": "glitch_stabilizer", "item_quantity": 2},
	"ironhold_underground_data": {"lore": "ironhold_lore_3"},
}
const LYRA_PAST_ID := "wastes_lyra_past"
## "All other rewards ... unchanged": XP / gold of the nine mapped quests before T06.
const PRE_T06_XP_GOLD: Dictionary = {
	"oakhaven_lost_memories": [150, 75],
	"oakhaven_corrupted_cellar": [200, 100],
	"oakhaven_herbalist_favor": [100, 50],
	"ironhold_arena_legend": [500, 300],
	"secret_debug_room": [1000, 500],
	"wastes_echo_hunter": [350, 150],
	"wastes_survivor_cache": [250, 200],
	"ironhold_underground_data": [300, 200],
	"wastes_lyra_past": [200, 0],
}
const FORGE_LINE_ID := "ironhold_blacksmith_material_request"
const MERCHANT_GUILD_ID := "ironhold_merchant_guild"
const HERB_DELIVERY_ID := "oakhaven_memory_herb_delivery"

## AC-3 vectors at 5%: [base, expected].
const DISCOUNT_VECTORS_5PCT: Array = [[0, 0], [1, 1], [10, 10], [30, 29], [45, 43], [80, 76], [120, 114]]

const ARENA_ID := "ironhold_arena_legend"
const ARENA_STEPS := 4
const BRONZE := "ch2_arena_bronze_complete"
const SILVER := "ch2_arena_silver_complete"
const GOLD := "ch2_arena_gold_complete"
const PLATINUM := "ch2_arena_platinum_complete"
const ARENA_CHARM := "extended_parry"

const HOARD_ID := "ironhold_underground_data"
const HOARD_STEPS := 3
const HOARD_LORE := "ironhold_lore_3"
## AC-8: old Data Hoard step -> clamped step.
const HOARD_STEP_MAP: Dictionary = {0: 0, 1: 1, 2: 2, 3: 2, 4: 2, 5: 2}

## A6-1: pre-T06 step counts of the four dead quests.
const DEAD_QUEST_STEPS: Dictionary = {
	"oakhaven_lost_memories": 4,
	"oakhaven_corrupted_cellar": 3,
	"oakhaven_herbalist_favor": 5,
	"ironhold_merchant_guild": 4,
}
const DEAD_SCAN_EXCLUDED: Array[String] = [
	"res://scripts/exploration/oakhaven.gd",
	"res://scripts/chapter2/ch2_ironhold_city.gd",
]
## Pre-existing since the initial commit (not a T06 hook): the arena district
## discovers Merchant's Guild Troubles, which then cannot be started (no Guild
## Master). Pinned exactly, so any new discover call still fails the scan.
const DEAD_DISCOVER_PREEXISTING: Array[String] = [
	"res://scripts/chapter2/ch2_arena_district.gd|ironhold_merchant_guild",
]

const STATE_HIDDEN := 0
const STATE_DISCOVERED := 1
const STATE_ACTIVE := 2
const STATE_COMPLETED := 3

var _passes := 0
var _failures: Array[String] = []
var _completed: Array[String] = []
var _updated: Array[String] = []
var _charms_unlocked: Array[String] = []


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	await process_frame
	await process_frame
	if not OS.get_user_data_dir().contains("aeth_phase0_test"):
		push_error("Refusing to run: user data dir is not isolated. Use tests/run_phase0_tests.ps1.")
		quit(2)
		return
	_sqm().quest_completed.connect(func(id: String) -> void: _completed.append(id))
	_sqm().quest_updated.connect(func(id: String, _step: int) -> void: _updated.append(id))
	_gm().charm_unlocked.connect(func(id: String) -> void: _charms_unlocked.append(id))
	_test_a1_resolution()
	_test_a1_mapping()
	_test_a1_discounts()
	_test_ac2_grant_rewards()
	_test_ac3_buy_price()
	_test_ac3_sell_price()
	_test_ac4_arena()
	_test_ac5_data_hoard()
	_test_a6_dead_quests()
	_test_a6_static_scan()
	_test_ac8_save_load()
	_test_ac8_old_save_data_hoard()
	_reset()
	print("")
	print("QUESTS UNIT RESULT: %d passed, %d failed" % [_passes, _failures.size()])
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
func _sqm() -> Node: return get_root().get_node("SideQuestManager")
func _inv() -> Node: return get_root().get_node("Inventory")
func _shop() -> Node: return get_root().get_node("ShopSystem")
func _lore() -> Node: return get_root().get_node("LoreJournal")
func _craft() -> Node: return get_root().get_node("CraftingSystem")


func _const(node: Node, name: String) -> Variant:
	return node.get_script().get_script_constant_map().get(name)


func _db() -> Dictionary:
	return _const(_sqm(), "QUEST_DATABASE")


## Fresh run state for every case: game, quests, shop discount, lore, signal logs.
func _reset() -> void:
	_gm().reset_game()
	_sqm().reset()
	_gm().shop_discount = 0.0
	var lj := _lore()
	lj._discovered_ids.clear()
	for entry in lj._entries.values():
		entry.discovered = false
	_completed.clear()
	_updated.clear()
	_charms_unlocked.clear()


func _state(id: String) -> int:
	return int(_sqm().quests[id]["state"])


func _step(id: String) -> int:
	return int(_sqm().quests[id]["current_step"])


func _gold() -> int:
	return int(_gm().player_stats.get("gold", 0))


func _xp() -> int:
	return int(_gm().player_stats.get("xp", 0))


func _count(arr: Array, value: String) -> int:
	return arr.filter(func(v: String) -> bool: return v == value).size()


func _set_flag(flag: String) -> void:
	_gm().set_story_flag(flag, true)


# ── A1-1 ────────────────────────────────────────────────────────────────

func _test_a1_resolution() -> void:
	print("-- A1-1 reward resolution")
	_reset()
	var inv := _inv()
	var base_inv: Node = load(INVENTORY_SCRIPT).new()
	var base_items: Dictionary = base_inv.ITEMS.duplicate()
	base_inv.free()
	var shop_items: Dictionary = _const(_shop(), "SHOP_ITEMS")
	var craft_items: Dictionary = _const(_craft(), "MATERIAL_ITEMS")
	var shop_probe_ok: bool = shop_items.has(SHOP_ONLY_ID) and not base_items.has(SHOP_ONLY_ID) \
			and inv.ITEMS.has(SHOP_ONLY_ID)
	var craft_probe_ok: bool = craft_items.has(CRAFT_ONLY_ID) and not base_items.has(CRAFT_ONLY_ID) \
			and inv.ITEMS.has(CRAFT_ONLY_ID)
	_check(shop_probe_ok, "setup: merged item set holds ShopSystem-only id '%s'" % SHOP_ONLY_ID)
	_check(craft_probe_ok, "setup: merged item set holds CraftingSystem-only id '%s'" % CRAFT_ONLY_ID)
	if not (shop_probe_ok and craft_probe_ok):
		_check(false, "A1-1 resolution skipped: merged item set not available")
		return
	var db := _db()
	_check(db.size() == QUEST_COUNT, "QUEST_DATABASE holds %d quests (got %d)" % [QUEST_COUNT, db.size()])
	var bad_keys: Array[String] = []
	var bad_ids: Array[String] = []
	var retired: Array[String] = []
	var resolved := 0
	var charm_info: Dictionary = _const(_gm(), "CHARM_INFO")
	for quest_id in db:
		var rewards: Dictionary = db[quest_id].get("rewards", {})
		for key in rewards:
			if not ALLOWED_REWARD_KEYS.has(key):
				bad_keys.append("%s.%s" % [quest_id, key])
			if key == "ability" or key == "unlock":
				retired.append("%s.%s" % [quest_id, key])
		if rewards.has("item"):
			if inv.ITEMS.has(str(rewards["item"])): resolved += 1
			else: bad_ids.append("%s item %s" % [quest_id, rewards["item"]])
		if rewards.has("charm"):
			if charm_info.has(str(rewards["charm"])): resolved += 1
			else: bad_ids.append("%s charm %s" % [quest_id, rewards["charm"]])
		if rewards.has("lore"):
			if _lore().has_entry(str(rewards["lore"])): resolved += 1
			else: bad_ids.append("%s lore %s" % [quest_id, rewards["lore"]])
	_check(bad_keys.is_empty(), "every reward key is in the allowed set %s" % [bad_keys])
	_check(retired.is_empty(), "no ability / unlock reward remains %s" % [retired])
	_check(bad_ids.is_empty(), "every item / charm / lore reward id resolves %s" % [bad_ids])
	# 12 quests carry one item / charm / lore id each (9 items, 2 charms, 1 lore).
	_check(resolved == 12, "12 item / charm / lore reward ids were checked (got %d)" % resolved)


# ── A1-2 / A1-3 ─────────────────────────────────────────────────────────

func _test_a1_mapping() -> void:
	print("-- A1-2 mapped rewards")
	var db := _db()
	for quest_id in MAPPED_REWARDS:
		var expected: Dictionary = MAPPED_REWARDS[quest_id]
		var rewards: Dictionary = db.get(quest_id, {}).get("rewards", {})
		var ok := not rewards.is_empty()
		for key in expected:
			ok = ok and rewards.has(key) and rewards[key] == expected[key]
		_check(ok, "%s reward is %s (got %s)" % [quest_id, expected, rewards])
	var lyra: Dictionary = db.get(LYRA_PAST_ID, {}).get("rewards", {})
	_check(not lyra.is_empty() and not lyra.has("ability"), "Lyra's Past has no ability reward")
	_check(int(lyra.get("xp", -1)) == 200, "Lyra's Past keeps its 200 XP")
	_check(lyra.get("relationship", {}) == {"lyra": 15}, "Lyra's Past keeps Lyra +15")
	var changed: Array[String] = []
	for quest_id in PRE_T06_XP_GOLD:
		var r: Dictionary = db.get(quest_id, {}).get("rewards", {})
		if int(r.get("xp", -1)) != PRE_T06_XP_GOLD[quest_id][0] or int(r.get("gold", -1)) != PRE_T06_XP_GOLD[quest_id][1]:
			changed.append(quest_id)
	_check(changed.is_empty(), "the nine mapped quests keep their XP and gold %s" % [changed])


func _test_a1_discounts() -> void:
	print("-- A1-3 discounts in data")
	var db := _db()
	var forge: Variant = db.get(FORGE_LINE_ID, {}).get("rewards", {}).get("shop_discount")
	var guild: Variant = db.get(MERCHANT_GUILD_ID, {}).get("rewards", {}).get("shop_discount")
	_check(forge != null and is_equal_approx(float(forge), 0.05), "Forge Line Supply shop_discount is 0.05 (got %s)" % [forge])
	_check(guild != null and is_equal_approx(float(guild), 0.15), "Merchant's Guild shop_discount is 0.15 (got %s)" % [guild])


# ── AC-2 ────────────────────────────────────────────────────────────────

func _grant_case(label: String, rewards: Dictionary, needle: String) -> Array:
	## Grants [param rewards] for "q_test" with 7 gold; checks gold, one returned entry.
	_reset()
	var gold_before := _gold()
	var skipped: Array = _sqm().grant_rewards("q_test", rewards)
	_check(_gold() == gold_before + 7 and _inv().gold == _gold(), "%s: the other reward (7 gold) is still granted" % label)
	_check(skipped.size() == 1 and str(skipped[0]).contains(needle), "%s: one skipped entry naming '%s' (got %s)" % [label, needle, skipped])
	return skipped


func _test_ac2_grant_rewards() -> void:
	print("-- AC-2 grant_rewards")
	_grant_case("unknown item", {"gold": 7, "item": "nope"}, "nope")
	_check(not _inv().items.has("nope"), "unknown item: nothing added to the inventory")

	_grant_case("unknown charm", {"gold": 7, "charm": "nope_charm"}, "nope_charm")
	_check(not _gm().unlocked_charms.has("nope_charm"), "unknown charm: not stored in unlocked_charms")

	_reset()
	var pages_before: int = _lore()._entries.size()
	_check(not _lore().has_entry("nope_lore"), "unknown lore: no page before the grant")
	_grant_case("unknown lore", {"gold": 7, "lore": "nope_lore"}, "nope_lore")
	_check(not _lore().has_entry("nope_lore") and _lore()._entries.size() == pages_before, "unknown lore: no empty page registered")
	_check(not _gm().has_flag("lore_nope_lore"), "unknown lore: no lore_ flag")

	_grant_case("ability", {"gold": 7, "ability": "x"}, "ability")
	_check(not _gm().has_flag("ability_x"), "ability: no ability_x flag")

	_grant_case("unlock", {"gold": 7, "unlock": "x"}, "unlock")
	_check(not _gm().has_flag("unlocked_x"), "unlock: no unlocked_x flag")

	_reset()
	var charms_before: int = _gm().unlocked_charms.size()
	var mixed: Array = _sqm().grant_rewards("q_test", {"item": "nope", "charm": ARENA_CHARM})
	_check(mixed.size() == 1 and str(mixed[0]).contains("nope"), "mixed: one skipped entry, the unknown item (got %s)" % [mixed])
	_check(_gm().unlocked_charms.has(ARENA_CHARM) and _gm().unlocked_charms.size() == charms_before + 1 \
			and _count(_charms_unlocked, ARENA_CHARM) == 1, "mixed: the known charm is unlocked once")

	# Real completion path through complete_quest.
	_reset()
	_sqm().start_quest(HERB_DELIVERY_ID)
	var potions_before: int = _inv().get_item_count("mana_potion")
	_sqm().complete_quest(HERB_DELIVERY_ID)
	_sqm().complete_quest(HERB_DELIVERY_ID)
	_check(_state(HERB_DELIVERY_ID) == STATE_COMPLETED, "complete_quest: Memory Herb Delivery is COMPLETED")
	_check(_gm().has_flag("side_quest_%s_complete" % HERB_DELIVERY_ID), "complete_quest: side_quest_%s_complete is set" % HERB_DELIVERY_ID)
	_check(_count(_completed, HERB_DELIVERY_ID) == 1, "complete_quest: quest_completed emitted once (got %d)" % _count(_completed, HERB_DELIVERY_ID))
	_check(_inv().get_item_count("mana_potion") == potions_before + 1, "complete_quest: the mana_potion reward lands once")


# ── AC-3 ────────────────────────────────────────────────────────────────

func _test_ac3_buy_price() -> void:
	print("-- AC-3a get_buy_price")
	_reset()
	var shop := _shop()
	var shop_items: Dictionary = _const(shop, "SHOP_ITEMS")
	_gm().shop_discount = 0.05
	for v in DISCOUNT_VECTORS_5PCT:
		var got: int = shop.get_buy_price({"buy_price": v[0]})
		_check(got == v[1], "5%%: %d -> %d (got %d)" % [v[0], v[1], got])
	_gm().shop_discount = 0.0
	var changed: Array[String] = []
	for id in shop_items:
		if shop.get_buy_price(id) != int(shop_items[id]["buy_price"]):
			changed.append(id)
	_check(not shop_items.is_empty() and changed.is_empty(), "0%%: every SHOP_ITEMS price unchanged (%d items) %s" % [shop_items.size(), changed])
	_gm().shop_discount = 1.0
	var not_one: Array[String] = []
	var priced := 0
	for id in shop_items:
		if int(shop_items[id]["buy_price"]) > 0:
			priced += 1
			if shop.get_buy_price(id) != 1:
				not_one.append(id)
	_check(priced > 0 and not_one.is_empty(), "100%%: every priced item costs 1 (%d items) %s" % [priced, not_one])
	_gm().shop_discount = 1.5
	_check(shop.get_buy_price({"buy_price": 120}) == 1, "discount 1.5 is clamped to 100% (120 -> 1)")
	_gm().shop_discount = -0.5
	_check(shop.get_buy_price({"buy_price": 120}) == 120, "discount -0.5 is clamped to 0% (120 -> 120)")
	_gm().shop_discount = 0.05
	_check(shop.get_buy_price("health_potion") == 29, "5%: health_potion by id 30 -> 29")
	_check(shop.get_buy_price("no_such_item_id") == 0, "unknown item id -> 0")
	_gm().shop_discount = 0.0


func _sell_button_price(item_id: String, data: Dictionary) -> int:
	## Builds a real sell row (ShopSystem._add_sell_row) and reads its "SELL %dG" button.
	var shop := _shop()
	var container: Node = shop._item_container
	shop._add_sell_row(item_id, data, 1)
	var row: Node = container.get_child(container.get_child_count() - 1)
	var price := -1
	for b in row.find_children("*", "Button", true, false):
		var text: String = b.text
		if text.begins_with("SELL "):
			price = int(text.trim_prefix("SELL ").trim_suffix("G"))
	row.free()
	return price


func _test_ac3_sell_price() -> void:
	print("-- AC-3c sell prices")
	_reset()
	var shop_items: Dictionary = _const(_shop(), "SHOP_ITEMS")
	var differ: Array[String] = []
	var unread: Array[String] = []
	for id in shop_items:
		_gm().shop_discount = 0.0
		var at0 := _sell_button_price(id, shop_items[id])
		_gm().shop_discount = 0.05
		var at5 := _sell_button_price(id, shop_items[id])
		if at0 < 0:
			unread.append(id)
		if at0 != at5 or at0 != int(shop_items[id].get("sell_price", -2)):
			differ.append("%s %d/%d" % [id, at0, at5])
	_gm().shop_discount = 0.0
	_check(not shop_items.is_empty() and unread.is_empty(), "a SELL button was read for every shop item %s" % [unread])
	_check(differ.is_empty(), "sell price identical at 0 and 0.05 for all %d shop items %s" % [shop_items.size(), differ])


# ── AC-4 ────────────────────────────────────────────────────────────────

func _test_ac4_arena() -> void:
	print("-- AC-4 Arena Legend")
	_reset()
	_check(_const(_sqm(), "ARENA_TIER_FLAGS") == [BRONZE, SILVER, GOLD, PLATINUM], "ARENA_TIER_FLAGS are bronze, silver, gold, platinum")
	_check(_db()[ARENA_ID]["steps"].size() == ARENA_STEPS, "Arena Legend has %d steps" % ARENA_STEPS)

	# 4a / 4e
	_sqm().start_arena_legend()
	_check(_state(ARENA_ID) == STATE_ACTIVE and _step(ARENA_ID) == 0, "4a start with no tier cleared: ACTIVE at step 0")
	_set_flag(BRONZE); _sqm().sync_arena_legend()
	_check(_step(ARENA_ID) == 1, "4e Bronze win -> step 1 (got %d)" % _step(ARENA_ID))
	_sqm().sync_arena_legend()
	_check(_step(ARENA_ID) == 1, "4e repeat Bronze win -> still 1")
	_set_flag(GOLD); _sqm().sync_arena_legend()
	_check(_step(ARENA_ID) == 3, "4e Gold win -> step 3 (got %d)" % _step(ARENA_ID))
	_set_flag(SILVER); _sqm().sync_arena_legend()
	_check(_step(ARENA_ID) == 3, "4e later Silver win -> still 3")
	_sqm().sync_arena_legend()
	_check(_step(ARENA_ID) == 3 and _state(ARENA_ID) == STATE_ACTIVE, "4e repeat Gold win -> still 3, ACTIVE")

	# 4j idempotent
	_reset()
	_set_flag(BRONZE)
	_sqm().start_arena_legend()
	var updates := _count(_updated, ARENA_ID)
	for i in 3:
		_sqm().sync_arena_legend()
	_check(_step(ARENA_ID) == 1 and _count(_updated, ARENA_ID) == updates, "4j sync x3 with Bronze cleared: step 1, no extra advance")

	# 4f / 4g
	_reset()
	_sqm().start_arena_legend()
	_updated.clear()
	_set_flag(PLATINUM); _sqm().sync_arena_legend()
	_check(_state(ARENA_ID) == STATE_COMPLETED, "4f Platinum first -> COMPLETED")
	_check(_count(_updated, ARENA_ID) == ARENA_STEPS, "4f exactly %d advances (got %d)" % [ARENA_STEPS, _count(_updated, ARENA_ID)])
	_check(_gm().unlocked_charms.has(ARENA_CHARM) and _count(_charms_unlocked, ARENA_CHARM) == 1, "4g extended_parry unlocked once")
	var gold_after := _gold()
	var xp_after := _xp()
	_sqm().sync_arena_legend()
	_sqm().start_arena_legend()
	_check(_count(_completed, ARENA_ID) == 1, "4g quest_completed once after a repeat Platinum win (got %d)" % _count(_completed, ARENA_ID))
	_check(_gold() == gold_after and _xp() == xp_after and _count(_charms_unlocked, ARENA_CHARM) == 1, "4g repeat Platinum win grants nothing")

	# 4i catch-up at start
	_reset()
	_set_flag(SILVER); _set_flag(GOLD)
	_sqm().start_arena_legend()
	_check(_state(ARENA_ID) == STATE_ACTIVE and _step(ARENA_ID) == 3, "4i start with Silver+Gold cleared -> step 3 (got %d)" % _step(ARENA_ID))
	_reset()
	_set_flag(PLATINUM)
	_sqm().start_arena_legend()
	_check(_state(ARENA_ID) == STATE_COMPLETED and _count(_completed, ARENA_ID) == 1, "4i start with Platinum cleared -> COMPLETED once")

	# 4l not ACTIVE
	_reset()
	_set_flag(GOLD); _sqm().sync_arena_legend()
	_check(_state(ARENA_ID) == STATE_HIDDEN and _step(ARENA_ID) == 0, "4l sync while HIDDEN changes nothing")
	_sqm().discover_quest(ARENA_ID)
	_sqm().sync_arena_legend()
	_check(_state(ARENA_ID) == STATE_DISCOVERED and _step(ARENA_ID) == 0, "4l sync while DISCOVERED changes nothing")

	# 4m a tier flag set by any mode (Time Attack) counts at the next sync
	_reset()
	_sqm().start_arena_legend()
	_set_flag(SILVER)
	_sqm().sync_arena_legend()
	_check(_step(ARENA_ID) == 2, "4m a newly set Silver flag counts: step 2 (got %d)" % _step(ARENA_ID))


# ── AC-5 ────────────────────────────────────────────────────────────────

func _test_ac5_data_hoard() -> void:
	print("-- AC-5 Data Hoard")
	_reset()
	_check(_db()[HOARD_ID]["steps"] == ["Enter the Underground", "Fix the routing junction", "Defeat the Data Wraith"], "Data Hoard has the three story steps")
	_sqm().data_hoard_wraith_defeated()
	_sqm().data_hoard_junction_fixed()
	_check(_state(HOARD_ID) == STATE_HIDDEN, "Wraith / junction before entry change nothing")
	_sqm().data_hoard_entered()
	_check(_state(HOARD_ID) == STATE_ACTIVE and _step(HOARD_ID) == 1, "5a first entry -> ACTIVE, step 1")
	_sqm().data_hoard_entered()
	_sqm().data_hoard_entered()
	_check(_step(HOARD_ID) == 1, "5c entering three times -> still step 1 (got %d)" % _step(HOARD_ID))
	_sqm().data_hoard_junction_fixed()
	_sqm().data_hoard_junction_fixed()
	_check(_step(HOARD_ID) == 2 and _state(HOARD_ID) == STATE_ACTIVE, "5c junction solved twice -> step 2 (got %d)" % _step(HOARD_ID))
	_check(not _lore().is_discovered(HOARD_LORE), "5b %s not discovered before the Wraith" % HOARD_LORE)
	_sqm().data_hoard_wraith_defeated()
	_check(_state(HOARD_ID) == STATE_COMPLETED, "5b Wraith -> COMPLETED")
	_check(_lore().is_discovered(HOARD_LORE), "5b %s discovered" % HOARD_LORE)
	_check(_count(_completed, HOARD_ID) == 1, "5b one quest_completed")
	var gold_after := _gold()
	var xp_after := _xp()
	var step_after := _step(HOARD_ID)
	_sqm().data_hoard_entered()
	_sqm().data_hoard_junction_fixed()
	_sqm().data_hoard_wraith_defeated()
	_check(_state(HOARD_ID) == STATE_COMPLETED and _step(HOARD_ID) == step_after, "5d after COMPLETED, re-entry / re-solve / Wraith restart nothing")
	_check(_gold() == gold_after and _xp() == xp_after and _count(_completed, HOARD_ID) == 1, "5d after COMPLETED nothing is re-granted")

	_reset()
	_sqm().data_hoard_entered()
	_sqm().data_hoard_wraith_defeated()
	_check(_state(HOARD_ID) == STATE_COMPLETED and _count(_completed, HOARD_ID) == 1, "5e Wraith at step 1 completes the quest once")


# ── A6 ──────────────────────────────────────────────────────────────────

func _test_a6_dead_quests() -> void:
	print("-- A6-1 dead quests")
	_reset()
	var db := _db()
	for id in DEAD_QUEST_STEPS:
		var n: int = db.get(id, {}).get("steps", []).size()
		_check(n == DEAD_QUEST_STEPS[id], "%s keeps %d steps (got %d)" % [id, DEAD_QUEST_STEPS[id], n])
	var not_hidden: Array[String] = []
	for id in DEAD_QUEST_STEPS:
		if _state(id) != STATE_HIDDEN:
			not_hidden.append(id)
	_check(not_hidden.is_empty(), "all four dead quests HIDDEN after a reset %s" % [not_hidden])
	# Drive the manager-level hooks of the live quests; the dead ones must not move.
	_sqm().start_quest(HERB_DELIVERY_ID); _sqm().complete_quest(HERB_DELIVERY_ID)
	_sqm().start_quest(FORGE_LINE_ID); _sqm().complete_quest(FORGE_LINE_ID)
	_set_flag(PLATINUM); _sqm().start_arena_legend()
	_sqm().data_hoard_entered(); _sqm().data_hoard_junction_fixed(); _sqm().data_hoard_wraith_defeated()
	not_hidden.clear()
	for id in DEAD_QUEST_STEPS:
		if _state(id) != STATE_HIDDEN:
			not_hidden.append(id)
	_check(not_hidden.is_empty(), "dead quests still HIDDEN after the Iris, Garro, arena and Underground manager hooks %s" % [not_hidden])


func _gd_files(dir_path: String, out: Array[String]) -> void:
	var dir := DirAccess.open(dir_path)
	if dir == null:
		return
	for f in dir.get_files():
		if f.ends_with(".gd"):
			out.append(dir_path.path_join(f))
	for d in dir.get_directories():
		_gd_files(dir_path.path_join(d), out)


func _test_a6_static_scan() -> void:
	print("-- A6-2 static guard")
	var files: Array[String] = []
	_gd_files(SCRIPTS_DIR, files)
	var ids := "|".join(DEAD_QUEST_STEPS.keys())
	var re := RegEx.new()
	re.compile("\\b(start_quest|discover_quest|advance_quest|complete_quest|complete_optional_objective)\\s*\\(\\s*\"(%s)\"" % ids)
	var start_hits: Array[String] = []
	var discover_hits: Array[String] = []
	var progress_hits: Array[String] = []
	var excluded_start_hits := 0
	var scanned := 0
	for path in files:
		var text := FileAccess.get_file_as_string(path)
		var excluded := DEAD_SCAN_EXCLUDED.has(path)
		if not excluded:
			scanned += 1
		for m in re.search_all(text):
			var hit := "%s|%s" % [path, m.get_string(2)]
			if excluded:
				if m.get_string(1) == "start_quest":
					excluded_start_hits += 1
				continue
			match m.get_string(1):
				"start_quest": start_hits.append(hit)
				"discover_quest": discover_hits.append(hit)
				_: progress_hits.append(hit)
	_check(scanned > 0, "scan read %d script files under %s (0 must fail)" % [scanned, SCRIPTS_DIR])
	# Positive control: the orphaned oakhaven.gd does start the dead quests, so the pattern works.
	_check(excluded_start_hits > 0, "pattern finds the start_quest calls in the excluded orphan scripts (%d)" % excluded_start_hits)
	_check(start_hits.is_empty(), "no start_quest of a dead quest outside the orphans %s" % [start_hits])
	_check(progress_hits.is_empty(), "no advance / complete of a dead quest outside the orphans %s" % [progress_hits])
	discover_hits.sort()
	_check(discover_hits == DEAD_DISCOVER_PREEXISTING, "discover_quest of a dead quest only at the pre-existing arena-district call %s" % [discover_hits])


# ── AC-8 ────────────────────────────────────────────────────────────────

func _roundtrip() -> void:
	## get_save_data -> JSON -> reset -> load_save_data, as a real save does.
	var json := JSON.stringify(_sqm().get_save_data())
	var parsed: Variant = JSON.parse_string(json)
	_sqm().reset()
	_sqm().load_save_data(parsed if parsed is Dictionary else {})


func _snapshot() -> Dictionary:
	return {
		"gold": _gold(), "inv_gold": _inv().gold, "xp": _xp(),
		"items": _inv().items.duplicate(true),
		"charms": _gm().unlocked_charms.duplicate(true),
		"flags": _gm().story_flags.duplicate(true),
		"lore": _lore().get_save_data(),
		"lore_pages": _lore()._entries.size(),
		"titles": _gm().titles_earned.duplicate(),
		"discount": _gm().shop_discount,
	}


func _test_ac8_save_load() -> void:
	print("-- AC-8 save / load")
	for old_step in HOARD_STEP_MAP:
		_reset()
		_sqm().start_quest(HOARD_ID)
		_sqm().quests[HOARD_ID]["current_step"] = old_step
		_roundtrip()
		_check(_state(HOARD_ID) == STATE_ACTIVE and _step(HOARD_ID) == HOARD_STEP_MAP[old_step],
				"8b Data Hoard old step %d -> %d (got %d)" % [old_step, HOARD_STEP_MAP[old_step], _step(HOARD_ID)])

	_reset()
	_sqm().start_quest(ARENA_ID)
	_sqm().quests[ARENA_ID]["current_step"] = 4
	_roundtrip()
	_check(_state(ARENA_ID) == STATE_ACTIVE and _step(ARENA_ID) == 3, "8b Arena Legend old step 4 -> 3 (got %d)" % _step(ARENA_ID))

	# 8e negative / oversized ACTIVE steps
	_reset()
	_sqm().start_quest(HOARD_ID)
	_sqm().quests[HOARD_ID]["current_step"] = -4
	_roundtrip()
	_check(_step(HOARD_ID) == 0, "8e negative ACTIVE step -4 -> 0 (got %d)" % _step(HOARD_ID))
	_sqm().quests[HOARD_ID]["current_step"] = 50
	_roundtrip()
	_check(_step(HOARD_ID) == 2, "8e oversized ACTIVE step 50 -> 2 (got %d)" % _step(HOARD_ID))

	# COMPLETED clamped, DISCOVERED untouched, nothing granted by the load (8c)
	_reset()
	_sqm().data_hoard_entered(); _sqm().data_hoard_junction_fixed(); _sqm().data_hoard_wraith_defeated()
	_sqm().quests[HOARD_ID]["current_step"] = 6
	_sqm().discover_quest(ARENA_ID)
	_sqm().quests[ARENA_ID]["current_step"] = 2
	var before := _snapshot()
	_completed.clear()
	_updated.clear()
	_charms_unlocked.clear()
	_roundtrip()
	_check(_state(HOARD_ID) == STATE_COMPLETED and _step(HOARD_ID) == HOARD_STEPS, "COMPLETED step 6 -> %d (got %d)" % [HOARD_STEPS, _step(HOARD_ID)])
	_check(_state(ARENA_ID) == STATE_DISCOVERED and _step(ARENA_ID) == 2, "DISCOVERED entry left alone (step 2)")
	var after := _snapshot()
	var diff: Array[String] = []
	for k in before:
		if before[k] != after[k]:
			diff.append(k)
	_check(diff.is_empty(), "8c gold, XP, inventory, charms, flags, lore unchanged by the load %s" % [diff])
	_check(_completed.is_empty() and _updated.is_empty() and _charms_unlocked.is_empty(), "8c the load emits no quest_completed / quest_updated / charm_unlocked")

	# 8d Arena at step 3 + Platinum completes once on the next sync
	_reset()
	_sqm().start_quest(ARENA_ID)
	_sqm().quests[ARENA_ID]["current_step"] = 3
	_roundtrip()
	_set_flag(PLATINUM)
	_sqm().sync_arena_legend()
	_sqm().sync_arena_legend()
	_check(_state(ARENA_ID) == STATE_COMPLETED and _count(_completed, ARENA_ID) == 1, "8d Arena loaded at 3 + Platinum: COMPLETED once on the next sync")
	_check(_count(_charms_unlocked, ARENA_CHARM) == 1, "8d extended_parry granted once")

	# 8f completed quests loaded: complete / advance / sync are no-ops
	_reset()
	_sqm().data_hoard_entered(); _sqm().data_hoard_wraith_defeated()
	_set_flag(PLATINUM); _sqm().start_arena_legend()
	_check(_state(HOARD_ID) == STATE_COMPLETED and _state(ARENA_ID) == STATE_COMPLETED, "8f setup: both quests COMPLETED before the save")
	_roundtrip()
	var loaded := _snapshot()
	_completed.clear()
	_updated.clear()
	_charms_unlocked.clear()
	_sqm().complete_quest(HOARD_ID)
	_sqm().advance_quest(HOARD_ID)
	_sqm().data_hoard_wraith_defeated()
	_sqm().complete_quest(ARENA_ID)
	_sqm().advance_quest(ARENA_ID)
	_sqm().sync_arena_legend()
	_sqm().start_arena_legend()
	_check(_state(HOARD_ID) == STATE_COMPLETED and _step(HOARD_ID) == HOARD_STEPS \
			and _state(ARENA_ID) == STATE_COMPLETED and _step(ARENA_ID) == ARENA_STEPS, "8f loaded COMPLETED quests keep state and step")
	_check(_completed.is_empty() and _updated.is_empty() and _charms_unlocked.is_empty(), "8f complete / advance / sync after load emit nothing")
	_check(_snapshot() == loaded, "8f complete / advance / sync after load grant nothing")


## Old saves: pre-T06 builds restarted the Data Hoard at step 0 on every entry, and
## a save whose Data Wraith is dead can never re-enter the Underground.
func _test_ac8_old_save_data_hoard() -> void:
	print("-- AC-8 old-save Data Hoard (sync_data_hoard)")
	# 8g ACTIVE at step 0: the load keeps 0 and grants nothing; entry repairs it.
	_reset()
	_sqm().start_quest(HOARD_ID)
	_sqm().quests[HOARD_ID]["current_step"] = 0
	var before := _snapshot()
	_completed.clear()
	_updated.clear()
	_roundtrip()
	_check(_state(HOARD_ID) == STATE_ACTIVE and _step(HOARD_ID) == 0, "8g old save ACTIVE step 0 loads at step 0 (got %d)" % _step(HOARD_ID))
	_check(_snapshot() == before and _completed.is_empty() and _updated.is_empty(), "8g the load grants and emits nothing")
	_sqm().data_hoard_entered()
	_check(_state(HOARD_ID) == STATE_ACTIVE and _step(HOARD_ID) == 1, "8g entry repairs step 0 -> 1 (got %d)" % _step(HOARD_ID))
	_sqm().data_hoard_entered()
	_check(_step(HOARD_ID) == 1, "8g a second entry stays at step 1 (got %d)" % _step(HOARD_ID))
	_sqm().data_hoard_junction_fixed()
	_check(_state(HOARD_ID) == STATE_ACTIVE and _step(HOARD_ID) == 2, "8g the junction then advances to step 2 (got %d)" % _step(HOARD_ID))

	# 8h ACTIVE at step 1 with the Wraith already dead: sync completes it once.
	_reset()
	_sqm().start_quest(HOARD_ID)
	_sqm().quests[HOARD_ID]["current_step"] = 1
	_set_flag("ch2_data_wraith_defeated")
	before = _snapshot()
	_completed.clear()
	_roundtrip()
	_check(_state(HOARD_ID) == STATE_ACTIVE and _snapshot() == before and _completed.is_empty(), "8h old save with the Wraith dead: the load grants nothing")
	_sqm().sync_data_hoard()
	_check(_state(HOARD_ID) == STATE_COMPLETED and _count(_completed, HOARD_ID) == 1, "8h sync_data_hoard completes the quest once")
	_check(_lore().is_discovered(HOARD_LORE) and _lore()._discovered_ids.count(HOARD_LORE) == 1, "8h %s discovered once" % HOARD_LORE)
	var hoard_gold := int(_db()[HOARD_ID]["rewards"]["gold"])
	_check(_gold() == int(before["gold"]) + hoard_gold, "8h the gold reward lands once (+%d)" % hoard_gold)
	var done := _snapshot()
	_sqm().sync_data_hoard()
	_sqm().data_hoard_entered()
	_check(_snapshot() == done and _count(_completed, HOARD_ID) == 1, "8h a second sync / entry after COMPLETED grants nothing")

	# 8i the same at step 0: sync repairs and completes in one call.
	_reset()
	_sqm().start_quest(HOARD_ID)
	_set_flag("ch2_data_wraith_defeated")
	_sqm().sync_data_hoard()
	_check(_state(HOARD_ID) == STATE_COMPLETED and _count(_completed, HOARD_ID) == 1, "8i step 0 + Wraith dead: one sync completes once")

	# 8j HIDDEN / DISCOVERED with the Wraith flag: sync does nothing.
	_reset()
	_set_flag("ch2_data_wraith_defeated")
	before = _snapshot()
	_sqm().sync_data_hoard()
	_check(_state(HOARD_ID) == STATE_HIDDEN and _snapshot() == before, "8j HIDDEN + Wraith flag: sync does nothing")
	_sqm().discover_quest(HOARD_ID)
	before = _snapshot()
	_sqm().sync_data_hoard()
	_check(_state(HOARD_ID) == STATE_DISCOVERED and _snapshot() == before and _completed.is_empty(), "8j DISCOVERED + Wraith flag: sync does nothing")

	# 8k ACTIVE at step 1 without the flag: sync changes nothing.
	_reset()
	_sqm().data_hoard_entered()
	_updated.clear()
	_sqm().sync_data_hoard()
	_check(_state(HOARD_ID) == STATE_ACTIVE and _step(HOARD_ID) == 1 and _updated.is_empty(), "8k ACTIVE step 1, Wraith alive: sync changes nothing")
