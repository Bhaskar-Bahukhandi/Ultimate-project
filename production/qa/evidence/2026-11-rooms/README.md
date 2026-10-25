# Evidence: Y1-P0-S08 — Elara's house and the shrine as real rooms

Story: `production/epics/y1-p0-stabilize/story-s08-elara-house-shrine-rooms.md`

Both rooms are **placeholder shapes** (`ColorRect` walls, table, altar and dressing), not production art.
ComfyUI used: **No** (no art was generated for this story; AGENTS.md art truth gate).

## Acceptance criteria → evidence

| AC | What | Evidence |
|---|---|---|
| AC-1 | House scene: walls/table solid, 5 inspect spots, camera limits, no new strings | `ch1_rooms_test.log` (C1, C1 literal scan) |
| AC-2 | Stew in the room: one `ch1_stew_done` emit on each path, none on abort | `ch1_rooms_test.log` (C1 stew paths); `chapter1_route_test.log` (`_stew_run`) |
| AC-3 | Invite → door → house; step 5 names the village door | `ch1_rooms_test.log` (C2/C3); `chapter1_route_test.log` (arrow table, S5 check) |
| AC-4 | Back in the village at the door, afternoon starts | `ch1_rooms_test.log` (C2/C3) |
| AC-5 | Shrine scene, dressing table (5 rows) | `ch1_rooms_test.log` (C4) |
| AC-6 | Arena hands off to the shrine; 7-term scan | `ch1_rooms_test.log` (C5 scan, C6 routes) |
| AC-7 | Old post-decision saves forward to the shrine | `ch1_rooms_test.log` (C5 fixtures, through `load_game`) |
| AC-8 | Fresh-arrival autosave + card; altar single-fire | `ch1_rooms_test.log` (C6) |
| AC-9 | Chain in CUTSCENE; 3 bridge rows; saves refused | `ch1_rooms_test.log` (C6) |
| AC-10 | Save/load (a)–(e), aborts leave EXPLORATION | `ch1_rooms_test.log` (C5, C7) |
| AC-11 | No drift: golden captured at HEAD `38219e3`, replayed | `golden_capture.log`; `../../../AethelgardPrototype/tests/integration/story/ch1_s08_golden.json`; `ch1_rooms_test.log` (C6, C2/C3 golden fields) |
| AC-12 | Gamepad focus and joypad interact | `ch1_rooms_test.log` (C9, C6 focus) |
| AC-13 | Reachability for both rooms; village still passes; sealed control fails | `reachability_test.log`; `ch1_rooms_test.log` (dressing has no collision) |
| AC-14 | Room suite registered (suite_limits, run_all_tests.ps1, ci.yml); layout guard | `run_all.log` (LAYOUT 6/0, ROOMS) |
| AC-15 | Updated suites: route test, reachability; breadcrumb golden unchanged | `chapter1_route_test.log`, `reachability_test.log` |
| AC-16 | Full run, dialogue, reachability, `git diff --check` | `run_all.log` + the post-review re-runs below |
| AC-17 | Tour stops `s08_elara_house`, `s08_shrine`; `ch1_breadcrumb_oakhaven` reaches step 6 through the house | `report.md`, `capture.md`, `ch1_breadcrumb_oakhaven.png` |
| AC-18 | Live-renderer screenshots | `elara_house.png`, `shrine.png` (+ `s08_shrine_altar.png`, see below) |
| AC-19 | This README | — |

## Screenshots (live renderer, not headless)

All from one tour run in a real 1280x720 window (Godot 4.6.3, forward_plus, NVIDIA RTX 2050); none is from
`--headless` or the dummy renderer. Viewed by the orchestrator, not only by the agent that captured them.
Re-captured at 19:46 after the `/code-review` fixes (`capture.md`); the first capture's village shot predated the
door fix.

- `elara_house.png` — the whole room after the stew (`ch1_stew_done` preset): walls, table, Elara, all five
  inspect shapes, the door gap, the player with an "[F] Interact" prompt. No dialogue box.
