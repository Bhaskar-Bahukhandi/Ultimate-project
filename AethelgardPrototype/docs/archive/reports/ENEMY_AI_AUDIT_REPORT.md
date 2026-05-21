# Enemy AI & Variety Systems — Comprehensive Audit Report

**Date:** 2026-03-01  
**Scope:** `enemy_base.gd`, all `enemies/*.gd`, `drop_manager.gd`, `game_manager.gd` DDA  
**Project:** AethelgardPrototype (Godot 4.6 GDScript, Hollow Knight-style)

---

## Summary

| Severity     | Count |
|-------------|-------|
| CRITICAL     | 5     |
| HIGH         | 9     |
| MEDIUM       | 12    |
| LOW          | 8     |
| IMPROVEMENTS | 14    |

---

## CRITICAL Bugs (Crashes / Softlocks)

### C-1: `_apply_level_scaling` accesses GameManager without null guard — crash on startup without autoload

**File:** `scripts/combat/enemy_base.gd` ~L1038-1048  
**Impact:** If GameManager autoload is missing or renamed, every enemy crashes on `_ready()`.

```gdscript
# CURRENT (broken)
func _apply_level_scaling() -> void:
    var player_level: int = GameManager.player_stats.get("level", 1)
    var level_factor = 1.0 + maxf(player_level - 1, 0) * 0.08
    var dda_mult = GameManager.get_difficulty_multiplier()
```

```gdscript
# FIX
func _apply_level_scaling() -> void:
    if not has_node("/root/GameManager"):
        return
    var player_level: int = GameManager.player_stats.get("level", 1)
    var level_factor = 1.0 + maxf(player_level - 1, 0) * 0.08
    var dda_mult = GameManager.get_difficulty_multiplier()
```

---

### C-2: DDA telegraph visual desyncs from actual timing — misleading attack windows

**File:** `scripts/combat/enemy_base.gd` ~L306-325  
**Impact:** The telegraph tween uses the **pre-DDA** `telegraph_duration`, but the state machine uses the **post-DDA** value. At low difficulty (DDA mult 0.75), the visual flash finishes in ~0.28s but the state machine waits ~0.47s — the enemy stands idle with normal color before striking. At high difficulty, the attack fires before the visual completes.

```gdscript
# CURRENT (broken order)
if has_node("Sprite"):
    var sprite = get_node("Sprite")
    var orig_color = sprite.modulate
    if _telegraph_tween and _telegraph_tween.is_valid():
        _telegraph_tween.kill()
    _telegraph_tween = create_tween()
    _telegraph_tween.tween_property(sprite, "modulate", Color(1.0, 0.4, 0.2, 1.0), telegraph_duration * 0.5)
    _telegraph_tween.tween_property(sprite, "modulate", orig_color, telegraph_duration * 0.3)

if has_node("/root/GameManager"):
    var dda = GameManager.get_difficulty_multiplier()
    telegraph_duration = maxf(telegraph_duration / dda, 0.25)
```

```gdscript
# FIX — apply DDA scaling BEFORE creating the tween
if has_node("/root/GameManager"):
    var dda = GameManager.get_difficulty_multiplier()
    telegraph_duration = maxf(telegraph_duration / dda, 0.25)

if has_node("Sprite"):
    var sprite = get_node("Sprite")
    var orig_color = sprite.modulate
    if _telegraph_tween and _telegraph_tween.is_valid():
        _telegraph_tween.kill()
    _telegraph_tween = create_tween()
    _telegraph_tween.tween_property(sprite, "modulate", Color(1.0, 0.4, 0.2, 1.0), telegraph_duration * 0.5)
    _telegraph_tween.tween_property(sprite, "modulate", orig_color, telegraph_duration * 0.3)
```

---

### C-3: DataSprite fallback bolt uses `ColorRect` (Control) as if it were Node2D — bolt doesn't move or hit correctly

**File:** `scripts/combat/enemies/data_sprite.gd` ~L131-160  
**Impact:** `ColorRect` inherits from `Control`, not `Node2D`. When added as a child of a Node2D parent, `global_position` behaves differently. The bolt will not position or move correctly, and the distance-based collision check (`bolt.global_position.distance_to(player.global_position)`) gives wrong results.

