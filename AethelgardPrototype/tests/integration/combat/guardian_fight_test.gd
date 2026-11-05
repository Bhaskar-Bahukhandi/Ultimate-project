extends SceneTree
## Y1-P0-T13b: the Broken Mile guardian is a real side-scroll fight.
##   C1  AC-1  the guardian alone: its declared values, the attack chosen by distance (never a roll), the charge
##             telegraphed from range, telegraph times and damage under the pins, one attack then RECOVER, both
##             attacks parried, no contact damage
##   C2  AC-2  the STORY_FIGHTS row
##   C3  AC-3  the Broken Mile's hand-off: the Fight button, the give-up and the no-panel fallback each start the
##             arena within 0.5 s, the staged guardian still visible; filter and calm resolve without it, as before
##   C4  AC-4  the fight in the arena: the win (shards, flag once, nothing else given, one scene change) and the
##             retry, also while the guardian is mid-charge
##   C5  AC-5  the Broken Mile loaded with ch1_guardian_fought resumes at root_refused, also after a save and a
##             load at rest_stop; pause -> main menu from the fight leaves no story meta and the flag unset
## C3 and C5 load the real Broken Mile as the current scene and drive its dialogue a line a frame (first option at
## every choice). The walk to the panel runs at WALK_TIME_SCALE; the choice and the hand-off are timed at 1x, in
## real time. The C3 drivers are the notes': _on_root_access_refused() for the Fight button, root_panel_timeout
## lowered for the give-up, apply_button nulled after _ready for the no-panel fallback.
## Pins (AC-6): every runtime number in AC-1 is checked under _apply_pins, applied before the guardian spawns
## (its HP is scaled in _ready); the DDA score is re-applied before each attack. The pins are written to the
## fields directly, never through set_difficulty / set_accessibility (both save user://game_settings.cfg),
## snapshotted first and restored after the suite.
## The scene changes go to a stub scene (tests/fixtures/story_fight_return_stub.tscn), as in story_fight_test.
## The arena is added as a plain child of the root, so it stays alive after a scene change.
## Test-side isolation costs, named: the guardian is driven through take_damage and direct state writes
## (current_state, attack_cooldown) between attacks; _stun_active, telegraph_timer, _player_in_attack_range and the
## arena's _story_cfg are read; PlayerCombat is driven through take_damage / _start_parry / die.
## Run: tests/run_phase0_tests.ps1 -Script res://tests/integration/combat/guardian_fight_test.gd

const ARENA := "res://scenes/combat/combat_arena.tscn"
const ARENA_SCRIPT := "res://scripts/combat/combat_arena.gd"
const STUB := "res://tests/fixtures/story_fight_return_stub.tscn"
const GUARDIAN_SCRIPT := "res://scripts/combat/enemies/broken_mile_guardian.gd"
const BIBLE := "res://story/STORY_BIBLE.md"
const ROW_ID := "ch1_guardian"
const FLAG := "ch1_guardian_fought"
const SHARD_COLOR := Color(0.32, 0.26, 0.2)
const FLOOR_Y := 600.0                    # the arena floor: bodies' feet rest at this y
const GUARDIAN_POS := Vector2(760, FLOOR_Y)   # the row's enemy_spawn x, on the floor (the spawn's y 400 is in the air)
const PIN_DDA_SCORE := 52.5               # remap(52.5, 20, 85, 0.75, 1.25) = 1.0
const STOMP_DIST := 50.0                  # inside STOMP_RANGE (70)
const CHARGE_DIST := 200.0                # between STOMP_RANGE and CHARGE_RANGE (360)
const REPEATS := 5
const PARRY_LEAD := 0.1                   # the parry starts this long before the hit (its window is 0.18 s)
const STAGGER_TIME := 1.2                 # PlayerCombat._on_successful_parry: enemy.stagger(1.2)
const SETTLE_FRAMES := 3                  # physics frames _arm holds the pair in place after a teleport
const PLAYER_HIT := 15.0                  # one player hit (player_combat.gd:171), for the poise checks (D9)
const RETRY_CHARGE_DIST := 332.0          # mid-charge retry: the old charge reaches the spawn after the restore
const DEATH_LEAD := 0.2                   # mid-charge retry: the player dies this long (game time) before the telegraph
const SCALED_DDA_SCORE := 85.0            # R3: remap(85, 20, 85, 0.75, 1.25) = 1.25
const SCALED_ZONE_LEVEL := 3              # R3: two levels above the pinned player level 1, damage multiplier 1.5
const STEADY_HIT_GAP := 0.9               # R1: game seconds between player hits while the guardian walks in
const STEADY_START_DIST := 410.0          # R1: inside DETECTION_RANGE (420), beyond CHARGE_RANGE (360)
const STEADY_HOLD := 2.0                  # R1: game seconds the player keeps its distance before letting it walk in
const STEADY_WATCH := 5.0                 # R1: game seconds the whole case is watched for a telegraph
const SLIDE_WATCH := 0.5                  # game seconds of RECOVER watched for a slide (RECOVER_TIME is 0.8)
const LAST_TICK_TIMEOUT := 0.05           # R2: root_panel_timeout for the give-up's last-tick case
const KILL_WATCH := 1.0                   # game seconds the player is watched after the guardian is killed mid-attack
const PATH := "res://scenes/chapter1/path_to_oakhaven.tscn"
const VILLAGE := "res://scenes/chapter1/oakhaven_village.tscn"
const MAIN_MENU := "res://scenes/main_menu.tscn"
const META_KEYS := ["story_fight_id", "story_fight_return_scene", "pending_encounter", "boss_fight_id"]
const HANDOFF_LIMIT := 0.5                # AC-3: the hand-off within 0.5 s of the choice
const PANEL_POLL := 0.1                   # the panel's wait loop polls every 0.1 s (ch1_path_to_oakhaven.gd)
const TEST_PANEL_TIMEOUT := 0.5           # root_panel_timeout, lowered for the give-up case
const WALK_TIME_SCALE := 4.0              # the Broken Mile's walk-and-talk runs at 4x; the choice at 1x
const HANDOFF_WAIT := 3.0                 # real seconds C3 waits for a hand-off that is due within 0.5 s
const MILE_WAIT := 60.0                   # real seconds one run of the Broken Mile may take to reach a line
const DIRECTIVE_LAST := "it's coming back"   # guardian_directive's last line, right before root_access_open
const REFUSED_FIRST := "I could've changed it"   # root_refused's first line
const FILTER_LINE := "Changed what it thinks it's defending against"   # root_used
const CALM_LINE := "Turned it down"       # root_used_calm
const REST_FIRST := "You keep taking that scrap out"   # rest_stop's first line
const NOT_EDITED := "you looked at that beast like you could read it"   # rest_stop without ch1_root_first_edit
const EDITED := "you changed a Fracture directive"     # rest_stop with ch1_root_first_edit
const RIDGE_FIRST := "There. Oakhaven."
## One line from each node between the walk-in and the panel (tree_flicker to guardian_directive).
const WALK_IN_LINES := ["Did you see that? The tree", "If somebody else came out of that crater",
	"She's hiding a wince", "metadata", "Is there another way around it?", "DIRECTIVE: DEFEND NEST"]
## The flags a save made after the hand-off holds (set before it by broken_mile.dlg), plus the fight's own.
const RESUME_FLAGS := ["ch1_broken_mile_entered", "ch1_data_vision_unlocked", "root_access_unlocked", FLAG]

var _passes := 0
var _failures: Array[String] = []
var _transitions := 0
var _outcomes: Array = []
var _pin_snapshot: Dictionary = {}
var _dda_pin := PIN_DDA_SCORE             # the DDA score _reapply_dda writes (SCALED_DDA_SCORE for the R3 runs)
var _seen_text: Array[String] = []      # every dialogue line shown while the driver runs ("speaker: text")
var _driving := false
var _drive_gen := 0                       # only the newest _drive loop keeps running
var _hold_at := ""                        # the driver stops advancing while a line containing this is shown


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
	await _test_c1_guardian()
	await _test_c2_row()
	await _test_c3_handoff()
	await _test_c4_win()
	await _test_c4_retry()
	await _test_c4_retry_mid_charge()
	await _test_c4_kill_mid_attack("TELEGRAPH")
	await _test_c4_kill_mid_attack("ATTACK")
	await _test_c5_resume()
	_restore_pins()
	_finish()


func _finish() -> void:
	print("")
	print("GUARDIAN FIGHT RESULT: %d passed, %d failed" % [_passes, _failures.size()])
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