- `shrine.png` — the arrival frame on the kill route: the gate end (Killed dressing, stair door). The arrival card has
  faded (black and text alpha 0.00). The camera shows 512x288 of the 512x640 room, so **no single frame holds both
  ends**: `s08_shrine_altar.png` (same arrival, player moved up the runner, nothing interacted with) shows the altar
  end (words panel, altar stone). The two together cover AC-18's shrine shot. A zoomed-out single frame was rejected
  because it would not be what the player sees.
- `ch1_breadcrumb_oakhaven.png` — the village after the house round trip, step-6 objective shown, the player at
  the shut door with no prompt.
- Cosmetic, not caused by this story: the objective panel overlaps the house's Herbs shape and the village's
  location/glitch text; the player's prompt and name cover part of the altar stone in the altar shot.
- `run_screenshots.ps1 -Evidence` was not used: it names the folder `<current yyyy-MM>-<topic>`, which would have
  written `2026-10-2026-11-rooms`. The files were copied by hand (`capture.md`).

## Runs

| Run | Result | Log |
|---|---|---|
| Golden capture at HEAD `38219e3`, twice | 52/0 then 66/0, `GOLDEN SAME: true` | `golden_capture.log` |
| Shrine probe (step C, throwaway) | 195/0, golden diffs 0 | `step_c_shrine_probe.log` |
| Rooms suite before the VFX fix | 386/0, 5× "Lambda capture … was freed" | `ch1_rooms_test_before_vfx_fix.log` |
| Rooms suite after the VFX fix | 386/0, 0× lambda error | `ch1_rooms_test.log` |
| Route test (step D2) | 395/0, 518 s | `chapter1_route_test.log` |
| Reachability (step D2) | 25/0 | `reachability_test.log` |
| Full suite (24 suites), 1690 s | 22 green; **2 failed** (route test 394/1, phase0 80/1), 0× lambda error | `run_all.log` |
| Re-entry regression, watched failing on the unfixed code | 389/3 (the three C3b checks) | `ch1_rooms_test_reentry_watchfail.log` |
| Rooms suite after the review fixes | **392/0**, 173 s, 0× lambda error | `ch1_rooms_test_after_review.log` |
| Route test after the review fixes | first 394/1 (my own tour comment contained the literal flag call the scan counts; reworded), then **395/0**, 515 s | `chapter1_route_test_after_review.log` |
| Phase 0 blockers after the review fixes | **81/0**, 311 s | `phase0_blockers_test_after_review.log` |
| Other suites that load the village/arena, after the fixes | combat_fixes 45/0, reachability 25/0, screen_flash 107/0, null_potion 83/0 | `*_test_after_review.log` |
| Quick suites after the fixes | layout 6/0, load_all ok=209 bad=0, dialogue 54/0 | (console) |
| Door-position check (C3c) watched failing: house spot moved to (700, 1200) | 388/4 (C3c ×2 plus the two placement checks); file restored byte-identical | `ch1_rooms_test_door_watchfail.log` |
| Parse check, 13 added/changed scripts (`.claude/scripts/godot-parse-check.gd`) | all `ok`, exit 0 | (console) |

