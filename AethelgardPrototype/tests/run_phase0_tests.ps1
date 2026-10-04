# Runs the Phase 0 regression tests headless with an isolated user:// directory,
# so real save files are never read or overwritten.
# Usage:  powershell -File tests/run_phase0_tests.ps1   (from AethelgardPrototype/)
$ErrorActionPreference = "Stop"
$project = Split-Path -Parent $PSScriptRoot
$godot = Get-ChildItem "C:\Godot" -Filter "Godot_v4*_console.exe" | Sort-Object Name -Descending | Select-Object -First 1
if (-not $godot) { throw "Godot console executable not found under C:\Godot" }

$isolated = Join-Path ([IO.Path]::GetTempPath()) ("aeth_phase0_test_" + [guid]::NewGuid().ToString("N"))
New-Item -ItemType Directory -Force $isolated | Out-Null
$oldAppData = $env:APPDATA
try {
    $env:APPDATA = $isolated   # Godot resolves user:// under %APPDATA% on Windows
    & $godot.FullName --headless --path $project --script res://tests/phase0_blockers_test.gd
    $code = $LASTEXITCODE
} finally {
    $env:APPDATA = $oldAppData
    Remove-Item -Recurse -Force $isolated -ErrorAction SilentlyContinue
}
exit $code
