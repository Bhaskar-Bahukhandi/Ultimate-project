@tool
extends Resource
class_name LootTable

## =========================================================================
## LOOT TABLE — Randomized drop tables for enemies
## =========================================================================
## Attach to enemies via @export. Define weighted item drops.
## Supports guaranteed drops, conditional drops, and rarity scaling.
## =========================================================================

## A single entry in the loot table
@export var entries: Array[LootEntry] = []

## Guaranteed gold range (always drops)
@export var gold_min: int = 0
@export var gold_max: int = 10

## Guaranteed XP range (always drops)
@export var xp_min: int = 0
@export var xp_max: int = 20

## Maximum number of item drops per kill (0 = unlimited)
@export var max_drops: int = 3

## Roll the loot table and return an array of item drops
func roll() -> Array[Dictionary]:
	var drops: Array[Dictionary] = []
	
	# Roll for each entry independently
	for entry in entries:
		if drops.size() >= max_drops and max_drops > 0:
			break
		
		var _roll = randf() * 100.0
		if _roll <= entry.drop_chance:
			var qty = randi_range(entry.quantity_min, entry.quantity_max)
			if qty > 0:
				drops.append({
					"item_id": entry.item_id,
					"quantity": qty,
					"rarity": entry.rarity_override
				})
	
	return drops

## Roll gold reward
func roll_gold() -> int:
	return randi_range(gold_min, gold_max)

## Roll XP reward
func roll_xp() -> int:
	return randi_range(xp_min, xp_max)

## Get a single random item (simplified API for boss drops)
func get_random_item() -> Dictionary:
	var all_drops = roll()
	if all_drops.size() > 0:
		return all_drops[0]
	return {}
