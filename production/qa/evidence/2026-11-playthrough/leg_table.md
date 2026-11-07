# Y1-P0-T14b leg table: New Game to the credits

The order, kinds, flags and caps below are the suite's `LEGS` list
(`AethelgardPrototype/tests/integration/playthrough/full_playthrough_test.gd`), taken from the three runs' own log lines
(`leg NN ... s real, kind K, cap C s` and each leg's `AC-5 ... flags set at the hand-off` check). Runs:
`t14b_hopfix_run1.log`, `t14b_hopfix_run2.log`, `t14b_hopfix_run3.log` (Godot 4.6.3, local, 2026-11-07, on the final bot
`b6e7b29f…`, after the boar-flake and knight-hop fixes), each 405 passed, 0 failed. The earlier columns from
`t14b_run4..6.log` (before the code-review and hop fixes) are replaced; those logs are kept. Times are real seconds from
the leg's arrival to its hand-off. Cap rule (AC-6) for the T14b legs 00-26: at least 3x the slowest run and at least 60
s. Legs 27-65 are T14a's, with T14a's caps (60 s, trials 30 s). R5 marks a leg in `KNOWN_R5_DIALOGUE` (TD-043): its
scene hands off with the dialogue box still up.

| Leg | Scene | Kind | Flags checked at the hand-off | Cap s | Final 1 | Final 2 | Final 3 | Spread | 3x slowest | R5 |
|---|---|---|---|---|---|---|---|---|---|---|
| 00 | opening_crash_site_hook.tscn | room | ["ch1_opening_hook_signal_found", "ch1_opening_hook_complete", "plane_crash_completed"] | 60 | 0.3 | 0.4 | 0.3 | 0.1 | 1.2 |  |
| 01 | elara_meeting.tscn | story | [] | 60 | 1.8 | 1.8 | 1.8 | 0.0 | 5.4 |  |
| 02 | combat_arena.tscn | fight | ["first_slime_defeated", "ch1_slime_fought"] | 60 | 1.4 | 1.4 | 1.4 | 0.0 | 4.2 |  |
| 03 | elara_meeting.tscn | story | ["elara_first_truth", "ch1_elara_trusted", "elara_met", "ch1_elara_glitch_witch_met"] | 60 | 1.6 | 1.5 | 1.6 | 0.1 | 4.8 |  |
| 04 | path_to_oakhaven.tscn | story | ["ch1_broken_mile_entered", "ch1_ironhold_lead", "elara_arm_noticed", "ch1_data_vision_unlocked", "root_access_unlocked"] | 180 | 59.6 | 60.0 | 59.4 | 0.6 | 180.0 |  |
| 05 | combat_arena.tscn | fight | ["ch1_guardian_fought"] | 60 | 1.4 | 1.4 | 1.3 | 0.1 | 4.2 |  |
| 06 | path_to_oakhaven.tscn | story | ["ch1_guardian_fought", "ch1_root_discovered_unused", "ch1_personal_goal_set"] | 60 | 1.3 | 1.3 | 1.3 | 0.0 | 3.9 |  |
| 07 | oakhaven_village.tscn | room | ["ch1_oakhaven_entered", "ch1_northfall_registry_seen"] | 60 | 0.5 | 0.5 | 0.4 | 0.1 | 1.5 |  |
| 08 | elara_house.tscn | room | ["ch1_stew_done", "ch1_stew_asked_where", "ch1_elara_arm_talked"] | 60 | 1.3 | 1.3 | 1.3 | 0.0 | 3.9 |  |
| 09 | oakhaven_village.tscn | room | ["ch1_north_field_helped", "ch1_sluice_edited", "ch1_boar_fought"] | 60 | 0.9 | 0.9 | 0.9 | 0.0 | 2.7 |  |
| 10 | combat_arena.tscn | fight | ["ch1_boar_fight_won"] | 60 | 1.4 | 1.4 | 1.4 | 0.0 | 4.2 |  |
| 11 | oakhaven_village.tscn | room | ["ch1_boar_fight_won", "ch1_corrupted_boar_defeated", "ch1_bridge_saved"] | 60 | 2.0 | 2.0 | 2.0 | 0.0 | 6.0 |  |
| 12 | oakhaven_region.tscn | hop | ["ch1_oakhaven_entered", "ch1_corrupted_boar_defeated", "ch1_bridge_saved"] | 60 | 0.3 | 0.3 | 0.3 | 0.0 | 0.9 | TD-043 |
| 13 | tutorial_knight_boss.tscn | boss | ["ch1_knight_killed", "ch1_aldric_kill_owned", "ch1_tutorial_knight_defeated"] | 60 | 3.4 | 3.4 | 3.4 | 0.0 | 10.2 | TD-043 |
| 14 | shrine.tscn | room | ["source_key_fragment_1", "ch1_oakhaven_warned_villagers", "ch1_elara_joined"] | 60 | 3.1 | 3.1 | 3.1 | 0.0 | 9.3 |  |
| 15 | shatter_transition.tscn | shatter | ["ch1_shatter_witnessed", "ch1_complete"] | 60 | 8.3 | 8.4 | 8.3 | 0.1 | 25.2 |  |
| 16 | ironhold_gate.tscn | story | ["ch2_ironhold_entered", "ch2_seraphina_met"] | 60 | 4.1 | 4.1 | 4.1 | 0.0 | 12.3 |  |
| 17 | ironhold_region.tscn | ironhold | ["ch2_market_visited"] | 60 | 0.3 | 0.3 | 0.2 | 0.1 | 0.9 |  |
| 18 | seraphina_encounter.tscn | story | ["ch2_seraphina_truth", "ch2_command_hall_done"] | 60 | 1.2 | 1.2 | 1.2 | 0.0 | 3.6 |  |
| 19 | ironhold_region.tscn | ironhold | ["ch2_medicine_quest_active", "ch2_medicine_done", "ch2_medicine_early", "ch2_tower_bell_stopped"] | 60 | 1.0 | 1.0 | 1.0 | 0.0 | 3.0 | TD-043 |
| 20 | clock_tower.tscn | boss | ["ch2_clockwork_automaton_defeated", "ch2_clock_tower_complete", "ch2_shift_rescue_now", "ch2_underground_unlocked"] | 60 | 2.0 | 2.1 | 2.0 | 0.1 | 6.3 |  |
| 21 | ironhold_region.tscn | ironhold | ["ch2_underground_unlocked"] | 60 | 0.1 | 0.1 | 0.1 | 0.0 | 0.3 |  |
| 22 | underground_network.tscn | boss | ["ch2_data_wraith_defeated", "ch2_data_wraith_restored", "ch2_underground_complete"] | 60 | 2.1 | 2.1 | 2.1 | 0.0 | 6.3 |  |
| 23 | ironhold_region.tscn | ironhold | ["ch2_data_wraith_restored"] | 60 | 0.2 | 0.2 | 0.2 | 0.0 | 0.6 | TD-043 |
| 24 | administrator_boss.tscn | boss | ["ch2_administrator_proxy_defeated"] | 60 | 2.0 | 1.9 | 1.9 | 0.1 | 6.0 |  |
| 25 | seraphina_choice.tscn | story | ["source_key_fragment_2", "ch2_city_stable"] | 60 | 1.8 | 1.8 | 1.8 | 0.0 | 5.4 |  |
| 26 | ch2_ending.tscn | story | ["ch2_complete", "act1_report_local", "act1_pace_early"] | 60 | 6.1 | 6.2 | 6.2 | 0.1 | 18.6 | TD-043 |
| 27 | ironhold_departure.tscn | story | ["ch3_ironhold_departed"] | 60 | 1.4 | 1.3 | 1.3 | 0.1 | 4.2 |  |
| 28 | fractured_wastes_region.tscn | region | ["ch3_server_room_unlocked"] | 60 | 0.0 | 0.0 | 0.0 | 0.0 | 0.0 |  |
| 29 | fractured_wastes.tscn | story | ["ch3_fragment_3_collected", "source_key_fragment_3"] | 60 | 1.1 | 1.2 | 1.2 | 0.1 | 3.6 |  |
| 30 | data_stream.tscn | story | ["ch3_data_stream_complete"] | 60 | 12.2 | 12.2 | 12.2 | 0.0 | 36.6 |  |
| 31 | archive_depths.tscn | story | ["ch3_fragment_4_collected", "ch3_kaelthas_allied", "source_key_fragment_4"] | 60 | 2.5 | 2.5 | 2.6 | 0.1 | 7.8 |  |
| 32 | kaelthas_betrayal.tscn | story | [] | 60 | 2.0 | 2.0 | 2.0 | 0.0 | 6.0 |  |
| 33 | ch3_ending.tscn | input | ["ch3_complete", "ch4_unlocked"] | 60 | 1.9 | 1.9 | 1.9 | 0.0 | 5.7 |  |
| 34 | ch4_forgotten_sectors_intro.tscn | story | ["ch4_forgotten_sectors_entered"] | 60 | 0.3 | 0.3 | 0.3 | 0.0 | 0.9 |  |
| 35 | ch4_null_court.tscn | story | ["ch4_choice_preserve_deleted", "source_key_fragment_5"] | 60 | 1.0 | 1.0 | 1.0 | 0.0 | 3.0 |  |
| 36 | ch4_ending.tscn | story | ["ch4_complete"] | 60 | 0.3 | 0.4 | 0.4 | 0.1 | 1.2 |  |
| 37 | ch5_mirror_city_intro.tscn | story | ["ch5_mirror_city_entered"] | 60 | 0.3 | 0.3 | 0.3 | 0.0 | 0.9 |  |
| 38 | ch5_mirror_plaza.tscn | story | ["ch5_identity_refused_obedience"] | 60 | 0.6 | 0.6 | 0.6 | 0.0 | 1.8 |  |
| 39 | ch5_reflection_trial.tscn | story | ["ch5_echo_control_rejected"] | 60 | 0.4 | 0.4 | 0.4 | 0.0 | 1.2 |  |
| 40 | ch5_mirror_kaelen_confrontation.tscn | story | ["ch5_mirror_duel_cleared"] | 60 | 0.7 | 0.7 | 0.7 | 0.0 | 2.1 |  |
| 41 | ch5_ending.tscn | story | ["ch5_complete"] | 60 | 0.3 | 0.4 | 0.3 | 0.1 | 1.2 |  |
| 42 | ch6_cathedral_intro.tscn | story | ["ch6_cathedral_entered"] | 60 | 0.3 | 0.3 | 0.3 | 0.0 | 0.9 |  |
| 43 | ch6_cathedral_nave.tscn | story | ["ch6_mercy_trial_cleared", "ch6_efficiency_trial_cleared", "ch6_obedience_trial_cleared"] | 60 | 0.7 | 0.7 | 0.7 | 0.0 | 2.1 |  |
| 44 | ch6_choir_core.tscn | story | ["ch6_choir_silenced", "ch6_fragment_6_collected", "source_key_fragment_6"] | 60 | 0.9 | 0.8 | 0.9 | 0.1 | 2.7 |  |
| 45 | ch6_choir_combat_trial.tscn | trial | ["ch6_choir_combat_trial_cleared"] | 30 | 4.3 | 4.4 | 4.4 | 0.1 | 13.2 |  |
| 46 | ch6_ending.tscn | story | ["ch6_complete"] | 60 | 0.4 | 0.4 | 0.3 | 0.1 | 1.2 |  |
| 47 | ch7_deep_backup_intro.tscn | story | ["ch7_deep_backup_entered"] | 60 | 0.3 | 0.3 | 0.3 | 0.0 | 0.9 |  |
| 48 | ch7_memory_ocean_hub.tscn | story | ["ch7_memory_island_hazard_cleared"] | 60 | 0.4 | 0.4 | 0.4 | 0.0 | 1.2 |  |
| 49 | ch7_archive_tide.tscn | story | ["ch7_backups_preserved", "ch7_fragment_7_collected", "source_key_fragment_7"] | 60 | 0.8 | 0.9 | 0.9 | 0.1 | 2.7 |  |
| 50 | ch7_archive_tide_combat_trial.tscn | trial | ["ch7_archive_tide_surge_cleared"] | 30 | 4.7 | 4.7 | 4.6 | 0.1 | 14.1 |  |
| 51 | ch7_ending.tscn | story | ["ch7_complete"] | 60 | 0.4 | 0.4 | 0.4 | 0.0 | 1.2 |  |
| 52 | ch8_revolt_intro.tscn | story | ["ch8_revolt_intro_seen"] | 60 | 0.3 | 0.3 | 0.3 | 0.0 | 0.9 |  |
| 53 | ch8_saved_assembly.tscn | story | ["ch8_faction_requests_started"] | 60 | 0.7 | 0.7 | 0.7 | 0.0 | 2.1 |  |
| 54 | ch8_revolt_crisis.tscn | story | ["ch8_revolt_led"] | 60 | 0.6 | 0.6 | 0.6 | 0.0 | 1.8 |  |
| 55 | ch8_ending.tscn | story | ["ch8_complete"] | 60 | 0.4 | 0.4 | 0.4 | 0.0 | 1.2 |  |
| 56 | ch9_human_patch_intro.tscn | story | ["ch9_human_patch_entered"] | 60 | 0.3 | 0.3 | 0.3 | 0.0 | 0.9 |  |
| 57 | ch9_memory_lab.tscn | story | ["ch9_data_vision_scan_complete"] | 60 | 0.4 | 0.5 | 0.4 | 0.1 | 1.5 |  |
| 58 | ch9_creator_trial.tscn | story | ["ch9_truth_confessed"] | 60 | 0.4 | 0.4 | 0.4 | 0.0 | 1.2 |  |
| 59 | ch9_ending.tscn | story | ["ch9_complete"] | 60 | 0.4 | 0.4 | 0.3 | 0.1 | 1.2 |  |
| 60 | ch10_root_intro.tscn | story | ["ch10_root_entered"] | 60 | 0.3 | 0.3 | 0.3 | 0.0 | 0.9 |  |
| 61 | ch10_kernel_descent.tscn | story | ["ch10_kernel_trial_cleared"] | 60 | 0.7 | 0.7 | 0.7 | 0.0 | 2.1 |  |
| 62 | ch10_witness_chamber.tscn | story | ["ch10_witness_preparation_complete"] | 60 | 0.4 | 0.4 | 0.4 | 0.0 | 1.2 |  |
| 63 | ch10_sovereign_final_trial.tscn | trial | ["ch10_sovereign_final_trial_cleared"] | 30 | 5.8 | 5.8 | 5.8 | 0.0 | 17.4 |  |
| 64 | ch10_sovereign_confrontation.tscn | story | ["ch10_destroy_sovereign"] | 60 | 0.8 | 0.9 | 0.9 | 0.1 | 2.7 |  |
| 65 | ch10_ending.tscn | ending | ["ch10_complete", "true_ending_seen", "ng_plus_unlocked"] | 60 | 0.4 | 0.4 | 0.4 | 0.0 | 1.2 |  |

Leg 12 (`oakhaven_region`, kind hop) is checked at its hand-off like every leg; the menu and credits follow
leg 65 (T14a's checks).

## Whole suite per run

| Run | Bot run line (s real) | Runner wall clock incl. boot (s) | Result |
|---|---|---|---|
| Final 1 | 182.3 | not timed | 405 passed, 0 failed |
| Final 2 | 183.2 | not timed | 405 passed, 0 failed |
| Final 3 | 182.1 | not timed | 405 passed, 0 failed |
| 4 (earlier bot) | 171.5 | not timed | 405 passed, 0 failed |
| 5 (earlier bot) | 171.5 | 174 | 405 passed, 0 failed |
| 6 (earlier bot) | 171.6 | 174 | 405 passed, 0 failed |

## Player HP in the arena fights (INFO lines, start -> end of the alive window)

| Run | ch1_slime | ch1_guardian | ch1_boar |
|---|---|---|---|
| Final 1 | 100.0/100.0 -> 100.0/100.0 | 110.0/110.0 -> 96.4077669902913/110.0 | 96.0/110.0 -> 82.4077669902913/110.0 |
| Final 2 | 100.0/100.0 -> 100.0/100.0 | 110.0/110.0 -> 96.4077669902913/110.0 | 96.0/110.0 -> 82.4077669902913/110.0 |
| Final 3 | 100.0/100.0 -> 100.0/100.0 | 110.0/110.0 -> 96.4077669902913/110.0 | 96.0/110.0 -> 82.4077669902913/110.0 |

Before the fix (3 s REAL windows, `t14b_boar_diag_a_1..4.log`) the boar was entered at 15-25 of 110 HP and left at 1-11 after one charge; one run in about 20 died to the first charge (`t14b_mutation_e_flake_boar_death.log`).
Earlier measurement runs with the 3 s real window: `t14b_run1..3.log` (178.3-178.4 s, 405/0 each).

Slowest final whole run: 183.2 s (bot run line). `suite_limits.txt`: min checks 405, timeout 600 s, by the
file's own rule (3x 183.2 = 549.6 s, rounded up to a whole minute); the CI step's `timeout-minutes` is
12 (720 s), so the suite limit sits below it. Until the code-review gate of /story-done this was 360 s (2x), against
that rule, with the step left at 10 minutes; corrected 2026-11-07.
