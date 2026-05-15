# Comprehensive Resource Management Audit Report
## AethelgardPrototype — Godot 4.6 GDScript

**Scope:** 9 files / Audio, Memory, Tween, Signal, Timer, and Node lifecycle issues  
**Date:** 2025  
**Severity scale:** CRITICAL (crash/hang risk) · HIGH (leak/accumulation) · MEDIUM (wasteful/degraded) · LOW (code-smell/minor)

---

## BUG 1: CRITICAL — music_manager.gd — play_track() / _start_procedural_track()

**Issue:** Switching from a file-based track to a procedural track never stops `_music_player`. The `_start_procedural_track()` function (line 487) sets `_procedural_active = true` and resets indices, but does NOT call `_music_player.stop()`. If the previous track was file-based (started via `_play_file_track()`, line 457), its `AudioStreamPlayer` keeps playing indefinitely underneath the new procedural notes, causing audio overlap, doubled CPU usage, and user-audible corruption.

**Fix — music_manager.gd, line 487:**
```gdscript
func _start_procedural_track(track: Dictionary, _fade_in: bool) -> void:
    # ADD: stop any file-based stream still playing on _music_player
    if _music_player.playing:
        _music_player.stop()
    _procedural_active = true
    _procedural_note_index = 0
    ...
```

---

## BUG 2: CRITICAL — game_juice.gd — slowmo_moment() / boss_death_sequence() / reality_shatter_effect()

**Issue:** Multiple functions set `Engine.time_scale` to a low value (0.15–0.3) then await a `SceneTreeTimer` before restoring it. Because `GameJuice` is an autoload, `is_inside_tree()` is **always true**, so the guard `if not is_inside_tree(): Engine.time_scale = 1.0; return` is dead code. If `SceneTransitions.change_scene()` is called *during* the await AND the restoration tween fails (create_tween returns null on an orphaned node), `Engine.time_scale` remains permanently reduced, making the entire game run in slow-motion.

**Affected functions & lines:**
- `slowmo_moment()` — line 572
- `boss_death_sequence()` — line 633, 645
- `reality_shatter_effect()` — line 670, 673

**Fix — game_juice.gd, add a fail-safe in `_process()`:**
```gdscript
# At the top of _process:
func _process(_delta: float) -> void:
    # Fail-safe: restore time_scale if no slowmo is supposed to be active
    if not _slowmo_active and Engine.time_scale != 1.0:
        Engine.time_scale = 1.0
    ...
```
And wrap every slowmo entry/exit with a `_slowmo_active` guard bool.

---

## BUG 3: HIGH — game_juice.gd — _time_wobble()

**Issue:** `_time_wobble()` (line 586) sets `Engine.time_scale = 0.6`, awaits, then resets to `1.0`. There is no concurrency guard. If `_time_wobble()` fires during an active `slowmo_moment()` (time_scale = 0.3), it **raises** time_scale to 0.6, breaking the slowmo. When `_time_wobble()` completes, it resets to 1.0, **prematurely ending** the slowmo_moment.

**Fix — game_juice.gd, line 586:**
```gdscript
var _time_scale_lock: bool = false

func _time_wobble(duration: float = 0.1) -> void:
    if _time_scale_lock or Engine.time_scale < 0.6:
        return  # Don't override a deeper slowmo
    _time_scale_lock = true
    Engine.time_scale = 0.6
    await get_tree().create_timer(duration * 0.6).timeout
    _time_scale_lock = false
    if Engine.time_scale == 0.6:  # Only restore if we still own it
        Engine.time_scale = 1.0
```

---

## BUG 4: HIGH — vfx_library.gd — spawn() (all sub-spawners)

**Issue:** There is **no upper bound** on the number of active VFX nodes. Every `spawn()` call creates new `CPUParticles2D`, `Node2D`, or `Label` nodes. During sustained combat (rapid hits, multi-enemy encounters, boss fights with particle-heavy attacks), hundreds of VFX nodes can exist simultaneously. Each `CPUParticles2D` consumes CPU for simulation + a draw call. This will cause frame-rate collapse on lower-end hardware.

**Affected:** All spawner functions (`_spawn_particles` line 504, `_spawn_arc` line 570, `_spawn_ring_burst` line 686, `spawn_damage_number` line 843, etc.)

