extends Camera2D
class_name CinematicCamera

## Professional camera system for cutscenes and dynamic gameplay
## Enhanced: follow mode, dead zone, bounds, responsive letterbox

signal camera_move_finished
signal shake_finished
signal zoom_finished

@export var smooth_enabled: bool = true
@export var smooth_speed: float = 5.0

var target_position: Vector2
var target_zoom: Vector2 = Vector2.ONE
var is_moving: bool = false
var is_shaking: bool = false
var is_zooming: bool = false

var shake_intensity: float = 0.0
var shake_decay: float = 5.0
var original_offset: Vector2

# Letterbox bars for cinematic mode
var _letterbox_top: ColorRect
var _letterbox_bottom: ColorRect
var _letterbox_layer: CanvasLayer
var _letterbox_active: bool = false

# Trauma-based shake (modern approach)
var _trauma: float = 0.0
var _trauma_decay: float = 1.5
const MAX_SHAKE_OFFSET: float = 24.0
const MAX_SHAKE_ROTATION: float = 2.0

# ─── FOLLOW MODE ─────────────────────────────────────────────────────
var _follow_target: Node2D = null
var _follow_offset: Vector2 = Vector2.ZERO
var _follow_speed: float = 5.0
var _follow_dead_zone: Vector2 = Vector2(32, 24)  # Pixels of wiggle before camera moves
# ─── LOOK-AHEAD (predicts player movement for responsive camera) ──────
var _look_ahead_enabled: bool = true
var _look_ahead_strength: float = 60.0  # Max pixels to look ahead
var _look_ahead_speed: float = 3.0      # Smoothing speed
var _current_look_ahead: Vector2 = Vector2.ZERO
# ─── BOUNDS ──────────────────────────────────────────────────────────
var _bounds_enabled: bool = false
var _bounds_rect: Rect2 = Rect2()  # World-space camera limits

# ─── MODE ────────────────────────────────────────────────────────────
enum CameraMode { FREE, FOLLOW, CINEMATIC }
var _mode: CameraMode = CameraMode.FREE

func _ready() -> void:
	original_offset = offset
	target_position = global_position
	_build_letterbox()

func _process(delta) -> void:
	# ─── Follow mode with dead zone ───────────────────────────
	if _mode == CameraMode.FOLLOW and is_instance_valid(_follow_target):
		var target_pos = _follow_target.global_position + _follow_offset
		# ─── Look-ahead: offset camera toward player velocity (Hollow Knight style) ───
		if _look_ahead_enabled and _follow_target is CharacterBody2D:
			var vel: Vector2 = _follow_target.velocity
			var desired_look: Vector2 = Vector2.ZERO
			if vel.length_squared() > 100.0:  # Only look ahead if meaningfully moving
				desired_look = vel.normalized() * _look_ahead_strength
				# Horizontal bias: look ahead more on X than Y
				desired_look.y *= 0.35
			_current_look_ahead = _current_look_ahead.lerp(desired_look, _look_ahead_speed * delta)
			target_pos += _current_look_ahead
		var diff = target_pos - global_position
		# Only move if outside dead zone
		if abs(diff.x) > _follow_dead_zone.x or abs(diff.y) > _follow_dead_zone.y:
			global_position = global_position.lerp(target_pos, _follow_speed * delta)
		# Clamp to bounds
		if _bounds_enabled:
			global_position = _clamp_to_bounds(global_position)
	
	# Smooth camera movement (cinematic / free mode)
	if is_moving and smooth_enabled:
		global_position = global_position.lerp(target_position, smooth_speed * delta)
		if global_position.distance_to(target_position) < 1.0:
			global_position = target_position
			if _bounds_enabled:
				global_position = _clamp_to_bounds(global_position)
			is_moving = false
			camera_move_finished.emit()
	
	# Smooth zoom
	if is_zooming:
		zoom = zoom.lerp(target_zoom, smooth_speed * delta)
		if zoom.distance_to(target_zoom) < 0.01:
			zoom = target_zoom
			is_zooming = false
			zoom_finished.emit()
	
	# Camera shake — legacy intensity-based system
	if is_shaking and _trauma <= 0.001:
		shake_intensity = lerp(shake_intensity, 0.0, shake_decay * delta)
		offset = original_offset + Vector2(
			randf_range(-shake_intensity, shake_intensity),
			randf_range(-shake_intensity, shake_intensity)
		)
		
		if shake_intensity < 0.1:
			is_shaking = false
			offset = original_offset
			shake_finished.emit()
	
	# Trauma-based shake (modern, layerable) — takes priority when active
	if _trauma > 0.001:
		_apply_trauma_shake(delta)

