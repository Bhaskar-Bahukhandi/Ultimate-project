extends SceneTree
## Y1-P0-T13c: the north-field boar is a real side-scroll fight. Stage A: cases C1, C2 and C4.
##   C1  AC-1  the boar alone: its declared values, the telegraph wherever the player stands, off-screen culling off,
##             the charge (no turn, 14 damage once, jumped for nothing, wall to wall into dizzy), dizzy (2.0 s, still,
##             hits take HP and do not move it), armour outside dizzy, the pogo, the parry, no contact damage, the
##             scaled numbers, and a charge with no walls ending in RECOVER after CHARGE_MAX_TIME
##   C2  AC-2  the STORY_FIGHTS row and the bible row
##   C4  AC-4  the fight in the arena: the win (shards, flag once, nothing else given, one scene change) and the
##             retry, also while the boar is mid-charge
## Stage B: cases C3 and C5, driven through the real village (its dialogue, a save and a load, the pause menu).
##   C3  AC-3  the village's hand-off (from the boar trigger and from the bridge trigger); calm and nest without it
##   C5  AC-5  back from the arena: the return beat after the fade-in, the triggers held off, paid once; the reload
##             after fight, calm and nest; pause -> main menu from the fight
## Pins (AC-6): every runtime number is checked under _apply_pins, applied before the boar spawns (its HP is scaled in
## _ready); the DDA score is re-applied before each charge. The pins are written to the fields directly, never
## through set_difficulty / set_accessibility (both save user://game_settings.cfg), snapshotted and restored.
## The scene changes go to a stub scene (tests/fixtures/story_fight_return_stub.tscn), as in guardian_fight_test.
## Test-side isolation costs, named: the boar is driven through take_damage, its own dizzy entry and direct state
## writes (current_state, attack_cooldown) between charges; _dizzy, _stun_active, _charge_elapsed, _is_on_screen,
## _screen_notifier and the arena's _story_cfg are read; PlayerCombat is driven through take_damage / _start_parry /
## die and, for the pogo, through its input actions.
## Run: tests/run_phase0_tests.ps1 -Script res://tests/integration/combat/boar_fight_test.gd

const ARENA := "res://scenes/combat/combat_arena.tscn"
const ARENA_SCRIPT := "res://scripts/combat/combat_arena.gd"
const STUB := "res://tests/fixtures/story_fight_return_stub.tscn"
const BOAR_SCRIPT := "res://scripts/combat/enemies/field_boar.gd"
const BIBLE := "res://story/STORY_BIBLE.md"
const TWEEN_ANIMATOR := "res://scripts/effects/tween_animator.gd"
const ROW_ID := "ch1_boar"
const FLAG := "ch1_boar_fight_won"
const SHARD_COLOR := Color(0.7, 0.15, 0.15)
const FLOOR_Y := 600.0                    # the arena floor: bodies' feet rest at this y
const BOAR_POS := Vector2(760, FLOOR_Y)   # the row's enemy_spawn x, on the floor (the spawn's y 400 is in the air)
const LEFT_POS := Vector2(100, FLOOR_Y)   # next to the left wall, for the wall-to-wall charge
const NEAR_WALL_POS := Vector2(1100, FLOOR_Y)   # a short run to the right wall
const AIR_Y := FLOOR_Y - 200.0            # the held player: a charge passes under it
const PIN_DDA_SCORE := 52.5               # remap(52.5, 20, 85, 0.75, 1.25) = 1.0
const NEAR_DIST := 50.0
const MID_DIST := 300.0
const FAR_DIST := 900.0
const OFFSCREEN_POS := Vector2(1200, FLOOR_Y)   # 1200 px from the player at x 0: off-screen, inside DETECTION_RANGE
const OFFSCREEN_DIST := 1200.0
const FAR_AWAY_X := -1240.0               # 2000 px left of the boar at x 760
const WALL_RIGHT_X := 1200.0              # a wall-to-wall charge must end at least this far right
const PATH_DIST := 200.0                  # the player stands this far in the charge's path
const REPEATS := 3
const STAGGER_TIME := 1.2                 # PlayerCombat._on_successful_parry: enemy.stagger(1.2)
const PARRY_LEAD := 0.1                   # the parry starts this long before the hit (its window is 0.18 s)
const SETTLE_FRAMES := 3                  # physics frames _arm holds the pair in place after a teleport
const PLAYER_HIT := 15.0                  # one player hit (player_combat.gd:171)
const POGO_HIT := 27.0                    # 15 x POGO_DAMAGE_MULT 1.8 x combo multiplier 1.0
const CROSS_AT := 0.15                    # game seconds into the charge when the player is moved behind the boar
const RETRY_CHARGE_DIST := 250.0          # mid-charge retry: the old charge reaches the spawn after the restore
const DEATH_LEAD := 0.2                   # mid-charge retry: the player dies this long (game time) before the telegraph
const SCALED_DDA_SCORE := 85.0            # remap(85, 20, 85, 0.75, 1.25) = 1.25
const SCALED_ZONE_LEVEL := 3              # two levels above the pinned player level 1, damage multiplier 1.5
const CONTACT_WATCH := 1.0                # game seconds the player stands inside the boar with no charge
const PAUSE_HOLD := 1.0                   # wall seconds the game is held paused (R2)
const PAUSE_AFTER := 0.3                  # game seconds into the charge, or into dizzy, when the pause comes
const JUMP_LEAD_PX := 60.0                # the real jump: pressed when the hit box is this far from the player
const RESTORE_WATCH := 1.0                # game seconds the player is watched after a retry's restore
const LIMIT := 6.0                        # game seconds one charge may take before the watcher gives up
const BOAR_CONSTANTS := {"BOAR_MAX_HEALTH": 45.0, "CHARGE_TELEGRAPH": 0.6, "CHARGE_DAMAGE": 14.0,
	"CHARGE_SPEED": 420.0, "CHARGE_MAX_TIME": 3.5, "DIZZY_TIME": 2.0, "RECOVER_TIME": 0.8, "ATTACK_COOLDOWN": 1.2,
	"MOVE_SPEED": 0.0, "CHARGE_SWEEP_ACTIVE": 0.02, "BOAR_CONTACT_DAMAGE": 0.0, "BOAR_DODGE_CHANCE": 0.0}

var _passes := 0
var _failures: Array[String] = []
var _transitions := 0
var _outcomes: Array = []
var _pin_snapshot: Dictionary = {}
var _dda_pin := PIN_DDA_SCORE             # the DDA score _reapply_dda writes (SCALED_DDA_SCORE for the scaled run)


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	await process_frame
	if not OS.get_user_data_dir().contains("aeth_phase0_test"):
		push_error("Refusing to run: user data dir is not isolated. Use tests/run_phase0_tests.ps1.")
		quit(2)
		return
	get_root().get_node("SceneTransitions").transition_started.connect(func(): _transitions += 1)
	_snapshot_pins()
	await _test_c1_boar()
	await _test_c1_no_walls()
	await _test_c1_retry_control()
	await _test_c2_row()
	await _test_c3_handoff()
	await _test_c4_win()
	await _test_c4_retry()
	await _test_c4_retry_mid_charge()
	await _test_c5_resume()
	_restore_pins()
	_finish()


func _finish() -> void:
	print("")
	print("BOAR FIGHT RESULT: %d passed, %d failed" % [_passes, _failures.size()])
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


# ── helpers ───────────────────────────────────────────────────────────────

func _gm() -> Node:
	return get_root().get_node("GameManager")


func _juice() -> Node:
	return get_root().get_node("GameJuice")


func _wait(seconds: float) -> void:
	var end := Time.get_ticks_msec() + int(seconds * 1000.0)
	while Time.get_ticks_msec() < end:
		await process_frame


func _wait_until(cond: Callable, timeout_sec: float) -> bool:
	var end := Time.get_ticks_msec() + int(timeout_sec * 1000.0)
	while Time.get_ticks_msec() < end:
		if cond.call():
			return true
		await process_frame
	return cond.call()


func _wait_scene_settled() -> void:
	var st := get_root().get_node("SceneTransitions")
	await _wait_until(func(): return not st.is_transitioning, 6.0)


func _time_requests_empty() -> bool:
	var cs := get_root().get_node("ContextStack")
	return cs._time_requests.is_empty() and is_equal_approx(Engine.time_scale, 1.0) and not cs.any_open()


## The boar script, or null before it exists (its checks then fail by name instead of aborting the suite).
func _boar_script() -> Script:
	return load(BOAR_SCRIPT) if ResourceLoader.exists(BOAR_SCRIPT) else null


func _consts() -> Dictionary:
	var script := _boar_script()
	return script.get_script_constant_map() if script else {}


## How far the charge's hit box reaches from the boar's centre (|offset.x| + width / 2); INF without the constants.
func _charge_reach(c: Dictionary) -> float:
	if not c.has("CHARGE_HITBOX_OFFSET") or not c.has("CHARGE_HITBOX_SIZE"):
		return INF
	return absf(c["CHARGE_HITBOX_OFFSET"].x) + c["CHARGE_HITBOX_SIZE"].x * 0.5


## A named constant of EnemyBase (State, AttackType), read at run time: naming EnemyBase here would compile
## enemy_base.gd before the autoloads exist and this whole script would fail to load.
func _base_enum(enum_name: String, value_name: String) -> int:
	var base: Script = load("res://scripts/combat/enemy_base.gd")
	return int(base.get_script_constant_map()[enum_name][value_name])


func _state(value_name: String) -> int:
	return _base_enum("State", value_name)


func _boar(arena: Node) -> Node:
	return arena.get_node_or_null("Enemies/StoryFightBoar")


func _freeze(enemy: Node) -> void:
	if is_instance_valid(enemy):
		enemy.set_physics_process(false)
		enemy.set_process(false)


func _hurt_player(arena: Node, amount: float = 9999.0) -> void:
	arena.player.take_damage(amount, Vector2.ZERO, "Test", "melee")


func _shards(arena: Node) -> Array:
	return arena.get_children().filter(func(n): return n.name.begins_with("StoryFightShard"))


## The hit flash's tween EnemyBase._play_hit_flash records on the sprite (its "flash_tween" meta), or null.
func _flash_tween(sprite: CanvasItem) -> Variant:
	if sprite == null or not sprite.has_meta("flash_tween"):
		return null
	return sprite.get_meta("flash_tween")


## Whether TweenAnimator (EnemyBase._tween_hurt's hurt tween) is animating the sprite. Its static method is called
## through the loaded script: naming the class here would compile it before the autoloads exist.
func _hurt_animating(sprite: CanvasItem) -> bool:
	if sprite == null:
		return false
	return bool((load(TWEEN_ANIMATOR) as Script).call("is_animating", sprite))


## The dizzy cue (D10): "shown", "hidden", or "missing" when the boar has no DizzyCue label.
func _cue(b: Node) -> String:
	var cue: CanvasItem = b.get_node_or_null("DizzyCue") if is_instance_valid(b) else null
	if cue == null:
		return "missing"
	return "shown" if cue.visible else "hidden"


func _tick() -> float:
	return 1.0 / float(Engine.physics_ticks_per_second)


# ── the pins (AC-6) ───────────────────────────────────────────────────────

## Snapshots every field _apply_pins writes. Called once, before the first pin.
func _snapshot_pins() -> void:
	var gm := _gm()
	var stats: Dictionary = gm.player_stats
	var juice := _juice()
	_pin_snapshot = {
		"dda": gm._dda_performance_score,
		"difficulty": gm.selected_difficulty,
		"level": stats.get("level", 1),
		"defense": stats.get("defense", 0),
		"ng_plus": gm.ng_plus_cycle,
		"buffs": get_root().get_node("ChoiceConsequences").active_buffs.duplicate(true),
		"invincibility_present": gm.accessibility_settings.has("invincibility_mode"),
		"invincibility": gm.accessibility_settings.get("invincibility_mode", false),
		"combo_count": juice._combo_count,
		"combo_timer": juice._combo_timer,
		"combo_milestone": juice._last_combo_milestone,
	}


## The pins behind AC-1's numbers: player level 1, DDA score 52.5 (multiplier 1.0), difficulty NORMAL, player
## defense 0, NG+ cycle 0, enemy-weakness buffs cleared, invincibility off, the GameJuice combo reset (the pogo's
## damage carries its multiplier). Fields are written directly: set_difficulty and set_accessibility save
## user://game_settings.cfg. Applied before the boar spawns.
func _apply_pins() -> void:
	var gm := _gm()
	gm.player_stats["level"] = 1
	gm.player_stats["defense"] = 0
	gm.selected_difficulty = gm.Difficulty.NORMAL
	gm.ng_plus_cycle = 0
	get_root().get_node("ChoiceConsequences").active_buffs.clear()
	gm.accessibility_settings["invincibility_mode"] = false
	_reset_combo()
	_reapply_dda()