```gdscript
# CURRENT (broken)
func _create_fallback_bolt(dir: Vector2) -> Node2D:
    var bolt = ColorRect.new()
    bolt.color = Color(0.3, 0.6, 1.0, 0.9)
    bolt.size = Vector2(12, 6)
    ...
    return bolt  # ColorRect is NOT a Node2D!
```

```gdscript
# FIX — use Area2D with a colored visual child, or use a Sprite2D
func _create_fallback_bolt(dir: Vector2) -> Node2D:
    var bolt = Node2D.new()
    bolt.name = "DataBolt"
    var visual = ColorRect.new()
    visual.color = Color(0.3, 0.6, 1.0, 0.9)
    visual.size = Vector2(12, 6)
    visual.position = Vector2(-6, -3)
    visual.mouse_filter = Control.MOUSE_FILTER_IGNORE
    bolt.add_child(visual)
    bolt.rotation = dir.angle()
    bolt.set_meta("direction", dir)
    bolt.set_meta("speed", _bolt_speed)
    bolt.set_meta("damage", _bolt_damage)
    return bolt
```

---

### C-4: GlitchWolf teleport can clip enemy inside walls — softlock/stuck enemy

**File:** `scripts/combat/enemies/glitch_wolf.gd` ~L84-97  
**Impact:** `_teleport_behind_player` sets `global_position` directly without any physics collision check. If the target position is inside a wall, the wolf gets stuck permanently. Compare with `AdministratorProxyBoss._admin_command("teleport")` which properly checks with `PhysicsPointQueryParameters2D`.

```gdscript
# CURRENT (no safety check)
global_position = Vector2(target_x, target_y)
```

```gdscript
# FIX — validate destination before teleporting
var space_state = get_world_2d().direct_space_state
if space_state:
    var params = PhysicsPointQueryParameters2D.new()
    params.position = Vector2(target_x, target_y)
    params.collision_mask = 1  # terrain layer
    if not space_state.intersect_point(params, 1).is_empty():
        # Destination blocked — try in front instead
        target_x = player.global_position.x - behind_dir * _teleport_offset
        params.position = Vector2(target_x, target_y)
        if not space_state.intersect_point(params, 1).is_empty():
            return  # Both blocked, abort teleport
global_position = Vector2(target_x, target_y)
```

---

### C-5: Boss fights never call `GameManager.start_boss_fight()` / `end_boss_fight()` — flawless achievement permanently broken

**File:** All boss scripts + `scripts/game_manager.gd` ~L494-507  
**Impact:** GameManager has a complete boss fight tracking system (`start_boss_fight`, `record_boss_hit_taken`, `end_boss_fight`) that checks for the `no_damage_boss` achievement. **None** of the 4 boss scripts ever call these methods. The achievement is impossible to unlock.

```gdscript
# FIX — Example for TutorialKnightBoss._start_boss_intro()
# Add at start of fight:
if has_node("/root/GameManager"):
    GameManager.start_boss_fight()

# FIX — In die() or boss_defeated handler:
if has_node("/root/GameManager"):
    GameManager.end_boss_fight()
```

Same for ClockworkAutomatonBoss, DataWraithBoss, AdministratorProxyBoss.

---

## HIGH Priority Issues (Broken Mechanics)

### H-1: ShadowWraith ignores base class state machine — stun recovery sets wrong state

**File:** `scripts/combat/enemies/shadow_wraith.gd`  
**Impact:** ShadowWraith overrides `_ai_behavior` and only checks its own `_phase` enum, never `current_state`. When `_apply_hitstun()` fires (via base `take_damage` during corporeal), it sets `current_state = State.STUNNED` and later resets to `State.CHASE`. But the wraith's AI never checks `current_state`, so after stun recovery the internal state is `CHASE` while behavior is driven by `_phase`. This works accidentally but means the wraith's state is permanently desynced.

