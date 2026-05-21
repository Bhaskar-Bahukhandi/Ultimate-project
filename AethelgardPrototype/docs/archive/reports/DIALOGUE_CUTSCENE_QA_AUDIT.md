# Dialogue & Cutscene System — QA Audit Report

**Project:** AethelgardPrototype (Godot 4.6 GDScript)  
**Scope:** DialogueManager, CutsceneManager, CutsceneDirector, ChoiceConsequences, NPC dialogue scenes, cutscene scripts  
**Files Analyzed:** 15+ source files (~10,000+ lines)  
**Bugs Found:** 13 (1 CRITICAL, 4 HIGH, 3 MEDIUM, 5 LOW)  
**Bugs Fixed Inline:** 9 of 13 (all CRITICAL/HIGH/MEDIUM)

---

## Summary Table

| # | Severity | File | Bug | Status |
|---|----------|------|-----|--------|
| 1 | **CRITICAL** | ch1_oakhaven_village.gd | Misplaced solo dialogue code in `_exit_tree` | ✅ FIXED |
| 2 | **HIGH** | dialogue_manager.gd | `dialogue_started`/`dialogue_finished` never emit in modern API | ✅ FIXED |
| 3 | **HIGH** | pause_screen.gd | ESC fires both dialogue skip AND pause menu | ✅ FIXED |
| 4 | **HIGH** | dialogue_manager.gd | Ghost input accepted during pause overlay | ✅ FIXED |
| 5 | **HIGH** | cutscene_manager.gd | `create_flash_effect` leaks ColorRect on root | ✅ FIXED |
| 6 | **MEDIUM** | ch1_oakhaven_village.gd | NPC dialogues don't set `GameState.DIALOGUE` | ✅ FIXED |
| 7 | **MEDIUM** | dialogue_manager.gd | `show_choices()` not recorded in `dialogue_history` | ✅ FIXED |
| 8 | **MEDIUM** | cutscene_director.gd | `cancel()` doesn't unblock player input; no `_exit_tree` | ✅ FIXED |
| 9 | **LOW** | choice_consequences.gd | Orphaned `wraith_power` in `ABILITY_DESCRIPTIONS` | ✅ FIXED |
| 10 | **LOW** | ch1_tutorial_knight.gd | Custom dialogue system bypasses DialogueManager | 📝 Documented |
| 11 | **LOW** | ch1_oakhaven_village.gd | NPC dialogues infinitely repeatable | 📝 Documented |
| 12 | **LOW** | Multiple files | `SceneTransitions.change_scene()` without `has_node` guard | 📝 Documented |
| 13 | **LOW** | cutscene_director.gd | `cancel()` can't interrupt non-dialogue commands mid-await | 📝 Documented |

---

## CRITICAL Bugs

### BUG #1 — `_exit_tree` Contains Misplaced Solo Dialogue (Code Merge Error)

**File:** `scripts/chapter1/ch1_oakhaven_village.gd`  
**Impact:** Solo players (no Elara) never see entrance dialogue. The `_exit_tree` method does an unsafe `await` on dialogue playback, causing undefined behavior when the node is being removed from the scene tree.

**Root Cause:** A code merge placed the `else` branch of `if has_elara:` inside `_exit_tree()`. The `else:` keyword became syntactically attached to the `if has_node("/root/GameManager")` check in `_exit_tree`, so:

1. If GameManager exists AND signal is connected → disconnect ✓
2. ELSE → attempt to play solo entrance dialogue during tree exit ✗

**Broken code:**
```gdscript
func _exit_tree() -> void:
    if has_node("/root/GameManager") and GameManager.glitch_meter_changed.is_connected(...):
        GameManager.glitch_meter_changed.disconnect(...)
        if not is_inside_tree(): return
    else:
        await _play_dialogue_array(village_entrance_solo_dialogue)  # ← WRONG
        if not is_inside_tree(): return
```

**Fix applied:** Moved the `else` branch back to `_ready()` where the `if has_elara:` check lives. Cleaned `_exit_tree` to only do signal disconnection.

---

## HIGH Bugs

### BUG #2 — `dialogue_started`/`dialogue_finished` Never Emit in Modern API

**File:** `scripts/dialogue_manager.gd`  
**Impact:** Any system listening for `dialogue_started` or `dialogue_finished` (achievements, analytics, state tracking) would never trigger when using the modern `say()`/`hide_dialogue()` API. Only the legacy `start_dialogue()`/`end_dialogue()` path emitted these signals.

**Root Cause:** The modern `say()` method sets `is_active = true` and shows the panel, but never emits `dialogue_started`. Similarly, `hide_dialogue()` sets `is_active = false` but never emitted `dialogue_finished`.

**Fix applied:**
- `say()`: Emit `dialogue_started` when panel first becomes visible
- `hide_dialogue()`: Emit `dialogue_finished` when `was_active` is true

---

### BUG #3 — ESC Key Fires Both Dialogue Skip AND Pause Menu

**File:** `scripts/ui/pause_screen.gd`  
**Impact:** Pressing ESC during active dialogue would both skip the dialogue line (DialogueManager._input) AND toggle the pause menu (PauseScreen._input). The player would see the pause screen open mid-conversation.

