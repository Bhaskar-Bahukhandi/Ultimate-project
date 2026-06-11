extends SceneTree

const DIAGNOSTIC_DIR := "res://assets/art_sources/comfyui_tests/ironhold_q3_import_preview/diagnostics"
const DIAGNOSTIC_PATH := "res://assets/art_sources/comfyui_tests/ironhold_q3_import_preview/diagnostics/ironhold_q3_scene_load_check.json"
const MAIN_MENU_SCENE := "res://scenes/main_menu.tscn"
const IRONHOLD_REGION_SCENE := "res://scenes/regions/ironhold_region.tscn"
const IRONHOLD_PRODUCTION := "res://assets/production_art/tilesets/ironhold/ironhold_tileset.png"

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(DIAGNOSTIC_DIR))
	var checks := []
	checks.append(await _load_scene_check("main menu", MAIN_MENU_SCENE, "MainMenu"))
	checks.append(await _load_ironhold_region_check())

	var all_passed := true
	for check in checks:
		if str(check.get("result", "")) != "Pass":
			all_passed = false
			break

	var file := FileAccess.open(ProjectSettings.globalize_path(DIAGNOSTIC_PATH), FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify({
			"phase": "10M-Q3",
			"checks": checks,
			"all_passed": all_passed,
		}, "\t"))
	if not all_passed:
		push_error("Ironhold Q3 scene load check failed.")
		quit(1)
		return
	print("Ironhold Q3 scene load check: PASS")
	quit(0)

func _load_scene_check(label: String, scene_path: String, expected_root_name: String) -> Dictionary:
	await _clear_current_scene()
	var packed := load(scene_path) as PackedScene
	if not packed:
		return {"scenario": label, "scene": scene_path, "result": "Fail", "reason": "PackedScene could not be loaded."}
	var scene := packed.instantiate()
	get_root().add_child(scene)
	current_scene = scene
	await _settle_frames(8)
	var passed := scene.name == expected_root_name or _find_node_by_name(scene, expected_root_name) != null
	return {
		"scenario": label,
		"scene": scene_path,
		"root": scene.name,
		"expected_root_or_node": expected_root_name,
		"result": "Pass" if passed else "Fail",
	}

func _load_ironhold_region_check() -> Dictionary:
	await _clear_current_scene()
	var asset_manager = get_root().get_node_or_null("AssetManager")
	if asset_manager and asset_manager.has_method("set_ironhold_force_generated_fallback"):
		asset_manager.set_ironhold_force_generated_fallback(false)
	var packed := load(IRONHOLD_REGION_SCENE) as PackedScene
	if not packed:
		return {"scenario": "Ironhold region scene", "scene": IRONHOLD_REGION_SCENE, "result": "Fail", "reason": "PackedScene could not be loaded."}
	var scene := packed.instantiate()
	get_root().add_child(scene)
	current_scene = scene
	await _settle_frames(14)
	var player := _find_node_by_name(scene, "Player")
	var visual_layer := _find_node_by_name(scene, "V2IronholdGroundTiles")
	var farming_marker := _find_node_by_name(scene, "IronholdTrainingYardFarming")
	var production_path := "" if visual_layer == null else str(visual_layer.get_meta("visual_tileset_path", ""))
	var production_enabled := false if visual_layer == null else bool(visual_layer.get_meta("visual_tileset_production", false))
	var passed := player != null and visual_layer != null and farming_marker != null and production_path == IRONHOLD_PRODUCTION and production_enabled
	return {
		"scenario": "Ironhold region scene",
		"scene": IRONHOLD_REGION_SCENE,
		"player_found": player != null,
		"visual_layer_found": visual_layer != null,
		"visual_layer_path": production_path,
		"visual_layer_production": production_enabled,
		"farming_marker_found": farming_marker != null,
		"result": "Pass" if passed else "Fail",
	}

func _clear_current_scene() -> void:
	if current_scene and is_instance_valid(current_scene):
		current_scene.queue_free()
		await _settle_frames(2)

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