```gdscript
# FIX — check base state before phase behavior
func _ai_behavior(delta: float) -> void:
    if current_state == State.STUNNED:
        velocity.x = move_toward(velocity.x, 0.0, 200.0 * delta)
        return
    _phase_timer += delta
    _float_offset += delta * 2.0
    match _phase:
        Phase.ETHEREAL:
            _ethereal_behavior(delta)
        Phase.CORPOREAL:
            _corporeal_behavior(delta)
```

---

### H-2: No contact damage system — `contact_damage` variable is never used for body collision

**File:** `scripts/combat/enemy_base.gd`  
**Impact:** Every enemy has a `contact_damage` value but there is NO body collision handler that damages the player on touch. Damage only happens through explicit `_deal_damage_in_range()` calls during attacks. Walking into an enemy does nothing. In a Hollow Knight-style game, contact damage is fundamental.

```gdscript
# FIX — Add to enemy_base.gd _setup_detection_areas() or as separate hurtbox
# Option: Connect _detection_area.body_entered for contact damage
func _on_player_contact(body: Node2D) -> void:
    if body.is_in_group("player") and is_hostile and current_state != State.DEAD:
        if body.has_method("take_damage"):
            body.take_damage(contact_damage, global_position, enemy_name, "contact")
```

Note: Needs a cooldown to prevent per-frame damage while overlapping.

---

### H-3: Enemies walk off platform edges during patrol — no ledge detection

**File:** `scripts/combat/enemy_base.gd` ~L247-264 (`_state_patrol`)  
**Impact:** Patrol only checks `is_on_wall()` to reverse direction. There's no floor-edge raycast. Patrolling enemies walk straight off cliffs.

```gdscript
# FIX — Add floor-ahead raycasts
func _state_patrol(delta: float) -> void:
    velocity.x = patrol_direction * movement_speed * 0.5
    patrol_timer += delta
    if _player_in_detection:
        current_state = State.CHASE
        return
    # Edge detection
    if is_on_floor():
        var ray_pos = global_position + Vector2(patrol_direction * 20.0, 5.0)
        var space = get_world_2d().direct_space_state
        if space:
            var query = PhysicsRayQueryParameters2D.create(ray_pos, ray_pos + Vector2(0, 30), 1)
            var result = space.intersect_ray(query)
            if result.is_empty():
                patrol_direction *= -1.0
                patrol_timer = 0.0
                return
    if is_on_wall() or patrol_timer >= patrol_duration:
        patrol_direction *= -1.0
        patrol_timer = 0.0
```

---

### H-4: `_on_gold_touched` accesses `GameManager` without null guard — crash if autoload missing

**File:** `scripts/drop_manager.gd` ~L365  

```gdscript
# CURRENT
GameManager.add_gold(amount)
```

```gdscript
# FIX
if has_node("/root/GameManager"):
    GameManager.add_gold(amount)
```

---

### H-5: CorruptedRat uses `_play_hit_flash()` as telegraph — misleads player

**File:** `scripts/combat/enemies/corrupted_rat.gd` ~L80  
**Impact:** `_play_hit_flash()` flashes white/red, which is the universal "I got hurt" feedback. Using it as an attack telegraph makes the player think the rat was damaged, not that it's about to lunge.

```gdscript
# FIX — use a distinct telegraph visual
func _perform_lunge() -> void:
    _is_lunging = true
    velocity.x = 0.0
    # Distinct telegraph: orange/yellow flash instead of damage flash
    if has_node("Sprite"):
        var sprite = get_node("Sprite")
        var tw = create_tween()
        tw.tween_property(sprite, "modulate", Color(1.0, 0.7, 0.2), 0.08)
        tw.tween_property(sprite, "modulate", Color.WHITE, 0.07)
    _sfx("enemy_telegraph", 0.1)
    await get_tree().create_timer(0.15).timeout
    ...
```

---

### H-6: Enemy projectiles pass through walls — no obstacle collision

**File:** `scripts/combat/enemy_base.gd` ~L445-515 (projectile script)  
**Impact:** The inline projectile script only checks `body_entered` for player group or non-enemy bodies. Wall collision would depend on having physics layers set correctly. The projectile has `collision_mask = 2` (player only), so it **never** collides with terrain (layer 1). Projectiles fly through all walls.

