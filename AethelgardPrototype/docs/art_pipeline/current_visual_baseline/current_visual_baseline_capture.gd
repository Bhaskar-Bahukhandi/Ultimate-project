extends SceneTree

## M4 baseline capture for the last M3 visual state before production-art replacement.

const CAPTURES: Array[Dictionary] = [
	{"id": "oakhaven", "scene": "res://scenes/regions/oakhaven_region.tscn"},
	{"id": "ironhold", "scene": "res://scenes/regions/ironhold_region.tscn"},
	{"id": "fractured_wastes", "scene": "res://scenes/regions/fractured_wastes_region.tscn"},
	{"id": "forgotten_sectors", "scene": "res://scenes/regions/forgotten_sectors_revisit_hub.tscn"},
	{"id": "cathedral_server", "scene": "res://scenes/regions/cathedral_server_revisit_hub.tscn"},
	{"id": "memory_ocean", "scene": "res://scenes/regions/memory_ocean_revisit_hub.tscn"},
	{"id": "root_of_heaven_prep", "scene": "res://scenes/regions/root_of_heaven_prep_hub.tscn"},
	{"id": "tutorial_knight_arena", "scene": "res://scenes/chapter1/tutorial_knight_boss.tscn"},
]


func _initialize() -> void:
	call_deferred("_capture_all")


func _capture_all() -> void:
	for capture_data in CAPTURES:
		await _capture_scene(capture_data)
	if current_scene and is_instance_valid(current_scene):
		current_scene.queue_free()
		await process_frame
		await process_frame
	quit()


func _capture_scene(capture_data: Dictionary) -> void:
	var scene_path: String = capture_data.get("scene", "")
	var packed_scene := load(scene_path) as PackedScene
	if not packed_scene:
		push_error("[M4_BASELINE] Capture scene missing: %s" % scene_path)
		return

	if current_scene and is_instance_valid(current_scene):
		current_scene.queue_free()
		await process_frame

	var scene := packed_scene.instantiate()
	get_root().add_child(scene)
	current_scene = scene
	for frame_index in range(8):
		await process_frame

	var image := get_root().get_texture().get_image()
	var output_path := "res://docs/art_pipeline/current_visual_baseline/%s_m3_baseline.png" % capture_data.get("id", "scene")
	var error := image.save_png(ProjectSettings.globalize_path(output_path))
	if error == OK:
		print("[M4_BASELINE] Captured %s -> %s" % [scene_path, output_path])
	else:
		push_error("[M4_BASELINE] Screenshot save failed for %s: %s" % [scene_path, error])

