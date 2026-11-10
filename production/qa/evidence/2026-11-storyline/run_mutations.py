"""Run the storyline-axes checker on the real GDD and on mutated copies; write one log per run.

Design review round 2 (2026-11-10). Every mutation must make the checker FAIL; the real GDD must PASS.
Mutated copies go to <scratch_dir>/mutations (outside the repo); logs go next to this script.

Usage: python -I -B run_mutations.py <repo_root> <scratch_dir>
"""
import subprocess
import sys
from pathlib import Path

sys.stdout.reconfigure(encoding="utf-8")
root = Path(sys.argv[1])
scratch = Path(sys.argv[2]) / "mutations"
scratch.mkdir(parents=True, exist_ok=True)
evidence = root / "production/qa/evidence/2026-11-storyline"
gdd_path = root / "design/gdd/storyline-axes.md"
gdd = gdd_path.read_text(encoding="utf-8")

COMBO_ALL = "Elara, Seraphina, Lyra, Kaelthas |"
MUTATIONS = {
    # --- the eight from revision 1, re-run against the hardened checker
    "missing_heading": [("## Tuning Knobs", "## Tuning Values")],
    "wrong_count": [("`valid_count: 24`", "`valid_count: 25`")],
    "duplicate_id": [("| SL-YOU-HEARTH-CHOOSE | YOU | HEARTH | CHOOSE |", "| SL-YOU-HEARTH-RELEASE | YOU | HEARTH | CHOOSE |")],
    "deleted_row": [("| SL-SHARED-ARCHIVE-CHOOSE | SHARED | ARCHIVE | CHOOSE | valid | BOUND | — | PRODUCTION_MASTER_2.1.md:10187 | Elara, Seraphina, Lyra, Kaelthas |\n", "")],
    "wrong_invalid": [("| SL-YOU-HEARTH-RESTORE | YOU | HEARTH | RESTORE | invalid | — | R1 |", "| SL-YOU-HEARTH-RESTORE | YOU | HEARTH | RESTORE | valid | SOLE | — |")],
    "bogus_flag": [("| act1_report_command | faction:CONTINUITY | + | until:lock:faction | PRODUCTION_MASTER_2.1.md:2858 |\n",
                    "| act1_report_command | faction:CONTINUITY | + | until:lock:faction | PRODUCTION_MASTER_2.1.md:2858 |\n| ch1_bogus_flag | faction:HEARTH | + | until:lock:faction | PRODUCTION_MASTER_2.1.md:2856 |\n")],
    "dropped_arc": [("| 07 | Things Lyra Forgot | deleted:* | faction:ARCHIVE | 1.0 | 3619 |\n", "")],
    "wrong_overturn": [("| act1_report_local | faction:HEARTH | + | until:lock:faction |", "| act1_report_local | faction:HEARTH | + | no |")],
    # --- review round 2 (qa-lead M1-M3 and the other passing edits it listed), plus one per new check
    "m1_formula_invalid_set": [("(NONE, CONTINUITY, RELEASE) }", "(YOU, HEARTH, RELEASE) }")],
    "m2_rule_label_swap": [("| R1 | YOU + HEARTH + RESTORE |", "| R2 | YOU + HEARTH + RESTORE |"),
                           ("| R2 | NONE + ARCHIVE + RELEASE |", "| R1 | NONE + ARCHIVE + RELEASE |"),
                           ("| invalid | — | R1 |", "| invalid | — | R2x |"),
                           ("| invalid | — | R2 |", "| invalid | — | R1 |"),
                           ("| invalid | — | R2x |", "| invalid | — | R2 |")],
    "m3_seed_direction_flip": [("| act1_report_archive | faction:ARCHIVE | + |", "| act1_report_archive | faction:ARCHIVE | − |")],
    "m3_seed_retarget": [("| act1_report_local | faction:HEARTH | + |", "| act1_report_local | faction:ARCHIVE | + |")],
    "valid_source_pm1": [("PRODUCTION_MASTER_2.1.md:9071 |", "PRODUCTION_MASTER_2.1.md:1 |")],
    "arc_pm_line_swap": [("| 1.0 | 1904 |", "| 1.0 | 1953x |"), ("| 1.0 | 1953 |", "| 1.0 | 1904 |"), ("| 1.0 | 1953x |", "| 1.0 | 1953 |")],
    "secret_wrong_rule": [("transforms R1 / YHR", "transforms R2 / YHR")],
    "companion_removed": [("| SL-NONE-HEARTH-CHOOSE | NONE | HEARTH | CHOOSE | valid | NONE_AUTH | — | PRODUCTION_MASTER_2.1.md:10745 | Elara, Seraphina, Lyra, Kaelthas |",
                           "| SL-NONE-HEARTH-CHOOSE | NONE | HEARTH | CHOOSE | valid | NONE_AUTH | — | PRODUCTION_MASTER_2.1.md:10745 | Elara, Seraphina, Lyra |")],
    "rule_text_wrong": [('"Hearth will not endorse unilateral compulsory restoration."', '"Hearth will not endorse unilateral voluntary restoration."')],
    "prereq_dropped": [("`WITNESS_SEATS`, `SEVEN_WITNESSES_AVAILABLE` (PM:11215-11218)", "`SEVEN_WITNESSES_AVAILABLE` (PM:11215-11218)")],
    "signature_timing": [("storyline_id(A, F, D, I):", "storyline_id(A, F, D, I, timing):")],
    "composer_no_unset": [("| authority | enum | UNSET, YOU, SHARED, NONE |", "| authority | enum | YOU, SHARED, NONE |")],
    "family_split_prose": [("(SOLE 8, BOUND 9, NONE_AUTH 7)", "(SOLE 9, BOUND 9, NONE_AUTH 6)")],
    "reachable_wrong": [("`reachable_1_0: 25`", "`reachable_1_0: 27`")],
    "timing_direction": [("| act1_pace_early | timing | 0 |", "| act1_pace_early | timing | + |")],
    "stale_s_equals_t": [("if I and enabled(T) and prereqs_met(T)", "if S = T and enabled(T) and prereqs_met(T)")],
}


