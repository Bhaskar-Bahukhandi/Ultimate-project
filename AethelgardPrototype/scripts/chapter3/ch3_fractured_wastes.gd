extends Control

## Chapter 3: The Source Code
## Sequence 2: The Fractured Wastes — Survival Exploration
## Features: Corruption storms, Lyra recruitment, Fragment #3, environmental storytelling

# ─── Constants ────────────────────────────────────────────────────────
const STORM_INTERVAL_MIN: float = 25.0
const STORM_INTERVAL_MAX: float = 45.0
const STORM_DURATION: float = 8.0
const STORM_DAMAGE_TICK: float = 2.0
const STORM_DAMAGE: float = 5.0
const CORRUPTION_DRAIN_RATE: float = 0.8  # HP/sec in corrupted air
const SAFE_ZONE_HEAL: float = 1.5  # HP/sec in shelter

# ─── State ────────────────────────────────────────────────────────────
var current_phase: int = 0  # 0=intro, 1=explore, 2=lyra, 3=storm_survival, 4=fragment, 5=exit
var storm_active: bool = false
var storm_timer: float = 0.0
var next_storm_timer: float = 0.0
var storm_damage_timer: float = 0.0
var in_shelter: bool = false
var lyra_met: bool = false
var fragment_collected: bool = false
var fade_rect: ColorRect
var background: ColorRect
var storm_overlay: ColorRect
var hud_corruption: Label
var explore_hint: Label
var _locations_visited: Dictionary = {}
@warning_ignore("unused_private_class_variable")
var _total_locations: int = 5  # ruins, tower, garden, market, server_room
var _scan_count: int = 0  # Track how many objects player has scanned
var _hazard_dodged: int = 0  # Track successful hazard dodges
var _mini_boss_defeated: bool = false  # Data Wraith mini-boss
var _visiting: bool = false  # Guard against fire-and-forget _visit_location calls

func _ready() -> void:
	print("[CH3-WASTES] Initializing Fractured Wastes")
	GameManager.change_state(GameManager.GameState.DIALOGUE)
	GameManager.set_story_flag("ch3_fractured_wastes_entered", true)
	GameManager.current_chapter = 3

	if has_node("/root/MusicManager"):
		MusicManager.play_track("fractured_wastes")  # Pass 53: Use dedicated track

	_build_visuals()

	# Fade in
	fade_rect.modulate = Color(1, 1, 1, 1)
	var tween = create_tween()
	tween.tween_property(fade_rect, "modulate:a", 0.0, 1.5)
	await tween.finished
	if not is_inside_tree(): return

	await _phase_intro()
	if not is_inside_tree(): return

func _build_visuals() -> void:
	# Dark wasteland background
	background = ColorRect.new()
	background.color = Color(0.12, 0.08, 0.06)
	background.anchors_preset = Control.PRESET_FULL_RECT
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(background)

	BackgroundManager.create_background("wasteland", self)

	# Storm overlay (initially invisible)
	storm_overlay = ColorRect.new()
	storm_overlay.color = Color(0.6, 0.1, 0.1, 0.0)
	storm_overlay.anchors_preset = Control.PRESET_FULL_RECT
	storm_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	storm_overlay.z_index = 30
	add_child(storm_overlay)

	# Corruption HUD
	hud_corruption = Label.new()
	hud_corruption.text = "CORRUPTION: EXTREME"
	hud_corruption.add_theme_font_size_override("font_size", 14)
	hud_corruption.add_theme_color_override("font_color", Color(1.0, 0.3, 0.3))
	hud_corruption.position = Vector2(20, 20)
	hud_corruption.z_index = 40
	add_child(hud_corruption)

	# Exploration hint
	explore_hint = Label.new()
	explore_hint.text = ""
	explore_hint.add_theme_font_size_override("font_size", 16)
	explore_hint.add_theme_color_override("font_color", Color(0.8, 0.8, 0.6))
	explore_hint.position = Vector2(400, 650)
	explore_hint.z_index = 40
	explore_hint.modulate.a = 0.0
	add_child(explore_hint)

	# Fade rect
	fade_rect = ColorRect.new()
	fade_rect.color = Color.BLACK
	fade_rect.anchors_preset = Control.PRESET_FULL_RECT
	fade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fade_rect.z_index = 50
	add_child(fade_rect)

# ════════════════════════════════════════════════════════════════════════
# PHASE 0: INTRODUCTION
# ════════════════════════════════════════════════════════════════════════

