extends SceneTree
## Tests for ContextStack — the single owner of pause, open menus and
## Engine.time_scale — and for the bugs it replaces (review R1).
## Run: tests/run_phase0_tests.ps1 -Script res://tests/context_stack_test.gd

const REGION_SCENE := "res://scenes/regions/fractured_wastes_region.tscn"

var _passes := 0
var _failures: Array[String] = []


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	await process_frame
	await process_frame
	if not OS.get_user_data_dir().contains("aeth_phase0_test"):
		push_error("Refusing to run: user data dir is not isolated. Use tests/run_phase0_tests.ps1.")
		quit(2)
		return
	await _test_contexts()
	await _test_time_scale()
	await _test_pause_menu_and_map()
	await _test_owner_scene_change()
	await _test_juice_and_hitstop()
	await _test_journal_and_shop()
	print("")
	print("CONTEXT RESULT: %d passed, %d failed" % [_passes, _failures.size()])
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


func _cs() -> Node: return get_root().get_node("ContextStack")
func _wait(s: float) -> void: await create_timer(s, true, false, true).timeout


func _key_event(action: String) -> InputEventAction:
	var ev := InputEventAction.new()
	ev.action = action
	ev.pressed = true
	return ev


func _test_contexts() -> void:
	print("[contexts]")
	var cs := _cs()
	cs.clear()
	_check(not paused, "starts unpaused")
	_check(cs.push(&"a"), "push a")
	_check(paused and cs.is_open(&"a") and cs.top() == &"a", "a pauses the tree")
	_check(cs.changed_this_frame(), "changed_this_frame() right after a push")
	_check(not cs.push(&"b"), "exclusive: b refused while a is open")
	_check(cs.push(&"over", null, true, true, false) and cs.top() == &"over", "non-exclusive context stacks on top")
	cs.pop(&"over")
	_check(paused and cs.top() == &"a", "popping the top keeps the one below")
	cs.pop(&"a")
	_check(not paused and not cs.any_open(), "last pop unpauses")
	_check(cs.push(&"overlay", null, false, false) and not paused and not cs.gameplay_blocked(), "non-pausing, non-blocking overlay")
	cs.pop(&"overlay")
	var owner := Node.new()
	get_root().add_child(owner)
	cs.push(&"owned", owner)
	owner.queue_free()
	await process_frame
	_check(not cs.is_open(&"owned") and not paused, "context closes when its owner leaves the tree")
	cs.push(&"x")
	cs.clear()
	_check(not paused and not cs.any_open(), "clear() closes everything")


func _test_time_scale() -> void:
	print("[time scale]")
	var cs := _cs()
	cs.clear_time_scale()
	cs.request_time_scale(&"slow", 0.5, 10)
	_check(is_equal_approx(Engine.time_scale, 0.5), "single request applies")
	cs.request_time_scale(&"stop", 0.05, 30)
	_check(is_equal_approx(Engine.time_scale, 0.05), "higher priority wins")
	cs.request_time_scale(&"also_slow", 0.3, 10)
	cs.release_time_scale(&"stop")
	_check(is_equal_approx(Engine.time_scale, 0.3), "after release, the slower of equal priorities wins")
	cs.release_time_scale(&"slow")
	cs.release_time_scale(&"also_slow")
	_check(is_equal_approx(Engine.time_scale, 1.0), "no requests = 1.0")
	cs.request_time_scale(&"stuck", 0.2, 10)
	cs.clear_time_scale()
	_check(is_equal_approx(Engine.time_scale, 1.0), "clear_time_scale() drops everything")


