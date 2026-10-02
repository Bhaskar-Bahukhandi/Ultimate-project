extends SceneTree

const OUT := "res://docs/gameplay_audit/phase_10n_a2_opening_hook/a2_4_runtime_validation/diagnostics/probe_08_full_first_minute_smoke.json"
const SCENE_PATH := "res://scenes/chapter1/opening_crash_site_hook.tscn"

var result := {"phase":"10N-A2.4","probe":"probe_08_full_first_minute_smoke","evidence_type":"CORRECTED HEADLESS RUNTIME EVIDENCE","start_marker_printed":false,"status":"started","steps":[]}

func _initialize() -> void:
	print("A2_4_PROBE_08_START")
	result["start_marker_printed"] = true
	_write()
	_reset_game()
	var start_ticks := Time.get_ticks_msec()
	var packed := load(SCENE_PATH) as PackedScene
	var scene := packed.instantiate() if packed else null
	if scene == null:
		_finish(false, "Scene failed to instantiate")
		return
	root.add_child(scene)
	await process_frame
	await process_frame
	await physics_frame
	var player := _find(scene, "Player")
	var signal_node := _find(scene, "SignalFragment")
	var pulse := _find(scene, "GlitchPulse")
	var path := _find(scene, "OakhavenPath")
	if player == null or signal_node == null or pulse == null or path == null:
		_finish(false, "Required node missing in smoke path")
		return
	var initial: Vector2 = (player as Node2D).global_position
	Input.action_press("move_right")
	for i in range(8):
		await physics_frame
	Input.action_release("move_right")
	var moved: bool = (player as Node2D).global_position.distance_to(initial) > 1.0
	result["steps"].append({"step":"movement", "pass":moved})
	player.call("_interact_with", signal_node)
	await process_frame
	var signal_ok: bool = _flag("ch1_opening_hook_signal_found")
	result["steps"].append({"step":"signal_interaction", "pass":signal_ok})
	scene.call("_on_glitch_pulse_body_entered", player)
	await process_frame
	var danger_ok: bool = _flag("ch1_opening_hook_danger_seen")
	result["steps"].append({"step":"glitch_pulse", "pass":danger_ok})
	scene.call("_complete_opening_hook")
	await process_frame
	var complete_ok: bool = _flag("ch1_opening_hook_complete") and _flag("plane_crash_completed") and _flag("ch1_awakening_complete") and _flag("ch1_glitch_crater_complete")
	result["steps"].append({"step":"completion_flags", "pass":complete_ok})
	result["elapsed_ms"] = Time.get_ticks_msec() - start_ticks
	_finish(moved and signal_ok and danger_ok and complete_ok, "automated smoke path ran without waiting for transition")

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
	print("A2_4_PROBE_08_DONE %s" % result["status"])
	quit(0 if ok else 1)

func _write() -> void:
	var file := FileAccess.open(OUT, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(result, "  "))
		file.close()

