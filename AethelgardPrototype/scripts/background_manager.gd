extends Node

## BackgroundManager — Procedural placeholder backgrounds per location
## Generates rich gradient-based multi-layer environments with atmosphere
## Auto-upgrades to real PNG assets when dropped into assets/backgrounds/

# ── Asset paths for real backgrounds (when available) ──
const BG_ASSETS = {
	# Prologue
	"plane_interior": "res://assets/backgrounds/prologue/bg_plane_interior_base.png",
	"plane_glitch1": "res://assets/backgrounds/prologue/bg_plane_interior_glitch1.png",
	"plane_glitch2": "res://assets/backgrounds/prologue/bg_plane_interior_glitch2.png",
	"plane_glitch3": "res://assets/backgrounds/prologue/bg_plane_interior_glitch3.png",
	"plane_glitch4": "res://assets/backgrounds/prologue/bg_plane_interior_glitch4.png",
	"night_sky": "res://assets/backgrounds/prologue/bg_plane_window_sky.png",
	"crash_sequence": "res://assets/backgrounds/prologue/bg_crash_sequence.png",
	"bsod": "res://assets/backgrounds/prologue/bg_bsod.png",
	"boot_screen": "res://assets/backgrounds/prologue/bg_boot_screen.png",
	# Chapter 1
	"glitch_crater_sky": "res://assets/backgrounds/chapter1/bg_crater_sky.png",
	"glitch_crater_ground": "res://assets/backgrounds/chapter1/bg_crater_ground.png",
	"forest_twilight": "res://assets/backgrounds/chapter1/bg_forest_twilight.png",
	"oakhaven_sky": "res://assets/backgrounds/chapter1/bg_oakhaven_sky.png",
	"oakhaven_buildings_far": "res://assets/backgrounds/chapter1/bg_oakhaven_buildings_far.png",
	"oakhaven_buildings_near": "res://assets/backgrounds/chapter1/bg_oakhaven_buildings_near.png",
	"oakhaven_ground": "res://assets/backgrounds/chapter1/bg_oakhaven_ground.png",
	"tutorial_arena": "res://assets/backgrounds/chapter1/bg_arena_tutorial.png",
	"shatter_bridge": "res://assets/backgrounds/chapter1/bg_shatter_bridge.png",
	# Chapter 2
	"ironhold_sky": "res://assets/backgrounds/chapter2/bg_ironhold_sky.png",
	"ironhold_industrial": "res://assets/backgrounds/chapter2/bg_ironhold_industrial.png",
	"ironhold_market": "res://assets/backgrounds/chapter2/bg_ironhold_market.png",
	"ironhold_arena": "res://assets/backgrounds/chapter2/bg_ironhold_arena.png",
	"ironhold_clock_tower": "res://assets/backgrounds/chapter2/bg_ironhold_clock_tower.png",
	"underground": "res://assets/backgrounds/chapter2/bg_underground.png",
	"admin_boss_arena": "res://assets/backgrounds/chapter2/bg_admin_boss_arena.png",
	# Overlays
	"scanlines": "res://assets/backgrounds/overlays/bg_overlay_scanlines.png",
	"static_noise": "res://assets/backgrounds/overlays/bg_overlay_static.png",
	"rain": "res://assets/backgrounds/weather/bg_weather_rain.png",
	"fog": "res://assets/backgrounds/weather/bg_weather_fog.png",
}

# ── Color palettes per area ──
const PALETTE = {
	"prologue": {
		"seat_blue": Color(0.17, 0.30, 0.42),
		"interior_white": Color(0.91, 0.91, 0.91),
		"emergency_blue": Color(0.29, 0.565, 0.886),
		"night": Color(0.10, 0.10, 0.10),
		"cyan": Color(0.0, 1.0, 1.0),
		"sky_dark": Color(0.04, 0.04, 0.10),
		"sky_mid": Color(0.10, 0.10, 0.16),
	},
	"oakhaven": {
		"wood": Color(0.36, 0.25, 0.20),
		"grass": Color(0.29, 0.545, 0.29),
		"thatch": Color(0.545, 0.451, 0.333),
		"sky_top": Color(0.529, 0.808, 0.922),
		"sky_bottom": Color(0.69, 0.878, 0.902),
		"stone": Color(0.502, 0.502, 0.502),
		"flower_red": Color(0.8, 0.2, 0.2),
		"flower_yellow": Color(0.9, 0.8, 0.3),
	},
	"ironhold": {
		"copper": Color(0.722, 0.451, 0.20),
		"rust": Color(0.545, 0.271, 0.075),
		"brass": Color(1.0, 0.843, 0.0),
		"metal": Color(0.44, 0.50, 0.565),
		"cyan_glow": Color(0.0, 1.0, 1.0),
		"sky_top": Color(1.0, 0.549, 0.259),
		"sky_bottom": Color(0.4, 0.2, 0.35),
		"smoke": Color(0.3, 0.3, 0.35, 0.6),
	},
	"combat": {
		"stone_light": Color(0.353, 0.353, 0.353),
		"stone_dark": Color(0.227, 0.227, 0.227),
		"spotlight": Color(1.0, 0.843, 0.0),
		"iron": Color(0.44, 0.50, 0.565),
		"warning": Color(1.0, 0.267, 0.267),
	},
	"crater": {
		"sky": Color(0.15, 0.08, 0.25),
		"nebula": Color(0.22, 0.10, 0.35),
		"ground": Color(0.14, 0.09, 0.20),
		"glow": Color(0.0, 1.0, 1.0),
		"grass": Color(0.227, 0.49, 0.227),
		"dirt": Color(0.42, 0.267, 0.137),
	},
	"forest": {
		"sky": Color(0.15, 0.10, 0.25),
		"canopy_dark": Color(0.176, 0.314, 0.086),
		"canopy_mid": Color(0.239, 0.42, 0.122),
		"trunk": Color(0.36, 0.25, 0.20),
		"path": Color(0.45, 0.35, 0.22),
		"firefly": Color(1.0, 0.95, 0.5),
	},
}

var _viewport_size = Vector2(1280, 720)

func _ready() -> void:
	print("[BackgroundManager] Initialized — procedural backgrounds active")
	_viewport_size = Vector2(
		ProjectSettings.get_setting("display/window/size/viewport_width", 1280),
		ProjectSettings.get_setting("display/window/size/viewport_height", 720)
	)

# =====================================================================
# PUBLIC API — Call from any scene script
# =====================================================================

func has_real_asset(bg_key: String) -> bool:
	## Check if a real background PNG exists for this location
	if bg_key in BG_ASSETS:
		return FileAccess.file_exists(BG_ASSETS[bg_key])
	return false

func get_real_texture(bg_key: String) -> Texture2D:
	## Load a real background texture if available
	if has_real_asset(bg_key):
		return load(BG_ASSETS[bg_key])
	return null

func create_background(location: String, parent: Node = null) -> Control:
	## Create a complete multi-layer background for a location.
	## If real assets exist, uses those. Otherwise generates procedural placeholders.
	## Supported locations:
	## plane_interior, night_sky, bsod, boot_screen, crash_sequence,
	## glitch_crater, forest_twilight, oakhaven, tutorial_arena,
	## shatter_bridge, ironhold_sky, ironhold_city, ironhold_market,
	## ironhold_arena, ironhold_clock_tower, underground,
	## admin_boss_arena, chapter_end
	var bg: Control
	
	# Check for real asset first
	if has_real_asset(location):
		bg = _make_real_bg(location)
	else:
		bg = _generate_procedural(location)
	
	if parent and bg:
		parent.add_child(bg)
		parent.move_child(bg, 0)

	return bg


func change_background(location: String, parent: Node = null) -> Control:
	## Swap the active generated background for a new location.
	## Unlike create_background(), this removes any background this manager
	## previously created under `parent`, so repeated calls (e.g. one per
	## cutscene beat) don't stack layers on top of each other.
	##
	## Called by cutscene_manager.handle_background() for
	## {"type": "background", "scene": "<location>"} beats.
	if parent == null:
		parent = get_tree().current_scene
	if parent == null:
		push_warning("[BG] change_background('%s'): no parent scene available" % location)
		return null
	for child in parent.get_children():
		if child is Control and str(child.name).begins_with("Background_"):
			child.queue_free()
	return create_background(location, parent)

