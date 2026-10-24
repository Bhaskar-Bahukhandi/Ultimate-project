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
## Run: tests/run_phase0_tests.ps1 -Script res://tests/integration/combat/combat_fixes_test.gd

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
	await _test_t11_dash_iframes()
	await _test_t11_strike_label()
	await _test_t11_one_sound()
	await _test_t11_last_kill()
	_test_t11_single_time_writer()
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


# ── Y1-P0-T11: combat-feel leftovers ─────────────────────────────────────
# Story type: Logic/Integration; output tests/integration/combat/; gate BLOCKING.

var _sfx_log: Array[String] = []


func _on_sfx_requested(sfx_name: String) -> void:
	_sfx_log.append(sfx_name)


func _sfx_count(sfx_name: String) -> int:
	return _sfx_log.count(sfx_name)


## Frees every bare stage left by earlier tests and the current scene, then
## builds a new one (earlier stages stay in the tree, and the name lookup in
## _bare_stage would return their player).
func _fresh_stage() -> CharacterBody2D:
	for c in get_root().get_children():
		if String(c.name).contains("BareStage") or c == current_scene:
			c.queue_free()
	await process_frame
	await process_frame
	get_root().get_node("GameManager").reset_game()
	var player := _bare_stage()
	await _frames(20)
	get_root().get_node("DialogueManager").force_reset()
	return player


## Waits (real time, bounded) for hitstop, its ramp and any last-kill slowdown
## to finish, then drops every time request so the next case starts at 1.0.
func _settle_fx() -> void:
	var fx := get_root().get_node("CombatFX")
	var cs := get_root().get_node("ContextStack")
	var start := Time.get_ticks_msec()
	while Time.get_ticks_msec() - start < 3000:
		var ramp: Tween = fx._hitstop_recover_tween
		if not fx.is_hitstop_active and not fx._pending_last_kill \
				and not cs.has_time_request(&"last_kill") \
				and not (ramp != null and ramp.is_valid() and ramp.is_running()):
			break
		await process_frame
	fx._pending_last_kill = false
	if fx.is_hitstop_active:
		fx._force_end_hitstop()
	cs.clear_time_scale()
	await process_frame


## A real EnemyBase subclass laid out like combat_arena.tscn's TutorialSlime.
## AI is switched off so it neither moves out of the swing nor hits the player.
func _real_enemy(stage: Node, script_path: String, pos: Vector2) -> CharacterBody2D:
	var e := CharacterBody2D.new()
	var sprite := ColorRect.new()
	sprite.name = "Sprite"
	sprite.position = Vector2(-32, -32)
	sprite.size = Vector2(64, 64)
	e.add_child(sprite)
	var col := CollisionShape2D.new()
	col.name = "CollisionShape2D"
	var box := RectangleShape2D.new()
	box.size = Vector2(64, 64)
	col.shape = box
	e.add_child(col)
	var bar := ProgressBar.new()
	bar.name = "HealthBar"
	e.add_child(bar)
	var label := Label.new()
	label.name = "Label"
	e.add_child(label)
	e.set_script(load(script_path))
	e.position = pos
	stage.add_child(e)
	e.set_physics_process(false)
	e.set_process(false)
	return e


func _reset_player(player: CharacterBody2D) -> void:
	player.invulnerable = false
	player.invuln_timer = 0.0
	player.is_dashing = false
	player.current_health = player.max_health


