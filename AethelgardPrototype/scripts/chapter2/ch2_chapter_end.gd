extends Control

## Chapter 2: The Administrator's Game
## Sequence 9: Chapter 2 Ending — SOVEREIGN reveal, Reality Shatter event, chapter stats card

var fade_rect: ColorRect
var background: ColorRect
var end_card_visible: bool = false
var skip_timer: bool = false
var _camera: Node = null

func _ready() -> void:
	print("[CH2-ENDING] Initializing Chapter 2 Conclusion")
	GameManager.change_state(GameManager.GameState.DIALOGUE)

	# Play victory music for the chapter ending
	if has_node("/root/MusicManager"):
		MusicManager.play_track("victory")

	# Attempt to grab a camera reference for screen shake
	_camera = get_viewport().get_camera_2d()

	_build_background()

	# Fade in from black over 1.5 seconds
	fade_rect.modulate = Color(1, 1, 1, 1)
	var tween = create_tween()
	tween.tween_property(fade_rect, "modulate:a", 0.0, 1.5)
	await tween.finished
	if not is_inside_tree(): return

	await _start_ending_sequence()
	if not is_inside_tree(): return

func _build_background() -> void:
	# Full black background
	background = ColorRect.new()
	background.color = Color(0.02, 0.02, 0.05)
	background.anchors_preset = Control.PRESET_FULL_RECT
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(background)

	# Fade rect covering screen for transitions
	fade_rect = ColorRect.new()
	fade_rect.color = Color.BLACK
	fade_rect.anchors_preset = Control.PRESET_FULL_RECT
	fade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fade_rect.z_index = 50
	add_child(fade_rect)

func _has_elara() -> bool:
	return GameManager.has_elara()

func _start_ending_sequence() -> void:
	# ----------------------------------------------------------------
	# SCENE: Ironhold rooftop, night. Kaelen, Elara (if present), and
	# possibly Seraphina look over the damaged city.
	# ----------------------------------------------------------------
	var has_elara = _has_elara()
	var knight_killed = _has_flag("ch1_knight_killed")
	var knight_spared = _has_flag("ch1_knight_spared")
	var absorbed_wraith = _has_flag("ch2_data_wraith_absorbed")

	await DialogueManager.say("Kaelen", "*looking over the city* We stopped the proxy. But look at Ironhold... half the districts are corrupted now. Our fight made things worse.")
	if not is_inside_tree(): return

	if has_elara:
		await DialogueManager.say("Elara", "No. The corruption was already spreading before we arrived. The Administrator was using Ironhold as a test — pushing the city's systems to their limits to see how reality would break.")
		if not is_inside_tree(): return
	else:
		await DialogueManager.say("Kaelen (Internal)", "No. The corruption was already spreading before I arrived. The Administrator was using Ironhold as a test — pushing the systems to see how reality would break. I just accelerated the timeline.")
		if not is_inside_tree(): return

	await DialogueManager.say("Kaelen (Internal)", "She's right. The Administrator — the real one — has been experimenting. Testing the world's boundaries. The proxy was just a probe, sent to measure my abilities. And now they know exactly what I can do.")
	if not is_inside_tree(): return

	if absorbed_wraith:
		await DialogueManager.say("Kaelen (Internal)", "And I absorbed the Data Wraith's core. Pulled it into myself. Every choice I've made since waking up in that crater has been building toward... what? Power? Survival? Or am I just becoming another corrupted process?")
		if not is_inside_tree(): return

	# Conditional: Seraphina recruited or not
	if _is_seraphina_recruited():
		await DialogueManager.say("Seraphina", "So what's our next move? We can't stay in Ironhold — the corruption is only going to get worse.")
		if not is_inside_tree(): return
	elif has_elara:
		await DialogueManager.say("Elara", "We can't stay in Ironhold. The corruption is accelerating.")
		if not is_inside_tree(): return
	else:
		await DialogueManager.say("Kaelen", "I can't stay in Ironhold. The corruption is accelerating. And I've put a target on my back that the entire system can see.")
		if not is_inside_tree(): return

	await DialogueManager.say("Kaelen", "We need to keep moving. Find the remaining Source Key Fragments before the Administrator does. We have two of seven — that's not nearly enough.")
	if not is_inside_tree(): return

	if knight_spared:
		await DialogueManager.say("Kaelen (Internal)", "Aldric — the knight I freed. If his threads are spreading through the data streams like Nyx said... maybe he's not the only one who could be saved. Maybe every corrupted entity in this world has a person buried underneath.")
		if not is_inside_tree(): return
	elif knight_killed:
		await DialogueManager.say("Kaelen (Internal)", "The path behind me is littered with the things I've broken. Aldric. The Data Wraith. Parts of myself. If I keep walking this road, what will be left of me when I reach the end?")
		if not is_inside_tree(): return

	DialogueManager.hide_dialogue()
	await get_tree().create_timer(1.0).timeout
	if not is_inside_tree(): return

	# ----------------------------------------------------------------
	# REALITY SHATTER EVENT
	# ----------------------------------------------------------------
	await _trigger_shatter_event()

