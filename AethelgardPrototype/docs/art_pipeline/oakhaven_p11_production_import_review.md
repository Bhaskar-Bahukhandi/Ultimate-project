# Phase 10M-P11 Controlled Oakhaven Production-Art Import Review

## 1. Summary

Phase 10M-P11 imported the tuned P10 Oakhaven morning, afternoon, and night atlases into controlled production-art slots. AssetManager now resolves Oakhaven visual tiles through a safe time-state loader with generated fallback preservation. The real Oakhaven scene was not edited, but its existing visual-only `AssetManager.try_create_v2_visual_tile_layer("oakhaven", ...)` call now resolves to production afternoon by default.

Overall verdict: production afternoon is better than the generated fallback in the actual Oakhaven scene, but morning/night are staged only through loader and preview-board validation. Accept afternoon first; delay full morning/night gameplay enablement until a later time-system phase.

## 2. Input Verification

| Input | Source Path | Status | Notes |
| --- | --- | --- | --- |
| P10 morning tuned atlas | `assets/art_sources/comfyui_tests/oakhaven_p10_palette_tuning/tuned_atlases/oakhaven_p10_morning_tuned.png` | Pass | 512x512 RGBA, nonblank. |
| P10 afternoon tuned atlas | `assets/art_sources/comfyui_tests/oakhaven_p10_palette_tuning/tuned_atlases/oakhaven_p10_afternoon_tuned.png` | Pass | 512x512 RGBA, nonblank. |
| P10 night tuned atlas | `assets/art_sources/comfyui_tests/oakhaven_p10_palette_tuning/tuned_atlases/oakhaven_p10_night_tuned.png` | Pass | 512x512 RGBA, nonblank. |
| P10 screenshots | `assets/art_sources/comfyui_tests/oakhaven_p10_palette_tuning/screenshots/` | Pass | Morning/afternoon/night preview references exist. |
| P10 review doc | `docs/art_pipeline/oakhaven_p10_palette_tuning_review.md` | Pass | Decision supported production import pass. |
| P8 layout map | `assets/art_sources/comfyui_tests/oakhaven_p8/manifest/oakhaven_p8_tile_layout.md` | Pass | Shared 32x32 coordinate grammar. |
| Generated fallback | `assets/generated_v2/tilesets/oakhaven_v2_prototype_tileset.png` | Pass | Still present and loadable. |

## 3. Production Files Created

| File | Purpose | Validation Result |
| --- | --- | --- |
| `assets/production_art/tilesets/oakhaven/oakhaven_morning_tileset.png` | Morning production candidate | Pass: 512x512 RGBA, nonblank. |
| `assets/production_art/tilesets/oakhaven/oakhaven_afternoon_tileset.png` | Default Oakhaven production candidate | Pass: 512x512 RGBA, nonblank. |
| `assets/production_art/tilesets/oakhaven/oakhaven_night_tileset.png` | Night production candidate | Pass: 512x512 RGBA, nonblank. |
| `assets/production_art/tilesets/oakhaven/oakhaven_time_of_day_manifest.json` | Production import metadata | Pass: JSON valid. |
| `assets/production_art/tilesets/oakhaven/README.md` | Lineage and fallback notes | Pass. |

## 4. AssetManager / Loader Changes

| Function/Path | Change | Risk | Result |
| --- | --- | --- | --- |
| `scripts/asset_manager.gd` production table | Oakhaven production visual slot now points to `oakhaven_afternoon_tileset.png`. | Low: Oakhaven visual-only layer already used AssetManager. | Pass. |
| `get_oakhaven_tileset(time_state := "afternoon")` | New public texture getter. | Low: additive API. | Pass. |
| `get_oakhaven_tileset_slot(time_state := "afternoon")` | New metadata-rich resolver for production/fallback status. | Low: additive API. | Pass. |
| Oakhaven time-state normalization | Empty/invalid states resolve to afternoon. | Low. | Pass; `dusk` resolves to afternoon. |
| Missing variant behavior | Missing morning/night can fall back to afternoon; missing/default failure falls back to generated V2. | Low. | Pass via controlled missing-path probe. |
| `try_create_v2_visual_tile_layer(..., time_state := "afternoon")` | Existing callers preserved; optional time state added at end. | Low: compatible signature extension. | Pass. |
| Runtime fallback toggle | `set_oakhaven_force_generated_fallback()` added for validation/rollback preview only. | Low: defaults false and is not saved. | Pass. |

