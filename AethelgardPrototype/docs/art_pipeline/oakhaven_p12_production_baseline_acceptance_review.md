# PHASE 10M-P12 OAKHAVEN PRODUCTION BASELINE ACCEPTANCE REPORT

## 1. Summary

* Production afternoon accepted: Yes, as the Oakhaven afternoon baseline.
* Actual Oakhaven scene tested: Yes, using the real `scenes/regions/oakhaven_region.tscn` scene.
* Screenshots captured: Yes, 6 actual-scene screenshots plus a contact sheet.
* Visual repairs applied: None.
* Fallback preserved: Yes, runtime generated fallback override still works.
* Overall verdict: Production afternoon is cleaner and more coherent than the generated fallback in the real scene, but Oakhaven is not final-polish complete.

## 2. Integration Verification

| Check | Result | Notes |
| --- | --- | --- |
| Production afternoon default | Pass | `AssetManager.get_oakhaven_tileset_slot()` resolves to `res://assets/production_art/tilesets/oakhaven/oakhaven_afternoon_tileset.png`. |
| Morning/night staged | Pass | Morning and night atlases load through AssetManager, but the real scene uses default afternoon only. No day/night gameplay was enabled. |
| Fallback valid | Pass | Runtime fallback override resolves to `res://assets/generated_v2/tilesets/oakhaven_v2_prototype_tileset.png`. |
| Invalid state handling | Pass | Invalid state `dusk` normalizes to afternoon production. |
| Actual scene visual layer | Pass | `V2OakhavenGroundTiles` exists and reports production afternoon metadata in production captures. |

## 3. Screenshot Evidence

| View | Fallback/Production | Screenshot Path | Notes |
| --- | --- | --- | --- |
| Village center | Fallback | `assets/art_sources/comfyui_tests/oakhaven_p12_acceptance/screenshots/oakhaven_p12_fallback_center.png` | Baseline comparison point. Fallback shows harsher repeated ground pattern. |
| Village center | Production | `assets/art_sources/comfyui_tests/oakhaven_p12_acceptance/screenshots/oakhaven_p12_production_center.png` | Cleaner and calmer ground read; NPCs and labels remain legible. |
| Player spawn | Production | `assets/art_sources/comfyui_tests/oakhaven_p12_acceptance/screenshots/oakhaven_p12_production_spawn.png` | Player contrast is safe against production ground. |
| Farming/outskirts | Production | `assets/art_sources/comfyui_tests/oakhaven_p12_acceptance/screenshots/oakhaven_p12_production_farming_area.png` | Farming marker, prompt, and herb patch remain readable. |
| South exit | Production | `assets/art_sources/comfyui_tests/oakhaven_p12_acceptance/screenshots/oakhaven_p12_production_exit_area.png` | Exit marker and label are readable; open grass remains tile-visible but acceptable. |
| NPC cluster | Production | `assets/art_sources/comfyui_tests/oakhaven_p12_acceptance/screenshots/oakhaven_p12_production_npc_area.png` | NPC labels and village props remain readable. |

Contact sheet:
`assets/art_sources/comfyui_tests/oakhaven_p12_acceptance/contact_sheets/oakhaven_p12_fallback_vs_production_contact_sheet.png`

## 4. Visual QA Findings

| Area | Result | Issue Found | Action |
| --- | --- | --- | --- |
| Grass | Pass | Minor square tiling in open areas. | Accept for baseline; revisit in broader polish. |
| Path | Pass | No blocking issue. | No repair. |
| Transitions | Pass | Existing path/grass decals carry most transition detail. | No repair. |
| Buildings | Pass | Roof/building props remain readable. | No repair. |
| Fence/hedge | Pass | Hedges remain readable against production ground. | No repair. |
| Props/decals | Pass | V3 props/decals remain compatible. | No repair. |
| Player visibility | Pass | Player sprite remains bright and readable. | No repair. |
| NPC visibility | Pass | Five NPCs detected and readable in captures. | No repair. |
| Labels/prompts | Pass | Name labels, farming prompt, and exit label remain readable. | No repair. |
| Farming marker | Pass | Herb patch and prompt visible in farming capture. | No repair. |
| Exits/gates | Pass | South/east exit nodes detected; south exit capture readable. | No repair. |
| Collision expectation | Pass | No visual obstruction suggests changed collision. Collision was untouched. | No repair. |
| Overall scene feel | Pass | Production afternoon improves coherence while preserving existing scene layout. | Accept baseline. |

## 5. Repairs Applied

| File | Change | Reason | Risk |
| --- | --- | --- | --- |
| None | No visual or gameplay repair applied. | Screenshots did not justify changing z-index, opacity, layout, collision, or loader behavior. | None. |

