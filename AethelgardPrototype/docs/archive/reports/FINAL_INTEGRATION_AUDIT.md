# FINAL INTEGRATION AUDIT — Pass 59-60

**Project:** AethelgardPrototype (Godot 4.6 / GDScript)  
**Scope:** Complete `scripts/` directory (~78 .gd files)  
**Date:** Final quality pass after 58 improvement passes  

---

## Severity Summary

| Severity | Count |
|----------|-------|
| CRITICAL | 0     |
| HIGH     | 5     |
| MEDIUM   | 10    |
| LOW      | 5     |
| **TOTAL**| **20**|

---

## TOP 20 FINDINGS

---

### #1 — HIGH: Systemic Signal Disconnection Gap

**Files:** Project-wide (all scripts with `.connect()` calls)  
**Lines:** ~100+ `.connect()` calls vs only **3** `.disconnect()` calls in entire codebase  

Only `combat_effects.gd` (lines 120, 127) and `glitch_overlay.gd` (line 68) ever disconnect signals. Every other script connects signals in `_ready()` but never disconnects in `_exit_tree()`. This means:

- **`player_combat.gd:284`** — `GameManager.player_leveled_up.connect(_on_player_leveled_up)` — never disconnected
- **`combat_arena.gd:27`** — `GameManager.glitch_meter_changed.connect(...)` — never disconnected
- **`ch1_oakhaven_village.gd:129`** — `GameManager.glitch_meter_changed.connect(...)` — never disconnected
- **`enemy_base.gd:195`** — `GameManager.difficulty_adjusted.connect(...)` — never disconnected
- **`achievements.gd:86,95,102`** — Multiple GameManager/GameJuice/SideQuestManager signal connections — none disconnected

**Risk:** If a node is freed without disconnecting, the signal can fire into a freed object (rare crash) or cause duplicate connections on scene re-entry. The `is_connected()` guard on player_combat.gd:283 mitigates duplicates for ONE signal only.

**Fix:** Add `_exit_tree()` to every script that connects to autoload signals, disconnecting each one.

---

### #2 — HIGH: Dead Code — Damage Label Pool Never Used (combat_effects.gd)

**File:** `scripts/combat_effects.gd`  
**Lines:** 60-63  

```gdscript
const DAMAGE_POOL_SIZE: int = 12
@warning_ignore("unused_private_class_variable")
var _damage_label_pool: Array[Label] = []
@warning_ignore("unused_private_class_variable")
var _pool_index: int = 0
```

`DAMAGE_POOL_SIZE`, `_damage_label_pool`, and `_pool_index` are declared but **never referenced** anywhere in the codebase. This is a planned object-pool optimization that was never implemented. The `@warning_ignore` suppresses the Godot editor warning, hiding the dead code.

**Fix:** Either implement the pool (pre-allocate Labels in `_ready()` and cycle them in `spawn_damage_number()`) or remove the dead declarations entirely.

---

### #3 — HIGH: Dead Code — Afterimage Pool Never Populated (game_juice.gd)

**File:** `scripts/effects/game_juice.gd`  
**Lines:** 44-46  

```gdscript
const MAX_AFTERIMAGES: int = 8
@warning_ignore("unused_private_class_variable")
var _afterimage_pool: Array[ColorRect] = []
```

`_afterimage_pool` is never written to or read from. `MAX_AFTERIMAGES` is declared but unreferenced. The afterimage dash/attack visual system defined in `_afterimage_colors` (line 48) has no consumer code. This is a designed-but-unfinished feature.

**Fix:** Implement the afterimage system (spawn ColorRects on dash/attack into the pool) or remove the stubs.

---

### #4 — HIGH: Dead Code — Glow Variables Never Used (administrator_enforcer.gd)

**File:** `scripts/combat/enemies/administrator_enforcer.gd`  
**Lines:** 10-13  

```gdscript
@warning_ignore("unused_private_class_variable")
var _glow_timer: float = 0.0
@warning_ignore("unused_private_class_variable")
var _glow_pulse_speed: float = 3.0
```

Both `_glow_timer` and `_glow_pulse_speed` are declared but **never referenced**. The `_start_glow_pulse()` function (line 67) creates a looping tween directly with hardcoded values instead of using these variables.

**Fix:** Either use `_glow_pulse_speed` in `_start_glow_pulse()` for the tween duration, or remove the unused variables.

---

### #5 — HIGH: Unused Signal — `buff_removed` Never Emitted (choice_consequences.gd)

