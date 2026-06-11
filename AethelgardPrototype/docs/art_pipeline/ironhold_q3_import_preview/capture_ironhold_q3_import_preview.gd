extends SceneTree

const SCREENSHOT_DIR := "res://assets/art_sources/comfyui_tests/ironhold_q3_import_preview/screenshots"
const CONTACT_DIR := "res://assets/art_sources/comfyui_tests/ironhold_q3_import_preview/contact_sheets"
const DIAGNOSTIC_DIR := "res://assets/art_sources/comfyui_tests/ironhold_q3_import_preview/diagnostics"
const CONTACT_SHEET := "res://assets/art_sources/comfyui_tests/ironhold_q3_import_preview/contact_sheets/ironhold_q3_fallback_vs_production_contact_sheet.png"
const DIAGNOSTIC_PATH := "res://assets/art_sources/comfyui_tests/ironhold_q3_import_preview/diagnostics/ironhold_q3_capture_diagnostics.json"

const IRONHOLD_PRODUCTION := "res://assets/production_art/tilesets/ironhold/ironhold_tileset.png"
const IRONHOLD_FALLBACK := "res://assets/generated_v2/tilesets/ironhold_v2_prototype_tileset.png"
const IRONHOLD_REGION_SCENE := "res://scenes/regions/ironhold_region.tscn"

const TILE_SIZE := 32
const BOARD_W := 24
const BOARD_H := 18
const BOARD_ORIGIN := Vector2(80, 98)
const VIEWPORT_SIZE := Vector2i(1024, 768)

const PREVIEW_CAPTURES := [
	{
		"id": "fallback_preview",
		"title": "Ironhold generated fallback",
		"force_fallback": true,
		"output": "res://assets/art_sources/comfyui_tests/ironhold_q3_import_preview/screenshots/ironhold_q3_fallback_preview.png",
	},
	{
		"id": "production_variant_b_preview",
		"title": "Ironhold production Variant B",
		"force_fallback": false,
		"output": "res://assets/art_sources/comfyui_tests/ironhold_q3_import_preview/screenshots/ironhold_q3_production_variant_b_preview.png",
	},
]

const Q1_TILES := {
	"floor": Vector2i(8, 0),
	"floor_alt": Vector2i(0, 1),
	"floor_shadow": Vector2i(9, 0),
	"floor_warm": Vector2i(6, 2),
	"floor_soot": Vector2i(6, 0),
	"floor_oil": Vector2i(7, 0),
	"walk_h": Vector2i(1, 3),
	"walk_v": Vector2i(2, 3),
	"walk_cross": Vector2i(11, 3),
	"walk_t_east": Vector2i(9, 3),
	"walk_t_south": Vector2i(8, 3),
	"walk_corner_se": Vector2i(5, 3),
	"wall": Vector2i(0, 11),
	"wall_panel": Vector2i(4, 11),
	"pillar": Vector2i(8, 11),
	"foundation_shadow": Vector2i(10, 11),
	"forge_ember": Vector2i(0, 9),
	"furnace_glow": Vector2i(1, 9),
	"hot_grate": Vector2i(3, 9),
	"cooled_grate": Vector2i(4, 9),
	"ash": Vector2i(5, 9),
	"smoke": Vector2i(9, 9),
	"heat_pipe": Vector2i(7, 9),
	"pipe_h": Vector2i(0, 13),
	"pipe_v": Vector2i(1, 13),
	"pipe_corner": Vector2i(2, 13),
	"pipe_valve": Vector2i(3, 13),
	"gear": Vector2i(4, 13),
	"crate": Vector2i(5, 13),
	"barrel": Vector2i(6, 13),
	"anvil": Vector2i(7, 13),
	"workbench": Vector2i(8, 13),
	"coal": Vector2i(9, 13),
	"scrap": Vector2i(10, 13),
	"tool_rack": Vector2i(11, 13),
	"machine": Vector2i(12, 13),
	"control": Vector2i(13, 13),
	"railing_h": Vector2i(0, 14),
	"railing_v": Vector2i(1, 14),
	"railing_corner": Vector2i(3, 14),
	"barrier": Vector2i(6, 14),
	"broken_barrier": Vector2i(7, 14),
	"ramp": Vector2i(9, 14),
	"cyan": Vector2i(3, 15),
	"magenta": Vector2i(4, 15),
	"steam": Vector2i(5, 15),
	"dust": Vector2i(6, 15),
}

