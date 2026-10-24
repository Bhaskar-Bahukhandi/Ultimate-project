# Y1-P0-T10 evidence: warn once per fallback, prune bound texts, release the cursor texture

- **Story:** `production/epics/y1-p0-stabilize/story-t10-log-spam-bound-texts-exit-leak.md`
- **Code:** `fix/phase0-playthrough-blockers` at `c01d80e` plus the uncommitted T10 change (the commit hash is added to
  the story's Completion Notes at close time). Windows 11, Godot 4.6.3.stable console
  (`Godot_v4.6.3-stable_win64_console.exe`), Windows PowerShell 5.1. The plan named `2026-11-exit-leak/`; the work
  was done in October.
- **Art caveat:** the production art behind most fallback slots was removed from this checkout in `abcf40c`
  (2026-10-04), so the warning counts hold for this art-less checkout only.

| Acceptance item | Result | Evidence |
|---|---|---|
| AC-1 warn once per message | Pass: `_warn_once()` keyed by message in `_missing_production_art_warned`; 20 sites and the four old helpers go through it; only :930 and the unknown-V3-visual warning (:1509, was :1513) stay bare; the only other changed lines are the helper body and the helpers' removed has/set guards | `static_checks.log` |
| AC-2 spam gone from the logs | Pass: for all 10 suites with AssetManager lines, lines after = distinct messages before, none repeated, distinct sets unchanged; full suite `WARNING: [AssetManager]` 463 → 102, all `WARNING` 494 → 131, distinct 26 → 26, (suite, message) sets equal (102 pairs). The other 2 fewer warnings are `ObjectDB instances leaked` lines (14 → 12), which vary run to run (TD-012) | `warning_counts.log`, `run_all.log` (after), `../2026-10-autoloads/run_all.log` (before) |
| AC-3 `bind_text` prunes | Pass: one pass builds `alive`, remembers a duplicate, then updates or appends; `_refresh_bound_texts()` unchanged; no new public API | `static_checks.log` |
| AC-4 prune test | Pass: `BOUNDTEXTS RESULT: 16 passed, 0 failed` (base_live 5); watch-fail on the pre-change code in a scratch worktree: `9 passed, 7 failed`, case 2 at 1006 entries instead of 6, cases 4 and 5 failing too (case 3's size check also fails there, only because case 2's dead entries are still in the list); registered: `.uid`, `suite_limits.txt` 16/120, `run_all_tests.ps1` (18 suites), `ci.yml` step; `test_layout_test` 6/6; `load_all` still 204 | `prune_watchfail.log`, `run_all.log`, `prune_after_review.log` (16/16 again after the code-review change to case 4) |
| AC-5 cursor released at exit | Pass: `game_manager.gd` diff is the new `_exit_tree()` only | `static_checks.log` |
| AC-6 clean exit log (real renderer) | Pass: `tests/run_exit_scan.ps1` before (pre-change scratch worktree) exits 1 on `LeakRidAlloc, LeakTexture, LeakRsNull` — the positive control; after exits 0 with `Loading resource: res://scenes/main_menu.tscn`, Godot exit 0, no ERROR line; full 59-shot tour after: `TOUR RESULT: 59 screenshots, 0 problems`, none of the three leak lines at exit | `exit_before.log`, `exit.log`, `tour_after.log`, `tour_after_report.md` |
| AC-7 cursor still shows | Pass: Bhaskar-Bahukhandi, manual, build `c01d80e` + the uncommitted T10 change, 2026-10-24: ran the game windowed, "the green crosshair cursor shows at the main menu". `_setup_custom_cursor()` unchanged (`static_checks.log`). Screenshots cannot show the OS cursor, so none is claimed | user's report (this row), `static_checks.log` |
| AC-8 suites and records | Pass: `run_all_tests.ps1` 18/18, `All suites passed.`, 1132 s; every existing suite's count equals the T09 run (`../2026-10-autoloads/run_all.log`); `git diff --check` clean; CHANGELOG entry; TD-012 logged | `run_all.log`, `static_checks.log` |

## Notes on the logs

- **Code review changes (2026-10-24, after the full run):** prune-suite case 4 re-measures `base_live` after its
  `await process_frame` (another autoload could bind or free a label in that frame), re-run 16/16 in
  `prune_after_review.log`; `run_exit_scan.ps1` now writes the renderer line into the log header, and `exit.log` was
  re-run with it (clean, 437 lines). `run_all.log` predates both and is otherwise unaffected (the suite count and
  checks are the same).
- **Renderer:** both exit scans ran on `Vulkan 1.4.329 - Forward+ - Using Device #0: NVIDIA - NVIDIA GeForce RTX 2050`
  (no driver override in `project.godot`; this machine did not use 4.6's documented D3D12 default). Leak lines are only
  comparable between runs on the same driver; the header of `exit.log` records it.
- **`tour_after.log` was re-saved from UTF-16 to UTF-8** (the tour's `Tee-Object` writes UTF-16 under Windows
  PowerShell 5.1), so plain `grep` sees its lines: `TOUR RESULT: 59 screenshots, 0 problems`, no leak line.

- **`exit.log` is longer than `exit_before.log`** (437 vs 249 lines) only because of the
  `Loading cache for shader …` lines: the main checkout has a shader cache from earlier runs and the fresh scratch
  worktree did not. Both load the same 14 resources, including `main_menu.tscn`. Both logs also have the Vulkan loader's
  `Registry lookup failed to get layer manifest files` warning, which is a driver message, not a project one.
- **Still at exit, not fixed here:** `WARNING: ObjectDB instances leaked at exit` and
  `ERROR: 1 resources still in use at exit` at the end of the tour and of some suites. That is an audio stream outliving
  the tree, tracked as TD-012; the plain boot to the menu (`exit.log`) does not show it.
- **CI cannot see renderer leaks** (it runs headless), so `run_exit_scan.ps1` is local only and not in `run_all_tests.ps1`
  or `ci.yml`.
- The watch-fail and the before scan ran in a scratch `git worktree` at `c01d80e`, with the new suite, its `.uid` and
  `suite_limits.txt` copied in. The worktree was removed afterwards; this checkout was never switched to old code.