## The DDA score drifts with every hit the player takes, so it is written again before each charge.
func _reapply_dda() -> void:
	_gm()._dda_performance_score = _dda_pin


func _reset_combo() -> void:
	var juice := _juice()
	juice._combo_count = 0
	juice._combo_timer = 0.0
	juice._last_combo_milestone = 0


func _restore_pins() -> void:
	var gm := _gm()
	gm.player_stats["level"] = _pin_snapshot["level"]
	gm.player_stats["defense"] = _pin_snapshot["defense"]
	gm.selected_difficulty = _pin_snapshot["difficulty"]
	gm.ng_plus_cycle = _pin_snapshot["ng_plus"]
	var buffs: Array = get_root().get_node("ChoiceConsequences").active_buffs
	buffs.clear()
	buffs.append_array(_pin_snapshot["buffs"])
	if _pin_snapshot["invincibility_present"]:
		gm.accessibility_settings["invincibility_mode"] = _pin_snapshot["invincibility"]
	else:
		gm.accessibility_settings.erase("invincibility_mode")
	gm._dda_performance_score = _pin_snapshot["dda"]
	var juice := _juice()
	juice._combo_count = _pin_snapshot["combo_count"]
	juice._combo_timer = _pin_snapshot["combo_timer"]
	juice._last_combo_milestone = _pin_snapshot["combo_milestone"]


# ── the arena ─────────────────────────────────────────────────────────────

## Resets the game, applies the pins, sets the story metas and loads the arena as a plain child of the root.
func _start_arena() -> Node:
	var gm := _gm()
	gm.reset_game()
	get_root().get_node("DialogueManager").force_reset()
	for k in ["story_fight_id", "story_fight_return_scene", "pending_encounter", "boss_fight_id"]:
		if gm.has_meta(k):
			gm.remove_meta(k)
	_apply_pins()
	gm.set_meta("story_fight_id", ROW_ID)
	gm.set_meta("story_fight_return_scene", STUB)
	var arena: Node = (load(ARENA) as PackedScene).instantiate()
	get_root().add_child(arena)
	for i in 4:
		await process_frame
	_outcomes.clear()
	if arena.has_signal("story_fight_resolved"):
		arena.story_fight_resolved.connect(func(o): _outcomes.append(o))
	return arena


func _end_arena(arena: Node) -> void:
	if is_instance_valid(arena):
		arena.queue_free()
	for k in ["story_fight_id", "story_fight_return_scene", "pending_encounter", "boss_fight_id"]:
		if _gm().has_meta(k):
			_gm().remove_meta(k)
	get_root().get_node("ContextStack").clear_time_scale()


## Full HP in the player and in GameManager, invulnerability and any parry run out.
func _heal_player(arena: Node) -> void:
	var p = arena.player
	p.current_health = p.max_health
	_gm().player_stats["hp"] = int(p.max_health)
	p.invulnerable = false
	p.invuln_timer = 0.0
	p.parry_active = false
	p.velocity = Vector2.ZERO


## Puts the boar at `pos` in CHASE with no cooldown and the player `dist` px to its left (to its right when dist is
## negative), at full HP. It first waits out any hit-stop and holds both in place for SETTLE_FRAMES with the cooldown
## up, so the boar's Area2D flags catch up with the teleport before a telegraph can start.
func _arm(arena: Node, b: Node, dist: float, pos: Vector2 = BOAR_POS) -> void:
	var clean := await _wait_until(func(): return is_equal_approx(Engine.time_scale, 1.0), 2.0)
	if not clean:
		_check(false, "setup: Engine.time_scale did not return to 1.0 within 2 s before a charge (%s)"
			% str(Engine.time_scale))
	# A boar left dizzy by the last case is waited out: its timer is still pending and would end a later dizzy early.
	await _wait_until(func(): return not b._stun_active, 4.0)
	for i in SETTLE_FRAMES:
		b.attack_cooldown = 999.0
		b.velocity = Vector2.ZERO
		b.global_position = pos
		arena.player.velocity = Vector2.ZERO
		arena.player.global_position = pos - Vector2(dist, 0.0)
		await physics_frame
	_heal_player(arena)
	_reapply_dda()
	b.velocity = Vector2.ZERO
	b.global_position = pos
	if b._stun_active:
		_check(false, "setup: the boar was still stunned when the next charge was armed")
	b._stun_active = false
	b._dizzy = false
	b._hitstun_frozen = false
	b.recover_timer = 0.0
	b.attack_cooldown = 0.0
	b.current_health = b.max_health
	b.current_state = _state("CHASE")
	arena.player.global_position = pos - Vector2(dist, 0.0)


## _arm, then the cooldown up again: the boar stands in CHASE and starts nothing.
func _arm_idle(arena: Node, b: Node, dist: float, pos: Vector2 = BOAR_POS) -> void:
	await _arm(arena, b, dist, pos)
	b.attack_cooldown = 999.0


## One charge from _arm, watched a physics frame at a time until the boar is dizzy or in RECOVER (or LIMIT s pass).
## `mode`: "stand" (the player on the floor in the path), "air" (the player held AIR_Y high: the charge passes under
## it), "cross" (air, then moved behind the boar CROSS_AT s into the charge), "parry" (the player parries at the
## notes' moment), "stand_clear" (stand, the player's invulnerability cleared every frame) or "jump" (stand,
## then the player's own jump action JUMP_LEAD_PX before the hit box arrives). Returns the telegraph's first
## attack type, frames and game time, telegraph_duration, the states in order, the player's HP drop and how many
## separate hits made it, whether the boar ended dizzy or in RECOVER, x at the launch and at the end, whether it kept
## one direction, the game time spent in ATTACK and whether it was stunned.
func _run_charge(arena: Node, b: Node, dist: float, mode: String, pos: Vector2 = BOAR_POS) -> Dictionary:
	var p: CharacterBody2D = arena.player
	await _arm(arena, b, dist, pos)
	var hp_start: float = p.current_health
	var last_hp := hp_start
	var tele := _state("TELEGRAPH")
	var attack := _state("ATTACK")
	var recover := _state("RECOVER")
	var chase := _state("CHASE")
	var consts := _consts()
	var reach: float = _charge_reach(consts)
	var speed: float = consts.get("CHARGE_SPEED", 420.0)
	var air := mode == "air" or mode == "cross"
	var air_x: float = p.global_position.x
	var r := {"attack": -1, "frames": 0, "game_time": 0.0, "duration": 0.0, "states": [], "hp_drop": 0.0, "hits": 0,
		"dizzy": false, "recovered": false, "launch_x": NAN, "end_x": NAN, "one_dir": true, "dir": 0.0,
		"attack_time": 0.0, "stun": false, "parry_dx": 0.0, "time": 0.0, "jumped": false, "passed": false,
		"rise": 0.0}
	var frame := 0
	var release_at := -1
	var side0 := 0.0
	var tick := _tick()
	var last := -1
	var parried := false
	var crossed := false
	var cap_msec := Time.get_ticks_msec() + int(LIMIT * 4000.0)
	while r["time"] < LIMIT and Time.get_ticks_msec() < cap_msec:
		if not is_instance_valid(b):
			break
		if air:
			p.velocity = Vector2.ZERO
			p.global_position = Vector2(air_x, AIR_Y)
		if mode == "stand_clear":
			p.invulnerable = false
			p.invuln_timer = 0.0
		await physics_frame
		frame += 1
		r["time"] += tick * Engine.time_scale
		if p.current_health < last_hp:
			r["hits"] += 1
		last_hp = p.current_health
		if mode == "stand_clear" and r["hits"] > 1:
			break   # a second hit answers the check (28 HP); more could kill the player (mutation z)
		if not is_instance_valid(b):
			break
		var st: int = b.current_state
		if st == chase:
			_reapply_dda()
		if mode == "jump":
			if frame == release_at:
				Input.action_release("jump")
			r["rise"] = maxf(r["rise"], FLOOR_Y - p.global_position.y)
			var dx: float = p.global_position.x - b.global_position.x
			if st == attack and not r["jumped"] and absf(dx) - reach <= JUMP_LEAD_PX:
				Input.action_press("jump")   # as _pogo's jump: pressed after a physics frame, held two
				r["jumped"] = true
				release_at = frame + 2
				side0 = signf(dx)
			elif r["jumped"] and signf(dx) != side0:
				r["passed"] = true
		if st == tele:
			if r["frames"] == 0:
				r["attack"] = b.current_attack
			r["frames"] += 1
			r["game_time"] += tick * Engine.time_scale
			r["launch_x"] = b.global_position.x
			r["duration"] = b.telegraph_duration
		if st == attack:
			r["attack_time"] += tick * Engine.time_scale
			if absf(b.velocity.x) > 1.0:
				var d := signf(b.velocity.x)
				if r["dir"] == 0.0:
					r["dir"] = d
				elif d != r["dir"]:
					r["one_dir"] = false
			if mode == "cross" and not crossed and r["attack_time"] >= CROSS_AT:
				crossed = true
				air_x = clampf(2.0 * b.global_position.x - air_x, 0.0, 1260.0)
			if mode == "parry" and not parried \
					and absf(p.global_position.x - b.global_position.x) - reach <= speed * PARRY_LEAD:
				p._start_parry()
				parried = true
				r["parry_dx"] = absf(p.global_position.x - b.global_position.x)
		if st != last:
			r["states"].append(st)
			last = st
		r["stun"] = r["stun"] or b._stun_active
		if b._dizzy:
			r["dizzy"] = true
			break
		if st == recover:
			r["recovered"] = true
			break
	if mode == "jump":
		Input.action_release("jump")
	r["end_x"] = b.global_position.x if is_instance_valid(b) else NAN
	r["hp_drop"] = hp_start - p.current_health
	return r


## Watches the boar for `seconds` of game time, a physics frame at a time (the DDA pin held): did it start a
## telegraph or a charge, was it stunned on every frame, and how far did it move.
func _watch_quiet(b: Node, seconds: float) -> Dictionary:
	var tele := _state("TELEGRAPH")
	var attack := _state("ATTACK")
	var tick := _tick()
	var out := {"acted": false, "stunned_throughout": true, "dx": 0.0}
	var x0: float = b.global_position.x
	var game := 0.0
	var end_msec := Time.get_ticks_msec() + int(seconds * 4000.0) + 1000   # a cap, should time scale stall
	# Stop within half a frame of `seconds`: summed frame times drift by float error.
	while game + tick * 0.5 < seconds and Time.get_ticks_msec() < end_msec:
		_reapply_dda()
		await physics_frame
		game += tick * Engine.time_scale
		if b.current_state == tele or b.current_state == attack:
			out["acted"] = true
		if not b._stun_active:
			out["stunned_throughout"] = false
		out["dx"] = maxf(out["dx"], absf(b.global_position.x - x0))
	return out


## Watches a dizzy boar from the frame it was seen dizzy until it is not: game time spent (counting the frame it was
## seen), whether `_dizzy` and `_stun_active` held on every frame, whether it started anything, how far it moved and
## the state it was in afterwards.
func _watch_dizzy(b: Node) -> Dictionary:
	var tick := _tick()
	var out := {"time": tick, "both": true, "acted": false, "dx": 0.0, "after": -1}
	var x0: float = b.global_position.x
	var cap_msec := Time.get_ticks_msec() + 12000
	while Time.get_ticks_msec() < cap_msec:
		await physics_frame
		if not b._dizzy:
			break
		out["time"] += tick * Engine.time_scale
		out["both"] = out["both"] and b._stun_active
		if b.current_state == _state("TELEGRAPH") or b.current_state == _state("ATTACK"):
			out["acted"] = true
		out["dx"] = maxf(out["dx"], absf(b.global_position.x - x0))
	out["after"] = b.current_state
	return out


## The player's pogo through its input actions: jump from the floor under the boar, then {move_down} + {attack} once
## on the way down within reach of its hit box. Returns whether it fired, the boar's HP drop and the player's
## vertical speed on that frame.
func _pogo(arena: Node, b: Node) -> Dictionary:
	var p: CharacterBody2D = arena.player
	var r := {"fired": false, "hp_drop": 0.0, "bounce": 0.0, "diag": ""}
	p.global_position = Vector2(b.global_position.x, FLOOR_Y)
	p.velocity = Vector2.ZERO
	for i in SETTLE_FRAMES:
		await physics_frame
	var hp0: float = b.current_health
	Input.action_press("jump")
	await physics_frame
	await physics_frame
	Input.action_release("jump")
	# The press is made between physics steps (a process frame): from inside a physics step the attack action's
	# is_action_just_pressed() read false (seen in t13c_boar_fight_run2.log).
	var end_msec := Time.get_ticks_msec() + 3000
	while Time.get_ticks_msec() < end_msec:
		p.global_position.x = b.global_position.x
		var diff: float = b.global_position.y - p.global_position.y
		if p.velocity.y > 0.0 and diff > 20.0 and diff < 90.0:
			Input.action_press("move_down")
			Input.action_press("attack")
			r["diag"] = "diff %.0f, just_pressed %s, floor %s" % [diff, str(Input.is_action_just_pressed("attack")),
				str(p.is_on_floor())]
			await physics_frame
			await physics_frame
			r["diag"] += ", pogoing %s, boar y %.0f, player y %.0f" % [str(p.is_pogoing), b.global_position.y,
				p.global_position.y]
			r["fired"] = true
			r["bounce"] = p.velocity.y
			break
		await process_frame
	Input.action_release("move_down")
	Input.action_release("attack")
	await physics_frame
	r["hp_drop"] = hp0 - b.current_health
	return r


