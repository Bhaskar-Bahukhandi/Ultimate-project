extends CanvasLayer

## Glitch overlay — visual corruption effects that scale with corruption level
## Combines shader-based distortion (when available) with procedural CPU effects:
##   10%+: Faint edge tint, barely noticeable
##   20%+: Edge vignette indicators pulse
##   25%+: Corruption warning label, occasional noise rectangles
##   40%+: Scanline shimmer overlay, color shift hints
##   50%+: Stronger vignette, displacement noise, chromatic separation sim
##   75%+: Heavy distortion, screen tearing simulation, red hostile edges

var color_rect: ColorRect
var shader_material: ShaderMaterial
var _shader_loaded: bool = false
var _update_cooldown: float = 0.0

# Corruption HUD warning
var _corruption_warning: Label = null
# Screen edge corruption indicators
var _edge_indicators: Array[ColorRect] = []
# Scanline overlay
var _scanline_container: Control = null
var _scanlines: Array[ColorRect] = []
# Noise rectangles (corruption glitch blocks)
var _noise_rects: Array[ColorRect] = []
const MAX_NOISE_RECTS: int = 6
# Chromatic aberration simulation layers
var _chroma_red: ColorRect = null
var _chroma_blue: ColorRect = null
# Screen tear simulation
var _tear_rects: Array[ColorRect] = []
const MAX_TEARS: int = 3
# flash_glitch/trigger_glitch end time. Until then the throttled per-level
# updates leave the shader, noise and chroma layers alone; otherwise they reset
# them within ~66 ms and the flash never lasts its requested duration.
var _flash_until_msec: int = 0

func _ready() -> void:
	layer = 95  # Below dialogue (100) but above most game elements

	# Try to load shader safely
	var shader_path = "res://shaders/glitch_effect.gdshader"
	if ResourceLoader.exists(shader_path):
		var shader = load(shader_path)
		if shader:
			shader_material = ShaderMaterial.new()
			shader_material.shader = shader
			_shader_loaded = true

	if _shader_loaded:
		# Create fullscreen ColorRect for shader
		color_rect = ColorRect.new()
		color_rect.material = shader_material
		color_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		color_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
		color_rect.visible = false
		add_child(color_rect)
	else:
		push_warning("[GLITCH OVERLAY] Shader not found — using CPU-only corruption effects")

	# Build all CPU-based corruption visual layers
	_build_corruption_warning()
	_build_edge_vignette()
	_build_scanline_overlay()
	_build_noise_rects()
	_build_chromatic_layers()
	_build_tear_rects()

	# Connect to GameManager
	if has_node("/root/GameManager"):
		if GameManager.glitch_meter_changed.is_connected(_on_glitch_meter_changed):
			GameManager.glitch_meter_changed.disconnect(_on_glitch_meter_changed)
		GameManager.glitch_meter_changed.connect(_on_glitch_meter_changed)
	else:
		push_warning("[GLITCH OVERLAY] GameManager autoload not found — corruption visuals disabled")

	_update_shader()

func _build_corruption_warning() -> void:
	_corruption_warning = Label.new()
	_corruption_warning.text = ""
	_corruption_warning.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_corruption_warning.add_theme_font_size_override("font_size", 13)
	_corruption_warning.add_theme_color_override("font_color", Color(1.0, 0.3, 0.3, 0.8))
	_corruption_warning.add_theme_constant_override("outline_size", 2)
	_corruption_warning.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.7))
	_corruption_warning.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	_corruption_warning.offset_left = -300
	_corruption_warning.offset_top = 8
	_corruption_warning.offset_right = -12
	_corruption_warning.visible = false
	_corruption_warning.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_corruption_warning)

func _process(delta) -> void:
	_update_cooldown -= delta
	if _update_cooldown <= 0.0:
		_update_cooldown = 0.066  # ~15fps throttle
		if not has_node("/root/GameManager"):
			return
		var flashing = _is_flashing()
		_update_shader()
		_update_corruption_warning()
		_update_edge_vignette()
		_update_scanlines()
		if not flashing:
			_update_noise_rects()
			_update_chromatic_layers()
		_update_tear_rects()

func _is_flashing() -> bool:
	return Time.get_ticks_msec() < _flash_until_msec

func _start_flash(duration: float) -> void:
	_flash_until_msec = maxi(_flash_until_msec, Time.get_ticks_msec() + int(duration * 1000.0))

func _update_shader() -> void:
	if not _shader_loaded or not shader_material or not color_rect:
		return
	if _is_flashing():
		return

	var corruption = GameManager.glitch_meter / 100.0

	if corruption < 0.15:
		color_rect.visible = false
		return

	color_rect.visible = true
	shader_material.set_shader_parameter("corruption", corruption)
	shader_material.set_shader_parameter("time_scale", 1.0 + corruption * 0.8)

