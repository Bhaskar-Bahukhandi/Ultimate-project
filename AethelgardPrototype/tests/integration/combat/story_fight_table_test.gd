extends SceneTree
## Y1-P0 TD-031: the story-fight table holds the whole fight, and one builder makes every enemy body.
## The golden cases (8, 10, 11) were captured BEFORE the refactor, so this same test proves nothing visible changed.
##   AC-2 / QA case 1   every STORY_FIGHTS row validates clean; STORY_FIGHT_DEFAULTS holds the AC-2 values
##   AC-3 / QA case 2   validate_story_fight: one message per problem, naming the key; int/float number keys pass
##   AC-3 / QA case 3   an invalid row given through story_fight_table is refused: default mode, metas removed
##   AC-6 / QA case 4   a row with required keys only (another enemy script, no backdrop) runs a whole fight:
##                      spawns, the win after shard_fade, its flags, its return scene, no shards
##   AC-1 / QA case 5   a 2-tree backdrop without `path` makes 2 trunks and no path; no tree literal in the code
##   AC-6 / QA case 6   the test row's retry: a fresh enemy at the spawn with layer 4 and mask 1 (read before its
##                      _ready, which sets layer 4 and mask 1 itself)
##   AC-6 / QA case 6b  a row with an enemy_type that has no size or colour entry uses its own enemy_size and
##                      enemy_color for the Sprite and the collision rect
##   AC-5 / QA case 7   _build_enemy_body's node shape; the source has one body builder and no inline body
##   AC-7 / QA case 8   the ch1_slime story fight: every StoryFightTrunk and StoryFightCanopy rect, the
##                      Background, Ground/GroundSprite and Ground/StoryFightPath rects, the StoryFightSlime body
##   AC-4 / QA case 9   the win with the enemy already freed: the shards start at the row's enemy_spawn
##   AC-7 / QA case 10  an encounter (GameManager meta `pending_encounter`) with two explicit enemies of
##                      different types, one at level 3: each body's name, position, zone_level, max_health,
##                      pending_zone_level meta, Sprite, CollisionShape2D, layer, mask, script
##   AC-7 / QA case 11  a boss fight (meta `boss_fight_id`) with a pinned checkpoint (retry fraction 0.8):
##                      the body, current_health = max_health * 0.8, _boss_initial_hp = max_health
## The new seams (story_fight_table, validate_story_fight, _build_enemy_body, STORY_FIGHT_DEFAULTS) are reached
## by name at run time, so on an arena without them the cases fail by name instead of stopping the suite.
##   AC-2 / QA case 4b  shard_count 0 with shard_fade 1.2: the win waits the row's fade, not the default
## Test rows: the arena's story_fight_table is set to {id: row} before add_child. Their fights are driven
## through die() and the player's take_damage; case 9 frees the enemy and calls _on_story_enemy_died itself.
## Private state this test reads or drives, named: the arena's _story_id, _is_random_encounter, _is_boss_fight,
## _encounter_enemies, _boss_node, _boss_initial_hp and a direct _on_story_enemy_died() call (case 9);
## GameManager._dda_performance_score, _dda_recent_kills, _dda_recent_deaths; RandomEncounterSystem
## ._enemies_alive, ._encounter_enemy_count; the arena's source text (cases 5 and 7).
## Isolation (AC-8): each case pins GameManager's DDA score (-> get_difficulty_multiplier), its kill and death
## window counters and player_stats["level"] (EnemyBase._apply_level_scaling reads them), case 11 also the boss
## checkpoint, and restores all of it afterwards; case 11 removes the `boss_fight_id` meta that
## _start_boss_fight leaves set. The cases give the same result in any order (CASE_ORDER).
## Test-side isolation costs, named: GameManager._dda_* and RandomEncounterSystem._enemies_alive /
## _encounter_enemy_count (the arena overwrites them in an encounter) are read, set and restored; the arena's
## _encounter_enemies, _boss_node and _boss_initial_hp are read; every body is read the moment the arena's
## _ready has built it (the enemies' physics would move them afterwards), except the boss, whose HP is set
## and recorded on the arena's two awaited frames.
## Run: tests/run_phase0_tests.ps1 -Script res://tests/integration/combat/story_fight_table_test.gd

const ARENA := "res://scenes/combat/combat_arena.tscn"
const STUB := "res://tests/fixtures/story_fight_return_stub.tscn"
## True prints every snapshot as `GOLDEN-CAPTURE <label>.<key> = <value>` and asserts only structure.
const CAPTURE := false
const CASE_ORDER := ["slime", "encounter", "boss", "defaults", "validate", "refused", "required_only", "slow_fade", "trees",
	"retry", "own_look", "builder", "shard_fallback"]
const ARENA_SCRIPT := "res://scripts/combat/combat_arena.gd"
## The functions that build an enemy body: none may build one inline (AC-5). The story retry spawns through
## _spawn_story_enemy (case 6 covers it at run time).
const SPAWN_FUNCS := ["_start_random_encounter", "_start_boss_fight", "_spawn_story_enemy"]
const AC2_DEFAULTS := {"shard_count": 0, "shard_fade": 0.6, "shard_size": 12.0, "shard_z": 20,
	"shard_color": Color(1, 1, 1), "backdrop": {}}
## A row with the required keys only: another enemy script than the slime's, no backdrop, no shard keys.
const TEST_ROW := {
	"enemy_script": "res://scripts/combat/enemies/corrupted_rat.gd",
	"enemy_type": "corrupted_rat",
	"enemy_name": "TestRowRat",
	"enemy_spawn": Vector2(640, 400),
	"player_spawn": Vector2(240, 400),
	"default_return_scene": STUB,
	"flags": ["td031_test_row_won", "td031_test_row_second_flag"],
	"controls": "{move} — Move",
}
## Two trees, no path (QA 5): [x, width, height].
const TWO_TREE_BACKDROP := {"sky": Color(0.3, 0.2, 0.1), "ground": Color(0.1, 0.3, 0.2), "tree": Color(0.2, 0.1, 0.3),
	"margin": Vector2(700, 400), "trees": [[100.0, 30.0, 200.0], [900.0, 40.0, 220.0]]}
const OLD_TREE_LITERAL := "[-420.0, 38.0, 230.0]"
const FALLBACK_SPAWN := Vector2(300, 400)   # QA 9
## An enemy_type with no ENEMY_SIZES / ENEMY_COLORS entry and the row's own look (QA 2, QA 6b).
const GUARDIAN_TYPE := "td031_guardian"
const GUARDIAN_LOOK := {"enemy_type": GUARDIAN_TYPE, "enemy_size": Vector2(70, 50), "enemy_color": Color(0.8, 0.2, 0.6)}
const GUARDIAN_BODY_EXPECTED := {
	"guardian.present": true, "guardian.name": "TestRowRat", "guardian.position": "640.000,400.000",
	"guardian.sprite.present": true, "guardian.sprite.size": "70.000,50.000", "guardian.sprite.position": "-35.000,-50.000",
	"guardian.sprite.color": "cc3399ff", "guardian.shape.present": true, "guardian.shape.size": "70.000,50.000",
	"guardian.shape.position": "0.000,-25.000",
}