```gdscript
# FIX — set collision_mask to detect both player (2) and terrain (1)
proj.collision_mask = 3  # bits 1+2 = terrain + player
# In the inline script, check if collider is terrain:
func _on_body(body):
    if body.is_in_group("player") and body.has_method("take_damage"):
        body.take_damage(damage, global_position, "Enemy Projectile")
        queue_free()
    elif body.collision_layer & 1:  # terrain
        queue_free()
```

Same issue affects: Clockwork Automaton gears, Data Wraith tendrils, Admin Proxy projectiles, DataSprite bolts.

---

### H-7: ClockworkAutomatonBoss phase check order can skip Phase 2 on large hits

**File:** `scripts/combat/enemies/clockwork_automaton_boss.gd` ~L183-190  

```gdscript
# CURRENT
if hp_pct <= PHASE2_HP_PCT and phase < 2:
    _enter_phase(2)
elif hp_pct <= PHASE3_HP_PCT and phase < 3:
    _enter_phase(3)
```

If a massive hit drops the boss from 100% to 25%, `phase < 2` is true so it enters Phase 2. Phase 3 is skipped until the NEXT `_ai_behavior` tick. Comment says "Check lower phases first so a large hit doesn't skip phases" but `elif` prevents checking both in the same tick.

```gdscript
# FIX — use sequential ifs, not elif
if hp_pct <= PHASE3_HP_PCT and phase < 3:
    if phase < 2:
        _enter_phase(2)
    _enter_phase(3)
elif hp_pct <= PHASE2_HP_PCT and phase < 2:
    _enter_phase(2)
```

Or better: check from highest phase down:
```gdscript
if hp_pct <= PHASE3_HP_PCT and phase < 3:
    _enter_phase(3)
elif hp_pct <= PHASE2_HP_PCT and phase < 2:
    _enter_phase(2)
```

---

### H-8: Detection Area2D collision_mask targets layer 2 but player layer isn't guaranteed to be 2

**File:** `scripts/combat/enemy_base.gd` ~L981-1000  
**Impact:** All detection areas use `collision_mask = 2` (bit 2). If the player's `collision_layer` is not exactly bit 2, detection will fail silently. There's no validation or constant for this. Needs a shared constant or project-level layer assignment.

---

### H-9: `_on_pickup_expired` creates tween on DropManager instead of pickup node

**File:** `scripts/drop_manager.gd` ~L378-382  
**Impact:** If multiple pickups expire simultaneously, many orphan tweens are created on the DropManager node. If DropManager processes other logic, these tweens accumulate.

```gdscript
# CURRENT
var tween = create_tween()  # creates on DropManager (self)
```

```gdscript
# FIX
var tween = pickup.create_tween()  # tween bound to pickup, auto-freed with it
```

---

## MEDIUM Issues (Polish)

### M-1: `take_damage` calls `TweenAnimator.play_hurt(self)` directly instead of using `_tween_hurt()` wrapper

**File:** `scripts/combat/enemy_base.gd` ~L558  
**Impact:** Inconsistency. The base class defines safe wrappers `_tween_hurt()` and `_tween_die()` but `take_damage` bypasses them. If TweenAnimator is ever converted to an autoload, this would need a guard.

---

### M-2: All child enemies redundantly call `add_to_group("enemies")` — already done in base `_ready()`

**Files:** `slime.gd:32`, `corrupted_rat.gd:27`, `glitch_wolf.gd:27`, `corrupted_guard.gd:30`, `data_sprite.gd:33`, `shadow_wraith.gd:30`, `clockwork_soldier.gd:27`, `administrator_enforcer.gd:24`  
**Impact:** Harmless (idempotent) but clutters code.

---

### M-3: Child enemies override `max_health`/`current_health` AFTER `super._ready()` — negates level scaling

**Files:** All non-boss enemy scripts (slime.gd ~L22-24, etc.)  
**Impact:** `super._ready()` calls `_apply_level_scaling()` which scales `max_health`. Then the child's `_ready()` sets `max_health = 30.0` (hardcoded), overriding the scaled value. Boss scripts correctly set stats BEFORE `super._ready()` — regular enemies should do the same.