# ── C1 (AC-1): the boar alone ─────────────────────────────────────────────

func _test_c1_boar() -> void:
	print("[C1 the boar: values, telegraph, charge, dizzy, armour, pogo, parry, contact, scaled]")
	_c1_constants()
	var arena := await _start_arena()
	var b := _boar(arena)
	_check(b != null and b.get_script().resource_path == BOAR_SCRIPT,
		"C1 the arena spawns one StoryFightBoar running field_boar.gd")
	if b == null:
		_end_arena(arena)
		await process_frame
		return
	await _wait(0.5)   # past the spawn-in tween (0.3 s)
	_c1_instance_values(b)
	await _c1_off_screen(arena, b)
	await _c1_telegraph(arena, b)
	await _c1_charge(arena, b)
	await _c1_once_per_charge(arena, b)
	await _c1_charge_box_gate(arena, b)
	await _c1_real_jump(arena, b)
	await _c1_wall_and_dizzy(arena, b)
	await _c1_pause(arena, b)
	await _c1_hits_during_attack(arena, b)
	await _c1_armour(arena, b)
	await _c1_pogo(arena, b)
	await _c1_parry(arena, b)
	await _c1_parry_telegraph(arena, b)
	await _c1_stagger_dizzy(arena, b)
	await _c1_stagger_in_recover(arena, b)
	await _c1_no_contact_damage(arena, b)
	await _c1_scaled(arena, b)
	_end_arena(arena)
	await process_frame


## AC-1's declared values as plain constants of the script.
func _c1_constants() -> void:
	var c := _consts()
	for key in BOAR_CONSTANTS:
		_check(c.has(key) and is_equal_approx(float(c[key]), BOAR_CONSTANTS[key]),
			"C1 constant %s is %s (found %s)" % [key, str(BOAR_CONSTANTS[key]), str(c.get(key, "<missing>"))])
	_check(c.get("CHARGE_HITBOX_SIZE", Vector2.ZERO) == Vector2(60, 36)
		and c.get("CHARGE_HITBOX_OFFSET", Vector2.ZERO) == Vector2(30, -20),
		"C1 the charge's hit box is 60 x 36 at offset (30, -20) (%s, %s)"
			% [str(c.get("CHARGE_HITBOX_SIZE")), str(c.get("CHARGE_HITBOX_OFFSET"))])
	var reach: float = _charge_reach(c)
	_check(reach <= 120.0 and reach == 60.0,
		"C1 the charge's hit box reaches 60 px from the centre, within the parry's 120 px (%s px)" % str(reach))
	_check(float(c.get("DETECTION_RANGE", 0.0)) >= 1280.0,
		"C1 DETECTION_RANGE is at least the arena's width, 1280 (%s)" % str(c.get("DETECTION_RANGE")))
	var run: float = float(c.get("CHARGE_SPEED", 0.0)) * float(c.get("CHARGE_MAX_TIME", 0.0))
	_check(run > 1232.0,
		"C1 a full charge (speed x CHARGE_MAX_TIME = %s px) is longer than the 1232 px between the walls" % str(run))


## The spawned boar's runtime values under the pins: HP 45 (level scaling included), no contact damage, no dodge.
func _c1_instance_values(b: Node) -> void:
	_check(b.enemy_name == "Corrupted Boar", "C1 enemy_name is 'Corrupted Boar' (found '%s')" % b.enemy_name)
	_check(is_equal_approx(b.max_health, 45.0) and is_equal_approx(b.current_health, 45.0) and b.zone_level == 0,
		"C1 max_health is 45 under the pins, zone_level 0 (found %s)" % str(b.max_health))
	_check(b.contact_damage == 0.0, "C1 contact_damage is 0 (found %s)" % str(b.contact_damage))
	_check(b.dodge_chance == 0.0, "C1 dodge_chance is 0: no random dodge on a hit (found %s)" % str(b.dodge_chance))
	_check(b.movement_speed == 0.0, "C1 movement_speed is 0: it does not walk between charges (%s)"
		% str(b.movement_speed))
	_check(b.attacks_available == [_base_enum("AttackType", "CHARGE")],
		"C1 its one attack is the charge (%s)" % str(b.attacks_available))
	_check(b.detection_range >= 1280.0, "C1 detection_range (%s) reaches across the arena" % str(b.detection_range))


## Off-screen culling is off: no ScreenNotifier child, no notifier reference, and _is_on_screen stays true with the
## player moved 2000 px away (the flag is read, never forced: enemy_base.gd keys its frame skip on it).
func _c1_off_screen(arena: Node, b: Node) -> void:
	await _arm_idle(arena, b, NEAR_DIST)
	var p: CharacterBody2D = arena.player
	p.set_physics_process(false)
	for i in 5:
		p.global_position = Vector2(FAR_AWAY_X, AIR_Y)
		await physics_frame
	var on_screen: bool = b._is_on_screen
	p.set_physics_process(true)
	_check(b.get_node_or_null("ScreenNotifier") == null and b.get("_screen_notifier") == null,
		"C1 off-screen culling is off: no ScreenNotifier child and no notifier reference")
	# Non-discriminating headless (/code-review): with EnemyBase's notifier present the flag also stays true, since
	# no screen_exited arrives without a renderer; reported, not counted. The structural check above is the gate.
	print("  INFO (not a check): _is_on_screen with the player 2000 px away: %s" % str(on_screen))


## The telegraph is 0.6 s, game time +- one frame, wherever the player stands, and the attack is never a roll. The
## 1200 px run puts the player off-screen for a 1280-px view but inside DETECTION_RANGE.
func _c1_telegraph(arena: Node, b: Node) -> void:
	var charge := _base_enum("AttackType", "CHARGE")
	var tick := _tick()
	var cases := [["near", NEAR_DIST, BOAR_POS], ["mid", MID_DIST, BOAR_POS], ["far", FAR_DIST, Vector2(1100, FLOOR_Y)],
		["1200 px away", OFFSCREEN_DIST, OFFSCREEN_POS]]
	for case in cases:
		var r: Dictionary = await _run_charge(arena, b, case[1], "air", case[2])
		if case[0] == "1200 px away":
			# Non-discriminating headless as an off-screen check (see _c1_off_screen): reported, not counted.
			print("  INFO (not a check): the player 1200 px away: telegraph %d frames, duration %s"
				% [r["frames"], str(r["duration"])])
			continue
		_check(r["attack"] == charge and r["frames"] > 0 and absf(r["frames"] * tick - 0.6) <= tick + 0.0001
			and is_equal_approx(r["duration"], 0.6) and absf(r["game_time"] - 0.6) <= tick + 0.0001,
			"C1 the player %s: telegraph then CHARGE, 0.6 s +- one frame (duration %s, %d frames, %.3f s)"
				% [case[0], str(r["duration"]), r["frames"], r["game_time"]])


## The charge: it keeps its launch direction when the player crosses behind it, takes exactly 14 once from a player
## in its path, takes nothing from a player who is not in it (jumped).
func _c1_charge(arena: Node, b: Node) -> void:
	var cross: Dictionary = await _run_charge(arena, b, PATH_DIST, "cross")
	_check(cross["dir"] == -1.0 and cross["one_dir"] and cross["states"].has(_state("ATTACK")),
		"C1 the charge keeps its launch direction when the player crosses behind it (dir %s, one direction %s)"
			% [str(cross["dir"]), str(cross["one_dir"])])
	var hit: Dictionary = await _run_charge(arena, b, PATH_DIST, "stand")
	_check(is_equal_approx(hit["hp_drop"], 14.0) and hit["hits"] == 1,
		"C1 a player in the path loses exactly 14, once per charge (%s HP, %d hits)"
			% [str(hit["hp_drop"]), hit["hits"]])
	var jumped: Dictionary = await _run_charge(arena, b, PATH_DIST, "air")
	_check(is_zero_approx(jumped["hp_drop"]) and jumped["states"].has(_state("ATTACK")),
		"C1 a player who jumps the charge loses nothing (%s HP)" % str(jumped["hp_drop"]))


## A charge launched at one wall reaches the other and ends dizzy; at the wall it is dizzy for 2.0 s (game time,
## +- one frame), still, with no attack. A hit while dizzy takes 15 and leaves its x unchanged and its velocity 0.
func _c1_wall_and_dizzy(arena: Node, b: Node) -> void:
	var tick := _tick()
	await _arm_idle(arena, b, NEAR_DIST)
	var cue_before := _cue(b)
	var r: Dictionary = await _run_charge(arena, b, -900.0, "air", LEFT_POS)
	var cue_during := _cue(b)
	_check(r["dizzy"] and r["end_x"] >= WALL_RIGHT_X and not r["recovered"],
		"C1 a charge launched at the left wall reaches the right wall and ends dizzy (dizzy %s, x %.0f)"
			% [str(r["dizzy"]), r["end_x"]])
	_check(r["dizzy"] and b._dizzy and b._stun_active,
		"C1 at the wall `_dizzy` and `_stun_active` are both true")
	var w: Dictionary = await _watch_dizzy(b)
	var cue_after := _cue(b)
	_check(r["dizzy"] and cue_before == "hidden" and cue_during == "shown" and cue_after == "hidden",
		"C1 the dizzy cue (D10) is hidden before the wall, shown while dizzy and hidden after (%s, %s, %s)"
			% [cue_before, cue_during, cue_after])
	_check(r["dizzy"] and absf(w["time"] - 2.0) <= tick + 0.0001 and w["both"],
		"C1 dizzy lasts 2.0 s of game time +- one frame, stunned throughout (%.3f s, both %s)"
			% [w["time"], str(w["both"])])
	_check(r["dizzy"] and w["dx"] < 1.0 and not w["acted"],
		"C1 while dizzy it stands still and starts nothing (moved %.1f px, acted %s)" % [w["dx"], str(w["acted"])])
	_check(r["dizzy"] and w["after"] == _state("RECOVER"),
		"C1 after dizzy it is in RECOVER (state %s)" % str(w["after"]))
	var quiet: Dictionary = await _watch_quiet(b, float(_consts().get("RECOVER_TIME", 0.8))
		+ float(_consts().get("ATTACK_COOLDOWN", 1.2)) - 3.0 * tick)
	_check(not quiet["acted"], "C1 no new telegraph before RECOVER_TIME + ATTACK_COOLDOWN after dizzy")
	# A hit while dizzy: HP 15 lower, no slide, no hop.
	await _arm_idle(arena, b, NEAR_DIST)
	b._enter_dizzy()
	await physics_frame
	var x0: float = b.global_position.x
	var hp0: float = b.current_health
	b.take_damage(PLAYER_HIT, arena.player.global_position)
	var still_v: bool = b.velocity.x == 0.0 and b.velocity.y == 0.0
	for i in 5:
		await physics_frame
	_check(is_equal_approx(hp0 - b.current_health, PLAYER_HIT) and absf(b.global_position.x - x0) < 0.5 and still_v
		and b._dizzy,
		"C1 a hit while dizzy takes 15, leaves x unchanged (%.2f px) and velocity at 0 (still %s)"
			% [absf(b.global_position.x - x0), str(still_v)])


