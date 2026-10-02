extends SceneTree

const SCENE_PATH := "res://scenes/chapter1/opening_crash_site_hook.tscn"
const MENU_PATH := "res://scenes/main_menu.tscn"
const DIAG_DIR := "res://docs/gameplay_audit/phase_10n_a2_8_headed_first_minute_fix/diagnostics"
const PROBE_NAME := "probe_06_full_smoke_after_fix"
const DIAG_PATH := DIAG_DIR + "/" + PROBE_NAME + ".json"

func _initialize() -> void:
	_run()

func _base_data() -> Dictionary:
	return {"probe": PROBE_NAME, "evidence_type": "CORRECTED HEADLESS RUNTIME EVIDENCE", "checks": {}, "errors": [], "pass": false}

func _instantiate_scene(path: String, data: Dictionary) -> Node:
	var packed := load(path) as PackedScene
	if not packed:
		data["errors"].append("failed to load PackedScene: %s" % path)
		return null
	var scene := packed.instantiate()
	get_root().add_child(scene)
	return scene

func _flag(flag_name: String) -> bool:
	var gm := get_root().get_node_or_null("GameManager")
	return gm != null and gm.call("get_story_flag", flag_name)

func _set_flag(flag_name: String, value: bool) -> void:
	var gm := get_root().get_node_or_null("GameManager")
	if gm:
		gm.call("set_story_flag", flag_name, value)

func _clear_opening_flags() -> void:
	for flag in ["ch1_opening_hook_started", "ch1_opening_hook_signal_found", "ch1_opening_hook_danger_seen", "ch1_opening_hook_complete", "plane_crash_completed", "ch1_awakening_complete", "ch1_glitch_crater_complete"]:
		_set_flag(flag, false)

func _write_json(data: Dictionary) -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(DIAG_DIR))
	data["timestamp"] = Time.get_datetime_string_from_system()
	var file := FileAccess.open(DIAG_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(data, "\t"))
		file.close()

func _finish(data: Dictionary, scene: Node = null) -> void:
	if scene and is_instance_valid(scene):
		scene.queue_free()
	_write_json(data)
	print("A2_8_%s_DONE" % PROBE_NAME)
	quit(0 if data["pass"] else 1)

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

func _press_scene_action(scene: Node, action: String) -> void:
	var event := InputEventAction.new()
	event.action = action
	event.pressed = true
	scene.call("_input", event)

func _run() -> void:
	print("A2_8_PROBE_06_START")
	var data := _base_data()
	_clear_opening_flags()
	var scene := _instantiate_scene(SCENE_PATH, data)
	if not scene:
		_finish(data)
		return
	await process_frame
	await physics_frame
	var player := scene.get_node_or_null("Player") as CharacterBody2D
	await _hold_action("move_right", 120)
	data["checks"]["moved_toward_signal"] = player.global_position.x > 330.0
	player.global_position = scene.get("SIGNAL_POS") + Vector2(-125, 0)
	await process_frame
	_press_scene_action(scene, "interact")
	await process_frame
	data["checks"]["signal_flag"] = _flag("ch1_opening_hook_signal_found")
	player.global_position = scene.get("PULSE_POS") + Vector2(-8, 0)
	await process_frame
	await process_frame
	data["checks"]["pulse_flag"] = _flag("ch1_opening_hook_danger_seen")
	player.global_position = scene.get("EXIT_POS") + Vector2(-70, 0)
	_press_scene_action(scene, "root_access")
	await process_frame
	data["checks"]["complete_flag"] = _flag("ch1_opening_hook_complete")
	data["checks"]["compat_flags"] = _flag("plane_crash_completed") and _flag("ch1_awakening_complete") and _flag("ch1_glitch_crater_complete")
	data["pass"] = not data["checks"].values().has(false)
	if not data["pass"]:
		data["errors"].append("full first-minute smoke failed")
	_finish(data, scene)