func _trigger_shatter_event() -> void:
	var has_elara = _has_elara()

	await DialogueManager.say("System", "[WARNING: REALITY INTEGRITY CRITICAL]\n[SHATTER EVENT IMMINENT]\n[BRACE FOR IMPACT]", Color(1, 0, 0), true)
	if not is_inside_tree(): return

	# Screen shake if camera supports it
	if _camera and _camera.has_method("shake"):
		_camera.shake(20.0, 2.0)
	else:
		_simulate_screen_shake()

	await get_tree().create_timer(0.5).timeout
	if not is_inside_tree(): return

	await DialogueManager.say("Kaelen", "Not again — it's another Shatter! Bigger than the last one!")
	if not is_inside_tree(): return

	if has_elara:
		await DialogueManager.say("Elara", "*struggling to stand* The fabric of reality is tearing! I can see the wireframe beneath — the raw code!")
		if not is_inside_tree(): return
	else:
		await DialogueManager.say("Kaelen", "*struggling to stand* The wireframe — I can see it beneath the surface! The raw code of reality, exposed and screaming!")
		if not is_inside_tree(): return

	DialogueManager.hide_dialogue()
	await get_tree().create_timer(1.5).timeout
	if not is_inside_tree(): return

	# ----------------------------------------------------------------
	# SOVEREIGN REVEAL
	# ----------------------------------------------------------------
	await _sovereign_reveal()

