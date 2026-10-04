extends CanvasLayer
## Controls screen — rebind every action for keyboard and gamepad.
## Opened from the main menu's and the pause menu's Options:
##   ControlsMenu.open(self, button_to_refocus)
## It's a ContextStack context stacked on top of whatever opened it, so Esc
## here closes only this screen.

signal closed

const SELF_PATH := "res://scripts/ui/controls_menu.gd"
const KEYBOARD := &"keyboard"
const GAMEPAD := &"gamepad"
const CONTEXT_ID := &"controls"
const COL_ACTION := 230.0
const COL_BIND := 190.0

var _return_focus: Control = null
var _buttons: Dictionary = {}          # "action|device" -> Button
var _listen_action: StringName = &""
var _listen_device: StringName = &""
var _status: Label = null
var _first_button: Button = null


## Open the screen above `parent`. Returns null if another menu refused it.
static func open(parent: Node, return_focus: Control = null) -> CanvasLayer:
	if not ContextStack.push(CONTEXT_ID, null, true, true, false):
		return null
	var menu: CanvasLayer = load(SELF_PATH).new()
	menu._return_focus = return_focus
	parent.add_child(menu)
	return menu


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 120
	_build()
	InputService.bindings_changed.connect(_refresh)
	InputService.device_changed.connect(_on_device_changed)
	_refresh()
	if _first_button:
		_first_button.grab_focus()


func is_listening() -> bool:
	return _listen_action != &""


func close() -> void:
	if is_queued_for_deletion():
		return
	_listen_action = &""
	ContextStack.pop(CONTEXT_ID)
	if _return_focus and is_instance_valid(_return_focus) and _return_focus.is_visible_in_tree():
		_return_focus.grab_focus()
	closed.emit()
	queue_free()


func _exit_tree() -> void:
	# Freed with its parent (scene change) without close(): don't leave the game paused.
	ContextStack.pop(CONTEXT_ID)


# ── Input ─────────────────────────────────────────────────────────────────

func _input(event: InputEvent) -> void:
	if is_listening():
		_capture(event)
		return
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		close()


func _capture(event: InputEvent) -> void:
	# Esc or Start cancels, whichever column is waiting.
	var cancel: bool = (event is InputEventKey and event.pressed
			and (event.physical_keycode == KEY_ESCAPE or event.keycode == KEY_ESCAPE)) \
		or (event is InputEventJoypadButton and event.pressed and event.button_index == JOY_BUTTON_START)
	if not cancel:
		var wanted := false
		if _listen_device == KEYBOARD:
			wanted = event is InputEventKey and event.pressed and not event.echo
		else:
			wanted = (event is InputEventJoypadButton and event.pressed) \
				or (event is InputEventJoypadMotion and absf(event.axis_value) >= InputService.AXIS_PRESS
					and event.axis not in InputService.RESERVED_PAD_AXES)
		if not wanted:
			_swallow(event)
			return
	get_viewport().set_input_as_handled()
	var action := _listen_action
	var device := _listen_device
	_listen_action = &""
	if cancel:
		_set_status("Cancelled.")
		_refresh()
		_focus_binding(action, device)
		return
	var result: Dictionary = InputService.rebind(action, device, event)
	if not result["ok"]:
		_set_status("Can't use that: %s." % result["reason"])
	else:
		var notes: Array[String] = []
		for other in result["swapped"]:
			notes.append("%s moved to %s" % [_label(other), InputService.prompt(other, device)])
		for other in result["removed"]:
			notes.append("%s keeps %s" % [_label(other), InputService.prompt(other, device)])
		for other in result["unbound"]:
			notes.append("%s is now unbound" % _label(other))
		_set_status("%s → %s. %s" % [_label(action), InputService.prompt(action, device), "  ".join(notes)])
	_refresh()
	_focus_binding(action, device)


## Keep stray input (mouse, key releases, the other device) from reaching
## the game or the menu underneath while waiting for a press.
func _swallow(event: InputEvent) -> void:
	if not event is InputEventMouseMotion:
		get_viewport().set_input_as_handled()


func _start_listen(action: StringName, device: StringName) -> void:
	_listen_action = action
	_listen_device = device
	var btn: Button = _buttons.get(_key(action, device))
	if btn:
		btn.text = "Press a key…" if device == KEYBOARD else "Press a button…"
	_set_status("Press the new %s for %s. %s cancels." % [
		"key" if device == KEYBOARD else "button", _label(action),
		"Esc" if device == KEYBOARD else "Start"])


# ── UI ────────────────────────────────────────────────────────────────────

