# Story TD-022: The export smoke check reads the game's exit code under Windows PowerShell 5.1

> **Epic**: Y1-P0 Stabilize (Sprint 001)
> **Task ID**: TD-022 (`docs/tech-debt-register.md#TD-022`; raised at the T12 close, target "Sprint 001 (before T15)")
> **Status**: Complete
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

**Performance**: none — build tooling; no game cost. A normal run's time is unchanged (one extra property read); a
timed-out run adds `taskkill` and up to about 10 s of cleanup and log-merge retries.

**AGENTS.md protected areas**: none touched. No game code, scene, save format, test suite, `suite_limits.txt`, `ci.yml`,
export preset or `.uid` change. Files: `AethelgardPrototype/tools/export_windows.ps1`, `AethelgardPrototype/CHANGELOG.md`,
`docs/tech-debt-register.md` (TD-022 resolved, header counts), this story, its `production/sprint-status.yaml` entry
(status only, written by `/dev-story` and `/story-done`), a new evidence folder `production/qa/evidence/2026-10-export/`.
Production-art fallback: not affected (no asset change).

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
   tour that passes prints `FAILED: TOUR RESULT: … 0 problems (see …\report.md)`.
4. **Who runs it under 5.1.** The script's usage line (:22-23) and the "build the exe" step of the monthly plans
   (`production/plan/2026/2026-11.md`, six places) say `powershell -File …` (Windows PowerShell 5.1). T15 (a human
   plays the exported build) starts with that build.
5. **History.** The same `Start-Process` pattern has been there since the first export script (`e964cc5`, 2026-10-05),
   whose CHANGELOG entry reports a clean first result; a run under PowerShell 7 (installed at
   `C:\Program Files\PowerShell\7`) would explain it, unproven.
6. **Timeout path (inferred from the code; disproved at /dev-story, 2026-10-26).** On a timeout `Invoke-Built` calls
   `$p.Kill()` (:84), which stops only the process it started; under `-Tour` that is the console wrapper, so the real
   game was expected to keep running. *Correction (AC-5 d):* with the old `Kill()` the child `Aethelgard.exe` was still
   listed straight after the kill and gone by the 5 s check — the same as with `taskkill /F /T` (AC-5 c). The old code
   did not leave the game running in this run; `taskkill /F /T` is kept as the safer form (it does not depend on the
   child noticing that its wrapper died), as `tests/run_phase0_tests.ps1` does.
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

