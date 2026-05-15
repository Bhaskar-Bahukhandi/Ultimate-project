extends Node
## ==========================================================================
## PROGRESSION BREADCRUMB — Shows current main story objective on the HUD
## ==========================================================================
## Autoload or add to any scene. Reads story flags from GameManager and
## displays a persistent subtle objective hint at the top-left of the screen.
## Also shows directional arrows pointing toward objective locations.
## ==========================================================================

signal objective_changed(objective_text: String)

# ── UI Elements ──────────────────────────────────────────────────────
var _hud_layer: CanvasLayer = null
var _objective_panel: PanelContainer = null
var _objective_label: RichTextLabel = null
var _arrow_indicator: Label = null
var _pulse_tween: Tween = null

# ── State ────────────────────────────────────────────────────────────
var _current_objective: String = ""
var _current_hint: String = ""
var _target_position: Vector2 = Vector2.ZERO
var _has_target: bool = false
var _visible: bool = true

# ── Objective database: ordered by priority (first matching = active) ──
# Each entry: {flag_required (must be true), flag_blocker (if true, skip),
#              text, hint, target_pos (in current region)}
const OBJECTIVES: Array = [
	# ── Chapter 1 ──
	{
		"blocker": "tutorial_completed",
		"required": "",
		"text": "Survive the crash site",
		"hint": "Follow the glowing path out of the crater",
		"region": "oakhaven",
		"target": Vector2(400, 300),
	},
	{
		"blocker": "ch1_knight_spared",  # OR ch1_knight_killed
		"blocker_alt": "ch1_knight_killed",
		"required": "tutorial_completed",
		"text": "Defeat the Corrupted Sentinel",
		"hint": "The sentinel guards the path ahead — prepare for battle",
		"region": "oakhaven",
		"target": Vector2(2200, 1100),
	},
	{
		"blocker": "ch1_complete",
		"required": "tutorial_completed",
		"text": "Explore Oakhaven & find Elara",
		"hint": "Talk to the villagers and investigate the corruption",
		"region": "oakhaven",
		"target": Vector2(1200, 800),
	},

	# ── Chapter 2 ──
	{
		"blocker": "ch2_ironhold_entered",
		"required": "ch1_complete",
		"text": "Travel to Ironhold",
		"hint": "Head to the world map and enter the Ironhold region",
		"region": "overworld",
		"target": Vector2(800, 400),
	},
	{
		"blocker": "ch2_data_wraith_defeated",
		"required": "ch2_ironhold_entered",
		"text": "Investigate the Underground Network",
		"hint": "The underground passages hide the Data Wraith — Rec. Lv 7",
		"region": "ironhold",
		"target": Vector2(1200, 2000),
	},
	{
		"blocker": "ch2_clockwork_automaton_defeated",
		"required": "ch2_data_wraith_defeated",
		"text": "Ascend the Clock Tower",
		"hint": "The Clockwork Automaton guards the upper floors — Rec. Lv 9",
		"region": "ironhold",
		"target": Vector2(3100, 400),
	},
	{
		"blocker": "ch2_administrator_proxy_defeated",
		"required": "ch2_clockwork_automaton_defeated",
		"text": "Defeat the Administrator Proxy",
		"hint": "Deep in the underground, a proxy of the Administrator awaits — Rec. Lv 11",
		"region": "ironhold",
		"target": Vector2(1400, 2200),
	},
	{
		"blocker": "ch2_complete",
		"required": "ch2_administrator_proxy_defeated",
		"text": "Complete Chapter 2",
		"hint": "Return to the surface and decide what to do with what you've learned",
		"region": "ironhold",
		"target": Vector2(1400, 900),
	},

	# ── Chapter 3 ──
	{
		"blocker": "ch3_sovereign_defeated",
		"required": "ch2_complete",
		"text": "Enter the Fractured Wastes",
		"hint": "The final region holds the truth about Aethelgard — Rec. Lv 12+",
		"region": "fractured_wastes",
		"target": Vector2(1500, 1300),
	},
	{
		"blocker": "ch3_complete",
		"required": "ch3_sovereign_defeated",
		"text": "Confront the Source",
		"hint": "The SOVEREIGN has fallen. What lies beyond?",
		"region": "fractured_wastes",
		"target": Vector2(1500, 500),
	},

	# ── Endgame / Free Roam ──
	{
		"blocker": "",
		"required": "ch3_complete",
		"text": "Free Roam — Explore at will",
		"hint": "All regions are open. Find secrets, complete side quests, challenge the arena",
		"region": "",
		"target": Vector2.ZERO,
	},
]


func _ready() -> void:
	_build_hud()
	# Update objective every 2 seconds (not every frame)
	var timer = Timer.new()
	timer.wait_time = 2.0
	timer.autostart = true
	timer.timeout.connect(_refresh_objective)
	add_child(timer)
	# Initial refresh
	call_deferred("_refresh_objective")


