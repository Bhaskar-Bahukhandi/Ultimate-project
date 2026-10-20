# TD-007 test runners: per-suite time limit and minimum checks — evidence

- **Task:** TD-007 · Stop a hung test suite, and fail a suite that ran fewer checks than it should
  (`production/epics/y1-p0-stabilize/story-td007-runner-watchdog.md`)
- **Code:** `fix/phase0-playthrough-blockers` at `8e37f5d` plus the uncommitted TD-007 change to
  `AethelgardPrototype/tests/run_phase0_tests.ps1`, `run_tests.sh`, the new `suite_limits.txt`, a comment in
  `run_all_tests.ps1`, and `.github/workflows/ci.yml` (a comment, Chapter 1 `timeout-minutes` 15 → 30). Captured
  2026-10-20 on Windows 11, Godot 4.6.3 console, Windows PowerShell 5.1 and Git Bash (GNU coreutils 8.32
  `timeout`). The work started on `a707a95`; `8e37f5d` (closing TD-003, docs only) landed meanwhile and changed
  no runner. `run_all.log` names the SHA-256 prefixes of the three files it ran with.
- **Probes:** throwaway `extends SceneTree` scripts and two stub "Godot" bash scripts, kept in the session
  scratchpad and never committed. The logs quote their output in full. H1: `SCRIPT ERROR` before `quit()` in
  `_initialize`. H2: no error, awaits a 100000 s timer. W5: quits 0 after 15 s. C1: a test function returns
  early, 1 of 2 checks runs. C2: no result line. M3: `TD007M3 ok=5 bad=0`. M5: two result lines. M6: only a
  lowercase `x result:` line. M7: `RESULT: 1 passed, 1 failed`, `quit(1)`. E1: `push_error` only. E2: `load()` of a
  missing resource. E3: `emit_signal` of an unknown signal. R1–R9: the TD-003 probes. K1: stub that ignores
  SIGTERM. K2: stub SIGKILLed after 1 s.
- **"OLD" runners** are `git show HEAD:<path>` copies (HEAD = `a707a95`, identical to `8e37f5d` for these
  files) with only the project-path line pinned. **Harness guard:** every case runs under an outer limit (40 s
  for an OLD hang, 90 s otherwise); a run still going at it is a HANG, and only that probe's Godot is stopped.

