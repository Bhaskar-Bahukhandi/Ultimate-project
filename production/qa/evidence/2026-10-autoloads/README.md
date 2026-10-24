# Y1-P0-T09 evidence: InteractionPrompt and ObjectPool autoloads removed

- **Story:** `production/epics/y1-p0-stabilize/story-t09-unused-autoloads.md`
- **Code:** `fix/phase0-playthrough-blockers` at `6f84335` plus the uncommitted T09 change (the commit hash is added
  to the CHANGELOG entry and the story's Completion Notes at commit / close time). Windows 11, Godot
  4.6.3.stable console (`Godot_v4.6.3-stable_win64_console.exe`), Windows PowerShell 5.1.

| Acceptance item | Result | Evidence |
|---|---|---|
| AC-1 autoload list 32 → 30, `project.godot` diff exactly two removed lines | Pass: whole-file `cmp` against HEAD minus the two lines identical; numstat `0 2` | `static_checks.log` |
| AC-2 four files deleted, no reference left, gameplay scripts unchanged | Pass: `--name-status` shows the 4 deletions and no `.tscn`; path and uid greps empty; scoped diff of `player_topdown.gd`, the opening hook and `scenes/` empty (added in /code-review at the end of the log) | `static_checks.log` |
| AC-3 load_all 206 → 204 | Pass: 206 before; 204 after, which the old minimum rejects (`RUNNER FAIL ... 204 check(s) ran, expected at least 206`); exit 0 with min 204 | `load_all_before.log`, `load_all_after_old_min.log`, `load_all_after.log` |
| AC-4 boot scan reaches the menu, no new errors, negative control | Pass: before and after both load `res://scenes/main_menu.tscn` (with `--verbose --fixed-fps 60 --quit-after 300`); the two removed scripts load before, not after; 0 error lines either side; the forbidden pattern matches the negative control (`Failed to instantiate an autoload, can't load from path: res://scripts/object_pool.gd.`) and not the after-boot | `boot_before.log`, `boot_after.log`, `boot_compare.log`, `boot_negative_control*.log` |
| AC-5 CI boot guard | Pass locally: the new grep matches both negative-control logs and neither after-boot log; the old grep (`SCRIPT ERROR\|Parse Error`) matched neither negative control; `ci.yml` parses. The first CI run after the push is still to be recorded | `ci_grep_check.log`, `ci_yaml_parse.log` |
| AC-6 main menu, live renderer, before and after | Pass: both captures live (forward_plus); pixel-identical, as expected (the tour loads the menu directly and neither autoload drew anything) | `main_menu_before.png`, `main_menu_after.png`, `report_*.md`, `capture_*.md`, `pixel_diff.log` |
| AC-7 full suite | Pass: 17/17, `All suites passed.`, 1133 s; counts equal `2026-10-ngplus/td002_run_all.log` except `LOADALL ok=204` (chapter1 `CH1 RESULT: 391 passed, 0 failed`, chapter2 `CH2 RESULT: 49 passed, 0 failed`) | `run_all.log` |

## Notes on the logs

- **Encoding noise:** logs written through PowerShell 5 redirection (`boot_after.log`, the negative-control logs)
  start with a UTF-8 BOM and show the em dash in `[BackgroundManager] Initialized — ...` as mangled characters; the
  before log is CRLF, others LF. None of this affects any pattern used; `boot_compare.log`'s full diff lists that one
  line as differing for that reason only.
- **`boot_negative_control_noimport.log` is a record, not a control:** a fresh worktree with no `.godot` import cache
  prints unrelated `class_name` parse errors and autoload failures. The real negative control,
  `boot_negative_control.log`, ran after `--import`, so only the deleted script's errors appear.
- **Shutdown-leak lines** (`Leaked instance: AudioStream...`, `ObjectDB instances leaked at exit`) appear in the before
  log and not in the verbose after log, from one run each; they are audio objects, not the removed nodes, and are not
  claimed as a benefit.
- **The CI-style boot logs** (no `--verbose`) print nothing from the splash or the menu, so they do not by themselves
  show the 300-frame window reaches the menu; the verbose logs do (frame 300 at a fixed 1/60 s is 5 s of game time,
  past the 3.0 s splash).
- The stale local `.godot/uid_cache.bin` still holds the deleted scripts' uids; the after-boot ran without re-import
  and was clean, and CI re-imports from a clean checkout.
