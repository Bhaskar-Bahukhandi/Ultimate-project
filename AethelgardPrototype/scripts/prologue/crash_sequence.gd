extends Control

@onready var color_rect = $ColorRect
@onready var status_label = $CenterContainer/VBoxContainer/StatusLabel
@onready var message_label = $CenterContainer/VBoxContainer/MessageLabel
@onready var progress_label = $CenterContainer/VBoxContainer/ProgressLabel

var sequence_phase = 0
var glitch_intensity = 0.0
var phase_timer = 0.0
var char_timer = 0.0
var current_text = ""
var target_text = ""
var char_index = 0

# Comprehensive boot sequence as per Chapter 0 specification — expanded
var boot_sequence = [
	# Phase 1: CRISIS — something went very wrong (5 lines, ~3s)
	{"text": "KERNEL_PANIC: CRITICAL_PROCESS_DIED", "delay": 0.6, "color": Color.RED},
	{"text": "STACK_DUMP: 0x00707 → FLIGHT_707.DAT", "delay": 0.4, "color": Color.RED},
	{"text": "STACK_DUMP: 0x00001 → CONSCIOUSNESS.EXE", "delay": 0.4, "color": Color.RED},
	{"text": "ATTEMPTING RESTORE FROM LAST CHECKPOINT...", "delay": 1.0, "color": Color.YELLOW},
	{"text": "ERROR: NO CHECKPOINT FOUND", "delay": 0.8, "color": Color.RED},
	{"text": "", "delay": 0.3, "color": Color.BLACK},
	
	# Phase 2: TRANSFER — consciousness being moved (4 lines, ~4s)
	{"text": "FALLBACK: LOADING BACKUP — MEMORY_FRAGMENT_001.DAT", "delay": 1.5, "color": Color.CYAN},
	{"text": "DECOMPRESSING CONSCIOUSNESS STREAM...", "delay": 1.0, "color": Color.CYAN},
	{"text": "BINDING TO NEW HOST ENVIRONMENT...", "delay": 1.0, "color": Color.CYAN},
	{"text": "", "delay": 0.5, "color": Color.BLACK},
	
	# Phase 3: SYSTEM CHECK — brief, punchy (4 lines, ~3s)
	{"text": "> SYSTEM REBOOT INITIATED...", "delay": 1.0, "color": Color.CYAN},
	{"text": "> CHECKING SUBSYSTEMS... [PARTIAL — 3 DEGRADED, 1 CORRUPTED]", "delay": 1.0, "color": Color.YELLOW},
	{"text": "", "delay": 0.3, "color": Color.BLACK},
	
	# Phase 4: INTRUDER ALERT — the dramatic core (8 lines, ~8s)
	{"text": "> WARNING: UNAUTHORIZED USER DETECTED.", "delay": 1.5, "color": Color.YELLOW},
	{"text": "> USER_ID:  VANCE_KAELEN", "delay": 0.6, "color": Color.YELLOW},
	{"text": "> ORIGIN:   EARTH_REALITY (non-native)", "delay": 0.6, "color": Color.YELLOW},
	{"text": "> CLEARANCE: NONE", "delay": 0.5, "color": Color.RED},
	{"text": "", "delay": 0.5, "color": Color.BLACK},
	{"text": "> ATTEMPTING DELETION OF FOREIGN ENTITY...", "delay": 1.5, "color": Color.RED},
	{"text": "> ERROR: DELETION FAILED — Permission denied", "delay": 1.0, "color": Color.RED},
	{"text": "> REASON: USER HAS ROOT ACCESS", "delay": 1.5, "color": Color.MAGENTA},
	{"text": "> ROOT ACCESS ORIGIN: [UNKNOWN — ANOMALOUS]", "delay": 1.2, "color": Color.MAGENTA},
	{"text": "", "delay": 0.5, "color": Color.BLACK},
	
	# Phase 5: CONTAINMENT — system decides what to do (6 lines, ~6s)
	{"text": "> ESCALATING TO SYSTEM ADMINISTRATORS...", "delay": 0.8, "color": Color.RED},
	{"text": "> RESPONSE: [PENDING]", "delay": 0.8, "color": Color.YELLOW},
	{"text": "", "delay": 0.3, "color": Color.BLACK},
	{"text": "> CONTAINMENT PROTOCOL: ASSIGNING TO LOW-RISK ZONE", "delay": 1.0, "color": Color.CYAN},
	{"text": "> DIFFICULTY: HARDCORE (non-adjustable)", "delay": 0.8, "color": Color.RED},
	{"text": "", "delay": 0.3, "color": Color.BLACK},
	
	# Phase 6: DEPLOY — short, final (2 lines, ~3s)
	{"text": "> Deploying user to crash site.", "delay": 1.2, "color": Color.GREEN},
	{"text": "> WAKE_UP.EXE EXECUTED.", "delay": 2.0, "color": Color.GREEN},
]

