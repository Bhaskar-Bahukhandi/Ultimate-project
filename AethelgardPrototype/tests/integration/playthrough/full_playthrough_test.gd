extends SceneTree
## Tests for story Y1-P0-T14b (production/epics/y1-p0-stabilize/story-t14b-playthrough-ch1-fights.md, AC-1..AC-7),
## built on T14a's bot (story-t14a-playthrough-ch3-to-credits.md): a bot that plays the game headless from New Game.
## It starts with GameManager.reset_game() and DialogueManager.force_reset(), then loads the first story scene (the
## crash-site hook), as a New Game does and as chapter1_route_test.gd _test_new_game_to_region starts it: no seeded
## flag, key, stat or relationship. It plays Chapter 1 through its three arena fights (the slime, the Broken Mile
## guardian, the north-field boar) to the Oakhaven region, the region's boss gate to the Tutorial Knight, the shrine,
## the shatter played through, Chapter 2 on chapter2_route_test.gd's careful route (Ironhold's region legs, the Clock
## Tower, the Underground, the Administrator Proxy, Seraphina's choice, the Act 1 end) and then T14a's Chapter 3-10
## legs, the ending, the main menu with NEW GAME+ and the credits, in one run.
##
## LEGS is the leg table: [scene, kind, flags set by the time the scene hands off, real-time cap in s, options]. One
## list drives the order check, the per-leg flag check, the caps and the log. Kinds: "room" (scenes that wait on the
## player: the bot pokes the scene's own interaction handlers), "story" (dialogue only; an end card waiting for a key
## gets a real ui_accept), "fight" (a combat_arena story fight; options name the STORY_FIGHTS row; its flags are the
## row's win flags), "hop" (oakhaven_region -> the knight through the region's interact key), "boss" (the knight and
## the Chapter 2 bosses: alive window, then the scene's own defeat callback), "shatter" (played through, no skip
## input), "ironhold" (an Ironhold region visit: the steps in its options, through the region's own handlers), then
## T14a's "region" (walk to the Wastes' ServerRoomGate and use it), "input" (ch3_ending waits for a key press),
## "trial" (a late-game hazard trial) and "ending" (ch10_ending), then the main menu.
##
## DRIVER (kept from T14a). Every frame: an open choice -> option 0 once its buttons are focusable (DialogueManager
## enables them after its 0.5 s grace period, so the bot answers no sooner than a player could; logged with the prompt
## and the option's text), else active dialogue -> DialogueManager.skip_all() (show_choices clears the skip, so it is
## re-armed every frame it is needed). Outside trials Engine.time_scale is set to 4 every frame (inside an arena too:
## that overrides its hitstop, harmless for a bot that does not play the fight); a trial scene is left alone, because
## the trial resets the scale to 1 with ContextStack.clear_time_scale() at every attempt. A leg ends at the scene's
## own hand-off (SceneTransitions.transition_started); the next leg is armed as soon as the scene swaps, so a scene
## that hands off at once is still seen. At transition_started the suite samples: no dialogue active and no
## ContextStack entry open (the plan's R5 check), the leg's flags, and for a fight the retries and the player. The next
## scene must be the one the table names. Every leg has its own real-time cap (Time.get_ticks_msec, LEGS column 4). A
## cap or a wrong next scene stops the bot (no later legs run on a broken state) and prints a softlock report: leg,
## scene, cap, elapsed real seconds, the last speaker and line, the open choice prompt, the last choice answered. A
## single exit function (_finish) restores Engine.time_scale = 1 and ContextStack.clear_time_scale() on every pass and
## fail path, asserts the scale and prints it.
##
## KNOWN R5 DIALOGUE (user decision 2026-11-07, TD-043). Five scenes start their scene change with the dialogue box
## still up (no hide_dialogue() before change_scene). KNOWN_R5_DIALOGUE names those legs by index and scene path. At
## every hand-off the ContextStack half of R5 is checked on every leg; "no dialogue active" is checked on every leg not
## in the list; on a listed leg an active dialogue is an INFO line naming TD-043, and NO active dialogue FAILS (TD-043
## may be fixed: remove the entry). The list only ever shrinks.
##
## FIGHTS (T14b D3, AC-2). Once the arena holds its story enemy, the bot checks the scene and story_fight_id and that
## the row's win flags are still false, then runs the alive window: it ends once BOTH hold, 3 s of game time
## (FIGHT_ALIVE_S, added up frame by frame in _tick_game_time: physics frames stepped / ticks per second x the time
## scale they ran at, frames stepped while paused excluded) and the enemy out of IDLE at least once, bounded
## by a wall cap. Through it the player stays alive with no retry and the enemy's current_state is never DEAD; a death
## in the window fails the run with the softlock report. Each fight prints the player's HP at the window's start and
## end (INFO). History: a 3 s REAL window (12 s of game time) drained HP across the Chapter 1 fights (HP carries over,
## nothing heals between them) until a boar charge killed the player in about 1 run in 20 (README, flake section).
## While the enemy is still IDLE the bot holds move_right with real input events (a player walking toward it;
## the slime only notices the player within 250 px) and releases it once the enemy has left IDLE.
## Then it finishes the enemy through its own API (_enter_dizzy() when it has one, then
## take_damage(max_health), as chapter1_route_test.gd does) and checks: win flags set, story_fight_retries 0, the
## player not dead, one hand-off to the return scene.
## BOSSES (T14b D3, AC-3, AC-4). The knight once its combat_started is true, the Chapter 2 bosses once their scene has
## settled (no dialogue for SETTLE_FRAMES frames; the Proxy once its boss_node exists; the Underground once its wraith
## dialogue, started with _on_wraith_approach as the route test does, is over): the same FIGHT_ALIVE_S of game time
## (no IDLE condition: a boss scene's state is not an EnemyBase state), player alive and the knight's
## combat_started still true, then the scene's own callback (_on_boss_defeated,
## _on_automaton_defeated, _on_data_wraith_defeated). The leg checks the scene's own defeated state
## (BOSS_DEFEATED_VARS) was false just before the callback and is true at the hand-off.
## KNIGHT HOP (AC-3). The leg clears GameManager's boss_return_scene meta, waits for the region to be idle, puts the
## player on the TutorialKnightGate (again only while the region's _overlapping does not list the gate, at most
## HOP_PLACE_MAX times) and, once it is listed, sends a real "interact" input event, which the region's own
## _unhandled_input turns into _enter_boss_arena(). Its level warning (level under 3) is answered with option 0,
## "Enter the Arena".
## SHATTER (AC-3). No skip input is sent: the leg checks the scene's chapter_end_card was seen visible, the "Chapter 1
## Complete. Press ... to continue" line was shown (the skip path, _on_skip_cutscene, shows neither) and the scene's
## _skip_completed is false at the hand-off.
## GUARDIAN (T14b D2). The Root Access panel in path_to_oakhaven gets no input at all; its give-up (1800 pausable
## 0.1 s ticks) picks the fight. Checked on the game's state at the hand-off: _root_choice "fight", the target filter
## on ALL (index 0), aggression 1.0, GameManager.glitch_meter unchanged since the panel opened.
##
## HAZARD TRIALS (T14a decision D2). The trial scene is loaded for real; the bot waits until one attempt has run for 3 s
## of scaled time (at the trial's own scale) with the player alive (attempt number unchanged, no retry requested, not
## dead; a death restarts the count), then - only at a moment when no hazard is in flight (_active_markers empty) -
## sets the scene's _retry_requested and calls its own _complete_trial() (rewards, flag, auto-save, hand-off).
## Completing during a hazard's active window makes _run_hazard write to a freed marker (findings.md F-2).
##
## ISOLATION COSTS (named, accepted):
##   - The driver reads and calls PRIVATE DialogueManager members: _awaiting_choice, _choice_result, _choice_container,
##     _text_label, _speaker_label and _on_choice_pressed(0). There is no public "answer the open choice" API (TD-016).
##   - T14b, the crash-site hook: the bot reads its private _dialogue_busy and _player, calls
##     _on_signalfragment_interaction(_player) and then _complete_opening_hook() (the route test's start, :250-257)
##     instead of walking to the fused metal and the road east and pressing interact.
##   - T14b, the village and Elara's house: the bot calls the scenes' own interaction handlers with the scene's Player
##     (_on_elara_house_door_interaction, _on_bridge_trigger, _on_door_interaction; copied from the route test's
##     _poke_room) instead of walking there, gated on private members (_invited, _entrance_done, in_dialogue, _busy()).
##   - T14b, the three arena fights (D3): the bot reads the arena's private _story_enemy and _story_id, its player and
##     story_fight_retries, and finishes the enemy with _enter_dizzy() (when present) and take_damage(max_health).
##     The fight itself is not played; T15's human pass plays it.
##   - T14b, the guardian give-up: the bot only reads path_to_oakhaven's private _root_choice, _target_filter,
##     root_access_tutorial_active and aggression_spinbox; it never writes them or presses the panel.
##   - T14b, the knight hop: the player is placed on the TutorialKnightGate (global_position) instead of walking
##     there; the interact key itself is a real input event through the region's own handler.
##   - T14b, the knight and the Chapter 2 bosses (D3): the fights are not played; the bot reads each scene's player
##     (player / player_node, is_dead), combat_started, boss_node, _wraith_approached, and calls _on_boss_defeated(),
##     _on_automaton_defeated(), _on_wraith_approach(player_node) and _on_data_wraith_defeated().
##   - T14b, the shrine: _on_altar_interaction / _on_stair_door_interaction with the scene's Player, gated on _busy()
##     (the route test's _poke_room), instead of walking to the altar and the stair door.
##   - T14b, Chapter 2's region: the bot calls ironhold_region.gd's _interact_npc (Rook, Rem), _interact_story (the
##     story gates) and _interact_boss (AdminBossGate) directly, as chapter2_route_test.gd does, gated on its private
##     _city_busy; and sets ch2_arena_bronze_complete by flag, then calls _place_story_gates() (the arena bracket is
##     not under test, chapter2_route_test.gd :168-169).
##   - T14b, the shatter: reads its chapter_end_card and private _skip_completed.
##   - The trial legs read private scene members (_attempts, _retry_requested, _active_markers, player), set
##     _retry_requested and call _complete_trial().
##   - The Wastes region leg calls the region's _interact_story(ServerRoomGate) instead of walking the player onto the
##     gate and pressing interact (what a player does; reachability_test.gd proves the gate is touchable).
##   - ch3_ending's key wait is ended by a real ui_accept input event; if that ever stops working the bot sets the
##     scene's _waiting_for_input = false to finish the run, and that leg's check fails.
##   - The beats really run: they auto-save to slot 99, set story flags and collect Source Keys, inside the runner's
##     isolated aeth_phase0_test user:// (the suite refuses to run outside it).
##   - Each Godot boot logs 6 "Can't use get_node() with absolute paths" ERROR lines before any test code
##     (pre-existing).
##
## START STATE (T14b AC-1, D1). reset_game() + force_reset(), then the hook. T14a's SEED_* (a Chapter 3 seed) is gone;
## at the Chapter 3 hand-off the bot prints the real state (flags, keys, level, gold, XP, relationships) as INFO.
## Run: tests/run_phase0_tests.ps1 -Script res://tests/integration/playthrough/full_playthrough_test.gd

