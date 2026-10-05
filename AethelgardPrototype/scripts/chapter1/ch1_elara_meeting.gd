extends Control

## Chapter 1, A1-P02 — The Wrong Weapon: Kaelen meets Elara on the crash-site path.
## Animatic staging; the words are in dialogue/ch1/elara_meeting.dlg.

@onready var camera: CinematicCamera = $CinematicCamera
@onready var cutscene_mgr: CutsceneManager = $CutsceneManager
@onready var characters_layer = $CharactersLayer
@onready var particles_layer = $ParticlesLayer
@onready var glitch_particles = $ParticlesLayer/GlitchParticles
@onready var static_particles = $ParticlesLayer/StaticNoise
@onready var transition = $ScreenTransition
@onready var dialogue_box = $UILayer/DialogueBox
@onready var glitch_overlay = $EffectsLayer/GlitchOverlay
@onready var flash_overlay = $EffectsLayer/FlashOverlay
@onready var null_block_visual = $EffectsLayer/NullBlockVisual

var cinematic_active = true
var skip_requested = false
var _is_transitioning = false
var _ambient_tweens: Array[Tween] = []

func _exit_tree() -> void:
	for tw in _ambient_tweens:
		if tw and tw.is_valid():
			tw.kill()
	_ambient_tweens.clear()

func _ready() -> void:
	print("[CH1-SEQ2] Initializing Elara the Glitch-Witch meeting")
	GameManager.change_state(GameManager.GameState.PROLOGUE)
	
	cutscene_mgr.camera = camera
	cutscene_mgr.dialogue_box = dialogue_box
	cutscene_mgr.characters_container = characters_layer
	cutscene_mgr.custom_effect.connect(_on_custom_effect)
	
	camera.smooth_enabled = true
	camera.smooth_speed = 3.0
	camera.make_current()
	
	dialogue_box.visible = false
	if null_block_visual:
		null_block_visual.visible = false

	# Build procedural forest environment
	_build_environment()
	_widen_environment(64.0)

	await get_tree().create_timer(0.3, false).timeout
	if not is_inside_tree(): return
	
	# Fade in from the previous glitch transition
	transition.transition_in(ScreenTransition.TransitionType.FADE, 1.5)
	await transition.transition_finished
	if not is_inside_tree(): return

	# Cinematic letterbox bars
	camera.enable_letterbox(60.0, 0.8)

	await start_elara_meeting()
	if not is_inside_tree(): return

