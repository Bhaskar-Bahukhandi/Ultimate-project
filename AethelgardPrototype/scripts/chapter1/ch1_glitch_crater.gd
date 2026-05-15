extends Control

## Chapter 1: The Null Pointer Exception
## Sequence 1: Initialization and Awakening at the Glitch Crater
## Animatic cinematic — uses CutsceneManager, CinematicCamera, particles, effects

@onready var camera: CinematicCamera = $CinematicCamera
@onready var cutscene_mgr: CutsceneManager = $CutsceneManager
@onready var characters_layer = $CharactersLayer
@onready var particles_layer = $ParticlesLayer
@onready var ambient_dust = $ParticlesLayer/AmbientDust
@onready var glitch_particles = $ParticlesLayer/GlitchParticles
@onready var transition = $ScreenTransition
@onready var dialogue_box = $UILayer/DialogueBox
@onready var chapter_title = $UILayer/ChapterTitle
@onready var subtitle = $UILayer/Subtitle
@onready var glitch_overlay = $EffectsLayer/GlitchOverlay
@onready var flash_overlay = $EffectsLayer/FlashOverlay
@onready var boot_text = $UILayer/BootSequence
@onready var status_window = $UILayer/StatusWindow

var cinematic_active = true
var skip_requested = false
var _is_transitioning = false
var boot_lines_queue: Array = []
var current_boot_index = 0
var _ambient_tweens: Array[Tween] = []

func _exit_tree() -> void:
	for tw in _ambient_tweens:
		if tw and tw.is_valid():
			tw.kill()
	_ambient_tweens.clear()

func _ready() -> void:
	print("[CH1] Initializing Glitch Crater Awakening cinematic")
	GameManager.change_state(GameManager.GameState.PROLOGUE)
	
	# Setup cutscene manager references
	cutscene_mgr.camera = camera
	cutscene_mgr.dialogue_box = dialogue_box
	cutscene_mgr.characters_container = characters_layer
	cutscene_mgr.custom_effect.connect(_on_custom_effect)
	
	# Camera setup
	camera.smooth_enabled = true
	camera.smooth_speed = 3.0
	camera.make_current()
	
	# Hide UI elements initially
	dialogue_box.visible = false
	chapter_title.modulate.a = 0.0
	subtitle.modulate.a = 0.0
	boot_text.visible = false
	status_window.visible = false

	# Build procedural environment (visible after fade-in)
	_build_environment()

	await get_tree().create_timer(0.5).timeout
	if not is_inside_tree(): return
	await start_sequence()
	if not is_inside_tree(): return

