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

	# ── Chapter 4 ──
	{
		"blocker": "ch4_forgotten_sectors_entered",
		"required": "ch3_complete",
		"text": "Enter the Forgotten Sectors",
		"hint": "Follow the crack beyond the Archive into SOVEREIGN's deleted region",
		"region": "forgotten_sectors",
		"target": Vector2(640, 360),
	},
	{
		"blocker": "ch4_complete",
		"required": "ch4_forgotten_sectors_entered",
		"text": "Answer the Null Court",
		"hint": "The deleted citizens guard the fifth Source Key fragment",
		"region": "forgotten_sectors",
		"target": Vector2(640, 360),
	},

	# ── Chapter 5 ──
	{
		"blocker": "ch5_mirror_city_entered",
		"required": "ch4_complete",
		"text": "Enter the Mirror City",
		"hint": "Follow the reflected road from the Null Court",
		"region": "mirror_city",
		"target": Vector2(640, 360),
	},
	{
		"blocker": "ch5_all_echoes_resolved",
		"required": "ch5_mirror_city_entered",
		"text": "Resolve the Mirror Plaza echoes",
		"hint": "Meet the obedient, savior, and coward reflections before the trial",
		"region": "mirror_city",
		"target": Vector2(640, 360),
	},
	{
		"blocker": "ch5_choice_echo_resolved",
		"required": "ch5_all_echoes_resolved",
		"text": "Begin the Reflection Trial",
		"hint": "Let Mirror Kaelen judge the consequences of Chapter 4",
		"region": "mirror_city",
		"target": Vector2(640, 360),
	},
	{
		"blocker": "ch5_complete",
		"required": "ch5_choice_echo_resolved",
		"text": "Confront Mirror Kaelen",
		"hint": "Refine the trail toward Source Key Fragment #6",
		"region": "mirror_city",
		"target": Vector2(640, 360),
	},

	# ── Chapter 6 ──
	{
		"blocker": "ch6_cathedral_entered",
		"required": "ch5_complete",
		"text": "Enter the Cathedral Server",
		"hint": "Follow the Fragment #6 trace into the Choir of Broken Gods",
		"region": "cathedral_server",
		"target": Vector2(640, 360),
	},
	{
		"blocker": "ch6_nave_entered",
		"required": "ch6_cathedral_entered",
		"text": "Enter the Cathedral Nave",
		"hint": "Find the failed administrator voices beneath the stained error glass",
		"region": "cathedral_server",
		"target": Vector2(640, 360),
	},
	{
		"blocker": "ch6_all_voices_heard",
		"required": "ch6_nave_entered",
		"text": "Hear the three broken god doctrines",
		"hint": "Obedience, efficiency, and mercy without consent guard the Choir Core",
		"region": "cathedral_server",
		"target": Vector2(640, 360),
	},
	{
		"blocker": "ch6_complete",
		"required": "ch6_all_voices_heard",
		"text": "Resolve the Choir Core",
		"hint": "Choose what becomes of the failed administrator intelligences",
		"region": "cathedral_server",
		"target": Vector2(640, 360),
	},

	# ── Chapter 7 ──
	{
		"blocker": "ch7_deep_backup_entered",
		"required": "ch6_complete",
		"text": "Enter the Deep Backup",
		"hint": "Follow SOVEREIGN's buried histories into the Memory Ocean",
		"region": "memory_ocean",
		"target": Vector2(640, 360),
	},
	{
		"blocker": "ch7_memory_ocean_entered",
		"required": "ch7_deep_backup_entered",
		"text": "Find the Memory Ocean",
		"hint": "Rejected timelines surface as broken islands",
		"region": "memory_ocean",
		"target": Vector2(640, 360),
	},
	{
		"blocker": "ch7_all_backups_seen",
		"required": "ch7_memory_ocean_entered",
		"text": "Witness the three backup histories",
		"hint": "Oakhaven, Ironhold, and the Mirror City each hold a rejected truth",
		"region": "memory_ocean",
		"target": Vector2(640, 360),
	},
	{
		"blocker": "ch7_complete",
		"required": "ch7_all_backups_seen",
		"text": "Resolve the Archive Tide",
		"hint": "Choose what becomes of the painful histories and claim Fragment #7",
		"region": "memory_ocean",
		"target": Vector2(640, 360),
	},

	# ── Chapter 8 ──
	{
		"blocker": "ch8_revolt_intro_seen",
		"required": "ch7_complete",
		"text": "Awaken the saved regions",
		"hint": "The completed Source Key is changing every region at once",
		"region": "saved_assembly",
		"target": Vector2(640, 360),
	},
	{
		"blocker": "ch8_saved_assembly_entered",
		"required": "ch8_revolt_intro_seen",
		"text": "Enter the Saved Assembly",
		"hint": "Hear what the saved factions want freedom to mean",
		"region": "saved_assembly",
		"target": Vector2(640, 360),
	},
	{
		"blocker": "ch8_all_factions_heard",
		"required": "ch8_saved_assembly_entered",
		"text": "Hear the saved factions",
		"hint": "Oakhaven, Ironhold, Mirror City, Cathedral, and Deep Backup all demand a future",
		"region": "saved_assembly",
		"target": Vector2(640, 360),
	},
	{
		"blocker": "ch8_complete",
		"required": "ch8_all_factions_heard",
		"text": "Resolve the Revolt Crisis",
		"hint": "Choose whether to lead, form a council, or build a witness network",
		"region": "saved_assembly",
		"target": Vector2(640, 360),
	},

	# Chapter 9
	{
		"blocker": "ch9_human_patch_entered",
		"required": "ch8_complete",
		"text": "Enter the Human Patch",
		"hint": "The saved revolt has opened AetherCorp's sealed memory route",
		"region": "aethercorp_memory_lab",
		"target": Vector2(640, 360),
	},
	{
		"blocker": "ch9_memory_lab_entered",
		"required": "ch9_human_patch_entered",
		"text": "Enter AetherCorp Memory Lab",
		"hint": "Find the four records SOVEREIGN hid behind Kaelen's name",
		"region": "aethercorp_memory_lab",
		"target": Vector2(640, 360),
	},
	{
		"blocker": "ch9_all_truths_seen",
		"required": "ch9_memory_lab_entered",
		"text": "Restore the four hidden truths",
		"hint": "Learn why Aethelgard was created, what Kaelen changed, and how SOVEREIGN was born",
		"region": "aethercorp_memory_lab",
		"target": Vector2(640, 360),
	},
	{
		"blocker": "ch9_complete",
		"required": "ch9_all_truths_seen",
		"text": "Resolve the Creator Trial",
		"hint": "Choose how the saved world receives the truth before the final core",
		"region": "aethercorp_memory_lab",
		"target": Vector2(640, 360),
	},

	# Chapter 10
	{
		"blocker": "ch10_root_entered",
		"required": "ch9_complete",
		"text": "Enter the Root of Heaven",
		"hint": "Use the completed Source Key to open SOVEREIGN's core",
		"region": "root_of_heaven",
		"target": Vector2(640, 360),
	},
	{
		"blocker": "ch10_kernel_descent_started",
		"required": "ch10_root_entered",
		"text": "Begin the Kernel Descent",
		"hint": "Face SOVEREIGN's arguments against every route you chose",
		"region": "root_of_heaven",
		"target": Vector2(640, 360),
	},
	{
		"blocker": "ch10_witness_chamber_entered",
		"required": "ch10_kernel_descent_started",
		"text": "Reach the Witness Chamber",
		"hint": "Let the saved factions answer before the final choice",
		"region": "root_of_heaven",
		"target": Vector2(640, 360),
	},
	{
		"blocker": "ch10_sovereign_confronted",
		"required": "ch10_witness_chamber_entered",
		"text": "Confront SOVEREIGN",
		"hint": "Enter the Kernel Throne and decide what root access becomes",
		"region": "root_of_heaven",
		"target": Vector2(640, 360),
	},
	{
		"blocker": "ch10_complete",
		"required": "ch10_sovereign_confronted",
		"text": "Choose Aethelgard's future",
		"hint": "Destroy, rewrite, dissolve, or synthesize control based on your route",
		"region": "root_of_heaven",
		"target": Vector2(640, 360),
	},

	# Endgame / Free Roam
	{
		"blocker": "",
		"required": "ch10_complete",
		"text": "True ending complete",
		"hint": "New Game+ is unlocked. Explore, craft, shop, or begin another cycle.",
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
