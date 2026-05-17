extends CharacterBody2D
class_name EnemyBase
## ==========================================================================
## Base class for all enemies — provides:
##   State-machine AI (idle/patrol/chase/telegraph/attack/recover/stunned/dead)
##   Hackable properties via Root Access system
##   Area2D-based detection (signal-driven, not per-frame distance)
##   Off-screen culling, dynamic level scaling, auto-loot, floating HP bar
##   Auto-sprite loading from AssetManager w/ procedural placeholder detail
## ==========================================================================

signal died
signal health_changed(new_health: float, max_health: float)

# ── Hackable Exports ──────────────────────────────────────────────────────
@export var movement_speed: float = 100.0:
	set(value):
		movement_speed = clampf(value, 0.0, 500.0)
		_on_property_hacked("movement_speed")

@export var gravity_scale: float = 1.0:
	set(value):
		gravity_scale = clampf(value, -2.0, 3.0)
		_on_property_hacked("gravity_scale")

@export var elasticity: float = 1.0:
	set(value):
		elasticity = clampf(value, 0.0, 5.0)
		_on_property_hacked("elasticity")

@export var is_hostile: bool = true:
	set(value):
		is_hostile = value
		_on_property_hacked("is_hostile")

@export var max_health: float = 50.0
@export var contact_damage: float = 10.0

# ── Constants ─────────────────────────────────────────────────────────────
const GRAVITY = 980.0
const HP_BAR_SHOW_DURATION = 4.0

# ── Enums ─────────────────────────────────────────────────────────────────
enum State { IDLE, PATROL, CHASE, ATTACK, TELEGRAPH, RECOVER, STUNNED, DEAD }
enum AttackType { SLASH, THRUST, SLAM, CHARGE, PROJECTILE }

# ── Runtime State ─────────────────────────────────────────────────────────
var enemy_name: String = ""
var current_health: float = 0.0
var is_hacked: bool = false
var hacked_properties: Array[String] = []
var current_state: int = State.IDLE
var player_ref: CharacterBody2D = null
var detection_range: float = 250.0
var attack_range: float = 90.0
var lose_aggro_range: float = 400.0

# ── Combat AI ─────────────────────────────────────────────────────────────
var attack_cooldown: float = 0.0
var attack_cooldown_base: float = 1.2
var telegraph_timer: float = 0.0
var telegraph_duration: float = 0.45
var attack_active_duration: float = 0.14
var recover_timer: float = 0.0
var recover_duration: float = 0.6
var current_attack: int = AttackType.SLASH
var attacks_available: Array[int] = [AttackType.SLASH]
var attack_weights: Dictionary = {}
var combo_count: int = 0
var max_combo: int = 1
var patrol_direction: float = 1.0
var patrol_timer: float = 0.0
var patrol_duration: float = 3.0
var idle_timer: float = 0.0
var idle_duration: float = 1.5
var chase_speed_mult: float = 1.3
var retreat_after_attack: bool = false
var retreat_timer: float = 0.0

## Dodge/retreat behavior (IMP 5)
var dodge_chance: float = 0.15  ## Chance to dodge when hit (0.0 = never, 1.0 = always)
var dodge_speed: float = 350.0  ## Horizontal speed during dodge
var _dodge_cooldown: float = 0.0  ## Cooldown timer
const DODGE_COOLDOWN_TIME: float = 2.0

## Guards against concurrent stun coroutines
var _stun_active: bool = false
## Hitstun freeze flag (keeps gravity active unlike set_physics_process(false))
var _hitstun_frozen: bool = false
## Deferred charge damage check
var _charge_damage_pending: bool = false
## Charge travel timer — prevents damage on the very first frame before enemy moves
var _charge_travel_timer: float = 0.0
const CHARGE_MIN_TRAVEL_TIME: float = 0.12

## Contact damage cooldown
var _contact_cooldown: float = 0.0

# ── Area2D Detection ──────────────────────────────────────────────────────
var _detection_area: Area2D = null
var _attack_area: Area2D = null
var _player_in_detection: bool = false
var _player_in_attack_range: bool = false

# ── Off-Screen Culling ────────────────────────────────────────────────────
var _screen_notifier: VisibleOnScreenNotifier2D = null
var _is_on_screen: bool = true
var _offscreen_frame_counter: int = 0

# ── Dynamic Scaling ───────────────────────────────────────────────────────
var _base_max_health: float = 0.0
var _base_contact_damage: float = 0.0
var _base_movement_speed: float = 0.0
var _base_xp_reward: int = 0  # Pass 55: Prevent xp compounding
var _base_gold_reward: int = 0  # Pass 55: Prevent gold compounding
var xp_reward: int = 10
var gold_reward: int = 5

## Zone-based enemy level (set by RandomEncounterSystem or boss scripts).
## If 0, falls back to old player-level scaling for backwards compatibility.
var zone_level: int = 0

@export var loot_table: LootTable = null

# ── Health Bar ────────────────────────────────────────────────────────────
var _hp_bar: ProgressBar = null
var _hp_bar_bg: ColorRect = null
var _hp_label: Label = null
var _hp_bar_visible_timer: float = 0.0

# ── Cached projectile script ─────────────────────────────────────────────
static var _cached_enemy_proj_script: GDScript = null  # Pass 55 M-02: Share across all instances

# ── Tracked tweens (BUG 9 FIX) ───────────────────────────────────────────
var _telegraph_tween: Tween = null
var _hack_tween: Tween = null

# ── Frame-Cached Enemy Group (PERF: avoids O(n²) group lookups) ────────────
static var _enemies_cache: Array = []
static var _enemies_cache_frame: int = -1

# ── Asset name mapping ────────────────────────────────────────────────────
const CLASS_TO_ASSET: Dictionary = {
	"Slime": "slime_green",
	"CorruptedRat": "corrupted_rat",
	"GlitchWolf": "glitch_wolf",
	"CorruptedGuard": "corrupted_guard",
	"DataSprite": "data_sprite",
	"ClockworkSoldier": "clockwork_soldier",
	"ShadowWraith": "shadow_wraith",
	"TutorialKnightBoss": "knight_tutorial",
	"ClockworkAutomatonBoss": "arachnid_clockwork",
	"DataWraithBoss": "wraith",
	"AdministratorEnforcer": "corrupted_guard",
	"AdministratorProxyBoss": "lich_lord",
}


# ══════════════════════════════════════════════════════════════════════════
# LIFECYCLE
# ══════════════════════════════════════════════════════════════════════════

func _ready() -> void:
	# Apply choice consequence enemy HP multiplier before initializing
	if has_node("/root/ChoiceConsequences"):
		max_health *= ChoiceConsequences.get_enemy_hp_multiplier()
	# Apply NG+ scaling — enemies get stronger each cycle
	if has_node("/root/GameManager") and GameManager.ng_plus_cycle > 0:
		var ng_mult: float = GameManager.get_ng_plus_enemy_multiplier()
		max_health = int(max_health * ng_mult)
		contact_damage = int(contact_damage * ng_mult)
		xp_reward = int(xp_reward * ng_mult)  # More XP to compensate
		gold_reward = int(gold_reward * ng_mult)
	current_health = max_health
	_base_max_health = max_health
	_base_contact_damage = contact_damage
	_base_movement_speed = movement_speed
	_base_xp_reward = xp_reward  # Pass 55: Store original before scaling
	_base_gold_reward = gold_reward
	add_to_group("enemies")
	add_to_group("hackable")

	set_meta("original_movement_speed", movement_speed)
	set_meta("original_gravity_scale", gravity_scale)
	set_meta("original_elasticity", elasticity)
	set_meta("original_is_hostile", is_hostile)

	if attacks_available.is_empty():
		attacks_available = [AttackType.SLASH]
	if attack_weights.is_empty():
		for atk in attacks_available:
			attack_weights[atk] = 1.0

	_setup_detection_areas()
	_setup_screen_notifier()
	_apply_level_scaling()

	if not loot_table:
		_generate_default_loot_table()

	_try_load_real_sprite()
	_try_load_kenney_animated_sprite()
	_enhance_placeholder_sprite()
	_setup_health_bar()

	if has_node("/root/GameManager"):
		if not GameManager.difficulty_adjusted.is_connected(_on_difficulty_adjusted):
			GameManager.difficulty_adjusted.connect(_on_difficulty_adjusted)

	spawn_in()


