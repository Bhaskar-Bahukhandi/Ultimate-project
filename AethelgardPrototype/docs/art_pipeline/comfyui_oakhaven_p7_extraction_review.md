# ComfyUI Oakhaven P7 Extraction Review

Phase 10M-P7 extracted the selected P6 crops into a review-only Oakhaven draft atlas preview. No new ComfyUI images were generated, no production art was imported, and no gameplay scenes/scripts were edited.

## Input Artifact Check

| Artifact | Path | Status |
| --- | --- | --- |
| P6 review markdown | docs/art_pipeline/comfyui_oakhaven_p6_review.md | Read |
| P6 generation manifest | assets/art_sources/comfyui_tests/oakhaven_p6/phase10mp6_generation_manifest.json | Read |
| P6 candidate manifest | assets/art_sources/comfyui_tests/oakhaven_p6/phase10mp6_candidate_manifest.json | Read |
| P6 raw folder | assets/art_sources/comfyui_tests/oakhaven_p6/raw/ | 12 PNG sources present |
| P6 source records | assets/art_sources/comfyui_tests/oakhaven_p6/source_records/ | 12 source records present |
| P6 candidate contact sheet | assets/art_sources/comfyui_tests/oakhaven_p6/review/phase10mp6_candidate_contact_sheet.png | Viewed |
| P6 draft preview atlas | assets/art_sources/comfyui_tests/oakhaven_p6/oakhaven_p6_draft_preview_atlas.png | Viewed |

## Candidate Extraction

| Candidate | Source File | Crop Coordinates | Intended Use | Extracted Path | Result |
| --- | --- | --- | --- | --- | --- |
| grass_terrain_attempt1_crop | grass_terrain_attempt1_seed610001.png | (256, 192, 320, 256) | Grass terrain filler | assets/art_sources/comfyui_tests/oakhaven_p7/extracted_raw/grass_terrain_attempt1_crop_raw.png | Extracted exact 64x64 crop |
| grass_terrain_attempt2_crop | grass_terrain_attempt2_seed610002.png | (320, 96, 384, 160) | Alternate floor/trim study | assets/art_sources/comfyui_tests/oakhaven_p7/extracted_raw/grass_terrain_attempt2_crop_raw.png | Extracted exact 64x64 crop |
| dirt_path_attempt2_crop_a | dirt_path_attempt2_seed620002.png | (64, 64, 128, 128) | Rough path/floor texture | assets/art_sources/comfyui_tests/oakhaven_p7/extracted_raw/dirt_path_attempt2_crop_a_raw.png | Extracted exact 64x64 crop |
| dirt_path_attempt2_crop_b | dirt_path_attempt2_seed620002.png | (256, 64, 320, 128) | Rough path/floor texture | assets/art_sources/comfyui_tests/oakhaven_p7/extracted_raw/dirt_path_attempt2_crop_b_raw.png | Extracted exact 64x64 crop |
| path_transitions_attempt1_crop | path_transitions_attempt1_seed630001.png | (0, 32, 64, 96) | Path edge transition study | assets/art_sources/comfyui_tests/oakhaven_p7/extracted_raw/path_transitions_attempt1_crop_raw.png | Extracted exact 64x64 crop |
| path_transitions_attempt2_crop_a | path_transitions_attempt2_seed630002.png | (32, 224, 96, 288) | Hedge/path edge study | assets/art_sources/comfyui_tests/oakhaven_p7/extracted_raw/path_transitions_attempt2_crop_a_raw.png | Extracted exact 64x64 crop |
| path_transitions_attempt2_crop_b | path_transitions_attempt2_seed630002.png | (288, 64, 352, 128) | Magic marker/prop study | assets/art_sources/comfyui_tests/oakhaven_p7/extracted_raw/path_transitions_attempt2_crop_b_raw.png | Extracted exact 64x64 crop |
| fence_hedge_attempt2_crop_a | fence_hedge_attempt2_seed640002.png | (160, 96, 224, 160) | Hedge/bush prop | assets/art_sources/comfyui_tests/oakhaven_p7/extracted_raw/fence_hedge_attempt2_crop_a_raw.png | Extracted exact 64x64 crop |
| fence_hedge_attempt2_crop_b | fence_hedge_attempt2_seed640002.png | (64, 288, 128, 352) | Wood prop/fence support | assets/art_sources/comfyui_tests/oakhaven_p7/extracted_raw/fence_hedge_attempt2_crop_b_raw.png | Extracted exact 64x64 crop |
| fence_hedge_attempt2_crop_c | fence_hedge_attempt2_seed640002.png | (320, 288, 384, 352) | Cottage/fence support | assets/art_sources/comfyui_tests/oakhaven_p7/extracted_raw/fence_hedge_attempt2_crop_c_raw.png | Extracted exact 64x64 crop |
| small_props_attempt1_crop_a | small_props_attempt1_seed660001.png | (64, 192, 128, 256) | Village prop/source | assets/art_sources/comfyui_tests/oakhaven_p7/extracted_raw/small_props_attempt1_crop_a_raw.png | Extracted exact 64x64 crop |
| small_props_attempt1_crop_b | small_props_attempt1_seed660001.png | (320, 96, 384, 160) | Hedge/clutter source | assets/art_sources/comfyui_tests/oakhaven_p7/extracted_raw/small_props_attempt1_crop_b_raw.png | Extracted exact 64x64 crop |

