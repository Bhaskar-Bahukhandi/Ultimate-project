# PHASE 10M-U2.1 COMFYUI E:\Comfy TARGETED RE-AUDIT REPORT

## 1. Summary

* AGENTS.md read: Yes
* `E:\Comfy` checked: Yes
* ComfyUI install found: Yes
* ComfyUI process running: No
* API reachable: No
* Models found: Yes
* Real generation readiness: Not ready until ComfyUI is manually launched and API/model loading is verified
* Final verdict: `ComfyUI installed but not running`

No art was generated. No `/prompt` call was made. No production import was run.

## 2. Why U2 Needed Recheck

U2 correctly reported `ComfyUI unavailable` for API availability because neither
`127.0.0.1:8188` nor `127.0.0.1:8000` was reachable. U2 checked common C-drive and
user-folder locations but did not clearly verify the historical `E:\Comfy` path.

U2.1 explicitly checked `E:\Comfy`, the historical model folders, the expected
checkpoint `v1-5-pruned-emaonly.safetensors`, the expected LoRA
`sedatal_pixel_art_lora.safetensors`, launch candidates, processes, ports, and safe
metadata endpoints.

## 3. E-Drive Install Discovery

| Path | Exists | ComfyUI Indicator Found | Notes |
| --- | --- | --- | --- |
| `E:\Comfy` | Yes | No | Root exists; appears to be a ComfyUI Desktop install root. |
| `E:\Comfy\ComfyUI` | Yes | Yes | Contains ComfyUI.exe and resources. |
| `E:\Comfy\ComfyUI_windows_portable` | No | No | Portable folder not present. |
| `E:\Comfy\models` | Yes | Yes | Model root exists. |
| `E:\Comfy\models\checkpoints` | Yes | Yes | Checkpoint folder exists; expected checkpoint found. |
| `E:\Comfy\models\loras` | Yes | Yes | LoRA folder exists; expected pixel-art LoRA found. |
| `E:\Comfy\output` | Yes | Yes | Output folder exists; not used in this audit. |
| `E:\Comfy\custom_nodes` | Yes | Yes | Folder exists; child count was 0 in targeted check. |
| `E:\Comfy\user` | Yes | Yes | User folder exists. |
| `E:\Comfy\ComfyUI\models` | No | No | Models are at E:\Comfy\models instead. |
| `E:\Comfy\ComfyUI\models\checkpoints` | No | No | Models are at E:\Comfy\models\checkpoints instead. |
| `E:\Comfy\ComfyUI\models\loras` | No | No | Models are at E:\Comfy\models\loras instead. |
| `E:\Comfy\ComfyUI\output` | No | No | Output is at E:\Comfy\output instead. |
| `E:\Comfy\ComfyUI\custom_nodes` | No | No | Custom nodes are at E:\Comfy\custom_nodes instead. |

Shallow E-drive discovery found `E:\Comfy` only as the relevant top-level ComfyUI-like
folder. A first exploratory shallow command had a PowerShell regex escaping issue, then
the targeted checks above were rerun with literal paths and succeeded.

## 4. Launch Script / Python Environment Check

| Candidate | Path | Exists | Safe Manual Launch Command | Notes |
| --- | --- | --- | --- | --- |
| ComfyUI Desktop executable | `E:\Comfy\ComfyUI\ComfyUI.exe` | Yes | `& "E:\Comfy\ComfyUI\ComfyUI.exe"` | Preferred manual launch for this Desktop-style install. Not launched by Codex. |
| ComfyUI main.py through detected venv | `E:\Comfy\ComfyUI\resources\ComfyUI\main.py` | Yes | `Set-Location "E:\Comfy\ComfyUI\resources\ComfyUI"; & "E:\Comfy\.venv\Scripts\python.exe" "main.py" --listen 127.0.0.1 --port 8000` | Manual CLI candidate. Model-path behavior was not validated because the server was not launched. |
| Detected virtualenv Python | `E:\Comfy\.venv\Scripts\python.exe` | Yes | `Used by the manual main.py command above.` | Python executable exists and is readable. |
| run_nvidia_gpu.bat | `E:\Comfy\run_nvidia_gpu.bat` | No | `` | No batch launcher at this path. |
| run_cpu.bat | `E:\Comfy\run_cpu.bat` | No | `` | No batch launcher at this path. |
| portable run_nvidia_gpu.bat | `E:\Comfy\ComfyUI_windows_portable\run_nvidia_gpu.bat` | No | `` | Portable folder not present. |

