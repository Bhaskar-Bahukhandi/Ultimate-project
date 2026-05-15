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

func _ready() -> void:
	print("[CH2-CLOCKTOWER] Initializing Clock Tower dungeon")
	GameManager.change_state(GameManager.GameState.EXPLORATION)

	# Play combat music for the clock tower dungeon
	if has_node("/root/MusicManager"):
		MusicManager.play_track("clock_tower")  # Pass 53: Use dedicated clock tower track

	if camera:
		camera.make_current()

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

func _entry_dialogue() -> void:
	var has_elara = _has_elara()

	await DialogueManager.say("Kaelen", "This is the Clock Tower — the beating heart of Ironhold. Every tick of every clock in the city is synchronized from here.")
	if not is_inside_tree(): return

	if has_elara:
		await DialogueManager.say("Elara", "More than that. The Clock Tower controls Ironhold's tick rate — the fundamental speed at which this region of the world processes. If someone tampered with it...")
		if not is_inside_tree(): return
	else:
		await DialogueManager.say("Kaelen (Internal)", "The Clock Tower controls Ironhold's tick rate — the fundamental speed at which this region processes. If someone tampered with it, the entire city would desync.")
		if not is_inside_tree(): return

	await DialogueManager.say("Kaelen (Internal)", "Tick rate. In engine terms, that's the server's update frequency. If someone is manipulating the Clock Tower, they're essentially overclocking or throttling the entire region. That would explain the time distortions refugees reported at the gate.")
	if not is_inside_tree(): return

	if has_elara:
		await DialogueManager.say("Elara", "Can you feel it? The air is thick with temporal variance. Some areas of the tower run faster, others slower. The Administration's chronometers are failing.")
		if not is_inside_tree(): return
	else:
		await DialogueManager.say("Kaelen", "*stepping through the threshold* The air feels... thick. Like walking through syrup in some spots. Temporal variance — some pockets are running fast, others dragging. No one to watch my back in here.")
		if not is_inside_tree(): return

	await DialogueManager.say("System", "[ENTERING: CLOCK TOWER — CENTRAL CHRONOMETRY]\n[Tick Rate Anomalies: DETECTED]\n[Temporal Stability: 34%]\n[Authorization: OVERRIDDEN]", Color(1, 0.7, 0.2), true)
	if not is_inside_tree(): return

	await DialogueManager.say("Kaelen", "Thirty-four percent temporal stability. That means time itself is fractured in here. We need to ascend to the top — that's where the master regulator will be.")
	if not is_inside_tree(): return

	if has_elara:
		await DialogueManager.say("Elara", "And whatever is corrupting it. Be ready for anything, Kaelen. The clockwork guardians won't let us pass easily.")
		if not is_inside_tree(): return
	else:
		await DialogueManager.say("Kaelen (Internal)", "Whatever is corrupting this place is at the top. And I'll have to fight through the guardians alone. Root Access will have to be enough.")
		if not is_inside_tree(): return
		if _has_flag("ch2_data_wraith_absorbed"):
			await DialogueManager.say("System", "[ROOT ACCESS: WRAITH ABSORPTION RESONATING WITH TEMPORAL FIELD]\n[Additional capability: TEMPORAL DRAIN — available in combat]", Color(0.8, 0.4, 1.0), true)
			if not is_inside_tree(): return

	DialogueManager.hide_dialogue()

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

		# Main floor platform
		_create_wall(Vector2(0, y), Vector2(TOWER_WIDTH, 20))

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

	# Ceiling above boss arena
	_create_wall(Vector2(0, -250), Vector2(TOWER_WIDTH, 20))

func _create_wall(pos: Vector2, wall_size: Vector2) -> void:
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
	## Discovery dialogue on floor 3 — Administrator corruption revealed
	var has_elara = _has_elara()

	await DialogueManager.say("Kaelen", "Wait. Look at these data streams running through the walls. They're not just clock signals — there's something else encoded in them.")
	if not is_inside_tree(): return

	await DialogueManager.say("System", "[ANALYZING DATA STREAM...]\n[Hidden payload detected]\n[Type: ADMINISTRATIVE OVERRIDE COMMANDS]\n[Origin: EXTERNAL — NOT IRONHOLD]", Color(1, 0.3, 0.3), true)
	if not is_inside_tree(): return

	await DialogueManager.say("Kaelen", "Administrative override commands. Someone is piggybacking on the clock tower's tick-rate signal to inject commands into Ironhold's core processes.")
	if not is_inside_tree(): return

	if has_elara:
		await DialogueManager.say("Elara", "That's... that's how they're doing it. The corruption isn't random — it's deliberate. Someone is USING the clock tower to rewrite Ironhold from the inside.")
		if not is_inside_tree(): return
	else:
		await DialogueManager.say("Kaelen", "It's not random. None of it was random. Someone is deliberately USING this tower to rewrite the entire city from the inside out.")
		if not is_inside_tree(): return

	await DialogueManager.say("Kaelen (Internal)", "Injecting commands through the timing signal. It's elegant and terrifying — like hiding malware in a system clock's interrupt handler. Every process in the city syncs to this tower, so every process receives the payload.")
	if not is_inside_tree(): return

	if has_elara:
		await DialogueManager.say("Elara", "The Administrator. It has to be. They're not just monitoring Ironhold — they're actively corrupting it. Rewriting the citizens, the guards, the infrastructure. Turning the city into something... else.")
		if not is_inside_tree(): return
	else:
		await DialogueManager.say("Kaelen (Internal)", "The Administrator. Not just watching — actively rewriting. Citizens, guards, infrastructure — all being converted into something the Administrator needs. And no one here understands what's happening to them.")
		if not is_inside_tree(): return

	await DialogueManager.say("Kaelen", "Then the automaton at the top isn't just a guardian — it's a relay. A corrupted process amplifying the Administrator's signal. We have to shut it down.")
	if not is_inside_tree(): return

	if has_elara:
		await DialogueManager.say("Elara", "*gripping her staff* Then we climb. And we break whatever is at the top of this tower.")
		if not is_inside_tree(): return
	else:
		await DialogueManager.say("Kaelen", "*clenching fists* Then I climb. And I break whatever is waiting at the top.")
		if not is_inside_tree(): return
		if _has_flag("ch1_knight_killed"):
			await DialogueManager.say("Kaelen (Internal)", "Another thing to destroy. I'm getting good at that. Maybe too good.")
			if not is_inside_tree(): return

	DialogueManager.hide_dialogue()

