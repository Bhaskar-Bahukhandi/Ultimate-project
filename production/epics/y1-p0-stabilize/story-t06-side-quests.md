# Story T06: Make the reachable Act 1 side quests completable and every quest reward real

> **Epic**: Y1-P0 Stabilize (Sprint 001)
> **Task ID**: Y1-P0-T06 (`production/plan/_source/Y1-P0.json#Y1-P0-T06`)
> **Status**: Complete
> **Layer**: Feature
> **Type**: Integration
> **Estimate**: 3 days
> **Manifest Version**: N/A — `docs/architecture/control-manifest.md` does not exist
> **Last Updated**: 2026-10-20

## Context

**GDD**: none exists for side quests. **Design source of record**:
`production/decisions/2026-10-audit-decisions.md` §5 (decision 5A), refined by the user's T06 decisions of
2026-10-20 below, after a code audit found the record's premise incomplete.
**Requirement**: N/A — no TR-ID registered (`docs/architecture/tr-registry.yaml` holds no requirements).

**ADR Governing Implementation**: N/A — data and hook fixes inside the existing `SideQuestManager`; no
architectural decision is made.
**ADR Decision Summary**: N/A
**ADR Version**: N/A

**Engine**: Godot 4.6 (4.6.3 at `C:/Godot`) | **Risk**: HIGH (`docs/engine-reference/godot/VERSION.md`, 4.6 row)
**Engine Notes**: no post-cutoff API expected.

**Control Manifest Rules**: NOT ASSESSED — no control manifest.

**Performance**: no measurable impact expected; quest checks run on events (wins, interactions, entering a
scene), not per frame.

**AGENTS.md protected areas** (explicit user approvals, 2026-10-20):
1. `scripts/combat/arena_manager.gd` `_arena_win` (~:557, quest advance at ~:599-600): ONLY the side-quest
   advance call changes. Fight behaviour, tier flags (~:592-596), rewards of the fight itself: untouched.
2. `scripts/side_quest_manager.gd` load (~:583-607): clamp a saved quest's step index to the quest's current
   step count. Load logic only; the save FORMAT does not change.
Story flags: no new story flag is added or removed (quest completion already writes
`side_quest_<id>_complete`). Combat, collision, Source Key, NG+, world map: untouched. Item and charm data:
only REFERENCED by the new mapping, no new definitions.

### Audit facts (2026-10-20, read-only; line numbers approximate)

- Quests live in `SideQuestManager.QUEST_DATABASE` (`scripts/side_quest_manager.gd` ~29-154), 15 of them.
- Only 2 of the 8 Act 1 quests can finish today: Memory Herb Delivery (Apothecary Iris,
  `scripts/regions/oakhaven_region.gd` ~935-958) and Forge Line Supply (Garro,
  `scripts/regions/ironhold_region.gd` ~975-996).
- Lost Memories, The Corrupted Cellar and The Herbalist's Favor are discovered and started only in
  `scripts/exploration/oakhaven.gd`, a scene nothing loads; their content (cellar, Forge Golem, basement,
  flickering NPC) does not exist. Merchant's Guild Troubles has no Guild Master NPC.
- Arena Legend is discovered (`ch2_arena_district.gd` ~34) but never started (its only `start_quest` is in the
  orphaned `ch2_ironhold_city.gd` ~551). `arena_manager.gd` ~599-600 advances it on ANY win when active; there
  is no Phantom Champion fight. `ch2_arena_district.gd` ~273 always fights the highest tier the level allows.
- The Data Hoard (`ironhold_underground_data`) has 6 cache steps; the Underground
  (`ch2_underground_network.gd`) has no caches: start on entry (~67-68), one advance after the routing junction
  (~372-373), the Data Wraith boss (~389). The scene-local `_puzzle_solved` lets re-entry advance again.
- `complete_quest` (~269-323): item → `Inventory.add_item` (unknown → `push_warning`, nothing granted,
  `inventory_system.gd` ~268-270); charm → `GameManager.unlock_charm` (any id stored; only `CHARM_INFO` keys,
  `game_manager.gd` ~58-66, are shown); lore → `LoreJournal.discover` (unknown ids auto-register an empty
  page, `lore_journal.gd` ~74-76); `unlock` / `ability` / `title` / `shop_discount` are set but read by nothing
  (shop price is plain `buy_price`, `shop_system.gd` ~741, ~885).
