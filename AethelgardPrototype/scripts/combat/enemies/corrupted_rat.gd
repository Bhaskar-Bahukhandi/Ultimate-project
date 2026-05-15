extends EnemyBase
class_name CorruptedRat

## Corrupted Rat — Fast, aggressive lunge attacker with burrow/ambush capability.
## Charges at player rapidly, pauses briefly, then lunges again.
## NEW: Can burrow underground to reposition and ambush from below.

var _lunge_cooldown: float = 2.0
var _lunge_timer: float = 0.0
var _is_lunging: bool = false
var _lunge_speed: float = 350.0
var _lunge_duration: float = 0.25

# ── Burrow Mechanic ──────────────────────────────────────────────────────
var _burrow_cooldown: float = 6.0
var _burrow_timer: float = 0.0
var _is_burrowed: bool = false
var _burrow_duration: float = 1.5
var _burrow_emerge_damage: float = 18.0
var _burrow_count: int = 0  # Track how many times we've burrowed


func _ready() -> void:
	enemy_name = "Corrupted Rat"
	max_health = 25.0
	current_health = max_health
	contact_damage = 12.0
	movement_speed = 130.0
	detection_range = 300.0
	attack_range = 80.0
	xp_reward = 20
	gold_reward = 8
	elasticity = 1.0
	gravity_scale = 1.0
	attack_cooldown = _lunge_cooldown
	super._ready()


func _ai_behavior(delta: float) -> void:
	_burrow_timer += delta

	if _is_burrowed:
		return  # Don't process AI while underground

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

	var dir = direction_to_player()
	velocity.x = dir.x * movement_speed


func _attack_behavior(delta: float) -> void:
	var dist = distance_to_player()

	if dist > attack_range * 3.0:
		current_state = State.CHASE
		return

	if _is_lunging:
		return

	_lunge_timer += delta
	if _lunge_timer >= _lunge_cooldown:
		_perform_lunge()
		_lunge_timer = 0.0
	elif _burrow_timer >= _burrow_cooldown and _burrow_count < 3:
		_start_burrow()
		_burrow_timer = 0.0


func _perform_lunge() -> void:
	## Quick dash toward the player with a brief telegraph.
	if current_state == State.DEAD:
		return

	_is_lunging = true

	# Brief telegraph — stop and flash orange (distinct from hit flash)
	velocity.x = 0.0
	if has_node("Sprite"):
		var sprite = get_node("Sprite")
		var tw = create_tween()
		tw.tween_property(sprite, "modulate", Color(1.0, 0.7, 0.2), 0.08)
		tw.tween_property(sprite, "modulate", Color.WHITE, 0.07)

	await get_tree().create_timer(0.30).timeout
	if not is_inside_tree() or current_state == State.DEAD:
		_is_lunging = false
		return

	# Lunge
	var dir = direction_to_player()
	velocity.x = dir.x * _lunge_speed
	velocity.y = -80.0
	_sfx("enemy_lunge", 0.1)

	await get_tree().create_timer(_lunge_duration).timeout
	if not is_inside_tree() or current_state == State.DEAD:
		_is_lunging = false
		return

	# Check hit
	_deal_damage_in_range(attack_range, contact_damage)
	velocity.x = move_toward(velocity.x, 0.0, 600.0)
	_is_lunging = false


func die() -> void:
	if current_state == State.DEAD:
		return
	_is_burrowed = false
	_sfx("enemy_death")
	_vfx("vfx_enemy_death", global_position)
	super.die()


## Burrow underground, reposition behind player, emerge with damage
func _start_burrow() -> void:
	if _is_burrowed or current_state == State.DEAD:
		return

	_is_burrowed = true
	_burrow_count += 1

	# Visual: sink into ground
	if has_node("Sprite"):
		var sprite = get_node("Sprite")
		var tw = create_tween()
		tw.tween_property(sprite, "modulate:a", 0.0, 0.25)
		tw.parallel().tween_property(sprite, "scale:y", 0.1, 0.25)

	velocity = Vector2.ZERO
	set_collision_layer_value(3, false)  # Become intangible

	if has_node("/root/VFXLibrary"):
		VFXLibrary.spawn_status_indicator("*burrows*", global_position + Vector2(0, -20), get_parent(), false)

	await get_tree().create_timer(_burrow_duration).timeout
	if not is_inside_tree() or current_state == State.DEAD:
		_is_burrowed = false
		return

	# Emerge behind player
	_emerge_from_burrow()


func _emerge_from_burrow() -> void:
	var players = get_tree().get_nodes_in_group("player")
	if players.is_empty():
		_is_burrowed = false
		return

	var player_pos: Vector2 = (players[0] as Node2D).global_position

	# Position behind player
	var behind_offset = 100.0 if randf() > 0.5 else -100.0
	global_position = Vector2(player_pos.x + behind_offset, player_pos.y)

	# Visual: emerge
	if has_node("Sprite"):
		var sprite = get_node("Sprite")
		var tw = create_tween()
		tw.tween_property(sprite, "modulate:a", 1.0, 0.15)
		tw.parallel().tween_property(sprite, "scale:y", 1.0, 0.15)

	set_collision_layer_value(3, true)  # Become tangible again
	_is_burrowed = false

	# Emerge attack — damage nearby player
	var dist = distance_to_player()
	if dist < 120.0:
		for p in players:
			if is_instance_valid(p) and p.has_method("take_damage"):
				p.take_damage(_burrow_emerge_damage)
		if has_node("/root/CombatFX"):
			CombatFX.apply_screen_shake(8.0, 0.2)

	if has_node("/root/VFXLibrary"):
		VFXLibrary.spawn_status_indicator("AMBUSH!", global_position + Vector2(0, -40), get_parent(), false)

	current_state = State.ATTACK
