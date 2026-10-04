#!/usr/bin/env bash
# Runs a headless test/probe script with an isolated user:// directory (Linux/macOS
# counterpart of run_phase0_tests.ps1), so real save files are never touched.
# Usage (from AethelgardPrototype/):
#   GODOT=/path/to/godot tests/run_tests.sh                       # Phase 0 suite
#   GODOT=/path/to/godot tests/run_tests.sh res://tests/load_all_test.gd
set -euo pipefail
script="${1:-res://tests/phase0_blockers_test.gd}"
godot="${GODOT:-godot}"
project="$(cd "$(dirname "$0")/.." && pwd)"

# Tests check for this marker in OS.get_user_data_dir() and refuse to run without it.
isolated="$(mktemp -d "${TMPDIR:-/tmp}/aeth_phase0_test_XXXXXX")"
trap 'rm -rf "$isolated"' EXIT

# Godot resolves user:// under $XDG_DATA_HOME on Linux.
XDG_DATA_HOME="$isolated" "$godot" --headless --path "$project" --script "$script"
