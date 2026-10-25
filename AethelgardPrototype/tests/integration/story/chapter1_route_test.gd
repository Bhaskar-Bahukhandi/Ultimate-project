extends SceneTree
## Plays Chapter 1 end to end on the rewritten dialogue (dialogue/prologue,
## dialogue/ch1): crash site → Elara → Broken Mile → Oakhaven → Elara's house
## (the stew) → Oakhaven's afternoon → Aldric → the shrine (Fragment One →
## village meeting → Elara joins) → the Chapter 1 ending.
## A fake player answers every choice from a pick list (default: first option).
## Run: tests/run_phase0_tests.ps1 -Script res://tests/integration/story/chapter1_route_test.gd

const HOOK := "res://scenes/chapter1/opening_crash_site_hook.tscn"
const ELARA := "res://scenes/chapter1/elara_meeting.tscn"
const PATH := "res://scenes/chapter1/path_to_oakhaven.tscn"
const VILLAGE := "res://scenes/chapter1/oakhaven_village.tscn"
const REGION := "res://scenes/regions/oakhaven_region.tscn"
const KNIGHT := "res://scenes/chapter1/tutorial_knight_boss.tscn"
## Y1-P0-S08: the stew plays in Elara's house; the rest of Chapter 1 after Aldric in the shrine.
const HOUSE := "res://scenes/chapter1/elara_house.tscn"
const SHRINE := "res://scenes/chapter1/shrine.tscn"
const HOUSE_WRITER := "res://scripts/chapter1/ch1_elara_house.gd"
const HOUSE_DOOR_NODE := "Doors/ElaraHouseDoor"
const STEW_FIRST := "This smells amazing. What is it?"   # elara_house.dlg `start`, first line
const SHATTER := "res://scenes/chapter1/shatter_transition.tscn"
const GATE := "res://scenes/chapter2/ironhold_gate.tscn"
const SHATTER_DLG := "res://dialogue/ch1/shatter.dlg"
## AC-9: wording from the old shatter script, and "*" for a *stage direction*.
const OLD_SCRIPT := ["412", "iterations", "at that bridge", "AetherCorp", "Chapter 1", "side-scroll", "top-down", "gravity", "Welcome to", "*"]

var _passes := 0
var _failures: Array[String] = []
var _driving := false
var _picks: Array = []
var _seen_text: Array[String] = []
var _shatter_mark := 0            # _seen_text index where the shatter scene began
var _cam_xs: Array[float] = []    # shatter-scene camera x, one sample per frame
## Shatter-scene samples, one per frame: n (= _seen_text.size() at that frame, so
## n == i + 1 while line i is the newest), camera y, camera is_shaking, dialogue box
## visible, scene modulate.
var _samples: Array[Dictionary] = []
var _drive_gen := 0               # only the newest _drive() loop keeps running
## `do desaturate` target colour (ch1_shatter_transition.gd DESATURATE_COLOR).
const DESAT := Color(0.6, 0.6, 0.7, 1.0)
var _hold_at := ""                # the driver stops advancing while this line is on screen
var _scenes_seen := {}            # scene paths _wait_for saw current (cleared per route)


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	await process_frame
	await process_frame
	if not OS.get_user_data_dir().contains("aeth_phase0_test"):
		push_error("Refusing to run: user data dir is not isolated. Use tests/run_phase0_tests.ps1.")
		quit(2)
		return
	Engine.time_scale = 4.0
	await _test_new_game_to_region()
	await _test_aldric_kill_route()
	await _test_aldric_purge_route()
	await _test_aldric_spare_route()
	await _test_purge_cancelled()
	await _test_shatter_routing()
	await _test_shatter_old_save()
	await _test_shatter_source()
	await _test_shatter_skips()
	await _test_shatter_slow_reader()
	await _test_village_afternoon()
	await _test_crash_site_interactions()
	await _test_village_interactions()
	# Y1-P0-T05 breadcrumb tests (pure resolver cases first, then the live scenes)
	await _end_scene()
	_test_bc_table_text()
	_test_bc_flag_writers()
	_test_bc_golden_regression()
	_test_bc_any_of()
	_test_bc_load_cases()
	_test_bc_bridge_flags()
	_test_bc_dlg_objective_lines()
	_test_bc_label_format()
	_test_bc_kill_route_samples()
	_test_bc_new_flags_registered()
	await _test_bc_broken_mile_flag()
	await _test_bc_arrows_hook()
	await _test_bc_arrows_village()
	await _test_bc_stew_flag()
	await _test_bc_alarm_routes()
	Engine.time_scale = 1.0
	print("")
	print("CH1 RESULT: %d passed, %d failed" % [_passes, _failures.size()])
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


func _gm() -> Node: return get_root().get_node("GameManager")
func _dm() -> Node: return get_root().get_node("DialogueManager")


## Advances lines and answers choices from _picks (first option when empty).
## Records every line shown, so the test can check which script played.
func _drive(gen: int) -> void:
	var dm := _dm()
	while _driving and gen == _drive_gen:
		if dm._is_visible and dm._text_label and dm._text_label.text != "":
			var line: String = "%s: %s" % [dm._speaker_label.text, dm._text_label.text]
			if _seen_text.is_empty() or _seen_text.back() != line:
				_seen_text.append(line)
		var sc = current_scene
		if sc and sc.scene_file_path == SHATTER and sc.get("camera") != null:
			_cam_xs.append(sc.camera.global_position.x)
			_samples.append({"n": _seen_text.size(), "y": sc.camera.global_position.y,
				"shake": sc.camera.is_shaking, "box": dm._is_visible, "mod": sc.modulate})
		if dm._awaiting_choice:
			if dm._choice_result == -1 and dm._choice_container != null:
				dm._on_choice_pressed(_picks.pop_front() if not _picks.is_empty() else 0)
		elif dm._is_visible and not (_hold_at != "" and not _seen_text.is_empty() and _seen_text.back().contains(_hold_at)):
			dm._skip_typing = true
			dm._advance_requested = true
		await process_frame


func _start(picks: Array) -> void:
	_picks = picks.duplicate()
	if not _driving:
		_driving = true
		_drive_gen += 1   # a loop told to stop this frame must not carry on beside the new one
		_drive(_drive_gen)


func _saw(fragment: String) -> bool:
	return _seen_text.any(func(l): return l.contains(fragment))


## Waits for `path`, poking scenes that need the player to do something.
func _wait_for(path: String, timeout_sec: float) -> bool:
	var deadline := Time.get_ticks_msec() + int(timeout_sec * 1000.0)
	var next_poke := 0
	var st := get_root().get_node("SceneTransitions")
	while Time.get_ticks_msec() < deadline:
		var s := current_scene
		if s:
			_scenes_seen[s.scene_file_path] = true
		if s and s.scene_file_path == path and not st.is_transitioning:
			return true
		if s and s.scene_file_path == PATH and s.get("root_access_tutorial_active") and not s.get("guardian_resolved"):
			s._target_filter.select(1)     # TARGET FILTER: ALL → FRACTURE_ENTITIES
			s._on_root_access_apply()
		elif s and not st.is_transitioning and Time.get_ticks_msec() >= next_poke and _poke_room(s):
			next_poke = Time.get_ticks_msec() + 1000
		await process_frame
	return false


## One "walk up and press interact" for the scenes that wait on the player
## (Y1-P0-S08 placement). Returns true when it poked something.
##   village: after the invite, Elara's door; after the stew, the bridge.
##   house:   once the stew is done, the door back out.
##   shrine:  once the arrival card is over, the altar, then the stair door.
func _poke_room(s: Node) -> bool:
	var player := s.get_node_or_null("Player")
	if player == null:
		return false
	match s.scene_file_path:
		VILLAGE:
			if s.get("_entrance_done") and not s.get("in_dialogue"):
				s._on_bridge_trigger(player)   # walk to the bridge
				return true
			if s.get("_invited") and not s.get("_entrance_done") and not s._busy():
				s._on_elara_house_door_interaction(player)   # walk to Elara's door
				return true
		HOUSE:
			if _gm().has_flag("ch1_stew_done") and not s._busy():
				s._on_door_interaction(player)   # back out to the village
				return true
		SHRINE:
			if not s._busy():
				if not _gm().has_flag("source_key_fragment_1"):
					s._on_altar_interaction(player)
				else:
					s._on_stair_door_interaction(player)
				return true
	return false


func _test_new_game_to_region() -> void:
	print("[New Game → Oakhaven region]")
	var gm := _gm()
	gm.reset_game()
	_seen_text.clear()
	_scenes_seen.clear()
	change_scene_to_file(HOOK)
	for i in 4:
		await process_frame
	# trust Elara; ask about her arm; help with the field; edit the sluice
	# (current terrain); fight the boar; fix the bridge. Stew topics take the
	# first remaining option each time until "(Just eat.)".
	_start([0, 0])
	var hook := current_scene
	var deadline := Time.get_ticks_msec() + 30000
	while hook._dialogue_busy and Time.get_ticks_msec() < deadline:
		await process_frame
	hook._on_signalfragment_interaction(hook._player)
	while hook._dialogue_busy and Time.get_ticks_msec() < deadline:
		await process_frame
	hook._complete_opening_hook()
	_check(await _wait_for(ELARA, 60.0), "crash site → Elara meeting")
	_check(await _wait_for(PATH, 240.0), "Elara meeting → Broken Mile")
	_check(_saw("Is that a place?") and gm.has_flag("elara_first_truth") and gm.has_flag("ch1_elara_trusted"),
		"Elara meeting plays elara_meeting.dlg; 'trust' keeps the legacy flag")
	_check(await _wait_for(VILLAGE, 300.0), "Broken Mile → Oakhaven")
	_check(gm.has_flag("ch1_data_vision_unlocked") and gm.has_flag("root_access_unlocked") and gm.has_flag("ch1_root_first_edit"),
		"Data Vision and Root Access unlock; the target-filter edit counts as the first Root edit")
	_check(_saw("Changed what it thinks it's defending against") and _saw("metadata"), "Broken Mile plays broken_mile.dlg (filter branch)")
	_check(await _wait_for(REGION, 420.0), "Oakhaven → the region (stopped at %s)" % (current_scene.scene_file_path if current_scene else "?"))
	_check(gm.has_flag("ch1_oakhaven_entered") and gm.has_flag("ch1_northfall_registry_seen"), "gate and road ledger played (Northfall entry seen)")
	_check(gm.has_flag("ch1_stew_asked_where") and gm.has_flag("ch1_elara_arm_talked") and _scenes_seen.has(HOUSE) and gm.has_flag("ch1_stew_done"),
		"stew topics played (in Elara's house, through her door and back: house seen %s)" % _scenes_seen.has(HOUSE))
	var field_flags := ["ch1_north_field_helped", "ch1_sluice_edited", "ch1_boar_fought", "ch1_corrupted_boar_defeated"]
	_check(field_flags.all(func(f): return gm.has_flag(f)), "north field: helped, sluice edited, boar fought %s" % [field_flags.map(func(f): return "%s=%s" % [f, gm.has_flag(f)])])
	_check(gm.has_flag("ch1_bridge_saved"), "the bridge was fixed before dark")
	_check(not _saw("looped 412 times") and not _saw("*"), "no old-script lines or *stage directions* on screen")
	_driving = false