const PIN_DDA_SCORE := 50.0   # the neutral score: _recalc_dda keeps it at 50 with no kills and no deaths
const PIN_PLAYER_LEVEL := 1
const BOSS_ID := "clockwork_automaton"
const BOSS_RETRY_FRACTION := 0.8   # game_manager.gd get_boss_retry_hp_fraction: 3+ attempts and best phase 3+
const BOSS_CHECKPOINT := {"attempts": 3, "best_phase": 3, "best_hp_pct_removed": 0.5}
const ENCOUNTER := {
	"encounter_type": "combat", "reward_mult": 1.0, "zone_id": "oakhaven_outskirts",
	"enemies": [{"type": "slime", "level": 1}, {"type": "corrupted_rat", "level": 3}],
}

var _passes := 0
var _failures: Array[String] = []
var _saved := {}
var _outcomes: Array = []
var _transitions := 0


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	await process_frame
	if not OS.get_user_data_dir().contains("aeth_phase0_test"):
		push_error("Refusing to run: user data dir is not isolated. Use tests/run_phase0_tests.ps1.")
		quit(2)
		return
	get_root().get_node("SceneTransitions").transition_started.connect(func(): _transitions += 1)
	for case_name in CASE_ORDER:
		match case_name:
			"slime":
				await _test_slime_backdrop_and_body_match_golden()
			"encounter":
				await _test_encounter_bodies_match_golden()
			"boss":
				await _test_boss_body_and_checkpoint_hp_match_golden()
			"defaults":
				_test_every_row_validates_and_defaults_hold_ac2_values()
			"validate":
				_test_validate_names_each_problem_key()
			"refused":
				await _test_invalid_row_runs_default_mode()
			"required_only":
				await _test_required_keys_row_runs_whole_fight()
			"slow_fade":
				await _test_no_shards_win_waits_row_fade()
			"trees":
				await _test_two_tree_backdrop_makes_two_trunks()
			"retry":
				await _test_row_retry_spawns_fresh_body()
			"own_look":
				await _test_row_enemy_look_overrides_type_tables()
			"builder":
				_test_build_enemy_body_shape_and_single_builder()
			"shard_fallback":
				await _test_freed_enemy_shards_start_at_row_spawn()
	_finish()


func _finish() -> void:
	print("")
	print("STORY FIGHT TABLE RESULT: %d passed, %d failed" % [_passes, _failures.size()])
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


func _wait_until(cond: Callable, timeout_sec: float) -> bool:
	var end := Time.get_ticks_msec() + int(timeout_sec * 1000.0)
	while Time.get_ticks_msec() < end:
		if cond.call():
			return true
		await process_frame
	return cond.call()


func _clear_metas() -> void:
	for k in ["story_fight_id", "story_fight_return_scene", "pending_encounter", "boss_fight_id"]:
		if _gm().has_meta(k):
			_gm().remove_meta(k)


## A float as a stable string: rounded to 3 decimals, never "-0.000".
func _f(x: float) -> String:
	var v := snappedf(x, 0.001)
	if v == 0.0:
		v = 0.0
	return "%.3f" % v


func _v(v: Vector2) -> String:
	return "%s,%s" % [_f(v.x), _f(v.y)]


## Resets the game, then pins the state the snapshots depend on (after the reset: reset_game restores the
## DDA score and clears the checkpoints itself). Returns what to put back.
func _pin_state(checkpoint: Dictionary) -> Dictionary:
	var gm := _gm()
	var res := get_root().get_node("RandomEncounterSystem")
	var saved := {
		"score": gm._dda_performance_score, "kills": gm._dda_recent_kills, "deaths": gm._dda_recent_deaths,
		"level": gm.player_stats.get("level", 1), "checkpoints": gm.boss_checkpoints.duplicate(true),
		"alive": res._enemies_alive, "count": res._encounter_enemy_count,
	}
	gm.reset_game()
	get_root().get_node("DialogueManager").force_reset()
	gm._dda_performance_score = PIN_DDA_SCORE
	gm._dda_recent_kills = 0
	gm._dda_recent_deaths = 0
	gm.player_stats["level"] = PIN_PLAYER_LEVEL
	gm.boss_checkpoints = {}
	if not checkpoint.is_empty():
		gm.boss_checkpoints[BOSS_ID] = checkpoint.duplicate()
	return saved


func _restore_state(saved: Dictionary) -> void:
	var gm := _gm()
	var res := get_root().get_node("RandomEncounterSystem")
	gm._dda_performance_score = saved["score"]
	gm._dda_recent_kills = saved["kills"]
	gm._dda_recent_deaths = saved["deaths"]
	gm.player_stats["level"] = saved["level"]
	gm.boss_checkpoints = saved["checkpoints"]
	res._enemies_alive = saved["alive"]
	res._encounter_enemy_count = saved["count"]


## Pins the state, sets the metas, adds the arena to the root. No frame has run when it returns, so the arena's
## _ready has built the story backdrop and every spawned body, and nothing has moved yet.
func _begin_case(metas: Dictionary, checkpoint: Dictionary) -> Node:
	_saved = _pin_state(checkpoint)
	_clear_metas()
	for k in metas:
		_gm().set_meta(k, metas[k])
	var arena: Node = (load(ARENA) as PackedScene).instantiate()
	get_root().add_child(arena)
	return arena


func _end_case(arena: Node) -> void:
	get_root().get_node("DialogueManager").force_reset()
	if is_instance_valid(arena):
		arena.queue_free()
	_clear_metas()
	get_root().get_node("ContextStack").clear_time_scale()
	_restore_state(_saved)
	await process_frame
	await process_frame


## Compares a snapshot with its golden constant, one check per field (the name says which); in CAPTURE mode
## it prints the snapshot instead.
func _check_golden(label: String, actual: Dictionary, golden: Dictionary) -> void:
	if CAPTURE:
		for k in actual:
			print("GOLDEN-CAPTURE %s.%s = %s" % [label, k, var_to_str(actual[k])])
		return
	var keys_match: bool = actual.size() == golden.size() and golden.keys().all(func(k): return actual.has(k))
	_check(keys_match, "%s has exactly the %d golden fields (found %d)" % [label, golden.size(), actual.size()])
	for k in golden:
		_check(actual.has(k) and typeof(actual[k]) == typeof(golden[k]) and actual[k] == golden[k],
			"%s %s equals the golden value %s (found %s)" % [label, k, var_to_str(golden[k]), var_to_str(actual.get(k, "<missing>"))])


# ── snapshots: plain values only ──────────────────────────────────────────

