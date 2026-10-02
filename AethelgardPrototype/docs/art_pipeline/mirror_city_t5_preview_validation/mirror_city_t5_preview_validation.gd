extends SceneTree

const OUT_ROOT := "res://assets/art_sources/comfyui_tests/mirror_city_t5_preview_validation"
const SCREENSHOT_DIR := OUT_ROOT + "/screenshots"
const BOARD_DIR := OUT_ROOT + "/preview_boards"
const CONTACT_DIR := OUT_ROOT + "/contact_sheets"
const MANIFEST_DIR := OUT_ROOT + "/manifest"
const DIAGNOSTIC_DIR := OUT_ROOT + "/diagnostics"
const DIAGNOSTIC_PATH := DIAGNOSTIC_DIR + "/mirror_city_t5_godot_preview_diagnostics.json"

const BOARD_SIZE := Vector2i(1600, 900)
const PANEL_SIZE := Vector2i(720, 560)
const TILE := 32

const CURRENT_FALLBACK := "res://assets/generated_v2/tilesets/mirror_city_v2_prototype_tileset.png"
const OLD_T2 := "res://assets/art_sources/comfyui_tests/late_hubs_t2_family_builder/generated_tiles/late_hub_t2_mirror_city_family.png"
const VARIANT_A := "res://assets/art_sources/comfyui_tests/mirror_city_t4_identity_rebuild/generated_tiles/mirror_city_t4_variant_a_glass_civic.png"
const VARIANT_B := "res://assets/art_sources/comfyui_tests/mirror_city_t4_identity_rebuild/generated_tiles/mirror_city_t4_variant_b_fractured_reflection.png"
const VARIANT_C := "res://assets/art_sources/comfyui_tests/mirror_city_t4_identity_rebuild/generated_tiles/mirror_city_t4_variant_c_inverted_route.png"
const VARIANT_D := "res://assets/art_sources/comfyui_tests/mirror_city_t4_identity_rebuild/generated_tiles/mirror_city_t4_variant_d_hybrid_best.png"

const PROP_ATLAS := "res://assets/generated_v3/props/phase10mm_environment_prop_atlas.png"
const DECAL_ATLAS := "res://assets/generated_v3/overlays/phase10mm_environment_decal_atlas.png"

const OAKHAVEN_BASELINE := "res://assets/production_art/tilesets/oakhaven/oakhaven_afternoon_tileset.png"
const IRONHOLD_BASELINE := "res://assets/production_art/tilesets/ironhold/ironhold_tileset.png"
const FRACTURED_BASELINE := "res://assets/production_art/tilesets/fractured_wastes/fractured_wastes_tileset.png"

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	_make_dirs()
	var results := {
		"phase": "10M-T5",
		"script": "docs/art_pipeline/mirror_city_t5_preview_validation/mirror_city_t5_preview_validation.gd",
		"project_boot": true,
		"preview_only": true,
		"production_art_changed": false,
		"generated_v2_overwritten": false,
		"generated_v3_overwritten": false,
		"gameplay_scene_script_modified": false,
		"main_menu": await _check_scene_load_only("main menu", "res://scenes/main_menu.tscn"),
		"safety_checks": [],
		"input_checks": [],
		"preview_boards": [],
		"actual_scene_reference": {},
		"story_scene_candidates_skipped": [
			"res://scenes/chapter5/ch5_mirror_city_intro.tscn",
			"res://scenes/chapter5/ch5_mirror_plaza.tscn",
			"res://scenes/chapter5/ch5_mirror_kaelen_confrontation.tscn"
		]
	}
	for check in _input_texture_checks():
		results["input_checks"].append(check)
	for check in _safety_texture_checks():
		results["safety_checks"].append(check)
	for candidate in _candidates():
		results["preview_boards"].append(await _render_preview_board(candidate))
	results["preview_boards"].append(await _render_comparison_board(
		"d_vs_c",
		[
			_candidate_by_id("variant_d_primary"),
			_candidate_by_id("variant_c_backup")
		],
		BOARD_DIR + "/mirror_city_t5_variant_d_vs_c_direct_comparison.png"
	))
	results["preview_boards"].append(await _render_comparison_board(
		"fallback_t2_d_c",
		[
			_candidate_by_id("current_generated_v2"),
			_candidate_by_id("old_t2"),
			_candidate_by_id("variant_d_primary"),
			_candidate_by_id("variant_c_backup")
		],
		BOARD_DIR + "/mirror_city_t5_fallback_t2_d_c_comparison.png"
	))
	results["actual_scene_reference"] = await _check_actual_scene_reference()
	_write_json(DIAGNOSTIC_PATH, results)
	print("Mirror City T5 preview-only validation complete.")
	quit(0)

