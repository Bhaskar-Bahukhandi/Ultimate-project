extends Node
# Autoloaded as CombatFX — do not add class_name

## ==========================================================================
## COMBAT EFFECTS — Hitstop, Screen Shake, Damage Numbers, Camera Juice
## ==========================================================================
## Upgraded for Dead Cells / Prince of Persia: The Lost Crown level polish.
## Provides tiered hitstop, directional and trauma-based screen shake,
## dynamic camera zoom pulses, kill slowdown, and stylized damage numbers
## with pop-in, drift, and color grading.
## ==========================================================================

signal hitstop_requested(duration: float)
signal screen_shake_requested(intensity: float, duration: float)
signal kill_confirmed(position: Vector2)

func _play_sfx(sfx_name: String, variation: float = 0.0) -> void:
	if has_node("/root/SFXManager"):
		SFXManager.play(sfx_name, variation)

# ── Screen Shake State ─────────────────────────────────────────────────
var shake_intensity: float = 0.0
var shake_duration: float = 0.0
var shake_timer: float = 0.0
var original_camera_offset: Vector2 = Vector2.ZERO
var shake_direction: Vector2 = Vector2.ZERO  # Directional shake bias
var _noise_time: float = 0.0  # For perlin-like noise

# ── Camera Zoom Pulse State ────────────────────────────────────────────
var _zoom_tween: Tween = null
var _base_zoom: Vector2 = Vector2(1, 1)

# ── Hitstop State ──────────────────────────────────────────────────────
var is_hitstop_active: bool = false
var hitstop_timer: float = 0.0
var _hitstop_safety_timer: SceneTreeTimer = null

# ── Kill Tracking ──────────────────────────────────────────────────────
var _recent_kills: int = 0
var _kill_timer: float = 0.0
const MULTI_KILL_WINDOW: float = 1.5  # Seconds for multi-kill detection
const MULTI_KILL_THRESHOLDS = {
	2: {"text": "DOUBLE KILL", "color": Color(1.0, 0.7, 0.2)},
	3: {"text": "TRIPLE KILL", "color": Color(1.0, 0.4, 0.1)},
	4: {"text": "QUAD KILL", "color": Color(1.0, 0.1, 0.1)},
	5: {"text": "PENTAKILL", "color": Color(1.0, 0.85, 0.0)},
}

# ── Hitstop Tier Constants (Dead Cells / Lost Crown style) ─────────────
const HITSTOP_LIGHT = 0.04              # Light hit — barely noticeable
const HITSTOP_NORMAL = 0.07             # Standard melee hit
const HITSTOP_HEAVY = 0.12              # Heavy/finisher
const HITSTOP_PARRY = 0.15              # Perfect parry freeze
const HITSTOP_CRITICAL = 0.18           # Critical/charged attack
const HITSTOP_SPELL = 0.10              # Spell impact
const HITSTOP_COUNTER = 0.20            # Counter-hit (hitting during enemy attack)

# ── Damage Number Pool ────────────────────────────────────────────────
const DAMAGE_POOL_SIZE: int = 12
@warning_ignore("unused_private_class_variable")
var _damage_label_pool: Array[Label] = []  # Reserved for future damage number pooling
@warning_ignore("unused_private_class_variable")
var _pool_index: int = 0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

func _process(delta: float) -> void:
	# Handle hitstop — use unscaled time since Engine.time_scale = 0 during hitstop
	if is_hitstop_active:
		var real_delta = delta / max(Engine.time_scale, 0.001) if Engine.time_scale > 0.0 else (1.0 / 60.0)
		hitstop_timer -= real_delta
		if hitstop_timer <= 0:
			_end_hitstop()
		return  # Don't process other effects during hitstop

	# Handle screen shake with improved decay
	if shake_timer > 0:
		_noise_time += delta
		shake_timer -= delta
		_apply_shake()
		if shake_timer <= 0:
			_end_shake()

	# Multi-kill window tracking
	if _kill_timer > 0:
		_kill_timer -= delta
		if _kill_timer <= 0:
			_recent_kills = 0

# ==========================================================================
# HITSTOP — The #1 game-feel mechanic
# ==========================================================================