**File:** `scripts/choice_consequences.gd`  
**Lines:** 14-15  

```gdscript
@warning_ignore("unused_signal")
signal buff_removed(buff_id: String)
```

`buff_removed` is declared with `@warning_ignore("unused_signal")` but **never emitted** anywhere in the codebase. The complementary `buff_applied` signal (line 13) IS properly emitted. This means any system listening for buff removal events will never get notified.

**Fix:** Emit `buff_removed` wherever a buff is removed (search for `active_buffs.erase` / `active_buffs.remove_at` patterns), or remove the signal if the feature is descoped.

---

### #6 — MEDIUM: player_combat.gd _exit_tree Missing Signal Disconnect

**File:** `scripts/combat/player_combat.gd`  
**Lines:** 292-297  

```gdscript
func _exit_tree() -> void:
    for action in ["attack", "dash", "jump", "spell", "heal", "parry", "interact", "ui_accept"]:
        if Input.is_action_pressed(action):
            Input.action_release(action)
```

`_exit_tree()` releases phantom inputs (good) but does NOT disconnect `GameManager.player_leveled_up` which was connected on line 284. If the player node is freed and re-created (e.g., respawn), the old connection becomes a dangling reference.

**Fix:** Add `GameManager.player_leveled_up.disconnect(_on_player_leveled_up)` to `_exit_tree()`.

---

### #7 — MEDIUM: Tween Leak — HP Bar Flash (player_combat.gd)

**File:** `scripts/combat/player_combat.gd`  
**Lines:** 1470-1472  

```gdscript
var flash_tw = create_tween()
flash_tw.tween_property(_hp_bar, "modulate", Color(1, 0.3, 0.3), 0.05)
flash_tw.tween_property(_hp_bar, "modulate", Color.WHITE, 0.15)
```

A new tween is created every time the player takes damage without killing any previous flash tween. If the player takes rapid hits (which is common in boss fights), multiple overlapping tweens compete for `_hp_bar.modulate`, causing visual glitches and wasted resources.

**Fix:** Store `flash_tw` as an instance variable, call `.kill()` before creating a new one (same pattern used elsewhere in the codebase).

---

### #8 — MEDIUM: Looping Tween Without Cleanup Reference (administrator_enforcer.gd)

**File:** `scripts/combat/enemies/administrator_enforcer.gd`  
**Lines:** 71-73  

```gdscript
var tw = create_tween().set_loops()
tw.tween_property(sprite, "modulate", Color(1.5, 0.3, 0.3), 0.5)
tw.tween_property(sprite, "modulate", Color(1.0, 0.6, 0.6), 0.5)
```

The infinite-loop tween is stored in a local variable `tw` that immediately goes out of scope. While Godot will auto-kill node-bound tweens when the node is freed, there is no way to pause/stop the glow during specific game states (e.g., hack stun, death sequence). Compare with `tutorial_knight_boss_enemy.gd:579` which has the same pattern.

**Fix:** Store the tween in a member variable (e.g., use the existing `_glow_timer` slot renamed to `_glow_tween`) and kill it in `die()`.

---

### #9 — MEDIUM: ch1_tutorial_knight.gd — Multiple Tweens Without Kill Guards

**File:** `scripts/chapter1/ch1_tutorial_knight.gd`  
**Lines:** 688, 771, 832, 850, 1082, 1090, 1156  

Seven `create_tween()` calls across boss phase transitions and cutscene beats. None store the tween in a member variable or kill previous tweens. If phase transitions happen quickly (phase skip during fast kills), multiple tweens can stack on the same property.

**Fix:** Store phase transition tweens in a member variable (e.g., `_phase_tween`) and kill before reassigning.

---

### #10 — MEDIUM: Empty Stub Function — _handle_charged_attack (player_combat.gd)

**File:** `scripts/combat/player_combat.gd`  
**Lines:** 751-752  

```gdscript
func _handle_charged_attack() -> void:
    pass
```

This is an empty stub with no TODO comment. The companion function `_perform_charged_attack()` (line 755) IS implemented but `_handle_charged_attack` is never called. This is a partially designed feature that was either abandoned or split across passes.

**Fix:** Either complete the charged attack input handling or remove the stub and add a comment documenting the design decision.

---

### #11 — MEDIUM: Unused Variable — _total_locations (ch3_fractured_wastes.gd)

**File:** `scripts/chapter3/ch3_fractured_wastes.gd`  
**Line:** 32  

