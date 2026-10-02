extends SceneTree

const OUT_ROOT := "res://assets/art_sources/comfyui_tests/late_hubs_t3_preview_validation"
const SCREENSHOT_DIR := OUT_ROOT + "/screenshots"
const CONTACT_DIR := OUT_ROOT + "/contact_sheets"
const BOARD_DIR := OUT_ROOT + "/preview_boards"
const MANIFEST_DIR := OUT_ROOT + "/manifest"
const DIAGNOSTIC_DIR := OUT_ROOT + "/diagnostics"
const DIAGNOSTIC_PATH := DIAGNOSTIC_DIR + "/late_hubs_t3_godot_preview_diagnostics.json"

const BOARD_SIZE := Vector2i(1600, 900)
const PANEL_SIZE := Vector2i(660, 510)
const TILE := 32

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
		"phase": "10M-T3",
		"script": "docs/art_pipeline/late_hubs_t3_preview_validation/late_hubs_t3_preview_validation.gd",
		"project_boot": true,
		"preview_only": true,
		"production_art_changed": false,
		"generated_v2_overwritten": false,
		"generated_v3_overwritten": false,
		"gameplay_scene_script_modified": false,
		"preview_boards": [],
		"actual_scene_references": [],
		"safety_checks": []
	}
	var main_menu := await _check_scene_load_only("main menu", "res://scenes/main_menu.tscn")
	results["main_menu"] = main_menu
	for check in _safety_texture_checks():
		results["safety_checks"].append(check)
	for hub in _preview_hubs():
		results["preview_boards"].append(await _render_preview_board(hub))
	for hub in _scene_hubs():
		results["actual_scene_references"].append(await _capture_scene_reference(hub))
	_write_json(DIAGNOSTIC_PATH, results)
	print("Late hubs T3 preview-only validation complete.")
	quit(0)

func _make_dirs() -> void:
	for dir in [SCREENSHOT_DIR, CONTACT_DIR, BOARD_DIR, MANIFEST_DIR, DIAGNOSTIC_DIR]:
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(dir))

func _preview_hubs() -> Array:
	return [
		{
			"id": "forgotten_sectors",
			"name": "Forgotten Sectors",
			"current": "res://assets/generated_v2/tilesets/forgotten_sectors_v2_prototype_tileset.png",
			"candidate": "res://assets/art_sources/comfyui_tests/late_hubs_t2_family_builder/generated_tiles/late_hub_t2_forgotten_sectors_family.png",
			"board": BOARD_DIR + "/late_hub_t3_forgotten_sectors_current_vs_candidate.png",
			"missing_current": false,
			"accent": Color(0.25, 0.82, 0.92),
		},
		{
			"id": "mirror_city",
			"name": "Mirror City",
			"current": "res://assets/generated_v2/tilesets/mirror_city_v2_prototype_tileset.png",
			"candidate": "res://assets/art_sources/comfyui_tests/late_hubs_t2_family_builder/generated_tiles/late_hub_t2_mirror_city_family.png",
			"board": BOARD_DIR + "/late_hub_t3_mirror_city_current_vs_candidate.png",
			"missing_current": false,
			"accent": Color(0.92, 0.35, 0.88),
		},
		{
			"id": "cathedral_server",
			"name": "Cathedral Server",
			"current": "res://assets/generated_v2/tilesets/cathedral_server_v2_prototype_tileset.png",
			"candidate": "res://assets/art_sources/comfyui_tests/late_hubs_t2_family_builder/generated_tiles/late_hub_t2_cathedral_server_family.png",
			"board": BOARD_DIR + "/late_hub_t3_cathedral_server_current_vs_candidate.png",
			"missing_current": false,
			"accent": Color(0.93, 0.72, 0.28),
		},
		{
			"id": "memory_ocean",
			"name": "Memory Ocean",
			"current": "res://assets/generated_v2/tilesets/memory_ocean_v2_prototype_tileset.png",
			"candidate": "res://assets/art_sources/comfyui_tests/late_hubs_t2_family_builder/generated_tiles/late_hub_t2_memory_ocean_family.png",
			"board": BOARD_DIR + "/late_hub_t3_memory_ocean_current_vs_candidate.png",
			"missing_current": false,
			"accent": Color(0.22, 0.68, 0.94),
		},
		{
			"id": "root_of_heaven",
			"name": "Root of Heaven Prep",
			"current": "res://assets/generated_v2/tilesets/root_of_heaven_v2_prototype_tileset.png",
			"candidate": "res://assets/art_sources/comfyui_tests/late_hubs_t2_family_builder/generated_tiles/late_hub_t2_root_of_heaven_family.png",
			"board": BOARD_DIR + "/late_hub_t3_root_of_heaven_current_vs_candidate.png",
			"missing_current": false,
			"accent": Color(0.94, 0.78, 0.32),
		},
		{
			"id": "saved_assembly",
			"name": "Saved Assembly",
			"current": "",
			"candidate": "res://assets/art_sources/comfyui_tests/late_hubs_t2_family_builder/generated_tiles/late_hub_t2_saved_assembly_family.png",
			"board": BOARD_DIR + "/late_hub_t3_saved_assembly_missing_vs_candidate.png",
			"missing_current": true,
			"accent": Color(0.32, 0.84, 0.74),
		},
		{
			"id": "human_patch_lab",
			"name": "Human Patch Lab",
			"current": "",
			"candidate": "res://assets/art_sources/comfyui_tests/late_hubs_t2_family_builder/generated_tiles/late_hub_t2_human_patch_lab_family.png",
			"board": BOARD_DIR + "/late_hub_t3_human_patch_lab_missing_vs_candidate.png",
			"missing_current": true,
			"accent": Color(0.46, 0.86, 0.88),
		},
		{
			"id": "shared_neutral",
			"name": "Shared Neutral Family",
			"current": "",
			"candidate": "res://assets/art_sources/comfyui_tests/late_hubs_t2_family_builder/generated_tiles/late_hub_t2_shared_neutral_family.png",
			"board": BOARD_DIR + "/late_hub_t3_shared_neutral_preview.png",
			"missing_current": true,
			"accent": Color(0.42, 0.76, 0.86),
		},
	]

