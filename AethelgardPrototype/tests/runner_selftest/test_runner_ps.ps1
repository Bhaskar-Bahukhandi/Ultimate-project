# Self-test for tests/run_phase0_tests.ps1 (TD-010). Windows PowerShell 5.1, LOCAL ONLY.
#   powershell -NoProfile -File AethelgardPrototype\tests\runner_selftest\test_runner_ps.ps1
#
# Runs the REAL runner with $env:GODOT pointing at stub_godot.cmd (absolute path), so no Godot
# starts. The stub prints a fixture from ps_fixtures\, touches a marker file and exits with
# STUB_EXIT. Every case uses -TimeoutSec 30 so a runner that ignored GODOT could not hold the
# real C:\Godot for long; the self-test also refuses to run a case whose GODOT is not under
# this folder or the scratch dir.
#
# Local-only: CI (ubuntu) cannot run the PS runner (needs C:\Godot, Get-CimInstance, taskkill).
# NOT covered (backlog item, TD-010 story AC-9): the watchdog's timeout / kill paths. They need a
# compiled .exe stub, because the watchdog finds Godot by process name and a .cmd runs as cmd.exe.
#
# The runner ends with `exit`, so each ordinary case runs it in a CHILD `powershell -NoProfile
# -File` process (exit code = $LASTEXITCODE, output = stdout via *>&1). The in-process leak case
# calls the runner with `&` from this script's own scope instead: `exit` in a script run by `&`
# ends only that script, so this self-test survives and reports. (Dot-sourcing would end the
# self-test; -File would be a new process and could not see this scope's variables.)
# The warning cases use -MinChecks to set the minimum (suite_limits.txt is not edited); the
# min=21 / ran=25 ceil cases are covered by the bash self-test, which can fake a larger count.
$ErrorActionPreference = "Continue"
$here = $PSScriptRoot
$runner = Join-Path (Split-Path -Parent $here) "run_phase0_tests.ps1"
$stub = Join-Path $here "stub_godot.cmd"
$fixDir = Join-Path $here "ps_fixtures"
$scratch = Join-Path ([IO.Path]::GetTempPath()) ("aeth_ps_selftest_" + [guid]::NewGuid().ToString("N"))
New-Item -ItemType Directory -Force $scratch | Out-Null

$saved = @{}
foreach ($n in "GODOT", "APPDATA", "STUB_FIXTURE", "STUB_MARKER", "STUB_EXIT") { $saved[$n] = [Environment]::GetEnvironmentVariable($n) }

$script:pass = 0
$script:fail = 0
$script:caseNo = 0

function Report([string]$name, [bool]$ok, [string]$detail) {
    if ($ok) { $script:pass++; Write-Host "PASS  $name" }
    else { $script:fail++; Write-Host "FAIL  $name"; if ($detail) { Write-Host ($detail -replace "(?m)^", "      | ") } }
}

# Runs the runner in a child powershell. Returns @{ Code; Text; Marker }.
function Invoke-Runner([string]$fixture, [string[]]$runnerArgs, [string]$exit = "", [string]$godot = $stub) {
    $script:caseNo++
    $marker = Join-Path $scratch ("marker_" + $script:caseNo)
    if ($godot -ne $stub -and -not $godot.StartsWith($scratch)) { throw "refusing GODOT outside the scratch dir: $godot" }
    $env:GODOT = $godot
    $env:STUB_FIXTURE = if ($fixture) { Join-Path $fixDir $fixture } else { "" }
    $env:STUB_MARKER = $marker
    $env:STUB_EXIT = $exit
    $out = & powershell -NoProfile -ExecutionPolicy Bypass -File $runner @runnerArgs -TimeoutSec 30 *>&1
    $code = $LASTEXITCODE
    $text = (@($out | ForEach-Object { "$_" }) -join "`n")
    return @{ Code = $code; Text = $text; Marker = (Test-Path $marker) }
}

