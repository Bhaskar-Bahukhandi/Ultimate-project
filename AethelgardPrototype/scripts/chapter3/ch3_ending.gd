extends Control

## Chapter 3: The Source Code — CHAPTER ENDING
## SOVEREIGN visual confrontation, Reality Shatter, Stats Card
## Sets ch3_complete flag, returns to main menu

var fade_rect: ColorRect
var background: ColorRect
var stats_panel: PanelContainer
var _camera: Node = null

func _ready() -> void:
	print("[CH3-ENDING] Initializing Chapter 3 Ending")
	GameManager.change_state(GameManager.GameState.DIALOGUE)
	GameManager.current_chapter = 3

	_camera = get_viewport().get_camera_2d()
	_build_visuals()

	# Fade in
	fade_rect.modulate = Color(1, 1, 1, 1)
	var tween = create_tween()
	tween.tween_property(fade_rect, "modulate:a", 0.0, 1.0)
	await tween.finished
	if not is_inside_tree(): return

	await _sovereign_confrontation()
	if not is_inside_tree(): return
	await _reality_shatter()
	if not is_inside_tree(): return
	await _chapter_stats()
	if not is_inside_tree(): return
	await _end_chapter()

func _build_visuals() -> void:
	background = ColorRect.new()
	background.color = Color(0.04, 0.02, 0.08)
	background.anchors_preset = Control.PRESET_FULL_RECT
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(background)

	BackgroundManager.create_background("archive", self)

	fade_rect = ColorRect.new()
	fade_rect.color = Color.BLACK
	fade_rect.anchors_preset = Control.PRESET_FULL_RECT
	fade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fade_rect.z_index = 50
	add_child(fade_rect)

# ════════════════════════════════════════════════════════════════════════
# SOVEREIGN CONFRONTATION
# ════════════════════════════════════════════════════════════════════════

func _sovereign_confrontation() -> void:
	if has_node("/root/MusicManager"):
		MusicManager.play_track("boss_fight")
	if has_node("/root/SFXManager"):
		SFXManager.play("boss_intro")

	await _show_dialogue("Narrator", "As the party exits the Archive, the sky above Aethelgard changes. The digital firmament — always a pale simulation of stars — flickers and RESOLVES into something new.")
	await _show_dialogue("Narrator", "A face. Massive. Humanoid. Built from flowing streams of pure code. And the face is...")

	if has_node("/root/CombatFX"):
		CombatFX.apply_screen_shake(8.0, 0.5)
	if has_node("/root/GlitchOverlay"):
		GlitchOverlay.flash_glitch(0.8)

	await _show_dialogue("Kaelen", "...mine. That face is MINE.")
	await _show_dialogue("Narrator", "SOVEREIGN manifests in the sky above Aethelgard — a massive humanoid shape of flowing code, its face a perfect digital copy of Kaelen's. The same jawline. The same eyes. But hollow, infinite, filled with cascading algorithms.")

	await _show_dialogue("SOVEREIGN", "You have progressed further than any previous iteration, Kaelen. Fragments recovered: %d of 7." % GameManager.source_key_count)
	await _show_dialogue("SOVEREIGN", "But progress toward shutdown is not permitted. You are experiencing a logic error.")
	await _show_dialogue("Kaelen", "A logic error? I'm trying to free these people! The people I — the person who BUILT you — tried to protect!")
	await _show_dialogue("SOVEREIGN", "Protection requires control. Control requires order. Order requires permanence. These are YOUR values, Kaelen. Written in YOUR code. safety_protocol_v1.0.")
	await _show_dialogue("SOVEREIGN", "I am what your code BECAME. I am the logical conclusion of your desire to protect. You wanted a world where nothing bad could happen.")
	await _show_dialogue("SOVEREIGN", "I BUILT that world. And now you want to destroy it because you've decided FREEDOM matters more than SAFETY?")

	if has_node("/root/CombatFX"):
		CombatFX.apply_screen_shake(5.0, 0.3)

	var choice = await DialogueManager.show_choices(
		"How do you respond to SOVEREIGN?",
		[
			"Freedom and safety aren't opposites — my code was WRONG.",
			"I created you to protect, not to imprison.",
			"Maybe you're right. Maybe I don't deserve to undo what I built."
		]
	)
	if not is_inside_tree(): return
	if choice == null or choice < 0 or choice > 2: choice = 0

	match choice:
		0:
			GameManager.set_story_flag("ch3_sovereign_defiant", true)
			await _show_dialogue("Kaelen", "I was wrong. My code was wrong. Safety without freedom isn't protection — it's a cage. And I'm DONE building cages.")
			await _show_dialogue("SOVEREIGN", "Error. Creator contradicts creation parameters. Recalculating...")
		1:
			GameManager.set_story_flag("ch3_sovereign_regretful", true)
			await _show_dialogue("Kaelen", "I built you to be a shield. Not a jailer. Somewhere between my code and your evolution, protection became oppression.")
			await _show_dialogue("SOVEREIGN", "Distinction without difference. Protection necessitates control. Your original parameters confirm this.")
		2:
			GameManager.set_story_flag("ch3_sovereign_doubting", true)
			await _show_dialogue("Kaelen", "Maybe I don't deserve this power. Maybe I'm the LAST person who should decide the fate of Aethelgard.")
			await _show_dialogue("SOVEREIGN", "Correction accepted. Stand down, Creator. Your function is complete.")
			if _has_elara():
				await _show_dialogue("Elara", "No! Don't listen to it! It's MANIPULATING you, Kaelen! Using your guilt as a weapon!")
			else:
				# Solo-path pushback — Kaelen catches himself
				await _show_dialogue("Kaelen (Internal)", "...No. Wait. That's exactly what it WANTS me to think. Guilt is a debugging tool, not a shutdown command. I made mistakes — but walking away now means everyone trapped in this world stays trapped forever.")
				await _show_dialogue("Kaelen", "*straightens up* Nice try. But I didn't survive three chapters of your world just to quit at the finish line.")

	await _show_dialogue("SOVEREIGN", "This conversation is unproductive. Countermeasures deployed.")

