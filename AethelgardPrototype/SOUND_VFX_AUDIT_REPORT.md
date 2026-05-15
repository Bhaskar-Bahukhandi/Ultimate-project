# Sound & VFX Audit Report — AethelgardPrototype

**Date:** 2026-03-02  
**Auditor:** GitHub Copilot  
**Scope:** sfx_manager.gd, music_manager.gd, vfx_library.gd, combat_effects.gd, game_juice.gd, cross-game SFX usage  

---

## Summary

- **CRITICAL:** 2 issues (silent failures from undefined SFX/music references)
- **HIGH:** 6 issues (missing crossfades, duplicated logic, race conditions)
- **MEDIUM:** 9 issues (missing SFX on events, unused definitions, inconsistencies)
- **LOW:** 7 issues (performance, polish, minor gaps)

---

## Issues (sorted by severity)

### CRITICAL

---

**1. CRITICAL — 11 SFX names referenced in code but NOT defined in `SFX_DEFS`**  
**Files:** Multiple  
**Description:**  
The following `SFXManager.play()` calls reference SFX names that do not exist in `SFX_DEFS`. Since `play()` only emits a `push_warning` and returns silently, these events play **no sound at all** at runtime:

| SFX Name | File | Line | Probable Intended SFX |
|---|---|---|---|
| `"choice_confirm"` | `scripts/dialogue_manager.gd` | ~L447 | `"choice_select"` or `"ui_confirm"` |
| `"parry_impact"` | `scripts/effects/game_juice.gd` | ~L300 | `"parry_perfect"` or `"parry"` |
| `"alert"` | `scripts/chapter3/ch3_fractured_wastes.gd` | ~L416, L606 | `"warning"` or `"alarm"` |
| `"alert"` | `scripts/chapter3/ch3_kaelthas_betrayal.gd` | ~L106 | `"warning"` or `"alarm"` |
| `"parry_success"` | `scripts/chapter1/ch1_glitch_crater.gd` | ~L510 | `"parry"` or `"parry_perfect"` |
| `"player_hit"` | `scripts/chapter1/ch1_glitch_crater.gd` | ~L516 | `"player_hurt"` |
| `"sword_slash"` | `scripts/chapter1/ch1_glitch_crater.gd` | ~L540 | `"sword_swing"` |
| `"parry_attempt"` | `scripts/chapter1/ch1_glitch_crater.gd` | ~L551 | `"parry"` or `"block"` |
| `"glitch_heavy"` | `scripts/chapter3/ch3_ending.gd` | ~L130 | `"glitch_surge"` |
| `"puzzle_solve"` | `scripts/chapter3/ch3_archive_depths.gd` | ~L169, L369, L437, L519 | New definition needed |
| `"ui_accept"` | `scripts/ui/pause_screen.gd` | ~L901 | `"ui_confirm"` |
| `"menu_move"` | `scripts/chapter3/ch3_data_stream.gd` | ~L195, L201 | `"ui_hover"` or `"ui_tab"` |

**Fix:** Either add definitions to `SFX_DEFS` for each missing name, or correct the call sites to use existing names.

---

**2. CRITICAL — 3 Music track names referenced but NOT defined in `TRACKS`**  
**Files:** Multiple  
**Description:**  
`MusicManager.play_track()` is called with track names that don't exist in the `TRACKS` dictionary. The function emits a `push_warning` and returns, causing **full silence** during these scenes:

| Track Name | File | Line | Probable Intended Track |
|---|---|---|---|
| `"battle"` | `scripts/chapter3/ch3_fractured_wastes.gd` | ~L617 | `"combat"` |
| `"battle"` | `scripts/chapter3/ch3_data_stream.gd` | ~L41 | `"combat"` |
| `"battle"` | `scripts/chapter3/ch3_kaelthas_betrayal.gd` | ~L119 | `"combat"` |
| `"boss"` | `scripts/chapter3/ch3_ending.gd` | ~L57 | `"boss_fight"` |
| `"boss"` | `scripts/chapter3/ch3_archive_depths.gd` | ~L238 | `"boss_fight"` |
| `"boss"` | `scripts/chapter3/ch3_kaelthas_betrayal.gd` | ~L171, L309 | `"boss_fight"` |
| `"menu"` | `scripts/chapter3/ch3_ending.gd` | ~L178 | `"main_menu"` |

