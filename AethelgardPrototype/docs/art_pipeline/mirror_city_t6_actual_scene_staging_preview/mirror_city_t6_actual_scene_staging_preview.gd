extends SceneTree

const PHASE := "10M-T6"
const VIEWPORT_SIZE := Vector2i(1280, 720)

const OUT_ROOT := "res://assets/art_sources/comfyui_tests/mirror_city_t6_actual_scene_staging_preview"
const SCREENSHOT_DIR := OUT_ROOT + "/screenshots"
const BOARD_DIR := OUT_ROOT + "/preview_boards"
const CONTACT_DIR := OUT_ROOT + "/contact_sheets"
const MANIFEST_DIR := OUT_ROOT + "/manifest"
const DIAGNOSTIC_DIR := OUT_ROOT + "/diagnostics"
const DIAGNOSTIC_PATH := DIAGNOSTIC_DIR + "/mirror_city_t6_capture_diagnostics.json"

const SAFE_SCENE := "res://scenes/regions/mirror_city_revisit_hub.tscn"
const RISKY_STORY_SCENES := [
	"res://scenes/chapter5/ch5_mirror_city_intro.tscn",
	"res://scenes/chapter5/ch5_mirror_plaza.tscn",
	"res://scenes/chapter5/ch5_mirror_kaelen_confrontation.tscn",
]

const CURRENT_FALLBACK := "res://assets/generated_v2/tilesets/mirror_city_v2_prototype_tileset.png"
const VARIANT_D := "res://assets/art_sources/comfyui_tests/mirror_city_t4_identity_rebuild/generated_tiles/mirror_city_t4_variant_d_hybrid_best.png"
const VARIANT_C := "res://assets/art_sources/comfyui_tests/mirror_city_t4_identity_rebuild/generated_tiles/mirror_city_t4_variant_c_inverted_route.png"
const OLD_T2 := "res://assets/art_sources/comfyui_tests/late_hubs_t2_family_builder/generated_tiles/late_hub_t2_mirror_city_family.png"
const T5_REVIEW := "res://docs/art_pipeline/mirror_city_t5_preview_validation_review.md"

const PROP_ATLAS := "res://assets/generated_v3/props/phase10mm_environment_prop_atlas.png"
const DECAL_ATLAS := "res://assets/generated_v3/overlays/phase10mm_environment_decal_atlas.png"
const OAKHAVEN_BASELINE := "res://assets/production_art/tilesets/oakhaven/oakhaven_afternoon_tileset.png"
const IRONHOLD_BASELINE := "res://assets/production_art/tilesets/ironhold/ironhold_tileset.png"
const FRACTURED_BASELINE := "res://assets/production_art/tilesets/fractured_wastes/fractured_wastes_tileset.png"

const TILE := 32
const FLOOR_POINTS := [
	Vector2(168, 188), Vector2(376, 146), Vector2(932, 150),
	Vector2(1122, 238), Vector2(1090, 518), Vector2(878, 594),
	Vector2(320, 582), Vector2(154, 476),
]

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	get_root().size = VIEWPORT_SIZE
	_make_dirs()
	var results := {
		"phase": PHASE,
		"script": "docs/art_pipeline/mirror_city_t6_actual_scene_staging_preview/mirror_city_t6_actual_scene_staging_preview.gd",
		"scene_used": SAFE_SCENE,
		"preview_only": true,
		"staging_method": "In-memory temporary Sprite2D visual layer added after scene load; scene and scripts are never saved.",
		"risky_story_scenes_skipped": RISKY_STORY_SCENES,
		"input_checks": _input_checks(),
		"safety_checks": _safety_checks(),
		"scene_reference": await _inspect_scene_reference(),
		"captures": [],
	}
	var packed_scene := load(SAFE_SCENE) as PackedScene
	if not packed_scene:
		results["scene_reference"]["scene_load"] = "Fail"
		results["scene_reference"]["notes"] = "Could not load safe Mirror City revisit hub."
		_write_json(DIAGNOSTIC_PATH, results)
		push_error("T6 could not load safe Mirror City scene.")
		quit(1)
		return
	for candidate in _candidates():
		results["captures"].append(await _capture_candidate(packed_scene, candidate))
	_write_json(DIAGNOSTIC_PATH, results)
	print("Mirror City T6 actual-scene staging preview complete.")
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
			"type": "fallback",
			"screenshot": SCREENSHOT_DIR + "/mirror_city_t6_current_generated_v2_actual_scene_preview.png",
			"board": BOARD_DIR + "/mirror_city_t6_current_generated_v2_scene_composition_board.png",
			"accent": Color(0.30, 0.82, 0.95),
		},
		{
			"id": "variant_d_primary",
			"label": "T4 Variant D primary",
			"path": VARIANT_D,
			"type": "t4_d",
			"screenshot": SCREENSHOT_DIR + "/mirror_city_t6_variant_d_actual_scene_preview.png",
			"board": BOARD_DIR + "/mirror_city_t6_variant_d_scene_composition_board.png",
			"accent": Color(0.56, 0.96, 1.00),
		},
		{
			"id": "variant_c_backup",
			"label": "T4 Variant C backup",
			"path": VARIANT_C,
			"type": "t4_c",
			"screenshot": SCREENSHOT_DIR + "/mirror_city_t6_variant_c_actual_scene_preview.png",
			"board": BOARD_DIR + "/mirror_city_t6_variant_c_scene_composition_board.png",
			"accent": Color(0.78, 0.76, 1.00),
		},
	]

