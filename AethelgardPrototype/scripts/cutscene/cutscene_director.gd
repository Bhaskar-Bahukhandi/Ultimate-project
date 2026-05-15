extends Node
class_name CutsceneDirector

## ==========================================================================
## CUTSCENE DIRECTOR — Fluent command queue for cinematic sequences
## ==========================================================================
## Provides a builder-style API for constructing cutscenes at runtime.
## Supports sequential commands, parallel groups, actor automation,
## velocity-based movement, and camera direction — all in one clean API.
##
## Usage:
##   var dir = CutsceneDirector.new()
##   add_child(dir)
##   dir.setup(camera, characters_layer)
##   dir.fade_out(0.5)
##       .move_actor("Kaelen", Vector2(500, 400), 1.5)
##       .camera_follow("Kaelen", 2.0)
##       .say("Kaelen", "Where am I?")
##       .parallel([
##           dir.cmd_shake(8.0, 0.5),
##           dir.cmd_tint(Color(0.3, 0.3, 0.6), 0.5),
##       ])
##       .wait(1.0)
##       .fade_in(0.5)
##   await dir.play()
## ==========================================================================

signal director_started
signal director_finished
signal command_completed(command_name: String)

## ─── REFS ────────────────────────────────────────────────────────────
var _camera: CinematicCamera
var _characters: Node2D
var _cutscene_mgr: CutsceneManager  # Optional: reuse existing CM

## ─── COMMAND QUEUE ───────────────────────────────────────────────────
var _queue: Array[Dictionary] = []
var _is_playing: bool = false
var _is_cancelled: bool = false

## ─── ACTOR REGISTRY ──────────────────────────────────────────────────
## Tracks actors and their velocities for velocity-based movement
var _actors: Dictionary = {}  # name → {node, velocity, target, moving}

## ─── SETUP ───────────────────────────────────────────────────────────

func setup(cam: CinematicCamera = null, chars: Node2D = null, cm: CutsceneManager = null) -> CutsceneDirector:
	_camera = cam
	_characters = chars
	_cutscene_mgr = cm
	return self

func register_actor(actor_name: String, node: Node2D, speed: float = 120.0) -> CutsceneDirector:
	## Register an actor for velocity-based movement automation.
	_actors[actor_name] = {
		"node": node,
		"speed": speed,
		"velocity": Vector2.ZERO,
		"target": Vector2.ZERO,
		"moving": false
	}
	return self

## ==========================================================================
## FLUENT QUEUE BUILDERS — Return self for chaining
## ==========================================================================

func move_actor(actor_name: String, target: Vector2, duration: float = 1.0, ease_type: int = Tween.TRANS_SINE) -> CutsceneDirector:
	_queue.append({
		"cmd": "move_actor",
		"actor": actor_name,
		"target": target,
		"duration": duration,
		"ease": ease_type
	})
	return self

func move_actor_by_velocity(actor_name: String, target: Vector2) -> CutsceneDirector:
	## Move actor to target using their registered speed (velocity-based).
	_queue.append({
		"cmd": "move_actor_velocity",
		"actor": actor_name,
		"target": target,
	})
	return self

func enter_actor(actor_name: String, position: Vector2, from: String = "left", duration: float = 0.8) -> CutsceneDirector:
	_queue.append({
		"cmd": "enter_actor",
		"actor": actor_name,
		"position": position,
		"from": from,
		"duration": duration
	})
	return self

func exit_actor(actor_name: String, to: String = "left", duration: float = 0.5) -> CutsceneDirector:
	_queue.append({
		"cmd": "exit_actor",
		"actor": actor_name,
		"to": to,
		"duration": duration
	})
	return self

func face_actor(actor_name: String, direction: String = "right") -> CutsceneDirector:
	_queue.append({
		"cmd": "face_actor",
		"actor": actor_name,
		"direction": direction
	})
	return self

func say(speaker: String, text: String, auto_advance: bool = false) -> CutsceneDirector:
	_queue.append({
		"cmd": "dialogue",
		"speaker": speaker,
		"text": text,
		"auto_advance": auto_advance
	})
	return self

func wait(duration: float = 1.0) -> CutsceneDirector:
	_queue.append({"cmd": "wait", "duration": duration})
	return self

