# Phase 10M-P5 Model Source Record

Status: one pixel-art LoRA downloaded and detected by local ComfyUI. No production art was changed.

## Selected Candidate

| Field | Value |
| --- | --- |
| Model / LoRA name | `SedatAl/pixel-art-LoRa` |
| Downloaded file | `sedatal_pixel_art_lora.safetensors` |
| Original repository filename | `pytorch_lora_weights.safetensors` |
| Source URL | `https://huggingface.co/SedatAl/pixel-art-LoRa` |
| File URL | `https://huggingface.co/SedatAl/pixel-art-LoRa/blob/main/pytorch_lora_weights.safetensors` |
| License | `creativeml-openrail-m` as listed on the Hugging Face model/file page |
| File size | `3,226,184` bytes |
| SHA-256 | `AD5034703699E910D5F9525EA5DB64ABCBD8D7396FF8F771C09403F3ADB048AD` |
| Download date | 2026-05-24 |
| Local file path | `E:\Comfy\models\loras\sedatal_pixel_art_lora.safetensors` |
| ComfyUI endpoint | `http://127.0.0.1:8000` |
| Base checkpoint expected | `v1-5-pruned-emaonly.safetensors` |
| ComfyUI detection | Detected by `LoraLoader` after restart |

## Intended Use

- Controlled local ComfyUI experiments for Oakhaven pixel-art tile-family generation.
- Batch size 1, `512x512`, no high-res fix, no ControlNet, no upscaler, no production import.
- Use only original prompts with no copyrighted names, franchise references, or living-artist style imitation.

## Limitations

- This is a general pixel-art LoRA, not a proven RPG tileset-specific model.
- It does not guarantee reusable `32x32` cells.
- Outputs must remain under `assets/art_sources/comfyui_tests/` until manually reviewed.
- Any later production-art import still requires separate approval and Godot validation.

