extends Control

## Cinematic Flight 707 Prologue - Professional Implementation
## Uses advanced camera work, particles, shaders, and cutscene sequencing

@onready var camera: CinematicCamera = $CinematicCamera
@onready var cutscene_mgr: CutsceneManager = $CutsceneManager
@onready var characters_layer = $CharactersLayer
@onready var particles_layer = $ParticlesLayer
@onready var ambient_dust = $ParticlesLayer/AmbientDust
@onready var turbulence_sparks = $ParticlesLayer/TurbulenceSparks
@onready var glitch_particles = $ParticlesLayer/GlitchParticles
@onready var transition = $ScreenTransition
@onready var dialogue_box = $UILayer/DialogueBox
@onready var speaker_label = $UILayer/DialogueBox/MarginContainer/VBox/SpeakerLabel
@onready var dialogue_text = $UILayer/DialogueBox/MarginContainer/VBox/DialogueText
@onready var chapter_title = $UILayer/ChapterTitle
@onready var subtitle = $UILayer/Subtitle
@onready var glitch_overlay = $EffectsLayer/GlitchOverlay
@onready var flash_overlay = $EffectsLayer/FlashOverlay

var prologue_active = true
var skip_requested = false
var _skip_hint: Label = null
var _skip_hold_timer: float = 0.0
const SKIP_HOLD_DURATION: float = 1.5

func _ready() -> void:
	print("[FLIGHT 707] Initializing cinematic prologue")
	_build_skip_hint()
	
	# Play engine hum ambient SFX
	if has_node("/root/SFXManager"):
		SFXManager.play("engine_hum")

	# Generate procedural background (auto-upgrades when real assets exist)
	BackgroundManager.create_background("plane_interior", self)
	
	# Setup cutscene manager references
	cutscene_mgr.camera = camera
	cutscene_mgr.dialogue_box = dialogue_box
	cutscene_mgr.characters_container = characters_layer
	
	# Connect custom effect signal
	cutscene_mgr.custom_effect.connect(_on_custom_effect)
	
	# Camera setup
	camera.smooth_enabled = true
	camera.smooth_speed = 3.0
	camera.make_current()
	
	# Wait a moment then start
	await get_tree().create_timer(0.5, false).timeout
	if not is_inside_tree(): return
	await start_cinematic_prologue()
	if not is_inside_tree(): return

func start_cinematic_prologue() -> void:
	## Main prologue sequence - Full cinematic experience
	
	# Start with black screen
	await transition.transition_out(ScreenTransition.TransitionType.FADE, 0.5)
	if not is_inside_tree(): return
	
	# Fade in title
	var title_tween = create_tween()
	title_tween.tween_property(chapter_title, "modulate:a", 1.0, 2.0)
	title_tween.tween_property(subtitle, "modulate:a", 1.0, 1.5)
	await title_tween.finished
	if not is_inside_tree(): return
	
	await get_tree().create_timer(2.0, false).timeout
	if not is_inside_tree(): return
	
	# Fade out title
	title_tween = create_tween()
	title_tween.set_parallel(true)
	title_tween.tween_property(chapter_title, "modulate:a", 0.0, 1.0)
	title_tween.tween_property(subtitle, "modulate:a", 0.0, 1.0)
	
	# Fade in scene
	transition.transition_in(ScreenTransition.TransitionType.FADE, 2.0)
	await transition.transition_finished
	if not is_inside_tree(): return
	
	# A skip during the title must not start the cutscene (it blocks pause and
	# sets the CUTSCENE state) while the scene is being swapped out.
	if skip_requested:
		return

	# Play main cutscene
	var cutscene = create_prologue_cutscene()
	cutscene_mgr.play_cutscene(cutscene)
	await cutscene_mgr.cutscene_finished
	if not is_inside_tree(): return
	
	if skip_requested:
		await transition_to_crash()
		if not is_inside_tree(): return
		return

	await _play_optional_flight_observations()
	if not is_inside_tree(): return
	
	# Final sequence - building to crash
	await play_crash_buildup()
	if not is_inside_tree(): return
	
	# Transition to crash sequence
	await transition_to_crash()
	if not is_inside_tree(): return

