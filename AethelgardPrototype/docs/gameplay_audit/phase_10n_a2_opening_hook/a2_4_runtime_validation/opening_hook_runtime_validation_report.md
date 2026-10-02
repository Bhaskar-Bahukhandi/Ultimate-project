# PHASE 10N-A2.4 OPENING HOOK RUNTIME VALIDATION REPORT

## 1. Summary

* Corrected command mode used: Yes
* Opening hook scene reached: Yes
* Opening hook scene proven broken: No
* Opening hook scene runtime validated: Yes
* Player movement validated: Yes
* Signal interaction validated: Yes
* GlitchPulse validated: Yes
* OakhavenPath validated: Yes
* Legacy route preserved: Yes
* A2 ready for manual headed play check: Yes
* A2 ready for A3: No
* Final verdict: The A2 opening hook passes corrected headless runtime validation. No headed viewport play happened in A2.4, so the next safe step is manual headed playtest before A3.

## 2. Command mode

* Godot executable: `C:\Godot\Godot_v4.6.3-stable_win64_console.exe`
* Log-file strategy: every project-context Godot command used `--log-file` with a dedicated writable log under `docs/gameplay_audit/phase_10n_a2_opening_hook/a2_4_runtime_validation/diagnostics/`.
* Process state before probes: no Godot process was detected before A2.4 probes.
* Why previous signal 11 issue is avoided: A2.3 showed the unlogged/sandboxed project-context launch could crash before script markers. A2.4 used the corrected mode: elevated filesystem access for the project path plus explicit writable log paths.

## 3. Probe matrix

| Probe | Purpose | Result | Evidence type | JSON | Log | Error/Notes |
|---|---|---|---|---|---|---|
| `probe_00_project_boot_corrected` | Prove corrected project-context launch and key autoload presence. | Pass | CORRECTED HEADLESS RUNTIME EVIDENCE | `docs/gameplay_audit/phase_10n_a2_opening_hook/a2_4_runtime_validation/diagnostics/probe_00_project_boot_corrected.json` | `docs/gameplay_audit/phase_10n_a2_opening_hook/a2_4_runtime_validation/diagnostics/probe_00_project_boot_corrected.log` | Autoloads found: AssetManager, GameManager, Inventory, ProgressionBreadcrumb, SceneTransitions. |
| `probe_01_new_game_route` | Confirm New Game target and legacy route target. | Pass | STATIC CODE EVIDENCE | `docs/gameplay_audit/phase_10n_a2_opening_hook/a2_4_runtime_validation/diagnostics/probe_01_new_game_route.json` | `docs/gameplay_audit/phase_10n_a2_opening_hook/a2_4_runtime_validation/diagnostics/probe_01_new_game_route.log` | New Game route points to `res://scenes/chapter1/opening_crash_site_hook.tscn`; legacy route points to `res://scenes/prologue/flight_707.tscn`. |
| `probe_02_load_opening_scene` | Load opening scene as PackedScene only. | Pass | CORRECTED HEADLESS RUNTIME EVIDENCE | `docs/gameplay_audit/phase_10n_a2_opening_hook/a2_4_runtime_validation/diagnostics/probe_02_load_opening_scene.json` | `docs/gameplay_audit/phase_10n_a2_opening_hook/a2_4_runtime_validation/diagnostics/probe_02_load_opening_scene.log` | PackedScene load succeeded. |
| `probe_03_instantiate_opening_scene` | Instantiate opening scene and report key nodes. | Pass | CORRECTED HEADLESS RUNTIME EVIDENCE | `docs/gameplay_audit/phase_10n_a2_opening_hook/a2_4_runtime_validation/diagnostics/probe_03_instantiate_opening_scene.json` | `docs/gameplay_audit/phase_10n_a2_opening_hook/a2_4_runtime_validation/diagnostics/probe_03_instantiate_opening_scene.log` | Player, camera, objective label, SignalFragment, GlitchPulse, OakhavenPath, and HUD found. |
| `probe_04_player_movement` | Simulate `move_right` and verify player position changes. | Pass | CORRECTED HEADLESS RUNTIME EVIDENCE | `docs/gameplay_audit/phase_10n_a2_opening_hook/a2_4_runtime_validation/diagnostics/probe_04_player_movement.json` | `docs/gameplay_audit/phase_10n_a2_opening_hook/a2_4_runtime_validation/diagnostics/probe_04_player_movement.log` | Player moved from `(250.000, 420.000)` to `(278.586, 420.000)`; camera exists/current. |
| `probe_05_signal_interaction` | Validate SignalFragment interaction path and signal flag. | Pass | CORRECTED HEADLESS RUNTIME EVIDENCE | `docs/gameplay_audit/phase_10n_a2_opening_hook/a2_4_runtime_validation/diagnostics/probe_05_signal_interaction.json` | `docs/gameplay_audit/phase_10n_a2_opening_hook/a2_4_runtime_validation/diagnostics/probe_05_signal_interaction.log` | Used `Player._interact_with(SignalFragment)`. `ch1_opening_hook_signal_found` set true; objective updated; pulse armed. |
| `probe_06_glitch_pulse` | Validate GlitchPulse danger path and flag. | Pass | CORRECTED HEADLESS RUNTIME EVIDENCE | `docs/gameplay_audit/phase_10n_a2_opening_hook/a2_4_runtime_validation/diagnostics/probe_06_glitch_pulse.json` | `docs/gameplay_audit/phase_10n_a2_opening_hook/a2_4_runtime_validation/diagnostics/probe_06_glitch_pulse.log` | Called `_on_glitch_pulse_body_entered(Player)` after signal interaction. `ch1_opening_hook_danger_seen` set true. |
| `probe_07_oakhaven_path_completion` | Validate OakhavenPath completion flags without letting transition proceed fully. | Pass | CORRECTED HEADLESS RUNTIME EVIDENCE | `docs/gameplay_audit/phase_10n_a2_opening_hook/a2_4_runtime_validation/diagnostics/probe_07_oakhaven_path_completion.json` | `docs/gameplay_audit/phase_10n_a2_opening_hook/a2_4_runtime_validation/diagnostics/probe_07_oakhaven_path_completion.log` | Before completion, compatibility flags were false. `_complete_opening_hook()` set `plane_crash_completed`, `ch1_awakening_complete`, `ch1_glitch_crater_complete`, and `ch1_opening_hook_complete` true. |
| `probe_08_full_first_minute_smoke` | Run short smoke path: load, movement, signal, pulse, completion. | Pass | CORRECTED HEADLESS RUNTIME EVIDENCE | `docs/gameplay_audit/phase_10n_a2_opening_hook/a2_4_runtime_validation/diagnostics/probe_08_full_first_minute_smoke.json` | `docs/gameplay_audit/phase_10n_a2_opening_hook/a2_4_runtime_validation/diagnostics/probe_08_full_first_minute_smoke.log` | Full smoke path completed in 479 ms. |

