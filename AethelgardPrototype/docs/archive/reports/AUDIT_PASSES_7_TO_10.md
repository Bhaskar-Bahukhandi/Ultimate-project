# Deep Audit — Passes 7–10
## Project Aethelgard (Godot 4.6 / GDScript)

---

# PASS 7 — INPUT HANDLING GAPS

---

### 7.1 · `jump` and `ui_accept` Both Map to Space — Dual Processing
**Severity:** HIGH  
**File:** [project.godot](project.godot) (input section) + [scripts/combat/player_combat.gd](scripts/combat/player_combat.gd)

In `project.godot`, both `jump` and `ui_accept` are bound to the Space key (physical keycode 32). Every press of Space fires **both** actions. In `player_combat.gd`, `_physics_process` reads `Input.is_action_just_pressed("jump")` for combat jumping, but pressing Space also triggers `ui_accept` listeners elsewhere in the tree (e.g., `DialogueManager._input`, `LevelUpUI._process`, `game_over._input`), leading to double-action side effects.

```gdscript
# project.godot
jump={...events=[Object(InputEventKey,"keycode":32,...)]}
ui_accept={...events=[Object(InputEventKey,"keycode":32,...)]}
```

**Suggested fix:** Remove the Space key from `ui_accept` events and only keep Enter, or dedicate Space exclusively to `jump` and use Enter/ui_accept for UI confirmation. Alternatively, in every `_input` handler that checks `ui_accept`, also call `set_input_as_handled()` so `jump` doesn't also fire.

---

