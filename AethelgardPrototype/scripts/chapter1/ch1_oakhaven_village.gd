extends Node2D

## Chapter 1: The Null Pointer Exception
## Sequence 4: Oakhaven Village — The Simulated Economy
## Top-down exploration with shops, NPC interactions, and Corrupted Boar elite encounter

@onready var shop_panel = get_node_or_null("UI/ShopPanel")
@onready var auction_panel = get_node_or_null("UI/AuctionPanel")
@onready var glitch_meter_bar = get_node_or_null("UI/HUD/TopBar/MarginContainer/HBoxContainer/RightInfo/GlitchMeter")
@onready var glitch_label = get_node_or_null("UI/HUD/TopBar/MarginContainer/HBoxContainer/RightInfo/GlitchLabel")
@onready var gold_label = get_node_or_null("UI/HUD/TopBar/MarginContainer/HBoxContainer/RightInfo/GoldLabel")
@onready var fade_rect = get_node_or_null("FadeRect")

var in_dialogue: bool = false
var in_shop: bool = false
var boar_triggered: bool = false
var _is_transitioning: bool = false
var _apothecary_dialogue_done: bool = false
var _auction_dialogue_done: bool = false

# Optional NPC interaction dialogues
var farmer_dialogue = [
	{"speaker": "Farmer Jenkins", "text": "Beautiful day for farming! The sun's been in the same position for... hm. How long has it been? I can't quite remember."},
	{"speaker": "Farmer Jenkins", "text": "I walk to the well. I draw water. I walk back. It's a good life. Simple. Some might say... *trails off, staring at the bucket* ...What was I saying?"},
	{"speaker": "Kaelen (Internal)", "text": "He almost broke through. For a moment, his eyes focused on something real \u2014 not his script, not his routine. Just the bucket in his hands and the question of why he's holding it."},
	{"speaker": "Kaelen (Internal)", "text": "Then the routine takes over again. Like watching someone dream of waking up and then fall back asleep. He doesn't know he's trapped. But somewhere, underneath the script, some part of him suspects."},
	{"speaker": "Farmer Jenkins", "text": "You're new here, aren't you? We don't get many visitors since the... the... *eyes flicker, voice drops to a whisper* ...I'm sorry. I don't know why I can't finish that sentence."},
]

var child_npc_dialogue = [
	{"speaker": "Village Child", "text": "Mister! Mister! Want to play tag? I've been 'it' for... *counts on fingers, runs out of fingers* ...a REALLY long time."},
	{"speaker": "Kaelen", "text": "Nobody else will play with you?"},
	{"speaker": "Village Child", "text": "The grown-ups just do the same things every day. Walk to the well. Walk back. Walk to the well. Walk back. Don't they get TIRED?"},
	{"speaker": "Kaelen (Internal)", "text": "She sees it. The loops, the repetition. The adults are locked in their patterns, but this kid... she's aware something is wrong. She just doesn't have the vocabulary to explain it."},
	{"speaker": "Village Child", "text": "You walk different from them. Like you're actually CHOOSING where to go. *tugs his sleeve* Can you teach me how to do that?"},
	{"speaker": "Kaelen", "text": "*voice catches* ...I'll try. I promise I'll try. Stay safe, kid."},
	{"speaker": "Kaelen (Internal)", "text": "She wants to learn how to choose. That hit harder than anything in this world has so far. Because I remember being her age, playing the same games, and never once wondering if the characters I controlled had a choice. I just assumed they didn't. I assumed wrong."},
]