func _snap_rect(out: Dictionary, prefix: String, node: Node) -> void:
	var rect := node as ColorRect
	out[prefix + ".present"] = rect != null
	if rect == null:
		return
	out[prefix + ".position"] = _v(rect.position)
	out[prefix + ".size"] = _v(rect.size)
	out[prefix + ".color"] = rect.color.to_html(true)


## An enemy body as the arena builds it: the Sprite rect, the CollisionShape2D, layer, mask, script.
func _snap_body(out: Dictionary, prefix: String, body: Node) -> void:
	var cb := body as CharacterBody2D
	out[prefix + ".present"] = cb != null
	if cb == null:
		return
	out[prefix + ".name"] = str(cb.name)
	out[prefix + ".position"] = _v(cb.position)
	out[prefix + ".collision_layer"] = cb.collision_layer
	out[prefix + ".collision_mask"] = cb.collision_mask
	out[prefix + ".script"] = cb.get_script().resource_path if cb.get_script() != null else "<none>"
	var sprite := cb.get_node_or_null("Sprite") as ColorRect
	out[prefix + ".sprite.present"] = sprite != null
	if sprite != null:
		out[prefix + ".sprite.size"] = _v(sprite.size)
		out[prefix + ".sprite.position"] = _v(sprite.position)
		out[prefix + ".sprite.color"] = sprite.color.to_html(true)
		out[prefix + ".sprite.mouse_filter"] = sprite.mouse_filter
	# The arena never names its CollisionShape2D (the node gets an automatic name), so it is found by type.
	var col: CollisionShape2D = null
	for child in cb.get_children():
		if child is CollisionShape2D:
			col = child
			break
	out[prefix + ".shape.present"] = col != null and col.shape is RectangleShape2D
	if col != null and col.shape is RectangleShape2D:
		out[prefix + ".shape.position"] = _v(col.position)
		out[prefix + ".shape.size"] = _v((col.shape as RectangleShape2D).size)


func _snap_slime_fight(arena: Node) -> Dictionary:
	var out := {}
	var trunks: Array = []
	var canopies: Array = []
	var backdrop := arena.get_node_or_null("StoryFightBackdrop")
	if backdrop != null:
		# The arena gives every trunk the name StoryFightTrunk and every canopy StoryFightCanopy, but add_child
		# renames all duplicates automatically, so only the first of each keeps its name. The arena adds them
		# as trunk, canopy, trunk, canopy ...: they are told apart by that order.
		var rects: Array = backdrop.get_children().filter(func(n): return n is ColorRect)
		out["first_trunk_name"] = str(rects[0].name) if rects.size() > 0 else "<none>"
		out["first_canopy_name"] = str(rects[1].name) if rects.size() > 1 else "<none>"
		for i in rects.size():
			(trunks if i % 2 == 0 else canopies).append(rects[i])
	var by_x := func(a, b): return a.position.x < b.position.x
	trunks.sort_custom(by_x)
	canopies.sort_custom(by_x)
	out["trunk_count"] = trunks.size()
	out["canopy_count"] = canopies.size()
	for i in trunks.size():
		_snap_rect(out, "trunk[%d]" % i, trunks[i])
	for i in canopies.size():
		_snap_rect(out, "canopy[%d]" % i, canopies[i])
	_snap_rect(out, "background", arena.get_node_or_null("Background"))
	_snap_rect(out, "ground_sprite", arena.get_node_or_null("Ground/GroundSprite"))
	_snap_rect(out, "path", arena.get_node_or_null("Ground/StoryFightPath"))
	_snap_body(out, "slime", arena.get_node_or_null("Enemies/StoryFightSlime"))
	return out


func _snap_encounter(arena: Node) -> Dictionary:
	var out := {}
	var bodies: Array = arena._encounter_enemies
	out["body_count"] = bodies.size()
	for i in bodies.size():
		var b: Node = bodies[i]
		var p := "enemy[%d]" % i
		_snap_body(out, p, b)
		out[p + ".zone_level"] = b.zone_level
		out[p + ".max_health"] = _f(b.max_health)
		out[p + ".has_pending_zone_level"] = b.has_meta("pending_zone_level")
		out[p + ".pending_zone_level"] = b.get_meta("pending_zone_level") if b.has_meta("pending_zone_level") else -1
	return out


## `out` already holds the body fields (read when the arena's _ready built it); this adds the HP values read
## after the arena's two awaited frames.
func _snap_boss_hp(out: Dictionary, arena: Node, spawned: Node) -> void:
	var boss: Node = arena._boss_node
	out["boss.is_the_spawned_body"] = boss != null and boss == spawned
	if boss == null:
		return
	out["boss.max_health"] = _f(boss.max_health)
	out["boss.current_health"] = _f(boss.current_health)
	out["boss.expected_current_health"] = _f(boss.max_health * BOSS_RETRY_FRACTION)
	out["boss.arena_initial_hp"] = _f(arena._boss_initial_hp)
	out["boss.initial_hp_equals_max"] = is_equal_approx(arena._boss_initial_hp, boss.max_health)
	out["boss.retry_fraction"] = _f(_gm().get_boss_retry_hp_fraction(BOSS_ID))


# ── QA case 8: the slime fight ────────────────────────────────────────────

func _test_slime_backdrop_and_body_match_golden() -> void:
	print("[QA 8 the ch1_slime fight: backdrop rects and the story enemy body]")
	var arena := await _begin_case({"story_fight_id": "ch1_slime", "story_fight_return_scene": STUB}, {})
	var snap := _snap_slime_fight(arena)
	_check(snap["trunk_count"] == 11 and snap["canopy_count"] == 11 and snap["slime.present"] and snap["path.present"],
		"QA 8 the slime fight built 11 trunks, 11 canopies, the path and the slime (%s trunks)" % str(snap["trunk_count"]))
	_check_golden("slime", snap, GOLDEN_SLIME)
	await _end_case(arena)


# ── QA case 10: an encounter ──────────────────────────────────────────────

func _test_encounter_bodies_match_golden() -> void:
	print("[QA 10 an encounter: two bodies of different types, one at level 3]")
	var arena := await _begin_case({"pending_encounter": ENCOUNTER.duplicate(true)}, {})
	await _wait_until(func(): return arena._encounter_enemies.size() == 2, 3.0)
	var snap := _snap_encounter(arena)
	_check(snap["body_count"] == 2 and arena._is_random_encounter and not _gm().has_meta("pending_encounter"),
		"QA 10 the encounter built 2 bodies and consumed pending_encounter (%s bodies)" % str(snap["body_count"]))
	_check(snap["body_count"] == 2 and snap["enemy[0].max_health"] != snap["enemy[1].max_health"]
		and snap["enemy[1].zone_level"] == 3,
		"QA 10 the two bodies differ in max_health and the second has zone_level 3")
	_check_golden("encounter", snap, GOLDEN_ENCOUNTER)
	await _end_case(arena)


# ── QA case 11: a boss fight ──────────────────────────────────────────────

