extends Node2D

## Chapter 2: The Administrator's Game
## Sequence 3: Arena District — Wave-based combat grinding

@onready var player_node = $Player
@onready var enemies_container = $Enemies
@onready var arena_mgr = $ArenaManager

var current_tier: String = "bronze"
var arena_running: bool = false
var _waiting_for_input: bool = false
var _in_results: bool = false
var _root_access_panel: RootAccessPanel = null

const ARENA_DLG := "res://dialogue/ch2/arena.dlg"

func _ready() -> void:
	print("[CH2-ARENA] Initializing Battle Arena")
	GameManager.change_state(GameManager.GameState.COMBAT)

	# Play combat music for the arena
	if has_node("/root/MusicManager"):
		MusicManager.play_track("arena")  # Pass 53: Use dedicated arena track

	# Replace placeholder sprite with real player art
	if player_node:
		AssetManager.replace_player_sprite(player_node, "combat")

	# Discover arena side quests
	if has_node("/root/SideQuestManager"):
		SideQuestManager.discover_quest("ironhold_arena_legend")
		SideQuestManager.discover_quest("ironhold_underground_data")
		SideQuestManager.discover_quest("ironhold_merchant_guild")

	_build_arena_environment()
	_setup_combat_hud()
	_setup_arena_manager()
	_setup_root_access()

	# Arena intro
	await get_tree().create_timer(0.5).timeout
	if not is_inside_tree(): return
	await _show_tier_selection()

func _build_arena_environment() -> void:
	## Build the arena combat area
	# Floor
	var floor_rect = ColorRect.new()
	floor_rect.color = Color(0.2, 0.15, 0.1)
	floor_rect.size = Vector2(1280, 200)
	floor_rect.position = Vector2(0, 520)
	floor_rect.z_index = -5
	add_child(floor_rect)

	# Arena walls
	var left_wall = StaticBody2D.new()
	left_wall.position = Vector2(0, 0)
	var lw_col = CollisionShape2D.new()
	var lw_shape = RectangleShape2D.new()
	lw_shape.size = Vector2(20, 720)
	lw_col.shape = lw_shape
	lw_col.position = Vector2(10, 360)
	left_wall.add_child(lw_col)
	add_child(left_wall)

	var right_wall = StaticBody2D.new()
	right_wall.position = Vector2(1260, 0)
	var rw_col = CollisionShape2D.new()
	var rw_shape = RectangleShape2D.new()
	rw_shape.size = Vector2(20, 720)
	rw_col.shape = rw_shape
	rw_col.position = Vector2(10, 360)
	right_wall.add_child(rw_col)
	add_child(right_wall)

	# Ground platform
	var ground = StaticBody2D.new()
	ground.position = Vector2(0, 520)
	var g_col = CollisionShape2D.new()
	var g_shape = RectangleShape2D.new()
	g_shape.size = Vector2(1280, 20)
	g_col.shape = g_shape
	g_col.position = Vector2(640, 10)
	ground.add_child(g_col)
	add_child(ground)

	# Elevated platforms for tactical gameplay
	_create_platform(Vector2(300, 400), Vector2(200, 15))
	_create_platform(Vector2(780, 400), Vector2(200, 15))
	_create_platform(Vector2(540, 300), Vector2(180, 15))

	# Background (arena stands)
	var bg = ColorRect.new()
	bg.color = Color(0.15, 0.12, 0.08)
	bg.size = Vector2(1280, 520)
	bg.position = Vector2(0, 0)
	bg.z_index = -10
	add_child(bg)

	# Decorative torch-like lights
	for x_pos in [100, 400, 640, 880, 1180]:
		var torch = ColorRect.new()
		torch.color = Color(1, 0.6, 0.2, 0.6)
		torch.size = Vector2(10, 20)
		torch.position = Vector2(x_pos, 30)
		add_child(torch)

	# Enemies container
	if not enemies_container:
		enemies_container = Node2D.new()
		enemies_container.name = "Enemies"
		add_child(enemies_container)