var guard_npc_dialogue = [
	{"speaker": "Village Guard", "text": "Halt! Who goes— *squints, relaxes* Oh. You're not from around here. Carry on, traveler."},
	{"speaker": "Kaelen", "text": "Aren't you supposed to guard the village? I saw something dangerous near the outskirts."},
	{"speaker": "Village Guard", "text": "*grips spear tighter* I know. I can HEAR it. The crashing, the grunting. But when I try to walk toward it, I just... I end up back here. Every time. My feet won't carry me past this post."},
	{"speaker": "Kaelen (Internal)", "text": "He can't leave his patrol zone. He's not lazy — he's literally unable to deviate from his coded path. And he KNOWS it. That frustration in his voice is real."},
	{"speaker": "Village Guard", "text": "*quietly* I used to think I was a coward. But it's not fear. It's like... my body refuses. Like something bigger than me decided I belong right here, and nowhere else."},
	{"speaker": "Kaelen (Internal)", "text": "...That's the most self-aware thing I've heard from anyone in this village. He's suffering, and he can't even name what's doing it to him."},
]

# Village entrance cinematic dialogue
var village_entrance_dialogue = [
	{"speaker": "Kaelen (Internal)", "text": "Thatched roofs. Blooming flowers. A windmill turning in the breeze. Somewhere, a bird is singing the same three notes on repeat."},
	{"speaker": "Kaelen (Internal)", "text": "Everything about this place screams 'safe zone.' The light shifted from that sickly glitch-green to warm amber the moment I crossed the boundary. Like a filter someone designed to make you exhale."},
	{"speaker": "Kaelen (Internal)", "text": "But that sky has a visible seam where the horizon meets the mountains. And every few seconds, the buildings shimmer — ghostly outlines visible underneath the surface, like the village is a painting stretched over a skeleton. This place is beautiful, and it's barely holding together."},
	{"speaker": "Elara", "text": "Welcome to Oakhaven. *smiles softly* I know it's not much. But it's peaceful. The people here are kind — they just... keep to their routines."},
	{"speaker": "Kaelen", "text": "Routines? You mean they repeat the same actions?"},
	{"speaker": "Elara", "text": "Farmer Jenkins walks to the well, draws water, walks back. Over and over, since before I can remember. He seems content. But sometimes I wonder... *trails off*"},
	{"speaker": "Kaelen (Internal)", "text": "She was about to say something vulnerable. Something about whether contentment and being trapped in a loop are the same thing. I file that thought away."},
	{"speaker": "Elara", "text": "There's a healer's shop if you need supplies. And there's something strange in the village square — a stone terminal covered in glowing numbers. The villagers won't go near it."},
	{"speaker": "Elara", "text": "Also — stay alert near the outskirts. Things have been wandering in from the wild zones lately. Corrupted things. The village guard tries, but... *lowers voice* ...he can't seem to leave his post."},
	{"speaker": "Kaelen", "text": "So it's a safe zone that isn't actually safe. Just safe enough to let your guard down. Got it."},
]

# Solo village entrance (no Elara)
var village_entrance_solo_dialogue = [
	{"speaker": "Kaelen (Internal)", "text": "Thatched roofs. Blooming flowers. A windmill turning in the breeze. Somewhere, a bird is singing the same three notes on repeat."},
	{"speaker": "Kaelen (Internal)", "text": "Everything about this place screams 'safe zone.' The light shifted from that sickly glitch-green to warm amber the moment I crossed the boundary. Like a filter someone designed to make you exhale."},
	{"speaker": "Kaelen (Internal)", "text": "But that sky has a visible seam where the horizon meets the mountains. And every few seconds, the buildings shimmer — ghostly outlines visible underneath the surface. Beautiful, and barely holding together."},
	{"speaker": "Kaelen (Internal)", "text": "No guide. No companion. Just me and a village full of people trapped in their daily routines. The farmer walks to the well. The guard stands at his post. The shopkeeper sells potions he can't quite name."},
	{"speaker": "Kaelen (Internal)", "text": "Elara said the village was peaceful. She also said things have been wandering in from the wild zones. Corrupted things. I should stay alert — I don't have anyone watching my back."},
	{"speaker": "Kaelen", "text": "*to himself* Find supplies. Talk to the locals. Learn what I can. And keep moving before the System Administrator finds me."},
]

