# PHASE 10M-V1 MIRROR CITY REAL COMFYUI SOURCE GENERATION REPORT

## 1. Summary

* AGENTS.md read: Yes
* ComfyUI endpoint: http://127.0.0.1:8000
* ComfyUI actually used: Yes
* `/prompt` called: Yes, 12 calls
* Images requested: 12
* Images generated: 12
* Workflow evidence saved: Yes, 12 workflow API JSON files
* History evidence saved: Yes, 12 `/history` JSON files
* Production art changed: No V1 production-art writes
* Generated_v2 overwritten: No
* Generated_v3 overwritten: No
* Scenes/scripts modified: No V1 scene/script writes
* Overall verdict: Real ComfyUI source evidence is complete, but the visual set is mixed. Four outputs are useful as source material; none should be imported directly.

## 2. Input / Environment Verification

| Check | Result | Notes |
| --- | --- | --- |
| endpoint reachable | Pass | http://127.0.0.1:8000 responded during generation. |
| nodes visible | Pass | CheckpointLoaderSimple, LoraLoader, KSampler, VAEDecode, SaveImage were visible. |
| checkpoint visible | Pass | v1-5-pruned-emaonly.safetensors |
| LoRA visible | Pass | sedatal_pixel_art_lora.safetensors |
| no production import | Pass | This phase did not import or write production art. |
| no protected path writes | Pass with pre-existing dirty caveat | V1 wrote only comfyui_real review evidence and the review doc. Existing dirty protected paths are listed in section 8. |

## 3. Workflow and Prompt Evidence