## The guardian script, or null before it exists (its checks then fail by name instead of aborting the suite).
func _guardian_script() -> Script:
	return load(GUARDIAN_SCRIPT) if ResourceLoader.exists(GUARDIAN_SCRIPT) else null


func _guardian_consts() -> Dictionary:
	var script := _guardian_script()
	return script.get_script_constant_map() if script else {}


## How far the charge's hit box reaches from the guardian's centre (|offset.x| + width / 2); INF without the constants.
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


func _guardian(arena: Node) -> Node:
	return arena.get_node_or_null("Enemies/StoryFightGuardian")


func _freeze(enemy: Node) -> void:
	if is_instance_valid(enemy):
		enemy.set_physics_process(false)
		enemy.set_process(false)


func _hurt_player(arena: Node, amount: float = 9999.0) -> void:
	arena.player.take_damage(amount, Vector2.ZERO, "Test", "melee")


func _shards(arena: Node) -> Array:
	return arena.get_children().filter(func(n): return n.name.begins_with("StoryFightShard"))


# ── the pins (AC-6) ───────────────────────────────────────────────────────

## Snapshots every field _apply_pins writes. Called once, before the first pin.
func _snapshot_pins() -> void:
	var gm := _gm()
	var stats: Dictionary = gm.player_stats
	_pin_snapshot = {
		"dda": gm._dda_performance_score,
		"difficulty": gm.selected_difficulty,
		"level": stats.get("level", 1),
		"defense": stats.get("defense", 0),
		"ng_plus": gm.ng_plus_cycle,
		"buffs": get_root().get_node("ChoiceConsequences").active_buffs.duplicate(true),
		"invincibility_present": gm.accessibility_settings.has("invincibility_mode"),
		"invincibility": gm.accessibility_settings.get("invincibility_mode", false),
	}


## The pins behind AC-1's numbers: player level 1, DDA score 52.5 (multiplier 1.0), difficulty NORMAL, player
## defense 0, NG+ cycle 0, enemy-weakness buffs cleared, invincibility off. Fields are written directly:
## set_difficulty and set_accessibility save user://game_settings.cfg. Applied before the guardian spawns.
func _apply_pins() -> void:
	var gm := _gm()
	gm.player_stats["level"] = 1
	gm.player_stats["defense"] = 0
	gm.selected_difficulty = gm.Difficulty.NORMAL
	gm.ng_plus_cycle = 0
	get_root().get_node("ChoiceConsequences").active_buffs.clear()
	gm.accessibility_settings["invincibility_mode"] = false
	_reapply_dda()


## The DDA score drifts with every hit the player takes, so it is written again before each attack.
func _reapply_dda() -> void:
	_gm()._dda_performance_score = _dda_pin


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


## Puts the guardian at `pos` in CHASE with no cooldown and the player `dist` px to its left, at full HP.
## It first waits out any hit-stop (CombatFX scales time down after a hit, which would stretch a telegraph over
## more physics frames) and holds both in place for SETTLE_FRAMES with the cooldown up, so the guardian's
## Area2D flags (_player_in_attack_range) catch up with the teleport before an attack can start.
func _arm(arena: Node, g: Node, dist: float, pos: Vector2 = GUARDIAN_POS) -> void:
	var clean := await _wait_until(func(): return is_equal_approx(Engine.time_scale, 1.0), 2.0)
	if not clean:
		_check(false, "setup: Engine.time_scale did not return to 1.0 within 2 s before an attack (%s); the next"
			% str(Engine.time_scale) + " telegraph's frame count would be stretched")
	for i in SETTLE_FRAMES:
		g.attack_cooldown = 999.0
		g.velocity = Vector2.ZERO
		g.global_position = pos
		arena.player.velocity = Vector2.ZERO
		arena.player.global_position = pos - Vector2(dist, 0.0)
		await physics_frame
	_heal_player(arena)
	_reapply_dda()
	g.velocity = Vector2.ZERO
	g.global_position = pos
	if g._stun_active:
		_check(false, "setup: the guardian was still stunned when the next attack was armed")
	g._stun_active = false
	g._hitstun_frozen = false
	g.recover_timer = 0.0
	g.attack_cooldown = 0.0
	g.current_state = _state("CHASE")
	arena.player.global_position = pos - Vector2(dist, 0.0)


## One attack from _arm, watched a physics frame at a time until the guardian is in RECOVER (or 4 s pass).
## `parry` is "" (none), "stomp" or "charge": the player parries at the notes' moment (AC-6 drivers).
## `hit` > 0: the guardian takes that much damage on the telegraph's first frame (the poise check, D9).
## Returns the first attack type seen in TELEGRAPH, the frames and the game time spent there, telegraph_duration,
## whether the player was inside attack_range when it began, the states seen in order, the player's HP drop, the
## guardian's HP after the hit and whether it reached RECOVER.
func _run_attack(arena: Node, g: Node, dist: float, parry: String = "", hit: float = 0.0) -> Dictionary:
	var p: CharacterBody2D = arena.player
	await _arm(arena, g, dist)
	var hp_start: float = p.current_health
	var tele := _state("TELEGRAPH")
	var attack := _state("ATTACK")
	var recover := _state("RECOVER")
	var chase := _state("CHASE")
	var consts := _guardian_consts()
	var reach: float = _charge_reach(consts)
	var speed: float = consts.get("CHARGE_SPEED", 500.0)
	var r := {"attack": -1, "frames": 0, "duration": 0.0, "in_attack_range": true, "start_dist": 0.0, "states": [],
		"hp_drop": 0.0, "recovered": false, "parry_frame": -1, "hit_frame": -1, "parry_dx": 0.0, "game_time": 0.0,
		"guardian_hp": -1.0, "launch_x": NAN, "recover_x": NAN}
	var tick := 1.0 / float(Engine.physics_ticks_per_second)
	var frame := 0
	var last := -1
	var parried := false
	var end_msec := Time.get_ticks_msec() + 4000
	while Time.get_ticks_msec() < end_msec:
		await physics_frame
		frame += 1
		if r["hit_frame"] < 0 and (p.current_health < hp_start or g._stun_active):
			r["hit_frame"] = frame
		var st: int = g.current_state
		if st == chase:
			_reapply_dda()
		if st == tele:
			if r["frames"] == 0:
				r["attack"] = g.current_attack
				r["in_attack_range"] = g._player_in_attack_range
				r["start_dist"] = g.global_position.distance_to(p.global_position)
				if hit > 0.0:
					g.take_damage(hit, p.global_position)
					r["guardian_hp"] = g.current_health
			r["frames"] += 1
			r["game_time"] += tick * Engine.time_scale
			r["launch_x"] = g.global_position.x   # the last TELEGRAPH frame: where the charge starts from
			r["duration"] = g.telegraph_duration
			# the stomp hits when the telegraph ends: parry PARRY_LEAD before that
			if parry == "stomp" and not parried and g.telegraph_timer >= g.telegraph_duration - PARRY_LEAD:
				p._start_parry()
				parried = true
				r["parry_frame"] = frame
		# the charge hits after travelling, once the player is PARRY_LEAD of travel from its hit box's far edge
		if parry == "charge" and not parried and st == attack \
				and absf(p.global_position.x - g.global_position.x) - reach <= speed * PARRY_LEAD:
			p._start_parry()
			parried = true
			r["parry_frame"] = frame
			r["parry_dx"] = absf(p.global_position.x - g.global_position.x)
		if st != last:
			r["states"].append(st)
			last = st
		if st == recover:
			r["recovered"] = true
			r["recover_x"] = g.global_position.x
			break
	r["hp_drop"] = hp_start - p.current_health
	return r


## Watches the guardian for `seconds` of game time, a physics frame at a time (the DDA pin held): did it start a
## telegraph or an attack, was it stunned on every frame, and was it in STUNNED on any.
func _watch_quiet(g: Node, seconds: float) -> Dictionary:
	var tele := _state("TELEGRAPH")
	var attack := _state("ATTACK")
	var tick := 1.0 / float(Engine.physics_ticks_per_second)
	var out := {"acted": false, "stunned_throughout": true, "stunned_any": false}
	var game := 0.0
	var end_msec := Time.get_ticks_msec() + int(seconds * 4000.0) + 1000   # a cap, should time scale stall
	# Stop within half a frame of `seconds`: summed frame times drift by float error, and one frame too many would
	# watch the very frame an attack is due.
	while game + tick * 0.5 < seconds and Time.get_ticks_msec() < end_msec:
		_reapply_dda()
		await physics_frame
		game += tick * Engine.time_scale
		if g.current_state == tele or g.current_state == attack:
			out["acted"] = true
		if not g._stun_active:
			out["stunned_throughout"] = false
		out["stunned_any"] = out["stunned_any"] or g.current_state == _state("STUNNED")
	return out


