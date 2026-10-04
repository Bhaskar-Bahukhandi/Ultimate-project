extends Node
## InputService — the ONE owner of input bindings at runtime:
##   • defaults (keyboard + gamepad) come from project.godot's InputMap,
##   • the player's rebinds are saved to user://input.cfg and applied at boot,
##   • tracks whether the player last used keyboard or gamepad (and which pad
##     family) so every on-screen prompt shows the right button,
##   • pauses the game when the controller disconnects mid-play,
##   • gives menus gamepad focus when nothing is focused.
## Nothing else calls InputMap.action_add_event / action_erase_event.
##
## Prompts:
##   InputService.prompt(&"interact")              -> "F" / "A" / "Cross" …
##   InputService.fmt("[{interact}] Talk")          -> "[F] Talk" / "[A] Talk"
##   InputService.bind_text(label, "[{interact}] Talk")   # re-renders itself
##                                                        # when the device or bindings change
## Tokens are any InputMap action name, plus {move} and {move_lr}.

signal device_changed(device: StringName)
signal bindings_changed

const KEYBOARD := &"keyboard"
const GAMEPAD := &"gamepad"

const CONFIG_PATH := "user://input.cfg"
const LEGACY_CONFIG_PATH := "user://key_bindings.cfg"   # pre-2026-10 keyboard-only rebinds
const CONFIG_VERSION := 1

## How far a stick/trigger must move to count as a press (rebinding, device detection).
const AXIS_PRESS := 0.6

## Every rebindable action, in the order the Controls screen lists them.
## `modes` = where the action is live. Two actions may share a button only if
## their modes never overlap: pad A is jump in combat and interact while
## exploring. Rebinding onto a button used by an overlapping action swaps them.
## `pad_fixed` = the gamepad binding can't be changed (stick movement).
const ACTIONS := {
	&"move_left":      {"label": "Move Left",       "modes": [&"explore", &"combat"], "pad_fixed": true},
	&"move_right":     {"label": "Move Right",      "modes": [&"explore", &"combat"], "pad_fixed": true},
	&"move_up":        {"label": "Move Up / Aim Up", "modes": [&"explore", &"combat"], "pad_fixed": true},
	&"move_down":      {"label": "Move Down / Pogo", "modes": [&"explore", &"combat"], "pad_fixed": true},
	&"jump":           {"label": "Jump",            "modes": [&"combat", &"dialogue"]},
	&"attack":         {"label": "Attack",          "modes": [&"explore", &"combat"]},
	&"defend":         {"label": "Parry / Block",   "modes": [&"combat"]},
	&"sprint":         {"label": "Dash / Sprint",   "modes": [&"explore", &"combat"]},
	&"spell":          {"label": "Spell",           "modes": [&"combat"]},
	&"heal":           {"label": "Heal",            "modes": [&"combat"]},
	&"root_access":    {"label": "Root Access",     "modes": [&"explore", &"combat"]},
	&"perfect_delete": {"label": "Perfect Delete",  "modes": [&"combat"]},
	&"flee_combat":    {"label": "Flee",            "modes": [&"combat"]},
	&"interact":       {"label": "Interact / Talk", "modes": [&"explore"]},
	&"data_vision":    {"label": "Data Vision",     "modes": [&"explore"]},
	&"world_map":      {"label": "World Map",       "modes": [&"explore"]},
	&"lore_journal":   {"label": "Lore Journal",    "modes": [&"explore"]},
	&"status_window":  {"label": "Status Window",   "modes": [&"explore", &"combat"]},
	&"skip":           {"label": "Skip (hold in dialogue)", "modes": [&"dialogue", &"combat"]},
}