func _build_environment() -> void:
	## Build the Glitch Crater environment — corrupted void with floating debris
	var env = Control.new()
	env.name = "Environment"
	env.set_anchors_preset(Control.PRESET_FULL_RECT)
	env.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(env)
	move_child(env, 0)

	# Dark void sky — deep purple, clearly visible
	var sky = ColorRect.new()
	sky.color = Color(0.15, 0.08, 0.25)
	sky.set_anchors_preset(Control.PRESET_FULL_RECT)
	sky.mouse_filter = Control.MOUSE_FILTER_IGNORE
	env.add_child(sky)

	# Upper nebula glow — bright purple haze
	var nebula = ColorRect.new()
	nebula.color = Color(0.22, 0.1, 0.35, 0.55)
	nebula.size = Vector2(1280, 220)
	nebula.position = Vector2(0, 0)
	nebula.mouse_filter = Control.MOUSE_FILTER_IGNORE
	env.add_child(nebula)

	# Ambient aurora shimmer — strong pulsing glow across the sky
	var aurora = ColorRect.new()
	aurora.color = Color(0.28, 0.12, 0.42, 0.4)
	aurora.size = Vector2(600, 150)
	aurora.position = Vector2(340, 50)
	aurora.mouse_filter = Control.MOUSE_FILTER_IGNORE
	env.add_child(aurora)
	var aurora_tw = create_tween().set_loops()
	_ambient_tweens.append(aurora_tw)
	aurora_tw.tween_property(aurora, "modulate:a", 0.3, 3.0).set_trans(Tween.TRANS_SINE)
	aurora_tw.tween_property(aurora, "modulate:a", 1.0, 3.0).set_trans(Tween.TRANS_SINE)

	# Stars
	for i in range(25):
		var star = ColorRect.new()
		star.size = Vector2(2, 2) if randf() > 0.25 else Vector2(3, 3)
		star.color = Color(0.7, 0.75, 1.0, randf_range(0.3, 0.8))
		star.position = Vector2(randf_range(20, 1260), randf_range(15, 280))
		star.mouse_filter = Control.MOUSE_FILTER_IGNORE
		env.add_child(star)
		var tw = create_tween().set_loops()
		_ambient_tweens.append(tw)
		tw.tween_property(star, "modulate:a", randf_range(0.15, 0.4), randf_range(1.5, 3.5)).set_delay(randf_range(0, 3))
		tw.tween_property(star, "modulate:a", 1.0, randf_range(1.5, 3.5))

	# Ground plane — visible dark terrain
	var ground = ColorRect.new()
	ground.color = Color(0.14, 0.09, 0.2)
	ground.size = Vector2(1280, 340)
	ground.position = Vector2(0, 380)
	ground.mouse_filter = Control.MOUSE_FILTER_IGNORE
	env.add_child(ground)

	# Horizon glow — bright atmospheric line
	var horizon = ColorRect.new()
	horizon.color = Color(0.25, 0.1, 0.38, 0.65)
	horizon.size = Vector2(1280, 30)
	horizon.position = Vector2(0, 360)
	horizon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	env.add_child(horizon)
	var hp = create_tween().set_loops()
	_ambient_tweens.append(hp)
	hp.tween_property(horizon, "modulate:a", 0.4, 3.0).set_trans(Tween.TRANS_SINE)
	hp.tween_property(horizon, "modulate:a", 1.0, 3.0).set_trans(Tween.TRANS_SINE)

	# Crater rim silhouettes
	var rims = [
		[Vector2(0, 355), Vector2(220, 55)],
		[Vector2(140, 368), Vector2(160, 38)],
		[Vector2(860, 350), Vector2(240, 60)],
		[Vector2(1040, 362), Vector2(240, 48)],
	]
	for rd in rims:
		var rim = ColorRect.new()
		rim.color = Color(0.16, 0.09, 0.22)
		rim.position = rd[0]
		rim.size = rd[1]
		rim.mouse_filter = Control.MOUSE_FILTER_IGNORE
		env.add_child(rim)

	# Crater depression (darker pit in center)
	var crater_pit = ColorRect.new()
	crater_pit.color = Color(0.06, 0.03, 0.09)
	crater_pit.size = Vector2(400, 70)
	crater_pit.position = Vector2(440, 400)
	crater_pit.mouse_filter = Control.MOUSE_FILTER_IGNORE
	env.add_child(crater_pit)

	# Floating corrupted rocks
	for i in range(6):
		var rock = ColorRect.new()
		rock.color = Color(0.2, 0.13, 0.3, 0.85)
		rock.size = Vector2(randf_range(8, 22), randf_range(6, 16))
		var ry = randf_range(240, 370)
		rock.position = Vector2(randf_range(60, 1220), ry)
		rock.rotation_degrees = randf_range(-25, 25)
		rock.mouse_filter = Control.MOUSE_FILTER_IGNORE
		env.add_child(rock)
		var ft = create_tween().set_loops()
		_ambient_tweens.append(ft)
		ft.tween_property(rock, "position:y", ry - randf_range(5, 18), randf_range(2.0, 4.5)).set_trans(Tween.TRANS_SINE).set_delay(randf_range(0, 2.5))
		ft.tween_property(rock, "position:y", ry, randf_range(2.0, 4.5)).set_trans(Tween.TRANS_SINE)

	# Corruption veins on the ground (glowing purple lines)
	for i in range(5):
		var vein = ColorRect.new()
		vein.color = Color(0.6, 0.15, 0.85, 0.4)
		vein.size = Vector2(randf_range(50, 180), 2)
		vein.position = Vector2(randf_range(80, 1100), randf_range(420, 660))
		vein.rotation_degrees = randf_range(-12, 12)
		vein.mouse_filter = Control.MOUSE_FILTER_IGNORE
		env.add_child(vein)
		var vt = create_tween().set_loops()
		_ambient_tweens.append(vt)
		vt.tween_property(vein, "modulate:a", randf_range(0.2, 0.4), randf_range(1.2, 2.5)).set_delay(randf_range(0, 1.5))
		vt.tween_property(vein, "modulate:a", 1.0, randf_range(1.2, 2.5))

	# Golden path (starts invisible, revealed during cutscene)
	var golden_path = ColorRect.new()
	golden_path.name = "GoldenPathHint"
	golden_path.color = Color(1.0, 0.85, 0.2, 0.0)
	golden_path.size = Vector2(500, 5)
	golden_path.position = Vector2(640, 448)
	golden_path.mouse_filter = Control.MOUSE_FILTER_IGNORE
	env.add_child(golden_path)

	# Drifting scan lines (CRT feel — "broken machine" theme)
	for i in range(4):
		var sl = ColorRect.new()
		sl.color = Color(0, 0, 0, 0.08)
		sl.size = Vector2(1280, 2)
		var sly = randf_range(50, 670)
		sl.position = Vector2(0, sly)
		sl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		env.add_child(sl)
		var slt = create_tween().set_loops()
		_ambient_tweens.append(slt)
		slt.tween_property(sl, "position:y", randf_range(50, 670), randf_range(5, 9)).set_delay(randf_range(0, 3))
		slt.tween_property(sl, "position:y", randf_range(50, 670), randf_range(5, 9))

	# Vignette (dark edges)
	var vig_top = ColorRect.new()
	vig_top.color = Color(0, 0, 0, 0.25)
	vig_top.size = Vector2(1280, 100)
	vig_top.position = Vector2(0, 0)
	vig_top.mouse_filter = Control.MOUSE_FILTER_IGNORE
	env.add_child(vig_top)
	var vig_bot = ColorRect.new()
	vig_bot.color = Color(0, 0, 0, 0.3)
	vig_bot.size = Vector2(1280, 100)
	vig_bot.position = Vector2(0, 620)
	vig_bot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	env.add_child(vig_bot)

func start_sequence() -> void:
	## Main Chapter 1 Sequence 1 — Glitch Crater Awakening
	
	# === PITCH BLACK START with stuttering audio buffer ===
	await transition.transition_out(ScreenTransition.TransitionType.FADE, 0.3)
	if not is_inside_tree(): return
	
	# === CHAPTER TITLE ===
	var title_tween = create_tween()
	title_tween.tween_property(chapter_title, "modulate:a", 1.0, 2.0)
	title_tween.tween_property(subtitle, "modulate:a", 1.0, 1.5)
	await title_tween.finished
	if not is_inside_tree(): return
	await get_tree().create_timer(2.5).timeout
	if not is_inside_tree(): return
	
	# Fade out title
	title_tween = create_tween()
	title_tween.set_parallel(true)
	title_tween.tween_property(chapter_title, "modulate:a", 0.0, 1.0)
	title_tween.tween_property(subtitle, "modulate:a", 0.0, 1.0)
	await title_tween.finished
	if not is_inside_tree(): return
	
	# === INTERNAL SYSTEM MONOLOGUE (Terminal text on black void) ===
	await play_internal_monologue()
	if not is_inside_tree(): return
	
	# === BSOD + SCREEN TEAR ===
	await play_bsod_crash()
	if not is_inside_tree(): return
	
	# === FADE INTO GLITCH CRATER ===
	transition.transition_in(ScreenTransition.TransitionType.FADE, 3.0)
	await transition.transition_finished
	if not is_inside_tree(): return

	# Cinematic letterbox bars
	camera.enable_letterbox(60.0, 0.8)

	# Start ambient particles
	ambient_dust.emitting = true
	
	# === UI BOOT SEQUENCE (diegetic) ===
	await play_ui_boot_sequence()
	if not is_inside_tree(): return
	
	# === STATUS WINDOW ===
	await show_status_window()
	if not is_inside_tree(): return

	# === GLITCH MEMORY COMBAT — Early taste of combat within first 5 min ===
	await _play_glitch_memory_combat()
	if not is_inside_tree(): return
	
	# === PLAY MAIN CUTSCENE (First Dialogue — Soliloquy) ===
	var cutscene = create_awakening_cutscene()
	cutscene_mgr.play_cutscene(cutscene)
	await cutscene_mgr.cutscene_finished
	if not is_inside_tree(): return
	
	if skip_requested:
		transition_to_elara_meeting()
		return
	
	# Transition to meeting Elara
	transition_to_elara_meeting()

