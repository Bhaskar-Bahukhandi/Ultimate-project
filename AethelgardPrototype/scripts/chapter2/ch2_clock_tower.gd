extends Node2D

## Chapter 2: The Administrator's Game
## Sequence 6: Clock Tower — Vertical dungeon with time manipulation and Clockwork Automaton boss

@onready var player_node = $Player
@onready var camera = $Camera2D

var automaton_defeated: bool = false
var _mid_dialogue_done: bool = false
var _pre_boss_done: bool = false
var _time_zones: Array = []
var _moving_platforms: Array = []
var _root_access_panel: RootAccessPanel = null

# Floor Y positions (ascending tower — lower Y = higher floor)
const FLOOR_Y = {
	1: 900,   # Ground floor — entry
	2: 650,   # Second floor — slow-time zone
	3: 400,   # Third floor — discovery chamber
	4: 150,   # Fourth floor — fast-time zone
	5: -150,  # Top floor — boss arena
}

func _has_elara() -> bool:
	return GameManager.has_elara()

func _has_flag(flag_name: String) -> bool:
	return GameManager.has_flag(flag_name)
const FLOOR_HEIGHT = 250
const TOWER_WIDTH = 800

func _attach_camera_to_player() -> void:
	if not is_instance_valid(camera) or not is_instance_valid(player_node):
		return
	camera.reparent(player_node, false)
	camera.position = Vector2(0, -40)
	camera.position_smoothing_enabled = true
	camera.make_current()

func _ready() -> void:
	print("[CH2-CLOCKTOWER] Initializing Clock Tower dungeon")
	GameManager.change_state(GameManager.GameState.EXPLORATION)

	# Play combat music for the clock tower dungeon
	if has_node("/root/MusicManager"):
		MusicManager.play_track("clock_tower")  # Pass 53: Use dedicated clock tower track

	if camera:
		camera.make_current()
		# The camera was a fixed sibling at the ground floor, so climbing the
		# tower took the player off-screen. Make it follow the player.
		_attach_camera_to_player.call_deferred()

	# Replace placeholder sprite with real player art
	if player_node:
		AssetManager.replace_player_sprite(player_node, "combat")

	_build_tower_environment()
	_create_gear_decorations()
	_create_time_zones()
	_create_moving_platforms()
	_spawn_tower_enemies()
	_create_floor_triggers()
	_setup_root_access()

	# Entry dialogue
	await get_tree().create_timer(0.5).timeout
	if not is_inside_tree(): return
	await _entry_dialogue()

const TOWER_DLG := "res://dialogue/ch2/clock_tower.dlg"

func _entry_dialogue() -> void:
	await DialogueManager.run(TOWER_DLG, "entry")

func _build_tower_environment() -> void:
	## Build the vertical clock tower dungeon
	# Dark tower background
	var bg = ColorRect.new()
	bg.color = Color(0.08, 0.06, 0.04)
	bg.size = Vector2(1200, 1600)
	bg.position = Vector2(-200, -400)
	bg.z_index = -10
	add_child(bg)

	# Tower walls (left and right boundaries)
	_create_wall(Vector2(0, -400), Vector2(20, 1600))    # Left wall
	_create_wall(Vector2(780, -400), Vector2(20, 1600))   # Right wall

	# Floor platforms for each level
	for floor_num in range(1, 6):
		var y = FLOOR_Y[floor_num]

		# Main floor platform. Floors above the ground are one-way: they were
		# solid full-width slabs, which sealed the player inside floor 1 (the
		# step platforms below each floor had nothing to lead into). Now you
		# jump up through a floor from the steps/lifts and land on top of it,
		# while anything standing on a floor — enemies, the boss — stays put.
		_create_wall(Vector2(0, y), Vector2(TOWER_WIDTH, 20), floor_num > 1)

		# Partial platforms and gaps for vertical navigation
		if floor_num < 5:
			# Opening on alternating sides so player zigzags up
			if floor_num % 2 == 1:
				# Gap on the right side
				_create_wall(Vector2(0, y - FLOOR_HEIGHT + 60), Vector2(350, 15))
				_create_wall(Vector2(0, y - FLOOR_HEIGHT + 140), Vector2(250, 15))
			else:
				# Gap on the left side
				_create_wall(Vector2(450, y - FLOOR_HEIGHT + 60), Vector2(350, 15))
				_create_wall(Vector2(550, y - FLOOR_HEIGHT + 140), Vector2(250, 15))

	# Ceiling above boss arena — at the top of the tower walls. It sat at y=-250,
	# only 100 px above the boss floor, overlapping where the boss spawns.
	_create_wall(Vector2(0, FLOOR_Y[5] - FLOOR_HEIGHT), Vector2(TOWER_WIDTH, 20))

