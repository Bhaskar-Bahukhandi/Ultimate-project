extends SceneTree
## Y1-P0-S08 room suite (AC-14): Elara's house and the shrine are real rooms.
## Story: production/epics/y1-p0-stabilize/story-s08-elara-house-shrine-rooms.md
## Groups C1-C9 follow the story's QA Test Cases. Not here, by design: AC-13
## reachability of both rooms (reachability_test.gd) and the chapter1_route_test
## updates (AC-15). C10 (registration, tour, evidence) is not a runtime check.
## The golden inputs (preset flags, picks, meeting choice) are read from
## ch1_s08_golden.json, never repeated here. Single-fire is measured by the most
## DialogueManager runs active at once (_max_runs, sampled by the driver), plus
## first lines seen once and story_flag_updated emits; never by counting
## change_scene requests (change_scene drops a second request on its own).
## DialogueManager.run does not refuse a second concurrent run.
## Waits are frame waits with deadlines; no assertion depends on time.
## Run: tests/run_phase0_tests.ps1 -Script res://tests/integration/level/ch1_rooms_test.gd

const VILLAGE := "res://scenes/chapter1/oakhaven_village.tscn"
const HOUSE := "res://scenes/chapter1/elara_house.tscn"
const KNIGHT := "res://scenes/chapter1/tutorial_knight_boss.tscn"
const SHRINE := "res://scenes/chapter1/shrine.tscn"
const SHATTER := "res://scenes/chapter1/shatter_transition.tscn"
const HOUSE_SRC := "res://scripts/chapter1/ch1_elara_house.gd"
const SHRINE_SRC := "res://scripts/chapter1/ch1_shrine.gd"
const ARENA_SRC := "res://scripts/chapter1/ch1_tutorial_knight.gd"
const GOLDEN_PATH := "res://tests/integration/story/ch1_s08_golden.json"
const FIXTURE_PRE := "res://tests/fixtures/ch1_s08_save_pre_fragment.save"
const FIXTURE_MID := "res://tests/fixtures/ch1_s08_save_mid_meeting.save"
const STORY_BIBLE := "res://story/STORY_BIBLE.md"
const SLOT1 := "user://save_slot_1.save"
const SLOT99 := "user://save_slot_99.save"
## AC-1 / AC-5: the only player-visible strings the two rooms may show.
const ALLOWED_TEXT := ["Kaelen", "Under the old gate", "Oakhaven, after dark", "SOURCE KEY 1/7"]
## The three literals that moved from the arena into the shrine script.
const SHRINE_MOVED := ["Under the old gate", "Oakhaven, after dark", "SOURCE KEY 1/7"]
## A line of a room script that hands a string to a UI node or an indicator.
const UI_SINK_RE := "(\\.text\\s*=|set_text\\(|append_text\\(|add_text\\(|tooltip_text|placeholder_text|spawn_status_indicator\\(|spawn_announcement\\(|spawn_pickup_text\\(|_location_card\\(|\\.say\\()"
## AC-6: none of these may remain in the arena script.
const ARENA_GONE := ["FRAGMENT_DLG", "fragment_one", "bridge_fell", "fragment_acquired", "_location_card", "shatter_transition", "_transition_timer"]
## First lines (fragments) of the dialogue nodes, for "seen once" counts.
const GATE_LINE := "Three hours, Elara."
const INVITE_LINE := "Food first, then you can worry about roads."
const STEW_FIRST := "This smells amazing. What is it?"
const STEW_SECOND := "That's a category, not a recipe."
const INSPECT_LINES := {
	"Bandages": "Bandages. A lot of them", "Herbs": "Half of these I don't recognise",
	"Focuses": "Three cracked", "Cloak": "Patched so many times", "Map": "Oakhaven, the crater",
}
const FRAG_FIRST := "SOURCE AUTHORIZATION"
const MEET_FIRST := "What was it down there?"
const JOINS_FIRST := "You're packing"
const BRIDGE_FELL_LINE := "Heard it go about an hour ago"
const BRIDGE_FIRST := "North bridge is cracked right through"
## House door outside spot in the village (ch1_elara_house.gd VILLAGE_DOOR_OUTSIDE)
## and Elara's two village spots (ch1_oakhaven_village.gd).
const VILLAGE_DOOR_OUTSIDE := Vector2(670, 1200)
const ELARA_AT_DOOR := Vector2(728, 1196)
const ELARA_AFTERNOON := Vector2(700, 900)
## AC-5 dressing table (flag set -> the one visible node, "" = none).
const DRESSING_ROWS := [
	[["ch1_root_purge", "ch1_knight_spared"], "DressingPurged"],
	[["ch1_knight_killed", "ch1_root_purge"], "DressingPurged"],
	[["ch1_knight_killed"], "DressingKilled"],
	[["ch1_knight_spared"], "DressingSpared"],
	[[], ""],
]
const DRESSINGS := ["DressingPurged", "DressingKilled", "DressingSpared"]
## The dressing each golden route shows (AC-5 table applied to the route's decision).
const ROUTE_DRESSING := {
	"kill": "DressingKilled", "spare": "DressingSpared", "purge": "DressingPurged",
	"kill_bridge_fell": "DressingKilled", "kill_no_bridge_choice": "DressingKilled",
}
const ROUTE_ORDER := ["kill", "spare", "purge", "kill_bridge_fell", "kill_no_bridge_choice"]
const GOLDEN_FIELDS := ["story_flags_true", "story_flag_count", "source_key_count", "glitch_meter", "gold", "relationships", "active_buff_flags"]

var _passes := 0
var _failures: Array[String] = []
var _golden: Dictionary = {}
var _driving := false
var _drive_gen := 0
var _picks: Array = []
var _seen_text: Array[String] = []
var _cards_seen: Array[String] = []     # place-card texts shown by the shrine
var _emits := {}                         # story flag -> number of (flag, true) emits
var _ts_log: Array[String] = []          # current scene at each transition_started
var _arena_combat_at_handoff: Array = []
var _delete_99_on_handoff := false
var _capture_armed := false              # post-Aldric: capture on transition_started in the shrine
var _captured := {}
var _stew_capture_armed := false         # stew: capture on the ch1_stew_done emit
var _stew_captured := {}
var _joy_button := -1
## Most DialogueManager runs seen active at once since the last reset. Proves
## single-fire: two runs started in one frame share the dialogue label, so
## first-line counts alone cannot tell one run from two (code review, 2026-10-25).
var _max_runs := 0


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	await process_frame
	await process_frame
	if not OS.get_user_data_dir().contains("aeth_phase0_test"):
		push_error("Refusing to run: user data dir is not isolated. Use tests/run_phase0_tests.ps1.")
		quit(2)
		return
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(GOLDEN_PATH))
	_golden = parsed if parsed is Dictionary else {}
	_check(_golden.has("stew") and _golden.has("post_aldric"), "golden %s loads with both segments" % GOLDEN_PATH)
	for e in InputMap.action_get_events("interact"):
		if e is InputEventJoypadButton:
			_joy_button = e.button_index
	_check(_joy_button >= 0, "the interact action has a joypad button in the input map (%d)" % _joy_button)
	Engine.time_scale = 4.0
	_gm().story_flag_updated.connect(_on_flag)
	_st().transition_started.connect(_on_ts)

	await _c1_house_room()
	_c1_source_strings()
	await _c1_stew_paths()
	await _c2_c3_village_loop()
	await _c3_no_reentry()
	_c3_door_position()
	await _c4_shrine_room()
	_c5_arena_scan()
	for route_name in ROUTE_ORDER:
		await _c6_route(route_name)
	await _c5_fixture("pre_fragment", FIXTURE_PRE, false)
	await _c5_fixture("mid_meeting", FIXTURE_MID, true)
	await _c7_house_save_load()
	await _c7_abort_mid_fragment()
	await _c7_abort_mid_chain()
	_c8_story_bible()
	await _c9_joypad_house()
	await _c9_joypad_shrine()

	Engine.time_scale = 1.0
	print("")
	print("ROOMS RESULT: %d passed, %d failed" % [_passes, _failures.size()])
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
func _st() -> Node: return get_root().get_node("SceneTransitions")
func _bc() -> Node: return get_root().get_node("ProgressionBreadcrumb")
func _state() -> String: return _gm().GameState.keys()[_gm().current_state]
func _scene_path() -> String: return current_scene.scene_file_path if current_scene else ""


