extends Node

## ==========================================================================
## SHOP SYSTEM — Enhanced global shop with BUY / SELL / Sort / Filter / Tooltips
## ==========================================================================
## Usage:
##   ShopSystem.open_shop("apothecary")   # Opens with apothecary inventory
##   ShopSystem.open_shop("blacksmith")    # Opens with blacksmith inventory
##   ShopSystem.open_shop("all")           # Opens with full catalog
## ==========================================================================

signal shop_opened(shop_type: String)
signal shop_closed
signal item_purchased(item_id: String, cost: int)
signal item_sold(item_id: String, revenue: int)

# Shop catalogs — each shop type has different items available
const SHOP_CATALOGS = {
	"apothecary": ["health_potion", "mana_potion", "glitch_stabilizer", "null_potion", "antidote"],
	"blacksmith": ["iron_sword", "steel_blade", "leather_armor", "chain_mail", "spiked_shield"],
	"charm_dealer": ["charm_extended_parry", "charm_soul_hoarder", "charm_corruption_resist", "charm_pogo_master", "charm_dash_master", "charm_thorns"],
	"general": ["health_potion", "mana_potion", "antidote", "iron_sword", "leather_armor"],
	"all": []  # Filled dynamically with everything
}

# Full item database with prices — extends the Inventory ITEMS
const SHOP_ITEMS = {
	# ── Consumables ──
	"health_potion": {
		"name": "Red Potion",
		"description": "Restores 50 HP (Integrity)",
		"type": "consumable",
		"buy_price": 30,
		"sell_price": 12,
		"effect": "heal",
		"value": 50.0
	},
	"mana_potion": {
		"name": "Blue Potion",
		"description": "Restores 30 MP (RAM)",
		"type": "consumable",
		"buy_price": 45,
		"sell_price": 18,
		"effect": "restore_mana",
		"value": 30.0
	},
	"glitch_stabilizer": {
		"name": "Glitch Stabilizer",
		"description": "Reduces corruption by 20%",
		"type": "consumable",
		"buy_price": 120,
		"sell_price": 48,
		"effect": "reduce_glitch",
		"value": 20.0
	},
	"null_potion": {
		"name": "Null Potion",
		"description": "Full heal. Blinds for 5s. Adds 3% corruption.",
		"type": "consumable",
		"buy_price": 800,
		"sell_price": 320,
		"effect": "null_heal",
		"value": 100.0
	},
	"antidote": {
		"name": "System Patch",
		"description": "Reduces corruption by 10%. Cures status effects.",
		"type": "consumable",
		"buy_price": 80,
		"sell_price": 32,
		"effect": "reduce_glitch",
		"value": 10.0
	},
	# ── Weapons ──
	"iron_sword": {
		"name": "Iron Sword",
		"description": "A sturdy iron blade. +10 ATK",
		"type": "weapon",
		"buy_price": 250,
		"sell_price": 100,
		"attack_bonus": 10.0
	},
	"steel_blade": {
		"name": "Steel Blade",
		"description": "Tempered steel, keen edge. +18 ATK",
		"type": "weapon",
		"buy_price": 700,
		"sell_price": 280,
		"attack_bonus": 18.0
	},
	# ── Armor ──
	"leather_armor": {
		"name": "Leather Armor",
		"description": "Basic protection. +5 DEF",
		"type": "armor",
		"buy_price": 180,
		"sell_price": 72,
		"defense_bonus": 5.0
	},
	"chain_mail": {
		"name": "Chain Mail",
		"description": "Linked steel rings. +12 DEF",
		"type": "armor",
		"buy_price": 550,
		"sell_price": 220,
		"defense_bonus": 12.0
	},
	"spiked_shield": {
		"name": "Spiked Shield",
		"description": "Blocks and retaliates. +8 DEF, reflects 5 damage",
		"type": "armor",
		"buy_price": 400,
		"sell_price": 160,
		"defense_bonus": 8.0
	},
	# ── Charms (Abilities) ──
	"charm_extended_parry": {
		"name": "Charm: Extended Parry",
		"description": "Parry window +40%. Easier timing.",
		"type": "charm",
		"buy_price": 800,
		"sell_price": 320,
		"charm_id": "extended_parry"
	},
	"charm_soul_hoarder": {
		"name": "Charm: Soul Hoarder",
		"description": "Gain +50% Soul. Spell and heal MP costs -20%.",
		"type": "charm",
		"buy_price": 1200,
		"sell_price": 480,
		"charm_id": "soul_hoarder"
	},
	"charm_corruption_resist": {
		"name": "Charm: Firewall",
		"description": "Corruption gain reduced by 40%.",
		"type": "charm",
		"buy_price": 1500,
		"sell_price": 600,
		"charm_id": "corruption_resist"
	},
	"charm_pogo_master": {
		"name": "Charm: Pogo Master",
		"description": "Pogo damage +80%. Pogo bounce height +30%.",
		"type": "charm",
		"buy_price": 600,
		"sell_price": 240,
		"charm_id": "pogo_master"
	},
	"charm_dash_master": {
		"name": "Charm: Shadow Dash",
		"description": "Dash cooldown -50%. Dash deals 10 damage.",
		"type": "charm",
		"buy_price": 1000,
		"sell_price": 400,
		"charm_id": "dash_master"
	},
	"charm_thorns": {
		"name": "Charm: Thorns of Pain",
		"description": "Deal 15 damage to attackers when hit.",
		"type": "charm",
		"buy_price": 700,
		"sell_price": 280,
		"charm_id": "thorns"
	},
	"charm_null_cloak": {
		"name": "Charm: Null Cloak",
		"description": "Halves random encounter rate. Perfect for exploration.",
		"type": "charm",
		"buy_price": 2000,
		"sell_price": 800,
		"charm_id": "null_cloak"
	},
}

