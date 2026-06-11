extends Node2D

@onready var dialogue_box = get_node_or_null("UI/DialogueBox")
@onready var speaker_label = get_node_or_null("UI/DialogueBox/MarginContainer/VBoxContainer/SpeakerLabel")
@onready var dialogue_text = get_node_or_null("UI/DialogueBox/MarginContainer/VBoxContainer/DialogueText")
@onready var glitch_meter_bar = get_node_or_null("UI/HUD/TopBar/MarginContainer/HBoxContainer/RightInfo/GlitchMeter")
@onready var glitch_label = get_node_or_null("UI/HUD/TopBar/MarginContainer/HBoxContainer/RightInfo/GlitchMeter/GlitchLabel")
@onready var perfect_delete_button = get_node_or_null("UI/HUD/TopBar/MarginContainer/HBoxContainer/RightInfo/PerfectDeleteButton")

var current_dialogue = []
var dialogue_index = 0
var in_dialogue = false

var awakening_dialogue = [
	{"speaker": "System", "text": "Welcome, User. You have successfully crashed into Sector 1. Current Objective: Survive the Tutorial."},
	{"speaker": "Kaelen", "text": "Survive the tutorial? I wrote the tutorial."},
	{"speaker": "System", "text": "Correction. You wrote the old tutorial. This one has been... patched."},
	{"speaker": "Kaelen", "text": "Ugh... my head... Where am I?"},
	{"speaker": "Kaelen", "text": "This isn't the plane. This is... a field? Medieval buildings?"},
	{"speaker": "Kaelen", "text": "Wait. I can see more than that. The code. The variables. Everything."},
	{"speaker": "System", "text": "[SYSTEM INITIALIZATION COMPLETE]"},
	{"speaker": "System", "text": "[CLASS ASSIGNED: SYSTEMS ARCHITECT]"},
	{"speaker": "System", "text": "[WARNING: ROOT ACCESS PERMISSIONS DETECTED]"},
	{"speaker": "System", "text": "[RECOMMEND: CONCEAL TRUE ABILITIES]"},
	{"speaker": "Kaelen", "text": "What?! A game window?! This is... I can see the source code of this world."},
	{"speaker": "Kaelen", "text": "I need to figure out what's happening. But first... survival."}
]

var elara_dialogue = [
	{"speaker": "???", "text": "You! You're awake! I've been watching you since you fell from the sky."},
	{"speaker": "Kaelen", "text": "Who are you? Where am I?"},
	{"speaker": "Elara", "text": "My name is Elara. You're in Oakhaven — or what's left of it. This is Aethelgard."},
	{"speaker": "Kaelen", "text": "Aethelgard? That's a... that's a game world. How is this possible?"},
	{"speaker": "Elara", "text": "It's more than a game. It's real to me — I was born here. Well, spawned. The System created me in a glitched zone."},
	{"speaker": "Kaelen", "text": "You're... an NPC?"},
	{"speaker": "Elara", "text": "Don't call me that. I think. I feel. I KNOW things I shouldn't. The System calls me a 'Glitch Witch' — some kind of error it can't delete."},
	{"speaker": "Kaelen", "text": "I got 'Systems Architect'. This world... it's running on code I can see."},
	{"speaker": "Elara", "text": "If you can see the code, then you might be the one who can fix what's broken. But first, you should know..."},
	{"speaker": "Elara", "text": "There are corrupted creatures here. That slime over there — it wasn't always hostile. The corruption changed it."},
	{"speaker": "Kaelen", "text": "A slime? Corrupted assets manifesting as enemies?"},
	{"speaker": "Elara", "text": "Exactly. Be careful."},
	{"speaker": "System", "text": "[RELATIONSHIP: ELARA +5]"}
]

var slime_encounter_intro = [
	{"speaker": "System", "text": "[COMBAT INITIATED]"},
	{"speaker": "System", "text": "[TRANSITIONING TO BATTLE MODE]"},
	{"speaker": "Kaelen", "text": "Here goes nothing..."}
]

