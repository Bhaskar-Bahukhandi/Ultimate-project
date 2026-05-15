# SPRITE & ASSET PLACEMENT GUIDE — Project Aethelgard

## How It Works

The game uses **AssetManager** (autoload) to scan for real sprites at startup. If a file exists at the expected path, it loads the real sprite. If not, it draws a colored rectangle placeholder. **You just drop PNG files into the right folders — no code changes needed.**

BackgroundManager works identically for backgrounds.

---

## FOLDER STRUCTURE TO CREATE

Create these folders inside `AethelgardPrototype/`:

```
assets/
├── sprites/
│   ├── player/
│   │   └── player.png                          ← generic player sprite (32×48)
│   ├── characters/                              ← full-body cutscene characters
│   │   ├── kaelen.png
│   │   ├── elara.png
│   │   ├── mira.png
│   │   ├── tutorial_knight.png
│   │   ├── elder.png
│   │   ├── farmer_jenkins.png
│   │   ├── seraphina.png
│   │   ├── nyx.png
│   │   ├── pip.png
│   │   └── gate_guard.png
│   ├── portraits/                               ← small face icons (72×72)
│   │   ├── kaelen.png
│   │   ├── kaelen_internal.png                  ← Kaelen's inner voice variant
│   │   ├── elara.png
│   │   ├── mira.png
│   │   ├── system.png                           ← "System" / "Data Vision" speaker
│   │   ├── unknown.png                          ← "???" speaker
│   │   ├── tutorial_knight.png
│   │   ├── elder.png
│   │   ├── seraphina.png
│   │   ├── nyx.png
│   │   └── gate_guard.png
│   ├── enemies/
│   │   ├── oakhaven/
│   │   │   ├── slime.png                        ← Green Slime (tutorial enemy)
│   │   │   └── boar.png                         ← Corrupted Boar
│   │   ├── ironhold/
│   │   │   ├── spider.png                       ← Clockwork Arachnid
│   │   │   └── turret.png                       ← Steam-Vent Sentinel
│   │   └── necropolis/
│   │       ├── skeleton.png                     ← Bone Construct
│   │       └── wraith.png                       ← Wraith
│   └── bosses/
│       ├── oakhaven/
│       │   └── knight.png                       ← Tutorial Knight boss
│       ├── ironhold/
│       │   └── hulk.png                         ← The Gear Hulk boss
│       └── necropolis/
│           └── lich.png                         ← Lich Lord boss
├── backgrounds/
│   ├── prologue/
│   │   ├── bg_plane_interior_base.png           ← airplane cabin, normal
│   │   ├── bg_plane_interior_glitch1.png        ← cabin with slight glitch
│   │   ├── bg_plane_interior_glitch2.png        ← cabin with more glitch
│   │   ├── bg_plane_interior_glitch3.png        ← cabin heavily corrupted
│   │   ├── bg_plane_interior_glitch4.png        ← cabin nearly destroyed
│   │   ├── bg_plane_window_sky.png              ← night sky through window
│   │   ├── bg_bsod.png                          ← blue screen of death
│   │   ├── bg_boot_screen.png                   ← dark boot/loading screen
│   │   └── bg_crash_sequence.png                ← crash/transition screen
│   ├── chapter1/
│   │   ├── bg_crater_sky.png                    ← glitch crater, purple sky
│   │   ├── bg_crater_ground.png                 ← glitch crater ground (BackgroundManager only)
│   │   ├── bg_forest_twilight.png               ← twilight forest path
│   │   ├── bg_oakhaven_sky.png                  ← village parallax: sky layer
│   │   ├── bg_oakhaven_buildings_far.png        ← village parallax: distant buildings
│   │   ├── bg_oakhaven_buildings_near.png       ← village parallax: close buildings
│   │   ├── bg_oakhaven_ground.png               ← village parallax: ground/grass
│   │   ├── bg_arena_tutorial.png                ← tutorial combat arena
│   │   └── bg_shatter_bridge.png                ← chapter end bridge scene
│   ├── chapter2/
│   │   ├── bg_ironhold_sky.png                  ← orange/copper sky
│   │   ├── bg_ironhold_industrial.png           ← factory/industrial backdrop
│   │   ├── bg_ironhold_market.png               ← market district
│   │   ├── bg_ironhold_arena.png                ← Ironhold combat arena
│   │   ├── bg_ironhold_clock_tower.png          ← clock tower backdrop
│   │   ├── bg_underground.png                   ← underground tunnels
│   │   └── bg_admin_boss_arena.png              ← Administrator boss arena (dark red)
│   ├── overlays/
│   │   ├── bg_overlay_scanlines.png             ← CRT scanline overlay (tileable)
│   │   └── bg_overlay_static.png                ← static noise overlay
│   └── weather/
│       ├── bg_weather_rain.png                  ← rain particle overlay
│       └── bg_weather_fog.png                   ← fog overlay
├── tilesets/
│   ├── oakhaven/
│   │   ├── sprout_lands.png                     ← village/grass/flower tiles
│   │   └── mystic_woods.png                     ← forest/tree tiles
│   ├── ironhold/
│   │   └── steampunk.png                        ← industrial/metal tiles
│   ├── necropolis/
│   │   └── gothicvania.png                      ← dark fantasy/cemetery tiles
│   ├── celestia/
│   │   └── floating_islands.png                 ← sky/cloud/island tiles
│   └── deepblue/
│       └── underwater.png                       ← underwater/ocean tiles
└── ui/
    ├── frame.png                                ← UI panel frame/border
    └── button.png                               ← UI button texture
```