## ─── SORT/FILTER ─────────────────────────────────────────────────────
enum SortMode { NONE, NAME_ASC, NAME_DESC, PRICE_ASC, PRICE_DESC, TYPE }
enum FilterMode { ALL, CONSUMABLE, WEAPON, ARMOR, CHARM }

var _sort_mode: SortMode = SortMode.NONE
var _filter_mode: FilterMode = FilterMode.ALL

## ─── BUY / SELL MODE ─────────────────────────────────────────────────
enum ShopMode { BUY, SELL }
var _shop_mode: ShopMode = ShopMode.BUY

# UI elements
var _ui_layer: CanvasLayer
var _panel: PanelContainer
var _item_container: VBoxContainer
var _gold_label: Label
var _title_label: Label
var _close_btn: Button
var _buy_tab: Button
var _sell_tab: Button
var _sort_btn: Button
var _filter_btn: Button
var _tooltip_panel: PanelContainer
var _tooltip_name: Label
var _tooltip_desc: RichTextLabel
var _is_open: bool = false
var _current_shop_type: String = ""

# ── Hover tracking ──
var _hovered_row: Control = null
var _hover_tween: Tween = null

func _ready() -> void:
	process_mode = PROCESS_MODE_ALWAYS
	_build_ui()
	_build_tooltip()
	_hide_shop()
	
	# Register shop items with Inventory if they don't exist
	_sync_items_to_inventory()

func _sync_items_to_inventory() -> void:
	## Ensure all shop items exist in the Inventory ITEMS database
	if not has_node("/root/Inventory"):
		return
	for item_id in SHOP_ITEMS.keys():
		if not Inventory.ITEMS.has(item_id):
			var shop_data = SHOP_ITEMS[item_id].duplicate()
			shop_data["max_stack"] = 99 if shop_data["type"] == "consumable" else 1
			Inventory.ITEMS[item_id] = shop_data

func _build_ui() -> void:
	## Build the shop UI programmatically
	_ui_layer = CanvasLayer.new()
	_ui_layer.layer = 98  # Below dialogue (100) but above game
	_ui_layer.name = "ShopUILayer"
	add_child(_ui_layer)
	
	# Background overlay (semi-transparent darken)
	var overlay = ColorRect.new()
	overlay.name = "ShopOverlay"
	overlay.color = Color(0, 0, 0, 0.6)
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	_ui_layer.add_child(overlay)
	
	# Main panel — centered, slightly wider for sell tab
	_panel = PanelContainer.new()
	_panel.name = "ShopPanel"
	_panel.set_anchors_preset(Control.PRESET_CENTER)
	_panel.custom_minimum_size = Vector2(580, 500)
	_panel.offset_left = -290
	_panel.offset_right = 290
	_panel.offset_top = -250
	_panel.offset_bottom = 250
	
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.04, 0.04, 0.10, 0.97)
	style.border_color = Color(0.8, 0.65, 0.1, 0.8)
	style.set_border_width_all(2)
	style.set_corner_radius_all(8)
	style.content_margin_left = 16
	style.content_margin_right = 16
	style.content_margin_top = 12
	style.content_margin_bottom = 12
	_panel.add_theme_stylebox_override("panel", style)
	_ui_layer.add_child(_panel)
	
	# Main VBox layout
	var main_vbox = VBoxContainer.new()
	main_vbox.add_theme_constant_override("separation", 6)
	_panel.add_child(main_vbox)
	
	# ── Header row: Title + Gold ──
	var header = HBoxContainer.new()
	header.add_theme_constant_override("separation", 12)
	main_vbox.add_child(header)
	
	_title_label = Label.new()
	_title_label.text = "SHOP"
	_title_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.2))
	_title_label.add_theme_font_size_override("font_size", 20)
	_title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(_title_label)
	
	_gold_label = Label.new()
	_gold_label.text = "Gold: 0"
	_gold_label.add_theme_color_override("font_color", Color(1.0, 0.9, 0.3))
	_gold_label.add_theme_font_size_override("font_size", 16)
	header.add_child(_gold_label)
	
	# ── Tab bar: BUY | SELL ──
	var tab_bar = HBoxContainer.new()
	tab_bar.add_theme_constant_override("separation", 4)
	main_vbox.add_child(tab_bar)
	
	_buy_tab = _create_tab_button("BUY", true)
	_buy_tab.pressed.connect(_switch_to_buy)
	tab_bar.add_child(_buy_tab)
	
	_sell_tab = _create_tab_button("SELL", false)
	_sell_tab.pressed.connect(_switch_to_sell)
	tab_bar.add_child(_sell_tab)
	
	# Spacer
	var spacer = Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tab_bar.add_child(spacer)
	
	# ── Sort button ──
	_sort_btn = Button.new()
	_sort_btn.text = "Sort: ---"
	_sort_btn.custom_minimum_size = Vector2(100, 28)
	_sort_btn.add_theme_font_size_override("font_size", 12)
	_sort_btn.add_theme_color_override("font_color", Color(0.7, 0.7, 0.8))
	var sort_style = StyleBoxFlat.new()
	sort_style.bg_color = Color(0.1, 0.1, 0.15, 0.8)
	sort_style.set_border_width_all(1)
	sort_style.border_color = Color(0.3, 0.3, 0.4, 0.5)
	sort_style.set_corner_radius_all(3)
	_sort_btn.add_theme_stylebox_override("normal", sort_style)
	_sort_btn.pressed.connect(_cycle_sort)
	tab_bar.add_child(_sort_btn)
	
	# ── Filter button ──
	_filter_btn = Button.new()
	_filter_btn.text = "Filter: All"
	_filter_btn.custom_minimum_size = Vector2(110, 28)
	_filter_btn.add_theme_font_size_override("font_size", 12)
	_filter_btn.add_theme_color_override("font_color", Color(0.7, 0.7, 0.8))
	var filter_style = sort_style.duplicate()
	_filter_btn.add_theme_stylebox_override("normal", filter_style)
	_filter_btn.pressed.connect(_cycle_filter)
	tab_bar.add_child(_filter_btn)
	
	# Separator
	var sep = HSeparator.new()
	sep.add_theme_constant_override("separation", 4)
	main_vbox.add_child(sep)
	
	# Scrollable item list
	var scroll = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.custom_minimum_size = Vector2(0, 320)
	main_vbox.add_child(scroll)
	
	_item_container = VBoxContainer.new()
	_item_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_item_container.add_theme_constant_override("separation", 4)
	scroll.add_child(_item_container)
	
	# Close button
	_close_btn = Button.new()
	_close_btn.text = "Close Shop [ESC]"
	_close_btn.custom_minimum_size = Vector2(0, 40)
	_close_btn.pressed.connect(close_shop)
	
	var btn_style = StyleBoxFlat.new()
	btn_style.bg_color = Color(0.15, 0.08, 0.08, 0.9)
	btn_style.border_color = Color(0.6, 0.3, 0.3, 0.6)
	btn_style.set_border_width_all(1)
	btn_style.set_corner_radius_all(4)
	btn_style.content_margin_top = 8
	btn_style.content_margin_bottom = 8
	_close_btn.add_theme_stylebox_override("normal", btn_style)
	_close_btn.add_theme_color_override("font_color", Color(0.9, 0.6, 0.6))
	_close_btn.add_theme_font_size_override("font_size", 14)
	main_vbox.add_child(_close_btn)

