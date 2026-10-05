extends Control

## Chapter 1, A1-P03 to A1-P06 — the Broken Mile: Data Vision, the first Root Access
## edit, the rest stop and the first sight of Oakhaven. Words: dialogue/ch1/broken_mile.dlg.

@onready var camera: CinematicCamera = $CinematicCamera
@onready var cutscene_mgr: CutsceneManager = $CutsceneManager
@onready var characters_layer = $CharactersLayer
@onready var particles_layer = $ParticlesLayer
@onready var glitch_particles = $ParticlesLayer/GlitchParticles
@onready var transition = $ScreenTransition
@onready var dialogue_box = $UILayer/DialogueBox
@onready var glitch_overlay = $EffectsLayer/GlitchOverlay
@onready var flash_overlay = $EffectsLayer/FlashOverlay
@onready var data_vision_overlay = $EffectsLayer/DataVisionOverlay
@onready var root_access_panel = $UILayer/RootAccessPanel
@onready var code_panel = $UILayer/RootAccessPanel/MarginContainer/VBox/CodePanel
@onready var aggression_spinbox = $UILayer/RootAccessPanel/MarginContainer/VBox/PropertyList/ElasticityRow/SpinBox  # node keeps its old name
@onready var apply_button = $UILayer/RootAccessPanel/MarginContainer/VBox/ApplyButton
@onready var tutorial_prompt = $UILayer/TutorialPrompt

var cinematic_active = true
var skip_requested = false
var root_access_tutorial_active = false
var _ambient_tweens: Array[Tween] = []

func _exit_tree() -> void:
	for tw in _ambient_tweens:
		if tw and tw.is_valid():
			tw.kill()
	_ambient_tweens.clear()

func _ready() -> void:
	print("[CH1-SEQ3] Initializing Path to Oakhaven — Combat Tutorial")
	GameManager.change_state(GameManager.GameState.PROLOGUE)
	
	cutscene_mgr.camera = camera
	cutscene_mgr.dialogue_box = dialogue_box
	cutscene_mgr.characters_container = characters_layer
	cutscene_mgr.custom_effect.connect(_on_custom_effect)
	
	camera.smooth_enabled = true
	camera.smooth_speed = 3.0
	camera.make_current()
	
	# Hide all overlay/UI initially
	dialogue_box.visible = false
	data_vision_overlay.visible = false
	root_access_panel.visible = false
	tutorial_prompt.visible = false

	# Build procedural forest path environment
	_build_environment()

	# Connect apply button
	if apply_button:
		apply_button.pressed.connect(_on_root_access_apply)
	
	await get_tree().create_timer(0.3).timeout
	if not is_inside_tree(): return
	transition.transition_in(ScreenTransition.TransitionType.FADE, 1.5)
	await transition.transition_finished
	if not is_inside_tree(): return

	# Cinematic letterbox bars
	camera.enable_letterbox(60.0, 0.8)

	await start_path_sequence()
	if not is_inside_tree(): return

