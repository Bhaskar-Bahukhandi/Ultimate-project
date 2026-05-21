extends Node
class_name PlayerAnimationController

## ==========================================================================
## PLAYER ANIMATION CONTROLLER
## ==========================================================================
## Drives visual state from player movement/combat flags.
## Works with BOTH ColorRect placeholders (via TweenAnimator) AND real
## AnimatedSprite2D sprites (via sprite.play("animation_name")).
##
## Usage — attach as child of the Player node (CharacterBody2D):
##   var anim_ctrl = PlayerAnimationController.new()
##   anim_ctrl.mode = "combat"   # or "topdown"
##   add_child(anim_ctrl)
##   # Then each frame: anim_ctrl.update_animation(delta)
##
## Or call from _physics_process:
##   anim_ctrl.update_animation(delta)
## ==========================================================================

## Which mode this controller runs in
enum Mode { COMBAT, TOPDOWN }
var mode: Mode = Mode.COMBAT

## Cached references
var sprite_node: Node = null          # The "Sprite" child (ColorRect, Sprite2D, or AnimatedSprite2D)
var player: CharacterBody2D = null    # Parent player node
var has_real_sprite: bool = false     # True if AnimatedSprite2D with real frames

## Current animation state
var current_anim: String = "idle"
var last_anim: String = ""
var _combat_visual_override: String = ""
var _combat_visual_override_timer: float = 0.0

## Idle bob for ColorRect placeholder
var _idle_bob_tween: Tween = null
var _run_bob_tween: Tween = null

func _ready() -> void:
	player = get_parent() as CharacterBody2D
	if not player:
		push_warning("[AnimCtrl] Parent is not CharacterBody2D")
		return
	_find_sprite()

func _find_sprite() -> void:
	## Find the Sprite child node and detect its type.
	if player.has_node("Sprite"):
		sprite_node = player.get_node("Sprite")
		has_real_sprite = sprite_node is AnimatedSprite2D and _has_valid_frames(sprite_node)
	else:
		sprite_node = null
		has_real_sprite = false

func _has_valid_frames(animated_sprite: AnimatedSprite2D) -> bool:
	## Check if the AnimatedSprite2D has loaded SpriteFrames with real animations.
	if not animated_sprite.sprite_frames:
		return false
	var anims = animated_sprite.sprite_frames.get_animation_names()
	# Top-down sheets may expose only directional idle animations.
	return "idle" in anims or "idle_down" in anims

func set_mode_combat() -> void:
	mode = Mode.COMBAT

func set_mode_topdown() -> void:
	mode = Mode.TOPDOWN

# ==========================================================================
# MAIN UPDATE — Call from player's _physics_process
# ==========================================================================

func update_animation(_delta: float) -> void:
	## Determine animation state from player flags and velocity, then play it.
	if not player or not sprite_node:
		_find_sprite()
		if not sprite_node:
			return
	if mode == Mode.COMBAT and _combat_visual_override_timer > 0.0:
		_combat_visual_override_timer = maxf(_combat_visual_override_timer - _delta, 0.0)
		if _combat_visual_override_timer <= 0.0:
			_combat_visual_override = ""

	var new_anim: String = _determine_state()

	if new_anim != current_anim:
		last_anim = current_anim
		current_anim = new_anim
		_play_animation(current_anim)

	# Update sprite direction
	_update_facing()

func _determine_state() -> String:
	## Read player state flags to pick the right animation name.
	if mode == Mode.COMBAT:
		return _determine_combat_state()
	else:
		return _determine_topdown_state()

# ==========================================================================
# COMBAT STATE DETERMINATION (side-scroll)
# ==========================================================================

func _determine_combat_state() -> String:
	# Priority order: death > hurt > attack > dash > defend > cast > heal > wall_slide > jump/fall > run > idle
	
	# Dead
	if _get_flag("is_dead"):
		return "die"

	# Existing combat code owns timing; this only holds named V2 visuals for
	# special actions that are otherwise represented by generic attack flags.
	if _combat_visual_override_timer > 0.0 and _combat_visual_override != "":
		return _combat_visual_override
	
	# Hurt (brief window after taking damage)
	# hurt is typically a transient state driven by take_damage, not a persistent flag
	
	# Attacking
	if _get_flag("is_attacking"):
		var step = _get_var("combo_step", 1)
		return "attack%d" % clampi(step, 1, 3)
	
	# Dashing
	if _get_flag("is_dashing"):
		return "dash"
	
	# Defending / Parrying
	if _get_flag("is_defending"):
		return "defend"
	
	# Casting spell
	if _get_flag("is_casting"):
		return "cast"
	
	# Healing
	if _get_flag("is_healing"):
		return "heal"
	
	# Wall sliding
	if _get_flag("is_wall_sliding"):
		return "wall_slide"
	
	# Airborne
	if not player.is_on_floor():
		if player.velocity.y < 0:
			return "jump"
		else:
			return "fall"
	
	# Grounded movement
	if abs(player.velocity.x) > 10.0:
		if _get_flag("is_sprinting"):
			return "run"
		return "walk"
	
	return "idle"