- Save: quest state and rewards share one save; loading drops quest ids no longer in the table (~593);
  `complete_quest` returns early for COMPLETED quests (~272), so no double grant within a run or on reload.

### User decisions (2026-10-20)

1. **Dead quests** (Lost Memories, The Corrupted Cellar, The Herbalist's Favor, Merchant's Guild Troubles):
   leave them in the table, unreachable as today; only their rewards change; recorded for a later content pass.
2. **Arena Legend**: starts at the first arena-district visit (Vex); steps = Bronze, Silver, Gold, Platinum
   (Phantom Champion step dropped, per 5A); a step advances on the first clear of its tier **or a higher tier**
   (the arena always fights the highest tier the level allows); repeat wins never advance.
3. **The Data Hoard**: 3 real steps — "Enter the Underground", "Fix the routing junction", "Defeat the Data
   Wraith" — each advanced once, re-entry guarded.
4. **Rewards**: every reward of all 15 quests resolves to something real; `grant_rewards` errors on unknown ids
   of every kind; `shop_discount` applies at the shop. Titles and the unread `side_quest_*` flags: recorded,
   untouched.
5. **Reward mapping** (approved as proposed):

| Quest | Old reward | New reward |
|---|---|---|
| Lost Memories (`oakhaven_lost_memories`) | item `memory_crystal` | item `memory_shard` ×1 |
| The Corrupted Cellar (`oakhaven_corrupted_cellar`) | item `forge_heart` | item `data_ore` ×2 |
| The Herbalist's Favor (`oakhaven_herbalist_favor`) | unlock `null_heal_potion` | item `null_potion` ×1 (decision 9) |
| Arena Legend (`ironhold_arena_legend`) | charm `arena_veteran` | charm `extended_parry` |
| The Debug Room (`secret_debug_room`) | charm `developer_insight` | charm `null_cloak` |
| Echo Hunter (`wastes_echo_hunter`) | ability `echo_sense` | item `glitch_stabilizer` ×2 |
| Lyra's Past (`wastes_lyra_past`) | ability `lyra_power_shot` | removed (XP + Lyra relationship +15 stay) |
| Survivor's Cache (`wastes_survivor_cache`) | item `stabilizer_mk2` | item `glitch_stabilizer` ×2 |
| The Data Hoard (`ironhold_underground_data`) | lore `sovereign_origin_fragment` | lore `ironhold_lore_3` |

All other rewards (XP, gold, stat boosts, relationships, titles, existing items) are unchanged.

2026-10-20, after QL-STORY-READY:
6. **Arena catch-up**: the catch-up check runs when the quest starts and after every win in any mode that
   sets the tier flags (Time Attack included); a save with tiers already cleared may complete the quest at the
   next district visit, with the normal completion notice and the charm granted once.
7. **Data Hoard**: defeating the Data Wraith completes the quest from any ACTIVE step.
8. **Rounding**: half-up integer rounding with a 1G minimum for priced items; free items stay free.

---

## Acceptance Criteria

- [ ] AC-1 The mapping above is applied in `QUEST_DATABASE`. For every reward of every quest: an `item` id
      exists in `Inventory.ITEMS` once the shop and crafting items are merged in (as at runtime); a `charm` id
      is a `GameManager.CHARM_INFO` key; a `lore` id is a registered LoreJournal entry (checked with a lookup
      that does not auto-register, e.g. a new `LoreJournal.has_entry(id)`). No `ability` or `unlock` reward
      remains anywhere, and every reward key is one of `xp, gold, item, item_quantity, stat_boost, relationship,
      charm, title, shop_discount, lore`.
- [ ] AC-2 Reward granting goes through a testable `SideQuestManager.grant_rewards(quest_id: String,
      rewards: Dictionary) -> Array[String]` called by `complete_quest`. For each unknown item / charm / lore id,
      and for each `ability` / `unlock` entry, it raises exactly one `push_error` naming the quest id and the
      reward, skips that entry (no `ability_*` / `unlocked_*` flag, no empty lore page, no stored unknown charm),
      returns the skipped entries, and still grants the quest's other rewards. The quest still completes.