func camera_move(target: Vector2, duration: float = 1.0) -> CutsceneDirector:
	_queue.append({"cmd": "camera_move", "target": target, "duration": duration})
	return self

func camera_zoom(zoom_level: Vector2, duration: float = 1.0) -> CutsceneDirector:
	_queue.append({"cmd": "camera_zoom", "zoom": zoom_level, "duration": duration})
	return self

func camera_shake(intensity: float = 10.0, duration: float = 0.5) -> CutsceneDirector:
	_queue.append({"cmd": "camera_shake", "intensity": intensity, "duration": duration})
	return self

func camera_follow(actor_name: String, duration: float = -1.0) -> CutsceneDirector:
	## Camera follows actor. duration = -1 means indefinitely until next camera command.
	_queue.append({"cmd": "camera_follow", "actor": actor_name, "duration": duration})
	return self

func camera_stop_follow() -> CutsceneDirector:
	_queue.append({"cmd": "camera_stop_follow"})
	return self

func camera_dolly(target: Vector2, zoom_level: Vector2, duration: float = 2.0) -> CutsceneDirector:
	_queue.append({"cmd": "camera_dolly", "target": target, "zoom": zoom_level, "duration": duration})
	return self

func camera_dutch(angle: float, duration: float = 0.5) -> CutsceneDirector:
	_queue.append({"cmd": "camera_dutch", "angle": angle, "duration": duration})
	return self

func camera_whip(target: Vector2, duration: float = 0.3) -> CutsceneDirector:
	_queue.append({"cmd": "camera_whip", "target": target, "duration": duration})
	return self

func camera_push_in(amount: float = 0.3, duration: float = 1.5) -> CutsceneDirector:
	_queue.append({"cmd": "camera_push_in", "amount": amount, "duration": duration})
	return self

func camera_pull_out(amount: float = 0.3, duration: float = 1.5) -> CutsceneDirector:
	_queue.append({"cmd": "camera_pull_out", "amount": amount, "duration": duration})
	return self

func fade_out(duration: float = 1.0, color: Color = Color.BLACK) -> CutsceneDirector:
	_queue.append({"cmd": "fade", "fade_type": "out", "duration": duration, "color": color})
	return self

func fade_in(duration: float = 1.0, color: Color = Color.BLACK) -> CutsceneDirector:
	_queue.append({"cmd": "fade", "fade_type": "in", "duration": duration, "color": color})
	return self

func tint(color: Color, duration: float = 1.0) -> CutsceneDirector:
	_queue.append({"cmd": "tint", "color": color, "duration": duration})
	return self

func clear_tint(duration: float = 0.5) -> CutsceneDirector:
	_queue.append({"cmd": "tint", "clear": true, "duration": duration})
	return self

func letterbox_on(bar_height: float = 72.0, duration: float = 0.6) -> CutsceneDirector:
	_queue.append({"cmd": "letterbox", "enabled": true, "height": bar_height, "duration": duration})
	return self

func letterbox_off(duration: float = 0.4) -> CutsceneDirector:
	_queue.append({"cmd": "letterbox", "enabled": false, "duration": duration})
	return self

func flash(color: Color = Color.WHITE, duration: float = 0.5) -> CutsceneDirector:
	_queue.append({"cmd": "flash", "color": color, "duration": duration})
	return self

func play_music(track: String) -> CutsceneDirector:
	_queue.append({"cmd": "music", "action": "play", "track": track})
	return self

func stop_music(fade_out_duration: float = 1.0) -> CutsceneDirector:
	_queue.append({"cmd": "music", "action": "stop", "fade_out": fade_out_duration})
	return self

func play_sfx(path: String, volume: float = 0.0) -> CutsceneDirector:
	_queue.append({"cmd": "sfx", "path": path, "volume": volume})
	return self

func emit_effect(effect_name: String, params: Dictionary = {}) -> CutsceneDirector:
	_queue.append({"cmd": "custom_effect", "effect": effect_name, "params": params})
	return self

func call_method(object: Object, method_name: String, args: Array = []) -> CutsceneDirector:
	## Call any method on any object — equivalent to AnimationPlayer method tracks.
	_queue.append({"cmd": "call_method", "object": object, "method": method_name, "args": args})
	return self

