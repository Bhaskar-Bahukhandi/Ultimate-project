# Phase 10M-C2 V2 Style Notes

## Direction

V2 stays original procedural pixel art, but aims for a stronger dark-fantasy and digital-glitch action-RPG read than the V1 atlas set.

## Palette

- Base values stay dark: midnight indigo, bruised charcoal, tarnished steel, deep forest, ink-purple void.
- Readability accents are selective and bright: cyan consent light, magenta corruption shards, warm ritual gold, blood-red danger.
- Adjacent regions should avoid sharing the same accent hierarchy. Oakhaven leans green and wood-gold; Ironhold leans iron/ember; Mirror City leans glass-cyan; Root of Heaven uses root-violet plus pale kernel light.

## Outline And Shape Rules

- Character silhouettes use a dark outer outline with internal shadow breaks rather than flat rectangles.
- Frame occupancy is intentionally higher than V1: top-down figures target roughly 22-27 pixels of a `32x32` frame and combat figures target roughly 44-58 pixels of a `64x64` frame.
- Weapons, shields, capes, staffs, packs, and corrupted protrusions should widen or angle the silhouette so animation rows read before color is considered.
- Glitch highlights should cut through silhouettes as thin displaced pixels, seams, and rune sparks, not broad neon flood fill.

## Shading

- Use at least shadow, midtone, and highlight on major body masses.
- Add a cool rim highlight on player/boss steel or consent-tech surfaces.
- Keep transparency clean around sprites and VFX. The checkerboard should reveal shape, not leftover boxes.
- Tiles use edge wear, cracks, tufting, metal seams, wave foam, or archive sigils to reduce flat block reads.

## Proportions

- Kaelen is compact but heroic: readable head, shoulders, long coat/cape split, glowing root seam, clear sword profile.
- The Tutorial Knight is broader and heavier than the player with shield mass, helm crest, plated legs, and corruption vents.
- NPCs differ by costume silhouette:
  - Elara: hooded mantle and staff-like arcane profile.
  - Seraphina: disciplined coat, shoulder guard, record tablet.
  - Lyra: agile scarf, quiver/satchel profile.
  - Null Clerk: tall archive robe and seal halo.
  - Assembly Runner: messenger pack and rushing split-coat shape.

## Animation Readability

- Idle rows breathe or pulse without losing silhouette.
- Walk/run rows show leg separation and weight shift.
- Combat attack rows show anticipation, active strike line, and follow-through in the sword silhouette.
- Hurt and death rows should break the neutral posture.
- VFX should reinforce active frames with sharper arcs, radial sparks, trails, and corruption shards.

## Region Visual Language

- Oakhaven: tufted grass, leaf-shadow paths, warm timber, hedge edges, flowers, hand-made sign marks.
- Ironhold: bricks, riveted plates, forge heat, pipes, rails, vents, crates.
- Fractured Wastes: cracked earth, shard intrusions, magenta rune tearing, dust edges, pits.
- Forgotten Sectors: null floors, archive walls, dossiers, seals, memory residue, void thresholds.
- Mirror City: glass panels, reflection veins, plaza stone, fountain light, arch facets, mirror sigils.
- Cathedral Server: server aisles, altar grids, firewall lattices, choir wires, control consoles.
- Memory Ocean: layered water, tide foam, salvage islands, drifting logs, backup-memory glow.
- Root of Heaven: root knots, kernel circuits, witness glyphs, portals, throne seams.

## V2 Improvements Over V1

- Larger and less boxy character occupancy.
- More differentiated NPC and enemy silhouettes.
- Stronger Tutorial Knight boss presence and attack poses.
- More readable combat weapon arcs and motion intent.
- VFX and icons use depth, sparks, inner highlights, and stronger silhouette framing.
- Tilesets use motif-specific texture and edge detail rather than flat palette blocks.
