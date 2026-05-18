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
const BASE_MAX_HEALTH = 420.0
const BASE_CONTACT_DAMAGE = 22.0
const BASE_MOVEMENT_SPEED = 135.0
const BASE_ATTACK_RANGE = 92.0
const ROOT_ACCESS_HP_PCT = 0.04
const CLOSE_PRESSURE_WINDOW = 1.4
const CLOSE_PRESSURE_HITS = 3
const CLOSE_PRESSURE_COOLDOWN = 1.25
const CLOSE_PRESSURE_GUARD_TIME = 0.48
const TRANSITION_GUARD_MULT = 0.2
const DEFENSIVE_ANSWER_STAGGER = 0.55
const STATUS_CALLOUT_REPEAT_GAP_MS = 520

# ── Phase state ─────────────────────────────────────────────────────────
var current_boss_phase: BossPhase = BossPhase.PHASE_1
var _phase_paused: bool = false
var _phase_pause_timer: float = 0.0
var _phase_pause_duration: float = 0.5
var _pending_phase: int = 0
var _phase_elapsed: float = 0.0
var _phase_attack_count: int = 0

# ── Attack bookkeeping ──────────────────────────────────────────────────
var _boss_attack_timer: float = 0.0
var _boss_attack_cooldown: float = 1.15
var _boss_combo_count: int = 0
var _boss_max_combo: int = 2
var _attack_active: bool = false
var _stagger_active: bool = false
var _slam_wave_active: bool = false
var _charge_rushing: bool = false
var _recent_attacks: Array[String] = []
var _phase_pattern_step: int = 0
var _root_access_ready: bool = false
var _forced_attack: String = ""
var _close_pressure_hits: int = 0
var _close_pressure_timer: float = 0.0
var _close_pressure_cooldown: float = 0.0
var _guard_timer: float = 0.0
var _heal_punish_cooldown: float = 0.0
var _flinch_cooldown: float = 0.0
var _status_callout_times: Dictionary = {}

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
	max_health = BASE_MAX_HEALTH
	contact_damage = BASE_CONTACT_DAMAGE
	movement_speed = BASE_MOVEMENT_SPEED
	detection_range = 450.0
	attack_range = BASE_ATTACK_RANGE
	xp_reward = 400
	gold_reward = 200
	zone_level = 2  # First real boss: challenging without becoming a stat sponge.
	elasticity = 1.0
	gravity_scale = 1.0
	super._ready()
	current_health = max_health
	_apply_phase_combat_tuning()

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
	_phase_elapsed += delta
	_close_pressure_timer = maxf(0.0, _close_pressure_timer - delta)
	_close_pressure_cooldown = maxf(0.0, _close_pressure_cooldown - delta)
	_guard_timer = maxf(0.0, _guard_timer - delta)
	_heal_punish_cooldown = maxf(0.0, _heal_punish_cooldown - delta)
	_flinch_cooldown = maxf(0.0, _flinch_cooldown - delta)
	if _close_pressure_timer <= 0.0:
		_close_pressure_hits = 0
	_maybe_pressure_healing_player()
	if _current_phase_floor_pct() > 0.0 and current_health / max_health <= _current_phase_floor_pct() and _phase_requirements_met():
		_check_phase_transitions()

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
		_boss_attack_timer = maxf(_boss_attack_timer, _boss_attack_cooldown * 0.8)
		return

	var spd = movement_speed
	if _is_enraged:
		spd *= 1.45

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
	_phase_attack_count += 1

	match attack:
		"slash":
			await _attack_slash()
		"low_sweep":
			await _attack_low_sweep()
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
		"corrupt_rift":
			await _attack_corrupt_rift()

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
	if _forced_attack != "":
		var forced := _forced_attack
		_forced_attack = ""
		_recent_attacks.append(forced)
		if _recent_attacks.size() > 2:
			_recent_attacks.pop_front()
		return forced
	var available: Array[String] = []
	var dist := distance_to_player()
	match current_boss_phase:
		BossPhase.PHASE_1:
			available = ["slash", "charge", "slash"]
		BossPhase.PHASE_2:
			available = ["low_sweep", "shield_bash", "slash", "charge"]
			if dist > attack_range * 1.55:
				available = ["charge", "slash"]
		BossPhase.PHASE_3, BossPhase.PHASE_3_RAGE:
			available = ["corrupt_rift", "teleport_slash", "low_sweep", "shockwave", "charge"]
			if dist > attack_range * 1.7:
				available = ["teleport_slash", "charge", "corrupt_rift"]
		BossPhase.PHASE_4:
			available = ["charge", "low_sweep", "shield_bash", "corrupt_rift", "slash"]
	if available.is_empty():
		return "slash"
	var chosen = available[_phase_pattern_step % available.size()]
	_phase_pattern_step += 1
	if dist > attack_range * 2.0 and chosen not in ["charge", "teleport_slash", "corrupt_rift"]:
		chosen = "charge"
	# Filter out the most recent attack to prevent repeats
	if _recent_attacks.size() > 0 and chosen == _recent_attacks.back():
		available = available.filter(func(a): return a != _recent_attacks.back())
		if available.is_empty():
			available = ["slash"]
		chosen = available[_phase_pattern_step % available.size()]
		_phase_pattern_step += 1
	_recent_attacks.append(chosen)
	if _recent_attacks.size() > 2:
		_recent_attacks.pop_front()
	return chosen


