extends SceneTree
## Y1-P0-T13a: the opening slime is a real fight in the combat arena's story-fight mode.
##   AC-2  the mode: metas consumed, one StoryFightSlime, forest backdrop, a non-blocking controls label,
##         Root Access and Perfect Delete refused (keyboard and pad), no XP / gold / drops, no cutscene skip;
##         the encounter and boss modes still win over it, a second load without metas is the default mode
##   AC-3  winning: 7 shards, both flags once, nothing else given, one scene change after the shard fade,
##         the guard (_resolved), the player dying during the shards and during COMBAT_EXIT (AC-8)
##   AC-4  dying is a tutorial retry with a fresh slime: no corruption, no game over, time scale clean,
##         a pounce whose windup ends after the retry, three retries in a row, the player-died-first order (D5)
##   AC-6  pause stops the retry and the slime; Root Access stays refused; a load clears the story metas
##   AC-7  the fight can be won with joypad events only; pad glyphs in the controls line
## The scene changes go to a stub scene (tests/fixtures/story_fight_return_stub.tscn). The arena is added as
## a plain child of the root, so it stays alive after a scene change and the retry timer can be observed.
## Test-side isolation costs, named: PlayerCombat and the slime are driven through take_damage / die /
## _perform_pounce; the arena's _story_enemy and ContextStack._time_requests are read; the kit test sets the
## arena's tutorial target (`slime`) to the story slime so only the story-mode refusal stops Root Access and
## Perfect Delete.
## Run: tests/run_phase0_tests.ps1 -Script res://tests/integration/combat/story_fight_test.gd

const ARENA := "res://scenes/combat/combat_arena.tscn"
const STUB := "res://tests/fixtures/story_fight_return_stub.tscn"
const SLIME_SCRIPT := "res://scripts/combat/enemies/slime.gd"
const SHARD_COLOR := Color(0.45, 0.85, 0.75)
const VIEW_SIZE := Vector2(1280, 720)   # the game's resolution (project.godot)
const PLAYER_STAND_Y := 576.0           # the camera's centre with the player on the ground (y 600)
const ACTION_BAR_HEIGHT := 70.0         # PlayerCombat's action buttons: offset_top -70 from the bottom

var _passes := 0
var _failures: Array[String] = []
var _transitions := 0
var _last_transition_msec := 0
var _outcomes: Array = []


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	await process_frame
	if not OS.get_user_data_dir().contains("aeth_phase0_test"):
		push_error("Refusing to run: user data dir is not isolated. Use tests/run_phase0_tests.ps1.")
		quit(2)
		return
	get_root().get_node("SceneTransitions").transition_started.connect(func():
		_transitions += 1
		_last_transition_msec = Time.get_ticks_msec())
	await _test_mode_setup()
	await _test_kit_refused()
	await _test_other_modes_win()
	await _test_win()
	await _test_win_guard()
	await _test_win_races()
	await _test_shards_readable()
	await _test_retry()
	await _test_retry_pounce_and_repeats()
	await _test_player_died_first()
	await _test_pause()
	await _test_gamepad_only()
	_finish()


func _finish() -> void:
	print("")
	print("STORY FIGHT RESULT: %d passed, %d failed" % [_passes, _failures.size()])
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


## Resets the game, sets the story metas and loads the arena as a plain child of the root.
func _start_arena(with_metas: bool = true) -> Node:
	var gm := _gm()
	gm.reset_game()
	get_root().get_node("DialogueManager").force_reset()
	for k in ["story_fight_id", "story_fight_return_scene", "pending_encounter", "boss_fight_id"]:
		if gm.has_meta(k):
			gm.remove_meta(k)
	if with_metas:
		gm.set_meta("story_fight_id", "ch1_slime")
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


func _slime(arena: Node):
	return arena.get_node_or_null("Enemies/StoryFightSlime")


func _freeze(enemy: Node) -> void:
	if is_instance_valid(enemy):
		enemy.set_physics_process(false)
		enemy.set_process(false)


