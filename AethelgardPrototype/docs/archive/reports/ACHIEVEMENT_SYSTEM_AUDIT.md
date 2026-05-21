# Achievement System Audit Report

**Project:** AethelgardPrototype (Godot 4.6 GDScript)  
**Date:** 2026-03-01  
**Files Audited:**
- `scripts/ui/achievements.gd` — Core achievement system (Autoload)
- `scripts/game_manager.gd` — Achievement triggers, save/load, boss tracking
- `scripts/combat/player_combat.gd` — Combat achievement triggers
- `scripts/combat/enemy_base.gd` — Kill/boss death rewards
- `scripts/exploration/oakhaven.gd` — Exploration scene
- `scripts/combat/arena_manager.gd` — Arena tier completion
- `scripts/side_quest_manager.gd` — Quest completions
- `scripts/shop_system.gd` — Shop visit trigger
- `scripts/chapter1/ch1_shatter_transition.gd` — Speedrun trigger
- `scripts/chapter1/ch1_tutorial_knight.gd` — Boss fight tracking
- `scripts/chapter2/ch2_administrator_boss.gd` — Boss fight tracking
- `scripts/effects/game_juice.gd` — Combo signal, achievement VFX

---

## Summary

| Severity | Found | Fixed |
|----------|-------|-------|
| CRITICAL | 2     | 2     |
| HIGH     | 5     | 5     |
| MEDIUM   | 3     | 2     |
| LOW      | 2     | 0     |
| **Total** | **12** | **9** |

**Achievement count:** 27 → **38** (11 new achievements added)

---

## CRITICAL Bugs — FIXED

### C1. Speedrun achievement ALWAYS unlocks trivially
**File:** `scripts/chapter1/ch1_shatter_transition.gd` line 494–498  
**Severity:** CRITICAL

`speedrun_active` is **never set to true** anywhere in the codebase. The `_process` timer in `game_manager.gd` only ticks `speedrun_seconds` when `speedrun_active == true`, so `speedrun_seconds` stays at `0.0` forever. The check `0.0 <= 1800` always passes, giving **every player** the speedrun achievement upon completing Chapter 1.

**Before:**
```gdscript
var speedrun_secs = GameManager.stats.get("speedrun_seconds", 999999)
if speedrun_secs <= 1800:
    Achievements.try_unlock("speedrun_30")
```

**Fix applied:** Use `playtime_seconds` (which always ticks correctly) and add a `> 0.0` guard:
```gdscript
var elapsed_secs = GameManager.playtime_seconds
if elapsed_secs > 0.0 and elapsed_secs <= 1800:
    Achievements.try_unlock("speedrun_30")
```

---

### C2. Achievements NOT persisted independently — lost on crash/new-game/save-delete
**File:** `scripts/ui/achievements.gd` (entire persistence model)  
**Severity:** CRITICAL

Achievements were stored **only inside game save slots** (`save_data["achievements"]`). This means:
1. Crash/quit without saving → all achievements lost
2. Loading an older save → achievements **revert to that save's state**  
3. Deleting a save file → achievements erased  
4. Starting a new game → achievements reset until a save is loaded
5. Multiple save slots → achievements tied to whichever slot was loaded last

**Fix applied:** Added independent `user://achievements.save` file:
- `_save_to_disk()` — writes to own file immediately on every unlock
- `_load_from_disk()` — loads on startup before any game save
- `load_save_data()` now **merges** (union) save-slot data with disk data — never loses progress
- Old game-save integration still works; data flows both directions

---

## HIGH Bugs — FIXED

### H1. Private API bypass: `_try_unlock` called directly
**File:** `scripts/combat/player_combat.gd` line 926  
**Severity:** HIGH

Player combat called the private `Achievements._try_unlock("pogo_kill")` instead of the public `Achievements.try_unlock()`. If `try_unlock` is extended with validation/hooks, pogo_kill would bypass them.

**Fix applied:** Changed to `Achievements.try_unlock("pogo_kill")`.

---

### H2. `bosses_killed` stat never incremented
**File:** `scripts/game_manager.gd` — `end_boss_fight()`  
**Severity:** HIGH

The stat `bosses_killed` exists in `DEFAULT_SESSION_STATS` but was never incremented anywhere. Boss kills are tracked for flawless-victory detection but the counter itself was dead.

**Fix applied:** Added to `end_boss_fight()`:
```gdscript
stats["bosses_killed"] = stats.get("bosses_killed", 0) + 1
```

---

### H3. GameJuice achievement VFX never triggered
**File:** `scripts/ui/achievements.gd` — `_try_unlock()`  
**Severity:** HIGH

`game_juice.gd` has `on_achievement_unlocked(achievement_name)` that spawns a golden announcement VFX, but it was **never called**. The popup animated and SFX played, but no in-world visual celebration occurred.

