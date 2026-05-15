extends Node

## ==========================================================================
## GAME JUICE — Unified visual feedback integration layer (Polished Edition)
## ==========================================================================
## Autoload that wires together CombatEffects, VFXLibrary, GlitchOverlay,
## SFXManager, and Camera to provide one-call game-feel functions.
##
## Usage:
##   GameJuice.on_player_land(player)
##   GameJuice.on_dash_start(player)
##   GameJuice.on_hit_connect(attacker, victim, damage, is_crit)
##   GameJuice.on_enemy_telegraph(enemy)
##   GameJuice.on_enemy_die(enemy)
##   GameJuice.on_parry(player)
##   GameJuice.on_heal(target)
##   GameJuice.flash_invincibility(sprite, duration)
##   GameJuice.spawn_afterimage(sprite)
##   GameJuice.screen_distortion_pulse(intensity, duration)
##   GameJuice.dramatic_zoom(duration, zoom_factor)
##   GameJuice.slowmo_moment(duration, time_scale)
##   GameJuice.boss_phase_transition()
##   GameJuice.reality_shatter_effect()
## ==========================================================================

signal combo_updated(count: int, multiplier: float)
signal combo_dropped
signal combo_milestone(milestone_name: String, count: int)

# ── Combo Tracking ────────────────────────────────────────────────────
var _combo_count: int = 0
var _combo_timer: float = 0.0
var _combo_decay: float = 3.0  # seconds before combo drops
var _combo_ui: CanvasLayer = null
var _combo_label: Label = null
var _combo_mult_label: Label = null
var _combo_tween: Tween = null
var _combo_tier_label: Label = null  # Style rank display
var _combo_timer_bar: ColorRect = null  # Visual decay indicator
var _combo_timer_bg: ColorRect = null
var _last_combo_milestone: int = 0  # Track last milestone for announcements

# ── Afterimage System ────────────────────────────────────────────────
var _afterimage_colors: Dictionary = {
	"dash": Color(0.3, 0.6, 1.0, 0.5),
	"attack": Color(1.0, 0.5, 0.2, 0.4),
	"parry": Color(0.3, 1.0, 0.5, 0.5),
	"spell": Color(0.6, 0.3, 1.0, 0.5),
}

# ── I-Frame Tracking ─────────────────────────────────────────────────
var _iframe_sprites: Dictionary = {}  # node_id -> {sprite, tween, timer}
var _pulse_tweens: Dictionary = {}  # control_instance_id -> Tween

# ── Hurt Overlay (reused) ────────────────────────────────────────────
var _hurt_overlay: ColorRect = null  # Pass 55 H-06: Reuse single overlay instead of spawning new per hit
var _hurt_tween: Tween = null

# ── Hit Streak Tracking ──────────────────────────────────────────────
var _hit_streak: int = 0  # Consecutive hits without taking damage
var _best_streak: int = 0
var _slowmo_active: bool = false
var _drop_tween: Tween
var _intro_tween: Tween

# ── Combo Tier Definitions ───────────────────────────────────────────
const COMBO_TIERS = [
	{"threshold": 3, "name": "SHARP", "color": Color(0.6, 1.0, 0.6)},
	{"threshold": 5, "name": "FIERCE", "color": Color(0.4, 0.8, 1.0)},
	{"threshold": 7, "name": "BRUTAL", "color": Color(0.9, 0.4, 1.0)},
	{"threshold": 10, "name": "DEVASTATING", "color": Color(1.0, 0.3, 0.3)},
	{"threshold": 15, "name": "UNSTOPPABLE", "color": Color(1.0, 0.5, 0.0)},
	{"threshold": 20, "name": "LEGENDARY", "color": Color(1.0, 0.85, 0.0)},
	{"threshold": 30, "name": "GODLIKE", "color": Color(1.0, 1.0, 1.0)},
]

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_combo_ui()

func _process(delta: float) -> void:
	# PERF: Skip when idle (no combo, no iframes, no slowmo, time_scale normal)
	if _combo_count == 0 and _iframe_sprites.is_empty() and not _slowmo_active and is_equal_approx(Engine.time_scale, 1.0):
		return
	# Fail-safe: restore time_scale if no slowmo is supposed to be active
	# BUT respect CombatFX hitstop — don't override their time_scale control
	if not _slowmo_active and not Engine.is_editor_hint() and Engine.time_scale != 1.0:
		if has_node("/root/CombatFX") and CombatFX.is_hitstop_active:
			pass  # CombatFX owns time_scale during hitstop
		else:
			Engine.time_scale = 1.0

	# Combo decay
	if _combo_count > 0:
		_combo_timer -= delta
		_update_combo_timer_bar()
		if _combo_timer <= 0:
			_drop_combo()

	# I-frame flash update (PERF: also clean up freed sprites)
	var to_remove: Array = []
	for id in _iframe_sprites:
		var data = _iframe_sprites[id]
		if not is_instance_valid(data["sprite"]):
			to_remove.append(id)
			continue
		data["timer"] -= delta
		if data["timer"] <= 0:
			_stop_iframe_flash(data)
			to_remove.append(id)
	for id in to_remove:
		_iframe_sprites.erase(id)

# ==========================================================================
# PUBLIC API — Combat Integration
# ==========================================================================