func _hurt_player(arena: Node, amount: float = 9999.0) -> void:
	arena.player.take_damage(amount, Vector2.ZERO, "Test", "melee")


func _shards(arena: Node) -> Array:
	return arena.get_children().filter(func(n): return n.name.begins_with("StoryFightShard"))


func _pad_events(action: String) -> Array:
	return InputMap.action_get_events(action).filter(func(e): return e is InputEventJoypadButton or e is InputEventJoypadMotion)


func _press_pad(action: String, pressed: bool = true) -> void:
	for e in _pad_events(action):
		var ev: InputEvent = e.duplicate()
		if ev is InputEventJoypadButton:
			ev.pressed = pressed
		elif ev is InputEventJoypadMotion:
			ev.axis_value = ev.axis_value if pressed else 0.0
		Input.parse_input_event(ev)
		return


## EnemyBase.State.DEAD, read at run time: naming EnemyBase here would compile enemy_base.gd before the
## autoloads exist (it uses the ChoiceConsequences autoload), and this whole script would fail to load.
func _dead_state(enemy: Object) -> int:
	var base: Script = enemy.get_script().get_base_script()
	return int(base.get_script_constant_map()["State"]["DEAD"])


func _time_requests_empty() -> bool:
	var cs := get_root().get_node("ContextStack")
	return cs._time_requests.is_empty() and is_equal_approx(Engine.time_scale, 1.0) and not cs.any_open()


# ── AC-2: the mode ────────────────────────────────────────────────────────

