# Story T14a: Playthrough bot from Chapter 3 to the credits — every Chapter 3–10 scene driven headless

> **Epic**: Y1-P0 Stabilize (Sprint 001)
> **Task ID**: Y1-P0-T14a (`production/plan/_source/Y1-P0.json#Y1-P0-T14`, days 1–3; sprint plan row Y1-P0-T14a)
> **Status**: Complete
> **Layer**: Feature
> **Type**: Integration
> **Estimate**: 3 days (map and Chapter 3; Chapters 4–6; Chapters 7–10, ending and records)
> **Manifest Version**: N/A — `docs/architecture/control-manifest.md` does not exist
> **Last Updated**: 2026-10-25

## Context

**GDD**: none (test tooling). **Source of record**: the plan entry above (title "Extend the playthrough bot from Oakhaven to
the credits", why "Phase 0 exit: 'the bot passes'; R8 no tests → bot coverage"; edge cases "Timed sequences (medicine
convoy, bridge) on the bot's default path", "A scene that awaits a real-time timer longer than the test timeout",
"Credits skipped vs watched"), and the sprint plan row for T14a ("`full_playthrough_test.gd` drives Ch4–10 headless;
softlocks found are logged by ~Day 0033. **Runs before T13**"). T14b (after T13a–c and TD-010) adds the Chapter 1 fight
legs and stitches New Game → credits. **Requirement**: N/A — no TR-ID registered.

**ADR Governing Implementation**: N/A — a test suite; no architectural decision.
**ADR Decision Summary**: N/A
**ADR Version**: N/A

**Engine**: Godot 4.6 (4.6.3 at `C:/Godot`) | **Risk**: HIGH (`docs/engine-reference/godot/VERSION.md`, 4.6 row)
**Engine Notes**: no post-cutoff API is planned. `ch3_ending._wait_for_input()` polls `Input.is_action_just_pressed`, so the
bot must feed a real input event (`Input.parse_input_event` with an `InputEventAction` for `ui_accept`, pressed then
released on the next frame) — verify that `is_action_just_pressed` sees it in a headless SceneTree script before relying
on it. `DialogueManager.show_choices` clears a pending `skip_all()` (dialogue_manager.gd:407-408), and each choice has a
0.5 s grace period (:690), so the driver re-arms the skip after every choice. `Engine.time_scale = 4` speeds scaled
waits (chapter2_route_test.gd:38 does the same), **but the hazard trials reset it**: `late_game_hazard_trial.gd` calls
`ContextStack.clear_time_scale()` at :54 and :511 (every attempt), and `context_stack.gd` `_apply_time_scale()` then sets
`Engine.time_scale = 1.0`; a hitstop release does the same. GDScript has no `finally`, so restoring the scale needs one
exit function that every path goes through. The trials use no random numbers (no `randf` / `randi` in the script), so an
attempt is deterministic.
`CreditsScreen` is an autoload with process mode ALWAYS that pushes a pausing ContextStack entry.

**Control Manifest Rules**: NOT ASSESSED — no control manifest.

**Performance**: test-only; no game cost. The suite's own run time is measured and recorded (expected a few minutes at
time scale 4; the CI step and `suite_limits.txt` timeout are set from the measurement).

**AGENTS.md protected areas**: **no game code changes in this story.** The bot only plays: it collects Source Keys 3–7,
sets the true-ending and NG+ flags, and writes auto-saves — all through the game's own code, inside the runner's isolated
`aeth_phase0_test` user directory. Collision, combat, save/load schema, story progression, Source Key, true ending, NG+,
world-map / free-travel code: read, never edited. Game-side bugs the bot finds are logged, not fixed (AC-6).

### Audit (2026-10-25, verified by reading the code)

1. **Chapter 3 chain.** `ironhold_departure` → `scenes/regions/fractured_wastes_region.tscn` (a region) → its
   `ServerRoomGate` (placed only when `ch2_data_wraith_defeated` is set and `ch3_fragment_3_collected` is not;
   `_interact_story` sets `ch3_server_room_unlocked` and changes to `scenes/chapter3/fractured_wastes.tscn`,
   fractured_wastes_region.gd:603-645) → `fractured_wastes` → `data_stream` → `archive_depths` → `kaelthas_betrayal` →
   `ch3_ending` → `scenes/chapter4/ch4_forgotten_sectors_intro.tscn`. With option 0 at the archive, Kaelthas is allied and
   the betrayal scene takes its allied path (ch3_kaelthas_betrayal.gd:35); otherwise its "boss" is 3 phases of 3 choice
   rounds. `ch3_ending._wait_for_input()` (:308-318) waits for a real `ui_accept` / `jump` press, capped at 120 s of scaled
   time. Fragments 3 and 4 are collected in Chapter 3.
