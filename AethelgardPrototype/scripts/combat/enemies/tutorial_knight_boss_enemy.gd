extends EnemyBase
class_name TutorialKnightBossEnemy

## Tutorial Knight — Chapter 1 boss. 4-phase fight teaching hack+slash mastery.
##
## Phase 1 (100-70 % HP): Disciplined swordsmanship, staggers on hit.
## Phase 2 ( 70-45 % HP): Aggressive — adds charge & shield-bash.
## Phase 3 ( 45-20 % HP): Corruption glitches — teleport slash, shockwave.
## Phase 3.5 Rage (20-10 %): Double speed, relentless combos, no flinch.
## Phase 4    (<10 % HP): Frozen in loop — Root Access or kill by force.

# ── Signals ─────────────────────────────────────────────────────────────
signal boss_defeated
signal phase_changed(new_phase: int)
signal root_access_triggered

# ── Phase thresholds ────────────────────────────────────────────────────
enum BossPhase { PHASE_1, PHASE_2, PHASE_3, PHASE_3_RAGE, PHASE_4 }

const PHASE_2_HP_PCT = 0.70
const PHASE_3_HP_PCT = 0.45
const PHASE_RAGE_HP_PCT = 0.20
const PHASE_4_HP_PCT = 0.10

# ── Phase state ─────────────────────────────────────────────────────────
var current_boss_phase: BossPhase = BossPhase.PHASE_1
var _phase_paused: bool = false
var _phase_pause_timer: float = 0.0
var _phase_pause_duration: float = 1.5
var _pending_phase: int = 0

# ── Attack bookkeeping ──────────────────────────────────────────────────
var _boss_attack_timer: float = 0.0
var _boss_attack_cooldown: float = 1.6
var _boss_combo_count: int = 0
var _boss_max_combo: int = 2
var _attack_active: bool = false
var _stagger_active: bool = false
var _slam_wave_active: bool = false
var _charge_rushing: bool = false
var _recent_attacks: Array[String] = []

# ── Rage ────────────────────────────────────────────────────────────────
var _is_enraged: bool = false

# ── Phase 4 lock ────────────────────────────────────────────────────────
var phase_4_locked: bool = false
var _phase_pulse_tween: Tween  # Stored for cleanup

# ── Intro tracking ──────────────────────────────────────────────────────
var _intro_played: bool = false


# ═════════════════════════════════════════════════════════════════════════
# LIFECYCLE
# ═════════════════════════════════════════════════════════════════════════

func _ready() -> void:
	# Set boss stats BEFORE super._ready() so level scaling applies correctly
	enemy_name = "Tutorial Knight"
	max_health = 600.0
	contact_damage = 35.0
	movement_speed = 120.0
	detection_range = 450.0
	attack_range = 80.0
	xp_reward = 400
	gold_reward = 200
	zone_level = 5  # Rec Lv 5 — soft gate for Oakhaven boss
	elasticity = 1.0
	gravity_scale = 1.0
	super._ready()
	current_health = max_health

	add_to_group("boss")

	tree_exiting.connect(func():
		var p = find_player()
		if is_instance_valid(p) and p.has_method("set_input_locked"):
			p.set_input_locked(false)
	)

	if not _has_gm() or not GameManager.story_flags.get("ch1_tutorial_knight_defeated", false):
		call_deferred("_start_boss_intro")


# ═════════════════════════════════════════════════════════════════════════
# BOSS INTRO CUTSCENE
# ═════════════════════════════════════════════════════════════════════════

