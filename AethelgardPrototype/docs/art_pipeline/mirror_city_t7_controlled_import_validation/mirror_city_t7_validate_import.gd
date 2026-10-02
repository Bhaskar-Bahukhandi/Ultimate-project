extends SceneTree

const OUT_ROOT := "res://assets/art_sources/comfyui_tests/mirror_city_t7_controlled_import"
const PREVIEW_DIR := OUT_ROOT + "/preview_boards"
const CONTACT_DIR := OUT_ROOT + "/contact_sheets"
const SCREENSHOT_DIR := OUT_ROOT + "/screenshots"
const MANIFEST_DIR := OUT_ROOT + "/manifest"
const DIAGNOSTICS_DIR := OUT_ROOT + "/diagnostics"
const DIAGNOSTICS_PATH := DIAGNOSTICS_DIR + "/mirror_city_t7_validation_diagnostics.json"

const MIRROR_SCENE := "res://scenes/regions/mirror_city_revisit_hub.tscn"
const MAIN_MENU_SCENE := "res://scenes/main_menu.tscn"
const PRODUCTION_PATH := "res://assets/production_art/tilesets/mirror_city/mirror_city_tileset.png"
const FALLBACK_PATH := "res://assets/generated_v2/tilesets/mirror_city_v2_prototype_tileset.png"
const MISSING_PRODUCTION_PATH := "res://assets/production_art/tilesets/mirror_city/__missing__.png"

var results := {
	"phase": "10M-T7",
	"preview_only": false,
	"live_viewport_screenshots": false,
	"evidence_mode": "deterministic runtime-composition boards",
	"checks": {},
	"boards": {},
	"contact_sheets": {},
	"scene": {},
	"safety_notes": [],
}


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	_make_dirs()
	get_root().size = Vector2i(1280, 720)
	results["checks"]["main_menu"] = await _load_scene_once(MAIN_MENU_SCENE)
	var asset_manager := _asset_manager()
	results["checks"]["asset_manager_available"] = asset_manager != null
	if not asset_manager:
		_write_results_and_quit(1)
		return

	results["checks"]["production_slot_default"] = _check_slot("production_default", false)
	results["checks"]["force_fallback_slot"] = _check_slot("force_fallback", true)
	asset_manager.set_mirror_city_force_generated_fallback(false)
	results["checks"]["missing_production_probe"] = _check_missing_production_probe()

	results["checks"]["mirror_scene_production"] = await _load_mirror_scene_capture(false, "production_variant_d", PREVIEW_DIR + "/mirror_city_t7_production_variant_d_board.png")
	results["checks"]["mirror_scene_force_fallback"] = await _load_mirror_scene_capture(true, "force_fallback", PREVIEW_DIR + "/mirror_city_t7_force_fallback_board.png")
	results["checks"]["mirror_scene_fallback_board"] = _save_atlas_board(FALLBACK_PATH, PREVIEW_DIR + "/mirror_city_t7_current_fallback_board.png")
	asset_manager.set_mirror_city_force_generated_fallback(false)

	results["checks"]["oakhaven_baseline_load"] = _image_load_check("res://assets/production_art/tilesets/oakhaven/oakhaven_afternoon_tileset.png")
	results["checks"]["ironhold_baseline_load"] = _image_load_check("res://assets/production_art/tilesets/ironhold/ironhold_tileset.png")
	results["checks"]["fractured_wastes_baseline_load"] = _image_load_check("res://assets/production_art/tilesets/fractured_wastes/fractured_wastes_tileset.png")
	results["checks"]["v3_props_load"] = _image_load_check("res://assets/generated_v3/props/phase10mm_environment_prop_atlas.png")
	results["checks"]["v3_decals_load"] = _image_load_check("res://assets/generated_v3/overlays/phase10mm_environment_decal_atlas.png")
	results["checks"]["mirror_generated_v2_fallback_load"] = _image_load_check(FALLBACK_PATH)
	results["checks"]["mirror_production_load"] = _image_load_check(PRODUCTION_PATH)

	_write_results_and_quit(0)


func _make_dirs() -> void:
	for path in [OUT_ROOT, PREVIEW_DIR, CONTACT_DIR, SCREENSHOT_DIR, MANIFEST_DIR, DIAGNOSTICS_DIR]:
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(path))


func _asset_manager() -> Node:
	return get_root().get_node_or_null("/root/AssetManager")


func _load_scene_once(scene_path: String) -> Dictionary:
	var packed := load(scene_path) as PackedScene
	if not packed:
		return {"loaded": false, "error": "PackedScene failed to load", "path": scene_path}
	var instance := packed.instantiate()
	if not instance:
		return {"loaded": false, "error": "instantiate failed", "path": scene_path}
	get_root().add_child(instance)
	await process_frame
	instance.queue_free()
	await process_frame
	return {"loaded": true, "path": scene_path}