**Fix — vfx_library.gd, add a global cap near the top of `spawn()`:**
```gdscript
const MAX_ACTIVE_EFFECTS: int = 60
var _active_count: int = 0

func spawn(effect_name: String, pos: Vector2, parent: Node) -> Node:
    ...
    if _active_count >= MAX_ACTIVE_EFFECTS:
        return null
    ...
    # After creating the effect node:
    _active_count += 1
    # In each cleanup callback:  _active_count -= 1
```

---

## BUG 5: HIGH — sfx_manager.gd — _cache / play()

**Issue:** The `_cache` dictionary (line ~14) stores generated `AudioStreamWAV` resources keyed by SFX name. It is **never automatically cleared**. With 80+ SFX definitions, each generating a few KB of PCM data, the cache can consume 1–5 MB and grow over the session. `clear_cache()` (line 958) exists but is never called by any other file in the project.

**Fix — sfx_manager.gd, add automatic cache clearing on scene change:**
```gdscript
func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS
    get_tree().tree_changed.connect(_on_tree_changed)

# Or better: call clear_cache() from SceneTransitionManager after each transition
```
And in scene_transition_manager.gd, after scene load completes:
```gdscript
if has_node("/root/SFXManager"):
    SFXManager.clear_cache()
```

---

## BUG 6: HIGH — music_manager.gd — _play_voice_note() / play_track()

**Issue:** When switching between procedural tracks via `play_track()`, `_start_procedural_track()` (line 487) clears voice indices and timers, which stops generating *new* notes. However, `AudioStreamPlayer` child nodes from the **previous track's notes** are still playing and finish on their own schedule (via `finished` → `queue_free`, line 607). With `MAX_CONCURRENT_NOTES = 6` (line 22) and notes up to 0.5s long, up to 6 stale notes bleed into the new track. No explicit cleanup of in-flight note players occurs on track switch.

**Fix — music_manager.gd, add to `_start_procedural_track()` around line 487:**
```gdscript
func _start_procedural_track(track: Dictionary, _fade_in: bool) -> void:
    if _music_player.playing:
        _music_player.stop()
    # Kill all in-flight note players from previous track
    for child in get_children():
        if child is AudioStreamPlayer and child != _music_player:
            child.queue_free()
    _procedural_active = true
    ...
```

---

## BUG 7: HIGH — game_manager.gd — trigger_corruption_game_over()

**Issue:** `_corruption_game_over_in_progress` is set to `true` on line 235 and only reset on line 801 (inside `reset_game()`). If `trigger_corruption_game_over()` successfully transitions to the game-over scene, this flag is **never cleared** unless `reset_game()` is explicitly called. If the game-over scene allows continuing without calling `reset_game()` (e.g., a "retry" button that just loads a save), the flag stays `true` and **blocks all future corruption game-overs**, making the corruption mechanic permanently non-functional.

**Fix — game_manager.gd, line 246, add flag reset after transition:**
```gdscript
func trigger_corruption_game_over() -> void:
    if current_state == GameState.GAME_OVER or _corruption_game_over_in_progress:
        return
    _corruption_game_over_in_progress = true
    change_state(GameState.GAME_OVER)
    ...
    if has_node("/root/SceneTransitions"):
        await SceneTransitions.change_scene(...)
    else:
        get_tree().change_scene_to_file(...)
    _corruption_game_over_in_progress = false  # ADD THIS
```

---

## BUG 8: MEDIUM — game_juice.gd — _drop_combo()

**Issue:** `_drop_combo()` (line 347) creates a local tween `drop_tw` via `create_tween()` on line 359. This tween is **not tracked** in any instance variable and cannot be killed. If `_drop_combo()` is called rapidly (e.g., combo resets in quick succession), multiple tweens fight over `_combo_label.modulate:a`, causing flickering and wasted processing. Only affects combos of 10+ hits but that's a common occurrence in sustained combat.

**Fix — game_juice.gd, line 359:**
```gdscript
var _drop_tween: Tween  # ADD: track at class level

func _drop_combo() -> void:
    ...
    if was_count >= 10 and _combo_label:
        _combo_label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
        if _drop_tween and _drop_tween.is_valid():
            _drop_tween.kill()
        _drop_tween = create_tween()
        _drop_tween.tween_property(_combo_label, "modulate:a", 0.0, 0.4)
```

---

