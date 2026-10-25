# Story S08: Elara's house and the shrine are real rooms — the stew plays at her table, Fragment One at the shrine altar

> **Epic**: Y1-P0 Stabilize (Sprint 001)
> **Task ID**: Y1-P0-S08 (`production/plan/_source/Y1-P0.json#Y1-P0-S08`)
> **Status**: In Progress
> **Layer**: Feature
> **Type**: Integration
> **Estimate**: 5 days (plan: 4; +1 for the test churn found at /story-readiness, audit item 7)
> **Manifest Version**: N/A — `docs/architecture/control-manifest.md` does not exist
> **Last Updated**: 2026-10-25

## Context

**GDD**: none (Chapter 1 level work). **Source of record**: the plan entry above (ROADMAP §5 "Build Elara's house and
the shrine as rooms"; four day-plans; edge cases "Entering the house before the stew invite", "Leaving the shrine before
Fragment One finishes", "Gamepad focus after the room's dialogue") and the sprint plan's acceptance criteria for S08
("`production/qa/evidence/2026-11-rooms/{elara_house,shrine}.png`; route tests green"). **Requirement**: N/A — no TR-ID
registered.

**ADR Governing Implementation**: N/A — two new scenes on the existing `SceneTransitions.change_scene` and
`GameManager.set_return_point` / `arrive_in_exploration_scene` seams; no new system. TransitionService (Y1-P1) will
replace the transition calls later.
**ADR Decision Summary**: N/A
**ADR Version**: N/A

**Engine**: Godot 4.6 (4.6.3 at `C:/Godot`) | **Risk**: HIGH (`docs/engine-reference/godot/VERSION.md`, 4.6 row)
**Engine Notes**: no post-cutoff API is planned. Rooms are `Node2D` scenes with `StaticBody2D` walls, the top-down
player (`scripts/exploration/player_topdown.gd`, as in `oakhaven_village.tscn`) and its child `Camera2D` with
`limit_left/top/right/bottom` set to the room rect. Interactables use the existing `interact_handler` meta +
`interactable` group (`player_topdown.gd:185`, `:312`). Collision shapes are queryable one physics frame after the scene
enters the tree (`reachability_test.gd` already waits 6 physics frames). `SceneTransitions.change_scene(path, style,
duration)` (`scene_transition_manager.gd:91`) emits `transition_completed` (`:18`). `Input.parse_input_event` with an
`InputEventJoypadButton` mapped to `interact` works headless.

**Control Manifest Rules**: NOT ASSESSED — no control manifest.

**Performance**: two small static scenes; one scene change each way. No performance impact expected. Not measured.

**AGENTS.md protected areas** (user decisions, 2026-10-25):
- **Story progression — allowed for this task** (prompt): the stew moves from the village arrival into the house; the
  post-Aldric chain (Fragment One → after-dark card → bridge news → meeting → Elara joins → shatter) moves from the arena
  into the shrine; the arena forwards a post-decision load to the shrine (D5). **No story flag is added, removed or
  renamed; no `.dlg` text changes.**
- **Collision — allowed for this task, scoped** (decision D4): walls of the two new rooms, the house table, the shrine
  altar, and in `oakhaven_village` one Elara's-house block plus its door trigger. No other wall, prop, hitbox or player
  collision change. Dressing nodes have no collision.
- **Source Key logic — allowed for this task, scoped** (decision D4): the existing `GameManager.collect_source_key(1)`
  call moves from `ch1_tutorial_knight.gd:_on_dlg_event` (`fragment_acquired`) to the shrine's event handler.
  `collect_source_key` itself is not touched (it already counts a fragment once, `game_manager.gd:1246-1253`).
- **Save/load**: no schema change. The shrine calls the existing `GameManager.auto_save()` on a fresh arrival; both
  rooms resume from existing flags.
- Not touched: combat, hitboxes, the boss fight itself, true ending, NG+, world-map / free-travel, accepted region
  baselines, production art (both rooms are placeholder shapes, labelled as such in the evidence README).

### Audit (2026-10-25, verified by reading the code)

1. **Elara's house does not exist.** `_play_entrance` (`ch1_oakhaven_village.gd:160-174`) plays gate → ledger →
   `elara_house invite` → fade to black → `elara_house start` (the stew) → sets `ch1_stew_done` → fade in. The player
   never walks anywhere; breadcrumb step 5 ("Go to Elara's house. She's making stew.") is only visible under the fade.
   The village has no Elara's-house building (only `ApothecaryBuilding`, `AuctionHouseBuilding`).
2. **Five written lines are unreachable.** `elara_house.dlg` nodes `inspect_bandages`, `inspect_herbs`,
   `inspect_focuses`, `inspect_cloak`, `inspect_map` have no caller anywhere in `scripts/` or `tests/`.
3. **The village replays its arrival on every load.** `_ready` runs `_play_entrance` unconditionally; `_seen`,
   `_afternoon_beats`, `_alarm_done`, `_field_resolved`, `_bridge_done` are scene-local. Coming back from a house scene
   would replay gate, ledger and stew. The village does not call `arrive_in_exploration_scene`.
4. **The shrine does not exist.** After `aldric.dlg` `after` (`do open_shrine_gate`, a flash only,
   `ch1_tutorial_knight.gd:1356-1358`), `_play_aldric_decision` (`:1263-1298`) shows a black "Under the old gate" card
   over the arena and plays `fragment_one.dlg` `fragment` (→ `fragment_acquired 1` → `collect_source_key(1)`), then the
   bridge check, "Oakhaven, after dark", `meeting`, `joins`, then `shatter_transition.tscn` (`:1298`). A second path
   to `shatter_transition` sits in `_process` (`:127-133`, the `_transition_timer` countdown); nothing ever sets the
   timer to 0 or above, so it is dead code — but if armed it would skip the shrine.
5. **Saving in the post-Aldric chain loads into a boss fight.** The only autosave is on boss defeat
   (`ch1_tutorial_knight.gd:1109`); a manual save during the meeting (DIALOGUE state, allowed) records the arena scene,
   whose `_ready` starts the fight again.
6. **Saving is allowed in DIALOGUE.** `save_game` refuses manual slots only in COMBAT / CUTSCENE
   (`game_manager.gd:1437-1441`); `quick_save` refuses in the same two (`:1811-1815`); `auto_save` is permissive and
   defers while `SceneTransitions.is_transitioning` (`:1802-1807`). So saves can land mid-stew and mid-Fragment.
7. **Tests and records that pin today's placement** (eight places; at /story-readiness this tripped the re-estimate,
   hence 5 days):
   - `chapter1_route_test` `_test_village_afternoon` (`:275`, "gate, ledger and stew play on arrival");
   - `_stew_run` / `_test_bc_stew_flag` (`:1393-1455`, load the village and watch the stew);
   - the main-route drive (`:160-188`) and the kill/spare routes (`:204-221`, `:521`);
   - the T05 scan "exactly one `set_story_flag(ch1_stew_done)` in scripts/" (`:1237-1244`);
   - `_test_bc_table_text` (`:964-967`) asserts `not has_target` for every Chapter 1 step, step 5 included;
   - the tour stop `ch1_breadcrumb_oakhaven` (`screenshot_tour_runner.gd:66`, runs the real stew in the village);
   - `STORY_BIBLE.md:183` names `ch1_oakhaven_village.gd` as the writer of `ch1_stew_done`;
   - `tests/suite_limits.txt`: `load_all_test.gd` min 205 counts scenes and scripts (`:33`), `chapter1_route_test.gd`
     min 391 (`:48`); a new suite needs a line here **and** a step in `.github/workflows/ci.yml` and
     `tests/run_all_tests.ps1` (header, `:24`).
   - Unaffected, confirmed: `tests/integration/story/breadcrumb_golden.json` (Chapter 2+, 71 cases, no Chapter 1
     text). It stays frozen; do not regenerate it.

