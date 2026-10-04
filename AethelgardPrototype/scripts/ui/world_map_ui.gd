extends Node
## ==========================================================================
## WORLD MAP UI — Press [M] to view region map with fast-travel (if unlocked)
## ==========================================================================

signal map_opened
signal map_closed

const REGION_DATA: Array = [
	{
		"id": "oakhaven",
		"name": "Oakhaven",
		"desc": "Peaceful village, now corrupted at its edges.",
		"pos": Vector2(90, 330),
		"color": Color(0.3, 0.6, 0.3),
		"rec_level": "1-5",
		"bosses": "Tutorial Knight (Lv 5)",
	},
	{
		"id": "ironhold",
		"name": "Ironhold",
		"desc": "Industrial city of gears and clockwork.",
		"pos": Vector2(205, 245),
		"color": Color(0.5, 0.4, 0.3),
		"rec_level": "6-11",
		"bosses": "Clockwork Automaton (Lv 9), Admin Proxy (Lv 11)",
	},
	{
		"id": "fractured_wastes",
		"name": "Fractured Wastes",
		"desc": "Corrupted wasteland. Dangerous corruption storms.",
		"pos": Vector2(320, 340),
		"color": Color(0.5, 0.2, 0.6),
		"rec_level": "5-7",
		"bosses": "Data Wraith (Lv 7)",
	},
	{
		"id": "forgotten_sectors",
		"name": "Forgotten Sectors",
		"desc": "Deleted transit pocket with a safe Chapter 4 revisit buffer.",
		"pos": Vector2(405, 225),
		"color": Color(0.2, 0.45, 0.55),
		"rec_level": "Story",
		"bosses": "Story route continues through Resume Story",
	},
	{
		"id": "mirror_city",
		"name": "Mirror City",
		"desc": "Reflected city edge with a safe Chapter 5 revisit buffer.",
		"pos": Vector2(490, 130),
		"color": Color(0.45, 0.65, 0.8),
		"rec_level": "Story",
		"bosses": "Story route continues through Resume Story",
	},
	{
		"id": "cathedral_server",
		"name": "Cathedral Server",
		"desc": "Server-cathedral buffer outside the Chapter 6 trial route.",
		"pos": Vector2(595, 215),
		"color": Color(0.72, 0.56, 0.2),
		"rec_level": "Story",
		"bosses": "Story route continues through Resume Story",
	},
	{
		"id": "memory_ocean",
		"name": "Memory Ocean",
		"desc": "Quiet backup shoreline outside the Chapter 7 choice route.",
		"pos": Vector2(690, 315),
		"color": Color(0.18, 0.45, 0.75),
		"rec_level": "Story",
		"bosses": "Story route continues through Resume Story",
	},
	{
		"id": "saved_assembly",
		"name": "Saved Assembly",
		"desc": "Assembly landing pad safe for post-unlock revisits.",
		"pos": Vector2(770, 225),
		"color": Color(0.45, 0.72, 0.45),
		"rec_level": "Story",
		"bosses": "Story route continues through Resume Story",
	},
	{
		"id": "human_patch_lab",
		"name": "Human Patch Lab",
		"desc": "Sealed lab antechamber outside the Chapter 9 evidence route.",
		"pos": Vector2(745, 120),
		"color": Color(0.72, 0.35, 0.32),
		"rec_level": "Story",
		"bosses": "Story route continues through Resume Story",
	},
	{
		"id": "root_of_heaven",
		"name": "Root of Heaven",
		"desc": "Final-prep buffer that cannot replay the Chapter 10 ending route.",
		"pos": Vector2(645, 75),
		"color": Color(0.92, 0.82, 0.42),
		"rec_level": "Story",
		"bosses": "Story route continues through Resume Story",
	},
	{
		"id": "__resume_story",
		"name": "Resume Story",
		"desc": "Return to the story route remembered before free travel.",
		"pos": Vector2(75, 95),
		"color": Color(1.0, 0.82, 0.25),
		"rec_level": "Current chapter",
		"bosses": "Uses the last remembered story scene when available",
		"action": "resume_story",
	},
]

var _map_layer: CanvasLayer = null
var _is_open: bool = false
var _selected_index: int = 0


func _ready() -> void:
	# The map pauses the game while open, so it must keep processing input.
	process_mode = Node.PROCESS_MODE_ALWAYS


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("world_map"):
		if _is_open:
			close_map()
			get_viewport().set_input_as_handled()
		else:
			# Only open in exploration mode, with no other menu or dialogue up
			if has_node("/root/GameManager") and GameManager.current_state == GameManager.GameState.EXPLORATION \
					and not DialogueManager.is_active:
				open_map()
				if _is_open:
					get_viewport().set_input_as_handled()
		return

	if not _is_open:
		return

	# The map is modal: no key reaches the game underneath (movement, F
	# interact, Esc opening pause) while it's open.
	if event is InputEventKey or event is InputEventJoypadButton or event is InputEventJoypadMotion:
		get_viewport().set_input_as_handled()

	if event.is_action_pressed("move_left") or event.is_action_pressed("ui_left"):
		_selected_index = (_selected_index - 1) % REGION_DATA.size()
		if _selected_index < 0:
			_selected_index = REGION_DATA.size() - 1
		_refresh_selection()
	elif event.is_action_pressed("move_right") or event.is_action_pressed("ui_right"):
		_selected_index = (_selected_index + 1) % REGION_DATA.size()
		_refresh_selection()
	elif event.is_action_pressed("ui_accept") or event.is_action_pressed("interact"):
		_fast_travel_to(_selected_index)
	elif event.is_action_pressed("ui_cancel"):
		close_map()


