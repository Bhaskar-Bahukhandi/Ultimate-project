extends EnemyBase
class_name SovereignBoss

## THE SOVEREIGN — Final boss of Chapter 3 and the entire game.
## A 5-phase fight representing the system's ultimate authority.
## Phase 1: Reality Warden — standard combat with system commands
## Phase 2: Code Rewriter — rewrites arena rules (gravity/speed changes)
## Phase 3: Memory Purge — summons echo clones of previous bosses
## Phase 4: Root Override — tries to revoke player's Root Access
## Phase 5: System Crash — desperate all-out assault, arena glitching

signal boss_defeated
signal phase_changed(new_phase: int)
signal system_command_used(command: String)
signal reality_rewritten(effect: String)

# ── Phase State ─────────────────────────────────────────────────────────
var phase: int = 1
var attack_timer: float = 0.0
var pattern_index: int = 0
var is_attacking: bool = false
var _active_projs: Array = []

# ── Phase Thresholds ────────────────────────────────────────────────────
const PHASE2_HP = 0.80
const PHASE3_HP = 0.60
const PHASE4_HP = 0.35
const PHASE5_HP = 0.15

var _phase_cooldowns: Dictionary = { 1: 2.5, 2: 2.0, 3: 3.0, 4: 2.0, 5: 1.2 }
var _phase_transition_timer: float = 1.0
const PHASE_TRANSITION_COOLDOWN: float = 0.5

# ── System Commands ─────────────────────────────────────────────────────
var _command_cooldown: float = 4.0
var _command_timer: float = 0.0
var _reality_effects_active: Dictionary = {}

# ── Phase 3: Echo Clones ───────────────────────────────────────────────
var _echo_clones: Array = []
var _has_summoned_echoes: bool = false

# ── Phase 4: Root Override ──────────────────────────────────────────────
var _override_attempts: int = 0
const MAX_OVERRIDE_ATTEMPTS = 3

# ── Phase 5: System Crash ──────────────────────────────────────────────
var _crash_timer: float = 0.0
var _crash_intensity: float = 0.0

# ── Teleport mechanics ─────────────────────────────────────────────────
var _teleport_cooldown: float = 3.0
var _teleport_timer: float = 0.0

# ── Attack patterns per phase ───────────────────────────────────────────
var _current_attack_pattern: Array = []


func _ready() -> void:
	enemy_name = "THE SOVEREIGN"
	max_health = 3500.0
	contact_damage = 35.0
	movement_speed = 130.0
	detection_range = 800.0
	attack_range = 160.0
	xp_reward = 2500
	gold_reward = 1500
	zone_level = 15
	elasticity = 0.8
	gravity_scale = 0.6
	add_to_group("boss")   # before super._ready(): EnemyBase builds a boss-style HP bar from it
	super._ready()
	current_health = max_health

	add_to_group("sovereign")

	# Ensure player input is restored on tree exit
	tree_exiting.connect(func():
		var p = find_player()
		if is_instance_valid(p) and p.has_method("set_input_locked"):
			p.set_input_locked(false)
		_cleanup_reality_effects()
	)

	if has_node("/root/GameManager"):
		if GameManager.has_method("start_boss_fight"):
			GameManager.start_boss_fight()

	# Visual: imposing golden-white sprite
	if has_node("Sprite") and get_node("Sprite") is ColorRect:
		var sprite = get_node("Sprite") as ColorRect
		sprite.color = Color(0.9, 0.8, 0.2)


# ═════════════════════════════════════════════════════════════════════════
# AI CORE
# ═════════════════════════════════════════════════════════════════════════

