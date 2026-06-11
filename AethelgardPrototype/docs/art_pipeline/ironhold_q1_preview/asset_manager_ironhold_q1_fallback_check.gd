extends SceneTree

const DIAGNOSTIC_DIR := "res://assets/art_sources/comfyui_tests/ironhold_q1/diagnostics"
const DIAGNOSTIC_PATH := "res://assets/art_sources/comfyui_tests/ironhold_q1/diagnostics/ironhold_q1_asset_manager_fallback_check.json"
const EXPECTED_FALLBACK := "res://assets/generated_v2/tilesets/ironhold_v2_prototype_tileset.png"
const PRODUCTION_SLOT := "res://assets/production_art/tilesets/ironhold_tileset.png"

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(DIAGNOSTIC_DIR))
	var asset_manager = load("res://scripts/asset_manager.gd").new()
	var background: TextureRect = asset_manager.try_create_v2_control_tileset_background("ironhold", "IronholdQ1FallbackProbe")
	var texture_loaded := background != null and background.texture != null
	var resolved_path := "" if background == null else str(background.get_meta("visual_tileset_path", ""))
	var production := false if background == null else bool(background.get_meta("visual_tileset_production", true))
	var production_slot_exists := FileAccess.file_exists(PRODUCTION_SLOT) or ResourceLoader.exists(PRODUCTION_SLOT)
	var fallback_exists := FileAccess.file_exists(EXPECTED_FALLBACK) or ResourceLoader.exists(EXPECTED_FALLBACK)
	var passed := texture_loaded and resolved_path == EXPECTED_FALLBACK and not production and not production_slot_exists and fallback_exists
	var data := {
		"phase": "10M-Q1",
		"scenario": "Ironhold AssetManager fallback check",
		"production_slot": PRODUCTION_SLOT,
		"production_slot_exists": production_slot_exists,
		"expected_fallback": EXPECTED_FALLBACK,
		"fallback_exists": fallback_exists,
		"texture_loaded": texture_loaded,
		"resolved_path": resolved_path,
		"visual_tileset_production": production,
		"result": "Pass" if passed else "Fail",
	}
	var file := FileAccess.open(ProjectSettings.globalize_path(DIAGNOSTIC_PATH), FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(data, "\t"))
	if background:
		background.free()
	asset_manager.free()
	if not passed:
		push_error("Ironhold Q1 AssetManager fallback check failed.")
		quit(1)
		return
	print("Ironhold Q1 AssetManager fallback check: PASS")
	quit(0)
