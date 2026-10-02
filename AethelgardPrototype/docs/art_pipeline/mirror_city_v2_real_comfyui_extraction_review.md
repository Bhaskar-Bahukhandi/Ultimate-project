# PHASE 10M-V2 MIRROR CITY REAL COMFYUI SOURCE EXTRACTION / USABILITY REVIEW

## 1. Summary

* AGENTS.md read: Yes.
* V1 real ComfyUI source evidence verified: Yes.
* ComfyUI used this phase: No new generation.
* `/prompt` called this phase: No.
* Production import performed: No.
* Candidate atlases created: 2 review-only extraction attempts.
* Game-scale mockups created: 2 review-only boards.
* Current Mirror City baseline changed: No.
* Overall verdict: V2 extraction produced useful reference material, but no extracted candidate clearly beats the current T7 procedural production baseline at game scale.

## 2. Source-truth classification

* ComfyUI used this phase: No new generation.
* Source images: real ComfyUI V1 evidence from `assets/art_sources/comfyui_real/mirror_city_v1_source_generation/`.
* Procedural/manual processing: Python/Pillow was used only for crop extraction, 64-to-32 downscale tests, direct 32px crop tests, contact sheets, diagnostic annotation, and review mockups.
* Manual pixel-art reconstruction: No.
* Classification of V2 outputs: derived extraction/review artifacts from real ComfyUI V1 sources, not fresh ComfyUI outputs and not production art.

## 3. Input evidence verification table

| Evidence/Input | Path | Status | Dimensions/Notes |
| --- | --- | --- | --- |
| phase evidence | assets/art_sources/comfyui_real/mirror_city_v1_source_generation/manifest/mirror_city_v1_comfyui_manifest.json | Present | n/a |
| phase evidence | assets/art_sources/comfyui_real/mirror_city_v1_source_generation/diagnostics/mirror_city_v1_generation_diagnostics.json | Present | n/a |
| workflow_api_json | assets/art_sources/comfyui_real/mirror_city_v1_source_generation/workflow/mirror_city_v1_family_a_seed_771003_workflow_api.json | Present | n/a |
| prompt_json | assets/art_sources/comfyui_real/mirror_city_v1_source_generation/prompts/mirror_city_v1_family_a_seed_771003_prompt.json | Present | n/a |
| history_json | assets/art_sources/comfyui_real/mirror_city_v1_source_generation/diagnostics/mirror_city_v1_family_a_seed_771003_history.json | Present | n/a |
| raw_comfyui_output | assets/art_sources/comfyui_real/mirror_city_v1_source_generation/outputs_raw/mirror_city_v1_family_a_seed_771003.png | Present | 512x512 RGB |
| workflow_api_json | assets/art_sources/comfyui_real/mirror_city_v1_source_generation/workflow/mirror_city_v1_family_b_seed_772002_workflow_api.json | Present | n/a |
| prompt_json | assets/art_sources/comfyui_real/mirror_city_v1_source_generation/prompts/mirror_city_v1_family_b_seed_772002_prompt.json | Present | n/a |
| history_json | assets/art_sources/comfyui_real/mirror_city_v1_source_generation/diagnostics/mirror_city_v1_family_b_seed_772002_history.json | Present | n/a |
| raw_comfyui_output | assets/art_sources/comfyui_real/mirror_city_v1_source_generation/outputs_raw/mirror_city_v1_family_b_seed_772002.png | Present | 512x512 RGB |
| workflow_api_json | assets/art_sources/comfyui_real/mirror_city_v1_source_generation/workflow/mirror_city_v1_family_c_seed_773001_workflow_api.json | Present | n/a |
| prompt_json | assets/art_sources/comfyui_real/mirror_city_v1_source_generation/prompts/mirror_city_v1_family_c_seed_773001_prompt.json | Present | n/a |
| history_json | assets/art_sources/comfyui_real/mirror_city_v1_source_generation/diagnostics/mirror_city_v1_family_c_seed_773001_history.json | Present | n/a |
| raw_comfyui_output | assets/art_sources/comfyui_real/mirror_city_v1_source_generation/outputs_raw/mirror_city_v1_family_c_seed_773001.png | Present | 512x512 RGB |
| workflow_api_json | assets/art_sources/comfyui_real/mirror_city_v1_source_generation/workflow/mirror_city_v1_family_d_seed_774002_workflow_api.json | Present | n/a |
| prompt_json | assets/art_sources/comfyui_real/mirror_city_v1_source_generation/prompts/mirror_city_v1_family_d_seed_774002_prompt.json | Present | n/a |
| history_json | assets/art_sources/comfyui_real/mirror_city_v1_source_generation/diagnostics/mirror_city_v1_family_d_seed_774002_history.json | Present | n/a |
| raw_comfyui_output | assets/art_sources/comfyui_real/mirror_city_v1_source_generation/outputs_raw/mirror_city_v1_family_d_seed_774002.png | Present | 512x512 RGB |
| generated_v2_fallback | assets/generated_v2/tilesets/mirror_city_v2_prototype_tileset.png | Present | 128x64 RGBA |
| t7_procedural_production | assets/production_art/tilesets/mirror_city/mirror_city_tileset.png | Present | 512x512 RGBA |
| v3_props | assets/generated_v3/props/phase10mm_environment_prop_atlas.png | Present | 1536x1024 RGBA |
| v3_decals | assets/generated_v3/overlays/phase10mm_environment_decal_atlas.png | Present | 1536x1024 RGBA |
| oakhaven | assets/production_art/tilesets/oakhaven/oakhaven_afternoon_tileset.png | Present | 512x512 RGBA |
| ironhold | assets/production_art/tilesets/ironhold/ironhold_tileset.png | Present | 512x512 RGBA |
| fractured_wastes | assets/production_art/tilesets/fractured_wastes/fractured_wastes_tileset.png | Present | 512x512 RGBA |

## 4. Files created

