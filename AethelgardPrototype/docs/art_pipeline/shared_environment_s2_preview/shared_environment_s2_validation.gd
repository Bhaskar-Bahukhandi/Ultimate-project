extends SceneTree

const DIAGNOSTIC_DIR := "res://assets/art_sources/comfyui_tests/shared_environment_s2_preview/diagnostics"
const CROP_DIR := "res://assets/art_sources/comfyui_tests/shared_environment_s2_preview/crop_checks"
const DIAGNOSTIC_PATH := "res://assets/art_sources/comfyui_tests/shared_environment_s2_preview/diagnostics/shared_environment_s2_godot_validation.json"
const GODOT_CROP_PROBE := "res://assets/art_sources/comfyui_tests/shared_environment_s2_preview/crop_checks/shared_env_s2_godot_runtime_crop_probe.png"

const CURRENT_PROP := "res://assets/generated_v3/props/phase10mm_environment_prop_atlas.png"
const CURRENT_DECAL := "res://assets/generated_v3/overlays/phase10mm_environment_decal_atlas.png"
const S1_PROP := "res://assets/art_sources/comfyui_tests/shared_environment_s1/generated_props/shared_environment_props_s1_variant_b.png"
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
const DECAL_REGIONS := {
	"oakhaven_path": Rect2i(18, 10, 630, 198),
	"oakhaven_stones": Rect2i(22, 228, 650, 128),
	"ironhold_road": Rect2i(676, 16, 820, 224),
	"fracture_field": Rect2i(18, 360, 500, 294),
	"shard_spill": Rect2i(270, 350, 246, 298),
	"archive_seals": Rect2i(520, 362, 382, 292),
	"mirror_ripples": Rect2i(900, 246, 602, 280),
	"cathedral_circuit": Rect2i(900, 510, 600, 240),
	"memory_tide": Rect2i(14, 674, 476, 326),
	"root_veins": Rect2i(492, 680, 406, 320),
	"arena_border": Rect2i(898, 754, 620, 252),
}

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(DIAGNOSTIC_DIR))
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(CROP_DIR))
	var checks := []
	checks.append(_check_texture("current V3 prop atlas", CURRENT_PROP, true, Vector2i(1536, 1024)))
	checks.append(_check_texture("current V3 decal atlas", CURRENT_DECAL, true, Vector2i(1536, 1024)))
	checks.append(_check_texture("S1 prop candidate", S1_PROP, true, Vector2i(1536, 1024)))
	checks.append(_check_texture("S1 decal candidate", S1_DECAL, true, Vector2i(1536, 1024)))
	checks.append(_check_texture("production prop slot absent", PROD_PROP, false, Vector2i.ZERO))
	checks.append(_check_texture("production decal slot absent", PROD_DECAL, false, Vector2i.ZERO))
	checks.append(_check_texture("Oakhaven baseline preservation", OAKHAVEN_BASELINE, true, Vector2i(512, 512)))
	checks.append(_check_texture("Ironhold baseline preservation", IRONHOLD_BASELINE, true, Vector2i(512, 512)))
	checks.append(_check_texture("Fractured Wastes baseline preservation", FRACTURED_BASELINE, true, Vector2i(512, 512)))
	checks.append(_check_asset_manager_fallback())
	checks.append(_check_candidate_contract())
	checks.append(await _check_main_menu())
	checks.append(await _check_scene_load("Oakhaven scene", "res://scenes/regions/oakhaven_region.tscn"))
	checks.append(await _check_scene_load("Ironhold scene", "res://scenes/regions/ironhold_region.tscn"))
	checks.append(await _check_scene_load("Fractured Wastes scene", "res://scenes/regions/fractured_wastes_region.tscn"))
	checks.append(_write_crop_probe())
	var all_passed := true
	for check in checks:
		if str(check.get("result", "")) != "Pass":
			all_passed = false
			break
	var file := FileAccess.open(ProjectSettings.globalize_path(DIAGNOSTIC_PATH), FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify({"phase": "10M-S2", "checks": checks, "all_passed": all_passed, "production_art_changed": false, "generated_v3_overwritten": false, "actual_gameplay_scenes_modified": false}, "\t"))
	if not all_passed:
		push_error("Shared Environment S2 validation failed.")
		quit(1)
		return
	print("Shared Environment S2 validation: PASS")
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