**Fix applied:** Added to `_try_unlock()`:
```gdscript
if has_node("/root/GameJuice"):
    GameJuice.on_achievement_unlocked(data.get("name", id))
```

---

### H4. No arena achievements connected to achievement system
**File:** `scripts/combat/arena_manager.gd`, `scripts/ui/achievements.gd`  
**Severity:** HIGH

Arena manager set story flags (`ch2_arena_bronze_complete`, etc.) but no achievements existed for arena tiers, and the achievement system didn't check those flags.

**Fix applied:** Added 5 arena achievements:
- `arena_bronze` — Complete Bronze tier
- `arena_silver` — Complete Silver tier
- `arena_gold` — Complete Gold tier
- `arena_platinum` — Complete Platinum tier
- `arena_streak_5` — Win 5 arena matches in a row

Added flag checks in `_check_stat_achievements()`.

---

### H5. Side quest completion not tracked by achievement system
**File:** `scripts/side_quest_manager.gd`, `scripts/ui/achievements.gd`  
**Severity:** HIGH

`SideQuestManager` emits `quest_completed(quest_id)` signal, but nothing in the achievement system listens for it. No quest-related achievements existed.

**Fix applied:**
- Added 3 quest achievements: `first_quest`, `all_quests`, `all_secrets`
- Connected `SideQuestManager.quest_completed` signal in `_ready()`
- Added `_on_quest_completed()` handler
- Added periodic checks for all-quests and all-secrets in `_check_stat_achievements()`

---

## MEDIUM Bugs — FIXED

### M1. `_process` polling instead of Timer for stat checks
**File:** `scripts/ui/achievements.gd`  
**Severity:** MEDIUM

`_check_stat_achievements()` was called every `_process` frame with a manual cooldown check. This wasted CPU on 59/60 frames doing nothing.

**Fix applied:** Replaced with a `Timer` node (1s interval), removed `_process` override entirely.

---

### M2. Missing standard Hollow Knight-style achievements
**File:** `scripts/ui/achievements.gd`  
**Severity:** MEDIUM

The original 27 achievements had no coverage for:
- Arena tiers
- Quest completion
- All bosses defeated
- All areas visited
- 100% completion

**Fix applied:** Added 11 new achievements:

| ID | Name | Category |
|----|------|----------|
| `all_bosses` | Boss Slayer | combat |
| `all_areas` | World Walker | explore |
| `arena_bronze` | Pit Fighter | arena |
| `arena_silver` | Silver Warrior | arena |
| `arena_gold` | Gold Champion | arena |
| `arena_platinum` | Platinum Legend | arena |
| `arena_streak_5` | On Fire | arena |
| `first_quest` | Side Tracked | quest |
| `all_quests` | Completionist | quest |
| `all_secrets` | Code Archaeologist | quest |
| `completion_100` | True Architect | meta |

---

## MEDIUM Bugs — NOT FIXED (documented for future)

### M3. Duplicate highest_combo tracking
**Files:** `player_combat.gd` line 677, `achievements.gd` (removed in new version)

Both `player_combat._perform_combo_attack()` and the old `_on_combo_updated()` wrote to `GameManager.stats["highest_combo"]` from different sources (`total_combo_hits` vs GameJuice `_combo_count`). The new achievements.gd no longer duplicates this — player_combat.gd is the single source of truth.

**Status:** Fixed as side-effect of achievements.gd rewrite.

---

## LOW Bugs — NOT FIXED (cosmetic)

### L1. Emoji icons may not render on all platforms
**File:** `scripts/ui/achievements.gd`  
**Severity:** LOW

Achievement icons use emoji characters (⚔️, 🔥, etc.). These may not render correctly with all font configurations in Godot. Consider adding a fallback text icon field or using `TextureRect` with actual icon assets.

### L2. No "no death" run achievement
**Severity:** LOW  

Standard Hollow Knight-style "Steel Soul" (complete game without dying) achievement is missing. Would require tracking `death_count == 0` at chapter completion.

---

## Achievement Trigger Coverage (Complete Map)

