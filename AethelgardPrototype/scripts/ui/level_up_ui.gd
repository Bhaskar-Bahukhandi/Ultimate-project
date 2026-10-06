extends CanvasLayer

## ==========================================================================
## LEVEL-UP UI — XP Bar + Level-Up Popup with stat change display
## ==========================================================================
## Shows a persistent XP bar at the bottom of the screen. When player levels
## up, shows an animated popup with stat changes and pauses briefly.
## ==========================================================================

# XP Bar elements
var _xp_bar_container: Control
var _xp_bar_bg: ColorRect
var _xp_bar_fill: ColorRect
var _xp_label: Label
var _level_label: Label

# Level-up popup
var _popup_panel: Panel
var _popup_title: Label
var _popup_stats: Label
var _popup_continue: Label
var _popup_visible: bool = false
var _popup_timer: float = 0.0
var _popup_tween: Tween = null

# Animation
var _xp_display_value: float = 0.0  # Smoothly animated XP bar
var _xp_target_value: float = 0.0

# Stat curve system — non-linear stat growth
# Returns stat bonus for a given level (indexed from 0)
var _hp_curve: Array = []
var _mp_curve: Array = []
var _atk_curve: Array = []

const XP_BAR_WIDTH: float = 200.0
const XP_BAR_HEIGHT: float = 8.0
const POPUP_DURATION: float = 3.0
const XP_TWEEN_SPEED: float = 2.0

func _ready() -> void:
	layer = 90  # Above gameplay, below pause screen
	_build_xp_bar()
	_build_level_popup()
	_generate_stat_curves()
	
	# Connect to GameManager level-up signal
	if GameManager:
		if not GameManager.player_leveled_up.is_connected(_on_player_leveled_up):
			GameManager.player_leveled_up.connect(_on_player_leveled_up)
		if not GameManager.state_changed.is_connected(_on_game_state_changed):
			GameManager.state_changed.connect(_on_game_state_changed)
	
	# Initialize XP bar
	_update_xp_bar_instant()
	_update_xp_bar_visibility()

func _process(delta) -> void:
	_update_xp_bar_visibility()
	# PERF: Skip when idle (no popup, no animation)
	if not _popup_visible and abs(_xp_display_value - _xp_target_value) < 0.001:
		return
	# Smooth XP bar animation
	if abs(_xp_display_value - _xp_target_value) > 0.001:
		_xp_display_value = lerp(_xp_display_value, _xp_target_value, XP_TWEEN_SPEED * delta)
		_xp_bar_fill.size.x = XP_BAR_WIDTH * _xp_display_value
	
	# Update XP display periodically
	_update_xp_label()
	
	# Popup auto-dismiss timer
	if _popup_visible:
		_popup_timer -= delta
		if _popup_timer <= 0:
			_dismiss_popup()


func _unhandled_input(event: InputEvent) -> void:
	# Reliable input handling for popup dismiss — _input is eaten by paused UIs
	if _popup_visible and event.is_action_pressed("ui_accept"):
		_dismiss_popup()
		get_viewport().set_input_as_handled()

# ==========================================================================
# XP BAR — Persistent bottom-left bar
# ==========================================================================

func _build_xp_bar() -> void:
	var container = Control.new()
	container.name = "XPBarContainer"
	container.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	container.position = Vector2(20, -30)
	add_child(container)
	_xp_bar_container = container
	
	# Level label
	_level_label = Label.new()
	_level_label.text = "Lv.1"
	_level_label.position = Vector2(0, -20)
	_level_label.add_theme_font_size_override("font_size", 14)
	_level_label.add_theme_color_override("font_color", Color(0.9, 0.85, 0.6))
	container.add_child(_level_label)
	
	# BG bar
	_xp_bar_bg = ColorRect.new()
	_xp_bar_bg.size = Vector2(XP_BAR_WIDTH, XP_BAR_HEIGHT)
	_xp_bar_bg.color = Color(0.15, 0.15, 0.2, 0.8)
	_xp_bar_bg.position = Vector2(0, 0)
	container.add_child(_xp_bar_bg)
	
	# Fill bar
	_xp_bar_fill = ColorRect.new()
	_xp_bar_fill.size = Vector2(0, XP_BAR_HEIGHT)
	_xp_bar_fill.color = Color(0.2, 0.7, 1.0, 0.9)
	_xp_bar_fill.position = Vector2(0, 0)
	container.add_child(_xp_bar_fill)
	
	# XP text
	_xp_label = Label.new()
	_xp_label.text = "0 / 100 XP"
	_xp_label.position = Vector2(0, XP_BAR_HEIGHT + 2)
	_xp_label.add_theme_font_size_override("font_size", 11)
	_xp_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.8))
	container.add_child(_xp_label)


