extends SceneTree

const DIAGNOSTIC_DIR := "res://assets/art_sources/comfyui_tests/ironhold_q2_preview/diagnostics"
const DIAGNOSTIC_PATH := "res://assets/art_sources/comfyui_tests/ironhold_q2_preview/diagnostics/ironhold_q2_asset_manager_fallback_check.json"
const IRONHOLD_FALLBACK := "res://assets/generated_v2/tilesets/ironhold_v2_prototype_tileset.png"
const IRONHOLD_PRODUCTION_SLOT := "res://assets/production_art/tilesets/ironhold_tileset.png"
const OAKHAVEN_AFTERNOON := "res://assets/production_art/tilesets/oakhaven/oakhaven_afternoon_tileset.png"

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(DIAGNOSTIC_DIR))
	var asset_manager = load("res://scripts/asset_manager.gd").new()
	var checks := []

	var background: TextureRect = asset_manager.try_create_v2_control_tileset_background("ironhold", "IronholdQ2FallbackProbe")
	var ironhold_texture_loaded := background != null and background.texture != null
	var ironhold_path := "" if background == null else str(background.get_meta("visual_tileset_path", ""))
	var ironhold_production := false if background == null else bool(background.get_meta("visual_tileset_production", true))
	var ironhold_production_slot_exists := FileAccess.file_exists(IRONHOLD_PRODUCTION_SLOT) or ResourceLoader.exists(IRONHOLD_PRODUCTION_SLOT)
	var ironhold_fallback_exists := FileAccess.file_exists(IRONHOLD_FALLBACK) or ResourceLoader.exists(IRONHOLD_FALLBACK)
	var ironhold_passed := ironhold_texture_loaded and ironhold_path == IRONHOLD_FALLBACK and not ironhold_production and not ironhold_production_slot_exists and ironhold_fallback_exists
	checks.append({
		"scenario": "Ironhold fallback behavior",
		"expected": "Ironhold production slot is absent and generated fallback loads.",
		"actual": {
			"texture_loaded": ironhold_texture_loaded,
			"resolved_path": ironhold_path,
			"visual_tileset_production": ironhold_production,
			"production_slot_exists": ironhold_production_slot_exists,
			"fallback_exists": ironhold_fallback_exists,
		},
		"result": "Pass" if ironhold_passed else "Fail",
	})
	if background:
		background.free()

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

	var all_passed := ironhold_passed and oakhaven_passed
	var data := {
		"phase": "10M-Q2",
		"checks": checks,
		"all_passed": all_passed,
		"production_art_changed": false,
	}
	var file := FileAccess.open(ProjectSettings.globalize_path(DIAGNOSTIC_PATH), FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(data, "\t"))
	asset_manager.free()
	if not all_passed:
		push_error("Ironhold Q2 AssetManager fallback check failed.")
		quit(1)
		return
	print("Ironhold Q2 AssetManager fallback check: PASS")
	quit(0)
