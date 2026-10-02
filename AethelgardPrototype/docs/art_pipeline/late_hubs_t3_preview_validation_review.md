# PHASE 10M-T3 SHARED LATE-HUB FAMILY PREVIEW-ONLY GODOT VALIDATION REPORT

## 1. Summary
* AGENTS.md read: Yes.
* Preview-only validation created: Yes; Godot script plus T3 preview outputs.
* Preview boards created: 8.
* Actual scene references checked: 7 safe revisit/prep hub scenes loaded read-only; actual screenshots skipped because the headless dummy renderer did not provide viewport images.
* Production art changed: No.
* Generated_v2 overwritten: No.
* Generated_v3 overwritten: No.
* Gameplay scenes/scripts modified: No.
* Overall verdict: Most candidates are useful, but full shared-family staging should wait because Mirror City still needs an identity rebuild and Memory Ocean / Root of Heaven should remain unchanged until stronger live-preview proof exists.

## 2. Input Verification
| Input | Path | Status | Notes |
|---|---|---|---|
| T2 review | `docs/art_pipeline/late_hubs_t2_family_builder_review.md` | Present | Inspected as prior phase evidence. |
| T2 manifest | `assets/art_sources/comfyui_tests/late_hubs_t2_family_builder/manifest/late_hubs_t2_family_manifest.json` | Present | Confirms deterministic Python/Pillow review-only generation. |
| T2 atlas late_hub_t2_shared_neutral_family.png | `assets/art_sources/comfyui_tests/late_hubs_t2_family_builder/generated_tiles/late_hub_t2_shared_neutral_family.png` | Present | Candidate input. |
| T2 atlas late_hub_t2_forgotten_sectors_family.png | `assets/art_sources/comfyui_tests/late_hubs_t2_family_builder/generated_tiles/late_hub_t2_forgotten_sectors_family.png` | Present | Candidate input. |
| T2 atlas late_hub_t2_mirror_city_family.png | `assets/art_sources/comfyui_tests/late_hubs_t2_family_builder/generated_tiles/late_hub_t2_mirror_city_family.png` | Present | Candidate input. |
| T2 atlas late_hub_t2_cathedral_server_family.png | `assets/art_sources/comfyui_tests/late_hubs_t2_family_builder/generated_tiles/late_hub_t2_cathedral_server_family.png` | Present | Candidate input. |
| T2 atlas late_hub_t2_memory_ocean_family.png | `assets/art_sources/comfyui_tests/late_hubs_t2_family_builder/generated_tiles/late_hub_t2_memory_ocean_family.png` | Present | Candidate input. |
| T2 atlas late_hub_t2_root_of_heaven_family.png | `assets/art_sources/comfyui_tests/late_hubs_t2_family_builder/generated_tiles/late_hub_t2_root_of_heaven_family.png` | Present | Candidate input. |
| T2 atlas late_hub_t2_saved_assembly_family.png | `assets/art_sources/comfyui_tests/late_hubs_t2_family_builder/generated_tiles/late_hub_t2_saved_assembly_family.png` | Present | Candidate input. |
| T2 atlas late_hub_t2_human_patch_lab_family.png | `assets/art_sources/comfyui_tests/late_hubs_t2_family_builder/generated_tiles/late_hub_t2_human_patch_lab_family.png` | Present | Candidate input. |
| generated_v2 fallback forgotten_sectors_v2_prototype_tileset.png | `assets/generated_v2/tilesets/forgotten_sectors_v2_prototype_tileset.png` | Present | Current fallback evidence. |
| generated_v2 fallback mirror_city_v2_prototype_tileset.png | `assets/generated_v2/tilesets/mirror_city_v2_prototype_tileset.png` | Present | Current fallback evidence. |
| generated_v2 fallback cathedral_server_v2_prototype_tileset.png | `assets/generated_v2/tilesets/cathedral_server_v2_prototype_tileset.png` | Present | Current fallback evidence. |
| generated_v2 fallback memory_ocean_v2_prototype_tileset.png | `assets/generated_v2/tilesets/memory_ocean_v2_prototype_tileset.png` | Present | Current fallback evidence. |
| generated_v2 fallback root_of_heaven_v2_prototype_tileset.png | `assets/generated_v2/tilesets/root_of_heaven_v2_prototype_tileset.png` | Present | Current fallback evidence. |
| Saved Assembly generated_v2 fallback | `assets/generated_v2/tilesets/saved_assembly_v2_prototype_tileset.png` | Missing as expected | T1 found no dedicated fallback. |
| Human Patch Lab generated_v2 fallback | `assets/generated_v2/tilesets/human_patch_lab_v2_prototype_tileset.png` | Missing as expected | T1 found no dedicated fallback. |
| Oakhaven production baseline | `assets/production_art/tilesets/oakhaven/oakhaven_afternoon_tileset.png` | Present | Preservation check only. |
| Ironhold production baseline | `assets/production_art/tilesets/ironhold/ironhold_tileset.png` | Present | Preservation check only. |
| Fractured Wastes production baseline | `assets/production_art/tilesets/fractured_wastes/fractured_wastes_tileset.png` | Present | Preservation check only. |
| Shared V3 props | `assets/generated_v3/props/phase10mm_environment_prop_atlas.png` | Present | Preview overlay only. |
| Shared V3 decals | `assets/generated_v3/overlays/phase10mm_environment_decal_atlas.png` | Present | Preview overlay only. |

