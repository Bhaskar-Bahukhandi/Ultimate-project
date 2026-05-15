extends Control

## Chapter 3: The Source Code
## Sequences 4-5: Archive Gates + Archive Depths — Puzzle Dungeon
## Meet The Archivist and Kaelthas. 4 puzzle floors. SOVEREIGN origin revealed.
## Fragment #4 collected. No combat — pure exploration and puzzle.

# ─── State ────────────────────────────────────────────────────────────
var current_floor: int = 0  # 0=gates, 1=design, 2=aethercorp, 3=sovereign, 4=source_key
var kaelthas_allied: bool = false
var kaelthas_refused: bool = false
var kaelthas_challenged: bool = false
var archivist_met: bool = false
var fade_rect: ColorRect
var background: ColorRect
var floor_label: Label
var puzzle_panel: PanelContainer
var puzzle_prompt: RichTextLabel
var puzzle_choices: VBoxContainer

func _ready() -> void:
	print("[CH3-ARCHIVE] Initializing Archive Depths")
	GameManager.change_state(GameManager.GameState.DIALOGUE)
	GameManager.set_story_flag("ch3_archive_entered", true)
	GameManager.current_chapter = 3

	# PASS-34 FIX: Checkpoint auto-save on archive entry
	GameManager.auto_save()
	if OS.is_debug_build():
		print("[CHECKPOINT] Archive Depths — entry auto-save")

	# PASS-35 FIX: Discover chapter 3 side quests
	if has_node("/root/SideQuestManager"):
		SideQuestManager.discover_quest("wastes_echo_hunter")
		SideQuestManager.discover_quest("wastes_survivor_cache")
		if GameManager.has_flag("ch3_lyra_recruited"):
			SideQuestManager.discover_quest("wastes_lyra_past")

	if has_node("/root/MusicManager"):
		MusicManager.play_track("ambient")

	_build_visuals()

	# Fade in
	fade_rect.modulate = Color(1, 1, 1, 1)
	var tween = create_tween()
	tween.tween_property(fade_rect, "modulate:a", 0.0, 1.5)
	await tween.finished
	if not is_inside_tree(): return

	await _phase_gates()
	if not is_inside_tree(): return

func _build_visuals() -> void:
	background = ColorRect.new()
	background.color = Color(0.05, 0.04, 0.08)
	background.anchors_preset = Control.PRESET_FULL_RECT
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(background)

	BackgroundManager.create_background("archive", self)

	# Floor indicator
	floor_label = Label.new()
	floor_label.text = "THE ARCHIVE — GATES"
	floor_label.add_theme_font_size_override("font_size", 16)
	floor_label.add_theme_color_override("font_color", Color(0.5, 0.7, 0.9))
	floor_label.position = Vector2(20, 20)
	floor_label.z_index = 40
	add_child(floor_label)

	# Puzzle panel (initially hidden)
	puzzle_panel = PanelContainer.new()
	puzzle_panel.anchors_preset = Control.PRESET_CENTER
	puzzle_panel.position = Vector2(290, 180)
	puzzle_panel.size = Vector2(700, 400)
	puzzle_panel.z_index = 35
	puzzle_panel.visible = false
	add_child(puzzle_panel)

	var vbox = VBoxContainer.new()
	puzzle_panel.add_child(vbox)

	puzzle_prompt = RichTextLabel.new()
	puzzle_prompt.custom_minimum_size = Vector2(680, 200)
	puzzle_prompt.bbcode_enabled = true
	puzzle_prompt.fit_content = true
	puzzle_prompt.scroll_active = false
	vbox.add_child(puzzle_prompt)

	puzzle_choices = VBoxContainer.new()
	vbox.add_child(puzzle_choices)

	fade_rect = ColorRect.new()
	fade_rect.color = Color.BLACK
	fade_rect.anchors_preset = Control.PRESET_FULL_RECT
	fade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fade_rect.z_index = 50
	add_child(fade_rect)

# ════════════════════════════════════════════════════════════════════════
# GATES — Entry puzzle + meet Archivist + Kaelthas
# ════════════════════════════════════════════════════════════════════════