func on_hit_connect(attacker: Node, _victim: Node, damage: float, is_crit: bool = false) -> void:
	## Additive hit juice: combo increment + glitch flash on heavy hits + hit streak.
	## Also escalates screen shake per combo for Hollow Knight-style mounting pressure.
	# Chromatic pulse on heavy hits
	var is_heavy = is_crit or damage >= 30
	if is_heavy and has_node("/root/GlitchOverlay"):
		GlitchOverlay.flash_glitch(0.15)

	# Increment hit streak
	_hit_streak += 1
	if _hit_streak > _best_streak:
		_best_streak = _hit_streak

	# Combo
	_increment_combo()

	# BUG 13 FIX: Crits extend combo timer instead of double-incrementing
	if is_crit:
		_combo_timer = minf(_combo_timer + 0.5, _combo_decay + 2.0)

	# ── Combo-escalating screen shake (Hollow Knight nail hit feel) ──
	var combo_shake_bonus = clampf(_combo_count * 0.4, 0.0, 6.0)
	var base_shake = 4.0 + combo_shake_bonus
	if is_heavy:
		base_shake += 4.0
	var cam = _get_active_camera()
	if cam and cam.has_method("add_trauma"):
		var trauma_amount = remap(base_shake, 4.0, 14.0, 0.04, 0.12)
		cam.add_trauma(clampf(trauma_amount, 0.03, 0.15))

	# Milestone VFX announcements
	_check_combo_milestone(attacker)

func on_player_hurt(_player: Node2D, damage: float = 0.0) -> void:
	## Player took damage — resets hit streak, adds screen flash + edge warning.
	_hit_streak = 0
	screen_distortion_pulse(0.2, 0.15)

	# ── Red screen flash proportional to damage (Hollow Knight hit feedback) ──
	var flash_alpha = clampf(remap(damage, 5.0, 50.0, 0.12, 0.35), 0.1, 0.4)
	if has_node("/root/VFXLibrary"):
		var scene_root = get_tree().current_scene
		if scene_root:
			# Pass 55 H-06: Reuse a single overlay instead of creating per-hit
			if not is_instance_valid(_hurt_overlay):
				_hurt_overlay = ColorRect.new()
				_hurt_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
				_hurt_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
				_hurt_overlay.z_index = 92
				scene_root.add_child(_hurt_overlay)
			_hurt_overlay.color = Color(1.0, 0.1, 0.05, flash_alpha)
			if _hurt_tween and _hurt_tween.is_valid():
				_hurt_tween.kill()
			_hurt_tween = _hurt_overlay.create_tween()
			_hurt_tween.tween_property(_hurt_overlay, "color:a", 0.0, 0.22).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)

	# ── Camera trauma on hit (scales with damage) ──
	var cam = _get_active_camera()
	if cam and cam.has_method("add_trauma"):
		var hit_trauma = clampf(remap(damage, 5.0, 60.0, 0.08, 0.25), 0.06, 0.3)
		cam.add_trauma(hit_trauma)

	# ── Brief time wobble on heavy damage for impact weight ──
	if damage >= 25.0:
		_time_wobble(0.08)

func on_player_land(player: Node) -> void:
	var fall_speed = absf(player.velocity.y) if player else 400.0
	var trauma = remap(fall_speed, 200.0, 950.0, 0.02, 0.12)
	trauma = clampf(trauma, 0.02, 0.12)
	var cam = get_viewport().get_camera_2d()
	if cam and cam.has_method("add_trauma"):
		cam.add_trauma(trauma)

	# ── Scaled landing VFX: light dust at low speed, heavy puff at high ──
	var scene_root = get_tree().current_scene
	if scene_root and has_node("/root/VFXLibrary"):
		if fall_speed > 600.0:
			VFXLibrary.spawn("vfx_dust_puff_heavy", player.global_position + Vector2(0, 20), scene_root)
		elif fall_speed > 200.0:
			VFXLibrary.spawn("vfx_dust_puff", player.global_position + Vector2(0, 20), scene_root)

func on_dash_start(player: Node2D) -> void:
	## Additive dash juice: afterimage trail + directional camera nudge.
	# Spawn colored afterimage trail
	spawn_afterimage_trail(player, 4, 0.04, "dash")

	# Camera nudge in facing direction
	var dir = player.get("facing_direction") if player.get("facing_direction") != null else 1.0
	if has_node("/root/CombatFX"):
		CombatFX.apply_directional_shake(3.0, 0.1, Vector2(dir, 0))

func on_dash_end(player: Node) -> void:
	var cam = get_viewport().get_camera_2d()
	if cam and cam.has_method("add_trauma"):
		cam.add_trauma(0.02)
	if player and has_node("/root/VFXLibrary"):
		var scene_root = get_tree().current_scene
		if scene_root:
			VFXLibrary.spawn("vfx_dust_puff", player.global_position + Vector2(0, 20), scene_root)

func on_jump(_player: Node) -> void:
	var cam = get_viewport().get_camera_2d()
	if cam and cam.has_method("add_trauma"):
		cam.add_trauma(0.015)

func on_double_jump(player: Node2D) -> void:
	## Extra juice for double jump — sparkle trail + camera ripple.
	spawn_afterimage(player, Color(0.5, 0.8, 1.0, 0.4))
	var cam = _get_active_camera()
	if cam and cam.has_method("add_trauma"):
		cam.add_trauma(0.03)

func on_wall_jump(player: Node2D) -> void:
	## Wall jump juice — brief flash + directional nudge.
	var dir = player.get("facing_direction") if player.get("facing_direction") != null else 1.0
	if has_node("/root/CombatFX"):
		CombatFX.apply_directional_shake(4.0, 0.08, Vector2(dir, 0))

