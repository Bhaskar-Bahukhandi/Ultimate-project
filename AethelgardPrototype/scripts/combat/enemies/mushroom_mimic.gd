extends EnemyBase
class_name MushroomMimic

## Mushroom Mimic — Disguises itself as a lore pickup, then attacks when approached.
## Unique mechanic: Starts invisible/disguised. When player gets close, reveals itself
## with a spore burst that briefly slows the player. Releases healing spores on death.

var _disguised: bool = true
var _reveal_range: float = 100.0
var _spore_cooldown: float = 4.0
var _spore_timer: float = 0.0
var _spore_damage: float = 6.0
var _spore_slow_duration: float = 1.5
var _hop_timer: float = 0.0
var _hop_interval: float = 1.8
var _hop_force: float = -280.0
var _death_heal_amount: float = 15.0  # Heals player on death


func _ready() -> void:
	enemy_name = "Mushroom Mimic"
	max_health = 55.0
	current_health = max_health
	contact_damage = 14.0
	movement_speed = 70.0
	detection_range = 100.0  # Short — relies on ambush
	attack_range = 60.0
	xp_reward = 40
	gold_reward = 25
	elasticity = 0.8
	gravity_scale = 1.0
	attack_cooldown = _spore_cooldown
	super._ready()

	# Start disguised — make sprite look like a lore pickup
	if has_node("Sprite") and get_node("Sprite") is ColorRect:
		var sprite = get_node("Sprite") as ColorRect
		sprite.color = Color(0.4, 0.65, 0.3, 0.7)  # Muted green, slightly transparent


func _ai_behavior(delta: float) -> void:
	if _disguised:
		_disguise_behavior(delta)
		return

	_hop_timer += delta
	_spore_timer += delta

	match current_state:
		State.IDLE:
			_idle_behavior(delta)
		State.CHASE:
			_chase_behavior(delta)
		State.ATTACK:
			_attack_behavior(delta)
		State.STUNNED:
			velocity.x = move_toward(velocity.x, 0.0, 300.0 * delta)


func _disguise_behavior(_delta: float) -> void:
	velocity.x = 0.0
	velocity.y = 0.0
	var dist = distance_to_player()
	if dist < _reveal_range and dist > 0.0:
		_reveal()


func _reveal() -> void:
	_disguised = false
	is_hostile = true
	detection_range = 300.0

	# Visual reveal — flash and grow
	if has_node("Sprite"):
		var sprite = get_node("Sprite")
		var tw = create_tween()
		tw.tween_property(sprite, "modulate", Color(1.0, 0.3, 0.8), 0.1)
		tw.tween_property(sprite, "modulate", Color.WHITE, 0.15)
		# Change color to hostile mushroom
		if sprite is ColorRect:
			sprite.color = Color(0.7, 0.2, 0.5)

	# Spore burst on reveal — area damage
	_emit_spore_burst()
	current_state = State.CHASE

	if has_node("/root/CombatFX"):
		CombatFX.apply_screen_shake(8.0, 0.3)
	if has_node("/root/VFXLibrary"):
		VFXLibrary.spawn_status_indicator("MIMIC!", global_position + Vector2(0, -50), get_parent(), false)


func _emit_spore_burst() -> void:
	# Damage nearby player
	var players = get_tree().get_nodes_in_group("player")
	for p in players:
		if is_instance_valid(p) and p.global_position.distance_to(global_position) < 120.0:
			if p.has_method("take_damage"):
				p.take_damage(_spore_damage)
			# Visual: spawn spore particles
			if has_node("/root/VFXLibrary"):
				for i in range(4):
					var offset = Vector2(randf_range(-40, 40), randf_range(-40, 10))
					VFXLibrary.spawn_pickup_text("*spore*", global_position + offset, get_parent(), Color(0.5, 0.8, 0.2))


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

	# Hop toward player
	var dir = direction_to_player()
	velocity.x = dir.x * movement_speed

	if _hop_timer >= _hop_interval and is_on_floor():
		velocity.y = _hop_force
		_hop_timer = 0.0


func _attack_behavior(delta: float) -> void:
	var dist = distance_to_player()
	if dist > attack_range * 2.5:
		current_state = State.CHASE
		return

	if _spore_timer >= _spore_cooldown:
		_emit_spore_burst()
		_spore_timer = 0.0

	# Continue hopping toward player
	var dir = direction_to_player()
	velocity.x = dir.x * movement_speed * 0.5
	if _hop_timer >= _hop_interval and is_on_floor():
		velocity.y = _hop_force * 0.7
		_hop_timer = 0.0


## Override die to release healing spores
func die() -> void:
	if current_state == State.DEAD:
		return
	# Release healing spores on death — rewards player for killing it
	var players = get_tree().get_nodes_in_group("player")
	for p in players:
		if is_instance_valid(p) and p.has_method("heal"):
			# heal() keeps the player's live HP and the saved stat in step; writing
			# only the stat was overwritten by the player's next hit.
			p.heal(_death_heal_amount)
			if has_node("/root/VFXLibrary"):
				VFXLibrary.spawn_pickup_text("+%d HP" % int(_death_heal_amount), global_position + Vector2(0, -40), get_parent(), Color(0.2, 1.0, 0.3))
		elif is_instance_valid(p) and has_node("/root/GameManager"):
			GameManager.player_stats["hp"] = mini(
				GameManager.player_stats.get("hp", 100) + int(_death_heal_amount),
				GameManager.player_stats.get("max_hp", 100)
			)
			if has_node("/root/VFXLibrary"):
				VFXLibrary.spawn_pickup_text("+%d HP" % int(_death_heal_amount), global_position + Vector2(0, -40), get_parent(), Color(0.2, 1.0, 0.3))
	super.die()