func _make_dirs() -> void:
	for dir in [SCREENSHOT_DIR, BOARD_DIR, CONTACT_DIR, MANIFEST_DIR, DIAGNOSTIC_DIR]:
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(dir))

func _candidates() -> Array:
	return [
		{
			"id": "current_generated_v2",
			"label": "Current generated_v2 fallback",
			"path": CURRENT_FALLBACK,
			"board": BOARD_DIR + "/mirror_city_t5_current_generated_v2_preview.png",
			"type": "fallback",
			"accent": Color(0.25, 0.72, 0.92),
			"notes": "Current generated_v2 fallback, preserved as rollback evidence."
		},
		{
			"id": "old_t2",
			"label": "Old T2 Mirror City",
			"path": OLD_T2,
			"board": BOARD_DIR + "/mirror_city_t5_old_t2_preview.png",
			"type": "t2",
			"accent": Color(0.78, 0.42, 0.92),
			"notes": "Old T2 candidate, readable but previously judged too generic."
		},
		{
			"id": "variant_d_primary",
			"label": "T4 Variant D primary",
			"path": VARIANT_D,
			"board": BOARD_DIR + "/mirror_city_t5_variant_d_primary_preview.png",
			"type": "t4",
			"accent": Color(0.50, 0.93, 0.95),
			"notes": "Hybrid best candidate, primary for T5."
		},
		{
			"id": "variant_c_backup",
			"label": "T4 Variant C backup",
			"path": VARIANT_C,
			"board": BOARD_DIR + "/mirror_city_t5_variant_c_backup_preview.png",
			"type": "t4",
			"accent": Color(0.72, 0.70, 1.0),
			"notes": "Inverted route candidate, backup for T5."
		},
		{
			"id": "variant_b_reference",
			"label": "T4 Variant B reference",
			"path": VARIANT_B,
			"board": BOARD_DIR + "/mirror_city_t5_variant_b_reference_preview.png",
			"type": "t4",
			"accent": Color(1.0, 0.40, 0.80),
			"notes": "Fractured reflection reference, identity stress test."
		},
		{
			"id": "variant_a_reference",
			"label": "T4 Variant A reference",
			"path": VARIANT_A,
			"board": BOARD_DIR + "/mirror_city_t5_variant_a_reference_preview.png",
			"type": "t4",
			"accent": Color(0.45, 0.86, 1.0),
			"notes": "Glass civic safety reference."
		}
	]

func _candidate_by_id(id: String) -> Dictionary:
	for candidate in _candidates():
		if str(candidate["id"]) == id:
			return candidate
	return {}

func _render_preview_board(candidate: Dictionary) -> Dictionary:
	var board := Image.create(BOARD_SIZE.x, BOARD_SIZE.y, false, Image.FORMAT_RGBA8)
	board.fill(Color(0.035, 0.04, 0.052, 1.0))
	_draw_frame(board, Rect2i(40, 58, BOARD_SIZE.x - 80, BOARD_SIZE.y - 104), Color(0.12, 0.15, 0.18), Color(0.015, 0.018, 0.026))
	var atlas := _load_image(str(candidate["path"]))
	var prop := _load_image(PROP_ATLAS)
	var decal := _load_image(DECAL_ATLAS)
	var accent: Color = candidate["accent"]
	if atlas.is_empty():
		_fill_rect(board, Rect2i(90, 120, 720, 560), Color(0.18, 0.08, 0.10))
	else:
		_render_layout(board, atlas, Rect2i(88, 122, 960, 640), str(candidate["type"]), accent)
		_render_stress_zone(board, atlas, Rect2i(1120, 130, 330, 160), str(candidate["type"]))
		_render_v3_zone(board, prop, decal, Rect2i(1120, 330, 330, 178))
		_render_glow_zone(board, atlas, Rect2i(1120, 548, 330, 130), accent)
		_render_route_marker_zone(board, atlas, Rect2i(1120, 716, 330, 82), accent)
	_draw_marker(board, Vector2i(504, 420), Color(0.34, 0.68, 1.0), Color(0.80, 0.94, 1.0))
	_draw_marker(board, Vector2i(670, 420), Color(1.0, 0.70, 0.34), Color(1.0, 0.90, 0.70))
	var err := board.save_png(ProjectSettings.globalize_path(str(candidate["board"])))
	await process_frame
	return {
		"id": candidate["id"],
		"label": candidate["label"],
		"source": candidate["path"],
		"preview_board": candidate["board"],
		"result": "Pass" if err == OK else "Fail",
		"notes": "Godot image-rendered preview board. Text annotations are added by the T5 report builder."
	}