func _build_environment() -> void:
	## Build the forest path environment — warmer woods approaching Oakhaven
	var env = Control.new()
	env.name = "Environment"
	env.set_anchors_preset(Control.PRESET_FULL_RECT)
	env.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(env)
	move_child(env, 0)

	# Warm twilight sky (slightly brighter than previous scene)
	var sky = ColorRect.new()
	sky.color = Color(0.1, 0.07, 0.14)
	sky.set_anchors_preset(Control.PRESET_FULL_RECT)
	sky.mouse_filter = Control.MOUSE_FILTER_IGNORE
	env.add_child(sky)

	# Warm sky gradient (sunset hint)
	var sky_warm = ColorRect.new()
	sky_warm.color = Color(0.18, 0.08, 0.06, 0.3)
	sky_warm.size = Vector2(1280, 150)
	sky_warm.position = Vector2(0, 0)
	sky_warm.mouse_filter = Control.MOUSE_FILTER_IGNORE
	env.add_child(sky_warm)

	# Distant treeline silhouette (far background layer)
	var far_trees = ColorRect.new()
	far_trees.color = Color(0.04, 0.07, 0.04, 0.7)
	far_trees.size = Vector2(1280, 120)
	far_trees.position = Vector2(0, 250)
	far_trees.mouse_filter = Control.MOUSE_FILTER_IGNORE
	env.add_child(far_trees)

	# Forest ground
	var ground = ColorRect.new()
	ground.color = Color(0.05, 0.09, 0.04)
	ground.size = Vector2(1280, 300)
	ground.position = Vector2(0, 420)
	ground.mouse_filter = Control.MOUSE_FILTER_IGNORE
	env.add_child(ground)

	# Dirt path
	var path = ColorRect.new()
	path.color = Color(0.14, 0.1, 0.06)
	path.size = Vector2(1280, 50)
	path.position = Vector2(0, 430)
	path.mouse_filter = Control.MOUSE_FILTER_IGNORE
	env.add_child(path)

	# Golden trail
	var golden = ColorRect.new()
	golden.name = "GoldenTrail"
	golden.color = Color(1.0, 0.85, 0.2, 0.2)
	golden.size = Vector2(1280, 6)
	golden.position = Vector2(0, 448)
	golden.mouse_filter = Control.MOUSE_FILTER_IGNORE
	env.add_child(golden)
	var gp = create_tween().set_loops()
	_ambient_tweens.append(gp)
	gp.tween_property(golden, "modulate:a", 0.3, 2.5).set_trans(Tween.TRANS_SINE)
	gp.tween_property(golden, "modulate:a", 1.0, 2.5).set_trans(Tween.TRANS_SINE)

	# Tree silhouettes (denser forest, approaching village)
	var tree_data = [
		[Vector2(30, 170), Vector2(45, 260)],
		[Vector2(120, 190), Vector2(38, 235)],
		[Vector2(280, 210), Vector2(32, 215)],
		[Vector2(430, 220), Vector2(28, 200)],
		[Vector2(750, 195), Vector2(35, 230)],
		[Vector2(900, 200), Vector2(40, 225)],
		[Vector2(1050, 185), Vector2(38, 240)],
		[Vector2(1180, 195), Vector2(35, 230)],
	]
	for td in tree_data:
		var green = Color(0.035, 0.065, 0.025)
		var trunk = ColorRect.new()
		trunk.color = green
		trunk.position = td[0]
		trunk.size = td[1]
		trunk.mouse_filter = Control.MOUSE_FILTER_IGNORE
		env.add_child(trunk)
		var canopy = ColorRect.new()
		canopy.color = Color(green.r + 0.025, green.g + 0.035, green.b + 0.015, 0.9)
		canopy.size = Vector2(td[1].x * 3.2, td[1].x * 2.8)
		canopy.position = Vector2(td[0].x - td[1].x * 1.1, td[0].y - td[1].x * 1.8)
		canopy.mouse_filter = Control.MOUSE_FILTER_IGNORE
		env.add_child(canopy)
		var sway = create_tween().set_loops()
		_ambient_tweens.append(sway)
		var cx = canopy.position.x
		sway.tween_property(canopy, "position:x", cx + randf_range(2, 6), randf_range(3.0, 5.5)).set_trans(Tween.TRANS_SINE).set_delay(randf_range(0, 2.5))
		sway.tween_property(canopy, "position:x", cx - randf_range(2, 6), randf_range(3.0, 5.5)).set_trans(Tween.TRANS_SINE)

	# Fireflies (warmer color, more of them near village)
	for i in range(10):
		var fly = ColorRect.new()
		fly.color = Color(1.0, 0.9, 0.3, randf_range(0.15, 0.45))
		fly.size = Vector2(3, 3)
		var fy = randf_range(180, 410)
		var fx = randf_range(60, 1220)
		fly.position = Vector2(fx, fy)
		fly.mouse_filter = Control.MOUSE_FILTER_IGNORE
		env.add_child(fly)
		var ff = create_tween().set_loops()
		_ambient_tweens.append(ff)
		ff.tween_property(fly, "position", Vector2(fx + randf_range(-35, 35), fy + randf_range(-25, 25)), randf_range(3, 6)).set_trans(Tween.TRANS_SINE).set_delay(randf_range(0, 3))
		ff.tween_property(fly, "modulate:a", randf_range(0.1, 0.3), randf_range(1, 2.5))
		ff.tween_property(fly, "position", Vector2(fx + randf_range(-35, 35), fy + randf_range(-25, 25)), randf_range(3, 6)).set_trans(Tween.TRANS_SINE)
		ff.tween_property(fly, "modulate:a", 1.0, randf_range(1, 2.5))

	# Distant village glow (warm light on the right horizon)
	var village_glow = ColorRect.new()
	village_glow.color = Color(0.25, 0.15, 0.05, 0.2)
	village_glow.size = Vector2(300, 150)
	village_glow.position = Vector2(980, 280)
	village_glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	env.add_child(village_glow)
	var vg = create_tween().set_loops()
	_ambient_tweens.append(vg)
	vg.tween_property(village_glow, "modulate:a", 0.5, 3.5).set_trans(Tween.TRANS_SINE)
	vg.tween_property(village_glow, "modulate:a", 1.0, 3.5).set_trans(Tween.TRANS_SINE)

	# Vignette
	var vig_top = ColorRect.new()
	vig_top.color = Color(0, 0, 0.01, 0.45)
	vig_top.size = Vector2(1280, 100)
	vig_top.position = Vector2(0, 0)
	vig_top.mouse_filter = Control.MOUSE_FILTER_IGNORE
	env.add_child(vig_top)
	var vig_bot = ColorRect.new()
	vig_bot.color = Color(0, 0, 0, 0.45)
	vig_bot.size = Vector2(1280, 100)
	vig_bot.position = Vector2(0, 620)
	vig_bot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	env.add_child(vig_bot)