# ── C1 (AC-1): the guardian alone ─────────────────────────────────────────

func _test_c1_guardian() -> void:
	print("[C1 the guardian: values, choice by distance, telegraphs, damage, recover, parry, contact]")
	_c1_constants()
	var arena := await _start_arena()
	var g := _guardian(arena)
	_check(g != null and g.get_script().resource_path == GUARDIAN_SCRIPT,
		"C1 the arena spawns one StoryFightGuardian running broken_mile_guardian.gd")
	if g == null:
		_end_arena(arena)
		await process_frame
		return
	await _wait(0.5)   # past the spawn-in tween (0.3 s)
	_c1_instance_values(g)
	await _c1_choice_and_damage(arena, g)
	await _c1_recover(arena, g)
	await _c1_charge_stop(arena, g)
	await _c1_poise(arena, g)
	await _c1_steady_hits(arena, g)
	await _c1_scaled(arena, g)
	await _c1_parry(arena, g)
	await _c1_no_contact_damage(arena, g)
	_end_arena(arena)
	await process_frame


## AC-1's declared values as plain constants of the script.
func _c1_constants() -> void:
	var c := _guardian_consts()
	var expected := {"GUARDIAN_MAX_HEALTH": 60.0, "STOMP_RANGE": 70.0, "CHARGE_RANGE": 360.0,
		"STOMP_TELEGRAPH": 0.45, "CHARGE_TELEGRAPH": 0.6, "STOMP_DAMAGE": 12.0, "CHARGE_DAMAGE": 14.0}
	for key in expected:
		_check(c.has(key) and is_equal_approx(float(c[key]), expected[key]),
			"C1 constant %s is %s (found %s)" % [key, str(expected[key]), str(c.get(key, "<missing>"))])
	var stomp_box: Vector2 = c.get("STOMP_HITBOX_SIZE", Vector2.ZERO)
	_check(c.has("STOMP_RANGE") and stomp_box.x > 2.0 * float(c["STOMP_RANGE"]),
		"C1 the stomp's hit box is wider than 2 x STOMP_RANGE, so a stomp started at the range edge can land (%s)"
			% str(stomp_box))
	var reach: float = _charge_reach(c)
	_check(reach <= 110.0,
		"C1 the charge's hit box reaches at most 110 px from the centre, so a parried charge staggers it (D8; %s px)"
			% str(reach))
	var travel: float = float(c.get("CHARGE_SPEED", 0.0)) * float(c.get("CHARGE_TRAVEL_TIME", 0.0))
	_check(travel >= 200.0, "C1 the charge covers at least 200 px (speed x travel time = %s px)" % str(travel))
	_check(c.has("CHARGE_RANGE") and c.has("DETECTION_RANGE")
		and float(c["CHARGE_RANGE"]) <= float(c["DETECTION_RANGE"]),
		"C1 CHARGE_RANGE is within the detection range")


## The spawned guardian's runtime values under the pins: HP 60 (level scaling included), attack_range 70, no contact
## damage.
func _c1_instance_values(g: Node) -> void:
	_check(g.enemy_name == "Mosswood Guardian", "C1 enemy_name is 'Mosswood Guardian' (found '%s')" % g.enemy_name)
	_check(is_equal_approx(g.max_health, 60.0) and is_equal_approx(g.current_health, 60.0) and g.zone_level == 0,
		"C1 max_health is 60 under the pins, zone_level 0 (found %s)" % str(g.max_health))
	_check(is_equal_approx(g.attack_range, 70.0),
		"C1 attack_range is 70 = STOMP_RANGE (found %s)" % str(g.attack_range))
	_check(g.contact_damage == 0.0, "C1 contact_damage is 0 (found %s)" % str(g.contact_damage))
	_check(g.max_combo == 1,
		"C1 max_combo is 1, so EnemyBase's random combo branch never runs (found %d)" % g.max_combo)
	_check(g.detection_range >= float(_guardian_consts().get("CHARGE_RANGE", INF)),
		"C1 detection_range (%s) reaches CHARGE_RANGE" % str(g.detection_range))


## The attack chosen by distance on REPEATS runs each, the charge started from range, telegraph times and damage.
func _c1_choice_and_damage(arena: Node, g: Node) -> void:
	var slam := _base_enum("AttackType", "SLAM")
	var charge := _base_enum("AttackType", "CHARGE")
	var attack := _state("ATTACK")
	var stomps: Array = []
	var charges: Array = []
	for i in REPEATS:
		stomps.append(await _run_attack(arena, g, STOMP_DIST))
	for i in REPEATS:
		charges.append(await _run_attack(arena, g, CHARGE_DIST))
	_check(stomps.all(func(r): return r["attack"] == slam),
		"C1 the player at 50 px: telegraph then SLAM, on all %d repeats (%s)"
			% [REPEATS, str(stomps.map(func(r): return r["attack"]))])
	_check(charges.all(func(r): return r["attack"] == charge),
		"C1 the player at 200 px: telegraph then CHARGE, on all %d repeats (%s)"
			% [REPEATS, str(charges.map(func(r): return r["attack"]))])
	var from_range := func(r): return not r["in_attack_range"] and r["start_dist"] > g.attack_range and r["frames"] > 0
	_check(charges.all(from_range),
		("C1 the charge is telegraphed from range: the player outside attack_range when it began"
			+ " (physics frames, no direct _begin_telegraph; %s px)")
			% str(charges.map(func(r): return snappedf(r["start_dist"], 0.1))))
	var frame := 1.0 / float(Engine.physics_ticks_per_second)
	var s: Dictionary = stomps[0]
	var c: Dictionary = charges[0]
	_check(absf(s["frames"] * frame - 0.45) <= frame + 0.0001 and is_equal_approx(s["duration"], 0.45),
		"C1 the stomp's telegraph is 0.45 s, +- one frame (duration %s, %d frames)" % [str(s["duration"]), s["frames"]])
	_check(absf(c["frames"] * frame - 0.6) <= frame + 0.0001 and is_equal_approx(c["duration"], 0.6),
		"C1 the charge's telegraph is 0.6 s, +- one frame (duration %s, %d frames)" % [str(c["duration"]), c["frames"]])
	_check(stomps.all(func(r): return is_equal_approx(r["hp_drop"], 12.0)),
		"C1 the stomp takes exactly 12 HP from the player (%s)" % str(stomps.map(func(r): return r["hp_drop"])))
	_check(charges.all(func(r): return is_equal_approx(r["hp_drop"], 14.0)),
		"C1 the charge takes exactly 14 HP from the player (%s)" % str(charges.map(func(r): return r["hp_drop"])))
	_check(charges.all(func(r): return r["states"].has(attack))
		and stomps.all(func(r): return not r["states"].has(attack)),
		"C1 the charge runs in ATTACK after its telegraph; the stomp lands straight from the telegraph")


## After one attack the state is RECOVER, and no second attack starts before RECOVER_TIME + ATTACK_COOLDOWN (game
## time, under the DDA pin), watched to one frame short of it.
func _c1_recover(arena: Node, g: Node) -> void:
	var recover := _state("RECOVER")
	var c := _guardian_consts()
	var tick := 1.0 / float(Engine.physics_ticks_per_second)
	var quiet_for: float = float(c.get("RECOVER_TIME", 0.0)) + float(c.get("ATTACK_COOLDOWN", 0.0)) - tick
	for dist in [STOMP_DIST, CHARGE_DIST]:
		var r: Dictionary = await _run_attack(arena, g, dist)
		var in_recover: bool = r["recovered"] and g.current_state == recover
		var hp: float = arena.player.current_health
		var quiet: Dictionary = await _watch_quiet(g, quiet_for)
		_check(in_recover and not quiet["acted"] and arena.player.current_health == hp,
			"C1 after the attack at %d px the state is RECOVER and no second attack starts within %.3f s (acted %s)"
				% [int(dist), quiet_for, str(quiet["acted"])])


## The charge stops dead at its travel end: it covers CHARGE_SPEED x CHARGE_TRAVEL_TIME (+- one frame) from where
## it launched, and RECOVER adds no slide (SLIDE_WATCH s of game time, x within 1 px).
func _c1_charge_stop(arena: Node, g: Node) -> void:
	var c := _guardian_consts()
	var speed := float(c.get("CHARGE_SPEED", 0.0))
	var expected := speed * float(c.get("CHARGE_TRAVEL_TIME", 0.0))
	var one_frame := speed / float(Engine.physics_ticks_per_second)
	var r: Dictionary = await _run_attack(arena, g, CHARGE_DIST)
	var travel: float = absf(r["recover_x"] - r["launch_x"])
	_check(r["recovered"] and absf(travel - expected) <= one_frame + 0.01,
		"C1 the charge travels CHARGE_SPEED x CHARGE_TRAVEL_TIME = %.0f px, +- one frame (%.1f px)"
			% [expected, travel])
	await _watch_quiet(g, SLIDE_WATCH)
	var slide: float = absf(g.global_position.x - r["recover_x"])
	_check(r["recovered"] and slide <= 1.0 and g.current_state == _state("RECOVER"),
		"C1 RECOVER after the charge adds no slide (%.1f px in %.1f s)" % [slide, SLIDE_WATCH])


