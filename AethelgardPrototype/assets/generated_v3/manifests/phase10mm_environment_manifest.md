# Phase 10M-M Environment Support Assets

These original generated support atlases are visual-only assets for the Phase 10M-M alpha polish pass.
They do not replace collision, story scenes, combat timing, or character sprites.

| Asset | Path | Purpose |
| --- | --- | --- |
| Prop atlas | `res://assets/generated_v3/props/phase10mm_environment_prop_atlas.png` | Cropped top-down roofs, hedges, archive shelving, consoles, salvage props, lab props, root-circuit rail, and arena-side dressing. |
| Decal atlas | `res://assets/generated_v3/overlays/phase10mm_environment_decal_atlas.png` | Cropped ground paths, road plates, fracture shards, archive seals, mirror ripples, cathedral circuits, memory tide decals, root veins, and arena border plates. |

Generation notes:
- The atlases were generated as original project support art on a flat chroma background.
- The checked-in PNGs are the alpha-cleaned versions used by Godot.
- `AssetManager` crops atlas regions through the Phase 10M-M v3 visual helper and keeps the older procedural/V2 visuals underneath as fallbacks.
