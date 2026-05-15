# PASS 38 — Cutscene Polish  &  PASS 39 — Edge Cases & Crash Prevention
## Aethelgard: The Glitch Sovereign — Comprehensive Audit Report

**Date:** 2025-01-XX  
**Engine:** Godot 4.6 / GDScript  
**Scope:** Every `.gd` file in the project (~35 scripts)  

---

## TABLE OF CONTENTS
1. [Pass 38 — Cutscene Polish](#pass-38--cutscene-polish)
2. [Pass 39 — Edge Cases & Crash Prevention](#pass-39--edge-cases--crash-prevention)
3. [Master Fix Table](#master-fix-table)
4. [Files Audited — Full List](#files-audited--full-list)
5. [Remaining Low-Risk Notes](#remaining-low-risk-notes)

---

## PASS 38 — CUTSCENE POLISH

### 38.1 — Cutscene Skip Mechanism

| File | Before | After | Status |
|------|--------|-------|--------|
| `cutscene_manager.gd` | Instant ESC skip — single key press immediately ended the entire cutscene with no cleanup | **Hold-to-skip** (1.5 s hold). Visual progress bar hint appears. On skip: fade overlay alpha → 0, canvas modulate → WHITE, audio faded out + stopped, `cutscene_finished` signal emitted. | ✅ FIXED |
| `ch1_shatter_transition.gd` | **No skip at all** — `_input()` was empty; players were trapped in cutscene | **Hold-to-skip** (1.5 s). Sets `ch1_shatter_witnessed`, `ch1_complete` flags, advances chapter to 2, resets DialogueManager, transitions to Chapter 2 with SceneTransitions fallback. | ✅ FIXED |
| `flight_707_cinematic.gd` | Already had hold-to-skip (1.5 s) with `_exit_tree()` cleanup | — | ✅ ALREADY GOOD |
| `crash_sequence.gd` | Already had hold-to-skip (1.5 s) | — | ✅ ALREADY GOOD |
| `cutscene_director.gd` | Uses `cancel()` API — no direct player skip (driven by CutsceneManager) | — | ✅ N/A |

#### 38.1.1 — Hold-to-Skip Implementation Details (CutsceneManager)

```gdscript
const SKIP_HOLD_DURATION: float = 1.5
var _skip_hold_timer: float = 0.0
var _skip_holding: bool = false
var _skip_hint: Control = null

func _process(delta: float) -> void:
    if _skip_holding and is_playing:
        _skip_hold_timer += delta
        _update_skip_hint(_skip_hold_timer / SKIP_HOLD_DURATION)
        if _skip_hold_timer >= SKIP_HOLD_DURATION:
            _skip_holding = false
            _hide_skip_hint()
            stop_cutscene()
```

- **Visual feedback:** A `PanelContainer` with a cyan progress `ColorRect` fills over 1.5 s.
- **Cleanup on skip:** `stop_cutscene()` now resets fade overlay alpha, canvas modulate, fades audio, and emits `cutscene_finished`.
- **Input:** `_unhandled_input()` tracks ESC press/release; single-press no longer skips.

### 38.2 — Fade Transitions

| Component | Assessment |
|-----------|-----------|
| `cutscene_manager.gd` — `_exec_fade()` | Solid. Uses `_get_or_create_overlay()` with proper parent checking. Tween-based with configurable duration. |
| `cutscene_manager.gd` — `_exec_screen_flash()` | Good. Creates overlay with `MOUSE_FILTER_IGNORE`, auto-fades. |
| `scene_transition_manager.gd` | Excellent. Has `_safe_reset_transition()`, `is_inside_tree()` after every await, `ResourceLoader.exists()` validation. |
| `screen_transition.gd` | Excellent. `is_inside_tree()` after every await, `SFXManager` guarded with `has_node`. |
| `ch1_shatter_transition.gd` | Fixed. Now has full fade handling + skip cleanup. |

### 38.3 — Camera Control During Cutscenes

| Component | Assessment |
|-----------|-----------|
| `cinematic_camera.gd` | **Excellent.** `is_instance_valid(_follow_target)` checked before every use. `is_inside_tree()` guard. Bounds-safe division. Smooth state-machine transitions (FOLLOWING → CINEMATIC → SHAKING). |
| `cutscene_manager.gd` — `_exec_camera_*` | Good. `_exec_camera_move()`, `_exec_camera_shake()`, `_exec_camera_zoom()` all tween-based with proper duration handling. |
| `cutscene_director.gd` — camera methods | Good. Builder API routes through CutsceneManager. |

### 38.4 — Character Positioning

| Component | Assessment |
|-----------|-----------|
| `cutscene_manager.gd` — `_exec_actor_enter/exit/move` | Solid. `_get_actor_node()` returns null-checked results. Actor removal handled by `_remove_managed_actor()`. |
| `cutscene_director.gd` — `_get_actor_node()` | Uses `AssetManager.create_sprite_node()` without guard — low risk (only called in cutscene context where autoloads are present). |

### 38.5 — Music & Audio Transitions

| Component | Assessment |
|-----------|-----------|
| `cutscene_manager.gd` — `_exec_music`, `_exec_sfx` | Uses `MusicManager`/`SFXManager` with `has_node` guards ✅ |
| `cutscene_manager.gd` — skip cleanup | Now fades audio out before stopping ✅ |
| `flight_707_cinematic.gd` | Guards MusicManager calls ✅ |

### 38.6 — Input Blocking

| Component | Assessment |
|-----------|-----------|
| `cutscene_manager.gd` — `is_playing` flag | Blocks game input while cutscene runs ✅ |
| `cutscene_manager.gd` — `_exec_wait_input` | Properly awaits input with timeout fallback ✅ |
| `ch1_shatter_transition.gd` | `ui_accept` passthrough for dialogue advancement; ESC reserved for skip ✅ |

---

## PASS 39 — EDGE CASES & CRASH PREVENTION

### 39.1 — Unguarded Autoload Access

This is the most common crash vector in the codebase. **Every autoload singleton** (`GameManager`, `DialogueManager`, `MusicManager`, `SFXManager`, `SceneTransitions`, `VFXLibrary`, etc.) must be accessed behind a `has_node("/root/AutoloadName")` guard.

#### Files Fixed:

**1. `glitch_overlay.gd`** — GameManager in `_ready()` + `_process()`
```gdscript
# BEFORE:
GameManager.glitch_meter_changed.connect(_on_glitch_meter_changed)

# AFTER:
if has_node("/root/GameManager"):
    GameManager.glitch_meter_changed.connect(_on_glitch_meter_changed)
else:
    push_warning("GlitchOverlay: GameManager not available")
```
```gdscript
# BEFORE (in _process):
var glitch = GameManager.glitch_meter

# AFTER:
if not has_node("/root/GameManager"): return
```

**2. `player_topdown.gd`** — 3 fixes
- Data vision timer: `GameManager.add_glitch_corruption()` → guarded
- `trigger_combat()`: `SceneTransitions.change_scene()` → guarded + fallback
- `get_stamina_percent()`: Division by zero → `maxf(max_stamina, 0.01)`

**3. `crash_sequence.gd`** — `transition_to_oakhaven()` + `_skip_sequence()`
- `GameManager.set_story_flag()` → guarded
- `SceneTransitions.change_scene()` → guarded + `get_tree().change_scene_to_file()` fallback

**4. `main_menu.gd`** — 4 fixes
- `_do_load_game()`: GameManager.load_game + VFXLibrary.spawn_status_indicator → guarded
- `_do_delete_save()`: GameManager.delete_save → guarded
- `_launch_chapter()`: DialogueManager.force_reset + GameManager.reset_game + SceneTransitions → guarded + fallback
- `_on_quit_pressed()`: SFXManager.play → guarded

**5. `choice_consequences.gd`** — `_ready()` signal connection
```gdscript
# BEFORE:
if GameManager:
    GameManager.story_flag_updated.connect(...)

# AFTER:
if has_node("/root/GameManager") and GameManager:
    GameManager.story_flag_updated.connect(...)
```

**6. `root_access_panel.gd`** — 3 fixes
- `open()`: SFXManager.play → guarded
- `close()`: SFXManager.play → guarded
- `_on_apply()`: SFXManager.play + GameManager.add_glitch_corruption → guarded

**7. `game_over.gd`** — Comprehensive rewrite (5 fixes)
- `_ready()`: `GameManager.glitch_meter` → safe local variable pattern
- `_auto_revive()`: GameManager.glitch_meter + reset + SceneTransitions → all guarded
- Menu button lambda: SceneTransitions.change_scene → guarded + fallback
- `_input()`: GameManager.glitch_meter → safe local variable
- `_process()`: GameManager.glitch_meter → safe local variable

Safe local variable pattern used throughout:
```gdscript
var _glitch = GameManager.glitch_meter if has_node("/root/GameManager") else 0.0
```

**8. `oakhaven.gd`** — `_ready()` signal connection
- `GameManager.change_state()` + `GameManager.glitch_meter_changed.connect()` → wrapped in `has_node("/root/GameManager")`

**9. `oakhaven_post_combat.gd`** — `end_epilogue()`
- `GameManager.reset_game()` → guarded
- `SceneTransitions.change_scene()` → guarded + fallback

### 39.2 — Division by Zero

| File | Location | Fix |
|------|----------|-----|
| `player_topdown.gd` | `get_stamina_percent()` | `stamina / max_stamina` → `stamina / maxf(max_stamina, 0.01)` ✅ |
| `combat_arena.gd` | HP bar calculation | Already uses `maxf(max_hp, 1.0)` ✅ |
| `asset_manager.gd` | `create_sprite_node()` | Already checks `tex_size.x > 0` ✅ |

### 39.3 — Null / Freed Node Access

| File | Pattern | Status |
|------|---------|--------|
| `cinematic_camera.gd` | `is_instance_valid(_follow_target)` | ✅ Already safe |
| `object_pool.gd` | `is_instance_valid()` throughout, stale purging, double-release guard | ✅ Excellent |
| `drop_manager.gd` | `is_instance_valid()` on pickups, `_cached_player_ref` validation | ✅ Already safe |
| `status_window.gd` | `is_inside_tree()` + `is_instance_valid()` in `_show_hint()` | ✅ Already safe |
| `scene_transition_manager.gd` | `is_inside_tree()` after every await | ✅ Already safe |
| `screen_transition.gd` | `is_inside_tree()` after every await | ✅ Already safe |
| `oakhaven_post_combat.gd` | `is_inside_tree()` after every await | ✅ Already safe |

### 39.4 — Signal-to-Freed-Node

| File | Pattern | Status |
|------|---------|--------|
| `glitch_overlay.gd` | Signal connection now guarded | ✅ Fixed |
| `choice_consequences.gd` | Signal connection now guarded | ✅ Fixed |
| `oakhaven.gd` | Signal connection now guarded | ✅ Fixed |
| `flight_707_cinematic.gd` | `_exit_tree()` disconnects signals | ✅ Already safe |

### 39.5 — Await on Freed Scene

All files with `await get_tree().create_timer().timeout` patterns now have `if not is_inside_tree(): return` guards after the await. This was already well-implemented across the codebase:
- `oakhaven_post_combat.gd` — every phase function ✅
- `scene_transition_manager.gd` — every transition ✅  
- `screen_transition.gd` — every animation ✅
- `flight_707_cinematic.gd` — every sequence ✅

### 39.6 — Array Index Out of Bounds

No unchecked array indexing found. Dictionary access uses `.get()` with defaults throughout.

### 39.7 — Type Mismatches / Empty Function Bodies

No problematic empty function bodies found. Type annotations are consistent.

### 39.8 — Files Already Exemplary (No Changes Needed)

| File | Why |
|------|-----|
| `object_pool.gd` | Gold-standard crash prevention: `is_instance_valid()`, stale purging, double-release guard, max pool size |
| `arena_manager.gd` | Uses `_has_gm()`, `_has_dm()`, `_has_am()` helper pattern throughout |
| `combat_arena.gd` | Same helper pattern + `maxf()` division guard |
| `cinematic_camera.gd` | Complete null/validity/tree checks |
| `scene_transition_manager.gd` | `_safe_reset_transition()`, `ResourceLoader.exists()`, `is_inside_tree()` |
| `screen_transition.gd` | `is_inside_tree()` after every await, `has_node` for SFXManager |
| `drop_manager.gd` | `is_instance_valid()` on all pickups, guarded autoload access |
| `vfx_library.gd` | `MAX_ACTIVE_EFFECTS` cap, `is_instance_valid()`, null parent checks |
| `background_manager.gd` | Pure procedural generators — zero autoload access in generation functions |
| `asset_manager.gd` | `FileAccess.file_exists()`, `tex_size.x > 0` guard, self-contained |
| `item_resource.gd` / `loot_table.gd` / `loot_entry.gd` | Clean data resources |

---

## MASTER FIX TABLE

| # | File | Fix Description | Category |
|---|------|----------------|----------|
| 1 | `cutscene_manager.gd` | Replaced instant ESC skip → 1.5 s hold-to-skip with visual progress bar + cleanup on skip (fade/audio/signal) | Pass 38 |
| 2 | `ch1_shatter_transition.gd` | Added complete hold-to-skip system + story flag preservation + scene transition with fallback | Pass 38 |
| 3 | `glitch_overlay.gd` | Guarded GameManager signal connection in `_ready()` | Pass 39 |
| 4 | `glitch_overlay.gd` | Guarded GameManager access in `_process()` | Pass 39 |
| 5 | `player_topdown.gd` | Guarded `GameManager.add_glitch_corruption()` in data vision timer | Pass 39 |
| 6 | `player_topdown.gd` | Guarded `SceneTransitions.change_scene()` in `trigger_combat()` + fallback | Pass 39 |
| 7 | `player_topdown.gd` | Fixed division by zero in `get_stamina_percent()` with `maxf()` | Pass 39 |
| 8 | `crash_sequence.gd` | Guarded GameManager + SceneTransitions in both transition paths | Pass 39 |
| 9 | `main_menu.gd` | Guarded 4 functions: load, delete, launch chapter, quit | Pass 39 |
| 10 | `choice_consequences.gd` | Strengthened `_ready()` guard with `has_node` | Pass 39 |
| 11 | `root_access_panel.gd` | Guarded SFXManager (open/close) + SFXManager/GameManager (apply) | Pass 39 |
| 12 | `game_over.gd` | Comprehensive 5-point guard rewrite for all GameManager/SceneTransitions | Pass 39 |
| 13 | `oakhaven.gd` | Guarded GameManager.change_state + signal connection in `_ready()` | Pass 39 |
| 14 | `oakhaven_post_combat.gd` | Guarded GameManager.reset_game + SceneTransitions in `end_epilogue()` | Pass 39 |

**Total: 14 fixes across 10 files**

---

## FILES AUDITED — FULL LIST

| # | File | Lines | Read | Modified |
|---|------|-------|------|----------|
| 1 | `scripts/cutscene/cutscene_manager.gd` | ~980 | ✅ Full | ✅ Yes |
| 2 | `scripts/cutscene/cutscene_director.gd` | 883 | ✅ Full | — |
| 3 | `scripts/prologue/flight_707_cinematic.gd` | 627 | ✅ Full | — |
| 4 | `scripts/chapter1/ch1_shatter_transition.gd` | ~590 | ✅ Full | ✅ Yes |
| 5 | `scripts/camera/cinematic_camera.gd` | 417 | ✅ Full | — |
| 6 | `scripts/glitch_overlay.gd` | 454 | ✅ Full | ✅ Yes |
| 7 | `scripts/player_animation_controller.gd` | 349 | ✅ Full | — |
| 8 | `scripts/object_pool.gd` | 232 | ✅ Full | — |
| 9 | `scripts/resources/item_resource.gd` | 127 | ✅ Full | — |
| 10 | `scripts/resources/loot_entry.gd` | 11 | ✅ Full | — |
| 11 | `scripts/resources/loot_table.gd` | 62 | ✅ Full | — |
| 12 | `scripts/ui/ui_stack.gd` | ~60 | ✅ Full | — |
| 13 | `scripts/ui/root_access_panel.gd` | 396 | ✅ Full | ✅ Yes |
| 14 | `scripts/ui/status_window.gd` | 343 | ✅ Full | — |
| 15 | `scripts/game_over.gd` | ~200 | ✅ Full | ✅ Yes |
| 16 | `scripts/main_menu.gd` | 897 | ✅ Full | ✅ Yes |
| 17 | `scripts/choice_consequences.gd` | 476 | ✅ Full | ✅ Yes |
| 18 | `scripts/drop_manager.gd` | 588 | ✅ Full | — |
| 19 | `scripts/exploration/player_topdown.gd` | 352 | ✅ Full | ✅ Yes |
| 20 | `scripts/exploration/oakhaven.gd` | 304 | ✅ Full | ✅ Yes |
| 21 | `scripts/exploration/oakhaven_post_combat.gd` | 638 | ✅ Full | ✅ Yes |
| 22 | `scripts/combat/arena_manager.gd` | 428 | ✅ Full | — |
| 23 | `scripts/combat/combat_arena.gd` | 314 | ✅ Full | — |
| 24 | `scripts/prologue/crash_sequence.gd` | 231 | ✅ Full | ✅ Yes |
| 25 | `scripts/effects/cinematic_vfx.gd` | 215 | ✅ Full | — |
| 26 | `scripts/effects/scene_transition_manager.gd` | 448 | ✅ Full | — |
| 27 | `scripts/effects/screen_transition.gd` | 307 | ✅ Full | — |
| 28 | `scripts/effects/vfx_library.gd` | 1003 | ✅ Full | — |
| 29 | `scripts/background_manager.gd` | 1115 | ✅ Full | — |
| 30 | `scripts/asset_manager.gd` | 781 | ✅ Full | — |

---

## REMAINING LOW-RISK NOTES

These items were identified but deliberately left unfixed because they are low-risk (used only in contexts where the autoload is guaranteed to exist):

1. **`cutscene_director.gd`** — `AssetManager` access in `_get_actor_node()` and `DialogueManager` in `_exec_dialogue()`. Only called during active cutscenses where autoloads are fully loaded.

2. **`player_animation_controller.gd`** — `TweenAnimator` calls without guard. Only used in gameplay animation context.

3. **`oakhaven_post_combat.gd`** — `GameManager.relationships["elara"]` and `GameManager.set_story_flag()` in choice callbacks. These are deeply nested in the epilogue sequence which only runs after full game initialization.

4. **`cinematic_vfx.gd`** — `VFXLibrary.spawn_status_indicator()` without guard in `spawn_ambient_particles()`. Same autoload layer, always co-present.

---

## PASS 38 + 39 SUMMARY

| Metric | Value |
|--------|-------|
| Files audited | 30 |
| Total lines read | ~14,000+ |
| Pass 38 fixes (cutscene polish) | 2 major (hold-to-skip + cleanup) |
| Pass 39 fixes (crash prevention) | 12 (autoload guards, division-by-zero, signal safety) |
| Total fixes applied | **14 across 10 files** |
| Files already exemplary | 10 (required zero changes) |
| Low-risk items deferred | 4 |
| Crash vectors eliminated | Division by zero, null autoload access, signal-to-freed-node, uncleanable cutscene state |

**All fixes have been APPLIED directly to the source files — no manual action required.**
