# PHASE 10M-S4 SHARED ENVIRONMENT V3 PROP BASELINE AUDIT REPORT

## 1. Summary
- AGENTS.md read: Yes
- Current V3 prop atlas audited: Yes
- S3 replacement rejected/accepted: Rejected for full replacement
- Full prop-atlas replacement recommended: No
- Targeted repair needed: No
- Decal path recommendation: Continue S1 decal candidate separately while keeping current V3 decals active
- Production art changed: No
- Generated V3 assets overwritten: No
- Actual gameplay scenes modified: No
- Overall verdict: Keep current V3 props unchanged; S1/S3 props remain reference-only.

## 2. Input Verification
| Input | Path | Status | Notes |
|---|---|---|---|
| current V3 prop atlas | `assets/generated_v3/props/phase10mm_environment_prop_atlas.png` | Pass | 1536x1024 RGBA baseline. |
| current V3 decal atlas | `assets/generated_v3/overlays/phase10mm_environment_decal_atlas.png` | Pass | 1536x1024 RGBA active decal baseline. |
| S1 prop candidate | `assets/art_sources/comfyui_tests/shared_environment_s1/generated_props/shared_environment_props_s1_variant_b.png` | Pass | Reference only. |
| S1 decal candidate | `assets/art_sources/comfyui_tests/shared_environment_s1/generated_decals/shared_environment_decals_s1_variant_b.png` | Pass | Promising; separate path recommended. |
| S3 prop candidates | `assets/art_sources/comfyui_tests/shared_environment_s3_prop_repair/generated_props/` | Pass | Reference only; no import. |
| S2 region contract | `assets/art_sources/comfyui_tests/shared_environment_s2_preview/manifest/shared_environment_s2_region_contract.json` | Pass | Exact 19 prop Rect2i regions audited. |
| production slots status | `assets/production_art/props/environment_prop_atlas.png`, `assets/production_art/backgrounds/environment_decal_atlas.png` | Pass | Both absent. |
| generated V3 unchanged | generated V3 prop/decal atlas paths | Pass | Not overwritten. |

## 3. Crop Comparison Summary
| Region ID | Current V3 Verdict | S3 B Verdict | Better Candidate | Decision |
|---|---|---|---|---|
| `oakhaven_roof` | 8.8: keep | 7.8: reference only | Current V3 | Keep V3 unchanged |
| `oakhaven_hedge_corner` | 8.5: keep | 7.9: reference only | Current V3 | Keep V3 unchanged |
| `oakhaven_flowers` | 8.7: keep | 7.7: reference only | Current V3 | Keep V3 unchanged |
| `oakhaven_herb_sign` | 8.6: keep | 7.4: reference only | Current V3 | Keep V3 unchanged |
| `ironhold_pipes` | 8.5: keep | 8.0: reference only | Current V3 | Keep V3 unchanged |
| `ironhold_forge` | 8.9: keep | 7.6: reference only | Current V3 | Keep V3 unchanged |
| `crates` | 8.4: keep | 7.9: reference only | Current V3 | Keep V3 unchanged |
| `archive_shelves` | 8.6: keep | 8.0: reference only | Current V3 | Keep V3 unchanged |
| `dossier_stack` | 8.5: keep | 7.7: reference only | Current V3 | Keep V3 unchanged |
| `null_seal` | 8.4: keep | 7.9: reference only | Current V3 | Keep V3 unchanged |
| `mirror_plinth` | 8.7: keep | 7.9: reference only | Current V3 | Keep V3 unchanged |
| `server_console` | 8.6: keep | 8.0: reference only | Current V3 | Keep V3 unchanged |
| `firewall_panel` | 8.5: keep | 8.0: reference only | Current V3 | Keep V3 unchanged |
| `tide_buoy` | 8.4: keep | 7.8: reference only | Current V3 | Keep V3 unchanged |
| `salvage_shelf` | 8.6: keep | 8.0: reference only | Current V3 | Keep V3 unchanged |
| `ocean_cache` | 8.5: keep | 7.8: reference only | Current V3 | Keep V3 unchanged |
| `lab_console` | 8.6: keep | 7.9: reference only | Current V3 | Keep V3 unchanged |
| `memory_tank` | 8.8: keep | 8.0: reference only | Current V3 | Keep V3 unchanged |
| `root_circuit_rail` | 8.7: keep | 8.0: reference only | Current V3 | Keep V3 unchanged |

