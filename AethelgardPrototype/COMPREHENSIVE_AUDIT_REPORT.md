# Aethelgard Prototype — Comprehensive Audit Report

**Scope:** Save System · Performance · Memory · General Polish  
**Engine:** Godot 4.6 (GDScript)  
**Files audited:** ~78 `.gd` scripts (9 core files read in full)  
**Date:** 2025-07-17

---

## CRITICAL — Will cause crashes, data loss, or soft-locks

### C-01 · Non-atomic save writes — data loss on crash
**File:** `scripts/game_manager.gd` · Lines 757–763  
**Category:** Save System  

`save_game()` opens the save file with `FileAccess.WRITE` and writes directly. If the game crashes, the OS kills the process, or disk runs out of space mid-write, the save file is truncated/corrupted and the player loses progress.

**Suggested fix:**
```gdscript
# Write to a temp file, then rename atomically
var tmp_path = save_path + ".tmp"
var file = FileAccess.open(tmp_path, FileAccess.WRITE)
file.store_string(JSON.stringify(save_data, "\t"))
file.close()
# Atomic rename (OS-level, won't leave partial files)
DirAccess.rename_absolute(tmp_path, save_path)
```

---

### C-02 · Recursive `load_game()` with `await` on non-coroutine
**File:** `scripts/game_manager.gd` · Lines 790–793  
**Category:** Save System  

When JSON parse fails, the code calls `_try_load_backup()` then does:
```gdscript
return await load_game(slot)  # Retry with restored backup
```
`load_game()` returns `bool`. The `await` on a non-coroutine call path is undefined in GDScript — it may hang or return immediately depending on control flow. Additionally, the `_load_in_progress` guard is set to `false` on line 791 before re-entering, but on the *recursive* call `_load_in_progress` gets set to `true` again, potentially leaving it stuck if the backup also fails in certain paths.

**Suggested fix:**
```gdscript
if _try_load_backup(save_path):
    _load_in_progress = false
    return load_game(slot)  # Remove await — not a coroutine in this branch
_load_in_progress = false
return false
```

---

### C-03 · Inventory validation operator precedence bug
**File:** `scripts/game_manager.gd` · Line ~872  
**Category:** Save System  

```gdscript
if item_id is String and qty is float or qty is int:
```
GDScript evaluates this as `(item_id is String and qty is float) or (qty is int)`, which means ANY integer qty passes regardless of whether `item_id` is a String. A non-string `item_id` paired with an `int` qty would be accepted, potentially corrupting the inventory dictionary with integer keys.

**Suggested fix:**
```gdscript
if item_id is String and (qty is float or qty is int):
```

---

### C-04 · Player projectile lambda captures stale `self` reference
**File:** `scripts/combat/player_combat.gd` · Lines 1072–1088  
**Category:** General Polish  

`_create_spell_projectile()` connects a `body_entered` lambda that captures `self` (the player). If the player is freed (death → `queue_free()`) while the projectile is still alive, the lambda attempts to call methods on a freed instance. The `is_instance_valid(projectile)` guard only checks the projectile, not the player.

**Suggested fix:**
```gdscript
projectile.body_entered.connect(func(body: Node2D) -> void:
    if not is_instance_valid(projectile): return
    if not is_instance_valid(self): return  # Add this guard
    # ... rest of lambda
)
```

---

## HIGH — Significant performance/memory issues or likely bugs

### H-01 · Per-note PCM generation in music system (no caching)
**File:** `scripts/music_manager.gd` · Lines 600–640  
**Category:** Performance · Memory  

`_play_voice_note()` generates a fresh `PackedByteArray` + `AudioStreamWAV` for every single music note. During active music playback, this runs dozens of times per second. Each note allocates ~4–16 KB of PCM data that becomes garbage immediately after the note finishes.

**Suggested fix:**
```gdscript
var _note_cache: Dictionary = {}  # key: "freq_dur_wave" → AudioStreamWAV

func _get_or_create_note(freq: float, duration: float, waveform: int) -> AudioStreamWAV:
    var key = "%d_%.2f_%d" % [int(freq), duration, waveform]
    if _note_cache.has(key):
        return _note_cache[key]
    var stream = _generate_note_stream(freq, duration, waveform)
    _note_cache[key] = stream
    return stream
```

---

### H-02 · SFX cache grows unbounded within scene sessions
**File:** `scripts/sfx_manager.gd` · `_cache: Dictionary`  
**Category:** Memory  

