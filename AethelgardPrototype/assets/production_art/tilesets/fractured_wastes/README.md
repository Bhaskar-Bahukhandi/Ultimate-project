# Fractured Wastes Production Tileset

This folder contains the Phase 10M-R3 controlled production-art import candidate for the Fractured Wastes region.

- Production atlas: `fractured_wastes_tileset.png`
- Source: `assets/art_sources/comfyui_tests/fractured_wastes_r1/generated_tiles/fractured_wastes_r1_variant_b_textured.png`
- Status: controlled import candidate / first baseline candidate
- Tile size: 32x32
- Atlas size: 512x512
- Grid: 16x16

Lineage:

- Phase 10M-R1 created deterministic Fractured Wastes variants A/B/C.
- Phase 10M-R2 validated those variants in a preview-only Godot board and selected Variant B textured as the best import candidate.
- Phase 10M-R3 stages Variant B in production_art with generated fallback preserved.

This is controlled deterministic generated art, not final release art. Do not delete the generated fallback at `assets/generated_v2/tilesets/fractured_wastes_v2_prototype_tileset.png`; AssetManager must be able to roll back to it if this production slot is missing, invalid, or manually overridden.