## BUG 9: MEDIUM — enemy_base.gd — _begin_telegraph()

**Issue:** `_begin_telegraph()` (line 295) creates a tween `tw` on line 321 via `create_tween()` to flash the sprite modulate. This tween is a **local variable** — never stored, never killed. Although the state machine normally prevents re-entry into TELEGRAPH, if `_apply_hitstun()` or `stagger()` interrupts the telegraph state and the enemy re-enters TELEGRAPH before the old tween finishes, two tweens simultaneously animate `sprite.modulate` causing visual corruption. The old tween also holds a reference to the sprite, delaying GC.

**Fix — enemy_base.gd, line 295:**
```gdscript
var _telegraph_tween: Tween  # ADD: track at class level

func _begin_telegraph() -> void:
    ...
    if has_node("Sprite"):
        var sprite = get_node("Sprite")
        if _telegraph_tween and _telegraph_tween.is_valid():
            _telegraph_tween.kill()
        _telegraph_tween = create_tween()
        _telegraph_tween.tween_property(sprite, "modulate", Color(1.0, 0.4, 0.2, 1.0), ...)
        _telegraph_tween.tween_property(sprite, "modulate", orig_color, ...)
```

---

## BUG 10: MEDIUM — player_combat.gd — _create_spell_projectile()

**Issue:** The projectile created in `_create_spell_projectile()` (line 990) has **two independent free paths**:
1. `body_entered` signal closure (line 1027) calls `projectile.queue_free()`
2. The attached `_process` script (line 1057) calls `queue_free()` when `lifetime <= 0`

While `queue_free()` is idempotent within the same frame, if `body_entered` fires on frame N and the node is freed at end of frame N, any pending signal emissions (e.g., a second body entering in the same physics step) invoke the closure on a **freed node reference**. In Godot 4.x this typically results in a silent error rather than a crash, but it pollutes the debug log.

**Fix — player_combat.gd, line 1027:**
```gdscript
projectile.body_entered.connect(func(body: Node2D) -> void:
    if not is_instance_valid(projectile):
        return
    if body.is_in_group("enemies") and body.has_method("take_damage"):
        ...
        projectile.queue_free()
)
```

---

## BUG 11: MEDIUM — enemy_base.gd — _spawn_projectile()

**Issue:** Same dual-free pattern as BUG 10. The inline projectile script (line 470) has both `_on_body()` → `queue_free()` and `lifetime` → `queue_free()` in `_physics_process()`. Additionally, `_on_body()` calls `queue_free()` for non-enemy non-player bodies (line 479: `elif not body.is_in_group("enemies"): queue_free()`), meaning environmental collision also triggers free. No `is_instance_valid` guard.

**Fix — enemy_base.gd, inline script around line 470:**
```gdscript
func _on_body(body):
    if not is_instance_valid(self):
        return
    ...
```

---

## BUG 12: MEDIUM — scene_transition_manager.gd — _combat_entry_out()

**Issue:** `_combat_entry_out()` creates a `flash_tw` tween (for `_flash_overlay`) that runs **independently and is not awaited**. The function then creates and awaits a separate `tween` for `_overlay`. If `change_scene()` re-entrance somehow occurs (e.g., a rapid double-call before `is_transitioning` fully latches), `flash_tw` and a new transition's tween would fight over `_flash_overlay.modulate.a`. More importantly, the un-tracked `flash_tw` cannot be killed by `_safe_reset_transition()`.

**Fix — scene_transition_manager.gd, store and kill `flash_tw`:**
```gdscript
var _flash_tween: Tween  # Track it

# In _combat_entry_out:
    if _flash_tween and _flash_tween.is_valid():
        _flash_tween.kill()
    _flash_tween = create_tween()
    _flash_tween.tween_property(...)
```

---

## BUG 13: MEDIUM — object_pool.gd — acquire() / stale reference accumulation

**Issue:** When a scene changes, nodes that were `acquire()`'d and added to the scene tree are freed with the scene. The pool's internal `_pools[type]` arrays still hold `WeakRef`-less direct references to these freed nodes. `acquire()` (line ~80) handles this by checking `is_instance_valid()` and skipping stale entries, but each skip is an O(1) pop that silently discards the entry without logging. Over many scene transitions for pool types with high churn (projectiles, VFX), the arrays bloat with stale references that consume loop iterations before a valid node is found.