func _ai_behavior(delta: float) -> void:
	if max_health <= 0.0:
		return

	_phase_transition_timer += delta
	_teleport_timer += delta
	_command_timer += delta

	var hp_pct: float = current_health / max_health

	# Phase transitions (check highest first to handle large damage spikes)
	if _phase_transition_timer >= PHASE_TRANSITION_COOLDOWN:
		if hp_pct <= PHASE5_HP and phase < 5:
			_enter_phase(5)
		elif hp_pct <= PHASE4_HP and phase < 4:
			_enter_phase(4)
		elif hp_pct <= PHASE3_HP and phase < 3:
			_enter_phase(3)
		elif hp_pct <= PHASE2_HP and phase < 2:
			_enter_phase(2)

	attack_timer += delta

	match current_state:
		State.IDLE:
			velocity.x = 0.0
			if is_hostile and distance_to_player() < detection_range:
				current_state = State.CHASE
		State.CHASE:
			_chase_behavior(delta)
		State.ATTACK:
			_attack_phase_behavior(delta)
		State.STUNNED:
			velocity.x = move_toward(velocity.x, 0.0, 300.0 * delta)

	# Phase 5: continuous glitch effects
	if phase == 5:
		_crash_timer += delta
		_crash_intensity = minf(_crash_intensity + delta * 0.1, 1.0)
		if _crash_timer >= 2.0:
			_crash_timer = 0.0
			_system_crash_pulse()


func _chase_behavior(_delta: float) -> void:
	var dist = distance_to_player()
	if dist > detection_range * 1.2:
		current_state = State.IDLE
		return
	if dist < attack_range:
		current_state = State.ATTACK
		return

	# Phase 5: faster movement
	var speed_mult = 1.0 + (phase - 1) * 0.1
	if phase == 5:
		speed_mult = 1.5

	var dir = direction_to_player()
	velocity.x = dir.x * movement_speed * speed_mult

	# Try teleport in later phases
	if phase >= 2 and _teleport_timer >= _teleport_cooldown and dist > 200.0:
		_sovereign_teleport()


# ═════════════════════════════════════════════════════════════════════════
# PHASE TRANSITIONS
# ═════════════════════════════════════════════════════════════════════════

func _enter_phase(p: int) -> void:
	phase = p
	_phase_transition_timer = 0.0
	phase_changed.emit(p)
	is_attacking = false
	attack_timer = 0.0
	pattern_index = 0
	velocity = Vector2.ZERO

	# Phase transition juice
	if has_node("/root/GameJuice") and GameJuice.has_method("boss_phase_transition"):
		GameJuice.boss_phase_transition()
	elif has_node("/root/CombatFX"):
		CombatFX.apply_screen_shake(18.0, 0.5)
		CombatFX.apply_hitstop(0.2)

	match phase:
		2:
			_announce("REALITY REWRITE PROTOCOL ENGAGED")
			movement_speed = 140.0
			_command_cooldown = 3.5
			# Change sprite color
			_change_sprite_color(Color(0.2, 0.6, 0.9))
		3:
			_announce("MEMORY PURGE — SUMMONING ECHOES")
			movement_speed = 120.0
			if not _has_summoned_echoes:
				_summon_echo_clones()
			_change_sprite_color(Color(0.5, 0.1, 0.7))
		4:
			_announce("ROOT ACCESS OVERRIDE INITIATED")
			movement_speed = 150.0
			_command_cooldown = 2.5
			_change_sprite_color(Color(0.9, 0.2, 0.1))
		5:
			_announce("S Y S T E M   C R A S H")
			movement_speed = 180.0
			contact_damage *= 1.5
			_cleanup_reality_effects()
			_change_sprite_color(Color(1.0, 1.0, 1.0))
			# Constant screen shake in phase 5
			if has_node("/root/CombatFX"):
				CombatFX.apply_screen_shake(5.0, 30.0)


# ═════════════════════════════════════════════════════════════════════════
# PHASE-SPECIFIC ATTACKS
# ═════════════════════════════════════════════════════════════════════════

func _attack_phase_behavior(delta: float) -> void:
	var dist = distance_to_player()
	if dist > attack_range * 3.0:
		current_state = State.CHASE
		return

	var cd: float = _phase_cooldowns.get(phase, 2.0)

	if is_attacking:
		return

	if attack_timer >= cd:
		attack_timer = 0.0
		match phase:
			1:
				_phase1_attack()
			2:
				if _command_timer >= _command_cooldown:
					_phase2_reality_command()
				else:
					_phase1_attack()
			3:
				_phase3_attack()
			4:
				# Each override adds +5% corruption. It used to repeat for the
				# whole phase ("ATTEMPT 7/3"), so a long phase 4 alone could push
				# the meter to 100% and end the run mid-fight.
				if _command_timer >= _command_cooldown and _override_attempts < MAX_OVERRIDE_ATTEMPTS:
					_phase4_root_override()
				else:
					_phase3_attack()
			5:
				_phase5_attack()