func _build_environment() -> void:
	## Build the forest clearing environment — twilight woods with golden trail
	var env = Control.new()
	env.name = "Environment"
	env.set_anchors_preset(Control.PRESET_FULL_RECT)
	env.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(env)
	move_child(env, 0)

	# Twilight sky — visible dark blue-purple
	var sky = ColorRect.new()
	sky.color = Color(0.16, 0.1, 0.28)
	sky.set_anchors_preset(Control.PRESET_FULL_RECT)
	sky.mouse_filter = Control.MOUSE_FILTER_IGNORE
	env.add_child(sky)

	# Upper sky glow
	var sky_glow = ColorRect.new()
	sky_glow.color = Color(0.25, 0.12, 0.4, 0.4)
	sky_glow.size = Vector2(1280, 180)
	sky_glow.position = Vector2(0, 0)
	sky_glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	env.add_child(sky_glow)

	# Forest ground — visible dark green
	var ground = ColorRect.new()
	ground.color = Color(0.08, 0.16, 0.06)
	ground.size = Vector2(1280, 300)
	ground.position = Vector2(0, 420)
	ground.mouse_filter = Control.MOUSE_FILTER_IGNORE
	env.add_child(ground)

	# Dirt path
	var path = ColorRect.new()
	path.color = Color(0.22, 0.16, 0.08)
	path.size = Vector2(1280, 50)
	path.position = Vector2(0, 430)
	path.mouse_filter = Control.MOUSE_FILTER_IGNORE
	env.add_child(path)

	# Golden trail on the path
	var golden = ColorRect.new()
	golden.name = "GoldenTrail"
	golden.color = Color(1.0, 0.85, 0.2, 0.4)
	golden.size = Vector2(1280, 6)
	golden.position = Vector2(0, 448)
	golden.mouse_filter = Control.MOUSE_FILTER_IGNORE
	env.add_child(golden)
	var gp = create_tween().set_loops()
	_ambient_tweens.append(gp)
	gp.tween_property(golden, "modulate:a", 0.4, 2.0).set_trans(Tween.TRANS_SINE)
	gp.tween_property(golden, "modulate:a", 1.0, 2.0).set_trans(Tween.TRANS_SINE)

	# Tree silhouettes (background trees on both sides)
	var tree_data = [
		[Vector2(50, 180), Vector2(40, 240)],
		[Vector2(180, 200), Vector2(35, 220)],
		[Vector2(350, 210), Vector2(30, 210)],
		[Vector2(800, 190), Vector2(38, 230)],
		[Vector2(950, 195), Vector2(42, 225)],
		[Vector2(1100, 185), Vector2(36, 235)],
		[Vector2(1200, 200), Vector2(32, 220)],
	]
	for td in tree_data:
		var base_green = Color(0.06, 0.14, 0.04)
		# Trunk
		var trunk = ColorRect.new()
		trunk.color = base_green
		trunk.position = td[0]
		trunk.size = td[1]
		trunk.mouse_filter = Control.MOUSE_FILTER_IGNORE
		env.add_child(trunk)
		# Canopy
		var canopy = ColorRect.new()
		canopy.color = Color(base_green.r + 0.02, base_green.g + 0.03, base_green.b + 0.01, 0.9)
		canopy.size = Vector2(td[1].x * 3, td[1].x * 2.5)
		canopy.position = Vector2(td[0].x - td[1].x, td[0].y - td[1].x * 1.5)
		canopy.mouse_filter = Control.MOUSE_FILTER_IGNORE
		env.add_child(canopy)
		# Canopy sway
		var sway = create_tween().set_loops()
		_ambient_tweens.append(sway)
		var cx = canopy.position.x
		sway.tween_property(canopy, "position:x", cx + randf_range(2, 5), randf_range(3.0, 5.0)).set_trans(Tween.TRANS_SINE).set_delay(randf_range(0, 2))
		sway.tween_property(canopy, "position:x", cx - randf_range(2, 5), randf_range(3.0, 5.0)).set_trans(Tween.TRANS_SINE)

	# Fireflies
	for i in range(8):
		var fly = ColorRect.new()
		fly.color = Color(0.85, 1.0, 0.4, randf_range(0.35, 0.7))
		fly.size = Vector2(3, 3)
		var fy = randf_range(200, 400)
		var fx = randf_range(80, 1200)
		fly.position = Vector2(fx, fy)
		fly.mouse_filter = Control.MOUSE_FILTER_IGNORE
		env.add_child(fly)
		var ff = create_tween().set_loops()
		_ambient_tweens.append(ff)
		ff.tween_property(fly, "position", Vector2(fx + randf_range(-30, 30), fy + randf_range(-20, 20)), randf_range(3, 6)).set_trans(Tween.TRANS_SINE).set_delay(randf_range(0, 3))
		ff.tween_property(fly, "modulate:a", randf_range(0.1, 0.3), randf_range(1, 2))
		ff.tween_property(fly, "position", Vector2(fx + randf_range(-30, 30), fy + randf_range(-20, 20)), randf_range(3, 6)).set_trans(Tween.TRANS_SINE)
		ff.tween_property(fly, "modulate:a", 1.0, randf_range(1, 2))

	# Vignette
	var vig_top = ColorRect.new()
	vig_top.color = Color(0, 0, 0.02, 0.25)
	vig_top.size = Vector2(1280, 100)
	vig_top.position = Vector2(0, 0)
	vig_top.mouse_filter = Control.MOUSE_FILTER_IGNORE
	env.add_child(vig_top)
	var vig_bot = ColorRect.new()
	vig_bot.color = Color(0, 0, 0, 0.25)
	vig_bot.size = Vector2(1280, 100)
	vig_bot.position = Vector2(0, 620)
	vig_bot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	env.add_child(vig_bot)