# =====================================================================
# REAL ASSET LOADER
# =====================================================================

func _make_real_bg(bg_key: String) -> Control:
	var container = Control.new()
	container.name = "Background_" + bg_key
	container.set_anchors_preset(Control.PRESET_FULL_RECT)
	container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	var tex_rect = TextureRect.new()
	tex_rect.texture = load(BG_ASSETS[bg_key])
	tex_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	tex_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	tex_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	container.add_child(tex_rect)
	return container

# =====================================================================
# PROCEDURAL GENERATORS
# =====================================================================

func _generate_procedural(location: String) -> Control:
	match location:
		"plane_interior":
			return _gen_plane_interior()
		"night_sky":
			return _gen_night_sky()
		"bsod":
			return _gen_bsod()
		"boot_screen":
			return _gen_boot_screen()
		"crash_sequence":
			return _gen_crash_bg()
		"glitch_crater":
			return _gen_glitch_crater()
		"forest_twilight":
			return _gen_forest()
		"oakhaven":
			return _gen_oakhaven()
		"tutorial_arena":
			return _gen_tutorial_arena()
		"shatter_bridge":
			return _gen_shatter_bridge()
		"ironhold_sky":
			return _gen_ironhold_sky()
		"ironhold_city", "ironhold_market":
			return _gen_ironhold_city()
		"ironhold_arena":
			return _gen_ironhold_arena()
		"ironhold_clock_tower":
			return _gen_ironhold_clock_tower()
		"underground":
			return _gen_underground()
		"admin_boss_arena":
			return _gen_admin_boss()
		"chapter_end":
			return _gen_chapter_end()
		"wasteland":
			return _gen_wasteland()
		"archive":
			return _gen_archive()
		"data_stream":
			return _gen_data_stream()
		_:
			push_warning("[BackgroundManager] Unknown location: " + location)
			return _gen_fallback(location)

# ── Helpers ──

func _new_container(loc_name: String) -> Control:
	var c = Control.new()
	c.name = "Background_" + loc_name
	c.set_anchors_preset(Control.PRESET_FULL_RECT)
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return c

func _add_rect(parent: Control, color: Color, pos: Vector2, sz: Vector2) -> ColorRect:
	var r = ColorRect.new()
	r.color = color
	r.position = pos
	r.size = sz
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(r)
	return r

func _add_fullscreen(parent: Control, color: Color) -> ColorRect:
	var r = ColorRect.new()
	r.color = color
	r.set_anchors_preset(Control.PRESET_FULL_RECT)
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(r)
	return r

func _add_gradient_v(parent: Control, top_color: Color, bottom_color: Color, pos := Vector2.ZERO, sz := Vector2.ZERO) -> TextureRect:
	## Add a vertical gradient (top_color at top → bottom_color at bottom)
	var size = sz if sz != Vector2.ZERO else _viewport_size
	var grad = Gradient.new()
	grad.set_color(0, top_color)
	grad.set_color(1, bottom_color)
	var tex = GradientTexture2D.new()
	tex.gradient = grad
	tex.width = int(size.x)
	tex.height = int(size.y)
	tex.fill_from = Vector2(0.5, 0.0)
	tex.fill_to = Vector2(0.5, 1.0)
	var tex_rect = TextureRect.new()
	tex_rect.texture = tex
	tex_rect.position = pos
	tex_rect.size = size
	tex_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(tex_rect)
	return tex_rect

func _add_stars(parent: Control, count: int, area: Rect2, twinkle := true) -> void:
	for i in range(count):
		var star = ColorRect.new()
		star.size = Vector2(2, 2) if randf() > 0.3 else Vector2(3, 3)
		star.color = Color(0.8, 0.85, 1.0, randf_range(0.3, 0.9))
		star.position = Vector2(
			randf_range(area.position.x, area.end.x),
			randf_range(area.position.y, area.end.y)
		)
		star.mouse_filter = Control.MOUSE_FILTER_IGNORE
		parent.add_child(star)
		if twinkle:
			var tw = parent.create_tween().set_loops()
			tw.tween_property(star, "modulate:a", randf_range(0.2, 0.5), randf_range(1.5, 4.0)).set_delay(randf_range(0, 3))
			tw.tween_property(star, "modulate:a", 1.0, randf_range(1.5, 4.0))

func _add_vignette(parent: Control) -> void:
	## Add top and bottom vignettes for cinematic feel
	var top = ColorRect.new()
	top.color = Color(0, 0, 0, 0.5)
	top.size = Vector2(_viewport_size.x, 60)
	top.position = Vector2.ZERO
	top.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(top)
	
	var bottom = ColorRect.new()
	bottom.color = Color(0, 0, 0, 0.5)
	bottom.size = Vector2(_viewport_size.x, 60)
	bottom.position = Vector2(0, _viewport_size.y - 60)
	bottom.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(bottom)

func _add_floating_particles(parent: Control, count: int, area: Rect2, color: Color, speed_range := Vector2(20, 60)) -> void:
	## Add gently floating particles in an area
	for i in range(count):
		var p = ColorRect.new()
		p.size = Vector2(3, 3) if randf() > 0.5 else Vector2(2, 2)
		p.color = color
		p.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var start_pos = Vector2(
			randf_range(area.position.x, area.end.x),
			randf_range(area.position.y, area.end.y)
		)
		p.position = start_pos
		parent.add_child(p)
		
		var tw = parent.create_tween().set_loops()
		var drift_y = randf_range(-speed_range.y, -speed_range.x)
		var drift_x = randf_range(-15, 15)
		tw.tween_property(p, "position", start_pos + Vector2(drift_x, drift_y), randf_range(3, 7)).set_trans(Tween.TRANS_SINE)
		tw.tween_property(p, "position", start_pos, randf_range(3, 7)).set_trans(Tween.TRANS_SINE)
		
		var alpha_tw = parent.create_tween().set_loops()
		alpha_tw.tween_property(p, "modulate:a", randf_range(0.2, 0.5), randf_range(1.5, 3.0))
		alpha_tw.tween_property(p, "modulate:a", 1.0, randf_range(1.5, 3.0))

# =====================================================================
# LOCATION GENERATORS
# =====================================================================

# ── PROLOGUE: Plane Interior ──
func _gen_plane_interior() -> Control:
	var c = _new_container("plane_interior")
	var pal = PALETTE["prologue"]
	
	# Cabin interior base (dark blue-gray)
	_add_gradient_v(c, pal["seat_blue"].darkened(0.3), pal["seat_blue"].darkened(0.5))
	
	# Ceiling
	_add_rect(c, pal["interior_white"].darkened(0.2), Vector2.ZERO, Vector2(_viewport_size.x, 80))
	
	# Overhead bins (left and right)
	_add_rect(c, pal["interior_white"].darkened(0.35), Vector2(50, 80), Vector2(400, 50))
	_add_rect(c, pal["interior_white"].darkened(0.35), Vector2(_viewport_size.x - 450, 80), Vector2(400, 50))
	
	# Aisle floor
	_add_rect(c, Color(0.29, 0.29, 0.36), Vector2(_viewport_size.x / 2 - 60, 400), Vector2(120, _viewport_size.y - 400))
	
	# Seat rows (left side)
	for row in range(4):
		var y = 200 + row * 120
		_add_rect(c, pal["seat_blue"], Vector2(80, y), Vector2(180, 80))
		_add_rect(c, pal["seat_blue"].lightened(0.1), Vector2(270, y), Vector2(180, 80))
		# Seat backs
		_add_rect(c, pal["seat_blue"].darkened(0.15), Vector2(80, y - 15), Vector2(370, 15))
	
	# Seat rows (right side)
	for row in range(4):
		var y = 200 + row * 120
		_add_rect(c, pal["seat_blue"], Vector2(_viewport_size.x - 450, y), Vector2(180, 80))
		_add_rect(c, pal["seat_blue"].lightened(0.1), Vector2(_viewport_size.x - 260, y), Vector2(180, 80))
		_add_rect(c, pal["seat_blue"].darkened(0.15), Vector2(_viewport_size.x - 450, y - 15), Vector2(370, 15))
	
	# Windows (small, left side)
	for i in range(4):
		var y = 150 + i * 120
		_add_rect(c, pal["sky_dark"], Vector2(15, y), Vector2(30, 40))
		# Window frame
		_add_rect(c, pal["interior_white"].darkened(0.4), Vector2(13, y - 2), Vector2(34, 2))
		_add_rect(c, pal["interior_white"].darkened(0.4), Vector2(13, y + 40), Vector2(34, 2))
	
	# Emergency lighting (blue strip along ceiling)
	var light_strip = _add_rect(c, pal["emergency_blue"], Vector2(0, 75), Vector2(_viewport_size.x, 5))
	light_strip.modulate.a = 0.7
	var lw = c.create_tween().set_loops()
	lw.tween_property(light_strip, "modulate:a", 0.3, 2.0).set_trans(Tween.TRANS_SINE)
	lw.tween_property(light_strip, "modulate:a", 0.9, 2.0).set_trans(Tween.TRANS_SINE)
	
	_add_vignette(c)
	return c

