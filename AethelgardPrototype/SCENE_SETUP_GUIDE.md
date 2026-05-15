# Scene Setup Guide for Godot Editor

## Purpose
This guide lists the manual Godot Editor tasks **YOU (the developer)** need to complete.
These are scene/node configurations that **cannot be done through code alone** — they require
using the Godot Editor UI to set up node trees, attach scripts, and configure properties.

All GDScript code is already written and complete. This guide ONLY covers scene (.tscn) setup
that you need to do manually in the editor.

---

## CRITICAL: combat_arena.tscn Setup

### Step 1: Update Enemy Node
1. **Open** `res://scenes/combat/combat_arena.tscn` in Godot
2. **Select** the enemy node (likely named "TutorialSlime" or "Slime")
3. **Change node type:**
   - Right-click node > Change Type > `CharacterBody2D`
4. **Attach script:**
   - With node selected > Inspector > Script > Attach
   - Choose `res://scripts/combat/enemies/slime.gd`
5. **Verify inheritance:**
   - Script should show: `extends EnemyBase`

### Step 2: Add Collision Shape
1. **With enemy node selected:**
   - Add Child Node > `CollisionShape2D`
2. **Configure shape:**
   - Inspector > Shape > New RectangleShape2D
   - Size: 64x64 (adjust for your sprite)

### Step 3: Add Health Bar
1. **With enemy node selected:**
   - Add Child Node > `ProgressBar`
   - Rename to exactly: `HealthBar`
2. **Configure:**
   - Max Value: 100
   - Value: 100
   - Position above enemy sprite
   - Size: ~80x10 pixels

### Step 4: Add Camera2D
1. **At root of scene:**
   - Add Child Node > `Camera2D`
2. **Configure:**
   - Enabled: checked
   - Current: checked (Make Current)
   - Position Smoothing: Enabled (0.5)
   - Zoom: (2, 2) for pixel art look

### Step 5: Verify Root Access Panel
**Check UI structure matches:**
```
RootAccessPanel (Panel or CanvasLayer)
  +-- MarginContainer
      +-- VBox (VBoxContainer)
          +-- Label (title)
          +-- PropertyList (VBoxContainer)
              +-- ElasticityRow (HBoxContainer)
              |   +-- Label
              |   +-- SpinBox
              +-- GravityRow (HBoxContainer)
              |   +-- Label
              |   +-- SpinBox
              +-- SpeedRow (HBoxContainer)
              |   +-- Label
              |   +-- SpinBox
              +-- HostileRow (HBoxContainer)
              |   +-- Label
              |   +-- CheckBox
              +-- Buttons (HBoxContainer)
                  +-- ApplyButton
                  +-- CancelButton
```

**If structure differs:** Either rebuild to match, or modify code in combat_arena.gd lines 88-108

---

## oakhaven.tscn Setup

### Step 1: Add Camera2D (Optional)
If exploration needs camera follow:
1. Add Child Node > `Camera2D`
2. Make it child of Player node
3. Enable smoothing

### Step 2: Verify Boundaries
Run game and try walking off edges. Should be blocked by invisible walls.

If not working:
- Check that `_create_map_boundaries()` is being called
- Adjust `map_size` in ch1_oakhaven_village.gd

---

## Player Setup (Both Modes)

### Combat Player (player_combat.gd)
**Node structure:**
```
Player (CharacterBody2D)
  +-- Sprite (Sprite2D or ColorRect placeholder)
  +-- CollisionShape2D
```

**Script:** `res://scripts/combat/player_combat.gd`

### Exploration Player (player_topdown.gd)
**Node structure:**
```
Player (CharacterBody2D)
  +-- Sprite (Sprite2D or ColorRect placeholder)
  +-- CollisionShape2D
```

**Script:** `res://scripts/exploration/player_topdown.gd`

---

## Testing Checklist

After completing the scene setup above, test these:

### 1. Enemy Validation
Run game and check console output:
- Should NOT see: "Enemy node doesn't have required signals"
- SHOULD see: "Enemy validation passed"

### 2. Root Access UI
- Press **E** in combat
- Should open panel without errors
- Should show current enemy properties
- Modify values and click Apply
- Enemy behavior should change

### 3. Screen Shake
- Attack enemy (J key)
- Camera should shake slightly
- If not: Camera2D missing or not current

### 4. Collision Boundaries
- Try walking to edge of map
- Should collide with invisible wall
- Can't fall off world

### 5. Health Bar
- Attack enemy
- Health bar above enemy should decrease
- If not visible: Check HealthBar node exists

---

## Common Errors and Fixes

### Error: "Node not found: MarginContainer/VBox/..."
**Fix:** Root Access Panel UI structure doesn't match code
**Solution:** Rebuild UI structure as shown above, or modify code to match your structure

### Error: "Invalid call. Nonexistent function 'elasticity'"
**Fix:** Enemy node doesn't have Slime script attached
**Solution:** Attach `res://scripts/combat/enemies/slime.gd` to enemy

### Error: "Attempt to call 'died' on null instance"
**Fix:** Enemy signals not connecting
**Solution:** Ensure enemy extends EnemyBase (check script inheritance)

### Warning: "No Camera2D found - screen shake disabled"
**Fix:** Scene missing camera
**Solution:** Add Camera2D node, enable it, make it current

### Error: "Enemy should be CharacterBody2D, is: Node2D"
**Fix:** Wrong node type
**Solution:** Change enemy node type to CharacterBody2D

---

## Priority Order

**Must Do (Game won't run without these):**
1. Change enemy to CharacterBody2D
2. Attach Slime script
3. Add CollisionShape2D to enemy

**Should Do (Features won't work without these):**
4. Build Root Access UI structure
5. Add Camera2D to arena
6. Add HealthBar to enemy

**Nice to Have (Polish):**
7. Proper sprites (currently using ColorRect placeholders)
8. Animations
9. Particle effects

---

## Quick Start (Minimal Setup)

**If you want to just test quickly:**

1. Open `combat_arena.tscn`
2. Select enemy node
3. **Change Type** > CharacterBody2D
4. **Attach Script** > slime.gd
5. Add **CollisionShape2D** child (any shape)
6. Add **Camera2D** to root
7. Run game (F5)

**This gets basic functionality working.**

For full features (Root Access, Health Bar), follow detailed steps above.

---

## Scene Files That Need Updates

| File | Priority |
|------|----------|
| combat_arena.tscn | CRITICAL |
| oakhaven.tscn | MEDIUM |
| player_topdown.tscn | LOW |
| player_combat.tscn | MEDIUM |

---

## After Setup Complete

Once scenes match scripts, you'll have:
- Working enemy AI (patrol, chase, attack)
- Functional Root Access (real property hacking)
- Screen shake and combat feedback
- Player death and respawn
- Glitch shader effects
- Save/load system
- Map boundaries

---

**Need Help?** Check console output - the code provides detailed warnings about what's missing.
