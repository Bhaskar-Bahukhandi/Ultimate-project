extends Node2D

## Chapter 2: The Administrator's Game
## Sequence 7: Administrator Proxy — Final boss fight with 4-phase admin commands

@onready var player_node = $Player
@onready var camera = $Camera2D

var arena_running: bool = false
var boss_node = null
## ESC may only skip the post-fight scene. Before this, "not running and no
## boss" was also true during the pre-fight intro, letting ESC skip the boss.
var _boss_defeated: bool = false
var _root_access_panel: RootAccessPanel = null

func _has_elara() -> bool:
	return GameManager.has_elara()

func _has_flag(flag_name: String) -> bool:
	return GameManager.has_flag(flag_name)

func _ready() -> void:
	print("[CH2-ADMIN-BOSS] Initializing Administrator Proxy encounter")
	GameManager.change_state(GameManager.GameState.COMBAT)

	# Play boss fight music for the Administrator Proxy
	if has_node("/root/MusicManager"):
		MusicManager.play_track("boss_fight")

	if camera:
		camera.make_current()

	# Replace placeholder sprite with real player art
	if player_node:
		AssetManager.replace_player_sprite(player_node, "combat")

	_build_city_square()
	_setup_combat_hud()
	_setup_root_access()

	# Entry sequence
	await get_tree().create_timer(0.5).timeout
	if not is_inside_tree(): return
	await _entry_dialogue()

func _build_city_square() -> void:
	## Build the city square arena — dramatic red-tinted sky
	# Sky / background — ominous red
	var bg = ColorRect.new()
	bg.color = Color(0.12, 0.02, 0.02)
	bg.size = Vector2(1280, 720)
	bg.position = Vector2(0, 0)
	bg.z_index = -10
	add_child(bg)

	# Red atmospheric glow
	var atmo = ColorRect.new()
	atmo.color = Color(0.4, 0.05, 0.05, 0.3)
	atmo.size = Vector2(1280, 300)
	atmo.position = Vector2(0, 0)
	atmo.z_index = -9
	add_child(atmo)

	# Ground — cobblestone square
	var ground_rect = ColorRect.new()
	ground_rect.color = Color(0.2, 0.18, 0.15)
	ground_rect.size = Vector2(1280, 200)
	ground_rect.position = Vector2(0, 520)
	ground_rect.z_index = -5
	add_child(ground_rect)

	# Ground platform (physics)
	var ground = StaticBody2D.new()
	ground.position = Vector2(0, 520)
	var g_col = CollisionShape2D.new()
	var g_shape = RectangleShape2D.new()
	g_shape.size = Vector2(1280, 20)
	g_col.shape = g_shape
	g_col.position = Vector2(640, 10)
	ground.add_child(g_col)
	add_child(ground)

	# Left wall
	var left_wall = StaticBody2D.new()
	left_wall.position = Vector2(-10, 0)
	var lw_col = CollisionShape2D.new()
	var lw_shape = RectangleShape2D.new()
	lw_shape.size = Vector2(20, 720)
	lw_col.shape = lw_shape
	lw_col.position = Vector2(10, 360)
	left_wall.add_child(lw_col)
	add_child(left_wall)

	# Right wall
	var right_wall = StaticBody2D.new()
	right_wall.position = Vector2(1270, 0)
	var rw_col = CollisionShape2D.new()
	var rw_shape = RectangleShape2D.new()
	rw_shape.size = Vector2(20, 720)
	rw_col.shape = rw_shape
	rw_col.position = Vector2(10, 360)
	right_wall.add_child(rw_col)
	add_child(right_wall)

	# Elevated platform (tactical cover)
	_create_platform(Vector2(540, 400), Vector2(200, 15))

	# Damaged buildings in background
	for x in [80, 300, 900, 1100]:
		var building = ColorRect.new()
		building.color = Color(0.1, 0.08, 0.08)
		building.size = Vector2(120, randf_range(180, 300))
		building.position = Vector2(x, 520 - building.size.y)
		building.z_index = -8
		add_child(building)

	# Glitching lamp posts
	for x_pos in [200, 500, 780, 1060]:
		var lamp = ColorRect.new()
		lamp.color = Color(1, 0.3, 0.1, 0.5)
		lamp.size = Vector2(6, 15)
		lamp.position = Vector2(x_pos, 490)
		add_child(lamp)

		# Flicker effect
		var flicker = create_tween().set_loops()
		flicker.tween_property(lamp, "modulate:a", 0.2, randf_range(0.1, 0.3))
		flicker.tween_property(lamp, "modulate:a", 1.0, randf_range(0.1, 0.3))

	# Data streams (ominous vertical lines descending from sky)
	for i in range(8):
		var stream = ColorRect.new()
		stream.color = Color(1, 0, 0, 0.08)
		stream.size = Vector2(2, 520)
		stream.position = Vector2(randf_range(50, 1230), 0)
		stream.z_index = -7
		add_child(stream)

