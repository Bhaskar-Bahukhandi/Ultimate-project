# Y1-P0-S05: new findings from the status re-check side notes (2026-11-08)

Source: the side notes, "not counted" notes and "candidates for new findings" in `recheck_1.md` to
`recheck_4.md`, `hand_check_20_a.md` and `hand_check_20_b.md` (this folder). Each candidate was
re-read in today's code (branch `fix/phase0-playthrough-blockers`, working tree). Static reading
only: nothing was run. Coverage was searched in the open rows of `production/findings/findings.csv`
and in `docs/tech-debt-register.md`. Paths are under `AethelgardPrototype/scripts/`.

Kept candidates were appended to `docs/tech-debt-register.md` as TD-048 to TD-054
(Status Open, Priority `—`, Sprint Backlog). Header now: 54 items, 45 open.

## Kept

| # | candidate (source note) | file:line today | TD |
|---|---|---|---|
| 1 | Tutorial Perfect Delete pays `_victory()` twice (recheck_2, CR-H4.4-05) | combat/combat_arena.gd:1407, :1421, :1439 (no once-guard) | TD-048 |
| 2 | Stat write erased by a recompute: encounter NPC `temp_defense` (recheck_2, CR-A-core-02a) | combat/random_encounter_system.gd:814; game_manager.gd:827-828; inventory_system.gd:513-522 | TD-049 |
| 3 | `npc_defense_bonus` meta never cleared (recheck_1, CR-H4.1-07) | combat/random_encounter_system.gd:812, :815; game_manager.gd:680-685 | TD-049 |
| 4 | `abort_arena()` has no caller (recheck_2, CR-H4.4-07) | combat/arena_manager.gd:166, :208, :253, :264 | TD-050 |
| 5 | Write-only `arena_mode` / `arena_tier` metas (recheck_1, CR-H4.1-07) | regions/ironhold_region.gd:1110-1134; chapter2/ch2_arena_district.gd:277-287 | TD-050 |
| 6 | SOVEREIGN phase-5 corruption uncapped (recheck_1, CR-C14) | combat/enemies/sovereign_boss.gd:134-140, :549-556 | TD-051 |
| 7 | Wastes storm warning holds the player while damage ticks (recheck_1, CR-C02) | regions/fractured_wastes_region.gd:18, :320-332, :345-348 | TD-052 |
| 8 | `slowmo_moment` calls share one ContextStack id (recheck_3, CR-A-combat-04) | effects/game_juice.gd:739-759 | TD-053 |
| 9 | Clock Tower defeat flash drawn in world space (recheck_4, CL-1004-D7) | chapter2/ch2_clock_tower.gd:478-485 | TD-054 |

Notes on the kept rows:

- 2 and 3 are one row: the same effect (`temp_defense`), same lines. The meta part is close to
  findings CR-V12 (open, "reset_game misses ... metas"), whose evidence says metas are now reset.
  The stat wipe is not covered anywhere.
- 4 and 5 are one row. The write-only metas showed the player-visible side: the Ironhold menu
  offers Time Attack and Endurance and a bracket, and the arena ignores all three
  (`ch2_arena_district.gd:277-278` "For prototype, start with highest available tier").
  The time-attack timeout, also noted as unreachable in recheck_2, is folded in.
- 1: tutorial mode is entered only from `exploration/player_topdown.gd` `trigger_combat` (:330, :437)
  and `exploration/oakhaven.gd:228`. Whether those are on the live path was not checked.

## Dropped

| candidate (source note) | reason | file:line |
|---|---|---|
| shop_system dead `/root/CutsceneManager` branch would refuse without `shop_closed` (recheck_2) | Covered by findings CR-H4.2-01 (open), whose evidence names the same dead lookup. Whoever fixes it must emit `shop_closed` on that refusal, as the ContextStack refusal does (:500-503) | shop_system.gd:488-493 |
| choice_consequences stat writes erased by a recompute (recheck_2) | Not real now: `_apply_stat_mods` writes `base_attack` / `base_defense` as well | choice_consequences.gd:210-214 |
| SOVEREIGN crash-wave tween untracked (recheck_3) | Not a real problem: the base `die()` keeps the boss 0.6 s, longer than the 0.5 s tween, and the wave sits under the arena, so a scene change frees it | combat/enemies/sovereign_boss.gd:569-586; combat/enemy_base.gd die() |
| Write-only `entered_from_overworld` / `overworld_return_region` metas (recheck_1) | Dead writes with no behaviour effect | overworld/overworld.gd:431-432 |
| Melee fallback hit test has no line of sight (recheck_2, CR-H4.4-03) | Covered by findings CR-V11 (open) | combat/player_combat.gd:834-839 |
| `flash_color` / `play_impact_flash` still capture the live modulate (recheck_2, CR-H4.7-02) | Not visible: `play_impact_flash` has no caller; `flash_color` runs only on a hack, and the hack tint is meant to stay | effects/tween_animator.gd:1179-1187; combat/enemy_base.gd:1049-1053 |
| Pause save slots show no slot status (recheck_1, CR-C11) | Observation, not a defect; a corrupt file can't replace the `.bak`. Overwriting from the title is CR-C12 (open) | ui/pause_screen.gd:1089-1103 |
| Administrator boss scene has no replay guard (recheck_2, CR-H4.6-02) | Not reachable: both gates hide once the defeat flag is set | regions/ironhold_region.gd:522-525 |
| `phase10mm_capture.gd` has no user-dir guard (recheck_1, CR-C19) | Debug tool. Its scenes autosave only on boss defeat, not on load | docs/visual_review/phase10mm/ |
| One vulnerable frame per 15 in a `dash_master` dash chain (hand_check_20_b, CR-H4.4-01) | Timing margin, not a defect | combat/player_combat.gd:1157-1168 |
| NG+ / New Game legacy flight_707 prologue (recheck_1, CR-C03) | Design note, not a defect. recheck_1 and hand_check_20_a disagree on which path uses it | main_menu.gd:116-119 |
| 589 tracked logs, 47 MB (recheck_4, CR-A-tooling-06) | Context only, the note says so | — |
| Residual parts of PARTIAL rows: CR-A-tooling-05, CL-1004-D2, CL-1004-D3, CR-A-ui-03, CR-C12, CR-H4.6-03, CR-H4.7-03, CR-R4 | Covered by their own findings.csv rows. The S05 status update handles them, not a new row | see recheck_4, hand_check_20_a/b |
