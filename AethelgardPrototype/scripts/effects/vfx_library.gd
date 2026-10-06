extends Node

## ==================================================================================
## VFX LIBRARY — Spawnable Particle & Visual Effects (Polished Edition)
## ==================================================================================
## Call VFXLibrary.spawn(effect_name, position, parent)
## Effects auto-free after lifetime. All use CPUParticles2D or tween-based visuals.
## Supports: particles, arc, vertical_arc, beam, circle, ring_burst, shatter,
##           lightning, shockwave, flash effect types.
## ==================================================================================

# Effect presets dictionary: effect_name -> config
const EFFECTS = {
	# ── COMBAT HIT EFFECTS ─────────────────────────────────────────────────
	"vfx_hit_spark": {
		"color": Color(1, 0.9, 0.3),
		"color_end": Color(1, 0.4, 0.1, 0.0),
		"amount": 12,
		"lifetime": 0.35,
		"speed": 160.0,
		"spread": 160.0,
		"gravity": Vector2(0, 120),
		"scale_min": 1.5,
		"scale_max": 3.5,
		"damping": 20,
	},
	"vfx_hit_spark_heavy": {
		"color": Color(1, 0.7, 0.2),
		"color_end": Color(1, 0.15, 0.0, 0.0),
		"amount": 20,
		"lifetime": 0.45,
		"speed": 220.0,
		"spread": 200.0,
		"gravity": Vector2(0, 180),
		"scale_min": 2.0,
		"scale_max": 5.0,
		"damping": 15,
	},
	"vfx_slash_arc": {
		"type": "arc",
		"color": Color(0.9, 0.95, 1.0),
		"duration": 0.18,
		"size": Vector2(65, 8),
	},
	"vfx_slash_arc_heavy": {
		"type": "arc",
		"color": Color(1.0, 0.85, 0.3),
		"duration": 0.25,
		"size": Vector2(90, 12),
	},
	"vfx_upslash_arc": {
		"type": "vertical_arc",
		"color": Color(0.85, 0.92, 1.0),
		"duration": 0.2,
		"size": Vector2(50, 8),
	},
	"vfx_critical_hit": {
		"color": Color(1, 0.3, 0.1),
		"color_end": Color(1, 0.0, 0.0, 0.0),
		"amount": 20,
		"lifetime": 0.5,
		"speed": 250.0,
		"spread": 360.0,
		"gravity": Vector2(0, 60),
		"scale_min": 2.0,
		"scale_max": 5.0,
		"damping": 10,
	},
	"vfx_counter_hit": {
		"color": Color(1, 0.85, 0.0),
		"color_end": Color(1, 0.5, 0.0, 0.0),
		"amount": 24,
		"lifetime": 0.6,
		"speed": 200.0,
		"spread": 360.0,
		"gravity": Vector2(0, -20),
		"scale_min": 2.0,
		"scale_max": 4.5,
		"damping": 25,
	},
	"vfx_perfect_delete": {
		"color": Color(0, 1, 0.5),
		"color_end": Color(0.0, 0.8, 1.0, 0.0),
		"amount": 28,
		"lifetime": 0.7,
		"speed": 150.0,
		"spread": 360.0,
		"gravity": Vector2(0, -50),
		"scale_min": 2.0,
		"scale_max": 4.0,
	},
	"vfx_parry_flash": {
		"type": "ring_burst",
		"color": Color(0.3, 1.0, 0.5, 0.8),
		"color_inner": Color(1.0, 1.0, 1.0, 0.6),
		"radius": 60,
		"duration": 0.3,
	},

	# ── MAGIC / HACK EFFECTS ──────────────────────────────────────────────
	"vfx_hack_beam": {
		"type": "beam",
		"color": Color(0, 1, 0.5),
		"duration": 0.5,
		"width": 4,
	},
	"vfx_hack_circle": {
		"type": "circle",
		"color": Color(0, 1, 0.5, 0.4),
		"radius": 45,
		"duration": 0.8,
	},
	"vfx_heal_ring": {
		"color": Color(0.3, 1, 0.4),
		"color_end": Color(0.1, 0.8, 0.3, 0.0),
		"amount": 16,
		"lifetime": 0.9,
		"speed": 35.0,
		"spread": 360.0,
		"gravity": Vector2(0, -70),
		"scale_min": 2.0,
		"scale_max": 3.0,
	},
	"vfx_heal_burst": {
		"type": "ring_burst",
		"color": Color(0.3, 1.0, 0.5, 0.6),
		"color_inner": Color(0.5, 1.0, 0.7, 0.4),
		"radius": 50,
		"duration": 0.5,
	},
	"vfx_soul_absorb": {
		"color": Color(0.4, 0.5, 1.0),
		"color_end": Color(0.6, 0.7, 1.0, 0.0),
		"amount": 8,
		"lifetime": 0.5,
		"speed": 80.0,
		"spread": 360.0,
		"gravity": Vector2(0, -120),
		"scale_min": 1.5,
		"scale_max": 3.0,
	},
	"vfx_corruption_burst": {
		"color": Color(0.6, 0, 0.8),
		"color_end": Color(0.8, 0.0, 0.6, 0.0),
		"amount": 24,
		"lifetime": 0.6,
		"speed": 120.0,
		"spread": 360.0,
		"gravity": Vector2(0, 30),
		"scale_min": 2.0,
		"scale_max": 4.0,
	},
	"vfx_spell_impact": {
		"color": Color(0.5, 0.7, 1.0),
		"color_end": Color(0.3, 0.4, 1.0, 0.0),
		"amount": 16,
		"lifetime": 0.4,
		"speed": 180.0,
		"spread": 360.0,
		"gravity": Vector2(0, -30),
		"scale_min": 2.0,
		"scale_max": 4.0,
		"damping": 30,
	},
	"vfx_wraith_blast": {
		"color": Color(0.7, 0.4, 1.0),
		"color_end": Color(0.5, 0.2, 0.8, 0.0),
		"amount": 18,
		"lifetime": 0.5,
		"speed": 140.0,
		"spread": 120.0,
		"gravity": Vector2(0, -100),
		"scale_min": 2.5,
		"scale_max": 4.5,
		"direction": Vector2.UP,
	},
	"vfx_dive_impact": {
		"color": Color(1.0, 0.6, 0.2),
		"color_end": Color(0.8, 0.3, 0.0, 0.0),
		"amount": 22,
		"lifetime": 0.5,
		"speed": 200.0,
		"spread": 160.0,
		"gravity": Vector2(0, 200),
		"scale_min": 2.5,
		"scale_max": 5.0,
		"direction": Vector2(0, -1),
		"damping": 15,
	},

	# ── DEATH / DESPAWN ───────────────────────────────────────────────────
	"vfx_enemy_death": {
		"color": Color(1, 0.2, 0.2),
		"color_end": Color(0.8, 0.0, 0.0, 0.0),
		"amount": 16,
		"lifetime": 0.5,
		"speed": 100.0,
		"spread": 360.0,
		"gravity": Vector2(0, 50),
		"scale_min": 2.0,
		"scale_max": 3.5,
	},
	"vfx_enemy_death_boss": {
		"color": Color(1.0, 0.5, 0.0),
		"color_end": Color(1.0, 0.0, 0.0, 0.0),
		"amount": 40,
		"lifetime": 1.0,
		"speed": 180.0,
		"spread": 360.0,
		"gravity": Vector2(0, -20),
		"scale_min": 3.0,
		"scale_max": 6.0,
		"damping": 10,
	},
	"vfx_data_dissolve": {
		"color": Color(0, 0.8, 1),
		"color_end": Color(0.0, 0.5, 0.8, 0.0),
		"amount": 35,
		"lifetime": 1.2,
		"speed": 50.0,
		"spread": 360.0,
		"gravity": Vector2(0, -90),
		"scale_min": 1.0,
		"scale_max": 2.5,
	},
	"vfx_slime_splat": {
		"color": Color(0.3, 0.9, 0.2),
		"color_end": Color(0.2, 0.6, 0.1, 0.0),
		"amount": 14,
		"lifetime": 0.5,
		"speed": 130.0,
		"spread": 180.0,
		"gravity": Vector2(0, 350),
		"scale_min": 3.0,
		"scale_max": 7.0,
	},
	"vfx_shatter": {
		"type": "shatter",
		"color": Color(0.7, 0.8, 1.0, 0.8),
		"fragment_count": 8,
		"duration": 0.6,
	},

	# ── ENVIRONMENT ───────────────────────────────────────────────────────
	"vfx_dust_puff": {
		"color": Color(0.7, 0.65, 0.5, 0.5),
		"color_end": Color(0.6, 0.55, 0.4, 0.0),
		"amount": 8,
		"lifetime": 0.5,
		"speed": 25.0,
		"spread": 180.0,
		"gravity": Vector2(0, -15),
		"scale_min": 3.0,
		"scale_max": 7.0,
	},
	"vfx_dust_puff_heavy": {
		"color": Color(0.65, 0.6, 0.45, 0.6),
		"color_end": Color(0.5, 0.45, 0.35, 0.0),
		"amount": 14,
		"lifetime": 0.7,
		"speed": 40.0,
		"spread": 200.0,
		"gravity": Vector2(0, -20),
		"scale_min": 4.0,
		"scale_max": 9.0,
	},
	"vfx_footstep_dust": {
		"color": Color(0.6, 0.55, 0.45, 0.4),
		"amount": 4,
		"lifetime": 0.3,
		"speed": 15.0,
		"spread": 120.0,
		"gravity": Vector2(0, -5),
		"scale_min": 2.0,
		"scale_max": 4.0,
	},
	"vfx_corruption_ambient": {
		"color": Color(0.5, 0, 0.7, 0.3),
		"color_end": Color(0.6, 0.0, 0.8, 0.0),
		"amount": 5,
		"lifetime": 2.5,
		"speed": 12.0,
		"spread": 360.0,
		"gravity": Vector2(0, -25),
		"scale_min": 2.0,
		"scale_max": 5.0,
	},
	"vfx_glitch_sparkle": {
		"color": Color(0, 1, 1, 0.7),
		"color_end": Color(0.0, 0.8, 1.0, 0.0),
		"amount": 8,
		"lifetime": 0.45,
		"speed": 60.0,
		"spread": 360.0,
		"gravity": Vector2.ZERO,
		"scale_min": 1.0,
		"scale_max": 3.0,
	},
	"vfx_wall_dust": {
		"color": Color(0.6, 0.6, 0.65, 0.4),
		"amount": 5,
		"lifetime": 0.4,
		"speed": 30.0,
		"spread": 90.0,
		"gravity": Vector2(0, 30),
		"scale_min": 2.0,
		"scale_max": 4.0,
	},
	"vfx_water_splash": {
		"color": Color(0.5, 0.7, 0.9, 0.6),
		"color_end": Color(0.4, 0.6, 0.8, 0.0),
		"amount": 10,
		"lifetime": 0.5,
		"speed": 100.0,
		"spread": 140.0,
		"gravity": Vector2(0, 250),
		"scale_min": 2.0,
		"scale_max": 4.0,
		"direction": Vector2.UP,
	},

	# ── CINEMATIC / AMBIENT PARTICLES ─────────────────────────────────────
	"vfx_rain": {
		"color": Color(0.6, 0.7, 0.9, 0.5),
		"amount": 50,
		"lifetime": 1.2,
		"speed": 350.0,
		"spread": 12.0,
		"gravity": Vector2(20, 650),
		"scale_min": 1.0,
		"scale_max": 1.5,
		"direction": Vector2(0.1, 1),
		"one_shot": false,
	},
	"vfx_rain_heavy": {
		"color": Color(0.5, 0.65, 0.85, 0.6),
		"amount": 80,
		"lifetime": 1.0,
		"speed": 450.0,
		"spread": 15.0,
		"gravity": Vector2(30, 800),
		"scale_min": 1.0,
		"scale_max": 2.0,
		"direction": Vector2(0.15, 1),
		"one_shot": false,
	},
	"vfx_snow": {
		"color": Color(0.95, 0.95, 1.0, 0.7),
		"amount": 25,
		"lifetime": 5.0,
		"speed": 25.0,
		"spread": 150.0,
		"gravity": Vector2(5, 35),
		"scale_min": 2.0,
		"scale_max": 4.0,
		"one_shot": false,
	},
	"vfx_embers": {
		"color": Color(1.0, 0.5, 0.1, 0.8),
		"color_end": Color(1.0, 0.2, 0.0, 0.0),
		"amount": 14,
		"lifetime": 2.5,
		"speed": 50.0,
		"spread": 80.0,
		"gravity": Vector2(0, -90),
		"scale_min": 1.5,
		"scale_max": 3.0,
		"one_shot": false,
	},
	"vfx_fireflies": {
		"color": Color(0.85, 1.0, 0.4, 0.6),
		"color_end": Color(0.7, 0.9, 0.3, 0.0),
		"amount": 10,
		"lifetime": 4.0,
		"speed": 12.0,
		"spread": 360.0,
		"gravity": Vector2(0, -8),
		"scale_min": 2.0,
		"scale_max": 3.5,
		"one_shot": false,
	},
	"vfx_sparks": {
		"color": Color(1.0, 0.9, 0.4, 0.9),
		"color_end": Color(1.0, 0.5, 0.1, 0.0),
		"amount": 18,
		"lifetime": 0.5,
		"speed": 200.0,
		"spread": 90.0,
		"gravity": Vector2(0, 250),
		"scale_min": 1.0,
		"scale_max": 2.0,
		"damping": 5,
	},
	"vfx_mist": {
		"color": Color(0.7, 0.7, 0.8, 0.12),
		"amount": 8,
		"lifetime": 6.0,
		"speed": 6.0,
		"spread": 180.0,
		"gravity": Vector2(3, 0),
		"scale_min": 10.0,
		"scale_max": 20.0,
		"one_shot": false,
	},
	"vfx_digital_rain": {
		"color": Color(0, 1, 0.5, 0.4),
		"color_end": Color(0.0, 0.7, 0.3, 0.0),
		"amount": 30,
		"lifetime": 2.0,
		"speed": 120.0,
		"spread": 10.0,
		"gravity": Vector2(0, 180),
		"scale_min": 1.0,
		"scale_max": 2.0,
		"one_shot": false,
	},
	"vfx_leaves": {
		"color": Color(0.4, 0.7, 0.2, 0.6),
		"color_end": Color(0.6, 0.5, 0.1, 0.0),
		"amount": 6,
		"lifetime": 4.0,
		"speed": 20.0,
		"spread": 180.0,
		"gravity": Vector2(15, 25),
		"scale_min": 3.0,
		"scale_max": 6.0,
		"one_shot": false,
	},
	"vfx_energy_field": {
		"color": Color(0.3, 0.6, 1.0, 0.4),
		"color_end": Color(0.2, 0.4, 0.8, 0.0),
		"amount": 12,
		"lifetime": 1.5,
		"speed": 20.0,
		"spread": 360.0,
		"gravity": Vector2.ZERO,
		"scale_min": 2.0,
		"scale_max": 4.0,
		"one_shot": false,
	},
	"vfx_lightning_crackle": {
		"type": "lightning",
		"color": Color(0.8, 0.9, 1.0, 0.9),
		"duration": 0.15,
		"segments": 6,
		"spread": 40.0,
		"length": 120.0,
	},

	# ── SCREEN-SPACE / OVERLAY EFFECTS ────────────────────────────────────
	"vfx_screen_shockwave": {
		"type": "shockwave",
		"color": Color(1.0, 1.0, 1.0, 0.3),
		"radius": 120,
		"duration": 0.4,
	},
	"vfx_flash_white": {
		"type": "flash",
		"color": Color(1.0, 1.0, 1.0, 0.4),
		"duration": 0.12,
	},
	"vfx_flash_red": {
		"type": "flash",
		"color": Color(1.0, 0.1, 0.1, 0.3),
		"duration": 0.15,
	},
	"vfx_flash_gold": {
		"type": "flash",
		"color": Color(1.0, 0.85, 0.2, 0.35),
		"duration": 0.15,
	},
}

