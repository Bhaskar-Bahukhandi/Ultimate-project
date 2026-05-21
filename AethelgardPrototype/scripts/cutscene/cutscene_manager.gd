extends Node
class_name CutsceneManager

## ==========================================================================
## CUTSCENE MANAGER — Enhanced beat-based cinematic system
## ==========================================================================
## Features:
##   - 16 beat types (camera, dialogue, characters, effects, audio, etc.)
##   - Dedicated input blocking during cutscenes
##   - Audio beat type for BGM/SFX during cinematics
##   - CanvasModulate scene tinting and fades
##   - Area2D trigger helper for world-placed cutscene zones
##   - NPC automation (walk paths, face directions)
##   - Smooth player control transition in/out
## ==========================================================================

signal cutscene_started
signal cutscene_finished
signal beat_finished(beat_name: String)
signal custom_effect(effect_name: String, parameters: Dictionary)

@export var camera: CinematicCamera
@export var dialogue_box: Control
@export var characters_container: Node2D

var is_playing: bool = false
var current_cutscene: Dictionary
var current_beat_index: int = 0
var paused: bool = false

## ─── INPUT BLOCKING ──────────────────────────────────────────────────
var _input_blocked: bool = false
var _pre_cutscene_process_mode: Dictionary = {}  # node → original process_mode

## ─── AUDIO ───────────────────────────────────────────────────────────
var _audio_player: AudioStreamPlayer = null
var _sfx_player: AudioStreamPlayer = null

## ─── SCREEN TINT (CanvasModulate) ────────────────────────────────────
var _canvas_modulate: CanvasModulate = null

## ─── FADE OVERLAY ────────────────────────────────────────────────────
var _fade_overlay: ColorRect = null
var _fade_layer: CanvasLayer = null

func _ready() -> void:
	# Create audio players
	_audio_player = AudioStreamPlayer.new()
	_audio_player.name = "CutsceneBGM"
	_audio_player.bus = "Music"
	add_child(_audio_player)
	
	_sfx_player = AudioStreamPlayer.new()
	_sfx_player.name = "CutsceneSFX"
	_sfx_player.bus = "SFX"
	add_child(_sfx_player)
	
	# Create fade overlay (CanvasLayer so it renders on top)
	_fade_layer = CanvasLayer.new()
	_fade_layer.layer = 99
	_fade_layer.name = "FadeLayer"
	add_child(_fade_layer)
	
	_fade_overlay = ColorRect.new()
	_fade_overlay.name = "FadeRect"
	_fade_overlay.color = Color(0, 0, 0, 0)
	_fade_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	_fade_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fade_overlay.visible = false
	_fade_layer.add_child(_fade_overlay)

## ─── TRIGGER HELPER ──────────────────────────────────────────────────

## Create an Area2D trigger that starts a cutscene when the player enters.
## Attach the returned Area2D as a child of a scene node positioned where desired.
static func create_trigger(cutscene_data: Dictionary, trigger_size: Vector2 = Vector2(64, 64), one_shot: bool = true) -> Area2D:
	var area = Area2D.new()
	area.name = "CutsceneTrigger"
	area.collision_layer = 0
	area.collision_mask = 2  # Player layer
	area.set_meta("cutscene_data", cutscene_data)
	area.set_meta("one_shot", one_shot)
	area.set_meta("triggered", false)
	
	var shape = CollisionShape2D.new()
	var rect = RectangleShape2D.new()
	rect.size = trigger_size
	shape.shape = rect
	area.add_child(shape)
	
	area.body_entered.connect(func(body):
		if not body.is_in_group("player"):
			return
		if area.get_meta("one_shot") and area.get_meta("triggered"):
			return
		area.set_meta("triggered", true)
		# Find CutsceneManager in the tree
		var cm = area.get_node_or_null("../CutsceneManager")
		if not cm:
			# Try to find it up the tree
			var parent = area.get_parent()
			while parent:
				cm = parent.get_node_or_null("CutsceneManager")
				if cm:
					break
				parent = parent.get_parent()
		if cm and cm is CutsceneManager:
			cm.play_cutscene(area.get_meta("cutscene_data"))
		else:
			push_warning("[CUTSCENE TRIGGER] No CutsceneManager found in tree")
	)
	
	return area