```gdscript
# CURRENT (slime.gd) — scaling is lost
func _ready() -> void:
    super._ready()          # scales max_health from 50 → 54
    max_health = 30.0       # overwritten!
    current_health = max_health
```

```gdscript
# FIX — set stats BEFORE super._ready()
func _ready() -> void:
    enemy_name = "Slime"
    max_health = 30.0
    current_health = max_health
    contact_damage = 8.0
    movement_speed = 40.0
    detection_range = 250.0
    attack_range = 50.0
    xp_reward = 15
    gold_reward = 5
    elasticity = 1.5
    super._ready()
```

Applies to: Slime, CorruptedRat, GlitchWolf, CorruptedGuard, DataSprite, ShadowWraith, ClockworkSoldier, AdministratorEnforcer.

---

### M-4: Boss intro can permanently lock player input if boss is destroyed externally during intro sequence

**Files:** `tutorial_knight_boss_enemy.gd` ~L91-157, `clockwork_automaton_boss.gd`, similar pattern  
**Impact:** If the tween is killed before the final callback (e.g., the boss node is freed by an external system), `player.set_input_locked(false)` never fires. Player is permanently frozen.

**Fix:** Add a `tree_exiting` signal connection to ensure unlock:
```gdscript
tree_exiting.connect(func():
    if is_instance_valid(player) and player.has_method("set_input_locked"):
        player.set_input_locked(false)
)
```

---

### M-5: `_on_detection_exited` doesn't verify player_ref — stale reference on multi-player edge case

**File:** `scripts/combat/enemy_base.gd` ~L1006-1008  
**Impact:** If detection exit fires after player_ref is freed, `_player_in_detection` is set to false but `player_ref` is never nulled. `find_player()` would still return the stale reference until `is_instance_valid` catches it.

---

### M-6: DropManager `_process` iterates ALL pickups every frame for magnetism

**File:** `scripts/drop_manager.gd` ~L275-290  
**Impact:** With `MAX_PICKUPS = 50`, this is up to 50 distance calculations per frame. Not catastrophic but wasteful. Could be event-driven or use Area2D overlap instead.

---

### M-7: Enemy separation loop is O(n²) across all enemies

**File:** `scripts/combat/enemy_base.gd` ~L279-283  
**Impact:** Every chasing enemy iterates all enemies in the group. With 20 enemies, that's 400 checks per physics frame. Should use spatial partitioning or limit to nearest neighbors.

```gdscript
# Current O(n²):
for other in get_tree().get_nodes_in_group("enemies"):
    if other == self or not is_instance_valid(other): continue
    var sep = global_position - other.global_position
    if sep.length() < 60.0 and sep.length() > 0.1:
        velocity.x += sep.normalized().x * 80.0
```

---

### M-8: `_generate_default_loot_table` creates new Resources every `_ready()` — no caching

**File:** `scripts/combat/enemy_base.gd` ~L1062-1090  
**Impact:** Every enemy without a loot_table export creates a fresh LootTable + LootEntry resources. For 50 enemies, that's 50+ Resource allocations. Could use shared presets.

---

### M-9: ShadowWraith soul drain bypasses DDA scaling — always same damage regardless of difficulty

**File:** `scripts/combat/enemies/shadow_wraith.gd` ~L110-118  
**Impact:** `_soul_drain_damage = 5.0` is hardcoded and never scaled by DDA or level. All other attacks are scaled through `contact_damage` which is level-scaled.

---

### M-10: CorruptedGuard sprite modulate set to `Color(0.6, 0.7, 1.0)` during block but never restored if interrupted

**File:** `scripts/combat/enemies/corrupted_guard.gd` ~L91-96  
**Impact:** If the guard is stunned or killed during block, the sprite stays blue-tinted. `die()` sets `_is_blocking = false` but doesn't reset sprite modulate.

```gdscript
# FIX — reset sprite in die()
func die() -> void:
    if current_state == State.DEAD:
        return
    _is_blocking = false
    if has_node("Sprite"):
        get_node("Sprite").modulate = Color.WHITE
    ...
```

