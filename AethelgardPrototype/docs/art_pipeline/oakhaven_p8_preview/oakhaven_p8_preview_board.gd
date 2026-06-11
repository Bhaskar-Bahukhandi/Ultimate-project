extends SceneTree

const BEST_ATLAS := "res://assets/art_sources/comfyui_tests/oakhaven_p8/generated_tiles/oakhaven_p8_variant_b_textured.png"
const BEST_MOCKUP := "res://assets/art_sources/comfyui_tests/oakhaven_p8/mockups/oakhaven_p8_variant_b_mockup.png"

func _init() -> void:
	var atlas := _load_preview_texture(BEST_ATLAS)
	var mockup := _load_preview_texture(BEST_MOCKUP)
	if atlas == null:
		push_error("P8 preview could not load best atlas: %s" % BEST_ATLAS)
		quit(1)
		return
	if mockup == null:
		push_error("P8 preview could not load best mockup: %s" % BEST_MOCKUP)
		quit(1)
		return

	print("P8 preview assets loaded: atlas=%s mockup=%s" % [BEST_ATLAS, BEST_MOCKUP])
	if DisplayServer.get_name() == "headless":
		print("P8 preview board asset check: PASS")
		quit(0)
		return

	var root_node := Node2D.new()
	root_node.name = "OakhavenP8PreviewBoard"
	root.add_child(root_node)

	var atlas_sprite := Sprite2D.new()
	atlas_sprite.name = "VariantBAtlas"
	atlas_sprite.texture = atlas
	atlas_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	atlas_sprite.position = Vector2(280, 300)
	root_node.add_child(atlas_sprite)

	var mockup_sprite := Sprite2D.new()
	mockup_sprite.name = "VariantBMockup"
	mockup_sprite.texture = mockup
	mockup_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	mockup_sprite.position = Vector2(1010, 300)
	root_node.add_child(mockup_sprite)

	var label := Label.new()
	label.text = "Oakhaven P8 Variant B - review-only preview"
	label.position = Vector2(24, 24)
	root.add_child(label)

func _load_preview_texture(path: String) -> Texture2D:
	if ResourceLoader.exists(path):
		var texture := load(path) as Texture2D
		if texture:
			return texture
	var image := Image.load_from_file(ProjectSettings.globalize_path(path))
	if image and not image.is_empty():
		return ImageTexture.create_from_image(image)
	return null
