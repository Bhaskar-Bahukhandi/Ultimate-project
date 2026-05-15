extends Node2D

## Chapter 2: The Administrator's Game
## Sequence 5: Underground Network — Dungeon exploration with mini-boss

@onready var player_node = $Player
@onready var camera = $Camera2D

var data_wraith_defeated: bool = false
var fragment_collected: bool = false
var _puzzle_solved: bool = false
var _corruption_cooldown: bool = false
var _root_access_panel: RootAccessPanel = null

func _ready() -> void:
	print("[CH2-UNDERGROUND] Initializing Underground Network dungeon")
	GameManager.change_state(GameManager.GameState.EXPLORATION)

	# Play exploration music for the underground
	if has_node("/root/MusicManager"):
		MusicManager.play_track("underground")  # Pass 53: Use dedicated underground track

	if camera:
		camera.make_current()

	# Replace placeholder sprite with real player art
	if player_node:
		AssetManager.replace_player_sprite(player_node, "combat")

	_build_underground_environment()
	_spawn_dungeon_enemies()
	_create_puzzles()
	_setup_root_access()

	# Entry dialogue
	await get_tree().create_timer(0.5).timeout
	if not is_inside_tree(): return
	await _entry_dialogue()

func _has_elara() -> bool:
	return GameManager.has_elara()

func _has_flag(flag_name: String) -> bool:
	return GameManager.has_flag(flag_name)

func _entry_dialogue() -> void:
	var has_elara = _has_elara()

	# PASS-34 FIX: Auto-save checkpoint on dungeon entry
	GameManager.auto_save()
	if OS.is_debug_build():
		print("[CHECKPOINT] Underground Network — entry auto-save")

	# PASS-35 FIX: Discover and start underground side quest
	if has_node("/root/SideQuestManager"):
		SideQuestManager.discover_quest("ironhold_underground_data")
		SideQuestManager.start_quest("ironhold_underground_data")

	await DialogueManager.say("Kaelen", "This is it. The old process threads beneath Ironhold. The air is thick with corrupted data — I can feel it buzzing against my skin.")
	if not is_inside_tree(): return

	if has_elara:
		await DialogueManager.say("Elara", "Be careful. The corruption is much stronger down here. These old threads were abandoned for a reason — they were too unstable to maintain.")
		if not is_inside_tree(): return
		await DialogueManager.say("Kaelen (Internal)", "Abandoned process threads. In software terms, these are orphaned subroutines — code that's still running but disconnected from the main loop. They evolve on their own, mutating without oversight.")
		if not is_inside_tree(): return
		await DialogueManager.say("Elara", "The Source Key Fragment should be in the deepest chamber. But there will be guardians — corrupted processes that protect the old data stores.")
		if not is_inside_tree(): return
	else:
		await DialogueManager.say("Kaelen (Internal)", "Abandoned process threads. In software terms, these are orphaned subroutines — code that's still running but disconnected from the main loop. Mutating without oversight for who knows how long.")
		if not is_inside_tree(): return
		await DialogueManager.say("Kaelen (Internal)", "No Elara to watch my back. No one to explain the dangers ahead. Just me, Root Access, and whatever horrors are festering in this digital graveyard.")
		if not is_inside_tree(): return
		await DialogueManager.say("Kaelen", "The Source Key Fragment should be in the deepest chamber. That's what Seraphina said... and what Pip confirmed. Time to earn it.")
		if not is_inside_tree(): return

	await DialogueManager.say("System", "[WARNING: ENTERING DEPRECATED ZONE]\n[Corruption density: HIGH]\n[System monitoring: OFFLINE]\n[Proceed with caution]", Color(1, 0.5, 0), true)
	if not is_inside_tree(): return

	DialogueManager.hide_dialogue()

