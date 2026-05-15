# LEVEL DESIGN & ENVIRONMENT AUDIT REPORT
## AethelgardPrototype — Godot 4.6

**Audit Date:** 2025  
**Scope:** Exploration scenes, scene transitions, environment variety, asset usage, backgrounds, level gating  
**Files Reviewed:** 30+ GDScript files, 29 .tscn scenes, 7 asset directories, 4 background directories  

---

## FINDINGS — Sorted by Severity

---

### [CRITICAL] — Game-Breaking / Fundamental Issues

---

**#1 — ALL Background Asset Directories Are Empty**  
- **Severity:** CRITICAL  
- **Files:** `scripts/background_manager.gd` (lines 8-42), directories `assets/backgrounds/prologue/`, `assets/backgrounds/chapter1/`, `assets/backgrounds/chapter2/`, `assets/backgrounds/chapter3/`  
- **Description:** The `BG_ASSETS` dictionary in `background_manager.gd` references 30+ PNG files across 4 chapter subdirectories (e.g., `bg_plane_interior_base.png`, `bg_crater_sky.png`, `bg_ironhold_sky.png`). **Every single directory is completely empty.** No background PNGs exist anywhere. The `has_real_asset()` check always returns `false`, causing 100% fallback to procedural ColorRect generation for all scenes.  
- **Suggested Fix:**  
  1. Create or commission actual background PNGs for each chapter area (at minimum: plane interior, glitch crater, forest, oakhaven, ironhold city, underground, clock tower, boss arenas, wasteland, archive).  
  2. Place them in the paths defined in `BG_ASSETS`.  
  3. Alternatively, use the 24 Kenney tile PNGs already in `assets/sprites/mysprites_backgrounds/` as tiling background layers.  

---

**#2 — 200+ Kenney Sprite Assets Registered But Never Load at Runtime**  
- **Severity:** CRITICAL  
- **File:** `scripts/asset_manager.gd` (lines 1–400: ASSET_PATHS dictionary; lines 449–470: scan_all_assets)  
- **Description:** `asset_manager.gd` registers 200+ Kenney asset paths in `ASSET_PATHS` (e.g., `"kenney_slime_blue": "res://assets/sprites/mysprites_enemies/slimeBlue.png"`). The raw PNG files **do exist on disk** (927+ files across `mysprites_enemies/`, `mysprites_characters/`, `mysprites_tiles/`, etc.). However, `scan_all_assets()` uses `ResourceLoader.exists(path)` which requires Godot `.import` metadata files to recognize the resources. If the project has never been opened in the Godot editor with these assets present, the `.import` files won't exist, causing every asset to report "not found" and fall back to colored `ColorRect` placeholders.  
- **Suggested Fix:**  
  1. Open the project in Godot Editor and let it auto-import all PNG files in `assets/sprites/`.  
  2. Verify `.import` files are generated for each PNG.  
  3. Add a startup log line counting how many Kenney assets actually loaded vs. fell back.  

---

**#3 — "archive" Background Location Undefined — 3 Chapter 3 Scenes Get Blank Fallback**  
- **Severity:** CRITICAL  
- **Files:**  
  - `scripts/background_manager.gd` (lines 168–211: `_generate_procedural()` match statement)  
  - `scripts/chapter3/ch3_archive_depths.gd` (line 61)  
  - `scripts/chapter3/ch3_ending.gd` (line 42)  
  - `scripts/chapter3/ch3_kaelthas_betrayal.gd` (line 48)  
- **Description:** Three Chapter 3 scenes call `BackgroundManager.create_background("archive", self)`. The `_generate_procedural()` match block has **no case for "archive"**, so it falls through to `_gen_fallback()` which renders a near-black gradient with a tiny "[Archive]" text label. The Archive — one of the most important narrative locations — has no procedural background generator at all.  
- **Suggested Fix:**  
  1. Add `"archive": return _gen_archive()` to the match block in `_generate_procedural()`.  
  2. Create a `_gen_archive()` function with recursive bookshelves, floating text particles, infinite-depth visual, and amber/teal color palette.  
  3. Add `"archive"` to the docstring list of supported locations.  

---