func on_enemy_die(_enemy: Node2D) -> void:
	## Additive enemy death juice: combo increment on kill.
	_increment_combo()  # BUG 13 FIX: Single increment on kill (was double)
	_hit_streak += 1   # Kill counts as streak continuation
	# Extend timer on kill as a bonus instead of extra combo counts
	_combo_timer = minf(_combo_timer + 1.0, _combo_decay + 2.0)

func on_enemy_telegraph(enemy: Node2D, attack_name: String = "") -> void:
	## Flash a warning indicator above the enemy with attack-specific styling.
	if not is_instance_valid(enemy):
		return

	var warn = Label.new()
	warn.text = "!"
	warn.add_theme_font_size_override("font_size", 28)
	warn.add_theme_constant_override("outline_size", 3)
	warn.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.8))
	warn.z_index = 10
	warn.mouse_filter = Control.MOUSE_FILTER_IGNORE

	# Color-code by attack type
	var warn_color = Color.RED
	match attack_name.to_lower():
		"charge", "rush", "lunge":
			warn_color = Color(1.0, 0.5, 0.0)
			warn.text = "!!"
		"heavy", "slam", "crush":
			warn_color = Color(1.0, 0.2, 0.0)
			warn.text = "!!!"
		"ranged", "projectile", "beam":
			warn_color = Color(1.0, 1.0, 0.0)
			warn.text = ">"
		"aoe", "area", "explosion":
			warn_color = Color(1.0, 0.0, 0.5)
			warn.text = "!!!"
		_:
			warn_color = Color.RED

	warn.add_theme_color_override("font_color", warn_color)
	warn.position = Vector2(-8, -55)
	enemy.add_child(warn)

	# Pop-in animation with bounce
	warn.scale = Vector2(0.2, 0.2)
	warn.modulate.a = 0.0
	warn.pivot_offset = Vector2(8, 14)
	var tw = warn.create_tween()
	tw.tween_property(warn, "scale", Vector2(1.6, 1.6), 0.08).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(warn, "modulate:a", 1.0, 0.06)
	tw.tween_property(warn, "scale", Vector2(1.0, 1.0), 0.12).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	tw.tween_interval(0.5)
	tw.tween_property(warn, "modulate:a", 0.0, 0.12)
	tw.tween_callback(warn.queue_free)

	if has_node("/root/SFXManager"):
		SFXManager.play("enemy_telegraph")

func on_parry(player: Node2D) -> void:
	## Additive parry juice: glitch flash + afterimage + screen impact.
	if has_node("/root/GlitchOverlay"):
		GlitchOverlay.flash_glitch(0.2)
	spawn_afterimage(player, _afterimage_colors["parry"])
	# Brief time wobble for dramatic parry feel
	_time_wobble(0.15)
	# Note: CombatFX.apply_parry_effects() handles screen shake + parry SFX.
	# Only add supplemental juice here (glitch flash, afterimage, time wobble).
	if player and has_node("/root/VFXLibrary"):
		var scene_root = get_tree().current_scene
		if scene_root:
			VFXLibrary.spawn("vfx_parry_flash", player.global_position + Vector2(0, -10), scene_root)

func on_heal(target: Node2D) -> void:
	## Additive heal juice: combo preservation + subtle glow.
	# Healing resets combo decay timer to be generous
	if _combo_count > 0:
		_combo_timer = _combo_decay
	# Visual feedback for heal completion
	var cam = get_viewport().get_camera_2d()
	if cam and cam.has_method("add_trauma"):
		cam.add_trauma(0.04)
	if target and has_node("/root/VFXLibrary"):
		var scene_root = get_tree().current_scene
		if scene_root:
			VFXLibrary.spawn("vfx_heal_ring", target.global_position, scene_root)
	dramatic_zoom(0.3, 1.03)

func on_spell_cast(player: Node2D, _spell_name: String = "") -> void:
	## Additive spell cast juice: afterimage + brief time dilation.
	spawn_afterimage(player, _afterimage_colors["spell"])
	_time_wobble(0.1)

func on_root_access_activate(target: Node2D) -> void:
	## Root Access hack visual.
	var pos = target.global_position
	var parent = target.get_parent()
	if parent and has_node("/root/VFXLibrary"):
		VFXLibrary.spawn("vfx_hack_circle", pos, parent)
		VFXLibrary.spawn("vfx_hack_beam", pos + Vector2(0, -40), parent)
	if has_node("/root/SFXManager"):
		SFXManager.play("hack_activate")
	screen_distortion_pulse(0.4, 0.3)

func on_pogo_bounce(player: Node2D, victim: Node2D, damage: float) -> void:
	## Hollow Knight-style pogo bounce: hitstop + directional shake + afterimage + VFX.
	## This is the most satisfying mechanic — nail hit pause is essential.
	# Hitstop (nail hit pause — the signature Hollow Knight feel)
	if has_node("/root/CombatFX"):
		CombatFX.apply_hitstop(CombatFX.HITSTOP_HEAVY)

	# Downward directional shake (player bouncing UP off enemy)
	var cam = _get_active_camera()
	if cam and cam.has_method("add_trauma"):
		cam.add_trauma(0.1)

	# Afterimage at bounce point
	spawn_afterimage(player, Color(1.0, 0.85, 0.3, 0.5))

	# Brief time wobble for weighty impact
	_time_wobble(0.06)

	# VFX: downward impact spark + bounce ring
	if victim and is_instance_valid(victim) and has_node("/root/VFXLibrary"):
		var scene_root = get_tree().current_scene
		if scene_root:
			VFXLibrary.spawn("vfx_hit_spark", victim.global_position + Vector2(0, -10), scene_root)
			VFXLibrary.spawn("vfx_dust_puff", victim.global_position + Vector2(0, -5), scene_root)

	# Combo increment
	_increment_combo()
	if damage >= 30:
		_increment_combo()

	# SFX
	if has_node("/root/SFXManager"):
		SFXManager.play("pogo_bounce")

