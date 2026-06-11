# Phase 10M-O Generation Prompt Library

These prompts are production-intake prompts, not permission to generate or import yet. They avoid
named commercial styles and keep current Godot slicing contracts visible in the prompt itself.

## Shared Direction Block

Use this block in every generation request unless the approved tool needs a shorter prompt:

> Original 2D game art for a dark fantasy RPG with subtle digital-glitch corruption, authored for a
> top-down Godot 4 project. Do not imitate any named game, franchise, studio, artist, screenshot,
> asset pack, or copyrighted style. Keep shapes readable at gameplay scale, keep surfaces coherent
> across an asset family, avoid text and watermarks, avoid photorealism, avoid 3D renders, avoid
> isometric perspective unless explicitly requested, and produce Godot-ready PNG output.

## Oakhaven Production Tileset

```text
Create an original top-down pixel-art RPG tileset sheet for the Oakhaven village region.

Style:
- dark fantasy with restrained digital-glitch undertones, still warm and humane
- readable meadow and village route art, not checkerboard grass
- no copyrighted or named-game style copying

Output contract:
- PNG tileset sheet
- 512x512 pixels minimum
- exact 32x32 tile grid, 16 columns by 16 rows if using 512x512
- no labels, no preview map, no margins, no grid numbers, no text, no watermark
- top-down gameplay perspective
- floor tiles may be opaque; transition, fence, edge, and prop-support cells should preserve alpha where appropriate
- nearest-neighbor pixel readability, clean edges, consistent palette

Required tile families:
- low-noise meadow floor variants for character readability
- natural dirt path centers, path turns, path T-junctions, path end caps, and meadow-to-path edges
- wood porch and threshold tiles
- fence bases and hedge/boundary support tiles
- cottage wall-base, doorway-base, roof-shadow/support, and ground-contact tiles
- herb patch, flower scatter, sign footing, cart footing, and exit marker support tiles
- subtle corrupted-glitch accent tiles used sparingly, never dominant on walkable ground

Avoid:
- one big environment illustration instead of reusable tiles
- side-view platformer perspective
- noisy grass in every tile
- floating roofs without wall/base support
- baked characters, UI, dialogue text, or collision markers

Goal:
The sheet must support an authored Oakhaven route with meadows, readable paths, fences, cottage bases,
and a beginner herb-farming area while keeping Kaelen and NPC silhouettes easy to read.
```

## Ironhold Production Tileset

```text
Create an original top-down pixel-art RPG tileset sheet for the Ironhold industrial region.

Style:
- dark fantasy forge district with restrained clockwork and digital-control corruption
- organized metal-and-brick traversal language, not noisy sci-fi wallpaper
- no copyrighted or named-game style copying

Output contract:
- PNG tileset sheet
- 512x512 pixels minimum
- exact 32x32 tile grid
- no labels, no preview map, no margins, no text, no watermark
- top-down gameplay perspective
- keep major walkable tiles calmer than border and machinery tiles

Required tile families:
- industrial road and walkway centers with readable variants
- metal plate edges, brick transitions, mine dirt transitions, and safe-corridor trim
- forge floor and training-yard apron tiles
- wall-base, pipe-base, crate-base, ore-cart support, rail, and threshold tiles
- low-frequency furnace glow accents and soot/weathering variants
- mine/training marker ground-contact tiles

Avoid:
- high-contrast bolts and rivets on every walkable tile
- side-view factory facades presented as floor tiles
- icon sheets instead of environment tiles
- baked NPCs, UI labels, text, or collision art

Goal:
The sheet must let Ironhold read as a legible forge district with roads, training space, shop/crafting
support, and industrial architecture while keeping NPC labels and player silhouettes readable.
```

## Fractured Wastes Production Tileset

```text
Create an original top-down pixel-art RPG tileset sheet for the Fractured Wastes region.

Style:
- dark fantasy badlands cut by memory fractures and subtle digital-glitch scars
- irregular terrain with danger language and safe-route readability
- no copyrighted or named-game style copying

Output contract:
- PNG tileset sheet
- 512x512 pixels minimum
- exact 32x32 tile grid
- no labels, no preview map, no margins, no text, no watermark
- top-down gameplay perspective
- preserve alpha on edge/scar/shard-support cells where appropriate

Required tile families:
- cracked soil floor variants with low repetition
- safe trail tiles and scar-edge transitions
- fracture scar centers and fringe tiles
- shard-pocket support tiles and stabilizer-pylon footing tiles
- shelter/core threshold tiles and broken-route support tiles
- warning-post footing and danger-border accent tiles
- sparse magenta/cyan corruption highlights kept lower than hazard/UI readability

Avoid:
- stamping the same crack in every cell
- one giant dark overlay expressed as tiles
- bright glitch noise behind enemy silhouettes
- baked hazards, interactable prompts, story text, or scene screenshots

Goal:
The sheet must support shard fields, a shelter/core approach, and readable farming-zone focal points
without turning the whole region into repeated cracked wallpaper.
```

## Kaelen Top-Down Player Sheet

```text
Create an original transparent top-down pixel-art player sprite sheet for Kaelen, the protagonist of a
dark fantasy RPG with subtle digital-glitch corruption.

Character direction:
- readable heroic silhouette with grounded traveler armor/cloak language
- original design only, no franchise or named-artist imitation
- keep clothing shapes stable across all rows
- do not include weapons trails, spell effects, text, or background

Output contract:
- transparent PNG sprite sheet with alpha
- exact full sheet size: 128x256 pixels
- exact frame size: 32x32 pixels
- exact layout: 4 columns x 8 rows
- center Kaelen consistently in every 32x32 frame
- preserve a stable ground contact point and silhouette size across frames
- no padding outside the stated sheet size
- no anti-aliased halo, no opaque background, no captions

Required row order:
1. idle_down, 4 frames
2. walk_down, 4 frames
3. idle_up, 4 frames
4. walk_up, 4 frames
5. idle_left, 4 frames
6. walk_left, 4 frames
7. idle_right, 4 frames
8. walk_right, 4 frames

Animation notes:
- idle rows should be subtle and loop cleanly
- walk rows should show clear foot cadence and cloak follow-through without shifting the collision footprint
- keep left and right rows coherent mirrors only if visual details still read correctly

Godot requirement:
This sheet must be slicable without manual row reordering into
assets/production_art/characters/player/kaelen_topdown_alpha_sheet.png.
```

