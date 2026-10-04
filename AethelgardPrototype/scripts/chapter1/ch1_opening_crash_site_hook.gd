extends Node2D

## The opening hook replaces the flight/crash/crater cinematics; Chapter 1 then
## continues with the Elara meeting → path to Oakhaven → village → region →
## overworld. Going straight to the overworld skipped Elara and the scenes that
## unlock Data Vision and Root Access.
const NEXT_SCENE := "res://scenes/chapter1/elara_meeting.tscn"
const PLAYER_SCENE := preload("res://scenes/player/player_topdown.tscn")
const START_POS := Vector2(250, 420)
const SIGNAL_POS := Vector2(545, 370)
const PULSE_POS := Vector2(740, 370)
const EXIT_POS := Vector2(1030, 370)
const MAP_SIZE := Vector2(1280, 720)
const SIGNAL_INTERACTION_RANGE := 150.0
const EXIT_INTERACTION_RANGE := 135.0
const PULSE_TRIGGER_RANGE := 72.0

var _player: CharacterBody2D = null
var _objective_label: Label = null
var _message_label: Label = null
var _prompt_label: Label = null
var _pulse_area: Area2D = null
var _pulse_visual: ColorRect = null
var _route_ping: ColorRect = null
var _signal_glow: ColorRect = null
var _signal_visual: ColorRect = null
var _signal_prompt_label: Label = null
var _signal_success_label: Label = null
var _path_marker: ColorRect = null
var _path_direction_label: Label = null
var _static_flash: ColorRect = null
var _signal_found := false
var _exit_started := false
var _breadcrumb_suppressed := false
var _last_pulse_knockback_delta := Vector2.ZERO
var _last_pulse_feedback_triggered := false
var _pulse_triggered := false


func _ready() -> void:
	print("[10N-A2] Opening crash-site hook loaded")
	if has_node("/root/GameManager"):
		GameManager.current_chapter = 1
		GameManager.current_region = "opening_crash_site"
		GameManager.change_state(GameManager.GameState.EXPLORATION)
		GameManager.set_story_flag("ch1_opening_hook_started", true)

	_build_environment()
	_create_route_boundaries()
	_spawn_player()
	_create_signal_fragment()
	_create_glitch_pulse()
	_create_oakhaven_exit()
	_create_hud()
	_suppress_global_breadcrumb()
	_update_objective("Stand up. Find a signal.", "Move with {move}. Press {interact} or {root_access} at the signal fragment.")
	_show_message("Your hands work before your memory does. Move.", 4.0)


func _process(_delta: float) -> void:
	_sync_opening_interaction_prompt()
	_sync_world_prompt_visibility()
	_check_hook_local_proximity_triggers()


func _input(event: InputEvent) -> void:
	if _exit_started or not _player:
		return
	if not (event.is_action_pressed("interact") or event.is_action_pressed("root_access")):
		return
	if not _signal_found and _player.global_position.distance_to(SIGNAL_POS) <= SIGNAL_INTERACTION_RANGE:
		_on_signalfragment_interaction(_player)
		get_viewport().set_input_as_handled()
		return
	if _signal_found and _player.global_position.distance_to(EXIT_POS) <= EXIT_INTERACTION_RANGE:
		_complete_opening_hook()
		get_viewport().set_input_as_handled()
		return


func _build_environment() -> void:
	_add_rect("Ground", Vector2.ZERO, MAP_SIZE, Color(0.045, 0.05, 0.07))
	_add_rect("CraterFloor", Vector2(150, 300), Vector2(760, 230), Color(0.075, 0.06, 0.095))
	_add_rect("CraterRimNorth", Vector2(90, 270), Vector2(880, 36), Color(0.12, 0.08, 0.12))
	_add_rect("CraterRimSouth", Vector2(110, 520), Vector2(860, 32), Color(0.11, 0.075, 0.11))
	_add_rect("CrashDebrisA", Vector2(340, 330), Vector2(90, 18), Color(0.23, 0.22, 0.26))
	_add_rect("CrashDebrisB", Vector2(430, 455), Vector2(120, 16), Color(0.18, 0.2, 0.24))
	_add_rect("BrokenRoad", Vector2(620, 348), Vector2(430, 44), Color(0.16, 0.145, 0.13))
	_add_rect("SafeGap", Vector2(805, 338), Vector2(52, 64), Color(0.23, 0.22, 0.18))
	for i in range(8):
		var chip := _add_rect("MemoryChip%d" % i, Vector2(190 + i * 76, 292 + ((i % 2) * 210)), Vector2(26, 6), Color(0.25, 0.85, 0.95, 0.28))
		chip.rotation = -0.25 + float(i % 3) * 0.22
	_add_world_label("OAKHAVEN SIGNAL", EXIT_POS + Vector2(-62, -58), 12, Color(0.72, 0.95, 0.82))
	_add_world_label("CRASH MEMORY SCAR", Vector2(365, 285), 11, Color(0.72, 0.62, 0.82))


