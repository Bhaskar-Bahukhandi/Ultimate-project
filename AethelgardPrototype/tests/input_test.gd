extends SceneTree
## Tests for InputService (bindings, rebinding, persistence, prompts, device
## switching), the Controls screen, and a guard against new hardcoded keys.
## Run: tests/run_phase0_tests.ps1 -Script res://tests/input_test.gd

const REGION_SCENE := "res://scenes/regions/fractured_wastes_region.tscn"

## Files allowed to name raw keys / keycodes:
const RAW_KEY_ALLOWLIST := [
	"res://scripts/core/input_service.gd",       # key labels, reserved Esc
	"res://scripts/ui/controls_menu.gd",         # Esc cancels a rebind
	"res://scripts/chapter3/ch3_fractured_wastes.gd",  # unreachable legacy menu (commented)
]
## Hardcoded "[F] Talk"-style hints. game_manager's "[F]" is the Firewall charm icon.
const HINT_ALLOWLIST := ["res://scripts/game_manager.gd"]

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
	var svc := _svc()
	DirAccess.remove_absolute(svc.CONFIG_PATH)
	DirAccess.remove_absolute(svc.LEGACY_CONFIG_PATH)
	svc.reset_to_defaults()

	_test_defaults()
	_test_prompts()
	_test_rebind()
	_test_persistence()
	_test_bad_config()
	_test_legacy_migration()
	await _test_device_switch()
	await _test_menu_focus()
	await _test_controls_menu()
	await _test_disconnect_pauses()
	_test_no_hardcoded_keys()

	svc.reset_to_defaults()
	print("")
	print("INPUT RESULT: %d passed, %d failed" % [_passes, _failures.size()])
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


func _svc() -> Node: return get_root().get_node("InputService")


func _key(code: Key) -> InputEventKey:
	var ev := InputEventKey.new()
	ev.physical_keycode = code
	ev.keycode = code
	ev.pressed = true
	return ev


func _pad(button: JoyButton) -> InputEventJoypadButton:
	var ev := InputEventJoypadButton.new()
	ev.button_index = button
	ev.pressed = true
	return ev


func _axis(axis: JoyAxis, value: float) -> InputEventJoypadMotion:
	var ev := InputEventJoypadMotion.new()
	ev.axis = axis
	ev.axis_value = value
	return ev


func _has(action: StringName, ev: InputEvent) -> bool:
	return InputMap.action_get_events(action).any(func(e): return _svc().same_input(e, ev))


# ── Defaults ──────────────────────────────────────────────────────────────

func _test_defaults() -> void:
	print("[defaults]")
	var svc := _svc()
	var missing: Array[String] = []
	for action in svc.ACTIONS:
		if svc.events_for(action, svc.KEYBOARD).is_empty() or svc.events_for(action, svc.GAMEPAD).is_empty():
			missing.append(String(action))
	_check(missing.is_empty(), "every action has a keyboard and a gamepad binding %s" % [missing])

	# No two actions that are live at the same time share an input.
	var clashes: Array[String] = []
	var names: Array = svc.ACTIONS.keys()
	for i in names.size():
		for j in range(i + 1, names.size()):
			var a: StringName = names[i]
			var b: StringName = names[j]
			if not svc.modes_overlap(a, b):
				continue
			for device in [svc.KEYBOARD, svc.GAMEPAD]:
				for ea in svc.events_for(a, device):
					for eb in svc.events_for(b, device):
						if svc.same_input(ea, eb):
							clashes.append("%s/%s on %s" % [a, b, svc.event_label(ea)])
	_check(clashes.is_empty(), "no conflicting default bindings %s" % [clashes])

	_check(_has(&"ui_accept", _pad(JOY_BUTTON_A)), "pad A confirms in menus (ui_accept)")
	_check(_has(&"ui_cancel", _pad(JOY_BUTTON_B)) and _has(&"ui_cancel", _key(KEY_ESCAPE)), "Esc / pad B cancel (ui_cancel)")
	_check(_has(&"pause_menu", _pad(JOY_BUTTON_START)), "Start pauses")
	_check(_has(&"lore_journal", _key(KEY_L)) and _has(&"skip", _key(KEY_TAB)), "journal (L) and skip (Tab) are actions now")