| Rooms suite after the `/code-review` fixes | **411/0**, 182 s, 0× lambda error | `ch1_rooms_test_after_code_review.log` |
| Mutation 1: altar guard (`_busy()`) removed from `_on_altar_interaction` | 406/5: "the double altar call ran fragment once (most runs active at once: 2)" ×5 routes; nothing else failed | `mutation_1_altar_guard_removed.log` |
| Mutation 2: stair-door guard removed from `_on_stair_door_interaction` | 400/11: run count ×5, joins first line twice ×5, purge golden flags | `mutation_2_stair_door_guard_removed.log` |
| Mutation 3: `ch1_stew_done` set before the stew run returns | 406/5: freed mid-run emits, stew golden ×3, (b) replay | `mutation_3_stew_flag_early.log` |
| Mutation 4: dressing precedence swapped (killed before purge) | 410/1: the killed+purge row | `mutation_4_dressing_order_swapped.log` |
| Mutation 5: shrine autosaves on every arrival (outside the fresh gate) | 409/2: (c) load makes no autosave; mid_meeting autosave | `mutation_5_autosave_on_every_arrival.log` |
| Screenshots re-captured after the fixes (live renderer) | 4 shots, 0 problems; village shot now has no prompt at the shut door | `capture.md`, `report.md` |
| Full suite after the `/code-review` fixes (AC-16) | **24/24 suites green**, 1431 s, 0× lambda error (ROOMS 411/0, CH1 395/0, PHASE0 81/0, REACH 25/0, LOADALL ok=209 bad=0, LAYOUT 6/0, PLAYTHROUGH 172/0) | `run_all_after_code_review.log` |

| Rooms suite after the second `/code-review` (mid-meeting check now scripts "It's handled" twice and asserts trust −10 exactly; header comment updated) | **411/0**, 0× lambda error | `ch1_rooms_test_round2.log` |
| Mutation 6: village door left open after the stew (`ch1_stew_done` dropped from `_elara_door_open`) | 407/4: "back at the shut door, the player targets nothing (ElaraHouseDoor…)" plus the three C3b checks | `mutation_6_door_open_after_stew.log` |
| Mutation 7: `ELARA_AT_DOOR_POS` moved into the house block (700, 1100) | 409/2: the spot guard and "Elara stands at the house door" | `mutation_7_elara_spot_in_house_block.log` |
| Mutation 8: the shrine plays `meeting` twice | 403/8, including "mid_meeting: the meeting's trust change applied exactly once (elara -20, expected -10)" | `mutation_8_meeting_played_twice.log` |
| Mutation 9: `data_vision_active` defaults to true | 405/6: "Data Vision off at capture" on all six golden segments | `mutation_9_data_vision_forced_on.log` |

| Rooms suite after the third `/code-review` (guard count exact at 11; mid-meeting asserts one choice asked) | **412/0**, 0× lambda error | `ch1_rooms_test_round3.log` |
| Mutation 10: one `is_inside_tree()` guard removed from the shrine chain (after `joins`) | 411/1: "(e) the moved code keeps its 11 is_inside_tree() guards (10)" — and nothing else | `mutation_10_shrine_guard_removed.log` |
| Mutation 11: the shrine plays `meeting` twice (for the new pick-count check) | 402/10, including "mid_meeting: the chain asked exactly one choice (0 scripted pick(s) left)" | `mutation_11_meeting_twice_pick_count.log` |

Each mutation ran in its own tool call, from a backup, and the file was restored byte-identical (`cmp`) before the
next (the `cmp` output is in the session transcript, not in a kept file). Mutations 1–7 ran before one or more of the
later edits to `ch1_rooms_test.gd` (round 2: the mid-meeting block; round 3: the guard count and one pick-count
check). Those edits touched only those checks; every other check is identical (the suite is untracked, so there is
no git diff to show it — compare the PASS/FAIL lines of `ch1_rooms_test_after_code_review.log`,
`ch1_rooms_test_round2.log` and `ch1_rooms_test_round3.log`). Durations in this table (518 s, 1431 s,
…) are console wall-clock readings, not lines in the logs.

