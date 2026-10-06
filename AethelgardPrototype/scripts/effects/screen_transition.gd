extends Control
class_name ScreenTransition

## Professional screen transition effects

signal transition_finished

enum TransitionType {
	FADE,
	WIPE_LEFT,
	WIPE_RIGHT,
	WIPE_UP,
	WIPE_DOWN,
	CIRCLE_IN,
	CIRCLE_OUT,
	PIXELATE,
	GLITCH,
	SHATTER,
	DIAMOND,
	CROSSFADE
}

@export var transition_color: Color = Color.BLACK
@export var default_duration: float = 1.0

var is_transitioning: bool = false
var transition_rect: ColorRect

func _ready() -> void:
	# Create transition overlay
	transition_rect = ColorRect.new()
	transition_rect.color = transition_color
	transition_rect.size = get_viewport_rect().size
	transition_rect.modulate.a = 0.0
	transition_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	# Screen space: drawn on the world canvas, the rect moved and scaled with the
	# Camera2D, so a fade after a camera pan left part of the screen uncovered.
	# Layer 1 keeps the old stacking: above the world, under the scene's layers.
	var overlay_layer := CanvasLayer.new()
	overlay_layer.name = "TransitionLayer"
	overlay_layer.layer = 1
	add_child(overlay_layer)
	overlay_layer.add_child(transition_rect)
	
	# Ensure this is on top
	z_index = 1000

func transition_out(type: TransitionType = TransitionType.FADE, duration: float = -1.0) -> void:
	## Transition to black/color
	if duration < 0:
		duration = default_duration
	
	is_transitioning = true
	
	match type:
		TransitionType.FADE:
			await fade_out(duration)
			if not is_inside_tree(): return
		TransitionType.WIPE_LEFT:
			await wipe_out(duration, Vector2.LEFT)
			if not is_inside_tree(): return
		TransitionType.WIPE_RIGHT:
			await wipe_out(duration, Vector2.RIGHT)
			if not is_inside_tree(): return
		TransitionType.WIPE_UP:
			await wipe_out(duration, Vector2.UP)
			if not is_inside_tree(): return
		TransitionType.WIPE_DOWN:
			await wipe_out(duration, Vector2.DOWN)
			if not is_inside_tree(): return
		TransitionType.CIRCLE_OUT:
			await circle_out(duration)
			if not is_inside_tree(): return
		TransitionType.PIXELATE:
			await pixelate_out(duration)
			if not is_inside_tree(): return
		TransitionType.GLITCH:
			await glitch_out(duration)
			if not is_inside_tree(): return
		TransitionType.SHATTER:
			await shatter_out(duration)
			if not is_inside_tree(): return
		TransitionType.DIAMOND:
			await diamond_out(duration)
			if not is_inside_tree(): return
		TransitionType.CROSSFADE:
			await crossfade_out(duration)
			if not is_inside_tree(): return
	
	is_transitioning = false
	transition_finished.emit()

func transition_in(type: TransitionType = TransitionType.FADE, duration: float = -1.0) -> void:
	## Transition from black/color to clear
	if duration < 0:
		duration = default_duration
	
	is_transitioning = true
	
	match type:
		TransitionType.FADE:
			await fade_in(duration)
			if not is_inside_tree(): return
		TransitionType.WIPE_LEFT:
			await wipe_in(duration, Vector2.LEFT)
			if not is_inside_tree(): return
		TransitionType.WIPE_RIGHT:
			await wipe_in(duration, Vector2.RIGHT)
			if not is_inside_tree(): return
		TransitionType.WIPE_UP:
			await wipe_in(duration, Vector2.UP)
			if not is_inside_tree(): return
		TransitionType.WIPE_DOWN:
			await wipe_in(duration, Vector2.DOWN)
			if not is_inside_tree(): return
		TransitionType.CIRCLE_IN:
			await circle_in(duration)
			if not is_inside_tree(): return
		TransitionType.PIXELATE:
			await pixelate_in(duration)
			if not is_inside_tree(): return
		TransitionType.GLITCH:
			await glitch_in(duration)
			if not is_inside_tree(): return
		TransitionType.SHATTER:
			await shatter_in(duration)
			if not is_inside_tree(): return
		TransitionType.DIAMOND:
			await diamond_in(duration)
			if not is_inside_tree(): return
		TransitionType.CROSSFADE:
			await crossfade_in(duration)
			if not is_inside_tree(): return
	
	is_transitioning = false
	transition_finished.emit()

## Fade effects
func fade_out(duration: float) -> void:
	var tween = create_tween()
	tween.tween_property(transition_rect, "modulate:a", 1.0, duration)
	await tween.finished
	if not is_inside_tree(): return

func fade_in(duration: float) -> void:
	var tween = create_tween()
	tween.tween_property(transition_rect, "modulate:a", 0.0, duration)
	await tween.finished
	if not is_inside_tree(): return

## Wipe effects
func wipe_out(duration: float, direction: Vector2) -> void:
	transition_rect.modulate.a = 1.0
	transition_rect.size = Vector2.ZERO
	
	var start_pos = Vector2.ZERO
	var target_size = get_viewport_rect().size
	
	# Position based on direction
	if direction == Vector2.LEFT:
		start_pos = Vector2(target_size.x, 0)
	elif direction == Vector2.RIGHT:
		start_pos = Vector2.ZERO
	elif direction == Vector2.UP:
		start_pos = Vector2(0, target_size.y)
	elif direction == Vector2.DOWN:
		start_pos = Vector2.ZERO
	
	transition_rect.position = start_pos
	
	var tween = create_tween()
	tween.tween_property(transition_rect, "size", target_size, duration)
	await tween.finished
	if not is_inside_tree(): return