func apply_hitstop(duration: float = 0.1) -> void:
	## Freeze the game briefly for impact feel.
	if is_hitstop_active:
		# Stack: extend current hitstop slightly (caps at 0.25s)
		hitstop_timer = min(hitstop_timer + duration * 0.5, 0.25)
		# If new hit is heavier, deepen the freeze
		var new_scale = remap(duration, 0.03, 0.20, 0.08, 0.01)
		new_scale = clamp(new_scale, 0.01, 0.08)
		if new_scale < Engine.time_scale:
			Engine.time_scale = new_scale
		return

	# Don't hitstop if game is already paused
	if get_tree().paused:
		return

	is_hitstop_active = true
	hitstop_timer = duration
	# Variable intensity: heavier hits = slower time scale = more dramatic
	var scale = remap(duration, 0.03, 0.20, 0.08, 0.01)
	Engine.time_scale = clamp(scale, 0.01, 0.08)
	hitstop_requested.emit(duration)

	# Safety fallback: force-end hitstop after 0.5s real time
	if _hitstop_safety_timer and _hitstop_safety_timer.timeout.is_connected(_force_end_hitstop):
		_hitstop_safety_timer.timeout.disconnect(_force_end_hitstop)
	_hitstop_safety_timer = get_tree().create_timer(0.5, true, false, true)
	_hitstop_safety_timer.timeout.connect(_force_end_hitstop)

func _end_hitstop() -> void:
	is_hitstop_active = false
	if _hitstop_safety_timer and _hitstop_safety_timer.timeout.is_connected(_force_end_hitstop):
		_hitstop_safety_timer.timeout.disconnect(_force_end_hitstop)
	_hitstop_safety_timer = null
	# Smooth time scale recovery (Dead Cells does this)
	var tween = create_tween()
	tween.tween_method(_set_time_scale, Engine.time_scale, 1.0, 0.04)

func _set_time_scale(value: float) -> void:
	Engine.time_scale = value

func _force_end_hitstop() -> void:
	## Safety net: force-end hitstop if timer somehow fails.
	if is_hitstop_active:
		push_warning("[COMBAT FX] Force-ending hitstop (safety fallback)")
		is_hitstop_active = false
		Engine.time_scale = 1.0

# ==========================================================================
# SCREEN SHAKE — Omnidirectional & Directional with Perlin-like noise
# ==========================================================================

func apply_screen_shake(intensity: float = 10.0, duration: float = 0.3) -> void:
	## Shake the camera for impact feel. Routes to trauma system when available.
	## Respects GameManager.accessibility_settings.screen_shake_intensity.
	var shake_mult: float = 1.0
	if has_node("/root/GameManager"):
		shake_mult = GameManager.get_screen_shake_multiplier()
	if shake_mult <= 0.0:
		return  # Screen shake disabled
	intensity *= shake_mult
	# ── Prefer camera's trauma system for higher-quality noise-based shake ──
	var camera = get_viewport().get_camera_2d()
	if camera and camera.has_method("add_trauma"):
		# Convert intensity+duration to trauma amount (0-1 range)
		var trauma_amount = clampf(intensity / 80.0, 0.02, 0.5)
		camera.add_trauma(trauma_amount)
		screen_shake_requested.emit(intensity, duration)
		return

	# Fallback: legacy shake for cameras without trauma
	if shake_timer <= 0:
		if camera:
			original_camera_offset = camera.offset
		else:
			original_camera_offset = Vector2.ZERO

	# Allow stacking: use max of current and new intensity
	if shake_timer > 0:
		shake_intensity = max(shake_intensity, intensity)
		shake_duration = max(shake_duration, duration)
		shake_timer = max(shake_timer, duration)
	else:
		shake_intensity = intensity
		shake_duration = duration
		shake_timer = duration
	shake_direction = Vector2.ZERO
	screen_shake_requested.emit(intensity, duration)

func apply_directional_shake(intensity: float, duration: float, direction: Vector2) -> void:
	## Directional screen shake — biased towards hit direction (Dead Cells style).
	var shake_mult: float = 1.0
	if has_node("/root/GameManager"):
		shake_mult = GameManager.get_screen_shake_multiplier()
	if shake_mult <= 0.0:
		return
	intensity *= shake_mult
	if shake_timer <= 0:
		var camera = get_viewport().get_camera_2d()
		if camera:
			original_camera_offset = camera.offset
		else:
			original_camera_offset = Vector2.ZERO

	shake_intensity = max(shake_intensity, intensity)
	shake_duration = max(shake_duration, duration)
	shake_timer = max(shake_timer, duration)
	shake_direction = direction.normalized()
	screen_shake_requested.emit(intensity, duration)