func on_pickup(_player: Node2D, _item_type: String = "gold") -> void:
	## Additive pickup juice: brief sparkle + satisfying pop.
	# Pass 53: Add pickup SFX based on type
	if has_node("/root/SFXManager"):
		if _item_type == "gold":
			SFXManager.play("gold_pickup")
		else:
			SFXManager.play("item_pickup")
	var cam = _get_active_camera()
	if cam and cam.has_method("add_trauma"):
		cam.add_trauma(0.02)

func on_checkpoint_reached(player: Node2D) -> void:
	## Checkpoint reached — brief glow + combo timer refresh.
	# Pass 53: Play save point SFX
	if has_node("/root/SFXManager"):
		SFXManager.play("save_point")
	if _combo_count > 0:
		_combo_timer = _combo_decay + 2.0  # Generous extension at checkpoints
	if has_node("/root/VFXLibrary"):
		VFXLibrary.spawn("vfx_glitch_sparkle", player.global_position + Vector2(0, -30), player.get_parent())

# ==========================================================================
# AFTERIMAGE SYSTEM
# ==========================================================================

func spawn_afterimage(source: Node2D, color: Color = Color(0.4, 0.6, 1.0, 0.5)) -> void:
	## Spawn a single ghost afterimage at the source's position.
	var sprite = _get_sprite(source)
	if not sprite:
		return

	var ghost = ColorRect.new()
	ghost.size = sprite.size if sprite is ColorRect else Vector2(32, 48)
	ghost.color = color
	ghost.global_position = source.global_position - ghost.size / 2.0
	ghost.z_index = source.z_index - 1
	ghost.modulate.a = color.a
	ghost.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var parent = source.get_parent()
	if parent:
		parent.add_child(ghost)
		var tw = parent.create_tween().set_parallel(true)
		tw.tween_property(ghost, "modulate:a", 0.0, 0.35).set_trans(Tween.TRANS_SINE)
		tw.tween_property(ghost, "scale", Vector2(1.1, 0.9), 0.35).set_trans(Tween.TRANS_SINE)
		tw.chain().tween_callback(ghost.queue_free)

func spawn_afterimage_trail(source: Node2D, count: int = 4, interval: float = 0.04, style: String = "dash") -> void:
	## Spawn a trail of afterimages over time with color gradient.
	var base_color = _afterimage_colors.get(style, Color(0.4, 0.6, 1.0, 0.5))
	for i in range(count):
		if not is_instance_valid(source) or not source.is_inside_tree():
			break
		# Gradient: each successive image is more transparent and slightly different hue
		var t = float(i) / max(count - 1, 1)
		var alpha = base_color.a * (1.0 - t * 0.6)
		var hue_shift = t * 0.08
		var trail_color = Color(
			clamp(base_color.r + hue_shift, 0, 1),
			clamp(base_color.g - hue_shift * 0.5, 0, 1),
			base_color.b,
			max(alpha, 0.08)
		)
		spawn_afterimage(source, trail_color)
		if i < count - 1:
			await get_tree().create_timer(interval).timeout
			if not is_inside_tree(): return

# ==========================================================================
# I-FRAME FLASH
# ==========================================================================

func flash_invincibility(sprite: Node, duration: float = 1.0) -> void:
	## Make a sprite blink rapidly during invincibility frames with sine-wave.
	if not is_instance_valid(sprite):
		return

	var id = sprite.get_instance_id()
	# Cancel existing flash
	if id in _iframe_sprites:
		_stop_iframe_flash(_iframe_sprites[id])
		_iframe_sprites.erase(id)

	var tw = create_tween()
	tw.set_loops(int(duration / 0.1))
	tw.tween_property(sprite, "modulate:a", 0.15, 0.05)
	tw.tween_property(sprite, "modulate:a", 1.0, 0.05)

	_iframe_sprites[id] = {"sprite": sprite, "tween": tw, "timer": duration}

func _stop_iframe_flash(data: Dictionary) -> void:
	if data["tween"] and data["tween"].is_valid():
		data["tween"].kill()
	if is_instance_valid(data["sprite"]):
		data["sprite"].modulate.a = 1.0

# ==========================================================================
# COMBO SYSTEM
# ==========================================================================

func _increment_combo() -> void:
	_combo_count += 1
	_combo_timer = _combo_decay
	var mult = get_combo_multiplier()
	_update_combo_ui()
	combo_updated.emit(_combo_count, mult)

func _drop_combo() -> void:
	if _combo_count > 0:
		var was_count = _combo_count
		_combo_count = 0
		_combo_timer = 0.0
		_last_combo_milestone = 0
		combo_dropped.emit()
		_update_combo_ui()

		# Dramatic drop effect for big combos
		if was_count >= 10 and _combo_label:
			_combo_label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
			if _drop_tween and _drop_tween.is_valid():
				_drop_tween.kill()
			_drop_tween = create_tween()
			_drop_tween.tween_property(_combo_label, "modulate:a", 0.0, 0.4).set_trans(Tween.TRANS_QUAD)