---

### M-11: Clockwork Automaton gear projectiles managed via coroutine loops — potential leak on fast death

**File:** `scripts/combat/enemies/clockwork_automaton_boss.gd` ~L395-430  
**Impact:** `_spawn_gear` creates a coroutine that runs `while elapsed < 3.0`. If the boss dies, `_safe()` returns false and the loop exits, but the gear may already be queued for the next frame's `await`. The `die()` cleanup loop handles this, but there's a race condition between the coroutine's `await get_tree().process_frame` and the `die()` calling `gear.queue_free()`.

---

### M-12: Admin Proxy Boss `/teleport` command can teleport player to unreachable area

**File:** `scripts/combat/enemies/administrator_proxy_boss.gd` ~L216-228  
**Impact:** The command generates a random offset (-200 to 200) and does a collision check, but only verifies the point isn't inside solid geometry. It doesn't check if the position is reachable (e.g., over a pit, on a floating platform). The player could be teleported into a death zone.

---

## LOW Issues (Dead Code / Style)

### L-1: `_glow_timer` and `_glow_pulse_speed` unused in AdministratorEnforcer

**File:** `scripts/combat/enemies/administrator_enforcer.gd` ~L10-13  
Already annotated with `@warning_ignore("unused_private_class_variable")`. Should be removed if not needed.

---

### L-2: `_boss_intro_zoom()` wrapper defined but boss scripts could call it directly

**File:** `scripts/combat/enemy_base.gd` ~L1225  
The wrapper just calls `GameJuice.boss_intro_zoom(self)` with a guard. Fine but adds a layer.

---

### L-3: `_safe()` helper defined identically in 3 boss scripts — should be in base class

**Files:** `tutorial_knight_boss_enemy.gd:465`, `clockwork_automaton_boss.gd:432`, `administrator_proxy_boss.gd:380`  
All have identical `func _safe() -> bool: return is_inside_tree() and current_state != State.DEAD`.

---

### L-4: `_has_gm()` helper defined in 2 boss scripts — should be in base class

**Files:** `tutorial_knight_boss_enemy.gd:703`, `clockwork_automaton_boss.gd:434`

---

### L-5: `_recent_attacks` tracking in TutorialKnightBoss uses Array — could be simpler

**File:** `scripts/combat/enemies/tutorial_knight_boss_enemy.gd` ~L302-310  
Maintains an array with manual pop_front when size > 2. A simple "last_attack" string would suffice.

---

### L-6: `attack_weights` dictionary initialized but never modified per-enemy

**File:** `scripts/combat/enemy_base.gd` ~L73-74  
All enemies get uniform weight `1.0` for every attack. The weighted random system exists but is never leveraged for variety.

---

### L-7: `_pending_phase` set in `_trigger_phase_pause` but never read

**File:** `scripts/combat/enemies/tutorial_knight_boss_enemy.gd` ~L530-545  
`_pending_phase` is written to in `_trigger_phase_pause` and `_enter_rage_phase` but never read anywhere.

---

### L-8: `retreat_after_attack` and `retreat_timer` exist in base but no enemy ever sets them

**File:** `scripts/combat/enemy_base.gd` ~L78-79  
`retreat_after_attack = false` is never set to true in any child class. Dead feature.

---

## IMPROVEMENT Suggestions

### I-1: Add invincibility frames (i-frames) to enemies after being hit

Currently enemies can be stunlocked by rapid attacks. Add a short `hit_cooldown` period (0.1-0.2s) where `take_damage` is ignored. This is standard in Hollow Knight-style games.

---

### I-2: Add platform-aware pathfinding or vertical AI behaviors

All enemy chasing uses flat `direction_to_player().x` — enemies have no concept of platforms, ladders, or vertical level design. For a Hollow Knight-style game, at minimum:
- Ground enemies should stop at edges when chasing (not just during patrol)
- Flying enemies (DataSprite, ShadowWraith) already work vertically
- Consider NavigationAgent2D for complex level geometry

---

### I-3: Add line-of-sight to initial detection — don't aggro through walls