func _build_underground_environment() -> void:
	## Build the underground dungeon
	# Rich procedural background from BackgroundManager
	if has_node("/root/BackgroundManager"):
		BackgroundManager.create_background("underground", self)

	# Dark background
	var bg = ColorRect.new()
	bg.color = Color(0.06, 0.04, 0.08)
	bg.size = Vector2(4000, 2000)
	bg.position = Vector2(-500, -500)
	bg.z_index = -10
	add_child(bg)

	# Ground platforms (dungeon layout)
	var platforms = [
		# Entry corridor
		Rect2(0, 500, 600, 20),
		Rect2(0, 300, 20, 220),  # Left wall
		# First chamber
		Rect2(600, 500, 500, 20),
		Rect2(600, 200, 20, 320),  # Wall
		Rect2(1080, 200, 20, 320),  # Wall
		# Connecting passage
		Rect2(1100, 400, 300, 20),
		# Puzzle chamber
		Rect2(1400, 500, 600, 20),
		Rect2(1400, 150, 20, 370),  # Wall
		Rect2(1980, 150, 20, 370),  # Wall
		# Final corridor
		Rect2(2000, 400, 400, 20),
		# Boss chamber
		Rect2(2400, 500, 800, 20),
		Rect2(2400, 100, 20, 420),  # Wall
		Rect2(3180, 100, 20, 420),  # Wall
		Rect2(2400, 100, 800, 20),  # Ceiling
	]

	for p in platforms:
		_create_wall(p.position, p.size)

	# Data pipe decorations (glowing lines)
	var pipes = [
		[Vector2(100, 480), Vector2(550, 480)],
		[Vector2(700, 180), Vector2(700, 480)],
		[Vector2(1200, 380), Vector2(1400, 380)],
		[Vector2(1600, 130), Vector2(1600, 480)],
		[Vector2(2100, 380), Vector2(2400, 380)],
		[Vector2(2600, 80), Vector2(2600, 480)],
	]

	for pipe in pipes:
		_create_data_pipe(pipe[0], pipe[1])

	# Corruption zones (visual hazards)
	_create_corruption_zone(Vector2(800, 400), Vector2(100, 100))
	_create_corruption_zone(Vector2(1500, 350), Vector2(120, 150))
	_create_corruption_zone(Vector2(2700, 350), Vector2(150, 150))

	# Fragment location marker (boss chamber)
	var fragment_glow = ColorRect.new()
	fragment_glow.color = Color(0, 1, 1, 0.3)
	fragment_glow.size = Vector2(40, 40)
	fragment_glow.position = Vector2(2770, 440)
	fragment_glow.name = "FragmentGlow"
	add_child(fragment_glow)

	# Pulse the fragment glow
	var pulse = create_tween().set_loops()
	pulse.tween_property(fragment_glow, "modulate:a", 0.3, 1.0)
	pulse.tween_property(fragment_glow, "modulate:a", 1.0, 1.0)

func _create_wall(pos: Vector2, wall_size: Vector2) -> void:
	var wall = StaticBody2D.new()
	wall.position = pos

	var rect = ColorRect.new()
	rect.color = Color(0.15, 0.1, 0.18)
	rect.size = wall_size
	wall.add_child(rect)

	var col = CollisionShape2D.new()
	var shape = RectangleShape2D.new()
	shape.size = wall_size
	col.shape = shape
	col.position = wall_size * 0.5
	wall.add_child(col)

	add_child(wall)

func _create_data_pipe(start: Vector2, end: Vector2) -> void:
	## Create a glowing data pipe between two points
	var pipe = ColorRect.new()
	pipe.color = Color(0, 0.5, 1, 0.15)
	var diff = end - start
	pipe.size = Vector2(max(abs(diff.x), 3), max(abs(diff.y), 3))
	pipe.position = Vector2(min(start.x, end.x), min(start.y, end.y))
	pipe.z_index = -5
	add_child(pipe)

func _create_corruption_zone(pos: Vector2, zone_size: Vector2) -> void:
	## Create a visual corruption hazard zone
	var zone = Area2D.new()
	zone.position = pos

	var visual = ColorRect.new()
	visual.color = Color(0.5, 0, 0.5, 0.2)
	visual.size = zone_size
	zone.add_child(visual)

	var col = CollisionShape2D.new()
	var shape = RectangleShape2D.new()
	shape.size = zone_size
	col.shape = shape
	col.position = zone_size * 0.5
	zone.add_child(col)

	zone.body_entered.connect(_on_corruption_zone_entered)
	add_child(zone)

