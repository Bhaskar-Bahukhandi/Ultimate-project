# PHASE 10N-A2 OPENING HOOK IMPLEMENTATION REPORT

## 1. Summary

* Implemented: Yes
* First playable control reached within ~10 seconds: Unproven
* Old route preserved: Yes
* Production art touched: No
* Generated assets touched: No
* Chapter 2+ touched: No
* Overall verdict: The scoped implementation is in place, but runtime validation is blocked because Godot headless runs timed out and emitted a signal 11 crash-handler backtrace after tool timeout. Do not treat this as ready for the next design phase until the scene is validated in a real headed or reliable headless run.

Evidence classification:

* CODE EVIDENCE: New Game route now points to `res://scenes/chapter1/opening_crash_site_hook.tscn`, with a fallback if the scene is missing.
* STATIC SCENE EVIDENCE: `opening_crash_site_hook.tscn` exists and references `ch1_opening_crash_site_hook.gd`.
* HEADLESS RUNTIME EVIDENCE: Attempted, but not completed due Godot timeout/crash-handler output.
* LIVE PLAY EVIDENCE: Not available.
* SCREENSHOT EVIDENCE: None.

## 2. Files changed

| Path | Purpose | Risk level | Rollback method |
|---|---|---:|---|
| `scripts/main_menu.gd` | Routes New Game to the new playable opening hook and adds a debug-only legacy cinematic start button. | Medium | Restore `_on_new_game_pressed()` to `res://scenes/prologue/flight_707.tscn`; remove `OPENING_HOOK_SCENE`, `LEGACY_PROLOGUE_SCENE`, `_start_legacy_cinematic_prologue()`, and `_add_legacy_prologue_debug_button()`. |
| `scripts/game_manager.gd` | Adds first-minute opening hook flags to default story flags. | Low | Remove the four `ch1_opening_hook_*` default flags. Existing saves are not migrated. |
| `scripts/ui/progression_breadcrumb.gd` | Adds first-minute breadcrumb objectives scoped to the new opening hook flags. | Low | Remove the three 10N-A2 objective entries. |
| `scripts/chapter1/ch1_opening_crash_site_hook.gd` | New playable crash-site hook built from existing player controller and runtime primitives. | Medium | Delete this script and route New Game back to legacy prologue. |
| `scenes/chapter1/opening_crash_site_hook.tscn` | New small scene that attaches the hook script. | Medium | Delete this scene and route New Game back to legacy prologue. |
| `docs/gameplay_audit/phase_10n_a2_opening_hook/tools/opening_hook_runtime_validation.gd` | Headless validation script for route/input/interactable checks. | Low | Delete the docs tool. |
| `docs/gameplay_audit/phase_10n_a2_opening_hook/diagnostics/opening_hook_static_validation.json` | Offline structural validation results after Godot runtime failed. | Low | Delete the diagnostics file. |
| `docs/gameplay_audit/phase_10n_a2_opening_hook/opening_hook_implementation_report.md` | This report. | Low | Delete or replace with updated validation report. |

## 3. New opening flow

1. Player selects New Game.
2. `GameManager.reset_game()` runs.
3. Main menu routes to `res://scenes/chapter1/opening_crash_site_hook.tscn`.
4. The scene sets Chapter 1 exploration state and `ch1_opening_hook_started`.
5. The player starts awake at the crash/glitch crater with immediate control.
6. Objective appears: `Stand up. Find a signal.`
7. Player can move using existing top-down controller input.
8. Player can inspect `SignalFragment`.
9. Signal interaction sets `ch1_opening_hook_signal_found`, changes objective to follow the Oakhaven signal, and shows the curiosity line: `Oakhaven death record looped 412 times. Elara marker still alive.`
10. A visible `GlitchPulse` danger zone arms near the route.
11. Entering the pulse sets `ch1_opening_hook_danger_seen` and shakes the camera.
12. Moving east through `OakhavenPath` completes the hook, sets early compatibility flags, and routes to the overworld near Oakhaven.

Estimated first-minute intent:

| Time | Beat |
|---:|---|
| 0-10s | Player has control and can move. |
| 0-20s | Objective is visible. |
| 10-30s | Signal fragment is interactable. |
| 20-45s | Glitch pulse arms as a small danger/stakes beat. |
| 30-60s | Oakhaven/Elara curiosity gap points east without dumping lore. |

## 4. Route/flag mapping

| Flag/objective | Action | Purpose |
|---|---|---|
| `ch1_opening_hook_started` | Set in new hook `_ready()` | Enables first-minute breadcrumb objective only on the new route. |
| `ch1_opening_hook_signal_found` | Set on signal interaction | Marks the first interactable complete and advances objective. |
| `ch1_opening_hook_danger_seen` | Set when player enters pulse | Records the small danger beat without damage/combat changes. |
| `ch1_opening_hook_complete` | Set when leaving crater | Enables post-hook breadcrumb to reach Oakhaven. |
| `plane_crash_completed` | Set when leaving crater | Compatibility with skipped flight/crash cinematic route. |
| `ch1_awakening_complete` | Set when leaving crater | Compatibility with existing Chapter 1 awakening state. |
| `ch1_glitch_crater_complete` | Set when leaving crater | Compatibility with existing route out of the crater. |
| `ch1_oakhaven_entered` | Read by breadcrumb only | Stops the `Reach Oakhaven.` breadcrumb once existing Oakhaven flow marks entry. |
| `tutorial_completed` | Existing breadcrumb still reads it | Not modified; this avoids pretending later tutorial/combat has happened. |

Old route preservation:

* `LEGACY_PROLOGUE_SCENE` remains `res://scenes/prologue/flight_707.tscn`.
* NG+ still routes to the legacy prologue.
* Debug builds add `DEBUG: LEGACY CINEMATIC START` under the New Game button.
* `_start_legacy_cinematic_prologue()` remains directly callable.

## 5. Design critique after implementation

What improved:

* New Game is no longer hard-blocked behind the long flight/cinematic path.
* First action is movement, not passive lore.
* The first objective is explicit and short.
* The first interactable creates a curiosity gap instead of a lore dump.
* The danger beat asks the player to move around a visible threat instead of reading about stakes.

What is still weak:

* The hook is visually primitive because this phase forbids art work.
* The first danger beat is a dodge/positioning pulse, not a real combat lesson.
* The Oakhaven transition still enters the old overworld/region flow, so Chapter 1 objective and quest clarity remain unresolved.
* Runtime validation did not complete, so there may be GDScript or scene-load issues that static checks cannot catch.
* If the player ignores the signal and wanders, the scene has only light environmental affordance; it may still need stronger blocking or prompt timing after validation.

What may still make players quit:

* The opening scene may look like a debug prototype until visual cleanup happens.
* If the interaction prompt does not appear correctly at runtime, the first objective will stall.
* If the overworld route after the hook remains unclear, the retention problem moves from minute one to minute two.
* No emotional anchor is physically present yet; Elara is only teased through the signal.
* No reward UI confirms progress beyond the local message and breadcrumb.

## 6. Validation results

| Check | Expected | Actual | Pass/Fail | Evidence path/log |
|---|---|---|---|---|
| AGENTS.md read | Read before edits | Read and followed | Pass | Conversation/tool context |
| Godot version | Godot 4.6.3 | `4.6.3.stable.official.7d41c59c4` | Pass | Console output |
| Project boot | Clean headless boot | Timed out; crash-handler emitted signal 11 after timeout | Fail | Godot console output |
| New Game route check | Routes to new hook | Static code confirms `OPENING_HOOK_SCENE` target | Static pass / runtime unproven | `docs/gameplay_audit/phase_10n_a2_opening_hook/diagnostics/opening_hook_static_validation.json` |
| First playable scene reached | Runtime reaches hook scene | Not validated at runtime | Fail | Godot headless timeout |
| Player node exists | Runtime hook has player | Static script creates `Player` from existing player scene | Static pass / runtime unproven | Static validation JSON |
| Movement input changes position | Input moves player | Not validated at runtime | Fail | Godot headless timeout |
| First objective text exists | Objective is visible and not stale | Static code has local HUD and breadcrumb objective | Static pass / runtime unproven | Static validation JSON |
| Interactable exists | At least one interactable in scene | Static code creates `SignalFragment` in group `interactable` | Static pass / runtime unproven | Static validation JSON |
| Danger/curiosity beat exists | Pulse and curiosity line exist | Static code creates `GlitchPulse` and signal line | Static pass / runtime unproven | Static validation JSON |
| Old cinematic route callable | Legacy/debug route remains | Static code has `LEGACY_PROLOGUE_SCENE` and `_start_legacy_cinematic_prologue()` | Static pass / runtime unproven | Static validation JSON |
| Protected asset folders | No A2 edits | No A2 writes performed; dirty asset status is pre-existing | Pass with pre-existing dirt | Git status output |
| Chapter 2+ protected content | No edits | No A2 edits detected under Chapter 2+ scenes/scripts | Pass | Git status output |
| `git diff --check` | No whitespace errors | Exit 0; warnings only for pre-existing CRLF normalization in `docs/art_pipeline/art_replacement_manifest.md` and `scripts/asset_manager.gd` | Pass with warnings | Console output |

