extends EnemyBase
class_name PhaseSpider

## Phase Spider — Teleports to ceiling, drops down for ambush attacks.
## Unique mechanic: Phases between ceiling and ground. Drops web traps
## that slow player. Can teleport behind player for backstab attacks.
## Fast, fragile, and highly mobile — punishes slow reactions.

var _phase_cooldown: float = 3.5
var _phase_timer: float = 0.0
var _is_on_ceiling: bool = false
var _drop_attack_speed: float = 500.0
var _drop_damage: float = 22.0
var _web_cooldown: float = 5.0
var _web_timer: float = 0.0
var _teleport_cooldown: float = 4.0
var _teleport_timer: float = 0.0
var _is_dropping: bool = false
## How far above its current height the spider phases (was an absolute y=50,
## which could be off-screen or outside the arena).
const CEILING_RISE: float = 200.0
## Seconds it hangs on the ceiling before the telegraphed drop.
const CEILING_HANG_TIME: float = 0.8
var _ground_y: float = 400.0  # Y position when on ground
var _original_position: Vector2 = Vector2.ZERO


func _ready() -> void:
	enemy_name = "Phase Spider"
	max_health = 45.0
	current_health = max_health
	contact_damage = 16.0
	movement_speed = 160.0
	detection_range = 350.0
	attack_range = 120.0
	xp_reward = 50
	gold_reward = 28
	elasticity = 1.2
	gravity_scale = 1.0
	attack_cooldown = 1.5
	super._ready()

	_original_position = global_position
	_ground_y = global_position.y

	# Visual: dark purple spider look
	if has_node("Sprite") and get_node("Sprite") is ColorRect:
		var sprite = get_node("Sprite") as ColorRect
		sprite.color = Color(0.35, 0.1, 0.45)


func _ai_behavior(delta: float) -> void:
	_phase_timer += delta
	_web_timer += delta
	_teleport_timer += delta

	if _is_dropping:
		return  # Don't interrupt drop attack

	# On the ceiling, always come back down. The drop used to start only from
	# ATTACK, which is unreachable from up there (the vertical gap alone exceeds
	# attack_range), so the spider stayed on the ceiling forever — unkillable,
	# and the encounter could never be won.
	if _is_on_ceiling:
		if _phase_timer >= CEILING_HANG_TIME:
			_start_drop_attack()
		return

	match current_state:
		State.IDLE:
			_idle_behavior(delta)
		State.CHASE:
			_chase_behavior(delta)
		State.ATTACK:
			_attack_behavior(delta)
		State.STUNNED:
			velocity.x = move_toward(velocity.x, 0.0, 400.0 * delta)


func _idle_behavior(_delta: float) -> void:
	velocity.x = 0.0
	if is_hostile and distance_to_player() < detection_range:
		current_state = State.CHASE


func _chase_behavior(_delta: float) -> void:
	var dist = distance_to_player()

	if dist > detection_range * 1.5:
		current_state = State.IDLE
		return

	if dist < attack_range:
		current_state = State.ATTACK
		return

	# Move toward player quickly
	var dir = direction_to_player()
	velocity.x = dir.x * movement_speed

	# Try to phase to ceiling for drop attack
	if not _is_on_ceiling and _phase_timer >= _phase_cooldown and dist < 250.0:
		_phase_to_ceiling()


func _attack_behavior(delta: float) -> void:
	var dist = distance_to_player()

	if dist > attack_range * 3.0:
		current_state = State.CHASE
		return

	# On ceiling → drop attack
	if _is_on_ceiling:
		_start_drop_attack()
		return

	# On ground → try teleport behind player or web trap
	if _teleport_timer >= _teleport_cooldown and dist < 200.0:
		_teleport_behind_player()
	elif _web_timer >= _web_cooldown:
		_drop_web_trap()

	# Basic chase while on ground
	var dir = direction_to_player()
	velocity.x = dir.x * movement_speed * 0.7

	# Phase to ceiling if cooldown ready
	if _phase_timer >= _phase_cooldown:
		_phase_to_ceiling()


func _phase_to_ceiling() -> void:
	if _is_on_ceiling or current_state == State.DEAD:
		return

	_is_on_ceiling = true
	_phase_timer = 0.0
	gravity_scale = 0.0

	# Visual: fade up to ceiling
	if has_node("Sprite"):
		var sprite = get_node("Sprite")
		var tw = create_tween()
		tw.tween_property(sprite, "modulate:a", 0.3, 0.2)
		tw.parallel().tween_property(self, "global_position:y", global_position.y - CEILING_RISE, 0.3)

	if has_node("/root/VFXLibrary"):
		VFXLibrary.spawn_status_indicator("*phases*", global_position + Vector2(0, -30), get_parent(), false)


