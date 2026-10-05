extends Node2D

## Chapter 1, C1-S01 to C1-S07 — Oakhaven. Top-down. Words are in dialogue/ch1/:
##   oakhaven_gate.dlg (Bran, the road ledger) → elara_house.dlg (stew)
##   → oakhaven_village.dlg (a normal afternoon: Mara, Old Fen, Jessa, the
##   farmers, the child and the chicken, the Whispering Stone)
##   → north_field.dlg (the alarm, the uphill water, the boar, the bridge).
## The alarm comes once the player has met a few people (the village has to
## feel lived in before it's threatened), or when they walk to the north
## field or the bridge. Aldric, Fragment One and the village meeting happen in
## the Tutorial Knight scene.

const DLG_DIR := "res://dialogue/ch1/"
const ALARM_AFTER_BEATS := 3          # afternoon conversations before the alarm
const NORTH_FIELD_POS := Vector2(1440, 1380)

@onready var shop_panel = get_node_or_null("UI/ShopPanel")
@onready var auction_panel = get_node_or_null("UI/AuctionPanel")
@onready var glitch_meter_bar = get_node_or_null("UI/HUD/TopBar/MarginContainer/HBoxContainer/RightInfo/GlitchMeter")
@onready var glitch_label = get_node_or_null("UI/HUD/TopBar/MarginContainer/HBoxContainer/RightInfo/GlitchLabel")
@onready var gold_label = get_node_or_null("UI/HUD/TopBar/MarginContainer/HBoxContainer/RightInfo/GoldLabel")
@onready var fade_rect = get_node_or_null("FadeRect")

var in_dialogue: bool = false
var in_shop: bool = false
var _is_transitioning: bool = false
var _dlg_depth := 0
var _entrance_done := false
var _alarm_done := false
var _field_resolved := false
var _field_running := false
var _bridge_done := false
var _bridge_running := false
var _seen: Dictionary = {}            # dialogue node -> true once played
var _afternoon_beats := 0
var _sword_pickup: Area2D = null

# Shop items for the fallback shop (ShopSystem normally handles it).
var shop_items = [
	{"id": "red_potion", "name": "Red Potion", "desc": "Restores 50 HP (Integrity)", "cost": 10, "effect": "heal", "value": 50},
	{"id": "blue_potion", "name": "Blue Potion", "desc": "Restores 10MB RAM (Mana)", "cost": 15, "effect": "restore_mana", "value": 10},
	{"id": "null_potion", "name": "Null Potion", "desc": "Restores 100% Integrity. Blinds for 5s.", "cost": 500, "effect": "null_heal", "value": 100},
]

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	GameManager.change_state(GameManager.GameState.EXPLORATION)
	GameManager.set_story_flag("ch1_oakhaven_entered", true)
	if not GameManager.glitch_meter_changed.is_connected(_on_glitch_meter_changed):
		GameManager.glitch_meter_changed.connect(_on_glitch_meter_changed)

	if has_node("/root/MusicManager"):
		MusicManager.play_track("exploration")

	var player = get_node_or_null("Player")
	if player:
		AssetManager.replace_player_sprite(player, "exploration")
	_setup_elara_v2_visual()

	var current_gold = GameManager.player_stats.get("gold", 0)
	if current_gold < 100:
		GameManager.add_gold(100 - current_gold)

	_create_map_boundaries()
	_set_up_villagers()

	if shop_panel:
		shop_panel.visible = false
	if auction_panel:
		auction_panel.visible = false

	if fade_rect:
		fade_rect.modulate = Color(0, 0, 0, 1)
		var tween = create_tween()
		tween.tween_property(fade_rect, "modulate:a", 0.0, 1.5)

	_update_gold_display()
	_update_glitch_display()

	await get_tree().create_timer(1.2).timeout
	if not is_inside_tree(): return
	await _play_entrance()


func _exit_tree() -> void:
	if has_node("/root/GameManager") and GameManager.glitch_meter_changed.is_connected(_on_glitch_meter_changed):
		GameManager.glitch_meter_changed.disconnect(_on_glitch_meter_changed)