## 6. Fallback / Rollback Validation

| Scenario | Expected | Actual | Result |
| --- | --- | --- | --- |
| Production default | Default Oakhaven resolves to afternoon production. | Passed in AssetManager P12 check and real scene metadata. | Pass |
| Generated fallback override | Runtime override resolves to generated fallback. | Passed; fallback screenshot uses generated path. | Pass |
| Invalid time state | Invalid state resolves to afternoon production. | `dusk` normalized to afternoon. | Pass |
| Missing production behavior | Missing variant returns null and safe production default remains available. | Controlled missing-path probe passed. | Pass |
| Morning/night staged but not enabled | Morning/night loadable but not default gameplay state. | Loadable through AssetManager; actual scene metadata remains afternoon. | Pass |

## 7. Player / NPC / Farming Smoke

| Check | Result | Notes |
| --- | --- | --- |
| Player spawn visible | Pass | Player found in every capture and readable at spawn/center. |
| NPCs visible | Pass | Five NPC nodes detected; labels readable in center/NPC captures. |
| Farming marker visible | Pass | `OakhavenOutskirtsFarming` detected and readable in farming capture. |
| Return/exit marker visible | Pass | `OverworldExit` and `OverworldExitEast` detected; south exit screenshot captured. |
| World map/free-travel surface | Pass | `scenes/overworld/overworld.tscn` loaded headlessly without immediate script errors. |
| Immediate script errors | Pass | Boot/load/capture commands exited 0. Existing missing production slot warnings fall back safely. |
| Softlock on scene load | Pass | Oakhaven scene loaded and updated during capture. |

## 8. Save/Load Smoke

| Check | Result | Notes |
| --- | --- | --- |
| Save/load mutation | Skipped | P12 made no save schema or persistent gameplay-state change. Running an actual save/reload would risk touching user save data for no new coverage. |
| Visual persistence expectation | Pass by design | Oakhaven visual selection is resolved from AssetManager at scene load; it is not serialized into save data. |

## 9. Quality Scores

| Category | Fallback Score | Production Afternoon Score | Verdict |
| --- | ---: | ---: | --- |
| Grass | 6.2 | 7.4 | Production is calmer and less noisy. |
| Path | 7.1 | 7.4 | Path decals remain readable and slightly better integrated. |
| Buildings | 7.2 | 7.5 | Buildings remain readable against the new baseline. |
| Props | 7.0 | 7.3 | Props and decals remain legible. |
| Readability | 7.0 | 7.7 | Player, NPCs, labels, farming, and exits are safe. |
| Oakhaven identity | 6.5 | 7.6 | Production reads more like a coherent meadow village. |
| Overall | 6.8 | 7.6 | Better than fallback, acceptable as baseline. |

## 10. Project Safety Validation

| Test | Result | Notes |
| --- | --- | --- |
| Discovered Godot path | Pass | `C:\Godot\Godot_v4.6.3-stable_win64_console.exe`. |
| Godot version | Pass | `4.6.3.stable.official.7d41c59c4`. |
| Project boot | Pass | `--headless --quit-after 2` exited 0. |
| Main menu | Pass | `res://scenes/main_menu.tscn` exited 0. |
| Oakhaven scene | Pass | `res://scenes/regions/oakhaven_region.tscn` exited 0. |
| World map/free-travel smoke | Pass | `res://scenes/overworld/overworld.tscn` exited 0. |
| AssetManager production load | Pass | P12 AssetManager check confirms afternoon production default. |
| AssetManager fallback | Pass | Runtime generated fallback override passed. |
| Actual-scene capture | Pass | All required screenshots and contact sheet written. Windowed capture reported renderer cleanup warnings at exit, but process exited 0. |
| No unintended production_art overwrite | Pass | P12 did not write to `assets/production_art/`; generated outputs are under P12 art-source/docs folders. |
| git diff --check | Pass | Exit 0 with existing CRLF normalization warnings only. |

## 11. Honest Recommendation

* Should afternoon be accepted as Oakhaven baseline? Yes.
* Should morning/night remain staged? Yes. They are loadable but should not be gameplay-enabled yet.
* Is the actual scene better than fallback? Yes, production afternoon is calmer, more coherent, and less visually noisy in the real scene.
* Is Oakhaven visually done? No. It is acceptable as a baseline, but open grass tiling and remaining generated V3 props/decals still need future polish.
* What still needs improvement? Broader environment prop/decal replacement, less visible large-field tiling, and later optional time-of-day QA if morning/night are ever enabled.
* Should we now move to Ironhold production-art pipeline? Yes.

## 12. Decision

Accept Oakhaven afternoon production-art baseline and move to Ironhold
