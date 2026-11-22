# The ONE place the local scripts name the Godot version this project is pinned to.
# Keep it equal to GODOT_VERSION in .github/workflows/ci.yml and to the pin in
# docs/engine-reference/godot/VERSION.md. C:\Godot may hold other versions (4.7.2 was
# installed beside 4.6.3 on 2026-10-30); taking "the newest" there silently ran the tests and
# the export on the wrong engine, and only 4.6.3 export templates are installed.
#
# Use (dot-source, then call):
#   . (Join-Path $PSScriptRoot "..\tools\pinned_godot.ps1")   # from tests\
#   . (Join-Path $PSScriptRoot "pinned_godot.ps1")            # from tools\
#   $godot = Get-PinnedGodot                                   # a FileInfo for the console exe
# A missing pinned exe throws, naming what C:\Godot does hold, instead of falling back.

$PinnedGodotVersion = "4.6.3"

function Get-PinnedGodot {
    $dir = "C:\Godot"
    $path = Join-Path $dir "Godot_v$($PinnedGodotVersion)-stable_win64_console.exe"
    if (-not (Test-Path -LiteralPath $path)) {
        $found = @(Get-ChildItem $dir -Filter "Godot_v*_console.exe" -ErrorAction SilentlyContinue |
            ForEach-Object { $_.Name }) -join ", "
        if (-not $found) { $found = "none" }
        throw "Pinned Godot $PinnedGodotVersion not found at $path (C:\Godot holds: $found). Install $PinnedGodotVersion, or change the pin here together with ci.yml and VERSION.md."
    }
    return Get-Item -LiteralPath $path
}
