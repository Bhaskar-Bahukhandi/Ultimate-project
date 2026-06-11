Add-Type -AssemblyName System.Drawing

$root = Resolve-Path (Join-Path $PSScriptRoot '..\..\..')
$font = New-Object System.Drawing.Font('Arial', 14, [System.Drawing.FontStyle]::Bold)
$smallFont = New-Object System.Drawing.Font('Arial', 10, [System.Drawing.FontStyle]::Regular)

function New-Canvas([int]$width, [int]$height) {
    $bitmap = New-Object System.Drawing.Bitmap($width, $height, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
    $graphics = [System.Drawing.Graphics]::FromImage($bitmap)
    $graphics.Clear([System.Drawing.Color]::Transparent)
    return @{ Bitmap = $bitmap; Graphics = $graphics }
}

function Draw-Grid($graphics, [int]$width, [int]$height, [int]$cellSize) {
    $gridPen = New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(130, 90, 196, 255), 1)
    for ($x = 0; $x -le $width; $x += $cellSize) {
        $graphics.DrawLine($gridPen, $x, 0, $x, $height)
    }
    for ($y = 0; $y -le $height; $y += $cellSize) {
        $graphics.DrawLine($gridPen, 0, $y, $width, $y)
    }
    $gridPen.Dispose()
}

function Save-Guide($canvas, [string]$path) {
    $dir = Split-Path -Parent $path
    if (-not (Test-Path -LiteralPath $dir)) {
        New-Item -ItemType Directory -Path $dir | Out-Null
    }
    $canvas.Bitmap.Save($path, [System.Drawing.Imaging.ImageFormat]::Png)
    $canvas.Graphics.Dispose()
    $canvas.Bitmap.Dispose()
    Write-Output $path
}

function New-TilesetGuide([string]$regionId, [string]$title, [string]$outputPath) {
    $canvas = New-Canvas 512 512
    Draw-Grid $canvas.Graphics 512 512 32
    $backing = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(180, 12, 18, 25))
    $textBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(245, 240, 248, 255))
    $canvas.Graphics.FillRectangle($backing, 0, 0, 512, 56)
    $canvas.Graphics.DrawString($title, $font, $textBrush, 12, 9)
    $canvas.Graphics.DrawString('512x512 PNG | 32 px top-down visual tile grid | source guide only', $smallFont, $textBrush, 12, 31)
    $canvas.Graphics.DrawString('Floor family', $smallFont, $textBrush, 18, 82)
    $canvas.Graphics.DrawString('Path/edge family', $smallFont, $textBrush, 178, 82)
    $canvas.Graphics.DrawString('Architecture support', $smallFont, $textBrush, 338, 82)
    $canvas.Graphics.DrawString($regionId + ' production export: assets/production_art/tilesets/' + $regionId + '_tileset.png', $smallFont, $textBrush, 18, 474)
    $backing.Dispose()
    $textBrush.Dispose()
    Save-Guide $canvas $outputPath
}

function New-AtlasGuide([string]$title, [string]$outputPath, [array]$regions) {
    $canvas = New-Canvas 1536 1024
    Draw-Grid $canvas.Graphics 1536 1024 32
    $titleBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(230, 14, 18, 28))
    $textBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(245, 242, 250, 255))
    $boxPen = New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(230, 255, 205, 74), 3)
    $canvas.Graphics.FillRectangle($titleBrush, 0, 0, 1536, 54)
    $canvas.Graphics.DrawString($title, $font, $textBrush, 14, 8)
    $canvas.Graphics.DrawString('Keep these crop rectangles until AssetManager atlas regions are revised.', $smallFont, $textBrush, 14, 31)
    foreach ($region in $regions) {
        $canvas.Graphics.DrawRectangle($boxPen, $region.X, $region.Y, $region.W, $region.H)
        $canvas.Graphics.FillRectangle($titleBrush, $region.X + 2, $region.Y + 2, [Math]::Min($region.W - 4, 190), 18)
        $canvas.Graphics.DrawString($region.Name, $smallFont, $textBrush, $region.X + 5, $region.Y + 3)
    }
    $titleBrush.Dispose()
    $textBrush.Dispose()
    $boxPen.Dispose()
    Save-Guide $canvas $outputPath
}

