#!/usr/bin/env bash
# Runs a headless test/probe script with an isolated user:// directory (Linux/macOS
# counterpart of run_phase0_tests.ps1), so real save files are never touched.
# A suite fails on a non-zero exit OR on any SCRIPT ERROR / Parse Error line in its
# output (TD-003): a runtime script error aborts the rest of a test function while
# Godot still exits with the code the script chose. The runner then prints
# "RUNNER FAIL <script>: <N> script error line(s)" with the matching lines (plus a
# ::error:: annotation under GitHub Actions), and exits 1 (or keeps Godot's own
# non-zero code).
# Usage (from AethelgardPrototype/):
#   GODOT=/path/to/godot tests/run_tests.sh                       # Phase 0 suite
#   GODOT=/path/to/godot tests/run_tests.sh res://tests/integration/project/load_all_test.gd
set -euo pipefail
script="${1:-res://tests/integration/playthrough/phase0_blockers_test.gd}"
godot="${GODOT:-godot}"
project="$(cd "$(dirname "$0")/.." && pwd)"

# Tests check for this marker in OS.get_user_data_dir() and refuse to run without it.
isolated="$(mktemp -d "${TMPDIR:-/tmp}/aeth_phase0_test_XXXXXX")"
log="$(mktemp "${TMPDIR:-/tmp}/aeth_test_log_XXXXXX")"
trap 'rm -rf "$isolated" "$log"' EXIT

# Godot resolves user:// under $XDG_DATA_HOME on Linux. Keep a copy of the output in
# $log for the script-error scan; PIPESTATUS[0] is Godot's own exit code.
set +e
XDG_DATA_HOME="$isolated" "$godot" --headless --path "$project" --script "$script" 2>&1 | tee "$log"
code=${PIPESTATUS[0]}
set -e

# grep -c exits 1 on zero matches, so guard it against set -e.
n="$(grep -cE 'SCRIPT ERROR|Parse Error' "$log" || true)"
if [ "$n" -gt 0 ]; then
    echo
    echo "RUNNER FAIL $script: $n script error line(s)"
    { grep -E -A1 'SCRIPT ERROR|Parse Error' "$log" || true; } | grep -v '^--$' | sed 's/^/  /'
    if [ "${GITHUB_ACTIONS:-}" = true ]; then
        echo "::error::RUNNER FAIL $script: $n script error line(s)"
    fi
    if [ "$code" -eq 0 ]; then code=1; fi
fi
exit "$code"