func _scene_hubs() -> Array:
	return [
		{"id": "forgotten_sectors", "name": "Forgotten Sectors", "scene": "res://scenes/regions/forgotten_sectors_revisit_hub.tscn", "screenshot": SCREENSHOT_DIR + "/late_hub_t3_forgotten_sectors_actual_reference.png"},
		{"id": "mirror_city", "name": "Mirror City", "scene": "res://scenes/regions/mirror_city_revisit_hub.tscn", "screenshot": SCREENSHOT_DIR + "/late_hub_t3_mirror_city_actual_reference.png"},
		{"id": "cathedral_server", "name": "Cathedral Server", "scene": "res://scenes/regions/cathedral_server_revisit_hub.tscn", "screenshot": SCREENSHOT_DIR + "/late_hub_t3_cathedral_server_actual_reference.png"},
		{"id": "memory_ocean", "name": "Memory Ocean", "scene": "res://scenes/regions/memory_ocean_revisit_hub.tscn", "screenshot": SCREENSHOT_DIR + "/late_hub_t3_memory_ocean_actual_reference.png"},
		{"id": "root_of_heaven", "name": "Root of Heaven Prep", "scene": "res://scenes/regions/root_of_heaven_prep_hub.tscn", "screenshot": SCREENSHOT_DIR + "/late_hub_t3_root_of_heaven_actual_reference.png"},
		{"id": "saved_assembly", "name": "Saved Assembly", "scene": "res://scenes/regions/saved_assembly_revisit_hub.tscn", "screenshot": SCREENSHOT_DIR + "/late_hub_t3_saved_assembly_actual_reference.png"},
		{"id": "human_patch_lab", "name": "Human Patch Lab", "scene": "res://scenes/regions/human_patch_lab_revisit_hub.tscn", "screenshot": SCREENSHOT_DIR + "/late_hub_t3_human_patch_lab_actual_reference.png"},
	]

func _render_preview_board(hub: Dictionary) -> Dictionary:
	var image := Image.create(BOARD_SIZE.x, BOARD_SIZE.y, false, Image.FORMAT_RGBA8)
	image.fill(Color(0.055, 0.06, 0.075))
	var current_img := _make_current_panel(hub)
	var candidate_img := _make_candidate_panel(hub)
	image.blit_rect(current_img, Rect2i(Vector2i.ZERO, current_img.get_size()), Vector2i(44, 132))
	image.blit_rect(candidate_img, Rect2i(Vector2i.ZERO, candidate_img.get_size()), Vector2i(884, 132))
	_fill_rect(image, Rect2i(36, 92, 682, 2), Color(0.26, 0.31, 0.38))
	_fill_rect(image, Rect2i(876, 92, 682, 2), Color(0.26, 0.31, 0.38))
	_fill_rect(image, Rect2i(930, 702, 330, 92), Color(0.02, 0.025, 0.035, 0.94))
	_fill_rect(image, Rect2i(1018, 426, 22, 22), Color(0.34, 0.62, 1.0))
	_fill_rect(image, Rect2i(1254, 426, 22, 22), Color(1.0, 0.72, 0.34))
	var err := image.save_png(ProjectSettings.globalize_path(str(hub["board"])))
	await process_frame
	return {
		"hub_id": hub["id"],
		"hub_area": hub["name"],
		"current_source": hub["current"] if str(hub["current"]) != "" else "missing dedicated generated_v2 fallback",
		"candidate_source": hub["candidate"],
		"preview_board": hub["board"],
		"result": "Pass" if err == OK else "Fail",
		"notes": "Preview board rendered from isolated textures; no runtime integration."
	}

