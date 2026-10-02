extends SceneTree

const SCENE_PATH := "res://scenes/chapter1/opening_crash_site_hook.tscn"
const DIAG_DIR := "res://docs/gameplay_audit/phase_10n_a2_6_first_minute_micro_polish/diagnostics"
const DIAG_PATH := DIAG_DIR + "/probe_06_full_smoke_micro_polish.json"


func _initialize() -> void:
	_run()


func _run() -> void:
	print("A2_6_PROBE_06_START")
	var data := {
		"probe": "probe_06_full_smoke_micro_polish",
		"evidence_type": "CORRECTED HEADLESS RUNTIME EVIDENCE",
		"steps": {},
		"flags": {},
		"pass": false,
		"errors": [],
	}
	_write_json(data)
	_clear_opening_flags()
	var scene := _instantiate_scene(data)
	if not scene:
		_write_json(data)
		quit(1)
		return
	await process_frame
	await physics_frame
	var player := scene.get_node_or_null("Player") as CharacterBody2D
	var signal_node := scene.get_node_or_null("SignalFragment")
	var pulse := scene.get_node_or_null("GlitchPulse") as Area2D
	var path := scene.get_node_or_null("OakhavenPath")
	if not player or not signal_node or not pulse or not path:
		data["errors"].append("required opening node missing")
		_write_json(data)
		quit(1)
		return
	await _hold_action("move_left", 70)
	data["steps"]["west_blocked"] = player.global_position.x >= 145.0
	player.global_position = Vector2(250, 420)
	await physics_frame
	await _hold_action("move_right", 120)
	data["steps"]["approached_signal"] = player.global_position.distance_to(signal_node.global_position) <= 95.0
	if player.has_method("_interact_with"):
		player.call("_interact_with", signal_node)
	await process_frame
	data["steps"]["signal_interacted"] = _flag("ch1_opening_hook_signal_found")
	data["steps"]["pulse_armed"] = pulse.visible and pulse.monitoring
	player.global_position = pulse.global_position + Vector2(6, 0)
	if scene.has_method("_on_glitch_pulse_body_entered"):
		scene.call("_on_glitch_pulse_body_entered", player)
	await process_frame
	data["steps"]["pulse_feedback"] = scene.get("_last_pulse_feedback_triggered") == true
	data["steps"]["danger_flag"] = _flag("ch1_opening_hook_danger_seen")
	if scene.has_method("_on_oakhaven_path_body_entered"):
		scene.call("_on_oakhaven_path_body_entered", player)
	await process_frame
	for flag in ["ch1_opening_hook_signal_found", "ch1_opening_hook_danger_seen", "ch1_opening_hook_complete", "plane_crash_completed", "ch1_awakening_complete", "ch1_glitch_crater_complete"]:
		data["flags"][flag] = _flag(flag)
	for key in data["steps"].keys():
		if not data["steps"][key]:
			data["errors"].append("smoke step failed: %s" % key)
	for flag in data["flags"].keys():
		if not data["flags"][flag]:
			data["errors"].append("expected flag missing: %s" % flag)
	data["pass"] = data["errors"].is_empty()
	scene.queue_free()
	_write_json(data)
	print("A2_6_PROBE_06_DONE")
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


func _flag(flag_name: String) -> bool:
	var gm := get_root().get_node_or_null("GameManager")
	return gm != null and gm.call("get_story_flag", flag_name)


func _clear_opening_flags() -> void:
	var gm := get_root().get_node_or_null("GameManager")
	if not gm:
		return
	for flag in ["ch1_opening_hook_signal_found", "ch1_opening_hook_danger_seen", "ch1_opening_hook_complete", "plane_crash_completed", "ch1_awakening_complete", "ch1_glitch_crater_complete"]:
		gm.call("set_story_flag", flag, false)


func _write_json(data: Dictionary) -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(DIAG_DIR))
	data["timestamp"] = Time.get_datetime_string_from_system()
	var file := FileAccess.open(DIAG_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(data, "\t"))
		file.close()
