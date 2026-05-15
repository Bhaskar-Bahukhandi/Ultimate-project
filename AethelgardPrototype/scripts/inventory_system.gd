extends Node
class_name InventorySystem

## Manages player inventory, items, and equipment

signal item_added(item_id: String, quantity: int)
signal item_removed(item_id: String, quantity: int)
signal item_used(item_id: String)
signal equipment_changed(slot: String, item_id: String)

# Item database
var ITEMS = {
	"health_potion": {
		"name": "Health Potion",
		"description": "Restores 50 HP",
		"type": "consumable",
		"effect": "heal",
		"value": 50.0,
		"buy_price": 10,
		"sell_price": 4,
		"max_stack": 99
	},
	"glitch_stabilizer": {
		"name": "Glitch Stabilizer",
		"description": "Reduces glitch meter by 20%",
		"type": "consumable",
		"effect": "reduce_glitch",
		"value": 20.0,
		"buy_price": 50,
		"sell_price": 20,
		"max_stack": 99
	},
	"iron_sword": {
		"name": "Iron Sword",
		"description": "A sturdy iron blade",
		"type": "weapon",
		"attack_bonus": 10.0,
		"buy_price": 120,
		"sell_price": 48,
		"max_stack": 1
	},
	"leather_armor": {
		"name": "Leather Armor",
		"description": "Basic protection",
		"type": "armor",
		"defense_bonus": 5.0,
		"buy_price": 80,
		"sell_price": 32,
		"max_stack": 1
	},
	"corrupted_knight_blade": {
		"name": "Corrupted Knight's Blade",
		"description": "A sentinel's sword crackling with unstable corruption energy. Its edge phases between solid and digital.",
		"type": "weapon",
		"attack_bonus": 8.0,
		"buy_price": 200,
		"sell_price": 80,
		"max_stack": 1
	},
	"data_wraith_phantom_cloak": {
		"name": "Phantom Cloak",
		"description": "Woven from purified process threads. Shimmers like heat haze, partially phasing in and out of existence.",
		"type": "armor",
		"defense_bonus": 8.0,
		"buy_price": 250,
		"sell_price": 100,
		"max_stack": 1
	},
	# ── Consumables synced from ShopSystem (PASS 37 FIX) ──
	"mana_potion": {
		"name": "Blue Potion",
		"description": "Restores 30 MP (RAM)",
		"type": "consumable",
		"effect": "restore_mana",
		"value": 30.0,
		"buy_price": 15,
		"sell_price": 6,
		"max_stack": 99
	},
	"null_potion": {
		"name": "Null Potion",
		"description": "Full heal. Blinds for 5s. Adds 3% corruption.",
		"type": "consumable",
		"effect": "null_heal",
		"value": 100.0,
		"buy_price": 500,
		"sell_price": 200,
		"max_stack": 99
	},
	"antidote": {
		"name": "System Patch",
		"description": "Reduces corruption by 10%. Cures status effects.",
		"type": "consumable",
		"effect": "reduce_glitch",
		"value": 10.0,
		"buy_price": 35,
		"sell_price": 14,
		"max_stack": 99
	},
	# ── Equipment synced from ShopSystem (PASS 37 FIX) ──
	"steel_blade": {
		"name": "Steel Blade",
		"description": "Tempered steel, keen edge. +18 ATK",
		"type": "weapon",
		"attack_bonus": 18.0,
		"buy_price": 350,
		"sell_price": 140,
		"max_stack": 1
	},
	"chain_mail": {
		"name": "Chain Mail",
		"description": "Linked steel rings. +12 DEF",
		"type": "armor",
		"defense_bonus": 12.0,
		"buy_price": 280,
		"sell_price": 112,
		"max_stack": 1
	},
	"spiked_shield": {
		"name": "Spiked Shield",
		"description": "Blocks and retaliates. +8 DEF, reflects 5 damage",
		"type": "armor",
		"defense_bonus": 8.0,
		"buy_price": 200,
		"sell_price": 80,
		"max_stack": 1
	},

	# ═══ TIER 3 — Mid-game Boss Drops ═══
	"automaton_core_blade": {
		"name": "Automaton Core Blade",
		"description": "Forged from the Clockwork Automaton's central gear. Attacks briefly overclock on crit. +25 ATK",
		"type": "weapon",
		"attack_bonus": 25.0,
		"buy_price": 0,
		"sell_price": 200,
		"max_stack": 1
	},
	"wraith_thread_armor": {
		"name": "Wraith-Thread Armor",
		"description": "Woven from Data Wraith remnants. Partially phases through corruption. +18 DEF",
		"type": "armor",
		"defense_bonus": 18.0,
		"buy_price": 0,
		"sell_price": 250,
		"max_stack": 1
	},

	# ═══ TIER 4 — Late-game Crafted / Rare Drops ═══
	"null_edge": {
		"name": "Null Edge",
		"description": "A blade that severs data streams. Deals bonus damage to corrupted enemies. +35 ATK",
		"type": "weapon",
		"attack_bonus": 35.0,
		"buy_price": 800,
		"sell_price": 320,
		"max_stack": 1
	},
	"memory_weave_mail": {
		"name": "Memory Weave Mail",
		"description": "Rebuilt from purified memory fragments. Absorbs corruption damage. +25 DEF",
		"type": "armor",
		"defense_bonus": 25.0,
		"buy_price": 700,
		"sell_price": 280,
		"max_stack": 1
	},
	"phase_spider_fang": {
		"name": "Phase Spider's Fang",
		"description": "A dagger that blinks through defenses. Ignores 30% armor. +22 ATK",
		"type": "weapon",
		"attack_bonus": 22.0,
		"buy_price": 0,
		"sell_price": 180,
		"max_stack": 1
	},
	"gear_sentry_plating": {
		"name": "Gear Sentry Plating",
		"description": "Salvaged turret armor. Heavy but impenetrable. +15 DEF",
		"type": "armor",
		"defense_bonus": 15.0,
		"buy_price": 0,
		"sell_price": 150,
		"max_stack": 1
	},
	"corruption_heart": {
		"name": "Corruption Heart",
		"description": "Pulsing core of a Corruption Elemental. Grants passive corruption resistance. +12 DEF, -5% corruption gain",
		"type": "accessory",
		"defense_bonus": 12.0,
		"attack_bonus": 0.0,
		"buy_price": 0,
		"sell_price": 200,
		"max_stack": 1
	},
	"mimic_spore_charm": {
		"name": "Mimic Spore Charm",
		"description": "Releases healing spores when HP drops below 30%. +5 ATK, +5 DEF",
		"type": "accessory",
		"attack_bonus": 5.0,
		"defense_bonus": 5.0,
		"buy_price": 0,
		"sell_price": 120,
		"max_stack": 1
	},

	# ═══ TIER 5 — Sovereign (Final Boss) Drops ═══
	"sovereign_protocol": {
		"name": "The Sovereign's Protocol",
		"description": "The weapon of a reality rewriter. Attacks destabilize enemy code. +50 ATK",
		"type": "weapon",
		"attack_bonus": 50.0,
		"buy_price": 0,
		"sell_price": 500,
		"max_stack": 1
	},
	"root_access_mantle": {
		"name": "Root Access Mantle",
		"description": "Cloak of absolute authority. Reduces all damage. +40 DEF",
		"type": "armor",
		"defense_bonus": 40.0,
		"buy_price": 0,
		"sell_price": 500,
		"max_stack": 1
	},
}

