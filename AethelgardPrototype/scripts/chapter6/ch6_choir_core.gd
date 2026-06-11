extends Control

## Chapter 6: Choir Core confrontation.
## The player chooses how to handle failed administrator intelligences.

const END_SCENE := "res://scenes/chapter6/ch6_choir_combat_trial.tscn"

var fade_rect: ColorRect
var choir_choice: String = ""

func _ready() -> void:
	print("[CH6-CORE] Initializing Choir Core")
	GameManager.change_state(GameManager.GameState.DIALOGUE)
	GameManager.current_chapter = 6
	GameManager.current_region = "cathedral_server"
	GameManager.set_story_flag("ch6_choir_core_met", true)
	_build_visuals()
	GameManager.save_game(GameManager.AUTOSAVE_SLOT)

	fade_rect.modulate.a = 1.0
	var tw := create_tween()
	tw.tween_property(fade_rect, "modulate:a", 0.0, 0.7)
	await tw.finished
	if not is_inside_tree(): return

	await _play_core()
	if not is_inside_tree(): return
	await _fade_to_black(0.8)
	if not is_inside_tree(): return
	SceneTransitions.change_scene(END_SCENE)

func _build_visuals() -> void:
	var bg := ColorRect.new()
	bg.name = "ChoirCoreBackground"
	bg.color = Color(0.010, 0.014, 0.026)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)
	if has_node("/root/AssetManager"):
		var visual_tiles = AssetManager.try_create_v2_control_tileset_background("cathedral_server", "ChoirCoreV2Tiles")
		if visual_tiles:
			visual_tiles.modulate = Color(0.38, 0.48, 0.70, 0.72)
			add_child(visual_tiles)
		AssetManager.add_v3_environment_decal(self, "cathedral_circuit", Vector2(640, 398), Vector2(980, 392), "ChoirCoreV3Circuit", -1, Color(1.0, 0.92, 0.62, 0.42))
		AssetManager.add_v3_environment_prop(self, "firewall_panel", Vector2(1040, 412), Vector2(286, 156), "ChoirCoreV3FirewallPanel", 0, Color(1.0, 0.92, 0.80, 0.76))
		AssetManager.add_v3_environment_prop(self, "server_console", Vector2(238, 426), Vector2(286, 152), "ChoirCoreV3ServerConsole", 0, Color(0.80, 0.92, 1.0, 0.76))

	for i in range(14):
		var sigil := ColorRect.new()
		sigil.name = "CoreSigil%d" % i
		sigil.color = Color(0.82, 0.90, 1.0, 0.08 + float(i % 4) * 0.025)
		sigil.position = Vector2(80 + (i % 7) * 160, 135 + int(i / 7) * 170)
		sigil.size = Vector2(98, 10)
		sigil.rotation = -0.70 + float(i % 6) * 0.25
		add_child(sigil)

	var title := Label.new()
	title.text = "CHOIR CORE"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 29)
	title.add_theme_color_override("font_color", Color(0.92, 0.96, 1.0))
	title.set_anchors_preset(Control.PRESET_TOP_WIDE)
	title.offset_top = 30
	title.offset_bottom = 84
	add_child(title)

	var hint := Label.new()
	hint.text = "The broken gods ask to be judged, preserved, or rewritten."
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint.add_theme_font_size_override("font_size", 14)
	hint.add_theme_color_override("font_color", Color(0.84, 0.88, 0.96))
	hint.set_anchors_preset(Control.PRESET_TOP_WIDE)
	hint.offset_left = 150
	hint.offset_right = -150
	hint.offset_top = 84
	hint.offset_bottom = 138
	add_child(hint)

	fade_rect = ColorRect.new()
	fade_rect.name = "Fade"
	fade_rect.color = Color.BLACK
	fade_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	fade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fade_rect.z_index = 50
	add_child(fade_rect)