func _create_route_boundaries() -> void:
	_add_blocker("OpeningBoundaryWestRubble", Vector2(105, 415), Vector2(88, 270), Color(0.16, 0.13, 0.15, 0.9))
	_add_blocker("OpeningBoundaryNorthCrater", Vector2(430, 276), Vector2(850, 34), Color(0.15, 0.09, 0.13, 0.92))
	_add_blocker("OpeningBoundarySouthCrater", Vector2(430, 548), Vector2(850, 36), Color(0.13, 0.085, 0.12, 0.92))
	_add_blocker("OpeningBoundaryNorthRoad", Vector2(848, 308), Vector2(420, 28), Color(0.14, 0.105, 0.105, 0.9))
	_add_blocker("OpeningBoundarySouthRoad", Vector2(848, 440), Vector2(420, 28), Color(0.14, 0.105, 0.105, 0.9))
	_add_blocker("OpeningBoundaryExitGuardNorth", Vector2(1125, 292), Vector2(150, 56), Color(0.11, 0.16, 0.13, 0.9))
	_add_blocker("OpeningBoundaryExitGuardSouth", Vector2(1125, 468), Vector2(150, 56), Color(0.11, 0.16, 0.13, 0.9))


func _add_blocker(name: String, center: Vector2, size: Vector2, color: Color) -> StaticBody2D:
	var body := StaticBody2D.new()
	body.name = name
	body.position = center
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = size
	shape.shape = rect
	body.add_child(shape)
	add_child(body)
	var visual := _add_rect("%sVisual" % name, center - (size * 0.5), size, color)
	visual.z_index = 1
	return body


func _add_rect(name: String, pos: Vector2, size: Vector2, color: Color) -> ColorRect:
	var rect := ColorRect.new()
	rect.name = name
	rect.position = pos
	rect.size = size
	rect.color = color
	add_child(rect)
	return rect


func _add_world_label(text: String, pos: Vector2, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.position = pos
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.85))
	label.add_theme_constant_override("shadow_offset_x", 1)
	label.add_theme_constant_override("shadow_offset_y", 1)
	add_child(label)
	return label


func _spawn_player() -> void:
	_player = PLAYER_SCENE.instantiate() as CharacterBody2D
	_player.name = "Player"
	_player.global_position = START_POS
	add_child(_player)
	var camera := _player.get_node_or_null("Camera2D") as Camera2D
	if camera:
		camera.name = "OpeningCamera"
		camera.zoom = Vector2(1.65, 1.65)
		camera.position_smoothing_enabled = true
		camera.position_smoothing_speed = 7.0
		camera.limit_left = 0
		camera.limit_top = 0
		camera.limit_right = int(MAP_SIZE.x)
		camera.limit_bottom = int(MAP_SIZE.y)
		camera.make_current()


func _create_signal_fragment() -> void:
	var area := Area2D.new()
	area.name = "SignalFragment"
	area.global_position = SIGNAL_POS
	area.add_to_group("interactable")
	area.set_meta("display_name", "Broken Signal Fragment")
	area.set_meta("interaction_type", "item")
	area.set_meta("opening_prompt_text", "[F/E] Interact")
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 110.0
	shape.shape = circle
	area.add_child(shape)
	var glow := ColorRect.new()
	glow.name = "SignalReadabilityGlow"
	glow.position = Vector2(-42, -42)
	glow.size = Vector2(84, 84)
	glow.color = Color(0.05, 0.95, 1.0, 0.24)
	area.add_child(glow)
	_signal_glow = glow
	var visual := ColorRect.new()
	visual.name = "SignalVisual"
	visual.position = Vector2(-22, -22)
	visual.size = Vector2(44, 44)
	visual.color = Color(0.08, 0.9, 1.0, 0.86)
	area.add_child(visual)
	_signal_visual = visual
	var marker := _add_world_label("SIGNAL", SIGNAL_POS + Vector2(-28, -58), 12, Color(0.88, 1.0, 1.0))
	marker.name = "SignalImportanceMarker"
	_signal_prompt_label = _add_world_label("[F/E] interact", SIGNAL_POS + Vector2(-42, 42), 11, Color(0.86, 0.95, 1.0))
	_signal_prompt_label.name = "SignalInteractPrompt"
	_signal_prompt_label.visible = false
	_signal_success_label = _add_world_label("CONNECTED", SIGNAL_POS + Vector2(-48, 42), 11, Color(0.62, 1.0, 0.72))
	_signal_success_label.name = "SignalConnectedMarker"
	_signal_success_label.visible = false
	add_child(area)
	var tween := create_tween().set_loops()
	tween.tween_property(glow, "modulate:a", 0.35, 0.45)
	tween.tween_property(glow, "modulate:a", 1.0, 0.45)


