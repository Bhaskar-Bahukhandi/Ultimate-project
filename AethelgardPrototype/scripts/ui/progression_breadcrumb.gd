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
var _target_scene: String = ""  # scene path a Chapter 1 arrow is bound to ("" = any scene)
var _visible: bool = true

# ── Objective database ──
# Each entry may carry:
#   required      one flag that must be set ("" = none)
#   required_any  a list of flags, at least one of which must be set
#   blocker, blocker_alt   single flags that end the entry when set
#   blockers      a list of flags, any of which ends the entry
#   text, hint, target (a fixed Vector2; Vector2.ZERO = no arrow)
# Chapter 1 entries ("chapter1": true) have no hint and no fixed target. An arrow is
# optional: "scene" (res:// path) plus "target_node" (node path inside that scene) aim
# it at that node, and only while that scene is the current scene.
# Chapter 2+ entries: first matching entry in table order wins.
# Chapter 1 entries (until "ch1_complete" is set): the LATEST matching step wins, so a
# later beat (an early alarm, a skipped step) moves the objective forward.
const OBJECTIVES: Array = [
	# ── Chapter 1 (Y1-P0-T05; texts approved 2026-10-18, step 0 from crash_site.dlg) ──
	{  # step 0
		"chapter1": true,
		"required": "ch1_opening_hook_started",
		"blockers": ["ch1_crash_trace_seen"],
		"text": "Find the plane. Look for survivors.",
		"hint": "",
		"scene": "res://scenes/chapter1/opening_crash_site_hook.tscn",
		"target_node": "SignalFragment",
	},
	{  # step 1
		"chapter1": true,
		"required": "ch1_crash_trace_seen",
		"blockers": ["elara_met"],
		"text": "Find people. A settlement east may know what happened to Flight 707.",
		"hint": "",
		"scene": "res://scenes/chapter1/opening_crash_site_hook.tscn",
		"target_node": "OakhavenPath",
	},
	{  # step 2
		"chapter1": true,
		"required": "elara_met",
		"blockers": ["ch1_broken_mile_entered"],
		"text": "Reach Oakhaven. Follow the first lead on the missing passengers.",
		"hint": "",
	},
	{  # step 3
		"chapter1": true,
		"required": "ch1_broken_mile_entered",
		"blockers": ["ch1_personal_goal_set"],
		"text": "Get through the Broken Mile with Elara.",
		"hint": "",
	},
	{  # step 4
		"chapter1": true,
		"required": "ch1_personal_goal_set",
		"blockers": ["ch1_oakhaven_entered"],
		"text": "Ask about Flight 707. Find a safe route to Ironhold.",
		"hint": "",
	},
	{  # step 5
		"chapter1": true,
		"required": "ch1_oakhaven_entered",
		"blockers": ["ch1_stew_done"],
		"text": "Go to Elara's house. She's making stew.",
		"hint": "",
	},
	{  # step 6
		"chapter1": true,
		"required": "ch1_stew_done",
		"blockers": ["ch1_north_field_helped", "ch1_north_field_refused"],
		"text": "Spend the afternoon in Oakhaven. Meet the people here.",
		"hint": "",
	},
	{  # step 7 (never shown on the refuse path)
		"chapter1": true,
		"required": "ch1_north_field_helped",
		"blockers": ["ch1_corrupted_boar_defeated"],
		"text": "Answer the alarm in the north field.",
		"hint": "",
		"scene": "res://scenes/chapter1/oakhaven_village.tscn",
		"target_node": "Triggers/BoarTrigger",
	},
	{  # step 8
		"chapter1": true,
		"required_any": ["ch1_corrupted_boar_defeated", "ch1_north_field_refused"],
		"blockers": ["ch1_bridge_repair_accepted", "ch1_bridge_evacuated", "ch1_bridge_ignored"],
		"text": "Deal with the north bridge before dark.",
		"hint": "",
		"scene": "res://scenes/chapter1/oakhaven_village.tscn",
		"target_node": "Triggers/BridgeTrigger",
	},
	{  # step 9 (no arrow: the boss node moves and is created at runtime)
		"chapter1": true,
		"required_any": ["ch1_bridge_repair_accepted", "ch1_bridge_evacuated", "ch1_bridge_ignored"],
		"blockers": ["ch1_tutorial_knight_defeated"],
		"text": "Stop Aldric.",
		"hint": "",
	},
	{  # step 10
		"chapter1": true,
		"required": "ch1_tutorial_knight_defeated",
		"blockers": ["ch1_complete"],
		"text": "Go down to the shrine. Then decide what to tell the village.",
		"hint": "",
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
	# Same order as the Ironhold region's gates: the Clock Tower gate opens
	# after the arena's bronze bracket, and the tower unlocks the Underground
	# (ch2_underground_unlocked), whose clearing opens the Proxy gate. Targets
	# are those gates' positions in ironhold_region.gd.
	{
		"blocker": "ch2_arena_bronze_complete",
		"required": "ch2_ironhold_entered",
		"text": "Win the Arena's Bronze bracket",
		"hint": "The Clock Tower stays sealed until you've proven yourself in the Arena",
		"region": "ironhold",
		"target": Vector2(1850, 1020),
	},
	{
		"blocker": "ch2_clockwork_automaton_defeated",
		"required": "ch2_arena_bronze_complete",
		"text": "Ascend the Clock Tower",
		"hint": "The Clockwork Automaton guards the upper floors — Rec. Lv 9",
		"region": "ironhold",
		"target": Vector2(2950, 620),
	},
	{
		"blocker": "ch2_data_wraith_defeated",
		"required": "ch2_clockwork_automaton_defeated",
		"text": "Investigate the Underground Network",
		"hint": "The underground passages hide the Data Wraith — Rec. Lv 7",
		"region": "ironhold",
		"target": Vector2(1150, 1950),
	},
	{
		"blocker": "ch2_administrator_proxy_defeated",
		"required": "ch2_data_wraith_defeated",
		"text": "Defeat the Administrator Proxy",
		"hint": "Deep in the underground, a proxy of the Administrator awaits — Rec. Lv 11",
		"region": "ironhold",
		"target": Vector2(1300, 2100),
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
	_objective_panel.offset_left = -312
	_objective_panel.offset_top = 10
	_objective_panel.offset_right = -12
	_objective_panel.offset_bottom = 60
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.02, 0.02, 0.06, 0.52)
	style.border_color = Color(0.2, 0.5, 0.9, 0.32)
	style.border_width_left = 2
	style.border_width_top = 0
	style.border_width_right = 0
	style.border_width_bottom = 0
	style.set_corner_radius_all(3)
	style.content_margin_left = 8
	style.content_margin_right = 8
	style.content_margin_top = 3
	style.content_margin_bottom = 3
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
	_objective_label.add_theme_font_size_override("normal_font_size", 11)
	_objective_label.add_theme_font_size_override("italics_font_size", 10)
	_objective_label.custom_minimum_size = Vector2(268, 24)
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

	var flags := {}
	for flag_name in GameManager.story_flags:
		if GameManager.get_story_flag(flag_name):
			flags[flag_name] = true
	var res := resolve_objective(flags)

	_has_target = false
	_target_scene = ""
	if res["has_target"]:
		_target_position = res["target"]
		_has_target = true
	elif res["scene"] != "" and res["target_node"] != "":
		_cache_scene_target(res["scene"], res["target_node"])

	var new_obj: String = res["text"]
	if new_obj != _current_objective:
		_current_objective = new_obj
		_current_hint = res["hint"]
		_update_display()
		objective_changed.emit(new_obj)


## Pure resolver: which objective applies for a given set of story flags.
## `flags` maps flag name -> bool; a missing key counts as false. Touches no
## game state, so tests can call it directly.
## Until "ch1_complete" is set, the Chapter 1 entries are tried from the last step
## to the first and the first match wins (latest step wins); once it is set they
## are skipped. Every other entry resolves first-match-wins in table order.
## Returns {"text", "hint", "scene", "target_node", "target": Vector2,
## "has_target": bool}. `text` is "" when nothing applies. `has_target` and
## `target` are the entry's fixed `target` (Chapter 2+). A Chapter 1 arrow is
## described by `scene` + `target_node` instead (has_target stays false); the
## node position is looked up by _refresh_objective().
func resolve_objective(flags: Dictionary) -> Dictionary:
	var found := {}
	if not flags.get("ch1_complete", false):
		for i in range(OBJECTIVES.size() - 1, -1, -1):
			var entry: Dictionary = OBJECTIVES[i]
			if entry.get("chapter1", false) and _entry_active(entry, flags):
				found = entry
				break
	if found.is_empty():
		for entry: Dictionary in OBJECTIVES:
			if entry.get("chapter1", false):
				continue
			if _entry_active(entry, flags):
				found = entry
				break
	var result := {
		"text": "", "hint": "", "scene": "", "target_node": "",
		"target": Vector2.ZERO, "has_target": false,
	}
	if found.is_empty():
		return result
	result["text"] = found["text"]
	result["hint"] = found.get("hint", "")
	result["scene"] = found.get("scene", "")
	result["target_node"] = found.get("target_node", "")
	var target: Vector2 = found.get("target", Vector2.ZERO)
	if target != Vector2.ZERO:
		result["target"] = target
		result["has_target"] = true
	return result


## True when `entry` applies to `flags`: no blocker flag set, `required` set (if
## given) and at least one `required_any` flag set (if given).
func _entry_active(entry: Dictionary, flags: Dictionary) -> bool:
	var single_blocker: String = entry.get("blocker", "")
	if single_blocker != "" and flags.get(single_blocker, false):
		return false
	var alt_blocker: String = entry.get("blocker_alt", "")
	if alt_blocker != "" and flags.get(alt_blocker, false):
		return false
	for blocker_flag: String in entry.get("blockers", []):
		if flags.get(blocker_flag, false):
			return false
	var required: String = entry.get("required", "")
	if required != "" and not flags.get(required, false):
		return false
	var required_any: Array = entry.get("required_any", [])
	if not required_any.is_empty():
		var any_set := false
		for required_flag: String in required_any:
			if flags.get(required_flag, false):
				any_set = true
				break
		if not any_set:
			return false
	return true


## Caches the arrow target for a scene-bound entry: only when `scene_path` is the
## current scene and `node_path` exists in it. _process() compares the cached
## scene path, so there is no per-frame node lookup.
func _cache_scene_target(scene_path: String, node_path: String) -> void:
	var tree := get_tree()
	if tree == null or tree.current_scene == null:
		return
	var current := tree.current_scene
	if current.scene_file_path != scene_path:
		return
	var node := current.get_node_or_null(NodePath(node_path))
	if node is Node2D or node is Control:
		_target_position = node.global_position
		_target_scene = scene_path
		_has_target = true


func _update_display() -> void:
	if not _objective_label:
		return

	if _current_objective.is_empty():
		_objective_panel.visible = false
		return

	_objective_panel.visible = true
	if _current_hint.is_empty():
		_objective_label.text = "[color=#4488CC][b]►[/b][/color] [color=#CCDDEE]%s[/color]" % _current_objective
	else:
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

	# A scene-bound target (Chapter 1) only shows while its scene is still current.
	if _target_scene != "":
		var current := get_tree().current_scene if is_inside_tree() else null
		if current == null or current.scene_file_path != _target_scene:
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
	# Map angle to 8-directional arrow. Screen y points down, so a positive
	# angle is below the player. (The old table showed ↗ for straight up and ↑
	# for up-right, and had no ↙/↖.)
	var arrows := ["→", "↘", "↓", "↙", "←", "↖", "↑", "↗"]
	return arrows[posmod(roundi(angle / (PI / 4.0)), 8)]


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

## The text currently rendered in the objective label ("" before the HUD is built
## or while no objective has been shown).
func get_objective_label_text() -> String:
	return _objective_label.text if _objective_label else ""

## Cached arrow target position (valid when has_arrow_target() is true).
func get_arrow_target() -> Vector2:
	return _target_position

## True when the current objective has a cached arrow target.
func has_arrow_target() -> bool:
	return _has_target

## Scene path the cached arrow target is bound to ("" for Chapter 2+ fixed targets).
func get_arrow_scene() -> String:
	return _target_scene

## Text of the on-screen arrow ("" when hidden). Updated by _process().
func get_arrow_text() -> String:
	return _arrow_indicator.text if _arrow_indicator else ""
