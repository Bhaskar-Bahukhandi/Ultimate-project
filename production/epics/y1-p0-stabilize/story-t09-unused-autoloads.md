# Story T09: Remove the unused InteractionPrompt and ObjectPool autoloads

> **Epic**: Y1-P0 Stabilize (Sprint 001)
> **Task ID**: Y1-P0-T09 (`production/plan/_source/Y1-P0.json#Y1-P0-T09`)
> **Status**: In Progress
> **Layer**: Foundation
> **Type**: Integration
> **Estimate**: 1 day
> **Manifest Version**: N/A — `docs/architecture/control-manifest.md` does not exist
> **Last Updated**: 2026-10-24

## Context

**GDD**: none (code cleanup). **Source of record**: the plan entry above ("CHANGELOG 2026-10-06 unused code;
ROADMAP R7 duplicated systems"), `AethelgardPrototype/CHANGELOG.md:225` ("Unused code (noted, not deleted): the
InteractionPrompt and ObjectPool autoloads") and `AethelgardPrototype/CODE_REVIEW_2026-10-04.md:466, :475`
("ObjectPool has zero callers but creates 39 nodes at boot"; "InteractionPrompt has zero callers but runs _process").
**Requirement**: N/A — no TR-ID registered.

**ADR Governing Implementation**: N/A — removes two unused autoloads; no architectural decision is made.
**ADR Decision Summary**: N/A
**ADR Version**: N/A

**Engine**: Godot 4.6 (4.6.3 at `C:/Godot`) | **Risk**: HIGH (`docs/engine-reference/godot/VERSION.md`, 4.6 row)
**Engine Notes**: no engine API is added. Edit `project.godot` on disk with the editor closed, so Godot does not
re-serialize the whole file into a noisy diff. `--quit-after N` counts frames, and headless frames are not tied to
real time; `--fixed-fps 60` makes each frame 1/60 s of game time (verify the flag works with `--headless` in 4.6.3
before relying on it).

**Control Manifest Rules**: NOT ASSESSED — no control manifest.

**Performance**: slightly less work at boot and per frame (39 pooled nodes and one always-processing CanvasLayer go
away); not measured, and not claimed as a gain.

**AGENTS.md protected areas**: none touched. Neither script is used by combat, collision, saves, story, Source Key,
NG+ or the world map (no callers; `ObjectPool`'s unused `enemy_projectile` factory is never called). No gameplay
script, scene or save format changes. Files: `AethelgardPrototype/project.godot` (two lines), the two scripts and
their `.uid` files (deleted), `tests/suite_limits.txt`, a comment in `tests/run_tests.sh` and one in
`tests/run_phase0_tests.ps1` (both quote the load_all count; the second added in /code-review), the CI boot step in
`.github/workflows/ci.yml`, `AethelgardPrototype/CHANGELOG.md`, evidence, this story.

### Audit facts (2026-10-24, read-only, re-checked in the main session and by QL-STORY-READY)

- `AethelgardPrototype/project.godot` `[autoload]` has exactly **32** entries, including
  `InteractionPrompt="*res://scripts/ui/interaction_prompt.gd"` (~:36) and `ObjectPool="*res://scripts/object_pool.gd"`
  (~:41). No test or code asserts the count, and no code depends on autoload order (every root lookup is by name;
  no `get_node_or_null` / `has_node` guard names either autoload).
- **No caller**: neither script declares a `class_name` (`extends CanvasLayer` / `extends Node`), so they are reachable
  only by autoload name. `git grep` finds no `ObjectPool.` / `InteractionPrompt.` / `/root/ObjectPool` /
  `/root/InteractionPrompt` use outside `object_pool.gd`'s own doc comment (:7-9), and none of their methods
  (`acquire`, `release`, `preload_pool`, `show_prompt`, ...) is called anywhere.
- **No scene or uid reference**: each script's uid appears only in its own `.uid` file among tracked files outside
  `production/` (`.godot/uid_cache.bin` also holds them; it is git-ignored and regenerated). No `.tscn`/`.tres`/`.cfg`
  names either path. `export_presets.cfg` uses `export_filter="all_resources"` and names neither file.
  `global_script_class_cache.cfg` has no entry for either (no `class_name`).
- **Name collision, not a reference**: the player's own `Label` named `"InteractionPrompt"` (created in
  `scripts/exploration/player_topdown.gd` ~:110-123, driven by its own nearest-target logic ~:219-243, and by
  `ch1_opening_crash_site_hook.gd` ~:455-458) is a different node; `chapter1_route_test.gd` ~:327, :378 checks it.
  It stays.
- **Boot side effects removed**: `interaction_prompt.gd._ready()` builds a hidden prompt panel on CanvasLayer 10 and
  runs `_process` every frame; `object_pool.gd._ready()` pre-creates 39 hidden nodes. Neither prints anything; no test
  asserts on them.
- **load_all**: `tests/integration/project/load_all_test.gd` walks `res://scripts` and `res://scenes` and loads every
  `.gd` and `.tscn` (206 today, `LOADALL ok=206 bad=0`); `.uid` files are not counted. Deleting the two scripts makes
  it 204, so `tests/suite_limits.txt` (`load_all_test.gd 206 120`, a minimum) becomes 204 in the same change, as its
  header requires; `tests/run_tests.sh` ~:112 quotes "LOADALL ok=206" in a comment.
- **Boot**: `run/main_scene` is `res://scenes/splash_screen.tscn`; `scripts/ui/splash_screen.gd` waits
  `SPLASH_DURATION := 3.0` s of accumulated delta, then `change_scene_to_file("res://scenes/main_menu.tscn")` (:81).
  Neither the splash nor `scripts/main_menu.gd` prints anything. CI's step "Boot check (fails on any script error)"
  (`.github/workflows/ci.yml` ~:86-92) runs `--headless --quit-after 120` and greps only `SCRIPT ERROR|Parse Error`:
  120 unthrottled headless frames likely end before the 3 s splash, so CI probably never boots into the menu, and a
  dangling autoload line (script deleted, line left) may print an error that this grep does not match (unverified).
- Several future plan months (2026-12, 2027-03 pooled VFX, 2028+ exercises) mention `object_pool.gd`.

### User decisions (2026-10-24)

1. **Delete** `scripts/object_pool.gd`, `scripts/ui/interaction_prompt.gd` and both `.uid` files (git history keeps
   them); no archive copy.
2. **Plan files are left as they are**; this story and the CHANGELOG entry say the code was removed in T09 and can be
   restored from git history (the commit hash goes in the CHANGELOG at commit time).
3. **CI boot guard**: widen the CI boot step so it reaches the menu (`--fixed-fps 60 --quit-after 300`) and also fails
   on the autoload-load error string observed in the negative control (AC-4), so a future dangling autoload line is
   caught.
4. QL-STORY-READY gaps (uid grep scope, boot scan rewrite, exact load_all and deletion checks, whole-file diff,
   before/after menu capture) adopted.

---

## Acceptance Criteria

- [ ] AC-1 **Autoload list.** `AethelgardPrototype/project.godot` `[autoload]` has **30** entries. Whole-file proof:
      `git show HEAD:AethelgardPrototype/project.godot | grep -v -E '^(InteractionPrompt|ObjectPool)='` equals the new
      file byte for byte, and `git diff --numstat -- AethelgardPrototype/project.godot` reads `0 2` (no
      re-serialization, no line-ending or trailing-newline change).
- [ ] AC-2 **Files gone, no reference left.** `git diff --name-status` for the change lists exactly four deletions
      (`scripts/object_pool.gd`, `scripts/object_pool.gd.uid`, `scripts/ui/interaction_prompt.gd`,
      `scripts/ui/interaction_prompt.gd.uid`) and no `.tscn`. Afterwards `git grep -n -i
      "object_pool\|ObjectPool\.\|/root/ObjectPool\|/root/InteractionPrompt\|interaction_prompt\.gd"` over
      `AethelgardPrototype/scripts`, `scenes`, `tests` and `project.godot` finds nothing, and
      `git grep -n -E 'b7a3nmdsg1ha0|cdjingjpdm244' -- ':!production/'` finds nothing. The player's own
      `"InteractionPrompt"` Label code (`player_topdown.gd`, `ch1_opening_crash_site_hook.gd`) is unchanged.
- [ ] AC-3 **load_all.** `load_all_test` prints exactly `LOADALL ok=204 bad=0` (read from the log after the deletion);
      `tests/suite_limits.txt` sets its `min_checks` to 204 and the `run_tests.sh` comment says 204.
- [ ] AC-4 **Boot scan.** `Godot --version` reports 4.6.3. Before the change and after it, the project's main scene
      is booted headless with the console executable, `--fixed-fps 60 --quit-after 300` (5 s of game time, past the
      3 s splash), `--verbose`, and `APPDATA` pointed at a fresh `aeth_phase0_test_*` dir; both logs are kept.
      - **Menu reached**: the after-log shows `res://scenes/main_menu.tscn` being loaded (a `--verbose` resource-load
        line; the exact string is read from the before-log). If `--verbose` names no scene load, a second scan with
        `--scene res://scenes/main_menu.tscn` stands in, and the evidence says so.
      - **No new errors**: the set of `ERROR`/`SCRIPT ERROR`/`Parse Error` lines in the after-log is a subset of the
        before-log's set, and the after-log has no line matching `SCRIPT ERROR|Parse Error|not declared in the current
        scope` or naming `ObjectPool` or `InteractionPrompt` (other than the player Label's, if any).
      - **Negative control** (scratch copy of the project, never this checkout): keep the `ObjectPool` autoload line
        but delete `object_pool.gd`; the same scan must print an error naming the missing autoload script, and that
        observed string is recorded in the evidence.
      - Shutdown warnings (`ObjectDB instances leaked`, `resources still in use at exit`) are not failures here.
- [ ] AC-5 **CI boot guard.** The CI step "Boot check (fails on any script error)" runs
      `--headless --fixed-fps 60 --quit-after 300` and fails on `SCRIPT ERROR|Parse Error` **or** the AC-4
      negative-control string; its step name stays double-quoted if it contains `: `; `ci.yml` still parses. Running
      the step's grep over the AC-4 negative-control log matches (it would fail the build), and over the after-log it
      does not. The first CI run after the push is recorded when it happens.
- [ ] AC-6 **Main menu.** A live-renderer capture of the main menu after the 30 autoloads boot
      (`tests/run_screenshots.ps1 -Only main_menu -Evidence autoloads`), retained in
      `production/qa/evidence/2026-10-autoloads/`, with a capture taken the same way **before** the change for
      comparison; the evidence note says both are live-renderer captures that load `main_menu.tscn` directly (the
      splash → menu path is AC-4).
- [ ] AC-7 **Suites.** Both route suites pass (`chapter1_route_test.gd`, which checks the player's own prompt Label,
      and `chapter2_route_test.gd`), and the full suite passes (`run_all_tests.ps1`, all 17, no `-Quick`) with every
      other suite's count equal to the last full run (`production/qa/evidence/2026-10-ngplus/td002_run_all.log`);
      `git diff --check` is clean; a new dated CHANGELOG entry records the removal (the 2026-10-06 line stays as
      history).

---

## Implementation Notes

- Order: take the before-scan, before-capture and baseline numbers first; then delete the two scripts and `.uid`
  files, remove the two `[autoload]` lines (editor closed), run `load_all` and read its new count, set
  `suite_limits.txt` and the `run_tests.sh` comment to that count; then the after-scan, the negative control, the CI
  edit and the suites.
- Boot scan: there is no runner for a plain boot; hand-roll it as `tests/run_phase0_tests.ps1` isolates `user://`
  (set `APPDATA`, run, restore, delete the dir). `--quit-after` exits 0 even on a script error, so the scan of the log
  is the check. Run the after-scan without a fresh `--import`, so a stale `.godot` cache is exercised too.
- Negative control: a scratch `git worktree` outside this checkout (`git -c core.longpaths=true worktree add
  --detach <scratch> HEAD`), delete `object_pool.gd` there only, import, scan, then remove the worktree.
- No test file is added: the proof is `load_all`, the boot scans, the CI guard, the route suites and the full suite
  (a test asserting two files are absent would only restate AC-2).
- Commit only with the user's OK: `refactor: drop unused InteractionPrompt and ObjectPool autoloads` with
  `Task: Y1-P0-T09` in the body.

---

## Out of Scope

- The player's own `"InteractionPrompt"` Label and its nearest-target logic (`player_topdown.gd`,
  `ch1_opening_crash_site_hook.gd`).