func _start_boss_intro() -> void:
	if _intro_played:
		return
	_intro_played = true
	if has_node("/root/GameManager"):
		GameManager.start_boss_fight()
	is_hostile = false
	current_state = State.IDLE

	var player = find_player()
	if player and player.has_method("set_input_locked"):
		player.set_input_locked(true)

	_boss_intro_zoom()

	# ── Letterbox + title card ──
	var canvas = CanvasLayer.new()
	canvas.layer = 90
	canvas.name = "BossIntroCard"
	add_child(canvas)

	var card_bg = ColorRect.new()
	card_bg.color = Color(0, 0, 0, 0)
	card_bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	card_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(card_bg)

	var center = CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(center)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 4)
	vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	center.add_child(vbox)

	var title_lbl = Label.new()
	title_lbl.text = "TUTORIAL KNIGHT"
	title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_lbl.add_theme_font_size_override("font_size", 32)
	title_lbl.add_theme_color_override("font_color", Color(0.85, 0.75, 0.5))
	title_lbl.modulate.a = 0.0
	title_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(title_lbl)

	var subtitle_lbl = Label.new()
	subtitle_lbl.text = "— Guardian of the First Gate —"
	subtitle_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle_lbl.add_theme_font_size_override("font_size", 14)
	subtitle_lbl.add_theme_color_override("font_color", Color(0.6, 0.55, 0.45))
	subtitle_lbl.modulate.a = 0.0
	subtitle_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(subtitle_lbl)

	# Letterbox bars
	var top_bar = ColorRect.new()
	top_bar.color = Color.BLACK
	top_bar.size = Vector2(1280, 0)
	top_bar.position = Vector2.ZERO
	top_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(top_bar)

	var bottom_bar = ColorRect.new()
	bottom_bar.color = Color.BLACK
	bottom_bar.size = Vector2(1280, 0)
	bottom_bar.position = Vector2(0, 720)
	bottom_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(bottom_bar)

	# Tween sequence
	var tw = create_tween()
	tw.tween_property(top_bar, "size:y", 60.0, 0.5).set_trans(Tween.TRANS_SINE)
	tw.parallel().tween_property(bottom_bar, "size:y", 60.0, 0.5).set_trans(Tween.TRANS_SINE)
	tw.parallel().tween_property(bottom_bar, "position:y", 660.0, 0.5).set_trans(Tween.TRANS_SINE)
	tw.parallel().tween_property(card_bg, "color:a", 0.3, 0.5)
	tw.tween_callback(func():
		_screen_shake(8.0, 0.5)
		_sfx("boss_roar")
	)
	tw.tween_property(title_lbl, "modulate:a", 1.0, 0.6).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
	tw.tween_property(subtitle_lbl, "modulate:a", 1.0, 0.4)
	tw.tween_interval(2.0)
	tw.tween_property(title_lbl, "modulate:a", 0.0, 0.3)
	tw.parallel().tween_property(subtitle_lbl, "modulate:a", 0.0, 0.3)
	tw.parallel().tween_property(card_bg, "color:a", 0.0, 0.4)
	tw.tween_property(top_bar, "size:y", 0.0, 0.4).set_trans(Tween.TRANS_SINE)
	tw.parallel().tween_property(bottom_bar, "size:y", 0.0, 0.4).set_trans(Tween.TRANS_SINE)
	tw.parallel().tween_property(bottom_bar, "position:y", 720.0, 0.4).set_trans(Tween.TRANS_SINE)
	tw.tween_callback(func():
		canvas.queue_free()
		is_hostile = true
		current_state = State.CHASE
		if is_instance_valid(player) and player.has_method("set_input_locked"):
			player.set_input_locked(false)
	)


# ═════════════════════════════════════════════════════════════════════════
# AI BEHAVIOR — overrides base
# ═════════════════════════════════════════════════════════════════════════

func _ai_behavior(delta: float) -> void:
	if current_state == State.DEAD:
		return

	# Phase-pause overlay (stagger on transition)
	if _phase_paused:
		velocity.x = 0.0
		_phase_pause_timer += delta
		if _phase_pause_timer >= _phase_pause_duration:
			_phase_paused = false
			if has_node("Sprite"):
				var spr = get_node("Sprite")
				if _is_enraged:
					spr.modulate = Color(1.5, 0.3, 0.3)
				else:
					spr.modulate = Color.WHITE
			current_state = State.CHASE
		return

	# Phase 4 lock — frozen
	if phase_4_locked:
		velocity = Vector2.ZERO
		return

	_boss_attack_timer += delta

	match current_state:
		State.IDLE:
			velocity.x = 0.0
			if is_hostile and distance_to_player() < detection_range:
				current_state = State.CHASE
		State.CHASE:
			_boss_chase(delta)
		State.ATTACK:
			_boss_attack(delta)
		State.STUNNED:
			velocity.x = move_toward(velocity.x, 0.0, 300.0 * delta)


