# Variant B - Fractured Reflection Layout

- Atlas path: `assets/art_sources/comfyui_tests/mirror_city_t4_identity_rebuild/generated_tiles/mirror_city_t4_variant_b_fractured_reflection.png`
- Dimensions: 512x512 RGBA
- Cell size: 32x32
- Grid: 16x16
- Intended use: Mirror City floor/wrapper/path candidate for review only.
- Collision implication: visual-only / no collision implication.
- Label-safe tile notes: Rows 9 and 14 plus R0 C14-C15 are low-noise dark tiles for labels and prompts.
- Glow intensity notes: cyan/magenta glow cells are intentionally local and non-blinding.
- Mirror City identity: Broken mirror district, fractured self-reflection, shard paths, still readable.

## Row / Cell Coordinate Map

| Range | Tile Names / Intended Use |
|---|---|
| R0 C0-C15 | dark mirror floor bases; C14-C15 label-safe dark surfaces |
| R1 C0-C15 | glass plate floor variations and low-noise grid variants |
| R2 C0-C15 | straight, vertical, cross, T, corner, and paired path route tiles |
| R3 C0-C15 | mirrored/reversed route arrows and symmetry path helpers |
| R4 C0-C15 | mirror wall/floor edge pieces and civic wrapper borders |
| R5 C0-C15 | corner transitions, diagonal glass seams, shadowed edge support |
| R6 C0-C15 | primary variant motifs |
| R7 C0-C15 | secondary variant motifs and inverted motifs |
| R8 C0-C15 | restrained cyan/magenta glow support cells |
| R9 C0-C15 | dark label-safe floor tiles and non-reflective surfaces |
| R10 C0-C15 | route markers, warning/reflection marker cells |
| R11 C0-C15 | fracture, ghost reflection, and mirror streak cells |
| R12 C0-C15 | repeat-safe floor and route stress-test cells |
| R13 C0-C15 | hybrid edge/detail cells for wrapper grammar |
| R14 C0-C15 | UI-safe dark glass and subdued glow pads |
| R15 C0-C14 | visual utility cells, masks, arrows, low-risk markers |
| R15 C15 | fully transparent utility cell |

## Variant Motifs

| Motif | Use |
|---|---|
| `cracked_plate` | Used in motif rows to make this candidate read as Mirror City rather than generic tech floor. |
| `shard_path` | Used in motif rows to make this candidate read as Mirror City rather than generic tech floor. |
| `diagonal_fracture` | Used in motif rows to make this candidate read as Mirror City rather than generic tech floor. |
| `warning_reflection` | Used in motif rows to make this candidate read as Mirror City rather than generic tech floor. |
