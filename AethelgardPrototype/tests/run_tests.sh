#!/usr/bin/env bash
# Runs a headless test/probe script with an isolated user:// directory (Linux/macOS
# counterpart of run_phase0_tests.ps1), so real save files are never touched.
# A suite fails on a non-zero exit OR on any SCRIPT ERROR / Parse Error line in its
# output (TD-003): a runtime script error aborts the rest of a test function while
# Godot still exits with the code the script chose. The runner then prints
# "RUNNER FAIL <script>: <N> script error line(s)" with the matching lines (plus a
# ::error:: annotation under GitHub Actions), and exits 1 (or keeps Godot's own
# non-zero code).
# Two limits per suite come from tests/suite_limits.txt (TD-007), as in run_phase0_tests.ps1:
# a time limit (GNU timeout(1) stops Godot, "RUNNER FAIL <script>: timed out after <N> s",
# exit 124) and a minimum number of checks that ran (passed + failed, from the last line
# that starts with an uppercase name and "RESULT: <N> passed, <M> failed" or
# "ok=<N> bad=<M>"). A *_test.gd under res://tests/ without an entry in that file is
# refused; any other script gets 600 s and no minimum. A minimum that has gone stale (more
# checks ran than min + max(2, ceil(min/10))) only prints "RUNNER WARN <script>: <ran> checks
# ran, suite_limits.txt minimum is <min>" (::warning:: under GitHub Actions); the exit code
# does not change (TD-010).
# tests/runner_selftest/test_runners.sh runs this script against a stub Godot (TD-010).
# Usage (from AethelgardPrototype/):
#   GODOT=/path/to/godot tests/run_tests.sh                       # Phase 0 suite
#   GODOT=/path/to/godot tests/run_tests.sh res://tests/integration/project/load_all_test.gd
#   TEST_TIMEOUT=20 MIN_CHECKS=2 GODOT=... tests/run_tests.sh <probe>   # override the file
# Environment: GODOT (executable), TEST_TIMEOUT (seconds, overrides the file's limit),
# MIN_CHECKS (overrides the file's minimum; 0 = none).
set -euo pipefail
script="${1:-res://tests/integration/playthrough/phase0_blockers_test.gd}"
godot="${GODOT:-godot}"
project="$(cd "$(dirname "$0")/.." && pwd)"

fail() {   # fail <message>: one RUNNER FAIL line (and a GitHub annotation in CI)
    echo
    echo "RUNNER FAIL $script: $1"
    if [ "${GITHUB_ACTIONS:-}" = true ]; then
        echo "::error::RUNNER FAIL $script: $1"
    fi
}

# Each line of suite_limits.txt: <res:// path> <min_checks> <timeout_seconds>; '#' starts
# a comment, and a CRLF line ending is ignored.
limits="$(awk -v s="$script" '{ gsub(/\r/, ""); sub(/#.*/, "") } $1 == s && NF >= 3 { print $2, $3; exit }' \
    "$project/tests/suite_limits.txt")"
if [ -z "$limits" ]; then
    case "$script" in
        res://tests/*_test.gd) fail "no entry in tests/suite_limits.txt"; exit 1 ;;
    esac
    limits="0 600"   # other scripts: no minimum, 600 s
fi
read -r min_checks timeout_sec <<< "$limits"
min_checks="${MIN_CHECKS:-$min_checks}"
timeout_sec="${TEST_TIMEOUT:-$timeout_sec}"
# A typo would otherwise make the numeric tests below error out and skip their check.
case "$min_checks" in
    '' | *[!0-9]*) fail "MIN_CHECKS must be a whole number, got '$min_checks'"; exit 1 ;;
esac
min_checks=$((10#$min_checks))   # a leading zero ("08") must not mean octal in $(( )) below
case "$timeout_sec" in
    '' | *[!0-9]* | 0) fail "TEST_TIMEOUT must be a whole number of seconds above 0, got '$timeout_sec'"; exit 1 ;;
esac

# A script error in the function that would call quit() leaves Godot running forever:
# GNU timeout(1) stops it (TERM, then KILL 10 s later) and exits 124 (137 after the KILL).
# Other timeouts (BSD, busybox) differ in flags and exit codes, so only coreutils counts.
watchdog=()
timeout_version="$(timeout --version 2>&1 || true)"
case "$timeout_version" in
    *coreutils*) watchdog=(timeout -k 10 "$timeout_sec") ;;
    *)
        if [ "${GITHUB_ACTIONS:-}" = true ]; then
            fail "GNU timeout(1) not found"
            exit 1
        fi
        echo "WARNING: GNU timeout(1) not found; running without a time limit" >&2
        ;;
esac

