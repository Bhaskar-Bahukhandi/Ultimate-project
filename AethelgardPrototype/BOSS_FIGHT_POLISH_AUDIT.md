# Boss Fight Polish & Game Feel Audit

**Date:** 2026-03-01  
**Scope:** All 4 boss encounters — Tutorial Knight, Clockwork Automaton, Data Wraith, Administrator Proxy  
**Focus:** Polish, game feel, missing features, attack patterns, phase transitions, victory sequences

---

## Executive Summary

The boss fight systems are structurally sound with proper state machines, phase transitions, null-checks, and cleanup. The major gaps are in **game feel polish**: missing `GameJuice` integration for phase transitions, no `boss_death_sequence()` calls, missing telegraph animations for attacks, no recovery windows after combos, and no victory reward UI. The fixes below are prioritized by impact.

---

## 1. TUTORIAL KNIGHT BOSS (`tutorial_knight_boss_enemy.gd`)

### 1A. Phase Transitions — Missing GameJuice Integration

**Problem:** Phase transitions use raw `_screen_shake` and `_vfx` but never call `GameJuice.boss_phase_transition()` which provides hitstop + shake + flash + slowmo + zoom. The encounter script (`ch1_tutorial_knight.gd`) handles hitstop/phase flash, but the boss itself should also trigger the full juice pipeline so it works even outside the chapter script.

**File:** `scripts/combat/enemies/tutorial_knight_boss_enemy.gd`  
**Location:** `_trigger_phase_pause()` (~line 511)

```gdscript
# OLD:
func _trigger_phase_pause(phase_number: int) -> void:
	## Brief stagger + VFX on phase change.
	_phase_paused = true
	_phase_pause_timer = 0.0
	_pending_phase = phase_number
	_attack_active = false
	_charge_rushing = false
	velocity = Vector2.ZERO

	_screen_shake(22.0, 0.5)
	_hitstop(0.1)

	if has_node("Sprite"):
		get_node("Sprite").modulate = Color(2, 2, 2)

	_vfx("vfx_glitch_sparkle", global_position)
	_vfx("vfx_glitch_sparkle", global_position + Vector2(30, -30))
	phase_changed.emit(phase_number)

# NEW:
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
```

### 1B. Missing Recovery Windows After Combos

**Problem:** After the boss completes a combo (hits `_boss_max_combo`), cooldown resets immediately. The player gets no breathing room. In Hollow Knight, after every boss combo there's a clear 0.8-1.5s window where the boss stands still and the player can heal or attack.

**File:** `scripts/combat/enemies/tutorial_knight_boss_enemy.gd`  
**Location:** `_execute_boss_attack()` (~line 276)

```gdscript
# OLD:
	_boss_combo_count += 1
	if _boss_combo_count >= _boss_max_combo:
		_boss_combo_count = 0
		_attack_active = false
	else:
		# Chain next attack quickly
		_boss_attack_timer = _boss_attack_cooldown * 0.7
		_attack_active = false

# NEW:
	_boss_combo_count += 1
	if _boss_combo_count >= _boss_max_combo:
		_boss_combo_count = 0
		# Recovery window — boss visibly pauses after a combo
		velocity.x = 0.0
		if has_node("Sprite"):
			get_node("Sprite").modulate = Color(0.8, 0.8, 1.0) if not _is_enraged else Color(1.2, 0.5, 0.5)
		var recovery_time = 1.2 if not _is_enraged else 0.7
		await get_tree().create_timer(recovery_time).timeout
		if not _safe():
			_attack_active = false
			return
		if has_node("Sprite"):
			get_node("Sprite").modulate = Color.WHITE if not _is_enraged else Color(1.5, 0.3, 0.3)
		_attack_active = false
	else:
		# Chain next attack quickly
		_boss_attack_timer = _boss_attack_cooldown * 0.7
		_attack_active = false
```

### 1C. Attack Telegraphs Need Clearer Visual + Audio Cues

**Problem:** Only `_attack_slash` has a telegraph (brief color change). Other attacks like `_attack_charge`, `_attack_shockwave`, `_attack_teleport_slash` lack the "!" telegraph that `GameJuice.on_enemy_telegraph()` provides. Players can't read what's coming.

**File:** `scripts/combat/enemies/tutorial_knight_boss_enemy.gd`  
**Location:** `_attack_charge()` (~line 350)

```gdscript
# OLD:
func _attack_charge() -> void:
	velocity.x = 0.0
	_status_text("!", global_position + Vector2(0, -50), false)
	await get_tree().create_timer(0.4).timeout

# NEW:
func _attack_charge() -> void:
	velocity.x = 0.0
	if has_node("/root/GameJuice"):
		GameJuice.on_enemy_telegraph(self, "charge")
	else:
		_status_text("!", global_position + Vector2(0, -50), false)
	# Brief crouch telegraph — boss squats before charging
	if has_node("Sprite"):
		var spr = get_node("Sprite")
		var tw = create_tween()
		tw.tween_property(spr, "scale:y", spr.scale.y * 0.8, 0.15)
		tw.tween_property(spr, "scale:y", spr.scale.y, 0.1)
	await get_tree().create_timer(0.4).timeout
```

**Location:** `_attack_shockwave()` (~line 395)