## 4. Actual Usage Audit
| Region ID | Usage Found | Scenes/Scripts | Priority | Notes |
|---|---|---|---|---|
| `oakhaven_roof` | Yes | scripts/regions/oakhaven_region.gd | High | Used inside generated Oakhaven building roof composition. |
| `oakhaven_hedge_corner` | Yes | scripts/regions/oakhaven_region.gd | High | Used twice in Oakhaven hedge polish. |
| `oakhaven_flowers` | Yes | scripts/regions/oakhaven_region.gd | High | Used twice as meadow/village flower accents. |
| `oakhaven_herb_sign` | Yes | scripts/regions/oakhaven_region.gd | Medium | Used as outskirts herb sign. |
| `ironhold_pipes` | Yes | scripts/regions/ironhold_region.gd | High | Used twice in Ironhold polish. |
| `ironhold_forge` | Yes | scripts/regions/ironhold_region.gd | High | Used in Ironhold training/forge area. |
| `crates` | Yes | scripts/regions/ironhold_region.gd, scripts/regions/late_revisit_hub.gd, scripts/combat/combat_arena.gd | High | Shared cross-region prop plate; most broadly reused. |
| `archive_shelves` | Yes | scripts/regions/late_revisit_hub.gd | Medium | Forgotten archive hub variant. |
| `dossier_stack` | Yes | scripts/regions/late_revisit_hub.gd | Medium | Forgotten archive hub variant. |
| `null_seal` | Yes | scripts/regions/late_revisit_hub.gd | Medium | Forgotten archive/null seal variant. |
| `mirror_plinth` | Yes | scripts/regions/late_revisit_hub.gd | Medium | Mirror hub variant. |
| `server_console` | Yes | scripts/regions/late_revisit_hub.gd, scripts/chapter6/ch6_choir_core.gd | High | Late hub and chapter 6 digital/cathedral props. |
| `firewall_panel` | Yes | scripts/regions/late_revisit_hub.gd, scripts/chapter6/ch6_choir_core.gd | High | Late hub and chapter 6 prop. |
| `tide_buoy` | Yes | scripts/regions/late_revisit_hub.gd | Medium | Memory ocean hub variant. |
| `salvage_shelf` | Yes | scripts/regions/late_revisit_hub.gd | Medium | Memory ocean hub variant. |
| `ocean_cache` | Yes | scripts/regions/late_revisit_hub.gd | Medium | Memory ocean hub variant. |
| `lab_console` | Yes | scripts/regions/late_revisit_hub.gd | High | Human patch lab hub variant. |
| `memory_tank` | Yes | scripts/regions/late_revisit_hub.gd | High | Human patch lab hub variant, used twice. |
| `root_circuit_rail` | Yes | scripts/regions/late_revisit_hub.gd | High | Root of Heaven hub variant. |

## 5. Screenshot / Preview Evidence
| Area | Evidence Path | Result | Notes |
|---|---|---|---|
| crop comparison sheet | `assets/art_sources/comfyui_tests/shared_environment_s4_v3_prop_audit/crop_reviews/shared_env_s4_all_prop_region_comparison.png` | Created | All 19 regions compared against S1/S3. |
| weak region focus sheet | `assets/art_sources/comfyui_tests/shared_environment_s4_v3_prop_audit/crop_reviews/shared_env_s4_weak_region_focus_sheet.png` | Created | Controversial regions still favor current V3. |
| Oakhaven reference | `res://scenes/regions/oakhaven_region.tscn` | Scene load Pass; screenshot skipped | Headless dummy renderer cannot capture reliable scene screenshots. |
| Ironhold reference | `res://scenes/regions/ironhold_region.tscn` | Scene load Pass; screenshot skipped | Headless dummy renderer cannot capture reliable scene screenshots. |
| Fractured Wastes reference | `res://scenes/regions/fractured_wastes_region.tscn` | Scene load Pass; screenshot skipped | Headless dummy renderer cannot capture reliable scene screenshots. |
| late hub reference | `res://scenes/regions/late_revisit_hub.tscn` | Skipped | Scene path not found; usage was confirmed from `scripts/regions/late_revisit_hub.gd`. |
| arena reference | `res://scenes/combat/combat_arena.tscn` | Scene load Pass; screenshot skipped | Headless dummy renderer cannot capture reliable scene screenshots. |
| full contact sheet | `assets/art_sources/comfyui_tests/shared_environment_s4_v3_prop_audit/contact_sheets/shared_env_s4_full_review_contact_sheet.png` | Created | V3 baseline compared to S3 B in controlled boards. |