func _test_boss_body_and_checkpoint_hp_match_golden() -> void:
	print("[QA 11 a boss fight with a checkpoint that gives 0.8 HP]")
	var arena := await _begin_case({"boss_fight_id": BOSS_ID}, BOSS_CHECKPOINT)
	var spawned: Node = arena._boss_node
	var snap := {}
	_snap_body(snap, "boss", spawned)
	# The checkpoint HP is set on the first awaited frame, _boss_initial_hp on the second.
	await process_frame
	await process_frame
	await _wait_until(func(): return arena._boss_initial_hp > 0.0, 3.0)
	_snap_boss_hp(snap, arena, spawned)
	_check(snap["boss.present"] and snap["boss.is_the_spawned_body"] and arena._is_boss_fight and snap["boss.retry_fraction"] == _f(BOSS_RETRY_FRACTION),
		"QA 11 the boss fight started and the pinned checkpoint gives retry fraction 0.8 (%s)" % str(snap.get("boss.retry_fraction")))
	_check(snap["boss.is_the_spawned_body"] and snap["boss.initial_hp_equals_max"]
		and snap["boss.current_health"] == snap["boss.expected_current_health"],
		"QA 11 current_health is max_health * 0.8 and _boss_initial_hp is max_health")
	_check_golden("boss", snap, GOLDEN_BOSS)
	await _end_case(arena)


# ── the new seams, reached by name (the file must load and fail by name on an arena without them) ──

func _arena_script() -> Script:
	return load(ARENA_SCRIPT)


func _has_validator() -> bool:
	return _arena_script().get_script_method_list().any(func(m): return m["name"] == "validate_story_fight")


## validate_story_fight(row), or one "<no validate_story_fight>" message on an arena without it.
func _validate(row: Dictionary) -> PackedStringArray:
	if not _has_validator():
		return PackedStringArray(["<no validate_story_fight>"])
	return _arena_script().call("validate_story_fight", row)


func _arena_source() -> String:
	return FileAccess.get_file_as_string(ARENA_SCRIPT)


## One function's text in the arena's source: its `func` line up to the next line that is not indented.
func _func_source(src: String, func_name: String) -> String:
	var out := PackedStringArray()
	var inside := false
	for raw in src.split("\n"):
		var line := raw.trim_suffix("\r")
		if line.begins_with("func %s(" % func_name) or line.begins_with("static func %s(" % func_name):
			inside = true
		elif inside and not line.is_empty() and not line.begins_with("\t"):
			break
		if inside:
			out.append(line)
	return "\n".join(out)


## TEST_ROW with `extra` merged over it (a mutable copy).
func _row(extra: Dictionary) -> Dictionary:
	var row: Dictionary = TEST_ROW.duplicate(true)
	row.merge(extra.duplicate(true), true)
	return row


## TWO_TREE_BACKDROP with `changes` merged over it (a mutable copy).
func _backdrop(changes: Dictionary) -> Dictionary:
	var backdrop: Dictionary = TWO_TREE_BACKDROP.duplicate(true)
	backdrop.merge(changes.duplicate(true), true)
	return backdrop


## Pins the state, sets the story metas and gives the arena a table holding only {id: row} before add_child
## (its _ready consumes the metas). No frame has run when it returns; the fight's enemy, if any, is frozen.
func _begin_row_case(id: String, row: Dictionary, return_scene: String = "") -> Node:
	_saved = _pin_state({})
	_clear_metas()
	_gm().set_meta("story_fight_id", id)
	if not return_scene.is_empty():
		_gm().set_meta("story_fight_return_scene", return_scene)
	var arena: Node = (load(ARENA) as PackedScene).instantiate()
	arena.set("story_fight_table", {id: row})
	_outcomes.clear()
	arena.story_fight_resolved.connect(func(o): _outcomes.append(o))
	get_root().add_child(arena)
	_freeze(_row_enemy(arena, row))
	return arena


func _row_enemy(arena: Node, row: Dictionary) -> Node:
	var enemy := arena.get_node_or_null("Enemies/" + str(row["enemy_name"]))
	return enemy if enemy != null and not enemy.is_queued_for_deletion() else null


func _story_started(arena: Node, id: String) -> bool:
	return is_instance_valid(arena) and str(arena.get("_story_id")) == id


func _freeze(enemy: Node) -> void:
	if is_instance_valid(enemy):
		enemy.set_physics_process(false)
		enemy.set_process(false)


func _shards(arena: Node) -> Array:
	return arena.get_children().filter(func(n): return str(n.name).begins_with("StoryFightShard"))


func _wait(seconds: float) -> void:
	var end := Time.get_ticks_msec() + int(seconds * 1000.0)
	while Time.get_ticks_msec() < end:
		await process_frame


func _wait_scene_settled() -> void:
	var st := get_root().get_node("SceneTransitions")
	await _wait_until(func(): return not st.is_transitioning, 6.0)


# ── QA case 1: every row validates; the defaults ──────────────────────────

func _test_every_row_validates_and_defaults_hold_ac2_values() -> void:
	print("[QA 1 every STORY_FIGHTS row validates clean; STORY_FIGHT_DEFAULTS holds the AC-2 values]")
	var consts: Dictionary = _arena_script().get_script_constant_map()
	_check(_has_validator(), "QA 1 the arena script has a static validate_story_fight")
	var rows: Dictionary = consts.get("STORY_FIGHTS", {})
	_check(not rows.is_empty(), "QA 1 STORY_FIGHTS has rows (%d)" % rows.size())
	for id in rows:
		var msgs := _validate(rows[id])
		_check(msgs.is_empty(), "QA 1 STORY_FIGHTS row '%s' validates with no message %s" % [id, str(msgs)])
	var test_msgs := _validate(TEST_ROW)
	_check(test_msgs.is_empty(), "QA 1 the test row (required keys only) validates with no message %s" % str(test_msgs))
	var defaults: Dictionary = consts.get("STORY_FIGHT_DEFAULTS", {})
	_check(defaults.size() == AC2_DEFAULTS.size(),
		"QA 1 STORY_FIGHT_DEFAULTS has exactly the %d AC-2 keys (found %d)" % [AC2_DEFAULTS.size(), defaults.size()])
	for k in AC2_DEFAULTS:
		_check(defaults.has(k) and typeof(defaults[k]) == typeof(AC2_DEFAULTS[k]) and defaults[k] == AC2_DEFAULTS[k],
			"QA 1 STORY_FIGHT_DEFAULTS %s is %s (found %s)" % [k, var_to_str(AC2_DEFAULTS[k]), var_to_str(defaults.get(k, "<missing>"))])


# ── QA case 2: validate_story_fight names each problem's key ──────────────