| File/Folder | Purpose |
| --- | --- |
| assets/art_sources/comfyui_real/mirror_city_v2_source_extraction_review/extracted_cells/a64_glass_panel_upper_left_64.png | V2 review-only extraction evidence |
| assets/art_sources/comfyui_real/mirror_city_v2_source_extraction_review/extracted_cells/a64_glass_panel_upper_left_32.png | V2 review-only extraction evidence |
| assets/art_sources/comfyui_real/mirror_city_v2_source_extraction_review/extracted_cells/a64_mirror_plate_mid_left_64.png | V2 review-only extraction evidence |
| assets/art_sources/comfyui_real/mirror_city_v2_source_extraction_review/extracted_cells/a64_mirror_plate_mid_left_32.png | V2 review-only extraction evidence |
| assets/art_sources/comfyui_real/mirror_city_v2_source_extraction_review/extracted_cells/a64_dark_label_sw_64.png | V2 review-only extraction evidence |
| assets/art_sources/comfyui_real/mirror_city_v2_source_extraction_review/extracted_cells/a64_dark_label_sw_32.png | V2 review-only extraction evidence |
| assets/art_sources/comfyui_real/mirror_city_v2_source_extraction_review/extracted_cells/a64_central_reflection_knot_64.png | V2 review-only extraction evidence |
| assets/art_sources/comfyui_real/mirror_city_v2_source_extraction_review/extracted_cells/a64_central_reflection_knot_32.png | V2 review-only extraction evidence |
| assets/art_sources/comfyui_real/mirror_city_v2_source_extraction_review/extracted_cells/a64_diagonal_route_nw_64.png | V2 review-only extraction evidence |
| assets/art_sources/comfyui_real/mirror_city_v2_source_extraction_review/extracted_cells/a64_diagonal_route_nw_32.png | V2 review-only extraction evidence |
| assets/art_sources/comfyui_real/mirror_city_v2_source_extraction_review/extracted_cells/a64_diagonal_route_se_64.png | V2 review-only extraction evidence |
| assets/art_sources/comfyui_real/mirror_city_v2_source_extraction_review/extracted_cells/a64_diagonal_route_se_32.png | V2 review-only extraction evidence |
| assets/art_sources/comfyui_real/mirror_city_v2_source_extraction_review/extracted_cells/a64_pale_vertical_panel_64.png | V2 review-only extraction evidence |
| assets/art_sources/comfyui_real/mirror_city_v2_source_extraction_review/extracted_cells/a64_pale_vertical_panel_32.png | V2 review-only extraction evidence |
| assets/art_sources/comfyui_real/mirror_city_v2_source_extraction_review/extracted_cells/a64_fragment_corner_ne_64.png | V2 review-only extraction evidence |
| assets/art_sources/comfyui_real/mirror_city_v2_source_extraction_review/extracted_cells/a64_fragment_corner_ne_32.png | V2 review-only extraction evidence |
| assets/art_sources/comfyui_real/mirror_city_v2_source_extraction_review/extracted_cells/a64_wall_edge_left_64.png | V2 review-only extraction evidence |
| assets/art_sources/comfyui_real/mirror_city_v2_source_extraction_review/extracted_cells/a64_wall_edge_left_32.png | V2 review-only extraction evidence |
| assets/art_sources/comfyui_real/mirror_city_v2_source_extraction_review/extracted_cells/a64_symmetric_floor_center_64.png | V2 review-only extraction evidence |
| assets/art_sources/comfyui_real/mirror_city_v2_source_extraction_review/extracted_cells/a64_symmetric_floor_center_32.png | V2 review-only extraction evidence |
| assets/art_sources/comfyui_real/mirror_city_v2_source_extraction_review/extracted_cells/b64_base_plate_01_64.png | V2 review-only extraction evidence |
| assets/art_sources/comfyui_real/mirror_city_v2_source_extraction_review/extracted_cells/b64_base_plate_01_32.png | V2 review-only extraction evidence |
| assets/art_sources/comfyui_real/mirror_city_v2_source_extraction_review/extracted_cells/b64_base_plate_02_64.png | V2 review-only extraction evidence |
| assets/art_sources/comfyui_real/mirror_city_v2_source_extraction_review/extracted_cells/b64_base_plate_02_32.png | V2 review-only extraction evidence |
| assets/art_sources/comfyui_real/mirror_city_v2_source_extraction_review/extracted_cells/b64_base_plate_03_64.png | V2 review-only extraction evidence |
| assets/art_sources/comfyui_real/mirror_city_v2_source_extraction_review/extracted_cells/b64_base_plate_03_32.png | V2 review-only extraction evidence |
| assets/art_sources/comfyui_real/mirror_city_v2_source_extraction_review/extracted_cells/b64_base_plate_04_64.png | V2 review-only extraction evidence |
| assets/art_sources/comfyui_real/mirror_city_v2_source_extraction_review/extracted_cells/b64_base_plate_04_32.png | V2 review-only extraction evidence |
| assets/art_sources/comfyui_real/mirror_city_v2_source_extraction_review/extracted_cells/b64_base_plate_05_64.png | V2 review-only extraction evidence |
| assets/art_sources/comfyui_real/mirror_city_v2_source_extraction_review/extracted_cells/b64_base_plate_05_32.png | V2 review-only extraction evidence |
| assets/art_sources/comfyui_real/mirror_city_v2_source_extraction_review/extracted_cells/b64_base_plate_06_64.png | V2 review-only extraction evidence |
| assets/art_sources/comfyui_real/mirror_city_v2_source_extraction_review/extracted_cells/b64_base_plate_06_32.png | V2 review-only extraction evidence |
| assets/art_sources/comfyui_real/mirror_city_v2_source_extraction_review/extracted_cells/a32_direct_center_knot.png | V2 review-only extraction evidence |
| assets/art_sources/comfyui_real/mirror_city_v2_source_extraction_review/extracted_cells/a32_direct_dark_tile.png | V2 review-only extraction evidence |
| assets/art_sources/comfyui_real/mirror_city_v2_source_extraction_review/extracted_cells/a32_direct_edge.png | V2 review-only extraction evidence |
| assets/art_sources/comfyui_real/mirror_city_v2_source_extraction_review/extracted_cells/b32_direct_plate_01.png | V2 review-only extraction evidence |
| assets/art_sources/comfyui_real/mirror_city_v2_source_extraction_review/extracted_cells/b32_direct_plate_02.png | V2 review-only extraction evidence |
| assets/art_sources/comfyui_real/mirror_city_v2_source_extraction_review/extracted_cells/b32_direct_plate_03.png | V2 review-only extraction evidence |
| assets/art_sources/comfyui_real/mirror_city_v2_source_extraction_review/candidate_atlases/mirror_city_v2_candidate_a_pure_a_seed_extraction_atlas.png | V2 review-only extraction evidence |
| assets/art_sources/comfyui_real/mirror_city_v2_source_extraction_review/candidate_atlases/mirror_city_v2_candidate_b_a_b_hybrid_extraction_atlas.png | V2 review-only extraction evidence |
| assets/art_sources/comfyui_real/mirror_city_v2_source_extraction_review/mockups/mirror_city_v2_candidate_a_game_scale_mockup.png | V2 review-only extraction evidence |
| assets/art_sources/comfyui_real/mirror_city_v2_source_extraction_review/mockups/mirror_city_v2_candidate_b_game_scale_mockup.png | V2 review-only extraction evidence |
| assets/art_sources/comfyui_real/mirror_city_v2_source_extraction_review/contact_sheets/mirror_city_v2_v1_source_candidates_contact_sheet.png | V2 review-only extraction evidence |
| assets/art_sources/comfyui_real/mirror_city_v2_source_extraction_review/contact_sheets/mirror_city_v2_extracted_cells_contact_sheet.png | V2 review-only extraction evidence |
| assets/art_sources/comfyui_real/mirror_city_v2_source_extraction_review/contact_sheets/mirror_city_v2_candidate_atlas_mockup_contact_sheet.png | V2 review-only extraction evidence |
| assets/art_sources/comfyui_real/mirror_city_v2_source_extraction_review/contact_sheets/mirror_city_v2_baseline_vs_extraction_comparison.png | V2 review-only extraction evidence |
| assets/art_sources/comfyui_real/mirror_city_v2_source_extraction_review/contact_sheets/mirror_city_v2_full_extraction_review_contact_sheet.png | V2 review-only extraction evidence |
| assets/art_sources/comfyui_real/mirror_city_v2_source_extraction_review/diagnostics/mirror_city_v2_d_seed_774002_rejected_glyph_regions.png | V2 review-only extraction evidence |
| assets/art_sources/comfyui_real/mirror_city_v2_source_extraction_review/diagnostics/v3_prop_sample.png | V2 review-only extraction evidence |
| assets/art_sources/comfyui_real/mirror_city_v2_source_extraction_review/diagnostics/v3_decal_sample.png | V2 review-only extraction evidence |
| assets/art_sources/comfyui_real/mirror_city_v2_source_extraction_review/manifest/mirror_city_v2_extraction_manifest.json | V2 review-only extraction evidence |
| assets/art_sources/comfyui_real/mirror_city_v2_source_extraction_review/diagnostics/mirror_city_v2_extraction_diagnostics.json | V2 review-only extraction evidence |
| docs/art_pipeline/mirror_city_v2_real_comfyui_extraction_review.md | V2 review-only extraction evidence |

## 5. Source candidate review

| Source | Path | Strength | Limitation |
| --- | --- | --- | --- |
| A seed 771003 | assets/art_sources/comfyui_real/mirror_city_v1_source_generation/outputs_raw/mirror_city_v1_family_a_seed_771003.png | Best real ComfyUI Mirror City identity | Useful as reference/extraction source; 32px crops are noisy/soft. |
| B seed 772002 | assets/art_sources/comfyui_real/mirror_city_v1_source_generation/outputs_raw/mirror_city_v1_family_b_seed_772002.png | Best base material source | Useful dark plates; lacks route language. |
| C seed 773001 | assets/art_sources/comfyui_real/mirror_city_v1_source_generation/outputs_raw/mirror_city_v1_family_c_seed_773001.png | Layout reference only | Too bright/grass-like; not used in atlases. |
| D seed 774002 | assets/art_sources/comfyui_real/mirror_city_v1_source_generation/outputs_raw/mirror_city_v1_family_d_seed_774002.png | Symmetry reference only | Glyph/text-like artifacts rejected; not used in atlases. |

## 6. Extraction method

Cells were produced by direct crop or crop plus downscale from V1 real ComfyUI images. No cells were drawn from scratch. No palette tuning, tinting, overpainting, cleanup, or manual pixel reconstruction was applied.

