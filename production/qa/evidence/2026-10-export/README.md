# TD-022 evidence: the export smoke check reads the game's exit code under Windows PowerShell 5.1

- **Story:** `production/epics/y1-p0-stabilize/story-td022-export-exit-code.md`
- **Code:** commit `c9f694f` on `fix/phase0-playthrough-blockers`; `AethelgardPrototype/tools/export_windows.ps1` there
  has SHA-256 `a7266698eec8e03687616cac2979aa3cd4d80405bf9c8d52ae136ad13e85235c` (checked at close against the
  committed blob). Windows 11, Godot 4.6.3.stable, Windows PowerShell
  5.1.26100.9711, PowerShell 7.6.9, NVIDIA GeForce RTX 2050 (Vulkan, Forward+).
- **Game code changed:** none. Only the export script, the CHANGELOG, the register row, the story, its sprint-status
  entry and this folder.
- **Which script each log is from:** `before_release_ps51.log` is from the unfixed script, on purpose. Every other log
  is from the final script: each `ac4_*.log` ends with the shell, its version and the script's SHA-256, and each
  `ac5_*.log` starts with the SHA-256 of the script under test (working tree) and of the mutant — all name `a7266698…`.
  The five builds and mutations (a)–(u) ran one after another on 2026-10-26, followed by a `%TEMP%` check.

| Acceptance item | Result | Evidence |
|---|---|---|
| Before the fix | The unfixed script, release build under 5.1: `FAILED: - exit code ` (empty), exit 1, although the game booted and exited | `before_release_ps51.log` |
| AC-1 exit code read | Pass: `$null = $p.Handle` on the line after `Start-Process`; release runs return 0 under 5.1 (`RELEASE OK`); a process that exits at once returns its code (b: `exit code 3`, no exception). `Code = -1` on a timeout is the unchanged return line (read, not logged) | `ac4_release_ps51.log`, `ac5_b.log` |
| AC-2 unreadable code is its own failure, checked first; the tour's pass rule | Pass: with the handle line removed, release prints `exit code unavailable (PowerShell could not read it)` (a), and the tour prints it followed by its `TOUR RESULT` line (e); with no `TOUR RESULT` line and no handle, the tour prints `exit code unavailable`, not `never started` (i); with no `TOUR RESULT` line and a readable code 0, `the tour never started or never finished (exit code 0)` (m); a real non-zero code prints `exit code 3` (b). A tour passes only at code 0 with at least one screenshot and `0 problems`: a non-zero tour prints its `TOUR RESULT` line and `(see …\report.md)` on one line (f), followed by `; exit code N` whenever the code is non-zero (f: `; exit code 1`; o: `; exit code 3` with a `0 problems` result); a tour reporting a problem at exit 0 fails (j); a tour with `0 screenshots, 0 problems` at exit 0 fails (n) | `ac5_a.log`, `ac5_e.log`, `ac5_i.log`, `ac5_m.log`, `ac5_b.log`, `ac5_f.log`, `ac5_o.log`, `ac5_j.log`, `ac5_n.log` |
| AC-3 timeout stops the tree without crashing | Pass. A logging line after the `taskkill` call in `Stop-Tree` shows each path: live `-Tour` build (c) and the same with no diagnostic pauses (k): `taskkill exit 0`; (c) logs the wrapper and game PIDs before the stop and none running at 5 s and 10 s; (k) leaves no new `aeth_phase0_test_<guid>` folder in `%TEMP%`. A process that had already exited (g): `taskkill exit 128`, `HasExited True`, exit 1, no exception. `taskkill` failing on a live process (h, a PID that does not exist): `taskkill exit 128`, then the `Kill()` fallback stops it (`FALLBACK … HasExited=True`); `taskkill` unable to start (l): `taskkill exit -1` (the reset), then `Kill()` stops it. The log held open by another process for 2 s (p, lock confirmed: `LOCK: held=True`): no warning, and the stub's stderr marker is in `smoke.log` afterwards — the merge completed after the lock was confirmed (that its first attempt met the lock is inferred: only `taskkill` and the folder removal run between the confirmed lock and the merge; attempts are not logged). Held for 8 s (q): `could not add the game's stderr …` in the FAILED list, the marker absent, the timeout failure still listed, no exception. A file in the isolated `user://` held for 8 s (r): `WARNING: could not remove the isolated user:// folder …`, no exception. **Fail closed on a run that finished** (fourth review): a passing tour whose stderr file is held right after it exits (s) ends `FAILED: could not add the game's stderr … its errors were not checked`, exit 1 — the same run with the previous warn-only code (u) ended `TOUR BUILD OK`, exit 0; a passing tour whose log itself is held (t) lists `could not read …`. In (q) the merge failure is a listed failure too | `ac5_c.log`, `ac5_k.log`, `ac5_g.log`, `ac5_h.log`, `ac5_l.log`, `ac5_p.log`, `ac5_q.log`, `ac5_r.log`, `ac5_s.log`, `ac5_t.log`, `ac5_u.log`, `r_temp_after.txt` |
| AC-4 real builds under both shells | Pass, one after another: release under 5.1 and 7 (`RELEASE OK: booted, ignored --debug-tour, exited cleanly`, exit 0); `-Tour` under 5.1 and 7 (`TOUR RESULT: 68 screenshots, 0 problems`, `TOUR BUILD OK`, exit 0); `-NoSmoke` under 5.1 (`BUILD OK`, exit 0). No `Aethelgard*` process before or after any run. `smoke_boot.png`: boot text at 0.5 s, title at 3.0 s, the main menu at 6.0 s and 11.9 s (AETHELGARD / The Glitch Sovereign; NEW GAME, LOAD GAME, OPTIONS, CREDITS, QUIT; `v0.1.0`). **Sign-off (user): signed off 2026-10-26.** The final 5.1 release run's capture is byte-identical to the signed-off file (both SHA-256 `2250e3b4…`), so the signed-off file is kept | `ac4_release_ps51.log`, `ac4_release_ps7.log`, `ac4_tour_ps51.log`, `ac4_tour_ps7.log`, `ac4_nosmoke_ps51.log`, `smoke_boot.png`, `smoke_boot_compare.txt` |
| AC-5 watched failing (5.1, a copy `tools/export_windows_mut.ps1`, deleted after) | Pass: (a)–(u) all caught, `ALL CAUGHT: yes`. Each log starts with the two SHA-256 values, every edit in full (OLD / NEW), the `Aethelgard*` process counts and the `%TEMP%` `aeth_phase0_test_<guid>` folder counts before and after; then the script's stdout and stderr. (h)–(l) were added at the first code review, (m) and the `STOPTREE` logging line at the second, (n)–(r) at the third, (s)–(u) at the fourth | `ac5_a.log` … `ac5_u.log`, `ac5_summary.log`, `harness_td022_mutations.py.txt` |
| AC-6 records | Usage comment names both shells; TD-022 resolved in `docs/tech-debt-register.md` (29 items, 22 open); CHANGELOG `fix(tools)` entry; `git diff --check` clean | this README |

