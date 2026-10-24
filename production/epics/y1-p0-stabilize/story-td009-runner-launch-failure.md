# Story TD-009: Fail a suite whose Godot never started, and list script errors from a log with a NUL byte

> **Epic**: Y1-P0 Stabilize (Sprint 001)
> **Task ID**: TD-009 (`docs/tech-debt-register.md#TD-009`; follow-ups of TD-003 / TD-007, raised in the TD-003
> close-out review and confirmed in the TD-007 session)
> **Status**: In Progress
> **Layer**: Foundation (test tooling)
> **Type**: Integration
> **Estimate**: 0.5 day (register effort: S)
> **Manifest Version**: N/A — `docs/architecture/control-manifest.md` does not exist
> **Last Updated**: 2026-10-21

## Context

**GDD**: none (test tooling). **Source of record**: TD-009 in `docs/tech-debt-register.md` (added with this
story). The three defects were found after TD-007 (`249cba4`) was reviewed; the user chose to commit TD-007
without them.
**Requirement**: N/A — no TR-ID registered.

**ADR Governing Implementation**: N/A — a change to the test runners and one register row; no architectural
decision is made.
**ADR Decision Summary**: N/A
**ADR Version**: N/A

**Engine**: Godot 4.6 (4.6.3 at `C:/Godot`) | **Risk**: LOW (no engine API; the runners start Godot and read its
console output)

**Control Manifest Rules**: NOT ASSESSED — no control manifest.

**AGENTS.md protected areas**: none touched. No game code, scene, save format, test suite, `suite_limits.txt`,
`ci.yml` or `.uid` change. Files: `AethelgardPrototype/tests/run_phase0_tests.ps1`,
`AethelgardPrototype/tests/run_tests.sh`, `docs/tech-debt-register.md` (TD-007 wording, new TD-009 row, header
counts), this story, a new evidence folder `production/qa/evidence/2026-10-runner-followups/`.

### Audit facts (2026-10-21, on HEAD `249cba4`)

1. **PowerShell runner, Godot fails to launch.** `& $godot.FullName ...` on a missing exe, under
   `$ErrorActionPreference = "Continue"`, writes a non-terminating error and runs nothing: `$LASTEXITCODE` stays
   unset, so `$code` is `$null`. The last line, `elseif ($failed -and $code -eq 0)`, does not promote `$null`, and
   `exit $null` exits 0. TD-007's `RUNNER FAIL <script>: no result line` is printed and the suite still passes.
   Confirmed by running the runner's statements against a missing exe (TD-007 session `item1_probe.ps1`: code
   null, process exit 0).
   **Corrected in /dev-story (2026-10-21, debug copies of the HEAD runner):** inside the runner's `try` the failed
   call is a *statement-terminating* error (`CommandNotFoundException` for a missing exe,
   `ApplicationFailedException` for a file that is not a program): the rest of the `try` is skipped, `finally`
   runs, and the script carries on after it. So `$code = $LASTEXITCODE` never runs, and resetting
   `$LASTEXITCODE` before the call could not change anything. `$code` is unset in a fresh process (exit 0); when
   the runner is called in-process (`& run_phase0_tests.ps1`, as the TD-007 probe matrix does), PowerShell's
   dynamic scoping makes it read the **caller's** `$code` (probe: caller `$code = 7`, stale `$LASTEXITCODE` 3 →
   runner exit 7). A `Stop` restore placed after the call inside the `try` would be skipped the same way.
2. **bash runner, NUL byte in the log.** In the TD-003 script-error block, `grep -cE` counts correctly, but
   `grep -E -A1 ... | grep -v '^--$'` prints `Binary file ... matches` instead of the matching lines: the first
   grep treats the log as binary, and the second grep treats its own input as binary too (checked with GNU grep
   3.0 under Git Bash: fixing only the first grep still prints `Binary file (standard input) matches`). The
   verdict and exit code are right; only the listing is lost. TD-007 already uses `LC_ALL=C grep -a` for the
   result-line scan.
