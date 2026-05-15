# Quick Reference - Cinematic Framework Usage

## 🎬 Adding Cinematics to ANY Scene

This framework is reusable across your entire game. Here's how to add cinematics to any scene in under 10 minutes.

---

## Step 1: Add Core Nodes to Scene

In your .tscn scene tree, add:
```
YourScene (Control or Node2D)
├── CinematicCamera (Camera2D with cinematic_camera.gd)
├── CutsceneManager (Node with cutscene_manager.gd)
└── ScreenTransition (Control with screen_transition.gd)
```

Add these layers for organization:
```
├── BackgroundLayer (CanvasLayer, layer=-100)
├── ParticlesLayer (CanvasLayer, layer=-50)
├── SceneLayer (Node2D or CanvasLayer, layer=0)
├── CharactersLayer (Node2D for character positioning)
├── UILayer (CanvasLayer, layer=100)
└── EffectsLayer (CanvasLayer, layer=200)
```

---

## Step 2: Connect Nodes in Script

```gdscript
extends Control

@onready var camera: CinematicCamera = $CinematicCamera
@onready var cutscene_mgr: CutsceneManager = $CutsceneManager
@onready var transition: ScreenTransition = $ScreenTransition
@onready var characters: Node2D = $CharactersLayer
@onready var dialogue_box: Control = $UILayer/DialogueBox  # if you have one

func _ready():
	# Connect cutscene manager
	cutscene_mgr.camera = camera
	cutscene_mgr.dialogue_box = dialogue_box
	cutscene_mgr.characters_container = characters
	
	# Activate camera
	camera.smooth_enabled = true
	camera.smooth_speed = 4.0
	camera.make_current()
	
	# Start your scene
	start_scene()

func start_scene():
	# Fade in
	await transition.transition_in(ScreenTransition.TransitionType.FADE, 1.0)
	
	# Play cutscene
	var cutscene = create_your_cutscene()
	cutscene_mgr.play_cutscene(cutscene)
	await cutscene_mgr.cutscene_finished
	
	# Continue with gameplay...
```

---

## Step 3: Define Your Cutscene

Create a function that returns a Dictionary with your beats:

```gdscript
func create_your_cutscene() -> Dictionary:
	return {
		"name": "My Cutscene",
		"beats": [
			# Beat 1: Establishing shot
			{
				"type": "camera_move",
				"target": Vector2(640, 360),  # Center screen
				"duration": 1.0
			},
			
			# Beat 2: Zoom in
			{
				"type": "camera_zoom",
				"zoom": Vector2(1.5, 1.5),
				"duration": 2.0
			},
			
			# Beat 3: Character appears
			{
				"type": "character_enter",
				"character": "Hero",
				"position": Vector2(400, 400),
				"from": "left",
				"duration": 2.0
			},
			
			# Beat 4: Dialogue
			{
				"type": "dialogue",
				"speaker": "Hero",
				"text": "This place... feels wrong.",
				"auto_advance": false  # Wait for player input
			},
			
			# Beat 5: Camera shake (danger!)
			{
				"type": "camera_shake",
				"intensity": 20.0,
				"duration": 1.5
			},
			
			# Beat 6: Multiple things at once
			{
				"type": "parallel",
				"beats": [
					{
						"type": "character_move",
						"character": "Hero",
						"target": Vector2(640, 400),
						"duration": 2.0
					},
					{
						"type": "camera_move",
						"target": Vector2(640, 360),
						"duration": 2.0
					}
				]
			},
			
			# Beat 7: Wait for tension
			{
				"type": "wait",
				"duration": 1.5
			},
			
			# Beat 8: Screen flash effect
			{
				"type": "effect",
				"effect": "flash",
				"color": Color.RED,
				"duration": 0.3
			}
		]
	}
```

---

## 🎯 Beat Type Quick Reference

### camera_move
Move camera to position smoothly
```gdscript
{
	"type": "camera_move",
	"target": Vector2(x, y),  # Absolute position in world
	"duration": 2.0
}
```

