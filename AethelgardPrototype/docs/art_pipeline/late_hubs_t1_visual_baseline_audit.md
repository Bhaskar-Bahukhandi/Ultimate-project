# PHASE 10M-T1 LATE HUB / CHAPTER 6-10 VISUAL BASELINE AUDIT REPORT

## 1. Summary

* AGENTS.md read: Yes.
* Late hub scenes found: 7 primary revisit/prep hub scenes, plus 6 chapter-specific support scenes for static audit.
* Generated late-hub tilesets found: 5 dedicated generated_v2 late-hub tilesets; Saved Assembly and Human Patch Lab have no dedicated generated_v2 tileset found.
* Screenshots captured: No new live captures in this builder step; existing visual-review screenshots copied where available.
* Production art changed: No.
* Generated assets overwritten: No.
* Gameplay scenes/scripts modified: No.
* Overall verdict: Late-hub visuals are uneven. The recurring weakness is the shared late-hub wrapper/floor grammar, with Saved Assembly and Human Patch Lab weakest as single areas because they lack dedicated generated_v2 tilesets.

## 2. Baseline Preservation

| Baseline | Path | Status | Notes |
|---|---|---|---|
| Oakhaven | `assets/production_art/tilesets/oakhaven/oakhaven_afternoon_tileset.png` | Present | Preservation check only; not modified. |
| Ironhold | `assets/production_art/tilesets/ironhold/ironhold_tileset.png` | Present | Preservation check only; not modified. |
| Fractured Wastes | `assets/production_art/tilesets/fractured_wastes/fractured_wastes_tileset.png` | Present | Preservation check only; not modified. |
| Shared V3 props | `assets/generated_v3/props/phase10mm_environment_prop_atlas.png` | Present | Preservation check only; not modified. |
| Shared V3 decals | `assets/generated_v3/overlays/phase10mm_environment_decal_atlas.png` | Present | Preservation check only; not modified. |

## 3. Late Hub Scene Inventory

| Hub/Area | Scene Path | Script Path | Load Status | Side-Effect Risk | Notes |
|---|---|---|---|---|---|
| Forgotten Sectors | `scenes/regions/forgotten_sectors_revisit_hub.tscn` | `scripts/regions/late_revisit_hub.gd` | Queued for safe load validation | Low-medium for shared revisit hub; chapter story/trial scenes skipped | Readable archive identity from V3 props, but floor and route scaffold still look prototype-like. |
| Mirror City | `scenes/regions/mirror_city_revisit_hub.tscn` | `scripts/regions/late_revisit_hub.gd` | Queued for safe load validation | Low-medium for shared revisit hub; chapter story/trial scenes skipped | Dedicated prototype tileset exists, but no accepted baseline or recent proof screenshot was found in the known visual review set. |
| Cathedral Server | `scenes/regions/cathedral_server_revisit_hub.tscn` | `scripts/regions/late_revisit_hub.gd` | Queued for safe load validation | Low-medium for shared revisit hub; chapter story/trial scenes skipped | Server identity is present through props, but architecture and drill-board floor remain limited. |
| Memory Ocean | `scenes/regions/memory_ocean_revisit_hub.tscn` | `scripts/regions/late_revisit_hub.gd` | Queued for safe load validation | Low-medium for shared revisit hub; chapter story/trial scenes skipped | Strongest current late-hub mood from existing review evidence, but still lacks a coherent island/water tile family. |
| Root of Heaven Prep | `scenes/regions/root_of_heaven_prep_hub.tscn` | `scripts/regions/late_revisit_hub.gd` | Queued for safe load validation | Low-medium for shared revisit hub; chapter story/trial scenes skipped | Final-threshold identity is visible, but the hub floor/prep marker still feels simplified against the route importance. |
| Saved Assembly | `scenes/regions/saved_assembly_revisit_hub.tscn` | `scripts/regions/late_revisit_hub.gd` | Queued for safe load validation | Low-medium for shared revisit hub; chapter story/trial scenes skipped | No dedicated generated_v2 tileset found; likely relies on shared/prototype visuals. |
| Human Patch Lab | `scenes/regions/human_patch_lab_revisit_hub.tscn` | `scripts/regions/late_revisit_hub.gd` | Queued for safe load validation | Low-medium for shared revisit hub; chapter story/trial scenes skipped | No dedicated generated_v2 tileset found; likely relies on shared/prototype visuals. |
| Chapter 6 Cathedral Nave | `scenes/chapter6/ch6_cathedral_nave.tscn` | `scripts/chapter6/ch6_cathedral_nave.gd` | Skipped | High/static only | Included for inventory, not loaded in this audit pass. |
| Chapter 6 Choir Core | `scenes/chapter6/ch6_choir_core.tscn` | `scripts/chapter6/ch6_choir_core.gd` | Skipped | High/static only | Included for inventory, not loaded in this audit pass. |
| Chapter 7 Memory Ocean Hub | `scenes/chapter7/ch7_memory_ocean_hub.tscn` | `scripts/chapter7/ch7_memory_ocean_hub.gd` | Skipped | High/static only | Included for inventory, not loaded in this audit pass. |
| Chapter 8 Saved Assembly | `scenes/chapter8/ch8_saved_assembly.tscn` | `scripts/chapter8/ch8_saved_assembly.gd` | Skipped | High/static only | Included for inventory, not loaded in this audit pass. |
| Chapter 9 Memory Lab | `scenes/chapter9/ch9_memory_lab.tscn` | `scripts/chapter9/ch9_memory_lab.gd` | Skipped | High/static only | Included for inventory, not loaded in this audit pass. |
| Chapter 10 Witness Chamber | `scenes/chapter10/ch10_witness_chamber.tscn` | `scripts/chapter10/ch10_witness_chamber.gd` | Skipped | High/static only | Included for inventory, not loaded in this audit pass. |