## Spawn an effect by name at a position, parented to given node
const MAX_ACTIVE_EFFECTS: int = 60
var _active_effect_count: int = 0

# PERF: Pre-cached scale curve shared across all particle effects (avoids per-spawn allocation)
var _cached_scale_curve: Curve = null
# PERF: Gradient cache keyed by (color_start, color_end) to avoid per-spawn Gradient+Point creation
var _gradient_cache: Dictionary = {}
# Status indicators on screen: "parent_id|text|cell" -> label instance id
var _live_indicators: Dictionary = {}

func _can_add_effect_now(parent: Node) -> bool:
	return parent and is_instance_valid(parent) and parent.is_inside_tree() and parent.is_node_ready()


func _add_effect_child(parent: Node, child: Node) -> bool:
	if not parent or not is_instance_valid(parent) or not child or not is_instance_valid(child):
		return false
	if _can_add_effect_now(parent):
		parent.add_child(child)
		return true
	parent.call_deferred("add_child", child)
	return false


func spawn(effect_name: String, pos: Vector2, parent: Node) -> Node:
	if not EFFECTS.has(effect_name):
		push_warning("VFXLibrary: Unknown effect '%s'" % effect_name)
		return null

	if not parent or not is_instance_valid(parent):
		return null

	# BUG 4 FIX: Cap active effects to prevent frame-rate collapse
	if _active_effect_count >= MAX_ACTIVE_EFFECTS:
		return null

	var config = EFFECTS[effect_name]
	var effect_type = config.get("type", "particles")

	var result: Node = null
	match effect_type:
		"particles":
			result = _spawn_particles(config, pos, parent)
		"arc":
			result = _spawn_arc(config, pos, parent)
		"vertical_arc":
			result = _spawn_vertical_arc(config, pos, parent)
		"beam":
			result = _spawn_beam(config, pos, parent)
		"circle":
			result = _spawn_circle(config, pos, parent)
		"ring_burst":
			result = _spawn_ring_burst(config, pos, parent)
		"shatter":
			result = _spawn_shatter(config, pos, parent)
		"lightning":
			result = _spawn_lightning(config, pos, parent)
		"shockwave":
			result = _spawn_shockwave(config, pos, parent)
		"flash":
			result = _spawn_flash(config, pos, parent)
		_:
			result = _spawn_particles(config, pos, parent)

	# Track active effect count for cap enforcement
	if result and is_instance_valid(result):
		_active_effect_count += 1
		result.tree_exiting.connect(func(): _active_effect_count = maxi(0, _active_effect_count - 1))
	return result