func _on_boss_trigger(body) -> void:
	if not body.is_in_group("player") or _pre_boss_done:
		return
	_pre_boss_done = true
	_pre_boss_dialogue()

func _pre_boss_dialogue() -> void:
	## Dialogue before the Clockwork Automaton fight
	var has_elara = _has_elara()
	GameManager.change_state(GameManager.GameState.COMBAT)

	await DialogueManager.say("Kaelen", "There it is. The Clockwork Automaton — the master regulator of the tower. And it's been completely corrupted.")
	if not is_inside_tree(): return

	if has_elara:
		await DialogueManager.say("Elara", "Look at its core. That's not standard clockwork energy — it's Administrator code. Purple and black, threaded through every gear. The Automaton has been reprogrammed.")
		if not is_inside_tree(): return
	else:
		await DialogueManager.say("Kaelen (Internal)", "The core... that's not normal clockwork energy. Purple and black corruption threads through every gear. Administrator code — this thing has been completely reprogrammed. And I have to fight it alone.")
		if not is_inside_tree(): return

	await DialogueManager.say("System", "[BOSS ENCOUNTER: CLOCKWORK AUTOMATON]\n[Class: Corrupted Temporal Relay]\n[Threat Level: SEVERE]\n[Phases: 3 — Gear Assault / Temporal Shockwave / Core Overload]", Color(1, 0.5, 0), true)
	if not is_inside_tree(): return

	await DialogueManager.say("Kaelen", "Three-phase combat pattern. Predictable gears first, then it speeds up. If we can survive long enough, it should expose its core. That's our window.")
	if not is_inside_tree(): return

	if has_elara:
		await DialogueManager.say("Elara", "I'll channel what temporal energy I can to slow its attacks. You find the opening. Together, Kaelen — we can do this.")
		if not is_inside_tree(): return
	else:
		await DialogueManager.say("Kaelen", "*activating Root Access* No backup. No partner. Just me and whatever I've become since I arrived in this world.")
		if not is_inside_tree(): return
		if _has_flag("ch2_data_wraith_absorbed"):
			await DialogueManager.say("System", "[ROOT ACCESS: WRAITH ABSORPTION AMPLIFYING]\n[Temporal Drain: READY]\n[Warning: Extended use will increase corruption]\n[Current Corruption: %d%%]" % int(GameManager.glitch_meter), Color(0.8, 0.4, 1.0), true)
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
	## React to boss phase transitions with screen effects and dialogue
	var has_elara = _has_elara()
	if camera and camera.has_method("shake"):
		camera.shake(12.0, 0.6)

	match new_phase:
		2:
			if has_elara:
				await DialogueManager.say("Elara", "It's accelerating! The temporal field around it just doubled — watch for shockwaves!")
				if not is_inside_tree(): return
			else:
				await DialogueManager.say("Kaelen", "It's speeding up! The temporal field just doubled — shockwaves incoming!")
				if not is_inside_tree(): return
			DialogueManager.hide_dialogue()
		3:
			await DialogueManager.say("Kaelen", "The core! It's destabilizing — the corruption can't hold. One more push!")
			if not is_inside_tree(): return
			if has_elara:
				await DialogueManager.say("Elara", "Now, Kaelen! Strike while the core is exposed!")
				if not is_inside_tree(): return
			else:
				await DialogueManager.say("Kaelen", "*gathering Root Access energy* NOW. While it's open!")
				if not is_inside_tree(): return
			DialogueManager.hide_dialogue()