# ==========================================================================
# TOP-DOWN STATE DETERMINATION
# ==========================================================================

func _determine_topdown_state() -> String:
	if player.velocity.length() > 10.0:
		if _get_flag("is_sprinting"):
			return "run"
		return "walk"
	return "idle"

# ==========================================================================
# PLAY ANIMATION — Real sprites or TweenAnimator fallback
# ==========================================================================

func _play_animation(anim_name: String) -> void:
	if has_real_sprite:
		_play_real_animation(anim_name)
	else:
		_play_tween_animation(anim_name)

func _play_real_animation(anim_name: String) -> void:
	## Play a named animation on AnimatedSprite2D.
	var animated: AnimatedSprite2D = sprite_node as AnimatedSprite2D
	if not animated or not animated.sprite_frames:
		return
	
	# Map our state names to actual animation names in the SpriteFrames
	var mapped = _map_animation_name(anim_name)
	
	if animated.sprite_frames.has_animation(mapped):
		if animated.animation != mapped or not animated.is_playing():
			animated.play(mapped)
	else:
		# Fallback: try "idle" if the specific animation doesn't exist
		if animated.sprite_frames.has_animation("idle") and animated.animation != "idle":
			animated.play("idle")

func _map_animation_name(anim_name: String) -> String:
	## Map internal state names to SpriteFrames animation names.
	## Override this mapping when you know your sprite sheet's animation names.
	match anim_name:
		"walk": return "walk" if _anim_exists("walk") else "run" if _anim_exists("run") else "idle"
		"run": return "run" if _anim_exists("run") else "walk"
		"idle": return "idle"
		"jump": return "jump" if _anim_exists("jump") else "idle"
		"fall": return "fall" if _anim_exists("fall") else "jump" if _anim_exists("jump") else "idle"
		"attack1": return "slash_1" if _anim_exists("slash_1") else "attack1" if _anim_exists("attack1") else "attack" if _anim_exists("attack") else "idle"
		"attack2": return "slash_2" if _anim_exists("slash_2") else "attack2" if _anim_exists("attack2") else "attack" if _anim_exists("attack") else "idle"
		"attack3": return "slash_3" if _anim_exists("slash_3") else "attack3" if _anim_exists("attack3") else "attack" if _anim_exists("attack") else "idle"
		"slash_1", "slash_2", "slash_3", "charged_slash", "upslash", "downslash":
			return anim_name if _anim_exists(anim_name) else "attack" if _anim_exists("attack") else "idle"
		"dash": return "dash" if _anim_exists("dash") else "run" if _anim_exists("run") else "walk"
		"defend": return "defend" if _anim_exists("defend") else "idle"
		"cast": return "cast" if _anim_exists("cast") else "idle"
		"heal": return "heal" if _anim_exists("heal") else "idle"
		"wall_slide": return "wall_slide" if _anim_exists("wall_slide") else "fall" if _anim_exists("fall") else "idle"
		"die": return "death" if _anim_exists("death") else "die" if _anim_exists("die") else "hurt" if _anim_exists("hurt") else "idle"
		"death": return "death" if _anim_exists("death") else "die" if _anim_exists("die") else "idle"
		"hurt": return "hurt" if _anim_exists("hurt") else "idle"
		_: return "idle"

func _anim_exists(anim_name: String) -> bool:
	if not has_real_sprite:
		return false
	var animated: AnimatedSprite2D = sprite_node as AnimatedSprite2D
	return animated and animated.sprite_frames and animated.sprite_frames.has_animation(anim_name)

func request_combat_visual(anim_name: String, hold_time: float) -> void:
	## Hold a presentation-only animation while player_combat keeps gameplay timing.
	if mode != Mode.COMBAT or hold_time <= 0.0:
		return
	_combat_visual_override = anim_name
	_combat_visual_override_timer = hold_time
	current_anim = ""
	_play_animation(anim_name)

func clear_combat_visual_override() -> void:
	_combat_visual_override = ""
	_combat_visual_override_timer = 0.0

# ==========================================================================
# TWEEN FALLBACK — ColorRect / Sprite2D placeholders
# ==========================================================================