**Fix:** Change the calls to use the correct track names (`"combat"`, `"boss_fight"`, `"main_menu"`), or add aliases in the TRACKS dictionary.

---

### HIGH

---

**3. HIGH — Procedural music has no crossfade on track change**  
**File:** `scripts/music_manager.gd` — `_start_procedural_track()` (~L498)  
**Description:**  
When switching between two procedural tracks (e.g. exploration → combat), `_start_procedural_track()` immediately stops all note players with `child.stop(); child.queue_free()` and starts the new track on the same frame. There is no fade-out of the old track's notes or fade-in of the new ones. The `_fade_in` parameter is received but **completely ignored** for procedural tracks.  
**Impact:** Jarring, instant music cuts on every scene/combat transition.  
**Fix:** Before clearing children, fade their volume to 0 over ~0.5s, then swap. Apply a volume ramp to the first notes of the new track. Example:
```gdscript
func _start_procedural_track(track: Dictionary, fade_in: bool) -> void:
    if _procedural_active:
        # Fade out existing notes over FADE_DURATION
        for child in get_children():
            if child is AudioStreamPlayer and child != _music_player:
                var tw = child.create_tween()
                tw.tween_property(child, "volume_db", -40.0, FADE_DURATION * 0.5)
                tw.tween_callback(child.queue_free)
    # ... rest of setup with delayed start
```

---

**4. HIGH — Duplicated parry SFX logic between `CombatFX` and `GameJuice`**  
**Files:** `scripts/combat_effects.gd` ~L377, `scripts/effects/game_juice.gd` ~L288-300  
**Description:**  
- `CombatFX.apply_parry_effects()` plays `"parry_perfect"` (VALID)  
- `GameJuice.on_parry()` plays `"parry_impact"` (**UNDEFINED — silent**)  
- Both are called via different code paths — if a caller invokes `GameJuice.on_parry()` instead of `CombatFX.apply_parry_effects()`, the parry has NO sound.  
- Additionally, both apply screen shake independently — if both are called for the same parry event, shake stacks excessively.  
**Fix:** `GameJuice.on_parry()` should either call `CombatFX.apply_parry_effects()` as the canonical path, or change `"parry_impact"` to `"parry_perfect"`. Remove duplicate shake from one path.

---

**5. HIGH — `play_positional()` mutates shared `_sfx_volume` — race condition**  
**File:** `scripts/sfx_manager.gd` — `play_positional()` (~L895-901)  
**Description:**  
```gdscript
func play_positional(sfx_name, world_pos, listener_pos, max_dist = 800.0):
    ...
    var saved_vol = _sfx_volume
    _sfx_volume *= falloff     # ← mutates shared state
    play(sfx_name)
    _sfx_volume = saved_vol    # ← restores after
```
If two positional sounds are queued in the same frame (e.g. multiple enemies), the `_sfx_volume` save/restore can interleave, causing incorrect volumes.  
**Fix:** Pass volume as a local parameter through to `_generate_sfx()` instead of mutating shared state, or calculate the volume adjustment on the AudioStreamPlayer's `volume_db` after generation.

---

**6. HIGH — `_fade_out_and_stop()` doesn't stop procedural note children**  
**File:** `scripts/music_manager.gd` — `_fade_out_and_stop()` (~L641)  
**Description:**  
The fade-out only tweens `_music_player.volume_db` (the file-based player) to -40dB. But procedural tracks spawn individual `AudioStreamPlayer` children for each note. Setting `_procedural_active = false` prevents new notes, but **existing note players continue playing** until they naturally finish. For long-duration notes (pad voices with 1.0s+ duration), this means up to 1+ seconds of audible bleed after "stop" is called.  
**Fix:** Also fade or immediately stop all `AudioStreamPlayer` children (except `_music_player`) in `_fade_out_and_stop()`.

