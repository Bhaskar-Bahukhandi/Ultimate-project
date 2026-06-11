# Phase 10M-P10 Oakhaven Time-of-Day Palette Tuning Review

## 1. Summary

Phase 10M-P10 tuned the three P8/P9 Oakhaven time-of-day atlas variants using deterministic Pillow color processing only. No ComfyUI generation was run, no AI image generation was used, no gameplay scene was edited, and nothing was written to `assets/production_art/`.

Overall verdict: the palette pass improved the time-of-day set enough for a later controlled import review. Afternoon remains the safest default, Morning now has more freshness and visual life, and Night is significantly more readable while keeping a cool magical night mood.

## 2. Input Verification

| Input | Path | Status | Notes |
| --- | --- | --- | --- |
| Morning source atlas | `assets/art_sources/comfyui_tests/oakhaven_p8/generated_tiles/oakhaven_p8_variant_a_clean.png` | Pass | 512x512 RGBA, 16x16 grid. |
| Afternoon source atlas | `assets/art_sources/comfyui_tests/oakhaven_p8/generated_tiles/oakhaven_p8_variant_b_textured.png` | Pass | 512x512 RGBA, 16x16 grid. |
| Night source atlas | `assets/art_sources/comfyui_tests/oakhaven_p8/generated_tiles/oakhaven_p8_variant_c_dark_glitch.png` | Pass | 512x512 RGBA, 16x16 grid. |
| P9 morning screenshot | `assets/art_sources/comfyui_tests/oakhaven_p9_time_preview/screenshots/oakhaven_p9_morning_preview.png` | Pass | 768x576 before reference. |
| P9 afternoon screenshot | `assets/art_sources/comfyui_tests/oakhaven_p9_time_preview/screenshots/oakhaven_p9_afternoon_preview.png` | Pass | 768x576 before reference. |
| P9 night screenshot | `assets/art_sources/comfyui_tests/oakhaven_p9_time_preview/screenshots/oakhaven_p9_night_preview.png` | Pass | 768x576 before reference. |
| P9 contact sheet | `assets/art_sources/comfyui_tests/oakhaven_p9_time_preview/contact_sheets/oakhaven_p9_time_of_day_contact_sheet.png` | Pass | 2304x576 before reference. |
| P8 layout map | `assets/art_sources/comfyui_tests/oakhaven_p8/manifest/oakhaven_p8_tile_layout.md` | Pass | Shared coordinate grammar confirmed. |
| P8 review doc | `docs/art_pipeline/comfyui_oakhaven_p8_controlled_tileset_review.md` | Pass | Confirms P8 was preview-only. |
| P9 review doc | `docs/art_pipeline/oakhaven_p9_time_of_day_preview_review.md` | Pass | Confirms P9 tuning target. |

## 3. Tuning Changes

| Time State | Original Variant | Main Issue | Tuning Applied | Result |
| --- | --- | --- | --- | --- |
| Morning | P8 Variant A clean | Readable but slightly plain. | Warm morning lift, moderate saturation gain, tiny deterministic luminance variation on terrain/path pixels. | Brighter, fresher, and more alive without becoming neon. |
| Afternoon | P8 Variant B textured | Already strongest default. | Minor contrast polish, slight saturation harmony, tiny path warmth. | Still the safest default; style changed very little. |
| Night | P8 Variant C dark/glitch | Atmospheric but too dark. | Lifted shadows, improved path/prop readability, restrained cool moonlit grade, preserved glitch accents. | Much more readable while still distinct from daytime. |

## 4. Tuned Atlas Files

| Time State | Tuned Atlas Path | 2x Preview Path | Status |
| --- | --- | --- | --- |
| Morning | `assets/art_sources/comfyui_tests/oakhaven_p10_palette_tuning/tuned_atlases/oakhaven_p10_morning_tuned.png` | `assets/art_sources/comfyui_tests/oakhaven_p10_palette_tuning/contact_sheets/oakhaven_p10_morning_tuned_2x.png` | Pass |
| Afternoon | `assets/art_sources/comfyui_tests/oakhaven_p10_palette_tuning/tuned_atlases/oakhaven_p10_afternoon_tuned.png` | `assets/art_sources/comfyui_tests/oakhaven_p10_palette_tuning/contact_sheets/oakhaven_p10_afternoon_tuned_2x.png` | Pass |
| Night | `assets/art_sources/comfyui_tests/oakhaven_p10_palette_tuning/tuned_atlases/oakhaven_p10_night_tuned.png` | `assets/art_sources/comfyui_tests/oakhaven_p10_palette_tuning/contact_sheets/oakhaven_p10_night_tuned_2x.png` | Pass |

## 5. Screenshot Evidence