# Apothecary dialogue
var apothecary_dialogue = [
	{"speaker": "Shopkeeper", "text": "Welcome, Traveler! Would you like to buy a..."},
	{"speaker": "Shopkeeper", "text": "...buy a... buy a... *winces, grips counter edge* ...buy a—"},
	{"speaker": "Shopkeeper", "text": "—Potion! Yes! *exhales with relief* Potions. I have many potions. Some of them even work as advertised."},
	{"speaker": "Kaelen (Internal)", "text": "He got stuck. Like a thought hitting a wall and bouncing back to the beginning. I've seen people zone out before, but watching someone's MIND glitch like that — losing a thought mid-sentence and not even knowing it happened — that's something else entirely."},
	{"speaker": "Kaelen", "text": "Does that happen to you often? The... repeating?"},
	{"speaker": "Shopkeeper", "text": "*confused smile* Does what happen? I was just saying — potions! I have many potions. ...Did I already say that?"},
	{"speaker": "Kaelen (Internal)", "text": "He doesn't even know it happened. At least the farmer gets a flicker of recognition. This man loops and forgets the loop. I'm not sure which is worse."},
	{"speaker": "Elara", "text": "The red ones are reliable. Stay away from anything labeled 'Experimental' unless you enjoy surprises."},
]

# Auction House dialogue
var auction_dialogue = [
	{"speaker": "Kaelen (Internal)", "text": "A stone column in the village square. Covered in scrolling green numbers, shifting prices, supply chains updating in real time. It looks alien here — a piece of advanced infrastructure sitting in the middle of a medieval village."},
	{"speaker": "Kaelen (Internal)", "text": "It's a marketplace. Not a local one — this is connected to something bigger. Prices from regions I haven't even visited. Trade volumes that suggest thousands of active participants."},
	{"speaker": "Kaelen", "text": "This stone tracks supply and demand across the entire world? In real time? That's more sophisticated than anything we had on— *catches himself* ...where I'm from."},
	{"speaker": "Elara", "text": "The villagers call it the 'Whispering Stone.' They don't use it, but they know it watches. Sometimes it flags someone — a trader who gets too greedy. The System Administrator takes notice."},
	{"speaker": "Kaelen (Internal)", "text": "Surveillance built into the infrastructure. Someone is watching for anything unusual — price gouging, hoarding, anything that disrupts the natural flow. This world has a guardian, and it pays attention."},
	{"speaker": "Kaelen", "text": "And this System Administrator — what happens to the people it flags?"},
	{"speaker": "Elara", "text": "*goes quiet* ...Nobody knows. They just... stop trading. The villagers say the Stone 'corrects' them. Nobody asks what correction means."},
	{"speaker": "Kaelen (Internal)", "text": "'Correction.' That word hangs in the air like smoke. Where I come from, that's called enforcement. Here, it sounds more like punishment. Or erasure."},
]

# Corrupted Boar encounter dialogue
var boar_encounter_dialogue = [
	{"speaker": "Kaelen", "text": "Something just crashed through that fence! *steps back* Its body is flickering — eyes like static. That's not a normal animal."},
	{"speaker": "Kaelen (Internal)", "text": "Corrupted. The same kind of distortion I saw in the crater, but concentrated into a living thing. Something is poisoning the creatures out here — twisting them from the inside."},
	{"speaker": "Elara", "text": "Corrupted Boar! Stay back — it's not like the slime! This one charges in a straight line at full speed. If it hits you head-on, you won't get back up!"},
	{"speaker": "Elara", "text": "When you're above it, press DOWN to bounce off its back — that's its weak point! I'll try to box it in!"},
	{"speaker": "Kaelen", "text": "*steadies himself* Alright. Dodge the charge, hit the back. I can do this."},
]

