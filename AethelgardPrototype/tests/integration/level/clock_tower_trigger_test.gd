extends SceneTree
## Tests for story Y1-P0-T12 (production/epics/y1-p0-stabilize/story-t12-ui-region-leftovers.md, AC-6): the Clock
## Tower's pre-boss trigger (`BossTrigger`, scripts/chapter2/ch2_clock_tower.gd) sits where the player really walks.
## Today's circle (r=50 at (400, -90)) lies BELOW floor 5 (its top surface is y=-150; the circle spans y -140..-40),
## so nobody standing on floor 5 can touch it and the `pre_boss` dialogue was skipped silently. Found while making this
## suite: the Area2D also kept the default collision_mask 1 while the player body is on layer 2 (player_combat.gd
## _ready), so body_entered never fired for the real player whatever the shape. The fix is a RectangleShape2D band
## across floor 5 plus collision_mask = 2 on BossTrigger. AC-6a (shape query, mask-independent) catches the shape;
## AC-6b/AC-6c (the real player) catch both. Expected values below are literals from the tower's geometry (floors at
## y 900/650/400/150/-150, walls x 0..20 and 780..800, player body 20x32 with its feet at the node origin, floor 4->5
## steps at y -40 (x 450..800) and y 40 (x 550..800), lift x 450..550 whose top surface is y -127.5 at the top of its
## run), never computed by the code under test.
##
## Checks (the check count is printed in the result line; the runner reads it):
##   AC-6a  shape samples, physics query (an Area-only PhysicsDirectSpaceState2D.intersect_shape, the way
##          reachability_test.gd tests "touchable"), with a 20x32 rectangle centred 16 px above its feet:
##          - 15 floor-5 standing samples (x = 30, 80, ..., 730, feet y -150) plus the right-hand limit x = 770:
##            vertical overlap >= 8 px
##          - 16 floor-4 standing samples (same x, feet y 150) and 7 floor 4->5 step samples: no overlap
##          - lift top (x = 500, feet y -127.5): overlap measured, expected 8..11 px (about 9.5; it is the floor 5
##              arrival point, so touching there is allowed and expected)
##          Vertical overlap is measured by lowering the body in 0.5 px steps until the query stops reporting the
##          trigger; the pixels lowered are the overlap (exact while the body's top edge starts inside or above the
##          band's lower edge, true for every sample here). A sample that does not touch at all measures 0.
##          Also: the node is still an Area2D named BossTrigger with body_entered connected to _on_boss_trigger.
##   AC-6b  the real player (the tower's own Player node, real physics frames) jumps from the floor 4->5 step's left
##          end (x = 460, feet y -40) and from the lift pinned at the top of its run (x = 500): it lands on floor 5,
##          `_pre_boss_done` is true and the `pre_boss` dialogue is running (DialogueManager.is_active, the game state
##          is COMBAT, and driving it to the end puts the pre_boss section's own lines in dialogue_history).
##   AC-6c  dash (reworked at code review, R3): a dash that starts on floor 5 is already inside the band, so asserting
##          `_pre_boss_done` after it could not fail. Instead: the band reaches both inner walls (x 20 and 780), so no
##          standing x on floor 5 is outside it; and during a real _start_dash() from x = 300 the body touches the band
##          at every one of 30 physics frames (and travels >= 100 px). (The story's start x = 20 is inside the left
##          wall, x 0..20.)
##   The lift case asserts that the trigger has ALREADY fired while the player stands on the lift top (the lift top
##   is inside the band's lower edge by about 9.5 px; it is the floor 5 arrival point). The step case is the one that
##   proves arrival: the step (feet y -40) is well below the band, so `_pre_boss_done` is false until the jump lands.
##
## ISOLATION COSTS (named, accepted):
##   - Each case instantiates a fresh tower and calls GameManager.reset_game(), so `_pre_boss_done` starts false.
##   - The tower's own enemies and boss (group "enemies") are freed right after instancing, so nothing fights the
##     player on its way up; the trigger, walls, floors and lift are untouched. The lift's looping tween is killed and
##     the platform pinned at the top of its run, so the lift case is deterministic (a moving lift would not be).
##   - The tower's _ready awaits 0.5 s and then plays the entry dialogue. Each case first waits that dialogue out
##     (skip_all() while active, a 10 s real-time cap) so it cannot be mistaken for the pre_boss dialogue and does not
##     freeze the player. The suite does not depend on it finishing earlier than the cap.
##   - The driver reads and calls the DialogueManager's public members only (is_active, skip_all, dialogue_history).
##   - The jump is a velocity assignment (JUMP_VELOCITY, player_combat.gd:21) on the real player, not an input event;
##     the player's own gravity, floor and one-way-platform handling do the rest.
##   - From the second case on, the log shows one "ERROR: Lambda capture at index 0 was freed" line while the previous
##     tower is freed (observed, cause not investigated; it is not a SCRIPT ERROR, so the runner does not fail on it, and
##     this suite does not rely on it).
##   - Each Godot boot logs 6 "Can't use get_node() with absolute paths" ERROR lines before any test code (pre-existing).
## Run: tests/run_phase0_tests.ps1 -Script res://tests/integration/level/clock_tower_trigger_test.gd

