# Runs a headless test/probe script with an isolated user:// directory, so real
# save files are never read or overwritten.
# A suite fails on a non-zero exit OR on any SCRIPT ERROR / Parse Error line in its
# output (TD-003): a runtime script error aborts the rest of a test function while
# Godot still exits with the code the script chose. The runner then prints
# "RUNNER FAIL <script>: <N> script error line(s)" with the matching lines, and
# exits 1 (or keeps Godot's own non-zero code).
# Two limits per suite come from tests/suite_limits.txt (TD-007):
# - a time limit: a script error in the function that would call quit() leaves Godot
#   running forever, so at the deadline the runner stops Godot together with the real
#   Godot its console exe starts as a child, prints "RUNNER FAIL <script>: timed out
#   after <N> s" and exits 124;
# - a minimum number of checks that ran (passed + failed, read from the last
#   line that starts with an uppercase name and "RESULT: <N> passed, <M> failed" or "ok=<N> bad=<M>"), which catches a test
#   function that returns early without any error.
# A *_test.gd under res://tests/ without an entry in that file is refused; any other
# script gets 600 s and no minimum.
# Usage (from AethelgardPrototype/):
#   powershell -File tests/run_phase0_tests.ps1
#   powershell -File tests/run_phase0_tests.ps1 -Script res://docs/visual_review/phase10mm/phase10mm_validation.gd
#   powershell -File tests/run_phase0_tests.ps1 -Script <probe> -TimeoutSec 20 -MinChecks 2   # override the file
param(
    # res:// path of the script to run (a suite, or a throwaway probe).
    [string]$Script = "res://tests/integration/playthrough/phase0_blockers_test.gd",
    # Time limit in seconds. 0 = the suite's limit from tests/suite_limits.txt, else 600.
    [int]$TimeoutSec = 0,
    # Minimum checks (passed + failed) that must have run. -1 = the suite's minimum from
    # tests/suite_limits.txt, else none; 0 = no minimum.
    [int]$MinChecks = -1
)
$ErrorActionPreference = "Stop"
$project = Split-Path -Parent $PSScriptRoot
$godot = Get-ChildItem "C:\Godot" -Filter "Godot_v4*_console.exe" | Sort-Object Name -Descending | Select-Object -First 1
if (-not $godot) { throw "Godot console executable not found under C:\Godot" }

# Each line of suite_limits.txt: <res:// path> <min_checks> <timeout_seconds>; '#' starts a comment.
$limits = $null
foreach ($row in Get-Content (Join-Path $PSScriptRoot "suite_limits.txt")) {
    $f = -split (($row -replace "`r", '') -replace '#.*$', '')
    if ($f.Count -ge 3 -and $f[0] -ceq $Script) { $limits = $f; break }
}
if (-not $limits -and $Script -clike 'res://tests/*_test.gd') {
    Write-Host "RUNNER FAIL $($Script): no entry in tests/suite_limits.txt"
    exit 1
}
if ($TimeoutSec -le 0) { $TimeoutSec = if ($limits) { [int]$limits[2] } else { 600 } }
if ($MinChecks -lt 0) { $MinChecks = if ($limits) { [int]$limits[1] } else { 0 } }