The `_cache` dictionary stores generated `AudioStreamWAV` objects keyed by SFX name + parameters. It is only cleared when `clear_cache()` is called (on scene transitions). In long combat encounters or exploration sessions, the cache can accumulate hundreds of entries (each 4–64 KB of PCM data), easily reaching 10+ MB.

**Suggested fix:**  
Add an LRU eviction policy or a size cap:
```gdscript
const MAX_CACHE_ENTRIES = 64

func _evict_oldest_if_needed():
    if _cache.size() > MAX_CACHE_ENTRIES:
        var oldest_key = _cache.keys()[0]
        _cache.erase(oldest_key)
```

---

### H-03 · Multiple `get_nodes_in_group("enemies")` calls per attack frame
**File:** `scripts/combat/player_combat.gd` · Lines ~700, ~800, ~1050, ~1340, ~1500  
**Category:** Performance  

Each attack function (`_perform_combo_attack`, `_perform_charged_attack`, `_execute_pogo`, `_perform_upslash`, `_on_successful_parry`, `take_damage` thorns) individually calls `get_tree().get_nodes_in_group("enemies")`. During a combo sequence with parry-counter and thorns charm, this can result in 4–6 group lookups in a single frame. Each call iterates the full scene tree.

**Suggested fix:**  
Cache the enemy list per frame, similar to `enemy_base.gd`'s `_get_enemies_cached()`:
```gdscript
var _enemies_cache: Array = []
var _enemies_cache_frame: int = -1

func _get_enemies_cached() -> Array:
    var frame = Engine.get_process_frames()
    if frame != _enemies_cache_frame:
        _enemies_cache = get_tree().get_nodes_in_group("enemies")
        _enemies_cache_frame = frame
    return _enemies_cache
```

---

### H-04 · Checksum computed but never validated on load
**File:** `scripts/game_manager.gd` · Lines 758–760 (save), 768–916 (load)  
**Category:** Save System  

`save_game()` computes a checksum: `save_data["_checksum"] = json_string.hash()`, but `load_game()` never reads or validates this checksum. The checksum field is useless dead code, and worse, it computes the hash on the JSON string *before* the checksum is added to the dict, then re-serializes the dict *with* the checksum — so even if validation were added, the hash wouldn't match.

**Suggested fix:**
```gdscript
# In save_game — compute checksum on final string:
var json_string = JSON.stringify(save_data, "\t")
var checksum = json_string.hash()
save_data["_checksum"] = checksum
# Re-serialize WITH checksum for storage
var final_string = JSON.stringify(save_data, "\t")

# In load_game — validate:
var stored_checksum = data.get("_checksum", 0)
data.erase("_checksum")
var data_string = JSON.stringify(data, "\t")
if data_string.hash() != stored_checksum:
    push_error("[LOAD] Checksum mismatch — save may be corrupted")
```

---

### H-05 · Background manager looping tweens never explicitly killed
**File:** `scripts/background_manager.gd` · Lines ~200–280  
**Category:** Memory · Performance  

`_add_stars()` and `_add_floating_particles()` create tweens with `set_loops()` (infinite looping) on procedurally generated ColorRect nodes. If the background Control persists across gameplay (e.g., not freed on scene transition), these tweens run indefinitely, consuming CPU and preventing their nodes from being garbage collected.

**Suggested fix:**  
Track all looping tweens and kill them when generating a new background:
```gdscript
var _active_bg_tweens: Array[Tween] = []

func _clear_background():
    for tw in _active_bg_tweens:
        if tw and tw.is_valid():
            tw.kill()
    _active_bg_tweens.clear()
    # ... then free old nodes
```

---

### H-06 · `on_player_hurt()` creates new ColorRect on every hit
**File:** `scripts/effects/game_juice.gd` · Lines ~600–630  
**Category:** Memory · Performance  

Every call to `on_player_hurt()` creates a new `ColorRect` for the red screen flash overlay, adds it to `scene_root`, tweens it, then `queue_free`s it. If the player is hit rapidly (e.g., multi-hit attacks, lingering damage zones), multiple overlapping flash rects exist simultaneously.

**Suggested fix:**  
Reuse a single persistent overlay node:
```gdscript
var _hurt_overlay: ColorRect = null

func on_player_hurt(player, amount):
    if not _hurt_overlay or not is_instance_valid(_hurt_overlay):
        _hurt_overlay = ColorRect.new()
        _hurt_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
        _hurt_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
        # Add to persistent location
    _hurt_overlay.color = Color(1, 0, 0, 0.3)
    # Tween alpha down...
```

