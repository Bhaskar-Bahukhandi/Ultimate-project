extends SceneTree

const OPENING_SCENE := "res://scenes/chapter1/opening_crash_site_hook.tscn"
const MAIN_MENU_SCENE := "res://scenes/main_menu.tscn"
const LEGACY_SCENE := "res://scenes/prologue/flight_707.tscn"
const OUTPUT_PATH := "res://docs/gameplay_audit/phase_10n_a2_opening_hook/diagnostics/opening_hook_runtime_validation.json"

var _results: Dictionary = {
	"phase": "10N-A2",
	"evidence_type": "HEADLESS RUNTIME EVIDENCE",
	"live_headed_play": false,
	"screenshot_status": "not_attempted_in_headless_validation",
	"checks": {},
	"errors": [],
}


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	await process_frame
	_record("opening_scene_exists", ResourceLoader.exists(OPENING_SCENE), OPENING_SCENE)
	_record("main_menu_scene_exists", ResourceLoader.exists(MAIN_MENU_SCENE), MAIN_MENU_SCENE)
	_record("legacy_scene_exists", ResourceLoader.exists(LEGACY_SCENE), LEGACY_SCENE)
	await _validate_opening_scene_direct()
	await _validate_main_menu_route()
	_write_results()
	var ok := true
	for check_name in _results["checks"].keys():
		if not bool(_results["checks"][check_name].get("pass", false)):
			ok = false
			break
	quit(0 if ok else 1)


func _validate_opening_scene_direct() -> void:
	var game_manager := root.get_node_or_null("GameManager")
	if game_manager and game_manager.has_method("reset_game"):
		game_manager.call("reset_game")

	var packed := ResourceLoader.load(OPENING_SCENE) as PackedScene
	if not packed:
		_record("opening_scene_loads", false, "PackedScene load failed")
		return
	var scene := packed.instantiate()
	root.add_child(scene)
	current_scene = scene
	await process_frame
	await physics_frame

	_record("first_playable_scene_reached", scene.name == "OpeningCrashSiteHook", scene.name)

	var player := scene.get_node_or_null("Player") as CharacterBody2D
	_record("player_node_exists", player != null, player.get_path() if player else "missing")

	if player:
		var start_pos := player.global_position
		Input.action_press("move_right")
		for _i in range(45):
			await physics_frame
		Input.action_release("move_right")
		var end_pos := player.global_position
		_record("movement_input_changes_player_position", end_pos.distance_to(start_pos) > 8.0, "start=%s end=%s distance=%.2f" % [str(start_pos), str(end_pos), end_pos.distance_to(start_pos)])

	var objective_label := scene.get_node_or_null("OpeningHookHUD/FirstMinuteObjectivePanel/VBoxContainer/ObjectiveLabel")
	_record("first_objective_text_exists", objective_label != null and str(objective_label.text).contains("Stand up. Find a signal"), objective_label.text if objective_label else "missing")

	var signal_node := scene.get_node_or_null("SignalFragment")
	_record("interactable_signal_exists", signal_node != null and signal_node.is_in_group("interactable"), signal_node.get_path() if signal_node else "missing")

	if scene.has_method("_on_signalfragment_interaction") and player:
		scene.call("_on_signalfragment_interaction", player)
		await process_frame
		var signal_flag := false
		if game_manager and game_manager.has_method("get_story_flag"):
			signal_flag = bool(game_manager.call("get_story_flag", "ch1_opening_hook_signal_found"))
		_record("signal_interaction_sets_flag", signal_flag, "ch1_opening_hook_signal_found=%s" % str(signal_flag))
		var pulse := scene.get_node_or_null("GlitchPulse")
		_record("danger_pulse_arms_after_interaction", pulse != null and pulse.visible and pulse.monitoring, "visible=%s monitoring=%s" % [str(pulse.visible if pulse else false), str(pulse.monitoring if pulse else false)])
	else:
		_record("signal_interaction_sets_flag", false, "handler/player missing")
		_record("danger_pulse_arms_after_interaction", false, "handler/player missing")

	scene.queue_free()
	await process_frame


func _validate_main_menu_route() -> void:
	var packed := ResourceLoader.load(MAIN_MENU_SCENE) as PackedScene
	if not packed:
		_record("main_menu_loads", false, "PackedScene load failed")
		return
	var menu := packed.instantiate()
	root.add_child(menu)
	current_scene = menu
	await process_frame
	_record("legacy_debug_method_exists", menu.has_method("_start_legacy_cinematic_prologue"), "_start_legacy_cinematic_prologue")
	_record("new_game_method_exists", menu.has_method("_on_new_game_pressed"), "_on_new_game_pressed")
	if menu.has_method("_on_new_game_pressed"):
		menu.call("_on_new_game_pressed")
		var reached := false
		var reached_name := ""
		for _i in range(160):
			await process_frame
			if current_scene:
				reached_name = current_scene.name
				if current_scene.name == "OpeningCrashSiteHook":
					reached = true
					break
		_record("new_game_routes_to_opening_hook", reached, reached_name)
	else:
		_record("new_game_routes_to_opening_hook", false, "new game method missing")


func _record(check_name: String, passed: bool, notes: String) -> void:
	_results["checks"][check_name] = {
		"pass": passed,
		"notes": notes,
	}


func _write_results() -> void:
	var file := FileAccess.open(OUTPUT_PATH, FileAccess.WRITE)
	if not file:
		push_error("[10N-A2] Could not write validation results: %s" % OUTPUT_PATH)
		return
	file.store_string(JSON.stringify(_results, "\t"))
	file.close()