const DLG := "res://dialogue/ch1/broken_mile.dlg"

## How the player dealt with the guardian: "filter" (edited what it defends
## against), "calm" (turned its aggression down) or "fight" (no Root edit).
var _root_choice := ""
var guardian_resolved := false
var _target_filter: OptionButton = null
var _guardian: ColorRect = null
var _cart: ColorRect = null

func start_path_sequence() -> void:
	## A1-P03 to A1-P06 — the Broken Mile. The words are all in
	## dialogue/ch1/broken_mile.dlg; this scene stages it and runs the first
	## Root Access edit.
	await _beats([
		{"type": "camera_move", "target": Vector2(640, 360), "duration": 0.5},
		{"type": "parallel", "beats": [
			{"type": "character_enter", "character": "Kaelen", "position": Vector2(300, 420), "from": "left", "duration": 2.0},
			{"type": "character_enter", "character": "Elara", "position": Vector2(380, 420), "from": "left", "duration": 2.5},
		]},
	])
	if not is_inside_tree(): return
	_flicker_tree()
	await _say_node("tree_flicker")
	if not is_inside_tree(): return
	await _walk(520, 600)
	if not is_inside_tree(): return
	await _say_node("walk_manifest")
	if not is_inside_tree(): return
	await _say_node("cart")
	if not is_inside_tree(): return
	await _say_node("data_vision")
	if not is_inside_tree(): return
	await _walk(600, 680)
	if not is_inside_tree(): return
	await _say_node("guardian_intro")
	if not is_inside_tree(): return
	await _say_node("guardian_directive")   # opens Root Access and waits for the player
	if not is_inside_tree(): return
	match _root_choice:
		"filter":
			await _guardian_turns_away()
			if not is_inside_tree(): return
			await _say_node("root_used")
		"calm":
			await _say_node("root_used_calm")
		_:
			await _stage_guardian_fight()
			if not is_inside_tree(): return
			await _say_node("root_refused")
	if not is_inside_tree(): return
	await _walk(760, 840)
	if not is_inside_tree(): return
	await _say_node("rest_stop")
	if not is_inside_tree(): return
	await _say_node("ridge")
	if not is_inside_tree(): return
	transition_to_oakhaven()

