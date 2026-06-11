extends SceneTree

const OAKHAVEN_SCENE := "res://scenes/regions/oakhaven_region.tscn"
const MANIFEST_DIR := "res://assets/art_sources/comfyui_tests/oakhaven_p11_import_preview/manifest"
const MANIFEST_PATH := "res://assets/art_sources/comfyui_tests/oakhaven_p11_import_preview/manifest/oakhaven_p11_actual_scene_probe.json"

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(MANIFEST_DIR))
	var asset_manager = get_root().get_node_or_null("AssetManager")
	if asset_manager and asset_manager.has_method("set_oakhaven_force_generated_fallback"):
		asset_manager.set_oakhaven_force_generated_fallback(false)

	var packed_scene := load(OAKHAVEN_SCENE) as PackedScene
	if not packed_scene:
		push_error("P11 actual scene probe could not load Oakhaven scene.")
		quit(1)
		return
	var scene := packed_scene.instantiate()
	get_root().add_child(scene)
	current_scene = scene
	for _frame_index in range(8):
		await process_frame

	var visual_layer := _find_node_by_name(scene, "V2OakhavenGroundTiles")
	var visual_found := visual_layer != null
	var visual_production := false
	var visual_path := ""
	var visual_time_state := ""
	if visual_layer:
		visual_production = bool(visual_layer.get_meta("visual_tileset_production", false))
		visual_path = str(visual_layer.get_meta("visual_tileset_path", ""))
		visual_time_state = str(visual_layer.get_meta("oakhaven_time_state", ""))

	var ok := visual_found and visual_production and visual_time_state == "afternoon"
	var data := {
		"phase": "10M-P11",
		"scene": OAKHAVEN_SCENE,
		"visual_layer_found": visual_found,
		"visual_tileset_production": visual_production,
		"visual_tileset_path": visual_path,
		"oakhaven_time_state": visual_time_state,
		"collision_modified": false,
		"gameplay_scene_file_modified": false,
		"result": "Pass" if ok else "Fail",
	}
	var file := FileAccess.open(ProjectSettings.globalize_path(MANIFEST_PATH), FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(data, "\t"))
	if not ok:
		push_error("P11 actual scene probe failed: %s" % data)
		quit(1)
		return
	print("P11 actual Oakhaven scene probe: PASS")
	quit(0)

func _find_node_by_name(root: Node, node_name: String) -> Node:
	if root.name == node_name:
		return root
	for child in root.get_children():
		var found := _find_node_by_name(child, node_name)
		if found:
			return found
	return null