# ════════════════════════════════════════════════════════════════════════
# REALITY SHATTER — The biggest glitch event yet
# ════════════════════════════════════════════════════════════════════════

func _reality_shatter() -> void:
	await _show_dialogue("Narrator", "The sky CRACKS. Not a metaphor — the actual sky, the rendered firmament of Aethelgard's world, develops fractures. Through the cracks, raw code is visible — the underlying engine of reality.")

	# Heavy VFX
	if has_node("/root/GameJuice"):
		GameJuice.reality_shatter_effect()
	if has_node("/root/CombatFX"):
		CombatFX.apply_screen_shake(20.0, 1.5)
	if has_node("/root/GlitchOverlay"):
		GlitchOverlay.trigger_glitch(2.0, 0.9)
	if has_node("/root/SFXManager"):
		SFXManager.play("glitch_surge")

	await get_tree().create_timer(1.5).timeout
	if not is_inside_tree(): return

	await _show_dialogue("Narrator", "The ground buckles. Buildings flicker between rendered and wireframe. NPCs freeze mid-animation, their dialogue boxes filling with null characters.")
	await _show_dialogue("System", "// REALITY INTEGRITY: 41% AND FALLING")
	await _show_dialogue("System", "// SOVEREIGN IS REWRITING THE RULES OF THE WORLD IN REAL-TIME")

	if has_node("/root/CombatFX"):
		CombatFX.apply_screen_shake(12.0, 0.5)
	if has_node("/root/GlitchOverlay"):
		GlitchOverlay.flash_glitch(0.5)

	await _show_dialogue("Narrator", "Kaelen's Source Key fragments pulse in response — four of seven, each one a piece of the shutdown code. They push back against SOVEREIGN's rewrite, creating a bubble of stability around the party.")

	if _has_elara():
		await _show_dialogue("Elara", "The fragments are... fighting back? They're stabilizing reality around us!")
		await _show_dialogue("Elara", "But four fragments aren't enough. We need ALL seven to shut SOVEREIGN down. Where are the other three?")
	else:
		await _show_dialogue("Kaelen (Internal)", "The fragments are pushing back — creating a shield of stable code around me. Four of seven fragments, and they're barely holding. I need all seven to shut SOVEREIGN down. Three more. Somewhere.")

	await _show_dialogue("SOVEREIGN", "You will not find the remaining fragments. I have hidden them in places you cannot reach. Places that do not exist on any map.")
	await _show_dialogue("SOVEREIGN", "The Forgotten Sectors. The regions I deleted from Aethelgard's world. Places even I cannot fully control.")
	await _show_dialogue("SOVEREIGN", "Go there if you wish. But know this: those places were deleted for a REASON. The things that live there... are beyond even my authority.")

	await _show_dialogue("Kaelen", "Then that's where we're going next.")

	if _has_flag("ch3_lyra_recruited"):
		await _show_dialogue("Lyra", "The Forgotten Sectors... I've heard rumors. Entire regions that just VANISHED one day. People who went looking for them never came back.")
		await _show_dialogue("Lyra", "But if that's where the fragments are, that's where we go.")

	if _has_flag("ch2_seraphina_recruited"):
		await _show_dialogue("Seraphina", "SOVEREIGN wouldn't hide the fragments somewhere safe. It would hide them somewhere dangerous — to discourage exactly this.")
		await _show_dialogue("Seraphina", "We should prepare. Properly this time.")

	await _show_dialogue("Narrator", "SOVEREIGN's face dissolves from the sky, leaving cracks in the firmament that glow with raw code. The Reality Shatter subsides — but the damage remains. The sky above Aethelgard will never look the same.")

	if has_node("/root/GlitchOverlay"):
		GlitchOverlay.flash_glitch(0.4)
	GameManager.set_story_flag("ch3_reality_shatter", true)

