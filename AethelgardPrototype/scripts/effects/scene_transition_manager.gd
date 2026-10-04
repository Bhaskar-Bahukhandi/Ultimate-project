extends CanvasLayer

## ==========================================================================
## Scene Transition Manager — Global Autoload for smooth scene transitions
## ==========================================================================
## Provides a universal API for transitioning between scenes with effects.
## Works as a CanvasLayer autoload so it persists across scene changes.
##
## Usage:
##   SceneTransitions.change_scene("res://scenes/main_menu.tscn")
##   SceneTransitions.change_scene("res://scenes/main_menu.tscn", TransitionStyle.GLITCH, 0.8)
##   SceneTransitions.fade_out()    # manual half-transition
##   SceneTransitions.fade_in()     # manual half-transition
## ==========================================================================

signal transition_started
signal transition_midpoint  ## Fires when screen is fully covered (scene swap point)
signal transition_completed

enum TransitionStyle {
	FADE,           ## Simple fade to black and back
	CROSSFADE,      ## Smooth sine-eased crossfade
	WIPE_LEFT,      ## Horizontal wipe from right to left
	WIPE_RIGHT,     ## Horizontal wipe from left to right
	GLITCH,         ## Digital glitch flashes (combat / corruption)
	SHATTER,        ## Glass-shatter color burst (boss defeat / chapter end)
	DIAMOND,        ## Classic RPG diamond wipe
	FLASH_WHITE,    ## Bright white flash (revival, level up)
	COMBAT_ENTRY,   ## Red-tinted fast wipe (entering combat)
	COMBAT_EXIT,    ## Slow fade from combat
}

# ─── CONFIGURATION ───────────────────────────────────────────────────────
const DEFAULT_DURATION: float = 0.6
const COMBAT_ENTRY_DURATION: float = 0.4
const COMBAT_EXIT_DURATION: float = 0.8
const CHAPTER_TRANSITION_DURATION: float = 1.2

# ─── STATE ───────────────────────────────────────────────────────────────
var is_transitioning: bool = false
var _overlay: ColorRect
var _flash_overlay: ColorRect
var _flash_tween: Tween = null  # BUG 12 FIX: tracked flash tween

func _ready() -> void:
	layer = 200  # Above everything including dialogue (layer 100)
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_overlays()

func _build_overlays() -> void:
	# Main transition overlay (black by default)
	_overlay = ColorRect.new()
	_overlay.name = "TransitionOverlay"
	_overlay.color = Color.BLACK
	_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	_overlay.modulate.a = 0.0
	add_child(_overlay)

	# Flash overlay (white, for impact flashes)
	_flash_overlay = ColorRect.new()
	_flash_overlay.name = "FlashOverlay"
	_flash_overlay.color = Color.WHITE
	_flash_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_flash_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	_flash_overlay.modulate.a = 0.0
	add_child(_flash_overlay)

# ==========================================================================
# PUBLIC API
# ==========================================================================

func _safe_reset_transition() -> void:
	## Reset transition state when interrupted/bailed. Prevents permanent lockout.
	is_transitioning = false
	# BUG 5 FIX: Clear SFX cache on scene transitions to prevent unbounded growth
	if has_node("/root/SFXManager"):
		SFXManager.clear_cache()
	if is_instance_valid(_overlay):
		_overlay.modulate.a = 0.0
		_overlay.size = Vector2.ZERO
		_overlay.scale = Vector2.ONE
		_overlay.position = Vector2.ZERO
	if is_instance_valid(_flash_overlay):
		_flash_overlay.modulate.a = 0.0