# Post-boar dialogue
var post_boar_dialogue = [
	{"speaker": "Kaelen", "text": "*breathing hard* That corruption on it... it wasn't random. The patterns were structured. Deliberate."},
	{"speaker": "Kaelen (Internal)", "text": "Someone is spreading corruption into living creatures near this village. This isn't natural decay — it's deliberate. Something out there is doing this on purpose."},
	{"speaker": "Elara", "text": "Nice work. Your timing on those bounces was perfect — most people take a dozen tries before they get the rhythm."},
	{"speaker": "Elara", "text": "*frowning* But that corruption worries me. Animals don't just become corrupted on their own. Something is actively reaching into the wild zones and... changing things."},
	{"speaker": "Kaelen", "text": "And it's spreading inward. Toward the village. Those people in their loops — what happens to them when the corruption reaches them? Jenkins. The child. The guard who can't leave his post."},
	{"speaker": "Elara", "text": "*quietly* ...I try not to think about that. We need to keep moving. The bridge to the next region is ahead. But, Kaelen — there's usually something guarding it. A knight."},
	{"speaker": "Kaelen", "text": "A boss fight at the bridge. Why am I not surprised."},
	{"speaker": "Elara", "text": "*hesitates* It should be straightforward. It's designed to be. But with the corruption spreading... I'm not sure anything here works the way it's supposed to anymore."},
]

# Shop items for the Apothecary
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

	# Play exploration music for Oakhaven village
	if has_node("/root/MusicManager"):
		MusicManager.play_track("exploration")
	
	# Replace placeholder sprite with real player art
	var player = get_node_or_null("Player")
	if player:
		AssetManager.replace_player_sprite(player, "exploration")
	_setup_elara_v2_visual()
	
	# Give the player some starting gold (use add_gold to stay synced with Inventory)
	var current_gold = GameManager.player_stats.get("gold", 0)
	if current_gold < 100:
		GameManager.add_gold(100 - current_gold)
	
	_create_map_boundaries()
	
	if shop_panel:
		shop_panel.visible = false
	if auction_panel:
		auction_panel.visible = false
	
	# Fade in
	if fade_rect:
		fade_rect.modulate = Color(0, 0, 0, 1)
		var tween = create_tween()
		tween.tween_property(fade_rect, "modulate:a", 0.0, 1.5)
	
	# Update UI
	_update_gold_display()
	_update_glitch_display()
	
	# Connect NPC interaction signals (not wired in .tscn)
	_connect_npc_signals()
	
	# Start with village entrance dialogue using DialogueManager
	await get_tree().create_timer(1.5).timeout
	if not is_inside_tree(): return
	var has_elara = GameManager.story_flags.get("ch1_elara_trusted", false) or GameManager.story_flags.get("ch1_elara_cautious", false)
	if has_elara:
		await _play_dialogue_array(village_entrance_dialogue)
		if not is_inside_tree(): return
	else:
		await _play_dialogue_array(village_entrance_solo_dialogue)
		if not is_inside_tree(): return


func _exit_tree() -> void:
	if has_node("/root/GameManager") and GameManager.glitch_meter_changed.is_connected(_on_glitch_meter_changed):
		GameManager.glitch_meter_changed.disconnect(_on_glitch_meter_changed)

func _create_map_boundaries() -> void:
	var map_size = Vector2(2500, 2000)
	_add_boundary(Vector2(0, -50), Vector2(map_size.x, 50))
	_add_boundary(Vector2(0, map_size.y), Vector2(map_size.x, 50))
	_add_boundary(Vector2(-50, 0), Vector2(50, map_size.y))
	_add_boundary(Vector2(map_size.x, 0), Vector2(50, map_size.y))

func _connect_npc_signals() -> void:
	## Connect NPC Area2D body_entered signals to interaction handlers.
	var npc_map = {
		"NPCs/Farmer": "_on_farmer_interaction",
		"NPCs/Child": "_on_child_interaction",
		"NPCs/Guard": "_on_guard_interaction",
	}
	for path in npc_map:
		var node = get_node_or_null(path)
		if node and node is Area2D:
			# BUG-21-25: Validate method exists before creating Callable from string
			if not has_method(npc_map[path]):
				print("[OAKHAVEN] Missing handler method: %s" % npc_map[path])
				continue
			if not node.body_entered.is_connected(Callable(self, npc_map[path])):
				node.body_entered.connect(Callable(self, npc_map[path]))
		else:
			print("[OAKHAVEN] NPC node not found or not Area2D: %s" % path)

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