- [ ] AC-3 One helper, `ShopSystem.get_buy_price(item) -> int`, is used by the displayed price, the
      affordability check, the "Need %dG" message and the gold deducted. Rule, in integers:
      `pct = clampi(roundi(GameManager.shop_discount * 100.0), 0, 100)`;
      `price = (base * (100 - pct) + 50) / 100` (half-up); `price = maxi(1, price)` when `base > 0`; `base <= 0`
      stays 0. At 0.05: 0→0, 1→1, 10→10, 30→29, 45→43, 80→76, 120→114. With `shop_discount` 0 every price is
      identical to before; sell prices are unchanged; sorting by raw `buy_price` may stay.
- [ ] AC-4 Arena Legend: still discovered as today; started at the top of `_show_tier_selection`
      (`ch2_arena_district.gd`), outside the first-visit `ch2_arena_entered` branch and before any "no tier
      available" return, whenever it is HIDDEN or DISCOVERED. 4 steps (Bronze, Silver, Gold, Platinum). An
      idempotent `SideQuestManager.sync_arena_legend()` runs at start and after every arena win: with `h` = the
      highest cleared tier index from the `ch2_arena_*_complete` flags (bronze 0 … platinum 3), while the quest is
      ACTIVE and `current_step <= h`, advance. So a Gold win counts Bronze and Silver too, a repeat win never
      advances, Platinum first completes all four, and a save with tiers already cleared catches up at start
      (decision 6). `_arena_win` keeps setting the tier flags before the sync.
- [ ] AC-5 The Data Hoard: 3 steps ("Enter the Underground", "Fix the routing junction", "Defeat the Data
      Wraith"). Entry starts it and completes step 1 only if it was not already ACTIVE or COMPLETED; the junction
      completes step 2 only when `current_step == 1`; defeating the Data Wraith completes it from any ACTIVE step
      (decision 7). Re-entering or re-solving never advances it twice (guarded by quest state, not by the
      scene-local `_puzzle_solved`); after COMPLETED nothing restarts or re-grants.
- [ ] AC-6 Lost Memories, The Corrupted Cellar, The Herbalist's Favor and Merchant's Guild Troubles keep their
      steps and stay unreachable exactly as today (no new start/advance hooks); only their rewards change.
- [ ] AC-7 Memory Herb Delivery (Iris) and Forge Line Supply (Garro) still complete through their existing
      hooks, rewards land once; Forge Line Supply's 5% discount now changes shop buy prices (AC-3).
- [ ] AC-8 Saves: completing a quest then saving and loading does not re-grant its rewards. On load, an ACTIVE
      quest's step index is clamped with `clampi(step, 0, steps.size() - 1)` and a COMPLETED quest's to
      `steps.size()`; DISCOVERED / HIDDEN entries are left alone. So the Data Hoard maps old steps
      {0→0, 1→1, 2→2, 3→2, 4→2, 5→2} and Arena Legend old step 4 → 3. Loading raises no error, grants nothing
      and emits no `quest_completed`.
- [ ] AC-9 `tests/unit/quests/side_quest_rewards_test.gd` and
      `tests/integration/quests/act1_quests_completable_test.gd` exist and pass, and are registered in
      `tests/run_all_tests.ps1` and `.github/workflows/ci.yml` (the layout guard requires both). The full suite
      passes and `git diff --check` is clean.

---

## Implementation Notes

- **Reward resolution needs the runtime item set.** `ShopSystem` and `CraftingSystem` merge their items into
  `Inventory.ITEMS` at runtime (`shop_system.gd` ~217-225, `crafting_system.gd` ~190-195), so the unit test must
  run with those autoloads loaded (as the existing SceneTree suites do), or resolve against the same merged set.
- **Seams for testing.** `QUEST_DATABASE` is a `const` (`side_quest_manager.gd:27`), so AC-2 needs
  `grant_rewards(quest_id, rewards) -> Array[String]` to test unknown ids with synthetic reward dictionaries.
  `LoreJournal.discover` auto-registers unknown ids, so AC-1 needs a non-registering `has_entry(id)` (run after
  `_ready`).
- **Arena start hook.** At the top of `_show_tier_selection` (`ch2_arena_district.gd` ~252), outside the
  `if not GameManager.has_flag("ch2_arena_entered")` first-visit branch (~255), so saves that already visited
  also start it; then call `sync_arena_legend()`. The sync reads the tier flags `_arena_win` sets (~592-596)
  before the existing advance call (~599-600), which the sync replaces.
- **Data Hoard hooks.** Start + step 1 on entry (~67-68), step 2 at the routing junction (~372-373), complete at
  the Data Wraith defeat (~389), each guarded by quest state as in AC-5.
- **Shop discount.** `get_buy_price()` is the one place; the UI row (`shop_system.gd` ~741) and `_buy_item`
  (~885) both call it. Integer math needs `@warning_ignore("integer_division")`. `load_save_data` already clamps
  `shop_discount` to 0..1 (`game_manager.gd` ~1624). Two discounts combine with `maxf` (existing behaviour).
- **Headless scenes.** If the arena district, the Underground or the region scenes can't run headless in the
  SceneTree style, test those hooks at manager level and record a short playtest for the scene wiring in
  `production/qa/evidence/2026-10-side-quests/` (mark that part DEFERRED, not skipped).
- **Tests.** The project's suites are custom SceneTree scripts (`_check` style, see
  `tests/integration/story/chapter1_route_test.gd`), run with `tests/run_phase0_tests.ps1 -Script res://…`.
  `tests/unit/` does not exist yet: create `tests/unit/quests/` (lowercase; each suite needs its `.uid` beside it
  per the layout guard `tests/integration/meta/test_layout_test.gd`).