func _test_t11_dash_iframes() -> void:
	print("[T11 AC-1: dash i-frames are 0.18 s + a 0.05 s tail]")
	var player := await _fresh_stage()
	await _settle_fx()
	_reset_player(player)
	await _frames(2)
	# One dash: count i-frames, hit on the first non-dashing frame (absorbed),
	# then on the first vulnerable frame (lands).
	player._start_dash()
	var inv_frames := 0
	var tail_done := false
	var tail_hp_kept := false
	var tail_no_dodge := false
	var land_done := false
	var landed := false
	for i in 60:
		await physics_frame
		if player.invulnerable:
			inv_frames += 1
		if not tail_done and not player.is_dashing:
			tail_done = true
			var hp: float = player.current_health
			var soul_before: float = player.current_soul
			player.take_damage(10.0, player.global_position + Vector2(40, 0), "T11 test")
			tail_hp_kept = player.current_health == hp and player.invulnerable
			tail_no_dodge = not player._perfect_dodge_awarded and player.current_soul == soul_before
		if not player.invulnerable:
			var hp2: float = player.current_health
			player.take_damage(10.0, player.global_position + Vector2(40, 0), "T11 test")
			land_done = true
			landed = player.current_health < hp2
			break
	_check(inv_frames >= 13 and inv_frames <= 15, "T11 AC-1: a dash from rest is invulnerable for 13-15 physics frames (got %d; old code 25)" % inv_frames)
	_check(tail_done and tail_hp_kept and tail_no_dodge, "T11 AC-1: a hit on the first frame after the dash ends is absorbed without a perfect dodge or Soul (seen %s, HP kept %s, no dodge and Soul unchanged %s)" % [tail_done, tail_hp_kept, tail_no_dodge])
	_check(land_done and landed, "T11 AC-1: a hit on the first frame where invulnerable is false lands (seen %s, HP dropped %s)" % [land_done, landed])

	await _settle_fx()
	_reset_player(player)
	await _frames(2)
	player._start_dash()
	await _frames(2)
	var hp3: float = player.current_health
	var was_dashing: bool = player.is_dashing
	player.take_damage(10.0, player.global_position + Vector2(40, 0), "T11 test")
	_check(was_dashing and player._perfect_dodge_awarded and player.current_health == hp3, "T11 AC-1: a hit while dashing is a PERFECT DODGE and does no damage (dashing %s, dodge %s)" % [was_dashing, player._perfect_dodge_awarded])
	await _frames(20)

	await _settle_fx()
	_reset_player(player)
	player.invulnerable = true
	player.invuln_timer = 0.8
	player._start_dash()
	var dash_started: bool = player.is_dashing
	var guard := 0
	while player.is_dashing and guard < 40:
		await physics_frame
		guard += 1
	var at_end: float = player.invuln_timer
	await _frames(42)
	_check(dash_started and absf(at_end - 0.8) < 0.001 and player.invulnerable, "T11 AC-1: a dash during 0.8 s hurt i-frames keeps 0.8 at dash end (dash started %s, %.3f) and is still invulnerable 42 frames later (%s)" % [dash_started, at_end, player.invulnerable])
	_reset_player(player)