```gdscript
@warning_ignore("unused_private_class_variable")
var _total_locations: int = 5  # ruins, tower, garden, market, server_room
```

`_total_locations` is declared but never referenced. The completion percentage logic uses `_locations_visited.size()` directly rather than dividing by this constant.

**Fix:** Use `_total_locations` in any completion tracking calculations, or remove it.

---

### #12 — MEDIUM: Only 8 of ~78 Scripts Implement _exit_tree()

**Files:** Project-wide  
**Scripts with _exit_tree():** `player_combat.gd`, `flight_707_cinematic.gd`, `ch1_glitch_crater.gd`, `ch1_path_to_oakhaven.gd`, `cinematic_vfx.gd`, `ch2_seraphina_choice.gd`, `ch1_elara_meeting.gd`, `ch1_tutorial_knight.gd` (via `_notification`)

The vast majority of scene scripts that connect signals, create timers, or spawn tweens do NOT implement `_exit_tree()` for cleanup. This includes major scripts like `combat_arena.gd`, `enemy_base.gd`, `ch2_ironhold_city.gd`, `ch3_fractured_wastes.gd`, and all boss enemy scripts.

**Risk:** Scene transitions or node freeing can leave orphaned signal connections and running tweens.

**Fix:** Add `_exit_tree()` to any script that connects to autoload signals or creates persistent tweens.

---

### #13 — MEDIUM: Incomplete Feature — Map Tab Placeholder (pause_screen.gd)

**File:** `scripts/ui/pause_screen.gd`  
**Line:** 670  

```gdscript
func _refresh_map_tab() -> void:
    ## Show simple map info — placeholder for full map
```

The map tab only displays a text-based location description. The comment explicitly states this is a placeholder. While functional, this is the only UI tab without a visual representation.

**Fix:** Document this as a known shipping limitation or implement a basic map graphic.

---

### #14 — MEDIUM: Inconsistent Autoload Guard Pattern

**Files:** `scripts/combat/player_combat.gd` (and others)  

`player_combat.gd` guards `VFXLibrary`, `GameJuice`, `CombatFX`, `ChoiceConsequences`, `Achievements`, `SceneTransitions` with `has_node("/root/...")` before access. But it accesses `GameManager` **directly** on lines 282-284 without a guard:

```gdscript
if not GameManager.player_leveled_up.is_connected(_on_player_leveled_up):
    GameManager.player_leveled_up.connect(_on_player_leveled_up)
```