- [x] AC-1 **Exit code read.** In `Invoke-Built`, `$null = $p.Handle` runs on the line after `Start-Process` (before
      `WaitForExit`), with a one-line comment naming the Windows PowerShell 5.1 behaviour. A run that finished returns
      `Code = $p.ExitCode`, including a process that exits almost at once (AC-5 b: no throw, the real code). A run that
      timed out returns `Done = $false`, `Code = -1` (not the killed process's own code).
- [x] AC-2 **An unreadable code is its own failure, checked first.** In both branches the `$null` check comes first —
      before any `-ne 0` test and before the "never started" message — and adds
      `exit code unavailable (PowerShell could not read it)`; a `$null` code never reaches an `exit code $($r.Code)` string.
      Release: a real non-zero code adds `exit code <N>`. `-Tour` (*amended at code review*): a run passes only with code 0
      **and** a `TOUR RESULT` line reporting at least one screenshot and `0 problems`; otherwise it adds
      `<TOUR RESULT line> (see …\report.md)`, followed by `; exit code <N>` when the code is non-zero; a `$null` code adds
      the result line after the unavailable message when there is one; no `TOUR RESULT` line with a readable code keeps
      `the tour never started or never finished (exit code <N>)`.
- [x] AC-3 **Timeout stops the whole tree without crashing the script.** On a timeout: `taskkill.exe /F /T /PID $p.Id` runs
      with `$ErrorActionPreference = "Continue"` for that call only and its output discarded, and is judged by
      `$LASTEXITCODE` (reset to -1 first, so a `taskkill` that cannot start does not read an earlier command's 0); if
      non-zero and `$p.HasExited` is false, `$p.Kill()` runs inside `try/catch`. A process that exited on its own in that
      window is still a timeout (`Done = $false`), not a script error. `Invoke-Built` always returns one hashtable. After
      a timeout the isolated `user://` folder is removed with retries for up to 5 s (the game may hold it while it is torn
      down), as `tests/run_phase0_tests.ps1` does, and a folder still there after that is named in a warning. The game's
      stderr is merged into the log with the same retry (one try for a run that finished). *Amended at the fourth
      review:* a merge that still fails, or a non-empty log that cannot be read, is a **failure** naming the log ("its
      errors were not checked"; the unmerged stderr is kept in `<log>.err`), never just a warning — the game's errors in
      it would otherwise go unchecked — and neither ends the script with an exception. Proven by AC-5 (c), (d), (g), (h),
      (k), (l), (p), (q), (r), (s), (t) and (u).
- [x] AC-4 **Real builds pass under both shells**, run one after another (they share `exports/`), from
      `AethelgardPrototype/`: `powershell -File tools/export_windows.ps1` and `pwsh -File tools/export_windows.ps1` each
      end with `RELEASE OK: booted, ignored --debug-tour, exited cleanly` and exit 0; `powershell -File
      tools/export_windows.ps1 -Tour` and the same under `pwsh` each end with `TOUR BUILD OK`, a `TOUR RESULT` line with 0
      problems, and exit 0; `powershell -File tools/export_windows.ps1 -NoSmoke` ends with `BUILD OK` and exit 0. Each
      run's console output is kept as a log. `smoke_boot.png` from one release run shows the main menu (title and menu
      buttons visible in the last frame); the user signs it off in the evidence README.
- [x] AC-5 **Watched failing** — a scratch copy of the script, never the committed file; Windows PowerShell 5.1; before
      each run `Get-Process Aethelgard*` is empty (logged). "Contains" means the printed FAILED list contains the line;
      a mutated run may add others (for example "only 0 of 120 frames"):
      (a) release, the `$p.Handle` line removed → contains `exit code unavailable`;
      (b) release, `Invoke-Built` starting `cmd.exe /c exit 3` instead of the game → contains `exit code 3`, and no
      PowerShell error is printed;
      (c) `-Tour`, timeout cut from 900 s to 15 s, after the log shows the game started → contains the tour-timeout line;
      the wrapper and child PIDs are logged before the stop, and no `Aethelgard*` process (matched by name, which covers
      both PIDs) is running 5 s and 10 s after the stop;
      (d) as (c) with the old `$p.Kill()` in place of `taskkill` → records whether the child PID is still running at 5 s
      and 10 s (this proves or disproves audit fact 6; either result is recorded; if nothing is left, AC-3 stays as the
      safer form and fact 6 is corrected); afterwards any `Aethelgard*` process is stopped (`Stop-Process -Force`) and
      `Get-Process Aethelgard*` is empty before the next run;
      (e) `-Tour`, the `$p.Handle` line removed → contains `exit code unavailable`;
      (f) `-Tour`, `Invoke-Built` starting `cmd.exe /c "echo TOUR RESULT: 1 screenshots, 1 problems& exit 1"` → contains
      `TOUR RESULT: 1 screenshots, 1 problems (see …\report.md)` on one line;
      (g) the timeout branch forced on `cmd.exe /c exit 0` (`WaitForExit(2000)`, then `$done` set false, so the process
      has already exited when `Stop-Tree` runs) → the script finishes with a timeout failure and exit 1, no PowerShell
      exception, no stack trace.
      *Added at code review (2026-10-26), same rules:*
      (h) the timeout branch forced on a live `cmd.exe /c ping -n 30 127.0.0.1` with `taskkill` given a PID that does not
      exist → the `Kill()` fallback stops the process (`HasExited` true, logged), timeout failure, exit 1, no exception;
      (i) `-Tour`, the `$p.Handle` line removed and `Invoke-Built` starting `cmd.exe /c exit 0` (no `TOUR RESULT` line) →
      contains `exit code unavailable`, not `never started`;
      (j) `-Tour`, a stub printing `TOUR RESULT: 1 screenshots, 1 problems` and exiting **0** → contains that line with
      `(see …\report.md)` (the tour text is checked, not only the exit code);
      (k) `-Tour`, timeout cut to 15 s with no diagnostic pauses → timeout failure, exit 1, no exception, and no new
      `aeth_phase0_test_<guid>` folder left in `%TEMP%`;
      (l) as (h) but `taskkill.exe` renamed to a command that does not exist → `$LASTEXITCODE` stays -1 and `Kill()`
      stops the process (`HasExited` true), no exception.
      *Added at the second review:* (m) `-Tour`, `Invoke-Built` starting `cmd.exe /c exit 0` with the handle line kept (no
      `TOUR RESULT` line, readable code 0) → contains `the tour never started or never finished (exit code 0)`. In the
      mutations that run `Stop-Tree` ((c), (g), (h), (k), (l)) a logging line after the `taskkill` call prints its
      `$LASTEXITCODE` and `HasExited`.
      *Added at the third review:* (n) `-Tour`, a stub printing `TOUR RESULT: 0 screenshots, 0 problems` at exit 0 →
      contains that line with `(see …\report.md)`; (o) `-Tour`, a stub printing `TOUR RESULT: 5 screenshots, 0 problems`
      at exit 3 → contains that line followed by `; exit code 3`; (p) the timeout branch forced on
      `cmd.exe /c "echo TD022-STDERR-MARKER 1>&2& exit 0"` (a stub that writes to stderr, so the merge has to open the
      log), the log held open by another process for 2 s (confirmed locked before the merge) → no warning, no exception,
      and the harness finds the marker in `smoke.log` afterwards; (q) as (p) with the lock held for 8 s →
      contains `could not add the game's stderr` (a failure since the fourth review), no exception, the timeout failure
      still listed, and the marker absent from `smoke.log`; (r) the timeout branch forced, a file inside the isolated
      `user://` held open for 8 s → `could not remove the isolated user:// folder` warning, no exception (the holding
      process deletes the folder when it lets go).
      *Added at the fourth review — a run that otherwise passes:* (s) `-Tour`, a stub printing
      `TOUR RESULT: 5 screenshots, 0 problems` and the stderr marker, exiting 0, with its stderr file held open for 4 s
      right after it exits (the merge fails; the log itself still reads with a passing result) → contains
      `could not add the game's stderr`, exit 1; (t) a passing-tour stub with nothing on stderr and the log itself held
      open for 4 s → contains `could not read`, exit 1; (u) as (s) with the fail-closed lines reverted to the previous
      warn-only code → no failure, `TOUR BUILD OK`, exit 0 (the gap the fourth review found, shown).
      Each log starts with every edit in full, the SHA-256 of the script under test and of the mutant, and the process
      and `%TEMP%` folder counts before and after; the harness is kept in the evidence folder.
- [x] AC-6 **Records.** The usage comment says the script runs under Windows PowerShell 5.1 and PowerShell 7; TD-022 is
      `Resolved <close date>` in the register with the evidence path, header counts updated; a CHANGELOG `fix:` entry;
      `production/qa/evidence/2026-10-export/README.md` maps each AC to its log and records the `smoke_boot.png`
      sign-off; no file outside the list above changes; `git diff --check` clean.

---

## Implementation Notes

- The change is in `Invoke-Built`, a new script-level `Stop-Tree` helper and the two branches' checks (:117, :132 at
  audit time; about 30 lines in all after the code-review fixes). Keep the script's style (comment density,
  `$failures.Add(...)` messages).
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
- The Web export, export templates or presets. What the smoke check checks was out of scope as written; the code
  reviews changed it (the tour pass rule, an empty or unreadable log, a failed stderr merge — AC-2, AC-3, AC-5 (h)–(u)),
  each amendment chosen by the user at its review round (2026-10-26) and recorded in the Completion Notes.

