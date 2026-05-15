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
		"pos": Vector2(200, 350),
		"color": Color(0.3, 0.6, 0.3),
		"rec_level": "1-5",
		"bosses": "Tutorial Knight (Lv 5)",
	},
	{
		"id": "ironhold",
		"name": "Ironhold",
		"desc": "Industrial city of gears and clockwork.",
		"pos": Vector2(480, 200),
		"color": Color(0.5, 0.4, 0.3),
		"rec_level": "6-11",
		"bosses": "Clockwork Automaton (Lv 9), Admin Proxy (Lv 11)",
	},
	{
		"id": "fractured_wastes",
		"name": "Fractured Wastes",
		"desc": "Corrupted wasteland. Dangerous corruption storms.",
		"pos": Vector2(650, 380),
		"color": Color(0.5, 0.2, 0.6),
		"rec_level": "5-7",
		"bosses": "Data Wraith (Lv 7)",
	},
]

var _map_layer: CanvasLayer = null
var _is_open: bool = false
var _selected_index: int = 0


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("world_map"):
		if _is_open:
			close_map()
		else:
			# Only open in exploration mode
			if has_node("/root/GameManager") and GameManager.current_state == GameManager.GameState.EXPLORATION:
				open_map()
		return

	if not _is_open:
		return

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
	_is_open = true
	_build_map_ui()
	map_opened.emit()


func close_map() -> void:
	if not _is_open:
		return
	_is_open = false
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

	# Roads connecting regions
	_draw_road(Vector2(200 + 210, 350 + 70), Vector2(480 + 210, 200 + 70))
	_draw_road(Vector2(480 + 210, 200 + 70), Vector2(650 + 210, 380 + 70))
	_draw_road(Vector2(200 + 210, 350 + 70), Vector2(650 + 210, 380 + 70))

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
	var marker = ColorRect.new()
	marker.name = "Region_%d" % index
	marker.color = rd["color"]
	marker.size = Vector2(24, 24)
	marker.position = rd["pos"] + Vector2(210, 70) + Vector2(-12, -12)
	_map_layer.add_child(marker)

	var border = ColorRect.new()
	border.name = "Border_%d" % index
	border.color = Color.TRANSPARENT
	border.size = Vector2(30, 30)
	border.position = rd["pos"] + Vector2(210, 70) + Vector2(-15, -15)
	_map_layer.add_child(border)

	var name_label = Label.new()
	name_label.text = rd["name"]
	name_label.add_theme_font_size_override("font_size", 11)
	name_label.add_theme_color_override("font_color", Color(0.9, 0.9, 0.85))
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.position = rd["pos"] + Vector2(210, 70) + Vector2(-30, 16)
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
		info.text = "%s  |  Rec. Level: %s\n%s\nBosses: %s\n\nYour Level: %d" % [
			rd["name"], rd["rec_level"], rd["desc"], rd["bosses"], player_lvl
		]


func _fast_travel_to(index: int) -> void:
	if index < 0 or index >= REGION_DATA.size():
		return
	var rd = REGION_DATA[index]
	close_map()
	# Travel to the selected region via SceneTransitions
	if has_node("/root/SceneTransitions"):
		SceneTransitions.enter_region(rd["id"])
