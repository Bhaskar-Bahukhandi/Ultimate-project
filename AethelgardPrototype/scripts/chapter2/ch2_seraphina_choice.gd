extends Control

## Chapter 2, C2-S15 to S17 — Fragment Two, the Flight 707 wall scene, Seraphina decides.
## Words: dialogue/ch2/fragment_two.dlg. (Scene file keeps its old name.)

var choice_made: int = -1
var _flicker_tweens: Array = []

func _exit_tree() -> void:
	for tw in _flicker_tweens:
		if tw and tw.is_valid():
			tw.kill()
	_flicker_tweens.clear()

func _ready() -> void:
	print("[CH2-SERAPHINA-CHOICE] Initializing Seraphina's Choice")
	GameManager.change_state(GameManager.GameState.DIALOGUE)

	# Play dialogue music for Seraphina's choice
	if has_node("/root/MusicManager"):
		MusicManager.play_track("dialogue")

	_build_background()

	await get_tree().create_timer(0.5).timeout
	if not is_inside_tree(): return
	await _start_sequence()
	if not is_inside_tree(): return

# --------------------------------------------------------------------------- #
#  Background — damaged city square at night, aftermath of proxy fight
# --------------------------------------------------------------------------- #

func _build_background() -> void:
	## Build the post-battle night scene with damaged city square
	# Dark night sky
	var sky = ColorRect.new()
	sky.color = Color(0.03, 0.02, 0.06)
	sky.size = Vector2(1280, 400)
	sky.position = Vector2(0, 0)
	sky.z_index = -10
	add_child(sky)

	# Orange-red glow on the horizon (aftermath of the proxy fight)
	var glow = ColorRect.new()
	glow.color = Color(0.55, 0.15, 0.05, 0.35)
	glow.size = Vector2(1280, 180)
	glow.position = Vector2(0, 220)
	glow.z_index = -9
	add_child(glow)

	var glow_pulse = create_tween().set_loops()
	glow_pulse.tween_property(glow, "modulate:a", 0.6, 2.5).set_trans(Tween.TRANS_SINE)
	glow_pulse.tween_property(glow, "modulate:a", 1.0, 2.5).set_trans(Tween.TRANS_SINE)
	_flicker_tweens.append(glow_pulse)

	# Ground — cracked city square
	var ground = ColorRect.new()
	ground.color = Color(0.12, 0.1, 0.08)
	ground.size = Vector2(1280, 320)
	ground.position = Vector2(0, 400)
	ground.z_index = -8
	add_child(ground)

	# Damage cracks / darker patches across the ground
	var crack_data = [
		Vector2(150, 430), Vector2(120, 18),
		Vector2(400, 460), Vector2(200, 12),
		Vector2(700, 420), Vector2(160, 15),
		Vector2(950, 470), Vector2(180, 10),
		Vector2(300, 510), Vector2(140, 14),
		Vector2(820, 530), Vector2(110, 12),
	]
	for i in range(0, crack_data.size(), 2):
		var crack = ColorRect.new()
		crack.color = Color(0.04, 0.03, 0.02, 0.8)
		crack.position = crack_data[i]
		crack.size = crack_data[i + 1]
		crack.rotation_degrees = randf_range(-12.0, 12.0)
		crack.z_index = -7
		add_child(crack)

	# Smoke / haze overlay
	var haze = ColorRect.new()
	haze.color = Color(0.2, 0.12, 0.08, 0.12)
	haze.size = Vector2(1280, 720)
	haze.position = Vector2(0, 0)
	haze.z_index = -1
	add_child(haze)

	var haze_tween = create_tween().set_loops()
	haze_tween.tween_property(haze, "modulate:a", 0.5, 4.0).set_trans(Tween.TRANS_SINE)
	haze_tween.tween_property(haze, "modulate:a", 1.0, 4.0).set_trans(Tween.TRANS_SINE)
	_flicker_tweens.append(haze_tween)

	# Flickering lights — damaged street lamps
	_create_flickering_light(Vector2(200, 350), Color(1, 0.7, 0.3, 0.5))
	_create_flickering_light(Vector2(580, 370), Color(1, 0.5, 0.2, 0.4))
	_create_flickering_light(Vector2(1020, 355), Color(1, 0.65, 0.25, 0.45))

	# Debris rectangles scattered around
	var debris_positions = [
		Vector2(100, 480), Vector2(340, 500), Vector2(560, 490),
		Vector2(760, 510), Vector2(1050, 485), Vector2(1180, 505),
	]
	for pos in debris_positions:
		var debris = ColorRect.new()
		var dw = randf_range(15.0, 40.0)
		var dh = randf_range(8.0, 20.0)
		debris.size = Vector2(dw, dh)
		debris.color = Color(0.18, 0.14, 0.1, 0.7)
		debris.position = pos
		debris.rotation_degrees = randf_range(-25.0, 25.0)
		debris.z_index = -6
		add_child(debris)