**What covers the `is_inside_tree()` guards (AC-10e).** The abort sections free the shrine mid-`fragment` and
mid-chain, check the state is EXPLORATION *before* calling `DialogueManager.force_reset()`, then check no ending was
requested and nothing was awarded twice. `force_reset()` (which also cancels the dialogue run) is deliberate: it
leaves no dialogue running into the next section. Mutation 10 shows those behaviour checks do **not** notice a
removed guard (a freed scene's paused coroutine does not visibly continue); only the exact text count does. So the
guards are covered by that count, and their effect by the state/award/transition checks. Mutation 8's first attempt scripted one "It's handled" pick: the replayed meeting then took the default
(public, no trust change), so the flag check caught it but the trust check did not. The test now scripts the pick
twice, and the kept log is the re-run where the trust check itself fails. The no-target-during-the-chain check
(C9) was also seen failing once (410/1) when the shrine freeze first went in without its target refresh; that log
was overwritten by the green re-run, so it is not kept. Mutations 1, 3 and 4 replace the step-D1 claims of the same name, which had no retained logs (code review
finding); 2 and 5 are new, for the checks the review found weak.

**Current logs:** for the rooms suite, `ch1_rooms_test_round3.log` is current (412/0, after the third review's
test-only change). For everything else the `*_after_code_review.log` files (and `run_all_after_code_review.log`,
24/24) are current; they supersede the `*_after_review.log` ones, which supersede `ch1_rooms_test.log` and
`chapter1_route_test.log` above. No game code changed after `run_all_after_code_review.log`. Not re-run after the fixes: the other 13 suites
of the full run, which do not load the village, house, shrine or arena (they were green in `run_all.log`).
The tour runner changed after the screenshots only in how one stop presets `ch1_stew_done` (a list instead of a
literal call; same flag, same scene); the screenshots were not re-captured.

The two full-run failures, and what fixed them:
1. `chapter1_route_test` — the T05 scan "exactly one `set_story_flag("ch1_stew_done")` in scripts/" found a second
   literal call: step E's tour stop preset in `scripts/debug/screenshot_tour_runner.gd`. The stop now presets from a
   list (`S08_HOUSE_FLAGS`) like the tour's other stops. Note: the scan only ever matched literal calls; it already
   ignored the tour's other list presets. It guards game writers, not debug presets.
2. `phase0_blockers_test` — "village continues to the Oakhaven region" waited for an afternoon that now starts only
   after the stew in the house; its village helper never used the house door. It now drives door → house → door,
   as the route test does. This suite was not in the story's audit item 7.

## Changes outside the story's declared files

- `scripts/effects/vfx_library.gd` (two lines, user-approved): one-shot particle and shatter cleanup timers now
  connect to the node's `queue_free` instead of a lambda capturing it. S08 frees the arena seconds after the loot, and
  a level-up sparkle parented to it outlived it; the lambda then logged "Lambda capture at index 0 was freed". Before
  the fix: 5 occurrences in the rooms suite, 4 in the route test; after: 0 (rooms suite, full run).
  Engine-reference coverage: NOT SOURCEABLE that freeing a Callable's target drops its connection
  (`docs/engine-reference/godot/` does not cover it); the evidence is the observed error count.
- `tests/integration/playthrough/phase0_blockers_test.gd` (village helper, see above).
- `.github/workflows/ci.yml`, `tests/run_all_tests.ps1`, `tests/suite_limits.txt` (AC-14 registration; minimums
  load_all 205→209, chapter1_route 391→395, reachability 21→25, ch1_rooms new at 392 / 600 s). The T14a session
  edited the same three files in parallel and committed its lines first (`b195732`); S08's lines are separate.

## Review (godot-gdscript-specialist): CHANGES REQUIRED → fixed

- BLOCKING: the village door stayed open all afternoon; going in and out rebuilt the village and restarted the
  afternoon (alarm, field +100 gold / +50 XP, bridge) every time. Fixed: the door opens only between the invite and
  the stew. Regression test C3b in `ch1_rooms_test` (watched failing first, see Runs).
- SHOULD FIX: the shrine's ending call could be dropped mid-transition after its guard was set (player frozen in
  CUTSCENE). Fixed: it waits out a running transition first.
- NIT: the house's return spot duplicates the village door position → test C3c ties them together.
- NIT: dead `elara_serves_stew` / `elara_sees_him_look` cases removed from the village (`elara_stands` kept: the
  review called it dead, but `north_field.dlg:12` still plays it); `return_point` typed; shrine `_exit_tree` uses the
  village's `has_node` + typed autoload pattern.

## `/code-review` (2026-10-25): CHANGES REQUIRED → fixed