func _build_hud() -> void:
	_hud_layer = CanvasLayer.new()
	_hud_layer.name = "ProgressionBreadcrumbHUD"
	_hud_layer.layer = 85  # Below quest tracker (90) and dialogue (100)
	add_child(_hud_layer)

	_objective_panel = PanelContainer.new()
	_objective_panel.name = "ObjectivePanel"
	_objective_panel.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	_objective_panel.offset_left = -360
	_objective_panel.offset_top = 12
	_objective_panel.offset_right = -12
	_objective_panel.offset_bottom = 72
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.02, 0.02, 0.06, 0.65)
	style.border_color = Color(0.2, 0.5, 0.9, 0.4)
	style.border_width_left = 3
	style.border_width_top = 0
	style.border_width_right = 0
	style.border_width_bottom = 0
	style.set_corner_radius_all(3)
	style.content_margin_left = 10
	style.content_margin_right = 10
	style.content_margin_top = 4
	style.content_margin_bottom = 4
	_objective_panel.add_theme_stylebox_override("panel", style)
	_objective_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_hud_layer.add_child(_objective_panel)

	var vbox = VBoxContainer.new()
	vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_objective_panel.add_child(vbox)

	_objective_label = RichTextLabel.new()
	_objective_label.bbcode_enabled = true
	_objective_label.fit_content = true
	_objective_label.scroll_active = false
	_objective_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_objective_label.custom_minimum_size = Vector2(318, 28)
	vbox.add_child(_objective_label)

	# Arrow indicator for direction
	_arrow_indicator = Label.new()
	_arrow_indicator.text = ""
	_arrow_indicator.add_theme_font_size_override("font_size", 11)
	_arrow_indicator.add_theme_color_override("font_color", Color(0.5, 0.7, 1.0, 0.7))
	_arrow_indicator.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(_arrow_indicator)


func _refresh_objective() -> void:
	if not has_node("/root/GameManager"):
		return

	# Hide outside exploration so it never overlays splash, menus, cutscenes, or game over.
	var state = GameManager.current_state if "current_state" in GameManager else -1
	if state != GameManager.GameState.EXPLORATION:
		_hud_layer.visible = false
		return
	_hud_layer.visible = _visible

	var new_obj = ""
	var new_hint = ""
	_has_target = false

	for obj in OBJECTIVES:
		# Check if blocker flag is set (means this objective is done)
		var blocked = false
		if obj["blocker"] != "":
			if GameManager.get_story_flag(obj["blocker"]):
				blocked = true
		if obj.has("blocker_alt") and obj["blocker_alt"] != "":
			if GameManager.get_story_flag(obj["blocker_alt"]):
				blocked = true
		if blocked:
			continue

		# Check if required flag is set (means prerequisites are met)
		if obj["required"] != "":
			if not GameManager.get_story_flag(obj["required"]):
				continue

		# This is our current objective
		new_obj = obj["text"]
		new_hint = obj["hint"]
		if obj["target"] != Vector2.ZERO:
			_target_position = obj["target"]
			_has_target = true
		break

	if new_obj != _current_objective:
		_current_objective = new_obj
		_current_hint = new_hint
		_update_display()
		objective_changed.emit(new_obj)


func _update_display() -> void:
	if not _objective_label:
		return

	if _current_objective.is_empty():
		_objective_panel.visible = false
		return

	_objective_panel.visible = true
	_objective_label.text = "[color=#4488CC][b]►[/b][/color] [color=#CCDDEE]%s[/color]\n[color=#667788][i]%s[/i][/color]" % [_current_objective, _current_hint]

	# Subtle pulse on objective change
	if _pulse_tween and _pulse_tween.is_valid():
		_pulse_tween.kill()
	_pulse_tween = create_tween()
	_objective_panel.modulate = Color(1.2, 1.2, 1.5, 1.0)
	_pulse_tween.tween_property(_objective_panel, "modulate", Color.WHITE, 1.5)


func _process(_delta: float) -> void:
	if not _has_target or not _arrow_indicator:
		if _arrow_indicator:
			_arrow_indicator.text = ""
		return

	# Get player position if available
	var player = _get_player()
	if not player:
		_arrow_indicator.text = ""
		return

	var dir = (_target_position - player.global_position).normalized()
	var dist = player.global_position.distance_to(_target_position)

	if dist < 100:
		_arrow_indicator.text = "  ★ Nearby"
		_arrow_indicator.add_theme_color_override("font_color", Color(1.0, 0.85, 0.2, 0.9))
		return

	# Convert direction to arrow
	var angle = atan2(dir.y, dir.x)
	var arrow = _angle_to_arrow(angle)
	var dist_text = "%dm" % int(dist / 10)
	_arrow_indicator.text = "  %s %s away" % [arrow, dist_text]
	_arrow_indicator.add_theme_color_override("font_color", Color(0.5, 0.7, 1.0, 0.7))


func _angle_to_arrow(angle: float) -> String:
	# Map angle to 8-directional arrow
	if angle >= -0.39 and angle < 0.39:
		return "→"
	elif angle >= 0.39 and angle < 1.18:
		return "↘"
	elif angle >= 1.18 and angle < 1.96:
		return "↓"
	elif angle >= 1.96 or angle < -1.96:
		return "←"
	elif angle >= -1.96 and angle < -1.18:
		return "↗"  # Actually NW but using ↖ → ↗
	elif angle >= -1.18 and angle < -0.39:
		return "↑"
	return "→"


func _get_player() -> Node2D:
	var tree = get_tree()
	if not tree:
		return null
	var players = tree.get_nodes_in_group("player")
	if players.is_empty():
		return null
	return players[0] as Node2D


## Public API

func hide_breadcrumb() -> void:
	_visible = false
	if _hud_layer:
		_hud_layer.visible = false

func show_breadcrumb() -> void:
	_visible = true
	if _hud_layer:
		_hud_layer.visible = true

func get_current_objective() -> String:
	return _current_objective

func force_refresh() -> void:
	_refresh_objective()
