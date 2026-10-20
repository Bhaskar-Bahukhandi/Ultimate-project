# Story TD-007: Stop a hung test suite, and fail a suite that ran fewer checks than it should

> **Epic**: Y1-P0 Stabilize (Sprint 001)
> **Task ID**: TD-007 (`docs/tech-debt-register.md#TD-007`; follow-up of TD-003, due before Y1-P0-T15)
> **Status**: In Progress
> **Layer**: Foundation (test tooling)
> **Type**: Integration
> **Estimate**: 1 day (register effort: M)
> **Manifest Version**: N/A — `docs/architecture/control-manifest.md` does not exist
> **Last Updated**: 2026-10-20

## Context

**GDD**: none (test tooling). **Source of record**: TD-007 in `docs/tech-debt-register.md`, raised in the TD-003
code review (`production/epics/y1-p0-stabilize/story-td003-runner-script-errors.md`, evidence
`production/qa/evidence/2026-10-runner/README.md`, "Code-review follow-ups").
**Requirement**: N/A — no TR-ID registered.

**ADR Governing Implementation**: N/A — a change to the test runners only; no architectural decision is made.
**ADR Decision Summary**: N/A
**ADR Version**: N/A

**Engine**: Godot 4.6 (4.6.3 at `C:/Godot`) | **Risk**: LOW (no engine API is used by the runners; they start,
watch and stop the Godot process and read its console output)
**Engine Notes**: On Windows `Godot_v4.6.3-stable_win64_console.exe` is a wrapper: the real
`Godot_v4.6.3-stable_win64.exe` runs as its child, so stopping a hung suite means stopping the process tree, not
only the wrapper. A `SCRIPT ERROR` aborts only the current function; when that function is the one that would call
`quit()`, the main loop keeps running forever. `Logger` / `OS.add_logger()` exist in 4.6.3
(`ClassDB.class_exists("Logger")` is true), which matters for the split-off part (b) below.

**Control Manifest Rules**: NOT ASSESSED — no control manifest.

**Performance**: the watchdog sleeps in a background runspace (PowerShell) or is `timeout(1)` (bash); a clean
suite is not slowed (spike: clean probe 1.8 s with the watchdog). Reading a ~20-line limits file once per suite.

**AGENTS.md protected areas**: none touched. No game code, scene, save format, test suite or `.uid` changes; the
per-suite check counts stay exactly as in `production/qa/evidence/2026-10-runner/run_all.log`.
Files: `AethelgardPrototype/tests/run_phase0_tests.ps1`, `AethelgardPrototype/tests/run_tests.sh`, new
`AethelgardPrototype/tests/suite_limits.txt`, a comment in `AethelgardPrototype/tests/run_all_tests.ps1`, a comment
and ch1's `timeout-minutes` in `.github/workflows/ci.yml`, evidence, the register, this story.

### Audit facts (2026-10-20, watched on the HEAD a707a95 runners; throwaway probes in the session scratchpad)

| Probe | What it does | PowerShell runner | bash runner |
|---|---|---|---|
| H1 | `SCRIPT ERROR` in `_initialize`, before its `quit(0)` | **hangs** (still running at 40 s) | **hangs** (stopped by an outer `timeout 40`, exit 124) |
| H2 | no error, `await`s a 100000 s timer before `quit` | **hangs** | not run (same mechanism) |
| E1 | `push_error(...)`, then `quit(0)` | exit 0, one `ERROR:` line | exit 0 |
| E2 | `load()` of a missing `.tres`, result unchecked, `quit(0)` | exit 0, two `ERROR:` lines | — |
| E3 | `Node.new().emit_signal("no_such_signal")`, `quit(0)` | exit 0, **no output at all** | — |
| C1 | test function returns early without an error; 1 of 2 checks runs | exit 0, `RESULT: 1 passed` | exit 0 |
| C2 | prints no result line, `quit(0)` | exit 0 | — |

- E3 corrects the register: in 4.6.3 emitting an unknown signal on a `Node` prints nothing, so no output scan can
  catch it.