# ── Individual attacks ──────────────────────────────────────────────────

func _front_warning(size: Vector2, y_offset: float, color: Color, duration: float) -> void:
	var facing := _facing_to_player()
	_front_warning_facing(facing, size, y_offset, color, duration)

func _front_warning_facing(facing: float, size: Vector2, y_offset: float, color: Color, duration: float) -> void:
	_spawn_attack_warning(Vector2(facing * size.x * 0.5, y_offset), size, color, duration)

func _facing_to_player() -> float:
	var dir = direction_to_player()
	var facing := signf(dir.x)
	if facing == 0.0:
		facing = 1.0
	return facing

func _spawn_attack_warning(center_offset: Vector2, size: Vector2, color: Color, duration: float) -> void:
	var parent = get_parent()
	if not parent:
		return
	var warning = ColorRect.new()
	warning.name = "BossAttackWarning"
	warning.color = color
	warning.size = size
	warning.position = global_position + center_offset - size / 2.0
	warning.z_index = 30
	warning.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(warning)
	var tw = warning.create_tween()
	tw.tween_property(warning, "color:a", 0.08, maxf(duration, 0.05)).set_trans(Tween.TRANS_SINE)
	tw.tween_callback(warning.queue_free)

func _reset_phase_pattern() -> void:
	_phase_pattern_step = 0
	_recent_attacks.clear()

func _force_next_attack(attack_name: String) -> void:
	_forced_attack = attack_name
	_boss_attack_timer = _boss_attack_cooldown
	if current_state != State.DEAD and not phase_4_locked:
		current_state = State.ATTACK


func _status_text(text: String, pos: Vector2, is_positive: bool = false) -> void:
	var now_ms := Time.get_ticks_msec()
	var last_ms := int(_status_callout_times.get(text, -100000))
	var gap := STATUS_CALLOUT_REPEAT_GAP_MS
	if text in ["ROOT ACCESS", "[E] ROOT ACCESS", "VICTORY", "OPEN!"]:
		gap = 120
	if now_ms - last_ms < gap:
		return
	_status_callout_times[text] = now_ms
	if has_node("/root/VFXLibrary"):
		VFXLibrary.spawn_status_indicator(text, pos, get_parent(), is_positive)

func _attack_slash() -> void:
	# Telegraph flash
	var slash_facing := _facing_to_player()
	var slash_size := Vector2(attack_range * 1.05, 112.0)
	var slash_y_offset := -10.0
	if has_node("Sprite"):
		get_node("Sprite").modulate = Color(1.0, 0.6, 0.3)
	_status_text("SLASH", global_position + Vector2(0, -62), false)
	_front_warning_facing(slash_facing, slash_size, slash_y_offset, Color(1.0, 0.55, 0.15, 0.34), 0.22)
	await get_tree().create_timer(0.22).timeout
	if not _safe(): return
	if has_node("Sprite"):
		get_node("Sprite").modulate = Color.WHITE if not _is_enraged else Color(1.5, 0.3, 0.3)
	velocity.x = slash_facing * 230.0
	_sfx("sword_swing", 0.1)
	await get_tree().create_timer(0.10).timeout
	if not _safe():
		return
	if _deal_boss_slash_damage(slash_facing, slash_size, slash_y_offset, contact_damage):
		_on_attack_connected(6.0, 0.10)
	velocity.x = 0.0
	await get_tree().create_timer(0.24).timeout


