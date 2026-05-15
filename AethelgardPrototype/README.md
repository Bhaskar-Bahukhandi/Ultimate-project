# Aethelgard: The Glitch Sovereign - Prototype v0.1

## Overview
This is a functional prototype of **Project Aethelgard: The Glitch Sovereign** (working title: Codebreaker), a hybrid 2D action-RPG that combines top-down exploration with side-scrolling combat.

## What's Included in This Prototype

### ✅ Completed Features

#### 1. **Flight 707 Prologue (Chapter 1)**
- 30-minute narrative sequence on the doomed flight
- Character introductions (Elara, Kaito, Seraphina)
- Crash sequence with glitch effects
- System compilation animation

#### 2. **Dual Viewport System**
- Top-down exploration mode (Pokemon-style)
- Side-scrolling combat mode (Hollow Knight-style)
- Seamless transitions between modes

#### 3. **Core Gameplay Mechanics**
- **Exploration Mode**: WASD movement, NPC interactions
- **Combat Mode**: Platformer physics with jumping and attacking
- **Root Access System**: Hack enemy properties in real-time
- **Perfect Delete Button**: 3-use instant kill mechanic
- **Glitch Meter**: Tracks corruption from using Root Access

#### 4. **Tutorial Sequence**
- Awakening in Oakhaven
- Meeting Elara (first Social Link)
- Tutorial combat against Green Slime
- Introduction to all core mechanics

#### 5. **Systems**
- Global game state manager
- Dialogue system with branching options
- Relationship tracking
- Story flags and progression
- HUD with HP, Glitch Meter, and skill indicators

## How to Run the Prototype

