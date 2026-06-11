# Oakhaven Production Art Request

## Needed First

- Runtime export: `assets/production_art/tilesets/oakhaven_tileset.png`
- Source slot: `assets/art_sources/tilesets/oakhaven/`
- Format: PNG with transparency where needed
- Grid: 32 px top-down visual tile family
- Preferred sheet size: at least 512x512

## Must Include

- calm meadow floor variants
- dirt path center, shoulders, turns, and organic edge transitions
- wood floor / threshold support
- cottage wall-base and roof-support tiles
- fences, hedge bases, herb-field support, warm village signage
- enough low-noise walkable tiles to keep Kaelen and Elara readable

## Must Avoid

- side-view platformer tiles
- single repeated grass square as the whole region floor
- roof-only sprites with no base or wall support
- copied commercial RPG visual language

## Review Checks

- Oakhaven remains readable at current camera scale
- exit and farming marker lanes remain visible
- existing collision nodes remain authoritative
- generated v2 fallback remains usable when the production file is removed

