extends Node

class_name TweenAnimator



## ==================================================================================

## TWEEN-BASED ANIMATION SYSTEM

## ==================================================================================

## Provides procedural animations via tweens for ColorRect placeholder sprites.

## Each function matches an AnimConst animation name. When real AnimatedSprite2D

## animations are added with the same names, you replace calls to TweenAnimator

## with animated_sprite.play("animation_name") â€” zero logic changes needed.

## ==================================================================================



# Active tweens by target node (to kill previous before playing new)

static var _active_tweens: Dictionary = {}

# Store base positions to prevent drift (BUG m3 fix)

static var _base_positions: Dictionary = {}

# Store base modulates to prevent tint loss (BUG 19/20 fix)
static var _base_modulates: Dictionary = {}

# Frame counter for periodic cleanup (PERF: avoid cleaning every _kill_existing call)
static var _last_cleanup_frame: int = 0



## Kill any running animation on a node before starting a new one

static func _kill_existing(node: Node) -> void:

	var node_id = node.get_instance_id()

	if _active_tweens.has(node_id):

		var old_tween: Tween = _active_tweens[node_id]

		if old_tween and old_tween.is_valid():

			old_tween.kill()

		_active_tweens.erase(node_id)

	# PERF: Periodic cleanup instead of every call (every ~60 frames / ~1 sec)

	var frame = Engine.get_process_frames()

	if frame - _last_cleanup_frame > 60:

		_last_cleanup_frame = frame

		_cleanup_freed_nodes()



static func _store_tween(node: Node, tween: Tween) -> void:

	_active_tweens[node.get_instance_id()] = tween



static func _cleanup_freed_nodes() -> void:

	## Remove entries for nodes that have been freed to prevent memory leak.

	var to_remove: Array = []

	for nid in _active_tweens.keys():

		var tween = _active_tweens[nid]

		if tween == null or not tween.is_valid():

			to_remove.append(nid)

	for nid in to_remove:

		_active_tweens.erase(nid)

		_base_positions.erase(nid)

		_base_scales.erase(nid)

		_base_modulates.erase(nid)


## BUG 18 FIX: Kill ALL active tweens and clear caches on scene change
static func clear_all_tweens() -> void:
	for nid in _active_tweens.keys():
		var tween = _active_tweens[nid]
		if tween and tween.is_valid():
			tween.kill()
	_active_tweens.clear()
	_base_positions.clear()
	_base_scales.clear()
	_base_modulates.clear()

## BUG 19/20 FIX: Get/store base modulate so tinted sprites restore correctly
static func _get_base_modulate(sprite: CanvasItem) -> Color:
	var nid = sprite.get_instance_id()
	if not _base_modulates.has(nid):
		_base_modulates[nid] = sprite.modulate
	return _base_modulates[nid]

static func _set_base_modulate(sprite: CanvasItem, c: Color) -> void:
	_base_modulates[sprite.get_instance_id()] = c

## True while a tracked animation (one-shot or looping) is running on the node.
static func is_animating(node: Node) -> bool:
	var tween = _active_tweens.get(node.get_instance_id())
	return tween != null and tween.is_valid()

## Rest x for animations that move the sprite sideways, recorded once per node.
## Reading position.x at call time made an interrupted lunge or hurt shake (hit
## mid-attack, a cancel) the new rest, so the sprite drifted a little more each time.
static func _get_rest_x(sprite: CanvasItem) -> float:
	if sprite is CollisionObject2D:
		return sprite.position.x  # a body moves; only child visuals have a fixed rest
	if not sprite.has_meta("_tween_rest_x"):
		sprite.set_meta("_tween_rest_x", sprite.position.x)
	return sprite.get_meta("_tween_rest_x")



static func _get_base_y(sprite: CanvasItem) -> float:

	## Get the stored base Y position, or store current as base.

	var nid = sprite.get_instance_id()

	if not _base_positions.has(nid):

		_base_positions[nid] = sprite.position.y

	return _base_positions[nid]



static func _set_base_y(sprite: CanvasItem, y: float) -> void:

	_base_positions[sprite.get_instance_id()] = y



# â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

# PLAYER COMBAT ANIMATIONS

# â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€



# Store base scales to preserve AssetManager sizing
static var _base_scales: Dictionary = {}
static var bs: Vector2 = Vector2.ONE  # Shorthand for current sprite's base scale

static func _get_base_scale(sprite: CanvasItem) -> Vector2:
	## Get stored base scale, or store current as base. This preserves AssetManager scaling.
	var nid = sprite.get_instance_id()
	if not _base_scales.has(nid):
		_base_scales[nid] = sprite.scale
	bs = _base_scales[nid]
	return bs

static func _set_base_scale(sprite: CanvasItem, s: Vector2) -> void:
	_base_scales[sprite.get_instance_id()] = s

static func _bs(sprite: CanvasItem, fx: float, fy: float) -> Vector2:
	## Multiply base scale by factors. Use this instead of absolute Vector2 for all scale targets.
	_get_base_scale(sprite)
	return Vector2(abs(bs.x) * fx, abs(bs.y) * fy)

static func _bsd(sprite: CanvasItem, fx: float, fy: float, dir_sign: float) -> Vector2:
	## Multiply base scale by factors, with directional flip on X.
	_get_base_scale(sprite)
	return Vector2(abs(bs.x) * fx * dir_sign, abs(bs.y) * fy)

# ---------------------------------------------------------------------------
# PLAYER COMBAT ANIMATIONS
# ---------------------------------------------------------------------------

## Idle -- expressive breathing: Y bob + scale pulse + subtle rotation
static func play_idle(sprite: CanvasItem) -> Tween:
	_kill_existing(sprite)
	var base_y = _get_base_y(sprite)
	_get_base_scale(sprite)
	sprite.position.x = _get_rest_x(sprite)  # undo a lunge cut short by this state change
	sprite.position.y = base_y
	sprite.rotation = 0.0
	sprite.scale = bs
	var tween = sprite.create_tween().set_loops()
	# Inhale -- rise + stretch tall + lean micro-right
	tween.tween_property(sprite, "position:y", base_y - 3, 0.7).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.parallel().tween_property(sprite, "scale", _bs(sprite, 0.97, 1.04), 0.7).set_trans(Tween.TRANS_SINE)
	tween.parallel().tween_property(sprite, "rotation", deg_to_rad(0.8), 0.7).set_trans(Tween.TRANS_SINE)
	# Exhale -- drop + squash wide + lean micro-left
	tween.tween_property(sprite, "position:y", base_y + 2, 0.8).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.parallel().tween_property(sprite, "scale", _bs(sprite, 1.03, 0.97), 0.8).set_trans(Tween.TRANS_SINE)
	tween.parallel().tween_property(sprite, "rotation", deg_to_rad(-0.5), 0.8).set_trans(Tween.TRANS_SINE)
	# Settle pause
	tween.tween_property(sprite, "position:y", base_y, 0.5).set_trans(Tween.TRANS_SINE)
	tween.parallel().tween_property(sprite, "scale", bs, 0.5).set_trans(Tween.TRANS_SINE)
	tween.parallel().tween_property(sprite, "rotation", 0.0, 0.5).set_trans(Tween.TRANS_SINE)
	_store_tween(sprite, tween)
	return tween

## Run -- dynamic footstep cycle with squash-stretch per step
static func play_run(sprite: CanvasItem, direction: float = 1.0) -> Tween:
	_kill_existing(sprite)
	_get_base_scale(sprite)
	var dir_sign = sign(direction) if direction != 0 else 1.0
	sprite.scale = Vector2(abs(bs.x) * dir_sign, abs(bs.y))
	var base_y = _get_base_y(sprite)
	sprite.position.x = _get_rest_x(sprite)  # undo a lunge cut short by this state change
	sprite.position.y = base_y
	var tween = sprite.create_tween().set_loops()
	# Step 1: Push off -- squash, lean forward
	tween.tween_property(sprite, "scale", _bsd(sprite, 1.08, 0.92, dir_sign), 0.06).set_trans(Tween.TRANS_QUAD)
	tween.parallel().tween_property(sprite, "rotation", deg_to_rad(6 * dir_sign), 0.06)
	# Step 1: Airborne -- stretch, rise
	tween.tween_property(sprite, "position:y", base_y - 6, 0.07).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(sprite, "scale", _bsd(sprite, 0.92, 1.1, dir_sign), 0.07)
	tween.parallel().tween_property(sprite, "rotation", deg_to_rad(2 * dir_sign), 0.07)
	# Step 1: Land -- squash on contact
	tween.tween_property(sprite, "position:y", base_y + 1, 0.05).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.parallel().tween_property(sprite, "scale", _bsd(sprite, 1.06, 0.94, dir_sign), 0.05)
	tween.parallel().tween_property(sprite, "rotation", deg_to_rad(-2 * dir_sign), 0.05)
	# Step 2: Push off (opposite foot)
	tween.tween_property(sprite, "scale", _bsd(sprite, 1.06, 0.94, dir_sign), 0.06).set_trans(Tween.TRANS_QUAD)
	tween.parallel().tween_property(sprite, "rotation", deg_to_rad(4 * dir_sign), 0.06)
	# Step 2: Airborne
	tween.tween_property(sprite, "position:y", base_y - 5, 0.07).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(sprite, "scale", _bsd(sprite, 0.94, 1.08, dir_sign), 0.07)
	tween.parallel().tween_property(sprite, "rotation", deg_to_rad(1 * dir_sign), 0.07)
	# Step 2: Land
	tween.tween_property(sprite, "position:y", base_y, 0.05).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.parallel().tween_property(sprite, "scale", _bsd(sprite, 1.0, 1.0, dir_sign), 0.05)
	tween.parallel().tween_property(sprite, "rotation", 0.0, 0.05)
	_store_tween(sprite, tween)
	return tween

