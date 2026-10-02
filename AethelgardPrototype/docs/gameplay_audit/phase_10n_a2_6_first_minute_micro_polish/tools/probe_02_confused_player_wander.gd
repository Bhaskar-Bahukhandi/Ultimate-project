extends SceneTree

const SCENE_PATH := "res://scenes/chapter1/opening_crash_site_hook.tscn"
const DIAG_DIR := "res://docs/gameplay_audit/phase_10n_a2_6_first_minute_micro_polish/diagnostics"
const DIAG_PATH := DIAG_DIR + "/probe_02_confused_player_wander.json"


func _initialize() -> void:
	_run()


func _run() -> void:
	print("A2_6_PROBE_02_START")
	var data := {
		"probe": "probe_02_confused_player_wander",
		"evidence_type": "CORRECTED HEADLESS RUNTIME EVIDENCE",
		"positions": {},
		"can_reach_signal": false,
		"pass": false,
		"errors": [],
	}
	_write_json(data)
	var scene := _instantiate_scene(data)
	if not scene:
		_write_json(data)
		quit(1)
		return
	await process_frame
	await physics_frame
	var player := scene.get_node_or_null("Player") as CharacterBody2D
	var signal_node := scene.get_node_or_null("SignalFragment") as Node2D
	if not player or not signal_node:
		data["errors"].append("player or signal missing")
		_write_json(data)
		quit(1)
		return
	data["positions"]["spawn"] = _v(player.global_position)
	await _hold_action("move_left", 85)
	data["positions"]["after_left_wander"] = _v(player.global_position)
	player.global_position = Vector2(250, 420)
	await physics_frame
	await _hold_action("move_up", 85)
	data["positions"]["after_up_wander"] = _v(player.global_position)
	player.global_position = Vector2(250, 420)
	await physics_frame
	await _hold_action("move_down", 85)
	data["positions"]["after_down_wander"] = _v(player.global_position)
	player.global_position = Vector2(250, 420)
	await physics_frame
	await _hold_action("move_right", 120)
	data["positions"]["after_signal_approach"] = _v(player.global_position)
	data["distance_to_signal"] = player.global_position.distance_to(signal_node.global_position)
	data["can_reach_signal"] = data["distance_to_signal"] <= 95.0
	if data["positions"]["after_left_wander"]["x"] < 145.0:
		data["errors"].append("left wander escaped west blocker")
	if data["positions"]["after_up_wander"]["y"] < 295.0:
		data["errors"].append("up wander escaped north blocker")
	if data["positions"]["after_down_wander"]["y"] > 555.0:
		data["errors"].append("down wander escaped south blocker")
	if not data["can_reach_signal"]:
		data["errors"].append("signal not reachable after route-boundary polish")
	data["pass"] = data["errors"].is_empty()
	scene.queue_free()
	_write_json(data)
	print("A2_6_PROBE_02_DONE")
	quit(0 if data["pass"] else 1)


func _instantiate_scene(data: Dictionary) -> Node:
	var packed := load(SCENE_PATH) as PackedScene
	if not packed:
		data["errors"].append("failed to load PackedScene")
		return null
	var scene := packed.instantiate()
	get_root().add_child(scene)
	return scene


func _hold_action(action: String, frames: int) -> void:
	var press := InputEventAction.new()
	press.action = action
	press.pressed = true
	Input.parse_input_event(press)
	for _i in range(frames):
		await physics_frame
	var release := InputEventAction.new()
	release.action = action
	release.pressed = false
	Input.parse_input_event(release)
	await physics_frame


func _v(value: Vector2) -> Dictionary:
	return {"x": snappedf(value.x, 0.001), "y": snappedf(value.y, 0.001)}


func _write_json(data: Dictionary) -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(DIAG_DIR))
	data["timestamp"] = Time.get_datetime_string_from_system()
	var file := FileAccess.open(DIAG_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(data, "\t"))
		file.close()