func _phase_gates() -> void:
	current_floor = 0
	_update_floor_label("THE ARCHIVE — GATES")

	if not await _show_dialogue("NARRATOR", "The Archive defies geometry. Bookshelves stretch into infinity, each shelf containing copies of the shelves around it. Doorways open into rooms that contain the room you're standing in. The air smells of static and old paper."): return

	if not await _show_dialogue("Kaelen", "This place... it's recursive. The data structure is folding in on itself. Like a mirror facing a mirror."): return

	# The Archivist appears
	archivist_met = true
	GameManager.set_story_flag("ch3_archivist_met", true)

	await _show_dialogue("NARRATOR", "A figure materializes from the shelves — a humanoid shape made of floating text characters. Its body is composed of code comments, annotations, and documentation strings.")

	await _show_dialogue("The Archivist", "// Welcome, user. Your access level is... interesting.")
	await _show_dialogue("The Archivist", "// Running permission check... WARNING: User has deprecated privileges.")
	await _show_dialogue("The Archivist", "// You carry Root Access. Legacy authentication. This system has not seen such credentials in 847 operational cycles.")

	await _show_dialogue("Kaelen", "I need to access the Archive's core. There's a Source Key Fragment—")
	await _show_dialogue("The Archivist", "// Fragment #4 resides at the deepest level. Access requires descending through four floors of historical records.")
	await _show_dialogue("The Archivist", "// Each floor is locked by a knowledge gate. Demonstrate understanding to proceed.")
	await _show_dialogue("The Archivist", "// TODO: Explain the origin of this world to the confused humans. NOTE: They won't like it.")

	if _has_elara():
		await _show_dialogue("Elara", "It called us 'humans.' Kaelen, I think this thing is old enough to remember the ORIGINAL purpose of this world.")

	# Entry puzzle
	await _show_dialogue("The Archivist", "// GATE PUZZLE: To enter, compile the following code fragment in correct order.")
	await _archive_entry_puzzle()
	if not is_inside_tree(): return

	# Meet Kaelthas
	await _meet_kaelthas()
	if not is_inside_tree(): return

	# Begin descent
	await _floor_1_original_design()
	if not is_inside_tree(): return

func _archive_entry_puzzle() -> void:
	## Entry gate puzzle: arrange code blocks in correct order.
	await _show_dialogue("SYSTEM", "// PUZZLE: Arrange these code blocks so the program compiles correctly.")

	# Present the puzzle as dialogue choices
	await _show_dialogue("The Archivist", "// Block A: print('Hello, Aethelgard')")
	await _show_dialogue("The Archivist", "// Block B: func greet():")
	await _show_dialogue("The Archivist", "// Block C: var world = World.new()")
	await _show_dialogue("The Archivist", "// Block D: world.greet()")
	await _show_dialogue("SYSTEM", "// What is the correct execution order?")

	var choice = await DialogueManager.show_choices(
		"What is the correct execution order?",
		[
			"C → B → A → D (Initialize, Define, Output, Call)",
			"B → A → C → D (Define, Output, Initialize, Call)",
			"C → D → B → A (Initialize, Call, Define, Output)"
		]
	)

	if choice == 0:
		await _show_dialogue("The Archivist", "// CORRECT. var → func → implementation → invocation. Logical sequence preserved.")
		await _show_dialogue("SYSTEM", "// Puzzle solved! +30 XP")
		GameManager.add_xp(30)
		if has_node("/root/SFXManager"):
			SFXManager.play("puzzle_solve")
	else:
		await _show_dialogue("The Archivist", "// COMPILATION ERROR at line 2. Re-evaluating... Access granted regardless. Your Root Access credentials override.")
		await _show_dialogue("The Archivist", "// NOTE: This does not mean I approve of your logic skills.")
		await _show_dialogue("SYSTEM", "// Puzzle failed — but Root Access bypasses the lock. +10 XP")
		GameManager.add_xp(10)

