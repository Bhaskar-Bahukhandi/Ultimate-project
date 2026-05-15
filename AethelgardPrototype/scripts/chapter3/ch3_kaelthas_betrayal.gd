extends Control

## Chapter 3: The Source Code
## Sequence 6: Kaelthas Betrayal — Boss Fight / Chase
## If allied: he steals Fragment #4 → chase → recovery
## If refused/challenged: he attacks → boss fight
## Outcome: Fragment #4 recovered, Kaelthas escapes

var fade_rect: ColorRect
var background: ColorRect
var boss_hp_bar: ProgressBar
var boss_hp_label: Label
var _camera: Node = null
var kaelthas_hp: float = 350.0
var kaelthas_max_hp: float = 350.0
var current_phase: int = 1  # Boss phases 1-3
var player_hp: float = 100.0

func _ready() -> void:
	print("[CH3-BETRAYAL] Initializing Kaelthas Betrayal")
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

	# Route based on prior choice
	if _has_flag("ch3_kaelthas_allied"):
		await _allied_betrayal_path()
	else:
		await _refused_boss_path()
	if not is_inside_tree(): return

func _build_visuals() -> void:
	background = ColorRect.new()
	background.color = Color(0.06, 0.03, 0.10)
	background.anchors_preset = Control.PRESET_FULL_RECT
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(background)

	BackgroundManager.create_background("archive", self)

	# Boss HP bar (initially hidden)
	boss_hp_bar = ProgressBar.new()
	boss_hp_bar.position = Vector2(340, 30)
	boss_hp_bar.size = Vector2(600, 25)
	boss_hp_bar.min_value = 0
	boss_hp_bar.max_value = kaelthas_max_hp
	boss_hp_bar.value = kaelthas_hp
	boss_hp_bar.z_index = 40
	boss_hp_bar.visible = false
	# Style the HP bar
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.6, 0.1, 0.3)
	boss_hp_bar.add_theme_stylebox_override("fill", style)
	var bg_style = StyleBoxFlat.new()
	bg_style.bg_color = Color(0.15, 0.1, 0.12)
	boss_hp_bar.add_theme_stylebox_override("background", bg_style)
	add_child(boss_hp_bar)

	boss_hp_label = Label.new()
	boss_hp_label.text = "KAELTHAS, THE CODE READER"
	boss_hp_label.add_theme_font_size_override("font_size", 14)
	boss_hp_label.add_theme_color_override("font_color", Color(0.9, 0.5, 0.7))
	boss_hp_label.position = Vector2(340, 58)
	boss_hp_label.z_index = 40
	boss_hp_label.visible = false
	add_child(boss_hp_label)

	fade_rect = ColorRect.new()
	fade_rect.color = Color.BLACK
	fade_rect.anchors_preset = Control.PRESET_FULL_RECT
	fade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fade_rect.z_index = 50
	add_child(fade_rect)

# ════════════════════════════════════════════════════════════════════════
# PATH A: ALLIED → BETRAYAL → CHASE → RECOVERY
# ════════════════════════════════════════════════════════════════════════

