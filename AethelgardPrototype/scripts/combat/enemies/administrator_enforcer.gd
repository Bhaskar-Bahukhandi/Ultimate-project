extends EnemyBase
class_name AdministratorEnforcer

## Administrator Enforcer — System punishment enemy at 75 %+ corruption.
## Teleports to chase the player relentlessly, pulsing red glow. Uses the
## base-class AI plus additional teleport-chase and corruption mechanics.

var _teleport_cooldown: float = 4.0
var _teleport_timer: float = 0.0
var _glow_tween: Tween  # Stored so we can kill on exit


func _ready() -> void:
	enemy_name = "Administrator Enforcer"
	max_health = 100.0
	current_health = max_health
	contact_damage = 25.0
	movement_speed = 100.0
	detection_range = 600.0
	attack_range = 70.0
	xp_reward = 80
	gold_reward = 40
	elasticity = 1.0
	gravity_scale = 0.5  # Slightly floaty — supernatural
	super._ready()
	add_to_group("administrator")

	# Start pulsing red glow
	_start_glow_pulse()


func _ai_behavior(delta: float) -> void:
	_teleport_timer += delta

	# Use the base class default AI state machine
	super._ai_behavior(delta)

	# Supplement: teleport toward player if they're far away
	if current_state == State.CHASE and _teleport_timer >= _teleport_cooldown:
		var dist = distance_to_player()
		if dist > detection_range * 0.6:
			_teleport_chase()
			_teleport_timer = 0.0


func _teleport_chase() -> void:
	## Blink closer to the player.
	var player = find_player()
	if not player:
		return

	_vfx("vfx_glitch_sparkle", global_position)
	_sfx("glitch_teleport", 0.15)

	# Teleport partway toward the player (not on top)
	var dir = (player.global_position - global_position).normalized()
	var teleport_dist = minf(distance_to_player() * 0.6, 250.0)
	global_position += dir * teleport_dist

	_vfx("vfx_glitch_sparkle", global_position)


func _start_glow_pulse() -> void:
	## Pulsing red glow to visually mark this as an administrative enemy.
	if not has_node("Sprite"):
		return
	var sprite = get_node("Sprite")
	if _glow_tween and _glow_tween.is_valid():
		_glow_tween.kill()
	_glow_tween = create_tween().set_loops()
	_glow_tween.tween_property(sprite, "modulate", Color(1.5, 0.3, 0.3), 0.5)
	_glow_tween.tween_property(sprite, "modulate", Color(1.0, 0.6, 0.6), 0.5)


func _exit_tree() -> void:
	super._exit_tree()  # disconnects GameManager.difficulty_adjusted
	if _glow_tween and _glow_tween.is_valid():
		_glow_tween.kill()


func die() -> void:
	if current_state == State.DEAD:
		return

	# Add corruption on death — the system punishes defiance
	if has_node("/root/GameManager"):
		GameManager.add_glitch_corruption(5.0)

	_status_text("SYSTEM: VIOLATION LOGGED", global_position + Vector2(0, -50), false)
	_vfx("vfx_enemy_death", global_position)
	_vfx("vfx_glitch_sparkle", global_position + Vector2(0, -20))
	_sfx("enforcer_death")
	super.die()