## Jump ascend -- dramatic anticipation squash into explosive vertical stretch
static func play_jump_up(sprite: CanvasItem) -> Tween:
	_kill_existing(sprite)
	var tween = sprite.create_tween()
	# Wind-up crouch (anticipation)
	tween.tween_property(sprite, "scale", _bs(sprite, 1.2, 0.7), 0.04).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	# Explosive launch stretch
	tween.tween_property(sprite, "scale", _bs(sprite, 0.75, 1.35), 0.06).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(sprite, "rotation", deg_to_rad(-3), 0.06)
	# Settle into air pose
	tween.tween_property(sprite, "scale", _bs(sprite, 0.85, 1.15), 0.1).set_trans(Tween.TRANS_SINE)
	tween.parallel().tween_property(sprite, "rotation", 0.0, 0.1)
	_store_tween(sprite, tween)
	return tween

## Fall -- elongate downward with speed lines feel + subtle panic wobble
static func play_fall(sprite: CanvasItem) -> Tween:
	_kill_existing(sprite)
	var tween = sprite.create_tween()
	# Stretch downward as gravity pulls
	tween.tween_property(sprite, "scale", _bs(sprite, 0.88, 1.15), 0.1).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	# Subtle panic wobble while falling
	tween.tween_property(sprite, "rotation", deg_to_rad(4), 0.08).set_trans(Tween.TRANS_SINE)
	tween.tween_property(sprite, "rotation", deg_to_rad(-3), 0.08).set_trans(Tween.TRANS_SINE)
	tween.tween_property(sprite, "rotation", deg_to_rad(2), 0.06).set_trans(Tween.TRANS_SINE)
	# Continue stretching
	tween.parallel().tween_property(sprite, "scale", _bs(sprite, 0.82, 1.22), 0.15).set_trans(Tween.TRANS_SINE)
	_store_tween(sprite, tween)
	return tween

## Land -- massive impact squash with multi-bounce recovery
static func play_land(sprite: CanvasItem) -> Tween:
	_kill_existing(sprite)
	_get_base_scale(sprite)
	var tween = sprite.create_tween()
	# Reset rotation from fall
	tween.tween_property(sprite, "rotation", 0.0, 0.02)
	# IMPACT -- massive squash
	tween.tween_property(sprite, "scale", _bs(sprite, 1.45, 0.55), 0.04).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	# Bounce 1 -- overcorrect tall
	tween.tween_property(sprite, "scale", _bs(sprite, 0.82, 1.2), 0.06).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	# Bounce 2 -- slight wide
	tween.tween_property(sprite, "scale", _bs(sprite, 1.08, 0.94), 0.05).set_trans(Tween.TRANS_SINE)
	# Bounce 3 -- almost there
	tween.tween_property(sprite, "scale", _bs(sprite, 0.97, 1.03), 0.04).set_trans(Tween.TRANS_SINE)
	# Settle
	tween.tween_property(sprite, "scale", bs, 0.06).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_store_tween(sprite, tween)
	return tween

## Attack 1 -- shorthand
static func play_attack(sprite: CanvasItem, direction: float = 1.0) -> Tween:
	return play_attack_combo(sprite, direction, 1)

## Combo attacks -- dramatic multi-step sword swings
static func play_attack_combo(sprite: CanvasItem, direction: float = 1.0, combo_step: int = 1) -> Tween:
	_kill_existing(sprite)
	var arm = sprite.get_node_or_null("Arm")
	var trail = sprite.get_node_or_null("WeaponTrail")
	var ds = sign(direction) if direction != 0 else 1.0
	var base_x = _get_rest_x(sprite)
	var base_y = _get_base_y(sprite)
	_get_base_scale(sprite)
	var tween = sprite.create_tween()

	match combo_step:
		1:  # Horizontal slash -- wind-up pull, explosive forward lunge, arc recovery
			# Wind-up pullback
			tween.tween_property(sprite, "position:x", base_x - 5 * ds, 0.03).set_trans(Tween.TRANS_QUAD)
			tween.parallel().tween_property(sprite, "scale", _bs(sprite, 0.9, 1.08), 0.03)
			tween.parallel().tween_property(sprite, "rotation", deg_to_rad(-8 * ds), 0.03)
			# SLASH -- explosive lunge
			tween.tween_property(sprite, "position:x", base_x + 18 * ds, 0.04).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
			tween.parallel().tween_property(sprite, "scale", _bs(sprite, 1.2, 0.88), 0.04)
			tween.parallel().tween_property(sprite, "rotation", deg_to_rad(12 * ds), 0.04)
			# Flash white on impact
			tween.parallel().tween_property(sprite, "modulate", Color(1.5, 1.5, 1.5), 0.03)
			# Recovery arc
			tween.tween_property(sprite, "modulate", _get_base_modulate(sprite), 0.06)
			tween.parallel().tween_property(sprite, "position:x", base_x + 3 * ds, 0.08).set_trans(Tween.TRANS_SINE)
			tween.parallel().tween_property(sprite, "rotation", deg_to_rad(-3 * ds), 0.08)
			tween.parallel().tween_property(sprite, "scale", _bs(sprite, 0.95, 1.05), 0.08)
			# Settle
			tween.tween_property(sprite, "position:x", base_x, 0.1).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
			tween.parallel().tween_property(sprite, "scale", bs, 0.08)
			tween.parallel().tween_property(sprite, "rotation", 0.0, 0.08)

		2:  # Upward arc -- spinning upslash with height
			# Crouch for upswing
			tween.tween_property(sprite, "scale", _bs(sprite, 1.15, 0.85), 0.03).set_trans(Tween.TRANS_QUAD)
			tween.parallel().tween_property(sprite, "rotation", deg_to_rad(-10 * ds), 0.03)
			# UPSLASH -- rise + spin
			tween.tween_property(sprite, "position:y", base_y - 12, 0.05).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
			tween.parallel().tween_property(sprite, "position:x", base_x + 14 * ds, 0.05)
			tween.parallel().tween_property(sprite, "rotation", deg_to_rad(18 * ds), 0.05)
			tween.parallel().tween_property(sprite, "scale", _bs(sprite, 0.85, 1.25), 0.05)
			# Impact flash
			tween.parallel().tween_property(sprite, "modulate", Color(1.4, 1.3, 1.5), 0.04)
			# Arc back down
			tween.tween_property(sprite, "position:y", base_y, 0.1).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
			tween.parallel().tween_property(sprite, "position:x", base_x, 0.12).set_trans(Tween.TRANS_SINE)
			tween.parallel().tween_property(sprite, "scale", bs, 0.1)
			tween.parallel().tween_property(sprite, "rotation", 0.0, 0.1)
			tween.parallel().tween_property(sprite, "modulate", _get_base_modulate(sprite), 0.08)

		3, _:  # Finisher thrust
			# BIG wind-up pullback
			tween.tween_property(sprite, "position:x", base_x - 10 * ds, 0.06).set_trans(Tween.TRANS_QUAD)
			tween.parallel().tween_property(sprite, "scale", _bs(sprite, 0.8, 1.15), 0.06)
			tween.parallel().tween_property(sprite, "rotation", deg_to_rad(-12 * ds), 0.06)
			# Brief pause (anticipation)
			tween.tween_interval(0.03)
			# THRUST -- maximum impact
			tween.tween_property(sprite, "position:x", base_x + 30 * ds, 0.04).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
			tween.parallel().tween_property(sprite, "scale", _bs(sprite, 1.4, 0.75), 0.04)
			tween.parallel().tween_property(sprite, "rotation", deg_to_rad(6 * ds), 0.03)
			# BIG impact flash
			tween.parallel().tween_property(sprite, "modulate", Color(2.0, 1.8, 1.5), 0.03)
			# Overshoot recovery
			tween.tween_property(sprite, "position:x", base_x - 4 * ds, 0.08).set_trans(Tween.TRANS_SINE)
			tween.parallel().tween_property(sprite, "modulate", _get_base_modulate(sprite), 0.08)
			# Elastic snap to origin
			tween.tween_property(sprite, "position:x", base_x, 0.12).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
			tween.parallel().tween_property(sprite, "scale", bs, 0.12).set_trans(Tween.TRANS_ELASTIC)
			tween.parallel().tween_property(sprite, "rotation", 0.0, 0.1)

	# Arm and trail shared logic
	if arm:
		arm.visible = true
		tween.parallel().tween_property(arm, "rotation", deg_to_rad(-60 * ds), 0.04).set_trans(Tween.TRANS_QUAD)
		tween.tween_callback(func():
			if is_instance_valid(arm):
				arm.visible = false
				arm.rotation = 0.0)
	if trail:
		trail.visible = true
		tween.parallel().tween_property(trail, "modulate:a", 1.0, 0.03)
		tween.tween_callback(func():
			if is_instance_valid(trail):
				trail.visible = false)

	_store_tween(sprite, tween)
	return tween