| Acceptance item | Result | Evidence |
|---|---|---|
| AC-1 limits file: 16 entries, `min_checks` = the `2026-10-runner/run_all.log` counts, timeouts 3× the measured Windows time (≥120 s), each below its CI step cap; one file for both runners; upkeep rule in its header; the three suite lists are one set | Pass. Baseline on the HEAD runners (1130 s, counts identical): ch1 536 s → 1620, phase0 309 s → 960, ch2 149 s → 480, act1_quests 56 s → 180, every other suite ≤16 s → 120. Linux CI (runs 39130932815, 39125308814, 2026-10-18): ch1 137 s, ch2 147 s, phase0 307 s. Only ch1's limit was above its cap: `timeout-minutes` 15 → 30. X1: `suite_limits.txt`, `run_all_tests.ps1` and `ci.yml` (+ `run_tests.sh` default) each list the same 16 suites, no duplicates | `baseline_timed_run_all.log`, `x1_suite_lists.log`, `tests/suite_limits.txt` |
| AC-2 timeout, PowerShell: 124 + `RUNNER FAIL <script>: timed out after <N> s`, process tree stopped, TD-003 summary still printed, no false timeout, isolation on the timeout path | Pass. W1/W2: OLD still running at 40 s; NEW exit 124 at 22.2–22.3 s with a 20 s limit, W1 also lists its `SCRIPT ERROR`; 0 Godot processes from the probe left, 0 isolation dirs left. In-process H1 and H2: `APPDATA` restored. W5 (quits at 15 s, limit 20 s): exit 0, no `RUNNER FAIL`. F1: with `taskkill.exe` unresolvable (PATH = scratch dir; `CommandNotFoundException` in a runspace, checked separately) the watchdog's `Stop-Process` fallback still stops the tree: exit 124 at 21.7 s, 0 left | `probe_matrix_ps.log` (SUMMARY, IN-PROCESS and F1 lines) |
| AC-3 timeout, bash/CI: GNU `timeout`, 124/137 counted only when the limit was reached, `::error::` in CI, missing GNU `timeout` is a warning locally and an error in CI | Pass under Git Bash. W1/W2 NEW: exit 124 at 20–21 s; W1 with `GITHUB_ACTIONS=true` adds the `::error::` lines. K1 (ignores SIGTERM, limit 3 s): killed after the `-k 10` grace, exit 124 with the message at 14 s. K2 (SIGKILLed at 1 s, limit 20 s): exit 137 passes through, no timeout message. G1 (a non-GNU `timeout` first on PATH): warning, exit 0. G2 (the same, `GITHUB_ACTIONS=true`): `RUNNER FAIL ... GNU timeout(1) not found` + `::error::`, exit 1 | `probe_matrix_sh.log`, `probe_matrix_sh_extra.log` |
| AC-4 minimum checks (both runners): N + F from the last column-0 `<NAME> RESULT:` / `ok=` line; refusal of an unregistered suite; CRLF-tolerant lookup | Pass on both runners. C1 min 2: OLD exit 0, NEW exit 1 `1 check(s) ran, expected at least 2`; min 1: exit 0. C2 min 1: NEW exit 1 `no result line`; no minimum: exit 0. M3 min 5 → 0, min 6 → 1. M5: the last line wins (`1 check(s) ran`). M6: lowercase → `no result line`. M7 min 2: exit 1 from Godot, no minimum message; min 3: `2 check(s) ran`. M4 `res://tests/unit/zz_td007/not_registered_test.gd`: refused before Godot starts, exit 1. V1/V2 (bash): `MIN_CHECKS=abc` and `TEST_TIMEOUT=0` refused, exit 1. CRLF: both lookups return `391 1620` / `81 960` from a CRLF copy, no `\r` (byte dump) | `probe_matrix_ps.log`, `probe_matrix_sh.log`, `probe_matrix_sh_extra.log`, `crlf_lookup.log` |
| AC-5 TD-003 behaviour unchanged | Pass. R1, R2, R2b, R3, R7a, R7b, R8, R9: the same exit codes OLD and NEW on both runners, and the OLD and NEW outputs are byte-identical (14 pairs compared: 8 PowerShell, 6 bash; bash R8/R9 OLD vs NEW in the extras log) | the three matrix logs |
| AC-6 probes old vs new | Pass (see AC-2–AC-4). E1/E2 exit 0 on both runners: part (b) is TD-008, not this story. E3 prints **no** `ERROR:` line at all in 4.6.3 (0 lines, exit 0, OLD and NEW), which corrects the register's TD-007 text. Under Git Bash no Godot process was left after any NEW timeout either (recorded, not asserted, per AC-6) | `probe_e3_unknown_signal.log`, matrix logs |
| AC-7 full suite, all 16, no `-Quick` | Pass on the final code (after the review suggestions): `All suites passed.`, exit 0, 1127 s; 0 `SCRIPT ERROR` / `Parse Error` / `RUNNER FAIL` / timeout-warning lines. All 16 result lines equal `2026-10-runner/run_all.log`. Per suite, measured vs limit: ch1 528.6 s / 1620 (×3.1), phase0 310.0 / 960 (×3.1), ch2 148.6 / 480 (×3.2), act1_quests 57.4 / 180 (×3.1), load_all 22.5 / 120 (×5.3), every other suite ≤10.7 s / 120 | `run_all.log` |
| AC-8 `git diff --check` clean; TD-007 Resolved, (b) split to TD-008 | Pass | `docs/tech-debt-register.md` (TD-007, TD-008) |
| AC-9 first CI run green on all 16 steps, per-step durations against the limits | **DEFERRED**: the branch is not pushed (pushing needs the user's OK). Linux SIGTERM handling, `XDG_DATA_HOME` isolation and output flushing at kill time are exercised only there | add the run URL here |

## Code-review follow-ups

`/code-review` (godot-specialist + qa-tester): APPROVED WITH SUGGESTIONS, all four applied before the final runs:
1. The PowerShell watchdog retries each second for up to 10 s and falls back to `Stop-Process` (child first) when
   `taskkill` fails, instead of failing open into the old hang (F1).
2. The bash result-line scan uses `LC_ALL=C grep -a`, so a stray non-UTF-8 byte cannot turn the log "binary".
3. `MIN_CHECKS` / `TEST_TIMEOUT` must be whole numbers (and the timeout above 0), so a typo cannot silently skip a
   check (V1, V2).
4. A header line rewrapped.

The testability pass also added G1/G2, K1/K2, bash R8/R9 OLD, in-process H2 and the CRLF check. Accepted untested:
the 5 s isolated-dir removal retry while a killed process still holds a handle (no lock injection), and the
millisecond-wide race when a suite exits on its own at the deadline.

Not retained: an earlier full run on the code before the review suggestions (16/16, the same counts, ch1 530 s,
1138 s total) was superseded by `run_all.log`; the first ad-hoc OLD-runner hang watches are superseded by the OLD
rows of the matrices. A hung probe from another session ran during the baseline timing run (~0.2 core).