# ════════════════════════════════════════════════════════════════════════
# GLITCH MEMORY COMBAT — Early gameplay within the first 5 minutes
# A fragmented memory of combat from Kaelen's past life bleeds through,
# giving the player a brief taste of the Hollow Knight combat system.
# ════════════════════════════════════════════════════════════════════════

var _memory_combat_active: bool = false
var _memory_enemy_hp: float = 40.0
var _memory_enemy_max_hp: float = 40.0
var _memory_player_pos: Vector2 = Vector2(300, 420)
var _memory_enemy_pos: Vector2 = Vector2(900, 420)
var _memory_enemy_node: ColorRect = null
var _memory_player_node: ColorRect = null
var _memory_hp_bar: ProgressBar = null
var _memory_combat_container: Control = null
var _memory_hint_label: Label = null
var _memory_attack_cooldown: float = 0.0
var _memory_parry_active: bool = false
var _memory_parry_timer: float = 0.0
var _memory_enemy_attack_timer: float = 2.5

func _play_glitch_memory_combat() -> void:
	## A fragmented "memory flash" — Kaelen's hands remember combat from a past life.
	## Short, punchy combat tutorial that feels like a glitching dream sequence.
	if skip_requested:
		return

	# Narrative setup
	await DialogueManager.say("Kaelen (Internal)", "My hands are shaking. Not from fear — from RECOGNITION. They remember something my brain doesn't. A fighting stance? When did I ever...", Color(0.5, 0.9, 1.0))
	if not is_inside_tree(): return

	await DialogueManager.say("System", "// MEMORY FRAGMENT DETECTED — Corrupted combat data leaking from consciousness buffer\n// Loading partial combat subroutine...", Color(1.0, 0.6, 0.0), true)
	if not is_inside_tree(): return

	# Screen glitch to transition into memory
	if has_node("/root/GlitchOverlay"):
		GlitchOverlay.flash_glitch(0.5)
	if has_node("/root/SFXManager"):
		SFXManager.play("glitch_trigger")

	DialogueManager.hide_dialogue()
	await get_tree().create_timer(0.5).timeout
	if not is_inside_tree(): return

	# Build the memory combat arena overlay
	_build_memory_arena()

	await DialogueManager.say("System", "// GLITCH MEMORY: A corrupted fragment. Something you once knew.\n// [J] Attack  |  [K] Parry  |  [A/D] Move", Color(0.5, 1.0, 0.5), true)
	if not is_inside_tree(): return

	DialogueManager.hide_dialogue()
	_memory_combat_active = true

	# Wait for combat to finish (enemy defeated or timeout)
	var timeout_timer: float = 30.0
	while _memory_combat_active and timeout_timer > 0:
		await get_tree().create_timer(0.1).timeout
		if not is_inside_tree(): return
		timeout_timer -= 0.1

	_memory_combat_active = false

	# Dramatic end
	if has_node("/root/GlitchOverlay"):
		GlitchOverlay.flash_glitch(0.4)

	await _destroy_memory_arena()
	if not is_inside_tree(): return

	# Post-combat narrative
	if _memory_enemy_hp <= 0:
		await DialogueManager.say("System", "// MEMORY FRAGMENT COMPLETE — Combat reflexes partially restored\n// +25 XP", Color(0.3, 1.0, 0.5), true)
		if not is_inside_tree(): return
		GameManager.add_xp(25)
		await DialogueManager.say("Kaelen (Internal)", "I... destroyed it. My body moved on its own. These reflexes — they're not from my life as a programmer. They're from HERE. From whatever this world is making me into.", Color(0.5, 0.9, 1.0))
		if not is_inside_tree(): return
	else:
		await DialogueManager.say("System", "// MEMORY FRAGMENT TIMED OUT — Combat data incomplete\n// Partial restoration: +10 XP", Color(1.0, 0.8, 0.3), true)
		if not is_inside_tree(): return
		GameManager.add_xp(10)
		await DialogueManager.say("Kaelen (Internal)", "The memory is fading. But my hands still tingle. Whatever that was... I'll need it again.", Color(0.5, 0.9, 1.0))
		if not is_inside_tree(): return

	DialogueManager.hide_dialogue()
	await get_tree().create_timer(0.5).timeout
	if not is_inside_tree(): return

