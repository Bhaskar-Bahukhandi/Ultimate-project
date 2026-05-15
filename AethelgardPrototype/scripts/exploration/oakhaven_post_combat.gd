extends Node2D

# Epilogue Scene Manager - Chapter 1 Conclusion
# Implements the comprehensive post-combat narrative as per design doc

@onready var dialogue_box = get_node_or_null("UI/DialogueBox")
@onready var speaker_label = get_node_or_null("UI/DialogueBox/MarginContainer/VBox/SpeakerLabel")
@onready var dialogue_text = get_node_or_null("UI/DialogueBox/MarginContainer/VBox/DialogueText")
@onready var choices_panel = get_node_or_null("UI/ChoicesPanel")
@onready var choice_question = get_node_or_null("UI/ChoicesPanel/MarginContainer/VBox/ChoiceQuestion")
@onready var choices_container = get_node_or_null("UI/ChoicesPanel/MarginContainer/VBox")
@onready var glitch_overlay = get_node_or_null("GlitchOverlay")
@onready var fade_rect = get_node_or_null("FadeRect")

var epilogue_phase = 0
var awaiting_choice = false
var current_choice_result = 0
var dialogue_index = 0
var typewriter_index = 0
var typewriter_timer = 0.0
var phase_timer = 0.0
var full_dialogue_text = ""  # Stores complete text for typewriter effect
var _phase_advancing = false  # Guard against double-advance from timed phases
var _all_lines_shown = false  # Track when player has read all lines in a phase