func _build_tooltip() -> void:
	## Create the hoverable tooltip panel.
	_tooltip_panel = PanelContainer.new()
	_tooltip_panel.name = "Tooltip"
	_tooltip_panel.visible = false
	_tooltip_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_tooltip_panel.custom_minimum_size = Vector2(240, 60)
	_tooltip_panel.z_index = 10
	
	var tip_style = StyleBoxFlat.new()
	tip_style.bg_color = Color(0.06, 0.06, 0.14, 0.96)
	tip_style.border_color = Color(0.6, 0.5, 0.2, 0.7)
	tip_style.set_border_width_all(1)
	tip_style.set_corner_radius_all(4)
	tip_style.content_margin_left = 10
	tip_style.content_margin_right = 10
	tip_style.content_margin_top = 8
	tip_style.content_margin_bottom = 8
	_tooltip_panel.add_theme_stylebox_override("panel", tip_style)
	
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 4)
	_tooltip_panel.add_child(vbox)
	
	_tooltip_name = Label.new()
	_tooltip_name.add_theme_font_size_override("font_size", 14)
	_tooltip_name.add_theme_color_override("font_color", Color(1.0, 0.9, 0.5))
	vbox.add_child(_tooltip_name)
	
	_tooltip_desc = RichTextLabel.new()
	_tooltip_desc.fit_content = true
	_tooltip_desc.bbcode_enabled = true
	_tooltip_desc.scroll_active = false
	_tooltip_desc.custom_minimum_size = Vector2(220, 0)
	_tooltip_desc.add_theme_font_size_override("normal_font_size", 12)
	_tooltip_desc.add_theme_color_override("default_color", Color(0.7, 0.7, 0.8))
	vbox.add_child(_tooltip_desc)
	
	_ui_layer.add_child(_tooltip_panel)

func _create_tab_button(text: String, active: bool) -> Button:
	## Create a BUY/SELL tab button.
	var btn = Button.new()
	btn.text = text
	btn.custom_minimum_size = Vector2(80, 30)
	btn.add_theme_font_size_override("font_size", 14)
	_style_tab(btn, active)
	return btn

func _style_tab(btn: Button, active: bool) -> void:
	## Apply active/inactive styling to a tab button.
	var s = StyleBoxFlat.new()
	if active:
		s.bg_color = Color(0.15, 0.12, 0.05, 0.95)
		s.border_color = Color(0.8, 0.65, 0.1, 0.8)
		btn.add_theme_color_override("font_color", Color(1.0, 0.85, 0.2))
	else:
		s.bg_color = Color(0.08, 0.08, 0.12, 0.7)
		s.border_color = Color(0.3, 0.3, 0.4, 0.4)
		btn.add_theme_color_override("font_color", Color(0.5, 0.5, 0.6))
	s.set_border_width_all(1)
	s.set_corner_radius_all(4)
	s.content_margin_left = 10
	s.content_margin_right = 10
	btn.add_theme_stylebox_override("normal", s)

## ─── TAB SWITCHING ───────────────────────────────────────────────────

func _switch_to_buy() -> void:
	_shop_mode = ShopMode.BUY
	_style_tab(_buy_tab, true)
	_style_tab(_sell_tab, false)
	_refresh_items()

