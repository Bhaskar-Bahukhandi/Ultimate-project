extends SceneTree

const OUT := "res://docs/gameplay_audit/phase_10n_a2_opening_hook/a2_4_runtime_validation/diagnostics/probe_05_signal_interaction.json"
const SCENE_PATH := "res://scenes/chapter1/opening_crash_site_hook.tscn"

var result := {"phase":"10N-A2.4","probe":"probe_05_signal_interaction","evidence_type":"CORRECTED HEADLESS RUNTIME EVIDENCE","start_marker_printed":false,"status":"started"}

func _initialize() -> void:
	print("A2_4_PROBE_05_START")
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
	await physics_frame
	var player := _find(scene, "Player")
	var signal_node := _find(scene, "SignalFragment")
	result["player_exists"] = player != null
	result["signal_exists"] = signal_node != null
	result["signal_in_interactable_group"] = signal_node != null and signal_node.is_in_group("interactable")
	result["scene_handler_exists"] = scene.has_method("_on_signalfragment_interaction")
	if player == null or signal_node == null:
		_finish(false, "Player or SignalFragment missing")
		return
	if player is Node2D and signal_node is Node2D:
		player.global_position = signal_node.global_position
		await physics_frame
	result["player_has_interact_method"] = player.has_method("_interact_with")
	if player.has_method("_interact_with"):
		player.call("_interact_with", signal_node)
		result["method_used"] = "Player._interact_with(SignalFragment)"
	else:
		scene.call("_on_signalfragment_interaction", player)
		result["method_used"] = "scene._on_signalfragment_interaction(Player) fallback"
	await process_frame
	result["flag_signal_found"] = _flag("ch1_opening_hook_signal_found")
	var objective := _find(scene, "ObjectiveLabel")
	result["objective_text"] = objective.text if objective and objective is Label else ""
	var pulse := _find(scene, "GlitchPulse")
	result["pulse_visible_after_signal"] = pulse.visible if pulse and pulse is CanvasItem else false
	result["pulse_monitoring_after_signal"] = pulse.monitoring if pulse and pulse is Area2D else false
	_finish(result["flag_signal_found"] and result["pulse_visible_after_signal"], "signal interaction path invoked")

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
	print("A2_4_PROBE_05_DONE %s" % result["status"])
	quit(0 if ok else 1)

func _write() -> void:
	var file := FileAccess.open(OUT, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(result, "  "))
		file.close()