const HOOK := "res://scenes/chapter1/opening_crash_site_hook.tscn"
const ELARA := "res://scenes/chapter1/elara_meeting.tscn"
const ARENA := "res://scenes/combat/combat_arena.tscn"
const PATH := "res://scenes/chapter1/path_to_oakhaven.tscn"
const VILLAGE := "res://scenes/chapter1/oakhaven_village.tscn"
const HOUSE := "res://scenes/chapter1/elara_house.tscn"
const REGION := "res://scenes/regions/oakhaven_region.tscn"
const KNIGHT := "res://scenes/chapter1/tutorial_knight_boss.tscn"
const SHRINE := "res://scenes/chapter1/shrine.tscn"
const SHATTER := "res://scenes/chapter1/shatter_transition.tscn"
const IH_GATE := "res://scenes/chapter2/ironhold_gate.tscn"
const IH_REGION := "res://scenes/regions/ironhold_region.tscn"
const IH_HALL := "res://scenes/chapter2/seraphina_encounter.tscn"
const IH_TOWER := "res://scenes/chapter2/clock_tower.tscn"
const IH_UNDER := "res://scenes/chapter2/underground_network.tscn"
const IH_PROXY := "res://scenes/chapter2/administrator_boss.tscn"
const IH_CHOICE := "res://scenes/chapter2/seraphina_choice.tscn"
const IH_ENDING := "res://scenes/chapter2/ch2_ending.tscn"
const MENU := "res://scenes/main_menu.tscn"
const SWITCH_CAP_S := 30.0
const TIME_SCALE := 4.0
const TRIAL_ALIVE_S := 3.0
const KEYS_AT_END := 7
## T14a's caps for its Chapter 3-10 legs (real seconds).
const CAP_STORY := 60.0
const CAP_TRIAL := 30.0
## T14b caps (real seconds, AC-6): each at least 3x its leg's slowest measured run and at least 60 s
## (production/qa/evidence/2026-11-playthrough/leg_table.md). Every Chapter 1 and 2 leg ran in 8.5 s or less.
const CAP_CH1 := 60.0
const CAP_FIGHT := 60.0
## The guardian leg holds the Root Access give-up (180 s of pausable game time): 52.4-60.0 s real over nine
## runs (slowest 60.0 s, t14b_hopfix_run2), x3 = 180.
const CAP_GUARDIAN := 180.0
## The alive window of every arena fight and boss, in GAME seconds (_tick_game_time: physics frames / ticks per
## second x the time scale they ran at, paused frames excluded; story AC-2 and AC-3), and the real-time cap on it.
const FIGHT_ALIVE_S := 3.0
const FIGHT_ALIVE_WALL_S := 30.0
## The minimum time between two room pokes (real ms), as the route test's _wait_for.
const POKE_INTERVAL_MS := 1000
## Frames with no dialogue (and, in Ironhold, the region not busy) before the bot acts on a settled scene.
const SETTLE_FRAMES := 10
## T14b cap (real seconds, AC-6) for the Chapter 2 legs: every one ran in 5.7 s or less.
const CAP_CH2 := 60.0
## The most times the knight hop places the player on the TutorialKnightGate before it fails the leg.
const HOP_PLACE_MAX := 3
## The level under which oakhaven_region.gd _enter_boss_arena warns (:1080).
const KNIGHT_WARN_LEVEL := 3
## The option-0 texts of the level warnings (oakhaven_region.gd :1084, ironhold_region.gd :1157), logged with the level.
const WARNING_OPTIONS := ["Enter the Arena", "Enter (Suicidal)"]
## The start of the shatter's last line, shown only when it is played through (ch1_shatter_transition.gd :373).
const SHATTER_END_LINE := "Chapter 1 Complete. Press"
## The legs whose scene hands off with the dialogue box still up (TD-043): {leg index: scene path}. Only shrinks.
const KNOWN_R5_DIALOGUE := {12: REGION, 13: KNIGHT, 19: IH_REGION, 23: IH_REGION, 26: IH_ENDING}
## Each boss scene's own "defeated" member, set by its defeat callback (ch1_tutorial_knight.gd :1106, ch2_clock_tower.gd
## :474, ch2_underground_network.gd :391, ch2_administrator_boss.gd :387).
const BOSS_DEFEATED_VARS := {"knight": "combat_ended", "tower": "automaton_defeated",
	"wraith": "data_wraith_defeated", "proxy": "_boss_defeated"}
## Each boss leg's defeat callback on its own scene (D3).
const BOSS_CALLBACKS := {"knight": "_on_boss_defeated", "tower": "_on_automaton_defeated",
	"wraith": "_on_data_wraith_defeated", "proxy": "_on_boss_defeated"}