## Poise (D9). A player hit during the telegraph takes the guardian's HP but leaves the telegraph running: the stomp
## lands on time. A hit during RECOVER stuns it lightly, and no telegraph starts before its cooldown. The guardian's
## dodge chance is 0, so every hit takes the hit-stun path.
func _c1_poise(arena: Node, g: Node) -> void:
	_check(g.dodge_chance == 0.0, "C1 dodge_chance is 0: no random dodge on a hit (D9; found %s)" % str(g.dodge_chance))
	var stunned := _state("STUNNED")
	var recover := _state("RECOVER")
	var tick := 1.0 / float(Engine.physics_ticks_per_second)
	g.current_health = g.max_health
	var r: Dictionary = await _run_attack(arena, g, STOMP_DIST, "", PLAYER_HIT)
	_check(r["recovered"] and not r["states"].has(stunned)
		and is_equal_approx(r["guardian_hp"], g.max_health - PLAYER_HIT),
		"C1 a hit during the telegraph takes %s HP (guardian at %s) and does not stun it (states %s)"
			% [str(PLAYER_HIT), str(r["guardian_hp"]), str(r["states"])])
	_check(absf(r["game_time"] - 0.45) <= tick + 0.0001 and is_equal_approx(r["hp_drop"], 12.0),
		"C1 after a hit during its telegraph the stomp still lands on time: 0.45 s +- one frame, 12 HP (%.3f s, %s HP)"
			% [r["game_time"], str(r["hp_drop"])])
	g.current_health = g.max_health
	var r2: Dictionary = await _run_attack(arena, g, STOMP_DIST)
	var hp_before: float = g.current_health
	var in_recover: bool = r2["recovered"] and g.current_state == recover
	g.take_damage(PLAYER_HIT, arena.player.global_position)
	var quiet: Dictionary = await _watch_quiet(g, float(_guardian_consts().get("ATTACK_COOLDOWN", 1.0)) * 0.9)
	var saw_stun: bool = quiet["stunned_any"]
	var acted: bool = quiet["acted"]
	_check(in_recover and saw_stun and g.current_health < hp_before,
		"C1 a hit during RECOVER takes HP and stuns it (in RECOVER %s, stunned %s, HP %s of %s)"
			% [str(in_recover), str(saw_stun), str(g.current_health), str(hp_before)])
	_check(not acted, "C1 after a hit during RECOVER no telegraph starts within 0.9 x its cooldown (D9)")
	g.current_health = g.max_health


## R1: hits in CHASE do not raise the cooldown. The guardian is hit every STEADY_HIT_GAP s, each hit stunning it
## briefly. For the first STEADY_HOLD s the player keeps STEADY_START_DIST away (seen, out of charge range), so
## several hits land in CHASE; then it lets the guardian walk in. It still starts a telegraph once within
## CHARGE_RANGE. Raising the cooldown after every stun (EnemyBase does not tick it during one) kept it from ever
## telegraphing. Its HP is topped up before each hit so the hits never kill it.
func _c1_steady_hits(arena: Node, g: Node) -> void:
	var p: CharacterBody2D = arena.player
	var tele := _state("TELEGRAPH")
	var stunned := _state("STUNNED")
	await _arm(arena, g, STEADY_START_DIST)
	var tick := 1.0 / float(Engine.physics_ticks_per_second)
	var hits := 0
	var saw_stun := false
	var began := false
	var game := 0.0          # game time since the arm, summed a physics frame at a time as _watch_quiet does
	var next_hit := 0.0
	var cap_msec := Time.get_ticks_msec() + int(STEADY_WATCH * 4000.0)   # a cap, should time scale stall
	while game < STEADY_WATCH and Time.get_ticks_msec() < cap_msec and not began:
		if game < STEADY_HOLD:
			p.global_position.x = g.global_position.x - STEADY_START_DIST
		if game >= next_hit:
			g.current_health = g.max_health
			g.take_damage(PLAYER_HIT, p.global_position)
			hits += 1
			next_hit += STEADY_HIT_GAP
		_reapply_dda()
		await physics_frame
		game += tick * Engine.time_scale
		saw_stun = saw_stun or g.current_state == stunned
		began = g.current_state == tele
	_check(began and saw_stun and hits >= 3,
		"C1 hit every %.1f s while it walks in, it still starts a telegraph (R1; %d hits, stunned %s, telegraph %s)"
			% [STEADY_HIT_GAP, hits, str(saw_stun), str(began)])
	await _wait_until(func(): return g.current_state == _state("RECOVER"), 3.0)   # let that attack finish
	await _wait_until(func(): return not g._stun_active, 2.0)
	g.current_health = g.max_health


## R3: AC-1's multiplier clauses away from 1.0. With the guardian's zone_level SCALED_ZONE_LEVEL (above the pinned
## player level 1) and the DDA score SCALED_DDA_SCORE, the stomp and the charge each take raw damage x
## get_enemy_damage_multiplier() and telegraph for raw time / the difficulty multiplier (0.25 s floor, +- one frame).
## Both are restored after.
func _c1_scaled(arena: Node, g: Node) -> void:
	var c := _guardian_consts()
	var tick := 1.0 / float(Engine.physics_ticks_per_second)
	var zone: int = g.zone_level
	g.zone_level = SCALED_ZONE_LEVEL
	_dda_pin = SCALED_DDA_SCORE
	var dmg_mult: float = g.get_enemy_damage_multiplier()
	_reapply_dda()
	var dda_mult: float = _gm().get_difficulty_multiplier()
	_check(is_equal_approx(dmg_mult, 1.5) and is_equal_approx(dda_mult, 1.25),
		"C1 scaled (R3): the multipliers under test are 1.5 (damage) and 1.25 (difficulty) (%s, %s)"
			% [str(dmg_mult), str(dda_mult)])
	var cases := [["stomp", STOMP_DIST, "STOMP_DAMAGE", "STOMP_TELEGRAPH"],
		["charge", CHARGE_DIST, "CHARGE_DAMAGE", "CHARGE_TELEGRAPH"]]
	for case in cases:
		var r: Dictionary = await _run_attack(arena, g, case[1])
		var want_dmg: float = float(c.get(case[2], 0.0)) * dmg_mult
		var want_time: float = maxf(float(c.get(case[3], 0.0)) / dda_mult, 0.25)
		_check(not is_equal_approx(dmg_mult, 1.0) and is_equal_approx(r["hp_drop"], want_dmg),
			"C1 scaled (R3): the %s takes raw x get_enemy_damage_multiplier() = %s x %s = %s HP (took %s)"
				% [case[0], str(c.get(case[2])), str(dmg_mult), str(want_dmg), str(r["hp_drop"])])
		_check(not is_equal_approx(dda_mult, 1.0) and is_equal_approx(r["duration"], want_time)
			and absf(r["game_time"] - want_time) <= tick + 0.0001,
			"C1 scaled (R3): the %s telegraphs raw / difficulty multiplier = %s / %s = %.3f s (%s s, %.3f s run)"
				% [case[0], str(c.get(case[3])), str(dda_mult), want_time, str(r["duration"]), r["game_time"]])
	g.zone_level = zone
	_dda_pin = PIN_DDA_SCORE
	_reapply_dda()


## Both attacks parried (D7): the guardian staggers, starts nothing for the stagger time, the hit does no damage.
func _c1_parry(arena: Node, g: Node) -> void:
	for mode in ["stomp", "charge"]:
		var dist: float = STOMP_DIST if mode == "stomp" else CHARGE_DIST
		var r: Dictionary = await _run_attack(arena, g, dist, mode)
		_check(r["recovered"] and g._stun_active and is_zero_approx(r["hp_drop"]),
			("C1 the parried %s: the guardian is staggered (_stun_active %s) and the player's HP is unchanged"
				+ " (drop %s; parry frame %d at %.0f px, hit frame %d)")
				% [mode, str(g._stun_active), str(r["hp_drop"]), r["parry_frame"], r["parry_dx"], r["hit_frame"]])
		var quiet: Dictionary = await _watch_quiet(g, STAGGER_TIME - 0.3)
		_check(not quiet["acted"] and quiet["stunned_throughout"],
			"C1 after the parried %s no new attack starts while it is staggered (acted %s)"
				% [mode, str(quiet["acted"])])
		var ended := await _wait_until(func(): return not g._stun_active, 3.0)   # the stagger's timer is game time
		_check(ended, "C1 the stagger after the parried %s ends (%.1f s)" % [mode, STAGGER_TIME])