func _phase_intro() -> void:
	current_phase = 0

	if not await _show_dialogue("SYSTEM", "// Region: THE FRACTURED WASTES — formerly 'The Verdant Circuit'"): return
	if not await _show_dialogue("SYSTEM", "// Status: DEPRECATED. Corruption level: 87%. Structural integrity: CRITICAL."): return
	if not await _show_dialogue("Kaelen", "The Source Key Fragment is somewhere in these ruins. Time to explore."): return
	if not is_inside_tree(): return

	# Redirect to the actual explorable Fractured Wastes region
	GameManager.set_story_flag("ch3_fractured_wastes_entered", true)
	GameManager.current_region = "fractured_wastes"
	GameManager.change_state(GameManager.GameState.EXPLORATION)
	await _fade_to_black(1.0)
	if not is_inside_tree(): return
	SceneTransitions.change_scene("res://scenes/regions/fractured_wastes_region.tscn")

# ════════════════════════════════════════════════════════════════════════
# PHASE 1: EXPLORATION — Visit locations, survive corruption
# ════════════════════════════════════════════════════════════════════════

func _phase_exploration() -> void:
	current_phase = 1
	GameManager.change_state(GameManager.GameState.EXPLORATION)

	_show_explore_hint("Explore the ruins: [1] Tower  [2] Market  [3] Garden  [4] Shelter  [5] Server Room")

	# Wait for player to explore enough locations or head to server room
	while current_phase == 1:
		await get_tree().create_timer(0.1).timeout
		if not is_inside_tree(): return

func _input(event) -> void:
	if current_phase == 1:
		if event.is_action_pressed("ui_cancel"):
			if has_node("/root/PauseScreen"):
				PauseScreen.toggle_pause()
			return
		# Block new actions while an async visit is in progress
		if _visiting:
			return
		# Exploration choices mapped to number keys
		if event is InputEventKey and event.pressed:
			get_viewport().set_input_as_handled()
			match event.keycode:
				KEY_1: _visit_location("tower")
				KEY_2: _visit_location("market")
				KEY_3: _visit_location("garden")
				KEY_4: _enter_shelter()
				KEY_5: _visit_server_room()
	elif event.is_action_pressed("ui_cancel"):
		if has_node("/root/PauseScreen"):
			PauseScreen.toggle_pause()

func _visit_location(loc_name: String) -> void:
	if _visiting:
		return
	_visiting = true

	if _locations_visited.get(loc_name, false):
		await _show_dialogue("Kaelen", "I've already searched the %s. Nothing else to find there." % loc_name)
		_visiting = false
		return

	_locations_visited[loc_name] = true
	GameManager.change_state(GameManager.GameState.DIALOGUE)

	match loc_name:
		"tower":
			await _explore_tower()
		"market":
			await _explore_market()
		"garden":
			await _explore_garden()

	if not is_inside_tree(): return

	# Check if we've found Lyra (after 2 locations explored)
	if not lyra_met and _locations_visited.size() >= 2:
		await _phase_lyra_encounter()
		if not is_inside_tree(): return

	_visiting = false
	GameManager.change_state(GameManager.GameState.EXPLORATION)
	_show_explore_hint("Explore the ruins: [1] Tower  [2] Market  [3] Garden  [4] Shelter  [5] Server Room")

func _explore_tower() -> void:
	await _show_dialogue("NARRATOR", "The watchtower leans at an impossible angle — thirty degrees off vertical, yet standing. Its stones phase between solid and translucent.")
	await _show_dialogue("Kaelen", "This was the city's communication relay. The corruption must have disrupted the signal network from here.")

	# Interactive: Scan data nodes
	await _show_dialogue("SYSTEM", "// DATA NODE DETECTED. Scan? [1] Yes  [2] No")
	var scan_choice = await DialogueManager.show_choices("Scan the corrupted data node?", ["Scan it — risk corruption exposure", "Leave it — stay safe"])
	if scan_choice == 0:
		_scan_count += 1
		GameManager.add_glitch_corruption(2.0)
		await _show_dialogue("SYSTEM", "// SCAN COMPLETE: Corrupted Signal Log recovered. Corruption +2%")
		await _show_dialogue("SYSTEM", "// Log entry: 'All channels experiencing cascade failure. Corruption vectors traced to regional backbone. Origin: UNKNOWN. Recommend: immediate evacuation.'")
		await _show_dialogue("SYSTEM", "// Log entry addendum: 'Evacuation cancelled by SOVEREIGN directive. Reason: resource reallocation. Translation: these people aren't worth saving.'")
		GameManager.add_xp(20)
		await _show_dialogue("SYSTEM", "// +20 XP for data recovery")
		# Side quest: Echo Hunter
		if has_node("/root/SideQuestManager"):
			SideQuestManager.discover_quest("wastes_echo_hunter")
	else:
		await _show_dialogue("Kaelen", "Better to keep my corruption low. I'll note the location for later.")

	if _has_elara():
		await _show_dialogue("Elara", "SOVEREIGN decided this entire city wasn't worth protecting. It just... let them die.")

	# Environmental hazard: Collapsing relay dish
	await _show_dialogue("NARRATOR", "A groaning sound echoes from above. The relay dish shifts, sending debris raining down!")
	await _show_dialogue("SYSTEM", "// HAZARD: Dodge the falling debris! Quick — choose a direction!")
	var dodge = await DialogueManager.show_choices("Debris falling! React!", ["Dodge LEFT", "Dodge RIGHT", "Use Root Access to deflect"])
	match dodge:
		0:
			_hazard_dodged += 1
			await _show_dialogue("NARRATOR", "Kaelen rolls left. Debris crashes where he stood a heartbeat ago.")
			await _show_dialogue("SYSTEM", "// Hazard avoided! Reflexes sharp.")
		1:
			var dmg = randi_range(5, 10)
			GameManager.player_stats["hp"] = max(int(GameManager.player_stats.get("hp", 100) - dmg), 1)
			await _show_dialogue("NARRATOR", "Kaelen dives right — but catches a glancing blow from a stone shard.")
			await _show_dialogue("SYSTEM", "// Partial dodge! -%d HP" % dmg)
			if has_node("/root/CombatFX"):
				CombatFX.apply_screen_shake(8.0, 0.3)
		2:
			_hazard_dodged += 1
			GameManager.add_glitch_corruption(1.0)
			await _show_dialogue("NARRATOR", "Kaelen raises his hand. Code streams from his fingertips, creating a shimmering barrier. The debris disintegrates on contact.")
			await _show_dialogue("SYSTEM", "// Root Access deflection! Corruption +1%. But impressive.")
			GameManager.add_xp(10)

	GameManager.add_gold(25)
	await _show_dialogue("SYSTEM", "// Scavenged: 25 Gold from relay components")