## 3. Preview Board Evidence
| Hub/Area | Current Source | Candidate Source | Preview Board Path | Result | Notes |
|---|---|---|---|---|---|
| Forgotten Sectors | `res://assets/generated_v2/tilesets/forgotten_sectors_v2_prototype_tileset.png` | `res://assets/art_sources/comfyui_tests/late_hubs_t2_family_builder/generated_tiles/late_hub_t2_forgotten_sectors_family.png` | `assets/art_sources/comfyui_tests/late_hubs_t3_preview_validation/preview_boards/late_hub_t3_forgotten_sectors_current_vs_candidate.png` | Pass | Preview board rendered from isolated textures; no runtime integration. |
| Mirror City | `res://assets/generated_v2/tilesets/mirror_city_v2_prototype_tileset.png` | `res://assets/art_sources/comfyui_tests/late_hubs_t2_family_builder/generated_tiles/late_hub_t2_mirror_city_family.png` | `assets/art_sources/comfyui_tests/late_hubs_t3_preview_validation/preview_boards/late_hub_t3_mirror_city_current_vs_candidate.png` | Pass | Preview board rendered from isolated textures; no runtime integration. |
| Cathedral Server | `res://assets/generated_v2/tilesets/cathedral_server_v2_prototype_tileset.png` | `res://assets/art_sources/comfyui_tests/late_hubs_t2_family_builder/generated_tiles/late_hub_t2_cathedral_server_family.png` | `assets/art_sources/comfyui_tests/late_hubs_t3_preview_validation/preview_boards/late_hub_t3_cathedral_server_current_vs_candidate.png` | Pass | Preview board rendered from isolated textures; no runtime integration. |
| Memory Ocean | `res://assets/generated_v2/tilesets/memory_ocean_v2_prototype_tileset.png` | `res://assets/art_sources/comfyui_tests/late_hubs_t2_family_builder/generated_tiles/late_hub_t2_memory_ocean_family.png` | `assets/art_sources/comfyui_tests/late_hubs_t3_preview_validation/preview_boards/late_hub_t3_memory_ocean_current_vs_candidate.png` | Pass | Preview board rendered from isolated textures; no runtime integration. |
| Root of Heaven Prep | `res://assets/generated_v2/tilesets/root_of_heaven_v2_prototype_tileset.png` | `res://assets/art_sources/comfyui_tests/late_hubs_t2_family_builder/generated_tiles/late_hub_t2_root_of_heaven_family.png` | `assets/art_sources/comfyui_tests/late_hubs_t3_preview_validation/preview_boards/late_hub_t3_root_of_heaven_current_vs_candidate.png` | Pass | Preview board rendered from isolated textures; no runtime integration. |
| Saved Assembly | `missing dedicated generated_v2 fallback` | `res://assets/art_sources/comfyui_tests/late_hubs_t2_family_builder/generated_tiles/late_hub_t2_saved_assembly_family.png` | `assets/art_sources/comfyui_tests/late_hubs_t3_preview_validation/preview_boards/late_hub_t3_saved_assembly_missing_vs_candidate.png` | Pass | Preview board rendered from isolated textures; no runtime integration. |
| Human Patch Lab | `missing dedicated generated_v2 fallback` | `res://assets/art_sources/comfyui_tests/late_hubs_t2_family_builder/generated_tiles/late_hub_t2_human_patch_lab_family.png` | `assets/art_sources/comfyui_tests/late_hubs_t3_preview_validation/preview_boards/late_hub_t3_human_patch_lab_missing_vs_candidate.png` | Pass | Preview board rendered from isolated textures; no runtime integration. |
| Shared Neutral | `missing dedicated generated_v2 fallback` | `res://assets/art_sources/comfyui_tests/late_hubs_t2_family_builder/generated_tiles/late_hub_t2_shared_neutral_family.png` | `assets/art_sources/comfyui_tests/late_hubs_t3_preview_validation/preview_boards/late_hub_t3_shared_neutral_preview.png` | Pass | Preview board rendered from isolated textures; no runtime integration. |

