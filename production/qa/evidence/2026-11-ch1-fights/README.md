# Evidence: Y1-P0-T13a — The opening slime is a real side-scroll fight

Story: `production/epics/y1-p0-stabilize/story-t13a-slime-fight.md`

The forest backdrop is **procedural** (`ColorRect` sky, ground, path and trees in the Elara meeting's colour values),
not production art. The shards are `ColorRect`s, too. ComfyUI used: **No**. No art was generated for this story
(AGENTS.md art truth gate). Production-art fallback: unchanged (the capture log shows the existing
`[AssetManager] … using generated fallback` warnings for Kaelen and the slime).

## Acceptance criteria → evidence

All logs below were made on the final code (after the `/code-review` fixes) unless the Runs table says otherwise.
Logs from before the review keep a `_pre_review` suffix.

| AC | What | Evidence |
|---|---|---|
| AC-1 | Hand-off: both metas at the hand-off, the next scene is the arena; the resumed meeting never loads the arena | `run_all_final.log` (CH1: "the story-fight metas hold at the hand-off", "T13a start is not replayed … the arena is never loaded") |
| AC-2 | Story-fight mode: metas consumed, one `StoryFightSlime`, backdrop colours and the path drawn on the ground, controls label, COMBAT, no CutsceneManager, kit refused, rewards and drops suppressed, default mode without metas | `story_fight_test_final_1.log` (18 `AC-2` checks, + encounter/boss mode checks) |
| AC-3 | Win: 7 shards, `_resolved` guard, flags once, XP/gold/inventory unchanged, HP kept, one `COMBAT_EXIT` no sooner than the shard fade, `story_fight_resolved("win")` | `story_fight_test_final_1.log` (14 `AC-3` checks) |
| AC-4 | Death is a retry with a fresh slime; a pounce in flight across the retry never acts; 3 retries; D5 (the player dead first) | `story_fight_test_final_1.log` (14 `AC-4`, 3 `D5` checks) |
| AC-5 | Resume at `after_slime`, Kaelen at (490, 420), 7 shards fade, save/load in the meeting, no arena; save refused in the arena; **with both flags set it also resumes (D8)** | `run_all_final.log` (CH1 `T13a` checks) |
| AC-6 | Pause holds the retry and the slime; Root Access refused while paused; metas removed on read and cleared by a load | `story_fight_test_final_1.log` (5 `AC-6` checks, + the AC-2 meta check) |
| AC-7 | Pad-only win; pad glyphs in the controls line; pad kit bindings refused | `story_fight_test_final_1.log` (3 `AC-7` checks, + the AC-2 kit check) |
| AC-8 | New suite and route-test extension, registered in `suite_limits.txt`, `run_all_tests.ps1`, `ci.yml`; the player dying during the shards and during `COMBAT_EXIT`; full suite green at its minimums | `story_fight_test_final_1.log` (4 `AC-8` checks); `run_all_final.log` (25/25 after round 1; `STORY FIGHT` 62, `CH1` 413); after round 2: `story_fight_test_final_1.log` (63/0), `chapter1_route_test_final.log` (413/0) |
| AC-9 | Screenshots, mutations (a)–(v), CHANGELOG, `git diff --check` | Screenshots below; `t13a_watchfail_mutations.log` + `_fqt.log` + `_jorsuv.log`; `AethelgardPrototype/CHANGELOG.md`; `git diff --check` clean (console) |

Two points in the suite differ from the story text:

- Mutation (h) "the metas are not removed on read" is mapped to AC-6 in the story. Its check is named `AC-2 both story
  metas are removed when the arena reads them` in the suite, because AC-2 requires consume-on-read.
- AC-3's 0.6 s shard fade is in the fight table (`shard_fade`), but it runs in **real time**, not game time, and the
  arena's wait for it does too (`create_timer(shard_fade, false, false, true)`: pause-aware, ignores time scale).
  The kill's slow motion stretched the game-time fade until the shards never left the death flash (see Findings).
  The slime spawns at x 760, not the story's "at the right" x 900, so it is in the first frame.

## Screenshots (live renderer, not headless)

All four are from a real 1280x720 window (Godot 4.6.3, Vulkan 1.4.329 Forward+, NVIDIA GeForce RTX 2050), driven by
`t13a_capture.gd.txt` through the real hand-off path: the story metas are set as the meeting sets them, then
`SceneTransitions.change_scene` to the arena, and the win returns to the real Elara meeting. None is from `--headless` or
the dummy renderer. The orchestrator opened each one before showing it to the user.

The four files here are **capture 5** (`capture_5.log`), one run on the final code after the `/code-review` fixes:

| File | Shows |
|---|---|
| `slime.png` | The fight: Kaelen left, the slime in the first frame, HUD, forest backdrop with the dirt path on the ground, the keyboard controls line above the action buttons |
| `slime-controls-pad.png` | The controls line after one pad A press: `Left Stick — Move \| A — Jump \| RT — Dash \| X — Attack \| RB — Parry` |
| `slime-shards.png` | 0.3 s after the kill: the 7 shards spread clear of the death flash |
| `slime-resume.png` | The meeting's resume staging: Kaelen at (490, 420), the meeting's own 7 shards, `after_slime`'s first line |

**Sign-off history (user, 2026-10-29):**

- Capture 3: the user signed off `slime.png`, `slime-controls-pad.png` and `slime-resume.png`. For the shards shot the
  user chose **"Make it readable"**; the fix and capture 4 followed, and the user signed off capture 4's
  `slime-shards.png` (`capture_3.log`, `capture_4.log`).
- `/code-review` then found that the backdrop's dirt path was never drawn (it sat behind the opaque ground; the
  signed-off shots show no path). After the fix, capture 5 replaced all four files. The user signed off
  all four capture-5 shots (2026-10-29).

## Findings made through the screenshots (fixed, with checks watched failing)

The first live capture showed defects that no headless check had caught. Each fix has a check, and each check was run
against the code before the fix:

| Defect seen | Fix | Check | Watch-fail |
|---|---|---|---|
| Grey void beside the backdrop: the camera follows the player with no limits, so it shows up to 640 px past each wall | The backdrop extends `backdrop_margin` (700, 400) past the arena on every side; trees added outside. Camera limits were not used because they also clamp the offset, which kills screen shake | `AC-2 the camera's view at the spawn and at both walls stays inside the forest backdrop` | `story_fight_test_framing_watchfail.log` (49/3) |
| The slime spawned off-screen (x 900; the first frame shows x up to 840) | `enemy_spawn` (760, 400) | `AC-2 the slime starts inside the first frame` | same log |
| The controls line drawn behind the HUD's action buttons (y 650–708) | Label at y 612 | `AC-2 the controls line sits above the HUD's action buttons` | same log |
| Shards illegible: small, under the death flash, and bunched because the kill's slow motion stretched the game-time tween | Real-time tween and wait, `shard_size` 12, `shard_z` 20 | `AC-3 under 0.1x time scale the shards spread in real time`, `AC-3 the shards are drawn above the slime's death flash and are 12 px` | `story_fight_test_shards_watchfail.log` (51/3: mean 6.0 px; the third failure is below) |

The green run after the framing fix is in `story_fight_test_framing_green.log` (52/0).

The first version of the shard test left the arena's `COMBAT_EXIT` running when the next test started. That made
`AC-4 … still in the arena` fail in the shard watch-fail run. The test now waits with `_wait_scene_settled()` before
it ends the arena.

The shard spread is random (no seed). The threshold of 12 px sits between about 6 px (game time, the bug) and the
33–38 px means of the green runs.

## Runs

| Run | Result | Log |
|---|---|---|
| Story-fight suite, first full version (49 checks), 10 runs in a row | 10 × 49/0, 33–36 s | `story_fight_test_repeat_10x.txt` |
| Full suite, first run | 24 green; `phase0_blockers_test` **timed out** at 960 s: its Chapter 1 bot stood in the new fight | `run_all_first_summary.txt` |
| Phase 0 blockers after the bot learned the fight | **82/0** (new check C3: `ch1_slime_fought`) | `phase0_blockers_test.log` |
| Framing checks, watch-fail on the old code / green | 49/3 / 52/0 | `story_fight_test_framing_watchfail.log`, `story_fight_test_framing_green.log` |
| Shard checks, watch-fail on the old code | 51/3 | `story_fight_test_shards_watchfail.log` |
| Before the review: story-fight suite, 3 runs | 3 × 54/0, about 34 s each | `story_fight_test_pre_review_1.log` … `_3.log` |
| Before the review: mutations (a)–(m) | control 3 × 54/0; all 13 failed their own check | `t13a_watchfail_mutations_pre_review.log` |
| Before the review: full suite | 25/25, 1478 s | `run_all_pre_review.log` |
| After the review fixes: mutations (a)–(s) | control 3 × 62/0; 17 of 19 as expected; (f) and (q) not, see below | `t13a_watchfail_mutations.log` |
| After the review fixes: full suite | **25/25** green, 1514 s, every count at its minimum (`STORY FIGHT` 62, `CH1` 413), no `RUNNER WARN` | `run_all_final.log` |
| Final code (one check relabelled): mutations (f), (q), (t) | all three failed their own check | `t13a_watchfail_mutations_fqt.log` |
| After round 1, the AC-6 check relabelled: story-fight suite, 3 runs | 3 × 62/0, 42–43 s each | `story_fight_test_round1_final_1.log` … `_3.log` |
| Final code (after round 2): story-fight suite, 3 runs | 3 × **63/0**, 42–43 s each | `story_fight_test_final_1.log` … `_3.log` |
| Final code (after round 2): Chapter 1 route test | **413/0**, 540 s | `chapter1_route_test_final.log` |
| Final code (after round 2): mutations (j), (o), (r), (s), (u), (v) | all six failed their own check | `t13a_watchfail_mutations_jorsuv.log` |
| `git diff --check` | clean | (console) |

The full suite was not re-run after the relabel. The relabel changed one check's message in `story_fight_test.gd` and
nothing else, and the three final suite runs cover that file.

## Mutations (AC-9)

The mutations ran in a scratch worktree at HEAD `a682b18` plus a copy of every uncommitted file under
`AethelgardPrototype/` and `.github/`. The harness re-copies those files before each run and asserts they are
byte-identical to the main checkout. It ran a control first, then one mutation per run, reverting each after its run.
A mutation counts as caught only when the suite fails **and** every expected check is among the failures.
Harness: `t13a_mutations.py.txt`.

| Mutation | Suite | Result | Expected failing check(s) |
|---|---|---|---|
| (a) metas ignored, tutorial mode runs | story fight | 4/3 + script errors | `AC-2 exactly one enemy` |
| (b) retry meta not set | story fight | 54/8 | `AC-4 …` |
| (c) base rewards not suppressed | story fight | 60/2 | `XP, gold and the inventory are unchanged` |
| (d) the meeting's resume check removed | chapter1_route | timed out (exit 124) | `T13a the meeting resumed at after_slime` |
| (e) Perfect Delete not refused | story fight | 61/1 | `Perfect Delete is refused` |
| (f) Root Access not refused (input gate and function guard) | story fight | 61/1 | `Root Access is refused from …` |
| (g) `_resolved` guard removed from the retry wait | story fight | 59/3 | `player.die() after the win`, both `AC-8 the player dies during …` |
| (h) metas not removed on read | story fight | 60/2 | `both story metas are removed` |
| (i) `ch1_slime_fought` not set | story fight | 57/3 | `ch1_slime_fought are set` |
| (j) old slime reset in place | story fight | 58/5 | `a new instance`, `the slime is a fresh instance` |
| (k) no shards | story fight | 59/3 | `polygon shards` |
| (l) retry timer runs during pause | story fight | 61/1 | `paused for 2.5 s` |
| (m) item drops not suppressed | story fight | 60/2 | `no item or gold pickup` |
| (n) the story slime keeps running while paused | story fight | 61/1 | `the same slime in the same place` |
| (o) the win does not wait for the shard fade | story fight | 61/2 | `waits for the 0.6 s shard fade` (192 ms, then 247 ms) |
| (p) the path drawn behind the ground | story fight | 61/1 | `path strip is drawn in front of the ground` |
| (q) Root Access guard removed, input gate kept | story fight | 61/1 | `Root Access is refused from …` |
| (r) story metas not in `TRANSIENT_METAS` | story fight | 62/1 | `both story metas are in TRANSIENT_METAS` |
| (s) the meeting's old resume check (both flags: loop) | chapter1_route | 411/2, 566 s | `with both flags set the meeting resumes` |
| (t) Root Access guard removed **and** ContextStack not exclusive | story fight | 59/3 | `Root Access is refused while paused` |
| (u) the retry does not mark the old slime DEAD (its pounce can act) | story fight | 62/1 | `never acts` (old slime velocity -198) |
| (v) both flags: `after_slime` plays, then one extra trip to the fight, then the path | chapter1_route | 412/1, 548 s | `no trip to the arena on the way` |

