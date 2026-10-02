# PHASE 10M-S3 SHARED ENVIRONMENT PROP ATLAS REPAIR REPORT

## 1. Summary

* AGENTS.md read: Yes
* Prop repair variants created: 3
* Best repaired variant: S3 Variant B rich
* Decal atlas changed: No
* Production art changed: No
* Generated V3 assets overwritten: No
* Actual gameplay scenes modified: No
* Overall verdict: Variant B is contract-aligned, richer than S1, cleaner than current V3, and suitable for preview-only Godot validation.

## 2. Input Verification

| Input | Path | Status | Notes |
|---|---|---|---|
| current V3 prop atlas | `assets/generated_v3/props/phase10mm_environment_prop_atlas.png` | Pass | 1536x1024 RGBA input preserved. |
| S1 prop candidate | `assets/art_sources/comfyui_tests/shared_environment_s1/generated_props/shared_environment_props_s1_variant_b.png` | Pass | Used as cleanliness/reference baseline. |
| S1 decal candidate | `assets/art_sources/comfyui_tests/shared_environment_s1/generated_decals/shared_environment_decals_s1_variant_b.png` | Pass | Reused unchanged in mockups. |
| S2 review | `docs/art_pipeline/shared_environment_s2_preview_validation_review.md` | Pass | S2 decision was prop repair before import. |
| S2 region contract | `assets/art_sources/comfyui_tests/shared_environment_s2_preview/manifest/shared_environment_s2_region_contract.json` | Pass | 19 prop Rect2i regions preserved. |
| production slots absent | `assets/production_art/props/environment_prop_atlas.png`, `assets/production_art/backgrounds/environment_decal_atlas.png` | Pass | Not written by S3. |
| generated V3 unchanged | generated V3 prop/decal atlases | Pass | Not overwritten by S3. |

## 3. Repair Strategy

S2 found that the S1 prop atlas was crop-aligned but too sparse and simplified compared with current V3. S3 repairs the prop atlas only by drawing richer deterministic prop content inside each exact hard-coded Rect2i. Current V3 was used as a density/reference target, while S1 was used as a cleanliness and alpha-control target. The decal atlas remains unchanged.

## 4. Repaired Prop Files Created

| Variant | File | Purpose | Status |
|---|---|---|---|
| A conservative | `assets/art_sources/comfyui_tests/shared_environment_s3_prop_repair/generated_props/shared_environment_props_s3_variant_a_conservative.png` | Clean, safest readability repair | Created |
| B rich | `assets/art_sources/comfyui_tests/shared_environment_s3_prop_repair/generated_props/shared_environment_props_s3_variant_b_rich.png` | Primary repaired candidate | Created |
| C dense/reference | `assets/art_sources/comfyui_tests/shared_environment_s3_prop_repair/generated_props/shared_environment_props_s3_variant_c_dense.png` | Density stress/reference candidate | Created |

## 5. Region-by-Region Repair Summary

