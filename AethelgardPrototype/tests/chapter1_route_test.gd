extends SceneTree
## Plays Chapter 1 end to end on the rewritten dialogue (dialogue/prologue,
## dialogue/ch1): crash site → Elara → Broken Mile → Oakhaven → Aldric →
## Fragment One → village meeting → Elara joins → the Chapter 1 ending.
## A fake player answers every choice from a pick list (default: first option).
## Run: tests/run_phase0_tests.ps1 -Script res://tests/chapter1_route_test.gd

const HOOK := "res://scenes/chapter1/opening_crash_site_hook.tscn"
const ELARA := "res://scenes/chapter1/elara_meeting.tscn"
const PATH := "res://scenes/chapter1/path_to_oakhaven.tscn"
const VILLAGE := "res://scenes/chapter1/oakhaven_village.tscn"
const REGION := "res://scenes/regions/oakhaven_region.tscn"
const KNIGHT := "res://scenes/chapter1/tutorial_knight_boss.tscn"
const SHATTER := "res://scenes/chapter1/shatter_transition.tscn"

var _passes := 0
var _failures: Array[String] = []
var _driving := false
var _picks: Array = []
var _seen_text: Array[String] = []


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
	await _test_village_afternoon()
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
func _drive() -> void:
	var dm := _dm()
	while _driving:
		if dm._is_visible and dm._text_label and dm._text_label.text != "":
			var line: String = "%s: %s" % [dm._speaker_label.text, dm._text_label.text]
			if _seen_text.is_empty() or _seen_text.back() != line:
				_seen_text.append(line)
		if dm._awaiting_choice:
			if dm._choice_result == -1 and dm._choice_container != null:
				dm._on_choice_pressed(_picks.pop_front() if not _picks.is_empty() else 0)
		elif dm._is_visible:
			dm._skip_typing = true
			dm._advance_requested = true
		await process_frame


func _start(picks: Array) -> void:
	_picks = picks.duplicate()
	if not _driving:
		_driving = true
		_drive()


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
	_check(gm.has_flag("ch1_knight_killed") and gm.has_flag("ch1_aldric_kill_owned"), "kill and how Kaelen owns it are recorded")
	_check(gm.has_flag("source_key_fragment_1") and gm.source_key_count == fragments_before + 1, "Fragment One is awarded and counted once")
	_check(_saw("I knew those words.") and _saw("That's the point."), "Fragment One plays the memory flash")
	_check(gm.has_flag("ch1_oakhaven_warned_villagers") and _saw("Boil your water"), "the village meeting plays (public warning)")
	_check(gm.has_flag("ch1_elara_joined") and gm.has_flag("ch1_tutorial_knight_defeated"), "Elara joins; the knight counts as defeated")
	_check(not gm.has_flag("ch1_bridge_fell"), "a fixed bridge doesn't fall")
	_driving = false


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
	_check(gm.has_flag("ch1_root_purge") and gm.has_flag("ch1_knight_spared"), "purge keeps Aldric alive (legacy ch1_knight_spared)")
	_check(gm.glitch_meter > corruption_before, "the purge costs corruption (%.0f → %.0f)" % [corruption_before, gm.glitch_meter])
	_check(_saw("You always were a liar."), "Aldric wakes up after the purge")
	_check(gm.has_flag("ch1_bridge_fell") and _saw("Nobody was on it"), "the unfixed bridge falls after dark; evacuating it saved lives")
	_check(gm.has_flag("ch1_oakhaven_left_quietly") and _saw("They're not children"), "leaving quietly is challenged by Elara")
	_driving = false


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