# ── Dialogue plumbing ─────────────────────────────────────────────────────

## Plays one .dlg node. While any node is playing, in_dialogue is true (the
## other triggers wait) and the game is in the DIALOGUE state.
func _run(file: String, node: String) -> Dictionary:
	_dlg_depth += 1
	in_dialogue = true
	GameManager.change_state(GameManager.GameState.DIALOGUE)
	var r: Dictionary = await DialogueManager.run(DLG_DIR + file + ".dlg", node, _on_dlg_event)
	_dlg_depth -= 1
	if _dlg_depth == 0:
		in_dialogue = false
		if is_inside_tree() and not _is_transitioning:
			GameManager.change_state(GameManager.GameState.EXPLORATION)
	return r

## Plays a node only the first time; returns true if it played.
func _run_once(file: String, node: String) -> bool:
	if _seen.has(node):
		return false
	_seen[node] = true
	await _run(file, node)
	return true

func _on_dlg_event(event: String) -> void:
	var parts := event.split(" ", false, 1)
	match parts[0]:
		"bran_opens_ledger", "ledger_entry_highlight", "elara_serves_stew", "elara_stands", "elara_sees_him_look", "dig_channel", "boar_nest_anchor":
			await get_tree().create_timer(0.35).timeout
		"gate_opens", "start_boar_fight", "quest_start", "objective", "journal":
			pass
		"chicken_duplicate":
			_flash_second_chicken()
		"bell_alarm", "boar_charge", "boar_pogo":
			_shake(9.0 if parts[0] != "bell_alarm" else 5.0)
			await get_tree().create_timer(0.4).timeout
		"boar_stunned":
			await get_tree().create_timer(0.3).timeout
		"fracture_spreads":
			_flash(Color(0.55, 0.0, 0.7, 0.35))
		"root_edit":
			GameManager.add_glitch_corruption(5.0)
			_flash(Color(0.0, 1.0, 0.5, 0.3))
		"time_passes":
			await _fade(1.0, 0.8)
			await get_tree().create_timer(0.6).timeout
			await _fade(0.0, 0.8)
		_:
			print("[OAKHAVEN] unhandled dialogue event: %s" % event)

func _fade(alpha: float, seconds: float) -> void:
	if not fade_rect:
		return
	var t := create_tween()
	t.tween_property(fade_rect, "modulate:a", alpha, seconds)
	await t.finished

func _flash(color: Color) -> void:
	if not fade_rect:
		return
	var old: Color = fade_rect.color
	fade_rect.color = Color(color.r, color.g, color.b)
	fade_rect.modulate.a = color.a
	var t := create_tween()
	t.tween_property(fade_rect, "modulate:a", 0.0, 0.35)
	t.tween_callback(func(): fade_rect.color = old)

func _shake(strength: float) -> void:
	var camera = get_viewport().get_camera_2d()
	if camera:
		var t := create_tween()
		t.tween_property(camera, "offset", Vector2(strength, -strength * 0.6), 0.04)
		t.tween_property(camera, "offset", Vector2(-strength, strength * 0.6), 0.04)
		t.tween_property(camera, "offset", Vector2.ZERO, 0.06)

# ── C1-S01 / S01B / S02: arriving ─────────────────────────────────────────

func _play_entrance() -> void:
	await _run("oakhaven_gate", "start")
	if not is_inside_tree(): return
	await _run("oakhaven_gate", "ledger")
	if not is_inside_tree(): return
	await _run("elara_house", "invite")
	if not is_inside_tree(): return
	await _fade(1.0, 0.6)
	if not is_inside_tree(): return
	await _run("elara_house", "start")
	if not is_inside_tree(): return
	await _fade(0.0, 0.8)
	_entrance_done = true

# ── C1-S03: a normal afternoon ────────────────────────────────────────────

