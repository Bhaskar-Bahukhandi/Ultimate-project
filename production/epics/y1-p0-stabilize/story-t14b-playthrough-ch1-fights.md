# Story T14b: Playthrough bot from New Game — Chapters 1–2 and the Chapter 1 fights, then on to the credits

> **Epic**: Y1-P0 Stabilize (Sprint 001)
> **Task ID**: Y1-P0-T14b (`production/plan/_source/Y1-P0.json#Y1-P0-T14`; sprint plan row Y1-P0-T14b)
> **Status**: Complete
> **Layer**: Feature
> **Type**: Integration
> **Estimate**: 3 days (sprint row: 1). Day 1 the Chapter 1 legs and the three arena fights; day 2 the knight, shrine,
> shatter and Chapter 2 legs; day 3 caps from measurement, checks, mutations, CI. Over the row because the audit found
> about 27 new legs and two hops no suite drives yet (below).
> **Manifest Version**: N/A — `docs/architecture/control-manifest.md` does not exist
> **Last Updated**: 2026-11-07

## Context

**GDD**: none (test tooling). **Source of record**: the plan entry (title "Extend the playthrough bot from Oakhaven to
the credits"; done "Bot passes New Game → credits headless; CI step added"; edge cases "Timed sequences (medicine
convoy, bridge) on the bot's default path", "A scene that awaits a real-time timer longer than the test timeout") and
the sprint row for T14b ("`tests/integration/playthrough/full_playthrough_test.gd` passes New Game → credits headless in
CI"). T14a built the bot from a seeded Chapter 3 start and left "the Chapter 1 fight legs and stitching New Game →
credits" to this story. **Requirement**: N/A — no TR-ID registered.

**ADR Governing Implementation**: N/A — a test suite; no architectural decision.

**Engine**: Godot 4.6 (4.6.3 at `C:/Godot`, every run with `GODOT` set to the 4.6.3 console exe, TD-036) | **Risk**:
MEDIUM (no post-cutoff API planned; the risk is in run time and real-time caps, not the engine).
**Engine Notes**: `combat_arena.gd` `_leave_story_fight` calls `ContextStack.clear_time_scale()` (scale back to 1); the
bot already re-sets `Engine.time_scale = 4` every frame outside trials (`full_playthrough_test.gd:240-241`). Forcing 4
inside an arena overrides its hitstop requests, which is harmless for a bot that does not play the fight.

**Control Manifest Rules**: NOT ASSESSED — no control manifest.

**Performance**: test-only; no game cost. The suite's run time grows (estimate 4–6 min locally); `suite_limits.txt` and
the CI step's timeout are set from the measurement, and the CI job must stay inside its `timeout-minutes: 45`.

**AGENTS.md protected areas**: **no game code changes in this story.** The bot only plays: the three Chapter 1 arena
fights, the knight, the Chapter 2 bosses, story flags, Source Keys 1–7, auto-saves — all through the game's own code,
inside the runner's isolated `aeth_phase0_test` user directory. Game-side bugs the bot finds are logged, not fixed.

### Audit (2026-11-06, read-only, verified by reading the code; HEAD `dab636f`)

1. **No suite drives New Game → `ironhold_gate` in one chain.** T14a's Audit item 5 says `chapter1_route_test` does; it
   does not. Its continuous leg `_test_new_game_to_region` (`chapter1_route_test.gd:237-297`) goes crash-site hook →
   elara_meeting → slime arena → elara_meeting → path_to_oakhaven → village ⇄ house (boar arena on the way) →
   `oakhaven_region` and stops. The knight is loaded directly (`_knight_scene`, :300-309,
   `change_scene_to_file(KNIGHT)`) and finished with `_on_boss_defeated()`; the shrine and shatter follow from there;
   the shatter → `ironhold_gate` hop is only seen in `_skip_during` (:787-823) on a fresh `reset_game()` with a seeded
   flag (hold-to-skip). `phase0_blockers_test` `_test_new_game_route_reaches_elara_and_oakhaven` (:421-443) also stops
   at the region.
2. **Two hops no suite drives:** the region → knight hop (`oakhaven_region.gd` interact on a `"boss"` target →
   `_enter_boss_arena()`, :895-902 and :1072; a level-under-3 warning whose option 0 is "Enter the Arena"), and the
   shatter scene played through (not skipped) into `ironhold_gate`.
3. **The guardian fight is not a dialogue choice.** It is the Root Access panel in `path_to_oakhaven`: left alone, the
   give-up (`root_panel_timeout` 180 s, `ch1_path_to_oakhaven.gd:218`, scaled, pausable) chooses fight and hands off to
   the T13b arena. Both existing drivers take an edit branch instead (the route test a filter edit, :184-186; phase0 the
   aggression spinbox, :378-410), so no suite drives the guardian arena from the path.
4. **Chapter 2** (`chapter2_route_test.gd`, careful route, every choice option 0, :141-210): gate → region; talk to
   Rook; Command Hall gate → hall → region; talk to Rem (convoy) → West Road gate (delivered early); the arena's bronze
   bracket set by flag (`ch2_arena_bronze_complete`, :168, "arena combat not under test") + `_place_story_gates()`;
   Clock Tower gate → tower, `_on_automaton_defeated()`; Underground gate, `_on_wraith_approach` +
   `_on_data_wraith_defeated()`; Admin Boss gate, `_on_boss_defeated()` → seraphina_choice → ch2_ending (end card:
   `skip_timer`) → `chapter3/ironhold_departure`. It starts from a 6-flag Chapter 1 seed at **level 12** "to skip the
   soft level warnings at boss gates" (:130-138). The convoy's "early" branch depends on talking to Rem before the tower
   (event order, not a timer); the bridge's "before dark" is set by the choice, not a deadline.
5. **Fights in the existing drivers** (`chapter1_route_test.gd:212-222`, phase0 `_ch1_poke`): the arena's `_story_enemy`
   is finished through its own API (`_enter_dizzy()` when it has one — the boar — then `take_damage(max_health)`). Rows'
   win flags: slime `first_slime_defeated`, `ch1_slime_fought`; guardian `ch1_guardian_fought`; boar
   `ch1_boar_fight_won` (`combat_arena.gd:123, 155, 185`).
6. **No shared helper library**: `_drive`, `_wait_for` and the scene pokes are inline and copied across three suites.
7. **Run time and caps.** The route tests allow 60–420 s per hop; the bot's caps are 60 s (story/region) and 30 s
   (trial), real time. At 4× the Root Access give-up alone is about 45 s real. CI #55: "Chapter 1 route" 542 s (the
   whole ~30-case suite), the bot's step 61–72 s, the job 28m44s against `timeout-minutes: 45` (`ci.yml:14`); the bot's
   step `timeout-minutes: 10` (:227), its suite limit 240 s (`suite_limits.txt:55`).
8. **The seed's drift.** Since `74e40e8` (the seed's source), 7 commits touched Chapter 1 or combat code and none
   Chapter 2. A real run reaches Chapter 3 with Chapter 1 flags the seed never had and a lower level, gold and XP than
   the seed's level 12 / 800 / 375; Chapters 3–10 have only ever been driven from the seed.
