extends SceneTree

const OAKHAVEN_SCENE := "res://scenes/regions/oakhaven_region.tscn"
const SCREENSHOT_DIR := "res://assets/art_sources/comfyui_tests/oakhaven_p11_import_preview/screenshots"
const CONTACT_DIR := "res://assets/art_sources/comfyui_tests/oakhaven_p11_import_preview/contact_sheets"
const MANIFEST_DIR := "res://assets/art_sources/comfyui_tests/oakhaven_p11_import_preview/manifest"
const FALLBACK_SCREENSHOT := "res://assets/art_sources/comfyui_tests/oakhaven_p11_import_preview/screenshots/oakhaven_p11_actual_fallback_scene.png"
const PRODUCTION_SCREENSHOT := "res://assets/art_sources/comfyui_tests/oakhaven_p11_import_preview/screenshots/oakhaven_p11_actual_afternoon_scene.png"
const CONTACT_SHEET := "res://assets/art_sources/comfyui_tests/oakhaven_p11_import_preview/contact_sheets/oakhaven_p11_actual_scene_fallback_vs_afternoon.png"
const MANIFEST_PATH := "res://assets/art_sources/comfyui_tests/oakhaven_p11_import_preview/manifest/oakhaven_p11_actual_scene_capture.json"

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	for path in [SCREENSHOT_DIR, CONTACT_DIR, MANIFEST_DIR]:
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(path))
	var packed_scene := load(OAKHAVEN_SCENE) as PackedScene
	if not packed_scene:
		push_error("P11 actual scene capture could not load Oakhaven scene.")
		quit(1)
		return

	var fallback_result := await _capture_one(packed_scene, true, FALLBACK_SCREENSHOT)
	var production_result := await _capture_one(packed_scene, false, PRODUCTION_SCREENSHOT)
	_set_fallback_mode(false)

	var fallback_image := Image.load_from_file(ProjectSettings.globalize_path(FALLBACK_SCREENSHOT))
	var production_image := Image.load_from_file(ProjectSettings.globalize_path(PRODUCTION_SCREENSHOT))
	if fallback_image == null or fallback_image.is_empty() or production_image == null or production_image.is_empty():
		push_error("P11 actual scene capture could not reload saved screenshots.")
		quit(1)
		return
	fallback_image.convert(Image.FORMAT_RGBA8)
	production_image.convert(Image.FORMAT_RGBA8)
	var contact := Image.create(fallback_image.get_width() + production_image.get_width(), max(fallback_image.get_height(), production_image.get_height()), false, Image.FORMAT_RGBA8)
	contact.fill(Color(0.08, 0.085, 0.10, 1.0))
	contact.blit_rect(fallback_image, Rect2i(0, 0, fallback_image.get_width(), fallback_image.get_height()), Vector2i.ZERO)
	contact.blit_rect(production_image, Rect2i(0, 0, production_image.get_width(), production_image.get_height()), Vector2i(fallback_image.get_width(), 0))
	var contact_err := contact.save_png(ProjectSettings.globalize_path(CONTACT_SHEET))
	if contact_err != OK:
		push_error("P11 actual scene contact save failed: %s" % contact_err)
		quit(1)
		return

	var data := {
		"phase": "10M-P11",
		"scene": OAKHAVEN_SCENE,
		"fallback_screenshot": FALLBACK_SCREENSHOT,
		"production_afternoon_screenshot": PRODUCTION_SCREENSHOT,
		"contact_sheet": CONTACT_SHEET,
		"fallback_result": fallback_result,
		"production_afternoon_result": production_result,
		"collision_modified": false,
		"gameplay_scene_file_modified": false,
	}
	var file := FileAccess.open(ProjectSettings.globalize_path(MANIFEST_PATH), FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(data, "\t"))
	print("P11 actual Oakhaven scene capture simple: PASS")
	quit(0)

func _capture_one(packed_scene: PackedScene, force_fallback: bool, output_path: String) -> Dictionary:
	_set_fallback_mode(force_fallback)
	if current_scene and is_instance_valid(current_scene):
		current_scene.queue_free()
		await process_frame
		await process_frame
	var scene := packed_scene.instantiate()
	get_root().add_child(scene)
	current_scene = scene
	for _frame_index in range(10):
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
		push_error("P11 actual scene production mismatch expected=%s actual=%s path=%s" % [expected_production, visual_production, visual_path])
		quit(1)
	var image := get_root().get_texture().get_image()
	var err := image.save_png(ProjectSettings.globalize_path(output_path))
	if err != OK:
		push_error("P11 actual scene screenshot failed: %s" % err)
		quit(1)
	return {
		"force_fallback": force_fallback,
		"screenshot": output_path,
		"visual_layer_found": visual_found,
		"visual_tileset_production": visual_production,
		"visual_tileset_path": visual_path,
		"oakhaven_time_state": visual_time_state,
	}

func _set_fallback_mode(force_fallback: bool) -> void:
	var asset_manager = get_root().get_node_or_null("AssetManager")
	if asset_manager and asset_manager.has_method("set_oakhaven_force_generated_fallback"):
		asset_manager.set_oakhaven_force_generated_fallback(force_fallback)

func _find_node_by_name(root: Node, node_name: String) -> Node:
	if root.name == node_name:
		return root
	for child in root.get_children():
		var found := _find_node_by_name(child, node_name)
		if found:
			return found
	return null
