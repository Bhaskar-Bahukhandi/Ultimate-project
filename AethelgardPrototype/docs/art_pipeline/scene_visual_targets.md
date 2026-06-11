# Scene Visual Targets

## Why M4 Exists

M3 screenshots show a repeated failure mode: individually improved props and decals do not make a
coherent world when the floor families, walls, backgrounds, marker language, and character scale do
not share the same authored visual system. The next visual pass should replace weak families of art,
not add another layer of patches.

## Worst Visual Issues Ranked

1. Oakhaven, Ironhold, and Fractured Wastes still expose repeated prototype tile cadence across the largest playable spaces.
2. Region architecture is not authored as connected buildings, walls, roads, and shadows; several facades still read as box masses with props placed over them.
3. Late revisit hubs retain wrapper-room composition because their floor and backdrop art lack region-specific architecture.
4. Shared generated decals and props are not stylistically strong enough to bridge all regions.
5. Lighting and background depth are flat, especially where characters sit on visually busy floors.
6. Marker and revisit UI language still competes with scene identity in hub spaces.
7. World map and arena visuals remain serviceable prototype presentation, not a cohesive RPG art layer.

## Targets

| Scene/Region | Current Screenshot Quality Issue | Desired Look | Required Assets | Scale Notes | Composition Notes | What Not To Do |
| --- | --- | --- | --- | --- | --- | --- |
| Oakhaven | Grass and path repeat in visible cells; roofs need architecture support | walkable warm village route with meadows, paths, fences, and grounded cottages | full meadow/path/wood tileset, cottage kit, fences, herbs, tree-line background, sign style | keep 32 px top-down scale and calm floors under NPCs | paths should lead to exits and farming herb patch | do not hide repeated tiles under broad translucent slabs |
| Ironhold | Metal floors are noisy and buildings remain blocky | legible forge district with roads, mine/training apron, stacked industry | industrial road tiles, brick/plate edges, forge kit, pipe kit, crates, skyline smoke plate | darker traversal strips should lift player and labels | organize focal areas around training marker and NPC groups | do not stamp high-contrast panels over all walkable ground |
| Fractured Wastes | Cracked terrain repeats and shelter/core composition reads prototype | irregular dangerous route with readable safe trails and shard pockets | scar tile family, trail edges, shard clusters, shelter kit, void-haze background | keep hazard contrast stronger than ground noise | form paths between shelter, core, and shard farming beat | do not use one giant scar overlay |
| Forgotten Sectors | Hub still resembles a wrapper room | erased archive aisle with shelves, seals, case desk, cleanup focal point | archive tile family, wall shelves, dossiers, court seal floor insets, null backdrop | markers should feel smaller than shelves and floor architecture | memory cleanup and deleted case file should occupy authored stations | do not let cyan wrapper strips define the room |
| Mirror City | Reflection space is still thin | elegant mirrored civic pause space | glass tiles, mirror frames, plinths, skyline/reflection plate | keep prompts backed by low-noise surfaces | mirror terminal as calm central focal point | do not fill background with noisy reflections behind text |
| Cathedral Server | Consoles sit on board-like floor | server nave with firewall drill framed by architecture | server aisle tiles, rack wall panels, console kit, firewall gate, circuit light plate | warnings and player must remain bright | drill area framed, return path still plain and clear | do not turn floor into dense glowing circuit wallpaper |
| Memory Ocean | Salvage props help but space still hub-like | tide-and-island salvage staging area | island edge tiles, wet path tiles, salvage dock props, ocean horizon, tide decals | water movement should stay lower contrast than prompts | salvage run at grounded dock or cache island | do not use cyan transit strips as the identity |
| Saved Assembly | Civic side marker floats in wrapper space | lived-in supply hall buffer | civic floor tiles, aid board, benches, crates, banner trims | props support not crowd label | return gate separate from supply board | do not add repeat farming visual language |
| Human Patch Lab | Clinical terminal lacks strong bay architecture | quiet unsettling lab bay | clean lab tiles, tank props, record terminal, cold background plates | pale assets need contrast behind labels | focus on record terminal with threatening periphery | do not spill route-state UI into lab art |
| Root of Heaven Prep | Root art competes with prompt and still reads generated | solemn sealed threshold before final route | circuit-root tile family, prep terminal, vast root lattice backdrop, restrained foreground arch | terminal and player silhouette first | frame prep terminal and sealed path | do not imply final-choice entrance is open |
| Tutorial Knight Arena | Upper space still thin and floor remains reusable board | authored training arena with readable warning-safe fight plane | arena floor plate, boundary ruins, backdrop wall/banners, trims | combat actors and telegraphs dominate | atmosphere sits outside warning lanes | do not change hitboxes or obscure attacks |
| Combat Arena | reusable arena reads abstract | neutral but intentional encounter stage | arena base plate, border kit, neutral backdrop | broad center stays readable | props at edge only | do not make encounter art region-specific too early |
| World Map | current prototype nodes and labels are utility-first | readable free-travel atlas with clear locked/unlocked/story-only states | map base, route nodes, state icons, restrained legend panel | test at current window sizes | navigation hierarchy before embellishment | do not copy commercial map language |

