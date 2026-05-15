extends EnemyBase
class_name ShadowWraith

## Shadow Wraith — Ethereal enemy that phases between corporeal and incorporeal (Gold tier).
## While ethereal: invulnerable, can't deal contact damage, drifts ominously.
## While corporeal: vulnerable, performs soul-drain attack, then phases out again.

enum Phase { ETHEREAL, CORPOREAL }

var _phase: Phase = Phase.ETHEREAL
var _phase_timer: float = 0.0
var _ethereal_duration: float = 3.0
var _corporeal_duration: float = 2.5
var _soul_drain_range: float = 100.0
var _soul_drain_damage: float = 5.0
var _drain_tick_timer: float = 0.0
var _dda_applied: bool = false
var _drain_tick_interval: float = 0.5
var _float_offset: float = 0.0


func _ready() -> void:
	enemy_name = "Shadow Wraith"
	max_health = 65.0
	current_health = max_health
	contact_damage = 14.0
	movement_speed = 60.0
	detection_range = 350.0
	attack_range = 100.0
	xp_reward = 60
	gold_reward = 28
	elasticity = 1.0
	gravity_scale = 0.0  # Floats
	super._ready()
	if not _dda_applied and has_node("/root/GameManager"):
		_soul_drain_damage *= GameManager.get_difficulty_multiplier()
		_dda_applied = true
	_enter_ethereal()


func _ai_behavior(delta: float) -> void:
	if current_state == State.STUNNED:
		velocity.x = move_toward(velocity.x, 0.0, 200.0 * delta)
		return

	_phase_timer += delta
	_float_offset += delta * 2.0

	match _phase:
		Phase.ETHEREAL:
			_ethereal_behavior(delta)
		Phase.CORPOREAL:
			_corporeal_behavior(delta)


func _ethereal_behavior(_delta: float) -> void:
	## Drift toward player. Invulnerable. Semi-transparent.
	var dir = direction_to_player()
	velocity.x = dir.x * movement_speed * 0.6
	velocity.y = sin(_float_offset) * 25.0

	if _phase_timer >= _ethereal_duration:
		_enter_corporeal()


func _corporeal_behavior(delta: float) -> void:
	## Solidify near the player, perform soul drain, then phase out.
	var dist = distance_to_player()

	# Move toward player while corporeal
	if dist > _soul_drain_range:
		var dir = direction_to_player()
		velocity.x = dir.x * movement_speed
	else:
		velocity.x = move_toward(velocity.x, 0.0, 150.0 * delta)

	velocity.y = sin(_float_offset) * 15.0

	# Soul drain — ticks damage when close
	if dist < _soul_drain_range:
		_drain_tick_timer += delta
		if _drain_tick_timer >= _drain_tick_interval:
			_drain_tick_timer = 0.0
			_soul_drain_tick()

	# Return to ethereal after duration
	if _phase_timer >= _corporeal_duration:
		_enter_ethereal()


func _enter_ethereal() -> void:
	## Become incorporeal — invulnerable, transparent.
	_phase = Phase.ETHEREAL
	_phase_timer = 0.0
	contact_damage = 0.0  # No contact damage while ethereal

	if has_node("Sprite"):
		var sprite = get_node("Sprite")
		var tw = create_tween()
		tw.tween_property(sprite, "modulate", Color(0.5, 0.3, 0.8, 0.35), 0.3)

	_sfx("wraith_phase", 0.1)
	_status_text("ETHEREAL", global_position + Vector2(0, -40), false)


func _enter_corporeal() -> void:
	## Solidify — vulnerable, can attack.
	_phase = Phase.CORPOREAL
	_phase_timer = 0.0
	_drain_tick_timer = 0.0
	contact_damage = 14.0  # Restore contact damage when corporeal

	if has_node("Sprite"):
		var sprite = get_node("Sprite")
		var tw = create_tween()
		tw.tween_property(sprite, "modulate", Color(0.7, 0.4, 1.0, 1.0), 0.3)

	_sfx("wraith_materialize")
	_status_text("CORPOREAL", global_position + Vector2(0, -40), false)


func _soul_drain_tick() -> void:
	## Deal a small tick of soul-drain damage to nearby player.
	var player = find_player()
	if not player or not player.has_method("take_damage"):
		return

	var dist = global_position.distance_to(player.global_position)
	if dist < _soul_drain_range:
		player.take_damage(_soul_drain_damage, global_position, enemy_name, "drain")
		_vfx("vfx_glitch_sparkle", player.global_position + Vector2(0, -20))


func take_damage(amount: float, knockback_source: Vector2 = Vector2.ZERO) -> void:
	## Cannot be damaged while ethereal.
	if _phase == Phase.ETHEREAL:
		_status_text("IMMUNE", global_position + Vector2(0, -30), false)
		return
	super.take_damage(amount, knockback_source)


func die() -> void:
	if current_state == State.DEAD:
		return
	_sfx("wraith_death")
	_vfx("vfx_enemy_death", global_position)
	_vfx("vfx_glitch_sparkle", global_position + Vector2(0, -20))
	super.die()