## ─── PLAY CUTSCENE ───────────────────────────────────────────────────

var _pre_cutscene_state: int = -1  # GameState before cutscene started

func play_cutscene(cutscene_data: Dictionary) -> void:
	if is_playing:
		push_warning("Cutscene already playing!")
		return
	
	is_playing = true
	current_cutscene = cutscene_data
	current_beat_index = 0
	
	# Save and set game state to CUTSCENE
	if has_node("/root/GameManager"):
		_pre_cutscene_state = GameManager.current_state
		GameManager.change_state(GameManager.GameState.CUTSCENE)
	
	# Block player input
	if cutscene_data.get("block_input", true):
		_block_input()
	
	cutscene_started.emit()
	
	print("[CUTSCENE] Starting: ", cutscene_data.get("name", "Unnamed"))
	
	await process_beats()
	if not is_inside_tree(): return
	
	# Auto-save if this was a chapter transition cutscene
	if cutscene_data.get("auto_save", false) and has_node("/root/GameManager"):
		GameManager.auto_save()
	
	# Restore input
	_unblock_input()
	
	# Restore game state to what it was before the cutscene (default to EXPLORATION)
	if has_node("/root/GameManager"):
		var restore_state = _pre_cutscene_state if _pre_cutscene_state >= 0 else GameManager.GameState.EXPLORATION
		# Don't restore MENU or GAME_OVER — use EXPLORATION instead
		if restore_state in [GameManager.GameState.MENU, GameManager.GameState.GAME_OVER]:
			restore_state = GameManager.GameState.EXPLORATION
		GameManager.change_state(restore_state)
		_pre_cutscene_state = -1
	
	is_playing = false
	cutscene_finished.emit()
	print("[CUTSCENE] Finished")

## ─── PROCESS BEATS ───────────────────────────────────────────────────

func process_beats() -> void:
	var beats = current_cutscene.get("beats", [])
	
	for i in range(beats.size()):
		if not is_playing or paused:
			break
		
		current_beat_index = i
		var beat = beats[i]
		await process_beat(beat)
		if not is_inside_tree(): return
		beat_finished.emit(beat.get("name", "beat_%d" % i))

func process_beat(beat: Dictionary) -> void:
	var beat_type = beat.get("type", "wait")
	
	print("[CUTSCENE BEAT] Type: %s" % beat_type)
	
	match beat_type:
		"camera_move":
			await handle_camera_move(beat)
		"camera_shake":
			await handle_camera_shake(beat)
		"camera_zoom":
			await handle_camera_zoom(beat)
		"character_enter":
			await handle_character_enter(beat)
		"character_exit":
			await handle_character_exit(beat)
		"character_move":
			await handle_character_move(beat)
		"dialogue":
			await handle_dialogue(beat)
		"wait":
			await handle_wait(beat)
		"parallel":
			await handle_parallel(beat)
		"effect":
			await handle_effect(beat)
		"fade":
			await handle_fade(beat)
		"custom":
			await handle_custom(beat)
		# ── NEW BEAT TYPES ──
		"audio":
			await handle_audio(beat)
		"tint":
			await handle_tint(beat)
		"npc_walk":
			await handle_npc_walk(beat)
		"npc_face":
			handle_npc_face(beat)
		# ── EXTENDED BEAT TYPES ──
		"letterbox":
			await handle_letterbox(beat)
		"music":
			handle_music(beat)
		"camera_follow":
			await handle_camera_follow(beat)
		"camera_dolly":
			await handle_camera_dolly(beat)
		"camera_whip":
			await handle_camera_whip(beat)
		"expression":
			handle_expression(beat)
		"background":
			await handle_background(beat)
		"title_card":
			await handle_title_card(beat)
		"call_method":
			await handle_call_method(beat)
		_:
			push_warning("[CUTSCENE] Unknown beat type: %s" % beat_type)
			await get_tree().create_timer(0.1).timeout
	
	if not is_inside_tree(): return

## ─── EXISTING BEAT HANDLERS ──────────────────────────────────────────

func handle_camera_move(beat: Dictionary) -> void:
	if not camera:
		return
	var target = beat.get("target", Vector2.ZERO)
	var duration = beat.get("duration", 1.0)
	camera.move_to(target, duration)
	await camera.camera_move_finished
	if not is_inside_tree(): return

