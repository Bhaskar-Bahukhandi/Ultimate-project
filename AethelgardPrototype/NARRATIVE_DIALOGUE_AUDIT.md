# NARRATIVE / DIALOGUE SYSTEMS AUDIT REPORT
## Aethelgard Prototype — Godot 4.6 GDScript

**Auditor:** GitHub Copilot  
**Date:** 2026-03-01  
**Files Audited:**
- `scripts/dialogue_manager.gd` (773 lines) — Core dialogue system  
- `scripts/cutscene/cutscene_manager.gd` (910 lines) — Beat-based cutscene engine  
- `scripts/cutscene/cutscene_director.gd` (874 lines) — Fluent cutscene builder  
- `scripts/choice_consequences.gd` (439 lines) — Choice buff/debuff tracking  
- `scripts/game_manager.gd` (905 lines) — Story flags, relationships, save/load  
- `scripts/chapter1/ch1_elara_meeting.gd` (758 lines) — Ch1 Elara dialogue  
- `scripts/chapter2/ch2_seraphina_choice.gd` (500 lines) — Ch2 branching choice  
- `scripts/chapter3/ch3_ending.gd` (290 lines) — Ch3 SOVEREIGN confrontation  

**Note:** `scripts/ui/dialogue_box.gd` does not exist. The dialogue UI is built entirely programmatically inside `dialogue_manager.gd`.

---

## SEVERITY LEGEND
- 🔴 **CRITICAL** — Crash, data loss, or stuck state  
- 🟠 **HIGH** — Major UX problem or logic bug  
- 🟡 **MEDIUM** — Polish issue, minor bug  
- 🟢 **LOW** — Enhancement, quality-of-life  

---

## 1. DIALOGUE FLOW ISSUES

### 1.1 🔴 CRITICAL — Timer-based typewriter creates orphaned coroutines on scene change
**File:** `scripts/dialogue_manager.gd`, lines 136–153  
**Current behavior:** The `say()` function uses `await get_tree().create_timer(delay).timeout` in a `while` loop for typewriter effect. If the scene changes mid-typewriter, `get_tree()` may return null before the `is_inside_tree()` check runs, causing an error. The `create_timer` also creates a SceneTreeTimer that is NOT freed when its parent is freed — it persists until timeout.  
**Impact:** Potential null reference errors on fast scene transitions.  
**Fix:**
```gdscript
# In say(), replace the typewriter loop (lines 136-153):
	while chars_shown < total_chars:
		if _skip_typing or _skip_all_requested:
			break
		chars_shown += 1
		_text_label.visible_characters = chars_shown
		if chars_shown % 2 == 0 and has_node("/root/SFXManager"):
			SFXManager.play_random(["text_tick", "text_tick_low", "text_tick_high"])
		var delay = 1.0 / TYPE_SPEED
		if Input.is_action_pressed("ui_accept") or Input.is_action_pressed("jump"):
			delay = 1.0 / TYPE_FAST_SPEED
		# Guard tree access before creating timer
		if not is_inside_tree():
			return
		await get_tree().create_timer(delay).timeout
		if not is_inside_tree():
			return
```

### 1.2 🟠 HIGH — No dialogue queue / batching system
**File:** `scripts/dialogue_manager.gd`  
**Current behavior:** Each `say()` call is awaited individually in chapter scripts, meaning every dialogue line requires `await DialogueManager.say(...)` + `if not is_inside_tree(): return` (2 lines per dialogue line). This creates massive script bloat (see ch2_seraphina_choice.gd — 30+ identical guard patterns).  
**Missing feature:** A batch dialogue API that accepts an array of lines.  
**Fix — add to dialogue_manager.gd after the `say()` function (after ~line 187):**
```gdscript
## Play a sequence of dialogue lines with automatic cleanup.
## Each entry: {"speaker": String, "text": String, "color": Color (opt), "auto_advance": bool (opt)}
func say_sequence(lines: Array[Dictionary]) -> void:
	for line in lines:
		if not is_inside_tree() or _skip_all_requested:
			return
		var speaker: String = line.get("speaker", "")
		var text: String = line.get("text", "")
		var color: Color = line.get("color", Color(-1, -1, -1))
		var auto_adv: bool = line.get("auto_advance", false)
		await say(speaker, text, color, auto_adv)
		if not is_inside_tree():
			return
```

### 1.3 🟡 MEDIUM — TYPE_SPEED is `var` but should be configurable at runtime
**File:** `scripts/dialogue_manager.gd`, line 61  
**Current behavior:** `TYPE_SPEED` is `var` (mutable) but there's no settings menu integration. `TYPE_FAST_SPEED` is `const`, preventing runtime adjustment.  
**Fix — make both configurable:**
```gdscript
# Line 61-62: change TYPE_FAST_SPEED to var
var TYPE_SPEED: float = 35.0
var TYPE_FAST_SPEED: float = 120.0  # Was const — now configurable from settings

## Call from settings menu to adjust text speed
func set_text_speed(normal: float, fast: float) -> void:
	TYPE_SPEED = clampf(normal, 10.0, 200.0)
	TYPE_FAST_SPEED = clampf(fast, normal + 10.0, 500.0)
```