**Root Cause:** Both `DialogueManager` and `PauseScreen` have `process_mode = PROCESS_MODE_ALWAYS` and both handle the `ui_cancel` action in `_input()`. DialogueManager marks the input as handled (`set_input_as_handled()`), but PauseScreen's `_input` fires before DialogueManager's because PauseScreen is on CanvasLayer 110 (higher = processes input first in Godot).

**Fix applied:** Added an early-return guard in `PauseScreen._input()`:
```gdscript
if has_node("/root/DialogueManager") and DialogueManager.is_active:
    return
```

---

### BUG #4 — Ghost Input During Pause Overlay

**File:** `scripts/dialogue_manager.gd`  
**Impact:** While the pause menu is open, SPACE key presses pass through to DialogueManager's `_input()`, setting `_advance_requested = true`. When unpaused, dialogue auto-advances without player intent.

**Root Cause:** DialogueManager's `_input()` (process_mode ALWAYS) had no pause guard. The pause screen uses `get_tree().paused = true`, but DialogueManager continues processing input.

**Fix applied:** Added `if get_tree().paused: return` guard at the top of `_input()`.

---

### BUG #5 — `create_flash_effect` Leaks ColorRect on Scene Root

**File:** `scripts/cutscene/cutscene_manager.gd`  
**Impact:** The flash effect creates a `ColorRect` and adds it to `get_tree().root`. The cleanup callback checks `if not is_inside_tree(): return`, but since the rect is on root (which is always in tree), the guard passes. However, if the CutsceneManager itself exits the tree before the cleanup timer fires, the `is_inside_tree()` call is on the wrong node. The flash rect remains opaque on screen forever.

**Fix applied:** Changed cleanup to use `is_instance_valid(flash)` → `flash.queue_free()` which correctly targets the flash rect itself.

---

## MEDIUM Bugs

### BUG #6 — NPC Dialogues Don't Change GameManager State to DIALOGUE

**File:** `scripts/chapter1/ch1_oakhaven_village.gd`  
**Impact:** During NPC conversations via `_play_dialogue_array()`, `GameManager.current_state` remains `EXPLORATION`. While player movement is frozen (player_topdown checks `DialogueManager.is_active`), other systems gating only on `GameManager.current_state` may remain active.

**Root Cause:** `_play_dialogue_array()` only sets the local `in_dialogue` flag. No state machine transition occurs.

**Fix applied:** Added `GameManager.change_state(GameManager.GameState.DIALOGUE)` at the start and restore previous state at the end:
```gdscript
var prev_state = GameManager.current_state
GameManager.change_state(GameManager.GameState.DIALOGUE)
# ... dialogue playback ...
GameManager.change_state(prev_state)
```

---

### BUG #7 — `show_choices()` Not Recorded in Dialogue History

**File:** `scripts/dialogue_manager.gd`  
**Impact:** `say()` records every line to `dialogue_history`, but `show_choices()` records nothing. The choice prompt text and the player's selected option are lost. Any history replay feature (journal, log screen) would have gaps at every branching decision.

**Fix applied:** Added history entry after choice selection:
```gdscript
dialogue_history.append({
    "speaker": speaker,
    "text": prompt,
    "choice": choices[result],
    "choice_index": result,
    "timestamp": Time.get_ticks_msec()
})
```

---

### BUG #8 — CutsceneDirector `cancel()` Doesn't Unblock Input; No `_exit_tree` Safety

**File:** `scripts/cutscene/cutscene_director.gd`  
**Impact:** If external code calls `cancel()` then `queue_free()`, the `play()` coroutine is abandoned. The player character remains `PROCESS_MODE_DISABLED` permanently — the game becomes unplayable.

**Root Cause:** `cancel()` sets `_is_cancelled = true` but doesn't call `_unblock_input()`. It relies on `play()` reaching `_unblock_input()` after the loop breaks, but that never happens if the director is freed.

**Fix applied:**
1. Added `_unblock_input()` call at the end of `cancel()`
2. Added `_exit_tree()` as a safety net:
```gdscript
func _exit_tree() -> void:
    if _is_playing:
        _unblock_input()
    if _canvas_modulate and is_instance_valid(_canvas_modulate):
        _canvas_modulate.queue_free()
        _canvas_modulate = null
```

---

## LOW Bugs

### BUG #9 — Orphaned `wraith_power` Entry in `ABILITY_DESCRIPTIONS`

**File:** `scripts/choice_consequences.gd`  
**Impact:** Display-only. The `ABILITY_DESCRIPTIONS` dictionary is keyed by ability name (e.g., `wraith_dash`, `spectral_aid`). The entry `wraith_power` is a **buff ID** (not an ability), so `has_ability("wraith_power")` would never return true. Its description ("Spectral ally blocks 1 attack every 20s") is also wrong — that describes `spectral_aid`, not the wraith absorption ability.

**Fix applied:** Removed the stale `wraith_power` key. The correct entries (`wraith_dash` and `spectral_aid`) remain.

---

### BUG #10 — Tutorial Knight Uses Custom Dialogue System (Design Inconsistency)