### Decisions (user, 2026-10-25)

- **D1 Transition: new scenes.** `scenes/chapter1/elara_house.tscn` and `scenes/chapter1/shrine.tscn`, entered with
  `SceneTransitions.change_scene`; the house returns to the village door through `set_return_point`. The village skips
  its arrival once `ch1_stew_done` is set.
- **D2 Getting in: the player walks.** After `invite`, Elara waits at a new house door; step 5 gets an arrow to the
  door; the door is inactive until the invite has played. The stew starts when the player is in the room.
- **D3 Shrine scope: the rest of Chapter 1.** The arena changes to the shrine after the Aldric decision. The altar
  plays Fragment One; then the stair door plays the after-dark card, the bridge news if it fell, the meeting and Elara
  joining, then the shatter transition. Manual saves and Quick Save are refused during that stretch.
- **D4 Protected areas: collision and the Source Key call site, scoped** as listed above.
- **D5 Old saves: forward to the shrine.** An arena load with `ch1_tutorial_knight_defeated` already set skips the fight
  and changes to the shrine.
- **D6 Shrine arrival** (default taken, user did not object): the card and the autosave happen only on a fresh arrival
  from the arena; a load into the shrine plays no card and makes no autosave.
- **D7 Evidence folder** (default taken): `production/qa/evidence/2026-11-rooms/`, as the sprint plan names it.
- **D8 Arrow before the invite** (default taken): step 5's arrow shows from `ch1_oakhaven_entered`, so it points at the
  door during gate/ledger/invite. Accepted: the player cannot move until the invite ends.
