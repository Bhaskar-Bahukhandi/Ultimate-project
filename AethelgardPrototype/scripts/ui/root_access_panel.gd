extends PanelContainer
class_name RootAccessPanel

## Reusable Root Access panel — dynamically reads hackable properties from any EnemyBase.
## Features: glitch FX, scanline overlay, matrix rain, terminal aesthetics.
## Usage:
##   var rap = RootAccessPanel.new()
##   ui_layer.add_child(rap)
##   rap.open(enemy_node)       # show & pause
##   # Player modifies sliders/checkboxes
##   # On "Apply Changes" or close → rap handles glitch cost + resume

signal hack_applied(enemy: EnemyBase, changes: Dictionary)
signal panel_closed

var _target: EnemyBase = null
var _property_controls: Dictionary = {}  # prop_name → Control
var _vbox: VBoxContainer
var _title_label: Label
var _desc_label: Label
var _property_list: VBoxContainer
var _apply_btn: Button
var _close_btn: Button
var _corruption_cost: float = 1.0  # Glitch % per hack

# ── Glitch FX ─────────────────────────────────────────────────────────
var _scanline_overlay: ColorRect = null
var _matrix_rain_label: Label = null
var _glitch_timer: float = 0.0
var _title_flicker_timer: float = 0.0
var _matrix_chars: String = "01アイウエオカキクケコ10サシスセソ><{}[];:"
var _jitter_offset: float = 0.0

func _ready() -> void:
	name = "RootAccessPanel"
	set_anchors_preset(Control.PRESET_CENTER)
	offset_left = -220
	offset_right = 220
	offset_top = -180
	offset_bottom = 180
	visible = false
	# Allow interaction while tree is paused
	process_mode = Node.PROCESS_MODE_ALWAYS

	_build_ui()

func _build_ui() -> void:
	# Panel style — dark terminal green with glow border
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.01, 0.04, 0.01, 0.96)
	style.border_color = Color(0.0, 1.0, 0.0, 0.9)
	style.border_width_top = 2
	style.border_width_bottom = 2
	style.border_width_left = 2
	style.border_width_right = 2
	style.content_margin_top = 12
	style.content_margin_bottom = 12
	style.content_margin_left = 14
	style.content_margin_right = 14
	style.corner_radius_top_left = 2
	style.corner_radius_top_right = 2
	style.corner_radius_bottom_left = 2
	style.corner_radius_bottom_right = 2
	style.shadow_color = Color(0.0, 0.8, 0.0, 0.3)
	style.shadow_size = 8
	add_theme_stylebox_override("panel", style)

	_vbox = VBoxContainer.new()
	_vbox.add_theme_constant_override("separation", 6)
	add_child(_vbox)

	# Title with glitch-style brackets
	_title_label = Label.new()
	_title_label.text = "[ ROOT ACCESS ]"
	_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title_label.add_theme_font_size_override("font_size", 16)
	_title_label.add_theme_color_override("font_color", Color(0.0, 1.0, 0.0))
	_vbox.add_child(_title_label)

	# Matrix rain decoration (scrolling chars below title)
	_matrix_rain_label = Label.new()
	_matrix_rain_label.text = ""
	_matrix_rain_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_matrix_rain_label.add_theme_font_size_override("font_size", 8)
	_matrix_rain_label.add_theme_color_override("font_color", Color(0.0, 0.6, 0.0, 0.4))
	_matrix_rain_label.clip_text = true
	_vbox.add_child(_matrix_rain_label)

	var sep = HSeparator.new()
	sep.add_theme_stylebox_override("separator", StyleBoxFlat.new())
	var sep_style = sep.get_theme_stylebox("separator") as StyleBoxFlat
	if sep_style:
		sep_style.bg_color = Color(0.0, 0.8, 0.0, 0.5)
		sep_style.content_margin_top = 1
		sep_style.content_margin_bottom = 1
	_vbox.add_child(sep)

	# Description
	_desc_label = Label.new()
	_desc_label.text = "// Hackable Properties:"
	_desc_label.add_theme_font_size_override("font_size", 12)
	_desc_label.add_theme_color_override("font_color", Color(0.3, 0.9, 0.3))
	_vbox.add_child(_desc_label)

	# ScrollContainer for property list
	var scroll = ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(0, 180)
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_vbox.add_child(scroll)

	_property_list = VBoxContainer.new()
	_property_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_property_list.add_theme_constant_override("separation", 4)
	scroll.add_child(_property_list)

	# Button row
	var btn_row = HBoxContainer.new()
	btn_row.add_theme_constant_override("separation", 8)
	_vbox.add_child(btn_row)

	_apply_btn = Button.new()
	_apply_btn.text = "Apply Changes [+%.0f%% Corruption]" % _corruption_cost
	_apply_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_apply_btn.custom_minimum_size = Vector2(0, 32)
	_apply_btn.pressed.connect(_on_apply)
	btn_row.add_child(_apply_btn)

	_close_btn = Button.new()
	_close_btn.text = "Cancel"
	_close_btn.custom_minimum_size = Vector2(80, 32)
	_close_btn.pressed.connect(close)
	btn_row.add_child(_close_btn)

	# Glitch meter warning with pulsing color
	var warning = Label.new()
	warning.text = "⚠ Each hack increases system corruption ⚠"
	warning.add_theme_font_size_override("font_size", 10)
	warning.add_theme_color_override("font_color", Color(1.0, 0.4, 0.1, 0.8))
	warning.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_vbox.add_child(warning)

	# Scanline overlay (subtle horizontal lines)
	_scanline_overlay = ColorRect.new()
	_scanline_overlay.name = "ScanlineOverlay"
	_scanline_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	_scanline_overlay.color = Color(0, 0, 0, 0)  # Transparent — we'll draw scanlines via modulate
	_scanline_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_scanline_overlay.z_index = 5
	add_child(_scanline_overlay)

