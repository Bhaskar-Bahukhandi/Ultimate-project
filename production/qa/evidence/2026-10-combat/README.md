# Y1-P0-T11 evidence: dash i-frames, one hit sound, STRIKE label, last-kill slowdown

- **Story:** `production/epics/y1-p0-stabilize/story-t11-combat-feel-leftovers.md`
- **Code:** `fix/phase0-playthrough-blockers` at `c2a7451` plus the uncommitted T11 change (the commit hash is added to the
  story's Completion Notes at close time). Windows 11, Godot 4.6.3.stable console, Windows PowerShell 5.1. The plan named
  `2026-11-combat/`; the work was done in October.
- **Combat edits** were approved by the user for this task (AGENTS.md protected area), 2026-10-24.
- **Code review (2026-10-24): CHANGES REQUIRED → fixed.** Two real bugs in the first version (the deferred slowdown
  ramped the hitstop back to 1.0 before dropping to 0.12; a stale 0.4 s restore timer could slow the next scene after
  `clear_time_scale()`), plus test and evidence gaps. All logs below are from after those fixes unless named otherwise.

| Acceptance item | Result | Evidence |
|---|---|---|
| AC-1 dash i-frames | Pass: 14 invulnerable frames from rest (13–15 allowed); tail hit absorbed with HP, Soul and no perfect dodge checked; first vulnerable frame lands; in-dash hit is a perfect dodge; a dash during 0.8 s hurt i-frames (dash start asserted) keeps 0.800 and is still invulnerable 42 frames later | `combat_fixes_after.log` |
| AC-2 one sound per hit / kill | Pass: light hit 1 `sword_hit`; parry counter 1 `heavy_hit`, 0 `critical_hit`, 0 `sword_hit`; take_damage kill 1 `enemy_death` (slime and corrupted_rat); direct `die()` 1 `enemy_death` | same |
| AC-3 STRIKE label | Pass: STRIKE 1/2/3; STRIKE 3 held while `attack_cooldown > 0`, then empty; step-1 clears on the `combo_timer` lapse; empty right after `take_damage`, a charged attack (user request) and a death-retry reset (code review) | same |
| AC-4 label captures | Pass: tour stop `t11_combat_hud` (live renderer), `TOUR RESULT: 2 screenshots, 0 problems`; preconditions checked in the stop: `combo_step 2`, label `STRIKE 2`, GameJuice `2 HIT`; after `take_damage(5)` HP 100 → 95 and the label empty. Re-captured after the code-review fixes | `t11_combat_hud_strike2.png`, `t11_combat_hud_after_hit.png`, `tour.log`, `report.md`, `capture.md` |
| AC-5 last-kill slowdown | Pass: pending during the kill's hitstop; started by `_end_hitstop` (direct handover, 0.120 at once) and `_force_end_hitstop`; **no burst of speed** (peak 0.120 over 200 ms real); released ~0.6 s after 0.12 (bound 2.0 s); dropped when paused, after `clear_time_scale()`, after a scene change; **a cleared slowdown does not come back** when its timer fires; nothing pending while paused; two slimes killed back to back → one slowdown (from the last one); two requests in one frame during a hitstop plus a third while it runs → one slowdown; a boss-group kill and `apply_last_kill_slowdown(true)` start nothing, **and the same setup without the boss group starts one** (control); end-to-end arena slime kill starts a slowdown (count +1) and reaches 0.12 within 1.0 s | `combat_fixes_after.log` |
| AC-6 one time-scale writer | Pass: 130 files under `res://scripts` scanned, comments stripped, no assignment to `Engine.time_scale` outside `scripts/core/context_stack.gd`; the pattern's self-test catches `= 0.5`, `-= 0.1` and an assignment at end of line and skips comments and `==` | same |
| AC-7 watch-fail | Pass, in three parts. (1) Pre-change code (`c2a7451`) with the first version of the suite: as is, the AC-1 and AC-3 checks fail and the AC-2/AC-5 checks crash on the missing test hooks (`watchfail_no_seams.log`); with a hook-only shim that adds the signal, counter and flags with **no behaviour change** (`watchfail_seam_shim.py`), 22 passed / 16 failed (`watchfail_seam_shim.log`; this was the first, 38-check version of the suite — the checks added later are covered by part 2 and 3). The 16 failures cover every AC-1 window/hurt check, every AC-2 and AC-3 check, AC-5 a, b1, b2, e, the direct-call g check and end-to-end. The other 12 new checks (the AC-1 tail/landing/in-dash checks, AC-5 c, the three d drop rules, f ×2, the boss-kill g check, AC-6) pass on the old code by design — the old code never started a slowdown, and the old dash still had those properties. (2) The drop rules, the boss flag, the two review fixes and the retry clear are each proven by a **mutation** in a scratch worktree holding the new code: 8 mutations (M1–M8, including the same-frame dedupe guard), each makes exactly its own check fail, 44 passed / 1 failed (`watchfail_mutations.log`, `ALL MUTATIONS CAUGHT: yes`; M1 shows the pop: speed peaks at 0.838 within 200 ms of the hitstop ending, against the fixed code's 0.120). (3) The charged-attack clear fails with that one fix removed (`watchfail_charged_label.log`) | listed |
| AC-8 suites and records | Pass: `combat_fixes_test.gd` 45/45 (`suite_limits.txt` min 45; the full run below had 44, before the re-review's test-only changes); `context_stack_test.gd` 33/33; full suite 18/18, `All suites passed.` (1163 s by the launching shell's stopwatch; the log has no timing line), every other suite's count equal to `../2026-10-exit-leak/run_all.log`; `git diff --check` clean; CHANGELOG entry | `run_all.log`, `combat_fixes_after.log` |
| AC-9 play note | **Pending — the user's play session** (Aldric fight + arena bronze bracket) | `play_note.md` (to be written) |

## Notes on the logs

- **AC-5(g)** checks that a boss-group kill and a direct boss call start no last-kill slowdown, with a positive control;
  it does not run a real boss death sequence, so it does not show the boss's own `boss_death` request still appearing
  (that code is unchanged). Feel note: the tutorial knight's normal kill now plays only `enemy_death_boss` (it played
  `enemy_death` on top before); worth a line in the play note.
- **Test enemies** are built from the slime and corrupted_rat scripts in the arena's node layout (there is no slime
  scene), with their AI off and the player invulnerable during the sound checks so contact cannot cancel a swing.
- **Error lines that do not fail the suite:** "Lambda capture at index 0 was freed" at the test's stage resets (after
  `reset_game`; the same message appears in other suites' logs), the known out-of-scope `enemy_base.gd:920`
  "no meta 'flash_tween'" error, and one `[COMBAT FX] Force-ending hitstop (safety fallback)` warning, which is the test's
  own `_force_end_hitstop()` call in case b2 (the backtrace names test line 600), not a leak.
- **AssetManager warnings** in the full run: 110 `WARNING: [AssetManager]` lines, up from 102 in the T10 run, because the
  combat suite now loads the combat arena (eight more distinct one-time messages). (A count of every line merely
  containing "AssetManager" gives 128; that is not the warning count.)
- The second capture is taken one frame after the hit to prove the label clears at once, so the game's normal
  damage-glitch overlay is on it.
- `tour.log` is saved as UTF-8 (the tour writes UTF-16 under Windows PowerShell 5.1).
