extends Node

## ==========================================================================
## DROP MANAGER — Spawns loot pickups when enemies die
## ==========================================================================
## Usage:
##   DropManager.spawn_drops(enemy.global_position, loot_table, parent)
##   DropManager.spawn_item(position, "health_potion", 1, parent)
##   DropManager.spawn_gold(position, 25, parent)
## ==========================================================================

signal item_dropped(item_id: String, position: Vector2)
signal item_picked_up(item_id: String, quantity: int)
signal gold_picked_up(amount: int)

## Auto-pickup range for minor loot (common consumables)
@export var auto_pickup_range: float = 80.0
## Magnetism range — items get pulled toward player
@export var magnetism_range: float = 150.0
## Magnetism speed
@export var magnetism_speed: float = 300.0
## Enable auto-pickup for common items
@export var auto_pickup_enabled: bool = true

## Active pickups in the world (for cleanup)
var _active_pickups: Array[Node2D] = []

## Cached player reference (PERF: avoids per-frame group lookup in _process)
var _cached_player_ref: Node2D = null

## Maximum simultaneous pickups (performance guard)
const MAX_PICKUPS: int = 50

func _ready() -> void:
	pass  # Default PROCESS_MODE_INHERIT: pickups pause correctly when tree is paused

## ─── MAIN API ────────────────────────────────────────────────────────

func spawn_drops(pos: Vector2, loot_table: Resource, parent: Node = null) -> Array[Node2D]:
	## Roll a loot table and spawn all drops at position with physics pop.
	if not loot_table:
		return []
	
	var target_parent = parent if parent else _get_default_parent()
	var spawned: Array[Node2D] = []
	
	# Roll items
	var drops = loot_table.roll()
	for drop in drops:
		var pickup = _create_item_pickup(drop["item_id"], drop["quantity"], drop.get("rarity", -1))
		if pickup:
			target_parent.add_child(pickup)
			pickup.global_position = pos
			pickup.set_meta("spawn_y", pos.y)
			_apply_pop_physics(pickup)
			spawned.append(pickup)
			_active_pickups.append(pickup)
			item_dropped.emit(drop["item_id"], pos)
	
	# Roll gold — spawn as gold pickup
	var gold_amount = loot_table.roll_gold()
	if gold_amount > 0:
		var gold_pickup = _create_gold_pickup(gold_amount)
		if gold_pickup:
			target_parent.add_child(gold_pickup)
			gold_pickup.global_position = pos
			gold_pickup.set_meta("spawn_y", pos.y)
			_apply_pop_physics(gold_pickup)
			spawned.append(gold_pickup)
			_active_pickups.append(gold_pickup)
	
	# Enforce pickup cap
	_enforce_pickup_limit()
	
	return spawned

func spawn_item(pos: Vector2, item_id: String, quantity: int = 1, parent: Node = null) -> Node2D:
	## Spawn a single item pickup at position.
	if quantity <= 0:
		push_warning("[DROP] Ignoring non-positive item pickup quantity for %s: %d" % [item_id, quantity])
		return null
	var target_parent = parent if parent else _get_default_parent()
	var pickup = _create_item_pickup(item_id, quantity)
	if pickup:
		target_parent.add_child(pickup)
		pickup.global_position = pos
		pickup.set_meta("spawn_y", pos.y)
		_apply_pop_physics(pickup)
		_active_pickups.append(pickup)
		item_dropped.emit(item_id, pos)
	return pickup

func spawn_gold(pos: Vector2, amount: int, parent: Node = null) -> Node2D:
	## Spawn a gold pickup at position.
	if amount <= 0:
		return null
	var target_parent = parent if parent else _get_default_parent()
	var gold_pickup = _create_gold_pickup(amount)
	if gold_pickup:
		target_parent.add_child(gold_pickup)
		gold_pickup.global_position = pos
		gold_pickup.set_meta("spawn_y", pos.y)
		_apply_pop_physics(gold_pickup)
		_active_pickups.append(gold_pickup)
	return gold_pickup

func clear_all_pickups() -> void:
	## Remove all active pickups from the world.
	for pickup in _active_pickups:
		if is_instance_valid(pickup):
			pickup.queue_free()
	_active_pickups.clear()

## ─── PICKUP CREATION ─────────────────────────────────────────────────