func _on_corruption_zone_entered(body) -> void:
	if body.is_in_group("player") and not _corruption_cooldown:
		_corruption_cooldown = true
		GameManager.add_glitch_corruption(1.0)
		# BUG-21-15: Guard autoload call
		if has_node("/root/VFXLibrary"):
			VFXLibrary.spawn_status_indicator("CORRUPTION +1%", body.global_position + Vector2(0, -40), self, false)
		await get_tree().create_timer(3.0).timeout
		if not is_inside_tree(): return
		_corruption_cooldown = false

func _spawn_dungeon_enemies() -> void:
	## Spawn dungeon enemies
	# First chamber enemies
	_spawn_enemy_at("corrupted_guard", Vector2(750, 460))
	_spawn_enemy_at("data_sprite", Vector2(900, 380))

	# Puzzle chamber enemies
	_spawn_enemy_at("shadow_wraith", Vector2(1600, 400))
	_spawn_enemy_at("corrupted_guard", Vector2(1750, 460))

	# Boss chamber — Data Wraith
	_spawn_data_wraith()

func _setup_root_access() -> void:
	## Add the reusable Root Access panel.
	_root_access_panel = RootAccessPanel.new()
	add_child(_root_access_panel)

func _input(event) -> void:
	if event.is_action_pressed("root_access") and _root_access_panel:
		if _root_access_panel.visible:
			_root_access_panel.close()
		elif player_node:
			var enemy = _root_access_panel.get_nearest_enemy(player_node.global_position)
			if enemy:
				_root_access_panel.open(enemy, 2.0)

func _spawn_enemy_at(enemy_type: String, pos: Vector2) -> void:
	## Spawn a regular enemy — uses AssetManager for sprites with ColorRect fallback
	var enemy: EnemyBase

	match enemy_type:
		"corrupted_guard":
			enemy = CorruptedGuard.new()
		"data_sprite":
			enemy = DataSprite.new()
		"shadow_wraith":
			enemy = ShadowWraith.new()
		_:
			return

	enemy.position = pos
	enemy.name = enemy_type + "_" + str(randi() % 9999)

	# Sprite — AssetManager first, ColorRect fallback
	var target_size = Vector2(30, 40)
	if AssetManager.is_asset_available(enemy_type):
		var sprite = Sprite2D.new()
		sprite.name = "Sprite"
		sprite.texture = AssetManager.get_sprite(enemy_type)
		sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		var tex_size = sprite.texture.get_size()
		if tex_size.x > 0 and tex_size.y > 0:
			var uniform = min(target_size.x / tex_size.x, target_size.y / tex_size.y) * 2.0
			sprite.scale = Vector2(uniform, uniform)
			sprite.offset = Vector2(0, -tex_size.y / 2.0)
		enemy.add_child(sprite)
	else:
		var sprite = ColorRect.new()
		sprite.name = "Sprite"
		sprite.size = target_size
		sprite.position = Vector2(-15, -40)
		sprite.color = AssetManager.get_placeholder_color(enemy_type)
		enemy.add_child(sprite)

	# Collision
	var col = CollisionShape2D.new()
	var shape = RectangleShape2D.new()
	shape.size = target_size
	col.shape = shape
	col.position = Vector2(0, -20)
	enemy.add_child(col)

	add_child(enemy)

func _spawn_data_wraith() -> void:
	## Spawn the Data Wraith mini-boss
	var boss = DataWraithBoss.new()
	boss.position = Vector2(2790, 400)
	boss.name = "DataWraith"

	var sprite = ColorRect.new()
	sprite.name = "Sprite"
	sprite.size = Vector2(50, 70)
	sprite.position = Vector2(-25, -70)
	sprite.color = Color(0.5, 0, 0.7)
	boss.add_child(sprite)

	var col = CollisionShape2D.new()
	var shape = RectangleShape2D.new()
	shape.size = Vector2(50, 70)
	col.shape = shape
	col.position = Vector2(0, -35)
	boss.add_child(col)

	# Health bar
	var hp_bar = ProgressBar.new()
	hp_bar.name = "HealthBar"
	hp_bar.size = Vector2(60, 8)
	hp_bar.position = Vector2(-30, -80)
	hp_bar.value = 100
	hp_bar.show_percentage = false
	boss.add_child(hp_bar)

	boss.boss_defeated.connect(_on_data_wraith_defeated)
	add_child(boss)