## Tutorial Knight Production Sheet

```text
Create an original transparent pixel-art combat sprite sheet for the Tutorial Knight boss.

Style:
- dark fantasy armored knight with restrained corrupted-digital accents
- intimidating but readable tutorial-combat silhouette
- original art only, no copied commercial boss design
- do not bake HUD, warning markers, hitboxes, text, or arena floor into frames

Output contract:
- transparent PNG sprite sheet with alpha
- exact full sheet size: 384x960 pixels
- exact frame size: 96x96 pixels
- exact layout: 4 columns x 10 rows
- keep the boss centered and grounded consistently within each frame
- leave transparent breathing room for broad attacks without changing the sheet grid
- no background, no text, no watermark, no opaque matte

Required row order:
1. idle, 4 frames
2. slash, 4 frames
3. charge, 4 frames
4. low_sweep, 4 frames
5. shield_bash, 4 frames
6. teleport_slash, 4 frames
7. corrupt_rift, 4 frames
8. shockwave, 4 frames
9. phase_change, 4 frames
10. defeat, 4 frames

Animation notes:
- each row should communicate the named move clearly at gameplay scale
- telegraph readability matters more than ornate detail
- keep attack visual effects attached to the knight only where they do not imply changed hitboxes

Godot requirement:
This sheet must be slicable into
assets/production_art/characters/bosses/tutorial_knight_alpha_sheet.png with the current row order.
```

## Enemy Sheet Shared Contract

Use this exact sheet contract for Fracture Slime, Clock Mite, and Memory Wisp:

```text
Output a transparent PNG enemy sprite sheet for a top-down RPG.
- exact full sheet size: 192x240 pixels
- exact frame size: 48x48 pixels
- exact layout: 4 columns x 5 rows
- row 1 idle, 4 frames
- row 2 move, 4 frames
- row 3 attack, 4 frames
- row 4 hurt, 4 frames
- row 5 death, 4 frames
- transparent alpha background
- no text, no matte, no hitbox art, no UI, no terrain floor
- keep the enemy centered with a stable ground/contact footprint
- output must be Godot-ready for direct slicing with no row reordering
```

### Fracture Slime

```text
Apply the enemy sheet shared contract to an original Fracture Slime:
- semi-translucent arcane slime with cracked memory-light trapped inside
- dark fantasy first, digital-glitch accents second
- attack row should show a readable lunge or compression release
- hurt row should show brief wobble/fracture reaction
- death row should collapse and dissipate without filling the frame with opaque effects
- keep a beginner-enemy silhouette readable against meadow and waste floors
```

### Clock Mite

```text
Apply the enemy sheet shared contract to an original Clock Mite:
- compact clockwork arachnid/insect enemy with metal legs and faint corrupted timing glyphs
- readable top-down body and leg rhythm
- move row should show scuttle motion
- attack row should show a snap, stab, or spring-loaded bite
- hurt and death rows should remain mechanically readable, not explode into unreadable debris
- do not copy spider monsters from any named game
```

### Memory Wisp

```text
Apply the enemy sheet shared contract to an original Memory Wisp:
- floating spectral memory mote with dark fantasy soul-light and digital backup fragments
- silhouette must stay readable despite translucency
- move row should drift with directional pulse
- attack row should show a compact emission or focused flare
- hurt row should flicker without losing frame-center consistency
- death row should disperse into fragments while preserving transparent PNG edges
```

## Tutorial Knight Arena Background

```text
Create an original 2D battle arena background and floor plate for the Tutorial Knight encounter.

Style:
- dark fantasy training arena with subtle corrupted-digital undertones
- authored alpha-RPG look, not a flat debug board
- no copyrighted or named-game style copying

Primary output contract:
- 1280x720 PNG scene plate
- readable central fight plane with low visual noise
- richer boundary and backdrop depth at outer arena edges
- no player, boss, UI, damage text, prompts, hitboxes, warning cones, logos, or watermarks
- no perspective that makes current combat actors appear detached from the floor

Composition requirements:
- center fight area remains clear for attack warnings and character silhouettes
- boundary ruins, training standards, banners, or distant wall depth can sit outside warning lanes
- floor detail should guide attention inward without creating fake hazards
- lighting may suggest dark fantasy plus digital corruption, but avoid neon wallpaper

Optional approved secondary exports if the tool supports them:
- transparent foreground trim PNG kept away from combat warning lanes
- transparent border decal PNG for arena edges

Godot requirement:
The art must remain visual-only when integrated later. It must not imply collision changes or obscure
Tutorial Knight attack readability.
```

## Post-Generation Intake Checklist

1. Save the raw output and the exact prompt revision in `assets/art_sources/` or its documented
   region subfolder.
2. Record tool, account/plan state, official terms/license page checked, generation date, and export
   settings in `docs/art_pipeline/`.
3. Check image dimensions, alpha, row order, tile grid, edge halos, and style coherence before export
   to `assets/production_art/`.
4. Reject previews, contact sheets, watermarked outputs, sheets with labels, and outputs that require
   gameplay changes to look correct.

