# Shared Environment S1 Contract Audit

## Summary

- Current prop atlas: `assets/generated_v3/props/phase10mm_environment_prop_atlas.png`
- Current decal atlas: `assets/generated_v3/overlays/phase10mm_environment_decal_atlas.png`
- Both atlases are 1536x1024 RGBA with alpha.
- `AssetManager` uses named hard-coded `Rect2i` regions for both atlases.
- S1 candidates preserve canvas dimensions and named region rectangles for review-only evaluation.
- Production import is not safe until a later phase validates these candidates in Godot.

## Prop Regions

| Region | Rect2i | Usage Sites | Notes |
|---|---|---|---|
| `oakhaven_roof` | `(32, 22, 248, 190)` | scripts\asset_manager.gd:888<br>scripts\regions\oakhaven_region.gd:276 | cottage roof strip, cottage crate, village wood trim |
| `oakhaven_hedge_corner` | `(760, 52, 390, 176)` | scripts\asset_manager.gd:889<br>scripts\regions\oakhaven_region.gd:362<br>scripts\regions\oakhaven_region.gd:365 | bush, hedge corner, village fence segment, tree stump |
| `oakhaven_flowers` | `(30, 264, 418, 82)` | scripts\asset_manager.gd:890<br>scripts\regions\oakhaven_region.gd:359<br>scripts\regions\oakhaven_region.gd:360 | flower patch, herb patch, grass clump, farm marker support |
| `oakhaven_herb_sign` | `(478, 238, 128, 126)` | scripts\asset_manager.gd:891<br>scripts\regions\oakhaven_region.gd:361 | signpost, broken sign, water bucket, clay pot |
| `ironhold_pipes` | `(616, 238, 544, 170)` | scripts\asset_manager.gd:892<br>scripts\regions\ironhold_region.gd:340<br>scripts\regions\ironhold_region.gd:343 | pipe horizontal, pipe vertical, pipe elbow, valve, gear, tool rack, warning barrier, grate, vent |
| `ironhold_forge` | `(1320, 226, 164, 194)` | scripts\asset_manager.gd:893<br>scripts\regions\ironhold_region.gd:341 | anvil, furnace control box, small forge glow insert |
| `crates` | `(40, 434, 540, 144)` | scripts\asset_manager.gd:894<br>scripts\combat\combat_arena.gd:165<br>scripts\combat\combat_arena.gd:166<br>scripts\regions\ironhold_region.gd:342<br>scripts\regions\late_revisit_hub.gd:367<br>scripts\regions\late_revisit_hub.gd:368 | small crate, large crate, barrel, broken barrel, sack, chest, table, bench, fence post, low fences, stone marker, rubble |
| `archive_shelves` | `(620, 370, 356, 218)` | scripts\asset_manager.gd:895<br>scripts\regions\late_revisit_hub.gd:348<br>scripts\regions\late_revisit_hub.gd:349 | archive shelves, archive box, seal pedestal |
| `dossier_stack` | `(988, 440, 94, 128)` | scripts\asset_manager.gd:896<br>scripts\regions\late_revisit_hub.gd:350 | dossier stack, memory shard stand |
| `null_seal` | `(1092, 432, 156, 176)` | scripts\asset_manager.gd:897<br>scripts\regions\late_revisit_hub.gd:351 | seal pedestal, magenta anomaly marker |
| `mirror_plinth` | `(1280, 430, 202, 192)` | scripts\asset_manager.gd:898<br>scripts\regions\late_revisit_hub.gd:354<br>scripts\regions\late_revisit_hub.gd:355 | mirror plinth, small portal trim |
| `server_console` | `(36, 612, 376, 194)` | scripts\asset_manager.gd:899<br>scripts\chapter6\ch6_choir_core.gd:46<br>scripts\regions\late_revisit_hub.gd:358 | small terminal, data pillar, broken server plate |
| `firewall_panel` | `(430, 612, 358, 194)` | scripts\asset_manager.gd:900<br>scripts\chapter6\ch6_choir_core.gd:45<br>scripts\regions\late_revisit_hub.gd:359 | firewall/server panel, cyan spark node |
| `tide_buoy` | `(824, 610, 120, 182)` | scripts\asset_manager.gd:901<br>scripts\regions\late_revisit_hub.gd:363 | memory tide gauge, cyan spark node |
| `salvage_shelf` | `(974, 610, 290, 198)` | scripts\asset_manager.gd:902<br>scripts\regions\late_revisit_hub.gd:362 | salvage crate, metal scrap, cloth scrap, survivor cache |
| `ocean_cache` | `(1268, 610, 236, 198)` | scripts\asset_manager.gd:903<br>scripts\regions\late_revisit_hub.gd:364 | memory cache, archive box, circuit stone |
| `lab_console` | `(34, 818, 248, 178)` | scripts\asset_manager.gd:904<br>scripts\regions\late_revisit_hub.gd:371 | lab console, terminal, circuit stone |
| `memory_tank` | `(292, 814, 170, 186)` | scripts\asset_manager.gd:905<br>scripts\regions\late_revisit_hub.gd:372<br>scripts\regions\late_revisit_hub.gd:373 | memory tank, data pillar |
| `root_circuit_rail` | `(628, 816, 844, 190)` | scripts\asset_manager.gd:906<br>scripts\regions\late_revisit_hub.gd:376 | root rail, circuit stone, cyan/magenta nodes |

