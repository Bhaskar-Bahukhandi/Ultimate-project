extends SceneTree

const SCREENSHOT_DIR := "res://assets/art_sources/comfyui_tests/fractured_wastes_r3_import_preview/screenshots"
const CONTACT_DIR := "res://assets/art_sources/comfyui_tests/fractured_wastes_r3_import_preview/contact_sheets"
const MOCKUP_DIR := "res://assets/art_sources/comfyui_tests/fractured_wastes_r3_import_preview/mockups"
const MANIFEST_DIR := "res://assets/art_sources/comfyui_tests/fractured_wastes_r3_import_preview/manifest"
const DIAGNOSTIC_DIR := "res://assets/art_sources/comfyui_tests/fractured_wastes_r3_import_preview/diagnostics"
const DIAGNOSTIC_PATH := "res://assets/art_sources/comfyui_tests/fractured_wastes_r3_import_preview/diagnostics/fractured_wastes_r3_capture_diagnostics.json"
const CONTACT_SHEET := "res://assets/art_sources/comfyui_tests/fractured_wastes_r3_import_preview/contact_sheets/fractured_wastes_r3_fallback_vs_production_contact_sheet.png"
const ACTUAL_CONTACT_SHEET := "res://assets/art_sources/comfyui_tests/fractured_wastes_r3_import_preview/contact_sheets/fractured_wastes_r3_actual_region_contact_sheet.png"

const FALLBACK_PATH := "res://assets/generated_v2/tilesets/fractured_wastes_v2_prototype_tileset.png"
const VARIANT_B_PATH := "res://assets/art_sources/comfyui_tests/fractured_wastes_r1/generated_tiles/fractured_wastes_r1_variant_b_textured.png"
const PRODUCTION_PATH := "res://assets/production_art/tilesets/fractured_wastes/fractured_wastes_tileset.png"
const FRACTURED_WASTES_SCENE := "res://scenes/regions/fractured_wastes_region.tscn"

const TILE_SIZE := 32
const BOARD_W := 24
const BOARD_H := 18
const BOARD_ORIGIN := Vector2(56, 96)
const VIEWPORT_SIZE := Vector2i(1280, 720)

const CAPTURES := [
	{
		"id": "fallback",
		"title": "Fractured Wastes generated fallback",
		"texture": FALLBACK_PATH,
		"output": "res://assets/art_sources/comfyui_tests/fractured_wastes_r3_import_preview/screenshots/fractured_wastes_r3_fallback_preview.png",
		"fallback": true,
	},
	{
		"id": "production_variant_b",
		"title": "Fractured Wastes production Variant B",
		"texture": PRODUCTION_PATH,
		"output": "res://assets/art_sources/comfyui_tests/fractured_wastes_r3_import_preview/screenshots/fractured_wastes_r3_production_variant_b_preview.png",
		"fallback": false,
	},
]

