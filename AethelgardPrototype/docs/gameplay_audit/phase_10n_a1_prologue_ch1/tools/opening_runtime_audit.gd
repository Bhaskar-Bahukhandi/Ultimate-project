extends SceneTree

const OUT_DIR := "res://docs/gameplay_audit/phase_10n_a1_prologue_ch1"
const DIAG_DIR := OUT_DIR + "/diagnostics"
const SCREEN_DIR := OUT_DIR + "/screenshots"

const SCENES := [
	{"id": "splash", "path": "res://scenes/splash_screen.tscn"},
	{"id": "main_menu", "path": "res://scenes/main_menu.tscn"},
	{"id": "flight_707", "path": "res://scenes/prologue/flight_707.tscn"},
	{"id": "crash_sequence", "path": "res://scenes/prologue/crash_sequence.tscn"},
	{"id": "glitch_crater_awakening", "path": "res://scenes/chapter1/glitch_crater_awakening.tscn"},
	{"id": "overworld", "path": "res://scenes/overworld/overworld.tscn"},
	{"id": "oakhaven_region", "path": "res://scenes/regions/oakhaven_region.tscn"},
	{"id": "elara_meeting", "path": "res://scenes/chapter1/elara_meeting.tscn"},
	{"id": "path_to_oakhaven", "path": "res://scenes/chapter1/path_to_oakhaven.tscn"},
	{"id": "oakhaven_village", "path": "res://scenes/chapter1/oakhaven_village.tscn"},
	{"id": "tutorial_knight_boss", "path": "res://scenes/chapter1/tutorial_knight_boss.tscn"},
]

var results: Dictionary = {
	"phase": "10N-A1",
	"classification": "HEADLESS RUNTIME EVIDENCE",
	"live_viewport_available": false,
	"live_play_claim": false,
	"note": "Headless scene-load and input probe only. Not a headed/live visual playtest.",
	"scenes": [],
	"fresh_start_probe": {},
	"movement_probe": {},
	"movement_probes": [],
	"input_actions_present": {},
	"errors": [],
}

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	_make_dirs()
	results["godot_version"] = Engine.get_version_info()
	results["input_actions_present"] = _input_actions_present()
	for scene_info in SCENES:
		await _inspect_scene(scene_info)
	await _probe_scene_movement("overworld", "res://scenes/overworld/overworld.tscn")
	await _probe_scene_movement("oakhaven_region", "res://scenes/regions/oakhaven_region.tscn")
	await _probe_scene_movement("oakhaven_village_legacy", "res://scenes/chapter1/oakhaven_village.tscn")
	if not results["movement_probes"].is_empty():
		results["movement_probe"] = results["movement_probes"][0]
	await _probe_fresh_start_route()
	_write_json(DIAG_DIR + "/opening_runtime_audit.json", results)
	quit()

func _make_dirs() -> void:
	var dirs := [OUT_DIR, OUT_DIR + "/tools", DIAG_DIR, SCREEN_DIR]
	for dir in dirs:
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(dir))

func _input_actions_present() -> Dictionary:
	var actions := [
		"move_left", "move_right", "move_up", "move_down", "jump",
		"attack", "defend", "interact", "pause_menu", "world_map",
		"status_window", "root_access", "data_vision", "heal", "flee_combat"
	]
	var out := {}
	for action in actions:
		out[action] = InputMap.has_action(action)
	return out