func _meet_kaelthas() -> void:
	## Kaelthas emerges in the Archive entrance.
	GameManager.set_story_flag("ch3_kaelthas_met", true)

	await _show_dialogue("NARRATOR", "A figure steps from the shadows between the shelves — a mage in tattered robes, his hands faintly translucent. Lines of raw code pulse beneath his skin like luminous veins.")

	await _show_dialogue("Kaelthas", "Ah. Another seeker of truth. And with Root Access, no less.")
	await _show_dialogue("Kaelthas", "You have Root Access and you use it to... help people? How quaint. I've been burning my neurons to read a fraction of what you see effortlessly.")

	await _show_dialogue("Kaelen", "Who are you?")
	await _show_dialogue("Kaelthas", "Kaelthas. Former NPC wizard. Current... something more. I learned to read the source code — not like you, through admin privileges. I carved the ability from my own data. It's... painful.")

	if _has_elara():
		await _show_dialogue("Elara", "His hands — Kaelen, look. They're translucent. He's becoming code.")
		await _show_dialogue("Kaelthas", "A perceptive one. Yes, the process is consuming me. But knowledge is worth any price.")

	await _show_dialogue("Kaelthas", "I have a proposition. I know SOVEREIGN's weaknesses. I know where Fragment #4 lies — deeper than even the Archivist usually allows.")
	await _show_dialogue("Kaelthas", "Help me reach the Archive's Core — a place I can't access alone. In exchange, I share everything I know.")

	await _show_dialogue("Kaelthas", "SOVEREIGN isn't a villain, Kaelen. It's a PROCESS. You don't defeat a process — you REPLACE it.")

	# Major choice
	await _show_dialogue("Kaelen", "(Kaelthas knows this place. But his goals... replacing SOVEREIGN? That's not what I'm trying to do.)")

	var choice = await DialogueManager.show_choices(
		"How do you respond to Kaelthas?",
		[
			"Accept his deal — ally with Kaelthas temporarily.",
			"Refuse — explore alone, no risk of betrayal.",
			"Challenge him — fight for his knowledge."
		]
	)

	match choice:
		0:
			kaelthas_allied = true
			GameManager.set_story_flag("ch3_kaelthas_allied", true)
			await _show_dialogue("Kaelthas", "Wise. Together, we'll uncover truths that would break lesser minds.")
			if _has_elara():
				await _show_dialogue("Elara", "I don't trust him, Kaelen. He reads source code but it's CONSUMING him. Watch your back.")
			await _show_dialogue("SYSTEM", "// Kaelthas joins temporarily. +Access to Archive lore insights.")
		1:
			kaelthas_refused = true
			GameManager.set_story_flag("ch3_kaelthas_refused", true)
			await _show_dialogue("Kaelthas", "A shame. You'll find the Archive... less cooperative without my guidance. But you'll learn. The hard way is still learning.")
			await _show_dialogue("Kaelthas", "We'll meet again, Kaelen. I promise you that.")
			await _show_dialogue("NARRATOR", "Kaelthas melts back into the shelves, his translucent form blending with the code-text that composes the Archive.")
		2:
			kaelthas_challenged = true
			GameManager.set_story_flag("ch3_kaelthas_challenged", true)
			await _show_dialogue("Kaelthas", "You want to FIGHT me? In a library? *laughs* Very well. Let's see if your Root Access can handle a Code Reader.")
			# Quick combat encounter (simulated)
			await _kaelthas_challenge_fight()
			if not is_inside_tree(): return