func _set_up_villagers() -> void:
	# Existing NPC nodes take their rewritten roles.
	_retarget_npc("NPCs/Guard", "Bran", Vector2(560, 840), _on_guard_interaction)
	_retarget_npc("NPCs/Farmer", "Tull", Vector2(300, 1100), _on_farmer_interaction)
	_retarget_npc("NPCs/Child", "Child", Vector2(1050, 950), _on_child_interaction)
	_retarget_npc("NPCs/Elara", "Elara", Vector2(700, 900), _on_elara_interaction)
	_relabel("NPCs/Apothecary", "Mara's")
	_bind_talk(get_node_or_null("NPCs/Apothecary"), _on_apothecary_interaction)
	_relabel("NPCs/AuctionTerminal", "Whispering Stone")
	_bind_talk(get_node_or_null("NPCs/AuctionTerminal"), _on_auction_interaction)
	_relabel("NPCs/CorruptedBoar", "North field")
	# New faces from the rewrite.
	_spawn_npc("Wenna", Vector2(345, 1100), Color(0.7, 0.8, 0.45), _on_wenna_interaction)
	_spawn_npc("Mother", Vector2(1100, 950), Color(0.85, 0.75, 0.6), _on_mother_interaction)
	_spawn_npc("Old Fen", Vector2(820, 760), Color(0.7, 0.68, 0.6), _on_old_fen_interaction)
	_spawn_npc("Jessa", Vector2(1150, 640), Color(0.75, 0.6, 0.8), _on_jessa_interaction)
	var chicken := ColorRect.new()
	chicken.name = "Pebbles"
	chicken.color = Color(0.95, 0.9, 0.8)
	chicken.size = Vector2(12, 10)
	chicken.position = Vector2(1000, 1000)
	add_child(chicken)

func _retarget_npc(path: String, label: String, pos: Vector2, handler: Callable) -> void:
	var npc := get_node_or_null(path) as Area2D
	if not npc:
		print("[OAKHAVEN] NPC node not found: %s" % path)
		return
	npc.position = pos
	npc.set_meta("display_name", label)
	_relabel(path, label)
	_bind_talk(npc, handler)

## Villagers talk when the player presses interact, never just because the
## player walked past (that used to start conversations by accident). The
## player's targeting (player_topdown.gd) calls the "interact_handler" meta.
## Walk-in triggers are kept only for story beats (boar, bridge) and pickups.
func _bind_talk(npc: Area2D, handler: Callable) -> void:
	if not npc:
		return
	npc.add_to_group("npc")
	npc.add_to_group("interactable")
	npc.set_meta("interact_handler", handler)
	if npc.body_entered.is_connected(handler):
		npc.body_entered.disconnect(handler)

func _relabel(path: String, text: String) -> void:
	var l := get_node_or_null(path + "/Label") as Label
	if l:
		l.text = text

func _spawn_npc(npc_name: String, pos: Vector2, color: Color, handler: Callable) -> Area2D:
	var npc := Area2D.new()
	npc.name = npc_name.replace(" ", "")
	npc.position = pos
	npc.add_to_group("npc")
	npc.set_meta("display_name", npc_name)
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 36.0
	shape.shape = circle
	npc.add_child(shape)
	var body := ColorRect.new()
	body.color = color
	body.size = Vector2(22, 30)
	body.position = Vector2(-11, -15)
	npc.add_child(body)
	var label := Label.new()
	label.text = npc_name
	label.position = Vector2(-30, -36)
	label.add_theme_font_size_override("font_size", 11)
	npc.add_child(label)
	if handler.is_valid():
		_bind_talk(npc, handler)
	get_node("NPCs").add_child(npc)
	return npc

func _flash_second_chicken() -> void:
	var twin := ColorRect.new()
	twin.color = Color(0.95, 0.9, 0.8)
	twin.size = Vector2(12, 10)
	twin.position = Vector2(1018, 1000)
	add_child(twin)
	var t := create_tween()
	t.tween_interval(0.25)
	t.tween_callback(twin.queue_free)

## Something is already playing: a conversation, the shop, the north-field
## sequence (which has gaps between its conversations), or a scene change.
func _busy() -> bool:
	return in_dialogue or in_shop or _field_running or _is_transitioning

