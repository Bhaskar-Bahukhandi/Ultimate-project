extends EnemyBase
class_name CorruptedGuard

## Corrupted Guard — Melee enemy with blocking and counter-attacks (Silver tier).
## Cycles between blocking (damage-reduced) and aggressive counter-strikes.
## Has armor that reduces incoming damage.

enum GuardState { PATROL, BLOCK, COUNTER, CHASE }

var _guard_state: GuardState = GuardState.PATROL
var _block_timer: float = 0.0
var _block_duration: float = 2.0
var _counter_window: float = 0.4
var _armor: float = 5.0
var _counter_damage_mult: float = 1.5
var _is_blocking: bool = false


func _ready() -> void:
	enemy_name = "Corrupted Guard"
	max_health = 80.0
	current_health = max_health
	contact_damage = 18.0
	movement_speed = 70.0
	detection_range = 280.0
	attack_range = 65.0
	xp_reward = 40
	gold_reward = 18
	elasticity = 1.0
	gravity_scale = 1.0
	attack_cooldown = 1.8
	super._ready()


func _ai_behavior(delta: float) -> void:
	match current_state:
		State.IDLE:
			_idle_behavior(delta)
		State.CHASE:
			_chase_behavior(delta)
		State.ATTACK:
			_attack_behavior(delta)
		State.STUNNED:
			velocity.x = move_toward(velocity.x, 0.0, 250.0 * delta)
			_is_blocking = false


func _idle_behavior(_delta: float) -> void:
	velocity.x = 0.0
	if is_hostile and distance_to_player() < detection_range:
		current_state = State.CHASE
		_guard_state = GuardState.CHASE


func _chase_behavior(_delta: float) -> void:
	var dist = distance_to_player()

	if dist > detection_range * 1.5:
		current_state = State.IDLE
		_guard_state = GuardState.PATROL
		return

	if dist < attack_range:
		current_state = State.ATTACK
		_enter_block()
		return

	var dir = direction_to_player()
	velocity.x = dir.x * movement_speed


func _attack_behavior(delta: float) -> void:
	var dist = distance_to_player()

	if dist > attack_range * 2.5:
		current_state = State.CHASE
		_is_blocking = false
		return

	_block_timer += delta

	if _is_blocking:
		velocity.x = 0.0
		if _block_timer >= _block_duration:
			_begin_counter()
	else:
		# Post-counter: return to block cycle
		if _block_timer >= _counter_window + 0.5:
			_enter_block()


func _enter_block() -> void:
	## Raise shield — reduced damage while blocking.
	_is_blocking = true
	_block_timer = 0.0
	_guard_state = GuardState.BLOCK
	velocity.x = 0.0

	if has_node("Sprite"):
		get_node("Sprite").modulate = Color(0.6, 0.7, 1.0)

	_status_text("BLOCKING", global_position + Vector2(0, -40), false)


func _begin_counter() -> void:
	## Drop shield and counter-attack.
	_is_blocking = false
	_block_timer = 0.0
	_guard_state = GuardState.COUNTER

	if has_node("Sprite"):
		get_node("Sprite").modulate = Color(1.0, 0.4, 0.3)

	var dir = direction_to_player()
	velocity.x = dir.x * movement_speed * 2.5

	_sfx("enemy_attack")
	_deal_damage_in_range(attack_range * 1.3, contact_damage * _counter_damage_mult)

	await get_tree().create_timer(_counter_window, false).timeout
	if not is_inside_tree() or current_state == State.DEAD:
		return
	velocity.x = 0.0

	if has_node("Sprite"):
		get_node("Sprite").modulate = Color.WHITE


func take_damage(amount: float, knockback_source: Vector2 = Vector2.ZERO) -> void:
	## Armor and blocking reduce incoming damage.
	var final = amount - _armor
	if _is_blocking:
		final *= 0.3
		_status_text("BLOCKED!", global_position + Vector2(0, -30), false)
		_sfx("shield_block")
	final = maxf(final, 1.0)
	super.take_damage(final, knockback_source)


func die() -> void:
	if current_state == State.DEAD:
		return
	_is_blocking = false
	if has_node("Sprite"):
		get_node("Sprite").modulate = Color.WHITE
	_sfx("enemy_death")
	_vfx("vfx_enemy_death", global_position)
	super.die()
