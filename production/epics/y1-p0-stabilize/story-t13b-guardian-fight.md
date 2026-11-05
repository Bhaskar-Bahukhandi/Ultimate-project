# Story T13b: The Broken Mile guardian is a real side-scroll fight

> **Epic**: Y1-P0 Stabilize (Sprint 001)
> **Task ID**: Y1-P0-T13b (`production/plan/_source/Y1-P0.json#Y1-P0-T13`, the guardian day; sprint plan row Y1-P0-T13b)
> **Status**: Complete
> **Layer**: Feature
> **Type**: Integration
> **Estimate**: 3 days (sprint row: 2). Day 1 the guardian's script and its row; day 2 the Broken Mile's hand-off,
> timeout and resume; day 3 tests, mutations, screenshots. Over the row's 2 days because the guardian is new AI, where
> the slime's script already existed. T13a took 4 days against 2.
> **Manifest Version**: N/A — `docs/architecture/control-manifest.md` does not exist
> **Last Updated**: 2026-11-05

## Context

**GDD**: none for Chapter 1 combat encounters (as T13a). **Source of record**: the plan entry above, guardian day:
"Create `scripts/combat/enemies/broken_mile_guardian.gd` from `enemy_base.gd` with 2 attacks and a telegraph", "Only
the 'refuse and fight' choice starts the arena; FRACTURE_ENTITIES filter and aggression-down still resolve without
combat", "Return to the path with `guardian_resolved = true` and the right reaction node", "Screenshot the fight"; done:
"Guardian fight reachable only from the fight branch". Sprint row: "As T13a; `…/guardian.png`".
`dialogue/ch1/broken_mile.dlg`: "A1-P04 — The First Edit. A corrupted guardian blocks the only stable pass";
`root_refused`: "The player won the fight without editing."
**Requirement**: N/A — no TR-ID registered.

**ADR Governing Implementation**: N/A — no ADR exists. The story-fight mode is T13a's, and TD-031 made a fight a row
of `STORY_FIGHTS`; this story adds a row and an enemy script, not a mode.
**ADR Decision Summary**: N/A
**ADR Version**: N/A

**Engine**: Godot 4.6 (4.6.3 at `C:/Godot`; every run sets `GODOT` to the 4.6.3 console exe, TD-036) | **Risk**: HIGH
(`docs/engine-reference/godot/VERSION.md`, 4.6 row)
**Engine Notes**: no post-cutoff API is planned. The guardian uses `EnemyBase`'s own state machine: the TELEGRAPH
state (`_begin_telegraph`, `enemy_base.gd:415`, a tint tween and a "!" marker), `AttackType.CHARGE` and
`AttackType.SLAM` (`_execute_attack`, `:483`), and `stagger()` on a parry (`:982`). Three things in that code
matter here: `_choose_attack()` rolls `randf()` over `attacks_available`; `_execute_attack()` may chain a combo with
`randf() < 0.4` while `combo_count < max_combo`; and `_begin_telegraph()` divides the telegraph time by
`GameManager.get_difficulty_multiplier()` (minimum 0.25 s). CHARGE deals `contact_damage × 1.2`, SLAM `× 1.6`, with
fixed telegraphs of 0.55 s and 0.6 s.

**Control Manifest Rules**: NOT ASSESSED — no control manifest.

**Performance**: no new cost expected — one enemy in the arena, as the slime's fight.

**AGENTS.md protected areas — allowed by the user for this story (D1, 2026-11-05):** *combat* (the new enemy script
`scripts/combat/enemies/broken_mile_guardian.gd` and a `ch1_guardian` row in `combat_arena.gd`'s `STORY_FIGHTS`) and
*story progression* (a new story flag `ch1_guardian_fought` and a resume point in the Broken Mile). Not touched:
collision layers, hitboxes in `enemy_base.gd`, `player_combat.gd`, the arena's story-fight code, save/load schema (a
story flag is data in the existing flags dictionary), Source Key, true ending, NG+, world map. The filter and calm
branches are unchanged. Production-art fallback: unchanged (the guardian uses the arena's placeholder body; the
backdrop is procedural and labelled so).

