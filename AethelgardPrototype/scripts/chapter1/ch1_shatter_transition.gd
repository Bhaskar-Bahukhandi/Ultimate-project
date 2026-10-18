extends Control

## Chapter 1: The Null Pointer Exception
## Sequence 6: The Transition — The Shatter
## Demonstrates the "Hybrid Engine" genre shift from Top-Down to Side-Scrolling
## Uses glass-shattering voronoi fracture visual metaphor

@onready var camera: CinematicCamera = $CinematicCamera
@onready var cutscene_mgr: CutsceneManager = $CutsceneManager
@onready var characters_layer = $CharactersLayer
@onready var transition = $ScreenTransition
@onready var dialogue_box = $UILayer/DialogueBox
@onready var glitch_overlay = $EffectsLayer/GlitchOverlay
@onready var flash_overlay = $EffectsLayer/FlashOverlay
@onready var shatter_effect = $EffectsLayer/ShatterEffect
@onready var chapter_title = $UILayer/ChapterTitle
@onready var subtitle = $UILayer/Subtitle
@onready var chapter_end_card = $UILayer/ChapterEndCard
@onready var end_card_text = $UILayer/ChapterEndCard/VBox/EndText

var cinematic_active = true

func _ready() -> void:
	print("[CH1-SHATTER] Initializing The Shatter transition")
	GameManager.change_state(GameManager.GameState.PROLOGUE)
	
	# Generate procedural background
	BackgroundManager.create_background("shatter_bridge", self)
	
	cutscene_mgr.camera = camera
	cutscene_mgr.dialogue_box = dialogue_box
	cutscene_mgr.characters_container = characters_layer
	cutscene_mgr.custom_effect.connect(_on_custom_effect)
	
	camera.smooth_enabled = true
	camera.smooth_speed = 3.0
	camera.make_current()
	
	# Hide everything initially
	dialogue_box.visible = false
	if shatter_effect:
		shatter_effect.visible = false
	chapter_title.modulate.a = 0.0
	subtitle.modulate.a = 0.0
	if chapter_end_card:
		chapter_end_card.visible = false
	
	await get_tree().create_timer(0.3, false).timeout
	if not is_inside_tree(): return
	transition.transition_in(ScreenTransition.TransitionType.FADE, 1.0)
	await transition.transition_finished
	if not is_inside_tree(): return
	
	await start_shatter_sequence()
	if not is_inside_tree(): return

func start_shatter_sequence() -> void:
	## Full Shatter transition sequence
	
	# (cinematic_active turns false when the player holds to skip; stop here then)
	# Part 1: Kaelen steps onto the bridge
	await play_bridge_approach()
	if not is_inside_tree() or not cinematic_active: return
	
	# Part 2: Environmental shift begins
	await play_environmental_shift()
	if not is_inside_tree() or not cinematic_active: return
	
	# Part 3: THE SHATTER — glass breaking effect
	await play_the_shatter()
	if not is_inside_tree() or not cinematic_active: return
	
	# Let the world reconstruction sink in
	await get_tree().create_timer(2.5, false).timeout
	if not is_inside_tree() or not cinematic_active: return
	
	# Part 4: Kaelen's dialogue
	await play_post_shatter_dialogue()
	if not is_inside_tree() or not cinematic_active: return
	
	# Let Chapter 1's themes settle before end card
	await get_tree().create_timer(3.0, false).timeout
	if not is_inside_tree() or not cinematic_active: return
	
	# Part 5: Chapter 1 End Card
	await play_chapter_end_card()
	if not is_inside_tree(): return

## Every spoken line of this scene is in dialogue/ch1/shatter.dlg (nodes bridge, shift,
## reconstruct, start). The scene stages the camera, the characters and the colour drain,
## and answers the file's `do` events in _on_dlg_event().
const SHATTER_DLG := "res://dialogue/ch1/shatter.dlg"

## `do desaturate`: the colour the world drains to, and how long the drain takes.
const DESATURATE_COLOR := Color(0.6, 0.6, 0.7, 1.0)
const DESATURATE_SECONDS := 3.0