Reviewers: godot-gdscript-specialist and godot-specialist (both APPROVE WITH SUGGESTIONS), qa-tester (GAPS). Every
finding was checked against the code before it was acted on.

Required, all fixed:
1. The altar and stair-door single-fire checks could not fail: `DialogueManager.run` does not refuse a second run
   (`dialogue_manager.gd:494-510`, the suite's comment said it did), the driver drops a repeated line, and
   `collect_source_key` sets its flag once. Now the driver records the most runs active at once (`_max_runs`);
   watched failing (mutations 1, 2).
2. AC-10(c) "a load makes no autosave" deleted slot 99 after `load_game`, which flushes queued autosaves before it
   returns (`game_manager.gd:1746`). Now deleted before the load, checked after the new shrine settles; watched
   failing (mutation 5).
3. Three step-D1 mutation claims had no logs: re-run with logs kept (mutations 1, 3, 4).
4. `ch1_breadcrumb_oakhaven.png` (17:49) predated the door fix (watched failing 18:22) and showed the old prompt:
   re-captured, plus a check that nothing is targeted at the shut door.
5. AC-16 had no green full run: see `run_all_after_code_review.log`.

Suggestions, all taken:
- The fresh-arrival meta has one name, `GameManager.SHRINE_FRESH_ARRIVAL_META` (it was four literals); the suite
  scans the arena and the shrine for a literal of their own.
- Elara's waiting spot is guarded like the return spot (within 96 px of the door, outside the house block).
- The arena polls `is_transitioning` instead of awaiting `transition_completed`, which an aborted transition never
  emits (`scene_transition_manager.gd:77-79`).
- The shrine player is frozen (physics off, target refreshed once so no stale prompt) under the black arrival card
  and through the after-dark chain. A CUTSCENE state alone would not have done it: `player_topdown.gd:248` freezes
  only for an active dialogue.
- The mid-meeting HEAD save is now played on to the ending (key count 1, trust unchanged).
- The Data Vision check fails if there is no player or the field is renamed.
- Village `_ready`: the return-point block extracted to `_arrive_from_return_point()` (58 → 54 lines counted to the
  next `func`, blank lines included; it was 42 at HEAD, already over the 40-line standard, so it still is). New handlers typed `body: Node`; two always-true conditions dropped.

Not changed (follow the surrounding code): the rooms use the autoload singletons and named placeholder constants
rather than injected dependencies and data files, as every Chapter 1 scene does.

## `/code-review` round 2 (2026-10-25): CHANGES REQUIRED → fixed

godot-gdscript-specialist and godot-specialist: APPROVE WITH SUGGESTIONS (both confirm every round-1 fix); qa-tester:
TESTABLE. The one required change was evidence: four checks added in round 1 had never been watched failing. They
now have (mutations 6–9), and the mid-meeting trust check, which could not fail as written (the public choice
changes no trust), now scripts the one choice that does. Suggestions taken here: this protected-path statement, the
D5 note below, and the suite header. Not taken (left as suggestions): a public target-refresh method on the player
(the shrine calls `_refresh_interaction_target` behind `has_method`; C9 catches it breaking), a viewport/zoom guard
on room size, making the source-count guard check behavioural.

## `/code-review` round 3 (2026-10-25): APPROVED WITH SUGGESTIONS

godot-gdscript-specialist and godot-specialist: APPROVE (no blocking or should-fix findings); qa-tester: TESTABLE.
Closed blind spots: skip-all still delivers Fragment One's `fragment_acquired` (`dialogue_manager.gd:568-575` runs
`do` steps regardless); release presets exclude `scripts/debug/*` (`export_presets.cfg:10`, `:51`); the village
door is reachable from outside the house block; clearing `boss_fight_id` / `boss_return_scene` in the village
affects no boss path; nothing can attack or dash under the shrine freeze. Suggestions applied: exact guard count
(mutation 10), pick-count assert (mutation 11), the README notes above and below. All four new `.uid` files
(`ch1_elara_house.gd`, `ch1_shrine.gd`, `ch1_rooms_test.gd`, `ch1_s08_golden_capture.gd`) go in the commit. Not
taken: a physics test for a player loaded inside the house block; gating Data Vision under the freeze (would edit
`player_topdown.gd`). The "ObjectDB instances leaked at exit" lines in the full runs are not new (17 in the pre-S08
T12 run, `2026-10-ui/run_all.log`).