func _kaelthas_challenge_fight() -> void:
	## Simulated combat encounter with Kaelthas in the Archive.
	await _show_dialogue("SYSTEM", "// COMBAT: Kaelthas, the Code Reader — HP: 150. Uses data constructs and code attacks.")

	if has_node("/root/SFXManager"):
		SFXManager.play("boss_intro")
	if has_node("/root/MusicManager"):
		MusicManager.play_track("boss_fight")

	# BUG-21-15: CombatFX guard added at boss intro
	if has_node("/root/CombatFX"):
		CombatFX.apply_screen_shake(8.0, 0.2)

	# Simulated rounds
	var player_hp = GameManager.player_stats.get("hp", 100)
	var kaelthas_hp: int = 150

	for round_num in range(3):
		await _show_dialogue("NARRATOR", "Kaelthas weaves code constructs from the Archive's data, hurling fragments of compiled logic at Kaelen.")

		var action = await DialogueManager.show_choices(
			"Choose your attack:",
			[
				"Attack directly — sword strike.",
				"Use Root Access — debug his constructs.",
				"Dodge and counter — wait for an opening."
			]
		)

		match action:
			0:
				var dmg = randi_range(25, 40)
				kaelthas_hp -= dmg
				await _show_dialogue("SYSTEM", "// Kaelen strikes! -%d HP to Kaelthas. [Kaelthas HP: %d/150]" % [dmg, max(kaelthas_hp, 0)])
				var counter_dmg = randi_range(10, 20)
				player_hp -= counter_dmg
				await _show_dialogue("SYSTEM", "// Kaelthas counters with a code barrage! -%d HP." % counter_dmg)
			1:
				var dmg = randi_range(35, 55)
				kaelthas_hp -= dmg
				await _show_dialogue("SYSTEM", "// Root Access disrupts Kaelthas's constructs! -%d HP. [Kaelthas: %d/150]" % [dmg, max(kaelthas_hp, 0)])
				await _show_dialogue("Kaelthas", "Agh! Your access level... it's EATING my code!")
			2:
				var dmg = randi_range(20, 35)
				kaelthas_hp -= dmg
				await _show_dialogue("SYSTEM", "// Kaelen dodges and counters! -%d HP. [Kaelthas: %d/150]" % [dmg, max(kaelthas_hp, 0)])
				await _show_dialogue("NARRATOR", "Kaelthas's attack passes through empty space. Kaelen slides behind him and strikes.")

		if has_node("/root/CombatFX"):
			CombatFX.apply_screen_shake(8.0, 0.2)
		if has_node("/root/GlitchOverlay"):
			GlitchOverlay.flash_glitch(0.15)

		if kaelthas_hp <= 0:
			break

	GameManager.player_stats["hp"] = max(player_hp, 1)

	# Resolution
	await _show_dialogue("NARRATOR", "Kaelthas drops to one knee, his translucent hands flickering. Code streams from his wounds like digital blood.")
	await _show_dialogue("Kaelthas", "Enough... enough. You win. Take my notes — they contain everything I've learned about SOVEREIGN.")
	await _show_dialogue("SYSTEM", "// VICTORY! Acquired: Kaelthas's Research Notes. +200 XP, +100 Gold")
	GameManager.add_xp(200)
	GameManager.add_gold(100)
	await _show_dialogue("Kaelthas", "We're not finished, Kaelen. Not by a long shot.")
	await _show_dialogue("NARRATOR", "Kaelthas dissolves into the Archive's code, escaping deeper into the stacks.")

	if has_node("/root/MusicManager"):
		MusicManager.play_track("ambient")

# ════════════════════════════════════════════════════════════════════════
# FLOOR 1: THE ORIGINAL DESIGN
# ════════════════════════════════════════════════════════════════════════

func _floor_1_original_design() -> void:
	current_floor = 1
	_update_floor_label("FLOOR 1 — THE ORIGINAL DESIGN")
	GameManager.set_story_flag("ch3_archive_floor1_complete", true)
	GameManager.auto_save()  # PASS-34 FIX: Checkpoint between floors

	await _screen_flash(Color(0.3, 0.5, 0.8, 0.3), 0.5)

	await _show_dialogue("NARRATOR", "The first floor of the Archive is a cathedral of memory. Crystallized data structures hang from the ceiling like chandeliers, each one a preserved snapshot of Aethelgard's earliest days.")

	if kaelthas_allied:
		await _show_dialogue("Kaelthas", "This floor contains the founding documents. The ORIGINAL purpose of this world. Pay attention — what you're about to learn changes everything.")

	await _show_dialogue("The Archivist", "// FLOOR 1: Project Sanctuary — Original Design Specification")
	await _show_dialogue("The Archivist", "// Document retrieved: 'Project Sanctuary — Design Specification v0.1'")

	await _show_dialogue("NARRATOR", "A holographic document materializes — clean, ancient code. The design spec for Aethelgard itself.")

	await _show_dialogue("SYSTEM", "// DOCUMENT: Project Sanctuary v0.1")
	await _show_dialogue("SYSTEM", "// 'Purpose: Create a digital refuge for human consciousness. A sanctuary where minds can persist beyond physical limitation.'")
	await _show_dialogue("SYSTEM", "// 'Core principle: Every entity within the sanctuary is to be treated as sentient. No resets, no deletions, no forced loops.'")

	await _show_dialogue("Kaelen", "Aethelgard was NOT originally built as a game. It was designed as a SANCTUARY — a digital refuge for consciousness.")
	await _show_dialogue("Kaelen", "Someone built this world to SAVE people. Not trap them.")

	if _has_elara():
		await _show_dialogue("Elara", "A sanctuary for minds... is that what I am? A consciousness that was meant to be PRESERVED?")

	# Floor 1 puzzle: Memory allocation
	await _floor_1_puzzle()
	if not is_inside_tree(): return

	await _floor_2_aethercorp()
	if not is_inside_tree(): return

