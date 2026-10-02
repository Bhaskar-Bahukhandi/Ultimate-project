# PHASE 10N-A2.6 FIRST-MINUTE MICRO-POLISH REPORT

## 1. Executive summary

* Implemented: Yes
* Runtime changes made: Yes
* Headed play happened: No
* Opening boundary polish: Pass by corrected headless runtime evidence
* Objective duplication reduced: Pass by corrected headless runtime evidence
* Prompt consistency fixed: Pass by corrected headless runtime evidence
* Signal readability improved: Pass by static/runtime node evidence, headed visual readability unproven
* GlitchPulse consequence added: Pass by corrected headless runtime evidence
* OakhavenPath clarity improved: Pass by static/runtime node evidence, headed visual readability unproven
* A2 ready for user manual headed playtest: Yes
* A2 ready for A3: No, not until headed visual/play-feel confirmation

Overall: A2.6 successfully adds small first-minute micro-polish without broad redesign, but no headed viewport play happened in A2.6.

## 2. Files changed

| File | Change | Reason | Risk | Rollback |
|---|---|---|---|---|
| `scripts/chapter1/ch1_opening_crash_site_hook.gd` | Added opening-only StaticBody2D route blockers, local breadcrumb suppression, F/E prompt alignment, SignalFragment readability primitives, GlitchPulse knockback/flash feedback, and Oakhaven east marker/prompt. | Fix high-confidence first-minute risks without touching broader Chapter 1 systems. | Medium-low; confined to A2 opening hook, but it changes movement boundaries and first-minute trigger feedback. | Revert the A2.6 additions in this file: route boundary helpers/call, prompt override helper, breadcrumb suppress/restore helpers, signal/path marker additions, pulse feedback fields/helper. |
| `docs/gameplay_audit/phase_10n_a2_6_first_minute_micro_polish/tools/*.gd` | Added seven corrected headless validation probes. | Validate boot, scene nodes, confused-player wandering, prompts, pulse consequence, completion flags, and smoke path. | Low; docs-only validation tools. | Delete the A2.6 docs folder. |
| `docs/gameplay_audit/phase_10n_a2_6_first_minute_micro_polish/diagnostics/*` | Added probe JSON/log evidence and command summary. | Preserve validation evidence. | Low; docs-only diagnostics. | Delete the A2.6 docs folder. |
| `docs/gameplay_audit/phase_10n_a2_6_first_minute_micro_polish/first_minute_micro_polish_report.md` | Added this phase report. | Required deliverable. | Low. | Delete this report. |

## 3. What changed in the first minute

The first-minute route is now more constrained and legible:

1. Player starts in the crash-site corridor.
2. Visible rubble/crater primitives block broad wandering away from the intended route.
3. Local opening HUD remains the authoritative objective surface while the hook is active.
4. Prompt text now says `F/E` consistently because both `interact` and `root_access` call the same interaction behavior.
5. SignalFragment has a primitive glow and `SIGNAL` marker.
6. Signal interaction arms GlitchPulse and updates the local objective toward Oakhaven.
7. GlitchPulse now knocks the player back slightly, flashes static, sets `ch1_opening_hook_danger_seen`, and does not damage the player.
8. OakhavenPath now has an east marker and `[F/E] Follow signal` metadata.
9. Completion still sets the A2 compatibility flags and restores the global breadcrumb.

## 4. Boundaries and confused-player behavior

Added opening-only blockers:

* `OpeningBoundaryWestRubble`
* `OpeningBoundaryNorthCrater`
* `OpeningBoundarySouthCrater`
* `OpeningBoundaryNorthRoad`
* `OpeningBoundarySouthRoad`
* `OpeningBoundaryExitGuardNorth`
* `OpeningBoundaryExitGuardSouth`

Corrected headless evidence:

* West wander stopped at x `157.004`, above the `145.0` escape threshold.
* Up wander stopped at y `303.004`, above the `295.0` escape threshold.
* Down wander stopped at y `519.996`, below the `555.0` escape threshold.
* SignalFragment remained reachable; final distance after route approach was `50.022`.

Softlock risk: no softlock was detected by the probe path, but headed feel is still not validated.

## 5. Objective and prompt behavior

The local opening HUD is authoritative during the hook. `ProgressionBreadcrumb.hide_breadcrumb()` is called while `ch1_opening_hook_started` is active and the hook is incomplete, then restored on completion or scene exit.

Prompt behavior:

* Opening HUD prompt: `Move with WASD. Press F or E at the signal fragment.`
* SignalFragment metadata: `[F/E] Interact`
* Player floating prompt near SignalFragment: `[F/E] Interact`
* OakhavenPath metadata: `[F/E] Follow signal`

This avoids the earlier first-minute mismatch where the scene implied one key while the player controller accepted both `F` and `E`.

Visible first-minute mojibake cleanup: no local hook strings needed global encoding repair. The global breadcrumb still contains broader mojibake in its source, but it is now hidden during the opening hook, so that specific first-minute duplicate/malformed surface is suppressed. No global text rewrite was done.

## 6. SignalFragment and GlitchPulse changes

SignalFragment:

* Added `SignalReadabilityGlow`.
* Added `SignalImportanceMarker` label.
* Changed nearby world prompt to `[F/E] interact`.
* Added `opening_prompt_text` metadata for hook-local prompt override.

GlitchPulse:

* Added `GlitchPulseFeedbackFlash` to the local HUD layer.
* Added harmless fixed knockback `Vector2(-58, 0)`.
* Clears player velocity after knockback.
* Sets `_last_pulse_feedback_triggered` for validation.
* Keeps `ch1_opening_hook_danger_seen`.
* Does not change HP, trigger combat, or create retry/death logic.