func _ready() -> void:
	# Play crash impact and glass shatter SFX
	if has_node("/root/SFXManager"):
		SFXManager.play("crash_impact")
		SFXManager.play("glass_shatter")

	# Initialize first message
	if boot_sequence.size() > 0:
		_update_progress()
		start_next_phase()
	
	# Set initial shader parameter
	if color_rect.material:
		color_rect.material.set_shader_parameter("glitch_strength", 0.0)
	
	# Build skip hint label
	_build_skip_hint()

var _skip_hint: Label = null
var _skip_hold_timer: float = 0.0
const SKIP_HOLD_DURATION: float = 1.0

func _build_skip_hint() -> void:
	_skip_hint = Label.new()
	_skip_hint.text = "Hold ESC to Skip to Chapter 1"
	_skip_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_skip_hint.add_theme_font_size_override("font_size", 14)
	_skip_hint.add_theme_color_override("font_color", Color(0.5, 0.5, 0.6, 0.6))
	_skip_hint.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	_skip_hint.offset_left = -200
	_skip_hint.offset_top = -30
	_skip_hint.offset_right = -10
	_skip_hint.offset_bottom = -8
	add_child(_skip_hint)

func _input(event) -> void:
	if event.is_action_pressed("ui_cancel"):
		_skip_hold_timer = 0.01  # Start tracking
		get_viewport().set_input_as_handled()

func _process(delta) -> void:
	# Handle hold-ESC-to-skip
	if _skip_hold_timer > 0.0 and Input.is_action_pressed("ui_cancel"):
		_skip_hold_timer += delta
		if _skip_hint:
			var pct = clamp(_skip_hold_timer / SKIP_HOLD_DURATION, 0.0, 1.0)
			_skip_hint.text = "Skipping... %d%%" % int(pct * 100)
			_skip_hint.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0, 0.8))
		if _skip_hold_timer >= SKIP_HOLD_DURATION:
			_skip_sequence()
			return
	else:
		_skip_hold_timer = 0.0
		if _skip_hint:
			_skip_hint.text = "Hold ESC to skip"
			_skip_hint.add_theme_color_override("font_color", Color(0.5, 0.5, 0.6, 0.6))
	
	# Gradually increase glitch intensity through phases
	var target_intensity = min(float(sequence_phase) / maxf(float(boot_sequence.size()), 1.0), 1.0)
	glitch_intensity = lerp(glitch_intensity, target_intensity, delta * 0.5)
	
	if color_rect.material:
		color_rect.material.set_shader_parameter("glitch_strength", glitch_intensity)
		color_rect.material.set_shader_parameter("time_offset", Time.get_ticks_msec() / 1000.0)
	
	# Handle typewriter effect
	if char_index < target_text.length():
		char_timer += delta
		if char_timer >= 0.03:  # 30ms per character for typewriter effect
			char_timer = 0.0
			char_index += 1
			current_text = target_text.substr(0, char_index)
			message_label.text = current_text
	else:
		# Wait for phase delay (check bounds to prevent index error)
		if sequence_phase < boot_sequence.size():
			phase_timer += delta
			if phase_timer >= boot_sequence[sequence_phase]["delay"]:
				advance_sequence()