# Inventory storage
var items: Dictionary = {}  # {item_id: quantity}

# Equipment slots
var equipment: Dictionary = {
	"weapon": null,
	"armor": null,
	"accessory": null
}

# Currency
var gold: int = 0

func _ready() -> void:
	# Sync gold from GameManager
	if has_node("/root/GameManager"):
		gold = GameManager.player_stats.get("gold", 0)
	
	# Only add starting items if inventory is empty (first launch)
	if items.is_empty():
		add_item("health_potion", 3)
		add_item("glitch_stabilizer", 2)

func add_item(item_id: String, quantity: int = 1) -> bool:
	## Add item to inventory
	if not ITEMS.has(item_id):
		push_error("[INVENTORY] Unknown item: " + item_id)
		return false
	
	var item_data = ITEMS[item_id]
	var max_stack = item_data.get("max_stack", 99)
	
	if items.has(item_id):
		var new_quantity = items[item_id] + quantity
		if new_quantity > max_stack:
			var actual_added = max_stack - items[item_id]
			if actual_added <= 0:
				push_warning("[INVENTORY] Already at max stack for " + item_id)
				return false  # Don't consume gold for zero items
			push_warning("[INVENTORY] Reached max stack for " + item_id)
			items[item_id] = max_stack
			item_added.emit(item_id, actual_added)
		else:
			items[item_id] = new_quantity
			item_added.emit(item_id, quantity)
	else:
		var actual = min(quantity, max_stack)
		items[item_id] = actual
		item_added.emit(item_id, actual)
	
	if has_node("/root/SFXManager"):
		SFXManager.play("item_pickup")
	if OS.is_debug_build():
		print("[INVENTORY] Added %d x %s" % [quantity, item_data.name])
	return true

