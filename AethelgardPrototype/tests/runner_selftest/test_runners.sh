#!/usr/bin/env bash
# Permanent self-test for tests/run_tests.sh (Y1-P0-TD-010). Runs the real runner with
# GODOT pointing at stub_godot.sh, which prints canned lines or sleeps, so no Godot is needed.
# It covers the runner behaviours TD-003 / TD-007 / TD-009 proved with throw-away probes:
# the script-error scan, exit codes, the last result line winning, no result line, the minimum
# check count, an unregistered suite, the GNU timeout -k path (124 over 137, the elapsed rule),
# NUL / 0xFF bytes in the output, the stale-min_checks warning and bad environment values.
#
# Isolation: every case runs under `env -u GITHUB_ACTIONS -u MIN_CHECKS -u TEST_TIMEOUT -u LC_ALL`
# plus only the variables that case sets, with its output in a file outside the scratch TMPDIR
# given to the runner. Every runner call sits inside `timeout -k 5 40`, so a broken runner fails
# a case instead of hanging CI. Needs GNU coreutils timeout (exit 2 otherwise).
# Usage (anywhere): bash AethelgardPrototype/tests/runner_selftest/test_runners.sh
# Last line: "RUNNER SELFTEST RESULT: <N> passed, <F> failed"; exit 0 only if F is 0.
set -u

here="$(cd "$(dirname "$0")" && pwd)"
runner="$(cd "$here/.." && pwd)/run_tests.sh"
stub="$here/stub_godot.sh"

# Resolved before any PATH change (the non-GNU timeout case puts a fake one first).
real_timeout="$(command -v timeout || true)"
case "$("$real_timeout" --version 2>&1 || true)" in
    *coreutils*) ;;
    *) echo "RUNNER SELFTEST: GNU coreutils timeout(1) is required (found '${real_timeout:-none}')" >&2; exit 2 ;;
esac
if [ ! -f "$runner" ] || [ ! -x "$stub" ]; then
    echo "RUNNER SELFTEST: need $runner and an executable $stub" >&2
    exit 2
fi

work="$(mktemp -d "${TMPDIR:-/tmp}/aeth_selftest_XXXXXX")"
scratch="$work/runner_tmp"   # the runner's TMPDIR: must be empty again at the end
out="$work/out"              # per-case output and marker files
mkdir -p "$scratch" "$out"
trap 'rm -rf "$work"' EXIT
start_all=$SECONDS

passed=0
failed=0
problems=""
case_no=0
RC=0 OUT="" MARKER="" CAPPED=0 ELAPSED=0

