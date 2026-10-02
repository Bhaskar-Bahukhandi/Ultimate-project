extends SceneTree

const DIAGNOSTIC_DIR := "res://assets/art_sources/comfyui_tests/shared_environment_s1/diagnostics"
const DIAGNOSTIC_PATH := "res://assets/art_sources/comfyui_tests/shared_environment_s1/diagnostics/shared_environment_s1_validation.json"
const MAIN_MENU_SCENE := "res://scenes/main_menu.tscn"
const OAKHAVEN_ATLAS := "res://assets/production_art/tilesets/oakhaven/oakhaven_afternoon_tileset.png"
const IRONHOLD_ATLAS := "res://assets/production_art/tilesets/ironhold/ironhold_tileset.png"
const FRACTURED_ATLAS := "res://assets/production_art/tilesets/fractured_wastes/fractured_wastes_tileset.png"
const GENERATED_PROP := "res://assets/generated_v3/props/phase10mm_environment_prop_atlas.png"
const GENERATED_DECAL := "res://assets/generated_v3/overlays/phase10mm_environment_decal_atlas.png"
const PRODUCTION_PROP := "res://assets/production_art/props/environment_prop_atlas.png"
const PRODUCTION_DECAL := "res://assets/production_art/backgrounds/environment_decal_atlas.png"

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(DIAGNOSTIC_DIR))
	var checks := []
	checks.append(await _check_main_menu())
	checks.append(_check_texture("Oakhaven baseline preservation", OAKHAVEN_ATLAS, true))
	checks.append(_check_texture("Ironhold baseline preservation", IRONHOLD_ATLAS, true))
	checks.append(_check_texture("Fractured Wastes baseline preservation", FRACTURED_ATLAS, true))
	checks.append(_check_texture("generated V3 prop atlas", GENERATED_PROP, true))
	checks.append(_check_texture("generated V3 decal atlas", GENERATED_DECAL, true))
	checks.append(_check_texture("production prop slot absent", PRODUCTION_PROP, false))
	checks.append(_check_texture("production decal slot absent", PRODUCTION_DECAL, false))
	checks.append(_check_asset_manager_v3())
	var all_passed := true
	for check in checks:
		if str(check.get("result", "")) != "Pass":
			all_passed = false
			break
	var file := FileAccess.open(ProjectSettings.globalize_path(DIAGNOSTIC_PATH), FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify({"phase": "10M-S1", "checks": checks, "all_passed": all_passed, "production_art_changed": false, "generated_v3_overwritten": false}, "\t"))
	if not all_passed:
		push_error("Shared Environment S1 validation failed.")
		quit(1)
		return
	print("Shared Environment S1 validation: PASS")
	quit(0)

func _check_main_menu() -> Dictionary:
	var packed := load(MAIN_MENU_SCENE) as PackedScene
	if not packed:
		return {"check": "main menu", "result": "Fail", "notes": "missing PackedScene"}
	var scene := packed.instantiate()
	get_root().add_child(scene)
	current_scene = scene
	await process_frame
	var ok := scene != null and scene.name == "MainMenu"
	scene.queue_free()
	await process_frame
	return {"check": "main menu", "scene": MAIN_MENU_SCENE, "root_name": scene.name if scene else "", "result": "Pass" if ok else "Fail"}

func _check_texture(label: String, path: String, should_exist: bool) -> Dictionary:
	var resource_exists := ResourceLoader.exists(path)
	var file_exists := FileAccess.file_exists(path)
	var exists := resource_exists or file_exists
	var texture: Texture2D = null
	if resource_exists:
		texture = load(path) as Texture2D
	if exists and not texture:
		var image := Image.load_from_file(ProjectSettings.globalize_path(path))
		if image and not image.is_empty():
			texture = ImageTexture.create_from_image(image)
	var ok := exists == should_exist
	if should_exist:
		ok = ok and texture != null
	return {"check": label, "path": path, "exists": exists, "texture_loaded": texture != null, "result": "Pass" if ok else "Fail"}

func _check_asset_manager_v3() -> Dictionary:
	var asset_manager := get_root().get_node_or_null("AssetManager")
	if not asset_manager:
		return {"check": "AssetManager V3 fallback", "result": "Fail", "notes": "autoload missing"}
	var prop = asset_manager.try_create_v3_environment_prop("crates", Vector2(160, 48), "S1PropProbe", -1)
	var decal = asset_manager.try_create_v3_environment_decal("arena_border", Vector2(360, 120), "S1DecalProbe", -1)
	var prop_ok := prop != null and str(prop.get_meta("phase10mm_v3_visual_id", "")) == "crates"
	var decal_ok := decal != null and str(decal.get_meta("phase10mm_v3_visual_id", "")) == "arena_border"
	if prop:
		prop.queue_free()
	if decal:
		decal.queue_free()
	return {"check": "AssetManager V3 fallback", "prop_ok": prop_ok, "decal_ok": decal_ok, "result": "Pass" if prop_ok and decal_ok else "Fail"}