## 4. Opening hook runtime state

| Runtime item                | Status | Evidence |
| --------------------------- | ------ | -------- |
| scene loads                 | Pass | `probe_02_load_opening_scene.json` |
| scene instantiates          | Pass | `probe_03_instantiate_opening_scene.json` |
| player exists               | Pass | `probe_03_instantiate_opening_scene.json` |
| movement works              | Pass | `probe_04_player_movement.json` |
| camera exists               | Pass | `probe_03_instantiate_opening_scene.json`, `probe_04_player_movement.json` |
| objective label exists      | Pass | `probe_03_instantiate_opening_scene.json` |
| SignalFragment exists       | Pass | `probe_03_instantiate_opening_scene.json`, `probe_05_signal_interaction.json` |
| signal interaction works    | Pass | `probe_05_signal_interaction.json` |
| GlitchPulse exists          | Pass | `probe_03_instantiate_opening_scene.json`, `probe_06_glitch_pulse.json` |
| danger flag works           | Pass | `probe_06_glitch_pulse.json` |
| OakhavenPath exists         | Pass | `probe_03_instantiate_opening_scene.json`, `probe_07_oakhaven_path_completion.json` |
| completion flag works       | Pass | `probe_07_oakhaven_path_completion.json`, `probe_08_full_first_minute_smoke.json` |
| compatibility flags correct | Pass | `probe_07_oakhaven_path_completion.json` |

## 5. Bugs found and fixes made

No A2 opening-hook runtime bugs were found, and no gameplay scripts or scenes were changed in A2.4.

Validation harness repairs were made only under `docs/gameplay_audit/phase_10n_a2_opening_hook/a2_4_runtime_validation/tools/`:

* `probe_00_project_boot_corrected.gd`: replaced invalid `SceneTree.has_node()` style check with root-node lookup.
* `probe_01_new_game_route.gd`: added explicit boolean typing where Godot could not infer a local variable type.
* `probe_05_signal_interaction.gd` through `probe_08_full_first_minute_smoke.gd`: replaced direct singleton references from validation scripts with dynamic root lookup/calls so the scripts compile as standalone SceneTree scripts.
* `probe_05_signal_interaction.gd` through `probe_08_full_first_minute_smoke.gd`: removed broad `GameManager.reset_game()` calls from probes and used targeted in-memory flag clearing instead to avoid harness-side absolute-node errors.
* `probe_05_signal_interaction.gd` through `probe_08_full_first_minute_smoke.gd`: fixed validation-script indentation/type issues found during probe execution.

These were validation harness fixes, not opening hook design or gameplay fixes. Dependent probes were rerun after repair and passed.

