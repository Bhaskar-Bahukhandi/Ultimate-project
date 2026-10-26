# Story TD-022: The export smoke check reads the game's exit code under Windows PowerShell 5.1

> **Epic**: Y1-P0 Stabilize (Sprint 001)
> **Task ID**: TD-022 (`docs/tech-debt-register.md#TD-022`; raised at the T12 close, target "Sprint 001 (before T15)")
> **Status**: Ready
> **Layer**: Foundation (build tooling)
> **Type**: Integration
> **Estimate**: 0.5 day (register effort: S)
> **Manifest Version**: N/A — `docs/architecture/control-manifest.md` does not exist
> **Last Updated**: 2026-10-26

## Context

**GDD**: none (build tooling). **Source of record**: TD-022 in `docs/tech-debt-register.md` — "`tools/export_windows.ps1`
smoke check reports `FAILED: exit code ` (empty) although the built game boots, records all 120 frames and exits cleanly
… cache `$p.Handle` right after starting" — seen at T12 close (`production/qa/evidence/2026-10-ui/export_run.log`).
**Requirement**: N/A — no TR-ID registered.

**ADR Governing Implementation**: N/A — a fix to one build script; no architectural decision is made.
**ADR Decision Summary**: N/A
**ADR Version**: N/A

**Engine**: Godot 4.6 (4.6.3 at `C:/Godot`) | **Risk**: LOW (no engine API; the script starts the exported game and
reads its exit code and console output). Engine note: a debug export has a console wrapper,
`Aethelgard.console.exe`, which starts the real `Aethelgard.exe` as its child; a release export has none.

**Control Manifest Rules**: NOT ASSESSED — no control manifest.

**Performance**: none — build tooling; no game cost. The script's own run time is unchanged (one extra property read;
`taskkill` only on a timeout).

**AGENTS.md protected areas**: none touched. No game code, scene, save format, test suite, `suite_limits.txt`, `ci.yml`,
export preset or `.uid` change. Files: `AethelgardPrototype/tools/export_windows.ps1`, `AethelgardPrototype/CHANGELOG.md`,
`docs/tech-debt-register.md` (TD-022 resolved, header counts), this story, a new evidence folder
`production/qa/evidence/2026-10-export/`. Production-art fallback: not affected (no asset change).

### Audit facts (2026-10-26, on HEAD `43449d2`)

1. **Cause, reproduced.** In Windows PowerShell 5.1, a `Start-Process -PassThru` object keeps the exit code only if its
   `Handle` was read while the process was alive. `Invoke-Built` (`tools/export_windows.ps1:81-91`) never reads it, so
   `$p.ExitCode` is `$null` after `WaitForExit`. A repro (`cmd.exe /c … exit N` through the same `Start-Process` call
   with output redirected) gives `ExitCode` null for N = 0 and N = 3 without the handle, and 0 / 3 with
   `$null = $p.Handle` read straight after the start. PowerShell 7.6 returns 0 / 3 either way.
2. **Effect on the release smoke check.** `elseif ($r.Code -ne 0)` (:132) is true for `$null`, so under 5.1 every
   release run fails with `exit code ` — a good build and a crashing build look the same. T12's run shows it: the game
   recorded 120 frames, exited, and the script printed `FAILED: - exit code `.
3. **Effect on `-Tour`.** `elseif ($r.Code -ne 0) { $failures.Add("$result …") }` (:117) is also true for `$null`, so a
   tour that passes prints `FAILED: TOUR RESULT: … passed`.
4. **Who runs it under 5.1.** The script's usage line (:22-23) and the "build the exe" step of the monthly plans
   (`production/plan/2026/2026-11.md`, six places) say `powershell -File …` (Windows PowerShell 5.1). T15 (a human
   plays the exported build) starts with that build.
5. **History.** The same `Start-Process` pattern has been there since the first export script (`e964cc5`, 2026-10-05),
   whose CHANGELOG entry reports a clean first result; a run under PowerShell 7 (installed at
   `C:\Program Files\PowerShell\7`) would explain it, unproven.
6. **Timeout path (inferred from the code, not yet run).** On a timeout `Invoke-Built` calls `$p.Kill()` (:84), which
   stops only the process it started. Under `-Tour` that is the console wrapper, so the real game can keep running.
   `tests/run_phase0_tests.ps1` stops a hung Godot with `taskkill /F /T` for the same reason.
7. **taskkill and Kill() failure paths (verified 2026-10-26 in 5.1 at readiness).** Under the script's
   `$ErrorActionPreference = "Stop"`, any stderr from `taskkill.exe` throws `NativeCommandError`, even with `2>$null`.
   Under `Continue`, `taskkill /F /T /PID` on a process that has already exited returns 128, and `$p.Kill()` on an exited
   process throws `MethodInvocationException`. A timeout can race with the game exiting on its own, so both paths are
   reachable. A process stopped by `taskkill /F` reports exit code 1, but the timeout path returns `Code = -1` by design.