## `do look_back`: how far the camera swings toward Oakhaven (the left) and how long
## each leg takes (out, then back).
const LOOK_BACK_OFFSET := Vector2(-80.0, 0.0)
const LOOK_BACK_SECONDS := 0.5

## The running colour drain (`do desaturate`). play_environmental_shift() waits for it.
var _desat_tween: Tween = null

func play_bridge_approach() -> void:
	## Kaelen and Elara step onto the bridge leading out of Oakhaven. Elara is always with
	## him (elara_meeting.dlg keeps her in every branch), so there is no solo variant.
	## Order: enter beats, then shatter.dlg `bridge`, then the walk to mid-bridge.
	await _play_beats("Bridge Approach", [
		{
			"type": "camera_move",
			"target": Vector2(640, 360),
			"duration": 0.5
		},
		{
			"type": "parallel",
			"beats": [
				{
					"type": "character_enter",
					"character": "Kaelen",
					"position": Vector2(350, 430),
					"from": "left",
					"duration": 2.0
				},
				{
					"type": "character_enter",
					"character": "Elara",
					"position": Vector2(280, 430),
					"from": "left",
					"duration": 2.5
				}
			]
		},
	])
	if not is_inside_tree() or not cinematic_active: return

	await DialogueManager.run(SHATTER_DLG, "bridge", _on_dlg_event)
	if not is_inside_tree() or not cinematic_active: return

	await _play_beats("Bridge Approach (walk)", [
		{
			"type": "parallel",
			"beats": [
				{
					"type": "character_move",
					"character": "Kaelen",
					"target": Vector2(640, 430),
					"duration": 3.0
				},
				{
					"type": "character_move",
					"character": "Elara",
					"target": Vector2(560, 430),
					"duration": 3.0
				}
			]
		},
	])
	if not is_inside_tree(): return

func _play_beats(cutscene_name: String, beats: Array) -> void:
	## Plays one cutscene and waits for it to finish. It also returns after a hold-to-skip:
	## _on_skip_cutscene() sets cinematic_active = false and then calls stop_cutscene(),
	## which emits cutscene_finished (synchronously) for a cutscene that was playing.
	## So the callers' `not cinematic_active` guards are what stop the sequence after a
	## skip; they must stay.
	cutscene_mgr.play_cutscene({"name": cutscene_name, "beats": beats})
	await cutscene_mgr.cutscene_finished

func play_environmental_shift() -> void:
	## Visual and audio shift. The lines are shatter.dlg `shift`; the colour drain starts
	## on its `do desaturate`, and this waits for it to finish before returning.
	print("[CH1-SHATTER] Environmental shift begins")
	
	_desat_tween = null
	await DialogueManager.run(SHATTER_DLG, "shift", _on_dlg_event)
	if not is_inside_tree() or not cinematic_active: return
	
	# The drain started during the run; it may already be over (a finished tween is
	# invalid, and waiting on one would never return).
	if _desat_tween != null and _desat_tween.is_valid():
		await _desat_tween.finished
		if not is_inside_tree() or not cinematic_active: return
	DialogueManager.hide_dialogue()

func _on_dlg_event(event: String) -> void:
	## Handles the `do` events of shatter.dlg. Awaited by DialogueManager.run(), so an
	## event that waits holds the dialogue until it is done. An unknown event warns and
	## returns at once: the dialogue must never hang on a name this scene doesn't know.
	match event:
		"desaturate":
			# Starts the drain and returns: the next line plays while the colour goes.
			_desat_tween = create_tween()
			_desat_tween.tween_property(self, "modulate", DESATURATE_COLOR, DESATURATE_SECONDS)
		"shake":
			# Feel the world changing
			camera.shake(4.0, 0.5)
			await get_tree().create_timer(1.5, false).timeout
		"pan_ironhold":
			# Absorb the new world — slow camera pan
			DialogueManager.hide_dialogue()
			camera.move_to(Vector2(640, 320), 2.0)
			await get_tree().create_timer(2.5, false).timeout
		"look_back":
			# Kaelen turns toward Oakhaven: the camera swings left, then returns.
			var home := camera.global_position
			await camera.move_to(home + LOOK_BACK_OFFSET, LOOK_BACK_SECONDS, Tween.TRANS_SINE)
			if not is_inside_tree(): return
			await camera.move_to(home, LOOK_BACK_SECONDS, Tween.TRANS_SINE)
		_:
			push_warning("[CH1-SHATTER] unhandled dialogue event: %s" % event)

