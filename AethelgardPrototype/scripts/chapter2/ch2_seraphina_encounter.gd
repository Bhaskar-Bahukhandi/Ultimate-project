extends Control

## Chapter 2, C2-S05 / S08 — the Command Hall (Brask, the disclosure choice) and the
## arena invitation. Words: dialogue/ch2/command_hall.dlg. (Scene file keeps its old name.)

@onready var camera: CinematicCamera = $CinematicCamera
@onready var cutscene_mgr: CutsceneManager = $CutsceneManager
@onready var characters_layer = $CharactersLayer
@onready var transition = $ScreenTransition
@onready var flash_overlay = $EffectsLayer/FlashOverlay

var choice_made: int = -1

func _ready() -> void:
	print("[CH2-SERAPHINA] Initializing Seraphina Encounter")
	GameManager.change_state(GameManager.GameState.DIALOGUE)

	# Play dialogue music for Seraphina encounter
	if has_node("/root/MusicManager"):
		MusicManager.play_track("dialogue")

	# Generate procedural background
	BackgroundManager.create_background("ironhold_arena", self)

	cutscene_mgr.camera = camera
	cutscene_mgr.characters_container = characters_layer
	cutscene_mgr.custom_effect.connect(_on_custom_effect)

	camera.smooth_enabled = true
	camera.make_current()

	await get_tree().create_timer(0.3).timeout
	if not is_inside_tree(): return
	transition.transition_in(ScreenTransition.TransitionType.FADE, 1.0)
	await transition.transition_finished
	if not is_inside_tree(): return

	await start_seraphina_sequence()
	if not is_inside_tree(): return

const DLG := "res://dialogue/ch2/command_hall.dlg"

func start_seraphina_sequence() -> void:
	## C2-S05 Command Hall and C2-S08 the arena invitation
	## (dialogue/ch2/command_hall.dlg).
	cutscene_mgr.play_cutscene({"name": "Command Hall", "beats": [
		{"type": "camera_move", "target": Vector2(640, 360), "duration": 0.5},
		{"type": "parallel", "beats": [
			{"type": "character_enter", "character": "Kaelen", "position": Vector2(420, 450), "from": "left", "duration": 1.2},
			{"type": "character_enter", "character": "Elara", "position": Vector2(350, 450), "from": "left", "duration": 1.4},
			{"type": "character_enter", "character": "Seraphina", "position": Vector2(560, 450), "from": "left", "duration": 1.0},
			{"type": "character_enter", "character": "Brask", "position": Vector2(860, 450), "from": "right", "duration": 1.0},
		]},
	]})
	await cutscene_mgr.cutscene_finished
	if not is_inside_tree(): return
	await DialogueManager.run(DLG, "start", _on_dlg_event)
	if not is_inside_tree(): return
	await get_tree().create_timer(0.8).timeout
	if not is_inside_tree(): return
	await _return_to_city()

func _on_dlg_event(event: String) -> void:
	match event:
		"hall":
			pass
		_:
			if event.begins_with("root_edit"):
				# The practice construct bows: a visible, costed edit.
				GameManager.add_glitch_corruption(3.0)
				camera.shake(3.0, 0.3)
				if flash_overlay:
					flash_overlay.color = Color(0.0, 1.0, 0.5, 0.3)
					flash_overlay.modulate.a = 0.6
					var t := create_tween()
					t.tween_property(flash_overlay, "modulate:a", 0.0, 0.4)
			else:
				print("[CH2-COMMAND-HALL] unhandled dialogue event: %s" % event)

func _return_to_city() -> void:
	DialogueManager.hide_dialogue()
	await transition.transition_out(ScreenTransition.TransitionType.FADE, 1.0) if transition else await get_tree().create_timer(1.0).timeout
	if not is_inside_tree(): return
	SceneTransitions.change_scene("res://scenes/regions/ironhold_region.tscn")

func _on_custom_effect(effect_name: String, _parameters: Dictionary) -> void:
	print("[CH2-SERAPHINA EFFECT] %s" % effect_name)