9. TD-010 is Complete (2026-10-25), so its `ci.yml` edits are in.

### Decisions (user, 2026-11-06)

- **D1 one chain:** drop `SEED_*`. The bot runs New Game → Chapters 1–2 → its existing Chapter 3–10 legs → credits in
  one run. A break in Chapters 1–2 stops the run there (no later leg runs on a broken state, as today).
- **D2 guardian:** leave the Root Access panel alone until its give-up, so the bot fights the T13b guardian. All three
  Chapter 1 arena fights are on the bot's path.
- **D3 fights:** as T14a's trials and the route tests: wait until the fight is running with the player alive, then
  finish it through the game's own API (arena enemies: `_enter_dizzy()` if present, then `take_damage(max_health)`; the
  knight and the Chapter 2 bosses: their scenes' `_on_*_defeated` callbacks; Chapter 2's bronze bracket set by its flag
  as `chapter2_route_test` does). Each is a named isolation cost; T15's human pass plays them.
- **D4 shared code:** copy the pokes the bot needs into `full_playthrough_test.gd` (no change to the three route
  suites); log a tech-debt item for the duplicated drivers.
- Carried from T14a: option 0 at every choice (D4 there) — in Chapter 2 the region legs follow `chapter2_route_test`'s
  careful order (Rook, Command Hall, Rem and the west road before the tower), which is option 0 plus the order a player
  takes; a test-side work-around may only do what a player could do, except the named isolation costs.