func _boss_chase(_delta: float) -> void:
	var dist = distance_to_player()
	if dist < attack_range:
		current_state = State.ATTACK
		return

	var spd = movement_speed
	if _is_enraged:
		spd *= 1.6

	var dir = direction_to_player()
	velocity.x = dir.x * spd


func _boss_attack(_delta: float) -> void:
	var dist = distance_to_player()
	if dist > attack_range * 3.0:
		current_state = State.CHASE
		return

	if _attack_active:
		return

	var cd = _boss_attack_cooldown
	if _is_enraged:
		cd *= 0.55

	if _boss_attack_timer >= cd:
		_execute_boss_attack()
		_boss_attack_timer = 0.0


# ═════════════════════════════════════════════════════════════════════════
# ATTACK SELECTION & EXECUTION
# ═════════════════════════════════════════════════════════════════════════

func _execute_boss_attack() -> void:
	_attack_active = true
	var attack = _pick_attack()

	match attack:
		"slash":
			await _attack_slash()
		"overhead_slam":
			await _attack_overhead_slam()
		"charge":
			await _attack_charge()
		"shield_bash":
			await _attack_shield_bash()
		"teleport_slash":
			await _attack_teleport_slash()
		"shockwave":
			await _attack_shockwave()

	if not is_inside_tree() or current_state == State.DEAD:
		_attack_active = false
		return

	_boss_combo_count += 1
	if _boss_combo_count >= _boss_max_combo:
		_boss_combo_count = 0
		_attack_active = false
	else:
		# Chain next attack quickly
		_boss_attack_timer = _boss_attack_cooldown * 0.7
		_attack_active = false


func _pick_attack() -> String:
	var available: Array[String] = []
	match current_boss_phase:
		BossPhase.PHASE_1:
			available = ["slash", "overhead_slam"]
		BossPhase.PHASE_2:
			available = ["slash", "overhead_slam", "charge", "shield_bash"]
		BossPhase.PHASE_3, BossPhase.PHASE_3_RAGE:
			available = ["slash", "overhead_slam", "charge", "teleport_slash", "shockwave"]
		BossPhase.PHASE_4:
			return "slash"
	if available.is_empty():
		return "slash"
	# Filter out the most recent attack to prevent repeats
	if _recent_attacks.size() > 0:
		available = available.filter(func(a): return a != _recent_attacks.back())
	if available.is_empty():
		available = ["slash"]
	var chosen = available[randi() % available.size()]
	_recent_attacks.append(chosen)
	if _recent_attacks.size() > 2:
		_recent_attacks.pop_front()
	return chosen


# ── Individual attacks ──────────────────────────────────────────────────

func _attack_slash() -> void:
	# Telegraph flash
	if has_node("Sprite"):
		get_node("Sprite").modulate = Color(1.0, 0.6, 0.3)
	await get_tree().create_timer(0.3).timeout
	if not _safe(): return
	if has_node("Sprite"):
		get_node("Sprite").modulate = Color.WHITE if not _is_enraged else Color(1.5, 0.3, 0.3)
	var dir = direction_to_player()
	velocity.x = dir.x * 200.0
	_sfx("sword_swing", 0.1)
	await get_tree().create_timer(0.25).timeout
	if not _safe():
		return
	_deal_boss_damage(attack_range, contact_damage)
	velocity.x = 0.0
	await get_tree().create_timer(0.3).timeout


func _attack_overhead_slam() -> void:
	velocity.x = 0.0
	_sfx("heavy_windup")
	await get_tree().create_timer(0.5).timeout
	if not _safe():
		return
	var dir = direction_to_player()
	velocity.x = dir.x * 250.0
	_sfx("sword_slam")
	_screen_shake(10.0, 0.2)
	await get_tree().create_timer(0.2).timeout
	if not _safe():
		return
	_deal_boss_damage(attack_range * 1.2, contact_damage * 1.5)
	_spawn_slam_wave()
	velocity.x = 0.0
	await get_tree().create_timer(0.6).timeout


