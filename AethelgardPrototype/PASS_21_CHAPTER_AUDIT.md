# PASS 21 — DEEP CHAPTER SCRIPT AUDIT

**Date:** 2025-01-28  
**Scope:** ALL chapter scripts (Ch0 Prologue, Ch1–Ch3), cutscene systems, and supporting singletons  
**Files Audited:** 27 files (6 Ch1, 9 Ch2, 6 Ch3, 2 Prologue, 2 Cutscene, 2 Singletons)  
**Severity Levels:** CRITICAL / HIGH / MEDIUM / LOW  
**Focus Areas:** Scene transitions, dialogue hangs, autoload assumptions, tween patterns, async safety, timer/signal callbacks, player state  

---

## Summary

| Severity | Count | Description |
|----------|-------|-------------|
| CRITICAL | 5     | Crashes, infinite hangs, data corruption |
| HIGH     | 9     | Visual corruption, blocked progression, lost state |
| MEDIUM   | 12    | Wrong data, inconsistent state, cosmetic glitches |
| LOW      | 7     | Dead code, minor inconsistencies |
| **TOTAL** | **33** | |

---

## CRITICAL — Game-Breaking

---

### BUG-21-01 · `tick_party_combat()` Signature Mismatch — CRASH  
**Files:** `scripts/chapter3/ch3_fractured_wastes.gd`, `scripts/chapter3/ch3_kaelthas_betrayal.gd`  
**Autoload:** `scripts/choice_consequences.gd`

The chapter scripts call `ChoiceConsequences.tick_party_combat()` with **zero arguments** and treat the return value as a `String`. But the actual function signature requires `delta: float` (non-optional) and returns `void`.

This **will crash at runtime** with `Invalid call. Nonexistent function` or wrong arg count error whenever a party member is present during these combat sequences.

**Old — ch3_fractured_wastes.gd (mini-boss combat loop):**
```gdscript
		if has_node("/root/ChoiceConsequences"):
			var assist_text = ChoiceConsequences.tick_party_combat()
			if assist_text != "":
				wraith_hp -= 10
				await _show_dialogue("SYSTEM", "// PARTY ASSIST: %s (-%d to Wraith)" % [assist_text, 10])
```

**New — ch3_fractured_wastes.gd:**
```gdscript
		if has_node("/root/ChoiceConsequences"):
			var assist_text := _get_party_assist()
			if assist_text != "":
				wraith_hp -= 10
				await _show_dialogue("SYSTEM", "// PARTY ASSIST: %s (-%d to Wraith)" % [assist_text, 10])
```

Add helper at bottom of the file:
```gdscript
func _get_party_assist() -> String:
	## Tick party combat for turn-based contexts and return assist description.
	for member in ChoiceConsequences.party_combat_members:
		if member == "seraphina" and ChoiceConsequences.has_ability("arena_combo"):
			return "Seraphina strikes with a combo attack!"
		elif member == "lyra" and ChoiceConsequences.has_ability("ranged_support"):
			return "Lyra fires a support shot!"
		elif member == "elara" and ChoiceConsequences.has_ability("glitch_shield"):
			return "Elara reinforces your defenses!"
	return ""
```

Apply same pattern in `ch3_kaelthas_betrayal.gd` wherever `tick_party_combat()` is called.

---

### BUG-21-02 · `_complete_stream()` Called Multiple Frames — Race Condition  
**File:** `scripts/chapter3/ch3_data_stream.gd`

`_process()` checks `if elapsed_time >= SEGMENT_DURATION` and calls `_complete_stream()`, which is `async`. The flag `stream_active = false` is set **inside** the async body, so `_process()` fires on the next frame before the flag is set, calling `_complete_stream()` a second (or third) time. This corrupts rewards and triggers duplicate scene transitions.

**Old:**
```gdscript
func _process(delta: float) -> void:
	if not stream_active:
		return
	# ... game loop ...
	elapsed_time += delta
	if elapsed_time >= SEGMENT_DURATION:
		_complete_stream()
```