func _play_tween_animation(anim_name: String) -> void:
	## Drive TweenAnimator for placeholder sprites (no real animation frames).
	# Kill previous looping tweens
	_kill_tweens()
	
	match anim_name:
		"idle":
			TweenAnimator.play_idle(sprite_node)
		"walk", "run":
			var dir = _get_var("facing_direction", 1.0)
			if dir is Vector2:
				dir = 1.0 if dir.x >= 0 else -1.0
			TweenAnimator.play_run(sprite_node, dir)
		"jump":
			TweenAnimator.play_jump_up(sprite_node)
		"fall":
			TweenAnimator.play_fall(sprite_node)
		"attack1", "attack2", "attack3":
			# Attacks are already driven by player_combat.gd via TweenAnimator
			pass
		"dash":
			var dir = _get_var("facing_direction", 1.0)
			if dir is Vector2:
				dir = 1.0 if dir.x >= 0 else -1.0
			TweenAnimator.play_dash(sprite_node, dir)
		"defend":
			# Subtle defensive stance via TweenAnimator (preserves base scale)
			TweenAnimator.play_defend(sprite_node)
		"heal":
			TweenAnimator.play_heal(sprite_node)
		"die":
			# Death is already driven by player_combat.gd via TweenAnimator
			pass
		"wall_slide":
			# Wall slide visual is handled by rotation in player_combat.gd
			pass
		_:
			# Reset to neutral -- use base scale, NOT Vector2.ONE
			var bs = TweenAnimator._get_base_scale(sprite_node)
			sprite_node.scale = bs
			sprite_node.rotation_degrees = 0.0

func _kill_tweens() -> void:
	## Stop any looping TweenAnimator tweens we started.
	if _idle_bob_tween and _idle_bob_tween.is_valid():
		_idle_bob_tween.kill()
		_idle_bob_tween = null
	if _run_bob_tween and _run_bob_tween.is_valid():
		_run_bob_tween.kill()
		_run_bob_tween = null

# ==========================================================================
# FACING / DIRECTION
# ==========================================================================

func _update_facing() -> void:
	## Flip sprite based on movement direction.
	if not sprite_node:
		return
	
	if mode == Mode.COMBAT:
		var dir = _get_var("facing_direction", 1.0)
		if sprite_node is Sprite2D or sprite_node is AnimatedSprite2D:
			# Art that faces LEFT needs inverted flip logic
			var faces_left = sprite_node.get_meta("faces_left", false)
			if faces_left:
				sprite_node.flip_h = (dir >= 0)  # flip_h=true to face right
			else:
				sprite_node.flip_h = (dir < 0)
		elif sprite_node is ColorRect:
			# ColorRect doesn't have flip_h — use scale.x instead
			sprite_node.scale.x = abs(sprite_node.scale.x) * sign(dir) if dir != 0 else abs(sprite_node.scale.x)
	else:
		# Top-down: use facing_direction Vector2 to pick direction suffix
		var dir: Vector2 = _get_var("facing_direction", Vector2.DOWN)
		if has_real_sprite:
			_set_topdown_direction(dir)

func _set_topdown_direction(dir: Vector2) -> void:
	## For top-down sprites with directional animations (idle_down, walk_right, etc.).
	if not has_real_sprite:
		return
	var animated: AnimatedSprite2D = sprite_node as AnimatedSprite2D
	if not animated:
		return
	
	# Determine direction suffix
	var suffix = "_down"
	if abs(dir.x) > abs(dir.y):
		suffix = "_right" if dir.x > 0 else "_left"
		# If no _left, use _right + flip_h
		if suffix == "_left" and not _anim_exists(current_anim + "_left"):
			suffix = "_right"
			animated.flip_h = true
		else:
			animated.flip_h = false
	else:
		suffix = "_down" if dir.y >= 0 else "_up"
		animated.flip_h = false
	
	# Try directional variant, fall back to base name
	var directional = current_anim + suffix
	if _anim_exists(directional):
		if animated.animation != directional:
			animated.play(directional)

# ==========================================================================
# HELPERS — safe access to parent player variables
# ==========================================================================

func _get_flag(flag_name: String) -> bool:
	## Safely read a bool from the parent player script.
	if player and flag_name in player:
		return player.get(flag_name)
	return false

func _get_var(var_name: String, default = null):
	## Safely read any variable from the parent player script.
	if player and var_name in player:
		return player.get(var_name)
	return default

# ==========================================================================
# SPRITE UPGRADE — Called when AssetManager replaces ColorRect with real sprite
# ==========================================================================

func on_sprite_replaced() -> void:
	## Call this after AssetManager.replace_player_sprite() to refresh references.
	_find_sprite()
	clear_combat_visual_override()
	current_anim = ""  # Force re-evaluation