func _create_item_pickup(item_id: String, quantity: int = 1, rarity_override: int = -1) -> Node2D:
	## Create an item pickup node with visual feedback.
	if _active_pickups.size() >= MAX_PICKUPS:
		return null
	if quantity <= 0:
		push_warning("[DROP] Ignoring non-positive item pickup quantity for %s: %d" % [item_id, quantity])
		return null
	
	# Look up item data
	var item_data = _get_item_data(item_id)
	if item_data.is_empty():
		push_warning("[DROP] Unknown item_id: %s" % item_id)
		return null
	
	var pickup = Node2D.new()
	pickup.name = "ItemPickup_%s" % item_id
	pickup.set_meta("pickup_type", "item")
	pickup.set_meta("item_id", item_id)
	pickup.set_meta("quantity", quantity)
	
	# Determine rarity for visual effects
	var rarity = rarity_override if rarity_override >= 0 else _get_item_rarity(item_id)
	pickup.set_meta("rarity", rarity)
	
	# Sprite — prefer Kenney item sprite, fallback to generated texture
	var sprite = Sprite2D.new()
	sprite.name = "Sprite"
	var kenney_tex: Texture2D = null
	if has_node("/root/AssetManager"):
		kenney_tex = AssetManager.get_item_texture(item_id)
	if kenney_tex:
		sprite.texture = kenney_tex
		# Scale Kenney items to ~28px for pickup size
		var tex_size = kenney_tex.get_size()
		if tex_size.x > 0 and tex_size.y > 0:
			var uniform = 28.0 / maxf(tex_size.x, tex_size.y)
			sprite.scale = Vector2(uniform, uniform)
	else:
		sprite.texture = _create_pickup_texture(item_data, rarity)
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	pickup.add_child(sprite)
	
	# Rarity glow
	_add_rarity_glow(pickup, rarity)
	
	# Pickup area (player walks over it)
	var area = Area2D.new()
	area.name = "PickupArea"
	area.collision_layer = 0
	area.collision_mask = 2  # Player layer
	var shape = CollisionShape2D.new()
	var circle = CircleShape2D.new()
	circle.radius = 20.0
	shape.shape = circle
	area.add_child(shape)
	pickup.add_child(area)
	area.body_entered.connect(_on_pickup_touched.bind(pickup))
	
	# Label showing item name
	var label = Label.new()
	label.name = "ItemLabel"
	label.text = item_data.get("name", item_id)
	if quantity > 1:
		label.text += " x%d" % quantity
	label.add_theme_font_size_override("font_size", 10)
	label.add_theme_color_override("font_color", _get_rarity_color(rarity))
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.position = Vector2(-40, -24)
	label.custom_minimum_size = Vector2(80, 0)
	label.visible = false  # Show on proximity
	pickup.add_child(label)
	
	# Bob animation
	_start_bob_animation(pickup)
	
	# Lifetime timer — pickups despawn after 30 seconds
	var lifetime = Timer.new()
	lifetime.name = "LifetimeTimer"
	lifetime.wait_time = 30.0
	lifetime.one_shot = true
	lifetime.timeout.connect(_on_pickup_expired.bind(pickup))
	lifetime.autostart = true
	pickup.add_child(lifetime)
	
	# Add script-like behavior via process
	pickup.set_meta("velocity", Vector2.ZERO)
	pickup.set_meta("grounded", false)
	pickup.set_meta("magnetized", false)
	pickup.set_process(true)
	
	return pickup

func _create_gold_pickup(amount: int) -> Node2D:
	## Create a gold coin pickup.
	if _active_pickups.size() >= MAX_PICKUPS:
		return null
	if amount <= 0:
		return null
	
	var pickup = Node2D.new()
	pickup.name = "GoldPickup_%d" % amount
	pickup.set_meta("pickup_type", "gold")
	pickup.set_meta("gold_amount", amount)
	pickup.set_meta("rarity", 0)  # Gold is always common rarity visual
	
	# Gold sprite — yellow square
	var sprite = Sprite2D.new()
	sprite.name = "Sprite"
	sprite.texture = _create_gold_texture(amount)
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	pickup.add_child(sprite)
	
	# Subtle yellow glow
	_add_gold_glow(pickup)
	
	# Pickup area
	var area = Area2D.new()
	area.name = "PickupArea"
	area.collision_layer = 0
	area.collision_mask = 2
	var shape = CollisionShape2D.new()
	var circle = CircleShape2D.new()
	circle.radius = 24.0  # Slightly larger for gold
	shape.shape = circle
	area.add_child(shape)
	pickup.add_child(area)
	area.body_entered.connect(_on_gold_touched.bind(pickup))
	
	# Label
	var label = Label.new()
	label.name = "GoldLabel"
	label.text = "%d G" % amount
	label.add_theme_font_size_override("font_size", 10)
	label.add_theme_color_override("font_color", Color(1.0, 0.9, 0.3))
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.position = Vector2(-30, -20)
	label.custom_minimum_size = Vector2(60, 0)
	label.visible = false
	pickup.add_child(label)
	
	# Bob
	_start_bob_animation(pickup)
	
	# Lifetime
	var lifetime = Timer.new()
	lifetime.name = "LifetimeTimer"
	lifetime.wait_time = 20.0
	lifetime.one_shot = true
	lifetime.timeout.connect(_on_pickup_expired.bind(pickup))
	lifetime.autostart = true
	pickup.add_child(lifetime)
	
	pickup.set_meta("velocity", Vector2.ZERO)
	pickup.set_meta("grounded", false)
	pickup.set_meta("magnetized", false)
	
	return pickup