| Region ID | S2 Problem | S3 Repair | Risk | Verdict |
|---|---|---|---|---|
| `oakhaven_roof` | S1 roof was too flat and sparse. | Added roof strip, tile marks, chimney, edge trim, and shadow. | low/medium | Pass |
| `oakhaven_hedge_corner` | S1 hedge had broad transparent gaps and simplified clusters. | Filled corner hedge with layered bush clusters and base shadows. | low/medium | Pass |
| `oakhaven_flowers` | S1 flower scatter was readable but thin. | Added varied flower, grass, and herb clusters across the crop. | low/medium | Pass |
| `oakhaven_herb_sign` | S1 sign marker lacked detail and grounding. | Added sign face, post, herb patch, bucket, and shadow. | low/medium | Pass |
| `ironhold_pipes` | S1 pipes were isolated lines without industrial mass. | Added pipe network, elbows, valves, joints, supports, and rivets. | low/medium | Pass |
| `ironhold_forge` | S1 forge was a simple box and weak silhouette. | Added furnace body, chimney, grate, warm glow, anvil, and control box. | low/medium | Pass |
| `crates` | S1 shared prop plate had low object density. | Added crates, barrels, sacks, rubble, fence pieces, and cast shadows. | low/medium | Pass |
| `archive_shelves` | S1 shelf area was large but simple. | Added book shelves, archive boxes, scrolls, and bottom grounding. | low/medium | Pass |
| `dossier_stack` | S1 dossier stack read as plain rectangles. | Added staggered paper stack, folders, edge lines, and shadow. | low/medium | Pass |
| `null_seal` | S1 seal was readable but too minimal. | Added pedestal, ritual rings, symbol lines, and controlled glow. | low/medium | Pass |
| `mirror_plinth` | S1 plinth was too empty. | Added plinth base, reflective shard/mirror, highlights, and stones. | low/medium | Pass |
| `server_console` | S1 console banks lacked screen/button density. | Added terminal banks, screens, buttons, cable lines, and shadows. | low/medium | Pass |
| `firewall_panel` | S1 panels were flat and sparse. | Added barrier plates, warning geometry, posts, vents, and red cores. | low/medium | Pass |
| `tide_buoy` | S1 marker was too plain. | Added buoy body, pole, ring base, glow, and marker base. | low/medium | Pass |
| `salvage_shelf` | S1 salvage cluster was sparse. | Added shelves, crates, scrap, cables, and grouped silhouettes. | low/medium | Pass |
| `ocean_cache` | S1 cache lacked storage identity. | Added cache/chest, net/rope, rocks, and small salvage pieces. | low/medium | Pass |
| `lab_console` | S1 lab console was too simple. | Added clinical console, screen, table, devices, and keyboard. | low/medium | Pass |
| `memory_tank` | S1 tank needed stronger glass/fluid silhouette. | Added glass tank, liquid core, base, cap, pipe, and highlights. | low/medium | Pass |
| `root_circuit_rail` | S1 rail was mostly empty across a very wide crop. | Added long rail, root/circuit strands, nodes, and repeating supports. | low/medium | Pass |

## 6. Crop Contract Validation

| Variant | Regions Valid | Nonblank Regions | Alignment | Risk | Verdict |
|---|---:|---:|---|---|---|
| S3 Variant A | 19/19 | 19/19 | aligned | low/medium | safe for preview |
| S3 Variant B | 19/19 | 19/19 | aligned | low/medium | best candidate |
| S3 Variant C | 19/19 | 19/19 | aligned | medium | dense reference |

Crop sheets:
* `assets/art_sources/comfyui_tests/shared_environment_s3_prop_repair/crop_checks/shared_env_s3_variant_a_prop_crop_check.png`
* `assets/art_sources/comfyui_tests/shared_environment_s3_prop_repair/crop_checks/shared_env_s3_variant_b_prop_crop_check.png`
* `assets/art_sources/comfyui_tests/shared_environment_s3_prop_repair/crop_checks/shared_env_s3_variant_c_prop_crop_check.png`

Diagnostics JSON: `assets/art_sources/comfyui_tests/shared_environment_s3_prop_repair/diagnostics/shared_environment_s3_prop_crop_diagnostics.json`

## 7. Prop Atlas Quality Scores

| Candidate | Contract Alignment | Silhouette | Richness | Alpha | Region Fit | Overall | Verdict |
|---|---:|---:|---:|---:|---:|---:|---|
| current V3 | 8.8 | 8.4 | 8.6 | 8.0 | 8.4 | 8.1 | fallback reference |
| S1 Variant B | 8.5 | 7.6 | 7.0 | 8.7 | 7.6 | 7.8 | too sparse |
| S3 Variant A | 8.7 | 8.1 | 7.9 | 8.8 | 8.1 | 8.1 | safe reference |
| S3 Variant B | 8.8 | 8.5 | 8.5 | 8.7 | 8.6 | 8.4 | best candidate |
| S3 Variant C | 8.8 | 8.3 | 8.8 | 8.4 | 8.2 | 8.2 | dense reference |

