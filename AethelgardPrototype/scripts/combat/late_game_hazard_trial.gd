extends Node2D

## Late-game real-time trial controller.
## This keeps the Phase 10H encounters small, but separates each chapter into
## its own mode so they do not all feel like the same hazard room.

const PLAYER_SCRIPT := preload("res://scripts/combat/player_combat.gd")

@export var trial_id: String = "choir_core"
@export var trial_title: String = "LATE GAME TRIAL"
@export var trial_subtitle: String = "Survive the pattern."
@export var completion_flag: String = ""
@export var next_scene: String = ""
@export var chapter: int = 10
@export var region: String = "root_of_heaven"
@export var xp_reward: int = 250
@export var gold_reward: int = 120
@export var reward_item: String = ""
@export var reward_quantity: int = 0

var player: CharacterBody2D
var visuals_layer: Node2D
var hazards_layer: Node2D
var status_label: Label
var phase_label: Label
var attempt_label: Label
var fade_rect: ColorRect

var _retry_requested: bool = false
var _attempts: int = 0
var _completed: bool = false
var _transition_started: bool = false
var _active_markers: Array[Node] = []
var _player_spawn := Vector2(180, 552)


func _ready() -> void:
	print("[LATE-TRIAL] Initializing %s" % trial_id)
	_configure_spawn()
	GameManager.change_state(GameManager.GameState.COMBAT)
	GameManager.current_chapter = chapter
	GameManager.current_region = region
	_build_arena()
	GameManager.save_game(GameManager.AUTOSAVE_SLOT)

	if _is_already_complete():
		call_deferred("_skip_completed_trial")
	else:
		call_deferred("_start_trial")


func _exit_tree() -> void:
	_clear_hazards()
	Engine.time_scale = 1.0


func get_validation_summary() -> Dictionary:
	return {
		"trial_id": trial_id,
		"mode": _mode_label(),
		"arena_identity": _arena_identity(),
		"completion_flag": completion_flag,
		"next_scene": next_scene,
		"patterns": _get_patterns(),
		"route_context": _route_context(),
		"reward": {
			"xp": xp_reward,
			"gold": gold_reward,
			"item": reward_item,
			"quantity": reward_quantity
		}
	}


func _configure_spawn() -> void:
	match trial_id:
		"archive_tide":
			_player_spawn = Vector2(165, 552)
		"sovereign_final":
			_player_spawn = Vector2(640, 552)
		_:
			_player_spawn = Vector2(180, 552)


func _build_arena() -> void:
	var bg := ColorRect.new()
	bg.name = "Background"
	bg.color = _theme_color().darkened(0.72)
	bg.position = Vector2.ZERO
	bg.size = Vector2(1280, 720)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)

	visuals_layer = Node2D.new()
	visuals_layer.name = "ArenaIdentity"
	add_child(visuals_layer)

	_add_platform(Rect2(Vector2(0, 596), Vector2(1280, 124)), "Ground", Color(0.18, 0.18, 0.22))
	match trial_id:
		"choir_core":
			_build_choir_arena()
		"archive_tide":
			_build_archive_arena()
		"sovereign_final":
			_build_sovereign_arena()
		_:
			_add_visual_rect(Rect2(Vector2(500, 140), Vector2(280, 360)), "TrainingPulse", Color(0.4, 0.6, 1.0, 0.12))

	hazards_layer = Node2D.new()
	hazards_layer.name = "Hazards"
	add_child(hazards_layer)
	_build_player()
	_build_ui()


