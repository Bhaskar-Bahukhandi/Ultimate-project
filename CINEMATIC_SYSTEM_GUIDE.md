# AETHELGARD — COMPLETE ASSET INTEGRATION GUIDE

> **Purpose**: Organized reference for every visual asset in the game. All sprite names, animation names, and file paths match the code exactly — add your assets with these names and they will automatically replace the procedural placeholders. No code changes needed.

---

# TABLE OF CONTENTS

1. [General Overview](#1-general-overview)
2. [Title Screen & Main Menu](#2-title-screen--main-menu)
3. [Characters](#3-characters)
   - [3.1 Kaelen (Player)](#31-kaelen--player-character)
   - [3.2 Elara (Glitch-Witch)](#32-elara--glitch-witch-companion)
   - [3.3 Mira (Flight Attendant)](#33-mira--flight-attendant)
   - [3.4 Tutorial Knight (Boss)](#34-tutorial-knight--chapter-1-boss)
   - [3.5 Green Slime (Enemy)](#35-green-slime--tutorial-enemy)
   - [3.6 Corrupted Boar (Enemy)](#36-corrupted-boar--elite-enemy)
   - [3.7 Village NPCs](#37-village-npcs)
4. [Backgrounds & Environments](#4-backgrounds--environments)
   - [4.1 Flight 707 (Prologue)](#41-flight-707--airplane-cabin)
   - [4.2 Crash Sequence (Prologue)](#42-crash-sequence--boot-screen)
   - [4.3 Glitch Crater](#43-glitch-crater--awakening)
   - [4.4 Forest Clearing (Elara Meeting)](#44-forest-clearing--elara-meeting)
   - [4.5 Path to Oakhaven](#45-path-to-oakhaven)
   - [4.6 Oakhaven Village](#46-oakhaven-village)
   - [4.7 Tutorial Knight Arena](#47-tutorial-knight-arena)
   - [4.8 Shatter Bridge](#48-shatter-bridge--chapter-transition)
   - [4.9 Combat Arena](#49-combat-arena)
   - [4.10 Environment Animations](#410-environment-animations)
   - [4.11 Tilesets](#411-tilesets)
5. [Visual Effects (VFX)](#5-visual-effects-vfx)
   - [5.1 Particle Effects](#51-particle-effects-cpuparticles2d)
   - [5.2 VFX Animations](#52-vfx-sprite-animations)
   - [5.3 Geometric Effects](#53-geometric-effects-tween-based)
   - [5.4 Text VFX](#54-text-based-vfx)
   - [5.5 Color Flashes & Overlays](#55-color-flashes--overlays)
   - [5.6 Screen Transitions](#56-screen-transitions)
6. [Shaders](#6-shaders)
7. [UI Elements](#7-ui-elements)
   - [7.1 Dialogue System](#71-dialogue-system)
   - [7.2 Combat HUD](#72-combat-hud)
   - [7.3 Interaction Prompts](#73-interaction-prompts)
   - [7.4 Status Window](#74-status-window)
   - [7.5 Pause Screen](#75-pause-screen)
   - [7.6 Root Access UI](#76-root-access-ui)
   - [7.7 UI Animations](#77-ui-animations)
8. [Camera System](#8-camera-system)
9. [Audio (Placeholder)](#9-audio-placeholder)
10. [Technical Reference](#10-technical-reference)
    - [10.1 Sprite Sheet Creation](#101-sprite-sheet-creation-guide)
    - [10.2 Import Settings](#102-godot-import-settings)
    - [10.3 Frame Counts](#103-frame-counts-reference)
    - [10.4 Sprite Sizes](#104-sprite-sizes-reference)
    - [10.5 Animation FPS](#105-animation-fps-reference)
    - [10.6 Autoloads](#106-autoload-registry)
    - [10.7 Input Mappings](#107-input-mappings)
    - [10.8 Scene Flow](#108-scene-flow)
    - [10.9 Story Flags](#109-story-flags)
    - [10.10 File Reference](#1010-file-reference)
    - [10.11 Integration Checklist](#1011-integration-checklist)

---

# 1. GENERAL OVERVIEW

## How the Placeholder System Works

The game currently uses **procedural placeholders** for all visuals — no actual sprite assets are needed to run it. Three systems handle this:

| System | Script | What It Does |
|---|---|---|
| **PlaceholderSprite** | `scripts/effects/placeholder_sprite.gd` | Creates multi-part ColorRect bodies (head, torso, limbs, etc.) for each character |
| **TweenAnimator** | `scripts/effects/tween_animator.gd` | Plays tween-based animations (bob, squash, stretch, flash) on placeholder sprites |
| **VFXLibrary** | `scripts/effects/vfx_library.gd` | Spawns CPUParticles2D effects procedurally (sparks, dust, healing rings, etc.) |

## Drop-In Replacement Workflow

When you create real sprites:

1. Create a **SpriteFrames** resource (`.tres`)
2. Add animations using the **exact names** listed in this guide
3. Replace the placeholder `ColorRect`/`Node2D` with an `AnimatedSprite2D` in the scene
4. Assign the SpriteFrames resource
5. The existing code references `AnimConst` constants which resolve to these exact string names — everything plays automatically

All animation name constants live in `scripts/animation_constants.gd` (class `AnimConst`).

## Asset File Paths

When you add real textures, place them at these paths. The `AssetManager` (`scripts/asset_manager.gd`) looks for them here:

### Character Sprites
| Key | Expected Path |
|---|---|
| `"player"` | `res://assets/sprites/player/player.png` |
| `"slime_green"` | `res://assets/sprites/enemies/oakhaven/slime.png` |
| `"boar_corrupted"` | `res://assets/sprites/enemies/oakhaven/boar.png` |
| `"knight_tutorial"` | `res://assets/sprites/bosses/oakhaven/knight.png` |
| `"arachnid_clockwork"` | `res://assets/sprites/enemies/ironhold/spider.png` |
| `"sentinel_steam"` | `res://assets/sprites/enemies/ironhold/turret.png` |
| `"gear_hulk"` | `res://assets/sprites/bosses/ironhold/hulk.png` |
| `"bone_construct"` | `res://assets/sprites/enemies/necropolis/skeleton.png` |
| `"wraith"` | `res://assets/sprites/enemies/necropolis/wraith.png` |
| `"lich_lord"` | `res://assets/sprites/bosses/necropolis/lich.png` |

### Tilesets
| Key | Expected Path |
|---|---|
| `"tileset_oakhaven"` | `res://assets/tilesets/oakhaven/sprout_lands.png` |
| `"tileset_oakhaven_forest"` | `res://assets/tilesets/oakhaven/mystic_woods.png` |
| `"tileset_ironhold"` | `res://assets/tilesets/ironhold/steampunk.png` |
| `"tileset_necropolis"` | `res://assets/tilesets/necropolis/gothicvania.png` |
| `"tileset_celestia"` | `res://assets/tilesets/celestia/floating_islands.png` |
| `"tileset_deepblue"` | `res://assets/tilesets/deepblue/underwater.png` |

### Backgrounds
| Key | Expected Path |
|---|---|
| `"bg_celestia_sky"` | `res://assets/backgrounds/celestia/clouds.png` |
| `"bg_deepblue"` | `res://assets/backgrounds/deepblue/ocean.png` |

### UI Assets
| Key | Expected Path |
|---|---|
| `"ui_frame"` | `res://assets/ui/frame.png` |
| `"ui_button"` | `res://assets/ui/button.png` |

---

# 2. TITLE SCREEN & MAIN MENU

## Main Menu

**Scene**: `scenes/main_menu.tscn` | **Script**: `scripts/main_menu.gd`

### Visual Description
- **Background**: Solid dark `Color(0.1, 0.1, 0.15)` — replace with a title art background image
- **Title Text**: Game title displayed prominently — replace with a logo sprite
- **Menu Buttons**: Start Game, Continue, Options, Quit — currently plain Label-based buttons

### Sprites Needed
| Sprite Name | Purpose | Suggested Size | Notes |
|---|---|---|---|
| `main_menu_background.png` | Full-screen background art | 1280×720 | Dark, atmospheric, showing Aethelgard world |
| `game_logo.png` | Title logo | 600×200 | "AETHELGARD" with digital glitch aesthetic |
| `menu_button_normal.png` | Button idle state | 300×50 | Dark panel with border |
| `menu_button_hover.png` | Button hover state | 300×50 | Highlighted/glowing version |
| `menu_button_pressed.png` | Button click state | 300×50 | Pressed/depressed version |
| `menu_cursor.png` | Custom cursor | 32×32 | Optional, digital/glitch themed |

## Game Over Screen

**Scene**: `scenes/game_over.tscn` | **Script**: `scripts/game_over.gd`

### Sprites Needed
| Sprite Name | Purpose | Suggested Size |
|---|---|---|
| `game_over_background.png` | Death screen background | 1280×720 |
| `game_over_text.png` | "FATAL ERROR" / game over text | 400×100 |

---

# 3. CHARACTERS

---

## 3.1 Kaelen — Player Character

### Visual Description
**Identity**: A young adult who crashed into the digital world of Aethelgard. Wears casual modern clothes (hoodie, jeans) that glitch at the edges. Blue-tinted digital aura. Eyes occasionally flash with code when using abilities.

**Placeholder Color**: `Color(0.1, 0.5, 1.0)` (blue) with accent `Color(0.2, 0.7, 1.0)` (light blue)

**Placeholder Structure** (`PlaceholderSprite.create_player_combat()`):
| Part | Node Name | Size | Color | Notes |
|---|---|---|---|---|
| Body | `"Body"` | 20×32 | Blue `(0.1, 0.5, 1.0)` | Main torso |
| Head | `"Head"` | 16×16 | Light blue `(0.2, 0.7, 1.0)` | On top of body |
| Left Eye | `"EyeL"` | 3×3 | White | On head |
| Right Eye | `"EyeR"` | 3×3 | White | On head |
| Arm | `"Arm"` | 14×6 | Blue | Hidden by default, shown during attacks |
| Weapon Trail | `"WeaponTrail"` | 30×3 | White | Hidden, shown during attack animations |

**Top-Down Structure** (`PlaceholderSprite.create_player_topdown()`):
| Part | Node Name | Size | Color |
|---|---|---|---|
| Body | `"Body"` | 24×24 | Blue `(0.1, 0.5, 1.0)` |
| Direction Indicator | `"DirIndicator"` | 8×8 | Light blue `(0.2, 0.7, 1.0)` |
| Head | `"Head"` | 16×6 | Light blue |

### Combat Mode Animations (Side-Scroll)

**Sprite Size**: `32×48 px` | **AnimatedSprite2D Node**: Replace `"PlayerSprite"` in combat scenes

| Animation Name | Constant | Frames | FPS | Loop | Description |
|---|---|---|---|---|---|
| `"idle"` | `AnimConst.PLAYER_IDLE` | 6 | 8 | Yes | Standing still, subtle breathing |
| `"run"` | `AnimConst.PLAYER_RUN` | 8 | 12 | Yes | Left/right run cycle |
| `"jump_up"` | `AnimConst.PLAYER_JUMP_UP` | 3 | 12 | No | Rising during jump |
| `"jump_peak"` | `AnimConst.PLAYER_JUMP_PEAK` | 2 | 8 | No | Apex hang moment |
| `"fall"` | `AnimConst.PLAYER_FALL` | 3 | 12 | No | Falling downward |
| `"land"` | `AnimConst.PLAYER_LAND` | 3 | 12 | No | Squash on landing |
| `"attack_1"` | `AnimConst.PLAYER_ATTACK_1` | 5 | 15 | No | Quick horizontal slash |
| `"attack_2"` | `AnimConst.PLAYER_ATTACK_2` | 5 | 15 | No | Follow-up reverse slash |
| `"attack_3"` | `AnimConst.PLAYER_ATTACK_3` | 7 | 15 | No | Heavy overhead finisher |
| `"attack_air"` | `AnimConst.PLAYER_ATTACK_AIR` | 6 | 15 | No | Aerial downward slash |
| `"hurt"` | `AnimConst.PLAYER_HURT` | 3 | 12 | No | Knockback flinch |
| `"die"` | `AnimConst.PLAYER_DIE` | 8 | 10 | No | Death collapse |
| `"dash"` | `AnimConst.PLAYER_DASH` | 4 | 15 | No | Horizontal dash blur |
| `"heal"` | `AnimConst.PLAYER_HEAL` | 6 | 10 | No | Green pulse rising from below |
| `"hack_start"` | `AnimConst.PLAYER_HACK_START` | 4 | 10 | No | Eyes glow, raise hand |
| `"hack_loop"` | `AnimConst.PLAYER_HACK_LOOP` | 4 | 10 | Yes | Typing gesture loop |
| `"hack_end"` | `AnimConst.PLAYER_HACK_END` | 4 | 10 | No | Hand down, eyes fade |
| `"perfect_delete"` | `AnimConst.PLAYER_PERFECT_DEL` | 6 | 15 | No | Red flash, sweeping arm |

### Top-Down Mode Animations (Exploration)

**Sprite Size**: `32×32 px` | **AnimatedSprite2D Node**: Replace `"PlayerTDSprite"` in exploration scenes

| Animation Name | Constant | Frames | FPS | Loop | Description |
|---|---|---|---|---|---|
| `"td_idle_down"` | `AnimConst.PLAYER_TD_IDLE_DOWN` | 2 | 8 | Yes | Facing down, still |
| `"td_idle_up"` | `AnimConst.PLAYER_TD_IDLE_UP` | 2 | 8 | Yes | Facing up, still |
| `"td_idle_left"` | `AnimConst.PLAYER_TD_IDLE_LEFT` | 2 | 8 | Yes | Facing left, still |
| `"td_idle_right"` | `AnimConst.PLAYER_TD_IDLE_RIGHT` | 2 | 8 | Yes | Facing right, still |
| `"td_walk_down"` | `AnimConst.PLAYER_TD_WALK_DOWN` | 4 | 10 | Yes | Walking down |
| `"td_walk_up"` | `AnimConst.PLAYER_TD_WALK_UP` | 4 | 10 | Yes | Walking up |
| `"td_walk_left"` | `AnimConst.PLAYER_TD_WALK_LEFT` | 4 | 10 | Yes | Walking left |
| `"td_walk_right"` | `AnimConst.PLAYER_TD_WALK_RIGHT` | 4 | 10 | Yes | Walking right |
| `"td_interact"` | `AnimConst.PLAYER_TD_INTERACT` | 3 | 10 | No | Reach forward gesture |

### Cutscene Animations

**Sprite Size**: `32×48 px` (same as combat) | Used during dialogue/cutscene sequences

| Animation Name | Constant | Frames | FPS | Loop | Description |
|---|---|---|---|---|---|
| `"cut_stand"` | `AnimConst.PLAYER_CUT_STAND` | 4 | 8 | Yes | Standing pose for dialogue |
| `"cut_look_up"` | `AnimConst.PLAYER_CUT_LOOK_UP` | 3 | 10 | No | Tilt head upward |
| `"cut_look_down"` | `AnimConst.PLAYER_CUT_LOOK_DOWN` | 3 | 10 | No | Look at ground |
| `"cut_surprise"` | `AnimConst.PLAYER_CUT_SURPRISE` | 4 | 10 | No | Step back, wide eyes |
| `"cut_nod"` | `AnimConst.PLAYER_CUT_NOD` | 3 | 10 | No | Agreement nod |
| `"cut_shake_head"` | `AnimConst.PLAYER_CUT_SHAKE` | 4 | 10 | No | Disagreement head shake |
| `"cut_think"` | `AnimConst.PLAYER_CUT_THINK` | 3 | 10 | No | Hand on chin, pondering |
| `"cut_point"` | `AnimConst.PLAYER_CUT_POINT` | 3 | 10 | No | Point at something |
| `"cut_sit"` | `AnimConst.PLAYER_CUT_SIT` | 2 | 8 | Yes | Sitting in airplane seat (prologue) |
| `"cut_wake_up"` | `AnimConst.PLAYER_CUT_WAKE_UP` | 6 | 10 | No | Waking up on ground (crater) |

### Additional Combat Animations Needed

These are referenced in the expanded combat mechanics but not yet in `AnimConst`:

| Animation Name | Frames | FPS | Loop | Description |
|---|---|---|---|---|
| `"sprint_run"` | 8 | 14 | Yes | Faster run at 1.8× speed |
| `"pogo_down"` | 4 | 15 | No | Downward pogo strike |
| `"pogo_bounce"` | 3 | 15 | No | Bounce after pogo hit |
| `"dash_ground"` | 4 | 15 | No | Ground dash with i-frames |
| `"dash_air"` | 4 | 15 | No | Air dash variant |
| `"block_hold"` | 2 | 8 | Yes | Active block stance |
| `"parry_success"` | 4 | 15 | No | Successful parry flash |

### Additional Top-Down Animations Needed

| Animation Name | Frames | FPS | Loop | Description |
|---|---|---|---|---|
| `"sprint_down"` | 6 | 14 | Yes | Sprinting down |
| `"sprint_up"` | 6 | 14 | Yes | Sprinting up |
| `"sprint_side"` | 6 | 14 | Yes | Sprinting left/right |

---

## 3.2 Elara — Glitch-Witch Companion

### Visual Description
**Identity**: A young woman who exists as a glitch in the system — half-real, half-code. Her left arm occasionally reveals wireframe underneath. Purple-tinted with pink energy sparks. Floats slightly off the ground. Hair moves like it's in digital wind.

**Placeholder Color**: `Color(0.75, 0.2, 1.0)` (purple) with accent `Color(1.0, 0.5, 1.0)` (pink)

**Placeholder Structure** (`PlaceholderSprite.create_elara()`):
| Part | Node Name | Size | Color | Notes |
|---|---|---|---|---|
| Body | `"Body"` | 20×34 | Purple `(0.75, 0.2, 1.0)` | Main form |
| Head | `"Head"` | 16×16 | Pink `(1.0, 0.5, 1.0)` | On top of body |
| Wireframe Arm | `"WireframeArm"` | 16×5 | Green `(0, 1, 0.5, 0.8)` | Hidden by default, revealed during cast/glitch |
| Glow | `"Glow"` | 30×44 | Purple 15% alpha | Ambient aura around body |

**Dialogue Portrait Color**: `Color(0.8, 0.5, 1.0)` (purple) in DialogueManager, `Color(0, 0.85, 0.5)` (green) in DialogueUI

### Animations

**Sprite Size**: `32×48 px` | **AnimatedSprite2D Node**: Replace `"ElaraSprite"`

| Animation Name | Constant | Frames | FPS | Loop | Description |
|---|---|---|---|---|---|
| `"elara_idle"` | `AnimConst.ELARA_IDLE` | 6 | 8 | Yes | Floating slightly, sparks orbiting |
| `"elara_walk"` | `AnimConst.ELARA_WALK` | 6 | 10 | Yes | Gliding walk, feet barely touching ground |
| `"elara_talk"` | `AnimConst.ELARA_TALK` | 4 | 10 | Yes | Gesticulating with hands during dialogue |
| `"elara_cast"` | `AnimConst.ELARA_CAST` | 8 | 15 | No | Hands glow, magic circle appears |
| `"elara_buffer_overflow"` | `AnimConst.ELARA_BUFFER_OVERFLOW` | 10 | 15 | No | Big spell, arm glows bright, particles burst |
| `"elara_glitch_arm"` | `AnimConst.ELARA_GLITCH_ARM` | 6 | 12 | No | Left arm reveals wireframe underneath |
| `"elara_laugh"` | `AnimConst.ELARA_LAUGH` | 4 | 10 | No | Amused expression, head tilt |
| `"elara_worry"` | `AnimConst.ELARA_WORRY` | 3 | 10 | No | Concerned face, brow furrow |
| `"elara_spawn_in"` | `AnimConst.ELARA_SPAWN_IN` | 10 | 12 | No | Static noise materializes into body |
| `"elara_point"` | `AnimConst.ELARA_POINT` | 3 | 10 | No | Pointing at something |
| `"elara_disappear"` | `AnimConst.ELARA_DISAPPEAR` | 8 | 12 | No | Glitch-dissolve out, fragments scatter |

### Tween Animations (Current Placeholder Behavior)
| Function | What It Looks Like |
|---|---|
| `play_elara_idle()` | Float ±5px Y over 1.5s; Glow alpha pulses 0.1↔0.25 |
| `play_elara_cast()` | WireframeArm raises -15px, glows `Color(0,1,0.5,1.0)`; Glow scales 1.5× at 0.5 alpha |

---

## 3.3 Mira — Flight Attendant

### Visual Description
**Identity**: Airline stewardess on Flight 707. Professional uniform, polished smile that seems slightly too perfect. Appears only in the prologue. Her movements have a subtle uncanny valley quality — scripted, not quite natural.

**Placeholder Color**: `Color(1.0, 0.85, 0.3)` (gold)

**Dialogue Portrait Color**: `Color(0.9, 0.6, 0.2)` (orange)

### Animations

**Sprite Size**: `32×48 px`

| Animation Name | Constant | Frames | FPS | Loop | Description |
|---|---|---|---|---|---|
| `"mira_idle"` | `AnimConst.MIRA_IDLE` | 4 | 8 | Yes | Standing with hands clasped |
| `"mira_talk"` | `AnimConst.MIRA_TALK` | 4 | 10 | Yes | Polite gesturing while speaking |
| `"mira_worry"` | `AnimConst.MIRA_WORRY` | 3 | 10 | No | Concern breaks through her smile |
| `"mira_brace"` | `AnimConst.MIRA_BRACE` | 3 | 12 | No | Turbulence brace position |

---

## 3.4 Tutorial Knight — Chapter 1 Boss

### Visual Description
**Identity**: `Sir_Reginald_Tutorial_Knight_V2.1` — A massive armored knight programmed to be the tutorial boss. Steel armor with gold trim. Orange-red visor slit. Carries a large sword and shield. In Phase 3, his armor glitches and shows error text, body vibrates with corrupted colors.

**Placeholder Color**: `Color(0.5, 0.5, 0.55)` (steel) with accent `Color(0.8, 0.7, 0.2)` (gold)

**Placeholder Structure** (`PlaceholderSprite.create_knight()`):
| Part | Node Name | Size | Color | Notes |
|---|---|---|---|---|
| Body | `"Body"` | 32×44 | Steel `(0.5, 0.5, 0.55)` | Large armored torso |
| Helmet | `"Helmet"` | 28×20 | Steel | On top of body |
| Visor | `"Visor"` | 18×4 | Orange-red `(0.9, 0.3, 0.1)` | Glowing slit on helmet |
| Sword | `"Sword"` | 6×40 | Steel | Right side |
| Shield | `"Shield"` | 10×24 | Gold `(0.8, 0.7, 0.2)` | Left side |
| Left Shoulder | `"ShoulderL"` | 10×8 | Steel | Left pauldron |
| Right Shoulder | `"ShoulderR"` | 10×8 | Steel | Right pauldron |

**Dialogue Portrait Color**: `Color(0.4, 0.4, 0.5)` (dark grey)

### Animations

**Sprite Size**: `48×64 px` | **AnimatedSprite2D Node**: Replace `"KnightSprite"`

| Animation Name | Constant | Frames | FPS | Loop | Description |
|---|---|---|---|---|---|
| `"knight_idle"` | `AnimConst.KNIGHT_IDLE` | 4 | 8 | Yes | Standing guard, slow breathing |
| `"knight_walk"` | `AnimConst.KNIGHT_WALK` | 6 | 10 | Yes | Slow heavy stomping walk |
| `"knight_slash_horizontal"` | `AnimConst.KNIGHT_SLASH_H` | 7 | 15 | No | Phase 1: wide horizontal sword sweep |
| `"knight_crush_vertical"` | `AnimConst.KNIGHT_CRUSH_V` | 8 | 15 | No | Phase 2: overhead vertical slam |
| `"knight_error_attack"` | `AnimConst.KNIGHT_ERROR_ATTACK` | 10 | 15 | No | Phase 3: glitched erratic attack |
| `"knight_hurt"` | `AnimConst.KNIGHT_HURT` | 3 | 12 | No | Armor sparks on hit |
| `"knight_stunned"` | `AnimConst.KNIGHT_STUNNED` | 4 | 12 | Yes | Vibrating, ERROR text above head |
| `"knight_hacked"` | `AnimConst.KNIGHT_HACKED` | 1 | 8 | Yes | Frozen T-pose, pink tint |
| `"knight_die"` | `AnimConst.KNIGHT_DIE` | 15 | 10 | No | Dissolve into data fragments |
| `"knight_telegraph"` | `AnimConst.KNIGHT_TELEGRAPH` | 4 | 12 | No | Wind-up tell before attack |
| `"knight_phase_shift"` | `AnimConst.KNIGHT_PHASE_SHIFT` | 6 | 12 | No | Glitch between combat phases |

### Tween Animations (Current Placeholder Behavior)
| Function | What It Looks Like |
|---|---|
| `play_knight_idle()` | Slow breathing ±1px Y over 1.2s |
| `play_knight_slash()` | Wind-up -15° rotation, sword rotates -90°→+90° in 0.08s |
| `play_knight_crush()` | Body raises -40px, slams +5px; scale (0.9,1.2)→(1.2,0.8) |
| `play_knight_error()` | Random vibrate ±6px, random modulate colors ×20 flashes |
| `play_knight_stunned()` | ±3px X vibrate loop |
| `play_knight_tpose()` | Sword/shield rotate ±90° out, arms extend 30px, alpha 0.7 |

### Phase Transition Visual Cues
| Phase | Visual Change |
|---|---|
| Phase 1 (Slash) | Normal knight appearance |
| Phase 2 (Crush) | +15% difficulty, faster attacks, subtle red tint |
| Phase 3 (Crash) | Armor glitches, zalgo text overlay, random color flashes, vibrating |
| Defeated | Grey tint `Color(0.7, 0.7, 0.7, 1.0)`, dissolve into data |

---

## 3.5 Green Slime — Tutorial Enemy

### Visual Description
**Identity**: A small translucent green blob. Jiggles constantly. Has two round white eyes with tiny black pupils. Bounces to move. When hacked via Root Access, turns pink.

**Placeholder Color**: `Color(0.2, 0.85, 0.2)` (green)

**Placeholder Structure** (`PlaceholderSprite.create_slime()`):
| Part | Node Name | Size | Color | Notes |
|---|---|---|---|---|
| Blob | `"Blob"` | 32×24 | Green `(0.2, 0.85, 0.2)` | Round body |
| Dome | `"Dome"` | 24×12 | Lighter green | Top of blob |
| Left Eye | `"EyeL"` | 5×5 | White | On dome |
| Right Eye | `"EyeR"` | 5×5 | White | On dome |
| Left Pupil | `"PupilL"` | 2×3 | Black | On eye |
| Right Pupil | `"PupilR"` | 2×3 | Black | On eye |
| Shadow | `"Shadow"` | 28×6 | Dark, semi-transparent | Below body |

### Animations

**Sprite Size**: `32×32 px` | **AnimatedSprite2D Node**: Replace `"SlimeSprite"`

| Animation Name | Constant | Frames | FPS | Loop | Description |
|---|---|---|---|---|---|
| `"slime_idle"` | `AnimConst.SLIME_IDLE` | 4 | 8 | Yes | Jiggle in place |
| `"slime_hop"` | `AnimConst.SLIME_HOP` | 6 | 12 | No | Squash-stretch hop forward |
| `"slime_attack"` | `AnimConst.SLIME_ATTACK` | 5 | 15 | No | Quick lunge forward |
| `"slime_hurt"` | `AnimConst.SLIME_HURT` | 3 | 12 | No | Flash white, squish flat |
| `"slime_die"` | `AnimConst.SLIME_DIE` | 8 | 10 | No | Splat into puddle |
| `"slime_bounce"` | `AnimConst.SLIME_BOUNCE` | 4 | 12 | No | High elasticity bounce |
| `"slime_hacked"` | `AnimConst.SLIME_HACKED` | 4 | 8 | Yes | Pink tint pulse (Root Access applied) |

### Tween Animations (Current Placeholder Behavior)
| Function | What It Looks Like |
|---|---|
| `play_slime_idle()` | Scale oscillates (1.1,0.9)↔(0.9,1.1) loop |
| `play_slime_hop()` | Squash (1.3,0.6)→spring (0.7,1.4), -30px Y arc |
| `play_slime_die()` | Splat: scale (2.0,0.2), green fade to `Color(0.2,0.85,0.2,0.6)` |
| `play_slime_hacked()` | Pink↔green color pulse: `Color(1.0,0.5,1.0)`↔`Color(0.2,0.85,0.2)` |

---

## 3.6 Corrupted Boar — Elite Enemy

### Visual Description
**Identity**: A large boar corrupted by system corruption. Dark red body with glowing red pixel eyes. Crimson aura pulses around it. Tusks are ivory-colored. Larger and more aggressive than normal enemies. In enrage mode, red glow intensifies and it moves 50% faster.

**Placeholder Color**: `Color(0.75, 0.15, 0.15)` (dark red)

**Placeholder Structure** (`PlaceholderSprite.create_boar()`):
| Part | Node Name | Size | Color | Notes |
|---|---|---|---|---|
| Body | `"Body"` | 48×32 | Dark red `(0.75, 0.15, 0.15)` | Wide, bulky |
| Head | `"Head"` | 20×20 | Dark red | Front of body |
| Tusk | `"Tusk"` | 8×4 | Ivory `(0.9, 0.85, 0.7)` | Protruding from head |
| Corruption Glow | `"CorruptionGlow"` | 52×36 | Crimson 20% alpha `(0.7, 0, 0.2, 0.2)` | Aura around entire body |
| Eye | `"Eye"` | 4×4 | Red `(1, 0, 0)` | Glowing pixel eye |

### Animations

**Sprite Size**: `64×48 px` | **AnimatedSprite2D Node**: Replace `"BoarSprite"`

| Animation Name | Constant | Frames | FPS | Loop | Description |
|---|---|---|---|---|---|
| `"boar_idle"` | `AnimConst.BOAR_IDLE` | 4 | 8 | Yes | Snorting, red eyes glow |
| `"boar_charge"` | `AnimConst.BOAR_CHARGE` | 6 | 15 | No | Head-down charge, dust trail |
| `"boar_attack"` | `AnimConst.BOAR_ATTACK` | 5 | 15 | No | Tusk gore upward |
| `"boar_hurt"` | `AnimConst.BOAR_HURT` | 3 | 12 | No | Flinch backward |
| `"boar_die"` | `AnimConst.BOAR_DIE` | 12 | 10 | No | Corruption dissolve effect |
| `"boar_enrage"` | `AnimConst.BOAR_ENRAGE` | 6 | 12 | No | Red aura pulse, screen shake |

### Tween Animations (Current Placeholder Behavior)
| Function | What It Looks Like |
|---|---|
| `play_boar_charge()` | Scale pop (1.1,0.95), charge -120px X |
| `play_boar_enrage()` | Scale 1.15×, modulate `Color(1,0.3,0.3)`, CorruptionGlow alpha rises to 0.6 |

### Combat Phases
| Phase | Behavior | Visual |
|---|---|---|
| 1. Charge | Runs at player | Normal appearance |
| 2. Vulnerability | Stunned after hitting wall | Stars/daze effect |
| 3. Enrage | +50% speed, more aggressive | Red glow intensifies |
| 4. Null Block | Creates corruption trap zone | Purple-black area on ground |

---

## 3.7 Village NPCs

### Visual Description
**Identity**: Generic villagers of Oakhaven. Simple medieval-fantasy clothing. Each has a distinct color and optional name label. They move on scripted patrol loops (a fact Kaelen notices).

**Placeholder Color**: `Color(0.9, 0.65, 0.3)` (orange)

**Placeholder Structure** (`PlaceholderSprite.create_npc(color, label)`):
| Part | Node Name | Size | Color | Notes |
|---|---|---|---|---|
| Body | `"Body"` | 20×30 | Varies per NPC | Main body |
| Head | `"Head"` | 14×14 | Varies | On top |
| Name Label | `"NameLabel"` | — | White, font_size 10 | Floating name above head |

### Named NPCs

| NPC | Role | Suggested Color | Unique Trait |
|---|---|---|---|
| Farmer Jenkins | Self-aware farmer | Brown `(0.6, 0.4, 0.2)` | Knows he's in a loop |
| Village Child | Curious kid | Light blue `(0.5, 0.7, 1.0)` | Asks if you're a Developer |
| Village Guard | Stuck guard | Grey `(0.5, 0.5, 0.55)` | Pathfinding disabled by Patch 4.2.1b |
| Apothecary | Potion seller | Green `(0.3, 0.7, 0.4)` | Sells Null Potion |
| Merchant | Shop owner | Gold `(0.8, 0.7, 0.2)` | Wiping counter |

### Animations

**Sprite Size**: `32×48 px`

| Animation Name | Constant | Frames | FPS | Loop | Description |
|---|---|---|---|---|---|
| `"apothecary_idle"` | `AnimConst.NPC_APOTHECARY_IDLE` | 4 | 6 | Yes | Stirring cauldron |
| `"apothecary_talk"` | `AnimConst.NPC_APOTHECARY_TALK` | 4 | 10 | Yes | Stutter-buffer animation |
| `"villager_idle"` | `AnimConst.NPC_VILLAGER_IDLE` | 2 | 6 | Yes | Standing around |
| `"villager_walk"` | `AnimConst.NPC_VILLAGER_WALK` | 4 | 10 | Yes | Walking about |
| `"guard_idle"` | `AnimConst.NPC_GUARD_IDLE` | 2 | 6 | Yes | Standing at post |
| `"merchant_idle"` | `AnimConst.NPC_MERCHANT_IDLE` | 4 | 6 | Yes | Wiping counter |

### Additional NPC Animations Needed

| Animation Name | Frames | FPS | Loop | Description |
|---|---|---|---|---|
| `"farmer_idle"` | 4 | 6 | Yes | Farmer Jenkins standing |
| `"farmer_talk"` | 4 | 10 | Yes | Farmer speaking |
| `"farmer_patrol"` | 6 | 10 | Yes | Walking the loop |
| `"child_idle"` | 4 | 6 | Yes | Kid standing around |
| `"child_talk"` | 4 | 10 | Yes | Kid speaking |
| `"child_tag"` | 6 | 12 | Yes | Playing tag |
| `"guard_talk"` | 4 | 10 | Yes | Guard speaking |
| `"guard_alert"` | 3 | 12 | No | Guard notices something |

---

# 4. BACKGROUNDS & ENVIRONMENTS

---

## 4.1 Flight 707 — Airplane Cabin

**Scene**: `scenes/prologue/flight_707.tscn` | **Script**: `scripts/prologue/flight_707.gd`

### Visual Description
The interior of a commercial airplane at night. CRT shader applied to everything for a retro-digital feel. Blue-tinted lighting. Seats in rows, a narrow aisle, overhead bins, and small oval windows showing clouds. The scene feels slightly wrong — too perfect, too scripted.

### Current Placeholder Colors
| Element | Node/ID | Color | Size |
|---|---|---|---|
| Background | `"Background"` | `Color(0.15, 0.18, 0.25)` dark blue-grey | Full screen |
| Atmospheric Gradient | `"AtmosphericGradient"` | `Color(0.2, 0.25, 0.35, 0.6)` | Full screen overlay |
| Cloud Layer | `"CloudLayer"` | `Color(0.8, 0.8, 1, 0.2)` | Background layer |
| Cabin Floor | `"Floor"` | `Color(0.25, 0.2, 0.18)` brown | Bottom strip |
| Cabin Walls | `"Walls"` | `Color(0.28, 0.28, 0.32)` grey | Side panels |
| Window | `"Window"` | `Color(0.4, 0.5, 0.7)` with glow `Color(0.6, 0.75, 1, 0.5)` | Small oval |
| Seat Row | `"SeatRow"` | `Color(0.2, 0.25, 0.35)` dark blue | Repeating seats |
| Laptop Glow | on Kaelen | `Color(1, 0.8, 0.3)` warm yellow | Small rect |
| Title Text | — | `Color(0.4, 0.8, 1)` cyan | "FLIGHT 707" |

### Sprites Needed
| Sprite Name | Purpose | Suggested Size | Notes |
|---|---|---|---|
| `cabin_background.png` | Full cabin interior | 1280×720 | Night-time airplane cabin with CRT aesthetic |
| `cabin_seats.png` | Row of airplane seats | 128×64 | Tileable/repeatable |
| `cabin_window.png` | Oval airplane window | 48×64 | Shows clouds/sky outside |
| `cabin_overhead_bin.png` | Overhead compartment | 128×32 | Luggage clipping through |
| `cabin_tray_table.png` | Fold-down tray | 32×24 | With coffee cup |
| `cabin_safety_card.png` | Safety instruction card | 24×32 | "Emergency exits rendered at runtime" |
| `cloud_parallax.png` | Scrolling clouds outside | 1920×360 | Seamlessly tileable, transparent |
| `laptop_screen.png` | Kaelen's laptop | 48×32 | With emails visible |

### Shaders Active
- **CRT Effect** (`crt_effect.gdshader`) on Background: `distortion=0.08`, `scanline_intensity=0.12`, `scanline_count=720`, `vignette=0.25`, `brightness=1.15`, `contrast=1.08`
- **Advanced Glitch** (`advanced_glitch.gdshader`) on GlitchOverlay: `glitch_strength=0.5`, `block_size=50.0`

### Interactable Objects
| Object | Interaction Key | Description |
|---|---|---|
| Overhead Bin | F | Luggage clipping through mesh |
| Tray Table | F | Coffee with floating point error temperature |
| Safety Card | F | "Emergency exits rendered at runtime" |
| Window | F | Skybox seam visible between cloud tiles |

---

## 4.2 Crash Sequence — Boot Screen

**Scene**: `scenes/prologue/crash_sequence.tscn` | **Script**: `scripts/prologue/crash_sequence.gd`

### Visual Description
A dark screen with scrolling green/yellow/red terminal text — like a BIOS boot sequence. 46 boot entries appear one by one. Background has an inline glitch shader (color separation + scanlines + block glitch effects).

### Current Placeholder Colors
| Element | Color | Notes |
|---|---|---|
| Background | `Color(0.1, 0.1, 0.2)` dark navy | With glitch shader |
| Normal text | `Color(0.5, 1.0, 0.5)` green | Standard boot entries |
| Warning text | `Color(1, 1, 0.3)` yellow | Attention entries |
| Error text | `Color(1, 0.3, 0.3)` red | Critical entries |
| Admin text | `Color(1, 0, 1)` magenta | ADMIN_EVENT entries |
| BSOD flash | `Color(0, 0, 0.8, 1.0)` blue | Blue screen flash |

### Sprites Needed
| Sprite Name | Purpose | Suggested Size |
|---|---|---|
| `boot_screen_background.png` | CRT monitor with scanlines | 1280×720 |
| `boot_cursor.png` | Blinking terminal cursor | 8×16 |

---

## 4.3 Glitch Crater — Awakening

**Scene**: `scenes/chapter1/glitch_crater_awakening.tscn` | **Script**: `scripts/chapter1/ch1_glitch_crater.gd`

### Visual Description
A crater made of fractured terrain — fragments of ground floating, digital particles drifting upward, corrupted purple-black patches, scattered code artifacts. The sky above is a glitching pixel grid. This is where Kaelen wakes up after crashing into Aethelgard.

### Sprites Needed
| Sprite Name | Purpose | Suggested Size | Notes |
|---|---|---|---|
| `crater_background.png` | Fractured landscape | 1280×720 | Broken terrain with floating fragments |
| `crater_ground_tiles.png` | Walkable ground | 32×32 tileset | Mix of natural + digital |
| `crater_floating_debris.png` | Floating rock/code fragments | 16×16 each | Several variations |
| `crater_corruption_patch.png` | Purple-black corrupted zones | 64×32 | Animated pulse |
| `crater_sky.png` | Glitching pixel sky | 1280×360 | Parallax background |
| `crater_digital_particles.png` | Rising data particles | 8×8 each | Green/cyan floating upward |
| `golden_path_tile.png` | The "golden path" Kaelen sees | 32×32 | Glowing directional guide |

### Environment Animations Used
- `"floating_debris"` (`AnimConst.ENV_FLOATING_DEBRIS`) — fragments hanging in air
- `"corruption_pulse"` (`AnimConst.ENV_CORRUPTION_PULSE`) — red-purple area pulse
- `"null_texture"` (`AnimConst.ENV_NULL_TEXTURE`) — purple-black checkerboard

### Current Procedural Background (implemented in `_build_environment()`)

Until sprite assets replace them, the scene renders a fully animated procedural environment built from layered `ColorRect` nodes inside an `Environment` Control container (inserted at child index 0, behind all other nodes).

**Layer Stack (back to front):**

| Layer | Node Name | Color/Value | Animation |
|---|---|---|---|
| Sky | `Sky` | `Color(0.02, 0.01, 0.06)` near-black void | Static |
| Nebula Glow | `NebulaGlow` | `Color(0.15, 0.05, 0.2, 0.3)` purple | Static |
| Stars (×25) | `Star_N` | `Color(0.8, 0.85, 1.0)` white-blue | Looping alpha fade 0.15–1.0, cycle 1.5–3.5s random |
| Ground | `Ground` | `Color(0.04, 0.025, 0.06)` dark purple-brown | Static |
| Horizon Glow | `HorizonGlow` | `Color(0.15, 0.05, 0.2, 0.4)` purple | Looping alpha pulse 0.4–1.0, 3.0s sine |
| Crater Rim (×4) | `CraterRim_N` | `Color(0.06, 0.03, 0.08)` dark silhouette | Static |
| Crater Depression | `CraterCenter` | `Color(0.01, 0.005, 0.02)` near-black | Static |
| Floating Rocks (×6) | `FloatingRock_N` | `Color(0.08, 0.04, 0.1)` dark purple | Looping Y-position sine bob, 5–18px amplitude, 2.0–4.5s cycle |
| Corruption Veins (×5) | `CorruptionVein_N` | `Color(0.6, 0.1, 0.8, 0.3)` purple | Looping alpha pulse 0.2–1.0, 1.2–2.5s cycle |
| Golden Path | `GoldenPathHint` | `Color(1.0, 0.85, 0.2, 0.0)` gold (hidden) | Revealed via "show_golden_path" effect: alpha tween to 0.35 over 1.5s + continuous pulse |
| Scan Lines (×4) | `ScanLine_N` | `Color(0.3, 0.8, 1.0, 0.03)` faint cyan | Looping vertical position drift, 5.0–9.0s cycle |
| Vignette Top | `VignetteTop` | `Color(0, 0, 0, 0.6)` | Static |
| Vignette Bottom | `VignetteBottom` | `Color(0, 0, 0, 0.5)` | Static |

**Letterbox Bars:** `camera.enable_letterbox(60.0, 0.8)` after fade-in; `camera.disable_letterbox(0.4)` before transition out.

**Golden Path Reveal Effect:**
```gdscript
# Triggered by "show_golden_path" custom effect beat
var gp = get_node_or_null("Environment/GoldenPathHint")
if gp:
    var gp_tween = create_tween()
    gp_tween.tween_property(gp, "color", Color(1.0, 0.85, 0.2, 0.35), 1.5)
    var gp_pulse = create_tween().set_loops()
    gp_pulse.tween_property(gp, "modulate:a", 0.5, 2.0).set_trans(Tween.TRANS_SINE).set_delay(1.5)
    gp_pulse.tween_property(gp, "modulate:a", 1.0, 2.0).set_trans(Tween.TRANS_SINE)
```

---

## 4.4 Forest Clearing — Elara Meeting

**Scene**: `scenes/chapter1/elara_meeting.tscn` | **Script**: `scripts/chapter1/ch1_elara_meeting.gd`

### Visual Description
A small forest clearing with trees around the edges. Magical, slightly unnatural feel — trees repeat in suspiciously regular patterns. A clearing where static noise gathers, then materializes into Elara. Glitch effects in the air.

### Sprites Needed
| Sprite Name | Purpose | Suggested Size | Notes |
|---|---|---|---|
| `forest_background.png` | Forest backdrop | 1280×720 | Repeating trees (intentional) |
| `forest_ground.png` | Ground tileset | 32×32 | Grass and dirt |
| `forest_tree.png` | Individual tree | 64×96 | Multiple variations |
| `forest_bush.png` | Underbrush | 32×32 | Decorative |
| `static_noise_overlay.png` | Where Elara spawns | 64×64 | Animated TV static |

### Color Flashes Used
- `Color(0.5, 0, 0.5, 0.6)` — Purple glitch flash during Elara's demo
- `Color(1, 1, 1, 0.5)` — White flash on magic use
- `Color(1, 0, 1)` — Magenta glitch artifact

### Environment Animations Used
- `"tree_sway"` (`AnimConst.ENV_TREE_SWAY`) — gentle wind movement
- `"grass_wave"` (`AnimConst.ENV_GRASS_WAVE`) — grass blowing

### Current Procedural Background (implemented in `_build_environment()`)

Layered `ColorRect` environment inside an `Environment` Control container at child index 0.

**Layer Stack (back to front):**

| Layer | Node Name | Color/Value | Animation |
|---|---|---|---|
| Sky | `Sky` | `Color(0.08, 0.05, 0.15)` deep purple twilight | Static |
| Sky Glow | `SkyGlow` | `Color(0.15, 0.1, 0.25, 0.3)` upper glow | Static |
| Ground | `Ground` | `Color(0.04, 0.08, 0.03)` dark forest green | Static |
| Dirt Path | `DirtPath` | `Color(0.12, 0.08, 0.04)` earthy brown | Static |
| Golden Trail | `GoldenTrail` | `Color(1.0, 0.85, 0.2, 0.25)` gold | Looping alpha pulse 0.15–0.35, 2.5s sine |
| Trees (×7) | trunk + canopy pairs | Trunk `Color(0.06, 0.04, 0.02)`, Canopy `Color(0.03, 0.06, 0.02)` | Canopy X-position sway 2–6px, 3.0–5.5s cycle |
| Fireflies (×8) | `Firefly_N` | `Color(0.6, 0.9, 0.3, 0.7)` yellow-green | Looping X/Y position drift 30–60px over 3–6s + alpha fade 0.1–0.8 over 1–2.5s |
| Vignette Top | `VignetteTop` | `Color(0, 0, 0, 0.4)` | Static |
| Vignette Bottom | `VignetteBottom` | `Color(0, 0, 0.05, 0.3)` blue tint | Static |

**Letterbox Bars:** `camera.enable_letterbox(60.0, 0.8)` after fade-in; `camera.disable_letterbox(0.4)` before transition out.

---

## 4.5 Path to Oakhaven

**Scene**: `scenes/chapter1/path_to_oakhaven.tscn` | **Script**: `scripts/chapter1/ch1_path_to_oakhaven.gd`

### Visual Description
A winding dirt path through rolling countryside. Flora and landscape pop in with obvious LOD transitions. Trees and bushes repeat in patterns. The path leads toward Oakhaven village in the distance. Data Vision reveals hidden wireframe overlays.

### Sprites Needed
| Sprite Name | Purpose | Suggested Size | Notes |
|---|---|---|---|
| `path_background.png` | Rolling countryside | 1280×720 | Parallax background |
| `path_ground.png` | Dirt path tileset | 32×32 | Brown/earthy tones |
| `path_grass.png` | Grass tiles | 32×32 | Green, windswept |
| `path_tree_variations.png` | Trees along path | 64×96 each | 3-4 variations |
| `path_bush.png` | Bushes | 32×32 | Decorative |
| `path_flower.png` | Wildflowers | 16×16 | Small decorative |
| `path_rock.png` | Rocks/boulders | 32×32 | Several sizes |
| `hidden_door.png` | Secret door (visible in Data Vision) | 32×64 | Layer 7 object |
| `data_vision_overlay.png` | Green wireframe overlay | 1280×720 | `Color(0, 0.8, 0, 0.3)` green tint |
| `data_vision_tag.png` | Object label tag | 64×16 | "Rock", "Tree [is_listening]", etc. |

### Data Vision Elements
When Data Vision is active, these overlays appear:
| Object Tag | Color | Special |
|---|---|---|
| "Rock" | Green wireframe | Normal object |
| "Tree [is_listening]" | Green wireframe | Suspicious metadata |
| "Hidden_Door [layer 7]" | Yellow wireframe | Secret |
| "Slime [HACKABLE]" | Red wireframe | Enemy target |

### Current Procedural Background (implemented in `_build_environment()`)

Warmer forest environment with a village glow on the horizon. Layered `ColorRect` nodes inside an `Environment` Control container at child index 0.

**Layer Stack (back to front):**

| Layer | Node Name | Color/Value | Animation |
|---|---|---|---|
| Sky | `Sky` | `Color(0.1, 0.07, 0.14)` warmer twilight | Static |
| Sunset Gradient | `SunsetGradient` | `Color(0.2, 0.1, 0.08, 0.2)` warm tint | Static |
| Distant Treeline | `DistantTreeline` | `Color(0.04, 0.06, 0.03, 0.6)` far silhouette | Static |
| Ground | `Ground` | `Color(0.06, 0.1, 0.04)` warmer forest green | Static |
| Dirt Path | `DirtPath` | `Color(0.14, 0.1, 0.05)` warm earthy | Static |
| Golden Trail | `GoldenTrail` | `Color(1.0, 0.85, 0.2, 0.2)` softer gold | Looping alpha pulse 0.1–0.3, 2.0s sine |
| Trees (×8) | trunk + canopy pairs | Trunk `Color(0.05, 0.035, 0.02)`, Canopy `Color(0.025, 0.055, 0.02)` denser | Canopy X-position sway 3–8px, 3.5–6.0s cycle |
| Fireflies (×10) | `Firefly_N` | `Color(0.9, 0.8, 0.3, 0.6)` warm gold-yellow | Looping X/Y drift 30–60px over 3–6s + alpha fade 0.1–0.7 over 1–2.5s |
| Village Glow | `VillageGlow` | `Color(1.0, 0.6, 0.2, 0.15)` warm orange, right side | Looping alpha pulse 0.1–0.25, 3.5s sine |
| Vignette Top | `VignetteTop` | `Color(0, 0, 0, 0.35)` | Static |
| Vignette Bottom | `VignetteBottom` | `Color(0, 0, 0.03, 0.25)` | Static |

**Letterbox Bars:** `camera.enable_letterbox(60.0, 0.8)` after fade-in; `camera.disable_letterbox(0.4)` before transition out.

**Environment Transition Progression (across all three cinematic scenes):**
1. **Crater** (cold, void, alien) → dark purples, floating debris, corruption
2. **Forest** (mysterious, twilight) → deep greens, fireflies, golden path
3. **Path** (warmer, approaching civilization) → warmer tones, village glow, denser trees

This color temperature shift mirrors Kaelen's emotional arc: shock → curiosity → cautious hope.

---

## 4.6 Oakhaven Village

**Scene**: `scenes/chapter1/oakhaven_village.tscn` | **Script**: `scripts/chapter1/ch1_oakhaven_village.gd`
**Exploration**: `scenes/exploration/oakhaven.tscn` | **Script**: `scripts/exploration/oakhaven_exploration.gd`

### Visual Description
A quaint medieval fantasy village — thatched roofs, cobblestone streets, market stalls, a central fountain. NPCs walk preset patrol routes. Everything looks like a charming JRPG village, but the skybox has visible seams and NPCs reset their paths too perfectly. An apothecary shop, a merchant stall, and a small auction area are present.

### Sprites Needed
| Sprite Name | Purpose | Suggested Size | Notes |
|---|---|---|---|
| `oakhaven_background.png` | Village panorama backdrop | 1280×720 | Quaint fantasy village |
| `oakhaven_tileset.png` | Ground/building tileset | 32×32 | Cobblestone, grass, dirt, water |
| `oakhaven_house_1.png` | Small cottage | 96×96 | Thatched roof |
| `oakhaven_house_2.png` | Larger building | 128×96 | Two-story |
| `oakhaven_shop_apothecary.png` | Apothecary building | 96×96 | With cauldron sign |
| `oakhaven_shop_merchant.png` | Merchant stall | 64×64 | With counter |
| `oakhaven_fountain.png` | Village fountain | 64×64 | Center of village |
| `oakhaven_market_stall.png` | Auction/market area | 64×48 | Wooden stall |
| `oakhaven_fence.png` | Wooden fence | 32×32 | Tileable |
| `oakhaven_well.png` | Village well | 32×48 | Decorative |
| `oakhaven_signpost.png` | Directional sign | 24×48 | Swinging in wind |
| `oakhaven_lamp.png` | Street lamp / torch | 16×48 | With flame animation |
| `skybox_seam.png` | Visible skybox error | 4×720 | Thin glitch line (intentional) |

### Environment Tileset
Use tileset at `res://assets/tilesets/oakhaven/sprout_lands.png` (key: `"tileset_oakhaven"`)
Forest areas use `res://assets/tilesets/oakhaven/mystic_woods.png` (key: `"tileset_oakhaven_forest"`)

### Environment Animations Used
- `"tree_sway"` — village trees
- `"grass_wave"` — lawn areas
- `"water_flow"` (`AnimConst.ENV_WATER_FLOW`) — fountain, stream
- `"torch_flicker"` (`AnimConst.ENV_TORCH_FLICKER`) — street lamps
- `"sign_swing"` (`AnimConst.ENV_SIGN_SWING`) — signpost
- `"door_open"` / `"door_close"` (`AnimConst.ENV_DOOR_OPEN` / `ENV_DOOR_CLOSE`) — shop doors

---

## 4.7 Tutorial Knight Arena

**Scene**: `scenes/chapter1/tutorial_knight_boss.tscn` | **Script**: `scripts/chapter1/ch1_tutorial_knight.gd`

### Visual Description
An enclosed arena — stone walls, torches along the edges, a flat stone floor. The Tutorial Knight stands at center. As the fight progresses to Phase 3, the arena begins glitching: walls flicker, corruption patches appear on the ground, the lighting goes erratic.

### Sprites Needed
| Sprite Name | Purpose | Suggested Size | Notes |
|---|---|---|---|
| `arena_background.png` | Stone arena backdrop | 1280×720 | Medieval arena walls |
| `arena_floor.png` | Stone floor tileset | 32×32 | Flat stone tiles |
| `arena_wall.png` | Arena wall tiles | 32×64 | Stone brick |
| `arena_torch.png` | Wall-mounted torch | 16×32 | With flame animation |
| `arena_pillar.png` | Stone pillar | 32×96 | At arena edges |
| `arena_corruption_crack.png` | Corruption seeping in (Phase 3) | 64×16 | Red-purple cracks |
| `arena_glitch_wall.png` | Glitched wall section (Phase 3) | 32×64 | Flickering tiles |

### Color Flashes Used
| Phase | Color Flash | Purpose |
|---|---|---|
| Phase 1→2 | `Color(1, 1, 1, 0.7)` white | Phase transition flash |
| Phase 2→3 | `Color(1, 0.8, 0, 0.7)` yellow | Escalation flash |
| Phase 3 | `Color(1, 0, 0, 0.2)` red tint | Corruption overlay |
| Defeat | `Color(0.7, 0.7, 0.7, 1.0)` grey | Knight deactivation |

---

## 4.8 Shatter Bridge — Chapter Transition

**Scene**: `scenes/chapter1/shatter_transition.tscn` | **Script**: `scripts/chapter1/ch1_shatter_transition.gd`

### Visual Description
A bridge spanning a divide between two worlds. On one side, the colorful fantasy landscape of Oakhaven. On the other, the dark steampunk industrial cityscape of Ironhold. The bridge itself shatters as Kaelen crosses — fragments falling into the void. The color palette shifts: warm greens and blues desaturate into browns and greys.

### Sprites Needed
| Sprite Name | Purpose | Suggested Size | Notes |
|---|---|---|---|
| `shatter_bridge.png` | The bridge structure | 640×128 | Fragmenting design |
| `shatter_fragment.png` | Bridge pieces breaking off | 16×16 each | Multiple variations |
| `shatter_oakhaven_bg.png` | Fantasy side background | 640×720 | Warm, colorful |
| `shatter_ironhold_bg.png` | Steampunk side background | 640×720 | Dark, industrial |
| `shatter_void.png` | The gap below the bridge | 1280×360 | Digital void / glitch abyss |

### Color Palette Transition
| Phase | Palette |
|---|---|
| Oakhaven Side | Normal warm colors |
| Mid-Bridge | Desaturation starts — `Color(0.6, 0.6, 0.7, 1.0)` muted |
| Ironhold Side | Brown-grey palette — `Color(0.5, 0.45, 0.35, 1.0)` industrial |

---

## 4.9 Combat Arena

**Scene**: `scenes/combat/combat_arena.tscn` | **Scripts**: `scripts/combat/combat_arena.gd`, `scripts/combat/player_combat.gd`, `scripts/combat/enemy_base.gd`

### Visual Description
The generic side-scrolling combat arena. Flat platform with background. Used for all combat encounters that aren't boss-specific. Simple layout: ground platform, optional platforms above.

### Sprites Needed
| Sprite Name | Purpose | Suggested Size | Notes |
|---|---|---|---|
| `combat_ground.png` | Main platform | 1280×32 | Tileable ground |
| `combat_platform.png` | Floating platform | 128×16 | Optional elevated platforms |
| `combat_background.png` | Arena background | 1280×720 | Changes per area context |

---

## 4.10 Environment Animations

These are general-purpose environment animations used across multiple scenes. Create these as SpriteFrames animations:

| Animation Name | Constant | Frames | FPS | Loop | Description | Sprite Size |
|---|---|---|---|---|---|---|
| `"tree_sway"` | `AnimConst.ENV_TREE_SWAY` | 4 | 6 | Yes | Gentle wind sway on trees | 64×96 |
| `"tree_tpose"` | `AnimConst.ENV_TREE_TPOSE` | 1 | 6 | Yes | Frozen T-pose tree (glitch) | 64×96 |
| `"grass_wave"` | `AnimConst.ENV_GRASS_WAVE` | 4 | 6 | Yes | Grass blowing in wind | 32×16 |
| `"water_flow"` | `AnimConst.ENV_WATER_FLOW` | 6 | 6 | Yes | Stream/river surface | 32×32 |
| `"water_uphill"` | `AnimConst.ENV_WATER_UPHILL` | 6 | 6 | Yes | Impossible uphill stream (glitch) | 32×32 |
| `"torch_flicker"` | `AnimConst.ENV_TORCH_FLICKER` | 4 | 8 | Yes | Wall torch flame | 16×32 |
| `"door_open"` | `AnimConst.ENV_DOOR_OPEN` | 4 | 10 | No | Door swinging open | 32×64 |
| `"door_close"` | `AnimConst.ENV_DOOR_CLOSE` | 4 | 10 | No | Door closing | 32×64 |
| `"bridge_creak"` | `AnimConst.ENV_BRIDGE_CREAK` | 3 | 6 | No | Bridge sway under weight | 128×32 |
| `"sign_swing"` | `AnimConst.ENV_SIGN_SWING` | 4 | 6 | Yes | Hanging sign sway | 24×32 |
| `"corruption_pulse"` | `AnimConst.ENV_CORRUPTION_PULSE` | 4 | 6 | Yes | Red-purple area pulse | 64×32 |
| `"null_texture"` | `AnimConst.ENV_NULL_TEXTURE` | 2 | 6 | Yes | Purple-black checkerboard loop | 32×32 |
| `"floating_debris"` | `AnimConst.ENV_FLOATING_DEBRIS` | 4 | 6 | Yes | Floating fragments | 16×16 |

---

## 4.11 Tilesets

### Required Tileset Files

| Tileset | Path | Area | Style |
|---|---|---|---|
| Oakhaven | `res://assets/tilesets/oakhaven/sprout_lands.png` | Village, farmland | Fantasy village, warm greens |
| Oakhaven Forest | `res://assets/tilesets/oakhaven/mystic_woods.png` | Forest paths, clearings | Dense forest, magical |
| Ironhold | `res://assets/tilesets/ironhold/steampunk.png` | Chapter 2 city | Industrial, gears, pipes |
| Necropolis | `res://assets/tilesets/necropolis/gothicvania.png` | Undead region | Dark gothic, bones |
| Celestia | `res://assets/tilesets/celestia/floating_islands.png` | Sky realm | Floating platforms, clouds |
| Deepblue | `res://assets/tilesets/deepblue/underwater.png` | Ocean region | Underwater, coral |

### Tileset Standards
- **Tile Size**: 32×32 px (matches Godot TileMap configuration)
- **Import**: Nearest filter, no mipmaps
- **Required layers**: Ground, walls, decorations, collision

---

# 5. VISUAL EFFECTS (VFX)

---

## 5.1 Particle Effects (CPUParticles2D)

These are created procedurally by `VFXLibrary` (`scripts/effects/vfx_library.gd`). Each can be replaced with a custom particle texture by setting `texture` on the CPUParticles2D node.

### Spawnable VFX Effects

| Effect Name | Particle Count | Lifetime | Color | Speed | Spread | Gravity |
|---|---|---|---|---|---|---|
| `"vfx_hit_spark"` | 8 | 0.3s | Yellow `(1, 0.9, 0.3)` | 120 | 180° | (0, 100) |
| `"vfx_critical_hit"` | 16 | 0.5s | Red-orange `(1, 0.3, 0.1)` | 200 | 360° | (0, 60) |
| `"vfx_perfect_delete"` | 24 | 0.7s | Green `(0, 1, 0.5)` | 150 | 360° | (0, -40) |
| `"vfx_heal_ring"` | 12 | 0.8s | Green `(0.3, 1, 0.4)` | 30 | 360° | (0, -60) |
| `"vfx_corruption_burst"` | 20 | 0.6s | Purple `(0.6, 0, 0.8)` | 100 | 360° | (0, 30) |
| `"vfx_enemy_death"` | 12 | 0.5s | Red `(1, 0.2, 0.2)` | 80 | 360° | (0, 50) |
| `"vfx_data_dissolve"` | 30 | 1.0s | Cyan `(0, 0.8, 1)` | 40 | 360° | (0, -80) |
| `"vfx_slime_splat"` | 10 | 0.5s | Green `(0.3, 0.9, 0.2)` | 100 | 180° | (0, 300) |
| `"vfx_dust_puff"` | 6 | 0.5s | Tan `(0.7, 0.65, 0.5, 0.5)` | 20 | 180° | (0, -10) |
| `"vfx_footstep_dust"` | 3 | 0.3s | Tan `(0.6, 0.55, 0.45, 0.4)` | 15 | 120° | (0, -5) |
| `"vfx_corruption_ambient"` | 4 | 2.0s | Purple `(0.5, 0, 0.7, 0.3)` | 10 | 360° | (0, -20) |
| `"vfx_glitch_sparkle"` | 6 | 0.4s | Cyan `(0, 1, 1, 0.6)` | 50 | 360° | ZERO |

### Enhanced Particle System (`scripts/effects/particle_system.gd`)

For larger environmental particle effects:

| Type | Amount | Lifetime | Color | Gravity | Speed | Use Case |
|---|---|---|---|---|---|---|
| `SPARKS` | 50 | 0.5s | Yellow→Orange→Red gradient | (0, 200) | 100–200 | Explosions, impacts |
| `SMOKE` | 30 | 2.0s | Grey `(0.3, 0.3, 0.3, 0.5)` fade | (0, -50) | 20–40 | Fire aftermath, steam |
| `GLITCH` | 100 | 0.3s | Cyan→Magenta→Black gradient | — | 150–300 | Reality tears, corruption |
| `MAGIC` | 80 | 1.5s | White→Purple→Blue gradient | (0, -30) | 20–60 | Elara's casting, portals |
| `DUST` | 50 | 5.0s | White `(1, 1, 1, 0.3)` | (0, 20) | 5–15 | Indoor ambient |
| `RAIN` | 200 | 2.0s | Light blue `(0.7, 0.7, 1, 0.6)` | (0, 500) | 200–300 | Weather |
| `SNOW` | 100 | 10.0s | White `(1, 1, 1, 0.8)` | (0, 30) | 10–30 | Weather |
| `FIRE` | 60 | 0.8s | White→Orange→Red→Dark gradient | (0, -100) | 50–100 | Torches, campfires |

---

## 5.2 VFX Sprite Animations

If you want to create hand-drawn VFX sprites (AnimatedSprite2D) instead of particles, use these names in SpriteFrames:

| Animation Name | Constant | Frames | FPS | Size | Description |
|---|---|---|---|---|---|
| `"vfx_slash_arc"` | `AnimConst.VFX_SLASH_ARC` | 4 | 15 | 32×32 | White arc trail from sword swing |
| `"vfx_hit_spark"` | `AnimConst.VFX_HIT_SPARK` | 6 | 15 | 32×32 | Impact spark burst |
| `"vfx_heal_ring"` | `AnimConst.VFX_HEAL_RING` | 8 | 15 | 64×64 | Green ring rising from below |
| `"vfx_corruption_burst"` | `AnimConst.VFX_CORRUPTION_BURST` | 8 | 15 | 64×64 | Red-purple corruption explosion |
| `"vfx_hack_particles"` | `AnimConst.VFX_HACK_PARTICLES` | 6 | 15 | 32×32 | Pink data fragments |
| `"vfx_perfect_delete"` | `AnimConst.VFX_PERFECT_DELETE` | 8 | 15 | 64×64 | Red disintegration sweep |
| `"vfx_dust_puff"` | `AnimConst.VFX_DUST_PUFF` | 5 | 15 | 32×32 | Small dust cloud |
| `"vfx_glitch_square"` | `AnimConst.VFX_GLITCH_SQUARE` | 4 | 15 | 32×32 | Random colored pixel squares |
| `"vfx_data_stream"` | `AnimConst.VFX_DATA_STREAM` | 8 | 15 | 32×32 | Green falling Matrix-style text |
| `"vfx_shatter"` | `AnimConst.VFX_SHATTER` | 12 | 15 | 128×128 | Glass/world shattering |
| `"vfx_level_up"` | `AnimConst.VFX_LEVEL_UP` | 10 | 15 | 64×64 | Gold ring expanding upward |
| `"vfx_buff_apply"` | `AnimConst.VFX_BUFF_APPLY` | 4 | 15 | 32×32 | Blue shimmer on target |
| `"vfx_debuff_apply"` | `AnimConst.VFX_DEBUFF_APPLY` | 4 | 15 | 32×32 | Red shimmer on target |
| `"vfx_portal_open"` | `AnimConst.VFX_PORTAL_OPEN` | 8 | 15 | 64×64 | Swirling portal appears |
| `"vfx_teleport"` | `AnimConst.VFX_TELEPORT` | 6 | 15 | 32×32 | Blink in/out effect |

---

## 5.3 Geometric Effects (Tween-Based)

These are procedurally created shapes animated with tweens. They can be replaced with sprites:

| Effect | Type | Color | Duration | Size |
|---|---|---|---|---|
| `"vfx_slash_arc"` | Arc shape | White `(0.9, 0.95, 1.0)` | 0.2s | 60×8 |
| `"vfx_hack_beam"` | Beam line | Green `(0, 1, 0.5)` | 0.5s | width=4 |
| `"vfx_hack_circle"` | Circle outline | Green `(0, 1, 0.5, 0.4)` | 0.8s | radius=40 |

---

## 5.4 Text-Based VFX

Floating text effects spawned by `VFXLibrary`:

| Function | Font Size | Default Color | Rise Distance | Duration |
|---|---|---|---|---|
| `spawn_damage_number(value, pos)` | 20 (normal) / 28 (crit) | White / Red `(1, 0.2, 0.1)` crit | -40px Y | 0.8s |
| `spawn_pickup_text(text, pos)` | 16 | Gold `(1, 0.85, 0.1)` | -30px Y | 1.0s |
| `spawn_status_indicator(text, pos)` | 14 | Green `(0.3, 1, 0.5)` buff / Red `(1, 0.3, 0.3)` debuff | -20px Y | 1.5s |

---

## 5.5 Color Flashes & Overlays

Full-screen color flashes used during dramatic moments. These are `ColorRect` nodes that flash briefly:

| Scene | Color | Duration | Purpose |
|---|---|---|---|
| Elara Meeting | `Color(0.5, 0, 0.5, 0.6)` purple | 0.3s | Glitch magic flash |
| Elara Meeting | `Color(1, 1, 1, 0.5)` white | 0.2s | Magic burst |
| Elara Meeting | `Color(1, 0, 1)` magenta | 0.1s | Glitch artifact |
| Glitch Crater | `Color(0.5, 1.0, 0.5)` green | varies | Boot text glow |
| Glitch Crater | `Color(1, 1, 0.3)` yellow | varies | Warning entry |
| Glitch Crater | `Color(1, 0.3, 0.3)` red | varies | Error entry |
| Glitch Crater | `Color(0, 0, 0.8, 1.0)` blue | 0.5s | BSOD flash |
| Path to Oakhaven | `Color(0, 0.8, 0, 0.3)` green | sustained | Data Vision overlay |
| Tutorial Knight | `Color(1, 1, 1, 0.7)` white | 0.3s | Phase 1→2 transition |
| Tutorial Knight | `Color(1, 0.8, 0, 0.7)` yellow | 0.3s | Phase 2→3 transition |
| Tutorial Knight | `Color(1, 0, 0, 0.2)` red | sustained | Phase 3 corruption |
| Shatter Transition | `Color(0.6, 0.6, 0.7, 1.0)` grey | gradual | Desaturation |
| Shatter Transition | `Color(0.5, 0.45, 0.35, 1.0)` brown | gradual | Ironhold palette |
| Post-Combat | `Color(1, 0, 0, 0.7)` red | 0.3s | Danger flash |
| Post-Combat | `Color(0.2, 0, 0.2, 0.5)` dark purple | sustained | Administrator shadow |
| Post-Combat | `Color(0, 0, 0, 0.9)` near-black | 0.5s | Silhouette reveal |
| Combat (Dash) | `Color(0.5, 0.8, 1.0, 0.7)` light blue | 0.15s | Dash i-frame flash |
| Combat (Parry) | `Color(0.3, 1.0, 0.3)` green | 0.1s | Successful parry |
| Combat (Block) | `Color(0.7, 0.7, 1.0)` light purple | sustained | Block stance |

---

## 5.6 Screen Transitions

**Script**: `scripts/effects/screen_transition.gd`

### Transition Types

| Type | Enum Value | Visual Description |
|---|---|---|
| Fade | `FADE` | Simple black fade in/out |
| Wipe Left | `WIPE_LEFT` | Black bar sweeps from right to left |
| Wipe Right | `WIPE_RIGHT` | Black bar sweeps from left to right |
| Wipe Up | `WIPE_UP` | Black bar sweeps upward |
| Wipe Down | `WIPE_DOWN` | Black bar sweeps downward |
| Circle In | `CIRCLE_IN` | Circle closes to center |
| Circle Out | `CIRCLE_OUT` | Circle opens from center |
| Pixelate | `PIXELATE` | Image pixelates to black |
| Glitch | `GLITCH` | 10 random color flashes then black |
| Shatter | `SHATTER` | 15 color steps through `[WHITE, CYAN, MAGENTA, BLACK, RED]` |
| Diamond | `DIAMOND` | Diamond wipe pattern |
| Crossfade | `CROSSFADE` | Alpha blend between scenes |

### Functions
```gdscript
ScreenTransition.transition_out(TransitionType.FADE, 1.0)
ScreenTransition.transition_in(TransitionType.FADE, 1.0)
ScreenTransition.scene_transition("res://scenes/next.tscn", TransitionType.FADE, TransitionType.FADE)
```

### Usage Across Scenes
| Scene | Transition Out | Transition In | Letterbox |
|---|---|---|---|
| Flight 707 → Crash | `GLITCH` | `FADE` | — |
| Crash → Glitch Crater | `FADE` | `FADE` (3.0s) | Enabled (60px, 0.8s) after fade-in |
| Glitch Crater → Elara | `GLITCH` (1.5s) | `FADE` | Disabled (0.4s) before transition |
| Elara → Path | `FADE` (1.5s) | `FADE` | Disabled (0.4s) before transition |
| Path → Oakhaven | `FADE` (1.5s) | `FADE` | Disabled (0.4s) before transition |
| Oakhaven → Knight | `FADE` | `FADE` | — |
| Knight → Shatter | `FADE` | `FADE` | — |
| Shatter Transition | 12 rapid `GlitchOverlay` flashes | Palette shift | — |

---

# 6. SHADERS

All shader files are in `AethelgardPrototype/shaders/`.

---

## 6.1 CRT Effect

**File**: `shaders/crt_effect.gdshader`

Makes the screen look like an old CRT monitor. Used in the Flight 707 prologue.

### Uniforms
| Uniform | Type | Default | Range | Description |
|---|---|---|---|---|
| `distortion` | float | 0.1 | 0.0–0.5 | Screen curvature distortion |
| `scanline_intensity` | float | 0.15 | 0.0–1.0 | Visibility of horizontal scanlines |
| `scanline_count` | float | 800 | 100–2000 | Number of scanlines |
| `vignette` | float | 0.3 | 0.0–1.0 | Edge darkening |
| `brightness` | float | 1.2 | 0.5–2.0 | Overall brightness |
| `contrast` | float | 1.1 | 0.5–2.0 | Color contrast |

### Flight 707 Settings
`distortion=0.08`, `scanline_intensity=0.12`, `scanline_count=720`, `vignette=0.25`, `brightness=1.15`, `contrast=1.08`

---

## 6.2 Advanced Glitch

**File**: `shaders/advanced_glitch.gdshader`

Heavy glitch distortion with color separation and block displacement. Used for GlitchOverlay and corruption effects.

### Uniforms
| Uniform | Type | Default | Range | Description |
|---|---|---|---|---|
| `glitch_strength` | float | 0.0 | 0.0–1.0 | Overall glitch intensity |
| `time_offset` | float | 0.0 | — | Time offset for animation |
| `block_size` | float | 50.0 | 10–200 | Size of displacement blocks |

---

## 6.3 Atmospheric Light

**File**: `shaders/atmospheric_light.gdshader`

Adds light rays, fog, and atmospheric depth to scenes.

### Uniforms
| Uniform | Type | Default | Description |
|---|---|---|---|
| `light_color` | vec4 | `(1, 0.9, 0.7, 1)` warm white | Color of light source |
| `light_position` | vec2 | — | Position of light source in UV space |
| `light_intensity` | float | 1.5 | Brightness of light rays |
| `ambient` | float | 0.3 | Base ambient light level |
| `fog_density` | float | 0.2 | Thickness of fog |
| `fog_color` | vec4 | `(0.5, 0.6, 0.8, 1)` blue-grey | Color of fog |

---

## 6.4 Hologram

**File**: `shaders/hologram.gdshader`

Makes a sprite look like a holographic projection. Scanlines, flicker, and cyan tint.

### Uniforms
| Uniform | Type | Default | Description |
|---|---|---|---|
| `hologram_color` | vec4 | `(0, 1, 1, 1)` cyan | Base hologram tint |
| `scan_speed` | float | 2.0 | Speed of scanning line |
| `flicker_speed` | float | 10.0 | Frequency of flicker |
| `line_density` | float | 100.0 | Density of horizontal lines |
| `distortion` | float | 0.05 | Amount of wave distortion |

---

# 7. UI ELEMENTS

---

## 7.1 Dialogue System

Two dialogue systems exist — `DialogueManager` (autoload singleton) and `DialogueUI` (scene-based). Both can be skinned with sprites.

### DialogueManager (Primary — `scripts/dialogue_manager.gd`)

**Layer**: CanvasLayer 100

| Element | Current Style | Size | Notes |
|---|---|---|---|
| Background Panel | `Color(0.03, 0.03, 0.08, 0.94)` dark | 1000×140 | Bottom-center of screen |
| Border | `Color(0, 0.7, 1, 0.5)` blue-cyan | 2px | Panel outline |
| Portrait Box | 72×72 ColorRect | 72×72 | Left side of panel |
| Speaker Name | Bold, colored per character | font_size 18 | Above dialogue text |
| Dialogue Text | Typewriter effect, 30 chars/sec | font_size 16 | Main text area |
| Advance Indicator | "▼ [SPACE]" blinking | font_size 14 | Bottom-right corner |
| Fast Forward | 120 chars/sec when held | — | Hold Space |

### Speaker Portrait Colors (DialogueManager)
| Speaker | Color |
|---|---|
| Kaelen | `Color(0.9, 0.95, 1.0)` white-blue |
| Elara | `Color(0.8, 0.5, 1.0)` purple |
| System | `Color(0, 1, 1)` cyan |
| Data Vision | `Color(0, 1, 0)` green |
| Mira | `Color(0.9, 0.6, 0.2)` orange |

### DialogueUI (Scene-based — `scripts/ui/dialogue_ui.gd`)

| Element | Current Style | Size |
|---|---|---|
| Background | `Color(0.05, 0.05, 0.12, 0.92)` | Panel |
| Border | `Color(0, 0.8, 1, 0.6)` | 2px |
| Portrait | 80×80 ColorRect | 80×80 |
| Typewriter Speed | 35 chars/sec | — |
| Advance Indicator | "▼ Press SPACE" | — |

### Speaker Portrait Colors (DialogueUI)
| Speaker | Color |
|---|---|
| Kael / Player | `Color(0.2, 0.5, 0.9)` blue |
| Elara | `Color(0, 0.85, 0.5)` green |
| Mira | `Color(0.9, 0.6, 0.2)` orange |
| Elder | `Color(0.7, 0.7, 0.8)` silver |
| Knight | `Color(0.4, 0.4, 0.5)` dark grey |
| System | `Color(0, 1, 1)` cyan |
| ??? | `Color(0.6, 0, 0.8)` purple |

### Portrait Mood Animations (DialogueUI)
| Mood | Effect |
|---|---|
| `angry` | Shake |
| `sad` | Desaturate to `Color(0.6, 0.6, 0.8)` |
| `excited` | Bounce |
| `glitched` | Random position offset |

### Sprites Needed to Replace Dialogue UI
| Sprite Name | Purpose | Size |
|---|---|---|
| `dialogue_panel.png` | Dialogue box background | 1000×140 (9-patch) |
| `dialogue_portrait_kaelen.png` | Kaelen's face portrait | 72×72 or 80×80 |
| `dialogue_portrait_elara.png` | Elara's face portrait | 72×72 or 80×80 |
| `dialogue_portrait_mira.png` | Mira's face portrait | 72×72 or 80×80 |
| `dialogue_portrait_knight.png` | Knight's face portrait | 72×72 or 80×80 |
| `dialogue_portrait_system.png` | System/terminal portrait | 72×72 or 80×80 |
| `dialogue_portrait_unknown.png` | Unknown speaker (???) | 72×72 or 80×80 |
| `dialogue_advance_arrow.png` | "Press Space" indicator | 16×16 |
| `dialogue_nameplate.png` | Speaker name background | 120×24 (9-patch) |

---

## 7.2 Combat HUD

**Script**: `scripts/ui/combat_hud_effects.gd`

### HUD Elements
| Element | Color/Style | Purpose |
|---|---|---|
| HP Bar | Red fill, red flash `Color(1, 0.3, 0.3)` on damage | Player health |
| HP Bar (healing) | Green flash `Color(0.3, 1, 0.4)` | Health recovery |
| Glitch Meter | Purple flash `Color(0.8, 0.2, 1.0)` on increase | Corruption level |
| Low HP Warning | Red pulse loop: `Color(1,0.3,0.3)` ↔ `Color(1,0.6,0.6)` | Low health alert |
| Boss HP Bar | Dramatic fill animation, scale pop | Boss health display |
| Boss Name | Slam animation: scale (2,2)→(1,1) | Boss intro text |
| Chapter Title | Dim BG overlay, cyan `Color(0, 0.8, 1)` chapter label | Chapter announcements |

### Sprites Needed
| Sprite Name | Purpose | Size |
|---|---|---|
| `hud_hp_bar_bg.png` | HP bar background | 200×20 |
| `hud_hp_bar_fill.png` | HP bar fill (stretchable) | 196×16 |
| `hud_hp_bar_damage.png` | Damage trail (red ghost) | 196×16 |
| `hud_glitch_meter_bg.png` | Corruption meter background | 200×20 |
| `hud_glitch_meter_fill.png` | Corruption fill | 196×16 |
| `hud_boss_bar_bg.png` | Boss HP bar background | 400×24 |
| `hud_boss_bar_fill.png` | Boss HP bar fill | 396×20 |
| `hud_portrait_frame.png` | Player portrait frame | 48×48 |

---

## 7.3 Interaction Prompts

**Script**: `scripts/ui/interaction_prompt.gd` | **Layer**: CanvasLayer (floating above world)

### Prompt Types & Colors
| Type | Color | Icon | Primary Key | Secondary Key |
|---|---|---|---|---|
| `"npc"` | Green `(0.6, 1.0, 0.6)` | `>>` | [F] Talk | [E] Inspect |
| `"shop"` | Yellow `(1.0, 0.9, 0.4)` | `$>` | [F] Browse | [E] Check Prices |
| `"item"` | Blue `(0.4, 0.8, 1.0)` | `?>` | [F] Pick Up | [E] Examine |
| `"door"` | Purple `(0.8, 0.6, 1.0)` | `\|>` | [F] Enter | [E] Check |
| `"enemy"` | Red `(1.0, 0.3, 0.3)` | `!>` | [J] Attack | [E] Scan |
| `"hackable"` | Neon Green `(0.0, 1.0, 0.5)` | `#>` | [E] Root Access | [TAB] Data Vision |
| `"default"` | Yellow `(1.0, 1.0, 0.6)` | `>>` | [F] Interact | [E] Inspect |

### Visual Style
- **Panel BG**: `Color(0.05, 0.05, 0.1, 0.85)` dark
- **Border**: `Color(0.3, 0.8, 0.3, 0.7)` green
- **Prompt Text**: font_size 13
- **Detail Text**: font_size 10, `Color(0.5, 0.5, 0.6)`
- **Animation**: Bob ±3px at speed 2.5, fade in/out

### Sprites Needed
| Sprite Name | Purpose | Size |
|---|---|---|
| `prompt_bubble.png` | Prompt background (9-patch) | 120×40 |
| `prompt_icon_npc.png` | NPC interaction icon | 16×16 |
| `prompt_icon_shop.png` | Shop icon | 16×16 |
| `prompt_icon_item.png` | Item pickup icon | 16×16 |
| `prompt_icon_door.png` | Door/entrance icon | 16×16 |
| `prompt_icon_enemy.png` | Enemy icon | 16×16 |
| `prompt_icon_hack.png` | Hackable target icon | 16×16 |

---

## 7.4 Status Window

**Script**: `scripts/ui/status_window.gd` | **Layer**: 99 | **Toggle**: `I` key

### Visual Style
- **Panel**: `Color(0.05, 0.08, 0.05, 0.92)` dark green-tinted background
- **Border**: `Color(0.0, 0.8, 0.3, 0.7)` green
- **Text**: `Color(0.0, 1.0, 0.4)` bright green, font_size 11
- **Size**: 380×600 px
- **Style**: ASCII box-drawing characters, terminal/debugger aesthetic
- **Auto-refresh**: Every 0.5s

### Sections Displayed
| Section | Content |
|---|---|
| IDENTITY | Name, class, level |
| HEALTH | Current/max HP |
| RAM | Memory fragments collected |
| CORRUPTION | Percentage + severity label (NOMINAL/ELEVATED/WARNING/CRITICAL) |
| COMBAT | Attack, defense stats |
| ABILITIES | Unlocked abilities list |
| STORY FLAGS | Current progress flags |

### Sprites Needed
| Sprite Name | Purpose | Size |
|---|---|---|
| `status_window_bg.png` | Terminal-style background | 380×600 (9-patch) |
| `status_window_border.png` | Green border frame | 384×604 |

---

## 7.5 Pause Screen

**Script**: `scripts/ui/pause_screen.gd` | **Layer**: 100 | **Toggle**: `Escape` key

### Visual Style
- **Panel**: Dark background with green accent
- **Style**: IDE-like tabbed interface

### 4 Tabs
| Tab | Title | Content |
|---|---|---|
| 1 | **Assets** | Player inventory from GameManager |
| 2 | **Functions** | 6 abilities: `root_access`, `data_vision`, `perfect_delete`, `garbage_collection`, `pogo_strike`, `sprint_dash` |
| 3 | **Ticket Backlog** | Dynamic quest tickets from story_flags |
| 4 | **Map** | 7 world regions, Source Key counter |

### Features
- `block_pause()` / `unblock_pause()` — lock during cutscenes
- Green accent color theme

### Sprites Needed
| Sprite Name | Purpose | Size |
|---|---|---|
| `pause_bg.png` | Full-screen dim overlay | 1280×720 |
| `pause_panel.png` | Central panel (9-patch) | 800×500 |
| `pause_tab_active.png` | Active tab button | 120×30 |
| `pause_tab_inactive.png` | Inactive tab button | 120×30 |
| `pause_icon_assets.png` | Inventory tab icon | 24×24 |
| `pause_icon_functions.png` | Abilities tab icon | 24×24 |
| `pause_icon_tickets.png` | Quests tab icon | 24×24 |
| `pause_icon_map.png` | Map tab icon | 24×24 |
| `pause_map_region.png` | Map region marker | 32×32 (×7) |
| `pause_source_key.png` | Source Key icon | 24×24 |

---

## 7.6 Root Access UI

**Style**: IDE/code editor window that unfolds over the screen

### Visual Description
When Kaelen uses Root Access on a hackable target, an IDE-like window appears showing the target's "code" — a list of properties. Hackable properties are highlighted in green. The player selects a property and modifies it. The window has a terminal aesthetic with monospace font.

### Sprites Needed
| Sprite Name | Purpose | Size |
|---|---|---|
| `root_access_bg.png` | IDE window background | 600×400 (9-patch) |
| `root_access_title_bar.png` | Window title bar | 600×24 |
| `root_access_property_normal.png` | Non-hackable property row | 560×24 |
| `root_access_property_hackable.png` | Hackable property row (green highlight) | 560×24 |
| `root_access_cursor.png` | Selection cursor | 16×16 |
| `root_access_confirm.png` | Confirm button | 80×24 |

---

## 7.7 UI Animations

These are tween-based UI animations. If you want to use sprite-based versions, create SpriteFrames with these names:

| Animation Name | Constant | Frames | FPS | Description |
|---|---|---|---|---|
| `"ui_dialogue_open"` | `AnimConst.UI_DIALOGUE_OPEN` | 3 | 12 | Dialogue box slides up from bottom |
| `"ui_dialogue_close"` | `AnimConst.UI_DIALOGUE_CLOSE` | 3 | 12 | Box slides down offscreen |
| `"ui_root_access_open"` | `AnimConst.UI_ROOT_ACCESS_OPEN` | 4 | 12 | IDE window unfolds |
| `"ui_root_access_close"` | `AnimConst.UI_ROOT_ACCESS_CLOSE` | 4 | 12 | IDE window folds shut |
| `"ui_hp_damage"` | `AnimConst.UI_HP_BAR_DAMAGE` | 3 | 12 | Red flash on HP loss |
| `"ui_hp_heal"` | `AnimConst.UI_HP_BAR_HEAL` | 3 | 12 | Green pulse on HP gain |
| `"ui_glitch_rise"` | `AnimConst.UI_GLITCH_METER_RISE` | 3 | 12 | Meter sparks as it fills |
| `"ui_gold_popup"` | `AnimConst.UI_GOLD_POPUP` | 3 | 12 | +Gold floating text |
| `"ui_xp_popup"` | `AnimConst.UI_XP_POPUP` | 3 | 12 | +XP floating text |
| `"ui_item_get"` | `AnimConst.UI_ITEM_GET` | 4 | 12 | Item acquire fanfare |
| `"ui_chapter_title"` | `AnimConst.UI_CHAPTER_TITLE` | 6 | 12 | Fade-in chapter text |
| `"ui_boss_intro"` | `AnimConst.UI_BOSS_INTRO` | 6 | 12 | Boss name slam effect |

---

# 8. CAMERA SYSTEM

**Script**: `scripts/camera/cinematic_camera.gd`

### Constants
- `MAX_SHAKE_OFFSET = 24.0` px
- `MAX_SHAKE_ROTATION = 2.0` degrees
- Letterbox bars: 1280×72 px, layer 90, `Color.BLACK`

### Camera Functions

| Function | Parameters | Description |
|---|---|---|
| `move_to(pos, duration)` | Vector2, float | Smooth tween pan to position |
| `pan_by(offset, duration)` | Vector2, float | Relative pan by offset |
| `zoom_to(zoom_level, duration)` | Vector2, float | Smooth zoom change |
| `shake(intensity, duration)` | float, float | Legacy intensity shake |
| `add_trauma(amount)` | float 0–1 | Trauma-based shake (quadratic falloff) |
| `earthquake_shake(duration)` | float | Intensity 20.0→0.0 over duration |
| `impact_shake()` | — | `shake(15.0, 0.3)` |
| `explosion_shake()` | — | `shake(25.0, 0.5)` |
| `focus_on(node, duration)` | Node2D, float | Focus camera on target node |
| `dolly_shot(pos, zoom, dur)` | Vector2, Vector2, float | Move + zoom simultaneously |
| `dutch_angle(degrees, dur)` | float, float | Camera tilt |
| `tracking_shot(waypoints, dur)` | Array[Vector2], float | Multi-waypoint rail shot |
| `push_in(amount, duration)` | float=0.3, float=1.5 | Dramatic zoom in |
| `pull_out(amount, duration)` | float=0.3, float=1.5 | Dramatic zoom out |
| `whip_pan(target, duration)` | Vector2, float=0.3 | Fast dramatic reveal pan |
| `enable_letterbox(height, dur)` | float=72, float=0.6 | Cinematic bars slide in |
| `disable_letterbox(duration)` | float=0.4 | Bars slide out |

### Camera Usage Across Scenes

| Scene | Camera Calls |
|---|---|
| Glitch Crater | zoom 0.8→1.2→1.5, `move_to()`, `shake(5.0, 0.3)`, `enable_letterbox(60, 0.8)`, `disable_letterbox(0.4)` |
| Elara Meeting | `move_to()`, `shake(10.0, 0.5)`, `shake(3.0, 0.2)`, `enable_letterbox(60, 0.8)`, `disable_letterbox(0.4)` |
| Path to Oakhaven | zoom, `move_to()`, `shake(5.0, 0.3)`, `shake(3.0, 0.2)`, `enable_letterbox(60, 0.8)`, `disable_letterbox(0.4)` |
| Oakhaven Village | Camera shake ±8/±5/±3/±10/±15 px (boar combat) |
| Tutorial Knight | `shake(20.0, 0.5)`, `earthquake_shake(1.0)` |
| Shatter Transition | `earthquake_shake(1.5)`, `shake(4.0, 0.5)`, `move_to()` |
| Flight 707 | zoom 0.9→1.4, shake 5.0→20.0+, `earthquake_shake(2.0)` |

---

# 9. AUDIO (PLACEHOLDER)

> **No audio has been implemented yet.** When adding audio, here are the sound effects and music tracks that should be created:

### Sound Effects Needed

| Category | Sound | Trigger |
|---|---|---|
| **Player** | Footstep (walk) | Each walk frame |
| **Player** | Footstep (sprint) | Each sprint frame, faster |
| **Player** | Jump | On jump input |
| **Player** | Land | On ground contact |
| **Player** | Sword swing (×3) | attack_1, attack_2, attack_3 |
| **Player** | Hurt grunt | On damage taken |
| **Player** | Death | On death |
| **Player** | Dash whoosh | On dash |
| **Player** | Pogo bounce | On pogo hit |
| **Player** | Parry clang | On successful parry |
| **Player** | Block thud | On damage blocked |
| **Player** | Heal chime | On heal |
| **Hack** | Root Access open | `hack_start` |
| **Hack** | Hacking loop | `hack_loop` |
| **Hack** | Root Access success | `hack_end` |
| **Hack** | Perfect Delete | Execution finish |
| **Slime** | Squelch (idle) | Idle jiggle |
| **Slime** | Hop | On hop movement |
| **Slime** | Splat (death) | On death |
| **Boar** | Snort | Idle |
| **Boar** | Charge rumble | During charge |
| **Boar** | Enrage roar | On enrage |
| **Knight** | Metal footsteps | Walk |
| **Knight** | Sword slash | Attacks |
| **Knight** | Armor clang (hurt) | On hit |
| **Knight** | Error buzz | Phase 3 glitch |
| **Knight** | Deactivation hum | Death dissolve |
| **UI** | Dialogue blip | Per character typed |
| **UI** | Menu select | Button hover |
| **UI** | Menu confirm | Button press |
| **UI** | Pause open/close | Escape press |
| **UI** | Chapter title woosh | Chapter announcement |
| **UI** | Boss intro slam | Boss name appear |
| **UI** | Item acquire jingle | Item pickup |
| **UI** | Gold pickup clink | Gold gained |
| **UI** | XP chime | XP gained |
| **UI** | Level up fanfare | Level up |
| **Environment** | Wind ambience | Outdoor areas |
| **Environment** | Village ambience | Oakhaven |
| **Environment** | Water flow | Near streams |
| **Environment** | Torch crackle | Near torches |
| **Environment** | Corruption hum | Near corrupt zones |
| **Glitch** | Static burst | Glitch events |
| **Glitch** | Digital corruption | Corruption increase |
| **Glitch** | Data Vision activate | Tab press |
| **Glitch** | Screen transition swoosh | Scene changes |
| **Airplane** | Engine hum | Flight 707 ambient |
| **Airplane** | Cabin ambience | Background noise |
| **Airplane** | Turbulence rumble | During shaking |
| **Airplane** | Crash explosion | Crash sequence |

### Music Tracks Needed

| Track | Scene | Mood |
|---|---|---|
| Main Menu Theme | Main menu | Mysterious, digital, atmospheric |
| Flight 707 | Prologue cabin | Calm with growing unease |
| Crash/Boot Sequence | Prologue crash, boot | Tense electronic, building |
| Glitch Crater | Awakening | Eerie, alien, wonder |
| Forest/Path | Elara meeting, Path | Peaceful with underlying code |
| Oakhaven Village | Village exploration | Warm fantasy village, slight artificiality |
| Combat (Normal) | Slime, Boar fights | Fast-paced, action |
| Tutorial Knight Boss | Boss fight | Intense, epic, glitching in Phase 3 |
| Shatter Transition | Bridge crossing | Dramatic, shifting genres |
| Victory Jingle | After defeating enemies | Short, triumphant |
| Game Over | Death screen | Somber, digital funeral |

---

# 10. TECHNICAL REFERENCE

---

## 10.1 Sprite Sheet Creation Guide

### Format Requirements
- **File Format**: PNG with transparency
- **Color Mode**: RGBA
- **Layout**: Horizontal strip (all frames in a single row per animation)
- **Naming**: `character_animation.png` (e.g., `kaelen_idle.png`, `slime_hop.png`)

### Creating a SpriteFrames Resource
1. In Godot, right-click in FileSystem → **New Resource** → **SpriteFrames**
2. Save as `.tres` file (e.g., `kaelen_combat.tres`)
3. In the SpriteFrames editor:
   - Click **Add Animation** for each animation name
   - Name it **exactly** as listed in this guide (e.g., `"idle"`, `"run"`, `"attack_1"`)
   - Import the sprite sheet and use **Add Frames from Sprite Sheet**
   - Set the correct number of columns/rows
   - Set FPS per animation
   - Toggle **Loop** for animations marked "Yes" in the tables above

### Alternative: Individual Frame Files
Instead of sprite sheets, you can use individual PNG frames:
- Name them: `animation_name_01.png`, `animation_name_02.png`, etc.
- Drag all frames into the SpriteFrames animation timeline

---

## 10.2 Godot Import Settings

For **all pixel art sprites**:

| Setting | Value |
|---|---|
| Filter Mode | **Nearest** (no smoothing) |
| Mipmaps | **Off** |
| Fix Alpha Border | **Off** |
| Premultiplied Alpha | **Off** |
| Process → Size Limit | 0 (no limit) |

In `Project Settings → Rendering → Textures`:
- Default Texture Filter: **Nearest**

---

## 10.3 Frame Counts Reference

Complete frame counts from `AnimConst.FRAME_COUNTS`:

### Player Combat
| Animation | Frames | | Animation | Frames |
|---|---|---|---|---|
| `idle` | 6 | | `run` | 8 |
| `jump_up` | 3 | | `jump_peak` | 2 |
| `fall` | 3 | | `land` | 3 |
| `attack_1` | 5 | | `attack_2` | 5 |
| `attack_3` | 7 | | `attack_air` | 6 |
| `hurt` | 3 | | `die` | 8 |
| `dash` | 4 | | `heal` | 6 |
| `hack_start` | 4 | | `hack_loop` | 4 |
| `hack_end` | 4 | | `perfect_delete` | 6 |

### Player Top-Down
| Animation | Frames | | Animation | Frames |
|---|---|---|---|---|
| `td_idle_down/up/left/right` | 2 each | | `td_walk_down/up/left/right` | 4 each |
| `td_interact` | 3 | | | |

### Elara
| Animation | Frames | | Animation | Frames |
|---|---|---|---|---|
| `elara_idle` | 6 | | `elara_walk` | 6 |
| `elara_talk` | 4 | | `elara_cast` | 8 |
| `elara_buffer_overflow` | 10 | | `elara_glitch_arm` | 6 |
| `elara_laugh` | 4 | | `elara_worry` | 3 |
| `elara_spawn_in` | 10 | | `elara_point` | 3 |
| `elara_disappear` | 8 | | | |

### Enemies
| Animation | Frames | | Animation | Frames |
|---|---|---|---|---|
| `slime_idle` | 4 | | `slime_hop` | 6 |
| `slime_attack` | 5 | | `slime_hurt` | 3 |
| `slime_die` | 8 | | `slime_bounce` | 4 |
| `slime_hacked` | 4 | | `boar_idle` | 4 |
| `boar_charge` | 6 | | `boar_attack` | 5 |
| `boar_hurt` | 3 | | `boar_die` | 12 |
| `boar_enrage` | 6 | | | |

### Tutorial Knight
| Animation | Frames | | Animation | Frames |
|---|---|---|---|---|
| `knight_idle` | 4 | | `knight_walk` | 6 |
| `knight_slash_horizontal` | 7 | | `knight_crush_vertical` | 8 |
| `knight_error_attack` | 10 | | `knight_hurt` | 3 |
| `knight_stunned` | 4 | | `knight_hacked` | 1 |
| `knight_die` | 15 | | `knight_telegraph` | 4 |
| `knight_phase_shift` | 6 | | | |

### VFX
| Animation | Frames | | Animation | Frames |
|---|---|---|---|---|
| `vfx_slash_arc` | 4 | | `vfx_hit_spark` | 6 |
| `vfx_heal_ring` | 8 | | `vfx_corruption_burst` | 8 |
| `vfx_hack_particles` | 6 | | `vfx_perfect_delete` | 8 |
| `vfx_dust_puff` | 5 | | `vfx_glitch_square` | 4 |
| `vfx_data_stream` | 8 | | `vfx_shatter` | 12 |
| `vfx_level_up` | 10 | | | |

---

## 10.4 Sprite Sizes Reference

From `AnimConst.SPRITE_SIZES`:

| Character/Category | Width × Height | Notes |
|---|---|---|
| `"player_combat"` | 32 × 48 | Taller for side-scroll |
| `"player_topdown"` | 32 × 32 | Square for top-down |
| `"elara"` | 32 × 48 | Same height as player |
| `"mira"` | 32 × 48 | Same height as player |
| `"slime"` | 32 × 32 | Small, round |
| `"boar"` | 64 × 48 | Wide, bulky |
| `"knight"` | 48 × 64 | Tall, imposing |
| `"npc_generic"` | 32 × 48 | Standard NPC size |
| `"vfx_small"` | 32 × 32 | Small effects |
| `"vfx_medium"` | 64 × 64 | Medium effects |
| `"vfx_large"` | 128 × 128 | Large effects (shatter, portals) |

---

## 10.5 Animation FPS Reference

From `AnimConst.ANIM_FPS`:

| Category | FPS | Timing |
|---|---|---|
| `idle` | 8 | Relaxed, slow |
| `walk` | 10 | Normal pace |
| `run` | 12 | Fast movement |
| `attack` | 15 | Snappy, responsive |
| `hurt` | 12 | Quick reaction |
| `die` | 10 | Dramatic, slower |
| `vfx` | 15 | Fast, punchy |
| `ui` | 12 | Smooth transitions |
| `cutscene` | 10 | Cinematic pace |
| `environment` | 6 | Slow ambient |

### Timing Reference
At 12 FPS: 4 frames = 0.33s | 6 frames = 0.5s | 8 frames = 0.67s | 12 frames = 1.0s | 16 frames = 1.33s

---

## 10.6 Autoload Registry

9 autoload singletons registered in `project.godot`:

| Autoload | Script | Purpose |
|---|---|---|
| GameManager | `scripts/game_manager.gd` | Player stats, story flags, save/load |
| DialogueManager | `scripts/dialogue_manager.gd` | Dialogue queue and display |
| AssetManager | `scripts/asset_manager.gd` | Asset loading and management |
| Inventory | `scripts/inventory_system.gd` | Item tracking |
| CombatFX | `scripts/combat_effects.gd` | Combat VFX |
| GlitchOverlay | `scripts/glitch_overlay.gd` | Screen-wide glitch effects |
| PauseScreen | `scripts/ui/pause_screen.gd` | IDE-style pause menu |
| StatusWindow | `scripts/ui/status_window.gd` | Debugger character inspector |
| InteractionPrompt | `scripts/ui/interaction_prompt.gd` | Floating interaction prompt |

---

## 10.7 Input Mappings

All registered in `project.godot`:

| Action | Key | Keycode | Usage |
|---|---|---|---|
| `move_left` | A | 65 | WASD movement |
| `move_right` | D | 68 | WASD movement |
| `move_up` | W | 87 | WASD movement |
| `move_down` | S | 83 | WASD movement |
| `jump` | Space | 32 | Combat: variable height jump |
| `attack` | J | 74 | Combat: 3-hit combo / Explore: engage |
| `root_access` | E | 69 | Interact + Root Access hack |
| `perfect_delete` | X | 88 | Execute low-HP enemies |
| `sprint` | Shift | 4194325 | Sprint (1.8×) / Tap for dash |
| `defend` | K | 75 | Block (hold) / Parry (2-frame window) |
| `data_vision` | Tab | 4194306 | Toggle Data Vision overlay |
| `pause_menu` | Escape | 4194305 | Toggle pause screen |
| `interact` | F | 70 | Primary interact (NPCs/items) |
| `status_window` | I | 73 | Toggle status debugger |
| `pogo` | S (airborne) | 83 | Pogo strike (downward bounce) |

---

## 10.8 Scene Flow

```
Main Menu (res://scenes/main_menu.tscn)
│
├─→ Flight 707 (res://scenes/prologue/flight_707.tscn)
│     └─→ Crash Sequence (res://scenes/prologue/crash_sequence.tscn)
│           └─→ Glitch Crater (res://scenes/chapter1/glitch_crater_awakening.tscn)
│                 └─→ Elara Meeting (res://scenes/chapter1/elara_meeting.tscn)
│                       └─→ Path to Oakhaven (res://scenes/chapter1/path_to_oakhaven.tscn)
│                             └─→ Oakhaven Village (res://scenes/chapter1/oakhaven_village.tscn)
│                                   └─→ Tutorial Knight (res://scenes/chapter1/tutorial_knight_boss.tscn)
│                                         └─→ Shatter Transition (res://scenes/chapter1/shatter_transition.tscn)
│                                               └─→ Main Menu (loop)
│
├─→ Oakhaven Exploration (res://scenes/exploration/oakhaven.tscn)
│     └─→ Combat Arena (res://scenes/combat/combat_arena.tscn)
│           └─→ Post-Combat (res://scenes/exploration/oakhaven_post_combat.tscn)
│
└─→ Game Over (res://scenes/game_over.tscn)
      └─→ Main Menu
```

---

## 10.9 Story Flags

| Flag | Set In | Purpose |
|---|---|---|
| `prologue_complete` | `crash_sequence.gd` | Prologue finished |
| `ch1_glitch_crater_awakened` | `ch1_glitch_crater.gd` | Woke up in crater |
| `ch1_elara_glitch_witch_met` | `ch1_elara_meeting.gd` | First met Elara |
| `ch1_glitch_magic_shown` | `ch1_elara_meeting.gd` | Saw Elara's glitch demo |
| `ch1_data_vision_unlocked` | `ch1_path_to_oakhaven.gd` | Data Vision ability gained |
| `ch1_root_access_tutorial` | `ch1_path_to_oakhaven.gd` | First hack completed |
| `ch1_oakhaven_entered` | `ch1_oakhaven_village.gd` | Arrived in village |
| `ch1_boar_defeated` | `ch1_oakhaven_village.gd` | Beat corrupted boar |
| `ch1_tutorial_knight_defeated` | `ch1_tutorial_knight.gd` | Beat the boss |
| `source_key_fragment_1` | `ch1_tutorial_knight.gd` | First Source Key (1/7) |
| `shatter_crossed` | `ch1_shatter_transition.gd` | Crossed to Chapter 2 |

---

## 10.10 File Reference

### Core Systems
| File | Purpose |
|---|---|
| `scripts/animation_constants.gd` | Master animation name constants (`AnimConst`) |
| `scripts/effects/placeholder_sprite.gd` | Procedural ColorRect sprite factory |
| `scripts/effects/tween_animator.gd` | Tween-based animation library (552 lines) |
| `scripts/effects/vfx_library.gd` | Particle VFX spawn system |
| `scripts/effects/particle_system.gd` | Enhanced environmental particles |
| `scripts/effects/screen_transition.gd` | Scene transition effects |
| `scripts/camera/cinematic_camera.gd` | Camera shake, zoom, pan, letterbox |

### UI Scripts
| File | Purpose |
|---|---|
| `scripts/dialogue_manager.gd` | Dialogue queue and display (autoload) |
| `scripts/ui/dialogue_ui.gd` | Animated dialogue box (scene-based) |
| `scripts/ui/combat_hud_effects.gd` | HP bar, glitch meter effects |
| `scripts/ui/pause_screen.gd` | IDE-style pause menu |
| `scripts/ui/status_window.gd` | Debugger character inspector |
| `scripts/ui/interaction_prompt.gd` | Floating interaction prompt |

### Game Logic
| File | Purpose |
|---|---|
| `scripts/game_manager.gd` | Player stats, story flags, save/load |
| `scripts/asset_manager.gd` | Asset loading and management |
| `scripts/inventory_system.gd` | Item tracking |
| `scripts/combat_effects.gd` | Combat VFX (autoload) |
| `scripts/glitch_overlay.gd` | Screen glitch effects (autoload) |

---

## 10.11 Integration Checklist

When you're ready to add real sprites, follow this checklist for each character:

- [ ] Create all sprite sheets at the correct size (see [Sprite Sizes](#104-sprite-sizes-reference))
- [ ] Import with Nearest filter, no mipmaps (see [Import Settings](#102-godot-import-settings))
- [ ] Create a SpriteFrames resource (`.tres`)
- [ ] Add every animation name from the character's table — **names must match exactly**
- [ ] Set correct FPS for each animation (see [Animation FPS](#105-animation-fps-reference))
- [ ] Mark looping animations: idle, walk, run, patrol, hacked, stunned
- [ ] Replace `ColorRect`/`Node2D` with `AnimatedSprite2D` in the scene
- [ ] Assign the SpriteFrames resource
- [ ] Test: existing code should auto-play animations via `AnimConst` constants
- [ ] Remove `PlaceholderSprite.create_*()` call if present in `_ready()`

### Total Animation Count

| Category | Count |
|---|---|
| Player Combat | 18 |
| Player Top-Down | 9 |
| Player Cutscene | 10 |
| Elara | 11 |
| Mira | 4 |
| Green Slime | 7 |
| Corrupted Boar | 6 |
| Tutorial Knight | 11 |
| Village NPCs | 6 |
| Environment | 13 |
| VFX | 15 |
| UI | 12 |
| **TOTAL** | **~122 animations** |

### Additional Animations (Not Yet in AnimConst)
| Category | Count |
|---|---|
| Player Sprint/Pogo/Dash/Block/Parry | 7 |
| Player Sprint (Top-Down) | 3 |
| Named NPCs (Jenkins/Child/Guard) | 8 |
| Data Vision Effects | 3 |
| **Additional Total** | **~21 animations** |

### Priority Order
1. **Player Combat** — Core gameplay, seen constantly
2. **Green Slime** — First enemy encountered
3. **Tutorial Knight** — Chapter 1 boss, climactic fight
4. **Elara** — Companion, seen in many scenes
5. **Player Top-Down** — Exploration mode
6. **Corrupted Boar** — Elite enemy
7. **Village NPCs** — Background characters
8. **Environment** — Ambient world animations
9. **VFX** — Combat and ability effects
10. **UI** — Interface elements

---

*Last Updated: Session 5 — Complete restructuring into organized asset reference format.*