func _attack_charge() -> void:
	velocity.x = 0.0
	_status_text("!", global_position + Vector2(0, -50), false)
	await get_tree().create_timer(0.4).timeout
	if not _safe():
		return
	_charge_rushing = true
	var dir = direction_to_player()
	velocity.x = dir.x * 350.0
	velocity.y = -100.0
	_sfx("dash", 0.15)
	await get_tree().create_timer(0.45).timeout
	if not _safe():
		_charge_rushing = false
		return
	_deal_boss_damage(attack_range * 1.5, contact_damage * 1.3)
	_screen_shake(8.0, 0.15)
	velocity.x = 0.0
	_charge_rushing = false
	await get_tree().create_timer(0.4).timeout


func _attack_shield_bash() -> void:
	var dir = direction_to_player()
	velocity.x = dir.x * 180.0
	_sfx("shield_hit")
	await get_tree().create_timer(0.2).timeout
	if not _safe():
		return
	_deal_boss_damage(attack_range * 0.8, contact_damage * 0.8)
	# Knockback emphasis
	var player = find_player()
	if player and is_instance_valid(player):
		var kb_dir = (player.global_position - global_position).normalized()
		if player.has_method("apply_knockback"):
			player.apply_knockback(kb_dir * 200.0)
	velocity.x = 0.0
	await get_tree().create_timer(0.5).timeout


func _attack_teleport_slash() -> void:
	_vfx("vfx_glitch_sparkle", global_position)
	_sfx("glitch_teleport", 0.2)
	var player = find_player()
	if not player:
		return
	# Teleport behind player
	var behind = -sign(player.global_position.x - global_position.x) * 70.0
	global_position = Vector2(player.global_position.x + behind, player.global_position.y)
	_vfx("vfx_glitch_sparkle", global_position)
	await get_tree().create_timer(0.30).timeout
	if not _safe():
		return
	_deal_boss_damage(attack_range, contact_damage * 1.2)
	_sfx("sword_swing")
	await get_tree().create_timer(0.3).timeout


func _attack_shockwave() -> void:
	velocity.y = -500.0
	_sfx("heavy_windup")
	await get_tree().create_timer(0.5).timeout
	if not _safe():
		return
	velocity.y = 800.0
	await get_tree().create_timer(0.3).timeout
	if not _safe():
		return
	_deal_boss_damage(150.0, contact_damage * 1.8)
	_screen_shake(18.0, 0.4)
	_vfx("vfx_hit_spark", global_position + Vector2(0, 10))
	await get_tree().create_timer(0.5).timeout


# ── Slam wave helper ────────────────────────────────────────────────────

func _spawn_slam_wave() -> void:
	if _slam_wave_active:
		return
	_slam_wave_active = true

	var origin = global_position + Vector2(0, 10)
	var wave_speed = 300.0
	var wave_duration = 0.6
	var wave_damage = contact_damage * 0.6
	if _is_enraged:
		wave_damage *= 1.25

	# Expand radius over time — only hit player once
	var elapsed = 0.0
	var wave_has_hit: bool = false
	while elapsed < wave_duration:
		await get_tree().create_timer(0.05).timeout
		if not is_inside_tree():
			_slam_wave_active = false
			return
		elapsed += 0.05
		var current_radius = wave_speed * elapsed
		var player = find_player()
		if player and player.has_method("take_damage") and not wave_has_hit:
			var dist = absf(player.global_position.x - origin.x)
			var height = player.global_position.y - origin.y
			if dist < current_radius and height > -70.0:
				player.take_damage(wave_damage, origin, enemy_name, "boss")
				wave_has_hit = true

	_slam_wave_active = false


# ═════════════════════════════════════════════════════════════════════════
# DAMAGE HELPER
# ═════════════════════════════════════════════════════════════════════════

func _deal_boss_damage(range_px: float, damage: float) -> void:
	if _is_enraged:
		damage *= 1.25
	var player = find_player()
	if not player or not player.has_method("take_damage"):
		return
	if global_position.distance_to(player.global_position) <= range_px:
		player.take_damage(damage, global_position, enemy_name, "boss")



# ═════════════════════════════════════════════════════════════════════════
# PHASE MANAGEMENT
# ═════════════════════════════════════════════════════════════════════════