## Standing within 30 px of the guardian does no damage: EnemyBase's contact check runs with the guardian's physics
## on. The player's own physics is held for the second: with it running, the player settles at another height than
## the guardian's origin and the straight-line gap the contact check measures grew to 31 px (seen in a run).
func _c1_no_contact_damage(arena: Node, g: Node) -> void:
	await _arm(arena, g, 20.0)
	g.is_hostile = true
	g.player_ref = arena.player
	var p: CharacterBody2D = arena.player
	var hp: float = p.current_health
	var acted := false
	var gap := 0.0
	p.set_physics_process(false)
	var end_msec := Time.get_ticks_msec() + 1000
	while Time.get_ticks_msec() < end_msec:
		g.attack_cooldown = 999.0   # no attack starts: only the contact check can hurt the player
		p.global_position = g.global_position - Vector2(20.0, 0.0)
		await physics_frame
		gap = maxf(gap, g.global_position.distance_to(p.global_position))
		if g.current_state == _state("TELEGRAPH") or g.current_state == _state("ATTACK"):
			acted = true
	p.set_physics_process(true)
	_check(not acted and gap < 30.0 and p.current_health == hp,
		("C1 within 30 px of the guardian for 1.0 s with physics running and no attack under way: HP unchanged"
			+ " (%s of %s; %.1f px, acted %s)") % [str(p.current_health), str(hp), gap, str(acted)])


# ── C2 (AC-2): the row ────────────────────────────────────────────────────

func _test_c2_row() -> void:
	print("[C2 the ch1_guardian row]")
	var arena_script: Script = load(ARENA_SCRIPT)
	var rows: Dictionary = arena_script.get_script_constant_map().get("STORY_FIGHTS", {})
	var row: Dictionary = rows.get(ROW_ID, {})
	_check(not row.is_empty(), "C2 STORY_FIGHTS has the row '%s'" % ROW_ID)
	var msgs: PackedStringArray = arena_script.call("validate_story_fight", row)
	_check(not row.is_empty() and msgs.is_empty(),
		"C2 validate_story_fight gives no message for the row %s" % str(msgs))
	_check(row.get("enemy_script") == GUARDIAN_SCRIPT and row.get("enemy_type") == "broken_mile_guardian"
		and row.get("enemy_name") == "StoryFightGuardian",
		"C2 enemy_script, enemy_type and enemy_name are the guardian's")
	_check(row.get("enemy_size") == Vector2(78, 56) and row.get("enemy_color") == Color(0.32, 0.26, 0.2),
		"C2 the body is the staged rectangle's: 78 x 56, Color(0.32, 0.26, 0.2)")
	var spawn: Vector2 = row.get("enemy_spawn", Vector2(9999, 0))
	var player_spawn: Vector2 = row.get("player_spawn", Vector2.ZERO)
	_check(spawn.x <= 840.0 and spawn.x > player_spawn.x,
		"C2 the guardian spawns inside the first frame (x <= 840), to the right of the player (x %s)" % str(spawn.x))
	_check(row.get("default_return_scene") == "res://scenes/chapter1/path_to_oakhaven.tscn",
		"C2 default_return_scene is the Broken Mile's scene")
	_check(row.get("flags") == [FLAG], "C2 flags is [\"%s\"] (found %s)" % [FLAG, str(row.get("flags"))])
	var slime_row: Dictionary = rows.get("ch1_slime", {})
	_check(row.get("shard_color") == SHARD_COLOR and row.get("shard_count") == 10,
		"C2 10 shards of the guardian's colour")
	for key in ["shard_fade", "shard_size", "shard_z"]:
		_check(not slime_row.is_empty() and row.get(key) == slime_row.get(key),
			"C2 %s is the slime row's (%s)" % [key, str(row.get(key))])
	_check(not slime_row.is_empty() and row.get("controls") == slime_row.get("controls"),
		"C2 the controls line is the slime row's")
	var backdrop: Dictionary = row.get("backdrop", {})
	_check(backdrop.get("sky") == Color(0.1, 0.07, 0.14) and backdrop.get("ground") == Color(0.05, 0.09, 0.04)
		and backdrop.get("path") == Color(0.14, 0.1, 0.06) and backdrop.get("tree") == Color(0.035, 0.065, 0.025),
		"C2 the backdrop is the Broken Mile's sky, ground, path and tree colours")
	var bible := FileAccess.get_file_as_string(BIBLE)
	_check(bible.contains("| `%s` |" % FLAG), "C2 STORY_BIBLE section 5 has a row for %s" % FLAG)


# ── the Broken Mile (C3, C5) ──────────────────────────────────────────────

## Advances the dialogue a line a frame and answers every choice with its first option, recording each line shown
## ("speaker: text"; the label holds the whole line from its first frame). Holds while the newest line has _hold_at.
func _drive(gen: int) -> void:
	var dm := get_root().get_node("DialogueManager")
	while _driving and gen == _drive_gen:
		if dm._is_visible and dm._text_label and dm._text_label.text != "":
			var line: String = "%s: %s" % [dm._speaker_label.text, dm._text_label.text]
			if _seen_text.is_empty() or _seen_text.back() != line:
				_seen_text.append(line)
		var held: bool = _hold_at != "" and not _seen_text.is_empty() and _seen_text.back().contains(_hold_at)
		if dm._awaiting_choice:
			if dm._choice_result == -1 and dm._choice_container != null:
				dm._on_choice_pressed(0)
		elif dm._is_visible and not held:
			dm._skip_typing = true
			dm._advance_requested = true
		await process_frame


func _start_driving() -> void:
	_driving = true
	_drive_gen += 1   # a loop told to stop this frame must not carry on beside the new one
	_drive(_drive_gen)


func _saw(fragment: String) -> bool:
	return _seen_text.any(func(l): return l.contains(fragment))


func _clear_metas() -> void:
	for k in META_KEYS:
		if _gm().has_meta(k):
			_gm().remove_meta(k)


func _scene_is(path: String) -> bool:
	return current_scene != null and current_scene.scene_file_path == path


## A fresh game with `flags` set, the dialogue driver running and the Broken Mile loaded as the current scene (its
## _ready has run to its first wait). Returns the scene, or null when it did not load.
func _load_broken_mile(flags: Array) -> Node:
	var gm := _gm()
	gm.reset_game()
	get_root().get_node("DialogueManager").force_reset()
	_clear_metas()
	for f in flags:
		gm.set_story_flag(f, true)
	_seen_text.clear()
	_hold_at = ""
	change_scene_to_file(PATH)
	await _wait_until(func(): return _scene_is(PATH), 5.0)
	_start_driving()
	return current_scene if _scene_is(PATH) else null


## Stops the driver, waits out any scene change and frees the current scene, at 1x with no story meta left: the
## stage A cases after C3 run with no current scene, as before.
func _leave_scene() -> void:
	_driving = false
	_hold_at = ""
	await _wait_scene_settled()
	_clear_metas()
	get_root().get_node("DialogueManager").force_reset()
	if current_scene != null:
		current_scene.queue_free()
	for i in 3:
		await process_frame
	get_root().get_node("ContextStack").clear_time_scale()
	Engine.time_scale = 1.0


## Runs the Broken Mile at WALK_TIME_SCALE until the Root Access panel is open and waiting (with `no_panel`, until
## guardian_directive's last line shows), then drops to 1x for the choice. True when it got there.
func _walk_to_choice(s: Node, no_panel: bool) -> bool:
	Engine.time_scale = WALK_TIME_SCALE
	var got := false
	if no_panel:
		got = await _wait_until(func(): return _saw(DIRECTIVE_LAST), MILE_WAIT)
	else:
		got = await _wait_until(
			func(): return is_instance_valid(s) and s.root_access_tutorial_active and not s.guardian_resolved, MILE_WAIT)
	Engine.time_scale = 1.0
	return got


