extends CanvasLayer

## Status Window — Debugger-Style Character Info Panel
## Displays: IDENTITY, HP/INTEGRITY%, RAM/MANA as GB, CORRUPTION%, LOCATION
## Themed as a runtime variable inspector / debugger watch window
## Toggle with I / status_window input action

var panel: PanelContainer = null
var status_text: RichTextLabel = null
var scroll_container: ScrollContainer = null
var close_btn: Button = null
var hint_label: Label = null

var status_open: bool = false
var auto_refresh_timer: float = 0.0
var hint_shown: bool = false
var _last_status_text: String = ""

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 99  # Just below pause screen
	
	# Always build UI programmatically for autoloaded .gd scripts
	_build_status_ui()
	_build_hint_notification()
	
	# Start hidden
	if panel:
		panel.visible = false
	
	if OS.is_debug_build():
		print("[STATUS] Status window system initialized \u2014 Press I to toggle")

func _unhandled_input(event) -> void:
	# Use _unhandled_input so other UI elements get priority
	if event.is_action_pressed("status_window"):
		toggle_status()
		get_viewport().set_input_as_handled()

func _process(delta: float) -> void:
	if status_open:
		auto_refresh_timer += delta
		if auto_refresh_timer >= 1.0:  # Refresh every 1.0 seconds (less jitter)
			auto_refresh_timer = 0.0
			_refresh_status()
	
	# Show hint notification once after reaching Oakhaven
	if not hint_shown and hint_label:
		if GameManager.story_flags.get("ch1_oakhaven_entered", false):
			hint_shown = true
			_show_hint()

func toggle_status() -> void:
	if not status_open:
		# Lock OPENING until the player reaches the first town (Oakhaven). This
		# used to block closing too, so a window opened before a New Game
		# reset could never be closed.
		if not GameManager.story_flags.get("ch1_oakhaven_entered", false):
			return
		# Overlay, not a pause: the world keeps running, but only one menu at a time.
		if not ContextStack.push(&"status_window", self, false, false):
			return
	else:
		ContextStack.pop(&"status_window")
	
	status_open = !status_open
	
	if panel:
		panel.visible = status_open
	
	if status_open:
		_refresh_status()
		if OS.is_debug_build():
			print("[STATUS] Status window OPENED")
	else:
		if OS.is_debug_build():
			print("[STATUS] Status window CLOSED")