func _build_choir_arena() -> void:
	_add_platform(Rect2(Vector2(310, 452), Vector2(160, 18)), "LeftChoirAppealStep", Color(0.20, 0.29, 0.40))
	_add_platform(Rect2(Vector2(810, 452), Vector2(160, 18)), "RightChoirConsentStep", Color(0.20, 0.29, 0.40))
	_add_visual_rect(Rect2(Vector2(290, 382), Vector2(200, 118)), "AppealGateVisual", Color(0.30, 0.68, 1.0, 0.14))
	_add_visual_rect(Rect2(Vector2(790, 382), Vector2(200, 118)), "ConsentGateVisual", Color(0.58, 0.88, 1.0, 0.14))
	_add_visual_rect(Rect2(Vector2(585, 118), Vector2(110, 478)), "CoreFirewallVisual", Color(0.92, 0.96, 1.0, 0.07))
	_add_scene_label("OBEDIENCE", Vector2(318, 356), Color(0.72, 0.88, 1.0), 14)
	_add_scene_label("CONSENT GATE", Vector2(800, 356), Color(0.80, 0.96, 1.0), 14)
	_add_scene_label("FIREWALL CORE", Vector2(570, 96), Color(0.96, 0.98, 1.0), 15)
	for i in range(5):
		_add_visual_rect(Rect2(Vector2(160 + i * 210, 180), Vector2(90, 12)), "ChoirLaw%d" % i, Color(0.82, 0.90, 1.0, 0.12))


func _build_archive_arena() -> void:
	_add_platform(Rect2(Vector2(185, 492), Vector2(180, 18)), "LeftMemoryIsland", Color(0.12, 0.30, 0.42))
	_add_platform(Rect2(Vector2(550, 418), Vector2(180, 18)), "MidMemoryIsland", Color(0.12, 0.30, 0.42))
	_add_platform(Rect2(Vector2(915, 492), Vector2(180, 18)), "RightMemoryIsland", Color(0.12, 0.30, 0.42))
	_add_visual_rect(Rect2(Vector2(0, 542), Vector2(1280, 54)), "PassiveMemoryTide", Color(0.20, 0.72, 1.0, 0.14))
	_add_scene_label("MEMORY TIDE", Vector2(32, 512), Color(0.48, 0.90, 1.0), 15)
	_add_scene_label("STABLE ISLAND", Vector2(560, 390), Color(0.72, 1.0, 0.92), 14)
	for i in range(6):
		_add_visual_rect(Rect2(Vector2(115 + i * 180, 155 + (i % 2) * 56), Vector2(112, 22)), "BrokenTimeline%d" % i, Color(0.48, 0.84, 1.0, 0.11))


func _build_sovereign_arena() -> void:
	_add_platform(Rect2(Vector2(245, 472), Vector2(150, 18)), "LeftWitnessLedge", Color(0.35, 0.20, 0.32))
	_add_platform(Rect2(Vector2(885, 472), Vector2(150, 18)), "RightWitnessLedge", Color(0.35, 0.20, 0.32))
	_add_visual_rect(Rect2(Vector2(590, 96), Vector2(100, 500)), "RootColumnVisual", Color(1.0, 0.45, 0.76, 0.11))
	_add_visual_rect(Rect2(Vector2(375, 332), Vector2(530, 240)), "JudgementCoreVisual", Color(1.0, 0.62, 0.90, 0.07))
	_add_scene_label("ROOT DECREE", Vector2(576, 74), Color(1.0, 0.72, 0.92), 15)
	_add_scene_label("WITNESS RELAY", Vector2(546, 308), Color(1.0, 0.86, 0.98), 14)
	for i in range(8):
		var x := 65 + (i % 4) * 325
		var y := 150 + int(i / 4) * 180
		_add_visual_rect(Rect2(Vector2(x, y), Vector2(78, 126)), "WitnessRoute%d" % i, Color(0.95, 0.90, 1.0, 0.10))


func _build_player() -> void:
	player = CharacterBody2D.new()
	player.name = "Player"
	player.add_to_group("player")
	player.position = _player_spawn
	player.set_meta("local_boss_retry_enabled", true)
	player.set_script(PLAYER_SCRIPT)

	var sprite := Sprite2D.new()
	sprite.name = "Sprite"
	sprite.centered = true
	sprite.texture = _make_player_texture(_theme_color().lightened(0.28))
	player.add_child(sprite)

	var collision := CollisionShape2D.new()
	collision.name = "CollisionShape2D"
	var shape := RectangleShape2D.new()
	shape.size = Vector2(32, 48)
	collision.shape = shape
	player.add_child(collision)

	var camera := Camera2D.new()
	camera.name = "Camera2D"
	camera.position_smoothing_enabled = true
	camera.limit_left = 0
	camera.limit_right = 1280
	camera.limit_top = 0
	camera.limit_bottom = 720
	player.add_child(camera)
	add_child(player)
	camera.make_current()

	if player.has_signal("died"):
		player.died.connect(_on_player_died)