**Fix — object_pool.gd, add periodic cleanup:**
```gdscript
func _purge_stale(pool_type: String) -> void:
    if not _pools.has(pool_type):
        return
    _pools[pool_type] = _pools[pool_type].filter(
        func(n): return is_instance_valid(n)
    )
```
Call `_purge_stale()` from `release()` or on a timer every few seconds.

---

## BUG 14: MEDIUM — player_combat.gd — die() / _on_death_complete()

**Issue:** The death sequence in `_on_death_complete()` (lines 1501+) uses multiple `await get_tree().create_timer(...).timeout` calls with `is_inside_tree()` guards. However, after `die()` calls `queue_free()` (implicitly via the death sequence), the player node is marked for deletion. Between the `queue_free()` call and the actual deletion (end of frame), pending awaits can still resume and execute code on the half-dead node. This is safe in practice for the guards present, BUT: `SceneTransitions.change_scene()` is called (line 1517) **from within the node that is about to be freed**, which means the scene change races with the node's deletion.

**Fix — player_combat.gd, use `call_deferred` for the scene change:**
```gdscript
# In _on_death_complete, before the scene change:
if has_node("/root/SceneTransitions"):
    SceneTransitions.call_deferred("change_scene", revival_scene, ...)
```

---

## BUG 15: MEDIUM — game_manager.gd — _try_spawn_enforcers()

**Issue:** `_try_spawn_enforcers()` (line 298) creates `CharacterBody2D.new()` enforcers and adds them to `player.get_parent()` via `call_deferred`. These enforcers are added to the **scene tree** (not as children of the autoload), so they're freed on scene change. However, the group check `get_tree().get_nodes_in_group("administrator_enforcers")` (line 312) counts nodes across **all scenes including those mid-deletion**. If the scene changes right after spawning, `call_deferred("add_child")` could fire for a parent that was just freed, silently failing and leaving the enforcer as an orphan node consuming memory.

**Fix — game_manager.gd, line 330:**
```gdscript
var parent_ref = weakref(player.get_parent())
for i in range(spawn_count):
    var enforcer = CharacterBody2D.new()
    ...
    if parent_ref.get_ref():
        parent_ref.get_ref().call_deferred("add_child", enforcer)
    else:
        enforcer.queue_free()
```

---

## BUG 16: LOW — player_combat.gd — _danger_tween (dead code)

**Issue:** `_danger_tween` is declared as an instance variable but is **never assigned or used** anywhere in the 1960-line file. This is dead code that implies an unfinished danger-pulse feature. While it doesn't leak (it's `null`), it creates confusion and implies missing cleanup for a tween that was intended to exist.

**Fix — player_combat.gd:** Either remove the variable declaration, or implement the intended danger overlay tween and add proper `kill()` cleanup.

---

## BUG 17: LOW — object_pool.gd — pool never shrinks

**Issue:** Once nodes are allocated (up to `MAX_POOL_SIZE = 50` per type), they are held as hidden children of the pool autoload node **indefinitely**, even if that pool type is never used again. With many pool types registered over a full playthrough, memory grows monotonically. Each pooled node retains its full sub-tree (children, shapes, scripts).

**Fix — object_pool.gd, add shrink-on-idle:**
```gdscript
const POOL_IDLE_TIMEOUT: float = 60.0  # seconds
var _pool_last_access: Dictionary = {}

func _process(delta):
    for pool_type in _pools:
        if Time.get_ticks_msec() / 1000.0 - _pool_last_access.get(pool_type, 0.0) > POOL_IDLE_TIMEOUT:
            _shrink_pool(pool_type)
```

---

## BUG 18: LOW — game_juice.gd — boss_intro_zoom()

**Issue:** `boss_intro_zoom()` (line 614) creates a tween on the camera (`create_tween()` targeting `cam.zoom`) and simultaneously sets `Engine.time_scale = 0.8` with await. The tween is stored in a local variable (`tw`) and **not tracked**. If `boss_intro_zoom()` is called twice (e.g., boss has two intro phases), two camera-zoom tweens fight. More critically, if the camera node is freed during the 3-second await (player dies during boss intro), the tween targets a freed node.