## Armour: outside dizzy a 15-damage hit leaves HP 45, starts no hit-stun, no knockback and does not touch its state.
func _c1_armour(arena: Node, b: Node) -> void:
	await _arm_idle(arena, b, NEAR_DIST)
	var hp0: float = b.current_health
	var sprite: CanvasItem = b.get_node_or_null("Sprite")
	var modulate_before: Color = sprite.modulate if sprite else Color.BLACK
	var flash_before: Variant = _flash_tween(sprite)
	var animating_before: bool = _hurt_animating(sprite)
	_freeze(b)   # no physics frame can zero a knockback before it is read (/code-review)
	var velocity_before: Vector2 = b.velocity
	var x_before: float = b.global_position.x
	b.take_damage(PLAYER_HIT, arena.player.global_position)
	b.take_damage(PLAYER_HIT, arena.player.global_position)
	# Read before any frame runs: _state_chase zeroes velocity.x every frame, so a later read would hide a knockback.
	var velocity_after: Vector2 = b.velocity
	var x_after: float = b.global_position.x
	var modulate_after: Color = sprite.modulate if sprite else Color.WHITE
	var flash_after: Variant = _flash_tween(sprite)
	var animating_after: bool = _hurt_animating(sprite)
	b.set_physics_process(true)
	b.set_process(true)
	await physics_frame
	_check(is_equal_approx(b.current_health, 45.0) and is_equal_approx(hp0, 45.0),
		"C1 outside dizzy a 15-damage hit leaves HP at 45 (HP %s)" % str(b.current_health))
	_check(not b._stun_active and not b._hitstun_frozen and b.current_state == _state("CHASE"),
		"C1 outside dizzy a hit starts no hit-stun (stun %s, state %s)" % [str(b._stun_active), str(b.current_state)])
	# x is reported only: with the boar's physics frozen it cannot move, so it would not discriminate.
	_check(velocity_after == velocity_before,
		"C1 outside dizzy a hit gives no knockback, read before the next frame (velocity %s -> %s, x %.1f -> %.1f)"
			% [str(velocity_before), str(velocity_after), x_before, x_after])
	_check(sprite != null and modulate_after == modulate_before and flash_after == flash_before
		and (animating_before or not animating_after),
		"C1 outside dizzy a hit plays no hit flash: modulate unchanged (%s -> %s), no new flash or hurt tween"
			% [str(modulate_before), str(modulate_after)])
	b.take_damage(9999.0, arena.player.global_position)
	_check(b.current_state != _state("DEAD") and is_equal_approx(b.current_health, 45.0),
		"C1 outside dizzy even 9999 damage cannot kill it")


## The pogo through input actions: 27 on a dizzy boar (the combo multiplier 1.0 first), nothing on an armoured one
## but the player still bounces.
func _c1_pogo(arena: Node, b: Node) -> void:
	await _arm_idle(arena, b, NEAR_DIST)
	var armoured: Dictionary = await _pogo(arena, b)
	_check(armoured["fired"] and armoured["bounce"] < -400.0 and is_zero_approx(armoured["hp_drop"]),
		"C1 a pogo on an armoured boar bounces the player and takes nothing (fired %s, vy %s, HP drop %s; %s)"
			% [str(armoured["fired"]), str(armoured["bounce"]), str(armoured["hp_drop"]), armoured["diag"]])
	await _arm_idle(arena, b, NEAR_DIST)
	_reset_combo()
	_check(is_equal_approx(_juice().get_combo_multiplier(), 1.0), "C1 the combo multiplier is 1.0 before the pogo")
	b._enter_dizzy()
	var dizzy: Dictionary = await _pogo(arena, b)
	_check(dizzy["fired"] and is_equal_approx(dizzy["hp_drop"], POGO_HIT),
		"C1 a pogo on a dizzy boar takes 27 = 15 x 1.8 (fired %s, HP drop %s; %s)"
			% [str(dizzy["fired"]), str(dizzy["hp_drop"]), dizzy["diag"]])
	_reset_combo()


## A parried charge: no damage, a stagger, the charge over, RECOVER then the cooldown; the armour holds during the
## stagger (a hit leaves HP unchanged and the stagger is not dizzy).
func _c1_parry(arena: Node, b: Node) -> void:
	var tick := _tick()
	var r: Dictionary = await _run_charge(arena, b, PATH_DIST, "parry")
	_check(r["recovered"] and b._stun_active and is_zero_approx(r["hp_drop"]) and not b._dizzy,
		("C1 the parried charge: the boar is staggered (stun %s), the charge is over, the player's HP unchanged"
			+ " (drop %s, parry at %.0f px) and it is not dizzy")
			% [str(b._stun_active), str(r["hp_drop"]), r["parry_dx"]])
	var hp0: float = b.current_health
	b.take_damage(PLAYER_HIT, arena.player.global_position)
	_check(is_equal_approx(b.current_health, hp0) and not b._dizzy and b.current_state == _state("RECOVER"),
		"C1 a hit during the parry stagger leaves HP unchanged (HP %s of %s)" % [str(b.current_health), str(hp0)])
	var ended := await _wait_until(func(): return not b._stun_active, 3.0)
	var in_recover: bool = b.current_state == _state("RECOVER")
	var c := _consts()
	var quiet_for: float = float(c.get("RECOVER_TIME", 0.8)) + float(c.get("ATTACK_COOLDOWN", 1.2)) - 4.0 * tick
	var quiet: Dictionary = await _watch_quiet(b, quiet_for)
	_check(ended and in_recover and not quiet["acted"],
		"C1 after the stagger it is in RECOVER and starts nothing before RECOVER_TIME + ATTACK_COOLDOWN (ended %s, %s)"
			% [str(ended), str(in_recover)])


## D9: a parry stagger that lands while the boar is in RECOVER (not interrupting a telegraph or a charge) ends with
## the cooldown up, so no telegraph starts within 0.9 x ATTACK_COOLDOWN of game time after the stagger ends. The
## stagger is called directly with PlayerCombat's duration (a successful parry calls enemy.stagger(1.2)): in RECOVER
## the boar has no attack to parry.
func _c1_stagger_in_recover(arena: Node, b: Node) -> void:
	await _arm_idle(arena, b, MID_DIST)
	b.current_state = _state("RECOVER")
	b.recover_timer = 0.0
	b.attack_cooldown = 0.0
	b.stagger(STAGGER_TIME)
	var staggered: bool = b._stun_active and not b._dizzy
	var ended := await _wait_until(func(): return not b._stun_active, 3.0)
	var cooldown := float(_consts().get("ATTACK_COOLDOWN", 1.2))
	var quiet: Dictionary = await _watch_quiet(b, cooldown * 0.9)
	_check(staggered and ended and not quiet["acted"],
		"C1 a parry stagger in RECOVER: no telegraph within 0.9 x ATTACK_COOLDOWN after it ends (D9; ended %s, %s)"
			% [str(ended), "acted" if quiet["acted"] else "quiet"])


## Control run (/code-review): the player's invulnerability is cleared every frame, so only the boar's own
## once-per-charge rule (_charge_hit_pending) can stop a second hit.
func _c1_once_per_charge(arena: Node, b: Node) -> void:
	var r: Dictionary = await _run_charge(arena, b, PATH_DIST, "stand_clear")
	_check(r["hits"] == 1 and is_equal_approx(r["hp_drop"], 14.0) and (r["dizzy"] or r["recovered"]),
		"C1 once per charge with the player's invulnerability cleared every frame: exactly one hit, the charge"
			+ " watched to its end (%d hits, %s HP, dizzy %s, recovered %s)"
			% [r["hits"], str(r["hp_drop"]), str(r["dizzy"]), str(r["recovered"])])


## The boar's charge-box gate (_on_enemy_attack_hitbox_body_entered), called directly: the double hit it stops is
## timing-dependent, so no charge reproduces it reliably. A charge box reporting the player while the charge's hit is
## no longer pending takes nothing; the same report with the hit pending takes CHARGE_DAMAGE (the control) and clears
## the pending flag. The boxes are built as EnemyBase builds one (its metas), at the player's position.
func _c1_charge_box_gate(arena: Node, b: Node) -> void:
	await _arm_idle(arena, b, NEAR_DIST)
	var p: CharacterBody2D = arena.player
	var results: Array = []
	for pending in [false, true]:
		_heal_player(arena)
		var box := Area2D.new()
		box.name = "TestChargeBox"
		box.set_meta("hit_targets", [])
		box.set_meta("damage", float(_consts().get("CHARGE_DAMAGE", 14.0)))
		box.set_meta("damage_type", "charge")
		box.set_meta("hitbox_size", _consts().get("CHARGE_HITBOX_SIZE", Vector2(60, 36)))
		b.add_child(box)
		box.global_position = p.global_position
		b._charge_hit_pending = pending
		var hp0: float = p.current_health
		b._on_enemy_attack_hitbox_body_entered(p, box)
		results.append([hp0 - p.current_health, b._charge_hit_pending])
		box.queue_free()
		await physics_frame
	_heal_player(arena)
	_check(is_zero_approx(results[0][0]) and is_equal_approx(results[1][0], 14.0) and not results[1][1],
		"C1 the charge-box gate: no hit when the charge's hit is not pending; 14 and the flag cleared when it is (%s)"
			% str(results))


## Control run (/code-review): the jump through the player's own jump action, pressed JUMP_LEAD_PX before the hit box
## reaches it; the charge passes under it and takes nothing.
func _c1_real_jump(arena: Node, b: Node) -> void:
	var r: Dictionary = await _run_charge(arena, b, PATH_DIST, "jump")
	_check(r["jumped"] and r["passed"] and r["rise"] > 30.0 and is_zero_approx(r["hp_drop"]),
		"C1 a real-input jump over the charge: it passes under the player, no damage (jumped %s, passed %s, rise %.0f"
			% [str(r["jumped"]), str(r["passed"]), r["rise"]] + " px, %s HP)" % str(r["hp_drop"]))


## R2: pause (PauseScreen.toggle_pause) mid-charge and while dizzy, held PAUSE_HOLD s of wall time. Paused, the charge
## neither moves nor ages; the dizzy does not drain, and still totals DIZZY_TIME of game time (+- one frame).
func _c1_pause(arena: Node, b: Node) -> void:
	var ps := get_root().get_node("PauseScreen")
	var p: CharacterBody2D = arena.player
	var tick := _tick()
	await _arm(arena, b, -900.0, LEFT_POS)
	var air_x: float = p.global_position.x
	var reached := false
	var cap := Time.get_ticks_msec() + 4000
	while Time.get_ticks_msec() < cap:
		p.velocity = Vector2.ZERO
		p.global_position = Vector2(air_x, AIR_Y)
		await physics_frame
		if b.current_state == _state("ATTACK") and b._charge_elapsed >= PAUSE_AFTER:
			reached = true
			break
	var x0: float = b.global_position.x
	var e0: float = b._charge_elapsed
	ps.toggle_pause()
	var was_paused: bool = paused
	await _wait(PAUSE_HOLD)
	var x1: float = b.global_position.x
	var e1: float = b._charge_elapsed
	ps.toggle_pause()
	_check(reached and was_paused and x1 == x0 and e1 == e0 and not paused,
		"C1 paused mid-charge for %.1f s: x and _charge_elapsed unchanged (paused %s; x %.1f -> %.1f, %.3f -> %.3f s)"
			% [PAUSE_HOLD, str(was_paused), x0, x1, e0, e1])
	cap = Time.get_ticks_msec() + 6000
	while Time.get_ticks_msec() < cap and not b._dizzy:
		p.velocity = Vector2.ZERO
		p.global_position = Vector2(air_x, AIR_Y)
		await physics_frame
	var dizzy_seen: bool = b._dizzy
	var game := tick   # the frame it was seen dizzy, as _watch_dizzy counts it
	var held := false
	var still_dizzy := false
	var pause_ok := false
	cap = Time.get_ticks_msec() + 8000
	while dizzy_seen and Time.get_ticks_msec() < cap:
		await physics_frame
		if not b._dizzy:
			break
		game += tick * Engine.time_scale
		if not held and game >= PAUSE_AFTER:
			held = true
			ps.toggle_pause()
			pause_ok = paused
			await _wait(PAUSE_HOLD)
			still_dizzy = b._dizzy and b._stun_active
			ps.toggle_pause()
	_check(dizzy_seen and held and pause_ok and still_dizzy and not paused and absf(game - 2.0) <= tick + 0.0001,
		"C1 paused %.1f s while dizzy: still dizzy after it, and dizzy totals 2.0 s of game time +- one frame (%.3f s)"
			% [PAUSE_HOLD, game])


## R3: hits on the first TELEGRAPH frame and the first ATTACK frame of a charge take no HP and start no hit-stun; the
## charge still runs one way into the wall and ends dizzy.
func _c1_hits_during_attack(arena: Node, b: Node) -> void:
	var p: CharacterBody2D = arena.player
	await _arm(arena, b, -900.0, LEFT_POS)
	var air_x: float = p.global_position.x
	var hit_tele := false
	var hit_attack := false
	var stunned := false
	var dirs: Array = []
	var cap := Time.get_ticks_msec() + 8000
	while Time.get_ticks_msec() < cap and not b._dizzy:
		p.velocity = Vector2.ZERO
		p.global_position = Vector2(air_x, AIR_Y)
		await physics_frame
		var st: int = b.current_state
		if st == _state("TELEGRAPH") and not hit_tele:
			hit_tele = true
			b.take_damage(PLAYER_HIT, p.global_position)
			stunned = stunned or b._stun_active or b._hitstun_frozen or b.current_state != st
		elif st == _state("ATTACK") and not hit_attack:
			hit_attack = true
			b.take_damage(PLAYER_HIT, p.global_position)
			stunned = stunned or b._stun_active or b._hitstun_frozen or b.current_state != st
		if b.current_state == _state("RECOVER") or (b.current_state == _state("STUNNED") and not b._dizzy):
			stunned = true
		if b.current_state == _state("ATTACK") and absf(b.velocity.x) > 1.0 and not dirs.has(signf(b.velocity.x)):
			dirs.append(signf(b.velocity.x))
	_check(hit_tele and hit_attack and is_equal_approx(b.current_health, 45.0) and not stunned,
		"C1 hits on the first TELEGRAPH and first ATTACK frames take no HP and start no hit-stun (HP %s, stunned %s)"
			% [str(b.current_health), str(stunned)])
	_check(hit_attack and dirs == [1.0] and b._dizzy and b.global_position.x >= WALL_RIGHT_X,
		"C1 after those hits the charge still runs one way into the wall and ends dizzy (dirs %s, dizzy %s, x %.0f)"
			% [str(dirs), str(b._dizzy), b.global_position.x])


