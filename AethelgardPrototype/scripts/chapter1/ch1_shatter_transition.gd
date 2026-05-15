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
	
	await get_tree().create_timer(0.3).timeout
	if not is_inside_tree(): return
	transition.transition_in(ScreenTransition.TransitionType.FADE, 1.0)
	await transition.transition_finished
	if not is_inside_tree(): return
	
	await start_shatter_sequence()
	if not is_inside_tree(): return

func start_shatter_sequence() -> void:
	## Full Shatter transition sequence
	
	# Part 1: Kaelen steps onto the bridge
	await play_bridge_approach()
	if not is_inside_tree(): return
	
	# Part 2: Environmental shift begins
	await play_environmental_shift()
	if not is_inside_tree(): return
	
	# Part 3: THE SHATTER — glass breaking effect
	await play_the_shatter()
	if not is_inside_tree(): return
	
	# Let the world reconstruction sink in
	await get_tree().create_timer(2.5).timeout
	if not is_inside_tree(): return
	
	# Part 4: Kaelen's dialogue
	await play_post_shatter_dialogue()
	if not is_inside_tree(): return
	
	# Let Chapter 1's themes settle before end card
	await get_tree().create_timer(3.0).timeout
	if not is_inside_tree(): return
	
	# Part 5: Chapter 1 End Card
	await play_chapter_end_card()
	if not is_inside_tree(): return

func play_bridge_approach() -> void:
	## Kaelen steps onto the bridge leading out of Oakhaven — expanded
	var has_elara = GameManager.story_flags.get("ch1_elara_trusted", false) or GameManager.story_flags.get("ch1_elara_cautious", false)
	
	var beats = [
		{
			"type": "camera_move",
			"target": Vector2(640, 360),
			"duration": 0.5
		},
	]
	
	if has_elara:
		beats.append({
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
		})
	else:
		beats.append({
			"type": "character_enter",
			"character": "Kaelen",
			"position": Vector2(350, 430),
			"from": "left",
			"duration": 2.0
		})
	
	# Kaelen walking dialogue
	beats.append({
		"type": "dialogue",
		"speaker": "Kaelen",
		"text": "This bridge... the materials change halfway. Oak planks on this side, industrial steel on the other. Like two completely different worlds welded together.",
		"auto_advance": false
	})
	
	if has_elara:
		beats.append({
			"type": "dialogue",
			"speaker": "Elara",
			"text": "The regions are stitched together at the bridges. Each one was built by a different hand — different rules, different physics, different laws of nature.",
			"auto_advance": false
		})
		beats.append({
			"type": "dialogue",
			"speaker": "Kaelen (Internal)",
			"text": "Different laws of nature. She's saying the way things WORK literally changes when you cross into a new region. That's either brilliant... or terrifying.",
			"auto_advance": false
		})
		beats.append({
			"type": "dialogue",
			"speaker": "Elara",
			"text": "When we cross... brace yourself. The Shatter isn't just visual. You'll feel it in your bones. The whole world literally tears itself apart and rebuilds around you — from a different angle.",
			"auto_advance": false
		})
		beats.append({
			"type": "dialogue",
			"speaker": "Kaelen",
			"text": "Top-down to side-scrolling. The way I see the world is about to completely change. *deep breath* Let's do it.",
			"auto_advance": false
		})
	else:
		beats.append({
			"type": "dialogue",
			"speaker": "Kaelen (Internal)",
			"text": "The planks change material halfway across. Oak gives way to steel. The air shifts — warmer, heavier, carrying the smell of smoke and metal. Two worlds welded at a seam, and I'm about to step across.",
			"auto_advance": false
		})
		beats.append({
			"type": "dialogue",
			"speaker": "Kaelen",
			"text": "Elara warned me about this before we parted. The Shatter — when the world tears itself apart and rebuilds from a different angle. Top-down to side-scrolling. *deep breath* ...Here goes nothing.",
			"auto_advance": false
		})
	
	if has_elara:
		beats.append({
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
		})
	else:
		beats.append({
			"type": "character_move",
			"character": "Kaelen",
			"target": Vector2(640, 430),
			"duration": 3.0
		})
	
	var cutscene = {
		"name": "Bridge Approach",
		"beats": beats
	}
	
	cutscene_mgr.play_cutscene(cutscene)
	await cutscene_mgr.cutscene_finished
	if not is_inside_tree(): return

