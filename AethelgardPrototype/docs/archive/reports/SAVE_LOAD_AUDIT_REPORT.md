# Save/Load System Audit Report
**Date:** 2026-03-01  
**Project:** AethelgardPrototype (Godot 4.6 GDScript)  
**Audited Files:**
- `scripts/game_manager.gd` — Core save/load, game state
- `scripts/ui/pause_screen.gd` — Pause UI (no save/load triggers)
- `scripts/effects/scene_transition_manager.gd` — Scene management during load
- `scripts/inventory_system.gd` — Inventory serialization
- `scripts/choice_consequences.gd` — Choice buff/party persistence
- `scripts/ui/achievements.gd` — Achievement persistence
- `scripts/shop_system.gd` — Shop state
- `scripts/music_manager.gd` — Settings persistence
- `scripts/main_menu.gd` — Save/load UI
- `scripts/game_over.gd` — Load on death

---

## System Overview

| Feature | Status | Details |
|---------|--------|---------|
| **Format** | JSON (human-readable) | `JSON.stringify(data, "\t")` — tab-indented, debug-friendly |
| **Save Slots** | 4 total | Slots 0, 1, 2 (manual) + Slot 99 (autosave) |
| **Auto-save** | Yes | On boss defeat, chapter transitions, cutscene end |
| **Settings** | Separate | `user://audio_settings.cfg` via ConfigFile (music + SFX volume) |
| **Save Path** | `user://save_slot_N.save` | Standard Godot user:// directory |
| **Version** | `1.2.0` (bumped) | Was `1.1.0`, now with migration support |

---

## Issues Found & Resolution

### CRITICAL — APPLIED

#### C1: ChoiceConsequences Not Saved or Restored on Load
**Severity:** CRITICAL  
**File:** `scripts/game_manager.gd` (save_game/load_game)  
**Problem:** `ChoiceConsequences` has `get_save_data()`/`load_save_data()` methods but **GameManager never called them**. On load:
- `story_flags` were set via direct assign (not `set_story_flag()`), so `story_flag_updated` never fired
- `active_buffs` array was empty — all `has_ability()` checks failed
- `party_combat_members` was empty — Elara/Seraphina/Lyra combat assists stopped
- All choice-based abilities (Glitch Shield, Death Strike, Wraith Dash, etc.) were lost

**Fix Applied:**
- `save_game()`: Now saves `choice_consequences` data via `ChoiceConsequences.get_save_data()`
- `load_game()`: Now restores via `ChoiceConsequences.load_save_data()` with full validation
- Added `rebuild_from_flags()` fallback for older saves without CC data
- `load_save_data()` in choice_consequences.gd now validates input types (Array/Dictionary guard)

#### C2: No Save Version Validation on Load
**Severity:** CRITICAL  
**File:** `scripts/game_manager.gd` (load_game)  
**Problem:** `SAVE_VERSION` was written into saves but **never checked on load**. Any format change between updates silently loaded stale/incompatible data.

**Fix Applied:**
- Added `COMPATIBLE_SAVE_VERSIONS` constant listing accepted versions
- `load_game()` now checks version and calls `_migrate_save_data()` for upgrades
- Incompatible versions produce a clear error and abort load
- Added full migration chain: `1.0.0` → `1.1.0` → `1.2.0`

#### C3: Save During Combat/Cutscene/Transition Not Guarded
**Severity:** CRITICAL  
**File:** `scripts/game_manager.gd` (save_game, auto_save)  
**Problem:** Manual and auto saves could fire during:
- Active combat (enemies mid-attack, HP states in flux)
- Cutscenes (scene may not be stable)
- Scene transitions (`current_scene` could be stale/null)
- Game Over state

**Fix Applied:**
- `save_game()`: Manual saves (non-autosave) now blocked during `COMBAT`, `CUTSCENE`, `GAME_OVER`
- `save_game()`: ALL saves blocked during `SceneTransitions.is_transitioning`
- `auto_save()`: Now skips during `GAME_OVER`, `MENU`, and active scene transitions

---

### HIGH — APPLIED