func _render_comparison_board(id: String, candidates: Array, output_path: String) -> Dictionary:
	var board := Image.create(BOARD_SIZE.x, BOARD_SIZE.y, false, Image.FORMAT_RGBA8)
	board.fill(Color(0.032, 0.038, 0.050, 1.0))
	var slots: Array
	if candidates.size() == 2:
		slots = [
			Rect2i(82, 154, 664, 562),
			Rect2i(854, 154, 664, 562)
		]
	else:
		slots = [
			Rect2i(78, 116, 700, 330),
			Rect2i(822, 116, 700, 330),
			Rect2i(78, 512, 700, 330),
			Rect2i(822, 512, 700, 330)
		]
	for i in range(candidates.size()):
		var candidate: Dictionary = candidates[i]
		var atlas := _load_image(str(candidate["path"]))
		_draw_frame(board, slots[i], Color(0.14, 0.16, 0.20), Color(0.02, 0.025, 0.035))
		if not atlas.is_empty():
			_render_layout(board, atlas, slots[i].grow(-22), str(candidate["type"]), candidate["accent"])
	var err := board.save_png(ProjectSettings.globalize_path(output_path))
	await process_frame
	return {
		"id": id,
		"label": id,
		"source": "multiple",
		"preview_board": output_path,
		"result": "Pass" if err == OK else "Fail",
		"notes": "Godot image-rendered direct comparison board. Text annotations are added by the T5 report builder."
	}

func _render_layout(target: Image, atlas: Image, rect: Rect2i, candidate_type: String, accent: Color) -> void:
	var scale := 1
	var cols := int(rect.size.x / TILE)
	var rows := int(rect.size.y / TILE)
	for y in range(rows):
		for x in range(cols):
			var row := 0
			var col := (x + y * 3) % 16
			if (x + y) % 5 == 0:
				row = 1
			if candidate_type == "fallback":
				row = y % 2
				col = x % 4
			_stamp_cell(target, atlas, row, col, rect.position + Vector2i(x * TILE * scale, y * TILE * scale), scale)
	# Wrapper/border test.
	for x in range(cols):
		_stamp_cell(target, atlas, 4, x % 16, rect.position + Vector2i(x * TILE, 0), scale)
		_stamp_cell(target, atlas, 5, x % 16, rect.position + Vector2i(x * TILE, (rows - 1) * TILE), scale)
	for y in range(rows):
		_stamp_cell(target, atlas, 4, (y + 4) % 16, rect.position + Vector2i(0, y * TILE), scale)
		_stamp_cell(target, atlas, 5, (y + 4) % 16, rect.position + Vector2i((cols - 1) * TILE, y * TILE), scale)
	# Primary mirrored route grammar.
	var center_y := int(rows / 2)
	var center_x := int(cols / 2)
	for x in range(3, cols - 3):
		_stamp_cell(target, atlas, 2, x % 16, rect.position + Vector2i(x * TILE, center_y * TILE), scale)
		_stamp_cell(target, atlas, 2, (15 - x) % 16, rect.position + Vector2i(x * TILE, (center_y - 2) * TILE), scale)
	for y in range(3, rows - 3):
		_stamp_cell(target, atlas, 3, y % 16, rect.position + Vector2i(center_x * TILE, y * TILE), scale)
		_stamp_cell(target, atlas, 3, (15 - y) % 16, rect.position + Vector2i((center_x - 4) * TILE, y * TILE), scale)
	# Reflection corridor.
	for x in range(4, cols - 4):
		_stamp_cell(target, atlas, 6, x % 16, rect.position + Vector2i(x * TILE, (center_y + 3) * TILE), scale)
		_stamp_cell(target, atlas, 7, (15 - x) % 16, rect.position + Vector2i(x * TILE, (center_y + 4) * TILE), scale)
	# Fractured mirror zone.
	for y in range(rows - 7, rows - 2):
		for x in range(3, 10):
			_stamp_cell(target, atlas, 11, (x + y) % 16, rect.position + Vector2i(x * TILE, y * TILE), scale)
	_draw_line(target, rect.position + Vector2i(96, rect.size.y - 210), rect.position + Vector2i(305, rect.size.y - 60), accent, 2)
	_draw_line(target, rect.position + Vector2i(124, rect.size.y - 64), rect.position + Vector2i(330, rect.size.y - 202), Color(1.0, 0.36, 0.78, 0.86), 1)
	# Dark label-safe area.
	_fill_rect(target, Rect2i(rect.position + Vector2i(rect.size.x - 370, rect.size.y - 210), Vector2i(314, 132)), Color(0.010, 0.015, 0.026, 0.96))
	_draw_frame(target, Rect2i(rect.position + Vector2i(rect.size.x - 370, rect.size.y - 210), Vector2i(314, 132)), Color(0.10, 0.18, 0.23), Color(0.010, 0.015, 0.026))
	# Route marker sample and non-blinding glow sample.
	for x in range(0, 6):
		_stamp_cell(target, atlas, 8, x % 16, rect.position + Vector2i((center_x + x - 3) * TILE, (center_y - 5) * TILE), scale)
	_fill_rect(target, Rect2i(rect.position + Vector2i(center_x * TILE - 10, (center_y - 5) * TILE + 8), Vector2i(20, 16)), accent)