func _exit_tree() -> void:
	if has_node("/root/GameManager") and GameManager.difficulty_adjusted.is_connected(_on_difficulty_adjusted):
		GameManager.difficulty_adjusted.disconnect(_on_difficulty_adjusted)


# ══════════════════════════════════════════════════════════════════════════
# PHYSICS LOOP
# ══════════════════════════════════════════════════════════════════════════

func _physics_process(delta: float) -> void:
	if current_state == State.DEAD:
		return

	# HP bar auto-hide
	if _hp_bar_visible_timer > 0.0 and not is_in_group("boss"):
		_hp_bar_visible_timer -= delta
		if _hp_bar_visible_timer <= 0.0:
			_set_hp_bar_visible(false)

	# Off-screen culling: reduce AI rate
	if not _is_on_screen:
		_offscreen_frame_counter += 1
		if _offscreen_frame_counter < 3:
			if not is_on_floor():
				velocity.y += GRAVITY * gravity_scale * delta
			move_and_slide()
			return
		_offscreen_frame_counter = 0

	# Gravity — always applied even during hitstun so airborne enemies fall (BUG 10 FIX)
	if not is_on_floor():
		velocity.y += GRAVITY * gravity_scale * delta

	# Bounce on landing (elasticity)
	if is_on_floor() and velocity.y > 0.0:
		if elasticity > 1.0:
			var bounce_factor = minf(elasticity - 1.0, 1.5)
			var bounce_vel = -velocity.y * bounce_factor
			velocity.y = clampf(bounce_vel, -600.0, 0.0)

	# BUG 10 FIX: During hitstun, only apply gravity + slide, skip AI logic
	if _hitstun_frozen:
		velocity.x = move_toward(velocity.x, 0.0, 800.0 * delta)  # Friction during stun
		move_and_slide()
		return

	_ai_behavior(delta)
	move_and_slide()
	_sync_animation_to_state()

	# Contact damage
	if _contact_cooldown > 0.0:
		_contact_cooldown -= delta
	elif is_hostile and current_state != State.DEAD and player_ref and is_instance_valid(player_ref):
		if global_position.distance_to(player_ref.global_position) < 30.0:
			if player_ref.has_method("take_damage") and contact_damage > 0.0:
				var scaled_dmg = contact_damage * get_enemy_damage_multiplier()
				player_ref.take_damage(scaled_dmg, global_position, enemy_name, "contact")
				_contact_cooldown = 0.5


# ══════════════════════════════════════════════════════════════════════════
# STATE-MACHINE AI
# ══════════════════════════════════════════════════════════════════════════

func _ai_behavior(delta: float) -> void:
	if not is_hostile:
		velocity.x = move_toward(velocity.x, 0.0, 200.0 * delta)
		return

	attack_cooldown = maxf(0.0, attack_cooldown - delta)
	_dodge_cooldown = maxf(0.0, _dodge_cooldown - delta)

	match current_state:
		State.IDLE:
			_state_idle(delta)
		State.PATROL:
			_state_patrol(delta)
		State.CHASE:
			_state_chase(delta)
		State.TELEGRAPH:
			_state_telegraph(delta)
		State.ATTACK:
			_state_attack(delta)
		State.RECOVER:
			_state_recover(delta)
		State.STUNNED:
			velocity.x = move_toward(velocity.x, 0.0, 400.0 * delta)


func _state_idle(delta: float) -> void:
	velocity.x = move_toward(velocity.x, 0.0, 200.0 * delta)
	idle_timer += delta

	if _player_in_detection:
		current_state = State.CHASE
		idle_timer = 0.0
		return

	if idle_timer >= idle_duration:
		current_state = State.PATROL
		idle_timer = 0.0
		patrol_timer = 0.0
		patrol_direction = [-1.0, 1.0].pick_random()


func _state_patrol(delta: float) -> void:
	velocity.x = patrol_direction * movement_speed * 0.5
	patrol_timer += delta

	if _player_in_detection:
		current_state = State.CHASE
		patrol_timer = 0.0
		return

	# Ledge detection — turn around at edges
	if is_on_floor():
		var space = get_world_2d().direct_space_state
		if space:
			var ray_start = global_position + Vector2(patrol_direction * 20.0, -5.0)
			var ray_end = ray_start + Vector2(0, 40.0)
			var query = PhysicsRayQueryParameters2D.create(ray_start, ray_end, 1)
			var result = space.intersect_ray(query)
			if result.is_empty():
				patrol_direction *= -1.0
				patrol_timer = 0.0
				velocity.x = 0.0
				return

	if is_on_wall() or patrol_timer >= patrol_duration:
		patrol_direction *= -1.0
		patrol_timer = 0.0
		if randf() < 0.3:
			current_state = State.IDLE
			idle_timer = 0.0
			patrol_direction *= -1.0


func _state_chase(delta: float) -> void:
	var player = find_player()
	if not player:
		current_state = State.IDLE
		return

	if not _player_in_detection:
		current_state = State.IDLE
		idle_timer = 0.0
		velocity.x = move_toward(velocity.x, 0.0, 200.0 * delta)
		return

	var dir = direction_to_player()
	velocity.x = dir.x * movement_speed * chase_speed_mult

	# Enemy separation to prevent stacking (frame-cached to avoid O(n²) group lookups)
	for other in _get_enemies_cached():
		if other == self or not is_instance_valid(other): continue
		if other.current_state == State.DEAD: continue
		var sep = global_position - other.global_position
		if sep.length() < 60.0 and sep.length() > 0.1:
			velocity.x += sep.normalized().x * 80.0

	# Face player
	if has_node("Sprite"):
		var spr = get_node("Sprite")
		if spr is Sprite2D:
			spr.flip_h = dir.x < 0.0
		else:
			spr.scale.x = -absf(spr.scale.x) if dir.x < 0.0 else absf(spr.scale.x)

	if _player_in_attack_range and attack_cooldown <= 0.0:
		_begin_telegraph()


func _begin_telegraph() -> void:
	current_state = State.TELEGRAPH
	telegraph_timer = 0.0
	velocity.x = 0.0

	current_attack = _choose_attack()
	# Pass attack type name to GameJuice for color-coded feedback
	var attack_name_str = AttackType.keys()[current_attack].to_lower()
	if has_node("/root/GameJuice"):
		GameJuice.on_enemy_telegraph(self, attack_name_str)

	match current_attack:
		AttackType.SLASH:
			telegraph_duration = 0.35
		AttackType.THRUST:
			telegraph_duration = 0.5
		AttackType.SLAM:
			telegraph_duration = 0.6
		AttackType.CHARGE:
			telegraph_duration = 0.55
		AttackType.PROJECTILE:
			telegraph_duration = 0.4

	if has_node("/root/GameManager"):
		var dda = GameManager.get_difficulty_multiplier()
		telegraph_duration = maxf(telegraph_duration / dda, 0.25)  # Lower DDA = longer telegraph; clamp minimum 0.25s

	if has_node("Sprite"):
		var sprite = get_node("Sprite")
		var orig_color = sprite.modulate
		# BUG 9 FIX: Kill previous telegraph tween before creating a new one
		if _telegraph_tween and _telegraph_tween.is_valid():
			_telegraph_tween.kill()
		_telegraph_tween = create_tween()
		_telegraph_tween.tween_property(sprite, "modulate", Color(1.0, 0.4, 0.2, 1.0), telegraph_duration * 0.5)
		_telegraph_tween.tween_property(sprite, "modulate", orig_color, telegraph_duration * 0.3)

	if has_node("/root/VFXLibrary"):
		VFXLibrary.spawn_status_indicator("!", global_position + Vector2(0, -50), get_parent(), false)