func _attack_low_sweep() -> void:
	velocity.x = 0.0
	_status_text("JUMP / POGO", global_position + Vector2(0, -62), false)
	if has_node("Sprite"):
		get_node("Sprite").modulate = Color(0.35, 0.9, 1.0)
	_front_warning(Vector2(attack_range * 1.55, 42.0), -6.0, Color(0.25, 0.95, 1.0, 0.38), 0.30)
	_sfx("heavy_windup", 0.12)
	await get_tree().create_timer(0.30).timeout
	if not _safe():
		return
	var dir = direction_to_player()
	velocity.x = dir.x * 170.0
	_sfx("sword_swing", 0.08)
	await get_tree().create_timer(0.08).timeout
	if not _safe():
		return
	if _deal_boss_low_sweep_damage(attack_range * 1.45, contact_damage * 0.9):
		_on_attack_connected(8.0, 0.14)
	velocity.x = 0.0
	if has_node("Sprite"):
		get_node("Sprite").modulate = Color.WHITE if not _is_enraged else Color(1.5, 0.3, 0.3)
	await get_tree().create_timer(0.40).timeout


func _attack_overhead_slam() -> void:
	velocity.x = 0.0
	_status_text("JUMP", global_position + Vector2(0, -62), false)
	if has_node("Sprite"):
		get_node("Sprite").modulate = Color(1.0, 0.25, 0.2)
	_front_warning(Vector2(attack_range * 1.2, 110.0), -30.0, Color(1.0, 0.1, 0.08, 0.35), 0.42)
	_sfx("heavy_windup")
	await get_tree().create_timer(0.42).timeout
	if not _safe():
		return
	var dir = direction_to_player()
	velocity.x = dir.x * 250.0
	_sfx("sword_slam")
	_screen_shake(10.0, 0.2)
	await get_tree().create_timer(0.14).timeout
	if not _safe():
		return
	if _deal_boss_melee_damage(attack_range * 1.15, contact_damage * 1.5, "boss_slam", 88.0, -28.0, 0.12):
		_on_attack_connected(12.0, 0.18)
	_spawn_slam_wave()
	velocity.x = 0.0
	if has_node("Sprite"):
		get_node("Sprite").modulate = Color.WHITE if not _is_enraged else Color(1.5, 0.3, 0.3)
	await get_tree().create_timer(0.52).timeout


func _attack_charge() -> void:
	velocity.x = 0.0
	_status_text("DASH", global_position + Vector2(0, -62), false)
	if has_node("Sprite"):
		get_node("Sprite").modulate = Color(1.0, 0.45, 0.15)
	_front_warning(Vector2(attack_range * 2.1, 58.0), -28.0, Color(1.0, 0.45, 0.0, 0.36), 0.34)
	await get_tree().create_timer(0.34).timeout
	if not _safe():
		return
	_charge_rushing = true
	var dir = direction_to_player()
	velocity.x = dir.x * 430.0
	velocity.y = -100.0
	_sfx("dash", 0.15)
	await get_tree().create_timer(0.16).timeout
	if not _safe():
		_charge_rushing = false
		return
	if _deal_boss_melee_damage(attack_range * 1.35, contact_damage * 1.3, "boss_charge", 58.0, -28.0, 0.10):
		_on_attack_connected(12.0, 0.16)
	_screen_shake(8.0, 0.15)
	await get_tree().create_timer(0.20).timeout
	velocity.x = 0.0
	_charge_rushing = false
	if has_node("Sprite"):
		get_node("Sprite").modulate = Color.WHITE if not _is_enraged else Color(1.5, 0.3, 0.3)
	await get_tree().create_timer(0.34).timeout