- **D9 Suite style:** `ch1_rooms_test.gd` follows this project's SceneTree suites (`_check(cond, name)`, `RESULT:`
  line), not the gdUnit4 `test_[scenario]_[expected]` naming in `.claude/rules/test-standards.md`.

### Room sketches (placeholder shapes, 32 px tiles)

**Elara's house** — 20 × 12 tiles (640 × 384 px), camera limits = room rect.
- Door: bottom wall, centre (Area2D `Door`, inactive while the stew runs).
- Table: centre, 4 × 2 tiles, collision. Elara (placeholder `ColorRect`, no label) on its far side.
- Inspect spots (Area2D, `interact_handler` → the matching `elara_house.dlg` node): `Bandages` (shelf, top-left),
  `Herbs` (drying rack, top-right), `Focuses` (bench, left wall), `Cloak` (peg, by the door), `Map` (right wall).
- Player spawn: just inside the door.

**Shrine** — 16 × 20 tiles (512 × 640 px), tall room, camera limits = room rect.
- Stair door: bottom wall, centre (Area2D `StairDoor`, inactive until Fragment One is collected).
- Gate dressing (just inside the stair door, no labels, no collision), at most one shown: `DressingPurged` (standing
  figure, light), `DressingKilled` (blade shape on the floor), `DressingSpared` (kneeling figure, grey), or none.
- Altar: top-centre, 3 × 2 tiles, collision; the wall above it is the "words on the wall" panel.
- Player spawn: at the stair door.

### Flow after S08

Village: gate → ledger → invite → (player walks; Elara at the door) → door → **house**: fade in → stew (`start`, topics
once each) → `ch1_stew_done` → free to inspect → door → **village** at the house door, arrival skipped, afternoon starts.

Arena: fight → Aldric decision (`aldric.dlg`, unchanged; `open_shrine_gate` flash stays) → consequences, loot,
`ch1_tutorial_knight_defeated` → **shrine**: autosave → "Under the old gate" card → altar → `fragment` →
`collect_source_key(1)` → stair door → CUTSCENE: "Oakhaven, after dark" (+ `bridge_fell` if it fell) → `meeting` →
`joins` → `shatter_transition.tscn`.

---

## Acceptance Criteria

### House

