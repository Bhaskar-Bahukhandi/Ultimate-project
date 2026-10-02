# PHASE 10N-A2.8 HEADED FIRST-MINUTE FIX REPORT

## 1. Executive verdict

* Runtime fixes made: Yes
* Computer Use headed validation happened: No
* Menu cleanup validated: Yes by `CORRECTED HEADLESS RUNTIME EVIDENCE`; No by headed screenshot evidence
* Signal interaction headed-validated: No
* GlitchPulse headed-validated: No
* OakhavenPath headed-validated: No
* A2 ready for A3: No
* Final recommendation: `Manual human playtest required`

Computer Use viewport control unavailable — A2.8 headed validation incomplete

A2.8 fixed the menu surface and first-minute interaction path in code and corrected headless runtime probes. It did not satisfy the phase's acceptance gate because the Computer Use runtime failed before visible viewport control, so no A2.8 headed screenshots were captured.

Final decision: `Computer Use validation unavailable — manual human playtest required`

## 2. Files changed

| File | Change | Reason | Risk | Rollback |
|---|---|---|---|---|
| `scripts/main_menu.gd` | Added `_configure_public_menu_surface()` and call from `_ready()`; hides Skip Prologue, Chapter Select, Completion, and legacy debug button from the normal menu; preserves legacy route method. | Remove debug/dev options from the fresh-player path without deleting routes. | Low-medium; menu visibility only. | Revert `_configure_public_menu_surface()` and its `_ready()` call. |
| `scripts/chapter1/ch1_opening_crash_site_hook.gd` | Added generous hook-local F/E signal and path interaction range, prompt sync, world prompt visibility, named CONNECTED marker, signal color feedback, pulse one-shot proximity fallback, and Oakhaven marker visibility. | Make visible prompt/range/action/success align for first-minute validation. | Medium; first-minute hook behavior only. | Revert A2.8 constants, vars, `_input`, prompt sync, proximity trigger, signal label naming/feedback, and pulse guard changes. |
| `docs/gameplay_audit/phase_10n_a2_8_headed_first_minute_fix/tools/*.gd` | Added seven corrected headless probes. | Required validation evidence. | Low; docs-only. | Delete A2.8 docs folder. |
| `docs/gameplay_audit/phase_10n_a2_8_headed_first_minute_fix/diagnostics/*` | Added probe logs/JSON, command summary, and Computer Use bootstrap error. | Required validation evidence. | Low; docs-only. | Delete A2.8 docs folder. |
| `docs/gameplay_audit/phase_10n_a2_8_headed_first_minute_fix/*.json` | Added screenshot manifest, headed timeline, and issue/fix matrix. | Required deliverables. | Low; docs-only. | Delete files. |
| `docs/gameplay_audit/phase_10n_a2_8_headed_first_minute_fix/headed_first_minute_fix_report.md` | Added this report. | Required deliverable. | Low; docs-only. | Delete file. |

## 3. Menu cleanup

Before problem: `COMPUTER USE SCREENSHOT EVIDENCE` from A2.7 showed the first menu exposing `DEBUG: LEGACY CINEMATIC START`, `SKIP PROLOGUE`, `CHAPTER SELECT`, and `COMPLETION`.

Fix: `STATIC CODE EVIDENCE` and `CORRECTED HEADLESS RUNTIME EVIDENCE` show `_configure_public_menu_surface()` hides/disables those normal-menu buttons while preserving `_start_legacy_cinematic_prologue()` and the legacy prologue scene resource.

Screenshot evidence: `NOT VALIDATED` in A2.8. Required screenshot `screenshots/01_menu_after_cleanup.png` was not captured because Computer Use failed at bootstrap.

Legacy route preservation: `CORRECTED HEADLESS RUNTIME EVIDENCE`; `probe_01_menu_public_surface` and `probe_05_oakhaven_path_reachability` confirm the legacy scene still exists/can be referenced.

## 4. SignalFragment reliability fix

Root cause hypothesis: `INFERENCE` from A2.7 screenshots and code suggested the visible static `[F/E] interact` label could be seen before the player was reliably inside the actual interaction path, and the player controller's nearby-interactable signal could fail to produce immediate visible feedback in headed play.

Fix:

* Increased SignalFragment collision radius from 42 to 110.
* Added hook-local `SIGNAL_INTERACTION_RANGE := 150.0`.
* Added hook-local `_input()` fallback so `interact`/F and `root_access`/E call `_on_signalfragment_interaction()` when the player is in range.
* Local player prompt is forced visible only inside the hook-local success range.
* World `[F/E] interact` prompt is hidden until the player is in range.
* Signal turns green and shows `CONNECTED` after success.

