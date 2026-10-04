# Runs a headless test/probe script with an isolated user:// directory, so real
# save files are never read or overwritten.
# Usage (from AethelgardPrototype/):
#   powershell -File tests/run_phase0_tests.ps1
#   powershell -File tests/run_phase0_tests.ps1 -Script res://docs/visual_review/phase10mm/phase10mm_validation.gd
param(
    [string]$Script = "res://tests/phase0_blockers_test.gd"
)
$ErrorActionPreference = "Stop"
$project = Split-Path -Parent $PSScriptRoot
$godot = Get-ChildItem "C:\Godot" -Filter "Godot_v4*_console.exe" | Sort-Object Name -Descending | Select-Object -First 1
if (-not $godot) { throw "Godot console executable not found under C:\Godot" }

# Scripts check for this marker in OS.get_user_data_dir() and refuse to run without it.
$isolated = Join-Path ([IO.Path]::GetTempPath()) ("aeth_phase0_test_" + [guid]::NewGuid().ToString("N"))
New-Item -ItemType Directory -Force $isolated | Out-Null
$oldAppData = $env:APPDATA
try {
    $env:APPDATA = $isolated   # Godot resolves user:// under %APPDATA% on Windows
    & $godot.FullName --headless --path $project --script $Script
    $code = $LASTEXITCODE
} finally {
    $env:APPDATA = $oldAppData
    Remove-Item -Recurse -Force $isolated -ErrorAction SilentlyContinue
}
exit $code