## Upslash — distinct upward slashing motion for directional attacks
static func play_upslash(sprite: CanvasItem, direction: float = 1.0) -> Tween:
	_kill_existing(sprite)
	var ds = sign(direction) if direction != 0 else 1.0
	var base_y = _get_base_y(sprite)
	_get_base_scale(sprite)
	var tween = sprite.create_tween()
	# Crouch before upswing
	tween.tween_property(sprite, "scale", _bs(sprite, 1.2, 0.8), 0.03)
	tween.parallel().tween_property(sprite, "rotation", deg_to_rad(-5 * ds), 0.03)
	# Explosive upward stretch + rise
	tween.tween_property(sprite, "scale", _bs(sprite, 0.7, 1.4), 0.05)
	tween.parallel().tween_property(sprite, "position:y", base_y - 16, 0.05).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(sprite, "rotation", deg_to_rad(15 * ds), 0.05)
	tween.parallel().tween_property(sprite, "modulate", Color(1.4, 1.4, 1.5), 0.03)
	# Settle back down
	tween.tween_property(sprite, "scale", bs, 0.12).set_trans(Tween.TRANS_ELASTIC)
	tween.parallel().tween_property(sprite, "position:y", base_y, 0.12).set_trans(Tween.TRANS_QUAD)
	tween.parallel().tween_property(sprite, "rotation", 0.0, 0.1)
	tween.parallel().tween_property(sprite, "modulate", _get_base_modulate(sprite), 0.08)
	_store_tween(sprite, tween)
	return tween


## Charged attack — dramatic wind-up hold + explosive release
static func play_charged_attack(sprite: CanvasItem, direction: float = 1.0) -> Tween:
	_kill_existing(sprite)
	var ds = sign(direction) if direction != 0 else 1.0
	var base_x = _get_rest_x(sprite)
	_get_base_scale(sprite)
	var tween = sprite.create_tween()
	# Big crouch wind-up
	tween.tween_property(sprite, "scale", _bs(sprite, 0.75, 1.2), 0.06)
	tween.parallel().tween_property(sprite, "position:x", base_x - 12 * ds, 0.06)
	tween.parallel().tween_property(sprite, "rotation", deg_to_rad(-15 * ds), 0.06)
	# Energy pulse glow
	tween.tween_property(sprite, "modulate", Color(1.8, 1.5, 0.8), 0.04)
	# EXPLOSIVE lunge
	tween.tween_property(sprite, "position:x", base_x + 40 * ds, 0.04).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(sprite, "scale", _bs(sprite, 1.5, 0.7), 0.04)
	tween.parallel().tween_property(sprite, "rotation", deg_to_rad(8 * ds), 0.03)
	tween.parallel().tween_property(sprite, "modulate", Color(2.5, 2.0, 1.5), 0.03)
	# Recoil overshoot
	tween.tween_property(sprite, "position:x", base_x - 6 * ds, 0.1).set_trans(Tween.TRANS_SINE)
	tween.parallel().tween_property(sprite, "modulate", _get_base_modulate(sprite), 0.1)
	# Elastic settle
	tween.tween_property(sprite, "position:x", base_x, 0.15).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(sprite, "scale", bs, 0.15).set_trans(Tween.TRANS_ELASTIC)
	tween.parallel().tween_property(sprite, "rotation", 0.0, 0.12)
	_store_tween(sprite, tween)
	return tween


## Spell cast — energy gather + magical pulse release
static func play_spell_cast(sprite: CanvasItem, spell_type: String = "default") -> Tween:
	_kill_existing(sprite)
	_get_base_scale(sprite)
	var base_mod = _get_base_modulate(sprite)
	var tween = sprite.create_tween()

	match spell_type:
		"vengeful_spirit":
			# Quick focus → horizontal thrust with magic glow
			tween.tween_property(sprite, "scale", _bs(sprite, 0.85, 1.1), 0.04)
			tween.parallel().tween_property(sprite, "modulate", Color(0.5, 0.7, 1.5), 0.04)
			tween.tween_property(sprite, "scale", _bs(sprite, 1.3, 0.85), 0.05).set_trans(Tween.TRANS_BACK)
			tween.parallel().tween_property(sprite, "modulate", Color(0.8, 1.2, 2.0), 0.03)
			tween.tween_property(sprite, "scale", bs, 0.15).set_trans(Tween.TRANS_ELASTIC)
			tween.parallel().tween_property(sprite, "modulate", base_mod, 0.12)
		"desolate_dive":
			# Rise up → slam down
			tween.tween_property(sprite, "scale", _bs(sprite, 0.75, 1.3), 0.06)
			tween.parallel().tween_property(sprite, "modulate", Color(1.0, 0.6, 0.2), 0.06)
			tween.tween_property(sprite, "scale", _bs(sprite, 1.6, 0.5), 0.04).set_trans(Tween.TRANS_BACK)
			tween.parallel().tween_property(sprite, "modulate", Color(2.0, 1.5, 0.5), 0.03)
			tween.tween_property(sprite, "scale", bs, 0.2).set_trans(Tween.TRANS_ELASTIC)
			tween.parallel().tween_property(sprite, "modulate", base_mod, 0.15)
		"howling_wraiths":
			# Expand upward in a magical burst
			tween.tween_property(sprite, "scale", _bs(sprite, 1.1, 0.85), 0.03)
			tween.parallel().tween_property(sprite, "modulate", Color(0.8, 0.5, 1.5), 0.03)
			tween.tween_property(sprite, "scale", _bs(sprite, 0.8, 1.4), 0.05).set_trans(Tween.TRANS_BACK)
			tween.parallel().tween_property(sprite, "modulate", Color(1.5, 0.8, 2.5), 0.04)
			tween.tween_property(sprite, "scale", bs, 0.15).set_trans(Tween.TRANS_ELASTIC)
			tween.parallel().tween_property(sprite, "modulate", base_mod, 0.1)
		_:
			# Generic spell glow pulse
			tween.tween_property(sprite, "modulate", Color(1.5, 1.5, 2.0), 0.05)
			tween.tween_property(sprite, "scale", _bs(sprite, 1.15, 1.15), 0.06)
			tween.tween_property(sprite, "scale", bs, 0.12).set_trans(Tween.TRANS_ELASTIC)
			tween.parallel().tween_property(sprite, "modulate", base_mod, 0.1)

	_store_tween(sprite, tween)
	return tween


## Air attack — downward strike from above
static func play_air_attack(sprite: CanvasItem, direction: float = 1.0) -> Tween:
	_kill_existing(sprite)
	var ds = sign(direction) if direction != 0 else 1.0
	var base_y = _get_base_y(sprite)
	_get_base_scale(sprite)
	var tween = sprite.create_tween()
	# Wind-up arc
	tween.tween_property(sprite, "scale", _bs(sprite, 0.85, 1.18), 0.03)
	tween.parallel().tween_property(sprite, "rotation", deg_to_rad(-10 * ds), 0.03)
	# Slash down
	tween.tween_property(sprite, "position:y", base_y + 8, 0.04).set_trans(Tween.TRANS_BACK)
	tween.parallel().tween_property(sprite, "scale", _bs(sprite, 1.25, 0.8), 0.04)
	tween.parallel().tween_property(sprite, "rotation", deg_to_rad(12 * ds), 0.04)
	tween.parallel().tween_property(sprite, "modulate", Color(1.5, 1.5, 1.5), 0.03)
	# Recovery
	tween.tween_property(sprite, "position:y", base_y, 0.1).set_trans(Tween.TRANS_QUAD)
	tween.parallel().tween_property(sprite, "scale", bs, 0.1).set_trans(Tween.TRANS_ELASTIC)
	tween.parallel().tween_property(sprite, "rotation", 0.0, 0.08)
	tween.parallel().tween_property(sprite, "modulate", _get_base_modulate(sprite), 0.08)
	_store_tween(sprite, tween)
	return tween


## Hurt -- dramatic white flash + red pulse + violent knockback shake + squash
static func play_hurt(sprite: CanvasItem) -> Tween:
	_kill_existing(sprite)
	# Rest values, not the current ones: a hit landing mid-shake or mid-flash
	# otherwise kept the sprite offset and tinted for good.
	var original_modulate = _get_base_modulate(sprite)
	var original_pos = Vector2(_get_rest_x(sprite), sprite.position.y)
	_get_base_scale(sprite)
	var tween = sprite.create_tween()

	# Instant white flash
	tween.tween_property(sprite, "modulate", Color(3.0, 3.0, 3.0), 0.02)
	tween.parallel().tween_property(sprite, "scale", _bs(sprite, 1.15, 0.9), 0.02)
	# Red pulse
	tween.tween_property(sprite, "modulate", Color(1.5, 0.1, 0.1), 0.04)
	# Violent knockback shake
	tween.tween_property(sprite, "position:x", original_pos.x - 12, 0.02).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(sprite, "rotation", deg_to_rad(-8), 0.02)
	tween.tween_property(sprite, "position:x", original_pos.x + 8, 0.03).set_trans(Tween.TRANS_SINE)
	tween.parallel().tween_property(sprite, "rotation", deg_to_rad(5), 0.03)
	tween.tween_property(sprite, "position:x", original_pos.x - 5, 0.03).set_trans(Tween.TRANS_SINE)
	tween.parallel().tween_property(sprite, "rotation", deg_to_rad(-3), 0.03)
	tween.tween_property(sprite, "position:x", original_pos.x + 2, 0.02).set_trans(Tween.TRANS_SINE)
	tween.tween_property(sprite, "position:x", original_pos.x, 0.05).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.parallel().tween_property(sprite, "rotation", 0.0, 0.05)
	# Scale recovery
	tween.parallel().tween_property(sprite, "scale", bs, 0.08).set_trans(Tween.TRANS_ELASTIC)
	# Fade color back
	tween.tween_property(sprite, "modulate", original_modulate, 0.15).set_trans(Tween.TRANS_SINE)

	_store_tween(sprite, tween)
	return tween