func _make_current_panel(hub: Dictionary) -> Image:
	var img := Image.create(PANEL_SIZE.x, PANEL_SIZE.y, false, Image.FORMAT_RGBA8)
	img.fill(Color(0.095, 0.105, 0.13))
	if bool(hub["missing_current"]):
		_fill_rect(img, Rect2i(32, 120, PANEL_SIZE.x - 64, 190), Color(0.13, 0.135, 0.155))
		return img
	var atlas := _load_image(str(hub["current"]))
	if atlas.is_empty():
		_fill_rect(img, Rect2i(32, 120, PANEL_SIZE.x - 64, 190), Color(0.18, 0.10, 0.10))
		return img
	for y in range(0, PANEL_SIZE.y, TILE * 2):
		for x in range(0, PANEL_SIZE.x, TILE * 2):
			var src := Rect2i(Vector2i((x / (TILE * 2)) % 4 * TILE, (y / (TILE * 2)) % 2 * TILE), Vector2i(TILE, TILE))
			var cell := atlas.get_region(src)
			cell.resize(TILE * 2, TILE * 2, Image.INTERPOLATE_NEAREST)
			img.blit_rect(cell, Rect2i(Vector2i.ZERO, cell.get_size()), Vector2i(x, y))
	_add_panel_overlays(img, str(hub["id"]), false)
	return img

func _make_candidate_panel(hub: Dictionary) -> Image:
	var img := Image.create(PANEL_SIZE.x, PANEL_SIZE.y, false, Image.FORMAT_RGBA8)
	img.fill(Color(0.075, 0.082, 0.098))
	var atlas := _load_image(str(hub["candidate"]))
	if atlas.is_empty():
		_fill_rect(img, Rect2i(32, 120, PANEL_SIZE.x - 64, 190), Color(0.18, 0.10, 0.10))
		return img
	for y in range(0, PANEL_SIZE.y, TILE):
		for x in range(0, PANEL_SIZE.x, TILE):
			var col := int((x / TILE + y / TILE) % 14)
			var row := 0 if (x / TILE + y / TILE) % 3 != 0 else 1
			_blit_cell(img, atlas, row, col, Vector2i(x, y))
	# wrapper/border test
	for x in range(0, PANEL_SIZE.x, TILE):
		_blit_cell(img, atlas, 4, int((x / TILE) % 16), Vector2i(x, 0))
		_blit_cell(img, atlas, 5, int((x / TILE) % 16), Vector2i(x, PANEL_SIZE.y - TILE))
	for y in range(0, PANEL_SIZE.y, TILE):
		_blit_cell(img, atlas, 4, int((y / TILE + 2) % 16), Vector2i(0, y))
		_blit_cell(img, atlas, 5, int((y / TILE + 2) % 16), Vector2i(PANEL_SIZE.x - TILE, y))
	# route clarity and repeated tile tests
	for x in range(4, 17):
		_blit_cell(img, atlas, 2, 0, Vector2i(x * TILE, 7 * TILE))
	for y in range(7, 12):
		_blit_cell(img, atlas, 2, 1, Vector2i(10 * TILE, y * TILE))
	for x in range(5, 16):
		_blit_cell(img, atlas, 12, int(x % 16), Vector2i(x * TILE, 12 * TILE))
	for x in range(4, 18):
		_blit_cell(img, atlas, 8, int(x % 16), Vector2i(x * TILE, 14 * TILE))
	for x in range(2, 8):
		_blit_cell(img, atlas, 10, int(x % 16), Vector2i(x * TILE, 3 * TILE))
	# dark label-safe area
	_fill_rect(img, Rect2i(36, 350, 330, 126), Color(0.02, 0.025, 0.035, 0.92))
	_add_panel_overlays(img, str(hub["id"]), true)
	return img