## A parry stagger during the TELEGRAPH (EnemyBase.stagger as PlayerCombat calls it): no charge launches, it goes to
## RECOVER, and the telegraph tween is killed.
func _c1_parry_telegraph(arena: Node, b: Node) -> void:
	await _arm(arena, b, MID_DIST)
	var reached := await _wait_until(func(): return b.current_state == _state("TELEGRAPH"), 3.0)
	var tween_before: bool = b._telegraph_tween != null and b._telegraph_tween.is_valid()
	b.stagger(STAGGER_TIME)
	var state_after: int = b.current_state
	var tween_after: bool = b._telegraph_tween != null and b._telegraph_tween.is_valid()
	var launched := false
	var tick := _tick()
	var game := 0.0
	var cap_msec := Time.get_ticks_msec() + int(STAGGER_TIME * 4000.0) + 1000   # a cap, should time scale stall
	while game < STAGGER_TIME - 0.1 and Time.get_ticks_msec() < cap_msec:
		await physics_frame
		game += tick * Engine.time_scale
		launched = launched or b.current_state == _state("ATTACK") or absf(b.velocity.x) > 1.0
	_check(reached and tween_before and state_after == _state("RECOVER") and not tween_after and not launched
		and game + 0.0001 >= STAGGER_TIME - 0.1,
		"C1 a stagger during the TELEGRAPH: RECOVER, the telegraph tween killed, no charge launches (%s, %s, %s)"
			% [str(state_after), str(tween_after), str(launched)])


## A stagger on a dizzy boar is ignored: it stays dizzy (`_dizzy`, `_stun_active`, STUNNED) and its cooldown and tint
## are untouched.
func _c1_stagger_dizzy(arena: Node, b: Node) -> void:
	await _arm_idle(arena, b, NEAR_DIST)
	b._enter_dizzy()
	b.attack_cooldown = 0.0   # from 0, a stagger that raised the cooldown (D9's branch) would show
	var cooldown: float = b.attack_cooldown
	var sprite: CanvasItem = b.get_node_or_null("Sprite")
	var tint: Color = sprite.modulate if sprite else Color.BLACK
	b.stagger(STAGGER_TIME)
	_check(b._dizzy and b._stun_active and b.current_state == _state("STUNNED") and b.attack_cooldown == cooldown
		and sprite != null and sprite.modulate == tint,
		"C1 a stagger on a dizzy boar is ignored: still dizzy, cooldown and tint untouched (dizzy %s, cooldown %s)"
			% [str(b._dizzy), str(b.attack_cooldown)])


## Control for C4's mid-charge retry (/code-review): the same setup, but after the restore the old boar is enabled
## again (ATTACK, its collision and physics back). The C4 watch must then see the old charge's hit, which shows that
## C4's "the old charge does not hit" check can fail. C4's own code is not touched.
func _test_c1_retry_control() -> void:
	print("[C1 control for C4's mid-charge retry: the old boar enabled again is seen hitting]")
	var arena := await _start_arena()
	var old := _boar(arena)
	if old == null:
		_check(false, "C1 retry control: no StoryFightBoar in the arena")
		_end_arena(arena)
		await process_frame
		return
	await _wait(0.5)
	var p: CharacterBody2D = arena.player
	var retries_before: int = arena.story_fight_retries
	var spawn := Vector2(arena._story_cfg["player_spawn"].x, FLOOR_Y)
	await _arm(arena, old, RETRY_CHARGE_DIST, spawn + Vector2(RETRY_CHARGE_DIST, 0.0))
	var layer: int = old.collision_layer
	var mask: int = old.collision_mask
	old.attack_cooldown = DEATH_LEAD
	_hurt_player(arena)
	var end_msec := Time.get_ticks_msec() + 8000
	while Time.get_ticks_msec() < end_msec and arena.story_fight_retries == retries_before:
		await physics_frame
		if is_instance_valid(old) and old.current_state == _state("CHASE"):
			_reapply_dda()
	var retried: bool = arena.story_fight_retries == retries_before + 1   # else the watch starts from the kill's HP
	p.invulnerable = false
	p.invuln_timer = 0.0
	p.global_position = spawn
	p.velocity = Vector2.ZERO
	_freeze(arena._story_enemy)
	var enabled := is_instance_valid(old)
	if enabled:
		old.current_state = _state("ATTACK")
		old.collision_layer = layer
		old.collision_mask = mask
		old.visible = true
		old.set_physics_process(true)
		old.set_process(true)
	var start_hp: float = p.current_health
	var lowest: float = start_hp
	var watched := 0.0   # game seconds
	var watch_cap := Time.get_ticks_msec() + int(RESTORE_WATCH * 4000.0) + 1000   # a cap, should time scale stall
	while watched < RESTORE_WATCH and Time.get_ticks_msec() < watch_cap:
		p.invulnerable = false
		p.invuln_timer = 0.0
		await physics_frame
		watched += _tick() * Engine.time_scale
		lowest = minf(lowest, p.current_health)
	_check(enabled and retried and start_hp == p.max_health and watched + 0.0001 >= RESTORE_WATCH
		and lowest < p.max_health,
		"C1 retry control: after a retry from full HP, with the old boar enabled again the C4 watch sees its hit"
			+ " (retried %s, start HP %s, lowest HP %s of %s)"
			% [str(retried), str(start_hp), str(lowest), str(p.max_health)])
	_end_arena(arena)
	await process_frame


## Standing within 30 px of the boar does no damage: EnemyBase's contact check runs with the boar's physics on, no
## charge under way. The player's own physics is held, as in the guardian's case.
func _c1_no_contact_damage(arena: Node, b: Node) -> void:
	await _arm_idle(arena, b, 20.0)
	b.is_hostile = true
	b.player_ref = arena.player
	var p: CharacterBody2D = arena.player
	var hp: float = p.current_health
	var acted := false
	var gap := 0.0
	p.set_physics_process(false)
	var game := 0.0
	var tick := _tick()
	var cap_msec := Time.get_ticks_msec() + int(CONTACT_WATCH * 4000.0) + 1000   # a cap, should time scale stall
	while game < CONTACT_WATCH and Time.get_ticks_msec() < cap_msec:
		b.attack_cooldown = 999.0   # nothing starts: only the contact check can hurt the player
		p.global_position = b.global_position - Vector2(20.0, 0.0)
		await physics_frame
		game += tick * Engine.time_scale
		gap = maxf(gap, b.global_position.distance_to(p.global_position))
		if b.current_state == _state("TELEGRAPH") or b.current_state == _state("ATTACK"):
			acted = true
	p.set_physics_process(true)
	_check(game + 0.0001 >= CONTACT_WATCH and not acted and gap < 30.0 and p.current_health == hp,
		"C1 within 30 px of the boar for 1.0 s with physics running and no charge: HP unchanged (%s of %s; %.1f px)"
			% [str(p.current_health), str(hp), gap])


## AC-1's multiplier clauses away from 1.0: zone_level 3 against the pinned player level 1 (damage multiplier 1.5, which
## also scales the boar's HP, so max_health is read after spawn) and the DDA score 85 (difficulty multiplier 1.25).
func _c1_scaled(arena: Node, b: Node) -> void:
	var c := _consts()
	var tick := _tick()
	var zone: int = b.zone_level
	b.zone_level = SCALED_ZONE_LEVEL
	_dda_pin = SCALED_DDA_SCORE
	var dmg_mult: float = b.get_enemy_damage_multiplier()
	_reapply_dda()
	var dda_mult: float = _gm().get_difficulty_multiplier()
	_check(is_equal_approx(dmg_mult, 1.5) and is_equal_approx(dda_mult, 1.25),
		"C1 scaled: the multipliers under test are 1.5 (damage) and 1.25 (difficulty) (%s, %s)"
			% [str(dmg_mult), str(dda_mult)])
	var r: Dictionary = await _run_charge(arena, b, PATH_DIST, "stand")
	var want_dmg: float = float(c.get("CHARGE_DAMAGE", 0.0)) * dmg_mult
	var want_time: float = maxf(float(c.get("CHARGE_TELEGRAPH", 0.0)) / dda_mult, 0.25)
	_check(not is_equal_approx(dmg_mult, 1.0) and is_equal_approx(r["hp_drop"], want_dmg) and r["hits"] == 1,
		"C1 scaled: the charge takes 14 x get_enemy_damage_multiplier() = %s HP, once (took %s in %d hits)"
			% [str(want_dmg), str(r["hp_drop"]), r["hits"]])
	_check(not is_equal_approx(dda_mult, 1.0) and is_equal_approx(r["duration"], want_time)
		and absf(r["game_time"] - want_time) <= tick + 0.0001,
		"C1 scaled: the charge telegraphs 0.6 / the difficulty multiplier = %.3f s (%s s, %.3f s run)"
			% [want_time, str(r["duration"]), r["game_time"]])
	b.zone_level = zone
	_dda_pin = PIN_DDA_SCORE
	_reapply_dda()


## With the arena's walls removed a charge runs for CHARGE_MAX_TIME (3.5 s of game time, +- two frames) and ends in
## RECOVER, never dizzy.
func _test_c1_no_walls() -> void:
	print("[C1 a charge with no walls ends in RECOVER after CHARGE_MAX_TIME]")
	var arena := await _start_arena()
	var b := _boar(arena)
	if b == null:
		_check(false, "C1 no walls: no StoryFightBoar in the arena")
		_end_arena(arena)
		await process_frame
		return
	await _wait(0.5)
	var removed := 0
	for n in arena.get_children():
		if n is StaticBody2D and n.position.y == -1400.0:   # the arena's two walls (combat_arena.gd)
			n.collision_layer = 0
			removed += 1
	var r: Dictionary = await _run_charge(arena, b, -1000.0, "air", LEFT_POS)
	var tick := _tick()
	var max_time: float = float(_consts().get("CHARGE_MAX_TIME", 3.5))
	_check(removed > 0 and r["recovered"] and not r["dizzy"]
		and absf(r["attack_time"] - max_time) <= 2.0 * tick + 0.0001,
		"C1 with %d walls removed a charge ends in RECOVER after %.1f s, not dizzy (recovered %s, dizzy %s, %.3f s)"
			% [removed, max_time, str(r["recovered"]), str(r["dizzy"]), r["attack_time"]])
	_end_arena(arena)
	await process_frame


# ── C2 (AC-2): the row ────────────────────────────────────────────────────