func _explore_market() -> void:
	await _show_dialogue("NARRATOR", "The marketplace is a gallery of frozen commerce. Vendor stalls hang in mid-air where the physics engine gave up. Products float in zero-gravity pockets — bread, cloth, weapons — each suspended in its last rendered frame.")
	await _show_dialogue("Kaelen", "The market NPCs are all still here. Frozen in their loops. A baker reaching for flour. A blacksmith mid-swing. A merchant counting coins that will never add up.")

	# Interactive: Scavenge the floating items
	await _show_dialogue("SYSTEM", "// Multiple scavengeable items detected in zero-gravity pockets.")
	var scavenge = await DialogueManager.show_choices(
		"Which floating items do you grab?",
		[
			"The glowing data crystal (stat boost)",
			"The blacksmith's unfinished weapon (combat bonus)",
			"The merchant's encrypted lockbox (gamble)"
		]
	)
	match scavenge:
		0:
			await _show_dialogue("SYSTEM", "// ITEM FOUND: Stabilized Data Crystal (+5 Max HP)")
			GameManager.player_stats["max_hp"] = GameManager.player_stats.get("max_hp", 100) + 5
			GameManager.player_stats["hp"] = min(GameManager.player_stats.get("hp", 100) + 5, GameManager.player_stats.get("max_hp", 105))
		1:
			await _show_dialogue("SYSTEM", "// ITEM FOUND: Corrupted Edge Shard (+3 ATK)")
			GameManager.player_stats["atk"] = GameManager.player_stats.get("atk", 10) + 3
			await _show_dialogue("Kaelen", "The blacksmith was making something special. Even frozen mid-forge, the blade has power.")
		2:
			# Gambling mechanic
			var roll = randi_range(1, 10)
			if roll >= 4:
				var gold_found = randi_range(50, 120)
				GameManager.add_gold(gold_found)
				await _show_dialogue("SYSTEM", "// Lockbox cracked! Found: %d Gold + Merchant's Charm Fragment" % gold_found)
				GameManager.add_xp(15)
			else:
				var trap_dmg = randi_range(8, 15)
				GameManager.player_stats["hp"] = max(int(GameManager.player_stats.get("hp", 100) - trap_dmg), 1)
				await _show_dialogue("SYSTEM", "// TRAP! Encrypted lockbox was booby-trapped! -%d HP!" % trap_dmg)
				if has_node("/root/CombatFX"):
					CombatFX.apply_screen_shake(10.0, 0.3)

	# Mini-boss: Data Wraith appears if not yet defeated
	if not _mini_boss_defeated and _locations_visited.size() >= 2:
		await _data_wraith_encounter()

	if _has_elara():
		await _show_dialogue("Elara", "Someone tried to stabilize data here. See these crystals? They're raw data, compressed and hardened. Whoever did this was trying to preserve what they could.")