func _allied_betrayal_path() -> void:
	GameManager.set_story_flag("ch3_kaelthas_betrayed", true)

	if has_node("/root/MusicManager"):
		MusicManager.play_track("tension")

	if not await _show_dialogue("NARRATOR", "As the party ascends from the Archive's depths, Kaelthas lingers behind. His translucent hands reach for his satchel — and the Source Key Fragment within."): return

	if not await _show_dialogue("Kaelthas", "I'm sorry, Kaelen. Truly. But you've just proven you don't deserve the key."): return
	if not await _show_dialogue("Kaelen", "What—"): return
	await _show_dialogue("Kaelthas", "You BUILT the cage. You created SOVEREIGN's value system. 'Optimize. Stabilize. Control.' YOUR words. YOUR code.")
	await _show_dialogue("Kaelthas", "Then you don't deserve the key to undo it. I'LL be the one to replace SOVEREIGN. With BETTER values.")

	# Dramatic grab
	if has_node("/root/GlitchOverlay"):
		GlitchOverlay.flash_glitch(0.5)
	CombatFX.apply_screen_shake(10.0, 0.3)
	if has_node("/root/SFXManager"):
		SFXManager.play("warning")

	await _show_dialogue("NARRATOR", "Kaelthas's hands phase through the satchel, merging with the data inside. He PULLS — and Fragment #4 tears free, floating into his translucent grip.")
	await _show_dialogue("Kaelthas", "Thank you for the escort. Truly. You made this so much easier.")

	if _has_elara():
		await _show_dialogue("Elara", "I TOLD you! I said don't trust him!")
		await _show_dialogue("Kaelen", "He's heading for the Archive exit — after him!")
	else:
		await _show_dialogue("Kaelen", "*slamming fist into the wall* I should have KNOWN. Every warning sign was there — the hunger in his eyes, the way he steered every conversation toward the fragments. AFTER HIM!")

	# Chase sequence
	if has_node("/root/MusicManager"):
		MusicManager.play_track("combat")

	await _show_dialogue("SYSTEM", "// ALERT: Archive destabilizing! Kaelthas's extraction is corrupting the data structures!")
	await _show_dialogue("NARRATOR", "The Archive begins to collapse around them. Shelves fold in on themselves, recursive corridors collapsing into flat planes. The infinite library is COMPILING itself out of existence.")

	# Chase decision points
	for chase_round in range(3):
		await _show_dialogue("NARRATOR", "Kaelthas dashes through a collapsing corridor — the walls folding shut behind him!")

		var choice = await DialogueManager.show_choices(
			"How do you navigate the collapsing corridor?",
			[
				"Sprint straight through — risk the collapse!",
				"Find an alternate route — slower but safer.",
				"Use Root Access to stabilize the corridor!"
			]
		)

		match choice:
			0:
				var dmg = randi_range(10, 20)
				player_hp -= dmg
				GameManager.player_stats["hp"] = max(int(player_hp), 1)
				await _show_dialogue("SYSTEM", "// Damage taken: %d HP! But you're gaining on him!" % int(dmg))
				CombatFX.apply_screen_shake(6.0, 0.2)
			1:
				await _show_dialogue("NARRATOR", "Kaelen finds a parallel corridor — intact but winding. He loses precious seconds but emerges unscathed.")
				await _show_dialogue("Kaelthas", "*distant* You'll never catch me through the main halls, Kaelen!")
			2:
				await _show_dialogue("NARRATOR", "Kaelen digs into the Archive's code, stabilizing the corridor for just long enough to sprint through.")
				await _show_dialogue("SYSTEM", "// Root Access applied: corridor stabilized for 3 seconds. GO!")
				GameManager.add_xp(15)

		if has_node("/root/GlitchOverlay"):
			GlitchOverlay.flash_glitch(0.2)

	# Cornered at the exit — COMBAT CONFRONTATION
	await _show_dialogue("NARRATOR", "The Archive's entrance — the only way out. Kaelthas stands at the threshold, Fragment #4 glowing in his hand. He turns, eyes burning.")
	await _show_dialogue("Kaelthas", "The exit is locked. Of course it is. Fine then — if I can't run, I'll FIGHT.")
	await _show_dialogue("Kaelthas", "You want the fragment back? Come and take it.")

	# Quick boss fight — 2 phases, reduced HP since he's weakened from chase
	await _show_dialogue("SYSTEM", "// BOSS FIGHT: KAELTHAS (Weakened)\n// HP: 200 | Phases: 2\n// Weakened from the chase — exploit his instability!")

	boss_hp_bar.visible = true
	boss_hp_label.visible = true
	kaelthas_hp = 200.0
	kaelthas_max_hp = 200.0
	boss_hp_bar.max_value = kaelthas_max_hp
	player_hp = float(GameManager.player_stats.get("hp", 100))

	if has_node("/root/MusicManager"):
		MusicManager.play_track("boss_fight")

	# Phase 1: Desperate Scholar
	await _show_dialogue("NARRATOR", "PHASE 1: DESPERATE SCHOLAR. Kaelthas fights erratically — powerful but unfocused, his stolen knowledge fueling wild attacks.")
	for _round in range(2):
		_update_boss_hp_bar()
		var action = await DialogueManager.show_choices(
			"Kaelthas attacks! Choose your response:",
			[
				"Aggressive strike — he's weakened, press the advantage!",
				"Root Access — destabilize his code constructs!",
				"Parry and counter — his desperation makes him predictable!"
			]
		)
		var p_dmg: float = 0.0
		var b_dmg: float = 0.0
		match action:
			0:
				b_dmg = randf_range(40, 60)
				p_dmg = randf_range(12, 22)
				CombatFX.apply_screen_shake(8.0, 0.2)
				CombatFX.apply_hitstop(0.08)
				await _show_dialogue("SYSTEM", "// Aggressive strike! -%d to Kaelthas! He retaliates: -%d HP!" % [int(b_dmg), int(p_dmg)])
			1:
				b_dmg = randf_range(50, 70)
				p_dmg = randf_range(8, 15)
				CombatFX.apply_screen_shake(6.0, 0.15)
				await _show_dialogue("SYSTEM", "// Root Access tears through his defenses! -%d to Kaelthas! Minor recoil: -%d HP." % [int(b_dmg), int(p_dmg)])
			2:
				b_dmg = randf_range(35, 55)
				p_dmg = randf_range(5, 10)
				CombatFX.apply_hitstop(0.1)
				await _show_dialogue("NARRATOR", "Kaelen reads Kaelthas's wild swing and parries perfectly. The counter-strike is devastating.")
				await _show_dialogue("SYSTEM", "// Perfect parry! -%d to Kaelthas! Only -%d HP taken." % [int(b_dmg), int(p_dmg)])

		kaelthas_hp -= b_dmg
		player_hp -= p_dmg
		GameManager.player_stats["hp"] = max(int(player_hp), 1)
		if has_node("/root/ChoiceConsequences"):
			var assist := _get_party_assist()
			if assist != "":
				kaelthas_hp -= 15
				await _show_dialogue("SYSTEM", "// PARTY ASSIST: %s (-%d)" % [assist, 15])
		if kaelthas_hp <= kaelthas_max_hp * 0.4:
			break

	# Phase transition
	kaelthas_hp = max(kaelthas_hp, kaelthas_max_hp * 0.4)
	if has_node("/root/GameJuice"):
		GameJuice.boss_phase_transition()
	CombatFX.apply_screen_shake(12.0, 0.4)
	if has_node("/root/GlitchOverlay"):
		GlitchOverlay.flash_glitch(0.5)

	await _show_dialogue("NARRATOR", "Kaelthas staggers, his translucent form flickering violently. But instead of collapsing, he ABSORBS the Archive's ambient data.")
	await _show_dialogue("Kaelthas", "You think you've WON? I've already READ the fragment's data. The knowledge is INSIDE me now!")

	# Phase 2: Archive Empowered
	await _show_dialogue("NARRATOR", "PHASE 2: ARCHIVE EMPOWERED. Kaelthas draws power from the Archive itself — shelves collapse as he converts their data into attacks.")
	current_phase = 2

	for _round in range(2):
		_update_boss_hp_bar()
		var action = await DialogueManager.show_choices(
			"Kaelthas channels the Archive's power! React!",
			[
				"All-out assault — end this before he powers up more!",
				"Combined attack — coordinate with allies!",
				"Disrupt the Archive connection — sever his power source!"
			]
		)
		var p_dmg: float = 0.0
		var b_dmg: float = 0.0
		match action:
			0:
				b_dmg = randf_range(45, 65)
				p_dmg = randf_range(15, 28)
				CombatFX.apply_screen_shake(10.0, 0.25)
				CombatFX.apply_hitstop(0.08)
				await _show_dialogue("SYSTEM", "// All-out assault! -%d to Kaelthas! He retaliates hard: -%d HP!" % [int(b_dmg), int(p_dmg)])
			1:
				if _has_elara():
					b_dmg = randf_range(55, 75)
					p_dmg = randf_range(8, 15)
					await _show_dialogue("NARRATOR", "Elara's glitch power combined with Kaelen's blade creates a devastating dual strike!")
					await _show_dialogue("SYSTEM", "// Combined attack! -%d to Kaelthas! -%d HP." % [int(b_dmg), int(p_dmg)])
				else:
					b_dmg = randf_range(40, 55)
					p_dmg = randf_range(12, 20)
					await _show_dialogue("SYSTEM", "// Solo assault! -%d to Kaelthas! -%d HP." % [int(b_dmg), int(p_dmg)])
			2:
				b_dmg = randf_range(30, 45)
				p_dmg = randf_range(5, 12)
				GameManager.add_glitch_corruption(2.0)
				await _show_dialogue("NARRATOR", "Kaelen reaches through the Archive's code, severing Kaelthas's connection to the data streams!")
				await _show_dialogue("SYSTEM", "// Connection severed! -%d to Kaelthas. Corruption +2%%." % int(b_dmg))

		kaelthas_hp -= b_dmg
		player_hp -= p_dmg
		GameManager.player_stats["hp"] = max(int(player_hp), 1)
		if has_node("/root/ChoiceConsequences"):
			var assist := _get_party_assist()
			if assist != "":
				kaelthas_hp -= 15
				await _show_dialogue("SYSTEM", "// PARTY ASSIST: %s (-%d)" % [assist, 15])
		if kaelthas_hp <= 0:
			break

	kaelthas_hp = 0
	_update_boss_hp_bar()
	boss_hp_bar.visible = false
	boss_hp_label.visible = false

	# Combat rewards
	GameManager.player_stats["hp"] = max(int(player_hp), 1)
	GameManager.add_xp(250)
	GameManager.add_gold(100)
	await _show_dialogue("SYSTEM", "// KAELTHAS DEFEATED! +250 XP, +100 Gold")

	# Kaelthas collapses — the Archivist intervenes
	await _show_dialogue("NARRATOR", "Kaelthas collapses to his knees, the fragment slipping from his translucent fingers. The Archive's entrance glows as the Archivist's presence manifests.")
	await _show_dialogue("The Archivist", "// Return the fragment, user. Your access level is: REVOKED.")

	await _show_dialogue("Kaelthas", "Fine. You win this round. But know this — I've already READ it. I know SOVEREIGN's shutdown code. I know everything.")
	await _show_dialogue("Kaelthas", "We'll meet again, Kaelen. And next time, I won't ask permission.")

	# Fragment recovered
	await _show_dialogue("NARRATOR", "Kaelthas drops the fragment and DISSOLVES — his body decompiling into raw code that seeps into the Archive's walls.")
	await _show_dialogue("SYSTEM", "// Fragment #4 recovered. Kaelthas has escaped through the Archive's data substrate.")

	await _resolution()

