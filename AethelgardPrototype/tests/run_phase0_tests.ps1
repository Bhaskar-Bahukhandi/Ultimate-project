# Runs a headless test/probe script with an isolated user:// directory, so real
# save files are never read or overwritten.
# A suite fails on a non-zero exit OR on any SCRIPT ERROR / Parse Error line in its
# output (TD-003): a runtime script error aborts the rest of a test function while
# Godot still exits with the code the script chose. The runner then prints
# "RUNNER FAIL <script>: <N> script error line(s)" with the matching lines, and
# exits 1 (or keeps Godot's own non-zero code).
# Usage (from AethelgardPrototype/):
#   powershell -File tests/run_phase0_tests.ps1
#   powershell -File tests/run_phase0_tests.ps1 -Script res://docs/visual_review/phase10mm/phase10mm_validation.gd
param(
    [string]$Script = "res://tests/integration/playthrough/phase0_blockers_test.gd"
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
    $ErrorActionPreference = "Continue"   # Godot writes to stderr; under 2>&1 Stop would throw on it
    # Stream every line as it arrives and keep a copy for the script-error scan below.
    $lines = & $godot.FullName --headless --path $project --script $Script 2>&1 |
        ForEach-Object { $l = "$_"; Write-Host $l; $l }
    $code = $LASTEXITCODE
} finally {
    $env:APPDATA = $oldAppData
    Remove-Item -Recurse -Force $isolated -ErrorAction SilentlyContinue
}

$hits = @()
if ($lines) {
    $hits = @($lines | Select-String -CaseSensitive -Pattern 'SCRIPT ERROR|Parse Error' -Context 0,1)
}
if ($hits.Count -gt 0) {
    Write-Host ""
    Write-Host "RUNNER FAIL $($Script): $($hits.Count) script error line(s)"
    foreach ($h in $hits) {
        Write-Host "  $($h.Line)"
        # A following line that is itself a match is listed as its own hit, not twice (as grep -A1).
        foreach ($p in $h.Context.PostContext) { if ($p -cnotmatch 'SCRIPT ERROR|Parse Error') { Write-Host "  $p" } }
    }
    if ($code -eq 0) { $code = 1 }
}
exit $code