# ── Driver (same approach as chapter1_route_test.gd _drive/_start) ───────────

func _drive(gen: int) -> void:
	var dm := _dm()
	while _driving and gen == _drive_gen:
		_max_runs = maxi(_max_runs, dm._runs_active)
		if dm._is_visible and dm._text_label and dm._text_label.text != "":
			var line: String = "%s: %s" % [dm._speaker_label.text, dm._text_label.text]
			if _seen_text.is_empty() or _seen_text.back() != line:
				_seen_text.append(line)
		var sc = current_scene
		if sc and is_instance_valid(sc) and sc.get("_card_layer") != null:
			var place := (sc.get("_card_layer") as Node).get_node_or_null("Place") as Label
			if place and place.text != "" and (_cards_seen.is_empty() or _cards_seen.back() != place.text):
				_cards_seen.append(place.text)
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
		_drive_gen += 1
		_drive(_drive_gen)


func _stop() -> void:
	_driving = false
	await process_frame


func _end_scene() -> void:
	await _stop()
	_dm().force_reset()
	if current_scene:
		current_scene.queue_free()
	await process_frame
	await process_frame


func _count(fragment: String, from: int = 0) -> int:
	var n := 0
	for i in range(from, _seen_text.size()):
		if _seen_text[i].contains(fragment):
			n += 1
	return n


func _emit_count(flag: String) -> int:
	return int(_emits.get(flag, 0))


func _wait(cond: Callable, ms: int) -> bool:
	var deadline := Time.get_ticks_msec() + ms
	while not cond.call() and Time.get_ticks_msec() < deadline:
		await process_frame
	return cond.call()


func _frames(n: int) -> void:
	for i in n:
		await process_frame


## Waits for a scene instance other than `old_id` at `path` (captures an id, not
## the node: a lambda that captured a freed node logs an engine error).
func _wait_new_scene(old_id: int, path: String, ms: int) -> bool:
	return await _wait(func(): return current_scene != null and current_scene.get_instance_id() != old_id and _scene_path() == path and not _st().is_transitioning, ms)


func _wait_scene(path: String, ms: int) -> bool:
	return await _wait(func(): return current_scene != null and _scene_path() == path and not _st().is_transitioning, ms)


## Waits until the scene's _busy() is false (two frames first, so a run can start).
func _idle(s: Node, ms: int = 30000) -> void:
	await process_frame
	await process_frame
	var ref: WeakRef = weakref(s)
	await _wait(func(): return ref.get_ref() == null or not ref.get_ref()._busy(), ms)


func _load_scene(path: String) -> Node:
	change_scene_to_file(path)
	for i in 6:
		await physics_frame
	await process_frame
	return current_scene


## Review finding 1 (regression): the village is rebuilt on every arrival and its
## afternoon state (alarm, field, bridge, lines seen) is scene-local, so going back
## into the house would restart the afternoon and pay the field's gold and XP again.
## The door therefore only opens between the invite and the stew.
func _c3_no_reentry() -> void:
	print("[C3b no re-entry: Elara's door stays shut once the stew has played]")
	var gm := _gm()
	gm.reset_game()
	_dm().force_reset()
	for f in ["ch1_oakhaven_entered", "ch1_northfall_registry_seen", "ch1_stew_done",
			"ch1_north_field_helped", "ch1_corrupted_boar_defeated"]:
		gm.set_story_flag(f, true)
	var v := await _load_scene(VILLAGE)
	await _wait(func(): return current_scene != null and current_scene.get("_entrance_done") == true, 30000)
	var door := v.get_node("Doors/ElaraHouseDoor")
	_check(not v._elara_door_open(), "after the stew the house door is shut")
	_check(not v._can_interact_with(door), "after the stew the house door offers no prompt")
	var vid := v.get_instance_id()
	v._on_elara_house_door_interaction(v.get_node("Player"))
	await _frames(30)
	_check(not _st().is_transitioning and current_scene != null and current_scene.get_instance_id() == vid,
		"interacting with the door after the stew stays in the same village (the afternoon can't restart)")
	await _end_scene()


## Review finding 4: the house's return spot is a copy of the village door's
## position. Ties the two together so moving the door can't strand the player.
func _c3_door_position() -> void:
	print("[C3c the house's return spot sits just outside the village door]")
	var consts: Dictionary = (load(HOUSE_SRC) as Script).get_script_constant_map()
	var spot: Vector2 = consts.get("VILLAGE_DOOR_OUTSIDE", Vector2.INF)
	var village: Node = (load(VILLAGE) as PackedScene).instantiate()
	var door := village.get_node_or_null("Doors/ElaraHouseDoor") as Node2D
	var doors := village.get_node_or_null("Doors") as Node2D
	var door_pos := Vector2.INF
	if door:
		door_pos = door.position + (doors.position if doors else Vector2.ZERO)
	_check(door != null and spot != Vector2.INF, "the village door node and the house's VILLAGE_DOOR_OUTSIDE both exist")
	_check(is_equal_approx(spot.x, door_pos.x) and spot.y > door_pos.y and spot.y - door_pos.y <= 64.0,
		"return spot %s is directly below the village door %s, within 64 px" % [spot, door_pos])
	_check(spot == VILLAGE_DOOR_OUTSIDE, "this suite's VILLAGE_DOOR_OUTSIDE equals the house's")
	# Elara's waiting spot (code review): beside the door, and not inside the house
	# block's collision (the lower 60% of ElaraHouseBuilding, as _add_building_collision builds it).
	var elara_spot: Vector2 = village.get_script().get_script_constant_map().get("ELARA_AT_DOOR_POS", Vector2.INF)
	var building := village.get_node_or_null("ElaraHouseBuilding") as Control
	var block := Rect2()
	if building:
		block = Rect2(building.position + Vector2(0, building.size.y * 0.4), Vector2(building.size.x, building.size.y * 0.6))
	_check(elara_spot != Vector2.INF and building != null, "the village's ELARA_AT_DOOR_POS and ElaraHouseBuilding both exist")
	_check(door_pos != Vector2.INF and elara_spot.distance_to(door_pos) <= 96.0 and not block.has_point(elara_spot),
		"Elara's waiting spot %s is within 96 px of the door %s and outside the house block %s" % [elara_spot, door_pos, block])
	village.free()
	# The fresh-arrival meta has one definition (GameManager); the arena and the shrine use it.
	for src in [ARENA_SRC, SHRINE_SRC]:
		var text := FileAccess.get_file_as_string(src)
		_check(not text.contains("\"shrine_fresh_arrival\"") and text.contains("GameManager.SHRINE_FRESH_ARRIVAL_META"),
			"%s uses GameManager.SHRINE_FRESH_ARRIVAL_META, no literal of its own" % src.get_file())


