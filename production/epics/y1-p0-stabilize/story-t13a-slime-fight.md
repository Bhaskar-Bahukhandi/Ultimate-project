# Story T13a: The opening slime is a real side-scroll fight

> **Epic**: Y1-P0 Stabilize (Sprint 001)
> **Task ID**: Y1-P0-T13a (`production/plan/_source/Y1-P0.json#Y1-P0-T13`, days 1–2 for the slime; sprint plan row Y1-P0-T13a)
> **Status**: Complete
> **Layer**: Feature
> **Type**: Integration
> **Estimate**: 2 days (day 1 the arena's story-fight mode, the hand-off and the retry; day 2 resume, tests, mutations,
> screenshots) — tight after the QL-STORY-READY additions; flagged as at risk of running over
> **Manifest Version**: N/A — `docs/architecture/control-manifest.md` does not exist
> **Last Updated**: 2026-10-30

## Context

**GDD**: none for Chapter 1 combat encounters. **Source of record**: the plan entry above — why "ROADMAP §5 'Make the boar,
the guardian and the opening slime real side-scroll fights'"; the slime day: "Hand off from `elara_meeting` to
`scenes/combat/combat_arena.tscn` with the slime spawn and the forest background, then return to the same spot", "Keep
the 'breaks into polygons' death beat and Elara's line after it", "Handle player death here as a tutorial retry, not
game over", "Run chapter1_route to confirm the flags after the fight are unchanged"; edge cases "Pausing mid-charge",
"Dying to the slime at 1 HP during its death animation", "Saving is blocked inside the arena and allowed after return",
"Gamepad-only play". `dialogue/ch1/elara_meeting.dlg`'s header: "The combat tutorial happens only when danger can't be
avoided". The sprint row: "Route test covers fight + non-fight branch; `production/qa/evidence/2026-11-ch1-fights/slime.png`"
(the slime has no non-fight branch: the meeting always meets it). T13a proves the pattern T13b (guardian) and T13c
(boar) reuse.
**Requirement**: N/A — no TR-ID registered.

**ADR Governing Implementation**: N/A — no ADR exists; the story-fight mode follows the arena's existing boss-mode
pattern (GameManager metas for the fight and the return scene).
**ADR Decision Summary**: N/A
**ADR Version**: N/A

**Engine**: Godot 4.6 (4.6.3 at `C:/Godot`) | **Risk**: HIGH (`docs/engine-reference/godot/VERSION.md`, 4.6 row)
**Engine Notes**: no post-cutoff API is planned. The arena already runs side-scroll physics (`player_combat.gd`,
`EnemyBase` on collision layer 4). A local retry already exists: `player.set_meta("local_boss_retry_enabled", true)`
stops `player_combat.die()` before the normal death path (it still emits `died` at once and returns after a 1.0 s
pause-aware timer), and `force_restore_after_death_retry(spawn)` restores the player, clears ContextStack time-scale
requests and gives 0.75 s of invulnerability (`player_combat.gd:2042-2068, 2182-2232`; `ch1_tutorial_knight.gd:461,
1203-1231`). Only the tutorial knight's enemy has `reset_for_retry()`; `slime.gd` has none, and its pounce is a
coroutine (`await create_timer(0.28)`), so a reset in place cannot stop a pounce already in flight.

**Control Manifest Rules**: NOT ASSESSED — no control manifest.

**Performance**: no new cost expected — one enemy in an arena that already runs encounters and bosses; the fight replaces
a 2 s staged tween with a short real fight.

**AGENTS.md protected areas — allowed by the user for this story (decisions D1–D4, 2026-10-27):** *combat* (a story-fight
mode in `scripts/combat/combat_arena.gd`, the slime's arena death beat, the tutorial retry) and *story progression* (a new
story flag `ch1_slime_fought` and a resume point in the Elara meeting). Not touched: collision layers, hitboxes, the
slime's stats or AI (`slime.gd`), save/load schema (a story flag is data in the existing flags dictionary), Source Key,
true ending, NG+, world map. Production-art fallback: unchanged (the slime uses the arena's existing sprite path and its
placeholder fallback; the forest backdrop is procedural and labelled so).