func _create_flickering_light(pos: Vector2, col: Color) -> void:
	## Create a small flickering light at the given position
	var light = ColorRect.new()
	light.color = col
	light.size = Vector2(14, 22)
	light.position = pos
	light.z_index = -2
	add_child(light)

	var flicker = create_tween().set_loops()
	var _base_alpha = col.a
	flicker.tween_property(light, "modulate:a", randf_range(0.15, 0.4), randf_range(0.08, 0.2))
	flicker.tween_property(light, "modulate:a", 1.0, randf_range(0.05, 0.15))
	flicker.tween_property(light, "modulate:a", randf_range(0.3, 0.7), randf_range(0.1, 0.3))
	flicker.tween_property(light, "modulate:a", 1.0, randf_range(0.1, 0.25))
	_flicker_tweens.append(flicker)

# --------------------------------------------------------------------------- #
#  Main dialogue sequence
# --------------------------------------------------------------------------- #

func _has_elara() -> bool:
	return GameManager.has_elara()

func _has_flag(flag_name: String) -> bool:
	return GameManager.has_flag(flag_name)

const FRAG_DLG := "res://dialogue/ch2/fragment_two.dlg"

func _start_sequence() -> void:
	## C2-S15 Fragment Two, C2-S16 the upper wall, C2-S17 Seraphina decides
	## (dialogue/ch2/fragment_two.dlg). She isn't a recruit button: she goes
	## with Kaelen unless the city can't spare her or he's lost her trust.
	await DialogueManager.run(FRAG_DLG, "fragment", _on_dlg_event)
	if not is_inside_tree(): return
	await _fade_card(1.2)
	if not is_inside_tree(): return
	await DialogueManager.run(FRAG_DLG, "wall", _on_dlg_event)
	if not is_inside_tree(): return

	# Can Ironhold spare its Knight-Commander? Not if the fever's loose, the
	# tunnels were left sealed overnight, or the Proxy is still standing.
	var stable := GameManager.has_flag("ch2_administrator_proxy_defeated") \
		and not GameManager.has_flag("ch2_medicine_late") and not GameManager.has_flag("ch2_shift_sealed")
	GameManager.set_story_flag("ch2_city_stable", stable)
	await DialogueManager.run(FRAG_DLG, "commitment", _on_dlg_event)
	if not is_inside_tree(): return
	_mark_seraphina_route()
	await _sequence_complete()

func _on_dlg_event(event: String) -> void:
	var parts := event.split(" ", false, 1)
	match parts[0]:
		"touch_fragment", "memory_flash":
			var flash := ColorRect.new()
			flash.color = Color(1, 1, 1, 0.6)
			flash.size = get_viewport_rect().size
			flash.z_index = 90
			add_child(flash)
			var t := create_tween()
			t.tween_property(flash, "color:a", 0.0, 0.5)
			t.tween_callback(flash.queue_free)
			await get_tree().create_timer(0.4).timeout
		"flash_ends", "upper_wall":
			await get_tree().create_timer(0.4).timeout
		"fragment_acquired":
			GameManager.collect_source_key(int(parts[1]) if parts.size() > 1 else 2)
		_:
			print("[CH2-FRAGMENT-TWO] unhandled dialogue event: %s" % event)

func _fade_card(seconds: float) -> void:
	var fade := ColorRect.new()
	fade.color = Color(0, 0, 0, 0)
	fade.size = get_viewport_rect().size
	fade.z_index = 80
	add_child(fade)
	var t := create_tween()
	t.tween_property(fade, "color:a", 1.0, seconds * 0.5)
	t.tween_property(fade, "color:a", 0.0, seconds * 0.5)
	t.tween_callback(fade.queue_free)
	await t.finished

## Legacy route markers that later chapters still read.
func _mark_seraphina_route() -> void:
	if GameManager.has_flag("ch2_seraphina_recruited"):
		GameManager.set_story_flag("ch2_seraphina_bond_marker", true)
	elif GameManager.has_flag("ch2_seraphina_stayed"):
		GameManager.set_story_flag("ch2_seraphina_ironhold_marker", true)
	elif GameManager.has_flag("ch2_seraphina_rejected"):
		GameManager.set_story_flag("ch2_seraphina_rift_marker", true)
	if has_node("/root/LoreJournal"):
		LoreJournal.discover("ironhold_seraphina_route_marker")

func _sequence_complete() -> void:
	await get_tree().create_timer(1.0).timeout
	if not is_inside_tree(): return
	DialogueManager.hide_dialogue()
	var fade = ColorRect.new()
	fade.color = Color(0, 0, 0, 0)
	fade.size = get_viewport_rect().size
	fade.z_index = 100
	add_child(fade)
	var tween = create_tween()
	tween.tween_property(fade, "color:a", 1.0, 1.5)
	await tween.finished
	if not is_inside_tree(): return
	SceneTransitions.change_scene("res://scenes/chapter2/ch2_ending.tscn")
