# Forgotten Sectors Layout

- Atlas path: `assets/art_sources/comfyui_tests/late_hubs_t2_family_builder/generated_tiles/late_hub_t2_forgotten_sectors_family.png`
- Dimensions: 512x512 RGBA
- Cell size: 32x32
- Grid: 16x16
- Intended hub: Forgotten Sectors
- Intended use: Archive, deleted records, sealed cases, forgotten transit, cyan/white memory geometry.
- Collision implication: visual-only / no collision implication
- Label-safe tiles: Rows 9 and 14, plus R0 C14, are intentionally dark and low-noise.
- Glow intensity: restrained support glows; no cell is intended as a full-screen light source.

## Coordinate / Cell Ranges

| Range | Tile names / intended use |
|---|---|
| R0 C0-C15 | low-noise base floors, UI-safe dark floor at C14, transparent utility at C15 |
| R1 C0-C15 | floor variations, subtle fade, label-safe and circuit support variants |
| R2 C0-C15 | horizontal, vertical, cross, T, corner, and broken route/path tiles |
| R3 C0-C15 | secondary route tiles, narrow paths, markers, and safe route variants |
| R4 C0-C15 | wall/floor edge support and soft border transitions |
| R5 C0-C15 | corner transitions, inside corners, shadowed borders |
| R6 C0-C15 | primary family motif cells |
| R7 C0-C15 | secondary family motif cells and readable pattern variants |
| R8 C0-C15 | glow support cells with restrained intensity |
| R9 C0-C15 | shadow cells and label-safe dark floor variants |
| R10 C0-C15 | visual-only marker cells and objective route support |
| R11 C0-C15 | decal-like floor motifs, cracks, fragments, repair or wave accents |
| R12 C0-C15 | safe path variants and low-noise repeated floor helpers |
| R13 C0-C15 | edge/detail hybrids for wrapper grammar |
| R14 C0-C15 | dark UI-safe floor cells and subdued glow pads |
| R15 C0-C14 | visual utility cells, masks, arrows, non-collision markers |
| R15 C15 | fully transparent utility cell |

## Family Motif Cells

| Motif | Notes |
|---|---|
| `archive_lines` | Used in R1, R6, R7, R11, and R13 with hub-specific palette accents. |
| `case_file` | Used in R1, R6, R7, R11, and R13 with hub-specific palette accents. |
| `memory_circle` | Used in R1, R6, R7, R11, and R13 with hub-specific palette accents. |
| `deleted_crack` | Used in R1, R6, R7, R11, and R13 with hub-specific palette accents. |

## Notes

- Identity: archive, deleted records, sealed transit, cyan/white memory geometry.
- This is a review-only atlas. It is not production art and is not wired into any scene.
- Transparent utility cell is R15 C15.