### Audit facts (2026-10-27, on HEAD `0e65c76`)

1. **The slime is staged, not played.** `ch1_elara_meeting.gd:183-271`: on `do slime_appears` a `ColorRect` slides in to
   about (640, 425); `_stage_slime_fight()` hops it to (520, 425), lunges Kaelen to (490, 420), flashes, and breaks it into
   7 polygon shards of `Color(0.45, 0.85, 0.75)` that fade out over 0.6 s. `start` ends at `do slime_appears`;
   `after_slime` opens "That wasn't blood. That wasn't anything. It just... came apart."
2. **`slime.gd` exists** (`EnemyBase`): 30 HP, contact damage 8, hops (1.8 s), a pounce with a 0.28 s windup. Its death
   is a generic smoke puff (`enemy_base.gd:931-960`), not the polygon beat. No `reset_for_retry()`.
3. **`combat_arena.gd` has three modes** checked in `_ready` (`:126-170`): random encounter (`pending_encounter` meta),
   boss (`boss_fight_id` + `boss_return_scene` metas; returns with `SceneTransitions` `COMBAT_EXIT`), and a tutorial
   `TutorialSlime` mode that nothing reaches (its only caller, `scenes/exploration/oakhaven.tscn`, is loaded by no
   scene); its victory sets `tutorial_completed` / `first_slime_defeated`, +50 XP, +10 gold, and goes to `oakhaven_region`.
4. **Arena behaviour**: saving is refused there (`GameManager.NON_RESUMABLE_SCENES`); random encounters only trigger in
   EXPLORATION and the arena sets COMBAT; `_input` (`:666-672`) opens Root Access and Perfect Delete with no gating by
   `root_access_unlocked`, which the story only sets on the Broken Mile; the cutscene hold-to-skip lives in
   `CutsceneManager`, which the arena does not use; a player death takes the normal path (+corruption, half HP, game over
   at 100 % glitch). The pause menu's `_return_to_main_menu()` (`pause_screen.gd:1362`) can leave the arena with any
   meta still set.