func _switch_to_sell() -> void:
	_shop_mode = ShopMode.SELL
	_style_tab(_buy_tab, false)
	_style_tab(_sell_tab, true)
	_refresh_items()

## ─── SORT / FILTER CYCLING ──────────────────────────────────────────

func _cycle_sort() -> void:
	_sort_mode = (_sort_mode + 1) % SortMode.size() as SortMode
	match _sort_mode:
		SortMode.NONE: _sort_btn.text = "Sort: ---"
		SortMode.NAME_ASC: _sort_btn.text = "Sort: A-Z"
		SortMode.NAME_DESC: _sort_btn.text = "Sort: Z-A"
		SortMode.PRICE_ASC: _sort_btn.text = "Sort: $↑"
		SortMode.PRICE_DESC: _sort_btn.text = "Sort: $↓"
		SortMode.TYPE: _sort_btn.text = "Sort: Type"
	_refresh_items()

func _cycle_filter() -> void:
	_filter_mode = (_filter_mode + 1) % FilterMode.size() as FilterMode
	match _filter_mode:
		FilterMode.ALL: _filter_btn.text = "Filter: All"
		FilterMode.CONSUMABLE: _filter_btn.text = "Filter: Potions"
		FilterMode.WEAPON: _filter_btn.text = "Filter: Weapons"
		FilterMode.ARMOR: _filter_btn.text = "Filter: Armor"
		FilterMode.CHARM: _filter_btn.text = "Filter: Charms"
	_refresh_items()

func _refresh_items() -> void:
	## Refresh the item list based on current mode/sort/filter.
	if _shop_mode == ShopMode.BUY:
		_populate_items(_current_shop_type)
	else:
		_populate_sell_items()

## ─── OPEN / CLOSE ────────────────────────────────────────────────────