func _make_player_texture(color: Color) -> ImageTexture:
	var image := Image.create(32, 48, false, Image.FORMAT_RGBA8)
	image.fill(Color(0, 0, 0, 0))
	image.fill_rect(Rect2i(Vector2i(5, 4), Vector2i(22, 40)), color)
	image.fill_rect(Rect2i(Vector2i(10, 0), Vector2i(12, 8)), Color(0.90, 0.95, 1.0, 1.0))
	return ImageTexture.create_from_image(image)


func _build_ui() -> void:
	var layer := CanvasLayer.new()
	layer.name = "TrialUI"
	add_child(layer)

	var panel := PanelContainer.new()
	panel.name = "InfoPanel"
	panel.set_anchors_preset(Control.PRESET_TOP_WIDE)
	panel.offset_left = 22
	panel.offset_right = -22
	panel.offset_top = 18
	panel.offset_bottom = 116
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.03, 0.035, 0.045, 0.90)
	style.border_color = _theme_color().lightened(0.25)
	style.set_border_width_all(2)
	style.set_corner_radius_all(6)
	style.set_content_margin_all(12)
	panel.add_theme_stylebox_override("panel", style)
	layer.add_child(panel)

	var box := VBoxContainer.new()
	panel.add_child(box)

	var title := Label.new()
	title.text = trial_title
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 22)
	title.add_theme_color_override("font_color", Color(0.94, 0.97, 1.0))
	box.add_child(title)

	phase_label = Label.new()
	phase_label.text = trial_subtitle
	phase_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	phase_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	phase_label.add_theme_font_size_override("font_size", 13)
	phase_label.add_theme_color_override("font_color", Color(0.78, 0.86, 0.96))
	box.add_child(phase_label)

	status_label = Label.new()
	status_label.text = _mode_hint()
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	status_label.add_theme_font_size_override("font_size", 13)
	status_label.add_theme_color_override("font_color", Color(1.0, 0.90, 0.62))
	box.add_child(status_label)

	attempt_label = Label.new()
	attempt_label.text = "Attempts: 0"
	attempt_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	attempt_label.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	attempt_label.offset_left = -220
	attempt_label.offset_top = 122
	attempt_label.offset_right = -24
	attempt_label.offset_bottom = 150
	attempt_label.add_theme_color_override("font_color", Color(0.90, 0.92, 1.0))
	layer.add_child(attempt_label)

	fade_rect = ColorRect.new()
	fade_rect.name = "Fade"
	fade_rect.color = Color.BLACK
	fade_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	fade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fade_rect.z_index = 100
	fade_rect.modulate.a = 0.0
	layer.add_child(fade_rect)


func _add_platform(rect: Rect2, platform_name: String, color: Color) -> void:
	var body := StaticBody2D.new()
	body.name = platform_name
	body.position = rect.position + rect.size * 0.5
	var shape := CollisionShape2D.new()
	var rect_shape := RectangleShape2D.new()
	rect_shape.size = rect.size
	shape.shape = rect_shape
	body.add_child(shape)
	add_child(body)

	_add_visual_rect(rect, "%sVisual" % platform_name, color)


func _add_visual_rect(rect: Rect2, visual_name: String, color: Color) -> ColorRect:
	var visual := ColorRect.new()
	visual.name = visual_name
	visual.position = rect.position
	visual.size = rect.size
	visual.color = color
	visual.mouse_filter = Control.MOUSE_FILTER_IGNORE
	visuals_layer.add_child(visual)
	return visual


func _start_trial() -> void:
	await get_tree().create_timer(0.35).timeout
	if not is_inside_tree() or _completed:
		return
	await _run_trial_loop()