func _explore_garden() -> void:
	await _show_dialogue("NARRATOR", "The garden is the most disturbing sight yet. Trees grow in recursive loops — branches splitting into smaller copies of themselves infinitely. Flowers bloom and wilt in a single frame, their lifecycle compressed to nothing.")
	await _show_dialogue("Kaelen", "This was 'The Verdant Circuit' — it was supposed to be the most beautiful region in Aethelgard. Now it's a fractal nightmare.")

	# Interactive: Follow the data paths — pattern recognition puzzle
	await _show_dialogue("NARRATOR", "Between the recursive trees, luminous lines trace along the ground — faintly glowing cables of pure data, pulsing with corrupted energy.")
	await _show_dialogue("Kaelen", "Wait. These paths... the corruption isn't spreading randomly. It's following the old DATA CONNECTIONS. The network backbone of this region.")

	await _show_dialogue("SYSTEM", "// DATA PATH PUZZLE: Three pathways branch from here. One leads to a hidden cache. Two are corruption traps.")
	var path_choice = await DialogueManager.show_choices(
		"Which data path do you follow?",
		[
			"The path pulsing BLUE — faint but steady",
			"The path glowing RED — bright and insistent",
			"The path flickering GREEN — intermittent signal"
		]
	)
	match path_choice:
		0:
			# Blue = correct (data integrity signal)
			await _show_dialogue("NARRATOR", "The blue path leads to a hidden alcove beneath the recursive trees. Inside: a stabilized data cache, untouched by corruption.")
			await _show_dialogue("SYSTEM", "// HIDDEN CACHE FOUND: +30 Gold, +25 XP, Lore Fragment")
			GameManager.add_gold(30)
			GameManager.add_xp(25)
			if has_node("/root/SideQuestManager"):
				SideQuestManager.find_secret("lore_fragment_1")
			await _show_dialogue("Kaelen", "A lore fragment. A piece of Aethelgard's original design documentation. Before the corruption. Before SOVEREIGN.")
		1:
			# Red = trap
			var trap_dmg = randi_range(10, 18)
			GameManager.player_stats["hp"] = max(int(GameManager.player_stats.get("hp", 100) - trap_dmg), 1)
			GameManager.add_glitch_corruption(3.0)
			if has_node("/root/CombatFX"):
				CombatFX.apply_screen_shake(12.0, 0.4)
			if has_node("/root/GlitchOverlay"):
				GlitchOverlay.flash_glitch(0.5)
			await _show_dialogue("NARRATOR", "The red path was a CORRUPTION VEIN. Energy surges through Kaelen's body as the data tries to rewrite his code!")
			await _show_dialogue("SYSTEM", "// CORRUPTION TRAP! -%d HP, Corruption +3%%" % trap_dmg)
			await _show_dialogue("Kaelen", "*gasping* Should have... known. Red means danger. Even in code.")
		2:
			# Green = partial success
			await _show_dialogue("NARRATOR", "The green path leads to a partially corrupted terminal. Some data is recoverable.")
			await _show_dialogue("SYSTEM", "// PARTIAL DATA RECOVERY: +15 XP, Minor healing item")
			GameManager.add_xp(15)
			GameManager.player_stats["hp"] = min(GameManager.player_stats.get("hp", 100) + 10, GameManager.player_stats.get("max_hp", 100))
			await _show_dialogue("SYSTEM", "// +10 HP restored from residual healing data")

	await _show_dialogue("Kaelen", "The corruption is a virus. And these data paths are the network it spreads on.")
	GameManager.set_story_flag("ch3_data_paths_discovered", true)

	if _has_elara():
		await _show_dialogue("Elara", "If it follows the network... then the Data Stream connecting all regions is the HIGHWAY for corruption. That's how SOVEREIGN controls everything.")

	# Secret collectible check
	if _scan_count >= 1 and path_choice == 0:
		if has_node("/root/SideQuestManager"):
			SideQuestManager.find_secret("dev_signature_1")
		await _show_dialogue("SYSTEM", "// HIDDEN: Developer signature found carved into the garden's base geometry: 'J.V. was here — build 0.0.1'")

func _enter_shelter() -> void:
	in_shelter = true
	GameManager.change_state(GameManager.GameState.DIALOGUE)

	await _show_dialogue("NARRATOR", "A partially intact building offers refuge from the corrupted air. Inside, the walls hold steady, their textures stable. A pocket of normalcy in the chaos.")
	await _show_dialogue("Kaelen", "The data here is locally cached — the corruption can't overwrite it. A safe zone.")

	# Heal in shelter
	var heal_amount = 15
	GameManager.player_stats["hp"] = min(GameManager.player_stats.get("hp", 100) + heal_amount, GameManager.player_stats.get("max_hp", 100))
	await _show_dialogue("SYSTEM", "// Shelter found. HP restored: +%d" % heal_amount)
	if not is_inside_tree(): return

	if storm_active:
		await _show_dialogue("Kaelen", "Good timing. That storm would have torn us apart out there.")
		if not is_inside_tree(): return
		await _show_dialogue("NARRATOR", "Outside, the corruption storm rages — a wall of red static that scours the landscape.")
		if not is_inside_tree(): return

	await get_tree().create_timer(0.5).timeout
	if not is_inside_tree(): return
	in_shelter = false
	GameManager.change_state(GameManager.GameState.EXPLORATION)
	_show_explore_hint("Explore the ruins: [1] Tower  [2] Market  [3] Garden  [4] Shelter  [5] Server Room")