## 4. Late Hub Tileset Inventory

| Hub/Area | Tileset Path | Dimensions | Production Slot | Current Quality | Notes |
|---|---|---|---|---|---|
| Forgotten Sectors | `assets/generated_v2/tilesets/forgotten_sectors_v2_prototype_tileset.png` | 128x64 | Absent | Prototype fallback, not accepted production baseline | Readable archive identity from V3 props, but floor and route scaffold still look prototype-like. |
| Mirror City | `assets/generated_v2/tilesets/mirror_city_v2_prototype_tileset.png` | 128x64 | Absent | Prototype fallback, not accepted production baseline | Dedicated prototype tileset exists, but no accepted baseline or recent proof screenshot was found in the known visual review set. |
| Cathedral Server | `assets/generated_v2/tilesets/cathedral_server_v2_prototype_tileset.png` | 128x64 | Absent | Prototype fallback, not accepted production baseline | Server identity is present through props, but architecture and drill-board floor remain limited. |
| Memory Ocean | `assets/generated_v2/tilesets/memory_ocean_v2_prototype_tileset.png` | 128x64 | Absent | Prototype fallback with stronger mood than most late hubs, still not production baseline | Strongest current late-hub mood from existing review evidence, but still lacks a coherent island/water tile family. |
| Root of Heaven Prep | `assets/generated_v2/tilesets/root_of_heaven_v2_prototype_tileset.png` | 128x64 | Absent | Prototype fallback with stronger mood than most late hubs, still not production baseline | Final-threshold identity is visible, but the hub floor/prep marker still feels simplified against the route importance. |
| Saved Assembly | `No dedicated generated_v2 tileset found` | missing | Absent | Missing dedicated generated tileset | No dedicated generated_v2 tileset found; likely relies on shared/prototype visuals. |
| Human Patch Lab | `No dedicated generated_v2 tileset found` | missing | Absent | Missing dedicated generated tileset | No dedicated generated_v2 tileset found; likely relies on shared/prototype visuals. |

## 5. Screenshot / Evidence