func play_the_shatter() -> void:
	## THE SHATTER — screen freezes, maps to 3D glass plane, shatters
	## (Every await is followed by the skip guard: a hold-to-skip during the effects must
	## not let the `reconstruct` node start afterwards.)
	print("[CH1-SHATTER] Executing THE SHATTER")
	
	# Step 1: FREEZE — screen holds
	# (In a real implementation, we'd capture the viewport texture)
	await get_tree().create_timer(1.0, false).timeout
	if not is_inside_tree() or not cinematic_active: return
	
	# Step 2: Glass cracking sound + visual
	# Initial crack lines appear
	if shatter_effect:
		shatter_effect.visible = true
		shatter_effect.modulate.a = 0.0
		var crack_tween = create_tween()
		crack_tween.tween_property(shatter_effect, "modulate:a", 1.0, 0.3)
		await crack_tween.finished
		if not is_inside_tree() or not cinematic_active: return
	
	# Step 3: SHATTER! — massive impact
	camera.earthquake_shake(1.5)
	
	# Bright flash
	flash_overlay.color = Color.WHITE
	flash_overlay.modulate.a = 1.0
	
	# Simulate glass shards flying (rapid color/position changes)
	for i in range(12):
		if glitch_overlay:
			glitch_overlay.visible = true
			glitch_overlay.color = Color(randf_range(0.3, 1.0), randf_range(0.3, 1.0), randf_range(0.3, 1.0), 0.7)
		await get_tree().create_timer(0.06, false).timeout
		if not is_inside_tree() or not cinematic_active: return
		if glitch_overlay:
			glitch_overlay.visible = false
		await get_tree().create_timer(0.04, false).timeout
		if not is_inside_tree() or not cinematic_active: return
	
	flash_overlay.modulate.a = 0.0
	
	# Step 4: Black screen momentarily
	flash_overlay.color = Color.BLACK
	flash_overlay.modulate.a = 1.0
	await get_tree().create_timer(1.0, false).timeout
	if not is_inside_tree() or not cinematic_active: return
	
	# Step 5: Reveal — the world's one line while the screen is still black
	await DialogueManager.run(SHATTER_DLG, "reconstruct", _on_dlg_event)
	if not is_inside_tree() or not cinematic_active: return
	DialogueManager.hide_dialogue()
	
	# Fade from black
	var reveal_tween = create_tween()
	reveal_tween.tween_property(flash_overlay, "modulate:a", 0.0, 2.0)
	await reveal_tween.finished
	if not is_inside_tree() or not cinematic_active: return
	
	# Reset modulate
	self.modulate = Color(0.5, 0.45, 0.35, 1.0)  # Ironhold's brass/rust palette
	
	if shatter_effect:
		shatter_effect.visible = false
	
	await get_tree().create_timer(1.0, false).timeout
	if not is_inside_tree() or not cinematic_active: return
	
	GameManager.set_story_flag("ch1_shatter_witnessed", true)

func play_post_shatter_dialogue() -> void:
	## Kaelen and Elara on the Ironhold side, then the look back at Oakhaven. Everything
	## from here to the end of the scene is one run of shatter.dlg's `start` node, which
	## routes on the Aldric and village flags itself. This scene reads no flags here.
	await DialogueManager.run(SHATTER_DLG, "start", _on_dlg_event)
	if not is_inside_tree() or not cinematic_active: return
	DialogueManager.hide_dialogue()