func _run_trial_loop() -> void:
	while is_inside_tree() and not _completed and not _transition_started:
		_retry_requested = false
		_attempts += 1
		attempt_label.text = "Attempts: %d" % _attempts
		await _reset_player_for_attempt()
		await _show_status("Attempt %d: %s" % [_attempts, _mode_hint()], 0.55)

		var survived := await _run_mode()
		if survived and not _retry_requested:
			await _complete_trial()
		elif is_inside_tree() and not _completed:
			_clear_hazards()
			await _show_status("Retrying safely. Watch the telegraph, not the text.", 0.75)


func _run_mode() -> bool:
	match trial_id:
		"choir_core":
			return await _run_choir_mode()
		"archive_tide":
			return await _run_archive_mode()
		"sovereign_final":
			return await _run_sovereign_mode()
		_:
			return await _run_generic_mode()


func _run_choir_mode() -> bool:
	await _show_status("Doctrine gate: Obedience. Do not stand where the command beam resolves.", 0.45)
	if not await _run_hazard(_pattern("Obedience Beam")): return false
	if not await _run_safe_zone(Rect2(Vector2(810, 390), Vector2(165, 110)), "Consent Gate", 0.95, 10.0, "stand in the consent gate before the firewall checks you"): return false

	await _show_status("Doctrine gate: Efficiency. The Core punishes panic and rewards timing.", 0.45)
	if not await _run_hazard(_pattern("Efficiency Bash")): return false
	if not await _run_hazard(_pattern("Mercy Sweep")): return false
	if not await _run_safe_zone(Rect2(Vector2(310, 390), Vector2(165, 110)), "Appeal Gate", 0.90, 10.0, "reach the appeal gate after the sweep"): return false

	await _show_status("Doctrine gate: Mercy Without Consent. Read both lanes before crossing.", 0.45)
	if not await _run_hazard(_pattern("Corruption Lanes")): return false
	if not await _run_hazard(_pattern("Corruption Lanes Return")): return false
	await _show_status("Choir doctrine broken. Short heal window.", 0.85)
	return not _retry_requested


func _run_archive_mode() -> bool:
	await _show_status("The Memory Ocean rises. Reach high ground before the backup tide crests.", 0.45)
	if not await _run_hazard(_pattern("Rising Tide")): return false
	if not await _run_safe_zone(Rect2(Vector2(550, 376), Vector2(180, 70)), "Stable Memory Island", 1.05, 12.0, "stand on the stable island before the ocean checks position"): return false

	await _show_status("Rejected timestamps form moving walls. Dash timing matters more than defense.", 0.45)
	if not await _run_hazard(_pattern("Timestamp Wall")): return false
	if not await _run_hazard(_pattern("Archive Undertow")): return false

	await _show_status("The center island collapses. Leave the memory that is breaking.", 0.45)
	if not await _run_hazard(_pattern("Broken Island Collapse")): return false
	if not await _run_safe_zone(Rect2(Vector2(915, 450), Vector2(180, 70)), "Right Memory Island", 0.95, 14.0, "reach the final island before the tide closes"): return false
	await _show_status("The Archive Tide recedes. Short heal window.", 0.85)
	return not _retry_requested


func _run_sovereign_mode() -> bool:
	await _show_status("SOVEREIGN judges the completed Source Key: %s" % _route_context(), 0.65)
	if not await _run_hazard(_pattern("Root Decree")): return false
	if not await _run_hazard(_route_judgement_pattern()): return false
	if not await _run_safe_zone(_sovereign_witness_safe_zone(), "Witness Relay", 0.85, 15.0, "stand with the witnesses before the root locks"): return false

	await _show_status("Final pressure: consent, ownership, and route compression arrive together.", 0.45)
	if not await _run_hazard(_pattern("Consent Shockwave")): return false
	if not await _run_hazard(_pattern("Single Owner Pulse")): return false
	if not await _run_hazard(_pattern("Route Compression Left")): return false
	if not await _run_hazard(_pattern("Route Compression Right")): return false
	await _show_status("The Root opens. No ending chosen yet; confrontation remains intact.", 0.85)
	return not _retry_requested


func _run_generic_mode() -> bool:
	for pattern in _get_patterns():
		if not await _run_hazard(pattern):
			return false
	return not _retry_requested