## [scene, kind, flags set by the time the scene hands off, cap s, options]. Chapter 1 flags are what
## chapter1_route_test.gd _test_new_game_to_region asserts, placed at the leg whose script or .dlg node sets them
## (option 0 at every choice). A fight leg's flags are its STORY_FIGHTS row's win flags (combat_arena.gd :123, :155,
## :185). Each Source Key leg also checks its source_key_fragment_N flag at its own hand-off: from Chapter 8 on,
## GameManager.normalize_source_key_progression() rebuilds the count from the chapters' fragment flags, so a missing
## collect_source_key() call would be hidden by the end-of-run count (T14a code review, mutation g).
const LEGS: Array = [
	[HOOK, "room", ["ch1_opening_hook_signal_found", "ch1_opening_hook_complete", "plane_crash_completed"], CAP_CH1],
	[ELARA, "story", [], CAP_CH1],
	[ARENA, "fight", ["first_slime_defeated", "ch1_slime_fought"], CAP_FIGHT, {"fight": "ch1_slime"}],
	[ELARA, "story", ["elara_first_truth", "ch1_elara_trusted", "elara_met", "ch1_elara_glitch_witch_met"], CAP_CH1],
	[PATH, "story", ["ch1_broken_mile_entered", "ch1_ironhold_lead", "elara_arm_noticed", "ch1_data_vision_unlocked",
		"root_access_unlocked"], CAP_GUARDIAN, {"root_giveup": true}],
	[ARENA, "fight", ["ch1_guardian_fought"], CAP_FIGHT, {"fight": "ch1_guardian"}],
	[PATH, "story", ["ch1_guardian_fought", "ch1_root_discovered_unused", "ch1_personal_goal_set"], CAP_CH1],
	[VILLAGE, "room", ["ch1_oakhaven_entered", "ch1_northfall_registry_seen"], CAP_CH1],
	[HOUSE, "room", ["ch1_stew_done", "ch1_stew_asked_where", "ch1_elara_arm_talked"], CAP_CH1],
	[VILLAGE, "room", ["ch1_north_field_helped", "ch1_sluice_edited", "ch1_boar_fought"], CAP_CH1],
	[ARENA, "fight", ["ch1_boar_fight_won"], CAP_FIGHT, {"fight": "ch1_boar"}],
	[VILLAGE, "room", ["ch1_boar_fight_won", "ch1_corrupted_boar_defeated", "ch1_bridge_saved"], CAP_CH1],
	[REGION, "hop", ["ch1_oakhaven_entered", "ch1_corrupted_boar_defeated", "ch1_bridge_saved"], CAP_CH1],
	[KNIGHT, "boss", ["ch1_knight_killed", "ch1_aldric_kill_owned", "ch1_tutorial_knight_defeated"], CAP_CH1,
		{"boss": "knight"}],
	[SHRINE, "room", ["source_key_fragment_1", "ch1_oakhaven_warned_villagers", "ch1_elara_joined"], CAP_CH1],
	[SHATTER, "shatter", ["ch1_shatter_witnessed", "ch1_complete"], CAP_CH1],
	# Chapter 2: chapter2_route_test.gd _test_careful_route :141-210, every choice option 0.
	[IH_GATE, "story", ["ch2_ironhold_entered", "ch2_seraphina_met"], CAP_CH2],
	[IH_REGION, "ironhold", ["ch2_market_visited"], CAP_CH2, {"steps": ["talk:Rook", "gate:CommandHallGate"]}],
	[IH_HALL, "story", ["ch2_seraphina_truth", "ch2_command_hall_done"], CAP_CH2],
	[IH_REGION, "ironhold", ["ch2_medicine_quest_active", "ch2_medicine_done", "ch2_medicine_early",
		"ch2_tower_bell_stopped"], CAP_CH2,
		{"steps": ["talk:Rem", "gate:WestRoadGate", "bronze", "gate:ClockTowerGate"]}],
	[IH_TOWER, "boss", ["ch2_clockwork_automaton_defeated", "ch2_clock_tower_complete", "ch2_shift_rescue_now",
		"ch2_underground_unlocked"], CAP_CH2, {"boss": "tower"}],
	[IH_REGION, "ironhold", ["ch2_underground_unlocked"], CAP_CH2, {"steps": ["gate:UndergroundGate"]}],
	[IH_UNDER, "boss", ["ch2_data_wraith_defeated", "ch2_data_wraith_restored", "ch2_underground_complete"], CAP_CH2,
		{"boss": "wraith"}],
	[IH_REGION, "ironhold", ["ch2_data_wraith_restored"], CAP_CH2, {"steps": ["gate:AdminBossGate"]}],
	[IH_PROXY, "boss", ["ch2_administrator_proxy_defeated"], CAP_CH2, {"boss": "proxy"}],
	[IH_CHOICE, "story", ["source_key_fragment_2", "ch2_city_stable"], CAP_CH2],
	[IH_ENDING, "story", ["ch2_complete", "act1_report_local", "act1_pace_early"], CAP_CH2, {"ch3_state": true}],
	# T14a's Chapter 3-10 legs, unchanged.
	["res://scenes/chapter3/ironhold_departure.tscn", "story", ["ch3_ironhold_departed"], CAP_STORY],
	["res://scenes/regions/fractured_wastes_region.tscn", "region", ["ch3_server_room_unlocked"], CAP_STORY],
	["res://scenes/chapter3/fractured_wastes.tscn", "story", ["ch3_fragment_3_collected", "source_key_fragment_3"],
		CAP_STORY],
	["res://scenes/chapter3/data_stream.tscn", "story", ["ch3_data_stream_complete"], CAP_STORY],
	["res://scenes/chapter3/archive_depths.tscn", "story", ["ch3_fragment_4_collected", "ch3_kaelthas_allied",
		"source_key_fragment_4"], CAP_STORY],
	["res://scenes/chapter3/kaelthas_betrayal.tscn", "story", [], CAP_STORY],
	["res://scenes/chapter3/ch3_ending.tscn", "input", ["ch3_complete", "ch4_unlocked"], CAP_STORY],
	["res://scenes/chapter4/ch4_forgotten_sectors_intro.tscn", "story", ["ch4_forgotten_sectors_entered"], CAP_STORY],
	["res://scenes/chapter4/ch4_null_court.tscn", "story", ["ch4_choice_preserve_deleted", "source_key_fragment_5"],
		CAP_STORY],
	["res://scenes/chapter4/ch4_ending.tscn", "story", ["ch4_complete"], CAP_STORY],
	["res://scenes/chapter5/ch5_mirror_city_intro.tscn", "story", ["ch5_mirror_city_entered"], CAP_STORY],
	["res://scenes/chapter5/ch5_mirror_plaza.tscn", "story", ["ch5_identity_refused_obedience"], CAP_STORY],
	["res://scenes/chapter5/ch5_reflection_trial.tscn", "story", ["ch5_echo_control_rejected"], CAP_STORY],
	["res://scenes/chapter5/ch5_mirror_kaelen_confrontation.tscn", "story", ["ch5_mirror_duel_cleared"], CAP_STORY],
	["res://scenes/chapter5/ch5_ending.tscn", "story", ["ch5_complete"], CAP_STORY],
	["res://scenes/chapter6/ch6_cathedral_intro.tscn", "story", ["ch6_cathedral_entered"], CAP_STORY],
	["res://scenes/chapter6/ch6_cathedral_nave.tscn", "story", ["ch6_mercy_trial_cleared",
		"ch6_efficiency_trial_cleared", "ch6_obedience_trial_cleared"], CAP_STORY],
	["res://scenes/chapter6/ch6_choir_core.tscn", "story", ["ch6_choir_silenced", "ch6_fragment_6_collected",
		"source_key_fragment_6"], CAP_STORY],
	["res://scenes/chapter6/ch6_choir_combat_trial.tscn", "trial", ["ch6_choir_combat_trial_cleared"], CAP_TRIAL],
	["res://scenes/chapter6/ch6_ending.tscn", "story", ["ch6_complete"], CAP_STORY],
	["res://scenes/chapter7/ch7_deep_backup_intro.tscn", "story", ["ch7_deep_backup_entered"], CAP_STORY],
	["res://scenes/chapter7/ch7_memory_ocean_hub.tscn", "story", ["ch7_memory_island_hazard_cleared"], CAP_STORY],
	["res://scenes/chapter7/ch7_archive_tide.tscn", "story", ["ch7_backups_preserved", "ch7_fragment_7_collected",
		"source_key_fragment_7"], CAP_STORY],
	["res://scenes/chapter7/ch7_archive_tide_combat_trial.tscn", "trial", ["ch7_archive_tide_surge_cleared"],
		CAP_TRIAL],
	["res://scenes/chapter7/ch7_ending.tscn", "story", ["ch7_complete"], CAP_STORY],
	["res://scenes/chapter8/ch8_revolt_intro.tscn", "story", ["ch8_revolt_intro_seen"], CAP_STORY],
	["res://scenes/chapter8/ch8_saved_assembly.tscn", "story", ["ch8_faction_requests_started"], CAP_STORY],
	["res://scenes/chapter8/ch8_revolt_crisis.tscn", "story", ["ch8_revolt_led"], CAP_STORY],
	["res://scenes/chapter8/ch8_ending.tscn", "story", ["ch8_complete"], CAP_STORY],
	["res://scenes/chapter9/ch9_human_patch_intro.tscn", "story", ["ch9_human_patch_entered"], CAP_STORY],
	["res://scenes/chapter9/ch9_memory_lab.tscn", "story", ["ch9_data_vision_scan_complete"], CAP_STORY],
	["res://scenes/chapter9/ch9_creator_trial.tscn", "story", ["ch9_truth_confessed"], CAP_STORY],
	["res://scenes/chapter9/ch9_ending.tscn", "story", ["ch9_complete"], CAP_STORY],
	["res://scenes/chapter10/ch10_root_intro.tscn", "story", ["ch10_root_entered"], CAP_STORY],
	["res://scenes/chapter10/ch10_kernel_descent.tscn", "story", ["ch10_kernel_trial_cleared"], CAP_STORY],
	["res://scenes/chapter10/ch10_witness_chamber.tscn", "story", ["ch10_witness_preparation_complete"], CAP_STORY],
	["res://scenes/chapter10/ch10_sovereign_final_trial.tscn", "trial", ["ch10_sovereign_final_trial_cleared"],
		CAP_TRIAL],
	["res://scenes/chapter10/ch10_sovereign_confrontation.tscn", "story", ["ch10_destroy_sovereign"], CAP_STORY],
	["res://scenes/chapter10/ch10_ending.tscn", "ending", ["ch10_complete", "true_ending_seen", "ng_plus_unlocked"],
		CAP_STORY],
]

var _passes := 0
var _failures: Array[String] = []
var _finished := false
var _halted := false

var _leg := -1
var _handed_off := false
var _snap: Dictionary = {}
var _handoffs := 0                  # transition_started calls since the current leg was armed
var _prev_handoffs := 0             # the same count for the previous leg, taken when the next one is armed
var _choices: Array = []            # [leg, prompt, option text]
var _last_container_id := 0
var _last_line := ""
var _last_ms := 0
var _trial_attempt := -1
var _trial_alive := 0.0
var _trial_completed := false
var _input_pressed := false
var _input_real_ok := false
var _gate_uses := 0
var _gate_ms := 0
var _legs_done := 0
var _hook_stage := 0
var _next_poke_ms := 0
var _fight_stage := 0               # 0 waiting for the story enemy, 1 alive window, 2 finished by the bot
var _fight_phys0 := 0
var _fight_phys_last := 0           # physics frame count at the last _tick_game_time call
var _scale_seen := 1.0              # Engine.time_scale at the top of the leg loop, before _drive_frame resets it
var _fight_wall0 := 0
var _fight_alive_s := 0.0
var _fight_left_idle := false
var _fight_dead_seen := false
var _walking := false              # the bot holds move_right (fight legs, until the enemy leaves IDLE)
var _fight_idle := -1               # EnemyBase.State.IDLE / DEAD, read from the enemy's script (_enemy_state)
var _fight_dead := -1
var _settle_frames := 0             # consecutive settled frames (see SETTLE_FRAMES)
var _hop_level := 0                 # the player's level when the knight hop started
var _hop_presses := 0
var _hop_places := 0                # times the bot placed the player on the TutorialKnightGate this leg
var _hop_ms := 0
var _boss_stage := 0                # 0 waiting for the fight, 1 alive window, 2 callback called by the bot
var _wraith_called := false
var _boss_defeated_before: Variant = null   # the scene's BOSS_DEFEATED_VARS value just before the bot's callback
var _shatter_card_seen := false
var _shatter_line_seen := false
var _step_idx := 0                  # the next step of an Ironhold region leg
var _end_card_pressed := false
var _root_open_glitch := -1.0       # glitch_meter when the Root Access panel was first seen open (-1: not seen)
var _root_open_ms := 0


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	await process_frame
	await process_frame
	if not OS.get_user_data_dir().contains("aeth_phase0_test"):
		push_error("Refusing to run: user data dir is not isolated. Use tests/run_phase0_tests.ps1.")
		quit(2)
		return
	var root := get_root()
	var autoloads_ok: bool = true
	for n in ["GameManager", "DialogueManager", "SceneTransitions", "ContextStack", "CreditsScreen"]:
		autoloads_ok = autoloads_ok and root.get_node_or_null(n) != null
	_check(autoloads_ok,
		"isolation: GameManager, DialogueManager, SceneTransitions, ContextStack and CreditsScreen autoloads are present")
	if not autoloads_ok:
		print("PLAYTHROUGH RESULT: %d passed, %d failed" % [_passes, _failures.size()])
		quit(1)
		return
	_st().transition_started.connect(_on_transition_started)
	_new_game()
	var t_start := Time.get_ticks_msec()
	await _play()
	if not _halted:
		await _menu_and_credits()
	if not _halted:
		_final_checks()
	print("  run: %d legs of %d played, %.1f s real" % [_legs_done, LEGS.size(),
		(Time.get_ticks_msec() - t_start) / 1000.0])
	_finish()