## Protected paths (AGENTS.md)

- **Changed, authorised by the story** (protected-areas block and decision D4): `scenes/chapter1/oakhaven_village.tscn`
  — additive only: `ElaraHouseBuilding`, `ElaraHouseRoof`, `ElaraHouseDoorway` (flat ColorRects in the village's
  existing block style) and the `Doors/ElaraHouseDoor` Area2D; collision for the one house block via
  `_add_building_collision`. This is the Chapter 1 village scene, not the accepted Oakhaven *region* baseline
  (`scenes/regions/oakhaven_region.tscn`), which is untouched.
- **Story progression** (allowed by the prompt): the stew and the post-Aldric chain moved; no story flag added,
  removed or renamed; no `.dlg` text changed (golden comparison, AC-11).
- **Source Key logic:** only the `collect_source_key(1)` call site moved (arena → shrine); the function is untouched.
- **Save/load:** no schema change. `GameManager.SHRINE_FRESH_ARRIVAL_META` is a transient meta (in
  `TRANSIENT_METAS`, cleared on every load), not a save field.
- **Collision:** only the two rooms' walls, the house table, the shrine altar stone, and the village house block.
- **Untouched:** combat, hitboxes, the boss fight, true ending, NG+, world map / free travel, accepted region
  baselines, production art. ComfyUI used: No.

**D5 note:** an old post-decision save forwarded from the arena to the shrine counts as a *fresh arrival* (the arena
sets the hand-off meta), so it gets the place card and an autosave when the fragment is not yet taken — as AC-7
requires. "A load makes no autosave" above means a load straight into the shrine (D6), not this forward.

## Known limitations (from the story's Out of Scope, and found during the work)

- A manual save made in the instant between `aldric.dlg` `after` setting `ch1_tutorial_knight_defeated` and the
  arena applying the consequences and loot would, when loaded, be forwarded to the shrine without the corruption,
  buff, blade, 500 gold and 200 XP. The window is a frame or so (the `open_shrine_gate` flash is not awaited).
- A save made before S08 with the player standing where Elara's house block now is (about x 560–780, y 1064–1160)
  loads the player inside its collision. New saves cannot be made there. How the player body recovers from the
  overlap is not covered by `docs/engine-reference/godot/`. A guard in the village's `_ready` cannot fix this:
  `load_game` applies the saved position only after the scene's `_ready` and two more frames
  (`game_manager.gd:1714-1735`); a real guard would belong in `GameManager`'s load restore (protected save/load code).
- Elara's house has no `_exit_tree` state reset (the shrine has one): leaving it mid-stew by a load or a quit leaves
  the state DIALOGUE until the next scene sets its own, which every destination scene does.

- The village's afternoon state is still scene-local: a **load** mid-afternoon restarts the afternoon (now without
  the stew). Normal play can no longer trigger it (the door is shut after the stew).
- Villagers stay silent before the stew (no new lines) — for S07's pacing playtest.
- The boss-defeat autosave (written before the Aldric decision) still reloads the fight; only loads with
  `ch1_tutorial_knight_defeated` set are forwarded to the shrine (D5).
- The shrine's `_exit_tree` state reset bumps `GameManager._state_change_count`, so a load started from inside the
  shrine skips `load_game`'s saved-state fallback (`game_manager.gd:1710`, `:1737`). Deliberate trade: every
  destination scene sets its own state in `_ready`; one that did not would be left in EXPLORATION.
- The house's inspect spots can only be looked at right after the stew, before leaving (the door then stays shut).