func call_func(callable: Callable) -> CutsceneDirector:
	## Call a Callable (lambda or bound method).
	_queue.append({"cmd": "call_func", "callable": callable})
	return self

func title_card(title: String, subtitle: String = "", duration: float = 3.0) -> CutsceneDirector:
	_queue.append({"cmd": "title_card", "title": title, "subtitle": subtitle, "duration": duration})
	return self

func set_expression(actor_name: String, expression: String) -> CutsceneDirector:
	## Change actor expression/emotion frame (if sprite sheet supports it).
	_queue.append({"cmd": "expression", "actor": actor_name, "expression": expression})
	return self

## ─── PARALLEL GROUP ──────────────────────────────────────────────────

func parallel(commands: Array[Dictionary]) -> CutsceneDirector:
	## Execute multiple commands simultaneously.
	_queue.append({"cmd": "parallel", "commands": commands})
	return self

## Static helpers to build command dicts for parallel() without queueing
static func cmd_move(actor: String, target: Vector2, dur: float = 1.0) -> Dictionary:
	return {"cmd": "move_actor", "actor": actor, "target": target, "duration": dur, "ease": Tween.TRANS_SINE}

static func cmd_shake(intensity: float = 10.0, dur: float = 0.5) -> Dictionary:
	return {"cmd": "camera_shake", "intensity": intensity, "duration": dur}

static func cmd_tint(color: Color, dur: float = 1.0) -> Dictionary:
	return {"cmd": "tint", "color": color, "duration": dur}

static func cmd_zoom(zoom_level: Vector2, dur: float = 1.0) -> Dictionary:
	return {"cmd": "camera_zoom", "zoom": zoom_level, "duration": dur}

static func cmd_cam_move(target: Vector2, dur: float = 1.0) -> Dictionary:
	return {"cmd": "camera_move", "target": target, "duration": dur}

static func cmd_fade_out(dur: float = 1.0, color: Color = Color.BLACK) -> Dictionary:
	return {"cmd": "fade", "fade_type": "out", "duration": dur, "color": color}

static func cmd_fade_in(dur: float = 1.0, color: Color = Color.BLACK) -> Dictionary:
	return {"cmd": "fade", "fade_type": "in", "duration": dur, "color": color}

static func cmd_wait(dur: float = 1.0) -> Dictionary:
	return {"cmd": "wait", "duration": dur}

static func cmd_enter(actor: String, pos: Vector2, from: String = "left", dur: float = 0.8) -> Dictionary:
	return {"cmd": "enter_actor", "actor": actor, "position": pos, "from": from, "duration": dur}

static func cmd_flash(color: Color = Color.WHITE, dur: float = 0.5) -> Dictionary:
	return {"cmd": "flash", "color": color, "duration": dur}

## ==========================================================================
## PLAY — Execute the entire command queue
## ==========================================================================

func play() -> void:
	if _is_playing:
		push_warning("[CutsceneDirector] Already playing")
		return
	_is_playing = true
	_is_cancelled = false
	director_started.emit()

	# Block player input
	_block_input()

	for i in range(_queue.size()):
		if _is_cancelled or not is_inside_tree():
			break
		await _execute_command(_queue[i])
		if not is_inside_tree():
			break
		command_completed.emit(_queue[i].get("cmd", "unknown"))

	_unblock_input()
	_is_playing = false
	_queue.clear()
	director_finished.emit()

func cancel() -> void:
	_is_cancelled = true
	# Clean up visual overlays immediately to prevent stuck screen
	if _fade_overlay and is_instance_valid(_fade_overlay):
		_fade_overlay.visible = false
		_fade_overlay.color.a = 0.0
	if _canvas_modulate and is_instance_valid(_canvas_modulate):
		_canvas_modulate.queue_free()
		_canvas_modulate = null
	if has_node("/root/DialogueManager"):
		DialogueManager.force_reset()
	# Unblock player immediately so cancel + queue_free doesn't leave player disabled
	_unblock_input()

func _exit_tree() -> void:
	# Safety net: ensure player is unblocked if this node is removed mid-cutscene
	if _is_playing:
		_unblock_input()
	if _canvas_modulate and is_instance_valid(_canvas_modulate):
		_canvas_modulate.queue_free()
		_canvas_modulate = null