func _update_corruption_warning() -> void:
	if not _corruption_warning:
		return

	var corruption = GameManager.glitch_meter

	if corruption < 25.0:
		_corruption_warning.visible = false
		return

	_corruption_warning.visible = true

	if corruption >= 75.0:
		_corruption_warning.text = "// SYSTEM HOSTILE -- %d%%" % int(corruption)
		_corruption_warning.add_theme_color_override("font_color", Color(1.0, 0.15, 0.15, 0.9))
	elif corruption >= 50.0:
		_corruption_warning.text = "// INSTABILITY -- %d%%" % int(corruption)
		_corruption_warning.add_theme_color_override("font_color", Color(1.0, 0.5, 0.2, 0.85))
	else:
		_corruption_warning.text = "// Corruption: %d%%" % int(corruption)
		_corruption_warning.add_theme_color_override("font_color", Color(1.0, 0.7, 0.3, 0.7))

	# Pulsing at high corruption with occasional flicker
	if corruption >= 75.0:
		var t = Time.get_ticks_msec() / 1000.0
		var pulse = 0.65 + sin(t * 4.0) * 0.35
		# Random flicker spikes
		if randf() < 0.03:
			pulse = randf_range(0.1, 0.4)
		_corruption_warning.modulate.a = pulse
	elif corruption >= 50.0:
		var t = Time.get_ticks_msec() / 1000.0
		_corruption_warning.modulate.a = 0.75 + sin(t * 2.0) * 0.2
	else:
		# Clear any pulse/flicker alpha left over from a higher band.
		_corruption_warning.modulate.a = 1.0

func _on_glitch_meter_changed(_value: float) -> void:
	_update_shader()

# ── Public API — Triggered Glitch Effects ────────────────────────────

func flash_glitch(duration: float = 0.2) -> void:
	_start_flash(duration)
	if _shader_loaded and color_rect:
		color_rect.visible = true
		shader_material.set_shader_parameter("corruption", 0.8)
		shader_material.set_shader_parameter("time_scale", 3.0)
		var tw = create_tween()
		tw.tween_interval(duration)
		tw.tween_callback(func():
			if is_instance_valid(color_rect):
				_update_shader()
		)

	# CPU flash: brief chromatic split + noise burst
	_flash_chromatic(duration)
	_flash_noise_burst(duration)

func trigger_glitch(duration: float = 0.5, intensity: float = 0.6) -> void:
	_start_flash(duration)
	if _shader_loaded and color_rect:
		color_rect.visible = true
		shader_material.set_shader_parameter("corruption", intensity)
		shader_material.set_shader_parameter("time_scale", 2.5)
		var tw = create_tween()
		tw.tween_interval(duration)
		tw.tween_callback(func():
			if is_instance_valid(color_rect):
				_update_shader()
		)

	_flash_chromatic(duration * 0.8)
	_flash_noise_burst(duration)

# ── Edge Vignette ────────────────────────────────────────────────────

func _build_edge_vignette() -> void:
	var edge_size = 60
	var edges_data = [
		{"name": "top", "anchor_left": 0.0, "anchor_top": 0.0, "anchor_right": 1.0, "anchor_bottom": 0.0, "offset_bottom": edge_size},
		{"name": "bottom", "anchor_left": 0.0, "anchor_top": 1.0, "anchor_right": 1.0, "anchor_bottom": 1.0, "offset_top": -edge_size},
		{"name": "left", "anchor_left": 0.0, "anchor_top": 0.0, "anchor_right": 0.0, "anchor_bottom": 1.0, "offset_right": edge_size},
		{"name": "right", "anchor_left": 1.0, "anchor_top": 0.0, "anchor_right": 1.0, "anchor_bottom": 1.0, "offset_left": -edge_size},
	]
	for data in edges_data:
		var edge = ColorRect.new()
		edge.name = "Edge_" + data["name"]
		edge.color = Color(0.8, 0.0, 0.1, 0.0)
		edge.mouse_filter = Control.MOUSE_FILTER_IGNORE
		edge.anchor_left = data["anchor_left"]
		edge.anchor_top = data["anchor_top"]
		edge.anchor_right = data["anchor_right"]
		edge.anchor_bottom = data["anchor_bottom"]
		if data.has("offset_bottom"):
			edge.offset_bottom = data["offset_bottom"]
		if data.has("offset_top"):
			edge.offset_top = data["offset_top"]
		if data.has("offset_right"):
			edge.offset_right = data["offset_right"]
		if data.has("offset_left"):
			edge.offset_left = data["offset_left"]
		edge.visible = false
		add_child(edge)
		_edge_indicators.append(edge)