## ─── PHYSICS POP ─────────────────────────────────────────────────────

func _apply_pop_physics(pickup: Node2D) -> void:
	## Give the pickup a burst of velocity to 'pop' out of the enemy.
	var angle = randf_range(-PI * 0.8, -PI * 0.2)  # Upward arc
	var strength = randf_range(120.0, 220.0)
	var vel = Vector2(cos(angle), sin(angle)) * strength
	pickup.set_meta("velocity", vel)
	pickup.set_meta("grounded", false)

## ─── PROCESS — physics + magnetism ───────────────────────────────────

func _process(delta: float) -> void:
	# PERF: Skip when no pickups exist
	if _active_pickups.is_empty():
		return
	var player = _get_player()
	
	for i in range(_active_pickups.size() - 1, -1, -1):
		var pickup = _active_pickups[i]
		if not is_instance_valid(pickup):
			_active_pickups.remove_at(i)
			continue
		
		_update_pickup_physics(pickup, delta)
		
		if player and is_instance_valid(player):
			_update_magnetism(pickup, player, delta)
			_update_label_visibility(pickup, player)

func _update_pickup_physics(pickup: Node2D, delta: float) -> void:
	## Simple gravity + bounce for the pop effect.
	if pickup.get_meta("grounded", false):
		return
	
	var vel: Vector2 = pickup.get_meta("velocity", Vector2.ZERO)
	vel.y += 500.0 * delta  # Gravity
	pickup.position += vel * delta
	pickup.set_meta("velocity", vel)
	
	# Simple ground check — stop at spawn y + 10 (approximate)
	# In a real scenario this would raycast, but for dropped items this works
	if vel.y > 0 and pickup.position.y > pickup.get_meta("spawn_y", pickup.position.y + 30):
		vel.y = -vel.y * 0.3  # Bounce
		if abs(vel.y) < 20.0:
			vel = Vector2.ZERO
			pickup.set_meta("grounded", true)
		pickup.set_meta("velocity", vel)

func _update_magnetism(pickup: Node2D, player: Node2D, delta: float) -> void:
	## Pull pickups toward the player when in range.
	if not auto_pickup_enabled:
		return
	
	var dist = pickup.global_position.distance_to(player.global_position)
	
	if dist < magnetism_range:
		var direction = (player.global_position - pickup.global_position).normalized()
		var pull_strength = magnetism_speed * (1.0 - dist / maxf(magnetism_range, 0.01))  # Stronger when closer
		pickup.global_position += direction * pull_strength * delta
		pickup.set_meta("magnetized", true)
		pickup.set_meta("grounded", true)  # Stop physics when magnetized

func _update_label_visibility(pickup: Node2D, player: Node2D) -> void:
	## Show item label when player is nearby.
	var label = pickup.get_node_or_null("ItemLabel")
	if not label:
		label = pickup.get_node_or_null("GoldLabel")
	if not label:
		return
	
	var dist = pickup.global_position.distance_to(player.global_position)
	label.visible = dist < 100.0

## ─── PICKUP COLLECTION ───────────────────────────────────────────────

func _on_pickup_touched(body: Node2D, pickup: Node2D) -> void:
	## Player walked over an item pickup.
	if not is_instance_valid(body) or not body.is_in_group("player"):
		return
	if not is_instance_valid(pickup):
		return
	
	var item_id = pickup.get_meta("item_id", "")
	var quantity: int = int(pickup.get_meta("quantity", 1))
	
	if item_id == "" or quantity <= 0:
		return
	
	# Add to inventory
	var success = false
	if has_node("/root/Inventory"):
		# Ensure item is in the database
		if not Inventory.ITEMS.has(item_id):
			var item_data = _get_item_data(item_id)
			if not item_data.is_empty():
				Inventory.ITEMS[item_id] = item_data
		success = Inventory.add_item(item_id, quantity)
	
	if success:
		_play_pickup_animation(pickup)
		item_picked_up.emit(item_id, quantity)
		
		# Show floating text
		var item_name = _get_item_data(item_id).get("name", item_id)
		var rarity = pickup.get_meta("rarity", 0)
		var _color = _get_rarity_color(rarity)
		if has_node("/root/VFXLibrary"):
			VFXLibrary.spawn_status_indicator(
				"+%s x%d" % [item_name, quantity],
				pickup.global_position + Vector2(0, -30),
				pickup.get_parent(),
				false
			)
	else:
		push_warning("[DROP] Failed to add %s to inventory" % item_id)