func remove_item(item_id: String, quantity: int = 1) -> bool:
	## Remove item from inventory
	if not items.has(item_id):
		return false
	
	if items[item_id] < quantity:
		return false
	
	items[item_id] -= quantity
	
	if items[item_id] <= 0:
		items.erase(item_id)
	
	item_removed.emit(item_id, quantity)
	return true

func use_item(item_id: String) -> bool:
	## Use a consumable item
	if not items.has(item_id):
		if OS.is_debug_build():
			print("[INVENTORY] Don't have item: " + item_id)
		return false
	
	var item_data = ITEMS[item_id]
	
	if item_data.type != "consumable":
		if OS.is_debug_build():
			print("[INVENTORY] Item is not consumable")
		return false
	
	# Apply item effect
	var success = _apply_item_effect(item_data)
	
	if success:
		remove_item(item_id, 1)
		item_used.emit(item_id)
		if has_node("/root/SFXManager"):
			SFXManager.play("potion_use")
		if OS.is_debug_build():
			print("[INVENTORY] Used " + item_data.name)
	
	return success

func _apply_item_effect(item_data: Dictionary) -> bool:
	## Apply the effect of a consumable item
	if not has_node("/root/GameManager"):
		push_error("[INVENTORY] GameManager not available")
		return false
	match item_data.effect:
		"heal":
			# Find player and heal
			var players = get_tree().get_nodes_in_group("player")
			if players.size() > 0:
				var player = players[0]
				if player.has_method("heal"):
					player.heal(item_data.value)
					return true
		
		"restore_mana":
			# Restore MP
			GameManager.player_stats["mp"] = min(
				GameManager.player_stats["mp"] + item_data.value,
				GameManager.player_stats["max_mp"]
			)
			if OS.is_debug_build():
				print("[INVENTORY] Restored %d MP (now %d/%d)" % [item_data.value, GameManager.player_stats["mp"], GameManager.player_stats["max_mp"]])
			return true
		
		"null_heal":
			# Heal HP + reduce corruption
			var players2 = get_tree().get_nodes_in_group("player")
			if players2.size() > 0:
				var player2 = players2[0]
				if player2.has_method("heal"):
					player2.heal(item_data.value)
			GameManager.add_glitch_corruption(-10.0)
			return true
		
		"reduce_glitch":
			GameManager.add_glitch_corruption(-item_data.value)
			return true
		
		_:
			push_warning("[INVENTORY] Unknown effect: " + str(item_data.effect))
			return false
	
	return false