## Cleanup / Refinement

Allowed cleanup only was used: light contrast normalization, mild saturation reduction, and palette dampening for harsh magenta/cyan artifacts. The raw extracted crops are preserved unchanged in `extracted_raw/`.

| Candidate | Cleanup Applied | Cleaned Path | Notes |
| --- | --- | --- | --- |
| grass_terrain_attempt1_crop | Light contrast/saturation normalization; harsh magenta/cyan damped where present; no generative edit | assets/art_sources/comfyui_tests/oakhaven_p7/extracted_cleaned/grass_terrain_attempt1_crop_cleaned.png | Keep as review/reference terrain source only. Do not import as a production grass tile. |
| grass_terrain_attempt2_crop | Light contrast/saturation normalization; harsh magenta/cyan damped where present; no generative edit | assets/art_sources/comfyui_tests/oakhaven_p7/extracted_cleaned/grass_terrain_attempt2_crop_cleaned.png | Reject for Oakhaven; use only as evidence that this source family is unsuitable. |
| dirt_path_attempt2_crop_a | Light contrast/saturation normalization; harsh magenta/cyan damped where present; no generative edit | assets/art_sources/comfyui_tests/oakhaven_p7/extracted_cleaned/dirt_path_attempt2_crop_a_cleaned.png | Keep as path texture reference. Not ready for import. |
| dirt_path_attempt2_crop_b | Light contrast/saturation normalization; harsh magenta/cyan damped where present; no generative edit | assets/art_sources/comfyui_tests/oakhaven_p7/extracted_cleaned/dirt_path_attempt2_crop_b_cleaned.png | Keep as path/floor study. Not ready for import. |
| path_transitions_attempt1_crop | Light contrast/saturation normalization; harsh magenta/cyan damped where present; no generative edit | assets/art_sources/comfyui_tests/oakhaven_p7/extracted_cleaned/path_transitions_attempt1_crop_cleaned.png | Keep as a transition grammar reference only. |
| path_transitions_attempt2_crop_a | Light contrast/saturation normalization; harsh magenta/cyan damped where present; no generative edit | assets/art_sources/comfyui_tests/oakhaven_p7/extracted_cleaned/path_transitions_attempt2_crop_a_cleaned.png | Keep for edge-study reference. Do not import as-is. |
| path_transitions_attempt2_crop_b | Light contrast/saturation normalization; harsh magenta/cyan damped where present; no generative edit | assets/art_sources/comfyui_tests/oakhaven_p7/extracted_cleaned/path_transitions_attempt2_crop_b_cleaned.png | Reference only for possible magic accent palette. Not an Oakhaven tile. |
| fence_hedge_attempt2_crop_a | Light contrast/saturation normalization; harsh magenta/cyan damped where present; no generative edit | assets/art_sources/comfyui_tests/oakhaven_p7/extracted_cleaned/fence_hedge_attempt2_crop_a_cleaned.png | Best P7 candidate. Keep for review atlas only. |
| fence_hedge_attempt2_crop_b | Light contrast/saturation normalization; harsh magenta/cyan damped where present; no generative edit | assets/art_sources/comfyui_tests/oakhaven_p7/extracted_cleaned/fence_hedge_attempt2_crop_b_cleaned.png | Keep for review atlas only. Needs manual redraw before production. |
| fence_hedge_attempt2_crop_c | Light contrast/saturation normalization; harsh magenta/cyan damped where present; no generative edit | assets/art_sources/comfyui_tests/oakhaven_p7/extracted_cleaned/fence_hedge_attempt2_crop_c_cleaned.png | Reference only for cottage/support color and silhouette. Not a building tile. |
| small_props_attempt1_crop_a | Light contrast/saturation normalization; harsh magenta/cyan damped where present; no generative edit | assets/art_sources/comfyui_tests/oakhaven_p7/extracted_cleaned/small_props_attempt1_crop_a_cleaned.png | Reject for atlas use. |
| small_props_attempt1_crop_b | Light contrast/saturation normalization; harsh magenta/cyan damped where present; no generative edit | assets/art_sources/comfyui_tests/oakhaven_p7/extracted_cleaned/small_props_attempt1_crop_b_cleaned.png | Reference only. Not suitable for production import. |