Mutations (n)–(t) were added after `/code-review` round 1, one for each new or rewritten check; (u) and (v) after round 2,
each isolating a clause that another mutation had only covered together with a second clause. Rows (j), (o), (r), (s),
(u) and (v) show the round-2 run (`_jorsuv.log`); the other rows show the round-1 run (`t13a_watchfail_mutations.log`,
(f), (q), (t) from `_fqt.log`).

Problems found along the way:

- **(e) and (f) were not caught on the first mutation run.**
  - With no story-fight test hook, Root Access and Perfect Delete fall back to the arena's tutorial target `slime`.
    That target is null in a story fight, so neither feature did anything, even when the story guard was removed.
  - The kit test now sets `arena.slime` to the story slime before its presses (commented in the suite).
  - The re-runs are `t13a_watchfail_mutations_ab.log` and `t13a_watchfail_mutations_efg.log`.
  - **The first run's log was overwritten** and is not kept.
- **(g) crashed natively once** (exit 0xC0000005 after about 10 s) on that first run.
  - It did not happen again in any later run: one unexplained crash in about 70 suite runs.
  - Its output was not kept.
- **"Root Access is refused while paused" still could not fail on the story guard alone.**
  - After the fix gave the check a target, mutations (f) and (q) still left it passing (`t13a_watchfail_mutations.log`:
    "NOT AS EXPECTED").
  - The reason is `ContextStack.push`. While the pause is open it refuses every exclusive context, so Root Access cannot
    open over a pause in any arena mode. Two things refuse it: the story guard returns first, and if it is removed,
    ContextStack refuses the push. Either one alone is enough, so the check fails only when both are removed. (Round 2
    corrected an earlier wording here that had this backwards.)
  - The fix:
    - The check is relabelled to say so.
    - (f) and (q) now expect only AC-2's check, which the story guard alone decides.
    - New mutation (t) removes both safeguards, and the check does catch it (`t13a_watchfail_mutations_fqt.log`).
- **(d) is caught by the route test's timeout, not by a fast failure.**
  - Without the resume check, the meeting replays the fight, the bot plays it again, and the suite runs to its 1620 s
    limit.
  - The dedicated resume test runs after the new-game route and is never reached under (d). So the check that catches
    (d) is the new-game route's `start played once (27)`.
- **Standby inflated the clock times in the review mutation run.**
  - (d) shows 4069 s, and (q) 2134 s for a suite that takes about 46 s.
  - The Windows System log shows the PC in Modern Standby (Kernel-Power 506 → 507) during the run: 20:02–20:13, 20:13–20:53,
    21:04–21:33 and 21:33–21:44 that evening.
  - The pass and fail results are unaffected; they match the other runs. Those two durations don't measure anything.
  - The later runs kept the PC awake.

## `/code-review` round 1 (2026-10-29): CHANGES REQUIRED → fixed

The reviewers were:

- godot-gdscript-specialist, for the scripts;
- godot-specialist, for engine APIs, the scene tree and lifecycle;
- qa-tester, for testability.

The orchestrator checked every finding below against the code before reporting it.

| # | Finding | Fix | Watched failing |
|---|---|---|---|
| 1 | With both meeting flags set, the meeting replayed `start`, handed off to the fight, and came back to the same state: an endless loop. A manual save is allowed in PROLOGUE, during the walk-out's 1.8 s fade, so this can be reached | **D8 (user):** the meeting resumes at `after_slime` whenever `ch1_slime_fought` is set | (s) |
| 2 | `story_fight_id` / `story_fight_return_scene` were not in `GameManager.TRANSIENT_METAS`. A quit or load during the fade into the arena carried them into a later tutorial-mode arena | Both added | (r) |
| 3 | The dirt path sat in the backdrop, behind the opaque `Ground/GroundSprite`, so it was never drawn (no path in the signed-off shots) | The path is the ground's last child | (p) |
| 4a | The pounce-windup check could not fail: the 0.28 s windup always ended before the 1.0 s retry | The pounce starts 0.85 s after the death on the retry's own clock, so it is in flight across the retry. The check is that nothing pounced | (j) |
| 4b | The paused slime stood out of detection range, so "the same place" could not fail | The slime is lifted 120 px; if it weren't paused, gravity would move it | (n) |
| 4c | "Root Access is refused while paused" had no target to act on | Target set; relabelled (see Mutations) | (t) |
| 4d | Nothing checked the 0.6 s wait before the scene change | Kill-to-transition time ≥ 500 ms (real time, a lower bound only) | (o) |
| 5 | AC-8's races were not tested: the player dying during the shards, and during `COMBAT_EXIT` | `_test_win_races` covers both windows. It asserts the death happened inside the window, then checks: no retry, one scene change, HP kept, time scale clean | (g) |

Suggestions left for later (the review did not require them):

