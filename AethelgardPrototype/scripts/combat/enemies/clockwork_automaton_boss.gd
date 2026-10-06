extends EnemyBase
class_name ClockworkAutomatonBoss

## Clockwork Automaton — 3-phase mechanical boss in the Clock Tower.
## Phase 1: Gear attacks, predictable.  Phase 2: Fast, shockwaves.
## Phase 3: Core exposed — takes double damage during exposure window.

signal boss_defeated
signal phase_changed(new_phase: int)

# ── Phase state ─────────────────────────────────────────────────────────
var phase: int = 1
var attack_timer: float = 0.0
var pattern_index: int = 0
var is_attacking: bool = false
var _active_gears: Array = []

# ── Core exposure ───────────────────────────────────────────────────────
var core_exposed: bool = false
var _core_timer: float = 0.0
const CORE_EXPOSE_DURATION = 4.0

# ── Thresholds ──────────────────────────────────────────────────────────
const PHASE2_HP_PCT = 0.65
const PHASE3_HP_PCT = 0.30

const PHASE_COOLDOWNS = { 1: 2.5, 2: 1.8, 3: 2.2 }
const PHASE_TRANSITION_COOLDOWN: float = 0.5
var _phase_transition_timer: float = PHASE_TRANSITION_COOLDOWN

# ── Intro tracking ──────────────────────────────────────────────────────
var _intro_played: bool = false


# ═════════════════════════════════════════════════════════════════════════
# LIFECYCLE
# ═════════════════════════════════════════════════════════════════════════

func _ready() -> void:
	# Set boss stats BEFORE super._ready() so level scaling applies correctly
	enemy_name = "Clockwork Automaton"
	xp_reward = 700
	gold_reward = 350
	movement_speed = 75.0
	max_health = 1200.0
	contact_damage = 70.0
	detection_range = 500.0
	attack_range = 110.0
	zone_level = 9  # Rec Lv 9 — Ironhold Clock Tower boss
	elasticity = 1.0
	gravity_scale = 1.3
	add_to_group("boss")   # before super._ready(): EnemyBase builds a boss-style HP bar from it
	super._ready()
	current_health = max_health


	tree_exiting.connect(func():
		var p = find_player()
		if is_instance_valid(p) and p.has_method("set_input_locked"):
			p.set_input_locked(false)
	)

	if not _has_gm() or not GameManager.story_flags.get("ch2_clockwork_automaton_defeated", false):
		call_deferred("_start_boss_intro")