func _test_mode_setup() -> void:
	print("[AC-2 the story-fight mode]")
	var gm := _gm()
	var arena := await _start_arena()
	_check(not gm.has_meta("story_fight_id") and not gm.has_meta("story_fight_return_scene"),
		"AC-2 both story metas are removed when the arena reads them")
	var enemies := arena.get_node("Enemies").get_children().filter(func(n): return n is CharacterBody2D and not n.is_queued_for_deletion())
	var slime = _slime(arena)
	_check(enemies.size() == 1 and slime != null and slime.get_script().resource_path == SLIME_SCRIPT,
		"AC-2 exactly one enemy, StoryFightSlime, running slime.gd (found %d)" % enemies.size())
	_check(arena.get_node_or_null("Enemies/TutorialSlime") == null or arena.get_node("Enemies/TutorialSlime").is_queued_for_deletion(),
		"AC-2 the scene's TutorialSlime is gone")
	_check(arena.get_node_or_null("Player") != null and arena.player.position.x < slime.position.x,
		"AC-2 the player is at the left, the slime at the right")
	_check(gm.current_state == gm.GameState.COMBAT, "AC-2 GameState is COMBAT (no random encounter can start)")
	_check(arena.find_children("*", "CutsceneManager", true, false).is_empty(), "AC-2 no CutsceneManager, so no hold-to-skip")
	_check(arena.get_node("Background").color == Color(0.16, 0.1, 0.28) and arena.get_node("Ground/GroundSprite").color == Color(0.08, 0.16, 0.06)
		and arena.get_node_or_null("Ground/StoryFightPath") != null and arena.get_node("Ground/StoryFightPath").color == Color(0.22, 0.16, 0.08),
		"AC-2 the backdrop uses the Elara meeting's sky, ground and path colours")
	# The path strip lies on the ground rect: with the same z it shows only if it comes later in the tree
	# (found in review: it sat in the backdrop, behind the opaque ground, and never showed).
	var path := arena.get_node_or_null("Ground/StoryFightPath") as CanvasItem
	var ground_rect := arena.get_node("Ground/GroundSprite") as CanvasItem
	_check(path != null and path.visible and path.z_index >= ground_rect.z_index and path.is_greater_than(ground_rect),
		"AC-2 the path strip is drawn in front of the ground, not hidden behind it")
	_check(arena.get_node_or_null("Phase10MMCombatBackplate") == null, "AC-2 the arena's cathedral decals are not drawn in the forest")
	# Framing (found in the AC-9 screenshots): the camera follows the player and has no limits.
	var sky: Rect2 = arena.get_node("Background").get_global_rect()
	var views_inside := true
	for cx in [arena._story_cfg["player_spawn"].x, 0.0, arena.ARENA_WIDTH]:
		var view := Rect2(Vector2(cx, PLAYER_STAND_Y) - VIEW_SIZE * 0.5, VIEW_SIZE)
		views_inside = views_inside and sky.encloses(view)
	_check(views_inside, "AC-2 the camera's view at the spawn and at both walls stays inside the forest backdrop (sky %s)" % sky)
	_check(absf(slime.position.x - arena.player.position.x) < VIEW_SIZE.x * 0.5 - 40.0,
		"AC-2 the slime starts inside the first frame (player x %.0f, slime x %.0f)" % [arena.player.position.x, slime.position.x])
	var label := arena.get_node_or_null("UI/StoryFightControls") as Label
	var text := label.text if label else ""
	_check(label != null and "Move" in text and "Jump" in text and "Dash" in text and "Attack" in text and "Parry" in text,
		"AC-2 one controls line names move, jump, dash, attack and parry (%s)" % text)
	_check(not get_root().get_node("DialogueManager").is_active, "AC-2 the controls line is a label, not a DialogueManager line")
	_check(label != null and label.position.y + label.size.y <= VIEW_SIZE.y - ACTION_BAR_HEIGHT,
		"AC-2 the controls line sits above the HUD's action buttons (bottom %.0f)" % (label.position.y + label.size.y if label else -1.0))
	_check(bool(slime.get_meta("suppress_base_rewards", false)) and slime.loot_table == null,
		"AC-2 the slime's XP and gold are suppressed and its loot table is cleared (no item drops)")
	# a pad press re-renders the label with pad glyphs
	var before := text
	var ev := InputEventJoypadButton.new()
	ev.button_index = JOY_BUTTON_X
	ev.pressed = true
	Input.parse_input_event(ev)
	await process_frame
	await process_frame
	var pad_text := label.text
	_check(pad_text != before and pad_text == get_root().get_node("InputService").fmt(arena._story_cfg["controls"]),
		"AC-7 after pad input the controls line shows pad glyphs (%s)" % pad_text)
	_end_arena(arena)
	await process_frame
	# a second load without metas runs the default mode
	var plain := await _start_arena(false)
	_check(plain.get_node_or_null("Enemies/TutorialSlime") != null and plain.get_node_or_null("StoryFightBackdrop") == null
		and _slime(plain) == null, "AC-2 a second load without story metas runs the default (tutorial) mode")
	_end_arena(plain)
	await process_frame
	# A load between the hand-off and the arena (quit or load during the fade) must not carry the metas into
	# a later arena: load_game and reset_game both clear GameManager.TRANSIENT_METAS.
	gm.set_meta("story_fight_id", "ch1_slime")
	gm.set_meta("story_fight_return_scene", STUB)
	gm.clear_transient_metas()
	_check(not gm.has_meta("story_fight_id") and not gm.has_meta("story_fight_return_scene"),
		"AC-6 both story metas are in TRANSIENT_METAS (clear_transient_metas, which load_game and reset_game call, removes them)")