While GameManager is likely always present (it's the core autoload), this inconsistency breaks the safety pattern. The same inconsistency appears in `enemy_base.gd`, `achievements.gd`, and `combat_arena.gd`.

**Fix:** Either guard ALL autoload accesses consistently, or document which autoloads are guaranteed-present (GameManager, DialogueManager) vs optional (VFXLibrary, GameJuice, CombatFX).

---

### #15 — MEDIUM: Empty `pass` Stubs Across Codebase

**Files:** Multiple  
- `player_combat.gd:752` — `_handle_charged_attack` (documented above as #10)
- `enemy_base.gd:598` — `_on_area` in dynamically-generated projectile script
- `player_animation_controller.gd:238, 251, 254` — Three empty match arms
- `ch2_ironhold_city.gd:374` — Empty function body

While some `pass` stubs are intentional (match arm fallthrough), the pattern is inconsistent — some have comments explaining the empty body, others do not.

**Fix:** Add `# Intentional: no action needed` comments to deliberate empty bodies, or implement the missing logic.

---

### #16 — LOW: Hardcoded Timer Durations in Chapter Scripts

**Files:** All chapter scripts (`ch1_*.gd`, `ch2_*.gd`, `ch3_*.gd`)  

Dozens of `await get_tree().create_timer(0.5).timeout`, `create_timer(1.0)`, `create_timer(2.0)` etc. with magic number durations. While these are cutscene/narrative timings that don't need constants, the lack of named references makes it impossible to globally adjust pacing without touching every file.

**Fix:** Consider a `CutsceneTiming` dictionary in `GameManager` or accept this as the cost of hand-tuned narrative pacing. LOW priority.

---

### #17 — LOW: @warning_ignore Used to Suppress Real Dead Code

**Files:** `combat_effects.gd`, `game_juice.gd`, `administrator_enforcer.gd`, `choice_consequences.gd`, `ch3_fractured_wastes.gd`  

13 total `@warning_ignore` annotations in the codebase. Of these, 5 suppress warnings about legitimately unused code (findings #2-5, #11). The annotations mask real technical debt instead of resolving it.

**Fix:** Remove `@warning_ignore` annotations and either implement the suppressed features or delete the dead code.

---

### #18 — LOW: Recursive load_game Call Could Stack (game_manager.gd)

**File:** `scripts/game_manager.gd`  
**Line:** 815  

```gdscript
if _try_load_backup(save_path):
    _load_in_progress = false
    return load_game(slot)  # Recursive call
```

If the primary save is corrupt, `load_game` calls `_try_load_backup` which renames the backup, then `load_game` calls itself recursively. If the backup is *also* corrupt, `_try_load_backup` will fail and the recursion terminates. However, the `_load_in_progress` flag is set to `false` before the recursive call, briefly allowing a concurrent load attempt from another callsite.

**Fix:** Keep `_load_in_progress = true` until after the recursive call returns, or refactor to iterative recovery.

---

### #19 — LOW: Tween Variable Reuse Without Explicit Kill (flight_707_cinematic.gd)

**File:** `scripts/prologue/flight_707_cinematic.gd`  
**Lines:** 66, 76  

```gdscript
var title_tween = create_tween()  # line 66
# ... tween operations ...
title_tween = create_tween()       # line 76 — overwrites reference
```

The first tween's reference is overwritten by the second assignment. The first tween will still run to completion (Godot doesn't GC active tweens), but if the second call happens before the first finishes, they'll conflict on the same properties.

**Fix:** Call `title_tween.kill()` before reassigning on line 76.

---

### #20 — LOW: ch1_glitch_crater.gd — Same Pattern as #19

**File:** `scripts/chapter1/ch1_glitch_crater.gd`  
**Lines:** 733, 745  

```gdscript
var tween = create_tween()   # line 733
# ... operations ...
tween = create_tween()        # line 745 — overwrites without kill
```

Same variable-reuse-without-kill pattern. The first tween may still be running when the second starts.

**Fix:** Call `tween.kill()` before reassigning.

---

## POSITIVE OBSERVATIONS

The codebase shows strong evidence of 58 thorough improvement passes:

1. **Excellent `is_inside_tree()` discipline** — `player_combat.gd` has 15+ `is_inside_tree()` checks after awaits, preventing freed-node crashes
2. **Robust save system** — Atomic write (temp + rename), checksum validation, version migration, backup recovery
3. **Division-by-zero guards** — `max()`, ternary `if total > 0`, and `.is_empty()` checks before `randi() %` throughout
4. **Tween kill-before-create pattern** — Properly implemented for `_panel_tween`, `_pulse_tween`, `_hurt_tween`, `_drop_tween`, `_combo_tween`, `_intro_tween`, `_zoom_tween`, `_hover_tween`, `_telegraph_tween`, `_fade_tween`, `_flash_tween`
5. **Named constants in player_combat.gd** — `SPEED`, `JUMP_VELOCITY`, `MAX_SOUL`, damage values etc. all const-declared
6. **Phantom input prevention** — `_exit_tree()` releases all held actions
7. **DDA system** — Dynamic difficulty adjustment with windowed performance tracking
8. **Comprehensive autoload guards** — `has_node("/root/...")` used extensively in player_combat.gd (30+ guard instances)

---

## METHODOLOGY

| Audit Category | Technique | Results |
|---|---|---|
| Signal connections/disconnections | `grep \.connect\( / \.disconnect\(` | 100+ connects, 3 disconnects |
| @warning_ignore annotations | `grep @warning_ignore` | 13 instances, 5 masking dead code |
| Await + is_inside_tree safety | `grep await / is_inside_tree` | Generally excellent coverage |
| Tween lifecycle management | `grep create_tween / \.kill\(` | 150+ creates, good kill pattern in autoloads |
| Division-by-zero risks | `grep randi.*%.*size\|/ ` | All guarded |
| Autoload guards | `grep has_node.*root` | 30+ in player_combat, inconsistent elsewhere |
| Dead code / stubs | `grep pass$ / @warning_ignore` | 5 dead code blocks, 5+ empty stubs |
| _exit_tree cleanup | `grep _exit_tree / _notification` | Only 8 of ~78 scripts |
| Hardcoded magic numbers | Manual review | Timer durations in chapter scripts |
| Recursive/re-entrant safety | Manual review of load_game | One recursive call with brief flag gap |

---

*End of Pass 59-60 — Final Integration Audit*
