extends EnemyBase
class_name AdministratorProxyBoss

## Administrator Proxy — Final boss of Chapter 2. 4-phase fight.
## Phase 1: Standard combat.  Phase 2: Admin commands (/ban, /mute, /teleport).
## Phase 3: /delete attempts (blocked by Root Access).  Phase 4: Root Access duel.

signal boss_defeated
signal phase_changed(new_phase: int)
signal admin_command_used(command: String)

# ── Phase state ─────────────────────────────────────────────────────────
var phase: int = 1
var attack_timer: float = 0.0
var pattern_index: int = 0
var is_attacking: bool = false
var _active_projs: Array = []
var _command_cd: float = 5.0
var _command_timer: float = 0.0
var _delete_attempts: int = 0
const MAX_DELETE_ATTEMPTS = 3

# ── Thresholds ──────────────────────────────────────────────────────────
const PHASE2_HP = 0.75
const PHASE3_HP = 0.45
const PHASE4_HP = 0.20

var _phase_cooldowns = { 1: 2.0, 2: 2.5, 3: 3.0, 4: 1.5 }
var _phase_transition_timer: float = 1.0  # Start above threshold so initial phase checks work
const PHASE_TRANSITION_COOLDOWN: float = 0.5  # Prevent rapid-fire phase transitions


func _ready() -> void:
	# Set boss stats BEFORE super._ready() so level scaling applies correctly
	enemy_name = "Administrator Proxy"
	xp_reward = 1200
	gold_reward = 600
	movement_speed = 115.0
	max_health = 2000.0
	contact_damage = 100.0
	detection_range = 600.0
	attack_range = 140.0
	zone_level = 11  # Rec Lv 11 — Ironhold Underground final boss
	elasticity = 1.0
	gravity_scale = 0.8
	add_to_group("boss")   # before super._ready(): EnemyBase builds a boss-style HP bar from it
	super._ready()
	current_health = max_health

	add_to_group("administrator")

	tree_exiting.connect(func():
		var p = find_player()
		if is_instance_valid(p) and p.has_method("set_input_locked"):
			p.set_input_locked(false)
	)

	if has_node("/root/GameManager"):
		GameManager.start_boss_fight()


# ═════════════════════════════════════════════════════════════════════════
# AI
# ═════════════════════════════════════════════════════════════════════════

func _ai_behavior(delta: float) -> void:
	if max_health <= 0.0:
		return
	_phase_transition_timer += delta
	var hp_pct = current_health / max_health
	# Check lower phases first so a large hit doesn't skip phases
	# Guard: wait PHASE_TRANSITION_COOLDOWN between transitions to prevent pile-up
	if _phase_transition_timer >= PHASE_TRANSITION_COOLDOWN:
		if hp_pct <= PHASE2_HP and phase < 2:
			_enter_phase(2)
		elif hp_pct <= PHASE3_HP and phase < 3:
			_enter_phase(3)
		elif hp_pct <= PHASE4_HP and phase < 4:
			_enter_phase(4)

	attack_timer += delta
	_command_timer += delta

	match current_state:
		State.IDLE:
			velocity.x = 0.0
			if is_hostile and distance_to_player() < detection_range:
				current_state = State.CHASE
		State.CHASE:
			_chase(delta)
		State.ATTACK:
			_attack(delta)
		State.STUNNED:
			velocity.x = move_toward(velocity.x, 0.0, 250.0 * delta)