func _ready() -> void:
	# Enable input processing while paused (for dialogue)
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	if has_node("/root/GameManager"):
		GameManager.change_state(GameManager.GameState.EXPLORATION)
		if not GameManager.glitch_meter_changed.is_connected(_on_glitch_meter_changed):
			GameManager.glitch_meter_changed.connect(_on_glitch_meter_changed)
	
	# Setup collision boundaries
	_create_map_boundaries()
	
	# Setup real sprites if available
	setup_sprites()
	
	# Glitch overlay is now autoloaded - no need to create here
	
	# Hide Perfect Delete button in exploration (only for combat)
	if perfect_delete_button:
		perfect_delete_button.visible = false
	
	# Discover side quests available in Oakhaven
	if has_node("/root/SideQuestManager"):
		SideQuestManager.discover_quest("oakhaven_lost_memories")
		SideQuestManager.discover_quest("oakhaven_corrupted_cellar")
		SideQuestManager.discover_quest("oakhaven_herbalist_favor")
	
	# PASS-35 FIX: Create NPC interaction areas for quest givers
	_setup_quest_npc_interactions()
	
	# Show awakening dialogue
	await get_tree().create_timer(1.0).timeout
	if not is_inside_tree(): return
	await _play_dialogue_sequence(awakening_dialogue)


func _exit_tree() -> void:
	if has_node("/root/GameManager") and GameManager.glitch_meter_changed.is_connected(_on_glitch_meter_changed):
		GameManager.glitch_meter_changed.disconnect(_on_glitch_meter_changed)


func _create_map_boundaries() -> void:
	## Create invisible collision boundaries around the map
	var map_size = Vector2(2000, 1500)  # Adjust to your map size
	
	# Top wall
	_add_boundary(Vector2(0, -50), Vector2(map_size.x, 50))
	# Bottom wall
	_add_boundary(Vector2(0, map_size.y), Vector2(map_size.x, 50))
	# Left wall
	_add_boundary(Vector2(-50, 0), Vector2(50, map_size.y))
	# Right wall
	_add_boundary(Vector2(map_size.x, 0), Vector2(50, map_size.y))
	
	if OS.is_debug_build():
		print("[OAKHAVEN] Map boundaries created")

func _add_boundary(pos: Vector2, size: Vector2) -> void:
	## Helper to create a single boundary wall
	var static_body = StaticBody2D.new()
	static_body.position = pos
	
	var collision_shape = CollisionShape2D.new()
	var rect_shape = RectangleShape2D.new()
	rect_shape.size = size
	collision_shape.shape = rect_shape
	collision_shape.position = size / 2.0
	
	static_body.add_child(collision_shape)
	add_child(static_body)

func setup_sprites() -> void:
	## Replace placeholder ColorRects with real assets if available
	var player = get_node_or_null("Player")
	if player:
		AssetManager.replace_player_sprite(player, "exploration")
	
	# Setup NPC sprites
	var elara = get_node_or_null("NPCs/Elara/Sprite")
	if elara and elara is ColorRect:
		var elara_v2 = AssetManager.try_build_v2_npc("Elara", 64.0)
		if elara_v2:
			var elara_parent = elara.get_parent()
			var elara_idx = elara.get_index()
			elara_parent.remove_child(elara)
			elara.queue_free()
			elara_parent.add_child(elara_v2)
			elara_parent.move_child(elara_v2, elara_idx)
		elif AssetManager.is_asset_available("char_elara"):
			var elara_parent = elara.get_parent()
			var elara_idx = elara.get_index()
			var elara_sprite = Sprite2D.new()
			elara_sprite.name = "Sprite"
			elara_sprite.texture = AssetManager.get_sprite("char_elara")
			elara_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			var esz = elara_sprite.texture.get_size()
			if esz.y > 0:
				elara_sprite.scale = Vector2(64.0 / max(esz.x, esz.y), 64.0 / max(esz.x, esz.y))
			elara_parent.remove_child(elara)
			elara.queue_free()
			elara_parent.add_child(elara_sprite)
			elara_parent.move_child(elara_sprite, elara_idx)
		else:
			elara.color = Color(1, 0.8, 0.3)
	
	var slime = get_node_or_null("NPCs/TutorialSlime/Sprite")
	if slime and slime is ColorRect:
		if AssetManager.is_asset_available("slime_green"):
			var slime_parent = slime.get_parent()
			var slime_idx = slime.get_index()
			var slime_sprite = Sprite2D.new()
			slime_sprite.name = "Sprite"
			slime_sprite.texture = AssetManager.get_sprite("slime_green")
			slime_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			var ssz = slime_sprite.texture.get_size()
			if ssz.y > 0:
				slime_sprite.scale = Vector2(64.0 / max(ssz.x, ssz.y), 64.0 / max(ssz.x, ssz.y))
			slime_parent.remove_child(slime)
			slime.queue_free()
			slime_parent.add_child(slime_sprite)
			slime_parent.move_child(slime_sprite, slime_idx)
		else:
			slime.color = AssetManager.get_placeholder_color("slime_green")