func _say_node(node: String) -> void:
	await DialogueManager.run(DLG, node, _on_dlg_event)

func _beats(beats: Array) -> void:
	cutscene_mgr.play_cutscene({"name": "Chapter 1 - The Broken Mile", "beats": beats})
	await cutscene_mgr.cutscene_finished

func _walk(kaelen_x: float, elara_x: float) -> void:
	await _beats([{"type": "parallel", "beats": [
		{"type": "character_move", "character": "Kaelen", "target": Vector2(kaelen_x, 420), "duration": 1.6},
		{"type": "character_move", "character": "Elara", "target": Vector2(elara_x, 420), "duration": 1.6},
		{"type": "camera_move", "target": Vector2((kaelen_x + elara_x) * 0.5, 360), "duration": 1.6},
	]}])

func _on_dlg_event(event: String) -> void:
	match event:
		"elara_casts_cart":
			_cart = _add_prop("Cart", Vector2(820, 395), Vector2(80, 44), Color(0.36, 0.24, 0.12))
			flash_overlay.color = Color(0.5, 0.0, 0.6, 0.5)
			flash_overlay.modulate.a = 0.7
			await get_tree().create_timer(0.15).timeout
			if not is_inside_tree(): return
			flash_overlay.modulate.a = 0.0
			var t := create_tween()
			t.tween_property(_cart, "position:y", 470.0, 0.6).set_trans(Tween.TRANS_BACK)
			await t.finished
		"elara_glances", "elara_looks_at_arm":
			await get_tree().create_timer(0.5).timeout
		"unlock_data_vision":
			_show_data_vision_labels()
		"guardian_attacks":
			_guardian = _add_prop("Guardian", Vector2(1100, 392), Vector2(78, 56), Color(0.32, 0.26, 0.2))
			var t := create_tween()
			t.tween_property(_guardian, "position:x", 800.0, 0.8).set_trans(Tween.TRANS_EXPO)
			await t.finished
			if not is_inside_tree(): return
			camera.shake(7.0, 0.3)
		"show_directive":
			flash_overlay.color = Color(0.0, 1.0, 0.4, 0.35)
			flash_overlay.modulate.a = 0.6
			var t := create_tween()
			t.tween_property(flash_overlay, "modulate:a", 0.0, 0.4)
		"root_access_open":
			await _run_root_access_panel()
		"kaelen_hand_glitch":
			var k = characters_layer.get_node_or_null("Kaelen")
			if k:
				k.modulate = Color(1, 0.2, 1)
				await get_tree().create_timer(0.05).timeout
				if is_instance_valid(k):
					k.modulate = Color.WHITE
		_:
			if not (event.begins_with("objective ") or event.begins_with("journal ")):
				print("[CH1-SEQ3] unhandled dialogue event: %s" % event)

func _add_prop(prop_name: String, pos: Vector2, size: Vector2, color: Color) -> ColorRect:
	var r := ColorRect.new()
	r.name = prop_name
	r.position = pos
	r.size = size
	r.color = color
	characters_layer.add_child(r)
	return r

func _flicker_tree() -> void:
	var tree := _add_prop("FlickerTree", Vector2(700, 230), Vector2(40, 190), Color(0.1, 0.2, 0.06))
	var t := create_tween()
	for i in 3:
		t.tween_property(tree, "color", Color(0.16, 0.08, 0.04), 0.08)
		t.tween_interval(0.25)
		t.tween_property(tree, "color", Color(0.1, 0.2, 0.06), 0.08)
		t.tween_interval(0.4)