func _run_hazard(pattern: Dictionary) -> bool:
	var rect: Rect2 = pattern.get("rect", Rect2())
	var telegraph := float(pattern.get("telegraph", 0.7))
	var active := float(pattern.get("active", 0.35))
	var recovery := float(pattern.get("recovery", 0.45))
	var damage := float(pattern.get("damage", 12.0))
	var hazard_name := str(pattern.get("name", "Hazard"))
	var damage_type := str(pattern.get("damage_type", "hazard"))
	var counterplay := str(pattern.get("counterplay", "move"))

	phase_label.text = "%s - %s" % [hazard_name, counterplay]
	var marker := _make_hazard_marker(rect, _hazard_color("telegraph"), "%sTelegraph" % hazard_name)
	_play_sfx("enemy_telegraph")
	await _wait_or_retry(telegraph)
	if _retry_requested or not is_inside_tree():
		_free_marker(marker)
		return false

	marker.color = _hazard_color("active")
	_play_sfx("warning")
	var hit_applied := false
	var elapsed := 0.0
	while elapsed < active:
		if _retry_requested or not is_inside_tree():
			_free_marker(marker)
			return false
		if not hit_applied and _player_in_rect(rect):
			hit_applied = true
			_damage_player(damage, rect.get_center(), hazard_name, damage_type)
		await get_tree().physics_frame
		elapsed += get_physics_process_delta_time()

	marker.color = _hazard_color("recovery")
	await _wait_or_retry(recovery)
	_free_marker(marker)
	return not _retry_requested


func _run_safe_zone(rect: Rect2, zone_name: String, duration: float, damage: float, counterplay: String) -> bool:
	phase_label.text = "%s - %s" % [zone_name, counterplay]
	var marker := _make_hazard_marker(rect, Color(0.25, 1.0, 0.68, 0.36), "%sSafeZone" % zone_name)
	await _wait_or_retry(duration)
	if _retry_requested or not is_inside_tree():
		_free_marker(marker)
		return false
	if not _player_in_rect(rect):
		marker.color = Color(1.0, 0.14, 0.10, 0.62)
		_play_sfx("warning")
		_damage_player(damage, rect.get_center(), zone_name, "position")
		await _wait_or_retry(0.25)
	else:
		marker.color = Color(0.35, 0.95, 1.0, 0.18)
		_play_sfx("ui_confirm")
		await _wait_or_retry(0.20)
	_free_marker(marker)
	return not _retry_requested


func _damage_player(damage: float, source_position: Vector2, source_name: String, damage_type: String) -> void:
	if not player or not is_instance_valid(player) or player.is_dead:
		return
	player.take_damage(damage, source_position, source_name, damage_type)


func _wait_or_retry(duration: float) -> void:
	var elapsed := 0.0
	while elapsed < duration and is_inside_tree() and not _retry_requested and not _transition_started:
		await get_tree().process_frame
		elapsed += get_process_delta_time()


func _show_status(text: String, duration: float) -> void:
	if status_label:
		status_label.text = text
	await _wait_or_retry(duration)


func _make_hazard_marker(rect: Rect2, color: Color, marker_name: String) -> ColorRect:
	var marker := ColorRect.new()
	marker.name = marker_name
	marker.position = rect.position
	marker.size = rect.size
	marker.color = color
	marker.mouse_filter = Control.MOUSE_FILTER_IGNORE
	marker.z_index = 12
	hazards_layer.add_child(marker)
	_active_markers.append(marker)
	return marker


func _free_marker(marker: Node) -> void:
	if marker:
		_active_markers.erase(marker)
		if is_instance_valid(marker):
			marker.queue_free()


func _clear_hazards() -> void:
	for marker in _active_markers.duplicate():
		if marker and is_instance_valid(marker):
			marker.queue_free()
	_active_markers.clear()
	if hazards_layer and is_instance_valid(hazards_layer):
		for child in hazards_layer.get_children():
			child.queue_free()


func _player_in_rect(rect: Rect2) -> bool:
	if not player or not is_instance_valid(player):
		return false
	var points := [
		player.global_position,
		player.global_position + Vector2(0, -22),
		player.global_position + Vector2(0, 22),
		player.global_position + Vector2(-14, 0),
		player.global_position + Vector2(14, 0)
	]
	for point in points:
		if rect.has_point(point):
			return true
	return false


