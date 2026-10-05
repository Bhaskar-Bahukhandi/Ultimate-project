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

func _attach_camera_to_player() -> void:
	if not is_instance_valid(camera) or not is_instance_valid(player_node):
		return
	camera.reparent(player_node, false)
	camera.position = Vector2(0, -40)
	camera.position_smoothing_enabled = true
	camera.make_current()

func _ready() -> void:
	print("[CH2-UNDERGROUND] Initializing Underground Network dungeon")
	GameManager.change_state(GameManager.GameState.EXPLORATION)

	# Play exploration music for the underground
	if has_node("/root/MusicManager"):
		MusicManager.play_track("underground")  # Pass 53: Use dedicated underground track

	if camera:
		camera.make_current()
		# The camera was a fixed sibling of the player, so the 3200 px dungeon
		# scrolled off-screen past x≈940. Make it follow the player.
		_attach_camera_to_player.call_deferred()

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

const UG_DLG := "res://dialogue/ch2/underground.dlg"

func _entry_dialogue() -> void:
	# PASS-34 FIX: Auto-save checkpoint on dungeon entry
	GameManager.auto_save()
	if OS.is_debug_build():
		print("[CHECKPOINT] Underground Network — entry auto-save")

	# PASS-35 FIX: Discover and start underground side quest
	if has_node("/root/SideQuestManager"):
		SideQuestManager.discover_quest("ironhold_underground_data")
		SideQuestManager.start_quest("ironhold_underground_data")

	await DialogueManager.run(UG_DLG, "entry", _on_ug_event)

func _on_ug_event(event: String) -> void:
	var parts := event.split(" ", false, 1)
	match parts[0]:
		"lights_flicker", "wraith_hostile", "wraith_unstable", "wraith_split", "wraith_ends":
			if camera and camera.has_method("shake"):
				camera.shake(5.0, 0.3)
			await get_tree().create_timer(0.35).timeout
		"data_vision_wraith", "kaelen_writes_name":
			await get_tree().create_timer(0.5).timeout
		"root_edit":
			GameManager.add_glitch_corruption(3.0)
		"absorb_wraith":
			GameManager.add_glitch_corruption(5.0)
			if camera and camera.has_method("shake"):
				camera.shake(10.0, 0.8)
		_:
			print("[CH2-UNDERGROUND] unhandled dialogue event: %s" % event)

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
	# Chamber walls stop above a doorway at floor level. They used to run from
	# the top down to the floor (y 520) with no opening, and the boss chamber
	# was a closed box — its entrance could only be reached through walls.
	var platforms = [
		# Entry corridor
		Rect2(0, 500, 600, 20),
		Rect2(0, 300, 20, 220),  # Left wall (map edge — stays solid)
		# First chamber
		Rect2(600, 500, 500, 20),
		Rect2(600, 200, 20, 200),  # Wall — doorway y 400-500
		Rect2(1080, 200, 20, 130),  # Wall — doorway y 330-500 up to the passage
		# Connecting passage
		Rect2(1100, 400, 300, 20),
		# Puzzle chamber
		Rect2(1400, 500, 600, 20),
		Rect2(1400, 150, 20, 180),  # Wall — doorway y 330-500 from the passage
		Rect2(1980, 150, 20, 180),  # Wall — doorway y 330-500 up to the corridor
		# Final corridor
		Rect2(2000, 400, 400, 20),
		# Boss chamber
		Rect2(2400, 500, 800, 20),
		Rect2(2400, 100, 20, 230),  # Wall — doorway y 330-500 from the corridor
		Rect2(3180, 100, 20, 420),  # Wall (map edge — stays solid)
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
	## A routing junction in the puzzle chamber, where the first stuck workers
	## are; then the approach to the Wraith (C2-S12), where the lights speak.
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

	var approach := Area2D.new()
	approach.name = "WraithApproach"
	approach.position = Vector2(2450, 420)
	var a_col := CollisionShape2D.new()
	var a_shape := CircleShape2D.new()
	a_shape.radius = 90.0
	a_col.shape = a_shape
	approach.add_child(a_col)
	approach.body_entered.connect(_on_wraith_approach)
	add_child(approach)

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

	await DialogueManager.run(UG_DLG, "workers", _on_ug_event)
	if not is_inside_tree(): return
	await DialogueManager.run(UG_DLG, "routing", _on_ug_event)

var _wraith_approached := false

func _on_wraith_approach(body) -> void:
	if not body.is_in_group("player") or _wraith_approached:
		return
	_wraith_approached = true
	await DialogueManager.run(UG_DLG, "wraith_lights", _on_ug_event)
	if not is_inside_tree(): return
	await DialogueManager.run(UG_DLG, "recognition", _on_ug_event)

func _on_data_wraith_defeated() -> void:
	## B03 down; C2-S13 the choice (restore / destroy / absorb). Fragment Two
	## comes later, after the Administrator Proxy (C2-S15).
	data_wraith_defeated = true
	GameManager.set_story_flag("ch2_data_wraith_defeated", true)
	GameManager.auto_save()  # Autosave on boss defeat

	await get_tree().create_timer(1.0).timeout
	if not is_inside_tree(): return

	# Boss loot: Phantom Cloak armour
	if Inventory and Inventory.has_method("add_item"):
		Inventory.add_item("data_wraith_phantom_cloak", 1)
		Inventory.add_gold(600)
	await DialogueManager.say("System", "[ITEM ACQUIRED: PHANTOM CLOAK]", Color(0, 1, 1), true)
	if not is_inside_tree(): return

	await DialogueManager.run(UG_DLG, "choice", _on_ug_event)
	if not is_inside_tree(): return

	GameManager.set_story_flag("ch2_underground_complete", true)
	DialogueManager.hide_dialogue()

	await get_tree().create_timer(1.5).timeout
	if not is_inside_tree(): return
	SceneTransitions.change_scene("res://scenes/regions/ironhold_region.tscn")
