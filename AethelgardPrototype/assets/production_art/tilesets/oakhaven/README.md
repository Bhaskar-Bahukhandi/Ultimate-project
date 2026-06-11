# Oakhaven Time-of-Day Tileset Import

This folder contains controlled Oakhaven production-art import candidates created during Phase 10M-P11.

Files:

- `oakhaven_morning_tileset.png`: tuned P10 morning atlas.
- `oakhaven_afternoon_tileset.png`: tuned P10 afternoon atlas and default gameplay-facing candidate.
- `oakhaven_night_tileset.png`: tuned P10 night atlas.
- `oakhaven_time_of_day_manifest.json`: import metadata, source lineage, fallback path, and variant mapping.

Lineage:

- P8 built the deterministic 32x32 Oakhaven tile grammar.
- P9 validated the shared layout as morning/afternoon/night preview boards.
- P10 tuned brightness and palette for readability.
- P11 imports the tuned atlases into a reversible production-art slot.

Fallback behavior:

- The generated fallback remains `res://assets/generated_v2/tilesets/oakhaven_v2_prototype_tileset.png`.
- AssetManager should fall back automatically if a production atlas is missing or invalid.
- Invalid or empty time-state requests should resolve to `afternoon`.

Status:

- Controlled import candidate.
- Not final release art.
- Do not delete the generated fallback assets.