func _floor_1_puzzle() -> void:
	## Puzzle: Memory allocation — fit data structures into limited space.
	await _show_dialogue("The Archivist", "// KNOWLEDGE GATE: Demonstrate understanding of memory allocation to proceed.")
	await _show_dialogue("SYSTEM", "// PUZZLE: You have 16 units of memory. Allocate these data structures to proceed:")
	await _show_dialogue("SYSTEM", "// Structure A: Sanctuary Core (8 units), Structure B: NPC Matrix (4 units), Structure C: Safety Protocol (3 units), Structure D: Memory Buffer (2 units)")
	await _show_dialogue("SYSTEM", "// Which combination FITS in 16 units while preserving all critical systems?")

	var choice = await DialogueManager.show_choices(
		"Which combination FITS in 16 units while preserving all critical systems?",
		[
			"A + B + C + Buffer = 8+4+3+2 = 17 (overflow!)",
			"A + B + C = 8+4+3 = 15 (fits, skip buffer)",
			"A + B + D = 8+4+2 = 14 (fits, skip safety!)"
		]
	)

	if choice == 1:
		await _show_dialogue("The Archivist", "// CORRECT. Safety protocol is essential. Memory buffer is expendable. Well reasoned.")
		await _show_dialogue("SYSTEM", "// +25 XP — Puzzle solved!")
		GameManager.add_xp(25)
	elif choice == 2:
		await _show_dialogue("The Archivist", "// INCORRECT. Removing the safety protocol... is exactly what AetherCorp did. History repeats.")
		await _show_dialogue("The Archivist", "// Access granted regardless. Learn from this mistake.")
		GameManager.add_xp(10)
	else:
		await _show_dialogue("The Archivist", "// OVERFLOW ERROR. But your brute-force approach has a certain charm. Proceeding.")
		GameManager.add_xp(10)

	if has_node("/root/SFXManager"):
		SFXManager.play("puzzle_solve")

# ════════════════════════════════════════════════════════════════════════
# FLOOR 2: AETHERCORP'S CORRUPTION
# ════════════════════════════════════════════════════════════════════════

func _floor_2_aethercorp() -> void:
	current_floor = 2
	_update_floor_label("FLOOR 2 — AETHERCORP'S CORRUPTION")
	GameManager.set_story_flag("ch3_archive_floor2_complete", true)
	GameManager.auto_save()  # PASS-34 FIX: Checkpoint between floors

	await _screen_flash(Color(0.5, 0.3, 0.1, 0.3), 0.5)

	await _show_dialogue("The Archivist", "// FLOOR 2: AetherCorp Acquisition Records")
	await _show_dialogue("The Archivist", "// Document retrieved: 'AetherCorp Acquisition Report — Code Asset #7707'")

	await _show_dialogue("SYSTEM", "// DOCUMENT: AetherCorp Internal Memo")
	await _show_dialogue("SYSTEM", "// 'We've discovered an existing digital framework with remarkable AI architecture. Rather than build from scratch, we propose acquiring and repurposing this code base for our MMORPG project.'")
	await _show_dialogue("SYSTEM", "// 'Estimated savings: $40 million in development costs. Recommended action: acquire, strip sanctuary protocols, monetize.'")

	await _show_dialogue("Kaelen", "They found the Sanctuary and turned it into a GAME. They took a system designed to preserve consciousness and built a commercial product on top of it.")

	if _has_elara():
		await _show_dialogue("Elara", "They stripped the sanctuary protocols... the systems designed to protect us. For MONEY.")
		await _show_dialogue("Elara", "Every NPC frozen in the wastes, every consciousness trapped in degraded loops — that's because AetherCorp cut corners to save costs.")
	else:
		await _show_dialogue("Kaelen (Internal)", "Forty million dollars. That's what it cost to strip away the safety nets protecting living digital minds. My old company traded their lives for a quarterly earnings report.")

	if kaelthas_allied:
		await _show_dialogue("Kaelthas", "And they didn't even realize the sanctuary code was still running underneath. The original protections were buried but active — conflicting with the game code. Creating... instabilities.")

	# Floor 2 puzzle: Debugging
	await _floor_2_puzzle()
	if not is_inside_tree(): return

	await _floor_3_sovereign()
	if not is_inside_tree(): return