8. **`-NoSmoke`** never calls `Invoke-Built` (:101-102), so it is not affected; it is run once as a regression check.

### Decisions (user, 2026-10-26)

- **D1 fix:** cache the handle (`$null = $p.Handle` straight after `Start-Process`), and make an exit code that is
  still unreadable its own failure, not an empty one. Not `System.Diagnostics.Process`, not "require PowerShell 7".
- **D2 proof:** real release and `-Tour` builds under PowerShell 5.1 and 7, plus mutations in a scratch copy of the
  script. No permanent self-test (it could only run on Windows, not in CI).
- **D3 timeout:** in scope — `taskkill /F /T` on a timeout, so the wrapper and the game both stop.
- **D4 sprint:** a Must Have in Sprint 001 before T15 (`production/sprint-status.yaml` entry and a `sprint-001.md`
  row).
- **QL-STORY-READY (GAPS, all 7 adopted by the user, 2026-10-26):** tour-branch watched-fail, the order of the null
  check, the taskkill / Kill() failure paths (fact 7), PID-based process checks, cleanup after mutation (d), `-NoSmoke`,
  and smaller wording (fast exit, `Code = -1` on timeout, who signs off `smoke_boot.png`, sequential runs).

---

## Acceptance Criteria

- [ ] AC-1 **Exit code read.** In `Invoke-Built`, `$null = $p.Handle` runs on the line after `Start-Process` (before
      `WaitForExit`), with a one-line comment naming the Windows PowerShell 5.1 behaviour. A run that finished returns
      `Code = $p.ExitCode`, including a process that exits almost at once (AC-5 b: no throw, the real code). A run that
      timed out returns `Done = $false`, `Code = -1` (not the killed process's own code).
- [ ] AC-2 **An unreadable code is its own failure, checked first.** In both branches the `$null` check comes first —
      before any `-ne 0` test and before the "never started" message — and adds
      `exit code unavailable (PowerShell could not read it)`; a `$null` code never reaches an `exit code $($r.Code)` string.
      Release: a real non-zero code adds `exit code <N>`. `-Tour`: a `TOUR RESULT` line with code 0 passes; a non-zero code
      adds `<TOUR RESULT line> (see …\report.md)`; no `TOUR RESULT` line with a readable code keeps
      `the tour never started or never finished (exit code <N>)`.
- [ ] AC-3 **Timeout stops the whole tree without crashing the script.** On a timeout: `taskkill.exe /F /T /PID $p.Id` runs
      with `$ErrorActionPreference = "Continue"` for that call only and its output discarded, and is judged by
      `$LASTEXITCODE`; if non-zero and `$p.HasExited` is false, `$p.Kill()` runs inside `try/catch`. A process that exited
      on its own in that window is still a timeout (`Done = $false`), not a script error. `Invoke-Built` always returns one
      hashtable. Proven by AC-5 (c), (d) and (g).
- [ ] AC-4 **Real builds pass under both shells**, run one after another (they share `exports/`), from
      `AethelgardPrototype/`: `powershell -File tools/export_windows.ps1` and `pwsh -File tools/export_windows.ps1` each
      end with `RELEASE OK: booted, ignored --debug-tour, exited cleanly` and exit 0; `powershell -File
      tools/export_windows.ps1 -Tour` and the same under `pwsh` each end with `TOUR BUILD OK`, a `TOUR RESULT` line with 0
      problems, and exit 0; `powershell -File tools/export_windows.ps1 -NoSmoke` ends with `BUILD OK` and exit 0. Each
      run's console output is kept as a log. `smoke_boot.png` from one release run shows the main menu (title and menu
      buttons visible in the last frame); the user signs it off in the evidence README.
- [ ] AC-5 **Watched failing** — a scratch copy of the script, never the committed file; Windows PowerShell 5.1; before
      each run `Get-Process Aethelgard*` is empty (logged). "Contains" means the printed FAILED list contains the line;
      a mutated run may add others (for example "only 0 of 120 frames"):
      (a) release, the `$p.Handle` line removed → contains `exit code unavailable`;
      (b) release, `Invoke-Built` starting `cmd.exe /c exit 3` instead of the game → contains `exit code 3`, and no
      PowerShell error is printed;
      (c) `-Tour`, timeout cut from 900 s to 15 s, after the log shows the game started → contains the tour-timeout line;
      the wrapper and child PIDs are logged before the timeout, and `Get-Process -Id` for both is empty 5 s and 10 s after
      the failure line;
      (d) as (c) with the old `$p.Kill()` in place of `taskkill` → records whether the child PID is still running at 5 s
      and 10 s (this proves or disproves audit fact 6; either result is recorded; if nothing is left, AC-3 stays as the
      safer form and fact 6 is corrected); afterwards `taskkill /F /T /IM Aethelgard*.exe` and an empty `Get-Process
      Aethelgard*` before the next run;
      (e) `-Tour`, the `$p.Handle` line removed → contains `exit code unavailable`;
      (f) `-Tour`, `Invoke-Built` starting `cmd.exe /c "echo TOUR RESULT: 1 screenshots, 1 problems & exit 1"` → contains
      `TOUR RESULT: 1 screenshots, 1 problems (see …\report.md)`;
      (g) the timeout branch forced on `cmd.exe /c exit 0` (timeout 0 s) → the script finishes with a timeout failure and
      exit 1, no PowerShell exception, no stack trace.