func create_prologue_cutscene() -> Dictionary:
	## Define the complete prologue cutscene with all beats
	
	return {
		"name": "Flight 707 - Main Sequence",
		"beats": [
			# Beat 1: Establish cabin
			{
				"type": "camera_move",
				"target": Vector2(640, 360),
				"duration": 0.5
			},
			
			# Beat 2: Kaelen enters
			{
				"type": "character_enter",
				"character": "Kaelen",
				"position": Vector2(400, 420),
				"from": "left",
				"duration": 2.0
			},
			
			# Beat 3: Internal monologue 1
			{
				"type": "dialogue",
				"speaker": "Kaelen (Internal)",
				"text": "Another red-eye flight. Tokyo to San Francisco. Twelve hours of recycled air and crying babies...",
				"auto_advance": false
			},
			
			# Beat 4: Camera push in
			{
				"type": "camera_zoom",
				"zoom": Vector2(1.2, 1.2),
				"duration": 2.0
			},
			
			# Beat 5: More internal thoughts
			{
				"type": "dialogue",
				"speaker": "Kaelen (Internal)",
				"text": "At least I can finish debugging that inventory system. Three more merges until the release candidate...",
				"auto_advance": false
			},
			
			# Beat 6: Mira enters from right
			{
				"type": "parallel",
				"beats": [
					{
						"type": "character_enter",
						"character": "Mira",
						"position": Vector2(880, 420),
						"from": "right",
						"duration": 2.5
					},
					{
						"type": "camera_move",
						"target": Vector2(700, 360),
						"duration": 2.5
					},
					{
						"type": "camera_zoom",
						"zoom": Vector2(1.0, 1.0),
						"duration": 2.0
					}
				]
			},
			
			# Beat 7: Mira's introduction
			{
				"type": "dialogue",
				"speaker": "Mira",
				"text": "Excuse me, is this seat taken?",
				"auto_advance": false
			},
			
			# Beat 8: Kaelen looks up
			{
				"type": "parallel",
				"beats": [
					{
						"type": "character_move",
						"character": "Kaelen",
						"target": Vector2(420, 420),
						"duration": 0.5
					},
					{
						"type": "camera_zoom",
						"zoom": Vector2(1.3, 1.3),
						"duration": 1.0
					}
				]
			},
			
			# Beat 9: Kaelen responds
			{
				"type": "dialogue",
				"speaker": "Kaelen",
				"text": "Uh, no. Go ahead.",
				"auto_advance": false
			},
			
			# Beat 10: Mira sits
			{
				"type": "character_move",
				"character": "Mira",
				"target": Vector2(760, 420),
				"duration": 2.0
			},
			
			# Beat 10.5: Mira introduces herself (FIXES NAME PLOTHOLE)
			{
				"type": "dialogue",
				"speaker": "Mira",
				"text": "I'm Mira, by the way. Mira Chen. Figured if we're stuck next to each other for twelve hours, we should at least know names.",
				"auto_advance": false
			},
			
			# Beat 10.6: Kaelen responds
			{
				"type": "dialogue",
				"speaker": "Kaelen",
				"text": "Kaelen. Kaelen Vance. And yeah... twelve hours is a long time to pretend the other person doesn't exist.",
				"auto_advance": false
			},
			
			# Beat 10.7: Mira smiles
			{
				"type": "dialogue",
				"speaker": "Mira",
				"text": "*smiles* Exactly. Nice to meet you, Kaelen.",
				"auto_advance": false
			},
			
			# Beat 11: Kaelen's observation
			{
				"type": "dialogue",
				"speaker": "Kaelen (Internal)",
				"text": "Mira Chen. She's reading a book. An actual paper book. When's the last time I saw that?",
				"auto_advance": false
			},
			
			# Beat 12: Camera pulls back
			{
				"type": "camera_zoom",
				"zoom": Vector2(0.9, 0.9),
				"duration": 2.0
			},
			
			# Beat 13: More passengers - Kid with GameBoy appears
			{
				"type": "character_enter",
				"character": "PlaneChild",
				"position": Vector2(300, 420),
				"from": "left",
				"duration": 1.5
			},
			
			# Beat 14: Kaelen notices game
			{
				"type": "dialogue",
				"speaker": "Kaelen (Internal)",
				"text": "Kid across the aisle is playing some retro RPG. Probably grinding for rare drops...",
				"auto_advance": false
			},
			
			# Beat 15: First subtle turbulence
			{
				"type": "parallel",
				"beats": [
					{
						"type": "camera_shake",
						"intensity": 5.0,
						"duration": 0.8
					},
					{
						"type": "effect",
						"effect": "trigger_turbulence_light",
						"duration": 0.8
					}
				]
			},
			
			# Beat 16: React to turbulence
			{
				"type": "dialogue",
				"speaker": "Kaelen (Internal)",
				"text": "Turbulence. Great.",
				"auto_advance": false
			},
			
			# Beat 17: Time passes - Flight attendant enters
			{
				"type": "parallel",
				"beats": [
					{
						"type": "character_enter",
						"character": "FlightAttendant",
						"position": Vector2(500, 300),
						"from": "top",
						"duration": 2.0
					},
					{
						"type": "wait",
						"duration": 1.0
					}
				]
			},
			
			# Beat 18: Notice stewardess
			{
				"type": "dialogue",
				"speaker": "Kaelen (Internal)",
				"text": "Flight attendant looks... tired? No, something else. Her eyes are unfocused.",
				"auto_advance": false
			},
			
			# Beat 19: First glitch - screen flicker
			{
				"type": "effect",
				"effect": "glitch_screen",
				"duration": 0.3
			},
			
			# Beat 20: Did he see that?
			{
				"type": "dialogue",
				"speaker": "Kaelen (Internal)",
				"text": "Did I just... no, just tired. Need to stop staring at screens for fourteen hours straight.",
				"auto_advance": false
			},
			
			# Beat 21: Kid's game glitches
			{
				"type": "parallel",
				"beats": [
					{
						"type": "camera_move",
						"target": Vector2(300, 360),
						"duration": 1.5
					},
					{
						"type": "camera_zoom",
						"zoom": Vector2(1.4, 1.4),
						"duration": 1.5
					}
				]
			},
			
			# Beat 22: Game glitch dialogue
			{
				"type": "dialogue",
				"speaker": "Child",
				"text": "Huh? What the... my save file just corrupted!",
				"auto_advance": false
			},
			
			# Beat 23: System messages start
			{
				"type": "dialogue",
				"speaker": "System",
				"text": "[ALERT: ANOMALY DETECTED IN SECTOR 707]",
				"auto_advance": true,
				"duration": 2.0
			},
			
			# Beat 24: Heavy turbulence begins
			{
				"type": "parallel",
				"beats": [
					{
						"type": "camera_shake",
						"intensity": 15.0,
						"duration": 3.0
					},
					{
						"type": "camera_zoom",
						"zoom": Vector2(1.0, 1.0),
						"duration": 2.0
					},
					{
						"type": "camera_move",
						"target": Vector2(640, 360),
						"duration": 2.0
					}
				]
			},
			
			# Beat 25: Pilot announcement
			{
				"type": "dialogue",
				"speaker": "Pilot (Intercom)",
				"text": "Ladies and gentlemen, this is your captain speaking. We're experiencing some... technical difficulties. Please remain calm and—",
				"auto_advance": true,
				"duration": 4.0
			},
			
			# Beat 26: Announcement cuts out
			{
				"type": "effect",
				"effect": "flash",
				"color": Color.RED,
				"duration": 0.2
			}
		]
	}