func _on_flag(flag: String, value: bool) -> void:
	if not value:
		return
	_emits[flag] = _emit_count(flag) + 1
	if flag == "ch1_stew_done" and _stew_capture_armed and _stew_captured.is_empty():
		_stew_captured = _snapshot()
		_stew_captured["_scene"] = _scene_path()


func _on_ts() -> void:
	var gm := _gm()
	_ts_log.append(_scene_path())
	if current_scene and _scene_path() == KNIGHT:
		_arena_combat_at_handoff.append(current_scene.combat_started)
		if _delete_99_on_handoff and gm.has_flag("ch1_tutorial_knight_defeated"):
			_delete_99_on_handoff = false
			if FileAccess.file_exists(SLOT99):
				DirAccess.remove_absolute(SLOT99)
	if _capture_armed and _captured.is_empty() and _scene_path() == SHRINE and gm.has_flag("ch1_elara_joined"):
		_captured = _snapshot()


## False when there is no player or the field is missing (a rename), so the
## capture's "Data Vision off" check cannot pass by default.
func _data_vision_off() -> bool:
	var players := get_nodes_in_group("player")
	if players.is_empty():
		return false
	for p in players:
		if not ("data_vision_active" in p) or p.data_vision_active:
			return false
	return true


## The golden's fields (see ch1_s08_golden_capture.gd _snapshot).
func _snapshot() -> Dictionary:
	var gm := _gm()
	var flags: Array = []
	for k in gm.story_flags:
		if gm.story_flags[k] == true:
			flags.append(String(k))
	flags.sort()
	var buffs: Array = []
	for b in get_root().get_node("ChoiceConsequences").active_buffs:
		buffs.append(String(b.get("source_flag", "")))
	buffs.sort()
	return {"story_flags_true": flags, "story_flag_count": flags.size(), "source_key_count": gm.source_key_count,
		"glitch_meter": gm.glitch_meter, "gold": gm.player_stats.get("gold", 0),
		"relationships": gm.relationships.duplicate(true), "active_buff_flags": buffs,
		"_data_vision_off": _data_vision_off()}


func _golden_compare(label: String, captured: Dictionary, gold: Dictionary) -> void:
	var a: Dictionary = JSON.parse_string(JSON.stringify(captured))
	for f in GOLDEN_FIELDS:
		var now := JSON.stringify(a.get(f), "", true)
		var want := JSON.stringify(gold.get(f), "", true)
		_check(now == want, "%s: %s equals the golden (golden=%s now=%s)" % [label, f, want, now])


func _preset(flags: Array) -> void:
	var gm := _gm()
	gm.reset_game()
	_seen_text.clear()
	_cards_seen.clear()
	_emits.clear()
	_ts_log.clear()
	_arena_combat_at_handoff.clear()
	_captured = {}
	_stew_captured = {}
	for f in flags:
		gm.set_story_flag(f, true)
	_emits.clear()
	gm.change_state(gm.GameState.EXPLORATION)


func _focus_ok() -> bool:
	var owner := get_root().gui_get_focus_owner()
	return owner == null or owner.is_visible_in_tree()


func _body_at(space: PhysicsDirectSpaceState2D, p: Vector2, exclude: Array) -> bool:
	var q := PhysicsPointQueryParameters2D.new()
	q.position = p
	q.collide_with_bodies = true
	q.collide_with_areas = false
	q.exclude = exclude
	return not space.intersect_point(q, 1).is_empty()


func _ui_texts(n: Node, out: Array) -> void:
	if n is Label or n is RichTextLabel or n is Button or n is LineEdit:
		out.append(String(n.text))
	for c in n.get_children():
		_ui_texts(c, out)


func _check_room_shapes(label: String, s: Node, solid: Dictionary, free: Dictionary) -> void:
	var player := s.get_node("Player") as CharacterBody2D
	var space := player.get_world_2d().direct_space_state
	for k in solid:
		_check(_body_at(space, solid[k], [player.get_rid()]), "%s: a body at the %s %s" % [label, k, solid[k]])
	for k in free:
		_check(not _body_at(space, free[k], [player.get_rid()]), "%s: no body at the %s %s" % [label, k, free[k]])
	var bodies := s.find_children("*", "StaticBody2D", true, false)
	_check(bodies.size() == solid.size(), "%s: exactly %d static bodies (walls + %s), found %d" % [label, solid.size(), "table/altar", bodies.size()])
	var floor_rect := s.get_node("Floor") as Control
	var r := Rect2(floor_rect.global_position, floor_rect.size)
	var cam := s.get_node("Player/Camera2D") as Camera2D
	_check(cam.limit_left == int(r.position.x) and cam.limit_top == int(r.position.y) and cam.limit_right == int(r.end.x) and cam.limit_bottom == int(r.end.y),
		"%s: camera limits equal the room rect %s (got %d,%d,%d,%d)" % [label, r, cam.limit_left, cam.limit_top, cam.limit_right, cam.limit_bottom])
	# The scene file's own text (the player script adds its existing "[F] Interact"
	# prompt at runtime; that string is not the room's).
	var texts: Array = []
	var fresh := (load(s.scene_file_path) as PackedScene).instantiate()
	_ui_texts(fresh, texts)
	fresh.free()
	var bad := texts.filter(func(t): return t != "" and not ALLOWED_TEXT.has(t))
	_check(not texts.is_empty() and bad.is_empty(), "%s: every Label/RichTextLabel/Button text in the scene is empty or allowlisted (%s; bad: %s)" % [label, str(texts), str(bad)])


func _joy_interact() -> void:
	var down := InputEventJoypadButton.new()
	down.device = 0
	down.button_index = _joy_button
	down.pressed = true
	Input.parse_input_event(down)
	await process_frame
	await process_frame
	var up := InputEventJoypadButton.new()
	up.device = 0
	up.button_index = _joy_button
	up.pressed = false
	Input.parse_input_event(up)
	await process_frame


## Puts the player at `pos` and waits until it targets `target` (or a deadline).
func _target(player: Node, pos: Vector2, target: Node) -> bool:
	# The player ignores interact while a dialogue box is still open (player_topdown.gd _input).
	await _wait(func(): return not _dm().is_active, 10000)
	(player as Node2D).global_position = pos
	for i in 4:
		await physics_frame
	return await _wait(func(): return player.nearby_interactable == target, 3000)


func _shrine_settled() -> bool:
	return current_scene != null and _scene_path() == SHRINE and not _st().is_transitioning \
		and not current_scene._arrival_running