---

## QA Test Cases

- **C1 (AC-1, AC-2)** — read the diff: the handle line sits right after `Start-Process`; in both branches the `$null`
  check is the first test; release passes on `Code -eq 0`, a tour on `Code -eq 0` and a `TOUR RESULT` line ending
  `, 0 problems`.
- **C2 (AC-3)** — read the diff: `taskkill` under `Continue` for that call only, output discarded, `$LASTEXITCODE`
  checked; `Kill()` only when `HasExited` is false, inside `try/catch`; one hashtable returned on every path.
- **C3 (AC-4)** — five logs (release and tour under 5.1 and 7, `-NoSmoke` under 5.1), each ending with its OK line and
  exit 0; `smoke_boot.png` signed off by the user.
- **C4 (AC-5 a, b, e, f)** — four logs whose FAILED lists contain, in turn: `exit code unavailable`, `exit code 3`,
  `exit code unavailable`, `TOUR RESULT: 1 screenshots, 1 problems (see …\report.md)`; no PowerShell error in (b).
- **C5 (AC-5 c, d)** — two logs with the empty pre-run `Get-Process`, the logged PIDs and the 5 s / 10 s checks; (d)
  followed by the cleanup and an empty `Get-Process`.
- **C6 (AC-5 g)** — a log ending with the timeout failure and exit 1, no exception text.
- **C6b (AC-5 h–m, added at code review)** — six logs: (h) and (l) `FALLBACK … HasExited=True`, with the logged
  `taskkill` exit code (non-zero, -1 for (l)); (i) `exit code unavailable` without `never started`; (j) the
  `TOUR RESULT … 1 problems (see …)` line at exit 0; (k) the `%TEMP%` folder count unchanged; (m) `never started or
  never finished (exit code 0)`.
- **C6c (AC-5 n–r, added at the third review)** — five logs: (n) the `0 screenshots` line at exit 0; (o) the result line
  followed by `; exit code 3`; (p) the lock confirmed, no warning and the stderr marker present in `smoke.log`; (q) the
  stderr-merge failure and the marker absent; (r) the user:// warning; none with PowerShell error text.