```gdscript
# OLD:
func _attack_shockwave() -> void:
	velocity.y = -500.0
	_sfx("heavy_windup")
	await get_tree().create_timer(0.5).timeout

# NEW:
func _attack_shockwave() -> void:
	if has_node("/root/GameJuice"):
		GameJuice.on_enemy_telegraph(self, "heavy")
	_sfx("heavy_windup")
	# Wind-up crouch before leap
	velocity.x = 0.0
	if has_node("Sprite"):
		var spr = get_node("Sprite")
		var tw = create_tween()
		tw.tween_property(spr, "scale", Vector2(spr.scale.x * 1.15, spr.scale.y * 0.7), 0.2)
		tw.tween_property(spr, "scale", Vector2(spr.scale.x * 0.8, spr.scale.y * 1.3), 0.15)
	await get_tree().create_timer(0.4).timeout
	if not _safe(): return
	velocity.y = -500.0
	await get_tree().create_timer(0.5).timeout
```

### 1D. Death Sequence — Missing `boss_death_sequence()`

**Problem:** `die()` calls basic VFX but never triggers `GameJuice.boss_death_sequence()` which provides dramatic slowmo + screen shake + shatter + zoom. This is a significant missing piece for the climactic moment.

**File:** `scripts/combat/enemies/tutorial_knight_boss_enemy.gd`  
**Location:** `die()` (~line 650)

```gdscript
# OLD:
func die() -> void:
	if current_state == State.DEAD:
		return
	current_state = State.DEAD
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

	if has_node("/root/GameJuice"):
		GameJuice.on_enemy_die(self)

# NEW:
func die() -> void:
	if current_state == State.DEAD:
		return
	current_state = State.DEAD
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

	# Full boss death juice: slowmo + shake + flash + shatter
	if has_node("/root/GameJuice"):
		GameJuice.boss_death_sequence()
	else:
		_screen_shake(20.0, 0.8)
```

### 1E. Phase 4 (Root Access) — No Visual Prompt

**Problem:** When Phase 4 triggers and the knight freezes, the only feedback is a signal emission and a color change. There's no pulsing "Use Root Access [E]" prompt on the boss itself.

**File:** `scripts/combat/enemies/tutorial_knight_boss_enemy.gd`  
**Location:** `_enter_phase_4()` (~line 556)

```gdscript
# OLD:
func _enter_phase_4() -> void:
	## Knight locks in infinite loop — Root Access or finish by force.
	phase_4_locked = true
	_attack_active = false
	_charge_rushing = false
	current_state = State.IDLE
	velocity = Vector2.ZERO

	_screen_shake(30.0, 0.8)
	_hitstop(0.15)

	if has_node("Sprite"):
		get_node("Sprite").modulate = Color(0.65, 0.45, 0.45)

	_vfx("vfx_glitch_sparkle", global_position)
	_vfx("vfx_glitch_sparkle", global_position + Vector2(0, -50))
	_vfx("vfx_enemy_death", global_position + Vector2(0, -30))
	root_access_triggered.emit()

# NEW:
func _enter_phase_4() -> void:
	## Knight locks in infinite loop — Root Access or finish by force.
	phase_4_locked = true
	_attack_active = false
	_charge_rushing = false
	current_state = State.IDLE
	velocity = Vector2.ZERO

	if has_node("/root/GameJuice"):
		GameJuice.boss_phase_transition()
	else:
		_screen_shake(30.0, 0.8)
		_hitstop(0.15)

	if has_node("Sprite"):
		get_node("Sprite").modulate = Color(0.65, 0.45, 0.45)
		# Pulsing glitch effect to signal the knight is stuck in a loop
		var pulse = create_tween().set_loops()
		pulse.tween_property(get_node("Sprite"), "modulate:a", 0.5, 0.4).set_trans(Tween.TRANS_SINE)
		pulse.tween_property(get_node("Sprite"), "modulate:a", 1.0, 0.4).set_trans(Tween.TRANS_SINE)

	_vfx("vfx_glitch_sparkle", global_position)
	_vfx("vfx_glitch_sparkle", global_position + Vector2(0, -50))
	_vfx("vfx_enemy_death", global_position + Vector2(0, -30))

	# Spawn persistent "ROOT ACCESS [E]" prompt above boss
	_status_text("[E] ROOT ACCESS", global_position + Vector2(0, -80), true)

	root_access_triggered.emit()
```

---

## 2. CLOCKWORK AUTOMATON BOSS (`clockwork_automaton_boss.gd`)

### 2A. Phase Transitions — Zero Feedback

**Problem:** `_enter_phase()` only changes stats and shows a status text. No hitstop, no screen effect, no slowmo. Phase 3 core exposure is a critical moment that should feel dramatic.

**File:** `scripts/combat/enemies/clockwork_automaton_boss.gd`  
**Location:** `_enter_phase()` (~line 188)

```gdscript
# OLD:
func _enter_phase(new_phase: int) -> void:
	phase = new_phase
	phase_changed.emit(new_phase)
	is_attacking = false
	attack_timer = 0.0
	pattern_index = 0
	_status_text("PHASE %d!" % phase, global_position + Vector2(0, -60), false)
	_vfx("vfx_hit_spark", global_position)

	match phase:
		2:
			movement_speed = 90.0
			contact_damage = 50.0
		3:
			movement_speed = 70.0
			contact_damage = 45.0
			_expose_core()

# NEW:
func _enter_phase(new_phase: int) -> void:
	phase = new_phase
	phase_changed.emit(new_phase)
	is_attacking = false
	attack_timer = 0.0
	pattern_index = 0

	# Full phase transition juice
	if has_node("/root/GameJuice"):
		GameJuice.boss_phase_transition()
	else:
		_screen_shake(16.0, 0.4)
		_hitstop(0.12)

	velocity = Vector2.ZERO

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
```