## Never bindable to gameplay actions: Esc/Start open the pause menu and
## cancel menus; the D-pad and left stick are movement and menu navigation.
const RESERVED_KEYS := [KEY_ESCAPE]
const RESERVED_PAD_BUTTONS := [JOY_BUTTON_START, JOY_BUTTON_GUIDE,
	JOY_BUTTON_DPAD_UP, JOY_BUTTON_DPAD_DOWN, JOY_BUTTON_DPAD_LEFT, JOY_BUTTON_DPAD_RIGHT]
const RESERVED_PAD_AXES := [JOY_AXIS_LEFT_X, JOY_AXIS_LEFT_Y]

const PAD_BUTTON_LABELS := {
	&"xbox": {
		JOY_BUTTON_A: "A", JOY_BUTTON_B: "B", JOY_BUTTON_X: "X", JOY_BUTTON_Y: "Y",
		JOY_BUTTON_LEFT_SHOULDER: "LB", JOY_BUTTON_RIGHT_SHOULDER: "RB",
		JOY_BUTTON_BACK: "View", JOY_BUTTON_START: "Menu",
		JOY_BUTTON_LEFT_STICK: "LS", JOY_BUTTON_RIGHT_STICK: "RS",
	},
	&"playstation": {
		JOY_BUTTON_A: "Cross", JOY_BUTTON_B: "Circle", JOY_BUTTON_X: "Square", JOY_BUTTON_Y: "Triangle",
		JOY_BUTTON_LEFT_SHOULDER: "L1", JOY_BUTTON_RIGHT_SHOULDER: "R1",
		JOY_BUTTON_BACK: "Create", JOY_BUTTON_START: "Options",
		JOY_BUTTON_LEFT_STICK: "L3", JOY_BUTTON_RIGHT_STICK: "R3",
	},
	# Godot's JOY_BUTTON_A is the bottom button, which Nintendo labels "B".
	&"nintendo": {
		JOY_BUTTON_A: "B", JOY_BUTTON_B: "A", JOY_BUTTON_X: "Y", JOY_BUTTON_Y: "X",
		JOY_BUTTON_LEFT_SHOULDER: "L", JOY_BUTTON_RIGHT_SHOULDER: "R",
		JOY_BUTTON_BACK: "-", JOY_BUTTON_START: "+",
		JOY_BUTTON_LEFT_STICK: "LS", JOY_BUTTON_RIGHT_STICK: "RS",
	},
}
const PAD_COMMON_LABELS := {
	JOY_BUTTON_DPAD_UP: "D-Pad Up", JOY_BUTTON_DPAD_DOWN: "D-Pad Down",
	JOY_BUTTON_DPAD_LEFT: "D-Pad Left", JOY_BUTTON_DPAD_RIGHT: "D-Pad Right",
	JOY_BUTTON_GUIDE: "Home",
}
const TRIGGER_LABELS := {
	&"xbox": ["LT", "RT"], &"playstation": ["L2", "R2"], &"nintendo": ["ZL", "ZR"],
}

var last_device: StringName = KEYBOARD
var pad_family: StringName = &"xbox"

var _defaults: Dictionary = {}        # action -> Array[InputEvent] (from project.godot)
var _bound_texts: Array = []          # [{ref: WeakRef, template, property}]
var _load_error: String = ""


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for action in ACTIONS:
		if not InputMap.has_action(action):
			push_error("[InputService] '%s' is missing from project.godot's InputMap" % action)
			continue
		_defaults[action] = _copy_events(InputMap.action_get_events(action))
	load_bindings()
	Input.joy_connection_changed.connect(_on_joy_connection_changed)
	if not Input.get_connected_joypads().is_empty():
		pad_family = _family_for(Input.get_connected_joypads()[0])


# ── Device tracking ───────────────────────────────────────────────────────

func _input(event: InputEvent) -> void:
	var device := _device_of(event)
	if device == &"":
		return
	if device == GAMEPAD:
		var fam := _family_for(event.device)
		if fam != pad_family:
			pad_family = fam
			if last_device == GAMEPAD:
				_refresh_bound_texts()
				device_changed.emit(GAMEPAD)
		_ensure_menu_focus(event)
	if device != last_device:
		last_device = device
		_refresh_bound_texts()
		device_changed.emit(device)