---

### H-07 · `_add_soul()` accesses `GameManager` without guard
**File:** `scripts/combat/player_combat.gd` · Lines 1395–1405  
**Category:** General Polish  

```gdscript
func _add_soul(amount: float) -> void:
    if has_node("/root/GameManager"):
        amount = int(amount * GameManager.get_player_dda_bonus())
    if GameManager.has_charm("soul_hoarder"):  # ← No guard!
```
Line 2 checks for GameManager, but line 4 accesses `GameManager.has_charm()` unconditionally. If GameManager doesn't exist (testing scenarios), this crashes.

**Suggested fix:**  
Wrap the second check in the same guard, or merge:
```gdscript
func _add_soul(amount: float) -> void:
    if has_node("/root/GameManager"):
        amount = int(amount * GameManager.get_player_dda_bonus())
        if GameManager.has_charm("soul_hoarder"):
            amount *= GameManager.get_charm_value("soul_hoarder", 1.0)
```

---

## MEDIUM — Suboptimal patterns or minor bugs

### M-01 · `_process()` in `music_manager.gd` runs procedural generation every frame
**File:** `scripts/music_manager.gd` · `_update_procedural_music()`  
**Category:** Performance  

`_process()` calls `_update_procedural_music()` every frame, which checks timing and generates notes. While the note generation itself is gated by timing, the function still runs string operations, dictionary lookups, and calculations every single frame even when no note is due.

**Suggested fix:**  
Use a `Timer` node set to the beat interval instead of per-frame polling, or add an early-out:
```gdscript
func _update_procedural_music() -> void:
    if not _is_playing: return  # Fast early-out
    if Time.get_ticks_msec() < _next_beat_time: return  # Skip frame work
```

---

### M-02 · Enemy projectile script uses embedded `source_code` string
**File:** `scripts/combat/enemy_base.gd` · Lines 554–593  
**Category:** Performance · Polish  

`_spawn_projectile()` builds a GDScript via `source_code` string. While the script is cached in `_cached_enemy_proj_script`, the initial `reload()` call parses and compiles GDScript at runtime. If the cache is not shared across instances (each `EnemyBase` has its own `_cached_enemy_proj_script`), each unique enemy type pays the compilation cost.

**Suggested fix:**  
Make `_cached_enemy_proj_script` a `static var` so all enemy instances share the cached script:
```gdscript
static var _cached_enemy_proj_script: GDScript = null
```
*(Same issue exists in `player_combat.gd` with `_cached_projectile_script`.)*

---

### M-03 · `_update_hud()` called frequently but does heavy work
**File:** `scripts/combat/player_combat.gd` · Lines 1980–2020  
**Category:** Performance  

`_update_hud()` is called on every damage event, every soul change, every heal, and every frame. It updates multiple Labels, ProgressBars, and StyleBoxFlat colors each time. Most of these values rarely change.

**Suggested fix:**  
Use a dirty flag pattern:
```gdscript
var _hud_dirty: bool = false

func _mark_hud_dirty(): _hud_dirty = true

func _process(delta):
    if _hud_dirty:
        _update_hud()
        _hud_dirty = false
```

---

### M-04 · `_danger_overlay` created lazily inside `_update_danger_overlay()`
**File:** `scripts/combat/player_combat.gd` · Lines 2062–2074  
**Category:** Performance  

`_update_danger_overlay()` is called every frame. If `_danger_overlay` is null, it calls `_setup_danger_overlay()` which allocates a CanvasLayer + ColorRect. This is a one-time cost, but the null check runs every frame.

**Suggested fix:**  
Call `_setup_danger_overlay()` once in `_ready()` instead of lazy init.

---

### M-05 · 50+ ungated `print()` calls across the codebase
**File:** Multiple (see list below)  
**Category:** General Polish  

Many `print()` calls are NOT gated behind `OS.is_debug_build()`. These will write to stdout in release builds, causing console spam and minor performance overhead. Key offenders:

| File | Approx. count |
|------|--------------|
| `asset_manager.gd` | ~15 |
| `inventory_system.gd` | ~12 |
| `shop_system.gd` | ~10 |
| `side_quest_manager.gd` | ~8 |
| `choice_consequences.gd` | ~6 |
| `cutscene_manager.gd` | ~6 |
| Various chapter scripts | ~20+ |

**Suggested fix:**  
Wrap all `print()` calls:
```gdscript
if OS.is_debug_build():
    print("[SHOP] Purchased %s" % item_name)
```
Or create a centralized logger utility.