- The last green full run (`2026-10-runner/run_all.log`) has **19** `ERROR:` lines, none from a failure: 14 come
  from negative tests that provoke them on purpose (`[SideQuest] ... (reward skipped)` x6 in
  side_quest_rewards, `[LOAD] Slot 1 has no usable save`, `[Dialogue] ... has no node 'no_such_node'`,
  `ConfigFile parse error at user://input.cfg`), and 5 are the engine's `Lambda capture at index 0 was freed`
  (phase0_blockers x3, act1_quests_completable x2).
- Every suite prints one result line: `<NAME> RESULT: <N> passed, <M> failed`, except load_all
  (`LOADALL ok=<N> bad=<M>`). Counts in `run_all.log`: layout 6, load_all 206, dialogue 47, context 33, input 52,
  side_quest_rewards 134, ngplus 192, fragment 21, null_potion 83, screen_flash 107, ch1 391, ch2 49,
  combat_fixes 10, reachability 21, act1_quests 114, phase0 81.
- Measured durations, Windows (baseline run of all 16 on the HEAD runners, 2026-10-20 20:17–20:36, 1130 s in total
  against 1128 s for `2026-10-runner/run_all.log`; counts identical; kept as `baseline_timed_run_all.log`):
  ch1 **536 s**, phase0 **309 s**, ch2 **149 s**, act1_quests **56 s**, load_all 16 s, screen_flash 11 s,
  combat_fixes 10 s, every other suite 2–7 s. Another session's hung probe Godot (~0.2 core) ran throughout.
- Measured durations, Linux CI (the last green runs, 39130932815 and 39125308814, 2026-10-18, before T05–T08):
  ch1 137 s, ch2 147 s, phase0 307 s, every other step ≤ 10 s; job 645–653 s. ch1 is ~4× slower here than in that
  run; it changed since (T05, T06), so its Linux time now is unknown until the next push.
- CI already caps some steps (`timeout-minutes`: 15 for ch1, ch2, act1_quests; 30 for phase0; job 45).
- `test_layout_test.gd` reads `run_tests.sh` with the regex `\$\{1:-(res://[^}]+)\}` to find the default suite,
  so the `script="${1:-res://...}"` line must keep that form.

### Decision on part (b), `ERROR:` lines — decided 2026-10-20 by the user: split to TD-008

**No runner-level `ERROR:` rule; split into a new register item (TD-008)** for in-suite error capture
with `OS.add_logger()` in a shared test helper, where each negative test declares the error it expects and any
other error fails a check. Reasons:
1. 14 of the 19 `ERROR:` lines in a green run are expected by the tests that cause them. The runner cannot tell
   them from a real failure without a per-suite allow-list of message patterns, kept away from the tests that own
   them; every new negative test would need a matching runner edit.
2. The 5 `Lambda capture ... was freed` lines are an engine report about game code. Allow-listing them hides
   them; failing on them needs a gameplay fix, which this story may not make (AGENTS.md).
3. CI runs on Linux, where the engine may print `ERROR:` lines that Windows does not (drivers, shutdown leaks
   such as `RID allocations ... leaked at exit`). That cannot be checked before the next push (AC-7 of TD-003 is
   still deferred), so an allow-list made on Windows risks a red CI on the first run.
4. It would not catch E3 (no output) at all.

Rejected alternative: an allow-list file now (`tests/expected_errors.txt`, `<suite> <regex>` per line, reviewed);
the runner fails on any `^ERROR:` line not matched for that suite. It catches E1/E2 today, with the costs in 1–3.

**Limits location** — decided 2026-10-20 by the user: one data file, `tests/suite_limits.txt`, read by both
runners (not runner arguments in `run_all_tests.ps1` and 16 `ci.yml` steps, which would be two copies to keep in
sync).

---

## Acceptance Criteria