func open_shop(shop_type: String = "apothecary") -> void:
	## Open the shop with a specific inventory type.
	if _is_open:
		return

	# Block during cutscenes
	if has_node("/root/CutsceneManager"):
		var cm = get_node("/root/CutsceneManager")
		if cm.is_playing if cm.has_method("is_playing") else cm.get("is_playing"):
			if OS.is_debug_build():
				print("[SHOP] Blocked — cutscene is playing")
			return

	# Integrate with UIStack to prevent overlap with pause/status/dialogue
	if has_node("/root/UIStack") and not UIStack.try_open("shop"):
		if OS.is_debug_build():
			print("[SHOP] Blocked by UIStack — another modal is open")
		return

	_is_open = true
	_current_shop_type = shop_type
	_shop_mode = ShopMode.BUY
	_sort_mode = SortMode.NONE
	_filter_mode = FilterMode.ALL
	_sort_btn.text = "Sort: ---"
	_filter_btn.text = "Filter: All"
	_style_tab(_buy_tab, true)
	_style_tab(_sell_tab, false)
	
	# Pause game while shopping
	get_tree().paused = true
	
	# Set title
	match shop_type:
		"apothecary":
			_title_label.text = "YE OLDE APOTHECARY"
		"blacksmith":
			_title_label.text = "BLACKSMITH TORVAL"
		"charm_dealer":
			_title_label.text = "CHARM DEALER — NYX"
		"general":
			_title_label.text = "GENERAL STORE"
		_:
			_title_label.text = "SHOP"
	
	_update_gold_display()
	_populate_items(shop_type)
	
	# Show with animation
	_ui_layer.visible = true
	_panel.modulate.a = 0.0
	_panel.scale = Vector2(0.9, 0.9)
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(_panel, "modulate:a", 1.0, 0.2)
	tween.tween_property(_panel, "scale", Vector2(1.0, 1.0), 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	
	shop_opened.emit(shop_type)
	if has_node("/root/SFXManager"):
		SFXManager.play("ui_open")
	if has_node("/root/Achievements"):
		Achievements.try_unlock("first_shop")

	# Focus first buy button for keyboard/gamepad navigation
	await get_tree().process_frame
	_grab_first_item_focus()

func close_shop() -> void:
	## Close the shop UI.
	if not _is_open:
		return
	_is_open = false
	_hide_tooltip()
	# Kill hover tween to avoid accessing freed rows
	if _hover_tween and _hover_tween.is_running():
		_hover_tween.kill()
	if has_node("/root/SFXManager"):
		SFXManager.play("ui_close")

	# Release UIStack modal slot
	if has_node("/root/UIStack"):
		UIStack.close("shop")

	# Only unpause if no other UI modal is active
	if has_node("/root/PauseScreen") and PauseScreen.is_paused:
		pass  # PauseScreen owns the pause state
	else:
		get_tree().paused = false
	
	var tween = create_tween()
	tween.tween_property(_panel, "modulate:a", 0.0, 0.15)
	tween.tween_callback(_hide_shop)
	
	shop_closed.emit()

func _grab_first_item_focus() -> void:
	## Focus the first buy/sell button for keyboard/gamepad navigation.
	if not _item_container:
		return
	for child in _item_container.get_children():
		# Look for PanelContainer rows containing HBoxContainers with Buttons
		if child is PanelContainer:
			for sub in child.get_children():
				if sub is HBoxContainer:
					for btn in sub.get_children():
						if btn is Button and not btn.disabled:
							btn.grab_focus()
							return

func _hide_shop() -> void:
	_ui_layer.visible = false

func _update_gold_display() -> void:
	if _gold_label:
		var gold = GameManager.player_stats.get("gold", 0)
		_gold_label.text = "Gold: %d" % gold

## ─── BUY MODE: POPULATE ─────────────────────────────────────────────

func _populate_items(shop_type: String) -> void:
	## Build the item list for BUY mode.
	for child in _item_container.get_children():
		child.queue_free()
	
	var item_ids: Array
	if shop_type == "all":
		item_ids = SHOP_ITEMS.keys()
	else:
		item_ids = SHOP_CATALOGS.get(shop_type, [])
	
	# Apply filter
	var filtered = _apply_filter_to_ids(item_ids)
	
	# Apply sort
	filtered = _apply_sort(filtered, true)
	
	if filtered.is_empty():
		_add_empty_label("No items match the current filter.")
		return
	
	for item_id in filtered:
		if not SHOP_ITEMS.has(item_id):
			continue
		var item = SHOP_ITEMS[item_id]
		
		# Check if player already owns this charm
		if item["type"] == "charm":
			var charm_id = item.get("charm_id", "")
			if charm_id != "" and GameManager.is_charm_unlocked(charm_id):
				_add_owned_label(item)
				continue
		
		_add_buy_row(item_id, item)

## ─── SELL MODE: POPULATE ─────────────────────────────────────────────

func _populate_sell_items() -> void:
	## Build the item list for SELL mode — shows player's inventory.
	for child in _item_container.get_children():
		child.queue_free()
	
	if not has_node("/root/Inventory"):
		_add_empty_label("Inventory unavailable.")
		return
	
	var sellable_ids: Array = []
	for item_id in Inventory.items.keys():
		if Inventory.items[item_id] <= 0:
			continue
		# Can't sell equipped items
		if _is_equipped(item_id):
			continue
		# Can't sell key items
		var data = _get_combined_item_data(item_id)
		if data.get("type", "") == "key_item":
			continue
		sellable_ids.append(item_id)
	
	# Apply filter
	sellable_ids = _apply_filter_to_ids(sellable_ids)
	
	# Apply sort (use sell_price for price sorting)
	sellable_ids = _apply_sort(sellable_ids, false)
	
	if sellable_ids.is_empty():
		_add_empty_label("Nothing to sell.")
		return
	
	for item_id in sellable_ids:
		var data = _get_combined_item_data(item_id)
		var qty = Inventory.items.get(item_id, 0)
		_add_sell_row(item_id, data, qty)

## ─── BUY ROW ─────────────────────────────────────────────────────────

func _add_buy_row(item_id: String, item: Dictionary) -> void:
	## Create a single shop item row with hover + tooltip.
	var row = PanelContainer.new()
	row.name = "BuyRow_%s" % item_id
	row.custom_minimum_size = Vector2(0, 48)
	
	var row_style = StyleBoxFlat.new()
	row_style.bg_color = Color(0.06, 0.06, 0.10, 0.6)
	row_style.set_corner_radius_all(3)
	row_style.content_margin_left = 8
	row_style.content_margin_right = 8
	row_style.content_margin_top = 4
	row_style.content_margin_bottom = 4
	row.add_theme_stylebox_override("panel", row_style)
	_item_container.add_child(row)
	
	# Hover signals
	row.mouse_entered.connect(_on_row_hover_enter.bind(row, item_id, item))
	row.mouse_exited.connect(_on_row_hover_exit.bind(row))
	
	var hbox = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 8)
	row.add_child(hbox)
	
	# Item info
	var info_vbox = VBoxContainer.new()
	info_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(info_vbox)
	
	var name_label = Label.new()
	name_label.text = item["name"]
	name_label.add_theme_font_size_override("font_size", 14)
	
	# Color-code by type
	match item["type"]:
		"consumable":
			name_label.add_theme_color_override("font_color", Color(0.7, 1.0, 0.7))
		"weapon":
			name_label.add_theme_color_override("font_color", Color(1.0, 0.6, 0.3))
		"armor":
			name_label.add_theme_color_override("font_color", Color(0.5, 0.7, 1.0))
		"charm":
			name_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.2))
	info_vbox.add_child(name_label)
	
	var desc_label = Label.new()
	desc_label.text = item["description"]
	desc_label.add_theme_font_size_override("font_size", 12)
	desc_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.7))
	info_vbox.add_child(desc_label)
	
	# Owned count
	var owned_qty = Inventory.items.get(item_id, 0) if has_node("/root/Inventory") else 0
	if owned_qty > 0:
		var owned_lbl = Label.new()
		owned_lbl.text = "Owned: %d" % owned_qty
		owned_lbl.add_theme_font_size_override("font_size", 12)
		owned_lbl.add_theme_color_override("font_color", Color(0.5, 0.6, 0.5))
		info_vbox.add_child(owned_lbl)
	
	# Buy button
	var buy_btn = Button.new()
	var price = item.get("buy_price", 0)
	buy_btn.text = "BUY %dG" % price
	buy_btn.custom_minimum_size = Vector2(90, 36)
	buy_btn.pressed.connect(_buy_item.bind(item_id))
	
	var gold = GameManager.player_stats.get("gold", 0)
	if gold < price:
		buy_btn.disabled = true
		buy_btn.add_theme_color_override("font_color", Color(0.5, 0.3, 0.3))
	else:
		buy_btn.add_theme_color_override("font_color", Color(0.3, 1.0, 0.3))
	
	var btn_style = StyleBoxFlat.new()
	btn_style.bg_color = Color(0.08, 0.12, 0.08, 0.9)
	btn_style.border_color = Color(0.3, 0.6, 0.3, 0.5)
	btn_style.set_border_width_all(1)
	btn_style.set_corner_radius_all(3)
	btn_style.content_margin_left = 8
	btn_style.content_margin_right = 8
	buy_btn.add_theme_stylebox_override("normal", btn_style)
	buy_btn.add_theme_font_size_override("font_size", 12)
	
	hbox.add_child(buy_btn)