func _build_memory_arena() -> void:
	## Build an overlay combat arena for the memory flash
	_memory_combat_container = Control.new()
	_memory_combat_container.name = "MemoryCombatArena"
	_memory_combat_container.set_anchors_preset(Control.PRESET_FULL_RECT)
	_memory_combat_container.z_index = 20
	add_child(_memory_combat_container)

	# Semi-transparent dark overlay
	var overlay = ColorRect.new()
	overlay.color = Color(0.0, 0.0, 0.05, 0.7)
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_memory_combat_container.add_child(overlay)

	# Glitchy scan lines
	for i in range(15):
		var scanline = ColorRect.new()
		scanline.color = Color(0.2, 0.8, 0.3, 0.05)
		scanline.size = Vector2(1280, 2)
		scanline.position = Vector2(0, i * 48)
		scanline.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_memory_combat_container.add_child(scanline)

	# Ground line
	var ground = ColorRect.new()
	ground.color = Color(0.15, 0.3, 0.15, 0.6)
	ground.size = Vector2(1280, 3)
	ground.position = Vector2(0, 470)
	ground.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_memory_combat_container.add_child(ground)

	# Player (glitchy green silhouette)
	_memory_player_node = ColorRect.new()
	_memory_player_node.color = Color(0.3, 1.0, 0.4, 0.8)
	_memory_player_node.size = Vector2(30, 50)
	_memory_player_node.position = _memory_player_pos
	_memory_combat_container.add_child(_memory_player_node)

	# Enemy (glitchy red corrupted shape)
	_memory_enemy_node = ColorRect.new()
	_memory_enemy_node.color = Color(1.0, 0.2, 0.2, 0.8)
	_memory_enemy_node.size = Vector2(40, 45)
	_memory_enemy_pos = Vector2(900, 425)
	_memory_enemy_node.position = _memory_enemy_pos
	_memory_combat_container.add_child(_memory_enemy_node)

	# Enemy HP bar
	_memory_hp_bar = ProgressBar.new()
	_memory_hp_bar.min_value = 0
	_memory_hp_bar.max_value = _memory_enemy_max_hp
	_memory_hp_bar.value = _memory_enemy_hp
	_memory_hp_bar.position = Vector2(490, 380)
	_memory_hp_bar.size = Vector2(300, 18)
	var bar_style = StyleBoxFlat.new()
	bar_style.bg_color = Color(0.8, 0.2, 0.2)
	_memory_hp_bar.add_theme_stylebox_override("fill", bar_style)
	var bar_bg = StyleBoxFlat.new()
	bar_bg.bg_color = Color(0.15, 0.05, 0.05)
	_memory_hp_bar.add_theme_stylebox_override("background", bar_bg)
	_memory_combat_container.add_child(_memory_hp_bar)

	# Enemy name label
	var enemy_label = Label.new()
	enemy_label.text = "CORRUPTED MEMORY FRAGMENT"
	enemy_label.add_theme_font_size_override("font_size", 12)
	enemy_label.add_theme_color_override("font_color", Color(1.0, 0.4, 0.4))
	enemy_label.position = Vector2(490, 400)
	_memory_combat_container.add_child(enemy_label)

	# Controls hint
	_memory_hint_label = Label.new()
	_memory_hint_label.text = "[J] Attack  |  [K] Parry  |  [A/D] Move"
	_memory_hint_label.add_theme_font_size_override("font_size", 14)
	_memory_hint_label.add_theme_color_override("font_color", Color(0.6, 0.9, 0.6, 0.7))
	_memory_hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_memory_hint_label.position = Vector2(400, 510)
	_memory_combat_container.add_child(_memory_hint_label)

	# Pulsing enemy glow
	var enemy_pulse = create_tween().set_loops()
	_ambient_tweens.append(enemy_pulse)
	enemy_pulse.tween_property(_memory_enemy_node, "modulate:a", 0.5, 0.8).set_trans(Tween.TRANS_SINE)
	enemy_pulse.tween_property(_memory_enemy_node, "modulate:a", 1.0, 0.8).set_trans(Tween.TRANS_SINE)

	# Reset combat state
	_memory_enemy_hp = _memory_enemy_max_hp
	_memory_player_pos = Vector2(300, 420)

func _process(delta: float) -> void:
	## Process the memory combat each frame
	if not _memory_combat_active:
		return

	_memory_attack_cooldown -= delta
	_memory_enemy_attack_timer -= delta

	# Parry window
	if _memory_parry_active:
		_memory_parry_timer -= delta
		if _memory_parry_timer <= 0:
			_memory_parry_active = false
			if is_instance_valid(_memory_player_node):
				_memory_player_node.color = Color(0.3, 1.0, 0.4, 0.8)

	# Player movement
	var move_dir: float = 0.0
	if Input.is_action_pressed("move_left"):
		move_dir = -1.0
	elif Input.is_action_pressed("move_right"):
		move_dir = 1.0
	_memory_player_pos.x += move_dir * 250.0 * delta
	_memory_player_pos.x = clampf(_memory_player_pos.x, 50, 1180)
	if is_instance_valid(_memory_player_node):
		_memory_player_node.position = _memory_player_pos

	# Enemy AI — simple approach and attack
	if is_instance_valid(_memory_enemy_node):
		var dir_to_player = sign(_memory_player_pos.x - _memory_enemy_pos.x)
		_memory_enemy_pos.x += dir_to_player * 80.0 * delta
		_memory_enemy_node.position = _memory_enemy_pos

	# Enemy attack
	if _memory_enemy_attack_timer <= 0:
		_memory_enemy_attack_timer = randf_range(2.0, 3.5)
		var dist = abs(_memory_player_pos.x - _memory_enemy_pos.x)
		if dist < 120:
			if _memory_parry_active:
				# Parried!
				_memory_enemy_hp -= 15.0
				_update_memory_hp_bar()
				if has_node("/root/SFXManager"):
					SFXManager.play("parry_perfect")
				_flash_memory_enemy(Color(1.0, 1.0, 0.3))
				_show_memory_text("PARRIED! -15", Color(1.0, 1.0, 0.3))
			else:
				# Hit player
				if has_node("/root/SFXManager"):
					SFXManager.play("player_hurt")
				_flash_memory_player(Color(1.0, 0.2, 0.2))
				_show_memory_text("HIT! Stay alert!", Color(1.0, 0.3, 0.3))

	# Check victory
	if _memory_enemy_hp <= 0:
		_memory_combat_active = false
		if is_instance_valid(_memory_enemy_node):
			_memory_enemy_node.color = Color(1.0, 1.0, 1.0, 0.5)
		if has_node("/root/SFXManager"):
			SFXManager.play("enemy_death")
		_show_memory_text("MEMORY FRAGMENT DESTROYED!", Color(0.3, 1.0, 0.5))