## Phase 1: Standard melee + system projectiles
func _phase1_attack() -> void:
	is_attacking = true
	var dist = distance_to_player()

	if dist < attack_range:
		# Melee slash
		_telegraph_flash(Color(1, 0.8, 0.2), 0.3)
		await get_tree().create_timer(0.3).timeout
		if not is_inside_tree() or current_state == State.DEAD:
			is_attacking = false
			return

		var slash_size := Vector2(attack_range * 1.2, 100.0)
		var facing := signf(direction_to_player().x)
		if facing == 0.0:
			facing = 1.0
		_deal_damage_in_attack_hitbox(Vector2(facing * slash_size.x * 0.5, -38.0), slash_size, contact_damage, "sovereign_slash", 0.16)
		if has_node("/root/CombatFX"):
			CombatFX.apply_screen_shake(8.0, 0.15)
	else:
		# Fire system bolt
		_fire_system_bolt()

	is_attacking = false


## Phase 2: Rewrite arena rules
func _phase2_reality_command() -> void:
	is_attacking = true
	_command_timer = 0.0

	var commands = ["gravity_shift", "speed_lock", "damage_zone", "platform_remove"]
	var cmd = commands[randi() % commands.size()]
	system_command_used.emit(cmd)

	_announce("/ %s" % cmd.to_upper())

	match cmd:
		"gravity_shift":
			_reality_gravity_shift()
		"speed_lock":
			_reality_speed_lock()
		"damage_zone":
			_reality_damage_zone()
		"platform_remove":
			_fire_system_bolt()  # Fallback: fire a bolt

	is_attacking = false


func _reality_gravity_shift() -> void:
	reality_rewritten.emit("gravity")
	# Temporarily alter player gravity
	var players = get_tree().get_nodes_in_group("player")
	for p in players:
		if is_instance_valid(p) and "gravity_scale" in p:
			p.gravity_scale = 0.3 if randf() > 0.5 else 2.0

	if has_node("/root/VFXLibrary"):
		VFXLibrary.spawn_status_indicator("GRAVITY ALTERED!", global_position + Vector2(0, -80), get_parent(), false)

	# Reset after duration
	await get_tree().create_timer(4.0).timeout
	if not is_inside_tree():
		return
	for p in get_tree().get_nodes_in_group("player"):
		if is_instance_valid(p) and "gravity_scale" in p:
			p.gravity_scale = 1.0


func _reality_speed_lock() -> void:
	reality_rewritten.emit("speed")
	# Slow player temporarily
	var players = get_tree().get_nodes_in_group("player")
	for p in players:
		if is_instance_valid(p) and "movement_speed" in p:
			var original_speed = p.movement_speed
			p.movement_speed *= 0.5

			if has_node("/root/VFXLibrary"):
				VFXLibrary.spawn_status_indicator("SPEED LOCKED!", p.global_position + Vector2(0, -60), get_parent(), false)

			await get_tree().create_timer(3.0).timeout
			if not is_inside_tree(): return
			if is_instance_valid(p) and "movement_speed" in p:
				p.movement_speed = original_speed


func _reality_damage_zone() -> void:
	reality_rewritten.emit("damage_zone")
	# Create a damage zone on the ground
	var zone = Area2D.new()
	zone.name = "DamageZone"

	var visual = ColorRect.new()
	visual.size = Vector2(200, 20)
	visual.position = Vector2(-100, -10)
	visual.color = Color(1.0, 0.1, 0.1, 0.4)
	visual.mouse_filter = Control.MOUSE_FILTER_IGNORE
	zone.add_child(visual)

	var col = CollisionShape2D.new()
	var shape = RectangleShape2D.new()
	shape.size = Vector2(200, 20)
	col.shape = shape
	zone.add_child(col)

	zone.collision_layer = 8
	zone.collision_mask = 2

	# Place at player's feet
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		zone.global_position = (players[0] as Node2D).global_position + Vector2(0, 20)

	if get_parent():
		get_parent().add_child(zone)

	# Damage on contact
	zone.body_entered.connect(func(body):
		if body.is_in_group("player") and body.has_method("take_damage"):
			body.take_damage(15.0)
	)

	if has_node("/root/VFXLibrary"):
		VFXLibrary.spawn_status_indicator("HAZARD ZONE!", zone.global_position + Vector2(0, -30), get_parent(), false)

	# Remove after 5 seconds
	await get_tree().create_timer(5.0).timeout
	if is_instance_valid(zone):
		zone.queue_free()