func _write_slot1(path: String) -> void:
	var f := FileAccess.open(SLOT1, FileAccess.WRITE)
	f.store_buffer(FileAccess.get_file_as_bytes(path))
	f.close()


# ── C1 house (AC-1, AC-2; AC-13 no-collision parts) ──────────────────────────

func _c1_house_room() -> void:
	print("[C1 house: walls, table, camera, labels, inspect spots (AC-1, AC-13)]")
	_preset(["ch1_stew_done"])
	_start([])
	var h := await _load_scene(HOUSE)
	_check(_scene_path() == HOUSE and h.get_script().resource_path == HOUSE_SRC, "house scene runs ch1_elara_house.gd")
	_check_room_shapes("house", h,
		{"top wall": Vector2(320, 16), "bottom wall": Vector2(320, 368), "left wall": Vector2(16, 192), "right wall": Vector2(624, 192), "table": Vector2(320, 192)},
		{"floor": Vector2(480, 280), "Elara placeholder": Vector2(320, 133), "Bandages": Vector2(80, 56), "Herbs": Vector2(560, 56),
			"Focuses": Vector2(56, 192), "Map": Vector2(584, 192), "Cloak": Vector2(216, 336)})
	var hp := h.get_node("Player")
	var door := h.get_node("Door") as Area2D
	_check(door.is_in_group("interactable") and door.has_meta("interact_handler"), "house door is bound to a handler")
	await _wait(func(): return not h._busy(), 5000)
	_check(_count(STEW_FIRST) == 0 and not h._stew_running and h._can_interact_with(door), "entry with ch1_stew_done: no stew line, door active")
	for spot in INSPECT_LINES:
		var a := h.get_node(spot) as Area2D
		_check(a.is_in_group("interactable") and a.has_meta("interact_handler"), "inspect %s is bound to a handler" % spot)
		a.get_meta("interact_handler").call(hp)
		await _idle(h)
		_check(_count(INSPECT_LINES[spot]) == 1, "inspect %s plays its elara_house.dlg node (first line seen once)" % spot)
	await _end_scene()


## A source scan: every string literal a room script hands to a UI node or an
## indicator is empty or allowlisted.
func _c1_source_strings() -> void:
	print("[C1/C4 literal scan of the room scripts (AC-1, AC-5)]")
	var sink := RegEx.create_from_string(UI_SINK_RE)
	var lit := RegEx.create_from_string("\"((?:[^\"\\\\]|\\\\.)*)\"")
	for src_path in [HOUSE_SRC, SHRINE_SRC]:
		var found: Array = []
		var bad: Array = []
		for line in FileAccess.get_file_as_string(src_path).split("\n"):
			if line.strip_edges().begins_with("#") or sink.search(line) == null:
				continue
			for m in lit.search_all(line):
				var s: String = m.get_string(1)
				found.append(s)
				if s != "" and not ALLOWED_TEXT.has(s):
					bad.append(s)
		_check(bad.is_empty(), "%s: no new player-visible string literal (bad: %s)" % [src_path.get_file(), str(bad)])
		if src_path == SHRINE_SRC:
			for s in SHRINE_MOVED:
				_check(found.has(s), "shrine script passes the moved literal \"%s\" to the UI" % s)


func _house_stew(label: String, picks: Array, skip_all: bool, abort: bool) -> void:
	print("[C1 stew in the house: %s (AC-2)]" % label)
	var gm := _gm()
	_preset(_golden["stew"]["preset_flags"])
	_start(picks)
	change_scene_to_file(HOUSE)
	await _frames(4)
	var h := current_scene
	var hp := h.get_node("Player")
	h._on_door_interaction(hp)
	await process_frame
	_check(not _st().is_transitioning and current_scene == h, "%s: door inactive while the stew runs" % label)
	_check(not h._can_interact_with(h.get_node("Door")), "%s: door offers no prompt while the stew runs" % label)
	var skipped := false
	var deadline := Time.get_ticks_msec() + 90000
	while Time.get_ticks_msec() < deadline and is_instance_valid(h) and h._stew_running:
		if skip_all and not skipped and _count(STEW_SECOND) > 0:
			skipped = true
			_dm().skip_all()
		if abort and gm.has_flag("ch1_stew_asked_where"):
			h.queue_free()
			break
		await process_frame
	await _frames(15)
	if abort:
		_check(_emit_count("ch1_stew_done") == 0 and not gm.has_flag("ch1_stew_done"), "%s: freeing the house mid-run emits nothing" % label)
		await _end_scene()
		return
	_check(_emit_count("ch1_stew_done") == 1, "%s: exactly one ch1_stew_done emit (%d)" % [label, _emit_count("ch1_stew_done")])
	_check(_count(STEW_FIRST) == 1, "%s: elara_house start played once (first line seen once)" % label)
	if skip_all:
		_check(skipped, "%s: skip_all() was called on the stew's second line" % label)
	else:
		_check(_focus_ok(), "%s: after the stew's last choice the GUI focus owner is null or visible (AC-12)" % label)
	_check(_state() == "EXPLORATION" and not h._busy(), "%s: EXPLORATION and the door active after the stew" % label)
	# Re-entry with the flag: no stew, door active.
	await _end_scene()
	_seen_text.clear()
	_start([])
	var h2 := await _load_scene(HOUSE)
	await _frames(30)
	_check(_count(STEW_FIRST) == 0 and not h2._stew_running and not h2._busy() and _emit_count("ch1_stew_done") == 1,
		"%s: re-entry with the flag plays no stew line, door active, no second emit" % label)
	await _end_scene()


func _c1_stew_paths() -> void:
	# The "topics then (Just eat.)" path is the golden replay in _c2_c3_village_loop.
	await _house_stew("(Just eat.) straight away", [4], false, false)
	await _house_stew("skip_all on line 2", [4], true, false)
	await _house_stew("freed mid-run", [0], false, true)


# ── C2 getting there, C3 coming back (AC-3, AC-4) + C8 stew golden (AC-11) ───