5. **The player has fought once before** (the crater's glitch-memory fight: attack, parry, move), so this is the second
   fight, not the first.
6. **Rewards**: `_configure_scripted_reward_enemy` sets `suppress_base_rewards`, which skips XP and gold only; item
   drops still spawn (`enemy_base.gd:1716-1718`, "Always spawn loot drops"), and `_ready` generates a default loot table
   whenever `loot_table` is null (`:218-219`). `EnemyBase.die()` frees the enemy itself after `create_timer(0.6)`
   (`:975-979`). A player hit writes `player_stats["hp"]` at once (`player_combat.gd:1923-1924`), before the 1.0 s death
   timer runs.
7. **Tests**: `chapter1_route_test` passes the meeting by waiting for the scene change (`:215-218`) and lists the known
   Chapter 1 flags at `:876-887`; `combat_fixes_test` builds a real `EnemyBase` laid out like the arena's TutorialSlime
   (`_real_enemy`, :301).

### Decisions (user, 2026-10-27)

- **D1 host:** a *story-fight* mode in `combat_arena.gd`, beside the encounter and boss modes, driven by GameManager metas
  (which enemy, the return scene) — the pattern T13b and T13c reuse. The dead tutorial mode is left as it is.
- **D2 resume:** a new story flag `ch1_slime_fought`; the Elara meeting, reloaded with it set, skips `start` and the fight
  and plays `after_slime`.
- **D3 kit:** no Root Access and no Perfect Delete in this fight (the story unlocks Root Access later); move, jump, dash,
  attack, parry.
- **D4 rewards:** set `first_slime_defeated` and `ch1_slime_fought`; no XP, no gold.
- Player death is a tutorial retry (the plan's step; the knight's existing pattern).
- **QL-STORY-READY (GAPS G1–G12, all folded in by the user, 2026-10-28):** a fresh slime on retry, the shard beat's owner,
  a guard between win and retry, metas consumed on read, pause, resume staging, gamepad-only play, tested hand-off, T14b
  hooks, more mutations, retry cleanup, four screenshots with the user's sign-off.
- **D5 race (user, 2026-10-28):** if the player is already dead when the slime dies, the retry wins: the slime's death is
  ignored and the normal retry runs, so 0 HP never reaches the meeting.
- **D6 drops (user, 2026-10-28):** the story fight suppresses the slime's item drops as well as XP and gold.
- **D7 controls line (user, 2026-10-28):** a non-blocking on-screen label (not DialogueManager), re-rendered when the input
  device changes.
- **D8 both flags set (user, 2026-10-29, during `/code-review`):** the meeting resumes at `after_slime` whenever
  `ch1_slime_fought` is set, even when `ch1_elara_glitch_witch_met` is set too (a manual save during the walk-out's
  fade). Replaying `start` there handed off to the fight again and came back to the same state, without end.
- **QL-STORY-READY third pass (GAPS 1–4, folded in, 2026-10-28):** a real test for D6 (no pickup nodes; the loot table
  cleared after `add_child`), C3's direct-`die()` check held long enough to mean something, the D5 retry finding the old
  slime already freed, and `story_fight_resolved`'s outcome values.
- **QL-STORY-READY second pass (GAPS 1–6, folded in, 2026-10-28):** the opposite race order (D5), a mutation-(g) test that
  bypasses invulnerability plus a retry count, an observable pause check and a pause-aware retry timer, the shard beat's
  duration, mutations (j)–(l), game-time timing, the old slime disabled before it is freed, and AC-6's Continue wording.

---

## Acceptance Criteria

- [x] AC-1 **Hand-off.** When `start` reaches `do slime_appears`, the slime appears as today; then (instead of
      `_stage_slime_fight()`) the meeting sets the story-fight metas — `story_fight_id = "ch1_slime"` and
      `story_fight_return_scene = "res://scenes/chapter1/elara_meeting.tscn"` — and changes scene to
      `scenes/combat/combat_arena.tscn` through `SceneTransitions` (`COMBAT_ENTRY`). Tested: at the hand-off both metas
      hold those values and the next scene is the arena; the meeting loaded with `ch1_slime_fought` set never loads the
      arena.
- [x] AC-2 **The arena's story-fight mode.** With `story_fight_id = "ch1_slime"` the arena (checked after the encounter
      and boss modes, before the tutorial mode) reads **and removes** both story metas in `_ready` (consume on read),
      then: removes the TutorialSlime; spawns one `slime.gd` enemy named `StoryFightSlime` at the right and keeps the
      player node `Player` at the left; draws a procedural forest backdrop from the Elara meeting's colour values
      (asserted by node colour; the look is checked by screenshot); shows one controls line — a non-blocking label, not
      DialogueManager (D7), re-rendered when the input device changes — through `InputService` naming move, jump, dash,
      attack and parry for the device in use; spawns no other enemy; leaves GameState COMBAT (no random encounter can
      start); offers no hold-to-skip (no `CutsceneManager`); refuses Root Access and Perfect Delete from keyboard and
      pad alike (no panel, no ContextStack entry, `perfect_delete_charges` unchanged); the slime's XP, gold and item
      drops are all suppressed (D6). A second load of the arena with no story metas runs its default mode.