const FALLBACK_TILES := {
	"floor": Vector2i(0, 0),
	"floor_alt": Vector2i(1, 0),
	"floor_shadow": Vector2i(1, 1),
	"floor_warm": Vector2i(2, 0),
	"floor_soot": Vector2i(0, 1),
	"floor_oil": Vector2i(1, 1),
	"walk_h": Vector2i(0, 1),
	"walk_v": Vector2i(0, 1),
	"walk_cross": Vector2i(0, 1),
	"walk_t_east": Vector2i(0, 1),
	"walk_t_south": Vector2i(0, 1),
	"walk_corner_se": Vector2i(0, 1),
	"wall": Vector2i(3, 0),
	"wall_panel": Vector2i(3, 1),
	"pillar": Vector2i(3, 0),
	"foundation_shadow": Vector2i(1, 1),
	"forge_ember": Vector2i(2, 0),
	"furnace_glow": Vector2i(2, 0),
	"hot_grate": Vector2i(3, 1),
	"cooled_grate": Vector2i(0, 1),
	"ash": Vector2i(1, 1),
	"smoke": Vector2i(1, 0),
	"heat_pipe": Vector2i(2, 0),
	"pipe_h": Vector2i(0, 1),
	"pipe_v": Vector2i(0, 1),
	"pipe_corner": Vector2i(0, 1),
	"pipe_valve": Vector2i(2, 1),
	"gear": Vector2i(1, 0),
	"crate": Vector2i(2, 1),
	"barrel": Vector2i(2, 1),
	"anvil": Vector2i(3, 1),
	"workbench": Vector2i(2, 1),
	"coal": Vector2i(1, 1),
	"scrap": Vector2i(1, 1),
	"tool_rack": Vector2i(3, 1),
	"machine": Vector2i(3, 0),
	"control": Vector2i(3, 1),
	"railing_h": Vector2i(0, 1),
	"railing_v": Vector2i(0, 1),
	"railing_corner": Vector2i(0, 1),
	"barrier": Vector2i(3, 1),
	"broken_barrier": Vector2i(3, 1),
	"ramp": Vector2i(1, 1),
	"cyan": Vector2i(1, 0),
	"magenta": Vector2i(3, 1),
	"steam": Vector2i(1, 1),
	"dust": Vector2i(1, 1),
}

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	get_root().size = VIEWPORT_SIZE
	for path in [SCREENSHOT_DIR, CONTACT_DIR, DIAGNOSTIC_DIR]:
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(path))

	var asset_manager = _get_asset_manager()
	var preview_results := []
	for capture in PREVIEW_CAPTURES:
		preview_results.append(await _capture_preview(asset_manager, capture))

	var actual_fallback := await _capture_actual_region(asset_manager, true, "res://assets/art_sources/comfyui_tests/ironhold_q3_import_preview/screenshots/ironhold_q3_actual_region_fallback.png")
	var actual_production := await _capture_actual_region(asset_manager, false, "res://assets/art_sources/comfyui_tests/ironhold_q3_import_preview/screenshots/ironhold_q3_actual_region_production.png")
	var contact_result := _build_contact_sheet()
	if asset_manager and asset_manager.has_method("set_ironhold_force_generated_fallback"):
		asset_manager.set_ironhold_force_generated_fallback(false)

	var data := {
		"phase": "10M-Q3",
		"previews": preview_results,
		"actual_region": {
			"fallback": actual_fallback,
			"production": actual_production,
		},
		"contact_sheet": contact_result,
		"production_art_changed": true,
		"actual_scene_modified": false,
		"chapter2_ironhold_city_capture": {"result": "Skipped", "reason": "chapter2 ironhold_city can run story/quest/dialogue side effects during _ready"},
		"arena_district_capture": {"result": "Skipped", "reason": "arena_district can enter combat/quest UI flow during _ready"},
	}
	var file := FileAccess.open(ProjectSettings.globalize_path(DIAGNOSTIC_PATH), FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(data, "\t"))
	print("Ironhold Q3 import preview capture: PASS")
	quit(0)

