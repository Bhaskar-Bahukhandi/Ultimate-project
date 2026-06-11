extends SceneTree

## Focused Phase 10M-M validation probe.
## Loads the polished presentation surfaces plus every chapter scene without
## changing collision, story-route scene ownership, or save data when slot 2 is occupied.

const TARGET_SCENES: Array[Dictionary] = [
	{"name": "main_menu", "scene": "res://scenes/main_menu.tscn"},
	{"name": "overworld", "scene": "res://scenes/overworld/overworld.tscn"},
	{"name": "oakhaven", "scene": "res://scenes/regions/oakhaven_region.tscn"},
	{"name": "ironhold", "scene": "res://scenes/regions/ironhold_region.tscn"},
	{"name": "fractured_wastes", "scene": "res://scenes/regions/fractured_wastes_region.tscn"},
	{"name": "forgotten_sectors", "scene": "res://scenes/regions/forgotten_sectors_revisit_hub.tscn"},
	{"name": "mirror_city", "scene": "res://scenes/regions/mirror_city_revisit_hub.tscn"},
	{"name": "cathedral_server", "scene": "res://scenes/regions/cathedral_server_revisit_hub.tscn"},
	{"name": "memory_ocean", "scene": "res://scenes/regions/memory_ocean_revisit_hub.tscn"},
	{"name": "saved_assembly", "scene": "res://scenes/regions/saved_assembly_revisit_hub.tscn"},
	{"name": "human_patch_lab", "scene": "res://scenes/regions/human_patch_lab_revisit_hub.tscn"},
	{"name": "root_of_heaven_prep", "scene": "res://scenes/regions/root_of_heaven_prep_hub.tscn"},
	{"name": "tutorial_knight", "scene": "res://scenes/chapter1/tutorial_knight_boss.tscn"},
	{"name": "combat_arena", "scene": "res://scenes/combat/combat_arena.tscn"},
	{"name": "choir_core", "scene": "res://scenes/chapter6/ch6_choir_core.tscn"},
]

const CHAPTER_DIRS: Array[String] = [
	"res://scenes/chapter1",
	"res://scenes/chapter2",
	"res://scenes/chapter3",
	"res://scenes/chapter4",
	"res://scenes/chapter5",
	"res://scenes/chapter6",
	"res://scenes/chapter7",
	"res://scenes/chapter8",
	"res://scenes/chapter9",
	"res://scenes/chapter10",
]

var _load_failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	print("[PHASE10MM] Validation probe started.")
	for target in TARGET_SCENES:
		await _load_scene(target.get("scene", ""), "TARGET", target.get("name", "scene"))

	await _world_map_smoke()
	await _resume_story_smoke()
	await _economy_smoke()
	await _save_load_checksum_smoke()

	var chapter_scenes := _collect_chapter_scenes()
	for scene_path in chapter_scenes:
		await _load_scene(scene_path, "CHAPTER_SWEEP", scene_path)

	if current_scene and is_instance_valid(current_scene):
		current_scene.queue_free()
		await process_frame
		await process_frame

	if _load_failures.is_empty():
		print("[PHASE10MM] Validation probe completed with no load failures.")
	else:
		push_error("[PHASE10MM] Validation probe load failures: %s" % str(_load_failures))
	quit()


func _load_scene(scene_path: String, scope: String, label: String) -> void:
	var packed_scene := load(scene_path) as PackedScene
	if not packed_scene:
		_load_failures.append(scene_path)
		push_error("[PHASE10MM][%s] FAIL load %s" % [scope, label])
		return

	if current_scene and is_instance_valid(current_scene):
		current_scene.queue_free()
		await process_frame

	var scene := packed_scene.instantiate()
	get_root().add_child(scene)
	current_scene = scene
	for frame_index in range(4):
		await process_frame
	if scope == "TARGET":
		_verify_target_contract(scene_path)
	print("[PHASE10MM][%s] PASS %s" % [scope, label])


