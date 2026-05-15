extends EnemyBase
class_name GlitchWolf

## Glitch Wolf — Teleports behind the player and pounces (Bronze tier arena).
## Fast, evasive predator. Uses short-range blinks to reposition before attacking.

var _teleport_cooldown: float = 3.5
var _teleport_timer: float = 0.0
var _pounce_range: float = 140.0
var _pounce_speed: float = 400.0
var _is_pouncing: bool = false
var _teleport_offset: float = 80.0
var _pounce_cooldown_timer: float = 0.0


func _ready() -> void:
	enemy_name = "Glitch Wolf"
	max_health = 40.0
	current_health = max_health
	contact_damage = 15.0
	movement_speed = 110.0
	detection_range = 350.0
	attack_range = 90.0
	xp_reward = 30
	gold_reward = 12
	elasticity = 1.0
	gravity_scale = 1.0
	attack_cooldown = 2.0
	super._ready()


func _ai_behavior(delta: float) -> void:
	_teleport_timer += delta
	_pounce_cooldown_timer += delta

	match current_state:
		State.IDLE:
			_idle_behavior(delta)
		State.CHASE:
			_chase_behavior(delta)
		State.ATTACK:
			_attack_behavior(delta)
		State.STUNNED:
			velocity.x = move_toward(velocity.x, 0.0, 350.0 * delta)


func _idle_behavior(_delta: float) -> void:
	velocity.x = 0.0
	if is_hostile and distance_to_player() < detection_range:
		current_state = State.CHASE


func _chase_behavior(_delta: float) -> void:
	var dist = distance_to_player()

	if dist > detection_range * 1.5:
		current_state = State.IDLE
		return

	# Teleport behind player when the cooldown is ready
	if _teleport_timer >= _teleport_cooldown and dist < _pounce_range * 1.5:
		_teleport_behind_player()
		_teleport_timer = 0.0
		return

	if dist < attack_range:
		current_state = State.ATTACK
		return

	var dir = direction_to_player()
	velocity.x = dir.x * movement_speed


func _attack_behavior(_delta: float) -> void:
	var dist = distance_to_player()

	if dist > attack_range * 2.5:
		current_state = State.CHASE
		return

	if _is_pouncing:
		return

	# Respect attack cooldown between pounces
	if _pounce_cooldown_timer < attack_cooldown:
		return

	# Pounce attack
	_pounce_cooldown_timer = 0.0
	_perform_pounce()


func _teleport_behind_player() -> void:
	## Blink behind the player with a glitch effect.
	var player = find_player()
	if not player:
		return

	# Determine "behind" based on player facing
	var behind_dir = 1.0 if player.global_position.x > global_position.x else -1.0
	behind_dir *= -1.0  # flip to get *behind* them

	var target_x = player.global_position.x + behind_dir * _teleport_offset
	var target_y = player.global_position.y

	# VFX at origin
	_vfx("vfx_glitch_sparkle", global_position)
	_sfx("glitch_teleport", 0.2)

	# Wall collision validation
	var space_state = get_world_2d().direct_space_state
	if space_state:
		var params = PhysicsPointQueryParameters2D.new()
		params.position = Vector2(target_x, target_y)
		params.collision_mask = 1
		if not space_state.intersect_point(params, 1).is_empty():
			target_x = player.global_position.x - behind_dir * _teleport_offset
			params.position = Vector2(target_x, target_y)
			if not space_state.intersect_point(params, 1).is_empty():
				return

	global_position = Vector2(target_x, target_y)

	# VFX at destination
	_vfx("vfx_glitch_sparkle", global_position)

	# Immediately pounce after teleport
	current_state = State.ATTACK


func _perform_pounce() -> void:
	## Leap at the player with a brief wind-up.
	if current_state == State.DEAD:
		return

	_is_pouncing = true
	velocity.x = 0.0

	# Brief telegraph
	await get_tree().create_timer(0.12).timeout
	if not is_inside_tree() or current_state == State.DEAD:
		_is_pouncing = false
		return

	var dir = direction_to_player()
	velocity.x = dir.x * _pounce_speed
	velocity.y = -200.0
	_sfx("enemy_pounce", 0.1)

	await get_tree().create_timer(0.3).timeout
	if not is_inside_tree() or current_state == State.DEAD:
		_is_pouncing = false
		return

	_deal_damage_in_range(attack_range, contact_damage)
	velocity.x = move_toward(velocity.x, 0.0, 500.0)
	_is_pouncing = false

	# Return to chase after attack
	current_state = State.CHASE


func die() -> void:
	if current_state == State.DEAD:
		return
	_vfx("vfx_glitch_sparkle", global_position)
	_vfx("vfx_enemy_death", global_position)
	_sfx("enemy_death")
	super.die()
