# Local CI run, 2026-11-22 (commit a7eb3b5)

GitHub Actions run 44939894456 for the push 3e0c554..a7eb3b5 did not start: "The job was not started because your
account is locked due to a billing issue." These are the same checks, run locally on Windows.

| check | result |
|---|---|
| Whitespace (`git diff --check 3e0c554 HEAD`) | clean |
| Commit-message hook self-test (`.githooks/test_commit_msg.sh`) | 21 passed, 0 failed |
| Commit messages 3e0c554..HEAD (7 commits) | all pass |
| Findings table + publish-script and findings unit tests | 265 rows reconcile; both unittest runs OK |
| Runner self-test (`tests/runner_selftest/test_runners.sh`) | 30 passed, 0 failed |
| Boot check (headless, 300 frames) | 0 error lines on Godot 4.6.3 and on 4.7.2 |
| All 28 suites (`tests/run_all_tests.ps1`), Godot 4.6.3 (CI's pinned `GODOT_VERSION`, forced with `GODOT=`) | All suites passed; playthrough bot 405/0 — `run_all_2026-11-22_a7eb3b5_godot4.6.3.log` |
| All 28 suites, Godot 4.7.2 (what the runner picks by default) | All suites passed; playthrough bot 405/0 — `run_all_2026-11-22_a7eb3b5_godot4.7.2.log` |

Note: `C:\Godot` holds both 4.6.3 and 4.7.2 (installed 2026-10-30). `tests/run_phase0_tests.ps1:49` and
`tools/export_windows.ps1:32` take the newest `Godot_v4*_console.exe` by name, so without `GODOT=` they run 4.7.2,
not the project's pinned 4.6.3 (`docs/engine-reference/godot/VERSION.md`, CI `GODOT_VERSION: 4.6.3`).

## Follow-up: scripts pinned to Godot 4.6.3 (2026-11-22, user decision "Pin the scripts")

`tools/pinned_godot.ps1` now names the pinned version once (`$PinnedGodotVersion = "4.6.3"`, kept equal to ci.yml's
`GODOT_VERSION` and VERSION.md); `tests/run_phase0_tests.ps1` (when `GODOT` is unset), `tests/run_exit_scan.ps1`,
`tests/run_screenshots.ps1` and `tools/export_windows.ps1` call `Get-PinnedGodot` instead of taking the newest exe.
A missing pinned exe throws and names what `C:\Godot` holds.

| check | result |
|---|---|
| `context_stack_test` through the runner, no `GODOT` | engine banner 4.6.3; 33 passed, 0 failed |
| helper with the pin set to 9.9.9 (watched failing) | throws: "Pinned Godot 9.9.9 not found ... (C:\Godot holds: ...4.6.3..., ...4.7.2...)" |
| `tools/export_windows.ps1` (release + smoke boot) | exported with 4.6.3; 0 export errors; RELEASE OK; exit 0 |
| `tests/runner_selftest/test_runner_ps.ps1` | 17 passed, 0 failed |