func get_combo_count() -> int:
	return _combo_count

func get_combo_multiplier() -> float:
	if _combo_count < 3:
		return 1.0
	elif _combo_count < 6:
		return 1.25
	elif _combo_count < 10:
		return 1.5
	elif _combo_count < 15:
		return 1.75
	elif _combo_count < 20:
		return 2.0
	elif _combo_count < 30:
		return 2.25
	else:
		return 2.5

func reset_combo() -> void:
	_combo_count = 0
	_combo_timer = 0.0
	_last_combo_milestone = 0
	_update_combo_ui()

func _get_combo_tier() -> Dictionary:
	## Get the current combo tier based on count.
	var current_tier = {}
	for tier in COMBO_TIERS:
		if _combo_count >= tier["threshold"]:
			current_tier = tier
	return current_tier

func _check_combo_milestone(source: Node) -> void:
	## Check if we've crossed a combo milestone and announce it.
	for tier in COMBO_TIERS:
		if _combo_count >= tier["threshold"] and _last_combo_milestone < tier["threshold"]:
			_last_combo_milestone = tier["threshold"]
			combo_milestone.emit(tier["name"], _combo_count)
			# Pass 53: Play combo milestone SFX
			if has_node("/root/SFXManager"):
				SFXManager.play("combo_milestone")
			# Tiered milestone celebration
			if tier["threshold"] >= 30:
				screen_distortion_pulse(0.3, 0.3)
				slowmo_moment(0.3, 0.4)
			elif tier["threshold"] >= 20:
				slowmo_moment(0.3, 0.5)
				dramatic_zoom(0.3, 1.08)
			elif tier["threshold"] >= 10:
				dramatic_zoom(0.3, 1.08)
			# Spawn announcement VFX
			if is_instance_valid(source) and source is Node2D:
				var parent = source.get_parent()
				if parent and has_node("/root/VFXLibrary"):
					VFXLibrary.spawn_announcement(
						tier["name"] + "!",
						source.global_position + Vector2(0, -80),
						parent,
						tier["color"],
						20
					)
			break

func _build_combo_ui() -> void:
	_combo_ui = CanvasLayer.new()
	_combo_ui.layer = 95
	_combo_ui.name = "ComboUILayer"
	add_child(_combo_ui)

	# Combo count label
	_combo_label = Label.new()
	_combo_label.name = "ComboCount"
	_combo_label.text = ""
	_combo_label.add_theme_font_size_override("font_size", 32)
	_combo_label.add_theme_color_override("font_color", Color(1, 0.85, 0.2))
	_combo_label.add_theme_constant_override("outline_size", 3)
	_combo_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.85))
	_combo_label.position = Vector2(20, 100)
	_combo_label.modulate.a = 0.0
	_combo_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_combo_ui.add_child(_combo_label)

	# Combo multiplier label
	_combo_mult_label = Label.new()
	_combo_mult_label.name = "ComboMult"
	_combo_mult_label.text = ""
	_combo_mult_label.add_theme_font_size_override("font_size", 18)
	_combo_mult_label.add_theme_color_override("font_color", Color(1, 0.6, 0.2))
	_combo_mult_label.add_theme_constant_override("outline_size", 2)
	_combo_mult_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.7))
	_combo_mult_label.position = Vector2(20, 140)
	_combo_mult_label.modulate.a = 0.0
	_combo_mult_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_combo_ui.add_child(_combo_mult_label)

	# Combo tier label (FIERCE, BRUTAL, etc.)
	_combo_tier_label = Label.new()
	_combo_tier_label.name = "ComboTier"
	_combo_tier_label.text = ""
	_combo_tier_label.add_theme_font_size_override("font_size", 14)
	_combo_tier_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
	_combo_tier_label.add_theme_constant_override("outline_size", 2)
	_combo_tier_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.7))
	_combo_tier_label.position = Vector2(20, 162)
	_combo_tier_label.modulate.a = 0.0
	_combo_tier_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_combo_ui.add_child(_combo_tier_label)

	# Combo timer bar (visual decay indicator)
	_combo_timer_bg = ColorRect.new()
	_combo_timer_bg.color = Color(0.15, 0.15, 0.15, 0.5)
	_combo_timer_bg.size = Vector2(120, 4)
	_combo_timer_bg.position = Vector2(20, 184)
	_combo_timer_bg.modulate.a = 0.0
	_combo_timer_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_combo_ui.add_child(_combo_timer_bg)

	_combo_timer_bar = ColorRect.new()
	_combo_timer_bar.color = Color(1, 0.85, 0.2, 0.8)
	_combo_timer_bar.size = Vector2(120, 4)
	_combo_timer_bar.position = Vector2(20, 184)
	_combo_timer_bar.modulate.a = 0.0
	_combo_timer_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_combo_ui.add_child(_combo_timer_bar)