func _test_validate_names_each_problem_key() -> void:
	print("[QA 2 validate_story_fight: one message per problem, naming the key]")
	var no_flags := _row({})
	no_flags.erase("flags")
	var no_trees: Dictionary = TWO_TREE_BACKDROP.duplicate(true)
	no_trees.erase("trees")
	var bad_rows := [
		["flags", "a row missing flags", no_flags],
		["enemy_spawn", "enemy_spawn as a String", _row({"enemy_spawn": "760, 400"})],
		["enemy_spwan", "an extra misspelt key enemy_spwan", _row({"enemy_spwan": Vector2(760, 400)})],
		["sky", "the old flat backdrop key sky", _row({"sky": Color(0.16, 0.1, 0.28)})],
		["enemy_script", "an enemy_script that does not exist", _row({"enemy_script": "res://scripts/combat/enemies/td031_no_such_enemy.gd"})],
		["trees", "a backdrop without trees", _row({"backdrop": no_trees})],
		["shard_fade", "shard_fade as a String", _row({"shard_fade": "0.6"})],
		["shard_color", "shard_color not a Color", _row({"shard_color": "white"})],
		["backdrop", "backdrop not a Dictionary", _row({"backdrop": ["sky"]})],
		["backdrop.sky", "backdrop.sky as a String", _row({"backdrop": _backdrop({"sky": "purple"})})],
		["backdrop.path", "a backdrop path that is not a Color", _row({"backdrop": _backdrop({"path": 5})})],
		["fog", "an unknown backdrop key fog", _row({"backdrop": _backdrop({"fog": Color(1, 1, 1)})})],
		["backdrop.trees[0]", "a trees entry of length 2", _row({"backdrop": _backdrop({"trees": [[100, 30], [900, 40, 220]]})})],
		["backdrop.trees[1]", "a non-numeric trees entry", _row({"backdrop": _backdrop({"trees": [[100, 30, 200], [900, "40", 220]]})})],
		["flags[0]", "flags [5]", _row({"flags": [5]})],
		["flags[0]", "flags [\"\"]", _row({"flags": [""]})],
		["enemy_script", "an enemy_script at an existing .tscn (not a Script)", _row({"enemy_script": ARENA})],
	]
	for bad in bad_rows:
		var msgs := _validate(bad[2])
		_check(msgs.size() == 1 and str(msgs[0]).contains(bad[0]),
			"QA 2 %s gives one message naming '%s' %s" % [bad[1], bad[0], str(msgs)])
	# The look keys: a wrong type is a type message (not an unknown key); an enemy_type with no ENEMY_SIZES /
	# ENEMY_COLORS entry needs both keys, so no row falls back to the 48 x 48 grey body.
	for bad_look in [["enemy_size", "enemy_size as a String", {"enemy_size": "70x50"}],
			["enemy_color", "enemy_color as a Vector2", {"enemy_color": Vector2(1, 1)}]]:
		var look_msgs := _validate(_row(bad_look[2]))
		_check(look_msgs.size() == 1 and str(look_msgs[0]).contains(bad_look[0]) and str(look_msgs[0]).contains("must be"),
			"QA 2 %s gives one type message naming '%s' %s" % [bad_look[1], bad_look[0], str(look_msgs)])
	var unknown_type := _validate(_row({"enemy_type": GUARDIAN_TYPE}))
	_check(unknown_type.size() == 2 and Array(unknown_type).any(func(m): return m.contains("enemy_size"))
		and Array(unknown_type).any(func(m): return m.contains("enemy_color")),
		"QA 2 an enemy_type with no size or colour entry and neither key gives two messages, enemy_size and enemy_color %s" % str(unknown_type))
	var own_look := _validate(_row(GUARDIAN_LOOK))
	_check(own_look.is_empty(), "QA 2 the same enemy_type with enemy_size and enemy_color gives no message %s" % str(own_look))
	var two_problems := _row({"enemy_spwan": Vector2(760, 400)})
	two_problems.erase("flags")
	var two_msgs := _validate(two_problems)
	_check(two_msgs.size() == 2 and Array(two_msgs).any(func(m): return m.contains("flags"))
		and Array(two_msgs).any(func(m): return m.contains("enemy_spwan")),
		"QA 2 a row missing flags and with enemy_spwan gives exactly two messages, one per key %s" % str(two_msgs))
	for extra in [{"shard_size": 12}, {"shard_count": 3.0}]:
		var msgs := _validate(_row(extra))
		_check(msgs.is_empty(), "QA 2 a row with %s gives no message %s" % [var_to_str(extra).replace("\n", ""), str(msgs)])


# ── QA case 3: an invalid row is refused ──────────────────────────────────

func _test_invalid_row_runs_default_mode() -> void:
	print("[QA 3 an invalid row given through story_fight_table: default mode, metas removed]")
	var id := "td031_invalid"
	# Valid but for one unknown key, so only the row check can refuse it.
	var row := _row({"sky": Color(0.16, 0.1, 0.28)})
	var arena := _begin_row_case(id, row, STUB)
	_check("story_fight_table" in arena, "QA 3 the arena exposes story_fight_table (the test's rows reach it)")
	var tutorial := arena.get_node_or_null("Enemies/TutorialSlime")
	_check(tutorial != null and not tutorial.is_queued_for_deletion() and _row_enemy(arena, row) == null
		and str(arena.get("_story_id")).is_empty() and arena.get_node_or_null("StoryFightBackdrop") == null,
		"QA 3 the refused row runs the default mode: the tutorial slime, no TestRowRat, no story id")
	_check(not _gm().has_meta("story_fight_id") and not _gm().has_meta("story_fight_return_scene"),
		"QA 3 both story metas are removed")
	await _end_case(arena)


# ── QA case 4: a row with required keys only runs a whole fight ───────────

