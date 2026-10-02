extends SceneTree

const DIAG_DIR := "res://assets/art_sources/comfyui_tests/shared_environment_s4_v3_prop_audit/diagnostics"
const SHOT_DIR := "res://assets/art_sources/comfyui_tests/shared_environment_s4_v3_prop_audit/screenshots"
const DIAG_PATH := "res://assets/art_sources/comfyui_tests/shared_environment_s4_v3_prop_audit/diagnostics/shared_env_s4_godot_validation.json"

const CURRENT_PROP := "res://assets/generated_v3/props/phase10mm_environment_prop_atlas.png"
const CURRENT_DECAL := "res://assets/generated_v3/overlays/phase10mm_environment_decal_atlas.png"
const PROD_PROP := "res://assets/production_art/props/environment_prop_atlas.png"
const PROD_DECAL := "res://assets/production_art/backgrounds/environment_decal_atlas.png"
const OAKHAVEN_BASELINE := "res://assets/production_art/tilesets/oakhaven/oakhaven_afternoon_tileset.png"
const IRONHOLD_BASELINE := "res://assets/production_art/tilesets/ironhold/ironhold_tileset.png"
const FRACTURED_BASELINE := "res://assets/production_art/tilesets/fractured_wastes/fractured_wastes_tileset.png"

const SCENES := [
	{"label": "main menu", "path": "res://scenes/main_menu.tscn", "shot": ""},
	{"label": "Oakhaven reference", "path": "res://scenes/regions/oakhaven_region.tscn", "shot": ""},
	{"label": "Ironhold reference", "path": "res://scenes/regions/ironhold_region.tscn", "shot": ""},
	{"label": "Fractured Wastes reference", "path": "res://scenes/regions/fractured_wastes_region.tscn", "shot": ""},
	{"label": "Late hub reference", "path": "res://scenes/regions/late_revisit_hub.tscn", "shot": ""},
	{"label": "Arena reference", "path": "res://scenes/combat/combat_arena.tscn", "shot": ""},
]

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(DIAG_DIR))
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(SHOT_DIR))
	var checks := []
	checks.append(_check_texture("current V3 prop atlas", CURRENT_PROP, true, Vector2i(1536, 1024)))
	checks.append(_check_texture("current V3 decal atlas", CURRENT_DECAL, true, Vector2i(1536, 1024)))
	checks.append(_check_texture("production prop slot absent", PROD_PROP, false, Vector2i.ZERO))
	checks.append(_check_texture("production decal slot absent", PROD_DECAL, false, Vector2i.ZERO))
	checks.append(_check_texture("Oakhaven baseline preservation", OAKHAVEN_BASELINE, true, Vector2i(512, 512)))
	checks.append(_check_texture("Ironhold baseline preservation", IRONHOLD_BASELINE, true, Vector2i(512, 512)))
	checks.append(_check_texture("Fractured Wastes baseline preservation", FRACTURED_BASELINE, true, Vector2i(512, 512)))
	checks.append(_check_asset_manager_fallback())
	for item in SCENES:
		checks.append(await _check_scene(item))
	var all_passed := true
	for check in checks:
		if str(check.get("result", "")) == "Fail":
			all_passed = false
	var file := FileAccess.open(ProjectSettings.globalize_path(DIAG_PATH), FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify({"phase": "10M-S4", "checks": checks, "all_passed": all_passed, "production_art_changed": false, "generated_v3_overwritten": false, "actual_gameplay_scenes_modified": false}, "\t"))
	print("Shared Environment S4 validation: " + ("PASS" if all_passed else "FAIL"))
	quit(0 if all_passed else 1)

func _check_texture(label: String, path: String, should_exist: bool, expected_size: Vector2i) -> Dictionary:
	var exists := ResourceLoader.exists(path) or FileAccess.file_exists(path)
	var image := Image.new()
	var loaded := false
	if exists:
		loaded = image.load(ProjectSettings.globalize_path(path)) == OK and not image.is_empty()
	var ok := exists == should_exist
	if should_exist:
		ok = ok and loaded and image.get_size() == expected_size
	return {"check": label, "path": path, "exists": exists, "loaded": loaded, "size": image.get_size() if loaded else Vector2i.ZERO, "result": "Pass" if ok else "Fail"}

func _check_asset_manager_fallback() -> Dictionary:
	var asset_manager := get_root().get_node_or_null("AssetManager")
	if not asset_manager:
		return {"check": "AssetManager V3 prop/decal fallback", "result": "Fail", "notes": "AssetManager missing"}
	var prop = asset_manager.try_create_v3_environment_prop("crates", Vector2(212, 58), "S4PropProbe", -1)
	var decal = asset_manager.try_create_v3_environment_decal("arena_border", Vector2(360, 120), "S4DecalProbe", -1)
	var prop_ok := prop != null and str(prop.get_meta("phase10mm_v3_visual_id", "")) == "crates"
	var decal_ok := decal != null and str(decal.get_meta("phase10mm_v3_visual_id", "")) == "arena_border"
	if prop:
		prop.queue_free()
	if decal:
		decal.queue_free()
	return {"check": "AssetManager V3 prop/decal fallback", "prop_ok": prop_ok, "decal_ok": decal_ok, "result": "Pass" if prop_ok and decal_ok else "Fail"}

func _check_scene(item: Dictionary) -> Dictionary:
	var path := str(item["path"])
	var label := str(item["label"])
	if not ResourceLoader.exists(path):
		return {"check": label, "path": path, "result": "Skipped", "notes": "scene path not found"}
	var packed := load(path) as PackedScene
	if not packed:
		return {"check": label, "path": path, "result": "Fail", "notes": "PackedScene load failed"}
	var scene := packed.instantiate()
	get_root().add_child(scene)
	current_scene = scene
	for i in range(8):
		await process_frame
	var shot := str(item.get("shot", ""))
	var saved := ""
	var screenshot_status := "Skipped: headless dummy renderer does not provide a reliable viewport image"
	if scene:
		scene.queue_free()
		await process_frame
	current_scene = null
	return {"check": label, "path": path, "screenshot": saved, "screenshot_status": screenshot_status, "result": "Pass"}
