extends SceneTree

const OUT := "res://docs/gameplay_audit/phase_10n_a2_opening_hook/a2_4_runtime_validation/diagnostics/probe_03_instantiate_opening_scene.json"
const SCENE_PATH := "res://scenes/chapter1/opening_crash_site_hook.tscn"

var result := {"phase":"10N-A2.4","probe":"probe_03_instantiate_opening_scene","evidence_type":"CORRECTED HEADLESS RUNTIME EVIDENCE","start_marker_printed":false,"status":"started","nodes":{}}

func _initialize() -> void:
	print("A2_4_PROBE_03_START")
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
	result["root_node_name"] = scene.name
	var player := _find(scene, "Player")
	var camera := _find(scene, "OpeningCamera")
	var objective := _find(scene, "ObjectiveLabel")
	var signal_node := _find(scene, "SignalFragment")
	var pulse := _find(scene, "GlitchPulse")
	var path := _find(scene, "OakhavenPath")
	result["nodes"] = {
		"player": player != null,
		"camera": camera != null,
		"objective_label": objective != null,
		"signal_fragment": signal_node != null,
		"glitch_pulse": pulse != null,
		"oakhaven_path": path != null,
		"hud": _find(scene, "OpeningHookHUD") != null
	}
	result["objective_text"] = objective.text if objective and objective is Label else ""
	var ok: bool = true
	for value in result["nodes"].values():
		ok = ok and bool(value)
	_finish(ok, "scene instantiated and runtime-created nodes inspected")

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
	print("A2_4_PROBE_03_DONE %s" % result["status"])
	quit(0 if ok else 1)

func _write() -> void:
	var file := FileAccess.open(OUT, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(result, "  "))
		file.close()