# ── Prompts ───────────────────────────────────────────────────────────────

func _test_prompts() -> void:
	print("[prompts]")
	var svc := _svc()
	_check(svc.prompt(&"interact", svc.KEYBOARD) == "F", "keyboard interact = F (%s)" % svc.prompt(&"interact", svc.KEYBOARD))
	_check(svc.prompt(&"move", svc.KEYBOARD) == "WASD", "{move} on keyboard = WASD (%s)" % svc.prompt(&"move", svc.KEYBOARD))
	_check(svc.prompt(&"move", svc.GAMEPAD) == "Left Stick", "{move} on gamepad = Left Stick")
	var expected := {&"xbox": ["A", "RT", "Y"], &"playstation": ["Cross", "R2", "Triangle"], &"nintendo": ["B", "ZR", "X"]}
	for fam in expected:
		svc.pad_family = fam
		var got := [svc.prompt(&"interact", svc.GAMEPAD), svc.prompt(&"sprint", svc.GAMEPAD), svc.prompt(&"spell", svc.GAMEPAD)]
		_check(got == expected[fam], "%s labels %s" % [fam, got])
	svc.pad_family = &"xbox"
	svc.last_device = svc.KEYBOARD
	_check(svc.fmt("[{interact}] Talk, {name} stays") == "[F] Talk, {name} stays", "fmt replaces action tokens only")
	_check(svc.fmt("no tokens") == "no tokens" and svc.fmt("{unclosed") == "{unclosed", "fmt leaves plain / broken text alone")


# ── Rebinding ─────────────────────────────────────────────────────────────

func _test_rebind() -> void:
	print("[rebind]")
	var svc := _svc()
	svc.reset_to_defaults()

	var r: Dictionary = svc.rebind(&"attack", svc.KEYBOARD, _key(KEY_P))
	_check(r["ok"] and svc.prompt(&"attack", svc.KEYBOARD) == "P" and not _has(&"attack", _key(KEY_J)), "attack J → P")

	r = svc.rebind(&"defend", svc.KEYBOARD, _key(KEY_P))
	_check(r["ok"] and &"attack" in r["swapped"] and svc.prompt(&"attack", svc.KEYBOARD) == "K"
		and svc.prompt(&"defend", svc.KEYBOARD) == "P", "binding a used key swaps (defend P, attack K)")

	r = svc.rebind(&"interact", svc.KEYBOARD, _key(KEY_Q))
	_check(r["ok"] and r["swapped"].is_empty() and _has(&"spell", _key(KEY_Q)),
		"interact (explore) may share Q with spell (combat only)")

	r = svc.rebind(&"heal", svc.KEYBOARD, _key(KEY_LEFT))
	_check(r["ok"] and &"move_left" in r["removed"] and svc.prompt(&"move_left", svc.KEYBOARD) == "A",
		"taking ← from Move Left leaves it on A, not on heal's old key")

	_check(not svc.rebind(&"attack", svc.KEYBOARD, _key(KEY_ESCAPE))["ok"], "Esc can't be bound")
	_check(not svc.rebind(&"attack", svc.GAMEPAD, _pad(JOY_BUTTON_START))["ok"], "Start can't be bound")
	_check(not svc.rebind(&"attack", svc.GAMEPAD, _pad(JOY_BUTTON_DPAD_UP))["ok"], "D-pad can't be bound")
	_check(not svc.rebind(&"attack", svc.GAMEPAD, _axis(JOY_AXIS_LEFT_X, 1.0))["ok"], "left stick can't be bound")
	_check(not svc.rebind(&"move_left", svc.GAMEPAD, _pad(JOY_BUTTON_X))["ok"], "gamepad movement is fixed")
	_check(not svc.rebind(&"attack", svc.KEYBOARD, _pad(JOY_BUTTON_X))["ok"], "a pad button can't go in the keyboard column")

	r = svc.rebind(&"attack", svc.GAMEPAD, _axis(JOY_AXIS_TRIGGER_LEFT, 0.9))
	_check(r["ok"] and svc.prompt(&"attack", svc.GAMEPAD) == "LT", "triggers can be bound (attack → LT)")

	svc.reset_to_defaults()
	_check(svc.prompt(&"attack", svc.KEYBOARD) == "J" and svc.prompt(&"attack", svc.GAMEPAD) == "X"
		and svc.prompt(&"move_left", svc.KEYBOARD) == "A", "reset restores defaults")