func _device_of(event: InputEvent) -> StringName:
	if event is InputEventKey and event.pressed:
		return KEYBOARD
	if event is InputEventMouseButton and event.pressed:
		return KEYBOARD
	if event is InputEventJoypadButton and event.pressed:
		return GAMEPAD
	if event is InputEventJoypadMotion and absf(event.axis_value) >= AXIS_PRESS:
		return GAMEPAD
	return &""


func _family_for(device_id: int) -> StringName:
	var joy_name := Input.get_joy_name(device_id).to_lower()
	for hint in ["playstation", "dualshock", "dualsense", "ps3", "ps4", "ps5", "sony"]:
		if hint in joy_name:
			return &"playstation"
	for hint in ["nintendo", "switch", "pro controller", "joy-con", "joycon"]:
		if hint in joy_name:
			return &"nintendo"
	return &"xbox"


func _on_joy_connection_changed(device_id: int, connected: bool) -> void:
	if connected:
		pad_family = _family_for(device_id)
		return
	if not Input.get_connected_joypads().is_empty():
		return
	var was_pad := last_device == GAMEPAD
	last_device = KEYBOARD
	_refresh_bound_texts()
	device_changed.emit(KEYBOARD)
	# Controller lost mid-play: pause instead of letting the player die.
	if was_pad and has_node("/root/GameManager") and has_node("/root/PauseScreen") \
			and GameManager.current_state in [GameManager.GameState.EXPLORATION, GameManager.GameState.COMBAT] \
			and not ContextStack.any_open() and not DialogueManager.is_active:
		PauseScreen.toggle_pause()


## Menus built in code often never grab focus, so a gamepad can't reach their
## buttons. On a gamepad navigation press with nothing focused, focus the
## first usable control of the open menu (or the title/game-over screen).
func _ensure_menu_focus(event: InputEvent) -> void:
	if not (event.is_action_pressed("ui_up") or event.is_action_pressed("ui_down")
			or event.is_action_pressed("ui_left") or event.is_action_pressed("ui_right")
			or event.is_action_pressed("ui_accept")):
		return
	var vp := get_viewport()
	if vp.gui_get_focus_owner() != null:
		return
	var root := _menu_root()
	if root == null:
		return
	var target := first_focusable(root)
	if target:
		target.grab_focus()
		vp.set_input_as_handled()   # this press only selects; the next one acts


func _menu_root() -> Node:
	var scene := get_tree().current_scene
	if ContextStack.any_open():
		var owner_node := ContextStack.top_owner()
		# Scene-owned panels (Root Access in an arena) manage their own focus;
		# searching the whole scene could land on a HUD button.
		if owner_node != null and owner_node != scene:
			return owner_node
		return null
	if has_node("/root/GameManager") and GameManager.current_state in [GameManager.GameState.MENU, GameManager.GameState.GAME_OVER]:
		return scene
	return null


## First visible, enabled control under `root` that can take focus.
static func first_focusable(root: Node) -> Control:
	for node in root.find_children("*", "Control", true, false):
		var c := node as Control
		if c.focus_mode == Control.FOCUS_NONE or not c.is_visible_in_tree():
			continue
		if c is BaseButton and c.disabled:
			continue
		# A SpinBox takes focus through its LineEdit (ui_up/ui_down step it).
		var spin_edit := c is LineEdit and c.get_parent() is SpinBox
		if not (c is BaseButton or c is Range or c is TabBar or c is ItemList or spin_edit):
			continue
		return c
	return null


# ── Prompts ───────────────────────────────────────────────────────────────

## Label for the button bound to `action` on `device` (default: last used).
func prompt(action: StringName, device: StringName = &"") -> String:
	if device == &"":
		device = last_device
	if action == &"move" or action == &"move_lr":
		return _move_prompt(action, device)
	if not InputMap.has_action(action):
		return str(action)
	for ev in InputMap.action_get_events(action):
		if _event_device(ev) == device:
			return event_label(ev)
	return "Unbound"