func _update_combo_ui() -> void:
	if _combo_count < 2:
		# Hide combo UI with fade
		if _combo_label:
			_combo_label.modulate.a = 0.0
		if _combo_mult_label:
			_combo_mult_label.modulate.a = 0.0
		if _combo_tier_label:
			_combo_tier_label.modulate.a = 0.0
		if _combo_timer_bar:
			_combo_timer_bar.modulate.a = 0.0
		if _combo_timer_bg:
			_combo_timer_bg.modulate.a = 0.0
		return

	if _combo_label:
		_combo_label.text = "%d HIT" % _combo_count if _combo_count < 10 else "%d HITS!" % _combo_count
		_combo_label.modulate.a = 1.0

		# Pop effect
		_combo_label.pivot_offset = Vector2(_combo_label.size.x * 0.5, _combo_label.size.y * 0.5)
		_combo_label.scale = Vector2(1.35, 1.35)
		if _combo_tween and _combo_tween.is_valid():
			_combo_tween.kill()
		_combo_tween = create_tween()
		_combo_tween.tween_property(_combo_label, "scale", Vector2(1.0, 1.0), 0.18).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)

		# Color escalation
		var tier = _get_combo_tier()
		if tier.size() > 0:
			_combo_label.add_theme_color_override("font_color", tier["color"])
		elif _combo_count >= 6:
			_combo_label.add_theme_color_override("font_color", Color(1, 0.7, 0.1))
		else:
			_combo_label.add_theme_color_override("font_color", Color(1, 0.85, 0.2))

	if _combo_mult_label:
		var mult = get_combo_multiplier()
		if mult > 1.0:
			_combo_mult_label.text = "x%.2f DMG" % mult
			_combo_mult_label.modulate.a = 1.0
			# Color matches combo tier
			if mult >= 2.0:
				_combo_mult_label.add_theme_color_override("font_color", Color(1.0, 0.3, 0.1))
			elif mult >= 1.5:
				_combo_mult_label.add_theme_color_override("font_color", Color(1.0, 0.5, 0.1))
			else:
				_combo_mult_label.add_theme_color_override("font_color", Color(1.0, 0.7, 0.2))
		else:
			_combo_mult_label.modulate.a = 0.0

	# Tier label
	if _combo_tier_label:
		var tier = _get_combo_tier()
		if tier.size() > 0:
			_combo_tier_label.text = tier["name"]
			_combo_tier_label.add_theme_color_override("font_color", tier["color"])
			_combo_tier_label.modulate.a = 1.0
		else:
			_combo_tier_label.modulate.a = 0.0

	# Show timer bar
	if _combo_timer_bg:
		_combo_timer_bg.modulate.a = 0.6
	if _combo_timer_bar:
		_combo_timer_bar.modulate.a = 1.0

func _update_combo_timer_bar() -> void:
	## Update the visual combo decay bar.
	if not _combo_timer_bar or _combo_count < 2:
		return
	var pct = clamp(_combo_timer / _combo_decay, 0.0, 1.0)
	_combo_timer_bar.size.x = 120.0 * pct

	# Color shifts from green to yellow to red as time runs out
	if pct > 0.5:
		_combo_timer_bar.color = Color(1.0 - (pct - 0.5) * 2.0, 1.0, 0.2, 0.8)
	else:
		_combo_timer_bar.color = Color(1.0, pct * 2.0, 0.1, 0.8)

# ==========================================================================
# SCREEN EFFECTS
# ==========================================================================

func screen_distortion_pulse(_intensity: float = 0.3, duration: float = 0.2) -> void:
	## Brief screen-wide corruption pulse for heavy impacts.
	if has_node("/root/GameManager") and GameManager.is_reduced_motion():
		return  # Pass 57: Skip non-essential VFX
	if has_node("/root/GlitchOverlay"):
		GlitchOverlay.flash_glitch(duration)

func dramatic_zoom(duration: float = 0.4, zoom_factor: float = 1.15) -> void:
	## Brief dramatic camera zoom for boss transitions, critical hits.
	if has_node("/root/GameManager") and GameManager.is_reduced_motion():
		return  # Pass 57: Skip non-essential VFX
	if has_node("/root/CombatFX"):
		CombatFX.apply_zoom_pulse(zoom_factor, duration)

func slowmo_moment(duration: float = 0.5, time_scale: float = 0.3) -> void:
	## Brief slow-motion moment for dramatic kills, phase transitions.
	if has_node("/root/GameManager") and GameManager.is_reduced_motion():
		return  # Pass 57: Skip time manipulation effects
	_slowmo_active = true
	Engine.time_scale = time_scale
	await get_tree().create_timer(duration * time_scale).timeout
	if not is_inside_tree():
		Engine.time_scale = 1.0
		_slowmo_active = false
		return
	# Smooth recovery instead of instant snap
	var tw = create_tween()
	if tw:
		tw.tween_method(_set_time_scale, time_scale, 1.0, 0.08)
		await tw.finished
	else:
		Engine.time_scale = 1.0
	_slowmo_active = false

func _set_time_scale(value: float) -> void:
	Engine.time_scale = value

var _owns_time_wobble: bool = false

func _time_wobble(duration: float = 0.1) -> void:
	## Ultra-brief time dilation wobble for micro-impacts (parry, spell cast).
	if _slowmo_active or Engine.time_scale < 0.6:
		return  # Don't override a deeper slowmo
	Engine.time_scale = 0.6
	_owns_time_wobble = true
	await get_tree().create_timer(duration * 0.6).timeout
	if not is_inside_tree():
		Engine.time_scale = 1.0
		_owns_time_wobble = false
		return
	if _owns_time_wobble:  # Only restore if we still own it
		Engine.time_scale = 1.0
		_owns_time_wobble = false