const SCENE := "res://scenes/chapter2/clock_tower.tscn"

# Literals from the tower geometry and the player (see the header).
const BODY := Vector2(20, 32)
const FLOOR5_FEET_Y := -150.0
const FLOOR4_FEET_Y := 150.0
const STEP_UPPER_FEET_Y := -40.0
const STEP_LOWER_FEET_Y := 40.0
const LIFT_TOP_FEET_Y := -127.5
const LIFT_TOP_POS := Vector2(500, -120)     # the lift platform node's position at the top of its run
const MIN_OVERLAP := 8.0
const LIFT_OVERLAP_MIN := 8.0
const LIFT_OVERLAP_MAX := 11.0
const OVERLAP_STEP := 0.5
const JUMP_VELOCITY := -560.0                # player_combat.gd:21
const STEP_JUMP_X := 460.0                   # left end of the step: the player's body spans x 450..470
const LIFT_JUMP_X := 500.0
const DASH_X := 300.0                        # middle of floor 5: a 30-frame dash right ends past the band's centre
const DASH_FRAMES := 30
const MIN_DASH_TRAVEL := 100.0               # px a real dash must cover for the per-frame check to mean anything
const INNER_LEFT_WALL_X := 20.0              # left wall x 0..20 (ch2_clock_tower.gd _build_tower_environment)
const INNER_RIGHT_WALL_X := 780.0            # right wall x 780..800
const TOLERANCE_PX := 0.5
const ARRIVAL_FRAMES := 240                  # 4 s of physics: a jump from the step lands in about 1.2 s
const LAND_TOLERANCE := 2.0
const SETTLE_CAP_MS := 10000
const PRE_BOSS_LINES := ["SCHEDULE DEVIATION.", "That's us. We're the deviation."]

var _passes := 0
var _failures: Array[String] = []
var _tower: Node2D
var _trigger: Area2D
var _gm: Node
var _dm: Node


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	await process_frame
	await process_frame
	if not OS.get_user_data_dir().contains("aeth_phase0_test"):
		push_error("Refusing to run: user data dir is not isolated. Use tests/run_phase0_tests.ps1.")
		quit(2)
		return
	_gm = get_root().get_node_or_null("GameManager")
	_dm = get_root().get_node_or_null("DialogueManager")
	_check(OS.get_user_data_dir().contains("aeth_phase0_test"), "isolation: user:// is the aeth_phase0_test directory (%s)" % OS.get_user_data_dir())
	_check(_gm != null and _dm != null, "isolation: GameManager and DialogueManager autoloads present")
	if _gm == null or _dm == null:
		_finish()
		return
	await _test_shape_samples()
	await _test_arrival("step", Vector2(STEP_JUMP_X, STEP_UPPER_FEET_Y), false)
	await _test_arrival("lift", Vector2(LIFT_JUMP_X, LIFT_TOP_FEET_Y), true)
	await _test_dash()
	await _drop_tower()
	_finish()


