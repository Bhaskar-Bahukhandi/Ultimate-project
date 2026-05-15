extends Node

## ==========================================================================
## OBJECT POOL — Reusable node pools for projectiles, VFX, damage numbers
## ==========================================================================
## Usage:
##   var proj = ObjectPool.acquire("enemy_projectile")   # Get from pool
##   ObjectPool.release("enemy_projectile", proj)         # Return to pool
##   ObjectPool.preload_pool("enemy_projectile", 10)      # Pre-warm pool
## ==========================================================================

# Pool storage: { pool_name: [available_nodes] }
var _pools: Dictionary = {}

# Active counts for debugging
var _active_counts: Dictionary = {}

# Factory functions: { pool_name: Callable that creates a new node }
var _factories: Dictionary = {}

# Maximum pool size per type (prevents memory bloat)
const MAX_POOL_SIZE: int = 50

func _ready() -> void:
	# Register built-in pool types
	register_pool("damage_number", _create_damage_number, 15)
	register_pool("hit_spark", _create_hit_spark, 10)
	register_pool("enemy_projectile", _create_enemy_projectile, 8)
	register_pool("afterimage", _create_afterimage, 6)

func register_pool(pool_name: String, factory: Callable, preload_count: int = 0) -> void:
	## Register a new pool type with a factory function.
	_pools[pool_name] = []
	_active_counts[pool_name] = 0
	_factories[pool_name] = factory
	
	if preload_count > 0:
		preload_pool(pool_name, preload_count)

func preload_pool(pool_name: String, count: int) -> void:
	## Pre-create nodes for a pool to avoid runtime allocation.
	if not _factories.has(pool_name):
		push_error("[POOL] No factory for pool: %s" % pool_name)
		return
	
	for i in range(count):
		if _pools[pool_name].size() >= MAX_POOL_SIZE:
			break
		var node = _factories[pool_name].call()
		node.visible = false
		node.set_meta("pool_name", pool_name)
		add_child(node)
		_pools[pool_name].append(node)

func acquire(pool_name: String) -> Node:
	## Get a node from the pool. Creates new if pool is empty.
	if not _pools.has(pool_name):
		if _factories.has(pool_name):
			_pools[pool_name] = []
			_active_counts[pool_name] = 0
		else:
			push_error("[POOL] Unknown pool: %s" % pool_name)
			return null

	var node: Node = null
	# Pop nodes from the pool, skipping any that were freed externally
	while _pools[pool_name].size() > 0:
		var candidate = _pools[pool_name].pop_back()
		if is_instance_valid(candidate):
			node = candidate
			break
		# Stale node — discard silently

	if node == null:
		# Pool empty or all stale — create new
		if _factories.has(pool_name):
			node = _factories[pool_name].call()
			node.set_meta("pool_name", pool_name)
		else:
			push_error("[POOL] No factory for pool: %s" % pool_name)
			return null

	node.visible = true
	_active_counts[pool_name] = _active_counts.get(pool_name, 0) + 1

	# Remove from our tree so caller can add it to their scene
	if node.get_parent() == self:
		remove_child(node)

	return node

func release(pool_name: String, node: Node) -> void:
	## Return a node to the pool for reuse.
	if not is_instance_valid(node):
		return

	if not _pools.has(pool_name):
		_pools[pool_name] = []

	# BUG 13 FIX: Purge stale references when pool is large
	@warning_ignore("integer_division")
	if _pools[pool_name].size() >= MAX_POOL_SIZE / 2:
		_purge_stale(pool_name)

	# Double-release guard — prevent same node being inserted twice
	if node in _pools[pool_name]:
		return

	# Remove from current parent
	if node.get_parent():
		node.get_parent().remove_child(node)

	# Reset common properties
	node.visible = false
	if node is Node2D:
		node.position = Vector2.ZERO
		node.rotation = 0.0
		node.scale = Vector2.ONE
		node.modulate = Color.WHITE

	# Always decrement active count on release
	_active_counts[pool_name] = max(0, _active_counts.get(pool_name, 0) - 1)

	# Re-add to our tree for safekeeping
	if _pools[pool_name].size() < MAX_POOL_SIZE:
		add_child(node)
		_pools[pool_name].append(node)
	else:
		# Pool full — just free it
		node.queue_free()

func _purge_stale(pool_name: String) -> void:
	## BUG 13 FIX: Remove freed/invalid references from a pool.
	if not _pools.has(pool_name):
		return
	var valid_nodes: Array = []
	for n in _pools[pool_name]:
		if is_instance_valid(n):
			valid_nodes.append(n)
	_pools[pool_name] = valid_nodes

func release_after_delay(pool_name: String, node: Node, delay: float) -> void:
	## Return a node to the pool after a delay. Useful for timed VFX.
	if not is_instance_valid(node):
		return
	# Tag node to prevent manual release during the delay
	node.set_meta("_pool_pending_release", true)
	await get_tree().create_timer(delay).timeout
	if not is_inside_tree(): return
	if is_instance_valid(node):
		node.remove_meta("_pool_pending_release")
		release(pool_name, node)

func get_pool_stats() -> Dictionary:
	## Debug: get pool sizes and active counts.
	var result: Dictionary = {}
	for pool_name in _pools.keys():
		result[pool_name] = {
			"available": _pools[pool_name].size(),
			"active": _active_counts.get(pool_name, 0)
		}
	return result

# ==========================================================================
# FACTORY FUNCTIONS — Create specific poolable node types
# ==========================================================================

func _create_damage_number() -> Node2D:
	## Create a damage number popup node.
	var container = Node2D.new()
	container.name = "PooledDamageNum"
	
	var label = Label.new()
	label.name = "Label"
	label.add_theme_font_size_override("font_size", 16)
	label.add_theme_color_override("font_color", Color(1.0, 0.3, 0.3))
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.position = Vector2(-30, -20)
	container.add_child(label)
	
	return container

func _create_hit_spark() -> Node2D:
	## Create a hit spark VFX node.
	var spark = Node2D.new()
	spark.name = "PooledHitSpark"
	
	# Simple colored rect that fades
	var rect = ColorRect.new()
	rect.name = "Visual"
	rect.size = Vector2(8, 8)
	rect.position = Vector2(-4, -4)
	rect.color = Color(1.0, 0.9, 0.3, 1.0)
	spark.add_child(rect)
	
	return spark

func _create_enemy_projectile() -> Node2D:
	## Create a reusable enemy projectile.
	var proj = Area2D.new()
	proj.name = "PooledProjectile"
	proj.collision_layer = 0
	proj.collision_mask = 2
	
	var shape = CollisionShape2D.new()
	var circle = CircleShape2D.new()
	circle.radius = 8.0
	shape.shape = circle
	proj.add_child(shape)
	
	var visual = ColorRect.new()
	visual.name = "Visual"
	visual.size = Vector2(12, 12)
	visual.position = Vector2(-6, -6)
	visual.color = Color(1.0, 0.2, 0.2, 0.9)
	proj.add_child(visual)
	
	return proj

func _create_afterimage() -> Node2D:
	## Create a reusable dash afterimage ghost.
	var ghost = Node2D.new()
	ghost.name = "PooledAfterimage"
	
	var rect = ColorRect.new()
	rect.name = "Visual"
	rect.size = Vector2(24, 36)
	rect.position = Vector2(-12, -36)
	rect.color = Color(0.3, 0.5, 1.0, 0.6)
	ghost.add_child(rect)
	
	return ghost