func _process(delta) -> void:
	if not visible:
		return

	# Matrix rain animation
	_glitch_timer += delta
	if _matrix_rain_label and fmod(_glitch_timer, 0.08) < delta:
		var rain_text = ""
		for i in range(48):
			rain_text += _matrix_chars[randi() % _matrix_chars.length()]
		_matrix_rain_label.text = rain_text

	# Title flicker effect — occasional brief corruption
	_title_flicker_timer += delta
	if _title_flicker_timer > randf_range(1.5, 4.0):
		_title_flicker_timer = 0.0
		_do_title_glitch()

	# Subtle panel jitter — undo previous offset, apply new one
	position.x -= _jitter_offset
	_jitter_offset = 0.0
	if fmod(_glitch_timer, 3.0) < 0.05:
		_jitter_offset = randf_range(-1, 1)
		position.x += _jitter_offset

	# Scanline scroll effect via modulate alpha pulse
	if _scanline_overlay:
		_scanline_overlay.modulate.a = 0.03 + sin(_glitch_timer * 8.0) * 0.02

func _do_title_glitch() -> void:
	## Brief title text corruption for effect.
	if not _title_label:
		return
	var original = _title_label.text
	# Corrupt a few characters
	var corrupted = ""
	for i in range(original.length()):
		if randf() < 0.3:
			corrupted += _matrix_chars[randi() % _matrix_chars.length()]
		else:
			corrupted += original[i]
	_title_label.text = corrupted
	_title_label.add_theme_color_override("font_color", Color(0.5, 1.0, 0.5))
	# Restore after brief delay
	var tw = create_tween()
	tw.tween_interval(0.08)
	tw.tween_callback(func():
		if is_instance_valid(_title_label):
			_title_label.text = original
			_title_label.add_theme_color_override("font_color", Color(0.0, 1.0, 0.0))
	)

func _unhandled_input(event) -> void:
	if visible and event.is_action_pressed("root_access"):
		close()
		get_viewport().set_input_as_handled()

# ── Public API ──────────────────────────────────────────────────────────

