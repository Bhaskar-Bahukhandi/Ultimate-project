# Development Notes

## Prototype Creation Log

### Overview
This prototype was created as a proof-of-concept for Project Aethelgard: The Glitch Sovereign. The goal was to demonstrate the core gameplay loop and unique mechanics within the first hour of gameplay.

### Technical Decisions

#### Why Godot 4.x?
- **2D Performance**: Godot excels at 2D games with low overhead
- **Node System**: Perfect for the dual-viewport architecture
- **GDScript**: Rapid prototyping with Python-like syntax
- **Open Source**: No licensing concerns
- **Reflection Capabilities**: Needed for the Root Access mechanic

#### Architecture Choices

##### State Management
- Single `GameManager` autoload for global state
- Prevents data loss between scene transitions
- Centralizes save/load logic

##### Dual Viewport Approach
In the full game, this would use SubViewports, but the prototype uses scene transitions for simplicity:
- Exploration: Top-down orthographic view
- Combat: Side-scrolling with parallax
- Transition effect placeholder (would be Voronoi fracture shader in full version)

##### Property-Based Hacking
The Root Access mechanic uses Godot's property system:
```gdscript
# Enemy properties stored in dictionary
var enemy_properties = {
    "elasticity": 1.0,
    "gravity_scale": 1.0
}

# Modified via UI
enemy.set("elasticity", new_value)
```

In full game, this would use reflection and custom attributes:
```gdscript
@export var elasticity: float = 1.0
@export_category("Hackable")
```

### Content Implementation

#### Prologue Sequence
- **20 dialogue beats** covering Flight 707
- Character introductions for 3 major NPCs
- System messages establishing the meta-narrative
- Skip option for repeat playthroughs

#### Tutorial Design
The tutorial teaches mechanics through necessity:
1. **Movement**: Must walk to NPCs
2. **Dialogue**: Elara explains the world
3. **Combat basics**: Forced encounter with slime
4. **Root Access**: Slime is intentionally tough, encouraging hacking
5. **Perfect Delete**: Persistent UI element tempts use

### Challenges Solved

#### Challenge 1: Maintaining Game State
**Problem**: Data loss when switching scenes  
**Solution**: GameManager autoload preserves:
- Player stats
- Relationships
- Story flags
- Glitch meter
- Perfect Delete charges

#### Challenge 2: Dialogue System
**Problem**: Need branching dialogue without complex plugin  
**Solution**: Array-based dialogue with choice objects:
```gdscript
{
    "speaker": "Ren",
    "text": "Choose action",
    "type": "choice",
    "choices": ["Option A", "Option B"]
}
```

#### Challenge 3: Root Access UI
**Problem**: Need to modify properties without breaking game logic  
**Solution**: Dictionary-based property storage + validation

### Performance Considerations

#### Optimization Techniques Used
1. **Object Pooling**: Not needed in prototype, but architecture supports it
2. **Scene Instancing**: Minimal scene loading
3. **Process Disabling**: Paused nodes during dialogue
4. **ColorRect Placeholders**: Zero texture memory usage

#### Scalability Notes
For full game with 15 kingdoms:
- Use TileMap for terrain (not individual ColorRects)
- Implement AssetLibrary for shared resources
- Stream audio and textures
- Use MultiMesh for particle systems
- Implement LOD for distant objects

### Content Metrics

#### Dialogue
- **Total lines**: ~40
- **Characters**: 3 (Ren, Elara, System)
- **Scenes**: 3 (Flight, Awakening, Combat)

#### Play Time
- **Prologue**: 5-10 minutes (skippable)
- **Awakening**: 3-5 minutes
- **Tutorial Combat**: 5-10 minutes
- **Total**: 15-30 minutes

#### Code Statistics
- **Scripts**: 9 .gd files
- **Scenes**: 7 .tscn files
- **Total Lines**: ~800 lines of GDScript
- **Functions**: ~50 methods
- **Classes**: 9 (scene scripts)

### Asset Pipeline Notes

#### Placeholder Art Strategy
Current prototype uses ColorRects for all sprites:
- **Player**: Blue rectangle (32x48px)
- **Enemies**: Green rectangle (64x64px)
- **NPCs**: Gold rectangle (32x32px)
- **Terrain**: Flat color background

Full game asset pipeline:
1. Source 16x16 pixel art from Itch.io packs
2. Apply pixel-perfect import settings
3. Use shader for glitch effects
4. Batch process in Aseprite

#### Audio Placeholder
No audio in prototype. Full game needs:
- **Music**: 15 kingdom themes + combat tracks
- **SFX**: ~200 effects (attacks, UI, glitches)
- **Voice**: Optional for key cutscenes

### Testing Notes

#### Tested Scenarios
✅ New game from menu  
✅ Prologue to awakening transition  
✅ Dialogue advancement  
✅ Player movement in exploration  
✅ Combat transition  
✅ Root Access property modification  
✅ Perfect Delete functionality  
✅ Glitch meter increase  
✅ Combat victory flow  

#### Known Bugs
1. **Camera jitter**: Minor if moving during dialogue
2. **Collision issues**: Some NPCs lack proper colliders
3. **No bounds checking**: Player can walk off map edges
4. **No death state**: Player can't die in prototype

### Future Development Priority

#### Critical Path (Next Iteration)
1. **Add proper collision**: TileMap with collision layers
2. **Enemy AI**: Basic patrol and attack patterns
3. **Animations**: At minimum, flip sprites based on direction
4. **Second kingdom**: Ironhold (steampunk theme)
5. **First boss**: The Gear Hulk

#### Systems to Expand
1. **Inventory system**: Currently not implemented
2. **Equipment**: Weapon and armor slots
3. **Skill tree**: The C:/Skills/ directory structure
4. **Save/load**: File I/O with JSON
5. **Settings menu**: Volume, keybinds, etc.

### Lessons Learned

#### What Worked Well
- **State management architecture**: GameManager pattern is solid
- **Modular dialogue**: Easy to write new scenes
- **Root Access concept**: Playtesting shows it's engaging
- **Scene separation**: Clean boundaries between game modes

#### What Needs Improvement
- **Combat feel**: Needs more "juice" (screen shake, particles, hitstop)
- **Visual feedback**: Need better indicators for hackable objects
- **Tutorial pacing**: Could introduce mechanics more gradually
- **Placeholder art**: Even simple shapes need more visual distinction

### References & Resources

#### Godot Documentation Used
- CharacterBody2D: https://docs.godotengine.org/en/stable/classes/class_characterbody2d.html
- Signals: https://docs.godotengine.org/en/stable/getting_started/step_by_step/signals.html
- Singletons (Autoload): https://docs.godotengine.org/en/stable/tutorials/scripting/singletons_autoload.html

#### Helpful Patterns
- State Machine: https://gameprogrammingpatterns.com/state.html
- Object Pool: https://gameprogrammingpatterns.com/object-pool.html
- Observer (Signals): https://gameprogrammingpatterns.com/observer.html

---

**Last Updated**: February 2026  
**Prototype Version**: 0.1  
**Next Milestone**: Vertical Slice (Chapters 1-5)