### 2B. Attack Telegraphs Missing

**Problem:** None of the Automaton's attacks call `GameJuice.on_enemy_telegraph()`. The hammer swing, stomp, charge, and shockwave all happen with zero warning. Adding telegraph calls gives the player readable cues.

**File:** `scripts/combat/enemies/clockwork_automaton_boss.gd`  
**Location:** `_hammer_swing()` (~line 308), `_stomp()` (~line 337), `_shockwave()` (~line 345), `_charge()` (~line 360)

```gdscript
# ADD at the start of each attack function:

func _hammer_swing() -> void:
	if has_node("/root/GameJuice"):
		GameJuice.on_enemy_telegraph(self, "heavy")
	velocity.x = 0.0
	# ... rest unchanged

func _stomp() -> void:
	if has_node("/root/GameJuice"):
		GameJuice.on_enemy_telegraph(self, "heavy")
	velocity.y = -400.0
	# ... rest unchanged

func _shockwave() -> void:
	if has_node("/root/GameJuice"):
		GameJuice.on_enemy_telegraph(self, "aoe")
	velocity.y = -500.0
	# ... rest unchanged

func _charge() -> void:
	if has_node("/root/GameJuice"):
		GameJuice.on_enemy_telegraph(self, "charge")
	velocity.x = 0.0
	# ... rest unchanged
```

### 2C. Core Exposure Takes Double Damage But Lacks Satisfying Feedback

**Problem:** When core is exposed, `take_damage()` doubles the amount and shows "CRITICAL!" text, but there's no special hit juice (extra screen shake, different SFX, flash color) to make the player feel rewarded for hitting during the window.

**File:** `scripts/combat/enemies/clockwork_automaton_boss.gd`  
**Location:** `take_damage()` (~line 440)

```gdscript
# OLD:
func take_damage(amount: float, knockback_source: Vector2 = Vector2.ZERO) -> void:
	var final = amount
	if core_exposed:
		final = amount * 2.0
		_status_text("CRITICAL!", global_position + Vector2(0, -40), false)
	super.take_damage(final, knockback_source)

# NEW:
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
			var spr = get_node("Sprite")
			var flash_tw = create_tween()
			flash_tw.tween_property(spr, "modulate", Color(3.0, 2.0, 0.5), 0.03)
			flash_tw.tween_property(spr, "modulate", Color(1.0, 0.5, 0.0), 0.1)
	super.take_damage(final, knockback_source)
```

### 2D. Death Sequence — No Boss Death Juice

**File:** `scripts/combat/enemies/clockwork_automaton_boss.gd`  
**Location:** `die()` (~line 460)

```gdscript
# OLD:
func die() -> void:
	if current_state == State.DEAD:
		return
	current_state = State.DEAD
	if has_node("/root/GameManager"):
		GameManager.end_boss_fight()
	boss_defeated.emit()
	# Clean up all active gear projectiles
	for g in _active_gears:
		if is_instance_valid(g):
			g.queue_free()
	_active_gears.clear()
	for i in 8:

# NEW:
func die() -> void:
	if current_state == State.DEAD:
		return
	current_state = State.DEAD
	if has_node("/root/GameManager"):
		GameManager.end_boss_fight()
	boss_defeated.emit()
	velocity = Vector2.ZERO
	set_physics_process(false)
	# Clean up all active gear projectiles
	for g in _active_gears:
		if is_instance_valid(g):
			g.queue_free()
	_active_gears.clear()
	# Full boss death sequence
	if has_node("/root/GameJuice"):
		GameJuice.boss_death_sequence()
	for i in 8:
```

### 2E. Missing Core Timer Visual

**Problem:** When the core is exposed, there's no countdown visual showing the player how long the window lasts. The 4-second window is invisible.

**File:** `scripts/combat/enemies/clockwork_automaton_boss.gd`  
**Location:** `_expose_core()` (~line 405)

```gdscript
# OLD:
func _expose_core() -> void:
	core_exposed = true
	_core_timer = 0.0
	_status_text("CORE EXPOSED!", global_position + Vector2(0, -60), false)
	if has_node("Sprite"):
		var tw = create_tween()
		tw.tween_property(get_node("Sprite"), "modulate", Color(1.0, 0.5, 0.0), 0.3)

# NEW:
func _expose_core() -> void:
	core_exposed = true
	_core_timer = 0.0
	_status_text("CORE EXPOSED — STRIKE NOW!", global_position + Vector2(0, -60), true)
	_screen_shake(10.0, 0.3)
	if has_node("Sprite"):
		var spr = get_node("Sprite")
		# Dramatic flash to orange
		var tw = create_tween()
		tw.tween_property(spr, "modulate", Color(3.0, 2.0, 0.5), 0.05)
		tw.tween_property(spr, "modulate", Color(1.0, 0.5, 0.0), 0.25)
		# Pulsing glow while core is exposed
		var pulse = create_tween().set_loops(int(CORE_EXPOSE_DURATION / 0.6))
		pulse.tween_property(spr, "modulate:a", 0.6, 0.3).set_trans(Tween.TRANS_SINE)
		pulse.tween_property(spr, "modulate:a", 1.0, 0.3).set_trans(Tween.TRANS_SINE)
```