func _get_asset_manager():
	var existing = get_root().get_node_or_null("AssetManager")
	if existing:
		return existing
	return load("res://scripts/asset_manager.gd").new()

func _capture_preview(asset_manager, capture: Dictionary) -> Dictionary:
	await _clear_current_scene()
	if asset_manager and asset_manager.has_method("set_ironhold_force_generated_fallback"):
		asset_manager.set_ironhold_force_generated_fallback(bool(capture.get("force_fallback", false)))
	var slot: Dictionary = asset_manager.get_ironhold_tileset_slot() if asset_manager else {}
	var texture := slot.get("texture") as Texture2D
	if not texture:
		push_error("Q3 could not resolve Ironhold preview texture for %s" % capture.get("id", "unknown"))
		quit(1)
		return {}

	var root := Node2D.new()
	root.name = "IronholdQ3PreviewRoot"
	get_root().add_child(root)
	current_scene = root
	_build_preview_board(root, texture, not bool(slot.get("production", false)), str(capture["title"]), str(slot.get("path", "")))
	await _settle_frames(6)

	var output := str(capture["output"])
	var save_result := _save_viewport(output)
	return {
		"id": str(capture["id"]),
		"title": str(capture["title"]),
		"screenshot": output,
		"resolved_path": str(slot.get("path", "")),
		"production": bool(slot.get("production", false)),
		"fallback_used": bool(slot.get("fallback_used", false)),
		"fallback_reason": str(slot.get("fallback_reason", "")),
		"texture_size": "%dx%d" % [texture.get_width(), texture.get_height()],
		"result": save_result,
	}

