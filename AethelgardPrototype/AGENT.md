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