func _input(event: InputEvent) -> void:
	## Handle both cinematic skip and memory combat input
	if _memory_combat_active:
		if event.is_action_pressed("attack") and _memory_attack_cooldown <= 0:
			_memory_attack_cooldown = 0.4
			var dist = abs(_memory_player_pos.x - _memory_enemy_pos.x)
			if dist < 100:
				var damage: float = randf_range(8.0, 14.0)
				_memory_enemy_hp -= damage
				_update_memory_hp_bar()
				if has_node("/root/SFXManager"):
					SFXManager.play("sword_swing")
				_flash_memory_enemy(Color(1.0, 1.0, 1.0))
				_show_memory_text("-%d" % int(damage), Color(1.0, 0.9, 0.3))
			else:
				_show_memory_text("Too far! Get closer.", Color(0.7, 0.7, 0.7))
		elif event.is_action_pressed("defend") and not _memory_parry_active:
			_memory_parry_active = true
			_memory_parry_timer = 0.3
			if is_instance_valid(_memory_player_node):
				_memory_player_node.color = Color(0.3, 0.5, 1.0, 0.9)
			if has_node("/root/SFXManager"):
				SFXManager.play("parry")
		return

	if not cinematic_active:
		return
	if event.is_action_pressed("ui_accept"):
		pass  # Dialogue advancement handled by cutscene_mgr

func _update_memory_hp_bar() -> void:
	if is_instance_valid(_memory_hp_bar):
		_memory_hp_bar.value = max(_memory_enemy_hp, 0)

func _flash_memory_enemy(color: Color) -> void:
	if not is_instance_valid(_memory_enemy_node):
		return
	_memory_enemy_node.color = color
	var tw = create_tween()
	tw.tween_property(_memory_enemy_node, "color", Color(1.0, 0.2, 0.2, 0.8), 0.2)

func _flash_memory_player(color: Color) -> void:
	if not is_instance_valid(_memory_player_node):
		return
	_memory_player_node.color = color
	var tw = create_tween()
	tw.tween_property(_memory_player_node, "color", Color(0.3, 1.0, 0.4, 0.8), 0.2)

func _show_memory_text(text: String, color: Color) -> void:
	if not is_instance_valid(_memory_combat_container):
		return
	var lbl = Label.new()
	lbl.text = text
	lbl.add_theme_font_size_override("font_size", 16)
	lbl.add_theme_color_override("font_color", color)
	lbl.position = Vector2(_memory_enemy_pos.x - 30, _memory_enemy_pos.y - 40)
	lbl.z_index = 25
	_memory_combat_container.add_child(lbl)
	var tw = create_tween()
	tw.tween_property(lbl, "position:y", lbl.position.y - 50, 0.8)
	tw.parallel().tween_property(lbl, "modulate:a", 0.0, 0.8)
	tw.tween_callback(lbl.queue_free)

func _destroy_memory_arena() -> void:
	if is_instance_valid(_memory_combat_container):
		var tw = create_tween()
		tw.tween_property(_memory_combat_container, "modulate:a", 0.0, 0.8)
		await tw.finished
		if not is_inside_tree(): return
		_memory_combat_container.queue_free()
		_memory_combat_container = null

func play_internal_monologue() -> void:
	## Kaelen's terminal text monologue before impact — Courier New CRT style
	boot_text.visible = true
	boot_text.text = ""
	
	var monologue_lines = [
		{
			"text": "> Something's wrong. I'm falling.",
			"delay": 1.5,
			"color": Color(0.5, 1.0, 0.5)
		},
		{
			"text": "> The air isn't right. Resistance is... nothing. Like gravity forgot how to work.",
			"delay": 2.0,
			"color": Color(0.5, 1.0, 0.5)
		},
		{
			"text": "> The world is breaking apart around me.",
			"delay": 1.5,
			"color": Color(1.0, 1.0, 0.3)
		},
		{
			"text": "> Impact in 3... 2... 1...",
			"delay": 2.0,
			"color": Color(1.0, 0.3, 0.3)
		},
		{
			"text": "> [CRITICAL ERROR — CONSCIOUSNESS INTERRUPTED]",
			"delay": 1.5,
			"color": Color(1.0, 0.0, 0.0)
		}
	]
	
	for line in monologue_lines:
		if skip_requested:
			break
		await typewrite_text(boot_text, line["text"], line["color"], 0.04)
		if not is_inside_tree(): return
		boot_text.text += "\n"
		await get_tree().create_timer(line["delay"]).timeout
		if not is_inside_tree(): return
	
	boot_text.visible = false

func play_bsod_crash() -> void:
	## Blue Screen of Death visual artifact with horizontal screen tear
	# Flash to blue (BSOD)
	flash_overlay.color = Color(0.0, 0.0, 0.8, 1.0)
	flash_overlay.modulate.a = 1.0
	
	# Show BSOD text
	boot_text.visible = true
	boot_text.text = ""
	boot_text.add_theme_color_override("font_color", Color.WHITE)
	boot_text.text = "SYSTEM_CRASH_DUMP\n\n*** STOP: 0x0000007E\n\nREALITY.DLL - Address 0x004F3A\n\nBeginning dump of physical memory...\nPhysical memory dump complete.\n\nContact your System Administrator."
	
	await get_tree().create_timer(2.0).timeout
	if not is_inside_tree(): return
	
	# Screen tear effect — rapid horizontal glitch flashes
	for i in range(8):
		glitch_overlay.visible = true
		glitch_overlay.color = Color(randf(), randf(), randf(), 0.7)
		await get_tree().create_timer(0.05).timeout
		if not is_inside_tree(): return
		glitch_overlay.visible = false
		await get_tree().create_timer(0.03).timeout
		if not is_inside_tree(): return
	
	# Absolute silence — snap to black
	flash_overlay.color = Color.BLACK
	boot_text.visible = false
	glitch_overlay.visible = false
	
	await get_tree().create_timer(2.0).timeout
	if not is_inside_tree(): return

