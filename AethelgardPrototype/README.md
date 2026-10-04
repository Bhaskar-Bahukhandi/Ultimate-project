# Aethelgard: The Glitch Sovereign

A 2D action-RPG in Godot 4.6. You explore a top-down open world, and combat switches to
side-scrolling, Soulslike action. A programmer wakes up inside a broken game world with
"Root Access": the power to edit enemies' properties at runtime, at the cost of corruption.

**Status:** pre-production prototype. The art is temporary and will be replaced by Pixel Art
Engine sprites. See [`ROADMAP_10_YEAR.md`](ROADMAP_10_YEAR.md) for the plan and
[`CODE_REVIEW_2026-10-04.md`](CODE_REVIEW_2026-10-04.md) for the current state of the code.

## Running

1. Install **Godot 4.6.x** (standard build, not .NET).
2. In Godot, choose **Import**, select `AethelgardPrototype/project.godot`, then **Import & Edit**.
3. Press **F5**. The game starts at the splash screen → main menu → **New Game**.

New Game plays the crash-site opening, then Elara's meeting → the path to Oakhaven → Oakhaven
village → the Oakhaven region and the overworld. The long Flight 707 cinematic prologue plays on
**New Game+**.

## Controls (keyboard)

| Action | Key | Action | Key |
|---|---|---|---|
| Move | WASD / arrow keys | Interact / talk | F |
| Jump | Space | Root Access | E |
| Attack | J | Perfect Delete | X |
| Defend / block | K | Spell | Q |
| Sprint | Shift | Heal | C |
| Data Vision | Tab | Flee combat | R |
| Pause | Esc | World map | M |
| Status window | I | Confirm (menus) | Enter |

Dialogue: Space or Enter advances; Esc once completes the line and Esc twice skips the
conversation. Skipping never makes a choice for you. Controls can be rebound in the main menu.
Gamepad support is not finished yet.

## Tests

Headless regression tests live in `tests/`. The runners point `user://` at a temporary folder, so
your real saves are never touched.

```bash
# Windows (from AethelgardPrototype/)
powershell -File tests/run_phase0_tests.ps1                                    # Phase 0 suite (~10 min)
powershell -File tests/run_phase0_tests.ps1 -Script res://tests/load_all_test.gd

# Linux / macOS
GODOT=/path/to/godot tests/run_tests.sh
GODOT=/path/to/godot tests/run_tests.sh res://tests/load_all_test.gd
```

CI (`.github/workflows/ci.yml`, at the repository root) runs the same checks on every push and
pull request: boot without script errors, load every script and scene, the dialogue and
ContextStack tests, the Phase 0 suite, and `git diff --check`.

## Layout

| Path | Contents |
|---|---|
| `scripts/` | All game code. The global systems are autoloads (see `project.godot`). `scripts/core/context_stack.gd` is the only code that pauses the game or changes game speed: open menus with `ContextStack.push/pop`, slow time with `request_time_scale/release_time_scale`. |
| `scenes/` | Scenes by chapter, plus `regions/`, `combat/`, `overworld/`. |
| `assets/` | Runtime art. `assets/art_sources/` is review-only (not imported, not exported). |
| `shaders/` | Glitch, CRT and other screen effects. |
| `dialogue/` | All dialogue as `.dlg` text files (format: `story/DIALOGUE_FORMAT.md`). `dialogue/_extracted/` is the old in-code dialogue, kept as rewrite material. |
| `story/` | Story bible, voice guide, act outlines, dialogue format. |
| `tests/` | Headless tests and runners (`context_stack_test.gd`, `dialogue_test.gd`, `phase0_blockers_test.gd`, `load_all_test.gd`). |
| `tools/` | Dev tools, e.g. `extract_dialogue.gd`. Not exported. |
| `docs/` | Art-pipeline and gameplay-audit history (not exported). |

Agent and contributor rules are in [`AGENTS.md`](AGENTS.md).