# ── PROLOGUE: Night Sky (through window) ──
func _gen_night_sky() -> Control:
	var c = _new_container("night_sky")
	var pal = PALETTE["prologue"]
	
	_add_gradient_v(c, pal["sky_dark"], pal["sky_mid"])
	_add_stars(c, 40, Rect2(0, 0, _viewport_size.x, _viewport_size.y * 0.7))
	
	# Moon
	var moon = ColorRect.new()
	moon.color = Color(0.95, 0.93, 0.7, 0.9)
	moon.size = Vector2(32, 32)
	moon.position = Vector2(_viewport_size.x * 0.75, 60)
	moon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	c.add_child(moon)
	
	# Cloud layer at bottom
	for i in range(6):
		var cloud = ColorRect.new()
		cloud.color = Color(0.7, 0.7, 0.8, randf_range(0.1, 0.25))
		cloud.size = Vector2(randf_range(100, 250), randf_range(20, 40))
		cloud.position = Vector2(randf_range(-50, _viewport_size.x), _viewport_size.y * 0.7 + randf_range(0, 80))
		cloud.mouse_filter = Control.MOUSE_FILTER_IGNORE
		c.add_child(cloud)
		# Drift
		var tw = c.create_tween().set_loops()
		tw.tween_property(cloud, "position:x", cloud.position.x + randf_range(30, 80), randf_range(15, 30))
		tw.tween_property(cloud, "position:x", cloud.position.x, randf_range(15, 30))
	
	return c

# ── PROLOGUE: BSOD ──
func _gen_bsod() -> Control:
	var c = _new_container("bsod")
	_add_fullscreen(c, Color(0.0, 0.0, 0.667))  # Classic BSOD blue #0000AA
	
	var text = Label.new()
	text.text = "*** STOP: 0x0000007E\nREALITY.DLL - Address 0x004F3A\nBeginning dump of physical memory...\nContact your System Administrator."
	text.add_theme_font_size_override("font_size", 18)
	text.add_theme_color_override("font_color", Color.WHITE)
	text.position = Vector2(100, 200)
	text.mouse_filter = Control.MOUSE_FILTER_IGNORE
	c.add_child(text)
	
	# Scanline effect — use fewer, thicker lines to reduce node count (was 180 nodes)
	for i in range(0, int(_viewport_size.y), 16):
		var line = ColorRect.new()
		line.color = Color(0, 0, 0, 0.12)
		line.size = Vector2(_viewport_size.x, 2)
		line.position = Vector2(0, i)
		line.mouse_filter = Control.MOUSE_FILTER_IGNORE
		c.add_child(line)
	
	return c

# ── PROLOGUE: Boot Screen ──
func _gen_boot_screen() -> Control:
	var c = _new_container("boot_screen")
	_add_fullscreen(c, Color(0.04, 0.04, 0.04))
	
	# Cursor blink
	var cursor = ColorRect.new()
	cursor.color = Color(0, 1, 0)  # Green terminal
	cursor.size = Vector2(10, 16)
	cursor.position = Vector2(40, 40)
	cursor.mouse_filter = Control.MOUSE_FILTER_IGNORE
	c.add_child(cursor)
	var tw = c.create_tween().set_loops()
	tw.tween_property(cursor, "modulate:a", 0.0, 0.5)
	tw.tween_property(cursor, "modulate:a", 1.0, 0.5)
	
	return c

# ── PROLOGUE: Crash sequence ──
func _gen_crash_bg() -> Control:
	var c = _new_container("crash_sequence")
	_add_gradient_v(c, Color(0.05, 0.05, 0.1), Color(0.02, 0.02, 0.05))
	
	# Streaked motion blur lines
	for i in range(12):
		var streak = ColorRect.new()
		streak.color = Color(0.5, 0.5, 0.6, randf_range(0.05, 0.15))
		streak.size = Vector2(_viewport_size.x, randf_range(2, 6))
		streak.position = Vector2(0, randf_range(0, _viewport_size.y))
		streak.mouse_filter = Control.MOUSE_FILTER_IGNORE
		c.add_child(streak)
	
	return c

# ── CHAPTER 1: Glitch Crater ──
func _gen_glitch_crater() -> Control:
	var c = _new_container("glitch_crater")
	var pal = PALETTE["crater"]
	
	# Sky
	_add_gradient_v(c, pal["sky"], pal["nebula"], Vector2.ZERO, Vector2(_viewport_size.x, _viewport_size.y * 0.55))
	
	# Nebula glow
	var nebula = _add_rect(c, Color(pal["nebula"].r, pal["nebula"].g, pal["nebula"].b, 0.4), Vector2(0, 0), Vector2(_viewport_size.x, 180))
	var ntw = c.create_tween().set_loops()
	ntw.tween_property(nebula, "modulate:a", 0.3, 3.0).set_trans(Tween.TRANS_SINE)
	ntw.tween_property(nebula, "modulate:a", 1.0, 3.0).set_trans(Tween.TRANS_SINE)
	
	_add_stars(c, 30, Rect2(0, 0, _viewport_size.x, _viewport_size.y * 0.5))
	
	# Ground
	_add_rect(c, pal["ground"], Vector2(0, _viewport_size.y * 0.55), Vector2(_viewport_size.x, _viewport_size.y * 0.45))
	
	# Grass patches
	for i in range(8):
		_add_rect(c, pal["grass"].darkened(randf_range(0, 0.3)),
			Vector2(randf_range(0, _viewport_size.x - 80), _viewport_size.y * 0.52 + randf_range(0, 20)),
			Vector2(randf_range(40, 100), randf_range(6, 12)))
	
	# Crater depression
	_add_rect(c, pal["dirt"], Vector2(_viewport_size.x * 0.3, _viewport_size.y * 0.6), Vector2(_viewport_size.x * 0.4, 50))
	_add_rect(c, pal["dirt"].darkened(0.3), Vector2(_viewport_size.x * 0.35, _viewport_size.y * 0.62), Vector2(_viewport_size.x * 0.3, 30))
	
	# Horizon glow
	var horizon = _add_rect(c, Color(pal["glow"].r, pal["glow"].g, pal["glow"].b, 0.2),
		Vector2(0, _viewport_size.y * 0.53), Vector2(_viewport_size.x, 12))
	var hw = c.create_tween().set_loops()
	hw.tween_property(horizon, "modulate:a", 0.3, 2.5).set_trans(Tween.TRANS_SINE)
	hw.tween_property(horizon, "modulate:a", 1.0, 2.5).set_trans(Tween.TRANS_SINE)
	
	# Floating particles
	_add_floating_particles(c, 8, Rect2(_viewport_size.x * 0.2, _viewport_size.y * 0.3, _viewport_size.x * 0.6, _viewport_size.y * 0.4), pal["glow"])
	
	_add_vignette(c)
	return c

