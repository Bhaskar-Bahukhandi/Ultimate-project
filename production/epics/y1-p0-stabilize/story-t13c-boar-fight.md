# Story T13c: The north-field boar is a real side-scroll fight

> **Epic**: Y1-P0 Stabilize (Sprint 001)
> **Task ID**: Y1-P0-T13c (`production/plan/_source/Y1-P0.json#Y1-P0-T13`, the boar day; sprint plan row Y1-P0-T13c)
> **Status**: Complete
> **Layer**: Feature
> **Type**: Integration
> **Estimate**: 3 days (sprint row: 2). Day 1 the boar's script and its row; day 2 the village's hand-off and resume and
> the two test bots; day 3 tests, mutations, screenshots. Over the row's 2 days for the same reason as T13b (new AI;
> T13b took 3 with review).
> **Manifest Version**: N/A — `docs/architecture/control-manifest.md` does not exist
> **Last Updated**: 2026-11-06

## Context

**GDD**: none for Chapter 1 combat encounters (as T13a and T13b). **Source of record**: the plan entry above, boar day:
"Create `scripts/combat/enemies/field_boar.gd`: charge, stun-on-wall, pogo window (the existing beat names)", "Calm
and rebuild-nest choices skip the arena and set their existing flags", "Make sure the bridge deadline keeps running
while the boar is handled (no hidden pause)", "Return to the village with the alarm sequence continuing"; done: "All
three boar outcomes reachable and set the existing flags"; edge case "Pausing mid-charge in the boar fight". Sprint
row: "As T13a; `…/boar.png`". `dialogue/ch1/north_field.dlg`, the staged fight: "It can't turn once it's running!
Jump it!", "Now, while it's dizzy! Jump, then {move_down} and {attack} on its back!".
**Requirement**: N/A — no TR-ID registered.

**ADR Governing Implementation**: N/A — no ADR exists. The story-fight mode is T13a's; TD-031 made a fight a row of
`STORY_FIGHTS`; T13b added the second row. This story adds a third row and an enemy script, not a mode.
**ADR Decision Summary**: N/A
**ADR Version**: N/A

**Engine**: Godot 4.6 (4.6.3 at `C:/Godot`; every run sets `GODOT` to the 4.6.3 console exe, TD-036) | **Risk**: HIGH
(`docs/engine-reference/godot/VERSION.md`, 4.6 row)
**Engine Notes**: no post-cutoff API is planned. The boar uses `EnemyBase`'s state machine as the guardian does
(`scripts/combat/enemies/broken_mile_guardian.gd` is the model: `_state_chase`, `_begin_telegraph`, `_execute_attack`,
`_state_attack`, `_apply_hitstun` and `stagger` overrides, per-frame charge hit boxes through
`_deal_damage_in_attack_hitbox`). `EnemyBase.take_damage` (`enemy_base.gd:805`) takes HP, plays the hit flash and
starts the hit-stun; the boar's armour overrides it. `CharacterBody2D.is_on_wall()` after `move_and_slide()` tells the
charge it reached a wall; the arena's walls stand at x -20 and x 1280. The player's pogo is `player_combat.gd`'s
down-attack in the air (`POGO_DAMAGE_MULT` 1.8, `POGO_VELOCITY` -500).

**Control Manifest Rules**: NOT ASSESSED — no control manifest.

**Performance**: no new cost expected — one enemy in the arena, as the slime's and the guardian's fights.