**New:**
```gdscript
func _process(delta: float) -> void:
	if not stream_active:
		return
	# ... game loop ...
	elapsed_time += delta
	if elapsed_time >= SEGMENT_DURATION:
		stream_active = false  # Prevent re-entry BEFORE the async call
		_complete_stream()
```

And remove the redundant `stream_active = false` from inside `_complete_stream()` if it exists there.

---

### BUG-21-03 · Truncated `_input()` Function — No-op ESC Handler  
**File:** `scripts/chapter3/ch3_kaelthas_betrayal.gd` (end of file, ~line 603)

The `_input` function is cut off — it checks `if event.is_action_pressed("ui_cancel"):` but has **no body**. In GDScript, a block with no statements after the colon is a parse error or silently does nothing, meaning the player cannot skip/escape during the boss fight.

**Old:**
```gdscript
func _input(event) -> void:
	if event.is_action_pressed("ui_cancel"):
```

**New:**
```gdscript
func _input(event) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
```

---

### BUG-21-04 · `show_choices()` Return Compared to `null` — Wrong Type Check  
**File:** `scripts/chapter3/ch3_ending.gd`

`DialogueManager.show_choices()` returns an `int` (0, 1, 2...) or `-1` on cancellation. The code checks `if choice == null: return`, which **never** matches because an int is never null. If the player somehow cancels the choice panel, execution falls through to `match choice` with an unhandled value (e.g., -1), causing the SOVEREIGN confrontation to produce wrong dialogue or silently skip.

**Old:**
```gdscript
	var choice = await DialogueManager.show_choices(
		"How do you face SOVEREIGN?",
		["Defiant — 'I didn't ask for this, but I won't kneel.'",
		 "Regretful — 'I just wanted to survive. I never meant to break anything.'",
		 "Doubting — 'Are you really wrong? Maybe the system IS better than freedom.'"]
	)
	if choice == null:
		return
```

**New:**
```gdscript
	var choice = await DialogueManager.show_choices(
		"How do you face SOVEREIGN?",
		["Defiant — 'I didn't ask for this, but I won't kneel.'",
		 "Regretful — 'I just wanted to survive. I never meant to break anything.'",
		 "Doubting — 'Are you really wrong? Maybe the system IS better than freedom.'"]
	)
	if not is_inside_tree():
		return
	if choice < 0 or choice > 2:
		choice = 0  # Default to defiant
```

---

### BUG-21-05 · Local `player_hp` Shadow — Stale GameManager State  
**File:** `scripts/chapter3/ch3_kaelthas_betrayal.gd`

Boss fight damage is tracked in a **local** `player_hp` float, copied from `GameManager.player_stats["hp"]` at fight start. All combat rounds modify the local variable. `GameManager.player_stats["hp"]` is only updated at the very end. During the fight:
- Party assists checking `GameManager.player_stats["hp"]` see stale pre-fight HP
- If the game auto-saves mid-fight, the save has pre-fight HP
- If the player dies from corruption damage (tracked separately), the HP appears full

**Old:**
```gdscript
	var player_hp: float = float(GameManager.player_stats.get("hp", 100))
	# ... 3-phase boss fight modifies player_hp ...
	# At end:
	GameManager.player_stats["hp"] = max(int(player_hp), 1)
```

**New:**
```gdscript
	# Use GameManager HP directly throughout the fight
	var player_hp: float = float(GameManager.player_stats.get("hp", 100))
	# After each damage application:
	GameManager.player_stats["hp"] = max(int(player_hp), 1)
```

Apply `GameManager.player_stats["hp"] = max(int(player_hp), 1)` **after every damage calculation inside each combat round**, not just at the end.

---

## HIGH — Progression Blockers & State Corruption

---

### BUG-21-06 · Looping Tweens Never Killed on Scene Exit  
**Files:** `scripts/chapter1/ch1_glitch_crater.gd`, `scripts/chapter1/ch1_elara_meeting.gd`, `scripts/chapter1/ch1_path_to_oakhaven.gd`

Multiple Chapter 1 scripts create `create_tween().set_loops()` tweens for ambient animations (floating, pulsing, glow effects) but never store references or kill them in `_exit_tree()`. Godot 4 auto-kills tweens bound to freed nodes, but if the tween targets a node on a **different** branch (e.g., a UI overlay on root), the tween survives scene transition and causes `Invalid instance` errors on the next scene.