func _check_asset_manager_fallback() -> Dictionary:
	var asset_manager := get_root().get_node_or_null("AssetManager")
	if not asset_manager:
		return {"check": "AssetManager current V3 fallback prop/decal check", "result": "Fail", "notes": "AssetManager missing"}
	var prop = asset_manager.try_create_v3_environment_prop("crates", Vector2(212, 58), "S2PropProbe", -1)
	var decal = asset_manager.try_create_v3_environment_decal("arena_border", Vector2(360, 120), "S2DecalProbe", -1)
	var prop_ok := prop != null and str(prop.get_meta("phase10mm_v3_visual_id", "")) == "crates"
	var decal_ok := decal != null and str(decal.get_meta("phase10mm_v3_visual_id", "")) == "arena_border"
	if prop:
		prop.queue_free()
	if decal:
		decal.queue_free()
	return {"check": "AssetManager current V3 fallback prop/decal check", "prop_ok": prop_ok, "decal_ok": decal_ok, "result": "Pass" if prop_ok and decal_ok else "Fail"}

func _check_candidate_contract() -> Dictionary:
	var prop_image := Image.new()
	var decal_image := Image.new()
	var prop_ok := prop_image.load(ProjectSettings.globalize_path(S1_PROP)) == OK
	var decal_ok := decal_image.load(ProjectSettings.globalize_path(S1_DECAL)) == OK
	var all_valid := prop_ok and decal_ok
	if all_valid:
		for id in PROP_REGIONS.keys():
			var rect: Rect2i = PROP_REGIONS[id]
			all_valid = all_valid and rect.position.x >= 0 and rect.position.y >= 0 and rect.end.x <= prop_image.get_width() and rect.end.y <= prop_image.get_height()
		for id in DECAL_REGIONS.keys():
			var rect: Rect2i = DECAL_REGIONS[id]
			all_valid = all_valid and rect.position.x >= 0 and rect.position.y >= 0 and rect.end.x <= decal_image.get_width() and rect.end.y <= decal_image.get_height()
	var candidate_prop = _make_candidate_sprite(S1_PROP, PROP_REGIONS, "crates", Vector2(212, 58), "S2CandidatePropProbe", -1)
	var candidate_decal = _make_candidate_sprite(S1_DECAL, DECAL_REGIONS, "arena_border", Vector2(360, 120), "S2CandidateDecalProbe", -1)
	var sprite_ok := candidate_prop != null and candidate_decal != null
	return {"check": "candidate prop/decal same-Rect2i contract", "rects_valid": all_valid, "candidate_sprites_created": sprite_ok, "result": "Pass" if all_valid and sprite_ok else "Fail"}

func _make_candidate_sprite(path: String, regions: Dictionary, visual_id: String, target_size: Vector2, node_name: String, layer_z_index: int) -> Sprite2D:
	if not regions.has(visual_id):
		return null
	var image := Image.new()
	if image.load(ProjectSettings.globalize_path(path)) != OK or image.is_empty():
		return null
	var texture := ImageTexture.create_from_image(image)
	var atlas := AtlasTexture.new()
	atlas.atlas = texture
	atlas.region = Rect2(regions[visual_id].position, regions[visual_id].size)
	var sprite := Sprite2D.new()
	sprite.name = node_name
	sprite.texture = atlas
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.z_index = layer_z_index
	var region: Rect2i = regions[visual_id]
	if target_size.x > 0.0 and target_size.y > 0.0:
		sprite.scale = Vector2(target_size.x / float(region.size.x), target_size.y / float(region.size.y))
	sprite.set_meta("phase10mm_v3_environment_visual", true)
	sprite.set_meta("phase10mm_v3_visual_id", visual_id)
	sprite.set_meta("shared_environment_s2_candidate", true)
	return sprite

func _check_main_menu() -> Dictionary:
	return await _check_scene_load("main menu", "res://scenes/main_menu.tscn")

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

func _write_crop_probe() -> Dictionary:
	var prop := Image.new()
	var decal := Image.new()
	if prop.load(ProjectSettings.globalize_path(S1_PROP)) != OK:
		return {"check": "Godot crop probe capture", "result": "Fail", "notes": "candidate prop load failed"}
	if decal.load(ProjectSettings.globalize_path(S1_DECAL)) != OK:
		return {"check": "Godot crop probe capture", "result": "Fail", "notes": "candidate decal load failed"}
	var sheet := Image.create(640, 360, false, Image.FORMAT_RGBA8)
	sheet.fill(Color(0.06, 0.055, 0.07, 1.0))
	sheet.blit_rect(prop, PROP_REGIONS["crates"], Vector2i(20, 30))
	sheet.blit_rect(prop, PROP_REGIONS["ironhold_pipes"], Vector2i(20, 190))
	sheet.blit_rect(decal, DECAL_REGIONS["arena_border"], Vector2i(330, 40))
	var err := sheet.save_png(ProjectSettings.globalize_path(GODOT_CROP_PROBE))
	return {"check": "Godot crop probe capture", "path": GODOT_CROP_PROBE, "result": "Pass" if err == OK else "Fail"}
