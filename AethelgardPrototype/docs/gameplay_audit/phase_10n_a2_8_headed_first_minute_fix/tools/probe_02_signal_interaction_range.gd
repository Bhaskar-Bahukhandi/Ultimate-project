extends SceneTree

const SCENE_PATH := "res://scenes/chapter1/opening_crash_site_hook.tscn"
const MENU_PATH := "res://scenes/main_menu.tscn"
const DIAG_DIR := "res://docs/gameplay_audit/phase_10n_a2_8_headed_first_minute_fix/diagnostics"
const PROBE_NAME := "probe_02_signal_interaction_range"
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

func _press_scene_action(scene: Node, action: String) -> void:
	var event := InputEventAction.new()
	event.action = action
	event.pressed = true
	if scene.has_method("_input"):
		scene.call("_input", event)


func _wait_for_prompt(scene: Node, player: Node) -> bool:
	for _i in range(8):
		if scene.has_method("_sync_opening_interaction_prompt"):
			scene.call("_sync_opening_interaction_prompt")
		if scene.has_method("_sync_world_prompt_visibility"):
			scene.call("_sync_world_prompt_visibility")
		await process_frame
		var prompt := player.get_node_or_null("InteractionPrompt") as Label if player else null
		if prompt != null and prompt.visible and prompt.text.find("F/E") >= 0:
			return true
	return false

func _run() -> void:
	print("A2_8_PROBE_02_START")
	var data := _base_data()
	for action in ["interact", "root_access"]:
		_clear_opening_flags()
		var scene := _instantiate_scene(SCENE_PATH, data)
		if not scene:
			_finish(data)
			return
		await process_frame
		await physics_frame
		var player := scene.get_node_or_null("Player") as CharacterBody2D
		player.global_position = scene.get("SIGNAL_POS") + Vector2(-135, 0)
		var prompt_visible := await _wait_for_prompt(scene, player)
		_press_scene_action(scene, action)
		await process_frame
		var flag_set := _flag("ch1_opening_hook_signal_found")
		data["checks"][action + "_near_prompt_visible"] = prompt_visible
		data["checks"][action + "_near_sets_flag"] = flag_set
		scene.queue_free()
		await process_frame
	_clear_opening_flags()
	var far_scene := _instantiate_scene(SCENE_PATH, data)
	await process_frame
	var far_player := far_scene.get_node_or_null("Player") as CharacterBody2D
	far_player.global_position = far_scene.get("SIGNAL_POS") + Vector2(-190, 0)
	if far_scene.has_method("_sync_opening_interaction_prompt"):
		far_scene.call("_sync_opening_interaction_prompt")
	if far_scene.has_method("_sync_world_prompt_visibility"):
		far_scene.call("_sync_world_prompt_visibility")
	await process_frame
	var far_prompt := far_player.get_node_or_null("InteractionPrompt") as Label if far_player else null
	var far_prompt_hidden := far_prompt == null or not far_prompt.visible
	_press_scene_action(far_scene, "interact")
	await process_frame
	data["checks"]["far_prompt_hidden"] = far_prompt_hidden
	data["checks"]["far_does_not_set_flag"] = not _flag("ch1_opening_hook_signal_found")
	data["pass"] = not data["checks"].values().has(false)
	if not data["pass"]:
		data["errors"].append("signal range/prompt/action mismatch")
	_finish(data, far_scene)
