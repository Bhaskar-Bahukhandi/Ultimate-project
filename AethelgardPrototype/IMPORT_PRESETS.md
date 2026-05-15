# Godot 4.3+ Import Presets for Pixel Art

## General Settings
.import
*.png filter=false
*.png mipmaps_generate=false
*.png compress/mode=0

## Sprite Import Preset
# Copy this to import settings for character/enemy sprites
filter: Nearest
mipmaps: Disabled
compress: Lossless
fix_alpha_border: true
process/size_limit: 0
detect_3d/compress_to: 0

## Tileset Import Preset  
# Use for tilemap sheets
filter: Nearest
mipmaps: Disabled
compress: Lossless
repeat: Disabled
fix_alpha_border: true

## Background Import Preset
# For parallax backgrounds
filter: Nearest (or Linear for smoother parallax)
mipmaps: Disabled
compress: VRAM Uncompressed
repeat: Enabled (if tiling)

## UI Import Preset
# For HUD elements
filter: Nearest
mipmaps: Disabled
compress: Lossless
fix_alpha_border: true
