# ComfyUI Local Art Pipeline

Phase 10M-P status: local ComfyUI access and hardware were validated, but no test image was
generated because the local ComfyUI model list contains no checkpoint model. This file defines the
safe first workflow once an approved, non-infringing local model is installed.

## Local Paths

| Purpose | Path |
| --- | --- |
| ComfyUI install root | `E:\Comfy` |
| ComfyUI desktop executable | `E:\Comfy\ComfyUI\ComfyUI.exe` |
| ComfyUI Python | `E:\Comfy\.venv\Scripts\python.exe` |
| ComfyUI output directory | `E:\Comfy\output` |
| Godot project | `C:\Users\BHASKAR BAHUKHANDI\OneDrive\Desktop\Ultimate project\AethelgardPrototype` |
| Approved test intake root | `assets/art_sources/comfyui_tests/` |
| First Oakhaven test intake | `assets/art_sources/comfyui_tests/oakhaven_test/` |
| Runtime production slot, after approval only | `assets/production_art/tilesets/oakhaven_tileset.png` |

## Startup and API Notes

The desktop app launched successfully from `E:\Comfy\ComfyUI\ComfyUI.exe`. It did not bind to the
requested `8188` port in this environment. The active API/UI endpoint was:

```text
http://127.0.0.1:8000
```

Useful API probes:

```powershell
Invoke-RestMethod -Uri "http://127.0.0.1:8000/system_stats"
Invoke-RestMethod -Uri "http://127.0.0.1:8000/object_info/CheckpointLoaderSimple"
```

The second command must list at least one checkpoint before image generation can run.

## Hardware Findings

| Item | Value |
| --- | --- |
| GPU | NVIDIA GeForce RTX 2050 |
| VRAM | 4096 MiB total |
| Driver CUDA support | CUDA 13.2 reported by `nvidia-smi` |
| ComfyUI Python | Python 3.12.11 |
| PyTorch | 2.10.0+cu130 |
| Torch CUDA | available, CUDA 13.0 runtime |
| ComfyUI version | 0.22.2 |
| Launch mode | ComfyUI Desktop app with Python backend |
| Bound endpoint | `127.0.0.1:8000` |
| VRAM mode in log | `NORMAL_VRAM` |
| Dynamic VRAM | detected and enabled |

## RTX 2050 4GB Safe Settings

| Asset Type | Resolution | Batch | Model Type | Risk | Notes |
| --- | --- | --- | --- | --- | --- |
| Oakhaven tileset test | 512x512 | 1 | SD 1.5-class or similarly light checkpoint | Medium | Use 20-24 steps, CFG 5-7, one seed at a time. |
| Prop/icon test | 512x512 | 1 | SD 1.5-class or pixel-art tuned small model | Low/Medium | Safer than full sprite sheets. Transparent cleanup may be manual. |
| Character concept | 512x512 | 1 | SD 1.5-class | Medium | Good for concept pass, not final frame-grid sheets. |
| Sprite sheet | 512x512 or exact sheet size | 1 | Specialized sprite/pixel model | High | Expect row/frame drift. Validate before import. |
| Smooth animation sheet | Exact frame-grid sheets | 1 row at a time if needed | Specialized animation/sprite workflow | High | 4GB VRAM is not ideal; avoid video/AnimateDiff for production sheets. |
| SDXL generation | 512x512 or higher | 1 | SDXL | High | Likely slow or unstable on 4GB VRAM. Avoid for first pass. |

Avoid on this laptop:

- SDXL or Flux workflows as the first pass
- high-res fix, large batches, video generation, AnimateDiff, ControlNet stacks, multiple LoRAs
- 1024x1024 generation on 4GB VRAM unless intentionally CPU/offload slow
- generating sprite sheets directly into production without manual frame-grid validation

## Required Model Setup Checklist

No checkpoint model was available during Phase 10M-P. Before generation, install one approved local
checkpoint under:

```text
E:\Comfy\models\checkpoints\
```

Recommended first model class:

- small SD 1.5-compatible checkpoint or another lightweight checkpoint that ComfyUI can load through
  `CheckpointLoaderSimple`