2. **Chapters 4–10 chain (linear; choices set flags only).** ch4: forgotten_sectors_intro → null_court (Source Key 5) →
   ending. ch5: mirror_city_intro → mirror_plaza → reflection_trial → mirror_kaelen_confrontation → ending. ch6:
   cathedral_intro → cathedral_nave → choir_core (Source Key 6) → **choir_combat_trial** → ending. ch7: deep_backup_intro →
   memory_ocean_hub (a story scene) → archive_tide (Source Key 7) → **archive_tide_combat_trial** → ending. ch8:
   revolt_intro → saved_assembly → revolt_crisis → ending. ch9: human_patch_intro → memory_lab → creator_trial → ending.
   ch10: root_intro → kernel_descent → witness_chamber → **sovereign_final_trial** → sovereign_confrontation → ending →
   `main_menu.tscn`. Each story scene sets flags, auto-saves to slot 99, fades, runs `say` / `show_choices`, and changes
   scene. **No `create_timer` in scripts/chapter4–10.**
3. **Hazard trials** (`scripts/combat/late_game_hazard_trial.gd`, the three bold scenes): real-time arenas (about 11–12 s
   per attempt); a death sets `_retry_requested` and loops forever (no game over). Each trial skips itself if its cleared
   flag is set, and `_complete_trial()` (:537) grants rewards, auto-saves and hands off.
4. **The ending does not roll the credits.** `ch10_ending.gd` sets `ch10_complete`, `true_ending_seen`, `ng_plus_unlocked`
   and `ng_plus_available = true` (:14-17), shows a static "TRUE ENDING … Credits …" text (:77) and returns to the main
   menu (:31). `CreditsScreen` (autoload, `scripts/ui/credits_screen.gd`) only opens from the main menu's Credits button
   (`show_credits(false)`, main_menu.gd:922); it scrolls at 40 px/s (160 with `jump` held) and closes on ui_cancel /
   pause_menu / skip.
5. **Existing coverage.** chapter1_route_test: New Game → … → ironhold_gate. chapter2_route_test: ironhold_gate → … →
   `scenes/chapter3/ironhold_departure.tscn` (its last check). ch3_flash_runtime_test: archive, wastes, departure (flash
   lines only). phase0_blockers_test only loads ch4_forgotten_sectors_intro and ch10_ending for save checks. **Nothing
   drives data_stream, kaelthas_betrayal, ch3_ending or any Chapter 4–10 scene end to end**; there is no earlier bot.
   Reusable patterns: chapter2_route_test's `_drive` / `_wait_for(path, timeout)` / `_region_idle` / `_enter_gate`, and
   ch3_flash_runtime_test's skip-and-answer driver.
6. **Registration.** `test_layout_test.gd` (:32, :39) fails unless every suite is in `run_all_tests.ps1` **and** `ci.yml`,
   so this suite gets its CI step now (the sprint row puts "CI step" in T14b; T14b extends the same suite and step).

### Decisions (user, 2026-10-25)

- **D1 start point:** Chapter 3's first scene, `ironhold_departure`, where chapter2_route_test stops — all of Chapter 3,
  then Chapters 4–10.
- **D2 hazard trials:** load each trial for real, check its loop starts and the player stays alive for a few seconds, then
  call the scene's own `_complete_trial()`. Fighting is out of scope (T15's human pass plays them).
- **D3 credits:** "reaches the credits" = `ch10_ending` ran with its flags, the main menu returns with NG+ offered, then
  `CreditsScreen` is opened from the menu and skipped. "The ending never plays CreditsScreen" is logged as a finding for
  design (true ending is protected; not changed here).
- **D4 route:** option 0 at every choice (the "liberation" ending), recorded choice by choice.
- **QL-STORY-READY (GAPS, all 10 adopted by the user, 2026-10-25):** time-scale handling, the trial "alive" window, the
  input-event fallback, the R5 sampling point, an exact per-leg flag table, the seed's source commit, auto-save checks,
  named credits / NG+ nodes, specific mutations (plus a driver mutation) and concrete QA cases. A test-side work-around
  may only do what a player could do. D2 means the trials' reward and flag paths run through the direct
  `_complete_trial()` call only; the arena itself is played by a human in T15.

