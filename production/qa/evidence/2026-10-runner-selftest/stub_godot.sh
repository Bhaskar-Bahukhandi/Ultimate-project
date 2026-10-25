#!/usr/bin/env bash
# Stand-in for the Godot executable, used only by tests/runner_selftest/test_runners.sh
# (Y1-P0-TD-010). tests/run_tests.sh calls it as
#   stub_godot.sh --headless --path <project> --script <script>
# and the arguments are ignored. No engine is started.
#
# Environment:
#   STUB_MODE    what to print or do (default: pass), see the case list below
#   STUB_EXIT    exit code after printing (default 0)
#   STUB_MARKER  if set, this file is touched first, so a case can tell whether the
#                runner reached the executable at all
#   STUB_COUNT   passed-check count printed by the "counted" mode
set -u
mode="${STUB_MODE:-pass}"
if [ -n "${STUB_MARKER:-}" ]; then
    touch "$STUB_MARKER"
fi

case "$mode" in
    pass)
        echo "STUB RESULT: 2 passed, 0 failed"
        ;;
    script_errors)
        echo "SCRIPT ERROR: stub failure one"
        echo "   at: stub_a (res://stub.gd:1)"
        echo "Parse Error: stub failure two"
        echo "   at: stub_b (res://stub.gd:2)"
        echo "STUB RESULT: 2 passed, 0 failed"
        ;;
    two_results)
        echo "A RESULT: 1 passed, 0 failed"
        echo "B RESULT: 5 passed, 0 failed"
        ;;
    two_results_reversed)
        echo "B RESULT: 5 passed, 0 failed"
        echo "A RESULT: 1 passed, 0 failed"
        ;;
    no_result)
        echo "stub finished without a result line"
        ;;
    loadall)
        echo "LOADALL ok=7 bad=0"
        ;;
    counted)
        # A suite that ran STUB_COUNT checks (the stale-min_checks warning cases).
        echo "STUB RESULT: ${STUB_COUNT:-0} passed, 0 failed"
        ;;
    sleep)
        exec sleep 20
        ;;
    result_then_sleep)
        # A suite that reported its checks and then hung before quit().
        echo "STUB RESULT: 50 passed, 0 failed"
        exec sleep 20
        ;;
    ignore_term)
        # No exec: the trap has to stay in this shell. An ignored TERM is inherited by sleep.
        trap '' TERM
        sleep 20
        ;;
    selfkill)
        sleep 1
        kill -9 $$
        ;;
    nul_listing)
        # NUL bytes inside the lines that follow a SCRIPT ERROR / Parse Error line (the -A1
        # context). The filler line makes grep print a "--" group separator between the two.
        printf 'SCRIPT ERROR: stub nul one\n'
        printf '   at: stub\0_a (res://stub.gd:1)\n'
        printf 'filler line\n'
        printf 'Parse Error: stub nul two\n'
        printf '   at: stub\0_b (res://stub.gd:2)\n'
        echo "STUB RESULT: 2 passed, 0 failed"
        ;;
    ff_result)
        # A valid result line followed by a non-UTF-8 byte (0xFF) at its end. The runner's end
        # anchor is open, so the line still counts; a UTF-8 grep without -a calls the log binary.
        printf 'FF RESULT: 2 passed, 0 failed\377\n'
        ;;
    *)
        echo "stub_godot.sh: unknown STUB_MODE '$mode'" >&2
        exit 99
        ;;
esac
exit "${STUB_EXIT:-0}"