## Move camera to position over time
func move_to(pos: Vector2, duration: float = 1.0) -> void:
	target_position = pos
	is_moving = true
	
	if not smooth_enabled:
		# Tween for non-smooth movement
		var tween = create_tween()
		tween.tween_property(self, "global_position", pos, duration)
		await tween.finished
		if not is_inside_tree(): return
		camera_move_finished.emit()

## Pan camera by offset
func pan_by(offset_amount: Vector2, duration: float = 1.0) -> void:
	move_to(global_position + offset_amount, duration)

## Zoom camera
func zoom_to(zoom_level: Vector2, duration: float = 1.0) -> void:
	target_zoom = zoom_level
	is_zooming = true
	
	if not smooth_enabled:
		var tween = create_tween()
		tween.tween_property(self, "zoom", zoom_level, duration)
		await tween.finished
		if not is_inside_tree(): return
		zoom_finished.emit()

## Shake camera with intensity
func shake(intensity: float, duration: float = 0.5) -> void:
	shake_intensity = intensity
	shake_decay = intensity / duration
	is_shaking = true

## Focus on a specific node
func focus_on(node: Node2D, duration: float = 1.0) -> void:
	if is_instance_valid(node):
		move_to(node.global_position, duration)

## ─── FOLLOW MODE ─────────────────────────────────────────────────────

func start_follow(target: Node2D, follow_speed: float = 5.0, dead_zone: Vector2 = Vector2(32, 24), follow_offset: Vector2 = Vector2.ZERO) -> void:
	## Start following a target node with dead zone.
	_follow_target = target
	_follow_speed = follow_speed
	_follow_dead_zone = dead_zone
	_follow_offset = follow_offset
	_mode = CameraMode.FOLLOW
	_current_look_ahead = Vector2.ZERO
	is_moving = false

func stop_follow(snap_to_current: bool = true) -> void:
	## Stop following and return to free mode.
	_mode = CameraMode.FREE
	_follow_target = null
	_current_look_ahead = Vector2.ZERO
	if snap_to_current:
		target_position = global_position

func set_look_ahead(is_enabled: bool, strength: float = 60.0, speed: float = 3.0) -> void:
	## Configure camera look-ahead behavior.
	_look_ahead_enabled = is_enabled
	_look_ahead_strength = strength
	_look_ahead_speed = speed
	if not is_enabled:
		_current_look_ahead = Vector2.ZERO

func enter_cinematic_mode() -> void:
	## Enter cinematic mode — stops follow, ready for manual control.
	_mode = CameraMode.CINEMATIC
	_follow_target = null
	is_moving = false

func exit_cinematic_mode(return_to_follow: bool = false, follow_target: Node2D = null) -> void:
	## Exit cinematic mode — optionally resume following a target.
	if return_to_follow and is_instance_valid(follow_target):
		start_follow(follow_target)
	else:
		_mode = CameraMode.FREE

## ─── BOUNDS ─────────────────────────────────────────────────────────

func set_bounds(rect: Rect2) -> void:
	## Set camera bounds (world-space rectangle the camera center stays within).
	_bounds_rect = rect
	_bounds_enabled = true

func clear_bounds() -> void:
	_bounds_enabled = false