## Watches for up to HANDOFF_WAIT s from `t0` (msec) for the hand-off: SceneTransitions busy while story_fight_id is
## ch1_guardian. Records its time, both metas, the staged guardian's alpha and whether root_refused showed before it;
## then the first scene after the Broken Mile, and the scene changes since `transitions_at_choice` 0.5 s after it.
func _watch_handoff(s: Node, t0: int, transitions_at_choice: int) -> Dictionary:
	var gm := _gm()
	var st := get_root().get_node("SceneTransitions")
	var r := {"handed": false, "elapsed": -1.0, "id": "", "ret": "", "alpha": -1.0, "refused_before": false,
		"next": "", "transitions": 0}
	var end := t0 + int(HANDOFF_WAIT * 1000.0)
	while Time.get_ticks_msec() < end:
		if st.is_transitioning and str(gm.get_meta("story_fight_id", "")) == ROW_ID:
			r["handed"] = true
			r["elapsed"] = (Time.get_ticks_msec() - t0) / 1000.0
			r["id"] = str(gm.get_meta("story_fight_id", ""))
			r["ret"] = str(gm.get_meta("story_fight_return_scene", ""))
			var g = s.get("_guardian") if is_instance_valid(s) else null
			r["alpha"] = g.modulate.a if g != null and is_instance_valid(g) else -1.0
			r["refused_before"] = _saw(REFUSED_FIRST)
			break
		await process_frame
	if r["handed"]:
		await _wait_until(func(): return current_scene != null and current_scene.scene_file_path != PATH, 6.0)
		r["next"] = current_scene.scene_file_path if current_scene != null else ""
		await _wait(0.5)
	r["transitions"] = _transitions - transitions_at_choice
	return r


## Runs the Broken Mile until a line containing `fragment` shows (MILE_WAIT cap), noting on the way any scene change,
## story-fight meta or open Root Access panel.
func _run_mile_until(s: Node, fragment: String) -> Dictionary:
	var gm := _gm()
	var st := get_root().get_node("SceneTransitions")
	var r := {"seen": false, "changed": false, "meta": false, "panel": false}
	var end := Time.get_ticks_msec() + int(MILE_WAIT * 1000.0)
	while Time.get_ticks_msec() < end:
		r["changed"] = r["changed"] or st.is_transitioning or not _scene_is(PATH)
		r["meta"] = r["meta"] or gm.has_meta("story_fight_id")
		if is_instance_valid(s):
			r["panel"] = r["panel"] or s.root_access_panel.visible or s.root_access_tutorial_active
		if _saw(fragment):
			r["seen"] = true
			break
		await process_frame
	return r


## Kaelen's and Elara's x and whether the staged guardian is in the scene, read from its CharactersLayer.
func _staging(s: Node) -> Dictionary:
	var layer: Node = s.get_node_or_null("CharactersLayer") if is_instance_valid(s) else null
	if layer == null:
		return {"kaelen": -1.0, "elara": -1.0, "guardian": true}
	var k = layer.get_node_or_null("Kaelen")
	var e = layer.get_node_or_null("Elara")
	return {"kaelen": k.position.x if k != null else -1.0, "elara": e.position.x if e != null else -1.0,
		"guardian": layer.get_node_or_null("Guardian") != null}


# ── C3 (AC-3): the Broken Mile's hand-off ─────────────────────────────────

func _test_c3_handoff() -> void:
	print("[C3 the Broken Mile hands the fight to the arena; filter and calm resolve without it]")
	await _c3_fight_case("the Fight button")
	await _c3_fight_case("the give-up")
	await _c3_fight_case("the no-panel fallback")
	await _c3_edit_case("filter")
	await _c3_edit_case("calm")
	await _c3_edit_case("filter", true)


## One fight outcome, through the notes' driver: "the Fight button" (_on_root_access_refused), "the give-up"
## (root_panel_timeout lowered to TEST_PANEL_TIMEOUT before the panel opens) or "the no-panel fallback"
## (apply_button nulled after _ready: nulling the panel before _ready crashes the scene).
## The give-up is timed from the panel opening, so its limit adds the timeout and one poll of the wait loop.
func _c3_fight_case(how: String) -> void:
	var gm := _gm()
	var s := await _load_broken_mile([])
	if s == null:
		_check(false, "C3 %s: the Broken Mile loads" % how)
		await _leave_scene()
		return
	var no_panel := how == "the no-panel fallback"
	var limit := HANDOFF_LIMIT
	if no_panel:
		s.apply_button = null
	elif how == "the give-up":
		s.set("root_panel_timeout", TEST_PANEL_TIMEOUT)   # set(): a scene without the member ignores it
		limit += TEST_PANEL_TIMEOUT + PANEL_POLL
	var reached := await _walk_to_choice(s, no_panel)
	var corruption: float = gm.glitch_meter
	var transitions_at_choice := _transitions
	var t0 := Time.get_ticks_msec()
	if how == "the Fight button":
		s._on_root_access_refused()
	elif no_panel:
		await _wait_until(func(): return gm.has_flag("root_access_unlocked"), 5.0)   # set right before the panel
		t0 = Time.get_ticks_msec()
	var r := await _watch_handoff(s, t0, transitions_at_choice)
	_check(reached and r["handed"] and r["id"] == ROW_ID and r["ret"] == PATH,
		"C3 %s: story_fight_id is '%s' and the return meta is the Broken Mile at the hand-off (reached %s; %s, %s)"
			% [how, ROW_ID, str(reached), r["id"], r["ret"]])
	_check(r["handed"] and r["elapsed"] <= limit,
		"C3 %s: the change to the arena starts within %.1f s of the choice (%.3f s)" % [how, limit, r["elapsed"]])
	_check(r["handed"] and is_equal_approx(r["alpha"], 1.0),
		"C3 %s: the staged guardian is still fully visible at the hand-off (modulate.a %s)" % [how, str(r["alpha"])])
	_check(r["handed"] and not r["refused_before"] and not gm.has_flag("ch1_root_discovered_unused"),
		"C3 %s: no root_refused line before the hand-off" % how)
	_check(r["next"] == ARENA and r["transitions"] == 1,
		"C3 %s: one scene change, to the arena (next '%s', %d changes)" % [how, r["next"], r["transitions"]])
	_check(is_equal_approx(gm.glitch_meter, corruption) and gm.has_flag("root_access_unlocked")
		and not gm.has_flag("ch1_root_first_edit") and not gm.has_flag("ch1_slime_root_access_tutorial")
		and not gm.has_flag(FLAG),
		"C3 %s: no corruption and no edit flag, root_access_unlocked set, %s not set before the fight" % [how, FLAG])
	await _leave_scene()


## Filter or calm: the edit resolves the guardian without the arena, as before T13b (its line, rest_stop's edited
## line, the edit flags, 10 corruption; the guardian turns away on filter and stays on calm).
## `last_tick` (R2): root_panel_timeout is dropped to LAST_TICK_TIMEOUT as the panel opens and the edit is applied at
## once, so the wait loop's next 0.1 s tick is past the give-up: the applied choice must stand, not become "fight".
## Apply is pressed twice in that frame, so "corruption was added once" also proves Apply's guardian_resolved guard.
func _c3_edit_case(how: String, last_tick: bool = false) -> void:
	var gm := _gm()
	var label := how + (" in the give-up's last tick" if last_tick else "")
	how = label
	var s := await _load_broken_mile([])
	if s == null:
		_check(false, "C3 %s: the Broken Mile loads" % how)
		await _leave_scene()
		return
	var reached := await _walk_to_choice(s, false)
	var corruption: float = gm.glitch_meter
	var corruption_adds: Array = []
	var on_meter := func(value: float):
		corruption_adds.append(value)
	gm.glitch_meter_changed.connect(on_meter)
	if reached and last_tick:
		s.set("root_panel_timeout", LAST_TICK_TIMEOUT)
	if reached:
		if how.begins_with("filter"):
			s._target_filter.select(1)   # TARGET FILTER: ALL -> FRACTURE_ENTITIES
		else:
			s.aggression_spinbox.value = 0.5
		s._on_root_access_apply()
		if last_tick:
			s._on_root_access_apply()   # a second click in the same frame: the guard must not charge it again
	_hold_at = EDITED   # rest_stop's line: the scene goes no further, so nothing after it can change scene
	Engine.time_scale = WALK_TIME_SCALE
	var r := await _run_mile_until(s, EDITED)
	Engine.time_scale = 1.0
	var is_filter := how.begins_with("filter")
	var line := FILTER_LINE if is_filter else CALM_LINE
	_check(reached and _saw(line) and r["seen"] and not _saw(REFUSED_FIRST),
		"C3 %s: its line plays ('%s'), then rest_stop's edited line; no root_refused line" % [how, line])
	_check(reached and not r["changed"] and not r["meta"],
		"C3 %s: no story meta and no scene change up to rest_stop (meta %s, changed %s)"
			% [how, str(r["meta"]), str(r["changed"])])
	_check(gm.has_flag("ch1_root_first_edit") and gm.has_flag("ch1_slime_root_access_tutorial")
		and is_equal_approx(gm.glitch_meter - corruption, 10.0) and not gm.has_flag("ch1_root_discovered_unused")
		and not gm.has_flag(FLAG),
		"C3 %s: the edit flags set, 10 corruption added (%s), ch1_root_discovered_unused and %s unset"
			% [how, str(gm.glitch_meter - corruption), FLAG])
	var g = s.get("_guardian") if is_instance_valid(s) else null
	var alpha: float = g.modulate.a if g != null and is_instance_valid(g) else -1.0
	var want_alpha := 0.0 if is_filter else 1.0
	_check(is_equal_approx(alpha, want_alpha),
		"C3 %s: the staged guardian %s (modulate.a %s)"
			% [how, "turns away" if is_filter else "stays", str(alpha)])
	gm.glitch_meter_changed.disconnect(on_meter)
	if last_tick:
		_check(corruption_adds.size() == 1,
			"C3 %s: corruption was added once (%d changes: %s)" % [how, corruption_adds.size(), str(corruption_adds)])
	await _leave_scene()