Also in the **project root** (already partially present):

```
AethelgardPrototype/
├── P before ch 1.png          ← Player sprite BEFORE Chapter 1 (exists ✓)
├── P after ch 1.png           ← Player sprite AFTER Chapter 1 / combat (exists ✓)
├── P top down.png             ← Player top-down exploration sprite (exists ✓)
└── Character sprites.png      ← Player sprite sheet (exists ✓)
```

---

## DETAILED BREAKDOWN BY CATEGORY

---

### 1. PLAYER CHARACTER SPRITES

| Asset Key | File Path | Used By | Size | Description |
|-----------|-----------|---------|------|-------------|
| `player` | `assets/sprites/player/player.png` | `combat_arena.gd`, `oakhaven.gd` | 32×48px | Generic player sprite (combat + exploration fallback) |
| `player_before_ch1` | `P before ch 1.png` (root) | `asset_manager.gd` | Any | Player appearance before Chapter 1 starts |
| `player_after_ch1` | `P after ch 1.png` (root) | `ch1_tutorial_knight.gd`, combat scenes | Any | Player appearance after awakening (used in combat) |
| `player_top_down` | `P top down.png` (root) | `player_topdown.gd`, exploration | Any | Top-down overhead view for Oakhaven exploration |
| `player_sprite_sheet` | `Character sprites.png` (root) | `asset_manager.gd` | Any | Full sprite sheet with all player frames |

**Where these are loaded:**
- `combat_arena.gd` line ~71: Replaces the Player/Sprite ColorRect with `AssetManager.get_sprite("player")`
- `oakhaven.gd` line ~109: Replaces Player/Sprite ColorRect with `AssetManager.get_sprite("player")`
- `ch1_tutorial_knight.gd` line ~240: Loads `"player_after_ch1"` for boss fight setup
- `asset_manager.gd` `create_player_sprite()`: Selects sprite based on context (`"combat"`, `"before_ch1"`, `"after_ch1"`, `"top_down"`)

**Note:** The 3 root PNGs already exist. The `assets/sprites/player/player.png` is the generic fallback if those aren't found.

---

### 2. CUTSCENE CHARACTER SPRITES (Full Body)

These appear during story cutscenes via `CutsceneManager` and are created by `AssetManager.create_character_sprite()`.

| Asset Key | File Path | Character | Used In |
|-----------|-----------|-----------|---------|
| `char_kaelen` | `assets/sprites/characters/kaelen.png` | Kaelen (protagonist) | All cutscenes |
| `char_elara` | `assets/sprites/characters/elara.png` | Elara the Glitch-Witch | Ch1 Elara meeting, forest scenes |
| `char_mira` | `assets/sprites/characters/mira.png` | Mira (flight attendant / NPC) | Prologue airplane scenes |
| `char_tutorial_knight` | `assets/sprites/characters/tutorial_knight.png` | Tutorial Knight | Ch1 boss encounter |
| `char_elder` | `assets/sprites/characters/elder.png` | Village Elder | Ch1 Oakhaven |
| `char_farmer_jenkins` | `assets/sprites/characters/farmer_jenkins.png` | Farmer Jenkins | Ch1 Oakhaven NPC |
| `char_seraphina` | `assets/sprites/characters/seraphina.png` | Seraphina | Ch2 encounter, Ironhold |
| `char_nyx` | `assets/sprites/characters/nyx.png` | Nyx | Ch2 Ironhold |
| `char_pip` | `assets/sprites/characters/pip.png` | Pip | Ch2 Ironhold |
| `char_gate_guard` | `assets/sprites/characters/gate_guard.png` | Ironhold Gate Guard | Ch2 gate scene |