- [ ] AC-1 **Per-suite limits file.** `AethelgardPrototype/tests/suite_limits.txt` lists every suite in
      `run_all_tests.ps1`, one line each: `<res:// path> <min_checks> <timeout_seconds>`, `#` comments allowed.
      `min_checks` equals the suite's count (passed + failed) in `2026-10-runner/run_all.log`; `timeout_seconds`
      is 3× the suite's measured Windows duration rounded up to a whole minute, and at least 120 s: ch1 1620,
      phase0 960, ch2 480, act1_quests 180, every other suite 120. Each limit stays below the suite's CI step cap
      so the runner's message is what CI shows: ch1's cap goes from 15 to 30 minutes (1620 s = 27 min; the job
      cap of 45 still holds: ~11 min of other steps + 27); the others already fit (ch2 480 s and act1 180 s under
      15 min, phase0 960 s under 30). Both runners read this one file; apart from that one `timeout-minutes`, no
      step in `ci.yml` and no call in `run_all_tests.ps1` changes. The file's header comment says who keeps it
      current: a change that adds, removes or splits checks in a suite, or adds or deletes scripts and scenes
      (load_all counts them), sets that suite's `min_checks` to the new count in the same change. A scripted
      comparison, kept in the evidence, shows that the file's paths, the 16 suites in `run_all_tests.ps1` and the
      suites `ci.yml` runs (its `run_tests.sh` arguments plus `run_tests.sh`'s default) are the same set, with no
      stale entry.
- [ ] AC-2 **Timeout (PowerShell).** Limits, one rule for both runners: `-TimeoutSec` / `-MinChecks` (bash:
      `TEST_TIMEOUT` / `MIN_CHECKS`) override the file; else the file's entry; else, for a script that is not a
      `*_test.gd` under `res://tests/`, **600 s** and no minimum (a `*_test.gd` there with no entry is refused,
      AC-4). When Godot is still running at the deadline, the runner stops Godot **and its child**
      (`taskkill /F /T`), prints `RUNNER FAIL <script>: timed out after <N> s`, still prints the TD-003
      script-error summary if any, and exits **124**. The timed-out flag is set only when the watchdog actually
      found and killed the process, so a suite that exits on its own just before the deadline is not reported as a
      timeout. Every output line up to the stop is still printed once. After a timeout the isolated dir is still
      removed (retried for up to 5 s while the killed processes release their handles) and `APPDATA` is restored.
      A suite that finishes in time is not affected, and the watchdog is gone when the runner exits.
- [ ] AC-3 **Timeout (bash/CI).** `run_tests.sh` runs Godot under GNU `timeout -k 10 <N>` with the same limits and
      the same message, plus a `::error::` line under `GITHUB_ACTIONS=true`. It reports a timeout, and exits 124,
      only when the exit is 124 or 137 **and** the elapsed time (`$SECONDS`) reached the limit; any other 137 (for
      example an OOM kill) passes through as Godot's code with no timeout message. If no GNU `timeout` is found
      (`timeout --version` does not name coreutils), it prints
      `WARNING: GNU timeout(1) not found; running without a time limit` and runs as before; under
      `GITHUB_ACTIONS=true` that is an error instead (`RUNNER FAIL <script>: GNU timeout(1) not found`, exit 1).
- [ ] AC-4 **Minimum checks (both runners).** For a suite with `min_checks > 0` that did not time out, the runner
      reads the **last** line matching `RESULT: <N> passed, <F> failed` or `ok=<N> bad=<F>` (case-sensitive; a
      lowercase `result:` does not count; the line must start at column 0 with an uppercase name such as
      `LAYOUT RESULT:` or `LOADALL ok=`, so a check description quoting such text is never counted, as all 16
      suites print their totals today — added in /dev-story from the godot-gdscript-specialist review) and counts
      the checks that **ran**, `N + F` (a failed check already fails the suite through its exit code; counting only
      passes would add a misleading second message). `N + F < min_checks` →
      `RUNNER FAIL <script>: <N+F> check(s) ran, expected at least <M>`; no such line →
      `RUNNER FAIL <script>: no result line (expected at least <M> checks to run)`. Either fails the suite: exit 1
      when Godot exited 0, otherwise Godot's code (124 wins). A `*_test.gd` under `res://tests/` with no entry in
      the file fails with `RUNNER FAIL <script>: no entry in tests/suite_limits.txt` before Godot starts; other
      scripts (probes, `docs/visual_review/...`) follow AC-2's rule. The lookup ignores a trailing `\r` (a CRLF
      working-tree edit of the file).