func _create_glitch_pulse() -> void:
	_pulse_area = Area2D.new()
	_pulse_area.name = "GlitchPulse"
	_pulse_area.global_position = PULSE_POS
	_pulse_area.visible = false
	_pulse_area.monitoring = false
	var shape := CollisionShape2D.new()
	var rect_shape := RectangleShape2D.new()
	rect_shape.size = Vector2(86, 110)
	shape.shape = rect_shape
	_pulse_area.add_child(shape)
	_pulse_visual = ColorRect.new()
	_pulse_visual.name = "PulseVisual"
	_pulse_visual.position = Vector2(-43, -55)
	_pulse_visual.size = Vector2(86, 110)
	_pulse_visual.color = Color(0.9, 0.1, 0.8, 0.36)
	_pulse_area.add_child(_pulse_visual)
	_pulse_area.body_entered.connect(_on_glitch_pulse_body_entered)
	add_child(_pulse_area)


func _create_oakhaven_exit() -> void:
	var area := Area2D.new()
	area.name = "OakhavenPath"
	area.global_position = EXIT_POS
	area.add_to_group("interactable")
	area.set_meta("display_name", "Oakhaven Signal Road")
	area.set_meta("opening_prompt_text", "[F/E] Follow signal")
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(120, 120)
	shape.shape = rect
	area.add_child(shape)
	var marker := ColorRect.new()
	marker.name = "PathMarker"
	marker.position = Vector2(-40, -42)
	marker.size = Vector2(80, 84)
	marker.color = Color(0.2, 0.55, 0.32, 0.28)
	area.add_child(marker)
	_path_marker = marker
	var arrow := ColorRect.new()
	arrow.name = "EastSignalArrow"
	arrow.position = Vector2(-96, -8)
	arrow.size = Vector2(92, 16)
	arrow.color = Color(0.2, 0.95, 0.62, 0.55)
	area.add_child(arrow)
	var label := _add_world_label("EAST TO OAKHAVEN", EXIT_POS + Vector2(-112, 50), 12, Color(0.82, 1.0, 0.86))
	label.name = "OakhavenPathDirectionLabel"
	label.visible = false
	_path_direction_label = label
	area.body_entered.connect(_on_oakhaven_path_body_entered)
	add_child(area)


func _create_hud() -> void:
	var layer := CanvasLayer.new()
	layer.name = "OpeningHookHUD"
	layer.layer = 95
	add_child(layer)

	var panel := PanelContainer.new()
	panel.name = "FirstMinuteObjectivePanel"
	panel.set_anchors_preset(Control.PRESET_TOP_LEFT)
	panel.offset_left = 14
	panel.offset_top = 14
	panel.offset_right = 480
	panel.offset_bottom = 94
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.02, 0.025, 0.04, 0.82)
	style.border_color = Color(0.3, 0.85, 0.9, 0.6)
	style.border_width_left = 2
	style.content_margin_left = 10
	style.content_margin_right = 10
	style.content_margin_top = 8
	style.content_margin_bottom = 8
	panel.add_theme_stylebox_override("panel", style)
	layer.add_child(panel)

	var box := VBoxContainer.new()
	panel.add_child(box)
	_objective_label = Label.new()
	_objective_label.name = "ObjectiveLabel"
	_objective_label.add_theme_font_size_override("font_size", 16)
	_objective_label.add_theme_color_override("font_color", Color(0.86, 0.95, 1.0))
	box.add_child(_objective_label)
	_prompt_label = Label.new()
	_prompt_label.name = "PromptLabel"
	_prompt_label.add_theme_font_size_override("font_size", 12)
	_prompt_label.add_theme_color_override("font_color", Color(0.66, 0.72, 0.78))
	box.add_child(_prompt_label)

	_message_label = Label.new()
	_message_label.name = "OpeningMessageLabel"
	_message_label.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	_message_label.offset_left = 18
	_message_label.offset_top = -92
	_message_label.offset_right = 860
	_message_label.offset_bottom = -22
	_message_label.add_theme_font_size_override("font_size", 18)
	_message_label.add_theme_color_override("font_color", Color(0.92, 0.96, 1.0))
	_message_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.9))
	_message_label.add_theme_constant_override("shadow_offset_x", 2)
	_message_label.add_theme_constant_override("shadow_offset_y", 2)
	layer.add_child(_message_label)

	_static_flash = ColorRect.new()
	_static_flash.name = "GlitchPulseFeedbackFlash"
	_static_flash.set_anchors_preset(Control.PRESET_FULL_RECT)
	_static_flash.color = Color(0.95, 0.12, 0.85, 0.0)
	_static_flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(_static_flash)