## 5. Preview Validation

| Preview | Screenshot Path | Result | Notes |
| --- | --- | --- | --- |
| fallback | `assets/art_sources/comfyui_tests/oakhaven_p11_import_preview/screenshots/oakhaven_p11_fallback_preview.png` | Pass | Generated fallback comparison board. |
| morning | `assets/art_sources/comfyui_tests/oakhaven_p11_import_preview/screenshots/oakhaven_p11_morning_preview.png` | Pass | Loaded through AssetManager production slot. |
| afternoon | `assets/art_sources/comfyui_tests/oakhaven_p11_import_preview/screenshots/oakhaven_p11_afternoon_preview.png` | Pass | Loaded through AssetManager production slot. |
| night | `assets/art_sources/comfyui_tests/oakhaven_p11_import_preview/screenshots/oakhaven_p11_night_preview.png` | Pass | Loaded through AssetManager production slot. |
| contact sheet | `assets/art_sources/comfyui_tests/oakhaven_p11_import_preview/contact_sheets/oakhaven_p11_fallback_vs_production_contact_sheet.png` | Pass | Fallback plus morning/afternoon/night side-by-side. |
| actual scene fallback | `assets/art_sources/comfyui_tests/oakhaven_p11_import_preview/screenshots/oakhaven_p11_actual_fallback_scene.png` | Pass | Captured with runtime fallback override. |
| actual scene production afternoon | `assets/art_sources/comfyui_tests/oakhaven_p11_import_preview/screenshots/oakhaven_p11_actual_afternoon_scene.png` | Pass | Captured with default production afternoon. |
| actual scene contact sheet | `assets/art_sources/comfyui_tests/oakhaven_p11_import_preview/contact_sheets/oakhaven_p11_actual_scene_fallback_vs_afternoon.png` | Pass | Actual scene fallback vs production afternoon. |

## 6. Actual Oakhaven Scene Integration

Integrated safely

The real Oakhaven scene file was not modified. Integration occurs through the existing visual-only call in `scripts/regions/oakhaven_region.gd`, which already creates `V2OakhavenGroundTiles` through AssetManager. After the AssetManager update, that layer resolves to production afternoon by default. Collision, NPC placement, player spawn, exits, story flags, farming markers, combat, and interactions were not changed.

Actual scene validation confirmed:

- fallback override path: `res://assets/generated_v2/tilesets/oakhaven_v2_prototype_tileset.png`, `production=false`
- default production path: `res://assets/production_art/tilesets/oakhaven/oakhaven_afternoon_tileset.png`, `production=true`
- actual time state: `afternoon`

## 7. Quality / Readability Scores

| Variant | Tile Readability | Player/NPC Contrast | Oakhaven Identity | Overall Score | Verdict |
| --- | --- | --- | --- | --- | --- |
| fallback | 6 | 8 | 5 | 6.0 | Serviceable but grid-noisy and visibly prototype. |
| morning | 8 | 8 | 8 | 8.0 | Strong preview-board candidate; not enabled in actual gameplay yet. |
| afternoon | 8 | 8 | 8 | 8.2 | Best actual-scene baseline; calmer and less noisy than fallback. |
| night | 8 | 8 | 8 | 7.8 | Readable in preview; should wait for real time-of-day scene testing. |

## 8. Fallback / Rollback Validation