- **Test checks:**
  - "Once" checks that count emits and scene changes, not just the first moment.
  - "HP kept" tested from a damaged HP.
  - Checks on the controls line that no placeholder is left unfilled, and that it shows keyboard keys before any input.
  - A pad-only win that also presses move, jump, dash and parry.
- **Untested paths:**
  - main menu or Continue during the fight;
  - an unknown fight id;
  - the default return scene;
  - pause during the win;
  - the resume shards' position.
- **Flake margins on a slow runner:** the shard check and the 3-retries loop.
- **Code:**
  - a silent refusal by `SceneTransitions.change_scene`;
  - Flee in a story fight;
  - `_apply_story_backdrop`'s length (43 lines).

## `/code-review` round 2 (2026-10-29): CHANGES REQUIRED → fixed

The code fixes were confirmed correct (godot-gdscript-specialist: every way into the meeting scene, the two metas'
lifetime, the path's draw order, collision and input). A replay of the meeting with both flags set adds Elara's +10
trust again; HEAD's meeting already replayed `after_slime` on that save, so that is not new. The qa-tester found test
gaps, all fixed:

| # | Finding | Fix | Watched failing |
|---|---|---|---|
| 1 | The pounce check joined "a fresh instance" and "nothing pounced"; (j) broke the first, so the second was never seen failing alone | Split into two checks; the clause on the fresh slime's velocity (always 0: `_idle_behavior` sets it) dropped | (u) |
| 2 | The 500 ms bound could fail on a slow runner: the real-time timer is created mid-frame and its first step is the previous frame's length | Lowered to 400 ms (the mutated value is about 200–250 ms) | (o) |
| 3 | "A load clears both story metas" called `clear_transient_metas()` directly, so it tested list membership, not a load | Renamed to what it tests; the two callers (`load_game`, `reset_game`) were confirmed by reading `game_manager.gd` | (r) |
| 4 | The both-flags check stopped at the first `after_slime` line: a single extra trip to the arena afterwards passed | It now also requires no arena on the way to the Broken Mile | (v) |
| 5 | The README said the story guard "is not the one that stops" Root Access over the pause; it returns first | Reworded (Mutations section) | — |

Not changed (suggestions): the path check rejects an equally valid fix that raises `z_index` instead; `show_behind_parent`
is not covered; a pause-refusal check in tutorial mode would cover ContextStack's refusal on its own.

The full suite was not re-run after round 2: round 2 changed only `story_fight_test.gd`, `chapter1_route_test.gd` and
`suite_limits.txt`, and both suites were run on their own (Runs table).

## CI run #45 (2026-10-31): Linux crash in the test → fixed

CI run #45 on `f715414` (run 41147782038) failed at the Story fight step. Godot exited with code 134 (abort) and
printed no result line. The steps after it did not run.

**Reproduced** under WSL Ubuntu with the official Godot 4.6.3 Linux build, the same file CI downloads (SHA-512 checked
against the release's `SHA512-SUMS.txt`). The project was a `git archive` of `f715414`, run through
`tests/run_tests.sh` as CI runs it.
- It crashed on every run, with signal 11 after about 6 s: `story_fight_test_linux_crash_f715414.log`.
- The GDScript backtrace points to `_test_win_guard`, `story_fight_test.gd:387`.

**Cause (in the test, not the game):** `var slime_id := slime.get_instance_id()` ran after the slime had freed itself.
`EnemyBase.die()` frees the enemy 0.6 s after it dies, and the test had already waited for the win and the scene to
settle. Calling a method through an untyped variable that holds a freed object crashed natively on Linux. On Windows it
passed every time but once: the one unexplained 0xC0000005 in about 70 Windows runs (TD-035) is probably the same bug.
That is not proven, because that run's backtrace was not kept.

**Fix:** the id is read before the kill. The check compares the same slime's id, so what it tests is unchanged.

| Run | Result | Log |
|---|---|---|
| Linux, test from `f715414` | exit 134, signal 11 at `:387`, no result line | `story_fight_test_linux_crash_f715414.log` |
| Linux, fixed test, 3 in a row | 63/0 each, 39–42 s | `story_fight_test_linux_fixed_1-3.log` |
| Windows, fixed test, 3 in a row | 63/0 each, 44–47 s (while the Linux runs below were going), **on Godot 4.7.2**, not the pinned 4.6.3 (see the note below) | `story_fight_test_windows_fixed_1-3.log` |
| Linux, the CI steps #45 skipped | reachability 25/0, ch1_rooms 445/0, act1_quests 114/0, phase0 82/0, playthrough 172/0 | `linux_ci_steps_after_story_fight.txt` |

**Correction (2026-11-01, TD-036).** The three Windows logs above ran on Godot 4.7.2, as their first line says. 4.7.2
was installed in `C:\Godot` beside 4.6.3 on 2026-10-30, and `run_phase0_tests.ps1` picks the highest version by name.
The Linux runs and CI use 4.6.3. CI #47 and #48 then ran the fixed test green on 4.6.3, so the fix itself is confirmed
on the pinned version.

## Changes outside the story's declared files

- `tests/integration/playthrough/phase0_blockers_test.gd`:
  - Its Chapter 1 bot now damages the story slime to 0, through the slime's own API, when it finds itself in the story fight. Without this the suite timed out (Runs table).
  - A new check, `C3: the slime was fought in the arena on the way`, raises its minimum from 81 to 82.
- `story/STORY_BIBLE.md` §5: one row for `ch1_slime_fought`. The route test checks that the row exists and that the
  flag has one writer.
- `scripts/game_manager.gd` (review fix 2): two names added to `TRANSIENT_METAS`. No save field changes.
- Declared, for reference: `suite_limits.txt` sets `chapter1_route_test` to 413 / 1620 s and `story_fight_test` to
  63 / 240 s.

## Protected paths (AGENTS.md)

- **Combat** (allowed by the story's D1–D4):
  - `scripts/combat/combat_arena.gd` gains the story-fight mode.
  - The encounter, boss and tutorial modes still start as before: `story_fight_test` has encounter and boss mode checks, and the `COMBAT FIXES` suite is green.
  - `enemy_base.gd`, `slime.gd`, `player_combat.gd`, hitboxes and collision are untouched.
- **Story progression** (allowed by D1–D4, D8):
  - One new flag, `ch1_slime_fought`, set only by the arena's fight table.
  - The resume point in `ch1_elara_meeting.gd`.
  - Every Chapter 1 flag check after the meeting is unchanged (CH1 413/0).
- **Save/load:** no schema change.
  - The two story-fight metas are hand-offs held in memory. They are consumed when the arena reads them, and cleared by every load and new game (`TRANSIENT_METAS`).
  - Saving inside the arena is refused, as it already was.
- **Untouched:** Source Key logic, true ending, NG+, world map / free travel, accepted region baselines, production art.

## Known limitations

- **Engine error on an enemy's first hit (TD-013, already in the register).**
  - `enemy_base.gd:923` logs `ERROR: The object does not have any 'meta' values with the key 'flash_tween'` on an
    enemy's first hit.
  - The new suite and the capture hit enemies more often, so the full run shows the error more often than before (8 times before T13a).
  - It is an `ERROR:` line, not `SCRIPT ERROR`, so the runner does not fail on it (TD-008).
- **Grey void in the other arena modes.**
  - The grey void beside the arena is fixed only in story-fight mode. The tutorial, encounter and boss modes still show it when the camera reaches a wall.
  - This predates the story, which did not change those modes.
- **Story-fight timeout.** Set to 180 s on 2026-11-01 (was 240 s). The suite takes 42–47 s on Windows (4.7.2, TD-036), 39–42 s on
  Linux (WSL) and 40 s on CI (run #47, 005ac99, the first CI run to finish it). 3× the slowest, 47 s, is 141 s, rounded
  up to a whole minute, per `suite_limits.txt`'s rule; well under the step's 10-minute `timeout-minutes`.
- **Not judged here:** the pacing and feel of the fight (slime difficulty, the retry delay). They are for `/team-qa` and
  T14b's playtest.

---

# Evidence: Y1-P0-T13b — The Broken Mile guardian is a real side-scroll fight

Story: `production/epics/y1-p0-stabilize/story-t13b-guardian-fight.md`. Every run here is on **Godot 4.6.3** (`GODOT`
set to the 4.6.3 console exe, TD-036; each log's first lines say so). The T13a sections above are unchanged.

## Acceptance criteria → evidence

| AC | Evidence |
|---|---|
| AC-1 the guardian | `guardian_fight_test.gd` C1 (constants, attack by distance, telegraph from range, telegraph times, exact damage, one attack then RECOVER, parry of both attacks, no contact damage, poise D9); mutations (a), (b), (c), (i), (j), (l) |
| AC-2 the row | C2; `story_fight_table_test` 305/0 (its QA 1 and QA 2 now include the row and `broken_mile_guardian.gd`); STORY_BIBLE §5 row; mutation (g) |
| AC-3 hand-off | C3 (Fight button 0.090 s, give-up 0.563 s, no-panel 0.000 s, staged guardian still visible; filter and calm unchanged); mutations (d), (e), (h) |
| AC-4 the fight | C4 (win: 10 shards, flag once, one change back; drops; retry; retry while the old charge runs); R1 watch-fail; mutations (g), (k) |
| AC-5 resume | C5 (first line `root_refused`'s, no panel or arena, Kaelen 600 / Elara 680, rest_stop not-edited line, save and load, main menu leaves no meta); mutation (f) |
| AC-6 tests | Suites registered in `suite_limits.txt`, `run_all_tests.ps1`, `ci.yml`; route test one-writer check (mutation (m)); full run 27/27 |
| AC-7 evidence | The four screenshots below, signed off by the user; CHANGELOG entry |

## Screenshots (live renderer, not headless)

All four are from a real 1280x720 window (Godot 4.6.3, Vulkan 1.4.329 Forward+, NVIDIA GeForce RTX 2050), driven by
`t13b_capture.gd.txt` through the real hand-off path: the story metas set as the Broken Mile sets them, then
`SceneTransitions.change_scene` to the arena, and the win returns to the real Broken Mile (`t13b_capture.log`). The
body is the arena's placeholder rectangle and the backdrop is procedural (no production art). The orchestrator opened
each one before showing it to the user. These are **capture 4**, taken on the final code after the `/code-review`
fixes. **Signed off by the user, 2026-11-05** (capture 3, on the code before the fixes, was signed off first and
replaced: the charge now stops at its travel end, which changed the shards shot).

| File | Shows |
|---|---|
| `guardian.png` | The fight: Kaelen, the guardian (78 x 56 brown body), HUD, the Broken Mile backdrop with its path, the keyboard controls line |
| `guardian-charge.png` | Half-way through the charge's telegraph: the guardian tinted, EnemyBase's "!" marker, 260 px from Kaelen (the capture places the player in charge range; the guardian spawns outside its 420 px detection range and waits, as the slime does) |
| `guardian-shards.png` | 0.3 s after the kill, once the charge had landed (HP 86/100, the 14) and stopped next to Kaelen (kill at 40 px): the death flash, with the brown shards over it, mostly hides him |
| `guardian-resume.png` | The Broken Mile's resume: `root_refused`'s first line in full, Kaelen at 600 and Elara at 680, no guardian |

Noted at sign-off, not fixed: the shards (the guardian's own brown) read poorly against the salmon death flash at
0.3 s; Elara's wider placeholder covers part of Kaelen in the resume shot (the positions the scene already uses at the
panel). Captures 1 and 2 (scratchpad only) failed or were reshot: an unquoted output path with a space, an
`EnemyBase` reference in the capture script compiled before the autoloads, no charge (player out of detection range),
shards at the frame's edge, the resume line not yet typed.

## Runs

| Run | Result | Log |
|---|---|---|
| Stage A, before the guardian existed | 0 passed, 29 failed, each by name | `t13b_tdd_before.log` |
| Stage A, after (3 runs) | 68/0 each | `t13b_guardian_fight_test_run1-3.log` |
| After review fixes R1, D9, D10, S1–S4 (3 runs) | 72/0 each | `t13b_guardian_fight_test_rev1_run1-3.log` |
| R1 watch-fail: the old guardian left alive on retry | 68 passed, 4 failed; "the old charge does not hit" failed (lowest HP 86.0) | `t13b_retry_check_watch_fail.log` |
| Stage B, before the scene change | 84 passed, 24 failed (C3 15, C5 8, one test bug fixed) | `t13b_stage_b_before.log` |
| Stage B, after (3 runs) | 108/0 each, about 56 s | `t13b_guardian_fight_test_final_run1-3.log` |
| `chapter1_route_test` | 417/0 (was 413) | `t13b_chapter1_route_test.log` |
| `phase0_blockers_test` | 82/0 | `t13b_phase0_blockers_test.log` |
| `story_fight_test`, `story_fight_table_test`, `load_all_test` | 63/0, 305/0, 210 ok | `t13b_story_fight_test_stage_b.log`, `t13b_story_fight_table_test_rev1.log`, `t13b_load_all_test_after_row.log` |
| After the mutations | 108/0 | `t13b_after_mutations.log` |
| Full local run, 27 suites | all passed, 1613 s | `t13b_run_all.log` |
| After the `/code-review` fixes (3 runs) | 128/0 each, about 78 s | `t13b_guardian_fight_test_rev2_run1-3.log` |
| `story_fight_test` after the fixes | 63/0 | `t13b_story_fight_test_rev2.log` |
| Full local run after the fixes, 27 suites | all passed, 1622 s (guardian 128/0, route 417/0, table 305/0, phase0 82/0, playthrough 172/0) | `t13b_run_all_rev2.log` |
| After the second review's test fixes F1–F6 (3 runs, then once after a comment re-wrap) | 129/0 each, about 77 s | `t13b_guardian_fight_test_rev3_run1-3.log`, `t13b_guardian_fight_test_rev3_after_comment_wrap.log` |
| R1 watch-fail at the wider retry distance (332 px) | 125 passed, 4 failed; "the old charge does not hit" failed (lowest HP 86.0) | `t13b_retry_check_watch_fail_rev3.log` |
| Parse check of the five changed scripts | all `ok`, exit 0 | (this README) |

## Mutations (AC-6)

`t13b_mutate.py`: one mutation per invocation, an exact one-match replacement, the file restored byte for byte and
SHA-256 checked. All 13 caught, each by its named check (`t13b_mutation_a.log` … `t13b_mutation_m.log`): (a) attack by
`randf()`; (b) the charge telegraph left at 0.55 s; (c) the stomp at `contact_damage * 1.6`; (d) filter hands off;
(e) the give-up never fires; (f) the resume check removed; (g) the row's flags empty; (h) the old ~2.15 s staging
before the hand-off; (i) no `_state_chase` override; (j) contact damage 8; (k) the arena's `loot_table = null` removed;
(l) poise removed; (m) the Broken Mile sets the flag itself (route test). (m) ran alongside (i), (j) and (l), which
touch only the guardian script; its target check reads source text.

After `/code-review` (`t13b_mutation_<id>_rev2.log`), all caught: (c) changed to `STOMP_DAMAGE * 1.6` (the stomp check
saw 19.2); (l) re-run; (n) the damage multiplier applied twice (27.0 instead of 18.0); (o) the telegraph not divided
(both scaled telegraph checks); (p) the charge not stopped (268.8 px travel, 221.3 px slide); (q) the cooldown raised
after every hit-stun (6 hits, no telegraph); (r) the give-up without `not guardian_resolved` (the four last-tick
checks); (e) re-run on R2's new line (the five give-up checks).

After the second review (`_rev3`): (s) a dead guardian that keeps acting (a `die()` override restoring physics and
state) → "C4 the guardian killed mid-charge: the player's HP is unchanged after the kill" (lowest HP 72, two charge
hits); the mid-telegraph variant of that check is backed by the guardian freeing itself 0.6 s after death, which this
mutation cannot switch off without changing `enemy_base.gd`; (t) Apply's `or guardian_resolved` guard removed →
"corruption was added once" (2 changes) and the 10-corruption check.

At `/story-done` (QL-TEST-COVERAGE gap: the first set had last run on the 108-check suite), (a), (b), (d), (f),
(g), (h), (i), (j), (k) and (m) were re-run on the final 129-check suite (`t13b_mutation_<id>_final.log`): all caught
by their named checks, every file SHA-restored, no Godot process left.

## `/code-review` (2026-11-05): CHANGES REQUIRED → fixed

GDScript, Godot scene-flow and QA reviews, each finding checked in the code by the orchestrator. Required: R1 a hit-stun
in CHASE raised the cooldown, so steady hits kept the guardian from attacking (now only from RECOVER); R2 the panel's
give-up overwrote a choice made in its last tick (paid edit, then the fight); R3 the multiplier clauses of AC-1 were
tested at 1.0 only (now also at damage x1.5 and difficulty x1.25); R4 D9/D10 recorded in the story. Also fixed: the
charge slid about 320 px in RECOVER, `dodge_chance` 0, the telegraph tween killed on a stagger, a full-length
no-second-attack watch, the freed-guardian checks, a stun check in `_arm`, GameState COMBAT, a kill mid-telegraph and
mid-charge. Not fixed, noted: the hand-off guard does not reset if `change_scene` refuses (as T13a's); the pause menu
during any scene transition (project-wide); the resume does not redraw the cart and flicker tree.

Second pass: GDScript CLEAN (every fix closed); QA GAPS, one required: C4's HP-after-kill check could not fail (the
win makes the player invulnerable). Fixed in the test (invulnerability cleared during the watch, mutation (s)), with
the corruption guard exercised (F2, mutation (t)), the multipliers asserted (F3), a wider retry margin (F4) and
game-time watches (F5, F6). Gameplay code unchanged in this round (SHA-256 as after the first fixes).

## Deviations and notes

- Accepted by the user: the guardian's `stagger()` override and its extra named constants (2026-11-05);
  `T13B_NEW_FLAGS` in the route test instead of the frozen Chapter 1 flag list; the guardian suite's timeout 180 s, raised to 240 s when the suite grew to about 78 s.
- Added during review (user decisions): D9 poise while attacking, D10 `_begin_telegraph` through `super`.
- Existing EnemyBase issues seen, not changed (out of scope): `get_meta("flash_tween", null)` prints an `ERROR:` line
  per telegraph; the parry tint stays on an enemy that leaves STUNNED early; a "Lambda capture freed" line.
- The four poise checks were watched failing through mutation (l), not directly.

## CI (AC-6)

CI run #53 on `449032a` (2026-11-05, https://github.com/Bhaskar-Bahukhandi/Ultimate-project/actions/runs/42016657461):
success in 25m48s on Godot 4.6.3 (Linux). Every step passed, including the whitespace and commit-message checks, the new
"Guardian fight (T13b …)" step (72 s, limit 240 s), "Story fight" (39 s), "Story fight table" (9 s) and "Chapter 1
route" (538 s).

---

# Evidence: Y1-P0-T13c — The north-field boar is a real side-scroll fight

Story: `production/epics/y1-p0-stabilize/story-t13c-boar-fight.md`. Every run here is on **Godot 4.6.3** (`GODOT` set
to the 4.6.3 console exe, TD-036; each log's first lines say so). The T13a and T13b sections above are unchanged.

## Acceptance criteria → evidence

| AC | Evidence |
|---|---|
| AC-1 the boar | `boar_fight_test.gd` C1 (constants; telegraph 0.6 s near, mid, far and off-screen; no turn; 14 once; jump clears it; wall to wall ends dizzy; dizzy 2.0 s, still, no hop; 3.5 s without a wall → RECOVER; armour: no HP, hit-stun, knockback or flash outside dizzy; 15 and the pogo's 27 while dizzy; the pogo bounces off the armoured boar; parry; D9 stagger in RECOVER; D10 star cue; contact; `dodge_chance` 0; scaled at ×1.5 / ×1.25); mutations a–j, r–v |
| AC-2 the row | C2; `story_fight_table_test` 307/0; STORY_BIBLE §5 row; mutation m |
| AC-3 hand-off | C3 (the boar trigger and the bridge trigger: stash, return point, metas, within 0.5 s, no staged line; the bridge trigger stops after the hand-off; calm and nest unchanged); mutations k, n, p |
| AC-4 the fight | C4 (win: 8 shards, the flag once, no XP/gold/drops, GameState COMBAT, one change back; retry; mid-charge retry with the player's invulnerability cleared; the cue hidden on death); mutation m |
| AC-5 return | C5 (the beat after the fade-in, the triggers held off, the two lines, paid once, the bridge after; a save and a load replays nothing and pays nothing after fight, calm or nest; main menu leaves no meta, stash or flag); mutations l, q |
| AC-6 tests | Suites registered; the route test drives the boar arena and its one-writer check (mutation o); the Phase 0 bot finishes the boar; full run (below) |
| AC-7 evidence | The four screenshots below, signed off by the user; CHANGELOG entry |

## Screenshots (live renderer, not headless)

All four are from a real 1280x720 window (Godot 4.6.3, Vulkan 1.4.329 Forward+, NVIDIA GeForce RTX 2050), driven by
`t13c_capture.gd.txt` through the real hand-off path: the village's flags, stash, return point and story metas set as
the village sets them at the fight choice, the arena as the scene, and the win back to the real village
(`t13c_capture.log`). The body is the arena's placeholder rectangle and the backdrop is procedural (no production art).
The orchestrator opened each one before showing it to the user. **Signed off by the user, 2026-11-06.**

| File | Shows |
|---|---|
| `boar.png` | The fight: Kaelen, the boar (48 x 40, the village marker's red), HUD at full HP, the open daytime field, the controls line with `Space then S + J — Pogo` |
| `boar-charge.png` | The boar half-way through its charge's telegraph (the "!!" glyph and EnemyBase's "!" marker) |
| `boar-dizzy.png` | The boar dizzy against the right wall, the `* * *` cue over it |
| `boar-return.png` | The north field after the win: Kaelen's "...It was still trying to get back to the nest. Right up until the end.", gold 100 paid |

Noted at sign-off, not fixed: Kaelen is below full HP in the charge and dizzy shots (earlier charges had landed while
the capture staged them); the HUD's SOUL, XP and Corruption labels read poorly on the light daytime sky. Capture 1
(scratchpad only) was reshot: the charge shot overlapped Kaelen, and the dizzy boar was outside the camera's view.

## Runs

| Run | Result | Log |
|---|---|---|
| Stage A, before the boar existed | 0 passed, 36 failed | `t13c_boar_fight_before.log` |
| Stage A, after (3 runs, then once after a re-wrap) | 90/0 each | `t13c_boar_fight_final_run1-3.log`, `…_run4_after_wrap.log` |
| Stage A review fixes, before the boar changes | 92 passed, 3 failed (the cue, D9) | `t13c_boar_fight_rev1_before.log` |
| Stage A review fixes, after (3 runs) | 95/0 each | `t13c_boar_fight_rev1_run1-3.log` |
| Stage B, before the village change | 103 passed, 25 failed (C3, C5) | `t13c_stage_b_before.log` |
| Stage B, after (3 runs) | 128/0 each, about 126 s | `t13c_boar_fight_final_b_run1-3.log` |
| `chapter1_route_test` | 425/0 (was 417) | `t13c_chapter1_route_test.log` |
| `phase0_blockers_test` | 82/0 | `t13c_phase0_blockers_test.log` |
| `ch1_rooms_test` (calms the boar, D11) | 445/0 | `t13c_ch1_rooms_test.log` |
| Dialogue format | 54/0 | `t13c_dialogue_test.log` |
| `story_fight_table_test`, `load_all_test` | 307/0, 211 ok | `t13c_story_fight_table_test.log`, `t13c_load_all_test.log` |
| Full local run, 28 suites | 27 passed; `test_layout` failed: `boar_fight_test.gd` had no `.uid` yet | `t13c_run_all.log` |
| `test_layout` after an import created the `.uid` files | 6/0 | `t13c_test_layout_after_uid.log` |
| Parse check of the seven changed scripts | all `ok`, exit 0 | (this README) |

## Mutations (AC-6)

`t13c_mutate.py`: one mutation per invocation, an exact one-match replacement (`--check` verifies every pattern without
running anything), the file restored byte for byte and SHA-256 checked. All 22 caught, each by its named check
(`t13c_mutation_a.log` … `t13c_mutation_v.log`): (a) the charge turns; (b) the telegraph left at 0.55 s; (c) the charge
at `CHARGE_DAMAGE * 1.6`; (d) no dizzy at the wall; (e) the armour removed; (f) the armour also while dizzy; (g) a parry
stagger counts as dizzy; (h) the multiplier applied twice; (i) the telegraph not divided; (j) `dodge_chance` 0.15;
(k) calm hands off; (l) the resume pays twice (caught by C5's save-and-load check); (m) the row's flags empty; (n) the
staged fight before the hand-off; (o) the village sets the flag itself (route test); (p) the bridge trigger carries on;
(q) the reload fix removed; (r) the off-screen override removed; (s) knockback while dizzy; (t) the 2.5 s charge;
(u) D9 removed; (v) D10 removed. A separate stage-A watch-fail of the armour check (`t13c_boar_fight_rev1_mutation_armour.log`)
touched two places and is superseded by (e).

## Deviations and notes

- Decisions D1–D11 are in the story. Added during the work: D9 (a parry outside an attack keeps the cooldown) and D10
  (the star cue) from the stage A review; D11 (`ch1_rooms_test` calms the boar; the boar's CI step 8 minutes).
- Stage A choices: the dizzy timer runs on physics frames (stable ±1 frame); a wall ends a charge only if the boar is
  running into it; an extra `ATTACK_RANGE` the base class needs; the row's `tree` colour with no trees.
- The route test also follows the fight on its early-alarm and hesitate-then-help routes, which pick "Fight it." too.
- Existing EnemyBase log noise (`flash_tween` `ERROR:` lines) appears here as in T13a and T13b; TD-041 logs the guardian's
  likely off-screen slowdown found during this story's readiness review.

## `/code-review` (2026-11-06): three rounds

- **Round 1: CHANGES REQUIRED → fixed.** R1 Mara's shop opened over the hand-off when her first talk was the third
  afternoon beat (watched failing: `t13c_r1_before.log`); R2 no case for pause mid-charge or while dizzy; R3 hits only
  tested while the boar was idle; R4 C4's HP-kept check compared full HP after a win that makes the player invulnerable
  (now from 40; mutation (ac)). Also: D9's floor scaled by the difficulty multiplier; `_alarm_done` set in the field's
  end; parry cases during the telegraph and on a dizzy boar; control runs (the mid-charge retry seen hitting; a
  real-input jump); a one-hit-per-charge override for charge boxes (a dev run took 3 hits from one charge with the
  player's invulnerability cleared); the off-screen checks turned into INFO lines; the knockback check made able to
  fail; the boar's CI step 10 minutes (runner timeout 540 s, about 165 s a run); TD-042 for the pogo's damage number on
  an armoured enemy. Full run after round 1: 28/28 (`t13c_run_all_final.log`).
- **Mutations added in round 1:** (w)–(ac), all caught. The first (z), which removed one of two clearing sites of
  `_charge_hit_pending`, survived (`t13c_mutation_z_first_def_survived.log`): an equivalent mutant, since either site
  alone stops a second hit. (z) was redefined to drop the sweep's own condition.
- **Round 2: CHANGES REQUIRED → fixed (test only).** The once-per-charge check crashed under (z) instead of failing by
  name; it now stops at a second hit (`t13c_mutation_z_fix3.log`: 137/1, no crash). Also: a direct test of the
  charge-box gate (watched failing by removing it, `t13c_boar_fight_fix3_watchfail_gate.log`); wall-clock caps on the
  game-time loops; game time in the two restore watches; two tidy-ups. 138/0 three times
  (`t13c_boar_fight_fix3_run1-3.log`).
- **Round 3: APPROVED WITH SUGGESTIONS → suggestions applied (test only).** S1 the retry control now also requires
  that a retry ran and the watch started from full HP; S2 the once-per-charge check now requires the charge watched to
  its end (dizzy or RECOVER); S3 the whole mutation set re-run on the final test file. S1's suspected vacuous pass did
  not occur: under (z) the control logs "retried true, start HP 100.0" (its lowest HP 0 is the old charge hitting
  every frame). S2 was not watched failing (it needs the 24 s wall cap to expire mid-charge).
- **Final evidence (game code unchanged since round 1; SHA-256 checked after every mutation):** boar suite 138/0 three
  times (`t13c_boar_fight_fix4_run1-3.log`, no script errors); all 29 mutations (a)–(ac) caught by their named checks
  (`t13c_mutation_<id>_fix4.log`), every file restored byte for byte. (e) (armour removed) also produces script errors
  after its named failures, as in every earlier (e) run: with the armour gone the boar dies early and a later case's
  wait reads it after it is freed (`boar_fight_test.gd:348`).

## CI (T13c, AC-6)

CI run #55 on `3b594ff` (2026-11-06, https://github.com/Bhaskar-Bahukhandi/Ultimate-project/actions/runs/42209447887):
success in 28m44s on Godot 4.6.3 (Linux). Every step passed (the Godot install skipped on a cache hit, as in #54),
including the commit-message check, the new "Boar fight (T13c …)" step (162 s; step limit 10 minutes, runner 540 s),
"Guardian fight" (72 s), "Story fight" (40 s), "Story fight table" (9 s) and "Chapter 1 route" (542 s).