# Comprehensive epilogue sequence
var epilogue_sequence = [
	# Phase 0: Post-Combat Reflection (Kaelen's Internal Monologue)
	{
		"type": "monologue",
		"speaker": "Kaelen (Internal)",
		"lines": [
			"[Screen fades from combat arena]",
			"...",
			"That wasn't like any tutorial I've ever designed.",
			"The slime... it *existed*. It fought. It died.",
			"And I... I deleted it.",
			"Not killed. Deleted. Like a corrupted file.",
			"Is that what I am now? A debugger with a kill switch?"
		],
		"duration": 8.0,
		"effects": ["glitch_pulse"]
	},
	
	# Phase 1: System Voice Warning
	{
		"type": "system_alert",
		"speaker": "System",
		"lines": [
			"[CORRUPTION DETECTED]",
			"[ROOT ACCESS USAGE LOGGED]",
			"[CURRENT INTEGRITY: %d%%]" % int(GameManager.glitch_meter),
			"[WARNING: EXCESSIVE REALITY MANIPULATION MAY ATTRACT ATTENTION]"
		],
		"duration": 5.0,
		"effects": ["red_flash", "screen_shake"]
	},
	
	# Phase 2: Kaelen's Response
	{
		"type": "monologue",
		"speaker": "Kaelen",
		"lines": [
			"Great. I'm debugging the universe and the universe is debugging *me*.",
			"If this world runs on code, then someone wrote it.",
			"And if someone wrote it... they're watching the logs."
		],
		"duration": 6.0,
		"effects": ["none"]
	},
	
	# Phase 3: Elara Approaches
	{
		"type": "dialogue",
		"speaker": "Elara",
		"lines": [
			"[Elara approaches from the treeline]",
			"Kaelen! You're okay!",
			"That was... incredible. I've never seen anyone fight like that.",
			"That glowing menu thing you summoned... what was it?"
		],
		"duration": 5.0,
		"effects": ["elara_enter"]
	},
	
	# Phase 4: Player Choice (Relationship Impact)
	{
		"type": "player_choice",
		"question": "How do you explain Root Access to Elara?",
		"choices": [
			{"text": "I hacked it. Changed its code.", "relationship_change": 5, "flag": "elara_truth"},
			{"text": "I... don't really know.", "relationship_change": 0, "flag": "elara_confused"},
			{"text": "Just game mechanics. Nothing special.", "relationship_change": -2, "flag": "elara_dismissed"}
		],
		"responses": [
			"Hacked it? You mean... this world is like a computer program? And you can *edit* it?",
			"Well, whatever it was, it worked. We should be careful though - using power we don't understand...",
			"...Right. Game mechanics. In a world we were pulled into by a plane crash. Sure."
		]
	},
	
	# Phase 5: Elara's Concern
	{
		"type": "dialogue",
		"speaker": "Elara",
		"lines": [
			"Listen, Kaelen. There's something you should know.",
			"When you used that power... I felt it. Like reality itself *shifted*.",
			"The System... it notices things like that.",
			"We need to be careful. Both of us."
		],
		"duration": 6.0,
		"effects": ["serious_tone"]
	},
	
	# Phase 6: Distant Glitch Warning
	{
		"type": "environmental",
		"description": "[Camera pans to distant tower on horizon]",
		"lines": [
			"[A structure in the distance begins glitching violently]",
			"[Reality tears appear around it, showing wireframe beneath]"
		],
		"duration": 3.0,
		"effects": ["camera_pan", "distant_glitch"]
	},
	
	# Phase 7: System Alert
	{
		"type": "system_alert",
		"speaker": "System",
		"lines": [
			"[WARNING]",
			"[UNAUTHORIZED REALITY EDITS DETECTED IN SECTOR 14]",
			"[DISPATCHING ADMINISTRATOR]",
			"[ESTIMATED ARRIVAL: 72:00:00]"
		],
		"duration": 5.0,
		"effects": ["red_screen", "alarm_sound"]
	},
	
	# Phase 8: Kaelen's Realization
	{
		"type": "monologue",
		"speaker": "Kaelen",
		"lines": [
			"Administrator? That doesn't sound good.",
			"Seventy-two hours. Three days.",
			"Before... what? Before someone comes to debug *me*?"
		],
		"duration": 5.0,
		"effects": ["tension_build"]
	},
	
	# Phase 9: The Hook - Mysterious Figure
	{
		"type": "cutscene",
		"description": "[A silhouette appears on the distant horizon]",
		"lines": [
			"[Static crackles across the screen]",
			"[A voice, distorted and mechanical]"
		],
		"duration": 3.0,
		"effects": ["silhouette_reveal", "static_heavy"]
	},
	
	# Phase 10: Administrator's Message
	{
		"type": "antagonist_reveal",
		"speaker": "???",
		"lines": [
			"Found you, Kenji.",
			"[Signal lost]"
		],
		"duration": 4.0,
		"effects": ["voice_distortion", "ominous"]
	},
	
	# Phase 11: Elara's Reaction
	{
		"type": "dialogue",
		"speaker": "Elara",
		"lines": [
			"Kaelen... did you hear that?",
			"Someone... someone just called your real name.",
			"How is that possible?"
		],
		"duration": 5.0,
		"effects": ["fear"]
	},
	
	# Phase 12: Final Determination
	{
		"type": "monologue",
		"speaker": "Kaelen",
		"lines": [
			"They know who I am. They know where I'm from.",
			"This isn't just a game world. It's a trap.",
			"And I have three days to figure out how to survive it.",
			"Time to stop playing by their rules."
		],
		"duration": 6.0,
		"effects": ["determination"]
	},
	
	# Phase 13: Chapter Complete
	{
		"type": "chapter_end",
		"lines": [
			"CHAPTER 1 COMPLETE",
			"",
			"TUTORIAL: SURVIVAL",
			"STATUS: COMPLETED",
			"",
			"NEW OBJECTIVE: UNDERSTAND THE SYSTEM",
			"TIME UNTIL ADMINISTRATOR ARRIVAL: 72:00:00",
			"",
			"ROOT ACCESS UNLOCKED",
			"CORRUPTION LEVEL: %d%%" % int(GameManager.glitch_meter),
			"RELATIONSHIP: ELARA +%d" % (GameManager.relationships.get("elara", 0)),
			"",
			"CHAPTER 2: THE ADMINISTRATOR'S GAME",
			"COMING SOON"
		],
		"duration": 10.0,
		"effects": ["title_card"]
	}
]

func _ready() -> void:
	# Initialize epilogue
	GameManager.set_story_flag("root_access_unlocked", true)
	if OS.is_debug_build():
		print("[EPILOGUE] Initializing comprehensive Chapter 1 conclusion")
	
	# Setup UI elements
	if dialogue_box:
		dialogue_box.visible = false
	if choices_panel:
		choices_panel.visible = false
	if fade_rect:
		fade_rect.modulate = Color(0, 0, 0, 1)  # Start with black screen
		# Fade in from black
		var tween = create_tween()
		tween.tween_property(fade_rect, "modulate:a", 0.0, 2.0)
	
	# Start epilogue sequence after fade in
	await get_tree().create_timer(2.5).timeout
	if not is_inside_tree(): return
	start_epilogue()

func start_epilogue() -> void:
	if OS.is_debug_build():
		print("[EPILOGUE] Starting Chapter 1 conclusion sequence")
	epilogue_phase = 0
	advance_epilogue()