# ── CHAPTER 1: Forest Twilight ──
func _gen_forest() -> Control:
	var c = _new_container("forest_twilight")
	var pal = PALETTE["forest"]
	
	# Twilight sky
	_add_gradient_v(c, pal["sky"], Color(0.2, 0.12, 0.3), Vector2.ZERO, Vector2(_viewport_size.x, _viewport_size.y * 0.5))
	
	_add_stars(c, 15, Rect2(0, 0, _viewport_size.x, _viewport_size.y * 0.35))
	
	# Far treeline silhouette
	for i in range(10):
		var x = i * (_viewport_size.x / 10) + randf_range(-20, 20)
		var h = randf_range(120, 200)
		_add_rect(c, pal["canopy_dark"].darkened(0.4), Vector2(x, _viewport_size.y * 0.35 - h * 0.3), Vector2(randf_range(60, 100), h))
	
	# Ground
	_add_rect(c, Color(0.12, 0.08, 0.06), Vector2(0, _viewport_size.y * 0.65), Vector2(_viewport_size.x, _viewport_size.y * 0.35))
	
	# Path
	_add_rect(c, pal["path"], Vector2(_viewport_size.x * 0.3, _viewport_size.y * 0.7), Vector2(_viewport_size.x * 0.4, 30))
	
	# Near trees (trunks + canopy)
	for i in range(6):
		var x = randf_range(0, _viewport_size.x)
		if x > _viewport_size.x * 0.35 and x < _viewport_size.x * 0.65:
			continue  # Keep path clear
		var trunk_h = randf_range(150, 250)
		var base_y = _viewport_size.y * 0.7
		_add_rect(c, pal["trunk"], Vector2(x, base_y - trunk_h), Vector2(16, trunk_h))
		_add_rect(c, pal["canopy_mid"], Vector2(x - 30, base_y - trunk_h - 40), Vector2(76, 50))
		_add_rect(c, pal["canopy_dark"], Vector2(x - 20, base_y - trunk_h - 30), Vector2(56, 35))
	
	# Fireflies
	_add_floating_particles(c, 10, Rect2(0, _viewport_size.y * 0.3, _viewport_size.x, _viewport_size.y * 0.4), pal["firefly"], Vector2(10, 30))
	
	# Kenney tile overlay: dirt path and grass on forest floor
	_add_kenney_tile_strip(c, "bg_tile_dirt", _viewport_size.y * 0.65, 3, Color(0.5, 0.4, 0.3), 0.3)
	_add_kenney_tile_strip(c, "bg_tile_grass", _viewport_size.y * 0.7, 1, Color(0.3, 0.5, 0.3), 0.3)
	_add_kenney_scatter(c, ["bg_tile_wood", "bg_tile_ground"], Rect2(0, _viewport_size.y * 0.6, _viewport_size.x, 60), 4, Vector2(0.6, 1.0), 0.25)
	
	_add_vignette(c)
	return c

# ── CHAPTER 1: Oakhaven ──
func _gen_oakhaven() -> Control:
	var c = _new_container("oakhaven")
	var pal = PALETTE["oakhaven"]
	
	# Sky gradient
	_add_gradient_v(c, pal["sky_top"], pal["sky_bottom"], Vector2.ZERO, Vector2(_viewport_size.x, _viewport_size.y * 0.45))
	
	# Clouds
	for i in range(5):
		var cloud = ColorRect.new()
		cloud.color = Color(1, 1, 1, randf_range(0.3, 0.6))
		cloud.size = Vector2(randf_range(80, 180), randf_range(20, 35))
		cloud.position = Vector2(randf_range(0, _viewport_size.x), randf_range(30, 150))
		cloud.mouse_filter = Control.MOUSE_FILTER_IGNORE
		c.add_child(cloud)
		var tw = c.create_tween().set_loops()
		tw.tween_property(cloud, "position:x", cloud.position.x + randf_range(20, 60), randf_range(20, 40))
		tw.tween_property(cloud, "position:x", cloud.position.x, randf_range(20, 40))
	
	# Distant mountains (silhouettes)
	for i in range(3):
		var mtn = ColorRect.new()
		mtn.color = Color(0.5, 0.5, 0.6, 0.4)
		var w = randf_range(300, 500)
		var h = randf_range(80, 140)
		mtn.size = Vector2(w, h)
		mtn.position = Vector2(i * 450 + randf_range(-50, 50), _viewport_size.y * 0.35 - h * 0.5)
		mtn.mouse_filter = Control.MOUSE_FILTER_IGNORE
		c.add_child(mtn)
	
	# Far buildings
	var building_data = [
		{"x": 100, "w": 120, "h": 160, "roof_h": 30},
		{"x": 350, "w": 100, "h": 130, "roof_h": 25},
		{"x": 550, "w": 140, "h": 180, "roof_h": 35},
		{"x": 800, "w": 110, "h": 140, "roof_h": 28},
		{"x": 1000, "w": 130, "h": 155, "roof_h": 32},
	]
	var ground_y = _viewport_size.y * 0.55
	for bd in building_data:
		# Stone walls
		_add_rect(c, pal["stone"].darkened(randf_range(0, 0.15)),
			Vector2(bd["x"], ground_y - bd["h"]),
			Vector2(bd["w"], bd["h"]))
		# Roof (thatch)
		_add_rect(c, pal["thatch"],
			Vector2(bd["x"] - 10, ground_y - bd["h"] - bd["roof_h"]),
			Vector2(bd["w"] + 20, bd["roof_h"]))
		# Windows
		for wi in range(2):
			_add_rect(c, Color(0.9, 0.85, 0.5, 0.7),
				Vector2(bd["x"] + 15 + wi * 50, ground_y - bd["h"] + 30),
				Vector2(20, 25))
		# Door
		_add_rect(c, pal["wood"].darkened(0.2),
			Vector2(bd["x"] + bd["w"] / 2 - 12, ground_y - 50),
			Vector2(24, 50))
	
	# Ground (cobblestone path + grass)
	_add_rect(c, pal["grass"], Vector2(0, ground_y), Vector2(_viewport_size.x, _viewport_size.y - ground_y))
	_add_rect(c, pal["stone"].lightened(0.1), Vector2(0, ground_y + 10), Vector2(_viewport_size.x, 40))
	
	# Flowers
	for i in range(12):
		var fl = ColorRect.new()
		fl.color = [pal["flower_red"], pal["flower_yellow"]][randi() % 2]
		fl.size = Vector2(4, 4)
		fl.position = Vector2(randf_range(0, _viewport_size.x), ground_y + randf_range(55, _viewport_size.y - ground_y - 20))
		fl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		c.add_child(fl)
	
	# Kenney tile overlay: grass ground strip and scattered items
	_add_kenney_tile_strip(c, "bg_tile_grass", ground_y, 3, Color(0.8, 1.0, 0.8), 0.45)
	_add_kenney_tile_strip(c, "bg_tile_stone", ground_y + 10, 1, Color.WHITE, 0.35)
	_add_kenney_scatter(c, ["bg_tile_wood", "bg_tile_bridge"], Rect2(100, ground_y - 10, _viewport_size.x - 200, 20), 4, Vector2(0.8, 1.2), 0.4)
	
	_add_vignette(c)
	return c

# ── CHAPTER 1: Tutorial Arena ──
func _gen_tutorial_arena() -> Control:
	var c = _new_container("tutorial_arena")
	var pal = PALETTE["combat"]
	
	# Dark ambience
	_add_gradient_v(c, pal["stone_dark"].darkened(0.4), pal["stone_dark"].darkened(0.6))
	
	# Stone walls (left + right)
	_add_rect(c, pal["stone_light"].darkened(0.2), Vector2(0, 0), Vector2(80, _viewport_size.y))
	_add_rect(c, pal["stone_light"].darkened(0.2), Vector2(_viewport_size.x - 80, 0), Vector2(80, _viewport_size.y))
	
	# Stone floor
	_add_rect(c, pal["stone_light"], Vector2(80, _viewport_size.y - 100), Vector2(_viewport_size.x - 160, 100))
	
	# Floor tile grid
	for x in range(80, int(_viewport_size.x) - 80, 32):
		var line = ColorRect.new()
		line.color = Color(1, 1, 1, 0.05)
		line.size = Vector2(1, 100)
		line.position = Vector2(x, _viewport_size.y - 100)
		line.mouse_filter = Control.MOUSE_FILTER_IGNORE
		c.add_child(line)
	
	# Sky peek above
	_add_rect(c, Color(0.3, 0.5, 0.8, 0.4), Vector2(80, 0), Vector2(_viewport_size.x - 160, 100))
	
	# Kenney tile overlay: stone floor and brick walls
	_add_kenney_tile_strip(c, "bg_tile_stone", _viewport_size.y - 100, 2, Color(0.6, 0.6, 0.65), 0.5)
	_add_kenney_tile_strip(c, "bg_tile_brick", 0, int(_viewport_size.y / 64), Color(0.5, 0.5, 0.55), 0.15)
	_add_kenney_scatter(c, ["bg_tile_spikes"], Rect2(200, _viewport_size.y - 110, _viewport_size.x - 400, 10), 3, Vector2(0.8, 1.0), 0.5)
	
	return c