func _c2_c3_village_loop() -> void:
	print("[C2/C3/C8 village invite -> door -> house stew (golden) -> door -> afternoon]")
	var gm := _gm()
	var bc := _bc()
	var stew_gold: Dictionary = _golden["stew"]
	_preset(stew_gold["preset_flags"])
	var v := await _load_scene(VILLAGE)
	var player := v.get_node("Player")
	if not player.is_in_group("player"):
		player.add_to_group("player")
	var door := v.get_node_or_null("Doors/ElaraHouseDoor") as Area2D
	_check(door != null and door.is_in_group("interactable") and door.has_meta("interact_handler"), "village has Doors/ElaraHouseDoor bound to a handler")
	if door == null:
		await _end_scene()
		return
	door.get_meta("interact_handler").call(player)
	await process_frame
	_check(not _st().is_transitioning and current_scene == v, "door does nothing before the invite")
	_start(stew_gold["picks"])
	await _wait(func(): return v._invited, 60000)
	await _frames(2)
	var elara := v.get_node("NPCs/Elara") as Area2D
	_check(v._invited and not v._entrance_done and gm.current_state == gm.GameState.EXPLORATION, "after the invite: player in EXPLORATION, entrance not done")
	_check(elara.position == ELARA_AT_DOOR, "Elara stands at the house door %s" % elara.position)
	_check(_count(GATE_LINE) == 1 and _count(INVITE_LINE) == 1, "gate and invite seen once on arrival")
	_check(_count(STEW_FIRST) == 0 and _emit_count("ch1_stew_done") == 0, "no stew in the village")
	v._on_old_fen_interaction(player)
	v._on_boar_trigger(player)
	v._on_bridge_trigger(player)
	await process_frame
	_check(not v.in_dialogue and not v._alarm_done and not v._bridge_running and v._seen.is_empty(), "villagers, north field and bridge inert before ch1_stew_done")
	_check(v._can_interact_with(door) and v._can_interact_with(elara) and not v._can_interact_with(v.get_node("NPCs/Guard")), "prompts before the stew: door and Elara yes, Bran no")
	_seen_text.append("-- replay mark --")   # the driver drops a line equal to the previous one
	elara.get_meta("interact_handler").call(player)
	await _idle(v)
	_check(_count(INVITE_LINE) == 2, "Elara at the door replays elara_house invite")
	# Breadcrumb step 5 (AC-3).
	var s5 := {}
	for f in ["ch1_opening_hook_started", "ch1_crash_trace_seen", "elara_met", "ch1_broken_mile_entered", "ch1_personal_goal_set", "ch1_oakhaven_entered"]:
		s5[f] = true
	var res: Dictionary = bc.resolve_objective(s5)
	_check(res["text"] == "Go to Elara's house. She's making stew." and res["scene"] == VILLAGE and res["target_node"] == "Doors/ElaraHouseDoor",
		"step 5 resolves to its unchanged text with the village and the door's node path (%s, %s)" % [res["scene"], res["target_node"]])
	(player as Node2D).global_position = Vector2(60, 60)
	bc.force_refresh()
	await _frames(3)
	_check(bc.has_arrow_target() and bc.get_arrow_scene() == VILLAGE and bc.get_arrow_target() == door.global_position, "step 5 arrow aims at the door in the village")
	_check(bc.get_arrow_text() != "", "step 5 arrow is visible in the village ('%s')" % bc.get_arrow_text())
	# Door -> house; the stew there is the golden replay.
	_start(stew_gold["picks"])
	_stew_capture_armed = true
	door.get_meta("interact_handler").call(player)
	_check(await _wait_scene(HOUSE, 30000), "door changes to the house")
	var h := current_scene
	await _frames(3)
	_check(bc.get_arrow_text() == "", "step 5 arrow hidden in the house")
	await _wait(func(): return not _stew_captured.is_empty() and not h._busy(), 90000)
	await _idle(h)
	_stew_capture_armed = false
	_check(not _stew_captured.is_empty() and _stew_captured.get("_scene", "") == HOUSE, "stew captured on the ch1_stew_done emit in the house")
	_check(_stew_captured.get("_data_vision_off", false), "stew: Data Vision off at capture")
	_golden_compare("stew", _stew_captured, stew_gold["capture"])
	_check(_count(STEW_FIRST) == 1 and _emit_count("ch1_stew_done") == 1, "topics then (Just eat.): stew once, exactly one ch1_stew_done emit")
	for f in ["ch1_stew_asked_where", "ch1_stew_asked_fracture", "ch1_stew_asked_magic", "ch1_elara_arm_talked"]:
		_check(gm.has_flag(f), "picks of all 0 asked every topic once (%s): asked topics left the list" % f)
	# House door -> village (AC-4).
	var mark := _seen_text.size()
	h.get_node("Door").get_meta("interact_handler").call(h.get_node("Player"))
	_check(await _wait_scene(VILLAGE, 30000), "house door changes to the village")
	var v2 := current_scene
	var vp := v2.get_node("Player") as Node2D
	await _frames(6)
	_check(vp.global_position.distance_to(VILLAGE_DOOR_OUTSIDE) < 2.0, "player placed at the house door %s" % vp.global_position)
	_check(v2._entrance_done and v2._invited, "arrival skipped (ch1_stew_done set)")
	await _frames(60)
	_check(_count(GATE_LINE, mark) == 0 and _count(INVITE_LINE, mark) == 0 and _count(STEW_FIRST, mark) == 0, "no arrival line on the return")
	# Code review: the step-E screenshot showed "[F] Interact" here, from before the
	# door was shut after the stew. Standing at the door, nothing may be targeted.
	_check(vp.get("nearby_interactable") == null, "back at the shut door, the player targets nothing (%s)" % vp.get("nearby_interactable"))
	var ve := v2.get_node("NPCs/Elara") as Area2D
	_check(ve.position == ELARA_AFTERNOON and ve.get_meta("interact_handler") == Callable(v2, "_on_elara_interaction"), "Elara at her afternoon spot with only the elara_repeat handler")
	ve.get_meta("interact_handler").call(vp)
	await _idle(v2)
	_check(_count(INVITE_LINE, mark) == 0, "after the stew the invite is never replayed")
	v2._on_old_fen_interaction(vp)
	await _idle(v2)
	v2._on_jessa_interaction(vp)
	await _idle(v2)
	_check(_count("Guessing.", mark) >= 1 and _count("Plants don't ask", mark) >= 1, "villagers talk after the return")
	_check(not v2._alarm_done, "no alarm after two first-time talks")
	v2._on_farmer_interaction(vp)
	await _idle(v2)
	_check(await _wait(func(): return v2._alarm_done, 60000), "the third first-time talk fires the alarm")
	_check(await _wait(func(): return v2._field_resolved, 120000), "the north field runs to its end after the return")
	await _idle(v2)
	v2._on_bridge_trigger(vp)
	_check(await _wait(func(): return _count(BRIDGE_FIRST, mark) >= 1, 60000), "the bridge trigger plays north_field bridge")
	_check(_emit_count("ch1_stew_done") == 1, "still exactly one ch1_stew_done emit")
	var v2_id := v2.get_instance_id()
	await _wait(func(): return current_scene != null and current_scene.get_instance_id() != v2_id and not _st().is_transitioning, 60000)
	await _end_scene()


# ── C4 shrine room and dressing (AC-5, AC-13 dressing) ───────────────────────

func _c4_shrine_room() -> void:
	print("[C4 shrine: walls, altar, camera, labels, dressing table (AC-5, AC-13)]")
	var packed: PackedScene = load(SHRINE)
	for row in DRESSING_ROWS:
		_preset(row[0])
		var s := packed.instantiate()
		get_root().add_child(s)
		await process_frame
		var vis: Array = []
		for n in DRESSINGS:
			if s.get_node(n).visible:
				vis.append(n)
		_check(vis == ([row[1]] if row[1] != "" else []), "dressing %s -> %s (visible %s)" % [str(row[0]), row[1] if row[1] != "" else "none", str(vis)])
		_check(not s._can_interact_with(s.get_node("StairDoor")), "stair door gated by the fragment flag (%s)" % str(row[0]))
		s.queue_free()
		await process_frame
	_preset(["ch1_tutorial_knight_defeated"])
	var sh := await _load_scene(SHRINE)
	_check(_scene_path() == SHRINE and sh.get_script().resource_path == SHRINE_SRC, "shrine scene runs ch1_shrine.gd")
	_check_room_shapes("shrine", sh,
		{"top wall": Vector2(256, 16), "bottom wall": Vector2(256, 624), "left wall": Vector2(16, 320), "right wall": Vector2(496, 320), "altar stone": Vector2(256, 96)},
		{"floor runner": Vector2(256, 300), "DressingPurged": Vector2(176, 530), "DressingKilled": Vector2(176, 548), "DressingSpared": Vector2(176, 542)})
	for n in DRESSINGS:
		_check(sh.get_node(n).find_children("*", "CollisionObject2D", true, false).is_empty(), "%s has no collision (AC-13)" % n)
	await _end_scene()