func _update_objective(main_text: String, prompt_text: String) -> void:
	if _objective_label:
		_objective_label.text = "OBJECTIVE: %s" % main_text
	if _prompt_label:
		InputService.bind_text(_prompt_label, prompt_text)


func _sync_opening_interaction_prompt() -> void:
	if not _player:
		return
	var player_prompt := _player.get_node_or_null("InteractionPrompt") as Label
	if not player_prompt:
		return
	var prompt_text := ""
	if not _signal_found and _player.global_position.distance_to(SIGNAL_POS) <= SIGNAL_INTERACTION_RANGE:
		prompt_text = "[F/E] Interact"
	elif _signal_found and _player.global_position.distance_to(EXIT_POS) <= EXIT_INTERACTION_RANGE:
		prompt_text = "[F/E] Follow signal"
	else:
		var nearby: Variant = _player.get("nearby_interactable")
		if nearby is Node and nearby.has_meta("opening_prompt_text"):
			prompt_text = str(nearby.get_meta("opening_prompt_text"))
	if prompt_text != "":
		player_prompt.text = prompt_text
		player_prompt.visible = true
	elif not _player.get("nearby_interactable"):
		player_prompt.visible = false


func _sync_world_prompt_visibility() -> void:
	if not _player:
		return
	if _signal_prompt_label:
		_signal_prompt_label.visible = not _signal_found and _player.global_position.distance_to(SIGNAL_POS) <= SIGNAL_INTERACTION_RANGE
	if _signal_success_label:
		_signal_success_label.visible = _signal_found
	if _path_direction_label:
		_path_direction_label.visible = _signal_found
	if _path_marker:
		_path_marker.color = Color(0.2, 0.75, 0.42, 0.72 if _signal_found else 0.28)


func _check_hook_local_proximity_triggers() -> void:
	if not _player or _exit_started:
		return
	if _signal_found and not _pulse_triggered and _pulse_area and _pulse_area.visible:
		if _player.global_position.distance_to(PULSE_POS) <= PULSE_TRIGGER_RANGE:
			_on_glitch_pulse_body_entered(_player)
	if _signal_found and _player.global_position.distance_to(EXIT_POS) <= EXIT_INTERACTION_RANGE * 0.65:
		_complete_opening_hook()


func _show_message(text: String, seconds: float = 3.5) -> void:
	if not _message_label:
		return
	_message_label.text = text
	_message_label.modulate.a = 1.0
	var tween := create_tween()
	tween.tween_interval(seconds)
	tween.tween_property(_message_label, "modulate:a", 0.0, 0.35)


func _on_signalfragment_interaction(_actor: Node) -> void:
	if _signal_found:
		_show_message("The signal is already locked east. Move before the crater pulses again.", 3.5)
		return
	_signal_found = true
	if _signal_visual:
		_signal_visual.color = Color(0.36, 1.0, 0.62, 0.95)
	if _signal_glow:
		_signal_glow.color = Color(0.16, 1.0, 0.42, 0.42)
	if _signal_prompt_label:
		_signal_prompt_label.visible = false
	if _signal_success_label:
		_signal_success_label.visible = true
	if has_node("/root/GameManager"):
		GameManager.set_story_flag("ch1_opening_hook_signal_found", true)
	_update_objective("Follow the Oakhaven signal.", "Avoid the pulse. Follow the east marker to Oakhaven.")
	_show_message("Recovered signal: Oakhaven death record looped 412 times. Elara marker still alive.", 5.0)
	_arm_glitch_pulse()
	_draw_route_ping()


