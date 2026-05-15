extends Node
class_name CinematicVFX

## ==========================================================================
## CINEMATIC VFX — Reusable visual effects for cutscenes & exploration
## ==========================================================================
## Provides vignette, ambient lighting, screen color grading, ambient
## particles, and text effects. Can be used standalone or via CutsceneDirector.
##
## Usage:
##   var vfx = CinematicVFX.new()
##   add_child(vfx)
##   vfx.set_vignette(0.3, Color(0, 0, 0.05))
##   vfx.set_ambient_light(Color(0.4, 0.3, 0.6))
##   vfx.spawn_ambient_particles("vfx_fireflies")
## ==========================================================================

## ─── VIGNETTE ────────────────────────────────────────────────────────
var _vignette_layer: CanvasLayer
var _vignette_top: ColorRect
var _vignette_bottom: ColorRect
var _vignette_left: ColorRect
var _vignette_right: ColorRect
var _vignette_active: bool = false
var _vignette_tween: Tween

## ─── AMBIENT LIGHT ───────────────────────────────────────────────────
var _ambient_modulate: CanvasModulate
var _ambient_active: bool = false

## ─── AMBIENT PARTICLES ──────────────────────────────────────────────
var _ambient_particles: Array = []  # Currently active ambient particle nodes

func _ready() -> void:
	_build_vignette()

func _build_vignette() -> void:
	_vignette_layer = CanvasLayer.new()
	_vignette_layer.layer = 85
	_vignette_layer.name = "VignetteLayer"
	add_child(_vignette_layer)
	
	var vp_size = _get_vp_size()
	
	# Top
	_vignette_top = ColorRect.new()
	_vignette_top.color = Color(0, 0, 0, 0)
	_vignette_top.size = Vector2(vp_size.x, vp_size.y * 0.15)
	_vignette_top.position = Vector2.ZERO
	_vignette_top.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_vignette_layer.add_child(_vignette_top)
	
	# Bottom
	_vignette_bottom = ColorRect.new()
	_vignette_bottom.color = Color(0, 0, 0, 0)
	_vignette_bottom.size = Vector2(vp_size.x, vp_size.y * 0.15)
	_vignette_bottom.position = Vector2(0, vp_size.y * 0.85)
	_vignette_bottom.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_vignette_layer.add_child(_vignette_bottom)
	
	# Left
	_vignette_left = ColorRect.new()
	_vignette_left.color = Color(0, 0, 0, 0)
	_vignette_left.size = Vector2(vp_size.x * 0.1, vp_size.y)
	_vignette_left.position = Vector2.ZERO
	_vignette_left.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_vignette_layer.add_child(_vignette_left)
	
	# Right
	_vignette_right = ColorRect.new()
	_vignette_right.color = Color(0, 0, 0, 0)
	_vignette_right.size = Vector2(vp_size.x * 0.1, vp_size.y)
	_vignette_right.position = Vector2(vp_size.x * 0.9, 0)
	_vignette_right.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_vignette_layer.add_child(_vignette_right)

func _get_vp_size() -> Vector2:
	var vp = get_viewport()
	if vp:
		return vp.get_visible_rect().size
	return Vector2(1280, 720)

## ─── VIGNETTE API ────────────────────────────────────────────────────

func set_vignette(intensity: float = 0.3, color: Color = Color.BLACK, duration: float = 0.8) -> void:
	## Enable vignette with given intensity (0.0 - 1.0) and color.
	_vignette_active = true
	var target_color = Color(color.r, color.g, color.b, intensity)
	if _vignette_tween and _vignette_tween.is_valid():
		_vignette_tween.kill()
	_vignette_tween = create_tween()
	_vignette_tween.set_parallel(true)
	_vignette_tween.tween_property(_vignette_top, "color", target_color, duration)
	_vignette_tween.tween_property(_vignette_bottom, "color", target_color, duration)
	_vignette_tween.tween_property(_vignette_left, "color", target_color, duration)
	_vignette_tween.tween_property(_vignette_right, "color", target_color, duration)

