extends Control

## Chapter 3: The Source Code
## Sequence 1: Ironhold Departure — Cinematic exit through the eastern bridge

var fade_rect: ColorRect
var background: ColorRect
var _camera: Node = null

func _ready() -> void:
	print("[CH3-DEPARTURE] Initializing Ironhold Departure")
	GameManager.change_state(GameManager.GameState.DIALOGUE)
	GameManager.set_story_flag("ch3_ironhold_departed", true)
	GameManager.current_chapter = 3

	if has_node("/root/MusicManager"):
		MusicManager.play_track("exploration")

	_camera = get_viewport().get_camera_2d()
	_build_background()

	# Fade in from black
	fade_rect.modulate = Color(1, 1, 1, 1)
	var tween = create_tween()
	tween.tween_property(fade_rect, "modulate:a", 0.0, 1.5)
	await tween.finished
	if not is_inside_tree(): return

	await _start_departure()
	if not is_inside_tree(): return

func _build_background() -> void:
	background = ColorRect.new()
	background.color = Color(0.08, 0.06, 0.12)
	background.anchors_preset = Control.PRESET_FULL_RECT
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(background)

	BackgroundManager.create_background("ironhold_city", self)

	fade_rect = ColorRect.new()
	fade_rect.color = Color.BLACK
	fade_rect.anchors_preset = Control.PRESET_FULL_RECT
	fade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fade_rect.z_index = 50
	add_child(fade_rect)

func _has_elara() -> bool:
	return GameManager.has_elara()

func _has_seraphina() -> bool:
	return _has_flag("ch2_seraphina_recruited")

func _has_flag(flag_name: String) -> bool:
	return GameManager.has_flag(flag_name)

func _start_departure() -> void:
	var has_elara = _has_elara()
	var has_seraphina = _has_seraphina()

	# ── Scene: Ironhold eastern gate, dawn. The damaged city behind them. ──
	if not await _show_dialogue("SYSTEM", "// CHAPTER 3: THE SOURCE CODE"): return
	if not is_inside_tree(): return
	await get_tree().create_timer(0.8).timeout
	if not is_inside_tree(): return

	if not await _show_dialogue("NARRATOR", "Dawn breaks over Ironhold. The eastern bridge — scarred from the Administrator's fall — groans under its own weight."): return

	if not await _show_dialogue("Kaelen", "Two fragments down, five to go. The next one's resonance is pulling east... into the dead zones."): return

	if has_elara:
		await _show_dialogue("Elara", "The Fractured Wastes. Nobody goes there, Kaelen. That region collapsed years ago — the corruption ate everything.")
		await _show_dialogue("Kaelen", "Which means SOVEREIGN's influence is weakest there. If a fragment survived, the corruption couldn't reach it.")
		await _show_dialogue("Elara", "Or it's what CAUSED the corruption.")
		# Elara's arm reacts
		await _show_dialogue("NARRATOR", "Elara's glitched arm flickers, lines of code cascading across her skin. She grips it tight.")
		await _show_dialogue("Elara", "My arm... it's responding to the fragment's signal. The closer we get, the stronger it becomes.")
	else:
		await _show_dialogue("Kaelen", "The Fractured Wastes. A whole region consumed by corruption. If a Source Key Fragment is there, that's where I'm headed.")

	if has_seraphina:
		await _show_dialogue("Seraphina", "The wastes are lawless territory. No city jurisdiction, no guard patrols. Whatever we find out there, we handle alone.")
		await _show_dialogue("Kaelen", "Good thing I brought a former arena champion then.")
		await _show_dialogue("Seraphina", "*smirks* Flattery. Keep it up — it might save your life.")
	elif _has_flag("ch2_seraphina_stayed"):
		await _show_dialogue("NARRATOR", "Kaelen pauses at the gate, remembering Seraphina's choice to remain and help rebuild Ironhold's resistance from within.")
		await _show_dialogue("Kaelen", "She'll hold down the city. We move forward.")

	# Reflection on Chapter 2
	await _show_dialogue("Kaelen", "The Administrator was just a proxy. SOVEREIGN was pulling strings the whole time... I can't keep reacting. I need to understand what SOVEREIGN actually IS.")

	# System warning
	await _screen_flash(Color(0.2, 0.8, 0.2, 0.4), 0.3)
	await _show_dialogue("SYSTEM", "// WARNING: Entering deprecated region. Stability not guaranteed. Proceed at own risk.")

	if has_elara:
		await _show_dialogue("Elara", "Deprecated. That's comforting.")
		await _show_dialogue("Kaelen", "At least they're honest about it.")

	# Final look back at Ironhold
	await _show_dialogue("NARRATOR", "Kaelen steps onto the eastern bridge. The metal protests beneath his feet. Behind him, Ironhold's chimneys belch smoke into a bruised sky. Ahead — nothing but wasteland.")
	if not is_inside_tree(): return

	await get_tree().create_timer(0.5).timeout
	if not is_inside_tree(): return

	# Glitch effect as they leave the "supported" region
	if has_node("/root/GlitchOverlay"):
		GlitchOverlay.flash_glitch(0.4)
	if has_node("/root/SFXManager"):
		SFXManager.play("glitch_trigger")

	await _show_dialogue("SYSTEM", "// Region boundary crossed. Entering: THE FRACTURED WASTES")
	await _show_dialogue("SYSTEM", "// Data integrity: 23%. Memory allocation: FRAGMENTED. Good luck, user.")
	if not is_inside_tree(): return

	# Transition
	await get_tree().create_timer(0.8).timeout
	if not is_inside_tree(): return

	await _fade_to_black(1.5)
	GameManager.current_region = "fractured_wastes"
	GameManager.change_state(GameManager.GameState.EXPLORATION)
	SceneTransitions.change_scene("res://scenes/regions/fractured_wastes_region.tscn")

# ── Utility Functions ─────────────────────────────────────────────────

func _show_dialogue(speaker: String, text: String) -> bool:
	await DialogueManager.say(speaker, text)
	return is_inside_tree()

func _screen_flash(color: Color, duration: float) -> void:
	if not is_instance_valid(fade_rect): return
	var old_z = fade_rect.z_index
	fade_rect.z_index = 100
	fade_rect.color = color
	fade_rect.modulate = Color(1, 1, 1, 0)
	var tw = create_tween()
	tw.tween_property(fade_rect, "modulate:a", 0.8, duration * 0.3)
	tw.tween_property(fade_rect, "modulate:a", 0.0, duration * 0.7)
	await tw.finished
	if not is_inside_tree(): return
	fade_rect.color = Color.BLACK
	fade_rect.z_index = old_z

func _fade_to_black(duration: float) -> void:
	if not is_instance_valid(fade_rect): return
	fade_rect.z_index = 100
	fade_rect.color = Color.BLACK
	fade_rect.modulate = Color(1, 1, 1, 0)
	var tw = create_tween()
	tw.tween_property(fade_rect, "modulate:a", 1.0, duration)
	await tw.finished
	if not is_inside_tree(): return

func _input(event) -> void:
	if event.is_action_pressed("ui_cancel"):
		if has_node("/root/PauseScreen"):
			PauseScreen.toggle_pause()