func _on_player_died() -> void:
	_retry_requested = true
	_clear_hazards()
	if status_label:
		status_label.text = "Signal lost. Local retry restoring player state."


func _reset_player_for_attempt() -> void:
	Engine.time_scale = 1.0
	_clear_hazards()
	if not player or not is_instance_valid(player):
		return
	_restore_player()
	await get_tree().process_frame
	_restore_player()
	await get_tree().physics_frame
	_restore_player()


func _restore_player() -> void:
	if not player or not is_instance_valid(player):
		return
	if player.has_method("force_restore_after_death_retry"):
		player.force_restore_after_death_retry(_player_spawn)
	else:
		player.global_position = _player_spawn
		player.velocity = Vector2.ZERO
		player.set("is_dead", false)
		player.set("invulnerable", true)
		player.set("invuln_timer", 0.65)
		if player.get("current_health") != null and player.get("max_health") != null:
			player.set("current_health", player.get("max_health"))


func _complete_trial() -> void:
	if _transition_started:
		return
	_completed = true
	_transition_started = true
	_clear_hazards()

	var first_completion := not _is_already_complete()
	if completion_flag != "":
		GameManager.set_story_flag(completion_flag, true)
	if first_completion:
		_set_player_level_signal_connected(false)
		if xp_reward > 0:
			GameManager.add_xp(xp_reward)
		if gold_reward > 0:
			GameManager.add_gold(gold_reward)
		if reward_item != "" and reward_quantity > 0:
			_grant_item(reward_item, reward_quantity)
		_set_player_level_signal_connected(true)
	else:
		await _show_status("Trial already cleared. Reward skipped.", 0.35)

	GameManager.save_game(GameManager.AUTOSAVE_SLOT)
	_play_sfx("arena_victory")
	await _show_status("Trial cleared. Route opening.", 0.9)
	await _fade_to_black(0.35)
	_transition_to_next_scene()


func _skip_completed_trial() -> void:
	if _transition_started:
		return
	_completed = true
	_transition_started = true
	_clear_hazards()
	await _show_status("Trial already stable. Routing forward without duplicate rewards.", 0.7)
	await _fade_to_black(0.25)
	_transition_to_next_scene()


func _transition_to_next_scene() -> void:
	if not is_inside_tree():
		return
	GameManager.change_state(GameManager.GameState.CUTSCENE)
	if next_scene == "":
		return
	if has_node("/root/SceneTransitions"):
		SceneTransitions.change_scene(next_scene)
	else:
		get_tree().change_scene_to_file(next_scene)


func _is_already_complete() -> bool:
	return completion_flag != "" and GameManager.has_flag(completion_flag)


func _set_player_level_signal_connected(should_connect: bool) -> void:
	if not player or not is_instance_valid(player):
		return
	var callback := Callable(player, "_on_player_leveled_up")
	if should_connect:
		if not GameManager.player_leveled_up.is_connected(callback):
			GameManager.player_leveled_up.connect(callback)
	elif GameManager.player_leveled_up.is_connected(callback):
		GameManager.player_leveled_up.disconnect(callback)