func _update_edge_vignette() -> void:
	var corruption = GameManager.glitch_meter / 100.0

	if corruption < 0.20:
		for edge in _edge_indicators:
			if is_instance_valid(edge):
				edge.visible = false
		return

	var t = Time.get_ticks_msec() / 1000.0
	var base_alpha: float
	var edge_color: Color

	if corruption >= 0.75:
		base_alpha = 0.14 + sin(t * 3.0) * 0.09
		edge_color = Color(0.8, 0.0, 0.1, base_alpha)
		# Random flicker at highest corruption
		if randf() < 0.05:
			base_alpha += randf_range(0.0, 0.15)
	elif corruption >= 0.50:
		base_alpha = 0.07 + sin(t * 2.0) * 0.04
		edge_color = Color(0.9, 0.3, 0.0, base_alpha)
	else:
		base_alpha = 0.03 + sin(t * 1.5) * 0.02
		edge_color = Color(0.0, 0.7, 0.3, base_alpha)

	for edge in _edge_indicators:
		if is_instance_valid(edge):
			edge.color = edge_color
			edge.visible = true

# ── Scanline Overlay ─────────────────────────────────────────────────

func _build_scanline_overlay() -> void:
	_scanline_container = Control.new()
	_scanline_container.name = "ScanlineOverlay"
	_scanline_container.set_anchors_preset(Control.PRESET_FULL_RECT)
	_scanline_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_scanline_container.visible = false
	add_child(_scanline_container)

	# Create horizontal scanline strips
	var viewport_h = 720
	var line_spacing = 4
	for y in range(0, viewport_h, line_spacing):
		var line = ColorRect.new()
		line.color = Color(0.0, 0.0, 0.0, 0.04)
		line.size = Vector2(1280, 1)
		line.position = Vector2(0, y)
		line.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_scanline_container.add_child(line)
		_scanlines.append(line)

func _update_scanlines() -> void:
	var corruption = GameManager.glitch_meter / 100.0

	if corruption < 0.40:
		if _scanline_container:
			_scanline_container.visible = false
		return

	if _scanline_container:
		_scanline_container.visible = true
		# Scanline intensity scales with corruption
		var line_alpha = remap(corruption, 0.40, 1.0, 0.03, 0.10)
		var t = Time.get_ticks_msec() / 1000.0
		# Shimmer: slowly vary alpha across lines
		for i in range(_scanlines.size()):
			if is_instance_valid(_scanlines[i]):
				var shimmer = sin(t * 2.0 + i * 0.5) * 0.02
				_scanlines[i].color.a = line_alpha + shimmer

# ── Noise Rectangles (glitch blocks) ─────────────────────────────────

func _build_noise_rects() -> void:
	for i in range(MAX_NOISE_RECTS):
		var rect = ColorRect.new()
		rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		rect.visible = false
		add_child(rect)
		_noise_rects.append(rect)

func _update_noise_rects() -> void:
	var corruption = GameManager.glitch_meter / 100.0

	if corruption < 0.25:
		for nr in _noise_rects:
			if is_instance_valid(nr):
				nr.visible = false
		return

	# Probability of noise block appearing this frame increases with corruption
	var spawn_chance = remap(corruption, 0.25, 1.0, 0.01, 0.15)

	for nr in _noise_rects:
		if not is_instance_valid(nr):
			continue
		if randf() < spawn_chance:
			# Spawn a random glitch block
			var w = randi_range(20, 200)
			var h = randi_range(2, 12)
			nr.size = Vector2(w, h)
			nr.position = Vector2(randf_range(0, 1280 - w), randf_range(0, 720 - h))
			# Color varies: green/cyan at low corruption, red/magenta at high
			if corruption >= 0.6:
				nr.color = Color(randf_range(0.6, 1.0), randf_range(0.0, 0.2), randf_range(0.0, 0.3), randf_range(0.1, 0.3))
			else:
				nr.color = Color(randf_range(0.0, 0.3), randf_range(0.6, 1.0), randf_range(0.3, 0.8), randf_range(0.05, 0.15))
			nr.visible = true
		else:
			nr.visible = false

func _flash_noise_burst(duration: float = 0.2) -> void:
	for nr in _noise_rects:
		if not is_instance_valid(nr):
			continue
		var w = randi_range(30, 300)
		var h = randi_range(3, 15)
		nr.size = Vector2(w, h)
		nr.position = Vector2(randf_range(0, 1280 - w), randf_range(0, 720 - h))
		nr.color = Color(randf_range(0.5, 1.0), randf_range(0.5, 1.0), randf_range(0.5, 1.0), randf_range(0.2, 0.5))
		nr.visible = true

	var tw = create_tween()
	tw.tween_interval(duration)
	tw.tween_callback(func():
		for nr2 in _noise_rects:
			if is_instance_valid(nr2):
				nr2.visible = false
	)