---

## 3. DATA WRAITH MINI-BOSS (`data_wraith_boss.gd`)

### 3A. Missing Boss Intro Cinematic

**Problem:** Data Wraith is the only boss that has NO intro sequence. It just calls `GameManager.start_boss_fight()` and is immediately hostile. Every other boss has letterbox bars, title card, and a zoom-in.

**File:** `scripts/combat/enemies/data_wraith_boss.gd`  
**Location:** `_ready()` (~line 22)

```gdscript
# OLD:
func _ready() -> void:
	# Set boss stats BEFORE super._ready() so level scaling applies correctly
	enemy_name = "Data Wraith"
	xp_reward = 150
	gold_reward = 80
	attack_cooldown = 2.0
	movement_speed = 80.0
	max_health = 200.0
	contact_damage = 35.0
	detection_range = 400.0
	attack_range = 120.0
	elasticity = 1.0
	gravity_scale = 0.2  # Floats ominously
	super._ready()
	current_health = max_health

	add_to_group("boss")

	if has_node("/root/GameManager"):
		GameManager.start_boss_fight()

# NEW:
var _intro_played: bool = false

func _ready() -> void:
	# Set boss stats BEFORE super._ready() so level scaling applies correctly
	enemy_name = "Data Wraith"
	xp_reward = 150
	gold_reward = 80
	attack_cooldown = 2.0
	movement_speed = 80.0
	max_health = 200.0
	contact_damage = 35.0
	detection_range = 400.0
	attack_range = 120.0
	elasticity = 1.0
	gravity_scale = 0.2  # Floats ominously
	super._ready()
	current_health = max_health

	add_to_group("boss")

	tree_exiting.connect(func():
		var p = find_player()
		if is_instance_valid(p) and p.has_method("set_input_locked"):
			p.set_input_locked(false)
	)

	call_deferred("_start_boss_intro")


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
	title_lbl.text = "DATA WRAITH"
	title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_lbl.add_theme_font_size_override("font_size", 28)
	title_lbl.add_theme_color_override("font_color", Color(0.6, 0.2, 1.0))
	title_lbl.modulate.a = 0.0
	title_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(title_lbl)

	var subtitle_lbl = Label.new()
	subtitle_lbl.text = "— Corrupted System Process —"
	subtitle_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle_lbl.add_theme_font_size_override("font_size", 12)
	subtitle_lbl.add_theme_color_override("font_color", Color(0.5, 0.3, 0.7))
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
	tw.tween_property(top_bar, "size:y", 50.0, 0.4).set_trans(Tween.TRANS_SINE)
	tw.parallel().tween_property(bottom_bar, "size:y", 50.0, 0.4).set_trans(Tween.TRANS_SINE)
	tw.parallel().tween_property(bottom_bar, "position:y", 670.0, 0.4).set_trans(Tween.TRANS_SINE)
	tw.parallel().tween_property(card_bg, "color:a", 0.25, 0.4)
	tw.tween_property(title_lbl, "modulate:a", 1.0, 0.5).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
	tw.tween_property(subtitle_lbl, "modulate:a", 1.0, 0.3)
	tw.tween_interval(1.5)
	tw.tween_property(title_lbl, "modulate:a", 0.0, 0.3)
	tw.parallel().tween_property(subtitle_lbl, "modulate:a", 0.0, 0.3)
	tw.parallel().tween_property(card_bg, "color:a", 0.0, 0.3)
	tw.tween_property(top_bar, "size:y", 0.0, 0.3).set_trans(Tween.TRANS_SINE)
	tw.parallel().tween_property(bottom_bar, "size:y", 0.0, 0.3).set_trans(Tween.TRANS_SINE)
	tw.parallel().tween_property(bottom_bar, "position:y", 720.0, 0.3).set_trans(Tween.TRANS_SINE)
	tw.tween_callback(func():
		canvas.queue_free()
		is_hostile = true
		current_state = State.CHASE
		if is_instance_valid(player) and player.has_method("set_input_locked"):
			player.set_input_locked(false)
	)
```

### 3B. Phase 2 Transition — Too Subtle

**Problem:** Phase 2 only changes speed/cooldown values, shows a status text, and tints the sprite purple. No hitstop, no shake, no slowmo. For a boss that's supposed to feel dangerous when enraged, this is underwhelming.

**File:** `scripts/combat/enemies/data_wraith_boss.gd`  
**Location:** `_enter_phase_2()` (~line 66)

