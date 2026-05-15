extends Control

@onready var glitch_effect = $GlitchEffect
@onready var corruption_label = $CenterContainer/VBox/CorruptionLabel

var glitch_timer: float = 0.0
# Shake container — we reparent children into this so shaking doesn't fight anchors
var _shake_container: Control = null

func _ready() -> void:
	# Build a shake container so screen shake doesn't conflict with Control anchors
	_setup_shake_container()

	# Play game over music
	if has_node("/root/MusicManager"):
		MusicManager.play_track("game_over")
	# Pass 53: Play death stinger SFX on game over screen entry
	if has_node("/root/SFXManager"):
		SFXManager.play("player_death")

	# Display final corruption level
	var _glitch = GameManager.glitch_meter if has_node("/root/GameManager") else 0.0
	if corruption_label:
		corruption_label.text = "Final Corruption Level: %d%%" % int(_glitch)

	# If corruption < 100%, this is a revival screen, not a game over
	if _glitch < 100.0:
		_auto_revive()
	else:
		animate_glitch()

func _setup_shake_container() -> void:
	## Wrap existing children in a container that can be offset without fighting anchors.
	_shake_container = Control.new()
	_shake_container.name = "ShakeContainer"
	_shake_container.set_anchors_preset(Control.PRESET_FULL_RECT)
	_shake_container.mouse_filter = Control.MOUSE_FILTER_IGNORE

	# Move all existing children into the shake container
	var children_to_move: Array[Node] = []
	for child in get_children():
		children_to_move.append(child)
	for child in children_to_move:
		remove_child(child)
		_shake_container.add_child(child)
	add_child(_shake_container)

	# Re-bind @onready references since they moved
	glitch_effect = _shake_container.get_node_or_null("GlitchEffect")
	corruption_label = _shake_container.get_node_or_null("CenterContainer/VBox/CorruptionLabel")

func _auto_revive() -> void:
	## Auto-revive at last village with corruption penalty (already applied by player_combat)
	var _gm = has_node("/root/GameManager")
	var _glitch = GameManager.glitch_meter if _gm else 0.0
	if corruption_label:
		corruption_label.text = "SYSTEM RESTORING... Corruption: %d%%" % int(_glitch)

	await get_tree().create_timer(2.0).timeout
	if not is_inside_tree(): return

	# Restore HP to 50%
	if _gm:
		GameManager.player_stats["hp"] = int(GameManager.player_stats.get("max_hp", 100) * 0.5)

	# Use centralized revival scene helper — SceneTransitions handles the fade
	var revival_scene = GameManager.get_revival_scene() if _gm else "res://scenes/main_menu.tscn"
	if has_node("/root/SceneTransitions"):
		SceneTransitions.change_scene(revival_scene, SceneTransitions.TransitionStyle.FLASH_WHITE)
	else:
		get_tree().change_scene_to_file(revival_scene)

func animate_glitch() -> void:
	if glitch_effect:
		var tween = create_tween().set_loops()
		tween.tween_property(glitch_effect, "color:a", 0.5, 0.1)
		tween.tween_property(glitch_effect, "color:a", 0.1, 0.1)

	# Show button prompts after a delay
	await get_tree().create_timer(2.0).timeout
	if not is_inside_tree(): return
	_build_game_over_options()

func _build_game_over_options() -> void:
	## Add visible button prompts to the game over screen
	var options_vbox = VBoxContainer.new()
	options_vbox.name = "OptionsContainer"
	options_vbox.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	options_vbox.offset_top = -120
	options_vbox.offset_bottom = -30
	options_vbox.offset_left = -200
	options_vbox.offset_right = 200
	options_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	options_vbox.add_theme_constant_override("separation", 12)

	var title_lbl = Label.new()
	title_lbl.text = "FATAL ERROR — SYSTEM FAILURE"
	title_lbl.add_theme_font_size_override("font_size", 14)
	title_lbl.add_theme_color_override("font_color", Color(1.0, 0.2, 0.2, 0.9))
	title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	options_vbox.add_child(title_lbl)

	# Load Last Save button
	var load_btn = Button.new()
	load_btn.text = "Load Last Save"
	load_btn.custom_minimum_size = Vector2(240, 40)
	load_btn.add_theme_font_size_override("font_size", 16)
	load_btn.pressed.connect(func():
		var auto_data = GameManager.get_save_info(GameManager.AUTOSAVE_SLOT)
		if auto_data.get("exists", false):
			await GameManager.load_game(GameManager.AUTOSAVE_SLOT)
		else:
			# No autosave — try slot 1, then slot 0
			for fallback_slot in [1, 0]:
				var slot_info = GameManager.get_save_info(fallback_slot)
				if slot_info.get("exists", false):
					await GameManager.load_game(fallback_slot)
					return
			# No saves found at all — reset and go to menu
			GameManager.reset_game()
			if has_node("/root/SceneTransitions"):
				SceneTransitions.change_scene("res://scenes/main_menu.tscn")
			else:
				get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
	)
	options_vbox.add_child(load_btn)

	# Return to Menu button
	var menu_btn = Button.new()
	menu_btn.text = "Return to Main Menu"
	menu_btn.custom_minimum_size = Vector2(240, 40)
	menu_btn.add_theme_font_size_override("font_size", 16)
	menu_btn.pressed.connect(func():
		if has_node("/root/GameManager"):
			GameManager.reset_game()
		if has_node("/root/SceneTransitions"):
			SceneTransitions.change_scene("res://scenes/main_menu.tscn")
		else:
			get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
	)
	options_vbox.add_child(menu_btn)

	# Quit button
	var quit_btn = Button.new()
	quit_btn.text = "Quit Game"
	quit_btn.custom_minimum_size = Vector2(240, 40)
	quit_btn.add_theme_font_size_override("font_size", 14)
	quit_btn.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
	quit_btn.pressed.connect(func(): get_tree().quit())
	options_vbox.add_child(quit_btn)

	# Fade in
	options_vbox.modulate.a = 0.0
	if _shake_container:
		_shake_container.add_child(options_vbox)
	else:
		add_child(options_vbox)
	var fade_tw = create_tween()
	fade_tw.tween_property(options_vbox, "modulate:a", 1.0, 0.6)
	fade_tw.tween_callback(func(): load_btn.grab_focus())

func _input(event) -> void:
	# Only allow manual input if corruption is at 100% (true game over)
	var _glitch = GameManager.glitch_meter if has_node("/root/GameManager") else 100.0
	if _glitch < 100.0:
		return

	# ui_accept is handled by button focus system — don't bypass buttons
	if event.is_action_pressed("ui_cancel"):
		print("[GAME OVER] Quitting game")
		get_tree().quit()
		get_viewport().set_input_as_handled()

func _process(delta) -> void:
	# Only shake during true game over (corruption at 100%)
	var _glitch = GameManager.glitch_meter if has_node("/root/GameManager") else 0.0
	if _glitch < 100.0:
		return

	glitch_timer += delta

	# Random screen shake via the shake container — never touches Control anchors
	if glitch_timer >= 0.1:
		glitch_timer = 0.0
		if _shake_container:
			var shake_offset = Vector2(randf_range(-5, 5), randf_range(-5, 5))
			_shake_container.position = shake_offset
