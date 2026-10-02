# Art Generation Truth Audit

Phase: 10M-U1 - Art pipeline truth reset and real ComfyUI requirement gate

Scope: documentation and audit only. This file does not approve new art, generate art,
import art, or change runtime behavior.

## 1. Summary

Recent art pipeline work mixed several different evidence types under folders named
`assets/art_sources/comfyui_tests`. That folder name is no longer reliable evidence
that ComfyUI was actually used.

This audit separates the current art evidence into four categories:

- Real ComfyUI-generated art: outputs backed by a workflow, prompt/run evidence,
  model/checkpoint information, seeds, ComfyUI output records, and source images.
- Deterministic procedural placeholder art: Python/Pillow/Godot generated layouts,
  mockups, atlases, crop-contract tests, and validation boards.
- Runtime validation boards: Godot or deterministic boards used to prove layout,
  readability, route grammar, crop contracts, overlays, or fallback behavior.
- Imported production baselines: files copied into `assets/production_art` by a
  controlled import phase, regardless of whether the source was real ComfyUI or
  procedural.

Current conclusion:

- Oakhaven has the strongest real ComfyUI lineage because Phase P6 records local
  ComfyUI generation, endpoint, checkpoint, source records, and output selections.
- Ironhold, Fractured Wastes, shared V3 props/decals, Mirror City T4-T7, and late
  hubs T1-T3 do not have sufficient real ComfyUI evidence in the audited reports.
- Several deterministic phases were placed under `comfyui_tests`; those are legacy
  naming artifacts and must not be described as real ComfyUI generation.
- Procedural output is acceptable only as placeholder/debug/preview evidence, crop
  tests, layout tests, or runtime validation boards.
- Future final-looking art must not be called real AI/ComfyUI art unless the
  evidence bundle in `real_comfyui_generation_requirements.md` exists.

## 2. Evidence Reviewed

Required files read for this reset:

| File | Status | Notes |
| --- | --- | --- |
| `AGENTS.md` | Read | Confirms safe, staged, reversible changes and honest reporting. |
| `docs/art_pipeline/art_replacement_manifest.md` | Read | Lists accepted production baselines and active fallbacks. |
| `docs/art_pipeline/shared_environment_v3_baseline_lock.md` | Read | Confirms current V3 prop/decal atlases remain active baseline; S1/S3 are archived/reference only. |
| `docs/art_pipeline/mirror_city_t7_controlled_production_import_review.md` | Read | Confirms Mirror City T7 imported Variant D but found no real ComfyUI evidence for T4-T7. |

Additional phase reports and manifests were inspected across Oakhaven, Ironhold,
Fractured Wastes, shared environment V3, Mirror City T4-T7, and late hubs T1-T3.

## 3. Phase Classification