## Die -- dramatic death: time-freeze flash, burst expand, data dissolve spin
static func play_die(sprite: CanvasItem) -> Tween:
	_kill_existing(sprite)
	_get_base_scale(sprite)
	var tween = sprite.create_tween()
	# Freeze frame -- bright white + scale pop
	tween.tween_property(sprite, "modulate", Color(4.0, 4.0, 4.0), 0.03)
	tween.parallel().tween_property(sprite, "scale", _bs(sprite, 1.2, 1.2), 0.03)
	# Hold the white flash
	tween.tween_interval(0.08)
	# Pull to red
	tween.tween_property(sprite, "modulate", Color(1.5, 0.1, 0.05), 0.06)
	# Death burst -- expand violently
	tween.tween_property(sprite, "scale", _bs(sprite, 1.6, 1.6), 0.08).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	# Data dissolve -- spin + collapse + fade
	tween.tween_property(sprite, "rotation", TAU * 1.5, 0.5).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.parallel().tween_property(sprite, "scale", _bs(sprite, 0.02, 0.02), 0.5).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	tween.parallel().tween_property(sprite, "modulate", Color(0.5, 0, 1, 0), 0.45).set_trans(Tween.TRANS_SINE)
	# Upward drift as they dissolve
	tween.parallel().tween_property(sprite, "position:y", sprite.position.y - 30, 0.5).set_trans(Tween.TRANS_SINE)
	_store_tween(sprite, tween)
	return tween

## Dash -- afterimage stretch with ghost trail feel + elastic snap-back
static func play_dash(sprite: CanvasItem, _direction: float = 1.0) -> Tween:
	_kill_existing(sprite)
	_get_base_scale(sprite)
	var tween = sprite.create_tween()
	# Pre-dash crouch
	tween.tween_property(sprite, "scale", _bs(sprite, 1.15, 0.85), 0.03)
	# DASH -- extreme horizontal stretch + ghost fade
	tween.tween_property(sprite, "scale", _bs(sprite, 1.8, 0.6), 0.03).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(sprite, "modulate:a", 0.25, 0.03)
	# Ghost trail phase
	tween.tween_property(sprite, "scale", _bs(sprite, 1.5, 0.7), 0.04)
	tween.parallel().tween_property(sprite, "modulate:a", 0.4, 0.04)
	# Rematerialize
	tween.tween_property(sprite, "scale", _bs(sprite, 0.85, 1.15), 0.06).set_trans(Tween.TRANS_SINE)
	tween.parallel().tween_property(sprite, "modulate:a", 0.9, 0.06)
	# Final settle with bounce
	tween.tween_property(sprite, "scale", _bs(sprite, 1.05, 0.97), 0.05).set_trans(Tween.TRANS_SINE)
	tween.parallel().tween_property(sprite, "modulate:a", 1.0, 0.05)
	tween.tween_property(sprite, "scale", bs, 0.06).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_store_tween(sprite, tween)
	return tween

## Pogo bounce -- Hollow Knight nail-bounce: sharp squash on contact, stretch upward
static func play_pogo_bounce(sprite: CanvasItem) -> Tween:
	_kill_existing(sprite)
	_get_base_scale(sprite)
	var tween = sprite.create_tween()
	# IMPACT -- hard squash + white flash (nail hits enemy below)
	tween.tween_property(sprite, "scale", _bs(sprite, 1.4, 0.55), 0.03).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(sprite, "modulate", Color(2.0, 2.0, 2.0), 0.02)
	# Hold the squash briefly (this IS the "nail hit pause" visual)
	tween.tween_interval(0.04)
	# BOUNCE -- explosive vertical stretch (player launches upward)
	tween.tween_property(sprite, "scale", _bs(sprite, 0.7, 1.4), 0.05).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(sprite, "modulate", Color.WHITE, 0.06)
	# Settle into air pose
	tween.tween_property(sprite, "scale", _bs(sprite, 0.88, 1.12), 0.08).set_trans(Tween.TRANS_SINE)
	tween.tween_property(sprite, "scale", bs, 0.1).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_store_tween(sprite, tween)
	return tween

## Hack start -- digital glow aura, levitate, purple energy channeling
static func play_hack_start(sprite: CanvasItem) -> Tween:
	_kill_existing(sprite)
	_get_base_scale(sprite)
	var tween = sprite.create_tween()
	# Digital flicker in
	tween.tween_property(sprite, "modulate", Color(0.6, 0.2, 1.0), 0.05)
	tween.tween_property(sprite, "modulate", Color(0.9, 0.5, 1.0), 0.05)
	tween.tween_property(sprite, "modulate", Color(0.5, 0.1, 0.8), 0.05)
	# Levitate
	tween.tween_property(sprite, "position:y", sprite.position.y - 12, 0.25).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(sprite, "scale", _bs(sprite, 1.1, 1.1), 0.25)
	# Settle into purple glow
	tween.tween_property(sprite, "modulate", Color(0.8, 0.4, 1.0), 0.15)

	var arm = sprite.get_node_or_null("Arm")
	if arm:
		arm.visible = true
		arm.modulate = Color(0, 1, 0.5)
		tween.parallel().tween_property(arm, "position:y", arm.position.y - 15, 0.3)

	_store_tween(sprite, tween)
	return tween

## Hack loop -- pulsating energy channel with scale throb
static func play_hack_loop(sprite: CanvasItem) -> Tween:
	_kill_existing(sprite)
	var tween = sprite.create_tween().set_loops()
	# Glow bright
	tween.tween_property(sprite, "modulate", Color(1.0, 0.6, 1.3), 0.25).set_trans(Tween.TRANS_SINE)
	tween.parallel().tween_property(sprite, "scale", _bs(sprite, 1.12, 1.12), 0.25).set_trans(Tween.TRANS_SINE)
	# Dim
	tween.tween_property(sprite, "modulate", Color(0.6, 0.3, 0.8), 0.25).set_trans(Tween.TRANS_SINE)
	tween.parallel().tween_property(sprite, "scale", _bs(sprite, 1.05, 1.05), 0.25).set_trans(Tween.TRANS_SINE)
	_store_tween(sprite, tween)
	return tween

## Heal -- rising golden-green aura with scale burst and gentle float
static func play_heal(sprite: CanvasItem) -> Tween:
	_kill_existing(sprite)
	var base_y = sprite.position.y
	_get_base_scale(sprite)
	var tween = sprite.create_tween()
	# Initial green flash
	tween.tween_property(sprite, "modulate", Color(0.5, 1.5, 0.5), 0.08)
	tween.parallel().tween_property(sprite, "scale", _bs(sprite, 1.1, 1.1), 0.08)
	# Rise up with golden glow
	tween.tween_property(sprite, "position:y", base_y - 8, 0.25).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(sprite, "modulate", Color(0.8, 1.2, 0.4), 0.25)
	# Pulse burst at apex
	tween.tween_property(sprite, "scale", _bs(sprite, 1.15, 1.15), 0.06).set_trans(Tween.TRANS_QUAD)
	tween.tween_property(sprite, "scale", bs, 0.08).set_trans(Tween.TRANS_ELASTIC)
	# Float back down
	tween.tween_property(sprite, "position:y", base_y, 0.3).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.parallel().tween_property(sprite, "modulate", Color.WHITE, 0.3).set_trans(Tween.TRANS_SINE)
	_store_tween(sprite, tween)
	return tween

## Defend / Parry -- brace pose with shield flash
static func play_defend(sprite: CanvasItem) -> Tween:
	_kill_existing(sprite)
	_get_base_scale(sprite)
	var tween = sprite.create_tween()
	# Brace -- widen stance
	tween.tween_property(sprite, "scale", _bs(sprite, 1.1, 0.95), 0.06).set_trans(Tween.TRANS_QUAD)
	# Shield flash
	tween.tween_property(sprite, "modulate", Color(0.6, 0.8, 1.5), 0.04)
	tween.tween_property(sprite, "modulate", Color(0.7, 0.85, 1.2), 0.1)
	# Hold brace
	tween.tween_interval(0.15)
	# Release
	tween.tween_property(sprite, "scale", bs, 0.12).set_trans(Tween.TRANS_SINE)
	tween.parallel().tween_property(sprite, "modulate", Color.WHITE, 0.12)
	_store_tween(sprite, tween)
	return tween

