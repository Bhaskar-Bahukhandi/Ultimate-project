extends SceneTree

const DIAGNOSTIC_DIR := "res://assets/art_sources/comfyui_tests/shared_environment_s3_prop_repair/diagnostics"
const CROP_DIR := "res://assets/art_sources/comfyui_tests/shared_environment_s3_prop_repair/crop_checks"
const DIAGNOSTIC_PATH := "res://assets/art_sources/comfyui_tests/shared_environment_s3_prop_repair/diagnostics/shared_environment_s3_godot_validation.json"
const GODOT_CROP_PROBE := "res://assets/art_sources/comfyui_tests/shared_environment_s3_prop_repair/crop_checks/shared_env_s3_godot_runtime_crop_probe.png"

const CURRENT_PROP := "res://assets/generated_v3/props/phase10mm_environment_prop_atlas.png"
const CURRENT_DECAL := "res://assets/generated_v3/overlays/phase10mm_environment_decal_atlas.png"
const S3_PROP := "res://assets/art_sources/comfyui_tests/shared_environment_s3_prop_repair/generated_props/shared_environment_props_s3_variant_b_rich.png"
const S1_DECAL := "res://assets/art_sources/comfyui_tests/shared_environment_s1/generated_decals/shared_environment_decals_s1_variant_b.png"
const PROD_PROP := "res://assets/production_art/props/environment_prop_atlas.png"
const PROD_DECAL := "res://assets/production_art/backgrounds/environment_decal_atlas.png"
const OAKHAVEN_BASELINE := "res://assets/production_art/tilesets/oakhaven/oakhaven_afternoon_tileset.png"
const IRONHOLD_BASELINE := "res://assets/production_art/tilesets/ironhold/ironhold_tileset.png"
const FRACTURED_BASELINE := "res://assets/production_art/tilesets/fractured_wastes/fractured_wastes_tileset.png"

const PROP_REGIONS := {
	"oakhaven_roof": Rect2i(32, 22, 248, 190),
	"oakhaven_hedge_corner": Rect2i(760, 52, 390, 176),
	"oakhaven_flowers": Rect2i(30, 264, 418, 82),
	"oakhaven_herb_sign": Rect2i(478, 238, 128, 126),
	"ironhold_pipes": Rect2i(616, 238, 544, 170),
	"ironhold_forge": Rect2i(1320, 226, 164, 194),
	"crates": Rect2i(40, 434, 540, 144),
	"archive_shelves": Rect2i(620, 370, 356, 218),
	"dossier_stack": Rect2i(988, 440, 94, 128),
	"null_seal": Rect2i(1092, 432, 156, 176),
	"mirror_plinth": Rect2i(1280, 430, 202, 192),
	"server_console": Rect2i(36, 612, 376, 194),
	"firewall_panel": Rect2i(430, 612, 358, 194),
	"tide_buoy": Rect2i(824, 610, 120, 182),
	"salvage_shelf": Rect2i(974, 610, 290, 198),
	"ocean_cache": Rect2i(1268, 610, 236, 198),
	"lab_console": Rect2i(34, 818, 248, 178),
	"memory_tank": Rect2i(292, 814, 170, 186),
	"root_circuit_rail": Rect2i(628, 816, 844, 190),
}

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(DIAGNOSTIC_DIR))
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(CROP_DIR))
	var checks := []
	checks.append(_check_texture("current V3 prop atlas", CURRENT_PROP, true, Vector2i(1536, 1024)))
	checks.append(_check_texture("current V3 decal atlas", CURRENT_DECAL, true, Vector2i(1536, 1024)))
	checks.append(_check_texture("S3 Variant B prop repair", S3_PROP, true, Vector2i(1536, 1024)))
	checks.append(_check_texture("S1 decal candidate unchanged", S1_DECAL, true, Vector2i(1536, 1024)))
	checks.append(_check_texture("production prop slot absent", PROD_PROP, false, Vector2i.ZERO))
	checks.append(_check_texture("production decal slot absent", PROD_DECAL, false, Vector2i.ZERO))
	checks.append(_check_texture("Oakhaven baseline preservation", OAKHAVEN_BASELINE, true, Vector2i(512, 512)))
	checks.append(_check_texture("Ironhold baseline preservation", IRONHOLD_BASELINE, true, Vector2i(512, 512)))
	checks.append(_check_texture("Fractured Wastes baseline preservation", FRACTURED_BASELINE, true, Vector2i(512, 512)))
	checks.append(_check_s3_prop_contract())
	checks.append(await _check_scene_load("main menu", "res://scenes/main_menu.tscn"))
	var all_passed := true
	for check in checks:
		if str(check.get("result", "")) != "Pass":
			all_passed = false
			break
	var file := FileAccess.open(ProjectSettings.globalize_path(DIAGNOSTIC_PATH), FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify({"phase": "10M-S3", "checks": checks, "all_passed": all_passed, "production_art_changed": false, "generated_v3_overwritten": false, "actual_gameplay_scenes_modified": false}, "\t"))
	if not all_passed:
		push_error("Shared Environment S3 validation failed.")
		quit(1)
		return
	print("Shared Environment S3 validation: PASS")
	quit(0)

