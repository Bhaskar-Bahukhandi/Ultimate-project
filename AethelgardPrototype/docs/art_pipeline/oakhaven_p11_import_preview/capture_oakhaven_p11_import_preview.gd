extends SceneTree

const TILE := 32
const BOARD_W := 24
const BOARD_H := 18

const SCREENSHOT_DIR := "res://assets/art_sources/comfyui_tests/oakhaven_p11_import_preview/screenshots"
const CONTACT_DIR := "res://assets/art_sources/comfyui_tests/oakhaven_p11_import_preview/contact_sheets"
const MANIFEST_DIR := "res://assets/art_sources/comfyui_tests/oakhaven_p11_import_preview/manifest"
const FALLBACK_PATH := "res://assets/generated_v2/tilesets/oakhaven_v2_prototype_tileset.png"

const SCREENSHOTS := {
	"fallback": "res://assets/art_sources/comfyui_tests/oakhaven_p11_import_preview/screenshots/oakhaven_p11_fallback_preview.png",
	"morning": "res://assets/art_sources/comfyui_tests/oakhaven_p11_import_preview/screenshots/oakhaven_p11_morning_preview.png",
	"afternoon": "res://assets/art_sources/comfyui_tests/oakhaven_p11_import_preview/screenshots/oakhaven_p11_afternoon_preview.png",
	"night": "res://assets/art_sources/comfyui_tests/oakhaven_p11_import_preview/screenshots/oakhaven_p11_night_preview.png",
}