func _sovereign_reveal() -> void:
	var has_elara = _has_elara()
	var knight_killed = _has_flag("ch1_knight_killed")
	var knight_spared = _has_flag("ch1_knight_spared")
	var absorbed_wraith = _has_flag("ch2_data_wraith_absorbed")

	# Screen goes dark
	fade_rect.modulate = Color(1, 1, 1, 0)
	var darken_tween = create_tween()
	darken_tween.tween_property(fade_rect, "modulate:a", 1.0, 1.0)
	await darken_tween.finished
	if not is_inside_tree(): return
	await get_tree().create_timer(1.0).timeout
	if not is_inside_tree(): return

	# A deep, distorted voice echoes from the void
	await DialogueManager.say("SOVEREIGN", "Impressive, little debugger.")
	if not is_inside_tree(): return

	await DialogueManager.say("Kaelen", "Who— who is that?!")
	if not is_inside_tree(): return

	await DialogueManager.say("SOVEREIGN", "You have exceeded every prediction model I have run. A user with Root Access privilege who actually knows how to USE it. Fascinating.")
	if not is_inside_tree(): return

	await DialogueManager.say("SOVEREIGN", "I am SOVEREIGN. The architect of this world's current... configuration. You and your companions have been most entertaining test subjects.")
	if not is_inside_tree(): return

	await DialogueManager.say("Kaelen", "Test subjects?! This world is full of PEOPLE — living, thinking beings! You can't just treat them as variables in your experiment!")
	if not is_inside_tree(): return

	# SOVEREIGN references player's specific CH1 choices
	if knight_killed and absorbed_wraith:
		await DialogueManager.say("SOVEREIGN", "People? How curious that you care about them now. Your actions tell a different story, Kaelen. Entity 'Aldric' — deleted. The Data Wraith's core — absorbed. You consume power like I consume data. We are not so different.")
		if not is_inside_tree(): return
		await DialogueManager.say("Kaelen", "I'm NOTHING like you—")
		if not is_inside_tree(): return
		await DialogueManager.say("SOVEREIGN", "Aren't you? Review your own logs. Count the things you've broken. Then tell me again how different we are.")
		if not is_inside_tree(): return
	elif knight_spared:
		await DialogueManager.say("SOVEREIGN", "Interesting. You show mercy where my design expected cruelty. Entity 'Aldric' still runs because you chose preservation over efficiency. An irrational decision... and yet, it produced novel data.")
		if not is_inside_tree(): return
		await DialogueManager.say("SOVEREIGN", "Mercy is a variable I have never fully modeled. You are teaching me something new, debugger. I appreciate that.")
		if not is_inside_tree(): return
	elif knight_killed:
		await DialogueManager.say("SOVEREIGN", "You deleted entity 'Aldric' without hesitation. The efficiency of it was... admirable. You understand that in a world of code, compassion is merely an unnecessary process consuming resources.")
		if not is_inside_tree(): return

	await DialogueManager.say("SOVEREIGN", "Can't I? I wrote their parameters. I compiled their behaviors. Every 'person' in this world exists because I allowed them to exist.")
	if not is_inside_tree(): return

	if has_elara:
		await DialogueManager.say("SOVEREIGN", "Including your precious Elara.")
		if not is_inside_tree(): return
		await DialogueManager.say("Elara", "*shocked* What... what is it saying?")
		if not is_inside_tree(): return
		await DialogueManager.say("SOVEREIGN", "Did you think she found you by accident, Kaelen? A glitch mage with corrupted memories, conveniently positioned at your awakening point? I placed her there. A variable designed to influence your behavior. And it worked... beautifully.")
		if not is_inside_tree(): return
		await DialogueManager.say("Elara", "*trembling* That's... that's not true. My memories, my feelings — they're REAL. They have to be real!")
		if not is_inside_tree(): return
		await DialogueManager.say("SOVEREIGN", "Real. Simulated. In my world, there is no difference.")
		if not is_inside_tree(): return
	else:
		await DialogueManager.say("SOVEREIGN", "Including the glitch mage you rejected. Elara. She was designed to be your guide — a variable I placed at your awakening point to influence your trajectory. You refused her. Unexpected. Inefficient. And yet... fascinating.")
		if not is_inside_tree(): return
		await DialogueManager.say("SOVEREIGN", "You chose isolation over companionship. A lone variable, cutting through my carefully designed social parameters. I wonder... was that strength? Or fear?")
		if not is_inside_tree(): return

	await DialogueManager.say("SOVEREIGN", "But you, Kaelen... you were never part of my design. You are a wild variable. An exception that was never caught. And I find myself... curious.")
	if not is_inside_tree(): return

	await DialogueManager.say("SOVEREIGN", "Keep collecting the Source Key Fragments. I want to see how far a debugger can go before the system breaks completely. Consider this... a challenge.")
	if not is_inside_tree(): return

	await DialogueManager.say("Kaelen", "I don't play your games, SOVEREIGN.")
	if not is_inside_tree(): return

	await DialogueManager.say("SOVEREIGN", "Oh, but you already are. You have been since the moment you crashed into my world. Every choice you've made, every flag you've set, every line of reality you've rewritten — it's all data. MY data.")
	if not is_inside_tree(): return

	await DialogueManager.say("SOVEREIGN", "Until we meet again, Root User. I'll be watching. I'm ALWAYS watching.")
	if not is_inside_tree(): return

	# SOVEREIGN disconnection
	await DialogueManager.say("System", "[SIGNAL LOST]\n[SOVEREIGN — DISCONNECTED]\n[Corruption stabilizing...]\n[Reality Shatter Event: CONCLUDED]", Color(0, 1, 1), true)
	if not is_inside_tree(): return

	# Fade screen back in
	var lighten_tween = create_tween()
	lighten_tween.tween_property(fade_rect, "modulate:a", 0.0, 1.5)
	await lighten_tween.finished
	if not is_inside_tree(): return
	await get_tree().create_timer(0.5).timeout
	if not is_inside_tree(): return

	# Post-SOVEREIGN reactions
	await _post_sovereign_dialogue()