**File:** `scripts/chapter1/ch1_tutorial_knight.gd` (~1218 lines)  
**Impact:** The tutorial knight fight scene implements its own complete dialogue system:
- `_dialogue_queue: Array` — private queue
- `_dialogue_active: bool` — private state
- `_update_dialogue()` — custom display logic
- `_on_dialogue_complete()` — custom callback

This bypasses DialogueManager entirely. Consequences:
- TAB-to-skip doesn't work (custom skip uses TAB but with different timing)
- Dialogue history is not recorded
- Speaker colors/portraits are handled differently
- ESC skip behavior is inconsistent

**Recommendation:** Refactor to use `DialogueManager.say()` in a future pass. This is a significant change and should be tested thoroughly.

---

### BUG #11 — Oakhaven NPC Dialogues Are Infinitely Repeatable

**File:** `scripts/chapter1/ch1_oakhaven_village.gd`  
**Impact:** Farmer Jenkins, Village Child, and Village Guard dialogue handlers have no one-shot flag. Every time the player re-enters the interaction area, the same conversation plays again. This may be intentional during development but feels immersion-breaking in a finished game.

**Recommendation:** Add flags like `_farmer_dialogue_done`, `_child_dialogue_done`, `_guard_dialogue_done` and set them after first playback. Optionally provide shortened repeat dialogue.

---

### BUG #12 — Some Cutscene Scripts Call `SceneTransitions` Without Guard

**Files affected:**
- `ch1_oakhaven_village.gd` (line 539)
- `ch1_shatter_transition.gd` (line 519)
- `ch1_elara_meeting.gd` (line 721)
- `ch2_ironhold_city.gd` (lines 605, 614, 622)
- `ch2_seraphina_choice.gd` (line 372)
- `ch1_tutorial_knight.gd` (line 138)

**Impact:** These call `SceneTransitions.change_scene()` without `if has_node("/root/SceneTransitions"):` guard. If the autoload is missing, these crash. However, SceneTransitions is a foundational autoload — if it's missing, every scene transition in the game is broken anyway.

**Recommendation:** Add guards for consistency with the rest of the codebase, but not urgent.

---

### BUG #13 — `CutsceneDirector.cancel()` Can't Interrupt Non-Dialogue Commands Mid-Await

**File:** `scripts/cutscene/cutscene_director.gd`  
**Impact:** The `_is_cancelled` flag is checked at the loop boundary in `play()`:
```gdscript
for i in range(_queue.size()):
    if _is_cancelled or not is_inside_tree():
        break
    await _execute_command(_queue[i])  # ← blocked until command finishes
```

For dialogue commands, `cancel()` calls `DialogueManager.force_reset()` which unblocks the await quickly. But non-dialogue commands (camera tweens, actor movements, wait timers) must complete their full duration. Cancel latency can be up to the duration of the longest queued command.

**Recommendation:** For a proper fix, each `_exec_*` method would need to store its tween reference and `cancel()` would kill active tweens. This is an architectural change — document as known limitation for now.

---

## Architecture Notes

### Signal Flow Diagram
```
GameManager.set_story_flag(flag, true)
    └─► story_flag_updated.emit(flag, true)
            └─► ChoiceConsequences._on_story_flag_updated(flag, true)
                    └─► apply_choice_buff(flag)
                            └─► Modifies GameManager.player_stats
                            └─► buff_applied.emit(buff_id)
```

### Dialogue State Layering
```
Layer 1: GameManager.current_state  → GameState.DIALOGUE / EXPLORATION
Layer 2: DialogueManager.is_active  → true / false (checked by player_topdown)
Layer 3: Local scene flags          → in_dialogue, _is_talking, etc.
```

All three layers should agree during dialogue. Bug #6 fixed the missing Layer 1 transition in Oakhaven.

### Input Priority (CanvasLayer order)
```
PauseScreen  — Layer 110, process_mode ALWAYS
DialogueManager — Layer 100, process_mode ALWAYS
CutsceneDirector — Layer 99 (fade), 101 (flash)
CutsceneManager  — Layer 99 (fade)
```

Godot processes `_input()` from highest layer down. PauseScreen fires before DialogueManager. Bug #3 fixed the resulting ESC conflict.

---

## Files Modified

| File | Changes |
|------|---------|
| `scripts/chapter1/ch1_oakhaven_village.gd` | Bug #1: Fixed _exit_tree merge error. Bug #6: Added GameState transitions in _play_dialogue_array |
| `scripts/dialogue_manager.gd` | Bug #2: Added signal emissions. Bug #4: Added pause guard. Bug #7: Added choice history recording |
| `scripts/ui/pause_screen.gd` | Bug #3: Added DialogueManager.is_active guard |
| `scripts/cutscene/cutscene_manager.gd` | Bug #5: Fixed flash rect cleanup with is_instance_valid |
| `scripts/cutscene/cutscene_director.gd` | Bug #8: Added _unblock_input to cancel(), added _exit_tree safety |
| `scripts/choice_consequences.gd` | Bug #9: Removed orphaned wraith_power ABILITY_DESCRIPTIONS entry |