# ── Persistence ───────────────────────────────────────────────────────────

func _test_persistence() -> void:
	print("[persistence]")
	var svc := _svc()
	svc.reset_to_defaults()
	var cfg := ConfigFile.new()
	cfg.load(svc.CONFIG_PATH)
	_check(not cfg.has_section("bindings"), "defaults save no overrides")

	svc.rebind(&"attack", svc.KEYBOARD, _key(KEY_P))
	svc.rebind(&"spell", svc.GAMEPAD, _pad(JOY_BUTTON_RIGHT_STICK))
	cfg = ConfigFile.new()
	cfg.load(svc.CONFIG_PATH)
	var saved: PackedStringArray = cfg.get_section_keys("bindings") if cfg.has_section("bindings") else PackedStringArray()
	_check(saved.has("attack") and saved.has("spell"), "only changed actions are saved %s" % [saved])

	# Simulate a restart: wipe the live map back to project defaults, then load.
	for action in svc.ACTIONS:
		svc._set_events(action, svc._defaults[action])
	svc.load_bindings()
	_check(svc.prompt(&"attack", svc.KEYBOARD) == "P" and svc.prompt(&"spell", svc.GAMEPAD) == "RS"
		and svc.prompt(&"jump", svc.KEYBOARD) == "Space", "rebinds survive a reload")
	svc.reset_to_defaults()


func _test_bad_config() -> void:
	print("[bad config]")
	var svc := _svc()
	svc.reset_to_defaults()
	var f := FileAccess.open(svc.CONFIG_PATH, FileAccess.WRITE)
	f.store_string("[bindings\nattack = {{{ not a config")
	f.close()
	svc.load_bindings()
	_check(svc.prompt(&"attack", svc.KEYBOARD) == "J" and svc.last_load_error() != "",
		"unreadable input.cfg → default controls, error recorded")

	var cfg := ConfigFile.new()
	cfg.set_value("meta", "version", 1)
	cfg.set_value("bindings", "attack", [{"type": "key", "code": -5}, {"type": "nonsense"}])
	cfg.set_value("bindings", "not_an_action", [{"type": "key", "code": 80}])
	cfg.set_value("bindings", "heal", "garbage")
	cfg.save(svc.CONFIG_PATH)
	svc.load_bindings()
	_check(svc.prompt(&"attack", svc.KEYBOARD) == "J" and svc.prompt(&"heal", svc.KEYBOARD) == "C",
		"invalid entries never unbind an action")
	svc.reset_to_defaults()


func _test_legacy_migration() -> void:
	print("[legacy key_bindings.cfg]")
	var svc := _svc()
	svc.reset_to_defaults()
	DirAccess.remove_absolute(svc.CONFIG_PATH)
	var old := ConfigFile.new()
	old.set_value("keys", "attack", KEY_P)
	old.set_value("keys", "move_left", KEY_A)   # unchanged from default
	old.set_value("keys", "pause_menu", KEY_ESCAPE)  # no longer rebindable: ignored
	old.save(svc.LEGACY_CONFIG_PATH)
	svc.load_bindings()
	var kb_left: Array = svc.events_for(&"move_left", svc.KEYBOARD).map(func(e): return svc.event_label(e))
	_check(svc.prompt(&"attack", svc.KEYBOARD) == "P", "old rebind (attack = P) carried over")
	_check(kb_left == ["A", "←"], "Move Left keeps A first and ← second %s" % [kb_left])
	var cfg := ConfigFile.new()
	cfg.load(svc.CONFIG_PATH)
	var saved: PackedStringArray = cfg.get_section_keys("bindings") if cfg.has_section("bindings") else PackedStringArray()
	_check(saved == PackedStringArray(["attack"]), "migration saves only the real change %s" % [saved])
	DirAccess.remove_absolute(svc.LEGACY_CONFIG_PATH)
	svc.reset_to_defaults()


