# Real ComfyUI Generation Requirements

Phase: 10M-U1 - Art pipeline truth reset and real ComfyUI requirement gate

Purpose: define the minimum evidence required before any future art phase may claim
that an asset is real ComfyUI-generated art.

## 1. Scope

These rules apply to every future phase that asks for real AI art, real ComfyUI art,
final-looking generated art, or production-bound generated art.

They do not prohibit deterministic tooling for:

- debug boards,
- layout tests,
- crop-contract tests,
- placeholder previews,
- runtime validation boards,
- comparison/contact sheets.

Deterministic procedural output must be labeled as procedural placeholder/debug/preview
evidence. It must not be described as real ComfyUI art or used to fake a production-art
source lineage.

## 2. Hard Gate

If real ComfyUI cannot be run, Codex must stop and report:

`ComfyUI unavailable`

Codex must not create fake procedural production art as a substitute for a requested
real ComfyUI generation phase.

## 3. Required Evidence Bundle

A future real ComfyUI phase must include all of the following:

| Required evidence | Requirement |
| --- | --- |
| `workflow_api.json` | The exact workflow API JSON submitted to ComfyUI. |
| Prompt JSON | The exact positive/negative prompt payload or prompt node JSON used for the run. |
| Checkpoint/model name | The checkpoint, model, LoRA, VAE, and other model references used. |
| Seed | The seed for each selected output. Randomized seeds must be captured after execution. |
| `prompt_id` | The prompt id returned by the ComfyUI `/prompt` call. |
| `/history` result or output metadata | Saved JSON from ComfyUI history or equivalent output metadata proving the run result. |
| Source output image path | The original ComfyUI output path before project copying, cropping, scaling, or editing. |
| Final copied project path | The project path where the selected output or derivative was copied. |
| Before/after contact sheet | Contact sheet comparing source output, any edits/crops, and final project candidate. |
| Manual edit statement | Explicit yes/no statement describing whether manual edit, crop, paintover, palette tuning, cleanup, or deterministic post-processing was used. |

If any required item is missing, the output must be classified as `unproven ComfyUI`
or `procedural/derived`, not real ComfyUI.

## 4. Required Folder Contract

Future real ComfyUI outputs should use this structure:

```text
assets/art_sources/comfyui_real/<phase>/
  workflow/
    workflow_api.json
  prompts/
    prompt.json
  outputs_raw/
    <original_comfyui_output_files>
  outputs_selected/
    <selected_source_files>
  manual_edits/
    <manual_or_post_processed_files_if_any>
  contact_sheets/
    <before_after_contact_sheets>
  manifest/
    <phase>_comfyui_manifest.json
```

Non-ComfyUI output should use separate folders such as:

```text
assets/art_sources/procedural_placeholders/<phase>/
assets/art_sources/runtime_validation/<phase>/
```

Do not create new non-ComfyUI phase outputs under `comfyui_tests`.

## 5. Required Manifest Fields

Each real ComfyUI phase manifest must include:

- `phase`
- `classification`: `real_comfyui`
- `comfyui_endpoint`
- `workflow_api_path`
- `prompt_json_path`
- `checkpoint_model`
- `loras`
- `vae`
- `sampler`
- `scheduler`
- `steps`
- `cfg`
- `width`
- `height`
- `seed`
- `prompt_id`
- `history_json_path`
- `source_output_image_path`
- `selected_output_path`
- `final_copied_project_path`
- `manual_edit_used`
- `manual_edit_notes`
- `before_after_contact_sheet_path`
- `license_or_source_notes`
- `accepted_for_review`
- `accepted_for_production_import`

## 6. Production Import Gate

Real ComfyUI generation and production import must be separate phases unless the user
explicitly requests a combined controlled import phase.

Before production import:

- source truth must be classified,
- review contact sheets must exist,
- fallback behavior must be preserved,
- generated_v2/generated_v3 must not be overwritten,
- accepted region baselines must not be touched,
- rollback instructions must be written,
- runtime validation must load the production asset and fallback asset safely.

A production import may use real ComfyUI art, deterministic placeholder art, or
human-authored art only if the report states that source truth clearly. It must not
imply real ComfyUI usage without the required evidence bundle.

## 7. Screenshot Evidence Gate

Deterministic boards are useful but are not live viewport proof.

A production acceptance report must distinguish:

- live Godot viewport screenshots,
- headless/dummy renderer screenshots,
- deterministic scene-composition boards,
- static contact sheets,
- crop-contract sheets.

If live viewport capture fails, the report must say so plainly. It must not describe
deterministic boards as live scene screenshots.

## 8. Failure Rules

Codex must stop and report `ComfyUI unavailable` when:

- the user specifically asks for real ComfyUI/AI art and ComfyUI cannot be reached,
- the ComfyUI executable/server/API is missing,
- the `/prompt` call cannot be made,
- the `/history` result cannot be retrieved,
- outputs cannot be proven to come from the recorded prompt/workflow.

Codex may still create procedural debug boards only if the user explicitly asks for
debug, layout, crop-contract, placeholder, or validation evidence and the output is
labeled accordingly.

## 9. Reporting Requirement

Every future art report must include:

- whether ComfyUI was actually used: Yes/No/Unproven,
- evidence paths,
- whether folder names are legacy/misleading,
- whether manual editing/post-processing was used,
- whether live viewport screenshot evidence exists,
- protected-path status,
- fallback/rollback status,
- final source-truth classification.

## 10. Decision Rule

If the required evidence bundle is complete, the phase may classify selected outputs
as real ComfyUI-generated art.

If the evidence bundle is incomplete, the phase must classify selected outputs as
unproven, procedural, derived, placeholder, or validation-only.

If real ComfyUI was requested but cannot be run, the correct decision is:

`ComfyUI unavailable`