#### H1: No Backup Saves Before Overwrite
**Severity:** HIGH  
**File:** `scripts/game_manager.gd` (save_game)  
**Problem:** Overwriting a save with no backup. If the write fails mid-operation (crash, disk full), both old and new saves are lost.

**Fix Applied:**
- Added `_backup_save_file()` — creates `.bak` copy before every write
- Backup is a full copy of the previous JSON file

#### H2: No Corrupted Save Recovery
**Severity:** HIGH  
**File:** `scripts/game_manager.gd` (load_game)  
**Problem:** If JSON parse fails, load just returned `false` with no recovery attempt.

**Fix Applied:**
- Added `_try_load_backup()` — on parse failure, attempts to restore from `.bak` file
- Validates backup is also valid JSON before restoring
- If backup is also corrupt, returns clear error
- On successful backup restore, retries the load automatically

#### H3: Save Data Integrity — Required Keys Validation
**Severity:** HIGH  
**File:** `scripts/game_manager.gd` (load_game)  
**Problem:** No validation that the loaded JSON actually contained expected fields. A manually edited or truncated save could load partial/garbage state.

**Fix Applied:**
- Added `REQUIRED_SAVE_KEYS` constant: `["version", "player_stats", "story_flags", "current_chapter"]`
- `load_game()` now validates all required keys exist before proceeding
- Added checksum field (`_checksum`) written to save for future integrity verification

#### H4: DDA Float Type Mismatch on Load
**Severity:** HIGH  
**File:** `scripts/game_manager.gd` (load_game, line ~770)  
**Problem:** `_dda_recent_deaths` is a `float` at runtime (incremented by 0.3 per hit taken), but the load default was `0` (integer). JSON deserialization may also return `int` for whole numbers, causing type mismatch in subsequent float arithmetic.

**Fix Applied:**
- All numeric loads now use explicit `float()` or `int()` casts
- Default for `_dda_recent_deaths` changed from `0` to `0.0`

#### H5: Inventory Load Not Validated
**Severity:** HIGH  
**File:** `scripts/game_manager.gd` (load_game)  
**Problem:** `Inventory.items` was directly assigned from save data without any validation. Could inject items with non-string IDs, non-integer quantities, or items that don't exist in the ITEMS database.

**Fix Applied:**
- Inventory items now validated per-entry: key must be `String`, value must be numeric
- Invalid entries are skipped with a warning
- Equipment slots validated against expected keys (`weapon`, `armor`, `accessory`)
- Equipment values validated as non-empty strings

#### H6: Boss Fight State Not Reset on Load
**Severity:** HIGH  
**File:** `scripts/game_manager.gd` (load_game)  
**Problem:** `boss_fight_active` and `boss_fight_hits_taken` were not reset on load. If saved during exploration after a boss fight, these could be stale `true`, causing the next boss to incorrectly register as "flawless" or ignore hit tracking.

**Fix Applied:**
- Load now explicitly resets `boss_fight_active = false` and `boss_fight_hits_taken = 0`

#### H7: Loaded Game State Could Be Unsafe
**Severity:** HIGH  
**File:** `scripts/game_manager.gd` (load_game)  
**Problem:** Only `MENU` state was remapped to `EXPLORATION` on load. If the save captured `COMBAT`, `CUTSCENE`, or `GAME_OVER` state, the game would restore to those states with no active enemies/cutscene.

**Fix Applied:**
- `COMBAT`, `CUTSCENE`, `GAME_OVER`, and `MENU` states all remap to `EXPLORATION` on load

---

### MEDIUM — Documented (Not Applied)

#### M1: No Explored Areas / Map State Saved
**Impact:** Map reveal progress is lost on load. Player re-enters fog-of-war areas.  
**Location:** `scripts/game_manager.gd` — no `explored_areas` field exists  
**Recommendation:** Add `var explored_areas: Dictionary = {}` tracking visited scene paths. Save/restore alongside story_flags.

#### M2: Shop Purchase History Not Tracked
**Impact:** Currently shops have unlimited stock, so no data loss. But if limited-stock items are added later, purchase history would be lost.  
**Location:** `scripts/shop_system.gd` — no save/load methods exist  
**Recommendation:** Add `get_save_data()`/`load_save_data()` to ShopSystem for purchased counts per shop.

