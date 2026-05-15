# Asset Sources — Aethelgard Prototype

## Sprites
- **Kenney.nl** (CC0 / Public Domain): https://kenney.nl/assets
  - Recommended packs: "1-Bit Pack", "Pixel Platformer", "Tiny Dungeon"
  - Download, extract to `assets/sprites/` subfolders

## Sound Effects
- **Freesound.org** (CC0): https://freesound.org/
  - Search for: sword_hit, footstep, ui_click, heal, damage
  - Download as .wav or .ogg, place in `assets/audio/sfx/`

## Music
- **OpenGameArt.org** (CC0/CC-BY): https://opengameart.org/
  - Search for: pixel RPG, chiptune, ambient
  - Place .ogg files in `assets/audio/music/`

## Folder Structure
```
assets/
├── sprites/
│   ├── player/       ← Player walk/idle/attack spritesheets
│   ├── enemies/      ← Enemy sprites per area
│   ├── npcs/         ← NPC sprites
│   ├── tiles/        ← Tileset images
│   ├── ui/           ← UI elements (buttons, frames, icons)
│   └── effects/      ← VFX sprites (particles, slashes)
├── audio/
│   ├── sfx/          ← Sound effects (.wav/.ogg)
│   └── music/        ← Background music (.ogg)
└── fonts/            ← Custom pixel fonts (.ttf)
```

## Priority (Day 2-4)
1. Player idle + walk sprites (4 frames each)
2. 1 enemy sprite (Glitch Imp — 2 frames idle)
3. 5 SFX: sword_hit, footstep, ui_click, heal, damage_taken
4. 1 music track for main menu