func _can_talk(body: Node) -> bool:
	return body.name == "Player" and _entrance_done and not _busy()

## After each first-time conversation: is it time for the alarm?
func _afternoon_beat_done() -> void:
	_afternoon_beats += 1
	if _afternoon_beats >= ALARM_AFTER_BEATS and not _alarm_done and is_inside_tree():
		await get_tree().create_timer(1.5).timeout
		if is_inside_tree() and not _busy():
			await _run_north_field()

## First conversation: the scene (and a step toward the alarm). After that,
## a repeat line, so nobody goes silent while still showing "Talk".
func _talk(first: String, repeat: String) -> void:
	if await _run_once("oakhaven_village", first):
		await _afternoon_beat_done()
	else:
		await _run("oakhaven_village", repeat)

func _on_farmer_interaction(body) -> void:
	if _can_talk(body):
		await _talk("farmers", "farmers_repeat")

func _on_wenna_interaction(body) -> void:
	# Wenna is half of the farmers' argument: first time, it's that scene.
	if _can_talk(body):
		await _talk("farmers", "wenna_repeat")

func _on_old_fen_interaction(body) -> void:
	if _can_talk(body):
		await _talk("old_fen", "old_fen_repeat")

func _on_jessa_interaction(body) -> void:
	if _can_talk(body):
		await _talk("jessa", "jessa_repeat")

func _on_mother_interaction(body) -> void:
	if _can_talk(body):
		await _run("oakhaven_village", "mother_repeat")

func _on_child_interaction(body) -> void:
	if not _can_talk(body):
		return
	if await _run_once("oakhaven_village", "chicken"):
		await _afternoon_beat_done()
	elif await _run_once("oakhaven_village", "lost_sword"):
		_spawn_sword_pickup()
	elif not GameManager.has_flag("ch1_child_sword_found"):
		await _run("oakhaven_village", "lost_sword_waiting")
	elif not await _run_once("oakhaven_village", "lost_sword_found"):
		await _run("oakhaven_village", "child_repeat")

func _spawn_sword_pickup() -> void:
	if _sword_pickup:
		return
	_sword_pickup = Area2D.new()
	_sword_pickup.name = "WoodenSword"
	_sword_pickup.position = Vector2(1250, 1180)
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 24.0
	shape.shape = circle
	_sword_pickup.add_child(shape)
	var vis := ColorRect.new()
	vis.color = Color(0.6, 0.42, 0.22)
	vis.size = Vector2(6, 26)
	vis.position = Vector2(-3, -13)
	_sword_pickup.add_child(vis)
	_sword_pickup.body_entered.connect(_on_sword_picked)
	add_child(_sword_pickup)

func _on_sword_picked(body) -> void:
	if body.name != "Player" or in_dialogue or not _sword_pickup:
		return
	_sword_pickup.queue_free()
	_sword_pickup = null
	GameManager.set_story_flag("ch1_child_sword_found", true)
	await _run("oakhaven_village", "lost_sword_found_pickup")

func _on_elara_interaction(body) -> void:
	if _can_talk(body):
		await _run("oakhaven_village", "elara_repeat")

func _on_guard_interaction(body) -> void:
	if not _can_talk(body):
		return
	await _run("oakhaven_village", "bran_repeat_road" if _field_resolved else "bran_repeat_field")
	if not is_inside_tree(): return
	await _discover_guard_post_data_vision_secret()

func _on_apothecary_interaction(body) -> void:
	if not _can_talk(body):
		return
	GameManager.set_story_flag("ch1_apothecary_visited", true)
	if await _run_once("oakhaven_village", "mara"):
		await _afternoon_beat_done()
		if not is_inside_tree(): return
		await open_shop()
		if not is_inside_tree(): return
		await _grant_crafting_intro_materials()
		return
	if GameManager.has_flag("ch1_boar_nest_rebuilt") and await _run_once("north_field", "mara_boar"):
		return
	await _run("oakhaven_village", "mara_repeat")
	if not is_inside_tree(): return
	await open_shop()

