# TD-009 test runners: Godot launch failure, NUL byte in the script-error listing — evidence

- **Task:** TD-009 · Fail a suite whose Godot never started, and list script errors from a log with a NUL byte
  (`production/epics/y1-p0-stabilize/story-td009-runner-launch-failure.md`)
- **Code:** `fix/phase0-playthrough-blockers` at `249cba4` (TD-007) plus the uncommitted TD-009 change to
  `AethelgardPrototype/tests/run_phase0_tests.ps1` and `run_tests.sh`. Captured 2026-10-21 on Windows 11,
  Godot 4.6.3 console, Windows PowerShell 5.1.26100.9711, Git Bash (GNU grep 3.0, locale `C.UTF-8`).
  `run_all.log` and `launch_failure.log` name the SHA-256 of the runners they ran with.
- **Probes:** throwaway, kept in the session scratchpad and never committed; the logs quote their output.
  "OLD" = `git show HEAD:` copies of the runners (HEAD = `249cba4`) with only the project-path line pinned
  (`suite_limits.txt` copied beside the PowerShell copy). Launch-failure copies change only the exe line, to a
  missing file or to a text file named `.exe`; each copy's `diff` against its source heads `launch_failure.log`.
  The bash NUL / 0xFF cases use a stub "Godot" script (it prints a `SCRIPT ERROR` line, a following line, a
  `Parse Error` line, a following line, a result line, exit 0); their outputs are kept as `od -c` dumps, so no
  log here holds a raw NUL.
- **Mutants** (scratch copies of NEW with one fix line removed or reverted): MU1 without `$code = $null`, MU4
  without `$lines = $null`, MU2 with `-a` only on the first listing grep, MU3 with `-a` only on the filter grep.

## Corrected mechanism (story fact 1)

The first draft (and the brief) assumed a launch failure leaves `$LASTEXITCODE` unset and that resetting it
before the call fixes the in-process case. Debug copies of the HEAD runner showed otherwise: inside the
runner's `try`, a failed launch (`CommandNotFoundException` for a missing exe, `ApplicationFailedException` for
a file that is not a program) is **statement-terminating**: the rest of the `try` is skipped, `finally` runs,
and the script continues after it. `$code = $LASTEXITCODE` never runs, so `$code` is unset in a fresh process
(exit 0), or, through PowerShell's dynamic scoping, the **caller's** `$code` when the runner is called with `&`
(L3c: exit 7). `$lines` has the same exposure (L3d). A `$LASTEXITCODE` reset could never be observed and was
dropped (user decision); the fix initializes `$code` and `$lines` before the `try`.

