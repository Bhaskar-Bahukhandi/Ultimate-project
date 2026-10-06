extends SceneTree
## Regression checks for the Act 1 playtest fight/collision fixes:
##   - time zones scale the player's speed once (they used to compound every
##     frame: x2 ran away into walls, x0.4 crawled at about 17%);
##   - placeholder rectangles flip around their centre (they used to flip
##     around the top-left corner, drawing the body a full width off its box);
##   - the top-down player moves in floating mode (grounded mode snagged on
##     corners);
##   - combat feel (the user's decision 1): melee hits count when the swing
##     touches the enemy's body, recovery cancels into a jump, an attack pressed
##     mid-dash is remembered, and hit-pause takes the longest request instead
##     of adding them up.
## Run: tests/run_phase0_tests.ps1 -Script res://tests/combat_fixes_test.gd

const TOWER := "res://scenes/chapter2/clock_tower.tscn"
const VILLAGE := "res://scenes/chapter1/oakhaven_village.tscn"

var _passes := 0
var _failures: Array[String] = []


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	await process_frame
	if not OS.get_user_data_dir().contains("aeth_phase0_test"):
		push_error("Refusing to run: user data dir is not isolated. Use tests/run_phase0_tests.ps1.")
		quit(2)
		return
	await _test_speed_multiplier()
	await _test_combat_feel()
	await _test_topdown_motion_mode()
	print("")
	print("COMBAT FIXES RESULT: %d passed, %d failed" % [_passes, _failures.size()])
	for f in _failures:
		print("  FAIL: " + f)
	quit(0 if _failures.is_empty() else 1)


func _check(cond: bool, name: String) -> void:
	if cond:
		_passes += 1
		print("  PASS: " + name)
	else:
		_failures.append(name)
		print("  FAIL: " + name)


func _frames(n: int) -> void:
	for i in n:
		await physics_frame


## Runs right for a second at the given multiplier; returns the settled speed.
func _speed_at(player: CharacterBody2D, mult: float) -> float:
	player.set_speed_multiplier(mult)
	player.velocity = Vector2.ZERO
	Input.action_press("move_right")
	var top := 0.0
	for i in 60:
		await physics_frame
		top = maxf(top, absf(player.velocity.x))
	Input.action_release("move_right")
	print("    mult=%.2f now=%.2f top=%.0f pos=%s floor=%s dashing=%s locked=%s dlg=%s" % [mult, player.speed_multiplier, top,
		player.global_position, player.is_on_floor(), player.get("is_dashing"), player.get("_input_locked"), get_root().get_node("DialogueManager").is_active])
	await _frames(30)
	return top


## A bare stage: a floor and the side-scroll player, nothing else (real
## scenes have intro dialogue and enemies that block or shove the player).
func _bare_stage() -> CharacterBody2D:
	var stage := Node2D.new()
	stage.name = "BareStage"
	var ground := StaticBody2D.new()
	var ground_shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(8000, 40)
	ground_shape.shape = rect
	ground_shape.position = Vector2(0, 540)
	ground.add_child(ground_shape)
	stage.add_child(ground)
	var player := CharacterBody2D.new()
	player.name = "Player"
	player.add_to_group("player")
	var sprite := ColorRect.new()
	sprite.name = "Sprite"
	sprite.position = Vector2(-16, -32)
	sprite.size = Vector2(32, 32)
	player.add_child(sprite)
	var col := CollisionShape2D.new()
	var box := RectangleShape2D.new()
	box.size = Vector2(20, 32)
	col.shape = box
	col.position = Vector2(0, -16)
	player.add_child(col)
	player.set_script(load("res://scripts/combat/player_combat.gd"))
	player.position = Vector2(0, 500)
	stage.add_child(player)
	get_root().add_child(stage)
	current_scene = stage
	return get_root().get_node("BareStage/Player") as CharacterBody2D


func _test_speed_multiplier() -> void:
	print("[time zones scale speed once]")
	get_root().get_node("GameManager").reset_game()
	var player := _bare_stage()
	await _frames(20)
	get_root().get_node("DialogueManager").force_reset()
	var speed: float = player.SPEED
	var normal := await _speed_at(player, 1.0)
	var fast := await _speed_at(player, 2.0)
	var slow := await _speed_at(player, 0.4)
	_check(absf(fast - speed * 2.0) < speed * 0.1, "x2 zone tops out near 2x run speed (%.0f vs %.0f), not runaway" % [fast, speed * 2.0])
	_check(absf(slow - speed * 0.4) < speed * 0.1, "x0.4 zone gives about 40%% speed (%.0f vs %.0f), not 17%%" % [slow, speed * 0.4])
	_check(absf(normal - speed) < speed * 0.1, "no zone: normal run speed (%.0f vs %.0f)" % [normal, speed])

	print("[placeholder sprites flip around their centre]")
	var sprite := player.get_node_or_null("Sprite") as Control
	if sprite == null:
		_check(true, "player has a real sprite here (nothing to flip around a corner)")
		return
	var body_x := player.global_position.x
	player.facing_direction = -1.0
	await _frames(3)
	var r := sprite.get_global_rect()
	# get_global_rect ignores negative scale; compute the drawn span from the transform.
	var xf := sprite.get_global_transform()
	var a := xf * Vector2.ZERO
	var b := xf * Vector2(sprite.size.x, 0)
	var centre := (a.x + b.x) * 0.5
	_check(absf(centre - body_x) < 2.0, "facing left, the placeholder is drawn centred on the body (%.1f vs %.1f; size %s)" % [centre, body_x, r.size])