Codex did not launch ComfyUI because this phase is audit/readiness-only and a server would
be long-running. Launch must be manual, then this audit should be rerun.

## 5. Model Readiness

| Type | File | Path | Size | Likely Usable | Notes |
| --- | --- | --- | --- | --- | --- |
| Checkpoint | `v1-5-pruned-emaonly.safetensors` | `E:\Comfy\models\checkpoints\v1-5-pruned-emaonly.safetensors` | 4,265,146,304 bytes / 4067.56 MiB | Yes | Expected SD 1.5 checkpoint from historical Oakhaven P6 lineage; readable. |
| LoRA | `sedatal_pixel_art_lora.safetensors` | `E:\Comfy\models\loras\sedatal_pixel_art_lora.safetensors` | 3,226,184 bytes / 3.08 MiB | Likely | Expected pixel-art LoRA from historical Oakhaven P6 lineage; readable. Actual compatibility still requires API/model-load validation after launch. |

No models were downloaded. Model folders were read-only inspected.

## 6. API / Process Check

| Check | Result | Notes |
| --- | --- | --- |
| `Process check` | Not running | No Python/ComfyUI/conda/uv process related to ComfyUI was listed. |
| `Port 8188` | No listener | `netstat` found no listener on port 8188. |
| `Port 8000` | No listener | `netstat` found no listener on port 8000. |
| `http://127.0.0.1:8188/system_stats` | Unreachable | Unable to connect to the remote server. |
| `http://127.0.0.1:8188/object_info` | Unreachable | Unable to connect to the remote server. |
| `http://127.0.0.1:8188/history` | Unreachable | Unable to connect to the remote server. |
| `http://127.0.0.1:8000/system_stats` | Unreachable | Unable to connect to the remote server. |
| `http://127.0.0.1:8000/object_info` | Unreachable | Unable to connect to the remote server. |
| `http://127.0.0.1:8000/history` | Unreachable | Unable to connect to the remote server. |
| `/prompt` | Not called | No generation prompt was queued. |

## 7. Existing Evidence Bundle Audit

| Evidence Item | Status | Path / Notes |
| --- | --- | --- |
| workflow_api.json | Missing | No submitted `workflow_api.json` found in Oakhaven P6 or workflow folders. |
| prompt JSON | Template only / partial historical | `docs/art_pipeline/comfyui_workflows/oakhaven_tileset_512_test_workflow.json.template` contains prompt text but is not a submitted prompt JSON/evidence bundle. |
| checkpoint/model/LoRA/VAE | Partially verified | Checkpoint and LoRA exist at `E:\Comfy\models`; VAE not specifically proven; API model-load not validated because server is not running. |
| seed | Partial historical | Oakhaven P6 source records and manifests include seeds such as `610001` through `660002`. |
| prompt_id | Missing | No `prompt_id` evidence found for Oakhaven P6. |
| history JSON | Missing | No `/history` result JSON found; API history endpoint unreachable. |
| original ComfyUI output path | Missing/incomplete | Oakhaven P6 records raw project paths, not a proven original external ComfyUI output path. |
| selected output path | Partial historical | `assets/art_sources/comfyui_tests/oakhaven_p6/phase10mp6_candidate_manifest.json` lists selected crop outputs. |
| copied project path | Partial historical | Oakhaven P6 raw/review/candidate paths exist under `assets/art_sources/comfyui_tests/oakhaven_p6/`. |
| before/after contact sheet | Partial historical | P6 has `phase10mp6_all_outputs_contact_sheet.png` and `phase10mp6_candidate_contact_sheet.png`. |
| manual edit statement | Partial historical | P7 states extraction and light cleanup were used; P8 states deterministic construction. No complete real-ComfyUI manual edit bundle exists. |

