# Story TD-004: A runtime check that the Chapter 3 scenes' own flash lines run

> **Epic**: Y1-P0 Stabilize (Sprint 001)
> **Task ID**: Y1-P0-TD-004 (`docs/tech-debt-register.md#TD-004`; added to Sprint 001 on 2026-10-24, `production/sprints/sprint-001.md`)
> **Status**: Complete
> **Layer**: Feature
> **Type**: Integration
> **Estimate**: 1 day
> **Manifest Version**: N/A — `docs/architecture/control-manifest.md` does not exist
> **Last Updated**: 2026-10-24

## Context

**GDD**: none (test debt). **Source of record**: register item TD-004 ("The four Chapter 3 flash call sites (archive ×5,
wastes, Ironhold departure) are proven only by a static routing scan and a tour stop that calls the flash itself; nothing
runs the scenes' own flash lines. Add a runtime scene check"), raised at the close of Y1-P0-T08
(`production/epics/y1-p0-stabilize/story-t08-flashes-fragment4-nullpotion.md`, Follow-ups), and the sprint plan row
("The Chapter 3 scenes' own flash lines … run in a headless scene check; watched failing with one flash call removed;
`suite_limits.txt` updated"). **Requirement**: N/A — no TR-ID registered.

**ADR Governing Implementation**: N/A — a test plus a one-line test seam; no architectural decision.
**ADR Decision Summary**: N/A
**ADR Version**: N/A

**Engine**: Godot 4.6 (4.6.3 at `C:/Godot`) | **Risk**: HIGH (`docs/engine-reference/godot/VERSION.md`, 4.6 row)
**Engine Notes**: no post-cutoff API. A signal on an autoload (`SceneTransitions`) can be connected from a SceneTree test.
`change_scene_to_file` swaps the scene at the end of the frame, so the test waits a frame before reading `current_scene`.
The flash tween's first step runs before a per-frame poll can see the 0.8 peak (the probe saw 0.64–0.79), which is why the
test uses a signal rather than polling for the peak.

**Control Manifest Rules**: NOT ASSESSED — no control manifest.

**Performance**: one signal emit per flash call; no cost in play. Test run ~30 s for the three scenes headless.

**AGENTS.md protected areas**: none edited. The test *runs* real story beats that auto-save, set Chapter 3 story flags and
collect Source Keys 3 and 4, all inside the runner's isolated `user://`; no story, save, Source Key or flash code changes.
The only game-code change is the test seam in `SceneTransitions.flash()`. Files: `scripts/effects/scene_transition_manager.gd`
(the signal), `tests/integration/vfx/ch3_flash_runtime_test.gd` and its `.uid` (new), `tests/suite_limits.txt`,
`tests/run_all_tests.ps1`, `.github/workflows/ci.yml` (one step), `AethelgardPrototype/CHANGELOG.md`,
`docs/tech-debt-register.md` (TD-004 resolved at close), evidence, this story.

### Audit facts (2026-10-24; key claims re-checked in the main session)

- The seven calls all read `await SceneTransitions.flash(color, duration)` behind `if has_node("/root/SceneTransitions")`:
  - `scripts/chapter3/ch3_archive_depths.gd:338` `Color(0.3, 0.5, 0.8, 0.3), 0.5` in `_floor_1_original_design`;
    `:436` `Color(0.5, 0.3, 0.1, 0.3), 0.5` in `_floor_2_aethercorp`; `:505` `Color(0.8, 0.2, 0.2, 0.3), 0.5` in
    `_floor_3_sovereign`; `:588` `Color(0.2, 0.6, 1.0, 0.4), 0.8` and `:603` `Color(0.3, 0.7, 1.0, 0.5), 1.0` in
    `_floor_4_source_key`. Each floor awaits the next at its end (floor 1 is started at :141).
  - `scripts/chapter3/ch3_fractured_wastes.gd:564` `Color(0.2, 0.6, 1.0, 0.5), 0.8` in `_phase_fragment`, reached only when
    `ch3_server_room_unlocked` is set and `ch3_fragment_3_collected` is not (:59-60); otherwise `_phase_intro` sends the
    player to the region without a flash.
  - `scripts/chapter3/ch3_ironhold_departure.gd:95` `Color(0.2, 0.8, 0.2, 0.4), 0.5` in `_start_departure`.
- `SceneTransitions.flash()` (`scripts/effects/scene_transition_manager.gd:169`) sets `_flash_overlay.color`, sets
  `modulate.a = 0.8` and tweens it to 0 over `duration`; it has no signal. The script already declares
  `transition_started` / `transition_midpoint` / `transition_completed` (:16-18). `combat_flash()` goes through `flash()`;
  `boss_phase_flash()` does not (not used by these scenes).
- Today's coverage (`tests/integration/vfx/screen_flash_test.gd`, 107 checks): F1 a static routing scan of the call sites,
  F3 frozen neighbour lines, F2/F2b the Oakhaven flashes in the real scene; the Chapter 3 lines themselves never run.
- **Feasibility probe (scratch worktree, 2026-10-24):** from `GameManager.reset_game()` and `change_scene_to_file(<scene>)`,
  with a driver that re-requests `DialogueManager.skip_all()` whenever dialogue is active and answers every choice with
  option 0, all three real scenes reached every flash, in order, with the literal colours: archive 5 (6 choices answered:
  entry puzzle, Kaelthas — option 0 = ally, which avoids the 3-round simulated fight — consent clause, floor 1/2/3
  puzzles), wastes 1 (with `ch3_server_room_unlocked`), Ironhold 1 (no choices). Each scene then loads the next
  (`kaelthas_betrayal`, `data_stream`, `fractured_wastes_region`). Times: archive ~9.6 s, wastes ~5.9 s, Ironhold ~7.2 s.
  `skip_all()` does not persist: `show_choices` (`dialogue_manager.gd:406-407`) and `hide_dialogue` (:330) clear it.
  `DialogueManager.is_skip_requested()` (:346) and `_choice_container` (:53) exist. Each scene leaves through
  `SceneTransitions.change_scene()` (archive :641, wastes :128 / :591, Ironhold :126), which emits `transition_started`
  and sets `is_transitioning`; the archive's Kaelthas branch sets `kaelthas_allied = true` (:10, :211).
  Each Godot boot logs 6 `ERROR: Can't use get_node() with absolute paths` lines before any test code runs (not
  `SCRIPT ERROR`, so the runner does not fail on them).

### User decisions (2026-10-24)

1. **Test seam:** `SceneTransitions.flash()` emits `signal flash_started(color: Color, duration: float)` as its first
   statement; no behaviour change. The test asserts the ordered colour and duration literals per scene, plus one overlay
   check per scene so the visible path stays covered.
2. **A new suite**, `tests/integration/vfx/ch3_flash_runtime_test.gd`, running the three real scenes; `screen_flash_test.gd`
   stays as it is.
3. QL-STORY-READY gaps G1-G5 (2026-10-24) adopted: stop each case on the scene's own hand-off, deferred overlay read,
   tighter driver terms with choice counts, four more mutations, named isolation costs.
4. *(during /dev-story, 2026-10-24)* The deferred read saw alpha 0.71-0.75, not 0.8 (each scene calls `flash()` from a
   resumed timer await, so the tween's first step runs before a deferred read). The emit moves to just after the overlay
   is set, so the handler reads 0.8 synchronously; AC-1 and AC-5 amended.

---

## Acceptance Criteria

- [x] AC-1 **Test seam.** `scripts/effects/scene_transition_manager.gd` declares
      `signal flash_started(color: Color, duration: float)` (with a `##` doc comment saying it is a test seam) and emits it
      in `flash()` right after the overlay's colour and alpha are set, before the fade tween is created (amended
      2026-10-24, user decision 4). `git diff` of the file shows only those lines; `combat_flash()` therefore emits too;
      nothing else changes.
- [x] AC-2 **Archive.** From `GameManager.reset_game()`, loading the real `res://scenes/chapter3/archive_depths.tscn` with
      the dialogue driver (below) records exactly these five `flash_started` emissions, in this order, before the scene
      leaves: `(0.3, 0.5, 0.8, 0.3) 0.5`, `(0.5, 0.3, 0.1, 0.3) 0.5`, `(0.8, 0.2, 0.2, 0.3) 0.5`, `(0.2, 0.6, 1.0, 0.4) 0.8`,
      `(0.3, 0.7, 1.0, 0.5) 1.0` (colours compared with `is_equal_approx`, durations to 0.001).
- [x] AC-3 **Wastes.** With `ch3_server_room_unlocked` set and `ch3_fragment_3_collected` unset, the real
      `res://scenes/chapter3/fractured_wastes.tscn` records exactly one emission `(0.2, 0.6, 1.0, 0.5) 0.8`. Control: from
      `reset_game()` with no flags, the same scene records **zero** emissions before it leaves for the region (shows the
      gate, so the flag is what makes the flash reachable).
- [x] AC-4 **Ironhold.** From `reset_game()`, the real `res://scenes/chapter3/ironhold_departure.tscn` records exactly one
      emission `(0.2, 0.8, 0.2, 0.4) 0.5`.
- [x] AC-5 **Visible path.** For the first flash of each scene, the `flash_started` handler reads the overlay
      synchronously (the signal fires after `flash()` has set it and before the fade exists): `SceneTransitions/FlashOverlay`'s
      `color` is approximately the emitted colour, `modulate.a` is 0.8 (± 0.001), and its global rect covers the viewport.
- [x] AC-6 **Driver and isolation.**
      - **Driver:** skip is re-requested when `dm.is_active and not dm.is_skip_requested()`; a choice is answered with
        option 0 (`dm._on_choice_pressed(0)`, private — say so in the suite's header) only once `dm._choice_container` is
        valid. The driver records each choice prompt and asserts: archive exactly 6 choices and `kaelthas_allied == true`
        afterwards (option 0 is the ally branch); wastes and Ironhold 0 choices. The six archive choices are named in the
        suite's header (the Kaelthas betrayal path is not exercised).
      - **Stop rule:** each case runs until `SceneTransitions.transition_started` (the scene's own hand-off) or a 20 s
        real-time cap; hitting the cap fails the case with the emissions seen so far. The `flash_started` recorder is
        disconnected on `transition_started`, and the emission count is asserted only then, so "exactly" covers the whole
        scene (a stray extra flash fails; the wastes control's zero is meaningful).
      - **Between cases:** wait for `transition_completed` (or `is_transitioning == false`), change to an empty scene, call
        `DialogueManager.force_reset()` and `GameManager.reset_game()`, and only then start the next case.
      - **Isolation costs, named in the header:** freed scenes may log "Resumed function … after await, but class instance
        is gone" (not `SCRIPT ERROR`, so the runner does not fail on it, and the suite does not rely on the runner for
        it); auto-saves go to the isolated `aeth_phase0_test` `user://`; `reset_game()` clears flags, Source Keys and
        deferred save slots.
      - The suite checks the isolation guard first; the result line is `CH3 FLASH RESULT: N passed, F failed`.
- [x] AC-7 **Watch-fail by mutation** (scratch worktree with the new code, one mutation per run, log kept): (a) the archive
      floor-3 flash line commented out → AC-2 fails; (b) the wastes colour literal changed → AC-3 fails; (c) the
      `flash_started.emit(...)` line removed → every scene case fails (proves the seam is what the test sees, not a vacuous
      pass; run with the AC-5 handler attached so its failure is not mistaken for this one); (d) the Ironhold flash call
      removed → AC-4 fails; (e) `_flash_overlay.color = color` removed from `flash()` → only AC-5 fails; (f) the archive
      `:603` duration changed from 1.0 to 0.1 → AC-2 fails on duration; (g) the wastes gate forced open (`if true:` at
      `_ready`) → the AC-3 control fails; (h) two archive flash colours swapped → AC-2 fails on order. *(code review, 2026-10-24)* A control run of the
      unmutated worktree is green, each mutation's diff is logged, and (i) `modulate.a` set to 0.5 → only the AC-5 alpha
      checks fail; (j) the overlay shrunk before the emit → only the AC-5 covers-the-viewport checks fail.
- [x] AC-8 **Registration, suites and records.** `.uid` beside the suite; `tests/suite_limits.txt` line with its check
      count and a 120 s timeout (3× the measured Windows time, rounded up, at least 120); `run_all_tests.ps1` entry and
      header "all 19 suites"; a `ci.yml` step (double-quoted `name:` if it contains `: `); `test_layout_test` and
      `load_all` (204, the suite is under `tests/`) pass; `screen_flash_test.gd` unchanged at 107; full suite 19/19 with
      every other suite's count equal to `production/qa/evidence/2026-10-combat/run_all.log`; `git diff --check` clean;
      a CHANGELOG `test:` line; TD-004 marked Resolved in `docs/tech-debt-register.md` at close.

---

## Implementation Notes

- Order: the seam first (one signal, one emit), then the suite with the driver, then registration, the mutations, the full
  suite.
- Driver loop per scene: connect `SceneTransitions.flash_started` (append `[color, duration]`) and `transition_started`
  (stop flag), `change_scene_to_file`, then each frame: if a choice is open and `dm._choice_container` is valid, record it
  and call `dm._on_choice_pressed(0)`; elif `dm.is_active and not dm.is_skip_requested()`, `dm.skip_all()`; stop on
  `transition_started` or the 20 s cap. Then disconnect, assert, and reset as in AC-6 before the next scene (never rely on
  the beat's own chaining).
- Read the overlay node the way `screen_flash_test.gd` does (`_overlay()`).
- Mutations follow the T11 pattern (`scratchpad/t11_mutations.py`: one scratch worktree, copy the changed files in, one
  mutation per run, revert, log).
- Commit only with the user's OK: `test(vfx): run the Chapter 3 scenes' own flash lines headless` with
  `Task: Y1-P0-TD-004` in the body.

---

## Out of Scope

- Any change to the flash calls, their colours or durations, the chapter 3 beats, saves, story flags or Source Keys.
- TD-005 (overlapping flashes fight over the overlay) and the reduce-flash accessibility option (Y1-P1).
- The Kaelthas betrayal path, `boss_phase_flash()`, Oakhaven (already covered by `screen_flash_test.gd`).
- The 6 boot-time `get_node()` absolute-path errors (pre-existing; not caused by this suite).

---

## QA Test Cases

*Reviewed by qa-lead (QL-STORY-READY, 2026-10-24: GAPS → G1-G5 adopted by the user).*

- **C1 seam (AC-1)** — `git diff` of `scene_transition_manager.gd`: signal + emit only.
- **C2 archive (AC-2)** — five emissions, literal colours and durations, in order.
- **C3 wastes (AC-3)** — one emission with the flag; zero without it.
- **C4 Ironhold (AC-4)** — one emission.
- **C5 visible path (AC-5)** — overlay colour, alpha in (0, 0.8], covers the viewport, per scene.
- **C6 driver (AC-6)** — choice counts (archive 6, `kaelthas_allied`; others 0); stop on `transition_started`; reset between cases; cap; isolation guard; result line.
- **C7 mutations (AC-7)** — a green control run and ten mutations (a-j), each failing its case, diffs logged.
- **C8 registration and suites (AC-8)** — 19/19, counts unchanged elsewhere.

---

## Test Evidence

**Story Type**: Integration
**Required evidence**: `tests/integration/vfx/ch3_flash_runtime_test.gd` (passing); `production/qa/evidence/2026-10-ch3-flash-runtime/`:
the suite log, the mutation log, the full-suite log and a README mapping each AC to its file.
**Run result**: N/A for a screenshot — nothing new is drawn; the flashes are the T08 visuals already captured in
`production/qa/evidence/2026-10-flash/`, and AC-5 checks the overlay in the real scenes.

**Status**: [x] Created — production/qa/evidence/2026-10-ch3-flash-runtime/ (README.md maps every AC to its log)

---

## Dependencies

- Depends on: Y1-P0-T08 (done: the flashes route through `SceneTransitions.flash()`), Y1-P0-T02 (done), TD-007 (done:
  `suite_limits.txt`).
- Unlocks: closes TD-004 before Y1-P0-T15, as the register requires.

---

## Completion Notes
**Completed**: 2026-10-24
**Criteria**: 8/8 passing. CI run [40109275299](https://github.com/Bhaskar-Bahukhandi/Ultimate-project/actions/runs/40109275299) on `5dcd64b` (ubuntu-latest) is green: all 19 test steps,
"Chapter 3 flashes (…)" in 25 s (suite limit 120 s; local Windows run ~28 s). Step logs need a GitHub sign-in and were
not read, so the per-scene hand-off times on Linux are not known; the verdict rests on step conclusions.
**Commit**: `5dcd64b` (test(vfx): run the Chapter 3 scenes' own flash lines headless).
**Deviations** (advisory):
- NOT ASSESSED: GDD / ADR / TR-registry traceability (none exist for this test debt).
- AC-1 and AC-5 amended during /dev-story (decision 4): the emit moved to just after the overlay is set, so the handler
  reads alpha 0.8 exactly (a deferred read saw 0.71–0.75).
- Code review added 6 isolation (settle) checks (47 → 53) and mutations (i) alpha and (j) overlay rect; the local
  19-suite run used the 47-check version (the additions touched only this suite and a doc comment); CI ran the final 53.
**Test Evidence**: Integration — `tests/integration/vfx/ch3_flash_runtime_test.gd` (53 checks); a green control run and
10 mutations each failing exactly its checks (`watchfail_mutations.log`, diffs logged);
`production/qa/evidence/2026-10-ch3-flash-runtime/`.
**Code Review**: Complete — /code-review (godot-gdscript-specialist, godot-specialist, qa-tester) APPROVED WITH
SUGGESTIONS, all applied in `5dcd64b`; LP-CODE-REVIEW APPROVE (condition: CI green before merge — met, run 40109275299);
QL-TEST-COVERAGE GAPS (minor: CI not yet run at the time — now green; one-machine timing; records — updated here).
**Follow-up**: TD-016 — assert each case's hand-off destination (above all the wastes control), and add a public
DialogueManager "answer the open choice" API so the suite stops reaching private members.