func _on_game_state_changed(_new_state: int) -> void:
	_update_xp_bar_visibility()
	# New Game / loading a save change level and XP without an XP gain, which
	# left the bar and "Lv." label showing the previous run.
	_level_label.text = "Lv.%d" % GameManager.player_stats.get("level", 1)
	_update_xp_bar_smooth()
	_update_xp_label()


func _update_xp_bar_visibility() -> void:
	if not _xp_bar_container or not has_node("/root/GameManager"):
		return
	var state = GameManager.current_state
	_xp_bar_container.visible = state == GameManager.GameState.EXPLORATION

# ==========================================================================
# LEVEL-UP POPUP — Animated stat display
# ==========================================================================

func _build_level_popup() -> void:
	_popup_panel = Panel.new()
	_popup_panel.name = "LevelUpPopup"
	_popup_panel.set_anchors_preset(Control.PRESET_CENTER)
	_popup_panel.size = Vector2(320, 220)
	_popup_panel.position = Vector2(-160, -110)
	_popup_panel.pivot_offset = Vector2(160, 110)  # Scale from center, not top-left
	_popup_panel.visible = false
	
	# Style
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.05, 0.08, 0.15, 0.95)
	style.border_color = Color(0.3, 0.7, 1.0, 0.8)
	style.border_width_top = 2
	style.border_width_bottom = 2
	style.border_width_left = 2
	style.border_width_right = 2
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	_popup_panel.add_theme_stylebox_override("panel", style)
	add_child(_popup_panel)
	
	# Title
	_popup_title = Label.new()
	_popup_title.text = "LEVEL UP!"
	_popup_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_popup_title.position = Vector2(10, 15)
	_popup_title.size = Vector2(300, 40)
	_popup_title.add_theme_font_size_override("font_size", 28)
	_popup_title.add_theme_color_override("font_color", Color(1.0, 0.9, 0.3))
	_popup_panel.add_child(_popup_title)
	
	# Stat changes
	_popup_stats = Label.new()
	_popup_stats.text = ""
	_popup_stats.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_popup_stats.position = Vector2(10, 60)
	_popup_stats.size = Vector2(300, 120)
	_popup_stats.add_theme_font_size_override("font_size", 16)
	_popup_stats.add_theme_color_override("font_color", Color(0.8, 0.9, 1.0))
	_popup_panel.add_child(_popup_stats)
	
	# Continue prompt
	_popup_continue = Label.new()
	InputService.bind_text(_popup_continue, "[Press {ui_accept} to continue]")
	_popup_continue.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_popup_continue.position = Vector2(10, 185)
	_popup_continue.size = Vector2(300, 25)
	_popup_continue.add_theme_font_size_override("font_size", 12)
	_popup_continue.add_theme_color_override("font_color", Color(0.5, 0.5, 0.6))
	_popup_panel.add_child(_popup_continue)

# ==========================================================================
# STAT CURVES — Non-linear growth (RPG progression feel)
# ==========================================================================

func _generate_stat_curves():
	## Generate stat growth values per level using non-linear curves.
	## Early levels give big gains, later levels taper off (diminishing returns).
	for i in range(20):  # Support up to lvl 20
		var t = float(i) / 19.0  # 0.0 → 1.0
		# HP curve: starts big (25), tapers (15). Total ~400 HP from 1→20
		_hp_curve.append(int(25 - 10 * t))
		# MP curve: starts 12, tapers to 8. Total ~200 MP
		_mp_curve.append(int(12 - 4 * t))
		# ATK curve: starts 4, tapers to 2
		_atk_curve.append(int(4 - 2 * t))

func get_hp_for_level(level: int) -> int:
	if level <= 0 or level > _hp_curve.size():
		return 15
	return _hp_curve[level - 1]

func get_mp_for_level(level: int) -> int:
	if level <= 0 or level > _mp_curve.size():
		return 8
	return _mp_curve[level - 1]

func get_atk_for_level(level: int) -> int:
	if level <= 0 or level > _atk_curve.size():
		return 2
	return _atk_curve[level - 1]

