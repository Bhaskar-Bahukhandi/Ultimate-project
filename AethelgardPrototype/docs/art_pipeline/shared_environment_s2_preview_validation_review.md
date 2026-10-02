# PHASE 10M-S2 SHARED ENVIRONMENT PROPS + DECALS PREVIEW-ONLY VALIDATION REPORT

## 1. Summary

* AGENTS.md read: Yes
* S1 typo/misplaced-file check: No misplaced `comfy_tests` folder found; no correction required
* Preview-only validation created: Yes
* Prop candidate validated: Yes
* Decal candidate validated: Yes
* Production art changed: No
* Generated V3 assets overwritten: No
* Actual gameplay scenes modified: No
* Overall verdict: S1 crops align with the hard-coded contract, decals are promising, but the prop atlas is too simplified versus current V3 in several broad regions. Repair props before import.

## 2. Input Verification

| Input | Path | Status | Notes |
|---|---|---|---|
| current V3 prop atlas | `assets/generated_v3/props/phase10mm_environment_prop_atlas.png` | Pass | 1536x1024 RGBA, alpha present. |
| current V3 decal atlas | `assets/generated_v3/overlays/phase10mm_environment_decal_atlas.png` | Pass | 1536x1024 RGBA, alpha present. |
| S1 prop candidate | `assets/art_sources/comfyui_tests/shared_environment_s1/generated_props/shared_environment_props_s1_variant_b.png` | Pass | 1536x1024 RGBA, alpha present. |
| S1 decal candidate | `assets/art_sources/comfyui_tests/shared_environment_s1/generated_decals/shared_environment_decals_s1_variant_b.png` | Pass | 1536x1024 RGBA, alpha present. |
| S1 audit docs | `assets/art_sources/comfyui_tests/shared_environment_s1/manifest/` | Pass | Audit, layout, and generation manifests present. |
| production slots absent | `assets/production_art/props/environment_prop_atlas.png`, `assets/production_art/backgrounds/environment_decal_atlas.png` | Pass | Both absent. |
| generated V3 unchanged | current V3 prop/decal atlas paths | Pass | No overwrite performed by S2. |

## 3. S1 Path Correction Check

| Check | Result | Action |
|---|---|---|
| `assets/art_sources/comfy_tests/shared_environment_s1/` | Missing | No move required. |
| `assets/art_sources/comfyui_tests/shared_environment_s1/` | Present | Used as source. |
| Correction made | No | The S1 report path was a typo only. |

## 4. AssetManager Region Contract

