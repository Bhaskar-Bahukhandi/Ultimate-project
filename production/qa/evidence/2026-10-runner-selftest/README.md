# Y1-P0-TD-010 evidence: a permanent self-test for the test runners

- **Story:** `production/epics/y1-p0-stabilize/story-td010-runner-selftest.md`
- **Code:** `fix/phase0-playthrough-blockers` at `b14c956` plus the uncommitted TD-010 change, after the /code-review
  fixes (the commit hash and the CI run are added at close time). Windows 11, Git Bash (GNU grep 3.0, GNU coreutils
  timeout 8.32), WSL Ubuntu (GNU grep 3.11, coreutils timeout 9.4, bash 5.2: the CI tool versions), Windows
  PowerShell 5.1, Godot 4.6.3.stable console for the full suite only.
- **Game code changed:** none. Only the two runners, `tests/suite_limits.txt` (header), `.github/workflows/ci.yml` (one
  step), `.gitattributes` (`*.cmd text eol=crlf`, so the stub keeps its CRLF bytes on a fresh clone with
  `core.eol=lf`; user decision during /dev-story) and the new `tests/runner_selftest/` folder.

| Acceptance item | Result | Evidence |
|---|---|---|
| AC-1 bash self-test | Pass: `RUNNER SELFTEST RESULT: 30 passed, 0 failed`, exit 0, 38 s (limit 90 s) on Git Bash; the same 30/30 under WSL Ubuntu with `GITHUB_ACTIONS=true`. Every case named in AC-1 is present, plus a `::warning::` case, a result-then-hang case and a `MIN_CHECKS=08` case (code review); the runner's scratch `TMPDIR` is empty at the end | `bash_selftest.log`, `bash_selftest_wsl_ci.log`; `stub_godot.sh` |
| AC-2 CI step | Written: step "Runner self-test (run_tests.sh against a stub Godot)" before the first suite, `timeout-minutes: 3`, prints `grep --version` first. The CI run is recorded at close | `ci.yml` diff; CI run (at close) |
| AC-3 line 119 (amended at code review) | Pass: line 119 reads with `LC_ALL=C grep -a -oE`, and `ff_result` (0xFF ending a valid result line, `LC_ALL=C.UTF-8`) reads the result, exit 0. The old-pattern check was dropped: with `-o` the old grep still extracts the result on grep 3.0 and 3.11 (it prints only the ASCII match), so it could never discriminate and would have failed CI. The change is a consistency hardening | `bash_selftest.log`, `bash_selftest_wsl_ci.log`; story AC-3 |
| AC-4 PS runner | Pass: `$env:GODOT` override through `[IO.FileInfo]` (absolute path, said in the comment), which prints `GODOT override: <path>` (code review); the new "did not start, or the runner failed before reading its exit code" text (header too); comments on the 10-query give-up and `$killed = $?`. With `GODOT` unset all 19 suites ran as before (AC-9), and after the review changes `test_layout_test` still gives 6/6 with no override line | `git diff`; `run_all.log` |
| AC-5 PS self-test | Pass: `RUNNER PS SELFTEST RESULT: 17 passed, 0 failed`, exit 0, ~10 s. The CRLF `stub_godot.cmd`, fixtures reused from the AC-1 lines, `-TimeoutSec 30` on every case, the in-process leak case through `&` (marker asserted absent since code review). Header says local-only and that timeout / kill cases are not covered | `ps_selftest.log`; `stub_godot.cmd`; `ps_fixtures/` |
| AC-6 warning | Pass in both runners: bash 13/10 warns, 12/10, 10/10, 24/21 none, 25/21 warns, min 0 none, `::warning::` under GitHub Actions, none after a timeout even with a result line printed, `08` read as 8; PS 13/10 warns, 13/11, 13/13, 13/0 none, exit 3 kept | both self-test logs |
| AC-7 result-line doc | Pass: the `suite_limits.txt` header documents the column-0 uppercase name (letters, digits, spaces, no underscores), the two forms, and that the last line wins. The Godot reviewer grepped all 19 suites: each matches | `suite_limits.txt` diff |
| AC-8 watch-fail | Pass: green controls, then 15 mutations each failing its case — (a) first result line, (b) elapsed rule, (c) script-error scan, (d1) `-a` on the `-A1` grep, (d2) `-a` on the `^--$` filter, (e) `-k 10`, (h) `>`→`>=`, (i) unregistered refusal, (j) the `10#` normalisation, (k) the timed-out guard, (f) PS `$code = $null`, (g) PS override (15 of 17 PS cases fail; the CRLF check and the unregistered case do not reach the exe), PS (h), PS (i), and (l) the PS override line. `ALL MUTATIONS CAUGHT: yes`. The first run did not catch (e) (`watchfail_mutations_run1.log`): without `-k`, GNU timeout still exits 124 once the 20 s sleep ends, so the `ignore_term` case now also asserts the runner returned in under 17 s (user decision during /dev-story) | `watchfail_mutations.log`, `watchfail_mutations_run1.log` |
| AC-9 suites and records | Pass locally: full suite with `GODOT` unset, 19/19, `All suites passed.`, 1169 s, every count equal to its `suite_limits.txt` minimum (ch3 flash 53), no `RUNNER WARN` / `RUNNER FAIL` line. This run predates the code-review changes, which touched `run_tests.sh` (CI only), the override branch of the PS runner (not taken with `GODOT` unset) and the self-tests. Git modes, eol, the CI log check and the register update are done at commit / close | `run_all.log`; `nul_listing_od.log` |

## Notes

- **0xFF placement:** the story's AC-1 put the 0xFF byte "inside the name". A name with that byte is not a result line
  at all under `LC_ALL=C` (`[A-Z0-9 ]`). The stub puts the byte at the end of a valid result line instead (the end is
  not anchored); story AC-1 amended.
- **Code review (CHANGES REQUIRED, all applied):** R1 the old-pattern CI gate would have failed on ubuntu's grep 3.11
  (dropped, AC-3 amended); R2 `MIN_CHECKS=08` broke the warning arithmetic as octal (`10#`, new case, mutation j);
  R3 `stub_godot.sh` must be committed as 100755 (`core.fileMode=false`), done at commit; S1 the PS runner names a
  `GODOT` override (mutation l); S2 the timed-out case now prints a result line before hanging (mutation k).
- **Not covered:** the PS runner's timeout and kill paths (they need a compiled `.exe` stub); logged as a backlog item
  at close. The stub's bare `Parse Error:` line differs from real Godot's `SCRIPT ERROR: Parse Error:` (stderr, exit 1);
  the runner pattern matches both.
- `nul_listing_od.log` is documentation only; the self-test compares the listing byte for byte with `cmp`.
