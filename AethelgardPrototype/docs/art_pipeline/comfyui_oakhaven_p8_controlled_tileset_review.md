# ComfyUI Oakhaven P8 Controlled Tileset Review

Phase 10M-P8 uses a deterministic pixel-art grammar builder instead of another broad ComfyUI tileset batch. No ComfyUI generation was run. No P6/P7 crop was directly imported. No `assets/production_art/` file was written.

## Method

- Built all tiles with Python/Pillow deterministic drawing.
- Shared 16x16 atlas grammar across all three variants.
- Used hard 32x32 cell boundaries, nearest-neighbor previews, limited palettes, and transparent overlay sprites for props/fences where appropriate.
- Used P6/P7 only as failure/context references, not as source imports.

## Input / Context Verification

| Check | Result | Notes |
| --- | --- | --- |
| Project path | Pass | `C:\Users\BHASKAR BAHUKHANDI\OneDrive\Desktop\Ultimate project\AethelgardPrototype` exists and contains `project.godot`. |
| Godot executable discovery | Pass | Preferred console executable found at `C:\Godot\Godot_v4.6.3-stable_win64_console.exe`. |
| Current fallback reference | Pass | `assets/generated_v2/tilesets/oakhaven_v2_prototype_tileset.png` exists. |
| Production Oakhaven tileset | Pass | `assets/production_art/tilesets/oakhaven_tileset.png` is absent. |
| P6/P7 context | Pass | P6/P7 review artifacts were present and used only as comparison/context. |
| ComfyUI generation | Pass | Not used in P8. |

## Files Created

| File | Purpose | Status |
| --- | --- | --- |
| assets/art_sources/comfyui_tests/oakhaven_p8/generated_tiles/oakhaven_p8_variant_a_clean.png | Variant A clean 512x512 atlas | Created |
| assets/art_sources/comfyui_tests/oakhaven_p8/generated_tiles/oakhaven_p8_variant_b_textured.png | Variant B textured 512x512 atlas | Created |
| assets/art_sources/comfyui_tests/oakhaven_p8/generated_tiles/oakhaven_p8_variant_c_dark_glitch.png | Variant C dark/glitch 512x512 atlas | Created |
| assets/art_sources/comfyui_tests/oakhaven_p8/review/oakhaven_p8_variant_a_clean_2x.png | Variant A nearest-neighbor 2x preview | Created |
| assets/art_sources/comfyui_tests/oakhaven_p8/review/oakhaven_p8_variant_b_textured_2x.png | Variant B nearest-neighbor 2x preview | Created |
| assets/art_sources/comfyui_tests/oakhaven_p8/review/oakhaven_p8_variant_c_dark_glitch_2x.png | Variant C nearest-neighbor 2x preview | Created |
| assets/art_sources/comfyui_tests/oakhaven_p8/mockups/oakhaven_p8_variant_a_mockup.png | Variant A 20x15 tile mockup | Created |
| assets/art_sources/comfyui_tests/oakhaven_p8/mockups/oakhaven_p8_variant_b_mockup.png | Variant B 20x15 tile mockup | Created |
| assets/art_sources/comfyui_tests/oakhaven_p8/mockups/oakhaven_p8_variant_c_mockup.png | Variant C 20x15 tile mockup | Created |
| assets/art_sources/comfyui_tests/oakhaven_p8/review/oakhaven_p8_comparison_contact_sheet.png | Fallback/P7/P8 comparison sheet | Created |
| assets/art_sources/comfyui_tests/oakhaven_p8/review/oakhaven_p8_variant_score_sheet.png | Variant score sheet | Created |
| assets/art_sources/comfyui_tests/oakhaven_p8/manifest/oakhaven_p8_tile_layout.md | Documented tile layout map | Created |
| assets/art_sources/comfyui_tests/oakhaven_p8/manifest/oakhaven_p8_generation_manifest.json | Generation and score manifest | Created |
| docs/art_pipeline/oakhaven_p8_preview/generate_oakhaven_p8.py | Reproducible deterministic generator | Created |

## Atlas Layout Summary

| Row Range | Category | Included Tiles |
| --- | --- | --- |
| 0-2 | Grass terrain and variations | Base/darker/lighter/patchy/sparse/flower/worn/shadowed grass plus meadow extras. |
| 3-5 | Dirt path and path centers | Dirt centers, path straights, T-junctions, cross, corners, ends, pebbles, shadow variants. |
| 6-8 | Grass/dirt transitions | Edges, outer/inner corners, diagonal rough edges, broken edges, islands, shadow/flower/stone variants. |
| 9-10 | Fence and hedge | Fence middles/posts/ends/gates/broken pieces, hedge blocks/lines/corners/openings. |
| 11-13 | Cottage/building support | Walls, wood, roofs, eaves, foundation shadows, doorway, windows, trim, porch/support pieces. |
| 14-15 | Props and utility | Flowers, herbs, sign, stone, stump, crate/barrel, shadow, glitch accent, leaves, marker, empty/separator/highlight utility. |

## Variant Review