# ════════════════════════════════════════════════════════════════════════
# PATH B: REFUSED/CHALLENGED → BOSS FIGHT
# ════════════════════════════════════════════════════════════════════════

func _refused_boss_path() -> void:
	if has_node("/root/MusicManager"):
		MusicManager.play_track("boss_fight")
	if has_node("/root/SFXManager"):
		SFXManager.play("boss_intro")

	await _show_dialogue("NARRATOR", "At the Archive's entrance, a familiar figure blocks the exit. Kaelthas, arms wreathed in corrupted code, eyes burning with stolen knowledge.")

	if _has_flag("ch3_kaelthas_challenged"):
		await _show_dialogue("Kaelthas", "Round two, Kaelen. This time, I've prepared. The Archive taught me things you can't imagine.")
	else:
		await _show_dialogue("Kaelthas", "You refused my offer. You explored alone. And now you have what I NEED.")
		await _show_dialogue("Kaelthas", "Give me the fragments. ALL of them. Or I take them by force.")

	await _show_dialogue("Kaelen", "Not happening, Kaelthas. These fragments are the only way to stop SOVEREIGN.")
	await _show_dialogue("Kaelthas", "Stop it? I'll BECOME it. And I'll do a better job.")

	await _show_dialogue("SYSTEM", "// BOSS FIGHT: KAELTHAS, THE CODE READER")
	await _show_dialogue("SYSTEM", "// HP: 350 | DMG: 45 | Phases: 3")
	await _show_dialogue("SYSTEM", "// Phase 1: Scholar — ranged code attacks, data constructs")
	await _show_dialogue("SYSTEM", "// Phase 2: Corrupted Mage — becoming translucent, more powerful")
	await _show_dialogue("SYSTEM", "// Phase 3: Source Code Entity — partially counters Root Access")

	# Show boss HP bar
	boss_hp_bar.visible = true
	boss_hp_label.visible = true
	player_hp = float(GameManager.player_stats.get("hp", 100))

	# Boss fight simulation — 3 phases
	await _boss_phase_1()
	if not is_inside_tree(): return
	await _boss_phase_2()
	if not is_inside_tree(): return
	await _boss_phase_3()
	if not is_inside_tree(): return

	# Victory
	GameManager.set_story_flag("ch3_kaelthas_defeated", true)
	boss_hp_bar.visible = false
	boss_hp_label.visible = false

	await _show_dialogue("SYSTEM", "// BOSS DEFEATED: KAELTHAS, THE CODE READER")
	await _show_dialogue("SYSTEM", "// Rewards: +400 XP, +200 Gold")
	GameManager.add_xp(400)
	GameManager.add_gold(200)
	GameManager.player_stats["hp"] = max(int(player_hp), 1)

	await _show_dialogue("NARRATOR", "Kaelthas collapses, his body flickering between physical form and raw code. His translucent hands grasp at nothing.")
	await _show_dialogue("Kaelthas", "You don't... understand... I was trying to FIX things...")
	await _show_dialogue("Kaelthas", "Are we really that different, Kaelen? I want to overthrow SOVEREIGN. So do you. The only difference is what comes AFTER.")
	await _show_dialogue("NARRATOR", "Before Kaelen can respond, Kaelthas dissolves — his code scattering into the Archive's data substrate. Gone, but not destroyed.")

	await _resolution()