| Scenario | Expected | Actual | Result |
| --- | --- | --- | --- |
| production present | morning/afternoon/night production slots load | All three loaded with `production=true`. | Pass |
| invalid time state | invalid state resolves to afternoon | `dusk` resolved to afternoon production with fallback metadata. | Pass |
| missing variant behavior | missing variant path does not crash and afternoon remains safe fallback | Controlled missing-path probe returned null and verified afternoon production available. | Pass |
| generated fallback still available | fallback texture loads when requested by validation override | Generated V2 fallback loaded with `production=false`. | Pass |
| actual scene rollback | runtime fallback toggle forces generated fallback in real Oakhaven scene | Actual scene fallback screenshot and metadata confirmed generated path. | Pass |

## 9. Comparison Against Current Fallback

| Area | Current Fallback | Production Oakhaven Result | Better/Worse |
| --- | --- | --- | --- |
| grass | Repeating high-cadence generated cells. | Smoother grass family; actual scene is calmer under player/NPC. | Better |
| path | Basic repeated tiles and patch overlays. | Preview path grammar is clearer; actual scene path remains partly governed by existing overlays. | Better |
| transitions | Sparse generated support. | Production atlas has richer transition grammar in preview. | Better |
| cottage/building | Existing V3 props dominate, fallback tiles are support only. | Production tile layer is quieter; building props remain unchanged. | Slightly better |
| fence/hedge | Existing V3 props dominate. | Production preview has usable hedge/fence grammar; actual scene still uses current prop overlays. | Better in preview, neutral in actual scene |
| props | Fallback sheet limited. | Production variants include clearer prop cells in preview; actual props remain V3 fallback. | Better in preview |
| overall scene feel | Prototype grid is visible. | Afternoon production reduces grid noise and keeps player readability. | Better |

## 10. Project Safety Validation

| Test | Result | Notes |
| --- | --- | --- |
| Discovered Godot path | Pass | `C:\Godot\Godot_v4.6.3-stable_win64_console.exe`. |
| Godot version | Pass | `4.6.3.stable.official.7d41c59c4`. |
| Project boot | Pass | Headless boot completed. |
| Main menu load | Pass | `res://scenes/main_menu.tscn` loaded headless. |
| Overworld/free-travel smoke | Pass | `res://scenes/overworld/overworld.tscn` loaded headless. |
| Oakhaven scene load | Pass | `res://scenes/regions/oakhaven_region.tscn` loaded headless. |
| AssetManager production load | Pass | `asset_manager_p11_import_check.gd` loaded all three production variants. |
| AssetManager fallback | Pass | Generated fallback and runtime fallback override validated. |
| Preview-only load | Pass | `capture_oakhaven_p11_import_preview.gd` saved fallback/morning/afternoon/night board screenshots. |
| Actual scene capture | Pass | Non-headless capture saved fallback and production-afternoon screenshots; Godot emitted renderer RID leak warnings at exit, but command exited 0. |
| No unintended production_art overwrite | Pass | Only `assets/production_art/tilesets/oakhaven/` received new P11 production files. |
| Save/load smoke | Not run | Save schema and save/load code were not touched; no save-slot mutation was needed for this visual-loader pass. |
| git diff --check | Pass | Exit code 0; existing CRLF normalization warnings only. |

## 11. Honest Recommendation

- Is afternoon production art better than fallback? Yes. In the actual Oakhaven scene it is quieter and less grid-noisy while preserving player readability.
- Should actual Oakhaven use afternoon only first? Yes. This is the safest baseline.
- Should all morning/day/night variants be enabled now? Not yet. They are imported and loader-safe, but only afternoon has actual scene screenshot validation.
- Is night readable enough in real context? Not proven yet. It is readable in preview-board context.
- Is this ready to accept as Oakhaven production-art baseline? Yes, with afternoon only.
- What still needs polish? Actual-scene composition still depends on V3 generated props/decals and broad region polygons; morning/night need real scene preview hooks before gameplay enablement.

## 12. Decision

Ready to accept Oakhaven production-art baseline with afternoon only