| Run | Seed | Prompt Family | Workflow Path | Prompt JSON Path | Prompt ID | History Path | Output Path | Status |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| mirror_city_v1_family_a_seed_771001 | 771001 | A - Mirror City tileset atlas | assets/art_sources/comfyui_real/mirror_city_v1_source_generation/workflow/mirror_city_v1_family_a_seed_771001_workflow_api.json | assets/art_sources/comfyui_real/mirror_city_v1_source_generation/prompts/mirror_city_v1_family_a_seed_771001_prompt.json | 4c356653-1bf3-4dd4-af06-2c7f2d849c37 | assets/art_sources/comfyui_real/mirror_city_v1_source_generation/diagnostics/mirror_city_v1_family_a_seed_771001_history.json | assets/art_sources/comfyui_real/mirror_city_v1_source_generation/outputs_raw/mirror_city_v1_family_a_seed_771001.png | generated |
| mirror_city_v1_family_a_seed_771002 | 771002 | A - Mirror City tileset atlas | assets/art_sources/comfyui_real/mirror_city_v1_source_generation/workflow/mirror_city_v1_family_a_seed_771002_workflow_api.json | assets/art_sources/comfyui_real/mirror_city_v1_source_generation/prompts/mirror_city_v1_family_a_seed_771002_prompt.json | 2bbf0a5f-5f7e-4255-9f3b-134dde813399 | assets/art_sources/comfyui_real/mirror_city_v1_source_generation/diagnostics/mirror_city_v1_family_a_seed_771002_history.json | assets/art_sources/comfyui_real/mirror_city_v1_source_generation/outputs_raw/mirror_city_v1_family_a_seed_771002.png | generated |
| mirror_city_v1_family_a_seed_771003 | 771003 | A - Mirror City tileset atlas | assets/art_sources/comfyui_real/mirror_city_v1_source_generation/workflow/mirror_city_v1_family_a_seed_771003_workflow_api.json | assets/art_sources/comfyui_real/mirror_city_v1_source_generation/prompts/mirror_city_v1_family_a_seed_771003_prompt.json | 48822a57-16f4-4c38-91ac-19b63419598b | assets/art_sources/comfyui_real/mirror_city_v1_source_generation/diagnostics/mirror_city_v1_family_a_seed_771003_history.json | assets/art_sources/comfyui_real/mirror_city_v1_source_generation/outputs_raw/mirror_city_v1_family_a_seed_771003.png | generated |
| mirror_city_v1_family_b_seed_772001 | 772001 | B - Fractured mirror route grammar | assets/art_sources/comfyui_real/mirror_city_v1_source_generation/workflow/mirror_city_v1_family_b_seed_772001_workflow_api.json | assets/art_sources/comfyui_real/mirror_city_v1_source_generation/prompts/mirror_city_v1_family_b_seed_772001_prompt.json | dc565499-b128-4056-82a1-7257b902de2a | assets/art_sources/comfyui_real/mirror_city_v1_source_generation/diagnostics/mirror_city_v1_family_b_seed_772001_history.json | assets/art_sources/comfyui_real/mirror_city_v1_source_generation/outputs_raw/mirror_city_v1_family_b_seed_772001.png | generated |
| mirror_city_v1_family_b_seed_772002 | 772002 | B - Fractured mirror route grammar | assets/art_sources/comfyui_real/mirror_city_v1_source_generation/workflow/mirror_city_v1_family_b_seed_772002_workflow_api.json | assets/art_sources/comfyui_real/mirror_city_v1_source_generation/prompts/mirror_city_v1_family_b_seed_772002_prompt.json | 41a2c398-31cb-402b-b59e-170e0ed54204 | assets/art_sources/comfyui_real/mirror_city_v1_source_generation/diagnostics/mirror_city_v1_family_b_seed_772002_history.json | assets/art_sources/comfyui_real/mirror_city_v1_source_generation/outputs_raw/mirror_city_v1_family_b_seed_772002.png | generated |
| mirror_city_v1_family_b_seed_772003 | 772003 | B - Fractured mirror route grammar | assets/art_sources/comfyui_real/mirror_city_v1_source_generation/workflow/mirror_city_v1_family_b_seed_772003_workflow_api.json | assets/art_sources/comfyui_real/mirror_city_v1_source_generation/prompts/mirror_city_v1_family_b_seed_772003_prompt.json | 32143189-014a-4ea2-ba89-6a7b3b32235d | assets/art_sources/comfyui_real/mirror_city_v1_source_generation/diagnostics/mirror_city_v1_family_b_seed_772003_history.json | assets/art_sources/comfyui_real/mirror_city_v1_source_generation/outputs_raw/mirror_city_v1_family_b_seed_772003.png | generated |
| mirror_city_v1_family_c_seed_773001 | 773001 | C - Inverted route / navigation mirrors | assets/art_sources/comfyui_real/mirror_city_v1_source_generation/workflow/mirror_city_v1_family_c_seed_773001_workflow_api.json | assets/art_sources/comfyui_real/mirror_city_v1_source_generation/prompts/mirror_city_v1_family_c_seed_773001_prompt.json | a8eaa36b-8adb-48b2-98c8-9cf12dd39d7b | assets/art_sources/comfyui_real/mirror_city_v1_source_generation/diagnostics/mirror_city_v1_family_c_seed_773001_history.json | assets/art_sources/comfyui_real/mirror_city_v1_source_generation/outputs_raw/mirror_city_v1_family_c_seed_773001.png | generated |
| mirror_city_v1_family_c_seed_773002 | 773002 | C - Inverted route / navigation mirrors | assets/art_sources/comfyui_real/mirror_city_v1_source_generation/workflow/mirror_city_v1_family_c_seed_773002_workflow_api.json | assets/art_sources/comfyui_real/mirror_city_v1_source_generation/prompts/mirror_city_v1_family_c_seed_773002_prompt.json | d95da0ad-8c5f-48e0-9d3f-f4e0f3185e5d | assets/art_sources/comfyui_real/mirror_city_v1_source_generation/diagnostics/mirror_city_v1_family_c_seed_773002_history.json | assets/art_sources/comfyui_real/mirror_city_v1_source_generation/outputs_raw/mirror_city_v1_family_c_seed_773002.png | generated |
| mirror_city_v1_family_c_seed_773003 | 773003 | C - Inverted route / navigation mirrors | assets/art_sources/comfyui_real/mirror_city_v1_source_generation/workflow/mirror_city_v1_family_c_seed_773003_workflow_api.json | assets/art_sources/comfyui_real/mirror_city_v1_source_generation/prompts/mirror_city_v1_family_c_seed_773003_prompt.json | 1f55eba6-a5c0-4a05-9be9-544b66ac19ec | assets/art_sources/comfyui_real/mirror_city_v1_source_generation/diagnostics/mirror_city_v1_family_c_seed_773003_history.json | assets/art_sources/comfyui_real/mirror_city_v1_source_generation/outputs_raw/mirror_city_v1_family_c_seed_773003.png | generated |
| mirror_city_v1_family_d_seed_774001 | 774001 | D - Practical hybrid candidate | assets/art_sources/comfyui_real/mirror_city_v1_source_generation/workflow/mirror_city_v1_family_d_seed_774001_workflow_api.json | assets/art_sources/comfyui_real/mirror_city_v1_source_generation/prompts/mirror_city_v1_family_d_seed_774001_prompt.json | 798a4a75-dda1-420e-8e26-0b782add3768 | assets/art_sources/comfyui_real/mirror_city_v1_source_generation/diagnostics/mirror_city_v1_family_d_seed_774001_history.json | assets/art_sources/comfyui_real/mirror_city_v1_source_generation/outputs_raw/mirror_city_v1_family_d_seed_774001.png | generated |
| mirror_city_v1_family_d_seed_774002 | 774002 | D - Practical hybrid candidate | assets/art_sources/comfyui_real/mirror_city_v1_source_generation/workflow/mirror_city_v1_family_d_seed_774002_workflow_api.json | assets/art_sources/comfyui_real/mirror_city_v1_source_generation/prompts/mirror_city_v1_family_d_seed_774002_prompt.json | 40e84cd1-a403-4d84-830b-bcaacda05ca1 | assets/art_sources/comfyui_real/mirror_city_v1_source_generation/diagnostics/mirror_city_v1_family_d_seed_774002_history.json | assets/art_sources/comfyui_real/mirror_city_v1_source_generation/outputs_raw/mirror_city_v1_family_d_seed_774002.png | generated |
| mirror_city_v1_family_d_seed_774003 | 774003 | D - Practical hybrid candidate | assets/art_sources/comfyui_real/mirror_city_v1_source_generation/workflow/mirror_city_v1_family_d_seed_774003_workflow_api.json | assets/art_sources/comfyui_real/mirror_city_v1_source_generation/prompts/mirror_city_v1_family_d_seed_774003_prompt.json | 12091c3d-da24-41ee-9263-92da5a4cc1ca | assets/art_sources/comfyui_real/mirror_city_v1_source_generation/diagnostics/mirror_city_v1_family_d_seed_774003_history.json | assets/art_sources/comfyui_real/mirror_city_v1_source_generation/outputs_raw/mirror_city_v1_family_d_seed_774003.png | generated |

