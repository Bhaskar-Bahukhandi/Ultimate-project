extends EnemyBase
class_name Slime

## Slime — Basic tutorial enemy that hops toward the player.
## Lowest threat tier. Slow, predictable, teaches basic combat timing.

# ── Hop timing ──
var _hop_timer: float = 0.0
var _hop_interval: float = 1.8
var _hop_strength: float = -350.0
var _hop_speed: float = 120.0

## Whether the slime is mid-hop.
var _is_hopping: bool = false


func _ready() -> void:
	enemy_name = "Slime"
	max_health = 30.0
	current_health = max_health
	contact_damage = 8.0
	movement_speed = 40.0
	detection_range = 250.0
	attack_range = 50.0
	xp_reward = 15
	gold_reward = 5
	elasticity = 1.5
	gravity_scale = 1.0
	attack_cooldown = 2.0
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
			velocity.x = move_toward(velocity.x, 0.0, 200.0 * delta)


func _idle_behavior(_delta: float) -> void:
	velocity.x = 0.0
	if is_hostile and distance_to_player() < detection_range:
		current_state = State.CHASE


func _chase_behavior(delta: float) -> void:
	var dist = distance_to_player()

	if dist > detection_range * 1.5:
		current_state = State.IDLE
		return

	if dist < attack_range:
		current_state = State.ATTACK
		return

	_hop_timer += delta
	if _hop_timer >= _hop_interval and is_on_floor():
		_perform_hop()
		_hop_timer = 0.0


func _attack_behavior(delta: float) -> void:
	var dist = distance_to_player()

	if dist > attack_range * 2.0:
		current_state = State.CHASE
		return

	_hop_timer += delta
	if _hop_timer >= _hop_interval * 0.7 and is_on_floor():
		_perform_hop()
		_hop_timer = 0.0

	# Contact damage handled by base class hit-box


func _perform_hop() -> void:
	## Hop toward the player with a squash-and-stretch feel.
	_is_hopping = true
	var dir = direction_to_player()
	velocity.x = dir.x * _hop_speed
	velocity.y = _hop_strength

	_sfx("enemy_hop", 0.15)

	## Landing squash visual
	if has_node("Sprite"):
		var sprite = get_node("Sprite")
		var tw = create_tween()
		tw.tween_property(sprite, "scale", Vector2(1.3, 0.7), 0.08)
		tw.tween_property(sprite, "scale", Vector2(0.8, 1.2), 0.1)
		tw.tween_property(sprite, "scale", Vector2(1.0, 1.0), 0.12)


func die() -> void:
	if current_state == State.DEAD:
		return
	_sfx("enemy_splat")
	_vfx("vfx_enemy_death", global_position)
	super.die()