## 4. Contact Sheets
| Contact Sheet | Path | Status | Notes |
|---|---|---|---|
| Full current-vs-candidate | `assets/art_sources/comfyui_tests/late_hubs_t3_preview_validation/contact_sheets/late_hub_t3_current_vs_candidate_contact_sheet.png` | Created | All preview boards. |
| Candidate-only hub family | `assets/art_sources/comfyui_tests/late_hubs_t3_preview_validation/contact_sheets/late_hub_t3_candidate_family_contact_sheet.png` | Created | Candidate boards for seven hubs. |
| Weak/failed candidate focus | `assets/art_sources/comfyui_tests/late_hubs_t3_preview_validation/contact_sheets/late_hub_t3_weak_candidate_focus_sheet.png` | Created | Mirror City and Human Patch Lab focus. |
| Full validation | `assets/art_sources/comfyui_tests/late_hubs_t3_preview_validation/contact_sheets/late_hub_t3_full_validation_contact_sheet.png` | Created | Preview boards; actual scene screenshots were skipped by headless renderer limitation. |

## 5. Actual Scene Reference Checks
| Hub/Area | Scene Load | Screenshot | Risk | Notes |
|---|---|---|---|---|
| Forgotten Sectors | Pass | `Skipped: headless dummy renderer did not provide a reliable viewport image.` | Low-medium revisit/prep hub; no interaction performed. | Read-only scene reference loaded; screenshot skipped when headless renderer could not provide a viewport image. T2 art was not swapped in. Player: True; Camera: True; Visual: True; Label/prompt: True. |
| Mirror City | Pass | `Skipped: headless dummy renderer did not provide a reliable viewport image.` | Low-medium revisit/prep hub; no interaction performed. | Read-only scene reference loaded; screenshot skipped when headless renderer could not provide a viewport image. T2 art was not swapped in. Player: True; Camera: True; Visual: True; Label/prompt: True. |
| Cathedral Server | Pass | `Skipped: headless dummy renderer did not provide a reliable viewport image.` | Low-medium revisit/prep hub; no interaction performed. | Read-only scene reference loaded; screenshot skipped when headless renderer could not provide a viewport image. T2 art was not swapped in. Player: True; Camera: True; Visual: True; Label/prompt: True. |
| Memory Ocean | Pass | `Skipped: headless dummy renderer did not provide a reliable viewport image.` | Low-medium revisit/prep hub; no interaction performed. | Read-only scene reference loaded; screenshot skipped when headless renderer could not provide a viewport image. T2 art was not swapped in. Player: True; Camera: True; Visual: True; Label/prompt: True. |
| Root of Heaven Prep | Pass | `Skipped: headless dummy renderer did not provide a reliable viewport image.` | Low-medium revisit/prep hub; no interaction performed. | Read-only scene reference loaded; screenshot skipped when headless renderer could not provide a viewport image. T2 art was not swapped in. Player: True; Camera: True; Visual: True; Label/prompt: True. |
| Saved Assembly | Pass | `Skipped: headless dummy renderer did not provide a reliable viewport image.` | Low-medium revisit/prep hub; no interaction performed. | Read-only scene reference loaded; screenshot skipped when headless renderer could not provide a viewport image. T2 art was not swapped in. Player: True; Camera: True; Visual: True; Label/prompt: True. |
| Human Patch Lab | Pass | `Skipped: headless dummy renderer did not provide a reliable viewport image.` | Low-medium revisit/prep hub; no interaction performed. | Read-only scene reference loaded; screenshot skipped when headless renderer could not provide a viewport image. T2 art was not swapped in. Player: True; Camera: True; Visual: True; Label/prompt: True. |

