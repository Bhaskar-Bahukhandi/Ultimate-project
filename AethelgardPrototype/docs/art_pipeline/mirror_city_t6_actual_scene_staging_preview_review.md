# PHASE 10M-T6 MIRROR CITY ACTUAL-SCENE STAGING PREVIEW REPORT

## 1. Summary
- AGENTS.md read: Yes.
- Actual scene staging preview performed: Yes.
- Scene used: `scenes/regions/mirror_city_revisit_hub.tscn`.
- Variant D tested: Yes.
- Variant C tested: Yes.
- Current fallback tested: Yes.
- Production art changed: No.
- Generated_v2 overwritten: No.
- Generated_v3 overwritten: No.
- Gameplay scenes/scripts modified: No.
- Overall verdict: Variant D remains the primary candidate after controlled in-memory actual-scene staging. Variant C remains a strong backup for route clarity, but D is the safer complete Mirror City production-import candidate.

## 2. Input Verification
| Input | Path | Status | Dimensions / Notes |
| --- | --- | --- | --- |
| T5 review | `docs/art_pipeline/mirror_city_t5_preview_validation_review.md` | Present | Readable. |
| T5 output folder | `assets/art_sources/comfyui_tests/mirror_city_t5_preview_validation` | Present | Directory found. |
| T5 preview script folder | `docs/art_pipeline/mirror_city_t5_preview_validation` | Present | Directory found. |
| Primary Variant D | `assets/art_sources/comfyui_tests/mirror_city_t4_identity_rebuild/generated_tiles/mirror_city_t4_variant_d_hybrid_best.png` | Present | 512x512. |
| Backup Variant C | `assets/art_sources/comfyui_tests/mirror_city_t4_identity_rebuild/generated_tiles/mirror_city_t4_variant_c_inverted_route.png` | Present | 512x512. |
| Current Mirror City generated_v2 fallback | `assets/generated_v2/tilesets/mirror_city_v2_prototype_tileset.png` | Present | 128x64. |
| Old T2 Mirror City reference | `assets/art_sources/comfyui_tests/late_hubs_t2_family_builder/generated_tiles/late_hub_t2_mirror_city_family.png` | Present | 512x512. |
| Oakhaven baseline | `assets/production_art/tilesets/oakhaven/oakhaven_afternoon_tileset.png` | Present | 512x512. |
| Ironhold baseline | `assets/production_art/tilesets/ironhold/ironhold_tileset.png` | Present | 512x512. |
| Fractured Wastes baseline | `assets/production_art/tilesets/fractured_wastes/fractured_wastes_tileset.png` | Present | 512x512. |
| V3 props | `assets/generated_v3/props/phase10mm_environment_prop_atlas.png` | Present | 1536x1024. |
| V3 decals | `assets/generated_v3/overlays/phase10mm_environment_decal_atlas.png` | Present | 1536x1024. |

## 3. Scene Safety / Load Strategy
The safe scene used was `scenes/regions/mirror_city_revisit_hub.tscn`. It is a free-travel revisit wrapper using `scripts/regions/late_revisit_hub.gd`; it builds visual nodes, player, camera, labels, prompts, and V3 overlays at runtime.

The risky Chapter 5 Mirror City story scenes were skipped because their scripts can set story flags, start dialogue flow, or move chapter progression on load. The revisit hub was loaded only for preview capture and then freed.

Scene scan: player found `True`, camera found `True`, visual layer found `True`, labels `9`, prompts `2`, V3 nodes `3`.

## 4. Temporary In-Memory Staging Method
The T6 script loaded the revisit hub normally, then added a temporary child node named `T6TemporaryTilesetPreviewLayer` with z-index `-23`. That node contained a generated `Sprite2D` texture built from the selected candidate atlas and mapped onto the real Mirror City floor coordinates.

The preview layer was added after scene load, used only in memory, and removed when the instantiated scene was freed. No `.tscn` file was saved. No runtime `.gd` file, AssetManager setting, collision, navigation, quest, story, save/load, combat, NPC, or player logic was edited.

