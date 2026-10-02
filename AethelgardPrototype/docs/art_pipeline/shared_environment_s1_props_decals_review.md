# PHASE 10M-S1 SHARED ENVIRONMENT PROPS + DECALS CONTROLLED BUILDER REPORT

## 1. Summary
- Contract audit completed: Yes
- Prop atlas candidate created: Yes, Variant B plus A/C review variants
- Decal atlas candidate created: Yes, Variant B plus A/C review variants
- Mockups created: Yes
- Production art changed: No
- Current generated assets overwritten: No
- Overall verdict: S1 candidates preserve the current 1536x1024 hard-coded region contract and are suitable for preview-only Godot validation, not production import.

## 2. Contract Audit
| Asset | Path | Dimensions | Usage Found | Hardcoded Regions | Replacement Risk | Notes |
|---|---|---|---|---|---|---|
| current generated prop atlas | `assets/generated_v3/props/phase10mm_environment_prop_atlas.png` | 1536x1024 RGBA | Cropped by `AssetManager.try_create_v3_environment_prop` | Yes, 19 named `Rect2i` regions | Medium | Replacement must preserve exact region rectangles or revise the contract. |
| current generated decal atlas | `assets/generated_v3/overlays/phase10mm_environment_decal_atlas.png` | 1536x1024 RGBA | Cropped by `AssetManager.try_create_v3_environment_decal` | Yes, 11 named `Rect2i` regions | Medium | Broad floor plates; exact coordinates matter. |
| planned production prop slot | `assets/production_art/props/environment_prop_atlas.png` | absent | AssetManager production-first fallback slot | N/A | Medium | Not written in S1. |
| planned production decal slot | `assets/production_art/backgrounds/environment_decal_atlas.png` | absent | AssetManager production-first fallback slot | N/A | Medium | Not written in S1. |

## 3. Files Created
| File | Purpose | Status |
|---|---|---|
| `assets/art_sources/comfyui_tests/shared_environment_s1/generated_props/shared_environment_props_s1_variant_b.png` | Primary prop candidate | Created |
| `assets/art_sources/comfyui_tests/shared_environment_s1/generated_decals/shared_environment_decals_s1_variant_b.png` | Primary decal candidate | Created |
| `assets/art_sources/comfyui_tests/shared_environment_s1/mockups/shared_env_s1_oakhaven_mockup.png` | Oakhaven review mockup | Created |
| `assets/art_sources/comfyui_tests/shared_environment_s1/mockups/shared_env_s1_ironhold_mockup.png` | Ironhold review mockup | Created |
| `assets/art_sources/comfyui_tests/shared_environment_s1/mockups/shared_env_s1_fractured_wastes_mockup.png` | Fractured Wastes review mockup | Created |
| `assets/art_sources/comfyui_tests/shared_environment_s1/mockups/shared_env_s1_arena_mockup.png` | Arena/combat review mockup | Created |
| `assets/art_sources/comfyui_tests/shared_environment_s1/contact_sheets/shared_env_s1_full_review_contact_sheet.png` | Full review sheet | Created |
| `assets/art_sources/comfyui_tests/shared_environment_s1/manifest/shared_environment_s1_contract_audit.md` | Contract audit | Created |
| `assets/art_sources/comfyui_tests/shared_environment_s1/manifest/shared_environment_s1_generation_manifest.json` | Generation manifest | Created |
| `docs/art_pipeline/shared_environment_s1/shared_environment_s1_validation.gd` | Validation script | Created |

## 4. Prop Atlas Layout Summary
| Region / Row Range | Category | Included Props |
|---|---|---|
| Existing Oakhaven regions | Village props | roof strip, hedge/bushes, flowers, herbs, sign, bucket, pot |
| Existing Ironhold regions | Industrial props | pipes, valves, gears, forge, anvil/control forms |
| `crates` region | Shared neutral props | small/large crates, barrels, sack/chest/table/bench/fence/rubble studies |
| Late hub regions | Digital-magical props | shelves, dossiers, seals, terminals, server plates, memory tanks, root rail |
| Additive unused micro cells | Review-only utility | crystals, crates, terminals; not current runtime contract |

## 5. Decal Atlas Layout Summary
| Region / Row Range | Category | Included Decals |
|---|---|---|
| Existing Oakhaven regions | Meadow/path decals | dirt-path blend, stones, grass tufts, leaf scatter |
| Existing Ironhold region | Industrial decals | road plates, soot/oil, scratches, rivets, warm scuffs |
| Existing Fractured Wastes regions | Corruption decals | fracture field, shard spill, purple scars, hazard accents |
| Existing late hub regions | Digital-magical decals | archive seals, mirror ripples, circuits, memory tide, root veins |
| Existing arena region | Combat decals | arena scuff, support ring, impact/scrape marks |
| Additive unused micro cells | Review-only utility | shadow/glow/spark/scratch swatches; not current runtime contract |