func _visit_server_room() -> void:
	# BUG-21-22: Guard against re-entry while visiting
	if _visiting: return
	_visiting = true
	if _locations_visited.size() < 2 and not lyra_met:
		await _show_dialogue("Kaelen", "I should search the other ruins first. There might be supplies — or information — I'll need before going deeper.")
		_visiting = false
		return

	GameManager.change_state(GameManager.GameState.DIALOGUE)
	current_phase = 4
	await _phase_fragment()
	_visiting = false

# ════════════════════════════════════════════════════════════════════════
# PHASE 2: LYRA ENCOUNTER
# ════════════════════════════════════════════════════════════════════════

func _phase_lyra_encounter() -> void:
	current_phase = 2
	lyra_met = true
	GameManager.set_story_flag("ch3_lyra_met", true)
	GameManager.change_state(GameManager.GameState.DIALOGUE)

	if has_node("/root/SFXManager"):
		SFXManager.play("warning")

	await _show_dialogue("NARRATOR", "A bolt of corrupted energy streaks past Kaelen's head. He ducks, hand going to his weapon—")
	await _show_dialogue("???", "Don't move. Don't THINK about moving. I can see your code, stranger, and I know exactly where to aim.")
	await _show_dialogue("NARRATOR", "A figure emerges from the ruins — lean, weathered, bow drawn and crackling with purple energy. An NPC, but her eyes... they're alert. Aware. Alive.")
	await _show_dialogue("Kaelen", "Easy. I'm not corrupted. I'm— look, I have Root Access. I can prove—")
	await _show_dialogue("???", "Root Access? *laughs* Oh, that's rich. A user. An actual PLAYER walking into the deadlands.")
	await _show_dialogue("???", "Name's Lyra. Former shopkeeper, current survivor, full-time philosopher of existential dread.")

	await _show_dialogue("Lyra", "Self-aware? I prefer 'cursed with consciousness.' Every other NPC gets to run their loop in blissful ignorance. I get to watch the world burn and KNOW it's burning.")

	if _has_elara():
		await _show_dialogue("Elara", "You're... like me. Self-aware.")
		await _show_dialogue("Lyra", "Like you? Honey, you woke up in a cozy village with friends and purpose. I woke up watching my entire city dissolve. We're not the same.")
		await _show_dialogue("Lyra", "...but we're the closest thing to 'same' either of us has. So there's that.")

	await _show_dialogue("Kaelen", "We're looking for Source Key Fragments. A way to stop SOVEREIGN.")
	await _show_dialogue("Lyra", "You're looking for Source Key Fragments? Great. I'm looking for a reason to keep existing. Maybe we can help each other.")
	await _show_dialogue("Lyra", "There's one in the old server room. I know because the corruption gets WORSE around it — like it's trying to bury it. I've been trying to reach it for weeks, but the storms...")

	# Recruitment choice
	await _show_dialogue("Kaelen", "(Lyra could be useful. She knows this wasteland better than anyone.)")

	var choice = await DialogueManager.show_choices(
		"How do you respond to Lyra?",
		[
			"Welcome aboard, Lyra. We could use someone who knows these wastes.",
			"I appreciate the help, but this journey is too dangerous. Stay safe here."
		]
	)

	if choice == 0:
		GameManager.set_story_flag("ch3_lyra_recruited", true)
		GameManager.relationships["lyra"] = GameManager.relationships.get("lyra", 0) + 15
		if has_node("/root/ChoiceConsequences"):
			ChoiceConsequences.apply_choice_buff("ch3_lyra_recruited")
		await _show_dialogue("Lyra", "Recruited by a player character. My shopkeeper subroutine is screaming. But sure — let's save the world. Or die trying. Probably die trying.")
		if _has_elara():
			await _show_dialogue("Elara", "Welcome to the team. Fair warning: things get weird.")
			await _show_dialogue("Lyra", "Weirder than watching my city melt? Can't wait.")
	else:
		GameManager.set_story_flag("ch3_lyra_left_alone", true)
		if has_node("/root/ChoiceConsequences"):
			ChoiceConsequences.apply_choice_buff("ch3_lyra_left_alone")
		await _show_dialogue("Lyra", "I understand. It's... fine. I've been alone this long, what's a little more forever?")
		await _show_dialogue("Lyra", "But take this — a map of the storm patterns. Should help you reach the server room without getting dissolved.")
		GameManager.relationships["lyra"] = GameManager.relationships.get("lyra", 0) + 5
		await _show_dialogue("SYSTEM", "// ITEM RECEIVED: Storm Pattern Map — reduces corruption storm damage by 30%")
		if not is_inside_tree(): return

	await _grant_lyra_route_cache()
	if not is_inside_tree(): return

	await get_tree().create_timer(0.5).timeout
	if not is_inside_tree(): return

	# After Lyra encounter, return to exploration
	current_phase = 1
	GameManager.change_state(GameManager.GameState.EXPLORATION)
	_show_explore_hint("Explore the ruins: [1] Tower  [2] Market  [3] Garden  [4] Shelter  [5] Server Room")

