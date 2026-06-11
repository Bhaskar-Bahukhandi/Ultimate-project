extends SceneTree

const DIAGNOSTIC_DIR := "res://assets/art_sources/comfyui_tests/fractured_wastes_r3_import_preview/diagnostics"
const DIAGNOSTIC_PATH := "res://assets/art_sources/comfyui_tests/fractured_wastes_r3_import_preview/diagnostics/fractured_wastes_r3_asset_manager_check.json"
const FALLBACK_PATH := "res://assets/generated_v2/tilesets/fractured_wastes_v2_prototype_tileset.png"
const PRODUCTION_PATH := "res://assets/production_art/tilesets/fractured_wastes/fractured_wastes_tileset.png"
const MISSING_PRODUCTION_PROBE := "res://assets/production_art/tilesets/fractured_wastes/__missing_r3_probe__.png"
const OAKHAVEN_AFTERNOON := "res://assets/production_art/tilesets/oakhaven/oakhaven_afternoon_tileset.png"
const IRONHOLD_BASELINE := "res://assets/production_art/tilesets/ironhold/ironhold_tileset.png"

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(DIAGNOSTIC_DIR))
	var asset_manager := get_root().get_node_or_null("AssetManager")
	var checks := []
	checks.append(_check_production_present(asset_manager))
	checks.append(_check_runtime_fallback_override(asset_manager))
	checks.append(_check_missing_production_behavior(asset_manager))
	checks.append(_check_generated_fallback_available())
	checks.append(_check_oakhaven_baseline(asset_manager))
	checks.append(_check_ironhold_baseline(asset_manager))

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
			"production_art_changed": true,
			"actual_scene_modified": false,
		}, "\t"))

	if not all_passed:
		push_error("Fractured Wastes R3 AssetManager import check failed.")
		quit(1)
		return
	print("Fractured Wastes R3 AssetManager import check: PASS")
	quit(0)

func _check_production_present(asset_manager: Node) -> Dictionary:
	if not asset_manager or not asset_manager.has_method("get_fractured_wastes_tileset_slot"):
		return {"check": "AssetManager production load", "result": "Fail", "notes": "Fractured Wastes loader unavailable."}
	asset_manager.set_fractured_wastes_force_generated_fallback(false)
	var slot: Dictionary = asset_manager.get_fractured_wastes_tileset_slot()
	var texture := slot.get("texture") as Texture2D
	var passed := texture != null and bool(slot.get("production", false)) and str(slot.get("path", "")) == PRODUCTION_PATH
	return {
		"check": "AssetManager production load",
		"expected": PRODUCTION_PATH,
		"resolved_path": str(slot.get("path", "")),
		"production": bool(slot.get("production", false)),
		"texture_size": "" if texture == null else "%dx%d" % [texture.get_width(), texture.get_height()],
		"result": "Pass" if passed else "Fail",
	}

func _check_runtime_fallback_override(asset_manager: Node) -> Dictionary:
	if not asset_manager or not asset_manager.has_method("set_fractured_wastes_force_generated_fallback"):
		return {"check": "Runtime fallback override", "result": "Fail", "notes": "Fallback override unavailable."}
	asset_manager.set_fractured_wastes_force_generated_fallback(true)
	var slot: Dictionary = asset_manager.get_fractured_wastes_tileset_slot()
	asset_manager.set_fractured_wastes_force_generated_fallback(false)
	var texture := slot.get("texture") as Texture2D
	var passed := texture != null and not bool(slot.get("production", true)) and str(slot.get("path", "")) == FALLBACK_PATH
	return {
		"check": "Runtime fallback override",
		"expected": FALLBACK_PATH,
		"resolved_path": str(slot.get("path", "")),
		"production": bool(slot.get("production", true)),
		"fallback_reason": str(slot.get("fallback_reason", "")),
		"texture_size": "" if texture == null else "%dx%d" % [texture.get_width(), texture.get_height()],
		"result": "Pass" if passed else "Fail",
	}

func _check_missing_production_behavior(asset_manager: Node) -> Dictionary:
	if not asset_manager or not asset_manager.has_method("_try_load_fractured_wastes_production_tileset") or not asset_manager.has_method("_fractured_wastes_generated_fallback_slot"):
		return {"check": "Missing production behavior", "result": "Fail", "notes": "Probe methods unavailable."}
	var missing_texture = asset_manager._try_load_fractured_wastes_production_tileset(MISSING_PRODUCTION_PROBE)
	var fallback_slot: Dictionary = asset_manager._fractured_wastes_generated_fallback_slot(FALLBACK_PATH, "missing production probe")
	var fallback_texture := fallback_slot.get("texture") as Texture2D
	var passed := missing_texture == null and fallback_texture != null and not bool(fallback_slot.get("production", true)) and str(fallback_slot.get("path", "")) == FALLBACK_PATH
	return {
		"check": "Missing production behavior",
		"missing_probe": MISSING_PRODUCTION_PROBE,
		"missing_texture_null": missing_texture == null,
		"fallback_path": str(fallback_slot.get("path", "")),
		"fallback_texture_loaded": fallback_texture != null,
		"result": "Pass" if passed else "Fail",
	}

func _check_generated_fallback_available() -> Dictionary:
	var texture := _load_texture(FALLBACK_PATH)
	return {
		"check": "Generated fallback still available",
		"path": FALLBACK_PATH,
		"texture_size": "" if texture == null else "%dx%d" % [texture.get_width(), texture.get_height()],
		"result": "Pass" if texture != null else "Fail",
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

func _load_texture(path: String) -> Texture2D:
	if ResourceLoader.exists(path):
		return load(path) as Texture2D
	var image := Image.load_from_file(ProjectSettings.globalize_path(path))
	if image and not image.is_empty():
		return ImageTexture.create_from_image(image)
	return null