| Hub/Area | Screenshot Path | Result | Notes |
|---|---|---|---|
| Forgotten Sectors | `assets/art_sources/comfyui_tests/late_hubs_t1_audit/screenshots/forgotten_sectors_reference_existing.png` | Existing screenshot copied | Copied existing visual-review screenshot as audit evidence |
| Mirror City | `Skipped` | No safe/new screenshot captured | Static tileset evidence only |
| Cathedral Server | `assets/art_sources/comfyui_tests/late_hubs_t1_audit/screenshots/cathedral_server_reference_existing.png` | Existing screenshot copied | Copied existing visual-review screenshot as audit evidence |
| Memory Ocean | `assets/art_sources/comfyui_tests/late_hubs_t1_audit/screenshots/memory_ocean_reference_existing.png` | Existing screenshot copied | Copied existing visual-review screenshot as audit evidence |
| Root of Heaven Prep | `assets/art_sources/comfyui_tests/late_hubs_t1_audit/screenshots/root_of_heaven_reference_existing.png` | Existing screenshot copied | Copied existing visual-review screenshot as audit evidence |
| Saved Assembly | `Skipped` | No safe/new screenshot captured | Static tileset evidence only |
| Human Patch Lab | `Skipped` | No safe/new screenshot captured | Static tileset evidence only |
| Contact sheet | `assets/art_sources/comfyui_tests/late_hubs_t1_audit/contact_sheets/late_hubs_t1_reference_contact_sheet.png` | Created | Uses existing screenshots and generated tileset references only. |

New screenshot capture was deferred to avoid scene-side effects during the audit builder. Existing review screenshots were reused where available, and Godot scene-load validation is handled by the preview-only validation script.

## 6. Visual Scores

| Hub/Area | Readability | Identity | Repetition | Atmosphere | Production Readiness | Replacement Urgency | Overall |
|---|---:|---:|---:|---:|---:|---:|---:|
| Forgotten Sectors | 6.0 | 6.2 | 5.0 | 5.8 | 4.8 | 6.8 | 5.8 |
| Mirror City | 5.7 | 5.8 | 5.0 | 5.8 | 4.6 | 6.4 | 5.5 |
| Cathedral Server | 6.0 | 6.4 | 4.8 | 6.2 | 4.8 | 6.7 | 5.8 |
| Memory Ocean | 6.4 | 6.8 | 5.5 | 6.8 | 5.2 | 6.2 | 6.1 |
| Root of Heaven Prep | 6.2 | 6.9 | 5.3 | 7.0 | 5.1 | 6.5 | 6.1 |
| Saved Assembly | 5.0 | 4.8 | 4.5 | 4.8 | 3.8 | 7.6 | 4.8 |
| Human Patch Lab | 5.1 | 5.0 | 4.5 | 5.0 | 3.8 | 7.5 | 4.9 |

## 7. Risk Scores

Scores use 1 as low risk and 10 as high risk.

| Hub/Area | Load Risk | Story Risk | Combat Risk | Art Replacement Risk | Implementation Complexity | Notes |
|---|---:|---:|---:|---:|---:|---|
| Forgotten Sectors | 3 | 2 | 1 | 5 | 5 | Shared hub load is relatively safe; full scene art swap would need fallback routing. |
| Mirror City | 3 | 3 | 1 | 5 | 5 | Mirror-specific story scenes should stay static-audit only until a preview phase. |
| Cathedral Server | 3 | 4 | 4 | 5 | 6 | Combat/trial chapter scenes are risky; revisit hub is safer. |
| Memory Ocean | 3 | 3 | 1 | 5 | 6 | Ocean visuals need careful readability against labels and route markers. |
| Root of Heaven Prep | 4 | 6 | 3 | 7 | 7 | Final-route importance raises replacement risk even when prep hub loads. |
| Saved Assembly | 3 | 4 | 2 | 6 | 6 | No dedicated tileset means a new controlled grammar is needed before import. |
| Human Patch Lab | 3 | 5 | 3 | 6 | 6 | No dedicated tileset and story/trial adjacency raise audit caution. |

## 8. Priority Ranking