func _test_kit_refused() -> void:
	print("[AC-2 Root Access and Perfect Delete are refused]")
	var gm := _gm()
	var arena := await _start_arena()
	var charges: int = gm.perfect_delete_charges
	# Both features fall back to the arena's tutorial target, which is null in a story fight, so they would
	# find nothing to act on even without the story-mode refusal. Pointing that target at the story slime
	# leaves the refusal as the only thing that stops them (the mutation run showed the gap).
	arena.slime = _slime(arena)
	var key_ra := InputEventAction.new()
	key_ra.action = "root_access"
	key_ra.pressed = true
	Input.parse_input_event(key_ra)
	var key_pd := InputEventAction.new()
	key_pd.action = "perfect_delete"
	key_pd.pressed = true
	Input.parse_input_event(key_pd)
	await process_frame
	await process_frame
	for action in ["root_access", "perfect_delete"]:
		_press_pad(action)
		await process_frame
		_press_pad(action, false)
		await process_frame
	arena._open_root_access()
	arena._use_perfect_delete()
	await process_frame
	_check(not get_root().get_node("ContextStack").is_open(&"root_access") and not arena.root_access_panel.visible and not arena.root_access_active,
		"AC-2 Root Access is refused from the keyboard, the pad and a direct call (no panel, no ContextStack entry)")
	_check(gm.perfect_delete_charges == charges and is_instance_valid(_slime(arena)) and _slime(arena).current_state != _dead_state(_slime(arena)) and not _slime(arena).is_queued_for_deletion(),
		"AC-2 Perfect Delete is refused: charges unchanged (%d) and the slime still stands" % gm.perfect_delete_charges)
	_end_arena(arena)
	await process_frame


func _test_other_modes_win() -> void:
	print("[the encounter and boss modes win over the story mode]")
	var gm := _gm()
	var arena := await _start_arena(false)
	_end_arena(arena)
	await process_frame
	gm.reset_game()
	gm.set_meta("story_fight_id", "ch1_slime")
	gm.set_meta("story_fight_return_scene", STUB)
	gm.set_meta("pending_encounter", {"encounter_type": "combat", "reward_mult": 1.0, "zone_id": "oakhaven_outskirts",
		"enemies": [{"type": "slime", "level": 1}]})
	var enc: Node = (load(ARENA) as PackedScene).instantiate()
	get_root().add_child(enc)
	for i in 4:
		await process_frame
	_check(enc._is_random_encounter and enc._story_id.is_empty() and _slime(enc) == null and not gm.has_meta("story_fight_id"),
		"the encounter mode still starts first, ignores the story fight and still consumes its metas")
	get_root().get_node("DialogueManager").force_reset()
	enc.queue_free()
	await process_frame
	for k in ["pending_encounter"]:
		if gm.has_meta(k):
			gm.remove_meta(k)
	gm.set_meta("story_fight_id", "ch1_slime")
	gm.set_meta("boss_fight_id", "clockwork_automaton")
	var boss: Node = (load(ARENA) as PackedScene).instantiate()
	get_root().add_child(boss)
	for i in 4:
		await process_frame
	_check(boss._is_boss_fight and boss._story_id.is_empty() and _slime(boss) == null,
		"the boss mode still starts, ignoring the story fight")
	get_root().get_node("DialogueManager").force_reset()
	boss.queue_free()
	await process_frame
	for k in ["boss_fight_id", "story_fight_id"]:
		if gm.has_meta(k):
			gm.remove_meta(k)


# ── AC-3: winning ─────────────────────────────────────────────────────────