| Time State | Screenshot Path | Notes |
| --- | --- | --- |
| Morning | `assets/art_sources/comfyui_tests/oakhaven_p10_palette_tuning/screenshots/oakhaven_p10_morning_preview.png` | 24x18 tile mockup; brighter and warmer than P9. |
| Afternoon | `assets/art_sources/comfyui_tests/oakhaven_p10_palette_tuning/screenshots/oakhaven_p10_afternoon_preview.png` | 24x18 tile mockup; best default remains stable. |
| Night | `assets/art_sources/comfyui_tests/oakhaven_p10_palette_tuning/screenshots/oakhaven_p10_night_preview.png` | 24x18 tile mockup; path/player readability improved. |
| Before/after contact sheet | `assets/art_sources/comfyui_tests/oakhaven_p10_palette_tuning/contact_sheets/oakhaven_p10_before_after_contact_sheet.png` | P9 vs P10 for all three states. |
| Tuned time-of-day contact sheet | `assets/art_sources/comfyui_tests/oakhaven_p10_palette_tuning/contact_sheets/oakhaven_p10_tuned_time_of_day_contact_sheet.png` | P10 Morning, Afternoon, Night side-by-side. |
| Fallback comparison sheet | `assets/art_sources/comfyui_tests/oakhaven_p10_palette_tuning/contact_sheets/oakhaven_p10_fallback_vs_tuned_contact_sheet.png` | Current fallback/P7 reference area and tuned P10 afternoon preview. |
| Godot validation sheet | `assets/art_sources/comfyui_tests/oakhaven_p10_palette_tuning/contact_sheets/oakhaven_p10_godot_preview_validation_contact_sheet.png` | Created by headless Godot loading P10 tuned assets. |

## 6. Readability / Quality Scores

| Time State | P9 Score | P10 Score | Improvement | Verdict |
| --- | --- | --- | --- | --- |
| Morning | 7.4 | 8.0 | +0.6 | Improved enough to be a viable morning candidate. |
| Afternoon | 8.0 | 8.1 | +0.1 | Still the best and safest default. |
| Night | 7.3 | 7.9 | +0.6 | Readability improved; still moodier than daytime. |

| Time State | Tile Readability | Player/NPC Readability | Atmosphere | Oakhaven Identity | Overall Score |
| --- | --- | --- | --- | --- | --- |
| Morning | 8 | 8 | 8 | 8 | 8.0 |
| Afternoon | 8 | 8 | 8 | 8 | 8.1 |
| Night | 8 | 8 | 8 | 8 | 7.9 |

## 7. Tile Coordinate Consistency

| Check | Result | Notes |
| --- | --- | --- |
| 512x512 preserved | Pass | All three tuned atlases are exactly 512x512. |
| 32x32 grid preserved | Pass | 16 columns by 16 rows preserved. |
| Same layout across tuned variants | Pass | Pixel processing only; no tile movement, insertion, or deletion. |
| No missing categories | Pass | 146 documented cells checked; 145 populated and only `transparent_empty_tile` intentionally empty in all variants. |
| Transparent cells preserved | Pass | The documented transparent tile remains transparent. |
| No production import | Pass | P10 outputs are under `assets/art_sources` and `docs/art_pipeline` only. |

## 8. Comparison Against Current Fallback

| Area | Current Fallback | P10 Tuned Result | Better/Worse |
| --- | --- | --- | --- |
| grass | Small, sparse generated fallback vocabulary. | More complete grass field with time-of-day variation. | Better |
| path | Readable but limited. | Winding path, turns, ends, and junctions remain readable in all states. | Better |
| transitions | Limited fallback support. | Edge and corner transition grammar is visible. | Better |
| cottage/building | Placeholder-like pieces. | Cottage reads as a coherent village structure. | Better |
| fence/hedge | Limited boundary support. | Fence and hedge lines read clearly; night hedge is acceptable but still the softest category. | Better |
| props | Sparse coverage. | Sign, stump, stone, barrel/crate, flowers, herbs, shadow, and glitch accent are visible. | Better |
| overall scene feel | Functional placeholder. | Coherent Oakhaven time-of-day draft. | Better |

## 9. Import Strategy Recommendation

- Is Variant B/Afternoon still the best default? Yes. It remains the safest single import candidate.
- Did Morning improve enough? Yes. It now feels warmer and less plain without losing readability.
- Did Night become readable enough? Yes for a review/import pass. It should still get one real in-scene scale check before final acceptance.
- Should we import B only later? That is still the conservative fallback if time-of-day support feels too expensive.
- Should we import all three later? Yes, the tuned set is now coherent enough to justify a controlled morning/day/night import pass.
- Is time-of-day worth the added complexity? For visual review, yes; the shared coordinate grammar makes it low-risk compared with unrelated atlas variants.
- Is production_art import justified now? Not in this phase. The next phase can be an import pass, but P10 itself remained preview-only.

## 10. Project Safety Validation

| Test | Result | Notes |
| --- | --- | --- |
| Discovered Godot path | Pass | `C:\Godot\Godot_v4.6.3-stable_win64_console.exe`. |
| Godot version | Pass | `4.6.3.stable.official.7d41c59c4`. |
| Project boot | Pass | Headless boot completed with existing startup logs. |
| Preview-only load/capture | Pass | `validate_oakhaven_p10_preview.gd` loaded tuned atlases/screenshots and saved a validation contact sheet. |
| AssetManager fallback | Pass | `asset_manager_fallback_check.gd` resolved Oakhaven to `res://assets/generated_v2/tilesets/oakhaven_v2_prototype_tileset.png` with `production=false`; missing production-art warning is expected. |
| No production_art overwrite | Pass | `assets/production_art/tilesets/oakhaven_tileset.png` is absent and `git diff -- assets/production_art` is empty. |
| git diff --check | Pass | Exit code 0; Git reported existing CRLF normalization warnings only. |

## 11. Decision

Ready for Oakhaven production-art import pass with morning/day/night variants
