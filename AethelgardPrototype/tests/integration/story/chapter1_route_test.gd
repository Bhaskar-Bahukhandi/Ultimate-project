extends SceneTree
## Plays Chapter 1 end to end on the rewritten dialogue (dialogue/prologue,
## dialogue/ch1): crash site → Elara → Broken Mile → Oakhaven → Aldric →
## Fragment One → village meeting → Elara joins → the Chapter 1 ending.
## A fake player answers every choice from a pick list (default: first option).
## Run: tests/run_phase0_tests.ps1 -Script res://tests/integration/story/chapter1_route_test.gd

const HOOK := "res://scenes/chapter1/opening_crash_site_hook.tscn"
const ELARA := "res://scenes/chapter1/elara_meeting.tscn"
const PATH := "res://scenes/chapter1/path_to_oakhaven.tscn"
const VILLAGE := "res://scenes/chapter1/oakhaven_village.tscn"
const REGION := "res://scenes/regions/oakhaven_region.tscn"
const KNIGHT := "res://scenes/chapter1/tutorial_knight_boss.tscn"
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
	while Time.get_ticks_msec() < deadline:
		var s := current_scene
		if s and s.scene_file_path == path and not get_root().get_node("SceneTransitions").is_transitioning:
			return true
		if s and s.scene_file_path == PATH and s.get("root_access_tutorial_active") and not s.get("guardian_resolved"):
			s._target_filter.select(1)     # TARGET FILTER: ALL → FRACTURE_ENTITIES
			s._on_root_access_apply()
		elif s and s.scene_file_path == VILLAGE and s.get("_entrance_done") and not s.get("in_dialogue") \
				and Time.get_ticks_msec() >= next_poke:
			next_poke = Time.get_ticks_msec() + 1000
			var player := s.get_node_or_null("Player")
			if player:
				s._on_bridge_trigger(player)   # walk to the bridge
		await process_frame
	return false


func _test_new_game_to_region() -> void:
	print("[New Game → Oakhaven region]")
	var gm := _gm()
	gm.reset_game()
	_seen_text.clear()
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
	_check(gm.has_flag("ch1_stew_asked_where") and gm.has_flag("ch1_elara_arm_talked"), "stew topics played")
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
	knight._on_boss_defeated()
	_check(await _wait_for(SHATTER, 240.0), "decision → fragment → meeting → Elara joins → Chapter 1 ending")
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
	knight._on_boss_defeated()
	_check(await _wait_for(SHATTER, 240.0), "purge route reaches the Chapter 1 ending")
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
	var s := current_scene
	var deadline := Time.get_ticks_msec() + 60000
	while not s._entrance_done and Time.get_ticks_msec() < deadline:
		await process_frame
	var player := s.get_node("Player")
	_check(s._entrance_done and _saw("Mara knows everything by lunch") and _saw("Today it's both."), "gate, ledger and stew play on arrival")
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
	knight._on_boss_defeated()
	var ok := await _wait_for(SHATTER, 240.0)
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