- **C6d (AC-5 s–u, added at the fourth review)** — (s) and (t): otherwise-passing tours that end `FAILED` with exit 1:
  (s) `could not add the game's stderr`, (t) `could not read`, neither ending `TOUR BUILD OK`; (u) the reverted code ends `TOUR BUILD OK`.
- **C7 (AC-6)** — `git diff --name-only` lists only the script, CHANGELOG, register, story, its sprint-status entry and
  evidence; register row resolved; `git diff --check` clean.

---

## Test Evidence

**Story Type**: Integration (build tooling)
**Required evidence**: `production/qa/evidence/2026-10-export/` — `README.md` (AC map), the four real-build logs
(AC-4) and the `-NoSmoke` log, a real `tour.log` with its line-ending record, `smoke_boot.png` with the user's
sign-off, the twenty-one mutation logs (AC-5 a–u) with the harness, and the PowerShell 5.1 / 7 repro output (audit facts
1 and 7). No automated suite (D2).
**Run result**: OBSERVED — the exported release build boots to the main menu (AETHELGARD / The Glitch Sovereign, NEW
GAME … QUIT, `v0.1.0`): `production/qa/evidence/2026-10-export/smoke_boot.png`, signed off by the user; the tour inside
the exported debug build: `TOUR RESULT: 68 screenshots, 0 problems` under PowerShell 5.1 and 7.

**Status**: [x] Created — committed in `c9f694f`; the README maps each AC to its log

---

## Dependencies

- Depends on: none open (Y1-P0-T12 done: it added the version print and raised TD-022).
- Unlocks: Y1-P0-T15 (the human playthrough builds the exe with this script); the monthly plans' "build the exe" step.

---

## Completion Notes
**Completed**: 2026-10-26
**Criteria**: 6/6 passing. Fix and evidence in `c9f694f` (`fix(tools)`); story `9e91825`. The committed
`tools/export_windows.ps1` has SHA-256 `a7266698…`, the hash every build and mutation log names. Release and `-Tour` exit 0
under Windows PowerShell 5.1 and PowerShell 7, `-NoSmoke` under 5.1; 21 mutations (a)–(u) caught; `smoke_boot.png` signed
off by the user (the final run's capture is byte-identical). The unfixed script's failure is kept
(`before_release_ps51.log`).
**Code review**: five `/code-review` rounds (engine specialist + QA each). Each round's fixes were chosen by the user:
round 1 [A] fix all (cleanup retry, `$LASTEXITCODE` reset, `0 problems` text check, mutations h–l, harness kept);
round 2 [A+] (the `PROBLEM` match, the result in the null-code message, a warning when cleanup gives up, mutation m,
`STOPTREE` logging, hashes in every log); round 3 [A] (`; exit code N`, at least one screenshot, the stderr merge retry,
mutations n–r); round 4 [A] (a failed merge or unreadable log **fails** the build — round 3's warn-only version let a
finished run pass unchecked, shown by (u) — mutations s–u); round 5 APPROVED WITH SUGGESTIONS. At close QL-TEST-COVERAGE
GAPS (no blocker) and LP-CODE-REVIEW CONCERNS (no blocker; no path where a bad build prints OK).
**Found and fixed beyond the plan**: the game log's CR LF kept by the `TOUR RESULT` / `PROBLEM` matches; an empty game log
crashed the script (predates TD-022); a timed-out run left its isolated `user://` in `%TEMP%`; a tour with a problem or no
screenshot passed at exit 0. Audit fact 6 (the old `Kill()` leaves the game running) was disproved and corrected.
**Deviations** (advisory):
- NOT ASSESSED: GDD / ADR / TR-registry traceability (none exist for build tooling).
- Scope: what the smoke check checks was listed out of scope and was changed by the review rounds (above); the AC text
  records each amendment. `production/sprints/sprint-001.md` was changed for decision D4 but is not in the story's file
  list; it gives the estimate as 1 day, the story and sprint-status 0.5.
- Evidence limits (QL-TEST-COVERAGE): only (a), (e) and (u) revert production logic; the other mutations are fault
  scenarios on the unchanged code. Nothing shows `taskkill /T` changing the outcome ((c) and (d) look the same); no
  non-zero exit code through the real console wrapper; PowerShell 7 ran the passing paths only; the merge's first try
  meeting the lock in (p) is inferred. Logged as TD-030, with a re-run protocol in the evidence README.
**Test Evidence**: Integration — no automated suite (D2); `production/qa/evidence/2026-10-export/` (README, 5 build logs,
21 mutation logs with the harness, the build-log wrapper, repro logs, `smoke_boot.png`).
**Tech debt logged**: TD-030 (export script follow-ups and evidence limits).