| Atlas | Region ID | Rect2i | Crop Valid | Runtime Usage | Risk |
|---|---|---|---|---|---|
| props | `oakhaven_roof` | `(32, 22, 248, 190)` | Pass | `try_create_v3_environment_prop` / `AtlasTexture` crop | Medium |
| props | `oakhaven_hedge_corner` | `(760, 52, 390, 176)` | Pass | `try_create_v3_environment_prop` / `AtlasTexture` crop | Medium |
| props | `oakhaven_flowers` | `(30, 264, 418, 82)` | Pass | `try_create_v3_environment_prop` / `AtlasTexture` crop | Medium |
| props | `oakhaven_herb_sign` | `(478, 238, 128, 126)` | Pass | `try_create_v3_environment_prop` / `AtlasTexture` crop | Medium |
| props | `ironhold_pipes` | `(616, 238, 544, 170)` | Pass | `try_create_v3_environment_prop` / `AtlasTexture` crop | Medium |
| props | `ironhold_forge` | `(1320, 226, 164, 194)` | Pass | `try_create_v3_environment_prop` / `AtlasTexture` crop | Medium |
| props | `crates` | `(40, 434, 540, 144)` | Pass | `try_create_v3_environment_prop` / `AtlasTexture` crop | Medium |
| props | `archive_shelves` | `(620, 370, 356, 218)` | Pass | `try_create_v3_environment_prop` / `AtlasTexture` crop | Medium |
| props | `dossier_stack` | `(988, 440, 94, 128)` | Pass | `try_create_v3_environment_prop` / `AtlasTexture` crop | Medium |
| props | `null_seal` | `(1092, 432, 156, 176)` | Pass | `try_create_v3_environment_prop` / `AtlasTexture` crop | Medium |
| props | `mirror_plinth` | `(1280, 430, 202, 192)` | Pass | `try_create_v3_environment_prop` / `AtlasTexture` crop | Medium |
| props | `server_console` | `(36, 612, 376, 194)` | Pass | `try_create_v3_environment_prop` / `AtlasTexture` crop | Medium |
| props | `firewall_panel` | `(430, 612, 358, 194)` | Pass | `try_create_v3_environment_prop` / `AtlasTexture` crop | Medium |
| props | `tide_buoy` | `(824, 610, 120, 182)` | Pass | `try_create_v3_environment_prop` / `AtlasTexture` crop | Medium |
| props | `salvage_shelf` | `(974, 610, 290, 198)` | Pass | `try_create_v3_environment_prop` / `AtlasTexture` crop | Medium |
| props | `ocean_cache` | `(1268, 610, 236, 198)` | Pass | `try_create_v3_environment_prop` / `AtlasTexture` crop | Medium |
| props | `lab_console` | `(34, 818, 248, 178)` | Pass | `try_create_v3_environment_prop` / `AtlasTexture` crop | Medium |
| props | `memory_tank` | `(292, 814, 170, 186)` | Pass | `try_create_v3_environment_prop` / `AtlasTexture` crop | Medium |
| props | `root_circuit_rail` | `(628, 816, 844, 190)` | Pass | `try_create_v3_environment_prop` / `AtlasTexture` crop | Medium |
| decals | `oakhaven_path` | `(18, 10, 630, 198)` | Pass | `try_create_v3_environment_decal` / `AtlasTexture` crop | Medium |
| decals | `oakhaven_stones` | `(22, 228, 650, 128)` | Pass | `try_create_v3_environment_decal` / `AtlasTexture` crop | Medium |
| decals | `ironhold_road` | `(676, 16, 820, 224)` | Pass | `try_create_v3_environment_decal` / `AtlasTexture` crop | Medium |
| decals | `fracture_field` | `(18, 360, 500, 294)` | Pass | `try_create_v3_environment_decal` / `AtlasTexture` crop | Medium |
| decals | `shard_spill` | `(270, 350, 246, 298)` | Pass | `try_create_v3_environment_decal` / `AtlasTexture` crop | Medium |
| decals | `archive_seals` | `(520, 362, 382, 292)` | Pass | `try_create_v3_environment_decal` / `AtlasTexture` crop | Medium |
| decals | `mirror_ripples` | `(900, 246, 602, 280)` | Pass | `try_create_v3_environment_decal` / `AtlasTexture` crop | Medium |
| decals | `cathedral_circuit` | `(900, 510, 600, 240)` | Pass | `try_create_v3_environment_decal` / `AtlasTexture` crop | Medium |
| decals | `memory_tide` | `(14, 674, 476, 326)` | Pass | `try_create_v3_environment_decal` / `AtlasTexture` crop | Medium |
| decals | `root_veins` | `(492, 680, 406, 320)` | Pass | `try_create_v3_environment_decal` / `AtlasTexture` crop | Medium |
| decals | `arena_border` | `(898, 754, 620, 252)` | Pass | `try_create_v3_environment_decal` / `AtlasTexture` crop | Medium |

Total prop regions: 19. Total decal regions: 11. Exact region preservation is required for a no-code production import.

## 5. Crop Contract Validation

