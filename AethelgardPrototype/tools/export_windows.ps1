# Builds the Windows export (preset "Windows Desktop" -> exports/windows/Aethelgard.exe)
# and smoke-tests the BUILT game, not the editor copy:
#   1. checks the export templates for this exact Godot version are installed;
#   2. exports (release by default, -DebugBuild for a debug build);
#   3. boots Aethelgard.exe with a real renderer and an isolated user:// for 12 s
#      of game time, recording frames with Movie Maker (--write-movie). It must exit
#      cleanly with no script errors or missing resources in its log.
# Exported builds ignore --script (debug and release alike), so the screenshot tour
# can't run inside them; this smoke test covers boot -> splash -> main menu only.
# Output: exports/windows/ (git-ignored): the exe, export.log, smoke.log and
# smoke_boot.png (four frames from the recording).
# Usage (from AethelgardPrototype/):
#   powershell -File tools/export_windows.ps1
#   powershell -File tools/export_windows.ps1 -DebugBuild -NoSmoke
param(
    [switch]$DebugBuild,
    [switch]$NoSmoke
)
$ErrorActionPreference = "Stop"
$project = Split-Path -Parent $PSScriptRoot
$godot = Get-ChildItem "C:\Godot" -Filter "Godot_v4*_console.exe" | Sort-Object Name -Descending | Select-Object -First 1
if (-not $godot) { throw "Godot console executable not found under C:\Godot" }

# "4.6.3.stable.official.7d41c59c4" -> templates live in export_templates\4.6.3.stable
$version = ((& $godot.FullName --version) | Select-Object -Last 1).Trim()
$tplVersion = ($version -split '\.')[0..3] -join '.'
$tplDir = Join-Path $env:APPDATA "Godot\export_templates\$tplVersion"
$tplFile = if ($DebugBuild) { "windows_debug_x86_64.exe" } else { "windows_release_x86_64.exe" }
if (-not (Test-Path (Join-Path $tplDir $tplFile))) {
    throw "Export template $tplFile for Godot $tplVersion is not installed in $tplDir. Install it from Editor > Manage Export Templates."
}

$outDir = Join-Path $project "exports\windows"
New-Item -ItemType Directory -Force $outDir | Out-Null
$exe = Join-Path $outDir "Aethelgard.exe"
if (Test-Path $exe) { Remove-Item -LiteralPath $exe -Force }
$mode = if ($DebugBuild) { "--export-debug" } else { "--export-release" }
Write-Host "Exporting ($mode) with Godot $version ..."
$ErrorActionPreference = "Continue"   # Godot writes warnings to stderr
& $godot.FullName --headless --path $project $mode "Windows Desktop" $exe 2>&1 |
    ForEach-Object { "$_" } | Set-Content -Path (Join-Path $outDir "export.log")
$ErrorActionPreference = "Stop"
$exportErrors = Select-String -Path (Join-Path $outDir "export.log") -Pattern "ERROR"
if (-not (Test-Path $exe)) { throw "Export failed: $exe was not written (see export.log)." }
Write-Host ("Built {0} ({1:N1} MB), {2} error lines in export.log" -f $exe, ((Get-Item $exe).Length / 1MB), @($exportErrors).Count)
if ($NoSmoke) { exit 0 }

# ── Smoke test: boot the built game and record it ───────────────────────────
$frames = Join-Path ([IO.Path]::GetTempPath()) ("aeth_movie_" + [guid]::NewGuid().ToString("N"))
$isolated = Join-Path ([IO.Path]::GetTempPath()) ("aeth_phase0_test_" + [guid]::NewGuid().ToString("N"))
New-Item -ItemType Directory -Force $frames, $isolated | Out-Null
$smokeLog = Join-Path $outDir "smoke.log"
$oldAppData = $env:APPDATA
try {
    $env:APPDATA = $isolated   # user:// resolves under %APPDATA%: real saves are never touched
    $proc = Start-Process -FilePath $exe -PassThru -NoNewWindow `
        -RedirectStandardOutput $smokeLog -RedirectStandardError "$smokeLog.err" `
        -ArgumentList @("--resolution", "1280x720", "--write-movie", "`"$(Join-Path $frames 'f.png')`"",
                        "--fixed-fps", "10", "--quit-after", "120")
    $finished = $proc.WaitForExit(180000)
    if (-not $finished) { $proc.Kill() }
} finally {
    $env:APPDATA = $oldAppData
}
Get-Content "$smokeLog.err" -ErrorAction SilentlyContinue | Add-Content $smokeLog
Remove-Item -LiteralPath "$smokeLog.err" -Force -ErrorAction SilentlyContinue

$bad = @()
if (-not $finished) { $bad += "the game didn't exit within 3 minutes" }
elseif ($proc.ExitCode -ne 0) { $bad += "exit code $($proc.ExitCode)" }
$log = Get-Content $smokeLog -Raw
foreach ($pattern in "SCRIPT ERROR", "Parse Error", "Failed loading resource", "Cannot open file", "No loader found") {
    $hits = ([regex]::Matches($log, [regex]::Escape($pattern))).Count
    if ($hits -gt 0) { $bad += "$hits x '$pattern'" }
}
$recorded = @(Get-ChildItem $frames -Filter "f*.png" | Sort-Object Name)
if ($recorded.Count -lt 100) { $bad += "only $($recorded.Count) of 120 frames were recorded" }

# Four frames (0.5 s, 3 s, 6 s, the last) side by side, for a human to look at.
if ($recorded.Count -gt 0) {
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
Remove-Item -LiteralPath $isolated -Recurse -Force -ErrorAction SilentlyContinue

Write-Host "Smoke log: $smokeLog"
Write-Host "Boot frames: $(Join-Path $outDir 'smoke_boot.png')"
if ($bad.Count -gt 0) {
    Write-Host "SMOKE FAILED: $($bad -join '; ')"
    exit 1
}
Write-Host "SMOKE OK: booted, ran 12 s of game time, exited cleanly"
exit 0
