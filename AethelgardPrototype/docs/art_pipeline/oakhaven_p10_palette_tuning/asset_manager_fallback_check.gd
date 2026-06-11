extends SceneTree

func _init() -> void:
	var production_path := "res://assets/production_art/tilesets/oakhaven_tileset.png"
	var fallback_path := "res://assets/generated_v2/tilesets/oakhaven_v2_prototype_tileset.png"
	var production_exists := FileAccess.file_exists(production_path) or ResourceLoader.exists(production_path)
	var fallback_exists := FileAccess.file_exists(fallback_path) or ResourceLoader.exists(fallback_path)
	print("P10 fallback check: production_exists=%s fallback_exists=%s" % [production_exists, fallback_exists])
	if production_exists:
		push_error("P10 fallback check expected no Oakhaven production tileset.")
		quit(1)
		return
	if not fallback_exists:
		push_error("P10 fallback check could not find generated Oakhaven fallback tileset.")
		quit(1)
		return

	var asset_manager = load("res://scripts/asset_manager.gd").new()
	var slot: Dictionary = asset_manager._resolve_visual_texture_slot(
		production_path,
		fallback_path,
		"oakhaven visual tileset"
	)
	var texture := slot.get("texture") as Texture2D
	var resolved_path := str(slot.get("path", ""))
	var production := bool(slot.get("production", true))
	print("P10 fallback check: resolved_path=%s production=%s" % [resolved_path, production])
	if production or resolved_path != fallback_path or texture == null:
		push_error("P10 fallback check did not resolve to the generated fallback tileset.")
		asset_manager.free()
		quit(1)
		return

	var visual_layer = asset_manager.try_create_v2_visual_tile_layer(
		"oakhaven",
		Vector2(64.0, 64.0),
		"P10FallbackCheckLayer",
		-10
	)
	if visual_layer == null:
		push_error("P10 fallback check could not create a visual-only fallback tile layer.")
		asset_manager.free()
		quit(1)
		return
	if not bool(visual_layer.get_meta("visual_only", false)):
		push_error("P10 fallback check layer was not marked visual-only.")
		visual_layer.free()
		asset_manager.free()
		quit(1)
		return

	visual_layer.free()
	asset_manager.free()
	print("P10 fallback check: PASS")
	quit(0)