func _test_t11_strike_label() -> void:
	print("[T11 AC-3: STRIKE label]")
	var player := await _fresh_stage()
	await _settle_fx()
	_reset_player(player)
	player.invulnerable = true
	player.invuln_timer = 100.0
	var label: Label = player._combo_indicator
	if label == null:
		_check(false, "T11 AC-3: the player has a chain label (_combo_indicator is null)")
		return
	player.combo_step = 0
	player.attack_cooldown = 0.0
	var texts: Array[String] = []
	for step in 3:
		var guard := 0
		while (player.attack_cooldown > 0.0 or player.is_attacking) and guard < 120:
			await physics_frame
			guard += 1
		player._perform_combo_attack()
		texts.append(label.text)
	_check(", ".join(texts) == "STRIKE 1, STRIKE 2, STRIKE 3", "T11 AC-3: strikes 1, 2, 3 read STRIKE 1/2/3 (got %s)" % [texts])

	var held := true
	var frames := 0
	while player.attack_cooldown > 0.0 and frames < 120:
		if label.text != "STRIKE 3":
			held = false
		await physics_frame
		frames += 1
	_check(held and label.text == "", "T11 AC-3: after step 3 the label holds STRIKE 3 while attack_cooldown > 0 (%s, %d frames) and is empty once it reaches 0 ('%s')" % [held, frames, label.text])

	var guard2 := 0
	while (player.attack_cooldown > 0.0 or player.is_attacking) and guard2 < 120:
		await physics_frame
		guard2 += 1
	player.combo_step = 0
	player._perform_combo_attack()
	var shown := label.text
	var guard3 := 0
	while player.combo_step != 0 and guard3 < 90:
		await physics_frame
		guard3 += 1
	_check(shown == "STRIKE 1" and player.combo_step == 0 and label.text == "", "T11 AC-3: after step 1 the label clears when combo_timer lapses ('%s' then '%s')" % [shown, label.text])

	var guard4 := 0
	while (player.attack_cooldown > 0.0 or player.is_attacking) and guard4 < 120:
		await physics_frame
		guard4 += 1
	player._perform_combo_attack()
	var before_hurt := label.text
	player.invulnerable = false
	player.invuln_timer = 0.0
	player.take_damage(5.0, player.global_position + Vector2(40, 0), "T11 test")
	_check(before_hurt == "STRIKE 1" and label.text == "", "T11 AC-3: take_damage empties the label at once ('%s' then '%s')" % [before_hurt, label.text])

	var guard5 := 0
	while (player.attack_cooldown > 0.0 or player.is_attacking) and guard5 < 120:
		await physics_frame
		guard5 += 1
	player.combo_step = 0
	player._perform_combo_attack()
	var before_charged := label.text
	player._perform_charged_attack()
	_check(before_charged == "STRIKE 1" and player.combo_step == 0 and label.text == "", "T11 AC-3: a charged attack ends the chain and empties the label at once ('%s' then '%s')" % [before_charged, label.text])

	var guard6 := 0
	while (player.attack_cooldown > 0.0 or player.is_attacking) and guard6 < 120:
		await physics_frame
		guard6 += 1
	player.combo_step = 0
	player._perform_combo_attack()
	var before_retry := label.text
	player.force_restore_after_death_retry(player.global_position)
	_check(before_retry == "STRIKE 1" and label.text == "", "T11 AC-3: a death retry reset empties the label ('%s' then '%s')" % [before_retry, label.text])
	await _frames(30)
	await _settle_fx()
	_reset_player(player)


func _wait_for_sfx(sfx_name: String, max_ms: int = 2000) -> void:
	var start := Time.get_ticks_msec()
	while _sfx_count(sfx_name) == 0 and Time.get_ticks_msec() - start < max_ms:
		await physics_frame
	await _frames(20)   # any duplicate from the same hit would have come by now