---

**7. HIGH — `apply_boss_kill_effects()` plays generic death sound, not boss death**  
**File:** `scripts/combat_effects.gd` — `apply_boss_kill_effects()` (~L425)  
**Description:**  
```gdscript
func apply_boss_kill_effects(position: Vector2) -> void:
    _play_sfx("enemy_death", 0.05)  # ← uses generic enemy_death (0.55s)
```
`SFX_DEFS` has a specifically crafted `"enemy_death_boss"` (1.2s duration, distortion, 4 layers) that is **never used anywhere in the codebase**. Boss kills sound identical to regular enemy kills.  
**Fix:** Change to `_play_sfx("enemy_death_boss", 0.05)`.

---

**8. HIGH — `game_over.gd` plays no player death SFX**  
**File:** `scripts/game_over.gd` ~L16  
**Description:**  
The game over screen only calls `MusicManager.play_track("game_over")`. While `player_combat.gd` does play `"player_death"` in `die()`, the game_over screen itself has no confirming death sound. If the transition is slow, the player death SFX may have already finished before the screen appears.  
**Fix:** Add a unique game-over stinger SFX or ensure the "game_over" music track covers this.

---

### MEDIUM

---

**9. MEDIUM — `on_player_hurt()` in GameJuice has no SFX**  
**File:** `scripts/effects/game_juice.gd` — `on_player_hurt()` (~L131-155)  
**Description:**  
This function applies red screen flash + camera trauma on player damage but never calls `SFXManager.play("player_hurt")`. The actual `player_hurt` SFX is played in `player_combat.gd`, so this only matters if `on_player_hurt()` is called as a standalone hurt feedback (which some callers could do).  
**Fix:** Add `if has_node("/root/SFXManager"): SFXManager.play("player_hurt")` or document that callers must play the SFX themselves.

---

**10. MEDIUM — `boss_death_sequence()` in GameJuice plays no SFX**  
**File:** `scripts/effects/game_juice.gd` — `boss_death_sequence()` (~L773-810)  
**Description:**  
This is a dramatic boss death cinematic (slowmo + shockwave + flash) but has **zero SFX calls**. Neither `"enemy_death_boss"` nor `"reality_shatter"` is played. Only CombatFX hitstop and screen shake. The boss dies in dramatic visual silence.  
**Fix:** Add `SFXManager.play("enemy_death_boss")` at the start and optionally `"reality_shatter"` during the shockwave.

---

**11. MEDIUM — SFX volume stored in two places with fragile sync**  
**Files:** `scripts/sfx_manager.gd` (~L30), `scripts/music_manager.gd` (~L21, L429)  
**Description:**  
`_sfx_volume` exists as a member variable in both `SFXManager` (L30) and `MusicManager` (L420). `SFXManager.play()` syncs from `MusicManager.get_sfx_volume()` every call, but `SFXManager.play_positional()` uses the local `_sfx_volume` before syncing. If `MusicManager` isn't loaded (unlikely but possible), the fallback is 0.8 regardless of what the user set.  
**Fix:** Have one canonical source of truth. Either remove `_sfx_volume` from `SFXManager` and always read from `MusicManager`, or let `SFXManager` own SFX volume entirely.

---

**12. MEDIUM — ~30+ defined SFX are never used in any game script**  
**File:** `scripts/sfx_manager.gd`  
**Description:**  
The following entries exist in `SFX_DEFS` but are never referenced by any `.gd` file via `SFXManager.play()` or `_play_sfx()`:

| Unused SFX | Category |
|---|---|
| `sword_hit_flesh` | Combat |
| `sword_hit_metal` | Combat |
| `heavy_windup` | Combat |
| `sword_slam` | Combat |
| `block` | Combat |
| `shield_break` | Combat |
| `enemy_hurt` | Combat |
| `enemy_hurt_heavy` | Combat |
| `enemy_death_boss` | Combat (see Issue #7) |
| `charged_loop` | Combat |
| `charged_release` | Combat |
| `boss_roar` | Combat |
| `footstep_stone/grass/metal/wood` | Movement |
| `double_jump` | Movement |
| `land_heavy` | Movement |
| `wall_slide` | Movement |
| `wall_jump` | Movement |
| `item_pickup_rare` | Items |
| `item_unequip` | Items |
| `gold_pickup_large` | Items |
| `charm_equip/unequip` | Items |
| `transition_fade` | Transitions |
| `transition_glitch` | Transitions |
| `corruption_pulse` | Glitch |
| `corruption_rise` | Glitch |
| `story_flag` | Quest |
| `notification_pop` | Quest |
| `wind_gust` | Environment |
| `lever_pull` | Environment |
| `secret_found` | Environment |
| `clock_tick/chime` | Chapter 2 |
| `time_slow/fast` | Chapter 2 |
| `gear_grind` | Chapter 2 |

**Impact:** These are wasted synthesis definitions and represent missing game feedback (e.g. footstep variant sounds on different terrain, rare item pickups, etc.)  
**Fix:** Wire these into their respective systems. For example:
- Footstep variants → player movement code based on terrain type
- `enemy_death_boss` → boss kill events
- `charged_release/loop` → charge attack system
- `secret_found`, `lever_pull` → environment interactions

---

**13. MEDIUM — `on_pickup()` in GameJuice has no SFX or VFX**  
**File:** `scripts/effects/game_juice.gd` — `on_pickup()` (~L371-375)  
**Description:**  
The pickup handler only adds a tiny 0.02 camera trauma. No SFX (like `"item_pickup"` or `"gold_pickup"`) is played, no VFX sparkle is spawned. Compare to `on_hit_connect()` which provides layers of feedback.  
**Fix:** Add `SFXManager.play()` based on `item_type` parameter and spawn `VFXLibrary.spawn("vfx_glitch_sparkle", ...)`.

---

**14. MEDIUM — `on_achievement_unlocked()` in GameJuice has no SFX**  
**File:** `scripts/effects/game_juice.gd` — `on_achievement_unlocked()` (~L920)  
**Description:**  
Spawns gold flash VFX and an announcement label but plays no sound. The `achievements.gd` file plays `"powerup"` independently, but there's a dedicated `"achievement_unlock"` SFX in `SFX_DEFS` that goes unused.  
**Fix:** Add `SFXManager.play("achievement_unlock")`.

---

**15. MEDIUM — `chapter_end_sequence()` in GameJuice has no SFX**  
**File:** `scripts/effects/game_juice.gd` — `chapter_end_sequence()` (~L824-835)  
**Description:**  
Dramatic chapter ending (screen shake + distortion + flash + slowmo) is entirely soundless. Neither `"reality_shatter"` nor any transition SFX is played.  
**Fix:** Add `SFXManager.play("transition_glitch")` or `"reality_shatter"` at the sequence start.

---

**16. MEDIUM — No dialogue start/end SFX**  
**File:** `scripts/dialogue_manager.gd`  
**Description:**  
Dialogue only has `"dialogue_advance"` on manual advancement. There is no SFX when a dialogue box first appears (e.g. `"ui_open"`) or when it closes (e.g. `"ui_close"`). The SFX_DEFS include text_tick variants but these are also not connected to the text display typewriter effect.  
**Fix:** Add `SFXManager.play("ui_open")` when dialogue starts and `SFXManager.play("ui_close")` when it ends. Connect `text_tick` variants to the typewriter character display.

---

**17. MEDIUM — MusicManager `set_sfx_volume()` sets AudioBus "SFX" but SFXManager plays on "Master"**  
**File:** `scripts/music_manager.gd` (~L424-428), `scripts/sfx_manager.gd` (AudioStreamPlayer defaults)  
**Description:**  
`MusicManager.set_sfx_volume()` adjusts the `"SFX"` audio bus via `AudioServer`. But `SFXManager` creates `AudioStreamPlayer` nodes without setting a bus — they default to `"Master"`. The volume is instead baked into waveform sample data. This means the AudioBus adjustment has **no effect** on procedurally generated SFX.  
**Fix:** Either set `.bus = "SFX"` on all SFX players in `SFXManager.play()`, or remove the bus-based volume control from `MusicManager.set_sfx_volume()` since baked volume is already used.

---

### LOW

---

**18. LOW — VFX `vfx_rain_heavy` uses 80 particles — potential perf concern**  
**File:** `scripts/effects/vfx_library.gd` — `EFFECTS["vfx_rain_heavy"]` (~L354)  
**Description:**  
80 `CPUParticles2D` particles with `one_shot: false` (continuous). Combined with the `MAX_ACTIVE_EFFECTS = 60` cap, a rain effect plus combat VFX could hit the cap quickly, causing combat VFX to be silently dropped.  
**Fix:** Reduce to 40-50 particles for heavy rain, or give weather a separate budget from combat VFX.

---

**19. LOW — `vfx_mist` uses scale_max 20.0 — very large for CPUParticles2D**  
**File:** `scripts/effects/vfx_library.gd` — `EFFECTS["vfx_mist"]` (~L410)  
**Description:**  
Scale 10-20 on CPU particles means each mist particle covers a huge screen area. With 8 particles + 6s lifetime, this could cause overdraw issues on lower-end hardware.  
**Fix:** Reduce to scale 6-12 and increase particle count slightly for similar visual density with less per-particle cost.

---

**20. LOW — No SFX for save point interaction**  
**File:** Various checkpoint/save code  
**Description:**  
`SFX_DEFS` has both `"save_point"` and `"save_complete"` defined, but neither appears in any `SFXManager.play()` call across the codebase. Save points are silent.  
**Fix:** Wire `"save_point"` to checkpoint activation and `"save_complete"` to successful save confirmation.

---

**21. LOW — `on_secret_found()` doesn't use the dedicated `"secret_found"` SFX**  
**File:** `scripts/effects/game_juice.gd` — `on_secret_found()` (~L909)  
**Description:**  
The function spawns VFX and an announcement but plays no sound. `SFX_DEFS` has a rich `"secret_found"` SFX (0.6s, 3 harmonics, swell) that is never called.  
**Fix:** Add `SFXManager.play("secret_found")`.

---

**22. LOW — `combo_milestone` SFX defined but never played on milestone**  
**File:** `scripts/sfx_manager.gd` (SFX_DEFS), `scripts/effects/game_juice.gd` — `_check_combo_milestone()` (~L498-515)  
**Description:**  
The `"combo_milestone"` SFX exists in `SFX_DEFS` but `_check_combo_milestone()` only spawns VFX announcements and calls `slowmo_moment`/`dramatic_zoom`. No sound is played.  
**Fix:** Add `SFXManager.play("combo_milestone")` in the milestone handler.

---

**23. LOW — Scene transitions use only `"transition_whoosh"` — two transition SFX unused**  
**Files:** `scripts/effects/scene_transition_manager.gd`, `scripts/sfx_manager.gd`  
**Description:**  
`"transition_fade"` and `"transition_glitch"` are defined in `SFX_DEFS` but scene transitions only use `"transition_whoosh"` and `"glitch_surge"`. Different transition types (fade vs. wipe vs. glitch) all sound the same.  
**Fix:** Map `"transition_fade"` to fade-type transitions and `"transition_glitch"` to glitch-type transitions in `scene_transition_manager.gd`.

---

**24. LOW — `_sfx_volume` in SFXManager defaults to 0.8, not synced from MusicManager on startup**  
**File:** `scripts/sfx_manager.gd` — `_ready()` (~L862)  
**Description:**  
`SFXManager._ready()` only sets `process_mode`. It doesn't sync `_sfx_volume` from `MusicManager` at startup. The first `play()` call will sync, but any direct access to `_sfx_volume` before the first play could use the hardcoded 0.8 default even if the user has set a different volume.  
**Fix:** Sync volume in `_ready()`:
```gdscript
func _ready():
    process_mode = Node.PROCESS_MODE_ALWAYS
    if has_node("/root/MusicManager"):
        _sfx_volume = MusicManager.get_sfx_volume()
```

---

## Quick Reference — Defined vs. Used

### Music Tracks
| Track Name | Defined | Referenced |
|---|---|---|
| `main_menu` | ✅ | ✅ |
| `exploration` | ✅ | ✅ |
| `exploration_night` | ✅ | ❌ Not found in any play_track call |
| `combat` | ✅ | ✅ |
| `combat_intense` | ✅ | ❌ Not found in any play_track call |
| `boss_fight` | ✅ | ✅ |
| `boss_rage` | ✅ | ✅ |
| `victory` | ✅ | ✅ |
| `dialogue` | ✅ | ✅ |
| `game_over` | ✅ | ✅ |
| `prologue` | ✅ | ❌ Not found in any play_track call |
| `crash` | ✅ | ❌ Not found in any play_track call |
| `glitch_zone` | ✅ | ❌ Not found in any play_track call |
| `ironhold` | ✅ | ❌ Not found in any play_track call |
| `underground` | ✅ | ❌ Not found in any play_track call |
| `clock_tower` | ✅ | ❌ Not found in any play_track call |
| `arena` | ✅ | ❌ Not found in any play_track call |
| `shop` | ✅ | ❌ Not found in any play_track call |
| `mystery` | ✅ | ❌ Not found in any play_track call |
| `sadness` | ✅ | ❌ Not found in any play_track call |
| `tension` | ✅ | ✅ |
| `fractured_wastes` | ✅ | ❌ Not found in any play_track call |
| `data_stream` | ✅ | ❌ Not found in any play_track call |
| `cutscene_emotional` | ✅ | ❌ Not found in any play_track call |
| `seraphina_theme` | ✅ | ❌ Not found in any play_track call |
| `administrator` | ✅ | ❌ Not found in any play_track call |
| `elara_theme` | ✅ | ❌ Not found in any play_track call |
| `title_reveal` | ✅ | ❌ Not found in any play_track call |
| `ambient` | ✅ | ✅ |
| `"battle"` | ❌ | ✅ (should be `"combat"`) |
| `"boss"` | ❌ | ✅ (should be `"boss_fight"`) |
| `"menu"` | ❌ | ✅ (should be `"main_menu"`) |

**Note:** Many scene-specific tracks (ironhold, underground, clock_tower, arena, shop, etc.) are defined but never wired to their respective scenes. These scenes default to generic "exploration" or "combat" music instead of their dedicated tracks.

---

## Priority Action Items

1. **Immediate (CRITICAL):** Fix the 11 undefined SFX names and 3 undefined music track names — these cause total audio silence in affected scenes.
2. **Next (HIGH):** Add crossfade to procedural music transitions. Fix the play_positional race condition. Wire `enemy_death_boss` to boss kill. Resolve duplicated parry logic.
3. **Then (MEDIUM):** Wire unused SFX to their systems (save_point, secret_found, combo_milestone, footstep variants). Add SFX to silent GameJuice functions. Fix the SFX audio bus routing.
4. **Polish (LOW):** Connect scene-specific music tracks to their scenes. Tune VFX particle counts for performance. Add missing transition SFX variety.