## Phase 3: Summon echo clones of previous bosses
func _summon_echo_clones() -> void:
	_has_summoned_echoes = true

	# Summon 2 weakened echo clones (Tutorial Knight echo + Clockwork echo)
	var echo_configs = [
		{"name": "Echo Knight", "hp": 300.0, "dmg": 15.0, "color": Color(0.5, 0.5, 0.5, 0.6)},
		{"name": "Echo Automaton", "hp": 250.0, "dmg": 12.0, "color": Color(0.5, 0.4, 0.3, 0.6)},
	]

	for config in echo_configs:
		var echo = CharacterBody2D.new()
		echo.name = config["name"].replace(" ", "")

		# Create sprite
		var sprite_rect = ColorRect.new()
		sprite_rect.name = "Sprite"
		sprite_rect.size = Vector2(48, 64)
		sprite_rect.position = Vector2(-24, -64)
		sprite_rect.color = config["color"]
		sprite_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		echo.add_child(sprite_rect)

		# Collision
		var col_shape = CollisionShape2D.new()
		var rect_shape = RectangleShape2D.new()
		rect_shape.size = Vector2(48, 64)
		col_shape.shape = rect_shape
		col_shape.position = Vector2(0, -32)
		echo.add_child(col_shape)

		echo.collision_layer = 4
		echo.collision_mask = 1

		# Use corrupted_guard as a base AI (has melee + patrol)
		var script_path = "res://scripts/combat/enemies/corrupted_guard.gd"
		if ResourceLoader.exists(script_path):
			echo.set_script(load(script_path))

		# Position near boss
		var offset_x = 150.0 if echo_configs.find(config) == 0 else -150.0
		echo.global_position = global_position + Vector2(offset_x, 0)

		if get_parent():
			get_parent().add_child(echo)

		# Override stats after script applies
		if "max_health" in echo:
			echo.max_health = config["hp"]
			echo.current_health = config["hp"]
			echo.contact_damage = config["dmg"]
			echo.enemy_name = config["name"]
			echo.xp_reward = 50
			echo.gold_reward = 30

		if echo.has_signal("died"):
			echo.died.connect(func(): _on_echo_died(echo))

		_echo_clones.append(echo)

	if has_node("/root/VFXLibrary"):
		VFXLibrary.spawn_status_indicator("ECHOES SUMMONED!", global_position + Vector2(0, -90), get_parent(), false)


func _on_echo_died(_echo: Node) -> void:
	_echo_clones.erase(_echo)


func _phase3_attack() -> void:
	is_attacking = true

	# Mix of melee and system bolts, faster pace
	var attacks = [_phase1_attack, _fire_system_bolt, _sovereign_teleport]
	var chosen = attacks[randi() % attacks.size()]
	if chosen == _phase1_attack:
		await _phase1_attack()
	elif chosen == _fire_system_bolt:
		_fire_system_bolt()
	else:
		await _sovereign_teleport()

	if not _safe(): return
	is_attacking = false


## Phase 4: Attempt to override player's Root Access
func _phase4_root_override() -> void:
	is_attacking = true
	_command_timer = 0.0
	_override_attempts += 1

	_announce("ROOT ACCESS OVERRIDE ATTEMPT %d/%d" % [_override_attempts, MAX_OVERRIDE_ATTEMPTS])

	# Visual: dramatic charging
	_telegraph_flash(Color(1, 0, 0), 0.6)

	await get_tree().create_timer(0.8).timeout
	if not is_inside_tree() or current_state == State.DEAD:
		is_attacking = false
		return

	# Player's Root Access "blocks" the override — deal corruption instead
	if has_node("/root/GameManager"):
		GameManager.add_glitch_corruption(5.0)

	if has_node("/root/VFXLibrary"):
		VFXLibrary.spawn_status_indicator("ROOT ACCESS HOLDS!", global_position + Vector2(0, -60), get_parent(), false)

	if has_node("/root/CombatFX"):
		CombatFX.apply_screen_shake(15.0, 0.3)

	# Fire burst of bolts after failed override
	for i in range(3):
		_fire_system_bolt()
		await get_tree().create_timer(0.2).timeout
		if not is_inside_tree() or current_state == State.DEAD:
			break

	if not _safe(): return
	is_attacking = false