```gdscript
# OLD:
func _enter_phase_2() -> void:
	phase = 2
	attack_cooldown = 1.4
	_tendril_cd = 2.5
	_corruption_field_cd = 5.0
	movement_speed = 110.0

	_vfx("vfx_glitch_sparkle", global_position)
	_status_text("CORRUPTED SURGE!", global_position + Vector2(0, -50), false)

	if has_node("Sprite"):
		var tw = create_tween()
		tw.tween_property(get_node("Sprite"), "modulate", Color(0.8, 0.0, 1.0), 0.5)

# NEW:
func _enter_phase_2() -> void:
	phase = 2
	attack_cooldown = 1.4
	_tendril_cd = 2.5
	_corruption_field_cd = 5.0
	movement_speed = 110.0

	# Full phase transition juice
	if has_node("/root/GameJuice"):
		GameJuice.boss_phase_transition()
	else:
		_screen_shake(12.0, 0.3)
		_hitstop(0.1)

	_vfx("vfx_glitch_sparkle", global_position)
	_vfx("vfx_glitch_sparkle", global_position + Vector2(20, -30))
	_vfx("vfx_glitch_sparkle", global_position + Vector2(-20, -30))
	_status_text("CORRUPTED SURGE!", global_position + Vector2(0, -50), false)

	if has_node("Sprite"):
		var spr = get_node("Sprite")
		var tw = create_tween()
		tw.tween_property(spr, "modulate", Color(2.0, 0.5, 3.0), 0.05)
		tw.tween_property(spr, "modulate", Color(0.8, 0.0, 1.0), 0.45)
```

### 3C. Death Sequence — Missing Boss Death Juice + No Cleanup Guard

**File:** `scripts/combat/enemies/data_wraith_boss.gd`  
**Location:** `die()` (~line 230)

```gdscript
# OLD:
func die() -> void:
	if current_state == State.DEAD:
		return
	current_state = State.DEAD
	if has_node("/root/GameManager"):
		GameManager.end_boss_fight()
	boss_defeated.emit()
	# Clean up all active projectiles
	for t in _active_tendrils:
		if is_instance_valid(t):
			t.queue_free()
	_active_tendrils.clear()
	for f in _active_fields:
		if is_instance_valid(f):
			f.queue_free()
	_active_fields.clear()
	for i in 5:

# NEW:
func die() -> void:
	if current_state == State.DEAD:
		return
	current_state = State.DEAD
	velocity = Vector2.ZERO
	set_physics_process(false)
	if has_node("/root/GameManager"):
		GameManager.end_boss_fight()
	boss_defeated.emit()
	# Full boss death juice
	if has_node("/root/GameJuice"):
		GameJuice.boss_death_sequence()
	# Clean up all active projectiles
	for t in _active_tendrils:
		if is_instance_valid(t):
			t.queue_free()
	_active_tendrils.clear()
	for f in _active_fields:
		if is_instance_valid(f):
			f.queue_free()
	_active_fields.clear()
	for i in 5:
```

### 3D. Corruption Field Lacks Telegraph

**Problem:** The corruption field spawns instantly at the player's feet with no warning. Player needs ~0.5s to react.

**File:** `scripts/combat/enemies/data_wraith_boss.gd`  
**Location:** `_spawn_corruption_field()` (~line 131)

```gdscript
# OLD:
func _spawn_corruption_field() -> void:
	if current_state == State.DEAD:
		return
	var player = find_player()
	if not player:
		return

	var field = ColorRect.new()
	field.color = Color(0.5, 0.0, 0.8, 0.4)
	field.size = Vector2(150, 30)

# NEW:
func _spawn_corruption_field() -> void:
	if current_state == State.DEAD:
		return
	var player = find_player()
	if not player:
		return

	# Telegraph — pulsing warning marker before field appears
	var warning = ColorRect.new()
	warning.color = Color(0.5, 0.0, 0.8, 0.15)
	warning.size = Vector2(150, 30)
	warning.mouse_filter = Control.MOUSE_FILTER_IGNORE
	get_parent().add_child(warning)
	warning.global_position = Vector2(player.global_position.x - 75, player.global_position.y)
	var warn_tw = create_tween().set_loops(3)
	warn_tw.tween_property(warning, "modulate:a", 0.3, 0.15)
	warn_tw.tween_property(warning, "modulate:a", 1.0, 0.15)
	_sfx("enemy_telegraph")
	await get_tree().create_timer(0.5).timeout
	if not _safe():
		if is_instance_valid(warning): warning.queue_free()
		return
	if is_instance_valid(warning): warning.queue_free()

	var field = ColorRect.new()
	field.color = Color(0.5, 0.0, 0.8, 0.4)
	field.size = Vector2(150, 30)
```

---

## 4. ADMINISTRATOR PROXY BOSS (`administrator_proxy_boss.gd`)

### 4A. Missing Boss Intro Cinematic

**Problem:** The Administrator Proxy has no `_start_boss_intro()` despite being the Ch2 final boss. The encounter script handles dialogue, but the boss itself starts hostile immediately. This means if reused outside the encounter script, there's no intro.

**File:** `scripts/combat/enemies/administrator_proxy_boss.gd`  
**Location:** `_ready()` (~line 35)

```gdscript
# OLD:
func _ready() -> void:
	...
	add_to_group("boss")
	add_to_group("administrator")

	tree_exiting.connect(func():
		var p = find_player()
		if is_instance_valid(p) and p.has_method("set_input_locked"):
			p.set_input_locked(false)
	)

	if has_node("/root/GameManager"):
		GameManager.start_boss_fight()

# RECOMMENDATION: Add _intro_played tracking + call_deferred("_start_boss_intro")
# similar to Tutorial Knight pattern, but gated on story flag:
#   if not _has_gm() or not GameManager.story_flags.get("administrator_proxy_defeated", false):
#       call_deferred("_start_boss_intro")
# For now the ch2_administrator_boss.gd encounter handles this via _entry_dialogue().
# But add a fallback intro for standalone testing.
```