func _create_puzzles() -> void:
	## Create data routing puzzle in puzzle chamber
	# Simple trigger-based puzzle: player activates nodes in correct order
	var puzzle_trigger = Area2D.new()
	puzzle_trigger.name = "PuzzleTrigger"
	puzzle_trigger.position = Vector2(1700, 460)

	var p_col = CollisionShape2D.new()
	var p_shape = CircleShape2D.new()
	p_shape.radius = 30.0
	p_col.shape = p_shape
	puzzle_trigger.add_child(p_col)

	var p_visual = ColorRect.new()
	p_visual.color = Color(0, 1, 0, 0.3)
	p_visual.size = Vector2(30, 30)
	p_visual.position = Vector2(-15, -15)
	puzzle_trigger.add_child(p_visual)

	puzzle_trigger.body_entered.connect(_on_puzzle_trigger)
	add_child(puzzle_trigger)

func _on_puzzle_trigger(body) -> void:
	if not body.is_in_group("player") or _puzzle_solved:
		return

	_puzzle_solved = true
	# PASS-34 FIX: Mid-dungeon checkpoint
	GameManager.auto_save()
	if OS.is_debug_build():
		print("[CHECKPOINT] Underground Network — puzzle chamber auto-save")

	# PASS-35 FIX: Advance data cache quest
	if has_node("/root/SideQuestManager") and SideQuestManager.is_quest_active("ironhold_underground_data"):
		SideQuestManager.advance_quest("ironhold_underground_data")

	await DialogueManager.say("Kaelen", "A data routing node. If I redirect this process thread... it should open the path to the deeper chambers.")
	if not is_inside_tree(): return
	await DialogueManager.say("System", "[DATA PIPE RE-ROUTED]\n[Access to Deep Chamber: GRANTED]", Color(0, 1, 0), true)
	if not is_inside_tree(): return
	DialogueManager.hide_dialogue()