func _create_platform(pos: Vector2, plat_size: Vector2) -> void:
	var platform = StaticBody2D.new()
	platform.position = pos

	var rect = ColorRect.new()
	rect.color = Color(0.3, 0.25, 0.2)
	rect.size = plat_size
	platform.add_child(rect)

	var col = CollisionShape2D.new()
	var shape = RectangleShape2D.new()
	shape.size = plat_size
	col.shape = shape
	col.position = plat_size * 0.5
	platform.add_child(col)

	add_child(platform)

func _setup_combat_hud() -> void:
	## Create combat HUD with boss health bar
	var hud = CanvasLayer.new()
	hud.layer = 50
	hud.name = "CombatHUD"
	add_child(hud)

	# Top bar background
	var top_bar = ColorRect.new()
	top_bar.color = Color(0.05, 0.02, 0.02, 0.85)
	top_bar.size = Vector2(1280, 50)
	hud.add_child(top_bar)

	# Player HP
	var hp_label = Label.new()
	hp_label.name = "HPLabel"
	hp_label.text = "HP: %d/%d" % [GameManager.player_stats["hp"], GameManager.player_stats["max_hp"]]
	hp_label.position = Vector2(15, 12)
	hp_label.add_theme_font_size_override("font_size", 14)
	hp_label.add_theme_color_override("font_color", Color(0.3, 1, 0.3))
	hud.add_child(hp_label)

	# Level
	var level_label = Label.new()
	level_label.name = "LevelLabel"
	level_label.text = "Lv.%d" % GameManager.player_stats["level"]
	level_label.position = Vector2(200, 12)
	level_label.add_theme_font_size_override("font_size", 14)
	level_label.add_theme_color_override("font_color", Color(0.5, 0.8, 1))
	hud.add_child(level_label)

	# Boss HP bar — centered at top
	var boss_bar_bg = ColorRect.new()
	boss_bar_bg.name = "BossBarBG"
	boss_bar_bg.color = Color(0.15, 0, 0, 0.8)
	boss_bar_bg.size = Vector2(500, 30)
	boss_bar_bg.position = Vector2(390, 55)
	hud.add_child(boss_bar_bg)

	var boss_hp_bar = ProgressBar.new()
	boss_hp_bar.name = "BossHPBar"
	boss_hp_bar.size = Vector2(496, 26)
	boss_hp_bar.position = Vector2(392, 57)
	boss_hp_bar.value = 100
	boss_hp_bar.show_percentage = false
	hud.add_child(boss_hp_bar)

	var boss_name_label = Label.new()
	boss_name_label.name = "BossNameLabel"
	boss_name_label.text = "ADMINISTRATOR PROXY"
	boss_name_label.position = Vector2(510, 85)
	boss_name_label.add_theme_font_size_override("font_size", 12)
	boss_name_label.add_theme_color_override("font_color", Color(1, 0.3, 0.3))
	hud.add_child(boss_name_label)

	# Phase indicator
	var phase_label = Label.new()
	phase_label.name = "PhaseLabel"
	phase_label.text = "PHASE 1"
	phase_label.position = Vector2(1100, 12)
	phase_label.add_theme_font_size_override("font_size", 16)
	phase_label.add_theme_color_override("font_color", Color(1, 0.5, 0.2))
	hud.add_child(phase_label)

	# Initially hide boss HP elements until boss spawns
	boss_bar_bg.visible = false
	boss_hp_bar.visible = false
	boss_name_label.visible = false
	phase_label.visible = false