func _check(cond: bool, name: String) -> void:
	if cond:
		_passes += 1
		print("  PASS: " + name)
	else:
		_failures.append(name)
		print("  FAIL: " + name)


## The GameManager autoload.
func _gm() -> Node: return get_root().get_node("GameManager")
## The DialogueManager autoload.
func _dm() -> Node: return get_root().get_node("DialogueManager")
## The SceneTransitions autoload.
func _st() -> Node: return get_root().get_node("SceneTransitions")
## The ContextStack autoload.
func _cs() -> Node: return get_root().get_node("ContextStack")


## The single exit: every pass and fail path ends here.
func _finish() -> void:
	if _finished:
		return
	_finished = true
	_set_walk(false)
	Engine.time_scale = 1.0
	_cs().clear_time_scale()
	_check(is_equal_approx(Engine.time_scale, 1.0), "exit: Engine.time_scale is 1 after the restore")
	print("  exit: Engine.time_scale restored to %s, ContextStack time requests cleared" % str(Engine.time_scale))
	print("")
	print("PLAYTHROUGH RESULT: %d passed, %d failed" % [_passes, _failures.size()])
	for f in _failures:
		print("  FAIL: " + f)
	quit(0 if _failures.is_empty() else 1)


# ── T14b AC-1: start state ────────────────────────────────────────────────────

## New Game: reset_game() and force_reset() (chapter1_route_test.gd :240, phase0_blockers_test.gd :424), nothing
## seeded. The first leg (the crash-site hook) is loaded by _play.
func _new_game() -> void:
	var gm := _gm()
	gm.reset_game()
	_dm().force_reset()
	var set_flags: Array = gm.story_flags.keys().filter(func(k): return gm.story_flags[k] == true)
	_check(set_flags.is_empty() and gm.source_key_count == 0 and gm.current_chapter == 1
		and is_zero_approx(gm.glitch_meter),
		"AC-1 start: New Game state after reset_game() (flags set %s, keys %d, chapter %d, glitch %s)"
			% [str(set_flags), gm.source_key_count, gm.current_chapter, str(gm.glitch_meter)])
	_check(LEGS[0][0] == HOOK, "AC-1 start: the first leg is the crash-site hook (%s)" % str(LEGS[0][0]).get_file())
	var stale: Array = KNOWN_R5_DIALOGUE.keys().filter(func(k): return (int(k) >= LEGS.size()
		or LEGS[k][0] != KNOWN_R5_DIALOGUE[k]))
	_check(stale.is_empty(), "AC-5 KNOWN_R5_DIALOGUE (TD-043) names %d legs, each matching its LEGS row (stale: %s)"
		% [KNOWN_R5_DIALOGUE.size(), str(stale)])


# ── driver ────────────────────────────────────────────────────────────────────

## One driver step. `kind` decides whether the bot owns Engine.time_scale (not inside a trial).
func _drive_frame(kind: String) -> void:
	if kind != "trial":
		Engine.time_scale = TIME_SCALE
	var dm := _dm()
	if is_instance_valid(dm._speaker_label) and is_instance_valid(dm._text_label) and dm._text_label.text != "":
		_last_line = "%s: %s" % [dm._speaker_label.text, str(dm._text_label.text).left(120)]
	if dm._awaiting_choice:
		var ready: bool = dm._choice_container != null and is_instance_valid(dm._choice_container)
		if not ready and not dm.is_skip_requested():
			dm.skip_all()   # show_choices clears skip; keep the prompt from typing out in real time
		if dm._choice_result == -1 and ready:
			var id: int = dm._choice_container.get_instance_id()
			var first := _first_button(dm._choice_container)
			# Answer only once the buttons are focusable: DialogueManager enables them after its 0.5 s grace period.
			if id != _last_container_id and first != null and first.focus_mode == Control.FOCUS_ALL:
				_last_container_id = id
				var prompt := str(dm._text_label.text).left(60) if is_instance_valid(dm._text_label) else ""
				_choices.append([_leg, prompt, first.text.left(60)])
				if first.text.strip_edges() in WARNING_OPTIONS:
					print("  info: level warning answered with option 0 '%s' at level %s"
						% [first.text, str(_gm().player_stats.get("level"))])
				dm._on_choice_pressed(0)
	elif dm.is_active and not dm.is_skip_requested():
		dm.skip_all()


## SceneTransitions.transition_started: the current scene's hand-off. Samples R5, the leg's flags, and the fight and
## Root Access state the leg's checks read (the scene is still the current one here).
func _on_transition_started() -> void:
	var gm := _gm()
	var expected: Array = LEGS[_leg][2] if _leg >= 0 and _leg < LEGS.size() else []
	var snap := {
		"dialogue_active": _dm().is_active,
		"stack_open": _cs().any_open(),
		"stack_top": _cs().top(),
		"missing": expected.filter(func(f): return not gm.has_flag(f)),
	}
	var s := current_scene
	if s != null and s.get("story_fight_retries") != null:
		var p = s.get("player")
		snap["retries"] = int(s.get("story_fight_retries"))
		snap["player_dead"] = p == null or not is_instance_valid(p) or bool(p.get("is_dead"))
	if s != null and s.get("_root_choice") != null:
		var filt = s.get("_target_filter")
		var spin = s.get("aggression_spinbox")
		snap["root"] = {
			"choice": str(s.get("_root_choice")),
			"filter": (filt as OptionButton).selected if is_instance_valid(filt) else -1,
			"aggression": float((spin as Range).value) if is_instance_valid(spin) else -1.0,
			"glitch": float(gm.glitch_meter),
		}
	snap["boss_return"] = str(gm.get_meta("boss_return_scene", ""))
	if s != null and _leg >= 0 and _leg < LEGS.size() and LEGS[_leg][1] == "boss":
		snap["boss_defeated"] = s.get(BOSS_DEFEATED_VARS.get(_leg_opts(_leg).get("boss", ""), ""))
	if s != null and s.get("_skip_completed") != null:
		snap["skip_completed"] = s.get("_skip_completed")
	_snap = snap
	_handoffs += 1
	_handed_off = true


## The current scene's file path, or "" when there is no current scene.
func _scene_path() -> String:
	return current_scene.scene_file_path if current_scene != null else ""


## The first Button under a choice container (the option-0 button), or null.
func _first_button(container: Node) -> Button:
	for n in container.find_children("*", "Button", true, false):
		return n as Button
	return null


## Leg `i`'s options (LEGS column 5), or an empty Dictionary.
func _leg_opts(i: int) -> Dictionary:
	return LEGS[i][4] if LEGS[i].size() > 4 else {}


## Leg `i`'s tag in check names: "leg 02 combat_arena.tscn (ch1_slime)".
func _leg_tag(i: int) -> String:
	var tag := "leg %02d %s" % [i, str(LEGS[i][0]).get_file()]
	var fight: String = _leg_opts(i).get("fight", "")
	return tag + (" (%s)" % fight if fight != "" else "")


## Arms leg `i`: from now on a transition_started belongs to it.
func _arm_leg(i: int) -> void:
	_leg = i
	_handed_off = false
	_snap = {}
	_prev_handoffs = _handoffs
	_handoffs = 0


## Waits (driving with the NEXT leg's kind, so a trial is left at its own time scale) until the active scene leaves
## `prev`; arms leg `next_index` the moment the scene swaps, then waits for the transition to end. Returns the new
## scene's path ("" on a cap).
func _await_scene_change(prev: String, next_index: int, next_kind: String) -> String:
	var t0 := Time.get_ticks_msec()
	var armed := false
	while Time.get_ticks_msec() - t0 < int(SWITCH_CAP_S * 1000.0):
		_drive_frame(next_kind)
		if current_scene != null and current_scene.scene_file_path != prev:
			if not armed:
				armed = true
				_arm_leg(next_index)
			if not _st().is_transitioning:
				await process_frame
				return _scene_path()
		await process_frame
	return ""


## Softlock report: everything a game-side bug report needs (`cap_s` 0 when no cap applied).
func _report(leg_index: int, why: String, elapsed_s: float, cap_s: float = 0.0) -> void:
	var dm := _dm()
	var prompt := ""
	if dm._awaiting_choice and is_instance_valid(dm._text_label):
		prompt = str(dm._text_label.text).left(80)
	var last_choice := "(none)" if _choices.is_empty() else str(_choices.back())
	print("  SOFTLOCK REPORT: %s" % why)
	print("    leg %d of %d, scene %s, %.1f s real%s" % [leg_index, LEGS.size(), _scene_path(), elapsed_s,
		(" (cap %d s)" % int(cap_s)) if cap_s > 0.0 else ""])
	print("    last line: %s" % _last_line)
	print("    open choice prompt: %s" % (prompt if prompt != "" else "(none)"))
	print("    last choice answered: %s" % last_choice)
	print("    dialogue active: %s, ContextStack top: '%s', time_scale %s" % [str(dm.is_active), str(_cs().top()),
		str(Engine.time_scale)])