func start_next_phase() -> void:
	if sequence_phase >= boot_sequence.size():
		transition_to_oakhaven()
		return
	
	var phase = boot_sequence[sequence_phase]
	target_text = phase["text"]
	char_index = 0
	current_text = ""
	char_timer = 0.0
	phase_timer = 0.0
	
	# Set color
	status_label.add_theme_color_override("font_color", phase["color"])
	message_label.add_theme_color_override("font_color", phase["color"])
	
	# Visual effects based on phase
	if phase["text"].contains("ERROR") or phase["text"].contains("PANIC"):
		# Screen shake effect
		var shake = Vector2(randf_range(-2, 2), randf_range(-2, 2))
		position = shake
	elif phase["text"].contains("DELETION"):
		# Intensify glitch
		if color_rect.material:
			color_rect.material.set_shader_parameter("glitch_strength", 1.0)
	else:
		position = Vector2.ZERO

func advance_sequence() -> void:
	sequence_phase += 1
	_update_progress()
	start_next_phase()

func _update_progress() -> void:
	## Update the compilation progress label based on how far through the boot sequence we are.
	if not progress_label:
		return
	var total = boot_sequence.size()
	if total == 0:
		return
	var pct = clamp(int(float(sequence_phase) / float(total) * 100.0), 0, 100)
	
	# Different labels for different progress ranges
	if pct < 15:
		progress_label.text = "Compiling entities... %d%%" % pct
		progress_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.7))
	elif pct < 40:
		progress_label.text = "Loading consciousness stream... %d%%" % pct
		progress_label.add_theme_color_override("font_color", Color(0.3, 0.8, 0.9))
	elif pct < 65:
		progress_label.text = "Binding to host environment... %d%%" % pct
		progress_label.add_theme_color_override("font_color", Color(0.9, 0.9, 0.3))
	elif pct < 85:
		progress_label.text = "Resolving permissions... %d%%" % pct
		progress_label.add_theme_color_override("font_color", Color(0.9, 0.4, 0.3))
	else:
		progress_label.text = "Deploying user... %d%%" % pct
		progress_label.add_theme_color_override("font_color", Color(0.3, 0.9, 0.4))

func transition_to_oakhaven() -> void:
	# Show 100% before fading out
	if progress_label:
		progress_label.text = "Deploying user... 100%"
		progress_label.add_theme_color_override("font_color", Color(0.3, 0.9, 0.4))
	
	# Hide skip hint
	if _skip_hint:
		_skip_hint.visible = false
	
	# Final transition effect
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(color_rect, "modulate:a", 0.0, 2.0)
	tween.tween_property(message_label, "modulate:a", 0.0, 2.0)
	tween.tween_property(status_label, "modulate:a", 0.0, 2.0)
	tween.tween_property(progress_label, "modulate:a", 0.0, 2.0)
	
	await tween.finished
	if not is_inside_tree(): return
	
	# Transition to Chapter 1: Glitch Crater Awakening
	if has_node("/root/GameManager"):
		GameManager.set_story_flag("plane_crash_completed", true)
	if has_node("/root/SceneTransitions"):
		SceneTransitions.change_scene("res://scenes/chapter1/glitch_crater_awakening.tscn")
	else:
		get_tree().change_scene_to_file("res://scenes/chapter1/glitch_crater_awakening.tscn")

func _skip_sequence() -> void:
	## Skip the entire boot sequence — go straight to Chapter 1
	set_process(false)
	if has_node("/root/GameManager"):
		GameManager.set_story_flag("plane_crash_completed", true)
	if has_node("/root/SceneTransitions"):
		SceneTransitions.change_scene("res://scenes/chapter1/glitch_crater_awakening.tscn", SceneTransitions.TransitionStyle.FADE)
	else:
		get_tree().change_scene_to_file("res://scenes/chapter1/glitch_crater_awakening.tscn")