### camera_zoom
Change zoom level
```gdscript
{
	"type": "camera_zoom",
	"zoom": Vector2(2.0, 2.0),  # 2x zoom
	"duration": 1.5
}
```

### camera_shake
Shake camera for impact
```gdscript
{
	"type": "camera_shake",
	"intensity": 15.0,  # Higher = more violent
	"duration": 1.0
}
```

### character_enter
Bring character on screen
```gdscript
{
	"type": "character_enter",
	"character": "CharacterName",
	"position": Vector2(400, 450),
	"from": "left",  # or "right", "top", "bottom"
	"duration": 2.0
}
```

### character_exit
Remove character from screen
```gdscript
{
	"type": "character_exit",
	"character": "CharacterName",
	"to": "right",  # or "left", "top", "bottom"
	"duration": 1.5
}
```

### character_move
Move character to new position
```gdscript
{
	"type": "character_move",
	"character": "CharacterName",
	"target": Vector2(640, 400),
	"duration": 1.5
}
```

### dialogue
Show dialogue text
```gdscript
{
	"type": "dialogue",
	"speaker": "Character Name",
	"text": "What they say...",
	"auto_advance": false  # If true, continues automatically after duration
}
```

### wait
Pause for dramatic timing
```gdscript
{
	"type": "wait",
	"duration": 2.0
}
```

### effect
Trigger visual effect
```gdscript
{
	"type": "effect",
	"effect": "flash",  # or "shake_screen", or custom
	"color": Color.WHITE,  # For flash effect
	"duration": 0.5
}
```

### fade
Fade screen in/out
```gdscript
{
	"type": "fade",
	"fade_type": "out",  # or "in"
	"color": Color.BLACK,
	"duration": 1.0
}
```

### parallel
Execute multiple beats simultaneously
```gdscript
{
	"type": "parallel",
	"beats": [
		{ "type": "camera_move", ... },
		{ "type": "character_move", ... },
		{ "type": "effect", ... }
	]
}
```

### custom
Call your own function
```gdscript
{
	"type": "custom",
	"callback": "my_function_name"
}

# In your script:
func my_function_name():
	print("Custom beat executed!")
	await get_tree().create_timer(1.0).timeout
```

---

## 🎨 Adding Shaders to Objects

### CRT Effect (Background)
```gdscript
# In scene or code:
var background = $BackgroundLayer/Background  # ColorRect
var crt_shader = load("res://shaders/crt_effect.gdshader")
var material = ShaderMaterial.new()
material.shader = crt_shader
material.set_shader_parameter("distortion", 0.08)
material.set_shader_parameter("scanline_intensity", 0.12)
material.set_shader_parameter("scanline_count", 720.0)
material.set_shader_parameter("vignette", 0.25)
background.material = material
```

### Glitch Effect (Overlay)
```gdscript
var overlay = $EffectsLayer/GlitchOverlay  # ColorRect
var glitch_shader = load("res://shaders/advanced_glitch.gdshader")
var material = ShaderMaterial.new()
material.shader = glitch_shader
material.set_shader_parameter("glitch_strength", 0.5)
overlay.material = material
overlay.visible = true  # Toggle when needed
```

### Hologram Effect (Characters)
```gdscript
var character = $CharactersLayer/Hero  # ColorRect
var hologram_shader = load("res://shaders/hologram.gdshader")
var material = ShaderMaterial.new()
material.shader = hologram_shader
material.set_shader_parameter("scanline_speed", 2.0)
material.set_shader_parameter("distortion_amount", 0.02)
material.set_shader_parameter("glow_strength", 0.3)
material.set_shader_parameter("base_color", Color(0.4, 0.7, 1.0))
character.material = material
```

---

## 🌟 Adding Particles