func open_map() -> void:
	if _is_open:
		return
	# Pauses the world (movement, encounters, storms) while browsing.
	if not ContextStack.push(&"world_map", self):
		return
	_is_open = true
	_build_map_ui()
	map_opened.emit()


func close_map() -> void:
	if not _is_open:
		return
	_is_open = false
	ContextStack.pop(&"world_map")
	if _map_layer and is_instance_valid(_map_layer):
		_map_layer.queue_free()
		_map_layer = null
	map_closed.emit()


func _build_map_ui() -> void:
	if _map_layer and is_instance_valid(_map_layer):
		_map_layer.queue_free()

	_map_layer = CanvasLayer.new()
	_map_layer.name = "WorldMapUI"
	_map_layer.layer = 90
	add_child(_map_layer)

	# Background
	var bg = ColorRect.new()
	bg.name = "MapBG"
	bg.color = Color(0.02, 0.02, 0.05, 0.92)
	bg.size = Vector2(1280, 720)
	_map_layer.add_child(bg)

	# Title
	var title = Label.new()
	title.text = "═══  WORLD MAP  ═══"
	title.add_theme_font_size_override("font_size", 22)
	title.add_theme_color_override("font_color", Color(0.7, 0.85, 1.0))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.size = Vector2(1280, 40)
	title.position = Vector2(0, 20)
	_map_layer.add_child(title)

	# Map area (stylized top-down)
	var map_area = ColorRect.new()
	map_area.name = "MapArea"
	map_area.color = Color(0.08, 0.08, 0.12)
	map_area.size = Vector2(860, 420)
	map_area.position = Vector2(210, 70)
	_map_layer.add_child(map_area)

	for ridge_data in [
		{"pos": Vector2(244, 140), "size": Vector2(794, 18), "color": Color(0.12, 0.22, 0.28, 0.26)},
		{"pos": Vector2(262, 360), "size": Vector2(730, 14), "color": Color(0.22, 0.12, 0.28, 0.20)},
		{"pos": Vector2(348, 448), "size": Vector2(610, 10), "color": Color(0.18, 0.20, 0.12, 0.20)},
	]:
		var ridge = ColorRect.new()
		ridge.color = ridge_data["color"]
		ridge.position = ridge_data["pos"]
		ridge.size = ridge_data["size"]
		_map_layer.add_child(ridge)

	# Roads connect the story-route region nodes.
	for i in range(REGION_DATA.size() - 2):
		_draw_road(REGION_DATA[i]["pos"] + Vector2(210, 70), REGION_DATA[i + 1]["pos"] + Vector2(210, 70))

	# Region markers
	for i in range(REGION_DATA.size()):
		var rd = REGION_DATA[i]
		_create_region_marker(rd, i)

	# Player position indicator
	var current = GameManager.current_region if has_node("/root/GameManager") else ""
	for i in range(REGION_DATA.size()):
		if REGION_DATA[i]["id"] == current:
			var you = Label.new()
			you.text = "▼ YOU"
			you.add_theme_font_size_override("font_size", 10)
			you.add_theme_color_override("font_color", Color(0.2, 0.9, 1.0))
			you.position = REGION_DATA[i]["pos"] + Vector2(210, 70) + Vector2(-10, -35)
			_map_layer.add_child(you)

	# Info panel at bottom
	var info_bg = ColorRect.new()
	info_bg.name = "InfoPanel"
	info_bg.color = Color(0.06, 0.06, 0.1, 0.9)
	info_bg.size = Vector2(860, 170)
	info_bg.position = Vector2(210, 510)
	_map_layer.add_child(info_bg)
	var info_edge = ColorRect.new()
	info_edge.color = Color(0.44, 0.62, 0.78, 0.48)
	info_edge.size = Vector2(860, 3)
	info_edge.position = Vector2(210, 510)
	_map_layer.add_child(info_edge)

	var info_label = Label.new()
	info_label.name = "InfoLabel"
	info_label.add_theme_font_size_override("font_size", 13)
	info_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.75))
	info_label.position = Vector2(230, 520)
	info_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	info_label.size = Vector2(820, 150)
	_map_layer.add_child(info_label)

	# Controls
	var controls = Label.new()
	controls.text = "[←/→] Select   [F/Enter] Travel   [M/Esc] Close"
	controls.add_theme_font_size_override("font_size", 10)
	controls.add_theme_color_override("font_color", Color(0.45, 0.45, 0.5))
	controls.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	controls.size = Vector2(1280, 20)
	controls.position = Vector2(0, 695)
	_map_layer.add_child(controls)

	_refresh_selection()


