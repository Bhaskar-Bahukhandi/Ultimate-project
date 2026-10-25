# TD-003 test runners fail on script errors — evidence

- **Task:** TD-003 · Fail a test suite when its output contains a SCRIPT ERROR or Parse Error
  (`production/epics/y1-p0-stabilize/story-td003-runner-script-errors.md`)
- **Code:** `fix/phase0-playthrough-blockers` at `9749085` plus the uncommitted TD-003 change to
  `AethelgardPrototype/tests/run_phase0_tests.ps1`, `run_tests.sh`, `run_all_tests.ps1` and
  `.github/workflows/ci.yml` (captured 2026-10-20, Windows 11, Godot 4.6.3 console, Windows PowerShell 5.1,
  Git Bash). `run_all.log` names the SHA-256 prefixes of the two runners it ran with.
- **Probes:** throwaway `extends SceneTree` scripts kept in the session scratchpad and never committed, as the
  task required. Each log quotes their output in full. In short: R1 passes one check, then calls a missing
  method on a `Node` inside a test function; R2 has a parse error in the script itself; R2b `load()`s a helper
  with a parse error and then `quit(0)`; R3 is clean; R7a is clean with `quit(3)`; R7b has a script error and then
  `quit(3)`; R8 prints lowercase and mixed-case look-alikes; R9 prints two adjacent `SCRIPT ERROR` lines.
- **"OLD" runners** are `git show HEAD:<path>` copies with only the project-path line pinned (they locate the
  project from their own folder).

| Acceptance item | Result | Evidence |
|---|---|---|
| AC-1 PowerShell runner: each line once and in order; exit 1 on a match when Godot exited 0, Godot's code otherwise; `RUNNER FAIL <script>: <N> script error line(s)` plus each match and the line after it | Pass. R1 and R2b: OLD exit 0, NEW exit 1 with the summary. R7b: NEW exit 3 with the summary. R3, R7a, R8: identical line counts OLD and NEW, no summary. Every failing run has exactly 4 more lines than OLD (blank, summary, match, `at:` line), so no Godot line is lost or doubled | `probe_matrix_ps.log` (SUMMARY at the end) |
| AC-2 bash runner (CI): the same verdicts and text; `::error::` only under `GITHUB_ACTIONS=true`; temp log and isolated dir removed, on the failing path too | Pass under Git Bash: the same exit codes as PowerShell for all probes. R1 with `GITHUB_ACTIONS=true` adds the `::error::` line and R3 with it adds none. 0 entries are left in a fresh `TMPDIR` after every run | `probe_matrix_sh.log` |
| AC-3 isolation unchanged | Pass. No run in either matrix changed the number of `aeth_phase0_test_*` dirs (before = after). The two dirs present during the in-process check belonged to runs going on at the same time: the full suite and a code reviewer's probe. `APPDATA` is restored after a failing (R1) and a clean (R3) run, with the runner invoked **in-process** so the restore is observable (in a child process it cannot leak either way) | `probe_matrix_ps.log`, `probe_inprocess_appdata.log` |
| AC-4 probes old vs new | Pass. R2b is the case the change exists for: Godot prints `SCRIPT ERROR: Parse Error`, `load()` still returns non-null and the process exits 0, so the OLD runner passes it and the NEW runner fails it | the three logs above |
| AC-5 full suite, all 16, no `-Quick` | Pass on the final code: `All suites passed.`, exit 0, 18 min 48 s; 0 `SCRIPT ERROR` / `Parse Error` / `RUNNER FAIL` lines. Every per-suite count equals the last green run (`2026-10-flash/run_all.log`); `load_all` ok=206 bad=0 | `run_all.log` |
| AC-6 `git diff --check` clean; TD-003 Resolved | Pass | `docs/tech-debt-register.md` (TD-003) |
| AC-7 first CI run green on all 16 test steps | Pass (2026-10-24): run #29 on `336f7fb`, `ubuntu-latest`, 18 min 33 s, all 16 test steps, the boot check and the whitespace and commit-message steps green; this is the only check of Linux `XDG_DATA_HOME` isolation. The first push after the change (`eaa330e`, run 40045950890) had no jobs because ci.yml did not parse; `336f7fb` quoted six step names and changed no step | https://github.com/Bhaskar-Bahukhandi/Ultimate-project/actions/runs/40049178997 |

## Code-review follow-ups

- **Listing dedupe** (suggestion 1, applied): with two adjacent matches, PowerShell's `-Context 0,1` printed the
  second line twice. On the runner without the fix R9 lists line B twice; with it, the listing matches bash's
  `grep -A1`. R1, R7b and R3 are unchanged after the fix. Evidence: `probe_dedupe.log`. The full-suite run above
  ran on this final code.
- **Not caught, recorded as TD-007:** a script error in the same function as `quit()` hangs Godot. This was
  watched on the OLD and the NEW runner, so it predates TD-003: `probe_hang.log`. The new runner prints the
  summary once the hung process is stopped. Also not caught: failures that print only `ERROR:` (`push_error`, a
  missing resource, an unknown signal), and a function that returns early without an error.

Not retained: an earlier full run on the code before the dedupe (16/16, the same counts, 0 matches) was
superseded by `run_all.log`. The first old-runner probe logs are superseded by the OLD columns of the matrices.
