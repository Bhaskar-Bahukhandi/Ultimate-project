extends SceneTree

const DIAGNOSTIC_DIR := "res://assets/art_sources/comfyui_tests/fractured_wastes_r3_import_preview/diagnostics"
const DIAGNOSTIC_PATH := "res://assets/art_sources/comfyui_tests/fractured_wastes_r3_import_preview/diagnostics/fractured_wastes_r3_scene_load_check.json"
const MAIN_MENU_SCENE := "res://scenes/main_menu.tscn"
const FRACTURED_WASTES_SCENE := "res://scenes/regions/fractured_wastes_region.tscn"
const FALLBACK_PATH := "res://assets/generated_v2/tilesets/fractured_wastes_v2_prototype_tileset.png"
const PRODUCTION_PATH := "res://assets/production_art/tilesets/fractured_wastes/fractured_wastes_tileset.png"

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(DIAGNOSTIC_DIR))
	var checks := []
	checks.append(await _check_main_menu_load())
	checks.append(await _check_region_scene(false))
	checks.append(await _check_region_scene(true))

	var all_passed := true
	for check in checks:
		if str(check.get("result", "")) != "Pass":
			all_passed = false
			break

	var file := FileAccess.open(ProjectSettings.globalize_path(DIAGNOSTIC_PATH), FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify({
			"phase": "10M-R3",
			"checks": checks,
			"all_passed": all_passed,
			"actual_scene_modified": false,
		}, "\t"))

	if not all_passed:
		push_error("Fractured Wastes R3 scene load check failed.")
		quit(1)
		return
	print("Fractured Wastes R3 scene load check: PASS")
	quit(0)

func _check_main_menu_load() -> Dictionary:
	await _clear_current_scene()
	var packed := load(MAIN_MENU_SCENE) as PackedScene
	if not packed:
		return {"check": "Main menu load", "result": "Fail", "notes": "PackedScene missing."}
	var scene := packed.instantiate()
	get_root().add_child(scene)
	current_scene = scene
	await _settle_frames(8)
	var passed := scene != null and scene.name == "MainMenu"
	return {
		"check": "Main menu load",
		"scene": MAIN_MENU_SCENE,
		"root_name": "" if scene == null else scene.name,
		"result": "Pass" if passed else "Fail",
	}

func _check_region_scene(force_fallback: bool) -> Dictionary:
	await _clear_current_scene()
	var asset_manager := get_root().get_node_or_null("AssetManager")
	if asset_manager and asset_manager.has_method("set_fractured_wastes_force_generated_fallback"):
		asset_manager.set_fractured_wastes_force_generated_fallback(force_fallback)
	var packed := load(FRACTURED_WASTES_SCENE) as PackedScene
	if not packed:
		return {"check": "Fractured Wastes region scene load", "result": "Fail", "notes": "PackedScene missing.", "force_fallback": force_fallback}
	var scene := packed.instantiate()
	get_root().add_child(scene)
	current_scene = scene
	await _settle_frames(18)

	var player := _find_node_by_name(scene, "Player")
	var camera := _find_node_by_name(scene, "RegionCamera")
	var visual_layer := _find_node_by_name(scene, "V2WastesGroundTiles")
	var farming_marker := _find_node_by_name(scene, "ShardFieldsFarming")
	var lyra := _find_node_by_name(scene, "Lyra")
	var survivor := _find_node_by_name(scene, "SurvivorKael")
	var visual_path := "" if visual_layer == null else str(visual_layer.get_meta("visual_tileset_path", ""))
	var visual_production := false if visual_layer == null else bool(visual_layer.get_meta("visual_tileset_production", false))
	var expected_path := FALLBACK_PATH if force_fallback else PRODUCTION_PATH
	var expected_production := not force_fallback
	var passed := player != null and camera != null and visual_layer != null and farming_marker != null and visual_path == expected_path and visual_production == expected_production
	if asset_manager and asset_manager.has_method("set_fractured_wastes_force_generated_fallback"):
		asset_manager.set_fractured_wastes_force_generated_fallback(false)
	return {
		"check": "Fractured Wastes region scene load",
		"scene": FRACTURED_WASTES_SCENE,
		"force_fallback": force_fallback,
		"expected_path": expected_path,
		"visual_layer_path": visual_path,
		"visual_layer_production": visual_production,
		"player_found": player != null,
		"camera_found": camera != null,
		"farming_marker_found": farming_marker != null,
		"lyra_found": lyra != null,
		"survivor_found": survivor != null,
		"result": "Pass" if passed else "Fail",
	}

func _clear_current_scene() -> void:
	if current_scene and is_instance_valid(current_scene):
		current_scene.queue_free()
		await _settle_frames(3)

func _settle_frames(count: int) -> void:
	for _i in range(count):
		await process_frame

func _find_node_by_name(root: Node, node_name: String) -> Node:
	if root.name == node_name:
		return root
	for child in root.get_children():
		var found := _find_node_by_name(child, node_name)
		if found:
			return found
	return null