func handle_camera_shake(beat: Dictionary) -> void:
	if not camera:
		return
	var intensity = beat.get("intensity", 10.0)
	var duration = beat.get("duration", 0.5)
	camera.shake(intensity, duration)
	await camera.shake_finished
	if not is_inside_tree(): return

func handle_camera_zoom(beat: Dictionary) -> void:
	if not camera:
		return
	var zoom_level = beat.get("zoom", Vector2.ONE)
	var duration = beat.get("duration", 1.0)
	camera.zoom_to(zoom_level, duration)
	await camera.zoom_finished
	if not is_inside_tree(): return

func handle_character_enter(beat: Dictionary) -> void:
	var character_name = beat.get("character", "")
	var position = beat.get("position", Vector2.ZERO)
	var duration = beat.get("duration", 0.5)
	var from_side = beat.get("from", "left")
	
	var character = get_or_create_character(character_name)
	if not character:
		return
	
	var start_pos = position
	match from_side:
		"left":
			start_pos.x -= 200
		"right":
			start_pos.x += 200
		"top":
			start_pos.y -= 200
		"bottom":
			start_pos.y += 200
	
	character.position = start_pos
	character.visible = true
	
	# Start walk animation while entering
	var walk_dir = (position - start_pos).normalized()
	_start_walk_anim(character, walk_dir)
	
	var tween = create_tween()
	tween.tween_property(character, "position", position, duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(character, "modulate:a", 1.0, duration * 0.5)
	await tween.finished
	if not is_inside_tree(): return
	
	# Switch to idle once arrived
	_stop_walk_anim(character)

func handle_character_exit(beat: Dictionary) -> void:
	var character_name = beat.get("character", "")
	var duration = beat.get("duration", 0.5)
	var to_side = beat.get("to", "left")
	
	var character = find_character(character_name)
	if not character:
		return
	
	var target_pos = character.position
	match to_side:
		"left":
			target_pos.x -= 200
		"right":
			target_pos.x += 200
		"top":
			target_pos.y -= 200
		"bottom":
			target_pos.y += 200
	
	# Start walk animation while exiting
	var walk_dir = (target_pos - character.position).normalized()
	_start_walk_anim(character, walk_dir)
	
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(character, "position", target_pos, duration)
	tween.tween_property(character, "modulate:a", 0.0, duration)
	await tween.finished
	if not is_inside_tree(): return
	
	character.visible = false

func handle_character_move(beat: Dictionary) -> void:
	var character_name = beat.get("character", "")
	var target = beat.get("target", Vector2.ZERO)
	var duration = beat.get("duration", 1.0)
	
	var character = find_character(character_name)
	if not character:
		return
	
	# Start walk animation while moving
	var walk_dir = (target - character.position).normalized()
	_start_walk_anim(character, walk_dir)
	
	var tween = create_tween()
	tween.tween_property(character, "position", target, duration).set_trans(Tween.TRANS_SINE)
	await tween.finished
	if not is_inside_tree(): return
	
	# Switch to idle once arrived
	_stop_walk_anim(character)

func handle_dialogue(beat: Dictionary) -> void:
	var speaker = beat.get("speaker", "")
	var text = beat.get("text", "")
	var auto_advance = beat.get("auto_advance", false)
	var color_override = beat.get("color", Color(-1, -1, -1))
	
	print("[DIALOGUE] Speaker: %s" % speaker)
	print("[DIALOGUE] Text: %s" % text)
	
	await DialogueManager.say(speaker, text, color_override, auto_advance)
	if not is_inside_tree(): return

func handle_wait(beat: Dictionary) -> void:
	var duration = beat.get("duration", 1.0)
	await get_tree().create_timer(duration).timeout
	if not is_inside_tree(): return

func handle_parallel(beat: Dictionary) -> void:
	var sub_beats = beat.get("beats", [])
	if sub_beats.size() == 0:
		return
	# Run all sub-beats concurrently using signal-based completion tracking
	var counter = [sub_beats.size()]  # Use array to avoid confusable capture reassignment
	var timeout_elapsed = 0.0
	var MAX_PARALLEL_TIMEOUT = 30.0  # Safety: 30 second max
	for sub_beat in sub_beats:
		# Fire-and-forget each sub-beat as a deferred coroutine
		_run_parallel_beat(sub_beat, func(): counter[0] -= 1)
	# Poll until all sub-beats complete
	while counter[0] > 0:
		await get_tree().create_timer(0.05).timeout
		if not is_inside_tree(): return
		if not is_playing:  # Cutscene was skipped
			return
		timeout_elapsed += 0.05
		if timeout_elapsed >= MAX_PARALLEL_TIMEOUT:
			push_warning("[CUTSCENE] Parallel beat timed out after %.0fs" % MAX_PARALLEL_TIMEOUT)
			return

func _run_parallel_beat(beat: Dictionary, on_done: Callable) -> void:
	## Helper: runs a single beat then calls on_done when finished.
	await process_beat(beat)
	on_done.call()

func handle_effect(beat: Dictionary) -> void:
	var effect_type = beat.get("effect", "flash")
	var duration = beat.get("duration", 0.5)
	
	match effect_type:
		"flash":
			await create_flash_effect(beat.get("color", Color.WHITE), duration)
			if not is_inside_tree(): return
		"shake_screen":
			if camera:
				camera.shake(beat.get("intensity", 10.0), duration)
				await camera.shake_finished
				if not is_inside_tree(): return
		"glitch_screen":
			custom_effect.emit("glitch_screen", beat)
			await get_tree().create_timer(duration).timeout
			if not is_inside_tree(): return
		"trigger_turbulence_light":
			custom_effect.emit("trigger_turbulence_light", beat)
			await get_tree().create_timer(duration).timeout
			if not is_inside_tree(): return
		_:
			custom_effect.emit(effect_type, beat)
			await get_tree().create_timer(duration).timeout
			if not is_inside_tree(): return

func handle_fade(beat: Dictionary) -> void:
	var fade_type = beat.get("fade_type", "out")
	var duration = beat.get("duration", 1.0)
	var color = beat.get("color", Color.BLACK)
	
	_fade_overlay.color = Color(color.r, color.g, color.b, 0.0 if fade_type == "out" else 1.0)
	_fade_overlay.visible = true
	_fade_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	var target_alpha = 1.0 if fade_type == "out" else 0.0
	var tween = create_tween()
	tween.tween_property(_fade_overlay, "color:a", target_alpha, duration)
	await tween.finished
	if not is_inside_tree(): return
	
	if fade_type == "in":
		_fade_overlay.visible = false

func handle_custom(beat: Dictionary) -> void:
	var callback = beat.get("callback", "")
	
	if callback.is_empty():
		push_warning("[CUSTOM BEAT] No callback specified")
		return
	
	var parent = get_parent()
	if parent and parent.has_method(callback):
		print("[CUSTOM BEAT] Calling %s()" % callback)
		await parent.call(callback)
		if not is_inside_tree(): return
	else:
		push_warning("[CUSTOM BEAT] Callback not found: %s" % callback)

## ─── NEW BEAT: AUDIO ─────────────────────────────────────────────────
## Usage:
##   {"type": "audio", "action": "play_bgm", "path": "res://audio/bgm.ogg", "volume": -5.0}
##   {"type": "audio", "action": "stop_bgm", "fade_out": 1.0}
##   {"type": "audio", "action": "play_sfx", "path": "res://audio/thunder.ogg"}

func handle_audio(beat: Dictionary) -> void:
	var action = beat.get("action", "play_bgm")
	
	match action:
		"play_bgm":
			var path = beat.get("path", "")
			if path != "" and ResourceLoader.exists(path):
				_audio_player.stream = load(path)
				_audio_player.volume_db = beat.get("volume", 0.0)
				_audio_player.play()
			elif path != "":
				push_warning("[CUTSCENE AUDIO] BGM not found: %s" % path)
			# If MusicManager exists, optionally crossfade
			if beat.get("use_music_manager", false) and has_node("/root/MusicManager"):
				var track = beat.get("track", "")
				if track != "":
					MusicManager.play_track(track)
		
		"stop_bgm":
			var fade_out = beat.get("fade_out", 0.0)
			if fade_out > 0 and _audio_player.playing:
				var tween = create_tween()
				tween.tween_property(_audio_player, "volume_db", -40.0, fade_out)
				await tween.finished
				if not is_inside_tree(): return
				_audio_player.stop()
			else:
				_audio_player.stop()
		
		"play_sfx":
			var path = beat.get("path", "")
			var sfx_name = beat.get("sfx", "")
			# Priority: file path > SFXManager procedural > skip
			if sfx_name != "" and has_node("/root/SFXManager"):
				SFXManager.play(sfx_name)
			elif path != "" and ResourceLoader.exists(path):
				_sfx_player.stream = load(path)
				_sfx_player.volume_db = beat.get("volume", 0.0)
				_sfx_player.play()
			elif path != "":
				push_warning("[CUTSCENE AUDIO] SFX not found: %s" % path)
		
		_:
			push_warning("[CUTSCENE AUDIO] Unknown action: %s" % action)
	
	# Audio beats are instant unless they have a wait
	var wait = beat.get("wait", 0.0)
	if wait > 0:
		await get_tree().create_timer(wait).timeout
		if not is_inside_tree(): return

## ─── NEW BEAT: TINT (CanvasModulate) ─────────────────────────────────
## Usage:
##   {"type": "tint", "color": Color(0.3, 0.3, 0.6), "duration": 1.0}
##   {"type": "tint", "clear": true, "duration": 0.5}

func handle_tint(beat: Dictionary) -> void:
	var duration = beat.get("duration", 1.0)
	var clear = beat.get("clear", false)
	
	if not _canvas_modulate:
		_canvas_modulate = CanvasModulate.new()
		_canvas_modulate.name = "CutsceneTint"
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
		var target_color = beat.get("color", Color(0.5, 0.5, 0.8))
		if target_color is Array:
			target_color = Color(target_color[0], target_color[1], target_color[2])
		var tween = create_tween()
		tween.tween_property(_canvas_modulate, "color", target_color, duration)
		await tween.finished
		if not is_inside_tree(): return

## ─── NEW BEAT: NPC WALK ──────────────────────────────────────────────
## Usage:
##   {"type": "npc_walk", "character": "Guard", "target": Vector2(500, 300), "speed": 80.0}

func handle_npc_walk(beat: Dictionary) -> void:
	var character_name = beat.get("character", "")
	var target = beat.get("target", Vector2.ZERO)
	var speed = beat.get("speed", 80.0)
	
	var character = find_character(character_name)
	if not character:
		character = get_or_create_character(character_name)
	if not character:
		return
	
	var distance = character.position.distance_to(target)
	var duration = distance / speed if speed > 0 else 1.0
	
	# Start walk animation (handles sprite flipping too)
	var dir = (target - character.position).normalized()
	_start_walk_anim(character, dir)
	
	var tween = create_tween()
	tween.tween_property(character, "position", target, duration).set_trans(Tween.TRANS_LINEAR)
	await tween.finished
	if not is_inside_tree(): return
	
	# Switch to idle once arrived
	_stop_walk_anim(character)

## ─── NEW BEAT: NPC FACE ──────────────────────────────────────────────
## Usage:
##   {"type": "npc_face", "character": "Guard", "direction": "left"}

func handle_npc_face(beat: Dictionary) -> void:
	var character_name = beat.get("character", "")
	var direction = beat.get("direction", "right")
	
	var character = find_character(character_name)
	if not character:
		return
	
	if character.has_node("Sprite"):
		var sprite = character.get_node("Sprite")
		var faces_left = sprite.get_meta("faces_left", false)
		match direction:
			"left":
				sprite.flip_h = !faces_left
			"right":
				sprite.flip_h = faces_left

## ─── EXTENDED BEAT: LETTERBOX ────────────────────────────────────────
## Usage:
##   {"type": "letterbox", "enabled": true, "height": 72.0, "duration": 0.6}
##   {"type": "letterbox", "enabled": false, "duration": 0.4}

func handle_letterbox(beat: Dictionary) -> void:
	if not camera:
		return
	if beat.get("enabled", true):
		await camera.enable_letterbox(beat.get("height", 72.0), beat.get("duration", 0.6))
	else:
		await camera.disable_letterbox(beat.get("duration", 0.4))
	if not is_inside_tree(): return

## ─── EXTENDED BEAT: MUSIC ────────────────────────────────────────────
## Usage:
##   {"type": "music", "action": "play", "track": "forest_ambience"}
##   {"type": "music", "action": "stop", "fade_out": 1.5}

func handle_music(beat: Dictionary) -> void:
	var action = beat.get("action", "play")
	if not has_node("/root/MusicManager"):
		return
	match action:
		"play":
			var track = beat.get("track", "")
			if track != "":
				MusicManager.play_track(track)
		"stop":
			MusicManager.stop(beat.get("fade_out", true))

## ─── EXTENDED BEAT: CAMERA FOLLOW ────────────────────────────────────
## Usage:
##   {"type": "camera_follow", "character": "Kaelen", "duration": 3.0, "speed": 5.0}

func handle_camera_follow(beat: Dictionary) -> void:
	if not camera:
		return
	var character_name = beat.get("character", "")
	var character = find_character(character_name)
	if not character:
		return
	var speed = beat.get("speed", 5.0)
	camera.start_follow(character, speed)
	
	var duration = beat.get("duration", -1.0)
	if duration > 0:
		await get_tree().create_timer(duration).timeout
		if not is_inside_tree(): return
		camera.stop_follow()

## ─── EXTENDED BEAT: CAMERA DOLLY ─────────────────────────────────────
## Usage:
##   {"type": "camera_dolly", "target": Vector2(800, 400), "zoom": Vector2(1.5, 1.5), "duration": 2.0}

func handle_camera_dolly(beat: Dictionary) -> void:
	if not camera:
		return
	var target = beat.get("target", Vector2.ZERO)
	var zoom_level = beat.get("zoom", Vector2.ONE)
	var duration = beat.get("duration", 2.0)
	await camera.dolly_shot(target, zoom_level, duration)
	if not is_inside_tree(): return

## ─── EXTENDED BEAT: CAMERA WHIP PAN ──────────────────────────────────
## Usage:
##   {"type": "camera_whip", "target": Vector2(900, 300), "duration": 0.3}

func handle_camera_whip(beat: Dictionary) -> void:
	if not camera:
		return
	await camera.whip_pan(beat.get("target", Vector2.ZERO), beat.get("duration", 0.3))
	if not is_inside_tree(): return

## ─── EXTENDED BEAT: EXPRESSION ───────────────────────────────────────
## Usage:
##   {"type": "expression", "character": "Elara", "expression": "surprised"}

func handle_expression(beat: Dictionary) -> void:
	var character_name = beat.get("character", "")
	var character = find_character(character_name)
	if not character:
		return
	var expr = beat.get("expression", "neutral")
	if character.has_method("set_expression"):
		character.call("set_expression", expr)
	else:
		var anim_sprite = character.get_node_or_null("AnimatedSprite2D")
		if anim_sprite and anim_sprite is AnimatedSprite2D:
			if anim_sprite.sprite_frames and anim_sprite.sprite_frames.has_animation(expr):
				anim_sprite.play(expr)

## ─── EXTENDED BEAT: BACKGROUND ───────────────────────────────────────
## Usage:
##   {"type": "background", "scene": "res://scenes/prologue/flight_707.tscn", "duration": 0.5}
##   {"type": "background", "color": Color(0.1, 0.05, 0.2), "duration": 0.5}

func handle_background(beat: Dictionary) -> void:
	var duration = beat.get("duration", 0.5)
	
	# If BackgroundManager autoload exists, use it
	if has_node("/root/BackgroundManager"):
		var scene_path = beat.get("scene", "")
		if scene_path != "":
			BackgroundManager.change_background(scene_path)
	
	# Color-based background change
	var color = beat.get("color", null)
	if color:
		var bg = get_tree().current_scene.get_node_or_null("Background")
		if bg and bg is ColorRect:
			var tween = create_tween()
			tween.tween_property(bg, "color", color, duration)
			await tween.finished
			if not is_inside_tree(): return
		else:
			await get_tree().create_timer(duration).timeout
			if not is_inside_tree(): return
	else:
		await get_tree().create_timer(0.1).timeout
		if not is_inside_tree(): return

## ─── EXTENDED BEAT: TITLE CARD ───────────────────────────────────────
## Usage:
##   {"type": "title_card", "title": "Chapter 1", "subtitle": "The Null Pointer Exception", "duration": 3.0}

func handle_title_card(beat: Dictionary) -> void:
	var title_text = beat.get("title", "")
	var subtitle_text = beat.get("subtitle", "")
	var duration = beat.get("duration", 3.0)
	
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
	
	## Animate: fade in → hold → fade out
	var tween = create_tween()
	tween.tween_property(title_label, "modulate:a", 1.0, 0.8).set_trans(Tween.TRANS_SINE)
	if vbox.get_child_count() > 1:
		tween.tween_property(vbox.get_child(1), "modulate:a", 1.0, 0.6).set_trans(Tween.TRANS_SINE)
	tween.tween_interval(max(duration - 2.0, 0.5))
	tween.tween_property(title_label, "modulate:a", 0.0, 0.6)
	if vbox.get_child_count() > 1:
		tween.tween_property(vbox.get_child(1), "modulate:a", 0.0, 0.4)
	await tween.finished
	if not is_inside_tree(): return
	layer.queue_free()

## ─── EXTENDED BEAT: CALL METHOD (AnimationPlayer equivalent) ─────────
## Usage:
##   {"type": "call_method", "callback": "trigger_explosion", "args": [Vector2(400, 300)]}

func handle_call_method(beat: Dictionary) -> void:
	var callback = beat.get("callback", "")
	var args = beat.get("args", [])
	
	if callback.is_empty():
		return
	
	var parent = get_parent()
	if parent and parent.has_method(callback):
		var result = parent.callv(callback, args)
		if result is Signal:
			await result
			if not is_inside_tree(): return

## ─── INPUT BLOCKING ──────────────────────────────────────────────────

func _block_input() -> void:
	## Disable player input during cutscene.
	_input_blocked = true
	
	# Disable player's process
	var players = get_tree().get_nodes_in_group("player")
	for player in players:
		_pre_cutscene_process_mode[player] = player.process_mode
		player.process_mode = Node.PROCESS_MODE_DISABLED
	
	# Block pause menu during cutscene
	if has_node("/root/PauseScreen"):
		PauseScreen.set_meta("cutscene_blocked", true)

func _unblock_input() -> void:
	## Restore player input after cutscene.
	_input_blocked = false
	
	for node in _pre_cutscene_process_mode.keys():
		if is_instance_valid(node):
			node.process_mode = _pre_cutscene_process_mode[node]
	_pre_cutscene_process_mode.clear()
	
	# Unblock pause menu
	if has_node("/root/PauseScreen"):
		PauseScreen.set_meta("cutscene_blocked", false)
	
	# Clean up tint if still active
	if _canvas_modulate and is_instance_valid(_canvas_modulate):
		_canvas_modulate.queue_free()
		_canvas_modulate = null

## ─── ANIMATION HELPERS ────────────────────────────────────────────────

func _start_walk_anim(character: Node2D, direction: Vector2) -> void:
	## Start walk animation on a cutscene character's Sprite child.
	var sprite = character.get_node_or_null("Sprite")
	if not sprite:
		return
	# Flip sprite based on horizontal movement direction
	if sprite is Sprite2D:
		var faces_left = sprite.get_meta("faces_left", false)
		if faces_left:
			sprite.flip_h = direction.x >= 0  # flip to face right when moving right
		else:
			sprite.flip_h = direction.x < 0   # flip to face left when moving left
	# Play walking animation
	var dir_sign = 1.0 if direction.x >= 0 else -1.0
	TweenAnimator.play_cutscene_walk(sprite, dir_sign)

func _stop_walk_anim(character: Node2D) -> void:
	## Stop walk animation and switch to idle on a cutscene character.
	var sprite = character.get_node_or_null("Sprite")
	if not sprite:
		return
	TweenAnimator.play_cutscene_idle(sprite)

## ─── CHARACTER HELPERS ───────────────────────────────────────────────

func get_or_create_character(character_name: String) -> Node2D:
	if not characters_container:
		return null
	
	var character = characters_container.get_node_or_null(character_name)
	if not character:
		character = AssetManager.create_character_sprite(character_name)
		characters_container.add_child(character)
	
	return character

func find_character(character_name: String) -> Node2D:
	if not characters_container:
		return null
	return characters_container.get_node_or_null(character_name)

## ─── FLASH EFFECT ────────────────────────────────────────────────────

func create_flash_effect(color: Color, duration: float):
	var flash = ColorRect.new()
	flash.color = color
	flash.size = get_viewport().get_visible_rect().size
	flash.modulate.a = 0.0
	get_tree().root.add_child(flash)
	
	var tween = create_tween()
	tween.tween_property(flash, "modulate:a", 0.8, duration * 0.3)
	tween.tween_property(flash, "modulate:a", 0.0, duration * 0.7)
	await tween.finished
	if is_instance_valid(flash):
		flash.queue_free()

## ─── CONTROL ─────────────────────────────────────────────────────────

## Hold-to-skip configuration
const SKIP_HOLD_DURATION: float = 1.5  # Seconds player must hold ESC to skip
var _skip_hold_timer: float = 0.0
var _skip_holding: bool = false
var _skip_hint: Label = null

func stop_cutscene() -> void:
	is_playing = false
	_skip_holding = false
	_skip_hold_timer = 0.0
	_hide_skip_hint()
	_unblock_input()
	# Force-reset dialogue to prevent orphaned dialogue boxes after ESC skip
	if has_node("/root/DialogueManager"):
		DialogueManager.force_reset()
	# Clean up fade overlay so screen isn't stuck dark after skip
	if _fade_overlay and is_instance_valid(_fade_overlay):
		_fade_overlay.modulate.a = 0.0
	# Reset canvas modulate tint
	if _canvas_modulate and is_instance_valid(_canvas_modulate):
		_canvas_modulate.color = Color.WHITE
	# Stop cutscene audio
	if _audio_player and is_instance_valid(_audio_player) and _audio_player.playing:
		var tw = create_tween()
		tw.tween_property(_audio_player, "volume_db", -40.0, 0.5)
		tw.tween_callback(_audio_player.stop)
	cutscene_finished.emit()

func pause_cutscene() -> void:
	paused = true

func resume_cutscene() -> void:
	paused = false

func _process(delta: float) -> void:
	if not is_playing:
		return
	# Hold-to-skip timer
	if _skip_holding:
		_skip_hold_timer += delta
		_update_skip_hint()
		if _skip_hold_timer >= SKIP_HOLD_DURATION:
			print("[CUTSCENE] Skip completed (held ESC for %.1fs)" % SKIP_HOLD_DURATION)
			stop_cutscene()

func _unhandled_input(event) -> void:
	if not is_playing:
		return
	if event.is_action_pressed("ui_cancel"):
		_skip_holding = true
		_skip_hold_timer = 0.0
		_show_skip_hint()
		get_viewport().set_input_as_handled()
	elif event.is_action_released("ui_cancel"):
		_skip_holding = false
		_skip_hold_timer = 0.0
		_hide_skip_hint()

func _show_skip_hint() -> void:
	if _skip_hint and is_instance_valid(_skip_hint):
		_skip_hint.visible = true
		return
	_skip_hint = Label.new()
	_skip_hint.text = "[Hold ESC to skip]  ░░░░░░░░░░"
	_skip_hint.add_theme_font_size_override("font_size", 14)
	_skip_hint.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0, 0.7))
	_skip_hint.add_theme_constant_override("outline_size", 2)
	_skip_hint.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.8))
	_skip_hint.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	_skip_hint.offset_left = -280
	_skip_hint.offset_top = -40
	_skip_hint.offset_right = -20
	_skip_hint.offset_bottom = -10
	if _fade_layer and is_instance_valid(_fade_layer):
		_fade_layer.add_child(_skip_hint)
	else:
		add_child(_skip_hint)

func _update_skip_hint() -> void:
	if not _skip_hint or not is_instance_valid(_skip_hint):
		return
	var progress = clampf(_skip_hold_timer / SKIP_HOLD_DURATION, 0.0, 1.0)
	var filled = int(progress * 10)
	var bar = "█".repeat(filled) + "░".repeat(10 - filled)
	_skip_hint.text = "[Hold ESC to skip]  %s" % bar

func _hide_skip_hint() -> void:
	if _skip_hint and is_instance_valid(_skip_hint):
		_skip_hint.visible = false