func _apply_shake() -> void:
	var camera = get_viewport().get_camera_2d()
	if not camera:
		shake_timer = 0.0
		return

	# Improved shake: perlin-noise-like with directional bias
	var decay = shake_timer / max(shake_duration, 0.001)
	var current_intensity = shake_intensity * decay * decay  # Quadratic falloff

	var shake_offset: Vector2
	if shake_direction != Vector2.ZERO:
		# Directional: mostly along hit direction with perpendicular noise
		var phase = sin(_noise_time * 60.0) * 0.5 + 0.5
		var along = shake_direction * current_intensity * (0.7 + phase * 0.3)
		var perp = Vector2(-shake_direction.y, shake_direction.x) * sin(_noise_time * 45.0) * 0.3 * current_intensity
		shake_offset = along * (1.0 if int(shake_timer * 60) % 2 == 0 else -0.6) + perp
	else:
		# Omnidirectional with smooth noise-based variation
		shake_offset = Vector2(
			sin(_noise_time * 50.0 + 1.5) * current_intensity,
			cos(_noise_time * 55.0 + 3.0) * current_intensity
		)
		shake_offset += Vector2(
			randf_range(-1, 1) * current_intensity * 0.3,
			randf_range(-1, 1) * current_intensity * 0.3
		)

	camera.offset = original_camera_offset + shake_offset

func _end_shake() -> void:
	shake_timer = 0.0
	shake_intensity = 0.0
	_noise_time = 0.0
	var camera = get_viewport().get_camera_2d()
	if camera:
		# Smooth return to original offset
		var tw = create_tween()
		tw.tween_property(camera, "offset", original_camera_offset, 0.05).set_trans(Tween.TRANS_SINE)

# ==========================================================================
# DAMAGE NUMBERS — Stylized with pop-in, drift, and color grading
# ==========================================================================

func spawn_damage_number(damage: float, pos: Vector2, is_critical: bool = false) -> void:
	## Create a floating damage number at the given world position.
	var scene_root = get_tree().current_scene
	if not scene_root:
		return

	# Use VFXLibrary's enhanced damage number if available
	if has_node("/root/VFXLibrary"):
		VFXLibrary.spawn_damage_number(int(damage), pos, scene_root, is_critical)
		return

	# Fallback: built-in damage number
	var label = Label.new()
	label.text = str(int(damage))
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.z_index = 100

	var font_size = 24 if is_critical else 18
	label.add_theme_font_size_override("font_size", font_size)

	var color: Color
	if is_critical:
		color = Color(1.0, 0.2, 0.1)
		label.text = str(int(damage)) + "!"
	elif damage > 30:
		color = Color(1.0, 0.5, 0.1)
	elif damage > 15:
		color = Color(1.0, 0.8, 0.3)
	else:
		color = Color(1.0, 1.0, 1.0)
	label.add_theme_color_override("font_color", color)
	label.add_theme_constant_override("outline_size", 3)
	label.add_theme_color_override("font_outline_color", Color(0.0, 0.0, 0.0, 0.9))

	scene_root.add_child(label)
	label.global_position = pos + Vector2(randf_range(-12, 12), -20)

	# Pop-in scale
	label.pivot_offset = Vector2(20, 12)
	label.scale = Vector2(0.3, 0.3)
	var pop_tw = label.create_tween()
	pop_tw.tween_property(label, "scale", Vector2(1.15, 1.15), 0.08).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	pop_tw.tween_property(label, "scale", Vector2(1.0, 1.0), 0.06).set_trans(Tween.TRANS_SINE)

	if is_critical:
		pop_tw.kill()
		var crit_tw = label.create_tween()
		crit_tw.tween_property(label, "scale", Vector2(1.6, 1.6), 0.1).set_trans(Tween.TRANS_BACK)
		crit_tw.tween_property(label, "scale", Vector2(1.0, 1.0), 0.25).set_trans(Tween.TRANS_ELASTIC)

	# Float up with arc + smooth fade
	var tween = label.create_tween().set_parallel(true)
	var drift_x = randf_range(-20, 20)
	tween.tween_property(label, "position:y", label.position.y - 65, 0.85).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(label, "position:x", label.position.x + drift_x, 0.85).set_trans(Tween.TRANS_SINE)
	tween.tween_property(label, "modulate:a", 0.0, 0.5).set_delay(0.4).set_trans(Tween.TRANS_SINE)
	tween.chain().tween_callback(label.queue_free)