# ── Device switching ──────────────────────────────────────────────────────

func _test_device_switch() -> void:
	print("[device switch]")
	var svc := _svc()
	svc.last_device = svc.KEYBOARD
	var label := Label.new()
	get_root().add_child(label)
	svc.bind_text(label, "[{interact}] Talk")
	_check(label.text == "[F] Talk", "bound label starts with the keyboard key")
	var seen := [0]
	var on_changed := func(_d): seen[0] += 1
	svc.device_changed.connect(on_changed)
	svc._input(_axis(JOY_AXIS_RIGHT_X, 0.1))   # stick drift: not a switch
	_check(svc.last_device == svc.KEYBOARD, "stick drift doesn't switch to gamepad")
	svc._input(_pad(JOY_BUTTON_X))
	_check(svc.last_device == svc.GAMEPAD and seen[0] == 1 and label.text == "[A] Talk",
		"a pad press switches prompts to the gamepad (%s)" % label.text)
	svc._input(_key(KEY_W))
	_check(svc.last_device == svc.KEYBOARD and label.text == "[F] Talk", "a key press switches back")
	svc.device_changed.disconnect(on_changed)
	label.free()
	svc._input(_pad(JOY_BUTTON_X))   # freed label must be skipped, not crash
	svc._input(_key(KEY_W))
	_check(true, "freed bound labels are dropped safely")


func _test_menu_focus() -> void:
	print("[gamepad menu focus]")
	var cs := get_root().get_node("ContextStack")
	cs.clear()
	var layer := CanvasLayer.new()
	var box := VBoxContainer.new()
	var disabled := Button.new()
	disabled.disabled = true
	var first := Button.new()
	box.add_child(disabled)
	box.add_child(first)
	layer.add_child(box)
	get_root().add_child(layer)
	await process_frame
	cs.push(&"test_menu", layer)
	var vp := get_root()
	if vp.gui_get_focus_owner():
		vp.gui_get_focus_owner().release_focus()
	var down := _pad(JOY_BUTTON_DPAD_DOWN)
	_svc()._input(down)
	_check(vp.gui_get_focus_owner() == first, "pad navigation with nothing focused focuses the menu's first usable button")
	cs.pop(&"test_menu")
	layer.free()
	_svc()._input(_key(KEY_W))


func _test_controls_menu() -> void:
	print("[controls screen]")
	var svc := _svc()
	var cs := get_root().get_node("ContextStack")
	var gm := get_root().get_node("GameManager")
	var pause := get_root().get_node("PauseScreen")
	svc.reset_to_defaults()
	cs.clear()
	change_scene_to_file(REGION_SCENE)
	for i in 4:
		await process_frame
	gm.change_state(gm.GameState.EXPLORATION)
	get_root().get_node("DialogueManager").force_reset()
	await process_frame

	pause.toggle_pause()
	var menu_script := load("res://scripts/ui/controls_menu.gd")
	var menu: CanvasLayer = menu_script.open(pause)
	await process_frame
	_check(menu != null and cs.top() == &"controls" and pause.is_paused, "Controls opens on top of pause")

	menu._start_listen(&"attack", svc.KEYBOARD)
	menu._input(_key(KEY_P))
	_check(svc.prompt(&"attack", svc.KEYBOARD) == "P" and not menu.is_listening(), "listening + key press rebinds")
	var btn: Button = menu._buttons["attack|keyboard"]
	_check(btn.text == "P", "row shows the new key (%s)" % btn.text)

	menu._start_listen(&"attack", svc.GAMEPAD)
	menu._input(_key(KEY_ESCAPE))
	_check(not menu.is_listening() and svc.prompt(&"attack", svc.GAMEPAD) == "X", "Esc cancels a pad rebind")

	menu._start_listen(&"attack", svc.GAMEPAD)
	menu._input(_axis(JOY_AXIS_LEFT_Y, 1.0))
	_check(menu.is_listening(), "left stick is ignored while waiting for a button")
	menu._input(_pad(JOY_BUTTON_Y))
	# Attack is live while exploring and in combat, so it collides with both
	# Spell (combat) and Lore Journal (explore) on Y; each takes attack's old X.
	_check(svc.prompt(&"attack", svc.GAMEPAD) == "Y" and svc.prompt(&"spell", svc.GAMEPAD) == "X"
		and svc.prompt(&"lore_journal", svc.GAMEPAD) == "X", "pad rebind swaps (attack Y; spell and journal X)")

	var esc := InputEventAction.new()
	esc.action = "ui_cancel"
	esc.pressed = true
	menu._input(esc)
	var pause_esc := InputEventAction.new()
	pause_esc.action = "pause_menu"
	pause_esc.pressed = true
	pause._input(pause_esc)   # the same Esc press reaching pause next
	await process_frame
	_check(not cs.is_open(&"controls") and pause.is_paused and cs.top() == &"pause",
		"one Esc closes Controls but leaves pause open")
	await process_frame
	pause._input(esc)   # cancel (pad B) on the pause menu itself
	_check(not pause.is_paused and not paused, "cancel / pad B closes pause and resumes")
	svc.reset_to_defaults()