### 4B. Phase Transitions — Inconsistent Feedback

**Problem:** `_enter_phase()` shows status text and changes stats but no hitstop/slowmo for phases 2-4. Phase 4 "ROOT ACCESS DUEL" is the climax but gets the same treatment as Phase 2.

**File:** `scripts/combat/enemies/administrator_proxy_boss.gd`  
**Location:** `_enter_phase()` (~line 96)

```gdscript
# OLD:
func _enter_phase(p: int) -> void:
	phase = p
	phase_changed.emit(p)
	is_attacking = false
	attack_timer = 0.0
	pattern_index = 0
	_command_timer = 0.0

	_vfx("vfx_hit_spark", global_position)

	match phase:
		2:
			_status_text("ADMIN MODE ACTIVATED", global_position + Vector2(0, -70), false)
			movement_speed = 120.0
		3:
			_status_text("/DELETE PROTOCOL INITIATED", global_position + Vector2(0, -70), false)
			contact_damage = 60.0
		4:
			_status_text("ROOT ACCESS DUEL!", global_position + Vector2(0, -70), false)
			movement_speed = 150.0
			for key in _phase_cooldowns:
				_phase_cooldowns[key] = 1.2

# NEW:
func _enter_phase(p: int) -> void:
	phase = p
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
			if has_node("/root/GameJuice"):
				GameJuice.screen_distortion_pulse(0.6, 0.5)
			_vfx("vfx_glitch_sparkle", global_position)
			_vfx("vfx_glitch_sparkle", global_position + Vector2(-40, -40))
			_vfx("vfx_glitch_sparkle", global_position + Vector2(40, -40))
			_vfx("vfx_enemy_death", global_position + Vector2(0, -30))
			if has_node("Sprite"):
				var tw = create_tween()
				tw.tween_property(get_node("Sprite"), "modulate", Color(3.0, 0.5, 3.0), 0.05)
				tw.tween_property(get_node("Sprite"), "modulate", Color(0.8, 0.2, 0.8), 0.4)
```

### 4C. /ban Command — Damages But Doesn't Actually Stun

**Problem:** The `/ban` command says "STUNNED!" but only deals 15 damage. It doesn't actually apply any stun/slow to the player. `/mute` says "SILENCED!" but doesn't disable spells. These commands need mechanical teeth.

**File:** `scripts/combat/enemies/administrator_proxy_boss.gd`  
**Location:** `_admin_command()` (~line 218)

```gdscript
# OLD:
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

# NEW:
	match command:
		"ban":
			var player = find_player()
			if player and player.has_method("take_damage"):
				player.take_damage(15.0, global_position, enemy_name, "boss")
				_status_text("/BAN — STUNNED!", player.global_position + Vector2(0, -40), false)
				# Actually stun the player briefly
				if player.has_method("set_input_locked"):
					player.set_input_locked(true)
				_screen_shake(6.0, 0.2)
				_vfx("vfx_glitch_sparkle", player.global_position)
			await get_tree().create_timer(1.0).timeout
			if not _safe(): return
			# Unlock player after stun duration
			var player2 = find_player()
			if player2 and player2.has_method("set_input_locked"):
				player2.set_input_locked(false)
		"mute":
			var player = find_player()
			var pos = player.global_position + Vector2(0, -40) if player else global_position
			_status_text("/MUTE — SILENCED!", pos, false)
			_vfx("vfx_glitch_sparkle", pos)
			# Disable spells for 3 seconds if player supports it
			if player and player.has_method("set_spells_locked"):
				player.set_spells_locked(true)
			await get_tree().create_timer(1.5).timeout
			if not _safe(): return
			if player and is_instance_valid(player) and player.has_method("set_spells_locked"):
				player.set_spells_locked(false)
```

### 4D. /delete — No Dramatic Build-up

**Problem:** `/DELETE @KAELEN` appears as text for 1.5s, then some damage and a VFX. For the game's most dramatic attack, this needs more buildup — screen darkening, charging VFX, slow mo.

**File:** `scripts/combat/enemies/administrator_proxy_boss.gd`  
**Location:** `_attempt_delete()` (~line 283)

```gdscript
# OLD:
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

# NEW:
func _attempt_delete() -> void:
	_delete_attempts += 1
	velocity = Vector2.ZERO

	# Build-up: screen darkens, boss glows red
	_status_text("/DELETE @KAELEN", global_position + Vector2(0, -60), false)
	if has_node("/root/GameJuice"):
		GameJuice.dramatic_zoom(2.0, 1.1)
	if has_node("Sprite"):
		var charge_tw = create_tween()
		charge_tw.tween_property(get_node("Sprite"), "modulate", Color(3.0, 0.0, 0.0), 0.3)

	# Charging phase — screen shake builds
	for i in 3:
		_screen_shake(4.0 + i * 3.0, 0.2)
		await get_tree().create_timer(0.4).timeout
		if not _safe(): return

	# The delete attempt fires
	var player = find_player()
	if player:
		_screen_shake(15.0, 0.3)
		_hitstop(0.15)
		_vfx("vfx_glitch_sparkle", player.global_position)
		_vfx("vfx_glitch_sparkle", player.global_position + Vector2(20, -20))
		_vfx("vfx_glitch_sparkle", player.global_position + Vector2(-20, -20))
		_status_text("ROOT ACCESS: DELETE BLOCKED!", player.global_position + Vector2(0, -50), true)
		if player.has_method("take_damage"):
			player.take_damage(contact_damage * 0.5, global_position, enemy_name, "boss")
		if has_node("/root/GameManager"):
			GameManager.add_glitch_corruption(3.0)

	# Recovery — boss staggers from failed delete
	if has_node("Sprite"):
		var recover_tw = create_tween()
		recover_tw.tween_property(get_node("Sprite"), "modulate", Color(0.8, 0.0, 0.15), 0.3)
	await get_tree().create_timer(1.0).timeout
```