- Adding object pooling anywhere, or editing the plan months that mention `object_pool.gd` (user decision 2).
- Historical reports that mention the two autoloads (`CODE_REVIEW_2026-10-04.md`, `docs/archive/reports/*`,
  `docs/gameplay_audit/*`, `design_archive/*`) and the dated `production/project-stage-report.md` snapshot.
- Any other autoload, an "every autoload path resolves" test suite (the CI guard covers the dangling case), and any
  shutdown-leak cleanup (not measured here).

---

## QA Test Cases

*Reviewed by qa-lead (QL-STORY-READY, 2026-10-24: GAPS → adopted by the user).*

- **C1 autoload list (AC-1)** — the whole-file comparison against HEAD minus the two lines, `git diff --numstat`
  `0 2`, and a count of 30 `[autoload]` entries.
- **C2 no reference left (AC-2)** — the four-deletion `git diff --name-status`, the scoped `git grep`s (paths and uids,
  excluding `production/`); `git diff` of `player_topdown.gd` and the opening hook is empty.
- **C3 load_all (AC-3)** — before: `LOADALL ok=206 bad=0`; after: exactly `LOADALL ok=204 bad=0` through the runner with
  min 204 (the 206 → 204 drop is explained by the two deleted `.gd` files; `.uid` files are not counted).
- **C4 boot scans (AC-4)** — before/after logs; menu-reached line; after-errors ⊆ before-errors; no forbidden pattern;
  the negative control prints the recorded autoload error.
- **C5 CI guard (AC-5)** — the new grep matches the negative-control log and not the after-log; `ci.yml` parses.
- **C6 main menu (AC-6)** — before and after PNGs, both live-renderer, report with 0 problems.
- **C7 suites (AC-7)** — both route suites, then the full suite: 17/17, counts equal to the last full run except
  load_all (204).

---

## Test Evidence

**Story Type**: Integration
**Required evidence**: `production/qa/evidence/2026-10-autoloads/`: the `load_all` log before and after, the before
and after boot-scan logs, the negative-control log with its error string, the CI-grep check, the before and after
main-menu captures, the full-suite log and the `project.godot` diff. No new test file (see Implementation Notes).
**Run result**: required: the main menu after boot (AC-6).

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Y1-P0-T02 (done: the tests and `load_all` layout). TD-007 (done: the `suite_limits.txt` minimum that
  must change with the file count).
- Unlocks: nothing directly; fewer autoloads before Y1-P0-T15, and a CI boot check that reaches the menu.