| Cell | Source | Crop Box | Output | Processing | Intended Use |
| --- | --- | --- | --- | --- | --- |
| a64_glass_panel_upper_left_64 | A_771003 | (64, 64, 128, 128) | assets/art_sources/comfyui_real/mirror_city_v2_source_extraction_review/extracted_cells/a64_glass_panel_upper_left_64.png | crop (64, 64, 128, 128); direct crop | mirror/glass floor plate |
| a64_glass_panel_upper_left_32 | A_771003 | (64, 64, 128, 128) | assets/art_sources/comfyui_real/mirror_city_v2_source_extraction_review/extracted_cells/a64_glass_panel_upper_left_32.png | crop (64, 64, 128, 128); downscaled/resized to 32x32 | mirror/glass floor plate |
| a64_mirror_plate_mid_left_64 | A_771003 | (128, 96, 192, 160) | assets/art_sources/comfyui_real/mirror_city_v2_source_extraction_review/extracted_cells/a64_mirror_plate_mid_left_64.png | crop (128, 96, 192, 160); direct crop | mirror plate material |
| a64_mirror_plate_mid_left_32 | A_771003 | (128, 96, 192, 160) | assets/art_sources/comfyui_real/mirror_city_v2_source_extraction_review/extracted_cells/a64_mirror_plate_mid_left_32.png | crop (128, 96, 192, 160); downscaled/resized to 32x32 | mirror plate material |
| a64_dark_label_sw_64 | A_771003 | (96, 352, 160, 416) | assets/art_sources/comfyui_real/mirror_city_v2_source_extraction_review/extracted_cells/a64_dark_label_sw_64.png | crop (96, 352, 160, 416); direct crop | dark label-safe tile |
| a64_dark_label_sw_32 | A_771003 | (96, 352, 160, 416) | assets/art_sources/comfyui_real/mirror_city_v2_source_extraction_review/extracted_cells/a64_dark_label_sw_32.png | crop (96, 352, 160, 416); downscaled/resized to 32x32 | dark label-safe tile |
| a64_central_reflection_knot_64 | A_771003 | (224, 224, 288, 288) | assets/art_sources/comfyui_real/mirror_city_v2_source_extraction_review/extracted_cells/a64_central_reflection_knot_64.png | crop (224, 224, 288, 288); direct crop | central reflection knot |
| a64_central_reflection_knot_32 | A_771003 | (224, 224, 288, 288) | assets/art_sources/comfyui_real/mirror_city_v2_source_extraction_review/extracted_cells/a64_central_reflection_knot_32.png | crop (224, 224, 288, 288); downscaled/resized to 32x32 | central reflection knot |
| a64_diagonal_route_nw_64 | A_771003 | (160, 160, 224, 224) | assets/art_sources/comfyui_real/mirror_city_v2_source_extraction_review/extracted_cells/a64_diagonal_route_nw_64.png | crop (160, 160, 224, 224); direct crop | route-like diagonal segment |
| a64_diagonal_route_nw_32 | A_771003 | (160, 160, 224, 224) | assets/art_sources/comfyui_real/mirror_city_v2_source_extraction_review/extracted_cells/a64_diagonal_route_nw_32.png | crop (160, 160, 224, 224); downscaled/resized to 32x32 | route-like diagonal segment |
| a64_diagonal_route_se_64 | A_771003 | (288, 288, 352, 352) | assets/art_sources/comfyui_real/mirror_city_v2_source_extraction_review/extracted_cells/a64_diagonal_route_se_64.png | crop (288, 288, 352, 352); direct crop | route-like diagonal segment |
| a64_diagonal_route_se_32 | A_771003 | (288, 288, 352, 352) | assets/art_sources/comfyui_real/mirror_city_v2_source_extraction_review/extracted_cells/a64_diagonal_route_se_32.png | crop (288, 288, 352, 352); downscaled/resized to 32x32 | route-like diagonal segment |
| a64_pale_vertical_panel_64 | A_771003 | (224, 128, 288, 192) | assets/art_sources/comfyui_real/mirror_city_v2_source_extraction_review/extracted_cells/a64_pale_vertical_panel_64.png | crop (224, 128, 288, 192); direct crop | pale glass panel |
| a64_pale_vertical_panel_32 | A_771003 | (224, 128, 288, 192) | assets/art_sources/comfyui_real/mirror_city_v2_source_extraction_review/extracted_cells/a64_pale_vertical_panel_32.png | crop (224, 128, 288, 192); downscaled/resized to 32x32 | pale glass panel |
| a64_fragment_corner_ne_64 | A_771003 | (352, 96, 416, 160) | assets/art_sources/comfyui_real/mirror_city_v2_source_extraction_review/extracted_cells/a64_fragment_corner_ne_64.png | crop (352, 96, 416, 160); direct crop | fractured reflection accent |
| a64_fragment_corner_ne_32 | A_771003 | (352, 96, 416, 160) | assets/art_sources/comfyui_real/mirror_city_v2_source_extraction_review/extracted_cells/a64_fragment_corner_ne_32.png | crop (352, 96, 416, 160); downscaled/resized to 32x32 | fractured reflection accent |
| a64_wall_edge_left_64 | A_771003 | (48, 192, 112, 256) | assets/art_sources/comfyui_real/mirror_city_v2_source_extraction_review/extracted_cells/a64_wall_edge_left_64.png | crop (48, 192, 112, 256); direct crop | mirror edge/wall hint |
| a64_wall_edge_left_32 | A_771003 | (48, 192, 112, 256) | assets/art_sources/comfyui_real/mirror_city_v2_source_extraction_review/extracted_cells/a64_wall_edge_left_32.png | crop (48, 192, 112, 256); downscaled/resized to 32x32 | mirror edge/wall hint |
| a64_symmetric_floor_center_64 | A_771003 | (192, 320, 256, 384) | assets/art_sources/comfyui_real/mirror_city_v2_source_extraction_review/extracted_cells/a64_symmetric_floor_center_64.png | crop (192, 320, 256, 384); direct crop | symmetric floor material |
| a64_symmetric_floor_center_32 | A_771003 | (192, 320, 256, 384) | assets/art_sources/comfyui_real/mirror_city_v2_source_extraction_review/extracted_cells/a64_symmetric_floor_center_32.png | crop (192, 320, 256, 384); downscaled/resized to 32x32 | symmetric floor material |
| b64_base_plate_01_64 | B_772002 | (32, 32, 96, 96) | assets/art_sources/comfyui_real/mirror_city_v2_source_extraction_review/extracted_cells/b64_base_plate_01_64.png | crop (32, 32, 96, 96); direct crop | dark mirror base tile |
| b64_base_plate_01_32 | B_772002 | (32, 32, 96, 96) | assets/art_sources/comfyui_real/mirror_city_v2_source_extraction_review/extracted_cells/b64_base_plate_01_32.png | crop (32, 32, 96, 96); downscaled/resized to 32x32 | dark mirror base tile |
| b64_base_plate_02_64 | B_772002 | (96, 32, 160, 96) | assets/art_sources/comfyui_real/mirror_city_v2_source_extraction_review/extracted_cells/b64_base_plate_02_64.png | crop (96, 32, 160, 96); direct crop | dark mirror base tile |
| b64_base_plate_02_32 | B_772002 | (96, 32, 160, 96) | assets/art_sources/comfyui_real/mirror_city_v2_source_extraction_review/extracted_cells/b64_base_plate_02_32.png | crop (96, 32, 160, 96); downscaled/resized to 32x32 | dark mirror base tile |
| b64_base_plate_03_64 | B_772002 | (160, 96, 224, 160) | assets/art_sources/comfyui_real/mirror_city_v2_source_extraction_review/extracted_cells/b64_base_plate_03_64.png | crop (160, 96, 224, 160); direct crop | dark mirror base tile |
| b64_base_plate_03_32 | B_772002 | (160, 96, 224, 160) | assets/art_sources/comfyui_real/mirror_city_v2_source_extraction_review/extracted_cells/b64_base_plate_03_32.png | crop (160, 96, 224, 160); downscaled/resized to 32x32 | dark mirror base tile |
| b64_base_plate_04_64 | B_772002 | (224, 160, 288, 224) | assets/art_sources/comfyui_real/mirror_city_v2_source_extraction_review/extracted_cells/b64_base_plate_04_64.png | crop (224, 160, 288, 224); direct crop | dark mirror base tile |
| b64_base_plate_04_32 | B_772002 | (224, 160, 288, 224) | assets/art_sources/comfyui_real/mirror_city_v2_source_extraction_review/extracted_cells/b64_base_plate_04_32.png | crop (224, 160, 288, 224); downscaled/resized to 32x32 | dark mirror base tile |
| b64_base_plate_05_64 | B_772002 | (288, 224, 352, 288) | assets/art_sources/comfyui_real/mirror_city_v2_source_extraction_review/extracted_cells/b64_base_plate_05_64.png | crop (288, 224, 352, 288); direct crop | dark mirror base tile |
| b64_base_plate_05_32 | B_772002 | (288, 224, 352, 288) | assets/art_sources/comfyui_real/mirror_city_v2_source_extraction_review/extracted_cells/b64_base_plate_05_32.png | crop (288, 224, 352, 288); downscaled/resized to 32x32 | dark mirror base tile |
| b64_base_plate_06_64 | B_772002 | (352, 288, 416, 352) | assets/art_sources/comfyui_real/mirror_city_v2_source_extraction_review/extracted_cells/b64_base_plate_06_64.png | crop (352, 288, 416, 352); direct crop | dark mirror base tile |
| b64_base_plate_06_32 | B_772002 | (352, 288, 416, 352) | assets/art_sources/comfyui_real/mirror_city_v2_source_extraction_review/extracted_cells/b64_base_plate_06_32.png | crop (352, 288, 416, 352); downscaled/resized to 32x32 | dark mirror base tile |
| a32_direct_center_knot | A_771003 | (240, 240, 272, 272) | assets/art_sources/comfyui_real/mirror_city_v2_source_extraction_review/extracted_cells/a32_direct_center_knot.png | crop (240, 240, 272, 272); direct crop | direct 32px center reflection probe |
| a32_direct_dark_tile | A_771003 | (96, 384, 128, 416) | assets/art_sources/comfyui_real/mirror_city_v2_source_extraction_review/extracted_cells/a32_direct_dark_tile.png | crop (96, 384, 128, 416); direct crop | direct 32px dark tile probe |
| a32_direct_edge | A_771003 | (48, 224, 80, 256) | assets/art_sources/comfyui_real/mirror_city_v2_source_extraction_review/extracted_cells/a32_direct_edge.png | crop (48, 224, 80, 256); direct crop | direct 32px edge probe |
| b32_direct_plate_01 | B_772002 | (48, 48, 80, 80) | assets/art_sources/comfyui_real/mirror_city_v2_source_extraction_review/extracted_cells/b32_direct_plate_01.png | crop (48, 48, 80, 80); direct crop | direct 32px base plate probe |
| b32_direct_plate_02 | B_772002 | (208, 208, 240, 240) | assets/art_sources/comfyui_real/mirror_city_v2_source_extraction_review/extracted_cells/b32_direct_plate_02.png | crop (208, 208, 240, 240); direct crop | direct 32px base plate probe |
| b32_direct_plate_03 | B_772002 | (336, 336, 368, 368) | assets/art_sources/comfyui_real/mirror_city_v2_source_extraction_review/extracted_cells/b32_direct_plate_03.png | crop (336, 336, 368, 368); direct crop | direct 32px base plate probe |