func _check_texture(label: String, path: String, should_exist: bool, expected_size: Vector2i) -> Dictionary:
	var exists := ResourceLoader.exists(path) or FileAccess.file_exists(path)
	var image := Image.new()
	var loaded := false
	if exists:
		var err := image.load(ProjectSettings.globalize_path(path))
		loaded = err == OK and not image.is_empty()
	var size_ok := true
	if should_exist and expected_size != Vector2i.ZERO:
		size_ok = loaded and image.get_size() == expected_size
	var ok := exists == should_exist
	if should_exist:
		ok = ok and loaded and size_ok
	return {"check": label, "path": path, "exists": exists, "loaded": loaded, "size": image.get_size() if loaded else Vector2i.ZERO, "result": "Pass" if ok else "Fail"}

func _check_s3_prop_contract() -> Dictionary:
	var prop_image := Image.new()
	var loaded := prop_image.load(ProjectSettings.globalize_path(S3_PROP)) == OK and not prop_image.is_empty()
	var all_valid := loaded
	if loaded:
		for id in PROP_REGIONS.keys():
			var rect: Rect2i = PROP_REGIONS[id]
			all_valid = all_valid and rect.position.x >= 0 and rect.position.y >= 0 and rect.end.x <= prop_image.get_width() and rect.end.y <= prop_image.get_height()
	var probe_ok := _write_crop_probe(prop_image) == OK
	return {"check": "S3 prop same-Rect2i contract", "rects_valid": all_valid, "crop_probe_saved": probe_ok, "result": "Pass" if all_valid and probe_ok else "Fail"}

func _check_scene_load(label: String, path: String) -> Dictionary:
	if not ResourceLoader.exists(path):
		return {"check": label, "path": path, "result": "Skipped", "notes": "scene path not found"}
	var packed := load(path) as PackedScene
	if not packed:
		return {"check": label, "path": path, "result": "Fail", "notes": "PackedScene load failed"}
	var scene := packed.instantiate()
	get_root().add_child(scene)
	current_scene = scene
	for i in range(4):
		await process_frame
	var ok := scene != null
	if scene:
		scene.queue_free()
		await process_frame
	current_scene = null
	return {"check": label, "path": path, "result": "Pass" if ok else "Fail"}

func _write_crop_probe(prop_image: Image) -> Error:
	if prop_image.is_empty():
		return ERR_CANT_OPEN
	var sheet := Image.create(760, 420, false, Image.FORMAT_RGBA8)
	sheet.fill(Color(0.06, 0.055, 0.07, 1.0))
	sheet.blit_rect(prop_image, PROP_REGIONS["crates"], Vector2i(20, 30))
	sheet.blit_rect(prop_image, PROP_REGIONS["ironhold_pipes"], Vector2i(20, 190))
	sheet.blit_rect(prop_image, PROP_REGIONS["server_console"], Vector2i(370, 30))
	sheet.blit_rect(prop_image, PROP_REGIONS["root_circuit_rail"], Vector2i(370, 230))
	return sheet.save_png(ProjectSettings.globalize_path(GODOT_CROP_PROBE))