### Requirements
- **Godot Engine 4.3+** (Download from https://godotengine.org/)

### Steps
1. Open Godot Engine
2. Click "Import"
3. Navigate to `AethelgardPrototype/project.godot`
4. Click "Import & Edit"
5. Press **F5** or click the Play button to run the game

## Controls

### Exploration Mode (Top-Down)
- **WASD / Arrow Keys**: Move
- **SPACE**: Interact with NPCs
- **E**: Open Root Access (when available)
- **X**: Use Perfect Delete

### Combat Mode (Side-Scrolling)
- **A/D or Left/Right**: Move left/right
- **SPACE**: Jump
- **J**: Attack
- **E**: Open Root Access menu
- **X**: Use Perfect Delete (instant kill)

## Gameplay Flow

### Chapter 1: The Crash
1. Start the game from the main menu
2. Experience the Flight 707 prologue (or skip it)
3. Watch the compilation sequence
4. Awaken in Oakhaven

### Chapter 2: Awakening
1. Read the awakening dialogue 
2. Move around the village (WASD)
3. Talk to Elara (Flight Attendant)
4. Encounter the Tutorial Slime

### Tutorial Combat
1. Transition to side-scrolling combat
2. **Basic Combat**: Press J to attack (get close to the slime)
3. **Root Access**: Press E to open the hacking menu
   - Modify enemy properties:
     - Set `elasticity` to 0 (prevents jumping)
     - Set `is_hostile` to false (makes enemy passive)
     - Adjust `movement_speed` or `gravity_scale`
   - Click "Apply Changes"
   - **Warning**: Increases Glitch Meter by 15%
4. **Perfect Delete**: Press X for instant kill
   - Only 3 charges for the entire game!
   - Uses one charge permanently
5. Defeat the slime to complete the tutorial

## Key Systems Explained

### Root Access Mechanic
The core differentiator of the game. When activated:
- Time pauses
- You can see and modify enemy properties
- Changes are applied in real-time
- Each use increases the Glitch Meter
- At 100% Glitch Meter = Game Over

**Hackable Properties:**
- `elasticity`: Affects bounce/jump height
- `gravity_scale`: Affects fall speed
- `movement_speed`: Enemy movement speed
- `is_hostile`: Makes enemy non-aggressive

### The Perfect Delete Button
- 3 uses total for the entire game (in full version: 100+ hours)
- Instantly deletes any enemy
- No XP or loot rewards
- Marks save file as "Tainted" (affects ending)
- Strategic resource management required

### Glitch Meter / Corruption System
- Starts at 0%
- Increases when using Root Access
- **25%**: Minor visual glitches
- **50%**: Physics anomalies (not fully implemented in prototype)
- **75%**: System Administrators spawn (not in prototype)
- **100%**: Game Over

## Technical Architecture

### File Structure
```
AethelgardPrototype/
├── project.godot (main project file)
├── icon.svg
├── scenes/
│   ├── main_menu.tscn
│   ├── prologue/
│   │   ├── flight_707.tscn (Flight prologue)
│   │   └── crash_sequence.tscn (Compilation scene)
│   ├── exploration/
│   │   ├── oakhaven.tscn (Top-down world)
│   │   └── oakhaven_post_combat.tscn (Victory screen)
│   ├── combat/
│   │   └── combat_arena.tscn (Side-scrolling combat)
│   └── player/
│       └── player_topdown.tscn
└── scripts/
    ├── game_manager.gd (Global state)
    ├── dialogue_manager.gd (Dialogue system)
    ├── prologue/
    │   ├── flight_707.gd
    │   └── crash_sequence.gd
    ├── exploration/
    │   ├── oakhaven.gd
    │   ├── player_topdown.gd
    │   └── oakhaven_post_combat.gd
    └── combat/
        ├── combat_arena.gd
        └── player_combat.gd
```

### Key Design Patterns

#### State Machine
The `GameManager` tracks the current game state:
- `MENU`: Main menu
- `PROLOGUE`: Flight 707 sequence
- `EXPLORATION`: Top-down mode
- `COMBAT`: Side-scrolling mode
- `DIALOGUE`: Active dialogue
- `ROOT_ACCESS_MODE`: Hacking interface

#### Persistent Viewports
Instead of loading separate scenes, both exploration and combat viewports remain in memory for instant transitions (not fully implemented in prototype but architected for it).

## What's NOT in This Prototype

This is a vertical slice focusing on the first hour. The following are not included:
- The other 14 kingdoms
- Procedural arena generation
- The full companionsystem (only Elara introduction)
- The Auction House economy
- Advanced Glitch Arts abilities
- Boss fights beyond the tutorial slime
- Multiple endings
- Post-game content
- Advanced shader effects
- Sound and music

## Extending the Prototype

### Adding New Enemies
1. Duplicate `TutorialSlime` node in `combat_arena.tscn`
2. Add hackable properties to the `combat_arena.gd` script
3. Modify sprite and behaviors

### Adding New Kingdoms
1. Create new scene in `scenes/exploration/`
2. Copy the structure from `oakhaven.tscn`
3. Change ground tiles, colors, and NPC positions
4. Add combat triggers

### Adding Dialogue
1. Create dialogue arrays in the format:
```gdscript
var my_dialogue = [
    {"speaker": "Character Name", "text": "Dialogue text"},
    {"speaker": "Ren", "text": "Response"}
]
```
2. Call `start_dialogue(my_dialogue)` from the scene script

## Known Issues / Limitations

1. **No collision shapes on some NPCs**: Not all NPCs have properly configured colliders
2. **Limited animations**: All sprites are colored rectangles (placeholder art)
3. **No combat AI**: The slime doesn't move or attack in this prototype
4. **No save/load system**: Save buttons are non-functional
5. **Prototype ends after first combat**: This is intentional

## Design Philosophy Notes

### Meta-Narrative
The game is about a programmer who gains "Root Access" to a game world. The mechanics reflect this:
- Enemies are data structures with properties
- The UI looks like a debug menu
- Corruption represents system instability
- The Perfect Delete button is a developer cheat tool

### Difficulty Scaling
The full game is designed to be extremely difficult:
- Bosses require frame-perfect inputs
- The final boss is designed to be "statistically impossible"
- Root Access allows creative problem-solving
- Player choice matters (use cheats or play fair)

## Next Steps for Full Development

### Phase 1 (Months 4-8): Vertical Slice
- [ ] Complete Chapters 1-5 (Oakhaven + Ironhold)
- [ ] Implement Auction House backend
- [ ] Add 3 Lesser God boss fights
- [ ] Polish combat physics
- [ ] Add animations and proper pixel art

### Phase 2 (Months 9-18): Production
- [ ] Build all 15 kingdoms
- [ ] Write 300,000+ words of dialogue
- [ ] Create procedural Glitchlands
- [ ] Implement all Social Links
- [ ] Create Wave Function Collapse arena generation

### Phase 3 (Months 19-24): Polish
- [ ] Add shader effects
- [ ] Compose music
- [ ] Test all 15 endings
- [ ] Balance economy
- [ ] QA and bug fixes

## Acknowledgments

Based on the comprehensive design documents:
- `Blueprint_and_roadmap.txt`
- `lore.txt`
- `context.txt`

### Core Inspirations
- **Hollow Knight**: Combat feel and difficulty
- **Persona 5**: Social Link system
- **Undertale**: Meta-narrative and player choice consequences
- **The Stanley Parable**: Deconstructive storytelling
- **EVE Online**: Complex player-driven economy

## Contact & Feedback

This is a prototype for demonstration purposes. Feedback welcome!

## License

All rights reserved. This is a prototype for Project Aethelgard.

---

**Version**: 0.1 Prototype  
**Build Date**: February 2026  
**Engine**: Godot 4.3+  
**Target Playtime**: ~15-30 minutes (first hour slice)