func _choose_attack() -> int:
	if attacks_available.is_empty():
		return AttackType.SLASH
	if attacks_available.size() == 1:
		return attacks_available[0]

	var total_weight = 0.0
	for atk in attacks_available:
		total_weight += attack_weights.get(atk, 1.0)

	var roll = randf() * total_weight
	var running = 0.0
	for atk in attacks_available:
		running += attack_weights.get(atk, 1.0)
		if roll <= running:
			return atk

	return attacks_available[0]


func _state_telegraph(delta: float) -> void:
	telegraph_timer += delta
	velocity.x = 0.0
	if telegraph_timer >= telegraph_duration:
		_execute_attack()


func _execute_attack() -> void:
	current_state = State.ATTACK
	recover_timer = 0.0
	combo_count += 1
	_sfx("sword_swing", 0.15)

	var dir = direction_to_player()

	match current_attack:
		AttackType.SLASH:
			var slash_size := Vector2(attack_range * 1.1, 84.0)
			_deal_damage_in_attack_hitbox(Vector2(dir.x * slash_size.x * 0.5, -30.0), slash_size, contact_damage, "slash")
			_vfx("vfx_hit_spark", global_position + dir * 40.0)
		AttackType.THRUST:
			velocity.x = dir.x * movement_speed * 3.0
			var thrust_size := Vector2(attack_range * 1.5, 64.0)
			_deal_damage_in_attack_hitbox(Vector2(dir.x * thrust_size.x * 0.5, -28.0), thrust_size, contact_damage * 1.3, "thrust")
			_vfx("vfx_hit_spark", global_position + dir * 60.0)
		AttackType.SLAM:
			var slam_size := Vector2(attack_range * 1.4, 96.0)
			_deal_damage_in_attack_hitbox(Vector2(0.0, -24.0), slam_size, contact_damage * 1.6, "slam")
			_vfx("vfx_hit_spark", global_position + Vector2(0.0, 10.0))
		AttackType.CHARGE:
			velocity.x = dir.x * movement_speed * 4.5
			_charge_damage_pending = true
			_charge_travel_timer = 0.0  # BUG 8 FIX: Reset travel timer — damage only after travel
			# Stay in ATTACK state for charge — let _state_attack() handle transition
			return
		AttackType.PROJECTILE:
			_spawn_projectile(dir)

	if combo_count < max_combo and randf() < 0.4:
		attack_cooldown = 0.2
		current_state = State.CHASE
	else:
		current_state = State.RECOVER
		recover_timer = 0.0
		combo_count = 0


func _state_attack(delta: float) -> void:
	velocity.x = move_toward(velocity.x, 0.0, 600.0 * delta)

	# BUG 8 FIX: Only check charge damage after enemy has traveled for a minimum time
	if _charge_damage_pending:
		_charge_travel_timer += delta
		if _charge_travel_timer >= CHARGE_MIN_TRAVEL_TIME:
			var dir = direction_to_player()
			var charge_size := Vector2(attack_range * 2.0, 74.0)
			_deal_damage_in_attack_hitbox(Vector2(dir.x * charge_size.x * 0.5, -30.0), charge_size, contact_damage * 1.2, "charge")
			_charge_damage_pending = false

	recover_timer += delta
	if recover_timer > 0.3:
		_charge_damage_pending = false
		current_state = State.RECOVER
		recover_timer = 0.0


func _state_recover(delta: float) -> void:
	recover_timer += delta
	velocity.x = move_toward(velocity.x, 0.0, 300.0 * delta)

	# IMP 5: Enhanced retreat — back off after attacking, with slight dodge-hop
	if retreat_after_attack and recover_timer < recover_duration * 0.5:
		var dir = direction_to_player()
		velocity.x = -dir.x * movement_speed * 0.8
		# Small back-hop at start of recovery for visual flair
		if recover_timer < 0.05 and is_on_floor():
			velocity.y = -120.0

	if recover_timer >= recover_duration:
		attack_cooldown = attack_cooldown_base
		if has_node("/root/GameManager"):
			attack_cooldown = attack_cooldown_base / maxf(GameManager.get_difficulty_multiplier(), 0.1)
		current_state = State.CHASE if _player_in_detection else State.IDLE


# ══════════════════════════════════════════════════════════════════════════
# DAMAGE / HIT / DEATH
# ══════════════════════════════════════════════════════════════════════════

func _deal_damage_in_range(range_px: float, damage: float) -> void:
	var player = find_player()
	if not player:
		return
	var dist = global_position.distance_to(player.global_position)
	if dist <= range_px and player.has_method("take_damage"):
		# Line-of-sight check — don't hit through walls
		var space_state = get_world_2d().direct_space_state
		if space_state:
			var query = PhysicsRayQueryParameters2D.create(global_position, player.global_position, 1)  # Mask 1 = world/walls
			query.exclude = [get_rid()]
			var result = space_state.intersect_ray(query)
			if result and result.collider != player:
				return  # Wall is blocking the attack
		var display_name: String = enemy_name if enemy_name != "" else name.capitalize()
		var scaled_atk_dmg = damage * get_enemy_damage_multiplier()
		player.take_damage(scaled_atk_dmg, global_position, display_name)


func _deal_damage_in_attack_hitbox(center_offset: Vector2, size: Vector2, damage: float, damage_type: String = "enemy_melee", active_duration: float = -1.0) -> bool:
	var player = find_player()
	if not player:
		return false
	if active_duration < 0.0:
		active_duration = attack_active_duration

	var hitbox := Area2D.new()
	hitbox.name = "EnemyAttackHitbox"
	hitbox.collision_layer = 0
	hitbox.collision_mask = 2
	hitbox.set_meta("hit_targets", [])
	hitbox.set_meta("damage", damage)
	hitbox.set_meta("damage_type", damage_type)
	hitbox.set_meta("hitbox_size", size)

	var collision := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = size
	collision.shape = shape
	hitbox.add_child(collision)
	_add_attack_hitbox_debug_visual(hitbox, size)

	add_child(hitbox)
	hitbox.global_position = global_position + center_offset
	hitbox.body_entered.connect(_on_enemy_attack_hitbox_body_entered.bind(hitbox))
	var tween := hitbox.create_tween()
	tween.tween_interval(active_duration)
	tween.tween_callback(hitbox.queue_free)

	var did_hit := false
	for target in _get_players_in_attack_hitbox(center_offset, size):
		if _damage_player_from_attack_hitbox(target, hitbox):
			did_hit = true
	return did_hit


func _get_players_in_attack_hitbox(center_offset: Vector2, size: Vector2) -> Array:
	var players: Array = []
	var world := get_world_2d()
	if not world:
		return players

	var shape := RectangleShape2D.new()
	shape.size = size
	var params := PhysicsShapeQueryParameters2D.new()
	params.shape = shape
	params.transform = Transform2D(0.0, global_position + center_offset)
	params.collide_with_bodies = true
	params.collide_with_areas = true
	params.collision_mask = 2
	params.exclude = [get_rid()]

	var hit_rect := Rect2(global_position + center_offset - size * 0.5, size)
	for hit in world.direct_space_state.intersect_shape(params, 16):
		var target = _resolve_player_collider(hit.get("collider"))
		if target and hit_rect.has_point(target.global_position) and target not in players:
			players.append(target)

	if players.is_empty():
		for candidate in get_tree().get_nodes_in_group("player"):
			if is_instance_valid(candidate) and hit_rect.has_point(candidate.global_position) and candidate not in players:
				players.append(candidate)
	return players


func _resolve_player_collider(collider: Object):
	var node = collider as Node
	while node:
		if node.is_in_group("player"):
			return node
		node = node.get_parent()
	return null


func _on_enemy_attack_hitbox_body_entered(body: Node, hitbox: Area2D) -> void:
	var target = _resolve_player_collider(body)
	if target:
		_damage_player_from_attack_hitbox(target, hitbox)