const TILE_COORDS := {
	"grass_base": Vector2i(0, 0),
	"grass_plain_backup": Vector2i(15, 0),
	"grass_patchy": Vector2i(3, 0),
	"grass_sparse": Vector2i(4, 0),
	"grass_leaf_scatter": Vector2i(9, 0),
	"grass_tiny_stones": Vector2i(12, 0),
	"dirt_center": Vector2i(0, 3),
	"dirt_variation": Vector2i(1, 3),
	"path_straight_horizontal": Vector2i(3, 3),
	"path_straight_vertical": Vector2i(4, 3),
	"path_t_junction_up": Vector2i(5, 3),
	"path_t_junction_down": Vector2i(6, 3),
	"path_t_junction_left": Vector2i(7, 3),
	"path_t_junction_right": Vector2i(8, 3),
	"path_cross": Vector2i(9, 3),
	"dirt_small_stone_embedded": Vector2i(10, 3),
	"path_turn_ne": Vector2i(11, 3),
	"path_turn_nw": Vector2i(12, 3),
	"path_turn_se": Vector2i(13, 3),
	"path_turn_sw": Vector2i(14, 3),
	"path_end_left": Vector2i(15, 3),
	"path_end_right": Vector2i(0, 4),
	"path_end_top": Vector2i(1, 4),
	"path_end_bottom": Vector2i(2, 4),
	"transition_top_edge": Vector2i(0, 6),
	"transition_bottom_edge": Vector2i(1, 6),
	"transition_left_edge": Vector2i(2, 6),
	"transition_right_edge": Vector2i(3, 6),
	"transition_outer_tl": Vector2i(4, 6),
	"transition_outer_tr": Vector2i(5, 6),
	"transition_outer_bl": Vector2i(6, 6),
	"transition_outer_br": Vector2i(7, 6),
	"fence_horizontal_middle": Vector2i(0, 9),
	"fence_vertical_middle": Vector2i(1, 9),
	"fence_post": Vector2i(2, 9),
	"fence_end_bottom": Vector2i(6, 9),
	"hedge_horizontal": Vector2i(8, 9),
	"hedge_vertical": Vector2i(9, 9),
	"hedge_corner_tl": Vector2i(10, 9),
	"hedge_corner_tr": Vector2i(11, 9),
	"hedge_broken_opening": Vector2i(14, 9),
	"cottage_wall_base": Vector2i(0, 11),
	"cottage_wall_variation": Vector2i(1, 11),
	"roof_edge_tile": Vector2i(3, 11),
	"roof_corner_tile": Vector2i(4, 11),
	"roof_center_tile": Vector2i(5, 11),
	"doorway_base": Vector2i(7, 11),
	"window_wall_detail": Vector2i(8, 11),
	"small_wooden_trim": Vector2i(9, 11),
	"roof_edge_left": Vector2i(10, 11),
	"roof_edge_right": Vector2i(11, 11),
	"roof_edge_top": Vector2i(12, 11),
	"wall_shadow_right": Vector2i(15, 11),
	"wall_moss_base": Vector2i(2, 12),
	"roof_moss_patch": Vector2i(3, 12),
	"cottage_step": Vector2i(4, 12),
	"flower_patch": Vector2i(0, 14),
	"herb_patch": Vector2i(1, 14),
	"wooden_sign": Vector2i(2, 14),
	"small_stone": Vector2i(3, 14),
	"tree_stump": Vector2i(4, 14),
	"crate_barrel_simple": Vector2i(5, 14),
	"soft_shadow_blob": Vector2i(6, 14),
	"glitch_flower_rune_accent": Vector2i(7, 14),
	"ground_leaf_scatter": Vector2i(8, 14),
	"village_marker_tile": Vector2i(9, 14),
	"shadow_only_tile": Vector2i(12, 14),
	"flower_patch_blue": Vector2i(14, 14),
	"tiny_mushroom_cluster": Vector2i(15, 14),
	"small_log": Vector2i(0, 15),
}

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	_ensure_output_dirs()
	var asset_manager = load("res://scripts/asset_manager.gd").new()
	var captures := {}
	var slot_results := {}

	var fallback_atlas := Image.load_from_file(ProjectSettings.globalize_path(FALLBACK_PATH))
	if fallback_atlas == null or fallback_atlas.is_empty():
		push_error("P11 fallback preview could not load generated fallback.")
		quit(1)
		return
	captures["fallback"] = _build_fallback_board(fallback_atlas)
	_save_capture(captures["fallback"], SCREENSHOTS["fallback"])

	for time_state in ["morning", "afternoon", "night"]:
		var slot: Dictionary = asset_manager.get_oakhaven_tileset_slot(time_state)
		var texture := slot.get("texture") as Texture2D
		if texture == null:
			push_error("P11 preview could not load Oakhaven production slot: %s" % time_state)
			asset_manager.free()
			quit(1)
			return
		var atlas := texture.get_image()
		if atlas == null or atlas.is_empty():
			push_error("P11 preview could not read Oakhaven texture image: %s" % time_state)
			asset_manager.free()
			quit(1)
			return
		captures[time_state] = _build_production_board(atlas, time_state)
		_save_capture(captures[time_state], SCREENSHOTS[time_state])
		slot_results[time_state] = {
			"path": slot.get("path", ""),
			"production": bool(slot.get("production", false)),
			"requested_time_state": slot.get("requested_time_state", time_state),
			"time_state": slot.get("time_state", time_state),
			"fallback_used": bool(slot.get("fallback_used", false)),
		}

	var contact_path := "res://assets/art_sources/comfyui_tests/oakhaven_p11_import_preview/contact_sheets/oakhaven_p11_fallback_vs_production_contact_sheet.png"
	var contact := _build_contact_sheet(captures)
	_save_capture(contact, contact_path)
	_write_manifest(slot_results, contact_path)
	asset_manager.free()
	print("P11 import preview capture: PASS")
	quit(0)

func _ensure_output_dirs() -> void:
	for path in [SCREENSHOT_DIR, CONTACT_DIR, MANIFEST_DIR]:
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(path))

func _save_capture(image: Image, path: String) -> void:
	var err := image.save_png(ProjectSettings.globalize_path(path))
	if err != OK:
		push_error("P11 preview could not save %s: %s" % [path, err])
		quit(1)