## 7. Candidate atlas review

| Candidate | Path | Source Mix | Review | Verdict |
| --- | --- | --- | --- | --- |
| V2 Candidate A | assets/art_sources/comfyui_real/mirror_city_v2_source_extraction_review/candidate_atlases/mirror_city_v2_candidate_a_pure_a_seed_extraction_atlas.png | Pure A-seed extraction | Strongest source identity, but repetition/noise and weak 32x32 tile safety. | Reject for import |
| V2 Candidate B | assets/art_sources/comfyui_real/mirror_city_v2_source_extraction_review/candidate_atlases/mirror_city_v2_candidate_b_a_b_hybrid_extraction_atlas.png | A+B extraction hybrid | Best V2 practical attempt, but still weaker than T7 at game scale. | Reference only |
| V2 Candidate C | Not created | Conservative/reference board not useful | C/D sources were layout/glyph-risk references, not atlas-safe. | Skipped |

## 8. Game-scale mockup review

| Mockup | Path | Readability | Beats T7? |
| --- | --- | --- | --- |
| Candidate A mockup | assets/art_sources/comfyui_real/mirror_city_v2_source_extraction_review/mockups/mirror_city_v2_candidate_a_game_scale_mockup.png | Readable enough for review; noisy and less crisp than T7. | No |
| Candidate B mockup | assets/art_sources/comfyui_real/mirror_city_v2_source_extraction_review/mockups/mirror_city_v2_candidate_b_game_scale_mockup.png | Best V2 game-scale result; base material works but route identity is weaker than T7. | No |

## 9. Comparison against current generated_v2 fallback and T7 production/procedural baseline

| Candidate | Path | Strengths | Recommendation |
| --- | --- | --- | --- |
| generated_v2 fallback | assets/generated_v2/tilesets/mirror_city_v2_prototype_tileset.png | Simple and readable; limited identity. | Keep fallback preserved |
| T7 production/procedural baseline | assets/production_art/tilesets/mirror_city/mirror_city_tileset.png | Crisp 32x32 grammar, stronger route/mirror language. | Keep active baseline |
| V2 Candidate A | assets/art_sources/comfyui_real/mirror_city_v2_source_extraction_review/candidate_atlases/mirror_city_v2_candidate_a_pure_a_seed_extraction_atlas.png | Better source texture identity than fallback, worse 32x32 control than T7. | Reference only |
| V2 Candidate B | assets/art_sources/comfyui_real/mirror_city_v2_source_extraction_review/candidate_atlases/mirror_city_v2_candidate_b_a_b_hybrid_extraction_atlas.png | More usable base extraction than A, still not an upgrade over T7. | Reference only |

Score table:

| Candidate | Mirror/Glass | Tile Readability | 32x32 Usability | Repetition | Label Readability | Route Clarity | V3 Compatibility | Improvement over T7 | Import Readiness | Verdict |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| current_generated_v2_fallback | 5 | 7 | 7 | 6 | 6 | 6 | 7 | 1 | 0 | preserved fallback, not the target winner |
| current_t7_procedural_baseline | 9 | 8 | 8 | 7 | 8 | 8 | 8 | 10 | 8 | keep active baseline |
| v2_candidate_a_pure_a_seed | 7 | 4 | 4 | 4 | 5 | 4 | 5 | 3 | 2 | interesting source, not tile-safe enough |
| v2_candidate_b_a_b_hybrid | 6 | 5 | 5 | 5 | 6 | 4 | 6 | 3 | 2 | best V2 extraction attempt, still weaker than T7 |

## 10. Honest visual verdict

The extracted V2 material does not clearly beat the current T7 Mirror City baseline. A seed 771003 has better organic mirror/glass source texture than T7, and B seed 772002 gives useful dark plate material, but both lose clarity when forced into 32x32 tiles. Candidate B is the best extraction attempt, but the T7 baseline remains more readable, more tile-safe, and more production-ready.

## 11. What is good

* A seed 771003 has the strongest Mirror City reflection identity.
* B seed 772002 can inform darker mirror-plate material.
* V2 mockups confirm some extracted material can sit under labels and V3 overlay samples.
* The V1 evidence bundle is complete enough for real ComfyUI source lineage.

## 12. What is risky

* 32x32 extraction from A becomes soft/noisy and loses deliberate route grammar.
* B is repetitive and lacks Mirror City navigation language.
* D includes glyph/text-like artifacts and was rejected for atlas use.
* C is too bright and grassy for direct Mirror City use.
* A production-ready result would require manual pixel-art reconstruction, which this phase did not do and must not pretend is already solved.

## 13. What is not done yet

* No production import.
* No runtime hook changes.
* No Godot scene edits.
* No new ComfyUI generation.
* No manual pixel cleanup or human-authored reconstruction.
* No live viewport validation of V2 artifacts.

## 14. Next best step

Keep the current T7 Mirror City baseline active. If continuing the real-art path, the next safest step is a second real ComfyUI source-generation prompt with tighter constraints: darker top-down tile atlas, no grass/outdoor language, no glyph/text motifs, stronger 32x32 tile boundaries, and less full-scene composition. A separate manual reconstruction phase could be considered later, but it should be labeled as manual/derived work, not raw ComfyUI extraction.

## 15. Protected path validation

Confirmed V2 wrote only under `assets/art_sources/comfyui_real/mirror_city_v2_source_extraction_review/` and `docs/art_pipeline/mirror_city_v2_real_comfyui_extraction_review.md`.