func _knight_scene() -> Node:
	change_scene_to_file(KNIGHT)
	for i in 4:
		await process_frame
	var k := current_scene
	var deadline := Time.get_ticks_msec() + 60000
	while not k.combat_started and Time.get_ticks_msec() < deadline:
		await process_frame
	return k


func _test_aldric_kill_route() -> void:
	print("[Aldric: kill → own it → tell the village everything]")
	var gm := _gm()
	_start([0, 0, 0])   # kill; "I ended his life."; public warning
	var knight = await _knight_scene()
	_check(knight.combat_started and _saw("Someone who should be dead"), "Aldric Returns plays before the fight")
	var fragments_before: int = gm.source_key_count
	_scenes_seen.clear()
	knight._on_boss_defeated()
	_check(await _wait_for(SHATTER, 240.0) and _scenes_seen.has(SHRINE),
		"decision → shrine: altar (fragment) → stair door (meeting → Elara joins) → Chapter 1 ending (shrine seen %s)" % _scenes_seen.has(SHRINE))
	_shatter_mark = _seen_text.size()
	_cam_xs.clear()
	_samples.clear()
	_check(gm.has_flag("ch1_knight_killed") and gm.has_flag("ch1_aldric_kill_owned"), "kill and how Kaelen owns it are recorded")
	_check(gm.has_flag("source_key_fragment_1") and gm.source_key_count == fragments_before + 1, "Fragment One is awarded and counted once")
	_check(_saw("I knew those words.") and _saw("That's the point."), "Fragment One plays the memory flash")
	_check(gm.has_flag("ch1_oakhaven_warned_villagers") and _saw("Boil your water"), "the village meeting plays (public warning)")
	_check(gm.has_flag("ch1_elara_joined") and gm.has_flag("ch1_tutorial_knight_defeated"), "Elara joins; the knight counts as defeated")
	_check(not gm.has_flag("ch1_bridge_fell"), "a fixed bridge doesn't fall")
	await _check_shatter_branch("kill", "after_kill", ["after_spare", "after_purge"], true)
	await _end_scene()


func _test_aldric_purge_route() -> void:
	print("[Aldric: purge → leave quietly; the unfixed bridge falls]")
	var gm := _gm()
	gm.reset_game()
	_seen_text.clear()
	gm.set_story_flag("ch1_bridge_evacuated", true)   # warned people off, didn't fix it
	var corruption_before: float = gm.glitch_meter
	_start([2, 0, 2])   # purge; confirm; "It's handled."
	var knight = await _knight_scene()
	_scenes_seen.clear()
	knight._on_boss_defeated()
	_check(await _wait_for(SHATTER, 240.0) and _scenes_seen.has(SHRINE), "purge route reaches the Chapter 1 ending through the shrine")
	_shatter_mark = _seen_text.size()
	_cam_xs.clear()
	_samples.clear()
	_check(gm.has_flag("ch1_root_purge") and gm.has_flag("ch1_knight_spared"), "purge keeps Aldric alive (legacy ch1_knight_spared)")
	_check(gm.glitch_meter > corruption_before, "the purge costs corruption (%.0f → %.0f)" % [corruption_before, gm.glitch_meter])
	_check(_saw("You always were a liar."), "Aldric wakes up after the purge")
	_check(gm.has_flag("ch1_bridge_fell") and _saw("Nobody was on it"), "the unfixed bridge falls after dark; evacuating it saved lives")
	_check(gm.has_flag("ch1_oakhaven_left_quietly") and _saw("They're not children"), "leaving quietly is challenged by Elara")
	await _check_shatter_branch("purge", "after_purge", ["after_spare", "after_kill"], false)
	await _end_scene()


func _idle(s: Node, timeout_sec: float = 30.0) -> void:
	var deadline := Time.get_ticks_msec() + int(timeout_sec * 1000.0)
	await process_frame
	while s._busy() and Time.get_ticks_msec() < deadline:
		var shop := get_root().get_node("ShopSystem")
		if shop.get("_is_open"):
			shop.close_shop()
		await process_frame


func _test_village_afternoon() -> void:
	print("[Oakhaven: a normal afternoon, then the alarm]")
	var gm := _gm()
	gm.reset_game()
	_seen_text.clear()
	gm.set_story_flag("ch1_elara_trusted", true)
	_start([])
	change_scene_to_file(VILLAGE)
	for i in 4:
		await process_frame
	# Y1-P0-S08: gate and ledger (and the invite) play on arrival; the stew plays in
	# Elara's house, and the afternoon starts back in the village.
	var r := await _through_house(current_scene)
	_check(r["invited"] and r["ledger_at_invite"] and not r["entrance_at_invite"] and not r["stew_before_house"],
		"gate and ledger play on arrival, then the invite; no stew in the village (%s)" % [r])
	_check(r["house"] and r["stew_done"] and _saw("Today it's both."), "the stew plays in Elara's house")
	var s: Node = r["village"]
	_check(s != null and s._entrance_done, "back through her door, the village afternoon has started")
	if s == null:
		_driving = false
		return
	var deadline := Time.get_ticks_msec() + 60000
	var player := s.get_node("Player")
	s._on_old_fen_interaction(player)
	await _idle(s)
	s._on_jessa_interaction(player)
	await _idle(s)
	_check(not s._alarm_done, "no alarm after two conversations")
	s._on_farmer_interaction(player)
	await _idle(s)
	deadline = Time.get_ticks_msec() + 60000
	while not s._field_resolved and Time.get_ticks_msec() < deadline:
		await process_frame
	await _idle(s)
	_check(_saw("Guessing.") and _saw("Plants don't ask") and _saw("That was the sluice's fault."), "Old Fen, Jessa and the farmers play their lines")
	_check(s._alarm_done and gm.has_flag("ch1_north_field_helped") and s._field_resolved, "the third conversation brings the alarm; the field gets resolved")
	s._on_child_interaction(player)
	await _idle(s)
	s._on_child_interaction(player)
	await _idle(s)
	_check(s._sword_pickup != null, "the child's lost sword appears in the world")
	s._on_sword_picked(player)
	await _idle(s)
	s._on_child_interaction(player)
	await _idle(s)
	_check(gm.has_flag("ch1_child_sword_returned") and _saw("My uncle Aldric's a knight"), "returning the sword plants 'Uncle Aldric'")
	s._on_apothecary_interaction(player)
	await _idle(s)
	_check(_saw("So you're the crater.") and gm.has_flag("ch1_mara_met"), "Mara's shop opens with her rewritten lines")
	_driving = false


## Puts the top-down player at `pos` and lets physics catch up (area enter/exit,
## the per-frame target refresh in player_topdown.gd).
func _place(player: Node2D, pos: Vector2) -> void:
	player.global_position = pos
	for i in 4:
		await physics_frame
	await process_frame


func _test_crash_site_interactions() -> void:
	print("[Crash site: prompts only where the key does something]")
	_gm().reset_game()
	_seen_text.clear()
	_start([])
	change_scene_to_file(HOOK)
	for i in 4:
		await process_frame
	var hook := current_scene
	var deadline := Time.get_ticks_msec() + 30000
	while hook._dialogue_busy and Time.get_ticks_msec() < deadline:
		await process_frame
	var player: Node2D = hook._player
	var prompt := player.get_node("InteractionPrompt") as Label
	var card: Dictionary = hook.INSPECT_POINTS.filter(func(p): return p["node"] == "safety_card")[0]
	await _place(player, card["pos"])
	_check(hook._current_target().get("kind", "") == "inspect" and prompt.visible, "next to the torn card: a Look prompt")
	_check(player.nearby_interactable == null, "the fused metal's big area no longer steals the press (it's %s from the card)" % int(card["pos"].distance_to(hook.SIGNAL_POS)))
	hook._inspect(card)
	await process_frame
	_check(not prompt.visible, "the prompt is hidden while the card's line plays")
	while hook._dialogue_busy and Time.get_ticks_msec() < deadline:
		await process_frame
	await process_frame
	_check(_saw("In the unlikely event"), "the torn card plays its own line, not the fused metal's")
	var after: Dictionary = hook._current_target()
	_check(after.get("point", {}).get("node", "") != "safety_card", "after looking, the card is no longer a target (now: %s)" % after.get("kind", "nothing"))
	var before := _seen_text.size()
	hook._inspect(card)
	await process_frame
	_check(_seen_text.size() == before and not hook._dialogue_busy, "a second look at the card does nothing (and nothing pretends it will)")
	# The sky point is far from everything else: once used, no prompt at all.
	var sky: Dictionary = hook.INSPECT_POINTS.filter(func(p): return p["node"] == "sky")[0]
	await _place(player, sky["pos"])
	hook._inspect(sky)
	await process_frame
	while hook._dialogue_busy and Time.get_ticks_msec() < deadline:
		await process_frame
	await process_frame
	_check(hook._current_target().is_empty() and not prompt.visible, "standing at a used point with nothing else in reach: no prompt")
	_driving = false


func _test_village_interactions() -> void:
	print("[Oakhaven: villagers wait for the key, and always answer]")
	_gm().reset_game()
	_seen_text.clear()
	gm_flag_trusted()
	# Y1-P0-S08: the stew happens in Elara's house; with ch1_stew_done set the village
	# skips its arrival and the afternoon (Jessa included) is open at once.
	_gm().set_story_flag("ch1_stew_done", true)
	_start([])
	change_scene_to_file(VILLAGE)
	for i in 4:
		await process_frame
	var s := current_scene
	var deadline := Time.get_ticks_msec() + 60000
	while not s._entrance_done and Time.get_ticks_msec() < deadline:
		await process_frame
	await process_frame
	var player: Node2D = s.get_node("Player")
	var jessa: Node2D = s.get_node("NPCs/Jessa")
	var dm := _dm()
	await _place(player, jessa.global_position + Vector2(0, 20))
	for i in 10:
		await physics_frame
	_check(not dm.is_active and not s.in_dialogue, "walking up to Jessa doesn't start a conversation by itself")
	_check(player.nearby_interactable == jessa and (player.get_node("InteractionPrompt") as Label).visible, "standing by Jessa: she's the target and the prompt shows")
	player._interact_with(player.nearby_interactable)
	await process_frame
	while s._busy() and Time.get_ticks_msec() < deadline:
		await process_frame
	_check(_saw("Plants don't ask"), "pressing interact plays Jessa's first conversation")
	player._interact_with(jessa)
	await process_frame
	while s._busy() and Time.get_ticks_msec() < deadline:
		await process_frame
	_check(_saw("water it"), "talking to her again gives a repeat line, not silence")
	var silent: Array = []
	for npc in s.get_node("NPCs").get_children():
		if npc.is_in_group("npc") and not npc.has_meta("interact_handler"):
			silent.append(npc.name)
	_check(silent.is_empty(), "every villager in the npc group has something to say %s" % [silent])
	var walk_ins: Array = []
	for npc in s.get_node("NPCs").get_children():
		if npc is Area2D and npc.has_meta("interact_handler") and npc.body_entered.is_connected(npc.get_meta("interact_handler")):
			walk_ins.append(npc.name)
	_check(walk_ins.is_empty(), "no villager talks on walk-in %s" % [walk_ins])
	_driving = false