func _process(delta: float) -> void:
	phase_timer += delta
	
	# Handle typewriter effect for dialogue — hold Space/accept to go 4x faster
	if dialogue_text and typewriter_index < full_dialogue_text.length():
		typewriter_timer += delta
		var speed = 0.03
		if Input.is_action_pressed("ui_accept") or Input.is_action_pressed("jump"):
			speed = 0.008  # 4x faster when holding action key
		if typewriter_timer >= speed:
			typewriter_timer = 0.0
			typewriter_index += 1
			# Update visible text to show characters up to current index
			dialogue_text.text = full_dialogue_text.substr(0, typewriter_index)

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept") or (event.is_action_pressed("interact") if InputMap.has_action("interact") else false):
		if awaiting_choice or _phase_advancing:
			return  # Don't skip during choices or auto-advancing phases

		if dialogue_index < get_current_phase_lines().size() - 1:
			dialogue_index += 1
			show_next_line()
		else:
			# All lines shown — allow immediate advance (no timer gate)
			_all_lines_shown = true
			advance_epilogue()

func get_current_phase_lines() -> Array:
	if epilogue_phase >= epilogue_sequence.size():
		return []
	return epilogue_sequence[epilogue_phase].get("lines", [])

func get_current_phase_duration() -> float:
	if epilogue_phase >= epilogue_sequence.size():
		return 0.0
	return epilogue_sequence[epilogue_phase].get("duration", 3.0)

func show_next_line() -> void:
	var lines = get_current_phase_lines()
	if dialogue_index >= lines.size():
		return
	
	var line = lines[dialogue_index]
	# HIGH PRIORITY: Add null check for dialogue_text
	if dialogue_text:
		# For RichTextLabel, escape brackets that aren't BBCode
		var display_text = line
		if dialogue_text is RichTextLabel:
			# Replace literal brackets with escaped versions if they're not BBCode tags
			# Stage directions like [Camera pans] should be displayed as-is
			display_text = line
		
		# Start with empty text for typewriter effect
		full_dialogue_text = display_text
		dialogue_text.text = ""
		typewriter_index = 0
		typewriter_timer = 0.0
	else:
		push_error("[EPILOGUE] dialogue_text node not found in scene hierarchy!")

func advance_epilogue() -> void:
	if epilogue_phase >= epilogue_sequence.size():
		end_epilogue()
		return

	var phase = epilogue_sequence[epilogue_phase]
	dialogue_index = 0
	phase_timer = 0.0
	_all_lines_shown = false
	_phase_advancing = false
	
	match phase["type"]:
		"monologue":
			show_monologue_phase(phase)
		"dialogue":
			show_dialogue_phase(phase)
		"system_alert":
			show_system_alert_phase(phase)
		"player_choice":
			show_choice_phase(phase)
		"environmental":
			show_environmental_phase(phase)
		"cutscene":
			show_cutscene_phase(phase)
		"antagonist_reveal":
			show_antagonist_phase(phase)
		"chapter_end":
			show_chapter_end_phase(phase)
	
	# Apply visual effects
	apply_phase_effects(phase.get("effects", []))
	
	epilogue_phase += 1

func show_monologue_phase(phase: Dictionary) -> void:
	if dialogue_box:
		dialogue_box.visible = true
	if speaker_label:
		speaker_label.text = phase["speaker"]
		speaker_label.add_theme_color_override("font_color", Color(0.7, 0.9, 1.0))
	show_next_line()

func show_dialogue_phase(phase: Dictionary) -> void:
	if dialogue_box:
		dialogue_box.visible = true
	if speaker_label:
		speaker_label.text = phase["speaker"]
		speaker_label.add_theme_color_override("font_color", Color.WHITE)
	show_next_line()

func show_system_alert_phase(phase: Dictionary) -> void:
	if dialogue_box:
		dialogue_box.visible = true
	if speaker_label:
		speaker_label.text = phase["speaker"]
		speaker_label.add_theme_color_override("font_color", Color.RED)
	show_next_line()

func show_choice_phase(phase: Dictionary) -> void:
	awaiting_choice = true
	if dialogue_box:
		dialogue_box.visible = false
	
	# Show choices panel
	if choices_panel:
		choices_panel.visible = true
	
	# Set question
	if choice_question:
		choice_question.text = phase.get("question", "Make your choice:")
	
	# Clear existing choice buttons (skip the question label)
	if choices_container:
		for child in choices_container.get_children():
			if child is Button:
				child.queue_free()
		
		# Add new choice buttons
		for i in range(phase["choices"].size()):
			var choice = phase["choices"][i]
			var button = Button.new()
			button.text = choice["text"]
			button.custom_minimum_size = Vector2(0, 40)
			button.pressed.connect(_on_choice_selected.bind(i, phase))
			choices_container.add_child(button)