func play_chapter_end_card() -> void:
	## Chapter 1 complete — show end card with stats
	
	# Fade to black
	flash_overlay.color = Color.BLACK
	var fade_tween = create_tween()
	fade_tween.tween_property(flash_overlay, "modulate:a", 1.0, 1.5)
	await fade_tween.finished
	if not is_inside_tree(): return
	
	# Build chapter end card text
	var has_elara = GameManager.story_flags.get("ch1_elara_trusted", false) or GameManager.story_flags.get("ch1_elara_cautious", false)
	var warned_village = GameManager.story_flags.get("ch1_oakhaven_warned_villagers", false)
	
	var knight_status = _knight_status()
	
	var companion_status = "Elara — ALLIED" if has_elara else "SOLO PATH"
	var village_status = "Warned" if warned_village else "Left in silence"
	var aldric_reward = _grant_aldric_outcome_reward(knight_status)
	
	var end_text = ""
	end_text += "═══════════════════════════════════\n"
	end_text += "  CHAPTER 1 COMPLETE\n"
	end_text += "  THE NULL POINTER EXCEPTION\n"
	end_text += "═══════════════════════════════════\n\n"
	end_text += "  STATUS: OAKHAVEN — CLEARED\n"
	end_text += "  BOSS: Corrupted Sentinel (Aldric) — %s\n" % knight_status
	end_text += "  COMPANION: %s\n\n" % companion_status
	end_text += "  CHOICES MADE:\n"
	end_text += "    • Oakhaven: %s\n" % village_status
	end_text += "    • Sentinel: %s\n\n" % knight_status
	end_text += "  REWARDS:\n"
	end_text += "    • 500 Gold\n"
	end_text += "    • Level Up (RAM: 13GB)\n\n"
	end_text += "    - Aldric Outcome: %s\n\n" % aldric_reward
	end_text += "  METRICS:\n"
	end_text += "    Corruption Level: %d%%\n" % int(GameManager.glitch_meter)
	end_text += "    Root Access Uses: 2\n"
	end_text += "    Gold Earned: %d\n\n" % GameManager.player_stats.get("gold", 500)
	end_text += "═══════════════════════════════════\n"
	end_text += "  NEXT: CHAPTER 2\n"
	end_text += "  THE STACK OVERFLOW — IRONHOLD\n"
	end_text += "═══════════════════════════════════"
	
	# Show end card
	if chapter_end_card:
		chapter_end_card.visible = true
		if end_card_text:
			end_card_text.text = end_text
		chapter_end_card.modulate.a = 0.0
		var card_tween = create_tween()
		card_tween.tween_property(chapter_end_card, "modulate:a", 1.0, 2.0)
		await card_tween.finished
		if not is_inside_tree(): return
	else:
		# Fallback: use chapter title area
		chapter_title.text = "CHAPTER 1 COMPLETE"
		subtitle.text = "THE NULL POINTER EXCEPTION"
		var tween = create_tween()
		tween.tween_property(chapter_title, "modulate:a", 1.0, 2.0)
		tween.tween_property(subtitle, "modulate:a", 1.0, 1.5)
		await tween.finished
		if not is_inside_tree(): return
	
	GameManager.set_story_flag("ch1_complete", true)
	GameManager.current_chapter = 2
	# Speedrun achievement check — use playtime_seconds (always ticks) rather than
	# speedrun_seconds which only ticks when speedrun_active flag is manually set.
	if has_node("/root/Achievements") and has_node("/root/GameManager"):
		var elapsed_secs = GameManager.playtime_seconds
		if elapsed_secs > 0.0 and elapsed_secs <= 1800:
			Achievements.try_unlock("speedrun_30")
	
	# ── Demo-mode gate: show "Get Full Game" screen instead of Ch2 ──
	if GameManager.DEMO_MODE:
		await DialogueManager.say("System", "Chapter 1 Complete — Demo Ended!", Color(0.0, 1.0, 0.6), false)
		if not is_inside_tree() or not cinematic_active: return
		_show_demo_end_screen()
		return

	# Wait for the player to advance (jump / accept)
	await DialogueManager.say("System", InputService.fmt("Chapter 1 Complete. Press [{jump}] to continue to Chapter 2..."), Color(0.6, 0.8, 1.0), false)
	if not is_inside_tree() or not cinematic_active: return  # skipped: _on_skip_cutscene already changed scene
	cinematic_active = false  # no hold-to-skip during the final fade (it would change scene twice)

	# Proceed to Chapter 2: The Administrator's Game
	print("[CH1] CHAPTER 1 COMPLETE — Transitioning to Chapter 2")
	print("=== CHAPTER 1: THE NULL POINTER EXCEPTION — COMPLETE ===")

	DialogueManager.hide_dialogue()
	await transition.transition_out(ScreenTransition.TransitionType.FADE, 2.0)
	if not is_inside_tree(): return
	SceneTransitions.change_scene("res://scenes/chapter2/ironhold_gate.tscn", SceneTransitions.TransitionStyle.SHATTER)