- clear license/source page saved before use
- suitable for pixel art or game-art prompting
- not gated, not copied from a commercial game, and not an asset-pack redistribution without license

Optional later additions:

- a small pixel-art LoRA with clear license/source page
- a transparent/background-removal workflow after the base image workflow works
- ControlNet or tile guidance only after 512x512 batch-1 generation is stable

Do not start with:

- SDXL, Flux, video/animation models, large ControlNet stacks, or unknown-license checkpoints
- any model advertised primarily through copied commercial game styles

## First Oakhaven Test Workflow

Prompt:

```text
Original 2D top-down RPG pixel-art tileset sheet for Oakhaven, a warm dark-fantasy village touched
by subtle digital-glitch corruption. 512x512 PNG, exact 32x32 tile grid, reusable tiles only, no
preview map. Include low-noise meadow grass variants, dirt path centers and edges, natural path
turns, wood porch tiles, cottage wall-base and roof-shadow support tiles, fence bases, hedges,
flower clusters, herb patch support, small sign footing, cart footing, soft ground shadows, and a
few restrained glitch-corruption accent tiles. Cohesive palette, readable at Godot top-down scale,
clear terrain transitions, no text, no labels, no characters, no UI, no watermark, no copyrighted
or named-game style imitation.
```

Negative prompt:

```text
copyrighted game style, named franchise, pokemon, hollow knight, swordigo, zelda, commercial game
screenshot, isometric map, side-view platformer, scene preview, labels, text, watermark, logo,
characters, monsters, UI, dialogue box, collision markers, grid numbers, noisy grass, repeated
checkerboard, photorealistic, 3d render, blurry, muddy, giant single illustration, opaque props
that are not tiles
```

Workflow notes:

- Start with one 512x512 image only.
- Use batch size 1.
- Save raw ComfyUI output under `assets/art_sources/comfyui_tests/oakhaven_test/`.
- Do not copy anything to `assets/production_art/` until visual review and tile-grid validation pass.
- If the generated image is only a pretty mockup, classify it as concept art, not a production tileset.

## Workflow Naming

| File | Purpose |
| --- | --- |
| `docs/art_pipeline/comfyui_workflows/oakhaven_tileset_512_test_workflow.json.template` | API workflow skeleton for one 512x512 Oakhaven test. Replace the checkpoint name before running. |
| `assets/art_sources/comfyui_tests/oakhaven_test/source_record.md` | Record actual model, prompt, seed, size, and license once a test is generated. |

## Output Naming

Use this pattern for test outputs:

```text
assets/art_sources/comfyui_tests/oakhaven_test/oakhaven_tileset_test_<YYYYMMDD>_<seed>.png
```

If approved later, export a reviewed runtime PNG as:

```text
assets/production_art/tilesets/oakhaven_tileset.png
```

## Validation Checklist

Before an output can move from `art_sources` to `production_art`:

- source model and license/source page are documented
- no copyrighted style or named-game prompt reference was used
- PNG is 512x512 or a documented approved size
- the sheet aligns to a 32x32 tile grid
- tile cells are reusable, not a single baked scene
- no watermark, text, labels, characters, UI, or collision hints
- palette and scale fit current Kaelen/NPC sprite readability
- Godot boot and AssetManager fallback still pass
- generated fallback remains available if the production PNG is removed

## Production Approval Path

1. Generate one test image only.
2. Copy the raw output and source record to `assets/art_sources/comfyui_tests/oakhaven_test/`.
3. Create a preview/contact sheet in the same test folder.
4. Manually review whether it is a real tileset or just concept art.
5. If approved, copy a cleaned runtime export to `assets/production_art/tilesets/oakhaven_tileset.png`.
6. Run Godot boot, target-scene load, AssetManager production-slot check, and fallback check.

## Fallback Strategy

Production art is optional. If `assets/production_art/tilesets/oakhaven_tileset.png` is absent,
`AssetManager` warns and keeps the generated fallback alive. No ComfyUI test output should bypass
that fallback path.