## Wall slide -- pressed against wall with friction vibrate
static func play_wall_slide(sprite: CanvasItem) -> Tween:
	_kill_existing(sprite)
	var tween = sprite.create_tween().set_loops()
	# Scrape down -- subtle vibrate
	tween.tween_property(sprite, "position:x", sprite.position.x + 1, 0.04)
	tween.parallel().tween_property(sprite, "scale", _bs(sprite, 1.05, 0.97), 0.04)
	tween.tween_property(sprite, "position:x", sprite.position.x - 1, 0.04)
	tween.parallel().tween_property(sprite, "scale", _bs(sprite, 0.98, 1.02), 0.04)
	tween.tween_property(sprite, "position:x", sprite.position.x, 0.04)
	tween.parallel().tween_property(sprite, "scale", _bs(sprite, 1.02, 0.99), 0.04)
	_store_tween(sprite, tween)
	return tween

## Sprint -- faster, more aggressive run
static func play_sprint(sprite: CanvasItem, direction: float = 1.0) -> Tween:
	_kill_existing(sprite)
	_get_base_scale(sprite)
	var ds = sign(direction) if direction != 0 else 1.0
	sprite.scale = Vector2(abs(bs.x) * ds, abs(bs.y))
	var base_y = _get_base_y(sprite)
	var tween = sprite.create_tween().set_loops()
	# Aggressive lean forward
	tween.tween_property(sprite, "rotation", deg_to_rad(10 * ds), 0.04)
	tween.parallel().tween_property(sprite, "scale", _bsd(sprite, 1.12, 0.88, ds), 0.04)
	# Explosive step up
	tween.tween_property(sprite, "position:y", base_y - 8, 0.05).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(sprite, "scale", _bsd(sprite, 0.88, 1.15, ds), 0.05)
	# Impact down
	tween.tween_property(sprite, "position:y", base_y + 2, 0.04).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.parallel().tween_property(sprite, "scale", _bsd(sprite, 1.1, 0.9, ds), 0.04)
	# Quick recovery
	tween.tween_property(sprite, "position:y", base_y, 0.03)
	tween.parallel().tween_property(sprite, "rotation", deg_to_rad(6 * ds), 0.03)
	_store_tween(sprite, tween)
	return tween

# ---------------------------------------------------------------------------
# SLIME ANIMATIONS -- gelatinous jiggle physics
# ---------------------------------------------------------------------------

## Slime idle -- organic jelly wobble with secondary motion
static func play_slime_idle(sprite: CanvasItem) -> Tween:
	_kill_existing(sprite)
	var base_y = _get_base_y(sprite)
	_get_base_scale(sprite)
	var tween = sprite.create_tween().set_loops()
	# Squish wide (exhale)
	tween.tween_property(sprite, "scale", _bs(sprite, 1.15, 0.85), 0.35).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.parallel().tween_property(sprite, "position:y", base_y + 2, 0.35).set_trans(Tween.TRANS_SINE)
	# Stretch tall (inhale)
	tween.tween_property(sprite, "scale", _bs(sprite, 0.85, 1.15), 0.35).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.parallel().tween_property(sprite, "position:y", base_y - 2, 0.35).set_trans(Tween.TRANS_SINE)
	# Subtle asymmetric wobble
	tween.tween_property(sprite, "scale", _bs(sprite, 1.08, 0.92), 0.25).set_trans(Tween.TRANS_SINE)
	tween.parallel().tween_property(sprite, "rotation", deg_to_rad(2), 0.25).set_trans(Tween.TRANS_SINE)
	tween.tween_property(sprite, "scale", _bs(sprite, 0.92, 1.08), 0.25).set_trans(Tween.TRANS_SINE)
	tween.parallel().tween_property(sprite, "rotation", deg_to_rad(-2), 0.25).set_trans(Tween.TRANS_SINE)
	tween.tween_property(sprite, "rotation", 0.0, 0.15)
	_store_tween(sprite, tween)
	return tween

## Slime hop -- dramatic squash-launch-arc-splat cycle
static func play_slime_hop(sprite: CanvasItem) -> Tween:
	_kill_existing(sprite)
	var base_y = sprite.position.y
	_get_base_scale(sprite)
	var tween = sprite.create_tween()
	# Pre-hop SQUASH
	tween.tween_property(sprite, "scale", _bs(sprite, 1.45, 0.5), 0.12).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	# LAUNCH
	tween.tween_property(sprite, "scale", _bs(sprite, 0.6, 1.5), 0.06).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(sprite, "position:y", base_y - 40, 0.15).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	# Air wobble
	tween.tween_property(sprite, "scale", _bs(sprite, 0.9, 1.1), 0.05).set_trans(Tween.TRANS_SINE)
	tween.tween_property(sprite, "scale", _bs(sprite, 1.1, 0.9), 0.05).set_trans(Tween.TRANS_SINE)
	# FALL
	tween.tween_property(sprite, "scale", _bs(sprite, 0.7, 1.3), 0.08)
	tween.parallel().tween_property(sprite, "position:y", base_y, 0.12).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	# SPLAT landing
	tween.tween_property(sprite, "scale", _bs(sprite, 1.5, 0.5), 0.04).set_trans(Tween.TRANS_QUAD)
	# Bounce recovery
	tween.tween_property(sprite, "scale", _bs(sprite, 0.85, 1.15), 0.06).set_trans(Tween.TRANS_ELASTIC)
	tween.tween_property(sprite, "scale", _bs(sprite, 1.05, 0.95), 0.05)
	tween.tween_property(sprite, "scale", bs, 0.06).set_trans(Tween.TRANS_SINE)
	_store_tween(sprite, tween)
	return tween