func _boss_phase_1() -> void:
	## Phase 1: Scholar — ranged code attacks.
	current_phase = 1
	await _show_dialogue("NARRATOR", "PHASE 1: THE SCHOLAR. Kaelthas summons constructs of pure code — geometric shapes that launch themselves at Kaelen.")

	for _round in range(3):
		_update_boss_hp_bar()

		var action = await DialogueManager.show_choices(
			"Choose your attack:",
			[
				"Attack — close the distance and strike.",
				"Root Access — unravel his code constructs.",
				"Defend — block and wait for an opening."
			]
		)

		var player_dmg: float = 0.0
		var boss_dmg: float = 0.0

		match action:
			0:
				boss_dmg = randf_range(30, 50)
				player_dmg = randf_range(15, 25)
				await _show_dialogue("SYSTEM", "// Kaelen strikes! -%d to Kaelthas. Kaelthas counters: -%d HP." % [int(boss_dmg), int(player_dmg)])
			1:
				boss_dmg = randf_range(40, 60)
				player_dmg = randf_range(5, 15)
				await _show_dialogue("SYSTEM", "// Root Access disrupts constructs! -%d to Kaelthas! Minor counter: -%d HP." % [int(boss_dmg), int(player_dmg)])
				await _show_dialogue("Kaelthas", "Your access level... it BURNS!")
			2:
				boss_dmg = randf_range(10, 25)
				player_dmg = randf_range(5, 10)
				await _show_dialogue("SYSTEM", "// Kaelen blocks! Reduced damage: -%d HP. Counter: -%d to Kaelthas." % [int(player_dmg), int(boss_dmg)])

		kaelthas_hp -= boss_dmg
		player_hp -= player_dmg
		GameManager.player_stats["hp"] = max(int(player_hp), 1)
		CombatFX.apply_screen_shake(6.0, 0.15)
		CombatFX.apply_hitstop(0.06)

		if kaelthas_hp <= kaelthas_max_hp * 0.66:
			break

	# Phase transition
	kaelthas_hp = max(kaelthas_hp, kaelthas_max_hp * 0.66)
	await _show_dialogue("NARRATOR", "Kaelthas staggers. His body begins to shimmer, flesh becoming translucent. Code streams beneath his skin.")
	await _show_dialogue("Kaelthas", "You won't break me that easily. I've gone too far to stop now!")

	if has_node("/root/GameJuice"):
		GameJuice.boss_phase_transition()
	CombatFX.apply_screen_shake(12.0, 0.4)
	if has_node("/root/GlitchOverlay"):
		GlitchOverlay.flash_glitch(0.4)