## ─── SELL ROW ────────────────────────────────────────────────────────

func _add_sell_row(item_id: String, item: Dictionary, quantity: int) -> void:
	## Create a sell row for an inventory item.
	var row = PanelContainer.new()
	row.name = "SellRow_%s" % item_id
	row.custom_minimum_size = Vector2(0, 48)
	
	var row_style = StyleBoxFlat.new()
	row_style.bg_color = Color(0.08, 0.06, 0.06, 0.6)
	row_style.set_corner_radius_all(3)
	row_style.content_margin_left = 8
	row_style.content_margin_right = 8
	row_style.content_margin_top = 4
	row_style.content_margin_bottom = 4
	row.add_theme_stylebox_override("panel", row_style)
	_item_container.add_child(row)
	
	# Hover
	row.mouse_entered.connect(_on_row_hover_enter.bind(row, item_id, item))
	row.mouse_exited.connect(_on_row_hover_exit.bind(row))
	
	var hbox = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 8)
	row.add_child(hbox)
	
	var info_vbox = VBoxContainer.new()
	info_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(info_vbox)
	
	var name_label = Label.new()
	name_label.text = "%s  x%d" % [item.get("name", item_id), quantity]
	name_label.add_theme_font_size_override("font_size", 14)
	match item.get("type", ""):
		"consumable":
			name_label.add_theme_color_override("font_color", Color(0.7, 1.0, 0.7))
		"weapon":
			name_label.add_theme_color_override("font_color", Color(1.0, 0.6, 0.3))
		"armor":
			name_label.add_theme_color_override("font_color", Color(0.5, 0.7, 1.0))
		_:
			name_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
	info_vbox.add_child(name_label)
	
	var desc_label = Label.new()
	desc_label.text = item.get("description", "")
	desc_label.add_theme_font_size_override("font_size", 12)
	desc_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.7))
	info_vbox.add_child(desc_label)
	
	# Sell price
	var sell_price = item.get("sell_price", int(item.get("buy_price", 10) * 0.4))
	
	# Sell button
	var sell_btn = Button.new()
	sell_btn.text = "SELL %dG" % sell_price
	sell_btn.custom_minimum_size = Vector2(90, 36)
	sell_btn.pressed.connect(_sell_item.bind(item_id, sell_price))
	sell_btn.add_theme_color_override("font_color", Color(1.0, 0.8, 0.3))
	
	var btn_style = StyleBoxFlat.new()
	btn_style.bg_color = Color(0.12, 0.10, 0.04, 0.9)
	btn_style.border_color = Color(0.6, 0.5, 0.2, 0.5)
	btn_style.set_border_width_all(1)
	btn_style.set_corner_radius_all(3)
	btn_style.content_margin_left = 8
	btn_style.content_margin_right = 8
	sell_btn.add_theme_stylebox_override("normal", btn_style)
	sell_btn.add_theme_font_size_override("font_size", 12)
	
	hbox.add_child(sell_btn)

func _add_owned_label(item: Dictionary) -> void:
	## Show an 'OWNED' label for already-purchased charms.
	var row = HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	_item_container.add_child(row)
	
	var info = VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(info)
	
	var name_lbl = Label.new()
	name_lbl.text = item["name"]
	name_lbl.add_theme_font_size_override("font_size", 14)
	name_lbl.add_theme_color_override("font_color", Color(0.5, 0.5, 0.4))
	info.add_child(name_lbl)
	
	var desc_lbl = Label.new()
	desc_lbl.text = item["description"]
	desc_lbl.add_theme_font_size_override("font_size", 11)
	desc_lbl.add_theme_color_override("font_color", Color(0.4, 0.4, 0.45))
	info.add_child(desc_lbl)
	
	var owned_lbl = Label.new()
	owned_lbl.text = "OWNED"
	owned_lbl.add_theme_font_size_override("font_size", 13)
	owned_lbl.add_theme_color_override("font_color", Color(0.4, 0.7, 0.4))
	owned_lbl.custom_minimum_size = Vector2(80, 36)
	owned_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	owned_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(owned_lbl)

func _add_empty_label(text: String) -> void:
	## Show a 'no items' message.
	var lbl = Label.new()
	lbl.text = text
	lbl.add_theme_font_size_override("font_size", 13)
	lbl.add_theme_color_override("font_color", Color(0.5, 0.5, 0.6))
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_item_container.add_child(lbl)

## ─── BUY LOGIC ───────────────────────────────────────────────────────

