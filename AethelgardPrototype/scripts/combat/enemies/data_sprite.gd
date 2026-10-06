extends EnemyBase
class_name DataSprite

## Data Sprite — Ranged flying enemy that hovers and fires data bolts (Silver tier).
## Evasive: drifts away from player when they get close, prefers long-range combat.
## NEW: Splits into 2 weaker clones at 50% HP. Clones have half stats.

var _bolt_cooldown: float = 2.5
var _bolt_timer: float = 0.0
var _bolt_speed: float = 280.0
var _bolt_damage: float = 12.0
var _hover_amplitude: float = 20.0
var _hover_speed: float = 2.5
var _hover_offset: float = 0.0
var _evade_distance: float = 120.0
var _preferred_distance: float = 200.0
var _is_firing: bool = false

# ── Clone/Split Mechanic ─────────────────────────────────────────────────
var _has_split: bool = false
var _is_clone: bool = false  # True if this is a spawned clone
var _split_threshold: float = 0.5  # Split at 50% HP

## Preloaded bolt script (if available).
var _bolt_script: GDScript = null


func _ready() -> void:
	enemy_name = "Data Sprite"
	max_health = 35.0
	current_health = max_health
	contact_damage = 8.0
	movement_speed = 90.0
	detection_range = 400.0
	attack_range = 300.0
	xp_reward = 35
	gold_reward = 15
	elasticity = 1.0
	gravity_scale = 0.0  # Floats in the air
	super._ready()

	# Check if this is a clone — apply reduced stats
	if has_meta("is_clone") and get_meta("is_clone"):
		_is_clone = true
		_has_split = true  # Clones can't split again
		max_health *= 0.5
		current_health = max_health
		contact_damage *= 0.5
		_bolt_damage *= 0.5
		_bolt_cooldown *= 0.8  # Clones fire slightly faster
		xp_reward = int(xp_reward * 0.3)  # Less XP for clones
		gold_reward = int(gold_reward * 0.3)
		enemy_name = "Data Clone"

	# Try preloading bolt script
	var bolt_path = "res://scripts/combat/enemies/data_bolt.gd"
	if ResourceLoader.exists(bolt_path):
		_bolt_script = load(bolt_path) as GDScript


func _ai_behavior(delta: float) -> void:
	_hover_offset += delta * _hover_speed
	_bolt_timer += delta

	match current_state:
		State.IDLE:
			_idle_behavior(delta)
		State.CHASE:
			_chase_behavior(delta)
		State.ATTACK:
			_attack_behavior(delta)
		State.STUNNED:
			velocity.x = move_toward(velocity.x, 0.0, 200.0 * delta)
			velocity.y = move_toward(velocity.y, 0.0, 200.0 * delta)


func _idle_behavior(_delta: float) -> void:
	# Gentle hover
	velocity.y = sin(_hover_offset) * _hover_amplitude
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

	# Move toward player while hovering
	var dir = direction_to_player()
	velocity.x = dir.x * movement_speed
	velocity.y = sin(_hover_offset) * _hover_amplitude


func _attack_behavior(delta: float) -> void:
	var dist = distance_to_player()

	if dist > attack_range * 1.5:
		current_state = State.CHASE
		return

	# Evasion: back away when player is too close
	if dist < _evade_distance:
		var away = -direction_to_player()
		velocity.x = away.x * movement_speed * 1.3
		velocity.y = away.y * movement_speed * 0.5 + sin(_hover_offset) * _hover_amplitude
	else:
		# Maintain preferred distance
		var dir = direction_to_player()
		if dist > _preferred_distance:
			velocity.x = dir.x * movement_speed * 0.4
		else:
			velocity.x = move_toward(velocity.x, 0.0, 100.0 * delta)
		velocity.y = sin(_hover_offset) * _hover_amplitude

	# Fire bolts
	if _bolt_timer >= _bolt_cooldown and not _is_firing:
		_fire_data_bolt()
		_bolt_timer = 0.0


func _fire_data_bolt() -> void:
	## Shoot a data bolt at the player.
	if current_state == State.DEAD:
		return

	var player = find_player()
	if not player:
		return

	_is_firing = true
	var dir = (player.global_position - global_position).normalized()

	_sfx("projectile_fire", 0.15)
	_vfx("vfx_hit_spark", global_position)

	# Create bolt using preloaded script or fallback ColorRect
	var bolt: Node2D
	if _bolt_script:
		bolt = CharacterBody2D.new()
		bolt.set_script(_bolt_script)
	else:
		bolt = _create_fallback_bolt(dir)

	bolt.global_position = global_position
	get_parent().add_child(bolt)

	# If fallback bolt, animate it manually
	if not _bolt_script:
		_animate_fallback_bolt(bolt, dir)

	_is_firing = false