- [ ] AC-1 **House scene.** `scenes/chapter1/elara_house.tscn` (script `scripts/chapter1/ch1_elara_house.gd`) matches
      the sketch: a physics shape query at each wall and at the table hits a body; the five inspect spots each play
      their `elara_house.dlg` node (first line seen); the camera's limits equal the room rect. No new player-visible
      string: every `Label` / `RichTextLabel` text in the scene and every string literal the house script passes to a
      UI node or indicator is either empty or on the allowlist of existing strings — `PlayerLabel` "Kaelen"
      (`oakhaven_village.tscn:129`), "Under the old gate", "Oakhaven, after dark", "SOURCE KEY 1/7"
      (`ch1_tutorial_knight.gd:1274`, `:1284`, `:1362`).
- [ ] AC-2 **Stew in the room.** On entry without `ch1_stew_done`, the house plays `elara_house start` once; each topic
      is still offered only until asked. `ch1_stew_done` is set by `ch1_elara_house.gd` when the stew run returns while
      the house is current, measured as exactly one `GameManager.story_flag_updated("ch1_stew_done", true)` emit, on
      each path: topics then "(Just eat.)"; "(Just eat.)" straight away; `DialogueManager.skip_all()` on the stew's
      second line. Freeing the house while the run awaits emits nothing. The door is inactive while the stew runs. On
      entry with `ch1_stew_done` set, no stew line is seen and the door is active.