func _refresh_status() -> void:
	## Refresh all status information from GameManager — preserves scroll position
	if not status_text:
		return
	
	var stats = GameManager.player_stats
	var flags = GameManager.story_flags
	
	# Calculate derived values
	var hp = stats.get("hp", 100)
	var max_hp = stats.get("max_hp", 100)
	var integrity_pct = (float(hp) / max(float(max_hp), 1.0)) * 100.0
	
	var mp = stats.get("mp", 50)
	var max_mp = stats.get("max_mp", 50)
	var ram_gb = stats.get("ram_gb", 12)
	var ram_used_gb = float(ram_gb) * (float(mp) / max(float(max_mp), 1.0))
	
	var corruption = GameManager.glitch_meter
	var level = stats.get("level", 1)
	var xp = stats.get("xp", 0)
	var gold = stats.get("gold", 0)
	var pd_charges = GameManager.perfect_delete_charges
	
	# Determine location string
	var location = _get_current_location()
	
	# Determine corruption severity color hint
	var corruption_status = "NOMINAL"
	var corruption_color = "green"
	if corruption >= 75:
		corruption_status = "CRITICAL"
		corruption_color = "red"
	elif corruption >= 50:
		corruption_status = "WARNING"
		corruption_color = "orange"
	elif corruption >= 25:
		corruption_status = "ELEVATED"
		corruption_color = "yellow"
	
	# HP color
	var hp_color = "green"
	if max_hp > 0 and float(hp) / float(max_hp) < 0.3:
		hp_color = "red"
	elif max_hp > 0 and float(hp) / float(max_hp) < 0.6:
		hp_color = "yellow"
	
	# Build the debugger-style status display with BBCode for colors
	var text = ""
	text += "[color=cyan]╔══════════════════════════════════════╗[/color]\n"
	text += "[color=cyan]║[/color]  [color=lime]RUNTIME VARIABLE INSPECTOR[/color]          [color=cyan]║[/color]\n"
	text += "[color=cyan]║[/color]  Entity: [color=white]PLAYER_KAELEN_VANCE[/color]         [color=cyan]║[/color]\n"
	text += "[color=cyan]╠══════════════════════════════════════╣[/color]\n"
	text += "[color=cyan]║[/color]                                      [color=cyan]║[/color]\n"
	text += "[color=cyan]║[/color]  [color=lime]▶ IDENTITY[/color]                          [color=cyan]║[/color]\n"
	text += "[color=cyan]║[/color]    name     = [color=white]\"Kaelen Vance\"[/color]        [color=cyan]║[/color]\n"
	text += "[color=cyan]║[/color]    class    = [color=white]\"Game Developer\"[/color]      [color=cyan]║[/color]\n"
	text += "[color=cyan]║[/color]    level    = [color=white]%d[/color]                     [color=cyan]║[/color]\n" % level
	text += "[color=cyan]║[/color]    xp       = [color=white]%d[/color]                    [color=cyan]║[/color]\n" % xp
	text += "[color=cyan]║[/color]                                      [color=cyan]║[/color]\n"
	text += "[color=cyan]║[/color]  [color=lime]▶ HEALTH / INTEGRITY[/color]                [color=cyan]║[/color]\n"
	text += "[color=cyan]║[/color]    hp       = [color=%s]%d / %d[/color]               [color=cyan]║[/color]\n" % [hp_color, hp, max_hp]
	text += "[color=cyan]║[/color]    integrity= [color=%s]%.1f%%[/color]                 [color=cyan]║[/color]\n" % [hp_color, integrity_pct]
	text += "[color=cyan]║[/color]    status   = [color=%s]%s[/color]                     [color=cyan]║[/color]\n" % [hp_color, "ALIVE" if hp > 0 else "DEAD"]
	text += "[color=cyan]║[/color]                                      [color=cyan]║[/color]\n"
	text += "[color=cyan]║[/color]  [color=lime]▶ RAM / MANA[/color]                        [color=cyan]║[/color]\n"
	text += "[color=cyan]║[/color]    total_ram= [color=white]%d GB[/color]                  [color=cyan]║[/color]\n" % ram_gb
	text += "[color=cyan]║[/color]    ram_used = [color=white]%.1f / %d GB[/color]          [color=cyan]║[/color]\n" % [ram_used_gb, ram_gb]
	text += "[color=cyan]║[/color]    mp       = [color=white]%d / %d[/color]               [color=cyan]║[/color]\n" % [mp, max_mp]
	text += "[color=cyan]║[/color]                                      [color=cyan]║[/color]\n"
	text += "[color=cyan]║[/color]  [color=lime]▶ CORRUPTION[/color]                        [color=cyan]║[/color]\n"
	text += "[color=cyan]║[/color]    level    = [color=%s]%.1f%%[/color]                 [color=cyan]║[/color]\n" % [corruption_color, corruption]
	text += "[color=cyan]║[/color]    status   = [color=%s]%s[/color]                     [color=cyan]║[/color]\n" % [corruption_color, corruption_status]
	text += "[color=cyan]║[/color]    permadeath= [color=%s]%s[/color]                    [color=cyan]║[/color]\n" % ["red" if corruption >= 100 else "green", "TRUE" if corruption >= 100 else "FALSE"]
	text += "[color=cyan]║[/color]                                      [color=cyan]║[/color]\n"
	text += "[color=cyan]║[/color]  [color=lime]▶ COMBAT[/color]                            [color=cyan]║[/color]\n"
	text += "[color=cyan]║[/color]    attack   = [color=white]%d[/color]                     [color=cyan]║[/color]\n" % stats.get("attack", 10)
	text += "[color=cyan]║[/color]    defense  = [color=white]%d[/color]                     [color=cyan]║[/color]\n" % stats.get("defense", 5)
	text += "[color=cyan]║[/color]    pd_charges= [color=white]%d[/color]                    [color=cyan]║[/color]\n" % pd_charges
	text += "[color=cyan]║[/color]    gold     = [color=yellow]%d[/color]                     [color=cyan]║[/color]\n" % gold
	text += "[color=cyan]║[/color]                                      [color=cyan]║[/color]\n"
	text += "[color=cyan]║[/color]  [color=lime]▶ LOCATION[/color]                          [color=cyan]║[/color]\n"
	text += "[color=cyan]║[/color]    region   = [color=white]\"%s\"[/color]                 [color=cyan]║[/color]\n" % location
	text += "[color=cyan]║[/color]    chapter  = [color=white]%d[/color]                     [color=cyan]║[/color]\n" % (GameManager.current_chapter if GameManager.current_chapter else 1)
	text += "[color=cyan]║[/color]                                      [color=cyan]║[/color]\n"
	text += "[color=cyan]║[/color]  [color=lime]▶ ABILITIES[/color]                         [color=cyan]║[/color]\n"
	text += "[color=cyan]║[/color]    root_access  = %s                 [color=cyan]║[/color]\n" % ("[color=lime]UNLOCKED[/color]" if flags.get("root_access_unlocked", false) else "[color=gray]LOCKED[/color]")
	text += "[color=cyan]║[/color]    data_vision  = %s                 [color=cyan]║[/color]\n" % ("[color=lime]UNLOCKED[/color]" if flags.get("ch1_data_vision_unlocked", false) else "[color=gray]LOCKED[/color]")
	text += "[color=cyan]║[/color]    perfect_del  = %s                 [color=cyan]║[/color]\n" % ("[color=lime]UNLOCKED[/color]" if flags.get("root_access_unlocked", false) else "[color=gray]LOCKED[/color]")
	text += "[color=cyan]║[/color]                                      [color=cyan]║[/color]\n"
	text += "[color=cyan]║[/color]  [color=lime]▶ STORY FLAGS[/color]                       [color=cyan]║[/color]\n"
	
	# Show recent story flags (last 5)
	var flag_keys = flags.keys()
	var show_count = min(flag_keys.size(), 5)
	for i in range(flag_keys.size() - show_count, flag_keys.size()):
		if i >= 0:
			var flag_val = str(flags[flag_keys[i]])
			var flag_color = "lime" if flags[flag_keys[i]] == true else "gray"
			text += "[color=cyan]║[/color]    [color=%s]%s = %s[/color]  [color=cyan]║[/color]\n" % [flag_color, str(flag_keys[i]).left(20), flag_val]
	
	text += "[color=cyan]║[/color]                                      [color=cyan]║[/color]\n"
	text += "[color=cyan]╠══════════════════════════════════════╣[/color]\n"
	text += "[color=cyan]║[/color]  [color=gray][I] Close  |  Auto-refresh: 1.0s[/color]   [color=cyan]║[/color]\n"
	text += "[color=cyan]╚══════════════════════════════════════╝[/color]"
	
	# Only update text if it actually changed — prevents scroll jump and flicker
	if text != _last_status_text:
		# Preserve scroll position
		var saved_scroll_v = 0
		if scroll_container:
			saved_scroll_v = scroll_container.scroll_vertical
		
		status_text.text = text
		
		# Restore scroll position after the text update takes effect
		if scroll_container:
			# Defer so the ScrollContainer recalculates first
			scroll_container.set_deferred("scroll_vertical", saved_scroll_v)
		
		_last_status_text = text