func _render_stress_zone(target: Image, atlas: Image, rect: Rect2i, candidate_type: String) -> void:
	_draw_frame(target, rect, Color(0.12, 0.145, 0.18), Color(0.025, 0.030, 0.040))
	var cols := int((rect.size.x - 22) / TILE)
	var rows := int((rect.size.y - 22) / TILE)
	for y in range(rows):
		for x in range(cols):
			var row := 10 if candidate_type != "fallback" else y % 2
			var col := (x + y) % 16 if candidate_type != "fallback" else x % 4
			_stamp_cell(target, atlas, row, col, rect.position + Vector2i(12 + x * TILE, 12 + y * TILE), 1)

func _render_v3_zone(target: Image, prop: Image, decal: Image, rect: Rect2i) -> void:
	_draw_frame(target, rect, Color(0.12, 0.145, 0.18), Color(0.025, 0.030, 0.040))
	if not prop.is_empty():
		var crop := _safe_region(prop, Rect2i(620, 370, 170, 120))
		crop.resize(126, 90, Image.INTERPOLATE_NEAREST)
		target.blend_rect(crop, Rect2i(Vector2i.ZERO, crop.get_size()), rect.position + Vector2i(24, 42))
	if not decal.is_empty():
		var crop_decal := _safe_region(decal, Rect2i(520, 362, 180, 130))
		crop_decal.resize(150, 104, Image.INTERPOLATE_NEAREST)
		target.blend_rect(crop_decal, Rect2i(Vector2i.ZERO, crop_decal.get_size()), rect.position + Vector2i(172, 36))

func _render_glow_zone(target: Image, atlas: Image, rect: Rect2i, accent: Color) -> void:
	_draw_frame(target, rect, Color(0.12, 0.145, 0.18), Color(0.015, 0.020, 0.030))
	for x in range(0, 8):
		_stamp_cell(target, atlas, 8, x % 16, rect.position + Vector2i(22 + x * TILE, 46), 1)
	_fill_rect(target, Rect2i(rect.position + Vector2i(24, 88), Vector2i(250, 15)), Color(accent.r, accent.g, accent.b, 0.40))
	_fill_rect(target, Rect2i(rect.position + Vector2i(24, 108), Vector2i(250, 6)), Color(1.0, 0.42, 0.84, 0.34))

