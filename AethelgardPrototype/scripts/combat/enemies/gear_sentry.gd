extends EnemyBase
class_name GearSentry

## Gear Sentry — Stationary turret enemy found in Ironhold/mechanical zones.
## Unique mechanic: Cannot move. Rotates to track player and fires gear projectiles
## in patterns (single shot → burst → spread). Can be hacked to friendly turret mode.
## Has high HP and armor but is completely stationary.

var _fire_cooldown: float = 2.0
var _fire_timer: float = 0.0
var _burst_count: int = 0
var _max_burst: int = 3
var _burst_delay: float = 0.3
var _is_firing: bool = false
var _gear_speed: float = 250.0
var _gear_damage: float = 15.0
var _fire_pattern: int = 0  # 0 = single, 1 = burst, 2 = spread
var _pattern_cycle: int = 0
var _armor: float = 5.0  # Damage reduction


func _ready() -> void:
	enemy_name = "Gear Sentry"
	max_health = 100.0
	current_health = max_health
	contact_damage = 20.0
	movement_speed = 0.0  # Cannot move
	detection_range = 450.0
	attack_range = 400.0
	xp_reward = 55
	gold_reward = 30
	elasticity = 0.0
	gravity_scale = 1.0
	attack_cooldown = _fire_cooldown
	super._ready()

	# Visual: make it look like a turret
	if has_node("Sprite") and get_node("Sprite") is ColorRect:
		var sprite = get_node("Sprite") as ColorRect
		sprite.color = Color(0.55, 0.45, 0.25)  # Bronze/copper


func _ai_behavior(delta: float) -> void:
	# Sentry NEVER moves
	velocity.x = 0.0

	_fire_timer += delta

	match current_state:
		State.IDLE:
			if is_hostile and distance_to_player() < detection_range:
				current_state = State.ATTACK
		State.ATTACK:
			_attack_behavior(delta)
		State.STUNNED:
			pass  # Just wait out stun


func _attack_behavior(_delta: float) -> void:
	var dist = distance_to_player()

	if dist > detection_range * 1.2:
		current_state = State.IDLE
		return

	if _is_firing:
		return

	if _fire_timer >= _fire_cooldown:
		_fire_timer = 0.0
		_start_fire_pattern()


func _start_fire_pattern() -> void:
	if current_state == State.DEAD:
		return

	# Cycle through patterns: single → burst → spread → repeat
	_fire_pattern = _pattern_cycle % 3
	_pattern_cycle += 1

	match _fire_pattern:
		0:
			_fire_single()
		1:
			_fire_burst()
		2:
			_fire_spread()


func _fire_single() -> void:
	# Telegraph: flash red briefly
	_telegraph_flash()
	await get_tree().create_timer(0.4, false).timeout
	if not is_inside_tree() or current_state == State.DEAD:
		return
	_spawn_gear_projectile(direction_to_player())


func _fire_burst() -> void:
	_is_firing = true
	_telegraph_flash()
	await get_tree().create_timer(0.3, false).timeout

	for i in range(_max_burst):
		if not is_inside_tree() or current_state == State.DEAD:
			break
		_spawn_gear_projectile(direction_to_player())
		await get_tree().create_timer(_burst_delay, false).timeout

	_is_firing = false


func _fire_spread() -> void:
	_telegraph_flash()
	await get_tree().create_timer(0.5, false).timeout
	if not is_inside_tree() or current_state == State.DEAD:
		return

	# Fire 3 projectiles in a fan pattern
	var base_dir = direction_to_player()
	var angle = atan2(base_dir.y, base_dir.x)

	for i in range(3):
		var spread_angle = angle + (i - 1) * 0.35  # ~20 degree spread
		var dir = Vector2(cos(spread_angle), sin(spread_angle))
		_spawn_gear_projectile(dir)


func _telegraph_flash() -> void:
	if has_node("Sprite"):
		var sprite = get_node("Sprite")
		var tw = create_tween()
		tw.tween_property(sprite, "modulate", Color(1.0, 0.2, 0.1), 0.1)
		tw.tween_property(sprite, "modulate", Color.WHITE, 0.1)


func _spawn_gear_projectile(dir: Vector2) -> void:
	# Create a simple projectile node
	var proj = Area2D.new()
	proj.name = "GearProjectile"

	# Visual
	var visual = ColorRect.new()
	visual.size = Vector2(12, 12)
	visual.position = Vector2(-6, -6)
	visual.color = Color(0.7, 0.5, 0.15)
	visual.mouse_filter = Control.MOUSE_FILTER_IGNORE
	proj.add_child(visual)

	# Collision (hits player)
	var col = CollisionShape2D.new()
	var shape = CircleShape2D.new()
	shape.radius = 6.0
	col.shape = shape
	proj.add_child(col)

	proj.collision_layer = 8   # Projectile layer
	proj.collision_mask = 2    # Player layer

	proj.global_position = global_position + Vector2(0, -20)

	# Store velocity and damage as meta
	proj.set_meta("velocity", dir.normalized() * _gear_speed)
	proj.set_meta("damage", _gear_damage)
	proj.set_meta("lifetime", 4.0)

	# Add to scene
	if get_parent():
		get_parent().add_child(proj)

	# Connect body entered for damage
	proj.body_entered.connect(_on_gear_hit_body.bind(proj))

	# Auto-destroy after lifetime
	_gear_projectile_lifetime(proj)


func _gear_projectile_lifetime(proj: Area2D) -> void:
	var lifetime: float = 4.0
	var vel: Vector2 = proj.get_meta("velocity", Vector2.ZERO) if is_instance_valid(proj) else Vector2.ZERO

	# Move projectile manually via a tween
	if is_instance_valid(proj):
		var end_pos = proj.global_position + vel * lifetime
		# Owned by the projectile: a tween on the sentry died with it, leaving
		# its gears frozen in mid-air for the rest of the scene.
		var tw = proj.create_tween()
		tw.tween_property(proj, "global_position", end_pos, lifetime)
		tw.tween_callback(func():
			if is_instance_valid(proj):
				proj.queue_free()
		)


func _on_gear_hit_body(body: Node2D, proj: Area2D) -> void:
	if body.is_in_group("player") and body.has_method("take_damage"):
		var dmg: float = proj.get_meta("damage", _gear_damage) if is_instance_valid(proj) else _gear_damage
		body.take_damage(dmg)
		if has_node("/root/CombatFX"):
			CombatFX.apply_screen_shake(5.0, 0.15)
	if is_instance_valid(proj):
		proj.queue_free()


## Override take_damage to apply armor reduction
func take_damage(amount: float, knockback_source: Vector2 = Vector2.ZERO) -> void:
	var reduced = maxf(amount - _armor, 1.0)
	super.take_damage(reduced, knockback_source)