func change_scene(scene_path: String, style: TransitionStyle = TransitionStyle.FADE, duration: float = -1.0) -> void:
	## Full scene transition: fade out → change scene → fade in.
	if is_transitioning:
		return
	if scene_path.is_empty() or not ResourceLoader.exists(scene_path):
		push_error("[SceneTransitions] Invalid scene path: %s" % scene_path)
		return
	is_transitioning = true
	if has_node("/root/SFXManager"):
		SFXManager.play("transition_whoosh")
	transition_started.emit()

	var dur = duration if duration > 0 else _get_default_duration(style)
	var half = dur * 0.5

	# Phase 1: Transition out
	await _transition_out(style, half)
	if not is_inside_tree():
		_safe_reset_transition()
		return
	transition_midpoint.emit()

	# BUG 18 FIX: Kill all active TweenAnimator tweens before scene swap
	TweenAnimator.clear_all_tweens()

	# Phase 2: Swap scene (with background loading for large scenes)
	var use_threaded = ResourceLoader.has_method("load_threaded_request")
	if use_threaded:
		ResourceLoader.load_threaded_request(scene_path)
		var status = ResourceLoader.load_threaded_get_status(scene_path)
		while status == ResourceLoader.THREAD_LOAD_IN_PROGRESS:
			await get_tree().process_frame
			if not is_inside_tree():
				_safe_reset_transition()
				return
			status = ResourceLoader.load_threaded_get_status(scene_path)
		if status == ResourceLoader.THREAD_LOAD_LOADED:
			var scene = ResourceLoader.load_threaded_get(scene_path)
			get_tree().change_scene_to_packed(scene)
		else:
			push_error("[SceneTransitions] Threaded load failed: %s" % scene_path)
			get_tree().change_scene_to_file(scene_path)
	else:
		var change_err = get_tree().change_scene_to_file(scene_path)
		if change_err != OK:
			push_error("[SceneTransitions] Failed to change scene (%d): %s" % [change_err, scene_path])
	await get_tree().process_frame  # Wait one frame for scene to initialize
	if not is_inside_tree():
		_safe_reset_transition()
		return
	await get_tree().process_frame
	if not is_inside_tree():
		_safe_reset_transition()
		return

	# Phase 3: Transition in
	await _transition_in(style, half)
	if not is_inside_tree():
		_safe_reset_transition()
		return

	is_transitioning = false
	transition_completed.emit()

