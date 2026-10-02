extends SceneTree

const SCENE_PATH := "res://scenes/chapter1/opening_crash_site_hook.tscn"
const DIAG_DIR := "res://docs/gameplay_audit/phase_10n_a2_6_first_minute_micro_polish/diagnostics"
const DIAG_PATH := DIAG_DIR + "/probe_03_signal_prompt_readability.json"


func _initialize() -> void:
	_run()


func _run() -> void:
	print("A2_6_PROBE_03_START")
	var data := {
		"probe": "probe_03_signal_prompt_readability",
		"evidence_type": "CORRECTED HEADLESS RUNTIME EVIDENCE",
		"input_actions": {},
		"prompt_text": "",
		"signal_flag_after_interaction": false,
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
	if not player or not signal_node:
		data["errors"].append("player or signal missing")
		_write_json(data)
		quit(1)
		return
	data["input_actions"] = {
		"interact": InputMap.has_action("interact"),
		"root_access": InputMap.has_action("root_access"),
	}
	data["signal_meta_prompt"] = str(signal_node.get_meta("opening_prompt_text", ""))
	var prompt := player.get_node_or_null("InteractionPrompt") as Label
	if prompt:
		player.set("nearby_interactable", signal_node)
		prompt.visible = true
		if scene.has_method("_sync_opening_interaction_prompt"):
			scene.call("_sync_opening_interaction_prompt")
		data["prompt_text"] = prompt.text
	if player.has_method("_interact_with"):
		player.call("_interact_with", signal_node)
	await process_frame
	var gm := get_root().get_node_or_null("GameManager")
	data["signal_flag_after_interaction"] = gm != null and gm.call("get_story_flag", "ch1_opening_hook_signal_found")
	if not data["input_actions"]["interact"] or not data["input_actions"]["root_access"]:
		data["errors"].append("F/E actions are not both present in InputMap")
	if data["signal_meta_prompt"] != "[F/E] Interact":
		data["errors"].append("SignalFragment prompt metadata is contradictory")
	if data["prompt_text"] != "[F/E] Interact":
		data["errors"].append("player prompt was not opening-overridden to [F/E] Interact")
	if not data["signal_flag_after_interaction"]:
		data["errors"].append("signal interaction did not set ch1_opening_hook_signal_found")
	data["pass"] = data["errors"].is_empty()
	scene.queue_free()
	_write_json(data)
	print("A2_6_PROBE_03_DONE")
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
