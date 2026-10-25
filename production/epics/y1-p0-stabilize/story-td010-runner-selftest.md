# Story TD-010: A permanent self-test for the test runners

> **Epic**: Y1-P0 Stabilize (Sprint 001)
> **Task ID**: Y1-P0-TD-010 (`docs/tech-debt-register.md#TD-010`; added to Sprint 001 on 2026-10-24, `production/sprints/sprint-001.md`)
> **Status**: In Progress
> **Layer**: Foundation
> **Type**: Integration
> **Estimate**: 2 days (cut line: the stale-min_checks warning, then the suite_limits.txt header doc)
> **Manifest Version**: N/A — `docs/architecture/control-manifest.md` does not exist
> **Last Updated**: 2026-10-24

## Context

**GDD**: none (test infrastructure). **Source of record**: register item TD-010 ("The test runners
(`run_phase0_tests.ps1`, `run_tests.sh`) have no permanent self-test: TD-003/TD-007/TD-009 were proven with throwaway
probes kept only in session scratchpads, and the Linux timeout / `timeout -k` path has never run … Add a self-test that
points `GODOT` at a stub script printing canned lines or sleeping (no engine needed), run in CI on Linux, covering 124
over 137, the elapsed rule, last result line wins, no result line, and an unregistered suite …"), raised at the close of
TD-007 (`production/epics/y1-p0-stabilize/story-td007-runner-watchdog.md`) and widened at TD-009; the sprint plan row
("must close before T14b (both edit `ci.yml`) … cut line if 2 days run out"). **Requirement**: N/A — no TR-ID registered.

**ADR Governing Implementation**: N/A — test infrastructure; no architectural decision.
**ADR Decision Summary**: N/A
**ADR Version**: N/A

**Engine**: Godot 4.6 (4.6.3 at `C:/Godot`) | **Risk**: HIGH (`docs/engine-reference/godot/VERSION.md`, 4.6 row)
**Engine Notes**: no engine API; the self-test runs no Godot at all (a stub stands in for it). Shell behaviour that
matters: bash command substitution drops NUL bytes, so a NUL on a result line never reaches `run_tests.sh:119` (only a
non-UTF-8 byte such as 0xFF can); `SECONDS` has whole-second granularity, so elapsed-rule cases need a margin of at least
10 s; GNU `timeout -k 10` sends TERM then KILL 10 s later (exit 124 / 137).

**Control Manifest Rules**: NOT ASSESSED — no control manifest.

**Performance**: no runtime cost in the game. The bash self-test adds well under 90 s to CI (the TERM-ignoring case waits for
the 10 s kill).

**AGENTS.md protected areas**: none touched (test tooling only). Files: `AethelgardPrototype/tests/run_tests.sh`,
`tests/run_phase0_tests.ps1`, `tests/suite_limits.txt` (header only), new `tests/runner_selftest/test_runners.sh`,
`tests/runner_selftest/stub_godot.sh` (executable, LF), `tests/runner_selftest/test_runner_ps.ps1` and its stub,
`.github/workflows/ci.yml` (one step), `AethelgardPrototype/CHANGELOG.md`, `docs/tech-debt-register.md` (TD-010 resolved
and a new item for the deferred PowerShell timeout cases, at close), evidence, this story.

### Audit facts (2026-10-24, read-only; key claims re-checked in the main session)

- **Injection.** `run_tests.sh` runs `"${GODOT:-godot}" --headless --path P --script S` (:24, :81) and honours
  `TEST_TIMEOUT` (:47) and `MIN_CHECKS` (:46); a fake script path that is not `res://tests/*_test.gd` gets the defaults
  `0 600` (:43), so a self-test needs no `suite_limits.txt` line; a fake `res://tests/x/foo_test.gd` is refused at :41
  before the stub runs. `run_phase0_tests.ps1` hardcodes `Get-ChildItem "C:\Godot" -Filter "Godot_v4*_console.exe"`
  and throws if absent (:35-36), before the suite_limits lookup (:38-47); it has `-TimeoutSec` / `-MinChecks` (:28, :31).
  Its watchdog finds Godot by process `Name` (:69, `$godot.Name`), so a `.cmd` stub (which runs as `cmd.exe`) cannot test
  the timeout path — that needs a real `.exe` stub.
- **Behaviours** (bash / PS): script-error scan → `RUNNER FAIL <s>: N script error line(s)`, exit 1 or Godot's non-zero
  code (`run_tests.sh:98-107` / `:129-142`); timeout → bash `timeout -k 10` (:62), 124 or 137 **and**
  `SECONDS - start >= timeout_sec` → `timed out after N s`, exit 124 (:87-91, :133), any other 137 passes through; PS sets
  `TimedOut` only after a real kill (:81), exit 124; min checks → `no result line (expected at least N checks to run)` /
  `N check(s) ran, expected at least M`, skipped after a timeout; the last column-0 uppercase result line wins, in the
  `RESULT: N passed, M failed` or `ok=N bad=M` form (:118 / :149); an unregistered `res://tests/*_test.gd` →
  `no entry in tests/suite_limits.txt`, exit 1. Bash only: non-numeric `MIN_CHECKS` / `TEST_TIMEOUT` → exit 1 (:49-54);
  no GNU `timeout` → a warning locally, `RUNNER FAIL … GNU timeout(1) not found` and exit 1 under `GITHUB_ACTIONS`
  (:61-69); a missing exe → exit 127, no message. PS only: a missing or unrunnable exe → `Godot did not start`, exit 1
  (:118-122); `$code` / `$lines` are reset to `$null` before the `try` (:89-90) so an in-process caller's variables cannot
  leak in; NUL handling is bash only.
- **Bundled fixes.** `run_tests.sh:119`: `result="$(echo "$result_line" | { grep -oE '…' || true; } | tail -n 1)"` lacks
  the `-a` / `LC_ALL=C` its neighbours have (:98, :102, :118). `run_phase0_tests.ps1:118-122` says "Godot did not start"
  also when Godot started and the pipeline threw (accepted-not-fixed in the TD-009 follow-ups). The watchdog loop
  (:67-84) gives up silently after 10 failed `Get-CimInstance` queries (fail-open: the suite then runs on), and
  `$killed = $?` (:79) reads the success of the `Stop-Process` just before it; neither is commented.
- **Earlier probes.** None of the TD-003/007/009 probe sources were committed; only their logs are
  (`production/qa/evidence/2026-10-runner*/`: `probe_matrix_ps.log`, `probe_matrix_sh.log`, `bytes.log` with `od -c`
  dumps of the N1 listing, …). `golden_n1_listing.od` is not in the repo and has to be regenerated. The TD-007 matrix
  case names (W/K/G/C/M/V) are a usable catalogue.
- **CI.** The bash self-test can run as one step before the suites (no Godot needed). The PS runner cannot run on ubuntu
  (it needs `C:\Godot`, `Get-CimInstance`, `taskkill`, `APPDATA`); whether `pwsh` is on ubuntu-latest is UNVERIFIED and
  irrelevant here. T14b also edits `ci.yml`: TD-010 lands first.

### User decisions (2026-10-24)

1. **PowerShell runner:** add an environment override (`$env:GODOT`, default unchanged) and a Windows-only,
   locally run `tests/runner_selftest/test_runner_ps.ps1` covering the non-timeout cases. The PS timeout / kill cases
   (they need a compiled `.exe` stub) go to the backlog as a new tech-debt item.
2. **Line 119:** apply the fix, and cover it with a 0xFF-on-the-result-line case in the bash self-test that runs in CI;
   its watch-fail is recorded as not shown locally (Git Bash's grep 3.0 shows no difference) — only the CI run proves it.
3. **Cut line items included:** the stale-min_checks warning and the `suite_limits.txt` result-line doc (dropped only if
   the 2 days run out).
4. QL-STORY-READY gaps G1-G9 (2026-10-24) adopted: environment isolation per case, 20 s stubs with a 40 s outer cap,
   a discriminating 0xFF case (SKIP fails in CI), literal NUL golden compared with `cmp`, exact warning text and gating,
   PowerShell stub details and markers, mutations d1/d2/h/i, git mode / eol checks.

---

## Acceptance Criteria

- [ ] AC-1 **Bash self-test.** `tests/runner_selftest/test_runners.sh` runs the real `tests/run_tests.sh` with
      `GODOT=<absolute path>/tests/runner_selftest/stub_godot.sh`, no engine. The stub switches on `STUB_MODE`, prints
      canned lines, exits with `STUB_EXIT` (default 0), touches `$STUB_MARKER` when it runs, and for the sleeping modes
      `exec`s `sleep 20` (`ignore_term`: `trap '' TERM; sleep 20`).
      - **Isolation:** every case runs as `env -u GITHUB_ACTIONS -u MIN_CHECKS -u TEST_TIMEOUT -u LC_ALL …` plus only the
        variables the case sets, with stdout+stderr captured to a file under a per-case dir outside the scratch `TMPDIR`
        given to the runner. `real_timeout="$(command -v timeout)"` is resolved before any `PATH` change; if it is not GNU
        coreutils `timeout` the self-test exits 2 with a message. Each runner call is wrapped in
        `"$real_timeout" -k 5 40 …` so a broken runner cannot hang CI; that outer cap fails the case by assertion.
      - **Cases** (exit code + text asserted; "no RUNNER FAIL" asserted where none is expected):
        - `pass` (prints `STUB RESULT: 2 passed, 0 failed`), `MIN_CHECKS=2` → exit 0, no RUNNER FAIL, marker present;
        - `script_errors` (prints, in order: `SCRIPT ERROR: stub failure one`, `   at: stub_a (res://stub.gd:1)`,
          `Parse Error: stub failure two`, `   at: stub_b (res://stub.gd:2)`, `STUB RESULT: 2 passed, 0 failed`; exit 0)
          → exit 1, `2 script error line(s)`, all four lines listed;
        - `pass` with `STUB_EXIT=3` → exit 3;
        - `two_results` (`A RESULT: 1 passed, 0 failed` then `B RESULT: 5 passed, 0 failed`), `MIN_CHECKS=4` → exit 0;
          `two_results_reversed` → exit 1, `1 check(s) ran, expected at least 4`;
        - `no_result`, `MIN_CHECKS=1` → exit 1, `no result line (expected at least 1 checks to run)`;
        - `loadall` (`LOADALL ok=7 bad=0`), `MIN_CHECKS=7` → exit 0; `MIN_CHECKS=8` → exit 1;
        - unregistered `res://tests/selftest/fake_test.gd` → exit 1, `no entry in tests/suite_limits.txt`, marker absent;
        - `sleep`, `TEST_TIMEOUT=2`, `MIN_CHECKS=1` → exit 124, `timed out after 2 s`, no `no result line`;
        - `ignore_term`, `TEST_TIMEOUT=2` → exit 124 (GNU timeout's 137 after the KILL, mapped by the elapsed rule),
          `timed out after 2 s`;
        - `selfkill` (SIGKILLs itself after 1 s), `TEST_TIMEOUT=20` → exit 137, no `timed out` text;
        - fake non-GNU `timeout` first on `PATH` (run as `"$real_timeout" -k 5 40 env PATH="$fake:$PATH" bash run_tests.sh`):
          without `GITHUB_ACTIONS` → the warning and exit 0; with `GITHUB_ACTIONS=true` → exit 1, `GNU timeout(1) not found`;
        - `nul_listing` (the NUL sits inside the line after `SCRIPT ERROR`, i.e. in the `-A1` context) → the runner's
          output, saved to a file, contains no `Binary file`, and its listing compared with `cmp` equals four literal
          expected lines written in the self-test (the `od -c` dump is kept as documentation only);
        - `ff_result` (result line `FF RESULT: 2 passed, 0 failed` with a 0xFF byte at its end — *amended during
          /dev-story*: a byte inside the name is not a result line at all), `LC_ALL=C.UTF-8`, `MIN_CHECKS=2` → exit 0
          (see AC-3);
        - `GODOT` at a missing file → exit 127 (a characterisation of today's silent failure: no RUNNER FAIL message);
        - `MIN_CHECKS=x` → exit 1, `MIN_CHECKS must be a whole number`; `TEST_TIMEOUT=0` → exit 1;
        - warning cases per AC-6.
      - The self-test prints `RUNNER SELFTEST RESULT: N passed, F failed` at column 0, exits 0 only if every case passes,
        asserts the scratch `TMPDIR` is empty at the end (the runner's temp log is removed), removes its own dirs in an
        `EXIT` trap, and finishes in under 90 s.
- [ ] AC-2 **CI step.** `.github/workflows/ci.yml` runs `bash AethelgardPrototype/tests/runner_selftest/test_runners.sh`
      as a step before the first test suite (no Godot needed), with a double-quoted `name:` if it contains `: ` and a
      `timeout-minutes` of 3; it prints `grep --version | head -1` first; the first CI run after the push is green and is
      recorded (its step duration and the grep version too).
- [ ] AC-3 **Line 119.** `run_tests.sh:119` reads the result with `LC_ALL=C grep -a -oE …`, like its neighbours, and the
      `ff_result` case shows the runner reads a result line that ends in 0xFF under `LC_ALL=C.UTF-8`. *Amended at code
      review (user decision [A]):* the first wording also ran the pre-fix pattern and required it to extract nothing in
      CI. That cannot hold: with `-o` grep prints only the matched text, which is plain ASCII, so the old pattern
      extracts the result on GNU grep 3.0 and 3.11 alike (verified on Git Bash and WSL Ubuntu), and a byte inside the
      match defeats the first grep too. No input the first grep accepts makes the old line 119 misbehave, so the change
      is a consistency hardening, not a bug fix, and the old-pattern check (which would have failed CI) was removed.
- [ ] AC-4 **PowerShell runner changes.** `run_phase0_tests.ps1` uses `$env:GODOT` as the executable when it is set
      (`[IO.FileInfo]`, so a missing path still reaches the launch and fails as "did not start"; the path must be
      absolute, said in the comment), else the existing `C:\Godot` lookup — with `GODOT` unset every suite runs exactly as
      before (AC-9). The launch-failure text becomes `Godot did not start, or the runner failed before reading its exit
      code` (header comment updated too). The watchdog's give-up after 10 failed queries and the `$killed = $?` line each
      get a one-line comment saying what they do. No other behaviour changes.
- [ ] AC-5 **PowerShell self-test (Windows, local).** `tests/runner_selftest/test_runner_ps.ps1` runs the real
      `run_phase0_tests.ps1` with `GODOT` set to the absolute path of `tests/runner_selftest/stub_godot.cmd` (CRLF;
      `type "%STUB_FIXTURE%"` then `exit /b %STUB_EXIT%`, touching `%STUB_MARKER%`; fixtures are text files reused from the
      AC-1 canned lines), output captured with `*>&1`, every case with `-TimeoutSec 30` (so a removed override cannot
      start the real `C:\Godot` for long). Cases, each asserting exit code, text and the marker: pass; script-error lines
      → exit 1 and `2 script error line(s)`; last result line wins; no result line with `-MinChecks 1`; `ok=N bad=M`; an
      unregistered `res://tests/*_test.gd` (marker absent); `GODOT` at a missing absolute path → exit 1 and the new "did
      not start" text; the in-process leak case — the self-test sets `$code = 0` and
      `$lines = @("X RESULT: 9 passed, 0 failed")` in its own scope and calls the runner with `&` (not dot-sourced, which
      would let its `exit` end the self-test; not `-File`), `GODOT` missing, and the runner still fails. Result line
      `RUNNER PS SELFTEST RESULT: N passed, F failed`. Its header says it is local-only (CI cannot run the PS runner) and
      that the timeout / kill cases are not covered (backlog item, AC-9).
- [ ] AC-6 **Stale-min_checks warning.** Both runners print, only when `min_checks > 0`, the suite did not time out and a
      result line exists, and `ran > min + max(2, ceil(min / 10))`, the line
      `RUNNER WARN <script>: <ran> checks ran, suite_limits.txt minimum is <min>` on stdout (prefixed `::warning::` under
      `GITHUB_ACTIONS` in bash); it never contains `RUNNER FAIL` and the exit code is unchanged. The bash self-test covers:
      min 10 with ran 13 → warning; ran 12 and ran 10 → none; min 21 with ran 24 → none, ran 25 → warning (proves the
      `ceil`); min 0 with ran 50 → none.
- [ ] AC-7 **Result-line doc.** The `tests/suite_limits.txt` header documents the result-line format the runners parse: a
      line starting at column 0 with an uppercase name of letters, digits and spaces (no underscores), then
      `RESULT: <N> passed, <M> failed` or `ok=<N> bad=<M>`; the last such line wins.
- [ ] AC-8 **Watch-fail.** In a scratch worktree, after a green control run of both self-tests, each mutation makes its
      case fail (diff and result logged): (a) `run_tests.sh` reads the first result line instead of the last → the
      `two_results` case fails; (b) the elapsed-rule condition removed → the `selfkill` case reports a timeout; (c) the
      script-error scan removed → the `script_errors` case passes Godot's 0; (d1) `-a` removed from the first listing grep
      at :102 → the NUL case fails; (d2) `-a` removed from the `grep -v '^--$'` filter → the NUL case fails; (e) `-k 10`
      dropped → the `ignore_term` case fails by assertion within the 40 s outer cap; (f) `run_phase0_tests.ps1`'s
      `$code = $null` removed → the PS leak case fails; (g) the `$env:GODOT` override removed → every PS case fails;
      (h) the warning's `>` changed to `>=` → the ran-12 case warns and fails; (i) the unregistered-suite refusal (:41)
      removed → the unregistered case fails (marker present). (The CI-only `ff_result` discrimination was dropped at code review, AC-3.)
- [ ] AC-9 **Suites and records.** The full suite (`run_all_tests.ps1`, 19 suites, no `-Quick`, `GODOT` unset) passes
      with every suite's count equal to its `tests/suite_limits.txt` minimum (ch3 flash 53) and no `RUNNER WARN` line;
      the CI log has no `RUNNER WARN` or `::warning::` line; `git diff --check` clean; `git ls-files -s` shows `100755` for
      `stub_godot.sh` and `test_runners.sh`, and `git ls-files --eol` shows `w/lf` for both (the `.cmd` stub CRLF); the stub
      sources, the fixtures and the `od -c` dump of the NUL listing kept in `production/qa/evidence/2026-10-runner-selftest/`;
      a CHANGELOG `test:` entry; at close TD-010 marked Resolved and a new register item for the PS timeout / kill cases
      (compiled `.exe` stub).

---

## Implementation Notes

- Order: the bash stub and self-test first (against the unchanged runner, so the first run shows which cases already
  pass and which need the fixes — line 119 and the warning), then the fixes, the PS override and self-test, the
  suite_limits header, the CI step, the mutations, the full suite.
- Stub modes (suggested): `pass`, `script_errors`, `exit3`, `two_results`, `two_results_reversed`, `no_result`,
  `loadall`, `sleep`, `ignore_term`, `selfkill`, `nul_listing`, `ff_result`, `many_checks`. Bytes are written with
  `printf '\0'` / `printf '\377'`.
- The fake non-GNU `timeout`: a script named `timeout` in a temp dir put first on `PATH` that prints a non-coreutils
  `--version`.
- Elapsed-rule margins: limit 2 s with 20 s stub sleeps for the timeout cases (`SECONDS` floors, so 2 s elapsed always
  reads >= 2); limit 20 s with a 1 s self-kill for the pass-through case. Every runner call sits inside
  `"$real_timeout" -k 5 40` (AC-1), so a broken runner fails a case instead of hanging CI.
- The NUL case's expected listing is four literal lines in the self-test, compared with `cmp` against the runner's
  saved output (command substitution would drop the NUL); the `od -c` dump of that output is kept as documentation only
  (it replaces the lost TD-009 `golden_n1_listing.od`).
- Stub mode `pass` with `STUB_EXIT=3` covers the non-zero exit (no separate `exit3` mode needed).
- PS self-test: in-process leak case = call the runner with `&` (not dot-sourced, not `powershell -File`) after setting
  `$code = 0` and `$lines = @("X RESULT: 9 passed, 0 failed")` in the caller's scope. Add a `*.cmd text eol=crlf` rule to
  `.gitattributes` only if the user agrees; otherwise commit the `.cmd` with CRLF and check `git ls-files --eol`.
- Commit only with the user's OK: `test(tools): permanent self-test for the test runners` with `Task: Y1-P0-TD-010` in
  the body.

---

## Out of Scope

- The PowerShell watchdog's timeout and kill paths (need a compiled `.exe` stub; backlog item at close).
- Running the PS runner in CI (Windows job), macOS / BSD tool variants, any change to how suites are written.
- TD-011 (the CI boot step's `| tee` without `pipefail`), TD-016 (ch3 flash suite follow-ups).

---

## QA Test Cases

*Reviewed by qa-lead (QL-STORY-READY, 2026-10-24: GAPS → G1-G9 adopted by the user).*

- **C1 bash self-test (AC-1)** — every listed case with exit code, text and marker; env isolated; outer cap; scratch `TMPDIR` empty; under 90 s.
- **C2 CI (AC-2, AC-3)** — the step runs before the suites; first run green; the `ff_result` case passes on ubuntu.
- **C3 PS runner (AC-4)** — override with `GODOT` set / unset; new text; two comments; nothing else in the diff.
- **C4 PS self-test (AC-5)** — the listed cases, including the in-process leak.
- **C5 warning and doc (AC-6, AC-7)** — shown / not shown cases; header text.
- **C6 mutations (AC-8)** — control green; (a)-(i) incl. d1/d2 each failing its case; diffs logged.
- **C7 suites and records (AC-9)** — 19/19 unchanged, no warning, executable bits, evidence files.

---

## Test Evidence

**Story Type**: Integration
**Required evidence**: `tests/runner_selftest/test_runners.sh` and `test_runner_ps.ps1` (passing);
`production/qa/evidence/2026-10-runner-selftest/`: both self-test logs, the mutation log, the full-suite log, the stub
sources, `golden_n1_listing.od`, the CI run, and a README mapping each AC to its file.
**Run result**: N/A — test tooling; nothing in the game changes.

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: TD-003, TD-007, TD-009 (done: the runner behaviours under test), Y1-P0-T02 (done).
- Unlocks: Y1-P0-T14b may edit `ci.yml` after this lands (sprint plan ordering); a permanent guard before T15.
