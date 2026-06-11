# PHASE 10M-Q2 IRONHOLD PREVIEW-ONLY GODOT VALIDATION REPORT

## 1. Summary

* Preview-only validation created: Yes.
* Variants tested: fallback, Variant A clean, Variant B textured, Variant C ember/dark.
* Best variant: Variant B textured.
* Screenshots captured: Yes, 4 preview screenshots, 1 actual-region reference screenshot, and 1 contact sheet.
* Production art changed: No.
* Actual Ironhold scenes modified: No.
* Overall verdict: Variant B is clearly better than the current fallback in the preview board and is ready for a controlled production-art import pass in a later phase.

## 2. Input Verification

| Input | Path | Status | Notes |
| --- | --- | --- | --- |
| Variant A | `assets/art_sources/comfyui_tests/ironhold_q1/generated_tiles/ironhold_q1_variant_a_clean.png` | Pass | 512x512 RGBA; safest readability. |
| Variant B | `assets/art_sources/comfyui_tests/ironhold_q1/generated_tiles/ironhold_q1_variant_b_textured.png` | Pass | 512x512 RGBA; Q1 best candidate and Q2 best preview result. |
| Variant C | `assets/art_sources/comfyui_tests/ironhold_q1/generated_tiles/ironhold_q1_variant_c_ember_dark.png` | Pass | 512x512 RGBA; mood/reference candidate. |
| Q1 layout map | `assets/art_sources/comfyui_tests/ironhold_q1/manifest/ironhold_q1_tile_layout.md` | Pass | 16x16, 32px grid documented. |
| Current fallback | `assets/generated_v2/tilesets/ironhold_v2_prototype_tileset.png` | Pass | 128x64 RGBA fallback remains available. |
| Production_art untouched | `assets/production_art/tilesets/ironhold_tileset.png` | Pass | File remains absent; Q2 did not import anything. |

## 3. Ironhold Scene / Fallback Inspection

| Item | Path | Result | Notes |
| --- | --- | --- | --- |
| `ironhold_region` | `scenes/regions/ironhold_region.tscn` | Found/loaded | Real region scene loaded for reference capture. |
| `ironhold_city` | `scenes/chapter2/ironhold_city.tscn` | Found/skipped for capture | Script runs story/quest/dialogue side effects during `_ready()`. |
| `arena_district` | `scenes/chapter2/arena_district.tscn` | Found/skipped for capture | Script enters combat/quest UI flow during `_ready()`. |
| Generated fallback tileset | `assets/generated_v2/tilesets/ironhold_v2_prototype_tileset.png` | Found/loaded | AssetManager resolves Ironhold to this fallback while production slot is absent. |
| AssetManager fallback behavior | `scripts/asset_manager.gd` | Pass | Q2 diagnostic confirms generated fallback and Oakhaven baseline preservation. |

## 4. Preview Script

Created:
`docs/art_pipeline/ironhold_q2_preview/capture_ironhold_q2_preview.gd`

The script renders a preview-only 24x18 Ironhold board with dark industrial floor, central walkway, labels, player/NPC markers, forge/furnace corner, pipes, machinery, props, railings, barriers, a dark corner, and a forge-lit area. It loads the current fallback and Q1 atlases directly from review paths, then saves PNG screenshots and a contact sheet.

It is preview-only because it runs as a standalone `SceneTree` script, is not referenced by gameplay scenes, writes only under `assets/art_sources/comfyui_tests/ironhold_q2_preview/`, and does not touch `production_art`, collision, scene files, story, combat, save/load, or world-map logic.

## 5. Screenshot Evidence

| Preview | Screenshot Path | Notes |
| --- | --- | --- |
| Fallback/reference | `assets/art_sources/comfyui_tests/ironhold_q2_preview/screenshots/ironhold_q2_fallback_preview.png` | Very noisy and repetitive behind labels. |
| Variant A | `assets/art_sources/comfyui_tests/ironhold_q2_preview/screenshots/ironhold_q2_variant_a_preview.png` | Safest readability, a little plain. |
| Variant B | `assets/art_sources/comfyui_tests/ironhold_q2_preview/screenshots/ironhold_q2_variant_b_preview.png` | Best balance of identity, texture, and readability. |
| Variant C | `assets/art_sources/comfyui_tests/ironhold_q2_preview/screenshots/ironhold_q2_variant_c_preview.png` | Readable but darker; better as mood reference. |
| Contact sheet | `assets/art_sources/comfyui_tests/ironhold_q2_preview/contact_sheets/ironhold_q2_fallback_vs_variants_contact_sheet.png` | 2x2 comparison sheet. |