## 8. Mockup Review

| Mockup | Path | Readability | Region Fit | Verdict |
|---|---|---|---|---|
| Oakhaven | `assets/art_sources/comfyui_tests/shared_environment_s3_prop_repair/mockups/shared_env_s3_oakhaven_variant_b_mockup.png` | High | Good | Variant B props read as village support. |
| Ironhold | `assets/art_sources/comfyui_tests/shared_environment_s3_prop_repair/mockups/shared_env_s3_ironhold_variant_b_mockup.png` | High | Good | Pipe/forge/console density repaired. |
| Fractured Wastes | `assets/art_sources/comfyui_tests/shared_environment_s3_prop_repair/mockups/shared_env_s3_fractured_wastes_variant_b_mockup.png` | High | Good | Salvage/crystal/cache props read clearly. |
| Arena/combat | `assets/art_sources/comfyui_tests/shared_environment_s3_prop_repair/mockups/shared_env_s3_arena_variant_b_mockup.png` | High | Good | Props support telegraph readability. |

## 9. Comparison Against Current V3 and S1

| Area | Current V3 | S1 Candidate | S3 Best Candidate | Better/Worse |
|---|---|---|---|---|
| broad prop density | Rich but artifact-prone | Too sparse | Richer controlled density | Better than S1, comparable/better than V3 |
| silhouette readability | Good, sometimes noisy | Clean but simple | Clear and richer | Better |
| region identity | Strong in several regions | Weak in broad regions | Stronger per-region identity | Better |
| alpha cleanliness | Good but busy | Very clean | Clean | Better than V3 |
| shadow grounding | Strong | Moderate | Stronger than S1 | Better than S1 |
| Ironhold richness | Strong | Weak | Repaired pipes/forge/consoles | Better than S1, cleaner than V3 |
| late hub richness | Strong | Sparse | Repaired consoles/seals/tank/rail | Better than S1 |
| overall usefulness | High fallback reference | Not import-ready | Preview-validation ready | Better than S1; candidate for S4 |

## 10. Project Safety Validation

| Test | Result | Notes |
|---|---|---|
| discovered Godot path | Pass | `C:\Godot\Godot_v4.6.3-stable_win64_console.exe` |
| Godot version | Pass | `4.6.3.stable.official.7d41c59c4` |
| project boot | Pass | Headless project boot completed. |
| main menu | Pass | Loaded by S3 validation script. |
| Oakhaven baseline preservation | Pass | `assets/production_art/tilesets/oakhaven/oakhaven_afternoon_tileset.png` loaded. |
| Ironhold baseline preservation | Pass | `assets/production_art/tilesets/ironhold/ironhold_tileset.png` loaded. |
| Fractured Wastes baseline preservation | Pass | `assets/production_art/tilesets/fractured_wastes/fractured_wastes_tileset.png` loaded. |
| no production_art overwrite | Pass | Shared prop/decal production slots remain absent; no production paths were written. |
| no generated_v3 overwrite | Pass | Current generated V3 prop/decal atlas paths were not modified. |
| no gameplay scene/script modification | Pass | S3 writes only art_sources/docs outputs. |
| git diff --check | Pass | No whitespace errors reported. |

## 11. Honest Visual Verdict

S3 Variant B is clearly better than S1 because it fills the broad regions, improves silhouettes, and gives each hard-coded crop a stronger visual identity. It is cleaner and more controlled than current V3 while approaching or exceeding V3 richness in the important broad prop plates. Some late-hub regions remain stylized and should be checked in Godot at real scene scale, but the contract is preserved. S1 decal candidate should remain unchanged for the next validation. S3 is ready for preview-only Godot validation, not production_art import. Roof, forge, cache, and late-hub props should still be judged at runtime scale before any import decision. Roof, forge, cache, and late-hub props should still be judged at runtime scale before any import decision.

## 12. Decision

Ready for shared props repaired candidate preview-only Godot validation pass