func is_playing() -> bool:
	return _is_playing

## ==========================================================================
## COMMAND EXECUTION ENGINE
## ==========================================================================

func _execute_command(cmd: Dictionary) -> void:
	var cmd_type = cmd.get("cmd", "")
	match cmd_type:
		"move_actor":
			await _exec_move_actor(cmd)
		"move_actor_velocity":
			await _exec_move_actor_velocity(cmd)
		"enter_actor":
			await _exec_enter_actor(cmd)
		"exit_actor":
			await _exec_exit_actor(cmd)
		"face_actor":
			_exec_face_actor(cmd)
		"dialogue":
			await _exec_dialogue(cmd)
		"wait":
			await get_tree().create_timer(cmd.get("duration", 1.0)).timeout
			if not is_inside_tree(): return
		"camera_move":
			await _exec_camera_move(cmd)
		"camera_zoom":
			await _exec_camera_zoom(cmd)
		"camera_shake":
			await _exec_camera_shake(cmd)
		"camera_follow":
			_exec_camera_follow(cmd)
		"camera_stop_follow":
			_exec_camera_stop_follow()
		"camera_dolly":
			await _exec_camera_dolly(cmd)
		"camera_dutch":
			await _exec_camera_dutch(cmd)
		"camera_whip":
			await _exec_camera_whip(cmd)
		"camera_push_in":
			await _exec_camera_push_in(cmd)
		"camera_pull_out":
			await _exec_camera_pull_out(cmd)
		"fade":
			await _exec_fade(cmd)
		"tint":
			await _exec_tint(cmd)
		"letterbox":
			await _exec_letterbox(cmd)
		"flash":
			await _exec_flash(cmd)
		"music":
			_exec_music(cmd)
		"sfx":
			_exec_sfx(cmd)
		"custom_effect":
			_exec_custom_effect(cmd)
		"call_method":
			await _exec_call_method(cmd)
		"call_func":
			await _exec_call_func(cmd)
		"title_card":
			await _exec_title_card(cmd)
		"expression":
			_exec_expression(cmd)
		"parallel":
			await _exec_parallel(cmd)
		_:
			push_warning("[CutsceneDirector] Unknown command: %s" % cmd_type)

## ==========================================================================
## COMMAND IMPLEMENTATIONS
## ==========================================================================

func _get_actor_node(actor_name: String) -> Node2D:
	## Find actor node from registry, characters container, or by name.
	if _actors.has(actor_name):
		return _actors[actor_name]["node"]
	if _characters:
		var node = _characters.get_node_or_null(actor_name)
		if node:
			return node
		# Try creating via AssetManager
		var created = AssetManager.create_character_sprite(actor_name)
		if created:
			_characters.add_child(created)
			return created
	return null

func _exec_move_actor(cmd: Dictionary) -> void:
	var actor = _get_actor_node(cmd.get("actor", ""))
	if not actor:
		return
	var target: Vector2 = cmd.get("target", Vector2.ZERO)
	var duration: float = cmd.get("duration", 1.0)
	var ease_type: int = cmd.get("ease", Tween.TRANS_SINE)

	# Walk animation
	var walk_dir = (target - actor.position).normalized()
	_start_walk_anim(actor, walk_dir)

	var tween = create_tween()
	tween.tween_property(actor, "position", target, duration).set_trans(ease_type).set_ease(Tween.EASE_IN_OUT)
	await tween.finished
	if not is_inside_tree(): return

	_stop_walk_anim(actor)

func _exec_move_actor_velocity(cmd: Dictionary) -> void:
	## Velocity-based movement: uses registered speed, calculates duration from distance.
	var actor_name: String = cmd.get("actor", "")
	var actor = _get_actor_node(actor_name)
	if not actor:
		return
	var target: Vector2 = cmd.get("target", Vector2.ZERO)
	var speed: float = 120.0
	if _actors.has(actor_name):
		speed = _actors[actor_name].get("speed", 120.0)
	var distance = actor.position.distance_to(target)
	var duration = distance / speed if speed > 0 else 1.0

	var walk_dir = (target - actor.position).normalized()
	_start_walk_anim(actor, walk_dir)

	var tween = create_tween()
	tween.tween_property(actor, "position", target, duration).set_trans(Tween.TRANS_LINEAR)
	await tween.finished
	if not is_inside_tree(): return

	_stop_walk_anim(actor)