func _test_win() -> void:
	print("[AC-3 winning]")
	var gm := _gm()
	var arena := await _start_arena()
	var slime = _slime(arena)
	_freeze(slime)
	var xp_before: int = gm.player_stats.get("xp", 0)
	var gold_before: int = gm.player_stats.get("gold", 0)
	var items_before: Dictionary = get_root().get_node("Inventory").items.duplicate()
	var hp_before: int = gm.player_stats.get("hp", 100)
	var pos: Vector2 = slime.global_position
	var transitions_before := _transitions
	var killed_msec := Time.get_ticks_msec()
	slime.take_damage(slime.max_health)
	var shards := _shards(arena)
	_check(shards.size() == 7 and shards.all(func(s): return s.color == SHARD_COLOR and s.global_position.distance_to(pos) < 80.0),
		"AC-3 the slime breaks into 7 polygon shards of the staged colour at its position (%d)" % shards.size())
	_check(gm.has_flag("first_slime_defeated") and gm.has_flag("ch1_slime_fought"), "AC-3 first_slime_defeated and ch1_slime_fought are set")
	_check(arena._story_resolved and arena.player.invulnerable, "AC-3 the guard is set and the player is invulnerable")
	_check(gm.player_stats.get("xp", 0) == xp_before and gm.player_stats.get("gold", 0) == gold_before
		and get_root().get_node("Inventory").items == items_before, "AC-3 XP, gold and the inventory are unchanged")
	var pickups: Array = get_root().get_node("DropManager")._active_pickups.filter(func(p): return is_instance_valid(p) and arena.is_ancestor_of(p))
	_check(pickups.is_empty() and slime.loot_table == null, "AC-3 no item or gold pickup in the arena and the loot table stays cleared")
	var done := await _wait_until(func(): return _outcomes.size() > 0, 3.0)
	_check(done and _outcomes == ["win"], "AC-3 story_fight_resolved emitted once, outcome 'win' (%s)" % str(_outcomes))
	await _wait_until(func(): return current_scene != null and current_scene.scene_file_path == STUB, 6.0)
	_check(current_scene != null and current_scene.scene_file_path == STUB and _transitions == transitions_before + 1,
		"AC-3 the game changed once to the return scene (transitions %d)" % (_transitions - transitions_before))
	# The test's arena is not the current scene, so an early change would not free it here; in the game it
	# would free the arena and the shards with it. A lower bound well under 600 ms: the timer is created
	# mid-frame and its first step is the previous frame's length, so a hitch before the kill shortens the
	# measured wait. Without the wait the change comes about 200 ms after the kill.
	var waited := _last_transition_msec - killed_msec
	_check(waited >= 400, "AC-3 the scene change waits for the 0.6 s shard fade (%d ms after the kill)" % waited)
	_check(gm.player_stats.get("hp", 0) == hp_before and gm.player_stats.get("hp", 0) > 0 and arena.story_fight_retries == 0,
		"AC-3 the player's HP is kept (%d) and no retry ran" % gm.player_stats.get("hp", 0))
	_check(_time_requests_empty(), "AC-3 no ContextStack entry or time-scale request is left")
	_end_arena(arena)
	await _wait_scene_settled()


func _test_win_guard() -> void:
	print("[AC-3 the guard: after the win the player cannot die and no retry runs]")
	var gm := _gm()
	var arena := await _start_arena()
	var slime = _slime(arena)
	_freeze(slime)
	slime.take_damage(slime.max_health)
	await _wait_until(func(): return _outcomes.size() > 0, 3.0)
	await _wait_scene_settled()
	var transitions_before := _transitions
	var hp: float = arena.player.current_health
	arena.player.take_damage(50.0, Vector2.ZERO, "Test", "melee")
	await process_frame
	_check(arena.player.current_health == hp and not arena.player.is_dead,
		"AC-3 player damage after the slime's death changes nothing (HP %d, is_dead %s)" % [arena.player.current_health, str(arena.player.is_dead)])
	var slime_id := slime.get_instance_id()
	arena.player.die()   # bypasses the invulnerability: only the guard can stop the retry
	await _wait(3.5)     # the arena is kept alive well past the retry's wait (1.0 s of game time)
	# the slime frees itself 0.6 s after dying, so "no retry" is: no new enemy instance appeared
	var enemies: Array = arena.get_node("Enemies").get_children().filter(func(c): return not c.is_queued_for_deletion())
	_check(arena.story_fight_retries == 0 and enemies.all(func(c): return c.get_instance_id() == slime_id) and _transitions == transitions_before,
		"AC-3 player.die() after the win: no retry, no new slime, no second scene change (retries %d)" % arena.story_fight_retries)
	_end_arena(arena)
	await process_frame