func _damage_player_from_attack_hitbox(player, hitbox: Area2D) -> bool:
	if current_state == State.DEAD or not is_instance_valid(hitbox):
		return false
	if not is_instance_valid(player) or not player.has_method("take_damage"):
		return false
	var hit_targets: Array = hitbox.get_meta("hit_targets", [])
	if player in hit_targets:
		return false
	var hitbox_size: Vector2 = hitbox.get_meta("hitbox_size", Vector2.ZERO)
	if hitbox_size != Vector2.ZERO:
		var active_rect := Rect2(hitbox.global_position - hitbox_size * 0.5, hitbox_size)
		if not active_rect.has_point(player.global_position):
			return false
	if not _has_line_of_sight_to_player(player):
		return false

	hit_targets.append(player)
	hitbox.set_meta("hit_targets", hit_targets)
	var display_name: String = enemy_name if enemy_name != "" else name.capitalize()
	var scaled_atk_dmg = float(hitbox.get_meta("damage", contact_damage)) * get_enemy_damage_multiplier()
	var damage_type := str(hitbox.get_meta("damage_type", "enemy_melee"))
	player.take_damage(scaled_atk_dmg, global_position, display_name, damage_type)
	return true


func _has_line_of_sight_to_player(player) -> bool:
	var space_state = get_world_2d().direct_space_state
	if not space_state:
		return true
	var query = PhysicsRayQueryParameters2D.create(global_position, player.global_position, 1)
	query.exclude = [get_rid()]
	var result = space_state.intersect_ray(query)
	return result.is_empty() or result.collider == player


func _add_attack_hitbox_debug_visual(hitbox: Area2D, size: Vector2) -> void:
	if not OS.is_debug_build():
		return
	if has_node("/root/GameManager") and GameManager.get_meta("combat_debug_hitboxes", false) != true:
		return
	var polygon := Polygon2D.new()
	var half_size := size * 0.5
	polygon.color = Color(1.0, 0.2, 0.15, 0.28)
	polygon.polygon = PackedVector2Array([
		Vector2(-half_size.x, -half_size.y),
		Vector2(half_size.x, -half_size.y),
		Vector2(half_size.x, half_size.y),
		Vector2(-half_size.x, half_size.y)
	])
	hitbox.add_child(polygon)


func _spawn_projectile(dir: Vector2) -> void:
	var proj = Area2D.new()
	proj.name = "EnemyProjectile"
	proj.global_position = global_position + dir * 30.0
	proj.add_to_group("enemy_projectiles")
	proj.collision_layer = 0
	proj.collision_mask = 3  # Terrain (1) + Player (2)

	var shape = CollisionShape2D.new()
	var circle = CircleShape2D.new()
	circle.radius = 8.0
	shape.shape = circle
	proj.add_child(shape)

	# IMP 6: Use Kenney sprite for projectile instead of plain ColorRect
	var used_sprite = false
	if has_node("/root/AssetManager"):
		var proj_keys = ["star", "fire", "spark"]  # Try these Kenney effects
		for key in proj_keys:
			var tex = AssetManager.get_asset(key)
			if tex:
				var spr = Sprite2D.new()
				spr.texture = tex
				var scale_factor = 20.0 / maxf(tex.get_width(), 1)
				spr.scale = Vector2(scale_factor, scale_factor)
				spr.modulate = Color(1.0, 0.3, 0.2, 0.95)
				proj.add_child(spr)
				used_sprite = true
				break

	if not used_sprite:
		var visual = ColorRect.new()
		visual.size = Vector2(12, 12)
		visual.position = Vector2(-6, -6)
		visual.color = Color(1.0, 0.2, 0.2, 0.9)
		visual.mouse_filter = Control.MOUSE_FILTER_IGNORE
		proj.add_child(visual)

	# Build/cache the projectile script
	if _cached_enemy_proj_script == null:
		var script = GDScript.new()
		script.source_code = """extends Area2D
var move_dir = Vector2.ZERO
var speed = 300.0
var damage = 10.0
var lifetime = 4.0

func _ready():
	body_entered.connect(_on_body)
	area_entered.connect(_on_area)

func _physics_process(delta):
	position += move_dir * speed * delta
	lifetime -= delta
	if lifetime <= 0:
		queue_free()

func _on_body(body):
	if not is_instance_valid(self): return  # BUG 11 FIX: dual-free guard
	if body.is_in_group("player") and body.has_method("take_damage"):
		body.take_damage(damage, global_position, "Enemy Projectile")
		queue_free()
	elif body.collision_layer & 1:
		queue_free()
	elif not body.is_in_group("enemies"):
		queue_free()

func _on_area(area):
	pass
"""
		script.reload()
		_cached_enemy_proj_script = script

	# Set script BEFORE adding to tree so _ready() fires with signals connected
	proj.set_script(_cached_enemy_proj_script)
	proj.set("move_dir", dir.normalized())
	proj.set("speed", 280.0)
	proj.set("damage", contact_damage * 0.8)
	proj.set("lifetime", 4.0)
	proj.set_meta("owner_id", get_instance_id())

	var parent = get_parent()
	if parent:
		parent.add_child(proj)
	else:
		proj.queue_free()


func take_damage(amount: float, knockback_source: Vector2 = Vector2.ZERO) -> void:
	if current_state == State.DEAD:
		return
	amount = maxf(amount, 0.0)  # Guard against negative damage increasing health
	# Pass 57: Apply difficulty-based player damage multiplier
	if has_node("/root/GameManager"):
		amount *= GameManager.get_player_damage_mult()

	# Zone-based soft gate: reduce player damage vs higher-level enemies
	amount *= get_player_damage_multiplier()

	current_health -= amount
	health_changed.emit(current_health, max_health)

	# Directional knockback
	var knockback_dir = Vector2.ZERO
	if knockback_source != Vector2.ZERO:
		knockback_dir = (global_position - knockback_source).normalized()
	else:
		var player = find_player()
		if player and is_instance_valid(player):
			knockback_dir = (global_position - player.global_position).normalized()

	if knockback_dir != Vector2.ZERO:
		var knockback_force = clampf(amount * 8.0, 80.0, 400.0)
		velocity.x = knockback_dir.x * knockback_force
		velocity.y = minf(-80.0, knockback_dir.y * knockback_force * 0.5)

	_play_hit_flash()
	_sfx("enemy_hurt", 0.15)
	TweenAnimator.play_hurt(self)
	_vfx("vfx_hit_spark", global_position + Vector2(0, -15))
	# Kenney spark VFX on hit
	if has_node("/root/AssetManager"):
		AssetManager.spawn_oneshot_vfx(get_parent(), "spark", global_position + Vector2(randf_range(-10, 10), randf_range(-20, -5)), Vector2(32, 32), 16.0)
	_update_health_bar()

	if current_health <= 0.0:
		if has_node("/root/GameManager"):
			GameManager.stats["enemies_killed"] = GameManager.stats.get("enemies_killed", 0) + 1
		if has_node("/root/CombatFX"):
			CombatFX.apply_kill_effects(global_position, amount)
		die()
	else:
		# IMP 5: Reactive dodge — after taking a hit, enemy may dodge backward
		if _dodge_cooldown <= 0.0 and randf() < dodge_chance and is_on_floor():
			_dodge_cooldown = DODGE_COOLDOWN_TIME
			var dodge_dir = -knockback_dir if knockback_dir != Vector2.ZERO else Vector2(-1, 0)
			velocity.x = dodge_dir.x * dodge_speed
			velocity.y = -150.0  # Small hop
			_sfx("sword_swing", 0.15)
			# Brief invulnerability flash
			if has_node("Sprite"):
				var spr = get_node("Sprite")
				spr.modulate.a = 0.4
				await get_tree().create_timer(0.2).timeout
				if is_instance_valid(self) and is_inside_tree() and has_node("Sprite"):
					get_node("Sprite").modulate.a = 1.0
		else:
			_apply_hitstun(amount)


func _apply_hitstun(amount: float) -> void:
	if _stun_active:
		return
	var _old_state = current_state
	current_state = State.STUNNED
	_stun_active = true
	_hitstun_frozen = true  # BUG 10 FIX: Use flag instead of disabling physics

	var stun_time = clampf(amount * 0.008, 0.15, 0.5)
	# BUG 10 FIX: Don't disable physics_process — gravity still needed for airborne enemies
	await get_tree().create_timer(stun_time).timeout
	if not is_inside_tree() or not is_instance_valid(self):
		return
	if current_state == State.DEAD:
		return
	_stun_active = false
	_hitstun_frozen = false
	if current_state == State.STUNNED:
		current_state = State.CHASE