**#4 — No Chapter 3 Entries in BG_ASSETS Dictionary**  
- **Severity:** CRITICAL  
- **File:** `scripts/background_manager.gd` (lines 8–42: BG_ASSETS const)  
- **Description:** `BG_ASSETS` defines paths for Prologue, Chapter 1, Chapter 2, and Overlays — but contains **zero Chapter 3 entries**. No paths for fractured wastes, archive depths, data stream, or Kaelthas betrayal backgrounds. When real background PNGs are eventually created, Chapter 3 will have no slots to use them.  
- **Suggested Fix:**  
  Add Chapter 3 entries to `BG_ASSETS`:
  ```gdscript
  # Chapter 3
  "wasteland": "res://assets/backgrounds/chapter3/bg_fractured_wastes.png",
  "wasteland_storm": "res://assets/backgrounds/chapter3/bg_wasteland_storm.png",
  "archive": "res://assets/backgrounds/chapter3/bg_archive_depths.png",
  "archive_core": "res://assets/backgrounds/chapter3/bg_archive_core.png",
  "data_stream": "res://assets/backgrounds/chapter3/bg_data_stream.png",
  "kaelthas_arena": "res://assets/backgrounds/chapter3/bg_kaelthas_arena.png",
  ```

---

### [HIGH] — Significant Visual/Quality Issues

---

**#5 — ALL Level Environments Built Entirely from Flat ColorRects — Zero Texture Usage**  
- **Severity:** HIGH  
- **Files affected (non-exhaustive):**  
  - `scripts/chapter1/ch1_glitch_crater.gd` — sky, nebula, aurora, ground, crater, rocks all ColorRect  
  - `scripts/chapter1/ch1_elara_meeting.gd` — forest clearing: flat green + brown rectangles  
  - `scripts/chapter1/ch1_path_to_oakhaven.gd` — forest path: all ColorRect  
  - `scripts/chapter1/ch1_oakhaven_village.gd` — top-down village: streets, buildings, NPCs all ColorRect  
  - `scripts/chapter1/ch1_tutorial_knight.gd` — boss arena: single floor + 3 platforms as ColorRect  
  - `scripts/chapter2/ch2_arena_district.gd` — arena walls, floor, platforms: ColorRect  
  - `scripts/chapter2/ch2_clock_tower.gd` — 5-floor tower: walls, floors, gears all ColorRect  
  - `scripts/chapter2/ch2_underground_network.gd` — dungeon: corridors, pipes, corruption zones all ColorRect  
  - `scripts/chapter2/ch2_administrator_boss.gd` — city square: buildings, lamps, data streams all ColorRect  
  - `scripts/chapter2/ch2_ironhold_city.gd` — 3000×2500 city map: streets, buildings, steam vents all ColorRect  
  - `scripts/chapter3/ch3_data_stream.gd` — lanes, obstacles, rider node: all ColorRect  
- **Description:** Every single play area across all 3 chapters constructs its visual environment using programmatic `ColorRect.new()` calls. No scene uses `Sprite2D`, `TextureRect`, `TileMap`, or any other textured node for level geometry. The player sees only flat colored rectangles with no detail, shading, or texture. This makes _every_ location visually indistinguishable at a glance.  
- **Suggested Fix:**  
  1. Replace floor/wall `ColorRect` nodes with `Sprite2D` using Kenney tile PNGs from `mysprites_tiles/` (245 tiles available).  
  2. Use `TextureRect` with repeat mode for large surfaces.  
  3. Add `Sprite2D` decoration items from `mysprites_items/` (18 PNGs) for environmental storytelling.  
  4. Replace enemy placeholder rects with `mysprites_enemies/` sprites (100+ PNGs).  

---