## Data Vision is observation, not authority: labels, nothing editable.
func _show_data_vision_labels() -> void:
	data_vision_overlay.visible = true
	data_vision_overlay.modulate.a = 0.0
	var box := VBoxContainer.new()
	box.name = "DataVisionTags"
	box.position = Vector2(860, 300)
	characters_layer.add_child(box)
	for tag in ["PROPERTY: STABILITY 12%", "TAG: ROAD_OBSTRUCTION", "OWNER: LEGACY_MAINT"]:
		var l := Label.new()
		l.text = tag
		l.add_theme_color_override("font_color", Color(0.3, 1.0, 0.5))
		l.add_theme_font_size_override("font_size", 13)
		box.add_child(l)
	var t := create_tween()
	t.tween_property(data_vision_overlay, "modulate:a", 0.5, 0.6)
	t.tween_interval(5.0)
	t.tween_property(data_vision_overlay, "modulate:a", 0.0, 0.8)
	t.parallel().tween_property(box, "modulate:a", 0.0, 0.8)
	t.tween_callback(func(): data_vision_overlay.visible = false)
	t.tween_callback(box.queue_free)

# ── The first Root Access edit (A1-P04) ───────────────────────────────────
# The guardian's directive is DEFEND NEST with TARGET FILTER: ALL and a null
# nest. Safe edits: the target filter and the aggression multiplier. The
# player may also refuse and just fight it.

func _run_root_access_panel() -> void:
	_root_choice = ""
	guardian_resolved = false
	if not root_access_panel or not apply_button:
		_root_choice = "fight"   # no UI: treat as fought normally
		return
	_configure_root_access_panel()
	root_access_panel.visible = true
	root_access_tutorial_active = true
	if tutorial_prompt:
		tutorial_prompt.visible = true
		tutorial_prompt.text = "ROOT ACCESS\nChange what it's defending against, or turn its aggression down, then Apply.\nEvery edit costs corruption. You can also just fight it."
	if _target_filter:
		_target_filter.grab_focus()
	var waited := 0.0
	while not guardian_resolved:
		await get_tree().create_timer(0.1).timeout
		if not is_inside_tree(): return
		waited += 0.1
		if waited > 180.0:   # nobody at the keyboard: fight it, no edit made
			_root_choice = "fight"
			guardian_resolved = true
	root_access_panel.visible = false
	root_access_tutorial_active = false
	if tutorial_prompt:
		tutorial_prompt.visible = false

func _configure_root_access_panel() -> void:
	var title := root_access_panel.get_node_or_null("MarginContainer/VBox/Title") as Label
	if title:
		title.text = "// ROOT ACCESS — Mosswood Guardian"
	if code_panel:
		code_panel.text = "DIRECTIVE: DEFEND NEST\nNEST_REFERENCE: null\n\n  [editable] target_filter\n  [editable] aggression_multiplier\n  (locked) health\n  (locked) nest_reference"
	var row_label := root_access_panel.get_node_or_null("MarginContainer/VBox/PropertyList/ElasticityRow/Label") as Label
	if row_label:
		row_label.text = "aggression_multiplier"
	if aggression_spinbox:
		aggression_spinbox.min_value = 0.0
		aggression_spinbox.max_value = 3.0
		aggression_spinbox.step = 0.1
		aggression_spinbox.value = 1.0
	var props = root_access_panel.get_node_or_null("MarginContainer/VBox/PropertyList")
	if props and _target_filter == null:
		var row := HBoxContainer.new()
		row.name = "TargetFilterRow"
		var l := Label.new()
		l.text = "target_filter"
		l.custom_minimum_size = Vector2(170, 0)
		row.add_child(l)
		_target_filter = OptionButton.new()
		_target_filter.add_item("ALL", 0)
		_target_filter.add_item("FRACTURE_ENTITIES", 1)
		row.add_child(_target_filter)
		props.add_child(row)
		props.move_child(row, 0)
	if _target_filter:
		_target_filter.select(0)
	var vbox = root_access_panel.get_node_or_null("MarginContainer/VBox")
	if vbox and not vbox.has_node("FightButton"):
		var fight := Button.new()
		fight.name = "FightButton"
		fight.text = "Don't edit it. Fight."
		fight.pressed.connect(_on_root_access_refused)
		vbox.add_child(fight)