func _finish() -> void:
	print("")
	print("CLOCK TOWER TRIGGER RESULT: %d passed, %d failed" % [_passes, _failures.size()])
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


# ── Tower set-up ─────────────────────────────────────────────────────────────

func _drop_tower() -> void:
	if _tower != null and is_instance_valid(_tower):
		_tower.queue_free()
		await process_frame
	_tower = null
	_trigger = null
	_dm.force_reset()


## A fresh tower with `_pre_boss_done` false, its enemies gone, its entry dialogue played out.
func _fresh_tower() -> void:
	await _drop_tower()
	_gm.reset_game()
	_tower = (load(SCENE) as PackedScene).instantiate()
	get_root().add_child(_tower)
	for e in get_nodes_in_group("enemies"):
		if _tower.is_ancestor_of(e):
			e.queue_free()
	await _frames(3)
	_trigger = _tower.get_node_or_null("BossTrigger") as Area2D
	await _settle_entry()


## Skips the entry dialogue (it starts 0.5 s after _ready) until the box is idle again.
func _settle_entry() -> void:
	var t0 := Time.get_ticks_msec()
	var seen := false
	while Time.get_ticks_msec() - t0 < SETTLE_CAP_MS:
		await process_frame
		if _dm.is_active:
			seen = true
			if not _dm.is_skip_requested():
				_dm.skip_all()
		elif seen:
			break
	await _frames(2)


func _player() -> CharacterBody2D:
	return _tower.get_node("Player") as CharacterBody2D


## Moves the real player so its feet are at `feet`, at rest.
func _place_player(feet: Vector2) -> void:
	var p := _player()
	p.global_position = feet
	p.velocity = Vector2.ZERO


# ── AC-6a: shape samples ─────────────────────────────────────────────────────

## Does a body of BODY size, feet at (x, feet_y), touch the trigger (Area-only query)?
func _touches(x: float, feet_y: float) -> bool:
	var shape := RectangleShape2D.new()
	shape.size = BODY
	var q := PhysicsShapeQueryParameters2D.new()
	q.shape = shape
	q.transform = Transform2D(0.0, Vector2(x, feet_y - BODY.y * 0.5))
	q.collide_with_areas = true
	q.collide_with_bodies = false
	for r in _tower.get_world_2d().direct_space_state.intersect_shape(q, 32):
		if r.collider == _trigger:
			return true
	return false


## Vertical overlap in px: the body is lowered in OVERLAP_STEP steps until it stops touching.
func _overlap_px(x: float, feet_y: float) -> float:
	var k := 0.0
	while k <= BODY.y * 2.0 and _touches(x, feet_y + k):
		k += OVERLAP_STEP
	return k