| Variant | Strength | Weakness | Overall Score | Verdict |
| --- | --- | --- | --- | --- |
| A clean | Best simple gameplay readability and lowest noise. | Plain compared to a final art pass. | 7.4 | good enough for preview-only Godot scene |
| B textured | Best balance of clean grammar, texture, and Oakhaven village identity. | Still deterministic draft art; cottage kit needs more polish. | 7.8 | good enough to consider production import in a later phase after preview review |
| C dark/glitch | Strongest mood and subtle magical corruption identity. | Darker palette may reduce readability in actual scenes. | 7.3 | good enough for preview-only Godot scene |

## Mockup Review

| Variant | Mockup Path | Readability | Oakhaven Feel | Verdict |
| --- | --- | --- | --- | --- |
| A clean | assets/art_sources/comfyui_tests/oakhaven_p8/mockups/oakhaven_p8_variant_a_mockup.png | High | Readable village corner, slightly plain | Preview-ready |
| B textured | assets/art_sources/comfyui_tests/oakhaven_p8/mockups/oakhaven_p8_variant_b_mockup.png | High | Best Oakhaven balance | Best variant |
| C dark/glitch | assets/art_sources/comfyui_tests/oakhaven_p8/mockups/oakhaven_p8_variant_c_mockup.png | Medium-high | Strong dark-fantasy/glitch feel | Preview-ready, needs brightness check |

## Comparison Against Previous Attempts

| Source | Result | Problem | P8 Improvement |
| --- | --- | --- | --- |
| current fallback | Tiny generated V2 sheet with readable but very limited grass/path/wood cells. | Too small and sparse to define Oakhaven village grammar. | P8 adds full terrain/path/building/prop grammar and mockup proof. |
| P6 | LoRA-assisted raw outputs had some source hints. | Noisy, crop-dependent, inconsistent, and not a real tileset. | P8 uses controlled cells and consistent layout instead of extracting accidental crops. |
| P7 | Review-only crop atlas clarified which P6 pieces were semi-usable. | Not coherent; only two 32x32 candidates were useful. | P8 is a coherent atlas with repeatable grass/path, logical transitions, and mockups. |
| P8 best variant | Variant B is structured and usable for preview review. | Still draft deterministic art; needs in-engine scale and scene-context review. | Best current Oakhaven candidate; clearly better than P7 as a grammar pass. |

## Tile Grammar Validation

| Category | Complete? | Usable? | Notes |
| --- | --- | --- | --- |
| grass | Yes | Yes | Base and variations repeat cleanly; B has the best natural texture. |
| dirt path | Yes | Yes | Straight, corner, T, cross, end, and center tiles are logically aligned. |
| transitions | Yes | Mostly | Edges/corners are complete; some rough variants need scene review for best combinations. |
| fence/hedge | Yes | Yes | Transparent overlay sprites read clearly in mockups. |
| cottage/building | Yes | Mostly | Enough for preview mock cottages; not production-polished yet. |
| props | Yes | Yes | Props are simple but readable and stay within cells. |
| utility tiles | Yes | Yes | Transparent empty, separator, shadow-only, and highlight-only cells are included. |

## Honest Visual Verdict

- Is P8 better than P7? Yes. P8 is a coherent tile grammar atlas, while P7 was a rough crop board.
- Is any variant better than the current fallback? Yes. Variant B is the strongest improvement because it provides actual terrain/path/building/prop grammar rather than a tiny fallback sample.
- Would importing the best variant improve Oakhaven? Probably, but not yet. It should go through a preview-only Godot scene review first.
- Is it ready for preview-only Godot testing? Yes.
- Is it ready for production_art import? No. It is coherent, but still draft deterministic art and needs in-engine scale, palette, and composition review.
- What still needs improvement? Cottage tiles need more charm, transition variants need practical scene testing, and props need a stronger final silhouette pass.

## Recommendation

Use Variant B textured as the best P8 review candidate. Keep all P8 outputs in `art_sources` and run a preview-only Godot pass before any production-art discussion.

## Project Safety Validation

| Test | Result | Notes |
| --- | --- | --- |
| Discovered Godot path | Pass | `C:\Godot\Godot_v4.6.3-stable_win64_console.exe` |
| Godot version | Pass | `4.6.3.stable.official.7d41c59c4` |
| Project boot | Pass | Headless boot with `--quit-after 2` exited 0 and initialized project autoloads. |
| AssetManager fallback | Pass | `docs/art_pipeline/oakhaven_p8_preview/asset_manager_fallback_check.gd` resolved Oakhaven to `res://assets/generated_v2/tilesets/oakhaven_v2_prototype_tileset.png` with `production=false`. The missing production-art warning is expected. |
| Preview-only asset check | Pass | `docs/art_pipeline/oakhaven_p8_preview/oakhaven_p8_preview_board.gd` loaded Variant B atlas and mockup from `art_sources` in headless mode. |
| No production_art overwrite | Pass | `assets/production_art/tilesets/oakhaven_tileset.png` is absent and `git diff -- assets/production_art` is empty. |
| git diff --check | Pass | Exit code 0. Git printed CRLF normalization warnings for pre-existing tracked script changes. |

## Decision

Ready for Oakhaven review-only Godot preview pass
