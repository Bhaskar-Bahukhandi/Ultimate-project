extends SceneTree

const SCENE_PATH := "res://scenes/chapter1/opening_crash_site_hook.tscn"
const MENU_PATH := "res://scenes/main_menu.tscn"
const DIAG_DIR := "res://docs/gameplay_audit/phase_10n_a2_8_headed_first_minute_fix/diagnostics"
const PROBE_NAME := "probe_01_menu_public_surface"
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
	print("A2_8_PROBE_01_START")
	var data := _base_data()
	var scene := _instantiate_scene(MENU_PATH, data)
	if not scene:
		_finish(data)
		return
	await process_frame
	await process_frame
	var vbox := scene.get_node_or_null("VBoxContainer")
	data["checks"]["vbox_exists"] = vbox != null
	var hidden_ok := true
	if vbox:
		for button_name in ["SkipPrologueButton", "ChapterSelectButton", "CompletionButton", "LegacyPrologueButton"]:
			var button := vbox.get_node_or_null(button_name) as Button
			var ok := button == null or (not button.visible and button.disabled and button.focus_mode == Control.FOCUS_NONE)
			data["checks"][button_name + "_hidden_or_absent"] = ok
			hidden_ok = hidden_ok and ok
		for button_name in ["NewGameButton", "LoadGameButton", "OptionsButton", "CreditsButton", "QuitButton"]:
			var button := vbox.get_node_or_null(button_name) as Button
			data["checks"][button_name + "_visible"] = button != null and button.visible and not button.disabled
	data["checks"]["legacy_route_callable"] = scene.has_method("_start_legacy_cinematic_prologue") and ResourceLoader.exists("res://scenes/prologue/flight_707.tscn")
	data["pass"] = hidden_ok and data["checks"].get("legacy_route_callable", false)
	if not data["pass"]:
		data["errors"].append("public menu surface still exposes dev route or legacy route missing")
	_finish(data, scene)