func _build() -> void:
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.6)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(dim)

	var panel := PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.offset_left = -360
	panel.offset_right = 360
	panel.offset_top = -300
	panel.offset_bottom = 300
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.06, 0.05, 0.1, 0.98)
	style.border_color = Color(0.4, 0.3, 0.7, 0.9)
	style.set_border_width_all(2)
	style.set_corner_radius_all(8)
	style.set_content_margin_all(16)
	panel.add_theme_stylebox_override("panel", style)
	add_child(panel)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	panel.add_child(vbox)

	var title := Label.new()
	title.text = "━━  CONTROLS  ━━"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 20)
	title.add_theme_color_override("font_color", Color(0.8, 0.7, 1.0))
	vbox.add_child(title)

	var header := HBoxContainer.new()
	vbox.add_child(header)
	for col in [["Action", COL_ACTION], ["Keyboard", COL_BIND], ["Gamepad", COL_BIND]]:
		var h := Label.new()
		h.text = col[0]
		h.custom_minimum_size = Vector2(col[1], 0)
		h.add_theme_font_size_override("font_size", 13)
		h.add_theme_color_override("font_color", Color(1.0, 0.85, 0.5))
		header.add_child(h)

	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(0, 400)
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	vbox.add_child(scroll)

	var rows := VBoxContainer.new()
	rows.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(rows)

	for action in InputService.ACTIONS:
		var row := HBoxContainer.new()
		row.custom_minimum_size = Vector2(0, 30)
		rows.add_child(row)
		var name_label := Label.new()
		name_label.text = _label(action)
		name_label.custom_minimum_size = Vector2(COL_ACTION, 0)
		name_label.add_theme_font_size_override("font_size", 13)
		name_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.9))
		row.add_child(name_label)
		for device in [KEYBOARD, GAMEPAD]:
			var btn := Button.new()
			btn.name = "Bind_%s_%s" % [action, device]
			btn.custom_minimum_size = Vector2(COL_BIND - 10, 28)
			btn.add_theme_font_size_override("font_size", 13)
			btn.disabled = not InputService.is_rebindable(action, device)
			btn.pressed.connect(_start_listen.bind(action, device))
			row.add_child(btn)
			_buttons[_key(action, device)] = btn
			if _first_button == null:
				_first_button = btn

	_status = Label.new()
	_status.autowrap_mode = TextServer.AUTOWRAP_WORD
	_status.custom_minimum_size = Vector2(0, 36)
	_status.add_theme_font_size_override("font_size", 12)
	_status.add_theme_color_override("font_color", Color(0.6, 0.9, 1.0))
	_status.text = "Select a binding, then press the new key or button. Movement on the left stick is fixed."
	vbox.add_child(_status)

	var footer := HBoxContainer.new()
	footer.alignment = BoxContainer.ALIGNMENT_CENTER
	footer.add_theme_constant_override("separation", 20)
	vbox.add_child(footer)

	var reset := Button.new()
	reset.name = "ResetDefaults"
	reset.text = "  Reset to Defaults  "
	reset.pressed.connect(func():
		InputService.reset_to_defaults()
		_set_status("Default controls restored."))
	footer.add_child(reset)

	var back := Button.new()
	back.name = "Back"
	back.text = "  Back  "
	back.pressed.connect(close)
	footer.add_child(back)


func _on_device_changed(_device: StringName) -> void:
	_refresh()


func _refresh() -> void:
	if not is_inside_tree():
		return
	for action in InputService.ACTIONS:
		for device in [KEYBOARD, GAMEPAD]:
			var btn: Button = _buttons.get(_key(action, device))
			if btn == null or (is_listening() and action == _listen_action and device == _listen_device):
				continue
			var events := InputService.events_for(action, device)
			var labels: Array[String] = []
			for ev in events:
				labels.append(InputService.event_label(ev))
			if device == GAMEPAD and InputService.ACTIONS[action].get("pad_fixed", false):
				labels.clear()
				labels.append("Left Stick / D-Pad")
			btn.text = " / ".join(labels) if not labels.is_empty() else "— unbound —"


func _focus_binding(action: StringName, device: StringName) -> void:
	var btn: Button = _buttons.get(_key(action, device))
	if btn:
		btn.grab_focus()


func _set_status(text: String) -> void:
	if _status:
		_status.text = text


func _label(action: StringName) -> String:
	return InputService.ACTIONS.get(action, {}).get("label", String(action))


static func _key(action: StringName, device: StringName) -> String:
	return "%s|%s" % [action, device]