func _play_dialogue_array(dialogue_array: Array, post_callback: String = "") -> void:
	## Play a dialogue array using DialogueManager with typewriter and Space-to-continue.
	in_dialogue = true
	var prev_state = GameManager.current_state
	GameManager.change_state(GameManager.GameState.DIALOGUE)
	for line in dialogue_array:
		if DialogueManager.is_skip_requested():
			break
		var speaker = line.get("speaker", "")
		var text = line.get("text", "")
		if speaker == "Elara":
			AssetManager.play_v2_npc_anim(get_node_or_null("NPCs/Elara"), "talk")
		await DialogueManager.say(speaker, text)
		if speaker == "Elara":
			AssetManager.play_v2_npc_anim(get_node_or_null("NPCs/Elara"), "idle")
		if not is_inside_tree(): return
	DialogueManager.hide_dialogue()
	
	# Handle post-dialogue triggers
	if post_callback == "open_shop":
		await open_shop()
	elif post_callback == "start_boar_combat":
		await start_boar_combat()
	elif post_callback == "post_boar_rewards":
		GameManager.set_story_flag("ch1_corrupted_boar_defeated", true)
		GameManager.add_gold(100)
		GameManager.add_xp(50)
		_update_gold_display()
	in_dialogue = false
	GameManager.change_state(prev_state)

func _on_apothecary_interaction(body) -> void:
	if body.name == "Player" and not in_dialogue and not in_shop:
		GameManager.set_story_flag("ch1_apothecary_visited", true)
		if not _apothecary_dialogue_done:
			_apothecary_dialogue_done = true
			await _play_dialogue_array(apothecary_dialogue, "open_shop")
			if not is_inside_tree(): return
			await _grant_crafting_intro_materials()
			if not is_inside_tree(): return
		else:
			# Skip dialogue on repeat visit — go straight to shop
			open_shop()

func _on_auction_interaction(body) -> void:
	if body.name == "Player" and not in_dialogue and not _is_transitioning:
		GameManager.set_story_flag("ch1_auction_house_visited", true)
		if not _auction_dialogue_done:
			_auction_dialogue_done = true
			await _play_dialogue_array(auction_dialogue)
			if not is_inside_tree(): return
		else:
			# Skip full dialogue on repeat — just show a short line
			in_dialogue = true
			await DialogueManager.say("Shopkeeper", "The Whispering Stone hums. Prices shift in real time.")
			if not is_inside_tree(): return
			DialogueManager.hide_dialogue()
			in_dialogue = false

func _on_boar_trigger(body) -> void:
	if body.name == "Player" and not boar_triggered:
		boar_triggered = true
		await _play_dialogue_array(boar_encounter_dialogue, "start_boar_combat")
		if not is_inside_tree(): return

func _on_bridge_trigger(body) -> void:
	## Player tries to exit via bridge — departure choice then Tutorial Knight boss
	if body.name == "Player" and not _is_transitioning and not in_dialogue:
		await _play_departure_choice()
		if not is_inside_tree(): return

func _play_departure_choice() -> void:
	## Before leaving, player can choose to warn the villagers about corruption
	in_dialogue = true
	
	var has_elara = GameManager.story_flags.get("ch1_elara_trusted", false) or GameManager.story_flags.get("ch1_elara_cautious", false)
	
	if has_elara:
		await DialogueManager.say("Elara", "*glances back at the village* Before we cross that bridge — the people here. The corruption is closing in on them. We could warn them. Or we could keep moving and not draw more attention.")
		if not is_inside_tree(): return
	
	await DialogueManager.say("Kaelen (Internal)", "The corruption is spreading. The boar proved that. These people — Jenkins, the child, the guard — they're sitting in the path of something they can't see and can't fight. Do I owe them a warning? Or would that just paint a bigger target on this village?", Color(0.5, 0.9, 1.0))
	if not is_inside_tree(): return
	
	var choice = await DialogueManager.show_choices(
		"The bridge to the next region is ahead. Behind you, Oakhaven's lights glow warm and oblivious. The villagers don't know what's coming. Do you warn them, or keep your head down?",
		[
			"Warn the villagers — they deserve to know",
			"Leave quietly — drawing attention could make things worse"
		],
		"Kaelen (Internal)"
	)
	if not is_inside_tree(): return
	
	match choice:
		0:
			await _warn_villagers()
			if not is_inside_tree(): return
		1:
			await _leave_quietly()
			if not is_inside_tree(): return
		_:
			await _leave_quietly()
			if not is_inside_tree(): return
	
	DialogueManager.hide_dialogue()
	in_dialogue = false
	await transition_to_bridge()