func _test_c2_row() -> void:
	print("[C2 the ch1_boar row]")
	var arena_script: Script = load(ARENA_SCRIPT)
	var rows: Dictionary = arena_script.get_script_constant_map().get("STORY_FIGHTS", {})
	var row: Dictionary = rows.get(ROW_ID, {})
	_check(not row.is_empty(), "C2 STORY_FIGHTS has the row '%s'" % ROW_ID)
	var msgs: PackedStringArray = arena_script.call("validate_story_fight", row)
	_check(not row.is_empty() and msgs.is_empty(),
		"C2 validate_story_fight gives no message for the row %s" % str(msgs))
	_check(row.get("enemy_script") == BOAR_SCRIPT and row.get("enemy_type") == "field_boar"
		and row.get("enemy_name") == "StoryFightBoar", "C2 enemy_script, enemy_type and enemy_name are the boar's")
	_check(row.get("enemy_size") == Vector2(48, 40) and row.get("enemy_color") == Color(0.7, 0.15, 0.15),
		"C2 the body is 48 x 40, Color(0.7, 0.15, 0.15), the village marker's")
	var spawn: Vector2 = row.get("enemy_spawn", Vector2(9999, 0))
	var player_spawn: Vector2 = row.get("player_spawn", Vector2.ZERO)
	_check(spawn.x <= 840.0 and spawn.x > player_spawn.x,
		"C2 the boar spawns inside the first frame (x <= 840), to the right of the player (x %s)" % str(spawn.x))
	_check(row.get("default_return_scene") == "res://scenes/chapter1/oakhaven_village.tscn",
		"C2 default_return_scene is the village's scene")
	_check(row.get("flags") == [FLAG], "C2 flags is [\"%s\"] (found %s)" % [FLAG, str(row.get("flags"))])
	var slime_row: Dictionary = rows.get("ch1_slime", {})
	_check(row.get("shard_color") == SHARD_COLOR and row.get("shard_count") == 8, "C2 8 shards of the boar's colour")
	for key in ["shard_fade", "shard_size", "shard_z"]:
		_check(not slime_row.is_empty() and row.get(key) == slime_row.get(key),
			"C2 %s is the slime row's (%s)" % [key, str(row.get(key))])
	var backdrop: Dictionary = row.get("backdrop", {})
	_check(backdrop.get("ground") == Color(0.25, 0.55, 0.3) and backdrop.get("sky") == Color(0.55, 0.72, 0.88)
		and backdrop.get("path") == Color(0.4, 0.3, 0.18) and backdrop.get("trees") == [],
		"C2 the backdrop is the village's ground, a daytime sky and a field path, with no trees")
	var slime_controls: String = str(slime_row.get("controls", ""))
	var want := slime_controls.replace("{defend} — Parry",
		"{jump} then {move_down} + {attack} — Pogo | {defend} — Parry")
	_check(want != slime_controls and row.get("controls") == want,
		"C2 the controls line is the slime row's with the pogo inserted before Parry (%s)" % str(row.get("controls")))
	var rendered: String = get_root().get_node("InputService").fmt(str(row.get("controls", "")))
	var label := Label.new()
	label.text = rendered
	var width: float = label.get_minimum_size().x
	label.free()
	_check(rendered.contains("Pogo") and not rendered.contains("{") and width > 0.0 and width <= 1280.0,
		"C2 the controls line renders the pogo with the bound keys and fits the 1280 px line (%.0f px: %s)"
			% [width, rendered])
	var bible := FileAccess.get_file_as_string(BIBLE)
	_check(bible.contains("| `%s` |" % FLAG), "C2 STORY_BIBLE section 5 has a row for %s" % FLAG)


# ── C4 (AC-4): the fight in the arena ─────────────────────────────────────

func _test_c4_win() -> void:
	print("[C4 winning]")
	var gm := _gm()
	var arena := await _start_arena()
	var b := _boar(arena)
	if b == null:
		_check(false, "C4 the win: no StoryFightBoar in the arena")
		_end_arena(arena)
		await process_frame
		return
	_check(gm.current_state == gm.GameState.COMBAT, "C4 GameState is COMBAT during the fight")
	await _wait(0.5)
	_freeze(b)
	var xp_before: int = gm.player_stats.get("xp", 0)
	var gold_before: int = gm.player_stats.get("gold", 0)
	var items_before: Dictionary = get_root().get_node("Inventory").items.duplicate()
	var hp_before := C4_KEPT_HP   # below full: a win that refilled or zeroed the HP would show (R4)
	arena.player.current_health = float(hp_before)
	gm.player_stats["hp"] = hp_before
	var flag_sets: Array = []
	var on_flag := func(flag_name: String, value: bool):
		if flag_name == FLAG and value:
			flag_sets.append(flag_name)
	gm.story_flag_updated.connect(on_flag)
	b.current_state = _state("CHASE")
	b.take_damage(9999.0)
	_check(b.current_state != _state("DEAD") and not gm.has_flag(FLAG) and not arena._story_resolved,
		"C4 HP to 0 outside dizzy is not possible: no death, no flag, no win")
	b._enter_dizzy()
	var pos: Vector2 = b.global_position
	var transitions_before := _transitions
	var cue_dizzy := _cue(b)
	b.take_damage(b.max_health)
	_check(cue_dizzy == "shown" and _cue(b) == "hidden",
		"C4 the dizzy cue is shown while dizzy and hidden when the boar dies (%s, %s)" % [cue_dizzy, _cue(b)])
	var shards := _shards(arena)
	_check(shards.size() == 8
		and shards.all(func(s): return s.color == SHARD_COLOR and s.global_position.distance_to(pos) < 80.0),
		"C4 the boar breaks into 8 polygon shards of Color(0.7, 0.15, 0.15) at its position (%d)" % shards.size())
	_check(gm.has_flag(FLAG), "C4 %s is set" % FLAG)
	_check(arena._story_resolved and arena.player.invulnerable, "C4 the guard is set and the player is invulnerable")
	_check(gm.player_stats.get("xp", 0) == xp_before and gm.player_stats.get("gold", 0) == gold_before
		and get_root().get_node("Inventory").items == items_before, "C4 XP, gold and the inventory are unchanged")
	var pickups: Array = get_root().get_node("DropManager")._active_pickups.filter(
		func(p): return is_instance_valid(p) and arena.is_ancestor_of(p))
	_check(pickups.is_empty() and b.loot_table == null,
		"C4 no item or gold pickup in the arena and the loot table is null")
	var done := await _wait_until(func(): return _outcomes.size() > 0, 3.0)
	_check(done and _outcomes == ["win"], "C4 story_fight_resolved emitted once, outcome 'win' (%s)" % str(_outcomes))
	await _wait_until(func(): return current_scene != null and current_scene.scene_file_path == STUB, 6.0)
	_check(current_scene != null and current_scene.scene_file_path == STUB and _transitions == transitions_before + 1,
		"C4 the game changed once to the return scene (transitions %d)" % (_transitions - transitions_before))
	_check(flag_sets.size() == 1, "C4 %s was set once (%d times)" % [FLAG, flag_sets.size()])
	_check(gm.player_stats.get("hp", 0) == hp_before and hp_before > 0 and arena.story_fight_retries == 0,
		"C4 the player's HP is kept (%d) and no retry ran" % gm.player_stats.get("hp", 0))
	_check(_time_requests_empty(), "C4 no ContextStack entry or time-scale request is left")
	gm.story_flag_updated.disconnect(on_flag)
	_end_arena(arena)
	await _wait_scene_settled()


func _test_c4_retry() -> void:
	print("[C4 the player's death is a retry with a fresh boar]")
	var gm := _gm()
	var arena := await _start_arena()
	var old := _boar(arena)
	if old == null:
		_check(false, "C4 the retry: no StoryFightBoar in the arena")
		_end_arena(arena)
		await process_frame
		return
	_freeze(old)
	var old_id := old.get_instance_id()
	var retries_before: int = arena.story_fight_retries
	_hurt_player(arena)
	_check(arena.player.is_dead, "C4 the player dies")
	var ok := await _wait_until(func(): return arena.story_fight_retries == retries_before + 1, 8.0)
	await process_frame
	var fresh := _boar(arena)
	_check(ok and fresh != null and fresh.get_instance_id() != old_id and fresh.current_health == fresh.max_health,
		"C4 a new StoryFightBoar instance at full HP, story_fight_retries + 1 (%d)" % arena.story_fight_retries)
	_check(not arena.player.is_dead and arena.player.current_health == arena.player.max_health
		and gm.player_stats.get("hp", 0) == int(arena.player.max_health),
		"C4 the player's HP is full after the retry")
	var old_valid := is_instance_valid(old)
	_check(old_valid and old.name == "StoryFightBoar_old" and not old.visible and old.collision_layer == 0,
		"C4 the old boar is disabled, hidden and renamed at once (still in the tree %s)" % str(old_valid))
	_check(_time_requests_empty(), "C4 time scale 1.0 and no ContextStack entry after the retry")
	_end_arena(arena)
	await process_frame


## The old boar is mid-charge when the retry runs. The player dies DEATH_LEAD before the telegraph begins (the boar's
## cooldown is set to it), so the retry (1.0 s of game time after the death) comes about 0.2 s into the charge. The
## boar starts RETRY_CHARGE_DIST from the spawn: its hit box (60 px reach, 420 px/s) reaches the spawn about 0.25 s
## after the restore, not before. The restore's invulnerability is cleared at once and the player is put on the floor
## (the arena restores it 200 px up, where the charge would pass under it), so only the old boar being disabled stops
## the hit.
func _test_c4_retry_mid_charge() -> void:
	print("[C4 the player dies while the boar is mid-charge]")
	var gm := _gm()
	var arena := await _start_arena()
	var old := _boar(arena)
	if old == null:
		_check(false, "C4 the mid-charge retry: no StoryFightBoar in the arena")
		_end_arena(arena)
		await process_frame
		return
	await _wait(0.5)
	var p: CharacterBody2D = arena.player
	var old_id := old.get_instance_id()
	var retries_before: int = arena.story_fight_retries
	var spawn := Vector2(arena._story_cfg["player_spawn"].x, FLOOR_Y)
	await _arm(arena, old, RETRY_CHARGE_DIST, spawn + Vector2(RETRY_CHARGE_DIST, 0.0))
	old.attack_cooldown = DEATH_LEAD
	_hurt_player(arena)
	var attack := _state("ATTACK")
	var begun := false
	var charging_at_retry := false
	var elapsed_at_retry := -1.0
	var end_msec := Time.get_ticks_msec() + 8000
	while Time.get_ticks_msec() < end_msec and arena.story_fight_retries == retries_before:
		await physics_frame
		# the last state before the retry disables it (DEAD): a read after the retry must not overwrite it
		if is_instance_valid(old) and old.current_state != _state("DEAD"):
			if old.current_state == _state("CHASE"):
				_reapply_dda()   # the death moved the DDA score; the telegraph must be read under the pin
			begun = begun or old.current_state == _state("TELEGRAPH")
			charging_at_retry = old.current_state == attack
			elapsed_at_retry = old._charge_elapsed
	p.invulnerable = false
	p.invuln_timer = 0.0
	p.global_position = spawn
	p.velocity = Vector2.ZERO
	var gap: float = absf(old.global_position.x - p.global_position.x) if is_instance_valid(old) else -1.0
	var fresh = arena._story_enemy   # the arena's own reference: by name it could be the old boar
	_freeze(fresh)                    # only the old charge is on trial now
	_check(begun and charging_at_retry and gap > _charge_reach(_consts()),
		"C4 the old boar was mid-charge (ATTACK) when the retry ran, its hit box short of the spawn"
			+ " (telegraphed %s, charging %s, %.2f s into the charge, %.0f px away)"
			% [str(begun), str(charging_at_retry), elapsed_at_retry, gap])
	await process_frame
	_check(arena.story_fight_retries == retries_before + 1 and fresh != null and fresh.get_instance_id() != old_id
		and not p.is_dead and p.current_health == p.max_health,
		"C4 a new StoryFightBoar instance, the player at full HP, story_fight_retries + 1 (%d)"
			% arena.story_fight_retries)
	var old_valid := is_instance_valid(old)
	_check(old_valid and old.current_state == _state("DEAD") and not old.visible and old.collision_layer == 0,
		"C4 the old, mid-charge boar is disabled (still in the tree %s)" % str(old_valid))
	var lowest: float = p.current_health
	var watched := 0.0   # game seconds
	var watch_cap := Time.get_ticks_msec() + int(RESTORE_WATCH * 4000.0) + 1000   # a cap, should time scale stall
	while watched < RESTORE_WATCH and Time.get_ticks_msec() < watch_cap:
		p.invulnerable = false
		p.invuln_timer = 0.0
		await physics_frame
		watched += _tick() * Engine.time_scale
		lowest = minf(lowest, p.current_health)
	_check(watched + 0.0001 >= RESTORE_WATCH and lowest == p.max_health
		and gm.player_stats.get("hp", 0) == int(p.max_health) and not p.is_dead,
		"C4 the player's HP stays full for 1 s after the restore, invulnerability cleared: the old charge does not hit"
			+ " (lowest HP %s)" % str(lowest))
	_end_arena(arena)
	await process_frame


# ── C3 and C5 (stage B): the village's hand-off and the return ────────────

const VILLAGE := "res://scenes/chapter1/oakhaven_village.tscn"
const MAIN_MENU := "res://scenes/main_menu.tscn"
const META_KEYS := ["story_fight_id", "story_fight_return_scene", "pending_encounter", "boss_fight_id"]
const RETURN_POS := Vector2(1440, 1290)   # NORTH_FIELD_POS (1440, 1380) + (0, -90): where the field puts the player
const HANDOFF_LIMIT := 0.5                # AC-3: the change to the arena within 0.5 s of the choice
const HANDOFF_WAIT := 3.0                 # real seconds C3 waits for a hand-off that is due within 0.5 s
const FIELD_WAIT := 30.0                  # real seconds a village beat (alarm to boar, or the return beat) may take
const SCENE_WAIT := 15.0                  # real seconds a scene change (the arena's win included) may take
const SETTLE_WAIT := 2.5                  # real seconds after a load: the 1.5 s fade-in and a would-be return beat
const QUIET_FRAMES := 60                  # frames watched for a line or a payment that must not come
const KILL_TRIES := 5                     # dizzy-and-hit attempts before the boar counts as not killed
const HOLD := -1                          # a pick that holds the driver at the choice: the test answers it
const FIELD_PICKS := [0, 0, HOLD]         # alarm: "I'm coming with you."; field_water: edit; boar: held
const CHOICE_FIGHT := 0
const CHOICE_CALM := 1
const CHOICE_NEST := 2
const FIELD_GOLD := 100                   # the field's end (ch1_oakhaven_village.gd)
const FIELD_XP := 50                      # before GameManager.add_xp's DDA bonus
const CALM_CORRUPTION := 5.0              # boar_calm's root_edit
const ALARM_FIRST := "The north field! It's split"
const BRIDGE_FIRST := "North bridge is cracked right through"
const STAGED_LINES := ["CORRUPTED BOAR", "It can't turn once it's running", "while it's dizzy", "ELITE DEFEATED"]
const AFTER_LINES := ["It was still trying to get back to the nest", "I know. I saw."]
const BRIDGE_FLAGS := ["ch1_bridge_repair_accepted", "ch1_bridge_evacuated", "ch1_bridge_ignored", "ch1_bridge_saved",
	"ch1_bridge_fell"]
