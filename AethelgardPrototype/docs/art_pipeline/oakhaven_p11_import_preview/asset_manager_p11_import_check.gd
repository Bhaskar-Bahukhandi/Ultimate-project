extends SceneTree

const MANIFEST_DIR := "res://assets/art_sources/comfyui_tests/oakhaven_p11_import_preview/manifest"
const MANIFEST_PATH := "res://assets/art_sources/comfyui_tests/oakhaven_p11_import_preview/manifest/oakhaven_p11_asset_manager_import_check.json"
const FALLBACK_PATH := "res://assets/generated_v2/tilesets/oakhaven_v2_prototype_tileset.png"
const MISSING_NIGHT_PROBE_PATH := "res://assets/production_art/tilesets/oakhaven/__missing_night_probe_tileset.png"

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(MANIFEST_DIR))
	var asset_manager = load("res://scripts/asset_manager.gd").new()
	var checks := []

	for time_state in ["morning", "afternoon", "night"]:
		var slot: Dictionary = asset_manager.get_oakhaven_tileset_slot(time_state)
		var texture := slot.get("texture") as Texture2D
		var ok: bool = texture != null and bool(slot.get("production", false)) and str(slot.get("time_state", "")) == time_state
		checks.append({
			"scenario": "%s production present" % time_state,
			"expected": "%s production atlas loads" % time_state,
			"actual": slot,
			"result": "Pass" if ok else "Fail",
		})
		if not ok:
			push_error("P11 production slot check failed for %s" % time_state)
			asset_manager.free()
			quit(1)
			return

	var invalid_slot: Dictionary = asset_manager.get_oakhaven_tileset_slot("dusk")
	var invalid_ok: bool = invalid_slot.get("texture") != null and bool(invalid_slot.get("production", false)) and str(invalid_slot.get("time_state", "")) == "afternoon"
	checks.append({
		"scenario": "invalid time state",
		"expected": "invalid state resolves to afternoon production atlas",
		"actual": invalid_slot,
		"result": "Pass" if invalid_ok else "Fail",
	})
	if not invalid_ok:
		push_error("P11 invalid time state check failed.")
		asset_manager.free()
		quit(1)
		return

	var fallback_slot: Dictionary = asset_manager._oakhaven_generated_fallback_slot(FALLBACK_PATH, "afternoon", "afternoon", "validation fallback probe")
	var fallback_ok: bool = fallback_slot.get("texture") != null and not bool(fallback_slot.get("production", true)) and str(fallback_slot.get("path", "")) == FALLBACK_PATH
	checks.append({
		"scenario": "generated fallback available",
		"expected": "generated fallback texture loads",
		"actual": fallback_slot,
		"result": "Pass" if fallback_ok else "Fail",
	})
	if not fallback_ok:
		push_error("P11 generated fallback check failed.")
		asset_manager.free()
		quit(1)
		return

	var missing_texture = asset_manager._try_load_oakhaven_production_variant(MISSING_NIGHT_PROBE_PATH, "night", "night")
	var afternoon_slot: Dictionary = asset_manager.get_oakhaven_tileset_slot("afternoon")
	var missing_ok: bool = missing_texture == null and afternoon_slot.get("texture") != null and bool(afternoon_slot.get("production", false))
	checks.append({
		"scenario": "controlled missing variant path",
		"expected": "missing variant load returns null and afternoon production remains available as safe fallback",
		"actual": {
			"missing_probe_path": MISSING_NIGHT_PROBE_PATH,
			"missing_texture_loaded": missing_texture != null,
			"afternoon_path": afternoon_slot.get("path", ""),
			"afternoon_production": bool(afternoon_slot.get("production", false)),
		},
		"result": "Pass" if missing_ok else "Fail",
	})
	if not missing_ok:
		push_error("P11 controlled missing variant check failed.")
		asset_manager.free()
		quit(1)
		return

	var data := {
		"phase": "10M-P11",
		"checks": checks,
		"production_art_changed": true,
		"fallback_preserved": true,
	}
	var file := FileAccess.open(ProjectSettings.globalize_path(MANIFEST_PATH), FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(data, "\t"))
	asset_manager.free()
	print("P11 AssetManager import check: PASS")
	quit(0)
