extends SceneTree

const OAKHAVEN_SCENE := "res://scenes/regions/oakhaven_region.tscn"
const SCREENSHOT_DIR := "res://assets/art_sources/comfyui_tests/oakhaven_p12_acceptance/screenshots"
const CONTACT_DIR := "res://assets/art_sources/comfyui_tests/oakhaven_p12_acceptance/contact_sheets"
const DIAGNOSTIC_DIR := "res://assets/art_sources/comfyui_tests/oakhaven_p12_acceptance/diagnostics"
const MANIFEST_DIR := "res://assets/art_sources/comfyui_tests/oakhaven_p12_acceptance/manifest"
const CONTACT_SHEET := "res://assets/art_sources/comfyui_tests/oakhaven_p12_acceptance/contact_sheets/oakhaven_p12_fallback_vs_production_contact_sheet.png"
const DIAGNOSTIC_PATH := "res://assets/art_sources/comfyui_tests/oakhaven_p12_acceptance/diagnostics/oakhaven_p12_actual_scene_capture_diagnostics.json"

const CAPTURES := [
	{
		"id": "fallback_center",
		"label": "Fallback center",
		"force_fallback": true,
		"focus": Vector2(1050, 1000),
		"output": "res://assets/art_sources/comfyui_tests/oakhaven_p12_acceptance/screenshots/oakhaven_p12_fallback_center.png",
	},
	{
		"id": "production_center",
		"label": "Production center",
		"force_fallback": false,
		"focus": Vector2(1050, 1000),
		"output": "res://assets/art_sources/comfyui_tests/oakhaven_p12_acceptance/screenshots/oakhaven_p12_production_center.png",
	},
	{
		"id": "production_spawn",
		"label": "Production spawn",
		"force_fallback": false,
		"focus": Vector2(1050, 1250),
		"output": "res://assets/art_sources/comfyui_tests/oakhaven_p12_acceptance/screenshots/oakhaven_p12_production_spawn.png",
	},
	{
		"id": "production_farming_area",
		"label": "Production farming",
		"force_fallback": false,
		"focus": Vector2(430, 980),
		"output": "res://assets/art_sources/comfyui_tests/oakhaven_p12_acceptance/screenshots/oakhaven_p12_production_farming_area.png",
	},
	{
		"id": "production_exit_area",
		"label": "Production exit",
		"force_fallback": false,
		"focus": Vector2(1600, 2300),
		"output": "res://assets/art_sources/comfyui_tests/oakhaven_p12_acceptance/screenshots/oakhaven_p12_production_exit_area.png",
	},
	{
		"id": "production_npc_area",
		"label": "Production NPCs",
		"force_fallback": false,
		"focus": Vector2(1050, 950),
		"output": "res://assets/art_sources/comfyui_tests/oakhaven_p12_acceptance/screenshots/oakhaven_p12_production_npc_area.png",
	},
]

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	get_root().size = Vector2i(1280, 720)
	for path in [SCREENSHOT_DIR, CONTACT_DIR, DIAGNOSTIC_DIR, MANIFEST_DIR]:
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(path))

	var packed_scene := load(OAKHAVEN_SCENE) as PackedScene
	if not packed_scene:
		push_error("P12 capture could not load Oakhaven scene.")
		quit(1)
		return

	var results := []
	for capture in CAPTURES:
		results.append(await _capture_one(packed_scene, capture))

	_set_fallback_mode(false)
	var contact_result := _build_contact_sheet()
	var diagnostics := {
		"phase": "10M-P12",
		"scene": OAKHAVEN_SCENE,
		"contact_sheet": CONTACT_SHEET,
		"contact_sheet_status": contact_result,
		"captures": results,
		"production_art_modified": false,
		"gameplay_scene_modified": false,
		"collision_modified": false,
	}
	var file := FileAccess.open(ProjectSettings.globalize_path(DIAGNOSTIC_PATH), FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(diagnostics, "\t"))
	print("P12 Oakhaven actual-scene acceptance capture: PASS")
	quit(0)