## AC-8: the slime dies first, then the player dies inside the two windows before the arena is gone: during
## the 0.6 s shard fade, and during the COMBAT_EXIT transition. player.die() bypasses the invulnerability (the
## kill zone's path). Either way the win stands: no retry, one scene change, the HP kept, time scale clean.
func _test_win_races() -> void:
	print("[AC-8 the player dies during the shards, and during COMBAT_EXIT]")
	var gm := _gm()
	var st := get_root().get_node("SceneTransitions")
	for window in ["the shard fade", "COMBAT_EXIT"]:
		var arena := await _start_arena()
		var slime = _slime(arena)
		_freeze(slime)
		var hp_before: int = gm.player_stats.get("hp", 0)
		var transitions_before := _transitions
		slime.take_damage(slime.max_health)
		var inside := false
		if window == "the shard fade":
			await process_frame
			inside = _outcomes.is_empty() and _transitions == transitions_before
		else:
			await _wait_until(func(): return _transitions > transitions_before, 3.0)
			inside = st.is_transitioning
		arena.player.die()
		await _wait_until(func(): return _outcomes.size() > 0, 3.0)
		await _wait_scene_settled()
		await _wait(2.0)   # well past the retry's 1.0 s wait (game time)
		_check(inside and _outcomes == ["win"] and arena.story_fight_retries == 0 and _transitions == transitions_before + 1
			and gm.has_flag("ch1_slime_fought"),
			"AC-8 the player dies during %s: the win stands, no retry, one scene change (in window %s, retries %d, transitions %d)"
				% [window, str(inside), arena.story_fight_retries, _transitions - transitions_before])
		_check(gm.player_stats.get("hp", 0) == hp_before and hp_before > 0 and _time_requests_empty(),
			"AC-8 after a death during %s the HP is kept (%d) and no time-scale request is left" % [window, gm.player_stats.get("hp", 0)])
		_end_arena(arena)
		await process_frame


## The shard beat must read on screen (found in the AC-9 screenshots): the kill's slow-motion stretched a
## game-time tween, so the shards stayed bunched under the slime's death flash.
func _test_shards_readable() -> void:
	print("[AC-3 the shard beat runs in real time, above the slime]")
	var arena := await _start_arena()
	var slime = _slime(arena)
	_freeze(slime)
	var origin: Vector2 = slime.global_position
	# The spread is random (other code draws from the same generator, so no seed fixes it): real time gives a
	# mean of ~33-38 px at 0.4 s, game time at 0.1x ~6 px; the 12 px threshold sits well between them.
	slime.take_damage(slime.max_health)
	Engine.time_scale = 0.1   # a heavy slow-motion, as the kill's hit-stop applies
	await _wait(0.4)          # real seconds: two thirds of the 0.6 s beat
	var shards := _shards(arena)
	var mean := 0.0
	for s in shards:
		mean += s.global_position.distance_to(origin + Vector2(-6, -22)) / maxf(1.0, shards.size())
	_check(shards.size() == 7 and mean > 12.0,
		"AC-3 under 0.1x time scale the shards spread in real time (mean %.1f px from the slime after 0.4 s)" % mean)
	_check(shards.size() == 7 and shards.all(func(s): return s.z_index > slime.z_index and s.size.x >= 12.0),
		"AC-3 the shards are drawn above the slime's death flash and are 12 px")
	Engine.time_scale = 1.0
	await _wait_until(func(): return _outcomes.size() > 0, 3.0)
	await _wait_scene_settled()   # the win's COMBAT_EXIT must finish before the next test reads current_scene
	_end_arena(arena)
	await process_frame


# ── AC-4: the tutorial retry ──────────────────────────────────────────────