func _test_required_keys_row_runs_whole_fight() -> void:
	print("[QA 4 a row with required keys only runs a whole fight]")
	var id := "td031_required_only"
	var row := _row({})
	var plain: Node = (load(ARENA) as PackedScene).instantiate()   # the scene's own colours, never in the tree
	var sky: Color = plain.get_node("Background").color
	var ground: Color = plain.get_node("Ground/GroundSprite").color
	plain.free()
	var arena := _begin_row_case(id, row)
	var enemy := _row_enemy(arena, row)
	_check(_story_started(arena, id) and enemy != null and enemy.get_script() != null
		and enemy.get_script().resource_path == row["enemy_script"],
		"QA 4 the test row's fight started with its own enemy script (story id '%s')" % str(arena.get("_story_id")))
	_check(arena.get_node_or_null("StoryFightBackdrop") == null and arena.get_node("Background").color == sky
		and arena.get_node("Ground/GroundSprite").color == ground and arena.get_node_or_null("Ground/StoryFightPath") == null,
		"QA 4 no backdrop: no StoryFightBackdrop or path; Background and GroundSprite keep the scene's colours")
	if enemy == null or not _story_started(arena, id):
		await _end_case(arena)
		return
	_check(enemy.position == row["enemy_spawn"] and arena.player.position == row["player_spawn"],
		"QA 4 the enemy is at the row's enemy_spawn and the player at its player_spawn (%s, %s)" % [enemy.position, arena.player.position])
	_check(enemy.loot_table == null and bool(enemy.get_meta("suppress_base_rewards", false)),
		"QA 4 the test row's enemy gives nothing: loot_table null and suppress_base_rewards set")
	var label := arena.get_node_or_null("UI/StoryFightControls") as Label
	var rendered: String = get_root().get_node("InputService").fmt(row["controls"])
	_check(label != null and not label.text.is_empty() and label.text == rendered,
		"QA 4 UI/StoryFightControls shows the row's controls, rendered (%s)" % (label.text if label else "no label"))
	var transitions_before := _transitions
	var killed := Time.get_ticks_msec()
	enemy.die()
	_check(row["flags"].all(func(f): return _gm().has_flag(f)), "QA 4 the kill sets the row's flags %s" % str(row["flags"]))
	await _wait(0.3)
	_check(_outcomes.is_empty() and _shards(arena).is_empty(),
		"QA 4 0.3 s after the kill: no win signal yet and no shard node %s" % str(_outcomes))
	await _wait_until(func(): return _outcomes.size() > 0, 3.0)
	# A lower bound under 600 ms: the real-time timer's first step is the previous frame's length.
	var waited := Time.get_ticks_msec() - killed
	_check(_outcomes == ["win"] and waited >= 400, "QA 4 the win is emitted after the 0.6 s shard_fade default (%d ms)" % waited)
	await _wait_until(func(): return _transitions > transitions_before, 6.0)
	await _wait_scene_settled()
	_check(_outcomes == ["win"] and _transitions == transitions_before + 1 and current_scene != null
		and current_scene.scene_file_path == row["default_return_scene"],
		"QA 4 the win is emitted once and the game changes once to the row's return scene (%s, %d transitions)"
			% [str(_outcomes), _transitions - transitions_before])
	_check(_shards(arena).is_empty(), "QA 4 no shard node at the end either (shard_count defaults to 0)")
	await _end_case(arena)


# ── QA case 4b: the win waits the row's shard_fade with no shards ─────────

func _test_no_shards_win_waits_row_fade() -> void:
	print("[QA 4b shard_count 0, shard_fade 1.2: the win waits the row's fade]")
	var id := "td031_slow_fade"
	var row := _row({"shard_count": 0, "shard_fade": 1.2})
	var arena := _begin_row_case(id, row)
	var enemy := _row_enemy(arena, row)
	_check(_story_started(arena, id) and enemy != null, "QA 4b the test row's fight started")
	if enemy == null or not _story_started(arena, id):
		await _end_case(arena)
		return
	var killed := Time.get_ticks_msec()
	enemy.die()
	await _wait(0.9)   # real seconds, well inside the 1.2 s fade and past the 0.6 s default
	_check(_outcomes.is_empty() and _shards(arena).is_empty(),
		"QA 4b 0.9 s after the kill: no win signal yet and no shard node %s" % str(_outcomes))
	await _wait_until(func(): return _outcomes.size() > 0, 2.0)
	var waited := Time.get_ticks_msec() - killed
	_check(_outcomes == ["win"] and waited <= 2000,
		"QA 4b the win is emitted once by about 2 s after the kill (%d ms) %s" % [waited, str(_outcomes)])
	await _wait_scene_settled()
	await _end_case(arena)


# ── QA case 5: a 2-tree backdrop ──────────────────────────────────────────

func _test_two_tree_backdrop_makes_two_trunks() -> void:
	print("[QA 5 a 2-tree backdrop without path: 2 trunks, no path; no tree literal in the arena's code]")
	var id := "td031_two_trees"
	var row := _row({"backdrop": TWO_TREE_BACKDROP})
	var arena := _begin_row_case(id, row)
	var backdrop := arena.get_node_or_null("StoryFightBackdrop")
	# Trunk, canopy, trunk, canopy ... in add order (add_child renames the duplicate names).
	var rects: Array = backdrop.get_children().filter(func(n): return n is ColorRect) if backdrop != null else []
	var trunks: Array = []
	for i in range(0, rects.size(), 2):
		trunks.append(rects[i])
	_check(_story_started(arena, id) and trunks.size() == 2 and rects.size() == 4,
		"QA 5 the 2-tree backdrop makes exactly 2 StoryFightTrunk and 2 canopies (%d rects)" % rects.size())
	var first: ColorRect = trunks[0] if trunks.size() > 0 else null
	_check(first != null and first.position == Vector2(100, 400) and first.size == Vector2(30, 200)
		and first.color == TWO_TREE_BACKDROP["tree"],
		"QA 5 the first trunk is the row's [100, 30, 200] in its tree colour (%s)" % (str(first.get_rect()) if first else "none"))
	_check(_story_started(arena, id) and arena.get_node_or_null("Ground/StoryFightPath") == null
		and arena.get_node("Background").color == TWO_TREE_BACKDROP["sky"],
		"QA 5 no StoryFightPath for a backdrop without path; the sky is the row's")
	# The table lives in the same file, so this text check is weak by itself: the 2-tree count above is the guard.
	_check(not _arena_source().contains(OLD_TREE_LITERAL),
		"AC-1 note: the old float literal %s is absent from combat_arena.gd (weak; the QA 5 trunk count is the guard)" % OLD_TREE_LITERAL)
	await _end_case(arena)


# ── QA case 6: the test row's retry ───────────────────────────────────────

func _test_row_retry_spawns_fresh_body() -> void:
	print("[QA 6 the test row's retry: a fresh enemy at the spawn with layer 4 and mask 1]")
	var id := "td031_retry"
	var row := _row({})
	var arena := _begin_row_case(id, row)
	var old := _row_enemy(arena, row)
	_check(_story_started(arena, id) and old != null, "QA 6 the test row's fight started")
	if old == null or not _story_started(arena, id):
		await _end_case(arena)
		return
	var old_id := old.get_instance_id()
	# EnemyBase._ready sets layer 4 and mask 1 itself, so the body is read as it enters the tree, before _ready.
	var entered: Array = []
	arena.get_node("Enemies").child_entered_tree.connect(func(n):
		if n is CharacterBody2D:
			entered.append({"name": str(n.name), "position": n.position, "layer": n.collision_layer,
				"mask": n.collision_mask, "id": n.get_instance_id()}))
	arena.player.take_damage(9999.0, Vector2.ZERO, "Test", "melee")
	await _wait_until(func(): return arena.story_fight_retries >= 1, 8.0)
	_freeze(_row_enemy(arena, row))
	var fresh: Dictionary = entered[0] if entered.size() == 1 else {}
	_check(arena.story_fight_retries == 1 and entered.size() == 1 and fresh.get("id", old_id) != old_id
		and fresh.get("name") == row["enemy_name"],
		"QA 6 the retry adds one fresh %s (retries %d, bodies added %d)" % [row["enemy_name"], arena.story_fight_retries, entered.size()])
	_check(fresh.get("position") == row["enemy_spawn"] and fresh.get("layer") == 4 and fresh.get("mask") == 1,
		"QA 6 the fresh enemy enters at the row's spawn with layer 4 and mask 1 %s" % str(fresh))
	_check(not arena.player.is_dead and arena.player.global_position.distance_to(row["player_spawn"]) < 4.0,
		"QA 6 the player is restored at the row's player_spawn (%s)" % arena.player.global_position)
	await _end_case(arena)