func gm_flag_trusted() -> void:
	_gm().set_story_flag("ch1_elara_trusted", true)


# ── T04: the shatter scene runs shatter.dlg ──────────────────────────────────

## Lines the shatter scene showed (from the arrival mark to the end card, which is
## outside T04: it still says "Chapter 1 Complete").
func _shatter_lines() -> Array:
	var lines: Array = _seen_text.slice(_shatter_mark)
	var end := lines.find_custom(func(l): return l.contains("Chapter 1 Complete"))
	return lines if end < 0 else lines.slice(0, end)


## Ends a driven test: stops the driver (a frame later only the next test's loop runs),
## clears the box and frees the current scene, so a parked end card can't act later.
func _end_scene() -> void:
	_driving = false
	_hold_at = ""
	await process_frame
	_dm().force_reset()
	if current_scene:
		current_scene.queue_free()
	await process_frame


## Index in _seen_text of the first line (from the shatter mark) containing `fragment`, or -1.
func _line_idx(fragment: String) -> int:
	return _seen_text.find_custom(func(l): return l.contains(fragment), _shatter_mark)


## The first spoken line of a shatter.dlg node (text only), "" if it can't be found.
func _first_line(node: String) -> String:
	var d: Dictionary = _dm().line_of(SHATTER_DLG, node)
	return String(d.get("text", ""))


func _wait_saw(fragment: String, timeout_sec: float) -> bool:
	var deadline := Time.get_ticks_msec() + int(timeout_sec * 1000.0)
	while Time.get_ticks_msec() < deadline:
		if _saw(fragment):
			return true
		await process_frame
	return false


## AC-9: nothing from the old script, and no *stage directions*, on screen in the scene.
func _check_no_old_script(route: String) -> void:
	var lines := _shatter_lines()
	var hits: Array[String] = []
	for l in lines:
		for bad in OLD_SCRIPT:
			if l.contains(bad):
				hits.append("%s <- %s" % [bad, l.left(50)])
	_check(not lines.is_empty() and hits.is_empty(), "%s: no old-script wording or *stage directions* in %d shown lines %s" % [route, lines.size(), hits])


## Follows the shatter scene on the current route (AC-2 effects, AC-4, AC-9). `node` is
## this route's Aldric node; `wrong` are the other routes' nodes, which must not show.
func _check_shatter_branch(route: String, node: String, wrong: Array, check_effects: bool) -> void:
	var s = current_scene
	if check_effects:
		var shifted := await _wait_saw("The bridge is still here", 180.0)
		_check(shifted and s.modulate.r < 0.95, "%s: 'do desaturate' drains the colour during the shift (red %.2f)" % [route, s.modulate.r])
		var still_i := _line_idx("The bridge is still here")
		_check(still_i >= 0 and _samples.any(func(x): return x["n"] <= still_i and x["shake"]),
			"%s: 'do shake' shakes the camera before 'The bridge is still here' is shown" % route)
		var recon := await _wait_saw("RECONSTRUCTION COMPLETE", 180.0)
		var recon_i := _line_idx("RECONSTRUCTION COMPLETE")
		var before: Array = _samples.filter(func(x): return x["n"] <= recon_i)
		var mod: Color = before.back()["mod"] if not before.is_empty() else Color.WHITE
		_check(recon and not before.is_empty() and mod.is_equal_approx(DESAT),
			"%s: the drain has finished (modulate %s) before the first RECONSTRUCTION line" % [route, mod])
	var walking := await _wait_saw("What are we walking into", 180.0)
	if check_effects:
		var hiss_i := _line_idx("steam hissing")
		var walk_i := _line_idx("What are we walking into")
		_check(hiss_i >= 0 and walk_i > hiss_i and _samples.any(func(x): return x["n"] > hiss_i and x["n"] <= walk_i and not x["box"]),
			"%s: 'do pan_ironhold' hides the dialogue box between 'steam hissing' and 'What are we walking into'" % route)
		var at_walk: Array = _samples.filter(func(x): return x["n"] == walk_i + 1)
		var cam_y: float = at_walk[0]["y"] if not at_walk.is_empty() else -1.0
		_check(not at_walk.is_empty() and absf(cam_y - 320.0) <= 10.0, "%s: the pan settles the camera at y≈320 (y %.1f)" % [route, cam_y])
	var mark := _cam_xs.size()
	var first := _first_line(node)
	var shown := false
	if not first.is_empty():
		shown = await _wait_saw(first, 180.0)
	_check(shown, "%s: the scene shows %s's first line" % [route, node])
	var xs: Array = _cam_xs.slice(mark)
	var home: float = xs[0] if not xs.is_empty() else -1.0
	var low: float = xs.min() if not xs.is_empty() else -1.0
	var back: float = xs.back() if not xs.is_empty() else -1.0
	_check(walking and not xs.is_empty() and low <= home - 20.0 and absf(back - home) < 3.0,
		"%s: 'do look_back' swings the camera left and back (home %.0f, min %.0f, end %.0f)" % [route, home, low, back])
	for w in wrong:
		var wl := _first_line(w)
		_check(not wl.is_empty() and not _saw(wl), "%s: %s's first line never shows" % [route, w])
	var ended := await _wait_saw("Okay. Walls first.", 180.0)
	_check(ended, "%s: the scene reaches onward's last line" % route)
	_check_no_old_script(route)


## Plays aldric.dlg with `picks` (kill / spare / purge) and waits at the shatter scene.
func _route_to_shatter(picks: Array) -> bool:
	var gm := _gm()
	gm.reset_game()
	_dm().force_reset()   # the box may still hold the last test's text
	_seen_text.clear()
	_cam_xs.clear()
	_samples.clear()
	_hold_at = ""
	_start(picks)
	var knight = await _knight_scene()
	_scenes_seen.clear()
	knight._on_boss_defeated()
	var ok: bool = await _wait_for(SHATTER, 240.0) and _scenes_seen.has(SHRINE)
	_shatter_mark = _seen_text.size()
	return ok


func _test_aldric_spare_route() -> void:
	print("[Aldric: spare → warn the village]")
	var gm := _gm()
	var ok := await _route_to_shatter([1, 0])   # hold him; public warning
	_check(ok, "spare route reaches the Chapter 1 ending")
	_check(gm.has_flag("ch1_knight_spared") and not gm.has_flag("ch1_root_purge") and not gm.has_flag("ch1_knight_killed"), "spare sets only ch1_knight_spared")
	await _check_shatter_branch("spare", "after_spare", ["after_kill", "after_purge"], false)
	await _end_scene()


func _test_purge_cancelled() -> void:
	print("[Aldric: purge prompt → 'No. Not like this. Hold him instead.']")
	var gm := _gm()
	var ok := await _route_to_shatter([2, 1, 0])   # purge; cancel; public warning
	_check(ok, "cancelled purge reaches the Chapter 1 ending")
	_check(not gm.has_flag("ch1_root_purge") and gm.has_flag("ch1_knight_spared"), "cancelled purge: ch1_root_purge false, ch1_knight_spared true")
	await _check_shatter_branch("purge cancelled", "after_spare", ["after_purge", "after_kill"], false)
	await _end_scene()


## AC-5: shatter.dlg from `start` with preset flags (no scene): 4 Aldric routes x 4 village routes.
func _test_shatter_routing() -> void:
	print("[shatter.dlg: every Aldric route x every village route ends at onward]")
	if current_scene:
		current_scene.queue_free()
		await process_frame
		await process_frame
	var gm := _gm()
	_shatter_mark = 0
	var aldric := {
		"purge": [["ch1_root_purge", "ch1_knight_spared"], "after_purge"],
		"kill": [["ch1_knight_killed"], "after_kill"],
		"spare": [["ch1_knight_spared"], "after_spare"],
		"none": [[], "after_none"],
	}
	var village := {
		"warned_villagers": ["ch1_oakhaven_warned_villagers", "village_warned"],
		"warned_leaders": ["ch1_oakhaven_warned_leaders", "village_leaders"],
		"left_quietly": ["ch1_oakhaven_left_quietly", "village_quiet"],
		"none": ["", "village_none"],
	}
	for a in aldric:
		for v in village:
			gm.reset_game()
			_dm().force_reset()
			_seen_text.clear()
			for f in aldric[a][0]:
				gm.set_story_flag(f, true)
			if village[v][0] != "":
				gm.set_story_flag(village[v][0], true)
			_hold_at = ""
			_start([])
			var r: Dictionary = await _dm().run(SHATTER_DLG, "start", func(_e: String) -> void: pass)
			var a_line := _first_line(aldric[a][1])
			var v_line := _first_line(village[v][1])
			_check(r.get("ok", false) and r.get("end_node", "") == "onward" and _saw("Okay. Walls first.")
				and not a_line.is_empty() and _saw(a_line) and not v_line.is_empty() and _saw(v_line),
				"aldric=%s village=%s: plays %s + %s and ends at onward (ok=%s)" % [a, v, aldric[a][1], village[v][1], r.get("ok")])
			_check_no_old_script("matrix aldric=%s village=%s" % [a, v])
	await _end_scene()


## AC-6: a save from before the rewrite (no Aldric flag, no village flag), full scene.
func _test_shatter_old_save() -> void:
	print("[Shatter scene: old save with no Aldric and no village flag]")
	var gm := _gm()
	gm.reset_game()
	_dm().force_reset()   # the box may still hold the last test's text
	_seen_text.clear()
	_cam_xs.clear()
	_samples.clear()
	_hold_at = ""
	_start([])
	change_scene_to_file(SHATTER)
	for i in 4:
		await process_frame
	_shatter_mark = 0
	var none_line := await _wait_saw(_first_line("after_none"), 180.0)
	var vnone_line := await _wait_saw(_first_line("village_none"), 180.0)
	_check(none_line and vnone_line, "no flags: after_none then village_none play")
	var card := await _wait_saw("Chapter 1 Complete. Press", 180.0)
	_check(card and gm.has_flag("ch1_complete") and gm.current_chapter == 2, "the scene continues to the end card (ch1_complete set)")
	_check_no_old_script("old save")
	await _end_scene()


## AC-1 / AC-2: the scene script holds no spoken lines; its event handler never hangs.
func _test_shatter_source() -> void:
	print("[Shatter scene script: no spoken lines, events handled]")
	var path := "res://scripts/chapter1/ch1_shatter_transition.gd"
	var src := FileAccess.get_file_as_string(path)
	var bodies := {}
	var cur := ""
	for line in src.split("\n"):
		if line.begins_with("func "):
			cur = line.get_slice("(", 0).trim_prefix("func ")
			bodies[cur] = ""
		elif cur != "":
			bodies[cur] += line + "\n"
	_check(src.contains('const SHATTER_DLG := "res://dialogue/ch1/shatter.dlg"'), "SHATTER_DLG points at shatter.dlg")
	var nodes := {"play_bridge_approach": "bridge", "play_environmental_shift": "shift",
		"play_the_shatter": "reconstruct", "play_post_shatter_dialogue": "start"}
	for fn in nodes:
		var body: String = bodies.get(fn, "")
		_check(not body.is_empty() and body.contains('DialogueManager.run(SHATTER_DLG, "%s", _on_dlg_event)' % nodes[fn]), "%s runs the '%s' node" % [fn, nodes[fn]])
		_check(not body.contains("DialogueManager.say(") and not body.contains('"type": "dialogue"') and not body.contains("has_elara") and not body.contains("story_flags.get("),
			"%s holds no say(), no dialogue beat, no has_elara / flag branch" % fn)
	var script: GDScript = load(path)
	var node = script.new()
	var done := [false]
	var probe := func() -> void:
		await node._on_dlg_event("not_an_event")
		done[0] = true
	probe.call()
	_check(done[0], "an unknown dialogue event returns at once (no hang)")
	node.free()