## 32x32 Downscale Usability

| Candidate | 64x64 Quality | 32x32 Quality | Verdict |
| --- | --- | --- | --- |
| grass_terrain_attempt1_crop | Medium source, but crop contains path/border artifacts and is not a clean repeating grass tile. | Marginal: grass reads, but the non-grass borders dominate at 32x32. | usable only at 64x64 |
| grass_terrain_attempt2_crop | Low: reads as synthetic panel/floor grid, not Oakhaven terrain. | Poor: strong grid remains after cleanup and scale reduction. | reject |
| dirt_path_attempt2_crop_a | Medium: has stone/floor texture, but too busy and square-panel-like for dirt path. | Readable as rough cobble/floor, not as a natural dirt village path. | usable only at 64x64 |
| dirt_path_attempt2_crop_b | Medium: useful texture fragments, but still reads more like tiled stone than dirt. | Readable but noisy; loses material intent at game scale. | usable only at 64x64 |
| path_transitions_attempt1_crop | Medium-low: has edge bands, but the layout is artificial and contains harsh color blocks. | Weak: it reads as stacked stripes rather than a usable terrain transition. | reference only |
| path_transitions_attempt2_crop_a | Medium: strongest transition crop, but color bands are still too graphic. | Semi-readable as edge material, but not coherent with the fallback environment. | usable only at 64x64 |
| path_transitions_attempt2_crop_b | Low: bright marker-like shape, but too abstract and scale-confused. | Poor: glow blob dominates the tile. | reference only |
| fence_hedge_attempt2_crop_a | Medium: reads as shrub/greenery and is one of the clearest P6 candidates. | Readable as a shrub/greenery accent, though not isolated cleanly. | usable at 32x32 |
| fence_hedge_attempt2_crop_b | Medium: the wood support shape is readable, though it is framed like a prop cell. | Readable as a small wood/crate/fence support. | usable at 32x32 |
| fence_hedge_attempt2_crop_c | Medium-low: suggests cottage/fence material, but most of the crop is unstructured green field. | Weak but semi-readable as a support fragment. | usable only at 64x64 |
| small_props_attempt1_crop_a | Low: mixed wall/floor fragments and a blocky gold object; not an isolated prop. | Poor: reads as noise and cropped fragments. | reject |
| small_props_attempt1_crop_b | Low-medium: contains color/clutter fragments but lacks a readable prop silhouette. | Poor: material identity collapses at 32x32. | reference only |

## Draft Atlas Review

- Atlas path: `assets/art_sources/comfyui_tests/oakhaven_p7/oakhaven_p7_review_only_draft_atlas.png`
- Included cells: 8
- Included categories: grass/floor, path/floor, transition studies, hedge/bush, wood/fence, cottage/support
- Missing categories: complete small props/reference, clean cottage/building kit, true path transition grammar, tileable grass set
- Coherence: low to medium. The palette cleanup helps, but the atlas still looks assembled from unrelated source cells.
- Fallback comparison: not better than the current fallback as a replacement. A few individual crops are richer than the V2 fallback sheet, but the current V3 path/hedge/prop fallback art is clearly more coherent.

## Contact Sheets / Review Artifacts