func _inspect_scene(scene_info: Dictionary) -> void:
	var entry := {
		"id": scene_info["id"],
		"path": scene_info["path"],
		"exists": ResourceLoader.exists(scene_info["path"]),
		"load_ok": false,
		"instantiate_ok": false,
		"node_count": 0,
		"labels": [],
		"buttons": [],
		"cameras": [],
		"players": [],
		"character_bodies": [],
		"areas": [],
		"color_rect_count": 0,
		"screenshot_path": "",
		"screenshot_status": "not_attempted",
		"screenshot_stats": {},
	}
	if not entry["exists"]:
		results["scenes"].append(entry)
		return
	var packed := ResourceLoader.load(scene_info["path"])
	entry["load_ok"] = packed != null
	if packed == null or not (packed is PackedScene):
		results["scenes"].append(entry)
		return
	var inst: Node = null
	var err_text := ""
	inst = (packed as PackedScene).instantiate()
	if inst == null:
		entry["instantiate_error"] = "PackedScene.instantiate returned null"
		results["scenes"].append(entry)
		return
	entry["instantiate_ok"] = true
	root.add_child(inst)
	await process_frame
	await process_frame
	_scan_node(inst, entry)
	var shot := SCREEN_DIR + "/" + str(scene_info["id"]) + "_headless.png"
	entry["screenshot_path"] = shot
	entry["screenshot_status"] = _capture_viewport(shot, entry)
	if is_instance_valid(inst):
		inst.queue_free()
	await process_frame
	if err_text != "":
		entry["runtime_error"] = err_text
	results["scenes"].append(entry)

func _scan_node(node: Node, entry: Dictionary) -> void:
	entry["node_count"] += 1
	if node is Label:
		entry["labels"].append({
			"path": str(node.get_path()),
			"text": _trim_text((node as Label).text),
			"visible": (node as CanvasItem).visible,
		})
	elif node is RichTextLabel:
		entry["labels"].append({
			"path": str(node.get_path()),
			"text": _trim_text((node as RichTextLabel).text),
			"visible": (node as CanvasItem).visible,
		})
	elif node is Button:
		entry["buttons"].append({
			"path": str(node.get_path()),
			"text": _trim_text((node as Button).text),
			"visible": (node as CanvasItem).visible,
		})
	elif node is Camera2D:
		entry["cameras"].append(str(node.get_path()))
	elif node is CharacterBody2D:
		entry["character_bodies"].append(str(node.get_path()))
	elif node is Area2D:
		entry["areas"].append(str(node.get_path()))
	elif node is ColorRect:
		entry["color_rect_count"] += 1
	if node.is_in_group("player") or node.name.to_lower().contains("player"):
		entry["players"].append(str(node.get_path()))
	for child in node.get_children():
		_scan_node(child, entry)

func _trim_text(text: String) -> String:
	text = text.replace("\n", "\\n")
	if text.length() > 140:
		return text.substr(0, 137) + "..."
	return text

func _capture_viewport(path: String, entry: Dictionary) -> String:
	var img := root.get_texture().get_image()
	if img == null or img.is_empty():
		return "failed_empty_image"
	entry["screenshot_stats"] = _sample_image_stats(img)
	var err := img.save_png(ProjectSettings.globalize_path(path))
	if err != OK:
		return "failed_save_%s" % str(err)
	return "saved_headless_capture"

func _sample_image_stats(img: Image) -> Dictionary:
	var w := img.get_width()
	var h := img.get_height()
	var samples := 0
	var non_black := 0
	var alpha_visible := 0
	var total_luma := 0.0
	var step_x = max(1, int(w / 32))
	var step_y = max(1, int(h / 18))
	for y in range(0, h, step_y):
		for x in range(0, w, step_x):
			var c := img.get_pixel(x, y)
			samples += 1
			var luma := (c.r + c.g + c.b) / 3.0
			total_luma += luma
			if c.a > 0.05:
				alpha_visible += 1
			if luma > 0.02:
				non_black += 1
	return {
		"width": w,
		"height": h,
		"samples": samples,
		"alpha_visible_samples": alpha_visible,
		"non_black_samples": non_black,
		"average_luma": total_luma / max(1, samples),
	}