func _start_drop_attack() -> void:
	if _is_dropping or current_state == State.DEAD:
		return

	_is_dropping = true

	# Position above player
	var players = get_tree().get_nodes_in_group("player")
	if players.is_empty():
		_is_dropping = false
		return

	var player_pos: Vector2 = (players[0] as Node2D).global_position

	# Telegraph: red flash while on ceiling
	if has_node("Sprite"):
		var sprite = get_node("Sprite")
		var tw = create_tween()
		tw.tween_property(sprite, "modulate", Color(1.0, 0.2, 0.2, 0.8), 0.15)
	
	# Move above player
	global_position.x = player_pos.x

	await get_tree().create_timer(0.4, false).timeout
	if not is_inside_tree() or current_state == State.DEAD:
		_is_dropping = false
		return

	# Drop!
	_is_on_ceiling = false
	gravity_scale = 1.0

	if has_node("Sprite"):
		var sprite = get_node("Sprite")
		var tw = create_tween()
		tw.tween_property(sprite, "modulate", Color.WHITE, 0.1)

	velocity.y = _drop_attack_speed

	# Check for hit after landing
	await get_tree().create_timer(0.5, false).timeout
	_is_dropping = false

	if not is_inside_tree() or current_state == State.DEAD:
		return

	# Damage on impact
	var dist = distance_to_player()
	if dist < 80.0:
		var p_list = get_tree().get_nodes_in_group("player")
		for p in p_list:
			if is_instance_valid(p) and p.has_method("take_damage"):
				p.take_damage(_drop_damage)
		if has_node("/root/CombatFX"):
			CombatFX.apply_screen_shake(12.0, 0.25)
			CombatFX.apply_hitstop(0.12)

	current_state = State.CHASE


func _teleport_behind_player() -> void:
	if current_state == State.DEAD:
		return

	_teleport_timer = 0.0

	var players = get_tree().get_nodes_in_group("player")
	if players.is_empty():
		return
	var player_pos: Vector2 = (players[0] as Node2D).global_position

	# Visual: disappear
	if has_node("Sprite"):
		var sprite = get_node("Sprite")
		var tw = create_tween()
		tw.tween_property(sprite, "modulate:a", 0.0, 0.1)

	await get_tree().create_timer(0.15, false).timeout
	if not is_inside_tree() or current_state == State.DEAD:
		return

	# Teleport behind player
	var behind_offset = 80.0 if player_pos.x > global_position.x else -80.0
	global_position = Vector2(player_pos.x + behind_offset, player_pos.y)

	# Reappear
	if has_node("Sprite"):
		var sprite = get_node("Sprite")
		var tw = create_tween()
		tw.tween_property(sprite, "modulate:a", 1.0, 0.1)

	if has_node("/root/VFXLibrary"):
		VFXLibrary.spawn_status_indicator("*blink*", global_position + Vector2(0, -30), get_parent(), false)


func _drop_web_trap() -> void:
	if current_state == State.DEAD:
		return

	_web_timer = 0.0

	# Create a web trap area at player's position
	var players = get_tree().get_nodes_in_group("player")
	if players.is_empty():
		return

	var target_pos: Vector2 = (players[0] as Node2D).global_position

	var web = Area2D.new()
	web.name = "WebTrap"

	var visual = ColorRect.new()
	visual.size = Vector2(60, 10)
	visual.position = Vector2(-30, -5)
	visual.color = Color(0.8, 0.8, 0.9, 0.5)
	visual.mouse_filter = Control.MOUSE_FILTER_IGNORE
	web.add_child(visual)

	var col = CollisionShape2D.new()
	var shape = RectangleShape2D.new()
	shape.size = Vector2(60, 10)
	col.shape = shape
	web.add_child(col)

	web.collision_layer = 8
	web.collision_mask = 2
	web.global_position = target_pos

	if get_parent():
		get_parent().add_child(web)

	# Web lasts 6 seconds, slows player on contact
	web.body_entered.connect(func(body):
		if body.is_in_group("player") and body.has_method("apply_slow"):
			body.apply_slow(0.5, 2.0)  # 50% speed for 2 seconds
		elif body.is_in_group("player"):
			# Fallback: just do minor damage
			if body.has_method("take_damage"):
				body.take_damage(5.0)
	)

	# Auto-destroy. The web times itself out: an await here never resumed if the
	# spider died first, so its webs stayed on the floor slowing the player forever.
	var expire := web.create_tween()
	expire.tween_interval(6.0)
	expire.tween_callback(web.queue_free)
