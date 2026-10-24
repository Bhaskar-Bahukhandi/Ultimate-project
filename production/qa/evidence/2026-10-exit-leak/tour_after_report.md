# Screenshot tour — 2026-10-24 12:05:00

Godot 4.6.3-stable (official), renderer `forward_plus`, NVIDIA GeForce RTX 2050. Window (1280.0, 720.0).

Game state is reset before each scene, so scenes show their default (fresh-save) state.

**No layout problems found.**

Contact sheets: `contact_scenes.png`, `contact_dialogue.png`.

| Shot | Scene / source | Notes |
|---|---|---|
| `main_menu.png` | main_menu.tscn |  |
| `ch1_crash_site.png` | opening_crash_site_hook.tscn |  |
| `ch1_elara_meeting.png` | elara_meeting.tscn |  |
| `ch1_broken_mile.png` | path_to_oakhaven.tscn |  |
| `ch1_oakhaven_village.png` | oakhaven_village.tscn |  |
| `ch1_oakhaven_region.png` | oakhaven_region.tscn |  |
| `ch1_aldric.png` | tutorial_knight_boss.tscn |  |
| `ch1_shatter.png` | shatter_transition.tscn |  |
| `ch2_ironhold_gate.png` | ironhold_gate.tscn |  |
| `ch2_ironhold_region.png` | ironhold_region.tscn |  |
| `ch2_command_hall.png` | seraphina_encounter.tscn |  |
| `ch2_arena.png` | arena_district.tscn |  |
| `ch2_clock_tower.png` | clock_tower.tscn |  |
| `ch2_underground.png` | underground_network.tscn |  |
| `ch2_proxy.png` | administrator_boss.tscn |  |
| `ch2_fragment_two.png` | seraphina_choice.tscn |  |
| `ch2_act1_end.png` | ch2_ending.tscn |  |
| `ch1_shatter_kill.png` | shatter_transition.tscn | real scene run; first line of shatter.dlg `after_kill` |
| `ch1_shatter_spare.png` | shatter_transition.tscn | real scene run; first line of shatter.dlg `after_spare` |
| `ch1_shatter_purge.png` | shatter_transition.tscn | real scene run; first line of shatter.dlg `after_purge` |
| `ch1_breadcrumb_oakhaven.png` | oakhaven_village.tscn | real scene run; Chapter 1 step-6 breadcrumb; 5 choice(s) answered with option 1; objective `Spend the afternoon in Oakhaven. Meet the people here.`; ch1_stew_done set by the real stew: true; ch1_oakhaven_entered: true; arrow target cached: false; arrow text EMPTY |
| `ui_pause.png` | oakhaven_region.tscn |  |
| `ui_controls.png` | oakhaven_region.tscn |  |
| `t06_shop_discount.png` | oakhaven_region.tscn | discount 0.05 from Forge Line Supply (quest state COMPLETED); health_potion raw 30G, get_buy_price 29G, button `BUY 29G` |
| `ch3_archive_flash_before.png` | archive_depths.tscn | baseline: same scene, no flash yet |
| `ch3_archive_flash.png` | archive_depths.tscn | SceneTransitions.flash((0.2, 0.6, 1.0, 0.4), 0.8) called by the stop (scene call is inside the Source Key coroutine; routing proven by screen_flash_test F1); overlay colour (0.2, 0.6, 1.0, 0.4), modulate.a 0.800 just before the capture; mean RGB before (0.040, 0.054, 0.107) -> flash frame (0.084, 0.204, 0.352); shift toward the flash colour 0.291 (min 0.010) |
| `ch1_oakhaven_flash_before.png` | oakhaven_village.tscn | baseline: same scene, no flash yet |
| `ch1_oakhaven_flash.png` | oakhaven_village.tscn | real scene _on_dlg_event("fracture_spreads"); overlay colour (0.55, 0.0, 0.7, 0.35), modulate.a 0.800 just before the capture; mean RGB before (0.250, 0.382, 0.262) -> flash frame (0.301, 0.318, 0.336); shift toward the flash colour 0.110 (min 0.010) |
| `dlg_prologue_before_the_ground_line.png` | before_the_ground.dlg | before_the_ground.dlg:16, 70 chars |
| `dlg_ch1_aldric_line.png` | aldric.dlg | aldric.dlg:90, 66 chars |
| `dlg_ch1_aldric_choice.png` | aldric.dlg | aldric.dlg:55, 3 options |
| `dlg_ch1_broken_mile_line.png` | broken_mile.dlg | broken_mile.dlg:128, 177 chars |
| `dlg_ch1_broken_mile_choice.png` | broken_mile.dlg | broken_mile.dlg:40, 2 options |
| `dlg_ch1_crash_site_line.png` | crash_site.dlg | crash_site.dlg:33, 85 chars |
| `dlg_ch1_elara_house_line.png` | elara_house.dlg | elara_house.dlg:35, 96 chars |
| `dlg_ch1_elara_house_choice.png` | elara_house.dlg | elara_house.dlg:16, 5 options |
| `dlg_ch1_elara_meeting_line.png` | elara_meeting.dlg | elara_meeting.dlg:81, 100 chars |
| `dlg_ch1_elara_meeting_choice.png` | elara_meeting.dlg | elara_meeting.dlg:41, 3 options |
| `dlg_ch1_fragment_one_line.png` | fragment_one.dlg | fragment_one.dlg:38, 141 chars |
| `dlg_ch1_fragment_one_choice.png` | fragment_one.dlg | fragment_one.dlg:32, 3 options |
| `dlg_ch1_north_field_line.png` | north_field.dlg | north_field.dlg:25, 143 chars |
| `dlg_ch1_north_field_choice.png` | north_field.dlg | north_field.dlg:45, 3 options |
| `dlg_ch1_oakhaven_gate_line.png` | oakhaven_gate.dlg | oakhaven_gate.dlg:28, 151 chars |
| `dlg_ch1_oakhaven_village_line.png` | oakhaven_village.dlg | oakhaven_village.dlg:95, 126 chars |
| `dlg_ch1_shatter_line.png` | shatter.dlg | shatter.dlg:39, 115 chars |
| `dlg_ch2_act1_end_line.png` | act1_end.dlg | act1_end.dlg:28, 135 chars |
| `dlg_ch2_act1_end_choice.png` | act1_end.dlg | act1_end.dlg:10, 3 options |
| `dlg_ch2_administrator_proxy_line.png` | administrator_proxy.dlg | administrator_proxy.dlg:19, 110 chars |
| `dlg_ch2_arena_line.png` | arena.dlg | arena.dlg:34, 95 chars |
| `dlg_ch2_clock_tower_line.png` | clock_tower.dlg | clock_tower.dlg:31, 88 chars |
| `dlg_ch2_clock_tower_choice.png` | clock_tower.dlg | clock_tower.dlg:64, 3 options |
| `dlg_ch2_command_hall_line.png` | command_hall.dlg | command_hall.dlg:23, 152 chars |
| `dlg_ch2_command_hall_choice.png` | command_hall.dlg | command_hall.dlg:16, 3 options |
| `dlg_ch2_fragment_two_line.png` | fragment_two.dlg | fragment_two.dlg:82, 70 chars |
| `dlg_ch2_ironhold_arrival_line.png` | ironhold_arrival.dlg | ironhold_arrival.dlg:27, 173 chars |
| `dlg_ch2_ironhold_city_line.png` | ironhold_city.dlg | ironhold_city.dlg:34, 160 chars |
| `dlg_ch2_ironhold_city_choice.png` | ironhold_city.dlg | ironhold_city.dlg:240, 2 options |
| `dlg_ch2_underground_line.png` | underground.dlg | underground.dlg:38, 129 chars |
| `dlg_ch2_underground_choice.png` | underground.dlg | underground.dlg:63, 3 options |
