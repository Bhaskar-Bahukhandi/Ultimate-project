# Quick Start Guide

## For First-Time Players

### Installation
1. Download and install **Godot Engine 4.3** or newer
   - Get it from: https://godotengine.org/download
   - Choose the **Standard** version (not .NET)
   
2. Extract the Godot executable
   - No installation needed, just run the .exe (Windows) or .app (Mac)

3. Import the project
   - Open Godot
   - Click "Import"
   - Navigate to `AethelgardPrototype/project.godot`
   - Click "Import & Edit"

4. Run the game
   - Press **F5** or click the ▶ Play button in the top-right
   - The game will open and show the main menu

### First Playthrough Tips

#### Option 1: Full Experience (~30 minutes)
1. Start from the main menu
2. Watch the Flight 707 prologue
3. Experience the crash sequence
4. Complete the tutorial combat

#### Option 2: Quick Test (~10 minutes)
1. Start from the main menu
2. Click "Skip Prologue" button during Flight 707 scene
3. Jump straight to Oakhaven awakening
4. Complete the tutorial combat

### Controls Cheat Sheet

```
=== EXPLORATION MODE (Top-Down) ===
WASD        - Move around
SPACE       - Talk to NPCs / Continue dialogue
E           - Open Root Access (not available until after combat)
X           - Perfect Delete button (visible in HUD)

=== COMBAT MODE (Side-Scrolling) ===
A/D         - Move left/right
SPACE       - Jump
J           - Attack (get close to enemy first)
E           - Open Root Access menu
  ├─ Modify enemy properties
  ├─ Click "Apply Changes"
  └─ Increases Glitch Meter!
X           - Perfect Delete (instant kill, uses 1 of 3 charges!)

=== UNIVERSAL ===
ESC         - Pause menu (not implemented)
F5          - Run game (in Godot editor)
```

### Your First Combat

When you encounter the **Green Slime**:

**Method 1: Normal Combat**
1. Press **J** repeatedly to attack
2. Stay close to the slime
3. It takes about 5 hits to defeat

**Method 2: Using Root Access** ⭐ RECOMMENDED
1. Press **E** to open the hacking menu
2. Try these modifications:
   - Set `elasticity` to **0** → Slime can't jump
   - Set `movement_speed` to **0** → Slime can't move
   - Uncheck `is_hostile` → Slime becomes passive
3. Click "Apply Changes"
4. **Warning**: Glitch Meter increases by 15%
5. Now attack the immobilized enemy

**Method 3: Perfect Delete** ⚠️ NOT RECOMMENDED
1. Press **X** 
2. Slime instantly dies
3. You lose 1 of 3 charges **permanently**
4. In the full game, this affects your ending!

### Understanding the HUD

```
┌─────────────────────────────────────────┐
│ Ren - Lv.1              Location: Oakhaven│
│ Class: Spellblade (?)   Glitch: 0%     │
│ [HP BAR: 100/100]      [DELETE BTN (3)] │
└─────────────────────────────────────────┘
```

- **HP Bar**: Your health (not used in tutorial)
- **Glitch Meter**: Corruption from using Root Access
  - 0-25%: Safe
  - 25-50%: Visual glitches
  - 50-75%: Physics anomalies
  - 75-100%: System Administrators spawn
  - 100%: GAME OVER
- **Perfect Delete Button**: Shows remaining charges

### Story Summary

**What's happening?**
- You were on Flight 707 (Tokyo → San Francisco)
- The plane "crashed" but you're not dead
- You've been "compiled" into a fantasy game world called Aethelgard
- You're assigned the "Spellblade" class (fake)
- Your real ability: **ROOT_ACCESS** (hidden)
- You can hack the game's code
- Other passengers are here too (Elara, Kaito, Seraphina, etc.)
- The Gods are watching this as entertainment
- There's a "Battle Royale" between the 15 kingdoms

**Your Goal (in full game):**
- Survive
- Find other passengers
- Uncover the truth
- Defeat the God King
- Return to Earth (maybe)

### Troubleshooting

#### "The game won't start"
- Make sure you're using **Godot 4.3** or newer
- Check that you imported `project.godot`, not a subfolder
- Try: Project → Reload Current Project

#### "I can't move"
- Make sure a dialogue box isn't open (press SPACE to close)
- Check that the game isn't paused
- Verify you're using WASD, not arrow keys

#### "Root Access button (E) doesn't work"
- You can only use it **during combat**
- It only works when enemies are present
- Make sure you've reached the combat sequence

#### "The slime won't take damage"
- You need to be **very close** (within ~100 pixels)
- Press **J** multiple times
- Or use Root Access to make it easier

#### "I see only colored rectangles"
- This is normal! The prototype uses placeholder art
- Full game will have proper pixel art sprites

### What Happens After Tutorial?

The prototype ends after defeating the slime with a victory screen.

**In the full game, you would:**
1. Return to Oakhaven village
2. Explore more of the kingdom
3. Meet more survivors from the plane
4. Build relationships (Persona-style)
5. Participate in the Auction House economy
6. Fight through 15 kingdoms
7. Battle Lesser Gods
8. Face the God King
9. Choose one of 15 endings

### Testing the Core Mechanics

Want to see all features quickly?

#### Test Root Access:
1. Get to combat
2. Press E
3. Try extreme values:
   - `elasticity`: 10.0 (super bouncy)
   - `gravity_scale`: 0.0 (floaty)
   - `movement_speed`: 500.0 (super fast)
4. Watch Glitch Meter increase

#### Test Perfect Delete:
1. Press X during combat
2. Watch the deletion effect
3. Check the button shows "(2)" charges left
4. **Note**: You can't get charges back!

#### Test Glitch Meter:
1. Use Root Access 7 times
2. Watch meter hit 100%+
3. Observe visual effects
4. (Game Over not implemented in prototype)

### For Developers

#### Modding the Prototype

**Change player stats:**
```gdscript
# Edit: scripts/game_manager.gd
var player_stats = {
    "hp": 100,  # Change to 9999 for god mode
    "max_hp": 100
}
```

**Add more dialogue:**
```gdscript
# Edit: scripts/exploration/oakhaven.gd
var my_dialogue = [
    {"speaker": "Ren", "text": "New dialogue!"},
]
start_dialogue(my_dialogue)
```

**Change Perfect Delete charges:**
```gdscript
# Edit: scripts/game_manager.gd
var perfect_delete_charges: int = 3  # Change to 999
```

**Disable Glitch Meter:**
```gdscript
# Edit: scripts/game_manager.gd
func add_glitch_corruption(amount: float):
    # glitch_meter += amount  # Comment this out
    pass
```

### Support & Feedback

This is a prototype demonstration. 

**Found a bug?**
- Check DEVELOPMENT_NOTES.md for known issues
- Most are intentional for prototype scope

**Want to contribute?**
- The code is extensively commented
- All scripts use clear naming conventions
- See file structure in README.md

---

**Enjoy the prototype!**  
**Remember**: This is just the first hour of a planned 100-hour game. 🎮