# Asserts exit code, required / forbidden text and the marker for one run.
function Check([string]$name, $r, [int]$code, [string[]]$has = @(), [string[]]$hasNot = @(), [bool]$markerExpected = $true) {
    $problems = @()
    if ($r.Code -ne $code) { $problems += "exit code $($r.Code), expected $code" }
    foreach ($s in $has) { if (-not $r.Text.Contains($s)) { $problems += "missing text: $s" } }
    foreach ($s in $hasNot) { if ($r.Text.Contains($s)) { $problems += "unexpected text: $s" } }
    if ($r.Marker -ne $markerExpected) { $problems += "marker present=$($r.Marker), expected $markerExpected" }
    Report $name ($problems.Count -eq 0) (($problems -join "`n") + "`n--- output ---`n" + $r.Text)
}

try {
    # The stub must really be CRLF: LF-only .cmd files can misparse labels and long lines.
    $bytes = [IO.File]::ReadAllBytes($stub)
    $lf = @($bytes | Where-Object { $_ -eq 10 }).Count
    $crlf = 0
    for ($i = 1; $i -lt $bytes.Length; $i++) { if ($bytes[$i] -eq 10 -and $bytes[$i - 1] -eq 13) { $crlf++ } }
    Report "stub_godot.cmd has CRLF line endings only" ($lf -gt 0 -and $lf -eq $crlf) "LF bytes: $lf, CRLF pairs: $crlf"

    $fake = "res://stub/fake.gd"   # not res://tests/*_test.gd, so no suite_limits.txt entry and no refusal

    $r = Invoke-Runner "pass.txt" @("-Script", $fake, "-MinChecks", "2")
    Check "pass: exit 0, no RUNNER FAIL/WARN, marker, override named" $r 0 @("STUB RESULT: 2 passed, 0 failed", "GODOT override: $stub") @("RUNNER FAIL", "RUNNER WARN")

    $r = Invoke-Runner "script_errors.txt" @("-Script", $fake)
    Check "script errors: exit 1, 2 lines listed" $r 1 @(
        "RUNNER FAIL $($fake): 2 script error line(s)", "SCRIPT ERROR: stub failure one", "at: stub_a (res://stub.gd:1)",
        "Parse Error: stub failure two", "at: stub_b (res://stub.gd:2)")

    $r = Invoke-Runner "pass.txt" @("-Script", $fake) "3"
    Check "pass with STUB_EXIT=3: exit 3 passes through" $r 3 @() @("RUNNER FAIL")

    $r = Invoke-Runner "two_results.txt" @("-Script", $fake, "-MinChecks", "4")
    Check "last result line wins (1 then 5, min 4): exit 0" $r 0 @() @("RUNNER FAIL")

    $r = Invoke-Runner "two_results_reversed.txt" @("-Script", $fake, "-MinChecks", "4")
    Check "last result line wins (5 then 1, min 4): exit 1" $r 1 @("RUNNER FAIL $($fake): 1 check(s) ran, expected at least 4")

    $r = Invoke-Runner "no_result.txt" @("-Script", $fake, "-MinChecks", "1")
    Check "no result line, min 1: exit 1" $r 1 @("RUNNER FAIL $($fake): no result line (expected at least 1 checks to run)")

    $r = Invoke-Runner "loadall.txt" @("-Script", $fake, "-MinChecks", "7")
    Check "ok=7 bad=0, min 7: exit 0" $r 0 @("LOADALL ok=7 bad=0") @("RUNNER FAIL")

    $r = Invoke-Runner "loadall.txt" @("-Script", $fake, "-MinChecks", "8")
    Check "ok=7 bad=0, min 8: exit 1" $r 1 @("RUNNER FAIL $($fake): 7 check(s) ran, expected at least 8")

    $r = Invoke-Runner "pass.txt" @("-Script", "res://tests/selftest/fake_test.gd")
    Check "unregistered res://tests/*_test.gd: exit 1, stub not run" $r 1 @("RUNNER FAIL res://tests/selftest/fake_test.gd: no entry in tests/suite_limits.txt") @() $false

    $missing = Join-Path $scratch "no_such_godot.exe"
    $r = Invoke-Runner "pass.txt" @("-Script", $fake) "" $missing
    Check "GODOT at a missing absolute path: exit 1, 'did not start' text" $r 1 @(
        "RUNNER FAIL $($fake): Godot did not start, or the runner failed before reading its exit code") @() $false

    # Stale-min_checks warning (checks13.txt reports 12 passed + 1 failed = 13 checks).
    $warnText = "RUNNER WARN $($fake): 13 checks ran, suite_limits.txt minimum is 10"
    $r = Invoke-Runner "checks13.txt" @("-Script", $fake, "-MinChecks", "10")
    Check "warning: min 10, ran 13 warns, exit 0, no RUNNER FAIL" $r 0 @($warnText) @("RUNNER FAIL")

    $r = Invoke-Runner "checks13.txt" @("-Script", $fake, "-MinChecks", "11")
    Check "warning: min 11, ran 13 (slack 2) does not warn" $r 0 @() @("RUNNER WARN", "RUNNER FAIL")

    $r = Invoke-Runner "checks13.txt" @("-Script", $fake, "-MinChecks", "13")
    Check "warning: min 13, ran 13 does not warn" $r 0 @() @("RUNNER WARN", "RUNNER FAIL")

    $r = Invoke-Runner "checks13.txt" @("-Script", $fake, "-MinChecks", "0")
    Check "warning: min 0, ran 13 does not warn" $r 0 @() @("RUNNER WARN", "RUNNER FAIL")

    $r = Invoke-Runner "checks13.txt" @("-Script", $fake, "-MinChecks", "10") "3"
    Check "warning leaves a non-zero Godot exit code unchanged (exit 3)" $r 3 @($warnText) @("RUNNER FAIL")

}
finally {
    foreach ($n in $saved.Keys) { [Environment]::SetEnvironmentVariable($n, $saved[$n]) }
}

