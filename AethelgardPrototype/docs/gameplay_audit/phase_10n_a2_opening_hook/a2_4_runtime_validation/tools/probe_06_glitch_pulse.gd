extends SceneTree

const OUT := "res://docs/gameplay_audit/phase_10n_a2_opening_hook/a2_4_runtime_validation/diagnostics/probe_06_glitch_pulse.json"
const SCENE_PATH := "res://scenes/chapter1/opening_crash_site_hook.tscn"

var result := {"phase":"10N-A2.4","probe":"probe_06_glitch_pulse","evidence_type":"CORRECTED HEADLESS RUNTIME EVIDENCE","start_marker_printed":false,"status":"started"}

func _initialize() -> void:
	print("A2_4_PROBE_06_START")
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
	var pulse := _find(scene, "GlitchPulse")
	result["player_exists"] = player != null
	result["signal_exists"] = signal_node != null
	result["pulse_exists"] = pulse != null
	if player == null or signal_node == null or pulse == null:
		_finish(false, "Required node missing")
		return
	player.call("_interact_with", signal_node)
	await process_frame
	result["pulse_visible_after_signal"] = pulse.visible if pulse is CanvasItem else false
	result["pulse_monitoring_after_signal"] = pulse.monitoring if pulse is Area2D else false
	if pulse is Node2D and player is Node2D:
		player.global_position = pulse.global_position
	await physics_frame
	if scene.has_method("_on_glitch_pulse_body_entered"):
		scene.call("_on_glitch_pulse_body_entered", player)
		result["method_used"] = "scene._on_glitch_pulse_body_entered(Player)"
	await process_frame
	result["flag_danger_seen"] = _flag("ch1_opening_hook_danger_seen")
	_finish(result["pulse_visible_after_signal"] and result["flag_danger_seen"], "glitch pulse armed and danger handler invoked")

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
	print("A2_4_PROBE_06_DONE %s" % result["status"])
	quit(0 if ok else 1)

func _write() -> void:
	var file := FileAccess.open(OUT, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(result, "  "))
		file.close()