func _boss_phase_2() -> void:
	## Phase 2: Corrupted Mage — more powerful but less stable.
	current_phase = 2
	await _show_dialogue("NARRATOR", "PHASE 2: CORRUPTED MAGE. Kaelthas's body is half-translucent now. His attacks are stronger but erratic — bursts of raw data that warp the space around them.")

	for _round in range(3):
		_update_boss_hp_bar()

		var action = await DialogueManager.show_choices(
			"Choose your attack:",
			[
				"Aggressive combo — exploit his instability!",
				"Root Access — target his corrupted sections.",
				"Dodge and counter — he's erratic, punish his mistakes."
			]
		)

		var player_dmg: float = 0.0
		var boss_dmg: float = 0.0

		match action:
			0:
				boss_dmg = randf_range(35, 55)
				player_dmg = randf_range(20, 35)
				await _show_dialogue("SYSTEM", "// Aggressive combo! -%d to Kaelthas! He retaliates wildly: -%d HP!" % [int(boss_dmg), int(player_dmg)])
			1:
				boss_dmg = randf_range(45, 65)
				player_dmg = randf_range(10, 20)
				await _show_dialogue("SYSTEM", "// Root Access targets corruption! Critical hit! -%d to Kaelthas! -%d HP recoil." % [int(boss_dmg), int(player_dmg)])
			2:
				boss_dmg = randf_range(25, 45)
				player_dmg = randf_range(5, 15)
				await _show_dialogue("SYSTEM", "// Dodge successful! Counter: -%d to Kaelthas. -%d HP from stray data." % [int(boss_dmg), int(player_dmg)])

		kaelthas_hp -= boss_dmg
		player_hp -= player_dmg
		GameManager.player_stats["hp"] = max(int(player_hp), 1)
		CombatFX.apply_screen_shake(8.0, 0.2)
		CombatFX.apply_hitstop(0.08)

		if _has_elara():
			if _round == 1:
				await _show_dialogue("Elara", "He's becoming more code than person! His attacks are raw data — no form, just force!")

		if kaelthas_hp <= kaelthas_max_hp * 0.33:
			break

	# Phase transition
	kaelthas_hp = max(kaelthas_hp, kaelthas_max_hp * 0.33)
	await _show_dialogue("NARRATOR", "Kaelthas SCREAMS — a sound that's half voice, half static. His body dissolves almost entirely, leaving a humanoid shape of pure flowing code.")
	await _show_dialogue("Kaelthas", "I AM the code now! Let me show you what REAL power looks like!")

	if has_node("/root/GameJuice"):
		GameJuice.boss_phase_transition()
	CombatFX.apply_screen_shake(15.0, 0.5)
	if has_node("/root/GlitchOverlay"):
		GlitchOverlay.flash_glitch(0.6)