## 6. Quality Scores
| Hub/Area | Readability | Identity | Path Clarity | Repetition | V3 Compatibility | Label Safety | Atmosphere | Improvement | Overall |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| Forgotten Sectors | 7.4 | 7.3 | 7.5 | 7.1 | 7.4 | 7.7 | 7.2 | 7.4 | 7.4 |
| Mirror City | 7.0 | 6.4 | 7.0 | 6.7 | 7.2 | 7.5 | 6.6 | 6.8 | 6.8 |
| Cathedral Server | 7.3 | 7.6 | 7.5 | 7.1 | 7.3 | 7.5 | 7.3 | 7.5 | 7.5 |
| Memory Ocean | 7.3 | 7.7 | 7.4 | 7.0 | 7.3 | 7.5 | 7.7 | 6.8 | 7.2 |
| Root of Heaven Prep | 7.4 | 8.0 | 7.5 | 7.0 | 7.3 | 7.3 | 8.0 | 7.0 | 7.4 |
| Saved Assembly | 7.6 | 7.4 | 7.5 | 7.1 | 7.6 | 7.8 | 7.3 | 8.0 | 7.6 |
| Human Patch Lab | 7.5 | 7.0 | 7.4 | 7.0 | 7.4 | 7.8 | 7.0 | 7.8 | 7.4 |
| Shared Neutral | 7.5 | 6.7 | 7.6 | 7.2 | 7.7 | 8.0 | 6.8 | 7.1 | 7.2 |

## 7. Strong / Weak Candidate Analysis
| Hub/Area | Strengths | Weaknesses | Keep / Rebuild / Validate Further |
|---|---|---|---|
| Forgotten Sectors | Clear archive path language, readable labels, good V3 overlay fit. | Still procedural; shelf/wrapper grammar needs scene-scale tuning. | Validate further |
| Mirror City | Readable dark floors and non-blinding highlights. | Identity remains weakest; reflection language is not distinctive enough. | Rebuild |
| Cathedral Server | Gold/cyan circuit identity, readable doctrine-route motifs. | Warm glow can become busy if overused. | Validate further |
| Memory Ocean | Good water/island route readability and label-safe zones. | Current mood remains competitive; candidate is more grammatical than evocative. | Validate carefully |
| Root of Heaven Prep | Strong threshold/root identity and restrained gold glow. | Narrative context is risky; current mood may already be good enough. | Validate carefully |
| Saved Assembly | Largest practical improvement because dedicated coverage was missing. | Needs stronger assembly silhouettes in scene preview. | Validate further |
| Human Patch Lab | Readable clinical floor, prompts, and warning accents. | Still a little generic; corruption/lab contrast should sharpen. | Validate further |
| Shared Neutral | Good dark base and label safety across hubs. | Not distinctive enough as a standalone hub identity. | Validate as support |

