extends EnemyBase
class_name CorruptionElemental

## Corruption Elemental — Absorbs damage to charge, then explodes in an AoE burst.
## Unique mechanic: Has a "charge meter" that fills as it takes damage. When full,
## it releases a devastating corruption burst. Player must kill it quickly or retreat
## when it's about to blow. Applies corruption on hit.

var _charge_meter: float = 0.0
var _charge_max: float = 80.0  # Damage absorbed before explosion
var _explosion_damage: float = 35.0
var _explosion_radius: float = 150.0
var _corruption_on_hit: float = 2.0  # Corruption per contact
var _is_charging: bool = false
var _is_exploding: bool = false
var _pulse_timer: float = 0.0
var _pulse_interval: float = 0.5
var _charge_visual_scale: float = 1.0


func _ready() -> void:
	enemy_name = "Corruption Elemental"
	max_health = 70.0
	current_health = max_health
	contact_damage = 18.0
	movement_speed = 85.0
	detection_range = 300.0
	attack_range = 100.0
	xp_reward = 65
	gold_reward = 40
	elasticity = 0.5
	gravity_scale = 0.3  # Floats slightly
	attack_cooldown = 2.0
	super._ready()

	# Visual: glowing corruption purple
	if has_node("Sprite") and get_node("Sprite") is ColorRect:
		var sprite = get_node("Sprite") as ColorRect
		sprite.color = Color(0.6, 0.1, 0.5)

var _pulse_tween: Tween = null


func _ai_behavior(delta: float) -> void:
	_pulse_timer += delta

	# Visual pulsing based on charge level
	if _charge_meter > 0.0 and _pulse_timer >= _pulse_interval:
		_pulse_timer = 0.0
		_pulse_visual()

	if _is_exploding:
		return

	match current_state:
		State.IDLE:
			_idle_behavior(delta)
		State.CHASE:
			_chase_behavior(delta)
		State.ATTACK:
			_attack_behavior(delta)
		State.STUNNED:
			velocity.x = move_toward(velocity.x, 0.0, 200.0 * delta)


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

	var dir = direction_to_player()
	velocity.x = dir.x * movement_speed
	# Slight hover
	velocity.y = sin(Time.get_ticks_msec() / 500.0) * 30.0


func _attack_behavior(_delta: float) -> void:
	var dist = distance_to_player()

	if dist > attack_range * 2.5:
		current_state = State.CHASE
		return

	# Move toward player aggressively when charged
	var speed_boost = 1.0 + (_charge_meter / _charge_max) * 0.5
	var dir = direction_to_player()
	velocity.x = dir.x * movement_speed * speed_boost

	# Apply corruption on close contact
	if dist < 60.0:
		_apply_corruption_to_player()

	# Check for explosion threshold
	if _charge_meter >= _charge_max:
		_start_explosion()


## Override take_damage to charge the meter
func take_damage(amount: float, knockback_source: Vector2 = Vector2.ZERO) -> void:
	# Absorb portion of damage into charge meter
	var absorbed: float = amount * 0.4  # 40% of damage goes to charge
	_charge_meter = minf(_charge_meter + absorbed, _charge_max)

	# Update visual scale based on charge
	_charge_visual_scale = 1.0 + (_charge_meter / _charge_max) * 0.4
	if has_node("Sprite"):
		var sprite = get_node("Sprite")
		sprite.scale = Vector2(_charge_visual_scale, _charge_visual_scale)

	# Show charge level warning
	var charge_pct = int((_charge_meter / _charge_max) * 100.0)
	if charge_pct >= 75 and has_node("/root/VFXLibrary"):
		VFXLibrary.spawn_status_indicator("CRITICAL!", global_position + Vector2(0, -60), get_parent(), false)

	# Still take the full damage to health
	super.take_damage(amount, knockback_source)

	# Check if charge is full
	if _charge_meter >= _charge_max and current_state != State.DEAD:
		_start_explosion()


func _apply_corruption_to_player() -> void:
	if has_node("/root/GameManager"):
		# Multiply by physics delta to be framerate-independent
		var delta = get_physics_process_delta_time()
		GameManager.add_glitch_corruption(_corruption_on_hit * 0.02 * delta * 60.0)  # Balanced for 60fps


func _pulse_visual() -> void:
	if not has_node("Sprite"):
		return
	var sprite = get_node("Sprite")
	var charge_ratio = _charge_meter / _charge_max
	var pulse_color: Color

	if charge_ratio < 0.5:
		pulse_color = Color(0.6, 0.1, 0.5).lerp(Color(0.8, 0.3, 0.1), charge_ratio * 2.0)
	else:
		pulse_color = Color(0.8, 0.3, 0.1).lerp(Color(1.0, 0.1, 0.1), (charge_ratio - 0.5) * 2.0)

	if _pulse_tween and _pulse_tween.is_valid():
		_pulse_tween.kill()
	_pulse_tween = create_tween()
	_pulse_tween.tween_property(sprite, "modulate", pulse_color, 0.15)
	_pulse_tween.tween_property(sprite, "modulate", Color.WHITE, 0.15)


func _start_explosion() -> void:
	if _is_exploding or current_state == State.DEAD:
		return

	_is_exploding = true
	velocity = Vector2.ZERO

	# Visual warning: rapid flashing and growing
	if has_node("Sprite"):
		var sprite = get_node("Sprite")
		var tw = create_tween()
		for i in range(5):
			tw.tween_property(sprite, "modulate", Color(1, 0, 0), 0.08)
			tw.tween_property(sprite, "modulate", Color(1, 1, 0), 0.08)
		tw.tween_property(sprite, "scale", Vector2(2.0, 2.0), 0.3)

	if has_node("/root/VFXLibrary"):
		VFXLibrary.spawn_status_indicator("!! DETONATING !!", global_position + Vector2(0, -70), get_parent(), false)

	await get_tree().create_timer(0.8, false).timeout
	if not is_inside_tree() or current_state == State.DEAD:
		return

	# EXPLODE
	_do_explosion()

	# Kill self
	die()


func _do_explosion() -> void:
	# Area damage to all players within radius
	var players = get_tree().get_nodes_in_group("player")
	for p in players:
		if not is_instance_valid(p):
			continue
		var dist = p.global_position.distance_to(global_position)
		if dist < _explosion_radius:
			# Damage falls off with distance
			var falloff = 1.0 - (dist / _explosion_radius)
			var dmg = _explosion_damage * falloff
			if p.has_method("take_damage"):
				p.take_damage(dmg)

	# Apply corruption
	if has_node("/root/GameManager"):
		GameManager.add_glitch_corruption(3.0)

	# Visual: screen shake and VFX
	if has_node("/root/CombatFX"):
		CombatFX.apply_screen_shake(25.0, 0.5)
		CombatFX.apply_hitstop(0.2)

	# Spawn explosion particles
	if has_node("/root/VFXLibrary"):
		for i in range(8):
			var angle = (i / 8.0) * TAU
			var offset = Vector2(cos(angle), sin(angle)) * 40.0
			VFXLibrary.spawn_pickup_text("*corrupt*", global_position + offset, get_parent(), Color(0.8, 0.1, 0.4))
