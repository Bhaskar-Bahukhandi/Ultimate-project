# Phase 10M-P9 Oakhaven Time-of-Day Preview Review

## 1. Summary

Phase 10M-P9 created a preview-only Godot capture script that composes the same 24x18 Oakhaven board from the three P8 atlas variants:

- Morning: P8 Variant A clean.
- Afternoon: P8 Variant B textured.
- Night: P8 Variant C dark/glitch.

No ComfyUI generation was run. No AI image generation was run. No gameplay scene was edited. No file was written to `assets/production_art/`.

Overall verdict: the time-of-day concept works as a preview, and Variant B is clearly the strongest default Oakhaven candidate. Variant A is readable but plain. Variant C is atmospheric and still readable, but dark enough to require brightness/palette tuning before any import decision.

## 2. Input Verification

| Input | Path | Status | Notes |
| --- | --- | --- | --- |
| Morning atlas | `assets/art_sources/comfyui_tests/oakhaven_p8/generated_tiles/oakhaven_p8_variant_a_clean.png` | Pass | 512x512 RGBA, 16x16 grid of 32x32 cells. |
| Afternoon atlas | `assets/art_sources/comfyui_tests/oakhaven_p8/generated_tiles/oakhaven_p8_variant_b_textured.png` | Pass | 512x512 RGBA, 16x16 grid of 32x32 cells. |
| Night atlas | `assets/art_sources/comfyui_tests/oakhaven_p8/generated_tiles/oakhaven_p8_variant_c_dark_glitch.png` | Pass | 512x512 RGBA, 16x16 grid of 32x32 cells. |
| Morning mockup | `assets/art_sources/comfyui_tests/oakhaven_p8/mockups/oakhaven_p8_variant_a_mockup.png` | Pass | 640x480 reference mockup exists. |
| Afternoon mockup | `assets/art_sources/comfyui_tests/oakhaven_p8/mockups/oakhaven_p8_variant_b_mockup.png` | Pass | 640x480 reference mockup exists. |
| Night mockup | `assets/art_sources/comfyui_tests/oakhaven_p8/mockups/oakhaven_p8_variant_c_mockup.png` | Pass | 640x480 reference mockup exists. |
| P8 layout map | `assets/art_sources/comfyui_tests/oakhaven_p8/manifest/oakhaven_p8_tile_layout.md` | Pass | Confirms shared zero-based 32x32 grammar. |
| P8 review doc | `docs/art_pipeline/comfyui_oakhaven_p8_controlled_tileset_review.md` | Pass | Confirms P8 was review-only and not production art. |

## 3. Time-of-Day Mapping

| Time State | Variant | Atlas Path | Intended Mood | Tint/Overlay | Result |
| --- | --- | --- | --- | --- | --- |
| Morning | P8 Variant A clean | `assets/art_sources/comfyui_tests/oakhaven_p8/generated_tiles/oakhaven_p8_variant_a_clean.png` | fresh, readable, early day | very light warm/neutral | Safe and readable, slightly plain. |
| Afternoon | P8 Variant B textured | `assets/art_sources/comfyui_tests/oakhaven_p8/generated_tiles/oakhaven_p8_variant_b_textured.png` | default Oakhaven daytime | neutral | Best default candidate. |
| Night | P8 Variant C dark/glitch | `assets/art_sources/comfyui_tests/oakhaven_p8/generated_tiles/oakhaven_p8_variant_c_dark_glitch.png` | darker magical night | subtle cool/dim | Atmospheric, but needs brightness/contrast tuning. |

## 4. Preview Scene / Script

| Item | Path | Notes |
| --- | --- | --- |
| Preview capture script | `docs/art_pipeline/oakhaven_p9_time_preview/capture_oakhaven_p9_time_preview.gd` | Extends `SceneTree`, loads P8 atlases, composes a 24x18 tile board using documented atlas coordinates, applies time tint, draws player/NPC scale markers, and saves PNGs. |
| Fallback validation script | `docs/art_pipeline/oakhaven_p9_time_preview/asset_manager_fallback_check.gd` | Verifies the production Oakhaven slot is absent and AssetManager resolves to the generated fallback. |

The preview is not connected to the main project scene tree, not referenced by gameplay, and does not modify collision, story, world map, farming, combat, animation systems, save/load, or AssetManager behavior.

## 5. Screenshot Evidence