func _test_retry() -> void:
	print("[AC-4 dying is a tutorial retry with a fresh slime]")
	var gm := _gm()
	var arena := await _start_arena()
	var old = _slime(arena)
	_freeze(old)
	var old_id := old.get_instance_id()
	var glitch_before: float = gm.glitch_meter
	var scene_before := current_scene
	_hurt_player(arena)
	_check(arena.player.is_dead, "AC-4 the player dies")
	var ok := await _wait_until(func(): return arena.story_fight_retries == 1, 8.0)
	_check(ok, "AC-4 the retry runs after the death animation")
	var fresh = _slime(arena)
	_check(fresh != null and fresh.get_instance_id() != old_id and fresh.current_health == fresh.max_health and fresh.visible,
		"AC-4 a fresh StoryFightSlime at full HP (a new instance), not the old one reset")
	_check(not is_instance_valid(old) or (old.name == "StoryFightSlime_old" and not old.visible and old.collision_layer == 0),
		"AC-4 the old slime is disabled, hidden and renamed at once")
	_check(not arena.player.is_dead and arena.player.current_health == arena.player.max_health and gm.player_stats.get("hp", 0) == int(arena.player.max_health)
		and arena.player.global_position.distance_to(arena._story_cfg["player_spawn"]) < 4.0,
		"AC-4 the player is restored at the spawn with full HP")
	_check(gm.glitch_meter == glitch_before and not gm.has_flag("player_died") and current_scene == scene_before and is_instance_valid(arena),
		"AC-4 no corruption, player_died unset, no game over: still in the arena")
	_check(_time_requests_empty(), "AC-4 time scale 1.0 and no ContextStack entry after the retry")
	await _wait(1.0)
	_check(not is_instance_valid(old), "AC-4 the old slime is freed about 0.6 s later")
	_end_arena(arena)
	await process_frame


func _test_retry_pounce_and_repeats() -> void:
	print("[AC-4 a death during the pounce windup, and three retries in a row]")
	var gm := _gm()
	var arena := await _start_arena()
	var old = _slime(arena)
	_freeze(old)               # no physics: a pounce that acts leaves its velocity set
	var old_id := old.get_instance_id()
	_hurt_player(arena)
	# The pounce starts on the retry's own clock (game time, pause-aware, from the same frame), so its 0.28 s
	# windup ends at 1.13 s, after the 1.0 s retry: the pounce is in flight across the retry.
	await create_timer(0.85, false).timeout
	old._perform_pounce()
	await _wait_until(func(): return arena.story_fight_retries == 1, 8.0)
	var cur = _slime(arena)
	_freeze(cur)
	# game time, from the retry (1.0 s): past the windup's end (1.13 s), before the old slime is freed (1.6 s)
	await create_timer(0.3, false).timeout
	_check(cur != null and cur.get_instance_id() != old_id, "AC-4 after a death during a pounce the slime is a fresh instance")
	# The old slime is still alive (freed 0.6 s after the retry) and frozen: had its pounce acted past the windup,
	# its velocity would be set. The retry marks it DEAD, so the pounce's _safe() check stops it.
	_check(is_instance_valid(old) and is_zero_approx(old.velocity.x),
		"AC-4 a pounce whose windup ends after the retry never acts (old slime velocity %.0f)" % (old.velocity.x if is_instance_valid(old) else -1.0))
	await _wait(1.0)           # past the 0.75 s of invulnerability
	_check(arena.player.current_health == arena.player.max_health and not arena.player.is_dead,
		"AC-4 after a death during the windup the player is still at full HP after the restore")
	for n in [2, 3, 4]:
		await _wait(1.0)       # the restore gives 0.75 s of invulnerability
		_hurt_player(arena)
		await _wait_until(func(): return arena.story_fight_retries == n, 8.0)
		await process_frame
		_freeze(_slime(arena))
		_check(arena.story_fight_retries == n and _time_requests_empty() and not arena.player.is_dead,
			"AC-4 retry %d of 3: time scale 1.0, no ContextStack entry or time-scale request" % (n - 1))
	_end_arena(arena)
	await process_frame