## Phase 5: All-out desperate assault
func _phase5_attack() -> void:
	is_attacking = true

	# Rapid alternating attacks
	var attack_type = randi() % 4
	match attack_type:
		0:
			# Rapid bolt barrage
			for i in range(5):
				if not is_inside_tree() or current_state == State.DEAD:
					break
				_fire_system_bolt()
				await get_tree().create_timer(0.15).timeout
		1:
			# Teleport + melee combo
			await _sovereign_teleport()
			await get_tree().create_timer(0.3).timeout
			if is_inside_tree() and current_state != State.DEAD:
				var combo_size := Vector2(attack_range * 1.5, 104.0)
				var combo_facing := signf(direction_to_player().x)
				if combo_facing == 0.0:
					combo_facing = 1.0
				_deal_damage_in_attack_hitbox(Vector2(combo_facing * combo_size.x * 0.5, -40.0), combo_size, contact_damage * 1.3, "sovereign_combo", 0.16)
				if has_node("/root/CombatFX"):
					CombatFX.apply_screen_shake(12.0, 0.2)
		2:
			# System crash wave (expanding AoE)
			_system_crash_wave()
		3:
			# Reality glitch — random effects
			_phase2_reality_command()

	if not _safe(): return
	is_attacking = false


func _system_crash_pulse() -> void:
	# Periodic screen-wide glitch effect during phase 5
	if has_node("/root/CombatFX"):
		CombatFX.apply_screen_shake(3.0 + _crash_intensity * 8.0, 0.3)

	# Small random corruption damage
	if has_node("/root/GameManager") and randf() < 0.3:
		GameManager.add_glitch_corruption(0.5)


func _system_crash_wave() -> void:
	# Expanding damage wave from boss position
	_announce("SYSTEM CRASH WAVE!")

	_telegraph_flash(Color(1, 1, 1), 0.5)
	await get_tree().create_timer(0.6).timeout
	if not is_inside_tree() or current_state == State.DEAD:
		return

	# Create expanding visual
	var wave = ColorRect.new()
	wave.name = "CrashWave"
	wave.size = Vector2(20, 600)
	wave.position = Vector2(-10, -300)
	wave.color = Color(1, 1, 1, 0.6)
	wave.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if get_parent():
		get_parent().add_child(wave)
		wave.global_position = global_position

	# Expand outward
	var tw = create_tween()
	tw.tween_property(wave, "size:x", 400.0, 0.5)
	tw.parallel().tween_property(wave, "position:x", -200.0, 0.5)
	tw.parallel().tween_property(wave, "modulate:a", 0.0, 0.5)
	tw.tween_callback(func():
		if is_instance_valid(wave):
			wave.queue_free()
	)

	# Damage players caught in the wave
	await get_tree().create_timer(0.25).timeout
	if not is_inside_tree():
		return
	var players = get_tree().get_nodes_in_group("player")
	for p in players:
		if is_instance_valid(p):
			var dist = abs(p.global_position.x - global_position.x)
			if dist < 200.0 and p.has_method("take_damage"):
				p.take_damage(25.0)

	if has_node("/root/CombatFX"):
		CombatFX.apply_screen_shake(20.0, 0.4)


# ═════════════════════════════════════════════════════════════════════════
# UTILITY ATTACKS
# ═════════════════════════════════════════════════════════════════════════