func _attack_shield_bash() -> void:
	_status_text("BLOCK", global_position + Vector2(0, -62), false)
	var dir = direction_to_player()
	var player = find_player()
	var defensive_answer := _player_is_defending_or_parrying(player)
	velocity.x = 0.0
	_front_warning(Vector2(attack_range * 0.9, 88.0), -30.0, Color(0.85, 0.85, 1.0, 0.32), 0.18)
	_sfx("shield_hit")
	await get_tree().create_timer(0.18).timeout
	if not _safe():
		return
	velocity.x = dir.x * 240.0
	await get_tree().create_timer(0.08).timeout
	if not _safe():
		return
	if _deal_boss_melee_damage(attack_range * 0.75, contact_damage * 0.8, "boss_bash", 72.0, -28.0, 0.10):
		defensive_answer = defensive_answer or _player_is_defending_or_parrying(player)
		if defensive_answer:
			_reward_defensive_answer()
		else:
			_on_attack_connected(9.0, 0.12)
	# Knockback emphasis
	if player and is_instance_valid(player):
		var kb_dir = (player.global_position - global_position).normalized()
		if player.has_method("apply_knockback") and not defensive_answer:
			player.apply_knockback(kb_dir * 200.0)
	velocity.x = 0.0
	await get_tree().create_timer(0.50 if defensive_answer else 0.42).timeout


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
	_status_text("TURN", global_position + Vector2(0, -62), false)
	if has_node("Sprite"):
		get_node("Sprite").modulate = Color(0.85, 0.45, 1.0)
	_front_warning(Vector2(attack_range, 96.0), -32.0, Color(0.8, 0.25, 1.0, 0.36), 0.34)
	await get_tree().create_timer(0.34).timeout
	if not _safe():
		return
	if _deal_boss_melee_damage(attack_range * 0.95, contact_damage * 1.2, "boss_teleport_slash", 82.0, -30.0, 0.11):
		_on_attack_connected(10.0, 0.14)
	_sfx("sword_swing")
	if has_node("Sprite"):
		get_node("Sprite").modulate = Color.WHITE if not _is_enraged else Color(1.5, 0.3, 0.3)
	await get_tree().create_timer(0.32).timeout


func _attack_shockwave() -> void:
	velocity.y = -500.0
	_status_text("AIR", global_position + Vector2(0, -62), false)
	_spawn_attack_warning(Vector2(0, -6.0), Vector2(310, 46), Color(0.95, 0.15, 0.95, 0.32), 0.46)
	_sfx("heavy_windup")
	await get_tree().create_timer(0.46).timeout
	if not _safe():
		return
	velocity.y = 800.0
	await get_tree().create_timer(0.3).timeout
	if not _safe():
		return
	if _deal_grounded_wave_damage(155.0, contact_damage * 1.45, "boss_shockwave"):
		_on_attack_connected(10.0, 0.16)
	_screen_shake(18.0, 0.4)
	_vfx("vfx_hit_spark", global_position + Vector2(0, 10))
	await get_tree().create_timer(0.48).timeout


# ── Slam wave helper ────────────────────────────────────────────────────