func spawn_status_text(text: String, pos: Vector2, color: Color = Color.WHITE, font_size: int = 16) -> void:
	## Spawn floating text for status effects (PARRY!, DODGE!, BLOCKED!, etc.).
	var scene_root = get_tree().current_scene
	if not scene_root:
		return

	var label = Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.z_index = 100
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.add_theme_constant_override("outline_size", 3)
	label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.85))
	scene_root.add_child(label)
	label.global_position = pos + Vector2(-30, -30)

	# Pop-in
	label.pivot_offset = Vector2(30, 10)
	label.scale = Vector2(0.2, 0.2)
	label.modulate.a = 0.0
	var tw = label.create_tween()
	tw.tween_property(label, "scale", Vector2(1.3, 1.3), 0.1).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(label, "modulate:a", 1.0, 0.06)
	tw.tween_property(label, "scale", Vector2(1.0, 1.0), 0.15).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	# Float up and fade
	tw.tween_property(label, "position:y", label.position.y - 50, 0.8).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(label, "modulate:a", 0.0, 0.5).set_delay(0.3)
	tw.chain().tween_callback(label.queue_free)

# ==========================================================================
# ALL-IN-ONE HIT EFFECTS — Tiered for Dead Cells / Lost Crown punch
# ==========================================================================

func apply_hit_effects(damage: float, hit_position: Vector2, is_heavy_hit: bool = false) -> void:
	## All-in-one hit feedback — tiered for maximum game feel.
	# Sound
	_play_sfx("heavy_hit" if is_heavy_hit else "sword_hit", 0.12)

	# Tiered hitstop based on hit severity
	var hitstop_duration: float
	if is_heavy_hit:
		hitstop_duration = HITSTOP_HEAVY
	elif damage > 40:
		hitstop_duration = HITSTOP_HEAVY
	elif damage > 20:
		hitstop_duration = HITSTOP_NORMAL
	else:
		hitstop_duration = HITSTOP_LIGHT
	apply_hitstop(hitstop_duration)

	# Screen shake scaled to damage
	var shake_power = clamp(damage * 0.5, 3.0, 25.0)
	if is_heavy_hit:
		shake_power *= 1.5
	apply_screen_shake(shake_power, 0.25)

	# Damage number with auto-critical styling
	spawn_damage_number(damage, hit_position, is_heavy_hit or damage > 30)

	# Zoom pulse on heavy hits
	if is_heavy_hit or damage > 35:
		apply_zoom_pulse(1.06, 0.2)

func apply_counter_hit_effects(damage: float, hit_position: Vector2) -> void:
	## Counter-hit: hitting enemy during their attack windup.
	_play_sfx("counter_hit")
	apply_hitstop(HITSTOP_COUNTER)
	apply_screen_shake(20.0, 0.3)
	apply_directional_shake(15.0, 0.2, Vector2.RIGHT)
	spawn_damage_number(damage * 1.5, hit_position, true)
	spawn_status_text("COUNTER!", hit_position + Vector2(0, -40), Color(1.0, 0.85, 0.0), 22)
	apply_zoom_pulse(1.08, 0.3)

func apply_parry_effects(hit_position: Vector2) -> void:
	## Parry-specific effects — bigger freeze, flash, stagger.
	_play_sfx("parry_perfect")
	apply_hitstop(HITSTOP_PARRY)
	apply_screen_shake(18.0, 0.3)
	spawn_status_text("PARRY!", hit_position + Vector2(0, -40), Color(0.3, 1.0, 0.5), 24)
	apply_zoom_pulse(1.08, 0.25)
	# Parry VFX
	var scene_root = get_tree().current_scene
	if scene_root and has_node("/root/VFXLibrary"):
		VFXLibrary.spawn("vfx_parry_flash", hit_position, scene_root)