---

## Acceptance Criteria

- [ ] AC-1 **One chain from New Game.** The bot starts with `GameManager.reset_game()` and the first story scene (the
      crash-site hook), as a New Game does, with no seeded flag, key, stat or relationship (`SEED_*` removed; the header
      rewritten). It runs every leg to `ironhold_departure` and on through T14a's legs to the credits in one run. Leg
      table (`LEGS`, one list as today, each with its kind and its own real-time cap): hook → elara_meeting → arena
      (`ch1_slime`) → elara_meeting → path_to_oakhaven → arena (`ch1_guardian`) → path_to_oakhaven → oakhaven_village ⇄
      elara_house → arena (`ch1_boar`) → oakhaven_village → oakhaven_region → tutorial_knight_boss → shrine →
      shatter_transition → ironhold_gate → ironhold_region (with seraphina_encounter, clock_tower, underground_network
      and administrator_boss as their own legs) → seraphina_choice → ch2_ending → ironhold_departure (T14a's leg 0) … →
      the credits. The exact list is written in the evidence leg table and matches `LEGS`.
- [ ] AC-2 **The three Chapter 1 fights.** For each arena leg the bot checks: the scene is `combat_arena.tscn` with
      `story_fight_id` the row's id; before the finish, each of the row's win flags (slime `first_slime_defeated`,
      `ch1_slime_fought`; guardian `ch1_guardian_fought`; boar `ch1_boar_fight_won`) is false (a flag set by an earlier
      leg or another path fails the leg); through the alive window `FIGHT_ALIVE_S` (3 s of game time counted from
      `Engine.get_physics_frames()` ÷ `Engine.physics_ticks_per_second`, with a wall cap) the player stays alive and the
      story enemy's `current_state` is never DEAD and leaves IDLE at least once (its AI ran); a death in the window
      fails the run with T14a's report (no retry is allowed). Then it finishes the enemy through its own API (D3) and
      checks the row's win flags are now set, no retry ran (`story_fight_retries` 0), the player is not dead, and the
      arena hands off once to the scene the row returns to. The guardian leg is reached through the Root Access give-up
      with no input to the panel (D2), checked on the game's state, not the bot's own record: `_root_choice == "fight"`,
      the target filter still on ALL (index 0), aggression still 1.0, and `GameManager.glitch_meter` unchanged since the
      panel opened (each edit adds 10, `ch1_path_to_oakhaven.gd:497`).
- [ ] AC-3 **The undriven hops.** Region → knight: the bot clears the `boss_return_scene` meta at the leg's start, then
      interacts with the region's boss target through the region's own interaction handler (the path a player's interact
      key takes). If the level warning shows (level under 3, `oakhaven_region.gd:1080`), the bot answers option 0
      ("Enter the Arena") and checks the warning's choice was seen; if it does not show, the bot logs the level. The hop
      check: `GameManager`'s `boss_return_scene` meta is `res://scenes/regions/oakhaven_region.tscn` before
      `tutorial_knight_boss` loads (only the region's `_enter_boss_arena()` sets it). The knight is finished with
      `_on_boss_defeated()` once its combat has started and the player has been alive for `FIGHT_ALIVE_S` (game time, as
      AC-2). Shrine: altar, then stair door. Shatter: played through with no skip input; the no-skip check is that the
      scene's `chapter_end_card` was seen visible and the "Chapter 1 Complete. Press … to continue" line was shown (the
      skip path, `_on_skip_cutscene`, shows neither); the leg ends at `ironhold_gate`.
- [ ] AC-4 **Chapter 2 legs.** The careful order of `chapter2_route_test` (Audit 4), through the region's own
      interaction handlers; the bronze bracket set by its flag and the bosses finished by their callbacks (D3), each
      named in the header's isolation costs. Any soft level warning at a boss gate (shown below the gate's recommended
      level minus 2, `ironhold_region.gd:1152`) is answered with option 0 ("Enter (Suicidal)"), which enters; the bot
      logs each warning seen, with the level. At the Chapter 3 hand-off the bot prints the full flag set, keys, level,
      gold, XP and relationships, and the evidence records the difference from T14a's old seed (INFO, not a check).