func _on_choice_selected(choice_index: int, phase: Dictionary) -> void:
	awaiting_choice = false
	var choice = phase["choices"][choice_index]
	
	# Apply relationship change
	GameManager.relationships["elara"] += choice.get("relationship_change", 0)
	if OS.is_debug_build():
		print("[EPILOGUE] Elara relationship changed by %d, now at %d" % [choice.get("relationship_change", 0), GameManager.relationships["elara"]])
	
	# Set story flag
	if choice.has("flag"):
		GameManager.set_story_flag(choice["flag"], true)
	
	# Hide choices panel
	if choices_panel:
		choices_panel.visible = false
	
	# Clear choice buttons
	if choices_container:
		for child in choices_container.get_children():
			if child is Button:
				child.queue_free()
	
	# Show Elara's response in dialogue box
	current_choice_result = choice_index
	if dialogue_box:
		dialogue_box.visible = true
	if speaker_label:
		speaker_label.text = "Elara"
		speaker_label.add_theme_color_override("font_color", Color.WHITE)
	if dialogue_text:
		dialogue_text.text = phase["responses"][choice_index]
	
	# Continue after delay
	await get_tree().create_timer(4.0).timeout
	if not is_inside_tree(): return
	advance_epilogue()

func show_environmental_phase(phase: Dictionary) -> void:
	_phase_advancing = true  # Block player input during auto-advance phases
	if dialogue_box:
		dialogue_box.visible = false
	# Environmental effects handled by apply_phase_effects
	await get_tree().create_timer(phase.get("duration", 3.0)).timeout
	if not is_inside_tree(): return
	if _phase_advancing:  # Guard against double-advance
		_phase_advancing = false
		advance_epilogue()

func show_cutscene_phase(phase: Dictionary) -> void:
	_phase_advancing = true  # Block player input during auto-advance phases
	if dialogue_box:
		dialogue_box.visible = false
	# Cutscene effects handled by apply_phase_effects
	await get_tree().create_timer(phase.get("duration", 3.0)).timeout
	if not is_inside_tree(): return
	if _phase_advancing:  # Guard against double-advance
		_phase_advancing = false
		advance_epilogue()

func show_antagonist_phase(phase: Dictionary) -> void:
	if dialogue_box:
		dialogue_box.visible = true
	if speaker_label:
		speaker_label.text = phase["speaker"]
		speaker_label.add_theme_color_override("font_color", Color(1.0, 0.3, 0.3))
	show_next_line()

func show_chapter_end_phase(phase: Dictionary) -> void:
	if dialogue_box:
		dialogue_box.visible = false
	
	# Create chapter end card
	var end_card = ColorRect.new()
	end_card.color = Color.BLACK
	end_card.size = get_viewport_rect().size
	add_child(end_card)
	
	var label = Label.new()
	label.text = "\n".join(phase["lines"])
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 24)
	label.size = get_viewport_rect().size
	end_card.add_child(label)
	
	# Fade in
	end_card.modulate = Color(1, 1, 1, 0)
	var tween = create_tween()
	tween.tween_property(end_card, "modulate:a", 1.0, 2.0)
	
	await get_tree().create_timer(phase.get("duration", 10.0)).timeout
	if not is_inside_tree(): return
	end_epilogue()

func apply_phase_effects(effects: Array) -> void:
	for effect in effects:
		match effect:
			"glitch_pulse":
				if glitch_overlay:
					var tween = create_tween()
					tween.tween_method(pulse_glitch, 0.0, 1.0, 1.0)
			"screen_shake":
				apply_screen_shake()
			"red_flash":
				apply_color_flash(Color.RED)
			"red_screen":
				apply_color_flash(Color(1, 0, 0, 0.7))
			"distant_glitch":
				# Visual effect for distant glitching - quick flash
				if glitch_overlay:
					glitch_overlay.color = Color(1, 1, 0, 0.3)
					var tween = create_tween()
					tween.tween_property(glitch_overlay, "color:a", 0.0, 0.5)
			"static_heavy":
				if glitch_overlay:
					# Intensify glitch effect with rapid flashing
					for i in range(5):
						glitch_overlay.color = Color(0.5, 1, 0.5, 0.4)
						await get_tree().create_timer(0.05).timeout
						if not is_inside_tree(): return
						glitch_overlay.color = Color(0.5, 1, 0.5, 0.1)
						await get_tree().create_timer(0.05).timeout
						if not is_inside_tree(): return
			"silhouette_reveal":
				# CRITICAL: Create silhouette for Administrator reveal
				create_silhouette_effect()
			"camera_pan":
				# Pan camera to show distant tower
				apply_camera_pan()
			"elara_enter":
				# Simulate Elara entering (visual placeholder)
				if OS.is_debug_build():
					print("[EFFECT] Elara approaches from treeline")
			"voice_distortion":
				# Audio effect placeholder
				if OS.is_debug_build():
					print("[EFFECT] Voice distortion applied")
			"ominous":
				# Dark atmosphere
				if fade_rect:
					fade_rect.color = Color(0.2, 0, 0.2, 0.5)
					var tween = create_tween()
					tween.tween_property(fade_rect, "color:a", 0.0, 1.0)
			"alarm_sound":
				# Audio placeholder
				if OS.is_debug_build():
					print("[EFFECT] Alarm sound playing")
			"fear", "serious_tone", "tension_build", "determination":
				# Emotional tone markers - could affect music/sfx
				if OS.is_debug_build():
					print("[EFFECT] Emotional tone: ", effect)