func _check_slot(label: String, force_fallback: bool) -> Dictionary:
	var asset_manager := _asset_manager()
	if not asset_manager:
		return {"label": label, "loaded": false, "error": "AssetManager missing"}
	asset_manager.set_mirror_city_force_generated_fallback(force_fallback)
	var slot: Dictionary = asset_manager.get_mirror_city_tileset_slot()
	var texture := slot.get("texture") as Texture2D
	return {
		"label": label,
		"force_fallback": force_fallback,
		"loaded": texture != null,
		"path": str(slot.get("path", "")),
		"production": bool(slot.get("production", false)),
		"fallback_used": bool(slot.get("fallback_used", false)),
		"fallback_reason": str(slot.get("fallback_reason", "")),
		"width": texture.get_width() if texture else 0,
		"height": texture.get_height() if texture else 0,
	}


func _check_missing_production_probe() -> Dictionary:
	var asset_manager := _asset_manager()
	if not asset_manager:
		return {"loaded": false, "error": "AssetManager missing"}
	asset_manager.set_mirror_city_force_generated_fallback(false)
	var slot: Dictionary = asset_manager.get_mirror_city_tileset_slot(MISSING_PRODUCTION_PATH)
	var texture := slot.get("texture") as Texture2D
	return {
		"loaded": texture != null,
		"path": str(slot.get("path", "")),
		"production": bool(slot.get("production", false)),
		"fallback_used": bool(slot.get("fallback_used", false)),
		"fallback_reason": str(slot.get("fallback_reason", "")),
		"width": texture.get_width() if texture else 0,
		"height": texture.get_height() if texture else 0,
	}


func _load_mirror_scene_capture(force_fallback: bool, label: String, board_path: String) -> Dictionary:
	var asset_manager := _asset_manager()
	if not asset_manager:
		return {"loaded": false, "error": "AssetManager missing"}
	asset_manager.set_mirror_city_force_generated_fallback(force_fallback)
	var packed := load(MIRROR_SCENE) as PackedScene
	if not packed:
		return {"loaded": false, "error": "Mirror scene PackedScene failed to load"}
	var instance := packed.instantiate()
	get_root().add_child(instance)
	await process_frame
	await process_frame
	var visual := instance.get_node_or_null("MirrorCityVisualTilesetFloor")
	var player := instance.get_node_or_null("Player")
	var camera := instance.get_node_or_null("Player/LateHubCamera")
	var future := instance.get_node_or_null("FutureRoutesMarker")
	var exit_gate := instance.get_node_or_null("ReturnGate")
	var board_saved := false
	if visual and visual is Sprite2D:
		var sprite := visual as Sprite2D
		if sprite.texture:
			var image := sprite.texture.get_image()
			board_saved = image.save_png(ProjectSettings.globalize_path(board_path)) == OK
			results["boards"][label] = board_path
	var output := {
		"loaded": true,
		"force_fallback": force_fallback,
		"visual_layer_found": visual != null,
		"visual_layer_path": str(visual.get_meta("visual_tileset_path", "")) if visual else "",
		"visual_layer_production": bool(visual.get_meta("visual_tileset_production", false)) if visual else false,
		"fallback_used": bool(visual.get_meta("fallback_used", false)) if visual else false,
		"fallback_reason": str(visual.get_meta("fallback_reason", "")) if visual else "",
		"player_found": player != null,
		"camera_found": camera != null,
		"labels_prompts_found": future != null and exit_gate != null,
		"v3_mirror_nodes_found": _has_child_named(instance, "V3MirrorRipples") and _has_child_named(instance, "V3MirrorPlinth") and _has_child_named(instance, "V3MirrorShardWest"),
		"board_saved": board_saved,
		"board_path": board_path,
	}
	results["scene"][label] = output
	instance.queue_free()
	await process_frame
	return output


func _save_atlas_board(path: String, board_path: String) -> Dictionary:
	var image := Image.load_from_file(ProjectSettings.globalize_path(path))
	if image == null or image.is_empty():
		return {"saved": false, "source": path, "board_path": board_path}
	var board := Image.create(1280, 720, false, Image.FORMAT_RGBA8)
	board.fill(Color(0.015, 0.018, 0.024, 1.0))
	for y in range(96, 624, 32):
		for x in range(96, 1184, 32):
			var sx := int(((x + y) / 32) % max(1, int(image.get_width() / 32))) * 32
			var sy := int(((x / 64 + y / 96) % max(1, int(image.get_height() / 32)))) * 32
			var src := Rect2i(sx, sy, min(32, image.get_width() - sx), min(32, image.get_height() - sy))
			board.blit_rect(image, src, Vector2i(x, y))
	var ok := board.save_png(ProjectSettings.globalize_path(board_path)) == OK
	results["boards"]["current_fallback"] = board_path
	return {"saved": ok, "source": path, "board_path": board_path}


func _image_load_check(path: String) -> Dictionary:
	var image := Image.load_from_file(ProjectSettings.globalize_path(path))
	return {
		"path": path,
		"loaded": image != null and not image.is_empty(),
		"width": image.get_width() if image and not image.is_empty() else 0,
		"height": image.get_height() if image and not image.is_empty() else 0,
	}


func _has_child_named(node: Node, target_name: String) -> bool:
	if node.name == target_name:
		return true
	for child in node.get_children():
		if _has_child_named(child, target_name):
			return true
	return false


func _write_results_and_quit(exit_code: int) -> void:
	var file := FileAccess.open(ProjectSettings.globalize_path(DIAGNOSTICS_PATH), FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(results, "\t"))
		file.close()
	quit(exit_code)