Detection uses Area2D (radius-based). Enemies detect the player through walls. Add a raycast check in `_on_detection_entered`:
```gdscript
func _on_detection_entered(body: Node2D) -> void:
    if body.is_in_group("player"):
        # LOS check
        var space = get_world_2d().direct_space_state
        var query = PhysicsRayQueryParameters2D.create(global_position, body.global_position, 1)
        query.exclude = [get_rid()]
        var result = space.intersect_ray(query)
        if result.is_empty() or result.collider == body:
            _player_in_detection = true
            player_ref = body as CharacterBody2D
```

---

### I-4: Create a boss HP bar UI at screen bottom (Hollow Knight style)

Current boss HP is a tiny bar hovering above the boss sprite. Hollow Knight uses a large, prominent bar at the bottom of the screen. Create a dedicated `BossHPBar` CanvasLayer UI that displays the boss name and a full-width bar.

---

### I-5: Add enemy group coordination / pack tactics

The enemy separation code prevents stacking, but there's no group AI. Suggestions:
- Flanking: If one enemy is in front, others try to get behind
- Attack turns: Only one enemy attacks at a time, others circle
- Alert system: One enemy detecting the player alerts nearby enemies

---

### I-6: Add unique death loot for bosses

All enemies use the same generic loot table. Bosses should drop guaranteed unique items or key items:
```gdscript
# In boss _ready():
var boss_loot = LootTable.new()
var key_item = LootEntry.new()
key_item.item_id = "source_key_fragment_1"
key_item.drop_chance = 100.0
key_item.quantity_min = 1
key_item.quantity_max = 1
boss_loot.entries.append(key_item)
loot_table = boss_loot
```

---

### I-7: Use `attack_weights` for adaptive difficulty — adjust based on player behavior

The weighted attack system exists but is static. Track which attacks the player dodges/gets hit by and adjust weights:
```gdscript
# After a successful hit:
attack_weights[current_attack] = minf(attack_weights[current_attack] + 0.2, 3.0)
# After player dodges:
attack_weights[current_attack] = maxf(attack_weights[current_attack] - 0.1, 0.5)
```

---

### I-8: Add enemy spawn VFX/animation — enemies currently pop into existence

No spawn-in effect. Add a materialization tween:
```gdscript
func spawn_in() -> void:
    modulate.a = 0.0
    scale = Vector2(0.3, 0.3)
    var tw = create_tween()
    tw.tween_property(self, "modulate:a", 1.0, 0.3)
    tw.parallel().tween_property(self, "scale", Vector2(1.0, 1.0), 0.3).set_trans(Tween.TRANS_BACK)
```

---

### I-9: `retreat_after_attack` is a dead feature — implement it for ranged enemies

DataSprite already has evasion logic, but the base class's `retreat_after_attack` pattern is never used. Enable it for enemies like CorruptedGuard (back off after counter-attack) to create tactical spacing.

---

### I-10: Add a `BossBase` class to reduce boss boilerplate

All 4 boss scripts duplicate: intro cutscene code, `_safe()`, `_has_gm()`, `_deal_melee()`, phase transition scaffolding. Extract to a shared `BossBase` class:
```
EnemyBase ← BossBase ← TutorialKnightBossEnemy
                      ← ClockworkAutomatonBoss
                      ← DataWraithBoss
                      ← AdministratorProxyBoss
```

---

### I-11: Add DDA integration to boss phase thresholds

Boss HP thresholds are hardcoded percentages. With DDA, struggling players could get earlier phase transitions (more dramatic, shorter fight) while skilled players face longer phases:
```gdscript
var dda = GameManager.get_difficulty_multiplier()
var adjusted_threshold = PHASE_2_HP_PCT + (1.0 - dda) * 0.1  # Easier = earlier transition
```

---

### I-12: Object pooling for projectiles

Every projectile creates new nodes (`Area2D`, `CollisionShape2D`, `ColorRect`) and `queue_free`s them. An `ObjectPool` script already exists at `scripts/object_pool.gd` but isn't used by any combat code. Integrate it for gear, tendril, and bolt projectiles.

---