func equip_item(item_id: String, slot: String) -> bool:
	## Equip an item to an equipment slot
	if not items.has(item_id):
		if OS.is_debug_build():
			print("[INVENTORY] Don't have item: " + item_id)
		return false
	
	var item_data = ITEMS[item_id]
	
	# Verify item type matches slot
	if item_data.type != slot:
		if OS.is_debug_build():
			print("[INVENTORY] Item type mismatch")
		return false
	
	# Unequip current item in slot
	if equipment[slot]:
		add_item(equipment[slot], 1)
	
	# Equip new item
	equipment[slot] = item_id
	remove_item(item_id, 1)
	
	equipment_changed.emit(slot, item_id)
	if has_node("/root/SFXManager"):
		SFXManager.play("item_equip")
	if OS.is_debug_build():
		print("[INVENTORY] Equipped " + item_data.name + " to " + slot)

	# Apply equipment bonuses
	_apply_equipment_bonuses()

	return true

func unequip_item(slot: String) -> bool:
	## Unequip an item from a slot
	if not equipment[slot]:
		return false

	var item_id = equipment[slot]
	equipment[slot] = null
	add_item(item_id, 1)

	equipment_changed.emit(slot, null)
	if has_node("/root/SFXManager"):
		SFXManager.play("item_equip")
	if OS.is_debug_build():
		print("[INVENTORY] Unequipped " + ITEMS[item_id].name + " from " + slot)
	
	_apply_equipment_bonuses()
	
	return true

func _apply_equipment_bonuses() -> void:
	## Calculate and apply total equipment bonuses to player stats.
	## Respects corruption penalty — applies on top of penalized base stats.
	if not has_node("/root/GameManager"):
		return
	var attack_bonus = 0.0
	var defense_bonus = 0.0
	
	for slot in equipment.keys():
		var item_id = equipment[slot]
		if item_id:
			var item_data = ITEMS[item_id]
			attack_bonus += item_data.get("attack_bonus", 0.0)
			defense_bonus += item_data.get("defense_bonus", 0.0)
	
	# Start from current (possibly corruption-penalized) base stats, then add bonuses
	var base_atk = GameManager.player_stats.get("base_attack", 15)
	var base_def = GameManager.player_stats.get("base_defense", 0)
	
	# Apply corruption penalty first, then add equipment bonuses on top
	var penalty = GameManager._corruption_stat_penalty if GameManager._corruption_stat_penalty > 0 else 0.0
	var penalized_atk = int(base_atk * (1.0 - penalty))
	var penalized_def = int(base_def * (1.0 - penalty))
	
	GameManager.player_stats["attack"] = int(penalized_atk + attack_bonus)
	GameManager.player_stats["defense"] = int(penalized_def + defense_bonus)
	
	if OS.is_debug_build():
		print("[INVENTORY] Equipment bonuses applied - ATK: +%d, DEF: +%d (corruption penalty: -%d%%)" % [attack_bonus, defense_bonus, int(penalty * 100)])

func has_item(item_id: String, quantity: int = 1) -> bool:
	## Check if player has item
	return items.get(item_id, 0) >= quantity

func get_item_count(item_id: String) -> int:
	## Get quantity of an item
	return items.get(item_id, 0)

func add_gold(amount: int) -> void:
	## Add currency — synced with GameManager.player_stats
	if amount < 0:
		push_warning("[INVENTORY] Attempted to add negative gold: %d" % amount)
		return
	gold += amount
	if has_node("/root/SFXManager"):
		SFXManager.play("gold_pickup")
	if has_node("/root/GameManager"):
		GameManager.player_stats["gold"] = gold
	if OS.is_debug_build():
		print("[INVENTORY] +%d gold (Total: %d)" % [amount, gold])

func remove_gold(amount: int) -> bool:
	## Remove currency if have enough
	if amount < 0:
		return false
	if gold >= amount:
		gold -= amount
		if has_node("/root/GameManager"):
			GameManager.player_stats["gold"] = gold
		if OS.is_debug_build():
			print("[INVENTORY] -%d gold (Total: %d)" % [amount, gold])
		return true
	return false

func get_inventory_summary() -> Array:
	## Get list of all items with details
	var summary = []
	for item_id in items.keys():
		var item_data = ITEMS[item_id].duplicate()
		item_data["id"] = item_id
		item_data["quantity"] = items[item_id]
		summary.append(item_data)
	return summary
