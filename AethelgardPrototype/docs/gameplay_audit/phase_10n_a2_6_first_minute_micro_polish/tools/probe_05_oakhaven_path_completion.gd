extends SceneTree

const SCENE_PATH := "res://scenes/chapter1/opening_crash_site_hook.tscn"
const DIAG_DIR := "res://docs/gameplay_audit/phase_10n_a2_6_first_minute_micro_polish/diagnostics"
const DIAG_PATH := DIAG_DIR + "/probe_05_oakhaven_path_completion.json"


func _initialize() -> void:
	_run()


func _run() -> void:
	print("A2_6_PROBE_05_START")
	var data := {
		"probe": "probe_05_oakhaven_path_completion",
		"evidence_type": "CORRECTED HEADLESS RUNTIME EVIDENCE",
		"pre_completion_flags": {},
		"post_completion_flags": {},
		"path_prompt": "",
		"legacy_route_preserved": false,
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
	var player := scene.get_node_or_null("Player")
	var signal_node := scene.get_node_or_null("SignalFragment")
	var path := scene.get_node_or_null("OakhavenPath")
	if not player or not signal_node or not path:
		data["errors"].append("player, signal, or OakhavenPath missing")
		_write_json(data)
		quit(1)
		return
	var gm := get_root().get_node_or_null("GameManager")
	var flags := ["ch1_opening_hook_complete", "plane_crash_completed", "ch1_awakening_complete", "ch1_glitch_crater_complete"]
	for flag in flags:
		data["pre_completion_flags"][flag] = gm != null and gm.call("get_story_flag", flag)
	data["path_prompt"] = str(path.get_meta("opening_prompt_text", ""))
	if player.has_method("_interact_with"):
		player.call("_interact_with", signal_node)
	await process_frame
	if scene.has_method("_on_oakhaven_path_body_entered"):
		scene.call("_on_oakhaven_path_body_entered", player)
	await process_frame
	for flag in flags:
		data["post_completion_flags"][flag] = gm != null and gm.call("get_story_flag", flag)
	var main_menu_script := load("res://scripts/main_menu.gd") as Script
	data["legacy_route_preserved"] = main_menu_script != null and "res://scenes/prologue/flight_707.tscn" in main_menu_script.source_code
	for flag in flags:
		if data["pre_completion_flags"][flag]:
			data["errors"].append("compatibility flag set before completion: %s" % flag)
		if not data["post_completion_flags"][flag]:
			data["errors"].append("completion did not set flag: %s" % flag)
	if data["path_prompt"] != "[F/E] Follow signal":
		data["errors"].append("OakhavenPath prompt metadata is not clear")
	if not data["legacy_route_preserved"]:
		data["errors"].append("legacy prologue route not detected")
	data["pass"] = data["errors"].is_empty()
	scene.queue_free()
	_write_json(data)
	print("A2_6_PROBE_05_DONE")
	quit(0 if data["pass"] else 1)


func _instantiate_scene(data: Dictionary) -> Node:
	var packed := load(SCENE_PATH) as PackedScene
	if not packed:
		data["errors"].append("failed to load PackedScene")
		return null
	var scene := packed.instantiate()
	get_root().add_child(scene)
	return scene


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