func _play_hit_flash() -> void:
	if not has_node("Sprite"):
		return
	var sprite = get_node("Sprite")
	var original_color = sprite.modulate

	if sprite.has_meta("flash_tween"):
		var old_tween: Tween = sprite.get_meta("flash_tween")
		if old_tween and old_tween.is_valid():
			old_tween.kill()

	var flash_tween = create_tween()
	sprite.set_meta("flash_tween", flash_tween)
	flash_tween.tween_property(sprite, "modulate", Color(5.0, 5.0, 5.0, 1.0), 0.02)
	flash_tween.tween_property(sprite, "modulate", Color(1.5, 0.3, 0.3, 1.0), 0.05)
	flash_tween.tween_property(sprite, "modulate", original_color, 0.12).set_trans(Tween.TRANS_SINE)


func die() -> void:
	current_state = State.DEAD
	set_physics_process(false)
	# Pass 55: Disable collision immediately so dead enemy can't block player
	collision_layer = 0
	collision_mask = 0
	
	# Play Kenney death animation if available
	_sync_animation_to_state()

	# Spawn death VFX using Kenney smoke/fire effects
	if has_node("/root/AssetManager"):
		AssetManager.spawn_oneshot_vfx(get_parent(), "smoke", global_position, Vector2(64, 64), 10.0)

	# Clean up only THIS enemy's projectiles
	for proj in get_tree().get_nodes_in_group("enemy_projectiles"):
		if is_instance_valid(proj) and proj.get_meta("owner_id", 0) == get_instance_id():
			proj.queue_free()

	_sfx("enemy_death", 0.1)
	died.emit()
	if has_node("/root/GameJuice"):
		GameJuice.on_enemy_die(self)
	if has_node("/root/GameManager"):
		GameManager.record_dda_kill()

	_award_death_rewards()
	_vfx("vfx_enemy_death", global_position)

	# Check if last enemy — dramatic slowdown (use cached group)
	var remaining = _get_enemies_cached()
	var alive_count = 0
	for e in remaining:
		if is_instance_valid(e) and e != self and e.get("current_state") != null and e.current_state != State.DEAD:
			alive_count += 1
	if alive_count == 0 and has_node("/root/CombatFX"):
		CombatFX.apply_last_kill_slowdown()

	if has_node("/root/CombatFX"):
		CombatFX.apply_kill_zoom()

	TweenAnimator.play_die(self)
	await get_tree().create_timer(0.6).timeout
	if not is_inside_tree():
		return
	if is_instance_valid(self):
		queue_free()


func stagger(duration: float = 1.0) -> void:
	## Stagger the enemy (used by player parry). Disables AI for duration.
	if current_state == State.DEAD or _stun_active:
		return
	_stun_active = true

	current_state = State.STUNNED
	_hitstun_frozen = true  # BUG 10 FIX: Use flag to preserve gravity
	velocity.x = 0.0  # Stop horizontal movement but keep vertical for gravity

	if has_node("Sprite"):
		get_node("Sprite").modulate = Color(1.0, 1.0, 0.6, 1.0)

	_vfx("vfx_hit_spark", global_position + Vector2(0, -15))

	await get_tree().create_timer(duration).timeout
	if not is_inside_tree() or not is_instance_valid(self):
		return
	_stun_active = false
	_hitstun_frozen = false
	if current_state == State.STUNNED:
		current_state = State.CHASE
		if has_node("Sprite"):
			get_node("Sprite").modulate = Color(1.0, 0.7, 1.0, 1.0) if is_hacked else Color.WHITE


# ══════════════════════════════════════════════════════════════════════════
# PLAYER LOOKUP
# ══════════════════════════════════════════════════════════════════════════

func find_player() -> CharacterBody2D:
	if player_ref == null or not is_instance_valid(player_ref):
		var players = get_tree().get_nodes_in_group("player")
		if players.size() > 0:
			player_ref = players[0] as CharacterBody2D
	return player_ref


func distance_to_player() -> float:
	var player = find_player()
	if player:
		return global_position.distance_to(player.global_position)
	return INF


func direction_to_player() -> Vector2:
	var player = find_player()
	if player:
		return (player.global_position - global_position).normalized()
	return Vector2.ZERO


# ══════════════════════════════════════════════════════════════════════════
# HACK SYSTEM
# ══════════════════════════════════════════════════════════════════════════

func _on_property_hacked(property_name: String) -> void:
	is_hacked = true
	if property_name not in hacked_properties:
		hacked_properties.append(property_name)

	_vfx("vfx_glitch_sparkle", global_position)
	if has_node("/root/VFXLibrary"):
		VFXLibrary.spawn_status_indicator("HACKED: " + property_name, global_position + Vector2(0, -40), get_parent(), false)

	if has_node("Sprite"):
		var sprite = get_node("Sprite")
		TweenAnimator.flash_color(sprite, Color(1.0, 0.5, 1.0))
		if _hack_tween and _hack_tween.is_valid():
			_hack_tween.kill()
		_hack_tween = sprite.create_tween()
		_hack_tween.tween_property(sprite, "modulate", Color(1.0, 0.7, 1.0, 1.0), 0.3)


func get_hackable_properties() -> Dictionary:
	return {
		"movement_speed": {
			"value": movement_speed,
			"type": "float",
			"range": [0.0, 500.0],
			"description": "Movement speed in pixels/second",
		},
		"gravity_scale": {
			"value": gravity_scale,
			"type": "float",
			"range": [-2.0, 3.0],
			"description": "Gravity multiplier (negative = float)",
		},
		"elasticity": {
			"value": elasticity,
			"type": "float",
			"range": [0.0, 5.0],
			"description": "Bounciness when landing",
		},
		"is_hostile": {
			"value": is_hostile,
			"type": "bool",
			"description": "Whether enemy attacks player",
		},
		"current_health": {
			"value": current_health,
			"type": "float",
			"range": [0.0, max_health],
			"description": "Current HP (set to 0 to kill)",
		},
	}


func apply_hack(property_name: String, new_value: Variant) -> void:
	match property_name:
		"movement_speed":
			movement_speed = float(new_value)
		"gravity_scale":
			gravity_scale = float(new_value)
		"elasticity":
			elasticity = float(new_value)
		"is_hostile":
			is_hostile = bool(new_value)
		"current_health":
			var old_health = current_health
			current_health = clampf(float(new_value), 0.0, max_health)
			health_changed.emit(current_health, max_health)
			if current_health <= 0.0 and old_health > 0.0:
				die()
		_:
			push_warning("Attempted to hack unknown property: " + property_name)


# ══════════════════════════════════════════════════════════════════════════
# AUTO-SPRITE LOADING
# ══════════════════════════════════════════════════════════════════════════

func _try_load_real_sprite() -> void:
	var sprite_node = get_node_or_null("Sprite")
	if not sprite_node:
		return
	if sprite_node is Sprite2D:
		return
	if not (sprite_node is ColorRect):
		return

	var class_name_str: String = get_script().get_global_name() if get_script() else ""
	var asset_name: String = ""
	if CLASS_TO_ASSET.has(class_name_str):
		asset_name = CLASS_TO_ASSET[class_name_str]
	else:
		asset_name = name.to_snake_case()

	if not has_node("/root/AssetManager"):
		return
	if not AssetManager.is_asset_available(asset_name):
		return

	var texture: Texture2D = AssetManager.get_sprite(asset_name)
	if not texture:
		return

	var old_size: Vector2 = sprite_node.size
	var target_size: float = maxf(old_size.x, old_size.y) * 1.5
	if target_size <= 0.0:
		target_size = 64.0

	var new_sprite = Sprite2D.new()
	new_sprite.name = "Sprite"
	new_sprite.texture = texture
	new_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST

	var tex_size = texture.get_size()
	if tex_size.x > 0.0 and tex_size.y > 0.0:
		var uniform = target_size / maxf(tex_size.x, tex_size.y)
		new_sprite.scale = Vector2(uniform, uniform)
		new_sprite.offset = Vector2(0.0, -tex_size.y / 2.0)

	var parent_node = sprite_node.get_parent()
	var idx = sprite_node.get_index()
	parent_node.remove_child(sprite_node)
	sprite_node.queue_free()
	parent_node.add_child(new_sprite)
	parent_node.move_child(new_sprite, idx)