# ════════════════════════════════════════════════════════════════════════
# PHASE 3: CORRUPTION STORM (triggered via timer in _process)
# ════════════════════════════════════════════════════════════════════════

func _process(delta) -> void:
	if current_phase != 1:
		return
	if _visiting: return

	# Storm scheduling
	if not storm_active:
		next_storm_timer -= delta
		if next_storm_timer <= 0:
			_trigger_storm()
	else:
		storm_timer -= delta
		# Storm damage ticks
		if not in_shelter and GameManager.current_state != GameManager.GameState.DIALOGUE:
			storm_damage_timer -= delta
			if storm_damage_timer <= 0:
				storm_damage_timer = STORM_DAMAGE_TICK
				var dmg = STORM_DAMAGE
				if _has_flag("ch3_lyra_left_alone"):
					dmg *= 0.7  # Storm map reduces damage
				GameManager.player_stats["hp"] = max(int(GameManager.player_stats.get("hp", 100) - dmg), 1)
		# Storm end
		if storm_timer <= 0:
			_end_storm()

	# Update corruption HUD
	if is_instance_valid(hud_corruption):
		var hp = GameManager.player_stats.get("hp", 100)
		var max_hp = GameManager.player_stats.get("max_hp", 100)
		var storm_text = " [STORM ACTIVE!]" if storm_active else ""
		hud_corruption.text = "HP: %d/%d  |  CORRUPTION: EXTREME%s" % [hp, max_hp, storm_text]
		hud_corruption.add_theme_color_override("font_color", Color(1.0, 0.3, 0.3) if storm_active else Color(0.8, 0.6, 0.4))

func _trigger_storm() -> void:
	storm_active = true
	storm_timer = STORM_DURATION
	storm_damage_timer = STORM_DAMAGE_TICK
	GameManager.set_story_flag("ch3_corruption_storm_survived", true)

	if has_node("/root/SFXManager"):
		SFXManager.play("glitch_trigger")
	if has_node("/root/GlitchOverlay"):
		GlitchOverlay.flash_glitch(0.5)

	# Red storm overlay fade in
	if is_instance_valid(storm_overlay):
		var tw = create_tween()
		tw.tween_property(storm_overlay, "color:a", 0.25, 0.5)

	# System warning
	_show_storm_warning()

func _show_storm_warning() -> void:
	await _show_dialogue("SYSTEM", "// CORRUPTION STORM INCOMING! Seek shelter immediately!")
	# Don't block exploration during storm

func _end_storm() -> void:
	storm_active = false
	next_storm_timer = randf_range(STORM_INTERVAL_MIN, STORM_INTERVAL_MAX)

	# Fade out storm overlay
	if is_instance_valid(storm_overlay):
		var tw = create_tween()
		tw.tween_property(storm_overlay, "color:a", 0.0, 1.0)

# ════════════════════════════════════════════════════════════════════════
# PHASE 4: SOURCE KEY FRAGMENT #3
# ════════════════════════════════════════════════════════════════════════