func _play() -> void:
	var first: String = LEGS[0][0]
	_arm_leg(0)
	var err := change_scene_to_file(first)
	_check(err == OK, "AC-1 the bot loads %s (got %d)" % [first.get_file(), err])
	var actual := ""
	var t0 := Time.get_ticks_msec()
	while Time.get_ticks_msec() - t0 < int(float(LEGS[0][3]) * 1000.0):
		_drive_frame(LEGS[0][1])
		if _scene_path() == first and not _st().is_transitioning:
			actual = first
			break
		await process_frame
	await process_frame
	for i in LEGS.size():
		var path: String = LEGS[i][0]
		_check(actual == path, "AC-1 leg %02d arrives at %s (got '%s')" % [i, path.get_file(), actual.get_file()])
		if actual != path:
			_report(i, "expected scene %s, got '%s'" % [path.get_file(), actual], 0.0)
			_halted = true
			return
		if i > 0 and LEGS[i - 1][1] == "fight":
			_check(_prev_handoffs == 1, "AC-2 %s: the arena handed off once to %s (%d hand-offs)"
				% [_leg_tag(i - 1), path.get_file(), _prev_handoffs])
		await _drive_leg(i)
		if _halted:
			return
		var next_path: String = LEGS[i + 1][0] if i + 1 < LEGS.size() else MENU
		var next_kind: String = LEGS[i + 1][1] if i + 1 < LEGS.size() else "menu"
		actual = await _await_scene_change(path, i + 1, next_kind)
		if actual == "":
			_check(false, "AC-5 leg %02d (%s) hands off to a new scene within %d s"
				% [i, path.get_file(), int(SWITCH_CAP_S)])
			_report(i, "no scene change after the hand-off", SWITCH_CAP_S, SWITCH_CAP_S)
			_halted = true
			return
		if actual != next_path:
			_check(false, "AC-5 after leg %02d (%s) the game goes to %s (got %s)"
				% [i, path.get_file(), next_path.get_file(), actual.get_file()])
			_report(i, "wrong next scene: expected %s, got %s" % [next_path.get_file(), actual.get_file()], 0.0)
			_halted = true
			return
	_leg = LEGS.size() - 1


## Drives one leg to the scene's own hand-off and runs the per-leg checks (AC-2, AC-5, AC-6).
func _drive_leg(i: int) -> void:
	var path: String = LEGS[i][0]
	var kind: String = LEGS[i][1]
	var opts := _leg_opts(i)
	var t0 := Time.get_ticks_msec()
	var cap_s := float(LEGS[i][3])
	var cap_ms := int(cap_s * 1000.0)
	var choices_before := _choices.size()
	# _handed_off / _snap were reset by _arm_leg when this scene swapped in; a hand-off seen since then counts.
	_trial_attempt = -1
	_trial_alive = 0.0
	_trial_completed = false
	_input_pressed = false
	_input_real_ok = false
	_gate_uses = 0
	_gate_ms = 0
	_hook_stage = 0
	_next_poke_ms = 0
	_fight_stage = 0
	_fight_alive_s = 0.0
	_fight_left_idle = false
	_fight_dead_seen = false
	_root_open_glitch = -1.0
	_root_open_ms = 0
	_settle_frames = 0
	_hop_presses = 0
	_hop_places = 0
	_hop_ms = 0
	_boss_stage = 0
	_wraith_called = false
	_boss_defeated_before = null
	_shatter_card_seen = false
	_shatter_line_seen = false
	_step_idx = 0
	_end_card_pressed = false
	_last_ms = Time.get_ticks_msec()
	if kind == "hop":
		_hop_start(i)
	if kind == "ending":
		await _ending_arrival_checks()
	while not _handed_off and Time.get_ticks_msec() - t0 < cap_ms:
		var now := Time.get_ticks_msec()
		var dt := (now - _last_ms) / 1000.0
		_last_ms = now
		_scale_seen = Engine.time_scale   # the scale the last frame's physics steps ran at, before the reset to 4
		_drive_frame(kind)
		match kind:
			"room":
				_drive_room()
			"story":
				_watch_root_panel()
				_drive_end_card()
			"hop":
				_drive_knight_hop(i)
			"boss":
				_drive_boss(i)
			"shatter":
				_drive_shatter()
			"ironhold":
				_drive_ironhold(i)
			"fight":
				_drive_fight(i)
			"region":
				_drive_region()
			"input":
				await _drive_input()
			"trial":
				_drive_trial(dt)
		if _halted:
			return
		await process_frame
	_set_walk(false)   # a fight that handed off while the bot still walked must not carry the key into the next leg
	var elapsed := (Time.get_ticks_msec() - t0) / 1000.0
	var tag := _leg_tag(i)
	_check(_handed_off, "AC-6 %s hands off within its %d s cap" % [tag, int(cap_s)])
	if not _handed_off:
		_report(i, "cap hit in %s (%s)" % [path.get_file(), kind], elapsed, cap_s)
		_halted = true
		return
	if kind == "input":
		_check(_input_real_ok,
			"T14a AC-3 %s: a real ui_accept input event ended the scene's key wait (no test-side fallback)" % tag)
	if kind == "fight":
		_fight_checks(i)
	if opts.get("root_giveup", false):
		_root_checks(i, elapsed)
	if kind == "hop":
		_hop_checks(i)
	if kind == "boss":
		var var_name: String = BOSS_DEFEATED_VARS.get(opts.get("boss", ""), "")
		_check(_boss_stage == 2 and _boss_defeated_before == false and _snap.get("boss_defeated") == true,
			"%s %s: the scene's own %s was false before the bot's callback and true at the hand-off (%s -> %s)"
				% [_boss_ac(i), tag, var_name, str(_boss_defeated_before), str(_snap.get("boss_defeated"))])
	if kind == "shatter":
		_shatter_checks(i)
	_check(not _snap["stack_open"], "AC-5 %s: no ContextStack entry open at the hand-off (stack top '%s')"
		% [tag, str(_snap["stack_top"])])
	if KNOWN_R5_DIALOGUE.get(i, "") == path:
		if _snap["dialogue_active"]:
			print("  INFO: %s: dialogue still active at the hand-off: known game-side issue TD-043 (KNOWN_R5_DIALOGUE)"
				% tag)
		else:
			_check(false, "AC-5 %s: KNOWN_R5_DIALOGUE lists this leg but no dialogue was active at the hand-off:"
				% tag + " TD-043 may be fixed; remove the entry")
	else:
		_check(not _snap["dialogue_active"], "AC-5 %s: no dialogue active at the hand-off (dialogue %s)"
			% [tag, str(_snap["dialogue_active"])])
	_check(_snap["missing"].is_empty(), "AC-5 %s: flags set at the hand-off %s (missing %s)"
		% [tag, str(LEGS[i][2]), str(_snap["missing"])])
	print("  leg %02d %-40s %5.1f s real, %d choice(s), kind %s, cap %d s" % [i, path.get_file(), elapsed,
		_choices.size() - choices_before, kind, int(cap_s)])
	_legs_done += 1
	if opts.get("ch3_state", false):
		_print_ch3_state()


# ── T14b: room legs (crash-site hook, village, Elara's house) ─────────────────

## One room step: the hook's start sequence, else a poke at most every POKE_INTERVAL_MS (the route test's _wait_for).
func _drive_room() -> void:
	var s := current_scene
	if s == null or _handed_off or _st().is_transitioning:
		return
	if s.scene_file_path == HOOK:
		_drive_hook(s)
	elif not _dm().is_active and Time.get_ticks_msec() >= _next_poke_ms and _poke_room(s):
		# Gated on the dialogue box being closed (it auto-hides after a grace period once a .dlg node ends): a player
		# walks to the door or the bridge after the last line, not in the frame it ends.
		_next_poke_ms = Time.get_ticks_msec() + POKE_INTERVAL_MS


## The crash-site hook, as chapter1_route_test.gd _test_new_game_to_region :250-257 starts it: wait for the opening
## dialogue (prologue + crash_site start) to finish, take the signal fragment, wait for its line, then leave east.
func _drive_hook(hook: Node) -> void:
	var busy: bool = hook.get("_dialogue_busy")
	match _hook_stage:
		0:
			if busy:
				_hook_stage = 1       # the opening is playing
		1:
			if not busy:
				hook._on_signalfragment_interaction(hook.get("_player"))
				_hook_stage = 2
		2:
			if not busy:
				hook._complete_opening_hook()
				_hook_stage = 3


## One "walk up and press interact" for the rooms that wait on the player. Copied from chapter1_route_test.gd
## _poke_room :199-234 (village, house and shrine branches; the arena branch is _drive_fight).
## Returns true when it poked something.
##   village: after the invite, Elara's door; after the stew, the bridge (which runs the north field first).
##   house:   once the stew is done, the door back out.
##   shrine:  the altar, then (Fragment One collected) the stair door.
func _poke_room(s: Node) -> bool:
	var player := s.get_node_or_null("Player")
	if player == null:
		return false
	match s.scene_file_path:
		VILLAGE:
			if s.get("_entrance_done") and not s.get("in_dialogue"):
				s._on_bridge_trigger(player)   # walk to the bridge
				return true
			if s.get("_invited") and not s.get("_entrance_done") and not s._busy():
				s._on_elara_house_door_interaction(player)   # walk to Elara's door
				return true
		HOUSE:
			if _gm().has_flag("ch1_stew_done") and not s._busy():
				s._on_door_interaction(player)   # back out to the village
				return true
		SHRINE:
			if not s._busy():
				if not _gm().has_flag("source_key_fragment_1"):
					s._on_altar_interaction(player)   # walk to the altar
				else:
					s._on_stair_door_interaction(player)   # walk to the stair door
				return true
	return false


# ── T14b AC-2: arena fights and the guardian give-up ──────────────────────────