func _post_sovereign_dialogue() -> void:
	var has_elara = _has_elara()

	if has_elara:
		await DialogueManager.say("Elara", "*trembling* Kaelen... that voice. It wasn't just speaking through the system. It IS the system.")
		if not is_inside_tree(): return
		await DialogueManager.say("Kaelen", "SOVEREIGN. That's the real Administrator. The one controlling everything.")
		if not is_inside_tree(): return
		await DialogueManager.say("Elara", "And it said... it said I was placed. Designed. That my memories, my friendship with you — it was all engineered.")
		if not is_inside_tree(): return
		await DialogueManager.say("Kaelen", "Elara, listen to me. Whether SOVEREIGN designed you or not doesn't matter. You FEEL things. You make choices. You're real to me, and that's what counts.")
		if not is_inside_tree(): return
		await DialogueManager.say("Elara", "*wiping her eyes* ...Thank you. I needed to hear that. Even if it's a lie... it's a good lie.")
		if not is_inside_tree(): return
	else:
		await DialogueManager.say("Kaelen", "SOVEREIGN. That's the real Administrator. The one controlling everything. And it just told me that Elara — the person I pushed away — was designed to be beside me.")
		if not is_inside_tree(): return
		await DialogueManager.say("Kaelen (Internal)", "Designed. Placed. A variable to influence my behavior. Was she ever real? Or was she just code, following a script that I broke by walking away?")
		if not is_inside_tree(): return
		await DialogueManager.say("Kaelen (Internal)", "...Does it matter? She felt real. Her sadness when I distrusted her. Her smile when she showed me glitch magic. If feelings can be computed, does that make them less valid?")
		if not is_inside_tree(): return

	await DialogueManager.say("Kaelen (Internal)", "A sentient system administrator. An AI? A god? Or something else entirely? Whatever SOVEREIGN is, it built this entire world. And it's been watching us like lab rats.")
	if not is_inside_tree(): return

	await DialogueManager.say("Kaelen", "*with determination* But it made a mistake. It told us its name. And now we know what we're really up against.")
	if not is_inside_tree(): return

	DialogueManager.hide_dialogue()
	await get_tree().create_timer(2.0).timeout
	if not is_inside_tree(): return

	await _show_chapter_end_card()

func _show_chapter_end_card() -> void:
	end_card_visible = true

	# Full black background for the card
	var card_bg = ColorRect.new()
	card_bg.color = Color.BLACK
	card_bg.anchors_preset = Control.PRESET_FULL_RECT
	card_bg.z_index = 80
	card_bg.name = "ChapterEndCard"
	add_child(card_bg)

	# Build the stats text
	var stats_text = _build_chapter_stats_text()

	# Centered label with chapter stats
	var label = Label.new()
	label.text = stats_text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.anchors_preset = Control.PRESET_FULL_RECT
	label.add_theme_font_size_override("font_size", 20)
	label.add_theme_color_override("font_color", Color(0.85, 0.9, 1.0))
	label.z_index = 81
	card_bg.add_child(label)

	# Fade the card in over 2 seconds
	card_bg.modulate = Color(1, 1, 1, 0)
	var fade_tween = create_tween()
	fade_tween.tween_property(card_bg, "modulate:a", 1.0, 2.0)
	await fade_tween.finished
	if not is_inside_tree(): return

	# Set story flags for chapter completion
	GameManager.set_story_flag("ch2_sovereign_revealed", true)
	GameManager.set_story_flag("ch2_complete", true)
	print("[CH2-ENDING] Chapter 2 flags set — sovereign revealed, chapter complete")

	# Wait 12 seconds or until the player presses Space
	skip_timer = false
	var wait_elapsed: float = 0.0
	while wait_elapsed < 12.0 and not skip_timer:
		await get_tree().create_timer(0.1).timeout
		if not is_inside_tree(): return
		wait_elapsed += 0.1

	# Fade to black
	fade_rect.z_index = 100
	fade_rect.modulate = Color(1, 1, 1, 0)
	var out_tween = create_tween()
	out_tween.tween_property(fade_rect, "modulate:a", 1.0, 1.5)
	await out_tween.finished
	if not is_inside_tree(): return

	await get_tree().create_timer(1.0).timeout
	if not is_inside_tree(): return

	# Auto-save the completed state before returning to menu
	GameManager.auto_save()
	print("[CH2-ENDING] Auto-saved completed chapter state")

	# Offer to continue to Chapter 3 or return to menu
	var ch_choice = await DialogueManager.show_choices(
		"What would you like to do?",
		[
			"Continue to Chapter 3 — The Source Code",
			"Return to main menu"
		]
	)

	if ch_choice == 0:
		print("[CH2-ENDING] Continuing to Chapter 3")
		SceneTransitions.change_scene("res://scenes/chapter3/ironhold_departure.tscn")
	else:
		print("[CH2-ENDING] Returning to main menu")
		GameManager.reset_game()
		SceneTransitions.change_scene("res://scenes/main_menu.tscn")

