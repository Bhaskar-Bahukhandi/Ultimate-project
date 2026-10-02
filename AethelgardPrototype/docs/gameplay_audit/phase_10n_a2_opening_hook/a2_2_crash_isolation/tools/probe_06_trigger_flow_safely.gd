extends SceneTree

const OPENING_SCENE := "res://scenes/chapter1/opening_crash_site_hook.tscn"
const OUT := "res://docs/gameplay_audit/phase_10n_a2_opening_hook/a2_2_crash_isolation/diagnostics/probe_06_trigger_flow_safely.json"

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	print("A2_2_PROBE_06_START")
	_write({"probe": "06_trigger_flow_safely", "last_marker": "start", "status": "running"})
	await process_frame
	var game_manager := root.get_node_or_null("GameManager")
	if game_manager and game_manager.has_method("reset_game"):
		game_manager.call("reset_game")
	var packed := ResourceLoader.load(OPENING_SCENE) as PackedScene
	if not packed:
		_write({"probe": "06_trigger_flow_safely", "last_marker": "packed_load_failed", "status": "fail"})
		quit(1)
		return
	var scene := packed.instantiate()
	root.add_child(scene)
	current_scene = scene
	for _i in range(5):
		await process_frame
	var player := scene.get_node_or_null("Player")
	_write({"probe": "06_trigger_flow_safely", "last_marker": "scene_ready", "status": "running", "player_exists": player != null})
	if not player or not scene.has_method("_on_signalfragment_interaction"):
		_write({"probe": "06_trigger_flow_safely", "last_marker": "missing_player_or_signal_handler", "status": "fail"})
		quit(1)
		return
	print("A2_2_PROBE_06_BEFORE_SIGNAL_INTERACTION")
	scene.call("_on_signalfragment_interaction", player)
	await process_frame
	var signal_flag := game_manager != null and game_manager.has_method("get_story_flag") and bool(game_manager.call("get_story_flag", "ch1_opening_hook_signal_found"))
	var pulse := scene.get_node_or_null("GlitchPulse")
	var pulse_armed := pulse != null and pulse.visible and pulse.monitoring
	_write({"probe": "06_trigger_flow_safely", "last_marker": "signal_flow_checked", "status": "running", "signal_flag": signal_flag, "pulse_armed": pulse_armed})
	print("A2_2_PROBE_06_BEFORE_COMPLETE_CALL")
	if scene.has_method("_complete_opening_hook"):
		scene.call("_complete_opening_hook")
	await process_frame
	var complete_flag := game_manager != null and game_manager.has_method("get_story_flag") and bool(game_manager.call("get_story_flag", "ch1_opening_hook_complete"))
	var passed := signal_flag and pulse_armed and complete_flag
	print("A2_2_PROBE_06_RESULT signal=%s pulse=%s complete=%s" % [str(signal_flag), str(pulse_armed), str(complete_flag)])
	_write({"probe": "06_trigger_flow_safely", "last_marker": "completion_flag_checked", "status": "pass" if passed else "fail", "signal_flag": signal_flag, "pulse_armed": pulse_armed, "complete_flag": complete_flag})
	quit(0 if passed else 1)

func _write(data: Dictionary) -> void:
	var file := FileAccess.open(OUT, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(data, "\t"))
		file.close()

