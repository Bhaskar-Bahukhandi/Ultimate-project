extends CharacterBody2D

## Top-down exploration player controller
## Mechanics: Move (WASD), Sprint (Shift, 1.8x), Interact (E/F), 
##            Data Vision Toggle (Tab), Combat Trigger (J)

const SPEED = 150.0
const SPRINT_SPEED = 270.0  # 1.8x base speed
const SPRINT_STAMINA_DRAIN = 15.0  # Stamina per second while sprinting
const SPRINT_STAMINA_REGEN = 8.0  # Stamina regen per second while not sprinting

@onready var debug_label = get_node_or_null("DebugLabel")
@onready var interaction_area = get_node_or_null("InteractionArea")

var nearby_interactable = null
var nearby_interactables: Array = []  # Track all nearby for cycling
var is_sprinting: bool = false
var stamina: float = 100.0
var max_stamina: float = 100.0

# Data Vision state
var data_vision_active: bool = false
var data_vision_overlay: CanvasLayer = null
var data_vision_labels: Array = []  # Floating labels showing object metadata
var data_vision_timer: float = 0.0  # Track how long DV has been on

# Interaction prompt UI
var interaction_prompt: Label = null
var facing_direction: Vector2 = Vector2.DOWN

# Animation controller
var _anim_controller = null
const _PlayerAnimCtrl = preload("res://scripts/player_animation_controller.gd")

func _ready() -> void:
	add_to_group("player")
	if debug_label:
		debug_label.text = GameManager.player_stats["name"]
	
	# Setup interaction area if it doesn't exist
	if not interaction_area:
		_create_interaction_area()
	
	# Create interaction prompt label
	_create_interaction_prompt()
	
	# Create Data Vision overlay
	_create_data_vision_overlay()
	
	# Setup animation controller
	_anim_controller = _PlayerAnimCtrl.new()
	_anim_controller.set_mode_topdown()
	add_child(_anim_controller)

func _create_interaction_area() -> void:
	## Create an Area2D for detecting nearby interactables
	interaction_area = Area2D.new()
	interaction_area.name = "InteractionArea"
	
	var collision_shape = CollisionShape2D.new()
	var circle_shape = CircleShape2D.new()
	circle_shape.radius = 50.0  # Interaction range
	collision_shape.shape = circle_shape
	
	interaction_area.add_child(collision_shape)
	add_child(interaction_area)
	
	# Connect signals
	interaction_area.area_entered.connect(_on_interactable_nearby)
	interaction_area.body_entered.connect(_on_body_nearby)
	interaction_area.area_exited.connect(_on_interactable_left)
	interaction_area.body_exited.connect(_on_body_left)

func _create_interaction_prompt() -> void:
	## Create floating [F] / [E] prompt that appears near interactable objects
	interaction_prompt = Label.new()
	interaction_prompt.name = "InteractionPrompt"
	interaction_prompt.text = ""
	interaction_prompt.visible = false
	interaction_prompt.add_theme_font_size_override("font_size", 14)
	interaction_prompt.add_theme_color_override("font_color", Color(1.0, 1.0, 0.6))
	interaction_prompt.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.8))
	interaction_prompt.add_theme_constant_override("shadow_offset_x", 1)
	interaction_prompt.add_theme_constant_override("shadow_offset_y", 1)
	interaction_prompt.position = Vector2(-30, -50)
	interaction_prompt.z_index = 10
	add_child(interaction_prompt)

func _create_data_vision_overlay() -> void:
	## Create the Data Vision visual overlay
	data_vision_overlay = CanvasLayer.new()
	data_vision_overlay.name = "DataVisionOverlay"
	data_vision_overlay.layer = 5
	data_vision_overlay.visible = false
	add_child(data_vision_overlay)
	
	# Green-tinted screen overlay
	var overlay_rect = ColorRect.new()
	overlay_rect.name = "OverlayTint"
	overlay_rect.color = Color(0.0, 0.3, 0.0, 0.15)
	overlay_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	data_vision_overlay.add_child(overlay_rect)

func _on_interactable_nearby(area) -> void:
	if area.is_in_group("interactable") or area.is_in_group("npc"):
		nearby_interactable = area
		if area not in nearby_interactables:
			nearby_interactables.append(area)
		_update_interaction_prompt()

func _on_body_nearby(body) -> void:
	if body.is_in_group("interactable") or body.is_in_group("npc"):
		nearby_interactable = body
		if body not in nearby_interactables:
			nearby_interactables.append(body)
		_update_interaction_prompt()
	elif body.is_in_group("enemy"):
		nearby_interactable = body
		if body not in nearby_interactables:
			nearby_interactables.append(body)
		_update_interaction_prompt()

