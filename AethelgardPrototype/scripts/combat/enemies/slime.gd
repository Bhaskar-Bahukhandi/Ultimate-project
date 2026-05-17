extends EnemyBase
class_name Slime

## Slime — Basic tutorial enemy that hops toward the player.
## Lowest threat tier. Slow, predictable, teaches basic combat timing.

# ── Hop timing ──
var _hop_timer: float = 0.0
var _hop_interval: float = 1.8
var _hop_strength: float = -350.0
var _hop_speed: float = 120.0
var _pounce_windup: float = 0.28
var _pounce_recovery: float = 0.38

## Whether the slime is mid-hop.
var _is_hopping: bool = false
var _is_pouncing: bool = false
var _pounce_recovery_timer: float = 0.0


func _ready() -> void:
	enemy_name = "Slime"
	max_health = 30.0
	current_health = max_health
	contact_damage = 8.0
	movement_speed = 55.0
	detection_range = 250.0
	attack_range = 72.0
	xp_reward = 15
	gold_reward = 5
	elasticity = 1.5
	gravity_scale = 1.0
	attack_cooldown_base = 1.25
	attack_active_duration = 0.16
	recover_duration = 0.35
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
	if _is_pouncing:
		return
	if _pounce_recovery_timer > 0.0:
		_pounce_recovery_timer -= delta
		velocity.x = move_toward(velocity.x, 0.0, 260.0 * delta)
		return

	var dist = distance_to_player()

	if dist > attack_range * 2.0:
		current_state = State.CHASE
		return

	_hop_timer += delta
	if _hop_timer >= _hop_interval * 0.7 and is_on_floor():
		_perform_pounce()
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


func _perform_pounce() -> void:
	_is_pouncing = true
	velocity.x = 0.0
	_status_text("!", global_position + Vector2(0, -42), false)
	_sfx("heavy_windup", 0.05)
	if has_node("Sprite"):
		get_node("Sprite").modulate = Color(1.0, 0.75, 0.35)

	await get_tree().create_timer(_pounce_windup).timeout
	if not _safe():
		_is_pouncing = false
		return

	var dir = direction_to_player()
	velocity.x = dir.x * (_hop_speed * 1.65)
	velocity.y = _hop_strength * 0.72
	_sfx("enemy_hop", 0.15)
	if has_node("Sprite"):
		get_node("Sprite").modulate = Color.WHITE
	_deal_damage_in_attack_hitbox(Vector2(dir.x * 48.0, -18.0), Vector2(96.0, 58.0), contact_damage * 1.25, "slime_pounce", 0.18)

	await get_tree().create_timer(0.18).timeout
	if not _safe():
		_is_pouncing = false
		return
	_is_pouncing = false
	_pounce_recovery_timer = _pounce_recovery


func die() -> void:
	if current_state == State.DEAD:
		return
	_sfx("enemy_splat")
	_vfx("vfx_enemy_death", global_position)
	super.die()
