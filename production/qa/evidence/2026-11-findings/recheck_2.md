# Y1-P0-S05 AC-2 — strict re-check 2 (19 rows marked `fixed`)

Date: 2026-11-08. Branch `fix/phase0-playthrough-blockers`, working tree as found (read-only).
Method: each finding re-read at its `source` line in `AethelgardPrototype/CODE_REVIEW_2026-10-04.md`,
every stated part checked against today's code (paths below are under `AethelgardPrototype/`),
cited commits checked with `git show --stat`. The row's `evidence` text was not taken as a conclusion.
No Godot run: this is a code-reading check, not a runtime test.

| id | verdict | what you checked (file:line) | note |
|---|---|---|---|
| CR-H4.2-02 | CONFIRMED | `grep '\.paused\s*='` over scripts/: only scripts/core/context_stack.gd:120 writes `get_tree().paused`; root_access_panel.gd:219/271, pause_screen.gd:150/153, shop_system.gd:497/567 push/pop contexts; pause recomputed from all open contexts (context_stack.gd:117-121) | cutscene_manager.gd:962 `paused` is the manager's own var. bbfd4a7 touched all 3 modals + context_stack; c386abc adds the guard test. |
| CR-H4.2-05 | CONFIRMED | ui/status_window.gd:56-68 (only opening gated on `ch1_oakhaven_entered`; close always pops), :35-41 (Esc/pause also closes it) | bbfd4a7 touched status_window.gd. |
| CR-H4.2-06 | CONFIRMED | shop_system.gd:497-503 (refused push emits `shop_closed` deferred); caller chapter1/ch1_oakhaven_village.gd:690-705; other early return :486 (`_is_open`) resolves when the open shop closes | The cutscene-block return at shop_system.gd:488-493 emits nothing, but `/root/CutsceneManager` is not an autoload (project.godot) so it is dead; if that lookup is ever made live it reintroduces this softlock. |
| CR-H4.2-08 | CONFIRMED | ui/credits_screen.gd:211-228 (`_scroll_active` set only after height measured, fallback 2000), :232-244 | 43ebeaf touched credits_screen.gd. |
| CR-H4.3-01 | CONFIRMED | inventory_system.gd:443-445 (equip swap), :470-472 (unequip), :485-487 `_return_equipped_item` writes `items[id] += 1` with no stack cap; no other equipment return path (game_manager.gd:1682 is load) | 43ebeaf touched inventory_system.gd. |
| CR-H4.4-02 | CONFIRMED | combat/player_combat.gd:575-580 (`target_vx = dir*speed*speed_multiplier` before lerp); only other use is the setter :2136-2137 | 859a30d touched player_combat.gd. |
| CR-H4.4-03 | CONFIRMED | combat/player_combat.gd:804-842 (shape query: any touched enemy body counts; origin `has_point` only in the empty-result fallback :834-839); pogo :1283 and upslash :1726 use the same query | 78bc24b touched player_combat.gd. Fallback has no line of sight (separate audit P1-9 item). |
| CR-H4.4-05 | CONFIRMED | combat/combat_arena.gd:1342-1343 busy guard, :1372/:1385 set/clear around the 0.6 s dissolve, :1356-1360 boss refused before `use_perfect_delete()`; after the dissolve target is freed/null so a press gets "NO TARGET" | Adjacent risk, not the stated defect: tutorial mode has no "already died" check, so a slime killed by melee during the dissolve reaches `_victory()` twice (:1407 via `_on_slime_died`, :1421) = +50 XP/+10 gold twice. |
| CR-H4.4-07 | CONFIRMED | chapter2/ch2_arena_district.gd:345-351 death calls `GameManager.record_arena_loss()` -> game_manager.gd:1232-1234 zeroes `win_streak`; mid-run exits gated on `not arena_running` (:427); `attempt_flee()` returns false outside random encounters (random_encounter_system.gd:937) | `abort_arena()` (arena_manager.gd:166) still has no caller. `_time_attack_timeout` (:252-259) emits defeat without a loss, but `start_time_attack`/`start_endurance` have no callers, so it can't be reached. |
| CR-H4.4-09 | CONFIRMED | combat/combat_arena.gd:1262 Root Access pushed with the arena as owner; ui/root_access_panel.gd:219 pushed with the panel (child of scene, ch2_arena_district.gd:148-153); context_stack.gd:52-56/104-108 pops on owner `tree_exiting` -> unpause | bbfd4a7 touched combat_arena.gd/root_access_panel.gd. |
| CR-H4.5-01 | CONFIRMED | combat/enemy_base.gd:19-43 (setters call `_on_property_hacked` only while `_applying_hack`), :1100-1113 `apply_hack` sets/clears it; arena apply goes through `apply_hack` (combat_arena.gd `_on_root_access_apply`); no other caller of `_on_property_hacked` | 43ebeaf touched enemy_base.gd. |
| CR-H4.6-01 | CONFIRMED | dialogue/ch1/broken_mile.dlg:62 and :88 set both flags; chapter1/ch1_path_to_oakhaven.gd:251/:257 run those nodes on the main path; New Game -> opening_crash_site_hook.gd:7 -> elara_meeting -> ch1_elara_meeting.gd:302 -> path_to_oakhaven | 477b97c touched crash_site_hook/path; e91d10d added broken_mile.dlg. Tests assert both flags (full_playthrough_test.gd:194-195, phase0_blockers_test.gd:435-436). |
| CR-H4.6-02 | CONFIRMED | regions/ironhold_region.gd:522-525 admin gate requires `ch2_underground_complete` and hides once `ch2_administrator_proxy_defeated`; spoke chain :584-594 (arena bronze -> clock tower; clock_tower.dlg:91 unlocks underground); chapter2/ch2_administrator_boss.gd:392 sets the defeat flag before autosave | Alt route ch2_ironhold_city.gd:68/83/662 is also guarded on the defeat flag, and no script loads ironhold_city.tscn. The boss scene itself has no replay guard (relies on the gates). a902517 touched ironhold_region.gd. |
| CR-H4.7-01 | CONFIRMED | cutscene/cutscene_manager.gd:922-959 (`_play_gen += 1`, restore + single emit only if was playing); play_cutscene :150 and beat loops :181/:187/:407 exit on gen mismatch; no beat handler calls `change_state` (only :138/:171) | 43ebeaf touched cutscene_manager.gd. |
| CR-H4.7-02 | CONFIRMED | effects/tween_animator.gd:34, :112-116 base modulate stored once; `play_hurt` :521-548 fades to stored base, not live colour; enemy flash enemy_base.gd:897-912/919-927 uses rest colour | Residual helpers `flash_color` (:1179-1187) and `play_impact_flash` (:1263-1268) still capture live `modulate`; the impact flash has no callers, and `flash_color` is called only on hack (enemy_base.gd:1049), not on hit. |
| CR-H4.7-12 | CONFIRMED | glitch_overlay.gd:111-115 `_start_flash`; :117-121 `_update_shader` skips while flashing; :106-108 noise/chromatic refresh skipped while flashing; flash_glitch/trigger_glitch :176-206 call `_start_flash(duration)` | 43ebeaf touched glitch_overlay.gd. |
| CR-V07 | CONFIRMED | `git rev-parse --show-toplevel` = repo root; .github/workflows/ci.yml exists; AUDIT_AND_FIX_PLAN.md:176 strikes P0-7 with correction | 5068459/6468280 exist; 6468280 adds AUDIT_AND_FIX_PLAN.md. |
| CR-V08 | CONFIRMED | P1-2: game_manager.gd:1015-1016 DEF to `base_defense` and `defense` (recompute :828 uses base); P1-3: :989/:993 cap = `XP_THRESHOLDS.size()` (20), also :1025/:1031; P1-8: combat/player_combat.gd:344-352 releases only names that exist in project.godot `[input]` (no `dash`/`parry`) | 6468280 touched game_manager.gd and player_combat.gd. |
| CR-A-core-02a | CONFIRMED | side_quest_manager.gd:306-314 attack/defense boosts also added to `base_*`; recompute inventory_system.gd:513-522 and game_manager.gd:827-828 build from base | `max_hp` boost isn't recomputed anywhere. Same wipe pattern exists outside quests (choice_consequences.gd:210/213, random_encounter_system.gd:814 write only `attack`/`defense`): not this finding, a candidate new finding. 43ebeaf touched side_quest_manager.gd. |

## Totals

- CONFIRMED: 19
- PARTIAL: 0
- WRONG: 0

Non-blocking observations (outside the stated defects, candidates for new rows rather than reopening these):
1. combat_arena.gd tutorial Perfect Delete + melee kill during the dissolve -> double `_victory()` payout.
2. shop_system.gd:488-493 dead cutscene-block return would silently softlock callers if revived.
3. choice_consequences.gd:210/213 and random_encounter_system.gd:814 stat boosts are erased by the next equipment/corruption recompute.
4. arena_manager.gd `abort_arena()` remains dead code.