| Acceptance item | Result | Evidence |
|---|---|---|
| AC-1 launch failure → `RUNNER FAIL <script>: Godot did not start`, exit 1; no minimum-checks message on that path; `Stop` set after the `finally` (new behaviour: HEAD stayed `Continue` after the call) | Pass. Inspection (I1): `$code = $null` (89), `$lines = $null` (90) before `try {` (91); `Continue` inside the `try` (93); `Stop` at 116, after `} finally` (99). The `Stop` line changes no probe or suite result (AC-4, AC-5) | `static_checks.log` (I1), `launch_failure.log` |
| AC-2 watched failing first: OLD vs NEW vs mutants | Pass. OLD: L1 exit **0** with `no result line`; L2 0; L3/L3b (after `cmd /c exit 0/3`) 0/0; L3c (caller `$code = 7`) **7**; L3d (caller `$lines` with a `SCRIPT ERROR` line) 0 with the caller's line listed as a script error; L5 (text file `.exe`) 0; L6 (missing exe, `-TimeoutSec 1 -MinChecks 2`) 0 with `no result line`. NEW: exit **1** in all eight, each with exactly one `RUNNER FAIL` line, `Godot did not start`. MU1: L3c back to 7, nothing else changes. MU4: L3d lists the caller's line again (two `RUNNER FAIL` lines), nothing else changes. L4 (bash, `GODOT=/no/such/godot`): 127 on OLD and NEW, unchanged | `launch_failure.log` (SUMMARY at the end), `bytes.log` / `bytes_summary.txt` (L4) |
| AC-3 NUL byte (bash): `LC_ALL=C grep -a` on the count, listing and filter; `LC_ALL=C sed` | Pass on Git Bash. N0 (no odd byte): OLD and NEW byte-identical. N1 (NUL after a match): OLD lists neither line (`  Binary file <log> matches`); NEW lists all four listing lines, equal to the golden dump. N3 (NUL only far from any match): OLD binary notice, NEW four lines. Count 2 and exit 1 everywhere. MU2: N1 `Binary file (standard input) matches`; MU3: N1 and N3 `Binary file <log> matches`, so each listing `-a` is load-bearing. N2 (0xFF): four lines on OLD and NEW under `C.UTF-8` and `LC_ALL=C` with grep 3.0 (no difference shown here). The count's `-a` is not shown to be needed (`grep -c` counts a binary file correctly); it keeps count and listing reading the log alike. **DEFERRED:** Linux, grep ≥ 3.5 (the binary notice goes to stderr) and BSD grep/sed on macOS — the first CI run after the next push | `bytes.log` (`od -c` per case), `bytes_summary.txt` |
| AC-4 no other change: TD-007 matrices OLD (`249cba4`) vs NEW, stdout, stderr and exit per pair; NEW exits equal the TD-007 NEW column; S3 | Pass. The TD-007 matrix scripts (SHA-256 in `static_checks.log`, equal to the TD-007 session's copies) were re-run as pairs: every NEW case (probe + arguments) on both runners. 86 output pairs: 84 byte-identical raw, 2 (K1, K2) equal after normalizing bash's job-control notice, which names the runner's path and PIDs (the OLD copy and the NEW runner live at different paths). 61 exit-code pairs all equal (25 PowerShell, 28 bash, 8 extras). The NEW exits equal the NEW column of `2026-10-runner-watchdog/` for all 25 + 28 + 8 cases. S3 (`test_layout_test.gd` through `run_tests.sh` under Git Bash): OLD and NEW exit 0, `LAYOUT RESULT: 6 passed, 0 failed`, equal to the reference | `probe_matrix_ps.log`, `probe_matrix_sh.log`, `probe_matrix_sh_extra.log`, `pair_compare.log`, `s3.log` |
| AC-5 full suite, all 16, no `-Quick` | Pass: `All suites passed.`, exit 0, 1149 s; 0 `SCRIPT ERROR` / `Parse Error` / `RUNNER FAIL` lines. The 16 result lines equal `2026-10-runner-watchdog/run_all.log` (its `[  N s]` timing prefix stripped) | `run_all.log`, `result_lines_td009.txt`, `result_lines_reference.txt` |
| AC-6 register: TD-007 wording quotes the CI caps; TD-009 row; header counts equal the rows; `git diff --check` clean | Pass. `ci.yml`: job 45; ch1 30 (15 at `8e37f5d`, before TD-007), ch2 15, act1_quests 15, phase0 30 | `static_checks.log` (X2), `docs/tech-debt-register.md` |

## Normalization used for the pair comparison (AC-4)

Raw bytes are compared first. Only when they differ, both sides pass through: drop `elapsed=<n>s`; replace
`aeth_phase0_test_*` / `aeth_test_log_*` and the harness's `sh?_XXXXXX` dirs with fixed names; replace
`<path>/run_tests.sh: line N: <pid> ` with `<runner>: line N: <pid> ` and a leading `<pid> Done` with
`<pid> Done`. Nothing else is changed. The only pairs allowed to differ were L1–L6, MU1–MU4 and N1–N3; none of
those are in the matrices, and no matrix pair differs after this step.

## Code review

`/code-review` (godot-specialist + qa-tester, plus a godot-gdscript-specialist check during /dev-story):
CHANGES REQUIRED → fixed → APPROVED WITH SUGGESTIONS.
1. Required: `$lines` left unassigned by a launch failure reads an in-process caller's `$lines` (L3d,
   verified) → `$lines = $null`.
2. The `Stop` line is new behaviour, not a restore → comment and story reworded.
3. Header line wrapped; bash comment moved above the `grep -c` guard comment.
4. `LC_ALL=C sed` in the listing (BSD sed may reject a non-UTF-8 byte; unverified here).
5. The did-not-start message is guarded with `-not $watch.TimedOut` (L6).

Accepted, not changed: if Godot starts and the PowerShell pipeline itself then throws, the runner says
`Godot did not start` (fail-closed, exit 1; not reproducible without fault injection). Two code lines stay
over 100 chars (106, 128), within the files' existing range. PowerShell 7 (`pwsh`) not assessed:
`run_all_tests.ps1` runs the runner with Windows PowerShell 5.1.

Not retained: the first launch probes on the pre-review code (superseded by `launch_failure.log`), an
in-process debug copy used to find the statement-terminating behaviour, and a first byte-probe run whose NEW
copy was empty because of a harness bug (OLD rows were valid; superseded by `bytes.log`).