const ACTUAL_VIEWS := [
	{
		"id": "fallback",
		"label": "Actual Fractured Wastes fallback",
		"focus": Vector2(1400, 1900),
		"output": "res://assets/art_sources/comfyui_tests/fractured_wastes_r3_import_preview/screenshots/fractured_wastes_r3_actual_region_fallback.png",
		"force_fallback": true,
	},
	{
		"id": "production",
		"label": "Actual Fractured Wastes production Variant B",
		"focus": Vector2(1400, 1900),
		"output": "res://assets/art_sources/comfyui_tests/fractured_wastes_r3_import_preview/screenshots/fractured_wastes_r3_actual_region_production.png",
		"force_fallback": false,
	},
	{
		"id": "spawn",
		"label": "Spawn / shelter production",
		"focus": Vector2(1400, 1900),
		"output": "res://assets/art_sources/comfyui_tests/fractured_wastes_r3_import_preview/screenshots/fractured_wastes_r3_actual_region_spawn.png",
		"force_fallback": false,
	},
	{
		"id": "path",
		"label": "Core path production",
		"focus": Vector2(1400, 1500),
		"output": "res://assets/art_sources/comfyui_tests/fractured_wastes_r3_import_preview/screenshots/fractured_wastes_r3_actual_region_path.png",
		"force_fallback": false,
	},
	{
		"id": "farming",
		"label": "Shard farming production",
		"focus": Vector2(2040, 760),
		"output": "res://assets/art_sources/comfyui_tests/fractured_wastes_r3_import_preview/screenshots/fractured_wastes_r3_actual_region_farming.png",
		"force_fallback": false,
	},
	{
		"id": "npc",
		"label": "Lyra / survivor label production",
		"focus": Vector2(1320, 1880),
		"output": "res://assets/art_sources/comfyui_tests/fractured_wastes_r3_import_preview/screenshots/fractured_wastes_r3_actual_region_npc.png",
		"force_fallback": false,
	},
	{
		"id": "rift_or_core",
		"label": "Rift / core production",
		"focus": Vector2(1500, 1500),
		"output": "res://assets/art_sources/comfyui_tests/fractured_wastes_r3_import_preview/screenshots/fractured_wastes_r3_actual_region_rift_or_core.png",
		"force_fallback": false,
	},
]

const R1_TILES := {
	"base": Vector2i(0, 0),
	"base_alt": Vector2i(1, 0),
	"ash": Vector2i(2, 0),
	"soil": Vector2i(3, 0),
	"scorch": Vector2i(4, 0),
	"stone": Vector2i(5, 0),
	"quiet": Vector2i(6, 0),
	"shadow": Vector2i(7, 0),
	"corrupt_ground": Vector2i(8, 0),
	"rubble_ground": Vector2i(9, 0),
	"path_center": Vector2i(0, 3),
	"path_h": Vector2i(1, 3),
	"path_v": Vector2i(2, 3),
	"path_corner_ne": Vector2i(3, 3),
	"path_corner_nw": Vector2i(4, 3),
	"path_corner_se": Vector2i(5, 3),
	"path_corner_sw": Vector2i(6, 3),
	"path_t_n": Vector2i(7, 3),
	"path_t_s": Vector2i(8, 3),
	"path_t_e": Vector2i(9, 3),
	"path_t_w": Vector2i(10, 3),
	"path_cross": Vector2i(11, 3),
	"path_end_n": Vector2i(12, 3),
	"path_end_s": Vector2i(13, 3),
	"path_end_e": Vector2i(14, 3),
	"path_end_w": Vector2i(15, 3),
	"stepping": Vector2i(0, 4),
	"dust_trail": Vector2i(1, 4),
	"scar": Vector2i(0, 9),
	"fracture_h": Vector2i(1, 9),
	"fracture_v": Vector2i(2, 9),
	"fracture_corner": Vector2i(3, 9),
	"rift": Vector2i(4, 9),
	"corrupt_patch": Vector2i(5, 9),
	"unstable": Vector2i(6, 9),
	"corrupt_pool": Vector2i(7, 9),
	"magenta_spark": Vector2i(8, 9),
	"anomaly": Vector2i(9, 9),
	"sealed_scar": Vector2i(10, 9),
	"fading_edge": Vector2i(11, 9),
	"stone_prop": Vector2i(0, 11),
	"rubble": Vector2i(1, 11),
	"collapsed_wall": Vector2i(2, 11),
	"pillar_base": Vector2i(3, 11),
	"pillar_top": Vector2i(4, 11),
	"slab": Vector2i(5, 11),
	"metal": Vector2i(6, 11),
	"marker_stone": Vector2i(7, 11),
	"broken_sign": Vector2i(8, 11),
	"wall_h": Vector2i(9, 11),
	"wall_v": Vector2i(10, 11),
	"ruin_corner": Vector2i(11, 11),
	"dead_scrub": Vector2i(0, 13),
	"thorn": Vector2i(1, 13),
	"dry_grass": Vector2i(2, 13),
	"root": Vector2i(3, 13),
	"stump": Vector2i(4, 13),
	"bone": Vector2i(5, 13),
	"flower": Vector2i(6, 13),
	"crate": Vector2i(7, 13),
	"campfire": Vector2i(8, 13),
	"cloth": Vector2i(9, 13),
	"salvage": Vector2i(10, 13),
	"warning": Vector2i(11, 13),
	"hazard_crack": Vector2i(12, 13),
	"vent": Vector2i(13, 13),
	"unstable_edge": Vector2i(14, 13),
	"shallow_stain": Vector2i(15, 13),
	"deep_stain": Vector2i(0, 14),
	"hazard_boundary": Vector2i(2, 14),
	"safe_boundary": Vector2i(3, 14),
	"shadow_only": Vector2i(1, 15),
	"violet_spark": Vector2i(4, 15),
	"cyan_spark": Vector2i(5, 15),
	"separator": Vector2i(7, 15),
}