func _try_load_kenney_animated_sprite() -> void:
	## Try to replace the Sprite child with a Kenney AnimatedSprite2D.
	## This gives enemies multi-frame idle/walk/hit/dead animations from separate PNGs.
	var sprite_node = get_node_or_null("Sprite")
	if not sprite_node:
		return
	# Don't replace if already an AnimatedSprite2D
	if sprite_node is AnimatedSprite2D:
		return
	if not has_node("/root/AssetManager"):
		return
	var class_name_str: String = get_script().get_global_name() if get_script() else ""
	if class_name_str == "":
		return
	var anim_sprite: AnimatedSprite2D = AssetManager.create_kenney_animated_enemy(class_name_str, 96.0)
	if not anim_sprite:
		return
	# Replace the existing sprite node
	var parent_node = sprite_node.get_parent()
	var idx = sprite_node.get_index()
	parent_node.remove_child(sprite_node)
	sprite_node.queue_free()
	parent_node.add_child(anim_sprite)
	parent_node.move_child(anim_sprite, idx)
	if OS.is_debug_build():
		print("[ENEMY] Kenney animated sprite loaded for %s" % class_name_str)

func _sync_animation_to_state() -> void:
	## Update the Kenney AnimatedSprite2D animation based on current AI state.
	var sprite_node = get_node_or_null("Sprite")
	if not sprite_node or not (sprite_node is AnimatedSprite2D):
		return
	var desired_anim: String = ""
	match current_state:
		State.IDLE:
			desired_anim = "idle"
		State.PATROL, State.CHASE:
			desired_anim = "walk"
		State.TELEGRAPH, State.ATTACK:
			desired_anim = "walk"  # reuse walk for attack telegraph
		State.STUNNED:
			desired_anim = "hit"
		State.DEAD:
			desired_anim = "dead"
		State.RECOVER:
			desired_anim = "idle"
	if desired_anim != "" and sprite_node.sprite_frames.has_animation(desired_anim):
		if sprite_node.animation != desired_anim:
			sprite_node.play(desired_anim)
	# Flip sprite based on movement direction
	if velocity.x > 10.0:
		sprite_node.flip_h = false
	elif velocity.x < -10.0:
		sprite_node.flip_h = true


func _enhance_placeholder_sprite() -> void:
	## Procedurally add visual detail to ColorRect placeholders.
	var sprite_node = get_node_or_null("Sprite")
	if not sprite_node or not (sprite_node is ColorRect):
		return

	var base_color: Color = sprite_node.color
	var w: float = sprite_node.size.x
	var h: float = sprite_node.size.y

	# Outline border
	var outline = ColorRect.new()
	outline.name = "Outline"
	outline.color = base_color.darkened(0.5)
	outline.position = Vector2(-2, -2)
	outline.size = Vector2(w + 4, h + 4)
	outline.z_index = -1
	outline.mouse_filter = Control.MOUSE_FILTER_IGNORE
	sprite_node.add_child(outline)

	# Eyes
	var class_str: String = get_script().get_global_name() if get_script() else ""
	var eye_y: float = h * 0.3
	var eye_spacing: float = w * 0.22
	var eye_size: float = clampf(w * 0.12, 4.0, 10.0)

	for side in [-1, 1]:
		var eye = ColorRect.new()
		eye.name = "Eye%s" % ("L" if side < 0 else "R")
		eye.color = Color.WHITE
		eye.size = Vector2(eye_size, eye_size)
		eye.position = Vector2(w / 2.0 + side * eye_spacing - eye_size / 2.0, eye_y - eye_size / 2.0)
		eye.mouse_filter = Control.MOUSE_FILTER_IGNORE
		sprite_node.add_child(eye)

		var pupil = ColorRect.new()
		pupil.name = "Pupil%s" % ("L" if side < 0 else "R")
		pupil.color = Color(0.1, 0.0, 0.0)
		pupil.size = Vector2(eye_size * 0.5, eye_size * 0.5)
		pupil.position = Vector2(eye_size * 0.35, eye_size * 0.35)
		pupil.mouse_filter = Control.MOUSE_FILTER_IGNORE
		eye.add_child(pupil)

	# Type-specific decorations
	match class_str:
		"Slime":
			var sheen = ColorRect.new()
			sheen.name = "Sheen"
			sheen.color = Color(base_color.lightened(0.3), 0.5)
			sheen.size = Vector2(w * 0.4, h * 0.2)
			sheen.position = Vector2(w * 0.2, h * 0.08)
			sheen.mouse_filter = Control.MOUSE_FILTER_IGNORE
			sprite_node.add_child(sheen)
		"GlitchWolf":
			for side2 in [-1, 1]:
				var ear = ColorRect.new()
				ear.name = "Ear%d" % (side2 + 2)
				ear.color = base_color.lightened(0.15)
				ear.size = Vector2(w * 0.2, h * 0.25)
				ear.position = Vector2(w / 2.0 + side2 * w * 0.28 - w * 0.1, -h * 0.2)
				ear.rotation = side2 * 0.3
				ear.mouse_filter = Control.MOUSE_FILTER_IGNORE
				sprite_node.add_child(ear)
		"CorruptedGuard", "AdministratorEnforcer":
			var visor = ColorRect.new()
			visor.name = "Visor"
			visor.color = Color(0.1, 0.1, 0.3, 0.8)
			visor.size = Vector2(w * 0.7, h * 0.15)
			visor.position = Vector2(w * 0.15, eye_y - h * 0.02)
			visor.mouse_filter = Control.MOUSE_FILTER_IGNORE
			sprite_node.add_child(visor)
		"ShadowWraith", "DataWraithBoss":
			var fade = ColorRect.new()
			fade.name = "GhostFade"
			fade.color = Color(base_color, 0.3)
			fade.size = Vector2(w * 1.2, h * 0.3)
			fade.position = Vector2(-w * 0.1, h * 0.8)
			fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
			sprite_node.add_child(fade)
		"ClockworkSoldier", "ClockworkAutomatonBoss":
			var gear = ColorRect.new()
			gear.name = "GearCore"
			gear.color = Color(0.85, 0.7, 0.2)
			gear.size = Vector2(w * 0.3, h * 0.3)
			gear.position = Vector2(w * 0.35, h * 0.5)
			gear.mouse_filter = Control.MOUSE_FILTER_IGNORE
			sprite_node.add_child(gear)
		"DataSprite":
			var core = ColorRect.new()
			core.name = "Core"
			core.color = Color(0.3, 1.0, 1.0, 0.7)
			core.size = Vector2(w * 0.25, h * 0.25)
			core.position = Vector2(w * 0.375, h * 0.45)
			core.mouse_filter = Control.MOUSE_FILTER_IGNORE
			sprite_node.add_child(core)
		"TutorialKnightBoss":
			var crest = ColorRect.new()
			crest.name = "Crest"
			crest.color = Color(1.0, 0.85, 0.2)
			crest.size = Vector2(w * 0.15, h * 0.35)
			crest.position = Vector2(w * 0.425, -h * 0.28)
			crest.mouse_filter = Control.MOUSE_FILTER_IGNORE
			sprite_node.add_child(crest)

			var sword = ColorRect.new()
			sword.name = "Sword"
			sword.color = Color(0.75, 0.75, 0.8)
			sword.size = Vector2(w * 0.08, h * 0.7)
			sword.position = Vector2(w + 4, h * 0.15)
			sword.mouse_filter = Control.MOUSE_FILTER_IGNORE
			sprite_node.add_child(sword)