## Replace {action} tokens with the current button labels.
func fmt(text: String) -> String:
	if "{" not in text:
		return text
	var out := ""
	var i := 0
	while i < text.length():
		var open := text.find("{", i)
		if open == -1:
			out += text.substr(i)
			break
		var close := text.find("}", open)
		if close == -1:
			out += text.substr(i)
			break
		out += text.substr(i, open - i)
		var token := StringName(text.substr(open + 1, close - open - 1))
		if token == &"move" or token == &"move_lr" or InputMap.has_action(token):
			out += prompt(token)
		else:
			out += text.substr(open, close - open + 1)
		i = close + 1
	return out


## Set `node.property` to fmt(template) now and whenever the device or the
## bindings change. Freed nodes are dropped automatically.
func bind_text(node: Object, template: String, property: StringName = &"text") -> void:
	if node == null:
		return
	for entry in _bound_texts:
		if entry["ref"].get_ref() == node and entry["property"] == property:
			entry["template"] = template
			node.set(property, fmt(template))
			return
	_bound_texts.append({"ref": weakref(node), "template": template, "property": property})
	node.set(property, fmt(template))


func _refresh_bound_texts() -> void:
	var alive: Array = []
	for entry in _bound_texts:
		var node: Object = entry["ref"].get_ref()
		if node == null:
			continue
		node.set(entry["property"], fmt(entry["template"]))
		alive.append(entry)
	_bound_texts = alive


func _move_prompt(which: StringName, device: StringName) -> String:
	if device == GAMEPAD:
		return "Left Stick"
	var dirs: Array = [&"move_left", &"move_right"] if which == &"move_lr" else [&"move_up", &"move_left", &"move_down", &"move_right"]
	var labels: Array[String] = []
	for d in dirs:
		labels.append(prompt(d, KEYBOARD))
	if labels.all(func(l): return l.length() == 1):
		return "".join(labels) if which == &"move" else "/".join(labels)
	return "/".join(labels)


## Human label for one bound event, for the current pad family.
func event_label(ev: InputEvent) -> String:
	if ev is InputEventKey:
		return _key_label(ev)
	if ev is InputEventJoypadButton:
		var fam: Dictionary = PAD_BUTTON_LABELS.get(pad_family, PAD_BUTTON_LABELS[&"xbox"])
		if fam.has(ev.button_index):
			return fam[ev.button_index]
		return PAD_COMMON_LABELS.get(ev.button_index, "Button %d" % ev.button_index)
	if ev is InputEventJoypadMotion:
		var triggers: Array = TRIGGER_LABELS.get(pad_family, TRIGGER_LABELS[&"xbox"])
		match ev.axis:
			JOY_AXIS_TRIGGER_LEFT: return triggers[0]
			JOY_AXIS_TRIGGER_RIGHT: return triggers[1]
			JOY_AXIS_LEFT_X: return "Left Stick " + ("Left" if ev.axis_value < 0 else "Right")
			JOY_AXIS_LEFT_Y: return "Left Stick " + ("Up" if ev.axis_value < 0 else "Down")
			JOY_AXIS_RIGHT_X: return "Right Stick " + ("Left" if ev.axis_value < 0 else "Right")
			JOY_AXIS_RIGHT_Y: return "Right Stick " + ("Up" if ev.axis_value < 0 else "Down")
		return "Axis %d" % ev.axis
	if ev is InputEventMouseButton:
		return "Mouse %d" % ev.button_index
	return "?"


