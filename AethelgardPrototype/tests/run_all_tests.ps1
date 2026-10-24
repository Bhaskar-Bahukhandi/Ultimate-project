# Runs every headless test suite, in the same order as .github/workflows/ci.yml.
# Keep SUITES in sync with the ci.yml steps when adding or removing a suite.
# Each suite goes through run_phase0_tests.ps1, so user:// stays isolated. A suite also
# fails on any SCRIPT ERROR / Parse Error line in its output (TD-003), not only on a non-zero exit.
# Each suite's time limit and minimum check count come from tests/suite_limits.txt (TD-007): a new
# suite needs a line there, or the runner refuses it.
# Usage (from AethelgardPrototype/ or the repo root):
#   powershell -File tests/run_all_tests.ps1          # all 17 suites
#   powershell -File tests/run_all_tests.ps1 -Quick   # skip the long route and phase0 suites
param(
    [switch]$Quick
)
$runner = Join-Path $PSScriptRoot "run_phase0_tests.ps1"
$suites = @(
    @{ Script = "res://tests/integration/meta/test_layout_test.gd";           Long = $false }
    @{ Script = "res://tests/integration/project/load_all_test.gd";           Long = $false }
    @{ Script = "res://tests/integration/dialogue/dialogue_test.gd";          Long = $false }
    @{ Script = "res://tests/integration/core/context_stack_test.gd";         Long = $false }
    @{ Script = "res://tests/integration/input/input_test.gd";                Long = $false }
    @{ Script = "res://tests/unit/quests/side_quest_rewards_test.gd";         Long = $false }
    @{ Script = "res://tests/unit/ngplus/ngplus_buff_stacking_test.gd";       Long = $false }
    @{ Script = "res://tests/unit/ngplus/ngplus_save_roundtrip_test.gd";      Long = $false }
    @{ Script = "res://tests/unit/achievements/fragment_achievement_test.gd"; Long = $false }
    @{ Script = "res://tests/unit/items/null_potion_test.gd";                Long = $false }
    @{ Script = "res://tests/integration/vfx/screen_flash_test.gd";          Long = $false }
    @{ Script = "res://tests/integration/story/chapter1_route_test.gd";       Long = $true }
    @{ Script = "res://tests/integration/story/chapter2_route_test.gd";       Long = $true }
    @{ Script = "res://tests/integration/combat/combat_fixes_test.gd";        Long = $false }
    @{ Script = "res://tests/integration/level/reachability_test.gd";         Long = $false }
    @{ Script = "res://tests/integration/quests/act1_quests_completable_test.gd"; Long = $true }
    @{ Script = "res://tests/integration/playthrough/phase0_blockers_test.gd"; Long = $true }
)
$failed = @()
foreach ($s in $suites) {
    if ($Quick -and $s.Long) { Write-Host "SKIP  $($s.Script) (-Quick)"; continue }
    Write-Host "=== $($s.Script)"
    & powershell -NoProfile -File $runner -Script $s.Script
    if ($LASTEXITCODE -ne 0) { $failed += "$($s.Script) (exit $LASTEXITCODE)" }
}
if ($failed.Count -gt 0) {
    Write-Host "`nFAILED $($failed.Count) suite(s):"
    $failed | ForEach-Object { Write-Host "  $_" }
    exit 1
}
Write-Host "`nAll suites passed."
exit 0