func _on_root_access_apply() -> void:
	# guardian_resolved: the panel stays up until the wait loop polls (0.1 s);
	# repeat clicks in that window used to charge corruption each time.
	if not root_access_tutorial_active or guardian_resolved:
		return
	var filter_changed := _target_filter != null and _target_filter.selected == 1
	var aggression: float = aggression_spinbox.value if aggression_spinbox else 1.0
	if filter_changed:
		_root_choice = "filter"
	elif aggression <= 0.1:
		_root_choice = "calm"
	else:
		if tutorial_prompt:
			tutorial_prompt.text = "Nothing changed yet. Edit target_filter or aggression_multiplier, then Apply."
		return
	guardian_resolved = true
	GameManager.add_glitch_corruption(10.0)
	GameManager.set_story_flag("ch1_slime_root_access_tutorial", true)  # legacy name: first Root edit done

func _on_root_access_refused() -> void:
	if not root_access_tutorial_active or guardian_resolved:
		return
	_root_choice = "fight"
	guardian_resolved = true

func _guardian_turns_away() -> void:
	if not _guardian:
		return
	var t := create_tween()
	t.tween_property(_guardian, "position:x", 1150.0, 1.0)
	t.parallel().tween_property(_guardian, "modulate:a", 0.0, 1.0)
	await t.finished

func _stage_guardian_fight() -> void:
	for i in 3:
		camera.shake(6.0, 0.2)
		flash_overlay.color = Color(1, 1, 1, 0.4)
		flash_overlay.modulate.a = 0.5
		await get_tree().create_timer(0.1).timeout
		if not is_inside_tree(): return
		flash_overlay.modulate.a = 0.0
		await get_tree().create_timer(0.35).timeout
		if not is_inside_tree(): return
	if _guardian:
		var t := create_tween()
		t.tween_property(_guardian, "modulate:a", 0.0, 0.8)
		await t.finished

var _is_transitioning_to_oakhaven: bool = false

func transition_to_oakhaven() -> void:
	## Transition to Sequence 4: Oakhaven Village
	if _is_transitioning_to_oakhaven:
		return
	_is_transitioning_to_oakhaven = true
	print("[CH1-SEQ3] Transitioning to Oakhaven Village")

	DialogueManager.hide_dialogue()
	if transition:
		camera.disable_letterbox(0.4)
		await transition.transition_out(ScreenTransition.TransitionType.FADE, 1.5)
		if not is_inside_tree(): return
		await get_tree().create_timer(0.3).timeout
		if not is_inside_tree(): return
	else:
		# Fallback fade if transition node doesn't exist
		var fallback_fade = ColorRect.new()
		fallback_fade.color = Color.BLACK
		fallback_fade.modulate.a = 0.0
		fallback_fade.size = get_viewport_rect().size
		add_child(fallback_fade)
		var tween = create_tween()
		tween.tween_property(fallback_fade, "modulate:a", 1.0, 1.5)
		await tween.finished
		if not is_inside_tree(): return
	
	SceneTransitions.change_scene("res://scenes/chapter1/oakhaven_village.tscn")

func _on_custom_effect(effect_name: String, parameters: Dictionary) -> void:
	match effect_name:
		"glitch_screen":
			glitch_overlay.visible = true
			glitch_overlay.color = Color(0.5, 1.0, 0.5, 0.4)
			await get_tree().create_timer(parameters.get("duration", 0.3)).timeout
			if not is_inside_tree(): return
			glitch_overlay.visible = false
		_:
			print("[CH1-SEQ3 EFFECT] Unhandled: %s" % effect_name)

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"):
		if root_access_tutorial_active:
			return  # Don't skip during tutorial