func _key_label(ev: InputEventKey) -> String:
	var code: Key = ev.physical_keycode if ev.physical_keycode != KEY_NONE else ev.keycode
	# Show what's printed on the player's keyboard (AZERTY Q for physical A).
	# The headless display server can't map layouts.
	if ev.physical_keycode != KEY_NONE and DisplayServer.get_name() != "headless":
		var local := DisplayServer.keyboard_get_keycode_from_physical(ev.physical_keycode)
		if local != KEY_NONE:
			code = local
	match code:
		KEY_ESCAPE: return "Esc"
		KEY_ENTER: return "Enter"
		KEY_KP_ENTER: return "Num Enter"
		KEY_SHIFT: return "Shift"
		KEY_CTRL: return "Ctrl"
		KEY_ALT: return "Alt"
		KEY_SPACE: return "Space"
		KEY_TAB: return "Tab"
		KEY_LEFT: return "←"
		KEY_RIGHT: return "→"
		KEY_UP: return "↑"
		KEY_DOWN: return "↓"
	return OS.get_keycode_string(code)


# ── Bindings ──────────────────────────────────────────────────────────────

func is_rebindable(action: StringName, device: StringName) -> bool:
	if not ACTIONS.has(action):
		return false
	return not (device == GAMEPAD and ACTIONS[action].get("pad_fixed", false))


## Events of `action` that belong to `device`, primary first.
func events_for(action: StringName, device: StringName) -> Array[InputEvent]:
	var out: Array[InputEvent] = []
	if InputMap.has_action(action):
		for ev in InputMap.action_get_events(action):
			if _event_device(ev) == device:
				out.append(ev)
	return out


## Turn a raw press into a clean, device-agnostic binding, or null if it
## can't be bound (wrong device, reserved button, stick not pushed far enough).
func normalize(event: InputEvent, device: StringName) -> InputEvent:
	if device == KEYBOARD and event is InputEventKey and event.pressed:
		var code: Key = event.physical_keycode if event.physical_keycode != KEY_NONE else event.keycode
		if code == KEY_NONE or code in RESERVED_KEYS:
			return null
		var k := InputEventKey.new()
		k.physical_keycode = code
		k.device = -1
		return k
	if device == GAMEPAD and event is InputEventJoypadButton and event.pressed:
		if event.button_index in RESERVED_PAD_BUTTONS:
			return null
		var b := InputEventJoypadButton.new()
		b.button_index = event.button_index
		b.device = -1
		return b
	if device == GAMEPAD and event is InputEventJoypadMotion and absf(event.axis_value) >= AXIS_PRESS:
		if event.axis in RESERVED_PAD_AXES:
			return null
		var m := InputEventJoypadMotion.new()
		m.axis = event.axis
		m.axis_value = signf(event.axis_value)
		m.device = -1
		return m
	return null


## Bind `event` as the primary `device` binding of `action`. An action that's
## live at the same time and already uses it loses it: if that was its only
## binding on this device it gets this action's old one (a swap, or unbound
## if there was none); otherwise it just keeps its other binding.
## Returns {"ok", "reason", "swapped", "removed", "unbound"} (lists of actions).
func rebind(action: StringName, device: StringName, event: InputEvent) -> Dictionary:
	var result := {"ok": false, "reason": "", "swapped": [], "removed": [], "unbound": []}
	if not is_rebindable(action, device):
		result["reason"] = "not rebindable"
		return result
	var ev := normalize(event, device)
	if ev == null:
		result["reason"] = "reserved or unsupported input"
		return result

	var mine := events_for(action, device)
	var old: InputEvent = mine[0] if not mine.is_empty() else null
	if old != null and same_input(old, ev):
		result["ok"] = true
		return result

	for other in ACTIONS:
		if other == action or not modes_overlap(action, other):
			continue
		var theirs := events_for(other, device)
		var hit := -1
		for i in theirs.size():
			if same_input(theirs[i], ev):
				hit = i
				break
		if hit == -1:
			continue
		if theirs.size() > 1:
			theirs.remove_at(hit)
			result["removed"].append(other)
		elif old != null:
			theirs[hit] = old.duplicate()
			result["swapped"].append(other)
		else:
			theirs.remove_at(hit)
			result["unbound"].append(other)
		_replace_device_events(other, device, theirs)

	# New primary first; drop a secondary that duplicates it (rebinding Move
	# Left to ← when ← was already its second key).
	var new_mine: Array[InputEvent] = [ev]
	for i in range(1, mine.size()):
		if not same_input(mine[i], ev):
			new_mine.append(mine[i])
	_replace_device_events(action, device, new_mine)

	result["ok"] = true
	save_bindings()
	_refresh_bound_texts()
	bindings_changed.emit()
	return result