func _attack_corrupt_rift() -> void:
	velocity.x = 0.0
	_status_text("RIFT", global_position + Vector2(0, -62), false)
	var player = find_player()
	var dir = direction_to_player()
	var facing := signf(dir.x)
	if facing == 0.0:
		facing = 1.0
	if has_node("Sprite"):
		get_node("Sprite").modulate = Color(1.0, 0.15, 0.85)
	_vfx("vfx_glitch_sparkle", global_position)
	_sfx("glitch_teleport", 0.12)
	var target_offset = Vector2(facing * attack_range * 0.85, -30.0)
	if player and is_instance_valid(player):
		target_offset = (player.global_position - global_position).clamp(Vector2(-150, -80), Vector2(150, 20))
	_spawn_attack_warning(target_offset, Vector2(76, 130), Color(0.95, 0.05, 1.0, 0.42), 0.38)
	_spawn_attack_warning(Vector2(-target_offset.x * 0.55, -30.0), Vector2(58, 104), Color(0.45, 0.15, 1.0, 0.25), 0.38)
	await get_tree().create_timer(0.38).timeout
	if not _safe():
		return
	var hit_primary := _deal_boss_rift_damage(target_offset, Vector2(76, 130), contact_damage * 1.15)
	var hit_secondary := _deal_boss_rift_damage(Vector2(-target_offset.x * 0.55, -30.0), Vector2(58, 104), contact_damage * 0.75)
	if hit_primary or hit_secondary:
		_on_attack_connected(14.0, 0.18)
	_vfx("vfx_glitch_sparkle", global_position + target_offset)
	if has_node("Sprite"):
		get_node("Sprite").modulate = Color.WHITE if not _is_enraged else Color(1.5, 0.3, 0.3)
	await get_tree().create_timer(0.44).timeout

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
func _deal_boss_melee_damage(range_px: float, damage: float, damage_type: String, hitbox_height: float = 86.0, y_offset: float = -30.0, active_duration: float = 0.12) -> bool:
	if _is_enraged:
		damage *= 1.25
	var dir = direction_to_player()
	var facing := signf(dir.x)
	if facing == 0.0:
		facing = 1.0
	var hitbox_size := Vector2(range_px, hitbox_height)
	return _deal_damage_in_attack_hitbox(Vector2(facing * hitbox_size.x * 0.5, y_offset), hitbox_size, damage, damage_type, active_duration)

func _deal_boss_slash_damage(facing: float, hitbox_size: Vector2, y_offset: float, damage: float) -> bool:
	if _is_enraged:
		damage *= 1.25
	var player = find_player()
	if not player or not is_instance_valid(player) or not player.has_method("take_damage"):
		return false
	if bool(player.get("invulnerable")) or bool(player.get("is_dead")):
		return false
	var center_offset := Vector2(facing * hitbox_size.x * 0.5, y_offset)
	var hit_rect := Rect2(global_position + center_offset - hitbox_size * 0.5, hitbox_size)
	if not _player_collision_overlaps_rect(player, hit_rect):
		return false
	if not _has_line_of_sight_to_player(player):
		return false
	player.take_damage(damage * get_enemy_damage_multiplier(), global_position, enemy_name, "boss_slash")
	return true

func _player_collision_overlaps_rect(player: Node, rect: Rect2) -> bool:
	for child in player.get_children():
		if child is CollisionShape2D and not child.disabled:
			var shape: Shape2D = child.shape
			if not shape:
				continue
			var extents := _shape_extents_for_rect(shape)
			var collision_rect := Rect2(child.global_position - extents, extents * 2.0)
			if collision_rect.intersects(rect):
				return true
	return rect.has_point(player.global_position)

func _shape_extents_for_rect(shape: Shape2D) -> Vector2:
	if shape is RectangleShape2D:
		return shape.size * 0.5
	if shape is CircleShape2D:
		return Vector2.ONE * shape.radius
	if shape is CapsuleShape2D:
		return Vector2(shape.radius, maxf(shape.height * 0.5, shape.radius))
	return Vector2(16.0, 32.0)

func _deal_boss_low_sweep_damage(range_px: float, damage: float) -> bool:
	if _is_enraged:
		damage *= 1.25
	var player = find_player()
	if not player or not is_instance_valid(player) or not player.has_method("take_damage"):
		return false
	if player.has_method("is_on_floor") and not player.is_on_floor():
		return false
	var dir = direction_to_player()
	var facing := signf(dir.x)
	if facing == 0.0:
		facing = 1.0
	var hitbox_size := Vector2(range_px, 34.0)
	var center_offset := Vector2(facing * hitbox_size.x * 0.5, -2.0)
	var hit_rect := Rect2(global_position + center_offset - hitbox_size * 0.5, hitbox_size)
	if not hit_rect.has_point(player.global_position) or not _has_line_of_sight_to_player(player):
		return false
	player.take_damage(damage * get_enemy_damage_multiplier(), global_position, enemy_name, "boss_low_sweep")
	return true