func _test_t11_one_sound() -> void:
	print("[T11 AC-2: one sound per hit, one per kill]")
	var player := await _fresh_stage()
	await _settle_fx()
	var stage := current_scene
	var sfx := get_root().get_node("SFXManager")
	sfx.sfx_requested.connect(_on_sfx_requested)
	_reset_player(player)
	player.invulnerable = true   # enemies cannot interrupt the swing
	player.invuln_timer = 100.0
	player.facing_direction = 1.0
	var at := player.global_position
	var tank := _real_enemy(stage, "res://scripts/combat/enemies/slime.gd", at + Vector2(50, -32))
	await _frames(3)
	tank.max_health = 100000.0
	tank.current_health = 100000.0

	# One landed light combo hit.
	player.combo_step = 0
	player.attack_cooldown = 0.0
	player.is_attacking = false
	_sfx_log.clear()
	player._perform_combo_attack()
	await _wait_for_sfx("sword_hit")
	var tank_hit: bool = tank.current_health < 100000.0
	_check(tank_hit and _sfx_count("sword_hit") == 1, "T11 AC-2: one landed light combo hit plays exactly one sword_hit (hit %s, sword_hit %d)" % [tank_hit, _sfx_count("sword_hit")])
	await _settle_fx()

	# Parry-counter hit.
	var guard := 0
	while (player.attack_cooldown > 0.0 or player.is_attacking) and guard < 120:
		await physics_frame
		guard += 1
	player.combo_step = 0
	player.parry_counter_active = true
	player.parry_counter_timer = 5.0
	var hp_before: float = tank.current_health
	_sfx_log.clear()
	player._perform_combo_attack()
	await _wait_for_sfx("heavy_hit")
	_check(tank.current_health < hp_before and _sfx_count("heavy_hit") == 1 and _sfx_count("critical_hit") == 0 and _sfx_count("sword_hit") == 0,
		"T11 AC-2: a parry-counter hit plays one heavy_hit, no critical_hit, no sword_hit (heavy %d, critical %d, sword %d)" % [_sfx_count("heavy_hit"), _sfx_count("critical_hit"), _sfx_count("sword_hit")])
	player.parry_counter_active = false
	await _settle_fx()

	# Kills through take_damage (the tank stays alive, so no last-kill here).
	for path in ["res://scripts/combat/enemies/slime.gd", "res://scripts/combat/enemies/corrupted_rat.gd"]:
		var victim := _real_enemy(stage, path, at + Vector2(300, -32))
		await _frames(3)
		_sfx_log.clear()
		victim.take_damage(99999.0, at)
		await _wait_for_sfx("enemy_death", 500)
		_check(_sfx_count("enemy_death") == 1, "T11 AC-2: a kill through take_damage on %s plays exactly one enemy_death (got %d)" % [path.get_file().get_basename(), _sfx_count("enemy_death")])
		await _settle_fx()

	# Direct die() (kill zone / Root Access): no kill effects ran.
	var direct := _real_enemy(stage, "res://scripts/combat/enemies/slime.gd", at + Vector2(400, -32))
	await _frames(3)
	_sfx_log.clear()
	direct.die()
	await _wait_for_sfx("enemy_death", 500)
	_check(_sfx_count("enemy_death") == 1, "T11 AC-2: a direct die() with no kill effects plays exactly one enemy_death (got %d)" % _sfx_count("enemy_death"))
	sfx.sfx_requested.disconnect(_on_sfx_requested)
	await _settle_fx()
	_reset_player(player)


func _poll_time_scale(target: float, max_frames: int) -> bool:
	for i in max_frames:
		if is_equal_approx(Engine.time_scale, target):
			return true
		await physics_frame
	return is_equal_approx(Engine.time_scale, target)