func _enter_phase(p: int) -> void:
	phase = p
	_phase_transition_timer = 0.0  # Guard against rapid-fire transitions
	phase_changed.emit(p)
	is_attacking = false
	attack_timer = 0.0
	pattern_index = 0
	_command_timer = 0.0
	velocity = Vector2.ZERO

	# Full boss phase transition juice
	if has_node("/root/GameJuice"):
		GameJuice.boss_phase_transition()
	else:
		_screen_shake(14.0, 0.4)
		_hitstop(0.15)

	match phase:
		2:
			_status_text("ADMIN MODE ACTIVATED", global_position + Vector2(0, -70), false)
			movement_speed = 120.0
			_vfx("vfx_glitch_sparkle", global_position)
			_vfx("vfx_glitch_sparkle", global_position + Vector2(40, -40))
			if has_node("Sprite"):
				var tw = create_tween()
				tw.tween_property(get_node("Sprite"), "modulate", Color(2.0, 1.0, 0.3), 0.05)
				tw.tween_property(get_node("Sprite"), "modulate", Color(1.0, 0.5, 0.2), 0.3)
		3:
			_status_text("/DELETE PROTOCOL INITIATED", global_position + Vector2(0, -70), false)
			contact_damage = 60.0
			_vfx("vfx_glitch_sparkle", global_position)
			_vfx("vfx_enemy_death", global_position + Vector2(0, -20))
			if has_node("Sprite"):
				var tw = create_tween()
				tw.tween_property(get_node("Sprite"), "modulate", Color(3.0, 0.0, 0.0), 0.05)
				tw.tween_property(get_node("Sprite"), "modulate", Color(1.0, 0.2, 0.2), 0.4)
		4:
			_status_text("ROOT ACCESS DUEL!", global_position + Vector2(0, -70), false)
			movement_speed = 150.0
			for key in _phase_cooldowns:
				_phase_cooldowns[key] = 1.2
			# Extra dramatic for final phase
			_vfx("vfx_glitch_sparkle", global_position)
			_vfx("vfx_glitch_sparkle", global_position + Vector2(-40, -40))
			_vfx("vfx_glitch_sparkle", global_position + Vector2(40, -40))
			_vfx("vfx_enemy_death", global_position + Vector2(0, -30))
			if has_node("Sprite"):
				var tw = create_tween()
				tw.tween_property(get_node("Sprite"), "modulate", Color(3.0, 0.5, 3.0), 0.05)
				tw.tween_property(get_node("Sprite"), "modulate", Color(0.8, 0.2, 0.8), 0.4)


func _chase(_delta: float) -> void:
	var dist = distance_to_player()
	if dist < attack_range:
		current_state = State.ATTACK
		return
	var dir = direction_to_player()
	velocity.x = dir.x * movement_speed
	if phase >= 4:
		velocity.y = dir.y * movement_speed * 0.5


func _attack(_delta: float) -> void:
	if distance_to_player() > attack_range * 3.0:
		current_state = State.CHASE
		return
	if is_attacking:
		return
	var cd: float = _phase_cooldowns.get(phase, 2.0)
	if attack_timer >= cd:
		_execute()
		attack_timer = 0.0


func _execute() -> void:
	match phase:
		1: await _p1()
		2: await _p2()
		3: await _p3()
		4: await _p4()


# ═════════════════════════════════════════════════════════════════════════
# PHASE 1 — Standard Combat
# ═════════════════════════════════════════════════════════════════════════

func _p1() -> void:
	is_attacking = true
	var atk = ["slash", "bolt", "dash"][pattern_index % 3]
	pattern_index += 1
	match atk:
		"slash": await _admin_slash()
		"bolt":  _energy_bolt()
		"dash":  await _dash_strike()
	if is_inside_tree():
		is_attacking = false


func _admin_slash() -> void:
	velocity.x = direction_to_player().x * 300.0
	await get_tree().create_timer(0.2).timeout
	if not _safe(): return
	_deal_melee(contact_damage, 80.0)
	velocity.x = 0.0


func _energy_bolt() -> void:
	var player = find_player()
	if not player: return
	_spawn_proj((player.global_position - global_position).normalized(), 350.0, Color(1, 0.2, 0.2))


func _dash_strike() -> void:
	await get_tree().create_timer(0.3).timeout
	if not _safe(): return
	var player = find_player()
	if not player: return
	var offset = 100.0 if global_position.x < player.global_position.x else -100.0
	global_position = Vector2(player.global_position.x + offset, player.global_position.y)
	_vfx("vfx_glitch_sparkle", global_position)
	velocity.x = direction_to_player().x * 400.0
	await get_tree().create_timer(0.2).timeout
	if not _safe(): return
	_deal_melee(contact_damage * 1.2, 70.0)
	velocity.x = 0.0


# ═════════════════════════════════════════════════════════════════════════
# PHASE 2 — Admin Commands
# ═════════════════════════════════════════════════════════════════════════