# ==========================================================================
# EVENTS
# ==========================================================================

func _on_player_leveled_up(new_level: int) -> void:
	## Show animated level-up popup with stat changes.
	# Block if another modal is open (don't interrupt shop/pause/dialogue)
	if ContextStack.any_open():
		# Queue for after current modal closes — just update stats silently
		if OS.is_debug_build():
			print("[LEVEL UI] Level-up popup suppressed — another modal is open")
		_update_xp_bar_smooth()
		_level_label.text = "Lv.%d" % new_level
		return

	# Get curve-based gains
	var hp_gain = get_hp_for_level(new_level)
	var mp_gain = get_mp_for_level(new_level)
	var atk_gain = get_atk_for_level(new_level)
	
	# Build stat text
	var old_hp = GameManager.player_stats.get("max_hp", 100) - hp_gain
	var old_mp = GameManager.player_stats.get("max_mp", 50) - mp_gain
	var old_atk = GameManager.player_stats.get("base_attack", 15) - atk_gain
	
	_popup_title.text = "LEVEL %d!" % new_level
	_popup_stats.text = "  HP:  %d → %d  (+%d)\n  MP:  %d → %d  (+%d)\n  ATK: %d → %d  (+%d)" % [
		old_hp, old_hp + hp_gain, hp_gain,
		old_mp, old_mp + mp_gain, mp_gain,
		old_atk, old_atk + atk_gain, atk_gain
	]
	
	# Show popup with animation
	_popup_panel.visible = true
	_popup_panel.modulate = Color(1, 1, 1, 0)
	_popup_panel.scale = Vector2(0.5, 0.5)
	_popup_visible = true
	_popup_timer = POPUP_DURATION
	SFXManager.play("level_up")

	_kill_popup_tween()
	_popup_tween = create_tween().set_parallel(true)
	_popup_tween.tween_property(_popup_panel, "modulate", Color(1, 1, 1, 1), 0.3).set_ease(Tween.EASE_OUT)
	_popup_tween.tween_property(_popup_panel, "scale", Vector2(1, 1), 0.4).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	
	# Flash XP bar gold
	var bar_tween = create_tween()
	bar_tween.tween_property(_xp_bar_fill, "color", Color(1.0, 0.9, 0.3), 0.2)
	bar_tween.tween_property(_xp_bar_fill, "color", Color(0.2, 0.7, 1.0, 0.9), 0.5)
	
	# Update level label
	_level_label.text = "Lv.%d" % new_level
	
	# Update XP bar for new level
	_update_xp_bar_smooth()
	
	print("[LEVEL UI] Showing level %d popup: +%d HP, +%d MP, +%d ATK" % [new_level, hp_gain, mp_gain, atk_gain])

func _dismiss_popup() -> void:
	_popup_visible = false
	SFXManager.play("ui_confirm")
	_kill_popup_tween()
	_popup_tween = create_tween()
	_popup_tween.tween_property(_popup_panel, "modulate", Color(1, 1, 1, 0), 0.25)
	_popup_tween.tween_callback(func(): _popup_panel.visible = false)

## A new level-up during the dismiss fade must not be hidden by that fade's callback.
func _kill_popup_tween() -> void:
	if _popup_tween and _popup_tween.is_valid():
		_popup_tween.kill()

# ==========================================================================
# XP BAR UPDATE
# ==========================================================================

func _update_xp_bar_instant() -> void:
	## Set XP bar to current value without animation.
	_xp_target_value = GameManager.get_xp_progress()
	_xp_display_value = _xp_target_value
	_xp_bar_fill.size.x = XP_BAR_WIDTH * _xp_display_value
	_level_label.text = "Lv.%d" % GameManager.player_stats.get("level", 1)
	_update_xp_label()

func _update_xp_bar_smooth() -> void:
	## Animate XP bar towards current value.
	_xp_target_value = GameManager.get_xp_progress()

func _update_xp_label() -> void:
	var xp = GameManager.player_stats.get("xp", 0)
	var next = GameManager.get_xp_for_next_level()
	if next < 0:
		_xp_label.text = "%d XP (MAX)" % xp
	else:
		_xp_label.text = "%d / %d XP" % [xp, next]

# Called externally when XP changes
func on_xp_gained(_amount: int) -> void:
	SFXManager.play("xp_gain")
	_update_xp_bar_smooth()