func _create_platform(pos: Vector2, plat_size: Vector2) -> void:
	var platform = StaticBody2D.new()
	platform.position = pos

	var rect = ColorRect.new()
	rect.color = Color(0.35, 0.3, 0.2)
	rect.size = plat_size
	platform.add_child(rect)

	var col = CollisionShape2D.new()
	var shape = RectangleShape2D.new()
	shape.size = plat_size
	col.shape = shape
	col.position = plat_size * 0.5
	platform.add_child(col)

	add_child(platform)

func _setup_arena_manager() -> void:
	## Initialize the arena manager
	if not arena_mgr:
		arena_mgr = ArenaManager.new()
		arena_mgr.name = "ArenaManager"
		add_child(arena_mgr)

	arena_mgr.setup(enemies_container, Rect2(100, 350, 1080, 150))
	arena_mgr.arena_victory.connect(_on_arena_victory)
	arena_mgr.arena_defeat.connect(_on_arena_defeat)

func _setup_root_access() -> void:
	## Add the reusable Root Access panel to the HUD.
	_root_access_panel = RootAccessPanel.new()
	var hud = get_node_or_null("CombatHUD")
	if hud:
		hud.add_child(_root_access_panel)
	else:
		add_child(_root_access_panel)

func _setup_combat_hud() -> void:
	## Create the combat HUD
	var hud = CanvasLayer.new()
	hud.layer = 50
	hud.name = "CombatHUD"
	add_child(hud)

	# Top bar
	var top_bar = ColorRect.new()
	top_bar.color = Color(0.05, 0.05, 0.1, 0.85)
	top_bar.size = Vector2(1280, 45)
	hud.add_child(top_bar)

	# Player HP
	var hp_label = Label.new()
	hp_label.name = "HPLabel"
	hp_label.text = "HP: %d/%d" % [GameManager.player_stats["hp"], GameManager.player_stats["max_hp"]]
	hp_label.position = Vector2(15, 10)
	hp_label.add_theme_font_size_override("font_size", 14)
	hp_label.add_theme_color_override("font_color", Color(0.3, 1, 0.3))
	hud.add_child(hp_label)

	# Level
	var level_label = Label.new()
	level_label.name = "LevelLabel"
	level_label.text = "Lv.%d" % GameManager.player_stats["level"]
	level_label.position = Vector2(200, 10)
	level_label.add_theme_font_size_override("font_size", 14)
	level_label.add_theme_color_override("font_color", Color(0.5, 0.8, 1))
	hud.add_child(level_label)

	# Gold
	var gold_label = Label.new()
	gold_label.name = "GoldLabel"
	gold_label.text = "Gold: %d" % GameManager.player_stats["gold"]
	gold_label.position = Vector2(300, 10)
	gold_label.add_theme_font_size_override("font_size", 14)
	gold_label.add_theme_color_override("font_color", Color(1, 0.85, 0.1))
	hud.add_child(gold_label)

	# XP Progress
	var xp_label = Label.new()
	xp_label.name = "XPLabel"
	var xp_next = GameManager.get_xp_for_next_level()
	if xp_next > 0:
		xp_label.text = "XP: %d/%d" % [GameManager.player_stats["xp"], xp_next]
	else:
		xp_label.text = "XP: MAX"
	xp_label.position = Vector2(450, 10)
	xp_label.add_theme_font_size_override("font_size", 14)
	xp_label.add_theme_color_override("font_color", Color(0.6, 0.9, 1.0))
	hud.add_child(xp_label)

	# Attack stat
	var atk_label = Label.new()
	atk_label.name = "ATKLabel"
	atk_label.text = "ATK: %d" % GameManager.player_stats.get("attack", 15)
	atk_label.position = Vector2(620, 10)
	atk_label.add_theme_font_size_override("font_size", 14)
	atk_label.add_theme_color_override("font_color", Color(1, 0.5, 0.5))
	hud.add_child(atk_label)

	# Tier indicator
	var tier_label = Label.new()
	tier_label.name = "TierLabel"
	tier_label.text = "ARENA — %s" % current_tier.to_upper()
	tier_label.position = Vector2(900, 10)
	tier_label.add_theme_font_size_override("font_size", 16)
	tier_label.add_theme_color_override("font_color", Color(1, 0.6, 0.2))
	hud.add_child(tier_label)

	# Streak counter
	var streak_label = Label.new()
	streak_label.name = "StreakLabel"
	streak_label.text = "Streak: %d" % GameManager.arena_stats["win_streak"]
	streak_label.position = Vector2(1100, 10)
	streak_label.add_theme_font_size_override("font_size", 14)
	streak_label.add_theme_color_override("font_color", Color(1, 0.4, 0.4))
	hud.add_child(streak_label)
	_fit_hud_around_player_hud(hud, top_bar)

