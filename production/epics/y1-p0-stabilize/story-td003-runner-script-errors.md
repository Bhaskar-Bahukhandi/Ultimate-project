# Story TD-003: Fail a test suite when its output contains a SCRIPT ERROR or Parse Error

> **Epic**: Y1-P0 Stabilize (Sprint 001)
> **Task ID**: TD-003 (`docs/tech-debt-register.md#TD-003`; follow-up of Y1-P0-T08, due before Y1-P0-T15)
> **Status**: In Progress
> **Layer**: Foundation (test tooling)
> **Type**: Integration
> **Estimate**: 0.5 day (register effort: S)
> **Manifest Version**: N/A — `docs/architecture/control-manifest.md` does not exist
> **Last Updated**: 2026-10-20

## Context

**GDD**: none (test tooling). **Source of record**: TD-003 in `docs/tech-debt-register.md`, raised by both QA
gates on Y1-P0-T08 (`production/epics/y1-p0-stabilize/story-t08-flashes-fragment4-nullpotion.md`, Follow-ups).
**Requirement**: N/A — no TR-ID registered.

**ADR Governing Implementation**: N/A — a change to the test runners only; no architectural decision is made.
**ADR Decision Summary**: N/A
**ADR Version**: N/A

**Engine**: Godot 4.6 (4.6.3 at `C:/Godot`) | **Risk**: LOW for this story (no engine API is used; the runners
only read Godot's console output)
**Engine Notes**: Godot 4.6.3 prints a runtime error as `SCRIPT ERROR: <message>` followed by `   at: <func>
(<file>:<line>)` and a GDScript backtrace, then **continues the caller**: the failing function returns early and
the suite's own `quit(code)` still runs. A parse error in the `--script` file prints
`SCRIPT ERROR: Parse Error: ...` and Godot already exits 1.

**Control Manifest Rules**: NOT ASSESSED — no control manifest.

**Performance**: negligible; the runner keeps the suite's output in memory and greps it once at the end.

**AGENTS.md protected areas**: none touched. No game code, scene, save format, test suite or `.uid` changes.
Files: `AethelgardPrototype/tests/run_phase0_tests.ps1`, `AethelgardPrototype/tests/run_tests.sh`, a comment in
`AethelgardPrototype/tests/run_all_tests.ps1` and `.github/workflows/ci.yml`, evidence, the register, this story.

### Audit facts (2026-10-20, read-only)

- `run_phase0_tests.ps1` runs Godot with `APPDATA` pointed at a fresh `aeth_phase0_test_<guid>` folder and exits
  with Godot's exit code; nothing reads the output. `run_all_tests.ps1` runs the 16 suites through it and fails a
  suite only on a non-zero exit. `run_tests.sh` (CI, Linux) does the same with `XDG_DATA_HOME`.
- CI already greps for `SCRIPT ERROR|Parse Error` in the **boot** check (`ci.yml` "Boot check" step) but not in
  any test step; every test step calls `run_tests.sh`, so fixing that script fixes CI.
- `run_screenshots.ps1` already captures Godot output with `$ErrorActionPreference = "Continue"` and
  `2>&1 | ForEach-Object { "$_" }`; the new PowerShell code uses the same idiom.
- The last green full run (`production/qa/evidence/2026-10-flash/run_all.log`, 17bc358 code) contains no
  `SCRIPT ERROR` or `Parse Error` line, so no suite is expected to start failing. Its `ERROR:` lines (e.g.
  "Lambda capture at index 0 was freed") are engine errors, not script errors, and stay out of scope.
- **Watched failing (2026-10-20)**: a throwaway probe suite (session scratchpad, never committed) passes one check,
  then calls a missing method on a `Node`. Through **both** unchanged runners it prints
  `SCRIPT ERROR: Invalid call. Nonexistent function 'this_method_does_not_exist' in base 'Node'.`, then
  `TD003 PROBE RESULT: 1 passed, 0 failed`, and the runner exits **0**. The check after the call never ran.

---

## Acceptance Criteria

- [ ] AC-1 `run_phase0_tests.ps1` prints every Godot output line (stdout and stderr) to the console exactly once,
      in order, as it arrives. When that output contains a line matching `SCRIPT ERROR` or `Parse Error`
      (case-sensitive, as in ci.yml) and Godot exited 0, the runner exits **1**; when Godot exited non-zero, the
      runner exits with **Godot's code** whether or not a line matched. On a match it prints, after the output:
      `RUNNER FAIL <script>: <N> script error line(s)` (`<script>` as passed to `-Script`, `<N>` the number of
      matching lines), then each matching line and the line after it (the `at: <func> (<file>:<line>)` location),
      indented two spaces.
- [ ] AC-2 `run_tests.sh` does the same on Linux/CI (`2>&1 | tee` to a temp log, `PIPESTATUS`, grep), with the same
      exit codes and the same `RUNNER FAIL` text; when `GITHUB_ACTIONS=true` it also prints
      `::error::RUNNER FAIL <script>: <N> script error line(s)`, and not otherwise. Its temp log and isolated dir
      are removed on exit, on the failing path too.
- [ ] AC-3 Isolation is unchanged: `APPDATA` (Windows) / `XDG_DATA_HOME` (Linux) still point at a fresh
      `aeth_phase0_test_*` dir that is removed afterwards (after a passing and after a failing run), and `APPDATA`
      is restored; suites' isolation guard still passes.
- [ ] AC-4 Probes (R1–R8 below), old runner vs new, both runners. The old runners are taken from
      `git show HEAD:<path>` into the scratchpad before any change, so the "before" runs are reproducible.
      The runtime-error probe (R1) and the loaded-broken-helper probe (R2b) exit 0 before and 1 after, with the
      `RUNNER FAIL` summary; the top-level parse-error probe (R2) exits non-zero before and after; the clean probe
      (R3) and the lowercase probe (R8) exit 0 before and after; `quit(3)` probes (R7) exit 3 after. Logs kept in
      `production/qa/evidence/2026-10-runner/`. If Godot's real output for R2b does not contain `Parse Error`,
      that is recorded as a hole in the pattern, not hidden.
- [ ] AC-5 Full suite through `run_all_tests.ps1` (all 16 entries of its suite list, without `-Quick`) on the new
      runner: 16/16 pass with 0 `SCRIPT ERROR` / `Parse Error` lines; the log in the evidence folder records the
      commit and working-tree state it ran on. If any suite fails on a real pre-existing script error, the story
      stops and reports it; nothing is suppressed or allow-listed.
- [ ] AC-6 `git diff --check` clean; TD-003 marked Resolved in `docs/tech-debt-register.md`.
- [ ] AC-7 (DEFERRED to the next push, which needs the user's OK) The first CI run on the branch after this change
      is green on all 16 test steps; its run URL is recorded here. The Phase 0 step's outer
      `| tee phase0.log; exit "${PIPESTATUS[0]}"` still passes the runner's exit code through. A Linux-only script
      error caught there falls under the AC-5 rule (stop, report, no suppression).

---

## Implementation Notes

- PowerShell: `$ErrorActionPreference = "Continue"` around the Godot call (stderr arrives as error records under
  `2>&1`, which `Stop` would turn into a throw), pipe through `ForEach-Object { $l = "$_"; Write-Host $l; $l }`
  to stream and collect, take `$LASTEXITCODE`, then `Select-String -CaseSensitive -Context 0,1`.
- Bash: keep `set -euo pipefail`; wrap the pipeline in `set +e` / `set -e`, read `${PIPESTATUS[0]}`.
- Comments in `run_all_tests.ps1` and `ci.yml` say that a suite now also fails on script errors; no step changes.
- Commit only with the user's OK, Conventional Commits with `Task: TD-003` in the body.

---

## Out of Scope

- The register's alternative (each suite asserting a minimum number of executed checks): it also catches a
  function that returns early without an error; recorded as a possible follow-up, not done here.
- Engine `ERROR:` / `WARNING:` lines and `ObjectDB instances leaked` (not script errors).
- `run_screenshots.ps1` (visual tour, not a pass/fail suite).
- A permanent regression test for the runner itself (the probe stays throwaway, per the task); follow-up if wanted.

---

## QA Test Cases

*Reviewed by qa-lead (QL-STORY-READY, 2026-10-20: GAPS → R2b, R7, R8, the pinned exit codes and summary text,
AC-7 and the tightened R4/R6 adopted).*

- **R1 runtime error** — probe: one passing `_check`, then `Node.new().this_method_does_not_exist()` inside a test
  function, then a `_check(false)` that is never reached; `quit(0 if no failures else 1)`. Old runner: exit 0,
  "1 passed, 0 failed". New runner: exit 1, `RUNNER FAIL <probe path>: 1 script error line(s)`, then the
  SCRIPT ERROR and its `at:` line.
- **R2 top-level parse error** — probe with `var x := 1 +`: old and new runner exit non-zero (Godot's own exit 1);
  the new runner lists the `Parse Error` line.
- **R2b parse error in a loaded file** — probe that calls `load()` on a scratch helper with a parse error at
  runtime, then `quit(0)`. Old runner: exit 0. New runner: exit 1 with the `Parse Error` line in the summary.
- **R3 clean** — probe that prints a result and `quit(0)`: exit 0 on both runners, no summary. Its console line
  count through the new runner equals the old runner's (no doubled or lost lines), run directly and through a
  one-suite `run_all_tests.ps1`-style call.
- **R4 bash runner** — R1, R2, R2b, R3, R7, R8 through `run_tests.sh` under Git Bash (`GODOT` = the Windows console
  exe, `APPDATA` pointed at an isolated dir since `XDG_DATA_HOME` is Linux-only, so the script's own isolation line
  is not exercised here; AC-7 covers Linux). Same verdicts. R1 with `GITHUB_ACTIONS=true` prints the `::error::`
  line; without it, no `::error::` line. After a passing and a failing run, no `aeth_phase0_test_*` dir and no
  temp log from it remain in the temp dir.
- **R5 full suite** — `run_all_tests.ps1`: 16/16, `All suites passed.`, grep of the log finds no
  `SCRIPT ERROR|Parse Error`.
- **R6 isolation** — after a passing run and after the failing R1 run, no `aeth_phase0_test_*` dir from it is left
  in `%TEMP%`, and `APPDATA` in the calling shell is unchanged.
- **R7 exit code passthrough** — a clean probe that calls `quit(3)`: new runner exits 3, no summary. A probe with
  a SCRIPT ERROR then `quit(3)`: new runner exits 3 (not 1) and prints the summary.
- **R8 case sensitivity** — a clean probe that prints a line containing lowercase `script error` and `parse error`,
  then `quit(0)`: new runner exits 0, no summary.

---

## Test Evidence

**Story Type**: Integration (test tooling)
**Required evidence**: probe logs (old and new runner, PowerShell and bash) and the full-suite log in
`production/qa/evidence/2026-10-runner/`.
**Run result**: N/A — nothing player-observable changes.

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Y1-P0-T08 (done; raised TD-003).
- Unlocks: Y1-P0-T15 (Phase 0 exit playthrough relies on the suite verdicts).