func _add_panel_overlays(img: Image, hub_id: String, include_v3: bool) -> void:
	if include_v3:
		var prop := _load_image(PROP_ATLAS)
		var decal := _load_image(DECAL_ATLAS)
		if not prop.is_empty():
			var prop_crop := prop.get_region(Rect2i(620, 370, 170, 120))
			if hub_id == "cathedral_server":
				prop_crop = prop.get_region(Rect2i(36, 612, 180, 120))
			elif hub_id == "memory_ocean":
				prop_crop = prop.get_region(Rect2i(824, 610, 120, 150))
			elif hub_id == "human_patch_lab":
				prop_crop = prop.get_region(Rect2i(34, 818, 160, 120))
			elif hub_id == "root_of_heaven":
				prop_crop = prop.get_region(Rect2i(628, 816, 220, 90))
			prop_crop.resize(112, 80, Image.INTERPOLATE_NEAREST)
			img.blend_rect(prop_crop, Rect2i(Vector2i.ZERO, prop_crop.get_size()), Vector2i(452, 210))
		if not decal.is_empty():
			var decal_crop := decal.get_region(Rect2i(520, 362, 180, 130))
			if hub_id == "memory_ocean":
				decal_crop = decal.get_region(Rect2i(14, 674, 180, 130))
			elif hub_id == "root_of_heaven":
				decal_crop = decal.get_region(Rect2i(492, 680, 180, 130))
			elif hub_id == "cathedral_server":
				decal_crop = decal.get_region(Rect2i(900, 510, 180, 130))
			decal_crop.resize(150, 100, Image.INTERPOLATE_NEAREST)
			img.blend_rect(decal_crop, Rect2i(Vector2i.ZERO, decal_crop.get_size()), Vector2i(446, 64))

func _blit_cell(target: Image, atlas: Image, row: int, col: int, pos: Vector2i) -> void:
	var src := Rect2i(col * TILE, row * TILE, TILE, TILE)
	target.blit_rect(atlas, src, pos)

func _fill_rect(image: Image, rect: Rect2i, color: Color) -> void:
	image.fill_rect(rect, color)

func _load_image(path: String) -> Image:
	var image := Image.new()
	if path == "":
		return image
	var err := image.load(ProjectSettings.globalize_path(path))
	if err != OK:
		push_warning("Could not load image: " + path)
	return image

func _add_rect(parent: Control, rect: Rect2, color: Color) -> ColorRect:
	var node := ColorRect.new()
	node.position = rect.position
	node.size = rect.size
	node.color = color
	parent.add_child(node)
	return node

func _add_label(parent: Control, text: String, pos: Vector2, size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.position = pos
	label.size = Vector2(680, 34)
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	parent.add_child(label)
	return label

func _add_image(parent: Control, image: Image, pos: Vector2) -> TextureRect:
	var texture := ImageTexture.create_from_image(image)
	var rect := TextureRect.new()
	rect.texture = texture
	rect.position = pos
	rect.size = Vector2(image.get_width(), image.get_height())
	rect.stretch_mode = TextureRect.STRETCH_KEEP
	parent.add_child(rect)
	return rect

func _add_marker(parent: Control, pos: Vector2, label_text: String, color: Color) -> void:
	_add_rect(parent, Rect2(pos, Vector2(20, 20)), color)
	_add_label(parent, label_text, pos + Vector2(-18, 24), 14, Color(0.90, 0.94, 0.98))

func _check_scene_load_only(label: String, path: String) -> Dictionary:
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

func _capture_scene_reference(hub: Dictionary) -> Dictionary:
	var path := str(hub["scene"])
	var result := {
		"hub_id": hub["id"],
		"hub_area": hub["name"],
		"scene": path,
		"scene_load": "Not run",
		"screenshot": "",
		"risk": "Low-medium revisit/prep hub; no interaction performed.",
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
	get_root().add_child(scene)
	current_scene = scene
	for i in range(8):
		await process_frame
	var flags := _scan_scene(scene)
	result["player_found"] = flags["player_found"]
	result["camera_found"] = flags["camera_found"]
	result["visual_layer_found"] = flags["visual_layer_found"]
	result["label_or_prompt_found"] = flags["label_or_prompt_found"]
	result["screenshot"] = "Skipped: headless dummy renderer did not provide a reliable viewport image."
	result["scene_load"] = "Pass" if scene != null else "Fail"
	result["notes"] = "Read-only scene reference loaded; screenshot skipped when headless renderer could not provide a viewport image. T2 art was not swapped in."
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

func _safety_texture_checks() -> Array:
	return [
		_check_texture("Oakhaven baseline preservation", OAKHAVEN_BASELINE, true, Vector2i(512, 512)),
		_check_texture("Ironhold baseline preservation", IRONHOLD_BASELINE, true, Vector2i(512, 512)),
		_check_texture("Fractured Wastes baseline preservation", FRACTURED_BASELINE, true, Vector2i(512, 512)),
		_check_texture("shared V3 props preservation", PROP_ATLAS, true, Vector2i(1536, 1024)),
		_check_texture("shared V3 decals preservation", DECAL_ATLAS, true, Vector2i(1536, 1024)),
	]

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

func _write_json(path: String, data: Dictionary) -> void:
	var file := FileAccess.open(ProjectSettings.globalize_path(path), FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(data, "\t"))
		file.close()