**Fix Pattern — add to each affected script:**
```gdscript
var _ambient_tweens: Array[Tween] = []

func _exit_tree() -> void:
	for tw in _ambient_tweens:
		if tw and tw.is_valid():
			tw.kill()
	_ambient_tweens.clear()
```

Store every `create_tween().set_loops()` result in `_ambient_tweens`.

---

### BUG-21-07 · `_flicker_tweens` Array Populated but Never Killed  
**File:** `scripts/chapter2/ch2_seraphina_choice.gd`

`_build_background()` stores looping tweens (glow_pulse, haze_tween, flicker tweens) in `_flicker_tweens: Array` but the script has **no** `_exit_tree()` method. If the player transitions out during the cinematic, these looping tweens may persist.

**Old:**
```gdscript
var _flicker_tweens: Array = []

func _build_background() -> void:
	# ... creates looping tweens and appends to _flicker_tweens ...
```

**New — add `_exit_tree()`:**
```gdscript
func _exit_tree() -> void:
	for tw in _flicker_tweens:
		if tw is Tween and tw.is_valid():
			tw.kill()
	_flicker_tweens.clear()
```

---

### BUG-21-08 · `GameManager.relationships["elara"] += 20` — Unguarded Dictionary Access  
**File:** `scripts/chapter1/ch1_tutorial_knight.gd`

Direct `[]` access on the `relationships` dictionary without `.get()`. If the `"elara"` key hasn't been initialized yet (e.g., player took an unusual path), this crashes with a `Key not found` error.

**Old:**
```gdscript
	GameManager.relationships["elara"] += 20
```

**New:**
```gdscript
	GameManager.relationships["elara"] = GameManager.relationships.get("elara", 0) + 20
```

---

### BUG-21-09 · `_show_dialogue()` Wrapper — Callers Resume on Freed Node  
**Files:** `scripts/chapter3/ch3_archive_depths.gd`, `scripts/chapter3/ch3_ironhold_departure.gd`, `scripts/chapter3/ch3_fractured_wastes.gd`, `scripts/chapter3/ch3_kaelthas_betrayal.gd`

All Ch3 scripts use a `_show_dialogue()` wrapper:
```gdscript
func _show_dialogue(speaker: String, text: String) -> void:
    await DialogueManager.say(speaker, text)
    if not is_inside_tree(): return
```

The wrapper's `return` exits `_show_dialogue` **normally** back to the caller. The caller then continues executing past its `await _show_dialogue(...)` line — on a freed node. Callers do **not** add their own `is_inside_tree()` check after the await.

**Fix — each caller must guard after the await:**
```gdscript
	await _show_dialogue("NARRATOR", "The archive hums with ancient code.")
	if not is_inside_tree(): return  # ADD THIS after every await _show_dialogue()
```

Alternatively, have `_show_dialogue()` return a `bool`:
```gdscript
func _show_dialogue(speaker: String, text: String) -> bool:
	await DialogueManager.say(speaker, text)
	return is_inside_tree()
```

Then callers do:
```gdscript
	if not await _show_dialogue("NARRATOR", "..."): return
```

---

### BUG-21-10 · `source_key_count` Hardcoded Default Overwrites Real Count  
**File:** `scripts/chapter3/ch3_archive_depths.gd`

The floor 4 source key logic overwrites any previously collected count with a hardcoded fallback of 3:

**Old:**
```gdscript
	GameManager.source_key_count = GameManager.get("source_key_count") if GameManager.get("source_key_count") != null else 3
	GameManager.source_key_count += 1
```

**New:**
```gdscript
	var current_count: int = GameManager.get("source_key_count") if GameManager.get("source_key_count") != null else 0
	GameManager.source_key_count = current_count + 1
```

The default should be `0` (no keys collected yet), not `3`.

---

### BUG-21-11 · `_on_boss_defeated()` — Unguarded `GameManager` Call After Guard  
**File:** `scripts/chapter2/ch2_administrator_boss.gd`

