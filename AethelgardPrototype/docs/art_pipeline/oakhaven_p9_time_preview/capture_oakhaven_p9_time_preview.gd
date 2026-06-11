extends SceneTree

const TILE := 32
const BOARD_W := 24
const BOARD_H := 18

const SCREENSHOT_DIR := "res://assets/art_sources/comfyui_tests/oakhaven_p9_time_preview/screenshots"
const CONTACT_DIR := "res://assets/art_sources/comfyui_tests/oakhaven_p9_time_preview/contact_sheets"
const PREVIEW_DIR := "res://assets/art_sources/comfyui_tests/oakhaven_p9_time_preview/preview_outputs"
const MANIFEST_DIR := "res://assets/art_sources/comfyui_tests/oakhaven_p9_time_preview/manifest"

const VARIANTS := {
	"morning": {
		"name": "Morning",
		"atlas": "res://assets/art_sources/comfyui_tests/oakhaven_p8/generated_tiles/oakhaven_p8_variant_a_clean.png",
		"screenshot": "res://assets/art_sources/comfyui_tests/oakhaven_p9_time_preview/screenshots/oakhaven_p9_morning_preview.png",
		"mood": "fresh, readable, early day"
	},
	"afternoon": {
		"name": "Afternoon",
		"atlas": "res://assets/art_sources/comfyui_tests/oakhaven_p8/generated_tiles/oakhaven_p8_variant_b_textured.png",
		"screenshot": "res://assets/art_sources/comfyui_tests/oakhaven_p9_time_preview/screenshots/oakhaven_p9_afternoon_preview.png",
		"mood": "default Oakhaven daytime"
	},
	"night": {
		"name": "Night",
		"atlas": "res://assets/art_sources/comfyui_tests/oakhaven_p8/generated_tiles/oakhaven_p8_variant_c_dark_glitch.png",
		"screenshot": "res://assets/art_sources/comfyui_tests/oakhaven_p9_time_preview/screenshots/oakhaven_p9_night_preview.png",
		"mood": "darker magical night"
	}
}

const TILE_COORDS := {
	"grass_base": Vector2i(0, 0),
	"grass_darker": Vector2i(1, 0),
	"grass_lighter": Vector2i(2, 0),
	"grass_patchy": Vector2i(3, 0),
	"grass_sparse": Vector2i(4, 0),
	"grass_flower_speckled": Vector2i(5, 0),
	"grass_worn": Vector2i(6, 0),
	"grass_shadowed": Vector2i(7, 0),
	"grass_leaf_scatter": Vector2i(9, 0),
	"grass_tiny_stones": Vector2i(12, 0),
	"grass_plain_backup": Vector2i(15, 0),
	"grass_dense_blades": Vector2i(0, 1),
	"dirt_center": Vector2i(0, 3),
	"dirt_variation": Vector2i(1, 3),
	"path_worn_center": Vector2i(2, 3),
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
	"wooden_wall_tile": Vector2i(2, 11),
	"roof_edge_tile": Vector2i(3, 11),
	"roof_corner_tile": Vector2i(4, 11),
	"roof_center_tile": Vector2i(5, 11),
	"foundation_shadow": Vector2i(6, 11),
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
	"small_log": Vector2i(0, 15)
}

func _init() -> void:
	_ensure_output_dirs()
	var screenshots := {}
	for key in ["morning", "afternoon", "night"]:
		var data: Dictionary = VARIANTS[key]
		var atlas := Image.load_from_file(ProjectSettings.globalize_path(data["atlas"]))
		if atlas == null or atlas.is_empty():
			push_error("P9 preview could not load atlas: %s" % data["atlas"])
			quit(1)
			return
		var board := _build_board(atlas, key)
		var save_path: String = data["screenshot"]
		var err := board.save_png(ProjectSettings.globalize_path(save_path))
		if err != OK:
			push_error("P9 preview could not save screenshot %s: %s" % [save_path, err])
			quit(1)
			return
		screenshots[key] = save_path
		print("P9 screenshot saved: %s" % save_path)

	var contact := _build_time_contact_sheet(screenshots)
	var contact_path := "res://assets/art_sources/comfyui_tests/oakhaven_p9_time_preview/contact_sheets/oakhaven_p9_time_of_day_contact_sheet.png"
	var contact_err := contact.save_png(ProjectSettings.globalize_path(contact_path))
	if contact_err != OK:
		push_error("P9 preview could not save time contact sheet: %s" % contact_err)
		quit(1)
		return

	var fallback_sheet := _build_fallback_contact_sheet(screenshots)
	var fallback_path := "res://assets/art_sources/comfyui_tests/oakhaven_p9_time_preview/contact_sheets/oakhaven_p9_fallback_vs_time_preview_contact_sheet.png"
	var fallback_err := fallback_sheet.save_png(ProjectSettings.globalize_path(fallback_path))
	if fallback_err != OK:
		push_error("P9 preview could not save fallback contact sheet: %s" % fallback_err)
		quit(1)
		return

	_write_capture_manifest(screenshots, contact_path, fallback_path)
	print("P9 time-of-day preview capture: PASS")
	quit(0)