**Fix — game_juice.gd, line 614:** Track the tween and validate camera before use:
```gdscript
var _intro_tween: Tween

func boss_intro_zoom(_boss_node: Node2D) -> void:
    var cam = get_viewport().get_camera_2d()
    if not cam:
        return
    if _intro_tween and _intro_tween.is_valid():
        _intro_tween.kill()
    _intro_tween = create_tween()
    ...
```

---

## BUG 19: LOW — sfx_manager.gd — play_positional()

**Issue:** `play_positional()` (line ~941) temporarily modifies the instance variable `_sfx_volume`, calls `play()`, then restores it. While GDScript is single-threaded and this is *technically* safe, if `play()` ever becomes async or if a signal handler fires during `play()` that also reads `_sfx_volume`, the volume will be incorrect. This is a fragile anti-pattern.

**Fix — sfx_manager.gd, pass volume as parameter instead of mutating shared state:**
```gdscript
func play_positional(sfx_name: String, world_pos: Vector2, listener_pos: Vector2, max_dist: float = 800.0) -> void:
    var dist = world_pos.distance_to(listener_pos)
    if dist > max_dist:
        return
    var falloff = 1.0 - (dist / max_dist)
    play(sfx_name, 0.0, falloff)  # Add optional volume_mult parameter to play()
```

---

## Summary Table

| # | Severity | File | Function | Category |
|---|----------|------|----------|----------|
| 1 | CRITICAL | music_manager.gd | play_track / _start_procedural_track | Audio overlap — file playback not stopped |
| 2 | CRITICAL | game_juice.gd | slowmo_moment / boss_death / reality_shatter | Engine.time_scale stuck permanently |
| 3 | HIGH | game_juice.gd | _time_wobble | Concurrent time_scale corruption |
| 4 | HIGH | vfx_library.gd | spawn (all) | Unbounded VFX node accumulation |
| 5 | HIGH | sfx_manager.gd | play / _cache | Unbounded AudioStreamWAV cache growth |
| 6 | HIGH | music_manager.gd | _play_voice_note / play_track | Stale note AudioStreamPlayers bleed across tracks |
| 7 | HIGH | game_manager.gd | trigger_corruption_game_over | Latch flag never cleared → mechanic disabled |
| 8 | MEDIUM | game_juice.gd | _drop_combo | Untracked tween stacking |
| 9 | MEDIUM | enemy_base.gd | _begin_telegraph | Untracked tween stacking on sprite |
| 10 | MEDIUM | player_combat.gd | _create_spell_projectile | Dual-free path on projectile |
| 11 | MEDIUM | enemy_base.gd | _spawn_projectile | Dual-free path on projectile |
| 12 | MEDIUM | scene_transition_manager.gd | _combat_entry_out | Untracked flash tween |
| 13 | MEDIUM | object_pool.gd | acquire | Stale reference accumulation |
| 14 | MEDIUM | player_combat.gd | die / _on_death_complete | Scene change from dying node |
| 15 | MEDIUM | game_manager.gd | _try_spawn_enforcers | Orphan enforcer on scene race |
| 16 | LOW | player_combat.gd | (class scope) | Dead _danger_tween variable |
| 17 | LOW | object_pool.gd | (pool lifecycle) | Pool never shrinks |
| 18 | LOW | game_juice.gd | boss_intro_zoom | Untracked camera tween |
| 19 | LOW | sfx_manager.gd | play_positional | Fragile shared-state mutation |

**Totals:** 2 CRITICAL · 5 HIGH · 7 MEDIUM · 5 LOW = **19 bugs**

---

## Priority Fix Order

1. **BUG 1 + 6** (music_manager.gd) — Fix together: stop `_music_player` and kill note children in `_start_procedural_track()`
2. **BUG 2 + 3** (game_juice.gd) — Add `_slowmo_active` guard and priority system for Engine.time_scale
3. **BUG 7** (game_manager.gd) — One-line fix: reset `_corruption_game_over_in_progress` after transition
4. **BUG 4** (vfx_library.gd) — Add MAX_ACTIVE_EFFECTS cap
5. **BUG 5** (sfx_manager.gd) — Wire up `clear_cache()` to scene transitions
6. **BUGs 8, 9, 12, 18** — Track and kill tweens (pattern fix, apply to all four)
7. **BUGs 10, 11** — Add `is_instance_valid` guards to projectile closures
8. Remaining MEDIUM/LOW bugs as time permits