- [ ] AC-5 **Per-leg checks as T14a.** At every hand-off (`transition_started`): no dialogue active, no ContextStack
      entry open (R5), the leg's flags set (the evidence leg table lists them per leg, taken from what the route tests
      assert), and the next scene the one the table names. A cap or a wrong next scene stops the run with T14a's
      softlock report. Every Chapter 3–10 check T14a had still runs and passes from the real state (Source Keys 1–7 by
      the end; NG+ offered; credits opened and skipped).
- [ ] AC-6 **Caps and run time.** Three local runs, each leg's real time logged per run. Each new leg's cap is at least
      3× its slowest run and at least 60 s; the leg table records all three times and their spread. The whole suite's
      local time is recorded; `suite_limits.txt` (min checks and timeout) and the CI step's `timeout-minutes` are raised
      from it; the step name says "New Game to the credits"; the CI job stays under its 45-minute limit.
- [ ] AC-7 **Tests and evidence.** Watched failing: the new legs fail on a deliberately broken driver before they pass.
      Mutations, one per run, each caught by its named check: (a) the slime row's win flags emptied by a runtime
      override inside the test (not an edit to `combat_arena.gd`) → the slime leg's flag check; (b) a fight finished
      before the alive window → the alive check; (c) the bot presses the Root Access panel (filter edit) → the guardian
      leg's game-state check; (d) the shatter skipped by input → the shatter leg's no-skip check; (e) Rem skipped (tower
      first) → the convoy leg's `ch2_medicine_early` check; (f) the knight hop done by `change_scene_to_file` instead of
      the region → the `boss_return_scene` hop check; (g) a 1 s cap on one Chapter 1 leg → the softlock report names
      that leg; (h) one Chapter 1 leg's next scene in the table made wrong → the next-scene check; (i) one room leg's
      expected flag swapped for a flag the game never sets → that leg's flag check; (j) a ContextStack entry pushed
      before a hand-off → the R5 check; (l) the player killed in a fight's alive window → the alive check fails the run
      naming the death. Three local runs green; full local run green on 4.6.3; CI green. Evidence in
      `production/qa/evidence/2026-11-playthrough/` (README with the AC map, leg table with flags and the three runs'
      times, run and mutation logs, the Chapter 3 state diff). A tech-debt row for the duplicated drivers (D4).
      CHANGELOG `test:` entry; `git diff --check` clean. No file under `AethelgardPrototype/scripts`, `scenes` or
      `dialogue` changes (`git diff --name-only` checked at close).

---

## Implementation Notes

- Reuse the bot's own driver (`_drive_frame`, `_arm_leg`, `_await_scene_change`, `_report`, `_finish`); add leg kinds
  for "room" (scene pokes), "fight" (arena) and "boss" (knight and Chapter 2 bosses), and per-leg caps in `LEGS`.
- Copy the pokes from `chapter1_route_test.gd` (`_poke_room` :199, hook start :250-255) and `chapter2_route_test.gd`
  (`_region_idle` :104, `_talk` :111, `_enter_gate` :119) into the bot, each with a comment naming its source.