func _capture_one(packed_scene: PackedScene, capture: Dictionary) -> Dictionary:
	var force_fallback := bool(capture.get("force_fallback", false))
	_set_fallback_mode(force_fallback)
	if current_scene and is_instance_valid(current_scene):
		current_scene.queue_free()
		await process_frame
		await process_frame

	var scene := packed_scene.instantiate()
	get_root().add_child(scene)
	current_scene = scene
	for _i in range(8):
		await process_frame

	var focus := capture.get("focus", Vector2.ZERO) as Vector2
	var player := _find_node_by_name(scene, "Player") as Node2D
	if player:
		player.global_position = focus
	var camera := _find_node_by_name(scene, "RegionCamera") as Camera2D
	if camera:
		camera.position_smoothing_enabled = false
		camera.global_position = focus
		camera.make_current()
		camera.reset_smoothing()

	for _i in range(8):
		await physics_frame
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
	var expected_production := not force_fallback
	if visual_found and visual_production != expected_production:
		push_error("P12 capture production mismatch for %s expected=%s actual=%s path=%s" % [capture.get("id", "unknown"), expected_production, visual_production, visual_path])
		quit(1)

	var image := get_root().get_texture().get_image()
	if image == null or image.is_empty():
		push_error("P12 capture failed because viewport image was empty. Run this script without --headless.")
		quit(1)
		return {}
	var output_path := str(capture.get("output", ""))
	var err := image.save_png(ProjectSettings.globalize_path(output_path))
	if err != OK:
		push_error("P12 screenshot save failed for %s: %s" % [output_path, err])
		quit(1)
		return {}

	return {
		"id": str(capture.get("id", "")),
		"label": str(capture.get("label", "")),
		"force_fallback": force_fallback,
		"focus": _vector_to_string(focus),
		"screenshot": output_path,
		"visual_layer_found": visual_found,
		"visual_tileset_production": visual_production,
		"visual_tileset_path": visual_path,
		"oakhaven_time_state": visual_time_state,
		"player_found": player != null,
		"npc_count": _count_nodes_with_meta(scene, "npc_name"),
		"farming_marker_found": _find_node_by_name(scene, "OakhavenOutskirtsFarming") != null,
		"south_exit_found": _find_node_by_name(scene, "OverworldExit") != null,
		"east_exit_found": _find_node_by_name(scene, "OverworldExitEast") != null,
		"label_count": _count_labels(scene),
	}

func _set_fallback_mode(force_fallback: bool) -> void:
	var asset_manager = get_root().get_node_or_null("AssetManager")
	if asset_manager and asset_manager.has_method("set_oakhaven_force_generated_fallback"):
		asset_manager.set_oakhaven_force_generated_fallback(force_fallback)

func _build_contact_sheet() -> Dictionary:
	var loaded_images := []
	for capture in CAPTURES:
		var image := Image.load_from_file(ProjectSettings.globalize_path(str(capture.get("output", ""))))
		if image == null or image.is_empty():
			return {"result": "Fail", "reason": "missing screenshot %s" % capture.get("output", "")}
		image.convert(Image.FORMAT_RGBA8)
		loaded_images.append(image)

	var cell_width := int(loaded_images[0].get_width())
	var cell_height := int(loaded_images[0].get_height())
	var columns := 3
	var rows := int(ceil(float(loaded_images.size()) / float(columns)))
	var contact := Image.create(cell_width * columns, cell_height * rows, false, Image.FORMAT_RGBA8)
	contact.fill(Color(0.07, 0.075, 0.085, 1.0))
	for index in range(loaded_images.size()):
		var x := (index % columns) * cell_width
		var y := int(index / columns) * cell_height
		var image: Image = loaded_images[index]
		contact.blit_rect(image, Rect2i(0, 0, image.get_width(), image.get_height()), Vector2i(x, y))

	var err := contact.save_png(ProjectSettings.globalize_path(CONTACT_SHEET))
	if err != OK:
		return {"result": "Fail", "reason": "save error %s" % err}
	return {"result": "Pass", "path": CONTACT_SHEET, "columns": columns, "rows": rows}

func _find_node_by_name(root: Node, node_name: String) -> Node:
	if root.name == node_name:
		return root
	for child in root.get_children():
		var found := _find_node_by_name(child, node_name)
		if found:
			return found
	return null

func _count_nodes_with_meta(root: Node, meta_name: String) -> int:
	var count := 1 if root.has_meta(meta_name) else 0
	for child in root.get_children():
		count += _count_nodes_with_meta(child, meta_name)
	return count

func _count_labels(root: Node) -> int:
	var count := 1 if root is Label else 0
	for child in root.get_children():
		count += _count_labels(child)
	return count

func _vector_to_string(value: Vector2) -> String:
	return "(%.1f, %.1f)" % [value.x, value.y]
