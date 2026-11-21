# Story T15: Phase 0 exit — a human plays New Game to the credits on an exported build

> **Epic**: Y1-P0 Stabilize (Sprint 001)
> **Task ID**: Y1-P0-T15 (`production/plan/_source/Y1-P0.json#Y1-P0-T15`; sprint plan row Y1-P0-T15)
> **Status**: Ready
> **Layer**: Release (QA)
> **Type**: Integration
> **Estimate**: 3 days (day 1 Act 1, day 2 Chapter 3 to the credits, day 3 fixes and exit checks). Sprint plan slots:
> Days 0040, 0041, 0043 (27, 28, 30 Nov), with the softlock-fix reserve before them (user decision 2026-11-21:
> "As planned, 27-30 Nov"; the Chapters 4-10 human pass on Day 0035, 22 Nov, comes first).
> **Manifest Version**: N/A — `docs/architecture/control-manifest.md` does not exist
> **Last Updated**: 2026-11-22

## Context

**Source of record**: the plan entry (ROADMAP §5 Months 1–2 exit: "a human can play New Game → credits with no
softlock; one playthrough log"), sprint plan row Y1-P0-T15 ("Playthrough on an exported Windows build
(`tools/export_windows.ps1`); `production/qa/playtest-2026-11-phase0.md` with 0 open softlocks; smoke-check + gate-check
reports"). **Requirement**: N/A — no TR-ID. **ADR**: N/A — a playtest and fix story; no architectural decision.

**Who does what**: the user plays (keyboard on day 1, gamepad on day 2). Claude builds the exe, prepares the log
template, turns the notes into the report with `/playtest-report`, fixes softlocks with the user's approval, and runs the
exit checks.

**AGENTS.md protected areas**: the playthrough changes nothing. A softlock fix may touch story progression, save/load,
combat or NG+ code; each such fix needs the user's explicit approval before it is written, and is its own commit.

### Audit (2026-11-21, read-only; HEAD `4e2a90a`)

1. **Build**: `AethelgardPrototype/tools/export_windows.ps1` (run from `AethelgardPrototype/` with `powershell -File
   tools/export_windows.ps1`) exports the release preset to `exports/windows/Aethelgard.exe`, checks the export log, and
   boots the exe for 12 s with a real renderer (output `export.log`, `smoke.log`, `smoke_boot.png` beside the exe). Its
   PowerShell 5.1 exit code was fixed in TD-022 (done 2026-10-26).
2. **The bot** (`tests/integration/playthrough/full_playthrough_test.gd`, T14a/T14b) already plays New Game to the
   credits headless on one route (option 0 at every choice); it is the regression net for fixes. Its evidence lives in
   `production/qa/evidence/2026-11-playthrough/`.
3. **NG+ unlock**: `ch10_ending.gd:16-17` sets the story flag `ng_plus_unlocked` and the in-memory
   `ng_plus_available`, so NEW GAME+ shows on the menu straight after the ending. After a restart the menu decides
   from the save instead: `main_menu.gd:83-92` reads `ch10_complete` through `get_save_info`. "Credits" is two things:
   the ch10 TRUE ENDING card (`ch10_ending.gd:77`, ending with "// CREDITS COMPLETE", `:126`) and a separate
   CreditsScreen on the menu. This story means the ending card.
4. **Saves and backup**: saves are `user://save_slot_<n>.save` (0-2 manual, 99 autosave; `game_manager.gd:36-38,
   1511`), written to a temp file and renamed, so a force-kill almost never damages the newest save. A `.bak` copy is
   kept when the previous save was valid (`game_manager.gd:1989`). The player can only reach it when a slot is damaged:
   `load_game` falls back to it once (`:1582`), and the menu offers "Restore" on a "Damaged save (backup available)"
   slot (`main_menu.gd:278`). The built game cannot open its save folder; `user://` on Windows is under
   `%APPDATA%\Godot\app_userdata\` (the exact folder name is confirmed on day 1).
5. **Route asked for by the plan**: Chapter 1 fight Aldric and spare him; Chapter 2 truth with Seraphina and the medicine
   on time; Chapter 3 onward on a gamepad. Chapters 4-10 are legacy content: note tone and flow breaks for the Y2 cleanup,
   do not fix content.
6. **Version and suite**: `project.godot` says `config/version="0.1.0"`; the full suite runs with
   `powershell -File tests/run_phase0_tests.ps1` from `AethelgardPrototype/`.
7. **Report path**: `/playtest-report` writes to `production/qa/playtests/playtest-[date]-[tester].md` by default; this
   story overrides it to `production/qa/playtest-2026-11-phase0.md` (the plan's path). Session logs are gitignored, so
   issues are tracked on GitHub or with `/bug-report`, not in a session log.
8. **Evidence folder**: the plan names `production/qa/evidence/2026-11-playthrough/*.png`; that folder holds T14b's bot
   evidence and README, so human evidence goes in its `human/` subfolder with its own `human/README.md` (a deliberate
   change from the plan's top-level path).

---

## Acceptance Criteria

- [ ] AC-1 **Exported build.** `powershell -File tools/export_windows.ps1` exits 0 at a recorded commit with a clean
      `git status --porcelain`; `export.log` has no errors and `smoke.log` passes. The report records the commit, the
      build time, the Godot version and the SHA-256 of `exports/windows/Aethelgard.exe`, and a menu screenshot shows
      version 0.1.0, so the played exe is the release build, not the editor.
- [ ] AC-2 **Act 1 played (day 1, keyboard).** New Game through the prologue, Chapter 1 (fight Aldric, spare him) and
      Chapter 2 (truth, medicine on time) to the end of Act 1. Every softlock, stuck prompt, visual bug and pacing note
      is logged with a timestamp, the scene and a screenshot under `production/qa/evidence/2026-11-playthrough/human/`,
      with one screenshot at each chapter boundary. At the end of Act 1 the autosave `save_slot_99.save` is copied to
      `human/saves/act1/`, and the report quotes its route flags (Aldric spared, the truth choice, the medicine outcome).
- [ ] AC-3 **Chapter 3 to the credits (day 2, gamepad).** From the Act 1 save, on a gamepad, to the ch10 TRUE ENDING card.
      Legacy Chapters 4-10 tone and flow breaks are noted, not fixed. Screenshots: the TRUE ENDING card and the "//
      CREDITS COMPLETE" line; then, after quitting the exe completely and relaunching it, the main menu showing NEW
      GAME+. The day-2 save copy in `human/saves/day2/` shows `ch10_complete` and `ng_plus_unlocked` true. If the credits
      are not reached, the blocking point is recorded with its scene, the last save and the steps.
- [ ] AC-4 **Edge checks, each with an expected result.** A check that does not meet it goes into the issue table with a
      severity.
      - Quit to menu mid-chapter and continue: play resumes at the last autosave in the same chapter; the report says
        what progress was lost.
      - Alt-tab during dialogue: back on the same line, and it advances.
      - Unplug the gamepad during dialogue: the keyboard advances it while the pad is out; the pad advances it after it
        is plugged back in.
      - Force-kill (`taskkill /F /IM Aethelgard.exe`) straight after the save indicator: the newest save loads.
      - Backup, done deliberately on a copy of the save folder: truncate the newest save; the slot shows "Damaged save
        (backup available)", Restore works, and play continues.
- [ ] AC-5 **Report.** `/playtest-report` writes `production/qa/playtest-2026-11-phase0.md` (overriding its default path):
      build (AC-1), route and choices, input devices, play time per part, the AC-4 results, and an issue table `id | time
      | scene | type (softlock / stuck prompt / visual / pacing / legacy-tone) | severity | screenshot | tracking`. Each
      issue is tracked as a GitHub issue (filed only with the user's OK, as in S05) or a `/bug-report` file in
      `production/qa/bugs/`. `human/README.md` maps T15's ACs to this evidence.
- [ ] AC-6 **Softlocks fixed (day 3).** A softlock is any state that can only be left by quitting or reloading, even if a
      reload gets past it. This AC needs AC-3's credits evidence (or AC-3's recorded blocking point) first. Every softlock
      found is fixed at its root cause (no skip button), each with a regression check in the route tests or the bot whose
      log shows it failing before the fix and passing after; each fix touching a protected area is approved by the user
      first. The report ends with 0 open softlocks, or names each one left open and why.
- [ ] AC-7 **Exit checks.** `/smoke-check` passes; the full suite including the bot passes
      (`powershell -File tests/run_phase0_tests.ps1`, its log saved in `human/`); `/gate-check` against the Phase 0 exit
      criteria returns PASS or CONCERNS (as the plan asks) and is saved, naming each open softlock if any. A FAIL means
      this story is not Done. The Phase 0 boxes in ROADMAP §5 that are now done are ticked with the user's OK.

### Decisions (user)

- **Schedule (2026-11-21, "As planned, 27-30 Nov").**
- **Readiness gaps (2026-11-22, "Apply the QA-lead rewrites"):** QL-STORY-READY returned GAPS; applied: a pass
  condition per edge check, a softlock definition, AC-6 gated on AC-3's evidence with fail-then-pass logs, AC-7 needing
  PASS or CONCERNS, AC-3's ending card plus a relaunch, save copies, the exe hash, the report path override, tracking
  on GitHub or `/bug-report`, the Audit corrections (NEW GAME+, backup, credits), and `human/README.md`.

---

## Implementation Notes

- Build once at the start of day 1 and play that exe for days 1 and 2; rebuild only after day-3 fixes, and note it.
- Keep a plain-text notes file open while playing (`production/qa/evidence/2026-11-playthrough/human/notes.md`): time,
  scene, what happened. Claude turns it into the report; the user does not write the report.
- Screenshots: Windows Snipping Tool or the game's own capture; save them in the `human/` folder with a time prefix.
- Fixes follow the root-cause rule from the plan; the bot or a route test must reproduce the softlock first.
- If a fight is too hard to finish, lower the difficulty in the pause screen and say so in the report; that is a
  pacing note, not a softlock.

---

## Out of Scope

- Rewriting legacy Chapters 4-10 content (noted for the Y2 cleanup only).
- Wiring the difficulty profiles, the time model or the storyline axes (Year 1 Phase 1-2 stories).
- Non-softlock fixes (visual, pacing, tone): logged and tracked, fixed later unless the user picks one for the reserve.
- S16 (the Phase 0 review), which reads this story's report.

---

## QA Test Cases

*Written by Claude from the QL-STORY-READY findings of 2026-11-22 against the revised ACs (the gate withheld its own
block because its verdict was GAPS). Every case needs the exported build; none can run before day 1.*

- **C1 (AC-1)** Setup: a clean tree at the build commit. Verify: the script's exit code, `export.log`, `smoke.log`, the
  SHA-256 in the report, the menu screenshot with 0.1.0. Pass: exit 0, no ERROR lines, smoke PASS, hash recorded,
  version visible.
- **C2 (AC-2)** Setup: New Game on keyboard. Verify: chapter-boundary screenshots, the `act1/` save copy and the quoted
  flags. Pass: the copy shows Aldric spared, the truth choice and the medicine outcome as played.
- **C3 (AC-3)** Setup: load the Act 1 save on a gamepad. Verify: the ending-card and "CREDITS COMPLETE" screenshots, the
  relaunch screenshot with NEW GAME+, the `day2/` save copy. Pass: all three exist and the copy shows `ch10_complete`
  and `ng_plus_unlocked` true; or a recorded blocking point.
- **C4 (AC-4)** Setup: as each check says. Verify: each expected result. Pass: all five met, or each miss is in the
  issue table with a severity.
- **C5 (AC-5)** Verify: the report at the overridden path with every listed section, and each issue's tracking link
  resolves. Pass: no issue without a tracking entry.
- **C6 (AC-6)** Verify: for each softlock, the fix commit, the fail-then-pass log and, for protected areas, the user's
  recorded approval. Pass: 0 open, or each open one named with its reason.
- **C7 (AC-7)** Verify: the smoke-check report, the suite log in `human/`, the gate-check report. Pass: suite green,
  gate-check PASS or CONCERNS.

---

## Test Evidence

**Story Type**: Integration
**Required evidence**: `production/qa/playtest-2026-11-phase0.md` (the playtest doc), screenshots, save copies and
`README.md` in `production/qa/evidence/2026-11-playthrough/human/`, the fail-then-pass log per softlock fix, the suite
log, the `/smoke-check` and `/gate-check` reports.
**Run result**: the playthrough is the run; the retained screenshots are its observation.

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: T14b, S08, TD-022 and every other Must Have except S16 — all done (S06c closed 2026-11-21).
- Unlocks: Y1-P0-S16 (Review Phase 0 and plan the spine).

---

## Completion Notes

(empty until /story-done)