func _deal_grounded_wave_damage(half_width: float, damage: float, damage_type: String) -> bool:
	var player = find_player()
	if not player or not is_instance_valid(player) or not player.has_method("take_damage"):
		return false
	if player.has_method("is_on_floor") and not player.is_on_floor():
		return false
	if absf(player.global_position.x - global_position.x) > half_width:
		return false
	if absf(player.global_position.y - global_position.y) > 96.0:
		return false
	if not _has_line_of_sight_to_player(player):
		return false
	player.take_damage(damage * get_enemy_damage_multiplier(), global_position, enemy_name, damage_type)
	return true

func _deal_boss_rift_damage(center_offset: Vector2, size: Vector2, damage: float) -> bool:
	if _is_enraged:
		damage *= 1.18
	return _deal_damage_in_attack_hitbox(center_offset, size, damage, "boss_corrupt_rift", 0.10)

func _on_attack_connected(shake_intensity: float, shake_duration: float) -> void:
	if has_node("/root/CombatFX"):
		CombatFX.apply_hitstop(0.045)
	_screen_shake(shake_intensity, shake_duration)


func _player_is_defending_or_parrying(player: Node) -> bool:
	if not player or not is_instance_valid(player):
		return false
	return bool(player.get("is_defending")) or bool(player.get("parry_active")) or bool(player.get("parry_counter_active"))


func _reward_defensive_answer() -> void:
	_status_text("OPEN!", global_position + Vector2(0, -78), true)
	if has_node("/root/CombatFX"):
		CombatFX.apply_hitstop(0.075)
	_screen_shake(7.0, 0.14)
	_vfx("vfx_parry_flash", global_position + Vector2(0, -18))
	stagger(DEFENSIVE_ANSWER_STAGGER)


func _apply_phase_combat_tuning() -> void:
	match current_boss_phase:
		BossPhase.PHASE_1:
			_boss_attack_cooldown = 0.78
			_boss_max_combo = 1
		BossPhase.PHASE_2:
			_boss_attack_cooldown = 0.68
			_boss_max_combo = 2
		BossPhase.PHASE_3:
			_boss_attack_cooldown = 0.62
			_boss_max_combo = 2
		BossPhase.PHASE_3_RAGE:
			_boss_attack_cooldown = 0.58
			_boss_max_combo = 2
		BossPhase.PHASE_4:
			_boss_attack_cooldown = 0.64
			_boss_max_combo = 2


# PHASE MANAGEMENT
# ═════════════════════════════════════════════════════════════════════════

func _current_phase_floor_pct() -> float:
	match current_boss_phase:
		BossPhase.PHASE_1:
			return PHASE_2_HP_PCT
		BossPhase.PHASE_2:
			return PHASE_3_HP_PCT
		BossPhase.PHASE_3:
			return PHASE_RAGE_HP_PCT
		BossPhase.PHASE_3_RAGE:
			return PHASE_4_HP_PCT
		BossPhase.PHASE_4:
			return ROOT_ACCESS_HP_PCT
	return 0.0


func _phase_min_duration() -> float:
	match current_boss_phase:
		BossPhase.PHASE_1:
			return 2.2
		BossPhase.PHASE_2:
			return 2.7
		BossPhase.PHASE_3:
			return 2.9
		BossPhase.PHASE_3_RAGE:
			return 1.9
		BossPhase.PHASE_4:
			return 1.8
	return 0.0


func _phase_min_attacks() -> int:
	match current_boss_phase:
		BossPhase.PHASE_1:
			return 2
		BossPhase.PHASE_2:
			return 3
		BossPhase.PHASE_3:
			return 3
		BossPhase.PHASE_3_RAGE:
			return 2
		BossPhase.PHASE_4:
			return 2
	return 0


func _phase_requirements_met() -> bool:
	return _phase_elapsed >= _phase_min_duration() and _phase_attack_count >= _phase_min_attacks()


func _reset_phase_progress() -> void:
	_phase_elapsed = 0.0
	_phase_attack_count = 0
	_boss_attack_timer = _boss_attack_cooldown


func _maybe_pressure_healing_player() -> void:
	if _heal_punish_cooldown > 0.0 or _attack_active or _phase_paused:
		return
	var player = find_player()
	if not player or not is_instance_valid(player):
		return
	if not bool(player.get("is_healing")):
		return
	_heal_punish_cooldown = 2.0
	_status_text("NO FREE HEAL", global_position + Vector2(0, -72), false)
	if current_boss_phase >= BossPhase.PHASE_3:
		_force_next_attack("corrupt_rift")
	else:
		_force_next_attack("charge")