func fade_out(duration: float = 0.4, color: Color = Color.BLACK) -> void:
	## Manual half-transition: fade to color. Use with fade_in() for custom flows.
	_overlay.color = color
	var tween = create_tween()
	tween.tween_property(_overlay, "modulate:a", 1.0, duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	await tween.finished
	if not is_inside_tree(): return

func fade_in(duration: float = 0.4) -> void:
	## Manual half-transition: fade from overlay to clear.
	var tween = create_tween()
	tween.tween_property(_overlay, "modulate:a", 0.0, duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	await tween.finished
	if not is_inside_tree(): return

func flash(color: Color = Color.WHITE, duration: float = 0.3) -> void:
	## Quick screen flash for impacts, level ups, phase changes.
	_flash_overlay.color = color
	_flash_overlay.modulate.a = 0.8
	var tween = create_tween()
	tween.tween_property(_flash_overlay, "modulate:a", 0.0, duration).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
	await tween.finished
	if not is_inside_tree(): return

func combat_flash(duration: float = 0.15) -> void:
	## Brief red combat impact flash.
	await flash(Color(1.0, 0.15, 0.0, 0.6), duration)
	if not is_inside_tree(): return

func boss_phase_flash(phase_color: Color = Color(1.0, 0.0, 0.0)) -> void:
	## Dramatic flash for boss phase transitions.
	if has_node("/root/SFXManager"):
		SFXManager.play("glitch_surge")
	_flash_overlay.color = phase_color
	_flash_overlay.modulate.a = 0.0
	var tween = create_tween()
	# Quick flash up then slow fade
	tween.tween_property(_flash_overlay, "modulate:a", 0.7, 0.08)
	tween.tween_property(_flash_overlay, "modulate:a", 0.0, 0.6).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
	await tween.finished
	if not is_inside_tree(): return

# ==========================================================================
# PRIVATE — TRANSITION OUT (screen → covered)
# ==========================================================================

func _transition_out(style: TransitionStyle, duration: float) -> void:
	match style:
		TransitionStyle.FADE, TransitionStyle.CROSSFADE:
			await _fade_to_black(duration)
			if not is_inside_tree(): return
		TransitionStyle.WIPE_LEFT:
			await _wipe_out(duration, Vector2.LEFT)
			if not is_inside_tree(): return
		TransitionStyle.WIPE_RIGHT:
			await _wipe_out(duration, Vector2.RIGHT)
			if not is_inside_tree(): return
		TransitionStyle.GLITCH:
			await _glitch_out(duration)
			if not is_inside_tree(): return
		TransitionStyle.SHATTER:
			await _shatter_out(duration)
			if not is_inside_tree(): return
		TransitionStyle.DIAMOND:
			await _diamond_out(duration)
			if not is_inside_tree(): return
		TransitionStyle.FLASH_WHITE:
			await _flash_white_out(duration)
			if not is_inside_tree(): return
		TransitionStyle.COMBAT_ENTRY:
			await _combat_entry_out(duration)
			if not is_inside_tree(): return
		TransitionStyle.COMBAT_EXIT:
			await _fade_to_black(duration)
			if not is_inside_tree(): return

# ==========================================================================
# PRIVATE — TRANSITION IN (covered → clear)
# ==========================================================================

func _transition_in(style: TransitionStyle, duration: float) -> void:
	match style:
		TransitionStyle.FADE, TransitionStyle.CROSSFADE:
			await _fade_from_black(duration)
			if not is_inside_tree(): return
		TransitionStyle.WIPE_LEFT:
			await _wipe_in(duration, Vector2.LEFT)
			if not is_inside_tree(): return
		TransitionStyle.WIPE_RIGHT:
			await _wipe_in(duration, Vector2.RIGHT)
			if not is_inside_tree(): return
		TransitionStyle.GLITCH:
			await _glitch_in(duration)
			if not is_inside_tree(): return
		TransitionStyle.SHATTER:
			await _shatter_in(duration)
			if not is_inside_tree(): return
		TransitionStyle.DIAMOND:
			await _diamond_in(duration)
			if not is_inside_tree(): return
		TransitionStyle.FLASH_WHITE:
			await _flash_white_in(duration)
			if not is_inside_tree(): return
		TransitionStyle.COMBAT_ENTRY:
			await _combat_entry_in(duration)
			if not is_inside_tree(): return
		TransitionStyle.COMBAT_EXIT:
			await _fade_from_black(duration)
			if not is_inside_tree(): return

# ==========================================================================
# TRANSITION IMPLEMENTATIONS
# ==========================================================================

func _fade_to_black(duration: float) -> void:
	_overlay.color = Color.BLACK
	_overlay.modulate.a = 0.0
	var tween = create_tween()
	tween.tween_property(_overlay, "modulate:a", 1.0, duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	await tween.finished
	if not is_inside_tree(): return

func _fade_from_black(duration: float) -> void:
	var tween = create_tween()
	tween.tween_property(_overlay, "modulate:a", 0.0, duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	await tween.finished
	if not is_inside_tree(): return

func _wipe_out(duration: float, direction: Vector2) -> void:
	_overlay.modulate.a = 1.0
	var target_size = get_viewport().get_visible_rect().size if get_viewport() else Vector2(1280, 720)
	if direction == Vector2.LEFT:
		# Wipe right-to-left: right edge stays at viewport right, left edge sweeps in
		_overlay.position = Vector2(target_size.x, 0)
		_overlay.size = Vector2(0, target_size.y)
		var tween = create_tween().set_parallel(true)
		tween.tween_property(_overlay, "position:x", 0.0, duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		tween.tween_property(_overlay, "size:x", target_size.x, duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		await tween.finished
	else:
		# Wipe left-to-right: left edge stays at 0, right edge sweeps across
		_overlay.position = Vector2.ZERO
		_overlay.size = Vector2(0, target_size.y)
		var tween = create_tween()
		tween.tween_property(_overlay, "size:x", target_size.x, duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		await tween.finished
	if not is_inside_tree(): return

func _wipe_in(duration: float, direction: Vector2) -> void:
	var vp_size = get_viewport().get_visible_rect().size if get_viewport() else Vector2(1280, 720)
	_overlay.size = vp_size
	_overlay.position = Vector2.ZERO
	if direction == Vector2.LEFT:
		# Reveal left-to-right: left edge sweeps to the right
		var tween = create_tween().set_parallel(true)
		tween.tween_property(_overlay, "position:x", vp_size.x, duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tween.tween_property(_overlay, "size:x", 0.0, duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		await tween.finished
	else:
		# Reveal right-to-left: right edge sweeps to the left (shrink from right)
		var tween = create_tween()
		tween.tween_property(_overlay, "size:x", 0.0, duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		await tween.finished
	if not is_inside_tree(): return
	_overlay.modulate.a = 0.0
	# Reset overlay layout so subsequent non-wipe transitions work correctly
	_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)

func _glitch_out(duration: float) -> void:
	if has_node("/root/SFXManager"):
		SFXManager.play("glitch_surge")
	_overlay.modulate.a = 0.0
	var step_time = duration / 8.0
	var glitch_colors = [
		Color(0.0, 1.0, 1.0), Color(1.0, 0.0, 1.0),
		Color(0.0, 1.0, 0.0), Color(1.0, 0.0, 0.0),
	]
	for i in range(8):
		_overlay.color = glitch_colors[i % glitch_colors.size()]
		_overlay.modulate.a = randf_range(0.3, 0.85)
		await get_tree().create_timer(step_time).timeout
		if not is_inside_tree(): return
	_overlay.color = Color.BLACK
	_overlay.modulate.a = 1.0

func _glitch_in(duration: float) -> void:
	var step_time = duration / 8.0
	var glitch_colors = [
		Color(1.0, 0.0, 0.0), Color(0.0, 1.0, 0.0),
		Color(1.0, 0.0, 1.0), Color(0.0, 1.0, 1.0),
	]
	for i in range(8):
		_overlay.color = glitch_colors[i % glitch_colors.size()]
		_overlay.modulate.a = randf_range(0.2, 0.7)
		await get_tree().create_timer(step_time).timeout
		if not is_inside_tree(): return
	_overlay.color = Color.BLACK
	_overlay.modulate.a = 0.0

func _shatter_out(duration: float) -> void:
	_overlay.modulate.a = 0.0
	var step_time = duration / 12.0
	var shatter_colors = [Color.WHITE, Color.CYAN, Color.MAGENTA, Color.BLACK]
	for i in range(12):
		_overlay.color = shatter_colors[i % shatter_colors.size()]
		_overlay.modulate.a = float(i + 1) / 12.0
		await get_tree().create_timer(step_time).timeout
		if not is_inside_tree(): return
	_overlay.color = Color.BLACK
	_overlay.modulate.a = 1.0

func _shatter_in(duration: float) -> void:
	var step_time = duration / 12.0
	var shatter_colors = [Color.BLACK, Color.MAGENTA, Color.CYAN, Color.WHITE]
	for i in range(12):
		_overlay.color = shatter_colors[i % shatter_colors.size()]
		_overlay.modulate.a = 1.0 - (float(i + 1) / 12.0)
		await get_tree().create_timer(step_time).timeout
		if not is_inside_tree(): return
	_overlay.color = Color.BLACK
	_overlay.modulate.a = 0.0

func _diamond_out(duration: float) -> void:
	_overlay.modulate.a = 0.0
	var vp_size = get_viewport().get_visible_rect().size if get_viewport() else Vector2(1280, 720)
	_overlay.pivot_offset = vp_size / 2.0
	_overlay.scale = Vector2(0.01, 0.01)
	_overlay.modulate.a = 1.0
	var tween = create_tween()
	tween.tween_property(_overlay, "scale", Vector2.ONE, duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	await tween.finished
	if not is_inside_tree(): return

func _diamond_in(duration: float) -> void:
	var vp_size = get_viewport().get_visible_rect().size if get_viewport() else Vector2(1280, 720)
	_overlay.pivot_offset = vp_size / 2.0
	_overlay.scale = Vector2.ONE
	_overlay.modulate.a = 1.0
	var tween = create_tween()
	tween.tween_property(_overlay, "scale", Vector2(0.01, 0.01), duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	await tween.finished
	if not is_inside_tree(): return
	_overlay.modulate.a = 0.0
	_overlay.scale = Vector2.ONE
	_overlay.pivot_offset = Vector2.ZERO

func _flash_white_out(duration: float) -> void:
	_overlay.color = Color.WHITE
	_overlay.modulate.a = 0.0
	var tween = create_tween()
	tween.tween_property(_overlay, "modulate:a", 1.0, duration).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_IN)
	await tween.finished
	if not is_inside_tree(): return

func _flash_white_in(duration: float) -> void:
	_overlay.color = Color.WHITE
	var tween = create_tween()
	tween.tween_property(_overlay, "modulate:a", 0.0, duration).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
	await tween.finished
	if not is_inside_tree(): return

func _combat_entry_out(duration: float) -> void:
	## Fast red-tinted wipe for entering combat.
	_overlay.color = Color(0.15, 0.0, 0.0)
	_overlay.modulate.a = 0.0
	# Quick red flash first
	_flash_overlay.color = Color(1.0, 0.0, 0.0, 0.4)
	_flash_overlay.modulate.a = 0.6
	# BUG 12 FIX: Kill previous flash tween before creating a new one
	if _flash_tween and _flash_tween.is_valid():
		_flash_tween.kill()
	_flash_tween = create_tween()
	_flash_tween.tween_property(_flash_overlay, "modulate:a", 0.0, duration * 0.6)
	# Then dark overlay
	var tween = create_tween()
	tween.tween_property(_overlay, "modulate:a", 1.0, duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	await tween.finished
	if not is_inside_tree(): return

func _combat_entry_in(duration: float) -> void:
	_overlay.color = Color(0.15, 0.0, 0.0)
	var tween = create_tween()
	tween.tween_property(_overlay, "modulate:a", 0.0, duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	await tween.finished
	if not is_inside_tree(): return

# ==========================================================================
# HELPERS
# ==========================================================================

func _get_default_duration(style: TransitionStyle) -> float:
	match style:
		TransitionStyle.COMBAT_ENTRY:
			return COMBAT_ENTRY_DURATION
		TransitionStyle.COMBAT_EXIT:
			return COMBAT_EXIT_DURATION
		TransitionStyle.SHATTER:
			return CHAPTER_TRANSITION_DURATION
		_:
			return DEFAULT_DURATION


# ==========================================================================
# REGION/OVERWORLD TRAVEL HELPERS
# ==========================================================================

## Return to the overworld from any region or combat
func return_to_overworld(from_region: String = "") -> void:
	if has_node("/root/GameManager"):
		GameManager.set_meta("return_to_overworld_from", from_region)
	change_scene("res://scenes/overworld/overworld.tscn", TransitionStyle.FADE)


## Return to a specific region from combat
func return_to_region(region_scene: String, return_position: Vector2 = Vector2.ZERO) -> void:
	if has_node("/root/GameManager") and return_position != Vector2.ZERO:
		GameManager.set_return_point(region_scene, return_position)
	change_scene(region_scene, TransitionStyle.COMBAT_EXIT)


## Enter a region from the overworld
func enter_region(region_id: String) -> void:
	var path := ""
	if has_node("/root/GameManager"):
		if not GameManager.is_region_unlocked_for_free_travel(region_id):
			push_warning("[SceneTransitions] Free travel region locked: %s" % region_id)
			return
		path = GameManager.get_free_travel_revisit_scene(region_id)
	if path.is_empty():
		push_warning("[SceneTransitions] No safe revisit scene for free travel region: %s" % region_id)
		return
	if has_node("/root/GameManager"):
		GameManager.current_region = region_id
	change_scene(path, TransitionStyle.DIAMOND)