func pulse_glitch(value: float) -> void:
	if glitch_overlay and glitch_overlay.material:
		glitch_overlay.material.set_shader_parameter("glitch_strength", value)

func apply_screen_shake() -> void:
	var original_pos = position
	var tween = create_tween()
	tween.tween_property(self, "position", original_pos + Vector2(randf_range(-5, 5), randf_range(-5, 5)), 0.05)
	tween.tween_property(self, "position", original_pos, 0.05)

func apply_color_flash(color: Color) -> void:
	if fade_rect:
		fade_rect.color = color
		var tween = create_tween()
		tween.tween_property(fade_rect, "modulate:a", 0.5, 0.1)
		tween.tween_property(fade_rect, "modulate:a", 0.0, 0.3)

func create_silhouette_effect() -> void:
	## CRITICAL: Create ominous silhouette for Administrator reveal
	# Create a dark silhouette figure in the distance
	var silhouette = ColorRect.new()
	silhouette.color = Color(0, 0, 0, 0.9)
	silhouette.size = Vector2(60, 150)  # Tall humanoid figure
	silhouette.position = Vector2(get_viewport_rect().size.x / 2 - 30, get_viewport_rect().size.y - 200)
	add_child(silhouette)
	
	# Fade in silhouette
	silhouette.modulate = Color(1, 1, 1, 0)
	var tween = create_tween()
	tween.tween_property(silhouette, "modulate:a", 1.0, 2.0)
	
	# Add red glow effect around silhouette
	var glow = ColorRect.new()
	glow.color = Color(1, 0, 0, 0.3)
	glow.size = Vector2(80, 170)
	glow.position = silhouette.position - Vector2(10, 10)
	add_child(glow)
	
	glow.modulate = Color(1, 1, 1, 0)
	var glow_tween = create_tween()
	glow_tween.tween_property(glow, "modulate:a", 0.5, 2.0)
	
	# Pulse the glow for ominous effect (finite loops to avoid leak)
	var pulse_tween = create_tween().set_loops(8)
	pulse_tween.tween_property(glow, "color:a", 0.5, 0.7)
	pulse_tween.tween_property(glow, "color:a", 0.2, 0.7)
	
	if OS.is_debug_build():
		print("[EFFECT] Administrator silhouette revealed")

func apply_camera_pan() -> void:
	## Pan camera to show distant tower
	# Simulate camera pan by moving entire scene
	var original_position = position
	var tween = create_tween()
	tween.tween_property(self, "position", position + Vector2(-100, -50), 1.5)
	tween.tween_property(self, "position", original_position, 1.0)
	
	if OS.is_debug_build():
		print("[EFFECT] Camera pans to distant tower")

func end_epilogue() -> void:
	if OS.is_debug_build():
		print("[EPILOGUE] Chapter 1 conclusion complete")
		print("=== PROTOTYPE END ===")
		print("Thank you for playing Aethelgard: The Glitch Sovereign!")

	# Fade to black before returning to main menu
	if fade_rect:
		fade_rect.color = Color.BLACK
		var tween = create_tween()
		tween.tween_property(fade_rect, "modulate:a", 1.0, 1.5)
		await tween.finished
		if not is_inside_tree(): return

	await get_tree().create_timer(1.0).timeout
	if not is_inside_tree(): return
	if has_node("/root/GameManager"):
		GameManager.reset_game()
	if has_node("/root/SceneTransitions"):
		SceneTransitions.change_scene("res://scenes/main_menu.tscn")
	else:
		get_tree().change_scene_to_file("res://scenes/main_menu.tscn")