func _exec_enter_actor(cmd: Dictionary) -> void:
	var actor_name: String = cmd.get("actor", "")
	var actor = _get_actor_node(actor_name)
	if not actor:
		return
	var position: Vector2 = cmd.get("position", Vector2.ZERO)
	var from: String = cmd.get("from", "left")
	var duration: float = cmd.get("duration", 0.8)

	var start_pos = position
	match from:
		"left": start_pos.x -= 200
		"right": start_pos.x += 200
		"top": start_pos.y -= 200
		"bottom": start_pos.y += 200

	actor.position = start_pos
	actor.visible = true
	actor.modulate.a = 0.0

	var walk_dir = (position - start_pos).normalized()
	_start_walk_anim(actor, walk_dir)

	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(actor, "position", position, duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(actor, "modulate:a", 1.0, duration * 0.5)
	await tween.finished
	if not is_inside_tree(): return

	_stop_walk_anim(actor)

func _exec_exit_actor(cmd: Dictionary) -> void:
	var actor = _get_actor_node(cmd.get("actor", ""))
	if not actor:
		return
	var to: String = cmd.get("to", "left")
	var duration: float = cmd.get("duration", 0.5)

	var target_pos = actor.position
	match to:
		"left": target_pos.x -= 200
		"right": target_pos.x += 200
		"top": target_pos.y -= 200
		"bottom": target_pos.y += 200

	var walk_dir = (target_pos - actor.position).normalized()
	_start_walk_anim(actor, walk_dir)

	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(actor, "position", target_pos, duration)
	tween.tween_property(actor, "modulate:a", 0.0, duration)
	await tween.finished
	if not is_inside_tree(): return

	actor.visible = false

func _exec_face_actor(cmd: Dictionary) -> void:
	var actor = _get_actor_node(cmd.get("actor", ""))
	if not actor:
		return
	var direction: String = cmd.get("direction", "right")
	var sprite = actor.get_node_or_null("Sprite")
	if not sprite:
		return
	var faces_left = sprite.get_meta("faces_left", false)
	match direction:
		"left":
			sprite.flip_h = !faces_left
		"right":
			sprite.flip_h = faces_left

func _exec_dialogue(cmd: Dictionary) -> void:
	var speaker: String = cmd.get("speaker", "")
	var text: String = cmd.get("text", "")
	var auto_advance: bool = cmd.get("auto_advance", false)
	await DialogueManager.say(speaker, text, Color(-1, -1, -1), auto_advance)
	if not is_inside_tree(): return

func _exec_camera_move(cmd: Dictionary) -> void:
	if not _camera: return
	_camera.move_to(cmd.get("target", Vector2.ZERO), cmd.get("duration", 1.0))
	await _camera.camera_move_finished
	if not is_inside_tree(): return

func _exec_camera_zoom(cmd: Dictionary) -> void:
	if not _camera: return
	_camera.zoom_to(cmd.get("zoom", Vector2.ONE), cmd.get("duration", 1.0))
	await _camera.zoom_finished
	if not is_inside_tree(): return

func _exec_camera_shake(cmd: Dictionary) -> void:
	if not _camera: return
	_camera.shake(cmd.get("intensity", 10.0), cmd.get("duration", 0.5))
	await _camera.shake_finished
	if not is_inside_tree(): return

## ─── CAMERA FOLLOW ───────────────────────────────────────────────────
var _follow_target_name: String = ""
var _follow_active: bool = false

func _exec_camera_follow(cmd: Dictionary) -> void:
	if not _camera: return
	_follow_target_name = cmd.get("actor", "")
	_follow_active = true
	_camera.set_meta("follow_target", _follow_target_name)
	# If duration > 0, wait then stop follow
	var dur: float = cmd.get("duration", -1.0)
	if dur > 0:
		await get_tree().create_timer(dur).timeout
		if not is_inside_tree(): return
		_follow_active = false

func _exec_camera_stop_follow() -> void:
	_follow_active = false
	_follow_target_name = ""

func _process(delta: float) -> void:
	if _follow_active and _camera and _follow_target_name != "":
		var actor = _get_actor_node(_follow_target_name)
		if actor:
			_camera.global_position = _camera.global_position.lerp(
				actor.global_position, _camera.smooth_speed * delta
			)

func _exec_camera_dolly(cmd: Dictionary) -> void:
	if not _camera: return
	await _camera.dolly_shot(cmd.get("target", Vector2.ZERO), cmd.get("zoom", Vector2.ONE), cmd.get("duration", 2.0))
	if not is_inside_tree(): return

func _exec_camera_dutch(cmd: Dictionary) -> void:
	if not _camera: return
	await _camera.dutch_angle(cmd.get("angle", 0.0), cmd.get("duration", 0.5))
	if not is_inside_tree(): return

func _exec_camera_whip(cmd: Dictionary) -> void:
	if not _camera: return
	await _camera.whip_pan(cmd.get("target", Vector2.ZERO), cmd.get("duration", 0.3))
	if not is_inside_tree(): return

func _exec_camera_push_in(cmd: Dictionary) -> void:
	if not _camera: return
	await _camera.push_in(cmd.get("amount", 0.3), cmd.get("duration", 1.5))
	if not is_inside_tree(): return

func _exec_camera_pull_out(cmd: Dictionary) -> void:
	if not _camera: return
	await _camera.pull_out(cmd.get("amount", 0.3), cmd.get("duration", 1.5))
	if not is_inside_tree(): return

## ─── FADE ────────────────────────────────────────────────────────────
var _fade_layer: CanvasLayer
var _fade_overlay: ColorRect

func _ensure_fade_overlay() -> void:
	if _fade_overlay:
		return
	_fade_layer = CanvasLayer.new()
	_fade_layer.layer = 99
	_fade_layer.name = "DirectorFadeLayer"
	add_child(_fade_layer)
	_fade_overlay = ColorRect.new()
	_fade_overlay.name = "DirectorFadeRect"
	_fade_overlay.color = Color(0, 0, 0, 0)
	_fade_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	_fade_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fade_overlay.visible = false
	_fade_layer.add_child(_fade_overlay)

func _exec_fade(cmd: Dictionary) -> void:
	_ensure_fade_overlay()
	var fade_type: String = cmd.get("fade_type", "out")
	var duration: float = cmd.get("duration", 1.0)
	var color: Color = cmd.get("color", Color.BLACK)

	_fade_overlay.color = Color(color.r, color.g, color.b, 0.0 if fade_type == "out" else 1.0)
	_fade_overlay.visible = true
	var target_alpha = 1.0 if fade_type == "out" else 0.0
	var tween = create_tween()
	tween.tween_property(_fade_overlay, "color:a", target_alpha, duration)
	await tween.finished
	if not is_inside_tree(): return
	if fade_type == "in":
		_fade_overlay.visible = false

## ─── TINT (CanvasModulate) ───────────────────────────────────────────
var _canvas_modulate: CanvasModulate

func _exec_tint(cmd: Dictionary) -> void:
	var duration: float = cmd.get("duration", 1.0)
	var clear: bool = cmd.get("clear", false)

	if not _canvas_modulate:
		_canvas_modulate = CanvasModulate.new()
		_canvas_modulate.name = "DirectorTint"
		get_tree().current_scene.add_child(_canvas_modulate)

	if clear:
		var tween = create_tween()
		tween.tween_property(_canvas_modulate, "color", Color.WHITE, duration)
		await tween.finished
		if not is_inside_tree(): return
		if is_instance_valid(_canvas_modulate):
			_canvas_modulate.queue_free()
			_canvas_modulate = null
	else:
		var target_color: Color = cmd.get("color", Color(0.5, 0.5, 0.8))
		var tween = create_tween()
		tween.tween_property(_canvas_modulate, "color", target_color, duration)
		await tween.finished
		if not is_inside_tree(): return

## ─── LETTERBOX ───────────────────────────────────────────────────────

func _exec_letterbox(cmd: Dictionary) -> void:
	if not _camera: return
	if cmd.get("enabled", true):
		await _camera.enable_letterbox(cmd.get("height", 72.0), cmd.get("duration", 0.6))
	else:
		await _camera.disable_letterbox(cmd.get("duration", 0.4))
	if not is_inside_tree(): return

## ─── FLASH ───────────────────────────────────────────────────────────

func _exec_flash(cmd: Dictionary) -> void:
	var color: Color = cmd.get("color", Color.WHITE)
	var duration: float = cmd.get("duration", 0.5)

	var flash_layer = CanvasLayer.new()
	flash_layer.layer = 101  # Above dialogue (100) so flashes are visible over dialogue
	add_child(flash_layer)
	var flash = ColorRect.new()
	flash.color = color
	flash.set_anchors_preset(Control.PRESET_FULL_RECT)
	flash.modulate.a = 0.0
	flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	flash_layer.add_child(flash)

	var tween = create_tween()
	tween.tween_property(flash, "modulate:a", 0.9, duration * 0.25)
	tween.tween_property(flash, "modulate:a", 0.0, duration * 0.75)
	await tween.finished
	if not is_inside_tree(): return
	flash_layer.queue_free()

## ─── MUSIC / SFX ─────────────────────────────────────────────────────

func _exec_music(cmd: Dictionary) -> void:
	var action: String = cmd.get("action", "play")
	if action == "play":
		var track: String = cmd.get("track", "")
		if track != "" and has_node("/root/MusicManager"):
			MusicManager.play_track(track)
	elif action == "stop":
		if has_node("/root/MusicManager"):
			MusicManager.stop(cmd.get("fade_out", true))

func _exec_sfx(cmd: Dictionary) -> void:
	var path: String = cmd.get("path", "")
	if path == "" or not ResourceLoader.exists(path):
		return
	var player = AudioStreamPlayer.new()
	player.stream = load(path)
	player.volume_db = cmd.get("volume", 0.0)
	player.bus = "SFX"
	add_child(player)
	player.play()
	player.finished.connect(player.queue_free)

## ─── CUSTOM EFFECT ───────────────────────────────────────────────────

func _exec_custom_effect(cmd: Dictionary) -> void:
	if _cutscene_mgr:
		_cutscene_mgr.custom_effect.emit(cmd.get("effect", ""), cmd.get("params", {}))

## ─── CALL METHOD (AnimationPlayer method track equivalent) ───────────

func _exec_call_method(cmd: Dictionary) -> void:
	var obj: Object = cmd.get("object", null)
	var method_name: String = cmd.get("method", "")
	var args: Array = cmd.get("args", [])
	if not is_instance_valid(obj) or method_name.is_empty():
		return
	if obj.has_method(method_name):
		var result = obj.callv(method_name, args)
		# If result is a coroutine, await it
		if result is Signal:
			await result

func _exec_call_func(cmd: Dictionary) -> void:
	var callable: Callable = cmd.get("callable", Callable())
	if callable.is_valid():
		var result = callable.call()
		if result is Signal:
			await result

## ─── TITLE CARD ──────────────────────────────────────────────────────

func _exec_title_card(cmd: Dictionary) -> void:
	var title_text: String = cmd.get("title", "")
	var subtitle_text: String = cmd.get("subtitle", "")
	var duration: float = cmd.get("duration", 3.0)

	var layer = CanvasLayer.new()
	layer.layer = 95
	add_child(layer)

	var container = CenterContainer.new()
	container.set_anchors_preset(Control.PRESET_FULL_RECT)
	container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(container)

	var vbox = VBoxContainer.new()
	vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	container.add_child(vbox)

	var title_label = Label.new()
	title_label.text = title_text
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.add_theme_font_size_override("font_size", 48)
	title_label.add_theme_color_override("font_color", Color(1, 0.95, 0.8))
	title_label.modulate.a = 0.0
	vbox.add_child(title_label)

	if subtitle_text != "":
		var sub_label = Label.new()
		sub_label.text = subtitle_text
		sub_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		sub_label.add_theme_font_size_override("font_size", 24)
		sub_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.8))
		sub_label.modulate.a = 0.0
		vbox.add_child(sub_label)

	# Fade in title
	var tween = create_tween()
	tween.tween_property(title_label, "modulate:a", 1.0, 0.8).set_trans(Tween.TRANS_SINE)
	if vbox.get_child_count() > 1:
		tween.tween_property(vbox.get_child(1), "modulate:a", 1.0, 0.6).set_trans(Tween.TRANS_SINE)
	tween.tween_interval(max(duration - 2.0, 0.0))
	# Fade out
	tween.tween_property(title_label, "modulate:a", 0.0, 0.6)
	if vbox.get_child_count() > 1:
		tween.tween_property(vbox.get_child(1), "modulate:a", 0.0, 0.4)
	await tween.finished
	if not is_inside_tree(): return
	layer.queue_free()