func _get_current_location() -> String:
	var flags = GameManager.story_flags
	# Chapter 2 locations (check newest first)
	if flags.get("ch2_administrator_proxy_defeated", false):
		return "Ironhold — City Square"
	elif flags.get("ch2_clock_tower_complete", false):
		return "Ironhold — Clock Tower (cleared)"
	elif flags.get("ch2_clockwork_automaton_defeated", false):
		return "Ironhold — Clock Tower (top)"
	elif flags.get("ch2_underground_network_complete", false):
		return "Ironhold — Underground Network"
	elif flags.get("ch2_seraphina_met", false):
		return "Ironhold — Memorial Gardens"
	elif flags.get("ch2_ironhold_entered", false):
		return "Ironhold City"
	# Chapter 1 locations
	elif flags.get("ch1_shatter_witnessed", false):
		return "Ironhold Approach"
	elif flags.get("ch1_tutorial_knight_defeated", false):
		return "Oakhaven Bridge"
	elif flags.get("ch1_oakhaven_entered", false):
		return "Oakhaven Village"
	elif flags.get("ch1_data_vision_unlocked", false):
		return "Path to Oakhaven"
	elif flags.get("ch1_elara_glitch_witch_met", false):
		return "Forest Path"
	elif flags.get("ch1_glitch_crater_complete", false):
		return "Glitch Crater Exit"
	else:
		return "Glitch Crater"