func _buy_item(item_id: String) -> void:
	## Process a purchase.
	if not SHOP_ITEMS.has(item_id):
		return
	
	var item = SHOP_ITEMS[item_id]
	var price = item.get("buy_price", 0)
	var gold = GameManager.player_stats.get("gold", 0)
	
	if gold < price:
		if OS.is_debug_build():
			print("[SHOP] Not enough gold! Need %d, have %d" % [price, gold])
		if has_node("/root/SFXManager"):
			SFXManager.play("ui_error")
		# Show floating feedback to player
		_show_shop_toast("Not enough gold! Need %dG" % price, Color(1, 0.3, 0.3))
		return
	
	# PASS 37 FIX: Pre-validate charm purchases to prevent paying for already-owned charms
	if item["type"] == "charm":
		var charm_id = item.get("charm_id", "")
		if charm_id != "" and GameManager.is_charm_unlocked(charm_id):
			if OS.is_debug_build():
				print("[SHOP] Charm already unlocked: %s" % charm_id)
			return
	
	# PASS 37 FIX: Deduct gold via Inventory API to prevent desync
	if has_node("/root/Inventory"):
		if not Inventory.remove_gold(price):
			if OS.is_debug_build():
				print("[SHOP] Gold deduction failed")
			return
	else:
		GameManager.player_stats["gold"] -= price
	
	# Apply purchase based on type
	var purchase_success = true
	match item["type"]:
		"consumable":
			if has_node("/root/Inventory"):
				purchase_success = Inventory.add_item(item_id, 1)
		"weapon", "armor":
			if has_node("/root/Inventory"):
				purchase_success = Inventory.add_item(item_id, 1)
		"charm":
			var charm_id = item.get("charm_id", "")
			if charm_id != "":
				GameManager.unlock_charm(charm_id)

	# Refund gold if inventory rejected item (e.g. max stack reached)
	if not purchase_success:
		if has_node("/root/Inventory"):
			Inventory.add_gold(price)
		else:
			GameManager.player_stats["gold"] += price
		if OS.is_debug_build():
			print("[SHOP] Purchase failed — gold refunded")
		if has_node("/root/SFXManager"):
			SFXManager.play("ui_error")
		return
	
	if OS.is_debug_build():
		print("[SHOP] Purchased %s for %d Gold" % [item["name"], price])
	if has_node("/root/SFXManager"):
		SFXManager.play("shop_buy")
	item_purchased.emit(item_id, price)
	GameManager.stats["items_found"] = GameManager.stats.get("items_found", 0) + 1
	
	# Refresh display
	_update_gold_display()
	_refresh_items()

## ─── SELL LOGIC ──────────────────────────────────────────────────────

func _sell_item(item_id: String, sell_price: int) -> void:
	## Sell one unit of an item from inventory.
	if not has_node("/root/Inventory"):
		return
	
	if not Inventory.has_item(item_id):
		if OS.is_debug_build():
			print("[SHOP] Don't have %s to sell" % item_id)
		return
	
	# PASS 37 FIX: Prevent selling equipped items or key items
	if _is_equipped(item_id):
		if OS.is_debug_build():
			print("[SHOP] Cannot sell equipped item: %s" % item_id)
		return
	var item_data = _get_combined_item_data(item_id)
	if item_data.get("type", "") == "key_item":
		if OS.is_debug_build():
			print("[SHOP] Cannot sell key item: %s" % item_id)
		return
	
	# PASS 37 FIX: Clamp sell_price to at least 1 to prevent free-selling bugs
	sell_price = maxi(sell_price, 1)
	
	# Remove from inventory (check return value to prevent gold duplication)
	if not Inventory.remove_item(item_id, 1):
		push_error("[SHOP] Failed to remove item '%s' during sell" % item_id)
		return
	
	# Add gold via Inventory API to keep sync (which syncs to GameManager)
	Inventory.add_gold(sell_price)
	
	if OS.is_debug_build():
		print("[SHOP] Sold %s for %d Gold" % [item_id, sell_price])
	if has_node("/root/SFXManager"):
		SFXManager.play("shop_sell")
	item_sold.emit(item_id, sell_price)
	
	_update_gold_display()
	_refresh_items()

## ─── HOVER / TOOLTIP ─────────────────────────────────────────────────

func _on_row_hover_enter(row: Control, item_id: String, item: Dictionary) -> void:
	## Highlight row + show tooltip.
	_hovered_row = row

	# Brighten row
	if _hover_tween and _hover_tween.is_running():
		_hover_tween.kill()
	if is_instance_valid(row):
		_hover_tween = create_tween()
		_hover_tween.tween_property(row, "modulate", Color(1.2, 1.2, 1.3), 0.1)

	# Show tooltip
	_show_tooltip(item_id, item)

func _on_row_hover_exit(row: Control) -> void:
	## Un-highlight row + hide tooltip.
	if _hovered_row == row:
		_hovered_row = null

	if _hover_tween and _hover_tween.is_running():
		_hover_tween.kill()
	if is_instance_valid(row):
		_hover_tween = create_tween()
		_hover_tween.tween_property(row, "modulate", Color.WHITE, 0.1)

	_hide_tooltip()

func _show_tooltip(item_id: String, item: Dictionary) -> void:
	## Populate and display the tooltip.
	_tooltip_name.text = item.get("name", item_id)
	
	var bbcode = ""
	bbcode += item.get("description", "") + "\n"
	bbcode += "[color=#888888]Type: %s[/color]\n" % item.get("type", "unknown").capitalize()
	
	if item.has("attack_bonus") and item["attack_bonus"] > 0:
		bbcode += "[color=#ff9955]+%.0f ATK[/color] " % item["attack_bonus"]
	if item.has("defense_bonus") and item["defense_bonus"] > 0:
		bbcode += "[color=#6699ff]+%.0f DEF[/color] " % item["defense_bonus"]
	if item.has("effect"):
		bbcode += "\n[color=#aaffaa]Effect: %s (%.0f)[/color]" % [item["effect"], item.get("value", 0)]
	
	bbcode += "\n[color=#ffee88]Buy: %dG[/color]  [color=#ddaa55]Sell: %dG[/color]" % [
		item.get("buy_price", 0),
		item.get("sell_price", int(item.get("buy_price", 10) * 0.4))
	]
	
	_tooltip_desc.text = bbcode
	
	_tooltip_panel.visible = true
	_tooltip_panel.position = Vector2(_panel.position.x + _panel.size.x + 8, _panel.position.y)

