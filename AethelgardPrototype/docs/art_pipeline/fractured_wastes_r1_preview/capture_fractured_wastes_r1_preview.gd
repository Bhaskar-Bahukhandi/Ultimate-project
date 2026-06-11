extends SceneTree

const OUTPUT_PATH := "res://assets/art_sources/comfyui_tests/fractured_wastes_r1/review/fractured_wastes_r1_godot_variant_b_preview.png"
const ATLAS_PATH := "res://assets/art_sources/comfyui_tests/fractured_wastes_r1/generated_tiles/fractured_wastes_r1_variant_b_textured.png"
const MOCKUP_PATH := "res://assets/art_sources/comfyui_tests/fractured_wastes_r1/mockups/fractured_wastes_r1_variant_b_mockup.png"
const VIEWPORT_SIZE := Vector2i(1280, 720)

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	get_root().size = VIEWPORT_SIZE
	var root := Control.new()
	root.name = "FracturedWastesR1PreviewOnly"
	get_root().add_child(root)
	current_scene = root

	var bg := ColorRect.new()
	bg.color = Color(0.035, 0.03, 0.04, 1.0)
	bg.size = Vector2(VIEWPORT_SIZE)
	root.add_child(bg)

	var title := _make_label("Fractured Wastes R1 Variant B preview-only board", Vector2(28, 20), 24, Color(0.92, 0.84, 0.72))
	root.add_child(title)
	var note := _make_label("Not connected to gameplay. No production_art import. Mockup uses the generated R1 atlas grammar.", Vector2(28, 52), 13, Color(0.72, 0.70, 0.74))
	root.add_child(note)

	var atlas_texture := _load_texture(ATLAS_PATH)
	var mockup_texture := _load_texture(MOCKUP_PATH)
	if not atlas_texture or not mockup_texture:
		push_error("R1 preview could not load generated atlas/mockup textures.")
		quit(1)
		return

	var mock := TextureRect.new()
	mock.texture = mockup_texture
	mock.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	mock.position = Vector2(28, 86)
	mock.size = Vector2(768, 576)
	root.add_child(mock)

	var atlas := TextureRect.new()
	atlas.texture = atlas_texture
	atlas.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	atlas.position = Vector2(836, 116)
	atlas.size = Vector2(384, 384)
	atlas.stretch_mode = TextureRect.STRETCH_SCALE
	root.add_child(atlas)

	root.add_child(_make_label("512x512 atlas scaled down", Vector2(836, 506), 13, Color(0.78, 0.74, 0.70)))
	root.add_child(_make_label("Best R1 candidate: clear safe path, localized corruption, readable labels.", Vector2(836, 538), 14, Color(0.95, 0.86, 0.65)))

	await _settle_frames(8)
	var image := get_root().get_texture().get_image()
	if image == null or image.is_empty():
		push_error("R1 preview viewport image is empty. Run without --headless for capture.")
		quit(1)
		return
	var err := image.save_png(ProjectSettings.globalize_path(OUTPUT_PATH))
	if err != OK:
		push_error("R1 preview screenshot save failed: %s" % err)
		quit(1)
		return
	print("Fractured Wastes R1 preview capture: PASS")
	quit(0)

func _load_texture(path: String) -> Texture2D:
	if ResourceLoader.exists(path):
		var texture := load(path) as Texture2D
		if texture:
			return texture
	var image := Image.load_from_file(ProjectSettings.globalize_path(path))
	if image and not image.is_empty():
		return ImageTexture.create_from_image(image)
	return null

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

func _settle_frames(count: int) -> void:
	for _i in range(count):
		await process_frame
