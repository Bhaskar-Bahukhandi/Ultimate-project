extends CanvasLayer
## Studio splash screen — glitch-themed boot sequence.
## Shows studio name with CRT / data-corruption effects, then loads main menu.

const SPLASH_DURATION := 3.0
const GLITCH_INTERVAL := 0.12
const BOOT_LINES := [
	"> INITIALIZING SYSTEM...",
	"> LOADING MEMORY FRAGMENT 0x7F3A...",
	"> AETHELGARD KERNEL v0.91 [CORRUPTED]",
	"> WARNING: REALITY ANCHOR UNSTABLE",
	"> BHASKAR BAHUKHANDI PRESENTS",
]

var _elapsed := 0.0
var _glitch_timer := 0.0
var _boot_index := 0
var _boot_timer := 0.0
var _done := false

@onready var _studio_label: Label = %StudioLabel
@onready var _boot_text: RichTextLabel = %BootText
@onready var _bg: ColorRect = %Background
@onready var _scanline: ColorRect = %Scanline
@onready var _fade: ColorRect = %FadeRect

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_studio_label.modulate.a = 0.0
	_fade.modulate.a = 0.0
	_boot_text.text = ""
	_scanline.modulate.a = 0.08

func _process(delta: float) -> void:
	if _done:
		return
	_elapsed += delta

	# --- Boot text phase (0 – 1.5s) ---
	if _boot_index < BOOT_LINES.size():
		_boot_timer += delta
		var interval := 0.28 if _boot_index < BOOT_LINES.size() - 1 else 0.4
		if _boot_timer >= interval:
			_boot_timer = 0.0
			_boot_text.text += BOOT_LINES[_boot_index] + "\n"
			_boot_index += 1
			if _boot_index == BOOT_LINES.size():
				_studio_label.modulate.a = 1.0

	# --- Glitch flicker on studio label ---
	_glitch_timer += delta
	if _glitch_timer >= GLITCH_INTERVAL and _studio_label.modulate.a > 0.0:
		_glitch_timer = 0.0
		_studio_label.position.x = randf_range(-3.0, 3.0)
		_studio_label.position.y = randf_range(-1.0, 1.0)
		# RGB split simulation via modulate color jitter
		var r := randf_range(0.85, 1.0)
		var g := randf_range(0.85, 1.0)
		var b := randf_range(0.85, 1.0)
		_studio_label.modulate = Color(r, g, b, _studio_label.modulate.a)

	# --- Scanline scroll ---
	_scanline.position.y = fmod(_elapsed * 120.0, 720.0)

	# --- Fade-out & transition ---
	if _elapsed >= SPLASH_DURATION - 0.5:
		_fade.modulate.a = minf((_elapsed - (SPLASH_DURATION - 0.5)) / 0.5, 1.0)
	if _elapsed >= SPLASH_DURATION:
		_transition_to_menu()

func _unhandled_input(event: InputEvent) -> void:
	if _done:
		return
	if event is InputEventKey or event is InputEventMouseButton or event is InputEventJoypadButton:
		if event.is_pressed():
			_transition_to_menu()

func _transition_to_menu() -> void:
	_done = true
	set_process(false)
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