# ── CHAPTER 1: Shatter Bridge ──
func _gen_shatter_bridge() -> Control:
	var c = _new_container("shatter_bridge")
	
	# Void sky
	_add_gradient_v(c, Color(0.12, 0.05, 0.2), Color(0.05, 0.02, 0.1))
	
	# Fracture lines
	for i in range(8):
		var crack = ColorRect.new()
		crack.color = Color(0.0, 1.0, 1.0, randf_range(0.3, 0.7))
		crack.size = Vector2(randf_range(2, 4), randf_range(50, 200))
		crack.position = Vector2(randf_range(0, _viewport_size.x), randf_range(0, _viewport_size.y))
		crack.rotation_degrees = randf_range(-30, 30)
		crack.mouse_filter = Control.MOUSE_FILTER_IGNORE
		c.add_child(crack)
		var tw = c.create_tween().set_loops()
		tw.tween_property(crack, "modulate:a", randf_range(0.1, 0.4), randf_range(0.5, 1.5))
		tw.tween_property(crack, "modulate:a", 1.0, randf_range(0.5, 1.5))
	
	# Bridge remnants
	_add_rect(c, Color(0.3, 0.25, 0.2), Vector2(0, _viewport_size.y * 0.7), Vector2(_viewport_size.x * 0.35, 30))
	_add_rect(c, Color(0.3, 0.25, 0.2), Vector2(_viewport_size.x * 0.65, _viewport_size.y * 0.7), Vector2(_viewport_size.x * 0.35, 30))
	
	# Floating debris
	_add_floating_particles(c, 6, Rect2(_viewport_size.x * 0.3, _viewport_size.y * 0.4, _viewport_size.x * 0.4, _viewport_size.y * 0.3), Color(0.0, 1.0, 1.0, 0.6))
	
	_add_vignette(c)
	return c

# ── CHAPTER 2: Ironhold Sky ──
func _gen_ironhold_sky() -> Control:
	var c = _new_container("ironhold_sky")
	var pal = PALETTE["ironhold"]
	
	# Sunset/dusk gradient
	_add_gradient_v(c, pal["sky_top"], pal["sky_bottom"])
	
	# Smoke columns
	for i in range(4):
		var smoke = ColorRect.new()
		smoke.color = pal["smoke"]
		smoke.size = Vector2(randf_range(30, 60), randf_range(200, 400))
		smoke.position = Vector2(randf_range(100, _viewport_size.x - 100), randf_range(-100, 100))
		smoke.mouse_filter = Control.MOUSE_FILTER_IGNORE
		c.add_child(smoke)
		var tw = c.create_tween().set_loops()
		tw.tween_property(smoke, "position:y", smoke.position.y - randf_range(20, 50), randf_range(5, 10))
		tw.tween_property(smoke, "position:y", smoke.position.y, randf_range(5, 10))
	
	return c

# ── CHAPTER 2: Ironhold City ──
func _gen_ironhold_city() -> Control:
	var c = _new_container("ironhold_city")
	var pal = PALETTE["ironhold"]
	
	# Industrial sky
	_add_gradient_v(c, pal["sky_top"], pal["sky_bottom"], Vector2.ZERO, Vector2(_viewport_size.x, _viewport_size.y * 0.4))
	
	# Smokestacks (far background)
	for i in range(3):
		var x = 200 + i * 350
		_add_rect(c, pal["metal"].darkened(0.3), Vector2(x, 50), Vector2(30, 250))
		# Smoke puff
		var smoke = _add_rect(c, pal["smoke"], Vector2(x - 15, 20), Vector2(60, 40))
		var tw = c.create_tween().set_loops()
		tw.tween_property(smoke, "modulate:a", 0.3, randf_range(2, 4))
		tw.tween_property(smoke, "modulate:a", 0.8, randf_range(2, 4))
	
	# Clock tower silhouette (center)
	_add_rect(c, pal["rust"].darkened(0.3), Vector2(_viewport_size.x / 2 - 40, 60), Vector2(80, 280))
	_add_rect(c, pal["rust"].darkened(0.2), Vector2(_viewport_size.x / 2 - 50, 50), Vector2(100, 30))
	# Clock face
	var clock = _add_rect(c, pal["brass"], Vector2(_viewport_size.x / 2 - 20, 85), Vector2(40, 40))
	clock.modulate.a = 0.8
	
	# Industrial buildings
	for i in range(5):
		var x = i * 260 + randf_range(-20, 20)
		var h = randf_range(120, 200)
		_add_rect(c, pal["metal"].darkened(randf_range(0.1, 0.3)),
			Vector2(x, _viewport_size.y * 0.5 - h),
			Vector2(randf_range(100, 160), h))
		# Rivets (decorative dots)
		for j in range(3):
			_add_rect(c, pal["copper"],
				Vector2(x + 10 + j * 30, _viewport_size.y * 0.5 - h + 10),
				Vector2(4, 4))
	
	# Ground (cobblestone)
	_add_rect(c, pal["metal"].darkened(0.4), Vector2(0, _viewport_size.y * 0.5), Vector2(_viewport_size.x, _viewport_size.y * 0.5))
	
	# Gears (decorative, visible in walls)
	for i in range(3):
		var gear = _add_rect(c, pal["copper"].darkened(0.2),
			Vector2(randf_range(100, _viewport_size.x - 200), randf_range(_viewport_size.y * 0.3, _viewport_size.y * 0.5)),
			Vector2(40, 40))
		var gw = c.create_tween().set_loops()
		gw.tween_property(gear, "rotation", TAU, randf_range(8, 15))
	
	# Cyan process thread glows
	for i in range(4):
		var glow = _add_rect(c, pal["cyan_glow"],
			Vector2(randf_range(50, _viewport_size.x - 50), randf_range(_viewport_size.y * 0.35, _viewport_size.y * 0.55)),
			Vector2(randf_range(3, 5), randf_range(30, 80)))
		glow.modulate.a = 0.6
		var tw = c.create_tween().set_loops()
		tw.tween_property(glow, "modulate:a", 0.2, randf_range(1, 3))
		tw.tween_property(glow, "modulate:a", 0.8, randf_range(1, 3))
	
	# Steam vents
	_add_floating_particles(c, 6, Rect2(0, _viewport_size.y * 0.4, _viewport_size.x, 100), Color(0.8, 0.8, 0.9, 0.3), Vector2(30, 80))
	
	# Kenney tile overlay: metal floor and brick details
	_add_kenney_tile_strip(c, "bg_tile_metal", _viewport_size.y * 0.5, 4, Color(0.7, 0.65, 0.6), 0.35)
	_add_kenney_tile_strip(c, "bg_tile_brick", _viewport_size.y * 0.5 - 20, 1, Color(0.6, 0.4, 0.3), 0.25)
	_add_kenney_scatter(c, ["bg_tile_ladder", "bg_tile_metal"], Rect2(50, _viewport_size.y * 0.25, _viewport_size.x - 100, 100), 3, Vector2(0.6, 1.0), 0.3)
	
	_add_vignette(c)
	return c