## Standard particle-based effect with richer color ramp and scale curve
func _spawn_particles(config: Dictionary, pos: Vector2, parent: Node) -> CPUParticles2D:
	var particles = CPUParticles2D.new()
	particles.position = pos
	particles.emitting = true
	particles.one_shot = config.get("one_shot", true)
	particles.explosiveness = 0.92 if particles.one_shot else 0.05
	particles.amount = config.get("amount", 8)
	particles.lifetime = config.get("lifetime", 0.5)
	particles.randomness = 0.3 if particles is GPUParticles2D else 0.0
	particles.lifetime_randomness = 0.3

	# Velocity & direction
	particles.direction = config.get("direction", Vector2.UP)
	particles.spread = config.get("spread", 180.0)
	particles.initial_velocity_min = config.get("speed", 50.0) * 0.4
	particles.initial_velocity_max = config.get("speed", 50.0)

	# Gravity
	particles.gravity = config.get("gravity", Vector2(0, 98))

	# Damping (friction / air resistance) for more natural deceleration
	if config.has("damping"):
		particles.damping_min = config["damping"] * 0.5
		particles.damping_max = config["damping"]

	# Scale with curve for polished falloff (PERF: reuse cached curve)
	particles.scale_amount_min = config.get("scale_min", 1.0)
	particles.scale_amount_max = config.get("scale_max", 2.0)
	if _cached_scale_curve == null:
		_cached_scale_curve = Curve.new()
		_cached_scale_curve.add_point(Vector2(0.0, 1.0))
		_cached_scale_curve.add_point(Vector2(0.5, 0.8))
		_cached_scale_curve.add_point(Vector2(1.0, 0.0))
	particles.scale_amount_curve = _cached_scale_curve

	# Color — rich gradient with midpoint (PERF: cache by color pair)
	var color_start: Color = config.get("color", Color.WHITE)
	var color_end: Color = config.get("color_end", Color(color_start.r, color_start.g, color_start.b, 0.0))
	var grad_key = "%s_%s" % [color_start, color_end]
	var gradient: Gradient
	if _gradient_cache.has(grad_key):
		gradient = _gradient_cache[grad_key]
	else:
		gradient = Gradient.new()
		gradient.set_color(0, color_start)
		var mid_color = color_start.lerp(color_end, 0.5)
		mid_color.a = color_start.a * 0.7
		gradient.add_point(0.6, mid_color)
		gradient.set_color(gradient.get_point_count() - 1, color_end)
		_gradient_cache[grad_key] = gradient
	particles.color_ramp = gradient

	_add_effect_child(parent, particles)

	if particles.one_shot:
		# Own tree: the parent may not be in the tree yet (deferred add above).
		# Pausable, like the particles, so a pause doesn't cut the effect short.
		var timer = get_tree().create_timer(config.get("lifetime", 0.5) + 0.3, false)
		timer.timeout.connect(func():
			if is_instance_valid(particles):
				particles.queue_free()
		)

	return particles