func _test_t11_last_kill() -> void:
	print("[T11 AC-5: last-kill slowdown runs after the kill's hitstop]")
	var player := await _fresh_stage()
	_reset_player(player)
	player.invulnerable = true
	player.invuln_timer = 100.0
	var fx := get_root().get_node("CombatFX")
	var cs := get_root().get_node("ContextStack")
	await _settle_fx()

	# (a) deferred while the kill's hitstop is active.
	var n0: int = fx.last_kill_started_count
	fx.apply_kill_effects(Vector2.ZERO, 10.0)
	fx.apply_last_kill_slowdown()
	_check(fx.is_hitstop_active and fx._pending_last_kill and not cs.has_time_request(&"last_kill") and fx.last_kill_started_count == n0,
		"T11 AC-5a: during the kill's hitstop the last-kill is pending, with no last_kill request (hitstop %s, pending %s)" % [fx.is_hitstop_active, fx._pending_last_kill])
	# (b1) released by _end_hitstop.
	fx._end_hitstop()
	var req_b1: bool = cs.has_time_request(&"last_kill")
	var count_b1: int = fx.last_kill_started_count - n0
	var handover_b1: float = Engine.time_scale
	var peak_b1: float = handover_b1
	var t_b1 := Time.get_ticks_msec()
	while Time.get_ticks_msec() - t_b1 < 200:   # real time, inside the 0.4 s hold
		await process_frame
		peak_b1 = maxf(peak_b1, Engine.time_scale)
	_check(peak_b1 <= 0.13, "T11 AC-5b: no burst of speed: Engine.time_scale stays at or below 0.13 for 200 ms real after the hitstop ends (at handover %.3f, peak %.3f)" % [handover_b1, peak_b1])
	var reached_b1 := is_equal_approx(handover_b1, 0.12) or await _poll_time_scale(0.12, 30)
	_check(req_b1 and count_b1 == 1 and reached_b1, "T11 AC-5b: _end_hitstop starts the pending last-kill (request %s, count +%d, time_scale reached 0.12 within 30 frames %s)" % [req_b1, count_b1, reached_b1])
	# (c) the request is released within 2.0 s real.
	var t0 := Time.get_ticks_msec()
	while cs.has_time_request(&"last_kill") and Time.get_ticks_msec() - t0 < 2000:
		await process_frame
	var held_ms := Time.get_ticks_msec() - t0
	_check(not cs.has_time_request(&"last_kill"), "T11 AC-5c: the last_kill request is released within 2.0 s real (held about %d ms more after 0.12 was seen)" % held_ms)
	await _settle_fx()

	# (b2) released by _force_end_hitstop.
	n0 = fx.last_kill_started_count
	fx.apply_kill_effects(Vector2.ZERO, 10.0)
	fx.apply_last_kill_slowdown()
	fx._force_end_hitstop()
	_check(cs.has_time_request(&"last_kill") and fx.last_kill_started_count == n0 + 1 and is_equal_approx(Engine.time_scale, 0.12),
		"T11 AC-5b: _force_end_hitstop starts the pending last-kill at once (count +%d, time_scale %.3f)" % [fx.last_kill_started_count - n0, Engine.time_scale])
	await _settle_fx()

	# A slowdown whose request is cleared (scene change, death, retry) must not come back
	# when its 0.4 s real-time timer fires.
	n0 = fx.last_kill_started_count
	fx.apply_last_kill_slowdown()
	var started_i: bool = fx.last_kill_started_count == n0 + 1 and cs.has_time_request(&"last_kill")
	cs.clear_time_scale()
	var stale_i := false
	var t2 := Time.get_ticks_msec()
	while Time.get_ticks_msec() - t2 < 800:
		if cs.has_time_request(&"last_kill") or not is_equal_approx(Engine.time_scale, 1.0):
			stale_i = true
		await process_frame
	_check(started_i and not stale_i, "T11 AC-5d: after clear_time_scale() the old slowdown's timer does not bring last_kill back (started %s, stale request or slow time seen %s)" % [started_i, stale_i])
	await _settle_fx()

	# (d1) paused at release: dropped.
	n0 = fx.last_kill_started_count
	fx.apply_kill_effects(Vector2.ZERO, 10.0)
	fx.apply_last_kill_slowdown()
	paused = true
	fx._end_hitstop()
	var d1_ok: bool = fx.last_kill_started_count == n0 and not cs.has_time_request(&"last_kill") and not fx._pending_last_kill
	paused = false
	_check(d1_ok, "T11 AC-5d: a pending last-kill is dropped if the tree is paused when the hitstop ends")
	await _settle_fx()

	# (d2) clear_time_scale() before release: dropped.
	n0 = fx.last_kill_started_count
	fx.apply_kill_effects(Vector2.ZERO, 10.0)
	fx.apply_last_kill_slowdown()
	cs.clear_time_scale()
	fx._end_hitstop()
	_check(fx.last_kill_started_count == n0 and not cs.has_time_request(&"last_kill") and not fx._pending_last_kill,
		"T11 AC-5d: a pending last-kill is dropped if clear_time_scale() ran before the hitstop ended")
	await _settle_fx()

	# (d3) current_scene changed before release: dropped.
	n0 = fx.last_kill_started_count
	var stage := current_scene
	fx.apply_kill_effects(Vector2.ZERO, 10.0)
	fx.apply_last_kill_slowdown()
	var other := Node.new()
	other.name = "T11OtherScene"
	get_root().add_child(other)
	current_scene = other
	fx._end_hitstop()
	var d3_ok: bool = fx.last_kill_started_count == n0 and not cs.has_time_request(&"last_kill") and not fx._pending_last_kill
	current_scene = stage
	other.queue_free()
	_check(d3_ok, "T11 AC-5d: a pending last-kill is dropped if current_scene changed before the hitstop ended")
	await _settle_fx()

	# (e2) two last-kill requests in the same frame during a hitstop: one slowdown.
	n0 = fx.last_kill_started_count
	fx.apply_kill_effects(Vector2.ZERO, 10.0)
	fx.apply_last_kill_slowdown()
	fx.apply_last_kill_slowdown()
	fx._end_hitstop()
	fx.apply_last_kill_slowdown()   # a third, while the first slowdown runs
	_check(fx.last_kill_started_count == n0 + 1, "T11 AC-5e: two requests in one frame during a hitstop, and a third while it runs, give one slowdown (count +%d)" % (fx.last_kill_started_count - n0))
	await _settle_fx()

	# (f) paused (Root Access): nothing pending, and no hitstop request.
	n0 = fx.last_kill_started_count
	paused = true
	fx.apply_last_kill_slowdown()
	var f1_ok: bool = not fx._pending_last_kill and fx.last_kill_started_count == n0 and not cs.has_time_request(&"last_kill")
	fx.apply_hitstop(0.1)
	var f2_ok: bool = not cs.has_time_request(&"hitstop") and not fx.is_hitstop_active
	paused = false
	_check(f1_ok, "T11 AC-5f: apply_last_kill_slowdown while paused leaves nothing pending and starts nothing")
	_check(f2_ok, "T11 AC-5f: apply_hitstop while paused makes no hitstop request")
	await _settle_fx()

	# (e) two real slimes dying on the same frame: one slowdown.
	var at := player.global_position
	var s1 := _real_enemy(stage, "res://scripts/combat/enemies/slime.gd", at + Vector2(200, -32))
	var s2 := _real_enemy(stage, "res://scripts/combat/enemies/slime.gd", at + Vector2(300, -32))
	await _frames(3)
	n0 = fx.last_kill_started_count
	s1.take_damage(99999.0, at)
	s2.take_damage(99999.0, at)
	await _settle_fx()
	_check(fx.last_kill_started_count == n0 + 1, "T11 AC-5e: two real slimes killed back to back give one last-kill slowdown, from the last one (count +%d)" % (fx.last_kill_started_count - n0))
	await _frames(45)   # their death tweens free them

	# (g) a boss killed as the last enemy: no deferred last-kill.
	var boss := _real_enemy(stage, "res://scripts/combat/enemies/slime.gd", at + Vector2(200, -32))
	boss.add_to_group("boss")
	await _frames(3)
	n0 = fx.last_kill_started_count
	boss.take_damage(99999.0, at)
	var boss_pending: bool = fx._pending_last_kill
	await _settle_fx()
	_check(not boss_pending and fx.last_kill_started_count == n0, "T11 AC-5g: a boss killed as the last enemy starts no last-kill (pending %s, count +%d)" % [boss_pending, fx.last_kill_started_count - n0])
	n0 = fx.last_kill_started_count
	fx.apply_last_kill_slowdown(true)
	_check(not fx._pending_last_kill and fx.last_kill_started_count == n0 and not cs.has_time_request(&"last_kill"), "T11 AC-5g: apply_last_kill_slowdown(true) starts nothing and leaves nothing pending")
	await _settle_fx()
	await _frames(45)   # the boss slime's death tween frees it
	var plain := _real_enemy(stage, "res://scripts/combat/enemies/slime.gd", at + Vector2(200, -32))
	await _frames(3)
	n0 = fx.last_kill_started_count
	plain.take_damage(99999.0, at)
	await _settle_fx()
	_check(fx.last_kill_started_count == n0 + 1, "T11 AC-5g control: the same setup without the boss group starts one last-kill (count +%d)" % (fx.last_kill_started_count - n0))
	await _frames(45)

	# End-to-end: the combat arena's slime.
	get_root().get_node("GameManager").reset_game()
	change_scene_to_file("res://scenes/combat/combat_arena.tscn")
	await _frames(20)
	get_root().get_node("DialogueManager").force_reset()
	await _settle_fx()
	var slime: Node = current_scene.get_node_or_null("Enemies/TutorialSlime") if current_scene else null
	if slime == null:
		_check(false, "T11 AC-5 end-to-end: combat_arena.tscn has Enemies/TutorialSlime")
		return
	var alive := 0
	for e in get_nodes_in_group("enemies"):
		if is_instance_valid(e) and e != slime and float(e.get("current_health") if e.get("current_health") != null else 0.0) > 0.0:
			alive += 1
	var n_e2e: int = fx.last_kill_started_count
	slime.take_damage(99999.0)
	var seen := false
	var t1 := Time.get_ticks_msec()
	while Time.get_ticks_msec() - t1 < 1000:
		if is_equal_approx(Engine.time_scale, 0.12):
			seen = true
			break
		await process_frame
	_check(seen and fx.last_kill_started_count > n_e2e, "T11 AC-5 end-to-end: killing the combat-arena slime with take_damage(99999) starts a last-kill slowdown and reaches time_scale 0.12 within 1.0 s real (count +%d, other live enemies %d)" % [fx.last_kill_started_count - n_e2e, alive])
	await _settle_fx()