**AGENTS.md protected areas — allowed by the user for this story (D1, 2026-11-05):** *combat* (the new enemy script
`scripts/combat/enemies/field_boar.gd` and a `ch1_boar` row in `combat_arena.gd`'s `STORY_FIGHTS`) and *story
progression* (a new story flag `ch1_boar_fight_won`, the village's hand-off and resume, and a new `north_field.dlg`
node holding two existing lines). Not touched: `enemy_base.gd`, `player_combat.gd` (the pogo is used as it is),
collision layers, the arena's story-fight code, save/load schema (a story flag is data in the existing flags
dictionary), Source Key, true ending, NG+, world map. The calm and nest branches are unchanged. Production-art
fallback: unchanged (the boar uses the arena's placeholder body; the backdrop is procedural and labelled so).

### Audit facts (2026-11-05, on HEAD `294ce70`)

1. **The boar is staged, not played.** `ch1_oakhaven_village.gd` `_run_north_field()` (`:499-534`): `alarm` (help or
   refuse) → the fade to the field (the player placed at `NORTH_FIELD_POS + (0, -90)`, `NORTH_FIELD_POS` (1440, 1380)) →
   `field_water` (the sluice) → `boar`, whose choices set `ch1_boar_fought` (and `do start_boar_fight`, a no-op),
   `ch1_boar_calmed` (and a 5-corruption Root edit) or `ch1_boar_nest_rebuilt` (and Elara's trust). With
   `ch1_boar_fought` the scene plays `boar_fight_staged` (shakes and shouted calls, "ELITE DEFEATED", then Kaelen's
   "...It was still trying to get back to the nest. Right up until the end." and Elara's "I know. I saw."). Every
   outcome then sets `ch1_corrupted_boar_defeated`, pays 100 gold and 50 XP and sets `_field_resolved`.
2. **The village can leave and come back** (Y1-P0-S08): `_stash_afternoon()` keeps `_seen`, the afternoon beats,
   `_alarm_done`, `_field_resolved` and `_bridge_done` in `GameManager.VILLAGE_AFTERNOON_META` (memory only, in
   `TRANSIENT_METAS`); `_restore_afternoon()` reads it in `_ready`; `GameManager.set_return_point(scene, pos)` and
   `_arrive_from_return_point()` place the player.
3. **No running deadline.** The bridge comes after the field; fixing it "takes the afternoon, on the spot" ("No
   WorldClock yet", `:551`). Nothing ticks during the boar, so the plan's "no hidden pause" holds by construction.
4. **The player's pogo exists**: a down-attack in the air (`player_combat.gd:73-82`, 15 × 1.8 = 27 damage).
5. **Test bots pick the fight.** `chapter1_route_test` checks `ch1_boar_fought` (`:272`) and drives the village;
   `phase0_blockers_test`'s driver picks choice 0 (`_driver_choice`, `:22`), which is "Fight it.". Both bots' arena
   hooks name `Enemies/StoryFightSlime` only (`phase0_blockers_test.gd:391`, `chapter1_route_test.gd:208`), so both
   would stall in a boar arena.
6. **Look.** The village's ground is `Color(0.25, 0.55, 0.3)` and the boar's map marker `Color(0.7, 0.15, 0.15)`
   (`scenes/chapter1/oakhaven_village.tscn`); `arena_manager.gd:474` sizes a boar 48 × 40. The arena has no `boar` entry
   in `ENEMY_SIZES` / `ENEMY_COLORS`, so the row gives both.
7. **Lessons from T13b, applied from the start:** every runtime number checked under one pin helper that writes the
   fields directly (never the saving setters) before the enemy spawns; scaled checks with both multipliers away from
   1.0; game-time watches; every new check watched failing or caught by a mutation; no check that the arena's win
   invulnerability makes true by itself.

### Decisions (user, 2026-11-05)

- **D1 permission:** combat (the new script and row) and story progression (`ch1_boar_fight_won`, the hand-off and the
  resume, the new dialogue node) are allowed. Only the fight choice hands off; calm and nest stay as they are.
- **D2 the boar: armoured until dizzy.** 45 HP. It telegraphs (0.6 s), then charges and cannot turn; the player jumps
  it. When the charge meets an arena wall it is dizzy for 2.0 s, the only time hits hurt it (a pogo or attacks). Charge
  14 damage. No contact damage.
- **D3 teaching:** the arena's controls line adds the pogo ({jump} then {move_down} + {attack}); no new UI; the staged
  calls stay out of the fight.
- **D4 return beat:** Kaelen's and Elara's two closing lines move, word for word, into a new `north_field.dlg` node
  `boar_fight_after`, played on return; `boar_fight_staged` stays in the file, unplayed.
- **D5 (derived, from T13b's D6–D9; object if you want otherwise):** `dodge_chance` 0; attacks chosen without a roll;
  the player's universal parry blocks the charge's damage and staggers the boar, but a parry stagger is not dizzy (the
  armour holds); a hit outside dizzy does nothing (no HP, no hit-stun, no knockback).
- **QL-STORY-READY (GAPS G1–G8, all folded in by the user, 2026-11-05):** every boar value named (G1); a charge long
  enough to cross the arena (G2); the bridge trigger stops after a hand-off (G3); the reload replay fixed (G4, D6);
  off-screen culling off for the boar (G5); dizzy, knockback and the parry's end specified (G6, D7, D8); the combo
  multiplier pinned (G7); the resume after the village's fade-in, with the triggers held off (G8). Second pass (GAPS N1,
  N2 and advisories A1–A6, all folded in by the user): the off-screen check reads the notifier, not the flag (N1); the
  resume between `:93` and `:95`, awaiting the fade (N2); dizzy on a connected timer (A1); no hop while dizzy (A2);
  `zone_level` 3 stated (A3); DDA 85 confirmed as the range's top (A4); refuse's replay named in Out of Scope (A5); the
  transitioning guard explicit (A6). Third pass (GAPS N3, folded in by the user): the off-screen telegraph timed at
  about 1200 px, inside detection range, not at 2000 px (N3); the fade await skipped when there is no `fade_rect`.
- **D6 reload fix (user, 2026-11-05):** in the village's `_ready`, `ch1_corrupted_boar_defeated` also sets
  `_field_resolved` and `_alarm_done`, so no field outcome (fight, calm or nest) replays or pays again after a load.
  This was an S08-era behaviour; T13c fixes it because the boar's pay-once depends on it.
- **D7 no knockback while dizzy (user, 2026-11-05):** a hit while dizzy takes HP but leaves the boar where it hit the
  wall.
- **D8 (derived, as the guardian's `stagger()`):** a parry ends the charge, the boar staggers (armour holds), then
  RECOVER and the cooldown.
- **Tech debt (user, 2026-11-05):** the guardian's likely off-screen slowdown (G5) is logged as TD-041, not fixed here.
- **D9 parry outside an attack (user, 2026-11-05, stage A review):** a parry stagger that lands while the boar is not
  telegraphing or charging (RECOVER or CHASE) leaves `attack_cooldown` at least `ATTACK_COOLDOWN`, so a parry never lets
  it telegraph at once.
- **D10 dizzy cue (user, 2026-11-05, stage A review):** a small label of stars above the body, shown only while dizzy;
  no tint (a modulate change would be recorded as the rest colour by `EnemyBase._sprite_rest_modulate` and corrupt later
  hit flashes).
- **`/code-review` (2026-11-06): CHANGES REQUIRED, user chose fix and re-review:** R1 Mara's shop opened over the
  hand-off when her first talk was the third afternoon beat (the shop's pausing modal survived into the arena); R2 no
  case for pause mid-charge or while dizzy; R3 hits only tested while the boar was idle; R4 C4's HP-kept check compared
  full HP after a win that makes the player invulnerable. Also folded in: D9's cooldown floor scaled by the difficulty
  multiplier, as `EnemyBase`'s RECOVER and the guardian's (a change to D9's wording); `_alarm_done` set in the field's
  end; parry cases during the telegraph and on a dizzy boar; control runs for the mid-charge retry, a real-input jump
  and once per charge; the pogo's damage number on the armoured boar logged as TD-042 (`player_combat.gd`, protected
  here).
- **D11 other suites through the field (user, 2026-11-06, stage B):** `ch1_rooms_test` (S08's) also drove the village's
  alarm with the first choice, now "Fight it.", and read the freed village; it picks *calm* there instead, since its
  subject is the house and the shrine. The boar suite's CI step is raised to 8 minutes (its runner timeout is 420 s,
  three times about 126 s).

---

## Acceptance Criteria

- [ ] AC-1 **The boar.** `scripts/combat/enemies/field_boar.gd` extends `EnemyBase` (class `FieldBoar`, `enemy_name`
      "Corrupted Boar"). Its values are named members at the top of the script: `BOAR_MAX_HEALTH` 45, `CHARGE_TELEGRAPH`
      0.6 s, `CHARGE_DAMAGE` 14, `CHARGE_SPEED` 420 px/s, `CHARGE_MAX_TIME` 3.5 s (420 × 3.5 = 1470 px, more than the
      1232 px between the walls' inner faces for a 48-px body, so every charge that starts in the arena reaches a wall),
      `DIZZY_TIME` 2.0 s, `RECOVER_TIME` 0.8 s, `ATTACK_COOLDOWN` 1.2 s, `DETECTION_RANGE` at least `ARENA_WIDTH`
      (1280), `MOVE_SPEED` 0 (it does not walk between charges), `CHARGE_HITBOX_SIZE` `Vector2(60, 36)` and
      `CHARGE_HITBOX_OFFSET` `Vector2(30, -20)` (it reaches |30| + 30 = 60 px from the centre, within the parry's 120
      px, and stands no higher than the 40-px body, so a jump clears it), `CHARGE_SWEEP_ACTIVE` 0.02 s (a fresh hit box
      each physics frame, as the guardian's), `BOAR_CONTACT_DAMAGE` 0 and `BOAR_DODGE_CHANCE` 0. Off-screen culling is
      off for the boar (an override of `_setup_screen_notifier()` that sets up nothing), so its AI runs every physics
      frame wherever the camera is (`enemy_base.gd:254-261` otherwise runs it every third frame off-screen). It has one
      attack, the charge (`AttackType.CHARGE`), never chosen by a roll: after its cooldown it telegraphs for
      `CHARGE_TELEGRAPH` (÷ the difficulty multiplier, 0.25 s floor), wherever the player stands, then runs toward the
      side the player was on at launch at `CHARGE_SPEED` without turning. The charge hits the player at most once, for
      `CHARGE_DAMAGE` × `get_enemy_damage_multiplier()` (applied once, by the hit box). It ends when the boar meets an
      arena wall (`is_on_wall()` after `move_and_slide()`): then it is **dizzy** for `DIZZY_TIME` of game time (a
      `_dizzy` flag and `_stun_active` both true, timed by `create_timer(DIZZY_TIME, false).timeout.connect(...)`, a
      connection dropped when the boar is freed and whose handler returns at once if the boar is DEAD; no movement, no
      attack; a hit while dizzy leaves `velocity.x` and `velocity.y` 0, so it neither slides nor hops, D7); or after
      `CHARGE_MAX_TIME` without a wall: then RECOVER, not dizzy. **Armour (D2, D5):** only while `_dizzy` does a hit
      take HP (EnemyBase's normal damage, the pogo's × 1.8 included); outside dizzy a hit takes no HP, starts no
      hit-stun, no knockback and no hit flash. A parry blocks the charge's damage, staggers the boar, ends the charge
      and sends it to RECOVER then the cooldown (D8, a `stagger()` override); the armour holds during that stagger.
      After dizzy: RECOVER, then the cooldown, then the next telegraph. `max_health` goes through `EnemyBase`'s level
      scaling. No `reset_for_retry()`. Nothing in `enemy_base.gd` changes.
- [ ] AC-2 **The row.** `STORY_FIGHTS["ch1_boar"]`: `enemy_script` the boar's; `enemy_type` `"field_boar"`; `enemy_name`
      `"StoryFightBoar"`; `enemy_size` `Vector2(48, 40)` and `enemy_color` `Color(0.7, 0.15, 0.15)` (the village
      marker's); the enemy spawned inside the first frame (x ≤ 840); `default_return_scene`
      `res://scenes/chapter1/oakhaven_village.tscn`; `flags` `["ch1_boar_fight_won"]`; shards in the boar's colour,
      `shard_count` 8, the other shard keys as the slime's; a procedural daytime backdrop (ground `Color(0.25, 0.55,
      0.3)`, the village's; sky `Color(0.55, 0.72, 0.88)`; a field path `Color(0.4, 0.3, 0.18)`; `trees` empty, the
      field is open); the controls line with the pogo: the slime row's line with `{jump} then {move_down} + {attack} —
      Pogo` inserted before `{defend} — Parry` (it fits the 1280-px line). `validate_story_fight` returns no message for
      it. `story/STORY_BIBLE.md` §5 gains a `ch1_boar_fight_won` row. Nothing else in `combat_arena.gd` changes.
- [ ] AC-3 **Hand-off, fight choice only.** When `boar` resolves as *fight* (`ch1_boar_fought` set), the village does
      not play `boar_fight_staged`: it stashes the afternoon (`_stash_afternoon()`), sets the return point to the north
      field (`NORTH_FIELD_POS + (0, -90)`), sets `story_fight_id = "ch1_boar"` and `story_fight_return_scene` to the
      village, and changes scene to the arena through `SceneTransitions` (`COMBAT_ENTRY`), once, within 0.5 s of the
      choice (measured to the `change_scene` call: `SceneTransitions.is_transitioning` turns true). Nothing else in the
      village runs after the hand-off: when the field was started by the bridge trigger (`_on_bridge_trigger`, which
      awaits `_run_north_field()` and then plays the bridge), it returns at once (no `bridge` line, no `ch1_bridge_*`
      flag, `_bridge_done` unchanged). *Calm* and *nest* never load the arena and play exactly as today (their flags,
      the 5 corruption for calm, Elara's trust for nest, then the field's end: `ch1_corrupted_boar_defeated`, 100 gold,
      50 XP).
- [ ] AC-4 **The fight.** In the arena the boar fight behaves as T13a's: one enemy `StoryFightBoar`, the player's death
      a retry with a fresh boar and full HP, Root Access and Perfect Delete refused, no XP, gold or item drops from the
      arena (`loot_table` null, no pickup node), GameState COMBAT. The win spawns 8 shards of the boar's colour, sets
      `ch1_boar_fight_won` once, keeps the player's HP, emits `story_fight_resolved("win")` and changes scene once to
      the village (`COMBAT_EXIT`). A player death mid-charge retries as any death: a new boar, and no hit from the old
      charge after the restore (with the player's invulnerability cleared, so the check can fail). A boar killed while
      dizzy wins; a kill is only possible while dizzy (the armour).
- [ ] AC-5 **Return.** The village rebuilt after the win: the player at the north field, the afternoon restored from the
      stash (no second alarm). In `_ready` between the HUD refresh (`ch1_oakhaven_village.gd:92-93`) and the `if
      _entrance_done: return` (`:95-96`, which always returns on the way back): `_field_running` is set true at once, so
      `_busy()` holds the boar and bridge triggers off until the beat ends; then the village awaits its own 1.5 s
      fade-in tween (`:89-90`, started but not awaited today); then `boar_fight_after` plays (Kaelen's "...It was still
      trying to get back to the nest. Right up until the end." and Elara's "I know. I saw.", text unchanged); then the
      field's end as today, once: `ch1_corrupted_boar_defeated`, 100 gold, 50 XP, `_field_resolved` true,
      `_field_running` false; the bridge is reachable as today. The resume is decided by flags, not by the stash: with
      `ch1_boar_fight_won` set and `ch1_corrupted_boar_defeated` unset, the village plays the return beat and pays once;
      with both set it plays nothing and pays nothing. **Reload (D6):** whenever `ch1_corrupted_boar_defeated` is set,
      `_ready` sets `_field_resolved` and `_alarm_done` true, so after a load no field outcome (fight, calm or nest)
      replays its alarm or choice or pays again, and walking onto the boar trigger does nothing. Leaving the arena by
      the pause menu's main menu leaves no story meta, no stash and no `ch1_boar_fight_won` (the menu path calls
      `GameManager.reset_game()`, which clears `TRANSIENT_METAS`).
- [ ] AC-6 **Tests.** A new suite `tests/integration/combat/boar_fight_test.gd` (own `BOAR FIGHT RESULT` line) checks
      AC-1 to AC-5 through cases C1–C5 below, every runtime number under one pin helper applied before the boar spawns
      (player level 1; DDA score 52.5 so the difficulty multiplier is 1.0, re-applied before each charge;
      `selected_difficulty` NORMAL; `player_stats.defense` 0; `ng_plus_cycle` 0; the boar's `zone_level` 0;
      `ChoiceConsequences.active_buffs` cleared; accessibility invincibility off; the GameJuice combo reset, its
      multiplier asserted 1.0 before the pogo case), written to the fields directly (never `set_difficulty` /
      `set_accessibility`, which save `user://game_settings.cfg`), snapshotted and restored; the player's HP restored to
      full before each charge; timing watched in game time. `chapter1_route_test` drives the boar arena on its fight
      route (the boar's API: dizzy it, then damage to 0), adds `ch1_boar_fight_won` to a `T13C_NEW_FLAGS` list (as
      `T13B_NEW_FLAGS`), checks its route still sets the four field flags and pays once, and gains a one-writer check
      (`"ch1_boar_fight_won"` once in `combat_arena.gd`; the village reads it with `has_flag` and never sets it;
      STORY_BIBLE §5 has its row). `phase0_blockers_test`'s arena hook finishes whichever story enemy the arena holds
      (`_story_enemy`), not only the slime, so its fight-choice route goes through the boar arena. Watched failing: the
      new suite's cases fail on today's code. Mutations, one per run, each caught by its named check: (a) the charge
      turns toward the player mid-run → C1's no-turn check (the test moves the player behind the boar mid-charge); (b)
      the telegraph left at EnemyBase's 0.55 s → C1's telegraph check; (c) the charge deals `CHARGE_DAMAGE × 1.6` → C1's
      charge-damage check; (d) no dizzy on the wall (RECOVER instead) → C1's dizzy check; (e) the armour removed (hits
      always take HP) → C1's armour check; (f) the armour also blocks hits while dizzy → C1's dizzy-damage check; (g) a
      parry stagger counts as dizzy → C1's parry-armour check; (h) the damage multiplier applied twice → C1's scaled
      damage check; (i) the telegraph not divided by the difficulty multiplier → C1's scaled telegraph check; (j)
      `dodge_chance` left at 0.15 → C1's check of the `dodge_chance` field; (k) calm hands off too → C3's calm check;
      (l) the resume ignores `ch1_corrupted_boar_defeated` (pays twice) → C5's save-and-load check (no
      `boar_fight_after`, no payment after a load; the first return still pays once); (m) the row's flag left out → C4's
      flag check; (n) the village still plays `boar_fight_staged` before the hand-off → C3's 0.5 s check; (o) the
      village sets `ch1_boar_fight_won` itself → the route test's one-writer check; (p) the bridge trigger carries on
      after a hand-off → C3's bridge check; (q) the reload fix removed → C5's reload check; (r) the off-screen override
      removed → C1's off-screen check; (s) knockback while dizzy → C1's dizzy-still check; (t) `CHARGE_MAX_TIME` back to
      2.5 s → C1's wall-to-wall check; (u) D9 removed (a stagger outside an attack leaves the cooldown) → C1's
      stagger-in-RECOVER check; (v) D10 removed (the cue never shown) → C1's and C4's cue checks. Added after
      `/code-review` (2026-11-06): (w) Mara's handler carries on after a hand-off → C3's Mara check; (x) contact damage
      8 → C1's contact check; (y) a parried charge not sent to RECOVER → C1's parried-charge check; (z) the charge sweep
      keeps querying after a hit (its `_charge_hit_pending` condition dropped) → C1's once-per-charge check with the
      player's invulnerability cleared (a first (z), one of the flag's two clearing sites removed, survived as an
      equivalent mutant: either site alone stops a second hit); (aa) the return beat does not wait for the fade-in →
      C5's fade check; (ab) a hit during the telegraph or the charge starts a hit-stun → C1's hits-during-attack check;
      (ac) the arena's win heals the player to full → C4's HP-kept check (the player's HP set to 40 before the win).
      Registered in `tests/suite_limits.txt`, `run_all_tests.ps1` and `ci.yml`; the full local run green on 4.6.3 and CI
      green.
- [ ] AC-7 **Evidence.** Live-renderer screenshots, each opened and signed off by the user, labelled live renderer in
      the evidence README (`production/qa/evidence/2026-11-ch1-fights/`, a T13c section): `boar.png` (player, boar, HUD,
      backdrop, the controls line with the pogo), `boar-charge.png` (the charge's telegraph showing), `boar-dizzy.png`
      (the boar dizzy at the wall) and `boar-return.png` (the village's return beat). The README labels the backdrop
      procedural and the body a placeholder. CHANGELOG `feat:` entry; `git diff --check` clean.

---

## Implementation Notes

- The boar: model it on `broken_mile_guardian.gd` (named constants; values set before `super._ready()`; `_state_chase`
  starting the telegraph from range; `_begin_telegraph` through `super`, then its own duration; the charge in
  `_execute_attack` / `_state_attack` with `velocity.x = 0` when it ends; `_apply_hitstun` and `stagger` overrides). The
  direction is fixed at launch (`_charge_dir`); `move_and_slide()` then `is_on_wall()` ends the charge into dizzy.
- Armour: override `take_damage(amount, knockback_source)`; outside dizzy return before `super` (no HP, no flash, no
  hit-stun); while dizzy call `super`, then set `velocity.x = 0` (D7). Keep "dizzy" separate from a parry's stagger (a
  `_dizzy` flag and a game-time timer, not `_stun_active` alone: no EnemyBase state ticks a dizzy timer, since STUNNED
  only applies friction and `_hitstun_frozen` skips the AI).
- Off-screen: override `_setup_screen_notifier()` with a body that sets up nothing, so `_is_on_screen` stays true.
- Parry (D8): copy the guardian's `stagger()` override (`broken_mile_guardian.gd:161-171`): end the charge, zero
  `velocity.x`, RECOVER then the cooldown.
- The village's bridge trigger: after `await _run_north_field()` in `_on_bridge_trigger`, return when a hand-off is
  under way (`_is_transitioning` or not inside the tree).
- The village's reload fix (D6): in `_ready`, `if GameManager.has_flag("ch1_corrupted_boar_defeated"):` set
  `_field_resolved` and `_alarm_done` true.
- The village: in `_run_north_field()`, replace the `boar_fight_staged` branch with a `_hand_off_to_boar_fight()` in the
  meeting's shape (a transitioning guard: `_is_transitioning = true` set before `change_scene`, which the bridge
  trigger's return check reads; `_stash_afternoon()`; `GameManager.set_return_point`; both story metas;
  `SceneTransitions.change_scene(ARENA, COMBAT_ENTRY)`), then return. Split the field's end (the defeated flag, gold,
  XP, `_field_resolved`, `_field_running` false) into one function both paths call. In `_ready`, between `:93` and `:95`
  (after the HUD refresh, before `if _entrance_done: return`): with `ch1_boar_fight_won` set and
  `ch1_corrupted_boar_defeated` unset, set `_field_running` true at once, await the fade-in tween straight after
  creating it (keep a reference to it; skip the await when there is no `fade_rect`, since the tween is only created `if
  fade_rect:`, `:87-90`), run `boar_fight_after`, then the field's end.
- `north_field.dlg`: add `~ boar_fight_after` with the two lines copied exactly; leave `boar_fight_staged` in place.
- Test drivers: the boar dizzied by placing it against a wall and letting a charge run, or by calling the boar's own
  dizzy entry if it has one; HP to 0 with `take_damage` while dizzy; the player's pogo through its own input actions
  (`jump`, then `move_down` + `attack`) in one C1 case so the pogo's ×1.8 on a dizzy boar is checked once for real.
- The pin helper: copy `guardian_fight_test.gd`'s (it already writes the fields directly and restores them), and add the
  GameJuice combo reset.
- Commit only with the user's OK: `feat(ch1): the north-field boar is a real fight` with `Task: Y1-P0-T13c`.

---

## Out of Scope

- `enemy_base.gd`, `player_combat.gd`, collision layers, the arena's story-fight code; production art for the boar.
- The calm and nest branches; any text change in `north_field.dlg` (one node added with existing lines only).
- The village's other afternoon state on a reload (the afternoon beats and `_seen` lines are not saved; only the field's
  replay after fight, calm or nest is fixed here, D6; *refusing* the field never sets `ch1_corrupted_boar_defeated`, so
  its alarm can still replay after a load, as today); the bridge.
- The guardian's off-screen slowdown (TD-041).
- T14b (the playthrough bot's Chapter 1 fight legs), beyond the two arena hooks this story must fix to stay green.
- A gamepad-only run of the boar fight (the arena's input path is shared, covered by T13a's AC-7), other than the pogo
  driven through input actions once.

---

## QA Test Cases

- **C1 (AC-1)** — the boar alone in a test arena, the pins applied before it spawns, the player's HP full and the DDA
  score re-applied before each charge: the declared constants equal AC-1's values and `max_health` is 45; after the
  cooldown it telegraphs 0.6 s (± one frame, game time) wherever the player stands (near, mid, far), never a roll;
  off-screen culling is off: the boar has no `ScreenNotifier` child, its `_screen_notifier` is null, and `_is_on_screen`
  stays true with the player moved 2000 px away (forcing the flag false is not the test: `enemy_base.gd:254` keys the
  frame skip on the flag itself); and with the player about 1200 px away (off-screen for a 1280-px view, inside
  `DETECTION_RANGE`) the telegraph is still 0.6 s; the charge keeps its launch direction when the player crosses behind
  it (no turn); a player in its path loses exactly 14, once per charge; a player who jumps it loses nothing; a charge
  launched at one wall reaches the other and ends dizzy; at the wall it is dizzy (`_dizzy` and `_stun_active` true) for
  2.0 s (± one frame, game time), still, with no attack; a hit while dizzy takes 15 and leaves its x unchanged; with
  walls removed a charge ends after 3.5 s in RECOVER, not dizzy; outside dizzy a 15-damage hit leaves HP 45, starts no
  hit-stun and no knockback; a pogo through input actions on a dizzy boar takes 27 (the combo multiplier asserted 1.0
  first) and on an armoured boar bounces the player and takes nothing; a parry of the charge → no damage, a stagger, the
  charge over, RECOVER then the cooldown, and a hit during that stagger leaves HP unchanged; contact within 30 px with
  physics running and no charge → no damage; `dodge_chance` 0; scaled (the boar's `zone_level` 3 with the player at
  level 1, which gives `get_enemy_damage_multiplier()` 1.5 (`enemy_base.gd:1534-1542`) and also scales the boar's HP and
  the player's damage to it, so the case reads the boar's `max_health` after spawn; the DDA score 85, the top of
  `remap(score, 20, 85, 0.75, 1.25)`, giving 1.25): the charge takes 14 × `get_enemy_damage_multiplier()` and telegraphs
  0.6 ÷ the difficulty multiplier, both multipliers asserted at 1.5 and 1.25 before the hits.
- **C2 (AC-2)** — `validate_story_fight(STORY_FIGHTS["ch1_boar"])` empty (also the table suite's QA 1); the row's values
  as listed; the controls line renders the pogo with the bound keys and fits the line.
- **C3 (AC-3)** — the village driven to `boar`: fight → the stash and the return point set, `story_fight_id ==
  "ch1_boar"`, the return meta is the village, `SceneTransitions.is_transitioning` true within 0.5 s of the choice and
  the arena the next scene, no `boar_fight_staged` line before it; the field started from the bridge trigger with fight
  chosen → the same, and no `bridge` line, no `ch1_bridge_*` flag and `_bridge_done` unchanged before the arena; calm →
  no arena, `ch1_boar_calmed`, 5 corruption, the field's end once; nest → no arena, `ch1_boar_nest_rebuilt`, the field's
  end once.
- **C4 (AC-4)** — the boar dizzy, HP to 0 → 8 shards of `Color(0.7, 0.15, 0.15)`, `ch1_boar_fight_won` once, player HP
  unchanged, no XP or gold from the arena, no pickup node and `loot_table` null, GameState COMBAT,
  `story_fight_resolved("win")`, one change to the village; HP to 0 outside dizzy is not possible (the armour); player
  HP to 0 → a new `StoryFightBoar`, player HP full, `story_fight_retries` + 1; player HP to 0 mid-charge → the same, and
  with the player's invulnerability cleared each frame, no hit from the old charge for 1 s after the restore.
- **C5 (AC-5)** — the village loaded after the win: the player at the north field; the return beat starts only after the
  fade-in, and the boar and bridge triggers do nothing while it plays; `boar_fight_after`'s two lines seen; no alarm
  line; `ch1_corrupted_boar_defeated` set, gold +100 and XP +50 once; `_field_resolved` true; the bridge trigger then
  answers; a save there and a load → no `boar_fight_after`, no second payment, and the player walked onto the boar
  trigger → no dialogue, no payment (the same after a calm or a nest outcome and a load); pause → main menu during the
  fight → no story meta, no stash, `ch1_boar_fight_won` unset.
- **C6 (AC-6/7)** — suites registered and green (the boar suite, the route test, `phase0_blockers_test`); the route
  test's one-writer check; mutations (a)–(ac) each failing its own check; four screenshots opened and signed off.

---

## Test Evidence

**Story Type**: Integration (with screenshots — the fight is player-visible)
**Required evidence**: `tests/integration/combat/boar_fight_test.gd` (passing), the extended
`tests/integration/story/chapter1_route_test.gd` and `tests/integration/playthrough/phase0_blockers_test.gd`
(passing), `production/qa/evidence/2026-11-ch1-fights/` (the README's T13c section with the AC map and the user's
sign-off, `boar.png`, `boar-charge.png`, `boar-dizzy.png`, `boar-return.png`, the suite logs, the mutation logs, the
full-run log).
**Run result**: OBSERVED — live renderer (Vulkan Forward+, RTX 2050): `boar.png`, `boar-charge.png`,
`boar-dizzy.png`, `boar-return.png`, opened and signed off by the user 2026-11-06.

---

## Dependencies

- Depends on: Y1-P0-T13a (Complete, the story-fight mode), Y1-P0-T13b (Complete, the guardian this boar is modelled on),
  TD-031 (Complete), TD-038 (Complete), Y1-P0-S08 (Complete, the village's stash and return point).
- Unlocks: Y1-P0-T14b (the playthrough bot's Chapter 1 fight legs).

---

## Completion Notes

**Completed**: 2026-11-06
**Criteria**: 7/7 passing locally. Deferred: AC-6's "CI green", recorded after the push (as T13b).
**Deviations** (advisory, accepted at close):
- D9–D11 added during the work: D9 a parry outside an attack keeps the cooldown, its floor scaled by the difficulty
  multiplier (as EnemyBase's RECOVER); D10 the star cue; D11 `ch1_rooms_test` calms the boar. D11's CI step is 10
  minutes, not 8 (raised in `/code-review` round 1); the runner timeout is 540 s.
- The dizzy timer is `create_timer(DIZZY_TIME, false, true)` (physics frames, stable ±1 frame), not AC-1's
  `create_timer(DIZZY_TIME, false)`.
- A wall ends a charge only when the boar runs into it (wall normal opposing the charge), after the first frame.
- An extra `ATTACK_RANGE` (60) the base class needs; the row keeps a `tree` colour though `trees` is empty.
- A one-hit-per-charge override of `_on_enemy_attack_hitbox_body_entered` (each frame's charge box outlives a frame and
  keeps its own hit list), beyond the plan text.
- C1's off-screen readings at 2000 px and 1200 px are INFO lines, not checks; the structural check (no ScreenNotifier
  child, no notifier reference) is the gate (mutation (r)).
- The route test also follows the fight on its early-alarm and hesitate-then-help routes.
- AC-6's mutation list gained (ac); (z) was redefined after its first definition proved equivalent.
- Mutation (e) (armour removed) is caught by eight named checks but also produces script errors afterwards (a freed boar
  read at `boar_fight_test.gd:348`), as in every (e) run.
**Test Evidence**: Integration: `tests/integration/combat/boar_fight_test.gd` 138/0 (three runs,
`t13c_boar_fight_fix4_run1-3.log`); all 29 mutations caught on the final test file (`t13c_mutation_<id>_fix4.log`);
full local run 28/28 on 4.6.3 (`t13c_run_all_story_done.log`); screenshots and README in
`production/qa/evidence/2026-11-ch1-fights/`.
**Code Review**: Complete — `/code-review` three rounds (CHANGES REQUIRED, CHANGES REQUIRED, APPROVED WITH
SUGGESTIONS, suggestions applied); LP-CODE-REVIEW APPROVE; QL-TEST-COVERAGE GAPS (advisory).
**Open, not logged as debt** (user chose close without tech-debt rows):
- QA gaps: Root Access and Perfect Delete refusal is tested on the slime row only (`story_fight_test.gd`); `_alarm_done`
  after a load is not asserted directly (mutation (q) is caught through the other reload checks); no check for the
  0.25 s telegraph floor, `max_health` through level scaling, or the dizzy timer's DEAD return.
- Code: `DETECTION_RANGE` is exactly its 1280 minimum (the player very likely cannot leave the circle in a 1232-px
  arena; unverified); `_begin_telegraph` and the stagger tint repeat EnemyBase's colours and floor; three private
  helpers lack doc comments.
- Noted at screenshot sign-off: Kaelen below full HP in two shots; HUD labels read poorly on the daytime sky.