- Add a short CHANGELOG entry. Commit only with the user's OK, with `Task: Y1-P0-T06` in the body.

---

## Out of Scope

- New content for the four dead quests (later content pass), new hooks for them.
- The inventory/shop price mismatches for the same item; item and charm balance.
- Titles and the `side_quest_<id>_complete` / `unlocked_*` / `ability_*` / `lore_*` flags being unread.
- NG+ re-granting quest rewards and stacking their stat boosts (belongs to Y1-P0-T07).
- The orphaned `scenes/exploration/oakhaven.tscn` and `scenes/chapter2/ironhold_city.tscn` and their scripts.
- Lore: Mara is the apothecary in Chapter 1 but "Oakhaven's baker" in `dialogue/ch2/underground.dlg:4`.
- Arena fight behaviour, tier selection, fight rewards (AGENTS.md: combat).

---

## QA Test Cases

*Reviewed by qa-lead (QL-STORY-READY, 2026-10-20: GAPS → cases below adopted). Manager-level cases are
deterministic and fit the project's `_check`-style SceneTree suites; scene-hook parts follow the "Headless
scenes" note. Watch each new case fail before trusting it.*

- **A1-1 resolution, non-vacuous** — Given the merged item set (setup fails unless it contains one known
  ShopSystem id and one known CraftingSystem id), CHARM_INFO and `LoreJournal.has_entry`; Then the quest count is
  15, every reward key is in the allowed set (catches typos like "itme"), and every item / charm / lore id
  resolves; no `ability` / `unlock` key exists.
- **A1-2 mapped rewards** — Then the nine mapped rewards equal the table including `item_quantity` (×2 for
  `data_ore` and `glitch_stabilizer`); Lyra's Past has no `ability` key and keeps its XP and Lyra +15.
- **A1-3 discounts in data** — Then Forge Line Supply's `shop_discount` is 0.05 and Merchant's Guild's is 0.15.
- **AC-2 (one per kind)** — Given `grant_rewards("q_test", {gold: G, item: "nope"})`; Then gold +G, no item, the
  returned list has one entry naming `q_test` and `nope`. Repeat for unknown `charm` (not stored in
  `unlocked_charms`), unknown `lore` (no empty page registered), `ability: "x"` (no `ability_x` flag) and
  `unlock: "x"` (no `unlocked_x` flag). Mixed `{item: "nope", charm: "extended_parry"}`: the charm is unlocked
  once and one entry is returned. For a real quest completed through `complete_quest`: state COMPLETED,
  `side_quest_<id>_complete` set, `quest_completed` emitted once.