## 6. Actual Scene Reference Captures

| Scene | Screenshot Path | Notes |
| --- | --- | --- |
| Ironhold region | `assets/art_sources/comfyui_tests/ironhold_q2_preview/screenshots/ironhold_q2_actual_region_reference.png` | Captured safely; actual visual layer/farming marker/player detected. |
| Ironhold city | Skipped | Scene runs story/quest/dialogue side effects on `_ready()`. |
| Arena district | Skipped | Scene enters combat state/arena UI flow on `_ready()`. |

## 7. Quality Scores

| Variant | Floor | Walkway | Forge Identity | Props/Obstacles | Player/NPC Contrast | Label Readability | Overall | Verdict |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | --- |
| Fallback | 4.8 | 4.6 | 5.4 | 4.5 | 5.6 | 5.2 | 4.9 | Reject as replacement target; keep as fallback only. |
| A clean | 8.4 | 8.6 | 7.3 | 7.5 | 8.8 | 8.8 | 8.0 | Safest readability candidate. |
| B textured | 8.0 | 8.6 | 8.3 | 8.0 | 8.4 | 8.3 | 8.3 | Best default candidate. |
| C ember/dark | 7.2 | 8.0 | 8.1 | 7.4 | 7.6 | 7.5 | 7.6 | Reference/mood candidate only. |

## 8. Variant Comparison

| Variant | Strength | Weakness | Recommendation |
| --- | --- | --- | --- |
| A clean | Highest readability and least floor noise. | Slightly plain for Ironhold. | Keep as safety/reference variant. |
| B textured | Best forge-city identity while labels remain readable. | Slight broad-floor speckle, but not blocking. | Use for controlled production-art import pass. |
| C ember/dark | Stronger mood and forge glow. | Darker; less safe as default. | Keep as mood reference only. |

## 9. Honest Visual Verdict

* Is Q2 Variant B better than the current fallback in preview? Yes.
* Is Variant B still the best candidate? Yes.
* Is Variant A safer? Yes, but it is also plainer.
* Is Variant C too dark? Slightly too dark for default import; useful as reference.
* Does Ironhold need palette tuning before import? Not mandatory before a controlled import pass; tune after real-scene import preview if needed.
* Is any variant ready for production-art import after this? Variant B is ready for a controlled import pass, not imported in Q2.
* What still needs improvement? Real-scene integration, opacity/modulation check, adjacency review, and whether existing V3 props harmonize with Variant B.

## 10. Project Safety Validation

| Test | Result | Notes |
| --- | --- | --- |
| Discovered Godot path | Pass | `C:\Godot\Godot_v4.6.3-stable_win64_console.exe` |
| Godot version | Pass | `4.6.3.stable.official.7d41c59c4` |
| Project boot | Pass | Headless boot exited 0. |
| Ironhold scene load if found | Pass | `res://scenes/regions/ironhold_region.tscn` loaded; expected missing production-art warnings fell back safely. |
| Preview-only capture | Pass | Windowed capture wrote fallback/A/B/C screenshots and contact sheet; renderer cleanup warnings appeared at exit but process exited 0. |
| AssetManager fallback | Pass | Q2 diagnostic confirms Ironhold resolves to generated fallback while production slot is absent. |
| No production_art overwrite | Pass | `git diff -- assets/production_art` empty; `ironhold_tileset.png` remains absent. |
| Oakhaven baseline preservation | Pass | Q2 diagnostic confirms Oakhaven afternoon production baseline still loads. |
| git diff --check | Pass | Exit 0 with CRLF normalization warnings only. |

## 11. Decision

Ready for Ironhold controlled production-art import pass with Variant B
