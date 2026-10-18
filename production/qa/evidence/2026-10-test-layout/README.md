# T02 test layout — evidence

- **Task:** Y1-P0-T02 · Move the tests into tests/unit and tests/integration
- **Commit:** `fcac1a9` on `fix/phase0-playthrough-blockers` (pushed 2026-10-18 as part of `4ad3fc0..6945234`)

| Acceptance item | Result | Evidence |
|---|---|---|
| 9/9 suites pass locally with unchanged counts | Pass: 10 suites incl. the new layout guard; every count equals the pre-move baseline | `run_all.log` (this folder), 665 s, exit 0 |
| CI green on the branch | Pass: all 19 steps, incl. "Test layout" and all 9 suites at their new paths, 10 min 46 s | https://github.com/Bhaskar-Bahukhandi/Ultimate-project/actions/runs/39119233225 |
| Layout guard committed | `tests/integration/meta/test_layout_test.gd` (6 checks); watched fail 5/6 on probe files before commit | CHANGELOG 2026-10-18 entry |
| Exports still exclude tests | Pass: `--export-pack` for "Windows Desktop" (451 files) and "Windows Debug Test" (453 files) contain **0** entries under `tests/` | Pack directory read from the PCK header (format 3). The only `tests/` strings in the packs are paths listed in `.godot/uid_cache.bin`, not test files. |
| Visual tour still finds its runner | Pass: `run_screenshots.ps1 -Only main_menu` → 1 screenshot, 0 problems | Live renderer, 1280×720, `run_artifacts/screenshots/20261018-161449/main_menu.png` (gitignored run artifact) |
| `run_tests.sh` with no argument | Resolves to `res://tests/integration/playthrough/phase0_blockers_test.gd`, which exists; CI's Phase 0 step passed using it | CI step 18 |

Known, not caused by T02: the tour's exit prints "1 RID allocations … leaked at exit" (Y1-P0-T10).