### Audit facts (2026-11-05, on HEAD `c7fecb2`)

1. **The guardian is staged, not played.** `ch1_path_to_oakhaven.gd`: on `do guardian_attacks` a 78 × 56 `ColorRect` of
   `Color(0.32, 0.26, 0.2)` slides from (1100, 392) to x 800 (`:298-304`). `guardian_directive` sets
   `root_access_unlocked` and opens the Root Access panel (`do root_access_open`, `_run_root_access_panel`, `:368`).
   Kaelen stands at x 600 and Elara at x 680 (`_walk(600, 680)`, `:240`).
2. **Three outcomes** (`start_path_sequence`, `:246-256`): *filter* (`_target_filter` = FRACTURE_ENTITIES, Apply) →
   `_guardian_turns_away()`, `root_used`; *calm* (aggression below 1.0, Apply) → `root_used_calm`; *fight* (the panel's
   "Don't edit it. Fight." button, `_on_root_access_refused`, or 180 s with the panel open, `:390`) →
   `_stage_guardian_fight()` (3 shakes and flashes, the rectangle fades) → `root_refused`, which sets
   `ch1_root_discovered_unused`. Filter and calm set `ch1_root_first_edit` and `ch1_slime_root_access_tutorial` and add
   10 corruption. All three go on to `rest_stop`, `ridge` and Oakhaven.
3. **No test drives the fight branch.** `chapter1_route_test` picks filter (`:179`); `phase0_blockers_test`'s
   `_ch1_poke` picks calm (`:384`). `_root_choice` and the 180 s limit are scene state with no test seam.
4. **The arena takes a second row.** `STORY_FIGHTS` has `ch1_slime` only. Root Access and Perfect Delete are refused in
   every story fight (TD-031 D3). `validate_story_fight` refuses a row whose enemy script does not extend `EnemyBase`
   (TD-038), and `story_fight_table_test`'s QA 1 and QA 2 validate every row and every script in
   `scripts/combat/enemies/`, so the new row and script are checked there without new cases. The guardian has no
   `ENEMY_SIZES` / `ENEMY_COLORS` entry, so its row must give `enemy_size` and `enemy_color`.
5. **The Broken Mile saves normally** (not in `GameManager.NON_RESUMABLE_SCENES`) and replays `start_path_sequence` from
   the top on every load.
6. **Scale.** Slime 30 HP, 8 contact damage; the player 100 HP, 15 damage a hit (`player_combat.gd:171`).
7. **Later chapters** read a "guardian" verdict from the Aldric choice (`ch4_null_court.gd:290`), not from this fight;
   nothing outside Chapter 1 reads `ch1_root_discovered_unused` or `ch1_root_first_edit`.

### Decisions (user, 2026-11-05)

- **D1 permission:** combat (the new script and row) and story progression (`ch1_guardian_fought` and the resume) are
  allowed.
- **D2 guardian:** 60 HP (4 hits). Two attacks, each telegraphed: a *charge* from range (0.6 s telegraph, rushes along
  the ground, 14 damage, meant to be jumped or dashed) and a *stomp* up close (0.45 s telegraph, 12 damage, parryable).
  Stats live in the script, like `slime.gd`.
- **D3 timeout:** the 180 s give-up on the panel starts the arena too: everything that leads to `root_refused` goes
  through the real fight.
- **D4 win beat:** shards like the slime's, in the guardian's own colour, more of them than the slime's 7 (row data
  only).
- **QL-STORY-READY (GAPS G1–G9, all folded in by the user, 2026-11-05):** numbered ranges and test positions, the charge
  started from range, the pins behind the damage numbers, a parry driver and its observable, mutations (c) and (h)
  rewritten, the flag registered, a drop check and a mid-charge retry, the no-panel fallback, the estimate in
  sprint-status.
- **D5 overrides (user, 2026-11-05):** the guardian overrides `_state_chase` (it telegraphs from range),
  `_begin_telegraph`, and the SLAM and CHARGE branches of `_execute_attack` / `_state_attack`, with its own named
  ranges, telegraph times, hit boxes and damages. `enemy_base.gd` stays unchanged.