## 6. Prop Atlas Quality Review
| Category | Score | Notes |
|---|---:|---|
| silhouette readability | 8.0 | Props read clearly at review scale; broad regions still limit atomic use. |
| region coverage | 8.3 | Covers Oakhaven, Ironhold, Fractured Wastes, late hubs, and combat crates. |
| scale consistency | 7.6 | Current broad region contract mixes scene plates and small props. |
| alpha cleanliness | 8.4 | Transparent background preserved. |
| shadow grounding | 8.0 | Small cast shadows added consistently. |
| improvement over current generated V3 props | 8.1 | Cleaner and more intentional than the generated atlas, pending in-engine validation. |

## 7. Decal Atlas Quality Review
| Category | Score | Notes |
|---|---:|---|
| alpha cleanliness | 8.5 | Transparent background preserved with low-opacity decals. |
| organic edge quality | 7.8 | Edges are softer and less slab-like, though still deterministic. |
| subtlety | 8.0 | Decals avoid fully opaque blocks. |
| arena readability | 8.1 | Warning area remains readable in arena mockup. |
| improvement over current generated V3 decals | 8.0 | Better organized and less noisy, pending in-engine validation. |

## 8. Mockup Review
| Mockup | Path | Readability | Region Fit | Verdict |
|---|---|---|---|---|
| Oakhaven | `assets/art_sources/comfyui_tests/shared_environment_s1/mockups/shared_env_s1_oakhaven_mockup.png` | Good | Good | Ready for preview validation. |
| Ironhold | `assets/art_sources/comfyui_tests/shared_environment_s1/mockups/shared_env_s1_ironhold_mockup.png` | Good | Good | Ready for preview validation. |
| Fractured Wastes | `assets/art_sources/comfyui_tests/shared_environment_s1/mockups/shared_env_s1_fractured_wastes_mockup.png` | Good | Good | Ready for preview validation. |
| Arena/combat | `assets/art_sources/comfyui_tests/shared_environment_s1/mockups/shared_env_s1_arena_mockup.png` | Good | Good | Ready for preview validation. |

## 9. Comparison Against Current Generated V3 Assets
| Area | Current Generated V3 | S1 Candidate | Better/Worse |
|---|---|---|---|
| props | Large generated crops, uneven visual intent | Cleaner controlled silhouettes and shadows | Better |
| decals | Broad generated overlay plates | More deliberate low-opacity overlays | Better |
| alpha | Present | Preserved | Same/better |
| shadows | Inconsistent | More consistent cast shadows | Better |
| region identity | Present but uneven | More region-specific | Better |
| combat readability | Functional but busy | Warning support remains readable | Better |
| overall usefulness | Useful fallback | Better review candidate | Better |

## 10. Project Safety Validation
| Test | Result | Notes |
|---|---|---|
| discovered Godot path | Pass | `C:\Godot\Godot_v4.6.3-stable_win64_console.exe` |
| Godot version | Pass | `4.6.3.stable.official.7d41c59c4` |
| project boot | Pass | Headless boot completed. |
| main menu | Pass | `res://scenes/main_menu.tscn` instantiated by validation script. |
| Oakhaven baseline preservation | Pass | Oakhaven afternoon production atlas exists and loads through file fallback. |
| Ironhold baseline preservation | Pass | Ironhold Variant B production atlas exists and loads through file fallback. |
| Fractured Wastes baseline preservation | Pass | Fractured Wastes Variant B production atlas exists and loads through file fallback. |
| no production_art overwrite | Pass | Production prop/decal slots remain absent. |
| no generated_v3 overwrite | Pass | Current generated V3 prop/decal atlases remain unchanged by S1 outputs. |
| git diff --check | Pass | No whitespace errors reported. |

## 11. Honest Visual Verdict

The S1 prop candidates are better than the current generated V3 props as review art: they have clearer silhouettes, cleaner alpha, more consistent grounding, and stronger region identity. The S1 decal candidates are also better as review art: they are more transparent, less slab-like, and better organized by region.

The existing contract is clear enough to build candidates because `AssetManager` exposes the exact hard-coded rectangles. It is not sufficient to declare production readiness in this phase; the candidates need preview-only Godot validation because the live scenes scale and tint these broad regions heavily.

These are ready for preview-only Godot validation. They are not ready for production_art import in S1.

What still needs improvement: verify broad cropped regions under actual scene tint/scale, decide whether additive micro cells should become a formal contract later, and repair any region whose current rectangle mixes too many unrelated props.

## 12. Decision

Ready for shared props/decals preview-only Godot validation pass