func _capture_candidate(packed_scene: PackedScene, candidate: Dictionary) -> Dictionary:
	if current_scene and is_instance_valid(current_scene):
		current_scene.queue_free()
		await process_frame
		await process_frame

	var scene := packed_scene.instantiate()
	get_root().add_child(scene)
	current_scene = scene
	for _i in range(10):
		await process_frame

	var player := _find_node_by_name(scene, "Player") as Node2D
	if player:
		player.global_position = Vector2(640, 430)
	var camera := _find_node_by_name(scene, "LateHubCamera") as Camera2D
	if camera:
		camera.position_smoothing_enabled = false
		camera.zoom = Vector2(1.45, 1.45)
		camera.make_current()
		camera.reset_smoothing()
	_show_preview_prompts(scene)

	var atlas := _load_image(str(candidate["path"]))
	var stage_image := _build_staged_floor_image(atlas, str(candidate["type"]), candidate["accent"])
	var preview_layer := _add_temporary_preview_layer(scene, stage_image, str(candidate["label"]))
	var board_status := _save_scene_composition_board(candidate, stage_image, scene)

	for _i in range(12):
		await physics_frame
		await process_frame

	var screenshot_status := "Skipped"
	var screenshot_note := ""
	var screenshot_path := ""
	if _can_attempt_viewport_capture():
		var viewport_image: Image = get_root().get_texture().get_image()
		if viewport_image != null and not viewport_image.is_empty():
			var err := viewport_image.save_png(ProjectSettings.globalize_path(str(candidate["screenshot"])))
			if err == OK:
				screenshot_status = "Pass"
				screenshot_path = str(candidate["screenshot"])
				screenshot_note = "Live viewport screenshot from the safe Mirror City revisit hub with temporary in-memory staging layer."
			else:
				screenshot_status = "Fail"
				screenshot_note = "Viewport image was present but save_png failed: %s" % err
		else:
			screenshot_status = "FallbackBoardOnly"
			screenshot_note = "Viewport image was empty; deterministic scene-composition board is the evidence."
	else:
		screenshot_status = "FallbackBoardOnly"
		screenshot_note = "Headless dummy renderer detected; deterministic scene-composition board is the evidence."

	var scan := _scan_scene(scene)
	var result := {
		"id": str(candidate["id"]),
		"label": str(candidate["label"]),
		"source_texture": str(candidate["path"]),
		"temporary_layer_name": preview_layer.name if preview_layer else "",
		"temporary_layer_z_index": preview_layer.z_index if preview_layer else 0,
		"screenshot": screenshot_path,
		"screenshot_status": screenshot_status,
		"screenshot_note": screenshot_note,
		"composition_board": str(candidate["board"]),
		"composition_board_status": board_status,
		"player_found": scan["player_found"],
		"camera_found": scan["camera_found"],
		"visual_layer_found": scan["visual_layer_found"],
		"label_count": scan["label_count"],
		"prompt_count": scan["prompt_count"],
		"v3_nodes_found": scan["v3_nodes_found"],
		"runtime_files_modified": false,
	}
	scene.queue_free()
	await process_frame
	current_scene = null
	return result