func _on_auction_interaction(body) -> void:
	if not _can_talk(body):
		return
	if await _run_once("oakhaven_village", "whispering_stone"):
		await _afternoon_beat_done()
	else:
		await _run("oakhaven_village", "whispering_stone_repeat")

# ── C1-S04 to C1-S06: the north field ─────────────────────────────────────

func _on_boar_trigger(body) -> void:
	if body.name == "Player" and _entrance_done and not _busy() and not _field_resolved:
		await _run_north_field()

## The alarm, then (if Kaelen helps) the uphill water and the boar. Refusing
## doesn't end anything: the village closes the field itself, with injuries.
func _run_north_field() -> void:
	if _field_resolved or _field_running:
		return
	_field_running = true
	_alarm_done = true
	await _run("north_field", "alarm")
	if not is_inside_tree(): return
	if GameManager.has_flag("ch1_north_field_refused"):
		await _run("north_field", "field_refused_aftermath")
		_field_resolved = true
		_field_running = false
		return
	await _fade(1.0, 0.5)
	if not is_inside_tree(): return
	var player = get_node_or_null("Player")
	if player:
		player.global_position = NORTH_FIELD_POS + Vector2(0, -90)
	await _fade(0.0, 0.5)
	if not is_inside_tree(): return
	await _run("north_field", "field_water")
	if not is_inside_tree(): return
	await _run("north_field", "boar")
	if not is_inside_tree(): return
	if GameManager.has_flag("ch1_boar_fought"):
		await _run("north_field", "boar_fight_staged")
		if not is_inside_tree(): return
	# The field is closed and the boar dealt with, whichever way.
	GameManager.set_story_flag("ch1_corrupted_boar_defeated", true)
	GameManager.add_gold(100)
	GameManager.add_xp(50)
	_update_gold_display()
	_field_resolved = true
	_field_running = false

# ── C1-S07: the bridge, then on to the region (and Aldric) ────────────────

func _on_bridge_trigger(body) -> void:
	if body.name != "Player" or _busy() or _bridge_running or not _entrance_done:
		return
	_bridge_running = true
	if not _field_resolved:
		await _run_north_field()
		if not is_inside_tree(): return
	if not _bridge_done:
		_bridge_done = true
		await _run("north_field", "bridge")
		if not is_inside_tree(): return
		if GameManager.has_flag("ch1_bridge_repair_accepted"):
			# No WorldClock yet: fixing it takes the afternoon, on the spot.
			await _on_dlg_event("time_passes")
			GameManager.set_story_flag("ch1_bridge_saved", true)
			await _run("north_field", "bridge_saved")
			if not is_inside_tree(): return
	await transition_to_bridge()

# ── Shop, crafting intro, Data Vision secret (unchanged mechanics) ────────

func _create_map_boundaries() -> void:
	var map_size = Vector2(2500, 2000)
	_add_boundary(Vector2(0, -50), Vector2(map_size.x, 50))
	_add_boundary(Vector2(0, map_size.y), Vector2(map_size.x, 50))
	_add_boundary(Vector2(-50, 0), Vector2(50, map_size.y))
	_add_boundary(Vector2(map_size.x, 0), Vector2(50, map_size.y))

func _add_boundary(pos: Vector2, size: Vector2) -> void:
	var static_body = StaticBody2D.new()
	static_body.position = pos
	var collision_shape = CollisionShape2D.new()
	var rect_shape = RectangleShape2D.new()
	rect_shape.size = size
	collision_shape.shape = rect_shape
	collision_shape.position = size / 2.0
	static_body.add_child(collision_shape)
	add_child(static_body)

func _setup_elara_v2_visual() -> void:
	var elara_visual = get_node_or_null("NPCs/Elara/Sprite")
	if not elara_visual or not (elara_visual is ColorRect):
		return
	var elara_v2 = AssetManager.try_build_v2_npc("Elara", 64.0)
	if not elara_v2:
		return
	var parent = elara_visual.get_parent()
	var idx = elara_visual.get_index()
	parent.remove_child(elara_visual)
	elara_visual.queue_free()
	parent.add_child(elara_v2)
	parent.move_child(elara_v2, idx)

