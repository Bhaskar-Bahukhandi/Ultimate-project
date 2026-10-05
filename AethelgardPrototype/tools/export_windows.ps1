# Builds the Windows game and tests the BUILT copy, not the editor copy.
#
# Default: release build (preset "Windows Desktop" -> exports/windows/Aethelgard.exe)
#   1. checks the export templates for this exact Godot version are installed;
#   2. exports; the export log must have no errors, and must show that the debug
#      test mode's tour runner (scripts/debug/) was NOT packed;
#   3. boots the exe with a real renderer and an isolated user:// for 12 s of game
#      time, recording frames with Movie Maker (--write-movie). It is started WITH
#      the "--debug-tour" flag, to prove a release build ignores it: it must reach
#      the main menu, exit cleanly, and never start the tour.
#   Output beside the exe: export.log, smoke.log, smoke_boot.png (four frames).
#
# -Tour: debug build of preset "Windows Debug Test" (exports/windows_debug_test/),
#   started with "-- --debug-tour": the screenshot tour runs INSIDE the built game
#   (scripts/core/debug_test_mode.gd), so every Act 1 scene and every .dlg file is
#   loaded from the packed build. A game window opens for about two minutes.
#   Output: run_artifacts/screenshots/build-<timestamp>/ (report.md, contact sheets).
#   -Only main_menu,ch2_ passes a subset to the tour.
#
# -NoSmoke: build only. Exit code: 0 = all checks passed, 1 = a check failed.
# Usage (from AethelgardPrototype/):
#   powershell -File tools/export_windows.ps1
#   powershell -File tools/export_windows.ps1 -Tour
param(
    [switch]$Tour,
    [string[]]$Only = @(),
    [switch]$NoSmoke
)
$ErrorActionPreference = "Stop"
$project = Split-Path -Parent $PSScriptRoot
$godot = Get-ChildItem "C:\Godot" -Filter "Godot_v4*_console.exe" | Sort-Object Name -Descending | Select-Object -First 1
if (-not $godot) { throw "Godot console executable not found under C:\Godot" }
$failures = New-Object System.Collections.Generic.List[string]

# "4.6.3.stable.official.7d41c59c4" -> templates live in export_templates\4.6.3.stable
$version = ((& $godot.FullName --version) | Select-Object -Last 1).Trim()
$tplVersion = ($version -split '\.')[0..3] -join '.'
$tplDir = Join-Path $env:APPDATA "Godot\export_templates\$tplVersion"
$tplFile = if ($Tour) { "windows_debug_x86_64.exe" } else { "windows_release_x86_64.exe" }
if (-not (Test-Path (Join-Path $tplDir $tplFile))) {
    throw "Export template $tplFile for Godot $tplVersion is not installed in $tplDir. Install it from Editor > Manage Export Templates."
}

if ($Tour) {
    $preset = "Windows Debug Test"; $mode = "--export-debug"; $outDir = Join-Path $project "exports\windows_debug_test"
} else {
    $preset = "Windows Desktop"; $mode = "--export-release"; $outDir = Join-Path $project "exports\windows"
}
New-Item -ItemType Directory -Force $outDir | Out-Null
$exe = Join-Path $outDir "Aethelgard.exe"
if (Test-Path $exe) { Remove-Item -LiteralPath $exe -Force }
$exportLog = Join-Path $outDir "export.log"
Write-Host "Exporting '$preset' ($mode) with Godot $version ..."
$ErrorActionPreference = "Continue"   # Godot writes warnings to stderr
& $godot.FullName --headless --path $project $mode $preset $exe 2>&1 |
    ForEach-Object { "$_" } | Set-Content -Path $exportLog
$ErrorActionPreference = "Stop"
if (-not (Test-Path $exe)) { throw "Export failed: $exe was not written (see export.log)." }
$exportErrors = @(Select-String -Path $exportLog -Pattern "ERROR")
if ($exportErrors.Count -gt 0) { $failures.Add("$($exportErrors.Count) error lines in export.log") }
# The export log lists every file it packs ("Storing File: res://...").
$packedDebug = @(Select-String -Path $exportLog -Pattern "Storing File: res://scripts/debug/")
if ($Tour -and $packedDebug.Count -eq 0) { $failures.Add("the debug-test build doesn't contain the tour runner") }
if (-not $Tour -and $packedDebug.Count -gt 0) { $failures.Add("the RELEASE build contains scripts/debug/ ($($packedDebug.Count) files)") }
Write-Host ("Built {0} ({1:N1} MB); export errors: {2}; scripts/debug files packed: {3}" -f
    $exe, ((Get-Item $exe).Length / 1MB), $exportErrors.Count, $packedDebug.Count)

