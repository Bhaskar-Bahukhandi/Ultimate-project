# PHASE 10N-A2.3 PROJECT BOOT / AUTOLOAD / VALIDATION HARNESS REPORT

## 1. Summary

* Project-context crash reproduced: Yes, in sandboxed project-context command forms.
* Smallest failing command: C:\Godot\Godot_v4.6.3-stable_win64_console.exe --path "C:\Users\BHASKAR BAHUKHANDI\OneDrive\Desktop\Ultimate project\AethelgardPrototype" --headless --quit
* First marker printed: No in sandboxed project-context forms; yes in corrected elevated/log-file project-context form.
* Existing Godot process conflict: No visible Godot process before probes.
* Crash category: Command-line environment / filesystem log-path issue, not proven autoload or opening-hook breakage.
* Opening hook scene reached: No.
* Opening hook scene proven broken: No.
* Recommended next action: Use the corrected launch mode for A2 opening-hook runtime validation or headed/manual play check.

## 2. Process state

* Existing Godot processes: None visible through Get-Process immediately before A2.3 probes.
* Command lines if available: Not available; earlier CIM command-line inspection returned access denied.
* Editor likely open: No evidence from the normal process list.
* Stale process risk: Low before probes. One elevated sandbox --quit attempt later left PIDs 356 and 24760; both were from this A2.3 command and were stopped.
* Whether probes were allowed to continue: Yes. The process-conflict gate was clear.

Process state evidence: docs/gameplay_audit/phase_10n_a2_opening_hook/a2_3_project_boot_autoload_repair/diagnostics/process_state_before.json

## 3. Command form matrix

| Test | Command form | Working dir | Result | Exit code | Signal 11 | Marker printed | JSON written | Classification |
|---|---|---|---|---:|---:|---:|---:|---|
| A | --version | C:\Users\BHASKAR BAHUKHANDI\OneDrive\Desktop\Ultimate project\AethelgardPrototype | Pass | 0 | False | False | False | Godot executable works. |
| B | no project context, absolute script path | C:\tmp | Pass | 0 | False | True | False | Script body works outside project context. |
| C | --path project + --headless + res:// script | C:\Users\BHASKAR BAHUKHANDI\OneDrive\Desktop\Ultimate project\AethelgardPrototype | Crash | 124 | True | False | False | Sandboxed project-context startup crashed before script marker. |
| D | project working directory + --headless + res:// script | C:\Users\BHASKAR BAHUKHANDI\OneDrive\Desktop\Ultimate project\AethelgardPrototype | Crash | 124 | True | False | False | Crash is not specific to --path syntax. |
| E | --path project + --headless + absolute script | C:\Users\BHASKAR BAHUKHANDI\OneDrive\Desktop\Ultimate project\AethelgardPrototype | Crash | 124 | True | False | False | Crash is not specific to res:// script path resolution. |
| F | --path project + --headless + --quit | C:\Users\BHASKAR BAHUKHANDI\OneDrive\Desktop\Ultimate project\AethelgardPrototype | Crash | 124 | True | False | False | Project-context startup can crash with no validation script at all. |
| G | sandbox reduced no-autoload project, sandboxed | C:\tmp | Crash | 1 | True | False | False | Crash reproduced without project autoloads; user://logs write failure is the first concrete error. |
| H | real project, elevated filesystem, explicit log, --quit-after 1 | C:\Users\BHASKAR BAHUKHANDI\OneDrive\Desktop\Ultimate project\AethelgardPrototype | Pass | 0 | False | False | False | Corrected command mode boots project cleanly. |
| I | real project, elevated filesystem, explicit log, res:// quit marker script | C:\Users\BHASKAR BAHUKHANDI\OneDrive\Desktop\Ultimate project\AethelgardPrototype | Pass | 0 | False | True | True | Validation harness can start when run with corrected command mode. |


Key result: the normal sandboxed project-context commands crashed before the script marker, but the same project booted and the marker script ran when launched with elevated filesystem access plus an explicit diagnostics log file.

Evidence files:

* docs/gameplay_audit/phase_10n_a2_opening_hook/a2_3_project_boot_autoload_repair/diagnostics/command_form_results.json
* docs/gameplay_audit/phase_10n_a2_opening_hook/a2_3_project_boot_autoload_repair/diagnostics/real_project_quit_after_1.log
* docs/gameplay_audit/phase_10n_a2_opening_hook/a2_3_project_boot_autoload_repair/diagnostics/project_probe_quit_marker.log
* docs/gameplay_audit/phase_10n_a2_opening_hook/a2_3_project_boot_autoload_repair/diagnostics/probe_quit_marker.json

## 4. Static project.godot audit

* Main scene: res://scenes/splash_screen.tscn
* Autoload count: 30
* Editor plugins/addons: no addons folder found; no active addon/plugin startup path identified in project.godot.
* Relevant display/render settings: viewport 1280x720; default canvas texture filter is nearest; headless mode still crashed before script marker in the sandboxed command environment.
* Boot-loaded scripts: all [autoload] entries listed below exist.
* .godot cache: present and recently touched, but corrected real-project boot succeeded, so cache corruption is not proven.

Static audit evidence: docs/gameplay_audit/phase_10n_a2_opening_hook/a2_3_project_boot_autoload_repair/diagnostics/project_config_static_audit.json

## 5. Autoload risk table

| Autoload | Path | Exists | Boot code risk | Headless risk | Notes |
|---|---|---:|---|---|---|
| GameManager | res://scripts/game_manager.gd | True | High | High | uses OS/DisplayServer/window APIs; uses FileAccess/DirAccess; loads/preloads resources at script level or runtime; has boot lifecycle code |
| DialogueManager | res://scripts/dialogue_manager.gd | True | High | High | uses viewport/render APIs; has boot lifecycle code |
| AssetManager | res://scripts/asset_manager.gd | True | High | High | uses OS/DisplayServer/window APIs; uses FileAccess/DirAccess; loads/preloads resources at script level or runtime; has boot lifecycle code |
| Inventory | res://scripts/inventory_system.gd | True | Medium | High | uses OS/DisplayServer/window APIs; has boot lifecycle code |
| CraftingSystem | res://scripts/crafting_system.gd | True | Low | Low | uses OS/DisplayServer/window APIs; has boot lifecycle code |
| CombatFX | res://scripts/combat_effects.gd | True | High | High | uses OS/DisplayServer/window APIs; uses viewport/render APIs; has boot lifecycle code |
| GlitchOverlay | res://scripts/glitch_overlay.gd | True | Medium | Low | loads/preloads resources at script level or runtime; has boot lifecycle code |
| VFXLibrary | res://scripts/effects/vfx_library.gd | True | Medium | Medium | no obvious boot-risk patterns found by text scan |
| PauseScreen | res://scripts/ui/pause_screen.gd | True | Medium | High | uses OS/DisplayServer/window APIs; uses viewport/render APIs; has boot lifecycle code |
| StatusWindow | res://scripts/ui/status_window.gd | True | Low | High | uses OS/DisplayServer/window APIs; uses viewport/render APIs; has boot lifecycle code |
| InteractionPrompt | res://scripts/ui/interaction_prompt.gd | True | Low | Low | has boot lifecycle code |
| MusicManager | res://scripts/music_manager.gd | True | Medium | High | loads/preloads resources at script level or runtime; has boot lifecycle code |
| SceneTransitions | res://scripts/effects/scene_transition_manager.gd | True | High | High | uses viewport/render APIs; has boot lifecycle code |
| ShopSystem | res://scripts/shop_system.gd | True | Medium | High | uses OS/DisplayServer/window APIs; uses viewport/render APIs; has boot lifecycle code |
| BackgroundManager | res://scripts/background_manager.gd | True | Medium | High | uses OS/DisplayServer/window APIs; uses FileAccess/DirAccess; loads/preloads resources at script level or runtime; has boot lifecycle code |
| ObjectPool | res://scripts/object_pool.gd | True | Low | Medium | has boot lifecycle code |
| LevelUpUI | res://scripts/ui/level_up_ui.gd | True | Low | Medium | uses OS/DisplayServer/window APIs; uses viewport/render APIs; has boot lifecycle code |
| DropManager | res://scripts/drop_manager.gd | True | Medium | Medium | has boot lifecycle code |
| SFXManager | res://scripts/sfx_manager.gd | True | Low | High | has boot lifecycle code |
| GameJuice | res://scripts/effects/game_juice.gd | True | High | High | uses viewport/render APIs; has boot lifecycle code |
| Achievements | res://scripts/ui/achievements.gd | True | Low | High | uses OS/DisplayServer/window APIs; uses viewport/render APIs; uses FileAccess/DirAccess; has boot lifecycle code |
| ChoiceConsequences | res://scripts/choice_consequences.gd | True | Medium | Medium | uses OS/DisplayServer/window APIs; uses viewport/render APIs; has boot lifecycle code |
| SideQuestManager | res://scripts/side_quest_manager.gd | True | Low | Medium | uses viewport/render APIs; has boot lifecycle code |
| UIStack | res://scripts/ui/ui_stack.gd | True | Low | Low | has boot lifecycle code |
| RandomEncounterSystem | res://scripts/combat/random_encounter_system.gd | True | High | High | uses OS/DisplayServer/window APIs; has boot lifecycle code |
| LoreJournal | res://scripts/ui/lore_journal.gd | True | Low | Medium | uses OS/DisplayServer/window APIs; uses viewport/render APIs; has boot lifecycle code |
| WorldMapUI | res://scripts/ui/world_map_ui.gd | True | Medium | Low | no obvious boot-risk patterns found by text scan |
| ProgressionBreadcrumb | res://scripts/ui/progression_breadcrumb.gd | True | Low | Medium | has boot lifecycle code |
| CreditsScreen | res://scripts/ui/credits_screen.gd | True | High | Medium | uses viewport/render APIs; has boot lifecycle code |
| CompletionTracker | res://scripts/ui/completion_tracker.gd | True | Medium | Low | uses viewport/render APIs; has boot lifecycle code |


