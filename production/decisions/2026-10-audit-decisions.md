# Audit decisions 3–9 — decision record

- **Task:** Y1-P0-T03 · Prepare the decision memo for the open audit decisions
- **Source:** `AethelgardPrototype/CHANGELOG.md:164` "Decisions left for the user". Items 1–2 (hit feel,
  collision) were decided on 2026-10-06 (`78bc24b`). This memo covers the remaining seven, numbered 3–9.
  The plan's title "decisions 3–5" undercounts them.
- **Evidence date:** 2026-10-18, branch `fix/phase0-playthrough-blockers` @ `817801f`.
- **AGENTS.md:** options marked ⚠ change a protected area (story progression, save schema, combat, NG+)
  and need your explicit approval in the task that implements them, not just here.

| # | Item | Implementing task (est.) |
|---|---|---|
| 3 | Chapter 1 shatter scene text | S02 + T04 (2 d) |
| 4 | Chapter 1 breadcrumb objectives | T05 (1 d) |
| 5 | Side-quest rewards and quests that can't finish | T06 (3 d) |
| 6 | NG+ stacking choice buffs | T07 (1 d) |
| 7 | Screen flashes that never show | T08 (2 d, shared with 8–9) |
| 8 | `fragment_4` achievement | T08 |
| 9 | `null_potion` text vs effect | T08 + S02 |

---

## 3. Chapter 1 shatter scene text

**Now:** `scripts/chapter1/ch1_shatter_transition.gd` `play_post_shatter_dialogue()` (lines ~331–425) is about
25 inline `DialogueManager.say` lines in the pre-rewrite voice: "Four hundred and twelve iterations"
(:381, :386, :393), Aldric "at that bridge" (:383), "5% extra" corruption (:390), stage directions
(`*gasping*`), and narrated mechanics ("gravity, actual GRAVITY", "Oakhaven was the tutorial",
"difficulty curve", AetherCorp). Purge sets `ch1_knight_spared` too (`aldric.dlg:115-116`) and the code
tests `knight_spared` first (:380), so purge plays the spare text.
**Done already:** `dialogue/ch1/shatter.dlg` (35b67e0) replaces the Aldric reflection, with purge checked first.

| Option | Cost | Touches |
|---|---|---|
| **A.** Wire only the Aldric reflection to `shatter.dlg` (T04 as planned); the other ~20 lines wait for a later voice pass | T04 2 d | dialogue only |
| **B.** Rewrite the whole post-shatter scene into `shatter.dlg` in the Chapter 1 voice, then wire it all | +~2 d writing (S02, from the buffer) + T04 2 d | dialogue only; no flags change |
| **C.** Cut the scene to the Aldric reflection plus 2–3 lines arriving in Ironhold | +0.5 d | dialogue only; loses the Ironhold arrival beat |

**Recommendation: B.** This is the last scene of Chapter 1, and every one of its lines breaks the voice
guide. Doing it once is cheaper than wiring A now and reopening the same function later.

## 4. Chapter 1 breadcrumb objectives

**Now:** two objective systems. `scripts/ui/progression_breadcrumb.gd` OBJECTIVES has 6 stale Chapter 1
entries keyed on flags (e.g. "Defeat the Corrupted Sentinel"; "a village that should not know your name",
which the 2026-10-05 retcon removed), with arrow targets. The `.dlg` files also set the HUD objective with
`do objective …` (crash_site:13, :36; elara_meeting:90; broken_mile:151). The 10 replacement lines are
approved (session log, 2026-10-18).

| Option | Cost | Touches |
|---|---|---|
| **A.** The breadcrumb table is the source: Chapter 1 gets the 10 approved lines keyed on flags; the `.dlg` `do objective` lines are kept only where they say the same text | T05 1–1.5 d | UI; reads story flags, writes none |
| **B.** Dialogue is the source: the table drops its Chapter 1 entries and only shows what `do objective` last set | 1 d + save work: the last objective must be saved so a load shows it | UI + save data ⚠ |
| **C.** Keep both as they are, only replace the strings | 0.5 d | UI; the two can still disagree |

**Recommendation: A.** Objectives derived from flags are right after a load (an edge case the plan
names) with no save change, and the arrows already live in the table.

## 5. Side-quest rewards and quests that can't finish

**Now:** `scripts/side_quest_manager.gd` lines 29–154, 15 quests.
- **Only 5 can finish** (herb delivery, blacksmith, mirror city, memory ocean, saved assembly), via
  `complete_optional_objective`.
- **10 can't:**
  - Oakhaven lost memories, corrupted cellar, herbalist favor: started, never advanced.
  - `ironhold_arena_legend`: advanced once per tier (`arena_manager.gd:600`); step 5, "Phantom
    Champion", has no fight.
  - `ironhold_underground_data`: 6 steps, one advance site (`ch2_underground_network.gd:373`).
  - Merchant guild and wastes ×3: discovered, never started.
  - `secret_debug_room`: discovered after 3 dev signatures, never started; only `dev_signature_1`
    exists in code.