# ── CHAPTER 2: Ironhold Arena (Interior) ──
func _gen_ironhold_arena() -> Control:
	var c = _new_container("ironhold_arena")
	var pal = PALETTE["combat"]
	
	# Dark interior
	_add_gradient_v(c, pal["stone_dark"].darkened(0.5), pal["stone_dark"].darkened(0.3))
	
	# Iron walls with rivets
	_add_rect(c, pal["iron"], Vector2(0, 0), Vector2(100, _viewport_size.y))
	_add_rect(c, pal["iron"], Vector2(_viewport_size.x - 100, 0), Vector2(100, _viewport_size.y))
	for side_x in [20, _viewport_size.x - 80]:
		for j in range(0, int(_viewport_size.y), 40):
			_add_rect(c, pal["iron"].lightened(0.2), Vector2(side_x + 30, j + 15), Vector2(5, 5))
	
	# Fighting pit floor
	_add_rect(c, pal["stone_light"], Vector2(100, _viewport_size.y - 120), Vector2(_viewport_size.x - 200, 120))
	
	# Spectator stands (background, upper area)
	_add_rect(c, pal["stone_dark"], Vector2(100, 0), Vector2(_viewport_size.x - 200, 150))
	for i in range(8):
		_add_rect(c, Color(0.6, 0.4, 0.3, 0.5), Vector2(140 + i * 120, 50), Vector2(15, 30))
	
	# Spotlights
	for x_pos in [_viewport_size.x * 0.3, _viewport_size.x * 0.5, _viewport_size.x * 0.7]:
		var spot = _add_rect(c, Color(pal["spotlight"].r, pal["spotlight"].g, pal["spotlight"].b, 0.15),
			Vector2(x_pos - 40, 150), Vector2(80, _viewport_size.y - 270))
		var tw = c.create_tween().set_loops()
		tw.tween_property(spot, "modulate:a", 0.6, randf_range(2, 4)).set_trans(Tween.TRANS_SINE)
		tw.tween_property(spot, "modulate:a", 1.0, randf_range(2, 4)).set_trans(Tween.TRANS_SINE)
	
	# Steam vents in corners
	_add_floating_particles(c, 3, Rect2(100, _viewport_size.y - 150, 100, 50), Color(0.8, 0.8, 0.9, 0.4))
	_add_floating_particles(c, 3, Rect2(_viewport_size.x - 200, _viewport_size.y - 150, 100, 50), Color(0.8, 0.8, 0.9, 0.4))
	
	# Kenney tile overlay: stone arena floor and metal walls
	_add_kenney_tile_strip(c, "bg_tile_stone", _viewport_size.y - 120, 2, Color(0.5, 0.5, 0.55), 0.45)
	_add_kenney_tile_strip(c, "bg_tile_metal", 0, 1, Color(0.55, 0.55, 0.6), 0.2)
	_add_kenney_scatter(c, ["bg_tile_spikes"], Rect2(150, _viewport_size.y - 130, _viewport_size.x - 300, 10), 4, Vector2(0.8, 1.0), 0.5)
	
	return c

# ── CHAPTER 2: Clock Tower ──
func _gen_ironhold_clock_tower() -> Control:
	var c = _new_container("ironhold_clock_tower")
	var pal = PALETTE["ironhold"]
	
	# Dark interior
	_add_fullscreen(c, pal["metal"].darkened(0.7))
	
	# Tower walls
	_add_rect(c, pal["rust"].darkened(0.4), Vector2(0, 0), Vector2(60, _viewport_size.y))
	_add_rect(c, pal["rust"].darkened(0.4), Vector2(_viewport_size.x - 60, 0), Vector2(60, _viewport_size.y))
	
	# Gear decorations (rotating)
	var gear_positions = [
		Vector2(100, 100), Vector2(400, 200), Vector2(700, 150),
		Vector2(200, 400), Vector2(600, 350), Vector2(900, 450)
	]
	for gp in gear_positions:
		var gear = _add_rect(c, pal["copper"].darkened(0.3), gp, Vector2(30, 30))
		var gear_tw = c.create_tween().set_loops()
		gear_tw.tween_property(gear, "rotation", TAU, randf_range(6, 12))
	
	# Platform hints
	for i in range(4):
		var y = 150 + i * 140
		var x_start: float = 80.0 if i % 2 == 0 else _viewport_size.x * 0.4
		_add_rect(c, pal["metal"], Vector2(x_start, y), Vector2(_viewport_size.x * 0.5, 15))
	
	# Brass glow at top (clock mechanism)
	var clock_glow = _add_rect(c, Color(pal["brass"].r, pal["brass"].g, pal["brass"].b, 0.3),
		Vector2(_viewport_size.x * 0.3, 20), Vector2(_viewport_size.x * 0.4, 80))
	var tw = c.create_tween().set_loops()
	tw.tween_property(clock_glow, "modulate:a", 0.4, 2.0).set_trans(Tween.TRANS_SINE)
	tw.tween_property(clock_glow, "modulate:a", 1.0, 2.0).set_trans(Tween.TRANS_SINE)
	
	return c

# ── CHAPTER 2: Underground Network ──
func _gen_underground() -> Control:
	var c = _new_container("underground")
	
	# Deep dark
	_add_fullscreen(c, Color(0.04, 0.03, 0.06))
	
	# Data pipe glows (horizontal cyan lines)
	for i in range(5):
		var pipe = _add_rect(c, Color(0, 1, 1, 0.15),
			Vector2(0, randf_range(50, _viewport_size.y - 50)),
			Vector2(_viewport_size.x, randf_range(3, 6)))
		var tw = c.create_tween().set_loops()
		tw.tween_property(pipe, "modulate:a", randf_range(0.3, 0.5), randf_range(1, 3))
		tw.tween_property(pipe, "modulate:a", 1.0, randf_range(1, 3))
	
	# Corruption zones (purple glow areas)
	for i in range(3):
		var zone = _add_rect(c, Color(0.4, 0.0, 0.6, 0.1),
			Vector2(randf_range(100, _viewport_size.x - 200), randf_range(100, _viewport_size.y - 200)),
			Vector2(randf_range(100, 200), randf_range(80, 150)))
		var tw = c.create_tween().set_loops()
		tw.tween_property(zone, "modulate:a", 0.3, randf_range(2, 4)).set_trans(Tween.TRANS_SINE)
		tw.tween_property(zone, "modulate:a", 1.0, randf_range(2, 4)).set_trans(Tween.TRANS_SINE)
	
	# Floating fragment hints
	_add_floating_particles(c, 5, Rect2(0, 0, _viewport_size.x, _viewport_size.y), Color(0, 1, 1, 0.5))
	
	# Kenney tile overlay: dark stone walls and brick floor
	_add_kenney_tile_strip(c, "bg_tile_stone", _viewport_size.y - 80, 2, Color(0.3, 0.25, 0.35), 0.3)
	_add_kenney_tile_strip(c, "bg_tile_brick", 0, 2, Color(0.2, 0.15, 0.25), 0.2)
	_add_kenney_scatter(c, ["bg_tile_ladder", "bg_tile_water_top"], Rect2(100, _viewport_size.y - 100, _viewport_size.x - 200, 20), 2, Vector2(0.7, 1.0), 0.35)
	
	return c

# ── CHAPTER 2: Administrator Boss Arena ──
func _gen_admin_boss() -> Control:
	var c = _new_container("admin_boss_arena")
	
	# Ominous red atmosphere
	_add_gradient_v(c, Color(0.15, 0.02, 0.02), Color(0.08, 0.0, 0.0))
	
	# Red atmospheric glow
	var glow = _add_rect(c, Color(0.5, 0.0, 0.0, 0.15), Vector2(0, _viewport_size.y * 0.3), Vector2(_viewport_size.x, 100))
	var tw = c.create_tween().set_loops()
	tw.tween_property(glow, "modulate:a", 0.3, 3.0).set_trans(Tween.TRANS_SINE)
	tw.tween_property(glow, "modulate:a", 1.0, 3.0).set_trans(Tween.TRANS_SINE)
	
	# Damaged building silhouettes
	for i in range(4):
		var x = i * 320 + randf_range(-30, 30)
		var h = randf_range(150, 280)
		_add_rect(c, Color(0.08, 0.05, 0.05), Vector2(x, _viewport_size.y * 0.5 - h), Vector2(randf_range(80, 140), h))
	
	# Ground
	_add_rect(c, Color(0.12, 0.08, 0.06), Vector2(0, _viewport_size.y * 0.5), Vector2(_viewport_size.x, _viewport_size.y * 0.5))
	
	# Data streams (vertical cyan lines)
	for i in range(6):
		var stream = _add_rect(c, Color(0.0, 1.0, 1.0, 0.1),
			Vector2(randf_range(50, _viewport_size.x - 50), 0),
			Vector2(3, _viewport_size.y))
		var stw = c.create_tween().set_loops()
		stw.tween_property(stream, "modulate:a", randf_range(0.2, 0.5), randf_range(1, 2.5))
		stw.tween_property(stream, "modulate:a", 1.0, randf_range(1, 2.5))
	
	# Warning lights
	for i in range(3):
		var light = _add_rect(c, Color(1.0, 0.0, 0.0, 0.5),
			Vector2(200 + i * 350, _viewport_size.y * 0.48),
			Vector2(8, 8))
		var ltw = c.create_tween().set_loops()
		ltw.tween_property(light, "modulate:a", 0.1, 0.5)
		ltw.tween_property(light, "modulate:a", 1.0, 0.5)
	
	# Kenney tile overlay: damaged metal floor, stone debris
	_add_kenney_tile_strip(c, "bg_tile_metal", _viewport_size.y * 0.5, 3, Color(0.4, 0.15, 0.1), 0.3)
	_add_kenney_tile_strip(c, "bg_tile_dirt", _viewport_size.y * 0.5 + 20, 2, Color(0.35, 0.1, 0.05), 0.2)
	_add_kenney_scatter(c, ["bg_tile_spikes", "bg_tile_stone"], Rect2(100, _viewport_size.y * 0.5 - 10, _viewport_size.x - 200, 20), 5, Vector2(0.6, 1.0), 0.4)
	
	_add_vignette(c)
	return c