func _create_wall(pos: Vector2, wall_size: Vector2, one_way: bool = false) -> void:
	var wall = StaticBody2D.new()
	wall.position = pos

	var rect = ColorRect.new()
	rect.color = Color(0.18, 0.14, 0.1)
	rect.size = wall_size
	wall.add_child(rect)

	var col = CollisionShape2D.new()
	var shape = RectangleShape2D.new()
	shape.size = wall_size
	col.shape = shape
	col.position = wall_size * 0.5
	col.one_way_collision = one_way
	wall.add_child(col)

	add_child(wall)

func _create_gear_decorations() -> void:
	## Create decorative gears throughout the tower
	var gear_positions = [
		Vector2(100, 850), Vector2(650, 830), Vector2(400, 780),
		Vector2(200, 600), Vector2(580, 580),
		Vector2(350, 350), Vector2(700, 370),
		Vector2(150, 100), Vector2(500, 120),
		Vector2(400, -100), Vector2(250, -180),
	]

	for pos in gear_positions:
		var gear = ColorRect.new()
		var gear_size = randf_range(20.0, 50.0)
		gear.size = Vector2(gear_size, gear_size)
		gear.color = Color(0.45, 0.35, 0.2, 0.5)
		gear.position = pos
		gear.pivot_offset = gear.size * 0.5
		gear.z_index = -3
		add_child(gear)

		# Rotate gears continuously
		var speed = randf_range(0.3, 1.2) * (1.0 if randi() % 2 == 0 else -1.0)
		var tween = create_tween().set_loops()
		tween.tween_property(gear, "rotation", TAU * sign(speed), abs(4.0 / speed))

func _create_time_zones() -> void:
	## Create temporal anomaly zones that affect player speed
	# Slow zone on floor 2
	_create_time_zone(Vector2(100, FLOOR_Y[2] - FLOOR_HEIGHT + 20), Vector2(300, 180), 0.4, "TEMPORAL DRAG")

	# Fast zone on floor 4
	_create_time_zone(Vector2(400, FLOOR_Y[4] - FLOOR_HEIGHT + 20), Vector2(300, 180), 2.0, "TEMPORAL SURGE")

	# Unstable zone on floor 3
	_create_time_zone(Vector2(250, FLOOR_Y[3] - 60), Vector2(200, 50), 0.0, "TEMPORAL FLUX")

func _create_time_zone(pos: Vector2, zone_size: Vector2, speed_mult: float, label_text: String) -> void:
	## Create an area that modifies player movement speed
	var zone = Area2D.new()
	zone.position = pos

	var visual = ColorRect.new()
	if speed_mult < 1.0:
		visual.color = Color(0.2, 0.3, 0.8, 0.15)
	elif speed_mult > 1.0:
		visual.color = Color(0.8, 0.3, 0.1, 0.15)
	else:
		visual.color = Color(0.6, 0.1, 0.6, 0.2)
	visual.size = zone_size
	zone.add_child(visual)

	var col = CollisionShape2D.new()
	var shape = RectangleShape2D.new()
	shape.size = zone_size
	col.shape = shape
	col.position = zone_size * 0.5
	zone.add_child(col)

	var label = Label.new()
	label.text = label_text
	label.position = Vector2(10, -18)
	label.add_theme_font_size_override("font_size", 10)
	label.add_theme_color_override("font_color", visual.color.lightened(0.5))
	zone.add_child(label)

	# Pulse the zone visual
	var pulse = create_tween().set_loops()
	pulse.tween_property(visual, "modulate:a", 0.4, 1.5)
	pulse.tween_property(visual, "modulate:a", 1.0, 1.5)

	zone.body_entered.connect(_on_time_zone_entered.bind(speed_mult, label_text))
	zone.body_exited.connect(_on_time_zone_exited)
	add_child(zone)
	_time_zones.append(zone)