- **7 reward ids don't exist** anywhere else: `memory_crystal`, `forge_heart`, `stabilizer_mk2` (items),
  `arena_veteran`, `developer_insight` (charms), plus the `null_heal_potion` unlock and the `echo_sense`
  ability. Unknown items log a warning and grant nothing (`inventory_system.gd:268`). The `unlocked_*`,
  `ability_*` and `lore_*` flags these rewards set are read by nothing.

| Option | Cost | Touches |
|---|---|---|
| **A.** Act 1 only (the 8 quests of chapters 1–2): every quest's steps match content that exists. The arena quest drops the Phantom Champion step until that fight exists, and the data hoard becomes the steps the underground actually has. Missing rewards point to an existing item or get a minimal definition. `grant_rewards` errors on unknown ids. Later-chapter quests stay as they are, recorded for those chapters' rebuild. | T06 3 d | quest data, item data (balance) |
| **B.** As A, and also delete the quests that have no content at all (merchant guild, wastes ×3, debug room) | 3 d | as A; removes quests from saves' quest lists ⚠ save data |
| **C.** All 15 quests completable now | ≥ 6 d (new content: caches, Phantom Champion, wastes) | quest + level content, combat ⚠ |

**Recommendation: A.** It fixes what Act 1 players meet, stays inside the 3-day estimate, and doesn't
touch saves. Each new item definition is listed for your OK in T06 (item data).

## 6. NG+ stacking choice buffs every cycle

**Now:** choice buffs add straight into `base_attack`, `base_defense`, `max_hp` and `max_mp`
(`choice_consequences.gd:210-228`). `start_new_game_plus()` carries those already-buffed values
(`game_manager.gd:533-537`), and the next run adds the same buffs again when the same flags are set. The
buff table holds +50 attack, +35 defense and +20 max HP in total. A run takes a subset (choices exclude
each other), so the per-cycle gain is measured in T07's test, not guessed here.

| Option | Cost | Touches |
|---|---|---|
| **A.** At NG+ start, subtract the finishing run's active buff mods from the carried stats | T07 0.5–1 d | NG+ ⚠ (no save-format change) |
| **B.** Keep buffs out of the base stats altogether: store them separately and derive them from flags every run | 1.5–2 d | NG+ ⚠, save data ⚠ (player_stats meaning changes) |
| **C.** Treat stacking as an NG+ feature, with a cap per stat | 0.5 d | NG+ ⚠, balance |