## 6. Region-by-Region Scores
| Region ID | Current V3 Score | S3 B Score | Keep/Repair Decision | Reason |
|---|---:|---:|---|---|
| `oakhaven_roof` | 8.8 | 7.8 | Keep V3 unchanged | V3 roof is more detailed and production-like; S3 remains symbolic. |
| `oakhaven_hedge_corner` | 8.5 | 7.9 | Keep V3 unchanged | V3 foliage has better organic texture and shape language. |
| `oakhaven_flowers` | 8.7 | 7.7 | Keep V3 unchanged | V3 flowers read as distinct plants; S3 is a cleaner scatter but less refined. |
| `oakhaven_herb_sign` | 8.6 | 7.4 | Keep V3 unchanged | V3 sign has stronger material and garden detail. |
| `ironhold_pipes` | 8.5 | 8.0 | Keep V3 unchanged | S3 is cleaner, but V3 pipe forms remain more dimensional. |
| `ironhold_forge` | 8.9 | 7.6 | Keep V3 unchanged | V3 forge is clearly more production-like. |
| `crates` | 8.4 | 7.9 | Keep V3 unchanged | V3 shared crate plate is more polished and varied. |
| `archive_shelves` | 8.6 | 8.0 | Keep V3 unchanged | S3 is cleaner, but V3 shelves carry stronger prop detail. |
| `dossier_stack` | 8.5 | 7.7 | Keep V3 unchanged | V3 stack has better material specificity. |
| `null_seal` | 8.4 | 7.9 | Keep V3 unchanged | V3 seal has stronger engraved surface detail. |
| `mirror_plinth` | 8.7 | 7.9 | Keep V3 unchanged | V3 plinth reads as a finished prop; S3 is placeholder-like. |
| `server_console` | 8.6 | 8.0 | Keep V3 unchanged | S3 is readable, but V3 console bank has stronger screen/body detail. |
| `firewall_panel` | 8.5 | 8.0 | Keep V3 unchanged | V3 panel detail remains more refined. |
| `tide_buoy` | 8.4 | 7.8 | Keep V3 unchanged | V3 buoy has a more finished silhouette. |
| `salvage_shelf` | 8.6 | 8.0 | Keep V3 unchanged | V3 salvage cluster is richer and more region-specific. |
| `ocean_cache` | 8.5 | 7.8 | Keep V3 unchanged | V3 cache has stronger natural/storage identity. |
| `lab_console` | 8.6 | 7.9 | Keep V3 unchanged | V3 lab console has stronger appliance silhouette. |
| `memory_tank` | 8.8 | 8.0 | Keep V3 unchanged | V3 tank is more dimensional and polished. |
| `root_circuit_rail` | 8.7 | 8.0 | Keep V3 unchanged | V3 rail is busier, but it is more visually complete and thematic. |

## 7. Decal Path Recommendation
S1 decal candidate should continue separately because S2 showed it was cleaner and more readable than current V3 decals in preview. Current V3 decals should remain active until a controlled decal-only validation/import pass proves replacement safety. Decal import is not blocked by rejecting the full prop replacement. The safest next step is a decal-focused validation pass using current V3 props as the stable baseline.

## 8. Project Safety Validation
| Test | Result | Notes |
|---|---|---|
| discovered Godot path | Pass | `C:\Godot\Godot_v4.6.3-stable_win64_console.exe` |
| Godot version | Pass | `4.6.3.stable.official.7d41c59c4` |
| project boot | Pass | Headless project boot completed. |
| main menu | Pass | Loaded by S4 validation script. |
| Oakhaven baseline preservation | Pass | `assets/production_art/tilesets/oakhaven/oakhaven_afternoon_tileset.png` loaded. |
| Ironhold baseline preservation | Pass | `assets/production_art/tilesets/ironhold/ironhold_tileset.png` loaded. |
| Fractured Wastes baseline preservation | Pass | `assets/production_art/tilesets/fractured_wastes/fractured_wastes_tileset.png` loaded. |
| AssetManager V3 prop/decal fallback | Pass | Current V3 prop/decal sprites instantiated; production slots absent. |
| no production_art overwrite | Pass | Shared prop/decal production slots remain absent. |
| no generated_v3 overwrite | Pass | Current generated V3 prop/decal atlas paths were not modified. |
| no gameplay scene/script modification | Pass | S4 writes only art_sources/docs outputs. |
| git diff --check | Pass | No whitespace errors reported. |

## 9. Honest Visual Verdict
Current V3 looks better than S3 overall. S3 props should not be imported. The full prop replacement pipeline should stop because S3 does not clearly beat current V3 in the high-priority actual-use regions. No V3 prop region has enough objective evidence to justify targeted repair now. Current V3 props should remain active. S1/S3 prop candidates should remain reference-only. The next useful step is a decal-focused validation path, not more full prop replacement work.

## 10. Decision
Keep current V3 props unchanged and move to decal validation