### 4E. Death Sequence — Needs Extra Drama for Final Boss

**File:** `scripts/combat/enemies/administrator_proxy_boss.gd`  
**Location:** `die()` (~line 390)

```gdscript
# OLD:
func die() -> void:
	if current_state == State.DEAD:
		return
	current_state = State.DEAD
	if has_node("/root/GameManager"):
		GameManager.end_boss_fight()
	boss_defeated.emit()
	# Clean up all active projectiles
	for p in _active_projs:
		if is_instance_valid(p):
			p.queue_free()
	_active_projs.clear()
	_status_text("[ADMIN PROXY TERMINATED]", global_position + Vector2(0, -70), false)

	for i in 10:

# NEW:
func die() -> void:
	if current_state == State.DEAD:
		return
	current_state = State.DEAD
	velocity = Vector2.ZERO
	set_physics_process(false)
	if has_node("/root/GameManager"):
		GameManager.end_boss_fight()
	boss_defeated.emit()
	# Clean up all active projectiles
	for p in _active_projs:
		if is_instance_valid(p):
			p.queue_free()
	_active_projs.clear()

	# Full boss death sequence — extra dramatic for final boss
	if has_node("/root/GameJuice"):
		GameJuice.boss_death_sequence()
	_status_text("[ADMIN PROXY TERMINATED]", global_position + Vector2(0, -70), false)
	_status_text("[SYSTEM AUTHORITY REVOKED]", global_position + Vector2(0, -90), true)

	for i in 10:
```

---

## 5. ENCOUNTER SCRIPTS

### 5A. ch2_administrator_boss.gd — Missing Phase Indicator Updates

**Problem:** The phase label in the HUD is created but `_on_phase_changed()` only updates it for phase 2. The check uses `if hp_pct <= PHASE2_HP and phase < 2` in the boss, but the encounter script's `_on_phase_changed()` handles all phases, which is correct. However, phase 3 and 4 don't update `PhaseLabel` text — the encounter script only updates it generically.

Already handled: `_on_phase_changed()` does set `phase_label.text = "PHASE %d" % new_phase` — this is correct.

### 5B. ch2_clock_tower.gd — No Boss HP Bar in HUD

**Problem:** The clock tower spawns the Clockwork Automaton boss but doesn't create a centralized boss HP bar in the HUD. The only HP display is the tiny 70px bar attached to the boss node itself. For a major boss fight at the top of a tower dungeon, this needs a proper screen-top HP bar.

**File:** `scripts/chapter2/ch2_clock_tower.gd`  
**Location:** After `_spawn_clockwork_automaton()` (~line 395)

```gdscript
# ADD: Boss HP bar creation after boss spawn
func _spawn_clockwork_automaton() -> void:
	## (existing code to spawn boss...)
	## ... after add_child(boss):

	# Create boss HP bar HUD
	var hud = CanvasLayer.new()
	hud.layer = 50
	hud.name = "BossHUD"
	add_child(hud)

	var bar_bg = ColorRect.new()
	bar_bg.color = Color(0.1, 0.05, 0.0, 0.8)
	bar_bg.size = Vector2(500, 28)
	bar_bg.position = Vector2(390, 15)
	hud.add_child(bar_bg)

	var boss_bar = ProgressBar.new()
	boss_bar.name = "BossHPBar"
	boss_bar.size = Vector2(496, 24)
	boss_bar.position = Vector2(392, 17)
	boss_bar.value = 100
	boss_bar.show_percentage = false
	var fill = StyleBoxFlat.new()
	fill.bg_color = Color(0.8, 0.6, 0.1)
	boss_bar.add_theme_stylebox_override("fill", fill)
	hud.add_child(boss_bar)

	var name_lbl = Label.new()
	name_lbl.text = "CLOCKWORK AUTOMATON"
	name_lbl.position = Vector2(530, 42)
	name_lbl.add_theme_font_size_override("font_size", 11)
	name_lbl.add_theme_color_override("font_color", Color(0.8, 0.6, 0.2))
	hud.add_child(name_lbl)

	# Update bar when health changes
	if boss.has_signal("health_changed"):
		boss.health_changed.connect(func(hp, max_hp):
			if is_instance_valid(boss_bar) and max_hp > 0:
				boss_bar.value = (hp / max_hp) * 100.0
		)
```

### 5C. ch1_tutorial_knight.gd — Boss HP Bar Uses max_value=700 Instead of Boss's Actual HP

**Problem:** The boss HP bar is created with `max_value = 700` and `value = 700`, but the Tutorial Knight has `max_health = 250.0` (before scaling). After level scaling, the actual HP varies. The bar should sync to the boss's real HP.