| Time State | Screenshot Path | Notes |
| --- | --- | --- |
| Morning | `assets/art_sources/comfyui_tests/oakhaven_p9_time_preview/screenshots/oakhaven_p9_morning_preview.png` | 768x576, 24x18 tiles. |
| Afternoon | `assets/art_sources/comfyui_tests/oakhaven_p9_time_preview/screenshots/oakhaven_p9_afternoon_preview.png` | 768x576, strongest default read. |
| Night | `assets/art_sources/comfyui_tests/oakhaven_p9_time_preview/screenshots/oakhaven_p9_night_preview.png` | 768x576, readable but dark. |
| Time contact sheet | `assets/art_sources/comfyui_tests/oakhaven_p9_time_preview/contact_sheets/oakhaven_p9_time_of_day_contact_sheet.png` | Side-by-side morning/afternoon/night. |
| Fallback comparison sheet | `assets/art_sources/comfyui_tests/oakhaven_p9_time_preview/contact_sheets/oakhaven_p9_fallback_vs_time_preview_contact_sheet.png` | Accessible generated fallback reference, P7 draft atlas if present, and P9 afternoon preview. |

## 6. Readability / Quality Scores

| Time State | Tile Readability | Player/NPC Readability | Atmosphere | Oakhaven Identity | Overall Score | Verdict |
| --- | --- | --- | --- | --- | --- | --- |
| Morning | 8 | 8 | 7 | 7 | 7.4 | Readable and safe for preview; slightly plain. |
| Afternoon | 8 | 8 | 8 | 8 | 8.0 | Best default Oakhaven preview. |
| Night | 7 | 8 | 8 | 8 | 7.3 | Good mood pass, but needs brightness/palette tuning. |

## 7. Tile Coordinate Consistency

| Check | Result | Notes |
| --- | --- | --- |
| Shared 32x32 grid | Pass | All three atlases are 512x512, 16 columns by 16 rows. |
| Same layout across variants | Pass | P8 layout map defines a shared coordinate grammar for A/B/C. |
| No missing tile categories | Pass | 146 documented cells checked; all three variants populate 145 cells, with only `transparent_empty_tile` intentionally empty. |
| Preview board coordinate use | Pass | The board uses grass, path, transitions, fence/hedge, cottage, props, utility shadow/accent cells. |
| No production import | Pass | P9 uses `assets/art_sources` only. |

## 8. Comparison Against Current Fallback

| Area | Current Fallback | P9 Time Preview | Better/Worse |
| --- | --- | --- | --- |
| grass | Sparse generated fallback cells; limited terrain vocabulary. | Full grass field with clean variations. | Better |
| path | Readable but small and limited. | Winding path grammar with turns, ends, and junctions. | Better |
| transitions | Limited fallback support. | Explicit grass/dirt edge and corner cells are visible. | Better |
| cottage/building | Fallback has tiny sample-like pieces. | Cottage base reads as an actual village structure. | Better |
| fence/hedge | Fallback is limited. | Fence and hedge boundaries read clearly at map scale. | Better |
| props | Fallback prop coverage is sparse. | Flowers, herbs, sign, stump, stone, barrel/crate, shadow, and glitch accent are visible. | Better |
| overall scene feel | Functional placeholder. | Coherent review-only Oakhaven village corner. | Better, but still draft art. |

## 9. Honest Visual Verdict

- Is Variant B better than fallback in-engine? Yes, in this preview it is more coherent and has a much stronger tile grammar than the accessible generated Oakhaven fallback.
- Do the three variants work as morning/day/night? Mostly yes. They share coordinates and form recognizable time states.
- Is Variant C too dark? It is not unreadable, but it is dark enough to need tuning before import.
- Is Variant A too plain? It is safe and readable, but a little under-charactered beside Variant B.
- Would importing Variant B alone improve Oakhaven? Probably, after a focused import/tuning review. It is the strongest candidate.
- Would importing all three variants be worth the added complexity? Not yet. Night and morning need tuning before time-of-day import is worth the extra system/art complexity.
- Is this ready for production_art import? No. It is ready for a controlled brightness/palette tuning pass, then a stricter import review.
- What still needs improvement? Night brightness, morning detail, prop polish, building depth, hedge/fence contrast, and final comparison inside the actual Oakhaven scene scale.

## 10. Project Safety Validation

| Test | Result | Notes |
| --- | --- | --- |
| Discovered Godot path | Pass | `C:\Godot\Godot_v4.6.3-stable_win64_console.exe`. |
| Godot version | Pass | `4.6.3.stable.official.7d41c59c4`. |
| Project boot | Pass | Headless boot completed with existing startup logs. |
| Preview-only load | Pass | `capture_oakhaven_p9_time_preview.gd` ran headless and exited 0. |
| Screenshot capture | Pass | Morning, afternoon, night, time contact sheet, and fallback comparison sheet saved. |
| AssetManager fallback | Pass | `asset_manager_fallback_check.gd` resolved to `res://assets/generated_v2/tilesets/oakhaven_v2_prototype_tileset.png` with `production=false`; the missing production-art warning is expected. |
| No production_art overwrite | Pass | `assets/production_art/tilesets/oakhaven_tileset.png` is absent and `git diff -- assets/production_art` is empty. The existing README-only `assets/production_art/` tree was not used. |
| git diff --check | Pass | Exit code 0; Git reported existing CRLF normalization warnings only. |

## 11. Decision

Needs brightness/palette tuning before import