## Hold ui_cancel (the scene's own hold-to-skip) until it completes.
func _hold_cancel(scene: Node) -> bool:
	var press := InputEventAction.new()
	press.action = &"ui_cancel"
	press.pressed = true
	Input.parse_input_event(press)
	var deadline := Time.get_ticks_msec() + 20000
	while is_instance_valid(scene) and not scene._skip_completed and Time.get_ticks_msec() < deadline:
		await process_frame
	var done: bool = is_instance_valid(scene) and scene._skip_completed
	var release := InputEventAction.new()
	release.action = &"ui_cancel"
	release.pressed = false
	Input.parse_input_event(release)
	return done


## AC-8 / AC-12: hold-to-skip while the line containing `marker` is on screen. The run
## stops, the flags and the reward land once, the scene changes once, and none of the
## `later` lines is ever shown.
func _skip_during(label: String, marker: String, later: Array) -> void:
	var gm := _gm()
	var inv := get_root().get_node("Inventory")
	var st := get_root().get_node("SceneTransitions")
	gm.reset_game()
	_dm().force_reset()
	_seen_text.clear()
	_cam_xs.clear()
	_samples.clear()
	gm.set_story_flag("ch1_knight_killed", true)   # SLAIN: the reward is Data Ore x1
	var ore_before: int = inv.get_item_count("data_ore")
	var changes := [0]
	var count := func() -> void: changes[0] += 1
	st.transition_midpoint.connect(count)
	_hold_at = marker
	_start([])
	change_scene_to_file(SHATTER)
	for i in 4:
		await process_frame
	var scene = current_scene
	var reached := await _wait_saw(marker, 180.0)
	var skipped := false
	if reached:
		skipped = await _hold_cancel(scene)
	var gate := false
	if skipped:
		gate = await _wait_for(GATE, 120.0)
	_driving = false
	_hold_at = ""
	st.transition_midpoint.disconnect(count)
	_check(reached and skipped, "%s: hold-to-skip completes while '%s' is on screen" % [label, marker])
	_check(gate and changes[0] == 1, "%s: the scene changes exactly once, to ironhold_gate (%d changes)" % [label, changes[0]])
	_check(gm.has_flag("ch1_shatter_witnessed") and gm.has_flag("ch1_complete") and gm.current_chapter == 2, "%s: shatter_witnessed, ch1_complete and chapter 2 are set" % label)
	_check(inv.get_item_count("data_ore") == ore_before + 1, "%s: the Aldric reward is granted exactly once (data_ore %d → %d)" % [label, ore_before, inv.get_item_count("data_ore")])
	_check(later.all(func(t): return not _saw(t)), "%s: no later node starts after the skip %s" % [label, later])
	await _end_scene()


func _test_shatter_skips() -> void:
	print("[Shatter scene: hold-to-skip during each node]")
	await _skip_during("skip in bridge", "Oakhaven ends where the oak does", ["lamps back in Oakhaven", "RECONSTRUCTION COMPLETE", "Everything's heavier"])
	await _skip_during("skip in shift", "REGION BOUNDARY", ["RECONSTRUCTION COMPLETE", "Everything's heavier"])
	await _skip_during("skip in reconstruct", "RECONSTRUCTION COMPLETE", ["Everything's heavier"])
	await _skip_during("skip in start", "Everything's heavier", [_first_line("after_kill"), "Walls first"])
	await _skip_during("skip in after_kill", _first_line("after_kill"), ["Walls first"])
	await _test_stopped_run_not_ok()


## AC-8: the scene discards run()'s result, so check it directly. force_reset() is what
## hold-to-skip calls; a run it stops returns ok = false and plays nothing more.
func _test_stopped_run_not_ok() -> void:
	print("[shatter.dlg: a run stopped by force_reset() returns ok = false]")
	_dm().force_reset()
	_seen_text.clear()
	_shatter_mark = 0
	var first := _first_line("bridge")
	_hold_at = first
	_start([])
	var res := [null]
	var runner := func() -> void:
		res[0] = await _dm().run(SHATTER_DLG, "bridge", func(_e: String) -> void: pass)
	runner.call()
	var on_screen := not first.is_empty() and await _wait_saw(first, 30.0)
	_dm().force_reset()
	var deadline := Time.get_ticks_msec() + 10000
	while res[0] == null and Time.get_ticks_msec() < deadline:
		await process_frame
	for i in 3:
		await process_frame
	var ok_after: Variant = res[0].get("ok") if res[0] != null else "no result"
	_check(on_screen and res[0] != null and res[0].get("ok", true) == false, "a run stopped mid-line returns ok = false (ok=%s)" % [ok_after])
	_check(on_screen and not _saw("Oakhaven ends where the oak does"), "the stopped run never shows the node's second line")
	await _end_scene()


## A slow reader holds the lamps line (just after `do desaturate`) until the 3 s drain is
## over: the drain is not awaited at the event, and the scene must not wait on the
## finished tween afterwards.
func _test_shatter_slow_reader() -> void:
	print("[Shatter scene: a slow reader on the lamps line]")
	var gm := _gm()
	gm.reset_game()
	_dm().force_reset()
	_seen_text.clear()
	_cam_xs.clear()
	_samples.clear()
	_shatter_mark = 0
	var lamps := "lamps back in Oakhaven"
	_hold_at = lamps
	_start([])
	change_scene_to_file(SHATTER)
	for i in 4:
		await process_frame
	var held := await _wait_saw(lamps, 180.0)
	# Hold until the 3 s drain is over, as a slow reader would. (Bounded; not a fixed real
	# time: scene changes reset Engine.time_scale, so game time per real second varies.)
	var until := Time.get_ticks_msec() + 15000
	while Time.get_ticks_msec() < until and not (is_instance_valid(current_scene) and current_scene.modulate.is_equal_approx(DESAT)):
		await process_frame
	for i in 10:
		await process_frame
	_hold_at = ""
	var recon := await _wait_saw("RECONSTRUCTION COMPLETE", 60.0)
	var li := _line_idx(lamps)
	var reds: Array = _samples.filter(func(x): return x["n"] == li + 1).map(func(x): return x["mod"].r)
	_check(held and reds.any(func(r): return r > 0.6 and r < 0.95),
		"'do desaturate' isn't awaited at the event: red is mid-drain while the lamps line shows (%d samples)" % reds.size())
	_check(held and reds.any(func(r): return is_equal_approx(r, 0.6)), "a slow reader sees the drain finish on the lamps line")
	_check(recon, "after a slow read the scene still reaches RECONSTRUCTION COMPLETE (no wait on a finished tween)")
	await _end_scene()


# ══ Y1-P0-T05: Chapter 1 breadcrumb objectives ═══════════════════════════════
# Story: production/epics/y1-p0-stabilize/story-t05-ch1-breadcrumbs.md (AC-1..AC-8).
# Pure cases call ProgressionBreadcrumb.resolve_objective(); live cases drive the
# real village / crash-site scenes. The golden file is frozen (do not regenerate).

const BC_GOLDEN := "res://tests/integration/story/breadcrumb_golden.json"
const BC_BIBLE := "res://story/STORY_BIBLE.md"
const BC_DLG_DIR := "res://dialogue/ch1"
const BC_BROKEN_MILE := "res://dialogue/ch1/broken_mile.dlg"
## The 11 Chapter 1 objective lines, step 0..10 (story table).
const BC_STEPS: Array = [
	"Find the plane. Look for survivors.",
	"Find people. A settlement east may know what happened to Flight 707.",
	"Reach Oakhaven. Follow the first lead on the missing passengers.",
	"Get through the Broken Mile with Elara.",
	"Ask about Flight 707. Find a safe route to Ironhold.",
	"Go to Elara's house. She's making stew.",
	"Spend the afternoon in Oakhaven. Meet the people here.",
	"Answer the alarm in the north field.",
	"Deal with the north bridge before dark.",
	"Stop Aldric.",
	"Go down to the shrine. Then decide what to tell the village.",
]
## The flag that starts each step (cumulative sets S0..S10 are prefixes of this list).
const BC_START_FLAGS: Array = [
	"ch1_opening_hook_started", "ch1_crash_trace_seen", "elara_met", "ch1_broken_mile_entered",
	"ch1_personal_goal_set", "ch1_oakhaven_entered", "ch1_stew_done", "ch1_north_field_helped",
	"ch1_corrupted_boar_defeated", "ch1_bridge_repair_accepted", "ch1_tutorial_knight_defeated",
]
const BC_BRIDGE_FLAGS: Array = ["ch1_bridge_repair_accepted", "ch1_bridge_evacuated", "ch1_bridge_ignored"]
## The six stale entries T05 replaced (the third had a hint, see _test_bc_table_text).
const BC_STALE_TEXTS: Array = [
	"Stand up. Find a signal.", "Follow the Oakhaven signal.", "Reach Oakhaven.",
	"Survive the crash site", "Defeat the Corrupted Sentinel", "Explore Oakhaven & find Elara",
]
const BC_STALE_HINT := "a village that should not know your name"
const BC_NEXT_CHAPTER := "Travel to Ironhold"
## Every story flag a Chapter 1 writer set before T05: literal names in
## set_story_flag("<name>" in scripts/chapter1/**/*.gd and `set <name>` lines in
## dialogue/ch1/*.dlg (calls passing false and `set <name> = false` excluded).
## Captured from commit d5ca821 on 2026-10-20 (git show HEAD:<path>, not the working
## tree). Update it only when a story adds a Chapter 1 progression flag with the
## user's approval (AGENTS.md: story progression is protected).
const BC_CH1_FLAG_WRITES_D5CA821: Array = [
	"ch1_aldric_kill_justified", "ch1_aldric_kill_owned", "ch1_aldric_kill_unsure",
	"ch1_aldric_outcome_reward_claimed", "ch1_apothecary_visited", "ch1_auction_house_visited",
	"ch1_awakening_complete", "ch1_boar_calmed", "ch1_boar_fought", "ch1_boar_nest_rebuilt",
	"ch1_bridge_evacuated", "ch1_bridge_fell", "ch1_bridge_ignored", "ch1_bridge_repair_accepted",
	"ch1_bridge_saved", "ch1_child_sword_found", "ch1_child_sword_returned", "ch1_complete",
	"ch1_corrupted_boar_defeated", "ch1_crafting_materials_intro_seen", "ch1_crash_trace_seen",
	"ch1_data_vision_secret_found", "ch1_data_vision_unlocked", "ch1_elara_arm_talked", "ch1_elara_cautious",
	"ch1_elara_glitch_witch_met", "ch1_elara_joined", "ch1_elara_trusted", "ch1_flight_fragment_found",
	"ch1_glitch_crater_complete", "ch1_ironhold_lead", "ch1_knight_killed", "ch1_knight_spared", "ch1_mara_met",
	"ch1_north_field_helped", "ch1_north_field_injuries", "ch1_north_field_refused",
	"ch1_northfall_registry_seen", "ch1_oakhaven_entered", "ch1_oakhaven_left_quietly",
	"ch1_oakhaven_warned_leaders", "ch1_oakhaven_warned_villagers", "ch1_opening_hook_complete",
	"ch1_opening_hook_danger_seen", "ch1_opening_hook_signal_found", "ch1_opening_hook_started",
	"ch1_personal_goal_set", "ch1_root_discovered_unused", "ch1_root_first_edit", "ch1_root_purge",
	"ch1_root_purge_used", "ch1_shatter_witnessed", "ch1_slime_root_access_tutorial", "ch1_sluice_dug",
	"ch1_sluice_edited", "ch1_sluice_isolated", "ch1_stew_asked_fracture", "ch1_stew_asked_magic",
	"ch1_stew_asked_where", "ch1_tutorial_knight_defeated", "elara_arm_noticed", "elara_arm_respected_silence",
	"elara_first_cautious", "elara_first_deflect", "elara_first_truth", "elara_met", "plane_crash_completed",
	"player_died", "root_access_unlocked", "tutorial_completed",
]
## The only flag writes T05 may add (user decision 2026-10-19).
const BC_T05_NEW_FLAGS: Array = ["ch1_broken_mile_entered", "ch1_stew_done"]
## A field run that has not returned by then counts as stalled (a check fails).
const BC_FIELD_TIMEOUT_SEC := 120.0