func _world_map_smoke() -> void:
	if not get_root().has_node("WorldMapUI"):
		_load_failures.append("WorldMapUI")
		push_error("[PHASE10MM][WORLD_MAP] FAIL autoload missing")
		return
	var world_map_ui := get_root().get_node("WorldMapUI")
	if get_root().has_node("GameManager"):
		get_root().get_node("GameManager").call("change_state", 1)
	world_map_ui.call("open_map")
	await process_frame
	var map_layer := world_map_ui.get_node_or_null("WorldMapUI")
	if map_layer:
		print("[PHASE10MM][WORLD_MAP] PASS opened region map layer")
	else:
		_load_failures.append("WorldMapUI.layer")
		push_error("[PHASE10MM][WORLD_MAP] FAIL map layer missing")
	world_map_ui.call("close_map")
	await process_frame


func _resume_story_smoke() -> void:
	if not get_root().has_node("GameManager"):
		_load_failures.append("GameManager.resume_story")
		push_error("[PHASE10MM][RESUME_STORY] FAIL game manager missing")
		return
	var game_manager := get_root().get_node("GameManager")
	var previous_story_scene: String = game_manager.get("free_travel_story_scene")
	await _load_scene("res://scenes/chapter1/oakhaven_village.tscn", "RESUME_STORY", "chapter_route_probe")
	game_manager.call("remember_story_return_from_current_scene")
	var story_scene: String = game_manager.call("get_free_travel_story_scene")
	game_manager.set("free_travel_story_scene", previous_story_scene)
	if story_scene == "res://scenes/chapter1/oakhaven_village.tscn":
		print("[PHASE10MM][RESUME_STORY] PASS remembered chapter-route scene")
	else:
		_load_failures.append("resume_story_contract")
		push_error("[PHASE10MM][RESUME_STORY] FAIL remembered %s" % story_scene)


func _economy_smoke() -> void:
	if get_root().has_node("ShopSystem"):
		var shop_system := get_root().get_node("ShopSystem")
		shop_system.call("open_shop", "general")
		await process_frame
		shop_system.call("close_shop")
		await process_frame
		print("[PHASE10MM][SHOP] PASS general shop open/close smoke")
	else:
		_load_failures.append("ShopSystem")
		push_error("[PHASE10MM][SHOP] FAIL autoload missing")

	if get_root().has_node("CraftingSystem"):
		var recipes: Dictionary = get_root().get_node("CraftingSystem").call("get_recipes")
		if recipes.has("assemble_trial_stabilizers"):
			print("[PHASE10MM][CRAFTING] PASS recipe query smoke")
		else:
			_load_failures.append("CraftingSystem.recipes")
			push_error("[PHASE10MM][CRAFTING] FAIL expected late-material recipe missing")
	else:
		_load_failures.append("CraftingSystem")
		push_error("[PHASE10MM][CRAFTING] FAIL autoload missing")


func _save_load_checksum_smoke() -> void:
	if not get_root().has_node("GameManager"):
		_load_failures.append("GameManager.save_load")
		push_error("[PHASE10MM][SAVE_LOAD] FAIL game manager missing")
		return
	var game_manager := get_root().get_node("GameManager")
	var slot_path := "user://save_slot_2.save"
	var slot_backup_path := slot_path + ".bak"
	var slot_snapshot := _snapshot_user_file(slot_path)
	var backup_snapshot := _snapshot_user_file(slot_backup_path)

	await _load_scene("res://scenes/regions/oakhaven_region.tscn", "SAVE_LOAD", "oakhaven_probe")
	var save_ok: bool = game_manager.call("save_game", 2)
	var info: Dictionary = game_manager.call("get_save_info", 2)
	var load_ok: bool = false
	if save_ok and info.get("exists", false):
		load_ok = await game_manager.call("load_game", 2)
	for frame_index in range(4):
		await process_frame
	_restore_user_file(slot_path, slot_snapshot)
	_restore_user_file(slot_backup_path, backup_snapshot)

	if save_ok and load_ok and info.get("current_scene", "") == "res://scenes/regions/oakhaven_region.tscn":
		print("[PHASE10MM][SAVE_LOAD] PASS checksum save/load round-trip through restored slot 2 snapshot")
	else:
		_load_failures.append("save_load_checksum")
		push_error("[PHASE10MM][SAVE_LOAD] FAIL save=%s load=%s info=%s" % [save_ok, load_ok, str(info)])