func _create_fallback_bolt(dir: Vector2) -> Node2D:
	## Create a Node2D wrapper with a colored rectangle as a bolt placeholder.
	var bolt = Node2D.new()
	bolt.name = "DataBolt"
	var visual = ColorRect.new()
	visual.color = Color(0.3, 0.6, 1.0, 0.9)
	visual.size = Vector2(12, 6)
	visual.position = Vector2(-6, -3)
	visual.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bolt.add_child(visual)
	bolt.rotation = dir.angle()
	bolt.set_meta("direction", dir)
	bolt.set_meta("speed", _bolt_speed)
	bolt.set_meta("damage", _bolt_damage)
	return bolt


func _animate_fallback_bolt(bolt: Node, dir: Vector2) -> void:
	## Drive a simple bolt through the scene and check player collision.
	var speed = _bolt_speed
	var damage = _bolt_damage
	var lifetime = 0.0
	# This coroutine drives the bolt and never resumes once the sprite is freed,
	# which left the bolt frozen in mid-air; take it along instead.
	tree_exiting.connect(bolt.queue_free, CONNECT_ONE_SHOT)

	while lifetime < 3.0 and is_instance_valid(bolt):
		# process_frame keeps firing while the game is paused; hold the bolt
		# still then instead of letting it fly on and hit the paused player.
		if can_process():
			bolt.position += dir * speed * get_process_delta_time()
			lifetime += get_process_delta_time()

			var player = find_player()
			if player and player.has_method("take_damage"):
				if bolt.global_position.distance_to(player.global_position) < 20.0:
					player.take_damage(damage, bolt.global_position, enemy_name, "ranged")
					bolt.queue_free()
					break

		await get_tree().process_frame
		if not is_inside_tree():
			if is_instance_valid(bolt):
				bolt.queue_free()
			return

	if is_instance_valid(bolt):
		bolt.queue_free()


func die() -> void:
	if current_state == State.DEAD:
		return
	_sfx("enemy_death")
	_vfx("vfx_enemy_death", global_position)
	super.die()


## Override take_damage to check for split threshold
func take_damage(amount: float, knockback_source: Vector2 = Vector2.ZERO) -> void:
	super.take_damage(amount, knockback_source)

	# Check if we should split
	if not _has_split and not _is_clone and current_health > 0.0 and max_health > 0.0:
		if current_health / max_health <= _split_threshold:
			_perform_split()


## Split into 2 weaker clones
func _perform_split() -> void:
	if _has_split or _is_clone:
		return

	_has_split = true

	if has_node("/root/VFXLibrary"):
		VFXLibrary.spawn_status_indicator("SPLIT!", global_position + Vector2(0, -50), get_parent(), false)

	if has_node("/root/CombatFX"):
		CombatFX.apply_screen_shake(6.0, 0.2)

	# Spawn 2 clones with reduced stats
	for i in range(2):
		var clone = CharacterBody2D.new()
		clone.name = "DataSpriteClone_%d" % (randi() % 1000)

		# Create sprite placeholder
		var sprite_rect = ColorRect.new()
		sprite_rect.name = "Sprite"
		sprite_rect.size = Vector2(28, 28)  # Smaller than original
		sprite_rect.position = Vector2(-14, -28)
		sprite_rect.color = Color(0.4, 0.8, 1.0, 0.7)  # Lighter, translucent
		sprite_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		clone.add_child(sprite_rect)

		# Collision
		var col_shape = CollisionShape2D.new()
		var rect_shape = RectangleShape2D.new()
		rect_shape.size = Vector2(28, 28)
		col_shape.shape = rect_shape
		col_shape.position = Vector2(0, -14)
		clone.add_child(col_shape)

		clone.collision_layer = 4
		clone.collision_mask = 1

		# Position offset from parent
		var offset_x = 60.0 if i == 0 else -60.0
		clone.global_position = global_position + Vector2(offset_x, 0)

		# Apply script
		var script = load("res://scripts/combat/enemies/data_sprite.gd")
		clone.set_script(script)

		# Set clone flag and reduced stats via meta (will be applied in _ready)
		clone.set_meta("is_clone", true)
		clone.set_meta("pending_zone_level", zone_level)
		# Nothing reads that meta; set the level itself so _ready() scales the clone
		# by zone like its parent (as combat_arena does for spawned enemies).
		clone.zone_level = zone_level

		if get_parent():
			get_parent().add_child(clone)

			# Connect died signal for encounter tracking
			if clone.has_signal("died") and has_node("/root/RandomEncounterSystem"):
				var type_str = "data_sprite"
				var level_val = zone_level
				clone.died.connect(func():
					RandomEncounterSystem.on_encounter_enemy_killed(type_str, level_val)
				)

	# Self gets 30% weaker after splitting
	max_health *= 0.7
	current_health = minf(current_health, max_health)
	contact_damage *= 0.7
	_bolt_damage *= 0.7

	# Register clones with encounter system to prevent premature victory
	if has_node("/root/RandomEncounterSystem") and RandomEncounterSystem.is_in_encounter():
		RandomEncounterSystem.register_additional_enemies(2)