const DLG := "res://dialogue/ch1/elara_meeting.dlg"

var _slime: ColorRect = null

func start_elara_meeting() -> void:
	## A1-P02 — The Wrong Weapon. Every word is in dialogue/ch1/elara_meeting.dlg;
	## this scene stages the camera, the characters and the slime.
	await _beats([
		{"type": "camera_move", "target": Vector2(640, 360), "duration": 0.5},
		{"type": "character_enter", "character": "Kaelen", "position": Vector2(350, 420), "from": "left", "duration": 2.0},
		{"type": "character_move", "character": "Kaelen", "target": Vector2(470, 420), "duration": 1.5},
	])
	if not is_inside_tree(): return
	await DialogueManager.run(DLG, "start", _on_dlg_event)
	if not is_inside_tree(): return
	await _stage_slime_fight()
	if not is_inside_tree(): return
	await DialogueManager.run(DLG, "after_slime", _on_dlg_event)
	if not is_inside_tree(): return
	GameManager.set_story_flag("ch1_elara_glitch_witch_met", true)
	transition_to_path()

func _beats(beats: Array) -> void:
	cutscene_mgr.play_cutscene({"name": "Chapter 1 - The Wrong Weapon", "beats": beats})
	await cutscene_mgr.cutscene_finished

func _on_dlg_event(event: String) -> void:
	match event:
		"slime_appears":
			_slime = ColorRect.new()
			_slime.name = "FractureSlime"
			_slime.color = Color(0.45, 0.85, 0.75)
			_slime.size = Vector2(46, 30)
			_slime.position = Vector2(920, 425)
			characters_layer.add_child(_slime)
			var t := create_tween()
			t.tween_property(_slime, "position:x", 640.0, 1.2)
			await t.finished
		"elara_enters":
			await _beats([{"type": "character_enter", "character": "Elara", "position": Vector2(780, 420), "from": "right", "duration": 0.8}])
		"kaelen_lowers_sword", "kaelen_reaches_for_sword":
			_nudge("Kaelen", Vector2(0, 6))
			await get_tree().create_timer(0.3, false).timeout
		"elara_lowers_bow", "elara_raises_bow":
			_nudge("Elara", Vector2(0, 4) if event == "elara_lowers_bow" else Vector2(0, -4))
			await get_tree().create_timer(0.3, false).timeout
		_:
			if not event.begins_with("objective "):
				print("[CH1-SEQ2] unhandled dialogue event: %s" % event)

func _nudge(character_name: String, offset: Vector2) -> void:
	var c = characters_layer.get_node_or_null(character_name)
	if c:
		var t := create_tween()
		t.tween_property(c, "position", c.position + offset, 0.15)
		t.tween_property(c, "position", c.position, 0.15)

## The slime blocks the path; Kaelen can't get round it. It isn't playable
## here (the real combat tutorial is on the Broken Mile), so it's staged:
## it closes in, he swings, and it breaks into polygons, not blood.
func _stage_slime_fight() -> void:
	if not _slime:
		return
	var hop := create_tween()
	hop.tween_property(_slime, "position", Vector2(530, 400), 0.35)
	hop.tween_property(_slime, "position", Vector2(520, 425), 0.25)
	await hop.finished
	if not is_inside_tree(): return
	await _beats([{"type": "character_move", "character": "Kaelen", "target": Vector2(490, 420), "duration": 0.25}])
	if not is_inside_tree(): return
	camera.shake(6.0, 0.25)
	flash_overlay.color = Color(1, 1, 1, 0.5)
	flash_overlay.modulate.a = 0.6
	await get_tree().create_timer(0.08, false).timeout
	if not is_inside_tree(): return
	flash_overlay.modulate.a = 0.0
	var origin := _slime.position
	_slime.queue_free()
	_slime = null
	for i in 7:
		var shard := ColorRect.new()
		shard.color = Color(0.45, 0.85, 0.75)
		shard.size = Vector2(8, 8)
		shard.rotation = randf() * TAU
		shard.position = origin + Vector2(20, 12)
		characters_layer.add_child(shard)
		var t := create_tween().set_parallel(true)
		t.tween_property(shard, "position", shard.position + Vector2(randf_range(-60, 60), randf_range(-50, 10)), 0.6)
		t.tween_property(shard, "modulate:a", 0.0, 0.6)
		t.chain().tween_callback(shard.queue_free)
	await get_tree().create_timer(0.7, false).timeout