# ── CHAPTER 2: Chapter End ──
func _gen_chapter_end() -> Control:
	var c = _new_container("chapter_end")
	_add_gradient_v(c, Color(0.02, 0.02, 0.05), Color(0.0, 0.0, 0.02))
	_add_stars(c, 20, Rect2(0, 0, _viewport_size.x, _viewport_size.y), true)
	_add_vignette(c)
	return c

# ── CHAPTER 3: Fractured Wastes ──
func _gen_wasteland() -> Control:
	var c = _new_container("wasteland")

	# Desolate dark sky with faint red tint
	_add_gradient_v(c, Color(0.08, 0.04, 0.06), Color(0.03, 0.02, 0.03))

	# Cracked ground plane
	_add_rect(c, Color(0.1, 0.08, 0.07), Vector2(0, _viewport_size.y * 0.55), Vector2(_viewport_size.x, _viewport_size.y * 0.45))

	# Ground cracks (dark lines)
	for i in range(6):
		var x = randf_range(50, _viewport_size.x - 50)
		var y_start = _viewport_size.y * 0.55 + randf_range(10, 80)
		_add_rect(c, Color(0.03, 0.02, 0.02), Vector2(x, y_start), Vector2(randf_range(2, 4), randf_range(40, 120)))

	# Ruined pillar silhouettes
	for i in range(3):
		var x = 150 + i * 350 + randf_range(-40, 40)
		var h = randf_range(100, 200)
		_add_rect(c, Color(0.06, 0.04, 0.05), Vector2(x, _viewport_size.y * 0.55 - h), Vector2(randf_range(30, 60), h))

	# Faint glitch corruption glow (purple haze)
	for i in range(2):
		var zone = _add_rect(c, Color(0.3, 0.0, 0.4, 0.08),
			Vector2(randf_range(80, _viewport_size.x - 250), randf_range(50, _viewport_size.y * 0.4)),
			Vector2(randf_range(120, 220), randf_range(60, 100)))
		var tw = c.create_tween().set_loops()
		tw.tween_property(zone, "modulate:a", 0.3, randf_range(3, 5)).set_trans(Tween.TRANS_SINE)
		tw.tween_property(zone, "modulate:a", 1.0, randf_range(3, 5)).set_trans(Tween.TRANS_SINE)

	# Sparse floating ash/ember particles
	_add_floating_particles(c, 8, Rect2(0, 0, _viewport_size.x, _viewport_size.y), Color(0.6, 0.3, 0.1, 0.4))

	_add_vignette(c)
	return c

# ── CHAPTER 3: The Archive ──
func _gen_archive() -> Control:
	var c = _new_container("archive")

	# Deep blue-black void background
	_add_gradient_v(c, Color(0.02, 0.02, 0.08), Color(0.0, 0.0, 0.03))

	# Floating data shelves / knowledge pillars
	for i in range(5):
		var x = 50 + i * 260 + randf_range(-30, 30)
		var h = randf_range(300, 550)
		var w = randf_range(40, 80)
		var _shelf = _add_rect(c, Color(0.08, 0.06, 0.14), Vector2(x, _viewport_size.y - h), Vector2(w, h))
		# Faint cyan data lines on shelves
		for j in range(int(h / 30)):
			_add_rect(c, Color(0.0, 0.6, 0.8, 0.15), Vector2(x + 4, _viewport_size.y - h + j * 30 + 10), Vector2(w - 8, 2))

	# Horizontal data streams (slowly scrolling light bands)
	for i in range(4):
		var y = randf_range(100, _viewport_size.y - 100)
		var stream = _add_rect(c, Color(0.0, 0.5, 1.0, 0.06), Vector2(0, y), Vector2(_viewport_size.x, randf_range(3, 8)))
		var tw = c.create_tween().set_loops()
		tw.tween_property(stream, "modulate:a", 0.2, randf_range(2.0, 4.0)).set_trans(Tween.TRANS_SINE)
		tw.tween_property(stream, "modulate:a", 1.0, randf_range(2.0, 4.0)).set_trans(Tween.TRANS_SINE)

	# Floating rune / glyph particles (teal)
	_add_floating_particles(c, 15, Rect2(0, 0, _viewport_size.x, _viewport_size.y), Color(0.0, 0.8, 1.0, 0.3))

	# Central glow — source of knowledge
	var glow = _add_rect(c, Color(0.1, 0.3, 0.5, 0.08), Vector2(_viewport_size.x * 0.3, _viewport_size.y * 0.2), Vector2(_viewport_size.x * 0.4, _viewport_size.y * 0.3))
	var gw = c.create_tween().set_loops()
	gw.tween_property(glow, "modulate:a", 0.4, 3.0).set_trans(Tween.TRANS_SINE)
	gw.tween_property(glow, "modulate:a", 1.0, 3.0).set_trans(Tween.TRANS_SINE)

	# Stars (this is deep inside the system)
	_add_stars(c, 12, Rect2(0, 0, _viewport_size.x, _viewport_size.y * 0.5), true)

	_add_vignette(c)
	return c

# ── CHAPTER 3: Data Stream Ride ──
func _gen_data_stream() -> Control:
	var c = _new_container("data_stream")

	# Electric blue-to-black vertical gradient
	_add_gradient_v(c, Color(0.0, 0.08, 0.18), Color(0.0, 0.02, 0.06))

	# Horizontal data stream lines (many, fast-looking)
	for i in range(12):
		var y = randf_range(20, _viewport_size.y - 20)
		var line_w = randf_range(_viewport_size.x * 0.3, _viewport_size.x)
		var line = _add_rect(c, Color(0.0, 0.6, 1.0, randf_range(0.05, 0.2)), Vector2(randf_range(-100, 200), y), Vector2(line_w, randf_range(1, 4)))
		var tw = c.create_tween().set_loops()
		tw.tween_property(line, "position:x", line.position.x - 400, randf_range(2.0, 5.0))
		tw.tween_property(line, "position:x", line.position.x, 0.01)

	# Data nodes (bright dots)
	_add_floating_particles(c, 20, Rect2(0, 0, _viewport_size.x, _viewport_size.y), Color(0.0, 1.0, 1.0, 0.4))

	_add_vignette(c)
	return c

# ── Fallback ──
func _gen_fallback(location: String) -> Control:
	var c = _new_container(location)
	_add_gradient_v(c, Color(0.1, 0.1, 0.15), Color(0.05, 0.05, 0.08))
	
	# Label showing location name
	var lbl = Label.new()
	lbl.text = "[" + location.replace("_", " ").capitalize() + "]"
	lbl.add_theme_font_size_override("font_size", 14)
	lbl.add_theme_color_override("font_color", Color(1, 1, 1, 0.3))
	lbl.position = Vector2(20, 20)
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	c.add_child(lbl)
	
	return c

# =====================================================================
# PARALLAX SYSTEM — For scenes that use Node2D (exploration/combat)
# =====================================================================