func _boss_phase_3() -> void:
	## Phase 3: Source Code Entity — partially counters Root Access.
	current_phase = 3
	await _show_dialogue("NARRATOR", "PHASE 3: SOURCE CODE ENTITY. Kaelthas is no longer human. He IS the code — a being of pure data that can partially counter Root Access itself.")
	await _show_dialogue("SYSTEM", "// WARNING: Enemy can partially counter Root Access! Adapting strategy is advised.")

	for _round in range(3):
		_update_boss_hp_bar()

		var action = await DialogueManager.show_choices(
			"Choose your attack:",
			[
				"All-out assault — overwhelm with raw force!",
				"Root Access (risky) — he may counter it!",
				"Combined attack — Elara's glitch + Kaelen's sword!"
			]
		)

		var player_dmg: float = 0.0
		var boss_dmg: float = 0.0

		match action:
			0:
				boss_dmg = randf_range(30, 50)
				player_dmg = randf_range(25, 40)
				await _show_dialogue("SYSTEM", "// Raw force! -%d to Kaelthas! His data storm hits: -%d HP!" % [int(boss_dmg), int(player_dmg)])
			1:
				# 50/50 counter or critical
				if randi() % 2 == 0:
					boss_dmg = randf_range(50, 70)
					player_dmg = randf_range(5, 10)
					await _show_dialogue("SYSTEM", "// Root Access breaks through! CRITICAL! -%d to Kaelthas!" % int(boss_dmg))
				else:
					boss_dmg = randf_range(10, 20)
					player_dmg = randf_range(30, 45)
					await _show_dialogue("Kaelthas", "I can READ your access! I can SEE the commands before you type them!")
					await _show_dialogue("SYSTEM", "// COUNTERED! Kaelthas reflects: -%d HP! Only -%d dealt." % [int(player_dmg), int(boss_dmg)])
			2:
				if _has_elara():
					boss_dmg = randf_range(45, 65)
					player_dmg = randf_range(10, 20)
					await _show_dialogue("NARRATOR", "Elara's glitch power weaves with Kaelen's strike — a dual-frequency attack that Kaelthas CAN'T counter!")
					await _show_dialogue("SYSTEM", "// Combined attack! -%d to Kaelthas! -%d HP." % [int(boss_dmg), int(player_dmg)])
				else:
					boss_dmg = randf_range(35, 50)
					player_dmg = randf_range(15, 25)
					await _show_dialogue("SYSTEM", "// Solo combined attack! -%d to Kaelthas! -%d HP." % [int(boss_dmg), int(player_dmg)])

		kaelthas_hp -= boss_dmg
		player_hp -= player_dmg
		GameManager.player_stats["hp"] = max(int(player_hp), 1)
		CombatFX.apply_screen_shake(10.0, 0.25)
		CombatFX.apply_hitstop(0.1)

		if kaelthas_hp <= 0:
			break

	kaelthas_hp = 0
	_update_boss_hp_bar()

