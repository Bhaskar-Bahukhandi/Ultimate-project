# Art Replacement Manifest

This manifest records the current M4 replacement slots. A production slot may be absent today;
`AssetManager` should then warn once and keep the generated fallback alive.

Quality ratings:
- `1/5`: placeholder or strongly prototype
- `2/5`: usable only as generated fallback
- `3/5`: playable alpha support art
- `4/5`: candidate production art
- `5/5`: final-quality locked art

| Current Asset Path | Current Quality Rating | Replacement Priority | Ideal Replacement Type | Expected Dimensions | Usage Scene | Fallback Path | Notes |
| --- | --- | --- | --- | --- | --- | --- | --- |
| `assets/production_art/tilesets/oakhaven/oakhaven_afternoon_tileset.png` plus staged morning/night variants | 4/5 | P0 | coherent Oakhaven time-of-day tileset family with path edges and cottage support tiles | 512x512, 32 px tiles, shared 16x16 layout | Oakhaven region | `assets/generated_v2/tilesets/oakhaven_v2_prototype_tileset.png` | Phase 10M-P11 controlled import candidate; accept afternoon first, keep morning/night staged until a later time-state pass |
| `assets/production_art/tilesets/ironhold/ironhold_tileset.png` | 4/5 | P0 | controlled industrial floor, walkway, forge, wall, pipe, machinery, and obstacle tile grammar | 512x512, 32 px tiles, 16x16 layout | Ironhold region | `assets/generated_v2/tilesets/ironhold_v2_prototype_tileset.png` | Phase 10M-Q3 controlled Variant B import candidate; generated fallback remains required for rollback |
| `assets/production_art/tilesets/fractured_wastes/fractured_wastes_tileset.png` | 4/5 | P0 | controlled cracked wasteland, safe-path, corruption, ruin, prop, and hazard-readability tile grammar | 512x512, 32 px tiles, 16x16 layout | Fractured Wastes region | `assets/generated_v2/tilesets/fractured_wastes_v2_prototype_tileset.png` | Phase 10M-R3 controlled Variant B import candidate; generated fallback remains required for rollback |
| `assets/generated_v3/props/phase10mm_environment_prop_atlas.png` | 2/5 | P0 | grounded region prop atlas with bases and cast shadows | preserve current atlas regions or revise contract explicitly | Oakhaven, Ironhold, late hubs, arenas | same current path | first production slot: `assets/production_art/props/environment_prop_atlas.png` |
| `assets/generated_v3/overlays/phase10mm_environment_decal_atlas.png` | 2/5 | P0 | authored floor/decal plates with organic edges | preserve current atlas regions or revise contract explicitly | visual polish scenes and late hubs | same current path | first production slot: `assets/production_art/backgrounds/environment_decal_atlas.png` |
| `assets/generated_v2/tilesets/forgotten_sectors_v2_prototype_tileset.png` | 2/5 | P1 | archive/court hub tile family | 32 px tiles, >=384x384 sheet | Forgotten Sectors hub | same current path | wrapper hub wants archive architecture, not generic board |
| `assets/generated_v2/tilesets/mirror_city_v2_prototype_tileset.png` | 2/5 | P1 | glass/reflection hub tile family | 32 px tiles, >=384x384 sheet | Mirror City hub | same current path | needs reflective identity without text noise |
| `assets/generated_v2/tilesets/cathedral_server_v2_prototype_tileset.png` | 2/5 | P1 | server nave and firewall tile family | 32 px tiles, >=384x384 sheet | Cathedral Server hub and Choir Core support | same current path | architecture should replace flat drill board feel |
| `assets/generated_v2/tilesets/memory_ocean_v2_prototype_tileset.png` | 2/5 | P1 | salvage island/tide hub tile family | 32 px tiles, >=384x384 sheet | Memory Ocean hub | same current path | needs islands and water edge language |
| `assets/generated_v2/tilesets/root_of_heaven_v2_prototype_tileset.png` | 2/5 | P1 | prep-hub threshold and circuit-root tile family | 32 px tiles, >=384x384 sheet | Root of Heaven prep hub | same current path | keep final-route art sealed |
| no dedicated generated tileset | 1/5 | P1 | Saved Assembly civic hub tileset | 32 px tiles, >=384x384 sheet | Saved Assembly hub | generated hub visuals | production slot reserved as `saved_assembly_tileset.png` |
| no dedicated generated tileset | 1/5 | P1 | Human Patch Lab clinical tileset | 32 px tiles, >=384x384 sheet | Human Patch Lab hub | generated hub visuals | production slot reserved as `human_patch_lab_tileset.png` |
| `assets/generated_v2/sprites/player/kaelen_topdown_v2_alpha_sheet.png` | 3/5 | P2 | production top-down Kaelen sheet | 128x256, 32 px frames and current rows | all top-down scenes | same current path | slot: `assets/production_art/characters/player/kaelen_topdown_alpha_sheet.png` |
| `assets/generated_v2/sprites/player/kaelen_combat_v2_alpha_sheet.png` | 3/5 | P2 | production combat Kaelen sheet | 256x768, 64 px frames and current rows | combat | same current path | slot: `assets/production_art/characters/player/kaelen_combat_alpha_sheet.png` |
| `assets/generated_v2/sprites/bosses/tutorial_knight_v2_alpha_sheet.png` | 3/5 | P2 | production Tutorial Knight sheet | 384x960, 96 px frames and current rows | tutorial boss | same current path | slot: `assets/production_art/characters/bosses/tutorial_knight_alpha_sheet.png` |
| `assets/generated_v2/sprites/enemies/fracture_slime_v2_alpha_sheet.png` | 3/5 | P2 | production enemy sheet | 192x240, 48 px frames and current rows | slime encounters | same current path | preserve idle/move/attack/hurt/death rows |
| `assets/generated_v2/sprites/enemies/clock_mite_v2_alpha_sheet.png` | 3/5 | P2 | production enemy sheet | 192x240, 48 px frames and current rows | PhaseSpider visual path | same current path | preserve class-to-sheet mapping |
| `assets/generated_v2/sprites/enemies/memory_wisp_v2_alpha_sheet.png` | 3/5 | P2 | production enemy sheet | 192x240, 48 px frames and current rows | DataSprite visual path | same current path | preserve fallback if absent |
| `assets/generated_v2/sprites/npcs/*_v2_alpha_sheet.png` | 3/5 | P2 | production NPC sheets | 128x96 each, 32 px frames and current rows | named NPC presentation paths | current generated NPC sheets | Elara, Seraphina, Lyra, Null Clerk, Assembly Runner have production slots |
| current generated arena decals and ColorRect supports | 2/5 | P1 | authored arena floor plate and backdrop trims | floor plate >=1280x720 | Tutorial Knight and combat arena | current scenes plus decal atlas | warning readability outranks atmosphere |
| current world-map procedural UI art | 2/5 | P1 | authored free-travel map and marker family | viewport-safe base plus scalable marker atlas | world map UI | current world map | improve route readability before ornament |