# ── C5 hand-off (AC-6) ───────────────────────────────────────────────────────

func _c5_arena_scan() -> void:
	print("[C5 arena source scan (AC-6)]")
	var src := FileAccess.get_file_as_string(ARENA_SRC)
	for term in ARENA_GONE:
		_check(src.count(term) == 0, "ch1_tutorial_knight.gd has no %s (%d)" % [term, src.count(term)])


# ── C5/C6/C8 the five post-Aldric routes (AC-6, AC-8, AC-9, AC-11, AC-12) ────

func _c6_route(name: String) -> void:
	print("[C6 route %s: arena -> shrine -> altar -> stair door -> ending]" % name)
	var gm := _gm()
	var route: Dictionary = _golden["post_aldric"]["routes"][name]
	var gold: Dictionary = route["capture"]
	var fell: bool = (gold["story_flags_true"] as Array).has("ch1_bridge_fell")
	_check((route["picks"] as Array).back() == route["meeting_choice"], "%s: golden picks end with the meeting choice %s" % [name, route["meeting_choice"]])
	_preset(route["preset_flags"])
	_start(route["picks"])
	change_scene_to_file(KNIGHT)
	await _frames(4)
	var k := current_scene
	await _wait(func(): return k.combat_started, 60000)
	_check(k.combat_started, "%s: arena fight started" % name)
	_delete_99_on_handoff = true
	k._on_boss_defeated()
	var arrived := await _wait_scene(SHRINE, 120000)
	_check(arrived, "%s: the arena changes to shrine.tscn (AC-6)" % name)
	_check(_ts_log.count(KNIGHT) == 1, "%s: one transition requested from the arena (%s)" % [name, str(_ts_log)])
	_check(gm.has_flag("ch1_tutorial_knight_defeated") and gm.player_stats.get("gold", 0) == gold["gold"], "%s: defeated flag and loot before the shrine" % name)
	if not arrived:
		await _end_scene()
		return
	var s := current_scene
	await process_frame
	_check(FileAccess.file_exists(SLOT99), "%s: fresh arrival writes the autosave (AC-8)" % name)
	if FileAccess.file_exists(SLOT99):
		var d: Variant = JSON.parse_string(FileAccess.get_file_as_string(SLOT99))
		_check(d is Dictionary and d.get("current_scene", "") == SHRINE, "%s: the autosave's current_scene is the shrine" % name)
	await _wait(func(): return _cards_seen.has("Under the old gate"), 10000)
	_check(_cards_seen.has("Under the old gate"), "%s: \"Under the old gate\" shown on arrival" % name)
	_check(not gm.has_meta(gm.SHRINE_FRESH_ARRIVAL_META), "%s: fresh-arrival meta read and cleared" % name)
	for n in DRESSINGS:
		_check(s.get_node(n).visible == (n == ROUTE_DRESSING[name]), "%s: %s visible = %s" % [name, n, n == ROUTE_DRESSING[name]])
	await _wait(_shrine_settled, 30000)
	var p: Node = s.get_node("Player")
	s._on_stair_door_interaction(p)
	_check(not s._chain_running and _state() == "EXPLORATION", "%s: stair door does nothing before the fragment" % name)
	# Altar: two handler calls in one frame. DialogueManager.run does NOT refuse a
	# second concurrent run, and collect_source_key sets its flag once, so only the
	# run count (_max_runs) proves the handler's own guard.
	_max_runs = 0
	s._on_altar_interaction(p)
	s._on_altar_interaction(p)
	_check(_state() == "DIALOGUE", "%s: the altar runs in DIALOGUE" % name)
	_check(s._altar_running and not s._can_interact_with(s.get_node("Altar")), "%s: altar guarded and offers no prompt while the fragment plays" % name)
	await _wait(func(): return _emit_count("source_key_fragment_1") > 0, 60000)
	await _frames(2)
	var labels: Array = []
	_ui_texts(s, labels)
	_check(labels.has("SOURCE KEY 1/7"), "%s: fragment_acquired shows the SOURCE KEY 1/7 indicator" % name)
	await _wait(func(): return not s._altar_running, 60000)
	_check(_max_runs == 1, "%s: the double altar call ran fragment once (most runs active at once: %d)" % [name, _max_runs])
	_check(_count(FRAG_FIRST) == 1, "%s: fragment first line seen once (%d)" % [name, _count(FRAG_FIRST)])
	_check(_emit_count("source_key_fragment_1") == 1, "%s: one source_key_fragment_1 emit (%d)" % [name, _emit_count("source_key_fragment_1")])
	_check(gm.source_key_count == 1 and _state() == "EXPLORATION", "%s: collect_source_key(1) counted it, back to EXPLORATION" % name)
	s._on_altar_interaction(p)
	_check(not s._altar_running and not s._can_interact_with(s.get_node("Altar")), "%s: altar inactive once the fragment is taken" % name)
	_check(s._can_interact_with(s.get_node("StairDoor")), "%s: stair door active after the fragment" % name)
	# Stair door: two handler calls in one frame (counted by _max_runs, as the altar).
	_capture_armed = true
	_max_runs = 0
	s._on_stair_door_interaction(p)
	s._on_stair_door_interaction(p)
	_check(_state() == "CUTSCENE", "%s: the chain runs in CUTSCENE" % name)
	_check(gm.save_game(0) == false, "%s: save_game(0) refused in the chain" % name)
	_check(gm.quick_save() == false, "%s: quick_save() refused in the chain" % name)
	await _wait(func(): return _count(JOINS_FIRST) > 0, 120000)
	_check(_focus_ok(), "%s: after the meeting choice the GUI focus owner is null or visible (AC-12)" % name)
	await _wait(func(): return not _captured.is_empty(), 120000)
	_capture_armed = false
	_check(not _captured.is_empty(), "%s: ending transition_started captured in the shrine with ch1_elara_joined" % name)
	_check(_cards_seen.has("Oakhaven, after dark"), "%s: \"Oakhaven, after dark\" shown by the stair door" % name)
	_check(_max_runs == 1, "%s: the double stair-door call ran the chain once (most runs active at once: %d)" % [name, _max_runs])
	_check(_count(MEET_FIRST) == 1, "%s: meeting first line seen once (%d)" % [name, _count(MEET_FIRST)])
	_check(_count(JOINS_FIRST) == 1, "%s: joins first line seen once (%d)" % [name, _count(JOINS_FIRST)])
	_check(gm.has_flag("ch1_bridge_fell") == fell, "%s: ch1_bridge_fell is %s" % [name, fell])
	_check((_count(BRIDGE_FELL_LINE) == 1) == fell, "%s: north_field bridge_fell played = %s" % [name, fell])
	_check(gm.source_key_count == 1, "%s: source_key_count is 1 at the end" % name)
	await _wait(func(): return not _st().is_transitioning, 60000)
	_check(_scene_path() == SHATTER, "%s: the ending scene is shatter_transition (%s)" % [name, _scene_path()])
	if not _captured.is_empty():
		_check(_captured.get("_data_vision_off", false), "%s: Data Vision off at capture" % name)
		_golden_compare(name, _captured, gold)
	await _end_scene()