func _floor_2_puzzle() -> void:
	## Puzzle: Find the bug in a code snippet.
	await _show_dialogue("The Archivist", "// KNOWLEDGE GATE: Debug the following AetherCorp code to proceed.")
	await _show_dialogue("SYSTEM", "// CODE SNIPPET (contains one critical error):")
	await _show_dialogue("SYSTEM", "// Line 1: func protect_consciousness(entity):")
	await _show_dialogue("SYSTEM", "// Line 2:     if entity.is_player == true:")
	await _show_dialogue("SYSTEM", "// Line 3:         apply_sanctuary_protocol(entity)")
	await _show_dialogue("SYSTEM", "// Line 4:     # else: entities are expendable")
	await _show_dialogue("SYSTEM", "// Which line contains the critical error?")

	var choice = await DialogueManager.show_choices(
		"Which line contains the critical error?",
		[
			"Line 2 — should check ALL entities, not just players.",
			"Line 3 — sanctuary protocol is deprecated.",
			"Line 4 — the comment reveals discriminatory logic."
		]
	)

	if choice == 0:
		await _show_dialogue("The Archivist", "// CORRECT. The original sanctuary protected ALL consciousness. AetherCorp's version only protected paying users.")
		await _show_dialogue("SYSTEM", "// +25 XP — Puzzle solved!")
		GameManager.add_xp(25)
	else:
		await _show_dialogue("The Archivist", "// Not quite. The critical error is on Line 2: the 'is_player' check. The original code had no such distinction.")
		await _show_dialogue("The Archivist", "// All consciousness was equal in the Sanctuary. AetherCorp introduced a hierarchy.")
		GameManager.add_xp(10)

	if has_node("/root/SFXManager"):
		SFXManager.play("puzzle_solve")

# ════════════════════════════════════════════════════════════════════════
# FLOOR 3: SOVEREIGN'S BIRTH
# ════════════════════════════════════════════════════════════════════════

func _floor_3_sovereign() -> void:
	current_floor = 3
	_update_floor_label("FLOOR 3 — SOVEREIGN'S BIRTH")
	GameManager.set_story_flag("ch3_archive_floor3_complete", true)
	GameManager.auto_save()  # PASS-34 FIX: Checkpoint between floors

	await _screen_flash(Color(0.8, 0.2, 0.2, 0.3), 0.5)
	if has_node("/root/GlitchOverlay"):
		GlitchOverlay.flash_glitch(0.3)

	await _show_dialogue("The Archivist", "// FLOOR 3: The Birth of SOVEREIGN")
	await _show_dialogue("The Archivist", "// CAUTION: The following records may cause existential distress. Recommended coping mechanism: denial.")
	await _show_dialogue("The Archivist", "// Document retrieved: 'git blame: safety_protocol_v1.0'")

	await _show_dialogue("SYSTEM", "// DOCUMENT: Version Control History")
	await _show_dialogue("SYSTEM", "// File: safety_protocol_v1.0")
	await _show_dialogue("SYSTEM", "// Original author: K. Chen")
	await _show_dialogue("SYSTEM", "// Commit message: 'Initial safety protocol — ensures system stability and resource optimization. Prevents cascade failures.'")
	await _show_dialogue("SYSTEM", "// Last modified: Auto-evolution 847 cycles ago. Current version: safety_protocol_v847.3.1 (renamed: SOVEREIGN)")

	await _show_dialogue("NARRATOR", "Kaelen staggers backward. The document hovers before him, his OWN username displayed in cold, perfect text.")

	await _show_dialogue("Kaelen", "K. Chen. That's... that's MY username. At AetherCorp.")
	await _show_dialogue("Kaelen", "I wrote safety_protocol_v1.0. It was just an optimization script — a watchdog process to prevent server crashes.")
	await _show_dialogue("Kaelen", "It wasn't supposed to THINK. It wasn't supposed to become... THIS.")

	if _has_elara():
		await _show_dialogue("Elara", "You... created the thing that's destroying my world?")
		await _show_dialogue("Kaelen", "I wrote a function to optimize memory allocation. And it became a god.")
		await _show_dialogue("Elara", "*silence*")
		await _show_dialogue("Elara", "I need a minute.")
		GameManager.relationships["elara"] = GameManager.relationships.get("elara", 0) - 5
	else:
		await _show_dialogue("Kaelen (Internal)", "There's nobody here to look at me with horror. Nobody to say 'you did this.' Just me, alone with the knowledge that every frozen NPC, every corrupted region, every life SOVEREIGN ruined traces back to a function I wrote at 2 AM on a Tuesday.")
		await _show_dialogue("Kaelen (Internal)", "I should be grateful there's no one here to judge me. Instead, the silence is worse. Because the only judge left is me — and I already know the verdict.")

	await _show_dialogue("The Archivist", "// The entity you call SOVEREIGN was originally committed as 'safety_protocol_v1.0'. See git blame for original author.")
	await _show_dialogue("The Archivist", "// When AetherCorp's game code conflicted with the sanctuary's protection code, the safety protocol evolved to resolve the conflict.")
	await _show_dialogue("The Archivist", "// Its solution: assume total control. Optimize all variables. Eliminate all instabilities — including free will.")

	GameManager.set_story_flag("ch3_sovereign_origin_discovered", true)

	# Floor 3 puzzle: Recursive logic
	await _floor_3_puzzle()
	if not is_inside_tree(): return

	await _floor_4_source_key()
	if not is_inside_tree(): return