func transition_to_path() -> void:
	## Transition to Sequence 3: Path to Oakhaven — Combat Tutorial
	if _is_transitioning:
		return
	_is_transitioning = true
	print("[CH1-SEQ2] Transitioning to Path to Oakhaven")

	DialogueManager.hide_dialogue()
	camera.disable_letterbox(0.4)
	await transition.transition_out(ScreenTransition.TransitionType.FADE, 1.5)
	if not is_inside_tree(): return
	await get_tree().create_timer(0.3, false).timeout
	if not is_inside_tree(): return
	
	SceneTransitions.change_scene("res://scenes/chapter1/path_to_oakhaven.tscn")

func _on_custom_effect(effect_name: String, _parameters: Dictionary) -> void:
	## Handle custom cutscene effects
	match effect_name:
		"elara_spawn_glitch":
			# Static noise particle burst + purple glitch flash (NOT white day-flash)
			if static_particles:
				static_particles.emitting = true
			flash_overlay.color = Color(0.6, 0.0, 0.8, 0.5)
			flash_overlay.modulate.a = 0.4
			await get_tree().create_timer(0.2, false).timeout
			if not is_inside_tree(): return
			flash_overlay.modulate.a = 0.0
			if static_particles:
				await get_tree().create_timer(0.3, false).timeout
				if not is_inside_tree(): return
				static_particles.emitting = false
		"elara_model_glitch":
			# Simulate Z-axis stretch glitch on Elara's character
			var elara_node = characters_layer.get_node_or_null("Elara")
			if elara_node:
				var original_scale = elara_node.scale
				elara_node.scale = Vector2(0.3, 5.0)  # Stretch infinitely on Y
				await get_tree().create_timer(0.08, false).timeout
				if not is_inside_tree(): return
				elara_node.scale = original_scale
				# Quick color flash
				elara_node.modulate = Color(1, 0, 1, 1)
				await get_tree().create_timer(0.05, false).timeout
				if not is_inside_tree(): return
				elara_node.modulate = Color.WHITE
		_:
			print("[CH1-SEQ2 EFFECT] Unhandled: %s" % effect_name)

# BUG-21-28: Removed empty _input() that only contained pass
# BUG-21-30: Removed orphaned _on_skip_pressed() — never connected to any signal


## The forest is painted for one 1280-wide screen at x = 0, but the camera
## pans past it on the walks and shakes past its edges, which showed the old
## fixed daytime BackgroundLayer as a bright strip at the side of the screen.
## Stretch every full-width band (sky, treeline, ground, path) by `margin` on
## both sides so the camera always lands on painted forest.
func _widen_environment(margin: float) -> void:
	var env := get_node_or_null("Environment") as Control
	if not env:
		return
	for child in env.get_children():
		var c := child as Control
		if c == null:
			continue
		if c.anchor_right == 1.0 and c.anchor_bottom == 1.0:   # the full-screen sky
			c.set_anchors_preset(Control.PRESET_TOP_LEFT)
			c.position = Vector2(-margin, -margin)
			c.size = Vector2(1280.0 + margin * 2.0, 720.0 + margin * 2.0)
		elif is_zero_approx(c.position.x) and is_equal_approx(c.size.x, 1280.0):
			c.position.x = -margin
			c.size.x = 1280.0 + margin * 2.0