func _hide_tooltip() -> void:
	if _tooltip_panel:
		_tooltip_panel.visible = false

## ─── FILTER / SORT HELPERS ──────────────────────────────────────────

func _apply_filter_to_ids(ids: Array) -> Array:
	## Filter item IDs by the current filter mode.
	if _filter_mode == FilterMode.ALL:
		return ids
	
	var type_str: String
	match _filter_mode:
		FilterMode.CONSUMABLE: type_str = "consumable"
		FilterMode.WEAPON: type_str = "weapon"
		FilterMode.ARMOR: type_str = "armor"
		FilterMode.CHARM: type_str = "charm"
		_: return ids
	
	var result: Array = []
	for id in ids:
		var data = _get_combined_item_data(id)
		if data.get("type", "") == type_str:
			result.append(id)
	return result

func _apply_sort(ids: Array, use_buy_price: bool) -> Array:
	## Sort item IDs by the current sort mode.
	if _sort_mode == SortMode.NONE or ids.is_empty():
		return ids
	
	var sorted_ids = ids.duplicate()
	
	match _sort_mode:
		SortMode.NAME_ASC:
			sorted_ids.sort_custom(func(a, b):
				var na = _get_combined_item_data(a).get("name", a)
				var nb = _get_combined_item_data(b).get("name", b)
				return na < nb
			)
		SortMode.NAME_DESC:
			sorted_ids.sort_custom(func(a, b):
				var na = _get_combined_item_data(a).get("name", a)
				var nb = _get_combined_item_data(b).get("name", b)
				return na > nb
			)
		SortMode.PRICE_ASC:
			var key = "buy_price" if use_buy_price else "sell_price"
			sorted_ids.sort_custom(func(a, b):
				var pa = _get_combined_item_data(a).get(key, 0)
				var pb = _get_combined_item_data(b).get(key, 0)
				return pa < pb
			)
		SortMode.PRICE_DESC:
			var key = "buy_price" if use_buy_price else "sell_price"
			sorted_ids.sort_custom(func(a, b):
				var pa = _get_combined_item_data(a).get(key, 0)
				var pb = _get_combined_item_data(b).get(key, 0)
				return pa > pb
			)
		SortMode.TYPE:
			var type_order = {"consumable": 0, "weapon": 1, "armor": 2, "charm": 3, "material": 4, "key_item": 5}
			sorted_ids.sort_custom(func(a, b):
				var ta = type_order.get(_get_combined_item_data(a).get("type", ""), 9)
				var tb = type_order.get(_get_combined_item_data(b).get("type", ""), 9)
				return ta < tb
			)
	
	return sorted_ids

func _get_combined_item_data(item_id: String) -> Dictionary:
	## Get item data from SHOP_ITEMS or Inventory ITEMS.
	if SHOP_ITEMS.has(item_id):
		return SHOP_ITEMS[item_id]
	if has_node("/root/Inventory") and Inventory.ITEMS.has(item_id):
		return Inventory.ITEMS[item_id]
	return {}

func _is_equipped(item_id: String) -> bool:
	## Check if the item is currently equipped.
	if not has_node("/root/Inventory"):
		return false
	for slot in Inventory.equipment.values():
		if slot == item_id:
			return true
	return false

func _apply_consumable_effect(item: Dictionary) -> void:
	## Apply the immediate effect of a consumable.
	var effect = item.get("effect", "")
	var value = item.get("value", 0.0)
	
	match effect:
		"heal":
			GameManager.player_stats["hp"] = min(
				GameManager.player_stats["hp"] + int(value),
				GameManager.player_stats["max_hp"])
		"restore_mana":
			GameManager.player_stats["mp"] = min(
				GameManager.player_stats["mp"] + int(value),
				GameManager.player_stats["max_mp"])
		"reduce_glitch":
			GameManager.add_glitch_corruption(-value)
		"null_heal":
			GameManager.player_stats["hp"] = GameManager.player_stats["max_hp"]
			GameManager.add_glitch_corruption(3.0)  # Corruption cost

func _input(event: InputEvent) -> void:
	if not _is_open:
		return
	if event.is_action_pressed("ui_cancel"):
		close_shop()
		get_viewport().set_input_as_handled()

func _show_shop_toast(msg: String, color: Color = Color.WHITE) -> void:
	## Show a brief floating text message above the shop panel.
	if not is_inside_tree():
		return
	var lbl = Label.new()
	lbl.text = msg
	lbl.add_theme_font_size_override("font_size", 14)
	lbl.add_theme_color_override("font_color", color)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.set_anchors_preset(Control.PRESET_CENTER_TOP)
	lbl.offset_top = 80
	lbl.z_index = 200
	add_child(lbl)
	var tw = create_tween()
	tw.tween_property(lbl, "offset_top", 50, 1.2)
	tw.parallel().tween_property(lbl, "modulate:a", 0.0, 1.2)
	tw.tween_callback(lbl.queue_free)
