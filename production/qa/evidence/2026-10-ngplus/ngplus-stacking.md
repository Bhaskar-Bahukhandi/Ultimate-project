# NG+ buff stacking: test evidence

- **Story**: Y1-P0-T07 (NG+ buffs stacked every cycle)
- **Date**: 2026-10-20
- **Engine**: Godot 4.6.3.stable (headless)
- **Suite**: `AethelgardPrototype/tests/unit/ngplus/ngplus_buff_stacking_test.gd`
- **Result**: `NGPLUS UNIT RESULT: 192 passed, 0 failed` (exit 0). Full output: `ngplus_unit.log` in this folder.
  (150/0 before the code-review additions; the full-suite log `run_all.log` is from that 150-check version.)

## What the test proves

Starting a New Game+ cycle must return the player's base ATK, base DEF and max HP to the baseline
(B = 15 / 0 / 100) no matter which story route was played, how many cycles were run, or how the
buffs were obtained. Before the fix, `start_new_game_plus()` carried the buff-inflated stats into the
next cycle and then re-applied the buffs, so they stacked (ATK +36, MaxHP -5 per kill-route cycle).

It covers, in order: T1 kill route over three cycles, T2 spare and purge routes, T3 negative max HP
total, T4 level-up against a no-buff control, T5 exclusive-flag flips, T6 duplicate flag set,
T7 max HP floor, T8 carry-over (gold/charms/items/equipment), T9 no buffs, partial totals keys and
the frozen save keys, T10 `CHOICE_BUFFS` integral guard (and no `max_mp` buff), T11 `soul_gain_bonus`
not carried, T12 NG+ twice in a row (characterization). Code review added the armor/defense checks
and the spare route to T8, the `max_mp` guard to T10, and T12.

Regression check (per `.claude/rules/test-standards.md`): the suite was run against the unfixed code
first and failed 21 checks, then passed 150/0 against the fixed code. After the code-review additions
the suite was run again against HEAD's unfixed `game_manager.gd` (a detached scratch worktree, since
removed): 167 passed / 25 failed (`ngplus_unit_unfixed.log`), including the new T8 checks
(spare route `defense: 8 vs 39`); 192/0 on the fixed code. T10's `max_mp` guard and T12 pass on both
(data guard / characterization).

## How it was run

```
powershell -NoProfile -File tests/run_phase0_tests.ps1 -Script res://tests/unit/ngplus/ngplus_buff_stacking_test.gd
```

run from `AethelgardPrototype/`. The runner isolates `user://` (`aeth_phase0_test`) and the suite
refuses to start otherwise. It is registered in `tests/run_all_tests.ps1` (`Long = $false`) and in
`.github/workflows/ci.yml`; `tests/integration/meta/test_layout_test.gd` passes 6/0.

## BEFORE / AFTER

Numbers are ATK / DEF / MaxHP. E = end of the cycle (buffs applied), P = player right after
`start_new_game_plus()`. Expected P = baseline 15 / 0 / 100 for every row.

BEFORE comes from the earlier run against the unfixed code. AFTER was captured from the fixed code
by a one-off throwaway script (deleted afterwards); T1 E/P are also printed by the suite itself
(`ngplus_unit.log`), and the E values for T2 spare, T3, T5, T6 and T9b match the literals the suite asserts.

| Case | BEFORE E | BEFORE P (unfixed) | AFTER E (fixed) | AFTER P (fixed) |
|------|----------|--------------------|-----------------|-----------------|
| T1 kill route, cycle 1 | 51 / 0 / 95 | 51 / 0 / 95 | 51 / 0 / 95 | 15 / 0 / 100 |
| T1 kill route, cycle 2 | 87 / 0 / 90 | 87 / 0 / 90 | 51 / 0 / 95 | 15 / 0 / 100 |
| T1 kill route, cycle 3 | 123 / 0 / 85 | 123 / 0 / 85 | 51 / 0 / 95 | 15 / 0 / 100 |
| T2 spare route | n/a (not recorded) | 18 / 31 / 135 | 18 / 31 / 135 | 15 / 0 / 100 |
| T2 spare + purge | n/a (not recorded) | 18 / 31 / 125 | 18 / 31 / 125 | 15 / 0 / 100 |
| T3 absorbed-only | n/a (not recorded) | ATK 25, MaxHP 85 | 25 / 0 / 85 | 15 / 0 / 100 |
| T5 knight flip (killed, then spared) | n/a (not recorded) | 15 / 5 / 115 | 15 / 5 / 115 | 15 / 0 / 100 |
| T5 wraith flip (absorbed, then restored) | n/a (not recorded) | 15 / 5 / 110 | 15 / 5 / 110 | 15 / 0 / 100 |
| T6 duplicate set (same flag twice) | n/a (not recorded) | 23 / 0 / 100 | 23 / 0 / 100 | 15 / 0 / 100 |
| T9b purge-only | n/a (not recorded) | MaxHP 90 | 15 / 0 / 90 | 15 / 0 / 100 |

BEFORE-run caveat: the unfixed-code numbers were reported from the earlier run as given in the
task; where only P was recorded, the E column says so rather than inferring it. The "BEFORE E" for
T1 cycles 2 and 3 shows the stacking (+36 ATK, -5 MaxHP per cycle).

## Frozen save keys (nothing added, removed or renamed)

Top-level keys of the save dictionary (37), identical before and after NG+ (asserted in T9):

```
_checksum, achievements, arena_stats, boss_checkpoints, choice_consequences, corruption_level,
current_chapter, current_region, current_scene, current_state, dda_performance_score,
dda_recent_deaths, dda_recent_kills, equipped_charms, free_travel_story_scene, glitch_meter,
inventory_equipment, inventory_gold, inventory_items, lore_journal, ng_plus_cycle,
perfect_delete_charges, perfect_delete_used, player_overworld_position, player_stats,
playtime_seconds, relationships, shop_discount, side_quests, source_key_count, speedrun_active,
stats, story_flags, timestamp, titles_earned, unlocked_charms, version
```

`choice_consequences` sub-keys (2): `active_buffs`, `party_combat_members`.

NG+ writes no file: T9 lists the isolated `user://` directory before and after
`start_new_game_plus()` and the listings are equal (`d:logs`, `f:achievements.save` both times).
Saving remains an explicit player action.

## Deviations from the story/plan

- `GameManager.get_save_data()` does not exist. The save dictionary is built inline inside
  `save_game()`, so the test builds the real save by calling `save_game(1)` in the isolated
  `user://` directory and reading the file back, instead of calling a getter.

## Known limitations

The max HP floor over-correction (correcting max HP upwards when a negative total would push it
below the floor) is unreachable with the current data: the lowest reachable max HP is 85 (T3,
wraith absorbed only), against a -15 buff, so the floor never engages through real play. T7 covers
the floor only by injecting max HP values directly (T+2, T+1, T, 1 with the +35 spare total); it does
not reach a negative-total over-correction. If a future buff pushes max HP toward the floor, that
path needs its own test.

Old saves (code review): a pre-v1.2 save is loaded through `ChoiceConsequences.rebuild_from_flags()`,
which rebuilds `active_buffs` without applying them to the stats. If such a save's stats never had
the buffs, NG+ now subtracts them anyway. Untested and unfixed here (the fix belongs in
`choice_consequences.gd`); see the story's known limitations.
