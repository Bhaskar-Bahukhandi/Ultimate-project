# Ironhold Production Tileset Candidate

This folder contains the controlled Ironhold production-art import candidate for Phase 10M-Q3.

## Current File

- `ironhold_tileset.png`: Ironhold Q1 Variant B textured atlas copied into the production-art pipeline as a reversible import candidate.
- `ironhold_production_manifest.json`: Source lineage, fallback path, atlas dimensions, and import notes.

## Lineage

- Q1 created deterministic Ironhold tileset variants using a strict 32x32 tile grammar.
- Q2 validated fallback, Variant A, Variant B, and Variant C in preview-only Godot screenshots.
- Q3 imports only Variant B textured into the Ironhold production-art slot for controlled loader and real-region validation.

## Fallback Behavior

The generated fallback remains available at:

`assets/generated_v2/tilesets/ironhold_v2_prototype_tileset.png`

Asset loading must fall back to the generated atlas if this production candidate is missing, invalid, or explicitly bypassed by a runtime fallback override.

## Status

Status: controlled import candidate.

This is not final release art. Do not delete the generated fallback assets.