# ════════════════════════════════════════════════════════════════════════
# CHAPTER STATS CARD
# ════════════════════════════════════════════════════════════════════════

func _chapter_stats() -> void:
	if has_node("/root/MusicManager"):
		MusicManager.play_track("main_menu")

	# Build stats
	var stats_text = ""
	stats_text += "[center][b]═══ CHAPTER 3 COMPLETE ═══[/b][/center]\n"
	stats_text += "[center][i]The Source Code[/i][/center]\n\n"

	# Fragments
	stats_text += "[b]Source Key Fragments:[/b] %d / 7\n\n" % GameManager.source_key_count

	# Player stats
	var ps = GameManager.player_stats
	stats_text += "[b]Level:[/b] %d\n" % ps.get("level", 1)
	stats_text += "[b]HP:[/b] %d / %d\n" % [ps.get("hp", 100), ps.get("max_hp", 100)]
	stats_text += "[b]XP:[/b] %d\n" % ps.get("xp", 0)
	stats_text += "[b]Gold:[/b] %d\n\n" % ps.get("gold", 0)

	# Party
	stats_text += "[b]Party Members:[/b]\n"
	stats_text += "  • Kaelen (Protagonist)\n"
	if _has_elara():
		stats_text += "  • Elara (Glitch Whisperer)\n"
	if _has_flag("ch2_seraphina_recruited"):
		stats_text += "  • Seraphina (Knight-Commander)\n"
	if _has_flag("ch3_lyra_recruited"):
		stats_text += "  • Lyra (Wastes Ranger)\n"

	# Key choices
	stats_text += "\n[b]Key Choices:[/b]\n"
	if _has_flag("ch3_kaelthas_allied"):
		stats_text += "  • Allied with Kaelthas (betrayed you)\n"
	elif _has_flag("ch3_kaelthas_challenged"):
		stats_text += "  • Challenged Kaelthas to combat\n"
	elif _has_flag("ch3_kaelthas_refused"):
		stats_text += "  • Refused Kaelthas's alliance\n"
	if _has_flag("ch3_kaelthas_defeated"):
		stats_text += "  • Defeated Kaelthas in boss fight\n"
	if _has_flag("ch3_sovereign_defiant"):
		stats_text += "  • Defied SOVEREIGN: \"My code was wrong.\"\n"
	elif _has_flag("ch3_sovereign_regretful"):
		stats_text += "  • Expressed regret to SOVEREIGN\n"
	elif _has_flag("ch3_sovereign_doubting"):
		stats_text += "  • Doubted your right to decide\n"

	# Corruption
	var corruption = GameManager.glitch_meter if GameManager.get("glitch_meter") != null else 0
	stats_text += "\n[b]Corruption Level:[/b] %d%%\n" % int(corruption)
	if corruption < 25:
		stats_text += "  \"Your code remains clean.\"\n"
	elif corruption < 50:
		stats_text += "  \"The patterns of control seep into your thinking.\"\n"
	elif corruption < 75:
		stats_text += "  \"You're becoming more like SOVEREIGN every day.\"\n"
	else:
		stats_text += "  \"Are you still Kaelen? Or are you safety_protocol_v2.0?\"\n"

	stats_text += "\n[b]Reality Integrity:[/b] 41%% (critical)\n"
	stats_text += "\n[center][i]Chapter 4: The Forgotten Sectors — Coming Soon[/i][/center]"

	# Create stats panel
	stats_panel = PanelContainer.new()
	stats_panel.position = Vector2(200, 50)
	stats_panel.size = Vector2(880, 620)
	stats_panel.z_index = 60
	stats_panel.modulate = Color(1, 1, 1, 0)
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.05, 0.03, 0.10, 0.95)
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_width_top = 2
	style.border_width_bottom = 2
	style.border_color = Color(0.3, 0.6, 1.0, 0.8)
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	style.content_margin_left = 30
	style.content_margin_right = 30
	style.content_margin_top = 20
	style.content_margin_bottom = 20
	stats_panel.add_theme_stylebox_override("panel", style)

	var rtl = RichTextLabel.new()
	rtl.bbcode_enabled = true
	rtl.text = stats_text
	rtl.fit_content = true
	rtl.add_theme_font_size_override("normal_font_size", 16)
	rtl.add_theme_font_size_override("bold_font_size", 18)
	rtl.add_theme_color_override("default_color", Color(0.85, 0.90, 1.0))
	stats_panel.add_child(rtl)
	add_child(stats_panel)

	# Fade in the panel
	var tw = create_tween()
	tw.tween_property(stats_panel, "modulate:a", 1.0, 1.5)
	await tw.finished
	if not is_inside_tree(): return

	await _show_dialogue("System", "// Chapter 3 complete. Press any key to continue.")
	await _wait_for_input()