- **AC-3a vectors** — `get_buy_price` at 0.05 gives 0→0, 1→1, 10→10, 30→29, 45→43, 80→76, 120→114; at 0.0 every
  base unchanged; at 1.0 every priced item is 1; an out-of-range discount is clamped.
- **AC-3b affordability** — With gold equal to the discounted price but below the raw price, the buy button is
  enabled and the purchase succeeds; with one less, it is disabled and the message shows the discounted amount.
- **AC-3c/3d consistency** — Sell prices identical at 0 and 0.05; for every item in `SHOP_ITEMS` at 0, 0.05 and
  1.0, the displayed price equals the gold actually deducted (a loop catches a missed call site).
- **AC-4 arena** (tier gates bronze 1, silver 3, gold 5, platinum 7; level via `player_stats.level`):
  4a HIDDEN/DISCOVERED → a district visit starts it ACTIVE at step 0; 4b a visit with `ch2_arena_entered`
  already set also starts it; 4c a visit at level 1–2 still starts it; 4d a second visit does not restart or
  reset it; 4e Bronze win → step 1, repeat Bronze → 1, Gold win → 3, later Silver → 3, repeat Gold → 3;
  4f Platinum first → COMPLETED after exactly 4 advances; 4g `extended_parry` unlocked once, a repeat Platinum
  win grants nothing, `quest_completed` once; 4h a level-5 player's repeated Gold wins stay at 3, then a
  Platinum win at level 7 completes it; 4i started with Silver and Gold flags already set → step 3 after the
  start-time sync; with Platinum set → COMPLETED at the visit (decision 6); 4j the sync is idempotent;
  4k the real `_arena_win` with `current_tier = "gold"` and the quest at step 0 ends at step 3 (flags set before
  the sync), if the arena manager can run headless; 4l a win while the quest is not ACTIVE changes nothing;
  4m a Time Attack win that sets a tier flag counts (decision 6).
- **AC-5 data hoard** — 5a first entry → ACTIVE, step 1; 5b junction → step 2, Wraith → COMPLETED,
  `ironhold_lore_3` discovered, one `quest_completed`; 5c entering three times → still step 1, solving the
  junction twice with the scene-local `_puzzle_solved` reset (as on reload) → step 2; 5d after COMPLETED,
  re-entry and re-solving restart and grant nothing; 5e the Wraith with the quest at step 1 completes it
  (decision 7).
- **A6-1 dead quests stay dead** — Pin the four dead quests' step counts to their pre-change values; all four
  HIDDEN at start and still HIDDEN after driving the Iris, Garro, arena-visit and Underground hooks.
- **A6-2 static guard** — Scanning `scripts/` for `start_quest` / `discover_quest` with the four ids, excluding
  the orphaned `exploration/oakhaven.gd` and `chapter2/ch2_ironhold_city.gd`, finds 0 hits (a scan of 0 files
  fails).
- **AC-7 working quests** — Iris and Garro each complete once; talking again changes no gold or inventory; after
  Garro a shop price equals `get_buy_price` at 0.05 (e.g. 30→29); a lower later discount never reduces it.
- **AC-8 saves** — 8a fixture: `start_quest`, set `quests[id]["current_step"]`, `get_save_data()`, round-trip
  through `JSON.stringify` / `JSON.parse_string`, `reset()`, `load_save_data()` (no hand-written dictionaries);
  8b the step map in AC-8 for the Data Hoard and Arena Legend; 8c gold, XP, inventory, charms, flags and lore are
  identical before and after the load, no error, no `quest_completed`; 8d Arena Legend loaded at step 3 with
  Platinum cleared completes once on the next sync; 8e a negative or oversized ACTIVE step is clamped; 8f a
  completed quest saved and loaded: a second `complete_quest`, `advance_quest` or sync is a no-op.
- **AC-9** — 9a the layout guard passes with both new suites (each with its `.uid`, generated by an editor
  import); 9b both listed in `run_all_tests.ps1` (`Long` set deliberately) and as `bash tests/run_tests.sh
  res://…` steps in `ci.yml`; 9c full suite and `git diff --check` clean, log retained in
  `production/qa/evidence/2026-10-side-quests/`.

---

## Test Evidence