# ══════════════════════════════════════════════════════════════════════════
# AREA2D DETECTION SYSTEM
# ══════════════════════════════════════════════════════════════════════════

func _setup_detection_areas() -> void:
	_detection_area = Area2D.new()
	_detection_area.name = "DetectionArea"
	_detection_area.collision_layer = 0
	_detection_area.collision_mask = 2
	var det_shape = CollisionShape2D.new()
	var det_circle = CircleShape2D.new()
	det_circle.radius = detection_range
	det_shape.shape = det_circle
	_detection_area.add_child(det_shape)
	add_child(_detection_area)
	_detection_area.body_entered.connect(_on_detection_entered)
	_detection_area.body_exited.connect(_on_detection_exited)

	_attack_area = Area2D.new()
	_attack_area.name = "AttackArea"
	_attack_area.collision_layer = 0
	_attack_area.collision_mask = 2
	var atk_shape = CollisionShape2D.new()
	var atk_circle = CircleShape2D.new()
	atk_circle.radius = attack_range
	atk_shape.shape = atk_circle
	_attack_area.add_child(atk_shape)
	add_child(_attack_area)
	_attack_area.body_entered.connect(_on_attack_range_entered)
	_attack_area.body_exited.connect(_on_attack_range_exited)


func _on_detection_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		_player_in_detection = true
		player_ref = body as CharacterBody2D


func _on_detection_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		_player_in_detection = false


func _on_attack_range_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		_player_in_attack_range = true


func _on_attack_range_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		_player_in_attack_range = false


# ══════════════════════════════════════════════════════════════════════════
# OFF-SCREEN CULLING
# ══════════════════════════════════════════════════════════════════════════

func _setup_screen_notifier() -> void:
	_screen_notifier = VisibleOnScreenNotifier2D.new()
	_screen_notifier.name = "ScreenNotifier"
	_screen_notifier.rect = Rect2(-40, -40, 80, 80)
	add_child(_screen_notifier)
	_screen_notifier.screen_entered.connect(_on_screen_entered)
	_screen_notifier.screen_exited.connect(_on_screen_exited)


func _on_screen_entered() -> void:
	_is_on_screen = true


func _on_screen_exited() -> void:
	_is_on_screen = false


# ══════════════════════════════════════════════════════════════════════════
# DYNAMIC SCALING
# ══════════════════════════════════════════════════════════════════════════

func _on_difficulty_adjusted(_new_mult: float) -> void:
	_apply_level_scaling()


func _apply_level_scaling() -> void:
	if not has_node("/root/GameManager"):
		return
	var player_level: int = GameManager.player_stats.get("level", 1)
	var dda_mult = GameManager.get_difficulty_multiplier()

	# ── Zone-Based Scaling (new system) ──
	# If zone_level is set, use it to scale enemy stats independently of player.
	# If zone_level is 0, fall back to legacy player-level scaling for compat.
	var level_factor: float
	if zone_level > 0:
		# Enemies scale with their zone, not the player
		level_factor = 1.0 + maxf(zone_level - 1, 0) * 0.12
	else:
		# Legacy: scale with player level (for old scenes that haven't been updated)
		level_factor = 1.0 + maxf(player_level - 1, 0) * 0.08

	level_factor *= dda_mult

	# Preserve HP percentage so mid-combat rescaling doesn't heal to full
	var hp_pct: float = 1.0
	if max_health > 0.0:
		hp_pct = current_health / max_health

	max_health = _base_max_health * level_factor
	current_health = max_health * hp_pct
	contact_damage = _base_contact_damage * level_factor

	if zone_level > 0:
		movement_speed = _base_movement_speed * (1.0 + maxf(zone_level - 1, 0) * 0.04) * dda_mult
	else:
		movement_speed = _base_movement_speed * (1.0 + maxf(player_level - 1, 0) * 0.03) * dda_mult

	# ── XP/Gold Scaling ──
	# Zone enemies give XP based on zone level vs player level.
	# Higher-level enemies give bonus XP; lower-level give penalty (min 10%).
	if zone_level > 0:
		var level_diff = zone_level - player_level
		var xp_mult = 1.0 + level_diff * 0.20  # +20% per level above player
		xp_mult = maxf(xp_mult, 0.10)           # min 10% XP from trivial enemies
		xp_reward = maxi(1, int(_base_xp_reward * xp_mult))
		var gold_mult = 1.0 + level_diff * 0.15
		gold_mult = maxf(gold_mult, 0.10)
		gold_reward = maxi(1, int(_base_gold_reward * gold_mult))
	else:
		# Pass 55: Use base values to prevent exponential compounding
		xp_reward = int(_base_xp_reward * (1.0 + maxf(player_level - 1, 0) * 0.05))
		gold_reward = int(_base_gold_reward * (1.0 + maxf(player_level - 1, 0) * 0.04))


## Returns damage multiplier when player attacks this enemy.
## Attacking enemies far above your level deals reduced damage (soft gate).
func get_player_damage_multiplier() -> float:
	if zone_level <= 0:
		return 1.0
	var player_level: int = GameManager.player_stats.get("level", 1)
	var level_diff = zone_level - player_level
	if level_diff <= 0:
		return 1.0  # Same level or below = full damage
	# Reduce player damage by 15% per level the enemy is above player
	return maxf(0.15, 1.0 - level_diff * 0.15)


## Returns damage multiplier for this enemy's attacks against the player.
## Enemies far above player level deal amplified damage (soft gate).
func get_enemy_damage_multiplier() -> float:
	if zone_level <= 0:
		return 1.0
	var player_level: int = GameManager.player_stats.get("level", 1)
	var level_diff = zone_level - player_level
	if level_diff <= 0:
		return 1.0  # Same level or below = normal damage
	# Amplify damage by 25% per level above player
	return 1.0 + level_diff * 0.25


# ══════════════════════════════════════════════════════════════════════════
# LOOT TABLE
# ══════════════════════════════════════════════════════════════════════════

func _generate_default_loot_table() -> void:
	loot_table = LootTable.new()
	loot_table.gold_min = maxi(1, gold_reward - 2)
	loot_table.gold_max = gold_reward + 3
	loot_table.xp_min = maxi(1, xp_reward - 2)
	loot_table.xp_max = xp_reward + 3
	loot_table.max_drops = 2

	var hp_entry = LootEntry.new()
	hp_entry.item_id = "health_potion"
	hp_entry.drop_chance = 15.0
	hp_entry.quantity_min = 1
	hp_entry.quantity_max = 1
	loot_table.entries.append(hp_entry)

	if max_health >= 100.0:
		var mp_entry = LootEntry.new()
		mp_entry.item_id = "mana_potion"
		mp_entry.drop_chance = 10.0
		mp_entry.quantity_min = 1
		mp_entry.quantity_max = 1
		loot_table.entries.append(mp_entry)

	if max_health >= 200.0:
		var stab_entry = LootEntry.new()
		stab_entry.item_id = "glitch_stabilizer"
		stab_entry.drop_chance = 5.0
		stab_entry.quantity_min = 1
		stab_entry.quantity_max = 1
		loot_table.entries.append(stab_entry)

	# Rare equipment drops from specific enemy types
	var rare_drop = _get_rare_drop_for_type()
	if not rare_drop.is_empty():
		var rare_entry = LootEntry.new()
		rare_entry.item_id = rare_drop
		rare_entry.drop_chance = 3.0  # 3% rare equipment drop
		rare_entry.quantity_min = 1
		rare_entry.quantity_max = 1
		loot_table.entries.append(rare_entry)


func _get_rare_drop_for_type() -> String:
	## Returns a rare equipment item_id based on enemy type, or "" if none.
	var my_name: String = name.to_lower()
	var my_class: String = get_script().get_global_name().to_lower() if get_script() else ""
	if "phase_spider" in my_class or "phase_spider" in my_name:
		return "phase_spider_fang"
	if "gear_sentry" in my_class or "gear_sentry" in my_name:
		return "gear_sentry_plating"
	if "corruption_elemental" in my_class or "corruption_elemental" in my_name:
		return "corruption_heart"
	if "mushroom_mimic" in my_class or "mushroom_mimic" in my_name:
		return "mimic_spore_charm"
	return ""