func _list_gd(dir_path: String, out: Array[String]) -> void:
	var d := DirAccess.open(dir_path)
	if d == null:
		return
	d.list_dir_begin()
	var entry := d.get_next()
	while entry != "":
		if entry != "." and entry != "..":
			var full := dir_path.path_join(entry)
			if d.current_is_dir():
				_list_gd(full, out)
			elif entry.ends_with(".gd"):
				out.append(full)
		entry = d.get_next()
	d.list_dir_end()


## Drops a '#' comment, ignoring '#' inside "..." or '...' strings.
func _strip_comment(line: String) -> String:
	var quote := ""
	var i := 0
	while i < line.length():
		var ch := line[i]
		if quote != "":
			if ch == "\\":
				i += 1
			elif ch == quote:
				quote = ""
		elif ch == "\"" or ch == "'":
			quote = ch
		elif ch == "#":
			return line.substr(0, i)
		i += 1
	return line


func _test_t11_single_time_writer() -> void:
	print("[T11 AC-6: ContextStack is the only Engine.time_scale writer]")
	var files: Array[String] = []
	_list_gd("res://scripts", files)
	var rx := RegEx.new()
	rx.compile("Engine\\.time_scale\\s*[+\\-*/]?=(?:[^=]|$)")
	var self_test_ok: bool = rx.search(_strip_comment("\tEngine.time_scale = 0.5")) != null \
		and rx.search(_strip_comment("\tEngine.time_scale -= 0.1")) != null \
		and rx.search(_strip_comment("\tEngine.time_scale =")) != null \
		and rx.search(_strip_comment("\t# Engine.time_scale = 0")) == null \
		and rx.search(_strip_comment("\tif Engine.time_scale == 1.0:")) == null
	_check(self_test_ok, "T11 AC-6: the scan pattern catches known-bad lines and skips comments and comparisons")
	var offenders: Array[String] = []
	for path in files:
		if path.ends_with("scripts/core/context_stack.gd"):
			continue
		var lines := FileAccess.get_file_as_string(path).split("\n")
		for n in lines.size():
			if rx.search(_strip_comment(lines[n])) != null:
				offenders.append("%s:%d" % [path, n + 1])
	_check(files.size() > 50 and offenders.is_empty(), "T11 AC-6: no script outside core/context_stack.gd assigns Engine.time_scale (%d files scanned; offenders %s)" % [files.size(), offenders])