func _arm_glitch_pulse() -> void:
	if not _pulse_area or not _pulse_visual:
		return
	_pulse_area.visible = true
	_pulse_area.monitoring = true
	var tween := create_tween().set_loops()
	tween.tween_property(_pulse_visual, "modulate:a", 0.25, 0.28)
	tween.tween_property(_pulse_visual, "modulate:a", 1.0, 0.18)
	_show_message("Danger: the memory scar is pulsing. Step around it.", 3.2)


func _draw_route_ping() -> void:
	_route_ping = _add_rect("DataVisionPingRoute", SIGNAL_POS + Vector2(30, -8), Vector2(430, 14), Color(0.1, 0.95, 0.78, 0.44))
	_route_ping.z_index = 5
	var tween := create_tween().set_loops(4)
	tween.tween_property(_route_ping, "modulate:a", 0.25, 0.35)
	tween.tween_property(_route_ping, "modulate:a", 1.0, 0.25)


func _on_glitch_pulse_body_entered(body: Node2D) -> void:
	if body != _player or _pulse_triggered:
		return
	_pulse_triggered = true
	if has_node("/root/GameManager"):
		GameManager.set_story_flag("ch1_opening_hook_danger_seen", true)
	_apply_glitch_pulse_feedback()
	_show_message("Glitch pulse shoved you back. Route east before it cycles again.", 3.5)
	_shake_camera()


func _apply_glitch_pulse_feedback() -> void:
	if not _player:
		return
	_last_pulse_feedback_triggered = true
	_last_pulse_knockback_delta = Vector2(-58, 0)
	_player.global_position += _last_pulse_knockback_delta
	_player.velocity = Vector2.ZERO
	if _static_flash:
		_static_flash.color = Color(0.95, 0.12, 0.85, 0.32)
		var tween := create_tween()
		tween.tween_property(_static_flash, "color:a", 0.0, 0.22)


func _shake_camera() -> void:
	if not _player:
		return
	var camera := _player.get_node_or_null("OpeningCamera") as Camera2D
	if not camera:
		return
	var original_offset := camera.offset
	var tween := create_tween()
	tween.tween_property(camera, "offset", Vector2(8, -5), 0.05)
	tween.tween_property(camera, "offset", Vector2(-5, 6), 0.05)
	tween.tween_property(camera, "offset", original_offset, 0.08)


func _on_oakhaven_path_body_entered(body: Node2D) -> void:
	if body == _player and _signal_found:
		_complete_opening_hook()
	elif body == _player:
		_show_message("The road is static until you inspect the signal fragment.", 3.0)


func _on_oakhavenpath_interaction(_actor: Node) -> void:
	if _signal_found:
		_complete_opening_hook()
	else:
		_show_message("The road is static until you inspect the signal fragment.", 3.0)


func _complete_opening_hook() -> void:
	if _exit_started:
		return
	_exit_started = true
	if has_node("/root/GameManager"):
		GameManager.set_story_flag("plane_crash_completed", true)
		GameManager.set_story_flag("ch1_awakening_complete", true)
		GameManager.set_story_flag("ch1_glitch_crater_complete", true)
		GameManager.set_story_flag("ch1_opening_hook_complete", true)
		GameManager.current_chapter = 1
		GameManager.current_region = ""
		GameManager.player_overworld_position = Vector2(350, 500)
		GameManager.change_state(GameManager.GameState.EXPLORATION)
	_restore_global_breadcrumb()
	_refresh_global_breadcrumb()
	_show_message("The signal points to Oakhaven. Someone there already knows your name.", 2.0)
	await get_tree().create_timer(0.45).timeout
	if not is_inside_tree():
		return
	if has_node("/root/SceneTransitions"):
		SceneTransitions.change_scene(NEXT_SCENE)
	else:
		get_tree().change_scene_to_file(NEXT_SCENE)


func _refresh_global_breadcrumb() -> void:
	if has_node("/root/ProgressionBreadcrumb"):
		ProgressionBreadcrumb.force_refresh()


func _suppress_global_breadcrumb() -> void:
	if has_node("/root/ProgressionBreadcrumb"):
		ProgressionBreadcrumb.hide_breadcrumb()
		_breadcrumb_suppressed = true


func _restore_global_breadcrumb() -> void:
	if _breadcrumb_suppressed and has_node("/root/ProgressionBreadcrumb"):
		ProgressionBreadcrumb.show_breadcrumb()
		_breadcrumb_suppressed = false


func _exit_tree() -> void:
	_restore_global_breadcrumb()