func boss_phase_transition() -> void:
	## Full boss phase transition juice: freeze + shake + flash + slowmo.
	if has_node("/root/CombatFX"):
		CombatFX.apply_hitstop(0.3)
	await get_tree().create_timer(0.32, true, false, true).timeout
	if not is_inside_tree(): return
	if has_node("/root/CombatFX"):
		CombatFX.apply_screen_shake(12.0, 0.5)
	if has_node("/root/SFXManager"):
		SFXManager.play("boss_phase")
	screen_distortion_pulse(0.5, 0.4)
	dramatic_zoom(0.6, 1.2)
	# VFX burst
	var scene_root = get_tree().current_scene
	if scene_root and has_node("/root/VFXLibrary"):
		VFXLibrary.spawn("vfx_screen_shockwave", Vector2(640, 360), scene_root)

func boss_intro_zoom(_boss_node: Node2D) -> void:
	## Cinematic camera pull toward boss during intro.
	var cam = get_viewport().get_camera_2d()
	if cam:
		var original_zoom = cam.zoom
		if _intro_tween and _intro_tween.is_valid():
			_intro_tween.kill()
		_intro_tween = create_tween()
		_intro_tween.tween_property(cam, "zoom", original_zoom * 1.15, 1.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		_intro_tween.tween_interval(2.0)
		_intro_tween.tween_property(cam, "zoom", original_zoom, 0.6).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	# Subtle slowmo during intro
	_slowmo_active = true
	Engine.time_scale = 0.8
	await get_tree().create_timer(3.0, true, false, true).timeout
	if not is_inside_tree():
		Engine.time_scale = 1.0
		_slowmo_active = false
		return
	Engine.time_scale = 1.0
	_slowmo_active = false

func boss_death_sequence() -> void:
	## Full boss death sequence: slowmo + screen effects + shatter.
	# Pass 53: Add boss death SFX
	if has_node("/root/SFXManager"):
		SFXManager.play("enemy_death_boss")
	if has_node("/root/CombatFX"):
		CombatFX.apply_hitstop(0.25)
	await get_tree().create_timer(0.28, true, false, true).timeout
	if not is_inside_tree(): return
	_slowmo_active = true
	Engine.time_scale = 0.15
	if has_node("/root/CombatFX"):
		CombatFX.apply_screen_shake(20.0, 0.8)
	dramatic_zoom(0.5, 1.12)
	if has_node("/root/GlitchOverlay"):
		GlitchOverlay.flash_glitch(0.6)
	var scene_root = get_tree().current_scene
	if scene_root and has_node("/root/VFXLibrary"):
		VFXLibrary.spawn("vfx_screen_shockwave", Vector2(640, 360), scene_root)
		VFXLibrary.spawn("vfx_flash_gold", Vector2.ZERO, scene_root)
	await get_tree().create_timer(0.5, true, false, true).timeout
	if not is_inside_tree():
		Engine.time_scale = 1.0
		_slowmo_active = false
		return
	# Smooth time restore
	var tw = create_tween()
	if tw:
		tw.tween_method(_set_time_scale, 0.15, 1.0, 0.3)
		await tw.finished
	else:
		Engine.time_scale = 1.0
	_slowmo_active = false

func reality_shatter_effect() -> void:
	## Full reality shattering effect for chapter endings, major story beats.
	if has_node("/root/CombatFX"):
		CombatFX.apply_screen_shake(15.0, 1.0)
	screen_distortion_pulse(0.8, 1.0)
	if has_node("/root/SFXManager"):
		SFXManager.play("reality_shatter")
	await get_tree().create_timer(0.3).timeout
	if not is_inside_tree(): return
	dramatic_zoom(0.8, 1.3)
	# Shatter VFX
	var scene_root = get_tree().current_scene
	if scene_root and has_node("/root/VFXLibrary"):
		VFXLibrary.spawn("vfx_shatter", Vector2(640, 360), scene_root)
		VFXLibrary.spawn("vfx_screen_shockwave", Vector2(640, 360), scene_root)
	await get_tree().create_timer(0.5).timeout
	if not is_inside_tree():
		Engine.time_scale = 1.0
		return
	_slowmo_active = true
	Engine.time_scale = 0.2
	await get_tree().create_timer(0.4).timeout
	if not is_inside_tree():
		Engine.time_scale = 1.0
		_slowmo_active = false
		return
	Engine.time_scale = 1.0
	_slowmo_active = false

func chapter_end_sequence() -> void:
	## Dramatic chapter ending sequence.
	# Pass 53: Add transition SFX for chapter end
	if has_node("/root/SFXManager"):
		SFXManager.play("transition_glitch")
	if has_node("/root/CombatFX"):
		CombatFX.apply_screen_shake(10.0, 1.5)
	screen_distortion_pulse(1.0, 1.5)
	await get_tree().create_timer(0.5).timeout
	if not is_inside_tree(): return
	var scene_root = get_tree().current_scene
	if scene_root and has_node("/root/VFXLibrary"):
		VFXLibrary.spawn("vfx_flash_white", Vector2.ZERO, scene_root)
	await slowmo_moment(1.0, 0.3)

# ==========================================================================
# UI JUICE
# ==========================================================================

func button_press_pop(button: Control) -> void:
	## Squash-pop animation on button press.
	if not is_instance_valid(button):
		return
	button.pivot_offset = button.size / 2.0
	button.scale = Vector2(0.88, 1.12)
	var tw = button.create_tween()
	tw.tween_property(button, "scale", Vector2(1.06, 0.94), 0.07).set_trans(Tween.TRANS_SINE)
	tw.tween_property(button, "scale", Vector2(1.0, 1.0), 0.12).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)