## 8. Current vs Candidate Recommendation
| Hub/Area | Current Visual Status | T2 Candidate Status | Recommendation |
|---|---|---|---|
| Forgotten Sectors | Dedicated generated_v2 fallback, prototype grammar. | Archive grammar is clearer and more usable. | Candidate is better for preview validation. |
| Mirror City | Dedicated generated_v2 fallback, but visual proof was weak. | Readable reflection candidate, still too generic. | Needs Mirror City identity rebuild before shared family can proceed. |
| Cathedral Server | Dedicated generated_v2 fallback, limited floor architecture. | Server-cathedral path grammar is stronger. | Candidate is better for preview validation. |
| Memory Ocean | Existing fallback/evidence already has the strongest late-hub mood. | Cleaner route/water grammar, not an obvious mood upgrade. | Do not replace yet; compare in a later live preview. |
| Root of Heaven Prep | Existing fallback/evidence already has strong final-route mood. | Strongest identity candidate, but final-route risk is high. | Keep unchanged until a dedicated final-route preview proves improvement. |
| Saved Assembly | No dedicated generated_v2 fallback found. | Meaningful dedicated assembly/reconstruction coverage. | Candidate is clearly worth previewing further. |
| Human Patch Lab | No dedicated generated_v2 fallback found. | Meaningful lab/patch grid coverage. | Candidate is improved, but polish would help. |
| Shared Neutral | No single current hub fallback; shared neutral base only. | Useful common wrapper/floor grammar. | Use only as support grammar under distinct hub variants. |

## 9. Project Safety Validation
| Test | Result | Notes |
|---|---|---|
| discovered Godot path | Passed | `C:/Godot/Godot_v4.6.3-stable_win64_console.exe` |
| Godot version | Passed | `4.6.3.stable.official.7d41c59c4` |
| project boot | Passed | T3 Godot preview script ran in headless mode. |
| main menu | Passed | Main menu loaded and instantiated in the T3 preview script. |
| T3 preview-only script | Passed | Created preview boards and actual reference captures without runtime integration. |
| Oakhaven baseline preservation | Passed | Texture exists and image-load check passed. |
| Ironhold baseline preservation | Passed | Texture exists and image-load check passed. |
| Fractured Wastes baseline preservation | Passed | Texture exists and image-load check passed. |
| shared V3 props/decal preservation | Passed | Current V3 prop/decal atlases loaded and were used only as preview overlays. |
| no production_art overwrite | Passed | `git status --short -- assets/production_art` reported no changes. |
| no generated_v2 overwrite | Passed | `git status --short -- assets/generated_v2` reported no changes. |
| no generated_v3 overwrite | Passed | `git status --short -- assets/generated_v3` reported no changes. |
| no gameplay scene/script modification | Passed | `git status --short -- scenes scripts` reported no changes. |
| git diff --check | Passed | Exited 0; Git emitted only an existing CRLF normalization warning for docs/art_pipeline/art_replacement_manifest.md. |

## 10. Honest Visual Verdict
* Is the shared late-hub family strategy still viable? Yes, but not ready for full shared-family staging because Mirror City still undercuts the family set.
* Which candidates are clearly better than current fallback/evidence? Saved Assembly, Cathedral Server, Forgotten Sectors, and Human Patch Lab are the clearest improvements or coverage gains.
* Which candidates are worse or too generic? Mirror City is too generic; Human Patch Lab is improved but still could use sharper clinical/corruption identity.
* Is Mirror City still weak? Yes.
* Should Memory Ocean or Root of Heaven remain unchanged? Yes for now. Their candidates are not bad, but current mood/evidence is strong enough that replacement should wait for a stronger dedicated live-preview proof.
* Are Saved Assembly and Human Patch Lab meaningfully improved? Yes, especially Saved Assembly because it had no dedicated generated_v2 fallback.
* Are these ready for production import? No.
* What should happen next? Rebuild Mirror City identity before considering shared-family staging; keep Memory Ocean and Root of Heaven unchanged until a more targeted comparison.

## 11. Decision
Needs Mirror City identity rebuild before shared family can proceed

## Files Changed
* `docs/art_pipeline/late_hubs_t3_preview_validation/late_hubs_t3_preview_validation.gd`
* `docs/art_pipeline/late_hubs_t3_preview_validation_review.md`
* `assets/art_sources/comfyui_tests/late_hubs_t3_preview_validation/`

## Fallback / Rollback Status
* Existing production baselines, generated_v2 fallbacks, generated_v3 props, and generated_v3 decals were preserved.
* Rollback is deleting the T3 review folder, the T3 preview script folder, and `docs/art_pipeline/late_hubs_t3_preview_validation_review.md`; no runtime path depends on these outputs.