func _build_production_board(atlas: Image, _time_state: String) -> Image:
	var board := Image.create(BOARD_W * TILE, BOARD_H * TILE, false, Image.FORMAT_RGBA8)
	board.fill(Color(0, 0, 0, 1))
	var grass_choices := ["grass_base", "grass_plain_backup", "grass_patchy", "grass_sparse", "grass_leaf_scatter", "grass_tiny_stones"]
	for y in range(BOARD_H):
		for x in range(BOARD_W):
			var pick_index := posmod(x * 7 + y * 11 + x * y, grass_choices.size())
			_blit_tile(board, atlas, grass_choices[pick_index], x, y)
	_add_transition_patch(board, atlas)
	_add_path(board, atlas)
	_add_cottage(board, atlas)
	_add_boundaries(board, atlas)
	_add_props(board, atlas)
	_draw_player_marker(board, Vector2i(12 * TILE + 9, 9 * TILE + 5), _time_state)
	_draw_npc_marker(board, Vector2i(14 * TILE + 12, 9 * TILE + 8))
	return board

func _build_fallback_board(atlas: Image) -> Image:
	var board := Image.create(BOARD_W * TILE, BOARD_H * TILE, false, Image.FORMAT_RGBA8)
	board.fill(Color(0.13, 0.20, 0.11, 1))
	var atlas_w := int(atlas.get_width() / TILE)
	var atlas_h := int(atlas.get_height() / TILE)
	for y in range(BOARD_H):
		for x in range(BOARD_W):
			var coord := Vector2i(posmod(x * 3 + y, atlas_w), posmod(x + y * 2, atlas_h))
			board.blit_rect(atlas, Rect2i(coord.x * TILE, coord.y * TILE, TILE, TILE), Vector2i(x * TILE, y * TILE))
	_draw_rect(board, Rect2i(0, 9 * TILE, BOARD_W * TILE, TILE), Color(0.46, 0.34, 0.22, 1.0))
	_draw_rect(board, Rect2i(10 * TILE, 7 * TILE, TILE, 4 * TILE), Color(0.46, 0.34, 0.22, 1.0))
	_draw_rect(board, Rect2i(17 * TILE, 2 * TILE, 4 * TILE, 4 * TILE), Color(0.48, 0.30, 0.20, 1.0))
	_draw_rect(board, Rect2i(17 * TILE, 2 * TILE, 4 * TILE, TILE), Color(0.42, 0.12, 0.12, 1.0))
	_draw_player_marker(board, Vector2i(12 * TILE + 9, 9 * TILE + 5), "fallback")
	_draw_npc_marker(board, Vector2i(14 * TILE + 12, 9 * TILE + 8))
	return board

func _add_transition_patch(board: Image, atlas: Image) -> void:
	var x0 := 2
	var y0 := 12
	for entry in [
		["transition_outer_tl", x0, y0], ["transition_top_edge", x0 + 1, y0], ["transition_top_edge", x0 + 2, y0], ["transition_outer_tr", x0 + 3, y0],
		["transition_left_edge", x0, y0 + 1], ["dirt_center", x0 + 1, y0 + 1], ["dirt_variation", x0 + 2, y0 + 1], ["transition_right_edge", x0 + 3, y0 + 1],
		["transition_outer_bl", x0, y0 + 2], ["transition_bottom_edge", x0 + 1, y0 + 2], ["transition_bottom_edge", x0 + 2, y0 + 2], ["transition_outer_br", x0 + 3, y0 + 2],
	]:
		_blit_tile(board, atlas, entry[0], int(entry[1]), int(entry[2]))

func _add_path(board: Image, atlas: Image) -> void:
	var path := {}
	for x in range(0, 7):
		path[Vector2i(x, 9)] = true
	for p in [Vector2i(7, 8), Vector2i(8, 8), Vector2i(9, 8), Vector2i(10, 7), Vector2i(11, 7), Vector2i(12, 7), Vector2i(13, 8), Vector2i(14, 8)]:
		path[p] = true
	for x in range(15, 24):
		path[Vector2i(x, 9)] = true
	for p in [Vector2i(10, 8), Vector2i(10, 9), Vector2i(10, 10), Vector2i(11, 10), Vector2i(12, 10)]:
		path[p] = true
	for cell in path.keys():
		_blit_tile(board, atlas, _path_tile_name(cell, path), cell.x, cell.y)

