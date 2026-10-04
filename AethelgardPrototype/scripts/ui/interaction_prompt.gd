extends CanvasLayer

## Interaction Prompt UI
## Shows contextual floating prompts near interactable objects
## Supports: NPCs, items, doors, enemies, hackable objects
## Integrates with Data Vision for enhanced metadata display

const PROMPT_OFFSET = Vector2(0, -70)  # Above the object
const FADE_SPEED = 5.0
const BOB_AMPLITUDE = 3.0
const BOB_SPEED = 2.5

@onready var prompt_panel: PanelContainer = null
@onready var prompt_label: RichTextLabel = null
@onready var detail_label: Label = null

var current_target: Node = null
var is_visible_prompt: bool = false
var bob_time: float = 0.0
var target_alpha: float = 0.0
var _cached_panel_style: StyleBoxFlat = null

# Prompt templates by interaction type. {action} tokens become the player's
# current key/button (InputService.fmt) when shown.
var prompt_templates = {
	"npc": {
		"keys": "[{interact}] Talk",
		"inspect": "[{root_access}] Inspect",
		"color": Color(0.6, 1.0, 0.6),
		"icon": ">>",
	},
	"shop": {
		"keys": "[{interact}] Browse",
		"inspect": "[{root_access}] Check Prices",
		"color": Color(1.0, 0.9, 0.4),
		"icon": "$>",
	},
	"item": {
		"keys": "[{interact}] Pick Up",
		"inspect": "[{root_access}] Examine",
		"color": Color(0.4, 0.8, 1.0),
		"icon": "?>",
	},
	"door": {
		"keys": "[{interact}] Enter",
		"inspect": "[{root_access}] Check",
		"color": Color(0.8, 0.6, 1.0),
		"icon": "|>",
	},
	"enemy": {
		"keys": "[{attack}] Attack",
		"inspect": "[{root_access}] Scan",
		"color": Color(1.0, 0.3, 0.3),
		"icon": "!>",
	},
	"hackable": {
		"keys": "[{root_access}] Root Access",
		"inspect": "[{data_vision}] Data Vision",
		"color": Color(0.0, 1.0, 0.5),
		"icon": "#>",
	},
	"default": {
		"keys": "[{interact}] Interact",
		"inspect": "[{root_access}] Inspect",
		"color": Color(1.0, 1.0, 0.6),
		"icon": ">>",
	}
}

func _ready() -> void:
	layer = 10
	_build_prompt_ui()

func _build_prompt_ui() -> void:
	## Construct the prompt UI programmatically
	# Main container — positioned in world space via _process
	prompt_panel = PanelContainer.new()
	prompt_panel.name = "PromptPanel"
	prompt_panel.visible = false
	prompt_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	# Style the panel
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.05, 0.05, 0.1, 0.85)
	style.border_color = Color(0.3, 0.8, 0.3, 0.7)
	style.border_width_bottom = 1
	style.border_width_top = 1
	style.border_width_left = 1
	style.border_width_right = 1
	style.corner_radius_top_left = 4
	style.corner_radius_top_right = 4
	style.corner_radius_bottom_left = 4
	style.corner_radius_bottom_right = 4
	style.content_margin_left = 10
	style.content_margin_right = 10
	style.content_margin_top = 5
	style.content_margin_bottom = 5
	prompt_panel.add_theme_stylebox_override("panel", style)
	
	var vbox = VBoxContainer.new()
	vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	# Main prompt text
	prompt_label = RichTextLabel.new()
	prompt_label.name = "PromptText"
	prompt_label.bbcode_enabled = true
	prompt_label.fit_content = true
	prompt_label.scroll_active = false
	prompt_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	prompt_label.add_theme_font_size_override("normal_font_size", 13)
	prompt_label.custom_minimum_size = Vector2(120, 0)
	vbox.add_child(prompt_label)
	
	# Detail line (object name / metadata)
	detail_label = Label.new()
	detail_label.name = "DetailText"
	detail_label.add_theme_font_size_override("font_size", 12)
	detail_label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.6))
	detail_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(detail_label)
	
	prompt_panel.add_child(vbox)
	add_child(prompt_panel)