### I-13: Add arena-specific enemy modifiers

The arena tier system spawns enemies from a list but doesn't apply tier-specific buffs. Add modifiers:
```gdscript
# In arena_manager.gd when spawning:
match current_tier:
    "silver":
        enemy.max_health *= 1.2
        enemy.contact_damage *= 1.1
    "gold":
        enemy.max_health *= 1.5
        enemy.movement_speed *= 1.15
    "platinum":
        enemy.max_health *= 2.0
        enemy.max_combo = 2
```

---

### I-14: DropManager should remove pickups from `_active_pickups` when collected

Currently, collected pickups stay in `_active_pickups` until `_process` catches `is_instance_valid == false`. Explicitly erase them in `_on_pickup_touched` and `_on_gold_touched`:
```gdscript
_active_pickups.erase(pickup)
```

---

## Files Audited

| File | Lines | Status |
|------|-------|--------|
| `scripts/combat/enemy_base.gd` | 1230 | 5 Critical, 4 High, 6 Medium |
| `scripts/combat/enemies/slime.gd` | 95 | M-3 |
| `scripts/combat/enemies/corrupted_rat.gd` | 103 | H-5, M-3 |
| `scripts/combat/enemies/glitch_wolf.gd` | 131 | C-4, M-3 |
| `scripts/combat/enemies/corrupted_guard.gd` | 128 | M-3, M-10 |
| `scripts/combat/enemies/data_sprite.gd` | 172 | C-3, M-3 |
| `scripts/combat/enemies/shadow_wraith.gd` | 134 | H-1, M-3, M-9 |
| `scripts/combat/enemies/clockwork_soldier.gd` | 130 | M-3 |
| `scripts/combat/enemies/administrator_enforcer.gd` | 80 | L-1, M-3 |
| `scripts/combat/enemies/tutorial_knight_boss_enemy.gd` | 703 | C-5, L-5, L-7 |
| `scripts/combat/enemies/clockwork_automaton_boss.gd` | 485 | C-5, H-7, M-11, L-3 |
| `scripts/combat/enemies/data_wraith_boss.gd` | 253 | C-5, L-3 |
| `scripts/combat/enemies/administrator_proxy_boss.gd` | 410 | C-5, M-12, L-3 |
| `scripts/drop_manager.gd` | 581 | H-4, H-9, M-6 |
| `scripts/game_manager.gd` (DDA section) | ~60 | DDA logic sound |

---

## Enemy Variety Assessment

| Enemy | Tier | Unique Mechanic | Variety Rating |
|-------|------|-----------------|----------------|
| Slime | Tutorial | Hop movement | ★★☆☆☆ — Very basic |
| Corrupted Rat | Bronze | Lunge attack | ★★☆☆☆ — Simple rush |
| Glitch Wolf | Bronze | Teleport + pounce | ★★★☆☆ — Good repositioning |
| Corrupted Guard | Silver | Block/counter cycle | ★★★★☆ — Forces timing |
| Data Sprite | Silver | Ranged + evasion | ★★★★☆ — Unique flying ranged |
| Shadow Wraith | Gold | Phase invulnerability | ★★★★☆ — Strategic timing |
| Clockwork Soldier | Gold | Ground slam + shockwave | ★★★☆☆ — Tanky but predictable |
| Admin Enforcer | Special | Teleport chase | ★★★☆☆ — Threatening but simple AI |
| Tutorial Knight | Boss | 4 phases + Root Access | ★★★★★ — Excellent design |
| Clockwork Automaton | Boss | 3 phases + core exposure | ★★★★☆ — Good gimmick |
| Data Wraith | Mini-boss | Corruption fields + tendrils | ★★★★☆ — Good area denial |
| Admin Proxy | Boss | Admin commands + /delete | ★★★★★ — Very thematic |

**Overall variety is GOOD** — each tier introduces mechanically distinct enemies. Main gaps:
- No aerial-only enemy that challenges platforming
- No enemy that spawns minions
- No enemy vulnerable to specific attack types (e.g., only hackable, not fightable)
- Missing a "shield enemy" that must be attacked from behind

---

*End of audit report.*