const FALLBACK_TILES := {
	"base": Vector2i(1, 0),
	"base_alt": Vector2i(3, 1),
	"ash": Vector2i(1, 1),
	"soil": Vector2i(1, 0),
	"scorch": Vector2i(3, 0),
	"stone": Vector2i(1, 1),
	"quiet": Vector2i(1, 0),
	"shadow": Vector2i(3, 0),
	"corrupt_ground": Vector2i(0, 0),
	"rubble_ground": Vector2i(3, 1),
	"path_center": Vector2i(1, 1),
	"path_h": Vector2i(3, 1),
	"path_v": Vector2i(3, 1),
	"path_corner_ne": Vector2i(3, 1),
	"path_corner_nw": Vector2i(3, 1),
	"path_corner_se": Vector2i(3, 1),
	"path_corner_sw": Vector2i(3, 1),
	"path_t_n": Vector2i(3, 1),
	"path_t_s": Vector2i(3, 1),
	"path_t_e": Vector2i(3, 1),
	"path_t_w": Vector2i(3, 1),
	"path_cross": Vector2i(3, 1),
	"path_end_n": Vector2i(3, 1),
	"path_end_s": Vector2i(3, 1),
	"path_end_e": Vector2i(3, 1),
	"path_end_w": Vector2i(3, 1),
	"stepping": Vector2i(1, 1),
	"dust_trail": Vector2i(1, 0),
	"scar": Vector2i(0, 0),
	"fracture_h": Vector2i(0, 0),
	"fracture_v": Vector2i(0, 0),
	"fracture_corner": Vector2i(2, 1),
	"rift": Vector2i(2, 0),
	"corrupt_patch": Vector2i(0, 1),
	"unstable": Vector2i(3, 0),
	"corrupt_pool": Vector2i(2, 1),
	"magenta_spark": Vector2i(2, 0),
	"anomaly": Vector2i(0, 1),
	"sealed_scar": Vector2i(3, 1),
	"fading_edge": Vector2i(0, 0),
	"stone_prop": Vector2i(1, 1),
	"rubble": Vector2i(1, 1),
	"collapsed_wall": Vector2i(3, 1),
	"pillar_base": Vector2i(3, 0),
	"pillar_top": Vector2i(3, 0),
	"slab": Vector2i(1, 1),
	"metal": Vector2i(3, 1),
	"marker_stone": Vector2i(1, 1),
	"broken_sign": Vector2i(3, 1),
	"wall_h": Vector2i(1, 1),
	"wall_v": Vector2i(1, 1),
	"ruin_corner": Vector2i(3, 1),
	"dead_scrub": Vector2i(1, 0),
	"thorn": Vector2i(0, 0),
	"dry_grass": Vector2i(1, 1),
	"root": Vector2i(3, 1),
	"stump": Vector2i(1, 1),
	"bone": Vector2i(3, 1),
	"flower": Vector2i(2, 0),
	"crate": Vector2i(1, 1),
	"campfire": Vector2i(1, 0),
	"cloth": Vector2i(3, 1),
	"salvage": Vector2i(1, 1),
	"warning": Vector2i(2, 0),
	"hazard_crack": Vector2i(0, 0),
	"vent": Vector2i(0, 1),
	"unstable_edge": Vector2i(3, 0),
	"shallow_stain": Vector2i(2, 1),
	"deep_stain": Vector2i(2, 1),
	"hazard_boundary": Vector2i(2, 0),
	"safe_boundary": Vector2i(1, 1),
	"shadow_only": Vector2i(3, 0),
	"violet_spark": Vector2i(2, 0),
	"cyan_spark": Vector2i(0, 1),
	"separator": Vector2i(3, 1),
}

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	get_root().size = VIEWPORT_SIZE
	for path in [SCREENSHOT_DIR, CONTACT_DIR, MOCKUP_DIR, MANIFEST_DIR, DIAGNOSTIC_DIR]:
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(path))

	var preview_results := []
	for capture in CAPTURES:
		preview_results.append(await _capture_preview(capture))

	var actual_results := []
	var packed := load(FRACTURED_WASTES_SCENE) as PackedScene
	if packed:
		for view in ACTUAL_VIEWS:
			actual_results.append(await _capture_actual_region_view(packed, view))
	else:
		actual_results.append({"result": "Skipped", "reason": "Fractured Wastes region scene failed to load."})

	var contact_result := _build_contact_sheet()
	var actual_contact_result := _build_actual_contact_sheet()
	var data := {
		"phase": "10M-R3",
		"previews": preview_results,
		"actual_region_captures": actual_results,
		"contact_sheet": contact_result,
		"actual_contact_sheet": actual_contact_result,
		"production_art_changed": true,
		"actual_scene_modified": false,
	}
	var file := FileAccess.open(ProjectSettings.globalize_path(DIAGNOSTIC_PATH), FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(data, "\t"))
	print("Fractured Wastes R3 import preview capture: PASS")
	quit(0)

