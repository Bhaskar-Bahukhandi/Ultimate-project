extends EnemyBase
class_name ClockworkSoldier

## Clockwork Soldier — Slow, heavily armored melee enemy (Gold tier).
## Ground-slam shockwave attack. High HP, high armor, low speed.
## Telegraphs attacks clearly — reward for patience and dodge timing.

var _slam_cooldown: float = 3.5
var _slam_timer: float = 0.0
var _is_slamming: bool = false
var _armor: float = 8.0
var _slam_damage: float = 30.0
var _slam_range: float = 130.0
var _shockwave_range: float = 180.0


func _ready() -> void:
	enemy_name = "Clockwork Soldier"
	max_health = 120.0
	current_health = max_health
	contact_damage = 22.0
	movement_speed = 45.0
	detection_range = 250.0
	attack_range = 80.0
	xp_reward = 55
	gold_reward = 25
	elasticity = 1.0
	gravity_scale = 1.3  # Heavy
	attack_cooldown = _slam_cooldown
	super._ready()


func _ai_behavior(delta: float) -> void:
	_slam_timer += delta

	match current_state:
		State.IDLE:
			_idle_behavior(delta)
		State.CHASE:
			_chase_behavior(delta)
		State.ATTACK:
			_attack_behavior(delta)
		State.STUNNED:
			velocity.x = move_toward(velocity.x, 0.0, 150.0 * delta)


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


func _attack_behavior(_delta: float) -> void:
	var dist = distance_to_player()

	if dist > attack_range * 3.0:
		current_state = State.CHASE
		return

	if _is_slamming:
		return

	if _slam_timer >= _slam_cooldown:
		_ground_slam()
		_slam_timer = 0.0


func _ground_slam() -> void:
	## Wind up and slam the ground, creating a shockwave.
	if current_state == State.DEAD:
		return

	_is_slamming = true
	velocity.x = 0.0

	# Telegraph — raise arms (visual cue)
	if has_node("Sprite"):
		var sprite = get_node("Sprite")
		var tw = create_tween()
		tw.tween_property(sprite, "position:y", -15.0, 0.4)
		tw.tween_property(sprite, "position:y", 0.0, 0.1)

	_sfx("heavy_windup")
	_status_text("!", global_position + Vector2(0, -50), false)

	# Wind-up pause
	await get_tree().create_timer(0.5).timeout
	if not is_inside_tree() or current_state == State.DEAD:
		_is_slamming = false
		return

	# Slam impact
	_sfx("ground_slam")
	_screen_shake(14.0, 0.3)
	_vfx("vfx_hit_spark", global_position + Vector2(0, 10))

	# Direct hit
	_deal_damage_in_range(_slam_range, _slam_damage)

	# Shockwave — wider but weaker
	await get_tree().create_timer(0.1).timeout
	if not is_inside_tree() or current_state == State.DEAD:
		_is_slamming = false
		return

	_deal_damage_in_range(_shockwave_range, _slam_damage * 0.5)
	_vfx("vfx_hit_spark", global_position + Vector2(-60, 10))
	_vfx("vfx_hit_spark", global_position + Vector2(60, 10))

	# Recovery
	await get_tree().create_timer(0.8).timeout
	if not is_inside_tree() or current_state == State.DEAD:
		_is_slamming = false
		return

	_is_slamming = false


func take_damage(amount: float, knockback_source: Vector2 = Vector2.ZERO) -> void:
	## Heavy armor reduces all incoming damage.
	var final = maxf(amount - _armor, 1.0)
	super.take_damage(final, knockback_source)


func die() -> void:
	if current_state == State.DEAD:
		return
	_screen_shake(8.0, 0.2)
	_sfx("heavy_fall")
	_vfx("vfx_enemy_death", global_position)
	super.die()