func _test_disconnect_pauses() -> void:
	print("[controller disconnect]")
	var svc := _svc()
	var cs := get_root().get_node("ContextStack")
	var gm := get_root().get_node("GameManager")
	var pause := get_root().get_node("PauseScreen")
	cs.clear()
	gm.change_state(gm.GameState.EXPLORATION)
	svc.last_device = svc.GAMEPAD
	svc._on_joy_connection_changed(0, false)
	_check(pause.is_paused and svc.last_device == svc.KEYBOARD, "losing the controller mid-play pauses and switches prompts to keyboard")
	pause.toggle_pause()
	svc.last_device = svc.KEYBOARD
	svc._on_joy_connection_changed(0, false)
	_check(not pause.is_paused, "a keyboard player isn't paused by a pad disconnect")


# ── Guard: no new hardcoded keys ──────────────────────────────────────────

func _test_no_hardcoded_keys() -> void:
	print("[no hardcoded keys]")
	var raw_key := RegEx.create_from_string("keycode\\s*==|is_physical_key_pressed|is_key_pressed|\\bKEY_[A-Z0-9_]+\\b")
	var hint := RegEx.create_from_string("\"[^\"]*(\\[(F|E|J|K|Q|C|X|R|M|I|L|TAB|Tab|ESC|Esc|SPACE|Space|Shift|SHIFT|ENTER|Enter|WASD|A/D)\\]|Press (SPACE|Space|ESC|Esc|TAB|Tab|ENTER|Enter|[A-Z])\\b)")
	var raw_hits: Array[String] = []
	var hint_hits: Array[String] = []
	for path in _gd_files("res://scripts"):
		var lines := FileAccess.get_file_as_string(path).split("\n")
		for i in lines.size():
			var line: String = lines[i]
			if line.strip_edges().begins_with("#"):
				continue
			if not path in RAW_KEY_ALLOWLIST and raw_key.search(line) and not "ItemType" in line and not "KEY_ITEM" in line:
				raw_hits.append("%s:%d" % [path.get_file(), i + 1])
			if not path in HINT_ALLOWLIST and hint.search(line):
				hint_hits.append("%s:%d" % [path.get_file(), i + 1])
	_check(raw_hits.is_empty(), "no raw keycode checks outside InputService %s" % [raw_hits])
	_check(hint_hits.is_empty(), "no hardcoded key hints — use {action} tokens %s" % [hint_hits])


func _gd_files(dir: String) -> Array[String]:
	var out: Array[String] = []
	for f in DirAccess.get_files_at(dir):
		if f.ends_with(".gd"):
			out.append(dir.path_join(f))
	for d in DirAccess.get_directories_at(dir):
		out.append_array(_gd_files(dir.path_join(d)))
	return out