## One fight step. Stage 0: wait for the arena's story enemy, then check the row id and that the win flags are false.
## Stage 1: the alive window (3 s of game time and the enemy out of IDLE, wall-capped); a death fails the run.
## Then the finish
## through the enemy's own API, copied from chapter1_route_test.gd :212-222 (and phase0_blockers_test.gd _ch1_poke).
func _drive_fight(i: int) -> void:
	var s := current_scene
	if s == null or _fight_stage >= 2 or _handed_off or _st().is_transitioning or s.scene_file_path != ARENA:
		return
	var tag := _leg_tag(i)
	var want: String = _leg_opts(i).get("fight", "")
	var enemy = s.get("_story_enemy")
	if _fight_stage == 0:
		if not is_instance_valid(enemy) or str(s.get("_story_id")) == "":
			return
		_check(s.scene_file_path == ARENA and str(s.get("_story_id")) == want,
			"AC-2 %s: the scene is combat_arena.tscn with story_fight_id '%s' (got '%s')"
				% [tag, want, str(s.get("_story_id"))])
		var early: Array = LEGS[i][2].filter(func(f): return _gm().has_flag(f))
		_check(early.is_empty(), "AC-2 %s: the row's win flags %s are false before the finish (already set %s)"
			% [tag, str(LEGS[i][2]), str(early)])
		_fight_idle = _enemy_state(enemy, "IDLE")
		_fight_dead = _enemy_state(enemy, "DEAD")
		_check(_fight_idle >= 0 and _fight_dead >= 0, "AC-2 %s: the enemy's State enum is readable (IDLE %d, DEAD %d)"
			% [tag, _fight_idle, _fight_dead])
		_fight_stage = 1
		_fight_phys0 = Engine.get_physics_frames()
		_fight_phys_last = _fight_phys0
		_fight_alive_s = 0.0
		_fight_wall0 = Time.get_ticks_msec()
		print("  INFO fight %s: player HP at the window's start %s" % [want, _player_hp(s.get("player"))])
		return
	var wall_s := (Time.get_ticks_msec() - _fight_wall0) / 1000.0
	_tick_game_time()
	var p = s.get("player")
	var dead: bool = p == null or not is_instance_valid(p) or bool(p.get("is_dead"))
	var retries: int = int(s.get("story_fight_retries"))
	if dead or retries > 0:
		_check(false, "AC-2 %s: the player stays alive through the alive window (dead %s, retries %d at %.2f s of game time)"
			% [tag, str(dead), retries, _fight_alive_s])
		_set_walk(false)
		_report(i, "the player died in the alive window of the %s fight" % want, wall_s)
		_halted = true
		return
	var state: int = int(enemy.get("current_state")) if is_instance_valid(enemy) else _fight_dead
	if state == _fight_dead:
		_fight_dead_seen = true
	elif state != _fight_idle:
		_fight_left_idle = true
	# A player walks toward the enemy: a real move_right input while it is still IDLE (the slime only notices the
	# player within its detection_range, 250 px, and spawns 560 px away), released once it has left IDLE.
	_set_walk(not _fight_left_idle and not _fight_dead_seen)
	if (_fight_alive_s < FIGHT_ALIVE_S or not _fight_left_idle) and wall_s < FIGHT_ALIVE_WALL_S:
		return
	_set_walk(false)
	print("  INFO fight %s: player HP at the window's end %s" % [want, _player_hp(p)])
	_check(_fight_alive_s >= FIGHT_ALIVE_S,
		"AC-2 %s: the alive window reached %.0f s of game time inside its %d s wall cap"
			% [tag, FIGHT_ALIVE_S, int(FIGHT_ALIVE_WALL_S)]
			+ " (%.2f s of game time at time_scale %s, %.2f s wall clock)"
			% [_fight_alive_s, str(Engine.time_scale), wall_s])
	_check(not _fight_dead_seen, "AC-2 %s: the story enemy's current_state was never DEAD in the alive window" % tag)
	_check(_fight_left_idle, "AC-2 %s: the story enemy left IDLE at least once in the alive window (its AI ran)" % tag)
	_fight_stage = 2
	if not is_instance_valid(enemy):
		return
	print("  fight %s: alive %.2f s of game time (%.2f s wall), enemy state %d; finishing it through its own API"
		% [want, _fight_alive_s, wall_s, int(enemy.get("current_state"))])
	# D3 isolation cost: the boar is armoured until dizzy, so it is made dizzy first (chapter1_route_test.gd :217-221).
	if enemy.has_method("_enter_dizzy"):
		enemy._enter_dizzy()
	enemy.take_damage(enemy.max_health)


## Adds the game time since the last call to _fight_alive_s: the physics frames stepped since then / ticks per second
## x the time scale they ran at (_scale_seen, read before _drive_frame resets it, so a hitstop in between counts at
## its own scale; Godot steps physics at the tick rate in real time and scales each step's delta). Frames stepped
## while the tree is paused add nothing (story AC-2, AC-3; code review S2).
func _tick_game_time() -> void:
	var f := Engine.get_physics_frames()
	if not paused:
		_fight_alive_s += float(f - _fight_phys_last) / float(Engine.physics_ticks_per_second) * _scale_seen
	_fight_phys_last = f


## The player's HP as "current/max", or "?" when it cannot be read.
func _player_hp(p: Variant) -> String:
	if p == null or not is_instance_valid(p):
		return "?"
	return "%s/%s" % [str(p.get("current_health")), str(p.get("max_health"))]


## Holds (on) or releases (off) the move_right action with real input events, as a player's key does.
func _set_walk(on: bool) -> void:
	if on == _walking:
		return
	_walking = on
	var ev := InputEventAction.new()
	ev.action = &"move_right"
	ev.pressed = on
	Input.parse_input_event(ev)


## The value of EnemyBase.State.<state_name>, read from the enemy's script chain at run time (-1 if absent). Naming
## the EnemyBase class in this file compiles enemy_base.gd before the autoloads exist (a SceneTree script is compiled
## first), which fails on its autoload names and leaves the enemies' scripts broken.
func _enemy_state(enemy: Object, state_name: String) -> int:
	var script: Script = enemy.get_script()
	while script != null:
		var states = script.get_script_constant_map().get("State")
		if states is Dictionary:
			return int(states.get(state_name, -1))
		script = script.get_base_script()
	return -1


## A fight leg's checks after its hand-off: the bot's finish came first, the win flags are set, no retry, player alive.
func _fight_checks(i: int) -> void:
	var tag := _leg_tag(i)
	_check(_fight_stage == 2, "AC-2 %s: the hand-off followed the bot's finish (fight stage %d)" % [tag, _fight_stage])
	_check(_snap["missing"].is_empty(), "AC-2 %s: the row's win flags %s are set after the finish (missing %s)"
		% [tag, str(LEGS[i][2]), str(_snap["missing"])])
	_check(_snap.get("retries", -1) == 0, "AC-2 %s: no retry ran (story_fight_retries %s)"
		% [tag, str(_snap.get("retries", "?"))])
	_check(_snap.get("player_dead", true) == false, "AC-2 %s: the player is not dead at the hand-off (dead %s)"
		% [tag, str(_snap.get("player_dead", "?"))])


## The Root Access panel: record glitch_meter when it is first seen open. Read-only; the bot never touches the panel.
func _watch_root_panel() -> void:
	var s := current_scene
	if s == null or _root_open_glitch >= 0.0 or s.get("root_access_tutorial_active") != true:
		return
	_root_open_glitch = float(_gm().glitch_meter)
	_root_open_ms = Time.get_ticks_msec()
	print("  info: Root Access panel open (glitch_meter %s); the bot gives it no input (D2)" % str(_root_open_glitch))


## The guardian leg (D2): the give-up chose the fight, checked on the game's state sampled at the hand-off.
func _root_checks(i: int, elapsed: float) -> void:
	var tag := _leg_tag(i)
	var r: Dictionary = _snap.get("root", {})
	_check(_root_open_glitch >= 0.0, "AC-2 %s: the Root Access panel opened (seen by the bot)" % tag)
	if _root_open_ms > 0:
		print("  info: Root Access panel to the hand-off: %.1f s real (leg %.1f s)"
			% [(Time.get_ticks_msec() - _root_open_ms) / 1000.0, elapsed])
	_check(r.get("choice", "") == "fight", "AC-2 %s: the game's _root_choice is 'fight' at the hand-off (got '%s')"
		% [tag, str(r.get("choice", "(no sample)"))])
	_check(int(r.get("filter", -1)) == 0 and is_equal_approx(float(r.get("aggression", -1.0)), 1.0),
		"AC-2 %s: target filter still ALL (index %s) and aggression still 1.0 (%s)"
			% [tag, str(r.get("filter", "?")), str(r.get("aggression", "?"))])
	_check(_root_open_glitch >= 0.0 and is_equal_approx(float(r.get("glitch", -2.0)), _root_open_glitch),
		"AC-2 %s: glitch_meter unchanged since the panel opened (%s -> %s)"
			% [tag, str(_root_open_glitch), str(r.get("glitch", "?"))])


# ── T14b pass 2: knight hop, bosses, shatter, Ironhold, end cards ─────────────

## Sends a real press and release of `action`, as a player's key does.
func _press(action: StringName) -> void:
	for pressed in [true, false]:
		var ev := InputEventAction.new()
		ev.action = action
		ev.pressed = pressed
		Input.parse_input_event(ev)


## The knight hop's start (AC-3): clear boss_return_scene, so only the region's _enter_boss_arena() can set it again.
func _hop_start(i: int) -> void:
	var gm := _gm()
	if gm.has_meta("boss_return_scene"):
		gm.remove_meta("boss_return_scene")
	_hop_level = int(gm.player_stats.get("level", 1))
	_check(not gm.has_meta("boss_return_scene"), "AC-3 %s: boss_return_scene is cleared at the leg's start (level %d)"
		% [_leg_tag(i), _hop_level])