func _test_topdown_motion_mode() -> void:
	print("[top-down player doesn't snag on corners]")
	get_root().get_node("GameManager").reset_game()
	change_scene_to_file(VILLAGE)
	await _frames(10)
	var player := current_scene.get_node("Player") as CharacterBody2D
	_check(player.motion_mode == CharacterBody2D.MOTION_MODE_FLOATING, "top-down player uses floating motion mode")


## A stand-in enemy: a body of `width` x 40 at `pos`, plus (optionally) a big
## detection-style Area2D like EnemyBase builds.
func _dummy_enemy(stage: Node, pos: Vector2, width: float, detection_radius: float = 0.0) -> CharacterBody2D:
	var src := GDScript.new()
	src.source_code = "extends CharacterBody2D
var hits := 0
func take_damage(_a = 0, _b = null, _c = null) -> void:
	hits += 1
"
	src.reload()
	var e := CharacterBody2D.new()
	e.set_script(src)
	e.add_to_group("enemies")
	e.collision_layer = 4
	var col := CollisionShape2D.new()
	var box := RectangleShape2D.new()
	box.size = Vector2(width, 40)
	col.shape = box
	col.position = Vector2(0, -20)
	e.add_child(col)
	if detection_radius > 0.0:
		var area := Area2D.new()
		var circle := CollisionShape2D.new()
		var c := CircleShape2D.new()
		c.radius = detection_radius
		circle.shape = c
		area.add_child(circle)
		e.add_child(area)
	e.position = pos
	stage.add_child(e)
	return e


func _test_combat_feel() -> void:
	print("[combat feel: overlap hits, jump-cancel, dash buffer, hit-pause]")
	get_root().get_node("GameManager").reset_game()
	var player := _bare_stage()
	await _frames(20)
	get_root().get_node("DialogueManager").force_reset()
	var stage := current_scene
	var at := player.global_position
	var reach := Vector2(48, 0)          # a swing box 64 wide, centred 48 px ahead
	var size := Vector2(64, 48)
	# A 160-wide boss whose centre (at +130) is outside the box but whose body
	# (from +50) overlaps it: the swing visibly connects, so it must hit.
	var boss := _dummy_enemy(stage, at + Vector2(130, 0), 160.0)
	# A small enemy far away whose 140 px detection circle reaches the box.
	var far := _dummy_enemy(stage, at + Vector2(200, 0), 20.0, 140.0)
	await _frames(3)
	var hit: Array = player._get_enemies_in_melee_hitbox(reach + Vector2(0, -20), size)
	_check(boss in hit, "a swing that touches a big enemy's body hits it (its centre is outside the box)")
	_check(not far in hit, "an enemy only 'touched' through its detection area is not hit")
	boss.queue_free()
	far.queue_free()
	await _frames(2)

	# Jump-cancel: in attack recovery, a jump press jumps and ends the attack.
	player.velocity = Vector2.ZERO
	player.is_attacking = true
	player.attack_recovery_timer = 0.15
	await physics_frame
	Input.action_press("jump")
	await physics_frame
	await physics_frame
	Input.action_release("jump")
	_check(player.velocity.y < 0.0 and not player.is_attacking, "jumping during attack recovery cancels into the jump (vy %.0f, attacking %s)" % [player.velocity.y, player.is_attacking])
	await _frames(60)

	# Dash buffer: an attack pressed mid-dash is remembered, and comes out as
	# the dash ends (DASH_CANCEL_INTO_ATTACK), the way a player would do it.
	player.is_attacking = false
	player.attack_cooldown = 0.0
	var before: Dictionary = player.get_combat_attack_metrics()
	Input.action_press("sprint")
	await physics_frame
	Input.action_release("sprint")
	await physics_frame
	var was_dashing: bool = player.is_dashing
	Input.action_press("attack")
	await physics_frame
	Input.action_release("attack")
	await _frames(20)   # the dash (0.18 s) ends
	var after: Dictionary = player.get_combat_attack_metrics()
	var buffered := int(after.get("buffered_combo", 0)) - int(before.get("buffered_combo", 0))
	var started := int(after.get("started", 0)) - int(before.get("started", 0))
	_check(was_dashing and buffered >= 1 and started >= 1, "an attack pressed mid-dash is buffered and comes out after the dash (dashing %s, buffered %d, started %d)" % [was_dashing, buffered, started])
	await _frames(40)

	# Hit-pause: two requests in one hit keep the longer, not the sum.
	var fx := get_root().get_node("CombatFX")
	fx.apply_hitstop(0.04)
	fx.apply_hitstop(0.13)
	var t: float = fx.hitstop_timer
	_check(absf(t - 0.13) < 0.005, "two hit-pause requests keep the longest (%.3f s, not 0.105 or 0.17)" % t)
	await _frames(30)