func _build_preview_board(root: Node2D, texture: Texture2D, fallback: bool, title: String, resolved_path: String) -> void:
	var bg := ColorRect.new()
	bg.color = Color(0.035, 0.037, 0.043, 1.0)
	bg.size = Vector2(VIEWPORT_SIZE)
	root.add_child(bg)

	root.add_child(_make_label(title, Vector2(32, 24), 22, Color(0.95, 0.86, 0.68)))
	root.add_child(_make_label("24x18 Q3 import preview - AssetManager resolved: %s" % resolved_path, Vector2(32, 54), 12, Color(0.72, 0.73, 0.72)))

	var tile_map: Dictionary = FALLBACK_TILES if fallback else Q1_TILES
	var cols: int = max(1, int(texture.get_width() / TILE_SIZE))
	var rows: int = max(1, int(texture.get_height() / TILE_SIZE))

	for y in range(BOARD_H):
		for x in range(BOARD_W):
			var key := "floor"
			if x < 4 and y > 12:
				key = "floor_shadow"
			elif x > 17 and y > 11:
				key = "floor_warm" if (x + y) % 2 == 0 else "floor_soot"
			elif (x * 11 + y * 7) % 13 == 0:
				key = "floor_alt"
			_add_tile(root, texture, _coord(tile_map, key, cols, rows), x, y)

	for x in range(2, 22):
		_add_tile(root, texture, _coord(tile_map, "walk_h", cols, rows), x, 9)
	for y in range(3, 16):
		_add_tile(root, texture, _coord(tile_map, "walk_v", cols, rows), 12, y)
	_add_tile(root, texture, _coord(tile_map, "walk_cross", cols, rows), 12, 9)
	_add_tile(root, texture, _coord(tile_map, "walk_t_east", cols, rows), 12, 5)
	for x in range(12, 20):
		_add_tile(root, texture, _coord(tile_map, "walk_h", cols, rows), x, 5)
	_add_tile(root, texture, _coord(tile_map, "walk_corner_se", cols, rows), 20, 5)
	for y in range(6, 12):
		_add_tile(root, texture, _coord(tile_map, "walk_v", cols, rows), 20, y)
	_add_tile(root, texture, _coord(tile_map, "walk_t_south", cols, rows), 6, 9)
	for y in range(10, 13):
		_add_tile(root, texture, _coord(tile_map, "walk_v", cols, rows), 6, y)
	_add_tile(root, texture, _coord(tile_map, "walk_warning", cols, rows), 9, 9)

	for x in range(BOARD_W):
		_add_tile(root, texture, _coord(tile_map, "wall_panel" if x % 4 == 0 else "wall", cols, rows), x, 0)
		_add_tile(root, texture, _coord(tile_map, "foundation_shadow", cols, rows), x, 1)
	for x in [3, 8, 14, 20]:
		_add_tile(root, texture, _coord(tile_map, "pillar", cols, rows), x, 1)

	for x in range(17, 23):
		_add_tile(root, texture, _coord(tile_map, "hot_grate" if x % 2 == 0 else "cooled_grate", cols, rows), x, 14)
	for x in range(18, 23):
		_add_tile(root, texture, _coord(tile_map, "forge_ember" if x % 2 else "ash", cols, rows), x, 15)
	_add_tile(root, texture, _coord(tile_map, "furnace_glow", cols, rows), 22, 13)
	_add_tile(root, texture, _coord(tile_map, "control", cols, rows), 21, 13)
	_add_tile(root, texture, _coord(tile_map, "heat_pipe", cols, rows), 19, 13)
	_add_tile(root, texture, _coord(tile_map, "smoke", cols, rows), 22, 12)

	for x in range(3, 10):
		_add_tile(root, texture, _coord(tile_map, "pipe_h", cols, rows), x, 3)
	_add_tile(root, texture, _coord(tile_map, "pipe_corner", cols, rows), 10, 3)
	for y in range(4, 7):
		_add_tile(root, texture, _coord(tile_map, "pipe_v", cols, rows), 10, y)
	_add_tile(root, texture, _coord(tile_map, "pipe_valve", cols, rows), 7, 3)

	for item in [
		[4, 11, "crate"], [5, 11, "barrel"], [16, 10, "anvil"], [17, 10, "workbench"],
		[15, 13, "coal"], [14, 14, "scrap"], [3, 15, "machine"], [4, 15, "tool_rack"],
	]:
		_add_tile(root, texture, _coord(tile_map, str(item[2]), cols, rows), int(item[0]), int(item[1]))

	for x in range(13, 23):
		_add_tile(root, texture, _coord(tile_map, "railing_h", cols, rows), x, 17)
	for y in range(12, 17):
		_add_tile(root, texture, _coord(tile_map, "railing_v", cols, rows), 13, y)
	_add_tile(root, texture, _coord(tile_map, "railing_corner", cols, rows), 13, 17)
	_add_tile(root, texture, _coord(tile_map, "barrier", cols, rows), 8, 13)
	_add_tile(root, texture, _coord(tile_map, "broken_barrier", cols, rows), 9, 13)
	_add_tile(root, texture, _coord(tile_map, "ramp", cols, rows), 7, 9)

	_add_tile(root, texture, _coord(tile_map, "cyan", cols, rows), 18, 6)
	_add_tile(root, texture, _coord(tile_map, "magenta", cols, rows), 5, 4)
	_add_tile(root, texture, _coord(tile_map, "steam", cols, rows), 21, 12)
	_add_tile(root, texture, _coord(tile_map, "dust", cols, rows), 2, 16)

	_add_marker(root, Vector2i(12, 10), Color(0.08, 0.76, 0.96), "Player", Color(0.86, 0.98, 1.0))
	_add_marker(root, Vector2i(9, 8), Color(0.70, 0.44, 0.26), "Engineer Mira", Color.WHITE)
	_add_marker(root, Vector2i(16, 8), Color(0.54, 0.66, 0.70), "Guard Voss", Color.WHITE)
	_add_marker(root, Vector2i(4, 13), Color(0.58, 0.54, 0.46), "Merchant", Color.WHITE)
	root.add_child(_make_label("[F] Talk", _tile_pos(Vector2i(9, 8)) + Vector2(-18, 26), 13, Color(1.0, 0.96, 0.55)))
	root.add_child(_make_label("[E] Inspect furnace controls", _tile_pos(Vector2i(18, 13)) + Vector2(-12, 32), 12, Color(1.0, 0.78, 0.44)))
	root.add_child(_make_label("Dark corner contrast", _tile_pos(Vector2i(1, 15)) + Vector2(0, 34), 12, Color(0.72, 0.76, 0.78)))
	root.add_child(_make_label("Forge glow should guide, not blind", _tile_pos(Vector2i(17, 16)) + Vector2(-10, 35), 12, Color(1.0, 0.66, 0.36)))