func _capture_preview(capture: Dictionary) -> Dictionary:
	await _clear_current_scene()
	var resolved := _resolve_preview_texture(capture)
	var texture := resolved.get("texture") as Texture2D
	if not texture:
		push_error("R3 could not load preview texture: %s" % capture["texture"])
		quit(1)
		return {}

	var root := Node2D.new()
	root.name = "FracturedWastesR3PreviewRoot"
	get_root().add_child(root)
	current_scene = root
	_build_preview_board(root, texture, bool(capture.get("fallback", false)), str(capture["title"]))
	await _settle_frames(6)

	var output := str(capture["output"])
	var result := _save_viewport(output)
	_copy_preview_to_mockups(output)
	return {
		"id": str(capture["id"]),
		"title": str(capture["title"]),
		"texture": str(resolved.get("path", capture["texture"])),
		"loaded_through_asset_manager": bool(resolved.get("loaded_through_asset_manager", false)),
		"production": bool(resolved.get("production", false)),
		"fallback_used": bool(resolved.get("fallback_used", false)),
		"fallback_reason": str(resolved.get("fallback_reason", "")),
		"screenshot": output,
		"texture_size": "%dx%d" % [texture.get_width(), texture.get_height()],
		"result": result,
	}

func _resolve_preview_texture(capture: Dictionary) -> Dictionary:
	var asset_manager := _get_asset_manager()
	if asset_manager and asset_manager.has_method("set_fractured_wastes_force_generated_fallback") and asset_manager.has_method("get_fractured_wastes_tileset_slot"):
		asset_manager.set_fractured_wastes_force_generated_fallback(bool(capture.get("fallback", false)))
		var slot: Dictionary = asset_manager.get_fractured_wastes_tileset_slot()
		asset_manager.set_fractured_wastes_force_generated_fallback(false)
		if slot.get("texture") != null:
			slot["loaded_through_asset_manager"] = true
			return slot

	var texture := _load_texture_path(str(capture["texture"]))
	return {
		"texture": texture,
		"path": str(capture["texture"]),
		"production": not bool(capture.get("fallback", false)),
		"fallback_used": bool(capture.get("fallback", false)),
		"fallback_reason": "direct texture load fallback",
		"loaded_through_asset_manager": false,
	}