func _on_gold_touched(body: Node2D, pickup: Node2D) -> void:
	## Player walked over a gold pickup.
	if not is_instance_valid(body) or not body.is_in_group("player"):
		return
	if not is_instance_valid(pickup):
		return
	
	var amount = pickup.get_meta("gold_amount", 0)
	if amount <= 0:
		return

	if has_node("/root/GameManager"):
		GameManager.add_gold(amount)
	if has_node("/root/Inventory"):
		Inventory.gold = GameManager.player_stats.get("gold", 0)
	
	_play_pickup_animation(pickup)
	gold_picked_up.emit(amount)

	if has_node("/root/VFXLibrary"):
		VFXLibrary.spawn_status_indicator(
			"+%d G" % amount,
			pickup.global_position + Vector2(0, -30),
			pickup.get_parent(),
			false
		)

func _on_pickup_expired(pickup: Node2D) -> void:
	## Remove pickup after lifetime expires.
	if is_instance_valid(pickup):
		# Fade out
		var tween = pickup.create_tween()
		tween.tween_property(pickup, "modulate:a", 0.0, 0.5)
		tween.tween_callback(pickup.queue_free)

## ─── PICKUP ANIMATION ────────────────────────────────────────────────

func _play_pickup_animation(pickup: Node2D) -> void:
	## Scale down + fade out when collected.
	# Disable further collisions
	var area = pickup.get_node_or_null("PickupArea")
	if area:
		area.set_deferred("monitoring", false)
	
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(pickup, "scale", Vector2(0.1, 0.1), 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	tween.tween_property(pickup, "modulate:a", 0.0, 0.2)
	tween.tween_property(pickup, "position:y", pickup.position.y - 20, 0.2)
	tween.chain().tween_callback(pickup.queue_free)

func _start_bob_animation(pickup: Node2D) -> void:
	## Gentle floating bob animation.
	var sprite = pickup.get_node_or_null("Sprite")
	if not sprite:
		return
	
	var tween = pickup.create_tween()
	tween.set_loops()
	tween.tween_property(sprite, "position:y", -4.0, 0.6).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(sprite, "position:y", 4.0, 0.6).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

## ─── RARITY VISUALS ─────────────────────────────────────────────────

func _add_rarity_glow(pickup: Node2D, rarity: int) -> void:
	## Add a colored glow effect based on item rarity.
	if rarity <= 0:  # No glow for common
		return
	
	var color = _get_rarity_color(rarity)
	
	# Create glow sprite (larger, semi-transparent, behind item)
	var glow = Sprite2D.new()
	glow.name = "RarityGlow"
	glow.z_index = -1
	
	# Create a simple glow texture
	var img = Image.create(16, 16, false, Image.FORMAT_RGBA8)
	img.fill(Color(color.r, color.g, color.b, 0.4))
	var tex = ImageTexture.create_from_image(img)
	glow.texture = tex
	glow.scale = Vector2(2.5, 2.5)
	glow.modulate = Color(color.r, color.g, color.b, 0.5)
	pickup.add_child(glow)
	
	# Pulse animation
	var tween = pickup.create_tween()
	tween.set_loops()
	tween.tween_property(glow, "modulate:a", 0.2, 0.8).set_trans(Tween.TRANS_SINE)
	tween.tween_property(glow, "modulate:a", 0.6, 0.8).set_trans(Tween.TRANS_SINE)

func _add_gold_glow(pickup: Node2D) -> void:
	## Subtle gold shimmer.
	var glow = Sprite2D.new()
	glow.name = "GoldGlow"
	glow.z_index = -1
	var img = Image.create(12, 12, false, Image.FORMAT_RGBA8)
	img.fill(Color(1.0, 0.9, 0.3, 0.3))
	var tex = ImageTexture.create_from_image(img)
	glow.texture = tex
	glow.scale = Vector2(2.0, 2.0)
	glow.modulate = Color(1.0, 0.9, 0.3, 0.35)
	pickup.add_child(glow)

## ─── TEXTURE GENERATION ─────────────────────────────────────────────

func _create_pickup_texture(item_data: Dictionary, rarity: int) -> ImageTexture:
	## Create a simple colored square texture for the pickup.
	var img = Image.create(12, 12, false, Image.FORMAT_RGBA8)
	
	var base_color: Color
	match item_data.get("type", "consumable"):
		"consumable":
			base_color = Color(0.3, 0.9, 0.3)  # Green
		"weapon":
			base_color = Color(0.9, 0.5, 0.2)  # Orange
		"armor":
			base_color = Color(0.4, 0.6, 1.0)  # Blue
		"charm":
			base_color = Color(1.0, 0.85, 0.2)  # Gold
		"material":
			base_color = Color(0.6, 0.6, 0.6)  # Gray
		"key_item":
			base_color = Color(1.0, 0.3, 0.8)  # Pink
		_:
			base_color = Color(0.7, 0.7, 0.7)
	
	# Tint by rarity
	var rarity_tint = _get_rarity_color(rarity)
	base_color = base_color.lerp(rarity_tint, 0.3)
	
	# Draw a bordered square
	for x in range(12):
		for y in range(12):
			if x == 0 or x == 11 or y == 0 or y == 11:
				img.set_pixel(x, y, base_color.darkened(0.3))
			else:
				img.set_pixel(x, y, base_color)
	
	return ImageTexture.create_from_image(img)

func _create_gold_texture(amount: int) -> ImageTexture:
	## Create a gold coin texture.
	var size = 10 if amount < 50 else 14
	var img = Image.create(size, size, false, Image.FORMAT_RGBA8)
	var gold_color = Color(1.0, 0.85, 0.1)
	var dark_gold = Color(0.8, 0.65, 0.05)
	
	for x in range(size):
		for y in range(size):
			# Simple circle approximation
			var cx = size / 2.0
			var cy = size / 2.0
			var dist = sqrt((x - cx) * (x - cx) + (y - cy) * (y - cy))
			if dist < size / 2.0 - 1:
				img.set_pixel(x, y, gold_color)
			elif dist < size / 2.0:
				img.set_pixel(x, y, dark_gold)
	
	return ImageTexture.create_from_image(img)

## ─── HELPERS ─────────────────────────────────────────────────────────

func _get_item_data(item_id: String) -> Dictionary:
	## Get item data from ShopSystem or Inventory.
	if has_node("/root/ShopSystem") and ShopSystem.SHOP_ITEMS.has(item_id):
		return ShopSystem.SHOP_ITEMS[item_id]
	if has_node("/root/Inventory") and Inventory.ITEMS.has(item_id):
		return Inventory.ITEMS[item_id]
	return {}

func _get_item_rarity(item_id: String) -> int:
	## Determine rarity from item data (0=common by default).
	var data = _get_item_data(item_id)
	if data.has("rarity"):
		return data["rarity"]
	# Estimate rarity from price
	var price = data.get("buy_price", 10)
	if price >= 1000:
		return 4  # Legendary
	elif price >= 500:
		return 3  # Epic
	elif price >= 200:
		return 2  # Rare
	elif price >= 50:
		return 1  # Uncommon
	return 0  # Common

func _get_rarity_color(rarity: int) -> Color:
	## Get color for a rarity level.
	match rarity:
		0: return Color(0.8, 0.8, 0.8)      # Common — gray-white
		1: return Color(0.3, 1.0, 0.3)      # Uncommon — green
		2: return Color(0.3, 0.5, 1.0)      # Rare — blue
		3: return Color(0.7, 0.3, 1.0)      # Epic — purple
		4: return Color(1.0, 0.85, 0.1)     # Legendary — gold
		_: return Color.WHITE

func _get_player() -> Node2D:
	## Find the player node (cached to avoid per-frame group lookup).
	if _cached_player_ref and is_instance_valid(_cached_player_ref):
		return _cached_player_ref
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		_cached_player_ref = players[0]
		return _cached_player_ref
	return null

func _get_default_parent() -> Node:
	## Get a sensible parent for spawned pickups.
	var current_scene = get_tree().current_scene
	if current_scene:
		return current_scene
	return get_tree().root

func _enforce_pickup_limit() -> void:
	## Remove oldest pickups if over the limit.
	while _active_pickups.size() > MAX_PICKUPS:
		var oldest = _active_pickups.pop_front()
		if is_instance_valid(oldest):
			oldest.queue_free()