func _on_data_wraith_defeated() -> void:
	## Data Wraith mini-boss defeated — expanded with Elara branching
	data_wraith_defeated = true
	GameManager.set_story_flag("ch2_data_wraith_defeated", true)
	GameManager.auto_save()  # Autosave on boss defeat
	GameManager.collect_source_key(2)
	var has_elara = _has_elara()

	await get_tree().create_timer(1.0).timeout
	if not is_inside_tree(): return

	await DialogueManager.say("Kaelen", "*breathing heavily* That thing... it was a corrupted system process. A piece of the world's infrastructure that went rogue.")
	if not is_inside_tree(): return

	if has_elara:
		await DialogueManager.say("Elara", "And look — it was guarding this.")
		if not is_inside_tree(): return
	else:
		await DialogueManager.say("Kaelen", "Wait... it was guarding something. Beneath the remains — there.")
		if not is_inside_tree(): return

	# Boss loot: Phantom Cloak armor
	await DialogueManager.say("System", "[ITEM ACQUIRED: PHANTOM CLOAK]\n[Woven from purified process threads]", Color(0, 1, 1))
	if not is_inside_tree(): return

	if Inventory and Inventory.has_method("add_item"):
		Inventory.add_item("data_wraith_phantom_cloak", 1)
		Inventory.add_gold(600)

	await DialogueManager.say("Kaelen", "Armour stitched from the Data Wraith's own threads... the code still pulses inside it.")
	if not is_inside_tree(): return

	if has_elara:
		# Elara's arm reaction to the residual corruption energy
		await DialogueManager.say("Elara", "*clutching her arm* Aagh! The residual corruption energy — it's reacting to my glitch magic! The corruption in my arm is—")
		if not is_inside_tree(): return
		if camera and camera.has_method("shake"):
			camera.shake(8.0, 0.5)
		await DialogueManager.say("Kaelen", "Elara! Are you okay?!")
		if not is_inside_tree(): return
		await DialogueManager.say("Elara", "*through gritted teeth* I'm... fine. The Wraith's corruption resonates with glitch energy. My arm has been partially corrupted since I was born — or compiled, I suppose. Wearing its remnants amplifies it.")
		if not is_inside_tree(): return
		await DialogueManager.say("Elara", "It hurts, but it also... I can feel the world's code more clearly. The data structures, the object hierarchies. It's like my perception just got an upgrade.")
		if not is_inside_tree(): return
	else:
		await DialogueManager.say("Kaelen", "The Wraith's residual energy... it's flowing into me. My Root Access is absorbing it.")
		if not is_inside_tree(): return
		if camera and camera.has_method("shake"):
			camera.shake(6.0, 0.4)
		await DialogueManager.say("System", "[ROOT ACCESS AMPLIFIED]\n[Corruption resonance detected]\n[Perception expanded: +15% data structure visibility]", Color(0, 1, 0.5), true)
		if not is_inside_tree(): return
		await DialogueManager.say("Kaelen (Internal)", "It hurts. Like a migraine made of static. But I can see farther now — deeper into the code. Everything is sharper.")
		if not is_inside_tree(): return

	# Player choice: restore, destroy, or absorb the Data Wraith
	await _data_wraith_choice()
	if not is_inside_tree(): return

	await DialogueManager.say("Kaelen", "Let's get back to the surface. We've grown stronger — that's what matters.")
	if not is_inside_tree(): return

	GameManager.set_story_flag("ch2_underground_complete", true)
	DialogueManager.hide_dialogue()

	# Return to city
	await get_tree().create_timer(1.5).timeout
	if not is_inside_tree(): return
	SceneTransitions.change_scene("res://scenes/regions/ironhold_region.tscn")