## The player's own combat HUD (player_combat.gd) already shows HP, level, gold
## and XP top-left and top-right; this scene's full-width bar was drawn right
## over it. Keep only what's unique to the arena, in the free space top-centre.
func _fit_hud_around_player_hud(hud: CanvasLayer, top_bar: ColorRect) -> void:
	for dup in ["HPLabel", "LevelLabel", "GoldLabel", "XPLabel"]:
		var n := hud.get_node_or_null(dup) as CanvasItem
		if n:
			n.visible = false
	top_bar.position = Vector2(440, 4)
	top_bar.size = Vector2(520, 36)
	var place := {"TierLabel": Vector2(456, 12), "ATKLabel": Vector2(700, 12), "StreakLabel": Vector2(820, 12)}
	for label_name in place:
		var l := hud.get_node_or_null(label_name) as Control
		if l:
			l.position = place[label_name]

func _show_tier_selection() -> void:
	## Show tier selection dialogue
	# C2-S08 — the first visit gets Vex's welcome and the corner advice.
	if not GameManager.has_flag("ch2_arena_entered"):
		GameManager.set_story_flag("ch2_arena_entered", true)
		await DialogueManager.run(ARENA_DLG, "enter")
		if not is_inside_tree(): return

	# Use a simple tier menu via dialogue choices
	var available_tiers = []
	for tier in ["bronze", "silver", "gold", "platinum"]:
		if arena_mgr.is_tier_available(tier):
			available_tiers.append(tier)

	if available_tiers.size() == 0:
		await DialogueManager.say("Vex", "No bracket'll take you yet, fighter. Go and get a bit harder first.")
		if not is_inside_tree(): return
		_return_to_city()
		return

	# For prototype, start with highest available tier
	current_tier = available_tiers[available_tiers.size() - 1]

	await DialogueManager.say("Vex", "%s bracket! %d waves! Try to look like you meant to come!" % [current_tier.capitalize(), arena_mgr.TIER_DATA[current_tier]["waves"]])
	if not is_inside_tree(): return
	DialogueManager.hide_dialogue()

	await get_tree().create_timer(1.0).timeout
	if not is_inside_tree(): return
	arena_running = true
	arena_mgr.start_arena(current_tier)

func _on_arena_victory(tier: String) -> void:
	## Called when all waves are cleared
	arena_running = false
	_in_results = true
	print("[CH2-ARENA] Victory in %s tier!" % tier)
	_update_hud()

	await get_tree().create_timer(2.0).timeout
	if not is_inside_tree(): return

	# Set tier completion flag
	var tier_flag = "ch2_arena_%s_complete" % tier
	if not GameManager.story_flags.get(tier_flag, false):
		GameManager.set_story_flag(tier_flag, true)

	# Set aggregate arena-complete flag once gold tier is cleared
	if tier == "gold" and not GameManager.story_flags.get("ch2_arena_complete", false):
		GameManager.set_story_flag("ch2_arena_complete", true)

	if tier == "bronze":
		await _grant_bronze_arena_material_reward()
		if not is_inside_tree(): return

	# C2-S09 — between rounds, the memorial wall.
	if not GameManager.has_flag("ch2_arena_memorial_seen"):
		await DialogueManager.run(ARENA_DLG, "memorial")
		if not is_inside_tree(): return

	await DialogueManager.run(ARENA_DLG, "again")
	if not is_inside_tree(): return
	DialogueManager.hide_dialogue()
	_in_results = false
	_waiting_for_input = true

