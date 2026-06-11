# Production Art Sourcing Checklist

Phase 10M-N found no local candidate that was both a clear top-priority production fit and locally
license-safe to promote into a runtime production slot.

## Obtain Or Generate Next

1. Oakhaven 32 px top-down production tileset at `>=512x512`
   - export name: `oakhaven_tileset.png`
   - must include meadow/path/cottage/fence/herb support families
2. Ironhold 32 px top-down production tileset at `>=512x512`
   - export name: `ironhold_tileset.png`
   - must include calm roads, industrial edges, forge/training, mine support
3. Fractured Wastes 32 px top-down production tileset at `>=512x512`
   - export name: `fractured_wastes_tileset.png`
   - must include irregular scar terrain and readable shard/shelter support
4. Shared environment prop atlas at `1536x1024`
   - export name: `environment_prop_atlas.png`
   - first revision should follow the current crop contract guide
5. Shared floor/decal atlas at `1536x1024`
   - export name: `environment_decal_atlas.png`
   - avoid giant opacity patches; design authored floor accents
6. Tutorial Knight arena floor/backdrop support
   - use the `1280x720` source guide
   - keep combat warnings unobscured

## Bring With Every Candidate

- source or generator record
- license or ownership note suitable for shipping review
- intended runtime export path
- image dimensions and tile/frame grid
- one screenshot or contact sheet from the source pack if available

## Do Not Promote Yet

- local top-level `assets/tilesets/oakhaven/*.png` and `assets/tilesets/ironhold/*.png`
  without a local shipping-license record
- Kenney platformer tile folders as the main top-down RPG world replacement
- generated v2/v3 fallback art re-labeled as production art

