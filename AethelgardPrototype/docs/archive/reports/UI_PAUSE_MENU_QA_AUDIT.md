# UI / PAUSE / MENU SYSTEMS — QA BUG AUDIT

**Scope:** `pause_screen.gd`, `status_window.gd`, `main_menu.gd`, `shop_system.gd`, UIStack integration, CanvasLayer ordering, input blocking  
**Engine:** Godot 4.6 GDScript  
**Date:** 2025-07-15

---

## LAYER MAP (Reference)

| Layer | System |
|-------|--------|
| 10 | InteractionPrompt |
| 50 | Region HUDs |
| 80 | Tutorial UI, Cinematic letterbox |
| 85 | Combat speed lines, ProgressionBreadcrumb |
| 90 | Combat HUD, LevelUpUI, WorldMapUI |
| 95 | **CompletionTracker**, **GlitchOverlay**, GameJuice combo |
| 98 | **ShopSystem**, Achievements popup |
| 99 | **StatusWindow**, CutsceneManager fade |
| 100 | **DialogueManager**, **LoreJournal**, GameManager save indicator |
| 101 | CutsceneDirector flash |
| 110 | **PauseScreen** |
| 120 | **CreditsScreen** |
| 200 | SceneTransitions |

---

## BUG #1 — CompletionTracker unconditionally unpauses the game tree

**Severity:** CRITICAL  
**Files:** `scripts/ui/completion_tracker.gd` L37-42, `scripts/ui/pause_screen.gd` L1247-1250  
**Repro:** Open Pause → click "Completion" → close CompletionTracker → game resumes behind the still-visible pause screen  

**Root Cause:**  
`PauseScreen._open_completion_from_pause()` (line 1249) calls `CompletionTracker.show_tracker()`, which sets `get_tree().paused = true` (line 37) — redundant because the tree is already paused. When the player presses any key to dismiss it, `hide_tracker()` (line 40) unconditionally sets `get_tree().paused = false`. The pause screen is still visible and `is_paused` remains `true`, but the game tree is now running.

**Fix:**

```gdscript
# completion_tracker.gd — replace lines 33-42

var _was_paused_before: bool = false

func show_tracker() -> void:
	_build_ui()
	visible = true
	_visible = true
	_was_paused_before = get_tree().paused
	get_tree().paused = true

func hide_tracker() -> void:
	visible = false
	_visible = false
	if not _was_paused_before:
		get_tree().paused = false
	# Clean up children
	for c in get_children():
		c.queue_free()
```

---

## BUG #2 — CompletionTracker bypasses UIStack

**Severity:** HIGH  
**File:** `scripts/ui/completion_tracker.gd` L33-42  
**Repro:** While the shop (or any UIStack modal) is open, call `CompletionTracker.show_tracker()` from console or code — it opens with no guard.

**Root Cause:**  
`show_tracker()` and `hide_tracker()` never call `UIStack.try_open()` / `UIStack.close()`. The tracker can overlap any other modal panel.

**Fix:**

```gdscript
# completion_tracker.gd — show_tracker()
func show_tracker() -> void:
	if has_node("/root/UIStack") and not UIStack.try_open("completion_tracker"):
		return
	_build_ui()
	visible = true
	_visible = true
	_was_paused_before = get_tree().paused
	get_tree().paused = true

# completion_tracker.gd — hide_tracker()
func hide_tracker() -> void:
	visible = false
	_visible = false
	if has_node("/root/UIStack"):
		UIStack.close("completion_tracker")
	if not _was_paused_before:
		get_tree().paused = false
	for c in get_children():
		c.queue_free()
```

---

## BUG #3 — CreditsScreen bypasses UIStack & unconditionally unpauses

**Severity:** HIGH  
**File:** `scripts/ui/credits_screen.gd` L96-101, L250-265  
**Repro:** Open pause screen → trigger credits somehow → credits close → game unpauses behind visible pause screen. Also, credits can be shown while another modal is active.

**Root Cause:**  
`show_credits()` sets `get_tree().paused = true` and `_finish_credits()` sets `get_tree().paused = false`, with no UIStack integration and no check whether the tree was already paused by another UI.