func _play_optional_flight_observations() -> void:
	## Optional prologue interactions: small lore reads before the crash escalates.
	var inspected: Dictionary = {}
	while inspected.size() < 3 and not skip_requested:
		var options: Array[String] = []
		var keys: Array[String] = []
		if not inspected.has("card"):
			options.append("Check the safety card tucked into the seat pocket")
			keys.append("card")
		if not inspected.has("manifest"):
			options.append("Glance at the cabin network manifest on Mira's tablet")
			keys.append("manifest")
		if not inspected.has("laptop"):
			options.append("Review the unfinished AetherCorp note on Kaelen's laptop")
			keys.append("laptop")
		options.append("Stop looking around and try to rest")
		keys.append("continue")

		var choice := await DialogueManager.show_choices("The cabin is quiet for one last minute. What does Kaelen notice?", options, "Kaelen")
		if not is_inside_tree(): return
		# -1 = the box was reset (a skip); don't treat it as picking option 0.
		if choice < 0 or skip_requested:
			break
		var key := keys[clampi(choice, 0, keys.size() - 1)]
		if key == "continue":
			break
		inspected[key] = true
		await _resolve_flight_observation(key)
		if not is_inside_tree(): return

	DialogueManager.hide_dialogue()


func _resolve_flight_observation(key: String) -> void:
	match key:
		"card":
			GameManager.set_story_flag("prologue_consent_card_found", true)
			await DialogueManager.say("Kaelen (Internal)", "The safety card flickers for half a second. Not oxygen masks. AetherCorp language: 'Emergency preservation requires consent confirmation unless subject is nonresponsive.'")
			if not is_inside_tree(): return
			await DialogueManager.say("Kaelen (Internal)", "Why would an airline safety card know AetherCorp transfer protocol?")
			if has_node("/root/LoreJournal"):
				LoreJournal.discover("prologue_consent_safety_card")
		"manifest":
			GameManager.set_story_flag("prologue_aethercorp_manifest_found", true)
			await DialogueManager.say("Mira", "My tablet just connected to something called AETHER-MANIFEST-707. That's... not the plane Wi-Fi.")
			if not is_inside_tree(): return
			await DialogueManager.say("Kaelen (Internal)", "The manifest lists sealed research packets, emergency audit keys, and my name beside a phrase I do not remember approving: Human Patch.")
			if has_node("/root/LoreJournal"):
				LoreJournal.discover("prologue_aethercorp_manifest")
		"laptop":
			GameManager.set_story_flag("prologue_human_patch_note_found", true)
			await DialogueManager.say("Kaelen (Internal)", "My laptop restores a draft note I thought I deleted: 'Human Patch: access is not ownership. Consent must survive panic states.'")
			if not is_inside_tree(): return
			await DialogueManager.say("Kaelen (Internal)", "That sounds like my writing. It also sounds like a warning I failed to finish.")
			if has_node("/root/LoreJournal"):
				LoreJournal.discover("prologue_human_patch_note")