func _create_region_marker(rd: Dictionary, index: int) -> void:
	var is_resume: bool = rd.get("action", "") == "resume_story"
	var unlocked: bool = is_resume or _is_region_unlocked(rd["id"])
	var marker = ColorRect.new()
	marker.name = "Region_%d" % index
	marker.color = rd["color"] if unlocked else Color(0.16, 0.16, 0.2)
	marker.size = Vector2(24, 24)
	marker.position = rd["pos"] + Vector2(210, 70) + Vector2(-12, -12)
	_map_layer.add_child(marker)

	var border = ColorRect.new()
	border.name = "Border_%d" % index
	border.color = Color.TRANSPARENT
	border.size = Vector2(30, 30)
	border.position = rd["pos"] + Vector2(210, 70) + Vector2(-15, -15)
	_map_layer.add_child(border)

	var name_plate = ColorRect.new()
	name_plate.color = Color(0.02, 0.03, 0.05, 0.74)
	name_plate.size = Vector2(116, 34)
	name_plate.position = rd["pos"] + Vector2(210, 70) + Vector2(-58, 14)
	_map_layer.add_child(name_plate)

	var name_label = Label.new()
	name_label.text = rd["name"] if unlocked else "%s\nLocked" % rd["name"]
	name_label.add_theme_font_size_override("font_size", 11)
	name_label.add_theme_color_override("font_color", Color(0.9, 0.9, 0.85) if unlocked else Color(0.48, 0.48, 0.55))
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	name_label.position = rd["pos"] + Vector2(210, 70) + Vector2(-54, 16)
	name_label.size = Vector2(108, 30)
	_map_layer.add_child(name_label)


func _draw_road(from: Vector2, to: Vector2) -> void:
	for i in range(20):
		var t = float(i) / 20.0
		var dot = ColorRect.new()
		dot.color = Color(0.25, 0.22, 0.2, 0.5)
		dot.size = Vector2(4, 4)
		dot.position = from.lerp(to, t)
		_map_layer.add_child(dot)


func _refresh_selection() -> void:
	if not _map_layer or not is_instance_valid(_map_layer):
		return

	# Reset all borders
	for i in range(REGION_DATA.size()):
		var border = _map_layer.get_node_or_null("Border_%d" % i)
		if border:
			border.color = Color.TRANSPARENT

	# Highlight selected
	var border = _map_layer.get_node_or_null("Border_%d" % _selected_index)
	if border:
		border.color = Color(1, 0.85, 0.3, 0.8)

	# Update info panel
	var info = _map_layer.get_node_or_null("InfoLabel")
	if info and _selected_index < REGION_DATA.size():
		var rd = REGION_DATA[_selected_index]
		var player_lvl = GameManager.player_stats.get("level", 1) if has_node("/root/GameManager") else 1
		var status := "Resume returns to the remembered story route."
		if rd.get("action", "") != "resume_story" and has_node("/root/GameManager"):
			status = GameManager.get_free_travel_lock_message(rd["id"])
			if status.is_empty():
				status = "Free travel available."
		info.text = "%s  |  Rec. Level: %s\n%s\nBosses: %s\nStatus: %s\nYour Level: %d" % [
			rd["name"], rd["rec_level"], rd["desc"], rd["bosses"], status, player_lvl
		]


func _fast_travel_to(index: int) -> void:
	if index < 0 or index >= REGION_DATA.size():
		return
	var rd = REGION_DATA[index]
	if rd.get("action", "") == "resume_story":
		_resume_story()
		return
	if not has_node("/root/GameManager"):
		_show_map_status("Travel is unavailable without the game state manager.")
		return
	var region_id: String = rd["id"]
	var travel_message: String = GameManager.get_free_travel_lock_message(region_id)
	if not travel_message.is_empty():
		_show_map_status(travel_message)
		return
	GameManager.remember_story_return_from_current_scene()
	close_map()
	# Travel to the selected region via SceneTransitions
	if has_node("/root/SceneTransitions"):
		SceneTransitions.enter_region(region_id)


func _is_region_unlocked(region_id: String) -> bool:
	return has_node("/root/GameManager") and GameManager.is_region_unlocked_for_free_travel(region_id)


func _show_map_status(message: String) -> void:
	var info = _map_layer.get_node_or_null("InfoLabel") if _map_layer and is_instance_valid(_map_layer) else null
	if info:
		info.text = message


func _resume_story() -> void:
	if not has_node("/root/GameManager"):
		_show_map_status("Story resume is unavailable without the game state manager.")
		return
	var scene_path: String = GameManager.get_free_travel_story_scene()
	if scene_path.is_empty() or not ResourceLoader.exists(scene_path):
		_show_map_status("No safe story resume scene is available yet.")
		return
	close_map()
	if has_node("/root/SceneTransitions"):
		SceneTransitions.change_scene(scene_path)
	else:
		get_tree().change_scene_to_file(scene_path)