func play_ui_boot_sequence() -> void:
	## Diegetic UI boot sequence — compiles line by line in top-left
	boot_text.visible = true
	boot_text.text = ""
	boot_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	boot_text.position = Vector2(30, 30)
	
	var boot_lines = [
		{"text": "> Loading 'Isekai_Protocol.exe'...", "delay": 1.0, "color": Color(0.5, 1.0, 0.5)},
		{"text": "> Asset integrity: 42%. Corrupted sectors detected.", "delay": 1.2, "color": Color(1.0, 1.0, 0.3)},
		{"text": ">... initializing HUD...", "delay": 0.8, "color": Color(0.5, 1.0, 0.5)},
		{"text": "> Optical_Sensors... [OK]", "delay": 0.6, "color": Color(0.0, 1.0, 0.0)},
		{"text": "> Physics_Interaction... [PARTIAL]", "delay": 0.6, "color": Color(1.0, 1.0, 0.3)},
		{"text": "> Magic_System... [CORRUPTED]", "delay": 0.8, "color": Color(1.0, 0.3, 0.3)},
		{"text": "> Root_Access... [ENABLED — WARNING: UNAUTHORIZED]", "delay": 1.5, "color": Color(1.0, 0.0, 1.0)},
	]
	
	for line in boot_lines:
		if skip_requested:
			break
		await typewrite_text(boot_text, line["text"], line["color"], 0.03)
		if not is_inside_tree(): return
		boot_text.text += "\n"
		await get_tree().create_timer(line["delay"]).timeout
		if not is_inside_tree(): return
	
	# Brief pause then fade out boot text
	await get_tree().create_timer(1.5).timeout
	if not is_inside_tree(): return
	var tween = create_tween()
	tween.tween_property(boot_text, "modulate:a", 0.0, 1.0)
	await tween.finished
	if not is_inside_tree(): return
	boot_text.visible = false
	boot_text.modulate.a = 1.0

func show_status_window() -> void:
	## Show the IDE-style Status Window that mimics a code editor
	status_window.visible = true
	status_window.modulate.a = 0.0
	
	# Set the status content
	var status_content = status_window.get_node_or_null("MarginContainer/VBox/Content")
	if status_content:
		status_content.text = "╔══════════════════════════════════════════════╗\n"
		status_content.text += "║  PARAMETER     │ VALUE            │ TYPE     ║\n"
		status_content.text += "╠══════════════════════════════════════════════╣\n"
		status_content.text += "║  IDENTITY      │ Admin_Guest      │ User     ║\n"
		status_content.text += "║  HP (INTEGRITY) │ 84%              │ Float    ║\n"
		status_content.text += "║  RAM (MANA)    │ 12GB / 16GB      │ Int      ║\n"
		status_content.text += "║  CORRUPTION    │ 0.05%            │ Float    ║\n"
		status_content.text += "║  LOCATION      │ Map_ID_01        │ String   ║\n"
		status_content.text += "╚══════════════════════════════════════════════╝"
	
	# Snap in with a digital effect
	var tween = create_tween()
	tween.tween_property(status_window, "modulate:a", 1.0, 0.3)
	await tween.finished
	if not is_inside_tree(): return
	
	# Camera shake on snap
	camera.shake(5.0, 0.3)
	
	await get_tree().create_timer(4.0).timeout
	if not is_inside_tree(): return
	
	# Fade out status window
	tween = create_tween()
	tween.tween_property(status_window, "modulate:a", 0.0, 1.5)
	await tween.finished
	if not is_inside_tree(): return
	status_window.visible = false