func _build_staged_floor_image(atlas: Image, candidate_type: String, accent: Color) -> Image:
	var image := Image.create(VIEWPORT_SIZE.x, VIEWPORT_SIZE.y, false, Image.FORMAT_RGBA8)
	image.fill(Color(0.0, 0.0, 0.0, 0.0))
	if atlas.is_empty():
		return image
	for y in range(128, 612, TILE):
		for x in range(128, 1156, TILE):
			var center := Vector2(float(x + TILE / 2), float(y + TILE / 2))
			if not Geometry2D.is_point_in_polygon(center, PackedVector2Array(FLOOR_POINTS)):
				continue
			var row := 0
			var col := int((x / TILE + y / TILE) % 16)
			if (x / TILE + y / TILE) % 5 == 0:
				row = 1
			if candidate_type == "fallback":
				row = int((y / TILE) % 2)
				col = int((x / TILE) % 4)
			_stamp_cell(image, atlas, row, col, Vector2i(x, y), 1, 0.86)
	# Mirror route grammar, mapped to the real revisit hub floor spine.
	for x in range(224, 1060, TILE):
		_stamp_cell(image, atlas, 2, int(x / TILE) % 16, Vector2i(x, 424), 1, 0.96)
	for y in range(210, 548, TILE):
		_stamp_cell(image, atlas, 3, int(y / TILE) % 16, Vector2i(624, y), 1, 0.96)
	for x in range(314, 966, TILE):
		_stamp_cell(image, atlas, 6, int(x / TILE) % 16, Vector2i(x, 492), 1, 0.74)
		_stamp_cell(image, atlas, 7, int(15 - x / TILE) % 16, Vector2i(x, 524), 1, 0.62)
	# Fracture/stress pocket west of center.
	for y in range(440, 568, TILE):
		for x in range(250, 410, TILE):
			_stamp_cell(image, atlas, 11, int((x + y) / TILE) % 16, Vector2i(x, y), 1, 0.78)
	_draw_line(image, Vector2i(260, 510), Vector2i(414, 578), accent, 2)
	_draw_line(image, Vector2i(292, 572), Vector2i(414, 454), Color(1.0, 0.38, 0.82, 0.82), 1)
	# Non-blinding marker glows near the central interaction marker.
	for offset in [-96, -64, -32, 0, 32, 64, 96]:
		_stamp_cell(image, atlas, 8, int(abs(offset) / 32) % 16, Vector2i(640 + offset, 384), 1, 0.64)
	_fill_rect(image, Rect2i(520, 426, 240, 6), Color(accent.r, accent.g, accent.b, 0.48))
	_fill_rect(image, Rect2i(520, 438, 240, 4), Color(1.0, 0.35, 0.82, 0.36))
	return image

func _add_temporary_preview_layer(scene: Node, stage_image: Image, label: String) -> Node2D:
	var layer := Node2D.new()
	layer.name = "T6TemporaryTilesetPreviewLayer"
	layer.z_index = -23
	layer.set_meta("t6_preview_only", true)
	layer.set_meta("candidate_label", label)
	var sprite := Sprite2D.new()
	sprite.name = "T6TemporaryTilesetPreviewSprite"
	sprite.centered = false
	sprite.texture = ImageTexture.create_from_image(stage_image)
	sprite.position = Vector2.ZERO
	layer.add_child(sprite)
	scene.add_child(layer)
	return layer

func _save_scene_composition_board(candidate: Dictionary, stage_image: Image, scene: Node) -> String:
	var board := Image.create(VIEWPORT_SIZE.x, VIEWPORT_SIZE.y, false, Image.FORMAT_RGBA8)
	board.fill(Color(0.025, 0.032, 0.046, 1.0))
	board.blend_rect(stage_image, Rect2i(Vector2i.ZERO, stage_image.get_size()), Vector2i.ZERO)
	_draw_frame(board, Rect2i(24, 18, 1232, 82), Color(0.10, 0.18, 0.23, 1.0), Color(0.015, 0.020, 0.032, 1.0))
	_draw_marker(board, Vector2i(640, 430), Color(0.30, 0.68, 1.0, 1.0), Color(0.86, 0.96, 1.0, 1.0))
	_draw_marker(board, Vector2i(640, 430), Color(1.0, 0.72, 0.32, 0.70), Color(1.0, 0.90, 0.66, 0.86), 10)
	_draw_frame(board, Rect2i(34, 108, 412, 82), Color(0.07, 0.12, 0.16, 1.0), Color(0.015, 0.020, 0.030, 0.92))
	_draw_frame(board, Rect2i(860, 112, 356, 118), Color(0.07, 0.12, 0.16, 1.0), Color(0.015, 0.020, 0.030, 0.92))
	_draw_frame(board, Rect2i(454, 586, 374, 78), Color(0.07, 0.12, 0.16, 1.0), Color(0.015, 0.020, 0.030, 0.92))
	var err := board.save_png(ProjectSettings.globalize_path(str(candidate["board"])))
	return "Pass" if err == OK else "Fail"