# Scripts check for this marker in OS.get_user_data_dir() and refuse to run without it.
$isolated = Join-Path ([IO.Path]::GetTempPath()) ("aeth_phase0_test_" + [guid]::NewGuid().ToString("N"))
New-Item -ItemType Directory -Force $isolated | Out-Null
$oldAppData = $env:APPDATA
# Watchdog: a runspace in this process that sleeps to the deadline, then stops the Godot
# console exe started below (a child of this process) together with its own child, the real
# Godot. Killing is set before the first kill; TimedOut only when a kill really stopped a
# process, so a suite that exits on its own just before the deadline is not a timeout.
# It asks again each second for up to 10 s: a failed WMI query or taskkill must not leave
# the suite hanging, which is the hang this watchdog exists for. If taskkill fails, the
# real Godot and then the console exe are stopped one by one with Stop-Process.
$watch = [hashtable]::Synchronized(@{ Killing = $false; TimedOut = $false })
$dog = [powershell]::Create()
[void]$dog.AddScript({
    param($ParentId, $ExeName, $Seconds, $Watch)
    Start-Sleep -Seconds $Seconds
    for ($i = 0; $i -lt 10; $i++) {
        try {
            $procs = @(Get-CimInstance Win32_Process -Filter "ParentProcessId=$ParentId AND Name='$ExeName'" -ErrorAction Stop)
        } catch { Start-Sleep -Seconds 1; continue }
        if ($procs.Count -eq 0) { break }
        $Watch.Killing = $true
        foreach ($p in $procs) {
            try { & taskkill.exe /F /T /PID $p.ProcessId 2>&1 | Out-Null; $killed = ($LASTEXITCODE -eq 0) } catch { $killed = $false }
            if (-not $killed) {
                $kids = @(Get-CimInstance Win32_Process -Filter "ParentProcessId=$($p.ProcessId)" -ErrorAction SilentlyContinue)
                foreach ($k in $kids) { Stop-Process -Id $k.ProcessId -Force -ErrorAction SilentlyContinue }
                Stop-Process -Id $p.ProcessId -Force -ErrorAction SilentlyContinue
                $killed = $?
            }
            if ($killed) { $Watch.TimedOut = $true }
        }
        Start-Sleep -Seconds 1
    }
}).AddArgument($PID).AddArgument($godot.Name).AddArgument($TimeoutSec).AddArgument($watch)
$dogRun = $null
try {
    $env:APPDATA = $isolated   # Godot resolves user:// under %APPDATA% on Windows
    $ErrorActionPreference = "Continue"   # Godot writes to stderr; under 2>&1 Stop would throw on it
    $dogRun = $dog.BeginInvoke()
    # Stream every line as it arrives and keep a copy for the scans below.
    $lines = & $godot.FullName --headless --path $project --script $Script 2>&1 |
        ForEach-Object { $l = "$_"; Write-Host $l; $l }
    $code = $LASTEXITCODE
} finally {
    # If the watchdog is mid-kill, let it finish so TimedOut is final before it is read.
    if ($watch.Killing -and $dogRun) { [void]$dogRun.AsyncWaitHandle.WaitOne(20000) }
    $dog.Stop()
    $dog.Dispose()
    $env:APPDATA = $oldAppData
    # After a timeout the killed processes may hold the dir for a moment: retry for up to 5 s.
    $until = [DateTime]::UtcNow.AddSeconds($(if ($watch.TimedOut) { 5 } else { 0 }))
    while ($true) {
        Remove-Item -Recurse -Force $isolated -ErrorAction SilentlyContinue
        if (-not (Test-Path $isolated) -or [DateTime]::UtcNow -ge $until) { break }
        Start-Sleep -Milliseconds 250
    }
}

$failed = $false
if ($watch.TimedOut) {
    Write-Host ""
    Write-Host "RUNNER FAIL $($Script): timed out after $TimeoutSec s"
    $failed = $true
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
    $failed = $true
}

# A suite that timed out has no result line; the timeout is the reason, not the count.
if ($MinChecks -gt 0 -and -not $watch.TimedOut) {
    # A result line starts at column 0 with an uppercase name ("LAYOUT RESULT: 6 passed, 0 failed",
    # "LOADALL ok=206 bad=0"), so a check description that quotes one is never counted; the last
    # such line wins, and a lowercase "result:" is not one. The end is not anchored (a trailing CR).
    $result = @($lines | Select-String -CaseSensitive -Pattern '^[A-Z0-9][A-Z0-9 ]* (?:RESULT: (\d+) passed, (\d+) failed|ok=(\d+) bad=(\d+))') |
        Select-Object -Last 1
    if (-not $result) {
        Write-Host ""
        Write-Host "RUNNER FAIL $($Script): no result line (expected at least $MinChecks checks to run)"
        $failed = $true
    } else {
        # Failed checks count as run: a failure already fails the suite through Godot's exit code.
        $ran = 0
        foreach ($g in $result.Matches[0].Groups | Select-Object -Skip 1) { if ($g.Success) { $ran += [int]$g.Value } }
        if ($ran -lt $MinChecks) {
            Write-Host ""
            Write-Host "RUNNER FAIL $($Script): $ran check(s) ran, expected at least $MinChecks"
            $failed = $true
        }
    }
}

if ($watch.TimedOut) { $code = 124 } elseif ($failed -and $code -eq 0) { $code = 1 }
exit $code