func reset_to_defaults() -> void:
	for action in _defaults:
		_set_events(action, _defaults[action])
	save_bindings()
	_refresh_bound_texts()
	bindings_changed.emit()


func modes_overlap(a: StringName, b: StringName) -> bool:
	var ma: Array = ACTIONS.get(a, {}).get("modes", [])
	var mb: Array = ACTIONS.get(b, {}).get("modes", [])
	return ma.any(func(m): return m in mb)


static func same_input(a: InputEvent, b: InputEvent) -> bool:
	if a is InputEventKey and b is InputEventKey:
		var ca: Key = a.physical_keycode if a.physical_keycode != KEY_NONE else a.keycode
		var cb: Key = b.physical_keycode if b.physical_keycode != KEY_NONE else b.keycode
		return ca == cb
	if a is InputEventJoypadButton and b is InputEventJoypadButton:
		return a.button_index == b.button_index
	if a is InputEventJoypadMotion and b is InputEventJoypadMotion:
		return a.axis == b.axis and signf(a.axis_value) == signf(b.axis_value)
	return false


## Swap in `device_events` for the action's events of that device, at the
## position the device's events had, so the other device's order is untouched.
func _replace_device_events(action: StringName, device: StringName, device_events: Array) -> void:
	var out: Array[InputEvent] = []
	var inserted := false
	for e in InputMap.action_get_events(action):
		if _event_device(e) != device:
			out.append(e)
		elif not inserted:
			out.append_array(device_events)
			inserted = true
	if not inserted:
		out.append_array(device_events)
	_set_events(action, out)


func _event_device(ev: InputEvent) -> StringName:
	if ev is InputEventKey or ev is InputEventMouseButton:
		return KEYBOARD
	if ev is InputEventJoypadButton or ev is InputEventJoypadMotion:
		return GAMEPAD
	return &""


func _set_events(action: StringName, events: Array) -> void:
	InputMap.action_erase_events(action)
	for ev in events:
		InputMap.action_add_event(action, ev.duplicate())


func _copy_events(events: Array) -> Array[InputEvent]:
	var out: Array[InputEvent] = []
	for ev in events:
		out.append(ev.duplicate())
	return out


# ── Persistence ───────────────────────────────────────────────────────────
# user://input.cfg stores only actions that differ from the defaults, so a
# later build's new default bindings still reach players who never rebound.

func save_bindings() -> bool:
	var cfg := ConfigFile.new()
	cfg.set_value("meta", "version", CONFIG_VERSION)
	for action in _defaults:
		var current := InputMap.action_get_events(action)
		if _same_event_list(current, _defaults[action]):
			continue
		var serialized: Array = []
		for ev in current:
			var d := _serialize(ev)
			if not d.is_empty():
				serialized.append(d)
		cfg.set_value("bindings", String(action), serialized)
	var err := cfg.save(CONFIG_PATH)
	if err != OK:
		push_error("[InputService] Could not save %s (error %d)" % [CONFIG_PATH, err])
		return false
	return true