# ── C4 (AC-4): the fight in the arena ─────────────────────────────────────

func _test_c4_win() -> void:
	print("[C4 winning]")
	var gm := _gm()
	var arena := await _start_arena()
	var g := _guardian(arena)
	if g == null:
		_check(false, "C4 the win: no StoryFightGuardian in the arena")
		_end_arena(arena)
		await process_frame
		return
	_check(gm.current_state == gm.GameState.COMBAT, "C4 GameState is COMBAT during the fight")
	_freeze(g)
	var xp_before: int = gm.player_stats.get("xp", 0)
	var gold_before: int = gm.player_stats.get("gold", 0)
	var items_before: Dictionary = get_root().get_node("Inventory").items.duplicate()
	var hp_before: int = gm.player_stats.get("hp", 100)
	var flag_sets: Array = []
	var on_flag := func(flag_name: String, value: bool):
		if flag_name == FLAG and value:
			flag_sets.append(flag_name)
	gm.story_flag_updated.connect(on_flag)
	var pos: Vector2 = g.global_position
	var transitions_before := _transitions
	g.take_damage(g.max_health)
	var shards := _shards(arena)
	_check(shards.size() == 10
		and shards.all(func(s): return s.color == SHARD_COLOR and s.global_position.distance_to(pos) < 80.0),
		"C4 the guardian breaks into 10 polygon shards of Color(0.32, 0.26, 0.2) at its position (%d)" % shards.size())
	_check(gm.has_flag(FLAG), "C4 %s is set" % FLAG)
	_check(arena._story_resolved and arena.player.invulnerable, "C4 the guard is set and the player is invulnerable")
	_check(gm.player_stats.get("xp", 0) == xp_before and gm.player_stats.get("gold", 0) == gold_before
		and get_root().get_node("Inventory").items == items_before, "C4 XP, gold and the inventory are unchanged")
	var pickups: Array = get_root().get_node("DropManager")._active_pickups.filter(
		func(p): return is_instance_valid(p) and arena.is_ancestor_of(p))
	_check(pickups.is_empty() and g.loot_table == null,
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
	print("[C4 the player's death is a retry with a fresh guardian]")
	var gm := _gm()
	var arena := await _start_arena()
	var old := _guardian(arena)
	if old == null:
		_check(false, "C4 the retry: no StoryFightGuardian in the arena")
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
	var fresh := _guardian(arena)
	_check(ok and fresh != null and fresh.get_instance_id() != old_id and fresh.current_health == fresh.max_health,
		"C4 a new StoryFightGuardian instance at full HP, story_fight_retries + 1 (%d)" % arena.story_fight_retries)
	_check(not arena.player.is_dead and arena.player.current_health == arena.player.max_health
		and gm.player_stats.get("hp", 0) == int(arena.player.max_health),
		"C4 the player's HP is full after the retry")
	var old_valid := is_instance_valid(old)
	_check(old_valid and old.name == "StoryFightGuardian_old" and not old.visible and old.collision_layer == 0,
		"C4 the old guardian is disabled, hidden and renamed at once (still in the tree %s)" % str(old_valid))
	_check(_time_requests_empty(), "C4 time scale 1.0 and no ContextStack entry after the retry")
	_end_arena(arena)
	await process_frame


## The old guardian is mid-charge when the retry runs. Both start on the floor. The player dies DEATH_LEAD before
## the telegraph begins (the guardian's cooldown is set to it), so the retry (STORY_RETRY_DELAY, 1.0 s of game time
## after the death) comes about 0.2 s into the charge's 0.5 s of travel. The guardian starts RETRY_CHARGE_DIST from
## the spawn and walks a little closer meanwhile, so its hit box (110 px reach, 520 px/s) reaches the spawn about
## 0.2 s after the restore (about 0.1 s before its travel ends): not on the dead player, whose take_damage returns
## early while the hit still counts as landed and would end the charge's hit. The restore's 0.75 s of
## invulnerability is cleared at once, so only the old guardian being disabled stops the hit. The arena restores
## the player at the spawn, 200 px above the floor, where the charge (along the floor) passes under it while it
## falls (about 0.64 s): the test puts it on the floor at once, so the height cannot stand in for the disabling
## either. Without the disabling (t13b_retry_check_watch_fail_rev3.log) the player takes the charge's 14.
func _test_c4_retry_mid_charge() -> void:
	print("[C4 the player dies while the guardian is mid-charge]")
	var gm := _gm()
	var arena := await _start_arena()
	var old := _guardian(arena)
	if old == null:
		_check(false, "C4 the mid-charge retry: no StoryFightGuardian in the arena")
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
	# Read at the retry, before the next physics step: the old charge must not have landed yet.
	p.invulnerable = false
	p.invuln_timer = 0.0
	p.global_position = spawn
	p.velocity = Vector2.ZERO
	var gap: float = absf(old.global_position.x - p.global_position.x) if is_instance_valid(old) else -1.0
	var fresh = arena._story_enemy   # the arena's own reference: by name it could be the old guardian
	_freeze(fresh)                    # only the old charge is on trial now
	_check(begun and charging_at_retry and gap > _charge_reach(_guardian_consts()),
		"C4 the old guardian was mid-charge (ATTACK) when the retry ran, its hit box short of the spawn"
			+ " (telegraphed %s, charging %s, %.2f s into the charge, %.0f px away)"
			% [str(begun), str(charging_at_retry), elapsed_at_retry, gap])
	await process_frame
	_check(arena.story_fight_retries == retries_before + 1 and fresh != null and fresh.get_instance_id() != old_id
		and not p.is_dead and p.current_health == p.max_health,
		"C4 a new StoryFightGuardian instance, the player at full HP, story_fight_retries + 1 (%d)"
			% arena.story_fight_retries)
	var old_valid := is_instance_valid(old)
	_check(old_valid and old.current_state == _state("DEAD") and not old.visible and old.collision_layer == 0,
		"C4 the old, mid-charge guardian is disabled (still in the tree %s)" % str(old_valid))
	var lowest: float = p.current_health
	var watch_end := Time.get_ticks_msec() + 1000
	while Time.get_ticks_msec() < watch_end:
		await physics_frame
		lowest = minf(lowest, p.current_health)
	_check(lowest == p.max_health and gm.player_stats.get("hp", 0) == int(p.max_health) and not p.is_dead,
		"C4 the player's HP stays full for 1 s after the restore, invulnerability cleared: the old charge does not hit"
			+ " (lowest HP %s)" % str(lowest))
	_end_arena(arena)
	await process_frame


## The guardian killed mid-telegraph ("TELEGRAPH") or mid-charge ("ATTACK"): one win, the flag set once, the player's
## HP unchanged from the kill on (the charge, launched 200 px away, would land about 0.17 s after its launch). The
## arena's win makes the player invulnerable, which would hide any hit, so the watch clears that every frame for
## KILL_WATCH s of game time: only the dead guardian's own stop keeps the player whole
## (t13b_mutation_s_rev3.log keeps a dead guardian's attack running).
func _test_c4_kill_mid_attack(phase: String) -> void:
	var what := "mid-telegraph" if phase == "TELEGRAPH" else "mid-charge"
	print("[C4 the guardian killed %s]" % what)
	var gm := _gm()
	var arena := await _start_arena()
	var g := _guardian(arena)
	if g == null:
		_check(false, "C4 the kill %s: no StoryFightGuardian in the arena" % what)
		_end_arena(arena)
		await process_frame
		return
	await _wait(0.5)
	var p: CharacterBody2D = arena.player
	var flag_sets: Array = []
	var on_flag := func(flag_name: String, value: bool):
		if flag_name == FLAG and value:
			flag_sets.append(flag_name)
	gm.story_flag_updated.connect(on_flag)
	await _arm(arena, g, CHARGE_DIST)
	var reached := await _wait_until(func(): return g.current_state == _state(phase), 3.0)
	var hp: float = p.current_health
	var stats_hp: int = gm.player_stats.get("hp", 0)
	var transitions_before := _transitions
	g.take_damage(g.max_health)
	var tick := 1.0 / float(Engine.physics_ticks_per_second)
	var lowest: float = p.current_health
	var game := 0.0
	var cap_msec := Time.get_ticks_msec() + int(KILL_WATCH * 4000.0) + 1000   # a cap, should time scale stall
	while game < KILL_WATCH and Time.get_ticks_msec() < cap_msec:
		p.invulnerable = false
		p.invuln_timer = 0.0
		await physics_frame
		game += tick * Engine.time_scale
		lowest = minf(lowest, p.current_health)
	var done := await _wait_until(func(): return _outcomes.size() > 0, 3.0)
	await _wait_scene_settled()
	_check(reached and done and _outcomes == ["win"] and _transitions == transitions_before + 1,
		"C4 the guardian killed %s: one win and one scene change (reached %s, %s, %d changes)"
			% [what, str(reached), str(_outcomes), _transitions - transitions_before])
	_check(flag_sets.size() == 1, "C4 the guardian killed %s: %s set once (%d times)" % [what, FLAG, flag_sets.size()])
	_check(reached and lowest == hp and gm.player_stats.get("hp", 0) == stats_hp,
		"C4 the guardian killed %s: the player's HP is unchanged after the kill, invulnerability cleared (%s, lowest %s)"
			% [what, str(hp), str(lowest)])
	gm.story_flag_updated.disconnect(on_flag)
	_end_arena(arena)
	await process_frame


# ── C5 (AC-5): the resume ─────────────────────────────────────────────────

func _test_c5_resume() -> void:
	print("[C5 the Broken Mile loaded with ch1_guardian_fought resumes at root_refused]")
	await _c5_resume_and_reload()
	await _c5_main_menu_from_fight()


## Loaded with the flag: root_refused first, with Kaelen at 600 and Elara at 680 and no guardian; no walk-in line,
## no panel, no arena; rest_stop with the not-edited line. A save there and a load resume the same way, and the scene
## goes on to Oakhaven. When the first line is not root_refused's, the later waits are skipped and their checks fail.
func _c5_resume_and_reload() -> void:
	var gm := _gm()
	var st := get_root().get_node("SceneTransitions")
	var s := await _load_broken_mile(RESUME_FLAGS)
	if s == null:
		_check(false, "C5 the Broken Mile loads")
		await _leave_scene()
		return
	_hold_at = NOT_EDITED   # the save is made while rest_stop's line is up
	Engine.time_scale = WALK_TIME_SCALE
	await _wait_until(func(): return not _seen_text.is_empty(), 20.0)
	var staging := _staging(s)   # on the frame the first line shows, before the walk on
	var first: String = _seen_text[0] if not _seen_text.is_empty() else "<none>"
	var resumed := first.contains(REFUSED_FIRST)
	var r := {"seen": false, "changed": true, "meta": true, "panel": true}
	if resumed:
		r = await _run_mile_until(s, NOT_EDITED)
	_check(resumed, "C5 the first line shown is root_refused's first ('%s')" % first)
	_check(is_equal_approx(staging["kaelen"], 600.0) and is_equal_approx(staging["elara"], 680.0)
		and not staging["guardian"],
		"C5 Kaelen at x 600 and Elara at x 680, no staged guardian, as root_refused begins (%s)" % str(staging))
	_check(resumed and not WALK_IN_LINES.any(_saw) and not r["panel"] and not r["changed"] and not r["meta"],
		"C5 no tree_flicker to guardian_directive line, no Root Access panel, no arena or story meta (panel %s)"
			% str(r["panel"]))
	_check(r["seen"] and _saw(REST_FIRST) and not _saw(EDITED),
		"C5 rest_stop is reached with the not-edited line ('%s')" % NOT_EDITED)
	_check(gm.has_flag("ch1_root_discovered_unused") and gm.has_flag("root_access_unlocked")
		and not gm.has_flag("ch1_root_first_edit"),
		"C5 root_refused set ch1_root_discovered_unused; root_access_unlocked is still set, no edit flag")
	var saved := false
	if r["seen"]:
		saved = gm.save_game(1)
	_check(saved, "C5 a save made at rest_stop is allowed")
	_driving = false
	await process_frame
	_seen_text.clear()
	_hold_at = ""
	var loaded := false
	if saved:
		loaded = await gm.load_game(1)
	_start_driving()
	await _wait_until(func(): return _scene_is(PATH) and not st.is_transitioning, 10.0)
	Engine.time_scale = WALK_TIME_SCALE   # the load's scene change set it back to 1x
	var s2 := current_scene
	var r2 := {"seen": false, "changed": true, "meta": true, "panel": true}
	var first2 := "<none>"
	if loaded and _scene_is(PATH):
		await _wait_until(func(): return not _seen_text.is_empty(), 20.0)
		first2 = _seen_text[0] if not _seen_text.is_empty() else "<none>"
		if first2.contains(REFUSED_FIRST):
			r2 = await _run_mile_until(s2, NOT_EDITED)
	_check(loaded and first2.contains(REFUSED_FIRST) and r2["seen"] and not r2["panel"] and not r2["changed"]
		and not r2["meta"],
		"C5 after a load of that save the first line is root_refused's again, no panel, no arena ('%s')" % first2)
	var arena_seen := false
	var village := false
	if r2["seen"]:
		var end := Time.get_ticks_msec() + int(MILE_WAIT * 1000.0)
		while Time.get_ticks_msec() < end:
			arena_seen = arena_seen or _scene_is(ARENA) or gm.has_meta("story_fight_id")
			if _scene_is(VILLAGE):
				village = true
				break
			await process_frame
	_check(village and _saw(RIDGE_FIRST) and not arena_seen,
		"C5 the resumed scene goes on to ridge and Oakhaven, with no trip to the arena")
	Engine.time_scale = 1.0
	await _leave_scene()


## Pause -> main menu during the guardian fight (the arena loaded as the current scene with the Broken Mile's metas):
## the pause menu's "Yes, Leave" reaches the main menu, no story meta is left and ch1_guardian_fought stays unset.
func _c5_main_menu_from_fight() -> void:
	var gm := _gm()
	var st := get_root().get_node("SceneTransitions")
	gm.reset_game()
	get_root().get_node("DialogueManager").force_reset()
	_clear_metas()
	gm.set_meta("story_fight_id", ROW_ID)
	gm.set_meta("story_fight_return_scene", PATH)
	change_scene_to_file(ARENA)
	await _wait_until(func(): return _scene_is(ARENA), 5.0)
	for i in 4:
		await process_frame
	var in_arena := _scene_is(ARENA)
	var g: Node = _guardian(current_scene) if in_arena else null
	var enemies: Array = []
	var holder: Node = current_scene.get_node_or_null("Enemies") if in_arena else null
	if holder != null:
		enemies = holder.get_children().map(func(n): return String(n.name))
	var had_guardian := g != null   # read now: once the arena is freed, g compares equal to null
	_freeze(g)
	var ps := get_root().get_node("PauseScreen")
	ps.toggle_pause()
	var paused: bool = ps.is_paused
	ps._return_to_main_menu()
	var yes: Button = null
	if ps._confirm_menu_panel != null:
		for b in ps._confirm_menu_panel.find_children("*", "Button", true, false):
			if b is Button and (b as Button).text.contains("Yes, Leave"):
				yes = b as Button
	var found_yes := yes != null   # read now: the button is freed with its panel once pressed
	if found_yes:
		yes.pressed.emit()
	var at_menu := await _wait_until(func(): return _scene_is(MAIN_MENU) and not st.is_transitioning, 8.0)
	_check(had_guardian and paused and found_yes and at_menu,
		"C5 pause -> main menu from the guardian fight reaches the main menu (guardian %s %s, paused %s, yes %s, menu %s)"
			% [str(had_guardian), str(enemies), str(paused), str(found_yes), str(at_menu)])
	_check(not gm.has_meta("story_fight_id") and not gm.has_meta("story_fight_return_scene") and not gm.has_flag(FLAG),
		"C5 leaving the fight by the main menu leaves no story meta and %s unset" % FLAG)
	await _leave_scene()