**Old:**
```gdscript
func _on_boss_defeated() -> void:
	if has_node("/root/GameManager"):
		GameManager.end_boss_fight()
	GameManager.set_story_flag("ch2_administrator_defeated", true)  # OUTSIDE guard
```

**New:**
```gdscript
func _on_boss_defeated() -> void:
	if has_node("/root/GameManager"):
		GameManager.end_boss_fight()
		GameManager.set_story_flag("ch2_administrator_defeated", true)
```

Move `set_story_flag()` inside the existing `has_node` guard.

---

### BUG-21-12 · Storm System Damages Player During Dialogue  
**File:** `scripts/chapter3/ch3_fractured_wastes.gd`

The `_process(delta)` method ticks the storm system (applies corruption damage, flashes warnings) **regardless** of whether the player is in a dialogue sequence. If a location visit triggers a long dialogue chain, storm damage ticks accumulate silently — potentially killing the player mid-conversation.

**Old:**
```gdscript
func _process(delta: float) -> void:
	if current_phase != 1:
		return
	_storm_timer -= delta
	# ... storm damage logic ...
```

**New:**
```gdscript
func _process(delta: float) -> void:
	if current_phase != 1:
		return
	if _visiting:  # Don't tick storms during location visits
		return
	_storm_timer -= delta
	# ... storm damage logic ...
```

---

### BUG-21-13 · `_give_loot()` — Bare Autoload Checks  
**File:** `scripts/chapter1/ch1_tutorial_knight.gd`

Loot granting uses `if Inventory:` as a truthiness check, which always passes for autoloads (they are valid Objects). This isn't a guard — it's a no-op that gives false confidence.

**Old:**
```gdscript
func _give_loot() -> void:
	if Inventory:
		Inventory.add_item("knight_helm", 1)
```

**New:**
```gdscript
func _give_loot() -> void:
	if has_node("/root/Inventory"):
		Inventory.add_item("knight_helm", 1)
```

---

### BUG-21-14 · `_glitch_tween` Looping Tween Not Killed in `_exit_tree()`  
**File:** `scripts/prologue/flight_707_cinematic.gd`

`toggle_glitch_overlay(true)` creates a `_glitch_tween = create_tween().set_loops()`. While the function properly kills-before-recreating, there is no `_exit_tree()` to kill it if the scene transitions while the overlay is active (e.g., during `play_crash_buildup()` rapid glitch toggling).

**Fix — add:**
```gdscript
func _exit_tree() -> void:
	if _glitch_tween and _glitch_tween.is_valid():
		_glitch_tween.kill()
		_glitch_tween = null
```

---

## MEDIUM — Wrong Data & Inconsistent State

---

### BUG-21-15 · Unguarded Autoload Calls Across Multiple Scripts  
**Files:** Multiple Chapter 2 & 3 scripts  

These autoload methods are called without `has_node("/root/AutoloadName")` guards, which crash if the autoload is removed or renamed:

| Script | Unguarded Call |
|--------|---------------|
| `ch3_archive_depths.gd` | `CombatFX.apply_screen_shake()`, `GlitchOverlay.flash_glitch()` |
| `ch3_data_stream.gd` | `CombatFX.apply_screen_shake()`, `CombatFX.apply_hitstop()` |
| `ch3_fractured_wastes.gd` | `CombatFX.apply_screen_shake()`, `CombatFX.apply_hitstop()` |
| `ch3_ending.gd` | `GameJuice.reality_shatter_effect()`, `GameJuice.boss_phase_transition()` |
| `ch2_underground_network.gd` | `VFXLibrary.spawn_status_indicator()` |

**Fix pattern:**
```gdscript
# Old:
CombatFX.apply_screen_shake(10.0, 0.3)

# New:
if has_node("/root/CombatFX"):
	CombatFX.apply_screen_shake(10.0, 0.3)
```

---

### BUG-21-16 · `_trigger_seraphina_encounter()` and `_trigger_administrator_arrival()` Unreachable  
**File:** `scripts/chapter2/ch2_ironhold_city.gd`