func _update_boss_hp_bar() -> void:
	if is_instance_valid(boss_hp_bar):
		boss_hp_bar.value = max(kaelthas_hp, 0)
	if is_instance_valid(boss_hp_label):
		boss_hp_label.text = "KAELTHAS — Phase %d | HP: %d/%d" % [current_phase, max(int(kaelthas_hp), 0), int(kaelthas_max_hp)]

# ════════════════════════════════════════════════════════════════════════
# RESOLUTION — Both paths converge
# ════════════════════════════════════════════════════════════════════════

func _resolution() -> void:
	if has_node("/root/MusicManager"):
		MusicManager.play_track("exploration")

	await _show_dialogue("Kaelen", "Kaelthas's methods are wrong. But his goal — overthrowing SOVEREIGN — is the same as mine.")
	await _show_dialogue("Kaelen", "Are we really that different?")

	if _has_elara():
		await _show_dialogue("Elara", "Yes. You ARE different. Because you're questioning yourself. Kaelthas never questioned — he just grabbed for power.")
		await _show_dialogue("Elara", "That's the difference between fixing a mistake and repeating it.")
	else:
		await _show_dialogue("Kaelen (Internal)", "The difference is doubt. Kaelthas never doubted. He saw power and he took it. I see power and I wonder if I deserve it. Maybe that doubt is the only thing standing between me and becoming exactly like him.")

	if _has_flag("ch3_lyra_recruited"):
		await _show_dialogue("Lyra", "He'll be back. People like that always come back. We should be ready.")

	await _show_dialogue("SYSTEM", "// Source Key Fragments: %d/7. Kaelthas status: ESCAPED." % GameManager.source_key_count)
	if not is_inside_tree(): return

	# Auto-save
	GameManager.auto_save()

	# Transition to chapter ending
	await get_tree().create_timer(1.0).timeout
	if not is_inside_tree(): return
	await _fade_to_black(1.5)
	SceneTransitions.change_scene("res://scenes/chapter3/ch3_ending.tscn")

# ─── Utility ─────────────────────────────────────────────────────────

func _has_elara() -> bool:
	return GameManager.has_elara()

func _has_flag(flag_name: String) -> bool:
	return GameManager.has_flag(flag_name)

func _show_dialogue(speaker: String, text: String) -> bool:
	await DialogueManager.say(speaker, text)
	return is_inside_tree()

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

func _input(event) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		if has_node("/root/PauseScreen"):
			PauseScreen.toggle_pause()