| Rank | Hub/Area | Why It Ranks Here | Recommended Next Action |
|---|---|---|---|
| 1 | Shared late-hub tileset family | Most late hubs share the same revisit-hub wrapper and prototype floor language; one controlled family can improve multiple weak areas without touching accepted early-region baselines. | Start shared late-hub tileset family builder pass |
| 2 | Saved Assembly | Weakest single area by asset coverage because no dedicated generated_v2 tileset was found. | If the family pass is rejected, start Saved Assembly dedicated builder |
| 3 | Human Patch Lab | Also lacks a dedicated generated_v2 tileset and likely needs lab-specific grammar. | Use as second dedicated late-hub target |
| 4 | Cathedral Server | Identity is present but architecture/floor support remain visibly prototype-like. | Revisit after shared family defines server/digital grammar |
| 5 | Forgotten Sectors | Readable enough through V3 props but still benefits from archive-sector floor/path cleanup. | Lower urgency than missing-dedicated-tileset hubs |
| 6 | Root of Heaven Prep | Important final-route visuals, but higher story/art risk makes it poor as the first new experiment. | Defer until a safer late-hub grammar is proven |
| 7 | Memory Ocean | Best current mood among audited late hubs. | Lower immediate priority |
| 8 | Mirror City | Needs more direct screenshot proof before ranking above missing-dedicated-tileset hubs. | Static audit and later preview capture first |

## 9. Honest Recommendation

* Which late hub is weakest visually? Saved Assembly and Human Patch Lab are the weakest single areas because no dedicated generated_v2 tileset was found for either.
* Which hub gives the best improvement per risk? The shared late-hub wrapper/floor family gives the best improvement per risk because most audited hubs use the same revisit-hub script and share the same prototype visual problem.
* Which hub should be upgraded first? Start with a shared late-hub tileset family, then specialize Saved Assembly and Human Patch Lab if needed.
* Should the next phase build one hub tileset or a shared late-hub family? Build a shared late-hub family first, with per-hub palette/identity variants.
* Are any scenes too risky to touch right now? Chapter story/trial scenes for Cathedral Server, Human Patch Lab, Root of Heaven, and other final-route content should remain static-audit only until a dedicated preview pass.
* What should not be changed? Accepted Oakhaven, Ironhold, Fractured Wastes baselines, shared V3 prop/decal baselines, gameplay scenes, scripts, AssetManager, collision, combat, story, save/load, world travel, and generated fallback assets.

## 10. Project Safety Validation

| Test | Result | Notes |
|---|---|---|
| discovered Godot path | Passed | `C:\Godot\Godot_v4.6.3-stable_win64_console.exe` |
| Godot version | Passed | `4.6.3.stable.official.7d41c59c4` |
| project boot | Passed | Headless project boot completed with exit code 0. |
| main menu | Passed | `res://scenes/main_menu.tscn` loaded and instantiated. |
| Oakhaven baseline preservation | Passed | Production baseline image exists and loaded as 512x512. |
| Ironhold baseline preservation | Passed | Production baseline image exists and loaded as 512x512. |
| Fractured Wastes baseline preservation | Passed | Production baseline image exists and loaded as 512x512. |
| shared V3 props/decals preservation | Passed | Current V3 prop/decal atlases exist and loaded as 1536x1024. AssetManager fallback warnings were expected because shared production slots remain intentionally absent. |
| no production_art overwrite | Passed | `git status --short -- assets/production_art` reported no changes. |
| no generated_v2 overwrite | Passed | `git status --short -- assets/generated_v2` reported no changes. |
| no generated_v3 overwrite | Passed | `git status --short -- assets/generated_v3` reported no changes. |
| no gameplay scene/script modification | Passed | `git status --short -- scenes scripts` reported no changes. |
| git diff --check | Passed | Command exited 0; warning only about CRLF/LF normalization in existing `docs/art_pipeline/art_replacement_manifest.md`. |
| late hub revisit/prep scene loads | Passed | All 7 safe revisit/prep hub scenes loaded and instantiated; player, camera, visual nodes, and label-like nodes were found. |
| chapter story/trial scene load | Skipped | Static audit only to avoid story/combat/quest side effects. |

## 11. Decision

Ready for shared late-hub tileset family builder pass