## Notes

- **Found during /dev-story and the four code reviews (fixed here; in `Invoke-Built`, the new `Stop-Tree` and
  `Test-Until` helpers and the tour check):**
  - **The tour's `TOUR RESULT` and `PROBLEM` lines kept a CR.** The game's own `tour.log` ends every line with CR LF
    (`real_tour_ps51_line_endings.txt`; the `TOUR RESULT` line ends `problems\r\n`). The old `.*` matches kept the CR,
    so a failing tour's `(see …\report.md)` landed after a carriage return. Both matches are now `[^\r\n]*`. The
    `PROBLEM`-line change is shown by reading (the real tour had 0 problems and no stub prints a `PROBLEM` line); it is
    the same change that (f) and (j) show for `TOUR RESULT`. **The CR LF in `real_tour_ps51.log` will not survive a
    commit** (`.gitattributes` `* text=auto` normalises it to LF), so the `.txt` record, taken from the raw file, is the
    evidence.
  - **A game that printed nothing crashed the script** (`ArgumentNullException` from `[regex]::Match`, because
    `Get-Content -Raw` of an empty log is `$null`; found by mutation i). This predates TD-022. The log text is now a
    `[string]`.
  - **A timed-out run left its isolated `user://` in `%TEMP%`**, and the stderr merge could meet a locked log. Both now
    retry for up to 5 s after a timeout (`Test-Until`, the same rule as `tests/run_phase0_tests.ps1`; one try for a run
    that finished); a folder left behind is a warning, (k) and (r) show it. A stderr merge that still fails, or a
    non-empty log that cannot be read, is a **failure** naming the log, not a warning (fourth review): with only a
    warning, a run that finished could pass with the game's errors unchecked — (u) shows the previous code doing exactly
    that, (s) and (t) the fix, (p) and (q) the retry on a timed-out run. The three `aeth_phase0_test_<guid>` folders left by the earlier runs are still
    in `%TEMP%` (the user declined their deletion), so the counts read 3 before and 3 after. In (r) the count reads 4
    afterwards because the test's own holding process deletes the folder after letting go, a few seconds after the
    harness counts; `%TEMP%` was back to the 3 old GUID folders when checked 15 s after the last mutation
    (`r_temp_after.txt`).
  - **A tour that reports a problem, or takes no screenshot, now fails even at exit code 0** (j, n). Whether
    `Aethelgard.console.exe` passes on a non-zero exit code is unproven (the real tour only ever exited 0, and the stubs
    in (f), (j), (n), (o) start `cmd.exe` directly), so the `TOUR RESULT` text is checked as well: a wrapper that always
    returned 0 would still fail a bad tour. A `-Only` filter that matches nothing used to pass with
    `0 screenshots, 0 problems`. A non-zero exit code is named in the failure (o).
  - **A `$null` exit code no longer hides the tour's result**: the unavailable message carries the `TOUR RESULT` line (e).
  - **`$LASTEXITCODE` is reset before `taskkill`** (l): a `taskkill` that cannot start no longer reads an earlier
    command's 0 and skips the `Kill()` fallback.