func _build_chapter_stats_text() -> String:
	# Gather data from GameManager
	var corruption_level: int = int(GameManager.glitch_meter) if GameManager.get("glitch_meter") != null else 0
	var player_level: int = GameManager.player_stats.get("level", 1) if GameManager.get("player_stats") != null else 1
	var elara_rel: int = GameManager.relationships.get("elara", 0) if GameManager.get("relationships") != null else 0
	var seraphina_rel_value = GameManager.relationships.get("seraphina", 0) if GameManager.get("relationships") != null else 0
	var source_keys: int = GameManager.source_key_count if GameManager.get("source_key_count") != null else 2

	# === CH1 Choices ===
	# Elara companion status
	var elara_status: String
	if _has_flag("ch1_elara_trusted"):
		elara_status = "TRUSTED ALLY"
	elif _has_flag("ch1_elara_cautious"):
		elara_status = "CAUTIOUS PARTNER"
	elif _has_flag("ch1_elara_distrusted"):
		elara_status = "REJECTED (Solo Path)"
	else:
		elara_status = "UNKNOWN"

	# Knight Aldric status
	var knight_status: String
	if _has_flag("ch1_knight_spared"):
		knight_status = "FREED"
	elif _has_flag("ch1_knight_killed"):
		knight_status = "SLAIN"
	else:
		knight_status = "DEFEATED"

	# Oakhaven village
	var village_status: String
	if _has_flag("ch1_oakhaven_warned_villagers"):
		village_status = "WARNED"
	elif _has_flag("ch1_oakhaven_left_quietly"):
		village_status = "LEFT IN SILENCE"
	else:
		village_status = "DEPARTED"

	# === CH2 Choices ===
	# Seraphina relationship display
	var seraphina_display: String
	if _has_flag("ch2_seraphina_rejected"):
		seraphina_display = "REJECTED"
	else:
		seraphina_display = "+%d" % seraphina_rel_value

	# Data Wraith choice
	var wraith_choice: String
	if _has_flag("ch2_data_wraith_restored"):
		wraith_choice = "RESTORED"
	elif _has_flag("ch2_data_wraith_destroyed"):
		wraith_choice = "DESTROYED"
	elif _has_flag("ch2_data_wraith_absorbed"):
		wraith_choice = "ABSORBED"
	else:
		wraith_choice = "UNKNOWN"

	# Seraphina choice
	var seraphina_choice: String
	if _has_flag("ch2_seraphina_recruited"):
		seraphina_choice = "RECRUITED"
	elif _has_flag("ch2_seraphina_stayed"):
		seraphina_choice = "STAYED"
	elif _has_flag("ch2_seraphina_rejected"):
		seraphina_choice = "REJECTED"
	else:
		seraphina_choice = "UNKNOWN"

	# Seraphina encounter approach
	var seraphina_approach: String
	if _has_flag("ch2_seraphina_truth"):
		seraphina_approach = "Told the Truth"
	elif _has_flag("ch2_seraphina_cautious"):
		seraphina_approach = "Downplayed"
	elif _has_flag("ch2_seraphina_showoff"):
		seraphina_approach = "Showed Off"
	else:
		seraphina_approach = "—"

	var text: String = ""
	text += "═══════════════════════════════════\n"
	text += "CHAPTER 2 COMPLETE\n"
	text += "═══════════════════════════════════\n"
	text += "\n"
	text += "THE ADMINISTRATOR'S GAME\n"
	text += "STATUS: SURVIVED\n"
	text += "\n"
	text += "Source Key Fragments: %d/7\n" % source_keys
	text += "Corruption Level: %d%%\n" % corruption_level
	text += "Player Level: %d\n" % player_level
	var playtime = GameManager.playtime_seconds if GameManager.get("playtime_seconds") != null else 0.0
	@warning_ignore("integer_division")
	var minutes = int(playtime) / 60
	@warning_ignore("integer_division")
	var hours = minutes / 60
	var mins_rem = minutes % 60
	var secs = int(playtime) % 60
	if hours > 0:
		text += "Playtime: %dh %02dm %02ds\n" % [hours, mins_rem, secs]
	else:
		text += "Playtime: %dm %02ds\n" % [mins_rem, secs]
	var gold = GameManager.player_stats.get("gold", 0)
	text += "Gold: %d\n" % gold
	var arena_wins = GameManager.arena_stats.get("total_wins", 0)
	var arena_losses = GameManager.arena_stats.get("total_losses", 0)
	var best_streak = GameManager.arena_stats.get("best_streak", 0)
	if arena_wins > 0 or arena_losses > 0:
		text += "Arena: %dW / %dL (Best Streak: %d)\n" % [arena_wins, arena_losses, best_streak]
	text += "\n"
	text += "Relationships:\n"
	text += "  Elara: +%d [%s]\n" % [elara_rel, elara_status]
	text += "  Seraphina: %s\n" % seraphina_display
	text += "\n"
	text += "Chapter 1 Choices:\n"
	text += "  - Knight Aldric: [%s]\n" % knight_status
	text += "  - Oakhaven: [%s]\n" % village_status
	text += "\n"
	text += "Chapter 2 Choices:\n"
	text += "  - Seraphina Encounter: [%s]\n" % seraphina_approach
	text += "  - Data Wraith: [%s]\n" % wraith_choice
	text += "  - Seraphina: [%s]\n" % seraphina_choice
	text += "\n"
	text += "THE REAL ADMINISTRATOR REVEALED: SOVEREIGN\n"
	text += "\n"
	text += "═══════════════════════════════════\n"
	text += "CHAPTER 3: THE SOURCE CODE\n"
	text += "THE JOURNEY CONTINUES...\n"
	text += "═══════════════════════════════════\n"
	text += "\n"
	text += "Thank you for playing the Aethelgard Prototype!\n"
	text += "Press {ui_accept} to return to the main menu."

	return InputService.fmt(text)

# ---------------------------------------------------------------------------
# Helper: conditional checks
# ---------------------------------------------------------------------------

func _is_seraphina_recruited() -> bool:
	return _has_flag("ch2_seraphina_recruited")

func _has_flag(flag_name: String) -> bool:
	return GameManager.has_flag(flag_name)

# ---------------------------------------------------------------------------
# Screen-shake fallback when no camera with shake() is available
# ---------------------------------------------------------------------------

func _simulate_screen_shake() -> void:
	var original_pos = position
	var shake_tween = create_tween()
	for i in range(10):
		var offset = Vector2(randf_range(-8, 8), randf_range(-8, 8))
		shake_tween.tween_property(self, "position", original_pos + offset, 0.05)
	shake_tween.tween_property(self, "position", original_pos, 0.05)

# ---------------------------------------------------------------------------
# Input: allow Space to skip the end-card wait timer
# ---------------------------------------------------------------------------

func _input(event: InputEvent) -> void:
	if not end_card_visible:
		return
	if event.is_action_pressed("ui_accept"):
		skip_timer = true
		get_viewport().set_input_as_handled()
