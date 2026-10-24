# Y1-P0-TD-004 evidence: the Chapter 3 scenes' own flash lines run, headless

- **Story:** `production/epics/y1-p0-stabilize/story-td004-ch3-flash-runtime.md`
- **Code:** `fix/phase0-playthrough-blockers` committed as `5dcd64b` (on top of `4f28fb1`). CI run
  [40109275299](https://github.com/Bhaskar-Bahukhandi/Ultimate-project/actions/runs/40109275299) on `5dcd64b` is green: all 19 test steps, the new suite in 25 s on Linux. Windows 11, Godot 4.6.3.stable console, Windows PowerShell 5.1.
- **Game code changed:** only the test seam in `scripts/effects/scene_transition_manager.gd` (a `flash_started` signal and
  one emit line in `flash()`). No Chapter 3 script, flash call, save, story flag or Source Key code changed.

| Acceptance item | Result | Evidence |
|---|---|---|
| AC-1 test seam | Pass: `signal flash_started(color: Color, duration: float)` with a `##` test-seam comment; emitted in `flash()` right after the overlay's colour and alpha are set, before the fade tween (amended during /dev-story, user decision 4); the doc comment also says handlers must stay synchronous and read-only (code review); the file's diff is those lines only | `git diff` of the file; `ch3_flash_runtime.log` ("AC-1 seam") |
| AC-2 archive | Pass (final suite run: 53/53): hand-off after ~8.2 s; exactly 5 emissions in order — `(0.3, 0.5, 0.8, 0.3) 0.5`, `(0.5, 0.3, 0.1, 0.3) 0.5`, `(0.8, 0.2, 0.2, 0.3) 0.5`, `(0.2, 0.6, 1.0, 0.4) 0.8`, `(0.3, 0.7, 1.0, 0.5) 1.0` | `ch3_flash_runtime.log` |
| AC-3 wastes | Pass: with `ch3_server_room_unlocked`, exactly 1 emission `(0.2, 0.6, 1.0, 0.5) 0.8` (hand-off ~5.2 s); control from a fresh game: exactly 0 emissions before the hand-off (~2.5 s) | same |
| AC-4 Ironhold | Pass: exactly 1 emission `(0.2, 0.8, 0.2, 0.4) 0.5` (hand-off ~5.8 s) | same |
| AC-5 visible path | Pass: for each scene's first flash, read in the `flash_started` handler: overlay colour equals the emitted colour, `modulate.a` = 0.8 (got 0.80000001), global rect (0, 0, 1280, 720) covers the viewport | same |
| AC-6 driver and isolation | Pass: isolation guard; archive exactly 6 choices answered and `kaelthas_allied` true (plus the story flag) at the hand-off; wastes, control and Ironhold 0 choices; each case stops on the scene's own `transition_started` (no 20 s cap hit), resets between cases, with a check that each hand-off transition finished before the reset (code review; 6 such checks); the driver keeps skip requested while a choice prompt is still typing, and a failed scene load stops the case at once; private DialogueManager members, freed-scene logs and the real auto-saves / flags / Source Keys named in the suite header | same; suite header |
| AC-7 watch-fail by mutation | Pass: a control run (unmutated worktree, 53/53, green), then 10 mutations, each failing as specified, with the diff applied recorded in the log — (a) archive floor-3 flash removed → AC-2; (b) wastes colour changed → AC-3 (plus the AC-5 colour line for that scene); (c) emit removed → AC-2, AC-3 and AC-4 all fail (24 passed / 13 failed); (d) Ironhold flash removed → AC-4 (plus the AC-5 read for that scene); (e) overlay colour line removed → only the three AC-5 colour checks; (f) archive `:603` duration 1.0 → 0.1 → the AC-2 flash #5 duration check; (g) wastes gate forced open → the AC-3 control; (h) archive floor-1/2 colours swapped → the AC-2 flash #1 and #2 colour checks (plus the archive AC-5 colour line); (i) `modulate.a` set to 0.5 → only the three AC-5 alpha checks; (j) the overlay shrunk to 10×10 before the emit → only the three AC-5 covers-the-viewport checks (both added at code review). `ALL MUTATIONS CAUGHT: yes` | `watchfail_mutations.log` |
| AC-8 registration, suites, records | Pass: `.uid`; `suite_limits.txt` 53 / 120 s (28 s measured); `run_all_tests.ps1` "all 19 suites"; `ci.yml` step "Chapter 3 flashes (…)" (quoted name, 10-minute timeout); `test_layout_test` 6/6; `load_all` 204; `screen_flash_test` 107/107; full suite 19/19, `All suites passed.` (1185 s by the launching shell's stopwatch; it ran the suite at 47 checks, before the code-review additions, which touched only this suite and a doc comment — the final 53/53 is `ch3_flash_runtime.log`), every other suite's count equal to `../2026-10-combat/run_all.log` except combat_fixes at 45 (its final count from T11's re-review; that log's full run had 44); `git diff --check` clean; CHANGELOG `test:` entry. TD-004 marked Resolved in the register at close (2026-10-24) | `run_all.log`, `ch3_flash_runtime.log` |

## Notes on the logs

- **AC-5 amendment:** a `call_deferred` read (the story's first wording) saw alpha 0.71–0.75, because each scene calls
  `flash()` from a resumed timer await and the tween's first step runs before a deferred read. The user chose to move
  the emit to just after the overlay is set, so the handler reads exactly 0.8 synchronously (story decision 4).
- **What the driver exercises:** option 0 at every archive choice, so the Kaelthas *ally* branch; the betrayal fight is
  not run by this suite. The beats really auto-save, set Chapter 3 flags and collect Source Keys 3 and 4, all inside the
  runner's isolated `user://`, and each case resets the game before the next.
- **No error lines from the suite:** the final `ch3_flash_runtime.log` has no `SCRIPT ERROR`, no
  "class instance is gone" line, and none of the six boot-time `get_node()` errors the story expected in this run.
  The usual missing-production-art fallback warnings and an "ObjectDB instances leaked at exit" warning (TD-012) appear.
- **Not a screenshot story:** nothing new is drawn; the flashes' look was captured under T08
  (`../2026-10-flash/`), and AC-5 checks the overlay in the real scenes.