func play_environmental_shift() -> void:
	## Visual and audio shift — expanded atmosphere
	print("[CH1-SHATTER] Environmental shift begins")
	
	# Kaelen notices the change starting
	await DialogueManager.say("Kaelen", "The colors are draining. Look — the greens are fading to grey, like someone's sucking the life out of the landscape.")
	if not is_inside_tree(): return
	
	# Desaturation effect — gradually grey out the world
	var desat_tween = create_tween()
	desat_tween.tween_property(self, "modulate", Color(0.6, 0.6, 0.7, 1.0), 3.0)
	
	# Audio shift
	await DialogueManager.say("System", "[AUDIO_SHIFT: Pastoral melody decelerating... Pitch -50%]\n[VISUAL_SHIFT: Color palette desaturating... Skybox transitioning to industrial smog]", Color(0.5, 0.5, 0.5), true)
	if not is_inside_tree(): return
	
	# Companion reacts to the shift
	var has_elara_shift = GameManager.story_flags.get("ch1_elara_trusted", false) or GameManager.story_flags.get("ch1_elara_cautious", false)
	if has_elara_shift:
		await DialogueManager.say("Elara", "It's starting. The boundary between regions is dissolving. Can you feel it? The air itself is changing — heavier, hotter, like walking toward a furnace.")
		if not is_inside_tree(): return
	else:
		await DialogueManager.say("Kaelen (Internal)", "It's starting. Something in the air is changing — heavier, hotter, like walking toward a furnace. The boundary between regions is dissolving.")
		if not is_inside_tree(): return

	# Feel the world changing
	camera.shake(4.0, 0.5)
	await get_tree().create_timer(1.5).timeout
	if not is_inside_tree(): return

	# Kaelen notices physical sensations
	await DialogueManager.say("Kaelen", "My movement feels... different. Heavier. Like the ground is pulling harder. Every step takes more effort.")
	if not is_inside_tree(): return

	if has_elara_shift:
		await DialogueManager.say("Elara", "That's the shift. The rules of this place are changing — how you move, how you jump, how far you fall. You'll need to relearn your own body on the other side.")
		if not is_inside_tree(): return
	else:
		await DialogueManager.say("Kaelen (Internal)", "The rules are changing — how I move, how I jump, how far I fall. I'll need to relearn my own body on the other side. No one to warn me what's coming.")
		if not is_inside_tree(): return
	
	# System warning
	await DialogueManager.say("System", "[WARNING: REGIONAL BOUNDARY BREAKING]\n[VIEW SHIFTING: Bird's Eye → Side View]\n[GRAVITY: Increasing]\n[BRACE FOR THE SHATTER]", Color(1.0, 0.3, 0.0), true)
	if not is_inside_tree(): return
	
	await desat_tween.finished
	if not is_inside_tree(): return
	DialogueManager.hide_dialogue()

func play_the_shatter() -> void:
	## THE SHATTER — screen freezes, maps to 3D glass plane, shatters
	print("[CH1-SHATTER] Executing THE SHATTER")
	
	# Step 1: FREEZE — screen holds
	# (In a real implementation, we'd capture the viewport texture)
	await get_tree().create_timer(1.0).timeout
	if not is_inside_tree(): return
	
	# Step 2: Glass cracking sound + visual
	# Initial crack lines appear
	if shatter_effect:
		shatter_effect.visible = true
		shatter_effect.modulate.a = 0.0
		var crack_tween = create_tween()
		crack_tween.tween_property(shatter_effect, "modulate:a", 1.0, 0.3)
		await crack_tween.finished
		if not is_inside_tree(): return
	
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
		await get_tree().create_timer(0.06).timeout
		if not is_inside_tree(): return
		if glitch_overlay:
			glitch_overlay.visible = false
		await get_tree().create_timer(0.04).timeout
		if not is_inside_tree(): return
	
	flash_overlay.modulate.a = 0.0
	
	# Step 4: Black screen momentarily
	flash_overlay.color = Color.BLACK
	flash_overlay.modulate.a = 1.0
	await get_tree().create_timer(1.0).timeout
	if not is_inside_tree(): return
	
	# Step 5: Reveal — new perspective (side-scrolling world peek)
	# Show a message about the rendering engine switch
	await DialogueManager.say("System", "[WORLD RECONSTRUCTION COMPLETE]\n[VIEW: Top-Down → Side-Scrolling]\n[REGION: Oakhaven → Ironhold]\n[Welcome to Ironhold.]", Color(1, 0.5, 0), true)
	if not is_inside_tree(): return
	DialogueManager.hide_dialogue()
	
	# Fade from black
	var reveal_tween = create_tween()
	reveal_tween.tween_property(flash_overlay, "modulate:a", 0.0, 2.0)
	await reveal_tween.finished
	if not is_inside_tree(): return
	
	# Reset modulate
	self.modulate = Color(0.5, 0.45, 0.35, 1.0)  # Ironhold's brass/rust palette
	
	if shatter_effect:
		shatter_effect.visible = false
	
	await get_tree().create_timer(1.0).timeout
	if not is_inside_tree(): return
	
	GameManager.set_story_flag("ch1_shatter_witnessed", true)

