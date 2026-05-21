# ACCESSIBILITY & QUALITY-OF-LIFE AUDIT REPORT

**Project:** Aethelgard: The Glitch Sovereign  
**Engine:** Godot 4.6  
**Date:** 2026-03-02  
**Auditor:** Automated Codebase Audit  

---

## EXECUTIVE SUMMARY

| Severity | Count |
|----------|-------|
| CRITICAL | 4     |
| HIGH     | 9     |
| MEDIUM   | 12    |
| LOW      | 8     |
| **TOTAL**| **33**|

**Overall Assessment:** The project has a solid accessibility *data layer* in `game_manager.gd` (colorblind mode keys, reduced motion flag, text scaling, screen-shake intensity, subtitle sizing, one-handed mode, extended parry window, auto-pogo). However, **most of these backend settings have no UI to configure them at runtime**, making them effectively inaccessible to players. The Options menu only exposes Text Speed, Music Volume, SFX Volume, and Key Bindings. Display settings (fullscreen, resolution, VSync), all accessibility toggles, and all difficulty assists are completely missing from the player-facing UI.

---

## 1. INPUT ACCESSIBILITY

### 1.1 Key Rebinding — Partial Support
- **Severity:** MEDIUM  
- **Category:** INPUT ACCESSIBILITY  
- **File(s):** [main_menu.gd](scripts/main_menu.gd#L553-L566), [project.godot](project.godot#L55-L147)  
- **Current state:** 10 actions are rebindable via the Options panel (`REBINDABLE_ACTIONS` array). Bindings are saved/loaded via `_save_key_bindings()` / `_load_key_bindings()`. However, `data_vision`, `perfect_delete`, `pause_menu`, and `status_window` are NOT in the rebindable list.
- **Recommended fix:** Add the missing 4 actions to `REBINDABLE_ACTIONS`:
  ```gdscript
  {"action": "data_vision", "label": "Data Vision"},
  {"action": "perfect_delete", "label": "Perfect Delete"},
  {"action": "pause_menu", "label": "Pause Menu"},
  {"action": "status_window", "label": "Status Window"},
  ```

### 1.2 Controller / Gamepad Support — Missing
- **Severity:** CRITICAL  
- **Category:** INPUT ACCESSIBILITY  
- **File(s):** [project.godot](project.godot#L55-L147)  
- **Current state:** All input actions in `project.godot` are exclusively `InputEventKey`. There are **zero `InputEventJoypadButton` or `InputEventJoypadMotion` entries**. The only gamepad awareness in the codebase is `ch3_ending.gd` line 337 which checks `InputEventJoypadButton` for a single event, and `pause_screen.gd` / `shop_system.gd` have comments about "keyboard/gamepad navigation" focus, but no actual joypad bindings exist.
- **Recommended fix:** Add `InputEventJoypadButton` and `InputEventJoypadMotion` events to every input action in `project.godot`. Map standard gamepad layout:
  - Left stick → move_left/right/up/down
  - A → jump, X → attack, Y → spell, B → heal
  - RB → defend, LB → sprint, LT → root_access
  - Start → pause_menu, Select → status_window

### 1.3 Input Deadzone — Hardcoded
- **Severity:** LOW  
- **Category:** INPUT ACCESSIBILITY  
- **File(s):** [project.godot](project.godot#L55-L147)  
- **Current state:** All input actions use `"deadzone": 0.5` (the default). There is no player-facing deadzone slider.
- **Recommended fix:** Add a deadzone slider (0.05–0.95) in the Options panel that calls `InputMap.action_set_deadzone()` for all actions.

### 1.4 One-Handed Mode — Backend Only
- **Severity:** HIGH  
- **Category:** INPUT ACCESSIBILITY  
- **File(s):** [game_manager.gd](scripts/game_manager.gd#L141)  
- **Current state:** `"one_handed_mode": false` exists in `DEFAULT_ACCESSIBILITY_SETTINGS` but there is **no UI toggle** and **no code that reads this flag** to remap controls. It's a dead setting.
- **Recommended fix:** 
  1. Add a toggle in an Accessibility sub-menu.
  2. Implement `_apply_one_handed_remap()` that reassigns combat controls to one hand (e.g., numpad or mouse buttons + nearby keys).

---

## 2. VISUAL ACCESSIBILITY

### 2.1 Colorblind Mode — Backend Only
- **Severity:** HIGH  
- **Category:** VISUAL ACCESSIBILITY  
- **File(s):** [game_manager.gd](scripts/game_manager.gd#L132)  
- **Current state:** `"colorblind_mode": "none"` is defined with explicit support for `"protanopia"`, `"deuteranopia"`, `"tritanopia"` in the settings dictionary. The value is persisted in `user://accessibility.cfg`. However, **no shader or color remap code reads this value**. No UI exists to select a mode.
- **Recommended fix:**
  1. Add a `CanvasLayer` with a `ColorRect` using a colorblind simulation shader that reads `GameManager.get_accessibility("colorblind_mode")`.
  2. Add a dropdown in an Accessibility sub-menu: None / Protanopia / Deuteranopia / Tritanopia.

### 2.2 Font Scaling — Backend Exists, UI Missing
- **Severity:** MEDIUM  
- **Category:** VISUAL ACCESSIBILITY  
- **File(s):** [game_manager.gd](scripts/game_manager.gd#L113), all UI scripts  
- **Current state:** `get_text_size_scale()` returns 0.8–2.0 and is properly clamped. However, the 100+ hardcoded `add_theme_font_size_override("font_size", N)` calls across the codebase **do not multiply by this scale factor**. No UI slider exists.
- **Recommended fix:**
  1. Create a helper: `func scaled_font(base: int) -> int: return int(base * GameManager.get_text_size_scale())`
  2. Replace all `add_theme_font_size_override("font_size", N)` with `add_theme_font_size_override("font_size", scaled_font(N))`.
  3. Add a slider in an Accessibility menu.

### 2.3 High-Contrast Mode — Backend Only
- **Severity:** MEDIUM  
- **Category:** VISUAL ACCESSIBILITY  
- **File(s):** [game_manager.gd](scripts/game_manager.gd#L119)  
- **Current state:** `is_high_contrast()` helper exists and returns the stored bool. **No code acts on it** — no background darkening, no UI contrast adjustment, no outline thickening.
- **Recommended fix:** When enabled, apply a high-contrast `CanvasLayer` overlay or swap to a high-contrast theme. Increase outline sizes on all labels, brighten interactive elements.

### 2.4 Reduced Motion — Partially Implemented
- **Severity:** LOW  
- **Category:** VISUAL ACCESSIBILITY  
- **File(s):** [game_manager.gd](scripts/game_manager.gd#L116)  
- **Current state:** `is_reduced_motion()` exists, and the comment says "Disables non-essential particles, screen effects." However, only `combat_effects.gd` line 149 references the screen shake multiplier from accessibility settings. The actual `is_reduced_motion()` flag is **not checked** by `VFXLibrary`, `GlitchOverlay`, `GameJuice`, `BackgroundManager`, or any particle-spawning code.
- **Recommended fix:** Gate all non-essential VFX behind `if not GameManager.is_reduced_motion()` checks in:
  - `vfx_library.gd` — `spawn_effect()`
  - `game_juice.gd` — screen shake, hit freeze, combo labels
  - `glitch_overlay.gd` — scanline, chromatic aberration, tear effects

### 2.5 Screen Reader Hints — Missing
- **Severity:** MEDIUM  
- **Category:** VISUAL ACCESSIBILITY  
- **File(s):** All UI scripts  
- **Current state:** No `Control.tooltip_text` or `AccessibleName` properties are set on any UI elements. Godot 4.6 supports basic accessibility properties but none are used.
- **Recommended fix:** Set `tooltip_text` / accessible descriptions on all interactive buttons, progress bars, and sliders in `pause_screen.gd`, `main_menu.gd`, `shop_system.gd`, `dialogue_manager.gd`.

---

## 3. DIFFICULTY OPTIONS

### 3.1 No Player-Selectable Difficulty — Critical Gap
- **Severity:** CRITICAL  
- **Category:** DIFFICULTY OPTIONS  
- **File(s):** [game_manager.gd](scripts/game_manager.gd#L539-L610)  
- **Current state:** The game has a sophisticated Dynamic Difficulty Adjustment (DDA) system that automatically adjusts enemy damage/cooldowns based on player deaths and kills. The multiplier ranges from 0.75 (struggling) to 1.25 (dominating). **However, there is no player-facing difficulty selector** (Easy / Normal / Hard). The crash sequence even taunts: `"DIFFICULTY: HARDCORE (non-adjustable)"`.
- **Recommended fix:** Add a difficulty selector at New Game and in the pause menu:
  ```gdscript
  enum Difficulty { STORY, EASY, NORMAL, HARD }
  # STORY: DDA floor at 0.5, player damage +50%, enemy damage -50%
  # EASY: DDA floor at 0.6
  # NORMAL: Current behavior
  # HARD: DDA ceiling at 1.5, no downward adjustment
  ```

### 3.2 Extended Parry Window — Backend Only, No UI
- **Severity:** MEDIUM  
- **Category:** DIFFICULTY OPTIONS  
- **File(s):** [game_manager.gd](scripts/game_manager.gd#L145)  
- **Current state:** `"extended_parry_window": false` exists in accessibility settings. **No code reads this value to actually extend the parry window**. The parry window in `player_combat.gd` is hardcoded.
- **Recommended fix:**
  1. In `player_combat.gd`, read the flag: `var parry_window = PARRY_WINDOW_BASE + (0.1 if GameManager.get_accessibility("extended_parry_window") else 0.0)`
  2. Add a toggle in an Accessibility/Assist sub-menu.

### 3.3 Auto-Pogo — Backend Only, No UI
- **Severity:** LOW  
- **Category:** DIFFICULTY OPTIONS  
- **File(s):** [game_manager.gd](scripts/game_manager.gd#L146)  
- **Current state:** `"auto_pogo": false` exists but is never read by `player_combat.gd`. The pogo mechanic requires manual DOWN+ATTACK input with no automation option.
- **Recommended fix:** In `player_combat.gd` pogo detection, check: `if GameManager.get_accessibility("auto_pogo") and not is_on_floor() and is_above_enemy:` to auto-trigger pogo.

### 3.4 Invincibility / God Mode Toggle — Missing
- **Severity:** HIGH  
- **Category:** DIFFICULTY OPTIONS  
- **File(s):** [game_manager.gd](scripts/game_manager.gd)  
- **Current state:** No invincibility toggle exists. No way for struggling players to bypass combat sections.
- **Recommended fix:** Add `"invincibility_mode": false` to `DEFAULT_ACCESSIBILITY_SETTINGS`. In `player_combat.gd`'s `take_damage()`, check and skip damage if enabled.

---

## 4. QOL — SAVE SYSTEM

### 4.1 Save System — Functional
- **Severity:** LOW (informational)  
- **Category:** QOL — SAVE SYSTEM  
- **File(s):** [game_manager.gd](scripts/game_manager.gd#L701-L970)  
- **Current state:** Robust save system with 3 manual slots + 1 autosave slot (99). JSON-based with checksums. `auto_save()` is called at boss defeats, dungeon entries, checkpoint floors, and chapter transitions. Load/Save UI exists in main menu with slot display.
- **Status:** Working well. Minor improvements possible.

### 4.2 Auto-Save Indicator — Missing
- **Severity:** MEDIUM  
- **Category:** QOL — SAVE SYSTEM  
- **File(s):** [game_manager.gd](scripts/game_manager.gd#L962-L968)  
- **Current state:** `auto_save()` silently saves. **No visual indicator** (spinning icon, "Saving..." text) is shown to the player. Multiple chapter scripts call `GameManager.auto_save()` at critical moments but the player has no feedback.
- **Recommended fix:** Add a small "Auto-saving..." label or animated icon to a persistent `CanvasLayer` that fades in/out over 1.5s when `auto_save()` is called:
  ```gdscript
  func auto_save() -> void:
      _show_save_indicator()
      save_game(AUTOSAVE_SLOT)
  ```

### 4.3 Save Confirmation in Pause Menu — Missing
- **Severity:** LOW  
- **Category:** QOL — SAVE SYSTEM  
- **File(s):** [pause_screen.gd](scripts/ui/pause_screen.gd#L895-L903)  
- **Current state:** Pause screen has "Save Game" button that calls `GameManager.auto_save()` with a `ui_confirm` SFX. **No visual confirmation** ("Game Saved!" text) appears.
- **Recommended fix:** Show a brief "Game Saved!" label that fades out after 2s when the save button is pressed.

### 4.4 Save Slot Management — No Delete Option
- **Severity:** LOW  
- **Category:** QOL — SAVE SYSTEM  
- **File(s):** [main_menu.gd](scripts/main_menu.gd#L95-L240)  
- **Current state:** Load screen shows 4 slots with info. `game_manager.gd` has `delete_save(slot)` function. **No delete button exists in the UI**.
- **Recommended fix:** Add a "Delete" button next to each save slot in the Load Game panel.

---

## 5. QOL — TUTORIALS

### 5.1 Combat Tutorial — Well Implemented
- **Severity:** LOW (informational)  
- **Category:** QOL — TUTORIALS  
- **File(s):** [ch1_tutorial_knight.gd](scripts/chapter1/ch1_tutorial_knight.gd#L48-L70), [combat_arena.gd](scripts/combat/combat_arena.gd#L100-L258)  
- **Current state:** Comprehensive 8-step contextual tutorial (move, jump, attack, dash, parry, pogo, spell, heal). Hints appear after 5s of inactivity. Skippable with TAB. Respects `GameManager.is_tutorial_hints_enabled()`. HUD tutorial overlay explains HP/Soul/Corruption bars. Two separate tutorial combat scenes exist.
- **Status:** Well done. This is a strong point.

### 5.2 Tutorial Hints Toggle — Backend Only, No UI
- **Severity:** MEDIUM  
- **Category:** QOL — TUTORIALS  
- **File(s):** [game_manager.gd](scripts/game_manager.gd#L144)  
- **Current state:** `"tutorial_hints_enabled": true` is checked by `ch1_tutorial_knight.gd` and the accessor `is_tutorial_hints_enabled()` exists. **No toggle in any settings menu** for players who want to disable hints on replay.
- **Recommended fix:** Add toggle in Accessibility/Gameplay sub-menu.

### 5.3 Controls Reminder — Partial
- **Severity:** MEDIUM  
- **Category:** QOL — TUTORIALS  
- **File(s):** [status_window.gd](scripts/ui/status_window.gd#L308-L331), [pause_screen.gd](scripts/ui/pause_screen.gd#L51-L82)  
- **Current state:** Status window shows a "Press I for Status Window" hint once. Pause screen footer shows "[ESC] Resume | [←→] Switch Tabs | [ENTER] Select". The ability descriptions in pause screen list keybindings. **No dedicated "Controls" reference page** exists in the pause menu for quick lookup.
- **Recommended fix:** Add a "Controls" tab to the pause screen showing all current key bindings (read from `InputMap`).

---

## 6. QOL — NAVIGATION

### 6.1 Minimap — Missing
- **Severity:** HIGH  
- **Category:** QOL — NAVIGATION  
- **File(s):** All exploration scripts  
- **Current state:** No minimap implementation exists anywhere in the codebase. The pause screen "Map" tab shows only a static text label (`"Loading map data..."` / simple location text).
- **Recommended fix:** Implement a basic minimap `CanvasLayer` for exploration scenes that tracks player position and shows landmarks. Even a simple text-based area map would help.

### 6.2 Objective Tracker — Implemented
- **Severity:** LOW (informational)  
- **Category:** QOL — NAVIGATION  
- **File(s):** [side_quest_manager.gd](scripts/side_quest_manager.gd#L347-L414)  
- **Current state:** HUD quest tracker exists in top-right corner showing up to 3 active quests with step progress. Updates dynamically. Chapter objectives displayed via System dialogue messages.
- **Status:** Working well.

### 6.3 Fast Travel — Missing
- **Severity:** HIGH  
- **Category:** QOL — NAVIGATION  
- **File(s):** No files  
- **Current state:** No fast travel system exists. Scene transitions are managed via `SceneTransitions` autoload but there's no player-initiated travel between unlocked locations.
- **Recommended fix:** Add a fast travel menu accessible from the pause screen Map tab. Track visited locations in `GameManager.story_flags` and allow teleportation between discovered areas.

### 6.4 Waypoint System — Missing
- **Severity:** MEDIUM  
- **Category:** QOL — NAVIGATION  
- **File(s):** No files  
- **Current state:** No visual waypoint indicators exist during exploration. The `cinematic_camera.gd` has a `tracking_shot(waypoints)` function but this is camera path data, not player navigation waypoints.
- **Recommended fix:** Add directional arrows or HUD indicators pointing toward the next objective during exploration sections.

---

## 7. QOL — SETTINGS

### 7.1 Volume Controls — Implemented
- **Severity:** LOW (informational)  
- **Category:** QOL — SETTINGS  
- **File(s):** [main_menu.gd](scripts/main_menu.gd#L657-L714)  
- **Current state:** Music Volume and SFX Volume sliders exist in Options. Values are saved to `user://audio_settings.cfg`. Properly connected to `MusicManager` and `SFXManager`.
- **Status:** Working.

### 7.2 Fullscreen Toggle — Missing
- **Severity:** HIGH  
- **Category:** QOL — SETTINGS  
- **File(s):** [project.godot](project.godot), [main_menu.gd](scripts/main_menu.gd)  
- **Current state:** `project.godot` sets viewport to 1280x720 with stretch mode `"viewport"`. **No fullscreen toggle** exists in Options or anywhere else. No `DisplayServer.window_set_mode()` call exists.
- **Recommended fix:** Add to Options panel:
  ```gdscript
  var fullscreen_cb = CheckButton.new()
  fullscreen_cb.text = "Fullscreen"
  fullscreen_cb.button_pressed = DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN
  fullscreen_cb.toggled.connect(func(on):
      DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN if on else DisplayServer.WINDOW_MODE_WINDOWED))
  ```

### 7.3 Resolution Options — Missing
- **Severity:** HIGH  
- **Category:** QOL — SETTINGS  
- **File(s):** [project.godot](project.godot#L49-L53)  
- **Current state:** Hardcoded 1280x720 viewport. No resolution selector in Options. No `window/size/resizable` setting.
- **Recommended fix:** Add a resolution dropdown with common options (1280x720, 1600x900, 1920x1080, 2560x1440) using `DisplayServer.window_set_size()`.

### 7.4 VSync Toggle — Missing
- **Severity:** MEDIUM  
- **Category:** QOL — SETTINGS  
- **File(s):** [project.godot](project.godot)  
- **Current state:** No VSync configuration in `project.godot` (defaults to engine default). No player-facing toggle.
- **Recommended fix:** Add to Options: `DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED)` / `VSYNC_DISABLED`.

### 7.5 Accessibility Settings Sub-Menu — Missing
- **Severity:** CRITICAL  
- **Category:** QOL — SETTINGS  
- **File(s):** [main_menu.gd](scripts/main_menu.gd#L573-L770)  
- **Current state:** The Options panel contains ONLY: Text Speed, Music Volume, SFX Volume, Key Bindings, Close. **All 14 accessibility settings** defined in `game_manager.gd` (screen shake, colorblind mode, high contrast, reduced motion, text size, subtitles, one-handed mode, input remap, tutorial hints, extended parry, auto-pogo) have **NO player-facing UI**. They can only be changed by manually editing `user://accessibility.cfg`.
- **Recommended fix:** Add an "Accessibility" section or sub-panel to the Options menu with:
  - Screen Shake: CheckButton + HSlider(0.0–1.0)
  - Colorblind Mode: OptionButton (None/Protanopia/Deuteranopia/Tritanopia)
  - High Contrast: CheckButton
  - Reduced Motion: CheckButton
  - Text Size: HSlider(0.8–2.0)
  - Subtitle Size: OptionButton (Small/Medium/Large)
  - Subtitle Speaker Colors: CheckButton
  - Tutorial Hints: CheckButton
  - Extended Parry Window: CheckButton
  - Auto-Pogo: CheckButton
  - One-Handed Mode: CheckButton
  All connected via `GameManager.set_accessibility(key, value)`.

---

## 8. QOL — GAMEPLAY FEEDBACK

### 8.1 Damage Numbers — Implemented
- **Severity:** LOW (informational)  
- **Category:** QOL — GAMEPLAY FEEDBACK  
- **File(s):** [player_combat.gd](scripts/combat/player_combat.gd#L720), [combat_effects.gd](scripts/combat_effects.gd#L260), [object_pool.gd](scripts/object_pool.gd#L167)  
- **Current state:** `_spawn_damage_number()` creates floating damage text. Critical hits use larger font (24 vs 18). Color-coded by type (parry counter = gold, spells = blue/purple). Object-pooled for performance.
- **Status:** Working well.

### 8.2 Damage Number Visibility Toggle — Missing
- **Severity:** LOW  
- **Category:** QOL — GAMEPLAY FEEDBACK  
- **File(s):** [player_combat.gd](scripts/combat/player_combat.gd), [combat_effects.gd](scripts/combat_effects.gd)  
- **Current state:** Damage numbers are always shown. No option to disable or resize them.
- **Recommended fix:** Add `"show_damage_numbers": true` to accessibility settings. Gate `_spawn_damage_number()` behind this flag.

### 8.3 HP Bar — Implemented  
- **Severity:** LOW (informational)  
- **Category:** QOL — GAMEPLAY FEEDBACK  
- **File(s):** [player_combat.gd](scripts/combat/player_combat.gd#L234), [enemy_base.gd](scripts/combat/enemy_base.gd#L1296), [ch1_tutorial_knight.gd](scripts/chapter1/ch1_tutorial_knight.gd#L395-L420)  
- **Current state:** Player has HP bar + label, enemies have HP bar with label, bosses have full-width HP bars with name labels and phase indicators.
- **Status:** Working well.

### 8.4 Cooldown Indicators — Missing Visual
- **Severity:** MEDIUM  
- **Category:** QOL — GAMEPLAY FEEDBACK  
- **File(s):** [player_combat.gd](scripts/combat/player_combat.gd#L44-L96)  
- **Current state:** Cooldowns for attack (0.22s), dash (0.38s), parry (0.15s), and pogo (0.2s) exist as internal timers. **No visual HUD indicators** show the player when abilities are ready. The player must rely on feel alone.
- **Recommended fix:** Add small cooldown pie-chart or bar indicators under the skill buttons or near the HP bar showing dash/parry/spell readiness.

### 8.5 Quest Log — Implemented
- **Severity:** LOW (informational)  
- **Category:** QOL — GAMEPLAY FEEDBACK  
- **File(s):** [side_quest_manager.gd](scripts/side_quest_manager.gd#L316-L342), [pause_screen.gd](scripts/ui/pause_screen.gd#L857-L873)  
- **Current state:** "Ticket Backlog" tab in pause screen shows active and completed quests. `get_quest_log_text()` provides detailed quest state. HUD tracker shows active objectives.
- **Status:** Working well.

### 8.6 Combo Counter — Implemented
- **Severity:** LOW (informational)  
- **Category:** QOL — GAMEPLAY FEEDBACK  
- **File(s):** [game_juice.gd](scripts/effects/game_juice.gd#L571-L597), [player_combat.gd](scripts/combat/player_combat.gd#L1864)  
- **Current state:** Combo counter, multiplier, and tier labels exist with pulsing animations.
- **Status:** Working.

---

## 9. PERFORMANCE QOL

### 9.1 Frame Rate Limiter — Missing
- **Severity:** MEDIUM  
- **Category:** PERFORMANCE QOL  
- **File(s):** [project.godot](project.godot)  
- **Current state:** No frame rate limiter setting. No `Engine.max_fps` configuration. No player-facing toggle.
- **Recommended fix:** Add to Options: An FPS limit dropdown (30/60/120/Unlimited) setting `Engine.max_fps`.

### 9.2 Particle Reduction — Partially Possible
- **Severity:** LOW  
- **Category:** PERFORMANCE QOL  
- **File(s):** [game_manager.gd](scripts/game_manager.gd#L134), [effects/vfx_library.gd](scripts/effects/vfx_library.gd#L491)  
- **Current state:** `VFXLibrary` caps active effects to prevent framerate collapse (line 491). The `"reduced_motion"` flag could theoretically control this but isn't connected. No player-facing "Low Quality" or "Reduce Particles" toggle.
- **Recommended fix:** Add `"particle_density": 1.0` to accessibility settings (0.25–1.0). Multiply `particles.amount` by this factor in `_spawn_particles()`.

### 9.3 Low-Quality Mode — Missing
- **Severity:** LOW  
- **Category:** PERFORMANCE QOL  
- **File(s):** [project.godot](project.godot)  
- **Current state:** No quality presets. Rendering set to "Forward Plus" with nearest-neighbor texture filtering (`default_texture_filter=0`). No option to disable post-processing effects.
- **Recommended fix:** Add a Quality dropdown (Low/Medium/High) that toggles:
  - GlitchOverlay shader effects
  - Particle counts
  - Screen shake effects
  - Background parallax complexity

---

## CRITICAL FINDINGS SUMMARY

| # | Finding | Severity | Impact |
|---|---------|----------|--------|
| 1 | **No gamepad/controller bindings** — game is keyboard-only | CRITICAL | Excludes all controller users |
| 2 | **No player-selectable difficulty** — DDA is automatic/hidden | CRITICAL | Players who struggle have no recourse; no accessibility for motor-impaired |
| 3 | **No accessibility settings UI** — 14 settings exist but have no menu | CRITICAL | All accessibility features are developer-only |
| 4 | **No fullscreen/resolution/VSync** in Options | HIGH | Basic expected PC game settings missing |
| 5 | **Colorblind mode defined but not implemented** | HIGH | Backend exists but no shader/remap code |
| 6 | **One-handed mode defined but not implemented** | HIGH | Dead code with no effect |
| 7 | **No minimap or fast travel** | HIGH | Navigation pain in exploration sections |
| 8 | **No invincibility/god mode assist** | HIGH | No skip option for accessibility needs |
| 9 | **100+ hardcoded font sizes ignore text scale setting** | MEDIUM | Text scaling feature cannot actually work |

---

## RECOMMENDED PRIORITY ORDER

### Phase 1 — Critical (Ship-Blocking)
1. Build Accessibility sub-menu in Options exposing all 14 existing settings
2. Add gamepad bindings to `project.godot` for all 16 actions
3. Add difficulty selector (Story/Easy/Normal/Hard) at New Game

### Phase 2 — High Priority
4. Add fullscreen toggle + resolution dropdown + VSync to Options
5. Implement colorblind shader that reads the existing setting
6. Implement one-handed mode remap logic
7. Add invincibility toggle to accessibility settings
8. Wire `get_text_size_scale()` into all font size overrides
9. Add auto-save visual indicator

### Phase 3 — Medium Priority
10. Add missing actions to key rebinding list
11. Wire `is_reduced_motion()` into VFX/particle systems
12. Add cooldown indicators to combat HUD
13. Add "Controls" tab to pause menu
14. Implement waypoint arrows for exploration objectives
15. Add FPS limiter option
16. Add screen reader tooltip text to UI elements
17. Add high-contrast mode implementation

### Phase 4 — Polish
18. Add deadzone slider for gamepad
19. Add particle density option
20. Add save slot delete button
21. Add save confirmation text
22. Add damage number toggle
23. Add fast travel system
24. Add minimap

---

*End of Audit Report*