func create_awakening_cutscene() -> Dictionary:
	## Cutscene beats for Kaelen's awakening — expanded with full soliloquy
	return {
		"name": "Chapter 1 - Glitch Crater Awakening",
		"beats": [
			# Beat 1: Wide shot of the crater — voxelated terrain, floating trees
			{
				"type": "camera_move",
				"target": Vector2(640, 400),
				"duration": 0.5
			},
			{
				"type": "camera_zoom",
				"zoom": Vector2(0.8, 0.8),
				"duration": 2.0
			},
			{
				"type": "wait",
				"duration": 1.5
			},
			
			# Beat 2: Kaelen sits up in the crater center
			{
				"type": "character_enter",
				"character": "Kaelen",
				"position": Vector2(640, 420),
				"from": "bottom",
				"duration": 2.5
			},
			
			# Beat 3: Camera pushes in on Kaelen
			{
				"type": "camera_zoom",
				"zoom": Vector2(1.2, 1.2),
				"duration": 2.0
			},
			
			# Beat 4: First line — disorientation
			{
				"type": "dialogue",
				"speaker": "Kaelen (Internal)",
				"text": "...My head. Feels like someone scooped out my brain, shook it, and put it back in sideways.",
				"auto_advance": false
			},
			
			# Beat 5: Looks around
			{
				"type": "dialogue",
				"speaker": "Kaelen (Internal)",
				"text": "Grass. Trees. Sky. The air smells like... ozone and wildflowers? That can't be right. I was on a plane. Flight 707. Tokyo to San Francisco.",
				"auto_advance": false
			},
			
			# Beat 5b: Physical reality check
			{
				"type": "dialogue",
				"speaker": "Kaelen (Internal)",
				"text": "I try to stand. My legs buckle immediately. My body feels wrong — lighter somehow, like I weigh less than I should. I hit the grass hard, palms first. It's wet. Cold. Real.",
				"auto_advance": false
			},
			
			# Beat 5c: Denial
			{
				"type": "dialogue",
				"speaker": "Kaelen (Internal)",
				"text": "This is a dream. Obviously. Hypoxia from cabin depressurization, or my brain misfiring in the milliseconds before impact. The mind constructs elaborate scenarios to shield itself from death. I read that somewhere.",
				"auto_advance": false
			},
			
			# Beat 5d: Testing the theory
			{
				"type": "dialogue",
				"speaker": "Kaelen",
				"text": "*He bites the inside of his cheek. Hard. The taste of copper floods his mouth. The pain is sharp and immediate and absolutely, undeniably real.*",
				"auto_advance": true,
				"duration": 3.0
			},
			
			# Beat 5e: The denial cracks
			{
				"type": "dialogue",
				"speaker": "Kaelen (Internal)",
				"text": "...Not a dream. Dreams don't hurt like this. I can feel individual blades of grass between my fingers. I can smell dirt and something sweet and chemical, like overheated electronics.",
				"auto_advance": false
			},
			
			# Beat 5f: Panic rising
			{
				"type": "dialogue",
				"speaker": "Kaelen (Internal)",
				"text": "The plane. The passengers. The sky TEARING ITSELF APART. The screens glitching. System errors everywhere. A blinding white flash. That wasn't a dream either. So where am I? What happened to me?",
				"auto_advance": false
			},
			
			# Beat 5g: The coping mechanism engages
			{
				"type": "dialogue",
				"speaker": "Kaelen (Internal)",
				"text": "Breathe, Kaelen. Catalogue. When you can't understand something, reduce it to components. That's what you do. That's what you've ALWAYS done. So do it now, before the panic swallows you.",
				"auto_advance": false
			},
			
			# Kaelen collecting himself — silent beat
			{
				"type": "wait",
				"duration": 2.0
			},
			
			# Beat 6: Camera pans to show floating tree
			{
				"type": "parallel",
				"beats": [
					{
						"type": "camera_move",
						"target": Vector2(800, 300),
						"duration": 2.0
					},
					{
						"type": "camera_zoom",
						"zoom": Vector2(1.0, 1.0),
						"duration": 2.0
					}
				]
			},
			
			# Beat 7: The defining analytical observation
			{
				"type": "dialogue",
				"speaker": "Kaelen",
				"text": "The ground doesn't line up. Look — there's a gap between the hillside and the path, like someone built them separately and just pushed them together without checking if they fit.",
				"auto_advance": false
			},
			
			# Beat 8: More environment analysis
			{
				"type": "dialogue",
				"speaker": "Kaelen (Internal)",
				"text": "That tree. It's floating three meters off the ground. And its shadow falls the wrong way — the shadow points east while the sun is in the west. Like two different people built the tree and the lighting and never talked to each other.",
				"auto_advance": false
			},
			
			# Beat 9: Kaelen taps the air
			{
				"type": "dialogue",
				"speaker": "Kaelen",
				"text": "*He reaches out and taps the invisible boundary around the floating tree. His hand stops against nothing — an invisible collision box.*",
				"auto_advance": true,
				"duration": 2.5
			},
			
			# Beat 10: Deeper observation
			{
				"type": "dialogue",
				"speaker": "Kaelen",
				"text": "An invisible wall. My hand stops against thin air. The tree isn't floating — the ground just doesn't reach it. Like whoever made this place forgot to connect the pieces.",
				"auto_advance": false
			},
			
			# Beat 11: The water paradox
			{
				"type": "dialogue",
				"speaker": "Kaelen (Internal)",
				"text": "And there — that stream. It's flowing UPHILL. Water doesn't do that. Not in any world that makes sense. Nobody checked this. Nobody tested any of this.",
				"auto_advance": false
			},
			
			# Beat 12: Camera returns to Kaelen
			{
				"type": "parallel",
				"beats": [
					{
						"type": "camera_move",
						"target": Vector2(640, 400),
						"duration": 1.5
					},
					{
						"type": "camera_zoom",
						"zoom": Vector2(1.3, 1.3),
						"duration": 1.5
					}
				]
			},
			
			# Beat 13: No magic circles
			{
				"type": "dialogue",
				"speaker": "Kaelen",
				"text": "No magic circles. No deities descending from the clouds. No mysterious old man with a quest scroll.",
				"auto_advance": false
			},
			
			# Beat 14: The thesis statement
			{
				"type": "dialogue",
				"speaker": "Kaelen",
				"text": "Just a half-finished world that someone built in a hurry and never bothered to polish.",
				"auto_advance": false
			},
			
			# Beat 15: THE defining line
			{
				"type": "dialogue",
				"speaker": "Kaelen",
				"text": "I'm not in a fantasy world. I'm inside a broken machine.",
				"auto_advance": false
			},
			
			# Let the thesis statement land
			{
				"type": "camera_zoom",
				"zoom": Vector2(1.5, 1.5),
				"duration": 1.5
			},
			{
				"type": "wait",
				"duration": 2.0
			},
			
			# Beat 16: Quick glitch flash
			{
				"type": "effect",
				"effect": "glitch_screen",
				"duration": 0.4
			},
			
			# Beat 17: Body check
			{
				"type": "dialogue",
				"speaker": "Kaelen (Internal)",
				"text": "I check my hands. Five fingers on each — good, at least my body seems complete. I'm wearing clothes I don't recognize. Some kind of generic adventurer outfit. Leather and cloth. Like someone dressed me for a role I didn't audition for.",
				"auto_advance": false
			},
			
			# Beat 18: The analytical acceptance
			{
				"type": "dialogue",
				"speaker": "Kaelen (Internal)",
				"text": "The plane. Flight 707. I remember the turbulence. I remember the screens flickering. I remember system error messages flooding my vision and then... nothing but white.",
				"auto_advance": false
			},
			
			# Beat 19: Connection to the project
			{
				"type": "dialogue",
				"speaker": "Kaelen (Internal)",
				"text": "AetherCorp's Project Aethelgard. The one I spent three years building. The one with the anomalous code patterns. I'm INSIDE it.",
				"auto_advance": false
			},
			
			# Beat 19b: The weight of that realization
			{
				"type": "dialogue",
				"speaker": "Kaelen (Internal)",
				"text": "Which means the plane... the other passengers... Mira, the kid with the GameBoy, the businessman with his spreadsheets... What happened to them? Are they here too? Are they ALIVE?",
				"auto_advance": false
			},
			
			# Beat 19c: Grief breaking through
			{
				"type": "dialogue",
				"speaker": "Kaelen (Internal)",
				"text": "Am I dead? Is this what death looks like for someone who spent their whole life staring at screens \u2014 an eternity trapped inside one?",
				"auto_advance": false
			},
			
			# Let existential dread settle — camera pulls back
			{
				"type": "camera_zoom",
				"zoom": Vector2(0.7, 0.7),
				"duration": 2.5
			},
			{
				"type": "wait",
				"duration": 1.5
			},
			
			# Beat 19d: The silence
			{
				"type": "dialogue",
				"speaker": "Kaelen",
				"text": "*He sits in the grass for a long time. The stream gurgles uphill. A bird sings the same four notes over and over, never changing. He lets the weight of it all settle on his shoulders.*",
				"auto_advance": true,
				"duration": 4.5
			},
			
			# Beat 19e: Choosing to move forward
			{
				"type": "dialogue",
				"speaker": "Kaelen (Internal)",
				"text": "I can't fall apart here. If there's even a chance those people are somewhere in this system \u2014 if there's even a chance this ISN'T death \u2014 then sitting in a crater feeling sorry for myself helps no one. Least of all me.",
				"auto_advance": false
			},
			
			# Resolve solidifying — camera pushes in
			{
				"type": "camera_zoom",
				"zoom": Vector2(1.2, 1.2),
				"duration": 1.5
			},
			{
				"type": "wait",
				"duration": 1.5
			},
			
			# Beat 20: Practical assessment — EARNED now
			{
				"type": "dialogue",
				"speaker": "Kaelen",
				"text": "Alright. Think. If I'm inside some kind of constructed world, there are rules. Patterns. Weaknesses I can find and use. I need to find a way out. And if there are other survivors... I need to find them first.",
				"auto_advance": false
			},
			
			# Beat 21: Camera pulls back to wide shot
			{
				"type": "camera_zoom",
				"zoom": Vector2(0.9, 0.9),
				"duration": 2.0
			},
			
			# Golden path appears in the environment
			{
				"type": "effect",
				"effect": "show_golden_path",
				"duration": 1.5
			},

			# Beat 22: System message — objective
			{
				"type": "dialogue",
				"speaker": "System",
				"text": "[LOCATION: SECTOR_0 — CRASH_SITE]\n[USER STATUS: Disoriented but functional]\n[ROOT ACCESS: Detected — Level 1]\n[OBJECTIVE: EXIT CRATER. FOLLOW GOLDEN_PATH.]",
				"auto_advance": true,
				"duration": 4.0
			},
			
			# Beat 23: Kaelen notices the golden path
			{
				"type": "dialogue",
				"speaker": "Kaelen (Internal)",
				"text": "A golden path. A literal glowing trail on the ground, leading somewhere. Could it be more obvious? Whoever built this world really wants me to go this way.",
				"auto_advance": false
			},
			
			# Beat 24: Final beat — he starts walking
			{
				"type": "dialogue",
				"speaker": "Kaelen",
				"text": "Fine. Let's follow the glowing breadcrumbs and see where this world wants me to go.",
				"auto_advance": false
			},
		]
	}

