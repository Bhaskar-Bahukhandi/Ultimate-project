extends Control

## Chapter 2, A1-T01 / C2-S01 to S03 — the road, Seraphina, the gate.
## Words: dialogue/ch2/ironhold_arrival.dlg.

@onready var camera: CinematicCamera = $CinematicCamera
@onready var cutscene_mgr: CutsceneManager = $CutsceneManager
@onready var characters_layer = $CharactersLayer
@onready var transition = $ScreenTransition
@onready var glitch_overlay = $EffectsLayer/GlitchOverlay
@onready var flash_overlay = $EffectsLayer/FlashOverlay

var cinematic_active = true

func _ready() -> void:
	print("[CH2-GATE] Initializing Ironhold Gate sequence")
	GameManager.change_state(GameManager.GameState.DIALOGUE)
	GameManager.set_story_flag("ch2_ironhold_entered", true)
	GameManager.current_chapter = 2

	# Play exploration music for gate approach
	if has_node("/root/MusicManager"):
		MusicManager.play_track("exploration")

	# Generate procedural background
	BackgroundManager.create_background("ironhold_city", self)

	cutscene_mgr.camera = camera
	cutscene_mgr.characters_container = characters_layer
	cutscene_mgr.custom_effect.connect(_on_custom_effect)

	camera.smooth_enabled = true
	camera.smooth_speed = 3.0
	camera.make_current()

	# Fade in
	await get_tree().create_timer(0.3).timeout
	if not is_inside_tree(): return
	transition.transition_in(ScreenTransition.TransitionType.FADE, 1.5)
	await transition.transition_finished
	if not is_inside_tree(): return

	await start_gate_sequence()
	if not is_inside_tree(): return

const DLG := "res://dialogue/ch2/ironhold_arrival.dlg"

func start_gate_sequence() -> void:
	## A1-T01, C2-S01 to C2-S03 — the road, Ironhold on the horizon, the
	## Knight-Commander, the gate. Words: dialogue/ch2/ironhold_arrival.dlg.
	await _beats([
		{"type": "camera_move", "target": Vector2(640, 360), "duration": 0.5},
		{"type": "parallel", "beats": [
			{"type": "character_enter", "character": "Kaelen", "position": Vector2(400, 450), "from": "left", "duration": 2.0},
			{"type": "character_enter", "character": "Elara", "position": Vector2(330, 450), "from": "left", "duration": 2.5},
		]},
	])
	if not is_inside_tree(): return
	for node in ["road", "horizon", "commander", "gate"]:
		await DialogueManager.run(DLG, node, _on_dlg_event)
		if not is_inside_tree(): return
	await get_tree().create_timer(0.6).timeout
	if not is_inside_tree(): return
	await _transition_to_city()

func _has_elara() -> bool:
	return GameManager.has_elara()

func _has_flag(flag_name: String) -> bool:
	return GameManager.has_flag(flag_name)

func _beats(beats: Array) -> void:
	cutscene_mgr.play_cutscene({"name": "Ironhold Arrival", "beats": beats})
	await cutscene_mgr.cutscene_finished

func _on_dlg_event(event: String) -> void:
	match event:
		"kaelen_stops", "seraphina_grip", "kaelen_still", "queues":
			await get_tree().create_timer(0.5).timeout
		"walk_on":
			await _beats([{"type": "parallel", "beats": [
				{"type": "character_move", "character": "Kaelen", "target": Vector2(520, 450), "duration": 1.4},
				{"type": "character_move", "character": "Elara", "target": Vector2(450, 450), "duration": 1.4},
			]}])
		"ironhold_reveal":
			camera.move_to(Vector2(640, 300), 2.0)
			await get_tree().create_timer(2.2).timeout
		"convoy_passes":
			camera.shake(3.0, 0.4)
			for i in 3:
				var wagon := ColorRect.new()
				wagon.color = Color(0.4, 0.3, 0.2)
				wagon.size = Vector2(70, 34)
				wagon.position = Vector2(1300 + i * 110, 500)
				characters_layer.add_child(wagon)
				var t := create_tween()
				t.tween_property(wagon, "position:x", -200.0 + i * 110, 3.5)
				t.tween_callback(wagon.queue_free)
			await get_tree().create_timer(1.0).timeout
		"seraphina_helmet_off":
			await _beats([{"type": "character_enter", "character": "Seraphina", "position": Vector2(760, 450), "from": "right", "duration": 0.9}])
			if flash_overlay:
				flash_overlay.color = Color(1, 1, 1, 0.25)
				flash_overlay.modulate.a = 0.5
				var t := create_tween()
				t.tween_property(flash_overlay, "modulate:a", 0.0, 0.3)
		_:
			print("[CH2-GATE] unhandled dialogue event: %s" % event)

func _transition_to_city() -> void:
	## Transition to the explorable Ironhold region
	print("[CH2-GATE] Transitioning to Ironhold Region (open-world)")
	DialogueManager.hide_dialogue()

	await transition.transition_out(ScreenTransition.TransitionType.WIPE_RIGHT, 1.0)
	if not is_inside_tree(): return
	GameManager.current_region = "ironhold"
	GameManager.change_state(GameManager.GameState.EXPLORATION)
	SceneTransitions.change_scene("res://scenes/regions/ironhold_region.tscn")

func _on_custom_effect(effect_name: String, _parameters: Dictionary) -> void:
	print("[CH2-GATE EFFECT] %s" % effect_name)

# BUG-21-28: Removed empty _input() that only contained pass