## 6. Static script-risk findings

* No concrete GDScript parse error was found by static text inspection.
* All 30 autoload script paths referenced by project.godot exist.
* Several autoloads perform normal boot-time UI, resource, audio, viewport, or file/config work. These are risk factors for headless validation, but not proof of the signal 11.
* scripts/asset_manager.gd::_ready() runs _scan_availability() and uses ResourceLoader.exists() against asset paths.
* scripts/game_manager.gd::_ready() loads accessibility/difficulty settings, sets up cursor/gamepad bindings, and builds the autosave indicator.
* scripts/dialogue_manager.gd::_ready() builds UI and stores the current scene.
* scripts/effects/scene_transition_manager.gd::_ready() builds transition overlays.
* scripts/music_manager.gd, scripts/sfx_manager.gd, scripts/ui/status_window.gd, scripts/ui/achievements.gd, and several UI managers use audio, viewport, or file/config APIs.
* Corrected real-project boot initialized GameManager, AssetManager, Inventory, PauseScreen, StatusWindow, BackgroundManager, and Achievements without signal 11. That weakens the autoload-failure hypothesis.

## 7. Sandbox findings

* Location: C:\tmp\aethelgard_boot_isolation
* What was copied/created: a reduced no-autoload diagnostic project and an autoload/scripts-only diagnostic project. The real project was not modified.
* Initial sandbox setup without elevated filesystem access failed to create the sandbox folder; it was retried with elevated filesystem access.
* Reduced no-autoload sandbox project, run in the normal sandboxed command environment, crashed with signal 11 after printing: ERROR: Could not create directory: 'user://logs'.
* That reduced project had no A2 opening hook, no real autoloads, and no main scene dependency. This is the strongest evidence that the crash is not caused by the opening hook scene or its validation script.
* Elevated real-project boot with explicit diagnostics log succeeded.
* Smallest config/autoload that reproduced or avoided crash: no specific autoload reproduced the crash. A reduced no-autoload sandbox project reproduced it under the restricted command environment, while the real project avoided it under corrected launch conditions.

Sandbox evidence: docs/gameplay_audit/phase_10n_a2_opening_hook/a2_3_project_boot_autoload_repair/diagnostics/sandbox_findings.json

## 8. What is actually going wrong

Evidence points to the Godot launch environment, specifically filesystem/log-path access, not to A2 gameplay code.

The decisive sequence is:

1. --version works.
2. A no-project absolute script prints both markers.
3. Sandboxed project-context launches crash before the first marker.
4. A reduced no-autoload sandbox project also crashes and reports it cannot create user://logs.
5. The real project boots cleanly when run with elevated filesystem access and an explicit diagnostics log file.
6. The same minimal quit-marker script prints both markers under that corrected launch mode.

No evidence reached scenes/chapter1/opening_crash_site_hook.tscn, scripts/chapter1/ch1_opening_crash_site_hook.gd, player movement, SignalFragment, GlitchPulse, or OakhavenPath. Those remain unvalidated, not broken.

## 9. Manual validation instructions

CLI project startup is no longer blocked if launched with the corrected command mode. If headed/manual validation is still needed, use these steps and do not treat them as already performed:

1. Close all Godot instances.
2. Reopen Godot normally.
3. Open the project.
4. Check the Output panel for errors before running.
5. Open scenes/chapter1/opening_crash_site_hook.tscn.
6. Press Run Current Scene.
7. Confirm player visible.
8. Confirm WASD movement.
9. Confirm objective visible.
10. Walk to SignalFragment and press interact.
11. Confirm the prompt and flag behavior.
12. Walk into GlitchPulse.
13. Walk toward OakhavenPath.
14. Copy exact errors/screenshots back.

## 10. Files created/modified

A2.3-created docs/tools/logs:

* docs/gameplay_audit/phase_10n_a2_opening_hook/a2_3_project_boot_autoload_repair/tools/probe_quit_marker.gd
* docs/gameplay_audit/phase_10n_a2_opening_hook/a2_3_project_boot_autoload_repair/diagnostics/process_state_before.json
* docs/gameplay_audit/phase_10n_a2_opening_hook/a2_3_project_boot_autoload_repair/diagnostics/project_config_static_audit.json
* docs/gameplay_audit/phase_10n_a2_opening_hook/a2_3_project_boot_autoload_repair/diagnostics/command_form_results.json
* docs/gameplay_audit/phase_10n_a2_opening_hook/a2_3_project_boot_autoload_repair/diagnostics/sandbox_findings.json
* docs/gameplay_audit/phase_10n_a2_opening_hook/a2_3_project_boot_autoload_repair/diagnostics/real_project_quit_after_1.log
* docs/gameplay_audit/phase_10n_a2_opening_hook/a2_3_project_boot_autoload_repair/diagnostics/project_probe_quit_marker.log
* docs/gameplay_audit/phase_10n_a2_opening_hook/a2_3_project_boot_autoload_repair/diagnostics/probe_quit_marker.json
* docs/gameplay_audit/phase_10n_a2_opening_hook/a2_3_project_boot_autoload_repair/opening_hook_project_boot_autoload_report.md

A2/A2.1/A2.2 pre-existing files were not modified by this phase.

Pre-existing dirty files include, at minimum:

* scripts/asset_manager.gd
* scripts/game_manager.gd
* scripts/main_menu.gd
* scripts/regions/late_revisit_hub.gd
* scripts/ui/progression_breadcrumb.gd
* scenes/chapter1/opening_crash_site_hook.tscn
* scripts/chapter1/ch1_opening_crash_site_hook.gd
* many pre-existing art/import/report artifacts under assets/art_sources, assets/production_art, and docs/art_pipeline.

## 11. Protected path status

A2.3 did not edit:

* assets/art_sources
* assets/production_art
* assets/generated_v2
* assets/generated_v3
* scenes
* scripts
* project.godot

Important nuance: several protected paths are already dirty from previous phases, especially assets/art_sources, assets/production_art, scenes/chapter1/opening_crash_site_hook.tscn, and multiple scripts/*.gd. Those are pre-existing changes, not A2.3 edits.

Validation:

* git diff --check: exit code 0. Git emitted CRLF normalization warnings for docs/art_pipeline/art_replacement_manifest.md and scripts/asset_manager.gd, but no whitespace-error failure.
* git status --short: confirms A2.3 added only the A2.3 docs/diagnostics folder; protected runtime/art paths remain dirty only from pre-existing work.

## 12. Next recommended phase

Ready for A2 headed/manual play check

FINAL DECISION:

Command mode issue identified