- Fight leg: wait for `arena._story_enemy`, check the row's win flags are still false, then the alive window, then
  finish (D3). Count game time from physics frames (`Engine.get_physics_frames()` delta ÷
  `Engine.physics_ticks_per_second`) with a wall cap: T14a's trial `dt` (wall ms × scale, `full_playthrough_test.gd`
  :387 and :468) over-counts on slow frames; T14a's trial legs keep their own counting.
- The Root Access give-up is 1800 pausable 0.1 s ticks (180 s of game time, `ch1_path_to_oakhaven.gd:429-437`): about 45
  s real at 4× is the floor, and frame quantisation can lengthen it; that leg's cap comes from AC-6's measurement.
- Keep `_finish` as the single exit (time scale restored on every path).

---

## Out of Scope

- Any game code, scene or dialogue change (AGENTS.md protected areas; findings are logged).
- Changing `chapter1_route_test`, `chapter2_route_test` or `phase0_blockers_test` (D4), and correcting T14a's closed
  story text (this story's Audit item 1 records the correction).
- Playing fights through input (D3); other routes, choices other than option 0, the Chapter 2 arena bracket itself.
- The ending not rolling the credits (T14a's finding, protected true-ending code).
- T15 (the human playthrough on an exported build).

---

## QA Test Cases

- **C1 (AC-1)** — the bot's first scene is the crash-site hook after `reset_game()`, no `SEED_*` symbol remains, the
  order check covers every leg in `LEGS`, the run reaches the credits.
- **C2 (AC-2)** — per arena leg: row id, win flags false before the finish, alive window in game time (physics frames)
  with the enemy never DEAD and out of IDLE at least once, a death in the window failing the run, finish, win flags set,
  retries 0, player not dead, one hand-off to the row's return scene; the guardian reached with `_root_choice` "fight",
  filter ALL, aggression 1.0 and `glitch_meter` unchanged.
- **C3 (AC-3)** — the knight scene reached from the region's boss interaction (`boss_return_scene` set by
  `_enter_boss_arena()`, not `change_scene_to_file`), the level warning answered with "Enter the Arena" if shown (else
  the level logged); shrine altar and stair; shatter played through (end card seen, the "Chapter 1 Complete" line shown)
  to `ironhold_gate`.
- **C4 (AC-4)** — the Chapter 2 flags the route test asserts on its careful route (`ch2_market_visited`,
  `ch2_command_hall_done`, `ch2_medicine_done` + `ch2_medicine_early`, `ch2_tower_bell_stopped`,
  `ch2_data_wraith_restored`, `ch2_city_stable`, `source_key_fragment_2` with count 2, `ch2_complete`); each boss-gate
  warning seen answered with option 0 and logged; the Chapter 3 state printed.
- **C5 (AC-5)** — every leg's R5 sample and flags; T14a's Chapter 3–10 checks unchanged and green.
- **C6 (AC-6/7)** — the three runs' times, their spread and the caps in the leg table; registration updated; mutations
  (a)–(j) and (l) each failing its own check; full local run and CI green.

---

## Test Evidence

**Story Type**: Integration
**Required evidence**: `AethelgardPrototype/tests/integration/playthrough/full_playthrough_test.gd` (passing, three
local runs), the full local run, CI green, and `production/qa/evidence/2026-11-playthrough/` (README with the AC map,
leg table, logs, mutation logs, the Chapter 3 state diff).
**Run result**: N/A — test-only story: no game code, scene or dialogue changes, so nothing new is player-observable;
the bot's logs are the observation.

---

## Dependencies

- Depends on: Y1-P0-T13a, T13b, T13c (Complete, the three arena fights), Y1-P0-T14a (Complete, the bot), TD-010
  (Complete, the runner self-test's `ci.yml` edits).
- Unlocks: Y1-P0-T15 (a human plays New Game to the credits on an exported build).

---

## Completion Notes

**Completed**: 2026-11-07

**Criteria**: 7/7 met locally, with two CI parts DEFERRED to the push: AC-7 "CI green" and AC-6 "the CI job stays under
its 45-minute limit" (expected about 31 min; the first CI run also logs leg 04's time against its 180 s cap).

**Final bot**: SHA-256 `5fb81cfe…` (`b6e7b29f…` plus `CAP_GUARDIAN` 160 -> 180 at the /story-done gate). 405 passed, 0
failed in `t14b_hopfix_run1..3.log` (182.1-183.2 s) and `t14b_capfix_run1.log` (183.9 s); full run 28/28 on 4.6.3
(`t14b_run_all_final.log`, on `b6e7b29f…`); mutations a, b, c, d, e, f, f2, g, h, i, j, l each caught by its named
check, file restored and SHA-256 verified (`t14b_mutation_<id>.log`, on `b6e7b29f…`; `t14b_mutate.py --check` 12/12 on
the final file).

**Deviations** (advisory, accepted):
- AC-2: the alive window counts physics frames ÷ ticks per second × the time scale (the story's formula without the
  scale counts real seconds); the arena window also needs the enemy out of IDLE; the knight and Chapter 2 boss windows
  use the same game time.
- AC-5: five hand-offs with the dialogue box up are excepted by `KNOWN_R5_DIALOGUE` (user decision; TD-043); a listed
  leg with no dialogue fails, so the list can only shrink.
- AC-6: caps measured locally only. At the /story-done gate `suite_limits.txt` went from `405 360` (2x, against the
  file's 3x rule) to `405 600`, the CI step's `timeout-minutes` from 10 to 12 (AC-6's raise had not been done), and the
  guardian leg's cap from 160 s to 180 s (3x its slowest final run, 60.0 s).
- AC-7: mutation (e) redefined to option 1 "We go up now." at `tower_warning` (the game refuses the tower under option
  0); (f) uses `SceneTransitions.change_scene` so it reaches the hop check, the story's `change_scene_to_file` is the
  extra (f2); b v2 and l v2 are re-runs on the game-time window; (k) was dropped at readiness.
- C1: `SEED_` remains in one header comment ("T14a's SEED_* … is gone"), no symbol.
- Two flakes root-caused and fixed test-side: the boar death (HP carried over, 3 s real windows) and the knight hop
  (re-placement loop never pressed interact, steps built a random ambush). Evidence README sections.

**Tech debt logged**: TD-043 (five hand-offs with dialogue up), TD-044 (random encounter in the knight scene), TD-045
(`enemy_base.gd:923` flash_tween ERROR), TD-046 (duplicated drivers, D4), TD-047 (enemy AI during the COMBAT_ENTRY
fade).

**Test Evidence**: Integration: `AethelgardPrototype/tests/integration/playthrough/full_playthrough_test.gd`;
`production/qa/evidence/2026-11-playthrough/` (README with the AC map, `leg_table.md`, run and mutation logs, the
Chapter 3 state diff). Run result: N/A, test-only, no game code, scene or dialogue change (`git diff --name-only`
checked).

**Code Review**: Complete. /code-review round 1 CHANGES REQUIRED, fixed, then APPROVED WITH SUGGESTIONS; LP-CODE-REVIEW
CONCERNS, acted on (AC-6 limits, leg-table times, README); QL-TEST-COVERAGE ADEQUATE.

**Open suggestions and untested checks** (not logged as debt): `_drive_leg` 112, `_drive_fight` 63, `_drive_boss` 43 and
`_play` 42 code lines (over 40; `_drive_leg` over complexity 10); a null player reads as a death (`:811`, `:1060`);
"left IDLE" also passes for PATROL; legs 12, 21 and 23 check only flags set earlier; no mutation for the
enemy-never-DEAD check, the hand-off retries / player-alive checks, the boss alive window, the R5 dialogue half, or a
death outside the slime fight; the warning log matches option text exactly; SETTLE_FRAMES counts frames.