func _show_preview_prompts(scene: Node) -> void:
	_set_prompts_visible(scene)

func _can_attempt_viewport_capture() -> bool:
	var display_name := DisplayServer.get_name().to_lower()
	if display_name.contains("headless"):
		return false
	if OS.has_feature("headless"):
		return false
	return true

func _set_prompts_visible(node: Node) -> void:
	if node is Label and node.name.to_lower().contains("prompt"):
		(node as Label).visible = true
	for child in node.get_children():
		_set_prompts_visible(child)

func _inspect_scene_reference() -> Dictionary:
	var result := {
		"scene": SAFE_SCENE,
		"scene_load": "Not run",
		"safe_reason": "Free-travel revisit wrapper; Chapter 5 story scenes are skipped.",
		"visual_strategy": "Existing scene has procedural ColorRect/Polygon2D visual nodes, V3 overlays, player camera, and UI. No saved TileMap or generated_v2 visual layer is present.",
		"scan": {},
	}
	if not ResourceLoader.exists(SAFE_SCENE):
		result["scene_load"] = "Fail"
		return result
	var packed := load(SAFE_SCENE) as PackedScene
	if not packed:
		result["scene_load"] = "Fail"
		return result
	var scene := packed.instantiate()
	get_root().add_child(scene)
	current_scene = scene
	for _i in range(8):
		await process_frame
	result["scene_load"] = "Pass"
	result["scan"] = _scan_scene(scene)
	scene.queue_free()
	await process_frame
	current_scene = null
	return result

func _scan_scene(node: Node) -> Dictionary:
	var flags := {
		"player_found": false,
		"camera_found": false,
		"visual_layer_found": false,
		"label_count": 0,
		"prompt_count": 0,
		"v3_nodes_found": [],
		"visual_nodes": [],
	}
	_scan_recursive(node, flags)
	return flags

func _scan_recursive(node: Node, flags: Dictionary) -> void:
	var lower := node.name.to_lower()
	if lower.contains("player"):
		flags["player_found"] = true
	if node is Camera2D or lower.contains("camera"):
		flags["camera_found"] = true
	if node is ColorRect or node is Polygon2D or node is Sprite2D or node is TileMap or node is TileMapLayer:
		flags["visual_layer_found"] = true
		var visual_nodes: Array = flags["visual_nodes"]
		if visual_nodes.size() < 32:
			visual_nodes.append({"name": node.name, "type": node.get_class(), "z_index": node.z_index if node is CanvasItem else 0})
	if node is Label:
		flags["label_count"] = int(flags["label_count"]) + 1
		if lower.contains("prompt"):
			flags["prompt_count"] = int(flags["prompt_count"]) + 1
	if lower.begins_with("v3"):
		var v3_nodes: Array = flags["v3_nodes_found"]
		v3_nodes.append(node.name)
	for child in node.get_children():
		_scan_recursive(child, flags)

func _input_checks() -> Array:
	return [
		_check_file("T5 review", T5_REVIEW, Vector2i.ZERO),
		_check_texture("current generated_v2 Mirror City fallback", CURRENT_FALLBACK, Vector2i(128, 64)),
		_check_texture("T4 Variant D primary", VARIANT_D, Vector2i(512, 512)),
		_check_texture("T4 Variant C backup", VARIANT_C, Vector2i(512, 512)),
		_check_texture("old T2 Mirror City reference", OLD_T2, Vector2i(512, 512)),
		_check_texture("V3 props", PROP_ATLAS, Vector2i(1536, 1024)),
		_check_texture("V3 decals", DECAL_ATLAS, Vector2i(1536, 1024)),
	]

func _safety_checks() -> Array:
	return [
		_check_texture("Oakhaven baseline preservation", OAKHAVEN_BASELINE, Vector2i(512, 512)),
		_check_texture("Ironhold baseline preservation", IRONHOLD_BASELINE, Vector2i(512, 512)),
		_check_texture("Fractured Wastes baseline preservation", FRACTURED_BASELINE, Vector2i(512, 512)),
		_check_texture("shared V3 props preservation", PROP_ATLAS, Vector2i(1536, 1024)),
		_check_texture("shared V3 decals preservation", DECAL_ATLAS, Vector2i(1536, 1024)),
		_check_texture("Mirror City generated_v2 fallback preservation", CURRENT_FALLBACK, Vector2i(128, 64)),
	]