func open(enemy: EnemyBase, corruption_cost: float = 1.0) -> void:
	## Open the panel for a specific enemy, pausing the game.
	if not enemy or not is_instance_valid(enemy):
		push_warning("[ROOT ACCESS] No valid enemy target")
		return
	if not enemy.has_method("get_hackable_properties"):
		push_warning("[ROOT ACCESS] Enemy is not hackable")
		return

	_target = enemy
	_corruption_cost = corruption_cost
	_apply_btn.text = "Apply Changes [+%.0f%% Corruption]" % _corruption_cost

	# Set title to enemy name
	var display_name = enemy.get("enemy_display_name")
	if display_name == null:
		display_name = enemy.name.replace("_", " ").capitalize()
	_title_label.text = "[ ROOT ACCESS — %s ]" % display_name.to_upper()

	# Build property controls dynamically
	_build_property_controls(enemy.get_hackable_properties())

	# Track hack usage
	if has_node("/root/GameManager"):
		GameManager.stats["hacks_used"] = GameManager.stats.get("hacks_used", 0) + 1

	# Glitch flash on open
	if has_node("/root/GlitchOverlay"):
		GlitchOverlay.flash_glitch(0.3)
	if has_node("/root/GameJuice"):
		GameJuice.on_root_access_activate(_target)

	# Animate open: scale from thin line to full
	scale = Vector2(1.0, 0.05)
	modulate.a = 0.0
	visible = true
	var tw = create_tween()
	tw.set_parallel(true)
	tw.tween_property(self, "scale", Vector2(1.0, 1.0), 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(self, "modulate:a", 1.0, 0.15)

	get_tree().paused = true
	if has_node("/root/SFXManager"):
		SFXManager.play("root_access_open")

func close() -> void:
	## Close the panel with glitch animation and resume the game.
	if has_node("/root/SFXManager"):
		SFXManager.play("root_access_close")
	# Animate close
	var tw = create_tween()
	tw.set_parallel(true)
	tw.tween_property(self, "scale:y", 0.05, 0.15).set_trans(Tween.TRANS_SINE)
	tw.tween_property(self, "modulate:a", 0.0, 0.15)
	tw.chain()
	tw.tween_callback(func():
		visible = false
		scale = Vector2(1.0, 1.0)
		modulate.a = 1.0
		get_tree().paused = false
		_target = null
		panel_closed.emit()
	)

func toggle(enemy: EnemyBase, corruption_cost: float = 1.0) -> void:
	## Toggle open/close. Convenience for input handlers.
	if visible:
		close()
	else:
		open(enemy, corruption_cost)

func get_nearest_enemy(from_pos: Vector2, max_range: float = 300.0) -> EnemyBase:
	## Utility: find the closest hackable enemy to a position.
	var best: EnemyBase = null
	var best_dist: float = max_range
	for node in get_tree().get_nodes_in_group("enemies"):
		if node is EnemyBase and is_instance_valid(node) and node.has_method("get_hackable_properties"):
			var dist = from_pos.distance_to(node.global_position)
			if dist < best_dist:
				best_dist = dist
				best = node
	return best

# ── Internal ────────────────────────────────────────────────────────────

func _build_property_controls(props: Dictionary) -> void:
	## Create sliders/checkboxes/spinboxes for each hackable property.
	# Clear previous
	for child in _property_list.get_children():
		child.queue_free()
	_property_controls.clear()

	for prop_name in props:
		var info: Dictionary = props[prop_name]
		var value = info["value"]
		var type: String = info.get("type", "float")
		var desc: String = info.get("description", prop_name)

		var row = HBoxContainer.new()
		row.add_theme_constant_override("separation", 6)
		_property_list.add_child(row)

		# Label
		var lbl = Label.new()
		lbl.text = prop_name + ":"
		lbl.custom_minimum_size = Vector2(120, 0)
		lbl.add_theme_font_size_override("font_size", 13)
		lbl.add_theme_color_override("font_color", Color(0.0, 1.0, 0.0))
		lbl.tooltip_text = desc
		row.add_child(lbl)

		match type:
			"bool":
				var cb = CheckBox.new()
				cb.button_pressed = bool(value)
				cb.text = "true" if value else "false"
				cb.add_theme_font_size_override("font_size", 13)
				cb.add_theme_color_override("font_color", Color(0.0, 1.0, 0.0))
				cb.toggled.connect(func(pressed): cb.text = "true" if pressed else "false")
				row.add_child(cb)
				_property_controls[prop_name] = cb

			"float", "int":
				var range_arr = info.get("range", [0.0, 100.0])
				var spin = SpinBox.new()
				spin.min_value = range_arr[0]
				spin.max_value = range_arr[1]
				spin.step = 0.1 if type == "float" else 1.0
				spin.value = value
				spin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
				spin.custom_minimum_size = Vector2(100, 0)
				spin.add_theme_font_size_override("font_size", 13)
				row.add_child(spin)
				_property_controls[prop_name] = spin

			_:
				# Fallback: read-only label
				var val_lbl = Label.new()
				val_lbl.text = str(value)
				val_lbl.add_theme_font_size_override("font_size", 13)
				val_lbl.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
				row.add_child(val_lbl)

func _on_apply() -> void:
	## Apply all changed values to the target enemy.
	if not _target or not is_instance_valid(_target):
		push_warning("[ROOT ACCESS] Target enemy is no longer valid")
		close()
		return

	var changes: Dictionary = {}

	for prop_name in _property_controls:
		var ctrl = _property_controls[prop_name]
		var new_value
		if ctrl is CheckBox:
			new_value = ctrl.button_pressed
		elif ctrl is SpinBox:
			new_value = ctrl.value
		else:
			continue

		# Only apply if changed
		var props: Dictionary = _target.get_hackable_properties()
		if props.has(prop_name):
			var old_value = props[prop_name]["value"]
			if typeof(new_value) == typeof(old_value) and new_value == old_value:
				continue
			elif str(new_value) == str(old_value):
				continue

		_target.apply_hack(prop_name, new_value)
		changes[prop_name] = new_value

	if changes.size() > 0:
		if has_node("/root/SFXManager"):
			SFXManager.play("hack_apply")
		# Increase corruption
		if has_node("/root/GameManager"):
			GameManager.add_glitch_corruption(_corruption_cost)
		print("[ROOT ACCESS] Hacked %d properties (+%.0f%% corruption)" % [changes.size(), _corruption_cost])
		hack_applied.emit(_target, changes)

		# Visual feedback — glitch flash
		if has_node("/root/GlitchOverlay"):
			GlitchOverlay.trigger_glitch(0.3)
	else:
		print("[ROOT ACCESS] No changes applied")

	close()