---

## Acceptance Criteria

- [x] AC-1 **Leg table.** `production/qa/evidence/2026-10-playthrough/leg_table.md` lists, in order, every scene from
      `scenes/chapter3/ironhold_departure.tscn` to `main_menu.tscn` (Chapter 3 region leg included): how it advances, what
      the bot does there, the key flags it sets, and the next scene. The suite's expected scene order is a literal list
      that matches this table entry for entry.
- [x] AC-2 **Start state.** The bot calls `GameManager.reset_game()`, then seeds exactly the state chapter2_route_test
      leaves at its Chapter 3 hand-off — the story flags, `source_key_count`, `current_chapter` and any meta the Chapter 3
      scenes read — captured once (by printing that state at the end of a chapter2_route_test run) and stored as a
      literal in the suite with a comment naming the commit it was captured at (drift until T14b stitches the two routes
      is an accepted risk); it includes the party / Elara state (`GameManager.has_elara()` is read in Chapter 3) and
      `ch2_data_wraith_defeated` (the Wastes gate needs it); then it loads `ironhold_departure`. The isolation
      guard (`OS.get_user_data_dir()` contains `aeth_phase0_test`) runs first.
- [x] AC-3 **Driver.** One driver, every frame: an open choice → option 0 (logged: scene, prompt, chosen text); active
      dialogue → `skip_all()`, re-armed after every choice; `ch3_ending`'s input wait → a real `ui_accept` input event
      (`Input.parse_input_event` with an `InputEventAction`, pressed then released next frame), and if the suite's first
      check shows `is_action_just_pressed` does not see it headlessly, the fallback `_waiting_for_input = false` is used
      and named in findings.md (the scene's own 120 s cap is scaled time: 30 s real at 4x);
      the Wastes region → the bot reaches `ServerRoomGate` and interacts with it the way chapter2_route_test enters
      gates; a hazard trial → wait until one attempt is running and the player has stayed alive in it for at least 3 s
      (summed scaled delta, within that attempt: `_attempts` unchanged, `_retry_requested` false, player alive; a death
      restarts the count on the next attempt), then call `_complete_trial()`. Every leg has a real-time cap measured with
      `Time.get_ticks_msec()` (60 s for a story scene or region, 30 s for a trial); hitting a cap fails the run with the
      leg index, scene path, elapsed real seconds, the last speaker and line shown, the open choice prompt (if any) and
      the last choice answered, and stops the bot (no later legs run on a broken state). Outside trials the bot sets
      `Engine.time_scale = 4` every frame (trials and hitstops reset it); a single exit function, used by every pass and
      fail path, sets it back to 1 and calls `ContextStack.clear_time_scale()`.
- [x] AC-4 **Per-leg checks.** For each leg: the next scene is the one the leg table names (order asserted); at each
      hand-off — sampled at the scene's own `SceneTransitions.transition_started` (*amended at code review*: the start of
      the fade-out is the hand-off; one frame after the transition the next scene may already have opened its own
      dialogue) — `DialogueManager.is_active` is false and `ContextStack.top()` is empty (the plan's R5 check); the leg's flags are set, exactly this table (option-0
      path; verified in the scripts):
      ironhold_departure `ch3_ironhold_departed` · Wastes region gate `ch3_server_room_unlocked` · fractured_wastes
      `ch3_fragment_3_collected` · data_stream `ch3_data_stream_complete` · archive_depths `ch3_fragment_4_collected`,
      `ch3_kaelthas_allied` · kaelthas_betrayal (hand-off to ch3_ending) · ch3_ending `ch3_complete`, `ch4_unlocked` ·
      ch4_forgotten_sectors_intro `ch4_forgotten_sectors_entered` · ch4_null_court `ch4_choice_preserve_deleted` ·
      ch4_ending `ch4_complete` · ch5_mirror_city_intro `ch5_mirror_city_entered` · ch5_mirror_plaza
      `ch5_identity_refused_obedience` · ch5_reflection_trial `ch5_echo_control_rejected` · ch5_mirror_kaelen_confrontation
      `ch5_mirror_duel_cleared` · ch5_ending `ch5_complete` · ch6_cathedral_intro `ch6_cathedral_entered` ·
      ch6_cathedral_nave `ch6_mercy_trial_cleared`, `ch6_efficiency_trial_cleared`, `ch6_obedience_trial_cleared` ·
      ch6_choir_core `ch6_choir_silenced`, `ch6_fragment_6_collected` · ch6_choir_combat_trial
      `ch6_choir_combat_trial_cleared` · ch6_ending `ch6_complete` · ch7_deep_backup_intro `ch7_deep_backup_entered` ·
      ch7_memory_ocean_hub `ch7_memory_island_hazard_cleared` · ch7_archive_tide `ch7_backups_preserved`,
      `ch7_fragment_7_collected` · ch7_archive_tide_combat_trial `ch7_archive_tide_surge_cleared` · ch7_ending
      `ch7_complete` · ch8_revolt_intro `ch8_revolt_intro_seen` · ch8_saved_assembly `ch8_faction_requests_started` ·
      ch8_revolt_crisis `ch8_revolt_led` · ch8_ending `ch8_complete` · ch9_human_patch_intro `ch9_human_patch_entered` ·
      ch9_memory_lab `ch9_data_vision_scan_complete` · ch9_creator_trial `ch9_truth_confessed` · ch9_ending
      `ch9_complete` · ch10_root_intro `ch10_root_entered` · ch10_kernel_descent `ch10_kernel_trial_cleared` ·
      ch10_witness_chamber `ch10_witness_preparation_complete` · ch10_sovereign_final_trial
      `ch10_sovereign_final_trial_cleared` · ch10_sovereign_confrontation `ch10_destroy_sovereign` · ch10_ending (AC-5).
      If /dev-story finds a flag on this list is not set on the option-0 path, that is a story correction recorded in the
      leg table, not a silent change. Source Keys 3–7 are collected (`source_key_count` = seed + 5 at the end). After the
      run `user://save_slot_99.save` exists inside the isolated `aeth_phase0_test` directory (the game auto-saves there),
      and the suite never writes outside `user://`. The SCRIPT ERROR / Parse Error scan is the runner's (TD-003), not the
      suite's. The suite's log prints one line per leg (index, scene, real seconds, choices answered).
- [x] AC-5 **Ending and credits.** After `ch10_ending`: `ch10_complete`, `true_ending_seen` and `ng_plus_unlocked` are set
      and `GameManager.ng_plus_available` is true; the ending's text contains "TRUE ENDING"; `main_menu.tscn` loads and its
      `_check_ng_plus_availability()` has added the visible "NEW GAME+" button. Then `CreditsScreen.show_credits(false)`
      opens it (visible, `ContextStack.top()` not empty), a `ui_cancel` input event closes it (the screen's skip:
      ui_cancel / pause_menu / skip, credits_screen.gd:251), and afterwards `ContextStack.top()` is empty and
      `get_tree().paused` is false. Watching the full scroll to its automatic end is not tested (accepted residual risk).
- [x] AC-6 **Findings, not fixes.** No file under `scripts/`, `scenes/` or `dialogue/` changes
      (`git diff --name-only <story-start commit>..HEAD -- AethelgardPrototype/scripts AethelgardPrototype/scenes
      AethelgardPrototype/dialogue` is empty at close). Every game-side defect the
      bot meets (a softlock, a dead end, a stuck dialogue, a missing hand-off, the ending not rolling CreditsScreen) is
      written to `production/qa/evidence/2026-10-playthrough/findings.md` (scene, symptom, how to reproduce, the bot's
      log line) and becomes a tech-debt row at close. A defect the bot cannot pass by playing is reported as the run's
      failure naming the scene (the plan's "or reports the exact blocking scene"); a test-side work-around is used only
      if it does what a player could do (pressing a key, walking to a gate, answering a prompt), and is named in the
      finding.
- [x] AC-7 **Suite, watch-fail and records.** `tests/integration/playthrough/full_playthrough_test.gd` (+ `.uid`), its own
      column-0 result line `PLAYTHROUGH RESULT: <N> passed, <M> failed`, a `tests/suite_limits.txt` entry (minimum = its
      final count; timeout 3x the slower of its local and first CI run times, at least 120 s; adjusted after the CI run if
      CI is slower), listed in `run_all_tests.ps1` as a Long suite (so
      `-Quick` skips it) and in `ci.yml` with a quoted step name and a `timeout-minutes` above the limit. Watch-fail in a
      scratch worktree after a green control, one mutation per run, each failing its own checks: (a) `ch5_reflection_trial.gd`'s
      hand-off target changed from `ch5_mirror_kaelen_confrontation.tscn` to `ch5_ending.tscn` → the order check fails at
      that leg; (b) `ch9_creator_trial.gd`'s `set_story_flag("ch9_truth_confessed", true)` removed → that leg's flag check
      fails; (c) the `_transition_to_next_scene()` call removed from `late_game_hazard_trial.gd` `_complete_trial()` → the
      Choir trial leg's cap fails naming `ch6_choir_combat_trial`; (d) `ch10_ending.gd`'s
      `set_story_flag("ng_plus_unlocked", true)` removed → AC-5 fails; (e) `ch8_revolt_intro.gd` pushes a ContextStack entry
      in `_ready` and never pops it → the R5 check fails at that leg; (f) driver mutation: the bot answers option 1 at the
      `ch4_null_court` main choice → the `ch4_choice_preserve_deleted` check fails. The green control runs 3 times in a
      row first. Full suite (all registered suites, this one included) with `GODOT` unset, every count equal to its minimum, no `RUNNER WARN`; the runner self-test green;
      evidence README in `production/qa/evidence/2026-10-playthrough/` mapping each AC to its file (leg table, findings,
      the suite log, mutation log, full-suite log); CHANGELOG `test:` entry; `git diff --check` clean.

---

## Implementation Notes

- Day 1: the leg table (AC-1) and the start state (AC-2), then Chapter 3 end to end (region gate, data stream, Kaelthas
  allied, the ch3_ending input wait). Day 2: Chapters 4–6 (the Choir trial). Day 3: Chapters 7–10, the ending, credits,
  registration, mutations, full suite.
- Build the driver on ch3_flash_runtime_test.gd's `_drive` (skip-and-answer, de-duplicated by the choice container) and
  chapter2_route_test.gd's `_wait_for(path, timeout)` (which also waits out `SceneTransitions.is_transitioning`). Reaching
  private DialogueManager members is an accepted isolation cost; name it in the suite header as those suites do.
- Make the leg list data: `[scene_path, kind ("story" / "region" / "trial" / "input_wait" / "ending"), key flags]`, so the
  table, the order check and the per-leg flag checks come from one list.
- For the Wastes region, the gate is placed only when `ch2_data_wraith_defeated` is set (part of the seeded state).
- If a real `ui_accept` event does not reach `Input.is_action_just_pressed` headlessly, record it and fall back to what the
  scene itself exposes (`_waiting_for_input = false`), named as a test-side work-around in findings.md.
- On failure print the leg, the scene, the elapsed real time, `DialogueManager` speaker/line and any open choice prompt —
  this is what a softlock report needs.
- Commit only with the user's OK: `test(playthrough): bot drives Chapter 3 to the credits` with `Task: Y1-P0-T14a`.

---

## Out of Scope

- Fixing any game-side defect the bot finds (logged per AC-6; fixes go to the softlock-fix reserve or their own story).
- Fighting the hazard trials (D2); other routes, the synthesis option, the bittersweet ending (D4).
- Chapters 1–2 and stitching New Game → credits, the Chapter 1 fight legs (T14b).
- Making the ending roll `CreditsScreen` (true ending is protected; logged as a finding).
- Watching the full credits scroll (skipped; "Credits skipped vs watched" — skipped is what this story checks).

---

## QA Test Cases

*Reviewed by qa-lead (QL-STORY-READY, 2026-10-25: GAPS → 10 gaps adopted by the user).*

- **C1 leg table (AC-1)** — open `leg_table.md` and the suite's leg list: same scenes, same order, from
  `ironhold_departure` to `main_menu.tscn`; expected 40 rows (6 Chapter 3 scenes + the Wastes region + 32 Chapter 4–10
  scenes + the main menu) — any other count is explained in the table.
- **C2 start state (AC-2)** — the suite's first checks: isolation guard passes; after seeding, `has_flag` is true for
  every seeded flag, `source_key_count` and `has_elara()` equal the literal; the seed comment names a commit.
- **C3 driver (AC-3)** — the log shows one "choice" line per prompt with option 0; `ch3_ending` passes via the input event
  (or the named fallback); the Wastes gate is entered; each trial logs "alive 3.0 s in attempt N" then
  `_complete_trial`; a forced cap (mutation c) prints leg index, scene, elapsed seconds, last speaker/line, open prompt,
  last choice; `Engine.time_scale` is 1 after the suite (pass and fail).
- **C4 per-leg (AC-4)** — for every leg: arrival scene equals the table; `DialogueManager.is_active` false and
  `ContextStack.top()` empty one frame after the transition; the leg's flags from the AC-4 table set;
  `source_key_count` = seed + 5 at the end; `user://save_slot_99.save` exists.
- **C5 ending and credits (AC-5)** — flags `ch10_complete`, `true_ending_seen`, `ng_plus_unlocked`;
  `ng_plus_available` true; "TRUE ENDING" in the ending text; main menu has a visible "NEW GAME+" button; credits open,
  close on `ui_cancel`, stack empty, tree unpaused.
- **C6 findings (AC-6)** — the `git diff --name-only` command over scripts / scenes / dialogue prints nothing; every
  findings.md entry has scene, symptom, reproduction and the bot's log line; "the ending never plays CreditsScreen" is
  entry 1.
- **C7 suite and records (AC-7)** — registration lines in `suite_limits.txt`, `run_all_tests.ps1` (Long) and `ci.yml`;
  control green 3x, mutations a–f each failing its own check; full suite green; evidence README maps every AC.

---

## Test Evidence

**Story Type**: Integration
**Required evidence**: `tests/integration/playthrough/full_playthrough_test.gd` (passing);
`production/qa/evidence/2026-10-playthrough/`: `leg_table.md`, `findings.md`, the suite log (one line per leg), the
mutation log, the full-suite log, and a README mapping each AC to its file.
**Run result**: N/A — test tooling; nothing in the game changes (the bot's per-leg log is the observation).

**Status**: [x] Created — committed in `b195732` and `2e6aba6`; evidence README maps each AC

---

## Dependencies

- Depends on: Y1-P0-T06 (done), Y1-P0-T12 (done); TD-010 (done: the runners' self-test).
- Unlocks: Y1-P0-T14b (Chapter 1 fight legs + New Game → credits in CI), and feeds T15 (the human playthrough) with the
  findings list.

---

## Completion Notes
**Completed**: 2026-10-25
**Criteria**: 7/7 passing. CI run [40192172143](https://github.com/Bhaskar-Bahukhandi/Ultimate-project/actions/runs/40192172143) on `b195732` (ubuntu-latest) is green: every step, the new "Playthrough bot" step
61 s against the 240 s limit (170 checks then), no runner `::warning::` annotation. The story-done fixes (`2e6aba6`, 172
checks) ran green 3x in a scratch worktree with mutations (a)–(j) each failing its own check; their first CI run is the
next push. Local runs 62–84 s.
**Commits**: `b195732` test(playthrough) the bot, registration, evidence; `2e6aba6` test(playthrough) story-done review
fixes (seed no longer holds `ch3_ironhold_departed` + a check that it is unset; trials complete only with the player
alive; `_finish` asserts the time scale).
**AC-6**: `git diff --name-only 74e40e8 2e6aba6 -- AethelgardPrototype/scripts AethelgardPrototype/scenes
AethelgardPrototype/dialogue` prints nothing (scoped to T14a's commits; S08 is changing game files in the same checkout,
uncommitted).
**Deviations** (advisory):
- NOT ASSESSED: GDD / ADR / TR-registry traceability (none exist for test tooling).
- AC-4: the suite also checks each `source_key_fragment_N` at the leg that grants it (code review, F-5), a superset of
  the story's flag table. Hand-off sampled at `transition_started` (amended at code review, recorded in AC-4).
- AC-7: watch-fail ran mutations (a)–(j), a superset of (a)–(f); (f) answers option 1 at every choice in leg 8, not
  only the main choice (same check fails). The full-suite log (`run_all.log`, 23/23, 1379 s) predates the code-review
  fixes (169 checks then); the CI run is the full-suite evidence for the committed bot.
- AC-1: the leg table is hand-written and matches `LEGS`; nothing parses it (its claim was reworded at close).
**Test Evidence**: Integration — `AethelgardPrototype/tests/integration/playthrough/full_playthrough_test.gd` (172
checks); `production/qa/evidence/2026-10-playthrough/`.
**Code Review**: Complete — /code-review CHANGES REQUIRED → R1–R8 + S1–S2 applied → APPROVED; at close QL-TEST-COVERAGE
ADEQUATE (Low gaps) and LP-CODE-REVIEW CONCERNS → findings 1 (vacuous leg-0 flag check) and 3 (trial completion with a
dead player) fixed in `2e6aba6`, the rest logged.
**Tech debt logged**: TD-023 (F-1 ending never rolls the credits; credits say "Version 1.0"), TD-024 (F-2 hazard trial
freed-marker robustness), TD-025 (F-3 Data Stream has no fail state — design question), TD-026 (bot follow-ups + F-5).