# run_runner [VAR=value ...] [-- <script>]
# Runs the real runner once. Sets RC (exit code), OUT (captured stdout+stderr file), MARKER
# (the file the stub touches), ELAPSED (whole seconds the call took). Set the array `inner_env` first to wrap the runner in `env ...`.
inner_env=()
run_runner() {
    local envs=() script="res://selftest/stub_case.gd"
    while [ $# -gt 0 ] && [ "$1" != "--" ]; do envs+=("$1"); shift; done
    if [ $# -gt 0 ]; then shift; script="${1:-$script}"; fi
    case_no=$((case_no + 1))
    OUT="$out/case$case_no.out"
    MARKER="$out/case$case_no.marker"
    local t0=$SECONDS
    env -u GITHUB_ACTIONS -u MIN_CHECKS -u TEST_TIMEOUT -u LC_ALL \
        TMPDIR="$scratch" GODOT="$stub" STUB_MARKER="$MARKER" \
        ${envs[@]+"${envs[@]}"} \
        "$real_timeout" -k 5 40 ${inner_env[@]+"${inner_env[@]}"} bash "$runner" "$script" > "$OUT" 2>&1
    RC=$?
    ELAPSED=$((SECONDS - t0))
    CAPPED=0
    if { [ "$RC" -eq 124 ] || [ "$RC" -eq 137 ]; } && [ "$ELAPSED" -ge 40 ]; then CAPPED=1; fi
    inner_env=()
}

problem() { problems="$problems; $1"; }
expect_exit() {
    if [ "$CAPPED" -eq 1 ]; then problem "outer 40 s cap hit (runner hung), exit $RC"; return; fi
    [ "$RC" -eq "$1" ] || problem "exit $RC, expected $1"
}
expect_text() { LC_ALL=C grep -aqF -- "$1" "$OUT" || problem "output lacks '$1'"; }
expect_no_text() { ! LC_ALL=C grep -aqF -- "$1" "$OUT" || problem "output has '$1'"; }
expect_line() { LC_ALL=C grep -aqxF -- "$1" "$OUT" || problem "output lacks the exact line '$1'"; }
expect_marker() {
    if [ "$1" = yes ]; then [ -e "$MARKER" ] || problem "stub did not run (no marker)"
    else [ ! -e "$MARKER" ] || problem "stub ran (marker present)"; fi
}
# finish <case description>: one PASS / FAIL line, in the style of the other suites
finish() {
    if [ -z "$problems" ]; then
        passed=$((passed + 1)); echo "  PASS: $1"
    else
        failed=$((failed + 1)); echo "  FAIL: $1 -- ${problems#; }"
        echo "    --- runner output (last 15 lines, case $case_no) ---"
        tail -n 15 "$OUT" | LC_ALL=C sed 's/^/    | /' | tr -d '\000'
    fi
    problems=""
}

echo "Runner self-test: $runner"
echo "  timeout: $("$real_timeout" --version 2>&1 | head -1)"

# --- result lines, minimum checks, exit codes -----------------------------------------------
run_runner STUB_MODE=pass MIN_CHECKS=2
expect_exit 0; expect_no_text "RUNNER FAIL"; expect_marker yes
finish "pass, 2 checks, MIN_CHECKS=2: exit 0, no RUNNER FAIL, stub ran"

run_runner STUB_MODE=script_errors
expect_exit 1; expect_text "RUNNER FAIL res://selftest/stub_case.gd: 2 script error line(s)"
expect_line "  SCRIPT ERROR: stub failure one"
expect_line "     at: stub_a (res://stub.gd:1)"
expect_line "  Parse Error: stub failure two"
expect_line "     at: stub_b (res://stub.gd:2)"
finish "script_errors with Godot exit 0: exit 1, '2 script error line(s)', all four lines listed"

run_runner STUB_MODE=pass STUB_EXIT=3
expect_exit 3
finish "pass with STUB_EXIT=3: Godot's own exit code 3 passes through"

run_runner STUB_MODE=two_results MIN_CHECKS=4
expect_exit 0; expect_no_text "RUNNER FAIL"
finish "two_results (1 then 5), MIN_CHECKS=4: last result line wins, exit 0"

run_runner STUB_MODE=two_results_reversed MIN_CHECKS=4
expect_exit 1; expect_text "1 check(s) ran, expected at least 4"
finish "two_results_reversed (5 then 1), MIN_CHECKS=4: last line wins, exit 1 with '1 check(s) ran'"

run_runner STUB_MODE=no_result MIN_CHECKS=1
expect_exit 1; expect_text "no result line (expected at least 1 checks to run)"
finish "no_result, MIN_CHECKS=1: exit 1 and 'no result line (expected at least 1 checks to run)'"

run_runner STUB_MODE=loadall MIN_CHECKS=7
expect_exit 0; expect_no_text "RUNNER FAIL"
finish "loadall 'ok=7 bad=0', MIN_CHECKS=7: exit 0"

run_runner STUB_MODE=loadall MIN_CHECKS=8
expect_exit 1; expect_text "7 check(s) ran, expected at least 8"
finish "loadall 'ok=7 bad=0', MIN_CHECKS=8: exit 1"

run_runner STUB_MODE=pass -- res://tests/selftest/fake_test.gd
expect_exit 1; expect_text "no entry in tests/suite_limits.txt"; expect_marker no
finish "unregistered res://tests/selftest/fake_test.gd: exit 1, 'no entry in tests/suite_limits.txt', stub not run"

# --- GNU timeout path (stubs sleep 20 s; the limit is 2 s, so SECONDS granularity cannot matter) ---
run_runner STUB_MODE=sleep TEST_TIMEOUT=2 MIN_CHECKS=1
expect_exit 124; expect_text "timed out after 2 s"; expect_no_text "no result line"
finish "sleep, TEST_TIMEOUT=2, MIN_CHECKS=1: exit 124, 'timed out after 2 s', no 'no result line'"

run_runner STUB_MODE=ignore_term TEST_TIMEOUT=2
expect_exit 124; expect_text "timed out after 2 s"
# Without -k 10 GNU timeout still exits 124, but only when the 20 s sleep ends; with it the KILL
# lands at about 12 s. The time is what proves the KILL.
[ "$ELAPSED" -lt 17 ] || problem "runner took $ELAPSED s (the KILL 10 s after the TERM should end it at about 12 s)"
finish "ignore_term (TERM ignored), TEST_TIMEOUT=2: KILL after 10 s (137) mapped to exit 124 within 17 s, 'timed out after 2 s'"

run_runner STUB_MODE=selfkill TEST_TIMEOUT=20
expect_exit 137; expect_no_text "timed out"
finish "selfkill after 1 s, TEST_TIMEOUT=20: exit 137 passes through, no 'timed out' text"

# --- watchdog availability, bad environment, missing executable -----------------------------
fake="$work/fake_bin"
mkdir -p "$fake"
cat > "$fake/timeout" <<'EOF'
#!/usr/bin/env bash
# Not coreutils: what a BSD / busybox timeout looks like to the runner's version probe.
if [ "${1:-}" = "--version" ]; then echo "timeout (fake busybox-style, not GNU)"; exit 0; fi
exit 0
EOF
chmod +x "$fake/timeout"

inner_env=(env "PATH=$fake:$PATH")
run_runner STUB_MODE=pass
expect_exit 0; expect_text "GNU timeout(1) not found"; expect_no_text "RUNNER FAIL"; expect_marker yes
finish "non-GNU timeout first on PATH, no GITHUB_ACTIONS: warning, runs without a limit, exit 0"

inner_env=(env "PATH=$fake:$PATH")
run_runner STUB_MODE=pass GITHUB_ACTIONS=true
expect_exit 1; expect_text "GNU timeout(1) not found"; expect_text "RUNNER FAIL"; expect_marker no
finish "non-GNU timeout first on PATH, GITHUB_ACTIONS=true: RUNNER FAIL 'GNU timeout(1) not found', exit 1"

run_runner GODOT="$out/no_such_godot"
expect_exit 127; expect_no_text "RUNNER FAIL"
finish "GODOT at a missing file: exit 127, no RUNNER FAIL message (characterises today's silent failure)"

run_runner STUB_MODE=pass MIN_CHECKS=x
expect_exit 1; expect_text "MIN_CHECKS must be a whole number"; expect_marker no
finish "MIN_CHECKS=x: exit 1, 'MIN_CHECKS must be a whole number', stub not run"

run_runner STUB_MODE=pass TEST_TIMEOUT=0
expect_exit 1; expect_text "TEST_TIMEOUT must be a whole number of seconds above 0"; expect_marker no
finish "TEST_TIMEOUT=0: exit 1, stub not run"

# --- stale-min_checks warning: ran > min + max(2, ceil(min / 10)) -----------------------------
warn_case() {   # warn_case <min> <ran> <warns: yes|no>
    local text="RUNNER WARN res://selftest/stub_case.gd: $2 checks ran, suite_limits.txt minimum is $1"
    run_runner STUB_MODE=counted STUB_COUNT="$2" MIN_CHECKS="$1"
    expect_exit 0; expect_no_text "RUNNER FAIL"
    if [ "$3" = yes ]; then expect_line "$text"; else expect_no_text "RUNNER WARN"; fi
    finish "warning: min $1, ran $2: $( [ "$3" = yes ] && echo "'$text', exit 0" || echo "no warning, exit 0" )"
}
warn_case 10 13 yes
warn_case 10 12 no
warn_case 10 10 no
warn_case 21 24 no
warn_case 21 25 yes
warn_case 0 50 no

run_runner STUB_MODE=counted STUB_COUNT=13 MIN_CHECKS=10 GITHUB_ACTIONS=true
expect_exit 0; expect_no_text "RUNNER FAIL"
expect_line "::warning::RUNNER WARN res://selftest/stub_case.gd: 13 checks ran, suite_limits.txt minimum is 10"
finish "warning under GITHUB_ACTIONS=true: '::warning::' prefix, exit 0"

# The stub prints a result line well over the minimum, then hangs: only the timed-out guard keeps
# the warning (and the count check) from reading that line.
run_runner STUB_MODE=result_then_sleep TEST_TIMEOUT=2 MIN_CHECKS=1
expect_exit 124; expect_text "timed out after 2 s"; expect_no_text "RUNNER WARN"
finish "warning: a suite that printed 50 checks and then timed out prints no RUNNER WARN, exit 124"

# A leading zero is decimal: 08 must not fail the arithmetic as octal (13 > 8 + 2 warns).
run_runner STUB_MODE=counted STUB_COUNT=13 MIN_CHECKS=08
expect_exit 0; expect_no_text "value too great"; expect_no_text "RUNNER FAIL"
expect_line "RUNNER WARN res://selftest/stub_case.gd: 13 checks ran, suite_limits.txt minimum is 8"
finish "warning: MIN_CHECKS=08 is read as 8 (no octal error), ran 13 warns, exit 0"

# --- NUL and 0xFF bytes ------------------------------------------------------------------------
# Expected listing: the lines after the 'RUNNER FAIL ... script error line(s)' line, each indented
# two spaces; the NUL bytes sit in the two 'at:' lines (the -A1 context) and the "--" group
# separator between the two entries is dropped. A command substitution would lose the NULs, so
# the runner's output is saved to a file and compared with cmp.
run_runner STUB_MODE=nul_listing
expect_exit 1
expect_no_text "Binary file"
listing="$out/nul_listing.actual"
expected="$out/nul_listing.expected"
LC_ALL=C sed -n '/^RUNNER FAIL .*script error line/,$p' "$OUT" | tail -n +2 > "$listing"
printf '  SCRIPT ERROR: stub nul one\n     at: stub\0_a (res://stub.gd:1)\n  Parse Error: stub nul two\n     at: stub\0_b (res://stub.gd:2)\n' > "$expected"
if ! cmp -s "$listing" "$expected"; then
    problem "listing differs from the four expected lines (od -c: actual / expected follow)"
    od -c "$listing" | head -n 12 | sed 's/^/    actual   | /'
    od -c "$expected" | head -n 12 | sed 's/^/    expected | /'
fi
finish "nul_listing: no 'Binary file', listing equals four literal lines (NULs kept), exit 1"

# 0xFF at the end of a valid result line, in a UTF-8 locale: the runner still reads the result.
# This guards the result-line reads as a whole. It does not single out the TD-010 change to the
# second grep (LC_ALL=C grep -a -oE): with -o grep prints only the matched text, which is plain
# ASCII, so even the old pattern (no -a) extracts the result here (GNU grep 3.0 and 3.11 alike),
# and a byte inside the match defeats the first grep too. That change is for consistency only.
run_runner STUB_MODE=ff_result MIN_CHECKS=2 LC_ALL=C.UTF-8
expect_exit 0; expect_no_text "RUNNER FAIL"
finish "ff_result under LC_ALL=C.UTF-8, MIN_CHECKS=2: runner reads the result line, exit 0"

# --- cleanliness and time ---------------------------------------------------------------------
if [ -z "$(ls -A "$scratch")" ]; then
    passed=$((passed + 1)); echo "  PASS: the runner's scratch TMPDIR is empty after all cases (temp logs removed)"
else
    failed=$((failed + 1)); echo "  FAIL: the runner's scratch TMPDIR still holds: $(ls -A "$scratch" | tr '\n' ' ')"
fi
elapsed=$((SECONDS - start_all))
if [ "$elapsed" -lt 90 ]; then
    passed=$((passed + 1)); echo "  PASS: the self-test finished in $elapsed s (limit 90 s)"
else
    failed=$((failed + 1)); echo "  FAIL: the self-test took $elapsed s (limit 90 s)"
fi

echo "RUNNER SELFTEST RESULT: $passed passed, $failed failed"
[ "$failed" -eq 0 ]