## 4. Generated Outputs Review

| Output | Family | Seed | Mirror Identity | Tile Usefulness | Top-Down | Route Grammar | Noise Control | Extraction Potential | Overall | Keep/Reject |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| assets/art_sources/comfyui_real/mirror_city_v1_source_generation/outputs_raw/mirror_city_v1_family_a_seed_771001.png | A | 771001 | 2 | 4 | 6 | 3 | 5 | 3 | 3 | Reject |
| assets/art_sources/comfyui_real/mirror_city_v1_source_generation/outputs_raw/mirror_city_v1_family_a_seed_771002.png | A | 771002 | 3 | 5 | 6 | 4 | 5 | 4 | 4 | Reject |
| assets/art_sources/comfyui_real/mirror_city_v1_source_generation/outputs_raw/mirror_city_v1_family_a_seed_771003.png | A | 771003 | 8 | 6 | 7 | 6 | 7 | 7 | 7 | Keep |
| assets/art_sources/comfyui_real/mirror_city_v1_source_generation/outputs_raw/mirror_city_v1_family_b_seed_772001.png | B | 772001 | 4 | 3 | 4 | 2 | 2 | 2 | 2 | Reject |
| assets/art_sources/comfyui_real/mirror_city_v1_source_generation/outputs_raw/mirror_city_v1_family_b_seed_772002.png | B | 772002 | 6 | 7 | 7 | 3 | 7 | 7 | 6 | Keep |
| assets/art_sources/comfyui_real/mirror_city_v1_source_generation/outputs_raw/mirror_city_v1_family_b_seed_772003.png | B | 772003 | 3 | 4 | 5 | 3 | 5 | 3 | 3 | Reject |
| assets/art_sources/comfyui_real/mirror_city_v1_source_generation/outputs_raw/mirror_city_v1_family_c_seed_773001.png | C | 773001 | 3 | 6 | 8 | 7 | 6 | 5 | 5 | Keep |
| assets/art_sources/comfyui_real/mirror_city_v1_source_generation/outputs_raw/mirror_city_v1_family_c_seed_773002.png | C | 773002 | 3 | 5 | 6 | 6 | 5 | 4 | 4 | Reject |
| assets/art_sources/comfyui_real/mirror_city_v1_source_generation/outputs_raw/mirror_city_v1_family_c_seed_773003.png | C | 773003 | 1 | 2 | 5 | 3 | 4 | 1 | 1 | Reject |
| assets/art_sources/comfyui_real/mirror_city_v1_source_generation/outputs_raw/mirror_city_v1_family_d_seed_774001.png | D | 774001 | 4 | 5 | 5 | 4 | 3 | 4 | 4 | Reject |
| assets/art_sources/comfyui_real/mirror_city_v1_source_generation/outputs_raw/mirror_city_v1_family_d_seed_774002.png | D | 774002 | 6 | 5 | 6 | 6 | 4 | 5 | 5 | Keep |
| assets/art_sources/comfyui_real/mirror_city_v1_source_generation/outputs_raw/mirror_city_v1_family_d_seed_774003.png | D | 774003 | 2 | 5 | 5 | 3 | 5 | 3 | 3 | Reject |

