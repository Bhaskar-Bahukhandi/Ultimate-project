# PHASE 10M-U2 REAL COMFYUI ENVIRONMENT + EVIDENCE AUDIT

## 1. Summary

- ComfyUI actually available: No
- Can Codex safely generate real ComfyUI art right now: No
- Final exact availability verdict: `ComfyUI unavailable`
- Generation performed: No
- Import performed: No
- Deterministic replacement art created: No

This is an audit-only result. Historical Oakhaven P6 records provide the strongest
project lineage for prior ComfyUI use, but this audit did not verify a current usable
ComfyUI environment or a complete modern evidence bundle.

## 2. AGENTS.md Compliance

`AGENTS.md` was read before the audit. The followed Art Generation Truth Gate rules include:

- Folder names such as `comfyui_tests` are not proof that ComfyUI was used.
- Future art reports must state whether ComfyUI was actually used, source-truth
  classification, evidence paths, manual editing/post-processing status, live viewport
  screenshot status, fallback/rollback status, and protected-path status.
- Real ComfyUI art may only be claimed when the required evidence bundle exists.
- If real ComfyUI is requested but unavailable or unproven, stop and report exactly
  `ComfyUI unavailable`.
- Do not silently substitute deterministic Python/Pillow/Godot procedural art for
  requested real ComfyUI art.

No art was generated, no import was run, and no gameplay files were modified.

## 3. Local ComfyUI Discovery

### Explicit paths checked

| Path | Install found |
| --- | --- |
| `C:\Users\BHASKAR BAHUKHANDI\ComfyUI` | No |
| `C:\Users\BHASKAR BAHUKHANDI\ComfyUI_windows_portable` | No |
| `C:\Users\BHASKAR BAHUKHANDI\Desktop\ComfyUI` | No |
| `C:\Users\BHASKAR BAHUKHANDI\Desktop\ComfyUI_windows_portable` | No |
| `C:\Users\BHASKAR BAHUKHANDI\Documents\ComfyUI` | No |
| `C:\Users\BHASKAR BAHUKHANDI\Downloads\ComfyUI` | No |
| `C:\ComfyUI` | No |
| `C:\ComfyUI_windows_portable` | No |
| `C:\AI\ComfyUI` | No |
| `C:\Users\BHASKAR BAHUKHANDI\OneDrive\Desktop\Ultimate project\ComfyUI` | No |
| `C:\Users\BHASKAR BAHUKHANDI\OneDrive\Desktop\Ultimate project\ComfyUI_windows_portable` | No |

### Targeted recursive discovery

Targeted searches under Desktop, Documents, Downloads, the project parent, and the project
found only:

- `assets/art_sources/comfyui_tests/` - legacy project evidence/output folder, not an install.
- `docs/art_pipeline/comfyui_workflows/` - contains one workflow template, not a runnable install.

No ComfyUI install folder was found.

### Python/venv evidence

- Running process check found no Python/ComfyUI/conda/uv process related to ComfyUI.
- No ComfyUI `venv`, `python_embeded`, or install-local Python environment was found in
  targeted ComfyUI paths.

### Launch scripts

No ComfyUI launch scripts were found in the targeted audit paths:

- `main.py`
- `run_nvidia_gpu.bat`
- `run_cpu.bat`
- `run_comfyui.bat`
- `webui-user.bat` in a ComfyUI-related path

### Custom nodes/models folders

No ComfyUI `models`, `custom_nodes`, or `output` directories were found in a verified install.

## 4. API Reachability

No generation prompt was queued. Only safe metadata/history endpoints were probed.

| Endpoint | Reachable | Result |
| --- | --- | --- |
| `http://127.0.0.1:8188/system_stats` | No | Unable to connect to the remote server |
| `http://127.0.0.1:8188/object_info` | No | Unable to connect to the remote server |
| `http://127.0.0.1:8188/history` | No | Unable to connect to the remote server |
| `http://127.0.0.1:8000/system_stats` | No | Unable to connect to the remote server |
| `http://127.0.0.1:8000/object_info` | No | Unable to connect to the remote server |
| `http://127.0.0.1:8000/history` | No | Unable to connect to the remote server |

`netstat` showed no listener on ports `8188` or `8000`.

## 5. Evidence Bundle Audit

| Required evidence | Status | Notes |
| --- | --- | --- |
| `workflow_api.json` | Missing | No submitted `workflow_api.json` found. Only `docs/art_pipeline/comfyui_workflows/oakhaven_tileset_512_test_workflow.json.template` exists. |
| Prompt JSON | Missing/incomplete | The template contains prompt text, but no submitted prompt JSON bundle was found for a current run. |
| Checkpoint/model/LoRA/VAE | Partial historical | Oakhaven P6 docs record `v1-5-pruned-emaonly.safetensors` and `sedatal_pixel_art_lora.safetensors`; no complete current model folder or VAE evidence found. |
| Seed | Partial historical | Oakhaven P6 source records and manifest include seeds such as `610001`; other audited families lack real ComfyUI seed bundles. |
| `prompt_id` | Missing | No prompt id evidence found outside policy docs describing the requirement. |
| `/history` result or output metadata | Missing | No ComfyUI history JSON/result found. API `/history` was unreachable. |
| Original ComfyUI output path | Missing/incomplete | Oakhaven P6 records project raw output paths, but no original external ComfyUI output folder/path was proven. |
| Copied project path | Partial historical | Oakhaven P6 raw/review paths exist in `assets/art_sources/comfyui_tests/oakhaven_p6/`. |
| Before/after contact sheet | Partial historical | Oakhaven P6 has `phase10mp6_all_outputs_contact_sheet.png`; other families do not have real ComfyUI before/after evidence. |
| Manual edit/post-processing statement | Partial historical | P7/P8 docs discuss extraction/cleanup/deterministic building; no complete current real-ComfyUI manual edit statement bundle found. |