func _clamp_to_bounds(pos: Vector2) -> Vector2:
	## Clamp position within bounds rect.
	if not _bounds_enabled:
		return pos
	var half_vp = get_viewport_rect().size / (2.0 * zoom)
	var min_pos = _bounds_rect.position + half_vp
	var max_pos = _bounds_rect.end - half_vp
	if min_pos.x > max_pos.x:
		pos.x = (_bounds_rect.position.x + _bounds_rect.end.x) * 0.5
	else:
		pos.x = clampf(pos.x, min_pos.x, max_pos.x)
	if min_pos.y > max_pos.y:
		pos.y = (_bounds_rect.position.y + _bounds_rect.end.y) * 0.5
	else:
		pos.y = clampf(pos.y, min_pos.y, max_pos.y)
	return pos

## Cinematic dolly shot (move + zoom simultaneously)
func dolly_shot(target_pos: Vector2, zoom_level: Vector2, duration: float = 2.0) -> void:
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "global_position", target_pos, duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(self, "zoom", zoom_level, duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	await tween.finished
	if not is_inside_tree(): return
	camera_move_finished.emit()

## Reset camera to default state
func reset_camera(duration: float = 1.0) -> void:
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "global_position", Vector2.ZERO, duration)
	tween.tween_property(self, "zoom", Vector2.ONE, duration)
	tween.tween_property(self, "offset", original_offset, duration)
	await tween.finished
	if not is_inside_tree(): return

## Dutch angle (tilted camera)
func dutch_angle(angle_degrees: float, duration: float = 0.5) -> void:
	var tween = create_tween()
	tween.tween_property(self, "rotation_degrees", angle_degrees, duration)
	await tween.finished
	if not is_inside_tree(): return

## Screen shake patterns
func earthquake_shake(duration: float = 2.0) -> void:
	var start_time = Time.get_ticks_msec()
	is_shaking = true
	
	while Time.get_ticks_msec() - start_time < duration * 1000:
		var progress = float(Time.get_ticks_msec() - start_time) / (duration * 1000)
		shake_intensity = lerp(20.0, 0.0, progress)
		await get_tree().create_timer(0.05).timeout
		if not is_inside_tree(): return
	
	is_shaking = false
	offset = original_offset
	shake_finished.emit()

func impact_shake() -> void:
	shake(15.0, 0.3)

func explosion_shake() -> void:
	shake(25.0, 0.5)

# =========================================================================
# TRAUMA-BASED SHAKE (Modern, layerable)
# =========================================================================

func add_trauma(amount: float) -> void:
	## Add trauma (0.0-1.0) — stacks and decays smoothly
	_trauma = min(_trauma + amount, 1.0)
	is_shaking = true

func _apply_trauma_shake(delta: float) -> void:
	## Process trauma-based screen shake each frame
	if _trauma <= 0.001:
		if is_shaking and shake_intensity < 0.1:
			is_shaking = false
			offset = original_offset
			rotation_degrees = 0.0
			shake_finished.emit()
		return
	
	_trauma = max(_trauma - _trauma_decay * delta, 0.0)
	var shake_amount = _trauma * _trauma  # Quadratic falloff for more natural feel
	offset = original_offset + Vector2(
		randf_range(-MAX_SHAKE_OFFSET, MAX_SHAKE_OFFSET) * shake_amount,
		randf_range(-MAX_SHAKE_OFFSET, MAX_SHAKE_OFFSET) * shake_amount
	)
	rotation_degrees = randf_range(-MAX_SHAKE_ROTATION, MAX_SHAKE_ROTATION) * shake_amount

# =========================================================================
# LETTERBOX BARS — Cinematic mode
# =========================================================================