const MARA_BEATS_BEFORE := 2              # ALARM_AFTER_BEATS 3 less one: Mara's first talk is the third beat
const RESUME_FLAGS := ["ch1_north_field_helped", "ch1_sluice_edited", "ch1_boar_fought", FLAG]
const C4_KEPT_HP := 40                    # the player's HP before the C4 win: below full, so a refill would show

var _seen_text: Array[String] = []        # every dialogue line shown while the driver runs ("speaker: text")
var _driving := false
var _drive_gen := 0                       # only the newest _drive loop keeps running
var _picks: Array = []                    # the driver's answers in order (the first option when empty)


## Advances the dialogue a line a frame and answers each choice from _picks (the first option when empty); a HOLD pick
## leaves the choice open for the test to answer. Records each line shown ("speaker: text").
func _drive(gen: int) -> void:
	var dm := get_root().get_node("DialogueManager")
	while _driving and gen == _drive_gen:
		if dm._is_visible and dm._text_label and dm._text_label.text != "":
			var line: String = "%s: %s" % [dm._speaker_label.text, dm._text_label.text]
			if _seen_text.is_empty() or _seen_text.back() != line:
				_seen_text.append(line)
		if dm._awaiting_choice:
			if dm._choice_result == -1 and dm._choice_container != null and not _held():
				dm._on_choice_pressed(_picks.pop_front() if not _picks.is_empty() else 0)
		elif dm._is_visible:
			dm._skip_typing = true
			dm._advance_requested = true
		await process_frame


func _start_driving(picks: Array) -> void:
	_picks = picks.duplicate()
	_driving = true
	_drive_gen += 1   # a loop told to stop this frame must not carry on beside the new one
	_drive(_drive_gen)


func _held() -> bool:
	return not _picks.is_empty() and int(_picks[0]) == HOLD


## True while the driver holds at an open choice.
func _at_held_choice() -> bool:
	var dm := get_root().get_node("DialogueManager")
	return _held() and dm._awaiting_choice and dm._choice_result == -1 and dm._choice_container != null


## Waits for the driver to hold at a choice; true when it did within FIELD_WAIT.
func _wait_held() -> bool:
	return await _wait_until(_at_held_choice, FIELD_WAIT)


## Answers the held choice with `choice`.
func _answer(choice: int) -> void:
	_picks.pop_front()
	get_root().get_node("DialogueManager")._on_choice_pressed(choice)


func _saw(fragment: String) -> bool:
	return _seen_text.any(func(l): return l.contains(fragment))


## Whether a line from index `mark` on contains `fragment`.
func _saw_from(fragment: String, mark: int) -> bool:
	return _seen_text.slice(mark).any(func(l): return l.contains(fragment))


func _scene_is(path: String) -> bool:
	return current_scene != null and current_scene.scene_file_path == path


## The arena is the settled current scene and holds its boar.
func _arena_ready() -> bool:
	return _scene_is(ARENA) and not get_root().get_node("SceneTransitions").is_transitioning \
		and _boar(current_scene) != null


## The village is the settled current scene.
func _village_ready() -> bool:
	return _scene_is(VILLAGE) and not get_root().get_node("SceneTransitions").is_transitioning


func _gold() -> int:
	return int(_gm().player_stats.get("gold", 0))


func _xp() -> int:
	return int(_gm().player_stats.get("xp", 0))


## GameManager.VILLAGE_AFTERNOON_META, the key of the village's stash, read from its script.
func _stash_key() -> String:
	var gm := _gm()
	var consts: Dictionary = gm.get_script().get_script_constant_map()
	return str(consts.get("VILLAGE_AFTERNOON_META", gm.get("VILLAGE_AFTERNOON_META")))


func _clear_metas() -> void:
	var gm := _gm()
	for k in META_KEYS + [_stash_key()]:
		if gm.has_meta(k):
			gm.remove_meta(k)


## Stops the driver, waits out any scene change and frees the current scene, at 1x with no story meta and no stash
## left: the stage A cases after C3 run with no current scene, as before.
func _leave_scene() -> void:
	_driving = false
	_picks.clear()
	await _wait_scene_settled()
	_clear_metas()
	get_root().get_node("DialogueManager").force_reset()
	if current_scene != null:
		current_scene.queue_free()
	for i in 3:
		await process_frame
	get_root().get_node("ContextStack").clear_time_scale()
	Engine.time_scale = 1.0


## A fresh game under the pins with the afternoon open (ch1_stew_done: no arrival, the triggers live), the driver
## running with `picks`, and the village loaded as the current scene. Returns the scene, or null.
func _load_village(picks: Array, flags: Array = []) -> Node:
	var gm := _gm()
	gm.reset_game()
	get_root().get_node("DialogueManager").force_reset()
	_clear_metas()
	_apply_pins()
	gm.set_story_flag("ch1_stew_done", true)
	for f in flags:
		gm.set_story_flag(f, true)
	_seen_text.clear()
	change_scene_to_file(VILLAGE)
	await _wait_until(func(): return _scene_is(VILLAGE), 5.0)
	_start_driving(picks)
	return current_scene if _scene_is(VILLAGE) else null


## Waits for the held boar choice, answers fight and watches until the arena is the settled current scene. The metas,
## the stash and the return point are read on the frame the change starts; the bridge's state until the arena.
func _watch_fight_handoff(s: Node) -> Dictionary:
	var gm := _gm()
	var st := get_root().get_node("SceneTransitions")
	var r := {"held": false, "handed": false, "elapsed": INF, "id": "", "ret": "", "stash": false,
		"ret_pos": Vector2.INF, "ret_scene": "", "staged": false, "bridge_line": false, "bridge_flag": false,
		"bridge_done": false, "next": "", "transitions": 0}
	r["held"] = await _wait_held()
	var transitions_at_choice := _transitions
	if not r["held"]:
		return r
	_answer(CHOICE_FIGHT)
	var t0 := Time.get_ticks_msec()
	var end := t0 + int(HANDOFF_WAIT * 1000.0)
	while Time.get_ticks_msec() < end:
		if st.is_transitioning:
			r["handed"] = true
			r["elapsed"] = (Time.get_ticks_msec() - t0) / 1000.0
			r["id"] = str(gm.get_meta("story_fight_id", ""))
			r["ret"] = str(gm.get_meta("story_fight_return_scene", ""))
			r["stash"] = gm.has_meta(_stash_key())
			r["ret_pos"] = gm.get_meta("return_position", Vector2.INF)
			r["ret_scene"] = str(gm.get_meta("return_position_scene", ""))
			break
		await process_frame
	r["staged"] = STAGED_LINES.any(_saw)
	var end2 := Time.get_ticks_msec() + int(SCENE_WAIT * 1000.0)
	while Time.get_ticks_msec() < end2 and not (_scene_is(ARENA) and not st.is_transitioning):
		if is_instance_valid(s):
			r["bridge_done"] = r["bridge_done"] or s._bridge_done
		await process_frame
	r["bridge_line"] = _saw(BRIDGE_FIRST)
	r["bridge_flag"] = BRIDGE_FLAGS.any(func(f): return gm.has_flag(f))
	r["next"] = current_scene.scene_file_path if current_scene != null else ""
	r["transitions"] = _transitions - transitions_at_choice
	return r


## The village driven to the boar choice and the fight chosen; returns the arena once it is the settled current scene
## with its boar, or null. Fills `pay` with the gold, XP and DDA bonus read at the choice.
func _village_to_arena(pay: Dictionary) -> Node:
	var s := await _load_village(FIELD_PICKS)
	if s == null:
		return null
	s._on_boar_trigger(s.get_node("Player"))
	var held: bool = await _wait_held()
	if not held:
		return null
	pay["gold"] = _gold()
	pay["xp"] = _xp()
	pay["bonus"] = _gm().get_player_dda_bonus()
	_answer(CHOICE_FIGHT)
	var ok: bool = await _wait_until(_arena_ready, SCENE_WAIT)
	return current_scene if ok else null


## Wins the arena's boar fight as C4 does: dizzy, then damage to 0 (the armour holds outside dizzy).
func _kill_boar(arena: Node) -> bool:
	var b := _boar(arena)
	for i in KILL_TRIES:
		if not is_instance_valid(b) or b.current_health <= 0.0:
			break
		if not b._dizzy:
			b._enter_dizzy()
		b.take_damage(b.max_health)
		for j in 3:
			await process_frame
	return not is_instance_valid(b) or b.current_health <= 0.0


## Leaves the current village (driver stopped, dialogue reset, scene freed), loads slot 1 and, once the village is back
## and settled past its fade-in, walks the player onto the boar trigger. {"loaded", "lines" shown after the load,
## "paid" (gold or XP moved), "resolved" (_field_resolved), "running" (_field_running)}.
func _reload(saved: bool) -> Dictionary:
	var gm := _gm()
	var r := {"loaded": false, "lines": [], "paid": true, "resolved": false, "running": true}
	var gold := _gold()
	var xp := _xp()
	_driving = false
	get_root().get_node("DialogueManager").force_reset()
	if current_scene != null:
		current_scene.queue_free()
	for i in 3:
		await process_frame
	if not saved:
		return r
	_seen_text.clear()
	_start_driving([])
	var loaded: bool = await gm.load_game(1)
	var back := false
	if loaded:
		back = await _wait_until(_village_ready, SCENE_WAIT)
	if not back:
		return r
	var v := current_scene
	await _wait(SETTLE_WAIT)
	if is_instance_valid(v):
		v._on_boar_trigger(v.get_node("Player"))
	for i in QUIET_FRAMES:
		await process_frame
	r["loaded"] = is_instance_valid(v)
	r["lines"] = _seen_text.duplicate()
	r["paid"] = _gold() != gold or _xp() != xp
	if is_instance_valid(v):
		r["resolved"] = v._field_resolved
		r["running"] = v._field_running
	return r


# ── C3 (AC-3): the village hands the fight to the arena ────────────────────

func _test_c3_handoff() -> void:
	print("[C3 the village hands the boar fight to the arena; calm and nest resolve without it]")
	await _c3_fight_case("the boar trigger")
	await _c3_fight_case("the bridge trigger")
	await _c3_other_case(CHOICE_CALM)
	await _c3_other_case(CHOICE_NEST)
	await _c3_mara_third_beat()


## Fight, with the field started from the boar trigger or from the bridge trigger (which awaits the field, then would
## play the bridge): the stash, the return point and both metas at the hand-off, within 0.5 s, no staged line, one
## change to the arena; from the bridge, no bridge line, flag or _bridge_done before the arena.
func _c3_fight_case(how: String) -> void:
	var gm := _gm()
	var s := await _load_village(FIELD_PICKS)
	if s == null:
		_check(false, "C3 %s: the village loads" % how)
		await _leave_scene()
		return
	var player := s.get_node("Player")
	if how == "the bridge trigger":
		s._on_bridge_trigger(player)
	else:
		s._on_boar_trigger(player)
	var r := await _watch_fight_handoff(s)
	_check(r["held"] and r["handed"] and r["id"] == ROW_ID and r["ret"] == VILLAGE,
		"C3 %s: story_fight_id is '%s' and the return meta is the village at the hand-off (held %s; '%s', '%s')"
			% [how, ROW_ID, str(r["held"]), r["id"], r["ret"]])
	_check(r["handed"] and r["stash"] and r["ret_scene"] == VILLAGE and r["ret_pos"] == RETURN_POS,
		"C3 %s: the afternoon is stashed and the return point is the north field %s (stash %s, '%s' %s)"
			% [how, str(RETURN_POS), str(r["stash"]), r["ret_scene"], str(r["ret_pos"])])
	_check(r["handed"] and r["elapsed"] <= HANDOFF_LIMIT,
		"C3 %s: the change to the arena starts within %.1f s of the choice (%.3f s)"
			% [how, HANDOFF_LIMIT, r["elapsed"]])
	_check(r["handed"] and not r["staged"], "C3 %s: no boar_fight_staged line before the hand-off" % how)
	_check(r["next"] == ARENA and r["transitions"] == 1,
		"C3 %s: one scene change, to the arena (next '%s', %d changes)" % [how, r["next"], r["transitions"]])
	_check(r["handed"] and gm.has_flag("ch1_boar_fought") and not gm.has_flag("ch1_corrupted_boar_defeated")
		and not gm.has_flag(FLAG),
		"C3 %s: ch1_boar_fought set; ch1_corrupted_boar_defeated and %s unset before the fight" % [how, FLAG])
	if how == "the bridge trigger":
		_check(r["handed"] and not r["bridge_line"] and not r["bridge_flag"] and not r["bridge_done"],
			"C3 the bridge trigger: no bridge line, no ch1_bridge_* flag, _bridge_done unchanged (%s, %s, %s)"
				% [str(r["bridge_line"]), str(r["bridge_flag"]), str(r["bridge_done"])])
	await _leave_scene()