Headless result: `CORRECTED HEADLESS RUNTIME EVIDENCE`; `probe_02_signal_interaction_range` passed after probe timing repair, and `probe_03_signal_success_feedback` passed after naming the success label for validation.

Headed result: `NOT VALIDATED`. No A2.8 viewport control or screenshots occurred.

## 5. GlitchPulse and OakhavenPath validation

Pulse visibility: `CORRECTED HEADLESS RUNTIME EVIDENCE`; `probe_03` confirms the pulse arms after signal interaction.

Pulse consequence: `CORRECTED HEADLESS RUNTIME EVIDENCE`; `probe_04` confirms danger flag, knockback/feedback marker, and HP unchanged.

Oakhaven marker: `CORRECTED HEADLESS RUNTIME EVIDENCE`; path label becomes visible after signal success, path marker brightens, and completion flags validate in `probe_05`/`probe_06`.

Transition/arrival: `NOT VALIDATED` in headed play. Headless probes validate flags, not the visible transition feel.

## 6. Headless validation matrix

| Probe | Result | Evidence type | JSON | Log | Notes |
|---|---|---|---|---|---|
| `probe_00_boot_corrected` | Pass | `CORRECTED HEADLESS RUNTIME EVIDENCE` | `diagnostics/probe_00_boot_corrected.json` | `diagnostics/probe_00_boot_corrected.log` | Project/autoload boot works. |
| `probe_01_menu_public_surface` | Pass | `CORRECTED HEADLESS RUNTIME EVIDENCE` | `diagnostics/probe_01_menu_public_surface.json` | `diagnostics/probe_01_menu_public_surface.log` | Public menu hides debug/dev buttons; legacy route remains internally callable. |
| `probe_02_signal_interaction_range` | Pass after probe timing repair | `CORRECTED HEADLESS RUNTIME EVIDENCE` | `diagnostics/probe_02_signal_interaction_range.json` | `diagnostics/probe_02_signal_interaction_range.log` | F and E set signal flag in prompt range; far prompt stays hidden and far action does not set flag. |
| `probe_03_signal_success_feedback` | Pass after success-label naming/probe repair | `CORRECTED HEADLESS RUNTIME EVIDENCE` | `diagnostics/probe_03_signal_success_feedback.json` | `diagnostics/probe_03_signal_success_feedback.log` | Objective changes, signal turns green, CONNECTED marker visible, pulse/path marker active. |
| `probe_04_glitch_pulse_feedback` | Pass | `CORRECTED HEADLESS RUNTIME EVIDENCE` | `diagnostics/probe_04_glitch_pulse_feedback.json` | `diagnostics/probe_04_glitch_pulse_feedback.log` | Danger flag and feedback marker set; HP unchanged. |
| `probe_05_oakhaven_path_reachability` | Pass | `CORRECTED HEADLESS RUNTIME EVIDENCE` | `diagnostics/probe_05_oakhaven_path_reachability.json` | `diagnostics/probe_05_oakhaven_path_reachability.log` | Completion and compatibility flags set; legacy route exists. |
| `probe_06_full_smoke_after_fix` | Pass | `CORRECTED HEADLESS RUNTIME EVIDENCE` | `diagnostics/probe_06_full_smoke_after_fix.json` | `diagnostics/probe_06_full_smoke_after_fix.log` | Smoke path: move, signal, pulse, completion flags. |

Known validation notes: logs still include the pre-existing Kaelen production-art fallback warning. Some headless probes report ObjectDB leak warnings on exit from timer/tween cleanup, matching earlier harness behavior and not a gameplay crash.

## 7. Computer Use headed timeline

| Event | Time | Evidence type | Result | Notes |
|---|---:|---|---|---|
| Computer Use bootstrap | N/A | `NOT VALIDATED` | Failed | `node_repl/js` failed with missing `sandboxPolicy` metadata before app/window control. |
| Menu visible | N/A | `NOT VALIDATED` | Not captured | No A2.8 screenshot. |
| New Game clicked | N/A | `NOT VALIDATED` | Not performed | No viewport control. |
| First control | N/A | `NOT VALIDATED` | Not observed | Headless only. |
| Signal prompt | N/A | `CORRECTED HEADLESS RUNTIME EVIDENCE` | Pass | Probe validation only. |
| Signal success | N/A | `CORRECTED HEADLESS RUNTIME EVIDENCE` | Pass | Probe validation only. |
| GlitchPulse | N/A | `CORRECTED HEADLESS RUNTIME EVIDENCE` | Pass | Probe validation only. |
| OakhavenPath | N/A | `CORRECTED HEADLESS RUNTIME EVIDENCE` | Pass | Probe validation only. |
| Transition/arrival | N/A | `NOT VALIDATED` | Not captured | Headed transition still required. |