func play_crash_buildup() -> void:
	## Final sequence before crash - intensifying glitches
	print("[PROLOGUE] Playing crash buildup sequence")
	
	# Play turbulence SFX
	if has_node("/root/SFXManager"):
		SFXManager.play("turbulence")

	# Start particle chaos
	trigger_turbulence_particles()
	
	# Rapid glitch effects
	for i in range(5):
		if skip_requested:
			return
		
		toggle_glitch_overlay(true)
		camera.shake(20.0 + i * 5.0, 0.4)
		
		# Trigger glitch particles on intense moments
		if i >= 2:
			trigger_glitch_particles()
		
		await get_tree().create_timer(0.5, false).timeout
		if not is_inside_tree(): return
		toggle_glitch_overlay(false)
		await get_tree().create_timer(0.3, false).timeout
		if not is_inside_tree(): return
	
	# System messages
	show_system_dialogue("CRITICAL ERROR: REALITY.DLL NOT RESPONDING")
	await get_tree().create_timer(1.5, false).timeout
	if not is_inside_tree(): return
	
	show_system_dialogue("ATTEMPTING EMERGENCY RESTART...")
	await get_tree().create_timer(1.0, false).timeout
	if not is_inside_tree(): return
	
	# Massive shake with all particles
	camera.earthquake_shake(2.0)
	trigger_turbulence_particles()
	trigger_glitch_particles()
	
	# Flash to white
	flash_screen(Color.WHITE, 0.5)
	await get_tree().create_timer(0.5, false).timeout
	if not is_inside_tree(): return
	
	# Everything glitches out
	toggle_glitch_overlay(true)
	await get_tree().create_timer(1.0, false).timeout
	if not is_inside_tree(): return

func show_dialogue(speaker: String, text: String) -> void:
	## Helper to show dialogue
	dialogue_box.visible = true
	speaker_label.text = speaker
	dialogue_text.text = text
	
	# Set color based on speaker
	if "System" in speaker:
		speaker_label.add_theme_color_override("font_color", Color.RED)
	elif "Internal" in speaker:
		speaker_label.add_theme_color_override("font_color", Color(0.5, 0.9, 1.0))
	else:
		speaker_label.add_theme_color_override("font_color", Color.WHITE)

func show_system_dialogue(text: String) -> void:
	## Show system alert dialogue
	show_dialogue("System", "[color=red]%s[/color]" % text)

var _glitch_tween: Tween = null

func _exit_tree() -> void:
	if _glitch_tween and _glitch_tween.is_valid():
		_glitch_tween.kill()
		_glitch_tween = null

func toggle_glitch_overlay(enabled: bool) -> void:
	## Toggle glitch visual effect
	if _glitch_tween and _glitch_tween.is_valid():
		_glitch_tween.kill()
		_glitch_tween = null
	glitch_overlay.visible = enabled
	if enabled:
		_glitch_tween = create_tween().set_loops()
		_glitch_tween.tween_property(glitch_overlay, "color:a", 0.4, 0.1)
		_glitch_tween.tween_property(glitch_overlay, "color:a", 0.1, 0.1)

func flash_screen(color: Color, duration: float) -> void:
	## Flash the screen with a color
	flash_overlay.color = color
	flash_overlay.modulate.a = 0.0
	
	var tween = create_tween()
	tween.tween_property(flash_overlay, "modulate:a", 0.9, duration * 0.3)
	tween.tween_property(flash_overlay, "modulate:a", 0.0, duration * 0.7)