func _path_tile_name(cell: Vector2i, path: Dictionary) -> String:
	var n := path.has(cell + Vector2i(0, -1))
	var e := path.has(cell + Vector2i(1, 0))
	var s := path.has(cell + Vector2i(0, 1))
	var w := path.has(cell + Vector2i(-1, 0))
	var count := 0
	for has_neighbor in [n, e, s, w]:
		if has_neighbor:
			count += 1
	if count >= 4:
		return "path_cross"
	if count == 3:
		if not s:
			return "path_t_junction_up"
		if not n:
			return "path_t_junction_down"
		if not e:
			return "path_t_junction_left"
		return "path_t_junction_right"
	if count == 2:
		if e and w:
			return "path_straight_horizontal"
		if n and s:
			return "path_straight_vertical"
		if n and e:
			return "path_turn_ne"
		if n and w:
			return "path_turn_nw"
		if s and e:
			return "path_turn_se"
		return "path_turn_sw"
	if count == 1:
		if e:
			return "path_end_left"
		if w:
			return "path_end_right"
		if s:
			return "path_end_top"
		return "path_end_bottom"
	return "dirt_center"

func _add_cottage(board: Image, atlas: Image) -> void:
	var bx := 17
	var by := 2
	var rows := [
		["roof_corner_tile", "roof_edge_top", "roof_edge_top", "roof_edge_tile"],
		["roof_edge_left", "roof_center_tile", "roof_moss_patch", "roof_edge_right"],
		["cottage_wall_base", "window_wall_detail", "cottage_wall_variation", "small_wooden_trim"],
		["wall_moss_base", "doorway_base", "cottage_step", "wall_shadow_right"],
	]
	for y in range(rows.size()):
		for x in range(rows[y].size()):
			_blit_tile(board, atlas, rows[y][x], bx + x, by + y)

func _add_boundaries(board: Image, atlas: Image) -> void:
	for x in range(2, 11):
		_blit_tile(board, atlas, "fence_horizontal_middle", x, 3)
	for y in range(4, 9):
		_blit_tile(board, atlas, "fence_vertical_middle", 2, y)
	for entry in [["fence_post", 2, 3], ["fence_post", 10, 3], ["fence_end_bottom", 2, 9]]:
		_blit_tile(board, atlas, entry[0], int(entry[1]), int(entry[2]))
	for x in range(15, 22):
		_blit_tile(board, atlas, "hedge_horizontal", x, 13)
	for entry in [["hedge_corner_tl", 14, 13], ["hedge_corner_tr", 22, 13]]:
		_blit_tile(board, atlas, entry[0], int(entry[1]), int(entry[2]))
	for y in range(14, 17):
		_blit_tile(board, atlas, "hedge_vertical", 14, y)
		_blit_tile(board, atlas, "hedge_vertical", 22, y)
	_blit_tile(board, atlas, "hedge_broken_opening", 18, 13)

func _add_props(board: Image, atlas: Image) -> void:
	for entry in [
		["flower_patch", 5, 5], ["herb_patch", 6, 6], ["wooden_sign", 8, 7], ["small_stone", 16, 7], ["tree_stump", 18, 15],
		["crate_barrel_simple", 21, 7], ["soft_shadow_blob", 17, 7], ["glitch_flower_rune_accent", 12, 5], ["ground_leaf_scatter", 7, 11],
		["village_marker_tile", 14, 10], ["flower_patch_blue", 20, 15], ["tiny_mushroom_cluster", 17, 15], ["small_log", 6, 15],
		["dirt_small_stone_embedded", 4, 10], ["shadow_only_tile", 19, 6],
	]:
		_blit_tile(board, atlas, entry[0], int(entry[1]), int(entry[2]))