func apply_perfect_dodge_effects(pos: Vector2) -> void:
	## Perfect dodge visual feedback.
	_play_sfx("dodge_perfect")
	apply_hitstop(HITSTOP_LIGHT)
	spawn_status_text("DODGE!", pos + Vector2(0, -40), Color(0.4, 0.8, 1.0), 20)

func apply_kill_effects(position: Vector2, _damage: float) -> void:
	## Extra-juicy feedback when killing an enemy — Dead Cells kill feel.
	_play_sfx("enemy_death", 0.1)
	apply_hitstop(HITSTOP_CRITICAL)
	apply_screen_shake(20.0, 0.35)
	apply_zoom_pulse(1.1, 0.3)
	kill_confirmed.emit(position)

	# Kill flash
	_spawn_kill_flash()

	# Multi-kill tracking
	_recent_kills += 1
	_kill_timer = MULTI_KILL_WINDOW
	_check_multi_kill(position)

	# VFX — prefer Kenney sprite VFX, fallback to VFXLibrary
	var scene_root = get_tree().current_scene
	if scene_root:
		# Kenney fire/smoke burst on kill
		if has_node("/root/AssetManager"):
			AssetManager.spawn_oneshot_vfx(scene_root, "fire", position, Vector2(48, 48), 14.0)
			AssetManager.spawn_oneshot_vfx(scene_root, "smoke", position + Vector2(0, -10), Vector2(56, 56), 10.0)
			# Scatter stars for collectible feel
			for i in range(3):
				var offset = Vector2(randf_range(-30, 30), randf_range(-40, -10))
				AssetManager.spawn_oneshot_vfx(scene_root, "star", position + offset, Vector2(20, 20), 8.0)
		if has_node("/root/VFXLibrary"):
			VFXLibrary.spawn("vfx_enemy_death", position, scene_root)

func apply_boss_kill_effects(position: Vector2) -> void:
	## Even more dramatic kill effects for bosses.
	_play_sfx("enemy_death_boss", 0.05)
	apply_hitstop(HITSTOP_COUNTER)
	apply_screen_shake(25.0, 0.6)
	apply_zoom_pulse(1.15, 0.5)
	_spawn_kill_flash()
	var scene_root = get_tree().current_scene
	if scene_root:
		# Kenney boss death VFX — big explosions + magic
		if has_node("/root/AssetManager"):
			for i in range(5):
				var offset = Vector2(randf_range(-50, 50), randf_range(-60, 20))
				var delay_t = float(i) * 0.08
				get_tree().create_timer(delay_t).timeout.connect(func():
					if is_inside_tree() and scene_root.is_inside_tree():
						AssetManager.spawn_oneshot_vfx(scene_root, "flame", position + offset, Vector2(72, 72), 12.0)
						AssetManager.spawn_oneshot_vfx(scene_root, "magic", position + offset * 0.5, Vector2(48, 48), 10.0)
				)
		if has_node("/root/VFXLibrary"):
			VFXLibrary.spawn("vfx_enemy_death_boss", position, scene_root)
			VFXLibrary.spawn("vfx_screen_shockwave", position, scene_root)
			VFXLibrary.spawn("vfx_flash_gold", Vector2.ZERO, scene_root)

func _spawn_kill_flash() -> void:
	## Full-screen flash overlay on enemy kill for extra impact.
	var scene_root = get_tree().current_scene
	if not scene_root:
		return
	if has_node("/root/VFXLibrary"):
		VFXLibrary.spawn("vfx_flash_white", Vector2.ZERO, scene_root)
		return
	# Fallback: manual flash
	var flash = ColorRect.new()
	flash.color = Color(1.0, 1.0, 0.85, 0.35)
	flash.set_anchors_preset(Control.PRESET_FULL_RECT)
	flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	flash.z_index = 90
	scene_root.add_child(flash)
	var tw = flash.create_tween()
	tw.tween_property(flash, "color:a", 0.0, 0.18).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.tween_callback(flash.queue_free)

