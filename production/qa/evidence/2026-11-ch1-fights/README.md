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
- **Story-fight timeout.** The `story_fight_test` timeout is 240 s, against 42–47 s locally. It will be set to 3× the slower of the local and CI
  times (at least 120 s) once CI has run it.
- **Not judged here:** the pacing and feel of the fight (slime difficulty, the retry delay). They are for `/team-qa` and
  T14b's playtest.