func _bc() -> Node: return get_root().get_node("ProgressionBreadcrumb")


func _res(flags: Dictionary) -> Dictionary: return _bc().resolve_objective(flags)


func _objectives() -> Array:
	return _bc().get_script().get_script_constant_map()["OBJECTIVES"]


## Cumulative set S`n` (flags BC_START_FLAGS[0..n]) plus `extra`, minus `drop`.
func _sset(n: int, extra: Array = [], drop: Array = []) -> Dictionary:
	var f := {}
	for i in range(n + 1):
		f[BC_START_FLAGS[i]] = true
	for e in extra:
		f[e] = true
	for d in drop:
		f.erase(d)
	return f


## Index (0..10) of the Chapter 1 step `res` resolved to, -1 if it is not one.
func _step_of(res: Dictionary) -> int:
	return BC_STEPS.find(res["text"])


## Every story flag that is true in the real GameManager (what the HUD resolves from).
func _live_flags() -> Dictionary:
	var f := {}
	for k in _gm().story_flags:
		if _gm().get_story_flag(k):
			f[k] = true
	return f


func _force_explore() -> void:
	_gm().current_state = _gm().GameState.EXPLORATION


## Resolves `flags` and checks it is exactly Chapter 1 step `want`.
func _check_step(flags: Dictionary, want: int, name: String) -> void:
	var res := _res(flags)
	var got := _step_of(res)
	_check(got == want and res["text"] == BC_STEPS[want],
		"%s -> step %d (got step %d '%s')" % [name, want, got, res["text"]])


func _read_text(path: String) -> String:
	return FileAccess.get_file_as_string(path)


## Every .gd under `dir`, recursively (res:// paths).
func _gd_files(dir: String) -> Array:
	var out: Array = []
	for f in DirAccess.get_files_at(dir):
		if f.ends_with(".gd"):
			out.append(dir.path_join(f))
	for d in DirAccess.get_directories_at(dir):
		out.append_array(_gd_files(dir.path_join(d)))
	return out


## Lines of every dialogue/ch1/*.dlg as {file, line}. Empty means the scan found nothing.
func _dlg_lines() -> Array:
	var out: Array = []
	for f in DirAccess.get_files_at(BC_DLG_DIR):
		if not f.ends_with(".dlg"):
			continue
		for l in _read_text(BC_DLG_DIR.path_join(f)).split("\n"):
			out.append({"file": f, "line": l.strip_edges()})
	return out


## Flag a .dlg `set` line writes to true, or "" (not a set line, or `set <flag> = false`).
## Mirrors dialogue_script.gd: an optional leading [if ...] condition, then
## `set <flag>` or `set <flag> = true|false`.
func _dlg_set_flag(line: String) -> String:
	var l := RegEx.create_from_string("^(\\[[^\\]]*\\]\\s*)+").sub(line.strip_edges(), "").strip_edges()
	if not l.begins_with("set "):
		return ""
	var body := l.substr(4).strip_edges()
	var value := "true"
	if body.contains("="):
		var parts := body.split("=", true, 1)
		body = parts[0].strip_edges()
		value = parts[1].strip_edges().to_lower()
	if value == "false" or body.is_empty() or body.contains(" "):
		return ""
	return body


