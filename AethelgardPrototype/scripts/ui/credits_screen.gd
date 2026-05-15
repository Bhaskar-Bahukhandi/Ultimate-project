extends CanvasLayer

## Credits Screen — Scrolling credits roll
## Plays after Chapter 3 completion or from main menu
## Themed as a terminal/code readout — because Kaelen is a developer

var _panel: PanelContainer = null
var _scroll_container: ScrollContainer = null
var _credits_vbox: VBoxContainer = null
var _scroll_tween: Tween = null
var _is_showing: bool = false
var _skip_label: Label = null

# Credits data — sections with headers and entries
const CREDITS_DATA: Array = [
	{"header": "AETHELGARD: THE GLITCH SOVEREIGN", "entries": [""]},
	{"header": "// CREATED BY", "entries": [
		"Bhaskar Bahukhandi — Everything",
		"Game Design, Programming, Writing, Systems Architecture",
	]},
	{"header": "// NARRATIVE & WORLD DESIGN", "entries": [
		"Story, Lore & Dialogue — Bhaskar Bahukhandi",
		"World of Aethelgard — A digital realm where code is reality",
		"Characters: Kaelen, Elara, Seraphina, The Administrator, The Glitch Sovereign",
	]},
	{"header": "// PROGRAMMING", "entries": [
		"Engine: Godot 4.6 (Forward+)",
		"Language: GDScript",
		"Combat System — Hollow Knight-inspired nail combat",
		"Procedural Music Engine — Multi-voice waveform synthesis",
		"Procedural SFX Engine — Real-time sound generation",
		"Scene Transition System — 10 custom transition styles",
		"Save System — Atomic writes with backup recovery",
		"Dialogue System — Typewriter text with branching choices",
		"Random Encounter System — JRPG-style overworld battles",
		"Arena Challenge System — Standard, Time Attack, Endurance",
		"Progression Breadcrumb System — Dynamic objective tracking",
		"Charm & Equipment System — 10+ equippable items",
		"Side Quest Framework — Multi-stage quest tracking",
		"Accessibility Suite — Colorblind, text scale, assist modes",
	]},
	{"header": "// ART & VISUALS", "entries": [
		"Placeholder sprites generated procedurally at runtime",
		"Shader Effects — CRT scanlines, glitch distortion, corruption overlay",
		"VFX Library — Screen shake, hitstop, damage numbers, style ranks",
		"Scene art and backgrounds — Work in progress",
	]},
	{"header": "// AUDIO", "entries": [
		"All music and sound effects are procedurally generated",
		"No external audio files — pure waveform synthesis",
		"Multi-track system: exploration, combat, boss, menu themes",
		"Dynamic music transitions based on game state",
	]},
	{"header": "// SPECIAL THANKS", "entries": [
		"The Godot Engine community",
		"Hollow Knight — For combat inspiration",
		"Undertale — For narrative ambition",
		"Every indie dev who ships solo",
		"You — For playing this game",
	]},
	{"header": "// TOOLS USED", "entries": [
		"Godot Engine 4.6",
		"Visual Studio Code",
		"GitHub Copilot",
	]},
	{"header": "", "entries": [
		"",
		"━━━━━━━━━━━━━━━━━━━━━━━━━━",
		"",
		"\"In a world made of code,",
		"the greatest bug is forgetting",
		"that you are the programmer.\"",
		"",
		"— Kaelen",
		"",
		"━━━━━━━━━━━━━━━━━━━━━━━━━━",
		"",
		"Thank you for playing.",
		"",
		"AETHELGARD: THE GLITCH SOVEREIGN",
		"Version 1.0",
		"",
		"© 2026 Bhaskar Bahukhandi",
		"All rights reserved.",
		"",
		"",
		"",
	]},
]

const SCROLL_SPEED: float = 40.0  # pixels per second
const FAST_SCROLL_SPEED: float = 160.0  # when holding skip

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 120  # Above everything
	visible = false

func show_credits(return_to_menu: bool = true) -> void:
	if _is_showing:
		return
	_is_showing = true
	visible = true
	get_tree().paused = true
	_build_credits_ui()
	_start_scroll(return_to_menu)