These two functions are defined but never called by any trigger area, signal connection, `_input` handler, or story gate. They appear to be story progression functions that should be invoked when certain flags are set, but no mechanism does so.

**Likely fix:** Connect them to story flag checks in `_process()` or register as callbacks:
```gdscript
func _process(_delta: float) -> void:
	if GameManager.has_flag("ch2_arena_complete") and not _seraphina_triggered:
		_seraphina_triggered = true
		_trigger_seraphina_encounter()
	if GameManager.has_flag("ch2_underground_complete") and not _admin_triggered:
		_admin_triggered = true
		_trigger_administrator_arrival()
```

---

### BUG-21-17 · `_transition_timer` in `_process()` Fires Scene Change Mid-Dialogue  
**File:** `scripts/chapter1/ch1_tutorial_knight.gd`

A `_transition_timer` counts down in `_process()` regardless of dialogue state. If a post-fight dialogue sequence is playing, the timer hits zero and triggers `SceneTransitions.change_scene()` — ripping the player out mid-sentence.

**Fix:** Guard the timer behind dialogue completion:
```gdscript
func _process(delta: float) -> void:
	if not _dialogue_complete:
		return
	if _transition_timer > 0:
		_transition_timer -= delta
		if _transition_timer <= 0:
			_do_scene_transition()
```

---

### BUG-21-18 · `GameManager.get("glitch_meter")` — Inconsistent Property Access  
**File:** `scripts/chapter2/ch2_chapter_end.gd`

Uses `GameManager.get("property_name")` with null fallback, which uses `Object.get()` — this retrieves the raw property value or null. Other scripts access `GameManager.glitch_meter` directly or use `GameManager.player_stats.get()`. The inconsistency suggests uncertainty about whether the property exists.

**Fix:** Use the same access pattern as other scripts:
```gdscript
# Old:
var corruption = GameManager.get("glitch_meter") if GameManager.get("glitch_meter") != null else 0

# New:
var corruption = GameManager.glitch_meter if "glitch_meter" in GameManager else 0
```

Or standardize on a getter: `GameManager.get_corruption()`.

---

### BUG-21-19 · `get_viewport().get_camera_2d()` May Return Null  
**File:** `scripts/chapter1/ch1_oakhaven_village.gd`, `scripts/chapter3/ch3_ending.gd`

Both scripts call `get_viewport().get_camera_2d()` on scenes that may not have a Camera2D node (they extend Control). The resulting null reference is either used unsafely or stored but unused.

**Fix:**
```gdscript
var _camera = get_viewport().get_camera_2d()
if _camera:
	_camera.shake(...)
```

---

### BUG-21-20 · `_spawn_clockwork_automaton()` Connects Signal Without Safety Check  
**File:** `scripts/chapter2/ch2_clock_tower.gd`

Connects to a `boss_defeated` signal on the spawned boss node without verifying the signal exists:

**Old:**
```gdscript
	boss_node.boss_defeated.connect(_on_boss_defeated)
```

**New:**
```gdscript
	if boss_node.has_signal("boss_defeated"):
		boss_node.boss_defeated.connect(_on_boss_defeated)
	else:
		push_warning("[CLOCK TOWER] Boss node missing 'boss_defeated' signal")
```

---

### BUG-21-21 · `_wait_for_input()` Double-Handling with `_input()`  
**File:** `scripts/chapter3/ch3_ending.gd`

`_input()` emits a `_next_input` signal for **any** `InputEventKey` press, including `ui_cancel` which has its own handling. The `_wait_for_input()` helper awaits `_next_input`, so pressing ESC both triggers the cancel handler AND satisfies the input wait — advancing the sequence unexpectedly.

**Fix — exclude ui_cancel from the signal:**
```gdscript
func _input(event) -> void:
	if event is InputEventKey and event.pressed:
		if event.is_action("ui_cancel"):
			# Handle skip/cancel separately
			get_viewport().set_input_as_handled()
			return
		_next_input.emit()
		get_viewport().set_input_as_handled()
```

---

### BUG-21-22 · `_visit_server_room()` Missing `_visiting` Guard  
**File:** `scripts/chapter3/ch3_fractured_wastes.gd`