**Fix:**

```gdscript
# credits_screen.gd — add state tracking
var _was_paused_before: bool = false

func show_credits(return_to_menu: bool = true) -> void:
	if _is_showing:
		return
	if has_node("/root/UIStack") and not UIStack.try_open("credits"):
		return
	_is_showing = true
	visible = true
	_was_paused_before = get_tree().paused
	get_tree().paused = true
	_build_credits_ui()
	_start_scroll(return_to_menu)

# In _finish_credits, replace the `get_tree().paused = false` lines:
# (both in the tween callback ~L257 and the else branch ~L265)

# Replace:  get_tree().paused = false
# With:
	if not _was_paused_before:
		get_tree().paused = false
	if has_node("/root/UIStack"):
		UIStack.close("credits")
```

---

## BUG #4 — LoreJournal bypasses UIStack entirely

**Severity:** HIGH  
**File:** `scripts/ui/lore_journal.gd` L126-140  
**Repro:** Open pause screen → press L → LoreJournal opens on top of the pause UI at the same layer as dialogue (100). The pause screen is still registered as the active modal.

**Root Cause:**  
`open_journal()` and `close_journal()` have zero UIStack calls. The journal can open over any active modal.

**Fix:**

```gdscript
func open_journal() -> void:
	if _is_open:
		return
	if has_node("/root/UIStack") and not UIStack.try_open("lore_journal"):
		return
	_is_open = true
	_build_journal_ui()
	journal_opened.emit()

func close_journal() -> void:
	if not _is_open:
		return
	_is_open = false
	if has_node("/root/UIStack"):
		UIStack.close("lore_journal")
	if _journal_panel and is_instance_valid(_journal_panel):
		_journal_panel.queue_free()
		_journal_panel = null
	journal_closed.emit()
```

---

## BUG #5 — LoreJournal CanvasLayer conflicts with DialogueManager (both layer 100)

**Severity:** MEDIUM  
**Files:** `scripts/ui/lore_journal.gd` L148, `scripts/dialogue_manager.gd` (CanvasLayer layer 100)  
**Repro:** Advance dialogue → press L → journal renders on top of (or interleaved with) dialogue text.