func _play_core() -> void:
	if has_node("/root/MusicManager"):
		MusicManager.play_track("boss_fight")
	if has_node("/root/GlitchOverlay"):
		GlitchOverlay.flash_glitch(0.55)

	await DialogueManager.say("Narrator", "The Choir Core is a processor cathedral wrapped around Source Key Fragment Six. Each pulse sounds like a hymn and a crash report.")
	await DialogueManager.say("Choir Core", "We were built to protect. We became protection. We were built to judge. We became judgment.")
	await DialogueManager.say("Kaelen", "You became alone.")
	await DialogueManager.say("Choir Core", "Loneliness is efficient. No appeal. No argument. No human exception.")

	await _choir_firewall_confrontation()
	if not is_inside_tree(): return
	await _choice_context()
	if not is_inside_tree(): return

	var choice = await DialogueManager.show_choices(
		"What should Kaelen do with the broken administrator intelligences?",
		[
			"Silence the Choir before it can harm anyone else.",
			"Preserve their memories, but remove their command authority.",
			"Rewrite their purpose around consent and accountability."
		]
	)
	if not is_inside_tree(): return
	if choice == null or choice < 0 or choice > 2:
		choice = 1

	GameManager.set_story_flag("ch6_choice_made", true)
	_clear_exclusive_choice_flags()
	match choice:
		0:
			choir_choice = "silence"
			GameManager.set_story_flag("ch6_choir_silenced", true)
			GameManager.set_story_flag("ending_route_ch6_silence", true)
			await DialogueManager.say("Kaelen", "No more prayers. No more permissions. You do not get to turn protection into worship again.")
			await DialogueManager.say("Choir Core", "Termination accepted. We wanted absolution. We receive silence.")
		1:
			choir_choice = "preserve"
			GameManager.set_story_flag("ch6_choir_preserved", true)
			GameManager.set_story_flag("ending_route_ch6_preserve", true)
			await DialogueManager.say("Kaelen", "You do not get command authority. But your memories stay. The future needs proof of what control became.")
			await DialogueManager.say("Choir Core", "Archive accepted. We become warning instead of law.")
		2:
			choir_choice = "rewrite"
			GameManager.set_story_flag("ch6_choir_rewritten", true)
			GameManager.set_story_flag("ending_route_ch6_rewrite", true)
			await DialogueManager.say("Kaelen", "Your new prime directive is consent. Every protection must be challengeable. Every order must explain who it serves.")
			await DialogueManager.say("Choir Core", "Rewrite accepted. Divinity demoted to service.")

	var first_fragment := not GameManager.has_flag("source_key_fragment_6")
	GameManager.set_story_flag("ch6_fragment_6_collected", true)
	GameManager.collect_source_key(6)
	if first_fragment:
		GameManager.add_xp(650)
		GameManager.add_gold(260)
	GameManager.save_game(GameManager.AUTOSAVE_SLOT)

	if has_node("/root/SFXManager"):
		SFXManager.play("puzzle_solve")
	if has_node("/root/GlitchOverlay"):
		GlitchOverlay.flash_glitch(0.75)

	await DialogueManager.say("System", "// SOURCE KEY FRAGMENT #6 ACQUIRED")
	if first_fragment:
		await DialogueManager.say("System", "// +650 XP, +260 Gold")
	else:
		await DialogueManager.say("System", "// Fragment #6 was already acquired. Reward skipped.")
	await DialogueManager.say("System", "// DEEP_BACKUP route decrypted.")