function Invoke-Built([string[]]$GameArgs, [string]$Log, [int]$TimeoutSec) {
    # Runs the built game with an isolated user:// (real saves are never touched).
    $isolated = Join-Path ([IO.Path]::GetTempPath()) ("aeth_phase0_test_" + [guid]::NewGuid().ToString("N"))
    New-Item -ItemType Directory -Force $isolated | Out-Null
    $console = Join-Path $outDir "Aethelgard.console.exe"   # debug builds get a console wrapper
    $run = if (Test-Path $console) { $console } else { $exe }
    $oldAppData = $env:APPDATA
    try {
        $env:APPDATA = $isolated
        $p = Start-Process -FilePath $run -ArgumentList $GameArgs -PassThru -NoNewWindow `
            -RedirectStandardOutput $Log -RedirectStandardError "$Log.err"
        $done = $p.WaitForExit($TimeoutSec * 1000)
        if (-not $done) { $p.Kill() }
    } finally {
        $env:APPDATA = $oldAppData
        Remove-Item -LiteralPath $isolated -Recurse -Force -ErrorAction SilentlyContinue
    }
    Get-Content "$Log.err" -ErrorAction SilentlyContinue | Add-Content $Log
    Remove-Item -LiteralPath "$Log.err" -Force -ErrorAction SilentlyContinue
    return @{ Done = $done; Code = $(if ($done) { $p.ExitCode } else { -1 }); Text = (Get-Content $Log -Raw) }
}

function Test-LogClean([string]$Text) {
    foreach ($pattern in "SCRIPT ERROR", "Parse Error", "Failed loading resource", "Cannot open file", "No loader found") {
        $hits = ([regex]::Matches($Text, [regex]::Escape($pattern))).Count
        if ($hits -gt 0) { $failures.Add("$hits x '$pattern' in the built game's log") }
    }
}

if ($NoSmoke) {
    # build only
} elseif ($Tour) {
    # ── The screenshot tour, inside the built game ────────────────────────────
    $shots = Join-Path $project ("run_artifacts\screenshots\build-" + (Get-Date -Format "yyyyMMdd-HHmmss"))
    New-Item -ItemType Directory -Force $shots | Out-Null
    $gdignore = Join-Path $project "run_artifacts\.gdignore"
    if (-not (Test-Path $gdignore)) { New-Item -ItemType File $gdignore | Out-Null }
    $gameArgs = @("--resolution", "1280x720", "--", "--debug-tour", "`"--out=$shots`"")
    if ($Only.Count -gt 0) { $gameArgs += "--only=" + ($Only -join ",") }
    $tourLog = Join-Path $outDir "tour.log"
    Write-Host "Running the screenshot tour inside the built game (a window opens) ..."
    $r = Invoke-Built $gameArgs $tourLog 900
    $result = [regex]::Match($r.Text, "TOUR RESULT: .*").Value
    if (-not $r.Done) { $failures.Add("the tour didn't finish within 15 minutes") }
    elseif (-not $result) { $failures.Add("the tour never started or never finished (exit code $($r.Code))") }
    elseif ($r.Code -ne 0) { $failures.Add("$result (see $shots\report.md)") }
    Test-LogClean $r.Text
    [regex]::Matches($r.Text, "  PROBLEM: .*") | ForEach-Object { Write-Host $_.Value }
    Write-Host "Tour log: $tourLog"
    Write-Host "Screenshots: $shots"
    if ($result) { Write-Host $result }
} else {
    # ── Release boot, recorded, WITH the debug flag (it must be ignored) ─────
    $frames = Join-Path ([IO.Path]::GetTempPath()) ("aeth_movie_" + [guid]::NewGuid().ToString("N"))
    New-Item -ItemType Directory -Force $frames | Out-Null
    $smokeLog = Join-Path $outDir "smoke.log"
    $gameArgs = @("--resolution", "1280x720", "--write-movie", "`"$(Join-Path $frames 'f.png')`"",
                  "--fixed-fps", "10", "--quit-after", "120", "--", "--debug-tour")
    $r = Invoke-Built $gameArgs $smokeLog 180
    if (-not $r.Done) { $failures.Add("the game didn't exit within 3 minutes") }
    elseif ($r.Code -ne 0) { $failures.Add("exit code $($r.Code)") }
    Test-LogClean $r.Text
    if ($r.Text -match "DebugTestMode|Screenshot tour") { $failures.Add("the release build reacted to --debug-tour") }
    $recorded = @(Get-ChildItem $frames -Filter "f*.png" | Sort-Object Name)
    if ($recorded.Count -lt 100) { $failures.Add("only $($recorded.Count) of 120 frames were recorded") }
    if ($recorded.Count -gt 0) {
        # Four frames (0.5 s, 3 s, 6 s, the last) side by side, for a human to look at.
        Add-Type -AssemblyName System.Drawing
        $picks = @(5, 30, 60, ($recorded.Count - 1)) | ForEach-Object { [math]::Min($_, $recorded.Count - 1) }
        $w = 640; $h = 360
        $sheet = New-Object System.Drawing.Bitmap ($w * 2), ($h * 2)
        $g = [System.Drawing.Graphics]::FromImage($sheet)
        $font = New-Object System.Drawing.Font "Segoe UI", 14
        for ($i = 0; $i -lt 4; $i++) {
            $img = [System.Drawing.Image]::FromFile($recorded[$picks[$i]].FullName)
            $x = ($i % 2) * $w; $y = [math]::Floor($i / 2) * $h
            $g.DrawImage($img, $x, $y, $w, $h)
            $g.DrawString(("t = {0:N1} s" -f ($picks[$i] / 10)), $font, [System.Drawing.Brushes]::Yellow, $x + 8, $y + 8)
            $img.Dispose()
        }
        $sheet.Save((Join-Path $outDir "smoke_boot.png"))
        $g.Dispose(); $sheet.Dispose()
    }
    Remove-Item -LiteralPath $frames -Recurse -Force -ErrorAction SilentlyContinue
    Write-Host "Smoke log: $smokeLog"
    Write-Host "Boot frames: $(Join-Path $outDir 'smoke_boot.png')"
}

if ($failures.Count -gt 0) {
    Write-Host "FAILED:"
    $failures | ForEach-Object { Write-Host "  - $_" }
    exit 1
}
Write-Host $(if ($NoSmoke) { "BUILD OK" } elseif ($Tour) { "TOUR BUILD OK" } else { "RELEASE OK: booted, ignored --debug-tour, exited cleanly" })
exit 0