**Story Type**: Integration
**Required evidence**: `tests/unit/quests/side_quest_rewards_test.gd` and
`tests/integration/quests/act1_quests_completable_test.gd` passing, with a log in
`production/qa/evidence/2026-10-side-quests/`.

**Status**: [x] Created — tests/unit/quests/side_quest_rewards_test.gd (134/0), tests/integration/quests/act1_quests_completable_test.gd (114/0), production/qa/evidence/2026-10-side-quests/

---

## Dependencies

- Depends on: Y1-P0-T02 (done), Y1-P0-T03 (done; decision 5A). No story files for these by sprint decision;
  status in `production/sprint-status.yaml`.
- Unlocks: Y1-P0-T14a (playthrough bot Ch4–10 legs need completable quests), Y1-P0-S07.

---

## Completion Notes
**Completed**: 2026-10-20
**Criteria**: 9/9 passing (notes on AC-2, AC-4, AC-8 below). Nothing deferred.
**Deviations**:
- NOT ASSESSED: GDD / ADR / TR-registry traceability (none exist); judged against decision 5A and user decisions 1–8, no deviation found.
- ADVISORY: AC-2 "exactly one push_error naming the quest id" and AC-8 "loading raises no error" are verified by reading `production/qa/evidence/2026-10-side-quests/run_all.log` (exactly six `[SideQuest] q_test: …` lines, one per unknown-kind case; no other `[SideQuest]` error in the 12-suite run), not by a test (the 4.5+ Logger API is not covered by `docs/engine-reference`). QA case 4h is verified at quest-logic level, without level mechanics (protected combat code). QA case 4c wording: Bronze opens at level 1, so the "no tier" path is level 0 (tested).
- Added after code review (user, 2026-10-20): `sync_data_hoard()` on Underground entry and Ironhold region load (`scripts/regions/ironhold_region.gd`, one guarded call) repairs old saves; loading itself still grants nothing.
- Accepted LP-CODE-REVIEW concerns (user, 2026-10-20): `grant_rewards` cyclomatic complexity ~15–20 and 46 lines (split into per-kind helpers); the two catch-ups run from scene code, not after load (a post-load reconcile hook is the alternative).
- Data Hoard lore reward `ironhold_lore_3` is also a world pickup (`ironhold_region.gd:45`); a player who found it first gets the XP and gold but no new page. Kept; flagged for game-designer to pick a unique Underground entry (user, 2026-10-20).
- Observations outside T06: shop Null Potion text still "Blinds for 5s" (T08, decision 9); top-bar gold vs shop gold differ (Inventory.gold vs player_stats gold); "Lambda capture freed" engine errors from `data_sprite.gd` on Underground re-entry (pre-existing).
**Test Evidence**: Integration — `AethelgardPrototype/tests/unit/quests/side_quest_rewards_test.gd` (134/0) and `AethelgardPrototype/tests/integration/quests/act1_quests_completable_test.gd` (114/0, real scenes headless), registered in `tests/run_all_tests.ps1` and `.github/workflows/ci.yml`; full suite 12/12, 1118 s (`production/qa/evidence/2026-10-side-quests/run_all.log`); live-renderer shop shot `production/qa/evidence/2026-10-side-quests/t06_shop_discount.png` (Red Potion BUY 29G at 5%). Watched fail: price vector, mapped quantity, clamp map, dead-quest step count, guild id, step-0 repair and Wraith flag (production mutations), plus the real regression it caught (dropped `side_quest_<id>_complete`, restored).
**Code Review**: Complete — /code-review APPROVED WITH SUGGESTIONS (Data Hoard old-save catch-up applied); LP-CODE-REVIEW CONCERNS (accepted); QL-TEST-COVERAGE GAPS (advisory).
**Follow-up (recommend a follow-up story)**: split `grant_rewards`; post-load reconcile hook for the catch-ups; capture push_error via a Logger once the engine reference covers it; non-literal dead-quest scan and pinning unchanged rewards; live captures of the arena quest start and Underground flow; unique lore reward for the Data Hoard (game-designer); content pass for the four dead quests; NG+ re-granting quest rewards (T07); orphaned `scenes/exploration/oakhaven.tscn` and `scenes/chapter2/ironhold_city.tscn`; Mara apothecary vs baker (lore).