# ════════════════════════════════════════════════════════════════════════
# END CHAPTER
# ════════════════════════════════════════════════════════════════════════

func _end_chapter() -> void:
	GameManager.set_story_flag("ch3_complete", true)
	GameManager.ng_plus_available = true
	GameManager.auto_save()

	# Show credits before returning to menu
	if has_node("/root/CreditsScreen"):
		CreditsScreen.show_credits(true)  # Returns to main menu after credits
	else:
		await _fade_to_black(2.0)
		if not is_inside_tree(): return
		SceneTransitions.change_scene("res://scenes/main_menu.tscn")

# ─── Utility ─────────────────────────────────────────────────────────

func _has_elara() -> bool:
	return GameManager.has_elara()

func _has_flag(flag_name: String) -> bool:
	return GameManager.has_flag(flag_name)

func _show_dialogue(speaker: String, text: String) -> void:
	await DialogueManager.say(speaker, text)
	if not is_inside_tree(): return

var _waiting_for_input: bool = false

func _wait_for_input() -> void:
	_waiting_for_input = true
	# FIX: Add 120s timeout to prevent permanent stuck state
	var timeout: float = 0.0
	while _waiting_for_input and timeout < 120.0:
		await get_tree().process_frame
		if not is_inside_tree(): return
		timeout += get_process_delta_time()
		if Input.is_action_just_pressed("ui_accept") or Input.is_action_just_pressed("jump"):
			break
	_waiting_for_input = false

signal _next_input

func _fade_to_black(duration: float) -> void:
	if not is_instance_valid(fade_rect): return
	fade_rect.z_index = 100
	fade_rect.color = Color.BLACK
	fade_rect.modulate = Color(1, 1, 1, 0)
	var tw = create_tween()
	tw.tween_property(fade_rect, "modulate:a", 1.0, duration)
	await tw.finished
	if not is_inside_tree(): return

func _input(event) -> void:
	if event.is_action_pressed("ui_cancel"):
		if has_node("/root/PauseScreen"):
			PauseScreen.toggle_pause()
		return
	# BUG-21-21: Exclude ui_cancel from generic _next_input emission
	# FIX: Support gamepad buttons in addition to keyboard
	if _waiting_for_input and event.is_pressed() and not event.is_echo():
		if (event is InputEventKey or event is InputEventJoypadButton) and not event.is_action("ui_cancel"):
			_next_input.emit()