## 8. Screenshot review

No A2.8 screenshots were captured.

Required screenshots not captured:

* `screenshots/01_menu_after_cleanup.png`
* `screenshots/02_first_playable_after_fix.png`
* `screenshots/03_signal_prompt_range.png`
* `screenshots/04_after_signal_success.png`
* `screenshots/05_glitch_pulse_visible.png`
* `screenshots/06_glitch_pulse_feedback.png`
* `screenshots/07_oakhaven_path_marker.png`
* `screenshots/08_transition_or_arrival.png`
* `screenshots/09_worst_remaining_visual_issue.png`

Reason: `Computer Use viewport control unavailable — A2.8 headed validation incomplete`.

## 9. Remaining issues

P0 blockers:

* Computer Use headed viewport validation did not happen.
* A2.8 cannot be accepted as passed because SignalFragment, GlitchPulse, and OakhavenPath need headed proof after the fix.

P1 retention risks:

* Opening still likely looks primitive/blockout-like; not visually rechecked after A2.8.
* Menu cleanup needs actual viewport screenshot confirmation.

P2 polish issues:

* Signal/pulse/path feedback is still primitive-only.
* Transition feel is still unvalidated.

Future issues:

* A3 objective clarity should wait until a headed/manual pass confirms the first-minute path now works.

## 10. Scorecard after A2.8

| Category | Score | Evidence type | Notes |
|---|---:|---|---|
| Menu professionalism | 7/10 | `CORRECTED HEADLESS RUNTIME EVIDENCE` | Public debug buttons hidden in code, but no screenshot. |
| First control clarity | 6/10 | `CORRECTED HEADLESS RUNTIME EVIDENCE` | A2.4/A2.6 validated movement; no A2.8 headed play. |
| Visual readability | 4/10 | `INFERENCE` | Primitive scene likely remains rough. |
| Signal interaction reliability | 7/10 | `CORRECTED HEADLESS RUNTIME EVIDENCE` | F/E/range/prompt now pass probes. |
| Prompt clarity | 7/10 | `CORRECTED HEADLESS RUNTIME EVIDENCE` | Prompt hidden until in success range; no headed proof. |
| GlitchPulse danger feel | 5/10 | `CORRECTED HEADLESS RUNTIME EVIDENCE` | Feedback exists mechanically; feel not seen. |
| OakhavenPath clarity | 6/10 | `CORRECTED HEADLESS RUNTIME EVIDENCE` | Marker/label/path pass probes; no screenshot. |
| First-minute retention | 5/10 | `INFERENCE` | Better structure, still visually unproven. |
| Readiness for A3 | 4/10 | `INFERENCE` | Needs headed/manual validation first. |

## 11. Protected path status

This phase intentionally edited only allowed runtime files and docs:

* `scripts/main_menu.gd`
* `scripts/chapter1/ch1_opening_crash_site_hook.gd`
* `docs/gameplay_audit/phase_10n_a2_8_headed_first_minute_fix/`

This phase did not edit:

* `assets/art_sources`
* `assets/production_art`
* `assets/generated_v2`
* `assets/generated_v3`
* ComfyUI/art pipeline
* AssetManager
* save schema
* Chapter 2+
* `project.godot`

`git diff --check` result: exit code 0; warnings only for CRLF/LF normalization in pre-existing files and `scripts/main_menu.gd`.

Pre-existing dirty/untracked files remain in assets/art pipeline outputs and earlier A2 files; they were not created by A2.8.

## 12. Next recommended phase

`Manual human playtest required`

Use the exact A2.8 manual validation path next:

1. Launch the game normally.
2. Confirm menu now shows only New Game, Load Game, Options, Credits, Quit, and any legitimate NG+ button.
3. Click New Game.
4. Move to SignalFragment.
5. Confirm `[F/E] interact` appears only when close enough.
6. Press F, then E if needed.
7. Confirm objective changes, Signal turns green/CONNECTED, pulse appears, and east marker appears.
8. Trigger GlitchPulse and confirm visible harmless feedback.
9. Move east to OakhavenPath and confirm route completion/transition.
10. Capture the required screenshots.

FINAL DECISION: `Computer Use validation unavailable — manual human playtest required`