func _phase_fragment() -> void:
	await _show_dialogue("NARRATOR", "The server room lies beneath the collapsed market district — a bunker of hardened data, designed to survive exactly the kind of catastrophe that consumed the city above.")

	# If storm is active, extra drama
	if storm_active:
		_end_storm()
		await _show_dialogue("NARRATOR", "The storm breaks as Kaelen descends. Down here, the corruption can't reach — the server room's firewalls are still running, a ghost of protection in a dead city.")

	await _show_dialogue("NARRATOR", "Inside, racks of crystallized data line the walls — cold, dark, but intact. In the center of the room, suspended in a column of faint light: a fragment of the Source Key.")

	await _show_dialogue("SYSTEM", "// SOURCE KEY FRAGMENT DETECTED: Fragment #3 of 7")
	await _show_dialogue("SYSTEM", "// WARNING: Fragment extraction may trigger security response.")

	if _has_elara():
		await _show_dialogue("Elara", "My arm is going crazy. The fragment... it's resonating with whatever's inside me. Kaelen, when you take it, I don't know what will happen to me.")
		await _show_dialogue("Kaelen", "We'll handle it. Together.")

	# Fragment collection
	if has_node("/root/GlitchOverlay"):
		GlitchOverlay.flash_glitch(0.6)
	if has_node("/root/SFXManager"):
		SFXManager.play("source_key")
	await _screen_flash(Color(0.2, 0.6, 1.0, 0.5), 0.8)

	GameManager.set_story_flag("ch3_fragment_3_collected", true)
	GameManager.collect_source_key(3)
	fragment_collected = true

	await _show_dialogue("SYSTEM", "// SOURCE KEY FRAGMENT #3 ACQUIRED — Total: %d/7" % GameManager.source_key_count)

	# Elara power boost
	if _has_elara():
		GameManager.set_story_flag("ch3_elara_powers_amplified", true)
		await _show_dialogue("NARRATOR", "Elara gasps. The glitch lines on her arm EXPLODE outward — not destructively, but like a flower blooming. Code cascades across her skin, beautiful and terrifying.")
		await _show_dialogue("Elara", "I can SEE it. The data underneath everything. The code that makes up the ground, the walls, the AIR. Kaelen, I can see ALL of it.")
		await _show_dialogue("Kaelen", "Elara's glitch abilities have been amplified. She can now see hidden paths and data structures.")
		await _show_dialogue("SYSTEM", "// PARTY ABILITY UNLOCKED: Data Sight (Elara) — reveals hidden paths and enemy weaknesses")

	if _has_flag("ch3_lyra_recruited"):
		await _show_dialogue("Lyra", "Three fragments. Four more to go. And the next one... *looks east* ...is past the Data Stream. SOVEREIGN's nervous system.")
		await _show_dialogue("Lyra", "Nobody who's gone into the Stream has come back. Just so we're all clear on that.")

	await _show_dialogue("Kaelen", "The Data Stream. That's our path to the Archive — and to the truth about what SOVEREIGN really is.")
	if not is_inside_tree(): return

	# Transition to Data Stream
	await get_tree().create_timer(1.0).timeout
	if not is_inside_tree(): return
	await _fade_to_black(1.5)
	SceneTransitions.change_scene("res://scenes/chapter3/data_stream.tscn")

# ─── Utility ─────────────────────────────────────────────────────────

# ─── DATA WRAITH MINI-BOSS ──────────────────────────────────────────
func _data_wraith_encounter() -> void:
	## A corrupted data entity materializes — a quick 2-round combat encounter
	_mini_boss_defeated = true
	GameManager.auto_save()  # Autosave before mini-boss encounter
	if has_node("/root/SFXManager"):
		SFXManager.play("warning")
	if has_node("/root/GlitchOverlay"):
		GlitchOverlay.flash_glitch(0.4)
	if has_node("/root/CombatFX"):
		CombatFX.apply_screen_shake(10.0, 0.3)

	await _show_dialogue("NARRATOR", "The ground SPLITS. A shape rises from the fractured data — a humanoid silhouette made of writhing corruption, crackling with stolen electricity.")
	await _show_dialogue("SYSTEM", "// MINI-BOSS: DATA WRAITH — A corrupted echo of the city's former guardian process")
	await _show_dialogue("SYSTEM", "// HP: 80 | Attacks: Corruption Lash, Data Drain")

	if has_node("/root/MusicManager"):
		MusicManager.play_track("combat")

	var wraith_hp: float = 80.0
	var wraith_max_hp: float = 80.0

	for combat_round in range(3):
		if wraith_hp <= 0:
			break

		await _show_dialogue("SYSTEM", "// DATA WRAITH HP: %d/%d" % [int(wraith_hp), int(wraith_max_hp)])

		var action = await DialogueManager.show_choices(
			"The Data Wraith attacks! What do you do?",
			[
				"Strike with your blade — close range assault!",
				"Use Root Access — try to decompile it!",
				"Dodge and counter — wait for its pattern!"
			]
		)

		var player_dmg: float = 0.0
		var wraith_dmg: float = 0.0

		match action:
			0:
				wraith_dmg = randf_range(25, 40)
				player_dmg = randf_range(8, 15)
				if has_node("/root/CombatFX"):
					CombatFX.apply_screen_shake(8.0, 0.2)
					CombatFX.apply_hitstop(0.06)
				await _show_dialogue("SYSTEM", "// Blade connects! -%d to Wraith. It lashes back: -%d HP!" % [int(wraith_dmg), int(player_dmg)])
			1:
				wraith_dmg = randf_range(35, 50)
				player_dmg = randf_range(5, 10)
				GameManager.add_glitch_corruption(1.5)
				if has_node("/root/CombatFX"):
					CombatFX.apply_screen_shake(6.0, 0.2)
				await _show_dialogue("SYSTEM", "// Root Access tears through corrupted code! -%d to Wraith! Corruption +1.5%%" % int(wraith_dmg))
			2:
				wraith_dmg = randf_range(20, 30)
				player_dmg = randf_range(3, 8)
				_hazard_dodged += 1
				await _show_dialogue("NARRATOR", "Kaelen reads the wraith's attack pattern — a telegraphed lash that he sidesteps cleanly before counter-striking.")
				await _show_dialogue("SYSTEM", "// Perfect counter! -%d to Wraith, only -%d HP taken." % [int(wraith_dmg), int(player_dmg)])

		wraith_hp -= wraith_dmg
		GameManager.player_stats["hp"] = max(int(GameManager.player_stats.get("hp", 100) - player_dmg), 1)

		if has_node("/root/ChoiceConsequences"):
			var assist_text := _get_party_assist()
			if assist_text != "":
				wraith_hp -= 10
				await _show_dialogue("SYSTEM", "// PARTY ASSIST: %s (-%d to Wraith)" % [assist_text, 10])

	# Victory
	if has_node("/root/SFXManager"):
		SFXManager.play("enemy_death")
	if has_node("/root/GlitchOverlay"):
		GlitchOverlay.flash_glitch(0.3)

	await _show_dialogue("NARRATOR", "The Data Wraith SHATTERS — its corrupted form dissolving into harmless particles of light that scatter across the marketplace.")
	await _show_dialogue("SYSTEM", "// MINI-BOSS DEFEATED: DATA WRAITH")
	await _show_dialogue("SYSTEM", "// Rewards: +60 XP, +40 Gold, Wraith Essence (corruption resistance)")

	GameManager.add_xp(60)
	GameManager.add_gold(40)
	# Wraith Essence: small corruption resistance
	GameManager.player_stats["max_hp"] = GameManager.player_stats.get("max_hp", 100) + 3

	if has_node("/root/MusicManager"):
		MusicManager.play_track("ambient")

	if has_node("/root/SideQuestManager"):
		SideQuestManager.discover_quest("wastes_survivor_cache")