**#6 — 927 Kenney Sprites on Disk, Zero Used in Level Construction**  
- **Severity:** HIGH  
- **Files:** All scene scripts (see #5), `assets/sprites/mysprites_*/` directories  
- **Description:** The project ships with 927+ Kenney PNG sprite assets:  
  - `mysprites_enemies/`: 100+ enemy sprites (slime, bat, spider, ghost, snake, etc.)  
  - `mysprites_tiles/`: 245+ platform and terrain tiles  
  - `mysprites_characters/`: 65 character sprites  
  - `mysprites_items/`: 18 collectible item sprites  
  - `mysprites_ui/`: 88+ UI element sprites  
  - `mysprites_effects/`: 90+ VFX sprites (slash, fire, smoke, spark)  
  - `mysprites_backgrounds/`: 24 background tile sprites  
  
  None of these are referenced in ANY scene construction code. `AssetManager.create_sprite_node()` handles the real→placeholder fallback, but no level build function calls it for environmental objects (floors, walls, decorations). Only player/enemy sprites go through `AssetManager`.  
- **Suggested Fix:**  
  1. In each `_build_*_environment()` function, replace `ColorRect.new()` wall/floor/platform calls with `AssetManager.create_sprite_node("kenney_tile_*", size)`.  
  2. Add decorative `Sprite2D` objects using items, effects, and background tiles.  
  3. Create a `LevelBuilder` utility class that constructs tiled environments from the Kenney tileset.  

---

**#7 — Parallax Background System Exists But Is Never Used**  
- **Severity:** HIGH  
- **File:** `scripts/background_manager.gd` (line 1007: `create_parallax_background()`)  
- **Description:** `BackgroundManager` defines a `create_parallax_background()` function for Node2D-based scenes (combat, exploration) that creates a `ParallaxBackground` with multiple layers at different scroll speeds. **This function is never called anywhere in the entire project.** All Node2D scenes either build their own single-layer ColorRect backgrounds or don't use BackgroundManager at all.  
- **Suggested Fix:**  
  1. In `ch1_glitch_crater.gd`, `ch1_path_to_oakhaven.gd`, `ch2_clock_tower.gd`, `ch2_underground_network.gd`, and `ch2_administrator_boss.gd` — call `BackgroundManager.create_parallax_background(location, self)` instead of building single-layer ColorRect backgrounds.  
  2. Alternatively refactor scene scripts to use `BackgroundManager.create_background()` which already falls back gracefully.  

---

**#8 — 11 of 17 Gameplay Scenes Don't Use BackgroundManager At All**  
- **Severity:** HIGH  
- **Files that DO use BackgroundManager:**  
  - `prologue/flight_707_cinematic.gd` → "plane_interior"  
  - `chapter1/ch1_shatter_transition.gd` → "shatter_bridge"  
  - `chapter2/ch2_ironhold_gate.gd` → "ironhold_city"  
  - `chapter2/ch2_seraphina_encounter.gd` → "ironhold_arena"  
  - `chapter3/ch3_ironhold_departure.gd` → "ironhold_city"  
  - `chapter3/ch3_fractured_wastes.gd` → "wasteland"  
  - `chapter3/ch3_archive_depths.gd` → "archive" (broken — see #3)  
  - `chapter3/ch3_ending.gd` → "archive" (broken — see #3)  
  - `chapter3/ch3_kaelthas_betrayal.gd` → "archive" (broken — see #3)  
- **Files that build their OWN backgrounds (bypassing BackgroundManager):**  
  - `prologue/crash_sequence.gd`  
  - `chapter1/ch1_glitch_crater.gd`  
  - `chapter1/ch1_elara_meeting.gd`  
  - `chapter1/ch1_path_to_oakhaven.gd`  
  - `chapter1/ch1_oakhaven_village.gd`  
  - `chapter1/ch1_tutorial_knight.gd`  
  - `chapter2/ch2_arena_district.gd`  
  - `chapter2/ch2_ironhold_city.gd`  
  - `chapter2/ch2_clock_tower.gd`  
  - `chapter2/ch2_underground_network.gd`  
  - `chapter2/ch2_administrator_boss.gd`  
  - `chapter3/ch3_data_stream.gd`  
- **Description:** A centralized background system exists with procedural generators for 17 distinct locations plus parallax support. But the majority of scenes ignore it and build ad-hoc ColorRect backgrounds inline. This defeats the purpose of having a background manager and prevents consistent art direction or easy asset upgrades.  
- **Suggested Fix:**  
  Route ALL scenes through `BackgroundManager.create_background()` or `create_parallax_background()`. Each scene's `_build_*_environment()` should delegate background creation to BackgroundManager, while keeping only scene-specific foreground objects (platforms, NPCs, triggers) in the scene script.  

---

**#9 — ch1_tutorial_knight.gd Boss Arena Has Minimal Environment**  
- **Severity:** HIGH  
- **File:** `scripts/chapter1/ch1_tutorial_knight.gd` (environment setup section)  
- **Description:** The Tutorial Knight boss arena — the first major boss encounter — consists of: one floor `ColorRect` (1280×200), 3 small platform `ColorRect`s (200×15 each), and 2 invisible wall colliders. The background is a single full-screen `ColorRect` with a grid overlay. There's no arena decoration, no crowd, no environmental storytelling. This is the player's first boss fight and it looks like a debug test level.  
- **Suggested Fix:**  
  1. Add `BackgroundManager.create_parallax_background("tutorial_arena", self)` for a multi-layer background.  
  2. Use Kenney tiles from `mysprites_tiles/` for floor and platforms.  
  3. Add environmental details: torch sprites, broken pillars, arena boundary walls with texture.  
  4. Add a bridge railing or backdrop to establish the "Shatter Bridge" narrative context.  

---

**#10 — ch2_clock_tower.gd Gear Decorations Are Plain ColorRects**  
- **Severity:** HIGH  
- **File:** `scripts/chapter2/ch2_clock_tower.gd` (lines 153–175: `_create_gear_decorations()`)  
- **Description:** The Clock Tower's signature visual element — decorative gears — are rendered as rotating plain colored squares (`ColorRect` with `pivot_offset`). Gears should be circular with teeth, but `ColorRect` only produces rectangles. The result is 11 rotating brown squares scattered throughout the tower. The `mysprites_effects/` folder contains gear-like sprites that could be used.  
- **Suggested Fix:**  
  1. Create a gear sprite or use a circular Kenney sprite from `mysprites_effects/`.  
  2. Replace `ColorRect` gears with `Sprite2D` nodes.  
  3. Add interlocking gear animations where adjacent gears rotate in opposite directions.  

---

### [MEDIUM] — Functional / Quality Concerns

---

**#11 — NPC Nodes Referenced in Scene Scripts May Not Exist in .tscn Files**  
- **Severity:** MEDIUM  
- **Files:**  
  - `scripts/exploration/oakhaven.gd` — references `"NPCs/FlickeringNPC"`, `"NPCs/Blacksmith"`, `"NPCs/Apothecary"` via `get_node_or_null()`  
  - `scripts/chapter1/ch1_oakhaven_village.gd` — references `"NPCs/Farmer"`, `"NPCs/Child"`, `"NPCs/Guard"` via `get_node_or_null()`  
- **Description:** These scripts use `get_node_or_null()` to find Area2D NPCs in the scene tree, then connect `body_entered` signals. If the .tscn files don't contain these nodes (they're likely purely programmatic scenes), the NPCs will silently not appear. The scripts handle `null` gracefully (no crash), but the player loses all NPC interaction in those scenes.  
- **Suggested Fix:**  
  1. Verify that `scenes/exploration/oakhaven_explore.tscn` and `scenes/chapter1/oakhaven_village.tscn` contain the expected NPC nodes as Area2D children.  
  2. If they don't exist in the .tscn, add programmatic NPC creation as a fallback (similar to how `ch1_oakhaven_village.gd` creates the player node if `$Player` is null).  

---

**#12 — BackgroundManager Docstring Is Outdated — Missing Supported Locations**  
- **Severity:** MEDIUM  
- **File:** `scripts/background_manager.gd` (lines 127-132: `create_background()` docstring)  
- **Description:** The docstring for `create_background()` lists supported locations but omits `"wasteland"` and `"chapter_end"` which ARE implemented, and doesn't mention that `"archive"` is NOT implemented despite being called. The documented list:  
  ```
  plane_interior, night_sky, bsod, boot_screen, crash_sequence,
  glitch_crater, forest_twilight, oakhaven, tutorial_arena,
  shatter_bridge, ironhold_sky, ironhold_city, ironhold_market,
  ironhold_arena, ironhold_clock_tower, underground,
  admin_boss_arena, chapter_end
  ```
  Missing from list: `wasteland` (implemented), `chapter_end` (implemented)  
  Listed but working differently: `ironhold_city` and `ironhold_market` share the same generator  
- **Suggested Fix:**  
  Update the docstring to reflect all actually-supported locations and mark `"archive"` as TODO.  

---

**#13 — ch2_ironhold_city.gd District Gating Explained Only via Print Statements**  
- **Severity:** MEDIUM  
- **File:** `scripts/chapter2/ch2_ironhold_city.gd`  
- **Description:** The ironhold city hub gates access to districts via story flags (arena → Seraphina → underground → clock tower → admin boss). When a player tries to enter a locked district, the only feedback is a dialogue line. There is no visual indicator on the map showing which districts are locked/unlocked, no minimap markers, and no quest log hint. The gating chain is:  
  - Arena District: always available  
  - Seraphina Encounter: requires `ch2_arena_bronze_complete`  
  - Underground Network: requires `ch2_seraphina_met`  
  - Clock Tower: requires `ch2_underground_complete`  
  - Administrator Boss: requires `ch2_clock_tower_complete`  
  
  This is entirely linear with no visual guidance.  
- **Suggested Fix:**  
  1. Add colored indicators to district markers on the city map (green = available, red = locked, gray = completed).  
  2. Show a tooltip or label when hovering near a locked district explaining the prerequisite.  
  3. Consider a quest tracker HUD element showing the current chapter objective.  

---

**#14 — ch3_data_stream.gd Player "Rider" Is a 30×40 Cyan Rectangle**  
- **Severity:** MEDIUM  
- **File:** `scripts/chapter3/ch3_data_stream.gd` (lines 63-69: rider_node creation)  
- **Description:** The Data Stream sequence — an on-rails action segment — represents the player as a plain 30×40 cyan `ColorRect`. Obstacles and data fragments are also ColorRects. The `mysprites_characters/` folder has 65 character sprite PNGs that could be used. This is a unique genre-shift moment that should feel visually distinct.  
- **Suggested Fix:**  
  1. Use `AssetManager.create_sprite_node("player", Vector2(30, 40))` for the rider.  
  2. Use `mysprites_items/` sprites for data fragments.  
  3. Use `mysprites_effects/` sprites for obstacles.  

---

**#15 — Exploration Map Boundaries Are Hardcoded with No Consistent Scale**  
- **Severity:** MEDIUM  
- **Files:**  
  - `scripts/exploration/oakhaven.gd` — map bounds: 2000×1500  
  - `scripts/chapter1/ch1_oakhaven_village.gd` — map bounds: 2500×2000  
  - `scripts/chapter2/ch2_ironhold_city.gd` — map bounds: 3000×2500  
- **Description:** Each exploration scene defines its own map boundaries with different sizes, created by spawning 4 `StaticBody2D` walls at the edges. There is no shared constant or level-size system. The player has no visual indicator of map boundaries until they physically hit an invisible wall. Scale jumps significantly between Oakhaven (2000×1500) and Ironhold (3000×2500).  
- **Suggested Fix:**  
  1. Define map size constants in a shared config (e.g., `LevelConfig.MAP_SIZES`).  
  2. Add visible boundary walls using textured sprites instead of invisible static bodies.  
  3. Add minimap or edge-of-map visual indicator.  

---

**#16 — ch2_underground_network.gd Corruption Zones Use Invisible Collision**  
- **Severity:** MEDIUM  
- **File:** `scripts/chapter2/ch2_underground_network.gd` (lines 155–175: `_create_corruption_zone()`)  
- **Description:** Corruption zones are hazard areas that damage the player on contact. They're rendered as faintly transparent purple `ColorRect`s (`Color(0.5, 0, 0.5, 0.2)`) — almost invisible against the dark underground background (`Color(0.06, 0.04, 0.08)`). The player can easily walk into damage zones without seeing them. There are no particle effects, no warning glow, no pulsing animation.  
- **Suggested Fix:**  
  1. Increase alpha to at least 0.4 and add a pulsing tween animation.  
  2. Add particle effects (corrupted sparkles) using `mysprites_effects/` sprites.  
  3. Add a proximity warning via SFX or screen tint when near a corruption zone.  

---

**#17 — ch2_clock_tower.gd Time Zones Have Minimal Visual Distinction**  
- **Severity:** MEDIUM  
- **File:** `scripts/chapter2/ch2_clock_tower.gd` (lines 177–200+: `_create_time_zone()`)  
- **Description:** Time zones — the clock tower's core mechanic — are represented by semi-transparent `ColorRect`s with a text label. Slow zones are blue-tinted, fast zones are assumed to be a different color. The visual is subtle and easily missed during platforming. No particle effects, no screen-space distortion, no audio cue when entering a time zone.  
- **Suggested Fix:**  
  1. Add screen-space shader effects (e.g., time dilation blur for slow zones, speed lines for fast zones).  
  2. Add particle emitters that move at the zone's speed multiplier.  
  3. Add an audio rumble/hum that changes pitch based on time speed.  

---

**#18 — ch1_path_to_oakhaven.gd and ch1_elara_meeting.gd Share Near-Identical Forest Visuals**  
- **Severity:** MEDIUM  
- **Files:**  
  - `scripts/chapter1/ch1_elara_meeting.gd` — builds forest clearing with ColorRects  
  - `scripts/chapter1/ch1_path_to_oakhaven.gd` — builds forest path with ColorRects  
- **Description:** Both scenes construct "forest" environments from the same dark green/brown ColorRect palette. Without textured assets, both scenes appear almost identical to the player despite being narratively distinct locations (an open clearing vs. a constrained forest path). The progression from "meeting Elara" to "walking the path" has no visual landmark change.  
- **Suggested Fix:**  
  1. Use different BackgroundManager palettes (clearing = brighter/more open, path = darker/more enclosed).  
  2. Add unique environmental props: the clearing could have a crystal pond, the path could have fallen trees.  
  3. Use Kenney tiles to differentiate ground textures (grass vs. dirt path).  

---

**#19 — Scene Transitions All Work But Have No Loading Screen Variety**  
- **Severity:** MEDIUM  
- **Files:** All scene scripts that call `SceneTransitions.change_scene()`  
- **Description:** All 20+ scene transitions reference valid .tscn files and work correctly. However, every transition uses either `SceneTransitions.change_scene()` with default style or `SceneTransitions.TransitionStyle.COMBAT_ENTRY`. There's no variety in transition effects to match the narrative context (e.g., "shatter" effects for reality breaks, "glitch" effects for entering corrupted areas, "dissolve" for time-skip moments).  
- **Suggested Fix:**  
  1. Add transition styles: `GLITCH_WARP`, `REALITY_SHATTER`, `FADE_TO_STATIC`, `DATA_STREAM`.  
  2. Use `COMBAT_ENTRY` only for combat transitions, `GLITCH_WARP` for chapter boundaries, fade for calm moments.  

---

### [LOW] — Polish / Best Practice

---

**#20 — Decorative Elements (Torches, Lamps, Pipe Lights) Are Tiny ColorRects**  
- **Severity:** LOW  
- **Files:**  
  - `scripts/chapter2/ch2_arena_district.gd` (torches: 10×20 orange rectangles at y=30)  
  - `scripts/chapter2/ch2_administrator_boss.gd` (lamps: 6×15 rectangles; data streams: 2px-wide lines)  
  - `scripts/chapter2/ch2_underground_network.gd` (data pipes: 3px-wide neon rectangles)  
- **Description:** All decorative lighting and atmospheric elements are tiny `ColorRect` nodes (some as small as 6×15 pixels). These serve as placeholders but produce virtually no visual impact. The `mysprites_effects/` folder contains 90+ particle/VFX sprites including fire, flames, sparks, and glow effects that could replace these.  
- **Suggested Fix:**  
  Use `Sprite2D` with Kenney effects (fire, flame, spark PNGs) for torches and lamps. Add `PointLight2D` nodes for actual lighting.  

---

**#21 — No TileMap Usage Across Entire Project**  
- **Severity:** LOW  
- **Files:** All scene scripts; `assets/sprites/mysprites_tiles/` (245 tiles)  
- **Description:** Godot's `TileMap` system is designed for efficient 2D level construction. The project has 245 Kenney platform tiles perfectly suited for TileMap usage, but every level is constructed via individual `ColorRect` and `StaticBody2D` nodes created programmatically. This is less performant (each rectangle is a separate draw call) and produces visually flat results.  
- **Suggested Fix:**  
  1. Create `TileSet` resources from the Kenney tile sprites.  
  2. Use `TileMap` for floor, wall, and platform geometry in exploration and combat scenes.  
  3. This also enables auto-tiling for smooth terrain transitions.  

---

**#22 — No PointLight2D / CanvasModulate Lighting in Any Scene**  
- **Severity:** LOW  
- **Files:** All scene scripts  
- **Description:** No scene uses Godot's 2D lighting system. The underground network, clock tower, and boss arenas would benefit dramatically from `PointLight2D` (torch/lamp glow, corruption glow) and `CanvasModulate` (global scene tinting for atmosphere). Currently, "dark" scenes are just dark `ColorRect` backgrounds with no contrast or focal points.  
- **Suggested Fix:**  
  Add `PointLight2D` nodes at torch/lamp/glow positions. Use `CanvasModulate` for global ambiance per scene (warm yellow for Oakhaven, cold blue for underground, red for boss arenas).  

---

**#23 — ch3_fractured_wastes.gd Exploration Uses Number Keys Instead of Movement**  
- **Severity:** LOW  
- **File:** `scripts/chapter3/ch3_fractured_wastes.gd` (lines 145–165: `_input()`)  
- **Description:** The Fractured Wastes exploration phase — narratively a survival scenario — uses number key presses (1–5) to "visit" locations instead of actual player movement through a map. This reduces what should be an atmospheric exploration scene to a text-menu selection. Every other exploration scene in the game uses actual player movement with a top-down character controller.  
- **Suggested Fix:**  
  1. Implement a Node2D-based exploration map (like Oakhaven/Ironhold) with Area2D triggers at each location.  
  2. Keep the corruption storm as a real-time environmental hazard the player must physically avoid.  
  3. Add visual shelter locations the player can physically enter.  

---

**#24 — asset_manager.gd create_sprite_node() Centers Sprites Inconsistently**  
- **Severity:** LOW  
- **File:** `scripts/asset_manager.gd` (lines 478–503: `create_sprite_node()`)  
- **Description:** When a real asset is available, `Sprite2D` is returned (centered by default). When falling back, a `ColorRect` is returned with `position = -size / 2` to simulate centering. This produces different anchor behavior: `Sprite2D` centers on its position, while `ColorRect` offsets from its position. Any code positioning these nodes will behave differently depending on whether the real asset loaded or not.  
- **Suggested Fix:**  
  Wrap the `ColorRect` fallback in a `Node2D` container with the rect as a child, matching `Sprite2D` centering behavior exactly.  

---

**#25 — No Auto-Save Checkpoints in Chapter 1 or Chapter 2 Combat Scenes**  
- **Severity:** LOW  
- **Files:**  
  - `scripts/chapter1/ch1_tutorial_knight.gd` — no `GameManager.auto_save()` call  
  - `scripts/chapter2/ch2_arena_district.gd` — no auto-save  
  - `scripts/chapter2/ch2_administrator_boss.gd` — no auto-save  
- **Description:** Chapter 3 scenes consistently call `GameManager.auto_save()` on entry (e.g., `ch3_archive_depths.gd` line 27, `ch2_underground_network.gd` line 59). But the Tutorial Knight boss, Arena District, and Administrator Proxy boss — all high-risk combat scenes — don't auto-save. If the player dies or the game crashes, progress is lost.  
- **Suggested Fix:**  
  Add `GameManager.auto_save()` at the start of every combat scene's `_ready()` function.  

---

**#26 — ch2_seraphina_choice.gd and ch2_chapter_end.gd Build Backgrounds Inline**  
- **Severity:** LOW  
- **Files:**  
  - `scripts/chapter2/ch2_seraphina_choice.gd` — builds background with ColorRects  
  - `scripts/chapter2/ch2_chapter_end.gd` — builds background with ColorRects  
- **Description:** Both dialogue-heavy scenes create their own ColorRect backgrounds instead of using BackgroundManager. `ch2_seraphina_choice.gd` should use `"ironhold_city"` or a custom `"seraphina_courtyard"` background. `ch2_chapter_end.gd` should use `"chapter_end"` which IS implemented in BackgroundManager.  
- **Suggested Fix:**  
  Replace inline background construction with `BackgroundManager.create_background()` calls.  

---

## SUMMARY

| Severity | Count | Key Theme |
|----------|-------|-----------|
| CRITICAL | 4 | Missing background assets, broken asset pipeline, undefined location |
| HIGH | 6 | 100% ColorRect environments, unused sprites, unused parallax system |
| MEDIUM | 9 | NPC references, invisible hazards, no visual gating, inconsistent scale |
| LOW | 7 | No TileMap, no lighting, missing checkpoints, Polish items |
| **TOTAL** | **26** | |

### Priority Remediation Order:
1. **Fix #2 first** — Open project in Godot Editor to generate `.import` files for all Kenney PNGs.
2. **Fix #3** — Add `_gen_archive()` to BackgroundManager immediately (3 scenes are broken).
3. **Fix #8 + #5** — Route all scenes through BackgroundManager AND start replacing ColorRect floors/walls with Kenney tiles.
4. **Fix #1 + #4** — Create or commission actual background PNGs (or enhance procedural generators).
5. **Fix #6 + #7** — Integrate Kenney sprites into level construction; activate parallax system.
6. **Address MEDIUM findings** (gating UI, hazard visibility, NPC verification).
7. **Polish LOW findings** (lighting, TileMap, checkpoints, transition variety).