## One knight-hop step (AC-3): once the region is idle, put the player on the TutorialKnightGate, let the physics step
## report the overlap, then send a real "interact" press to the region's own _unhandled_input (again after 2 s if
## nothing followed, at most 3 presses). The level warning's choice is answered by _drive_frame (option 0).
func _drive_knight_hop(i: int) -> void:
	var s := current_scene
	if s == null or _handed_off or _st().is_transitioning or _hop_presses >= 3 or s.scene_file_path != REGION:
		return
	if s.call("_is_talking"):
		_settle_frames = 0
		return
	_settle_frames += 1
	if _settle_frames < SETTLE_FRAMES or (_hop_presses > 0 and Time.get_ticks_msec() - _hop_ms < 2000):
		return
	var gate := s.get_node_or_null("TutorialKnightGate") as Node2D
	var player := s.get("_player") as Node2D
	if gate == null or player == null:
		_check(false, "AC-3 %s: the region has its TutorialKnightGate and player (gate %s, player %s)"
			% [_leg_tag(i), str(gate), str(player)])
		_report(i, "no TutorialKnightGate or player in oakhaven_region", 0.0)
		_halted = true
		return
	# Press only once the region itself lists the gate in its _overlapping (what its interact key acts on). Teleport
	# only while it does not, at most HOP_PLACE_MAX times: an earlier "within 1 px of the gate" test re-teleported
	# every frame physics nudged the player, never pressed, and each sub-200 px hop counted as random-encounter steps
	# (random_encounter_system.gd :449-465) until an ambush fired (t14b_run_all_final.log, leg 12).
	var overlapping: Array = s.get("_overlapping") if s.get("_overlapping") is Array else []
	if not overlapping.has(gate):
		if _hop_places >= HOP_PLACE_MAX:
			_check(false, "AC-3 %s: the region lists the TutorialKnightGate as overlapping after %d placement(s)"
				% [_leg_tag(i), _hop_places])
			_report(i, "the region never registered the player on the TutorialKnightGate", 0.0)
			_halted = true
			return
		_hop_places += 1
		player.global_position = gate.global_position
		_settle_frames = 0       # the overlap is reported on a later physics step
		return
	_hop_presses += 1
	_hop_ms = Time.get_ticks_msec()
	print("  info: knight hop: real interact press %d on the TutorialKnightGate (level %d)" % [_hop_presses, _hop_level])
	_press(&"interact")


## The knight hop's checks (AC-3): boss_return_scene set by the region at the hand-off; the warning seen or the level.
func _hop_checks(i: int) -> void:
	var tag := _leg_tag(i)
	_check(_snap.get("boss_return", "") == REGION,
		"AC-3 %s: boss_return_scene is oakhaven_region.tscn when the knight is handed off (got '%s')"
			% [tag, str(_snap.get("boss_return", ""))])
	_check(_hop_presses >= 1, "AC-3 %s: a real interact press started the hop (%d press(es))" % [tag, _hop_presses])
	if _hop_level < KNIGHT_WARN_LEVEL:
		var seen := _choices.any(func(c): return c[0] == i and str(c[2]).strip_edges() == "Enter the Arena")
		_check(seen, "AC-3 %s: the level warning (level %d) was seen and answered with option 0 'Enter the Arena'"
			% [tag, _hop_level])
	else:
		print("  info: %s: no level warning expected at level %d" % [tag, _hop_level])


## The AC tag of a boss leg: the knight is AC-3, the Chapter 2 bosses AC-4.
func _boss_ac(i: int) -> String:
	return "AC-3" if _leg_opts(i).get("boss", "") == "knight" else "AC-4"


## Whether a boss leg's fight is running: the knight's combat_started; the Proxy's boss_node on a settled scene; the
## Underground's wraith dialogue (started here with _on_wraith_approach, chapter2_route_test.gd :182) over; the Clock
## Tower settled.
func _boss_ready(s: Node, which: String) -> bool:
	match which:
		"knight":
			return s.get("combat_started") == true
		"proxy":
			return s.get("boss_node") != null and _settle_frames >= SETTLE_FRAMES
		"wraith":
			if not _wraith_called:
				if _settle_frames < SETTLE_FRAMES:
					return false
				_wraith_called = true
				_settle_frames = 0
				s._on_wraith_approach(s.get("player_node"))
				return false
			return s.get("_wraith_approached") == true and _settle_frames >= SETTLE_FRAMES
	return _settle_frames >= SETTLE_FRAMES


## One boss step (D3): wait for the fight, then the alive window (FIGHT_ALIVE_S of game time; the knight's
## combat_started must stay true, a retry clears it), then the scene's own defeat callback. A death fails the run.
func _drive_boss(i: int) -> void:
	var s := current_scene
	if s == null or _boss_stage >= 2 or _handed_off or _st().is_transitioning or s.scene_file_path != LEGS[i][0]:
		return
	var which: String = _leg_opts(i).get("boss", "")
	var tag := "%s %s" % [_boss_ac(i), _leg_tag(i)]
	_settle_frames = _settle_frames + 1 if not _dm().is_active else 0
	if _boss_stage == 0:
		if _boss_ready(s, which):
			_boss_stage = 1
			_fight_phys0 = Engine.get_physics_frames()
			_fight_phys_last = _fight_phys0
			_fight_alive_s = 0.0
			_fight_wall0 = Time.get_ticks_msec()
			print("  info: boss %s: the fight is running; the alive window starts (player HP %s)"
				% [which, _player_hp(_boss_player(s, which))])
		return
	var wall_s := (Time.get_ticks_msec() - _fight_wall0) / 1000.0
	var real_s := float(Engine.get_physics_frames() - _fight_phys0) / float(Engine.physics_ticks_per_second)
	_tick_game_time()
	var p = _boss_player(s, which)
	var dead: bool = p == null or not is_instance_valid(p) or p.get("is_dead") == true
	var running: bool = which != "knight" or s.get("combat_started") == true
	if dead or not running:
		_check(false, "%s: the player stays alive through the %.0f s game-time alive window (dead %s, running %s at %.2f"
			% [tag, FIGHT_ALIVE_S, str(dead), str(running), _fight_alive_s] + " s game, %.2f s real)" % real_s)
		_report(i, "the player died in the alive window of the %s fight" % which, wall_s)
		_halted = true
		return
	if _fight_alive_s < FIGHT_ALIVE_S and wall_s < FIGHT_ALIVE_WALL_S:
		return
	_check(_fight_alive_s >= FIGHT_ALIVE_S,
		"%s: the alive window reached %.0f s of game time (physics frames / ticks per second x time_scale)"
			% [tag, FIGHT_ALIVE_S]
			+ " in its %d s wall cap (%.2f s game = %.2f s real at time_scale %s)"
			% [int(FIGHT_ALIVE_WALL_S), _fight_alive_s, real_s, str(Engine.time_scale)])
	_check(p.get("is_dead") != null, "%s: the scene's player has a readable is_dead (the alive check means something)"
		% tag)
	_boss_stage = 2
	_boss_defeated_before = s.get(BOSS_DEFEATED_VARS.get(which, ""))
	var method: String = BOSS_CALLBACKS.get(which, "")
	print("  boss %s: alive %.2f s game, player HP %s at the window's end; calling the scene's %s() (D3)"
		% [which, _fight_alive_s, _player_hp(p), method])
	s.call(method)


## A boss scene's player node: the knight scene's `player`, the Chapter 2 boss scenes' `player_node`.
func _boss_player(s: Node, which: String) -> Variant:
	return s.get("player") if which == "knight" else s.get("player_node")


## The shatter (AC-3): watch for the end card and the last line; no skip input is ever sent.
func _drive_shatter() -> void:
	var s := current_scene
	if s == null or s.scene_file_path != SHATTER:
		return
	var card = s.get("chapter_end_card")
	if is_instance_valid(card) and (card as CanvasItem).visible:
		_shatter_card_seen = true
	var dm := _dm()
	if (is_instance_valid(dm._text_label) and str(dm._text_label.text).contains(SHATTER_END_LINE)) \
			or _last_line.contains(SHATTER_END_LINE):
		_shatter_line_seen = true


## The shatter's no-skip checks (AC-3).
func _shatter_checks(i: int) -> void:
	var tag := _leg_tag(i)
	_check(_shatter_card_seen, "AC-3 %s: played through: chapter_end_card was seen visible" % tag)
	_check(_shatter_line_seen, "AC-3 %s: played through: the '%s ... to continue' line was shown"
		% [tag, SHATTER_END_LINE])
	_check(_snap.get("skip_completed", true) == false, "AC-3 %s: no skip: _skip_completed is false at the hand-off (%s)"
		% [tag, str(_snap.get("skip_completed", "(no sample)"))])


