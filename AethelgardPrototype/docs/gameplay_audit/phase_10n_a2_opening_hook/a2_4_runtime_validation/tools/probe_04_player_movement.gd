extends SceneTree

const OUT := "res://docs/gameplay_audit/phase_10n_a2_opening_hook/a2_4_runtime_validation/diagnostics/probe_04_player_movement.json"
const SCENE_PATH := "res://scenes/chapter1/opening_crash_site_hook.tscn"

var result := {"phase":"10N-A2.4","probe":"probe_04_player_movement","evidence_type":"CORRECTED HEADLESS RUNTIME EVIDENCE","start_marker_printed":false,"status":"started"}

func _initialize() -> void:
	print("A2_4_PROBE_04_START")
	result["start_marker_printed"] = true
	_write()
	var packed := load(SCENE_PATH) as PackedScene
	if packed == null:
		_finish(false, "PackedScene failed to load")
		return
	var scene := packed.instantiate()
	root.add_child(scene)
	await process_frame
	await process_frame
	await physics_frame
	var player := _find(scene, "Player") as CharacterBody2D
	result["player_exists"] = player != null
	result["move_right_action_exists"] = InputMap.has_action("move_right")
	if player == null:
		_finish(false, "Player node missing")
		return
	var initial := player.global_position
	Input.action_press("move_right")
	for i in range(12):
		await physics_frame
	Input.action_release("move_right")
	await physics_frame
	var final := player.global_position
	result["initial_position"] = _v2(initial)
	result["final_position"] = _v2(final)
	result["delta"] = _v2(final - initial)
	result["movement_changed_position"] = final.distance_to(initial) > 1.0
	var camera := _find(scene, "OpeningCamera") as Camera2D
	result["camera_exists"] = camera != null
	result["camera_current"] = camera.is_current() if camera else false
	_finish(result["movement_changed_position"] and result["camera_exists"], "movement input simulated with Input.action_press('move_right')")

func _find(node: Node, node_name: String) -> Node:
	if node.name == node_name:
		return node
	for child in node.get_children():
		var found := _find(child, node_name)
		if found:
			return found
	return null

func _v2(v: Vector2) -> String:
	return "(%.3f, %.3f)" % [v.x, v.y]

func _finish(ok: bool, notes: String) -> void:
	result["status"] = "pass" if ok else "fail"
	result["notes"] = notes
	_write()
	print("A2_4_PROBE_04_DONE %s" % result["status"])
	quit(0 if ok else 1)

func _write() -> void:
	var file := FileAccess.open(OUT, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(result, "  "))
		file.close()