# ── QA case 6b: a row's own enemy size and colour ─────────────────────────

func _test_row_enemy_look_overrides_type_tables() -> void:
	print("[QA 6b a row with an unknown enemy_type and its own enemy_size and enemy_color]")
	var id := "td031_own_look"
	var row := _row(GUARDIAN_LOOK)
	var arena := _begin_row_case(id, row)
	_check(_story_started(arena, id), "QA 6b the row's fight started (story id '%s')" % str(arena.get("_story_id")))
	var snap := {}
	_snap_body(snap, "guardian", _row_enemy(arena, row))
	for k in GUARDIAN_BODY_EXPECTED:
		_check(typeof(snap.get(k)) == typeof(GUARDIAN_BODY_EXPECTED[k]) and snap.get(k) == GUARDIAN_BODY_EXPECTED[k],
			"QA 6b %s is the row's %s (found %s)" % [k, var_to_str(GUARDIAN_BODY_EXPECTED[k]), var_to_str(snap.get(k, "<missing>"))])
	await _end_case(arena)


# ── QA case 7: the builder ────────────────────────────────────────────────

const BUILDER_EXPECTED := {
	"builder.present": true, "builder.name": "X", "builder.position": "5.000,6.000",
	"builder.collision_layer": 4, "builder.collision_mask": 1, "builder.script": "<none>",
	"builder.sprite.present": true, "builder.sprite.size": "30.000,20.000", "builder.sprite.position": "-15.000,-20.000",
	"builder.sprite.color": "ff0000ff", "builder.sprite.mouse_filter": 2,
	"builder.shape.present": true, "builder.shape.position": "0.000,-10.000", "builder.shape.size": "30.000,20.000",
}

func _test_build_enemy_body_shape_and_single_builder() -> void:
	print("[QA 7 _build_enemy_body's node shape; one body builder in the source]")
	var arena: Node = (load(ARENA) as PackedScene).instantiate()   # never enters the tree
	var has_builder := arena.has_method("_build_enemy_body")
	_check(has_builder, "QA 7 the arena has _build_enemy_body")
	if has_builder:
		var body: Node = arena.call("_build_enemy_body", "X", Vector2(30, 20), Color(1, 0, 0), Vector2(5, 6))
		var snap := {}
		_snap_body(snap, "builder", body)
		for k in BUILDER_EXPECTED:
			_check(typeof(snap.get(k)) == typeof(BUILDER_EXPECTED[k]) and snap.get(k) == BUILDER_EXPECTED[k],
				"QA 7 %s is %s (found %s)" % [k, var_to_str(BUILDER_EXPECTED[k]), var_to_str(snap.get(k, "<missing>"))])
		_check(body != null and body.get_child_count() == 2, "QA 7 the body has exactly 2 children, Sprite and the shape")
		if body != null:
			body.free()
	arena.free()
	var src := _arena_source()
	var builder_src := _func_source(src, "_build_enemy_body")
	_check(src.count("CharacterBody2D.new()") == 1 and builder_src.contains("CharacterBody2D.new()")
		and builder_src.contains("RectangleShape2D.new()"),
		"QA 7 CharacterBody2D.new() appears once in combat_arena.gd, in _build_enemy_body with its shape (%d)" % src.count("CharacterBody2D.new()"))
	for f in SPAWN_FUNCS:
		var f_src := _func_source(src, f)
		_check(not f_src.is_empty() and not f_src.contains("CharacterBody2D.new()") and not f_src.contains("RectangleShape2D.new()")
			and not f_src.contains("name = \"Sprite\""), "QA 7 %s builds no body, shape or Sprite rect inline" % f)


# ── QA case 9: the shard origin when the enemy is already freed ───────────

func _test_freed_enemy_shards_start_at_row_spawn() -> void:
	print("[QA 9 the win with the enemy already freed: the shards start at the row's enemy_spawn]")
	var id := "td031_shard_fallback"
	var row := _row({"shard_count": 3, "enemy_spawn": FALLBACK_SPAWN, "player_spawn": Vector2(100, 400)})
	var arena := _begin_row_case(id, row)
	var enemy := _row_enemy(arena, row)
	_check(_story_started(arena, id) and enemy != null, "QA 9 the test row's fight started")
	if enemy == null or not _story_started(arena, id):
		await _end_case(arena)
		return
	enemy.free()                    # the arena's _story_enemy is now a freed instance
	arena._on_story_enemy_died()    # not awaited: it spawns the shards, then waits the shard fade
	var side: float = AC2_DEFAULTS["shard_size"]
	var expected := FALLBACK_SPAWN + Vector2(-side * 0.5, -22.0)
	var shards := _shards(arena)
	_check(shards.size() == 3 and shards.all(func(s): return s.position.is_equal_approx(expected)),
		"QA 9 3 shards start at %s, not at (900, 400) %s" % [expected, str(shards.map(func(s): return s.position))])
	await _wait_until(func(): return _outcomes.size() > 0, 3.0)
	await _wait_scene_settled()
	_check(_outcomes == ["win"], "QA 9 the win still resolves once %s" % str(_outcomes))
	await _end_case(arena)


# ── golden values: captured on HEAD b27a318 before TD-031 (game code as at b27a318; HEAD 9bd9ead added docs only).
# Log: production/qa/evidence/2026-11-td031/golden_capture_before.log (CAPTURE true, 3 identical runs).

