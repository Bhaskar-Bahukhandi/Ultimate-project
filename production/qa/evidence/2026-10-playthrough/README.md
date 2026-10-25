# Y1-P0-T14a evidence: the playthrough bot drives Chapter 3 to the credits

- **Story:** `production/epics/y1-p0-stabilize/story-t14a-playthrough-ch3-to-credits.md`
- **Code:** `fix/phase0-playthrough-blockers`, commits `b195732` (the bot) and `2e6aba6` (story-done review fixes). CI run
  [40192172143](https://github.com/Bhaskar-Bahukhandi/Ultimate-project/actions/runs/40192172143) on `b195732`: green, the bot step 61 s. Windows 11, Godot 4.6.3.stable console, Windows PowerShell 5.1.
- **Game code changed:** none (AC-6). New: `tests/integration/playthrough/full_playthrough_test.gd` (+ `.uid`); edited:
  `tests/suite_limits.txt`, `tests/run_all_tests.ps1`, `.github/workflows/ci.yml`, `CHANGELOG.md`.
- **Shared checkout note:** while T14a ran, another session was working on S08 (Chapter 1 rooms) in the same checkout.
  The bot's final run, the mutation runs and the full suite therefore ran in scratch worktrees at HEAD plus only the
  T14a files, so none of that in-progress work is in these results.

| Acceptance item | Result | Evidence |
|---|---|---|
| AC-1 leg table | Pass: 40 rows (6 Chapter 3 scenes + the Wastes region + 32 Chapter 4–10 scenes + the main menu); the suite's `LEGS` list is the same order, and the suite asserts each next scene | `leg_table.md`; `bot_run.log` |
| AC-2 start state | Pass: the state chapter2_route_test's careful route leaves at its Chapter 3 hand-off, printed by a copy of that suite at `74e40e8` (40 flags true — 39 seeded: `ch3_ironhold_departed` is left out because the probe ran after the departure scene, and a check asserts it is unset so leg 0 must set it —, `source_key_count` 2, level 12, Elara with the party, `ch2_data_wraith_defeated` set); seeded after `reset_game()`; the isolation guard runs first | `probe_ch2_state.gd.txt`, `probe_ch2_state.log`; `bot_run.log` (AC-2 lines) |
| AC-3 driver | Pass: option 0 at all 52 choice prompts, each answered only once its buttons are focusable (after DialogueManager's 0.5 s grace) and logged with the prompt and the option's text; skip re-armed; `ch3_ending`'s wait ended by a real `ui_accept` input event (an AC-3 check, which fails if the fallback is ever needed); the Wastes `ServerRoomGate` used only outside a transition (retried if no hand-off within 2 s); each trial at its own time scale (1) until attempt 1 has kept the player alive ≥ 3 s, then — with no hazard in flight — `_retry_requested` + `_complete_trial()` (F-2); real-time caps with a softlock report including the cap (exercised by mutations a and c); `Engine.time_scale` restored, asserted and printed by the single exit; a trial completes only while the player is alive | `bot_run.log`; `watchfail_mutations.log` (a, c) |
| AC-4 per-leg checks | Pass: 39 legs × (arrival, hand-off within the cap, no dialogue and no ContextStack entry at the scene's own `transition_started` — AC-4 amended at code review —, the table's flags incl. each `source_key_fragment_N` at the leg that grants it); the next leg is armed when the scene swaps; `source_key_count` 2 → 7; `user://save_slot_99.save` written in the isolated user dir (the suite itself writes no files) | `bot_run.log` |
| AC-5 ending and credits | Pass: ch10_ending sets `ch10_complete`, `true_ending_seen`, `ng_plus_unlocked`, `ng_plus_available`; its text contains "TRUE ENDING"; the main menu shows a visible NEW GAME+ button; `CreditsScreen.show_credits(false)` opens (credits context open) and a `ui_cancel` event closes it (stack empty, tree unpaused) | `bot_run.log` (AC-5 lines) |
| AC-6 findings | Pass: no game file changed by T14a (the `git diff --name-only` over scripts / scenes / dialogue is recorded at close, scoped to T14a's commits, because S08 is changing game files in the same checkout); findings F-1 the ending never plays CreditsScreen and the credits say "Version 1.0"; F-2 a hazard trial can write to a freed marker (a player can reach it, rarely; the bot avoids it); F-3 the Data Stream minigame has no fail state; F-4 unregistered speakers seen live (TD-019); F-5 the Source Key count is rebuilt from chapter flags from Chapter 8 on; test-side shortcuts named | `findings.md`; `bot_run1_hazard_script_error.log` (F-2 as first seen) |
| AC-7 suite and records | Pass: 172 checks, `PLAYTHROUGH RESULT`, `suite_limits.txt` 172 / 240 s (local runs 62–84 s; CI bot step 61 s), `run_all_tests.ps1` (Long), `ci.yml` step (10 min), `test_layout_test` 6/6. Watch-fail in a scratch worktree on the final code: control green 3 runs in a row (172/172 each), then mutations (a) ch5 hand-off target, (b) ch9 flag, (c) trial hand-off call, (d) ng_plus_unlocked, (e) a ContextStack leak in ch8, (f) the driver picking option 1 in ch4_null_court, (g) Source Key 5's grant removed, (h) the credits closed with ui_accept, (i) the departure scene no longer setting `ch3_ironhold_departed`, (j) `_finish` not restoring the time scale — each failing its own check, `ALL MUTATIONS CAUGHT: yes`. Earlier runs kept: `watchfail_mutations_run1.log` (a harness label off by one), `watchfail_mutations_pre_review.log` (before the code-review fixes, a–f); the a–h run before the story-done fixes is in git at `b195732`. Full suite 23/23 with `GODOT` unset (1379 s, before the code-review fixes, which touched only this suite and its `suite_limits.txt` line; CI run 40192172143 ran every suite on the committed bot), every count equal to its minimum, no `RUNNER WARN`; runner self-test 30/30; CHANGELOG entry | `watchfail_mutations.log`, `run_all.log` |

## Notes

- **Code review (CHANGES REQUIRED, all applied):** trials now run at their own time scale (the arrival wait re-applied
  4x before); trials complete only with no hazard in flight (F-2 race); the next leg is armed at the scene swap; the
  gate is used outside transitions with a retry; choices wait for the grace period and log the option text; the input
  fallback fails a check; the softlock report names the cap; shortcuts named in the header and findings; per-leg Source
  Key flags (mutation g exposed F-5); mutations (g) and (h) added; timeout 240 s.
- `ObjectDB instances leaked at exit` warnings appear for most suites, this one included (TD-012); they are WARNING
  lines, not RUNNER WARN or SCRIPT ERROR.
- **Story-done gates (2026-10-25):** QL-TEST-COVERAGE ADEQUATE; LP-CODE-REVIEW CONCERNS. Fixed in `2e6aba6`: leg 0's
  flag check could not fail (the seed held the flag), and a trial could complete with a dead player; plus an exit-state
  assertion. `bot_run.log` and `leg_table.md` timings are from the run before these fixes (170 checks); the 172-check runs
  are the control runs in `watchfail_mutations.log`. The rest is TD-026.