| Atlas | Region ID | Current Crop | Candidate Crop | Alignment | Risk | Verdict |
|---|---|---|---|---|---|---|
| props | `oakhaven_roof` | nonblank | nonblank | aligned | low/medium | safe for preview |
| props | `oakhaven_hedge_corner` | nonblank | nonblank | aligned | low/medium | safe for preview |
| props | `oakhaven_flowers` | nonblank | nonblank | aligned | low/medium | safe for preview |
| props | `oakhaven_herb_sign` | nonblank | nonblank | aligned | low/medium | safe for preview |
| props | `ironhold_pipes` | nonblank | nonblank | aligned | low/medium | safe for preview |
| props | `ironhold_forge` | nonblank | nonblank | aligned | low/medium | safe for preview |
| props | `crates` | nonblank | nonblank | aligned | low/medium | safe for preview |
| props | `archive_shelves` | nonblank | nonblank | aligned | low/medium | safe for preview |
| props | `dossier_stack` | nonblank | nonblank | aligned | low/medium | safe for preview |
| props | `null_seal` | nonblank | nonblank | aligned | low/medium | safe for preview |
| props | `mirror_plinth` | nonblank | nonblank | aligned | low/medium | safe for preview |
| props | `server_console` | nonblank | nonblank | aligned | low/medium | safe for preview |
| props | `firewall_panel` | nonblank | nonblank | aligned | low/medium | safe for preview |
| props | `tide_buoy` | nonblank | nonblank | aligned | low/medium | safe for preview |
| props | `salvage_shelf` | nonblank | nonblank | aligned | low/medium | safe for preview |
| props | `ocean_cache` | nonblank | nonblank | aligned | low/medium | safe for preview |
| props | `lab_console` | nonblank | nonblank | aligned | low/medium | safe for preview |
| props | `memory_tank` | nonblank | nonblank | aligned | low/medium | safe for preview |
| props | `root_circuit_rail` | nonblank | nonblank | aligned | low/medium | safe for preview |
| decals | `oakhaven_path` | nonblank | nonblank | aligned | low/medium | safe for preview |
| decals | `oakhaven_stones` | nonblank | nonblank | aligned | low/medium | safe for preview |
| decals | `ironhold_road` | nonblank | nonblank | aligned | low/medium | safe for preview |
| decals | `fracture_field` | nonblank | nonblank | aligned | low/medium | safe for preview |
| decals | `shard_spill` | nonblank | nonblank | aligned | low/medium | safe for preview |
| decals | `archive_seals` | nonblank | nonblank | aligned | low/medium | safe for preview |
| decals | `mirror_ripples` | nonblank | nonblank | aligned | low/medium | safe for preview |
| decals | `cathedral_circuit` | nonblank | nonblank | aligned | low/medium | safe for preview |
| decals | `memory_tide` | nonblank | nonblank | aligned | low/medium | safe for preview |
| decals | `root_veins` | nonblank | nonblank | aligned | low/medium | safe for preview |
| decals | `arena_border` | nonblank | nonblank | aligned | low/medium | safe for preview |

Prop crop contract sheet: `assets/art_sources/comfyui_tests/shared_environment_s2_preview/crop_checks/shared_env_s2_prop_crop_contract_check.png`

Decal crop contract sheet: `assets/art_sources/comfyui_tests/shared_environment_s2_preview/crop_checks/shared_env_s2_decal_crop_contract_check.png`

## 6. Preview Boards / Screenshot Evidence

| Board | Current Screenshot | Candidate Screenshot | Contact Sheet | Verdict |
|---|---|---|---|---|
| Oakhaven | `assets/art_sources/comfyui_tests/shared_environment_s2_preview/screenshots/shared_env_s2_oakhaven_current.png` | `assets/art_sources/comfyui_tests/shared_environment_s2_preview/screenshots/shared_env_s2_oakhaven_candidate.png` | `assets/art_sources/comfyui_tests/shared_environment_s2_preview/contact_sheets/shared_env_s2_oakhaven_current_vs_candidate.png` | Candidate readable; props simpler than current. |
| Ironhold | `assets/art_sources/comfyui_tests/shared_environment_s2_preview/screenshots/shared_env_s2_ironhold_current.png` | `assets/art_sources/comfyui_tests/shared_environment_s2_preview/screenshots/shared_env_s2_ironhold_candidate.png` | `assets/art_sources/comfyui_tests/shared_environment_s2_preview/contact_sheets/shared_env_s2_ironhold_current_vs_candidate.png` | Decals improve readability; props lose richness. |
| Fractured Wastes | `assets/art_sources/comfyui_tests/shared_environment_s2_preview/screenshots/shared_env_s2_fractured_wastes_current.png` | `assets/art_sources/comfyui_tests/shared_environment_s2_preview/screenshots/shared_env_s2_fractured_wastes_candidate.png` | `assets/art_sources/comfyui_tests/shared_environment_s2_preview/contact_sheets/shared_env_s2_fractured_wastes_current_vs_candidate.png` | Candidate decals cleaner; prop detail needs repair. |
| Arena/combat | `assets/art_sources/comfyui_tests/shared_environment_s2_preview/screenshots/shared_env_s2_arena_current.png` | `assets/art_sources/comfyui_tests/shared_environment_s2_preview/screenshots/shared_env_s2_arena_candidate.png` | `assets/art_sources/comfyui_tests/shared_environment_s2_preview/contact_sheets/shared_env_s2_arena_current_vs_candidate.png` | Candidate warning readability good. |

## 7. Actual Scene Reference Checks