func play_post_shatter_dialogue() -> void:
	## Kaelen's reaction to the genre shift — expanded reflection with choice callbacks
	
	var has_elara = GameManager.story_flags.get("ch1_elara_trusted", false) or GameManager.story_flags.get("ch1_elara_cautious", false)
	var knight_killed = GameManager.story_flags.get("ch1_knight_killed", false)
	var knight_spared = GameManager.story_flags.get("ch1_knight_spared", false)
	var warned_village = GameManager.story_flags.get("ch1_oakhaven_warned_villagers", false)
	
	await DialogueManager.say("Kaelen", "*gasping* ...What just happened? The entire world just BROKE and rebuilt itself around me.")
	if not is_inside_tree(): return
	
	await DialogueManager.say("Kaelen", "*stumbling* ...Everything SHIFTED. I'm seeing the world from the SIDE now — and gravity, actual GRAVITY, pulling me DOWN. Before, it was like floating. Now every step has weight.")
	if not is_inside_tree(): return
	
	if has_elara:
		await DialogueManager.say("Elara", "Welcome to the other side of The Shatter. It never gets easier. The first time I crossed, I couldn't move for an hour — my body had to relearn how to walk.")
		if not is_inside_tree(): return
	else:
		await DialogueManager.say("Kaelen (Internal)", "No one here to tell me if this is normal. No one to explain what just happened. Every cell in my body is screaming that the rules just changed — gravity, movement, perspective. I need to adapt. Fast.", Color(0.5, 0.9, 1.0))
		if not is_inside_tree(): return
	
	await DialogueManager.say("Kaelen (Internal)", "The air smells like soot and hot copper. The skybox went from pastoral blue to industrial grey in one hard cut. Chimney stacks. Gears. Steam vents.", Color(0.5, 0.9, 1.0))
	if not is_inside_tree(): return
	
	await DialogueManager.say("Kaelen (Internal)", "Oakhaven was the tutorial. The safe zone. The place where the game holds your hand and teaches you the basics while pretending it's a charming village.", Color(0.5, 0.9, 1.0))
	if not is_inside_tree(): return
	
	await DialogueManager.say("Kaelen (Internal)", "This... this is Ironhold. The Steam Realm. And judging by how thick that smog is, the corruption here runs a LOT deeper.", Color(0.5, 0.9, 1.0))
	if not is_inside_tree(): return
	
	# Absorb the new world — slow camera pan
	DialogueManager.hide_dialogue()
	camera.move_to(Vector2(640, 320), 2.0)
	await get_tree().create_timer(2.5).timeout
	if not is_inside_tree(): return
	
	if has_elara:
		await DialogueManager.say("Kaelen", "Elara, what are we walking into?")
		if not is_inside_tree(): return
		await DialogueManager.say("Elara", "Ironhold. Industrial-era region. The NPCs here are factory workers, gearwrights, and steam-powered automatons. The boss is... complicated.")
		if not is_inside_tree(): return
		await DialogueManager.say("Elara", "But we'll deal with that when we get there. For now, just... take a moment. Getting through Chapter 1 is no small thing.")
		if not is_inside_tree(): return
	else:
		await DialogueManager.say("Kaelen (Internal)", "Ironhold. That's what the system called this region during the reconstruction. Industrial-era. Chimneys, steam, gears. The enemies here won't be slimes and boars. They'll be machines. And the boss...", Color(0.5, 0.9, 1.0))
		if not is_inside_tree(): return
		await DialogueManager.say("Kaelen", "One chapter down. I barely survived it. And something tells me the difficulty curve is about to get a lot steeper.")
		if not is_inside_tree(): return
	
	# Knight reflection — branches based on kill/spare choice
	if knight_spared:
		await DialogueManager.say("Kaelen", "*looking back at the bridge* Aldric — the knight — he said 'thank you.' Four hundred and twelve iterations of the same fight, and I was the first person who thought to free him instead of just winning.")
		if not is_inside_tree(): return
		await DialogueManager.say("Kaelen (Internal)", "I left him standing at that bridge. Alive. Free. Fighting the corruption inside him with every breath. I hope that freedom holds. I hope it was worth the risk.", Color(0.5, 0.9, 1.0))
		if not is_inside_tree(): return
	elif knight_killed:
		await DialogueManager.say("Kaelen", "*looking back at the bridge, fists clenched* Aldric. His name was Aldric. I ended four hundred and twelve cycles of suffering in a single strike. He asked me to. He THANKED me.")
		if not is_inside_tree(): return
		await DialogueManager.say("Kaelen (Internal)", "But the system called it 'entity deletion.' Not liberation. Deletion. There's a difference between freeing someone and erasing them, and I'm not sure which one I did.", Color(0.5, 0.9, 1.0))
		if not is_inside_tree(): return
		await DialogueManager.say("Kaelen (Internal)", "The corruption it left in me — 5% extra, crawling through my data like an echo of his pain. Every choice in this world costs something. Every act of mercy is also an act of violence.", Color(0.5, 0.9, 1.0))
		if not is_inside_tree(): return
	else:
		await DialogueManager.say("Kaelen", "*looking back at the bridge* The Tutorial Knight said 'thank you.' Four hundred and twelve iterations of the same fight, and I was the first person who thought to end the loop instead of winning it.")
		if not is_inside_tree(): return
	
	# Weight of the Tutorial Knight's gratitude
	await get_tree().create_timer(2.0).timeout
	if not is_inside_tree(): return
	
	# Village reflection — branches based on warn/leave choice
	if warned_village:
		await DialogueManager.say("Kaelen (Internal)", "The farmer at his well. The guard trapped at his post. The child who wanted to learn how to CHOOSE. I warned them. It might not change anything — they might not be able to change. But at least they know someone saw them. Someone cared enough to speak.", Color(0.5, 0.9, 1.0))
		if not is_inside_tree(): return
	else:
		await DialogueManager.say("Kaelen (Internal)", "The farmer at his well. The guard trapped at his post. The child who wanted to learn how to CHOOSE. I left them without saying goodbye. Without warning them. The smart move. The safe move. The move that tastes like ash.", Color(0.5, 0.9, 1.0))
		if not is_inside_tree(): return
	
	await DialogueManager.say("Kaelen (Internal)", "AetherCorp did things like this. Traps disguised as games — keep people running in circles, keep them hooked, keep them spending. I quit because I couldn't stomach it anymore. And now I'm standing inside one, seeing what it does to the people caught in it.", Color(0.5, 0.9, 1.0))
	if not is_inside_tree(): return
	
	await DialogueManager.say("Kaelen (Internal)", "But I didn't just watch it happen. I BUILT parts of this. My code, my architecture, my optimizations — they're in the foundation. If this world is a prison, I helped lay the bricks.", Color(0.5, 0.9, 1.0))
	if not is_inside_tree(): return
	
	if has_elara:
		await DialogueManager.say("Elara", "*gently* You're asking questions nobody else asks. Not just 'how do I get stronger' but 'what am I breaking along the way.' That matters, Kaelen. More than you know.")
		if not is_inside_tree(): return
		await DialogueManager.say("Kaelen", "*quietly* ...Seven Source Key Fragments, guarded by the seven Lower Gods. And a System Administrator who probably already knows we're coming. Let's move.")
		if not is_inside_tree(): return
	else:
		await DialogueManager.say("Kaelen", "*quietly, to himself* Seven Source Key Fragments. Seven Lower Gods. One System Administrator. And me — alone, with a dead man's blade and a corruption meter that keeps climbing. ...Let's move.")
		if not is_inside_tree(): return
	
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
	var knight_killed = GameManager.story_flags.get("ch1_knight_killed", false)
	var knight_spared = GameManager.story_flags.get("ch1_knight_spared", false)
	var has_elara = GameManager.story_flags.get("ch1_elara_trusted", false) or GameManager.story_flags.get("ch1_elara_cautious", false)
	var warned_village = GameManager.story_flags.get("ch1_oakhaven_warned_villagers", false)
	
	var knight_status = "DEFEATED"
	if knight_spared:
		knight_status = "FREED"
	elif knight_killed:
		knight_status = "SLAIN"
	
	var companion_status = "Elara — ALLIED" if has_elara else "SOLO PATH"
	var village_status = "Warned" if warned_village else "Left in silence"
	
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
		if not is_inside_tree(): return
		_show_demo_end_screen()
		return

	# Wait for player to press Space to continue
	await DialogueManager.say("System", "Chapter 1 Complete. Press [SPACE] to continue to Chapter 2...", Color(0.6, 0.8, 1.0), false)
	if not is_inside_tree(): return

	# Proceed to Chapter 2: The Administrator's Game
	print("[CH1] CHAPTER 1 COMPLETE — Transitioning to Chapter 2")
	print("=== CHAPTER 1: THE NULL POINTER EXCEPTION — COMPLETE ===")

	DialogueManager.hide_dialogue()
	await transition.transition_out(ScreenTransition.TransitionType.FADE, 2.0)
	if not is_inside_tree(): return
	SceneTransitions.change_scene("res://scenes/chapter2/ironhold_gate.tscn", SceneTransitions.TransitionStyle.SHATTER)

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
	_skip_hint.text = "[Hold ESC to skip]  ░░░░░░░░░░"
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
	_skip_hint.text = "[Hold ESC to skip]  %s" % bar

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