func _test_player_died_first() -> void:
	print("[AC-4 D5: the player dies first, the slime inside the death window]")
	var gm := _gm()
	var arena := await _start_arena()
	var slime = _slime(arena)
	_freeze(slime)
	var transitions_before := _transitions
	_hurt_player(arena)
	await _wait(0.2)
	slime.take_damage(slime.max_health)
	_check(_shards(arena).is_empty() and not gm.has_flag("ch1_slime_fought") and not gm.has_flag("first_slime_defeated")
		and _outcomes.is_empty() and not arena._story_resolved,
		"D5 the slime's death is ignored: no shards, no flags, no outcome, no guard")
	var ok := await _wait_until(func(): return arena.story_fight_retries == 1, 8.0)
	await process_frame
	_check(ok and not arena.player.is_dead and gm.player_stats.get("hp", 0) == int(arena.player.max_health),
		"D5 the retry runs and the player's HP is full before anything leaves the arena")
	_check(_slime(arena) != null and _slime(arena) != slime and _transitions == transitions_before and _time_requests_empty(),
		"D5 a fresh slime, no scene change, time scale clean")
	_end_arena(arena)
	await process_frame


# ── AC-6: pause ───────────────────────────────────────────────────────────

func _test_pause() -> void:
	print("[AC-6 pause stops the retry]")
	var cs := get_root().get_node("ContextStack")
	var arena := await _start_arena()
	var slime = _slime(arena)
	var slime_id := slime.get_instance_id()
	_hurt_player(arena)
	await _wait(0.15)
	_check(cs.push(&"pause", arena), "AC-6 the pause context opens")
	await process_frame
	# Lifted off the ground: unpaused, gravity would pull it down (an idle slime out of range would not move).
	slime.global_position.y -= 120.0
	var slime_pos: Vector2 = slime.global_position
	await _wait(2.5)
	_check(arena.story_fight_retries == 0 and arena.player.is_dead and arena.player.current_health == 0.0
		and _slime(arena) != null and _slime(arena).get_instance_id() == slime_id and _slime(arena).global_position.distance_to(slime_pos) < 1.0,
		"AC-6 paused for 2.5 s: no retry, the player still dead at HP 0, the same slime in the same place (in the air)")
	# Two things refuse it here: the story-mode guard, and ContextStack, which opens no exclusive context over
	# the pause in any arena mode. Removing either alone leaves it refused (the guard alone is AC-2's check);
	# the mutation run removes both. A target is set so neither "no target" return can stand in for them.
	arena.slime = slime
	arena._open_root_access()
	_check(not cs.is_open(&"root_access") and not arena.root_access_active,
		"AC-6 Root Access is refused while paused (the story guard and ContextStack's pause both refuse it)")
	cs.pop(&"pause")
	var ok := await _wait_until(func(): return arena.story_fight_retries == 1, 8.0)
	_check(ok and not arena.player.is_dead, "AC-6 resuming continues the retry")
	_end_arena(arena)
	await process_frame


# ── AC-7: joypad only ─────────────────────────────────────────────────────

func _test_gamepad_only() -> void:
	print("[AC-7 the fight is won with joypad events only]")
	var gm := _gm()
	var arena := await _start_arena()
	var slime = _slime(arena)
	_freeze(slime)
	var player = arena.player
	player.global_position = Vector2(slime.global_position.x - 90.0, slime.global_position.y)
	await _wait(0.4)
	_press_pad("move_right")
	await _wait(0.12)
	_press_pad("move_right", false)
	var won := false
	var end := Time.get_ticks_msec() + 15000
	while Time.get_ticks_msec() < end and not gm.has_flag("ch1_slime_fought"):
		player.global_position.y = slime.global_position.y
		if player.global_position.x < slime.global_position.x - 70.0 or player.global_position.x > slime.global_position.x - 20.0:
			player.global_position.x = slime.global_position.x - 45.0
		_press_pad("attack")
		await _wait(0.08)
		_press_pad("attack", false)
		await _wait(0.45)
	won = gm.has_flag("ch1_slime_fought")
	_check(won, "AC-7 the slime is beaten with pad attack and move events only")
	await _wait_until(func(): return _outcomes.size() > 0, 3.0)
	_check(_outcomes == ["win"], "AC-7 the win outcome is emitted")
	_end_arena(arena)
	await _wait_scene_settled()