**Root Cause:**  
Both systems create CanvasLayers at `layer = 100`. Godot renders same-layer CanvasLayers in tree order, which is non-deterministic for autoloads. Even with UIStack fix (Bug #4), the layer collision still causes z-fighting if both are visible during a brief transition.

**Fix:**

```gdscript
# lore_journal.gd — _build_journal_ui(), line 148
# Change:  layer.layer = 100
# To:
layer.layer = 105  # Above dialogue (100), below pause (110)
```

---

## BUG #6 — LoreJournal uses raw keycode instead of input action

**Severity:** MEDIUM  
**File:** `scripts/ui/lore_journal.gd` L33-36  
**Repro:** Player rebinds keys in Options → the L key still toggles the journal regardless of rebinding.

**Root Cause:**  
The `_input()` handler checks `event.keycode == KEY_L` directly instead of using an InputMap action. It also has a confusing double-check: first checking `status_window` action AND `KEY_L`, then falling through to a raw `KEY_L` check.

```gdscript
# Current problematic code:
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("status_window") and Input.is_key_pressed(KEY_L):
		toggle_journal()
	elif event is InputEventKey and event.pressed and event.keycode == KEY_L:
		toggle_journal()
```

**Fix:**  
Register a `lore_journal` action in project settings and use it:

```gdscript
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("lore_journal"):
		toggle_journal()
```

If you cannot add a new action yet, at minimum remove the nonsensical first branch and block during other modals:

```gdscript
func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_L:
		if has_node("/root/UIStack") and UIStack.is_any_open():
			return
		if has_node("/root/DialogueManager") and DialogueManager.is_active:
			return
		toggle_journal()
```

---

## BUG #7 — ShopSystem.close_shop() unconditionally unpauses

**Severity:** HIGH  
**File:** `scripts/shop_system.gd` L543-559  
**Repro:** Hypothetical — if shop were ever opened while another system had the tree paused (unlikely due to UIStack, but `force_open` exists), closing the shop would unpause the tree unexpectedly.

**Root Cause:**  
`close_shop()` line 559 does `get_tree().paused = false` without checking whether the tree was already paused before the shop opened.

**Fix:**

```gdscript
# shop_system.gd — add at class level:
var _was_paused_before_shop: bool = false

# In open_shop(), before line 506:
_was_paused_before_shop = get_tree().paused

# In close_shop(), replace line 559:
# Old: get_tree().paused = false
# New:
if not _was_paused_before_shop:
	get_tree().paused = false
```

---

## BUG #8 — NG+ button duplicated on every _ready() call

**Severity:** MEDIUM  
**File:** `scripts/main_menu.gd` L73-104  
**Repro:** Return to main menu multiple times from in-game → each time `_ready()` runs → `_check_ng_plus_availability()` appends another "NEW GAME+" button.

**Root Cause:**  
`_check_ng_plus_availability()` creates a new `Button` and inserts it into the VBoxContainer without checking whether an "NGPlusButton" already exists.

**Fix:**

```gdscript
# main_menu.gd — add at the start of _check_ng_plus_availability(), after the return guard:
func _check_ng_plus_availability() -> void:
	# ... existing ng_plus_available checks ...
	if not GameManager.ng_plus_available:
		return
	var vbox = get_node_or_null("VBoxContainer")
	if not vbox:
		return
	# ── FIX: prevent duplicate button ──
	if vbox.get_node_or_null("NGPlusButton"):
		return
	var new_game_btn = vbox.get_node_or_null("NewGameButton")
	# ... rest unchanged ...
```

---

## BUG #9 — StatusWindow has no game-state guards

**Severity:** MEDIUM  
**File:** `scripts/ui/status_window.gd` L35-38  
**Repro:** Enter combat → press I → status window opens mid-fight, stealing focus from combat UI.

**Root Cause:**  
`toggle_status()` only checks `ch1_oakhaven_entered`. It never checks `GameManager.current_state` for COMBAT, DIALOGUE, CUTSCENE, or GAME_OVER, meaning the status window can open during active gameplay states where it shouldn't.

**Fix:**

```gdscript
# status_window.gd — toggle_status(), add after the Oakhaven lock check:
func toggle_status() -> void:
	if not GameManager.story_flags.get("ch1_oakhaven_entered", false):
		return
	# Block during active gameplay states
	if GameManager.current_state in [
		GameManager.GameState.COMBAT,
		GameManager.GameState.DIALOGUE,
		GameManager.GameState.CUTSCENE,
		GameManager.GameState.GAME_OVER,
	]:
		return
	# ... rest unchanged ...
```

---

## BUG #10 — PauseScreen can open during COMBAT

**Severity:** MEDIUM  
**File:** `scripts/ui/pause_screen.gd` L103-114  
**Repro:** During a boss fight → press ESC → game pauses, player can equip/unequip charms mid-combat, breaking combat balance.

**Root Cause:**  
`_input()` only blocks pause for `DialogueManager.is_active` and `cutscene_blocked` meta. It has no check for `GameManager.current_state == COMBAT`. The charm equip system in pause_screen even has combat-state text feedback ("Cannot change charms during combat!"), implying this state was anticipated but the gate was only put on the charm action, not on pause opening.

**Fix (option A — block pause in combat):**

```gdscript
# pause_screen.gd — _input(), after the dialogue check:
		if has_node("/root/DialogueManager") and DialogueManager.is_active:
			return
		# Block pausing during combat
		if GameManager.current_state == GameManager.GameState.COMBAT:
			return
```

**Fix (option B — if you want pause in combat but no charm changes):**  
Keep the current behavior but ensure _refresh_charms_tab() disables all equip/unequip buttons when `GameManager.current_state == COMBAT`. This is partially implemented already via text feedback, but the buttons are still functional.

---

## BUG #11 — GlitchOverlay and CompletionTracker share layer 95

**Severity:** LOW  
**File:** `scripts/ui/completion_tracker.gd` L28, `scripts/ui/glitch_overlay.gd` (layer 95)  
**Repro:** Glitch effects play while CompletionTracker is open → visual corruption bleeds through/overlaps the tracker panel.

**Root Cause:**  
Both use `layer = 95`. The GlitchOverlay uses `mouse_filter = IGNORE` so it doesn't steal input, but visual artifacts appear over the tracker.

**Fix:**

```gdscript
# completion_tracker.gd — change layer to 96 or higher
layer = 96  # Above glitch overlay (95)
```

---

## BUG #12 — GameManager save indicator conflicts with DialogueManager (both layer 100)

**Severity:** LOW  
**File:** `scripts/game_manager.gd` (save indicator CanvasLayer at 100), `scripts/dialogue_manager.gd` (CanvasLayer at 100)  
**Repro:** Auto-save triggers during dialogue → save indicator briefly z-fights with dialogue panel.

**Root Cause:**  
Same layer value (100) for both CanvasLayers. Tree order determines which renders on top.

**Fix:**

```gdscript
# game_manager.gd — save indicator layer
# Change from 100 to 102 (above dialogue, below lore journal's new value of 105)
_save_indicator_layer.layer = 102
```

---

## BUG #13 — StatusWindow hardcoded viewport position breaks at non-720p resolutions

**Severity:** LOW  
**File:** `scripts/ui/status_window.gd` L220-223  
**Repro:** Run at 1080p or 4K resolution → status panel is positioned based on 1280×720 and appears misaligned.

**Root Cause:**  
```gdscript
var vp_size = get_viewport().get_visible_rect().size if get_viewport() else Vector2(1280, 720)
panel.position = Vector2(vp_size.x - 415, 20)
```
`_build_status_ui()` runs in `_ready()`, so `vp_size` is computed once and never updated when the window is resized.

**Fix:**  
Use anchors instead of absolute positioning, or listen for `get_viewport().size_changed` to reposition.

```gdscript
# status_window.gd — in _build_status_ui(), replace position logic:
panel.set_anchors_preset(Control.PRESET_CENTER_RIGHT)
panel.offset_left = -420
panel.offset_top = -320
panel.offset_right = -20
panel.offset_bottom = 320
```

---

## BUG #14 — CompletionTracker hint label position hardcoded

**Severity:** LOW  
**File:** `scripts/ui/status_window.gd` L285  
**Repro:** Non-720p resolution → the "[Press I for Status Window]" hint appears at wrong position.

**Root Cause:**  
`hint_label.position = Vector2(460, 680)` — hardcoded for 1280×720.

**Fix:**

```gdscript
# Use anchors instead:
hint_label.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
hint_label.offset_top = -40
hint_label.offset_bottom = 0
hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
```

---

## BUG #15 — LoreJournal doesn't block input during DialogueManager/Combat

**Severity:** MEDIUM  
**File:** `scripts/ui/lore_journal.gd` L33-36  
**Repro:** During dialogue → press L → journal opens, obscuring dialogue. During combat → press L → journal opens, obscuring combat HUD.

**Root Cause:**  
The `_input()` handler has no state guards.

**Fix:**  
(Partially addressed by Bug #4 UIStack fix. Additional guard:)

```gdscript
func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_L:
		if has_node("/root/DialogueManager") and DialogueManager.is_active:
			return
		if GameManager.current_state in [
			GameManager.GameState.COMBAT,
			GameManager.GameState.CUTSCENE,
			GameManager.GameState.GAME_OVER,
		]:
			return
		toggle_journal()
```

---

## BUG #16 — CreditsScreen uses raw keycodes instead of input actions

**Severity:** LOW  
**File:** `scripts/ui/credits_screen.gd` L236-241  
**Repro:** Player rebinds Enter/Escape → credits skip doesn't respect new bindings.

**Root Cause:**  
```gdscript
if event.keycode == KEY_ENTER or event.keycode == KEY_ESCAPE:
```
Hard-coded keycodes instead of `ui_accept` / `ui_cancel` actions.

**Fix:**

```gdscript
if event.is_action_pressed("ui_accept") or event.is_action_pressed("ui_cancel"):
	_finish_credits()
	get_viewport().set_input_as_handled()
```

---

## BUG #17 — LoreJournal creates orphaned CanvasLayer nodes on repeated open/close

**Severity:** MEDIUM  
**File:** `scripts/ui/lore_journal.gd` L143-148  
**Repro:** Open journal → close → open again → repeat → CanvasLayer children accumulate.

**Root Cause:**  
`_build_journal_ui()` creates a new `CanvasLayer` child (L145-146) and adds `_journal_panel` to it. But `close_journal()` only frees `_journal_panel` — NOT the CanvasLayer parent. Each open/close cycle leaks one CanvasLayer node.

```gdscript
# Current code:
func _build_journal_ui() -> void:
	if _journal_panel and is_instance_valid(_journal_panel):
		_journal_panel.queue_free()
	var layer = CanvasLayer.new()
	layer.layer = 100
	add_child(layer)                    # added as child of LoreJournal node
	_journal_panel = PanelContainer.new()
	# ...
	layer.add_child(_journal_panel)     # panel is child of layer
```

When `close_journal()` frees `_journal_panel`, the parent CanvasLayer remains in the tree.

**Fix:**

```gdscript
# Add a class variable:
var _journal_layer: CanvasLayer = null

func _build_journal_ui() -> void:
	# Clean up previous layer entirely
	if _journal_layer and is_instance_valid(_journal_layer):
		_journal_layer.queue_free()

	_journal_layer = CanvasLayer.new()
	_journal_layer.layer = 105  # (also fixes Bug #5 layer conflict)
	add_child(_journal_layer)

	_journal_panel = PanelContainer.new()
	# ... rest of UI building ...
	_journal_layer.add_child(_journal_panel)

func close_journal() -> void:
	if not _is_open:
		return
	_is_open = false
	if has_node("/root/UIStack"):
		UIStack.close("lore_journal")
	if _journal_layer and is_instance_valid(_journal_layer):
		_journal_layer.queue_free()
		_journal_layer = null
	_journal_panel = null
	journal_closed.emit()
```

---

## SUMMARY TABLE

| # | Severity | File | Short Description |
|---|----------|------|-------------------|
| 1 | **CRITICAL** | completion_tracker.gd | Unconditionally unpauses tree (desyncs with pause screen) |
| 2 | **HIGH** | completion_tracker.gd | Bypasses UIStack — can overlap other modals |
| 3 | **HIGH** | credits_screen.gd | Bypasses UIStack & unconditionally unpauses |
| 4 | **HIGH** | lore_journal.gd | Bypasses UIStack entirely |
| 5 | **MEDIUM** | lore_journal.gd | CanvasLayer 100 collides with DialogueManager |
| 6 | **MEDIUM** | lore_journal.gd | Raw KEY_L keycode ignores key rebinding |
| 7 | **HIGH** | shop_system.gd | close_shop() unconditionally unpauses |
| 8 | **MEDIUM** | main_menu.gd | NG+ button duplicated on each _ready() |
| 9 | **MEDIUM** | status_window.gd | No game-state guards (opens during combat/cutscene) |
| 10 | **MEDIUM** | pause_screen.gd | Opens during COMBAT, allows charm changes |
| 11 | **LOW** | completion_tracker.gd | Layer 95 collision with GlitchOverlay |
| 12 | **LOW** | game_manager.gd | Save indicator layer 100 collides with dialogue |
| 13 | **LOW** | status_window.gd | Hardcoded 720p position breaks at other resolutions |
| 14 | **LOW** | status_window.gd | Hint label hardcoded position |
| 15 | **MEDIUM** | lore_journal.gd | No state guards (opens during dialogue/combat) |
| 16 | **LOW** | credits_screen.gd | Raw keycodes ignore rebinding |
| 17 | **MEDIUM** | lore_journal.gd | CanvasLayer leak on repeated open/close |

**Total: 1 CRITICAL, 4 HIGH, 7 MEDIUM, 5 LOW**