## 6. Remaining risks

* No headed viewport play happened in A2.4.
* Actual player feel is not validated by headless probes.
* UI readability and visual glitches are not validated by headless probes.
* Save persistence is not validated; probes intentionally used per-process in-memory flag mutation.
* Full New Game button clicking was not performed; route target and fallback were validated from code/static resource evidence.
* The transition to overworld was not allowed to complete fully in `probe_07`; completion flags were verified before the timer-driven transition side effect.
* `probe_07` and `probe_08` logs include ObjectDB leak warnings from quitting while scene timers/tweens are still live. This is a validation harness limitation, not evidence of an opening-hook gameplay crash.
* Logs include an existing AssetManager warning that Kaelen production art is missing and generated fallback is used. This is pre-existing and unrelated to A2.4.
* Fun, pacing, player comprehension, and retention are still not validated without a headed/manual playtest.

## 7. Manual headed playtest checklist

Because no headed viewport play happened in A2.4, use this exact manual checklist next:

1. Close stale Godot validation processes if any are open.
2. Open the project in Godot.
3. Open `scenes/chapter1/opening_crash_site_hook.tscn`.
4. Run Current Scene.
5. Confirm the player is visible.
6. Confirm WASD movement feels responsive.
7. Confirm the initial objective text is visible and readable.
8. Walk to `SignalFragment` and press interact.
9. Confirm objective/message/flag behavior changes after interaction.
10. Walk into `GlitchPulse` and confirm the danger beat is visible and not confusing.
11. Walk toward `OakhavenPath` and confirm completion/transition behavior.
12. Record exact errors, screenshots, or observations.

## 8. Files created/modified

### A2.4-created tools/logs/reports

* `docs/gameplay_audit/phase_10n_a2_opening_hook/a2_4_runtime_validation/tools/probe_00_project_boot_corrected.gd`
* `docs/gameplay_audit/phase_10n_a2_opening_hook/a2_4_runtime_validation/tools/probe_01_new_game_route.gd`
* `docs/gameplay_audit/phase_10n_a2_opening_hook/a2_4_runtime_validation/tools/probe_02_load_opening_scene.gd`
* `docs/gameplay_audit/phase_10n_a2_opening_hook/a2_4_runtime_validation/tools/probe_03_instantiate_opening_scene.gd`
* `docs/gameplay_audit/phase_10n_a2_opening_hook/a2_4_runtime_validation/tools/probe_04_player_movement.gd`
* `docs/gameplay_audit/phase_10n_a2_opening_hook/a2_4_runtime_validation/tools/probe_05_signal_interaction.gd`
* `docs/gameplay_audit/phase_10n_a2_opening_hook/a2_4_runtime_validation/tools/probe_06_glitch_pulse.gd`
* `docs/gameplay_audit/phase_10n_a2_opening_hook/a2_4_runtime_validation/tools/probe_07_oakhaven_path_completion.gd`
* `docs/gameplay_audit/phase_10n_a2_opening_hook/a2_4_runtime_validation/tools/probe_08_full_first_minute_smoke.gd`
* `docs/gameplay_audit/phase_10n_a2_opening_hook/a2_4_runtime_validation/diagnostics/*.json`
* `docs/gameplay_audit/phase_10n_a2_opening_hook/a2_4_runtime_validation/diagnostics/*.log`
* `docs/gameplay_audit/phase_10n_a2_opening_hook/a2_4_runtime_validation/opening_hook_runtime_validation_report.md`

### A2.4 runtime code changes

None.

### Pre-existing A2/A2.1/A2.2/A2.3 changes

Pre-existing A2-family files remain in the worktree, including the opening hook scene/script, routing changes, prior validation scripts, and prior reports. A2.4 did not modify those runtime files.

### Pre-existing dirty files

The repository contains pre-existing dirty/untracked files from earlier phases, including prior art pipeline reports/assets and A2 implementation files. They are separate from A2.4 validation outputs.

## 9. Protected path status

A2.4 did not touch:

* `assets/art_sources`
* `assets/production_art`
* `assets/generated_v2`
* `assets/generated_v3`
* Chapter 2+
* ComfyUI/art pipeline
* AssetManager
* save schema

`git diff --check` exited with code 0. It reported CRLF normalization warnings for pre-existing files only:

* `docs/art_pipeline/art_replacement_manifest.md`
* `scripts/asset_manager.gd`

No whitespace-error failure was reported.

## 10. Next recommended phase

`10N-A2.5 manual headed playtest`

A2.4 validates the runtime path in corrected headless mode, but a headed/manual pass is still required before A3 because the opening's visual presentation, input feel, UI readability, and retention value cannot be judged from headless probes.

FINAL DECISION: A2 runtime validated — ready for manual headed playtest