- [ ] AC-5 **TD-003 behaviour unchanged.** The TD-003 probes (R1 runtime error, R2 parse error, R2b loaded broken
      helper, R3 clean, R7a/R7b `quit(3)`, R8 lowercase, R9 adjacent matches) give the same exit codes and the same
      `RUNNER FAIL ... script error line(s)` text as on HEAD, both runners. Isolation unchanged (no
      `aeth_phase0_test_*` dir left, `APPDATA` restored), on the timeout path too.
- [ ] AC-6 **Probes, old vs new, both runners.** H1 and H2 hang on the OLD runner and exit 124 on the NEW one
      within the timeout plus 15 s. On the PowerShell runner no Godot process from the probe is left afterwards,
      the isolated dir is gone and `APPDATA` is restored. Under Git Bash the bash runner is held to the message and
      exit code only, and the number of Godot processes left is recorded (MSYS `timeout` may stop only the console
      wrapper); tree cleanup on Linux, where there is no wrapper, is shown by AC-9. C1 and C2 (given an
      entry with `min_checks 2` through `-MinChecks` / `MIN_CHECKS` or a scratch copy of the limits file) exit 0
      OLD and 1 NEW with the AC-4 message. E1 and E2 exit 0 on both (part (b) not in this story, recorded).
      Logs in `production/qa/evidence/2026-10-runner-watchdog/`.
- [ ] AC-7 **Full suite.** `run_all_tests.ps1` (all 16, no `-Quick`) on the new runners: 16/16, `All suites
      passed.`, no `RUNNER FAIL` line, per-suite counts equal to `2026-10-runner/run_all.log`, per-suite durations
      recorded; the log records the commit and working-tree state it ran on.
- [ ] AC-8 `git diff --check` clean; TD-007 in `docs/tech-debt-register.md` marked Resolved for (a) and (c), with
      (b) recorded as decided (split to TD-008 with the reasons above, or done here if the alternative is chosen).
- [ ] AC-9 (DEFERRED to the next push, which needs the user's OK) The first CI run after this change is green on
      all 16 test steps; each step's duration is recorded here and checked against its `timeout_seconds` (at
      least 2× headroom on Linux; a miss is fixed by editing only `tests/suite_limits.txt`). Run URL recorded here.

---

## Implementation Notes

- PowerShell watchdog: keep TD-003's streaming call (`& $godot ... 2>&1 | ForEach-Object { ... Write-Host ... }`)
  unchanged. Before it, start a `[powershell]::Create()` runspace that sleeps `$TimeoutSec`, then finds
  `Win32_Process` entries with `ParentProcessId = $PID` and the console exe's name, sets a synchronized flag and runs
  `taskkill /F /T /PID`. After Godot returns: `$dog.Stop(); $dog.Dispose()`. (Spike in the scratchpad: H1 stopped at
  15.9 s, no orphans; clean probe 1.8 s.)
- Bash: `timeout -k 10 "$secs" "$godot" ...` inside the existing `2>&1 | tee` pipeline; `PIPESTATUS[0]` is 124 or
  137 on a timeout. With `set -u`, expand an optional prefix array as `${t[@]+"${t[@]}"}` (macOS bash 3.2).
- Limits lookup: PowerShell splits each non-comment line on whitespace; bash uses
  `awk -v s="$script" '$1 == s { print $2, $3 }'`. `-MinChecks` / `-TimeoutSec` (PS) and `MIN_CHECKS` /
  `TEST_TIMEOUT` (bash) override the file, for probes.