- [ ] AC-6 **Records.** The usage comment says the script runs under Windows PowerShell 5.1 and PowerShell 7; TD-022 is
      `Resolved <close date>` in the register with the evidence path, header counts updated; a CHANGELOG `fix:` entry;
      `production/qa/evidence/2026-10-export/README.md` maps each AC to its log and records the `smoke_boot.png`
      sign-off; no file outside the list above changes; `git diff --check` clean.

---

## Implementation Notes

- The change is about ten lines in `Invoke-Built` plus the two `Code` checks (:117, :132). Keep the script's style
  (comment density, `$failures.Add(...)` messages).
- `$p.Id` is the PID for `taskkill`. Read the handle before anything that could let the process exit first.
- Release builds take a few minutes to export (~100 MB); each tour run opens a game window for about two minutes. Run
  the real builds (AC-4) and the mutations one after another, not in parallel (they share `exports/`).
- Keep `taskkill` from leaking into `Invoke-Built`'s return value: assign or discard its output, so the function still
  returns a single hashtable (audit fact 7).
- Mutations: copy the script to the scratchpad, edit the copy, run it with `-File <copy>` but `$project` must still be
  `AethelgardPrototype/` — the script derives it from `$PSScriptRoot`, so put the copy in `AethelgardPrototype/tools/`
  under a git-ignored name, or pass the path. Delete the copy afterwards; `git status` must be clean of it.
- Commit only with the user's OK: `fix(tools): export smoke check reads the exit code under PowerShell 5.1` with
  `Task: TD-022`.

---

## Out of Scope

- Running the export in CI (the CI runner is Linux; no Windows export job).
- Changing the documented command from `powershell` to `pwsh` (D1).
- A permanent self-test for `Invoke-Built` (D2).
- The `ObjectDB instances leaked at exit` warning in the smoke log (TD-012).
- The Web export, export templates, presets, or what the smoke check checks.

---

## QA Test Cases

- **C1 (AC-1, AC-2)** — read the diff: the handle line sits right after `Start-Process`; in both branches the `$null`
  check is the first test; the pass conditions are `Code -eq 0`.
- **C2 (AC-3)** — read the diff: `taskkill` under `Continue` for that call only, output discarded, `$LASTEXITCODE`
  checked; `Kill()` only when `HasExited` is false, inside `try/catch`; one hashtable returned on every path.
- **C3 (AC-4)** — five logs (release and tour under 5.1 and 7, `-NoSmoke` under 5.1), each ending with its OK line and
  exit 0; `smoke_boot.png` signed off by the user.
- **C4 (AC-5 a, b, e, f)** — four logs whose FAILED lists contain, in turn: `exit code unavailable`, `exit code 3`,
  `exit code unavailable`, `TOUR RESULT: 1 screenshots, 1 problems (see …\report.md)`; no PowerShell error in (b).
- **C5 (AC-5 c, d)** — two logs with the empty pre-run `Get-Process`, the logged PIDs and the 5 s / 10 s checks; (d)
  followed by the cleanup and an empty `Get-Process`.
- **C6 (AC-5 g)** — a log ending with the timeout failure and exit 1, no exception text.
- **C7 (AC-6)** — `git diff --name-only` lists only the script, CHANGELOG, register, story and evidence; register row
  resolved; `git diff --check` clean.

---

## Test Evidence

**Story Type**: Integration (build tooling)
**Required evidence**: `production/qa/evidence/2026-10-export/` — `README.md` (AC map), the four real-build logs
(AC-4) and the `-NoSmoke` log, `smoke_boot.png` with the user's sign-off, the seven mutation logs (AC-5 a–g) and the
PowerShell 5.1 / 7 repro output (audit facts 1 and 7). No automated suite (D2).
**Run result**: to be recorded — the release smoke boot and the tour run the exported game with a real renderer.

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: none open (Y1-P0-T12 done: it added the version print and raised TD-022).
- Unlocks: Y1-P0-T15 (the human playthrough builds the exe with this script); the monthly plans' "build the exe" step.