func _check_phase_transitions() -> void:
	if max_health <= 0:
		return
	var hp_pct = current_health / max_health
	if not _phase_requirements_met() and hp_pct <= _current_phase_floor_pct():
		return

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
	_phase_pause_duration = 0.45
	_pending_phase = phase_number
	_attack_active = false
	_charge_rushing = false
	velocity = Vector2.ZERO
	_reset_phase_pattern()
	_apply_phase_combat_tuning()
	_reset_phase_progress()
	match phase_number:
		2:
			_forced_attack = "low_sweep"
		3:
			_forced_attack = "corrupt_rift"

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
	_apply_phase_combat_tuning()
	_phase_paused = true
	_phase_pause_timer = 0.0
	_phase_pause_duration = 0.5
	_pending_phase = 35
	_attack_active = false
	_charge_rushing = false
	velocity = Vector2.ZERO
	_reset_phase_pattern()
	_reset_phase_progress()
	_forced_attack = "teleport_slash"

	_screen_shake(35.0, 0.8)
	_hitstop(0.15)

	if has_node("Sprite"):
		get_node("Sprite").modulate = Color(1.5, 0.3, 0.3)

	_vfx("vfx_glitch_sparkle", global_position)
	_vfx("vfx_glitch_sparkle", global_position + Vector2(30, -30))
	_vfx("vfx_glitch_sparkle", global_position + Vector2(-30, -30))
	_vfx("vfx_enemy_death", global_position + Vector2(0, -20))

	contact_damage *= 1.18
	movement_speed *= 1.35
	phase_changed.emit(35)


func _enter_phase_4() -> void:
	current_boss_phase = BossPhase.PHASE_4
	## Final Stand first; Root Access opens only after the last sliver of HP.
	phase_4_locked = false
	_root_access_ready = false
	_attack_active = false
	_charge_rushing = false
	current_state = State.CHASE
	is_hostile = true
	velocity = Vector2.ZERO
	_reset_phase_pattern()
	movement_speed = BASE_MOVEMENT_SPEED * 1.6
	contact_damage = BASE_CONTACT_DAMAGE * 1.15
	_apply_phase_combat_tuning()
	_reset_phase_progress()
	_forced_attack = "charge"

	# Full phase transition juice for the climactic moment
	if has_node("/root/GameJuice"):
		GameJuice.boss_phase_transition()
	else:
		_screen_shake(30.0, 0.8)
		_hitstop(0.15)

	if has_node("Sprite"):
		get_node("Sprite").modulate = Color(1.35, 0.35, 0.35)

	_vfx("vfx_glitch_sparkle", global_position)
	_vfx("vfx_glitch_sparkle", global_position + Vector2(0, -50))
	_vfx("vfx_enemy_death", global_position + Vector2(0, -30))

	_status_text("FINAL STAND", global_position + Vector2(0, -80), false)

	phase_changed.emit(4)


func _enter_root_access_lock() -> void:
	if _root_access_ready:
		return
	_root_access_ready = true
	phase_4_locked = true
	_attack_active = false
	_charge_rushing = false
	current_state = State.IDLE
	velocity = Vector2.ZERO
	if _phase_pulse_tween and _phase_pulse_tween.is_valid():
		_phase_pulse_tween.kill()
	if has_node("Sprite"):
		var spr = get_node("Sprite")
		spr.modulate = Color(0.65, 0.45, 0.45)
		_phase_pulse_tween = create_tween().set_loops()
		_phase_pulse_tween.tween_property(spr, "modulate:a", 0.5, 0.4).set_trans(Tween.TRANS_SINE)
		_phase_pulse_tween.tween_property(spr, "modulate:a", 1.0, 0.4).set_trans(Tween.TRANS_SINE)
	_screen_shake(18.0, 0.4)
	_vfx("vfx_glitch_sparkle", global_position)
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