func _build_credits_ui() -> void:
	# Clean up old UI
	if _panel and is_instance_valid(_panel):
		_panel.queue_free()

	_panel = PanelContainer.new()
	_panel.name = "CreditsPanel"
	_panel.set_anchors_preset(Control.PRESET_FULL_RECT)

	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.02, 0.02, 0.04, 1.0)
	_panel.add_theme_stylebox_override("panel", style)
	add_child(_panel)

	var margin = MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 100)
	margin.add_theme_constant_override("margin_right", 100)
	margin.add_theme_constant_override("margin_top", 0)
	margin.add_theme_constant_override("margin_bottom", 0)
	_panel.add_child(margin)

	var outer_vbox = VBoxContainer.new()
	margin.add_child(outer_vbox)

	_scroll_container = ScrollContainer.new()
	_scroll_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_scroll_container.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	# Hide scrollbar for cinematic feel
	_scroll_container.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_NEVER
	outer_vbox.add_child(_scroll_container)

	_credits_vbox = VBoxContainer.new()
	_credits_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_credits_vbox.add_theme_constant_override("separation", 4)
	_scroll_container.add_child(_credits_vbox)

	# Top spacer — start credits off-screen at bottom
	var top_spacer = Control.new()
	top_spacer.custom_minimum_size = Vector2(0, 600)
	_credits_vbox.add_child(top_spacer)

	# Build credits text
	for section in CREDITS_DATA:
		var header_text: String = section.get("header", "")
		if header_text != "":
			var header_sep = Control.new()
			header_sep.custom_minimum_size = Vector2(0, 24)
			_credits_vbox.add_child(header_sep)

			var header_label = Label.new()
			header_label.text = header_text
			header_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			header_label.add_theme_font_size_override("font_size", 22 if section == CREDITS_DATA[0] else 16)
			header_label.add_theme_color_override("font_color", Color(0.4, 0.8, 1.0) if section == CREDITS_DATA[0] else Color(0.3, 0.7, 0.4))
			_credits_vbox.add_child(header_label)

			var underline = Label.new()
			underline.text = "─" .repeat(header_text.length())
			underline.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			underline.add_theme_font_size_override("font_size", 10)
			underline.add_theme_color_override("font_color", Color(0.2, 0.4, 0.3, 0.6))
			_credits_vbox.add_child(underline)

		var entries: Array = section.get("entries", [])
		for entry_text in entries:
			var entry_label = Label.new()
			entry_label.text = entry_text
			entry_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			entry_label.add_theme_font_size_override("font_size", 14)
			entry_label.add_theme_color_override("font_color", Color(0.75, 0.75, 0.82))
			entry_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			_credits_vbox.add_child(entry_label)

	# Bottom spacer — let credits scroll fully past view
	var bottom_spacer = Control.new()
	bottom_spacer.custom_minimum_size = Vector2(0, 700)
	_credits_vbox.add_child(bottom_spacer)

	# Skip hint at bottom of screen
	_skip_label = Label.new()
	_skip_label.text = "[ENTER/ESC] Skip    [SPACE] Fast Forward"
	_skip_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_skip_label.add_theme_font_size_override("font_size", 11)
	_skip_label.add_theme_color_override("font_color", Color(0.35, 0.35, 0.4))
	outer_vbox.add_child(_skip_label)

	# Fade in
	_panel.modulate.a = 0.0
	var fade = create_tween()
	fade.tween_property(_panel, "modulate:a", 1.0, 1.0)

var _return_to_menu: bool = true
var _scroll_position: float = 0.0
var _total_scroll_height: float = 0.0
var _scroll_active: bool = false

func _start_scroll(return_to_menu: bool) -> void:
	_return_to_menu = return_to_menu
	_scroll_position = 0.0
	_scroll_active = true
	# Wait a frame for layout to resolve
	await get_tree().process_frame
	await get_tree().process_frame
	_total_scroll_height = _credits_vbox.size.y - _scroll_container.size.y
	if _total_scroll_height <= 0:
		_total_scroll_height = 2000.0

	# Play credits music
	if has_node("/root/MusicManager"):
		MusicManager.play_track("main_menu")

func _process(delta: float) -> void:
	if not _scroll_active or not _is_showing:
		return

	var speed = FAST_SCROLL_SPEED if Input.is_action_pressed("jump") else SCROLL_SPEED
	_scroll_position += speed * delta

	if _scroll_container and is_instance_valid(_scroll_container):
		_scroll_container.scroll_vertical = int(_scroll_position)

	# Check if scroll completed
	if _scroll_position >= _total_scroll_height:
		_finish_credits()

func _input(event: InputEvent) -> void:
	if not _is_showing:
		return
	# Skip with Enter or Escape
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_ENTER or event.keycode == KEY_ESCAPE:
			_finish_credits()
			get_viewport().set_input_as_handled()

func _finish_credits() -> void:
	if not _is_showing:
		return
	_scroll_active = false
	_is_showing = false

	# Fade out
	if _panel and is_instance_valid(_panel):
		var fade = create_tween()
		fade.tween_property(_panel, "modulate:a", 0.0, 0.8)
		fade.tween_callback(func():
			if _panel and is_instance_valid(_panel):
				_panel.queue_free()
			visible = false
			get_tree().paused = false
			if _return_to_menu:
				if has_node("/root/SceneTransitions"):
					SceneTransitions.change_scene("res://scenes/main_menu.tscn")
				else:
					get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
		)
	else:
		visible = false
		get_tree().paused = false