func _collect_chapter_scenes() -> Array[String]:
	var scenes: Array[String] = []
	for chapter_dir in CHAPTER_DIRS:
		var dir := DirAccess.open(chapter_dir)
		if not dir:
			push_error("[PHASE10MM][CHAPTER_SWEEP] Missing directory %s" % chapter_dir)
			continue
		for file_name in dir.get_files():
			if file_name.ends_with(".tscn"):
				scenes.append("%s/%s" % [chapter_dir, file_name])
	scenes.sort()
	print("[PHASE10MM][CHAPTER_SWEEP] Scene count %d" % scenes.size())
	return scenes


func _verify_target_contract(scene_path: String) -> void:
	if not current_scene or not is_instance_valid(current_scene):
		return
	match scene_path:
		"res://scenes/regions/oakhaven_region.tscn":
			_verify_farming_marker("oakhaven_outskirts", "EARLY_FARMING")
		"res://scenes/regions/ironhold_region.tscn":
			_verify_farming_marker("ironhold_training_yard", "EARLY_FARMING")
		"res://scenes/regions/fractured_wastes_region.tscn":
			_verify_farming_marker("fractured_wastes_shard_fields", "EARLY_FARMING")
		"res://scenes/regions/forgotten_sectors_revisit_hub.tscn":
			_verify_late_hub("forgotten_sectors_cleanup")
		"res://scenes/regions/cathedral_server_revisit_hub.tscn":
			_verify_late_hub("cathedral_firewall_drill")
		"res://scenes/regions/memory_ocean_revisit_hub.tscn":
			_verify_late_hub("memory_ocean_salvage_run")
		"res://scenes/regions/mirror_city_revisit_hub.tscn", \
		"res://scenes/regions/saved_assembly_revisit_hub.tscn", \
		"res://scenes/regions/human_patch_lab_revisit_hub.tscn", \
		"res://scenes/regions/root_of_heaven_prep_hub.tscn":
			_verify_return_gate()


func _verify_late_hub(zone_id: String) -> void:
	_verify_return_gate()
	_verify_farming_marker(zone_id, "LATE_FARMING")


func _verify_return_gate() -> void:
	if current_scene.get_node_or_null("ReturnGate"):
		print("[PHASE10MM][RETURN_GATE] PASS %s" % current_scene.scene_file_path)
	else:
		_load_failures.append("%s.return_gate" % current_scene.scene_file_path)
		push_error("[PHASE10MM][RETURN_GATE] FAIL %s" % current_scene.scene_file_path)


func _verify_farming_marker(zone_id: String, scope: String) -> void:
	if _has_meta_value(current_scene, "farming_zone_id", zone_id):
		print("[PHASE10MM][%s] PASS %s" % [scope, zone_id])
	else:
		_load_failures.append("%s.%s" % [scope, zone_id])
		push_error("[PHASE10MM][%s] FAIL %s" % [scope, zone_id])


func _has_meta_value(node: Node, meta_key: StringName, expected_value: Variant) -> bool:
	if node.has_meta(meta_key) and node.get_meta(meta_key) == expected_value:
		return true
	for child in node.get_children():
		if child is Node and _has_meta_value(child, meta_key, expected_value):
			return true
	return false


func _snapshot_user_file(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {"exists": false, "text": ""}
	var file := FileAccess.open(path, FileAccess.READ)
	if not file:
		return {"exists": false, "text": ""}
	var text := file.get_as_text()
	file.close()
	return {"exists": true, "text": text}


func _restore_user_file(path: String, snapshot: Dictionary) -> void:
	if snapshot.get("exists", false):
		var file := FileAccess.open(path, FileAccess.WRITE)
		if file:
			file.store_string(snapshot.get("text", ""))
			file.close()
		return
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