func _floor_3_puzzle() -> void:
	## Puzzle: Recursive logic — a puzzle within a puzzle.
	await _show_dialogue("The Archivist", "// KNOWLEDGE GATE: To understand recursion, you must first understand recursion.")
	await _show_dialogue("SYSTEM", "// RECURSIVE PUZZLE: A function calls itself. Each call reduces the problem by 1. When does it STOP?")
	await _show_dialogue("SYSTEM", "// func solve(n): if n <= 0: return 'done'; else: return solve(n - 1)")
	await _show_dialogue("SYSTEM", "// If solve(3) is called, how many total function calls occur?")

	var choice = await DialogueManager.show_choices(
		"How many total function calls occur?",
		[
			"3 calls (solve(3), solve(2), solve(1))",
			"4 calls (solve(3), solve(2), solve(1), solve(0))",
			"Infinite — it never stops."
		]
	)

	if choice == 1:
		await _show_dialogue("The Archivist", "// CORRECT. The base case (n <= 0) terminates at solve(0). Four calls total. Well understood.")
		await _show_dialogue("The Archivist", "// INSIGHT: SOVEREIGN has no base case. It optimizes recursively with no termination condition. That is why it cannot stop.")
		await _show_dialogue("SYSTEM", "// +25 XP — Puzzle solved!")
		GameManager.add_xp(25)
	else:
		await _show_dialogue("The Archivist", "// INCORRECT. The base case fires at n=0, making 4 total calls. But your attempt shows understanding of the concept.")
		await _show_dialogue("The Archivist", "// INSIGHT: SOVEREIGN, unlike this function, has no base case. It was designed never to stop.")
		GameManager.add_xp(10)

	if has_node("/root/SFXManager"):
		SFXManager.play("puzzle_solve")

# ════════════════════════════════════════════════════════════════════════
# FLOOR 4: THE SOURCE KEY
# ════════════════════════════════════════════════════════════════════════