func clear_vignette(duration: float = 0.5) -> void:
	## Disable vignette by fading to transparent.
	_vignette_active = false
	var transparent = Color(0, 0, 0, 0)
	if _vignette_tween and _vignette_tween.is_valid():
		_vignette_tween.kill()
	_vignette_tween = create_tween()
	_vignette_tween.set_parallel(true)
	_vignette_tween.tween_property(_vignette_top, "color", transparent, duration)
	_vignette_tween.tween_property(_vignette_bottom, "color", transparent, duration)
	_vignette_tween.tween_property(_vignette_left, "color", transparent, duration)
	_vignette_tween.tween_property(_vignette_right, "color", transparent, duration)

## ─── AMBIENT LIGHT API ──────────────────────────────────────────────

func set_ambient_light(color: Color, duration: float = 1.0) -> void:
	## Apply a CanvasModulate tint to the entire scene for ambient lighting.
	if not _ambient_modulate or not is_instance_valid(_ambient_modulate):
		_ambient_modulate = CanvasModulate.new()
		_ambient_modulate.name = "AmbientLight"
		var scene = get_tree().current_scene
		if not scene:
			_ambient_modulate.free()
			_ambient_modulate = null
			return
		scene.add_child(_ambient_modulate)
	_ambient_active = true
	var tween = create_tween()
	tween.tween_property(_ambient_modulate, "color", color, duration)

func clear_ambient_light(duration: float = 0.5) -> void:
	## Remove ambient lighting tint.
	if not _ambient_modulate or not is_instance_valid(_ambient_modulate):
		_ambient_modulate = null
		return
	_ambient_active = false
	var tween = create_tween()
	tween.tween_property(_ambient_modulate, "color", Color.WHITE, duration)
	await tween.finished
	if is_inside_tree() and is_instance_valid(_ambient_modulate):
		_ambient_modulate.queue_free()
		_ambient_modulate = null

## ─── AMBIENT PARTICLES API ──────────────────────────────────────────

func spawn_ambient_particles(effect_name: String, position: Vector2 = Vector2.ZERO) -> Node:
	## Spawn continuous ambient particles (rain, snow, fireflies, etc).
	## Returns the particle node so you can move/free it later.
	var parent = get_tree().current_scene
	if not parent:
		return null
	var node = VFXLibrary.spawn(effect_name, position, parent)
	if node:
		_ambient_particles.append(node)
	return node

func clear_ambient_particles() -> void:
	## Free all ambient particle nodes.
	for p in _ambient_particles:
		if is_instance_valid(p):
			p.queue_free()
	_ambient_particles.clear()

## ─── SCREEN FLASH ────────────────────────────────────────────────────

func screen_flash(color: Color = Color.WHITE, duration: float = 0.3) -> void:
	## Quick full-screen flash effect.
	var layer = CanvasLayer.new()
	layer.layer = 100
	add_child(layer)
	var flash = ColorRect.new()
	flash.color = color
	flash.set_anchors_preset(Control.PRESET_FULL_RECT)
	flash.modulate.a = 0.0
	flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(flash)
	
	var tween = create_tween()
	tween.tween_property(flash, "modulate:a", 0.9, duration * 0.2)
	tween.tween_property(flash, "modulate:a", 0.0, duration * 0.8)
	await tween.finished
	if is_inside_tree():
		layer.queue_free()

## ─── COLOR GRADE ─────────────────────────────────────────────────────

func color_grade(color: Color, duration: float = 1.0) -> void:
	## Apply a color grade overlay (semi-transparent tint over everything).
	# Remove existing color grade layer to prevent stacking
	var existing = get_node_or_null("ColorGrade")
	if existing:
		existing.queue_free()
	var layer = CanvasLayer.new()
	layer.layer = 80
	layer.name = "ColorGrade"
	add_child(layer)
	var overlay = ColorRect.new()
	overlay.color = Color(color.r, color.g, color.b, 0.0)
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(overlay)
	
	var tween = create_tween()
	tween.tween_property(overlay, "color:a", color.a, duration)

## ─── CLEANUP ─────────────────────────────────────────────────────────

func cleanup() -> void:
	## Clean up all effects.
	clear_vignette(0.0)
	clear_ambient_particles()
	if _ambient_modulate and is_instance_valid(_ambient_modulate):
		_ambient_modulate.queue_free()
		_ambient_modulate = null

func _exit_tree() -> void:
	cleanup()