func _entry_dialogue() -> void:
	## 72-hour countdown expires — Administrator arrives
	var has_elara = _has_elara()

	await DialogueManager.say("System", "[ALERT: 72-HOUR COUNTDOWN EXPIRED]\n[ADMINISTRATOR DISPATCHED]\n[PREPARING LOCAL INSTANCE...]", Color(1, 0, 0), true)
	if not is_inside_tree(): return

	await DialogueManager.say("Kaelen", "The countdown... it's over. Something is coming.")
	if not is_inside_tree(): return

	if has_elara:
		await DialogueManager.say("Elara", "I can feel it. Reality is thinning — something is forcing its way through the world's firewall.")
		if not is_inside_tree(): return
	else:
		await DialogueManager.say("Kaelen (Internal)", "Reality is thinning. I can feel it in my skin — something is forcing its way through the world's firewall. And I'm standing here to meet it. Alone.")
		if not is_inside_tree(): return

	# Screen shake
	if camera and camera.has_method("shake"):
		camera.shake(15.0, 1.0)
	else:
		_simulate_shake()

	await get_tree().create_timer(1.0).timeout
	if not is_inside_tree(): return

	await DialogueManager.say("System", "[ADMINISTRATOR PROXY — ONLINE]\n[Authorization Level: SYSTEM]\n[Objective: PURGE UNAUTHORIZED USER]", Color(1, 0, 0), true)
	if not is_inside_tree(): return

	await DialogueManager.say("Administrator Proxy", "User 'Kaelen'. Unauthorized Root Access detected. You have been flagged for immediate termination.")
	if not is_inside_tree(): return

	await DialogueManager.say("Kaelen", "So you're the one who's been watching us. The Administrator.")
	if not is_inside_tree(): return

	await DialogueManager.say("Administrator Proxy", "I am merely a proxy — a subroutine dispatched to correct an anomaly. You are that anomaly. Your deletion has been scheduled.")
	if not is_inside_tree(): return

	if has_elara:
		await DialogueManager.say("Elara", "Kaelen, be careful! This thing is operating at system-level priority. It's like fighting the world itself!")
		if not is_inside_tree(): return
	else:
		await DialogueManager.say("Kaelen (Internal)", "System-level priority. This thing has the same authority as the world's operating system. Fighting it is like trying to argue with gravity.")
		if not is_inside_tree(): return
		if _has_flag("ch2_data_wraith_absorbed"):
			await DialogueManager.say("System", "[ROOT ACCESS: WRAITH ABSORPTION RESONATING]\n[Anomalous power detected — combat advantage possible]\n[Warning: Administrator Proxy may adapt to absorbed signature]", Color(0.8, 0.4, 1.0), true)
			if not is_inside_tree(): return

	await DialogueManager.say("Kaelen", "Then it's about time the world met its debugger.")
	if not is_inside_tree(): return

	DialogueManager.hide_dialogue()

	await get_tree().create_timer(1.0).timeout
	if not is_inside_tree(): return
	_spawn_boss()

func _spawn_boss() -> void:
	## Spawn the Administrator Proxy boss
	boss_node = AdministratorProxyBoss.new()
	boss_node.position = Vector2(900, 420)
	boss_node.name = "AdministratorProxy"

	# Boss sprite — tall, red-black figure
	var sprite = ColorRect.new()
	sprite.name = "Sprite"
	sprite.size = Vector2(50, 80)
	sprite.position = Vector2(-25, -80)
	sprite.color = Color(0.8, 0, 0.15)
	boss_node.add_child(sprite)

	# Collision shape
	var col = CollisionShape2D.new()
	var shape = RectangleShape2D.new()
	shape.size = Vector2(50, 80)
	col.shape = shape
	col.position = Vector2(0, -40)
	boss_node.add_child(col)

	# Health bar on boss
	var hp_bar = ProgressBar.new()
	hp_bar.name = "HealthBar"
	hp_bar.size = Vector2(60, 8)
	hp_bar.position = Vector2(-30, -95)
	hp_bar.value = 100
	hp_bar.show_percentage = false
	boss_node.add_child(hp_bar)

	# Connect boss signals
	if boss_node.has_signal("phase_changed"):
		boss_node.phase_changed.connect(_on_phase_changed)
	if boss_node.has_signal("admin_command_used"):
		boss_node.admin_command_used.connect(_on_admin_command_used)
	if boss_node.has_signal("boss_defeated"):
		boss_node.boss_defeated.connect(_on_boss_defeated)
	if boss_node.has_signal("health_changed"):
		boss_node.health_changed.connect(_on_boss_health_changed)

	# Track boss fight for flawless achievement
	if has_node("/root/GameManager"):
		GameManager.start_boss_fight()

	add_child(boss_node)

	# Show boss HP bar in HUD
	var hud = get_node_or_null("CombatHUD")
	if hud:
		var bar_bg = hud.get_node_or_null("BossBarBG")
		var bar = hud.get_node_or_null("BossHPBar")
		var name_label = hud.get_node_or_null("BossNameLabel")
		var phase_label = hud.get_node_or_null("PhaseLabel")
		if bar_bg: bar_bg.visible = true
		if bar: bar.visible = true
		if name_label: name_label.visible = true
		if phase_label: phase_label.visible = true

	arena_running = true

	# Boss entrance effect — fade in
	boss_node.modulate.a = 0.0
	var entrance_tween = create_tween()
	entrance_tween.tween_property(boss_node, "modulate:a", 1.0, 1.5)