| Phase / asset family | Real ComfyUI used | Deterministic procedural output | Preview-only validation | Production import | Live screenshot evidence | Deterministic board evidence | Truth classification |
| --- | --- | --- | --- | --- | --- | --- | --- |
| Oakhaven P6 source generation | Yes | No for source generation | Review/candidate evidence only | No | Not the main evidence type | Contact sheets/source records | Real ComfyUI source phase. Reports cite local ComfyUI output, endpoint, checkpoint, seeds/source records, and generated source outputs. |
| Oakhaven P7 extraction | No new ComfyUI run | Crop extraction and review assembly | Yes | No | No runtime import evidence | Yes | Derived review phase from P6 sources, not a fresh ComfyUI generation phase. |
| Oakhaven P8-P10 tileset/tuning/preview | No new ComfyUI run found | Controlled assembly/tuning and preview generation | Yes | No | Limited/preview evidence only | Yes | Procedural/review handling of Oakhaven candidate material. |
| Oakhaven P11-P12 production acceptance | Source lineage includes P6 real ComfyUI | Controlled import/validation support | Yes | Yes | Actual-scene screenshot evidence reported for accepted afternoon baseline | Yes | Imported production baseline with real-ComfyUI source lineage plus later controlled assembly/tuning. Not a pure untouched ComfyUI output. |
| Ironhold Q1 candidate builder | No evidence found | Yes, deterministic Pillow builder | Review-only | No | No | Yes | Procedural placeholder/candidate phase under legacy `comfyui_tests` naming. |
| Ironhold Q2 validation | No evidence found | Validation board generation | Yes | No | Godot/actual-region reference screenshots reported | Yes | Preview-only runtime validation, not ComfyUI generation. |
| Ironhold Q3 import | No evidence found | Imported Q1 deterministic Variant B | Yes | Yes | Actual-region fallback/production screenshots reported | Yes | Accepted production baseline, but source truth is deterministic/procedural, not real ComfyUI. |
| Fractured Wastes R1 candidate builder | No evidence found | Yes, deterministic Pillow atlas/mockup generator | Review-only | No | No | Yes | Procedural placeholder/candidate phase under legacy `comfyui_tests` naming. |
| Fractured Wastes R2 validation | No evidence found | Validation board generation | Yes | No | Godot/actual-region references reported | Yes | Preview-only runtime validation, not ComfyUI generation. |
| Fractured Wastes R3 import | No evidence found | Imported R1 deterministic Variant B | Yes | Yes | Actual-region fallback/production screenshots reported | Yes | Accepted production baseline, but source truth is deterministic/procedural, not real ComfyUI. |
| Shared V3 props/decals S1-S5 | No evidence found | Yes, deterministic prop/decal candidate and repair content | Yes | No new production_art import | Live screenshots skipped or limited; S4 notes headless dummy rendering limits | Yes, crop/contact/validation boards | Active generated_v3 baseline remains locked. It is accepted as current baseline support art, not real ComfyUI output. |
| Mirror City T4 identity rebuild | No evidence found | Yes, deterministic Python/Pillow generated T4 variants | Review-only | No | No | Yes | Procedural candidate art under legacy `comfyui_tests` naming. |
| Mirror City T5 preview validation | No evidence found | Preview-board rendering/evidence only | Yes | No | Actual-scene screenshot skipped/unreliable | Yes | Preview-only validation, not ComfyUI generation. |
| Mirror City T6 actual-scene staging preview | No evidence found | Deterministic scene-composition boards | Yes | No | No reliable live viewport screenshots | Yes | In-memory staging evidence only; deterministic fallback boards, not live screenshots. |
| Mirror City T7 controlled import | No evidence found | Uses T4 deterministic Variant D plus runtime boards | Yes | Yes | No live viewport screenshot evidence; deterministic boards only | Yes | Imported production baseline from deterministic candidate. Truth status is controlled procedural production baseline, not real ComfyUI. |
| Late hubs T1 visual audit | No evidence found | Static audit/contact evidence; copied existing screenshots where available | Audit/review-only | No | No new live captures | Yes | Review/audit evidence only under legacy `comfyui_tests` naming. |
| Late hubs T2 family builder | No evidence found | Generated family candidates | Review-only | No | No | Yes | Procedural family candidates under legacy `comfyui_tests` naming. |
| Late hubs T3 preview validation | No evidence found | Preview boards and validation artifacts | Yes | No | Preview/reference captures only, no runtime integration | Yes | Preview-only validation, not ComfyUI generation. |

## 4. Legacy `comfyui_tests` Naming Findings

These folders or phase outputs use `comfyui_tests` naming but do not have enough
evidence to classify them as real ComfyUI generation:

- `assets/art_sources/comfyui_tests/ironhold_q1/`
- `assets/art_sources/comfyui_tests/ironhold_q2_preview_validation/`
- `assets/art_sources/comfyui_tests/fractured_wastes_r1/`
- `assets/art_sources/comfyui_tests/fractured_wastes_r2_preview_validation/`
- `assets/art_sources/comfyui_tests/shared_environment_s1/`
- `assets/art_sources/comfyui_tests/shared_environment_s2_preview_validation/`
- `assets/art_sources/comfyui_tests/shared_environment_s3_prop_repair/`
- `assets/art_sources/comfyui_tests/shared_environment_s4_v3_prop_audit/`
- `assets/art_sources/comfyui_tests/late_hubs_t1_audit/`
- `assets/art_sources/comfyui_tests/late_hubs_t2_family_builder/`
- `assets/art_sources/comfyui_tests/late_hubs_t3_preview_validation/`
- `assets/art_sources/comfyui_tests/mirror_city_t4_identity_rebuild/`
- `assets/art_sources/comfyui_tests/mirror_city_t5_preview_validation/`
- `assets/art_sources/comfyui_tests/mirror_city_t6_actual_scene_staging_preview/`
- `assets/art_sources/comfyui_tests/mirror_city_t7_controlled_import/`

Oakhaven P6 is the exception found in this audit: its reports and source records
indicate actual local ComfyUI generation. Later Oakhaven folders may be derived
from P6 sources, but they are not themselves fresh ComfyUI runs unless they carry
the required evidence bundle.

## 5. Accepted Placeholders and Baselines

Accepted or active baselines that should remain untouched by this audit:

| Asset | Current status | Truth status |
| --- | --- | --- |
| `assets/production_art/tilesets/oakhaven/oakhaven_afternoon_tileset.png` | Accepted production baseline | Strong real-ComfyUI lineage from P6 plus controlled extraction/tuning/import. |
| `assets/production_art/tilesets/ironhold/ironhold_tileset.png` | Accepted production baseline | Controlled import from deterministic/procedural source; not real ComfyUI. |
| `assets/production_art/tilesets/fractured_wastes/fractured_wastes_tileset.png` | Accepted production baseline | Controlled import from deterministic/procedural source; not real ComfyUI. |
| `assets/production_art/tilesets/mirror_city/mirror_city_tileset.png` | Controlled T7 production baseline if present | Imported from deterministic T4 Variant D; not real ComfyUI and still lacks live viewport proof. |
| `assets/generated_v3/props/phase10mm_environment_prop_atlas.png` | Active generated_v3 support baseline | Deterministic/generated support art; not real ComfyUI. |
| `assets/generated_v3/overlays/phase10mm_environment_decal_atlas.png` | Active generated_v3 support baseline | Deterministic/generated support art; not real ComfyUI. |
| Late hub T1-T3 artifacts under `assets/art_sources` | Review-only evidence | Placeholder/procedural/validation artifacts only. |

"Accepted" in this table means accepted for the current prototype baseline, not
accepted as proof of real ComfyUI generation.

## 6. Real ComfyUI Assets Found

Evidence sufficient for real ComfyUI classification was found only for the Oakhaven
P6 source-generation lineage.

Known evidence from the audited reports includes:

- Reported local ComfyUI generation in `docs/art_pipeline/comfyui_oakhaven_p6_review.md`.
- Endpoint noted as `http://127.0.0.1:8000`.
- Base checkpoint noted as `v1-5-pruned-emaonly.safetensors`.
- P6 source records under `assets/art_sources/comfyui_tests/oakhaven_p6/source_records/`.

This audit did not find equivalent workflow, prompt, prompt_id, history, seed, and
source-output metadata bundles for Ironhold, Fractured Wastes, shared V3 props/decals,
Mirror City T4-T7, or late hubs T1-T3.

## 7. Assets That Should Be Replaced Later

The following are safe to keep for the current prototype, but should be candidates
for later replacement if the project requires true AI/human-authored final art:

- Ironhold production baseline, because it was imported from deterministic Q1 output.
- Fractured Wastes production baseline, because it was imported from deterministic R1 output.
- Mirror City production baseline, because it was imported from deterministic T4 Variant D
  and T7 did not capture live viewport screenshot proof.
- Shared V3 prop/decal atlases, because they are active generated baselines but not real
  ComfyUI outputs.
- Late hub T1-T3 candidate families, because they are review-only/procedural validation
  artifacts and are not production-ready real art.

Oakhaven can remain the safest accepted baseline because it has the clearest real
ComfyUI source lineage. It may still receive a future final-authoring pass, but this
audit does not require replacing it.

## 8. What Should Not Be Touched

This U1 phase must not touch:

- `assets/production_art/`
- `assets/generated_v2/`
- `assets/generated_v3/`
- `scenes/`
- `scripts/`
- `scripts/asset_manager.gd`
- Chapter 5 story scenes
- combat systems or combat scenes
- save/load scripts
- world travel scripts
- collision, navigation, NPC logic, player logic, quests, story flags, Source Key,
  true ending, or NG+

## 9. Future Naming Contract

New work should stop using `comfyui_tests` for non-ComfyUI outputs.

Recommended folders:

- `assets/art_sources/comfyui_real/<phase>/` for real ComfyUI runs with complete evidence.
- `assets/art_sources/procedural_placeholders/<phase>/` for deterministic placeholder art.
- `assets/art_sources/runtime_validation/<phase>/` for preview boards and scene validation evidence.
- `assets/art_sources/import_evidence/<phase>/` for contact sheets and audit evidence tied to a controlled import.

Legacy `comfyui_tests` folders may remain in place for history, but reports and manifests
must explicitly label whether ComfyUI was actually used.

## 10. Next Safest Real-Art Target

The next safest real-art target is Mirror City, but only as a new real ComfyUI source
generation and review phase. It should not begin with another production import.

Reasoning:

- Mirror City has the most recent deterministic production import.
- T7 established fallback behavior and a narrow runtime path, making it easier to test
  safely later.
- Mirror City still lacks live viewport screenshot proof.
- A real ComfyUI source pack could replace the deterministic T4 Variant D lineage without
  touching generated_v2/generated_v3 or other accepted region baselines.

The next phase should first create a real ComfyUI evidence bundle and review-only contact
sheets. Production import should remain a separate later phase.

## 11. Final Decision

Art pipeline truth reset complete.
