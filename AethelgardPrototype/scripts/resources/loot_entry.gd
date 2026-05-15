@tool
extends Resource
class_name LootEntry

## A single entry in a LootTable — one possible drop

@export var item_id: String = ""
@export_range(0.0, 100.0, 0.1) var drop_chance: float = 10.0  # Percent chance
@export var quantity_min: int = 1
@export var quantity_max: int = 1
@export var rarity_override: int = -1  # -1 = use item's native rarity