func _knight_status() -> String:
	if GameManager.story_flags.get("ch1_root_purge", false):
		return "ROOT PURGED"
	if GameManager.story_flags.get("ch1_knight_spared", false):
		return "FREED"
	if GameManager.story_flags.get("ch1_knight_killed", false):
		return "SLAIN"
	return "DEFEATED"

func _grant_aldric_outcome_reward(knight_status: String) -> String:
	if GameManager.has_flag("ch1_aldric_outcome_reward_claimed"):
		return "Already claimed"

	GameManager.set_story_flag("ch1_aldric_outcome_reward_claimed", true)
	if has_node("/root/CraftingSystem"):
		CraftingSystem.get_recipes()
	if not has_node("/root/Inventory"):
		return "Recorded"

	match knight_status:
		"ROOT PURGED":
			if Inventory.add_item("memory_shard", 2):
				return "Memory Shard x2"
		"FREED":
			if Inventory.add_item("memory_shard", 1):
				return "Memory Shard x1"
		"SLAIN":
			if Inventory.add_item("data_ore", 1):
				return "Data Ore x1"
		_:
			if Inventory.add_item("glitch_herb", 1):
				return "Glitch Herb x1"

	return "Recorded"

func _on_custom_effect(effect_name: String, _parameters: Dictionary) -> void:
	match effect_name:
		_:
			print("[SHATTER EFFECT] %s" % effect_name)

## ─── Hold-to-skip mechanism ─────────────────────────────────────────
const SKIP_HOLD_DURATION: float = 1.5
var _skip_hold_timer: float = 0.0
var _skip_holding: bool = false
var _skip_hint: Label = null
var _skip_completed: bool = false

func _process(delta: float) -> void:
	if not cinematic_active or _skip_completed:
		return
	if _skip_holding:
		_skip_hold_timer += delta
		_update_skip_hint()
		if _skip_hold_timer >= SKIP_HOLD_DURATION:
			_skip_completed = true
			_skip_holding = false
			_hide_skip_hint()
			_on_skip_cutscene()

func _input(event) -> void:
	if event.is_action_pressed("ui_cancel") and cinematic_active and not _skip_completed:
		_skip_holding = true
		_skip_hold_timer = 0.0
		_show_skip_hint()
		get_viewport().set_input_as_handled()
	elif event.is_action_released("ui_cancel"):
		_skip_holding = false
		_skip_hold_timer = 0.0
		_hide_skip_hint()
	elif event.is_action_pressed("ui_accept"):
		pass

func _show_skip_hint() -> void:
	if _skip_hint and is_instance_valid(_skip_hint):
		_skip_hint.visible = true
		return
	_skip_hint = Label.new()
	_skip_hint.text = InputService.fmt("[Hold {ui_cancel} to skip]  %s") % "░".repeat(10)
	_skip_hint.add_theme_font_size_override("font_size", 14)
	_skip_hint.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0, 0.7))
	_skip_hint.add_theme_constant_override("outline_size", 2)
	_skip_hint.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.8))
	_skip_hint.anchors_preset = Control.PRESET_BOTTOM_RIGHT
	_skip_hint.offset_left = -280
	_skip_hint.offset_top = -40
	_skip_hint.offset_right = -20
	_skip_hint.offset_bottom = -10
	add_child(_skip_hint)