func _on_phase_changed(new_phase: int) -> void:
	## Show dialogue for each boss phase transition
	# Update phase label
	var hud = get_node_or_null("CombatHUD")
	if hud:
		var phase_label = hud.get_node_or_null("PhaseLabel")
		if phase_label:
			phase_label.text = "PHASE %d" % new_phase

	match new_phase:
		2:
			await DialogueManager.say("Administrator Proxy", "Standard combat protocols insufficient. Elevating to Administrative Commands.")
			if not is_inside_tree(): return
			await DialogueManager.say("System", "[ADMIN COMMANDS UNLOCKED]\n[/ban] [/mute] [/teleport]", Color(1, 0.5, 0), true)
			if not is_inside_tree(): return
			DialogueManager.hide_dialogue()

		3:
			await DialogueManager.say("Administrator Proxy", "Enough games. Initiating deletion protocol.")
			if not is_inside_tree(): return
			await DialogueManager.say("System", "[WARNING: /delete COMMAND AUTHORIZED]\n[Target: User 'Kaelen']\n[Root Access interference detected]", Color(1, 0, 0), true)
			if not is_inside_tree(): return
			await DialogueManager.say("Kaelen", "You can't just delete me! My Root Access is fighting your commands!")
			if not is_inside_tree(): return
			DialogueManager.hide_dialogue()

		4:
			await DialogueManager.say("Administrator Proxy", "Impossible. No user should have this level of system access. What ARE you?")
			if not is_inside_tree(): return
			await DialogueManager.say("Kaelen", "I'm the one who rewrites the rules.")
			if not is_inside_tree(): return
			await DialogueManager.say("System", "[ROOT ACCESS VS ADMIN AUTHORITY]\n[REALITY CONFLICT IN PROGRESS]", Color(0, 1, 1), true)
			if not is_inside_tree(): return
			DialogueManager.hide_dialogue()

func _on_admin_command_used(command: String) -> void:
	## Visual feedback for admin commands
	if not player_node:
		return

	var indicator_pos = player_node.global_position + Vector2(0, -50)

	match command:
		"ban":
			if is_instance_valid(player_node):
				if VFXLibrary:
					VFXLibrary.spawn_status_indicator("/BAN — STUNNED!", indicator_pos, self, false)
		"mute":
			if is_instance_valid(player_node):
				if VFXLibrary:
					VFXLibrary.spawn_status_indicator("/MUTE — ABILITIES LOCKED!", indicator_pos, self, false)
		"teleport":
			if is_instance_valid(player_node):
				if VFXLibrary:
					VFXLibrary.spawn_status_indicator("/TELEPORT — RELOCATED!", indicator_pos, self, false)
		"delete":
			if is_instance_valid(player_node):
				if VFXLibrary:
					VFXLibrary.spawn_status_indicator("/DELETE BLOCKED BY ROOT ACCESS!", indicator_pos, self, false)
			GameManager.add_glitch_corruption(3.0)

			# Red flash effect
			var flash = ColorRect.new()
			flash.color = Color(1, 0, 0, 0.4)
			flash.size = Vector2(1280, 720)
			flash.z_index = 40
			add_child(flash)
			var flash_tween = create_tween()
			flash_tween.tween_property(flash, "modulate:a", 0.0, 0.5)
			flash_tween.tween_callback(flash.queue_free)

func _on_boss_health_changed(new_hp: float, max_hp: float) -> void:
	## Update the HUD boss HP bar when boss takes damage
	var hud = get_node_or_null("CombatHUD")
	if hud:
		var bar = hud.get_node_or_null("BossHPBar")
		if bar and max_hp > 0.0:
			bar.value = (new_hp / max_hp) * 100.0

