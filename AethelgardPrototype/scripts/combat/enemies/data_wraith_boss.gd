extends EnemyBase
class_name DataWraithBoss

## Data Wraith — Mini-boss in the Underground Network. Corrupted system process.
## Attacks with corruption fields, data tendrils, and corruption lunges.
## Phase 1: Normal.  Phase 2 (<50 % HP): Enraged — faster, more tendrils.

signal boss_defeated

var attack_timer: float = 0.0
var _corruption_field_timer: float = 0.0
var _corruption_field_cd: float = 8.0
var _tendril_timer: float = 0.0
var _tendril_cd: float = 4.0
var phase: int = 1
var is_attacking: bool = false
var _active_tendrils: Array = []
var _active_fields: Array = []


func _ready() -> void:
	# Set boss stats BEFORE super._ready() so level scaling applies correctly
	enemy_name = "Data Wraith"
	xp_reward = 500
	gold_reward = 250
	attack_cooldown = 1.6
	movement_speed = 100.0
	max_health = 800.0
	contact_damage = 50.0
	detection_range = 450.0
	attack_range = 130.0
	zone_level = 7  # Rec Lv 7 — Fractured Wastes boss
	elasticity = 1.0
	gravity_scale = 0.2  # Floats ominously
	super._ready()
	current_health = max_health

	add_to_group("boss")

	if has_node("/root/GameManager"):
		GameManager.start_boss_fight()


func _ai_behavior(delta: float) -> void:
	# Phase transition
	if current_health <= max_health * 0.5 and phase == 1:
		_enter_phase_2()

	attack_timer += delta
	_corruption_field_timer += delta
	_tendril_timer += delta

	match current_state:
		State.IDLE:
			_idle(delta)
		State.CHASE:
			_chase(delta)
		State.ATTACK:
			_attack(delta)
		State.STUNNED:
			velocity.x = move_toward(velocity.x, 0.0, 200.0 * delta)


func _enter_phase_2() -> void:
	phase = 2
	attack_cooldown = 1.4
	_tendril_cd = 2.5
	_corruption_field_cd = 5.0
	movement_speed = 110.0

	# Full phase transition juice
	if has_node("/root/GameJuice"):
		GameJuice.boss_phase_transition()
	else:
		_screen_shake(12.0, 0.3)
		_hitstop(0.1)

	_vfx("vfx_glitch_sparkle", global_position)
	_vfx("vfx_glitch_sparkle", global_position + Vector2(20, -30))
	_vfx("vfx_glitch_sparkle", global_position + Vector2(-20, -30))
	_status_text("CORRUPTED SURGE!", global_position + Vector2(0, -50), false)

	if has_node("Sprite"):
		var spr = get_node("Sprite")
		var tw = create_tween()
		tw.tween_property(spr, "modulate", Color(2.0, 0.5, 3.0), 0.05)
		tw.tween_property(spr, "modulate", Color(0.8, 0.0, 1.0), 0.45)


func _idle(_delta: float) -> void:
	velocity.x = sin(attack_timer * 0.3) * 20.0
	velocity.y = cos(attack_timer * 0.5) * 15.0
	if is_hostile and distance_to_player() < detection_range:
		current_state = State.CHASE


func _chase(_delta: float) -> void:
	var dist = distance_to_player()
	if dist > detection_range * 2.0:
		current_state = State.IDLE
		return
	if dist < attack_range:
		current_state = State.ATTACK
		return
	var dir = direction_to_player()
	velocity.x = dir.x * movement_speed
	velocity.y = dir.y * movement_speed * 0.3


func _attack(_delta: float) -> void:
	if is_attacking:
		return
	var dist = distance_to_player()
	if dist > attack_range * 2.5:
		current_state = State.CHASE
		return

	# Corruption field (area denial)
	if _corruption_field_timer >= _corruption_field_cd:
		_spawn_corruption_field()
		_corruption_field_timer = 0.0
		return

	# Data tendrils (ranged)
	if _tendril_timer >= _tendril_cd and dist > 60.0:
		_shoot_tendrils()
		_tendril_timer = 0.0
		return

	# Melee lunge
	if attack_timer >= attack_cooldown and not is_attacking:
		_corruption_lunge()
		attack_timer = 0.0


# ═════════════════════════════════════════════════════════════════════════
# ATTACKS
# ═════════════════════════════════════════════════════════════════════════