func _on_interactable_left(area) -> void:
	nearby_interactables.erase(area)
	if nearby_interactable == area:
		nearby_interactable = nearby_interactables.back() if nearby_interactables.size() > 0 else null
	_update_interaction_prompt()

func _on_body_left(body) -> void:
	nearby_interactables.erase(body)
	if nearby_interactable == body:
		nearby_interactable = nearby_interactables.back() if nearby_interactables.size() > 0 else null
	_update_interaction_prompt()

func _update_interaction_prompt() -> void:
	## Show/hide the interaction prompt based on nearby objects
	if not interaction_prompt:
		return
	
	if nearby_interactable:
		interaction_prompt.visible = true
		if nearby_interactable.is_in_group("enemy"):
			interaction_prompt.text = "[J] Attack"
			interaction_prompt.add_theme_color_override("font_color", Color(1.0, 0.3, 0.3))
		elif nearby_interactable.is_in_group("npc"):
			interaction_prompt.text = "[F] Talk  [E] Inspect"
			interaction_prompt.add_theme_color_override("font_color", Color(0.6, 1.0, 0.6))
		else:
			interaction_prompt.text = "[F] Interact  [E] Inspect"
			interaction_prompt.add_theme_color_override("font_color", Color(1.0, 1.0, 0.6))
		
		# Add Data Vision hint if DV is unlocked
		if GameManager.story_flags.get("ch1_data_vision_unlocked", false) and not data_vision_active:
			interaction_prompt.text += "\n[TAB] Data Vision"
	else:
		interaction_prompt.visible = false

func _physics_process(delta: float) -> void:
	# Freeze movement while dialogue is active
	if has_node("/root/DialogueManager") and DialogueManager.is_active:
		velocity = Vector2.ZERO
		move_and_slide()
		return

	# Get input direction
	var direction = Vector2.ZERO
	
	if Input.is_action_pressed("move_right"):
		direction.x += 1
	if Input.is_action_pressed("move_left"):
		direction.x -= 1
	if Input.is_action_pressed("move_down"):
		direction.y += 1
	if Input.is_action_pressed("move_up"):
		direction.y -= 1
	
	# Normalize to prevent faster diagonal movement
	if direction != Vector2.ZERO:
		direction = direction.normalized()
		facing_direction = direction
	
	# Sprint handling
	is_sprinting = Input.is_action_pressed("sprint") and stamina > 0 and direction != Vector2.ZERO
	
	# Stamina management
	if is_sprinting:
		stamina -= SPRINT_STAMINA_DRAIN * delta
		stamina = max(stamina, 0)
		if stamina <= 0:
			is_sprinting = false
	else:
		stamina += SPRINT_STAMINA_REGEN * delta
		stamina = min(stamina, max_stamina)
	
	# Apply movement with smooth acceleration/deceleration
	var current_speed = SPRINT_SPEED if is_sprinting else SPEED
	var target_velocity = direction * current_speed
	var accel_weight = 25.0 * delta if direction != Vector2.ZERO else 10.0 * delta
	velocity = velocity.lerp(target_velocity, minf(accel_weight, 1.0))
	move_and_slide()
	
	# Update animation state after movement
	if _anim_controller:
		_anim_controller.update_animation(delta)
	
	# Data Vision timer — System Monitor attention increases
	if data_vision_active:
		data_vision_timer += delta
		if data_vision_timer > 10.0:
			# After 10s, start adding corruption slowly
			if has_node("/root/GameManager"):
				GameManager.add_glitch_corruption(0.1 * delta)
	
	# Update Data Vision floating labels positions (if active)
	if data_vision_active:
		_update_data_vision_labels()

func _input(event: InputEvent) -> void:
	# Block all interaction input while dialogue is active
	if has_node("/root/DialogueManager") and DialogueManager.is_active:
		return

	# Interaction input — E key (root_access) or F key (interact)
	if (event.is_action_pressed("root_access") or event.is_action_pressed("interact")) and nearby_interactable:
		_interact_with(nearby_interactable)
		get_viewport().set_input_as_handled()
		return
	
	# Data Vision toggle — Tab key
	if event.is_action_pressed("data_vision"):
		if GameManager.story_flags.get("ch1_data_vision_unlocked", false):
			_toggle_data_vision()
		else:
			if OS.is_debug_build():
				print("[DATA VISION] Not yet unlocked")
		get_viewport().set_input_as_handled()
		return
	
	# Combat trigger (J key)
	if event.is_action_pressed("attack"):
		if nearby_interactable and (nearby_interactable.is_in_group("enemy") or nearby_interactable.name.contains("Slime")):
			trigger_combat()
			get_viewport().set_input_as_handled()