## Literal Chapter 1 flag writes in the working tree (same rules as the frozen list):
## {"names": {name: true}, "files": int}.
func _ch1_flag_writes() -> Dictionary:
	var names := {}
	var files := 0
	var re := RegEx.create_from_string("set_story_flag\\(\\s*\"([^\"]+)\"\\s*(?:,\\s*([A-Za-z_]+))?")
	for p in _gd_files("res://scripts/chapter1"):
		files += 1
		for m in re.search_all(_read_text(p)):
			if m.get_string(2) != "false":
				names[m.get_string(1)] = true
	for f in DirAccess.get_files_at(BC_DLG_DIR):
		if not f.ends_with(".dlg"):
			continue
		files += 1
		for l in _read_text(BC_DLG_DIR.path_join(f)).split("
"):
			var flag := _dlg_set_flag(l)
			if flag != "":
				names[flag] = true
	return {"names": names, "files": files}


# AC-1a ───────────────────────────────────────────────────────────────────────
func _test_bc_table_text() -> void:
	print("[Breadcrumb AC-1a: the 11 Chapter 1 lines]")
	_gm().reset_game()
	var objs := _objectives()
	var ch1 := objs.filter(func(e): return e.get("chapter1", false))
	_check(ch1.size() == BC_STEPS.size(), "OBJECTIVES holds exactly %d Chapter 1 entries (has %d)" % [BC_STEPS.size(), ch1.size()])
	_check(_res({})["text"] == "", "no flags set -> no objective")
	for n in BC_STEPS.size():
		var res := _res(_sset(n))
		_check(res["text"] == BC_STEPS[n] and res["hint"] == "" and not res["has_target"],
			"S%d resolves to step %d exactly: '%s' (got '%s', hint '%s')" % [n, n, BC_STEPS[n], res["text"], res["hint"]])
	# Y1-P0-S08: has_target means a fixed Vector2 (Chapter 2+ only), so it stays false
	# above for S5 too; S5's arrow comes from a scene + node path instead.
	var s5 := _res(_sset(5))
	_check(s5["scene"] == VILLAGE and s5["target_node"] == HOUSE_DOOR_NODE,
		"S5 names the village scene and %s for its arrow (got '%s', '%s')" % [HOUSE_DOOR_NODE, s5["scene"], s5["target_node"]])
	_check(objs.size() > 0, "the OBJECTIVES scan found entries")
	for stale in BC_STALE_TEXTS:
		var hits := objs.filter(func(e): return e.get("text", "") == stale)
		_check(hits.is_empty(), "stale entry gone from OBJECTIVES: '%s'" % stale)
	var hint_hits := objs.filter(func(e): return String(e.get("hint", "")).contains(BC_STALE_HINT))
	_check(hint_hits.is_empty(), "stale hint gone from OBJECTIVES: '%s'" % BC_STALE_HINT)


# AC-1b ───────────────────────────────────────────────────────────────────────
func _test_bc_flag_writers() -> void:
	print("[Breadcrumb AC-1b: every table flag has a writer]")
	var table_flags := {}
	for e in _objectives():
		if not e.get("chapter1", false):
			continue
		if e.get("required", "") != "":
			table_flags[e["required"]] = true
		for f in e.get("required_any", []):
			table_flags[f] = true
		for f in e.get("blockers", []):
			table_flags[f] = true
	_check(table_flags.size() >= BC_START_FLAGS.size(), "table names %d distinct flags (derived from OBJECTIVES)" % table_flags.size())
	var dlg := _dlg_lines()
	_check(dlg.size() > 0, "dialogue/ch1 scan read %d lines" % dlg.size())
	var gd_texts: Array = []
	for p in _gd_files("res://scripts"):
		gd_texts.append({"path": p, "text": _read_text(p)})
	_check(gd_texts.size() > 0, "scripts/ scan read %d files" % gd_texts.size())
	for flag in table_flags:
		var writers: Array = []
		for d in dlg:
			if _dlg_set_flag(d["line"]) == flag:
				writers.append("%s: %s" % [d["file"], d["line"]])
		var needle := "set_story_flag(\"%s\"" % flag
		for g in gd_texts:
			for l in String(g["text"]).split("\n"):
				if l.contains(needle) and not l.contains(", false"):
					writers.append(String(g["path"]).get_file())
					break
		_check(not writers.is_empty(), "flag '%s' has a writer %s" % [flag, writers])


# AC-2a ───────────────────────────────────────────────────────────────────────
func _test_bc_golden_regression() -> void:
	print("[Breadcrumb AC-2a: Chapter 2+ results match the frozen golden baseline]")
	var gm := _gm()
	var data = JSON.parse_string(_read_text(BC_GOLDEN))
	_check(data is Dictionary and data.has("cases"), "golden file parses")
	var cases: Array = data["cases"]
	_check(cases.size() == 71, "golden file holds 71 cases (has %d)" % cases.size())
	var bc := _bc()
	for c in cases:
		gm.reset_game()
		for f in c["flags"]:
			gm.set_story_flag(f, true)
		var live := _live_flags()
		var res := _res(live)
		_force_explore()
		bc.force_refresh()
		var want_t := Vector2(c["target"][0], c["target"][1])
		var ok: bool = res["text"] == c["text"] and res["hint"] == c["hint"] \
			and res["has_target"] == c["has_target"] and res["target"] == want_t \
			and bc.get_current_objective() == c["text"] and _step_of(res) == -1 \
			and live.size() == c["flags"].size()
		_check(ok, "golden '%s' -> '%s' / has_target %s %s (got '%s', hint ok %s, target %s, live '%s', flags %d vs %d)" % [
			c["name"], c["text"], c["has_target"], want_t, res["text"], res["hint"] == c["hint"],
			res["target"], bc.get_current_objective(), live.size(), c["flags"].size()])
	var b: Dictionary = data["boundary"]
	var bset := {}
	for f in b["flags"]:
		bset[f] = true
	_check(bset.size() == 3 and bset.has("ch1_complete") and bset.has("ch1_oakhaven_entered") and bset.has("ch1_tutorial_knight_defeated"),
		"boundary set is {ch1_complete, ch1_oakhaven_entered, ch1_tutorial_knight_defeated}")
	_check(b["text"] == "Survive the crash site", "the old resolver stuck on a stale Chapter 1 entry here (so this boundary is a real change)")
	var res_b := _res(bset)
	_check(res_b["text"] == BC_NEXT_CHAPTER and _step_of(res_b) == -1,
		"boundary set resolves to '%s', never a Chapter 1 step (got '%s')" % [BC_NEXT_CHAPTER, res_b["text"]])
	var res_c := _res(_sset(10, ["ch1_complete"]))
	_check(res_c["text"] == BC_NEXT_CHAPTER and res_c["has_target"], "S10 + ch1_complete -> Chapter 2 entry with its target")


# AC-2b ───────────────────────────────────────────────────────────────────────
func _test_bc_any_of() -> void:
	print("[Breadcrumb AC-2b: any-of required and blocker lists]")
	var bc := _bc()
	# _entry_active is private by convention only; GDScript lets the test call it
	# directly on a synthetic entry, which is the only way to isolate the list logic.
	var entry := {"required_any": ["A", "B"], "blockers": ["X", "Y"], "text": "t"}
	_check(bc._entry_active(entry, {"B": true}), "required_any: eligible with only the second flag")
	_check(bc._entry_active(entry, {"A": true}), "required_any: eligible with only the first flag")
	_check(not bc._entry_active(entry, {}), "required_any: not eligible with neither flag")
	_check(not bc._entry_active(entry, {"A": true, "X": true}), "blockers: first blocker ends it")
	_check(not bc._entry_active(entry, {"A": true, "Y": true}), "blockers: second blocker ends it")
	var both := {"required": "R", "required_any": ["A", "B"], "text": "t"}
	_check(not bc._entry_active(both, {"R": true}) and not bc._entry_active(both, {"A": true}) and bc._entry_active(both, {"R": true, "A": true}),
		"required and required_any are ANDed")
	# The same logic through the real table.
	_check_step(_sset(6, ["ch1_corrupted_boar_defeated"]), 8, "S6 + boar defeated only (any-of: first flag)")
	_check_step(_sset(6, ["ch1_north_field_refused"]), 8, "S6 + refused only (any-of: second flag)")
	_check_step(_sset(6), 6, "S6 alone (neither any-of flag)")
	_check_step(_sset(6, ["ch1_north_field_helped"]), 7, "S6 + helped (ends step 6 through the blockers list)")
	_check_step(_sset(6, ["ch1_north_field_refused"]), 8, "S6 + refused (ends step 6 through the second blocker)")


# AC-3a/3b/3c/3d, AC-8b pure ──────────────────────────────────────────────────
func _test_bc_load_cases() -> void:
	print("[Breadcrumb AC-3 / AC-8b: old saves, early alarm, later flag wins, chapter end]")
	var old_save := {"ch1_oakhaven_entered": true, "ch1_personal_goal_set": true, "elara_met": true, "ch1_mara_met": true}
	_check_step(old_save, 5, "AC-3a old save (no stew_done, no broken_mile_entered)")
	_check_step(_sset(6, ["ch1_north_field_helped"]), 7, "AC-3b S6 + helped, no boar flag")
	_check_step(_sset(7, ["ch1_corrupted_boar_defeated"]), 8, "AC-3b same + boar defeated")
	_check_step(_sset(10, [], ["ch1_stew_done"]), 10, "AC-3c S10 without ch1_stew_done: the later flag wins")
	_check_step({"ch1_tutorial_knight_defeated": true}, 10, "AC-3c only the knight flag set")
	_check_step(_sset(10, ["ch1_elara_joined"]), 10, "AC-3d S10 + ch1_elara_joined, no ch1_complete")
	var done := _res(_sset(10, ["ch1_elara_joined", "ch1_complete"]))
	_check(done["text"] == BC_NEXT_CHAPTER and _step_of(done) == -1, "AC-3d + ch1_complete -> Chapter 2 entry (got '%s')" % done["text"])
	_check_step(_sset(6, ["ch1_north_field_refused"]), 8, "AC-8b S6 + refused skips step 7")
	var s6_only := _res(_sset(6))
	_check(s6_only["text"] == BC_STEPS[6], "AC-8b S6 alone is still step 6 (so the refused result above is a real move)")
	# Unreachable in play (north_field.dlg's help and refuse branches are exclusive);
	# documents what latest-step-wins does with it: step 8 (refused satisfies its any-of).
	_check_step(_sset(6, ["ch1_north_field_helped", "ch1_north_field_refused"]), 8, "S6 + helped + refused (unreachable)")
	var only_done := _res({"ch1_complete": true})
	_check(only_done["text"] == BC_NEXT_CHAPTER and _step_of(only_done) == -1, "{ch1_complete} alone -> '%s' (got '%s')" % [BC_NEXT_CHAPTER, only_done["text"]])


# AC-8c ───────────────────────────────────────────────────────────────────────
func _test_bc_bridge_flags() -> void:
	print("[Breadcrumb AC-8c: each bridge end flag moves to step 9]")
	_check_step(_sset(8), 8, "S8 before any bridge flag")
	_check_step(_sset(6, ["ch1_north_field_refused"]), 8, "S6 + refused before any bridge flag")
	for f in BC_BRIDGE_FLAGS:
		_check_step(_sset(8, [f]), 9, "S8 + %s" % f)
		_check_step(_sset(6, ["ch1_north_field_refused", f]), 9, "S6 + refused + %s" % f)


# AC-7 ────────────────────────────────────────────────────────────────────────
func _test_bc_dlg_objective_lines() -> void:
	print("[Breadcrumb AC-7: exactly four 'do objective' lines, each equal to its step]")
	var re := RegEx.create_from_string("^do objective (.+)$")
	var found: Array = []
	for d in _dlg_lines():
		var m := re.search(String(d["line"]))
		if m:
			found.append({"file": d["file"], "text": m.get_string(1)})
	_check(found.size() == 4, "exactly 4 'do objective' lines in dialogue/ch1 (found %d)" % found.size())
	var want := [["crash_site.dlg", 0], ["crash_site.dlg", 1], ["elara_meeting.dlg", 2], ["broken_mile.dlg", 4]]
	for w in want:
		var hit := found.filter(func(f): return f["file"] == w[0] and f["text"] == BC_STEPS[w[1]])
		_check(hit.size() == 1, "%s has the 'do objective' line of step %d" % [w[0], w[1]])


# AC-4 ────────────────────────────────────────────────────────────────────────
func _test_bc_label_format() -> void:
	print("[Breadcrumb AC-4: label text with and without a hint]")
	var gm := _gm()
	var bc := _bc()
	var arrow := String.chr(0x25BA)
	var old_fmt := "[color=#4488CC][b]" + arrow + "[/b][/color] [color=#CCDDEE]%s[/color]\n[color=#667788][i]%s[/i][/color]"
	# Prime with a Chapter 2 entry so the Chapter 1 entry below is a real change and re-renders.
	gm.reset_game()
	gm.set_story_flag("ch1_complete", true)
	_force_explore()
	bc.force_refresh()
	_check(bc.get_current_objective() == BC_NEXT_CHAPTER, "primed with the Chapter 2 entry")
	gm.reset_game()
	for i in range(4):
		gm.set_story_flag(BC_START_FLAGS[i], true)
	_force_explore()
	bc.force_refresh()
	var label: String = bc.get_objective_label_text()
	_check(bc.get_current_objective() == BC_STEPS[3], "Chapter 1 step 3 is current")
	var want1 := "[color=#4488CC][b]" + arrow + "[/b][/color] [color=#CCDDEE]" + BC_STEPS[3] + "[/color]"
	_check(label == want1, "Chapter 1 label is just the objective line (got '%s')" % label)
	_check(not label.contains("[i]") and not label.contains("[/i]") and not label.ends_with("\n") and not label.contains("\n"),
		"Chapter 1 label has no [i], [/i], line break")
	gm.reset_game()
	gm.set_story_flag("ch1_complete", true)
	_force_explore()
	bc.force_refresh()
	var res := _res({"ch1_complete": true})
	_check(res["hint"] != "", "the Chapter 2 entry has a hint")
	_check(bc.get_objective_label_text() == old_fmt % [res["text"], res["hint"]],
		"Chapter 2 label equals the old format string byte for byte (got '%s')" % bc.get_objective_label_text())


# AC-8a ───────────────────────────────────────────────────────────────────────
## Sets each step's start flag in route order on the live GameManager (the order the
## kill route sets them) and reads the live HUD objective every time. The flags are set
## directly: the dialogue-driven kill route is covered by the route tests above.
func _test_bc_kill_route_samples() -> void:
	print("[Breadcrumb AC-8a: live HUD at each step's start flag]")
	var gm := _gm()
	var bc := _bc()
	gm.reset_game()
	_force_explore()
	bc.force_refresh()   # empty flags: clears any stale objective so the first step is a change
	var emitted: Array = []
	var rec := func(t: String) -> void: emitted.append(t)
	bc.objective_changed.connect(rec)
	for n in BC_STEPS.size():
		gm.set_story_flag(BC_START_FLAGS[n], true)
		_force_explore()
		bc.force_refresh()
		_check(bc.get_current_objective() == BC_STEPS[n], "after %s the HUD shows step %d (got '%s')" % [BC_START_FLAGS[n], n, bc.get_current_objective()])
	gm.set_story_flag("ch1_elara_joined", true)
	bc.force_refresh()
	_check(bc.get_current_objective() == BC_STEPS[10], "ch1_elara_joined leaves step 10 up")
	gm.set_story_flag("ch1_complete", true)
	bc.force_refresh()
	_check(bc.get_current_objective() == BC_NEXT_CHAPTER, "ch1_complete moves the HUD to the Chapter 2 entry")
	bc.objective_changed.disconnect(rec)
	var want: Array = BC_STEPS.duplicate()
	want.append(BC_NEXT_CHAPTER)
	_check(emitted == want, "objective_changed fired once per step, in order (got %d: %s)" % [emitted.size(), emitted])


# AC-6a ───────────────────────────────────────────────────────────────────────
## Runs one .dlg node and reports `flag` at the first visible line and at the end.
func _probe_dlg(path: String, node: String, flag: String) -> Dictionary:
	var gm := _gm()
	var dm := _dm()
	var st := {"done": false, "seen_first": false, "flag_at_first_line": false}
	var runner := func() -> void:
		await dm.run(path, node)
		st["done"] = true
	runner.call()
	var deadline := Time.get_ticks_msec() + 60000
	while not st["done"] and Time.get_ticks_msec() < deadline:
		if not st["seen_first"] and dm._is_visible and dm._text_label.text != "":
			st["seen_first"] = true
			st["flag_at_first_line"] = gm.has_flag(flag)
		await process_frame
	st["flag_at_end"] = gm.has_flag(flag)
	return st


func _test_bc_broken_mile_flag() -> void:
	print("[Breadcrumb AC-6a: ch1_broken_mile_entered is set by the first node]")
	var gm := _gm()
	var flag := "ch1_broken_mile_entered"
	gm.reset_game()
	_seen_text.clear()
	_start([])
	_check(not gm.has_flag(flag), "flag is unset before the walk")
	var first := await _probe_dlg(BC_BROKEN_MILE, "tree_flicker", flag)
	_check(first["done"] and first["seen_first"], "tree_flicker ran and showed a line")
	_check(first["flag_at_first_line"], "flag is already set when tree_flicker's first line shows")
	_check(first["flag_at_end"], "flag is set after tree_flicker")
	_dm().force_reset()
	gm.reset_game()
	var other := await _probe_dlg(BC_BROKEN_MILE, "walk_manifest", flag)
	_check(other["done"] and other["seen_first"], "walk_manifest ran and showed a line")
	_check(not other["flag_at_first_line"] and not other["flag_at_end"], "running walk_manifest first does not set the flag")
	_driving = false
	await _end_scene()


# AC-6c ───────────────────────────────────────────────────────────────────────
## The kill/refuse routes cannot be compared against a pre-T05 flag set without the
## old code, so this checks the parts that can be proved without it: each new flag has
## exactly one writer, in the place the story names, and both are in the bible's §5.
func _test_bc_new_flags_registered() -> void:
	print("[Breadcrumb AC-6c: the two new flags have one writer each and are in the bible]")
	var dlg := _dlg_lines()
	var sets_mile := dlg.filter(func(d): return d["line"] == "set ch1_broken_mile_entered")
	var sets_stew := dlg.filter(func(d): return String(d["line"]).begins_with("set ch1_stew_done"))
	_check(sets_mile.size() == 1 and sets_mile[0]["file"] == "broken_mile.dlg", "ch1_broken_mile_entered: one 'set' line, in broken_mile.dlg (%d)" % sets_mile.size())
	_check(sets_stew.is_empty(), "ch1_stew_done is not set from a .dlg")
	var script_hits := {"ch1_stew_done": 0, "ch1_broken_mile_entered": 0}
	var files := _gd_files("res://scripts")
	_check(files.size() > 0, "scripts/ scan found files")
	var stew_writers: Array = []
	for p in files:
		var text := _read_text(p)
		for flag in script_hits:
			var n := text.count("set_story_flag(\"%s\"" % flag)
			script_hits[flag] += n
			if flag == "ch1_stew_done" and n > 0:
				stew_writers.append(p)
	_check(script_hits["ch1_stew_done"] == 1 and stew_writers == [HOUSE_WRITER],
		"ch1_stew_done: exactly one set_story_flag in scripts/, in ch1_elara_house.gd (%d: %s)" % [script_hits["ch1_stew_done"], stew_writers])
	_check(script_hits["ch1_broken_mile_entered"] == 0, "ch1_broken_mile_entered is not set from scripts/ (%d)" % script_hits["ch1_broken_mile_entered"])
	var bible := _read_text(BC_BIBLE)
	var s5 := bible.find("## 5. ")
	var s6 := bible.find("## 6. ")
	_check(s5 >= 0 and s6 > s5, "STORY_BIBLE.md has sections 5 and 6")
	var section := bible.substr(s5, s6 - s5)
	_check(section.contains("| `ch1_broken_mile_entered` |"), "STORY_BIBLE §5 has the ch1_broken_mile_entered row")
	_check(section.contains("| `ch1_stew_done` |"), "STORY_BIBLE §5 has the ch1_stew_done row")
	# No other Chapter 1 flag write was added (or removed) relative to the pre-T05 commit.
	var scan := _ch1_flag_writes()
	var cur: Dictionary = scan["names"]
	_check(scan["files"] > 0 and cur.size() > 0 and BC_CH1_FLAG_WRITES_D5CA821.size() > 0,
		"Chapter 1 flag-write scan read %d files, found %d names (frozen list %d)" % [scan["files"], cur.size(), BC_CH1_FLAG_WRITES_D5CA821.size()])
	var want := {}
	for f in BC_CH1_FLAG_WRITES_D5CA821:
		want[f] = true
	for f in BC_T05_NEW_FLAGS:
		want[f] = true
	var added := cur.keys().filter(func(f): return not want.has(f))
	var missing := want.keys().filter(func(f): return not cur.has(f))
	added.sort()
	missing.sort()
	_check(added.is_empty() and missing.is_empty() and cur.size() == want.size(),
		"Chapter 1 flag writes == d5ca821 set + T05's two (%d names; written but not expected: %s; expected but not written: %s)" % [cur.size(), added, missing])


# AC-5 ────────────────────────────────────────────────────────────────────────
func _arrow_frames() -> void:
	await process_frame
	await process_frame


func _put_player_far(scene: Node) -> Node2D:
	var player: Node2D = scene.get_node("Player")
	if not player.is_in_group("player"):
		player.add_to_group("player")
	player.global_position = Vector2(60, 60)
	return player


func _test_bc_arrows_hook() -> void:
	print("[Breadcrumb AC-5: arrows at the crash site]")
	var gm := _gm()
	var bc := _bc()
	var arrow_entries := _objectives().filter(func(e): return e.get("chapter1", false) and e.get("scene", "") != "")
	_check(arrow_entries.size() == 5, "5 Chapter 1 entries have an arrow (got %d)" % arrow_entries.size())
	_check(arrow_entries.all(func(e): return String(e["scene"]).begins_with("res://") and ResourceLoader.exists(e["scene"]) and String(e.get("target_node", "")) != ""),
		"each arrow entry names an existing res:// scene and a target node")
	var s5_arrow := arrow_entries.filter(func(e): return e.get("text", "") == BC_STEPS[5])
	_check(s5_arrow.size() == 1 and s5_arrow[0]["scene"] == VILLAGE and s5_arrow[0]["target_node"] == HOUSE_DOOR_NODE and not s5_arrow[0].has("target"),
		"step 5's arrow entry is the village scene + %s, no fixed target (%s)" % [HOUSE_DOOR_NODE, s5_arrow])
	var no_arrow := _objectives().filter(func(e): return e.get("chapter1", false) and e.get("scene", "") == "")
	_check(no_arrow.size() == 6 and no_arrow.all(func(e): return not e.has("target") and not e.has("target_node")),
		"the other 6 Chapter 1 entries have no scene, node or fixed target")
	await _end_scene()
	gm.reset_game()
	_seen_text.clear()
	_start([])
	change_scene_to_file(HOOK)
	for i in 4:
		await process_frame
	var hook := current_scene
	var deadline := Time.get_ticks_msec() + 30000
	while hook._dialogue_busy and Time.get_ticks_msec() < deadline:
		await process_frame
	_driving = false
	var player := _put_player_far(hook)
	_check(hook.get_node_or_null("SignalFragment") != null and hook.get_node_or_null("OakhavenPath") != null, "SignalFragment and OakhavenPath exist in the crash-site scene")
	gm.set_story_flag("ch1_opening_hook_started", true)
	_check(not gm.has_flag("ch1_crash_trace_seen"), "precondition: crash trace not seen yet")
	_force_explore()
	bc.force_refresh()
	await _arrow_frames()
	_check(bc.get_current_objective() == BC_STEPS[0] and bc.has_arrow_target() and bc.get_arrow_scene() == HOOK, "step 0 caches an arrow bound to the crash site")
	_check(bc.get_arrow_target() == Vector2(545, 370), "step 0 arrow aims at (545,370) (got %s)" % bc.get_arrow_target())
	_check(bc.get_arrow_text().contains("away"), "step 0 arrow is shown when the player is far (got '%s')" % bc.get_arrow_text())
	gm.set_story_flag("ch1_crash_trace_seen", true)
	bc.force_refresh()
	await _arrow_frames()
	_check(bc.get_current_objective() == BC_STEPS[1] and bc.get_arrow_target() == Vector2(1030, 370),
		"step 1 arrow aims at (1030,370) (got %s)" % bc.get_arrow_target())
	_check(bc.get_arrow_text().contains("away"), "step 1 arrow is shown (got '%s')" % bc.get_arrow_text())
	# Hide case 1: the cached scene is not the current one. The same player, target and
	# cache are kept, only the scene path differs, so the empty text can only come from
	# the scene check; restoring the path proves the arrow can come back.
	hook.scene_file_path = "res://scenes/chapter1/not_the_crash_site.tscn"
	await _arrow_frames()
	_check(bc.get_arrow_text() == "", "arrow text is empty when the cached scene is not the current scene (got '%s')" % bc.get_arrow_text())
	hook.scene_file_path = HOOK
	bc.force_refresh()
	await _arrow_frames()
	_check(bc.get_arrow_text().contains("away"), "arrow is back once the scene matches again (got '%s')" % bc.get_arrow_text())
	# Hide case 2: the target node is missing.
	var path_node := hook.get_node("OakhavenPath")
	path_node.name = "OakhavenPath_gone"
	bc.force_refresh()
	await _arrow_frames()
	_check(not bc.has_arrow_target() and bc.get_arrow_text() == "", "arrow is hidden when the target node is missing (got '%s')" % bc.get_arrow_text())
	path_node.name = "OakhavenPath"
	bc.force_refresh()
	await _arrow_frames()
	_check(bc.has_arrow_target() and bc.get_arrow_text().contains("away"), "arrow returns when the node is back (got '%s')" % bc.get_arrow_text())
	# Hide case 3: an entry with no target (step 2).
	gm.set_story_flag("elara_met", true)
	bc.force_refresh()
	await _arrow_frames()
	_check(bc.get_current_objective() == BC_STEPS[2] and not bc.has_arrow_target() and bc.get_arrow_text() == "",
		"step 2 has no arrow even though the player is in the crash site (got '%s')" % bc.get_arrow_text())
	_check(player.is_inside_tree(), "the player stayed in the scene for the hide cases (so empty text is not 'no player')")
	await _end_scene()


func _test_bc_arrows_village() -> void:
	print("[Breadcrumb AC-5: arrows in Oakhaven]")
	var gm := _gm()
	var bc := _bc()
	gm.reset_game()
	_seen_text.clear()
	change_scene_to_file(VILLAGE)
	for i in 4:
		await process_frame
	var s := current_scene
	_put_player_far(s)
	var boar: Node2D = s.get_node("Triggers/BoarTrigger")
	var bridge: Node2D = s.get_node("Triggers/BridgeTrigger")
	_check(boar.global_position != bridge.global_position, "the two triggers are at different places")
	for i in range(8):
		gm.set_story_flag(BC_START_FLAGS[i], true)
	_force_explore()
	bc.force_refresh()
	await _arrow_frames()
	_check(bc.get_current_objective() == BC_STEPS[7] and bc.get_arrow_scene() == VILLAGE and bc.get_arrow_target() == boar.global_position,
		"step 7 arrow aims at Triggers/BoarTrigger %s (got %s)" % [boar.global_position, bc.get_arrow_target()])
	_check(bc.get_arrow_text().contains("away"), "step 7 arrow is shown (got '%s')" % bc.get_arrow_text())
	gm.set_story_flag("ch1_corrupted_boar_defeated", true)
	bc.force_refresh()
	await _arrow_frames()
	_check(bc.get_current_objective() == BC_STEPS[8] and bc.get_arrow_target() == bridge.global_position,
		"step 8 arrow aims at Triggers/BridgeTrigger %s (got %s)" % [bridge.global_position, bc.get_arrow_target()])
	_check(bc.get_arrow_text().contains("away"), "step 8 arrow is shown (got '%s')" % bc.get_arrow_text())
	s.scene_file_path = HOOK
	await _arrow_frames()
	_check(bc.get_arrow_text() == "", "step 8 arrow hides when the current scene is another scene (got '%s')" % bc.get_arrow_text())
	s.scene_file_path = VILLAGE
	await _end_scene()


# AC-6b ───────────────────────────────────────────────────────────────────────
## Loads Elara's house (Y1-P0-S08: the stew plays there) and watches the stew. `picks`
## answer the stew topics; `skip_all` calls DialogueManager.skip_all() on the stew's
## second line; `abort` frees the scene after the first topic, while the stew run is
## still open.
func _stew_run(label: String, picks: Array, skip_all: bool, abort: bool) -> void:
	var gm := _gm()
	var dm := _dm()
	var flag := "ch1_stew_done"
	gm.reset_game()
	_seen_text.clear()
	var emits := [0]
	var rec := func(f: String, v: bool) -> void:
		if f == flag and v:
			emits[0] += 1
	gm.story_flag_updated.connect(rec)
	_start(picks)
	change_scene_to_file(HOUSE)
	for i in 4:
		await process_frame
	var s := current_scene
	var early := false
	var saw_choice := false
	var at_stew_line := true
	var stew_frames := 0
	var skipped := false
	var aborted := false
	var running_at_abort := false
	var deadline := Time.get_ticks_msec() + 90000
	while Time.get_ticks_msec() < deadline and is_instance_valid(s) and s._stew_running:
		# Marker: the stew's second line. (skip-all fast-forwards the later lines, so the
		# last stew line may never be on screen for a frame.)
		var in_stew := _saw("That's a category, not a recipe.")
		if dm._awaiting_choice and in_stew:
			saw_choice = true
			early = early or gm.has_flag(flag)
		if in_stew and not saw_choice:
			stew_frames += 1
			at_stew_line = at_stew_line and not gm.has_flag(flag)
		if skip_all and not skipped and _saw("That's a category, not a recipe."):
			skipped = true
			dm.skip_all()
		if abort and gm.has_flag("ch1_stew_asked_where"):
			running_at_abort = s._stew_running
			aborted = true
			s.queue_free()
			break
		await process_frame
	if abort:
		for i in 15:
			await process_frame
		gm.story_flag_updated.disconnect(rec)
		_check(aborted and running_at_abort, "%s: the scene was left mid-run (after the first topic)" % label)
		_check(not gm.has_flag(flag) and emits[0] == 0, "%s: ch1_stew_done is not set when the scene is left mid-run (%d emits)" % [label, emits[0]])
		await _end_scene()
		return
	for i in 3:
		await process_frame
	gm.story_flag_updated.disconnect(rec)
	_check(saw_choice and not early, "%s: the stew choices were seen and ch1_stew_done was not set while they were open" % label)
	_check(at_stew_line and stew_frames > 0, "%s: ch1_stew_done not set while the stew lines play (%d frames watched)" % [label, stew_frames])
	_check(is_instance_valid(s) and not s._stew_running and gm.has_flag(flag) and emits[0] == 1,
		"%s: ch1_stew_done is set once the stew run has returned, exactly once (%d emits)" % [label, emits[0]])
	if skip_all:
		_check(skipped, "%s: skip_all was requested during the stew" % label)
	await _end_scene()


func _test_bc_stew_flag() -> void:
	print("[Breadcrumb AC-6b: ch1_stew_done on every stew path]")
	var gm := _gm()
	await _stew_run("topics then (Just eat.)", [0, 3], false, false)
	_check(gm.has_flag("ch1_stew_asked_where") and not gm.has_flag("ch1_stew_asked_fracture"), "that path asked one topic, then ate")
	await _stew_run("(Just eat.) straight away", [4], false, false)
	_check(not gm.has_flag("ch1_stew_asked_where") and not gm.has_flag("ch1_stew_asked_fracture"), "that path asked no topic")
	await _stew_run("skip-all", [4], true, false)
	_check(not gm.has_flag("ch1_stew_asked_where"), "the skip-all path asked no topic")
	await _stew_run("scene left mid-run", [0], false, true)


# AC-3b integration, AC-8b / hesitate-then-help live ───────────────────────────
## Waits until the current scene is `path` and no transition is running; the scene, or
## null at the deadline.
func _scene_ready(path: String, timeout_sec: float) -> Node:
	var st := get_root().get_node("SceneTransitions")
	var deadline := Time.get_ticks_msec() + int(timeout_sec * 1000.0)
	while Time.get_ticks_msec() < deadline:
		if current_scene and current_scene.scene_file_path == path and not st.is_transitioning:
			return current_scene
		await process_frame
	return null


## Y1-P0-S08: from a freshly loaded village `v` (driver running), waits for the arrival
## (gate, ledger, invite), walks through Doors/ElaraHouseDoor, lets the stew play in the
## house, leaves by the house door and returns the village as it comes back.
## {"invited", "ledger_at_invite", "entrance_at_invite", "stew_before_house", "house",
##  "stew_done", "village" (Node or null)}.
func _through_house(v: Node, timeout_sec: float = 120.0) -> Dictionary:
	var gm := _gm()
	var out := {"invited": false, "ledger_at_invite": false, "entrance_at_invite": true, "stew_before_house": true,
		"house": false, "stew_done": false, "village": null}
	var deadline := Time.get_ticks_msec() + int(timeout_sec * 1000.0)
	while is_instance_valid(v) and not v._invited and Time.get_ticks_msec() < deadline:
		await process_frame
	if not is_instance_valid(v) or not v._invited:
		return out
	out["invited"] = true
	out["ledger_at_invite"] = _saw("Mara knows everything by lunch")
	out["entrance_at_invite"] = v._entrance_done
	out["stew_before_house"] = gm.has_flag("ch1_stew_done") or _saw(STEW_FIRST)
	while is_instance_valid(v) and not v._elara_door_open() and Time.get_ticks_msec() < deadline:
		await process_frame
	v._on_elara_house_door_interaction(v.get_node("Player"))
	var h := await _scene_ready(HOUSE, timeout_sec)
	if h == null:
		return out
	out["house"] = true
	while is_instance_valid(h) and (h._busy() or not gm.has_flag("ch1_stew_done")) and Time.get_ticks_msec() < deadline:
		await process_frame
	out["stew_done"] = gm.has_flag("ch1_stew_done") and _saw(STEW_FIRST)
	if not is_instance_valid(h):
		return out
	h._on_door_interaction(h.get_node("Player"))
	var v2 := await _scene_ready(VILLAGE, timeout_sec)
	if v2 != null:
		await process_frame
	out["village"] = v2
	return out


## Village afternoon open: arrival played, the stew played in Elara's house (topics
## answered by the default first option), back in the village, no afternoon beats.
## Returns the village scene (null if the walk through the house did not finish).
func _village_after_entrance() -> Node:
	_gm().reset_game()
	_seen_text.clear()
	_start([])
	change_scene_to_file(VILLAGE)
	for i in 4:
		await process_frame
	var r := await _through_house(current_scene)
	return r["village"]


## Runs s._run_north_field() under a deadline, so a stalled run (e.g. a pick that does
## not exist in the dialogue) fails a check instead of hanging the suite.
## Returns true when the run returned in time.
func _run_field_bounded(s: Node, timeout_sec: float) -> bool:
	var st := {"done": false}
	var runner := func() -> void:
		await s._run_north_field()
		st["done"] = true
	runner.call()
	var deadline := Time.get_ticks_msec() + int(timeout_sec * 1000.0)
	while not st["done"] and Time.get_ticks_msec() < deadline:
		await process_frame
	return st["done"]


func _test_bc_alarm_routes() -> void:
	print("[Breadcrumb AC-3b / AC-8b: the alarm on the live village route]")
	var gm := _gm()
	var bc := _bc()
	# Early alarm, help (the bridge trigger runs the field first).
	var s := await _village_after_entrance()
	_check(s._entrance_done and gm.has_flag("ch1_stew_done"), "early alarm: entrance done, stew done")
	_force_explore()
	bc.force_refresh()
	_check(bc.get_current_objective() == BC_STEPS[6], "early alarm: step 6 before the alarm (got '%s')" % bc.get_current_objective())
	_start([0])
	_check(await _run_field_bounded(s, BC_FIELD_TIMEOUT_SEC), "early alarm: the field run finished within %ds" % int(BC_FIELD_TIMEOUT_SEC))
	_check(gm.has_flag("ch1_north_field_helped") and gm.has_flag("ch1_corrupted_boar_defeated"), "early alarm: helped, field resolved, boar flag set")
	_force_explore()
	bc.force_refresh()
	_check(bc.get_current_objective() == BC_STEPS[8], "early alarm: a forced refresh shows step 8 (got '%s')" % bc.get_current_objective())
	_driving = false
	await _end_scene()
	# Refuse: picks [1, 1] = "This isn't my..." then "I'm staying here.".
	# Note: refresh is suppressed outside EXPLORATION, so objective_changed history
	# cannot prove step 7 was never shown (it would pass vacuously); the proof is that
	# ch1_north_field_helped is never set and step 8 follows step 6 directly.
	s = await _village_after_entrance()
	_force_explore()
	bc.force_refresh()
	_check(bc.get_current_objective() == BC_STEPS[6], "refuse: step 6 before the alarm (got '%s')" % bc.get_current_objective())
	_start([1, 1])
	_check(await _run_field_bounded(s, BC_FIELD_TIMEOUT_SEC), "refuse: the field run finished within %ds" % int(BC_FIELD_TIMEOUT_SEC))
	_check(gm.has_flag("ch1_north_field_refused") and not gm.has_flag("ch1_north_field_helped"), "refuse: refused set, helped never set")
	_check(not gm.has_flag("ch1_corrupted_boar_defeated") and s._field_resolved, "refuse: the aftermath ended, no boar flag")
	_force_explore()
	bc.force_refresh()
	_check(bc.get_current_objective() == BC_STEPS[8], "refuse: a forced refresh shows step 8 (got '%s')" % bc.get_current_objective())
	_driving = false
	await _end_scene()
	# Hesitate, then help: picks [1, 0].
	s = await _village_after_entrance()
	_start([1, 0])
	var st := {"done": false}
	var runner := func() -> void:
		await s._run_north_field()
		st["done"] = true
	runner.call()
	var step_when_helped := -2
	var refused_when_helped := true
	var deadline := Time.get_ticks_msec() + int(BC_FIELD_TIMEOUT_SEC * 1000.0)
	while not st["done"] and Time.get_ticks_msec() < deadline:
		if step_when_helped == -2 and gm.has_flag("ch1_north_field_helped") and not gm.has_flag("ch1_corrupted_boar_defeated"):
			# Pure resolve on the live flags: state is DIALOGUE here, so the HUD would not refresh.
			step_when_helped = _step_of(_res(_live_flags()))
			refused_when_helped = gm.has_flag("ch1_north_field_refused")
		await process_frame
	_check(st["done"], "hesitate-then-help: the field run finished")
	_check(step_when_helped == 7 and not refused_when_helped, "hesitate-then-help: helped set -> step 7 while the boar is open (got step %d)" % step_when_helped)
	_check(not gm.has_flag("ch1_north_field_refused"), "hesitate-then-help: refused never set")
	_driving = false
	await _end_scene()
