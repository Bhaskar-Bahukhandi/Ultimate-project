# Runs the visual tour (tests/screenshot_tour.gd) with a real renderer and an
# isolated user:// directory. A game window opens for a couple of minutes; audio
# is muted. Output: run_artifacts/screenshots/<timestamp>/ (git-ignored) with
# one PNG per shot, contact_scenes.png, contact_dialogue.png, report.md, tour.log.
# Usage (from AethelgardPrototype/):
#   powershell -File tests/run_screenshots.ps1
#   powershell -File tests/run_screenshots.ps1 -Only main_menu,ch2_,dlg_ch1
#   powershell -File tests/run_screenshots.ps1 -Only ch1_shatter -Evidence shatter
# -Evidence <topic> also copies the PNGs and report.md into the committed folder
# production/qa/evidence/<YYYY-MM>-<topic>/ (see its README), with a capture.md
# saying how they were made. Nothing is copied if the tour fails.
param(
    [string[]]$Only = @(),
    [string]$Evidence = ""
)
if ($Evidence -and $Evidence -notmatch '^[a-z0-9]+(-[a-z0-9]+)*$') {
    throw "-Evidence takes a lowercase, hyphenated topic such as 'shatter' or 'ch1-fights'."
}
$ErrorActionPreference = "Stop"
$project = Split-Path -Parent $PSScriptRoot
$godot = Get-ChildItem "C:\Godot" -Filter "Godot_v4*_console.exe" | Sort-Object Name -Descending | Select-Object -First 1
if (-not $godot) { throw "Godot console executable not found under C:\Godot" }

$artifacts = Join-Path $project "run_artifacts"
$out = Join-Path $artifacts ("screenshots\" + (Get-Date -Format "yyyyMMdd-HHmmss"))
New-Item -ItemType Directory -Force $out | Out-Null
# Keep Godot from importing the PNGs as project assets.
$gdignore = Join-Path $artifacts ".gdignore"
if (-not (Test-Path $gdignore)) { New-Item -ItemType File $gdignore | Out-Null }

$isolated = Join-Path ([IO.Path]::GetTempPath()) ("aeth_phase0_test_" + [guid]::NewGuid().ToString("N"))
New-Item -ItemType Directory -Force $isolated | Out-Null
$oldAppData = $env:APPDATA
$userArgs = @("--out=$out")
if ($Only.Count -gt 0) { $userArgs += "--only=" + ($Only -join ",") }
try {
    $env:APPDATA = $isolated   # Godot resolves user:// under %APPDATA% on Windows
    $ErrorActionPreference = "Continue"   # Godot writes warnings to stderr
    & $godot.FullName --path $project --resolution 1280x720 --script res://tests/screenshot_tour.gd -- @userArgs 2>&1 |
        ForEach-Object { "$_" } | Tee-Object -FilePath (Join-Path $out "tour.log")
    $code = $LASTEXITCODE
} finally {
    $env:APPDATA = $oldAppData
    Remove-Item -Recurse -Force $isolated -ErrorAction SilentlyContinue
}
Write-Host "Screenshots: $out"

if ($Evidence) {
    if ($code -ne 0) {
        Write-Warning "Tour failed (exit $code): nothing copied to evidence."
    } else {
        $repo = Split-Path -Parent $project
        $dest = Join-Path $repo ("production\qa\evidence\" + (Get-Date -Format "yyyy-MM") + "-" + $Evidence)
        New-Item -ItemType Directory -Force $dest | Out-Null
        $shots = Get-ChildItem $out -Filter "*.png" | Where-Object { $_.Name -notlike "contact_*" }
        $shots | Copy-Item -Destination $dest -Force
        Copy-Item (Join-Path $out "report.md") (Join-Path $dest "report.md") -Force -ErrorAction SilentlyContinue
        $commit = (& git -C $repo rev-parse --short HEAD 2>$null)
        $dirty = if (& git -C $repo status --porcelain -- AethelgardPrototype 2>$null) { " (uncommitted changes under AethelgardPrototype/)" } else { "" }
        $only = if ($Only.Count -gt 0) { " -Only " + ($Only -join ",") } else { "" }
        @(
            "# Capture: $(Get-Date -Format 'yyyy-MM-dd HH:mm')",
            "",
            "- **How:** real-renderer tour (``tests/run_screenshots.ps1$only -Evidence $Evidence``), 1280x720, $($godot.Name)",
            "- **Commit:** $commit$dirty",
            "- **Source run:** ``$out`` (git-ignored)",
            ("- **Files:** " + (($shots | ForEach-Object { $_.Name }) -join ", "))
        ) | Set-Content -Path (Join-Path $dest "capture.md") -Encoding utf8
        Write-Host "Evidence: $($shots.Count) screenshot(s) copied to $dest"
    }
}
exit $code