### Triggered by periodic stat polling (Timer — every 1s):
| Achievement | Condition | Working? |
|-------------|-----------|----------|
| `first_blood` | enemies_killed ≥ 1 | ✅ |
| `kill_50` | enemies_killed ≥ 50 | ✅ |
| `kill_100` | enemies_killed ≥ 100 | ✅ |
| `die_5` | death_count ≥ 5 | ✅ |
| `die_20` | death_count ≥ 20 | ✅ |
| `perfect_parry` | parries_landed ≥ 1 | ✅ |
| `ten_parries` | parries_landed ≥ 10 | ✅ |
| `first_hack` | hacks_used ≥ 1 | ✅ |
| `corruption_50` | glitch_meter ≥ 50 | ✅ |
| `corruption_75` | glitch_meter ≥ 75 | ✅ |
| `level_10` | level ≥ 10 | ✅ |
| `rich` | gold ≥ 1000 | ✅ |
| `prologue_complete` | story flag | ✅ |
| `ch1_complete` | story flag | ✅ |
| `ch2_complete` | story flag | ✅ |
| `ch3_complete` | story flag | ✅ |
| `root_access` | story flag | ✅ |
| `fragment_1` | source_key_count ≥ 1 | ✅ |
| `fragment_4` | source_key_count ≥ 4 | ✅ |
| `charm_3` | equipped_charms.size() ≥ 3 | ✅ |
| `full_party` | 3 party members recruited | ✅ |
| `arena_bronze` | story flag | ✅ NEW |
| `arena_silver` | story flag | ✅ NEW |
| `arena_gold` | story flag | ✅ NEW |
| `arena_platinum` | story flag | ✅ NEW |
| `arena_streak_5` | best_streak ≥ 5 | ✅ NEW |
| `all_areas` | all 3 areas visited | ✅ NEW |
| `all_bosses` | 4 boss flags cleared | ✅ NEW |
| `completion_100` | completion % = 100 | ✅ NEW |
| `all_secrets` | all secrets found | ✅ NEW |
| `all_quests` | all quests complete | ✅ NEW |

### Triggered by signals/events:
| Achievement | Trigger Source | Working? |
|-------------|---------------|----------|
| `combo_5` | GameJuice.combo_updated signal | ✅ |
| `combo_15` | GameJuice.combo_updated signal | ✅ |
| `pogo_kill` | player_combat.gd _execute_pogo() | ✅ FIXED |
| `no_damage_boss` | game_manager.gd end_boss_fight() | ✅ |
| `first_shop` | shop_system.gd open_shop() | ✅ |
| `speedrun_30` | ch1_shatter_transition.gd | ✅ FIXED |
| `first_quest` | SideQuestManager.quest_completed signal | ✅ NEW |

### Dead achievements: **NONE** — all 38 achievements are reachable.

---

## Edge Case Analysis

| Edge Case | Status |
|-----------|--------|
| Double-unlock prevention | ✅ `if id in unlocked: return` guard |
| Progress going backwards | ✅ N/A — stat-based; stats only increment |
| Race conditions (rapid unlocks) | ✅ Queue-based popup system; `_popup_active` flag |
| Crash during unlock | ✅ FIXED — `_save_to_disk()` called immediately on unlock |
| Save slot interference | ✅ FIXED — `load_save_data()` now merges (union) instead of overwriting |
| Game reset clears achievements | ✅ By design — `reset_game()` doesn't touch Achievements singleton; disk persistence survives |

---

## Persistence Architecture (After Fix)

```
┌─────────────────────────────────┐
│   user://achievements.save      │  ← Independent file, written on every unlock
│   (survives across all saves)   │
└────────────┬────────────────────┘
             │ _load_from_disk() on startup
             │ _save_to_disk() on every unlock
             ▼
┌─────────────────────────────────┐
│   Achievements singleton (RAM)  │ ← Source of truth at runtime
│   unlocked: Dictionary          │
└────────────┬────────────────────┘
             │ get_save_data() / load_save_data()
             │ (bidirectional merge — union, never lose)
             ▼
┌─────────────────────────────────┐
│   user://save_slot_N.save       │  ← Game save slots (still include
│   save_data["achievements"]     │     achievements for convenience)
└─────────────────────────────────┘
```

---

## UI Notification System

| Feature | Status |
|---------|--------|
| Toast popup | ✅ Animated PanelContainer slides in from top |
| Sound effect | ✅ `SFXManager.play("powerup")` on unlock |
| In-world VFX | ✅ FIXED — `GameJuice.on_achievement_unlocked()` now called |
| Queue system | ✅ Multiple unlocks queue and show sequentially |
| Works while paused | ✅ `process_mode = PROCESS_MODE_ALWAYS` |

---

## Files Modified

1. **`scripts/ui/achievements.gd`** — Complete overhaul: independent persistence, 11 new achievements, Timer-based polling, GameJuice integration, quest/arena/boss tracking, merged save/load
2. **`scripts/game_manager.gd`** — `end_boss_fight()` now increments `bosses_killed` stat
3. **`scripts/combat/player_combat.gd`** — Fixed `_try_unlock` → `try_unlock` API call
4. **`scripts/chapter1/ch1_shatter_transition.gd`** — Fixed speedrun check to use `playtime_seconds` instead of dead `speedrun_seconds`