func _check_file(label: String, path: String, _expected_size: Vector2i) -> Dictionary:
	var exists := FileAccess.file_exists(path) or FileAccess.file_exists(ProjectSettings.globalize_path(path)) or ResourceLoader.exists(path)
	return {"check": label, "path": path, "exists": exists, "loaded": exists, "size": [0, 0], "result": "Pass" if exists else "Fail"}

func _check_texture(label: String, path: String, expected_size: Vector2i) -> Dictionary:
	var exists := FileAccess.file_exists(path) or FileAccess.file_exists(ProjectSettings.globalize_path(path)) or ResourceLoader.exists(path)
	var image := Image.new()
	var loaded := false
	if exists:
		var err := image.load(ProjectSettings.globalize_path(path))
		loaded = err == OK and not image.is_empty()
	var size_ok := expected_size == Vector2i.ZERO or (loaded and image.get_size() == expected_size)
	var ok := exists and loaded and size_ok
	return {"check": label, "path": path, "exists": exists, "loaded": loaded, "size": [image.get_width(), image.get_height()] if loaded else [0, 0], "result": "Pass" if ok else "Fail"}

func _load_image(path: String) -> Image:
	var image := Image.new()
	if path.is_empty():
		return image
	var err := image.load(ProjectSettings.globalize_path(path))
	if err != OK:
		push_warning("Could not load image: " + path)
	return image

func _stamp_cell(target: Image, atlas: Image, row: int, col: int, pos: Vector2i, scale: int, alpha: float) -> void:
	if atlas.is_empty():
		return
	var cols: int = max(1, int(atlas.get_width() / TILE))
	var rows: int = max(1, int(atlas.get_height() / TILE))
	var src := Rect2i((col % cols) * TILE, (row % rows) * TILE, TILE, TILE)
	var cell := atlas.get_region(src)
	if alpha < 0.999:
		_apply_alpha(cell, alpha)
	if scale != 1:
		cell.resize(TILE * scale, TILE * scale, Image.INTERPOLATE_NEAREST)
	target.blend_rect(cell, Rect2i(Vector2i.ZERO, cell.get_size()), pos)

func _apply_alpha(image: Image, alpha: float) -> void:
	for y in range(image.get_height()):
		for x in range(image.get_width()):
			var c := image.get_pixel(x, y)
			c.a *= alpha
			image.set_pixel(x, y, c)

func _draw_frame(image: Image, rect: Rect2i, border: Color, fill: Color) -> void:
	image.fill_rect(rect, border)
	image.fill_rect(rect.grow(-4), fill)

func _fill_rect(image: Image, rect: Rect2i, color: Color) -> void:
	image.fill_rect(rect, color)

func _draw_marker(image: Image, center: Vector2i, fill: Color, edge: Color, radius: int = 15) -> void:
	var outer := radius + 3
	for y in range(-outer, outer + 1):
		for x in range(-outer, outer + 1):
			var dist := x * x + y * y
			var p := center + Vector2i(x, y)
			if p.x < 0 or p.y < 0 or p.x >= image.get_width() or p.y >= image.get_height():
				continue
			if dist <= radius * radius:
				image.set_pixelv(p, fill)
			if dist <= outer * outer and dist >= (radius - 2) * (radius - 2):
				image.set_pixelv(p, edge)

func _draw_line(image: Image, a: Vector2i, b: Vector2i, color: Color, width: int) -> void:
	var delta := b - a
	var steps: int = maxi(abs(delta.x), abs(delta.y))
	if steps <= 0:
		return
	for i in range(steps + 1):
		var t := float(i) / float(steps)
		var p := Vector2i(roundi(lerpf(float(a.x), float(b.x), t)), roundi(lerpf(float(a.y), float(b.y), t)))
		for oy in range(-width, width + 1):
			for ox in range(-width, width + 1):
				var q := p + Vector2i(ox, oy)
				if q.x >= 0 and q.y >= 0 and q.x < image.get_width() and q.y < image.get_height():
					image.set_pixelv(q, color)

func _find_node_by_name(root: Node, node_name: String) -> Node:
	if root.name == node_name:
		return root
	for child in root.get_children():
		var found := _find_node_by_name(child, node_name)
		if found:
			return found
	return null

func _write_json(path: String, data: Dictionary) -> void:
	var file := FileAccess.open(ProjectSettings.globalize_path(path), FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(data, "\t"))
		file.close()