#### M3: No Save During Pause Screen
**Impact:** Players can only save from the main menu or rely on autosave. No manual save button in the pause screen.  
**Location:** `scripts/ui/pause_screen.gd` — no save buttons in any tab  
**Recommendation:** Add a "Save Game" button to the pause UI footer, opening a slot picker that calls `GameManager.save_game(slot)`.

#### M4: Autosave Frequency Could Be Higher  
**Impact:** Autosave only triggers on boss defeat and chapter transitions. Long exploration sessions between bosses have no checkpoints.  
**Location:** Various chapter scripts call `GameManager.auto_save()`  
**Recommendation:** Add periodic autosave (every 5-10 minutes of playtime) in `_process()` or on room/area transitions.

#### M5: `get_save_info()` Doesn't Show ChoiceConsequences Summary
**Impact:** Load screen shows level/HP/corruption but not active choice effects. Players may not remember which choices they made in each slot.  
**Location:** `scripts/game_manager.gd` → `get_save_info()`  
**Recommendation:** Add party members and active buff count to the info dictionary.

---

### LOW — Documented (Not Applied)

#### L1: Save File Not Compressed
**Impact:** JSON with tab indentation produces ~15-30KB files. Acceptable for debugging but larger than needed.  
**Recommendation:** For release builds, consider removing indentation (`JSON.stringify(data)` without `"\t"`) or using binary serialization.

#### L2: No Save File Size Limit
**Impact:** Theoretically unbounded if story_flags or inventory grow extremely large.  
**Recommendation:** Add a check after stringify: `if json_string.length() > 1_000_000: push_error("Save too large")`

#### L3: No Delete Confirmation Dialog
**Impact:** Main menu delete button immediately erases saves with no "Are you sure?" prompt.  
**Location:** `scripts/main_menu.gd` → `_do_delete_save()`  
**Recommendation:** Add a confirmation dialog before calling `GameManager.delete_save()`.

#### L4: Inventory `_ready()` Adds Start Items Unconditionally
**Impact:** `inventory_system.gd` adds 3 health potions + 2 glitch stabilizers if `items.is_empty()`. After loading a save where all items were consumed, inventory appears empty, so start items re-add.  
**Location:** `scripts/inventory_system.gd` → `_ready()`  
**Recommendation:** Add a flag `var _initialized: bool = false` set after load to skip `_ready()` item grants.

---

## Data Completeness Checklist

| Data Category | Saved? | Notes |
|--------------|--------|-------|
| Player Stats (HP, MP, ATK, DEF, etc.) | ✅ | Full `player_stats` dictionary |
| Inventory items | ✅ | `inventory_items` + `inventory_gold` |
| Equipment loadout | ✅ | `inventory_equipment` (weapon/armor/accessory) |
| Story flags | ✅ | Full `story_flags` dictionary with safe merge |
| Relationships | ✅ | Full `relationships` dictionary |
| Achievements | ✅ | Via `Achievements.get_save_data()` |
| Choice consequences / buffs | ✅ **FIXED** | Was missing — now saved via `ChoiceConsequences.get_save_data()` |
| Party combat members | ✅ **FIXED** | Was missing — now saved with choice_consequences |
| Charm loadout | ✅ | `unlocked_charms` + `equipped_charms` |
| Gold | ✅ | In both `player_stats.gold` and `inventory_gold` |
| Corruption / Glitch meter | ✅ | `glitch_meter` + `corruption_level` |
| Arena stats | ✅ | Full `arena_stats` dictionary |
| Session stats | ✅ | Full `stats` dictionary (kills, deaths, combos, etc.) |
| DDA performance | ✅ **FIXED** | Was saving but with int/float type mismatch |
| Perfect Delete state | ✅ | `perfect_delete_charges` + `perfect_delete_used` |
| Player position | ✅ | Saved and restored with 2-frame wait |
| Current scene | ✅ | Scene path with `ResourceLoader.exists()` check |
| Playtime | ✅ | `playtime_seconds` |
| Speedrun timer | ✅ | Via `stats.speedrun_seconds` + `speedrun_active` flag |
| Explored areas / map reveals | ❌ | Not tracked — no `explored_areas` variable exists |
| Enemy states (respawn) | ❌ | Not tracked — enemies respawn on scene reload |
| Shop purchase history | ❌ | Not tracked — shops have unlimited stock currently |
| Audio settings | ✅ (separate) | `user://audio_settings.cfg` via `MusicManager` |