func _check_phase_transitions() -> void:
	if max_health <= 0:
		return
	var hp_pct = current_health / max_health

	if current_boss_phase == BossPhase.PHASE_1 and hp_pct <= PHASE_2_HP_PCT:
		current_boss_phase = BossPhase.PHASE_2
		_trigger_phase_pause(2)
	elif current_boss_phase == BossPhase.PHASE_2 and hp_pct <= PHASE_3_HP_PCT:
		current_boss_phase = BossPhase.PHASE_3
		_trigger_phase_pause(3)
	elif current_boss_phase == BossPhase.PHASE_3 and hp_pct <= PHASE_RAGE_HP_PCT:
		current_boss_phase = BossPhase.PHASE_3_RAGE
		_enter_rage_phase()
	elif current_boss_phase == BossPhase.PHASE_3_RAGE and hp_pct <= PHASE_4_HP_PCT:
		current_boss_phase = BossPhase.PHASE_4
		_enter_phase_4()


func _trigger_phase_pause(phase_number: int) -> void:
	## Brief stagger + VFX on phase change with full game juice.
	_phase_paused = true
	_phase_pause_timer = 0.0
	_pending_phase = phase_number
	_attack_active = false
	_charge_rushing = false
	velocity = Vector2.ZERO

	# Full juice pipeline: hitstop + shake + flash + slowmo + zoom
	if has_node("/root/GameJuice"):
		GameJuice.boss_phase_transition()
	else:
		_screen_shake(22.0, 0.5)
		_hitstop(0.1)

	if has_node("Sprite"):
		get_node("Sprite").modulate = Color(2, 2, 2)

	_vfx("vfx_glitch_sparkle", global_position)
	_vfx("vfx_glitch_sparkle", global_position + Vector2(30, -30))
	_status_text("PHASE %d!" % phase_number, global_position + Vector2(0, -70), false)
	phase_changed.emit(phase_number)


func _enter_rage_phase() -> void:
	## Desperation — corruption overwhelms, relentless combos.
	_is_enraged = true
	_boss_max_combo = 3
	_phase_paused = true
	_phase_pause_timer = 0.0
	_pending_phase = 35
	_attack_active = false
	_charge_rushing = false
	velocity = Vector2.ZERO

	_screen_shake(35.0, 0.8)
	_hitstop(0.15)

	if has_node("Sprite"):
		get_node("Sprite").modulate = Color(1.5, 0.3, 0.3)

	_vfx("vfx_glitch_sparkle", global_position)
	_vfx("vfx_glitch_sparkle", global_position + Vector2(30, -30))
	_vfx("vfx_glitch_sparkle", global_position + Vector2(-30, -30))
	_vfx("vfx_enemy_death", global_position + Vector2(0, -20))

	contact_damage *= 1.35
	movement_speed *= 1.7
	phase_changed.emit(35)


func _enter_phase_4() -> void:
	## Knight locks in infinite loop — Root Access or finish by force.
	phase_4_locked = true
	_attack_active = false
	_charge_rushing = false
	current_state = State.IDLE
	velocity = Vector2.ZERO

	# Full phase transition juice for the climactic moment
	if has_node("/root/GameJuice"):
		GameJuice.boss_phase_transition()
	else:
		_screen_shake(30.0, 0.8)
		_hitstop(0.15)

	if has_node("Sprite"):
		get_node("Sprite").modulate = Color(0.65, 0.45, 0.45)
		# Pulsing glitch effect to signal the knight is stuck in a loop
		if _phase_pulse_tween and _phase_pulse_tween.is_valid():
			_phase_pulse_tween.kill()
		_phase_pulse_tween = create_tween().set_loops()
		_phase_pulse_tween.tween_property(get_node("Sprite"), "modulate:a", 0.5, 0.4).set_trans(Tween.TRANS_SINE)
		_phase_pulse_tween.tween_property(get_node("Sprite"), "modulate:a", 1.0, 0.4).set_trans(Tween.TRANS_SINE)

	_vfx("vfx_glitch_sparkle", global_position)
	_vfx("vfx_glitch_sparkle", global_position + Vector2(0, -50))
	_vfx("vfx_enemy_death", global_position + Vector2(0, -30))

	# Spawn persistent "ROOT ACCESS" prompt above boss
	_status_text("[E] ROOT ACCESS", global_position + Vector2(0, -80), true)

	root_access_triggered.emit()


func hack_disable_attacking() -> void:
	## Player uses Root Access: set is_attacking = false → peaceful ending.
	is_hostile = false
	phase_4_locked = true
	boss_defeated.emit()