func _build_preview_board(root: Node2D, texture: Texture2D, fallback: bool, title: String) -> void:
	var bg := ColorRect.new()
	bg.color = Color(0.035, 0.03, 0.04, 1.0)
	bg.size = Vector2(VIEWPORT_SIZE)
	root.add_child(bg)

	root.add_child(_make_label(title, Vector2(30, 22), 24, Color(0.92, 0.84, 0.72)))
	root.add_child(_make_label("24x18 preview board - safe path, corruption/rift zone, labels, hazards, ruins, dead scrub - preview only", Vector2(30, 55), 13, Color(0.72, 0.70, 0.74)))

	var tile_map: Dictionary = FALLBACK_TILES if fallback else R1_TILES
	var cols: int = max(1, int(texture.get_width() / TILE_SIZE))
	var rows: int = max(1, int(texture.get_height() / TILE_SIZE))

	for y in range(BOARD_H):
		for x in range(BOARD_W):
			var key := "base"
			if x > 15 and y < 8:
				key = "corrupt_ground" if (x + y) % 3 == 0 else "shadow"
			elif x < 5 and y > 12:
				key = "scorch" if (x + y) % 2 == 0 else "shadow"
			elif x in [2, 5, 10, 14, 20]:
				key = "quiet"
			elif (x * 13 + y * 5) % 19 == 0:
				key = "stone"
			elif (x * 7 + y * 11) % 17 == 0:
				key = "base_alt"
			_add_tile(root, texture, _coord(tile_map, key, cols, rows), x, y)

	var path_cells := {}
	for x in range(1, 8):
		path_cells[Vector2i(x, 13)] = true
	for y in range(8, 14):
		path_cells[Vector2i(7, y)] = true
	for x in range(7, 15):
		path_cells[Vector2i(x, 8)] = true
	for y in range(4, 9):
		path_cells[Vector2i(14, y)] = true
	for x in range(14, 22):
		path_cells[Vector2i(x, 4)] = true
	for y in range(4, 12):
		path_cells[Vector2i(21, y)] = true
	for x in range(11, 15):
		path_cells[Vector2i(x, 12)] = true
	for y in range(9, 13):
		path_cells[Vector2i(11, y)] = true

	for cell in path_cells.keys():
		_add_tile(root, texture, _coord(tile_map, _path_key_for(cell, path_cells), cols, rows), cell.x, cell.y)

	for item in [
		[17, 6, "shallow_stain"], [18, 6, "scar"], [19, 6, "fracture_h"], [20, 6, "rift"],
		[18, 7, "unstable"], [19, 7, "deep_stain"], [20, 7, "warning"], [17, 8, "fading_edge"],
		[21, 8, "hazard_boundary"], [22, 10, "anomaly"], [22, 3, "violet_spark"],
		[4, 4, "wall_h"], [5, 4, "wall_h"], [6, 4, "ruin_corner"], [4, 5, "pillar_base"],
		[6, 5, "collapsed_wall"], [5, 6, "rubble"], [2, 14, "dead_scrub"], [3, 15, "thorn"],
		[5, 15, "root"], [9, 13, "crate"], [10, 13, "campfire"], [12, 14, "salvage"],
		[15, 3, "safe_boundary"], [13, 12, "hazard_boundary"], [16, 13, "bone"], [18, 13, "flower"],
		[11, 14, "cloth"], [3, 12, "stepping"], [4, 12, "dust_trail"], [19, 14, "cyan_spark"],
	]:
		_add_tile(root, texture, _coord(tile_map, str(item[2]), cols, rows), int(item[0]), int(item[1]))

	_add_marker(root, Vector2i(7, 12), Color(0.08, 0.76, 0.96), "Player", Color(0.86, 0.98, 1.0))
	_add_marker(root, Vector2i(10, 8), Color(0.78, 0.36, 0.86), "Lyra", Color.WHITE)
	_add_marker(root, Vector2i(12, 13), Color(0.62, 0.56, 0.45), "Survivor", Color.WHITE)
	root.add_child(_make_label("[F] Talk", _tile_pos(Vector2i(10, 8)) + Vector2(-4, 27), 13, Color(1.0, 0.96, 0.55)))
	root.add_child(_make_label("[E] Inspect scar", _tile_pos(Vector2i(18, 7)) + Vector2(-4, 36), 12, Color(1.0, 0.62, 0.95)))
	root.add_child(_make_label("Readable safe path", _tile_pos(Vector2i(1, 12)) + Vector2(-12, -18), 15, Color(0.98, 0.88, 0.60)))
	root.add_child(_make_label("Corruption/rift zone", _tile_pos(Vector2i(17, 5)) + Vector2(-2, -22), 13, Color(1.0, 0.46, 0.96)))
	root.add_child(_make_label("Dark corner contrast", _tile_pos(Vector2i(1, 16)) + Vector2(-2, 32), 12, Color(0.76, 0.76, 0.82)))
	root.add_child(_make_label("Hazard-looking art only - no collision change", Vector2(846, 620), 13, Color(0.86, 0.78, 0.64)))

	var atlas_preview := TextureRect.new()
	atlas_preview.texture = texture
	atlas_preview.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	atlas_preview.position = Vector2(870, 108)
	atlas_preview.size = Vector2(256, 256)
	atlas_preview.stretch_mode = TextureRect.STRETCH_SCALE
	root.add_child(atlas_preview)
	root.add_child(_make_label("Source atlas", Vector2(870, 374), 13, Color(0.75, 0.72, 0.72)))