- Comments in `run_all_tests.ps1` and `ci.yml` mention the limits file. The `timeout-minutes` in `ci.yml` stay as a
  backstop (ch1's raised to 30, AC-1).
- Commit only with the user's OK, Conventional Commits with `Task: TD-007` in the body.

---

## Out of Scope

- Part (b) if split: in-suite `ERROR:` capture (TD-008). No `ERROR:` / `WARNING:` line changes a verdict here.
- Fixing the `Lambda capture at index 0 was freed` engine errors (gameplay code).
- Changing any test suite, including adding a check to `test_layout_test.gd` that every suite has a limits entry
  (the runner enforces it instead; a layout check would change its count of 6).
- `run_screenshots.ps1`.
- A permanent regression test for the runners (probes stay throwaway, as for TD-003).

---

## QA Test Cases

*Reviewed by qa-lead (QL-STORY-READY, 2026-10-20: GAPS → all eight adopted: Git Bash scope, 137 + elapsed,
boundary flag, timeout-path isolation, 600 s default, R-regression/M5–M7/W5, suite-list cross-check, override
precedence and minimum upkeep).*

- **W1 hang after a script error (H1)** — OLD: still running at 40 s (stopped by the harness). NEW with
  `-TimeoutSec 20` / `TEST_TIMEOUT=20`: exit 124 by ~20–30 s, `RUNNER FAIL ... timed out after 20 s`, then the
  TD-003 summary with the `SCRIPT ERROR` line; no Godot process with the probe's path left.
- **W2 hang without an error (H2)** — the same, with no script-error summary.
- **W3 no false timeout** — R3 clean probe with a 20 s limit: exit 0, no `RUNNER FAIL`, line count equal to OLD.
- **W4 exit code order** — R7a `quit(3)` → 3; R7b script error + `quit(3)` → 3; H1 → 124.
- **W5 near the deadline** — a probe that waits 15 s and then quits 0, with a 20 s limit: exit 0, no `RUNNER FAIL`.
- **W1/W2 isolation** — after each timeout: no `aeth_phase0_test_*` dir from the run, `APPDATA` unchanged.
- **M1 early return (C1)** with min 2 → exit 1, `1 check(s) ran, expected at least 2`. Min 1 → exit 0.
- **M2 no result line (C2)** with min 1 → exit 1, `no result line`. With no minimum → exit 0.
- **M3 `ok=` form** — a probe printing `PROBE ok=5 bad=0` with min 5 → 0, with min 6 → 1.
- **M5 two result lines** — a probe printing `A RESULT: 5 passed, 0 failed` then `B RESULT: 1 passed, 0 failed`:
  min 2 → exit 1 with `1 check(s) ran` (the last line wins).
- **M6 lowercase** — a probe printing only `x result: 5 passed, 0 failed`: min 1 → `no result line`.
- **M7 failures count as run** — a probe printing `RESULT: 1 passed, 1 failed` and `quit(1)`: min 2 → exit 1 from
  Godot, no minimum-checks message; min 3 → exit 1 with `2 check(s) ran, expected at least 3`.
- **M4 unregistered suite** — a scratch `res://`-style path under `tests/` with no entry → fails before Godot starts
  (checked with a path that does not exist in the file; no file is added to the repo).
- **R-regression (AC-5)** — the TD-003 probes R1, R2, R2b, R3, R7a, R7b, R8, R9 on OLD and NEW, both runners: same
  exit codes and the same `script error line(s)` summary lines.
- **X1 suite lists** — the AC-1 comparison script's output in the evidence.
- **B1 bash** — W1, W2, W3, W4, M1–M7 through `run_tests.sh` under Git Bash (`GODOT` = Windows console exe,
  `APPDATA` isolated as in TD-003); `GITHUB_ACTIONS=true` adds `::error::` lines; `TMPDIR` left empty. Message and
  exit code only for the timeout cases; Godot processes left are recorded, not asserted (AC-6).
- **R5 full suite** — as AC-7.

---

## Test Evidence

**Story Type**: Integration (test tooling)
**Required evidence**: probe logs (old and new runner, PowerShell and bash), the baseline timing log, and the
full-suite log in `production/qa/evidence/2026-10-runner-watchdog/`.
**Run result**: N/A — nothing player-observable changes.

**Status**: [x] Created — production/qa/evidence/2026-10-runner-watchdog/ (README.md maps every AC to its log); no test file in tests/ by design (throwaway probes)

---

## Dependencies

- Depends on: TD-003 (done, a707a95).
- Unlocks: Y1-P0-T15 (a hung suite now stops with a reason instead of hanging the playthrough gate).
- Note for TD-002: a new suite added there needs a line in `tests/suite_limits.txt`, or the runner refuses it.