# In-process leak case: $code and $lines set in THIS scope must not be read by the runner
# when Godot never starts (dynamic scoping). Called with `&`, GODOT at a missing path.
# It runs OUTSIDE any try block on purpose: with a try in the caller, the launch failure
# (CommandNotFound) propagates as a terminating error through the runner and ends this
# self-test before the case can report; without one, the runner handles it and exits 1.
$leakMarker = Join-Path $scratch "marker_leak"
$env:GODOT = $missing
$env:STUB_FIXTURE = ""
$env:STUB_MARKER = $leakMarker
$env:STUB_EXIT = ""
$code = 0
$lines = @("X RESULT: 9 passed, 0 failed")
$leakOut = & $runner -Script $fake -TimeoutSec 30 *>&1
$leakCode = $LASTEXITCODE
$leakText = (@($leakOut | ForEach-Object { "$_" }) -join "`n")
$problems = @()
if ($leakCode -ne 1) { $problems += "exit code $leakCode, expected 1" }
if (-not $leakText.Contains("Godot did not start, or the runner failed before reading its exit code")) { $problems += "missing 'did not start' text" }
if (Test-Path $leakMarker) { $problems += "stub ran (marker present)" }
Report "in-process leak: caller's `$code=0 / `$lines do not hide a launch failure" ($problems.Count -eq 0) (($problems -join "`n") + "`n--- output ---`n" + $leakText)

foreach ($n in $saved.Keys) { [Environment]::SetEnvironmentVariable($n, $saved[$n]) }
Remove-Item -Recurse -Force $scratch -ErrorAction SilentlyContinue

Write-Host ""
Write-Host "RUNNER PS SELFTEST RESULT: $($script:pass) passed, $($script:fail) failed"
if ($script:fail -gt 0) { exit 1 }
exit 0