func trigger_turbulence_particles() -> void:
	## Trigger turbulence sparks effect
	turbulence_sparks.emitting = true
	await get_tree().create_timer(1.0, false).timeout
	if not is_inside_tree(): return
	turbulence_sparks.emitting = false

func trigger_glitch_particles() -> void:
	## Trigger glitch particles effect
	glitch_particles.emitting = true
	await get_tree().create_timer(1.5, false).timeout
	if not is_inside_tree(): return
	glitch_particles.emitting = false

var _is_transitioning = false

func transition_to_crash() -> void:
	## Transition to crash sequence
	if _is_transitioning:
		return
	_is_transitioning = true
	print("[PROLOGUE] Transitioning to crash sequence")

	DialogueManager.hide_dialogue()
	await transition.transition_out(ScreenTransition.TransitionType.GLITCH, 1.5)
	if not is_inside_tree(): return
	
	GameManager.set_story_flag("plane_crash_completed", true)  # Canonical flag for prologue completion
	await get_tree().create_timer(0.5, false).timeout
	if not is_inside_tree(): return
	
	SceneTransitions.change_scene("res://scenes/prologue/crash_sequence.tscn")

func _build_skip_hint() -> void:
	_skip_hint = Label.new()
	_skip_hint.text = InputService.fmt("Hold {ui_cancel} to Skip Prologue")
	_skip_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_skip_hint.add_theme_font_size_override("font_size", 14)
	_skip_hint.add_theme_color_override("font_color", Color(0.5, 0.5, 0.6, 0.6))
	_skip_hint.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	_skip_hint.offset_left = -260
	_skip_hint.offset_top = -30
	_skip_hint.offset_right = -10
	_skip_hint.offset_bottom = -8
	_skip_hint.z_index = 60
	add_child(_skip_hint)

func _input(event) -> void:
	## Handle input for dialogue advancement and hold-to-skip
	if not prologue_active:
		return
	# Start hold-to-skip tracking on ESC press
	if event.is_action_pressed("ui_cancel"):
		_skip_hold_timer = 0.01
		get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed("ui_accept"):
		pass

func _process_skip(delta: float) -> void:
	## Called from _process — tracks hold-ESC progress
	if _skip_hold_timer > 0.0 and Input.is_action_pressed("ui_cancel"):
		_skip_hold_timer += delta
		if _skip_hint:
			var pct = clamp(_skip_hold_timer / SKIP_HOLD_DURATION, 0.0, 1.0)
			_skip_hint.text = "Skipping Prologue... %d%%" % int(pct * 100)
			_skip_hint.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0, 0.9))
		if _skip_hold_timer >= SKIP_HOLD_DURATION:
			_on_skip_to_gameplay()
			return
	else:
		_skip_hold_timer = 0.0
		if _skip_hint:
			_skip_hint.text = InputService.fmt("Hold {ui_cancel} to Skip Prologue")
			_skip_hint.add_theme_color_override("font_color", Color(0.5, 0.5, 0.6, 0.6))

func _process(delta: float) -> void:
	_process_skip(delta)

func _on_skip_to_gameplay() -> void:
	## Skip the ENTIRE prologue — jump straight to Chapter 1 gameplay
	if not prologue_active:
		return
	prologue_active = false
	skip_requested = true
	_is_transitioning = true   # stop_cutscene() resumes start_cinematic_prologue(); keep it from also heading to the crash scene
	set_process(false)
	cutscene_mgr.stop_cutscene()
	if _skip_hint:
		_skip_hint.visible = false
	# Set all prologue flags so game state is consistent
	GameManager.set_story_flag("plane_crash_completed", true)
	GameManager.set_story_flag("prologue_skipped", true)
	SceneTransitions.change_scene("res://scenes/chapter1/glitch_crater_awakening.tscn", SceneTransitions.TransitionStyle.FADE)

func _on_skip_pressed() -> void:
	## Legacy: skip to crash sequence (not full skip)
	skip_requested = true
	prologue_active = false
	cutscene_mgr.stop_cutscene()
	await transition_to_crash()
	if not is_inside_tree(): return

func _on_custom_effect(effect_name: String, parameters: Dictionary) -> void:
	## Handle custom cutscene effects
	print("[CUSTOM EFFECT] %s" % effect_name)
	
	match effect_name:
		"glitch_screen":
			toggle_glitch_overlay(true)
			await get_tree().create_timer(parameters.get("duration", 0.3), false).timeout
			if not is_inside_tree(): return
			toggle_glitch_overlay(false)
		"trigger_turbulence_light":
			trigger_turbulence_particles()
		_:
			print("[CUSTOM EFFECT] Unhandled: %s" % effect_name)