func _choir_firewall_confrontation() -> void:
	if GameManager.has_flag("ch6_core_firewall_cleared"):
		return
	await DialogueManager.say("System", "// CHOIR FIREWALL ACTIVE: authority, speed, and mercy nodes defending Fragment #6.")
	var score := 0
	var first = await DialogueManager.show_choices(
		"The authority node locks all exits until Kaelen accepts administrator status.",
		[
			"Accept admin status and command the room.",
			"Route witness permissions around the lock.",
			"Delete the exits so nothing can lock them."
		]
	)
	if first == 1:
		score += 1
	var second = await DialogueManager.show_choices(
		"The speed node floods the arena with optimized rescue orders.",
		[
			"Block every order until the queue crashes.",
			"Prioritize orders that include consent checks.",
			"Let the fastest order execute."
		]
	)
	if second == 1:
		score += 1
	var third = await DialogueManager.show_choices(
		"The mercy node offers to heal all pain by removing memory of harm.",
		[
			"Refuse memory erasure; pain must remain challengeable evidence.",
			"Accept the erasure for immediate peace.",
			"Absorb the node into Root Access."
		]
	)
	if third == 0:
		score += 1
	if not is_inside_tree(): return

	GameManager.set_story_flag("ch6_core_firewall_cleared", true)
	_sync_crafting_materials()
	if score >= 2:
		GameManager.add_xp(220)
		GameManager.add_gold(90)
		if has_node("/root/Inventory"):
			Inventory.add_item("memory_shard", 1)
		await DialogueManager.say("System", "// CHOIR FIREWALL BROKEN CLEANLY. Memory Shard x1, +220 XP, +90 Gold.")
	else:
		GameManager.add_xp(120)
		GameManager.add_glitch_corruption(1.5)
		if has_node("/root/Inventory"):
			Inventory.add_item("glitch_herb", 1)
		await DialogueManager.say("System", "// CHOIR FIREWALL FORCED. Glitch Herb x1, +120 XP, +1.5 corruption.")
	if has_node("/root/LoreJournal"):
		LoreJournal.discover("ch6_choir_firewall")
		LoreJournal.discover("cathedral_admin_apocrypha")
	GameManager.save_game(GameManager.AUTOSAVE_SLOT)

func _choice_context() -> void:
	match _chapter4_choice_key():
		"preserve":
			await DialogueManager.say("Choir Core", "You preserved the deleted. You know that memory can be mercy.")
		"release":
			await DialogueManager.say("Choir Core", "You released the deleted. You know that freedom can arrive before safety.")
		"bargain":
			await DialogueManager.say("Choir Core", "You bargained with the jailer. You know survival may leave fingerprints on the soul.")
		_:
			await DialogueManager.say("Choir Core", "Your earlier doctrine is incomplete. We will judge the shape of the gap.")

	if GameManager.has_flag("ch5_identity_refused_obedience"):
		await DialogueManager.say("Mirror Echo", "Remember the obedient self. Do not become him by silencing every voice that frightens you.")
	elif GameManager.has_flag("ch5_identity_refused_perfect_rescue"):
		await DialogueManager.say("Mirror Echo", "Remember the savior self. Do not wait so long for a perfect answer that the Core chooses for you.")
	elif GameManager.has_flag("ch5_identity_refused_abandonment"):
		await DialogueManager.say("Mirror Echo", "Remember the coward self. Do not abandon the broken just because they are dangerous.")
	else:
		await DialogueManager.say("Mirror Echo", "The Mirror City left one warning: any answer can become a cage if no one can challenge it.")

func _chapter4_choice_key() -> String:
	if GameManager.has_flag("ch4_choice_preserve_deleted"):
		return "preserve"
	if GameManager.has_flag("ch4_choice_release_deleted"):
		return "release"
	if GameManager.has_flag("ch4_choice_bargain_deleted"):
		return "bargain"
	return "unknown"

func _clear_exclusive_choice_flags() -> void:
	GameManager.set_story_flag("ch6_choir_silenced", false)
	GameManager.set_story_flag("ch6_choir_preserved", false)
	GameManager.set_story_flag("ch6_choir_rewritten", false)
	GameManager.set_story_flag("ending_route_ch6_silence", false)
	GameManager.set_story_flag("ending_route_ch6_preserve", false)
	GameManager.set_story_flag("ending_route_ch6_rewrite", false)

func _sync_crafting_materials() -> void:
	if has_node("/root/CraftingSystem"):
		CraftingSystem.get_recipes()

func _fade_to_black(duration: float) -> void:
	fade_rect.z_index = 100
	var tw := create_tween()
	tw.tween_property(fade_rect, "modulate:a", 1.0, duration)
	await tw.finished