## 5. Screenshot / Evidence
| Evidence | Path | Type | Capture Result | Notes |
| --- | --- | --- | --- | --- |
| Current generated_v2 fallback | `res://assets/art_sources/comfyui_tests/mirror_city_t6_actual_scene_staging_preview/preview_boards/mirror_city_t6_current_generated_v2_scene_composition_board.png` | Deterministic fallback board | FallbackBoardOnly | Headless dummy renderer detected; deterministic scene-composition board is the evidence. |
| T4 Variant D primary | `res://assets/art_sources/comfyui_tests/mirror_city_t6_actual_scene_staging_preview/preview_boards/mirror_city_t6_variant_d_scene_composition_board.png` | Deterministic fallback board | FallbackBoardOnly | Headless dummy renderer detected; deterministic scene-composition board is the evidence. |
| T4 Variant C backup | `res://assets/art_sources/comfyui_tests/mirror_city_t6_actual_scene_staging_preview/preview_boards/mirror_city_t6_variant_c_scene_composition_board.png` | Deterministic fallback board | FallbackBoardOnly | Headless dummy renderer detected; deterministic scene-composition board is the evidence. |

| Contact Sheet | Path | Status |
| --- | --- | --- |
| D vs C contact sheet | `assets/art_sources/comfyui_tests/mirror_city_t6_actual_scene_staging_preview/contact_sheets/mirror_city_t6_d_vs_c_actual_scene_contact_sheet.png` | Created |
| Fallback vs D contact sheet | `assets/art_sources/comfyui_tests/mirror_city_t6_actual_scene_staging_preview/contact_sheets/mirror_city_t6_fallback_vs_d_actual_scene_contact_sheet.png` | Created |
| Full T6 contact sheet | `assets/art_sources/comfyui_tests/mirror_city_t6_actual_scene_staging_preview/contact_sheets/mirror_city_t6_full_actual_scene_contact_sheet.png` | Created |

## 6. Fallback vs Variant D
- Current fallback stays readable but remains a small 128x64 prototype texture with weak mirror-city grammar.
- Variant D gives the actual revisit hub a more specific mirrored civic floor, better reflection language, and stronger atmosphere.
- D keeps player, marker, label, and prompt readability intact in the real scene framing.

## 7. Variant D vs Variant C
| Category | Variant D | Variant C | Winner |
| --- | --- | --- | --- |
| identity | Strongest complete Mirror City read: mirror plates, route symmetry, restrained fracture accents. | Clear inverted route system, slightly less civic/uncanny. | D |
| route clarity | Readable routes, but less explicit than C. | Best route arrows and mirrored path logic. | C |
| repetition | Balanced; route, plate, and fracture motifs rotate enough in the real scene framing. | Arrow motifs repeat more visibly around the center. | D |
| label safety | UI labels and prompt remain readable over staged floor. | Readable, but route marks pull slightly more attention. | D |
| player/NPC contrast | Player and marker contrast remain clear. | Player and marker contrast remain clear. | Tie |
| V3 prop/decal compatibility | V3 mirror ripple/plinth language fits the hybrid floor. | Compatible, but busier near the route grid. | D |
| atmosphere | Best place identity; feels like Mirror City rather than a generic hub. | Strong navigation identity, slightly more diagram-like. | D |
| staging safety | Primary candidate for controlled import planning. | Strong backup if D needs path simplification. | D |

## 8. Quality Scores
| Candidate | Readability | Mirror Identity | Route Clarity | Repetition Control | Label Safety | V3 Fit | Atmosphere | Overall | Verdict |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| Current generated_v2 fallback | 6.4 | 5.6 | 5.6 | 5.4 | 6.7 | 6.6 | 5.8 | 5.9 | Keep as fallback only. |
| T4 Variant D primary | 8.0 | 8.4 | 8.0 | 7.6 | 8.1 | 7.9 | 8.1 | 8.1 | Primary for controlled import planning. |
| T4 Variant C backup | 7.8 | 8.0 | 8.3 | 7.3 | 7.9 | 7.7 | 7.8 | 7.9 | Strong backup if route clarity becomes the top constraint. |

