# Y1-P0-T14b evidence: the playthrough bot from New Game to the credits

Story: `production/epics/y1-p0-stabilize/story-t14b-playthrough-ch1-fights.md`. Suite:
`AethelgardPrototype/tests/integration/playthrough/full_playthrough_test.gd` (test-only; no file under
`AethelgardPrototype/scripts`, `scenes` or `dialogue` changed). Every run: Godot 4.6.3 console
(`C:\Godot\Godot_v4.6.3-stable_win64_console.exe`, `GODOT` set), `tests/run_phase0_tests.ps1`, local Windows,
2026-11-07. The leg table, with every leg's flags, cap and three run times: [leg_table.md](leg_table.md).

## AC map

| AC | What shows it | Where |
|---|---|---|
| AC-1 one chain from New Game | `AC-1 start: New Game state after reset_game()` (no flag set, keys 0, chapter 1, glitch 0); `AC-1 start: the first leg is the crash-site hook`; `AC-1 leg NN arrives at …` for all 66 legs; `run: 66 legs of 66 played`; no `SEED_*` left in the file | `t14b_run1..3.log`, `leg_table.md` |
| AC-2 the three Chapter 1 fights | per arena leg: `story_fight_id`, win flags false before, alive window (3 s of game time and the enemy out of IDLE; player HP printed at its start and end), enemy never DEAD, win flags set after, `story_fight_retries` 0, player not dead, `the arena handed off once`; guardian: `_root_choice is 'fight'`, filter ALL, aggression 1.0, `glitch_meter unchanged` | `t14b_run1..3.log` legs 02, 04, 05, 10; mutations a, b, c, l |
| AC-3 the undriven hops | `boss_return_scene is cleared at the leg's start`, `a real interact press started the hop`, the level-1 warning answered "Enter the Arena", `boss_return_scene is oakhaven_region.tscn when the knight is handed off`; knight alive window then `_on_boss_defeated()` with `combat_ended false -> true`; shrine altar then stair; shatter `chapter_end_card was seen visible`, the "Chapter 1 Complete. Press" line, `_skip_completed is false` | legs 12-15; mutations d, f, f2; `t14b_pass3a_watched_failure.log` |
| AC-4 Chapter 2 legs | careful route steps (Rook, Command Hall, Rem, west road, bronze flag, tower, Underground, Proxy); C4 flags at each hand-off; `Enter (Suicidal)` warning logged at level 4; `source_key_fragment_2 set and source_key_count 2`; the Chapter 3 state INFO lines | legs 16-26; mutation e; section below |
| AC-5 per-leg checks | at every hand-off: ContextStack empty, dialogue not active (except `KNOWN_R5_DIALOGUE`, TD-043), the leg's flags, the next scene the table names; T14a's Chapter 3-10, menu and credits checks green from the real state (7 Source Keys) | all runs; mutations h, i, j |
| AC-6 caps and run time | three final runs, per-leg times and spread, caps ≥ 3x slowest and ≥ 60 s (guardian 180 s); `suite_limits.txt` `405 600` (3x 183.2 s, rounded up to a whole minute, the file's rule); CI step renamed, `timeout-minutes: 12` (raised from 10). Corrected at the /story-done gate: see the last section | `leg_table.md`, `t14b_hopfix_run1..3.log`, `t14b_capfix_run1.log`, `AethelgardPrototype/tests/suite_limits.txt`, `.github/workflows/ci.yml` |
| AC-7 tests and evidence | watched failures (passes 1, 2, 3a), mutations a-l (below), the after-mutations clean run, TD-043..046, CHANGELOG `test:` entry | this folder; `docs/tech-debt-register.md`; `AethelgardPrototype/CHANGELOG.md` |

## Runs

| Log | Result | Bot time | Note |
|---|---|---|---|
| `t14b_pass1_run1.log`, `t14b_pass1_run2.log` | 93 / 0 each | 76.7 s | pass 1: New Game to `oakhaven_region` |
| `t14b_pass2_run1.log`, `t14b_pass2_run2.log` | 338 / 5 each | 178.7 / 178.3 s | the 5 R5 dialogue samples that became TD-043 |
| `t14b_run1.log`, `t14b_run2.log`, `t14b_run3.log` | 405 / 0 each | 178.4 / 178.4 / 178.3 s (wall 180 / 181 / 180 s) | AC-6 measurement runs |
| `t14b_after_mutations.log` | 405 / 0 | 178.5 s | after all mutations, file SHA-256 `e81f48a3…d64307` |
| `t14b_run4.log`, `t14b_run5.log`, `t14b_run6.log` | 405 / 0 each | 171.5 / 171.5 / 171.6 s (wall 174 s for 5 and 6) | after the boar-flake fix (game-time window); the leg table's times until the /story-done gate (now the hop-fix runs) |
| `t14b_run_all.log` | see the file's summary | — | every suite, Godot 4.6.3, after the fix |
| `t14b_hopfix_run1..3.log` | 405 / 0 each | 182.3 / 183.2 / 182.1 s | final bot `b6e7b29f…`; the leg table's times |
| `t14b_capfix_run1.log` | 405 / 0 | 183.9 s (leg 04 59.5 s, cap 180 s) | `CAP_GUARDIAN` 180, bot `5fb81cfe…` |

## Watched failures

| Pass | Broken step | Failing check | Log |
|---|---|---|---|
| 1 | the arena fight finish skipped | `AC-6 leg 02 combat_arena.tscn (ch1_slime) hands off within its 120 s cap` + softlock report leg 2 | `t14b_pass1_watched_failure.log` |
| 2 | the knight's `_on_boss_defeated()` skipped | `AC-5 leg 13 …: flags set at the hand-off (missing [all three])`, `AC-5 after leg 13 … goes to shrine.tscn (got combat_arena.tscn)` | `t14b_pass2_watched_failure.log` |
| 3a | the boss callback skipped (the rewritten callback check) | `AC-3 leg 13 tutorial_knight_boss.tscn: the scene's own combat_ended was false before the bot's callback and true at the hand-off (false -> false)` | `t14b_pass3a_watched_failure.log` |

## Mutations (`t14b_mutate.py`, one per invocation, bot file only; every run restored, SHA-256 verified)

| id | Mutation | Named check that failed (quoted) | Restored |
|---|---|---|---|
| a | slime win flags emptied at runtime (`_story_cfg["flags"] = []`) | `AC-2 leg 02 combat_arena.tscn (ch1_slime): the row's win flags [...] are set after the finish (missing ["first_slime_defeated", "ch1_slime_fought"])` | OK |
| b | fight finished before the alive window | `AC-2 leg 02 … the alive window reached 3 s of real time … (0.00 s real …)` (also legs 05, 10) | OK |
| c | Root Access filter edit + Apply | `AC-2 leg 04 path_to_oakhaven.tscn: the game's _root_choice is 'fight' at the hand-off (got 'filter')` (also filter index 1, glitch 0.0 -> 10.0) | OK |
| d | shatter skipped (ui_cancel held) | `AC-3 leg 15 shatter_transition.tscn: played through: chapter_end_card was seen visible`, the line check, `no skip: _skip_completed is false at the hand-off (true)` | OK |
| e (1st def.) | Rem skipped, tower first, steps only | NOT its named check: `AC-6 leg 19 ironhold_region.tscn hands off within its 60 s cap`. The game itself refuses the tower: `tower_warning` option 0 is "Not yet. The convoy first." (`ironhold_city.dlg:239-241`), so leg 19 never hands off. Redefined (coordinator decision) | OK (`t14b_mutation_e_first_def_game_refuses.log`) |
| e | Rem skipped, tower first, option 1 "We go up now." at `tower_warning` only | `AC-5 leg 19 ironhold_region.tscn: flags set at the hand-off [...] (missing ["ch2_medicine_quest_active", "ch2_medicine_done", "ch2_medicine_early"])` (also leg 25 `ch2_city_stable`) | OK |
| f | knight hop by `SceneTransitions.change_scene` (not the region's handler) | `AC-3 leg 12 oakhaven_region.tscn: boss_return_scene is oakhaven_region.tscn when the knight is handed off (got '')` | OK |
| f2 (extra) | knight hop by `change_scene_to_file` (the story's wording; emits no hand-off) | `AC-3 leg 12 …: boss_return_scene … (got '')`, `AC-5 after leg 12 … goes to tutorial_knight_boss.tscn (got combat_arena.tscn)`; the only hand-off seen was the knight scene's own random encounter (TD-044) | OK |
| g | 1 s cap on leg 04 | `AC-6 leg 04 path_to_oakhaven.tscn hands off within its 1 s cap` + softlock report "leg 4 of 66 … (cap 1 s)" | OK |
| h | leg 07's scene made elara_house in the table | `AC-5 after leg 06 (path_to_oakhaven.tscn) the game goes to elara_house.tscn (got oakhaven_village.tscn)` | OK |
| i | leg 08's flag swapped for `ch1_t14b_never_set` | `AC-5 leg 08 elara_house.tscn: flags set at the hand-off [...] (missing ["ch1_t14b_never_set"])` | OK |
| j | ContextStack entry pushed before the hook's hand-off | `AC-5 leg 00 opening_crash_site_hook.tscn: no ContextStack entry open at the hand-off (stack top 't14b_mutation_j')` (and every later leg) | OK |
| b v2 | as b, on the game-time window (after the flake fix) | `AC-2 leg 02 … the alive window reached 3 s of game time inside its 30 s wall cap (0.00 s of game time …)` (also legs 05, 10; the IDLE check too) | OK (`t14b_mutation_b_v2.log`, SHA-256 `8c4390f8…0b14a81`) |
| l v2 | as l, on the game-time window | `AC-2 leg 02 … the player stays alive through the alive window (dead true, retries 0 at 0.07 s of game time)` + `SOFTLOCK REPORT: the player died in the alive window of the ch1_slime fight` | OK (`t14b_mutation_l_v2.log`) |
| l | player killed in the slime alive window (`die()`) | `AC-2 leg 02 … the player stays alive through the 3 s real alive window (dead true, retries 0 at 0.02 s)` + `SOFTLOCK REPORT: the player died in the alive window of the ch1_slime fight` | OK |

**Re-run on the final bot file (2026-11-07, SHA-256 `8c4390f8…0b14a81`).** Rows a and c–j above ran on the bot before the
flake fix (`e81f48a3…d64307`); their logs are kept as `t14b_mutation_<id>_v1.log`. All ten were re-run, one per invocation,
on the final file; each was caught by the same named check and restored byte for byte (`restored=True`). Logs:
`t14b_mutation_<id>.log`.

| id | Named check that failed on the final file |
|---|---|
| a | `AC-2 leg 02 … the row's win flags […] are set after the finish (missing ["first_slime_defeated", "ch1_slime_fought"])` |
| c | `AC-2 leg 04 … _root_choice is 'fight' at the hand-off (got 'filter')`; filter index 1; `glitch_meter` 0.0 -> 10.0 |
| d | `AC-3 leg 15 … chapter_end_card was seen visible`; the line check; `_skip_completed is false at the hand-off (true)` |
| e | `AC-5 leg 19 ironhold_region.tscn: flags set at the hand-off […] (missing [… "ch2_medicine_early"])`; leg 25 `ch2_city_stable` |
| f | `AC-3 leg 12 … boss_return_scene is oakhaven_region.tscn when the knight is handed off (got '')` |
| f2 | the same hop check (got ''); `AC-5 after leg 12 … goes to tutorial_knight_boss.tscn (got combat_arena.tscn)` |
| g | `AC-6 leg 04 path_to_oakhaven.tscn hands off within its 1 s cap` + softlock report naming leg 4 |
| h | `AC-5 after leg 06 (path_to_oakhaven.tscn) the game goes to elara_house.tscn (got oakhaven_village.tscn)` |
| i | `AC-5 leg 08 elara_house.tscn: flags set at the hand-off […] (missing ["ch1_t14b_never_set"])` |
| j | `AC-5 leg 00 opening_crash_site_hook.tscn: no ContextStack entry open at the hand-off (stack top 't14b_mutation_j')` |

With b v2 and l v2, every mutation has now been caught on the final file. Clean run afterwards:
`t14b_after_mutations_final.log`, 405 / 0, 183.6 s.

## Chapter 3 state vs T14a's old seed (AC-4, INFO)

From `t14b_run1.log` (`INFO ch3 state` lines, identical in all runs):

| | Real run (T14b) | Old seed (T14a, `74e40e8`) |
|---|---|---|
| Level / gold / XP | 4 / 1500 / 628 | 12 / 800 / 375 |
| HP / max HP, attack, defense | 190 / 190, 37, 14 | 41 / 120, 20, 11 |
| Glitch meter | 21.0 | 11.0 |
| Source Keys | 2 | 2 |
| Chapter (at the hand-off) | 2 (ironhold_departure sets 3) | 3 (seeded) |
| Relationships | elara 20, seraphina 30 | elara 0, seraphina 30 |
| Flags | 76 set: all 39 seed flags except `elara_trust_high`, plus Chapter 1 detail flags (`ch1_*` beats, fights, stew, bridge, shatter) the seed never had | 39 |

T14a's Chapter 3-10 checks all pass from this real state.

## KNOWN_R5_DIALOGUE (TD-043) and tech debt

`KNOWN_R5_DIALOGUE = {12: oakhaven_region, 13: tutorial_knight_boss, 19: ironhold_region, 23: ironhold_region,
26: ch2_ending}`: these five scenes start their scene change with the dialogue box still up. On these legs an
active dialogue is an INFO line; no active dialogue FAILS (TD-043 may be fixed: remove the entry). The list only
shrinks. Rows added to `docs/tech-debt-register.md`: TD-043 (the five hand-offs), TD-044 (a random encounter inside
the idle knight scene), TD-045 (`enemy_base.gd:923` `flash_tween` ERROR on every enemy finish), TD-046 (drivers
duplicated across four suites, D4).

## Isolation costs (full list in the suite header)

Private DialogueManager members to answer choices; the hook's `_on_signalfragment_interaction` and
`_complete_opening_hook`; the village, house and shrine interaction handlers called with the scene's Player; the
arena fights finished with `_enter_dizzy()` + `take_damage(max_health)` (D3), reading `_story_enemy`, `_story_id`,
`player`, `story_fight_retries`; the guardian panel read-only (`_root_choice`, `_target_filter`,
`aggression_spinbox`); the knight hop's teleport onto the gate (the interact key is a real input event); the
knight's and Chapter 2 bosses' defeat callbacks; Ironhold's `_interact_npc` / `_interact_story` / `_interact_boss`
and the bronze bracket set by flag; the shatter's `_skip_completed` read; T14a's trial, Wastes gate and ch3_ending
costs. Player-possible inputs used: a real `move_right` hold in the arena fights until the enemy leaves IDLE, real
`interact` and `ui_accept` presses, room pokes only after the dialogue box closes.

## Deviations and decisions

- Every alive window (arena fights and bosses) is now 3 s of GAME time (`FIGHT_ALIVE_S`, `_game_seconds_since`);
  the arena fights also need the enemy out of IDLE. Until the flake fix the arena window was 3 s of REAL time
  (12 s of game time); the boss legs moved to game time first, because the idle player died to the knight at
  1.85 s real.
- Mutation (e) was redefined (above). Mutation (f) uses `SceneTransitions.change_scene` so it reaches the hop check;
  the story's `change_scene_to_file` wording is run as the extra (f2).

## Not verified

- **CI has not run this suite.** The expected CI job time (about 31 min against `timeout-minutes: 45`: CI #55's
  28m44s minus the old bot step's ~70 s plus ~180-200 s) is an estimate.
- **The guardian leg's time on CI.** Leg 04's cap (180 s) is 3x its slowest local run (60.0 s); the give-up's 1800
  pausable ticks can take longer at a lower frame rate. The first CI run's log line for leg 04 is the check.
- The two flakes seen on 2026-11-07 (the boar death and the knight hop) are root-caused and fixed in the two sections
  below; neither has been seen since.

## The boar-death flake: root cause and fix

- **Seen:** `t14b_mutation_e_flake_boar_death.log`: the player died 0.48 s real into the boar fight's alive window
  (leg 10), about once in 20 runs.
- **Root cause:** the player's HP carries over between the Chapter 1 arena fights and nothing heals between them
  (only a level-up adds +10 max HP between the slime and the guardian). The 3 s REAL alive windows (12 s of game time
  with nobody playing) drained it: in four instrumented runs (`t14b_boar_diag_a_1..4.log`, DIAG lines) the slime left
  58-68 of 100 HP, the guardian 15-25 of 110, and the boar's first charge (about 13.6) left 1-11. One extra earlier
  hit and the first charge kills, about 0.5 s real after arrival. The bot's `move_right` hold was not the trigger in
  the boar fight (the boar left IDLE during the entry transition, so the bot never walked; it charged a standing
  player).
- **Fix (test-side, player-possible):** the arena alive window is 3 s of game time and the enemy out of IDLE, as the
  story's AC-2 states. Runs 4-6: the slime 100 -> 100, the guardian 110 -> 96.4, the boar 96 -> 82.4 of 110 (see
  `leg_table.md`). Mutations b and l re-run on the new window (`_v2` logs), each caught.
- **Game-side finding:** the boar's AI runs during the arena's COMBAT_ENTRY fade-in (CHASE, then TELEGRAPH, with
  `trans=true` in all four runs): TD-047. HP not restored between the Chapter 1 fights is a design note, not a bug
  (a death is a tutorial retry at full HP).

## `/code-review` round 1 (2026-11-07): CHANGES REQUIRED → fixed

- **Required:** the AC-6 row above gave `suite_limits.txt` as `405 390`; the file says `405 360`. Corrected.
- **S1** `move_right` is released after every leg's loop (`_drive_leg`), so a fight that hands off while the bot walks
  cannot carry the key into the next leg.
- **S2** the alive window's game time is added up frame by frame (`_tick_game_time`): physics frames stepped since the
  last frame / ticks per second × the time scale read before `_drive_frame` resets it (a hitstop counts at its own
  scale); frames stepped while the tree is paused add nothing. Replaces `_game_seconds_since`, which multiplied the
  whole window by the current scale.
- **S3** doc comments on the nine undocumented functions (`_gm`, `_dm`, `_st`, `_cs`, `_scene_path`,
  `_ending_arrival_checks`, `_find_button`, `_menu_and_credits`, `_final_checks`).
- **S4** each boss window prints the player's HP at its start and end (new helper `_boss_player`).
- Checked and dropped: the end card's same-frame press/release (`ch2_chapter_end.gd:381-385` reads it in `_input` with
  `is_action_pressed`, so it works).
- **After the fixes** (bot SHA-256 `91450ac4…5331ea`): three runs 405 / 0 (`t14b_review_run1..3.log`, 177.3 s, 175.2 s,
  181.8 s). HP margins per window (run 1): slime 100 → 100, guardian 110 → 96.4, boar 96 → 82.4 of 110; knight
  82 → 82; tower 134 → 111.1 of 134; wraith 82 → 82 of 134; proxy 167 → 167.
- **All 12 mutations re-run on this file**, one per invocation, each caught by its named check and restored byte for
  byte: logs `t14b_mutation_<id>.log`. The previous rounds are kept as `t14b_mutation_<id>_v1.log` (file `e81f48a3…`)
  and `_v2.log` (file `8c4390f8…`).
- Suggestions left for later (not logged as debt): split `_drive_leg` / `_drive_fight` under 40 lines; mutations for
  the R5 dialogue half and a Chapter 2 boss window; the Chapter 2 bosses' window has no "fight running" signal beyond a
  settled scene; "left IDLE" also passes for PATROL; frame-count settles (SETTLE_FRAMES) on a fast headless loop.

## Second flake: the knight hop in the full run (2026-11-07), root cause and fix

- **Seen:** the full run after the review fixes (`t14b_run_all_hop_flake.log`, bot `91450ac4…`): leg 12
  (`oakhaven_region`) never pressed interact (0 presses in 11.7 s) and handed off to a random encounter ("AMBUSH!
  Enemies are stronger! [6 foes — 1.5x rewards]") instead of the knight; 108 passed, 5 failed. The other 27 suites passed.
- **Root cause (test side):** `_drive_knight_hop` re-placed the player on the TutorialKnightGate whenever it was more
  than 1 px away, and pressed only after 10 quiet frames with no re-placement. When physics nudged the player, the bot
  re-placed it every few frames, so it never pressed; and each re-placement under 200 px counts as walked distance for
  `RandomEncounterSystem` (`random_encounter_system.gd:449-465`, 32 px per step; the region's zone is not safe), until
  the step budget ran out and an ambush fired. A clean run places once and presses at once (leg 0.3 s).
- **Fix:** press once the region itself lists the gate in its `_overlapping` (what its `interact` handler acts on,
  `oakhaven_region.gd:845-847`, `:861-872`); place the player only while it does not, at most `HOP_PLACE_MAX` (3)
  times, else fail the leg by name with a softlock report.
- **Watched failing:** with the overlap test forced false, `AC-3 leg 12 oakhaven_region.tscn: the region lists the
  TutorialKnightGate as overlapping after 3 placement(s)` + a softlock report (`t14b_hopfix_watched_failure.log`); file
  restored (SHA-256 checked).
- **After the fix** (bot SHA-256 `b6e7b29f…a4bc95c`): three runs 405 / 0 (`t14b_hopfix_run1..3.log`, 182.3 s, 183.2 s,
  182.1 s); all 12 mutations re-run on this file, each caught by its named check and restored byte for byte
  (`t14b_mutation_<id>.log`; the previous round is kept as `_v3.log`, file `91450ac4…`). Full run:
  `t14b_run_all_final.log`.
- **Game-side note (not a defect in the bot):** random encounters can fire in `oakhaven_region` while a player stands
  near the knight gate, as designed; TD-044 (an encounter inside the knight scene) is likely the same step counter
  running while the zone stays set after leaving the region. Not investigated further here.

## `/story-done` gates (2026-11-07): AC-6 corrected

- **QL-TEST-COVERAGE: ADEQUATE.** Advisory gaps, not fixed here: the flag checks of legs 12, 21 and 23 list only
  flags set by earlier legs (their next-scene and hop checks carry them; mutation f); "left IDLE" also passes for
  PATROL; no mutation for the enemy-never-DEAD check, the hand-off retries / player-alive checks, the boss alive
  window, or a death outside the slime fight; the warning log matches the option text exactly.
- **LP-CODE-REVIEW: CONCERNS**, acted on:
  - `suite_limits.txt` set the timeout at 2x (360 s) against its own rule (3x the measured time, rounded up to a
    whole minute, below the step's `timeout-minutes`), and AC-6's raise of the CI step timeout was not done. Now
    `405 600` (3x 183.2 s = 549.6 s) and `timeout-minutes: 12`.
  - The leg table's times were from runs 4-6, before the review and hop fixes; regenerated from
    `t14b_hopfix_run1..3.log`. That showed the guardian leg at 59.4-60.0 s real against its 160 s cap (2.67x), so
    `CAP_GUARDIAN` is now 180 s (bot SHA-256 `5fb81cfe…`; the only change from `b6e7b29f…` is that constant and its
    comment). Confirming run: `t14b_capfix_run1.log`; `t14b_mutate.py --check`: 12 of 12 patterns still match.
  - The "Not verified" section said the boar flake's cause was not investigated; corrected.
  - Left as suggestions: four functions over 40 code lines (`_drive_leg` 112, `_drive_fight` 63, `_drive_boss` 43,
    `_play` 42; `_drive_leg` also over complexity 10); a null player is read as a death (`:811`, `:1060`).