func _get_patterns() -> Array:
	match trial_id:
		"choir_core":
			return [
				{"name": "Obedience Beam", "rect": Rect2(Vector2(580, 126), Vector2(120, 470)), "telegraph": 0.95, "active": 0.32, "recovery": 0.42, "damage": 15.0, "damage_type": "dash", "counterplay": "dash or leave the command beam"},
				{"name": "Efficiency Bash", "rect": Rect2(Vector2(500, 386), Vector2(280, 196)), "telegraph": 0.72, "active": 0.28, "recovery": 0.58, "damage": 18.0, "damage_type": "parry", "counterplay": "defend/parry or dash out"},
				{"name": "Mercy Sweep", "rect": Rect2(Vector2(80, 522), Vector2(1120, 74)), "telegraph": 0.82, "active": 0.34, "recovery": 0.52, "damage": 14.0, "damage_type": "jump", "counterplay": "jump or use the choir steps"},
				{"name": "Corruption Lanes", "rect": Rect2(Vector2(135, 138), Vector2(210, 458)), "telegraph": 0.75, "active": 0.32, "recovery": 0.28, "damage": 13.0, "damage_type": "corruption", "counterplay": "move to the open lane"},
				{"name": "Corruption Lanes Return", "rect": Rect2(Vector2(935, 138), Vector2(210, 458)), "telegraph": 0.75, "active": 0.32, "recovery": 0.48, "damage": 13.0, "damage_type": "corruption", "counterplay": "cross after recovery"}
			]
		"archive_tide":
			return [
				{"name": "Rising Tide", "rect": Rect2(Vector2(0, 518), Vector2(1280, 78)), "telegraph": 1.05, "active": 0.48, "recovery": 0.34, "damage": 15.0, "damage_type": "tide", "counterplay": "jump to a memory island"},
				{"name": "Timestamp Wall", "rect": Rect2(Vector2(420, 120), Vector2(105, 476)), "telegraph": 0.78, "active": 0.28, "recovery": 0.24, "damage": 16.0, "damage_type": "dash", "counterplay": "dash through the timestamp gap"},
				{"name": "Archive Undertow", "rect": Rect2(Vector2(760, 120), Vector2(105, 476)), "telegraph": 0.78, "active": 0.28, "recovery": 0.48, "damage": 16.0, "damage_type": "dash", "counterplay": "wait, then cross after the first wall"},
				{"name": "Broken Island Collapse", "rect": Rect2(Vector2(510, 392), Vector2(260, 204)), "telegraph": 0.95, "active": 0.38, "recovery": 0.42, "damage": 17.0, "damage_type": "position", "counterplay": "leave the center island"}
			]
		"sovereign_final":
			return [
				{"name": "Root Decree", "rect": Rect2(Vector2(600, 96), Vector2(80, 500)), "telegraph": 0.84, "active": 0.28, "recovery": 0.32, "damage": 18.0, "damage_type": "dash", "counterplay": "dash through or stay clear of the root"},
				{"name": "Consent Shockwave", "rect": Rect2(Vector2(100, 516), Vector2(1080, 80)), "telegraph": 0.86, "active": 0.34, "recovery": 0.42, "damage": 17.0, "damage_type": "jump", "counterplay": "jump the low wave"},
				{"name": "Single Owner Pulse", "rect": Rect2(Vector2(390, 332), Vector2(500, 250)), "telegraph": 0.76, "active": 0.30, "recovery": 0.52, "damage": 20.0, "damage_type": "parry", "counterplay": "defend/parry or retreat to a witness ledge"},
				{"name": "Route Compression Left", "rect": Rect2(Vector2(110, 120), Vector2(270, 476)), "telegraph": 0.66, "active": 0.26, "recovery": 0.20, "damage": 15.0, "damage_type": "position", "counterplay": "read the side compression"},
				{"name": "Route Compression Right", "rect": Rect2(Vector2(900, 120), Vector2(270, 476)), "telegraph": 0.66, "active": 0.26, "recovery": 0.45, "damage": 15.0, "damage_type": "position", "counterplay": "cross only during recovery"}
			]
		_:
			return [
				{"name": "Training Pulse", "rect": Rect2(Vector2(520, 460), Vector2(240, 130)), "telegraph": 0.8, "active": 0.4, "recovery": 0.6, "damage": 10.0, "damage_type": "hazard", "counterplay": "move out"}
			]


func _pattern(pattern_name: String) -> Dictionary:
	for pattern in _get_patterns():
		if str(pattern.get("name", "")) == pattern_name:
			return pattern
	push_warning("Late-game trial missing pattern: %s" % pattern_name)
	return _get_patterns()[0]