func _build_letterbox() -> void:
	## Create letterbox bars for cinematic mode
	_letterbox_layer = CanvasLayer.new()
	_letterbox_layer.layer = 90
	_letterbox_layer.name = "LetterboxLayer"
	add_child(_letterbox_layer)
	
	var vp_height = _get_viewport_height()
	
	_letterbox_top = ColorRect.new()
	_letterbox_top.color = Color.BLACK
	_letterbox_top.anchor_left = 0.0
	_letterbox_top.anchor_right = 1.0
	_letterbox_top.anchor_top = 0.0
	_letterbox_top.anchor_bottom = 0.0
	_letterbox_top.offset_right = 0
	_letterbox_top.offset_bottom = 0
	_letterbox_top.position = Vector2(0, 0)
	_letterbox_top.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_letterbox_layer.add_child(_letterbox_top)
	
	_letterbox_bottom = ColorRect.new()
	_letterbox_bottom.color = Color.BLACK
	_letterbox_bottom.anchor_left = 0.0
	_letterbox_bottom.anchor_right = 1.0
	_letterbox_bottom.anchor_top = 1.0
	_letterbox_bottom.anchor_bottom = 1.0
	_letterbox_bottom.offset_right = 0
	_letterbox_bottom.offset_top = 0
	_letterbox_bottom.position = Vector2(0, vp_height)
	_letterbox_bottom.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_letterbox_layer.add_child(_letterbox_bottom)

func _get_viewport_height() -> float:
	## Get viewport height dynamically — never hardcoded.
	var vp = get_viewport()
	if vp:
		return vp.get_visible_rect().size.y
	return 720.0  # Fallback only

func enable_letterbox(bar_height: float = 72.0, duration: float = 0.6) -> void:
	## Slide in cinematic letterbox bars
	if _letterbox_active:
		return
	_letterbox_active = true
	var vp_h = _get_viewport_height()
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(_letterbox_top, "size:y", bar_height, duration).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(_letterbox_bottom, "size:y", bar_height, duration).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(_letterbox_bottom, "position:y", vp_h - bar_height, duration).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	await tween.finished
	if not is_inside_tree(): return

func disable_letterbox(duration: float = 0.4) -> void:
	## Slide out cinematic letterbox bars
	if not _letterbox_active:
		return
	_letterbox_active = false
	var vp_h = _get_viewport_height()
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(_letterbox_top, "size:y", 0.0, duration).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	tween.tween_property(_letterbox_bottom, "size:y", 0.0, duration).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	tween.tween_property(_letterbox_bottom, "position:y", vp_h, duration).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	await tween.finished
	if not is_inside_tree(): return

# =========================================================================
# ADVANCED SHOTS
# =========================================================================

func tracking_shot(waypoints: Array[Vector2], total_duration: float = 4.0) -> void:
	## Smooth camera movement along multiple waypoints (rail shot)
	if waypoints.is_empty():
		return
	var segment_duration = total_duration / float(waypoints.size())
	for wp in waypoints:
		target_position = wp
		is_moving = true
		smooth_enabled = true
		await get_tree().create_timer(segment_duration).timeout
		if not is_inside_tree(): return
	camera_move_finished.emit()

func push_in(amount: float = 0.3, duration: float = 1.5) -> void:
	## Slow dramatic push-in zoom
	var new_zoom = zoom + Vector2(amount, amount)
	var tween = create_tween()
	tween.tween_property(self, "zoom", new_zoom, duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	await tween.finished
	if not is_inside_tree(): return
	zoom_finished.emit()

func pull_out(amount: float = 0.3, duration: float = 1.5) -> void:
	## Slow dramatic pull-out zoom
	var new_zoom = zoom - Vector2(amount, amount)
	new_zoom = new_zoom.clamp(Vector2(0.3, 0.3), Vector2(3.0, 3.0))
	var tween = create_tween()
	tween.tween_property(self, "zoom", new_zoom, duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	await tween.finished
	if not is_inside_tree(): return
	zoom_finished.emit()

func whip_pan(target_pos: Vector2, duration: float = 0.3) -> void:
	## Fast camera whip to a position — used for dramatic reveals
	smooth_enabled = false
	var tween = create_tween()
	tween.tween_property(self, "global_position", target_pos, duration).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
	add_trauma(0.2)  # Slight shake on arrival
	await tween.finished
	if not is_inside_tree(): return
	smooth_enabled = true
	camera_move_finished.emit()