Unlike all other `_visit_*()` functions which set `_visiting = true` at the top, `_visit_server_room()` omits it. Rapid key presses during the short input window can trigger the function multiple times, causing duplicate dialogue and rewards.

**Old:**
```gdscript
func _visit_server_room() -> void:
	# ... immediately starts dialogue ...
```

**New:**
```gdscript
func _visit_server_room() -> void:
	if _visiting:
		return
	_visiting = true
	# ... dialogue and rewards ...
	_visiting = false
```

---

### BUG-21-23 · `GameManager.get_flag()` vs `GameManager.has_flag()` API Inconsistency  
**File:** `scripts/side_quest_manager.gd`

Uses `GameManager.get_flag(quest_data["requires_flag"])` but other scripts uniformly use `GameManager.has_flag()`. If `get_flag()` doesn't exist on GameManager, this crashes at quest discovery time.

**Fix:** Use `has_flag()` consistently:
```gdscript
# Old:
if not GameManager.get_flag(quest_data["requires_flag"]):

# New:
if not GameManager.has_flag(quest_data["requires_flag"]):
```

---

### BUG-21-24 · `body_position_or_default()` References Potentially Null `player_node`  
**File:** `scripts/chapter2/ch2_clock_tower.gd`

The standalone helper function `body_position_or_default()` used in `_pre_boss_dialogue()` references `player_node` which may be null if the player character node hasn't been found/assigned.

**Fix:**
```gdscript
func body_position_or_default() -> Vector2:
	if player_node and is_instance_valid(player_node):
		return player_node.global_position
	return Vector2(640, 400)  # Sensible default
```

---

### BUG-21-25 · String-Based Callback Dispatch  
**File:** `scripts/chapter1/ch1_oakhaven_village.gd`

`_play_dialogue_array()` uses `parent.call(callback)` with raw string method names. If a method is renamed or misspelled, this fails **silently** — no error, no dialogue, potential soft-lock.

**Fix — add validation:**
```gdscript
if callback != "" and parent.has_method(callback):
	await parent.call(callback)
else:
	push_warning("[OAKHAVEN] Missing callback: %s" % callback)
```

---

### BUG-21-26 · NPC Dialogue Functions Are Async but Unguarded Against Simultaneous Interactions  
**File:** `scripts/chapter2/ch2_ironhold_city.gd`

NPC proximity triggers call async dialogue functions, but there's no `_is_talking` mutex. Walking between two NPCs rapidly can interleave two dialogue sequences.

**Fix:**
```gdscript
var _is_talking: bool = false

func _trigger_npc_dialogue(npc_name: String) -> void:
	if _is_talking:
		return
	_is_talking = true
	# ... dialogue ...
	_is_talking = false
```

---

## LOW — Dead Code & Minor Issues

---

### BUG-21-27 · Dead Code: `_camera` Assigned but Never Used  
**File:** `scripts/chapter3/ch3_ending.gd`

```gdscript
var _camera = get_viewport().get_camera_2d()
# _camera is never referenced again
```

Remove the assignment or use it for the intended screen effects.

---

### BUG-21-28 · Empty `_input()` Handlers (Pass-Only)  
**Files:** `scripts/chapter1/ch1_elara_meeting.gd`, `scripts/chapter2/ch2_ironhold_gate.gd`

Both have `_input()` functions containing only `pass`. These register as input handlers unnecessarily, consuming a small amount of processing.

**Fix:** Remove the empty `_input()` functions entirely.

---

### BUG-21-29 · Duplicate `is_inside_tree()` Return in Fallback Path  
**File:** `scripts/chapter2/ch2_underground_network.gd`

`_data_wraith_choice()` fallback case has the safety guard twice in sequence:

```gdscript
	# Fallback
	if not is_inside_tree(): return
	if not is_inside_tree(): return  # duplicate
```

Remove the duplicate line.

---

### BUG-21-30 · `_on_skip_pressed` Signal Never Connected  
**Files:** `scripts/chapter1/ch1_glitch_crater.gd`, `scripts/chapter1/ch1_elara_meeting.gd`