# ── C5 old saves forward (AC-7) + C6 load arrival (AC-8) + C7 (AC-10 c, d) ───

func _c5_fixture(which: String, path: String, has_fragment: bool) -> void:
	print("[C5 HEAD save %s through load_game (AC-7, AC-8, AC-10)]" % which)
	_preset([])
	var gm := _gm()
	_write_slot1(path)
	if FileAccess.file_exists(SLOT99):
		DirAccess.remove_absolute(SLOT99)
	var ok: bool = await gm.load_game(1)
	_check(ok, "%s: load_game(1) returns true" % which)
	var arrived := await _wait_scene(SHRINE, 60000)
	_check(arrived, "%s: forwarded from the arena to the shrine" % which)
	_check(_arena_combat_at_handoff.size() == 1 and _arena_combat_at_handoff[0] == false, "%s: the arena started no fight (%s)" % [which, str(_arena_combat_at_handoff)])
	if not arrived:
		await _end_scene()
		return
	var s := current_scene
	await _frames(10)
	_check(FileAccess.file_exists(SLOT99) == (not has_fragment), "%s: arrival autosave written = %s" % [which, not has_fragment])
	_check((s._card_layer != null) == (not has_fragment), "%s: arrival card shown = %s" % [which, not has_fragment])
	await _wait(_shrine_settled, 30000)
	_check(s._can_interact_with(s.get_node("Altar")) == (not has_fragment), "%s: altar active = %s" % [which, not has_fragment])
	_check(s._can_interact_with(s.get_node("StairDoor")) == has_fragment, "%s: stair door active = %s" % [which, has_fragment])
	_check(gm.source_key_count == (1 if has_fragment else 0), "%s: source_key_count is %d" % [which, 1 if has_fragment else 0])
	if has_fragment:
		# The likeliest real resume: a HEAD save taken mid-meeting, played on to the
		# ending from the stair door. No second award, no trust applied twice.
		# "It's handled" (index 2) is the meeting's one trust change (fragment_one.dlg
		# `silent`: do trust elara -10). Two picks of 2: a meeting replayed twice would
		# answer "It's handled" again and show -20 (the meeting is the chain's only choice).
		var elara_before := float(gm.relationships.get("elara", 0.0))
		_start([2, 2])
		s._on_stair_door_interaction(s.get_node("Player"))
		var ended := await _wait_scene(SHATTER, 180000)
		_check(ended, "%s: played on from the stair door to shatter_transition" % which)
		_check(gm.source_key_count == 1, "%s: source_key_count still 1 at the ending (%d)" % [which, gm.source_key_count])
		_check(gm.has_flag("ch1_elara_joined") and gm.has_flag("ch1_oakhaven_left_quietly"), "%s: meeting and joins played (left quietly, Elara joined)" % which)
		var elara_delta := float(gm.relationships.get("elara", 0.0)) - elara_before
		_check(is_equal_approx(elara_delta, -10.0), "%s: the meeting's trust change applied exactly once (elara %+.0f, expected -10)" % [which, elara_delta])
		# The meeting is the chain's only choice: exactly one of the two scripted picks is used.
		_check(_picks.size() == 1, "%s: the chain asked exactly one choice (%d scripted pick(s) left)" % [which, _picks.size()])
		await _end_scene()
		return
	# AC-10(c): save in the shrine before the altar, load. AC-8: a load makes no autosave.
	_check(gm.save_game(1), "(c) save_game(1) in the shrine before the altar")
	var s_id := s.get_instance_id()
	# Deleted BEFORE the load: load_game flushes any autosave queued during its own
	# transition before it returns, so deleting afterwards would hide one.
	if FileAccess.file_exists(SLOT99):
		DirAccess.remove_absolute(SLOT99)
	var ok2: bool = await gm.load_game(1)
	_check(ok2, "(c) load_game(1) of the shrine save")
	await _wait_new_scene(s_id, SHRINE, 30000)
	await _frames(10)
	_check(not FileAccess.file_exists(SLOT99), "(c) load into the shrine makes no autosave")
	var s2 := current_scene
	_check(_scene_path() == SHRINE and s2.get_instance_id() != s_id, "(c) a new shrine instance")
	_check(s2._card_layer == null, "(c) no card on a load")
	_check(s2._can_interact_with(s2.get_node("Altar")) and not s2._can_interact_with(s2.get_node("StairDoor")), "(c) altar active, stair door inactive")
	# AC-10(d): take the fragment, save, load.
	_start([])
	s2._on_altar_interaction(s2.get_node("Player"))
	await _wait(func(): return not s2._altar_running, 60000)
	_check(gm.source_key_count == 1, "(d) the altar counted the fragment")
	_check(gm.save_game(1), "(d) save_game(1) after fragment_acquired")
	var s2_id := s2.get_instance_id()
	var ok3: bool = await gm.load_game(1)
	_check(ok3, "(d) load_game(1) of the post-fragment save")
	await _wait_new_scene(s2_id, SHRINE, 30000)
	var s3 := current_scene
	await _frames(4)
	_check(s3.get_instance_id() != s2_id and not s3._can_interact_with(s3.get_node("Altar")) and s3._can_interact_with(s3.get_node("StairDoor")), "(d) altar inactive, stair door active")
	_check(gm.source_key_count == 1 and _emit_count("source_key_fragment_1") == 1, "(d) source_key_count rose by exactly 1 over the whole route")
	await _end_scene()


# ── C7 house save/load (AC-10 a, b) ──────────────────────────────────────────