func _test_shape_samples() -> void:
	await _fresh_tower()
	_check(_trigger != null and _trigger is Area2D, "AC-6a: BossTrigger exists and is an Area2D")
	if _trigger == null:
		return
	_check(_trigger.body_entered.is_connected(_tower._on_boss_trigger), "AC-6a: BossTrigger.body_entered is connected to _on_boss_trigger")
	_check(not _tower._pre_boss_done, "AC-6a: _pre_boss_done starts false in a fresh tower")
	var xs: Array[float] = []
	for i in 15:
		xs.append(30.0 + 50.0 * i)
	_check(xs.size() == 15 and xs[0] == 30.0 and xs[14] == 730.0, "AC-6a: 15 samples from x=30 to x=730 (got %d, last %s)" % [xs.size(), str(xs[xs.size() - 1])])
	xs.append(770.0)   # plus the right-hand standing limit (body x 760..780 beside the wall at x >= 780)
	var worst := 1000.0
	for x in xs:
		var ov := _overlap_px(x, FLOOR5_FEET_Y)
		worst = minf(worst, ov)
		_check(ov >= MIN_OVERLAP, "AC-6a: standing on floor 5 at x=%d overlaps the trigger by >= %d px (measured %s px)" % [int(x), int(MIN_OVERLAP), str(ov)])
	print("  measured: smallest floor-5 overlap %s px" % str(worst))
	for x in xs:
		var ov4 := _overlap_px(x, FLOOR4_FEET_Y)
		_check(ov4 == 0.0, "AC-6a: standing on floor 4 at x=%d does not touch the trigger (measured %s px)" % [int(x), str(ov4)])
	var steps: Array = [[460.0, STEP_UPPER_FEET_Y], [500.0, STEP_UPPER_FEET_Y], [600.0, STEP_UPPER_FEET_Y], [770.0, STEP_UPPER_FEET_Y],
		[560.0, STEP_LOWER_FEET_Y], [600.0, STEP_LOWER_FEET_Y], [770.0, STEP_LOWER_FEET_Y]]
	for s in steps:
		var ovs := _overlap_px(s[0], s[1])
		_check(ovs == 0.0, "AC-6a: standing on the step at x=%d, feet y=%d does not touch the trigger (measured %s px)" % [int(s[0]), int(s[1]), str(ovs)])
	var lift_ov := _overlap_px(LIFT_JUMP_X, LIFT_TOP_FEET_Y)
	print("  measured: lift top (x=%d, feet y=%s) overlap %s px" % [int(LIFT_JUMP_X), str(LIFT_TOP_FEET_Y), str(lift_ov)])
	_check(lift_ov >= LIFT_OVERLAP_MIN and lift_ov <= LIFT_OVERLAP_MAX, "AC-6a: lift top overlaps the trigger by %d..%d px, the floor 5 arrival point (measured %s px)" % [int(LIFT_OVERLAP_MIN), int(LIFT_OVERLAP_MAX), str(lift_ov)])


# ── AC-6b: arriving on floor 5 with the real player ──────────────────────────

## Pins the lift (the platform at x=500) at the top of its run: kills the tower's looping tweens first.
func _pin_lift() -> bool:
	for tw in get_processed_tweens():
		tw.kill()
	for pf in _tower._moving_platforms:
		if absf(pf.position.x - LIFT_JUMP_X) < 1.0:
			pf.position = LIFT_TOP_POS
			return true
	return false


func _count_pre_boss_lines() -> int:
	var n := 0
	for h in _dm.dialogue_history:
		if PRE_BOSS_LINES.has(str(h.get("text", ""))):
			n += 1
	return n


## Lets the pre_boss dialogue type out by skipping it, until the box is idle (or the real-time cap).
func _drive_dialogue_to_end() -> void:
	var t0 := Time.get_ticks_msec()
	while Time.get_ticks_msec() - t0 < SETTLE_CAP_MS:
		await process_frame
		if _dm.is_active:
			if not _dm.is_skip_requested():
				_dm.skip_all()
		else:
			break


func _test_arrival(label: String, feet: Vector2, lift: bool) -> void:
	await _fresh_tower()
	if _trigger == null:
		_check(false, "AC-6b %s: BossTrigger exists" % label)
		return
	if lift:
		_check(_pin_lift(), "AC-6b %s: the lift platform was found and pinned at the top of its run" % label)
	var p := _player()
	_place_player(feet)
	await _frames(4)
	# The body must be standing where the case says (the step / the lift top) before it jumps.
	_check(p.is_on_floor() and absf(p.global_position.y - feet.y) <= 1.0, "AC-6b %s: the player stands at feet y=%s before the jump (at %s, on_floor=%s)" % [label, str(feet.y), str(p.global_position), str(p.is_on_floor())])
	var fired_before_jump: bool = _tower._pre_boss_done
	print("  observed: %s - trigger already fired while standing there: %s" % [label, str(fired_before_jump)])
	# The lift top lies inside the band (its arrival point); the step lies well below it (code review R3).
	_check(fired_before_jump == lift, "AC-6b %s: trigger fired while standing there == %s (got %s)" % [label, str(lift), str(fired_before_jump)])
	var lines_before := _count_pre_boss_lines()
	p.velocity.y = JUMP_VELOCITY
	var landed := false
	var frames_used := 0
	var airborne := false
	for i in ARRIVAL_FRAMES:
		await physics_frame
		frames_used += 1
		if not p.is_on_floor():
			airborne = true
		if airborne and p.is_on_floor():
			landed = true
			break
	await _frames(2)
	_check(landed and absf(p.global_position.y - FLOOR5_FEET_Y) <= LAND_TOLERANCE, "AC-6b %s: the jump lands on floor 5 (feet y=%s, ended at %s after %d frames)" % [label, str(FLOOR5_FEET_Y), str(p.global_position), frames_used])
	_check(_tower._pre_boss_done, "AC-6b %s: _pre_boss_done is true after arriving on floor 5" % label)
	if _tower._pre_boss_done:
		_check(_dm.is_active and _gm.current_state == _gm.GameState.COMBAT, "AC-6b %s: the pre_boss dialogue is running (DialogueManager.is_active=%s, game state COMBAT=%s)" % [label, str(_dm.is_active), str(_gm.current_state == _gm.GameState.COMBAT)])
		await _drive_dialogue_to_end()
		_check(_count_pre_boss_lines() - lines_before == PRE_BOSS_LINES.size(), "AC-6b %s: the pre_boss section's own lines were spoken (%d of %d new in dialogue_history)" % [label, _count_pre_boss_lines() - lines_before, PRE_BOSS_LINES.size()])
	else:
		_check(false, "AC-6b %s: the pre_boss dialogue is running (never triggered)" % label)
		_check(false, "AC-6b %s: the pre_boss section's own lines were spoken (never triggered)" % label)