---

## Architecture Summary

```
┌─────────────────────────────────────────────────────────────┐
│                    SAVE FILE STRUCTURE                        │
│                   user://save_slot_N.save                    │
├─────────────────────────────────────────────────────────────┤
│  version: "1.2.0"                                           │
│  timestamp: "2026-03-01T12:00:00"                           │
│  _checksum: <int hash>                                      │
│  ┌─ player_stats: {hp, max_hp, mp, attack, defense, ...}   │
│  ├─ relationships: {elara: N, seraphina: N, ...}            │
│  ├─ story_flags: {ch1_complete: bool, ...}                  │
│  ├─ arena_stats: {total_wins, current_tier, ...}            │
│  ├─ stats: {death_count, enemies_killed, ...}               │
│  ├─ inventory_items: {item_id: qty, ...}                    │
│  ├─ inventory_equipment: {weapon, armor, accessory}         │
│  ├─ achievements: {id: timestamp, ...}                      │
│  ├─ choice_consequences: {active_buffs, party_members}  NEW │
│  ├─ unlocked_charms: {charm_id: true, ...}                  │
│  ├─ equipped_charms: [charm_id, ...]                        │
│  ├─ player_position: {x, y}                                 │
│  ├─ dda_*: performance_score, recent_deaths, recent_kills   │
│  └─ scalar fields: glitch_meter, corruption_level, etc.     │
└─────────────────────────────────────────────────────────────┘

┌───────────────────────┐     ┌─────────────────────────┐
│  user://audio_settings│     │  user://save_slot_N     │
│        .cfg           │     │       .save.bak     NEW │
│  (ConfigFile format)  │     │  (backup before write)  │
│  music_volume: 0.7    │     │                         │
│  sfx_volume: 0.8      │     │                         │
└───────────────────────┘     └─────────────────────────┘
```

### Save Flow
```
save_game(slot)
  ├─ Guard: block manual save in COMBAT/CUTSCENE/GAME_OVER     NEW
  ├─ Guard: block ALL saves during scene transition             NEW
  ├─ Collect all state into save_data dictionary
  ├─ Include ChoiceConsequences.get_save_data()                 NEW
  ├─ _backup_save_file() — create .bak copy                    NEW
  ├─ Add _checksum field                                        NEW
  └─ JSON.stringify → FileAccess.WRITE
```

### Load Flow
```
load_game(slot)
  ├─ Guard: _load_in_progress flag
  ├─ Parse JSON (on failure → _try_load_backup)                NEW
  ├─ Validate REQUIRED_SAVE_KEYS present                       NEW
  ├─ Version check → _migrate_save_data() if needed            NEW
  ├─ Restore state with safe _merge_dict + type casts          IMPROVED
  ├─ Reset boss_fight_active                                   NEW
  ├─ Validate inventory entries                                NEW
  ├─ Restore ChoiceConsequences (or rebuild_from_flags)        NEW
  ├─ Apply corruption effects + emit signals
  ├─ Change scene + restore player position
  └─ Force safe GameState (no COMBAT/CUTSCENE/GAME_OVER)       NEW
```

---

## Files Modified

1. **`scripts/game_manager.gd`** — 6 fixes applied:
   - Save version bumped to `1.2.0`; added `REQUIRED_SAVE_KEYS`, `COMPATIBLE_SAVE_VERSIONS`
   - `save_game()` — state guards, backup, ChoiceConsequences save, checksum
   - `load_game()` — version check, key validation, backup recovery, type casts, inventory validation, CC restore, boss reset, safe state remap
   - `auto_save()` — state/transition guards
   - Added `_backup_save_file()`, `_try_load_backup()`, `_migrate_save_data()`

2. **`scripts/choice_consequences.gd`** — 2 fixes applied:
   - `load_save_data()` — rewritten with full type validation
   - Added `rebuild_from_flags()` — fallback reconstruction from story flags

---

*All CRITICAL and HIGH priority fixes have been applied. Zero compile errors.*