func _data_wraith_choice() -> void:
	## Choice: restore, destroy, or absorb the data wraith's core — using show_choices()
	var has_elara = _has_elara()

	if has_elara:
		await DialogueManager.say("Elara", "Wait — the Data Wraith's core is still intact. It's corrupted, but the original process is still in there. We could...")
		if not is_inside_tree(): return
		await DialogueManager.say("Elara", "We could try to restore it. Purify the corruption and let the process thread run clean again. Or we could destroy it completely — make sure it never comes back.")
		if not is_inside_tree(): return
	else:
		await DialogueManager.say("Kaelen", "The Data Wraith's core is still intact. Pulsing with corrupted data. I can feel the original process buried underneath the corruption... still trying to run.")
		if not is_inside_tree(): return
		await DialogueManager.say("Kaelen (Internal)", "Three options. Purify it — restore the original process. Destroy it — end it permanently. Or... absorb it. Pull its power directly into Root Access. More corruption, but more power too.")
		if not is_inside_tree(): return

	var choice = await DialogueManager.show_choices(
		"What do you do with the Data Wraith's core?",
		[
			"Restore it — purify the corruption and let the process run",
			"Destroy it — eliminate the corrupted process permanently",
			"Absorb it — pull its power into Root Access"
		],
		"Kaelen"
	)
	if not is_inside_tree(): return

	match choice:
		0:  # Restore
			GameManager.set_story_flag("ch2_data_wraith_restored", true)
			await DialogueManager.say("Kaelen", "*using Root Access to purify the core* ...Cleaning corruption flags... restoring original parameters... done.")
			if not is_inside_tree(): return
			await DialogueManager.say("System", "[PROCESS THREAD RESTORED]\n[Status: CLEAN]\n[The data wraith dissolves into pure light]", Color(0, 1, 0.5), true)
			if not is_inside_tree(): return
			if has_elara:
				await DialogueManager.say("Elara", "You chose to heal instead of destroy. That says something about you, Kaelen.")
				if not is_inside_tree(): return
				GameManager.relationships["elara"] = GameManager.relationships.get("elara", 0) + 3
			else:
				await DialogueManager.say("Kaelen (Internal)", "Mercy. Again. The knight. Now this process. Am I choosing compassion... or am I afraid of what destruction does to my corruption meter?")
				if not is_inside_tree(): return
				await DialogueManager.say("System", "[KARMIC THREAD DETECTED]\n[Pattern: Preservation]\n[System Administrator notation: Subject favors restoration]", Color(0.5, 0.8, 1), true)
				if not is_inside_tree(): return

		1:  # Destroy
			GameManager.set_story_flag("ch2_data_wraith_destroyed", true)
			await DialogueManager.say("Kaelen", "*crushing the core* Some things are too broken to fix. Better to end it cleanly.")
			if not is_inside_tree(): return
			await DialogueManager.say("System", "[PROCESS THREAD TERMINATED]\n[Core destroyed]\n[Corruption +2%]", Color(1, 0.5, 0), true)
			if not is_inside_tree(): return
			GameManager.add_glitch_corruption(2.0)
			if has_elara:
				await DialogueManager.say("Elara", "*quietly* ...Was that mercy? Or convenience?")
				if not is_inside_tree(): return
			else:
				await DialogueManager.say("Kaelen (Internal)", "Gone. Permanently. Another deletion added to my growing list. The system is keeping count... and so am I.")
				if not is_inside_tree(): return

		2:  # Absorb
			GameManager.set_story_flag("ch2_data_wraith_absorbed", true)
			GameManager.add_glitch_corruption(5.0)
			await DialogueManager.say("Kaelen", "*reaching into the core with Root Access* I'm not destroying it or saving it. I'm TAKING it.")
			if not is_inside_tree(): return
			await DialogueManager.say("System", "[ROOT ACCESS: ABSORBING PROCESS CORE]\n[WARNING: Corruption surge — +5%]\n[WARNING: Power level significantly increased]\n[WARNING: System Administrator alert threshold breached]", Color(1, 0, 0), true)
			if not is_inside_tree(): return
			if camera and camera.has_method("shake"):
				camera.shake(10.0, 0.8)
			await DialogueManager.say("Kaelen", "*gasping* The power... I can feel every process thread in this sector. Every data pipe, every packet. It's overwhelming.")
			if not is_inside_tree(): return
			if has_elara:
				await DialogueManager.say("Elara", "*stepping back, horrified* Kaelen... your eyes. They're flickering. The corruption — you just jumped five percent in one moment! What have you DONE?!")
				if not is_inside_tree(): return
				await DialogueManager.say("Elara", "You're not healing the world or ending its pain. You're CONSUMING it. That's what the Administrator does. Is that what you want to become?")
				if not is_inside_tree(): return
				GameManager.relationships["elara"] = GameManager.relationships.get("elara", 0) - 5
			else:
				await DialogueManager.say("Kaelen (Internal)", "Power. Raw, unfiltered system power flowing through me. The corruption surged — 5% in a heartbeat — but the clarity... I can see EVERYTHING down here. Every wall, every data pipe, every hidden pathway.")
				if not is_inside_tree(): return
				await DialogueManager.say("Kaelen (Internal)", "This is dangerous. I know it's dangerous. But alone in the dark, with no allies and no guide... power is the only currency that matters.")
				if not is_inside_tree(): return
			await DialogueManager.say("System", "[ROOT ACCESS CAPACITY: EXPANDED]\n[New ability unlocked: PROCESS ABSORPTION]\n[The System Administrator has taken notice]", Color(1, 0.3, 0.3), true)
			if not is_inside_tree(): return

		_:
			GameManager.set_story_flag("ch2_data_wraith_restored", true)
			await DialogueManager.say("System", "[CHOICE RESOLUTION FALLBACK]\n[Defaulting to restoration path to preserve narrative continuity.]", Color(0, 1, 0.5), true)
			if not is_inside_tree(): return
			# BUG-21-29: Removed duplicate is_inside_tree() guard

	DialogueManager.hide_dialogue()
