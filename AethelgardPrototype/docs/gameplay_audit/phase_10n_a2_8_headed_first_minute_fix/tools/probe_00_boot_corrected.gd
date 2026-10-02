extends SceneTree

const SCENE_PATH := "res://scenes/chapter1/opening_crash_site_hook.tscn"
const MENU_PATH := "res://scenes/main_menu.tscn"
const DIAG_DIR := "res://docs/gameplay_audit/phase_10n_a2_8_headed_first_minute_fix/diagnostics"
const PROBE_NAME := "probe_00_boot_corrected"
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

func _run() -> void:
	print("A2_8_PROBE_00_START")
	var data := _base_data()
	for name in ["GameManager", "SceneTransitions", "AssetManager", "ProgressionBreadcrumb"]:
		data["checks"][name] = get_root().get_node_or_null(name) != null
	data["pass"] = not data["checks"].values().has(false)
	if not data["pass"]:
		data["errors"].append("missing expected autoload")
	_finish(data)