func _register_close_pressure_hit(knockback_source: Vector2) -> void:
	if knockback_source == Vector2.ZERO or _close_pressure_cooldown > 0.0 or phase_4_locked:
		return
	if knockback_source.distance_to(global_position) > attack_range * 1.25:
		return
	_close_pressure_hits += 1
	_close_pressure_timer = CLOSE_PRESSURE_WINDOW
	if _close_pressure_hits >= CLOSE_PRESSURE_HITS:
		_trigger_close_pressure_guard()


func _trigger_close_pressure_guard() -> void:
	_close_pressure_hits = 0
	_close_pressure_cooldown = CLOSE_PRESSURE_COOLDOWN
	_guard_timer = CLOSE_PRESSURE_GUARD_TIME
	_attack_active = false
	_charge_rushing = false
	velocity = Vector2.ZERO
	_status_text("GUARD COUNTER", global_position + Vector2(0, -72), false)
	if has_node("Sprite"):
		get_node("Sprite").modulate = Color(0.65, 0.85, 1.0)
	_front_warning(Vector2(attack_range * 0.9, 88.0), -30.0, Color(0.85, 0.95, 1.0, 0.34), 0.16)
	_force_next_attack("shield_bash")


func _apply_phase_floor_if_needed() -> bool:
	var floor_pct := _current_phase_floor_pct()
	if floor_pct <= 0.0 or _phase_requirements_met():
		return false
	var floor_hp := max_health * floor_pct + 1.0
	if current_health > floor_hp:
		return false
	current_health = floor_hp
	health_changed.emit(current_health, max_health)
	_update_health_bar()
	if _guard_timer <= 0.0:
		_guard_timer = 0.22
	_status_text("READ THE PATTERN", global_position + Vector2(0, -72), false)
	return true


func take_damage(amount: float, knockback_source: Vector2 = Vector2.ZERO) -> void:
	if current_state == State.DEAD:
		return
	_register_close_pressure_hit(knockback_source)
	if _phase_paused:
		amount *= TRANSITION_GUARD_MULT
	if _guard_timer > 0.0:
		amount *= 0.28

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
	if _apply_phase_floor_if_needed():
		return

	if current_health <= 0:
		die()
		return

	_check_phase_transitions()
	if current_boss_phase == BossPhase.PHASE_4 and not phase_4_locked and current_health / max_health <= ROOT_ACCESS_HP_PCT:
		_enter_root_access_lock()
		return

	# Phase-specific flinch behavior
	if current_boss_phase == BossPhase.PHASE_1 and current_state != State.STUNNED and not _stagger_active and _flinch_cooldown <= 0.0 and _guard_timer <= 0.0:
		_stagger_active = true
		_flinch_cooldown = 1.05
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

func reset_for_retry() -> void:
	if _phase_pulse_tween and _phase_pulse_tween.is_valid():
		_phase_pulse_tween.kill()
	current_boss_phase = BossPhase.PHASE_1
	_phase_paused = false
	_phase_pause_timer = 0.0
	_pending_phase = 0
	_phase_elapsed = 0.0
	_phase_attack_count = 0
	_boss_attack_timer = 0.0
	_boss_combo_count = 0
	_attack_active = false
	_stagger_active = false
	_slam_wave_active = false
	_charge_rushing = false
	_recent_attacks.clear()
	_phase_pattern_step = 0
	_forced_attack = ""
	_close_pressure_hits = 0
	_close_pressure_timer = 0.0
	_close_pressure_cooldown = 0.0
	_guard_timer = 0.0
	_heal_punish_cooldown = 0.0
	_flinch_cooldown = 0.0
	_status_callout_times.clear()
	_is_enraged = false
	phase_4_locked = false
	_root_access_ready = false
	contact_damage = BASE_CONTACT_DAMAGE
	movement_speed = BASE_MOVEMENT_SPEED
	attack_range = BASE_ATTACK_RANGE
	current_health = max_health
	collision_layer = 4
	collision_mask = 1
	is_hostile = true
	current_state = State.CHASE
	set_physics_process(true)
	if has_node("Sprite"):
		var spr = get_node("Sprite")
		spr.modulate = Color.WHITE
		spr.modulate.a = 1.0
	_apply_phase_combat_tuning()
	health_changed.emit(current_health, max_health)
	_update_health_bar()


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