## 7. Live play / screenshot honesty

Live headed play unavailable

No real headed play happened. No live viewport screenshot was captured. No headless screenshot was captured. The Godot headless boot, check-only, and validation script attempts timed out and emitted a signal 11 crash-handler backtrace after the tool timeout. The only completed evidence for the new route is code/static scene evidence plus offline static validation JSON.

## 8. Protected path status

| Protected path/system | A2 touched? | Notes |
|---|---:|---|
| `assets/art_sources` | No | Pre-existing untracked files/imports are present from earlier phases. |
| `assets/production_art` | No | Pre-existing untracked production import files/folders are present from earlier phases. |
| `assets/generated_v2` | No | No A2 writes. |
| `assets/generated_v3` | No | No A2 writes. |
| Chapter 2+ scenes/scripts | No | No A2 edits under Chapter 2+. |
| ComfyUI/art pipeline | No | Not touched. |
| AssetManager | No A2 edit | `scripts/asset_manager.gd` is already modified from earlier work; not touched in A2. |
| Save schema | No | Added default story flags only; no save version/schema migration. |
| Combat/collision/world travel/NG+/Source Key/true ending | No broad edits | NG+ route remains legacy prologue. |

Pre-existing dirty files observed before and after A2 include:

* `scripts/asset_manager.gd`
* `scripts/regions/late_revisit_hub.gd`
* many untracked prior art/source/import folders under `assets/art_sources` and `assets/production_art`
* prior docs/art pipeline outputs

## 9. Rollback plan

1. In `scripts/main_menu.gd`, change `_on_new_game_pressed()` back to `SceneTransitions.change_scene("res://scenes/prologue/flight_707.tscn")`.
2. Remove `OPENING_HOOK_SCENE`, `LEGACY_PROLOGUE_SCENE`, `_start_legacy_cinematic_prologue()`, and `_add_legacy_prologue_debug_button()` if the debug route is not wanted.
3. Remove the four `ch1_opening_hook_*` default flags from `scripts/game_manager.gd`.
4. Remove the three 10N-A2 objective entries from `scripts/ui/progression_breadcrumb.gd`.
5. Delete `scenes/chapter1/opening_crash_site_hook.tscn`.
6. Delete `scripts/chapter1/ch1_opening_crash_site_hook.gd`.
7. Delete `docs/gameplay_audit/phase_10n_a2_opening_hook/` if the audit artifacts are not needed.

Fallback behavior:

* If the new hook scene is missing, `main_menu.gd` logs a warning and falls back to the legacy cinematic prologue.
* The explicit debug legacy route also remains callable in debug builds.

## 10. Next best step

Recommend one next phase only:

10N-A2.1 - headed/runtime validation and first-minute bug fix pass.

Goal: run the new opening in a real headed viewport or a reliable Godot runtime session, confirm the player moves, confirm `SignalFragment` prompt/interaction works, confirm `GlitchPulse` and `OakhavenPath` work, then fix only concrete runtime issues. Do not start 10N-A3 until the first-minute hook has real runtime evidence.

Final decision:

10N-A2 not ready — opening hook still blocked

