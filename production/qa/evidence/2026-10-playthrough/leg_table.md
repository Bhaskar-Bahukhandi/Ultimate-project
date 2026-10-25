# Y1-P0-T14a leg table: Chapter 3 to the credits

The order and flags below are the suite's `LEGS` list (`AethelgardPrototype/tests/integration/playthrough/full_playthrough_test.gd`);
the suite asserts the order and the flags at each hand-off, so this table and the suite cannot disagree without a failure.
Route: option 0 at every choice (decision D4, the "liberation" ending). "Real s" and "choices" are from the green run
(`bot_run.log`, the run after the code-review fixes; Engine.time_scale 4 outside the trials, the trials at their own scale 1). 40 rows: 6 Chapter 3 scenes + the Wastes region + 32 Chapter 4–10
scenes + the main menu.

| # | Scene | Advances by | What the bot does | Flags checked at its hand-off | Next | Real s | Choices |
|---|---|---|---|---|---|---|---|
| 0 | chapter3/ironhold_departure | dialogue, flash | skip dialogue | ch3_ironhold_departed | regions/fractured_wastes_region | 1.3 | 0 |
| 1 | regions/fractured_wastes_region | player uses ServerRoomGate (placed when ch2_data_wraith_defeated) | `_interact_story(ServerRoomGate)` | ch3_server_room_unlocked | chapter3/fractured_wastes | 0.0 | 0 |
| 2 | chapter3/fractured_wastes | dialogue, flash | skip dialogue | ch3_fragment_3_collected, source_key_fragment_3 | chapter3/data_stream | 1.1 | 0 |
| 3 | chapter3/data_stream | lane-dodge minigame in `_process` (no fail state), dialogue | idle (the stream carries the player) | ch3_data_stream_complete | chapter3/archive_depths | 12.2 | 0 |
| 4 | chapter3/archive_depths | 6 choices, dialogue, flashes | option 0 (Kaelthas allied) | ch3_fragment_4_collected, ch3_kaelthas_allied, source_key_fragment_4 | chapter3/kaelthas_betrayal | 2.5 | 6 |
| 5 | chapter3/kaelthas_betrayal | allied path: choices | option 0 | (hand-off only) | chapter3/ch3_ending | 1.8 | 7 |
| 6 | chapter3/ch3_ending | 1 choice, then waits for ui_accept / jump (`_wait_for_input`) | option 0; a real `ui_accept` input event (it ended the wait; no fallback needed) | ch3_complete, ch4_unlocked | chapter4/ch4_forgotten_sectors_intro | 1.8 | 1 |
| 7 | chapter4/ch4_forgotten_sectors_intro | dialogue | skip | ch4_forgotten_sectors_entered | chapter4/ch4_null_court | 0.3 | 0 |
| 8 | chapter4/ch4_null_court | hazard, bailiff ×3, main choice (Source Key 5) | option 0 | ch4_choice_preserve_deleted, source_key_fragment_5 | chapter4/ch4_ending | 1.0 | 5 |
| 9 | chapter4/ch4_ending | dialogue | skip | ch4_complete | chapter5/ch5_mirror_city_intro | 0.4 | 0 |
| 10 | chapter5/ch5_mirror_city_intro | dialogue | skip | ch5_mirror_city_entered | chapter5/ch5_mirror_plaza | 0.3 | 0 |
| 11 | chapter5/ch5_mirror_plaza | calibration + identity choices | option 0 | ch5_identity_refused_obedience | chapter5/ch5_reflection_trial | 0.6 | 2 |
| 12 | chapter5/ch5_reflection_trial | 1 choice | option 0 | ch5_echo_control_rejected | chapter5/ch5_mirror_kaelen_confrontation | 0.4 | 1 |
| 13 | chapter5/ch5_mirror_kaelen_confrontation | duel = 3 choices | option 0 | ch5_mirror_duel_cleared | chapter5/ch5_ending | 0.7 | 3 |
| 14 | chapter5/ch5_ending | dialogue | skip | ch5_complete | chapter6/ch6_cathedral_intro | 0.4 | 0 |
| 15 | chapter6/ch6_cathedral_intro | dialogue | skip | ch6_cathedral_entered | chapter6/ch6_cathedral_nave | 0.3 | 0 |
| 16 | chapter6/ch6_cathedral_nave | 3 doctrine-trial choices | option 0 | ch6_mercy_trial_cleared, ch6_efficiency_trial_cleared, ch6_obedience_trial_cleared | chapter6/ch6_choir_core | 0.7 | 3 |
| 17 | chapter6/ch6_choir_core | firewall ×3 + main choice (Source Key 6) | option 0 | ch6_choir_silenced, ch6_fragment_6_collected, source_key_fragment_6 | chapter6/ch6_choir_combat_trial | 0.9 | 4 |
| 18 | chapter6/ch6_choir_combat_trial | real-time hazard trial | alive ≥ 3 s of attempt 1 at the trial's own time scale (1), then at a moment with no hazard in flight `_retry_requested` + `_complete_trial()` | ch6_choir_combat_trial_cleared | chapter6/ch6_ending | 4.3 | 0 |
| 19 | chapter6/ch6_ending | dialogue | skip | ch6_complete | chapter7/ch7_deep_backup_intro | 0.4 | 0 |
| 20 | chapter7/ch7_deep_backup_intro | dialogue | skip | ch7_deep_backup_entered | chapter7/ch7_memory_ocean_hub | 0.3 | 0 |
| 21 | chapter7/ch7_memory_ocean_hub | 1 hazard choice | option 0 | ch7_memory_island_hazard_cleared | chapter7/ch7_archive_tide | 0.4 | 1 |
| 22 | chapter7/ch7_archive_tide | waves ×3 + main choice (Source Key 7) | option 0 | ch7_backups_preserved, ch7_fragment_7_collected, source_key_fragment_7 | chapter7/ch7_archive_tide_combat_trial | 0.9 | 4 |
| 23 | chapter7/ch7_archive_tide_combat_trial | real-time hazard trial | alive ≥ 3 s of attempt 1 at the trial's own time scale (1), then at a moment with no hazard in flight `_retry_requested` + `_complete_trial()` | ch7_archive_tide_surge_cleared | chapter7/ch7_ending | 4.7 | 0 |
| 24 | chapter7/ch7_ending | dialogue | skip | ch7_complete | chapter8/ch8_revolt_intro | 0.4 | 0 |
| 25 | chapter8/ch8_revolt_intro | dialogue | skip | ch8_revolt_intro_seen | chapter8/ch8_saved_assembly | 0.3 | 0 |
| 26 | chapter8/ch8_saved_assembly | 3 faction-request choices | option 0 | ch8_faction_requests_started | chapter8/ch8_revolt_crisis | 0.7 | 3 |
| 27 | chapter8/ch8_revolt_crisis | stabilize + main choice | option 0 | ch8_revolt_led | chapter8/ch8_ending | 0.6 | 2 |
| 28 | chapter8/ch8_ending | dialogue | skip | ch8_complete | chapter9/ch9_human_patch_intro | 0.4 | 0 |
| 29 | chapter9/ch9_human_patch_intro | dialogue | skip | ch9_human_patch_entered | chapter9/ch9_memory_lab | 0.3 | 0 |
| 30 | chapter9/ch9_memory_lab | 1 choice | option 0 | ch9_data_vision_scan_complete | chapter9/ch9_creator_trial | 0.4 | 1 |
| 31 | chapter9/ch9_creator_trial | 1 choice | option 0 | ch9_truth_confessed | chapter9/ch9_ending | 0.4 | 1 |
| 32 | chapter9/ch9_ending | dialogue | skip | ch9_complete | chapter10/ch10_root_intro | 0.4 | 0 |
| 33 | chapter10/ch10_root_intro | dialogue | skip | ch10_root_entered | chapter10/ch10_kernel_descent | 0.3 | 0 |
| 34 | chapter10/ch10_kernel_descent | 3 lock choices | option 0 | ch10_kernel_trial_cleared | chapter10/ch10_witness_chamber | 0.7 | 3 |
| 35 | chapter10/ch10_witness_chamber | 4-option preparation choice | option 0 | ch10_witness_preparation_complete | chapter10/ch10_sovereign_final_trial | 0.4 | 1 |
| 36 | chapter10/ch10_sovereign_final_trial | real-time hazard trial | alive ≥ 3 s of attempt 1 at the trial's own time scale (1), then at a moment with no hazard in flight `_retry_requested` + `_complete_trial()` | ch10_sovereign_final_trial_cleared | chapter10/ch10_sovereign_confrontation | 5.8 | 0 |
| 37 | chapter10/ch10_sovereign_confrontation | final challenge ×3 + final choice | option 0 | ch10_destroy_sovereign | chapter10/ch10_ending | 0.8 | 4 |
| 38 | chapter10/ch10_ending | sets ch10_complete / true_ending_seen / ng_plus_unlocked / ng_plus_available in `_ready`; static "TRUE ENDING … Credits" text; dialogue | skip; AC-5 checks on arrival | ch10_complete, true_ending_seen, ng_plus_unlocked | main_menu | 0.4 | 0 |
| 39 | main_menu | — | checks the NEW GAME+ button; opens `CreditsScreen.show_credits(false)` and closes it with ui_cancel | — | — | — | — |

Totals: 52 choices answered with option 0 (each logged with its prompt and the option's text); Source Keys 3–7
collected (`source_key_count` 2 → 7, each `source_key_fragment_N` checked at its own leg); the run takes about 65 s of
real time locally.