func _ensure_output_dirs() -> void:
	for path in [SCREENSHOT_DIR, CONTACT_DIR, PREVIEW_DIR, MANIFEST_DIR]:
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(path))

func _build_board(atlas: Image, time_key: String) -> Image:
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
	_apply_time_tint(board, time_key)
	_draw_player_marker(board, Vector2i(12 * TILE + 9, 9 * TILE + 5), time_key)
	_draw_npc_marker(board, Vector2i(14 * TILE + 12, 9 * TILE + 8), time_key)
	return board

func _add_transition_patch(board: Image, atlas: Image) -> void:
	var x0 := 2
	var y0 := 12
	_blit_tile(board, atlas, "transition_outer_tl", x0, y0)
	_blit_tile(board, atlas, "transition_top_edge", x0 + 1, y0)
	_blit_tile(board, atlas, "transition_top_edge", x0 + 2, y0)
	_blit_tile(board, atlas, "transition_outer_tr", x0 + 3, y0)
	_blit_tile(board, atlas, "transition_left_edge", x0, y0 + 1)
	_blit_tile(board, atlas, "dirt_center", x0 + 1, y0 + 1)
	_blit_tile(board, atlas, "dirt_variation", x0 + 2, y0 + 1)
	_blit_tile(board, atlas, "transition_right_edge", x0 + 3, y0 + 1)
	_blit_tile(board, atlas, "transition_outer_bl", x0, y0 + 2)
	_blit_tile(board, atlas, "transition_bottom_edge", x0 + 1, y0 + 2)
	_blit_tile(board, atlas, "transition_bottom_edge", x0 + 2, y0 + 2)
	_blit_tile(board, atlas, "transition_outer_br", x0 + 3, y0 + 2)

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
	var count := int(n) + int(e) + int(s) + int(w)
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
		["wall_moss_base", "doorway_base", "cottage_step", "wall_shadow_right"]
	]
	for y in range(rows.size()):
		for x in range(rows[y].size()):
			_blit_tile(board, atlas, rows[y][x], bx + x, by + y)

func _add_boundaries(board: Image, atlas: Image) -> void:
	for x in range(2, 11):
		_blit_tile(board, atlas, "fence_horizontal_middle", x, 3)
	for y in range(4, 9):
		_blit_tile(board, atlas, "fence_vertical_middle", 2, y)
	_blit_tile(board, atlas, "fence_post", 2, 3)
	_blit_tile(board, atlas, "fence_post", 10, 3)
	_blit_tile(board, atlas, "fence_end_bottom", 2, 9)
	for x in range(15, 22):
		_blit_tile(board, atlas, "hedge_horizontal", x, 13)
	_blit_tile(board, atlas, "hedge_corner_tl", 14, 13)
	_blit_tile(board, atlas, "hedge_corner_tr", 22, 13)
	for y in range(14, 17):
		_blit_tile(board, atlas, "hedge_vertical", 14, y)
		_blit_tile(board, atlas, "hedge_vertical", 22, y)
	_blit_tile(board, atlas, "hedge_broken_opening", 18, 13)

func _add_props(board: Image, atlas: Image) -> void:
	for entry in [
		["flower_patch", 5, 5],
		["herb_patch", 6, 6],
		["wooden_sign", 8, 7],
		["small_stone", 16, 7],
		["tree_stump", 18, 15],
		["crate_barrel_simple", 21, 7],
		["soft_shadow_blob", 17, 7],
		["glitch_flower_rune_accent", 12, 5],
		["ground_leaf_scatter", 7, 11],
		["village_marker_tile", 14, 10],
		["flower_patch_blue", 20, 15],
		["tiny_mushroom_cluster", 17, 15],
		["small_log", 6, 15],
		["dirt_small_stone_embedded", 4, 10],
		["shadow_only_tile", 19, 6]
	]:
		_blit_tile(board, atlas, entry[0], int(entry[1]), int(entry[2]))

func _blit_tile(board: Image, atlas: Image, tile_name: String, cell_x: int, cell_y: int) -> void:
	var coord: Vector2i = TILE_COORDS[tile_name]
	var source_rect := Rect2i(coord.x * TILE, coord.y * TILE, TILE, TILE)
	var dest := Vector2i(cell_x * TILE, cell_y * TILE)
	board.blend_rect(atlas, source_rect, dest)

func _apply_time_tint(image: Image, time_key: String) -> void:
	var width := image.get_width()
	var height := image.get_height()
	for y in range(height):
		for x in range(width):
			var c := image.get_pixel(x, y)
			if time_key == "morning":
				c.r = clampf(c.r * 1.05 + 0.025, 0.0, 1.0)
				c.g = clampf(c.g * 1.025 + 0.015, 0.0, 1.0)
				c.b = clampf(c.b * 0.97, 0.0, 1.0)
			elif time_key == "night":
				c.r = clampf(c.r * 0.82, 0.0, 1.0)
				c.g = clampf(c.g * 0.88, 0.0, 1.0)
				c.b = clampf(c.b * 1.04 + 0.018, 0.0, 1.0)
			image.set_pixel(x, y, c)