function New-ArenaGuide([string]$outputPath) {
    $canvas = New-Canvas 1280 720
    $backing = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(170, 12, 12, 20))
    $fightBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(48, 80, 220, 140))
    $textBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(245, 242, 250, 255))
    $safePen = New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(235, 92, 235, 154), 3)
    $canvas.Graphics.FillRectangle($backing, 0, 0, 1280, 720)
    Draw-Grid $canvas.Graphics 1280 720 32
    $canvas.Graphics.FillRectangle($fightBrush, 160, 184, 960, 392)
    $canvas.Graphics.DrawRectangle($safePen, 160, 184, 960, 392)
    $canvas.Graphics.DrawString('Tutorial Knight arena floor/backdrop guide', $font, $textBrush, 18, 16)
    $canvas.Graphics.DrawString('Keep central combat readability and warning lanes clear.', $smallFont, $textBrush, 18, 40)
    $canvas.Graphics.DrawString('Authored edge/backdrop support zone', $smallFont, $textBrush, 18, 94)
    $canvas.Graphics.DrawString('Readable fight plane', $font, $textBrush, 536, 360)
    $backing.Dispose()
    $fightBrush.Dispose()
    $textBrush.Dispose()
    $safePen.Dispose()
    Save-Guide $canvas $outputPath
}

$propRegions = @(
    @{Name='oakhaven_roof'; X=32; Y=22; W=248; H=190},
    @{Name='oakhaven_hedge_corner'; X=760; Y=52; W=390; H=176},
    @{Name='oakhaven_flowers'; X=30; Y=264; W=418; H=82},
    @{Name='oakhaven_herb_sign'; X=478; Y=238; W=128; H=126},
    @{Name='ironhold_pipes'; X=616; Y=238; W=544; H=170},
    @{Name='ironhold_forge'; X=1320; Y=226; W=164; H=194},
    @{Name='crates'; X=40; Y=434; W=540; H=144},
    @{Name='archive_shelves'; X=620; Y=370; W=356; H=218},
    @{Name='dossier_stack'; X=988; Y=440; W=94; H=128},
    @{Name='null_seal'; X=1092; Y=432; W=156; H=176},
    @{Name='mirror_plinth'; X=1280; Y=430; W=202; H=192},
    @{Name='server_console'; X=36; Y=612; W=376; H=194},
    @{Name='firewall_panel'; X=430; Y=612; W=358; H=194},
    @{Name='tide_buoy'; X=824; Y=610; W=120; H=182},
    @{Name='salvage_shelf'; X=974; Y=610; W=290; H=198},
    @{Name='ocean_cache'; X=1268; Y=610; W=236; H=198},
    @{Name='lab_console'; X=34; Y=818; W=248; H=178},
    @{Name='memory_tank'; X=292; Y=814; W=170; H=186},
    @{Name='root_circuit_rail'; X=628; Y=816; W=844; H=190}
)

$decalRegions = @(
    @{Name='oakhaven_path'; X=18; Y=10; W=630; H=198},
    @{Name='oakhaven_stones'; X=22; Y=228; W=650; H=128},
    @{Name='ironhold_road'; X=676; Y=16; W=820; H=224},
    @{Name='fracture_field'; X=18; Y=360; W=500; H=294},
    @{Name='shard_spill'; X=270; Y=350; W=246; H=298},
    @{Name='archive_seals'; X=520; Y=362; W=382; H=292},
    @{Name='mirror_ripples'; X=900; Y=246; W=602; H=280},
    @{Name='cathedral_circuit'; X=900; Y=510; W=600; H=240},
    @{Name='memory_tide'; X=14; Y=674; W=476; H=326},
    @{Name='root_veins'; X=492; Y=680; W=406; H=320},
    @{Name='arena_border'; X=898; Y=754; W=620; H=252}
)

New-TilesetGuide 'oakhaven' 'Oakhaven Production Tileset Guide' (Join-Path $root 'assets\art_sources\tilesets\oakhaven\oakhaven_tileset_512x512_32px_grid_template.png')
New-TilesetGuide 'ironhold' 'Ironhold Production Tileset Guide' (Join-Path $root 'assets\art_sources\tilesets\ironhold\ironhold_tileset_512x512_32px_grid_template.png')
New-TilesetGuide 'fractured_wastes' 'Fractured Wastes Production Tileset Guide' (Join-Path $root 'assets\art_sources\tilesets\fractured_wastes\fractured_wastes_tileset_512x512_32px_grid_template.png')
New-AtlasGuide 'Shared Environment Prop Atlas Contract' (Join-Path $root 'assets\art_sources\props\environment_prop_atlas\environment_prop_atlas_contract_template.png') $propRegions
New-AtlasGuide 'Shared Environment Decal Atlas Contract' (Join-Path $root 'assets\art_sources\backgrounds\environment_decal_atlas\environment_decal_atlas_contract_template.png') $decalRegions
New-ArenaGuide (Join-Path $root 'assets\art_sources\backgrounds\tutorial_knight_arena\tutorial_knight_arena_1280x720_floor_template.png')

$font.Dispose()
$smallFont.Dispose()