- [ ] AC-3 **Getting there.** After `invite`, the player is in EXPLORATION in the village and Elara stands at the house
      door; interacting with her there plays `elara_house invite` again. Before `invite` has played, the door's handler
      does nothing. Villagers, the north field and the bridge stay inactive until `ch1_stew_done` (as today while the
      arrival runs). After `ch1_stew_done`, Elara is at her afternoon spot with only her afternoon handler
      (`elara_repeat`); `invite` is never replayed. Breadcrumb step 5 names `oakhaven_village.tscn` and the door's node
      path: the S5 entry has `scene` = `oakhaven_village.tscn` and `target_node` = `Doors/ElaraHouseDoor`, the arrow is
      visible and aims at the door in the village, and is hidden in the house. Step 5's text is unchanged, and
      `resolve_objective`'s `has_target` (a fixed Vector2 target, Chapter 2+ only) stays false for every Chapter 1 step.
      *(Corrected during /dev-story, user-approved 2026-10-25: the original said "S5 has a target; steps 0–4 and 6–10
      have no target", which does not match the code — steps 0, 1, 7 and 8 already had a `target_node`.)*
- [ ] AC-4 **Coming back.** Leaving the house sets a return point and changes to the village; the village calls
      `arrive_in_exploration_scene`, places the player at the house door, skips gate/ledger/invite/stew because
      `ch1_stew_done` is set (no arrival line seen), and starts the afternoon: villagers talk, three first-time talks
      fire the alarm (`ALARM_AFTER_BEATS` from 0), the north field and bridge triggers work.

### Shrine

- [ ] AC-5 **Shrine scene.** `scenes/chapter1/shrine.tscn` (script `scripts/chapter1/ch1_shrine.gd`) matches the
      sketch: a physics shape query at each wall and at the altar hits a body; the camera's limits equal the room rect;
      the same no-new-string check and allowlist as AC-1 (the shrine script holds the three moved literals).
      Dressing, for these flag sets:

      | Flags set | Visible dressing |
      |---|---|
      | `ch1_root_purge` + `ch1_knight_spared` | Purged |
      | `ch1_knight_killed` + `ch1_root_purge` | Purged (purge is checked first) |
      | `ch1_knight_killed` | Killed |
      | `ch1_knight_spared` | Spared |
      | none | none (the stair door is still gated by the fragment flag) |

      Exactly that node is visible and the others are hidden.
- [ ] AC-6 **Arena hands off.** After `_on_boss_defeated()` and the decision, the arena applies consequences, gives
      loot, sets `ch1_tutorial_knight_defeated` (as today) and requests `change_scene` to `shrine.tscn`, never to
      `shatter_transition.tscn`. Scan: `ch1_tutorial_knight.gd` contains zero occurrences of `FRAGMENT_DLG`,
      `fragment_one`, `bridge_fell`, `fragment_acquired`, `_location_card`, `shatter_transition` and
      `_transition_timer` (the dead countdown is removed).
- [ ] AC-7 **Old saves forward (D5).** An arena `_ready` with `ch1_tutorial_knight_defeated` set starts no fight
      (`combat_started` stays false) and, once `SceneTransitions.transition_completed` has fired (or
      `is_transitioning` is false — `change_scene` silently drops a request made mid-transition,
      `scene_transition_manager.gd:93-94`), changes to `shrine.tscn`, setting the fresh-arrival meta. Tested through
      `GameManager.load_game` (not `change_scene_to_file`) with two real HEAD saves (see AC-11's capture script):
      - saved before `fragment` (`source_key_fragment_1` not set): lands in the shrine, card and autosave happen, altar
        active;
      - saved mid-meeting (`source_key_fragment_1` set): lands in the shrine, no card, no autosave, altar inactive,
        stair door active.
- [ ] AC-8 **Fragment One at the altar.** On a fresh arrival (from the arena, `source_key_fragment_1` not set) the shrine
      calls `GameManager.auto_save()` and shows "Under the old gate"; a load into the shrine (D6) shows no card and
      makes no autosave. Measured in the isolated user dir: delete `user://save_slot_99.save` before the arrival; after
      `transition_completed` plus one frame the file exists and its `current_scene` is the shrine. For a load: delete
      the file after `load_game` returns, wait 10 frames, the file is still absent. The altar runs in the DIALOGUE
      state (so AC-10 b/d can save there) and plays `fragment_one fragment`; `fragment_acquired 1` calls
      `collect_source_key(1)` and shows the "SOURCE KEY 1/7" indicator. Single-fire: two altar handler calls in one
      frame → the first line of `fragment` is seen once and `story_flag_updated("source_key_fragment_1", true)` is
      emitted once. With `source_key_fragment_1` already set on arrival the altar is inactive. The stair door does
      nothing until the flag is set.
- [ ] AC-9 **The rest of Chapter 1 from the shrine.** The stair door switches the game state to CUTSCENE and runs
      "Oakhaven, after dark", then the bridge branch (logic moved unchanged):

      | Before | Plays | `ch1_bridge_fell` |
      |---|---|---|
      | a bridge choice made, `ch1_bridge_saved` not set | card, `north_field bridge_fell` | set |
      | `ch1_bridge_saved` set | card only | not set |
      | no bridge choice flag | card only | not set |

      then `meeting`, `joins`, and `change_scene` to `shatter_transition.tscn`. The stair door is single-fire: two
      handler calls in one frame → the first line of `meeting` is seen once and the first line of `joins` is seen once
      (a request count would not prove it: `change_scene` drops a second request on its own). During the chain
      `GameManager.save_game(0)` and `GameManager.quick_save()` both return false; `auto_save()` stays allowed by design
      (nothing in the chain calls it). `shatter_transition` behaves as before.

### Both rooms

- [ ] AC-10 **Save, load and abort.**
      (a) Save in the house after the stew, load: no stew, door active, leaving returns to the village door with no
      arrival.
      (b) Save mid-stew (DIALOGUE), load: the stew replays from `start`; `ch1_stew_done` is set once.
      (c) Save in the shrine before the altar, load: altar active, stair door inactive, no card.
      (d) Save after `fragment_acquired`, load: altar inactive, stair door active; `source_key_count` over the whole
      route rose by exactly 1.
      (e) Free the shrine (or change scene) mid-`fragment` and mid-chain: no `shatter_transition` request, no second
      award, and afterwards the game state is EXPLORATION (the shrine's `_exit_tree` resets CUTSCENE or DIALOGUE when
      it has requested no scene change). The moved code keeps its `if not is_inside_tree(): return` guards.
- [ ] AC-11 **No drift (golden).** Before any S08 edit, a capture script run from HEAD writes
      `tests/integration/story/ch1_s08_golden.json` (frozen like `breadcrumb_golden.json`; it records the HEAD commit
      hash and the scripted choice indices). Two segments, each recording the sorted true story flags,
      `source_key_count`, `glitch_meter`, `player_stats.gold`, `GameManager.relationships` and the sorted `source_flag`
      values of `ChoiceConsequences.active_buffs` (the field is `source_flag`; corrected during /dev-story). Data Vision is asserted off during capture (it adds corruption after 10 s,
      `player_topdown.gd:295-300`):
      - **Stew**: from a reset game with the explicit preset flag list in the fixture, which includes
        `ch1_oakhaven_entered`, `ch1_northfall_registry_seen` (set at HEAD by gate/ledger, `oakhaven_gate.dlg:23,42`;
        setting them again there changes nothing) and `elara_arm_respected_silence`; picks `[0, 0, 0, 0, 0]` (asked
        topics drop out of the list, so this asks all four, then "(Just eat.)"); captured on the `ch1_stew_done` emit.
      - **Post-Aldric**: from the arena with fixed preset flags, `_on_boss_defeated()`, for the routes kill, spare,
        purge, kill + bridge fell, and kill + no bridge choice; captured on the first `SceneTransitions.transition_started`
        emit while `current_scene` is the arena (HEAD) or the shrine (S08) and `ch1_elara_joined` is set.
      The same script, at HEAD, also writes two real saves through `save_game` in the DIALOGUE state (they carry a valid
      `_checksum`): one before `fragment`, one mid-meeting. They go to `tests/fixtures/ch1_s08_save_pre_fragment.save` and
      `tests/fixtures/ch1_s08_save_mid_meeting.save` and are copied into the isolated user-dir slot before `load_game`
      (AC-7). `ch1_rooms_test` replays each segment through the S08 placement (house; shrine) and the capture is equal
      to the golden. `STORY_BIBLE.md` §5 names `ch1_elara_house.gd` as the writer of `ch1_stew_done`; no other row changes.
- [ ] AC-12 **Gamepad focus.** After the stew's last choice closes and after the meeting choice closes, the GUI focus
      owner is null or visible. In the house, an injected joypad `interact` press near an inspect spot plays it; in the
      shrine, joypad `interact` drives the altar and the stair door before the chain and is inert during it.
- [ ] AC-13 **Reachability.** `reachability_test` lists both rooms; touchability is by geometry only (a door that is
      inactive still counts as touchable). From spawn every Area2D in each room is touchable, nothing blocks the route
      from the stair door to the altar (dressing has no collision), the village still passes with the house block and
      its door, and the sealed-Jessa control still fails.

### Tests, tour, evidence

- [ ] AC-14 **Room suite.** `tests/integration/level/ch1_rooms_test.gd` holds the AC-1–AC-13 cases, is registered in
      `tests/suite_limits.txt` (min checks + a timeout of at least 120 s), `.github/workflows/ci.yml` and
      `tests/run_all_tests.ps1`, and `test_layout_test` passes.
- [ ] AC-15 **Updated suites.** The eight places in audit item 7 are updated: `chapter1_route_test` drives the door,
      the house and the shrine; `_test_bc_table_text` expects a target for S5 only; the T05 stew scan finds its one
      writer in `ch1_elara_house.gd`; `load_all_test` and `chapter1_route_test` minimums are set from the new run.
      `breadcrumb_golden.json` is unchanged.
- [ ] AC-16 **Full run.** `dialogue_test`, `reachability_test`, the full suite (`run_all_tests.ps1`) and
      `git diff --check` pass; logs retained.
- [ ] AC-17 **Tour.** Stops `s08_elara_house` and `s08_shrine` exist; `ch1_breadcrumb_oakhaven` reaches its step-6 shot
      by driving the door handler, then the stew in the house, then the return.
- [ ] AC-18 **Live screenshots.** `elara_house.png` and `shrine.png` from the **live renderer** are retained under
      `production/qa/evidence/2026-11-rooms/`. A headless/dummy-renderer capture does not count. If no live run is
      possible, this AC is DEFERRED, not passed, and the story stays open (not Complete) until the shots exist.
- [ ] AC-19 **Evidence README.** `production/qa/evidence/2026-11-rooms/README.md` maps every AC to its file, labels both
      rooms as placeholder shapes, and lists the known limitations from Out of Scope, including: the shrine's
      `_exit_tree` state reset bumps `_state_change_count`, so a load started from inside the shrine skips `load_game`'s
      saved-state fallback (`game_manager.gd:1710`, `:1737`).

---

## Implementation Notes

- Order: day 1 the golden capture (AC-11) from HEAD, then the room sketches in code and the reachability check of the
  village house block; day 2 the house + village gating; day 3 the shrine + arena hand-off + D5; day 4 the room suite
  and route-test updates; day 5 tour, live screenshots, full run, README.
- Village gating: at the top of the arrival, `if GameManager.has_flag("ch1_stew_done")` → `_entrance_done = true`, no
  arrival. Otherwise play gate → ledger → invite, then hand control back; the house door's handler checks a scene-local
  `_invited` bool. `ch1_oakhaven_entered` is still set in `_ready` either way.
- House door position: a free spot near Elara's afternoon position (700, 900) so the `_add_building_collision` pattern
  (`:462-469`) covers the new block; run `reachability_test` on it before anything else lands.
- Return point: `GameManager.set_return_point(VILLAGE, door_outside_pos)` before `change_scene`; read it with
  `arrive_in_exploration_scene(scene_file_path)` in the village `_ready`. A fresh load ignores it (load sets the
  position itself, `game_manager.gd:1714-1726`).
- Fresh arrival vs load (D6): the arena sets a transient meta (e.g. `GameManager.set_meta("shrine_fresh_arrival",
  true)`, listed in `TRANSIENT_METAS`) before `change_scene`; the shrine reads and clears it. No save field.
- Single-fire: a scene-local `_altar_running` / `_chain_running` bool, set before the first `await`, as the village's
  `_field_running` does.
- Move, do not rewrite: the bridge check, `_location_card` and the `fragment_acquired` / `memory_flash` /
  `touch_fragment` / `village_gathers` / `elara_packs` / `villagers_panic` / `elara_watches` / `kaelen_recoils` /
  `flash_ends` / `elara_joins_party` event cases go to the shrine script with the same behaviour and the same
  `is_inside_tree()` guards. Effects that used the boss sprite stay in the arena (they belong to `aldric.dlg`).
- State exit on abort: the shrine's `_exit_tree` puts the state back to EXPLORATION if it is still CUTSCENE or DIALOGUE
  and no scene change was requested (AC-10e). The village `_run` pattern skips its restore once the scene has left
  the tree (`ch1_oakhaven_village.gd:100-103`), so do not rely on it.
- Arena forward (D5): `_ready` checks the flag first, skips the arena build-up that starts the fight, then
  `if SceneTransitions.is_transitioning: await SceneTransitions.transition_completed` before `change_scene(SHRINE)`.
- AC-6's scan also removes the `fragment_one` mention from the doc comment at `ch1_tutorial_knight.gd:1262` — expected.
- Tour: check the `ch1_aldric` stop (`screenshot_tour_runner.gd:28`) does not inherit `ch1_tutorial_knight_defeated`
  from an earlier stop, or it will be forwarded to the shrine.
- Golden capture: a one-off script under `tests/integration/story/` (kept, documented as "run once at HEAD"); the
  stew segment at HEAD loads the village and waits for the emit, the S08 run loads the house. Choice indices come from
  the fixture, not literals in the suite.
- Test driving: reuse the route test's handler-calling drive (`_on_<x>_interaction(player)` / the `interact_handler`
  meta) for the door, altar and stair door; never walk the player.
- Commit only with the user's OK: `feat(ch1): Elara's house and the shrine are rooms`, `Task: Y1-P0-S08` in the body.

---

## Out of Scope

- Persisting the afternoon state (`_alarm_done`, `_field_resolved`, `_bridge_done`, `_afternoon_beats`) across a village
  load: a mid-afternoon load still restarts the afternoon (now without the stew). Tech-debt candidate.
- New lines for villagers before the stew (they stay silent, as today during the arrival) — note for S07's pacing
  playtest.
- The boss-defeat autosave (written before the Aldric decision) still reloads the fight; only loads with
  `ch1_tutorial_knight_defeated` set are forwarded (D5).
- Production art, room lighting, music changes; a breadcrumb arrow inside the shrine; `aldric.dlg` `purged_later`.
- Any change to `shatter_transition`, the meeting choices, trust values or `collect_source_key`.

---

## QA Test Cases

*Reviewed by qa-lead (QL-STORY-READY, 2026-10-25: GAPS, 15 items → adopted; re-run GAPS, 7 items + 4 advisories →
adopted by the user; cases rewritten).*

- **C1 house (AC-1, AC-2)** — wall/table shape queries; camera limits; empty labels + literal scan; five inspect nodes;
  stew paths (topics → eat, eat at once, skip-all on line 2) each one emit; free mid-run → no emit; door inactive
  during the stew; re-entry with the flag plays nothing.
- **C2 getting there (AC-3)** — door inert before invite; Elara at the door replays `invite`; villagers/field/bridge
  inert until the flag; after the flag only `elara_repeat`; S5 `scene` + `target_node` name the door, arrow aimed at
  the door, hidden in the house; `has_target` false for all Chapter 1 steps.
- **C3 coming back (AC-4)** — player at the door; no arrival line; three talks fire the alarm; field and bridge work.
- **C4 shrine dressing (AC-5)** — the five-row table; no-string check.
- **C5 hand-off (AC-6, AC-7)** — `change_scene` target is the shrine; source scan (seven terms); both HEAD fixture
  saves through `load_game` → no fight, forwarded after the transition, the stated arrival for each.
- **C6 altar and chain (AC-8, AC-9)** — fresh arrival: autosave file appears + card; load: file stays absent, no card;
  altar in DIALOGUE; double altar call → `fragment` first line once, one flag emit; altar inert with the flag; stair
  door inert before it; the three bridge rows; double door call → `meeting` and `joins` first lines once each;
  `save_game(0)` and `quick_save()` false in the chain.
- **C7 save/load/abort (AC-10)** — cases (a)–(e); state EXPLORATION after both aborts.
- **C8 golden (AC-11)** — stew segment (explicit preset list) + five post-Aldric routes equal the fixture, captured on
  `transition_started`; Data Vision off; STORY_BIBLE row.
- **C9 focus and reach (AC-12, AC-13)** — focus owner after both choices; joypad interact in the house and the shrine
  (inert in CUTSCENE); reachability for both rooms + the village; dressing does not block; sealed control fails.
- **C10 suites, tour, evidence (AC-14–AC-19)** — registration in three places + layout guard; the eight updated places;
  full run + `git diff --check`; tour stops incl. `ch1_breadcrumb_oakhaven` step 6; live screenshots (or DEFERRED);
  README.

---

## Test Evidence

**Story Type**: Integration
**Required evidence**: `tests/integration/level/ch1_rooms_test.gd`, `tests/integration/story/ch1_s08_golden.json`, the
two `tests/fixtures/ch1_s08_save_*.save` files and the updated `chapter1_route_test.gd` (passing); `production/qa/evidence/2026-11-rooms/`: `elara_house.png`,
`shrine.png` (live renderer, placeholder shapes), the golden capture log, the `reachability_test` log, the full-suite
log, and `README.md` mapping each AC to its file.
**Run result**: to be recorded by /dev-story (OBSERVED with the retained screenshots).

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Y1-P0-T04 (done), Y1-P0-T05 (done; breadcrumb arrows and `ch1_stew_done`).
- Unlocks: Y1-P0-T15 (Phase 0 exit playthrough). Touches `chapter1_route_test.gd`, which T13a–c and T14b also edit:
  land S08 before T13a starts, or rebase.

---

## Completion Notes

*(filled in by /story-done)*