func _path_key_for(cell: Vector2i, cells: Dictionary) -> String:
	var n := cells.has(cell + Vector2i(0, -1))
	var e := cells.has(cell + Vector2i(1, 0))
	var s := cells.has(cell + Vector2i(0, 1))
	var w := cells.has(cell + Vector2i(-1, 0))
	var count := int(n) + int(e) + int(s) + int(w)
	if count >= 4:
		return "path_cross"
	if count == 3:
		if not n:
			return "path_t_s"
		if not s:
			return "path_t_n"
		if not e:
			return "path_t_w"
		return "path_t_e"
	if count == 2:
		if e and w:
			return "path_h"
		if n and s:
			return "path_v"
		if n and e:
			return "path_corner_ne"
		if n and w:
			return "path_corner_nw"
		if s and e:
			return "path_corner_se"
		return "path_corner_sw"
	if count == 1:
		if n:
			return "path_end_n"
		if s:
			return "path_end_s"
		if e:
			return "path_end_e"
		return "path_end_w"
	return "path_center"

func _capture_actual_region_view(packed: PackedScene, view: Dictionary) -> Dictionary:
	await _clear_current_scene()
	var asset_manager := _get_asset_manager()
	if asset_manager and asset_manager.has_method("set_fractured_wastes_force_generated_fallback"):
		asset_manager.set_fractured_wastes_force_generated_fallback(bool(view.get("force_fallback", false)))
	var scene := packed.instantiate()
	get_root().add_child(scene)
	current_scene = scene
	await _settle_frames(14)
	var focus: Vector2 = view["focus"]
	var player := _find_node_by_name(scene, "Player") as Node2D
	if player:
		player.global_position = focus
	var camera := _find_node_by_name(scene, "RegionCamera") as Camera2D
	if camera:
		camera.position_smoothing_enabled = false
		camera.global_position = focus
		camera.make_current()
		camera.reset_smoothing()
	await _settle_frames(14)

	var visual_layer := _find_node_by_name(scene, "V2WastesGroundTiles")
	var farming_marker := _find_node_by_name(scene, "ShardFieldsFarming")
	var lyra := _find_node_by_name(scene, "Lyra")
	var survivor := _find_node_by_name(scene, "SurvivorKael")
	var output := str(view["output"])
	var result := _save_viewport(output)
	if asset_manager and asset_manager.has_method("set_fractured_wastes_force_generated_fallback"):
		asset_manager.set_fractured_wastes_force_generated_fallback(false)
	return {
		"id": str(view["id"]),
		"label": str(view["label"]),
		"screenshot": output,
		"result": result,
		"force_fallback": bool(view.get("force_fallback", false)),
		"player_found": player != null,
		"camera_found": camera != null,
		"visual_layer_found": visual_layer != null,
		"visual_layer_path": "" if visual_layer == null else str(visual_layer.get_meta("visual_tileset_path", "")),
		"visual_layer_production": false if visual_layer == null else bool(visual_layer.get_meta("visual_tileset_production", false)),
		"farming_marker_found": farming_marker != null,
		"lyra_found": lyra != null,
		"survivor_found": survivor != null,
	}