## Calm or nest: no arena (no story meta, the village stays the scene); the choice's flag, 5 corruption on calm, then
## the field's end once: ch1_corrupted_boar_defeated, gold +100, XP +50 (times the DDA bonus).
func _c3_other_case(choice: int) -> void:
	var gm := _gm()
	var how := "calm" if choice == CHOICE_CALM else "nest"
	var s := await _load_village(FIELD_PICKS)
	if s == null:
		_check(false, "C3 %s: the village loads" % how)
		await _leave_scene()
		return
	s._on_boar_trigger(s.get_node("Player"))
	var held: bool = await _wait_held()
	var gold := _gold()
	var xp := _xp()
	var bonus: float = gm.get_player_dda_bonus()
	var corruption: float = gm.glitch_meter
	var meta_seen := false
	var left := false
	if held:
		_answer(choice)
		var end := Time.get_ticks_msec() + int(FIELD_WAIT * 1000.0)
		while Time.get_ticks_msec() < end and is_instance_valid(s) and (not s._field_resolved or s._field_running):
			meta_seen = meta_seen or gm.has_meta("story_fight_id")
			left = left or current_scene != s
			await process_frame
		for i in QUIET_FRAMES:   # a second payment would land here
			meta_seen = meta_seen or gm.has_meta("story_fight_id")
			left = left or current_scene != s
			await process_frame
	var resolved: bool = held and is_instance_valid(s) and s._field_resolved and not s._field_running
	_check(resolved and not meta_seen and not left,
		"C3 %s: no arena (no story meta, no scene change) and the field resolves in the village (held %s, meta %s)"
			% [how, str(held), str(meta_seen)])
	var flag := "ch1_boar_calmed" if choice == CHOICE_CALM else "ch1_boar_nest_rebuilt"
	_check(gm.has_flag(flag) and not gm.has_flag("ch1_boar_fought") and not gm.has_flag(FLAG),
		"C3 %s: %s set; ch1_boar_fought and %s unset" % [how, flag, FLAG])
	if choice == CHOICE_CALM:
		_check(held and is_equal_approx(gm.glitch_meter - corruption, CALM_CORRUPTION),
			"C3 calm: %.0f corruption added (%s)" % [CALM_CORRUPTION, str(gm.glitch_meter - corruption)])
	var xp_want := int(FIELD_XP * bonus)
	_check(resolved and gm.has_flag("ch1_corrupted_boar_defeated") and _gold() - gold == FIELD_GOLD
		and _xp() - xp == xp_want,
		"C3 %s: the field's end once: ch1_corrupted_boar_defeated, gold +%d, XP +%d (gold +%d, XP +%d)"
			% [how, FIELD_GOLD, xp_want, _gold() - gold, _xp() - xp])
	await _leave_scene()


# ── C5 (AC-5): back from the arena ─────────────────────────────────────────

func _test_c5_resume() -> void:
	print("[C5 back from the boar fight: the return beat once, the reload, the main menu]")
	await _c5_resume_and_reload()
	await _c5_reload_after(CHOICE_CALM)
	await _c5_reload_after(CHOICE_NEST)
	await _c5_resume_without_stash()
	await _c5_main_menu_from_fight()


## The fight won in the arena after the village's own hand-off, the village rebuilt: the player at the north field,
## the triggers held off while the return beat plays, the beat only after the fade-in, its two lines, no alarm, the
## field's end once. Then a save, the bridge answering, and a load: no beat, no payment, the boar trigger inert.
func _c5_resume_and_reload() -> void:
	var gm := _gm()
	var pay := {}
	var arena := await _village_to_arena(pay)
	var won := false
	if arena != null:
		won = await _kill_boar(arena)
	var at_village := false
	if won:
		at_village = await _wait_until(func(): return _scene_is(VILLAGE), SCENE_WAIT)
	var v: Node = current_scene if at_village else null
	var mark := _seen_text.size()
	var arrival_pos := Vector2.INF
	var arrival_running := false
	var quiet := true
	var after_alpha := -1.0
	if v != null:
		var vp := v.get_node("Player") as Node2D
		arrival_pos = vp.global_position
		arrival_running = v._field_running
		v._on_boar_trigger(vp)   # walked onto while the return beat holds the triggers off
		v._on_bridge_trigger(vp)
		var end := Time.get_ticks_msec() + int(FIELD_WAIT * 1000.0)
		while Time.get_ticks_msec() < end and is_instance_valid(v) and (not v._field_resolved or v._field_running):
			quiet = quiet and not v._bridge_running
			if after_alpha < 0.0 and _saw_from(AFTER_LINES[0], mark):
				after_alpha = v.fade_rect.modulate.a if v.fade_rect != null else 0.0
			await process_frame
		for i in QUIET_FRAMES:   # a second payment would land here
			await process_frame
	var resolved: bool = v != null and is_instance_valid(v) and v._field_resolved and not v._field_running
	var xp_want := int(FIELD_XP * float(pay.get("bonus", 1.0)))
	var gold_paid := _gold() - int(pay.get("gold", 0))
	var xp_paid := _xp() - int(pay.get("xp", 0))
	_check(won and at_village, "C5 the boar won in the arena (dizzy, then HP to 0); the scene is the village")
	_check(arrival_pos.is_equal_approx(RETURN_POS) and arrival_running,
		"C5 the player arrives at the north field %s with the field running at once (at %s, running %s)"
			% [str(RETURN_POS), str(arrival_pos), str(arrival_running)])
	_check(v != null and quiet and not _saw_from(BRIDGE_FIRST, mark) and not _saw_from(ALARM_FIRST, mark),
		"C5 the boar and bridge triggers walked onto during the return beat do nothing; no alarm line")
	_check(after_alpha >= 0.0 and after_alpha <= 0.01,
		"C5 the return beat starts only after the fade-in (fade alpha %s at its first line)" % str(after_alpha))
	_check(AFTER_LINES.all(func(f): return _saw_from(f, mark)) and not STAGED_LINES.any(_saw),
		"C5 boar_fight_after's two lines play; no boar_fight_staged line")
	_check(resolved and gm.has_flag("ch1_corrupted_boar_defeated") and gold_paid == FIELD_GOLD and xp_paid == xp_want,
		"C5 the field's end once: ch1_corrupted_boar_defeated, gold +%d, XP +%d, _field_resolved (gold +%d, XP +%d)"
			% [FIELD_GOLD, xp_want, gold_paid, xp_paid])
	var saved := false
	if resolved:
		saved = gm.save_game(1)
	_check(saved, "C5 a save made in the village after the return beat is allowed")
	var bridge_ok := false
	if resolved:
		_picks = [HOLD]   # held at the bridge's choice: nothing leaves the village
		v._on_bridge_trigger(v.get_node("Player"))
		bridge_ok = await _wait_until(func(): return _saw_from(BRIDGE_FIRST, mark), 10.0)
	_check(bridge_ok, "C5 the bridge trigger then answers: north_field bridge plays")
	var r := await _reload(saved)
	_check(r["loaded"] and r["lines"].is_empty() and not r["paid"] and r["resolved"] and not r["running"],
		"C5 a save there and a load: no boar_fight_after, no payment; the boar trigger does nothing (%s)" % str(r))
	await _leave_scene()


## Calm or nest resolved in the village, a save and a load: no field outcome replays or pays, and the boar trigger
## does nothing (D6).
func _c5_reload_after(choice: int) -> void:
	var gm := _gm()
	var how := "calm" if choice == CHOICE_CALM else "nest"
	var s := await _load_village(FIELD_PICKS)
	var resolved := false
	if s != null:
		s._on_boar_trigger(s.get_node("Player"))
		var held: bool = await _wait_held()
		if held:
			_answer(choice)
			var end := Time.get_ticks_msec() + int(FIELD_WAIT * 1000.0)
			while Time.get_ticks_msec() < end and is_instance_valid(s) and not resolved:
				resolved = s._field_resolved and not s._field_running
				await process_frame
	var saved := false
	if resolved:
		saved = gm.save_game(1)
	var r := await _reload(saved)
	_check(saved and r["loaded"] and r["lines"].is_empty() and not r["paid"] and r["resolved"] and not r["running"],
		"C5 after %s, a save and a load: no field line, no payment; the boar trigger does nothing (saved %s, %s)"
			% [how, str(saved), str(r)])
	await _leave_scene()


## Pause -> main menu during the boar fight (reached through the village's hand-off): the pause menu's "Yes, Leave"
## reaches the main menu, and no story meta, no stash and no ch1_boar_fight_won are left.
func _c5_main_menu_from_fight() -> void:
	var gm := _gm()
	var st := get_root().get_node("SceneTransitions")
	var arena := await _village_to_arena({})
	var had_boar := arena != null
	var stash_before := gm.has_meta(_stash_key())
	var paused := false
	var found_yes := false
	var at_menu := false
	if had_boar:
		_freeze(_boar(arena))
		var ps := get_root().get_node("PauseScreen")
		ps.toggle_pause()
		paused = ps.is_paused
		ps._return_to_main_menu()
		var yes: Button = null
		if ps._confirm_menu_panel != null:
			for b in ps._confirm_menu_panel.find_children("*", "Button", true, false):
				if b is Button and (b as Button).text.contains("Yes, Leave"):
					yes = b as Button
		found_yes = yes != null   # read now: the button is freed with its panel once pressed
		if found_yes:
			yes.pressed.emit()
		at_menu = await _wait_until(func(): return _scene_is(MAIN_MENU) and not st.is_transitioning, 8.0)
	_check(had_boar and stash_before and paused and found_yes and at_menu,
		"C5 pause -> main menu from the boar fight reaches the menu (boar %s, stash %s, paused %s, yes %s, menu %s)"
			% [str(had_boar), str(stash_before), str(paused), str(found_yes), str(at_menu)])
	_check(not gm.has_meta("story_fight_id") and not gm.has_meta("story_fight_return_scene")
		and not gm.has_meta(_stash_key()) and not gm.has_flag(FLAG),
		"C5 leaving the fight by the main menu leaves no story meta, no stash and %s unset" % FLAG)
	await _leave_scene()


## R1: Mara's first talk as the third afternoon beat brings the alarm; on "Fight it." the field hands off, and her
## shop must not open over the hand-off (ShopSystem pauses the tree, which would hold the arena behind it).
func _c3_mara_third_beat() -> void:
	var s := await _load_village(FIELD_PICKS)
	if s == null:
		_check(false, "C3 Mara as the third beat: the village loads")
		await _leave_scene()
		return
	s._afternoon_beats = MARA_BEATS_BEFORE
	s._on_apothecary_interaction(s.get_node("Player"))
	var held: bool = await _wait_held()
	var arrived := false
	if held:
		_answer(CHOICE_FIGHT)
		arrived = await _wait_until(_arena_ready, SCENE_WAIT)
	var shop := get_root().get_node("ShopSystem")
	var shop_open: bool = shop._is_open
	var was_paused := paused
	_check(held and arrived and not shop_open and not was_paused,
		"C3 Mara as the third beat, fight: arena reached, shop shut, tree not paused (arena %s, shop %s, paused %s)"
			% [str(arrived), str(shop_open), str(was_paused)])
	if shop_open:
		shop.close_shop()
	paused = false
	await _leave_scene()


## A return with no stash (the flags alone decide the resume, AC-5): after the return beat the field is resolved and
## _alarm_done is true, so the alarm cannot re-arm.
func _c5_resume_without_stash() -> void:
	var s := await _load_village([], RESUME_FLAGS)
	var done := false
	var end := Time.get_ticks_msec() + int(FIELD_WAIT * 1000.0)
	while s != null and Time.get_ticks_msec() < end and is_instance_valid(s) and not done:
		done = s._field_resolved and not s._field_running
		await process_frame
	var alarm_done: bool = done and is_instance_valid(s) and s._alarm_done
	_check(done and alarm_done,
		"C5 a return with no stash: after the return beat the field is resolved and _alarm_done is true (%s, %s)"
			% [str(done), str(alarm_done)])
	await _leave_scene()