## Naming Summary

- Visual tilesets: `assets/production_art/tilesets/<region_id>_tileset.png`, or a documented region folder slot such as `assets/production_art/tilesets/ironhold/ironhold_tileset.png`.
- Oakhaven time-of-day visual tilesets: `assets/production_art/tilesets/oakhaven/oakhaven_<time_state>_tileset.png`.
- Shared props atlas: `assets/production_art/props/environment_prop_atlas.png`.
- Shared floor/decal atlas: `assets/production_art/backgrounds/environment_decal_atlas.png`.
- Player sheets: `assets/production_art/characters/player/kaelen_topdown_alpha_sheet.png` and `kaelen_combat_alpha_sheet.png`.
- Boss sheets: `assets/production_art/characters/bosses/<boss_id>_alpha_sheet.png`.
- Enemy sheets: `assets/production_art/characters/enemies/<enemy_id>_alpha_sheet.png`.
- NPC sheets: `assets/production_art/characters/npcs/<npc_id>_alpha_sheet.png`.

## Phase 10M-N Local Sourcing Audit

The first production import pass found no local environment candidate that was both locally
license-safe to promote and a correct top-down production fit for the priority world slots.
Generated v2/v3 art remains fallback-only. Existing Kenney utility folders remain valuable fallback
inventory, but their platformer/utility style is not the first world replacement target. Existing
region files under `assets/tilesets/` need a local shipping-license record before promotion.