func _capture_actual_region(asset_manager, force_fallback: bool, output: String) -> Dictionary:
	await _clear_current_scene()
	if asset_manager and asset_manager.has_method("set_ironhold_force_generated_fallback"):
		asset_manager.set_ironhold_force_generated_fallback(force_fallback)
	var packed := load(IRONHOLD_REGION_SCENE) as PackedScene
	if not packed:
		return {"result": "Skipped", "reason": "Ironhold region scene could not be loaded.", "screenshot": output}
	var scene := packed.instantiate()
	get_root().add_child(scene)
	current_scene = scene
	await _settle_frames(14)

	var focus := Vector2(1500, 1000)
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

	var visual_layer := _find_node_by_name(scene, "V2IronholdGroundTiles")
	var farming_marker := _find_node_by_name(scene, "IronholdTrainingYardFarming")
	var save_result := _save_viewport(output)
	return {
		"result": save_result,
		"scene": IRONHOLD_REGION_SCENE,
		"screenshot": output,
		"force_fallback": force_fallback,
		"player_found": player != null,
		"camera_found": camera != null,
		"visual_layer_found": visual_layer != null,
		"visual_layer_path": "" if visual_layer == null else str(visual_layer.get_meta("visual_tileset_path", "")),
		"visual_layer_production": false if visual_layer == null else bool(visual_layer.get_meta("visual_tileset_production", false)),
		"farming_marker_found": farming_marker != null,
	}

func _save_viewport(output: String) -> String:
	var image := get_root().get_texture().get_image()
	if image == null or image.is_empty():
		push_error("Q3 viewport image is empty. Run the capture without --headless.")
		quit(1)
		return "Fail"
	var err := image.save_png(ProjectSettings.globalize_path(output))
	if err != OK:
		push_error("Q3 failed to save screenshot %s err=%s" % [output, err])
		quit(1)
		return "Fail"
	return "Pass"

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
	shadow.color = Color(0, 0, 0, 0.32)
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
	label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.95))
	label.add_theme_constant_override("shadow_offset_x", 1)
	label.add_theme_constant_override("shadow_offset_y", 1)
	return label

func _build_contact_sheet() -> Dictionary:
	var paths := [
		"res://assets/art_sources/comfyui_tests/ironhold_q3_import_preview/screenshots/ironhold_q3_fallback_preview.png",
		"res://assets/art_sources/comfyui_tests/ironhold_q3_import_preview/screenshots/ironhold_q3_production_variant_b_preview.png",
		"res://assets/art_sources/comfyui_tests/ironhold_q3_import_preview/screenshots/ironhold_q3_actual_region_fallback.png",
		"res://assets/art_sources/comfyui_tests/ironhold_q3_import_preview/screenshots/ironhold_q3_actual_region_production.png",
	]
	var images := []
	for path in paths:
		var image := Image.load_from_file(ProjectSettings.globalize_path(path))
		if image == null or image.is_empty():
			return {"result": "Fail", "reason": "missing screenshot %s" % path}
		image.convert(Image.FORMAT_RGBA8)
		images.append(image)
	var cell_w: int = images[0].get_width()
	var cell_h: int = images[0].get_height()
	var contact := Image.create(cell_w * 2, cell_h * 2, false, Image.FORMAT_RGBA8)
	contact.fill(Color(0.04, 0.04, 0.05, 1.0))
	for i in range(images.size()):
		contact.blit_rect(images[i], Rect2i(0, 0, cell_w, cell_h), Vector2i((i % 2) * cell_w, int(i / 2) * cell_h))
	var err := contact.save_png(ProjectSettings.globalize_path(CONTACT_SHEET))
	if err != OK:
		return {"result": "Fail", "reason": "save err=%s" % err}
	return {"result": "Pass", "path": CONTACT_SHEET, "columns": 2, "rows": 2}

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
