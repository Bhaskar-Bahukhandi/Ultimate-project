# PHASE 10M-U2.2 COMFYUI LAUNCH + API READINESS REPORT

## 1. Summary

* AGENTS.md read: Yes
* ComfyUI launch attempted: Yes
* Launch command used: `Start-Process -FilePath "E:\Comfy\ComfyUI\ComfyUI.exe" -WorkingDirectory "E:\Comfy\ComfyUI" -WindowStyle Hidden -PassThru`
* Process running: Yes
* API reachable: Yes
* Successful endpoint: `http://127.0.0.1:8000`
* Checkpoint visible: Yes
* LoRA visible: Yes
* `/prompt` called: No
* Art generated: No
* Final verdict: `ComfyUI environment verified for future source-generation phase`

This phase verified readiness only. No images were generated and no production import was run.

## 2. Launch Log

| Step | Command / Endpoint | Result | Notes |
| --- | --- | --- | --- |
| Read truth-gate docs | `AGENTS.md and U2/U2.1 docs` | Pass | Art Generation Truth Gate followed; no procedural substitution allowed. |
| Desktop launch | `Start-Process -FilePath "E:\Comfy\ComfyUI\ComfyUI.exe" -WorkingDirectory "E:\Comfy\ComfyUI" -WindowStyle Hidden -PassThru` | Started | Desktop process started; initial PID reported as 31372. |
| Poll 8188 | `http://127.0.0.1:8188/system_stats` | Unreachable | Repeated safe metadata probes failed on 8188. |
| Poll 8000 | `http://127.0.0.1:8000/system_stats` | Reachable | Port 8000 became reachable after desktop launch; status 200. |
| CLI fallback | `Start-Process -FilePath "E:\Comfy\.venv\Scripts\python.exe" ...` | Not attempted | Not needed because Desktop launch exposed API on 8000. |
| No prompt | `/prompt` | Not called | No generation prompt was queued. |

## 3. Process / Port Check

| Check | Result | Notes |
| --- | --- | --- |
| process list result | Running | Multiple ComfyUI.exe processes were listed under E:\Comfy\ComfyUI\ComfyUI.exe; python processes included the API listener. |
| port 8188 | No listener verified | Safe probes to 8188 failed during launch polling. |
| port 8000 | Listening | `netstat` showed 127.0.0.1:8000 LISTENING with PID 1744 after launch. |

Observed process details included ComfyUI Desktop processes under `E:\Comfy\ComfyUI\ComfyUI.exe`
and Python processes, including the listener on `127.0.0.1:8000`.

## 4. API Metadata Check

| Endpoint | Reachable | Response Summary | Notes |
| --- | --- | --- | --- |
| `http://127.0.0.1:8000/system_stats` | Yes | HTTP 200, 1463 bytes | Returned system metadata including ComfyUI version 0.22.2. |
| `http://127.0.0.1:8000/object_info` | Yes | HTTP 200, 1,179,418 bytes | Returned node metadata; required nodes and model filenames were visible. |
| `http://127.0.0.1:8000/history` | Yes | HTTP 200, 2 bytes | Returned `{}`; no generation history was created by this phase. |

No `/prompt` request was made.

## 5. Node / Model Readiness

| Item | Visible / Found | Notes |
| --- | --- | --- |
| `CheckpointLoaderSimple` | Yes | Visible in `/object_info`. |
| `LoraLoader` | Yes | Visible in `/object_info`. |
| `KSampler` | Yes | Visible in `/object_info`. |
| `VAEDecode` | Yes | Visible in `/object_info`. |
| `SaveImage` | Yes | Visible in `/object_info`. |
| `v1-5-pruned-emaonly.safetensors` | Yes | Exact filename found in `/object_info`; local file exists under E:\Comfy\models\checkpoints. |
| `sedatal_pixel_art_lora.safetensors` | Yes | Exact filename found in `/object_info`; local file exists under E:\Comfy\models\loras. |

## 6. Evidence Bundle Readiness

Future real ComfyUI generation can now collect the required evidence bundle, provided the
future phase saves it explicitly.

| Evidence Item | Readiness | Notes |
| --- | --- | --- |
| workflow API JSON | Can be collected in future generation phase | Do not generate in U2.2; save submitted workflow when a future real source-generation prompt runs. |
| prompt JSON | Can be collected in future generation phase | Future prompt must save exact positive/negative prompt payload. |
| checkpoint/LoRA model names | Ready | `v1-5-pruned-emaonly.safetensors` and `sedatal_pixel_art_lora.safetensors` are visible through API metadata. |
| seed | Can be collected in future generation phase | Future workflow must record selected/randomized seed after execution. |
| prompt_id | Can be collected in future generation phase | Requires a future `/prompt` call; not called in U2.2. |
| /history result | Can be collected in future generation phase | `/history` is reachable now and returned `{}` before generation. |
| original output path | Can be collected in future generation phase | Future generation must record original ComfyUI output path. |
| selected output path | Can be collected in future generation phase | Future review phase must record selected outputs. |
| before/after contact sheet | Can be created after future generation | Allowed only as evidence after actual source outputs exist. |
| manual edit statement | Required in future generation/report | Future report must state whether manual edits/post-processing were used. |

U2.2 itself did not create a generation evidence bundle because no generation was requested
or performed.

## 7. Protected Path Check

U2.2 wrote only:

* `docs/art_pipeline/comfyui_u2_2_launch_readiness_report.md`
* `docs/art_pipeline/comfyui_u2_2_launch_readiness_report.json`

No U2.2 changes were made to:

* `assets/production_art`
* `assets/generated_v2`
* `assets/generated_v3`
* `scenes`
* `scripts`

Pre-existing dirty files/folders are reported separately after validation.

## 8. Validation

Required validation after writing this report:

* `git diff --check`

Warnings and pre-existing dirty files are reported in the final chat response.

## 9. Honest Verdict

* Did Codex successfully launch ComfyUI? Yes.
* Is the API reachable? Yes, at `http://127.0.0.1:8000`.
* Are the required SD1.5 checkpoint and pixel-art LoRA visible? Yes.
* Is the environment ready for a future real ComfyUI source-generation phase? Yes, for a
  separate future phase that records the required evidence bundle.
* What should happen next? Run a separate real ComfyUI source-generation prompt. Do not import
  art in that phase unless explicitly requested as a separate controlled import.

Final verdict: `ComfyUI environment verified for future source-generation phase`

## 10. Next Best Step

Use a separate real ComfyUI source-generation phase prompt. That phase should:

* submit a workflow through ComfyUI,
* save `workflow_api.json` and prompt JSON,
* record checkpoint/LoRA names, seed, `prompt_id`, and `/history`,
* save original ComfyUI output paths and copied project paths,
* create review contact sheets only after outputs exist,
* include a manual edit/post-processing statement,
* avoid production import unless a later controlled import phase explicitly requests it.