## ─── EXPRESSION ──────────────────────────────────────────────────────

func _exec_expression(cmd: Dictionary) -> void:
	var actor = _get_actor_node(cmd.get("actor", ""))
	if not actor:
		return
	var expr: String = cmd.get("expression", "neutral")
	# If actor has a method to set expressions, call it
	if actor.has_method("set_expression"):
		actor.call("set_expression", expr)
	else:
		# Try to find AnimatedSprite2D child and set animation
		var anim_sprite = actor.get_node_or_null("AnimatedSprite2D")
		if anim_sprite and anim_sprite is AnimatedSprite2D:
			if anim_sprite.sprite_frames and anim_sprite.sprite_frames.has_animation(expr):
				anim_sprite.play(expr)

## ─── PARALLEL EXECUTION ──────────────────────────────────────────────

func _exec_parallel(cmd: Dictionary) -> void:
	var commands: Array = cmd.get("commands", [])
	if commands.is_empty():
		return
	# Use remaining counter + polling (same proven pattern as CutsceneManager)
	# GDScript coroutines called without await return null, so collecting and
	# awaiting return values does NOT wait for completion.
	var counter = [commands.size()]
	for c in commands:
		_run_parallel_cmd(c, func(): counter[0] -= 1)
	# Poll until all parallel commands complete
	var timeout_elapsed: float = 0.0
	while counter[0] > 0:
		await get_tree().create_timer(0.05).timeout
		if not is_inside_tree(): return
		if _is_cancelled: return
		timeout_elapsed += 0.05
		if timeout_elapsed >= 30.0:
			push_warning("[CutsceneDirector] Parallel commands timed out after 30s")
			return