func _render_route_marker_zone(target: Image, atlas: Image, rect: Rect2i, accent: Color) -> void:
	_draw_frame(target, rect, Color(0.12, 0.145, 0.18), Color(0.015, 0.020, 0.030))
	for x in range(0, 8):
		_stamp_cell(target, atlas, 12, x % 16, rect.position + Vector2i(26 + x * TILE, 24), 1)
	_draw_line(target, rect.position + Vector2i(60, 62), rect.position + Vector2i(270, 30), accent, 2)

func _stamp_cell(target: Image, atlas: Image, row: int, col: int, pos: Vector2i, scale: int) -> void:
	if atlas.is_empty():
		return
	var cols: int = max(1, int(atlas.get_width() / TILE))
	var rows: int = max(1, int(atlas.get_height() / TILE))
	var src := Rect2i((col % cols) * TILE, (row % rows) * TILE, TILE, TILE)
	var cell := _safe_region(atlas, src)
	if scale != 1:
		cell.resize(TILE * scale, TILE * scale, Image.INTERPOLATE_NEAREST)
	target.blend_rect(cell, Rect2i(Vector2i.ZERO, cell.get_size()), pos)

func _safe_region(source: Image, rect: Rect2i) -> Image:
	var src := rect
	src.position.x = clampi(src.position.x, 0, max(0, source.get_width() - 1))
	src.position.y = clampi(src.position.y, 0, max(0, source.get_height() - 1))
	src.size.x = mini(src.size.x, source.get_width() - src.position.x)
	src.size.y = mini(src.size.y, source.get_height() - src.position.y)
	if src.size.x <= 0 or src.size.y <= 0:
		return Image.create(TILE, TILE, false, Image.FORMAT_RGBA8)
	return source.get_region(src)

func _draw_frame(image: Image, rect: Rect2i, border: Color, fill: Color) -> void:
	image.fill_rect(rect, border)
	image.fill_rect(rect.grow(-4), fill)

func _fill_rect(image: Image, rect: Rect2i, color: Color) -> void:
	image.fill_rect(rect, color)

func _draw_marker(image: Image, center: Vector2i, fill: Color, edge: Color) -> void:
	for y in range(-16, 17):
		for x in range(-16, 17):
			var dist := x * x + y * y
			var p := center + Vector2i(x, y)
			if p.x < 0 or p.y < 0 or p.x >= image.get_width() or p.y >= image.get_height():
				continue
			if dist <= 256:
				image.set_pixelv(p, fill)
			if dist <= 324 and dist >= 242:
				image.set_pixelv(p, edge)

func _draw_line(image: Image, a: Vector2i, b: Vector2i, color: Color, width: int) -> void:
	var delta := b - a
	var steps := maxi(abs(delta.x), abs(delta.y))
	if steps <= 0:
		return
	for i in range(steps + 1):
		var t := float(i) / float(steps)
		var p := Vector2i(roundi(lerpf(a.x, b.x, t)), roundi(lerpf(a.y, b.y, t)))
		for oy in range(-width, width + 1):
			for ox in range(-width, width + 1):
				var q := p + Vector2i(ox, oy)
				if q.x >= 0 and q.y >= 0 and q.x < image.get_width() and q.y < image.get_height():
					image.set_pixelv(q, color)

func _load_image(path: String) -> Image:
	var image := Image.new()
	if path == "":
		return image
	var err := image.load(ProjectSettings.globalize_path(path))
	if err != OK:
		push_warning("Could not load image: " + path)
	return image

func _input_texture_checks() -> Array:
	return [
		_check_texture("T4 Variant A", VARIANT_A, true, Vector2i(512, 512)),
		_check_texture("T4 Variant B", VARIANT_B, true, Vector2i(512, 512)),
		_check_texture("T4 Variant C", VARIANT_C, true, Vector2i(512, 512)),
		_check_texture("T4 Variant D", VARIANT_D, true, Vector2i(512, 512)),
		_check_texture("old T2 Mirror City candidate", OLD_T2, true, Vector2i(512, 512)),
		_check_texture("current generated_v2 Mirror City fallback", CURRENT_FALLBACK, true, Vector2i(128, 64)),
		_check_texture("V3 props", PROP_ATLAS, true, Vector2i(1536, 1024)),
		_check_texture("V3 decals", DECAL_ATLAS, true, Vector2i(1536, 1024))
	]

