# Oakhaven ComfyUI Test Source Record

Phase: 10M-P3

Status: generated as a local test only. Do not promote to `assets/production_art/`.

| Field | Value |
| --- | --- |
| Tool | ComfyUI local |
| ComfyUI endpoint | `http://127.0.0.1:8000` |
| Model name | Stable Diffusion v1-5, ema-only inference checkpoint |
| Model filename | `v1-5-pruned-emaonly.safetensors` |
| Model file path | `E:\Comfy\models\checkpoints\v1-5-pruned-emaonly.safetensors` |
| Model source URL | `https://huggingface.co/stable-diffusion-v1-5/stable-diffusion-v1-5` |
| Model file URL | `https://huggingface.co/stable-diffusion-v1-5/stable-diffusion-v1-5/blob/main/v1-5-pruned-emaonly.safetensors` |
| License | `creativeml-openrail-m` as listed on the Hugging Face model card |
| Model SHA-256 | `6CE0161689B3853ACAA03779EC93EAFE75A02F4CED659BEE03F50797806FA2FA` |
| Download date | 2026-05-24 |
| Prompt ID | `bcd31b8e-219e-49fd-a91f-d671802006c6` |
| Seed | `1001001` |
| Sampler | `euler` |
| Scheduler | `normal` |
| Steps | `22` |
| CFG | `6.0` |
| Resolution | `512x512` |
| Batch size | `1` |
| Output file | `assets/art_sources/comfyui_tests/oakhaven_test/oakhaven_tileset_test_20260524_seed1001001.png` |
| Output SHA-256 | `464B725E9294123B11D93F39D9517DF0B5A9B6B2F0026874D4AA952B00A4849A` |
| Contact sheet | `assets/art_sources/comfyui_tests/oakhaven_test/oakhaven_tileset_test_20260524_seed1001001_contact_sheet.png` |
| Contact sheet SHA-256 | `04EA449C01BACFB53E7AFCC8FF10FBA72BFFB2685E193CA4E7E43DA628FB6ED5` |

## Prompt

```text
Original top-down RPG pixel-art tileset for Oakhaven village, 32x32 tile grid, 512x512 PNG sheet, meadow grass tiles, dirt path tiles, path edge transitions, cottage wall base tiles, wooden fence tiles, hedge tiles, flowers, herb patch, wooden sign, soft shadows, subtle dark fantasy mood, faint digital-glitch accent details, clean readable tiles, game asset sheet, transparent or simple flat background where appropriate, no characters, no UI, no watermark, no text.
```

## Negative Prompt

```text
copyrighted game style, named franchise, Pokemon, Hollow Knight, Swordigo, Zelda, Undertale, Stardew Valley, UI screenshot, map screenshot, characters, text, watermark, logo, signature, 3D render, realistic photo, messy collage, broken grid, unreadable tiles, collision markers, random letters, blurry, low quality, deformed, excessive noise.
```

## Review Notes

- The output is a valid 512x512 PNG and no runtime production-art slot was overwritten.
- The image is not a production-ready tileset. It reads more like a blocky map/concept plate than
  discrete reusable 32x32 terrain tiles.
- The negative prompt included named game references supplied in the Phase 10M-P3 request. Future
  runs should remove named games from both positive and negative prompts to fully satisfy the
  no-copyrighted-name prompt rule.
- Keep this output in `assets/art_sources/comfyui_tests/oakhaven_test/` only.