func _on_boss_defeated() -> void:
	## Administrator Proxy defeated — major story moment
	arena_running = false
	_boss_defeated = true
	var has_elara = _has_elara()
	if has_node("/root/GameManager"):
		GameManager.end_boss_fight()
		GameManager.set_story_flag("ch2_administrator_proxy_defeated", true)
	GameManager.auto_save()  # Autosave on boss defeat
	GameManager.add_glitch_corruption(8.0)

	print("[CH2-ADMIN-BOSS] Administrator Proxy defeated! +8% corruption")

	await get_tree().create_timer(2.0).timeout
	if not is_inside_tree(): return

	await DialogueManager.say("Administrator Proxy", "*static and distortion* Im...possible. A user... defeating an Administrator process...")
	if not is_inside_tree(): return

	await DialogueManager.say("Administrator Proxy", "Interesting. You are far more capable than your profile suggested. The real Administrator will want to know about this.")
	if not is_inside_tree(): return

	await DialogueManager.say("Kaelen", "*breathing heavily* The REAL Administrator? You mean there's something above you?")
	if not is_inside_tree(): return

	await DialogueManager.say("Administrator Proxy", "*voice breaking apart* I am... merely... a proxy. A shadow of true authority. When THEY come for you... and they WILL come... no amount of Root Access will save you.")
	if not is_inside_tree(): return

	await DialogueManager.say("System", "[ADMINISTRATOR PROXY — OFFLINE]\n[Corruption spike: +8%]\n[WARNING: Primary Administrator notified]\n[WARNING: Your location has been logged]", Color(1, 0, 0), true)
	if not is_inside_tree(): return

	if has_elara:
		await DialogueManager.say("Elara", "Kaelen... your corruption level just spiked. That fight cost us dearly.")
		if not is_inside_tree(): return
		await DialogueManager.say("Kaelen", "But we survived. And now we know — there's something bigger controlling this world. Something that sent that proxy after us.")
		if not is_inside_tree(): return
		await DialogueManager.say("Elara", "The real Administrator. The one pulling all the strings.")
		if not is_inside_tree(): return
		await DialogueManager.say("Kaelen", "We need to find the remaining Source Key Fragments before they send something worse. Five more fragments, and we might have enough power to face whatever's really running this world.")
		if not is_inside_tree(): return
	else:
		await DialogueManager.say("Kaelen", "*checking his hands — corruption veins pulsing* The corruption... it spiked. That fight cost me more than I can see.")
		if not is_inside_tree(): return
		await DialogueManager.say("Kaelen (Internal)", "But I survived. Alone. Against a system-level process. And now I know — there's something bigger out there. Something that sent this proxy like an exterminator sends a roach trap.")
		if not is_inside_tree(): return
		await DialogueManager.say("Kaelen", "The 'real' Administrator. The one pulling all the strings. Five more Source Key Fragments, and maybe I'll have enough power to face it.")
		if not is_inside_tree(): return
		if _has_flag("ch1_knight_killed") and _has_flag("ch2_data_wraith_absorbed"):
			await DialogueManager.say("Kaelen (Internal)", "I've killed, absorbed, and destroyed my way through two chapters of this world. When I finally meet the real Administrator... what will it see when it looks at me? A hero? Or a virus?")
			if not is_inside_tree(): return
		elif _has_flag("ch1_knight_spared"):
			await DialogueManager.say("Kaelen (Internal)", "I spared a knight. I fought a god's proxy. There has to be a way through this that doesn't cost me everything I am.")
			if not is_inside_tree(): return

	DialogueManager.hide_dialogue()

	# Transition to Seraphina's choice
	await get_tree().create_timer(1.5).timeout
	if not is_inside_tree(): return
	SceneTransitions.change_scene("res://scenes/chapter2/seraphina_choice.tscn")

func _simulate_shake() -> void:
	## Fallback screen shake when no CinematicCamera
	var original_pos = position
	var shake_tween = create_tween()
	for i in range(10):
		shake_tween.tween_property(self, "position", original_pos + Vector2(randf_range(-8, 8), randf_range(-6, 6)), 0.04)
	shake_tween.tween_property(self, "position", original_pos, 0.1)

func _setup_root_access() -> void:
	## Add the reusable Root Access panel.
	_root_access_panel = RootAccessPanel.new()
	var hud = get_node_or_null("CombatHUD")
	if hud:
		hud.add_child(_root_access_panel)
	else:
		add_child(_root_access_panel)

func _input(event) -> void:
	# Root Access toggle
	if event.is_action_pressed("root_access") and arena_running and _root_access_panel:
		if _root_access_panel.visible:
			_root_access_panel.close()
		elif boss_node and is_instance_valid(boss_node):
			_root_access_panel.open(boss_node, 5.0)  # Boss hacks cost 5% corruption
		get_viewport().set_input_as_handled()
		return

	if event.is_action_pressed("ui_cancel") and _boss_defeated:
		if DialogueManager.is_active:
			return  # Don't skip during post-boss dialogue
		DialogueManager.hide_dialogue()
		SceneTransitions.change_scene("res://scenes/chapter2/seraphina_choice.tscn")
		get_viewport().set_input_as_handled()