### 7.2 · `oakhaven.gd` Uses Raw Keycodes Instead of Input Actions
**Severity:** HIGH  
**File:** [scripts/exploration/oakhaven.gd](scripts/exploration/oakhaven.gd#L149-L152)

```gdscript
func _input(event):
    if in_dialogue and event is InputEventKey and event.pressed:
        if event.keycode == KEY_SPACE or event.keycode == KEY_ENTER:
            advance_dialogue()
```

This bypasses Godot's input map entirely. If the player rebinds `ui_accept` (the main menu has a rebinding system), this dialogue will still only respond to physical Space/Enter. It also does **not** call `set_input_as_handled()`, so other listeners (DialogueManager, PauseScreen, player_combat) will also process this same key event.

**Suggested fix:**
```gdscript
func _input(event):
    if in_dialogue:
        if event.is_action_pressed("ui_accept"):
            advance_dialogue()
            get_viewport().set_input_as_handled()
```

---

### 7.3 · `ch2_chapter_end.gd` Uses Raw Keycode `KEY_SPACE`
**Severity:** MEDIUM  
**File:** [scripts/chapter2/ch2_chapter_end.gd](scripts/chapter2/ch2_chapter_end.gd#L503-L506)

```gdscript
func _input(event: InputEvent):
    if not end_card_visible:
        return
    if event is InputEventKey and event.pressed and event.keycode == KEY_SPACE:
        skip_timer = true
```

Same issue as 7.2 — raw keycode ignores remapped inputs and does not consume the event.

**Suggested fix:** Use `event.is_action_pressed("ui_accept")` and call `get_viewport().set_input_as_handled()`.

---

### 7.4 · `combat_arena.gd` `_input` Has No Guards or Event Consumption
**Severity:** HIGH  
**File:** [scripts/combat/combat_arena.gd](scripts/combat/combat_arena.gd#L108-L113)

```gdscript
func _input(event):
    if event.is_action_pressed("root_access") and not root_access_active:
        open_root_access()
    elif event.is_action_pressed("perfect_delete"):
        use_perfect_delete()
```

Problems:
1. **No `set_input_as_handled()`** — other listeners also process `root_access` and `perfect_delete`.
2. **No state guard** — this fires even when the pause menu, shop, or dialogue is open. `combat_arena` does **not** have `process_mode = PROCESS_MODE_ALWAYS`, so pausing the tree blocks it, but if `DialogueManager` is active (layer 100, `PROCESS_MODE_ALWAYS`) and the player presses `E` (root_access), the arena still sees it because `_input` propagates to all nodes before `_unhandled_input`.
3. **No `is_action_pressed("perfect_delete")` check for charges** at the event level — `use_perfect_delete()` checks charges internally but the event is still consumed.

**Suggested fix:**
```gdscript
func _input(event):
    if DialogueManager.is_active or get_tree().paused:
        return
    if event.is_action_pressed("root_access") and not root_access_active:
        open_root_access()
        get_viewport().set_input_as_handled()
    elif event.is_action_pressed("perfect_delete"):
        use_perfect_delete()
        get_viewport().set_input_as_handled()
```

---

### 7.5 · Multiple Scene `_input` Handlers Pass Through Without Consuming
**Severity:** MEDIUM  
**File:** Multiple files

The following scene scripts have `_input(event)` handlers that receive events but do nothing meaningful with them (just `pass`) **and** do not consume the event. This means every `_input` in the tree still processes the event:

| File | Line | Code |
|------|------|------|
| [ch1_shatter_transition.gd](scripts/chapter1/ch1_shatter_transition.gd#L513-L514) | 513 | `if event.is_action_pressed("ui_accept"): pass` |
| [ch1_path_to_oakhaven.gd](scripts/chapter1/ch1_path_to_oakhaven.gd#L919-L922) | 919 | `if event.is_action_pressed("ui_accept"): ... return` |
| [ch1_elara_meeting.gd](scripts/chapter1/ch1_elara_meeting.gd#L746-L749) | 746 | `if event.is_action_pressed("ui_accept"): pass` |
| [ch1_glitch_crater.gd](scripts/chapter1/ch1_glitch_crater.gd#L826) | 826 | `if event.is_action_pressed("ui_accept"): pass` |

These are stub handlers left from cinematic scene wiring. They intercept `_input` (which runs **before** `_unhandled_input`) and swallow no events, meaning they're dead code that confuses maintenance.

**Suggested fix:** Either remove these empty handlers or, if they're meant to block ui_accept during cinematics, call `get_viewport().set_input_as_handled()`:
```gdscript
func _input(event):
    if cinematic_active and event.is_action_pressed("ui_accept"):
        get_viewport().set_input_as_handled()  # Block jump during cutscene
```

---

### 7.6 · `level_up_ui.gd` Uses `is_action_just_pressed` in `_process()` — No Event Consumption
**Severity:** MEDIUM  
**File:** [scripts/ui/level_up_ui.gd](scripts/ui/level_up_ui.gd)

```gdscript
func _process(delta):
    if popup_visible and Input.is_action_just_pressed("ui_accept"):
        hide_popup()
```

Using `Input.is_action_just_pressed()` in `_process()` (rather than `_input()`) means:
1. The event is **never** consumed — `DialogueManager`, `player_combat`, and every other input listener also sees it.
2. If the level-up popup appears during combat (possible when killing an enemy triggers `player_leveled_up`), pressing Space both dismisses the popup AND triggers a jump.

**Suggested fix:** Switch to `_input()` with event consumption:
```gdscript
func _input(event):
    if popup_visible and event.is_action_pressed("ui_accept"):
        hide_popup()
        get_viewport().set_input_as_handled()
```

---

### 7.7 · `player_combat.gd` Only Checks `DialogueManager.is_active` for Jump — Not Other Actions
**Severity:** MEDIUM  
**File:** [scripts/combat/player_combat.gd](scripts/combat/player_combat.gd)

In `_physics_process`, the jump input check guards against dialogue:
```gdscript
if Input.is_action_just_pressed("jump") and not DialogueManager.is_active:
    ...
```

But **attack**, **spell**, **heal**, **defend**, **sprint**, and **dash** inputs do NOT check `DialogueManager.is_active` or `GameManager.current_state`. If dialogue triggers mid-combat (e.g., boss phase transition dialogue), the player can still attack, cast spells, etc.

**Suggested fix:** Add a top-of-function guard:
```gdscript
func _physics_process(delta):
    if DialogueManager.is_active or GameManager.current_state == GameManager.GameState.CUTSCENE:
        velocity.x = move_toward(velocity.x, 0, FRICTION * delta)
        move_and_slide()
        return
    # ... rest of input handling
```

---

### 7.8 · `game_over.gd` Checks `ui_cancel` — Not Defined in project.godot
**Severity:** LOW  
**File:** [scripts/game_over.gd](scripts/game_over.gd#L60-L100)

```gdscript
if event.is_action_pressed("ui_cancel"):
    get_tree().quit()
```

`ui_cancel` is not defined in the `[input]` section of `project.godot`. It relies on Godot's **built-in** default mapping (Escape key). This works but is fragile — if the project ever adds a custom `ui_cancel` mapping or if Godot's defaults change, behavior may break silently. Additionally, `pause_menu` also maps to Escape, so pressing Escape during game-over will fire both `ui_cancel` and `pause_menu`.

**Suggested fix:** Either explicitly define `ui_cancel` in project.godot, or gate `game_over._input` to only respond when `GameManager.current_state == GameState.GAME_OVER`.

---

# PASS 8 — AUTOLOAD DEPENDENCY ORDER / INITIALIZATION RACE CONDITIONS

---

### Autoload Load Order (for reference)
| # | Autoload | Script |
|---|----------|--------|
| 1 | GameManager | game_manager.gd |
| 2 | DialogueManager | dialogue_manager.gd |
| 3 | AssetManager | asset_manager.gd |
| 4 | Inventory | inventory_system.gd |
| 5 | CombatEffects | combat_effects.gd |
| 6 | GlitchOverlay | glitch_overlay.gd |
| 7 | VFXLibrary | vfx_library.gd |
| 8 | PauseScreen | pause_screen.gd |
| 9 | StatusWindow | status_window.gd |
| 10 | InteractionPrompt | interaction_prompt.gd |
| 11 | MusicManager | music_manager.gd |
| 12 | SceneTransitions | scene_transition_manager.gd |
| 13 | ShopSystem | shop_system.gd |
| 14 | BackgroundManager | background_manager.gd |
| 15 | ObjectPool | object_pool.gd |
| 16 | LevelUpUI | level_up_ui.gd |
| 17 | DropManager | drop_manager.gd |
| 18 | SFXManager | sfx_manager.gd |

---

### 8.1 · `inventory_system.gd` `_ready()` Calls `SFXManager.play()` — SFXManager Not Yet Loaded
**Severity:** CRITICAL  
**File:** [scripts/inventory_system.gd](scripts/inventory_system.gd#L72-L77) + [scripts/inventory_system.gd](scripts/inventory_system.gd#L99)

Inventory is autoload #4. SFXManager is autoload #18 (last). During `_ready()`:

```gdscript
func _ready():
    if items.is_empty():
        add_item("health_potion", 3)      # calls SFXManager.play("item_pickup")
        add_item("glitch_stabilizer", 2)   # calls SFXManager.play("item_pickup")

func add_item(item_id: String, quantity: int = 1) -> bool:
    ...
    SFXManager.play("item_pickup")  # LINE 99 — SFXManager doesn't exist yet!
```

When Godot processes autoload #4's `_ready()`, autoloads #5–#18 haven't been instantiated. `SFXManager` is `null`, causing a runtime error (or silent failure if Godot defers the lookup).

**Suggested fix:** Guard the SFX call or defer it:
```gdscript
func add_item(item_id: String, quantity: int = 1) -> bool:
    ...
    if is_node_ready() and Engine.get_singleton("SFXManager") != null:
        SFXManager.play("item_pickup")
    # Or better: just skip SFX in _ready() by adding a flag
```

Or restructure: Move SFXManager higher in the autoload order (to #1 or #2), since it has no dependencies.

---

### 8.2 · `scene_transition_manager.gd` Calls `SFXManager.play()` at Runtime — Timing May Be Safe
**Severity:** LOW (info)  
**File:** [scripts/scene_transition_manager.gd](scripts/scene_transition_manager.gd)

`SceneTransitions` (#12) calls `SFXManager.play("transition_whoosh")` in `change_scene()`, which is only called after all autoloads have initialized. This is **safe** at runtime but would crash if `change_scene()` were ever called during `_ready()`.

**Suggested fix:** No immediate action needed, but add a null-check as defensive coding:
```gdscript
if SFXManager:
    SFXManager.play("transition_whoosh")
```

---

### 8.3 · `glitch_overlay.gd` Connects to `GameManager` Signal — Safe
**Severity:** NONE (verified safe)  
**File:** [scripts/glitch_overlay.gd](scripts/glitch_overlay.gd)

GlitchOverlay (#6) connects to `GameManager.glitch_meter_changed` in `_ready()`. GameManager is #1, so it exists. ✓

---

### 8.4 · `level_up_ui.gd` Connects to `GameManager.player_leveled_up` — Safe
**Severity:** NONE (verified safe)  
**File:** [scripts/ui/level_up_ui.gd](scripts/ui/level_up_ui.gd)

LevelUpUI (#16) connects to GameManager (#1). ✓

---

### 8.5 · 18 Autoloads Is Excessive — Performance & Maintenance Concern
**Severity:** MEDIUM (architectural)  
**File:** [project.godot](project.godot)

18 autoloads means 18 persistent nodes in the scene tree root, each with `_process()` / `_physics_process()` / `_input()` callbacks potentially running every frame. Several of these (InteractionPrompt, LevelUpUI, DropManager, BackgroundManager, ObjectPool) could be lazy-loaded or instantiated on demand rather than being permanent singletons.

**Suggested fix:** Consider consolidating related autoloads:
- Merge `SFXManager` + `MusicManager` → `AudioManager`
- Merge `CombatEffects` + `VFXLibrary` → `EffectsManager`
- Make `InteractionPrompt`, `LevelUpUI`, `DropManager` scene-local rather than global autoloads

---

### 8.6 · Multiple Autoloads Set `process_mode = PROCESS_MODE_ALWAYS` — Input Fights While Paused
**Severity:** MEDIUM  
**File:** Multiple autoloads

The following autoloads all have `process_mode = PROCESS_MODE_ALWAYS` and active `_input()` handlers:

| Autoload | Layer | Input Method |
|----------|-------|-------------|
| DialogueManager | 100 | `_input()` |
| PauseScreen | 100 | `_input()` |
| StatusWindow | 99 | `_unhandled_input()` |
| ShopSystem | — | `_input()` |
| RootAccessPanel | — | `_unhandled_input()` |
| DropManager | — | `PROCESS_MODE_ALWAYS` |

When the game is paused (e.g., PauseScreen opens), **all** of these still receive input events. If the player presses `I` (status_window) while paused, `StatusWindow._unhandled_input` will toggle it open on top of the pause screen. Similarly, `E` (root_access) can trigger `RootAccessPanel` while paused.

This is a combined input+UI issue — listed here because it's fundamentally a consequence of all these autoloads running with `PROCESS_MODE_ALWAYS`.

**Suggested fix:** Each `_input`/`_unhandled_input` handler should check whether another modal UI is already active:
```gdscript
func _unhandled_input(event):
    if PauseScreen.is_paused or DialogueManager.is_active or ShopSystem.is_open:
        return
    if event.is_action_pressed("status_window"):
        toggle_status()
```

---

# PASS 9 — UI EDGE CASES

---

### 9.1 · No Mutual Exclusion Between Modal UI Panels
**Severity:** HIGH  
**File:** Multiple UI scripts

Five different UI systems can all be opened simultaneously with no cross-checking:

| Panel | Opens Via | Pauses Tree? | Layer |
|-------|-----------|-------------|-------|
| PauseScreen | Escape (`pause_menu`) | Yes | 100 |
| StatusWindow | I (`status_window`) | No | 99 |
| ShopSystem | NPC interaction | Yes | — |
| RootAccessPanel | E (`root_access`) | Yes | — |
| DialogueManager | Script calls | No | 100 |

**Conflict scenarios:**
- Player presses `I` → StatusWindow opens → Player presses `Escape` → PauseScreen opens on top → StatusWindow is still visible underneath at layer 99
- ShopSystem opens (pauses tree) → Player presses `Escape` → PauseScreen toggles → `get_tree().paused = false` → Shop is still visible but game is unpaused
- RootAccessPanel opens (pauses tree) → Player presses `Escape` → PauseScreen `toggle_pause()` sets `paused = false` → RootAccessPanel expects tree to be paused

**Suggested fix:** Create a UI stack manager:
```gdscript
# In GameManager or a new UIManager autoload
var ui_stack: Array[String] = []

func push_ui(panel_name: String):
    ui_stack.append(panel_name)
    get_tree().paused = true

func pop_ui() -> String:
    var panel = ui_stack.pop_back()
    if ui_stack.is_empty():
        get_tree().paused = false
    return panel

func is_any_ui_open() -> bool:
    return not ui_stack.is_empty()
```

---

### 9.2 · PauseScreen and DialogueManager Both Use CanvasLayer 100 — Z-Order Conflict
**Severity:** MEDIUM  
**File:** [scripts/ui/pause_screen.gd](scripts/ui/pause_screen.gd) + [scripts/dialogue_manager.gd](scripts/dialogue_manager.gd)

Both set `layer = 100`. If dialogue triggers and the player immediately presses Escape, both panels render at the same layer. The one that appears "on top" depends on tree order (autoload insertion order: DialogueManager #2, PauseScreen #8), meaning DialogueManager will be **behind** PauseScreen. But since PauseScreen has `PROCESS_MODE_ALWAYS` and covers the full screen, the dialogue is invisible but still receiving input.

**Suggested fix:** Use distinct layers:
- DialogueManager: layer 100
- PauseScreen: layer 110 (always on top of everything)
- SceneTransitions: layer 200 (already correct — highest)

---

### 9.3 · `status_window.gd` Reads Wrong Key for Perfect Delete Charges — Always Shows 0
**Severity:** HIGH (data display bug)  
**File:** [scripts/ui/status_window.gd](scripts/ui/status_window.gd#L90)

```gdscript
var pd_charges = stats.get("perfect_deletes", 0)
```

The `player_stats` dictionary does NOT contain a `"perfect_deletes"` key. The actual data is stored as a **top-level variable** on GameManager:
```gdscript
var perfect_delete_charges: int = 3   # game_manager.gd line 7
```

This means `pd_charges` is **always 0** in the status display.

**Suggested fix:**
```gdscript
var pd_charges = GameManager.perfect_delete_charges
```

---

### 9.4 · `pause_screen.gd` Has the Same Wrong Key Bug for Perfect Deletes
**Severity:** HIGH (data display bug)  
**File:** [scripts/ui/pause_screen.gd](scripts/ui/pause_screen.gd#L270)

```gdscript
var pd_charges = GameManager.player_stats.get("perfect_deletes", 0)
```

Same issue as 9.3. `player_stats` has no `"perfect_deletes"` key. Will always display 0.

**Suggested fix:**
```gdscript
var pd_charges = GameManager.perfect_delete_charges
```

---

### 9.5 · StatusWindow ASCII Art Layout Will Break With Different Font Sizes
**Severity:** LOW  
**File:** [scripts/ui/status_window.gd](scripts/ui/status_window.gd)

The status window builds its display using fixed-width ASCII art formatting with `String.pad_left()` / `"%.1f"` formatting, relying on monospace alignment. If the font assigned is not monospace, or if the user changes system DPI/scaling, the columns will misalign. There's no `clip_text` or `text_overrun_behavior` set on the labels.

**Suggested fix:** Use a guaranteed monospace font (like the project's terminal font) and set `clip_text = true` on the label:
```gdscript
status_label.clip_text = true
status_label.add_theme_font_override("font", preload("res://assets/fonts/your_mono_font.tres"))
```

---

### 9.6 · InteractionPrompt at Layer 10 — Can Render Behind Scene CanvasLayers
**Severity:** LOW  
**File:** [scripts/interaction_prompt.gd](scripts/interaction_prompt.gd)

InteractionPrompt uses `layer = 10`. If any scene uses a CanvasLayer ≥ 10 for HUD elements, the interaction prompt will render behind them. Most other UI autoloads use layer 90–200.

**Suggested fix:** Set `layer = 50` or higher to ensure visibility above game content but below modal panels.

---

### 9.7 · `mouse_filter` Not Set on PauseScreen/ShopSystem Container Children
**Severity:** MEDIUM  
**File:** [scripts/ui/pause_screen.gd](scripts/ui/pause_screen.gd) + [scripts/shop_system.gd](scripts/shop_system.gd)

PauseScreen and ShopSystem build their UIs programmatically with many Panel/Label/Button children. Background panels and labels don't explicitly set `mouse_filter = MOUSE_FILTER_IGNORE`, which means they intercept mouse events and block clicks from reaching elements behind them. This can cause:
- Click-through issues where clicking a "gap" between buttons does nothing
- Mouse events intended for the game world are silently consumed by invisible UI elements when the panel is hidden but `visible = false` isn't set on all children

**Suggested fix:** On all non-interactive containers and labels:
```gdscript
panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
label.mouse_filter = Control.MOUSE_FILTER_IGNORE
```

---

# PASS 10 — STORY FLAG CONSISTENCY / GAME PROGRESSION

---

### 10.1 · `elara_truth`, `elara_confused`, `elara_dismissed` — Defined but Never Set
**Severity:** HIGH (dead flags — progression may depend on them)  
**File:** [scripts/game_manager.gd](scripts/game_manager.gd#L150-L152)

```gdscript
# Chapter 1 choice flags
"elara_truth": false,
"elara_confused": false,
"elara_dismissed": false,
```

These three flags are defined in `story_flags` but **`set_story_flag` is never called for any of them** anywhere in the codebase. The actual Elara choice flags used by ch1 scripts are:

```gdscript
"ch1_elara_trusted": false,    # line 155
"ch1_elara_distrusted": false,  # line 156
"ch1_elara_cautious": false,    # line 157
```

The `elara_truth/confused/dismissed` flags appear to be an earlier naming convention that was superseded but never cleaned up.

**Suggested fix:** Remove the dead flags from `story_flags` to avoid confusion:
```gdscript
# Remove these three lines:
# "elara_truth": false,
# "elara_confused": false,
# "elara_dismissed": false,
```

---

### 10.2 · `ch1_glitch_crater_complete` — Checked in UI but Never Set During Gameplay
**Severity:** CRITICAL (broken progression display)  
**File:** [scripts/ui/pause_screen.gd](scripts/ui/pause_screen.gd#L550) + [scripts/ui/status_window.gd](scripts/ui/status_window.gd#L216)

Two UI scripts check this flag to update map/location display:

```gdscript
# pause_screen.gd line 550
elif GameManager.story_flags.get("ch1_glitch_crater_complete", false):

# status_window.gd line 216
elif flags.get("ch1_glitch_crater_complete", false):
```

**But `set_story_flag("ch1_glitch_crater_complete", true)` is never called anywhere in the codebase.** A grep for `set_story_flag.*ch1_glitch_crater` returns zero matches. The flag only appears in `main_menu.gd` debug save data (hardcoded to `true` for chapter-skip saves).

This means the map display in PauseScreen and the location display in StatusWindow will **never** reflect the glitch crater section being complete during normal gameplay.

**Suggested fix:** In the glitch crater scene's completion logic (likely `ch1_glitch_crater.gd`), add:
```gdscript
GameManager.set_story_flag("ch1_glitch_crater_complete", true)
```

---

### 10.3 · `ch2_clock_tower_unlocked` — Defined but Never Set
**Severity:** HIGH (gating flag never triggers)  
**File:** [scripts/game_manager.gd](scripts/game_manager.gd#L180)

```gdscript
"ch2_clock_tower_unlocked": false,
```

This flag is defined but `set_story_flag("ch2_clock_tower_unlocked", true)` is never called anywhere. The clock tower entrance in `ch2_ironhold_city.gd` may be intended to check this flag for access gating, but since it's never set, the clock tower would remain permanently locked (or the gate check was never implemented).

**Suggested fix:** Set this flag when the player completes the underground section:
```gdscript
# In ch2_underground completion logic:
GameManager.set_story_flag("ch2_underground_complete", true)
GameManager.set_story_flag("ch2_clock_tower_unlocked", true)
```

---

### 10.4 · `elara_met` Set in `oakhaven.gd` — Redundant with `ch1_elara_glitch_witch_met`
**Severity:** MEDIUM (duplicate tracking)  
**File:** [scripts/exploration/oakhaven.gd](scripts/exploration/oakhaven.gd#L194-L195) + [scripts/game_manager.gd](scripts/game_manager.gd#L134)

```gdscript
# oakhaven.gd line 194-195
if body.name == "Player" and not GameManager.story_flags.get("elara_met", false):
    GameManager.set_story_flag("elara_met", true)
```

But the canonical Elara meeting scene (`ch1_elara_meeting.gd`) sets a **different** flag: `ch1_elara_glitch_witch_met`. This means there are two independent flags tracking the same narrative event:
- `elara_met` (set in oakhaven proximity detection)
- `ch1_elara_glitch_witch_met` (set in the actual meeting cutscene)

If any script checks `elara_met` expecting it to mean "the full meeting happened," it's incorrect — the player might have merely entered the proximity area without completing the meeting.

**Suggested fix:** Consolidate on one flag. Use `ch1_elara_glitch_witch_met` everywhere and remove `elara_met`, or make `elara_met` set only after the full meeting sequence.

---

### 10.5 · `ch1_complete` Is Set but Gating Uses `ch1_shatter_witnessed` Instead
**Severity:** MEDIUM (misleading flag usage)  
**File:** [scripts/chapter1/ch1_shatter_transition.gd](scripts/chapter1/ch1_shatter_transition.gd#L492) + [scripts/ui/pause_screen.gd](scripts/ui/pause_screen.gd#L492)

`ch1_shatter_transition.gd` sets both flags:
```gdscript
GameManager.set_story_flag("ch1_complete", true)  # line 492
```

But Chapter 2 entry and progression checks primarily use `ch1_shatter_witnessed` rather than `ch1_complete`. The `ch1_complete` flag is only checked by `pause_screen.gd` line 492 to determine whether to show Chapter 2 map content. This inconsistency means:
- If `ch1_shatter_witnessed` is set but `ch1_complete` isn't (theoretically possible if the shatter transition script changes), the player enters Ch2 but the pause map still shows Ch1 layout.
- The semantic difference between "shatter witnessed" and "chapter complete" is unclear.

**Suggested fix:** Pick one canonical "chapter 1 done" flag and use it consistently for both gating and UI.

---

### 10.6 · `ch2_arena_complete` Used in Debug Save but Not Defined in `story_flags`
**Severity:** LOW  
**File:** [scripts/main_menu.gd](scripts/main_menu.gd#L319) + [scripts/game_manager.gd](scripts/game_manager.gd#L130-L190)

The debug save data in `main_menu.gd` references `ch2_arena_complete`:
```gdscript
"flags": {..., "ch2_arena_complete": true, ...}
```

But the `story_flags` dictionary only defines tier-specific flags:
```gdscript
"ch2_arena_bronze_complete": false,
"ch2_arena_silver_complete": false,
"ch2_arena_gold_complete": false,
"ch2_arena_platinum_complete": false,
```

There is no `ch2_arena_complete` aggregate flag. Loading this debug save will create a flag that no script ever checks for, while the actual tier-specific flags remain `false`.

**Suggested fix:** Either add `ch2_arena_complete` to `story_flags` and set it when the arena storyline concludes, or update the debug save to set the individual tier flags.

---

### 10.7 · Full Progression Path Audit — Flag Chain Verification

Below is the expected progression with flag chain status:

```
PROLOGUE
  ├─ Flight 707 → Crash Sequence → plane_crash_completed ✓ (set in crash_sequence.gd)
  
CHAPTER 1
  ├─ Awakening        → ch1_awakening_complete        ✓ (set in ch1_glitch_crater.gd)
  ├─ Glitch Crater    → ch1_glitch_crater_complete     ✗ NEVER SET (see 10.2)
  ├─ Elara Meeting    → ch1_elara_glitch_witch_met     ✓
  │                   → ch1_data_vision_unlocked       ✓
  ├─ Path to Oakhaven → ch1_oakhaven_entered           ✓
  ├─ Oakhaven         → elara_met                      ⚠ REDUNDANT (see 10.4)
  │                   → root_access_unlocked           ✓
  ├─ Tutorial Knight  → ch1_tutorial_knight_defeated    ✓
  │                   → source_key_fragment_1           ✓
  ├─ Shatter Event    → ch1_shatter_witnessed           ✓
  │                   → ch1_complete                    ✓
  └─ Transition       → scene change to Ch2            ✓

CHAPTER 2
  ├─ Ironhold Gate    → ch2_ironhold_entered            ✓
  ├─ Arena            → ch2_arena_*_complete            ✓ (tier-specific)
  │                   → ch2_arena_complete              ✗ NOT DEFINED (see 10.6)
  ├─ Underground      → ch2_underground_complete        ✓
  │                   → ch2_clock_tower_unlocked        ✗ NEVER SET (see 10.3)
  ├─ Clock Tower      → ch2_clock_tower_complete        ? (script exists but untested)
  ├─ Administrator    → ch2_administrator_proxy_defeated ✓ (defined)
  └─ Chapter End      → ch2_complete                    ✓ (defined)
```

**Summary:** Three flags in the main progression chain are **never set** during gameplay (`ch1_glitch_crater_complete`, `ch2_clock_tower_unlocked`, `ch2_arena_complete`), meaning UI displays and potential gating logic that depend on them will silently fail.

---

# SUMMARY TABLE

| ID | Severity | Category | Issue |
|----|----------|----------|-------|
| 7.1 | HIGH | Input | `jump` and `ui_accept` both map to Space — dual processing |
| 7.2 | HIGH | Input | `oakhaven.gd` uses raw KEY_SPACE/KEY_ENTER instead of input actions |
| 7.3 | MEDIUM | Input | `ch2_chapter_end.gd` uses raw KEY_SPACE |
| 7.4 | HIGH | Input | `combat_arena.gd` _input has no guards or event consumption |
| 7.5 | MEDIUM | Input | Multiple scene _input handlers are empty stubs that don't consume |
| 7.6 | MEDIUM | Input | `level_up_ui.gd` uses Input polling in _process — no consumption |
| 7.7 | MEDIUM | Input | `player_combat.gd` only guards jump for dialogue, not other actions |
| 7.8 | LOW | Input | `game_over.gd` uses `ui_cancel` which isn't explicitly defined |
| 8.1 | CRITICAL | Autoload | `inventory_system._ready()` calls SFXManager before it exists |
| 8.2 | LOW | Autoload | `scene_transition_manager` calls SFXManager at runtime (safe but fragile) |
| 8.3 | NONE | Autoload | `glitch_overlay` → GameManager signal connection (verified safe) |
| 8.4 | NONE | Autoload | `level_up_ui` → GameManager signal connection (verified safe) |
| 8.5 | MEDIUM | Autoload | 18 autoloads is excessive — consider consolidation |
| 8.6 | MEDIUM | Autoload | Multiple PROCESS_MODE_ALWAYS autoloads fight for input while paused |
| 9.1 | HIGH | UI | No mutual exclusion between 5 modal UI panels |
| 9.2 | MEDIUM | UI | PauseScreen and DialogueManager both use layer 100 |
| 9.3 | HIGH | UI | `status_window.gd` reads wrong key `"perfect_deletes"` — always 0 |
| 9.4 | HIGH | UI | `pause_screen.gd` reads wrong key `"perfect_deletes"` — always 0 |
| 9.5 | LOW | UI | ASCII art layout breaks with non-monospace fonts |
| 9.6 | LOW | UI | InteractionPrompt at layer 10 — too low |
| 9.7 | MEDIUM | UI | mouse_filter not set on non-interactive UI children |
| 10.1 | HIGH | Flags | `elara_truth/confused/dismissed` defined but never set |
| 10.2 | CRITICAL | Flags | `ch1_glitch_crater_complete` checked in UI but never set |
| 10.3 | HIGH | Flags | `ch2_clock_tower_unlocked` defined but never set |
| 10.4 | MEDIUM | Flags | `elara_met` redundant with `ch1_elara_glitch_witch_met` |
| 10.5 | MEDIUM | Flags | `ch1_complete` vs `ch1_shatter_witnessed` inconsistent gating |
| 10.6 | LOW | Flags | `ch2_arena_complete` in debug save but not in story_flags dict |
| 10.7 | — | Flags | Full progression chain audit (3 broken links identified) |

**Critical:** 2 · **High:** 9 · **Medium:** 10 · **Low:** 5

---
*Audit generated from full codebase analysis. All line numbers verified against current source.*