func ui_shake(control: Control, intensity: float = 4.0, duration: float = 0.3) -> void:
	## Shake a UI element for error feedback, damage taken, etc.
	if not is_instance_valid(control):
		return
	var original_pos = control.position
	var tw = control.create_tween()
	var steps = int(duration / 0.04)
	for i in range(steps):
		var decay = 1.0 - float(i) / steps
		var offset = Vector2(
			randf_range(-intensity, intensity) * decay,
			randf_range(-intensity, intensity) * decay
		)
		tw.tween_property(control, "position", original_pos + offset, 0.04)
	tw.tween_property(control, "position", original_pos, 0.04)

func ui_pop_in(control: Control, duration: float = 0.3) -> void:
	## Pop-in animation for UI elements appearing.
	if not is_instance_valid(control):
		return
	control.pivot_offset = control.size / 2.0
	control.scale = Vector2(0.1, 0.1)
	control.modulate.a = 0.0
	var tw = control.create_tween().set_parallel(true)
	tw.tween_property(control, "scale", Vector2(1.05, 1.05), duration * 0.7).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(control, "modulate:a", 1.0, duration * 0.5)
	tw.chain().tween_property(control, "scale", Vector2(1.0, 1.0), duration * 0.3).set_trans(Tween.TRANS_SINE)

func ui_slide_in(control: Control, from_direction: Vector2 = Vector2.DOWN, distance: float = 40.0, duration: float = 0.3) -> void:
	## Slide-in animation for UI elements.
	if not is_instance_valid(control):
		return
	var target_pos = control.position
	control.position = target_pos + from_direction * distance
	control.modulate.a = 0.0
	var tw = control.create_tween().set_parallel(true)
	tw.tween_property(control, "position", target_pos, duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(control, "modulate:a", 1.0, duration * 0.6)

func ui_pulse(control: Control, scale_amount: float = 1.1, duration: float = 0.5) -> void:
	## Continuous pulse animation for attention-drawing UI elements.
	if not is_instance_valid(control):
		return
	# Kill previous pulse on the same control to prevent competing tweens
	var cid = control.get_instance_id()
	if cid in _pulse_tweens:
		var old = _pulse_tweens[cid]
		if old and old.is_valid():
			old.kill()
	control.pivot_offset = control.size / 2.0
	var tw = control.create_tween().set_loops()
	tw.tween_property(control, "scale", Vector2(scale_amount, scale_amount), duration * 0.5).set_trans(Tween.TRANS_SINE)
	tw.tween_property(control, "scale", Vector2(1.0, 1.0), duration * 0.5).set_trans(Tween.TRANS_SINE)
	_pulse_tweens[cid] = tw

# ==========================================================================
# ENVIRONMENTAL REACTIONS
# ==========================================================================

func on_room_enter(_room_name: String = "") -> void:
	## Subtle juice when entering a new area.
	var cam = _get_active_camera()
	if cam and cam.has_method("add_trauma"):
		cam.add_trauma(0.02)

func on_secret_found(position: Vector2, parent: Node) -> void:
	## Juice for discovering a secret area / hidden item.
	# Pass 53: Play dedicated secret_found SFX
	if has_node("/root/SFXManager"):
		SFXManager.play("secret_found")
	if has_node("/root/VFXLibrary"):
		VFXLibrary.spawn("vfx_glitch_sparkle", position, parent)
		VFXLibrary.spawn("vfx_flash_gold", Vector2.ZERO, parent)
		VFXLibrary.spawn_announcement("SECRET FOUND", position + Vector2(0, -60), parent, Color(1.0, 0.85, 0.2))
	if has_node("/root/CombatFX"):
		CombatFX.apply_screen_shake(5.0, 0.2)

func on_achievement_unlocked(achievement_name: String) -> void:
	## Juice for achievement unlocks.
	# Pass 53: Play achievement unlock SFX
	if has_node("/root/SFXManager"):
		SFXManager.play("achievement_unlock")
	var scene_root = get_tree().current_scene
	if scene_root and has_node("/root/VFXLibrary"):
		VFXLibrary.spawn("vfx_flash_gold", Vector2.ZERO, scene_root)
		VFXLibrary.spawn_announcement(achievement_name, Vector2(640, 200), scene_root, Color(1.0, 0.85, 0.0), 22)

# ==========================================================================
# HELPERS
# ==========================================================================

func _get_sprite(node: Node) -> Node:
	## Find a Sprite2D, ColorRect, or TextureRect child to animate.
	if node is Sprite2D or node is ColorRect or node is TextureRect:
		return node
	for name_hint in ["Sprite", "Sprite2D", "Body", "Visual"]:
		var child = node.get_node_or_null(name_hint)
		if child:
			return child
	# Fallback: first visual child
	for child in node.get_children():
		if child is Sprite2D or child is ColorRect or child is TextureRect:
			return child
	return null

func _get_active_camera() -> Node:
	## Find the active camera in the scene tree.
	var viewport = get_viewport()
	if viewport:
		return viewport.get_camera_2d()
	return null

func get_hit_streak() -> int:
	return _hit_streak

func get_best_streak() -> int:
	return _best_streak