## One Ironhold region step (AC-4), once the region is settled (not _city_busy, no dialogue for SETTLE_FRAMES frames).
## Steps, from chapter2_route_test.gd _test_careful_route :152-194 with _talk :111 and _enter_gate :119 copied:
## "talk:<NPC>" -> _interact_npc, "gate:<Gate>" -> _interact_story (AdminBossGate: _interact_boss), "bronze" -> the
## bracket's flag and _place_story_gates() (:168-169). The leg ends at the scene change the last step starts.
func _drive_ironhold(i: int) -> void:
	var s := current_scene
	if s == null or _handed_off or _st().is_transitioning or s.scene_file_path != IH_REGION:
		return
	var steps: Array = _leg_opts(i).get("steps", [])
	if _step_idx >= steps.size():
		return
	if s.get("_city_busy") == true or _dm().is_active:
		_settle_frames = 0
		return
	_settle_frames += 1
	if _settle_frames < SETTLE_FRAMES:
		return
	_settle_frames = 0
	var step: String = steps[_step_idx]
	_step_idx += 1
	var parts := step.split(":")
	var tag := _leg_tag(i)
	print("  info: %s step %d: %s (level %s)" % [tag, _step_idx, step, str(_gm().player_stats.get("level"))])
	if parts[0] == "bronze":
		_gm().set_story_flag("ch2_arena_bronze_complete", true)   # isolation cost: arena combat not under test
		s._place_story_gates()
		return
	var node: Node = s.get_node_or_null(parts[1])
	_check(node != null, "AC-4 %s: %s is in the region for step '%s'" % [tag, parts[1], step])
	if node == null:
		_report(i, "%s missing in ironhold_region (step '%s')" % [parts[1], step], 0.0)
		_halted = true
		return
	match parts[0]:
		"talk":
			s._interact_npc(node)
		"gate":
			if parts[1] == "AdminBossGate":
				s._interact_boss(node)
			else:
				s._interact_story(node)


## A chapter-end card that waits for a key (ch2_ending's end_card_visible): one real ui_accept press, as a player.
func _drive_end_card() -> void:
	var s := current_scene
	if s == null or _end_card_pressed or s.get("end_card_visible") != true:
		return
	_end_card_pressed = true
	print("  info: %s: end card visible; one real ui_accept press" % s.scene_file_path.get_file())
	_press(&"ui_accept")


## AC-4: the real state at the Chapter 3 hand-off, as INFO lines (compared with T14a's old seed in the evidence).
func _print_ch3_state() -> void:
	var gm := _gm()
	var flags: Array = gm.story_flags.keys().filter(func(k): return gm.story_flags[k] == true)
	flags.sort()
	print("  INFO ch3 state: %d flags set" % flags.size())
	for n in range(0, flags.size(), 6):
		print("  INFO ch3 flags: %s" % ", ".join(PackedStringArray(flags.slice(n, n + 6))))
	print("  INFO ch3 state: keys %d, level %s, gold %s, xp %s, glitch %s, chapter %s" % [gm.source_key_count,
		str(gm.player_stats.get("level")), str(gm.player_stats.get("gold")), str(gm.player_stats.get("xp")),
		str(gm.glitch_meter), str(gm.current_chapter)])
	print("  INFO ch3 state: player_stats %s" % str(gm.player_stats))
	print("  INFO ch3 state: relationships %s" % str(gm.relationships))
	_check(gm.has_flag("source_key_fragment_2") and gm.source_key_count == 2,
		"AC-4 at the Chapter 3 hand-off: source_key_fragment_2 set and source_key_count 2 (got %d)" % gm.source_key_count)


# ── T14a: region, input and trial legs ────────────────────────────────────────

## The Wastes region: use the ServerRoomGate once it exists (placed in _ready once ch2_data_wraith_defeated is set),
## only while no transition is running (SceneTransitions.change_scene ignores a call made during one); if no hand-off
## follows within 2 s, use it again (at most 3 times).
func _drive_region() -> void:
	if current_scene == null or _handed_off or _st().is_transitioning or _dm().is_active:
		return
	if _gate_uses >= 3 or (_gate_uses > 0 and Time.get_ticks_msec() - _gate_ms < 2000):
		return
	var gate := current_scene.get_node_or_null("ServerRoomGate")
	if gate != null:
		_gate_uses += 1
		_gate_ms = Time.get_ticks_msec()
		if _gate_uses > 1:
			print("  info: ServerRoomGate used again (use %d): no hand-off followed the previous use" % _gate_uses)
		current_scene._interact_story(gate)


## ch3_ending waits for a real ui_accept press (capped at 120 s of scaled time by the scene). A real input event first;
## if the scene is still waiting 30 frames later, the test-side fallback finishes the run and the leg's check fails.
func _drive_input() -> void:
	if current_scene == null or _input_pressed or current_scene.get("_waiting_for_input") != true:
		return
	_input_pressed = true
	var down := InputEventAction.new()
	down.action = &"ui_accept"
	down.pressed = true
	Input.parse_input_event(down)
	await process_frame
	var up := InputEventAction.new()
	up.action = &"ui_accept"
	up.pressed = false
	Input.parse_input_event(up)
	for n in 30:
		await process_frame
		if current_scene == null or current_scene.get("_waiting_for_input") != true:
			_input_real_ok = true
			print("  info: the real ui_accept input event ended ch3_ending's wait")
			return
	print("  FALLBACK (test-side): a real ui_accept event did not end ch3_ending's wait; set _waiting_for_input = false")
	current_scene._waiting_for_input = false


## A trial: wait for one attempt to have run for TRIAL_ALIVE_S of scaled time with the player alive, then complete it.
func _drive_trial(dt: float) -> void:
	var s := current_scene
	if s == null or _trial_completed:
		return
	var attempts: int = s.get("_attempts")
	if attempts != _trial_attempt:
		_trial_attempt = attempts
		_trial_alive = 0.0
	var p: Node = s.get("player")
	var dead: bool = p == null or not is_instance_valid(p) or bool(p.get("is_dead"))
	if attempts >= 1 and not dead and not bool(s.get("_retry_requested")):
		_trial_alive += dt * Engine.time_scale
	var markers: Array = s.get("_active_markers")
	if _trial_alive >= TRIAL_ALIVE_S and markers.is_empty() and not dead:
		_trial_completed = true
		print("  trial %s: alive %.1f s of scaled time in attempt %d at time_scale %s, no hazard in flight;"
			% [s.scene_file_path.get_file(), _trial_alive, attempts, str(Engine.time_scale)]
			+ " calling _complete_trial()")
		# Test-side work-around (findings.md F-2): completing mid-attempt is not something a player can do. Completing
		# while a hazard is in flight makes _run_hazard write to a marker _clear_hazards() has just freed (a script
		# error, hit once on the Sovereign trial; its active-window loop does not re-check the stop flags on its last
		# tick). So the bot completes only when no hazard marker exists, and sets _retry_requested first, so a hazard
		# that starts afterwards takes its own "stop" branch (free the marker, return false).
		s._retry_requested = true
		s._complete_trial()


# ── T14a AC-5: ending, main menu, credits ─────────────────────────────────────

## T14a AC-5: on arriving at ch10_ending, the ending's flags and the "TRUE ENDING" text.
func _ending_arrival_checks() -> void:
	await process_frame
	var gm := _gm()
	_check(gm.has_flag("ch10_complete") and gm.has_flag("true_ending_seen") and gm.has_flag("ng_plus_unlocked")
		and gm.ng_plus_available,
		"T14a AC-5 ch10_ending sets ch10_complete, true_ending_seen, ng_plus_unlocked and ng_plus_available")
	var found := false
	for n in current_scene.find_children("*", "RichTextLabel", true, false):
		if (n as RichTextLabel).get_parsed_text().contains("TRUE ENDING"):
			found = true
	_check(found, "T14a AC-5 the ending's text contains 'TRUE ENDING'")


## The current scene's first Button whose text is exactly `text`, or null.
func _find_button(text: String) -> Button:
	if current_scene == null:
		return null
	for n in current_scene.find_children("*", "Button", true, false):
		if (n as Button).text == text:
			return n as Button
	return null


## T14a AC-5: the ending returns to the main menu, NEW GAME+ is offered, and the credits open and close on ui_cancel.
func _menu_and_credits() -> void:
	var t0 := Time.get_ticks_msec()
	while _scene_path() != MENU and Time.get_ticks_msec() - t0 < int(SWITCH_CAP_S * 1000.0):
		await process_frame
	_check(_scene_path() == MENU, "T14a AC-5 the ending returns to main_menu.tscn")
	if _scene_path() != MENU:
		_report(LEGS.size(), "the game did not reach the main menu after ch10_ending",
			(Time.get_ticks_msec() - t0) / 1000.0)
		_halted = true
		return
	for n in 10:
		await process_frame
	var ng := _find_button("NEW GAME+")
	_check(ng != null and ng.visible, "T14a AC-5 the main menu offers a visible NEW GAME+ button")
	var credits := get_root().get_node("CreditsScreen")
	credits.show_credits(false)
	await process_frame
	await process_frame
	_check(credits.visible and _cs().is_open(&"credits") and _cs().any_open(),
		"T14a AC-5 CreditsScreen opens (visible, a ContextStack entry open)")
	var cancel := InputEventAction.new()
	cancel.action = &"ui_cancel"
	cancel.pressed = true
	Input.parse_input_event(cancel)
	await process_frame
	var release := InputEventAction.new()
	release.action = &"ui_cancel"
	release.pressed = false
	Input.parse_input_event(release)
	var t1 := Time.get_ticks_msec()
	while _cs().any_open() and Time.get_ticks_msec() - t1 < 10000:
		await process_frame
	_check(not _cs().any_open() and not paused,
		"T14a AC-5 a ui_cancel press closes the credits: ContextStack empty and the tree unpaused (top '%s', paused %s)"
			% [str(_cs().top()), str(paused)])


## End of run: 7 Source Keys, the slot-99 auto-save, and the log of every choice the bot answered.
func _final_checks() -> void:
	var gm := _gm()
	_check(gm.source_key_count == KEYS_AT_END,
		"T14a AC-4 Source Keys collected: source_key_count %d == %d" % [gm.source_key_count, KEYS_AT_END])
	_check(FileAccess.file_exists("user://save_slot_99.save"),
		"T14a AC-4 the game's auto-save exists in the isolated user:// (slot 99)")
	_check(_choices.size() > 0, "AC-1 the bot answered %d choice prompts with option 0" % _choices.size())
	for c in _choices:
		print("    choice leg %02d: %s -> option 0: %s" % [c[0], c[1], c[2]])