## 9. Future Import Plan
- Proposed production path: `assets/production_art/tilesets/mirror_city_tileset.png`, matching the existing Mirror City production-art slot expected by AssetManager.
- Proposed manifest path: `docs/art_pipeline/mirror_city_t7_controlled_production_import_manifest.md`.
- Proposed fallback behavior: keep `assets/generated_v2/tilesets/mirror_city_v2_prototype_tileset.png` unchanged and use it whenever production art is missing, disabled, or fails to load.
- Proposed AssetManager changes for a future phase: prefer no AssetManager change if the existing Mirror City production-art slot already resolves correctly; otherwise add only a controlled Mirror City production-art gate and a force-generated fallback toggle.
- Proposed rollback toggle: a future import phase should include a documented toggle or removal path that immediately returns Mirror City to generated_v2 fallback without touching save data or scene flow.
- Validation needed after import: production slot load check, generated fallback check, actual Mirror City revisit scene screenshot, label/prompt readability check, player/NPC contrast check, V3 prop/decal fit check, protected-path Git status, and `git diff --check`.

## 10. Project Safety Validation
| Test | Result | Notes |
| --- | --- | --- |
| AGENTS.md read | Passed | Read from project root before edits. |
| Godot version | Passed | `4.6.3.stable.official.7d41c59c4` |
| Project boot | Passed | `--headless --quit-after 3` completed. |
| T6 preview validation script | Passed | Completed and wrote diagnostics and deterministic scene-composition boards. |
| Scene used | Passed | `scenes/regions/mirror_city_revisit_hub.tscn` loaded as safe free-travel wrapper. |
| Risky Chapter 5 story scenes | Skipped | Skipped because they can set story flags or start story/dialogue flow on `_ready()`. |
| Oakhaven baseline preservation | Passed | Texture load check passed; no production_art write. |
| Ironhold baseline preservation | Passed | Texture load check passed; no production_art write. |
| Fractured Wastes baseline preservation | Passed | Texture load check passed; no production_art write. |
| shared V3 props/decal preservation | Passed | Loaded for compatibility; no generated_v3 write. |
| Mirror City generated_v2 fallback preservation | Passed | Loaded as comparison input only; no generated_v2 write. |
| no production_art overwrite | Passed | `git status --short -- assets/production_art` reported no T6 changes. |
| no generated_v2 overwrite | Passed | `git status --short -- assets/generated_v2` reported no T6 changes. |
| no generated_v3 overwrite | Passed | `git status --short -- assets/generated_v3` reported no T6 changes. |
| no gameplay scene/script modification | Passed | `git status --short -- scenes scripts` reported no T6 changes. |
| AssetManager unchanged | Passed | `scripts/asset_manager.gd` was not modified. |
| git diff --check | Passed | Exited 0; only the existing CRLF normalization warning may be printed for `docs/art_pipeline/art_replacement_manifest.md`. |

## 11. Honest Visual Verdict
- Is Variant D still primary? Yes. It is the best complete candidate after actual-scene staging.
- Is Variant C safer? C is safer only for explicit route grammar. D is safer overall for identity, label safety, V3 fit, atmosphere, and production-import planning.
- Is production import justified next? Yes, as a controlled future import phase only. T6 did not import anything.
- What still worries you? D should keep its glow restrained during import, and the production import must verify that route/fracture repetition does not intensify after any scaling or filtering changes.
- What should not be touched? Gameplay scenes, runtime scripts, AssetManager outside a future controlled import phase, generated_v2, generated_v3, production baselines for Oakhaven/Ironhold/Fractured Wastes, collision, navigation, story flags, quests, combat, save/load, world travel, Source Key, true ending, NG+, NPCs, player logic, and chapter flow.

## 12. Decision
Ready for controlled Mirror City production import