func _grant_bronze_arena_material_reward() -> void:
	if GameManager.has_flag("ch2_arena_material_reward_claimed"):
		return

	GameManager.set_story_flag("ch2_arena_material_reward_claimed", true)
	_sync_crafting_materials()
	if has_node("/root/Inventory"):
		Inventory.add_item("data_ore", 1)
	if has_node("/root/LoreJournal"):
		LoreJournal.discover("ironhold_blacksmith_craft_loop")

	await DialogueManager.say("Vex", "Bronze spoils! Garro asked me to pass on a chunk of Data Ore. Take it to his forge, come back louder.")
	if not is_inside_tree(): return
	await DialogueManager.say("System", "[ARENA MATERIAL]\nReceived: Data Ore x1", Color(0.0, 1.0, 0.5), true)

func _sync_crafting_materials() -> void:
	if has_node("/root/CraftingSystem"):
		CraftingSystem.get_recipes()

func _on_arena_defeat() -> void:
	## Called when player is defeated
	arena_running = false
	_in_results = true
	print("[CH2-ARENA] Defeat in arena")
	_update_hud()

	await get_tree().create_timer(2.0).timeout
	if not is_inside_tree(): return
	await DialogueManager.run(ARENA_DLG, "again_after_loss")
	if not is_inside_tree(): return
	DialogueManager.hide_dialogue()
	_in_results = false
	_waiting_for_input = true

func _return_to_city() -> void:
	## Return to Ironhold city hub
	DialogueManager.hide_dialogue()
	_waiting_for_input = false
	SceneTransitions.change_scene("res://scenes/regions/ironhold_region.tscn")

func _update_hud() -> void:
	## Refresh the combat HUD with current stats
	var hud = get_node_or_null("CombatHUD")
	if not hud:
		return
	var hp_label = hud.get_node_or_null("HPLabel")
	if hp_label:
		hp_label.text = "HP: %d/%d" % [GameManager.player_stats["hp"], GameManager.player_stats["max_hp"]]
	var level_label = hud.get_node_or_null("LevelLabel")
	if level_label:
		level_label.text = "Lv.%d" % GameManager.player_stats["level"]
	var gold_label = hud.get_node_or_null("GoldLabel")
	if gold_label:
		gold_label.text = "Gold: %d" % GameManager.player_stats["gold"]
	var xp_label = hud.get_node_or_null("XPLabel")
	if xp_label:
		var xp_next = GameManager.get_xp_for_next_level()
		if xp_next > 0:
			xp_label.text = "XP: %d/%d" % [GameManager.player_stats["xp"], xp_next]
		else:
			xp_label.text = "XP: MAX"
	var streak_label = hud.get_node_or_null("StreakLabel")
	if streak_label:
		streak_label.text = "Streak: %d" % GameManager.arena_stats["win_streak"]
	var tier_label = hud.get_node_or_null("TierLabel")
	if tier_label:
		tier_label.text = "ARENA — %s" % current_tier.to_upper()

func _input(event) -> void:
	# Root Access toggle
	if event.is_action_pressed("root_access") and arena_running and _root_access_panel:
		if _root_access_panel.visible:
			_root_access_panel.close()
		elif player_node:
			var enemy = _root_access_panel.get_nearest_enemy(player_node.global_position)
			if enemy:
				_root_access_panel.open(enemy, 2.0)  # Arena hacks cost 2% corruption
		get_viewport().set_input_as_handled()
		return
	
	if _waiting_for_input:
		if event.is_action_pressed("ui_accept"):
			# Fight again!
			_waiting_for_input = false
			# Heal player partially between rounds (50% recovery)
			var heal_amount = GameManager.player_stats["max_hp"] * 0.5
			GameManager.player_stats["hp"] = min(GameManager.player_stats["hp"] + int(heal_amount), GameManager.player_stats["max_hp"])
			_update_hud()
			arena_running = true
			arena_mgr.start_arena(current_tier)
		elif event.is_action_pressed("ui_cancel"):
			_return_to_city()
	elif event.is_action_pressed("ui_cancel") and not arena_running and not _in_results:
		_return_to_city()