func typewrite_text(label: Label, text: String, color: Color, speed: float = 0.03) -> void:
	## Typewriter effect for terminal-style text
	label.add_theme_color_override("font_color", color)
	var current = label.text
	for i in range(text.length()):
		if skip_requested:
			label.text = current + text
			return
		label.text = current + text.substr(0, i + 1)
		await get_tree().create_timer(speed).timeout
		if not is_inside_tree(): return

func transition_to_elara_meeting() -> void:
	## After awakening, transition to the open-world overworld near Oakhaven
	if _is_transitioning:
		return
	_is_transitioning = true
	print("[CH1] Transitioning to Open World")

	DialogueManager.hide_dialogue()
	camera.disable_letterbox(0.4)
	await transition.transition_out(ScreenTransition.TransitionType.GLITCH, 1.5)
	if not is_inside_tree(): return

	GameManager.set_story_flag("ch1_awakening_complete", true)
	GameManager.set_story_flag("ch1_glitch_crater_complete", true)
	GameManager.current_chapter = 1
	GameManager.current_region = ""
	GameManager.player_overworld_position = Vector2(400, 400)  # Near Oakhaven gate
	GameManager.change_state(GameManager.GameState.EXPLORATION)
	await get_tree().create_timer(0.3).timeout
	if not is_inside_tree(): return
	
	SceneTransitions.change_scene("res://scenes/overworld/overworld.tscn")

func _on_custom_effect(effect_name: String, parameters: Dictionary) -> void:
	## Handle custom cutscene effects
	match effect_name:
		"glitch_screen":
			# Play glitch surge SFX during glitch events
			if has_node("/root/SFXManager"):
				SFXManager.play("glitch_surge")
			glitch_overlay.visible = true
			glitch_overlay.color = Color(0.5, 1.0, 0.5, 0.4)
			await get_tree().create_timer(parameters.get("duration", 0.3)).timeout
			if not is_inside_tree(): return
			glitch_overlay.visible = false
		"show_golden_path":
			var gp = get_node_or_null("Environment/GoldenPathHint")
			if gp:
				var gp_tween = create_tween()
				gp_tween.tween_property(gp, "color", Color(1.0, 0.85, 0.2, 0.35), 1.5)
				var gp_pulse = create_tween().set_loops()
				_ambient_tweens.append(gp_pulse)
				gp_pulse.tween_property(gp, "modulate:a", 0.5, 2.0).set_trans(Tween.TRANS_SINE).set_delay(1.5)
				gp_pulse.tween_property(gp, "modulate:a", 1.0, 2.0).set_trans(Tween.TRANS_SINE)
			await get_tree().create_timer(parameters.get("duration", 1.5)).timeout
			if not is_inside_tree(): return
		_:
			print("[CH1 CUSTOM EFFECT] Unhandled: %s" % effect_name)

# _input and _on_skip_pressed handled by the memory combat _input above