func _grant_crafting_intro_materials() -> void:
	if GameManager.has_flag("ch1_crafting_materials_intro_seen"):
		return
	GameManager.set_story_flag("ch1_crafting_materials_intro_seen", true)
	_sync_crafting_materials()
	var granted := false
	if has_node("/root/Inventory"):
		granted = Inventory.add_item("glitch_herb", 2)
	if has_node("/root/LoreJournal"):
		LoreJournal.discover("oakhaven_crafting_notes")
	await DialogueManager.say("System", "[CRAFTING MATERIAL FOUND]\nReceived: Glitch Herb x2\nOpen the pause menu's Crafting tab to brew a Health Potion.", Color(0.0, 1.0, 0.5), true)
	if not is_inside_tree(): return
	if not granted:
		await DialogueManager.say("System", "[CRAFTING NOTE RECORDED]\nMaterial handoff skipped because the inventory was unavailable.", Color(1.0, 0.8, 0.2), true)

func _discover_guard_post_data_vision_secret() -> void:
	if GameManager.has_flag("ch1_data_vision_secret_found"):
		return
	if not GameManager.has_flag("ch1_data_vision_unlocked"):
		return
	GameManager.set_story_flag("ch1_data_vision_secret_found", true)
	await _run("oakhaven_village", "guard_post_secret")
	if not is_inside_tree(): return
	_sync_crafting_materials()
	if has_node("/root/Inventory"):
		Inventory.add_item("memory_shard", 1)
	GameManager.add_xp(15)
	if has_node("/root/LoreJournal"):
		LoreJournal.discover("oakhaven_guard_post_trace")
	await DialogueManager.say("System", "[DATA VISION SECRET]\nRecovered: Memory Shard x1, +15 XP.", Color(0.3, 0.9, 1.0), true)

func _sync_crafting_materials() -> void:
	if has_node("/root/CraftingSystem"):
		CraftingSystem.get_recipes()

func open_shop() -> void:
	## Mara's stores, through the global ShopSystem
	in_shop = true
	if has_node("/root/ShopSystem"):
		ShopSystem.open_shop("apothecary")
		await ShopSystem.shop_closed
		if not is_inside_tree(): return
	else:
		var shop_text = "SHOP — Mara's:\n\n"
		for item in shop_items:
			shop_text += "• %s — %s (Cost: %d Gold)\n" % [item["name"], item["desc"], item["cost"]]
		shop_text += "\nYour Gold: %d" % GameManager.player_stats.get("gold", 0)
		await DialogueManager.say("Mara", shop_text)
		if not is_inside_tree(): return
		DialogueManager.hide_dialogue()
	in_shop = false

func transition_to_bridge() -> void:
	## On to the open Oakhaven region; Aldric waits at the Knight's Arena gate.
	if _is_transitioning:
		return
	_is_transitioning = true
	print("[CH1-SEQ4] Transitioning to Oakhaven Region (open-world)")

	DialogueManager.hide_dialogue()
	if fade_rect:
		var tween = create_tween()
		tween.tween_property(fade_rect, "modulate:a", 1.0, 1.0)
		await tween.finished
		if not is_inside_tree(): return

	GameManager.current_region = "oakhaven"
	GameManager.change_state(GameManager.GameState.EXPLORATION)
	SceneTransitions.change_scene("res://scenes/regions/oakhaven_region.tscn")

func _update_gold_display() -> void:
	if gold_label:
		gold_label.text = "Gold: %d" % GameManager.player_stats.get("gold", 0)

func _update_glitch_display() -> void:
	if glitch_meter_bar:
		glitch_meter_bar.value = GameManager.glitch_meter
	if glitch_label:
		glitch_label.text = "Glitch: %d%%" % int(GameManager.glitch_meter)

func _on_glitch_meter_changed(_value: float) -> void:
	_update_glitch_display()