Evidence classification: partial historical evidence for Oakhaven P6, template only for the
workflow folder, and missing for a complete current real ComfyUI evidence bundle.

## 8. Project Lineage Truth Update

| Family | Previous U2 Classification | U2.1 Update | Action |
| --- | --- | --- | --- |
| Oakhaven | Partial historical ComfyUI lineage; current path unavailable in U2. | E:\Comfy install and expected models now found, but API is not running and evidence bundle remains incomplete. | Launch ComfyUI manually, rerun audit, then use a separate real source-generation prompt if API passes. |
| Ironhold | No sufficient real ComfyUI evidence; controlled procedural production baseline. | Unchanged. E:\Comfy does not retroactively prove Ironhold was ComfyUI-generated. | Do not relabel. Replace only in later evidence-backed phase. |
| Fractured Wastes | No sufficient real ComfyUI evidence; controlled procedural production baseline. | Unchanged. E:\Comfy does not retroactively prove Fractured Wastes was ComfyUI-generated. | Do not relabel. Replace only in later evidence-backed phase. |
| Mirror City T4-T7 | No real ComfyUI evidence; T7 is controlled deterministic/procedural baseline. | Unchanged. E:\Comfy presence does not change T4-T7 source truth. | Future Mirror City real-art pass requires new ComfyUI generation with evidence. |
| late hubs T1-T3 | Review-only/procedural/validation artifacts. | Unchanged. No late-hub ComfyUI evidence bundle found. | Do not promote or relabel. |
| shared V3 props/decals | Active generated_v3 baseline; no real ComfyUI evidence. | Unchanged. V3 remains locked active baseline unless targeted repair is justified. | Do not touch unless specific visible issue is proven. |

## 9. Protected Path Check

U2.1 wrote only:

* `docs/art_pipeline/comfyui_u2_1_e_drive_audit.md`
* `docs/art_pipeline/comfyui_u2_1_e_drive_audit.json`

No U2.1 changes were made to:

* `assets/production_art`
* `assets/generated_v2`
* `assets/generated_v3`
* `scenes`
* `scripts`

Pre-existing dirty files/folders must be reported separately after validation. They are not
U2.1 edits.

## 10. Validation

Required validation after writing this report:

* `git diff --check`

Warnings and pre-existing dirty files are reported in the final chat response.

## 11. Honest Verdict

* Is ComfyUI installed? Yes. `E:\Comfy` exists and contains a Desktop-style install with
  `E:\Comfy\ComfyUI\ComfyUI.exe`, `.venv`, model folders, user/output folders, and a
  ComfyUI `main.py` under resources.
* Is it running? No.
* Is the API reachable? No. Safe metadata probes on `8188` and `8000` failed.
* Are models present? Yes. The expected SD1.5 checkpoint and pixel-art LoRA are present and readable.
* Is it ready for a future real ComfyUI source-generation phase? Not yet. It must be launched,
  API reachability must be confirmed, and a future generation phase must capture the required
  evidence bundle.
* What do I need to manually do next? Launch ComfyUI manually, then rerun this audit.

Final verdict: `ComfyUI installed but not running`

## 12. Next Best Step

Launch ComfyUI manually with the Desktop executable:

```powershell
& "E:\Comfy\ComfyUI\ComfyUI.exe"
```

After it is running, rerun this audit and verify `http://127.0.0.1:8188` or
`http://127.0.0.1:8000` safe metadata endpoints before any source-generation prompt.

Alternative manual CLI candidate, if the Desktop app is not suitable:

```powershell
Set-Location "E:\Comfy\ComfyUI\resources\ComfyUI"
& "E:\Comfy\.venv\Scripts\python.exe" "main.py" --listen 127.0.0.1 --port 8000
```

The CLI command was not executed and its model-path behavior was not validated in U2.1.