func _run_parallel_cmd(cmd: Dictionary, on_done: Callable) -> void:
	## Helper: runs a single command then calls on_done when finished.
	await _execute_command(cmd)
	on_done.call()

## ─── INPUT BLOCKING ──────────────────────────────────────────────────
var _pre_process_modes: Dictionary = {}

func _block_input() -> void:
	var players = get_tree().get_nodes_in_group("player")
	for player in players:
		_pre_process_modes[player] = player.process_mode
		player.process_mode = Node.PROCESS_MODE_DISABLED

	# Block pause menu
	if has_node("/root/PauseScreen"):
		PauseScreen.set_meta("cutscene_blocked", true)

func _unblock_input() -> void:
	for node in _pre_process_modes.keys():
		if is_instance_valid(node):
			node.process_mode = _pre_process_modes[node]
	_pre_process_modes.clear()

	if has_node("/root/PauseScreen"):
		PauseScreen.set_meta("cutscene_blocked", false)

	# Clean up tint
	if _canvas_modulate and is_instance_valid(_canvas_modulate):
		_canvas_modulate.queue_free()
		_canvas_modulate = null

## ─── ANIMATION HELPERS (shared with CutsceneManager) ─────────────────

func _start_walk_anim(character: Node2D, direction: Vector2) -> void:
	var sprite = character.get_node_or_null("Sprite")
	if not sprite:
		return
	if sprite is Sprite2D:
		var faces_left = sprite.get_meta("faces_left", false)
		if faces_left:
			sprite.flip_h = direction.x >= 0
		else:
			sprite.flip_h = direction.x < 0
	var dir_sign = 1.0 if direction.x >= 0 else -1.0
	TweenAnimator.play_cutscene_walk(sprite, dir_sign)

func _stop_walk_anim(character: Node2D) -> void:
	var sprite = character.get_node_or_null("Sprite")
	if not sprite:
		return
	TweenAnimator.play_cutscene_idle(sprite)