| Artifact | Path | Status |
| --- | --- | --- |
| Raw crops contact sheet | assets/art_sources/comfyui_tests/oakhaven_p7/review/phase10mp7_raw_crops_contact_sheet.png | Created |
| Cleaned crops contact sheet | assets/art_sources/comfyui_tests/oakhaven_p7/review/phase10mp7_cleaned_crops_contact_sheet.png | Created |
| Downscale tests contact sheet | assets/art_sources/comfyui_tests/oakhaven_p7/review/phase10mp7_downscale_tests_contact_sheet.png | Created |
| Draft atlas review | assets/art_sources/comfyui_tests/oakhaven_p7/review/phase10mp7_draft_atlas_review.png | Created |
| P6 vs P7 comparison | assets/art_sources/comfyui_tests/oakhaven_p7/review/phase10mp7_p6_vs_p7_comparison.png | Created |
| Candidate manifest | assets/art_sources/comfyui_tests/oakhaven_p7/manifest/phase10mp7_candidate_manifest.json | Created |

## Optional Preview-Only Mock Scene

Skipped. The P7 atlas and contact sheets are sufficient for review, and a Godot preview scene would add no value without actual gameplay integration, which is forbidden in this phase.

## Comparison Against Current Fallback

| Area | Current Fallback | P7 Candidate Result | Better/Worse |
| --- | --- | --- | --- |
| grass/floor | Generated V2 fallback is simple but coherent as a tile. | One P7 grass crop has richer texture but carries path/border artifacts; one is rejected panel material. | Worse overall |
| dirt/path | V2 fallback path is plain and readable; V3 path decals are much stronger. | P7 dirt crops are richer but read as noisy stone panels, not natural path. | Mixed, not import-ready |
| transition | Current fallback has cleaner readable transitions through V3 overlays. | P7 transitions remain banded and artificial. | Worse |
| hedge/fence | V3 hedge/fence props are coherent and readable. | P7 bush and wood support crops are the best candidates, but inconsistent. | Some individual improvement over V2, worse than V3 |
| cottage/building | Current V3 roof/support props are coherent. | P7 cottage/support crop is only a fragment and not a building kit. | Worse |
| props | Current V3 props have clear silhouettes. | P7 small props are mostly cropped fragments or abstract glow/color blocks. | Worse |
| overall Oakhaven style | Fallback is rough but coherent enough for gameplay preview. | P7 is more textured in places but style-mismatched and incomplete. | Worse as a replacement |

## Honest Visual Verdict

- Did extraction improve P6? Yes, slightly. Exact extraction plus light palette cleanup makes the candidates easier to review.
- Are any candidates actually usable? A few are semi-usable for review only: the bush crop and wood support crop are the clearest; dirt/path crops are reference material.
- Is the draft atlas better than current fallback? No. It is more textured in isolated cells, but less coherent as an Oakhaven replacement.
- Would importing this improve Oakhaven? No. Importing it now would likely create a messy and inconsistent style.
- Should we run another generation pass? Not with the same broad SD 1.5 tile-family workflow as the main plan. More of the same is unlikely to solve tile grammar.
- Do we need a better tileset-specific model/workflow? Yes. A tileset-specific workflow with strict cell isolation, manual layout, and stronger control is needed.
- Is production_art import justified now? No.

## Recommendation

Needs a better tileset-specific model/workflow. Keep P7 as review evidence and source-reference material only.

## Project Safety Validation

| Test | Result | Notes |
| --- | --- | --- |
| Godot version | Pass | `4.6.3.stable.official.7d41c59c4` from `C:\Godot\Godot_v4.6.3-stable_win64_console.exe`. |
| Project boot | Pass | Headless boot with `--quit-after 2` exited 0 and initialized the project autoloads. |
| AssetManager fallback | Pass | `docs/art_pipeline/oakhaven_p7_preview/asset_manager_fallback_check.gd` resolved Oakhaven to `res://assets/generated_v2/tilesets/oakhaven_v2_prototype_tileset.png` with `production=false`. The missing production-art warning is expected. |
| No production_art overwrite | Pass | `assets/production_art/tilesets/oakhaven_tileset.png` is absent, and `git diff -- assets/production_art` is empty. The existing untracked `assets/production_art/` README tree was not used. |
| git diff --check | Pass | Exit code 0. Git printed CRLF normalization warnings for pre-existing tracked script changes. |

## Decision

Needs a better tileset-specific model/workflow