func _check_multi_kill(position: Vector2) -> void:
	## Check for multi-kill announcements.
	if not MULTI_KILL_THRESHOLDS.has(_recent_kills):
		return
	var mk = MULTI_KILL_THRESHOLDS[_recent_kills]
	var scene_root = get_tree().current_scene
	if scene_root and has_node("/root/VFXLibrary"):
		VFXLibrary.spawn_announcement(mk["text"], position + Vector2(0, -100), scene_root, mk["color"], 26)
	_play_sfx("multi_kill")
	apply_screen_shake(15.0, 0.3)

func apply_last_kill_slowdown() -> void:
	## Dramatic slowdown when the last enemy in a wave dies — bullet-time finish.
	if get_tree().paused or is_hitstop_active:
		return
	Engine.time_scale = 0.12
	var timer = get_tree().create_timer(0.4, true, false, true)  # Uses real time
	timer.timeout.connect(_restore_time_scale)

func _restore_time_scale() -> void:
	## Smoothly restore time scale after last-kill slowdown.
	var tw = create_tween()
	tw.tween_method(_set_time_scale, Engine.time_scale, 1.0, 0.12)

# ==========================================================================
# DYNAMIC CAMERA — Zoom Pulses for Combat Impact
# ==========================================================================

func apply_zoom_pulse(zoom_factor: float = 1.06, duration: float = 0.25) -> void:
	## Brief zoom-in pulse for heavy hits/finishers — Dead Cells style.
	var cam = get_viewport().get_camera_2d()
	if not cam:
		return
	# Kill previous zoom tween to avoid stacking
	if _zoom_tween and _zoom_tween.is_valid():
		_zoom_tween.kill()
		cam.zoom = _base_zoom

	_base_zoom = cam.zoom
	var target_zoom = _base_zoom * zoom_factor

	_zoom_tween = cam.create_tween()
	# Quick zoom in, elastic zoom back out
	_zoom_tween.tween_property(cam, "zoom", target_zoom, duration * 0.25).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_zoom_tween.tween_property(cam, "zoom", _base_zoom, duration * 0.75).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)

func apply_kill_zoom() -> void:
	## Stronger zoom pulse on enemy kill.
	apply_zoom_pulse(1.1, 0.35)

func apply_subtle_zoom(zoom_factor: float = 1.03, duration: float = 1.0) -> void:
	## Very gentle zoom for atmospheric moments.
	var cam = get_viewport().get_camera_2d()
	if not cam:
		return
	if _zoom_tween and _zoom_tween.is_valid():
		_zoom_tween.kill()
		cam.zoom = _base_zoom
	_base_zoom = cam.zoom
	_zoom_tween = cam.create_tween()
	_zoom_tween.tween_property(cam, "zoom", _base_zoom * zoom_factor, duration * 0.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_zoom_tween.tween_property(cam, "zoom", _base_zoom, duration * 0.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

# ==========================================================================
# SPELL / ABILITY EFFECTS
# ==========================================================================

func apply_spell_effects(damage: float, pos: Vector2, spell_type: String = "generic") -> void:
	## Spell impact feedback with type-specific styling.
	apply_hitstop(HITSTOP_SPELL)
	apply_screen_shake(8.0, 0.2)
	spawn_damage_number(damage, pos, damage > 25)

	var scene_root = get_tree().current_scene
	if not scene_root or not has_node("/root/VFXLibrary"):
		return

	match spell_type:
		"fire":
			VFXLibrary.spawn("vfx_embers", pos, scene_root)
		"ice":
			VFXLibrary.spawn("vfx_spell_impact", pos, scene_root)
		"lightning":
			VFXLibrary.spawn("vfx_lightning_crackle", pos, scene_root)
		"corruption":
			VFXLibrary.spawn("vfx_corruption_burst", pos, scene_root)
		_:
			VFXLibrary.spawn("vfx_spell_impact", pos, scene_root)

func apply_heal_effects(amount: float, pos: Vector2) -> void:
	## Healing visual feedback.
	var scene_root = get_tree().current_scene
	if not scene_root:
		return

	# Green damage number (positive)
	spawn_status_text("+%d" % int(amount), pos, Color(0.3, 1.0, 0.5), 20)

	if has_node("/root/VFXLibrary"):
		VFXLibrary.spawn("vfx_heal_ring", pos, scene_root)
		VFXLibrary.spawn("vfx_heal_burst", pos, scene_root)

	_play_sfx("heal")
