# Shared Environment V3 Baseline Lock

Phase: 10M-S5
Date: 2026-06-12

## Decision

The current generated V3 shared environment prop and decal atlases remain the active baseline for now.
No shared prop/decal full-atlas replacement is currently planned.

Active baseline assets:

- `assets/generated_v3/props/phase10mm_environment_prop_atlas.png`
- `assets/generated_v3/overlays/phase10mm_environment_decal_atlas.png`

Production slots remain unused in this phase:

- `assets/production_art/props/environment_prop_atlas.png`
- `assets/production_art/backgrounds/environment_decal_atlas.png`

## Why V3 Was Kept

The S4 audit found that the current generated V3 prop atlas is more refined and production-like than the S1/S3 replacement candidates across the actual hard-coded prop regions. V3 has stronger material detail, object silhouette, and region identity in high-priority uses such as Oakhaven roofs/hedges, Ironhold pipes/forge/crates, late hub consoles/panels/tanks, and combat arena support props.

The current generated V3 decal atlas also remains active. Although the S1 decal candidate showed promising readability in earlier preview work, S5 locks the current shared baseline and stops broad replacement planning. Any decal work should be restarted only as a narrow, evidence-based pass.

## Why S1/S3 Were Rejected For Full Replacement

S1 prop candidates were contract-aligned but visually too sparse and simplified. S3 improved S1 with richer deterministic drawing, but the result still looked more symbolic and placeholder-like than the current V3 atlas in many important regions. The comparison did not justify replacing the full V3 prop atlas.

S1/S3 prop outputs are retained only as archived/reference material under `assets/art_sources`. They should not be imported into `production_art` and should not replace `generated_v3` assets.

## Future Work Rule

Future shared environment work should not restart full-atlas replacement by default. Only target a specific V3 prop or decal region if an actual in-scene screenshot or focused review proves a visible problem. Any such repair must preserve the existing AssetManager region contract unless a later explicit contract-repair phase is approved.

## Safety Notes

- No art files were changed.
- No production art files were changed.
- No generated V3 files were overwritten.
- No gameplay scenes/scripts or AssetManager code were modified.
- Oakhaven, Ironhold, and Fractured Wastes baselines remain preserved.