func _add_tile(root: Node2D, texture: Texture2D, atlas_coord: Vector2i, x: int, y: int) -> void:
	var atlas := AtlasTexture.new()
	atlas.atlas = texture
	atlas.region = Rect2(atlas_coord.x * TILE_SIZE, atlas_coord.y * TILE_SIZE, TILE_SIZE, TILE_SIZE)
	var sprite := Sprite2D.new()
	sprite.texture = atlas
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.position = BOARD_ORIGIN + Vector2(x * TILE_SIZE + TILE_SIZE / 2.0, y * TILE_SIZE + TILE_SIZE / 2.0)
	root.add_child(sprite)

func _coord(tile_map: Dictionary, key: String, cols: int, rows: int) -> Vector2i:
	var coord: Vector2i = tile_map.get(key, Vector2i.ZERO)
	return Vector2i(clampi(coord.x, 0, cols - 1), clampi(coord.y, 0, rows - 1))

func _add_marker(root: Node2D, tile: Vector2i, color: Color, label_text: String, label_color: Color) -> void:
	var pos := _tile_pos(tile)
	var shadow := ColorRect.new()
	shadow.color = Color(0, 0, 0, 0.34)
	shadow.size = Vector2(20, 8)
	shadow.position = pos + Vector2(6, 23)
	root.add_child(shadow)
	var body := ColorRect.new()
	body.color = color
	body.size = Vector2(12, 24)
	body.position = pos + Vector2(10, 7)
	root.add_child(body)
	var head := ColorRect.new()
	head.color = Color(0.94, 0.72, 0.55)
	head.size = Vector2(14, 8)
	head.position = pos + Vector2(9, 3)
	root.add_child(head)
	root.add_child(_make_label(label_text, pos + Vector2(-18, -12), 12, label_color))

func _tile_pos(tile: Vector2i) -> Vector2:
	return BOARD_ORIGIN + Vector2(tile.x * TILE_SIZE, tile.y * TILE_SIZE)

func _make_label(text: String, pos: Vector2, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.position = pos
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.96))
	label.add_theme_constant_override("shadow_offset_x", 1)
	label.add_theme_constant_override("shadow_offset_y", 1)
	return label

func _load_texture_path(path: String) -> Texture2D:
	if ResourceLoader.exists(path):
		var texture := load(path) as Texture2D
		if texture:
			return texture
	var image := Image.load_from_file(ProjectSettings.globalize_path(path))
	if image and not image.is_empty():
		return ImageTexture.create_from_image(image)
	return null

func _get_asset_manager() -> Node:
	return get_root().get_node_or_null("AssetManager")