## Arc slash effect with inner glow
func _spawn_arc(config: Dictionary, pos: Vector2, parent: Node) -> Node2D:
	var container = Node2D.new()
	container.position = pos
	parent.add_child(container)

	var color: Color = config.get("color", Color.WHITE)
	var arc_size: Vector2 = config.get("size", Vector2(60, 8))
	var duration: float = config.get("duration", 0.2)

	# Main arc
	var arc = ColorRect.new()
	arc.color = color
	arc.size = arc_size
	arc.position = Vector2(-arc_size.x / 2, -arc_size.y / 2)
	arc.mouse_filter = Control.MOUSE_FILTER_IGNORE
	container.add_child(arc)

	# Inner glow (brighter, thinner)
	var glow = ColorRect.new()
	glow.color = Color(min(color.r + 0.3, 1.0), min(color.g + 0.3, 1.0), min(color.b + 0.3, 1.0), color.a * 0.6)
	glow.size = Vector2(arc_size.x * 0.7, arc_size.y * 0.4)
	glow.position = Vector2(-arc_size.x * 0.35, -arc_size.y * 0.2)
	glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	container.add_child(glow)

	var tween = container.create_tween()
	tween.tween_property(container, "rotation", deg_to_rad(80), duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(arc, "color:a", 0.0, duration * 0.9)
	tween.parallel().tween_property(glow, "color:a", 0.0, duration * 0.7)
	tween.parallel().tween_property(arc, "size:x", arc_size.x * 1.4, duration).set_trans(Tween.TRANS_SINE)
	tween.tween_callback(container.queue_free)

	return container

## Vertical arc for up-slashes
func _spawn_vertical_arc(config: Dictionary, pos: Vector2, parent: Node) -> Node2D:
	var container = Node2D.new()
	container.position = pos
	container.rotation = deg_to_rad(-90)
	parent.add_child(container)

	var color: Color = config.get("color", Color.WHITE)
	var arc_size: Vector2 = config.get("size", Vector2(50, 8))
	var duration: float = config.get("duration", 0.2)

	var arc = ColorRect.new()
	arc.color = color
	arc.size = arc_size
	arc.position = Vector2(-arc_size.x / 2, -arc_size.y / 2)
	arc.mouse_filter = Control.MOUSE_FILTER_IGNORE
	container.add_child(arc)

	var tween = container.create_tween()
	tween.tween_property(container, "rotation", container.rotation + deg_to_rad(70), duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(arc, "color:a", 0.0, duration * 0.9)
	tween.parallel().tween_property(arc, "size:x", arc_size.x * 1.3, duration)
	tween.tween_callback(container.queue_free)

	return container

## Beam effect with bright inner core
func _spawn_beam(config: Dictionary, pos: Vector2, parent: Node) -> ColorRect:
	var color: Color = config.get("color", Color(0, 1, 0.5))
	var width: int = config.get("width", 4)
	var duration: float = config.get("duration", 0.5)

	var beam = ColorRect.new()
	beam.color = color
	beam.size = Vector2(0, width)
	beam.position = pos - Vector2(0, float(width) / 2.0)
	beam.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(beam)

	# Inner bright core
	var core = ColorRect.new()
	core.color = Color(min(color.r + 0.4, 1.0), min(color.g + 0.4, 1.0), min(color.b + 0.4, 1.0), 0.7)
	core.size = Vector2(0, max(1, width - 2))
	core.position = Vector2(0, 1)
	core.mouse_filter = Control.MOUSE_FILTER_IGNORE
	beam.add_child(core)

	var tween = beam.create_tween()
	tween.tween_property(beam, "size:x", 220, duration * 0.3).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(core, "size:x", 200, duration * 0.3).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
	tween.tween_interval(duration * 0.35)
	tween.tween_property(beam, "color:a", 0.0, duration * 0.35)
	tween.parallel().tween_property(core, "color:a", 0.0, duration * 0.25)
	tween.tween_callback(beam.queue_free)

	return beam

## Circle expanding effect with smoother ring
func _spawn_circle(config: Dictionary, pos: Vector2, parent: Node) -> Node2D:
	var container = Node2D.new()
	container.position = pos
	parent.add_child(container)

	var radius: float = config.get("radius", 40)
	var color: Color = config.get("color", Color(0, 1, 0.5, 0.4))
	var duration: float = config.get("duration", 0.8)

	var segments = 16
	for i in range(segments):
		var angle = TAU * i / segments
		var rect = ColorRect.new()
		rect.color = color
		rect.size = Vector2(7, 3)
		rect.position = Vector2(cos(angle) * 5, sin(angle) * 5)
		rect.rotation = angle
		rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		container.add_child(rect)

	var tween = container.create_tween()
	tween.tween_property(container, "scale", Vector2(radius / 5.0, radius / 5.0), duration * 0.6).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(container, "modulate:a", 0.0, duration)
	tween.tween_callback(container.queue_free)

	return container

## Ring burst — expanding ring with inner flash (for parry, heal, shield)
func _spawn_ring_burst(config: Dictionary, pos: Vector2, parent: Node) -> Node2D:
	var container = Node2D.new()
	container.position = pos
	parent.add_child(container)

	var radius: float = config.get("radius", 60)
	var color: Color = config.get("color", Color(0.3, 1.0, 0.5, 0.8))
	var inner_color: Color = config.get("color_inner", Color(1.0, 1.0, 1.0, 0.6))
	var duration: float = config.get("duration", 0.3)

	# Outer ring segments
	var segments = 20
	for i in range(segments):
		var angle = TAU * i / segments
		var rect = ColorRect.new()
		rect.color = color
		rect.size = Vector2(8, 3)
		rect.position = Vector2(cos(angle) * 4, sin(angle) * 4)
		rect.rotation = angle
		rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		container.add_child(rect)

	# Central flash
	var flash = ColorRect.new()
	flash.color = inner_color
	flash.size = Vector2(20, 20)
	flash.position = Vector2(-10, -10)
	flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	container.add_child(flash)

	var tween = container.create_tween().set_parallel(true)
	tween.tween_property(container, "scale", Vector2(radius / 4.0, radius / 4.0), duration * 0.7).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
	tween.tween_property(container, "modulate:a", 0.0, duration)
	tween.tween_property(flash, "scale", Vector2(3.0, 3.0), duration * 0.5)
	tween.tween_property(flash, "color:a", 0.0, duration * 0.4)
	tween.chain().tween_callback(container.queue_free)

	return container

## Shatter effect — fragments fly outward (for boss death, breaking objects)
func _spawn_shatter(config: Dictionary, pos: Vector2, parent: Node) -> Node2D:
	var container = Node2D.new()
	container.position = pos
	parent.add_child(container)

	var color: Color = config.get("color", Color(0.7, 0.8, 1.0, 0.8))
	var count: int = config.get("fragment_count", 8)
	var duration: float = config.get("duration", 0.6)

	for i in range(count):
		var frag = ColorRect.new()
		var frag_size = randf_range(4, 12)
		frag.size = Vector2(frag_size, frag_size * randf_range(0.5, 1.5))
		frag.color = color.lerp(Color.WHITE, randf_range(0, 0.3))
		frag.position = Vector2(randf_range(-5, 5), randf_range(-5, 5))
		frag.rotation = randf() * TAU
		frag.mouse_filter = Control.MOUSE_FILTER_IGNORE
		container.add_child(frag)

		var angle = TAU * i / count + randf_range(-0.3, 0.3)
		var dist = randf_range(40, 100)
		var target_pos = Vector2(cos(angle) * dist, sin(angle) * dist)

		var tw = frag.create_tween().set_parallel(true)
		tw.tween_property(frag, "position", target_pos, duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tw.tween_property(frag, "rotation", frag.rotation + randf_range(-TAU, TAU), duration)
		tw.tween_property(frag, "modulate:a", 0.0, duration * 0.8).set_delay(duration * 0.2)
		tw.tween_property(frag, "scale", Vector2(0.3, 0.3), duration * 0.7).set_delay(duration * 0.3)

	var cleanup_timer = get_tree().create_timer(duration + 0.1, false)
	cleanup_timer.timeout.connect(func():
		if is_instance_valid(container):
			container.queue_free()
	)

	return container

## Lightning crackle — jagged line segments
func _spawn_lightning(config: Dictionary, pos: Vector2, parent: Node) -> Node2D:
	var container = Node2D.new()
	container.position = pos
	parent.add_child(container)

	var color: Color = config.get("color", Color(0.8, 0.9, 1.0, 0.9))
	var segments: int = config.get("segments", 6)
	var spread_val: float = config.get("spread", 40.0)
	var length: float = config.get("length", 120.0)
	var duration: float = config.get("duration", 0.15)

	var prev_pos = Vector2.ZERO
	for i in range(segments):
		var seg_length = length / segments
		var next_pos = prev_pos + Vector2(randf_range(-spread_val, spread_val), seg_length)
		var seg_dir = next_pos - prev_pos

		var seg = ColorRect.new()
		seg.color = color
		seg.size = Vector2(seg_dir.length(), 2)
		seg.position = prev_pos
		seg.rotation = seg_dir.angle()
		seg.mouse_filter = Control.MOUSE_FILTER_IGNORE
		container.add_child(seg)

		# Bright core line
		var core = ColorRect.new()
		core.color = Color(1, 1, 1, 0.8)
		core.size = Vector2(seg_dir.length(), 1)
		core.position = Vector2(0, 0.5)
		core.mouse_filter = Control.MOUSE_FILTER_IGNORE
		seg.add_child(core)

		prev_pos = next_pos

	var tween = container.create_tween()
	tween.tween_property(container, "modulate:a", 0.0, duration)
	tween.tween_callback(container.queue_free)

	return container

## Screen shockwave — delegates to ring_burst
func _spawn_shockwave(config: Dictionary, pos: Vector2, parent: Node) -> Node2D:
	return _spawn_ring_burst({
		"color": config.get("color", Color(1.0, 1.0, 1.0, 0.3)),
		"color_inner": Color(1.0, 1.0, 1.0, 0.1),
		"radius": config.get("radius", 120),
		"duration": config.get("duration", 0.4),
	}, pos, parent)

## Full-screen flash — brief white/red/gold overlay
func _spawn_flash(config: Dictionary, _pos: Vector2, parent: Node) -> Node:
	if not parent.is_inside_tree():
		return null
	var scene_root = parent.get_tree().current_scene
	if not scene_root:
		return null

	var color: Color = config.get("color", Color(1.0, 1.0, 1.0, 0.4))
	var duration: float = config.get("duration", 0.12)

	var flash = ColorRect.new()
	flash.color = color
	flash.set_anchors_preset(Control.PRESET_FULL_RECT)
	flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	flash.z_index = 95
	scene_root.add_child(flash)

	var tw = flash.create_tween()
	tw.tween_property(flash, "color:a", 0.0, duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.tween_callback(flash.queue_free)

	return flash

# =========================================================================
# CONVENIENCE TEXT SPAWNERS
# =========================================================================

## Spawn damage number with pop-in, outline, and float-up
func spawn_damage_number(value: int, pos: Vector2, parent: Node, is_critical: bool = false, color_override: Color = Color(-1,-1,-1)) -> Label:
	if not parent or not is_instance_valid(parent):
		return null

	var label = Label.new()
	label.position = pos - Vector2(20, 20)

	if color_override.r >= 0:
		label.add_theme_color_override("font_color", color_override)
	elif is_critical:
		label.add_theme_color_override("font_color", Color(1, 0.2, 0.1))
	else:
		label.add_theme_color_override("font_color", Color(1, 1, 1))

	# Outline for readability against all backgrounds
	label.add_theme_constant_override("outline_size", 3)
	label.add_theme_color_override("font_outline_color", Color(0.0, 0.0, 0.0, 0.85))

	if is_critical:
		label.add_theme_font_size_override("font_size", 28)
		label.text = str(value) + "!"
	else:
		label.add_theme_font_size_override("font_size", 20)
		label.text = str(value)

	parent.add_child(label)

	# Pop-in scale
	label.scale = Vector2(0.3, 0.3)
	label.pivot_offset = Vector2(20, 20)
	var pop_tween = label.create_tween()
	pop_tween.tween_property(label, "scale", Vector2(1.15, 1.15), 0.08).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	pop_tween.tween_property(label, "scale", Vector2(1.0, 1.0), 0.06).set_trans(Tween.TRANS_SINE)

	# Float up with arc + smooth fade
	var tween = label.create_tween()
	tween.set_parallel(true)
	var drift_x = randf_range(-18, 18)
	tween.tween_property(label, "position:y", pos.y - 70, 0.9).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(label, "position:x", label.position.x + drift_x, 0.9).set_trans(Tween.TRANS_SINE)
	tween.tween_property(label, "modulate:a", 0.0, 0.5).set_delay(0.45).set_trans(Tween.TRANS_SINE)
	if is_critical:
		pop_tween.kill()
		var crit_tween = label.create_tween()
		crit_tween.tween_property(label, "scale", Vector2(1.6, 1.6), 0.1).set_trans(Tween.TRANS_BACK)
		crit_tween.tween_property(label, "scale", Vector2(1.0, 1.0), 0.25).set_trans(Tween.TRANS_ELASTIC)
	tween.chain().tween_callback(label.queue_free)

	return label

## Spawn gold/XP pickup text with pop-in
func spawn_pickup_text(text: String, pos: Vector2, parent: Node, color: Color = Color(1, 0.85, 0.1)) -> Label:
	if not parent or not is_instance_valid(parent):
		return null

	var label = Label.new()
	label.text = text
	label.position = pos - Vector2(30, 10)
	label.add_theme_color_override("font_color", color)
	label.add_theme_font_size_override("font_size", 16)
	label.add_theme_constant_override("outline_size", 2)
	label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.7))
	parent.add_child(label)

	label.scale = Vector2(0.5, 0.5)
	label.pivot_offset = Vector2(30, 10)
	var pop = label.create_tween()
	pop.tween_property(label, "scale", Vector2(1.1, 1.1), 0.1).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	pop.tween_property(label, "scale", Vector2(1.0, 1.0), 0.08)

	var tween = label.create_tween()
	tween.tween_property(label, "position:y", pos.y - 45, 0.7).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(label, "modulate:a", 0.0, 0.6).set_delay(0.15)
	tween.tween_callback(label.queue_free)

	return label

## Spawn a buff/debuff indicator with pop-in and outline
func spawn_status_indicator(text: String, pos: Vector2, parent: Node, is_buff: bool = true) -> Label:
	if not parent or not is_instance_valid(parent):
		return null

	var label = Label.new()
	label.text = text
	label.position = pos - Vector2(40, 30)
	var color = Color(0.3, 1, 0.5) if is_buff else Color(1, 0.3, 0.3)
	label.add_theme_color_override("font_color", color)
	label.add_theme_font_size_override("font_size", 14)
	label.add_theme_constant_override("outline_size", 2)
	label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.7))

	# Same text at the same spot (save-button spam, repeated alerts) replaces the
	# copy still on screen instead of stacking unreadable duplicates.
	var key: String = "%d|%s|%s" % [parent.get_instance_id(), text, Vector2i((pos / 16.0).round())]
	var prev_id: int = _live_indicators.get(key, 0)
	var prev = instance_from_id(prev_id) if prev_id != 0 else null
	if prev is Node and not prev.is_queued_for_deletion():
		prev.queue_free()
	var label_id: int = label.get_instance_id()
	_live_indicators[key] = label_id
	label.tree_exiting.connect(func():
		if _live_indicators.get(key, 0) == label_id:
			_live_indicators.erase(key)
	)

	var animate_label = func() -> void:
		if not is_instance_valid(label):
			return
		label.scale = Vector2(0.4, 0.4)
		label.pivot_offset = Vector2(40, 15)
		var tween = label.create_tween()
		tween.tween_property(label, "scale", Vector2(1.15, 1.15), 0.1).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tween.tween_property(label, "scale", Vector2(1.0, 1.0), 0.08).set_trans(Tween.TRANS_SINE)
		tween.tween_property(label, "position:y", pos.y - 60, 1.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		tween.parallel().tween_property(label, "modulate:a", 0.0, 0.6).set_delay(0.45).set_trans(Tween.TRANS_SINE)
		tween.tween_callback(label.queue_free)

	if _add_effect_child(parent, label):
		animate_label.call()
	else:
		label.ready.connect(animate_label, CONNECT_ONE_SHOT)

	return label

## Spawn a stylized announcement text (for kills, achievements, milestones)
func spawn_announcement(text: String, pos: Vector2, parent: Node, color: Color = Color(1, 0.85, 0.2), font_size: int = 24) -> Label:
	if not parent or not is_instance_valid(parent):
		return null

	var label = Label.new()
	label.text = text
	label.position = pos - Vector2(60, 15)
	label.add_theme_color_override("font_color", color)
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_constant_override("outline_size", 4)
	label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.85))
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	parent.add_child(label)

	# Dramatic pop-in
	label.scale = Vector2(0.1, 0.1)
	label.pivot_offset = Vector2(60, 15)
	label.modulate.a = 0.0
	var tween = label.create_tween()
	tween.tween_property(label, "scale", Vector2(1.3, 1.3), 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(label, "modulate:a", 1.0, 0.08)
	tween.tween_property(label, "scale", Vector2(1.0, 1.0), 0.2).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	tween.tween_interval(0.8)
	tween.tween_property(label, "position:y", label.position.y - 30, 0.5).set_trans(Tween.TRANS_SINE)
	tween.parallel().tween_property(label, "modulate:a", 0.0, 0.4)
	tween.tween_callback(label.queue_free)

	return label