# ═════════════════════════════════════════════════════════════════════════
# BOSS INTRO
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
	title_lbl.text = "CLOCKWORK AUTOMATON"
	title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_lbl.add_theme_font_size_override("font_size", 32)
	title_lbl.add_theme_color_override("font_color", Color(0.8, 0.65, 0.2))
	title_lbl.modulate.a = 0.0
	title_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(title_lbl)

	var subtitle_lbl = Label.new()
	subtitle_lbl.text = "— Eternal Engine of the Clock Tower —"
	subtitle_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle_lbl.add_theme_font_size_override("font_size", 14)
	subtitle_lbl.add_theme_color_override("font_color", Color(0.65, 0.6, 0.5))
	subtitle_lbl.modulate.a = 0.0
	subtitle_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(subtitle_lbl)

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

	var tw = create_tween()
	tw.tween_property(top_bar, "size:y", 60.0, 0.5).set_trans(Tween.TRANS_SINE)
	tw.parallel().tween_property(bottom_bar, "size:y", 60.0, 0.5).set_trans(Tween.TRANS_SINE)
	tw.parallel().tween_property(bottom_bar, "position:y", 660.0, 0.5).set_trans(Tween.TRANS_SINE)
	tw.parallel().tween_property(card_bg, "color:a", 0.3, 0.5)
	tw.tween_callback(func():
		_screen_shake(6.0, 0.8)
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
# AI BEHAVIOR
# ═════════════════════════════════════════════════════════════════════════

func _ai_behavior(delta: float) -> void:
	# Phase transitions
	if max_health <= 0.0:
		return
	var hp_pct = current_health / max_health
	# Check lower phases first so a large hit doesn't skip phases. One hit that
	# crosses both thresholds used to fire phase 2 and phase 3 on consecutive
	# frames (two transition juices and two barks at once); space them out.
	_phase_transition_timer += delta
	if _phase_transition_timer >= PHASE_TRANSITION_COOLDOWN:
		if hp_pct <= PHASE2_HP_PCT and phase < 2:
			_enter_phase(2)
		elif hp_pct <= PHASE3_HP_PCT and phase < 3:
			_enter_phase(3)

	attack_timer += delta

	# Core timer
	if core_exposed:
		_core_timer += delta
		if _core_timer >= CORE_EXPOSE_DURATION:
			_close_core()

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
			velocity.x = move_toward(velocity.x, 0.0, 300.0 * delta)


func _enter_phase(new_phase: int) -> void:
	phase = new_phase
	_phase_transition_timer = 0.0
	phase_changed.emit(new_phase)
	is_attacking = false
	attack_timer = 0.0
	pattern_index = 0
	velocity = Vector2.ZERO

	# Full phase transition juice
	if has_node("/root/GameJuice"):
		GameJuice.boss_phase_transition()
	else:
		_screen_shake(16.0, 0.4)
		_hitstop(0.12)

	match phase:
		2:
			movement_speed = 90.0
			contact_damage = 50.0
			_status_text("TEMPORAL ACCELERATION!", global_position + Vector2(0, -60), false)
			_vfx("vfx_glitch_sparkle", global_position)
			_vfx("vfx_hit_spark", global_position + Vector2(-30, 0))
			_vfx("vfx_hit_spark", global_position + Vector2(30, 0))
		3:
			movement_speed = 70.0
			contact_damage = 45.0
			_status_text("CORE DESTABILIZING!", global_position + Vector2(0, -60), false)
			_vfx("vfx_glitch_sparkle", global_position)
			_vfx("vfx_enemy_death", global_position + Vector2(0, -20))
			_expose_core()


func _chase(_delta: float) -> void:
	var dist = distance_to_player()
	if dist < attack_range:
		current_state = State.ATTACK
		return
	velocity.x = direction_to_player().x * movement_speed


func _attack(_delta: float) -> void:
	if distance_to_player() > attack_range * 3.0:
		current_state = State.CHASE
		return
	if is_attacking:
		return
	var cd: float = PHASE_COOLDOWNS.get(phase, 2.5)
	if attack_timer >= cd:
		_execute_pattern()
		attack_timer = 0.0


# ═════════════════════════════════════════════════════════════════════════
# ATTACK PATTERNS
# ═════════════════════════════════════════════════════════════════════════

func _execute_pattern() -> void:
	match phase:
		1: await _phase1()
		2: await _phase2()
		3: await _phase3()


func _phase1() -> void:
	is_attacking = true
	var attacks = ["hammer", "gear_throw", "stomp"]
	var atk = attacks[pattern_index % attacks.size()]
	pattern_index += 1
	match atk:
		"hammer":   await _hammer_swing()
		"gear_throw": await _gear_throw()
		"stomp":    await _stomp()
	if is_inside_tree():
		is_attacking = false


func _phase2() -> void:
	is_attacking = true
	var attacks = ["rapid", "shockwave", "gear_barrage", "charge"]
	var atk = attacks[pattern_index % attacks.size()]
	pattern_index += 1
	match atk:
		"rapid":       await _rapid_swing()
		"shockwave":   await _shockwave()
		"gear_barrage": await _gear_barrage()
		"charge":      await _charge()
	if is_inside_tree():
		is_attacking = false


func _phase3() -> void:
	is_attacking = true
	if core_exposed:
		await _desperate_swing()
	else:
		var attacks = ["overcharge", "gear_storm", "charge"]
		var atk = attacks[pattern_index % attacks.size()]
		pattern_index += 1
		match atk:
			"overcharge": await _overcharge_slam()
			"gear_storm": await _gear_storm()
			"charge":     await _charge()
		if randf() < 0.3:
			_expose_core()
	if is_inside_tree():
		is_attacking = false


# ── Attack implementations ──────────────────────────────────────────────

func _hammer_swing() -> void:
	velocity.x = 0.0
	await get_tree().create_timer(0.5, false).timeout
	if not _safe(): return
	velocity.x = direction_to_player().x * 200.0
	await get_tree().create_timer(0.25, false).timeout
	if not _safe(): return
	_deal_melee(contact_damage, 70.0)
	velocity.x = 0.0

func _rapid_swing() -> void:
	for i in 2:
		velocity.x = 0.0
		await get_tree().create_timer(0.25, false).timeout
		if not _safe(): return
		velocity.x = direction_to_player().x * 250.0
		await get_tree().create_timer(0.15, false).timeout
		if not _safe(): return
		_deal_melee(contact_damage * 0.7, 70.0)
	velocity.x = 0.0

func _gear_throw() -> void:
	var player = find_player()
	if not player: return
	_spawn_gear((player.global_position - global_position).normalized(), 200.0)

func _gear_barrage() -> void:
	for i in 3:
		var player = find_player()
		if not player: break
		var dir = (player.global_position - global_position).normalized()
		_spawn_gear(dir.rotated((i - 1) * 0.2), 220.0)
		await get_tree().create_timer(0.3, false).timeout
		if not _safe(): return

func _gear_storm() -> void:
	for i in 6:
		var angle = i * (TAU / 6.0)
		_spawn_gear(Vector2(cos(angle), sin(angle)), 180.0)
	_screen_shake(14.0, 0.3)
	_vfx("vfx_hit_spark", global_position)

func _stomp() -> void:
	velocity.y = -400.0
	await get_tree().create_timer(0.6, false).timeout
	if not _safe(): return
	velocity.y = 700.0
	await get_tree().create_timer(0.4, false).timeout
	if not _safe(): return
	_deal_melee(contact_damage * 1.2, 100.0)
	_screen_shake(10.0, 0.2)
	_vfx("vfx_hit_spark", global_position)

func _shockwave() -> void:
	velocity.y = -500.0
	await get_tree().create_timer(0.6, false).timeout
	if not _safe(): return
	velocity.y = 800.0
	await get_tree().create_timer(0.3, false).timeout
	if not _safe(): return
	_deal_melee(contact_damage * 1.5, 150.0)
	_screen_shake(16.0, 0.35)
	_vfx("vfx_hit_spark", global_position)
	_status_text("SHOCKWAVE!", global_position + Vector2(0, -50), false)

func _overcharge_slam() -> void:
	velocity.y = -600.0
	await get_tree().create_timer(0.7, false).timeout
	if not _safe(): return
	velocity.y = 900.0
	await get_tree().create_timer(0.3, false).timeout
	if not _safe(): return
	_deal_melee(contact_damage * 2.0, 180.0)
	_screen_shake(22.0, 0.5)
	_vfx("vfx_hit_spark", global_position)

func _charge() -> void:
	velocity.x = 0.0
	await get_tree().create_timer(0.6, false).timeout
	if not _safe(): return
	velocity.x = direction_to_player().x * 400.0
	velocity.y = -100.0
	await get_tree().create_timer(0.5, false).timeout
	if not _safe(): return
	_deal_melee(contact_damage * 1.3, 80.0)
	_screen_shake(8.0, 0.15)
	velocity.x = 0.0

func _desperate_swing() -> void:
	velocity.x = direction_to_player().x * 100.0
	await get_tree().create_timer(0.4, false).timeout
	if not _safe(): return
	_deal_melee(contact_damage * 0.4, 60.0)
	velocity.x = 0.0


# ═════════════════════════════════════════════════════════════════════════
# CORE EXPOSURE
# ═════════════════════════════════════════════════════════════════════════

func _expose_core() -> void:
	core_exposed = true
	_core_timer = 0.0
	_status_text("CORE EXPOSED!", global_position + Vector2(0, -60), false)
	_sfx("boss_phase", 0.2)
	if has_node("Sprite"):
		var tw = create_tween()
		tw.tween_property(get_node("Sprite"), "modulate", Color(1.0, 0.5, 0.0), 0.3)
	# Pulsing warning VFX during exposure window
	_pulse_core_warning()

func _pulse_core_warning() -> void:
	## Flash the sprite orange/white to visually signal the vulnerability window.
	while core_exposed and is_inside_tree() and current_state != State.DEAD:
		if has_node("Sprite"):
			var tw = create_tween()
			tw.tween_property(get_node("Sprite"), "modulate", Color(1.5, 0.8, 0.2), 0.2)
			tw.tween_property(get_node("Sprite"), "modulate", Color(1.0, 0.5, 0.0), 0.2)
		await get_tree().create_timer(0.4, false).timeout
		if not is_inside_tree(): return

func _close_core() -> void:
	core_exposed = false
	if has_node("Sprite"):
		var tw = create_tween()
		tw.tween_property(get_node("Sprite"), "modulate", Color.WHITE, 0.3)


# ═════════════════════════════════════════════════════════════════════════
# HELPERS
# ═════════════════════════════════════════════════════════════════════════

func _deal_melee(damage: float, range_px: float) -> void:
	var player = find_player()
	if player and player.has_method("take_damage"):
		if global_position.distance_to(player.global_position) < range_px:
			player.take_damage(damage, global_position, enemy_name, "boss")


func _spawn_gear(direction: Vector2, speed: float) -> void:
	## Create a spinning gear projectile (ColorRect placeholder).
	var gear = ColorRect.new()
	gear.color = Color(0.7, 0.6, 0.3, 0.9)
	gear.size = Vector2(16, 16)
	gear.pivot_offset = Vector2(8, 8)
	gear.mouse_filter = Control.MOUSE_FILTER_IGNORE
	get_parent().add_child(gear)
	gear.global_position = global_position
	_active_gears.append(gear)

	var elapsed = 0.0
	while elapsed < 3.0 and is_instance_valid(gear) and _safe():
		# process_frame keeps firing while the tree is paused; hold the gear still.
		if get_tree().paused:
			await get_tree().process_frame
			continue
		gear.global_position += direction * speed * get_process_delta_time()
		gear.rotation += 10.0 * get_process_delta_time()
		elapsed += get_process_delta_time()

		var player = find_player()
		if player and player.has_method("take_damage"):
			if gear.global_position.distance_to(player.global_position) < 20.0:
				player.take_damage(contact_damage * 0.6, gear.global_position, enemy_name, "boss")
				gear.queue_free()
				_active_gears.erase(gear)
				return
		await get_tree().process_frame
		if not is_inside_tree():
			if is_instance_valid(gear):
				gear.queue_free()
			_active_gears.erase(gear)
			return
	_active_gears.erase(gear)
	if is_instance_valid(gear):
		gear.queue_free()



# ═════════════════════════════════════════════════════════════════════════
# DAMAGE / DEATH
# ═════════════════════════════════════════════════════════════════════════

func take_damage(amount: float, knockback_source: Vector2 = Vector2.ZERO) -> void:
	var final = amount
	if core_exposed:
		final = amount * 2.0
		_status_text("CORE CRITICAL!", global_position + Vector2(0, -40), false)
		# Extra juice for core hits — reward the player for timing
		_screen_shake(8.0, 0.15)
		_hitstop(0.06)
		_vfx("vfx_glitch_sparkle", global_position + Vector2(0, -20))
		if has_node("Sprite"):
			var flash_tw = create_tween()
			flash_tw.tween_property(get_node("Sprite"), "modulate", Color(3.0, 2.0, 0.5), 0.03)
			flash_tw.tween_property(get_node("Sprite"), "modulate", Color(1.0, 0.5, 0.0), 0.1)
	super.take_damage(final, knockback_source)


func die() -> void:
	if current_state == State.DEAD:
		return
	current_state = State.DEAD
	velocity = Vector2.ZERO
	set_physics_process(false)
	if has_node("/root/GameManager"):
		GameManager.end_boss_fight()
	boss_defeated.emit()
	# Full boss death sequence
	if has_node("/root/GameJuice"):
		GameJuice.boss_death_sequence()
	# Clean up all active gear projectiles
	for g in _active_gears:
		if is_instance_valid(g):
			g.queue_free()
	_active_gears.clear()
	for i in 8:
		var offset = Vector2(randf_range(-40, 40), randf_range(-50, 10))
		_vfx("vfx_enemy_death", global_position + offset)
		await get_tree().create_timer(0.15, false).timeout
		if not is_inside_tree():
			return
	super.die()