| Scene | Result | Notes |
|---|---|---|
| Main menu | Pass | Loaded by S2 validation script without scene edits. |
| Oakhaven region | Pass | Read-only scene load; accepted baseline remained available. |
| Ironhold region | Pass | Read-only scene load; accepted baseline remained available. |
| Fractured Wastes region | Pass | Read-only scene load; accepted baseline remained available. |
| Combat/Tutorial arena | Skipped | S2 board validates arena prop/decal contract; no gameplay arena scene swap was performed. |

## 8. Prop Atlas Quality Scores

| Category | Current V3 Score | S1 Candidate Score | Verdict |
|---|---:|---:|---|
| crop contract alignment | 8.8 | 8.5 | Candidate aligns. |
| silhouette readability | 8.4 | 7.6 | Current richer. |
| region coverage | 8.7 | 8.4 | Candidate covers regions. |
| scale consistency | 7.4 | 7.2 | Contract remains mixed. |
| alpha cleanliness | 8.0 | 8.7 | Candidate cleaner. |
| shadow grounding | 8.2 | 7.8 | Candidate consistent but simpler. |
| Oakhaven compatibility | 8.2 | 7.8 | Candidate readable, less rich. |
| Ironhold compatibility | 8.4 | 7.4 | Candidate too sparse in industrial regions. |
| Fractured Wastes compatibility | 8.1 | 7.6 | Candidate readable, less atmospheric. |
| arena/combat compatibility | 7.8 | 7.6 | Candidate readable but simpler. |
| overall | 8.1 | 7.8 | Needs prop repair before import. |

## 9. Decal Atlas Quality Scores

| Category | Current V3 Score | S1 Candidate Score | Verdict |
|---|---:|---:|---|
| crop contract alignment | 8.8 | 8.4 | Candidate aligns. |
| alpha cleanliness | 8.0 | 8.8 | Candidate cleaner. |
| organic edge quality | 8.3 | 7.7 | Current richer; candidate more controlled. |
| opacity/subtlety | 7.1 | 8.4 | Candidate better. |
| label readability | 7.5 | 8.1 | Candidate less busy. |
| warning telegraph readability | 7.4 | 8.1 | Candidate better in arena board. |
| Oakhaven compatibility | 8.0 | 8.0 | Comparable. |
| Ironhold compatibility | 7.7 | 8.1 | Candidate improves readability. |
| Fractured Wastes compatibility | 7.9 | 8.2 | Candidate cleaner. |
| arena/combat compatibility | 7.6 | 8.1 | Candidate better. |
| overall | 7.9 | 8.2 | Decals are import-candidate quality after prop repair. |

## 10. Project Safety Validation

| Test | Result | Notes |
|---|---|---|
| discovered Godot path | Pass | `C:\Godot\Godot_v4.6.3-stable_win64_console.exe` |
| Godot version | Pass | `4.6.3.stable.official.7d41c59c4` |
| project boot | Pass | Headless project boot completed. |
| main menu | Pass | Loaded by S2 validation script. |
| S2 preview-only capture | Pass | Runtime crop probe saved to `assets/art_sources/comfyui_tests/shared_environment_s2_preview/crop_checks/shared_env_s2_godot_runtime_crop_probe.png`. |
| AssetManager current V3 fallback prop/decal check | Pass | Current V3 prop/decal sprites instantiated through AssetManager fallback. |
| Oakhaven baseline preservation | Pass | `assets/production_art/tilesets/oakhaven/oakhaven_afternoon_tileset.png` loaded. |
| Ironhold baseline preservation | Pass | `assets/production_art/tilesets/ironhold/ironhold_tileset.png` loaded. |
| Fractured Wastes baseline preservation | Pass | `assets/production_art/tilesets/fractured_wastes/fractured_wastes_tileset.png` loaded. |
| no production_art overwrite | Pass | Shared prop/decal production slots remain absent; no production paths were written. |
| no generated_v3 overwrite | Pass | Current generated V3 prop/decal atlas paths were not modified. |
| no gameplay scene/script modification | Pass | Focused git status shows only S2 docs/art_sources outputs. |
| git diff --check | Pass | No whitespace errors reported. |

## 11. Honest Visual Verdict

S1 prop candidates are contract-aligned but not clearly better than current generated V3 props in contract-cropped preview. They are cleaner, but the current generated V3 prop atlas is richer and more production-like in several broad regions. Props need repair before import.

S1 decal candidates are better than current generated V3 decals in opacity control, label readability, and warning telegraph readability. No crop regions appear misaligned. The contract is safe enough for a later controlled import only after prop repair and one more preview validation.

These are not ready for production_art import yet.

## 12. Decision

Needs prop atlas repair before import