func _probe_scene_movement(id: String, path: String) -> void:
	var probe := {
		"id": id,
		"path": path,
		"scene_exists": ResourceLoader.exists(path),
		"load_ok": false,
		"player_found": false,
		"camera_found": false,
		"initial_position": null,
		"after_position": null,
		"input_sent": ["move_right"],
		"moved": false,
		"game_state_before": null,
		"game_state_after": null,
		"dialogue_active": null,
		"notes": [],
	}
	if not probe["scene_exists"]:
		results["movement_probes"].append(probe)
		return
	var packed := ResourceLoader.load(path)
	probe["load_ok"] = packed != null
	if packed == null or not (packed is PackedScene):
		results["movement_probes"].append(probe)
		return
	var inst := (packed as PackedScene).instantiate()
	root.add_child(inst)
	await process_frame
	await process_frame
	var player := inst.get_node_or_null("Player")
	if player == null:
		var candidates := get_nodes_in_group("player")
		if not candidates.is_empty():
			player = candidates[0]
	probe["player_found"] = player != null
	if player is Node2D:
		probe["initial_position"] = {"x": (player as Node2D).global_position.x, "y": (player as Node2D).global_position.y}
		probe["camera_found"] = (player as Node).get_node_or_null("Camera2D") != null
	var game_manager := root.get_node_or_null("GameManager")
	if game_manager != null:
		probe["game_state_before"] = game_manager.get("current_state")
	var dialogue_manager := root.get_node_or_null("DialogueManager")
	if dialogue_manager != null:
		probe["dialogue_active"] = dialogue_manager.get("is_active")
	Input.action_press("move_right")
	for i in range(30):
		await process_frame
	Input.action_release("move_right")
	await process_frame
	if player is Node2D:
		var after := (player as Node2D).global_position
		probe["after_position"] = {"x": after.x, "y": after.y}
		var before := Vector2(probe["initial_position"]["x"], probe["initial_position"]["y"])
		probe["moved"] = before.distance_to(after) > 1.0
	if game_manager != null:
		probe["game_state_after"] = game_manager.get("current_state")
	if probe["dialogue_active"] == true:
		probe["notes"].append("Initial Oakhaven dialogue was active during input probe; movement may be intentionally blocked.")
	if is_instance_valid(inst):
		inst.queue_free()
	await process_frame
	results["movement_probes"].append(probe)

func _write_json(path: String, data: Dictionary) -> void:
	var file := FileAccess.open(ProjectSettings.globalize_path(path), FileAccess.WRITE)
	if file == null:
		push_error("Failed to write " + path)
		return
	file.store_string(JSON.stringify(data, "\t"))
	file.close()

func _probe_fresh_start_route() -> void:
	var probe := {
		"classification": "HEADLESS RUNTIME EVIDENCE",
		"path": "res://scenes/main_menu.tscn",
		"scene_exists": ResourceLoader.exists("res://scenes/main_menu.tscn"),
		"new_game_method_exists": false,
		"new_game_called": false,
		"current_scene_after_wait": "",
		"current_scene_name_after_wait": "",
		"story_flags_after_call": {},
		"notes": [],
	}
	if not probe["scene_exists"]:
		results["fresh_start_probe"] = probe
		return
	var packed := ResourceLoader.load("res://scenes/main_menu.tscn")
	if packed == null or not (packed is PackedScene):
		probe["notes"].append("Main menu could not be loaded as PackedScene.")
		results["fresh_start_probe"] = probe
		return
	var inst := (packed as PackedScene).instantiate()
	root.add_child(inst)
	await process_frame
	await process_frame
	probe["new_game_method_exists"] = inst.has_method("_on_new_game_pressed")
	if inst.has_method("_on_new_game_pressed"):
		inst.call("_on_new_game_pressed")
		probe["new_game_called"] = true
		for i in range(180):
			await process_frame
		var current := current_scene
		if current != null:
			probe["current_scene_after_wait"] = current.scene_file_path
			probe["current_scene_name_after_wait"] = current.name
	var game_manager := root.get_node_or_null("GameManager")
	if game_manager != null:
		var flags = game_manager.get("story_flags")
		if flags is Dictionary:
			for key in ["plane_crash_completed", "ch1_awakening_complete", "ch1_glitch_crater_complete", "ch1_oakhaven_entered"]:
				probe["story_flags_after_call"][key] = flags.get(key, null)
	results["fresh_start_probe"] = probe