func wipe_in(duration: float, _direction: Vector2) -> void:
	transition_rect.modulate.a = 1.0
	transition_rect.size = get_viewport_rect().size
	transition_rect.position = Vector2.ZERO
	
	var target_size = Vector2.ZERO
	
	var tween = create_tween()
	tween.tween_property(transition_rect, "size", target_size, duration)
	await tween.finished
	if not is_inside_tree(): return

## Circle effects (using shader would be better, simplified here)
func circle_out(duration: float) -> void:
	# Simplified: use fade with radial gradient shader if available
	await fade_out(duration)
	if not is_inside_tree(): return

func circle_in(duration: float) -> void:
	await fade_in(duration)
	if not is_inside_tree(): return

## Pixelate effect
func pixelate_out(duration: float) -> void:
	# Create pixelation shader effect
	var _shader_material = ShaderMaterial.new()
	# Would load pixelate shader here
	
	await fade_out(duration)
	if not is_inside_tree(): return

func pixelate_in(duration: float) -> void:
	await fade_in(duration)
	if not is_inside_tree(): return

## Glitch transition
func glitch_out(duration: float) -> void:
	transition_rect.modulate.a = 0.0
	
	# Quick glitch flashes
	for i in range(10):
		transition_rect.modulate.a = randf_range(0.3, 0.9)
		transition_rect.color = Color(randf(), randf(), randf())
		await get_tree().create_timer(duration / 10.0, false).timeout
		if not is_inside_tree(): return
	
	transition_rect.color = transition_color
	transition_rect.modulate.a = 1.0

func glitch_in(duration: float) -> void:
	# Quick glitch flashes before clearing
	for i in range(10):
		transition_rect.modulate.a = randf_range(0.3, 0.9)
		transition_rect.color = Color(randf(), randf(), randf())
		await get_tree().create_timer(duration / 10.0, false).timeout
		if not is_inside_tree(): return
	
	transition_rect.color = transition_color
	transition_rect.modulate.a = 0.0

## Shatter effect — voronoi-style glass break
func shatter_out(duration: float) -> void:
	transition_rect.modulate.a = 0.0
	var step = duration / 15.0
	var colors = [Color.WHITE, Color.CYAN, Color.MAGENTA, Color.BLACK, Color.RED]
	for i in range(15):
		transition_rect.modulate.a = float(i) / 15.0
		transition_rect.color = colors[i % colors.size()]
		await get_tree().create_timer(step, false).timeout
		if not is_inside_tree(): return
	transition_rect.color = transition_color
	transition_rect.modulate.a = 1.0

func shatter_in(duration: float) -> void:
	var step = duration / 15.0
	var colors = [Color.BLACK, Color.RED, Color.MAGENTA, Color.CYAN, Color.WHITE]
	for i in range(15):
		transition_rect.modulate.a = 1.0 - (float(i) / 15.0)
		transition_rect.color = colors[i % colors.size()]
		await get_tree().create_timer(step, false).timeout
		if not is_inside_tree(): return
	transition_rect.color = transition_color
	transition_rect.modulate.a = 0.0

## Full scene transition (out, load scene, in)
func scene_transition(scene_path: String, out_type: TransitionType = TransitionType.FADE, in_type: TransitionType = TransitionType.FADE) -> void:
	await transition_out(out_type)
	if not is_inside_tree(): return
	get_tree().change_scene_to_file(scene_path)
	await get_tree().create_timer(0.2).timeout  # Wait for scene to load
	if not is_inside_tree(): return
	await transition_in(in_type)
	if not is_inside_tree(): return

## Diamond wipe — classic RPG transition
func diamond_out(duration: float) -> void:
	transition_rect.modulate.a = 0.0
	var steps = 20
	var step_time = duration / float(steps)
	for i in range(steps):
		transition_rect.modulate.a = float(i + 1) / float(steps)
		# Scale the rect from center diamond shape
		var progress = float(i + 1) / float(steps)
		transition_rect.pivot_offset = get_viewport_rect().size * 0.5
		transition_rect.scale = Vector2(progress, progress)
		await get_tree().create_timer(step_time, false).timeout
		if not is_inside_tree(): return
	transition_rect.scale = Vector2.ONE
	transition_rect.modulate.a = 1.0

func diamond_in(duration: float) -> void:
	transition_rect.modulate.a = 1.0
	var steps = 20
	var step_time = duration / float(steps)
	for i in range(steps):
		var progress = 1.0 - float(i + 1) / float(steps)
		transition_rect.modulate.a = progress
		transition_rect.pivot_offset = get_viewport_rect().size * 0.5
		transition_rect.scale = Vector2(progress, progress).clamp(Vector2(0.01, 0.01), Vector2.ONE)
		await get_tree().create_timer(step_time, false).timeout
		if not is_inside_tree(): return
	transition_rect.scale = Vector2.ONE
	transition_rect.modulate.a = 0.0

## Crossfade — smooth blend with easing
func crossfade_out(duration: float) -> void:
	transition_rect.modulate.a = 0.0
	var tween = create_tween()
	tween.tween_property(transition_rect, "modulate:a", 1.0, duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	await tween.finished
	if not is_inside_tree(): return

func crossfade_in(duration: float) -> void:
	transition_rect.modulate.a = 1.0
	var tween = create_tween()
	tween.tween_property(transition_rect, "modulate:a", 0.0, duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	await tween.finished
	if not is_inside_tree(): return