Why this is safer: it makes the danger beat mechanically real without introducing damage, failure, combat balance, save/retry, or broader controller changes.

## 7. Validation matrix

| Probe | Result | Evidence type | JSON | Log | Notes |
|---|---|---|---|---|---|
| `probe_00_boot_corrected` | Pass | CORRECTED HEADLESS RUNTIME EVIDENCE | `diagnostics/probe_00_boot_corrected.json` | `diagnostics/probe_00_boot_corrected.log` | Corrected project boot/autoloads worked. |
| `probe_01_opening_scene_nodes` | Pass | CORRECTED HEADLESS RUNTIME EVIDENCE | `diagnostics/probe_01_opening_scene_nodes.json` | `diagnostics/probe_01_opening_scene_nodes.log` | Player, camera, HUD, SignalFragment, glow, GlitchPulse, OakhavenPath, boundaries, and breadcrumb suppression detected. |
| `probe_02_confused_player_wander` | Pass | CORRECTED HEADLESS RUNTIME EVIDENCE | `diagnostics/probe_02_confused_player_wander.json` | `diagnostics/probe_02_confused_player_wander.log` | Wrong-direction wandering constrained; signal still reachable. |
| `probe_03_signal_prompt_readability` | Pass | CORRECTED HEADLESS RUNTIME EVIDENCE | `diagnostics/probe_03_signal_prompt_readability.json` | `diagnostics/probe_03_signal_prompt_readability.log` | `F/E` actions exist; prompt metadata and floating prompt match; signal flag set. |
| `probe_04_glitch_pulse_consequence` | Pass | CORRECTED HEADLESS RUNTIME EVIDENCE | `diagnostics/probe_04_glitch_pulse_consequence.json` | `diagnostics/probe_04_glitch_pulse_consequence.log` | Pulse armed; danger flag set; knockback happened; HP stayed `100 -> 100`. |
| `probe_05_oakhaven_path_completion` | Pass | CORRECTED HEADLESS RUNTIME EVIDENCE | `diagnostics/probe_05_oakhaven_path_completion.json` | `diagnostics/probe_05_oakhaven_path_completion.log` | Compatibility flags false before completion and true after; legacy route detected. |
| `probe_06_full_smoke_micro_polish` | Pass | CORRECTED HEADLESS RUNTIME EVIDENCE | `diagnostics/probe_06_full_smoke_micro_polish.json` | `diagnostics/probe_06_full_smoke_micro_polish.log` | Full smoke path passed through blocked edge, signal, pulse, and completion flags. |

Harness notes:

* An initial custom `ProcessStartInfo` runner timed out before probe markers because its argument handling did not match the A2.4 command mode.
* Final validation used direct PowerShell call-operator Godot commands with explicit `--log-file`, matching A2.4.
* Probe scripts were repaired to use `SceneTree._initialize()` and avoid the reserved local variable name `signal`.
* One runtime parse warning in `_sync_opening_interaction_prompt()` was fixed by explicitly typing the local `Variant`.
* Godot logs still show the pre-existing Kaelen top-down production-art warning and generated fallback use.
* Probes 03-06 still show ObjectDB leak warnings from early headless quit while tweens/async timers exist; no probe failed from this.

## 8. Remaining risks

* No headed viewport play happened in A2.6.
* Player feel, blocker naturalness, and visual readability are still not proven.
* Signal glow/marker and Oakhaven marker are primitive-only and may look rough in a real viewport.
* The GlitchPulse feedback is mechanically real but may still feel weak or visually crude without headed review.
* First quest structure still needs A3.
* Save/retry flow is still not validated by this phase.
* Full transition feel into overworld/Oakhaven was not visually validated.

## 9. Manual headed checklist for user

1. Open the project in Godot.
2. Run the game normally.
3. Click New Game.
4. Confirm first control timing.
5. Try walking away from the intended route before touching SignalFragment.
6. Confirm blockers feel natural instead of arbitrary.
7. Confirm SignalFragment is visually obvious.
8. Confirm prompt key text is correct and not duplicated.
9. Trigger GlitchPulse and describe the feedback: knockback, flash, camera shake, message.
10. Walk to OakhavenPath and confirm the east marker and transition are clear.
11. Take screenshots of any ugly/confusing parts.

## 10. Protected path status

This phase did not intentionally edit:

* `assets/art_sources`
* `assets/production_art`
* `assets/generated_v2`
* `assets/generated_v3`
* Chapter 2+ content
* ComfyUI/art pipeline
* `scripts/asset_manager.gd`
* save schema
* `project.godot`

Allowed A2.6 runtime edit:

* `scripts/chapter1/ch1_opening_crash_site_hook.gd`

Pre-existing dirty state observed:

* Many art source/import files were already untracked before A2.6.
* `scripts/asset_manager.gd` was already modified before A2.6.
* `scenes/chapter1/opening_crash_site_hook.tscn` and `scripts/chapter1/ch1_opening_crash_site_hook.gd` were already untracked A2 files before A2.6.

`git diff --check` result:

* Exit code `0`.
* Warnings only: CRLF/LF normalization warnings for `docs/art_pipeline/art_replacement_manifest.md` and `scripts/asset_manager.gd`.

## 11. Next recommended phase

`10N-A2.7 user manual headed playtest evidence intake`

Final decision: `A2.6 micro-polish passed — user manual headed playtest required`
