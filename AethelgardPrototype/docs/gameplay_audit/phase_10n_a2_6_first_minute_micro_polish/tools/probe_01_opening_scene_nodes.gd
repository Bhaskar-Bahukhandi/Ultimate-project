extends SceneTree

const SCENE_PATH := "res://scenes/chapter1/opening_crash_site_hook.tscn"
const DIAG_DIR := "res://docs/gameplay_audit/phase_10n_a2_6_first_minute_micro_polish/diagnostics"
const DIAG_PATH := DIAG_DIR + "/probe_01_opening_scene_nodes.json"


func _initialize() -> void:
	_run()


func _run() -> void:
	print("A2_6_PROBE_01_START")
	var data := {
		"probe": "probe_01_opening_scene_nodes",
		"evidence_type": "CORRECTED HEADLESS RUNTIME EVIDENCE",
		"scene_path": SCENE_PATH,
		"nodes": {},
		"boundary_nodes": [],
		"breadcrumb_hidden_during_hook": false,
		"pass": false,
		"errors": [],
	}
	_write_json(data)
	var scene := _instantiate_scene(data)
	if not scene:
		_write_json(data)
		quit(1)
		return
	await process_frame
	await physics_frame
	var player := scene.get_node_or_null("Player")
	var hud := scene.get_node_or_null("OpeningHookHUD")
	var signal_node := scene.get_node_or_null("SignalFragment")
	var pulse := scene.get_node_or_null("GlitchPulse")
	var path := scene.get_node_or_null("OakhavenPath")
	var boundaries := _collect_children_with_prefix(scene, "OpeningBoundary")
	data["nodes"] = {
		"player": player != null,
		"camera": player != null and player.get_node_or_null("OpeningCamera") != null,
		"hud": hud != null,
		"objective_label": hud != null and hud.find_child("ObjectiveLabel", true, false) != null,
		"prompt_label": hud != null and hud.find_child("PromptLabel", true, false) != null,
		"signal_fragment": signal_node != null,
		"signal_glow": signal_node != null and signal_node.get_node_or_null("SignalReadabilityGlow") != null,
		"glitch_pulse": pulse != null,
		"pulse_flash": hud != null and hud.find_child("GlitchPulseFeedbackFlash", true, false) != null,
		"oakhaven_path": path != null,
		"oakhaven_direction_label": scene.get_node_or_null("OakhavenPathDirectionLabel") != null,
	}
	data["boundary_nodes"] = boundaries
	var breadcrumb := get_root().get_node_or_null("ProgressionBreadcrumb")
	data["breadcrumb_hidden_during_hook"] = breadcrumb != null and breadcrumb.get("_visible") == false
	for key in data["nodes"].keys():
		if not data["nodes"][key]:
			data["errors"].append("missing runtime node: %s" % key)
	if boundaries.size() < 5:
		data["errors"].append("expected opening boundary nodes")
	if not data["breadcrumb_hidden_during_hook"]:
		data["errors"].append("global breadcrumb was not hidden during opening hook")
	data["pass"] = data["errors"].is_empty()
	scene.queue_free()
	_write_json(data)
	print("A2_6_PROBE_01_DONE")
	quit(0 if data["pass"] else 1)


func _instantiate_scene(data: Dictionary) -> Node:
	var packed := load(SCENE_PATH) as PackedScene
	if not packed:
		data["errors"].append("failed to load PackedScene")
		return null
	var scene := packed.instantiate()
	get_root().add_child(scene)
	return scene


func _collect_children_with_prefix(node: Node, prefix: String) -> Array:
	var found := []
	for child in node.get_children():
		if child.name.begins_with(prefix):
			found.append(child.name)
	return found


func _write_json(data: Dictionary) -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(DIAG_DIR))
	data["timestamp"] = Time.get_datetime_string_from_system()
	var file := FileAccess.open(DIAG_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(data, "\t"))
		file.close()