func _build_status_ui() -> void:
	## Runtime construction of status UI — uses direct position/size for reliability
	panel = PanelContainer.new()
	panel.name = "StatusPanel"
	# Position dynamically based on viewport size — right-aligned with margin
	var vp_size = get_viewport().get_visible_rect().size if get_viewport() else Vector2(1280, 720)
	panel.position = Vector2(vp_size.x - 415, 20)
	panel.size = Vector2(400, min(640, vp_size.y - 40))
	panel.custom_minimum_size = Vector2(400, 640)
	panel.add_theme_stylebox_override("panel", _create_dark_panel())
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(panel)
	
	var margin = MarginContainer.new()
	margin.name = "MarginContainer"
	margin.add_theme_constant_override("margin_left", 12)
	margin.add_theme_constant_override("margin_right", 12)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_bottom", 10)
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	panel.add_child(margin)
	
	var vbox = VBoxContainer.new()
	vbox.name = "VBox"
	margin.add_child(vbox)
	
	# Title bar
	var title = Label.new()
	title.text = "[ RUNTIME VARIABLE INSPECTOR ]"
	title.add_theme_font_size_override("font_size", 13)
	title.add_theme_color_override("font_color", Color(0.0, 1.0, 0.5))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)
	
	# Separator
	var sep = HSeparator.new()
	sep.add_theme_color_override("separator", Color(0.0, 0.6, 0.3, 0.5))
	vbox.add_child(sep)
	
	# Scrollable status text
	scroll_container = ScrollContainer.new()
	scroll_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll_container.custom_minimum_size = Vector2(0, 520)
	scroll_container.mouse_filter = Control.MOUSE_FILTER_STOP  # Allow scroll interaction
	vbox.add_child(scroll_container)
	
	status_text = RichTextLabel.new()
	status_text.name = "StatusText"
	status_text.text = "Initializing..."
	status_text.bbcode_enabled = true
	status_text.fit_content = true
	status_text.scroll_active = false  # Let ScrollContainer handle scrolling
	status_text.add_theme_font_size_override("normal_font_size", 12)
	status_text.add_theme_color_override("default_color", Color(0.0, 1.0, 0.4))
	status_text.mouse_filter = Control.MOUSE_FILTER_IGNORE
	scroll_container.add_child(status_text)
	
	# Close button
	close_btn = Button.new()
	close_btn.name = "CloseButton"
	close_btn.text = "[ I ] CLOSE STATUS WINDOW"
	close_btn.add_theme_font_size_override("font_size", 12)
	close_btn.add_theme_color_override("font_color", Color(0.0, 1.0, 0.4))
	var btn_style = StyleBoxFlat.new()
	btn_style.bg_color = Color(0.08, 0.15, 0.08, 0.9)
	btn_style.border_color = Color(0.0, 0.8, 0.3, 0.7)
	btn_style.set_border_width_all(1)
	btn_style.set_corner_radius_all(3)
	btn_style.content_margin_top = 6
	btn_style.content_margin_bottom = 6
	close_btn.add_theme_stylebox_override("normal", btn_style)
	close_btn.add_theme_stylebox_override("hover", btn_style.duplicate())
	close_btn.pressed.connect(toggle_status)
	vbox.add_child(close_btn)

func _build_hint_notification() -> void:
	## Build a small 'Press I for Status' hint that fades in then out
	hint_label = Label.new()
	hint_label.text = "[  Press  I  for Status Window  ]"
	hint_label.add_theme_font_size_override("font_size", 14)
	hint_label.add_theme_color_override("font_color", Color(0.0, 1.0, 0.5))
	hint_label.position = Vector2(460, 680)  # Bottom center area
	hint_label.modulate.a = 0.0
	add_child(hint_label)

func _show_hint() -> void:
	## Fade in the hint, hold, then fade out
	await get_tree().create_timer(3.0).timeout  # Wait 3 seconds after scene loads
	if not is_inside_tree(): return
	if not hint_label or not is_instance_valid(hint_label):
		return
	var t = create_tween()
	t.tween_property(hint_label, "modulate:a", 1.0, 0.8)
	t.tween_interval(4.0)
	t.tween_property(hint_label, "modulate:a", 0.0, 1.5)
	t.tween_callback(func():
		if hint_label and is_instance_valid(hint_label):
			hint_label.queue_free()
			hint_label = null
	)

func _create_dark_panel() -> StyleBoxFlat:
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.02, 0.06, 0.02, 0.95)
	style.border_color = Color(0.0, 0.8, 0.3, 0.8)
	style.set_border_width_all(2)
	style.set_corner_radius_all(3)
	style.shadow_color = Color(0, 0.5, 0.2, 0.3)
	style.shadow_size = 4
	return style