# ── AC-6c: dash ──────────────────────────────────────────────────────────────

## Code review R3: a dash that STARTS on floor 5 is already inside the band, so "_pre_boss_done after a dash" could not
## fail. What a dash could do is carry the player out of the band before body_entered is seen; so this case checks
## (1) the band reaches both inner walls, so no standing x on floor 5 lies outside it, and (2) at every physics frame
## of a real dash across the middle of floor 5 the player's body still touches the band.
func _test_dash() -> void:
	await _fresh_tower()
	if _trigger == null:
		_check(false, "AC-6c dash: BossTrigger exists")
		return
	var col := _trigger.get_child(0) as CollisionShape2D
	var shape := col.shape as RectangleShape2D
	if shape == null:
		_check(false, "AC-6c dash: BossTrigger is a RectangleShape2D band")
		return
	var band := Rect2(col.global_position - shape.size * 0.5, shape.size)
	_check(band.position.x <= INNER_LEFT_WALL_X + TOLERANCE_PX and band.end.x >= INNER_RIGHT_WALL_X - TOLERANCE_PX,
		"AC-6c dash: the band reaches both inner walls (x %.1f..%.1f covers %.0f..%.0f), so no standing x on floor 5 is outside it" % [band.position.x, band.end.x, INNER_LEFT_WALL_X, INNER_RIGHT_WALL_X])
	var p := _player()
	p.facing_direction = 1.0
	_place_player(Vector2(DASH_X, FLOOR5_FEET_Y))
	await _frames(2)
	# Standing on floor 5 fires pre_boss at once; its dialogue holds the player, so let it finish before dashing.
	if _tower._pre_boss_done:
		await _drive_dialogue_to_end()
	p._start_dash()   # the real dash: sets is_dashing and velocity.x = DASH_SPEED (player_combat.gd:1151)
	_check(p.is_dashing and p.velocity.x > 0.0, "AC-6c dash: the player is dashing right (is_dashing=%s, vx=%s)" % [str(p.is_dashing), str(p.velocity.x)])
	var start_x := p.global_position.x
	var outside_frames := 0
	for i in DASH_FRAMES:
		await physics_frame
		if not _touches(p.global_position.x, p.global_position.y):
			outside_frames += 1
	print("  observed: dash from x=%.0f ended at %s" % [start_x, str(p.global_position)])
	_check(p.global_position.x - start_x >= MIN_DASH_TRAVEL, "AC-6c dash: the dash carried the player at least %.0f px (moved %.0f)" % [MIN_DASH_TRAVEL, p.global_position.x - start_x])
	_check(outside_frames == 0, "AC-6c dash: the body touches the band at every one of %d physics frames of the dash (%d outside)" % [DASH_FRAMES, outside_frames])
