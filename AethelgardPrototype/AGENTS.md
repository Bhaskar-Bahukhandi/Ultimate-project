# AethelgardPrototype Agent Instructions

## Project
Godot 4.6 2D RPG project.

Project path:
C:\Users\BHASKAR BAHUKHANDI\OneDrive\Desktop\Ultimate project\AethelgardPrototype

Godot executable folder:
C:\Godot

Prefer the console Godot executable if present.

## Core Rules
- Do not make broad gameplay changes unless explicitly requested.
- Preserve fallback behavior for all production art imports.
- Do not overwrite production assets without a controlled import phase.
- Do not modify collision, hitboxes, combat, save/load schema, story progression, Source Key logic, true ending, NG+, or world-map/free-travel logic unless the prompt explicitly allows it.
- Do not touch accepted region baselines unless the prompt explicitly asks for preservation checks.
- Keep generated/review-only assets under assets/art_sources or docs/art_pipeline until production import is explicitly requested.
- Never claim production readiness without screenshot/test evidence.

## Validation Expectations
For Godot work:
- discover Godot executable under C:\Godot
- run Godot version check
- run project boot check
- run relevant scene-load checks
- run fallback/rollback checks for production-art imports
- run git diff --check
- report skipped tests honestly

## Reporting Expectations
Every phase report must include:
- summary
- files changed
- validation table
- fallback/rollback status if relevant
- honest visual or technical verdict
- exact next decision

## Art Pipeline Rules
- Use deterministic controlled builder passes before production import.
- For region art, follow:
  1. controlled grammar builder,
  2. preview-only Godot validation,
  3. controlled production import,
  4. actual scene acceptance.
- Oakhaven, Ironhold, and Fractured Wastes have accepted production baselines.
- Shared props/decals are still P0 improvement targets.

## Art Generation Truth Gate
- Folder names such as `comfyui_tests` are not proof that ComfyUI was used.
- Every future art report must explicitly state whether ComfyUI was actually used (`Yes`, `No`, or `Unproven`), source-truth classification, evidence paths, manual editing/post-processing status, live viewport screenshot status, fallback/rollback status, and protected-path status.
- Real ComfyUI art may only be claimed when the evidence bundle in `docs/art_pipeline/real_comfyui_generation_requirements.md` exists, including `workflow_api.json`, prompt JSON, checkpoint/model/LoRA/VAE details, seed, `prompt_id`, `/history` result or equivalent output metadata, original ComfyUI output path, copied project path, before/after contact sheet, and manual edit statement.
- If real ComfyUI or real AI art is requested but unavailable or unproven, stop and report exactly `ComfyUI unavailable`.
- Do not silently substitute deterministic Python/Pillow/Godot procedural art for requested real ComfyUI art.
- Deterministic procedural output is allowed only for debug boards, crop-contract tests, placeholder previews, runtime validation boards, or comparison sheets, and must be clearly labeled as procedural, placeholder, or validation-only.
- Real ComfyUI generation and production import should be separate phases unless the prompt explicitly requests a combined controlled import.
- Production import reports must distinguish live Godot viewport screenshots from headless/dummy renderer screenshots, deterministic boards, static contact sheets, and crop-contract sheets.
- Existing accepted baselines must not be replaced only because a new procedural candidate exists.
- Current truth state: Oakhaven has the strongest real ComfyUI lineage; Ironhold, Fractured Wastes, Mirror City T4-T7, late hubs T1-T3, and shared V3 props/decals do not currently have sufficient real ComfyUI evidence.
- Current V3 props/decals are locked as the active baseline unless a visible, specific issue justifies targeted repair. Mirror City T7, if present, is a controlled deterministic/procedural production baseline, not real ComfyUI art.