**Recommended size:** 50×80px minimum (the code uses origin at character's feet, sprite is offset upward)

**Where loaded:** `cutscene_manager.gd` line ~323 → calls `AssetManager.create_character_sprite(character_name)` → looks up `CHARACTER_MAP` → loads from `assets/sprites/characters/`

**Placeholder behavior:** Without these files, characters appear as colored rectangles with a name label above them. Colors per character are defined in `PLACEHOLDER_COLORS`.

---

### 3. DIALOGUE PORTRAIT SPRITES (Face Icons)

Shown in the dialogue box next to the speaker's name.

| Asset Key | File Path | Speakers That Use It |
|-----------|-----------|----------------------|
| `portrait_kaelen` | `assets/sprites/portraits/kaelen.png` | "Kaelen" |
| `portrait_kaelen_internal` | `assets/sprites/portraits/kaelen_internal.png` | "Kaelen (Internal)" — inner monologue |
| `portrait_elara` | `assets/sprites/portraits/elara.png` | "Elara", "Elara (Glitch-Witch)" |
| `portrait_mira` | `assets/sprites/portraits/mira.png` | "Mira", "Mira (Flight Attendant)" |
| `portrait_system` | `assets/sprites/portraits/system.png` | "System", "Data Vision" |
| `portrait_unknown` | `assets/sprites/portraits/unknown.png` | "???" |
| `portrait_tutorial_knight` | `assets/sprites/portraits/tutorial_knight.png` | "Tutorial Knight", "Knight" |
| `portrait_elder` | `assets/sprites/portraits/elder.png` | "Elder" |
| `portrait_seraphina` | `assets/sprites/portraits/seraphina.png` | "Seraphina" |
| `portrait_nyx` | `assets/sprites/portraits/nyx.png` | "Nyx" |
| `portrait_gate_guard` | `assets/sprites/portraits/gate_guard.png` | "Gate Guard" |

**Recommended size:** 72×72px (the dialogue box `custom_minimum_size` is `Vector2(72, 72)`)

**Where loaded:** `dialogue_manager.gd` line ~629 → `AssetManager.get_portrait_key(speaker)` → `AssetManager.get_sprite(portrait_key)` → applies to `TextureRect` inside the portrait container.

**Placeholder behavior:** Shows a colored rectangle with the speaker's first initial letter (e.g., "K" for Kaelen).

---

### 4. ENEMY SPRITES

Each enemy scene needs a child node named **"Sprite"** — either a `Sprite2D` or `ColorRect`. The code looks for `get_node("Sprite")` to do modulate effects, flip_h, telegraph flashes, etc.

#### Oakhaven Enemies
| Asset Key | File Path | Enemy Script | Placeholder Color |
|-----------|-----------|-------------|-------------------|
| `slime_green` | `assets/sprites/enemies/oakhaven/slime.png` | `slime.gd` | Green (0.2, 0.8, 0.2) |
| `boar_corrupted` | `assets/sprites/enemies/oakhaven/boar.png` | — | Brown (0.6, 0.3, 0.2) |
| `knight_tutorial` | `assets/sprites/bosses/oakhaven/knight.png` | `tutorial_knight_boss_enemy.gd` | Gray (0.7, 0.7, 0.7) |

#### Ironhold Enemies
| Asset Key | File Path | Enemy Script | Placeholder Color |
|-----------|-----------|-------------|-------------------|
| `arachnid_clockwork` | `assets/sprites/enemies/ironhold/spider.png` | `clockwork_soldier.gd` | Brown (0.4, 0.3, 0.2) |
| `sentinel_steam` | `assets/sprites/enemies/ironhold/turret.png` | — | Brown (0.5, 0.4, 0.3) |
| `gear_hulk` | `assets/sprites/bosses/ironhold/hulk.png` | `clockwork_automaton_boss.gd` | Tan (0.6, 0.5, 0.4) |

#### Necropolis Enemies
| Asset Key | File Path | Enemy Script | Placeholder Color |
|-----------|-----------|-------------|-------------------|
| `bone_construct` | `assets/sprites/enemies/necropolis/skeleton.png` | — | Off-White (0.9, 0.9, 0.8) |
| `wraith` | `assets/sprites/enemies/necropolis/wraith.png` | `shadow_wraith.gd` | Purple (0.3, 0.3, 0.5) |
| `lich_lord` | `assets/sprites/bosses/necropolis/lich.png` | `data_wraith_boss.gd` | Purple (0.5, 0.2, 0.5) |

#### Enemies WITHOUT AssetManager entries (use ColorRect directly in code):
These enemies build their own visuals in code. Add sprites to their "Sprite" child nodes in their `.tscn` scenes:

| Enemy | Script | Current Visual | Recommended Sprite |
|-------|--------|---------------|-------------------|
| Administrator Enforcer | `administrator_enforcer.gd` | Red ColorRect (80×100) with yellow "eyes" | 80×100px dark red armored figure |
| Corrupted Guard | `corrupted_guard.gd` | ColorRect placeholder | Guard sprite with corruption effects |
| Corrupted Rat | `corrupted_rat.gd` | ColorRect placeholder | Small rat with glitch corruption |
| Data Sprite | `data_sprite.gd` | ColorRect placeholder | Floating data/pixel creature |
| Glitch Wolf | `glitch_wolf.gd` | ColorRect placeholder | Wolf with digital distortion |
| Administrator Proxy Boss | `administrator_proxy_boss.gd` | ColorRect placeholder | Hovering admin hologram |

**How enemy sprites work:**
- `enemy_base.gd` looks for a child node named `"Sprite"` (line ~254)
- If it's a `Sprite2D`, it uses `flip_h` based on movement direction
- If it's a `ColorRect`, direction flipping doesn't apply (visual stays same)
- Attack telegraph: flashes `modulate` to orange (line ~298)
- Hit flash: briefly colors red
- Hacked tint: modulates to green `Color(0.3, 1.0, 0.3)` when hacked

---

### 5. BACKGROUND SPRITES

All backgrounds are **1280×720px** (or 1920×1080) and fill the entire screen.

#### Prologue Backgrounds
| Key (BackgroundManager) | File Path | Description |
|-------------------------|-----------|-------------|
| `plane_interior` | `assets/backgrounds/prologue/bg_plane_interior_base.png` | Normal airplane cabin interior |
| `plane_glitch1` | `assets/backgrounds/prologue/bg_plane_interior_glitch1.png` | Same cabin, slight glitch distortion |
| `plane_glitch2` | `assets/backgrounds/prologue/bg_plane_interior_glitch2.png` | More distortion, colors shifting |
| `plane_glitch3` | `assets/backgrounds/prologue/bg_plane_interior_glitch3.png` | Heavy corruption, geometry breaking |
| `plane_glitch4` | `assets/backgrounds/prologue/bg_plane_interior_glitch4.png` | Nearly dissolved, pixel chaos |
| `night_sky` | `assets/backgrounds/prologue/bg_plane_window_sky.png` | Dark night sky seen through plane window |
| `bsod` | `assets/backgrounds/prologue/bg_bsod.png` | Blue Screen of Death |
| `boot_screen` | `assets/backgrounds/prologue/bg_boot_screen.png` | Dark terminal/boot loading screen |
| `crash_sequence` | `assets/backgrounds/prologue/bg_crash_sequence.png` | Transition crash visual |

**Used by:** `flight_707_cinematic.gd` line ~29 → `BackgroundManager.create_background("plane_interior", self)`

#### Chapter 1 Backgrounds
| Key | File Path | Description |
|-----|-----------|-------------|
| `glitch_crater_sky` | `assets/backgrounds/chapter1/bg_crater_sky.png` | Purple/void sky above crash crater |
| `glitch_crater_ground` | `assets/backgrounds/chapter1/bg_crater_ground.png` | Crater ground (BackgroundManager only) |
| `forest_twilight` | `assets/backgrounds/chapter1/bg_forest_twilight.png` | Dark enchanted forest path |
| `oakhaven_sky` | `assets/backgrounds/chapter1/bg_oakhaven_sky.png` | Blue sky (parallax layer 1 — farthest) |
| `oakhaven_buildings_far` | `assets/backgrounds/chapter1/bg_oakhaven_buildings_far.png` | Distant village buildings (parallax layer 2) |
| `oakhaven_buildings_near` | `assets/backgrounds/chapter1/bg_oakhaven_buildings_near.png` | Close buildings (parallax layer 3) |
| `oakhaven_ground` | `assets/backgrounds/chapter1/bg_oakhaven_ground.png` | Ground/grass (parallax layer 4 — nearest) |
| `tutorial_arena` | `assets/backgrounds/chapter1/bg_arena_tutorial.png` | Tutorial combat arena floor |
| `shatter_bridge` | `assets/backgrounds/chapter1/bg_shatter_bridge.png` | Bridge breaking at chapter end |

**Parallax note:** Oakhaven uses 4 layers for depth scrolling. Create separate transparent PNGs for each layer.

**Used by:** `ch1_shatter_transition.gd` line ~28 → `BackgroundManager.create_background("shatter_bridge", self)`

#### Chapter 2 Backgrounds
| Key | File Path | Description |
|-----|-----------|-------------|
| `ironhold_sky` | `assets/backgrounds/chapter2/bg_ironhold_sky.png` | Copper/orange industrial sky |
| `ironhold_industrial` | `assets/backgrounds/chapter2/bg_ironhold_industrial.png` | Factory cityscape |
| `ironhold_market` | `assets/backgrounds/chapter2/bg_ironhold_market.png` | Market district with stalls |
| `ironhold_arena` | `assets/backgrounds/chapter2/bg_ironhold_arena.png` | Ironhold combat arena |
| `ironhold_clock_tower` | `assets/backgrounds/chapter2/bg_ironhold_clock_tower.png` | Giant clock tower |
| `underground` | `assets/backgrounds/chapter2/bg_underground.png` | Dark underground tunnels |
| `admin_boss_arena` | `assets/backgrounds/chapter2/bg_admin_boss_arena.png` | Administrator boss fight arena (dark red void) |

**Used by:** `ch2_seraphina_encounter.gd` → `"ironhold_arena"`, `ch2_ironhold_gate.gd` → `"ironhold_city"`

#### Overlays & Weather
| Key | File Path | Description |
|-----|-----------|-------------|
| `scanlines` | `assets/backgrounds/overlays/bg_overlay_scanlines.png` | Horizontal CRT scanlines (tile vertically, semi-transparent) |
| `static_noise` | `assets/backgrounds/overlays/bg_overlay_static.png` | Random noise static overlay |
| `rain` | `assets/backgrounds/weather/bg_weather_rain.png` | Rain particle/streak overlay |
| `fog` | `assets/backgrounds/weather/bg_weather_fog.png` | Fog mist overlay |

#### Future Kingdoms (defined but not yet scenes)
| Key | File Path | Description |
|-----|-----------|-------------|
| `bg_celestia_sky` | `assets/backgrounds/celestia/clouds.png` | Floating islands kingdom sky |
| `bg_deepblue` | `assets/backgrounds/deepblue/ocean.png` | Underwater kingdom backdrop |

---

### 6. TILESET SPRITES (Top-Down Exploration Maps)

Used by `AssetManager.get_tileset()` for building TileMap-based exploration levels.

| Asset Key | File Path | Kingdom | Contents |
|-----------|-----------|---------|----------|
| `tileset_oakhaven` | `assets/tilesets/oakhaven/sprout_lands.png` | Oakhaven | Village, grass, flowers, houses |
| `tileset_oakhaven_forest` | `assets/tilesets/oakhaven/mystic_woods.png` | Oakhaven | Forest, trees, rocks, paths |
| `tileset_ironhold` | `assets/tilesets/ironhold/steampunk.png` | Ironhold | Metal, pipes, gears, factory |
| `tileset_necropolis` | `assets/tilesets/necropolis/gothicvania.png` | Necropolis | Cemetery, dark stone, bones |
| `tileset_celestia` | `assets/tilesets/celestia/floating_islands.png` | Celestia | Cloud, sky stone, crystal |
| `tileset_deepblue` | `assets/tilesets/deepblue/underwater.png` | Deep Blue | Coral, sand, underwater ruins |

---

### 7. EFFECT / VFX SPRITES

The VFX system (`vfx_library.gd`) uses **CPUParticles2D** (code-generated particles — no sprite files needed) and **ColorRect** shapes for:

| Effect | Current Visual | How to Upgrade |
|--------|---------------|----------------|
| Hit Sparks | 8×8 yellow ColorRect | Replace `object_pool.gd` `_create_hit_spark()` ColorRect with a Sprite2D + spark texture |
| Enemy Projectiles | 12×12 red ColorRect | Replace `object_pool.gd` `_create_enemy_projectile()` visual |
| Dash Afterimage | 24×36 blue ColorRect | Replace `object_pool.gd` `_create_afterimage()` with player silhouette |
| Damage Numbers | Label node (text only) | Already text-based, no sprite needed |
| Slash Arc | ColorRect (curved) | `vfx_library.gd` line ~227: Replace with slash sprite |
| Beam Effect | ColorRect (thin rectangle) | `vfx_library.gd` line ~245: Replace with beam texture |
| Screen Flash | Full-screen ColorRect | `scene_transition_manager.gd`: Keep as-is (solid color) |
| Glitch Overlay | Full-screen shader | `glitch_overlay.gd`: Uses a shader (no sprite) |

**If you want to use sprite-based VFX**, create these optional files:
```
assets/effects/
├── hit_spark.png          ← 16×16 white/yellow burst (4-frame sheet)
├── slash_arc.png          ← 64×32 curved slash trail
├── projectile.png         ← 12×12 energy ball
├── afterimage.png         ← Same size as player sprite, single color silhouette
├── heal_particle.png      ← 8×8 green sparkle
└── corruption_particle.png ← 8×8 purple/void shard
```
Then modify `object_pool.gd` factory functions to load these instead of creating ColorRects.

---

### 8. UI SPRITES

| Asset Key | File Path | Usage |
|-----------|-----------|-------|
| `ui_frame` | `assets/ui/frame.png` | UI panel border/frame |
| `ui_button` | `assets/ui/button.png` | Button texture |

Additional UI elements that use ColorRects (upgradeable):
- **XP Bar:** `level_up_ui.gd` — dark gray bg + gold fill bar
- **Health Bar:** Built into enemy scenes as ProgressBar nodes
- **Shop overlay:** `shop_system.gd` — dark semi-transparent background
- **Gambling UI:** `gambling_system.gd` — overlay panels

---

## QUICK REFERENCE: Priority Order

### Must-Have (Game Looks Playable)
1. `P after ch 1.png` — ✅ Already exists
2. `P top down.png` — ✅ Already exists  
3. `assets/sprites/enemies/oakhaven/slime.png` — Tutorial slime
4. `assets/sprites/bosses/oakhaven/knight.png` — Tutorial boss
5. `assets/backgrounds/prologue/bg_plane_interior_base.png` — First thing player sees
6. `assets/backgrounds/chapter1/bg_crater_sky.png` — First game world scene
7. `assets/sprites/portraits/kaelen.png` — Most common dialogue portrait

### Nice-to-Have (Polished Feel)
8. All 11 portraits (shows character faces in dialogue)
9. All 10 character sprites (real characters in cutscenes)
10. All 9 prologue + chapter 1 backgrounds
11. Remaining enemy sprites

### Future Content
12. Chapter 2 backgrounds (7 files)
13. Ironhold + Necropolis enemies
14. Tilesets
15. Celestia / Deep Blue kingdom assets
16. VFX sprite replacements
17. UI frame/button textures

---

## HOW TO VERIFY YOUR ASSETS

Run the game and check the console output. AssetManager prints a report at startup:

```
AssetManager initialized - Scanning for assets...
✓ Asset loaded: player_before_ch1
✓ Asset loaded: player_after_ch1
✓ Asset loaded: player_top_down
○ Asset not found (using placeholder): char_kaelen
○ Asset not found (using placeholder): slime_green
...
```

- `✓` = Real sprite loaded successfully
- `○` = Using colored rectangle placeholder
- `✗` = File exists but failed to load (check format)

---

## IMAGE FORMAT NOTES

- **Format:** PNG (with transparency where needed)
- **Import:** Godot auto-imports PNGs. For pixel art, set import preset to:
  - Filter: `Nearest` (not Linear) — keeps pixels sharp
  - Repeat: Disabled
- **Backgrounds:** 1280×720 or 1920×1080, opaque
- **Characters:** Any size, transparent background, origin at feet
- **Portraits:** 72×72px recommended, transparent or solid background
- **Enemies:** 32×32 to 128×128 depending on enemy size, transparent background
- **Tilesets:** Standard tile grid (16×16 or 32×32 cells)