func _on_time_zone_entered(body, speed_mult: float, zone_name: String) -> void:
	if body.is_in_group("player"):
		if body.has_method("set_speed_multiplier"):
			body.set_speed_multiplier(speed_mult)
		VFXLibrary.spawn_status_indicator(zone_name, body.global_position + Vector2(0, -40), self, false)

func _on_time_zone_exited(body) -> void:
	if body.is_in_group("player"):
		if body.has_method("set_speed_multiplier"):
			body.set_speed_multiplier(1.0)

func _create_moving_platforms() -> void:
	## Create moving platforms between floors for vertical traversal
	# Platform between floor 1 and 2 (right side)
	_create_moving_platform(Vector2(550, FLOOR_Y[1] - 30), Vector2(550, FLOOR_Y[2] + 30), 4.0)

	# Platform between floor 2 and 3 (left side)
	_create_moving_platform(Vector2(150, FLOOR_Y[2] - 30), Vector2(150, FLOOR_Y[3] + 30), 5.0)

	# Platform between floor 3 and 4 (center)
	_create_moving_platform(Vector2(350, FLOOR_Y[3] - 30), Vector2(350, FLOOR_Y[4] + 30), 4.5)

	# Platform between floor 4 and boss arena (right side)
	_create_moving_platform(Vector2(500, FLOOR_Y[4] - 30), Vector2(500, FLOOR_Y[5] + 30), 5.5)