# Tests check for this marker in OS.get_user_data_dir() and refuse to run without it.
isolated="$(mktemp -d "${TMPDIR:-/tmp}/aeth_phase0_test_XXXXXX")"
log="$(mktemp "${TMPDIR:-/tmp}/aeth_test_log_XXXXXX")"
trap 'rm -rf "$isolated" "$log"' EXIT

# Godot resolves user:// under $XDG_DATA_HOME on Linux. Keep a copy of the output in
# $log for the scans below; PIPESTATUS[0] is Godot's own exit code.
start=$SECONDS
set +e
XDG_DATA_HOME="$isolated" ${watchdog[@]+"${watchdog[@]}"} "$godot" --headless --path "$project" --script "$script" 2>&1 | tee "$log"
code=${PIPESTATUS[0]}
set -e
# 124 (TERM) or 137 (KILL) is a timeout only if the limit was really reached; any other
# 137, such as an OOM kill, is Godot's own code and passes through.
timed_out=0
if [ ${#watchdog[@]} -gt 0 ] && { [ "$code" -eq 124 ] || [ "$code" -eq 137 ]; } \
    && [ $((SECONDS - start)) -ge "$timeout_sec" ]; then
    timed_out=1
    fail "timed out after $timeout_sec s"
fi

# -a and LC_ALL=C, as for the result-line scan below: a NUL or non-UTF-8 byte would make grep
# print "Binary file ... matches" instead of the lines, and the filter grep reads the listing,
# which can carry that byte too; sed runs under LC_ALL=C as well (BSD sed can reject a non-UTF-8
# byte). The filter stays grep -v '^--$' (not GNU-only --no-group-separator) for macOS grep.
# grep -c exits 1 on zero matches, so guard it against set -e.
n="$(LC_ALL=C grep -a -cE 'SCRIPT ERROR|Parse Error' "$log" || true)"
if [ "$n" -gt 0 ]; then
    echo
    echo "RUNNER FAIL $script: $n script error line(s)"
    { LC_ALL=C grep -a -E -A1 'SCRIPT ERROR|Parse Error' "$log" || true; } | LC_ALL=C grep -a -v '^--$' | LC_ALL=C sed 's/^/  /'
    if [ "${GITHUB_ACTIONS:-}" = true ]; then
        echo "::error::RUNNER FAIL $script: $n script error line(s)"
    fi
    if [ "$code" -eq 0 ]; then code=1; fi
fi

# A suite that timed out has no result line; the timeout is the reason, not the count.
if [ "$min_checks" -gt 0 ] && [ "$timed_out" -eq 0 ]; then
    # A result line starts at column 0 with an uppercase name ("LAYOUT RESULT: 6 passed, 0 failed",
    # "LOADALL ok=204 bad=0"), so a check description that quotes one is never counted; the last
    # such line wins, and a lowercase "result:" is not one. The end is not anchored (a trailing CR).
    # Only the "RESULT: N passed, M failed" / "ok=N bad=M" part is kept, so digits in the name
    # (TD007) are not summed.
    # -a and LC_ALL=C: a stray non-UTF-8 byte must not turn the log "binary" (grep would print
    # "Binary file matches" instead of the line) or change what [A-Z] means.
    result_line="$({ LC_ALL=C grep -a -E '^[A-Z0-9][A-Z0-9 ]* (RESULT: [0-9]+ passed, [0-9]+ failed|ok=[0-9]+ bad=[0-9]+)' "$log" || true; } | tail -n 1)"
    result="$(echo "$result_line" | { LC_ALL=C grep -a -oE 'RESULT: [0-9]+ passed, [0-9]+ failed|ok=[0-9]+ bad=[0-9]+' || true; } | tail -n 1)"
    if [ -z "$result" ]; then
        fail "no result line (expected at least $min_checks checks to run)"
        if [ "$code" -eq 0 ]; then code=1; fi
    else
        # Failed checks count as run: a failure already fails the suite through Godot's exit code.
        ran="$(echo "$result" | sed -E 's/[^0-9]+/ /g' | awk '{ print $1 + $2 }')"
        if [ "$ran" -lt "$min_checks" ]; then
            fail "$ran check(s) ran, expected at least $min_checks"
            if [ "$code" -eq 0 ]; then code=1; fi
        else
            # A minimum far below the real count no longer guards anything: warn (never fail)
            # when ran > min + max(2, ceil(min / 10)), so the entry gets updated (TD-010).
            slack=$(( (min_checks + 9) / 10 ))
            if [ "$slack" -lt 2 ]; then slack=2; fi
            if [ "$ran" -gt $((min_checks + slack)) ]; then
                warn="RUNNER WARN $script: $ran checks ran, suite_limits.txt minimum is $min_checks"
                if [ "${GITHUB_ACTIONS:-}" = true ]; then warn="::warning::$warn"; fi
                echo "$warn"
            fi
        fi
    fi
fi

if [ "$timed_out" -eq 1 ]; then code=124; fi
exit "$code"