func _draw_player_marker(image: Image, top_left: Vector2i, time_key: String) -> void:
	var outline := Color(0.03, 0.035, 0.04, 1.0)
	var body := Color(0.25, 0.66, 0.95, 1.0)
	var cloak := Color(0.08, 0.20, 0.48, 1.0)
	if time_key == "night":
		body = Color(0.55, 0.86, 1.0, 1.0)
		cloak = Color(0.12, 0.28, 0.64, 1.0)
	_draw_rect(image, Rect2i(top_left.x + 3, top_left.y + 2, 8, 7), outline)
	_draw_rect(image, Rect2i(top_left.x + 4, top_left.y + 3, 6, 5), Color(0.96, 0.83, 0.62, 1.0))
	_draw_rect(image, Rect2i(top_left.x + 2, top_left.y + 9, 11, 13), outline)
	_draw_rect(image, Rect2i(top_left.x + 3, top_left.y + 10, 9, 11), cloak)
	_draw_rect(image, Rect2i(top_left.x + 5, top_left.y + 10, 5, 8), body)
	_draw_rect(image, Rect2i(top_left.x + 3, top_left.y + 22, 3, 3), outline)
	_draw_rect(image, Rect2i(top_left.x + 9, top_left.y + 22, 3, 3), outline)

func _draw_npc_marker(image: Image, top_left: Vector2i, _time_key: String) -> void:
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

func _build_time_contact_sheet(screenshots: Dictionary) -> Image:
	var width := BOARD_W * TILE * 3
	var height := BOARD_H * TILE
	var sheet := Image.create(width, height, false, Image.FORMAT_RGBA8)
	sheet.fill(Color(0.08, 0.085, 0.10, 1.0))
	var x_offset := 0
	for key in ["morning", "afternoon", "night"]:
		var img := Image.load_from_file(ProjectSettings.globalize_path(screenshots[key]))
		sheet.blit_rect(img, Rect2i(0, 0, img.get_width(), img.get_height()), Vector2i(x_offset, 0))
		x_offset += img.get_width()
	return sheet

func _build_fallback_contact_sheet(screenshots: Dictionary) -> Image:
	var fallback := Image.load_from_file(ProjectSettings.globalize_path("res://assets/generated_v2/tilesets/oakhaven_v2_prototype_tileset.png"))
	var p7 := Image.load_from_file(ProjectSettings.globalize_path("res://assets/art_sources/comfyui_tests/oakhaven_p7/oakhaven_p7_review_only_draft_atlas.png"))
	var afternoon := Image.load_from_file(ProjectSettings.globalize_path(screenshots["afternoon"]))
	var sheet := Image.create(1280, 640, false, Image.FORMAT_RGBA8)
	sheet.fill(Color(0.08, 0.085, 0.10, 1.0))
	if fallback != null and not fallback.is_empty():
		fallback.resize(512, 256, Image.INTERPOLATE_NEAREST)
		sheet.blit_rect(fallback, Rect2i(0, 0, 512, 256), Vector2i(16, 16))
	if p7 != null and not p7.is_empty():
		var p7_bg := _checker_image(512, 512)
		p7_bg.blend_rect(p7, Rect2i(0, 0, 512, 512), Vector2i.ZERO)
		sheet.blit_rect(p7_bg, Rect2i(0, 0, 512, 512), Vector2i(16, 112))
	if afternoon != null and not afternoon.is_empty():
		sheet.blit_rect(afternoon, Rect2i(0, 0, afternoon.get_width(), afternoon.get_height()), Vector2i(544, 32))
	return sheet

func _checker_image(width: int, height: int) -> Image:
	var image := Image.create(width, height, false, Image.FORMAT_RGBA8)
	image.fill(Color(0.12, 0.13, 0.16, 1.0))
	for y in range(0, height, 16):
		for x in range(0, width, 16):
			var color := Color(0.19, 0.20, 0.23, 1.0) if posmod(x / 16 + y / 16, 2) == 0 else Color(0.14, 0.15, 0.18, 1.0)
			_draw_rect(image, Rect2i(x, y, 16, 16), color)
	return image

func _write_capture_manifest(screenshots: Dictionary, contact_path: String, fallback_path: String) -> void:
	var data := {
		"phase": "10M-P9",
		"capture_method": "Godot headless Image composition from preview-only P8 atlases",
		"preview_only": true,
		"production_art_changed": false,
		"screenshots": screenshots,
		"contact_sheet": contact_path,
		"fallback_comparison_sheet": fallback_path,
		"board_tiles": [BOARD_W, BOARD_H],
		"tile_size": TILE
	}
	var file := FileAccess.open(ProjectSettings.globalize_path(MANIFEST_DIR + "/oakhaven_p9_capture_manifest.json"), FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(data, "\t"))
