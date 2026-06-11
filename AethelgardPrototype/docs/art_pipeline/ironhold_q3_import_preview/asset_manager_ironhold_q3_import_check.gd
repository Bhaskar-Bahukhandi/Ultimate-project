extends SceneTree

const DIAGNOSTIC_DIR := "res://assets/art_sources/comfyui_tests/ironhold_q3_import_preview/diagnostics"
const DIAGNOSTIC_PATH := "res://assets/art_sources/comfyui_tests/ironhold_q3_import_preview/diagnostics/ironhold_q3_asset_manager_import_check.json"
const IRONHOLD_PRODUCTION := "res://assets/production_art/tilesets/ironhold/ironhold_tileset.png"
const IRONHOLD_MISSING_PROBE := "res://assets/production_art/tilesets/ironhold/__q3_missing_probe.png"
const IRONHOLD_FALLBACK := "res://assets/generated_v2/tilesets/ironhold_v2_prototype_tileset.png"
const OAKHAVEN_AFTERNOON := "res://assets/production_art/tilesets/oakhaven/oakhaven_afternoon_tileset.png"

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(DIAGNOSTIC_DIR))
	var asset_manager = load("res://scripts/asset_manager.gd").new()
	var checks := []

	var production_slot: Dictionary = asset_manager.get_ironhold_tileset_slot()
	var production_texture = production_slot.get("texture")
	var production_passed := production_texture != null and bool(production_slot.get("production", false)) and str(production_slot.get("path", "")) == IRONHOLD_PRODUCTION
	checks.append({
		"scenario": "production present",
		"expected": "Ironhold production Variant B loads from the controlled production-art slot.",
		"actual": {
			"texture_loaded": production_texture != null,
			"path": str(production_slot.get("path", "")),
			"production": bool(production_slot.get("production", false)),
			"fallback_used": bool(production_slot.get("fallback_used", true)),
		},
		"result": "Pass" if production_passed else "Fail",
	})

	asset_manager.set_ironhold_force_generated_fallback(true)
	var fallback_slot: Dictionary = asset_manager.get_ironhold_tileset_slot()
	asset_manager.set_ironhold_force_generated_fallback(false)
	var fallback_texture = fallback_slot.get("texture")
	var fallback_passed := fallback_texture != null and not bool(fallback_slot.get("production", true)) and str(fallback_slot.get("path", "")) == IRONHOLD_FALLBACK and bool(fallback_slot.get("fallback_used", false))
	checks.append({
		"scenario": "runtime fallback override",
		"expected": "Generated fallback loads when the runtime override is enabled.",
		"actual": {
			"texture_loaded": fallback_texture != null,
			"path": str(fallback_slot.get("path", "")),
			"production": bool(fallback_slot.get("production", true)),
			"fallback_used": bool(fallback_slot.get("fallback_used", false)),
			"fallback_reason": str(fallback_slot.get("fallback_reason", "")),
		},
		"result": "Pass" if fallback_passed else "Fail",
	})

	var missing_texture = asset_manager._try_load_ironhold_production_tileset(IRONHOLD_MISSING_PROBE)
	var missing_fallback: Dictionary = asset_manager._ironhold_generated_fallback_slot(IRONHOLD_FALLBACK, "missing production probe")
	var missing_passed := missing_texture == null and missing_fallback.get("texture") != null and str(missing_fallback.get("path", "")) == IRONHOLD_FALLBACK
	checks.append({
		"scenario": "missing production behavior",
		"expected": "A missing production path does not crash and can resolve to generated fallback.",
		"actual": {
			"missing_texture_is_null": missing_texture == null,
			"fallback_texture_loaded": missing_fallback.get("texture") != null,
			"fallback_path": str(missing_fallback.get("path", "")),
		},
		"result": "Pass" if missing_passed else "Fail",
	})

	var generated_fallback_exists := FileAccess.file_exists(ProjectSettings.globalize_path(IRONHOLD_FALLBACK)) or ResourceLoader.exists(IRONHOLD_FALLBACK)
	checks.append({
		"scenario": "generated fallback still available",
		"expected": "The generated Ironhold fallback PNG remains present.",
		"actual": {
			"path": IRONHOLD_FALLBACK,
			"exists": generated_fallback_exists,
		},
		"result": "Pass" if generated_fallback_exists else "Fail",
	})

	var oakhaven_slot: Dictionary = asset_manager.get_oakhaven_tileset_slot("afternoon")
	var oakhaven_passed := oakhaven_slot.get("texture") != null and bool(oakhaven_slot.get("production", false)) and str(oakhaven_slot.get("path", "")) == OAKHAVEN_AFTERNOON
	checks.append({
		"scenario": "Oakhaven baseline preservation",
		"expected": "Oakhaven afternoon production baseline remains available.",
		"actual": {
			"texture_loaded": oakhaven_slot.get("texture") != null,
			"path": str(oakhaven_slot.get("path", "")),
			"production": bool(oakhaven_slot.get("production", false)),
			"time_state": str(oakhaven_slot.get("time_state", "")),
		},
		"result": "Pass" if oakhaven_passed else "Fail",
	})

	var all_passed := true
	for check in checks:
		if str(check.get("result", "")) != "Pass":
			all_passed = false
			break

	var data := {
		"phase": "10M-Q3",
		"checks": checks,
		"all_passed": all_passed,
		"production_path": IRONHOLD_PRODUCTION,
		"fallback_path": IRONHOLD_FALLBACK,
		"oakhaven_preservation_path": OAKHAVEN_AFTERNOON,
	}
	var file := FileAccess.open(ProjectSettings.globalize_path(DIAGNOSTIC_PATH), FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(data, "\t"))
	asset_manager.free()
	if not all_passed:
		push_error("Ironhold Q3 AssetManager import check failed.")
		quit(1)
		return
	print("Ironhold Q3 AssetManager import check: PASS")
	quit(0)