func _c7_house_save_load() -> void:
	print("[C7 (a) save in the house after the stew, load]")
	var gm := _gm()
	_preset(_golden["stew"]["preset_flags"] + ["ch1_stew_done"])
	_start([])
	var h := await _load_scene(HOUSE)
	await _wait(func(): return not h._busy(), 5000)
	_check(gm.save_game(1), "(a) save_game(1) in the house after the stew")
	var mark := _seen_text.size()
	var h_id := h.get_instance_id()
	var ok: bool = await gm.load_game(1)
	_check(ok, "(a) load_game(1)")
	await _wait_new_scene(h_id, HOUSE, 30000)
	var h2 := current_scene
	await _frames(30)
	_check(h2.get_instance_id() != h_id and _count(STEW_FIRST, mark) == 0 and not h2._busy() and h2._can_interact_with(h2.get_node("Door")), "(a) after the load: no stew, door active")
	h2.get_node("Door").get_meta("interact_handler").call(h2.get_node("Player"))
	_check(await _wait_scene(VILLAGE, 30000), "(a) leaving changes to the village")
	var v := current_scene
	await _frames(60)
	_check((v.get_node("Player") as Node2D).global_position.distance_to(VILLAGE_DOOR_OUTSIDE) < 2.0 and v._entrance_done, "(a) back at the house door, arrival skipped")
	_check(_count(GATE_LINE, mark) == 0 and _count(INVITE_LINE, mark) == 0, "(a) no arrival line")
	await _end_scene()

	print("[C7 (b) save mid-stew (DIALOGUE), load]")
	_preset(_golden["stew"]["preset_flags"])
	_start([4, 4])
	change_scene_to_file(HOUSE)
	await _frames(4)
	var hb := current_scene
	await _wait(func(): return _count(STEW_FIRST) > 0, 30000)
	_check(_state() == "DIALOGUE", "(b) the stew runs in DIALOGUE")
	_check(gm.save_game(1), "(b) save_game(1) mid-stew")
	var hb_id := hb.get_instance_id()
	var okb: bool = await gm.load_game(1)
	_check(okb, "(b) load_game(1) of the mid-stew save")
	await _wait_new_scene(hb_id, HOUSE, 30000)
	var hb2 := current_scene
	_check(hb2.get_instance_id() != hb_id, "(b) a new house instance after the load")
	await _wait(func(): return _emit_count("ch1_stew_done") > 0, 90000)
	await _idle(hb2)
	await _frames(15)
	_check(_count(STEW_FIRST) == 2, "(b) the stew replays from start after the load (first line seen again)")
	_check(_emit_count("ch1_stew_done") == 1 and gm.has_flag("ch1_stew_done"), "(b) ch1_stew_done set once (%d)" % _emit_count("ch1_stew_done"))
	await _end_scene()


# ── C7 abort (AC-10 e) ───────────────────────────────────────────────────────

func _c7_abort_mid_fragment() -> void:
	print("[C7 (e) free the shrine mid-fragment]")
	var gm := _gm()
	_preset(_golden["post_aldric"]["base_flags"] + ["ch1_tutorial_knight_defeated"])
	var s := await _load_scene(SHRINE)
	_start([0, 0, 0])
	s._on_altar_interaction(s.get_node("Player"))
	await _wait(func(): return _count(FRAG_FIRST) > 0, 30000)
	await _stop()
	s.queue_free()
	await _frames(2)
	_check(_state() == "EXPLORATION", "(e) mid-fragment: state back to EXPLORATION (%s)" % _state())
	_dm().force_reset()
	await _frames(30)
	_check(gm.source_key_count == 0 and _emit_count("source_key_fragment_1") == 0, "(e) mid-fragment: no award")
	_check(not _ts_log.has(SHRINE), "(e) mid-fragment: no shatter_transition request")


func _c7_abort_mid_chain() -> void:
	print("[C7 (e) free the shrine mid-chain]")
	var gm := _gm()
	_preset(_golden["post_aldric"]["base_flags"] + ["ch1_tutorial_knight_defeated"])
	gm.collect_source_key(1)
	_emits.clear()
	var s := await _load_scene(SHRINE)
	_start([0, 0, 0])
	s._on_stair_door_interaction(s.get_node("Player"))
	await _wait(func(): return _count(MEET_FIRST) > 0, 60000)
	await _stop()
	s.queue_free()
	await _frames(2)
	_check(_state() == "EXPLORATION", "(e) mid-chain: state back to EXPLORATION (%s)" % _state())
	_dm().force_reset()
	await _frames(120)
	_check(_ts_log.is_empty(), "(e) mid-chain: no transition requested (%s)" % str(_ts_log))
	_check(gm.source_key_count == 1 and _emit_count("source_key_fragment_1") == 0, "(e) mid-chain: no second award")
	var src := FileAccess.get_file_as_string(SHRINE_SRC)
	# A text count, exact on purpose (code review round 3): ch1_shrine.gd has 11 guards,
	# so dropping one fails here. Adding a guard means updating this number.
	_check(src.count("if not is_inside_tree(): return") == 11, "(e) the moved code keeps its 11 is_inside_tree() guards (%d)" % src.count("if not is_inside_tree(): return"))


# ── C8 STORY_BIBLE row (AC-11) ───────────────────────────────────────────────

func _c8_story_bible() -> void:
	print("[C8 STORY_BIBLE names the stew's writer (AC-11)]")
	var rows := Array(FileAccess.get_file_as_string(STORY_BIBLE).split("\n")).filter(func(l): return l.begins_with("| `ch1_stew_done`"))
	_check(rows.size() == 1 and rows[0].contains("ch1_elara_house.gd") and not rows[0].contains("ch1_oakhaven_village.gd"),
		"STORY_BIBLE's ch1_stew_done row names ch1_elara_house.gd as the writer")


# ── C9 joypad (AC-12) ────────────────────────────────────────────────────────

func _c9_joypad_house() -> void:
	print("[C9 joypad interact in the house (AC-12)]")
	_preset(["ch1_stew_done"])
	_start([])
	var h := await _load_scene(HOUSE)
	await _wait(func(): return not h._busy(), 5000)
	var p := h.get_node("Player")
	var spot := h.get_node("Bandages")
	_check(await _target(p, Vector2(80, 110), spot), "house: the player targets Bandages from beside the shelf")
	await _joy_interact()
	await _idle(h)
	_check(_count(INSPECT_LINES["Bandages"]) == 1, "house: a joypad interact press plays inspect_bandages")
	await _end_scene()


func _c9_joypad_shrine() -> void:
	print("[C9 joypad interact in the shrine (AC-12)]")
	_preset(_golden["post_aldric"]["base_flags"] + ["ch1_tutorial_knight_defeated"])
	_start([0, 0, 0])
	var s := await _load_scene(SHRINE)
	var p := s.get_node("Player")
	_check(await _target(p, Vector2(256, 190), s.get_node("Altar")), "shrine: the player targets the altar")
	await _joy_interact()
	_check(await _wait(func(): return s._altar_running or _emit_count("source_key_fragment_1") == 1, 3000), "shrine: a joypad press starts the altar")
	await _wait(func(): return not s._altar_running, 60000)
	_check(_emit_count("source_key_fragment_1") == 1 and _count(FRAG_FIRST) == 1, "shrine: joypad altar plays fragment once")
	_check(await _target(p, Vector2(256, 568), s.get_node("StairDoor")), "shrine: the player targets the stair door after the fragment")
	await _joy_interact()
	_check(await _wait(func(): return s._chain_running and _state() == "CUTSCENE", 3000), "shrine: a joypad press starts the chain (CUTSCENE)")
	await _wait(func(): return _count(MEET_FIRST) > 0, 60000)
	var stair_hits := _seen_text.size()
	await _joy_interact()
	await _joy_interact()
	await _wait(func(): return _count(JOINS_FIRST) > 0, 60000)
	_check(_count(MEET_FIRST) == 1 and _count(JOINS_FIRST) == 1 and p.nearby_interactable == null and _count(MEET_FIRST, stair_hits) == 0,
		"shrine: joypad presses during the chain are inert (meeting and joins once, no target)")
	await _end_scene()
	await _frames(2)
	_check(_state() == "EXPLORATION", "shrine: state back to EXPLORATION after leaving mid-chain")
