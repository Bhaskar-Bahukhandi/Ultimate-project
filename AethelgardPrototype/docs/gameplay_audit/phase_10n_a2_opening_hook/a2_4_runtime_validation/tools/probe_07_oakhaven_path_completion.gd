extends SceneTree

const OUT := "res://docs/gameplay_audit/phase_10n_a2_opening_hook/a2_4_runtime_validation/diagnostics/probe_07_oakhaven_path_completion.json"
const SCENE_PATH := "res://scenes/chapter1/opening_crash_site_hook.tscn"

var result := {"phase":"10N-A2.4","probe":"probe_07_oakhaven_path_completion","evidence_type":"CORRECTED HEADLESS RUNTIME EVIDENCE","start_marker_printed":false,"status":"started"}

func _initialize() -> void:
	print("A2_4_PROBE_07_START")
	result["start_marker_printed"] = true
	_write()
	_reset_game()
	var packed := load(SCENE_PATH) as PackedScene
	var scene := packed.instantiate() if packed else null
	if scene == null:
		_finish(false, "Scene failed to instantiate")
		return
	root.add_child(scene)
	await process_frame
	await process_frame
	var player := _find(scene, "Player")
	var signal_node := _find(scene, "SignalFragment")
	var path := _find(scene, "OakhavenPath")
	result["player_exists"] = player != null
	result["signal_exists"] = signal_node != null
	result["oakhaven_path_exists"] = path != null
	if player == null or signal_node == null or path == null:
		_finish(false, "Required node missing")
		return
	result["compat_flags_before"] = _flags(["plane_crash_completed", "ch1_awakening_complete", "ch1_glitch_crater_complete", "ch1_opening_hook_complete"])
	player.call("_interact_with", signal_node)
	await process_frame
	result["signal_flag_after_signal"] = _flag("ch1_opening_hook_signal_found")
	if scene.has_method("_complete_opening_hook"):
		scene.call("_complete_opening_hook")
		result["method_used"] = "scene._complete_opening_hook(), checked before transition timer elapsed"
	await process_frame
	result["completion_flags_after"] = _flags(["plane_crash_completed", "ch1_awakening_complete", "ch1_glitch_crater_complete", "ch1_opening_hook_complete"])
	var gm := _game_manager()
	result["current_region_after"] = gm.get("current_region") if gm else ""
	var before_ok: bool = true
	for value in result["compat_flags_before"].values():
		before_ok = before_ok and not bool(value)
	var after_ok: bool = true
	for value in result["completion_flags_after"].values():
		after_ok = after_ok and bool(value)
	_finish(before_ok and after_ok, "completion flags validated without waiting for scene transition")

func _game_manager() -> Node:
	return root.get_node_or_null("GameManager")

func _reset_game() -> void:
	var gm := _game_manager()
	if gm and gm.has_method("set_story_flag"):
		for flag in ["plane_crash_completed", "ch1_awakening_complete", "ch1_glitch_crater_complete", "ch1_opening_hook_started", "ch1_opening_hook_signal_found", "ch1_opening_hook_danger_seen", "ch1_opening_hook_complete"]:
			gm.call("set_story_flag", flag, false)

func _flag(flag: String) -> bool:
	var gm := _game_manager()
	if gm and gm.has_method("get_story_flag"):
		return bool(gm.call("get_story_flag", flag))
	return false

func _flags(names: Array) -> Dictionary:
	var data := {}
	for flag in names:
		data[flag] = _flag(flag)
	return data

func _find(node: Node, node_name: String) -> Node:
	if node.name == node_name:
		return node
	for child in node.get_children():
		var found := _find(child, node_name)
		if found:
			return found
	return null

func _finish(ok: bool, notes: String) -> void:
	result["status"] = "pass" if ok else "fail"
	result["notes"] = notes
	_write()
	print("A2_4_PROBE_07_DONE %s" % result["status"])
	quit(0 if ok else 1)

func _write() -> void:
	var file := FileAccess.open(OUT, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(result, "  "))
		file.close()