func _create_moving_platform(start: Vector2, end: Vector2, cycle_time: float) -> void:
	## Create a platform that moves between two vertical points
	var platform = AnimatableBody2D.new()
	platform.position = start

	var rect = ColorRect.new()
	rect.color = Color(0.5, 0.4, 0.25)
	rect.size = Vector2(100, 15)
	rect.position = Vector2(-50, -7)
	platform.add_child(rect)

	var col = CollisionShape2D.new()
	var shape = RectangleShape2D.new()
	shape.size = Vector2(100, 15)
	col.shape = shape
	platform.add_child(col)

	add_child(platform)

	# Animate movement
	var tween = create_tween().set_loops()
	tween.tween_property(platform, "position", end, cycle_time * 0.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(platform, "position", start, cycle_time * 0.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_moving_platforms.append(platform)

func _spawn_tower_enemies() -> void:
	## Spawn enemies on each floor
	# Floor 1 — light resistance
	_spawn_enemy_at("clockwork_soldier", Vector2(300, FLOOR_Y[1] - 40))
	_spawn_enemy_at("clockwork_soldier", Vector2(600, FLOOR_Y[1] - 40))

	# Floor 2 — shadows in the slow zone
	_spawn_enemy_at("shadow_wraith", Vector2(200, FLOOR_Y[2] - 50))
	_spawn_enemy_at("clockwork_soldier", Vector2(500, FLOOR_Y[2] - 40))

	# Floor 3 — mixed guard
	_spawn_enemy_at("shadow_wraith", Vector2(400, FLOOR_Y[3] - 50))
	_spawn_enemy_at("shadow_wraith", Vector2(650, FLOOR_Y[3] - 50))

	# Floor 4 — heavy resistance before boss
	_spawn_enemy_at("clockwork_soldier", Vector2(200, FLOOR_Y[4] - 40))
	_spawn_enemy_at("clockwork_soldier", Vector2(450, FLOOR_Y[4] - 40))
	_spawn_enemy_at("shadow_wraith", Vector2(650, FLOOR_Y[4] - 50))

	# Floor 5 — Boss
	_spawn_clockwork_automaton()

func _spawn_enemy_at(enemy_type: String, pos: Vector2) -> void:
	## Spawn a regular enemy — uses AssetManager for sprites with ColorRect fallback
	var enemy: EnemyBase

	match enemy_type:
		"clockwork_soldier":
			enemy = ClockworkSoldier.new()
		"shadow_wraith":
			enemy = ShadowWraith.new()
		_:
			return

	enemy.position = pos
	enemy.name = enemy_type + "_" + str(randi() % 9999)

	# Sprite — AssetManager first, ColorRect fallback
	var target_size = Vector2(30, 40)
	if AssetManager.is_asset_available(enemy_type):
		var sprite = Sprite2D.new()
		sprite.name = "Sprite"
		sprite.texture = AssetManager.get_sprite(enemy_type)
		sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		var tex_size = sprite.texture.get_size()
		if tex_size.x > 0 and tex_size.y > 0:
			var uniform = min(target_size.x / tex_size.x, target_size.y / tex_size.y) * 2.0
			sprite.scale = Vector2(uniform, uniform)
			sprite.offset = Vector2(0, -tex_size.y / 2.0)
		enemy.add_child(sprite)
	else:
		var sprite = ColorRect.new()
		sprite.name = "Sprite"
		sprite.size = target_size
		sprite.position = Vector2(-15, -40)
		sprite.color = AssetManager.get_placeholder_color(enemy_type)
		enemy.add_child(sprite)

	var col = CollisionShape2D.new()
	var shape = RectangleShape2D.new()
	shape.size = target_size
	col.shape = shape
	col.position = Vector2(0, -20)
	enemy.add_child(col)

	add_child(enemy)

func _setup_root_access() -> void:
	## Add the reusable Root Access panel.
	_root_access_panel = RootAccessPanel.new()
	add_child(_root_access_panel)

func _input(event) -> void:
	if event.is_action_pressed("root_access") and _root_access_panel:
		if _root_access_panel.visible:
			_root_access_panel.close()
		elif player_node:
			var enemy = _root_access_panel.get_nearest_enemy(player_node.global_position)
			if enemy:
				_root_access_panel.open(enemy, 2.0)
		get_viewport().set_input_as_handled()

func _spawn_clockwork_automaton() -> void:
	## Spawn the Clockwork Automaton boss at the top of the tower
	var boss = ClockworkAutomatonBoss.new()
	boss.position = Vector2(400, FLOOR_Y[5] - 70)
	boss.name = "ClockworkAutomaton"

	var sprite = ColorRect.new()
	sprite.name = "Sprite"
	sprite.size = Vector2(60, 80)
	sprite.position = Vector2(-30, -80)
	sprite.color = Color(0.6, 0.45, 0.15)
	boss.add_child(sprite)

	var col = CollisionShape2D.new()
	var shape = RectangleShape2D.new()
	shape.size = Vector2(60, 80)
	col.shape = shape
	col.position = Vector2(0, -40)
	boss.add_child(col)

	# Health bar
	var hp_bar = ProgressBar.new()
	hp_bar.name = "HealthBar"
	hp_bar.size = Vector2(70, 8)
	hp_bar.position = Vector2(-35, -95)
	hp_bar.value = 100
	hp_bar.show_percentage = false
	boss.add_child(hp_bar)

	# BUG-21-20: Guard signal connections with has_signal check
	if boss.has_signal("boss_defeated"):
		boss.boss_defeated.connect(_on_automaton_defeated)
	if boss.has_signal("phase_changed"):
		boss.phase_changed.connect(_on_boss_phase_changed)
	if boss.has_signal("health_changed"):
		boss.health_changed.connect(_on_automaton_health_changed.bind(hp_bar))
	add_child(boss)

func _on_automaton_health_changed(new_hp: float, max_hp: float, bar: ProgressBar) -> void:
	if is_instance_valid(bar) and max_hp > 0.0:
		bar.value = (new_hp / max_hp) * 100.0

func _create_floor_triggers() -> void:
	## Create triggers for mid-dungeon dialogue and boss arena entry
	# Mid-dungeon trigger on floor 3
	var mid_trigger = Area2D.new()
	mid_trigger.name = "MidTrigger"
	mid_trigger.position = Vector2(400, FLOOR_Y[3] - 30)
	var mt_col = CollisionShape2D.new()
	var mt_shape = CircleShape2D.new()
	mt_shape.radius = 60.0
	mt_col.shape = mt_shape
	mid_trigger.add_child(mt_col)
	mid_trigger.body_entered.connect(_on_mid_trigger)
	add_child(mid_trigger)

	# Pre-boss trigger just below floor 5
	var boss_trigger = Area2D.new()
	boss_trigger.name = "BossTrigger"
	boss_trigger.position = Vector2(400, FLOOR_Y[5] + 60)
	var bt_col = CollisionShape2D.new()
	var bt_shape = CircleShape2D.new()
	bt_shape.radius = 50.0
	bt_col.shape = bt_shape
	boss_trigger.add_child(bt_col)
	boss_trigger.body_entered.connect(_on_boss_trigger)
	add_child(boss_trigger)

func _on_mid_trigger(body) -> void:
	if not body.is_in_group("player") or _mid_dialogue_done:
		return
	_mid_dialogue_done = true
	_mid_dungeon_dialogue()

func _mid_dungeon_dialogue() -> void:
	## Floor 3: the scratched map mark (a seed for later).
	await DialogueManager.run(TOWER_DLG, "mid")

func _on_boss_trigger(body) -> void:
	if not body.is_in_group("player") or _pre_boss_done:
		return
	_pre_boss_done = true
	_pre_boss_dialogue()

func _pre_boss_dialogue() -> void:
	## B02 The Minute Hand, before the fight.
	GameManager.change_state(GameManager.GameState.COMBAT)
	await DialogueManager.run(TOWER_DLG, "pre_boss")
	if not is_inside_tree(): return

	# Camera shake for dramatic boss intro
	if camera and camera.has_method("shake"):
		camera.shake(10.0, 0.8)

	DialogueManager.hide_dialogue()
	await get_tree().create_timer(1.0).timeout
	if not is_inside_tree(): return

	# Pan camera to boss briefly
	if camera and camera.has_method("pan_to"):
		camera.pan_to(Vector2(400, FLOOR_Y[5] - 70), 1.0)
		await get_tree().create_timer(1.5).timeout
		if not is_inside_tree(): return
		if player_node:
			camera.pan_to(body_position_or_default(), 0.8)

func body_position_or_default() -> Vector2:
	return player_node.global_position if player_node else Vector2(400, FLOOR_Y[5] + 60)

func _on_boss_phase_changed(new_phase: int) -> void:
	## The Minute Hand speaks in system tone; one bark per phase.
	if camera and camera.has_method("shake"):
		camera.shake(12.0, 0.6)
	var bark := ""
	match new_phase:
		2:
			bark = "bark_replay"    # it starts replaying your last combo
		3:
			bark = "bark_correct"
	if bark == "":
		return
	var line: Dictionary = DialogueManager.line_of(TOWER_DLG, bark)
	if line.is_empty():
		return
	DialogueManager.say(line["speaker"], line["text"], Color(-1, -1, -1), true)

func _on_automaton_defeated() -> void:
	## B02 down: half the tower back, then C2-S11 — the missing shift.
	automaton_defeated = true
	GameManager.set_story_flag("ch2_clockwork_automaton_defeated", true)
	GameManager.auto_save()  # Autosave on boss defeat

	var flash = ColorRect.new()
	flash.color = Color(1, 0.9, 0.6, 0.8)
	flash.size = Vector2(1280, 720)
	flash.z_index = 100
	add_child(flash)
	var flash_tween = create_tween()
	flash_tween.tween_property(flash, "modulate:a", 0.0, 1.5)
	flash_tween.tween_callback(flash.queue_free)

	if camera and camera.has_method("shake"):
		camera.shake(15.0, 1.0)

	await get_tree().create_timer(2.0).timeout
	if not is_inside_tree(): return

	# victory → missing_shift → unlock (sets ch2_clock_tower_complete and ch2_underground_unlocked)
	await DialogueManager.run(TOWER_DLG, "victory")
	if not is_inside_tree(): return
	GameManager.set_story_flag("ch2_clock_tower_complete", true)
	DialogueManager.hide_dialogue()

	await get_tree().create_timer(1.5).timeout
	if not is_inside_tree(): return
	SceneTransitions.change_scene("res://scenes/regions/ironhold_region.tscn")