- **D6 no contact damage (user, 2026-11-05):** `contact_damage` 0; the guardian hurts only through its two telegraphed
  attacks.
- **D7 both attacks parryable (user, 2026-11-05):** the player's parry is universal and works on both; the charge is
  still meant to be jumped or dashed. No change to `player_combat.gd`.
- **QL-STORY-READY second pass (GAPS N1–N7, all folded in by the user, 2026-11-05):** the damage multiplier applied
  once, the charge parry timed from its hit, `attack_range` given a value, the contact check run with physics on, the
  pins written to fields (not the saving setters) before the guardian spawns, mutation (k) reworded, the C3 drivers
  named.
- **D8 charge reach (user, 2026-11-05):** the charge's hit box reaches at most 110 px from the guardian's centre, so a
  parried charge always staggers it (a parry staggers enemies within 120 px of the player). The 120 px is a
  straight-line distance and the 110 px horizontal, so this holds while the two centres differ in height by about
  48 px or less; on the arena floor they do.
- **D9 poise while attacking (user, 2026-11-05, during /dev-story review):** a player hit during the guardian's
  TELEGRAPH or ATTACK takes HP but does not interrupt it (EnemyBase's light hit-stun is ignored there); only a parry
  does. A hit-stun that starts in RECOVER ends with the attack cooldown set, so a hit never skips the cooldown. Hits in
  CHASE or IDLE stun as EnemyBase does and do not raise the cooldown (`/code-review` R1: raising it there let steady
  hits stop the guardian ever attacking). `dodge_chance` 0: no random dodge on a hit.
- **D10 telegraph through `super` (user, 2026-11-05, during /dev-story review):** `_begin_telegraph` calls
  `super._begin_telegraph()`, then sets the guardian's own duration and restarts the tint at that length.
- **Accepted deviations (user, 2026-11-05):** a `stagger()` override (a parry landing through an earlier frame's hit
  box ends the attack in RECOVER) and the guardian's extra named constants; `T13B_NEW_FLAGS` in the route test
  instead of the frozen Chapter 1 flag list; the guardian suite's timeout 180 s, raised to 240 s (2026-11-05) when
  the suite grew to about 78 s.
- **`/code-review` (2026-11-05): CHANGES REQUIRED, user chose fix and re-review:** R1 (above), R2 (the panel's give-up
  overwrote a choice made in its last tick), R3 (the multiplier clauses of AC-1 tested at 1.0 only), R4 (this record);
  with the charge stopping at its travel end and `dodge_chance` 0.

---

## Acceptance Criteria

- [x] AC-1 **The guardian.** `scripts/combat/enemies/broken_mile_guardian.gd` extends `EnemyBase` (class
      `BrokenMileGuardian`, `enemy_name` "Mosswood Guardian"). Its values are named members at the top of the script
      (D5): `GUARDIAN_MAX_HEALTH` 60, `STOMP_RANGE` 70 px, `CHARGE_RANGE` 360 px (≤ its `detection_range`, set before
      `super._ready()`), `attack_range` = `STOMP_RANGE`, `STOMP_TELEGRAPH` 0.45 s, `CHARGE_TELEGRAPH` 0.6 s,
      `STOMP_DAMAGE` 12, `CHARGE_DAMAGE` 14, the stomp's hit box (wider than `2 × STOMP_RANGE`, so a stomp started at
      the range edge can land), the charge's hit box (reaching at most 110 px from the guardian's centre, D8), the
      charge's speed and travel time (it covers at least 200 px), and `contact_damage` 0 (D6). It picks its attack by
      distance, never by `randf()`: the *stomp* (`AttackType.SLAM`) when the player is within `STOMP_RANGE`, the
      *charge* (`AttackType.CHARGE`) when between `STOMP_RANGE` and `CHARGE_RANGE`. It starts the telegraph itself from
      anywhere in that span (an `_state_chase` override): `EnemyBase` only starts one inside `attack_range`
      (`enemy_base.gd:411`). Each attack runs through `EnemyBase`'s TELEGRAPH state first. The telegraph time is the
      attack's own divided by the difficulty multiplier (`EnemyBase`'s scaling and 0.25 s floor kept); each hit passes
      its raw damage to `_deal_damage_in_attack_hitbox`, which applies `get_enemy_damage_multiplier()` once
      (`enemy_base.gd:684`), and `max_health` goes through `EnemyBase`'s level scaling. Under the suite's pins (below)
      that is 60 HP, 0.6 s / 14 for the charge and 0.45 s / 12 for the stomp. One attack, then RECOVER (`max_combo` 1,
      so `_execute_attack`'s `randf()` combo branch never runs). Both attacks can be parried by the player's universal
      parry (D7): the guardian staggers (`_stun_active` true for its stagger time, no new attack meanwhile) and the hit
      does no damage. Standing within 30 px of it does no damage. The charge stops when its travel time ends (no slide
      in RECOVER). Poise (D9): a hit during TELEGRAPH or ATTACK takes HP and does not interrupt the attack; a hit-stun
      from RECOVER ends with the cooldown set; hits in CHASE do not raise the cooldown; `dodge_chance` 0. No
      `reset_for_retry()` (the arena respawns the enemy, as for the slime). Nothing in `enemy_base.gd` changes.
- [x] AC-2 **The row.** `STORY_FIGHTS["ch1_guardian"]`: `enemy_script` the guardian's; `enemy_type`
      `"broken_mile_guardian"`; `enemy_name` `"StoryFightGuardian"`; `enemy_size` `Vector2(78, 56)` and `enemy_color`
      `Color(0.32, 0.26, 0.2)` (the staged rectangle's); the enemy spawned inside the first frame (x ≤ 840, as the
      slime's); `default_return_scene` `res://scenes/chapter1/path_to_oakhaven.tscn`; `flags` `["ch1_guardian_fought"]`;
      shards in the guardian's colour, `shard_count` 10, the other shard keys as the slime's; a procedural backdrop from
      the Broken Mile's colours (sky `(0.1, 0.07, 0.14)`, ground `(0.05, 0.09, 0.04)`, path `(0.14, 0.1, 0.06)`, trees
      `(0.035, 0.065, 0.025)`, `ch1_path_to_oakhaven.gd:81-145`); the slime row's controls line. `validate_story_fight`
      returns no message for it. Nothing else in `combat_arena.gd` changes. `story/STORY_BIBLE.md` §5 gains a
      `ch1_guardian_fought` row (set by the arena's story-fight table; read by the Broken Mile to resume at
      `root_refused`), beside `ch1_slime_fought`'s.
- [x] AC-3 **Hand-off, fight branch only.** When the panel resolves as *fight* (the Fight button; the give-up after
      `root_panel_timeout` seconds, 180 by default and a member a test can lower; or the no-panel fallback,
      `ch1_path_to_oakhaven.gd:371-372`), the Broken Mile does not run `_stage_guardian_fight()` (it goes): it sets
      `story_fight_id = "ch1_guardian"` and `story_fight_return_scene` to its own scene, hides the dialogue and changes
      scene to the arena through `SceneTransitions` (`COMBAT_ENTRY`), once, within 0.5 s of the choice, with the staged
      guardian still fully visible (`modulate.a` 1.0) at that moment. *Filter* and *calm* never load the arena and play
      exactly as today (`root_used` / `root_used_calm`, their flags and the 10 corruption).
- [x] AC-4 **The fight.** In the arena the guardian fight behaves as T13a's: one enemy `StoryFightGuardian`, the
      player's death a retry with a fresh guardian and full HP, Root Access and Perfect Delete refused, no XP, gold or
      item drops, GameState COMBAT. The win spawns 10 shards of the guardian's colour, sets `ch1_guardian_fought` once,
      keeps the player's HP, emits `story_fight_resolved("win")` and changes scene once to the Broken Mile
      (`COMBAT_EXIT`). XP, gold and the inventory are unchanged, no pickup node is in the arena after the guardian's
      death and its `loot_table` is null. A player death while the guardian is mid-charge retries as any death: the old
      guardian is disabled, a new instance spawns, and the player takes no hit from the old charge after the restore.
      The rest of T13a's arena behaviour (the win/retry races, pause, the kit refusal from keyboard and pad) is shared
      code, tested on the slime row by `story_fight_test` and not repeated here.
- [x] AC-5 **Resume.** `path_to_oakhaven.tscn` loaded with `ch1_guardian_fought` set: no walk-in, no `tree_flicker` to
      `guardian_directive` lines, no Root Access panel, no arena; Kaelen at x 600 and Elara at x 680, no guardian;
      `root_refused` plays (setting `ch1_root_discovered_unused`), then the walk, `rest_stop`, `ridge` and Oakhaven as
      today. `rest_stop` shows the not-edited line ("you looked at that beast like you could read it"). It resumes the
      same way whenever the flag is set, including from a save made later in the scene, so it never hands off twice.
      `root_access_unlocked` stays set. Leaving the arena by the pause menu's main menu leaves no story meta and does
      not set `ch1_guardian_fought`.
- [x] AC-6 **Tests.** A new suite `tests/integration/combat/guardian_fight_test.gd` (own `GUARDIAN FIGHT RESULT` line)
      checks AC-1, AC-3, AC-4 and AC-5 through cases C1–C5 below. Every runtime number in AC-1 is checked under one
      named pin helper, applied before the guardian spawns (its HP is scaled in `_ready`, `enemy_base.gd:216`) with the
      DDA score re-applied before each attack: player level 1, DDA score 52.5 (the multiplier is `remap(score, 20, 85,
      0.75, 1.25)`, `game_manager.gd:1078`, so 52.5 gives 1.0; 50 gives 0.981, and every hit the player takes moves the
      score), `selected_difficulty` NORMAL, `player_stats.defense` 0, `ng_plus_cycle` 0, the guardian's `zone_level` 0,
      `ChoiceConsequences.active_buffs` cleared (enemy weakness off), accessibility invincibility off. The helper writes
      these fields directly, never through `set_difficulty` / `set_accessibility` (both save
      `user://game_settings.cfg`), snapshots them first and restores them after the suite. The player's 1.0 s
      invulnerability runs out between hits. AC-1's declared values are also checked as plain constants.
      `chapter1_route_test` adds `ch1_guardian_fought` to its flag list, checks it stays unset on its filter route, and
      gains a one-writer check like `_test_t13a_flag_registered` (`chapter1_route_test.gd:1815`):
      `"ch1_guardian_fought"` appears once in `combat_arena.gd`, the Broken Mile reads it and never sets it, and
      STORY_BIBLE §5 has its row. Watched failing: the new suite's cases fail on today's code (no guardian script; the
      Broken Mile stages the fight). Mutations, one per run, each caught by its own check: (a) the guardian picks by
      `randf()` → C1's choice check; (b) the charge's telegraph left at EnemyBase's 0.55 s → C1's telegraph check; (c)
      the stomp deals `STOMP_DAMAGE × 1.6` (EnemyBase's SLAM factor) → C1's stomp-damage check; (d) filter
      hands off too → C3's filter check; (e) the timeout does not hand off → C3's timeout check; (f) the resume check
      removed → C5; (g) the row's flag left out → C4's flag check; (h) `_stage_guardian_fight()` still runs before the
      hand-off → C3's 0.5 s and still-visible check; (i) no `_state_chase` override → C1's mid-range charge check; (j)
      `contact_damage` left at a non-zero value → C1's contact check; (k) the arena's `enemy.set("loot_table", null)`
      line removed → C4's `loot_table` null check; (l) the poise override removed → C1's poise checks; (m) the Broken
      Mile sets `ch1_guardian_fought` itself → the route test's one-writer check. Added after `/code-review`
      (2026-11-05): (n) the guardian multiplies its own damage by `get_enemy_damage_multiplier()` as well → C1's scaled
      damage check; (o) the telegraph not divided by the difficulty multiplier → C1's scaled telegraph check; (p) the
      charge keeps sliding in RECOVER → C1's charge-stop check; (q) the cooldown raised after every hit-stun → C1's
      steady-hits check; (r) the give-up ignores a choice made in its last tick → C3's last-tick check. The scaled
      checks
      run once with the guardian's `zone_level` above the player's level and the DDA score away from 52.5. Registered
      in `tests/suite_limits.txt`, `run_all_tests.ps1` and `ci.yml`; the full local run green on 4.6.3 and CI green.
- [x] AC-7 **Evidence.** Live-renderer screenshots, each opened and signed off by the user, labelled live renderer in
      the evidence README: `production/qa/evidence/2026-11-ch1-fights/guardian.png` (player, guardian, HUD, backdrop,
      controls line), `guardian-charge.png` (the charge's telegraph showing), `guardian-shards.png` (the win beat) and
      `guardian-resume.png` (the Broken Mile's resume staging). The README labels the backdrop procedural and the body a
      placeholder. CHANGELOG `feat:` entry; `git diff --check` clean.

---

## Implementation Notes

- The guardian (D5): set `detection_range` (≥ `CHARGE_RANGE`) and `attack_range` before `super._ready()`: `EnemyBase`
  builds its detection and attack circles from them in `_ready` (`enemy_base.gd:1385`, `:1398`). Override
  `_choose_attack()` (distance, no roll), `_state_chase` (start the telegraph between `STOMP_RANGE` and `CHARGE_RANGE`,
  once `attack_cooldown` is 0), `_begin_telegraph()` (set the attack's own duration, then divide by the difficulty
  multiplier with EnemyBase's 0.25 s floor), and the SLAM and CHARGE branches of `_execute_attack()` / `_state_attack()`
  (the guardian's hit boxes and the raw `STOMP_DAMAGE` / `CHARGE_DAMAGE`, through `_deal_damage_in_attack_hitbox`, which
  applies the damage multiplier and lets the player's parry work). `max_combo = 1`. If any of this needs a change to
  `enemy_base.gd`, stop and ask.
- A parry (D7) is the player's: `player_combat.take_damage` checks `parry_active` (`:1894`) and staggers enemies within
  120 px (`:2022`). After a parry `_execute_attack` sets RECOVER over STUNNED (`enemy_base.gd:518`), so the observable
  is `_stun_active` and no new attack for the stagger time, not `current_state`.
- The suite's pin helper: the list in AC-6, written to the fields directly, snapshotted first and restored after the
  suite.
- The Broken Mile: in `start_path_sequence`, check `GameManager.has_flag("ch1_guardian_fought")` first, as the Elara
  meeting checks `ch1_slime_fought`; a `_resume_after_guardian_fight()` places the two characters and runs
  `root_refused`, then the existing tail (`_walk(760, 840)`, `rest_stop`, `ridge`, `transition_to_oakhaven()`). Split
  the tail into its own function so both paths share it.
- The hand-off: `_hand_off_to_guardian_fight()` in the meeting's shape (`ch1_elara_meeting.gd:242-251`), with a
  transitioning guard.
- `root_panel_timeout`: a member, default 180.0, read by the panel's wait loop.
- Test drivers: `StoryFightGuardian.take_damage(max_health)` for the win; the panel's `_on_root_access_refused()` for
  the Fight button; the no-panel fallback by setting `apply_button = null` after `_ready` (nulling `root_access_panel`
  before `_ready` crashes at `:49`); the timeout by lowering `root_panel_timeout`. The 0.5 s hand-off limit is measured
  to the `change_scene` call, not to the scene swap: `SceneTransitions.is_transitioning` turns true within 0.5 s while
  `story_fight_id == "ch1_guardian"`, and the arena is then the next `current_scene` (`SceneTransitions` exposes no
  target, only `is_transitioning`, `scene_transition_manager.gd:44`).
  `player._start_parry()` (`player_combat.gd:1237`, a 0.18 s window): for the stomp once the guardian's
  `telegraph_timer` ≥ its telegraph time − 0.1 s; for the charge 0.1 s before its hit lands (it hits after travelling,
  not when the telegraph ends); the player within 120 px. The attack-choice checks run the guardian through physics
  frames; they never call `_begin_telegraph()` themselves. The contact check keeps the guardian's physics running (not
  T13a's `_freeze`, which stops `_physics_process`, where contact damage runs), `is_hostile` true and `player_ref` set,
  and holds `attack_cooldown` high every frame so no attack starts.
- `production/sprint-status.yaml`: T13b's `estimate_days` 3, as this story.
- T14b: its bot picks calm, so it never reaches this fight; its `_ch1_poke` arena branch names `StoryFightSlime` only
  and is left as it is.
- Commit only with the user's OK: `feat(ch1): the Broken Mile guardian is a real fight` with `Task: Y1-P0-T13b`.

---

## Out of Scope

- The boar (T13c); the playthrough bot's Chapter 1 fight legs (T14b).
- `enemy_base.gd`, `player_combat.gd`, collision layers, the arena's story-fight code; production art for the guardian.
- TD-032 (main-menu route and pad jump/dash/parry gaps), TD-034 (slime colour), TD-039 (row checks for
  `default_return_scene` and `enemy_name`), TD-040.
- Any change to `broken_mile.dlg`'s text; the filter and calm branches.
- A gamepad-only run of the guardian fight (the arena's input path is the slime's, covered by T13a's AC-7).

---

## QA Test Cases

- **C1 (AC-1)** — the guardian alone in a test arena, the pins applied before it spawns and the DDA score before each
  attack, and before each attack the player's `current_health` and `GameManager.player_stats["hp"]` restored to full
  and the 1.0 s invulnerability run out (the 10 attacks deal 130, more than the player's 100 HP, and a death would
  start a retry and move the DDA score): the declared constants equal AC-1's values (`attack_range` 70) and
  `max_health` is 60; the player at 50 px →
  telegraph then SLAM; at 200 px → telegraph then CHARGE, started without the player entering `attack_range` (physics
  frames, no direct `_begin_telegraph()`); the same choice on 5 repeats each; telegraph times 0.45 s / 0.6 s (± one
  frame); the player's HP drops by exactly 12 / 14; after one attack the state is RECOVER, never a second attack
  straight away; a parry of the stomp and, separately, of the charge (each timed as in the notes) → `_stun_active` true,
  no new attack for the stagger time, player HP unchanged; the player held within 30 px for 1.0 s with physics running,
  `is_hostile` true, `player_ref` set and no attack under way → HP unchanged. Poise (D9): a hit during the stomp's
  telegraph → HP down, not stunned, the stomp lands on time; a hit in RECOVER → no telegraph before the cooldown; hits
  every 0.9 s while it walks in → it still starts a telegraph; `dodge_chance` 0. The charge's travel ends within one
  frame of `CHARGE_SPEED × CHARGE_TRAVEL_TIME` from its start, and RECOVER adds no slide. Scaled (R3): with the
  guardian's `zone_level` above the player's level and the DDA score away from 52.5, the stomp and the charge each take
  raw damage × `get_enemy_damage_multiplier()` and telegraph for raw time ÷ the difficulty multiplier.
- **C2 (AC-2)** — `validate_story_fight(STORY_FIGHTS["ch1_guardian"])` empty (also covered by the table suite's QA 1);
  the row's values as listed.
- **C3 (AC-3)** — the Broken Mile driven to the panel: Fight → `story_fight_id == "ch1_guardian"`, the return meta is
  the Broken Mile, one change to the arena within 0.5 s with the staged guardian's `modulate.a` still 1.0, no
  `root_refused` line before it; `root_panel_timeout` set to 0.5 → the same; the no-panel fallback → the same; filter →
  `root_used`, no arena; calm → `root_used_calm`, no arena; corruption and flags as today; the last-tick case (R2):
  `root_panel_timeout` 0.05 and the filter applied before the panel's first 0.1 s tick → `root_used`, no arena, 10
  corruption once.
- **C4 (AC-4)** — guardian HP to 0 → 10 shards of `Color(0.32, 0.26, 0.2)`, `ch1_guardian_fought` once, player HP
  unchanged, XP, gold and the inventory unchanged, no pickup node and `loot_table` null, `story_fight_resolved("win")`,
  one change to the Broken Mile; player HP to 0 → a new `StoryFightGuardian` instance, player HP full,
  `story_fight_retries` + 1; player HP to 0 while the guardian is mid-charge → the same, and player HP still full 1 s
  after the restore.
- **C5 (AC-5)** — the Broken Mile loaded with the flag: the first line shown is `root_refused`'s first, no panel, no
  arena; `rest_stop` reached with the not-edited line; a save there and a load → the first line is `root_refused`'s
  again, no arena; pause → main menu during the fight → no meta, the flag unset.
- **C6 (AC-6/7)** — suites registered and green; the route test's one-writer check for `ch1_guardian_fought`; mutations
  (a)–(r) each failing its own check; four screenshots opened and signed off.

---

## Test Evidence

**Story Type**: Integration (with screenshots — the fight is player-visible)
**Required evidence**: `tests/integration/combat/guardian_fight_test.gd` (passing), the extended
`tests/integration/story/chapter1_route_test.gd` (passing), `production/qa/evidence/2026-11-ch1-fights/` (the README's
T13b section with the AC map and the user's sign-off, `guardian.png`, `guardian-charge.png`, `guardian-shards.png`,
`guardian-resume.png`, the suite logs, the mutation logs, the full-run log).
**Run result**: OBSERVED — live renderer (Vulkan Forward+, RTX 2050), capture 4 on the final code: `guardian.png`,
`guardian-charge.png`, `guardian-shards.png`, `guardian-resume.png` in `production/qa/evidence/2026-11-ch1-fights/`,
each opened and signed off by the user (2026-11-05).

---

## Dependencies

- Depends on: Y1-P0-T13a (Complete, the story-fight mode), TD-031 (Complete, a fight is a row), TD-038 (Complete, the
  enemy-script check).
- Unlocks: Y1-P0-T14b (the bot's Chapter 1 fight legs, with T13c).

---

## Completion Notes

**Completed**: 2026-11-05
**Verdict**: COMPLETE WITH NOTES
**Criteria**: 7/7 passing; AC-6's "CI green" is DEFERRED (the changeset is not pushed; local full run 27/27 on Godot
4.6.3, `t13b_run_all_rev2.log`).
**Deviations** (advisory, user-accepted):
- The guardian's `stagger()` override and its extra named constants (beyond AC-1's list).
- `T13B_NEW_FLAGS` in `chapter1_route_test` instead of the frozen Chapter 1 flag list (AC-6 said "its flag list").
- The guardian suite's timeout 240 s (180 s first; the suite grew to about 78 s).
- D9 (poise, `dodge_chance` 0) and D10 (`_begin_telegraph` through `super`), added during the stage A review.
- Estimate 3 days against the sprint row's 2.
**Test Evidence**: Integration tests `AethelgardPrototype/tests/integration/combat/guardian_fight_test.gd` (new, 129
checks) and `AethelgardPrototype/tests/integration/story/chapter1_route_test.gd` (417 checks, the T13b flag checks);
watched failing before the code (0/29, 84/24); mutations (a)–(t) and the R1 watch-fail each caught by a named check,
the older ones re-run on the final suite; four screenshots signed off. All in
`production/qa/evidence/2026-11-ch1-fights/` (README, T13b section).
**Code Review**: Complete. `/code-review` three rounds (CHANGES REQUIRED → fixed: R1 a hit-stun lockout, R2 the
give-up overwriting a last-tick edit, R3 the multiplier clauses tested at 1.0 only, R4 the story record; then F1 a
check that could not fail; then APPROVED WITH SUGGESTIONS). QL-TEST-COVERAGE GAPS (stale mutation evidence, closed by
the re-run; the rest below). LP-CODE-REVIEW APPROVE.
**Open, not fixed** (noted in the evidence README; no tech debt logged at the user's choice):
- QL: poise during a hit mid-charge is not checked; no mutation removes the hand-off guard; the range boundaries
  (70/71, 360/361 px) are not checked; AC-3's "hides the dialogue" has no assertion.
- LP: a stagger arriving in RECOVER can leave the cooldown at 0; the stagger tint can stay yellow after a late hit
  flash (as in EnemyBase); the 0.25 s floor and the cooldown formula are copied from EnemyBase.
- Review suggestions: the hand-off guard does not reset if `change_scene` refuses (as T13a's); the resume does not
  redraw the cart and flicker tree; the pause menu during any scene transition (project-wide); the shard contrast and
  the Kaelen/Elara placeholder overlap in the screenshots.
**Known after close**: push and confirm CI is green on this changeset (AC-6).
