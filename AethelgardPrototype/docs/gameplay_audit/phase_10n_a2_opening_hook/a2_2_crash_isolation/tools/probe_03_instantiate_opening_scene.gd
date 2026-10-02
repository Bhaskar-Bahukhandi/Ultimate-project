extends SceneTree

const OPENING_SCENE := "res://scenes/chapter1/opening_crash_site_hook.tscn"
const OUT := "res://docs/gameplay_audit/phase_10n_a2_opening_hook/a2_2_crash_isolation/diagnostics/probe_03_instantiate_opening_scene.json"

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	print("A2_2_PROBE_03_START")
	_write({"probe": "03_instantiate_opening_scene", "last_marker": "start", "status": "running"})
	await process_frame
	var packed := ResourceLoader.load(OPENING_SCENE) as PackedScene
	_write({"probe": "03_instantiate_opening_scene", "last_marker": "packed_loaded", "status": "running", "loaded": packed != null})
	if not packed:
		quit(1)
		return
	print("A2_2_PROBE_03_BEFORE_INSTANTIATE")
	var scene := packed.instantiate()
	_write({"probe": "03_instantiate_opening_scene", "last_marker": "instantiated_not_added", "status": "running", "scene_name": scene.name})
	print("A2_2_PROBE_03_BEFORE_ADD_CHILD")
	root.add_child(scene)
	current_scene = scene
	for _i in range(5):
		await process_frame
	var node_status := {
		"scene_name": scene.name,
		"player": scene.get_node_or_null("Player") != null,
		"signal_fragment": scene.get_node_or_null("SignalFragment") != null,
		"glitch_pulse": scene.get_node_or_null("GlitchPulse") != null,
		"oakhaven_path": scene.get_node_or_null("OakhavenPath") != null
	}
	print("A2_2_PROBE_03_NODES %s" % JSON.stringify(node_status))
	_write({"probe": "03_instantiate_opening_scene", "last_marker": "node_check_complete", "status": "pass", "nodes": node_status})
	quit(0)

func _write(data: Dictionary) -> void:
	var file := FileAccess.open(OUT, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(data, "\t"))
		file.close()