## Helper to play a dialogue sequence through the global DialogueManager
func _play_dialogue_sequence(dialogue_array: Array) -> void:
	if not has_node("/root/DialogueManager"):
		# Fallback: print to console
		for line in dialogue_array:
			if OS.is_debug_build():
				print("[DIALOGUE] %s: %s" % [line["speaker"], line["text"]])
		return
	in_dialogue = true
	for line in dialogue_array:
		if not is_inside_tree():
			break
		var speaker = line.get("speaker", "")
		var text = line.get("text", "")
		var color = Color(1, 0.3, 0.3) if speaker == "System" else Color.WHITE
		if speaker == "Elara":
			AssetManager.play_v2_npc_anim(get_node_or_null("NPCs/Elara"), "talk")
		await DialogueManager.say(speaker, text, color)
		if speaker == "Elara":
			AssetManager.play_v2_npc_anim(get_node_or_null("NPCs/Elara"), "idle")
		if DialogueManager.is_skip_requested():
			break
	DialogueManager.hide_dialogue()
	in_dialogue = false

var elara_repeat_lines = [
	{"speaker": "Elara", "text": "Be careful out there. I sense the corruption growing stronger."},
	{"speaker": "Elara", "text": "If you find anything strange, let me know. My glitch senses are tingling."},
	{"speaker": "Elara", "text": "There's something deeper going on here. I can feel the System watching us."},
	{"speaker": "Elara", "text": "I've survived this long by being careful. You should do the same."},
]

func _on_elara_interaction(_source) -> void:
	if not GameManager.story_flags.get("elara_met", false):
		GameManager.set_story_flag("elara_met", true)
		GameManager.set_story_flag("ch1_elara_glitch_witch_met", true)
		GameManager.relationships["elara"] = 5
		await _play_dialogue_sequence(elara_dialogue)
		# PASS-35 FIX: Elara can hint about the Lost Memories quest
		if has_node("/root/SideQuestManager"):
			await _play_dialogue_sequence([{"speaker": "Elara", "text": "Oh — before you go, there's a flickering NPC near the village square. She seems stuck in a loop, murmuring about pieces of herself. You might be able to help her."}])
			SideQuestManager.start_quest("oakhaven_lost_memories")
	else:
		# Repeat interaction — random idle line
		var line = elara_repeat_lines[randi() % elara_repeat_lines.size()]
		await _play_dialogue_sequence([line])

func _on_slime_interaction(_source) -> void:
	await _play_dialogue_sequence(slime_encounter_intro)
	await get_tree().create_timer(0.3).timeout
	if not is_inside_tree(): return
	# Transition to combat
	if has_node("/root/SceneTransitions"):
		SceneTransitions.change_scene("res://scenes/combat/combat_arena.tscn", SceneTransitions.TransitionStyle.COMBAT_ENTRY)
	else:
		get_tree().change_scene_to_file("res://scenes/combat/combat_arena.tscn")

func _on_perfect_delete_pressed() -> void:
	# This button should only work in combat, not exploration
	if OS.is_debug_build():
		print("[WARNING] Perfect Delete only works in combat!")