func create_parallax_background(location: String, parent: Node2D = null) -> ParallaxBackground:
	## Create a parallax background for Node2D-based scenes (combat, exploration).
	## Returns a ParallaxBackground with multiple layers at different scroll speeds.
	
	var parallax = ParallaxBackground.new()
	parallax.name = "ParallaxBG_" + location
	
	match location:
		"oakhaven":
			_add_parallax_layer(parallax, _gen_oakhaven_sky_layer(), Vector2(0.2, 0.2))
			_add_parallax_layer(parallax, _gen_oakhaven_far_layer(), Vector2(0.4, 0.4))
			_add_parallax_layer(parallax, _gen_oakhaven_ground_layer(), Vector2(1.0, 1.0))
		"ironhold_city":
			_add_parallax_layer(parallax, _gen_ironhold_sky_layer(), Vector2(0.2, 0.2))
			_add_parallax_layer(parallax, _gen_ironhold_far_layer(), Vector2(0.4, 0.4))
		"tutorial_arena":
			_add_parallax_layer(parallax, _gen_arena_bg_layer(), Vector2(0.1, 0.1))
		_:
			_add_parallax_layer(parallax, _gen_default_parallax_layer(location), Vector2(0.3, 0.3))
	
	if parent:
		parent.add_child(parallax)
		parent.move_child(parallax, 0)
	
	return parallax

func _add_parallax_layer(parallax: ParallaxBackground, sprite: Sprite2D, motion_scale: Vector2) -> void:
	var layer = ParallaxLayer.new()
	layer.motion_scale = motion_scale
	layer.add_child(sprite)
	parallax.add_child(layer)

func _gen_oakhaven_sky_layer() -> Sprite2D:
	var pal = PALETTE["oakhaven"]
	var grad = Gradient.new()
	grad.set_color(0, pal["sky_top"])
	grad.set_color(1, pal["sky_bottom"])
	var tex = GradientTexture2D.new()
	tex.gradient = grad
	tex.width = 1920
	tex.height = 540
	tex.fill_from = Vector2(0.5, 0.0)
	tex.fill_to = Vector2(0.5, 1.0)
	var sprite = Sprite2D.new()
	sprite.texture = tex
	sprite.position = Vector2(640, 270)
	return sprite

func _gen_oakhaven_far_layer() -> Sprite2D:
	# Simple green treeline
	var img = Image.create(1920, 400, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	# Draw treeline as solid block at bottom
	for x in range(1920):
		var h = int(80 + sin(x * 0.02) * 30 + sin(x * 0.05) * 15)
		for y in range(400 - h, 400):
			img.set_pixel(x, y, PALETTE["oakhaven"]["grass"].darkened(0.3))
	var tex = ImageTexture.create_from_image(img)
	var sprite = Sprite2D.new()
	sprite.texture = tex
	sprite.position = Vector2(640, 400)
	return sprite

func _gen_oakhaven_ground_layer() -> Sprite2D:
	var img = Image.create(1920, 300, false, Image.FORMAT_RGBA8)
	img.fill(PALETTE["oakhaven"]["grass"])
	# Stone path
	for x in range(1920):
		for y in range(20, 60):
			img.set_pixel(x, y, PALETTE["oakhaven"]["stone"].lightened(0.1))
	var tex = ImageTexture.create_from_image(img)
	var sprite = Sprite2D.new()
	sprite.texture = tex
	sprite.position = Vector2(640, 570)
	return sprite

func _gen_ironhold_sky_layer() -> Sprite2D:
	var pal = PALETTE["ironhold"]
	var grad = Gradient.new()
	grad.set_color(0, pal["sky_top"])
	grad.set_color(1, pal["sky_bottom"])
	var tex = GradientTexture2D.new()
	tex.gradient = grad
	tex.width = 1920
	tex.height = 540
	tex.fill_from = Vector2(0.5, 0.0)
	tex.fill_to = Vector2(0.5, 1.0)
	var sprite = Sprite2D.new()
	sprite.texture = tex
	sprite.position = Vector2(640, 270)
	return sprite

func _gen_ironhold_far_layer() -> Sprite2D:
	var pal = PALETTE["ironhold"]
	var img = Image.create(1920, 800, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	# Industrial silhouettes
	var buildings = [
		[100, 300], [350, 400], [600, 350], [850, 500], [1100, 380], [1400, 450], [1650, 320]
	]
	for b in buildings:
		for x in range(b[0], b[0] + 120):
			if x >= 1920:
				break
			for y in range(800 - b[1], 800):
				img.set_pixel(x, y, pal["metal"].darkened(0.4))
	var tex = ImageTexture.create_from_image(img)
	var sprite = Sprite2D.new()
	sprite.texture = tex
	sprite.position = Vector2(640, 360)
	return sprite

func _gen_arena_bg_layer() -> Sprite2D:
	var pal = PALETTE["combat"]
	var grad = Gradient.new()
	grad.set_color(0, pal["stone_dark"].darkened(0.3))
	grad.set_color(1, pal["stone_dark"])
	var tex = GradientTexture2D.new()
	tex.gradient = grad
	tex.width = 1920
	tex.height = 1080
	tex.fill_from = Vector2(0.5, 0.0)
	tex.fill_to = Vector2(0.5, 1.0)
	var sprite = Sprite2D.new()
	sprite.texture = tex
	sprite.position = Vector2(640, 360)
	return sprite

func _gen_default_parallax_layer(location: String) -> Sprite2D:
	var grad = Gradient.new()
	grad.set_color(0, Color(0.1, 0.1, 0.15))
	grad.set_color(1, Color(0.05, 0.05, 0.08))
	var tex = GradientTexture2D.new()
	tex.gradient = grad
	tex.width = 1920
	tex.height = 1080
	tex.fill_from = Vector2(0.5, 0.0)
	tex.fill_to = Vector2(0.5, 1.0)
	var sprite = Sprite2D.new()
	sprite.texture = tex
	sprite.name = location + "_default"
	sprite.position = Vector2(640, 360)
	return sprite


# =====================================================================
# KENNEY TILE OVERLAY SYSTEM — Enhances procedural BGs with real sprites
# =====================================================================

## Tile a Kenney texture into a strip across the bottom of a background container.
## Used to add textured ground/platforms on top of procedural gradients.
func _add_kenney_tile_strip(parent: Control, asset_key: String, y_start: float, rows: int = 2, tint: Color = Color.WHITE, alpha: float = 0.7) -> void:
	if not has_node("/root/AssetManager"):
		return
	var tex = AssetManager.get_texture(asset_key)
	if tex == null:
		return
	var tile_w = tex.get_width()
	var tile_h = tex.get_height()
	if tile_w <= 0 or tile_h <= 0:
		return
	var cols = ceili(_viewport_size.x / tile_w) + 1
	for row in range(rows):
		for col in range(cols):
			var tex_rect = TextureRect.new()
			tex_rect.texture = tex
			tex_rect.position = Vector2(col * tile_w, y_start + row * tile_h)
			tex_rect.modulate = Color(tint.r, tint.g, tint.b, alpha)
			tex_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
			parent.add_child(tex_rect)


## Scatter random Kenney tile decorations (crates, signs, etc.) across a region.
func _add_kenney_scatter(parent: Control, asset_keys: Array, area: Rect2, count: int, scale_range: Vector2 = Vector2(1.0, 1.5), alpha: float = 0.8) -> void:
	if not has_node("/root/AssetManager"):
		return
	for i in range(count):
		var key = asset_keys[randi() % asset_keys.size()]
		var tex = AssetManager.get_texture(key)
		if tex == null:
			continue
		var tex_rect = TextureRect.new()
		tex_rect.texture = tex
		var s = randf_range(scale_range.x, scale_range.y)
		tex_rect.scale = Vector2(s, s)
		tex_rect.position = Vector2(
			randf_range(area.position.x, area.end.x),
			randf_range(area.position.y, area.end.y)
		)
		tex_rect.modulate.a = alpha
		tex_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		parent.add_child(tex_rect)


## Add a Kenney background tile as a large scaled backdrop element.
func _add_kenney_bg_panel(parent: Control, asset_key: String, pos: Vector2, target_size: Vector2, alpha: float = 0.6) -> void:
	if not has_node("/root/AssetManager"):
		return
	var tex = AssetManager.get_texture(asset_key)
	if tex == null:
		return
	var tex_rect = TextureRect.new()
	tex_rect.texture = tex
	tex_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	tex_rect.custom_minimum_size = target_size
	tex_rect.size = target_size
	tex_rect.position = pos
	tex_rect.modulate.a = alpha
	tex_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(tex_rect)