### Method 1: Use EnhancedParticleSystem Helper
```gdscript
# Import the class
const EnhancedParticleSystem = preload("res://scripts/effects/particle_system.gd")

func add_dust_particles():
	var particles = CPUParticles2D.new()
	EnhancedParticleSystem.setup_dust(particles)
	particles.position = Vector2(640, 360)
	particles.emitting = true
	$ParticlesLayer.add_child(particles)

func add_sparks():
	var particles = CPUParticles2D.new()
	EnhancedParticleSystem.setup_sparks(particles)
	particles.position = Vector2(800, 300)
	particles.one_shot = true
	particles.emitting = true
	$ParticlesLayer.add_child(particles)
```

### Method 2: Add in Scene Editor
1. Add CPUParticles2D to ParticlesLayer
2. Set properties:
   - Amount: 30-50
   - Lifetime: 1.0-3.0
   - Emission shape: Rectangle or Sphere
   - Direction: Vector2(0, 1) for falling
   - Gravity: Vector2(0, 20) for physics
   - Initial velocity: 50-100
   - Scale: 2-5
   - Color: Choose atmospheric color

### Available Particle Types
```gdscript
EnhancedParticleSystem.setup_sparks(particles)     # Orange impact sparks
EnhancedParticleSystem.setup_smoke(particles)      # Rising smoke
EnhancedParticleSystem.setup_glitch(particles)     # Digital corruption
EnhancedParticleSystem.setup_magic(particles)      # Purple energy
EnhancedParticleSystem.setup_dust(particles)       # Ambient particles
EnhancedParticleSystem.setup_rain(particles)       # Weather
EnhancedParticleSystem.setup_snow(particles)       # Cold weather
EnhancedParticleSystem.setup_fire(particles)       # Flames
```

---

## 🔄 Screen Transitions

### Transition Between Scenes
```gdscript
# Fade out, change scene, fade in:
await transition.scene_transition(
	"res://scenes/next_scene.tscn",
	ScreenTransition.TransitionType.FADE,
	1.0  # Duration
)
```

### Available Transition Types
```gdscript
ScreenTransition.TransitionType.FADE           # Classic fade to black
ScreenTransition.TransitionType.WIPE_LEFT      # Wipe left to right
ScreenTransition.TransitionType.WIPE_RIGHT     # Wipe right to left
ScreenTransition.TransitionType.WIPE_UP        # Wipe up
ScreenTransition.TransitionType.WIPE_DOWN      # Wipe down
ScreenTransition.TransitionType.CIRCLE_IN      # Circle closes
ScreenTransition.TransitionType.CIRCLE_OUT     # Circle opens
ScreenTransition.TransitionType.PIXELATE       # Pixelated dissolve
ScreenTransition.TransitionType.GLITCH         # Digital glitch
ScreenTransition.TransitionType.SHATTER        # Screen shatters
```

### Manual Transition Control
```gdscript
# Transition out
await transition.transition_out(
	ScreenTransition.TransitionType.GLITCH,
	1.5
)

# Do something during black screen
await get_tree().create_timer(0.5).timeout

# Transition in
await transition.transition_in(
	ScreenTransition.TransitionType.FADE,
	2.0
)
```

---

## 📷 Camera Control Directly

You can also control the camera directly outside of cutscenes:

```gdscript
# Move camera
camera.move_to(Vector2(800, 400), 2.0)
await camera.camera_move_finished

# Zoom camera
camera.zoom_to(Vector2(2.0, 2.0), 1.5)
await camera.zoom_finished

# Shake camera (impact)
camera.impact_shake()

# Shake camera (explosion)
camera.explosion_shake()

# Shake camera (earthquake)
camera.earthquake_shake(3.0)  # 3 seconds

# Focus on a node
var target = $CharactersLayer/Hero
camera.focus_on(target, 1.5)

# Dolly shot (zoom in while moving)
camera.dolly_shot(Vector2(640, 360), Vector2(1.5, 1.5), 2.5)

# Dutch angle (tilt)
camera.dutch_angle(10.0, 1.0)  # 10 degrees over 1 second

# Reset everything
camera.reset_camera(1.5)
```