func _on_automaton_defeated() -> void:
	## Clockwork Automaton boss defeated — major story progression
	automaton_defeated = true
	var has_elara = _has_elara()
	GameManager.set_story_flag("ch2_clockwork_automaton_defeated", true)
	GameManager.auto_save()  # Autosave on boss defeat

	# Screen flash on defeat
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

	# Post-boss dialogue — major story revelation
	await DialogueManager.say("Kaelen", "*breathing heavily* It's down. The master regulator is destroyed.")
	if not is_inside_tree(): return

	if has_elara:
		await DialogueManager.say("Elara", "And look — the override signal! It's collapsing! The data streams are clearing!")
		if not is_inside_tree(): return
	else:
		await DialogueManager.say("Kaelen", "*looking up* The override signal... it's collapsing. The data streams running through the walls are clearing.")
		if not is_inside_tree(): return

	await DialogueManager.say("System", "[CLOCKWORK AUTOMATON: OFFLINE]\n[Administrative Override Signal: SEVERED]\n[Ironhold Tick Rate: STABILIZING]\n[Corruption injection: HALTED — LOCALLY]", Color(0, 1, 0.5), true)
	if not is_inside_tree(): return

	await DialogueManager.say("Kaelen", "Locally. That's the key word. We stopped the signal HERE, but the Administrator is broadcasting from somewhere else. Other cities, other regions — they're all still being corrupted.")
	if not is_inside_tree(): return

	if has_elara:
		await DialogueManager.say("Elara", "*staring at exposed data streams* Kaelen, look at this. The override commands — I can read fragments of them now that the relay is down.")
		if not is_inside_tree(): return
		await DialogueManager.say("Elara", "These aren't just corruption payloads. They're REWRITE orders. The Administrator isn't breaking things — it's rebuilding them. Recompiling cities, NPCs, entire ecosystems into something new.")
		if not is_inside_tree(): return
	else:
		await DialogueManager.say("Kaelen", "*examining the exposed data streams* Now that the relay is down, I can read fragments of the override commands. These aren't just corruption payloads...")
		if not is_inside_tree(): return
		await DialogueManager.say("Kaelen", "They're REWRITE orders. The Administrator isn't breaking things — it's rebuilding them. Recompiling cities, NPCs, ecosystems into something entirely new. Something it needs.")
		if not is_inside_tree(): return

	await DialogueManager.say("Kaelen (Internal)", "Recompilation. The Administrator is actively corrupting cities — not destroying them, but transforming them. Converting them into infrastructure for something larger. A network. A system within the system.")
	if not is_inside_tree(): return

	await DialogueManager.say("Kaelen", "The Administrator is actively corrupting cities across Aethelgard. Ironhold was just one node. If this signal was relayed from the tower to every process in the city, then every major city must have a similar relay.")
	if not is_inside_tree(): return

	if has_elara:
		await DialogueManager.say("Elara", "Then destroying one relay isn't enough. We need to find the source — the Administrator itself. And to do that, we need more Source Key Fragments. They're the only things that can unlock the deeper layers of the system.")
		if not is_inside_tree(): return
		await DialogueManager.say("Kaelen", "How many do we have now?")
		if not is_inside_tree(): return
		await DialogueManager.say("Elara", "Two of seven. But each one we collect makes us more visible to the Administrator. Destroying this relay just sent up a flare. It knows we're here now.")
		if not is_inside_tree(): return
	else:
		await DialogueManager.say("Kaelen", "Destroying one relay isn't enough. I need the source — the Administrator itself. And the Source Key Fragments are the only way to unlock the deeper system layers.")
		if not is_inside_tree(): return
		await DialogueManager.say("Kaelen (Internal)", "Two of seven fragments collected. Each one makes me more visible. And destroying this relay just sent up a flare the size of a supernova. The Administrator knows exactly where I am now.")
		if not is_inside_tree(): return
		if _has_flag("ch1_knight_killed") and _has_flag("ch2_data_wraith_absorbed"):
			await DialogueManager.say("Kaelen (Internal)", "Knight deleted. Wraith absorbed. Relay destroyed. I'm leaving a trail of destruction across this world. Is that what Root Access is turning me into? Or is that just... me?")
			if not is_inside_tree(): return

	await DialogueManager.say("System", "[WARNING: ADMINISTRATIVE AWARENESS ELEVATED]\n[Threat response protocols: ACTIVATING]\n[The 72-hour countdown accelerates — remaining time: REDUCED]", Color(1, 0, 0), true)
	if not is_inside_tree(): return

	await DialogueManager.say("Kaelen", "The countdown we picked up at the gate — it just got worse. The Administrator knows we're here now.")
	if not is_inside_tree(): return

	if has_elara:
		await DialogueManager.say("Elara", "Then we'd better make those hours count. Let's get back to Ironhold — the city should be recovering now that the corruption signal is cut. But we need to prepare for what's coming.")
		if not is_inside_tree(): return
	else:
		await DialogueManager.say("Kaelen", "Then every hour counts. Ironhold should be recovering now. Time to get back and prepare for what's coming next.")
		if not is_inside_tree(): return

	GameManager.set_story_flag("ch2_clock_tower_complete", true)
	DialogueManager.hide_dialogue()

	# Return to Ironhold
	await get_tree().create_timer(2.0).timeout
	if not is_inside_tree(): return
	SceneTransitions.change_scene("res://scenes/regions/ironhold_region.tscn")
