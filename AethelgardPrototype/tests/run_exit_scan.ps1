# Boots the project with a REAL renderer, quits after 300 frames at the main menu, saves
# the full log and fails if the exit output shows renderer leaks (Y1-P0-T10).
#
# LOCAL ONLY. CI runs headless (dummy renderer) and cannot see renderer leaks; this scan
# needs a display and a GPU/driver, and a game window opens for a few seconds. It is not
# registered in run_all_tests.ps1 or ci.yml. Do NOT add --headless to it.
#
# Fails (exit 1) when ANY of these hold, and names each one that failed:
#   GodotExitCode   Godot's exit code is non-zero
#   EmptyLog        the log has no lines (stderr is merged in with 2>&1)
#   NoMainMenuLoad  no "Loading resource: res://scenes/main_menu.tscn" line (--verbose), so a
#                   crashed or stalled boot cannot pass
#   LeakRidAlloc    log contains "RID allocations of type"
#   LeakTexture     log contains 'RIDs of type "Texture" were leaked'
#   LeakRsNull      log contains 'RenderingServer::get_singleton()" is null'
# user:// is isolated to a temp APPDATA (aeth_phase0_test_*), deleted afterwards.
#
# Usage (from anywhere):
#   powershell -File AethelgardPrototype/tests/run_exit_scan.ps1
#   powershell -File AethelgardPrototype/tests/run_exit_scan.ps1 -Out C:\temp\before.log -Project C:\scratch\wt\AethelgardPrototype
param(
    # Godot project folder (the one holding project.godot). Default: the one next to this script.
    # Point it at a scratch worktree to scan an older commit (positive control).
    [string]$Project = (Split-Path -Parent $PSScriptRoot),
    # Where the full log goes. Default: <repo root>/production/qa/evidence/2026-10-exit-leak/exit.log
    [string]$Out = ""
)
$ErrorActionPreference = "Stop"
if (-not $Out) {
    $repoRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
    $Out = Join-Path $repoRoot "production\qa\evidence\2026-10-exit-leak\exit.log"
}
if (-not (Test-Path (Join-Path $Project "project.godot"))) { throw "No project.godot under $Project" }
$godot = Get-ChildItem "C:\Godot" -Filter "Godot_v4*_console.exe" | Sort-Object Name -Descending | Select-Object -First 1
if (-not $godot) { throw "Godot console executable not found under C:\Godot" }
$outDir = Split-Path -Parent ([IO.Path]::GetFullPath($Out))
New-Item -ItemType Directory -Force $outDir | Out-Null

$isolated = Join-Path ([IO.Path]::GetTempPath()) ("aeth_phase0_test_" + [guid]::NewGuid().ToString("N"))
New-Item -ItemType Directory -Force $isolated | Out-Null
$oldAppData = $env:APPDATA
$sw = [Diagnostics.Stopwatch]::StartNew()
# Set before the try so a launch failure cannot leave a caller's same-named variables in play.
$code = $null
$lines = @()
$godotArgs = @("--verbose", "--fixed-fps", "60", "--quit-after", "300", "--path", $Project)
try {
    $env:APPDATA = $isolated   # Godot resolves user:// under %APPDATA% on Windows
    $ErrorActionPreference = "Continue"   # Godot writes to stderr; under 2>&1 Stop would throw on it
    $lines = @(& $godot.FullName @godotArgs 2>&1 | ForEach-Object { "$_" })
    $code = $LASTEXITCODE
} finally {
    $env:APPDATA = $oldAppData
    Remove-Item -Recurse -Force $isolated -ErrorAction SilentlyContinue
}
$ErrorActionPreference = "Stop"

# Which renderer ran (e.g. "Vulkan 1.4.329 - Forward+ - Using Device #0: ..."): leak lines are only
# comparable between runs on the same driver.
$driver = @($lines | Where-Object { $_ -match 'Using Device #' } | Select-Object -First 1)
$driverText = if ($driver.Count -gt 0) { $driver[0].Trim() } else { "driver line not found" }
$header = "----- exit scan | $($godot.Name) | args: $($godotArgs -join ' ') | exit=$code | $([int]$sw.Elapsed.TotalSeconds) s | lines=$($lines.Count) | driver: $driverText | $(Get-Date -Format s)"
$header | Out-File -FilePath $Out -Encoding utf8
if ($lines.Count -gt 0) { $lines | Out-File -FilePath $Out -Encoding utf8 -Append }

function Test-LogHas([string[]]$Lines, [string]$Text) {
    return (@($Lines | Where-Object { $_.Contains($Text) }).Count -gt 0)
}

$failures = @()
if ($null -eq $code -or $code -ne 0) { $failures += "GodotExitCode (exit=$code)" }
if ($lines.Count -eq 0) { $failures += "EmptyLog" }
if (@($lines | Where-Object { $_ -match 'Loading resource: res://scenes/main_menu\.tscn' }).Count -eq 0) {
    $failures += "NoMainMenuLoad"
}
if (Test-LogHas $lines 'RID allocations of type') { $failures += "LeakRidAlloc" }
if (Test-LogHas $lines 'RIDs of type "Texture" were leaked') { $failures += "LeakTexture" }
if (Test-LogHas $lines 'RenderingServer::get_singleton()" is null') { $failures += "LeakRsNull" }

Write-Host "Exit scan: $($godot.Name), exit=$code, $($lines.Count) log line(s), driver: $driverText"
Write-Host "Log: $Out"
if ($failures.Count -gt 0) {
    Write-Host "EXIT SCAN FAIL: $($failures -join ', ')"
    foreach ($l in @($lines | Where-Object { $_.Contains('RID allocations of type') -or $_.Contains('were leaked') -or $_.Contains('RenderingServer::get_singleton()" is null') })) {
        Write-Host "  $l"
    }
    exit 1
}
Write-Host "EXIT SCAN OK: clean exit, main menu loaded, no renderer leak lines"
exit 0