func _p2() -> void:
	is_attacking = true
	if _command_timer >= _command_cd:
		var cmd = ["ban", "mute", "teleport"][pattern_index % 3]
		await _admin_command(cmd)
		if not _safe(): return
		_command_timer = 0.0
	else:
		var atk = ["slash", "bolt", "double_bolt"][pattern_index % 3]
		match atk:
			"slash":      await _admin_slash()
			"bolt":       _energy_bolt()
			"double_bolt":
				_energy_bolt()
				if _safe():
					await get_tree().create_timer(0.3).timeout
					if _safe():
						_energy_bolt()
	if not _safe(): return
	pattern_index += 1
	if is_inside_tree():
		is_attacking = false


func _admin_command(command: String) -> void:
	admin_command_used.emit(command)
	_status_text("/" + command.to_upper(), global_position + Vector2(0, -50), false)

	match command:
		"ban":
			var player = find_player()
			if player and player.has_method("take_damage"):
				player.take_damage(15.0, global_position, enemy_name, "boss")
				_status_text("/BAN — STUNNED!", player.global_position + Vector2(0, -40), false)
			await get_tree().create_timer(1.0).timeout
		"mute":
			var player = find_player()
			var pos = player.global_position + Vector2(0, -40) if player else global_position
			_status_text("/MUTE — SILENCED!", pos, false)
			await get_tree().create_timer(1.5).timeout
		"teleport":
			var player = find_player()
			if player:
				var offset = randf_range(-200, 200)
				var target = player.global_position + Vector2(offset, 0)
				# Verify destination is not inside solid geometry (multi-point margin check)
				var space = get_world_2d().direct_space_state
				var is_clear = true
				if space:
					# Check center + 4 cardinal offsets to prevent partial wall clips
					var margin_pts = [Vector2.ZERO, Vector2(16, 0), Vector2(-16, 0), Vector2(0, -24), Vector2(0, 24)]
					for pt in margin_pts:
						var params = PhysicsPointQueryParameters2D.new()
						params.position = target + pt
						params.collision_mask = 1  # terrain layer
						if not space.intersect_point(params, 1).is_empty():
							is_clear = false
							break
					if is_clear:
						player.global_position = target
				_vfx("vfx_glitch_sparkle", player.global_position)
				_status_text("/TELEPORT!", player.global_position + Vector2(0, -40), false)
			await get_tree().create_timer(0.5).timeout


# ═════════════════════════════════════════════════════════════════════════
# PHASE 3 — /DELETE Protocol
# ═════════════════════════════════════════════════════════════════════════

func _p3() -> void:
	is_attacking = true
	if _delete_attempts < MAX_DELETE_ATTEMPTS and _command_timer >= _command_cd * 1.5:
		await _attempt_delete()
		if not _safe(): return
		_command_timer = 0.0
	else:
		var atk = ["triple", "barrage", "slam"][pattern_index % 3]
		match atk:
			"triple":
				for i in 3:
					await _admin_slash()
					if not _safe(): break
					await get_tree().create_timer(0.15).timeout
					if not _safe(): break
			"barrage":
				for i in 4:
					await _energy_bolt()
					if not _safe(): break
					await get_tree().create_timer(0.2).timeout
					if not _safe(): break
			"slam":
				velocity.y = -500.0
				await get_tree().create_timer(0.5).timeout
				if _safe():
					velocity.y = 800.0
					await get_tree().create_timer(0.3).timeout
					if _safe():
						_deal_melee(contact_damage * 2.0, 160.0)
						_vfx("vfx_hit_spark", global_position)
	if not _safe(): return
	pattern_index += 1
	if is_inside_tree():
		is_attacking = false


func _attempt_delete() -> void:
	_delete_attempts += 1
	_status_text("/DELETE @KAELEN", global_position + Vector2(0, -60), false)
	await get_tree().create_timer(1.5).timeout
	if not _safe(): return

	var player = find_player()
	if player:
		_vfx("vfx_glitch_sparkle", player.global_position)
		_status_text("ROOT ACCESS: DELETE BLOCKED!", player.global_position + Vector2(0, -50), true)
		if player.has_method("take_damage"):
			player.take_damage(contact_damage * 0.5, global_position, enemy_name, "boss")
		if has_node("/root/GameManager"):
			GameManager.add_glitch_corruption(3.0)
	await get_tree().create_timer(0.5).timeout