# ═════════════════════════════════════════════════════════════════════════
# DAMAGE & DEATH OVERRIDES
# ═════════════════════════════════════════════════════════════════════════

func take_damage(amount: float, knockback_source: Vector2 = Vector2.ZERO) -> void:
	if current_state == State.DEAD:
		return

	# Lighter knockback for boss
	if knockback_source != Vector2.ZERO:
		var kb_dir = (global_position - knockback_source).normalized()
		velocity.x = kb_dir.x * clampf(amount * 3.0, 30.0, 120.0)

	# Phase 4: can still be killed by force
	if phase_4_locked:
		current_health -= amount
		health_changed.emit(current_health, max_health)
		_update_health_bar()
		_play_hit_flash()
		_tween_hurt()
		_vfx("vfx_hit_spark", global_position + Vector2(0, -15))
		if current_health <= 0:
			_kill_effects(global_position, amount)
			die()
		return

	current_health -= amount
	health_changed.emit(current_health, max_health)
	_update_health_bar()
	_play_hit_flash()
	_tween_hurt()
	_vfx("vfx_hit_spark", global_position + Vector2(0, -15))

	if current_health <= 0:
		die()
		return

	_check_phase_transitions()

	# Phase-specific flinch behavior
	if current_boss_phase == BossPhase.PHASE_1 and current_state != State.STUNNED and not _stagger_active:
		_stagger_active = true
		var _prev = current_state
		current_state = State.STUNNED
		velocity.x = move_toward(velocity.x, 0.0, 300.0)
		_attack_active = false
		_charge_rushing = false
		await get_tree().create_timer(0.2).timeout
		if not is_inside_tree() or not is_instance_valid(self):
			return
		_stagger_active = false
		if current_state == State.STUNNED:
			current_state = State.CHASE
	elif current_boss_phase == BossPhase.PHASE_2:
		# Minor visual flinch only
		if has_node("Sprite"):
			var spr = get_node("Sprite")
			var orig = spr.modulate
			spr.modulate = Color(1.0, 0.4, 0.4)
			await get_tree().create_timer(0.08).timeout
			if is_inside_tree() and is_instance_valid(self) and is_instance_valid(spr):
				spr.modulate = orig
	# Phase 3+: no flinch


func die() -> void:
	if current_state == State.DEAD:
		return
	current_state = State.DEAD
	# Disable collision immediately so dead boss can't absorb attacks
	collision_layer = 0
	collision_mask = 0
	if _phase_pulse_tween and _phase_pulse_tween.is_valid():
		_phase_pulse_tween.kill()
	if has_node("/root/GameManager"):
		GameManager.end_boss_fight()
	phase_4_locked = true
	_attack_active = false
	_charge_rushing = false
	velocity = Vector2.ZERO
	set_physics_process(false)

	_sfx("enemy_death")
	died.emit()
	boss_defeated.emit()

	# Full boss death sequence: slowmo + shake + flash + shatter
	if has_node("/root/GameJuice"):
		GameJuice.boss_death_sequence()
	else:
		_screen_shake(20.0, 0.8)
	if has_node("/root/GameManager"):
		GameManager.record_dda_kill()
	if has_node("/root/CombatFX"):
		CombatFX.apply_last_kill_slowdown()
		CombatFX.apply_kill_zoom()

	_award_death_rewards()
	_tween_die()
	_vfx("vfx_enemy_death", global_position)

	await get_tree().create_timer(1.0).timeout
	if is_inside_tree() and is_instance_valid(self):
		queue_free()


# ═════════════════════════════════════════════════════════════════════════
# HACKABLE PROPERTIES — Root Access interface
# ═════════════════════════════════════════════════════════════════════════

func get_hackable_properties() -> Dictionary:
	var props = super.get_hackable_properties()
	props["is_attacking"] = {
		"value": is_hostile and not phase_4_locked,
		"type": "bool",
		"description": "Whether the knight can attack. Set to FALSE to end the loop."
	}
	return props


func apply_hack(property_name: String, new_value: Variant) -> void:
	if property_name == "is_attacking":
		if not bool(new_value):
			hack_disable_attacking()
		return
	super.apply_hack(property_name, new_value)