3. **Register wording.** TD-007's description says CI "stops only at the job timeout". The long steps have their
   own `timeout-minutes` (before TD-007: ch1, ch2 and act1_quests 15 min, phase0 30 min; TD-007 raised ch1 to 30);
   only the short suites wait for the 45-minute job limit.

### Decision: `--no-group-separator`

**Not used; keep `grep -v '^--$'`.** `--no-group-separator` is a GNU grep option, and `run_tests.sh` is the
"Linux/macOS" runner; BSD grep on macOS is not available here to check, so the portable filter stays. Its only
side effect is display-only: a log line that is exactly `--` right after a match is dropped from the listing (the
count, and so the verdict, is unaffected). The filter grep gets `LC_ALL=C ... -a` too (fact 2).

---

## Acceptance Criteria

- [ ] AC-1 **Launch failure (PowerShell).** *(Revised in /dev-story with the user, 2026-10-21, after the
      corrected fact 1; the `$global:LASTEXITCODE = $null` reset of the first draft was dropped as unobservable.)*
      `run_phase0_tests.ps1` sets `$code = $null` and `$lines = $null` before the `try` (both assignments are skipped
      by a launch failure; `$lines` added in /code-review, probe L3d), and sets `$ErrorActionPreference = "Stop"`
      after the `finally` (so it also applies when a launch failure skips the rest of the `try`). That `Stop` is
      new behaviour, not a restore: at HEAD the script stayed `Continue` after the call, so the scans after the
      `try` now run under `Stop`. A `$null` code with no timeout means Godot never ran: the runner prints
      `RUNNER FAIL <script>: Godot did not start` and exits 1. On that path the minimum-checks message is not
      printed (the launch failure is the reason, not the count, as for a timeout). A suite that starts is
      unaffected. The `Stop` line has no observable effect on any probe, so it is **inspection-only**:
      `grep -n ErrorActionPreference` in the evidence shows it after the `finally`, and AC-4/AC-5 show the code
      after the `try` still reaches `exit` with the same codes.
- [ ] AC-2 **Watched failing first.** Scratch copies of the HEAD runner and of the NEW runner (project path pinned,
      `suite_limits.txt` copied beside each) with only the exe line pointed at a missing file. The evidence holds
      the `diff` of each copy against its source (only those lines differ), the SHA-256 of the OLD and NEW runners
      and the PowerShell version.
      - L1 (default phase0 suite, min 81): OLD exit **0** with `no result line`; NEW exit **1** with exactly one
        `RUNNER FAIL` line, `Godot did not start`, and no `no result line`.
      - L2 (a clean probe, no minimum): OLD exit 0, no `RUNNER FAIL`; NEW exit 1, `Godot did not start`.
      - L3 / L3b, in-process after a native command that exited 0 / 3 (`cmd /c exit 0|3`): OLD exits 0 in both
        (the stale code is never read, fact 1); NEW exits 1 with `Godot did not start` in both.
      - L3c, in-process from a caller that has `$code = 7` (and a stale exit code 3): OLD exits **7** with no
        launch message; NEW exits 1 with `Godot did not start`.
      - L4 (bash, no change expected): `GODOT=/no/such/godot` exits 127, recorded.
      - L5: the exe line pointed at an existing text file named `.exe` (exists but cannot run): OLD and NEW
        recorded whichever way it goes; NEW must not exit 0.
      - L3d, in-process from a caller whose `$lines` holds a `SCRIPT ERROR` line: NEW prints exactly one
        `RUNNER FAIL` line (`Godot did not start`), exit 1; OLD lists the caller's line as a script error, exit 0.
      - L6: missing exe with `-TimeoutSec 1 -MinChecks 2`: NEW exactly `Godot did not start`, no timeout message,
        exit 1.
      - Mutant MU1: NEW without the `$code = $null` line: L3c exits 7 again. Mutant MU4: NEW without the
        `$lines = $null` line: L3d lists the caller's line again. Each line is load-bearing.
