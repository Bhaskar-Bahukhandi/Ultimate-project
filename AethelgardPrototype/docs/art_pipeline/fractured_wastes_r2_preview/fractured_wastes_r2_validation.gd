extends SceneTree

const DIAGNOSTIC_DIR := "res://assets/art_sources/comfyui_tests/fractured_wastes_r2_preview/diagnostics"
const DIAGNOSTIC_PATH := "res://assets/art_sources/comfyui_tests/fractured_wastes_r2_preview/diagnostics/fractured_wastes_r2_validation.json"
const FRACTURED_WASTES_SCENE := "res://scenes/regions/fractured_wastes_region.tscn"
const FRACTURED_WASTES_FALLBACK := "res://assets/generated_v2/tilesets/fractured_wastes_v2_prototype_tileset.png"
const FRACTURED_WASTES_PRODUCTION_SLOT := "res://assets/production_art/tilesets/fractured_wastes_tileset.png"
const OAKHAVEN_AFTERNOON := "res://assets/production_art/tilesets/oakhaven/oakhaven_afternoon_tileset.png"
const IRONHOLD_BASELINE := "res://assets/production_art/tilesets/ironhold/ironhold_tileset.png"

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(DIAGNOSTIC_DIR))
	var checks := []
	var asset_manager = get_root().get_node_or_null("AssetManager")
	checks.append(_check_asset_manager_fallback(asset_manager))
	checks.append(_check_oakhaven_baseline(asset_manager))
	checks.append(_check_ironhold_baseline(asset_manager))
	checks.append(await _check_fractured_wastes_scene())

	var all_passed := true
	for check in checks:
		if str(check.get("result", "")) != "Pass":
			all_passed = false
			break

	var file := FileAccess.open(ProjectSettings.globalize_path(DIAGNOSTIC_PATH), FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify({
			"phase": "10M-R2",
			"checks": checks,
			"all_passed": all_passed,
			"production_art_changed": false,
		}, "\t"))
	if not all_passed:
		push_error("Fractured Wastes R2 validation failed.")
		quit(1)
		return
	print("Fractured Wastes R2 validation: PASS")
	quit(0)

func _check_asset_manager_fallback(asset_manager: Node) -> Dictionary:
	if not asset_manager:
		return {"check": "AssetManager fallback", "result": "Fail", "notes": "AssetManager autoload missing."}
	var layer = asset_manager.try_create_v2_visual_tile_layer(
		"fractured_wastes",
		Vector2(128, 128),
		"R2FracturedWastesFallbackProbe",
		-17,
		[Vector2i(1, 1), Vector2i(0, 0)]
	)
	if not layer:
		return {"check": "AssetManager fallback", "result": "Fail", "notes": "No visual layer returned."}
	var resolved_path := str(layer.get_meta("visual_tileset_path", ""))
	var production := bool(layer.get_meta("visual_tileset_production", true))
	layer.queue_free()
	var production_slot_exists := FileAccess.file_exists(ProjectSettings.globalize_path(FRACTURED_WASTES_PRODUCTION_SLOT)) or ResourceLoader.exists(FRACTURED_WASTES_PRODUCTION_SLOT)
	var passed := resolved_path == FRACTURED_WASTES_FALLBACK and not production and not production_slot_exists
	return {
		"check": "AssetManager fallback",
		"expected": FRACTURED_WASTES_FALLBACK,
		"resolved_path": resolved_path,
		"production": production,
		"production_slot_exists": production_slot_exists,
		"result": "Pass" if passed else "Fail",
	}

func _check_oakhaven_baseline(asset_manager: Node) -> Dictionary:
	if not asset_manager or not asset_manager.has_method("get_oakhaven_tileset_slot"):
		return {"check": "Oakhaven baseline preservation", "result": "Fail", "notes": "Oakhaven loader unavailable."}
	var slot: Dictionary = asset_manager.get_oakhaven_tileset_slot("afternoon")
	var passed := slot.get("texture") != null and bool(slot.get("production", false)) and str(slot.get("path", "")) == OAKHAVEN_AFTERNOON
	return {
		"check": "Oakhaven baseline preservation",
		"path": str(slot.get("path", "")),
		"production": bool(slot.get("production", false)),
		"result": "Pass" if passed else "Fail",
	}

func _check_ironhold_baseline(asset_manager: Node) -> Dictionary:
	if not asset_manager or not asset_manager.has_method("get_ironhold_tileset_slot"):
		return {"check": "Ironhold baseline preservation", "result": "Fail", "notes": "Ironhold loader unavailable."}
	var slot: Dictionary = asset_manager.get_ironhold_tileset_slot()
	var passed := slot.get("texture") != null and bool(slot.get("production", false)) and str(slot.get("path", "")) == IRONHOLD_BASELINE
	return {
		"check": "Ironhold baseline preservation",
		"path": str(slot.get("path", "")),
		"production": bool(slot.get("production", false)),
		"result": "Pass" if passed else "Fail",
	}

func _check_fractured_wastes_scene() -> Dictionary:
	var packed := load(FRACTURED_WASTES_SCENE) as PackedScene
	if not packed:
		return {"check": "Fractured Wastes scene load", "result": "Fail", "notes": "PackedScene missing."}
	var scene := packed.instantiate()
	get_root().add_child(scene)
	current_scene = scene
	await _settle_frames(12)
	var player := _find_node_by_name(scene, "Player")
	var camera := _find_node_by_name(scene, "RegionCamera")
	var visual_layer := _find_node_by_name(scene, "V2WastesGroundTiles")
	var farming_marker := _find_node_by_name(scene, "ShardFieldsFarming")
	var visual_path := "" if visual_layer == null else str(visual_layer.get_meta("visual_tileset_path", ""))
	var visual_production := false if visual_layer == null else bool(visual_layer.get_meta("visual_tileset_production", false))
	var passed := player != null and camera != null and visual_layer != null and farming_marker != null and visual_path == FRACTURED_WASTES_FALLBACK and not visual_production
	return {
		"check": "Fractured Wastes scene load",
		"scene": FRACTURED_WASTES_SCENE,
		"player_found": player != null,
		"camera_found": camera != null,
		"visual_layer_found": visual_layer != null,
		"visual_layer_path": visual_path,
		"visual_layer_production": visual_production,
		"farming_marker_found": farming_marker != null,
		"result": "Pass" if passed else "Fail",
	}

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
