# PHASE 10N-A2.2 OPENING HOOK CRASH ISOLATION REPORT

## 1. Summary

* Crash isolated: Yes
* Smallest failing probe: `probe_00_quit_only.gd` when run with `--path "C:\Users\BHASKAR BAHUKHANDI\OneDrive\Desktop\Ultimate project\AethelgardPrototype"`
* Crash category: `Project boot/autoload issue`
* Is opening hook scene proven broken: Unproven
* Is validation script proven broken: No
* Is project boot proven stable: No
* Final verdict: The crash happens before a quit-only script prints its first marker or writes JSON when launched in project context. The same quit-only script runs outside project context. This does not implicate the A2 opening hook scene yet.

## 2. Existing process check

* Existing Godot processes: one process was already present before A2.2 probes: PID `10284`, process `Godot_v4.6.3-stable_win64`, empty window title, path `C:\Godot\Godot_v4.6.3-stable_win64.exe`, start time `2026-06-19 23:13:31`.
* Editor likely open: Unproven. Empty window title suggests it may be a stale/headless process, but command line could not be safely read.
* Validation conflict risk: Present. I did not kill the process because it was not safe to prove whether it was user-owned editor state or a stale validation run.

## 3. Probe matrix

| Probe | Command | Expected | Result | Exit code | JSON produced | Last marker | Classification |
|---|---|---|---|---:|---|---|---|
| Version | `C:\Godot\Godot_v4.6.3-stable_win64_console.exe --version` | Print Godot version | Printed `4.6.3.stable.official.7d41c59c4` | 0 | No | N/A | Executable can answer version. |
| Probe 00, project context | `C:\Godot\Godot_v4.6.3-stable_win64_console.exe --path "C:\Users\BHASKAR BAHUKHANDI\OneDrive\Desktop\Ultimate project\AethelgardPrototype" --headless --script "res://docs/gameplay_audit/phase_10n_a2_opening_hook/a2_2_crash_isolation/tools/probe_00_quit_only.gd"` | Print marker, write JSON, quit | Timed out, then crash handler reported signal 11 | 124 | No | None | Smallest failing project-context command. Crash occurs before script body marker. |
| Probe 00, no-project control | `C:\Godot\Godot_v4.6.3-stable_win64_console.exe --headless --script "C:\Users\BHASKAR BAHUKHANDI\OneDrive\Desktop\Ultimate project\AethelgardPrototype\docs\gameplay_audit\phase_10n_a2_opening_hook\a2_2_crash_isolation\tools\probe_00_quit_only.gd"` from `C:\tmp` | Print marker and quit | Printed both markers and exited | 0 | No | `A2_2_PROBE_00_BEFORE_QUIT` | Plain `--script` works outside project context; crash is tied to project path/autoload context or existing process conflict. |
| Probe 01 | Not run | Autoload availability | Skipped because Probe 00 failed in project context | N/A | No | N/A | Per prompt strategy, deeper probes are unsafe/noisy until project-context script launch is stable. |
| Probe 02 | Not run | PackedScene load only | Skipped | N/A | No | N/A | Opening scene not reached. |
| Probe 03 | Not run | Instantiate opening scene | Skipped | N/A | No | N/A | Opening scene not reached. |
| Probe 04 | Not run | Player movement | Skipped | N/A | No | N/A | Opening scene not reached. |
| Probe 05 | Not run | Interactable/objective | Skipped | N/A | No | N/A | Opening scene not reached. |
| Probe 06 | Not run | Trigger flow | Skipped | N/A | No | N/A | Opening scene not reached. |

## 4. Crash details

Exact failing command:

```powershell
& "C:\Godot\Godot_v4.6.3-stable_win64_console.exe" --path "C:\Users\BHASKAR BAHUKHANDI\OneDrive\Desktop\Ultimate project\AethelgardPrototype" --headless --script "res://docs/gameplay_audit/phase_10n_a2_opening_hook/a2_2_crash_isolation/tools/probe_00_quit_only.gd"
```

Stdout/stderr tail:

```text
command timed out after 60821 milliseconds

================================================================
CrashHandlerException: Program crashed with signal 11
Engine version: Godot Engine v4.6.3.stable.official (7d41c59c457bd5a245092b4e7eb2d833e3b3f8c3)
Dumping the backtrace.
[1] error(-1): no debug info in PE/COFF executable
...
[15] error(-1): no debug info in PE/COFF executable
-- END OF C++ BACKTRACE --
================================================================
```

Crash timing:

* The crash happened before `A2_2_PROBE_00_START`.
* No `probe_00_quit_only.json` was produced.
* The same script printed both markers and exited when launched without project context from `C:\tmp`.

Repeated or one-off:

* Not repeated with the same project-context command because the prompt says to stop repeating a command once the same crash is observed.
* Prior A2/A2.1 project-context Godot commands also produced signal 11, which is consistent with this result.

## 5. Opening hook status

Only based on successful probes:

| Item | Status | Evidence |
|---|---|---|
| scene file exists | Unproven in runtime; statically yes from A2 report | Probe 02 was not reached. |
| scene loadable as PackedScene | Unproven | Probe 02 skipped. |
| scene instantiates | Unproven | Probe 03 skipped. |
| player exists | Unproven | Probe 03/04 skipped. |
| movement works | Unproven | Probe 04 skipped. |
| objective exists | Unproven | Probe 05 skipped. |
| SignalFragment exists | Unproven | Probe 05 skipped. |
| GlitchPulse exists | Unproven | Probe 05/06 skipped. |
| OakhavenPath exists | Unproven | Probe 05/06 skipped. |
| legacy route preserved | Unproven in runtime; statically yes from A2 report | Main menu runtime not reached. |

## 6. What is actually going wrong

Evidence supports this narrow conclusion:

* `--version` works, so the executable is not totally unusable.
* A quit-only script works when launched outside the project context.
* The same quit-only script crashes before its first marker when launched with the project path.
* Therefore the A2 opening hook scene, the A2 validation script body, player movement, SignalFragment, GlitchPulse, and OakhavenPath were not reached.

Most likely root cause by evidence: project-context startup, autoload initialization, project import/editor state, or a conflict with the existing Godot process. The exact autoload/resource is not isolated because the crash occurs before Probe 00 script code executes.

## 7. Manual editor validation instructions

Only perform this manually; I did not perform these steps.

1. Close any stale headless Godot process if you confirm it is not your editor.
2. Open Godot normally.
3. Open `scenes/chapter1/opening_crash_site_hook.tscn`.
4. Check whether the scene opens without editor errors.
5. Press `Run Current Scene`.
6. Confirm whether the player appears.
7. Confirm whether WASD moves the player.
8. Confirm whether objective text appears.
9. Walk to `SignalFragment` and press interact.
10. Confirm whether `GlitchPulse` appears after interaction.
11. Walk into `GlitchPulse`.
12. Walk toward `OakhavenPath`.
13. Screenshot or copy exact editor/runtime errors.

## 8. Files created/modified

A2.2-created docs/tools/logs:

* `docs/gameplay_audit/phase_10n_a2_opening_hook/a2_2_crash_isolation/tools/probe_00_quit_only.gd`
* `docs/gameplay_audit/phase_10n_a2_opening_hook/a2_2_crash_isolation/tools/probe_01_project_boot_only.gd`
* `docs/gameplay_audit/phase_10n_a2_opening_hook/a2_2_crash_isolation/tools/probe_02_load_opening_scene_only.gd`
* `docs/gameplay_audit/phase_10n_a2_opening_hook/a2_2_crash_isolation/tools/probe_03_instantiate_opening_scene.gd`
* `docs/gameplay_audit/phase_10n_a2_opening_hook/a2_2_crash_isolation/tools/probe_04_player_movement_only.gd`
* `docs/gameplay_audit/phase_10n_a2_opening_hook/a2_2_crash_isolation/tools/probe_05_interactable_only.gd`
* `docs/gameplay_audit/phase_10n_a2_opening_hook/a2_2_crash_isolation/tools/probe_06_trigger_flow_safely.gd`
* `docs/gameplay_audit/phase_10n_a2_opening_hook/a2_2_crash_isolation/diagnostics/probe_command_summary.json`
* `docs/gameplay_audit/phase_10n_a2_opening_hook/a2_2_crash_isolation/opening_hook_crash_isolation_report.md`

Pre-existing A2 changes:

* `scripts/main_menu.gd`
* `scripts/game_manager.gd`
* `scripts/ui/progression_breadcrumb.gd`
* `scripts/chapter1/ch1_opening_crash_site_hook.gd`
* `scenes/chapter1/opening_crash_site_hook.tscn`
* `docs/gameplay_audit/phase_10n_a2_opening_hook/tools/opening_hook_runtime_validation.gd`
* `docs/gameplay_audit/phase_10n_a2_opening_hook/diagnostics/opening_hook_static_validation.json`
* `docs/gameplay_audit/phase_10n_a2_opening_hook/opening_hook_implementation_report.md`

Pre-existing dirty files:

* `scripts/asset_manager.gd`
* `scripts/regions/late_revisit_hub.gd`
* many untracked prior art/source/import folders under `assets/art_sources` and `assets/production_art`

## 9. Protected path status

Confirmed A2.2 did not edit:

* `assets/art_sources`
* `assets/production_art`
* `assets/generated_v2`
* `assets/generated_v3`
* `scenes`
* `scripts`

`git diff --check` result: pass, with pre-existing CRLF normalization warnings for `docs/art_pipeline/art_replacement_manifest.md` and `scripts/asset_manager.gd`.

## 10. Next recommended phase

`10N-A2.3 validation harness repair`

Goal: isolate project-context startup outside the opening hook by investigating autoload initialization and the existing Godot process/editor conflict, then rerun probes 01-06 only after Probe 00 succeeds in project context.

FINAL DECISION:

Crash isolated — project boot/autoload issue