func _corruption_lunge() -> void:
	if current_state == State.DEAD:
		return
	is_attacking = true
	var dir = direction_to_player()
	velocity.x = dir.x * movement_speed * 3.0
	velocity.y = -50.0
	_vfx("vfx_glitch_sparkle", global_position)

	await get_tree().create_timer(0.3).timeout
	if not _safe():
		is_attacking = false
		return

	_check_player_hit()
	is_attacking = false


func _spawn_corruption_field() -> void:
	if current_state == State.DEAD:
		return
	var player = find_player()
	if not player:
		return

	var field = ColorRect.new()
	field.color = Color(0.5, 0.0, 0.8, 0.4)
	field.size = Vector2(150, 30)
	field.mouse_filter = Control.MOUSE_FILTER_IGNORE
	get_parent().add_child(field)
	field.global_position = Vector2(player.global_position.x - 75, player.global_position.y)
	_active_fields.append(field)

	_status_text("CORRUPTION ZONE!", player.global_position + Vector2(0, -60), false)

	for i in 5:
		await get_tree().create_timer(0.6).timeout
		if not _safe():
			if is_instance_valid(field):
				field.queue_free()
			_active_fields.erase(field)
			return
		if not is_instance_valid(field):
			break
		if is_instance_valid(player) and player.has_method("take_damage"):
			var fd = absf(player.global_position.x - (field.global_position.x + 75))
			if fd < 80.0:
				player.take_damage(8.0, global_position, enemy_name, "boss")

	_active_fields.erase(field)
	if is_instance_valid(field):
		var fade = field.create_tween()
		fade.tween_property(field, "modulate:a", 0.0, 0.5)
		fade.tween_callback(field.queue_free)


func _shoot_tendrils() -> void:
	if current_state == State.DEAD:
		return
	var player = find_player()
	if not player:
		return
	var base_dir = (player.global_position - global_position).normalized()
	var count = 2 if phase == 1 else 3
	for i in count:
		var offset = (i - (count - 1) / 2.0) * 0.3
		_fire_tendril(base_dir.rotated(offset))
	_vfx("vfx_hit_spark", global_position)


func _fire_tendril(direction: Vector2) -> void:
	var tendril = ColorRect.new()
	tendril.color = Color(0.6, 0.0, 1.0, 0.8)
	tendril.size = Vector2(20, 8)
	tendril.rotation = direction.angle()
	tendril.mouse_filter = Control.MOUSE_FILTER_IGNORE
	get_parent().add_child(tendril)
	tendril.global_position = global_position
	_active_tendrils.append(tendril)

	var speed = 250.0
	var elapsed = 0.0
	while elapsed < 2.0 and is_instance_valid(tendril) and _safe():
		tendril.global_position += direction * speed * get_process_delta_time()
		elapsed += get_process_delta_time()
		var player = find_player()
		if player and player.has_method("take_damage"):
			if tendril.global_position.distance_to(player.global_position) < 25.0:
				player.take_damage(contact_damage * 0.5, tendril.global_position, enemy_name, "boss")
				tendril.queue_free()
				_active_tendrils.erase(tendril)
				return
		await get_tree().process_frame
		if not is_inside_tree():
			if is_instance_valid(tendril):
				tendril.queue_free()
			_active_tendrils.erase(tendril)
			return
	_active_tendrils.erase(tendril)
	if is_instance_valid(tendril):
		tendril.queue_free()


func _check_player_hit() -> void:
	if current_state == State.DEAD or not is_hostile:
		return
	var player = find_player()
	if player and player.has_method("take_damage"):
		if global_position.distance_to(player.global_position) < 65.0:
			player.take_damage(contact_damage, global_position, enemy_name, "boss")


# ═════════════════════════════════════════════════════════════════════════
# DEATH
# ═════════════════════════════════════════════════════════════════════════

func die() -> void:
	if current_state == State.DEAD:
		return
	current_state = State.DEAD
	velocity = Vector2.ZERO
	set_physics_process(false)
	if has_node("/root/GameManager"):
		GameManager.end_boss_fight()
	boss_defeated.emit()
	# Full boss death juice
	if has_node("/root/GameJuice"):
		GameJuice.boss_death_sequence()
	# Clean up all active projectiles
	for t in _active_tendrils:
		if is_instance_valid(t):
			t.queue_free()
	_active_tendrils.clear()
	for f in _active_fields:
		if is_instance_valid(f):
			f.queue_free()
	_active_fields.clear()
	for i in 5:
		var offset = Vector2(randf_range(-30, 30), randf_range(-40, 10))
		_vfx("vfx_enemy_death", global_position + offset)
		await get_tree().create_timer(0.2).timeout
		if not is_inside_tree():
			return
	super.die()