# ══════════════════════════════════════════════════════════════════════════
# HEALTH BAR
# ══════════════════════════════════════════════════════════════════════════

func _setup_health_bar() -> void:
	var bar_width = 40.0
	var bar_height = 5.0
	var is_boss = is_in_group("boss")
	if is_boss:
		bar_width = 80.0
		bar_height = 8.0

	_hp_bar_bg = ColorRect.new()
	_hp_bar_bg.name = "HPBarBG"
	_hp_bar_bg.size = Vector2(bar_width + 2, bar_height + 2)
	_hp_bar_bg.position = Vector2(-bar_width / 2.0 - 1, -55)
	_hp_bar_bg.color = Color(0.1, 0.1, 0.1, 0.8)
	_hp_bar_bg.z_index = 20
	_hp_bar_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_hp_bar_bg)

	_hp_bar = ProgressBar.new()
	_hp_bar.name = "HealthBar"
	_hp_bar.position = Vector2(-bar_width / 2.0, -54)
	_hp_bar.size = Vector2(bar_width, bar_height)
	_hp_bar.min_value = 0.0
	_hp_bar.max_value = 100.0
	_hp_bar.value = 100.0
	_hp_bar.show_percentage = false
	_hp_bar.z_index = 21
	_hp_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var fill_style = StyleBoxFlat.new()
	fill_style.bg_color = Color(0.9, 0.15, 0.2) if is_boss else Color(0.8, 0.2, 0.2)
	_hp_bar.add_theme_stylebox_override("fill", fill_style)

	var bg_style = StyleBoxFlat.new()
	bg_style.bg_color = Color(0.15, 0.05, 0.05, 0.6)
	_hp_bar.add_theme_stylebox_override("background", bg_style)
	add_child(_hp_bar)

	if is_boss:
		_hp_label = Label.new()
		_hp_label.name = "HPLabel"
		var display_name: String = get("enemy_display_name") if get("enemy_display_name") != null else name.replace("_", " ").capitalize()
		_hp_label.text = display_name
		_hp_label.add_theme_font_size_override("font_size", 10)
		_hp_label.add_theme_color_override("font_color", Color(1, 0.7, 0.7))
		_hp_label.position = Vector2(-bar_width / 2.0, -68)
		_hp_label.z_index = 22
		_hp_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(_hp_label)

	# Bosses start with visible HP bar; non-bosses start hidden
	_set_hp_bar_visible(is_boss)


func _set_hp_bar_visible(vis: bool) -> void:
	if _hp_bar_bg:
		_hp_bar_bg.visible = vis
	if _hp_bar:
		_hp_bar.visible = vis
	if _hp_label:
		_hp_label.visible = vis


func _update_health_bar() -> void:
	if _hp_bar and max_health > 0.0:
		_hp_bar.value = (current_health / max_health) * 100.0
		_set_hp_bar_visible(true)
		_hp_bar_visible_timer = HP_BAR_SHOW_DURATION

		var pct = current_health / max_health
		var fill_style = _hp_bar.get_theme_stylebox("fill") as StyleBoxFlat
		if fill_style:
			if pct > 0.5:
				fill_style.bg_color = Color(0.8, 0.2, 0.2).lerp(Color(0.9, 0.7, 0.1), (pct - 0.5) * 2.0)
			else:
				fill_style.bg_color = Color(0.6, 0.1, 0.1).lerp(Color(0.8, 0.2, 0.2), pct * 2.0)

			if pct <= 0.2 and pct > 0.0:
				fill_style.bg_color = Color(0.3, 0.9, 1.0)


# ══════════════════════════════════════════════════════════════════════════
# DEATH REWARDS
# ══════════════════════════════════════════════════════════════════════════

func _award_death_rewards() -> void:
	# In random encounters, XP/gold is batch-awarded by RandomEncounterSystem,
	# but item drops should still spawn so the player can collect them.
	var in_encounter: bool = has_node("/root/RandomEncounterSystem") and RandomEncounterSystem.is_in_encounter()
	var suppress_base_rewards: bool = bool(get_meta("suppress_base_rewards", false))

	if not in_encounter and not suppress_base_rewards:
		var final_xp = xp_reward
		var final_gold = gold_reward
		if has_node("/root/GameManager"):
			GameManager.add_xp(final_xp)
			GameManager.add_gold(final_gold)

		if has_node("/root/VFXLibrary"):
			VFXLibrary.spawn_status_indicator("+%d XP" % final_xp, global_position + Vector2(0, -40), get_parent(), false)
			VFXLibrary.spawn_status_indicator("+%d G" % final_gold, global_position + Vector2(0, -60), get_parent(), false)

	# Always spawn loot drops (even during encounters — items are gameplay rewards)
	if loot_table and has_node("/root/DropManager"):
		DropManager.spawn_drops(global_position, loot_table, get_parent())


# ══════════════════════════════════════════════════════════════════════════
# AUTOLOAD HELPER WRAPPERS
# ══════════════════════════════════════════════════════════════════════════

func _sfx(sound_name: String, variation: float = 0.0) -> void:
	if has_node("/root/SFXManager"):
		if variation > 0.0:
			SFXManager.play(sound_name, variation)
		else:
			SFXManager.play(sound_name)


func _vfx(effect_name: String, pos: Vector2) -> void:
	if has_node("/root/VFXLibrary"):
		VFXLibrary.spawn(effect_name, pos, get_parent())


func _screen_shake(intensity: float, duration: float) -> void:
	## Safe wrapper for CombatFX.apply_screen_shake.
	if has_node("/root/CombatFX"):
		CombatFX.apply_screen_shake(intensity, duration)


func _hitstop(duration: float) -> void:
	## Safe wrapper for CombatFX.apply_hitstop.
	if has_node("/root/CombatFX"):
		CombatFX.apply_hitstop(duration)


func _kill_effects(pos: Vector2, damage: float) -> void:
	## Safe wrapper for CombatFX.apply_kill_effects.
	if has_node("/root/CombatFX"):
		CombatFX.apply_kill_effects(pos, damage)


func _status_text(text: String, pos: Vector2, is_positive: bool = false) -> void:
	## Safe wrapper for VFXLibrary.spawn_status_indicator.
	if has_node("/root/VFXLibrary"):
		VFXLibrary.spawn_status_indicator(text, pos, get_parent(), is_positive)


func _tween_hurt() -> void:
	## Safe wrapper for TweenAnimator.play_hurt (static class, always available).
	var target: CanvasItem = get_node("Sprite") if has_node("Sprite") else self
	TweenAnimator.play_hurt(target)


func _tween_die() -> void:
	## Safe wrapper for TweenAnimator.play_die (static class, always available).
	var target: CanvasItem = get_node("Sprite") if has_node("Sprite") else self
	TweenAnimator.play_die(target)


func _boss_intro_zoom() -> void:
	## Safe wrapper for GameJuice.boss_intro_zoom.
	if has_node("/root/GameJuice"):
		GameJuice.boss_intro_zoom(self)


func _safe() -> bool:
	return is_inside_tree() and current_state != State.DEAD


func _has_gm() -> bool:
	return has_node("/root/GameManager")


## Return a frame-cached list of all enemies (shared across all EnemyBase instances).
## Prevents O(n²) when N enemies each query the group every frame.
func _get_enemies_cached() -> Array:
	var frame = Engine.get_process_frames()
	if frame != _enemies_cache_frame:
		_enemies_cache = get_tree().get_nodes_in_group("enemies")
		_enemies_cache_frame = frame
	return _enemies_cache


func spawn_in() -> void:
	var target_scale = scale  # Preserve intended scale (bosses may differ from 1x)
	modulate.a = 0.0
	scale = target_scale * 0.3
	var tw = create_tween()
	tw.tween_property(self, "modulate:a", 1.0, 0.3)
	tw.parallel().tween_property(self, "scale", target_scale, 0.3).set_trans(Tween.TRANS_BACK)