func _safety_texture_checks() -> Array:
	return [
		_check_texture("Oakhaven baseline preservation", OAKHAVEN_BASELINE, true, Vector2i(512, 512)),
		_check_texture("Ironhold baseline preservation", IRONHOLD_BASELINE, true, Vector2i(512, 512)),
		_check_texture("Fractured Wastes baseline preservation", FRACTURED_BASELINE, true, Vector2i(512, 512)),
		_check_texture("shared V3 props preservation", PROP_ATLAS, true, Vector2i(1536, 1024)),
		_check_texture("shared V3 decals preservation", DECAL_ATLAS, true, Vector2i(1536, 1024)),
		_check_texture("Mirror City generated_v2 fallback preservation", CURRENT_FALLBACK, true, Vector2i(128, 64))
	]

func _check_texture(label: String, path: String, should_exist: bool, expected_size: Vector2i) -> Dictionary:
	var exists := FileAccess.file_exists(path) or FileAccess.file_exists(ProjectSettings.globalize_path(path)) or ResourceLoader.exists(path)
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
	return {
		"check": label,
		"path": path,
		"exists": exists,
		"loaded": loaded,
		"size": [image.get_width(), image.get_height()] if loaded else [0, 0],
		"result": "Pass" if ok else "Fail"
	}

func _check_scene_load_only(label: String, path: String) -> Dictionary:
	if not ResourceLoader.exists(path):
		return {"check": label, "path": path, "result": "Skipped", "notes": "scene path not found"}
	var packed := load(path) as PackedScene
	if not packed:
		return {"check": label, "path": path, "result": "Fail", "notes": "PackedScene load failed"}
	var scene := packed.instantiate()
	var ok := scene != null
	if scene:
		scene.free()
	return {"check": label, "path": path, "result": "Pass" if ok else "Fail", "notes": "Loaded and instantiated only; not connected to gameplay."}

func _check_actual_scene_reference() -> Dictionary:
	var path := "res://scenes/regions/mirror_city_revisit_hub.tscn"
	var result := {
		"scene": path,
		"scene_load": "Not run",
		"screenshot_status": "Skipped",
		"screenshot": "",
		"risk": "Low-medium: safe revisit hub candidate; story scenes skipped.",
		"player_found": false,
		"camera_found": false,
		"visual_layer_found": false,
		"label_or_prompt_found": false,
		"notes": ""
	}
	if not ResourceLoader.exists(path):
		result["scene_load"] = "Skipped"
		result["risk"] = "Scene path missing."
		return result
	var packed := load(path) as PackedScene
	if not packed:
		result["scene_load"] = "Fail"
		result["notes"] = "PackedScene load failed."
		return result
	var scene := packed.instantiate()
	result["scene_load"] = "Pass" if scene != null else "Fail"
	if scene:
		get_root().add_child(scene)
		current_scene = scene
		for i in range(8):
			await process_frame
		var flags := _scan_scene(scene)
		result["player_found"] = flags["player_found"]
		result["camera_found"] = flags["camera_found"]
		result["visual_layer_found"] = flags["visual_layer_found"]
		result["label_or_prompt_found"] = flags["label_or_prompt_found"]
		result["notes"] = "Loaded in tree read-only, then freed without interaction. Screenshot skipped because no T4 art was swapped into the scene."
		scene.queue_free()
		await process_frame
		current_scene = null
	return result

func _scan_scene(node: Node) -> Dictionary:
	var flags := {
		"player_found": false,
		"camera_found": false,
		"visual_layer_found": false,
		"label_or_prompt_found": false
	}
	_scan_recursive(node, flags)
	return flags

func _scan_recursive(node: Node, flags: Dictionary) -> void:
	var lower := node.name.to_lower()
	if lower.contains("player"):
		flags["player_found"] = true
	if node is Camera2D or lower.contains("camera"):
		flags["camera_found"] = true
	if node is TileMap or node is TileMapLayer or node is Sprite2D or lower.contains("visual") or lower.contains("tile"):
		flags["visual_layer_found"] = true
	if node is Label or node is RichTextLabel or lower.contains("label") or lower.contains("prompt"):
		flags["label_or_prompt_found"] = true
	for child in node.get_children():
		_scan_recursive(child, flags)

func _write_json(path: String, data: Dictionary) -> void:
	var file := FileAccess.open(ProjectSettings.globalize_path(path), FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(data, "\t"))
		file.close()