def run(label: str, gdd_file: Path, expect: str, log: Path) -> str:
    cmd = [sys.executable, "-I", "-B", "check_storyline_axes.py", "--gdd", str(gdd_file)]
    proc = subprocess.run(cmd, cwd=evidence, capture_output=True, text=True, encoding="utf-8")
    log.write_text(f"# {label} (expected {expect})\n$ python -I -B check_storyline_axes.py --gdd {gdd_file}\n"
                   f"{proc.stdout}{proc.stderr}exit code: {proc.returncode}\n", encoding="utf-8", newline="\n")
    got = "PASS" if proc.returncode == 0 else "FAIL" if proc.returncode == 1 else f"ERROR({proc.returncode})"
    last = [l for l in proc.stdout.splitlines() if l.startswith("FAIL ")]
    print(f"{label:28} expected {expect:4} got {got:5} {'OK ' if got == expect else 'BAD'} {last[0] if last else ''}")
    return got


bad = 0
bad += run("Real GDD and Story Bible", gdd_path, "PASS", evidence / "check_pass.log") != "PASS"
for name, edits in MUTATIONS.items():
    text = gdd
    for old, new in edits:
        if text.count(old) != 1:
            print(f"{name}: edit target occurs {text.count(old)} times, not 1: {old[:70]!r}")
            bad += 1
            break
        text = text.replace(old, new)
    else:
        path = scratch / f"storyline-axes.{name}.md"
        path.write_text(text, encoding="utf-8")
        bad += run(f"Mutation '{name}' on a temp copy", path, "FAIL", evidence / f"mutation_{name}.log") != "FAIL"
print(f"\n{len(MUTATIONS)} mutations; {bad} unexpected results")
sys.exit(1 if bad else 0)
