extends SceneTree

## Focused Phase 10M-N production slot and fallback probe.


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var production_oakhaven := "res://assets/production_art/tilesets/oakhaven_tileset.png"
	var production_prop_atlas := "res://assets/production_art/props/environment_prop_atlas.png"
	var production_decal_atlas := "res://assets/production_art/backgrounds/environment_decal_atlas.png"
	print("[PHASE10MN][PRODUCTION_SLOT] oakhaven_exists=%s prop_atlas_exists=%s decal_atlas_exists=%s" % [
		FileAccess.file_exists(production_oakhaven),
		FileAccess.file_exists(production_prop_atlas),
		FileAccess.file_exists(production_decal_atlas),
	])
	var asset_manager = get_root().get_node_or_null("AssetManager")
	if not asset_manager:
		push_error("[PHASE10MN][ASSET_MANAGER] FAIL autoload missing")
		quit()
		return

	var tile_layer = asset_manager.call("try_create_v2_visual_tile_layer", "oakhaven", Vector2(64, 64), "ProductionSlotProbe", -1, [Vector2i(0, 0)])
	if tile_layer:
		print("[PHASE10MN][FALLBACK] PASS missing production Oakhaven slot still built generated visual layer")
		tile_layer.queue_free()
	else:
		push_error("[PHASE10MN][FALLBACK] FAIL Oakhaven generated fallback missing")

	var prop = asset_manager.call("try_create_v3_environment_prop", "oakhaven_roof", Vector2(64, 64), "PropProbe", -1)
	if prop:
		print("[PHASE10MN][FALLBACK] PASS missing production prop atlas still built generated prop")
		prop.queue_free()
	else:
		push_error("[PHASE10MN][FALLBACK] FAIL generated prop atlas missing")

	var decal = asset_manager.call("try_create_v3_environment_decal", "oakhaven_path", Vector2(64, 64), "DecalProbe", -1)
	if decal:
		print("[PHASE10MN][FALLBACK] PASS missing production decal atlas still built generated decal")
		decal.queue_free()
	else:
		push_error("[PHASE10MN][FALLBACK] FAIL generated decal atlas missing")
	quit()