- [ ] AC-3 **NUL byte (bash).** All three greps of the TD-003 block (the count, the listing, the `^--$` filter) use
      `LC_ALL=C grep -a`, and the listing's `sed` runs under `LC_ALL=C` (added in /code-review: BSD sed may
      reject a non-UTF-8 byte under a UTF-8 locale; unverified here, GNU sed handles N2 either way). A stub Godot prints a `SCRIPT ERROR` line, a following line, a `Parse Error` line and a
      result line, and exits 0. Outputs are kept as `od -c` dumps (a raw NUL breaks diff and whitespace
      tooling); OLD's random log path in its `Binary file` line is normalized to `<log>`. The evidence records
      `grep --version` and the locale.
      - N0 (no odd byte): OLD and NEW byte-identical.
      - N1 (NUL on the line after the `SCRIPT ERROR` match): OLD lists neither matching line; NEW lists all four
        listing lines, equal to a golden dump; same count (2) and exit (1) on both.
      - N3 (NUL only on a line far from any match): isolates the first grep: OLD lists neither line, NEW lists them.
      - N2 (`0xFF` instead of NUL): run under the session's UTF-8 locale and under `LC_ALL=C`, OLD vs NEW recorded.
      - Mutants MU2 (`-a` only on the first listing grep) and MU3 (only on the filter grep): N1 still lists neither
        line, so each `-a` is load-bearing. The count's `-a` is not shown to be needed (GNU `grep -c` counts a
        binary file correctly); it is there so the count and listing read the log the same way, and is stated so.
      - DEFERRED: Linux, grep ≥ 3.5, where the `Binary file` notice goes to stderr; checked on the first CI run
        after the next push, as TD-007 AC-9.
        - **CI result (2026-10-24):** run [#29](https://github.com/Bhaskar-Bahukhandi/Ultimate-project/actions/runs/40049178997) on `336f7fb` is green on all 16 test steps, so the
          changed `run_tests.sh` runs on Linux without breaking a green suite. **Still unverified:** the NUL-byte
          listing on Linux grep ≥ 3.5. A green run never has a script error to list, the step logs (grep version,
          output) need a GitHub sign-in, and macOS (BSD grep/sed) is not in CI. Checking it needs a deliberately
          failing probe with a NUL byte run on Linux, or the logs read by someone signed in.
- [ ] AC-4 **No other change.** The TD-007 probe matrices (`matrix_ps.ps1`, `matrix_sh.sh`, `matrix_sh_extra.sh`,
      copied from the TD-007 session and pinned by SHA-256 in the evidence) run again with OLD = HEAD `249cba4`
      and NEW = the working tree. Every OLD/NEW pair: the same exit code, and stdout and stderr byte-identical
      once the timing fields (`elapsed=`, and the scratch paths in the harness header lines) are normalized as
      described in the evidence README. The only pairs allowed to differ are L1–L6, MU1–MU4 and N1–N3; any other
      difference fails. The NEW exit codes equal the NEW column of `2026-10-runner-watchdog/` (H1/H2 are 124 on
      both sides now: HEAD has the watchdog). S3: one fast real suite (`test_layout_test.gd`) through
      `run_tests.sh` under Git Bash: exit 0, its result line equal to `2026-10-runner-watchdog/run_all.log`.
- [ ] AC-5 **Full suite.** `powershell -NoProfile -File AethelgardPrototype/tests/run_all_tests.ps1` (all 16, no
      `-Quick`) on the new runners: 16/16, `All suites passed.`, no `RUNNER FAIL` line, per-suite counts equal to
      `production/qa/evidence/2026-10-runner-watchdog/run_all.log`; the log names the commit and working-tree
      state it ran on.
- [ ] AC-6 **Register.** TD-007's description says the long CI steps stop at their own `timeout-minutes` and only
      the short suites wait for the 45-minute job limit, quoting the values `grep -n timeout-minutes
      .github/workflows/ci.yml` shows (kept in the evidence: job 45; ch1 30 since TD-007, 15 before; ch2 15;
      act1_quests 15; phase0 30). TD-009 row added and marked Resolved with this story and the evidence path; the
      header's item and open counts equal a count of the table's rows (shown in the evidence). `git diff --check`
      clean.

---

## Implementation Notes

- PowerShell (as revised, fact 1): `$code = $null` before the `try`; `$ErrorActionPreference = "Stop"` right after
  the `finally`. Then `if ($null -eq $code -and -not $watch.TimedOut)` → message + `$failed` (the guard, from the
  godot-gdscript-specialist check, keeps the timeout message the only one); skip the minimum-checks block when the
  code is null; the last line promotes a null code to 1 as it does 0.
- bash: `n="$(LC_ALL=C grep -a -cE ... || true)"` and
  `{ LC_ALL=C grep -a -E -A1 ... || true; } | LC_ALL=C grep -a -v '^--$' | sed 's/^/  /'`, with a comment that
  points at the result-line scan's reason.
- Header comments of both runners: one line each for the new behaviour (PowerShell) / the `-a` reason (bash).
- Commit only with the user's OK, Conventional Commits with `Task: TD-009` in the body.

---

## Out of Scope

- `ERROR:` lines (TD-008), the TD-007 watchdog, `suite_limits.txt`, `ci.yml`, `run_all_tests.ps1`.
- A committed normalization or comparison script: the timing normalization is stated in the evidence README.
- Known limit (recorded in /code-review, no change): if Godot starts and the PowerShell pipeline itself then
  throws (e.g. `Write-Host` fails), `$code` stays null and the runner says `Godot did not start` — fail-closed
  (exit 1), message imprecise. Not reproducible without fault injection.
- macOS (BSD grep/sed) and Linux grep ≥ 3.5: not available here; Linux is checked on the first CI run (AC-3).
- PowerShell 7 (`pwsh`): the statement-terminating behaviour was observed on Windows PowerShell 5.1 only; the
  runners are invoked with `powershell` (5.1) by `run_all_tests.ps1`.
- A permanent regression test for the runners (probes stay throwaway, as for TD-003 / TD-007).

---

## QA Test Cases

*Reviewed by qa-lead (QL-STORY-READY, 2026-10-21: GAPS → all six adopted by the user: L3b/L5 and the single
`RUNNER FAIL` line, copy diffs and hashes, inspection-only `Stop` line and mutant MU1, N3 + mutants MU2/MU3 +
dumps + locale + deferred Linux grep ≥ 3.5, named allowed diffs + stdout/stderr/exit per pair + pinned matrices +
S3, register values quoted and counts checked.)*

- **L1–L6, MU1, MU4** — as AC-2.
- **N0–N3, MU2, MU3** — as AC-3.
- **P1** — the TD-007 PowerShell matrix, OLD vs NEW (AC-4).
- **S1, S2** — the TD-007 bash matrix and extra cases, OLD vs NEW (AC-4); **S3** one real suite through
  `run_tests.sh` (AC-4).
- **I1** — `grep -n ErrorActionPreference` on the NEW runner (AC-1, inspection).
- **R5** — the full suite (AC-5).
- **X2** — register: `grep -n timeout-minutes` and the row count (AC-6).

---

## Test Evidence

**Story Type**: Integration (test tooling)
**Required evidence**: launch-failure and NUL-byte probe logs (old and new runner), the re-run TD-007 matrices,
the full-suite log, in `production/qa/evidence/2026-10-runner-followups/` with a README mapping each AC to its log.
**Run result**: N/A — nothing player-observable changes.

**Status**: [x] Created — production/qa/evidence/2026-10-runner-followups/ (README.md maps every AC to its log); no test file in tests/ by design (throwaway probes)

---

## Dependencies

- Depends on: TD-007 (`249cba4`).
- Unlocks: nothing directly; keeps the runners' verdict honest before Y1-P0-T15.