## 5. Contact Sheets

| Sheet | Path | Status | Notes |
| --- | --- | --- | --- |
| All raw outputs | assets/art_sources/comfyui_real/mirror_city_v1_source_generation/contact_sheets/mirror_city_v1_all_raw_outputs_contact_sheet.png | Created | 12 real ComfyUI outputs. |
| Selected outputs | assets/art_sources/comfyui_real/mirror_city_v1_source_generation/contact_sheets/mirror_city_v1_selected_outputs_contact_sheet.png | Created | 4 conservative source selections. |
| Baseline vs selected | assets/art_sources/comfyui_real/mirror_city_v1_source_generation/contact_sheets/mirror_city_v1_procedural_baseline_vs_selected_contact_sheet.png | Created | Reference only; no production import. |

## 6. Selected Candidates

| Candidate | Source Output | Why Selected | Risk | Recommended Use |
| --- | --- | --- | --- | --- |
| mirror_city_v1_family_a_seed_771003 | assets/art_sources/comfyui_real/mirror_city_v1_source_generation/outputs_raw/mirror_city_v1_family_a_seed_771003.png | Best mirror/glass identity; strong symmetry, but needs extraction into clean 32x32 cells. | Requires extraction/polish; not production-ready. | Source extraction/review only. |
| mirror_city_v1_family_b_seed_772002 | assets/art_sources/comfyui_real/mirror_city_v1_source_generation/outputs_raw/mirror_city_v1_family_b_seed_772002.png | Useful dark mirror-plate base source; lacks route identity. | Requires extraction/polish; not production-ready. | Source extraction/review only. |
| mirror_city_v1_family_c_seed_773001 | assets/art_sources/comfyui_real/mirror_city_v1_source_generation/outputs_raw/mirror_city_v1_family_c_seed_773001.png | Readable route/plaza structure, but too bright and grassy for Mirror City. | Requires extraction/polish; not production-ready. | Source extraction/review only. |
| mirror_city_v1_family_d_seed_774002 | assets/art_sources/comfyui_real/mirror_city_v1_source_generation/outputs_raw/mirror_city_v1_family_d_seed_774002.png | Strong symmetry, but glyph/text-like artifacts make it risky. | Requires extraction/polish; not production-ready. | Source extraction/review only. |