func _fire_system_bolt() -> void:
	var player = find_player()
	if not player:
		return

	var dir = (player.global_position - global_position).normalized()

	var bolt = Area2D.new()
	bolt.name = "SystemBolt"

	var visual = ColorRect.new()
	visual.size = Vector2(14, 8)
	visual.position = Vector2(-7, -4)
	visual.color = Color(1.0, 0.9, 0.2, 0.9)
	visual.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bolt.add_child(visual)

	var col = CollisionShape2D.new()
	var shape = CircleShape2D.new()
	shape.radius = 7.0
	col.shape = shape
	bolt.add_child(col)

	bolt.collision_layer = 8
	bolt.collision_mask = 2
	bolt.global_position = global_position + Vector2(0, -30)

	if get_parent():
		get_parent().add_child(bolt)

	bolt.body_entered.connect(func(body):
		if body.is_in_group("player") and body.has_method("take_damage"):
			var bolt_dmg = 18.0 + phase * 3.0
			body.take_damage(bolt_dmg)
			if has_node("/root/CombatFX"):
				CombatFX.apply_screen_shake(4.0, 0.1)
		if is_instance_valid(bolt):
			bolt.queue_free()
	)

	# Animate bolt movement
	var speed = 300.0 + phase * 30.0
	var end_pos = bolt.global_position + dir * speed * 3.0
	var tw = create_tween()
	tw.tween_property(bolt, "global_position", end_pos, 3.0)
	tw.tween_callback(func():
		if is_instance_valid(bolt):
			bolt.queue_free()
	)

	_active_projs.append(bolt)


func _sovereign_teleport() -> void:
	if current_state == State.DEAD:
		return

	_teleport_timer = 0.0
	var player = find_player()
	if not player:
		return

	# Disappear
	if has_node("Sprite"):
		var sprite = get_node("Sprite")
		var tw = create_tween()
		tw.tween_property(sprite, "modulate:a", 0.0, 0.1)

	await get_tree().create_timer(0.15).timeout
	if not is_inside_tree() or current_state == State.DEAD:
		return

	# Teleport near player
	var offset = 120.0 if randf() > 0.5 else -120.0
	global_position = player.global_position + Vector2(offset, 0)

	# Reappear
	if has_node("Sprite"):
		var sprite = get_node("Sprite")
		var tw = create_tween()
		tw.tween_property(sprite, "modulate:a", 1.0, 0.1)
		tw.tween_property(sprite, "modulate", Color(1, 0.8, 0.2), 0.1)
		tw.tween_property(sprite, "modulate", Color.WHITE, 0.1)


func _telegraph_flash(color: Color, duration: float) -> void:
	if has_node("Sprite"):
		var sprite = get_node("Sprite")
		var tw = create_tween()
		tw.tween_property(sprite, "modulate", color, duration * 0.4)
		tw.tween_property(sprite, "modulate", Color.WHITE, duration * 0.6)


func _change_sprite_color(color: Color) -> void:
	if has_node("Sprite") and get_node("Sprite") is ColorRect:
		(get_node("Sprite") as ColorRect).color = color


func _announce(text: String) -> void:
	if has_node("/root/VFXLibrary"):
		VFXLibrary.spawn_status_indicator(text, global_position + Vector2(0, -90), get_parent(), false)


func _cleanup_reality_effects() -> void:
	# Reset any lingering reality alterations
	var players = get_tree().get_nodes_in_group("player")
	for p in players:
		if is_instance_valid(p):
			if "gravity_scale" in p:
				p.gravity_scale = 1.0
			if "movement_speed" in p:
				# Don't know original speed; set to default combat speed
				p.movement_speed = 330.0

	# Clean up echo clones
	for echo in _echo_clones:
		if is_instance_valid(echo):
			echo.queue_free()
	_echo_clones.clear()


# ═════════════════════════════════════════════════════════════════════════
# DEATH
# ═════════════════════════════════════════════════════════════════════════

func die() -> void:
	if current_state == State.DEAD:
		return

	_cleanup_reality_effects()

	# Clean up active projectiles
	for proj in _active_projs:
		if is_instance_valid(proj):
			proj.queue_free()
	_active_projs.clear()

	boss_defeated.emit()

	# Set chapter 3 complete flags
	if has_node("/root/GameManager"):
		GameManager.set_story_flag("ch3_sovereign_defeated", true)
		GameManager.set_story_flag("ch3_complete", true)

	super.die()
