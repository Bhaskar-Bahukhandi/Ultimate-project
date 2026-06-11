extends SceneTree

const DIAGNOSTIC_DIR := "res://assets/art_sources/comfyui_tests/oakhaven_p12_acceptance/diagnostics"
const DIAGNOSTIC_PATH := "res://assets/art_sources/comfyui_tests/oakhaven_p12_acceptance/diagnostics/oakhaven_p12_asset_manager_acceptance_check.json"
const FALLBACK_PATH := "res://assets/generated_v2/tilesets/oakhaven_v2_prototype_tileset.png"
const AFTERNOON_PATH := "res://assets/production_art/tilesets/oakhaven/oakhaven_afternoon_tileset.png"
const MORNING_PATH := "res://assets/production_art/tilesets/oakhaven/oakhaven_morning_tileset.png"
const NIGHT_PATH := "res://assets/production_art/tilesets/oakhaven/oakhaven_night_tileset.png"
const MISSING_PROBE_PATH := "res://assets/production_art/tilesets/oakhaven/__missing_p12_acceptance_probe_tileset.png"

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(DIAGNOSTIC_DIR))
	var asset_manager = load("res://scripts/asset_manager.gd").new()
	var checks := []

	var default_slot: Dictionary = asset_manager.get_oakhaven_tileset_slot()
	_append_check(
		checks,
		"production default",
		"Default Oakhaven slot resolves to afternoon production.",
		_slot_to_data(default_slot),
		_slot_is_production(default_slot, AFTERNOON_PATH, "afternoon")
	)

	for time_state in ["morning", "afternoon", "night"]:
		var slot: Dictionary = asset_manager.get_oakhaven_tileset_slot(time_state)
		var expected_path := AFTERNOON_PATH
		if time_state == "morning":
			expected_path = MORNING_PATH
		elif time_state == "night":
			expected_path = NIGHT_PATH
		_append_check(
			checks,
			"%s staged variant load" % time_state,
			"%s production atlas is loadable through AssetManager." % time_state,
			_slot_to_data(slot),
			_slot_is_production(slot, expected_path, time_state)
		)

	var invalid_slot: Dictionary = asset_manager.get_oakhaven_tileset_slot("dusk")
	_append_check(
		checks,
		"invalid time state",
		"Invalid Oakhaven time state resolves to afternoon production.",
		_slot_to_data(invalid_slot),
		_slot_is_production(invalid_slot, AFTERNOON_PATH, "afternoon") and bool(invalid_slot.get("fallback_used", false))
	)

	asset_manager.set_oakhaven_force_generated_fallback(true)
	var forced_fallback_slot: Dictionary = asset_manager.get_oakhaven_tileset_slot("afternoon")
	_append_check(
		checks,
		"runtime generated fallback override",
		"Runtime override resolves Oakhaven to generated fallback without removing production files.",
		_slot_to_data(forced_fallback_slot),
		_slot_is_generated_fallback(forced_fallback_slot)
	)
	asset_manager.set_oakhaven_force_generated_fallback(false)

	var missing_texture = asset_manager._try_load_oakhaven_production_variant(MISSING_PROBE_PATH, "night", "night")
	var post_missing_default: Dictionary = asset_manager.get_oakhaven_tileset_slot("afternoon")
	_append_check(
		checks,
		"controlled missing production behavior",
		"Missing production variant probe returns null and afternoon production remains available.",
		{
			"missing_probe_path": MISSING_PROBE_PATH,
			"missing_texture_loaded": missing_texture != null,
			"default_after_probe": _slot_to_data(post_missing_default),
		},
		missing_texture == null and _slot_is_production(post_missing_default, AFTERNOON_PATH, "afternoon")
	)

	var all_passed := true
	for check in checks:
		if str(check.get("result", "")) != "Pass":
			all_passed = false
			break

	var data := {
		"phase": "10M-P12",
		"checks": checks,
		"all_passed": all_passed,
		"production_default": "afternoon",
		"morning_night_staged_only": true,
		"generated_fallback_preserved": true,
	}
	var file := FileAccess.open(ProjectSettings.globalize_path(DIAGNOSTIC_PATH), FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(data, "\t"))
	asset_manager.free()

	if not all_passed:
		push_error("P12 AssetManager acceptance check failed.")
		quit(1)
		return
	print("P12 AssetManager acceptance check: PASS")
	quit(0)

func _append_check(checks: Array, scenario: String, expected: String, actual: Variant, passed: bool) -> void:
	checks.append({
		"scenario": scenario,
		"expected": expected,
		"actual": actual,
		"result": "Pass" if passed else "Fail",
	})

func _slot_is_production(slot: Dictionary, expected_path: String, expected_time_state: String) -> bool:
	return slot.get("texture") != null \
		and bool(slot.get("production", false)) \
		and str(slot.get("path", "")) == expected_path \
		and str(slot.get("time_state", "")) == expected_time_state

func _slot_is_generated_fallback(slot: Dictionary) -> bool:
	return slot.get("texture") != null \
		and not bool(slot.get("production", true)) \
		and str(slot.get("path", "")) == FALLBACK_PATH

func _slot_to_data(slot: Dictionary) -> Dictionary:
	return {
		"texture_loaded": slot.get("texture") != null,
		"path": str(slot.get("path", "")),
		"production": bool(slot.get("production", false)),
		"requested_time_state": str(slot.get("requested_time_state", "")),
		"time_state": str(slot.get("time_state", "")),
		"fallback_used": bool(slot.get("fallback_used", false)),
		"fallback_reason": str(slot.get("fallback_reason", "")),
	}