## 7. Manual Editing / Post-processing Statement

* Manual editing used: No.
* Cropping used: No.
* Palette tuning used: No.
* Deterministic post-processing used: No output image post-processing was applied.
* Contact sheets were created only for review using Python/Pillow. Selected outputs were copied byte-for-byte from the raw copied project outputs.

## 8. Protected Path Check

Confirmed V1 did not intentionally write to:

* `assets/production_art`
* `assets/generated_v2`
* `assets/generated_v3`
* `scenes`
* `scripts`

Pre-existing dirty files reported by protected-path status:

```text
M scripts/asset_manager.gd
 M scripts/regions/late_revisit_hub.gd
?? assets/production_art/tilesets/mirror_city/
```

Full `git status --short` after V1:

```text
D AGENT.md
 M docs/art_pipeline/art_replacement_manifest.md
 M scripts/asset_manager.gd
 M scripts/regions/late_revisit_hub.gd
?? AGENTS.md
?? assets/art_sources/comfyui_real/
?? assets/art_sources/comfyui_tests/late_hubs_t1_audit/
?? assets/art_sources/comfyui_tests/late_hubs_t2_family_builder/
?? assets/art_sources/comfyui_tests/late_hubs_t3_preview_validation/
?? assets/art_sources/comfyui_tests/mirror_city_t4_identity_rebuild/
?? assets/art_sources/comfyui_tests/mirror_city_t5_preview_validation/
?? assets/art_sources/comfyui_tests/mirror_city_t6_actual_scene_staging_preview/
?? assets/art_sources/comfyui_tests/mirror_city_t7_controlled_import/
?? assets/art_sources/comfyui_tests/shared_environment_s1/
?? assets/art_sources/comfyui_tests/shared_environment_s2_preview/
?? assets/art_sources/comfyui_tests/shared_environment_s3_prop_repair/
?? assets/art_sources/comfyui_tests/shared_environment_s4_v3_prop_audit/
?? assets/production_art/tilesets/mirror_city/
?? docs/art_pipeline/art_generation_truth_audit.md
?? docs/art_pipeline/comfyui_u2_1_e_drive_audit.json
?? docs/art_pipeline/comfyui_u2_1_e_drive_audit.md
?? docs/art_pipeline/comfyui_u2_2_launch_readiness_report.json
?? docs/art_pipeline/comfyui_u2_2_launch_readiness_report.md
?? docs/art_pipeline/comfyui_u2_environment_audit.json
?? docs/art_pipeline/comfyui_u2_environment_audit.md
?? docs/art_pipeline/late_hubs_t1_validation.gd
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

## 9. Validation

`git diff --check` result:

```text
warning: in the working copy of 'AethelgardPrototype/docs/art_pipeline/art_replacement_manifest.md', CRLF will be replaced by LF the next time Git touches it
warning: in the working copy of 'AethelgardPrototype/scripts/asset_manager.gd', CRLF will be replaced by LF the next time Git touches it
```

## 10. Honest Visual Verdict

* Are the real ComfyUI outputs better than procedural Mirror City T4/T7? Not as finished runtime-ready art. A seed 771003 has better real mirror identity than most procedural evidence, but the generated set is less controlled than T4/T7.
* Are any outputs usable as source material? Yes. A 771003, B 772002, C 773001, and D 774002 are usable for extraction/review with clear caveats.
* Are any outputs close to production-ready? No. They need extraction, cleanup, tile grammar work, and artifact removal before any import discussion.
* Is another ComfyUI generation pass needed? Likely yes after extraction review, with tighter prompts against grass/outdoor drift and text/glyph artifacts.
* Should production import happen now? No.
* What should happen next? Run a review/extraction pass against the selected real ComfyUI outputs, then decide whether a second real ComfyUI generation pass is needed.

## 11. Decision

Real ComfyUI source candidates ready for extraction/review pass