- [x] AC-3 **Win.** The arena listens to the slime's `died` signal and owns the beat: 7 polygon shards of `Color(0.45,
      0.85, 0.75)` spawn at the slime's position (the generic smoke puff still plays with them). A `_resolved` guard is
      set at the slime's death: from then on the player is invulnerable and the retry cannot run. This applies only if
      the player is alive when the slime dies (D5; otherwise see AC-4). Then `first_slime_defeated` and
      `ch1_slime_fought` are set once, XP, gold and the inventory are unchanged, the player's HP is kept as it is (it
      carries into the Elara meeting and the Broken Mile, and is above 0), and after the shards' 0.6 s fade (a value in
      the fight table) the game changes once to the return scene (`COMBAT_EXIT`), which sets its own GameState (the
      meeting sets PROLOGUE in `_ready`). The arena exposes the outcome for tests and the T14b bot: a
      `story_fight_resolved(outcome)` signal whose only outcome is `"win"` (a retry emits nothing and only increments
      `story_fight_retries`), the `story_fight_retries` count, and the `ch1_slime_fought` flag.
- [x] AC-4 **Death is a tutorial retry with a fresh slime.** In the story fight the player's death does not take the
      normal path: no corruption, `player_died` not set, no game-over scene. After the player's 1.0 s death timer (game
      time; the arena's own wait is pause-aware, `create_timer(1.0, false)`), unless `_resolved` is set, the old slime —
      if it still exists (`is_instance_valid`; after its own death it frees itself 0.6 s later) — is disabled and hidden
      at once (no physics, no hitbox, not visible) and freed about 0.5 s later, a fresh `slime.gd` instance named
      `StoryFightSlime` is spawned at the slime spawn (so no timer or coroutine of the old one can act; the suite's log
      has no `SCRIPT ERROR` line, which the runner checks — `ERROR:` lines are not checked, TD-008),
      `story_fight_retries` goes up by one, and the player is restored at the spawn with full HP
      (`force_restore_after_death_retry`, 0.75 s of invulnerability). After every retry `Engine.time_scale == 1.0`, no
      ContextStack entry and no time-scale request is left; this holds across at least 3 retries in a row. If the slime
      is already dead when the player dies, the win stands and no retry runs. If the player is already dead when the
      slime dies (a hit in flight, the kill zone), the slime's death is ignored — no shards, no flags, no scene change —
      and the retry runs (D5).
- [x] AC-5 **Resume.** `elara_meeting.tscn` loaded with `ch1_slime_fought` set and `ch1_elara_glitch_witch_met` not set:
      the opening camera move and Kaelen's walk-in are skipped; Kaelen is placed at (490, 420); 7 static shards of the
      slime colour lie around (520, 425) and fade out over 0.6 s as `after_slime` starts; `start` is not replayed; the
      arena is never loaded; `after_slime` plays and continues exactly as today (Elara's entrance, the questions, the
      three-way choice, `elara_met`, `ch1_elara_glitch_witch_met`, the walk to the Broken Mile). With both flags set the
      meeting also resumes at `after_slime` (D8). Saving inside the arena is refused (existing rule). Tested: a save made in the
      meeting after the return, loaded again → the first dialogue line shown is `after_slime`'s first line and no scene
      change to the arena happens.
- [x] AC-6 **Leaving the arena another way.** Returning to the main menu from the pause menu during the fight leaves no
      story meta and does not set `ch1_slime_fought`, so the meeting loaded again reaches the hand-off and the fight
      again; Continue behaves as it does today (it loads the last save, which may be from before the meeting). With the
      pause context on the ContextStack, the slime, the death timer and the win and retry transitions do not advance,
      Root Access is refused, and resuming continues them.
- [x] AC-7 **Gamepad-only.** The fight can be won with joypad input only (`InputEventJoypadButton` /
      `InputEventJoypadMotion` for move, jump, dash, attack, parry); the controls line shows pad glyphs after pad input;
      the `root_access` and `perfect_delete` pad bindings are refused as in AC-2.
- [x] AC-8 **Tests.** A new suite `tests/integration/combat/story_fight_test.gd` (own `STORY FIGHT RESULT` line) checks
      AC-2, AC-3 (the slime dies first, then the player during the shards and during `COMBAT_EXIT`: flags set once, one
      scene change; the player dies first, then the slime within 0.5 s: the retry runs, D5), AC-4 (including a death
      during the pounce windup, then full HP 1 s after the restore, and 3 retries in a row), AC-6 and AC-7 (a scripted
      joypad run that wins the fight), and that the encounter and boss modes still start as before.
      `chapter1_route_test` drives the meeting's fight through the slime's API (damage to 0), checks AC-1's hand-off and
      AC-5's resume and save/load case, adds `ch1_slime_fought` to its flag list, and every Chapter 1 flag check after
      the meeting is unchanged. Both registered in `tests/suite_limits.txt`, `run_all_tests.ps1` and `ci.yml`; the full
      suite green with every count at its minimum.
- [x] AC-9 **Evidence and records.** Live-renderer screenshots, each opened and checked, labelled live renderer in the
      evidence README: `production/qa/evidence/2026-11-ch1-fights/slime.png` (the fight: player, slime, HUD, backdrop,
      controls line), `slime-shards.png` (the polygon beat), `slime-resume.png` (the meeting's resume staging) and
      `slime-controls-pad.png` (the controls line after pad input); the README labels the backdrop procedural and
      records the user's sign-off on the four screenshots. Watch-fail in a scratch worktree, one mutation per run, each
      failing its own check: (a) the arena ignores the story metas (tutorial mode runs) → AC-2; (b) the retry meta not
      set (normal death path) → AC-4; (c) base rewards not suppressed → the XP/gold check; (d) the meeting's resume
      check removed (the fight replays) → AC-5 in the route test; (e) Perfect Delete not refused → AC-2's charges check;
      (f) Root Access not refused → AC-2's ContextStack check; (g) the `_resolved` guard removed → AC-3's race check;
      (h) the metas not removed on read → AC-6; (i) `ch1_slime_fought` not set → AC-5; (j) the retry resets the old
      slime in place instead of respawning it → C4's new-instance check; (k) the arena does not spawn the shards → C3's
      shard count; (l) the retry wait uses a timer that runs during pause → C6; (m) item drops not suppressed → C3's
      pickup check. Added after `/code-review` (2026-10-29): (n) the slime runs while paused → C6's stillness check;
      (o) the win does not wait for the shard fade → C3's timing check; (p) the path drawn behind the ground → AC-2's
      path check; (q) Root Access refused only by the input gate → AC-2's direct-call check; (r) the story metas not in
      `TRANSIENT_METAS` → AC-6's load check; (s) the meeting's old resume check → AC-5's both-flags check; (t) the
      Root Access guard removed and ContextStack not exclusive → AC-6's pause check. Added after the second review
      round (2026-10-29): (u) the retry does not mark the old slime DEAD → AC-4's "a pounce whose windup ends after the
      retry never acts" check; (v) with both flags set, one extra trip to the arena after `after_slime` → AC-5's "no trip
      to the arena on the way" check. CHANGELOG `feat:` entry; `git diff --check` clean.

---

## Implementation Notes

- Follow the boss mode's shape: `_ready()` reads and removes `story_fight_id` / `story_fight_return_scene`; a
  `_start_story_fight(id)` builds the fight from a small table keyed by the id (enemy script, spawn points, backdrop, the
  two flags), so T13b/T13c add rows, not modes. Keep the table in the arena script (gameplay values in data: HP and damage
  stay in `slime.gd`).
- Retry: set `local_boss_retry_enabled` on the player when the story fight starts (before any damage); on `player.died`,
  wait with `create_timer(1.0, false)` (pause-aware; the engine default keeps counting during pause), check `_resolved`,
  then disable and hide the slime, free it about 0.5 s later, spawn a fresh one and call `force_restore_after_death_retry(PLAYER_SPAWN)`
  (the knight's `_reset_player_for_retry` shape; the slime is respawned because it has no `reset_for_retry()`).
- Kit: gate `_open_root_access()` and `_use_perfect_delete()` on the story mode (D3); the other modes stay as they are.
- Drops (D6): clear the slime's `loot_table` *after* `add_child` (`EnemyBase._ready` regenerates a default table when it
  is null, `enemy_base.gd:218`), in the arena's own setup; `slime.gd` and `enemy_base.gd` stay unchanged.
- The retry guards the old slime with `is_instance_valid`: after its own death it frees itself 0.6 s later.
- The `died` handler checks the player first: if `player.is_dead`, ignore the slime's death (D5).
- Polygon beat: reuse the meeting's shard code (7 shards, `Color(0.45, 0.85, 0.75)`) at the slime's position, driven by
  the arena's `died` handler.
- Meeting: the resume path places Kaelen and static shards, then runs `after_slime`; `_stage_slime_fight()` goes.
- Test drivers: `StoryFightSlime.take_damage(max_health)` for the win; the player's `take_damage` for the retry; joypad
  events through `Input.parse_input_event` for AC-7 (the playthrough bot's pattern).
- Commit only with the user's OK: `feat(ch1): the opening slime is a real fight` with `Task: Y1-P0-T13a`.

---

## Out of Scope

- The guardian (T13b) and the boar (T13c); the playthrough bot's Chapter 1 fight legs (T14b — it uses AC-3's signal, the
  flag and the stable node names).
- `slime.gd`'s stats and AI, collision layers, hitboxes; production art for the slime (the existing sprite path and its
  fallback are used).
- The arena's unused tutorial mode and `scenes/exploration/oakhaven.tscn` (left as they are).
- Any change to `elara_meeting.dlg`'s text.

---

## QA Test Cases

- **C1 (AC-1)** — route test: at the hand-off `story_fight_id == "ch1_slime"`, the return meta names the meeting, the
  next scene is the arena; the meeting loaded with `ch1_slime_fought` set never loads the arena.
- **C2 (AC-2)** — story_fight_test: one enemy, `StoryFightSlime`; both metas gone after `_ready`; root_access /
  perfect_delete (keyboard and pad) leave no ContextStack entry and the charges unchanged; no `CutsceneManager`;
  GameState COMBAT; backdrop nodes use the meeting's colour values; a second arena load without metas runs the default.
- **C3 (AC-3)** — slime HP to 0 → 7 shards of the colour at its position, both flags set once, XP/gold and the inventory
  equal to before, player HP unchanged and above 0, one scene change to the meeting after the 0.6 s fade,
  `story_fight_resolved("win")` emitted; no DropManager pickup node in the arena after the slime's death and
  `StoryFightSlime.loot_table == null` (D6; the inventory alone cannot show it — pickups land out of the player's
  reach); after the slime's death, `player.take_damage` → HP unchanged and `is_dead` false, and `player.die()` called
  directly (bypassing invulnerability) with the arena kept alive (the scene change stubbed or held) for at least 1.2 s
  of game time → no retry: `story_fight_retries` and the `StoryFightSlime` instance id unchanged, one scene change.
- **C4 (AC-4)** — player HP to 0 → polled in game time (the death slow-mo stretches it) with a margin: player HP = max,
  `story_fight_retries` + 1, glitch meter unchanged, `player_died` unset, still in the arena, a new `StoryFightSlime`
  instance at the spawn with full HP; a death during the pounce windup → player HP still max 1 s after the restore; 3
  retries in a row → `Engine.time_scale == 1.0` and no ContextStack entry after each; player HP to 0, then the slime's
  HP to 0 within 0.5 s → no shards, no flags, no scene change, the retry runs, and `player_stats.hp` is full before
  anything leaves the arena; after that restore `Engine.time_scale == 1.0` with no ContextStack time-scale request, and
  the suite log has no `SCRIPT ERROR` line (D5).
- **C5 (AC-5)** — the meeting with `ch1_slime_fought` set: no `slime_appears`, Kaelen at (490, 420), shards present then
  gone, `after_slime` lines seen, the chosen branch's flags set; save after the return, load → first line is
  `after_slime`'s, no arena load.
- **C6 (AC-6)** — pause → main menu during the fight: no story meta, `ch1_slime_fought` false; the slime's position
  unchanged over 2 s of pause; player HP to 0, pause pushed for 2 s → the player still `is_dead`, HP 0, the same slime
  instance; pause popped → restored within 1.0 s plus a margin; Root Access refused while paused.
- **C7 (AC-7)** — a joypad-only run wins the fight; the controls line shows pad glyphs; pad root_access / perfect_delete
  refused.
- **C8 (AC-8/9)** — suites registered and green; mutations a–m each failing their own check; the four screenshots
  opened, signed off.

---

## Test Evidence

**Story Type**: Integration (with screenshots — the fight is player-visible)
**Required evidence**: `tests/integration/combat/story_fight_test.gd` (passing), the extended
`tests/integration/story/chapter1_route_test.gd` (passing), `production/qa/evidence/2026-11-ch1-fights/` (README with
the AC map and the user's sign-off, `slime.png`, `slime-shards.png`, `slime-resume.png`, `slime-controls-pad.png`, the
suite logs, the mutation log, the full-suite log).
**Run result**: OBSERVED — live renderer (Vulkan Forward+, RTX 2050), capture 5: `slime.png`, `slime-controls-pad.png`,
`slime-shards.png` and `slime-resume.png` in `production/qa/evidence/2026-11-ch1-fights/`, each opened and signed off by the
user (captures 3 and 4 were rejected; the README records why and what changed).

**Status**: [x] Created — uncommitted at close; the README maps each AC to its checks and logs

---

## Dependencies

- Depends on: Y1-P0-T11 (Complete: combat-feel leftovers), Y1-P0-T04 (Complete: the shatter rewire shares
  `chapter1_route_test.gd`).
- Unlocks: Y1-P0-T13b and Y1-P0-T13c (reuse the story-fight mode), Y1-P0-T14b (the bot's Chapter 1 fight legs).

---

## Completion Notes
**Completed**: 2026-10-30
**Criteria**: 9/9 passing, two of them with gaps. AC-6 is partial: the pause checks pass, but neither the main-menu route
nor a win under pause is tested. AC-7 is partial: the scripted pad win presses only move and attack (jump, dash and parry
by pad are untested). In AC-3, "HP kept" is checked from full HP only. Both gaps are logged as TD-032. Left to a
playtest: the feel of the fight and a run on a real gamepad. Suites: `story_fight_test` 63/0 three runs in a row
(42–43 s); `chapter1_route_test` 413/0 (540 s); full local suite 25/25 after the round-1 fixes. Round 2 changed tests
only, and the two suites it touched were re-run green. Mutations (a)–(v) were all caught, each failing its own check.
`git diff --check` is clean.
**Code review**: two `/code-review` rounds.
- Round 1 returned CHANGES REQUIRED; the user chose [A] and "resume after the slime" (D8). Fixed: the both-flags loop
  (D8); the story metas added to `TRANSIENT_METAS`; the path strip drawn behind the ground; four vacuous checks; the
  AC-8 death-during-win races.
- Round 2 returned CHANGES REQUIRED, all test gaps; the user chose [A]. Fixed: the pounce check split; the fade bound
  set to 400 ms; the metas check renamed; the no-arena clause added; mutations (u) and (v) added.
- The round-2 fixes were verified by re-runs, not by a third review.
- At close: QL-TEST-COVERAGE returned GAPS and LP-CODE-REVIEW returned CONCERNS C1–C5. Neither has a blocker. The user
  accepted both and had them logged.
**Deviations** (advisory):
- NOT ASSESSED: GDD / ADR / TR-registry traceability (none exist for Chapter 1 combat encounters).
- The win's 0.6 s shard fade and wait run in real time, not game time. Both are pause-aware, so the kill's slow motion
  does not stretch the beat; capture 3 showed it bunched.
- The slime spawns at x 760, not x 900, so it is inside the first frame.
- Colour continuity: the meeting's slime is teal, the arena's slime is green (the shards are teal). Logged as TD-034.
- Files changed outside the story's list:
  - `phase0_blockers_test.gd`: the arena hand-off forward.
  - `STORY_BIBLE.md`.
  - `game_manager.gd`: `TRANSIENT_METAS` (round 1).
- The AC-9 mutation list grew from (a)–(m) to (a)–(v) during review.
**Test Evidence**: Integration, made of:
- `tests/integration/combat/story_fight_test.gd` (new, 63 checks);
- `tests/integration/story/chapter1_route_test.gd` (413 checks);
- the fixture `tests/fixtures/story_fight_return_stub.tscn`;
- `production/qa/evidence/2026-11-ch1-fights/`: the README with the AC map, the four signed-off screenshots, the suite
  and full-run logs, the mutation logs, and the harness and capture scripts.
**Tech debt logged**:
- TD-031: the fight table to hold the whole fight before T13b, plus a shared enemy-body builder.
- TD-032: the AC-6 and AC-7 test gaps.
- TD-033: tests and the arena reaching into private state.
- TD-034: the slime's colour continuity and the grey void.
- TD-035: one unexplained native crash.
**Known after close**: CI has not run this changeset. Once it has, set `story_fight_test`'s timeout (240 s now) to
3× the slower of the local and CI times, at least 120 s.