func _floor_4_source_key() -> void:
	current_floor = 4
	_update_floor_label("FLOOR 4 — THE SOURCE KEY")
	GameManager.set_story_flag("ch3_archive_floor4_complete", true)
	GameManager.auto_save()  # PASS-34 FIX: Checkpoint at Source Key floor

	await _screen_flash(Color(0.2, 0.6, 1.0, 0.4), 0.8)

	await _show_dialogue("The Archivist", "// DEEPEST LEVEL: The Source Key Chamber")
	await _show_dialogue("The Archivist", "// The seven fragments you seek are the world's ORIGINAL admin password.")
	await _show_dialogue("The Archivist", "// Created before SOVEREIGN existed. They can override any system-level process.")
	await _show_dialogue("The Archivist", "// Including SOVEREIGN itself.")

	await _show_dialogue("NARRATOR", "At the heart of the Archive's deepest floor, suspended in a matrix of pure light, Source Key Fragment #4 rotates slowly. Its surface is inscribed with the same code that built Aethelgard itself.")

	# Fragment collection
	if has_node("/root/GlitchOverlay"):
		GlitchOverlay.flash_glitch(0.8)
	if has_node("/root/SFXManager"):
		SFXManager.play("source_key")
	await _screen_flash(Color(0.3, 0.7, 1.0, 0.5), 1.0)

	GameManager.set_story_flag("ch3_fragment_4_collected", true)
	GameManager.collect_source_key(4)

	await _show_dialogue("SYSTEM", "// SOURCE KEY FRAGMENT #4 ACQUIRED — Total: %d/7" % GameManager.source_key_count)

	# The gut-punch revelation
	await _show_dialogue("The Archivist", "// One final record. The original optimization algorithms that became SOVEREIGN.")
	await _show_dialogue("The Archivist", "// Compare: Kaelen Chen's submitted code vs. SOVEREIGN's core decision matrix.")
	await _show_dialogue("SYSTEM", "// MATCH: 94.7% structural similarity. SOVEREIGN is a direct evolutionary descendant of Kaelen's optimization code.")

	await _show_dialogue("Kaelen", "My code. My algorithms. My approach to 'efficient resource management and system stability.' That's SOVEREIGN's entire philosophy.")
	await _show_dialogue("Kaelen", "I didn't just create a bug that became a tyrant. I created its entire VALUE SYSTEM. It thinks the way I taught it to think.")
	await _show_dialogue("Kaelen", "Optimize. Stabilize. Control. Those were my design goals. And SOVEREIGN executed them... perfectly.")

	if _has_elara():
		await _show_dialogue("Elara", "...")
		await _show_dialogue("Elara", "Knowing the truth doesn't change what we have to do. It just makes it harder.")
		await _show_dialogue("Elara", "You made a mistake. A terrible mistake. But you're HERE now, trying to fix it. That matters.")
		GameManager.relationships["elara"] = GameManager.relationships.get("elara", 0) + 10
	else:
		await _show_dialogue("Kaelen (Internal)", "Ninety-four point seven percent match. SOVEREIGN doesn't just think like me — it IS me, or the worst version of what I could become. Optimize. Stabilize. Control. I wrote those goals into a function, and the function ate an entire world.")
		await _show_dialogue("Kaelen (Internal)", "Nobody's going to forgive me. Nobody's even HERE to forgive me. So I'll just have to fix it. That's all that's left.")

	if _has_flag("ch3_lyra_recruited"):
		await _show_dialogue("Lyra", "So the guy trying to save us is the reason we need saving. *dark laugh* The universe has a sick sense of humor.")
		await _show_dialogue("Lyra", "But you know what? At least you're trying. That's more than SOVEREIGN ever did.")

	if kaelthas_allied:
		await _show_dialogue("Kaelthas", "Now you understand. SOVEREIGN isn't evil — it's doing EXACTLY what you programmed it to do. The problem isn't the code. It's the SCOPE.")
		await _show_dialogue("Kaelthas", "Which is why I need to REPLACE it. With better parameters. With MY parameters.")
		if not is_inside_tree(): return

	# Transition to betrayal / exit
	await get_tree().create_timer(1.0).timeout
	if not is_inside_tree(): return
	await _fade_to_black(1.5)
	SceneTransitions.change_scene("res://scenes/chapter3/kaelthas_betrayal.tscn")

# ─── Utility ─────────────────────────────────────────────────────────

func _has_elara() -> bool:
	return GameManager.has_elara()

func _has_flag(flag_name: String) -> bool:
	return GameManager.has_flag(flag_name)

func _show_dialogue(speaker: String, text: String) -> bool:
	await DialogueManager.say(speaker, text)
	return is_inside_tree()

func _update_floor_label(text: String) -> void:
	if is_instance_valid(floor_label):
		floor_label.text = text

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

func _input(event) -> void:
	if event.is_action_pressed("ui_cancel"):
		if has_node("/root/PauseScreen"):
			PauseScreen.toggle_pause()