func load_bindings() -> void:
	_load_error = ""
	for action in _defaults:
		_set_events(action, _defaults[action])
	if FileAccess.file_exists(CONFIG_PATH):
		var cfg := ConfigFile.new()
		var err := cfg.load(CONFIG_PATH)
		if err != OK:
			# Keep defaults; leave the file alone so it can be inspected.
			_load_error = "unreadable (error %d)" % err
			push_warning("[InputService] %s is unreadable (error %d); using default controls" % [CONFIG_PATH, err])
			return
		for key in (cfg.get_section_keys("bindings") if cfg.has_section("bindings") else PackedStringArray()):
			var action := StringName(key)
			if not _defaults.has(action):
				continue
			var raw: Variant = cfg.get_value("bindings", key, [])
			if not raw is Array:
				continue
			var events: Array[InputEvent] = []
			for d in raw:
				var ev := _deserialize(d)
				if ev:
					events.append(ev)
			# An entry that decodes to nothing would silently unbind the action.
			if not events.is_empty():
				_set_events(action, events)
	elif FileAccess.file_exists(LEGACY_CONFIG_PATH):
		_migrate_legacy()
	_refresh_bound_texts()
	bindings_changed.emit()


## Old main-menu rebinds: [keys] action = physical keycode (keyboard only).
func _migrate_legacy() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(LEGACY_CONFIG_PATH) != OK or not cfg.has_section("keys"):
		return
	for key in cfg.get_section_keys("keys"):
		var action := StringName(key)
		var code: Variant = cfg.get_value("keys", key)
		if not _defaults.has(action) or typeof(code) != TYPE_INT or code <= 0:
			continue
		var ev := InputEventKey.new()
		ev.physical_keycode = code
		ev.device = -1
		var mine := events_for(action, KEYBOARD)
		if not mine.is_empty() and same_input(mine[0], ev):
			continue
		# Old rebinds replaced the primary key; keep any secondary (arrows).
		var new_mine: Array[InputEvent] = [ev]
		for i in range(1, mine.size()):
			if not same_input(mine[i], ev):
				new_mine.append(mine[i])
		_replace_device_events(action, KEYBOARD, new_mine)
	save_bindings()
	print("[InputService] Migrated key bindings from %s" % LEGACY_CONFIG_PATH)


func last_load_error() -> String:
	return _load_error


## Same bindings: per device, the same inputs in the same order (the first is
## the one prompts show). How keyboard and gamepad events interleave doesn't matter.
func _same_event_list(a: Array, b: Array) -> bool:
	for device in [KEYBOARD, GAMEPAD]:
		var da := a.filter(func(e): return _event_device(e) == device)
		var db := b.filter(func(e): return _event_device(e) == device)
		if da.size() != db.size():
			return false
		for i in da.size():
			if not same_input(da[i], db[i]):
				return false
	return true


static func _serialize(ev: InputEvent) -> Dictionary:
	if ev is InputEventKey:
		return {"type": "key", "code": int(ev.physical_keycode if ev.physical_keycode != KEY_NONE else ev.keycode)}
	if ev is InputEventJoypadButton:
		return {"type": "button", "index": int(ev.button_index)}
	if ev is InputEventJoypadMotion:
		return {"type": "axis", "axis": int(ev.axis), "dir": int(signf(ev.axis_value))}
	return {}


static func _deserialize(d: Variant) -> InputEvent:
	if not d is Dictionary:
		return null
	match d.get("type", ""):
		"key":
			var code := int(d.get("code", 0))
			if code <= 0:
				return null
			var k := InputEventKey.new()
			k.physical_keycode = code
			k.device = -1
			return k
		"button":
			var idx := int(d.get("index", -1))
			if idx < 0 or idx >= JOY_BUTTON_MAX:
				return null
			var b := InputEventJoypadButton.new()
			b.button_index = idx
			b.device = -1
			return b
		"axis":
			var axis := int(d.get("axis", -1))
			var dir := int(d.get("dir", 0))
			if axis < 0 or axis >= JOY_AXIS_MAX or dir == 0:
				return null
			var m := InputEventJoypadMotion.new()
			m.axis = axis
			m.axis_value = float(dir)
			m.device = -1
			return m
	return null