Protected-path status after V2:

```text
M scripts/asset_manager.gd
 M scripts/regions/late_revisit_hub.gd
?? assets/production_art/tilesets/fractured_wastes/fractured_wastes_tileset.png.import
?? assets/production_art/tilesets/ironhold/ironhold_tileset.png.import
?? assets/production_art/tilesets/mirror_city/
?? assets/production_art/tilesets/oakhaven/oakhaven_afternoon_tileset.png.import
?? assets/production_art/tilesets/oakhaven/oakhaven_morning_tileset.png.import
?? assets/production_art/tilesets/oakhaven/oakhaven_night_tileset.png.import
```

`git diff --check`:

```text
warning: in the working copy of 'AethelgardPrototype/docs/art_pipeline/art_replacement_manifest.md', CRLF will be replaced by LF the next time Git touches it
warning: in the working copy of 'AethelgardPrototype/scripts/asset_manager.gd', CRLF will be replaced by LF the next time Git touches it
```

Pre-existing dirty status before V2:

```text
D AGENT.md
 M docs/art_pipeline/art_replacement_manifest.md
 M scripts/asset_manager.gd
 M scripts/regions/late_revisit_hub.gd
?? AGENTS.md
?? assets/art_sources/comfyui_real/
?? assets/art_sources/comfyui_tests/fractured_wastes_r1/generated_tiles/fractured_wastes_r1_variant_a_clean.png.import
?? assets/art_sources/comfyui_tests/fractured_wastes_r1/generated_tiles/fractured_wastes_r1_variant_b_textured.png.import
?? assets/art_sources/comfyui_tests/fractured_wastes_r1/generated_tiles/fractured_wastes_r1_variant_c_corrupt_dark.png.import
?? assets/art_sources/comfyui_tests/fractured_wastes_r1/mockups/fractured_wastes_r1_variant_a_mockup.png.import
?? assets/art_sources/comfyui_tests/fractured_wastes_r1/mockups/fractured_wastes_r1_variant_a_mockup_2x.png.import
?? assets/art_sources/comfyui_tests/fractured_wastes_r1/mockups/fractured_wastes_r1_variant_b_mockup.png.import
?? assets/art_sources/comfyui_tests/fractured_wastes_r1/mockups/fractured_wastes_r1_variant_b_mockup_2x.png.import
?? assets/art_sources/comfyui_tests/fractured_wastes_r1/mockups/fractured_wastes_r1_variant_c_mockup.png.import
?? assets/art_sources/comfyui_tests/fractured_wastes_r1/mockups/fractured_wastes_r1_variant_c_mockup_2x.png.import
?? assets/art_sources/comfyui_tests/fractured_wastes_r1/review/fractured_wastes_r1_comparison_contact_sheet.png.import
?? assets/art_sources/comfyui_tests/fractured_wastes_r1/review/fractured_wastes_r1_fallback_tileset_reference.png.import
?? assets/art_sources/comfyui_tests/fractured_wastes_r1/review/fractured_wastes_r1_godot_variant_b_preview.png.import
?? assets/art_sources/comfyui_tests/fractured_wastes_r1/review/fractured_wastes_r1_variant_a_clean_2x.png.import
?? assets/art_sources/comfyui_tests/fractured_wastes_r1/review/fractured_wastes_r1_variant_b_textured_2x.png.import
?? assets/art_sources/comfyui_tests/fractured_wastes_r1/review/fractured_wastes_r1_variant_c_corrupt_dark_2x.png.import
?? assets/art_sources/comfyui_tests/fractured_wastes_r2_preview/contact_sheets/fractured_wastes_r2_actual_region_reference_contact_sheet.png.import
?? assets/art_sources/comfyui_tests/fractured_wastes_r2_preview/contact_sheets/fractured_wastes_r2_fallback_vs_variants_contact_sheet.png.import
?? assets/art_sources/comfyui_tests/fractured_wastes_r2_preview/mockups/fractured_wastes_r2_fallback_preview.png.import
?? assets/art_sources/comfyui_tests/fractured_wastes_r2_preview/mockups/fractured_wastes_r2_variant_a_preview.png.import
?? assets/art_sources/comfyui_tests/fractured_wastes_r2_preview/mockups/fractured_wastes_r2_variant_b_preview.png.import
?? assets/art_sources/comfyui_tests/fractured_wastes_r2_preview/mockups/fractured_wastes_r2_variant_c_preview.png.import
?? assets/art_sources/comfyui_tests/fractured_wastes_r2_preview/screenshots/fractured_wastes_r2_actual_region_farming_reference.png.import
?? assets/art_sources/comfyui_tests/fractured_wastes_r2_preview/screenshots/fractured_wastes_r2_actual_region_npc_reference.png.import
?? assets/art_sources/comfyui_tests/fractured_wastes_r2_preview/screenshots/fractured_wastes_r2_actual_region_path_reference.png.import
?? assets/art_sources/comfyui_tests/fractured_wastes_r2_preview/screenshots/fractured_wastes_r2_actual_region_reference.png.import
?? assets/art_sources/comfyui_tests/fractured_wastes_r2_preview/screenshots/fractured_wastes_r2_actual_region_spawn_reference.png.import
?? assets/art_sources/comfyui_tests/fractured_wastes_r2_preview/screenshots/fractured_wastes_r2_fallback_preview.png.import
?? assets/art_sources/comfyui_tests/fractured_wastes_r2_preview/screenshots/fractured_wastes_r2_variant_a_preview.png.import
?? assets/art_sources/comfyui_tests/fractured_wastes_r2_preview/screenshots/fractured_wastes_r2_variant_b_preview.png.import
?? assets/art_sources/comfyui_tests/fractured_wastes_r2_preview/screenshots/fractured_wastes_r2_variant_c_preview.png.import
?? assets/art_sources/comfyui_tests/fractured_wastes_r3_import_preview/contact_sheets/fractured_wastes_r3_actual_region_contact_sheet.png.import
?? assets/art_sources/comfyui_tests/fractured_wastes_r3_import_preview/contact_sheets/fractured_wastes_r3_fallback_vs_production_contact_sheet.png.import
?? assets/art_sources/comfyui_tests/fractured_wastes_r3_import_preview/mockups/fractured_wastes_r3_fallback_preview.png.import
?? assets/art_sources/comfyui_tests/fractured_wastes_r3_import_preview/mockups/fractured_wastes_r3_production_variant_b_preview.png.import
?? assets/art_sources/comfyui_tests/fractured_wastes_r3_import_preview/screenshots/fractured_wastes_r3_actual_region_fallback.png.import
?? assets/art_sources/comfyui_tests/fractured_wastes_r3_import_preview/screenshots/fractured_wastes_r3_actual_region_farming.png.import
?? assets/art_sources/comfyui_tests/fractured_wastes_r3_import_preview/screenshots/fractured_wastes_r3_actual_region_npc.png.import
?? assets/art_sources/comfyui_tests/fractured_wastes_r3_import_preview/screenshots/fractured_wastes_r3_actual_region_path.png.import
?? assets/art_sources/comfyui_tests/fractured_wastes_r3_import_preview/screenshots/fractured_wastes_r3_actual_region_production.png.import
?? assets/art_sources/comfyui_tests/fractured_wastes_r3_import_preview/screenshots/fractured_wastes_r3_actual_region_rift_or_core.png.import
?? assets/art_sources/comfyui_tests/fractured_wastes_r3_import_preview/screenshots/fractured_wastes_r3_actual_region_spawn.png.import
?? assets/art_sources/comfyui_tests/fractured_wastes_r3_import_preview/screenshots/fractured_wastes_r3_fallback_preview.png.import
?? assets/art_sources/comfyui_tests/fractured_wastes_r3_import_preview/screenshots/fractured_wastes_r3_production_variant_b_preview.png.import
?? assets/art_sources/comfyui_tests/ironhold_q1/generated_tiles/ironhold_q1_variant_a_clean.png.import
?? assets/art_sources/comfyui_tests/ironhold_q1/generated_tiles/ironhold_q1_variant_b_textured.png.import
?? assets/art_sources/comfyui_tests/ironhold_q1/generated_tiles/ironhold_q1_variant_c_ember_dark.png.import
?? assets/art_sources/comfyui_tests/ironhold_q1/mockups/ironhold_q1_variant_a_mockup.png.import
?? assets/art_sources/comfyui_tests/ironhold_q1/mockups/ironhold_q1_variant_a_mockup_2x.png.import
?? assets/art_sources/comfyui_tests/ironhold_q1/mockups/ironhold_q1_variant_b_mockup.png.import
?? assets/art_sources/comfyui_tests/ironhold_q1/mockups/ironhold_q1_variant_b_mockup_2x.png.import
?? assets/art_sources/comfyui_tests/ironhold_q1/mockups/ironhold_q1_variant_c_mockup.png.import
?? assets/art_sources/comfyui_tests/ironhold_q1/mockups/ironhold_q1_variant_c_mockup_2x.png.import
?? assets/art_sources/comfyui_tests/ironhold_q1/review/ironhold_q1_comparison_contact_sheet.png.import
?? assets/art_sources/comfyui_tests/ironhold_q1/review/ironhold_q1_variant_a_clean_2x.png.import
?? assets/art_sources/comfyui_tests/ironhold_q1/review/ironhold_q1_variant_b_textured_2x.png.import
?? assets/art_sources/comfyui_tests/ironhold_q1/review/ironhold_q1_variant_c_ember_dark_2x.png.import
?? assets/art_sources/comfyui_tests/ironhold_q2_preview/contact_sheets/ironhold_q2_fallback_vs_variants_contact_sheet.png.import
?? assets/art_sources/comfyui_tests/ironhold_q2_preview/screenshots/ironhold_q2_actual_region_reference.png.import
?? assets/art_sources/comfyui_tests/ironhold_q2_preview/screenshots/ironhold_q2_fallback_preview.png.import
?? assets/art_sources/comfyui_tests/ironhold_q2_preview/screenshots/ironhold_q2_variant_a_preview.png.import
?? assets/art_sources/comfyui_tests/ironhold_q2_preview/screenshots/ironhold_q2_variant_b_preview.png.import
?? assets/art_sources/comfyui_tests/ironhold_q2_preview/screenshots/ironhold_q2_variant_c_preview.png.import
?? assets/art_sources/comfyui_tests/ironhold_q3_import_preview/contact_sheets/ironhold_q3_fallback_vs_production_contact_sheet.png.import
?? assets/art_sources/comfyui_tests/ironhold_q3_import_preview/screenshots/ironhold_q3_actual_region_fallback.png.import
?? assets/art_sources/comfyui_tests/ironhold_q3_import_preview/screenshots/ironhold_q3_actual_region_production.png.import
?? assets/art_sources/comfyui_tests/ironhold_q3_import_preview/screenshots/ironhold_q3_fallback_preview.png.import
?? assets/art_sources/comfyui_tests/ironhold_q3_import_preview/screenshots/ironhold_q3_production_variant_b_preview.png.import
?? assets/art_sources/comfyui_tests/late_hubs_t1_audit/
?? assets/art_sources/comfyui_tests/late_hubs_t2_family_builder/
?? assets/art_sources/comfyui_tests/late_hubs_t3_preview_validation/
?? assets/art_sources/comfyui_tests/mirror_city_t4_identity_rebuild/
?? assets/art_sources/comfyui_tests/mirror_city_t5_preview_validation/
?? assets/art_sources/comfyui_tests/mirror_city_t6_actual_scene_staging_preview/
?? assets/art_sources/comfyui_tests/mirror_city_t7_controlled_import/
?? assets/art_sources/comfyui_tests/oakhaven_p10_palette_tuning/contact_sheets/oakhaven_p10_afternoon_tuned_2x.png.import
?? assets/art_sources/comfyui_tests/oakhaven_p10_palette_tuning/contact_sheets/oakhaven_p10_before_after_contact_sheet.png.import
?? assets/art_sources/comfyui_tests/oakhaven_p10_palette_tuning/contact_sheets/oakhaven_p10_fallback_vs_tuned_contact_sheet.png.import
?? assets/art_sources/comfyui_tests/oakhaven_p10_palette_tuning/contact_sheets/oakhaven_p10_godot_preview_validation_contact_sheet.png.import
?? assets/art_sources/comfyui_tests/oakhaven_p10_palette_tuning/contact_sheets/oakhaven_p10_morning_tuned_2x.png.import
?? assets/art_sources/comfyui_tests/oakhaven_p10_palette_tuning/contact_sheets/oakhaven_p10_night_tuned_2x.png.import
?? assets/art_sources/comfyui_tests/oakhaven_p10_palette_tuning/contact_sheets/oakhaven_p10_tuned_time_of_day_contact_sheet.png.import
?? assets/art_sources/comfyui_tests/oakhaven_p10_palette_tuning/mockups/oakhaven_p10_afternoon_mockup.png.import
?? assets/art_sources/comfyui_tests/oakhaven_p10_palette_tuning/mockups/oakhaven_p10_morning_mockup.png.import
?? assets/art_sources/comfyui_tests/oakhaven_p10_palette_tuning/mockups/oakhaven_p10_night_mockup.png.import
?? assets/art_sources/comfyui_tests/oakhaven_p10_palette_tuning/screenshots/oakhaven_p10_afternoon_preview.png.import
?? assets/art_sources/comfyui_tests/oakhaven_p10_palette_tuning/screenshots/oakhaven_p10_morning_preview.png.import
?? assets/art_sources/comfyui_tests/oakhaven_p10_palette_tuning/screenshots/oakhaven_p10_night_preview.png.import
?? assets/art_sources/comfyui_tests/oakhaven_p10_palette_tuning/tuned_atlases/oakhaven_p10_afternoon_tuned.png.import
?? assets/art_sources/comfyui_tests/oakhaven_p10_palette_tuning/tuned_atlases/oakhaven_p10_morning_tuned.png.import
?? assets/art_sources/comfyui_tests/oakhaven_p10_palette_tuning/tuned_atlases/oakhaven_p10_night_tuned.png.import
?? assets/art_sources/comfyui_tests/oakhaven_p11_import_preview/contact_sheets/oakhaven_p11_actual_scene_fallback_vs_afternoon.png.import
?? assets/art_sources/comfyui_tests/oakhaven_p11_import_preview/contact_sheets/oakhaven_p11_fallback_vs_production_contact_sheet.png.import
?? assets/art_sources/comfyui_tests/oakhaven_p11_import_preview/screenshots/oakhaven_p11_actual_afternoon_scene.png.import
?? assets/art_sources/comfyui_tests/oakhaven_p11_import_preview/screenshots/oakhaven_p11_actual_fallback_scene.png.import
?? assets/art_sources/comfyui_tests/oakhaven_p11_import_preview/screenshots/oakhaven_p11_afternoon_preview.png.import
?? assets/art_sources/comfyui_tests/oakhaven_p11_import_preview/screenshots/oakhaven_p11_fallback_preview.png.import
?? assets/art_sources/comfyui_tests/oakhaven_p11_import_preview/screenshots/oakhaven_p11_morning_preview.png.import
?? assets/art_sources/comfyui_tests/oakhaven_p11_import_preview/screenshots/oakhaven_p11_night_preview.png.import
?? assets/art_sources/comfyui_tests/oakhaven_p12_acceptance/contact_sheets/oakhaven_p12_fallback_vs_production_contact_sheet.png.import
?? assets/art_sources/comfyui_tests/oakhaven_p12_acceptance/screenshots/oakhaven_p12_fallback_center.png.import
?? assets/art_sources/comfyui_tests/oakhaven_p12_acceptance/screenshots/oakhaven_p12_production_center.png.import
?? assets/art_sources/comfyui_tests/oakhaven_p12_acceptance/screenshots/oakhaven_p12_production_exit_area.png.import
?? assets/art_sources/comfyui_tests/oakhaven_p12_acceptance/screenshots/oakhaven_p12_production_farming_area.png.import
?? assets/art_sources/comfyui_tests/oakhaven_p12_acceptance/screenshots/oakhaven_p12_production_npc_area.png.import
?? assets/art_sources/comfyui_tests/oakhaven_p12_acceptance/screenshots/oakhaven_p12_production_spawn.png.import
?? assets/art_sources/comfyui_tests/oakhaven_p7/downscale_tests/dirt_path_attempt2_crop_a_32x32.png.import
?? assets/art_sources/comfyui_tests/oakhaven_p7/downscale_tests/dirt_path_attempt2_crop_a_32x32_preview64.png.import
?? assets/art_sources/comfyui_tests/oakhaven_p7/downscale_tests/dirt_path_attempt2_crop_b_32x32.png.import
?? assets/art_sources/comfyui_tests/oakhaven_p7/downscale_tests/dirt_path_attempt2_crop_b_32x32_preview64.png.import
?? assets/art_sources/comfyui_tests/oakhaven_p7/downscale_tests/fence_hedge_attempt2_crop_a_32x32.png.import
?? assets/art_sources/comfyui_tests/oakhaven_p7/downscale_tests/fence_hedge_attempt2_crop_a_32x32_preview64.png.import
?? assets/art_sources/comfyui_tests/oakhaven_p7/downscale_tests/fence_hedge_attempt2_crop_b_32x32.png.import
?? assets/art_sources/comfyui_tests/oakhaven_p7/downscale_tests/fence_hedge_attempt2_crop_b_32x32_preview64.png.import
?? assets/art_sources/comfyui_tests/oakhaven_p7/downscale_tests/fence_hedge_attempt2_crop_c_32x32.png.import
?? assets/art_sources/comfyui_tests/oakhaven_p7/downscale_tests/fence_hedge_attempt2_crop_c_32x32_preview64.png.import
?? assets/art_sources/comfyui_tests/oakhaven_p7/downscale_tests/grass_terrain_attempt1_crop_32x32.png.import
?? assets/art_sources/comfyui_tests/oakhaven_p7/downscale_tests/grass_terrain_attempt1_crop_32x32_preview64.png.import
?? assets/art_sources/comfyui_tests/oakhaven_p7/downscale_tests/grass_terrain_attempt2_crop_32x32.png.import
?? assets/art_sources/comfyui_tests/oakhaven_p7/downscale_tests/grass_terrain_attempt2_crop_32x32_preview64.png.import
?? assets/art_sources/comfyui_tests/oakhaven_p7/downscale_tests/path_transitions_attempt1_crop_32x32.png.import
?? assets/art_sources/comfyui_tests/oakhaven_p7/downscale_tests/path_transitions_attempt1_crop_32x32_preview64.png.import
?? assets/art_sources/comfyui_tests/oakhaven_p7/downscale_tests/path_transitions_attempt2_crop_a_32x32.png.import
?? assets/art_sources/comfyui_tests/oakhaven_p7/downscale_tests/path_transitions_attempt2_crop_a_32x32_preview64.png.import
?? assets/art_sources/comfyui_tests/oakhaven_p7/downscale_tests/path_transitions_attempt2_crop_b_32x32.png.import
?? assets/art_sources/comfyui_tests/oakhaven_p7/downscale_tests/path_transitions_attempt2_crop_b_32x32_preview64.png.import
?? assets/art_sources/comfyui_tests/oakhaven_p7/downscale_tests/small_props_attempt1_crop_a_32x32.png.import
?? assets/art_sources/comfyui_tests/oakhaven_p7/downscale_tests/small_props_attempt1_crop_a_32x32_preview64.png.import
?? assets/art_sources/comfyui_tests/oakhaven_p7/downscale_tests/small_props_attempt1_crop_b_32x32.png.import
?? assets/art_sources/comfyui_tests/oakhaven_p7/downscale_tests/small_props_attempt1_crop_b_32x32_preview64.png.import
?? assets/art_sources/comfyui_tests/oakhaven_p7/extracted_cleaned/dirt_path_attempt2_crop_a_cleaned.png.import
?? assets/art_sources/comfyui_tests/oakhaven_p7/extracted_cleaned/dirt_path_attempt2_crop_b_cleaned.png.import
?? assets/art_sources/comfyui_tests/oakhaven_p7/extracted_cleaned/fence_hedge_attempt2_crop_a_cleaned.png.import
?? assets/art_sources/comfyui_tests/oakhaven_p7/extracted_cleaned/fence_hedge_attempt2_crop_b_cleaned.png.import
?? assets/art_sources/comfyui_tests/oakhaven_p7/extracted_cleaned/fence_hedge_attempt2_crop_c_cleaned.png.import
?? assets/art_sources/comfyui_tests/oakhaven_p7/extracted_cleaned/grass_terrain_attempt1_crop_cleaned.png.import
?? assets/art_sources/comfyui_tests/oakhaven_p7/extracted_cleaned/grass_terrain_attempt2_crop_cleaned.png.import
?? assets/art_sources/comfyui_tests/oakhaven_p7/extracted_cleaned/path_transitions_attempt1_crop_cleaned.png.import
?? assets/art_sources/comfyui_tests/oakhaven_p7/extracted_cleaned/path_transitions_attempt2_crop_a_cleaned.png.import
?? assets/art_sources/comfyui_tests/oakhaven_p7/extracted_cleaned/path_transitions_attempt2_crop_b_cleaned.png.import
?? assets/art_sources/comfyui_tests/oakhaven_p7/extracted_cleaned/small_props_attempt1_crop_a_cleaned.png.import
?? assets/art_sources/comfyui_tests/oakhaven_p7/extracted_cleaned/small_props_attempt1_crop_b_cleaned.png.import
?? assets/art_sources/comfyui_tests/oakhaven_p7/extracted_raw/dirt_path_attempt2_crop_a_raw.png.import
?? assets/art_sources/comfyui_tests/oakhaven_p7/extracted_raw/dirt_path_attempt2_crop_b_raw.png.import
?? assets/art_sources/comfyui_tests/oakhaven_p7/extracted_raw/fence_hedge_attempt2_crop_a_raw.png.import
?? assets/art_sources/comfyui_tests/oakhaven_p7/extracted_raw/fence_hedge_attempt2_crop_b_raw.png.import
?? assets/art_sources/comfyui_tests/oakhaven_p7/extracted_raw/fence_hedge_attempt2_crop_c_raw.png.import
?? assets/art_sources/comfyui_tests/oakhaven_p7/extracted_raw/grass_terrain_attempt1_crop_raw.png.import
?? assets/art_sources/comfyui_tests/oakhaven_p7/extracted_raw/grass_terrain_attempt2_crop_raw.png.import
?? assets/art_sources/comfyui_tests/oakhaven_p7/extracted_raw/path_transitions_attempt1_crop_raw.png.import
?? assets/art_sources/comfyui_tests/oakhaven_p7/extracted_raw/path_transitions_attempt2_crop_a_raw.png.import
?? assets/art_sources/comfyui_tests/oakhaven_p7/extracted_raw/path_transitions_attempt2_crop_b_raw.png.import
?? assets/art_sources/comfyui_tests/oakhaven_p7/extracted_raw/small_props_attempt1_crop_a_raw.png.import
?? assets/art_sources/comfyui_tests/oakhaven_p7/extracted_raw/small_props_attempt1_crop_b_raw.png.import
?? assets/art_sources/comfyui_tests/oakhaven_p7/oakhaven_p7_review_only_draft_atlas.png.import
?? assets/art_sources/comfyui_tests/oakhaven_p7/review/phase10mp7_cleaned_crops_contact_sheet.png.import
?? assets/art_sources/comfyui_tests/oakhaven_p7/review/phase10mp7_downscale_tests_contact_sheet.png.import
?? assets/art_sources/comfyui_tests/oakhaven_p7/review/phase10mp7_draft_atlas_review.png.import
?? assets/art_sources/comfyui_tests/oakhaven_p7/review/phase10mp7_p6_vs_p7_comparison.png.import
?? assets/art_sources/comfyui_tests/oakhaven_p7/review/phase10mp7_raw_crops_contact_sheet.png.import
?? assets/art_sources/comfyui_tests/oakhaven_p8/generated_tiles/oakhaven_p8_variant_a_clean.png.import
?? assets/art_sources/comfyui_tests/oakhaven_p8/generated_tiles/oakhaven_p8_variant_b_textured.png.import
?? assets/art_sources/comfyui_tests/oakhaven_p8/generated_tiles/oakhaven_p8_variant_c_dark_glitch.png.import
?? assets/art_sources/comfyui_tests/oakhaven_p8/mockups/oakhaven_p8_variant_a_mockup.png.import
?? assets/art_sources/comfyui_tests/oakhaven_p8/mockups/oakhaven_p8_variant_a_mockup_2x.png.import
?? assets/art_sources/comfyui_tests/oakhaven_p8/mockups/oakhaven_p8_variant_b_mockup.png.import
?? assets/art_sources/comfyui_tests/oakhaven_p8/mockups/oakhaven_p8_variant_b_mockup_2x.png.import
?? assets/art_sources/comfyui_tests/oakhaven_p8/mockups/oakhaven_p8_variant_c_mockup.png.import
?? assets/art_sources/comfyui_tests/oakhaven_p8/mockups/oakhaven_p8_variant_c_mockup_2x.png.import
?? assets/art_sources/comfyui_tests/oakhaven_p8/review/oakhaven_p8_comparison_contact_sheet.png.import
?? assets/art_sources/comfyui_tests/oakhaven_p8/review/oakhaven_p8_variant_a_clean_2x.png.import
?? assets/art_sources/comfyui_tests/oakhaven_p8/review/oakhaven_p8_variant_b_textured_2x.png.import
?? assets/art_sources/comfyui_tests/oakhaven_p8/review/oakhaven_p8_variant_c_dark_glitch_2x.png.import
?? assets/art_sources/comfyui_tests/oakhaven_p8/review/oakhaven_p8_variant_score_sheet.png.import
?? assets/art_sources/comfyui_tests/oakhaven_p9_time_preview/contact_sheets/oakhaven_p9_fallback_vs_time_preview_contact_sheet.png.import
?? assets/art_sources/comfyui_tests/oakhaven_p9_time_preview/contact_sheets/oakhaven_p9_time_of_day_contact_sheet.png.import
?? assets/art_sources/comfyui_tests/oakhaven_p9_time_preview/screenshots/oakhaven_p9_afternoon_preview.png.import
?? assets/art_sources/comfyui_tests/oakhaven_p9_time_preview/screenshots/oakhaven_p9_morning_preview.png.import
?? assets/art_sources/comfyui_tests/oakhaven_p9_time_preview/screenshots/oakhaven_p9_night_preview.png.import
?? assets/art_sources/comfyui_tests/shared_environment_s1/
?? assets/art_sources/comfyui_tests/shared_environment_s2_preview/
?? assets/art_sources/comfyui_tests/shared_environment_s3_prop_repair/
?? assets/art_sources/comfyui_tests/shared_environment_s4_v3_prop_audit/
?? assets/production_art/tilesets/fractured_wastes/fractured_wastes_tileset.png.import
?? assets/production_art/tilesets/ironhold/ironhold_tileset.png.import
?? assets/production_art/tilesets/mirror_city/
?? assets/production_art/tilesets/oakhaven/oakhaven_afternoon_tileset.png.import
?? assets/production_art/tilesets/oakhaven/oakhaven_morning_tileset.png.import
?? assets/production_art/tilesets/oakhaven/oakhaven_night_tileset.png.import
?? docs/art_pipeline/art_generation_truth_audit.md
?? docs/art_pipeline/comfyui_u2_1_e_drive_audit.json
?? docs/art_pipeline/comfyui_u2_1_e_drive_audit.md
?? docs/art_pipeline/comfyui_u2_2_launch_readiness_report.json
?? docs/art_pipeline/comfyui_u2_2_launch_readiness_report.md
?? docs/art_pipeline/comfyui_u2_environment_audit.json
?? docs/art_pipeline/comfyui_u2_environment_audit.md
?? docs/art_pipeline/fractured_wastes_r1_preview/capture_fractured_wastes_r1_preview.gd.uid
?? docs/art_pipeline/fractured_wastes_r1_preview/fractured_wastes_r1_validation.gd.uid
?? docs/art_pipeline/fractured_wastes_r2_preview/capture_fractured_wastes_r2_preview.gd.uid
?? docs/art_pipeline/fractured_wastes_r2_preview/fractured_wastes_r2_validation.gd.uid
?? docs/art_pipeline/fractured_wastes_r3_import_preview/asset_manager_fractured_wastes_r3_import_check.gd.uid
?? docs/art_pipeline/fractured_wastes_r3_import_preview/capture_fractured_wastes_r3_import_preview.gd.uid
?? docs/art_pipeline/fractured_wastes_r3_import_preview/fractured_wastes_r3_scene_load_check.gd.uid
?? docs/art_pipeline/ironhold_q1_preview/asset_manager_ironhold_q1_fallback_check.gd.uid
?? docs/art_pipeline/ironhold_q2_preview/asset_manager_ironhold_q2_fallback_check.gd.uid
?? docs/art_pipeline/ironhold_q2_preview/capture_ironhold_q2_preview.gd.uid
?? docs/art_pipeline/ironhold_q3_import_preview/asset_manager_ironhold_q3_import_check.gd.uid
?? docs/art_pipeline/ironhold_q3_import_preview/capture_ironhold_q3_import_preview.gd.uid
?? docs/art_pipeline/ironhold_q3_import_preview/ironhold_q3_scene_load_check.gd.uid
?? docs/art_pipeline/late_hubs_t1_validation.gd
?? docs/art_pipeline/late_hubs_t1_validation.gd.uid
?? docs/art_pipeline/late_hubs_t1_visual_baseline_audit.md
?? docs/art_pipeline/late_hubs_t2_family_builder_review.md
?? docs/art_pipeline/late_hubs_t3_preview_validation/
?? docs/art_pipeline/late_hubs_t3_preview_validation_review.md
?? docs/art_pipeline/mirror_city_t4_identity_rebuild_review.md
?? docs/art_pipeline/mirror_city_t5_preview_validation/
?? docs/art_pipeline/mirror_city_t5_preview_validation_review.md
?? docs/art_pipeline/mirror_city_t6_actual_scene_staging_preview/
?? docs/art_pipeline/mirror_city_t6_actual_scene_staging_preview_review.md
?? docs/art_pipeline/mirror_city_t7_controlled_import_validation/
?? docs/art_pipeline/mirror_city_t7_controlled_production_import_review.md
?? docs/art_pipeline/mirror_city_v1_real_comfyui_source_generation_review.md
?? docs/art_pipeline/mirror_city_v2_real_comfyui_extraction_review.md
?? docs/art_pipeline/oakhaven_p10_palette_tuning/asset_manager_fallback_check.gd.uid
?? docs/art_pipeline/oakhaven_p10_palette_tuning/validate_oakhaven_p10_preview.gd.uid
?? docs/art_pipeline/oakhaven_p11_import_preview/asset_manager_p11_import_check.gd.uid
?? docs/art_pipeline/oakhaven_p11_import_preview/capture_oakhaven_p11_actual_scene.gd.uid
?? docs/art_pipeline/oakhaven_p11_import_preview/capture_oakhaven_p11_actual_scene_simple.gd.uid
?? docs/art_pipeline/oakhaven_p11_import_preview/capture_oakhaven_p11_import_preview.gd.uid
?? docs/art_pipeline/oakhaven_p11_import_preview/probe_oakhaven_p11_actual_scene.gd.uid
?? docs/art_pipeline/oakhaven_p12_acceptance/asset_manager_p12_acceptance_check.gd.uid
?? docs/art_pipeline/oakhaven_p12_acceptance/capture_oakhaven_p12_acceptance.gd.uid
?? docs/art_pipeline/oakhaven_p7_preview/asset_manager_fallback_check.gd.uid
?? docs/art_pipeline/oakhaven_p8_preview/asset_manager_fallback_check.gd.uid
?? docs/art_pipeline/oakhaven_p8_preview/oakhaven_p8_preview_board.gd.uid
?? docs/art_pipeline/oakhaven_p9_time_preview/asset_manager_fallback_check.gd.uid
?? docs/art_pipeline/oakhaven_p9_time_preview/capture_oakhaven_p9_time_preview.gd.uid
?? docs/art_pipeline/real_comfyui_generation_requirements.md
?? docs/art_pipeline/shared_environment_s1/
?? docs/art_pipeline/shared_environment_s1_props_decals_review.md
?? docs/art_pipeline/shared_environment_s2_preview/
?? docs/art_pipeline/shared_environment_s2_preview_validation_review.md
?? docs/art_pipeline/shared_environment_s3_prop_repair/
?? docs/art_pipeline/shared_environment_s3_prop_repair_review.md
?? docs/art_pipeline/shared_environment_s4_v3_prop_audit/
?? docs/art_pipeline/shared_environment_s4_v3_prop_audit_review.md
?? docs/art_pipeline/shared_environment_v3_baseline_lock.md
```

## 16. Final decision

V2 source useful only as reference: keep current Mirror City baseline