Both files define `_on_skip_pressed()` but no signal ever connects to it. The intended skip button UI was likely planned but never wired up. These scripts do have hold-ESC skip via `_process()`, so the orphaned function is dead code.

**Fix:** Remove the orphaned `_on_skip_pressed()` methods, or wire them to a skip button if one is planned.

---

### BUG-21-31 · Tween Variable Shadowing  
**File:** `scripts/chapter1/ch1_path_to_oakhaven.gd`

A local `tween` variable in a nested scope shadows an outer `tween` variable, making the outer tween unreachable for cleanup.

**Fix:** Use unique names: `tween_inner`, `pulse_tween`, etc.

---

### BUG-21-32 · `_on_custom_effect` Match Only Has Wildcard  
**File:** `scripts/chapter1/ch1_shatter_transition.gd`

The `_on_custom_effect` handler only has a wildcard `_:` branch — it doesn't actually handle any specific effects, making the signal connection pointless.

**Fix:** Either implement the needed effects or remove the signal connection.

---

### BUG-21-33 · `_nyx_dialogue()` Direct `story_flags.get()` Instead of `has_flag()`  
**File:** `scripts/chapter2/ch2_ironhold_city.gd`

Uses `GameManager.story_flags.get("flag", false)` directly instead of the canonical `GameManager.has_flag("flag")` wrapper. While functionally equivalent, it bypasses any future validation or logging in `has_flag()`.

**Fix:**
```gdscript
# Old:
if GameManager.story_flags.get("ch2_seraphina_met", false):

# New:
if GameManager.has_flag("ch2_seraphina_met"):
```

---

## Supporting Script Notes

### `cutscene_director.gd` & `cutscene_manager.gd`
Both systems are **well-implemented** with consistent `is_inside_tree()` guards, proper tween cleanup, input blocking/unblocking, and timeout-protected parallel execution. No critical bugs found. Minor note: `_exec_call_method()` checks `if result is Signal` to await coroutines, but GDScript 4 `callv()` on an async function doesn't return a Signal — it starts the coroutine without awaiting. This means async callbacks passed to `call_method` beats won't be properly awaited.

### `side_quest_manager.gd`
Clean implementation. Quest state machine works correctly. Notification system properly chains via tween callbacks. Only issue is the `get_flag()` vs `has_flag()` inconsistency (BUG-21-23).

### `choice_consequences.gd`
Well-designed buff/debuff system with proper save/load. The `tick_party_combat()` signature mismatch with callers (BUG-21-01) is the sole critical issue. Consider adding a turn-based variant: `tick_party_combat_turn() -> String` for scripted combat encounters.

### `prologue/crash_sequence.gd`
Clean typewriter-driven boot sequence. Properly uses `_process()` for phased progression. Hold-ESC skip is correctly implemented. No bugs found.

### `prologue/flight_707_cinematic.gd`
Professional CutsceneManager integration. Good `is_inside_tree()` discipline. Only issue is the looping `_glitch_tween` missing `_exit_tree()` cleanup (BUG-21-14).

---

## Systemic Patterns to Address

### 1. Looping Tween Cleanup
**Affected:** 5+ scripts across all chapters  
**Pattern:** Every script that calls `create_tween().set_loops()` must store the tween reference and kill it in `_exit_tree()`.

### 2. `_show_dialogue()` Wrapper Safety
**Affected:** All Ch3 scripts  
**Pattern:** Either callers must add `if not is_inside_tree(): return` after every `await _show_dialogue()`, or the wrapper should return a boolean indicating tree membership.

### 3. Autoload Guard Consistency
**Affected:** 8+ scripts  
**Pattern:** All autoload calls (CombatFX, VFXLibrary, GlitchOverlay, GameJuice, SFXManager) should use the `has_node("/root/Name")` pattern before calling methods.

### 4. `tick_party_combat()` API  
**Affected:** choice_consequences.gd + all combat scripts  
**Pattern:** Add a turn-based variant `get_party_assist_text() -> String` for scripted encounters that don't have per-frame delta.

---

**End of PASS 21 Audit**