Conclusion: no complete evidence bundle exists for a current real ComfyUI generation path.

## 6. Project Lineage Truth Table

| Family | Claimed/source folder | Real ComfyUI evidence found? | Procedural/deterministic evidence? | Production baseline status | Trust level | Action |
| --- | --- | --- | --- | --- | --- | --- |
| Oakhaven | `assets/art_sources/comfyui_tests/oakhaven_p6 plus later Oakhaven P7-P12 docs` | Partial historical P6 evidence: endpoint/checkpoint/LoRA, seeds, raw output paths, source records, contact sheet. No reachable current API and no complete workflow_api/prompt_id/history bundle found. | Yes. P7 extraction/cleanup and P8-P10 controlled builder/tuning phases include deterministic or derived review work. | Accepted Oakhaven afternoon production baseline remains in production_art. | Strongest real ComfyUI lineage in project, but current generation path unavailable. | Keep accepted baseline. Future real-art work must rerun ComfyUI with the required evidence bundle. |
| Ironhold | `assets/art_sources/comfyui_tests/ironhold_q1 and Q2/Q3 outputs` | No | Yes. Q1 reports deterministic Pillow builder; Q2/Q3 are preview/import validation. | Accepted production baseline exists. | Controlled procedural baseline, not real ComfyUI. | Do not relabel as ComfyUI. Replace only in a later real-art or human-authored phase with evidence. |
| Fractured Wastes | `assets/art_sources/comfyui_tests/fractured_wastes_r1 and R2/R3 outputs` | No | Yes. R1 reports deterministic Pillow atlas/mockup generation; R2/R3 are validation/import phases. | Accepted production baseline exists. | Controlled procedural baseline, not real ComfyUI. | Do not relabel as ComfyUI. Replace only in a later real-art or human-authored phase with evidence. |
| Mirror City T4-T7 | `assets/art_sources/comfyui_tests/mirror_city_t4_identity_rebuild through mirror_city_t7_controlled_import` | No | Yes. T4 manifest says deterministic Python/Pillow and comfyui_used false; T7 report says no real ComfyUI usage was found. | T7 controlled deterministic/procedural production baseline present if mirror_city production slot exists. | Controlled procedural production baseline, not real ComfyUI. | Future Mirror City real-art pass requires a new ComfyUI source-generation phase after ComfyUI is installed/launched. |
| Late hubs T1-T3 | `assets/art_sources/comfyui_tests/late_hubs_t1_audit through late_hubs_t3_preview_validation` | No | Yes. T1 is audit/copy evidence; T2 manifest says deterministic controlled Python/Pillow; T3 is preview validation. | Review-only; no production import. | Placeholder/validation only. | Do not promote or label as ComfyUI. Restart with real evidence if real AI art is requested. |
| Shared V3 props/decals | `assets/generated_v3 plus shared_environment S1-S5 review folders` | No | Yes. S3 manifest says deterministic Python/Pillow and no_comfyui true. | Current generated_v3 prop/decal atlases are locked active baseline. | Active generated baseline, not real ComfyUI. | Do not touch unless a specific visible issue justifies targeted repair. |

## 7. Protected Path Check

U2 wrote only:

- `docs/art_pipeline/comfyui_u2_environment_audit.md`
- `docs/art_pipeline/comfyui_u2_environment_audit.json`

Protected path status for this phase:

| Path | U2 changed? | Notes |
| --- | --- | --- |
| `assets/production_art` | No | Pre-existing untracked Mirror City production folder remains from prior T7 work. U2 did not touch it. |
| `assets/generated_v2` | No | No U2 changes. |
| `assets/generated_v3` | No | No U2 changes. |
| `scenes` | No | No U2 changes. |
| `scripts` | No | Pre-existing modified `scripts/asset_manager.gd` and `scripts/regions/late_revisit_hub.gd` remain from prior work. U2 did not touch them. |

## 8. Validation

Required validation after writing this report:

- `git diff --check`: run after report creation.
- Pre-existing dirty files are reported separately in the final chat response and should not
  be confused with U2 changes.
- Warnings must not be hidden.

## 9. Honest Verdict

`ComfyUI unavailable`

Reason: no reachable ComfyUI API was found, no local ComfyUI install was found in targeted
common locations, and no complete evidence bundle exists for a current generation path.
Historical Oakhaven P6 evidence is useful lineage evidence, but it is not enough to prove
that Codex can safely generate real ComfyUI art right now.

## 10. Next Best Step

Install or launch ComfyUI manually first, then rerun this audit. The next recommended prompt
type is a separate real ComfyUI environment verification/source-generation readiness prompt,
not an art generation or production import prompt.