const GOLDEN_SLIME := {
	"first_trunk_name": "StoryFightTrunk",
	"first_canopy_name": "StoryFightCanopy",
	"trunk_count": 11,
	"canopy_count": 11,
	"trunk[0].present": true,
	"trunk[0].position": "-420.000,370.000",
	"trunk[0].size": "38.000,230.000",
	"trunk[0].color": "0f240aff",
	"trunk[1].present": true,
	"trunk[1].position": "-180.000,385.000",
	"trunk[1].size": "34.000,215.000",
	"trunk[1].color": "0f240aff",
	"trunk[2].present": true,
	"trunk[2].position": "50.000,360.000",
	"trunk[2].size": "40.000,240.000",
	"trunk[2].color": "0f240aff",
	"trunk[3].present": true,
	"trunk[3].position": "180.000,380.000",
	"trunk[3].size": "35.000,220.000",
	"trunk[3].color": "0f240aff",
	"trunk[4].present": true,
	"trunk[4].position": "350.000,390.000",
	"trunk[4].size": "30.000,210.000",
	"trunk[4].color": "0f240aff",
	"trunk[5].present": true,
	"trunk[5].position": "800.000,370.000",
	"trunk[5].size": "38.000,230.000",
	"trunk[5].color": "0f240aff",
	"trunk[6].present": true,
	"trunk[6].position": "950.000,375.000",
	"trunk[6].size": "42.000,225.000",
	"trunk[6].color": "0f240aff",
	"trunk[7].present": true,
	"trunk[7].position": "1100.000,365.000",
	"trunk[7].size": "36.000,235.000",
	"trunk[7].color": "0f240aff",
	"trunk[8].present": true,
	"trunk[8].position": "1200.000,380.000",
	"trunk[8].size": "32.000,220.000",
	"trunk[8].color": "0f240aff",
	"trunk[9].present": true,
	"trunk[9].position": "1420.000,375.000",
	"trunk[9].size": "36.000,225.000",
	"trunk[9].color": "0f240aff",
	"trunk[10].present": true,
	"trunk[10].position": "1660.000,365.000",
	"trunk[10].size": "40.000,235.000",
	"trunk[10].color": "0f240aff",
	"canopy[0].present": true,
	"canopy[0].position": "-458.000,313.000",
	"canopy[0].size": "114.000,95.000",
	"canopy[0].color": "142b0de6",
	"canopy[1].present": true,
	"canopy[1].position": "-214.000,334.000",
	"canopy[1].size": "102.000,85.000",
	"canopy[1].color": "142b0de6",
	"canopy[2].present": true,
	"canopy[2].position": "10.000,300.000",
	"canopy[2].size": "120.000,100.000",
	"canopy[2].color": "142b0de6",
	"canopy[3].present": true,
	"canopy[3].position": "145.000,327.500",
	"canopy[3].size": "105.000,87.500",
	"canopy[3].color": "142b0de6",
	"canopy[4].present": true,
	"canopy[4].position": "320.000,345.000",
	"canopy[4].size": "90.000,75.000",
	"canopy[4].color": "142b0de6",
	"canopy[5].present": true,
	"canopy[5].position": "762.000,313.000",
	"canopy[5].size": "114.000,95.000",
	"canopy[5].color": "142b0de6",
	"canopy[6].present": true,
	"canopy[6].position": "908.000,312.000",
	"canopy[6].size": "126.000,105.000",
	"canopy[6].color": "142b0de6",
	"canopy[7].present": true,
	"canopy[7].position": "1064.000,311.000",
	"canopy[7].size": "108.000,90.000",
	"canopy[7].color": "142b0de6",
	"canopy[8].present": true,
	"canopy[8].position": "1168.000,332.000",
	"canopy[8].size": "96.000,80.000",
	"canopy[8].color": "142b0de6",
	"canopy[9].present": true,
	"canopy[9].position": "1384.000,321.000",
	"canopy[9].size": "108.000,90.000",
	"canopy[9].color": "142b0de6",
	"canopy[10].present": true,
	"canopy[10].position": "1620.000,305.000",
	"canopy[10].size": "120.000,100.000",
	"canopy[10].color": "142b0de6",
	"background.present": true,
	"background.position": "-700.000,-400.000",
	"background.size": "2680.000,1520.000",
	"background.color": "291a47ff",
	"ground_sprite.present": true,
	"ground_sprite.position": "-700.000,0.000",
	"ground_sprite.size": "2680.000,520.000",
	"ground_sprite.color": "14290fff",
	"path.present": true,
	"path.position": "-700.000,0.000",
	"path.size": "2680.000,22.000",
	"path.color": "382914ff",
	"slime.present": true,
	"slime.name": "StoryFightSlime",
	"slime.position": "760.000,400.000",
	"slime.collision_layer": 4,
	"slime.collision_mask": 1,
	"slime.script": "res://scripts/combat/enemies/slime.gd",
	"slime.sprite.present": true,
	"slime.sprite.size": "48.000,36.000",
	"slime.sprite.position": "-24.000,-36.000",
	"slime.sprite.color": "33cc33ff",
	"slime.sprite.mouse_filter": 2,
	"slime.shape.present": true,
	"slime.shape.position": "0.000,-18.000",
	"slime.shape.size": "48.000,36.000",
}
const GOLDEN_ENCOUNTER := {
	"body_count": 2,
	"enemy[0].present": true,
	"enemy[0].name": "Slime_0",
	"enemy[0].position": "500.000,400.000",
	"enemy[0].collision_layer": 4,
	"enemy[0].collision_mask": 1,
	"enemy[0].script": "res://scripts/combat/enemies/slime.gd",
	"enemy[0].sprite.present": true,
	"enemy[0].sprite.size": "48.000,36.000",
	"enemy[0].sprite.position": "-24.000,-36.000",
	"enemy[0].sprite.color": "33cc33ff",
	"enemy[0].sprite.mouse_filter": 2,
	"enemy[0].shape.present": true,
	"enemy[0].shape.position": "0.000,-18.000",
	"enemy[0].shape.size": "48.000,36.000",
	"enemy[0].zone_level": 1,
	"enemy[0].max_health": "29.423",
	"enemy[0].has_pending_zone_level": true,
	"enemy[0].pending_zone_level": 1,
	"enemy[1].present": true,
	"enemy[1].name": "CorruptedRat_1",
	"enemy[1].position": "800.000,400.000",
	"enemy[1].collision_layer": 4,
	"enemy[1].collision_mask": 1,
	"enemy[1].script": "res://scripts/combat/enemies/corrupted_rat.gd",
	"enemy[1].sprite.present": true,
	"enemy[1].sprite.size": "40.000,28.000",
	"enemy[1].sprite.position": "-20.000,-28.000",
	"enemy[1].sprite.color": "8c5933ff",
	"enemy[1].sprite.mouse_filter": 2,
	"enemy[1].shape.present": true,
	"enemy[1].shape.position": "0.000,-14.000",
	"enemy[1].shape.size": "40.000,28.000",
	"enemy[1].zone_level": 3,
	"enemy[1].max_health": "30.404",
	"enemy[1].has_pending_zone_level": true,
	"enemy[1].pending_zone_level": 3,
}
const GOLDEN_BOSS := {
	"boss.present": true,
	"boss.name": "Clockwork Automaton",
	"boss.position": "800.000,400.000",
	"boss.collision_layer": 4,
	"boss.collision_mask": 1,
	"boss.script": "res://scripts/combat/enemies/clockwork_automaton_boss.gd",
	"boss.sprite.present": true,
	"boss.sprite.size": "80.000,100.000",
	"boss.sprite.position": "-40.000,-100.000",
	"boss.sprite.color": "99804dff",
	"boss.sprite.mouse_filter": 2,
	"boss.shape.present": true,
	"boss.shape.position": "0.000,-50.000",
	"boss.shape.size": "80.000,100.000",
	"boss.is_the_spawned_body": true,
	"boss.max_health": "2306.769",
	"boss.current_health": "1845.415",
	"boss.expected_current_health": "1845.415",
	"boss.arena_initial_hp": "2306.769",
	"boss.initial_hp_equals_max": true,
	"boss.retry_fraction": "0.800",
}