**File:** `scripts/chapter1/ch1_tutorial_knight.gd`  
**Location:** `_build_ui()` (~line 400)

```gdscript
# OLD:
	boss_hp_bar.min_value = 0
	boss_hp_bar.max_value = 700
	boss_hp_bar.value = 700

# NEW:
	boss_hp_bar.min_value = 0
	boss_hp_bar.max_value = 100  # Will be synced via health_changed signal
	boss_hp_bar.value = 100
```

This is actually handled later by `_on_boss_health_changed()` which sets `boss_hp_bar.max_value = max_hp`, so the initial value of 700 will be corrected on first damage. But it means the bar shows full before any hit. Setting to 100 with percentage-based display is cleaner.

---

## 6. CROSS-CUTTING IMPROVEMENTS

### 6A. Boss HP Bars — All Bosses Should Show HP Bar Permanently

**Problem:** `enemy_base.gd` auto-hides HP bars for non-boss entities after 4s, and for bosses it explicitly skips the timer (`if not is_in_group("boss")`). But the boss HP bar built in `_setup_health_bar()` starts hidden (`_set_hp_bar_visible(false)`). Bosses should start with their bar visible.

**File:** `scripts/combat/enemy_base.gd`  
**Location:** `_setup_health_bar()` end (~line 1170)

```gdscript
# OLD:
	_set_hp_bar_visible(false)

# NEW:
	_set_hp_bar_visible(is_in_group("boss"))
```

### 6B. GameJuice.boss_phase_transition() — Missing SFX Fallback

**Problem:** `boss_phase_transition()` plays `SFXManager.play("boss_phase")` but if SFXManager doesn't have that sound registered, it fails silently. Most bosses don't call this function anyway (fixed above). But the function itself should have a fallback.

Already wrapped in `if has_node("/root/SFXManager")` — OK, silent failure is acceptable.

### 6C. Tween Cleanup — Potential Orphan Tweens on Boss Death

**Problem:** When a boss dies mid-attack, `await get_tree().create_timer()` calls may still be pending with tweens that reference freed nodes. The `_safe()` check handles most cases, but tweens created on child nodes (like `Sprite` modulate tweens) aren't killed on death.

**Recommendation:** Add to all boss `die()` functions:

```gdscript
# Kill all active tweens on the Sprite to prevent orphan animations
if has_node("Sprite"):
	var spr = get_node("Sprite")
	if spr.has_meta("flash_tween"):
		var ft = spr.get_meta("flash_tween")
		if ft and ft.is_valid():
			ft.kill()
```

---

## 7. DIFFICULTY CURVE ANALYSIS

| Boss | HP | Phase Thresholds | Damage | Recovery Window | Verdict |
|---|---|---|---|---|---|
| Tutorial Knight | 250 | 70/45/20/10% | 15 base | 0s (NONE) | **Needs recovery windows** (Fix 1B) |
| Clockwork Auto | 320 | 65/30% | 35 base | 0s between patterns | **Needs post-combo pause** |
| Data Wraith | 200 | 50% | 35 base | Natural (projectile gaps) | OK — ranged boss allows breathing |
| Admin Proxy | 500 | 75/45/20% | 50 base | 0s (NONE) | **Needs recovery windows** |

**Key Issue:** Tutorial Knight and Admin Proxy both have 0 forced recovery windows after attack combos. The Tutorial Knight can combo 2-3 attacks with near-zero gap. In Hollow Knight, every boss has a visible 0.5-1.5s rest after each attack pattern where they stand still. This is the #1 game feel issue.

---

## 8. MISSING FEATURES PRIORITY LIST

| Priority | Feature | Boss(es) | Status |
|---|---|---|---|
| **P0** | Recovery windows after combos | Tutorial Knight, Admin Proxy | Missing |
| **P0** | `GameJuice.boss_phase_transition()` calls | ALL 4 | Missing (only encounter scripts have partial juice) |
| **P0** | `GameJuice.boss_death_sequence()` calls | ALL 4 | Missing |
| **P1** | Attack telegraph calls (`GameJuice.on_enemy_telegraph`) | Clockwork, Data Wraith | Missing |
| **P1** | Data Wraith boss intro cinematic | Data Wraith | Missing |
| **P1** | Boss HP bar for Clock Tower encounter | Clockwork Auto | Missing |
| **P2** | Core exposure timer visual | Clockwork Auto | Missing |
| **P2** | /ban actually stuns player | Admin Proxy | Flavor text only |
| **P2** | Phase 4 Root Access prompt on boss | Tutorial Knight | Missing |
| **P2** | Sprite-level tween cleanup on death | ALL 4 | Partial |
| **P3** | Admin Proxy standalone intro | Admin Proxy | No fallback |
| **P3** | Boss HP bar starts visible | ALL (via enemy_base) | Starts hidden |

---

## Summary

The boss systems are mechanically complete but lack the **juice layer** that makes Hollow Knight-style combat feel impactful. The three highest-impact fixes are:

1. **Add recovery windows** after boss attack combos (Tutorial Knight, Admin Proxy)
2. **Call `GameJuice.boss_phase_transition()`** in all boss phase changes
3. **Call `GameJuice.boss_death_sequence()`** in all boss death functions

These three changes alone will dramatically improve the feel of every boss encounter. The code for these systems already exists in `game_juice.gd` — it just isn't being called by the bosses.