func _update_skip_hint() -> void:
	if not _skip_hint or not is_instance_valid(_skip_hint):
		return
	var progress = clampf(_skip_hold_timer / SKIP_HOLD_DURATION, 0.0, 1.0)
	var filled = int(progress * 10)
	var bar = "█".repeat(filled) + "░".repeat(10 - filled)
	_skip_hint.text = InputService.fmt("[Hold {ui_cancel} to skip]  %s") % bar

func _hide_skip_hint() -> void:
	if _skip_hint and is_instance_valid(_skip_hint):
		_skip_hint.visible = false

func _on_skip_cutscene() -> void:
	## Skip directly to Chapter 2 transition
	cinematic_active = false
	if cutscene_mgr:
		cutscene_mgr.stop_cutscene()
	if has_node("/root/DialogueManager"):
		DialogueManager.force_reset()
	GameManager.set_story_flag("ch1_shatter_witnessed", true)
	GameManager.set_story_flag("ch1_complete", true)
	GameManager.current_chapter = 2
	_grant_aldric_outcome_reward(_knight_status())  # the end card grants it on the full path
	if GameManager.DEMO_MODE:
		_show_demo_end_screen()
		return
	if has_node("/root/SceneTransitions"):
		SceneTransitions.change_scene("res://scenes/chapter2/ironhold_gate.tscn", SceneTransitions.TransitionStyle.SHATTER)
	else:
		get_tree().change_scene_to_file("res://scenes/chapter2/ironhold_gate.tscn")

# ── Demo-mode end screen (Chapter 1 gate) ────────────────────────────
func _show_demo_end_screen() -> void:
	DialogueManager.hide_dialogue()
	var layer := CanvasLayer.new()
	layer.layer = 99
	add_child(layer)

	# Dim bg
	var bg := ColorRect.new()
	bg.color = Color(0, 0, 0, 0.85)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	layer.add_child(bg)

	var vbox := VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_CENTER)
	vbox.offset_left = -300
	vbox.offset_top = -180
	vbox.offset_right = 300
	vbox.offset_bottom = 180
	vbox.add_theme_constant_override("separation", 16)
	layer.add_child(vbox)

	var title := Label.new()
	title.text = "THANKS FOR PLAYING THE DEMO!"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 28)
	title.add_theme_color_override("font_color", Color(0.0, 1.0, 0.6))
	vbox.add_child(title)

	var body := Label.new()
	body.text = "Chapter 1: The Null Pointer Exception is complete.\nThe full game includes 3 chapters, 17 enemy types,\n38 achievements, 10 side quests, and New Game+."
	body.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	body.add_theme_font_size_override("font_size", 16)
	body.add_theme_color_override("font_color", Color(0.85, 0.85, 0.9))
	vbox.add_child(body)

	var cta := Label.new()
	cta.text = "GET THE FULL GAME ON ITCH.IO"
	cta.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	cta.add_theme_font_size_override("font_size", 20)
	cta.add_theme_color_override("font_color", Color(1.0, 0.85, 0.3))
	vbox.add_child(cta)

	var url_btn := Button.new()
	url_btn.text = "Open itch.io Page"
	url_btn.pressed.connect(func(): OS.shell_open("https://itch.io"))  # Replace with real URL
	vbox.add_child(url_btn)

	var menu_btn := Button.new()
	menu_btn.text = "Return to Main Menu"
	menu_btn.pressed.connect(func():
		if has_node("/root/SceneTransitions"):
			SceneTransitions.change_scene("res://scenes/main_menu.tscn")
		else:
			get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
	)
	vbox.add_child(menu_btn)