func _route_judgement_pattern() -> Dictionary:
	var pattern := _pattern("Single Owner Pulse").duplicate(true)
	if GameManager.has_flag("ch9_truth_hidden"):
		pattern["name"] = "Hidden Truth Compression"
		pattern["counterplay"] = "retreat to a witness ledge before the hidden route closes"
	elif GameManager.has_flag("ch8_council_formed"):
		pattern["name"] = "Council Deadlock Pulse"
		pattern["counterplay"] = "defend/parry the center debate pulse"
	elif GameManager.has_flag("ch8_witness_network_created") or GameManager.has_flag("ch9_truth_distributed"):
		pattern["name"] = "Witness Network Surge"
		pattern["rect"] = Rect2(Vector2(165, 325), Vector2(950, 250))
		pattern["counterplay"] = "move to a witness ledge before the network surges"
	else:
		pattern["name"] = "Single Owner Pulse"
	return pattern


func _sovereign_witness_safe_zone() -> Rect2:
	if GameManager.has_flag("ch8_witness_network_created") or GameManager.has_flag("ch9_truth_distributed"):
		return Rect2(Vector2(245, 432), Vector2(150, 75))
	if GameManager.has_flag("ch8_council_formed"):
		return Rect2(Vector2(885, 432), Vector2(150, 75))
	return Rect2(Vector2(565, 472), Vector2(150, 80))


func _route_context() -> String:
	if trial_id != "sovereign_final":
		return "chapter-specific"
	if GameManager.has_flag("ch9_truth_confessed"):
		return "confession route"
	if GameManager.has_flag("ch9_truth_hidden"):
		return "hidden-truth route"
	if GameManager.has_flag("ch9_truth_distributed"):
		return "distributed-truth route"
	if GameManager.has_flag("ch8_council_formed"):
		return "council route"
	if GameManager.has_flag("ch8_witness_network_created"):
		return "witness route"
	return "unified revolt route"


func _mode_label() -> String:
	match trial_id:
		"choir_core":
			return "choir_mode"
		"archive_tide":
			return "archive_tide_mode"
		"sovereign_final":
			return "sovereign_final_mode"
		_:
			return "generic_mode"


func _arena_identity() -> String:
	match trial_id:
		"choir_core":
			return "firewall gates and doctrine checks"
		"archive_tide":
			return "memory islands, rising tide, and collapsing history"
		"sovereign_final":
			return "route judgement, witness relays, and root compression"
		_:
			return "basic training"


func _mode_hint() -> String:
	match trial_id:
		"choir_core":
			return "Choir mode: solve firewall gates while reacting to command pulses."
		"archive_tide":
			return "Archive mode: climb memory islands and escape tide pressure."
		"sovereign_final":
			return "Root mode: survive route-based judgement before the final choice."
		_:
			return "Survive the telegraph and active window."


func _theme_color() -> Color:
	match trial_id:
		"choir_core":
			return Color(0.50, 0.72, 1.0)
		"archive_tide":
			return Color(0.38, 0.86, 1.0)
		"sovereign_final":
			return Color(1.0, 0.52, 0.82)
		_:
			return Color(0.7, 0.8, 1.0)


func _hazard_color(stage: String) -> Color:
	var base := _theme_color()
	match stage:
		"telegraph":
			return Color(base.r, base.g, base.b, 0.34)
		"active":
			return Color(1.0, 0.16, 0.12, 0.60)
		"recovery":
			return Color(base.r, minf(base.g + 0.12, 1.0), minf(base.b + 0.12, 1.0), 0.18)
		_:
			return Color(base.r, base.g, base.b, 0.30)


func _add_scene_label(text: String, position: Vector2, color: Color, font_size: int = 14) -> void:
	var label := Label.new()
	label.text = text
	label.position = position
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.add_theme_constant_override("outline_size", 2)
	label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.78))
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	visuals_layer.add_child(label)


func _grant_item(item_id: String, quantity: int) -> bool:
	if has_node("/root/CraftingSystem") and CraftingSystem.has_method("get_recipes"):
		CraftingSystem.get_recipes()
	if has_node("/root/Inventory") and Inventory.has_method("add_item"):
		return Inventory.add_item(item_id, quantity)
	return false


func _play_sfx(sound_id: String) -> void:
	if has_node("/root/SFXManager"):
		SFXManager.play(sound_id)


func _fade_to_black(duration: float) -> void:
	if not fade_rect:
		return
	var tw := create_tween()
	tw.tween_property(fade_rect, "modulate:a", 1.0, duration)
	await tw.finished