---

### M-06 · `_hp_display_value` lerp in `_update_hud()` is framerate-dependent
**File:** `scripts/combat/player_combat.gd` · Line ~1982  
**Category:** General Polish  

```gdscript
_hp_display_value = lerpf(_hp_display_value, current_health, 0.15)
```
The lerp factor `0.15` is a fixed ratio per frame, making the animation speed depend on framerate (faster at higher FPS). 

**Suggested fix:**
```gdscript
_hp_display_value = lerpf(_hp_display_value, current_health, 1.0 - exp(-10.0 * delta))
```

---

### M-07 · `_apply_level_scaling()` mutates `xp_reward` / `gold_reward` without base reference
**File:** `scripts/combat/enemy_base.gd` · Lines 1197–1210  
**Category:** Save System / General Polish  

```gdscript
xp_reward = int(xp_reward * (1.0 + maxf(player_level - 1, 0) * 0.05))
gold_reward = int(gold_reward * (1.0 + maxf(player_level - 1, 0) * 0.04))
```
Unlike `max_health` / `contact_damage` / `movement_speed` which multiply from `_base_*` values, `xp_reward` and `gold_reward` multiply from their current (already-scaled) values. Each call to `_apply_level_scaling()` (triggered by DDA adjustments) compounds the rewards exponentially.

**Suggested fix:**
```gdscript
var _base_xp_reward: int
var _base_gold_reward: int
# Store in _ready(), then use in scaling:
xp_reward = int(_base_xp_reward * (1.0 + ...))
gold_reward = int(_base_gold_reward * (1.0 + ...))
```

---

### M-08 · `_play_hit_flash()` stores tween in node meta — fragile pattern
**File:** `scripts/combat/enemy_base.gd` · Lines 690–705  
**Category:** General Polish  

```gdscript
sprite.set_meta("flash_tween", flash_tween)
```
Using node metadata to track tweens works but is fragile — if anything else calls `set_meta("flash_tween", ...)` or the sprite is replaced (Kenney sprite loading), the old tween reference is lost and can't be killed.

**Suggested fix:**  
Use an instance variable `_flash_tween: Tween` like `_telegraph_tween` already does.

---

### M-09 · Scene transition overlay not reset after diamond transition
**File:** `scripts/effects/scene_transition_manager.gd` · Lines 394–402  
**Category:** General Polish  

`_diamond_out()` sets `_overlay.scale` to `Vector2(0.01, 0.01)` then animates to `Vector2.ONE`. `_diamond_in()` resets `scale` and `pivot_offset` at the end, but if the transition is interrupted (e.g., `_safe_reset_transition()`), the overlay may retain the non-identity scale, breaking subsequent fade transitions.

**Suggested fix:**  
In `_safe_reset_transition()`, explicitly reset:
```gdscript
_overlay.scale = Vector2.ONE
_overlay.pivot_offset = Vector2.ZERO
```

---

### M-10 · `die()` in `enemy_base.gd` disables physics then awaits timer
**File:** `scripts/combat/enemy_base.gd` · Lines 710–751  
**Category:** General Polish  

```gdscript
func die() -> void:
    current_state = State.DEAD
    set_physics_process(false)
    # ... 
    await get_tree().create_timer(0.6).timeout
    if not is_inside_tree(): return
    if is_instance_valid(self): queue_free()
```
`set_physics_process(false)` is called immediately, but the enemy node persists for 0.6s for death animation. During this time, the enemy's collision shapes are still active. Other enemies or the player could still collide with the dead enemy's body.

**Suggested fix:**  
Disable collision on death:
```gdscript
func die():
    current_state = State.DEAD
    set_physics_process(false)
    collision_layer = 0
    collision_mask = 0
```

---

## LOW — Minor polish or optimization opportunities

### L-01 · `_get_death_tip()` uses `randi() % array.size()` — modulo bias
**File:** `scripts/combat/player_combat.gd` · Line ~1610  
**Category:** General Polish  

```gdscript
return tip_pool[randi() % tip_pool.size()]
```
`randi() % N` introduces modulo bias when N is not a power of 2. Functionally irrelevant for tip selection, but `randi_range()` or `tip_pool.pick_random()` is more idiomatic.

**Suggested fix:** `return tip_pool.pick_random()`

---

### L-02 · `_enhance_placeholder_sprite()` creates many child nodes
**File:** `scripts/combat/enemy_base.gd` · Lines 975–1095  
**Category:** Performance  