func _blit_tile(board: Image, atlas: Image, tile_name: String, cell_x: int, cell_y: int) -> void:
	var coord: Vector2i = TILE_COORDS[tile_name]
	board.blend_rect(atlas, Rect2i(coord.x * TILE, coord.y * TILE, TILE, TILE), Vector2i(cell_x * TILE, cell_y * TILE))

func _draw_player_marker(image: Image, top_left: Vector2i, time_state: String) -> void:
	var outline := Color(0.03, 0.035, 0.04, 1.0)
	var body := Color(0.25, 0.66, 0.95, 1.0)
	var cloak := Color(0.08, 0.20, 0.48, 1.0)
	if time_state == "night":
		body = Color(0.55, 0.86, 1.0, 1.0)
		cloak = Color(0.12, 0.28, 0.64, 1.0)
	_draw_rect(image, Rect2i(top_left.x + 3, top_left.y + 2, 8, 7), outline)
	_draw_rect(image, Rect2i(top_left.x + 4, top_left.y + 3, 6, 5), Color(0.96, 0.83, 0.62, 1.0))
	_draw_rect(image, Rect2i(top_left.x + 2, top_left.y + 9, 11, 13), outline)
	_draw_rect(image, Rect2i(top_left.x + 3, top_left.y + 10, 9, 11), cloak)
	_draw_rect(image, Rect2i(top_left.x + 5, top_left.y + 10, 5, 8), body)
	_draw_rect(image, Rect2i(top_left.x + 3, top_left.y + 22, 3, 3), outline)
	_draw_rect(image, Rect2i(top_left.x + 9, top_left.y + 22, 3, 3), outline)

func _draw_npc_marker(image: Image, top_left: Vector2i) -> void:
	var outline := Color(0.04, 0.035, 0.03, 1.0)
	_draw_rect(image, Rect2i(top_left.x + 4, top_left.y + 3, 6, 5), Color(0.92, 0.70, 0.50, 1.0))
	_draw_rect(image, Rect2i(top_left.x + 2, top_left.y + 9, 11, 12), outline)
	_draw_rect(image, Rect2i(top_left.x + 3, top_left.y + 10, 9, 10), Color(0.66, 0.30, 0.22, 1.0))
	_draw_rect(image, Rect2i(top_left.x + 5, top_left.y + 20, 3, 3), outline)
	_draw_rect(image, Rect2i(top_left.x + 9, top_left.y + 20, 3, 3), outline)

func _draw_rect(image: Image, rect: Rect2i, color: Color) -> void:
	for y in range(rect.position.y, rect.position.y + rect.size.y):
		for x in range(rect.position.x, rect.position.x + rect.size.x):
			if x >= 0 and y >= 0 and x < image.get_width() and y < image.get_height():
				image.set_pixel(x, y, color)

func _build_contact_sheet(captures: Dictionary) -> Image:
	var sheet := Image.create(BOARD_W * TILE * 4, BOARD_H * TILE, false, Image.FORMAT_RGBA8)
	sheet.fill(Color(0.08, 0.085, 0.10, 1.0))
	var x_offset := 0
	for key in ["fallback", "morning", "afternoon", "night"]:
		var image: Image = captures[key]
		sheet.blit_rect(image, Rect2i(0, 0, image.get_width(), image.get_height()), Vector2i(x_offset, 0))
		x_offset += image.get_width()
	return sheet

func _write_manifest(slot_results: Dictionary, contact_path: String) -> void:
	var data := {
		"phase": "10M-P11",
		"preview_only": true,
		"production_art_changed": true,
		"capture_method": "Godot headless Image composition using AssetManager Oakhaven production slots",
		"fallback_path": FALLBACK_PATH,
		"screenshots": SCREENSHOTS,
		"contact_sheet": contact_path,
		"slot_results": slot_results,
		"board_tiles": [BOARD_W, BOARD_H],
		"tile_size": TILE,
	}
	var file := FileAccess.open(ProjectSettings.globalize_path(MANIFEST_DIR + "/oakhaven_p11_import_preview_manifest.json"), FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(data, "\t"))