func _save_viewport(output: String) -> String:
	var image := get_root().get_texture().get_image()
	if image == null or image.is_empty():
		push_error("R3 viewport image is empty. Run capture without --headless.")
		quit(1)
		return "Fail"
	var err := image.save_png(ProjectSettings.globalize_path(output))
	if err != OK:
		push_error("R3 failed to save screenshot %s err=%s" % [output, err])
		quit(1)
		return "Fail"
	return "Pass"

func _build_contact_sheet() -> Dictionary:
	var paths := [
		"res://assets/art_sources/comfyui_tests/fractured_wastes_r3_import_preview/screenshots/fractured_wastes_r3_fallback_preview.png",
		"res://assets/art_sources/comfyui_tests/fractured_wastes_r3_import_preview/screenshots/fractured_wastes_r3_production_variant_b_preview.png",
		"res://assets/art_sources/comfyui_tests/fractured_wastes_r3_import_preview/screenshots/fractured_wastes_r3_actual_region_fallback.png",
		"res://assets/art_sources/comfyui_tests/fractured_wastes_r3_import_preview/screenshots/fractured_wastes_r3_actual_region_production.png",
	]
	return _make_image_grid(paths, CONTACT_SHEET, 2)

func _build_actual_contact_sheet() -> Dictionary:
	var paths := [
		"res://assets/art_sources/comfyui_tests/fractured_wastes_r3_import_preview/screenshots/fractured_wastes_r3_actual_region_spawn.png",
		"res://assets/art_sources/comfyui_tests/fractured_wastes_r3_import_preview/screenshots/fractured_wastes_r3_actual_region_path.png",
		"res://assets/art_sources/comfyui_tests/fractured_wastes_r3_import_preview/screenshots/fractured_wastes_r3_actual_region_farming.png",
		"res://assets/art_sources/comfyui_tests/fractured_wastes_r3_import_preview/screenshots/fractured_wastes_r3_actual_region_npc.png",
		"res://assets/art_sources/comfyui_tests/fractured_wastes_r3_import_preview/screenshots/fractured_wastes_r3_actual_region_rift_or_core.png",
	]
	return _make_image_grid(paths, ACTUAL_CONTACT_SHEET, 3)

func _make_image_grid(paths: Array, output: String, cols: int) -> Dictionary:
	var images := []
	for path in paths:
		var image := Image.load_from_file(ProjectSettings.globalize_path(str(path)))
		if image == null or image.is_empty():
			return {"result": "Fail", "reason": "missing screenshot %s" % path}
		image.convert(Image.FORMAT_RGBA8)
		images.append(image)
	var cell_w: int = images[0].get_width()
	var cell_h: int = images[0].get_height()
	var rows := int(ceil(float(images.size()) / float(cols)))
	var contact := Image.create(cell_w * cols, cell_h * rows, false, Image.FORMAT_RGBA8)
	contact.fill(Color(0.04, 0.035, 0.045, 1.0))
	for i in range(images.size()):
		contact.blit_rect(images[i], Rect2i(0, 0, cell_w, cell_h), Vector2i((i % cols) * cell_w, int(i / cols) * cell_h))
	var err := contact.save_png(ProjectSettings.globalize_path(output))
	if err != OK:
		return {"result": "Fail", "reason": "save err=%s" % err}
	return {"result": "Pass", "path": output, "columns": cols, "rows": rows}

func _copy_preview_to_mockups(output: String) -> void:
	var image := Image.load_from_file(ProjectSettings.globalize_path(output))
	if image == null or image.is_empty():
		return
	var filename := output.get_file()
	image.save_png(ProjectSettings.globalize_path("%s/%s" % [MOCKUP_DIR, filename]))

func _clear_current_scene() -> void:
	if current_scene and is_instance_valid(current_scene):
		current_scene.queue_free()
		await _settle_frames(2)

func _settle_frames(count: int) -> void:
	for _i in range(count):
		await process_frame

func _find_node_by_name(root: Node, node_name: String) -> Node:
	if root.name == node_name:
		return root
	for child in root.get_children():
		var found := _find_node_by_name(child, node_name)
		if found:
			return found
	return null