## Slime splat death -- flatten + spread + ooze dissolve
static func play_slime_die(sprite: CanvasItem) -> Tween:
	_kill_existing(sprite)
	var tween = sprite.create_tween()
	# Impact squish
	tween.tween_property(sprite, "scale", _bs(sprite, 1.3, 0.7), 0.04)
	# POP -- white flash
	tween.tween_property(sprite, "modulate", Color(2.0, 2.0, 2.0), 0.03)
	# Spread into puddle
	tween.tween_property(sprite, "scale", _bs(sprite, 2.5, 0.15), 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	tween.parallel().tween_property(sprite, "modulate", Color(0.2, 1.0, 0.2, 0.6), 0.12)
	# Wobble as puddle
	tween.tween_property(sprite, "scale", _bs(sprite, 2.3, 0.2), 0.06).set_trans(Tween.TRANS_SINE)
	tween.tween_property(sprite, "scale", _bs(sprite, 2.6, 0.12), 0.06).set_trans(Tween.TRANS_SINE)
	# Dissolve
	tween.tween_property(sprite, "modulate:a", 0.0, 0.35).set_trans(Tween.TRANS_SINE)
	_store_tween(sprite, tween)
	return tween

## Slime hacked -- corrupted color cycling with digital stutter
static func play_slime_hacked(sprite: CanvasItem) -> Tween:
	_kill_existing(sprite)
	var tween = sprite.create_tween().set_loops()
	tween.tween_property(sprite, "modulate", Color(1.0, 0.3, 1.0), 0.15)
	tween.parallel().tween_property(sprite, "scale", _bs(sprite, 1.05, 0.95), 0.15)
	tween.tween_property(sprite, "modulate", Color(0.3, 1.0, 0.5), 0.15)
	tween.parallel().tween_property(sprite, "scale", _bs(sprite, 0.95, 1.05), 0.15)
	tween.tween_property(sprite, "modulate", Color(1.0, 0.5, 0.8), 0.1)
	tween.parallel().tween_property(sprite, "rotation", deg_to_rad(3), 0.1)
	tween.tween_property(sprite, "rotation", deg_to_rad(-3), 0.1)
	tween.tween_property(sprite, "rotation", 0.0, 0.05)
	_store_tween(sprite, tween)
	return tween

# ---------------------------------------------------------------------------
# KNIGHT BOSS ANIMATIONS -- heavy, imposing, ground-shaking
# ---------------------------------------------------------------------------

## Knight idle -- menacing slow breathing with armor weight
static func play_knight_idle(sprite: CanvasItem) -> Tween:
	_kill_existing(sprite)
	var base_y = _get_base_y(sprite)
	_get_base_scale(sprite)
	var tween = sprite.create_tween().set_loops()
	# Heavy inhale
	tween.tween_property(sprite, "position:y", base_y - 2, 1.0).set_trans(Tween.TRANS_SINE)
	tween.parallel().tween_property(sprite, "scale", _bs(sprite, 1.02, 1.02), 1.0).set_trans(Tween.TRANS_SINE)
	# Heavy exhale
	tween.tween_property(sprite, "position:y", base_y + 1, 1.2).set_trans(Tween.TRANS_SINE)
	tween.parallel().tween_property(sprite, "scale", _bs(sprite, 0.99, 0.99), 1.2).set_trans(Tween.TRANS_SINE)
	tween.parallel().tween_property(sprite, "rotation", deg_to_rad(-0.5), 1.2).set_trans(Tween.TRANS_SINE)
	tween.tween_property(sprite, "position:y", base_y, 0.6).set_trans(Tween.TRANS_SINE)
	tween.parallel().tween_property(sprite, "scale", bs, 0.6)
	tween.parallel().tween_property(sprite, "rotation", 0.0, 0.6)
	_store_tween(sprite, tween)
	return tween

## Knight horizontal slash
static func play_knight_slash(sprite: CanvasItem) -> Tween:
	_kill_existing(sprite)
	var sword = sprite.get_node_or_null("Sword")
	var base_x = _get_rest_x(sprite)
	_get_base_scale(sprite)
	var tween = sprite.create_tween()
	# Heavy wind-up
	tween.tween_property(sprite, "rotation", deg_to_rad(-20), 0.25).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.parallel().tween_property(sprite, "position:x", base_x + 6, 0.25)
	tween.parallel().tween_property(sprite, "scale", _bs(sprite, 0.9, 1.1), 0.25)
	if sword:
		tween.parallel().tween_property(sword, "rotation", deg_to_rad(-100), 0.25)
	# Brief hold
	tween.tween_interval(0.06)
	# SLASH
	tween.tween_property(sprite, "rotation", deg_to_rad(15), 0.06).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(sprite, "position:x", base_x - 8, 0.06)
	tween.parallel().tween_property(sprite, "scale", _bs(sprite, 1.15, 0.9), 0.06)
	tween.parallel().tween_property(sprite, "modulate", Color(1.5, 1.5, 1.5), 0.04)
	if sword:
		tween.parallel().tween_property(sword, "rotation", deg_to_rad(100), 0.06)
	# Recovery
	tween.tween_property(sprite, "rotation", 0.0, 0.3).set_trans(Tween.TRANS_SINE)
	tween.parallel().tween_property(sprite, "position:x", base_x, 0.3)
	tween.parallel().tween_property(sprite, "scale", bs, 0.25)
	tween.parallel().tween_property(sprite, "modulate", Color.WHITE, 0.15)
	if sword:
		tween.parallel().tween_property(sword, "rotation", 0.0, 0.3)
	_store_tween(sprite, tween)
	return tween

## Knight vertical crush -- raise high, dramatic slam
static func play_knight_crush(sprite: CanvasItem) -> Tween:
	_kill_existing(sprite)
	var base_y = sprite.position.y
	_get_base_scale(sprite)
	var tween = sprite.create_tween()
	# Raise up
	tween.tween_property(sprite, "position:y", base_y - 50, 0.35).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(sprite, "scale", _bs(sprite, 0.85, 1.25), 0.35)
	# Dread pause
	tween.tween_interval(0.1)
	# SLAM
	tween.tween_property(sprite, "position:y", base_y + 8, 0.06).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.parallel().tween_property(sprite, "scale", _bs(sprite, 1.35, 0.7), 0.06)
	tween.parallel().tween_property(sprite, "modulate", Color(1.5, 1.2, 1.0), 0.04)
	# Ground shake
	tween.tween_property(sprite, "position:x", sprite.position.x - 4, 0.02)
	tween.tween_property(sprite, "position:x", sprite.position.x + 4, 0.02)
	tween.tween_property(sprite, "position:x", sprite.position.x - 3, 0.02)
	tween.tween_property(sprite, "position:x", sprite.position.x + 2, 0.02)
	tween.tween_property(sprite, "position:x", sprite.position.x, 0.02)
	# Recover
	tween.tween_property(sprite, "position:y", base_y, 0.2).set_trans(Tween.TRANS_SINE)
	tween.parallel().tween_property(sprite, "scale", bs, 0.2)
	tween.parallel().tween_property(sprite, "modulate", Color.WHITE, 0.15)
	_store_tween(sprite, tween)
	return tween

## Knight error/glitched -- violent digital corruption
static func play_knight_error(sprite: CanvasItem) -> Tween:
	_kill_existing(sprite)
	var base_pos = sprite.position
	_get_base_scale(sprite)
	var tween = sprite.create_tween()
	for i in range(25):
		var offset = Vector2(randf_range(-8, 8), randf_range(-6, 6))
		var glitch_color = Color(randf(), randf(), randf())
		var glitch_scale = _bs(sprite, randf_range(0.9, 1.1), randf_range(0.9, 1.1))
		tween.tween_property(sprite, "position", base_pos + offset, 0.025)
		tween.parallel().tween_property(sprite, "modulate", glitch_color, 0.025)
		tween.parallel().tween_property(sprite, "scale", glitch_scale, 0.025)
	tween.tween_property(sprite, "position", base_pos, 0.08)
	tween.parallel().tween_property(sprite, "modulate", Color.WHITE, 0.08)
	tween.parallel().tween_property(sprite, "scale", bs, 0.08)
	_store_tween(sprite, tween)
	return tween

## Knight stunned -- dazed wobble
static func play_knight_stunned(sprite: CanvasItem) -> Tween:
	_kill_existing(sprite)
	var base_pos = sprite.position
	var tween = sprite.create_tween().set_loops()
	tween.tween_property(sprite, "position", base_pos + Vector2(4, 0), 0.04)
	tween.parallel().tween_property(sprite, "rotation", deg_to_rad(2), 0.04)
	tween.tween_property(sprite, "position", base_pos + Vector2(-4, 0), 0.04)
	tween.parallel().tween_property(sprite, "rotation", deg_to_rad(-2), 0.04)
	tween.tween_property(sprite, "position", base_pos + Vector2(2, -1), 0.04)
	tween.parallel().tween_property(sprite, "rotation", deg_to_rad(1), 0.04)
	tween.tween_property(sprite, "position", base_pos + Vector2(-2, 1), 0.04)
	tween.parallel().tween_property(sprite, "rotation", deg_to_rad(-1), 0.04)
	_store_tween(sprite, tween)
	return tween

## Knight T-pose -- arms out, freeze, digital shutdown
static func play_knight_tpose(sprite: CanvasItem) -> Tween:
	_kill_existing(sprite)
	var sword = sprite.get_node_or_null("Sword")
	var shield = sprite.get_node_or_null("Shield")
	var tween = sprite.create_tween()
	if sword:
		tween.tween_property(sword, "rotation", deg_to_rad(90), 0.3)
		tween.parallel().tween_property(sword, "position:x", 35, 0.3)
	if shield:
		tween.parallel().tween_property(shield, "rotation", deg_to_rad(-90), 0.3)
		tween.parallel().tween_property(shield, "position:x", -35, 0.3)
	tween.tween_property(sprite, "modulate", Color(0.4, 0.4, 0.5, 0.6), 0.25)
	tween.parallel().tween_property(sprite, "scale", _bs(sprite, 1.05, 1.05), 0.25)
	_store_tween(sprite, tween)
	return tween

# ---------------------------------------------------------------------------
# BOAR ANIMATIONS -- brutal, heavy, feral
# ---------------------------------------------------------------------------

## Boar charge -- snort warning, devastating rush
static func play_boar_charge(sprite: CanvasItem) -> Tween:
	_kill_existing(sprite)
	var base_x = sprite.position.x
	_get_base_scale(sprite)
	var tween = sprite.create_tween()
	# Snort
	tween.tween_property(sprite, "scale", _bs(sprite, 1.15, 0.9), 0.15).set_trans(Tween.TRANS_QUAD)
	tween.parallel().tween_property(sprite, "rotation", deg_to_rad(3), 0.15)
	tween.tween_property(sprite, "scale", _bs(sprite, 0.9, 1.1), 0.1)
	tween.parallel().tween_property(sprite, "rotation", deg_to_rad(-2), 0.1)
	# Dig in
	tween.tween_property(sprite, "scale", _bs(sprite, 1.2, 0.8), 0.08)
	tween.parallel().tween_property(sprite, "rotation", deg_to_rad(-8), 0.08)
	# CHARGE
	tween.tween_property(sprite, "position:x", base_x - 150, 0.2).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.parallel().tween_property(sprite, "scale", _bs(sprite, 1.3, 0.75), 0.1)
	tween.parallel().tween_property(sprite, "modulate", Color(1.3, 0.8, 0.8), 0.1)
	# Impact stop
	tween.tween_property(sprite, "rotation", deg_to_rad(5), 0.05)
	tween.parallel().tween_property(sprite, "scale", _bs(sprite, 0.85, 1.15), 0.05)
	tween.parallel().tween_property(sprite, "modulate", Color.WHITE, 0.1)
	tween.tween_property(sprite, "rotation", 0.0, 0.15)
	tween.parallel().tween_property(sprite, "scale", bs, 0.15)
	_store_tween(sprite, tween)
	return tween

## Boar enrage -- pulsing red aura with scale growth
static func play_boar_enrage(sprite: CanvasItem) -> Tween:
	_kill_existing(sprite)
	var glow = sprite.get_node_or_null("CorruptionGlow")
	var tween = sprite.create_tween()
	# Grow with rage
	tween.tween_property(sprite, "scale", _bs(sprite, 1.2, 1.2), 0.25).set_trans(Tween.TRANS_QUAD)
	# Red pulse
	tween.tween_property(sprite, "modulate", Color(1.5, 0.2, 0.2), 0.1)
	if glow:
		tween.parallel().tween_property(glow, "color:a", 0.7, 0.1)
	tween.tween_property(sprite, "modulate", Color(1.0, 0.5, 0.5), 0.1)
	tween.tween_property(sprite, "modulate", Color(1.3, 0.3, 0.3), 0.1)
	# Settle at enraged size
	tween.tween_property(sprite, "modulate", Color.WHITE, 0.25)
	tween.parallel().tween_property(sprite, "scale", _bs(sprite, 1.1, 1.1), 0.2)
	if glow:
		tween.parallel().tween_property(glow, "color:a", 0.3, 0.25)
	_store_tween(sprite, tween)
	return tween

# ---------------------------------------------------------------------------
# ELARA ANIMATIONS -- ethereal, magical, glitch-witch aura
# ---------------------------------------------------------------------------

## Elara idle -- mystical float with glowing aura pulse
static func play_elara_idle(sprite: CanvasItem) -> Tween:
	_kill_existing(sprite)
	var glow = sprite.get_node_or_null("Glow")
	var base_y = _get_base_y(sprite)
	_get_base_scale(sprite)
	var tween = sprite.create_tween().set_loops()
	# Float up
	tween.tween_property(sprite, "position:y", base_y - 6, 1.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.parallel().tween_property(sprite, "scale", _bs(sprite, 0.98, 1.03), 1.2).set_trans(Tween.TRANS_SINE)
	tween.parallel().tween_property(sprite, "rotation", deg_to_rad(1.5), 1.2).set_trans(Tween.TRANS_SINE)
	if glow:
		tween.parallel().tween_property(glow, "color:a", 0.3, 1.2)
	# Float down
	tween.tween_property(sprite, "position:y", base_y + 4, 1.4).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.parallel().tween_property(sprite, "scale", _bs(sprite, 1.02, 0.98), 1.4).set_trans(Tween.TRANS_SINE)
	tween.parallel().tween_property(sprite, "rotation", deg_to_rad(-1), 1.4).set_trans(Tween.TRANS_SINE)
	if glow:
		tween.parallel().tween_property(glow, "color:a", 0.1, 1.4)
	# Return to center
	tween.tween_property(sprite, "position:y", base_y, 0.8).set_trans(Tween.TRANS_SINE)
	tween.parallel().tween_property(sprite, "scale", bs, 0.8)
	tween.parallel().tween_property(sprite, "rotation", 0.0, 0.8)
	_store_tween(sprite, tween)
	return tween

## Elara cast -- dramatic energy channeling
static func play_elara_cast(sprite: CanvasItem) -> Tween:
	_kill_existing(sprite)
	var wire_arm = sprite.get_node_or_null("WireframeArm")
	var glow = sprite.get_node_or_null("Glow")
	_get_base_scale(sprite)
	var tween = sprite.create_tween()

	# Channel energy
	tween.tween_property(sprite, "modulate", Color(0.9, 0.6, 1.3), 0.15)
	tween.parallel().tween_property(sprite, "scale", _bs(sprite, 1.08, 1.08), 0.15)
	if wire_arm:
		wire_arm.visible = true
		tween.parallel().tween_property(wire_arm, "position:y", wire_arm.position.y - 18, 0.2)
		tween.parallel().tween_property(wire_arm, "modulate", Color(0, 1.5, 0.5, 1.0), 0.2)
	if glow:
		tween.parallel().tween_property(glow, "color:a", 0.6, 0.2)
		tween.parallel().tween_property(glow, "scale", Vector2(1.6, 1.6), 0.2)

	# Charge up
	tween.tween_property(sprite, "modulate", Color(1.3, 1.0, 1.8), 0.1)
	tween.parallel().tween_property(sprite, "scale", _bs(sprite, 1.12, 1.12), 0.1)

	# Hold
	tween.tween_interval(0.4)

	# Release burst
	tween.tween_property(sprite, "scale", _bs(sprite, 1.2, 1.2), 0.05)
	tween.parallel().tween_property(sprite, "modulate", Color(2.0, 1.5, 2.5), 0.05)
	tween.tween_property(sprite, "modulate", Color.WHITE, 0.2)
	tween.parallel().tween_property(sprite, "scale", bs, 0.2).set_trans(Tween.TRANS_ELASTIC)
	if wire_arm:
		tween.parallel().tween_property(wire_arm, "position:y", wire_arm.position.y, 0.2)
		tween.tween_callback(func(): wire_arm.visible = false)
	if glow:
		tween.parallel().tween_property(glow, "color:a", 0.15, 0.25)
		tween.parallel().tween_property(glow, "scale", Vector2(1.0, 1.0), 0.25)

	_store_tween(sprite, tween)
	return tween

## Elara spawn in -- digital materialization
static func play_elara_spawn(sprite: CanvasItem) -> Tween:
	_kill_existing(sprite)
	_get_base_scale(sprite)
	sprite.scale = Vector2(0.0, abs(bs.y) * 2.5)
	sprite.modulate = Color(1, 1, 1, 0)
	var tween = sprite.create_tween()
	# Rapid digital flicker
	for i in range(6):
		var alpha = 0.4 + randf() * 0.4
		tween.tween_property(sprite, "modulate:a", alpha, 0.03)
		tween.parallel().tween_property(sprite, "scale:x", abs(bs.x) * randf_range(0.0, 0.5), 0.03)
		tween.tween_property(sprite, "modulate:a", 0.0, 0.02)
	# Materialize
	tween.tween_property(sprite, "modulate:a", 1.0, 0.1)
	tween.parallel().tween_property(sprite, "scale", bs, 0.25).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	# Subtle settle glow
	tween.tween_property(sprite, "modulate", Color(0.9, 0.7, 1.2), 0.1)
	tween.tween_property(sprite, "modulate", Color.WHITE, 0.15)
	_store_tween(sprite, tween)
	return tween

# ---------------------------------------------------------------------------
# ENVIRONMENT ANIMATIONS
# ---------------------------------------------------------------------------

## Tree sway
static func play_tree_sway(node: CanvasItem) -> Tween:
	_kill_existing(node)
	var period = 2.0 + randf() * 1.5
	var tween = node.create_tween().set_loops()
	tween.tween_property(node, "rotation", deg_to_rad(3), period).set_trans(Tween.TRANS_SINE)
	tween.parallel().tween_property(node, "scale:x", node.scale.x * 1.02, period).set_trans(Tween.TRANS_SINE)
	tween.tween_property(node, "rotation", deg_to_rad(-2.5), period * 0.9).set_trans(Tween.TRANS_SINE)
	tween.parallel().tween_property(node, "scale:x", node.scale.x * 0.98, period * 0.9).set_trans(Tween.TRANS_SINE)
	tween.tween_property(node, "rotation", 0.0, period * 0.4).set_trans(Tween.TRANS_SINE)
	tween.parallel().tween_property(node, "scale:x", node.scale.x, period * 0.4).set_trans(Tween.TRANS_SINE)
	_store_tween(node, tween)
	return tween

## Corruption area pulse
static func play_corruption_pulse(node: CanvasItem) -> Tween:
	_kill_existing(node)
	var tween = node.create_tween().set_loops()
	tween.tween_property(node, "modulate:a", 0.55, 0.6).set_trans(Tween.TRANS_SINE)
	tween.parallel().tween_property(node, "modulate", Color(0.8, 0.2, 0.8, 0.55), 0.6).set_trans(Tween.TRANS_SINE)
	tween.tween_property(node, "modulate:a", 0.15, 0.8).set_trans(Tween.TRANS_SINE)
	tween.parallel().tween_property(node, "modulate", Color(0.5, 0.0, 0.5, 0.15), 0.8).set_trans(Tween.TRANS_SINE)
	_store_tween(node, tween)
	return tween

## Floating debris
static func play_floating(node: CanvasItem, amplitude: float = 8.0) -> Tween:
	_kill_existing(node)
	var base_y = node.position.y
	var period = 2.0 + randf() * 1.5
	var tween = node.create_tween().set_loops()
	tween.tween_property(node, "position:y", base_y - amplitude, period).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.parallel().tween_property(node, "rotation", deg_to_rad(3), period).set_trans(Tween.TRANS_SINE)
	tween.tween_property(node, "position:y", base_y + amplitude, period * 1.1).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.parallel().tween_property(node, "rotation", deg_to_rad(-3), period * 1.1).set_trans(Tween.TRANS_SINE)
	_store_tween(node, tween)
	return tween

## Sign/torch swing
static func play_swing(node: CanvasItem, max_angle: float = 5.0) -> Tween:
	_kill_existing(node)
	var tween = node.create_tween().set_loops()
	tween.tween_property(node, "rotation", deg_to_rad(max_angle), 1.2).set_trans(Tween.TRANS_SINE)
	tween.tween_property(node, "rotation", deg_to_rad(-max_angle * 0.8), 1.1).set_trans(Tween.TRANS_SINE)
	tween.tween_property(node, "rotation", deg_to_rad(max_angle * 0.6), 1.0).set_trans(Tween.TRANS_SINE)
	tween.tween_property(node, "rotation", deg_to_rad(-max_angle * 0.9), 1.15).set_trans(Tween.TRANS_SINE)
	_store_tween(node, tween)
	return tween

## Water shimmer
static func play_water_shimmer(node: CanvasItem) -> Tween:
	_kill_existing(node)
	var period = 0.6 + randf() * 0.5
	var tween = node.create_tween().set_loops()
	tween.tween_property(node, "modulate", Color(0.9, 0.95, 1.1, 0.85), period).set_trans(Tween.TRANS_SINE)
	tween.tween_property(node, "modulate", Color(1.0, 1.0, 1.0, 1.0), period * 0.8).set_trans(Tween.TRANS_SINE)
	tween.tween_property(node, "modulate", Color(0.85, 0.92, 1.05, 0.9), period * 1.1).set_trans(Tween.TRANS_SINE)
	tween.tween_property(node, "modulate", Color(1.0, 1.0, 1.0, 1.0), period * 0.9).set_trans(Tween.TRANS_SINE)
	_store_tween(node, tween)
	return tween

## Null texture checkerboard flicker
static func play_null_texture(node: CanvasItem) -> Tween:
	_kill_existing(node)
	var tween = node.create_tween().set_loops()
	tween.tween_property(node, "modulate", Color(0.6, 0, 0.6), 0.2)
	tween.parallel().tween_property(node, "scale", _bs(node, 1.02, 0.98), 0.2)
	tween.tween_property(node, "modulate", Color(0, 0, 0), 0.15)
	tween.parallel().tween_property(node, "scale", _bs(node, 0.98, 1.02), 0.15)
	tween.tween_property(node, "modulate", Color(0.5, 0, 0.5), 0.25)
	tween.parallel().tween_property(node, "scale", _bs(node, 1.0, 1.0), 0.25)
	_store_tween(node, tween)
	return tween

# ---------------------------------------------------------------------------
# GENERIC / UTILITY
# ---------------------------------------------------------------------------

## Flash a color and return with optional scale punch
static func flash_color(node: CanvasItem, color: Color, duration: float = 0.15) -> Tween:
	var original = node.modulate
	_get_base_scale(node)
	var tween = node.create_tween()
	tween.tween_property(node, "modulate", color, duration * 0.25)
	tween.parallel().tween_property(node, "scale", _bs(node, 1.08, 1.08), duration * 0.25)
	tween.tween_property(node, "modulate", original, duration * 0.75)
	tween.parallel().tween_property(node, "scale", bs, duration * 0.5).set_trans(Tween.TRANS_ELASTIC)
	return tween

## Pulse scale with elastic bounce
static func pulse_scale(node: CanvasItem, scale_factor: float = 1.15, duration: float = 0.3) -> Tween:
	_get_base_scale(node)
	var tween = node.create_tween()
	tween.tween_property(node, "scale", _bs(node, scale_factor, scale_factor), duration * 0.35).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(node, "scale", bs, duration * 0.65).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	return tween

## Fade in from transparent with scale pop
static func fade_in(node: CanvasItem, duration: float = 0.5) -> Tween:
	_get_base_scale(node)
	node.modulate.a = 0.0
	node.scale = bs * 0.8
	var tween = node.create_tween()
	tween.tween_property(node, "modulate:a", 1.0, duration * 0.7).set_trans(Tween.TRANS_SINE)
	tween.parallel().tween_property(node, "scale", bs, duration).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	return tween

## Fade out to transparent with scale shrink
static func fade_out(node: CanvasItem, duration: float = 0.5) -> Tween:
	_get_base_scale(node)
	var tween = node.create_tween()
	tween.tween_property(node, "modulate:a", 0.0, duration).set_trans(Tween.TRANS_SINE)
	tween.parallel().tween_property(node, "scale", bs * 0.85, duration).set_trans(Tween.TRANS_SINE)
	return tween

## Slide in from direction with overshoot
static func slide_in(node: Control, from: String = "bottom", duration: float = 0.3) -> Tween:
	var target_pos = node.position
	match from:
		"bottom":
			node.position.y += 200
		"top":
			node.position.y -= 200
		"left":
			node.position.x -= 400
		"right":
			node.position.x += 400

	node.modulate.a = 0.0
	var tween = node.create_tween()
	tween.tween_property(node, "position", target_pos, duration).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(node, "modulate:a", 1.0, duration * 0.5)
	return tween

## Slide out with acceleration
static func slide_out(node: Control, to: String = "bottom", duration: float = 0.3) -> Tween:
	var target = node.position
	match to:
		"bottom":
			target.y += 200
		"top":
			target.y -= 200
		"left":
			target.x -= 400
		"right":
			target.x += 400

	var tween = node.create_tween()
	tween.tween_property(node, "position", target, duration).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	tween.parallel().tween_property(node, "modulate:a", 0.0, duration * 0.8)
	return tween

## Typewriter text effect for Label nodes
static func typewriter(label: Label, full_text: String, chars_per_sec: float = 30.0) -> Tween:
	label.text = ""
	label.visible_characters = 0
	label.text = full_text
	var duration = full_text.length() / maxf(chars_per_sec, 1.0)
	var tween = label.create_tween()
	tween.tween_property(label, "visible_characters", full_text.length(), duration)
	return tween

## Screen impact flash
static func play_impact_flash(sprite: CanvasItem) -> Tween:
	var original = sprite.modulate
	var tween = sprite.create_tween()
	tween.tween_property(sprite, "modulate", Color(3.0, 3.0, 3.0), 0.02)
	tween.tween_property(sprite, "modulate", original, 0.1).set_trans(Tween.TRANS_SINE)
	return tween

## Gentle hover for UI elements
static func play_ui_hover(node: CanvasItem) -> Tween:
	_kill_existing(node)
	var base_y = node.position.y
	var tween = node.create_tween().set_loops()
	tween.tween_property(node, "position:y", base_y - 4, 1.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(node, "position:y", base_y + 4, 1.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_store_tween(node, tween)
	return tween

## Cutscene walk animation -- use during cutscene character movement
static func play_cutscene_walk(sprite: CanvasItem, direction: float = 1.0) -> Tween:
	## Gentler walk animation for cutscene characters (not as aggressive as play_run).
	_kill_existing(sprite)
	_get_base_scale(sprite)
	var dir_sign = sign(direction) if direction != 0 else 1.0
	# Only flip X when the sprite child is a ColorRect; Sprite2D uses flip_h
	if sprite is ColorRect:
		sprite.scale = Vector2(abs(bs.x) * dir_sign, abs(bs.y))
	var base_y = _get_base_y(sprite)
	sprite.position.y = base_y
	var tween = sprite.create_tween().set_loops()
	# Step 1: gentle push
	tween.tween_property(sprite, "position:y", base_y - 3, 0.12).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(sprite, "scale", _bs(sprite, 0.97, 1.04), 0.12).set_trans(Tween.TRANS_SINE)
	tween.parallel().tween_property(sprite, "rotation", deg_to_rad(2 * dir_sign), 0.12).set_trans(Tween.TRANS_SINE)
	# Step 1: land
	tween.tween_property(sprite, "position:y", base_y + 1, 0.1).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	tween.parallel().tween_property(sprite, "scale", _bs(sprite, 1.03, 0.97), 0.1).set_trans(Tween.TRANS_SINE)
	tween.parallel().tween_property(sprite, "rotation", deg_to_rad(-1 * dir_sign), 0.1).set_trans(Tween.TRANS_SINE)
	# Step 2: gentle push
	tween.tween_property(sprite, "position:y", base_y - 2, 0.12).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(sprite, "scale", _bs(sprite, 0.98, 1.03), 0.12).set_trans(Tween.TRANS_SINE)
	tween.parallel().tween_property(sprite, "rotation", deg_to_rad(1.5 * dir_sign), 0.12).set_trans(Tween.TRANS_SINE)
	# Step 2: land
	tween.tween_property(sprite, "position:y", base_y, 0.1).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	tween.parallel().tween_property(sprite, "scale", bs, 0.1).set_trans(Tween.TRANS_SINE)
	tween.parallel().tween_property(sprite, "rotation", 0.0, 0.1).set_trans(Tween.TRANS_SINE)
	_store_tween(sprite, tween)
	return tween

## Cutscene idle -- gentle breathing for cutscene characters
static func play_cutscene_idle(sprite: CanvasItem) -> Tween:
	## Gentle idle for cutscene characters -- preserves base scale.
	_kill_existing(sprite)
	var base_y = _get_base_y(sprite)
	_get_base_scale(sprite)
	sprite.position.y = base_y
	sprite.rotation = 0.0
	sprite.scale = bs
	var tween = sprite.create_tween().set_loops()
	# Gentle breathe up
	tween.tween_property(sprite, "position:y", base_y - 2, 0.9).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.parallel().tween_property(sprite, "scale", _bs(sprite, 0.98, 1.02), 0.9).set_trans(Tween.TRANS_SINE)
	# Gentle breathe down
	tween.tween_property(sprite, "position:y", base_y + 1, 1.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.parallel().tween_property(sprite, "scale", _bs(sprite, 1.02, 0.98), 1.0).set_trans(Tween.TRANS_SINE)
	# Settle
	tween.tween_property(sprite, "position:y", base_y, 0.6).set_trans(Tween.TRANS_SINE)
	tween.parallel().tween_property(sprite, "scale", bs, 0.6).set_trans(Tween.TRANS_SINE)
	_store_tween(sprite, tween)
	return tween
