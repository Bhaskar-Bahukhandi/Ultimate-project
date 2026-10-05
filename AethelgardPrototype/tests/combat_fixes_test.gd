extends SceneTree
## Regression checks for the Act 1 playtest fight/collision fixes:
##   - time zones scale the player's speed once (they used to compound every
##     frame: x2 ran away into walls, x0.4 crawled at about 17%);
##   - placeholder rectangles flip around their centre (they used to flip
##     around the top-left corner, drawing the body a full width off its box);
##   - the top-down player moves in floating mode (grounded mode snagged on
##     corners).
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