# ═════════════════════════════════════════════════════════════════════════
# PHASE 4 — Root Access Duel
# ═════════════════════════════════════════════════════════════════════════

func _p4() -> void:
	is_attacking = true
	var atk = ["code_slash", "reality_tear", "overload", "final_delete"][pattern_index % 4]
	pattern_index += 1

	match atk:
		"code_slash":
			for i in 4:
				velocity.x = direction_to_player().x * 350.0
				await get_tree().create_timer(0.12).timeout
				if not _safe(): break
				_deal_melee(contact_damage * 0.5, 70.0)
			if _safe():
				velocity.x = 0.0
		"reality_tear":
			for i in 8:
				var angle = i * (TAU / 8.0)
				_spawn_proj(Vector2(cos(angle), sin(angle)), 200.0, Color(1, 0, 0.5))
			await get_tree().create_timer(0.5).timeout
		"overload":
			_status_text("SYSTEM OVERLOAD!", global_position + Vector2(0, -50), false)
			await get_tree().create_timer(1.0).timeout
			if _safe():
				_deal_melee(contact_damage * 1.8, 250.0)
				_vfx("vfx_hit_spark", global_position)
		"final_delete":
			_status_text("/DELETE — DENIED", global_position + Vector2(0, -50), false)
			await get_tree().create_timer(0.8).timeout
			if _safe():
				await _energy_bolt()

	if is_inside_tree():
		is_attacking = false


# ═════════════════════════════════════════════════════════════════════════
# HELPERS
# ═════════════════════════════════════════════════════════════════════════

func _deal_melee(damage: float, range_px: float) -> void:
	var player = find_player()
	if player and player.has_method("take_damage"):
		if global_position.distance_to(player.global_position) < range_px:
			player.take_damage(damage, global_position, enemy_name, "boss")


func _spawn_proj(direction: Vector2, speed: float, color: Color) -> void:
	var proj = ColorRect.new()
	proj.color = color
	proj.size = Vector2(14, 14)
	proj.pivot_offset = Vector2(7, 7)
	proj.mouse_filter = Control.MOUSE_FILTER_IGNORE
	get_parent().add_child(proj)
	proj.global_position = global_position
	_active_projs.append(proj)

	var elapsed = 0.0
	while elapsed < 3.0 and is_instance_valid(proj) and _safe():
		proj.global_position += direction * speed * get_process_delta_time()
		proj.rotation += 5.0 * get_process_delta_time()
		elapsed += get_process_delta_time()

		var player = find_player()
		if player and player.has_method("take_damage"):
			if proj.global_position.distance_to(player.global_position) < 20.0:
				player.take_damage(contact_damage * 0.4, proj.global_position, enemy_name, "boss")
				proj.queue_free()
				_active_projs.erase(proj)
				return
		await get_tree().process_frame
		if not is_inside_tree():
			if is_instance_valid(proj):
				proj.queue_free()
			_active_projs.erase(proj)
			return
	_active_projs.erase(proj)
	if is_instance_valid(proj):
		proj.queue_free()



# ═════════════════════════════════════════════════════════════════════════
# DEATH
# ═════════════════════════════════════════════════════════════════════════

func die() -> void:
	if current_state == State.DEAD:
		return
	current_state = State.DEAD
	velocity = Vector2.ZERO
	set_physics_process(false)
	if has_node("/root/GameManager"):
		GameManager.end_boss_fight()
	boss_defeated.emit()
	# Full boss death sequence — extra dramatic for final boss
	if has_node("/root/GameJuice"):
		GameJuice.boss_death_sequence()
	# Clean up all active projectiles
	for p in _active_projs:
		if is_instance_valid(p):
			p.queue_free()
	_active_projs.clear()
	_status_text("[ADMIN PROXY TERMINATED]", global_position + Vector2(0, -70), false)
	_status_text("[SYSTEM AUTHORITY REVOKED]", global_position + Vector2(0, -90), true)

	for i in 10:
		var offset = Vector2(randf_range(-50, 50), randf_range(-60, 10))
		_vfx("vfx_enemy_death", global_position + offset)
		await get_tree().create_timer(0.12).timeout
		if not is_inside_tree():
			return

	if has_node("/root/GameManager"):
		GameManager.add_glitch_corruption(8.0)
	super.die()