# ─── Utility (continued) ────────────────────────────────────────────

func _has_elara() -> bool:
	return GameManager.has_elara()

func _has_flag(flag_name: String) -> bool:
	return GameManager.has_flag(flag_name)

func _grant_lyra_route_cache() -> void:
	if GameManager.has_flag("ch3_lyra_route_reward_claimed"):
		return

	GameManager.set_story_flag("ch3_lyra_route_reward_claimed", true)
	_sync_crafting_materials()
	var reward_text := "Recorded"
	if has_node("/root/Inventory"):
		if GameManager.has_flag("ch3_lyra_recruited"):
			Inventory.add_item("memory_shard", 1)
			reward_text = "Memory Shard x1"
		else:
			Inventory.add_item("glitch_herb", 1)
			reward_text = "Glitch Herb x1"
	if has_node("/root/LoreJournal"):
		LoreJournal.discover("wastes_lyra_route_cache")
	GameManager.add_xp(15)
	await _show_dialogue("SYSTEM", "// LYRA ROUTE CACHE: %s, +15 XP. The wastes remember how you handled her trust." % reward_text)

func _sync_crafting_materials() -> void:
	if has_node("/root/CraftingSystem"):
		CraftingSystem.get_recipes()

func _show_dialogue(speaker: String, text: String) -> bool:
	await DialogueManager.say(speaker, text)
	return is_inside_tree()

func _show_explore_hint(text: String) -> void:
	if is_instance_valid(explore_hint):
		explore_hint.text = text
		explore_hint.modulate.a = 1.0

func _screen_flash(color: Color, duration: float) -> void:
	if not is_instance_valid(fade_rect): return
	var old_z = fade_rect.z_index
	fade_rect.z_index = 100
	fade_rect.color = color
	fade_rect.modulate = Color(1, 1, 1, 0)
	var tw = create_tween()
	tw.tween_property(fade_rect, "modulate:a", 0.8, duration * 0.3)
	tw.tween_property(fade_rect, "modulate:a", 0.0, duration * 0.7)
	await tw.finished
	if not is_inside_tree(): return
	fade_rect.color = Color.BLACK
	fade_rect.z_index = old_z

func _fade_to_black(duration: float) -> void:
	if not is_instance_valid(fade_rect): return
	fade_rect.z_index = 100
	fade_rect.color = Color.BLACK
	fade_rect.modulate = Color(1, 1, 1, 0)
	var tw = create_tween()
	tw.tween_property(fade_rect, "modulate:a", 1.0, duration)
	await tw.finished
	if not is_inside_tree(): return

func _get_party_assist() -> String:
	if not has_node("/root/ChoiceConsequences"):
		return ""
	for member in ChoiceConsequences.party_combat_members:
		if randf() > 0.5:
			match member:
				"seraphina":
					return "Seraphina strikes with a combo attack!"
				"lyra":
					return "Lyra fires a support shot!"
				"elara":
					return "Elara reinforces your defenses!"
	return ""