func _warn_villagers() -> void:
	## Player warns the village about approaching corruption
	GameManager.set_story_flag("ch1_oakhaven_warned_villagers", true)
	
	await DialogueManager.say("Kaelen", "*raises his voice* Listen! All of you! The creatures in the wild zones — they're getting worse. Corruption is spreading inward, toward your village. The boar that attacked was just the beginning.")
	if not is_inside_tree(): return
	
	await DialogueManager.say("Village Guard", "*grips his spear, eyes wide* I KNEW it. I could hear the sounds getting closer every night. But how do we fight something we can't even walk toward?")
	if not is_inside_tree(): return
	
	await DialogueManager.say("Farmer Jenkins", "*stops mid-walk to the well* ...Fight? What's 'fight' mean in this context? I don't... I don't have that subroutine. But I heard your words, stranger. I'll remember them. Somehow.")
	if not is_inside_tree(): return
	
	await DialogueManager.say("Village Child", "*tugs Kaelen's sleeve* Are the bad things coming HERE? Will they make everyone do the loop thing even MORE? Will they make ME do it too?")
	if not is_inside_tree(): return
	
	await DialogueManager.say("Kaelen", "*kneels down* I'm going to find a way to fix this. I promise. Just... stay away from the outskirts. Stay together. Watch out for each other.")
	if not is_inside_tree(): return
	
	var has_elara = GameManager.story_flags.get("ch1_elara_trusted", false) or GameManager.story_flags.get("ch1_elara_cautious", false)
	if has_elara:
		await DialogueManager.say("Elara", "*quietly, to Kaelen* That was brave. And maybe foolish. But they needed to hear it. Even if they can't fully understand, the seed is planted now. Some part of them will remember.")
		if not is_inside_tree(): return
		GameManager.relationships["elara"] = GameManager.relationships.get("elara", 0) + 10
	
	await DialogueManager.say("System", "[ACTION: Warning delivered to Oakhaven NPCs]\n[NPC awareness: MARGINALLY INCREASED]\n[System Administrator attention: SLIGHTLY INCREASED]\n[The village remembers your name.]", Color(0.0, 1.0, 0.5), true)
	if not is_inside_tree(): return

func _leave_quietly() -> void:
	## Player leaves without warning anyone
	GameManager.set_story_flag("ch1_oakhaven_left_quietly", true)
	
	await DialogueManager.say("Kaelen (Internal)", "I can't fix everything. Warning them might make the System Administrator look more closely at this village, and that attention could be worse than the corruption itself. Sometimes the kindest thing is to stay quiet and keep moving.", Color(0.5, 0.9, 1.0))
	if not is_inside_tree(): return
	
	var has_elara = GameManager.story_flags.get("ch1_elara_trusted", false) or GameManager.story_flags.get("ch1_elara_cautious", false)
	if has_elara:
		await DialogueManager.say("Elara", "*nods slowly* I understand. Sometimes the help that draws attention is worse than the problem it tries to solve. Let's go.")
		if not is_inside_tree(): return
	
	await DialogueManager.say("Kaelen (Internal)", "The child's face. The farmer's confused smile. The guard who can't leave his post. I'm walking away from all of them. It's the smart move. I just wish it didn't feel like abandonment.", Color(0.5, 0.9, 1.0))
	if not is_inside_tree(): return

func _on_farmer_interaction(body) -> void:
	## Player talks to Farmer Jenkins
	if body.name == "Player" and not in_dialogue and not _is_transitioning:
		await _play_dialogue_array(farmer_dialogue)
		if not is_inside_tree(): return