func _test_pause_menu_and_map() -> void:
	print("[pause menu + world map]")
	var cs := _cs()
	var gm := get_root().get_node("GameManager")
	var pause := get_root().get_node("PauseScreen")
	var world_map := get_root().get_node("WorldMapUI")
	cs.clear()
	change_scene_to_file(REGION_SCENE)
	for i in 4:
		await process_frame
	gm.change_state(gm.GameState.EXPLORATION)
	get_root().get_node("DialogueManager").force_reset()

	await process_frame
	pause._input(_key_event("pause_menu"))
	_check(pause.is_paused and paused and cs.top() == &"pause", "Esc opens pause through ContextStack")
	pause._input(_key_event("pause_menu"))
	_check(pause.is_paused, "a second Esc in the same frame is ignored (one press, one action)")
	await process_frame
	pause._input(_key_event("pause_menu"))
	_check(not pause.is_paused and not paused, "Esc again closes it")

	await process_frame
	world_map._input(_key_event("world_map"))
	_check(world_map._is_open and paused and cs.top() == &"world_map", "M opens the map and pauses the world")
	pause.toggle_pause()
	_check(not pause.is_paused, "pause can't open over the map")
	var esc := _key_event("ui_cancel")
	world_map._input(esc)
	pause._input(_key_event("pause_menu"))  # the same Esc press, reaching pause next
	_check(not world_map._is_open and not pause.is_paused and not paused,
		"one Esc closes the map without also opening pause")


func _test_owner_scene_change() -> void:
	print("[scene change with a menu open]")
	var cs := _cs()
	cs.clear()
	await process_frame
	cs.push(&"root_access", current_scene)  # e.g. the arena's Root Access panel
	_check(paused, "scene-owned context pauses")
	paused = false  # let the scene change run (as a transition would)
	change_scene_to_file(REGION_SCENE)
	for i in 4:
		await process_frame
	_check(not cs.is_open(&"root_access") and not paused, "new scene doesn't load paused when the old scene's panel was open")


func _test_juice_and_hitstop() -> void:
	print("[slow-mo + hitstop]")
	var cs := _cs()
	cs.clear()
	cs.clear_time_scale()
	var juice := get_root().get_node("GameJuice")
	var fx := get_root().get_node("CombatFX")
	juice._time_wobble(0.3)
	await process_frame
	await process_frame
	_check(is_equal_approx(Engine.time_scale, 0.6), "wobble survives past one frame (old fail-safe killed it)")
	fx.apply_hitstop(0.1)
	_check(Engine.time_scale <= 0.08, "hitstop overrides wobble")
	await _wait(0.6)
	_check(is_equal_approx(Engine.time_scale, 1.0), "everything released afterwards (%.2f)" % Engine.time_scale)
	cs.request_time_scale(&"leftover", 0.3, 10)
	get_root().get_node("SceneTransitions").change_scene(REGION_SCENE)
	await _wait(2.0)
	_check(is_equal_approx(Engine.time_scale, 1.0), "scene transition clears leftover slow-mo")


func _test_journal_and_shop() -> void:
	print("[lore journal + shop]")
	var cs := _cs()
	var gm := get_root().get_node("GameManager")
	cs.clear()
	gm.change_state(gm.GameState.EXPLORATION)
	get_root().get_node("DialogueManager").force_reset()
	var journal := get_root().get_node("LoreJournal")
	var l := _key_event("lore_journal")
	journal._input(l)
	_check(journal._is_open and paused, "L opens the journal and pauses")
	journal._input(l)
	_check(not journal._is_open and not paused, "L closes it")
	gm.change_state(gm.GameState.MENU)
	journal._input(l)
	_check(not journal._is_open, "journal doesn't open on the title screen")
	gm.change_state(gm.GameState.EXPLORATION)

	var shop := get_root().get_node("ShopSystem")
	var closed := [false]
	var on_closed := func(): closed[0] = true
	shop.shop_closed.connect(on_closed)
	cs.push(&"pause")  # another menu is open
	shop.open_shop("general")
	await process_frame
	await process_frame
	_check(not shop._is_open and closed[0], "refused shop still emits shop_closed (no softlock for awaiting callers)")
	shop.shop_closed.disconnect(on_closed)
	cs.clear()