# ── Chromatic Aberration Simulation ──────────────────────────────────

func _build_chromatic_layers() -> void:
	# Red-shifted layer (slight offset)
	_chroma_red = ColorRect.new()
	_chroma_red.color = Color(1.0, 0.0, 0.0, 0.0)
	_chroma_red.set_anchors_preset(Control.PRESET_FULL_RECT)
	_chroma_red.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_chroma_red.visible = false
	add_child(_chroma_red)

	# Blue-shifted layer (opposite offset)
	_chroma_blue = ColorRect.new()
	_chroma_blue.color = Color(0.0, 0.0, 1.0, 0.0)
	_chroma_blue.set_anchors_preset(Control.PRESET_FULL_RECT)
	_chroma_blue.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_chroma_blue.visible = false
	add_child(_chroma_blue)

func _update_chromatic_layers() -> void:
	var corruption = GameManager.glitch_meter / 100.0

	if corruption < 0.50:
		if _chroma_red and is_instance_valid(_chroma_red):
			_chroma_red.visible = false
		if _chroma_blue and is_instance_valid(_chroma_blue):
			_chroma_blue.visible = false
		return

	# Subtle chromatic shift — barely visible tinted overlays with position offset
	var intensity = remap(corruption, 0.50, 1.0, 0.01, 0.05)
	var t = Time.get_ticks_msec() / 1000.0
	var chroma_offset = sin(t * 1.5) * remap(corruption, 0.5, 1.0, 1.0, 4.0)

	if _chroma_red and is_instance_valid(_chroma_red):
		_chroma_red.visible = true
		_chroma_red.color = Color(1.0, 0.0, 0.0, intensity)
		_chroma_red.offset_left = chroma_offset
		_chroma_red.offset_right = chroma_offset

	if _chroma_blue and is_instance_valid(_chroma_blue):
		_chroma_blue.visible = true
		_chroma_blue.color = Color(0.0, 0.0, 1.0, intensity * 0.8)
		_chroma_blue.offset_left = -chroma_offset
		_chroma_blue.offset_right = -chroma_offset

func _flash_chromatic(duration: float = 0.2) -> void:
	if not _chroma_red or not is_instance_valid(_chroma_red):
		return
	if not _chroma_blue or not is_instance_valid(_chroma_blue):
		return

	_chroma_red.visible = true
	_chroma_blue.visible = true
	_chroma_red.color = Color(1.0, 0.0, 0.0, 0.08)
	_chroma_blue.color = Color(0.0, 0.0, 1.0, 0.06)
	_chroma_red.offset_left = 3.0
	_chroma_red.offset_right = 3.0
	_chroma_blue.offset_left = -3.0
	_chroma_blue.offset_right = -3.0

	var tw = create_tween().set_parallel(true)
	tw.tween_property(_chroma_red, "color:a", 0.0, duration)
	tw.tween_property(_chroma_blue, "color:a", 0.0, duration)
	tw.tween_property(_chroma_red, "offset_left", 0.0, duration)
	tw.tween_property(_chroma_blue, "offset_left", 0.0, duration)

# ── Screen Tear Simulation ───────────────────────────────────────────

func _build_tear_rects() -> void:
	for i in range(MAX_TEARS):
		var tear = ColorRect.new()
		tear.mouse_filter = Control.MOUSE_FILTER_IGNORE
		tear.visible = false
		add_child(tear)
		_tear_rects.append(tear)

func _update_tear_rects() -> void:
	var corruption = GameManager.glitch_meter / 100.0

	if corruption < 0.65:
		for tear in _tear_rects:
			if is_instance_valid(tear):
				tear.visible = false
		return

	# Screen tears: horizontal strips that briefly shift sideways
	var tear_chance = remap(corruption, 0.65, 1.0, 0.005, 0.06)

	for tear in _tear_rects:
		if not is_instance_valid(tear):
			continue
		if randf() < tear_chance:
			var h = randi_range(3, 20)
			var y_pos = randf_range(0, 720 - h)
			var x_offset = randf_range(-15, 15)
			tear.size = Vector2(1280, h)
			tear.position = Vector2(x_offset, y_pos)
			# Slightly tinted horizontal band
			tear.color = Color(
				randf_range(0.0, 0.15),
				randf_range(0.0, 0.15),
				randf_range(0.0, 0.15),
				randf_range(0.1, 0.25)
			)
			tear.visible = true
		else:
			tear.visible = false