func _on_child_interaction(body) -> void:
	## Player talks to the Village Child
	if body.name == "Player" and not in_dialogue and not _is_transitioning:
		await _play_dialogue_array(child_npc_dialogue)
		if not is_inside_tree(): return

func _on_guard_interaction(body) -> void:
	## Player talks to the Village Guard
	if body.name == "Player" and not in_dialogue and not _is_transitioning:
		await _play_dialogue_array(guard_npc_dialogue)
		if not is_inside_tree(): return
		await _discover_guard_post_data_vision_secret()
		if not is_inside_tree(): return

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
	_sync_crafting_materials()
	if has_node("/root/Inventory"):
		Inventory.add_item("memory_shard", 1)
	GameManager.add_xp(15)
	if has_node("/root/LoreJournal"):
		LoreJournal.discover("oakhaven_guard_post_trace")
	await DialogueManager.say("System", "[DATA VISION SECRET]\nA disabled evacuation-rights clause flickers under the guard post.\nRecovered: Memory Shard x1, +15 XP.", Color(0.3, 0.9, 1.0), true)

func _sync_crafting_materials() -> void:
	if has_node("/root/CraftingSystem"):
		CraftingSystem.get_recipes()

func open_shop() -> void:
	## Open the apothecary shop using global ShopSystem
	in_shop = true
	if has_node("/root/ShopSystem"):
		ShopSystem.open_shop("apothecary")
		await ShopSystem.shop_closed
		if not is_inside_tree(): return
	else:
		# Fallback — just show available items in dialogue
		var shop_text = "SHOP — Ye Olde Apothecary:\n\n"
		for item in shop_items:
			shop_text += "• %s — %s (Cost: %d Gold)\n" % [item["name"], item["desc"], item["cost"]]
		shop_text += "\nYour Gold: %d" % GameManager.player_stats.get("gold", 0)
		await DialogueManager.say("Shopkeeper", shop_text)
		if not is_inside_tree(): return
		DialogueManager.hide_dialogue()
	in_shop = false

func _populate_shop() -> void:
	## Populate shop panel with buyable items
	var item_list = shop_panel.get_node_or_null("MarginContainer/VBox/ItemList")
	if not item_list:
		return
	
	# Clear existing items
	for child in item_list.get_children():
		child.queue_free()
	
	for item in shop_items:
		var button = Button.new()
		button.text = "%s — %d Gold" % [item["name"], item["cost"]]
		button.custom_minimum_size = Vector2(0, 40)
		button.pressed.connect(_on_buy_item.bind(item))
		item_list.add_child(button)
	
	# Close button
	var close_btn = Button.new()
	close_btn.text = "Close Shop"
	close_btn.custom_minimum_size = Vector2(0, 40)
	close_btn.pressed.connect(_close_shop)
	item_list.add_child(close_btn)

func _on_buy_item(item: Dictionary) -> void:
	var gold = GameManager.player_stats.get("gold", 0)
	if gold >= item["cost"]:
		GameManager.add_gold(-item["cost"])
		_update_gold_display()
		
		# Apply effect
		match item["effect"]:
			"heal":
				GameManager.player_stats["hp"] = min(GameManager.player_stats["hp"] + item["value"], GameManager.player_stats["max_hp"])
			"restore_mana":
				GameManager.player_stats["mp"] = min(GameManager.player_stats["mp"] + item["value"], GameManager.player_stats["max_mp"])
			"null_heal":
				GameManager.player_stats["hp"] = GameManager.player_stats["max_hp"]
				# Blind effect placeholder
		
		print("[SHOP] Bought: %s for %d Gold" % [item["name"], item["cost"]])
	else:
		print("[SHOP] Not enough gold!")

func _close_shop() -> void:
	in_shop = false
	if shop_panel:
		shop_panel.visible = false