func _interact_with(interactable) -> void:
	if has_node("/root/SFXManager"):
		SFXManager.play("ui_confirm")
	if OS.is_debug_build():
		print("[INTERACTION] Interacting with: ", interactable.name)
	
	# Priority 1: Direct interact method on the interactable
	if interactable.has_method("interact"):
		interactable.interact(self)
		return
	
	# Priority 2: Send interaction signal to parent scene
	var parent = get_parent()
	if parent.has_method("_on_" + interactable.name.to_lower() + "_interaction"):
		parent.call("_on_" + interactable.name.to_lower() + "_interaction", self)
	else:
		# Fallback: show a message if DialogueManager is available
		if has_node("/root/DialogueManager"):
			DialogueManager.say("System", "Nothing interesting happens.")
		else:
			if OS.is_debug_build():
				print("[INTERACTION] No handler for: ", interactable.name)

func _toggle_data_vision() -> void:
	## Toggle Data Vision overlay — shows object metadata
	data_vision_active = !data_vision_active
	
	if data_vision_active:
		data_vision_overlay.visible = true
		data_vision_timer = 0.0
		if has_node("/root/SFXManager"):
			SFXManager.play("data_vision_on")
		_spawn_data_vision_labels()
		if OS.is_debug_build():
			print("[DATA VISION] Activated — System Monitor awareness increasing")
	else:
		data_vision_overlay.visible = false
		if has_node("/root/SFXManager"):
			SFXManager.play("data_vision_off")
		_clear_data_vision_labels()
		if OS.is_debug_build():
			print("[DATA VISION] Deactivated")

func _spawn_data_vision_labels() -> void:
	## Create floating green labels showing object metadata
	_clear_data_vision_labels()
	
	# Scan nearby objects and create labels
	var all_bodies = get_tree().get_nodes_in_group("interactable") + get_tree().get_nodes_in_group("npc") + get_tree().get_nodes_in_group("enemy")
	
	for obj in all_bodies:
		if not is_instance_valid(obj):
			continue
		if not obj is Node2D:
			continue
		
		# Check distance
		var dist = global_position.distance_to(obj.global_position)
		if dist > 300:
			continue
		
		# Create metadata label
		var label = Label.new()
		label.add_theme_font_size_override("font_size", 10)
		label.add_theme_color_override("font_color", Color(0.0, 1.0, 0.0, 0.9))
		
		# Build metadata text based on object type
		var meta_text = "[ID: %s]\n" % obj.name
		if obj.is_in_group("enemy"):
			meta_text += "[Type: HOSTILE]\n[Tag: HACKABLE]\n"
			if obj.has_method("get_hp"):
				meta_text += "[HP: %d]\n" % obj.get_hp()
		elif obj.is_in_group("npc"):
			meta_text += "[Type: NPC]\n[AI: IDLE_LOOP]\n"
		else:
			meta_text += "[Type: INTERACTABLE]\n"
		
		label.text = meta_text
		var screen_pos = obj.get_global_transform_with_canvas().origin
		label.position = screen_pos + Vector2(-20, -60)
		data_vision_overlay.add_child(label)
		data_vision_labels.append({"label": label, "target": obj})

func _update_data_vision_labels() -> void:
	## Update positions of floating Data Vision labels
	for entry in data_vision_labels:
		if is_instance_valid(entry["label"]) and is_instance_valid(entry["target"]):
			var screen_pos = entry["target"].get_global_transform_with_canvas().origin
			entry["label"].position = screen_pos + Vector2(-20, -60)

func _clear_data_vision_labels() -> void:
	## Remove all floating Data Vision labels
	for entry in data_vision_labels:
		if is_instance_valid(entry["label"]):
			entry["label"].queue_free()
	data_vision_labels.clear()

func trigger_combat() -> void:
	# Transition to combat mode
	if has_node("/root/SFXManager"):
		SFXManager.play("transition_whoosh")
	if OS.is_debug_build():
		print("[COMBAT] Triggering combat!")
	if has_node("/root/SceneTransitions"):
		SceneTransitions.change_scene("res://scenes/combat/combat_arena.tscn", SceneTransitions.TransitionStyle.COMBAT_ENTRY)
	else:
		get_tree().change_scene_to_file("res://scenes/combat/combat_arena.tscn")

func get_stamina_percent() -> float:
	return (stamina / maxf(max_stamina, 0.01)) * 100.0