- **Test corrections kept on record.** In an earlier run the (p)/(q) stub wrote nothing to stderr, so the merge never
  opened the locked log: (q) failed its expectation and (p) passed without testing anything; the stub now writes a
  marker to stderr and the harness reads `smoke.log` afterwards for it. (s) locks the stderr file, not the log: with
  the log itself locked, even the previous code fails a tour (no readable `TOUR RESULT`), so only a locked stderr file
  shows the fail-open case. All logs here are from the final run, after these corrections.
- **Audit fact 6 disproved (AC-5 d).** With the old `$p.Kill()` the game (`Aethelgard.exe`, child of
  `Aethelgard.console.exe`) was still listed straight after the kill and gone by the 5 s check, the same as with
  `taskkill /F /T` (c). Why is not known from this evidence (the wrapper imports the Windows job-object API, so the
  system may stop the child; not verified). The story's fact 6 is corrected; `taskkill /F /T` stays as the more direct
  form. The `Kill()` fallback stops only the process it started (in (h) and (l) the `ping` started by `cmd.exe` ran on);
  for the real game it relies on the wrapper, as (d) shows.
- **A late handle read does not throw** (`late_handle_ps51.log`, script inline): reading `$p.Handle` 800 ms after a 5.1
  process has exited returns normally in 5 of 5 runs and `ExitCode` stays `$null`, so such a run is reported as
  `exit code unavailable` (AC-2), not as a script error.
- **Audit facts 1 and 7 re-run:** `repro_ps51_ps7.log` (null `ExitCode` without the handle under 5.1, 0 / 3 with it;
  PowerShell 7 unaffected; `taskkill` on an exited PID throws under `Stop` and returns 128 under `Continue`; `Kill()` on
  an exited process throws), with both repro scripts inline.
- Not shown by any log: a readable non-zero tour code with no `TOUR RESULT` line ((m) covers code 0); the timeout paths
  under PowerShell 7 (the story asks for 5.1; under 7 only the passing paths ran, AC-4); whether the merge's first try
  in (p) met the lock (inferred; attempts are not logged); a non-zero code through the real console wrapper.
- Every mutation run exported its own build first (each log has its `Exporting …` and `Built …` lines). Mutations ran
  under Windows PowerShell 5.1 only, as the story specifies.
- `ObjectDB instances leaked at exit` in the smoke logs is TD-012, unchanged.
- Trailing spaces in these logs are raw output; `.gitattributes` exempts `production/qa/evidence/**/*.log` from the
  whitespace check.

## Re-run protocol (QL-TEST-COVERAGE at close)

There is no automated test for this script (decision D2: it needs Windows, a real renderer and an export). **Any change
to `AethelgardPrototype/tools/export_windows.ps1` re-runs at least** the AC-4 builds (release and `-Tour` under
`powershell` and `pwsh`, `-NoSmoke`) and mutations (a), (b), (e), (g), (s) and (u), and checks that each log names the
new script's SHA-256. How:

- `rerun_td022.sh.txt` — the bash wrapper that ran the five builds (it appends the `EXIT`, process-count and shell /
  SHA-256 lines to each `ac4_*.log`), copied the game's `tour.log`, compared `smoke_boot.png`, ran the harness and the
  final `%TEMP%` check.
- `harness_td022_mutations.py.txt` — the mutation harness (`python harness.py a b e g s u` runs a subset; every edit
  must match the script exactly once, so a changed script makes it stop at the edit that no longer applies).
- Both scripts carry this machine's absolute paths; change `ROOT` / `SCR` first. A full run takes about 35 minutes
  (each mutation exports a build; each tour opens a game window).
