@tool
extends Resource
class_name ItemResource

## =========================================================================
## ITEM RESOURCE — Data-driven item definition for Aethelgard
## =========================================================================
## Create .tres files in the editor, edit properties via Inspector.
## Drag-and-drop into LootTable, ShopSystem, or Inventory.
## =========================================================================

enum ItemType { CONSUMABLE, WEAPON, ARMOR, ACCESSORY, CHARM, MATERIAL, KEY_ITEM }
enum ItemRarity { COMMON, UNCOMMON, RARE, EPIC, LEGENDARY }

@export_group("Identity")
@export var item_id: String = ""
@export var item_name: String = ""
@export_multiline var description: String = ""
@export var icon: Texture2D
@export var type: ItemType = ItemType.CONSUMABLE
@export var rarity: ItemRarity = ItemRarity.COMMON

@export_group("Economy")
@export var buy_price: int = 10
@export var sell_price: int = 4
@export var max_stack: int = 99

@export_group("Stats (Weapon/Armor)")
@export var attack_bonus: float = 0.0
@export var defense_bonus: float = 0.0

@export_group("Consumable Effect")
@export var effect: String = ""       # "heal", "restore_mana", "reduce_glitch", "null_heal"
@export var effect_value: float = 0.0

@export_group("Charm")
@export var charm_id: String = ""     # Links to GameManager charm system

@export_group("Visual")
@export var drop_color: Color = Color.WHITE          # Glow color when dropped
@export var world_sprite: Texture2D                   # Sprite for world pickup entity

# ── Rarity colors for UI and drop glow ──
const RARITY_COLORS = {
	ItemRarity.COMMON: Color(0.8, 0.8, 0.8),
	ItemRarity.UNCOMMON: Color(0.3, 1.0, 0.3),
	ItemRarity.RARE: Color(0.3, 0.5, 1.0),
	ItemRarity.EPIC: Color(0.7, 0.3, 1.0),
	ItemRarity.LEGENDARY: Color(1.0, 0.85, 0.1),
}

const RARITY_NAMES = {
	ItemRarity.COMMON: "Common",
	ItemRarity.UNCOMMON: "Uncommon",
	ItemRarity.RARE: "Rare",
	ItemRarity.EPIC: "Epic",
	ItemRarity.LEGENDARY: "Legendary",
}

const TYPE_NAMES = {
	ItemType.CONSUMABLE: "Consumable",
	ItemType.WEAPON: "Weapon",
	ItemType.ARMOR: "Armor",
	ItemType.ACCESSORY: "Accessory",
	ItemType.CHARM: "Charm",
	ItemType.MATERIAL: "Material",
	ItemType.KEY_ITEM: "Key Item",
}

func get_rarity_color() -> Color:
	return RARITY_COLORS.get(rarity, Color.WHITE)

func get_rarity_name() -> String:
	return RARITY_NAMES.get(rarity, "Common")

func get_type_name() -> String:
	return TYPE_NAMES.get(type, "Item")

func get_display_name() -> String:
	return item_name if item_name != "" else item_id.replace("_", " ").capitalize()

## Convert to dictionary (for backward compatibility with existing Inventory/Shop)
func to_dict() -> Dictionary:
	var d = {
		"name": get_display_name(),
		"description": description,
		"type": get_type_name().to_lower(),
		"buy_price": buy_price,
		"sell_price": sell_price,
		"max_stack": max_stack,
	}
	if attack_bonus > 0:
		d["attack_bonus"] = attack_bonus
	if defense_bonus > 0:
		d["defense_bonus"] = defense_bonus
	if effect != "":
		d["effect"] = effect
		d["value"] = effect_value
	if charm_id != "":
		d["charm_id"] = charm_id
	return d

## Create an ItemResource from a legacy dictionary (ShopSystem/Inventory format)
static func from_dict(id: String, data: Dictionary) -> ItemResource:
	var res = ItemResource.new()
	res.item_id = id
	res.item_name = data.get("name", id.replace("_", " ").capitalize())
	res.description = data.get("description", "")
	res.buy_price = data.get("buy_price", 10)
	res.sell_price = data.get("sell_price", 4)
	res.max_stack = data.get("max_stack", 99)
	res.attack_bonus = data.get("attack_bonus", 0.0)
	res.defense_bonus = data.get("defense_bonus", 0.0)
	res.effect = data.get("effect", "")
	res.effect_value = data.get("value", 0.0)
	res.charm_id = data.get("charm_id", "")
	# Map type string to enum
	match data.get("type", "consumable"):
		"consumable": res.type = ItemType.CONSUMABLE
		"weapon": res.type = ItemType.WEAPON
		"armor": res.type = ItemType.ARMOR
		"accessory": res.type = ItemType.ACCESSORY
		"charm": res.type = ItemType.CHARM
		"material": res.type = ItemType.MATERIAL
		"key_item": res.type = ItemType.KEY_ITEM
	return res