func _process(delta: float) -> void:
	bob_time += delta
	
	# Fade prompt in/out
	var current_alpha = prompt_panel.modulate.a
	if is_visible_prompt:
		current_alpha = move_toward(current_alpha, 1.0, FADE_SPEED * delta)
	else:
		current_alpha = move_toward(current_alpha, 0.0, FADE_SPEED * delta)
		if current_alpha <= 0.01:
			prompt_panel.visible = false
			return
	prompt_panel.modulate.a = current_alpha
	
	# Position above target
	if current_target and is_instance_valid(current_target) and current_target is Node2D:
		var screen_pos = current_target.get_global_transform_with_canvas().origin
		var bob_offset = Vector2(0, sin(bob_time * BOB_SPEED) * BOB_AMPLITUDE)
		prompt_panel.position = screen_pos + PROMPT_OFFSET + bob_offset
		# Center horizontally
		prompt_panel.position.x -= prompt_panel.size.x * 0.5

func show_prompt(target: Node, interaction_type: String = "default") -> void:
	## Show interaction prompt near a target object
	current_target = target
	is_visible_prompt = true
	prompt_panel.visible = true
	
	# Get template
	var template = prompt_templates.get(interaction_type, prompt_templates["default"])
	
	# Build prompt text
	var color_hex = template["color"].to_html(false)
	var bbcode = "[color=#%s]%s %s[/color]" % [color_hex, template["icon"], _bb_escape(InputService.fmt(template["keys"]))]

	# Add inspect line if different from main action
	if template.has("inspect"):
		bbcode += "\n[color=#888888]%s[/color]" % _bb_escape(InputService.fmt(template["inspect"]))
	
	prompt_label.text = ""
	prompt_label.parse_bbcode(bbcode)
	
	# Detail line — object name
	var detail_name = str(target.name) if target else "???"
	if target and target.has_meta("display_name"):
		detail_name = target.get_meta("display_name")
	detail_label.text = "< %s >" % detail_name
	
	# Tint border based on type
	if not _cached_panel_style:
		_cached_panel_style = prompt_panel.get_theme_stylebox("panel").duplicate()
	_cached_panel_style.border_color = template["color"] * Color(1, 1, 1, 0.7)
	prompt_panel.add_theme_stylebox_override("panel", _cached_panel_style)

## "[B] Talk" must show brackets, not start a BBCode tag.
static func _bb_escape(text: String) -> String:
	return text.replace("[", "\u0001").replace("]", "[rb]").replace("\u0001", "[lb]")

func hide_prompt() -> void:
	## Fade out the prompt
	is_visible_prompt = false
	current_target = null

func show_custom_prompt(target: Node, text: String, color: Color = Color(1, 1, 1)) -> void:
	## Show a custom prompt with arbitrary text
	current_target = target
	is_visible_prompt = true
	prompt_panel.visible = true
	
	var color_hex = color.to_html(false)
	prompt_label.text = ""
	prompt_label.parse_bbcode("[color=#%s]%s[/color]" % [color_hex, text])
	detail_label.text = ""
	
	if not _cached_panel_style:
		_cached_panel_style = prompt_panel.get_theme_stylebox("panel").duplicate()
	_cached_panel_style.border_color = color * Color(1, 1, 1, 0.7)
	prompt_panel.add_theme_stylebox_override("panel", _cached_panel_style)

func show_data_vision_prompt(target: Node, metadata: Dictionary) -> void:
	## Show enhanced metadata prompt when Data Vision is active
	current_target = target
	is_visible_prompt = true
	prompt_panel.visible = true
	
	var bbcode = "[color=#00ff66]╔═ DATA VISION ═╗[/color]\n"
	bbcode += "[color=#00cc44]ID: %s[/color]\n" % metadata.get("id", target.name)
	
	if metadata.has("type"):
		bbcode += "[color=#00aa33]Type: %s[/color]\n" % metadata["type"]
	if metadata.has("hp"):
		bbcode += "[color=#ff6644]HP: %s[/color]\n" % str(metadata["hp"])
	if metadata.has("hackable"):
		var hack_color = "#00ff00" if metadata["hackable"] else "#666666"
		bbcode += "[color=%s]HACKABLE: %s[/color]\n" % [hack_color, str(metadata["hackable"]).to_upper()]
	if metadata.has("hidden"):
		bbcode += "[color=#ffaa00]HIDDEN: %s[/color]\n" % str(metadata["hidden"]).to_upper()
	
	bbcode += "[color=#00ff66]╚═══════════════╝[/color]"
	
	prompt_label.text = ""
	prompt_label.parse_bbcode(bbcode)
	detail_label.text = "[Layer: %s]" % metadata.get("layer", "default")
	
	if not _cached_panel_style:
		_cached_panel_style = prompt_panel.get_theme_stylebox("panel").duplicate()
	_cached_panel_style.border_color = Color(0.0, 1.0, 0.4, 0.8)
	prompt_panel.add_theme_stylebox_override("panel", _cached_panel_style)