**Old saves that already stacked:** leave them as they are (there are no public NG+ saves yet) or clamp
on load. **Recommendation: A**, and leave old saves alone. It's the smallest fix that makes three cycles
equal (T07's acceptance), with no save-format change.

## 7. Screen flashes that never show

**Now:** five per-scene copies (`ch3_archive_depths.gd:657`, `ch3_fractured_wastes.gd:725`,
`ch3_ironhold_departure.gd:132`, `ch3_kaelthas_betrayal.gd:584`, `ch1_oakhaven_village.gd:148`) plus a shared
`cinematic_vfx.gd:163 screen_flash()`. The audit says they never render. **Root cause not traced yet**
(T08 day 1). Lead: `ch3_archive_depths.gd:96` sets `anchors_preset` as a property on a code-built
`ColorRect`, which can leave it zero-sized. Unverified.

| Option | Cost | Touches |
|---|---|---|
| **A.** Find the root cause, fix it once in the shared helper, route the per-scene copies to it; keep the flashes soft (alpha ≤ 0.5, ≥ 0.5 s) with a TODO for the Y1-P1 reduce-flash option | T08 1–1.5 d | VFX |
| **B.** Remove the flashes (fades only) | 0.5 d | VFX; loses emphasis on story beats |
| **C.** Patch each scene separately | 1 d | VFX; the five copies stay |

**Recommendation: A.**

## 8. `fragment_4` achievement

**Now:** "Key Collector: Collect all available Source Key Fragments." It unlocks at 2 fragments
(`scripts/ui/achievements.gd:29, 169`), and `source_key_complete` already covers all 7.

| Option | Cost | Touches |
|---|---|---|
| **A.** Unlock at 4 (as the id says), rename to "Halfway to Root" / "Collect four Source Key fragments." | 0.25 d | achievements; players who unlocked it at 2 keep it |
| **B.** Keep 2, make the text say so: "Collect two Source Key fragments." | 0.25 d | text only |
| **C.** Remove it | 0.25 d | achievements list |

**Recommendation: A.** Four is a real milestone (the story bible has SOVEREIGN's concern rising after
Fragment 3). Achievements persist on their own, so nobody loses one.

## 9. `null_potion` text vs effect

**Now:** three definitions, two behaviours, one price conflict, and no blind anywhere:

| Where | Text | Effect | Price |
|---|---|---|---|
| `ch1_oakhaven_village.gd:42` | "Restores 100% Integrity. Blinds for 5s." | (`null_heal`) | 500 |
| `inventory_system.gd:80`, effect at :375 | "Full heal. Blinds for 5s. Adds 3% corruption." | heals 100 HP, corruption **−10** | 500 |
| `shop_system.gd:56`, effect at :1158 | same as inventory | full heal, corruption **+3** | 800 |

| Option | Cost | Touches |
|---|---|---|
| **A.** One definition in `inventory_system.gd`; effect = full heal, +3 corruption (the shop's); text "Full heal. Adds 3% corruption."; one price (500); the other two reference it | 0.5 d + string (S02) | item data (balance) |
| **B.** Make the text true: full heal, 5 s blind (new status effect and screen effect), +3 corruption | 1.5–2 d | combat status ⚠, accessibility |
| **C.** Make it a cure: heal 100 HP, −10 corruption (the inventory's); text to match | 0.5 d + string | item data (balance) |

**Recommendation: A.** It keeps the trade-off the name suggests (a big heal with a corruption cost) and
removes an effect nobody built. The herbalist quest's `null_heal_potion` unlock points to it (item 5).

---

## Also found (not one of the seven; for the record)

- **Bridge flag names differ:** `STORY_BIBLE.md` §5 says `ch1_bridge_saved` / `_evacuated` / `_fell`;
  `north_field.dlg` sets `ch1_bridge_repair_accepted` / `_evacuated` / `_ignored`. Recommendation: update
  the bible to match the code (no code change).
- **`administrator_enforcer.gd:58`** teleports without a collision check and can land in a wall. For the
  bug list (S05); combat is a protected area.

## Decisions

All seven decided by the user on **2026-10-18**, in each case the recommended option. ⚠ items still need
explicit approval inside the implementing task before protected code changes (AGENTS.md).

| # | Item | Decision (2026-10-18) | Implemented in | Effect on the plan |
|---|---|---|---|---|
| 3 | Shatter scene text | **B.** Rewrite the whole post-shatter scene into `dialogue/ch1/shatter.dlg`, then wire it | S02 (rewrite) → T04 (wire) | S02 +~2 d, from the buffer (free days 11 → 9) |
| 4 | Breadcrumbs | **A.** The flag-driven table in `progression_breadcrumb.gd` is the source; Chapter 1 gets the 10 approved lines; `.dlg` `do objective` lines stay only where they say the same text | T05 | none (1–1.5 d) |
| 5 | Side quests | **A.** Act 1's 8 quests match existing content (arena legend drops the Phantom Champion step for now; the data hoard becomes the underground's real steps); missing rewards point to existing items or get minimal definitions, each approved in T06; unknown reward ids raise an error; later-chapter quests recorded for their chapters' rebuild | T06 | none (3 d) |
| 6 | NG+ stacking | **A.** ⚠ At NG+ start, subtract the finishing run's active buff mods from the carried stats; no save-format change; already-stacked saves are left as they are | T07 | none (1 d) |
| 7 | Screen flashes | **A.** Trace the root cause, fix it once in `cinematic_vfx.gd screen_flash()`, route the five per-scene copies to it; soft flashes (alpha ≤ 0.5, ≥ 0.5 s) and a TODO for the Y1-P1 reduce-flash option | T08 | none |
| 8 | `fragment_4` | **A.** Unlocks at 4 fragments; name "Halfway to Root", text "Collect four Source Key fragments."; earlier unlocks are kept | T08 | none |
| 9 | `null_potion` | **A.** One definition in `inventory_system.gd`: full heal, +3 corruption, price 500; text "Full heal. Adds 3% corruption."; the village and shop entries reference it; the herbalist quest's `null_heal_potion` unlock points to it | T08 (+ the string, S02) | none |

Not decided here: the bridge flag names (recommendation above: update the bible to the code) and the
enforcer teleport (bug list, S05).

## Approved strings (S02, handed to T05 and T08)

**Chapter 1 objectives** (user approved 2026-10-18; the "ends when" column is T05's starting point):

| # | Step | Objective | Ends when |
|---|---|---|---|
| 1 | Crash site | Find people. A settlement east may know what happened to Flight 707. | `elara_met` |
| 2 | Elara | Reach Oakhaven. Follow the first lead on the missing passengers. | entering the Broken Mile |
| 3 | Broken Mile | Get through the Broken Mile with Elara. | `ch1_personal_goal_set` |
| 4 | Oakhaven gate | Ask about Flight 707. Find a safe route to Ironhold. | `ch1_oakhaven_entered` |
| 5 | Stew | Go to Elara's house. She's making stew. | end of the stew scene |
| 6 | Afternoon | Spend the afternoon in Oakhaven. Meet the people here. | `ch1_north_field_helped` / `_refused` |
| 7 | North field | Answer the alarm in the north field. | `ch1_boar_*` |
| 8 | Bridge | Deal with the north bridge before dark. | `ch1_bridge_*` |
| 9 | Aldric | Stop Aldric. | `ch1_tutorial_knight_defeated` |
| 10 | Village meeting | Go down to the shrine. Then decide what to tell the village. | `ch1_elara_joined` |

**`null_potion`** (follows decision 9): "Full heal. Adds 3% corruption."

**Quest reward names:** written in T06 once each missing reward's mapping is approved (decision 5).

**Shatter scene:** `dialogue/ch1/shatter.dlg`. The Aldric reflection was approved 2026-10-18 (35b67e0); the
rest of the scene is written under decision 3.