## Decal Regions

| Region | Rect2i | Usage Sites | Notes |
|---|---|---|---|
| `oakhaven_path` | `(18, 10, 630, 198)` | scripts\asset_manager.gd:909<br>scripts\regions\oakhaven_region.gd:357 | dirt-path blend, foot-worn path accent, meadow shadow |
| `oakhaven_stones` | `(22, 228, 650, 128)` | scripts\asset_manager.gd:910<br>scripts\regions\oakhaven_region.gd:358 | pebble scatter, grass tufts, leaf scatter, cottage base shadow |
| `ironhold_road` | `(676, 16, 820, 224)` | scripts\asset_manager.gd:911<br>scripts\regions\ironhold_region.gd:338<br>scripts\regions\ironhold_region.gd:339<br>scripts\regions\late_revisit_hub.gd:366 | soot/oil stains, metal scratches, rivets, grate shadows, warm forge scuffs |
| `fracture_field` | `(18, 360, 500, 294)` | scripts\asset_manager.gd:912<br>scripts\regions\fractured_wastes_region.gd:298<br>scripts\regions\fractured_wastes_region.gd:300 | cracked scar line, ash smear, dark rift shadow |
| `shard_spill` | `(270, 350, 246, 298)` | scripts\asset_manager.gd:913<br>scripts\regions\fractured_wastes_region.gd:299<br>scripts\regions\fractured_wastes_region.gd:301 | fracture spark, shard glow accent, hazard boundary accent |
| `archive_seals` | `(520, 362, 382, 292)` | scripts\asset_manager.gd:914<br>scripts\regions\late_revisit_hub.gd:347 | archive dust, seal fragments, data-grid fragment |
| `mirror_ripples` | `(900, 246, 602, 280)` | scripts\asset_manager.gd:915<br>scripts\regions\late_revisit_hub.gd:353 | memory ripple, portal floor glow |
| `cathedral_circuit` | `(900, 510, 600, 240)` | scripts\asset_manager.gd:916<br>scripts\chapter6\ch6_choir_core.gd:44<br>scripts\combat\combat_arena.gd:164<br>scripts\regions\late_revisit_hub.gd:357<br>scripts\regions\late_revisit_hub.gd:370 | cyan circuit line, magenta glitch line, seal ring quarter |
| `memory_tide` | `(14, 674, 476, 326)` | scripts\asset_manager.gd:917<br>scripts\regions\late_revisit_hub.gd:361 | memory ripple, tide smear, glow-only accents |
| `root_veins` | `(492, 680, 406, 320)` | scripts\asset_manager.gd:918<br>scripts\chapter1\ch1_tutorial_knight.gd:220<br>scripts\regions\late_revisit_hub.gd:375 | root vein glow, corruption cleanup smear |
| `arena_border` | `(898, 754, 620, 252)` | scripts\asset_manager.gd:919<br>scripts\chapter1\ch1_tutorial_knight.gd:219<br>scripts\combat\combat_arena.gd:163 | circular arena scuff, impact mark, sword scrape, warning support ring, cracked impact center |

## Contract Risk

Replacement risk is medium. The atlas dimensions and hard-coded regions are clear, but several regions are broad scene plates rather than atomic 32x32 cells. A later import must either preserve these exact rectangles or explicitly revise `AssetManager` and every usage target size.