Each enemy gets 5–10 child ColorRect nodes (outline, eyes, pupils, type-specific decorations) for placeholder sprites. With 20+ enemies on screen, this is 100–200 extra nodes. These are cosmetic and could be replaced with a single custom draw call.

**Suggested fix:**  
Consider using `_draw()` override for placeholder visuals, or skip enhancements for off-screen enemies.

---

### L-03 · `_combo_pop_tween` not killed in `_update_combo_indicator()` before null check
**File:** `scripts/combat/player_combat.gd` · Lines 2040–2050  
**Category:** General Polish  

The code correctly kills the old tween before creating a new one:
```gdscript
if _combo_pop_tween and _combo_pop_tween.is_valid():
    _combo_pop_tween.kill()
```
This is fine, but the combo indicator's `pivot_offset` is set every time the combo text changes. If `_combo_indicator.size` hasn't been computed yet (first frame), `pivot_offset` will be `Vector2.ZERO`.

**Suggested fix:**  
Set `pivot_offset` after a frame delay, or use `_combo_indicator.get_rect().size`.

---

### L-04 · `find_player()` caches but never invalidates on player death
**File:** `scripts/combat/enemy_base.gd` · Lines 785–790  
**Category:** General Polish  

```gdscript
func find_player() -> CharacterBody2D:
    if player_ref == null or not is_instance_valid(player_ref):
        var players = get_tree().get_nodes_in_group("player")
```
The `is_instance_valid` check handles freed players, but if the player dies and a new player is spawned (e.g., respawn), the old cached ref is stale until it's invalidated. Currently this works because `is_instance_valid` catches it, but it's worth noting.

---

### L-05 · `HUD` button actions use `Input.action_press/release` — no touch cleanup
**File:** `scripts/combat/player_combat.gd` · Lines 1956–1957  
**Category:** General Polish  

```gdscript
btn.button_down.connect(func() -> void: Input.action_press(action))
btn.button_up.connect(func() -> void: Input.action_release(action))
```
If the player node is freed (death) while a button is pressed, `button_up` never fires and the action stays "pressed" until the next scene load. This could cause phantom input.

**Suggested fix:**  
Release all actions in `_exit_tree()`:
```gdscript
func _exit_tree():
    for action in ["jump", "sprint", "attack", "defend", "spell", "heal"]:
        Input.action_release(action)
```

---

### L-06 · `_backup_save_file` / `_try_load_backup` — only one backup slot
**File:** `scripts/game_manager.gd`  
**Category:** Save System  

The backup system uses a single `.bak` file. If the backup itself is corrupted (e.g., two consecutive bad writes), recovery fails. Consider rotating backups (`.bak1`, `.bak2`).

---

### L-07 · `_merge_dict` result not validated for type mismatches
**File:** `scripts/game_manager.gd` · Load path  
**Category:** Save System  

`load_game()` uses `_merge_dict` to combine saved data over defaults. If a save file is hand-edited and a value type changes (e.g., `"hp"` becomes a string), the merged result silently carries the wrong type, which may cause type errors later in gameplay.

---

### L-08 · `_cached_scale_curve` shared but created per-instance
**File:** `scripts/effects/vfx_library.gd`  
**Category:** Performance  

The scale curve is created in `_ready()` and stored in `_cached_scale_curve`. Since VFXLibrary is an autoload singleton, this is fine. But if it were ever instanced multiple times, the curve would be duplicated. Consider making it a `static var` for safety.

---

## Summary

| Severity | Count | Top category |
|----------|-------|-------------|
| **CRITICAL** | 4 | Save System (3), Combat (1) |
| **HIGH** | 7 | Performance (3), Memory (3), Save (1) |
| **MEDIUM** | 10 | Performance (4), Polish (4), Save (2) |
| **LOW** | 8 | Polish (5), Save (2), Performance (1) |
| **Total** | **29** | |

### Priority fix order:
1. **C-03** — Operator precedence bug (1 min fix, prevents inventory corruption)
2. **C-01** — Atomic save writes (5 min fix, prevents data loss)
3. **C-02** — Remove `await` from recursive load (1 min fix, prevents hang)
4. **H-01** — Note caching in music manager (30 min, biggest perf win)
5. **H-03** — Frame-cached enemy group lookup in player_combat (15 min)
6. **H-06** — Reuse hurt overlay (10 min)
7. **M-07** — Base XP/gold reward compounding fix (5 min)
8. **M-05** — Gate print statements (30 min, tedious but important for release)