### 1.4 🟡 MEDIUM — Auto-advance timing not great for short vs. long lines
**File:** `scripts/dialogue_manager.gd`, line 158  
**Current behavior:** `var read_time = clampf(text.length() * 0.035, 2.5, 8.0)` — the max of 8 seconds is too short for very long lines (200+ chars like Seraphina's monologues would need ~7s but BBCode tags inflate `text.length()`).  
**Fix:**
```gdscript
# Line 158 — strip BBCode before calculating read time
	if auto_advance:
		var stripped_text = _text_label.get_parsed_text()  # Gets text without BBCode
		var read_time = clampf(stripped_text.length() * 0.04, 2.5, 12.0)
```

---

## 2. CHARACTER PORTRAIT ISSUES

### 2.1 🟠 HIGH — No expression system for portraits
**File:** `scripts/dialogue_manager.gd`, lines 644–690 (`_update_portrait`)  
**Current behavior:** Portraits are either a solid `ColorRect` with an initial letter, or a single texture from `AssetManager.get_portrait_texture(speaker)`. There's no way to pass an expression (happy, angry, surprised) to change the portrait mid-conversation.  
**Impact:** Static portraits during highly emotional scenes (Elara's vulnerability, Seraphina's confrontation). The cutscene system has an `expression` beat type, but it only affects world sprites — not the dialogue box portrait.  
**Fix — add expression support to `say()`:**
```gdscript
# Modify say() signature (line 114):
func say(speaker: String, text: String, color := Color(-1, -1, -1), auto_advance: bool = false, expression: String = "neutral") -> void:
	# ... existing code ...
	_update_portrait(speaker, color, expression)
	# ...

# Modify _update_portrait (line 644):
func _update_portrait(speaker: String, color: Color, expression: String = "neutral") -> void:
	if not _portrait_rect:
		return

	var tex: Texture2D = null
	if has_node("/root/AssetManager"):
		# Try expression-specific portrait first
		tex = AssetManager.get_portrait_texture(speaker, expression)
		if not tex:
			tex = AssetManager.get_portrait_texture(speaker)
	# ... rest of existing code ...
```

### 2.2 🟡 MEDIUM — Portrait `ColorRect` has no rounded corners / border
**File:** `scripts/dialogue_manager.gd`, line 580  
**Current behavior:** The portrait placeholder is a plain `ColorRect` — looks very placeholder/dev-mode.  
**Fix — use PanelContainer with StyleBoxFlat:**
```gdscript
# Replace _portrait_rect creation in _build_ui() (line 579-583):
	# Portrait placeholder — styled panel
	var portrait_panel = PanelContainer.new()
	portrait_panel.custom_minimum_size = Vector2(72, 72)
	portrait_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var portrait_style = StyleBoxFlat.new()
	portrait_style.bg_color = Color(0.15, 0.15, 0.2, 0.8)
	portrait_style.border_color = Color(0.0, 0.6, 1.0, 0.4)
	portrait_style.set_border_width_all(1)
	portrait_style.set_corner_radius_all(4)
	portrait_panel.add_theme_stylebox_override("panel", portrait_style)
	hbox.add_child(portrait_panel)
	
	_portrait_rect = ColorRect.new()
	_portrait_rect.custom_minimum_size = Vector2(68, 68)
	_portrait_rect.color = Color(0.3, 0.3, 0.4)
	_portrait_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	portrait_panel.add_child(_portrait_rect)
```

---

## 3. CHOICE SYSTEM ISSUES

### 3.1 🔴 CRITICAL — Race condition: choice buttons accept input during fade-in
**File:** `scripts/dialogue_manager.gd`, lines 365–374  
**Current behavior:** The grace period (`await get_tree().create_timer(0.5).timeout`) prevents stale Space from auto-confirming. However, mouse clicks on the buttons can still fire `_on_choice_pressed` during the 0.3s fade-in tween because `pressed` signal is connected immediately at button creation (line 420).  
**Impact:** Accidental choice selection if player clicks during fade-in animation.  
**Fix — disable buttons during fade-in, enable after grace period:**
```gdscript
# In _build_choice_buttons(), after creating buttons (around line 360):
	for i in range(choices.size()):
		var btn = _create_choice_button(choices[i], i)
		btn.disabled = true  # START disabled
		_choice_container.add_child(btn)
		buttons.append(btn)

	# Fade in
	_choice_container.modulate.a = 0.0
	var tween = create_tween()
	tween.tween_property(_choice_container, "modulate:a", 1.0, 0.3)

	# Grace period
	await get_tree().create_timer(0.5).timeout
	if not is_inside_tree():
		return
	while is_inside_tree() and (Input.is_action_pressed("ui_accept") or Input.is_action_pressed("jump")):
		await get_tree().process_frame
	if not is_inside_tree():
		return
	# Now enable buttons AND focus
	for btn in buttons:
		if is_instance_valid(btn):
			btn.disabled = false
			btn.focus_mode = Control.FOCUS_ALL
	if not buttons.is_empty() and is_instance_valid(buttons[0]):
		buttons[0].grab_focus()
```

### 3.2 🟠 HIGH — Keyboard navigation doesn't wrap around in choice buttons
**File:** `scripts/dialogue_manager.gd`, `_build_choice_buttons()`  
**Current behavior:** Buttons are in a `VBoxContainer` but no `focus_neighbor_top`/`focus_neighbor_bottom` is set. Pressing Up on the first button or Down on the last button does nothing rather than wrapping.  
**Fix — add after the focus_mode loop:**
```gdscript
	# Set focus neighbors for wrapping (add after buttons are enabled)
	if buttons.size() > 1:
		for i in range(buttons.size()):
			if is_instance_valid(buttons[i]):
				var prev_idx = (i - 1) % buttons.size()
				var next_idx = (i + 1) % buttons.size()
				if is_instance_valid(buttons[prev_idx]):
					buttons[i].focus_neighbor_top = buttons[prev_idx].get_path()
				if is_instance_valid(buttons[next_idx]):
					buttons[i].focus_neighbor_bottom = buttons[next_idx].get_path()
```

### 3.3 🟠 HIGH — `choice_selected` signal never emitted from modern API
**File:** `scripts/dialogue_manager.gd`, line 17  
**Current behavior:** Signal `choice_selected(choice_index: int)` is declared but ONLY emitted through the legacy `select_choice()` method (line 462). The modern `show_choices()` API (which all chapter scripts use) never emits it. Any system listening for `choice_selected` will never fire.  
**Fix — emit in `_on_choice_pressed`:**
```gdscript
# Line 422-423, modify _on_choice_pressed:
func _on_choice_pressed(index: int) -> void:
	_choice_result = index
	choice_selected.emit(index)  # ADD: emit for external listeners
	if has_node("/root/SFXManager"):
		SFXManager.play("choice_confirm")  # ADD: audio feedback on selection
```

### 3.4 🟡 MEDIUM — No visual confirmation flash on choice selection
**File:** `scripts/dialogue_manager.gd`, `_on_choice_pressed`  
**Current behavior:** Pressing a choice button immediately sets `_choice_result` and the choice container is destroyed. There's no visual/audio feedback that the choice was registered.  
**Fix — add brief flash before destroying buttons:**
```gdscript
func _on_choice_pressed(index: int) -> void:
	if _choice_result != -1:
		return  # Prevent double-selection
	_choice_result = index
	choice_selected.emit(index)
	if has_node("/root/SFXManager"):
		SFXManager.play("choice_confirm")
	# Flash selected button
	if _choice_container and is_instance_valid(_choice_container):
		var selected_btn = _choice_container.get_child(index + 1)  # +1 for header label
		if selected_btn and selected_btn is Button:
			selected_btn.modulate = Color(1.0, 0.9, 0.4)
```

---

## 4. CUTSCENE INTEGRATION ISSUES

### 4.1 🔴 CRITICAL — CutsceneManager ESC skip leaves dialogue box open
**File:** `scripts/cutscene/cutscene_manager.gd`, lines 901–907  
**Current behavior:** `_unhandled_input` calls `stop_cutscene()` on ESC, which sets `is_playing = false` and unblocks input. But `DialogueManager` may still be in the middle of `say()` — its `while not _advance_requested` loop continues waiting, and the dialogue box stays on screen with no way to dismiss it.  
**Fix — also force-reset DialogueManager:**
```gdscript
# Line 893-895, modify stop_cutscene:
func stop_cutscene() -> void:
	is_playing = false
	_unblock_input()
	# Force-reset dialogue to prevent orphaned dialogue boxes
	if has_node("/root/DialogueManager"):
		DialogueManager.force_reset()
```

### 4.2 🟠 HIGH — CutsceneManager and CutsceneDirector duplicate 90% of code
**File:** Both cutscene files  
**Current behavior:** `cutscene_manager.gd` (910 lines) and `cutscene_director.gd` (874 lines) contain nearly identical implementations of: fade, tint, letterbox, title_card, expression, camera operations, walk animation, input blocking. This is ~600 lines of duplicated code.  
**Impact:** Bug fixes must be applied twice. Divergent behavior over time.  
**Fix:** Extract shared functionality into a `CutsceneBeatExecutor` utility class, or have `CutsceneDirector` delegate to `CutsceneManager` for beat execution. This is a large refactor but prevents long-term divergence:
```gdscript
# scripts/cutscene/cutscene_beat_executor.gd (new file)
class_name CutsceneBeatExecutor

# Move all shared beat handlers here. Both CutsceneManager and 
# CutsceneDirector instantiate this class and delegate to it.
# This eliminates ~600 lines of duplication.
```

### 4.3 🟠 HIGH — `CutsceneManager.handle_tint()` leaks CanvasModulate on skip
**File:** `scripts/cutscene/cutscene_manager.gd`, lines 571–598  
**Current behavior:** `_canvas_modulate` is added to `get_tree().current_scene`. If cutscene is skipped via ESC (sets `is_playing = false`), `_unblock_input()` does clean it up. BUT — if the scene changes before `_unblock_input` runs, the modulate was added as a child of the old scene and gets freed with it, leaving `_canvas_modulate` as a dangling reference.  
**Fix — null-check after scene change:**
```gdscript
# In _unblock_input (line 853), add safety check:
func _unblock_input() -> void:
	_input_blocked = false
	for node in _pre_cutscene_process_mode.keys():
		if is_instance_valid(node):
			node.process_mode = _pre_cutscene_process_mode[node]
	_pre_cutscene_process_mode.clear()
	if has_node("/root/PauseScreen"):
		PauseScreen.set_meta("cutscene_blocked", false)
	# Clean up tint — check validity before freeing
	if _canvas_modulate != null:
		if is_instance_valid(_canvas_modulate):
			_canvas_modulate.queue_free()
		_canvas_modulate = null  # Always null out
```

### 4.4 🟡 MEDIUM — `create_flash_effect()` adds ColorRect to root, not CanvasLayer
**File:** `scripts/cutscene/cutscene_manager.gd`, lines 876-890  
**Current behavior:** `get_tree().root.add_child(flash)` — the flash ColorRect is added directly to root. Its `size` is set to viewport size but it has no anchors, so it won't resize on window resize. Also, it renders below the dialogue CanvasLayer (layer 100).  
**Fix:**
```gdscript
func create_flash_effect(color: Color, duration: float):
	var flash_layer = CanvasLayer.new()
	flash_layer.layer = 98  # Below dialogue (100) but above game
	add_child(flash_layer)
	
	var flash = ColorRect.new()
	flash.color = color
	flash.set_anchors_preset(Control.PRESET_FULL_RECT)
	flash.modulate.a = 0.0
	flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	flash_layer.add_child(flash)
	
	var tween = create_tween()
	tween.tween_property(flash, "modulate:a", 0.8, duration * 0.3)
	tween.tween_property(flash, "modulate:a", 0.0, duration * 0.7)
	await tween.finished
	if not is_inside_tree(): return
	flash_layer.queue_free()
```

---

## 5. STORY FLAG CONSISTENCY ISSUES

### 5.1 🔴 CRITICAL — Mutually exclusive flags are not enforced
**File:** `scripts/game_manager.gd`, `set_story_flag()`  
**Current behavior:** `set_story_flag` just sets `story_flags[flag_name] = value`. There's no enforcement of mutual exclusivity. If a bug sets both `ch1_elara_trusted` AND `ch1_elara_distrusted`, the system won't detect it. `ChoiceConsequences` will apply BOTH buffs.  
**Impact:** Corrupted save state, impossible game states, stacked contradictory buffs.  
**Fix — add mutual exclusion groups:**
```gdscript
# Add to game_manager.gd after DEFAULT_STORY_FLAGS:
const EXCLUSIVE_FLAG_GROUPS: Array[Array] = [
	["ch1_elara_trusted", "ch1_elara_cautious", "ch1_elara_distrusted"],
	["ch1_knight_spared", "ch1_knight_killed"],
	["ch2_seraphina_recruited", "ch2_seraphina_stayed", "ch2_seraphina_rejected"],
	["ch2_data_wraith_absorbed", "ch2_data_wraith_restored", "ch2_data_wraith_destroyed"],
	["ch3_kaelthas_allied", "ch3_kaelthas_refused", "ch3_kaelthas_challenged"],
	["ch3_sovereign_defiant", "ch3_sovereign_regretful", "ch3_sovereign_doubting"],
]

func set_story_flag(flag_name: String, value: bool = true) -> void:
	# Enforce mutual exclusivity
	if value:
		for group in EXCLUSIVE_FLAG_GROUPS:
			if flag_name in group:
				for other_flag in group:
					if other_flag != flag_name and story_flags.get(other_flag, false):
						push_warning("[STORY] Clearing mutually exclusive flag '%s' (new: '%s')" % [other_flag, flag_name])
						story_flags[other_flag] = false
						story_flag_updated.emit(other_flag, false)
				break
	story_flags[flag_name] = value
	story_flag_updated.emit(flag_name, value)
```

### 5.2 🟠 HIGH — `ch3_ending.gd` references `ch3_seraphina_recruited` which doesn't exist
**File:** `scripts/chapter3/ch3_ending.gd`, line ~172  
**Current behavior:** `_has_flag("ch3_seraphina_recruited")` — but the game only sets `ch2_seraphina_recruited` (in ch2_seraphina_choice.gd). There is no `ch3_seraphina_recruited` flag in `DEFAULT_STORY_FLAGS`. This means Seraphina will NEVER appear in the Ch3 ending dialogue even if recruited.  
**Fix — use the correct flag:**
```gdscript
# ch3_ending.gd line ~172, change:
	if _has_flag("ch3_seraphina_recruited"):
# to:
	if _has_flag("ch2_seraphina_recruited"):

# And line ~189:
	if _has_flag("ch3_seraphina_recruited"):
# to:
	if _has_flag("ch2_seraphina_recruited"):
```

### 5.3 🟠 HIGH — `ch3_ending.gd` references `ch3_lyra_recruited` but flag not in DEFAULT_STORY_FLAGS
**File:** `scripts/game_manager.gd`, `DEFAULT_STORY_FLAGS`  
**Current behavior:** `DEFAULT_STORY_FLAGS` does not include `ch3_lyra_recruited`, `ch3_kaelthas_allied`, `ch3_kaelthas_refused`, `ch3_kaelthas_challenged`, `ch3_kaelthas_defeated`, `ch3_sovereign_defiant`, `ch3_sovereign_regretful`, `ch3_sovereign_doubting`, or `ch3_reality_shatter`. These flags ARE set by ch3 scripts but will not be saved/loaded correctly because `_merge_dict` only adds overlay keys — if an old save is loaded that doesn't contain these keys, they default to `false` which is correct. But they should be declared for documentation and IDE support.  
**Fix — add missing Ch3 flags to DEFAULT_STORY_FLAGS:**
```gdscript
# Add to DEFAULT_STORY_FLAGS in game_manager.gd:
	"ch3_lyra_recruited": false, "ch3_lyra_left_alone": false,
	"ch3_kaelthas_allied": false, "ch3_kaelthas_refused": false,
	"ch3_kaelthas_challenged": false, "ch3_kaelthas_defeated": false,
	"ch3_sovereign_defiant": false, "ch3_sovereign_regretful": false,
	"ch3_sovereign_doubting": false, "ch3_reality_shatter": false,
	"ch3_complete": false,
```

### 5.4 🟡 MEDIUM — Relationship values not saved/loaded with validation
**File:** `scripts/game_manager.gd`, save/load  
**Current behavior:** Relationships are saved as plain Dictionary values. There's no range clamping. A modded save could set `relationships["elara"]` to 999999, which story scripts don't guard against (they use `>=` checks).  
**Fix — clamp relationship values:**
```gdscript
# Add helper method:
func adjust_relationship(character: String, amount: int) -> void:
	relationships[character] = clampi(relationships.get(character, 0) + amount, -100, 100)

# Use in chapter scripts instead of direct assignment:
# GameManager.relationships["seraphina"] = GameManager.relationships.get("seraphina", 0) + 10
# becomes:
# GameManager.adjust_relationship("seraphina", 10)
```

---

## 6. MEMORY LEAK & CLEANUP ISSUES

### 6.1 🔴 CRITICAL — `_build_choice_buttons` uses `pressed.connect` without disconnect
**File:** `scripts/dialogue_manager.gd`, line 420  
**Current behavior:** `btn.pressed.connect(_on_choice_pressed.bind(index))` — these are never explicitly disconnected. However, since `_destroy_choice_buttons` calls `queue_free()` on the container, the buttons and their connections WILL be cleaned up when the deferred free happens. **This is actually safe** because DialogueManager outlives the buttons. ✅ No leak here — false alarm on re-review.

### 6.2 🟠 HIGH — `ch1_elara_meeting.gd` cleans up `_ambient_tweens` but NOT `glitch_particles`
**File:** `scripts/chapter1/ch1_elara_meeting.gd`, lines 21-25  
**Current behavior:** `_exit_tree` kills ambient tweens but does not stop particle emitters. If particles are still emitting when the scene changes, the emitter is freed while active — usually fine in Godot, but can cause a brief visual artifact.  
**Fix:**
```gdscript
func _exit_tree() -> void:
	for tw in _ambient_tweens:
		if tw and tw.is_valid():
			tw.kill()
	_ambient_tweens.clear()
	# Stop any active particle emitters
	if glitch_particles and is_instance_valid(glitch_particles):
		glitch_particles.emitting = false
	if static_particles and is_instance_valid(static_particles):
		static_particles.emitting = false
```

### 6.3 🟠 HIGH — `CutsceneDirector` never cleans up `_fade_layer` or `_canvas_modulate` on `cancel()`
**File:** `scripts/cutscene/cutscene_director.gd`, line 296  
**Current behavior:** `cancel()` only sets `_is_cancelled = true`. The `play()` loop breaks out, calls `_unblock_input()` (which does tint cleanup), but `_fade_overlay` remains visible if cancel happens mid-fade, leaving a black/colored screen.  
**Fix:**
```gdscript
func cancel() -> void:
	_is_cancelled = true
	# Clean up visual overlays immediately
	if _fade_overlay and is_instance_valid(_fade_overlay):
		_fade_overlay.visible = false
		_fade_overlay.color.a = 0.0
	if _canvas_modulate and is_instance_valid(_canvas_modulate):
		_canvas_modulate.queue_free()
		_canvas_modulate = null
```

### 6.4 🟡 MEDIUM — `_show_buff_notification` and `_show_supply_notification` in `choice_consequences.gd` create Labels on root with no size constraint
**File:** `scripts/choice_consequences.gd`, lines 390-410  
**Current behavior:** Notifications are added to `get_tree().root` with hardcoded pixel positions (`Vector2(200, 620)`). On different resolution/aspect ratio, they'll appear in the wrong place or off-screen.  
**Fix — use CanvasLayer with proper anchoring:**
```gdscript
func _show_buff_notification(buff: Dictionary) -> void:
	var layer = CanvasLayer.new()
	layer.layer = 90
	add_child(layer)
	
	var notif = Label.new()
	notif.text = "CHOICE EFFECT: %s" % buff.get("description", "Unknown effect")
	notif.add_theme_font_size_override("font_size", 14)
	notif.add_theme_color_override("font_color", Color(1.0, 0.85, 0.3))
	notif.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	notif.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	notif.offset_top = -100
	notif.offset_bottom = -60
	notif.offset_left = -300
	notif.offset_right = 300
	layer.add_child(notif)
	
	var tw = create_tween()
	tw.tween_property(notif, "offset_top", notif.offset_top - 70, 2.0).set_trans(Tween.TRANS_SINE)
	tw.parallel().tween_property(notif, "modulate:a", 0.0, 2.0).set_delay(3.0)
	tw.tween_callback(layer.queue_free)
```

---

## 7. EDGE CASES

### 7.1 🔴 CRITICAL — Rapid clicking during choice buttons can lock the game
**File:** `scripts/dialogue_manager.gd`, `_on_choice_pressed`  
**Current behavior:** If a player clicks two buttons in the same frame (possible with very fast double-click or touch input), `_choice_result` gets set to the second button's index. The first button's `pressed` signal still fires but `_choice_result` is already set. This is benign. **However**, the real problem is clicking OUTSIDE the buttons during the `_awaiting_choice` state — the `_input` handler blocks `jump` action (line 483) but NOT mouse clicks on non-button areas. If the player manages to click outside and then the choice_container is freed by another code path, `_choice_result` stays at -1 and the 120-second timeout kicks in.  
**Fix — add double-click guard:**
```gdscript
func _on_choice_pressed(index: int) -> void:
	if _choice_result != -1:  # Already selected
		return
	_choice_result = index
	choice_selected.emit(index)
```

### 7.2 🟠 HIGH — `ch3_ending.gd` `_wait_for_input` has no timeout
**File:** `scripts/chapter3/ch3_ending.gd`, lines 266-270  
**Current behavior:** After the stats card, `_wait_for_input()` awaits the `_next_input` signal indefinitely. If the player puts down the controller or the signal never fires (e.g., `_input` is never called because another system consumed it), the game is stuck forever.  
**Fix — add timeout:**
```gdscript
func _wait_for_input() -> void:
	_waiting_for_input = true
	# Race: wait for input OR 60-second timeout
	var timer = get_tree().create_timer(60.0)
	var result = await _race_signals(_next_input, timer.timeout)
	_waiting_for_input = false

# Helper for signal racing:
func _race_signals(sig1: Signal, sig2: Signal) -> void:
	var done = false
	sig1.connect(func(): done = true, CONNECT_ONE_SHOT)
	sig2.connect(func(): done = true, CONNECT_ONE_SHOT)
	while not done:
		await get_tree().process_frame
		if not is_inside_tree():
			return
```
Or simpler — just poll in a loop:
```gdscript
func _wait_for_input() -> void:
	_waiting_for_input = true
	var timeout: float = 0.0
	while _waiting_for_input and timeout < 120.0:
		await get_tree().process_frame
		if not is_inside_tree(): return
		timeout += get_process_delta_time()
		if Input.is_action_just_pressed("ui_accept") or Input.is_action_just_pressed("jump"):
			break
	_waiting_for_input = false
```

### 7.3 🟡 MEDIUM — `_input` in `ch3_ending.gd` doesn't handle gamepad
**File:** `scripts/chapter3/ch3_ending.gd`, lines 280-285  
**Current behavior:** `_next_input` is only emitted for `InputEventKey` events. Gamepad button presses (`InputEventJoypadButton`) are ignored — gamepad players cannot advance past the stats card.  
**Fix:**
```gdscript
func _input(event) -> void:
	if event.is_action_pressed("ui_cancel"):
		if has_node("/root/PauseScreen"):
			PauseScreen.toggle_pause()
		return
	if _waiting_for_input and event.is_pressed() and not event.is_echo():
		if event is InputEventKey or event is InputEventJoypadButton:
			if not event.is_action("ui_cancel"):
				_next_input.emit()
```

### 7.4 🟡 MEDIUM — Scene transition during choice display orphans the choice container
**File:** `scripts/dialogue_manager.gd`  
**Current behavior:** `force_reset()` calls `_destroy_choice_buttons()` which calls `queue_free()`. The `_process` method detects scene changes and calls `force_reset()`. This should handle it correctly. ✅ However, `_choice_container` is a child of `_ui_layer` (the DialogueManager's CanvasLayer), NOT the scene — so it persists across scene changes. `force_reset` correctly handles this. **No bug here.**

---

## 8. NARRATIVE QUALITY ASSESSMENT

### 8.1 ✅ STRONG — Character voice distinctiveness
The dialogue in all three chapter scripts shows **excellent** character voice differentiation:
- **Kaelen**: Analytical, guarded, uses technical metaphors ("architecture", "wiring behind the walls", "security framework")
- **Kaelen (Internal)**: More vulnerable, self-aware, honest about fear
- **Elara**: Cheerful mask over genuine pain, bouncy speech patterns, emotional transparency
- **Seraphina**: Direct, confrontational, military bearing, emotional vulnerability breaks through
- **SOVEREIGN**: Cold, logical, uses Kaelen's own words against him
- **System messages**: Terse, code-comment style

### 8.2 ✅ STRONG — Emotional beats and pacing
The Elara meeting includes deliberate pauses (wait beats of 1.0-2.0s), camera zooms during emotional moments, and internal monologue that reveals character depth. Seraphina's confrontation properly escalates tension with conditional dialogue based on prior choices.

### 8.3 🟡 IMPROVEMENT — Some System messages break immersion
**Files:** Multiple chapter scripts  
**Example:** `"[RELATIONSHIP: Elara — TRUSTED COMPANION]\n[Elara will fight alongside you...]"` (ch1_elara_meeting.gd, line ~711)  
**Issue:** These are pure game-mechanical messages displayed through the narrative dialogue system. They break the 4th wall without being intentionally meta.  
**Recommendation:** Lean into the meta-narrative. Since Kaelen IS a programmer and the world IS code, rephrase these as Data Vision readouts:
```gdscript
# Instead of:
"[RELATIONSHIP: Elara — TRUSTED COMPANION]\n[Elara will fight alongside you...]"
# Use:
"// ENTITY_BOND_ANALYSIS: Elara.trust_level = COMPANION\n// Combat subroutine: glitch_shield.active = true\n// WARNING: Emotional dependencies create exploitable attack surface"
```

### 8.4 🟢 ENHANCEMENT — Missing narrative moment: first time seeing own portrait
The dialogue system shows character initials as placeholder portraits. When Kaelen first sees his own initial "K" in the dialogue box, there's an opportunity for a meta-comment about seeing himself represented as a letter.

---

## 9. MISSING FEATURES

### 9.1 🟠 HIGH — No dialogue history UI (text backlog)
**File:** `scripts/dialogue_manager.gd`  
**Current behavior:** `dialogue_history` array exists and is populated correctly (line 155). `get_dialogue_history()` and `clear_dialogue_history()` methods exist. But there is NO way for the player to VIEW the history. No backlog screen, no scroll-back.  
**Fix — add history panel toggled by a key:**
```gdscript
# Add to dialogue_manager.gd:
var _history_panel: PanelContainer = null
var _history_visible: bool = false

func _input(event: InputEvent) -> void:
	# ... existing input handling ...
	
	# History backlog toggle (L key or dedicated button)
	if event is InputEventKey and event.pressed and event.keycode == KEY_L:
		if _is_visible and not _awaiting_choice:
			_toggle_history()
			get_viewport().set_input_as_handled()

func _toggle_history() -> void:
	if _history_visible:
		_hide_history()
	else:
		_show_history()

func _show_history() -> void:
	_history_visible = true
	if _history_panel and is_instance_valid(_history_panel):
		_history_panel.queue_free()
	
	_history_panel = PanelContainer.new()
	_history_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	_history_panel.offset_left = 60
	_history_panel.offset_right = -60
	_history_panel.offset_top = 30
	_history_panel.offset_bottom = -200
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.02, 0.02, 0.06, 0.95)
	style.border_color = Color(0.0, 0.5, 0.8, 0.5)
	style.set_border_width_all(1)
	style.set_corner_radius_all(4)
	style.content_margin_left = 20
	style.content_margin_right = 20
	style.content_margin_top = 15
	style.content_margin_bottom = 15
	_history_panel.add_theme_stylebox_override("panel", style)
	
	var scroll = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_history_panel.add_child(scroll)
	
	var rtl = RichTextLabel.new()
	rtl.bbcode_enabled = true
	rtl.fit_content = true
	rtl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rtl.add_theme_font_size_override("normal_font_size", 14)
	rtl.add_theme_color_override("default_color", Color(0.7, 0.7, 0.8))
	
	var history_text = "[center][b]— DIALOGUE HISTORY —[/b][/center]\n\n"
	for entry in dialogue_history:
		var speaker: String = entry.get("speaker", "")
		var text: String = entry.get("text", "")
		var color: Color = SPEAKER_COLORS.get(speaker, Color(0.8, 0.8, 0.9))
		history_text += "[color=#%s][b]%s:[/b][/color] %s\n\n" % [color.to_html(false), speaker, text]
	rtl.text = history_text
	scroll.add_child(rtl)
	
	_ui_layer.add_child(_history_panel)
	# Scroll to bottom
	await get_tree().process_frame
	scroll.scroll_vertical = scroll.get_v_scroll_bar().max_value

func _hide_history() -> void:
	_history_visible = false
	if _history_panel and is_instance_valid(_history_panel):
		_history_panel.queue_free()
		_history_panel = null
```

### 9.2 🟡 MEDIUM — No "text speed" indicator during typewriter
**Current behavior:** When holding Space/Jump to speed up typewriter, there's no visual indication that fast-forward is active. Player doesn't know this feature exists.  
**Fix — add a small indicator:**
```gdscript
# In say(), inside the typewriter loop, after calculating delay:
		if Input.is_action_pressed("ui_accept") or Input.is_action_pressed("jump"):
			delay = 1.0 / TYPE_FAST_SPEED
			if _advance_indicator:
				_advance_indicator.text = "▶▶"
				_advance_indicator.visible = true
		else:
			if _advance_indicator:
				_advance_indicator.visible = false
```

### 9.3 🟡 MEDIUM — No choice replay / choice review screen
**Current behavior:** Once a choice is made, there's no way to see what you chose. The stats card in ch3 shows some choices, but there's no unified choice log accessible from the pause menu.  
**Fix — add to ChoiceConsequences:**
```gdscript
# Add to choice_consequences.gd:
var choice_log: Array[Dictionary] = []  # {"flag": String, "description": String, "chapter": int}

func _on_story_flag_updated(flag_name: String, value: bool) -> void:
	if not value:
		return
	if CHOICE_BUFFS.has(flag_name):
		apply_choice_buff(flag_name)
		choice_log.append({
			"flag": flag_name,
			"description": CHOICE_BUFFS[flag_name].get("description", ""),
			"timestamp": Time.get_ticks_msec()
		})
	# ... rest of existing code ...
```

### 9.4 🟢 LOW — No "auto-play" mode toggle
**Current behavior:** Auto-advance is per-line (`auto_advance` parameter). There's no global auto-play mode where the player can sit back and watch dialogue unfold automatically.  
**Fix:**
```gdscript
# Add to dialogue_manager.gd:
var auto_play_mode: bool = false
var auto_play_delay: float = 0.04  # seconds per character for read time

func toggle_auto_play() -> void:
	auto_play_mode = !auto_play_mode

# In say(), modify the manual advance wait section (~line 164):
	# ── Wait for manual advance ──
	if auto_play_mode:
		var stripped = _text_label.get_parsed_text()
		var wait_time = clampf(stripped.length() * auto_play_delay, 2.0, 15.0)
		var waited = 0.0
		while waited < wait_time and not _advance_requested and not _skip_all_requested:
			await get_tree().process_frame
			if not is_inside_tree(): return
			waited += get_process_delta_time()
		return
	# ... existing manual advance code ...
```

### 9.5 🟢 LOW — Dialogue SFX per-character is hardcoded
**File:** `scripts/dialogue_manager.gd`, line 143  
**Current behavior:** Text tick sounds are the same for all speakers (`"text_tick"` variants). Different characters should have distinct "voice" sounds.  
**Fix — add per-speaker tick configuration:**
```gdscript
const SPEAKER_SFX: Dictionary = {
	"Kaelen": ["text_tick", "text_tick_low"],
	"Kaelen (Internal)": ["text_tick_low"],
	"Elara": ["text_tick_high", "text_tick"],
	"SOVEREIGN": ["text_tick_low", "text_tick_low", "static_crackle"],
	"System": ["text_tick_high"],
}

# In say(), replace the SFX line (143):
		if chars_shown % 2 == 0 and has_node("/root/SFXManager"):
			var sfx_set = SPEAKER_SFX.get(speaker, ["text_tick", "text_tick_low", "text_tick_high"])
			SFXManager.play_random(sfx_set)
```

---

## 10. SUMMARY TABLE

| # | Severity | Category | Issue | File |
|---|----------|----------|-------|------|
| 1.1 | 🔴 | Crash | Orphaned timer coroutine on scene change | dialogue_manager.gd:136 |
| 3.1 | 🔴 | Race condition | Choice buttons accept clicks during fade-in | dialogue_manager.gd:365 |
| 4.1 | 🔴 | Stuck state | ESC skip leaves dialogue box open | cutscene_manager.gd:901 |
| 5.1 | 🔴 | Data integrity | Mutually exclusive flags not enforced | game_manager.gd:236 |
| 5.2 | 🟠 | Wrong flag | `ch3_seraphina_recruited` should be `ch2_seraphina_recruited` | ch3_ending.gd:172 |
| 5.3 | 🟠 | Missing data | Ch3 flags missing from DEFAULT_STORY_FLAGS | game_manager.gd:107 |
| 1.2 | 🟠 | Missing feature | No batch dialogue API | dialogue_manager.gd |
| 2.1 | 🟠 | Missing feature | No expression system for portraits | dialogue_manager.gd:644 |
| 3.2 | 🟠 | UX | Choice buttons don't wrap keyboard nav | dialogue_manager.gd:365 |
| 3.3 | 🟠 | Signal bug | `choice_selected` never emitted from modern API | dialogue_manager.gd:422 |
| 4.2 | 🟠 | Code quality | 600+ lines duplicated across cutscene files | cutscene_*.gd |
| 4.3 | 🟠 | Leak | CanvasModulate dangling reference on scene change | cutscene_manager.gd:571 |
| 6.2 | 🟠 | Cleanup | Particle emitters not stopped in _exit_tree | ch1_elara_meeting.gd:21 |
| 6.3 | 🟠 | Leak | Director cancel() leaves fade overlay visible | cutscene_director.gd:296 |
| 7.2 | 🟠 | Stuck state | `_wait_for_input` has no timeout | ch3_ending.gd:268 |
| 9.1 | 🟠 | Missing feature | No dialogue history UI | dialogue_manager.gd |
| 1.3 | 🟡 | Config | TYPE_FAST_SPEED is const, not configurable | dialogue_manager.gd:62 |
| 1.4 | 🟡 | UX | Auto-advance timing includes BBCode in length | dialogue_manager.gd:158 |
| 2.2 | 🟡 | Visual | Portrait placeholder looks dev-mode | dialogue_manager.gd:580 |
| 3.4 | 🟡 | UX | No visual feedback on choice selection | dialogue_manager.gd:422 |
| 4.4 | 🟡 | Visual | Flash effect uses wrong layer | cutscene_manager.gd:876 |
| 5.4 | 🟡 | Data | Relationship values not clamped | game_manager.gd |
| 6.4 | 🟡 | Layout | Notifications use hardcoded positions | choice_consequences.gd:390 |
| 7.3 | 🟡 | Input | Stats card doesn't accept gamepad input | ch3_ending.gd:280 |
| 7.4 | 🟡 | N/A | ✅ Verified safe — choice container on CanvasLayer | dialogue_manager.gd |
| 8.3 | 🟡 | Narrative | System messages break immersion | ch1/ch2 scripts |
| 9.2 | 🟡 | UX | No fast-forward visual indicator | dialogue_manager.gd |
| 9.3 | 🟡 | Missing feature | No choice review/log screen | choice_consequences.gd |
| 9.4 | 🟢 | Missing feature | No auto-play mode toggle | dialogue_manager.gd |
| 9.5 | 🟢 | Polish | Same SFX for all speakers | dialogue_manager.gd:143 |
| 8.4 | 🟢 | Narrative | Missed meta-narrative opportunity | - |

---

## PRIORITY FIXES (Recommended Order)

1. **Fix `ch3_seraphina_recruited` → `ch2_seraphina_recruited`** (5.2) — 2 lines, immediate story fix
2. **Add mutual exclusion for story flags** (5.1) — prevents data corruption
3. **Add Ch3 flags to DEFAULT_STORY_FLAGS** (5.3) — prevents silent save/load issues
4. **Fix choice button race condition** (3.1) — prevents accidental selections
5. **Fix cutscene ESC leaving dialogue open** (4.1) — prevents stuck state
6. **Fix `ch3_ending.gd` gamepad support + timeout** (7.2, 7.3) — prevents stuck state
7. **Emit `choice_selected` signal** (3.3) — enables external systems
8. **Add dialogue history UI** (9.1) — major QoL for players
9. **Add expression support to portraits** (2.1) — significant visual upgrade
10. **Refactor cutscene code duplication** (4.2) — long-term maintainability