func _on_glitch_meter_changed(value: float) -> void:
	if glitch_meter_bar:
		glitch_meter_bar.value = value
	if glitch_label:
		glitch_label.text = "Glitch: %d%%" % int(value)
	
	# Apply visual effects based on corruption
	if GameManager.corruption_level >= 1:
		modulate = Color(1, 0.95, 0.95)
	if GameManager.corruption_level >= 2:
		modulate = Color(1, 0.9, 0.9)
	if GameManager.corruption_level >= 3:
		modulate = Color(1, 0.8, 0.8)

func update_perfect_delete_button() -> void:
	# This is called from combat scenes only
	if perfect_delete_button:
		perfect_delete_button.visible = true
		perfect_delete_button.text = "PERFECT DELETE [X] (%d)" % GameManager.perfect_delete_charges

# ═══════════════════════════════════════════════════════════════════════
# PASS-35 FIX: NPC-driven quest interactions for Oakhaven
# ═══════════════════════════════════════════════════════════════════════

func _setup_quest_npc_interactions() -> void:
	## Create interactable quest-giving NPCs in Oakhaven
	# Flickering NPC — Lost Memories quest giver
	var flickering_npc = get_node_or_null("NPCs/FlickeringNPC")
	if flickering_npc:
		var area = flickering_npc.get_node_or_null("InteractionArea")
		if area and area is Area2D:
			if not area.body_entered.is_connected(_on_flickering_npc_interaction):
				area.body_entered.connect(_on_flickering_npc_interaction)
	
	# Blacksmith — Corrupted Cellar quest giver
	var blacksmith = get_node_or_null("NPCs/Blacksmith")
	if blacksmith:
		var area = blacksmith.get_node_or_null("InteractionArea")
		if area and area is Area2D:
			if not area.body_entered.is_connected(_on_blacksmith_interaction):
				area.body_entered.connect(_on_blacksmith_interaction)
	
	# Apothecary — Herbalist Favor quest giver
	var apothecary = get_node_or_null("NPCs/Apothecary")
	if apothecary:
		var area = apothecary.get_node_or_null("InteractionArea")
		if area and area is Area2D:
			if not area.body_entered.is_connected(_on_apothecary_interaction):
				area.body_entered.connect(_on_apothecary_interaction)

func _on_flickering_npc_interaction(_body) -> void:
	if not has_node("/root/SideQuestManager"):
		return
	if SideQuestManager.is_quest_complete("oakhaven_lost_memories"):
		return
	if not SideQuestManager.is_quest_active("oakhaven_lost_memories"):
		SideQuestManager.start_quest("oakhaven_lost_memories")
		await _play_dialogue_sequence([
			{"speaker": "???", "text": "P-pieces... my pieces... scattered... can you find them? Three memory fragments... near the well... behind the apothecary... in the basement..."},
			{"speaker": "System", "text": "[QUEST STARTED: Lost Memories]"}
		])

func _on_blacksmith_interaction(_body) -> void:
	if not has_node("/root/SideQuestManager"):
		return
	if SideQuestManager.is_quest_complete("oakhaven_corrupted_cellar"):
		return
	if not SideQuestManager.is_quest_active("oakhaven_corrupted_cellar"):
		SideQuestManager.start_quest("oakhaven_corrupted_cellar")
		await _play_dialogue_sequence([
			{"speaker": "Blacksmith", "text": "Careful where you step! There's something under my forge — sparks phase through the floor. Something's down there, and it ain't friendly."},
			{"speaker": "System", "text": "[QUEST STARTED: The Corrupted Cellar]"}
		])

func _on_apothecary_interaction(_body) -> void:
	if not has_node("/root/SideQuestManager"):
		return
	if SideQuestManager.is_quest_complete("oakhaven_herbalist_favor"):
		return
	if not SideQuestManager.is_quest_active("oakhaven_herbalist_favor"):
		SideQuestManager.start_quest("oakhaven_herbalist_favor")
		await _play_dialogue_sequence([
			{"speaker": "Apothecary", "text": "*sighs* My shelves are bare. Glitch Herbs only grow at the edges — forest rim, crater rim, and the corrupted grove. If you find three, I can brew something special."},
			{"speaker": "System", "text": "[QUEST STARTED: The Herbalist's Favor]"}
		])