func start_boar_combat() -> void:
	## Trigger the Corrupted Boar elite combat — expanded animatic style
	# Simulate the boar fight with camera effects
	
	# Screen shake — boar charges!
	var camera = get_viewport().get_camera_2d()
	if camera:
		var shake_tween = create_tween()
		shake_tween.tween_property(camera, "offset", Vector2(8, -5), 0.04)
		shake_tween.tween_property(camera, "offset", Vector2(-8, 5), 0.04)
		shake_tween.tween_property(camera, "offset", Vector2(5, -3), 0.04)
		shake_tween.tween_property(camera, "offset", Vector2.ZERO, 0.05)
	
	await get_tree().create_timer(0.5).timeout
	if not is_inside_tree(): return
	
	# Phase 1: Boar charges — dodge prompt
	await DialogueManager.say("System", "[BOAR CHARGES! Velocity: MAX — Trajectory: LINEAR]\n[DODGE! Jump (SPACE) to avoid charge attack!]", Color.RED, true)
	if not is_inside_tree(): return
	
	# Kaelen dodges
	await DialogueManager.say("Kaelen", "It can't turn mid-charge! It only knows how to run in a straight line. If I time the jump right...")
	if not is_inside_tree(): return
	
	# Phase 2: Pogo prompt
	await DialogueManager.say("System", "[BOAR IS STUNNED from wall collision!]\n[POGO STRIKE! Press {move_down} while airborne to bounce off its back!]", Color(0.0, 1.0, 0.5), true)
	if not is_inside_tree(): return
	
	# Camera shake — pogo impact
	if camera:
		var impact_tween = create_tween()
		impact_tween.tween_property(camera, "offset", Vector2(0, -10), 0.03)
		impact_tween.tween_property(camera, "offset", Vector2(0, 5), 0.05)
		impact_tween.tween_property(camera, "offset", Vector2.ZERO, 0.08)
	
	await DialogueManager.say("System", "[CRITICAL HIT! POGO STRIKE — Damage: 60]\n[Boar HP: 150 → 90]", Color(1.0, 1.0, 0.0), true)
	if not is_inside_tree(): return
	
	# Phase 3: Boar enrages — charges again
	await DialogueManager.say("System", "[BOAR ENRAGED! Charge speed +50% — Glitch shader intensifying!]\n[DODGE INCOMING CHARGE!]", Color.RED, true)
	if not is_inside_tree(): return
	
	# Barrier / solo mechanic
	var has_elara_boar = GameManager.story_flags.get("ch1_elara_trusted", false) or GameManager.story_flags.get("ch1_elara_cautious", false)
	if has_elara_boar:
		await DialogueManager.say("Elara", "I'll wall it in! BARRIER — I'm sealing the exits!")
		if not is_inside_tree(): return
	else:
		await DialogueManager.say("Kaelen", "It hit the wall! The debris is blocking the exit — it's got nowhere to run now!")
		if not is_inside_tree(): return

	# Phase 4: Another pogo + defeat
	await DialogueManager.say("System", "[Boar trapped against the barrier!]\n[POGO STRIKE available! Press {move_down} while airborne!]", Color(0.0, 1.0, 0.5), true)
	if not is_inside_tree(): return
	
	# Final impact
	if camera:
		var final_tween = create_tween()
		final_tween.tween_property(camera, "offset", Vector2(0, -15), 0.03)
		final_tween.tween_property(camera, "offset", Vector2(0, 8), 0.05)
		final_tween.tween_property(camera, "offset", Vector2.ZERO, 0.1)
	
	await DialogueManager.say("System", "[CRITICAL HIT! POGO STRIKE — Damage: 90]\n[Boar HP: 90 → 0]\n[ELITE DEFEATED!]", Color(1.0, 1.0, 0.0), true)
	if not is_inside_tree(): return
	
	DialogueManager.hide_dialogue()
	
	# Show post-boar dialogue
	await get_tree().create_timer(0.5).timeout
	if not is_inside_tree(): return
	await _play_dialogue_array(post_boar_dialogue, "post_boar_rewards")
	if not is_inside_tree(): return

func transition_to_bridge() -> void:
	## Redirect to the explorable Oakhaven region instead of linear boss fight
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
