extends Node

## Minimal crafting MVP.
## Keeps crafting transactional and stores results through the existing Inventory save data.

signal craft_succeeded(recipe_id: String, output_id: String, quantity: int)
signal craft_failed(recipe_id: String, reason: String)

const MATERIAL_ITEMS: Dictionary = {
	"glitch_herb": {
		"name": "Glitch Herb",
		"description": "A flickering herb that stabilizes damaged code.",
		"type": "material",
		"buy_price": 0,
		"sell_price": 5,
		"max_stack": 99
	},
	"slime_core": {
		"name": "Slime Core",
		"description": "A soft unstable core left by corrupted slimes.",
		"type": "material",
		"buy_price": 0,
		"sell_price": 8,
		"max_stack": 99
	},
	"data_ore": {
		"name": "Data Ore",
		"description": "Raw code-bearing ore used for simple equipment repairs.",
		"type": "material",
		"buy_price": 0,
		"sell_price": 12,
		"max_stack": 99
	},
	"memory_shard": {
		"name": "Memory Shard",
		"description": "A small fragment of stable memory, useful for anti-corruption mixtures.",
		"type": "material",
		"buy_price": 0,
		"sell_price": 10,
		"max_stack": 99
	}
}

const RECIPES: Dictionary = {
	"brew_health_potion": {
		"name": "Brew Health Potion",
		"description": "Distill Glitch Herbs into a basic healing potion.",
		"ingredients": {"glitch_herb": 2},
		"output": {"item_id": "health_potion", "quantity": 1}
	},
	"brew_mana_potion": {
		"name": "Brew Mana Potion",
		"description": "Blend stabilizing herbs with a Slime Core to restore RAM.",
		"ingredients": {"glitch_herb": 1, "slime_core": 1},
		"output": {"item_id": "mana_potion", "quantity": 1}
	},
	"assemble_glitch_stabilizer": {
		"name": "Assemble Glitch Stabilizer",
		"description": "Bind a Slime Core to a Memory Shard for corruption control.",
		"ingredients": {"slime_core": 1, "memory_shard": 1},
		"output": {"item_id": "glitch_stabilizer", "quantity": 1}
	},
	"forge_iron_sword": {
		"name": "Forge Iron Sword",
		"description": "Compress Data Ore into a reliable starter blade.",
		"ingredients": {"data_ore": 2},
		"output": {"item_id": "iron_sword", "quantity": 1}
	},
	"distill_field_medicine": {
		"name": "Distill Field Medicine",
		"description": "Use late-game memory substrate to brew a compact healing pair.",
		"ingredients": {"glitch_herb": 3, "memory_shard": 1},
		"output": {"item_id": "health_potion", "quantity": 2}
	},
	"stabilize_focus_tonics": {
		"name": "Stabilize Focus Tonics",
		"description": "Refine herbs through Data Ore into two RAM-restoring tonics.",
		"ingredients": {"glitch_herb": 2, "data_ore": 1},
		"output": {"item_id": "mana_potion", "quantity": 2}
	},
	"assemble_trial_stabilizers": {
		"name": "Assemble Trial Stabilizers",
		"description": "Bind one of each late-game material into corruption control supplies.",
		"ingredients": {"glitch_herb": 1, "data_ore": 1, "memory_shard": 1},
		"output": {"item_id": "glitch_stabilizer", "quantity": 2}
	},
	"weave_memory_mail": {
		"name": "Weave Memory Mail",
		"description": "Shape stable memories and Data Ore into late-game protective armor.",
		"ingredients": {"memory_shard": 3, "data_ore": 2},
		"output": {"item_id": "memory_weave_mail", "quantity": 1}
	}
}


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_sync_material_items()


func get_recipes() -> Dictionary:
	_sync_material_items()
	return RECIPES.duplicate(true)


func get_recipe(recipe_id: String) -> Dictionary:
	_sync_material_items()
	if not RECIPES.has(recipe_id):
		return {}
	return RECIPES[recipe_id].duplicate(true)


func can_craft(recipe_id: String) -> bool:
	return get_craft_blocker(recipe_id) == ""


func craft(recipe_id: String) -> bool:
	_sync_material_items()
	var blocker := get_craft_blocker(recipe_id)
	if blocker != "":
		craft_failed.emit(recipe_id, blocker)
		return false

	var recipe: Dictionary = RECIPES[recipe_id]
	var ingredients: Dictionary = recipe["ingredients"]
	var output: Dictionary = recipe["output"]
	var output_id := str(output.get("item_id", ""))
	var output_quantity := int(output.get("quantity", 0))
	var consumed: Dictionary = {}

	for ingredient_id in ingredients.keys():
		var item_id := str(ingredient_id)
		var quantity := int(ingredients[ingredient_id])
		if not Inventory.remove_item(item_id, quantity):
			_refund_ingredients(consumed)
			craft_failed.emit(recipe_id, "consume_failed")
			return false
		consumed[item_id] = int(consumed.get(item_id, 0)) + quantity

	if not Inventory.add_item(output_id, output_quantity):
		_refund_ingredients(consumed)
		craft_failed.emit(recipe_id, "output_add_failed")
		return false

	craft_succeeded.emit(recipe_id, output_id, output_quantity)
	if OS.is_debug_build():
		print("[CRAFTING] Crafted %s x%d via %s" % [output_id, output_quantity, recipe_id])
	return true


func get_craft_blocker(recipe_id: String) -> String:
	_sync_material_items()
	if not has_node("/root/Inventory"):
		return "inventory_unavailable"
	if not RECIPES.has(recipe_id):
		return "invalid_recipe"

	var recipe: Dictionary = RECIPES[recipe_id]
	var ingredients = recipe.get("ingredients", {})
	var output = recipe.get("output", {})

	if not (ingredients is Dictionary) or ingredients.is_empty():
		return "invalid_ingredients"
	if not (output is Dictionary):
		return "invalid_output"

	var output_id := str(output.get("item_id", ""))
	var output_quantity := int(output.get("quantity", 0))
	if output_id == "" or output_quantity <= 0 or not Inventory.ITEMS.has(output_id):
		return "invalid_output"

	var output_data: Dictionary = Inventory.ITEMS[output_id]
	var max_stack := int(output_data.get("max_stack", 99))
	if Inventory.get_item_count(output_id) + output_quantity > max_stack:
		return "output_stack_full"

	for ingredient_id in ingredients.keys():
		var item_id := str(ingredient_id)
		var quantity := int(ingredients[ingredient_id])
		if quantity <= 0:
			return "invalid_ingredients"
		if not Inventory.ITEMS.has(item_id):
			return "missing_ingredient_definition"
		if not Inventory.has_item(item_id, quantity):
			return "missing_ingredients"

	return ""


func _sync_material_items() -> void:
	if not has_node("/root/Inventory"):
		return
	for item_id in MATERIAL_ITEMS.keys():
		if not Inventory.ITEMS.has(item_id):
			Inventory.ITEMS[item_id] = MATERIAL_ITEMS[item_id].duplicate(true)


func _refund_ingredients(consumed: Dictionary) -> void:
	if not has_node("/root/Inventory"):
		return
	for item_id in consumed.keys():
		Inventory.add_item(str(item_id), int(consumed[item_id]))