---

## 🎯 Complete Mini-Example Scene

Here's a complete, copy-paste scene script you can use as a template:

```gdscript
extends Control

@onready var camera: CinematicCamera = $CinematicCamera
@onready var cutscene_mgr: CutsceneManager = $CutsceneManager
@onready var transition: ScreenTransition = $ScreenTransition

func _ready():
	# Setup
	cutscene_mgr.camera = camera
	cutscene_mgr.characters_container = $CharactersLayer
	camera.make_current()
	
	# Start
	await get_tree().create_timer(0.5).timeout
	start_scene()

func start_scene():
	# Fade in from black
	await transition.transition_in(ScreenTransition.TransitionType.FADE, 2.0)
	
	# Play cutscene
	var cutscene = {
		"name": "Opening",
		"beats": [
			{
				"type": "camera_move",
				"target": Vector2(640, 360),
				"duration": 0.5
			},
			{
				"type": "character_enter",
				"character": "Hero",
				"position": Vector2(640, 450),
				"from": "bottom",
				"duration": 2.0
			},
			{
				"type": "wait",
				"duration": 1.0
			},
			{
				"type": "camera_zoom",
				"zoom": Vector2(1.5, 1.5),
				"duration": 2.0
			}
		]
	}
	
	cutscene_mgr.play_cutscene(cutscene)
	await cutscene_mgr.cutscene_finished
	
	# Continue with gameplay
	print("Cutscene complete! Starting gameplay...")
```

---

## 💡 Pro Tips

### 1. Always Use Parallel for Multi-Element Scenes
Instead of:
```gdscript
# BAD: Sequential (feels slow)
{"type": "character_move", ...}
{"type": "camera_move", ...}
```

Do this:
```gdscript
# GOOD: Parallel (feels dynamic)
{
	"type": "parallel",
	"beats": [
		{"type": "character_move", ...},
		{"type": "camera_move", ...}
	]
}
```

### 2. Add Waits for Dramatic Timing
```gdscript
{"type": "dialogue", "text": "No... it can't be..."},
{"type": "wait", "duration": 1.5},  # Let it sink in
{"type": "camera_shake", "intensity": 20.0, ...}
```

### 3. Combine Zoom + Move for Dolly Shots
```gdscript
{
	"type": "parallel",
	"beats": [
		{"type": "camera_move", "target": Vector2(640, 360), "duration": 3.0},
		{"type": "camera_zoom", "zoom": Vector2(2.0, 2.0), "duration": 3.0}
	]
}
# This creates a zoom-in while moving (dolly effect)
```

### 4. Use Custom Beats for Unique Effects
```gdscript
{"type": "custom", "callback": "trigger_lightning"}

func trigger_lightning():
	$EffectsLayer/Flash.modulate.a = 1.0
	var tween = create_tween()
	tween.tween_property($EffectsLayer/Flash, "modulate:a", 0.0, 0.2)
	await tween.finished
```

### 5. Layer Particles for Depth
```gdscript
# Background particles (slow, big, blurry)
var bg_dust = CPUParticles2D.new()
EnhancedParticleSystem.setup_dust(bg_dust)
bg_dust.scale_amount_max = 8.0
bg_dust.initial_velocity_max = 10.0

# Foreground particles (fast, small, sharp)
var fg_dust = CPUParticles2D.new()
EnhancedParticleSystem.setup_dust(fg_dust)
fg_dust.scale_amount_max = 2.0
fg_dust.initial_velocity_max = 50.0
```

---

## 🚀 That's It!

You now know how to add professional cinematics to any scene in your game. The framework handles all the complex timing, coordination, and sequencing.

**Time to add cinematic cutscene: ~10 minutes**

Just remember:
1. Add the 3 core nodes (Camera, CutsceneManager, Transition)
2. Connect them in _ready()
3. Define your beats array
4. Call play_cutscene()

🎬 **Go make every scene cinematic!**
