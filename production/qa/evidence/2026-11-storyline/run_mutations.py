"""Run the storyline-axes checker on the real GDD and on mutated copies; write one log per run.

Design review rounds 2 and 3 (2026-11-10). Every mutation must make the checker FAIL; the real GDD must PASS.
Mutated copies go to <scratch_dir>/mutations (outside the repo); logs go next to this script.

Usage: python -I -B run_mutations.py <repo_root> <scratch_dir> [--gdd PATH]
"""
import argparse
import subprocess
import sys
from pathlib import Path

sys.stdout.reconfigure(encoding="utf-8")
parser = argparse.ArgumentParser()
parser.add_argument("root", type=Path)
parser.add_argument("scratch", type=Path)
parser.add_argument("--gdd", type=Path, default=None, help="GDD to test (default: <root>/design/gdd/storyline-axes.md)")
args = parser.parse_args()
root = args.root
scratch = args.scratch / "mutations"
scratch.mkdir(parents=True, exist_ok=True)
evidence = Path(__file__).resolve().parent
gdd_path = args.gdd or root / "design/gdd/storyline-axes.md"
bible_path = root / "AethelgardPrototype/story/STORY_BIBLE.md"
gdd = gdd_path.read_text(encoding="utf-8")

ALL4 = "Elara, Seraphina, Lyra, Kaelthas |"
MUTATIONS = {
    # --- the eight from revision 1
    "missing_heading": [("## Tuning Knobs", "## Tuning Values")],
    "wrong_count": [("`valid_count: 24`", "`valid_count: 25`")],
    "duplicate_id": [("| SL-YOU-HEARTH-CHOOSE | YOU | HEARTH | CHOOSE |", "| SL-YOU-HEARTH-RELEASE | YOU | HEARTH | CHOOSE |")],
    "deleted_row": [("| SL-SHARED-ARCHIVE-CHOOSE | SHARED | ARCHIVE | CHOOSE | valid | BOUND | — | PRODUCTION_MASTER_2.1.md:10187 | PRODUCTION_MASTER_2.1.md:10196 | " + ALL4 + "\n", "")],
    "wrong_invalid": [("| SL-YOU-HEARTH-RESTORE | YOU | HEARTH | RESTORE | invalid | — | R1 |", "| SL-YOU-HEARTH-RESTORE | YOU | HEARTH | RESTORE | valid | SOLE | — |")],
    "bogus_flag": [("| act1_report_command | faction:CONTINUITY | + | until:lock:faction | PRODUCTION_MASTER_2.1.md:2858 |\n",
                    "| act1_report_command | faction:CONTINUITY | + | until:lock:faction | PRODUCTION_MASTER_2.1.md:2858 |\n| ch1_bogus_flag | faction:HEARTH | + | until:lock:faction | PRODUCTION_MASTER_2.1.md:2856 |\n")],
    "dropped_arc": [("| 07 | Things Lyra Forgot | deleted:* | faction:ARCHIVE | 1.0 | 3619 |\n", "")],
    "wrong_overturn": [("| act1_report_local | faction:HEARTH | + | until:lock:faction |", "| act1_report_local | faction:HEARTH | + | no |")],
    # --- review round 2
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
    "companion_removed": [("| SL-NONE-HEARTH-CHOOSE | NONE | HEARTH | CHOOSE | valid | NONE_AUTH | — | PRODUCTION_MASTER_2.1.md:10745 | PRODUCTION_MASTER_2.1.md:10754 | " + ALL4,
                           "| SL-NONE-HEARTH-CHOOSE | NONE | HEARTH | CHOOSE | valid | NONE_AUTH | — | PRODUCTION_MASTER_2.1.md:10745 | PRODUCTION_MASTER_2.1.md:10754 | Elara, Seraphina, Lyra |")],
    "rule_text_wrong": [('"Hearth will not endorse unilateral compulsory restoration."', '"Hearth will not endorse unilateral voluntary restoration."')],
    "prereq_dropped": [("`OLD_WITNESS_SIGNATURE`, `WITNESS_SEATS` (PM:11215-11217)", "`OLD_WITNESS_SIGNATURE` (PM:11215-11217)")],
    "signature_timing": [("storyline_id(A, F, D, I):", "storyline_id(A, F, D, I, timing):")],
    "composer_no_unset": [("| authority | enum | UNSET, YOU, SHARED, NONE |", "| authority | enum | YOU, SHARED, NONE |")],
    "family_split_prose": [("(SOLE 8, BOUND 9, NONE_AUTH 7)", "(SOLE 9, BOUND 9, NONE_AUTH 6)")],
    "reachable_wrong": [("`reachable_1_0: 25`", "`reachable_1_0: 27`")],
    "timing_direction": [("| act1_pace_early | timing | 0 |", "| act1_pace_early | timing | + |")],
    "stale_s_equals_t": [("if I and enabled(T) and prereqs_met(T)", "if S = T and enabled(T) and prereqs_met(T)")],
    # --- review round 3 (qa-lead: transform map, family map, timing in the formula body, prose numbers, deleted
    #     Core Rules) and one per new check (danger column, unlock knob, lifecycle tables, runtime-AC tags)
    "r3_transform_map_swap": [("{ R1 → WITNESS, R2 → CROWNLESS, R3 → FIRSTWAKE }", "{ R1 → WITNESS, R2 → FIRSTWAKE, R3 → CROWNLESS }")],
    "r3_family_map_rule": [("(YOU → SOLE, SHARED → BOUND, NONE → NONE_AUTH)", "(YOU → SOLE, SHARED → NONE_AUTH, NONE → BOUND)")],
    "r3_family_map_formula": [("{ YOU → SOLE, SHARED → BOUND, NONE → NONE_AUTH }[A]", "{ YOU → BOUND, SHARED → SOLE, NONE → NONE_AUTH }[A]")],
    "r3_consent_family": [("SL-SECRET-WITNESS                          → CONSENT", "SL-SECRET-WITNESS                          → BOUND")],
    "r3_timing_in_body": [("    if A, F or D is UNSET                        → PENDING", "    if A, F or D is UNSET or act1_pace_late      → PENDING")],
    "r3_companion_in_body": [("    otherwise                                    → CRISIS ", "    if no companion present                      → CRISIS\n    otherwise                                    → CRISIS ")],
    "r3_counts_false_chain": [("valid_count        = 27 − 3 = 24", "valid_count        = 27 − 3 = 25")],
    "r3_counts_wrong_value": [("renegotiations_valid = 18 − 2 = 16", "renegotiations_valid = 18 − 1 = 17")],
    "r3_counts_line_dropped": [("family_BOUND       = 9\n", "")],
    "r3_deleted_core_rule_3": [("3. **Lock scenes resolve, clean or negotiated.** ", "")],
    "r3_deleted_core_rule_8": [("8. **A valid row is held to its word.** ", "")],
    "r3_core_rule_retitled": [("6. **Renegotiation.**", "6. **Revision.**")],
    "r3_state_renamed": [("| Fixed | FIXED |", "| Fixed | FIX |")],
    "r3_transition_unknown_state": [("| T12 | FIXED | execution confirmed | — | FINAL | — |", "| T12 | FIXED | execution confirmed | — | DONE | — |")],
    "r3_transition_dropped": [("| T9 | LEANING or PARTLY_LOCKED | Root of Heaven entry, any path | — | unchanged | turned back in the fiction |\n", "")],
    "r3_composer_state_vocab": [("| storyline_state | enum | LEANING, PARTLY_LOCKED, CRISIS, VALIDATED, FIXED, FINAL |", "| storyline_state | enum | LEANING, PARTLY_LOCKED, CRISIS, VALIDATED, FIXED |")],
    "r3_composer_lock_negotiated_vocab": [("| lock_negotiated | set | faction, authority, deleted |", "| lock_negotiated | set | faction, authority |")],
    "r3_composer_field_dropped": [("| storyline_id | string | a storyline ID, or empty while nothing is stored | T3, T5, T7 store it; T11 replaces it; nothing else |\n", "")],
    "r3_danger_wrong_line": [("PRODUCTION_MASTER_2.1.md:9080 |", "PRODUCTION_MASTER_2.1.md:9081 |")],
    "r3_danger_on_invalid": [("| PRODUCTION_MASTER_2.1.md:715 | — |", "| PRODUCTION_MASTER_2.1.md:715 | PRODUCTION_MASTER_2.1.md:9080 |")],
    "r3_unlock_flag_wrong": [("WITNESS: `SEVEN_WITNESSES_AVAILABLE` (PM:11218)", "WITNESS: `WITNESS_SEATS` (PM:11218)")],
    "r3_prereq_overlap": [("CROWNLESS: `CROWN_COORDINATES`,", "CROWNLESS: `WITNESS_SEATS`, `CROWN_COORDINATES`,")],
    "r3_ac_blocked_missing": [("with the default knobs it is empty. *Blocked by:* Y2-PP-T17, Y1-P1-T03.", "with the default knobs it is empty.")],
    "r3_ac_blocked_unknown": [("`storyline_id()` is `SL-A-F-D`. *Blocked by:* Y2-PP-T17.", "`storyline_id()` is `SL-A-F-D`. *Blocked by:* Y9-XX-T99.")],
    "r3_ac_unknown_observable": [("`crisis_offers()` is empty and", "`offers_now()` is empty and")],
    "r3_ac_number_gap": [("21. Boot validation", "22. Boot validation")],
    "r3_stale_secret_invoked": [("| I | bool | true, false | `secret_unlock_flag[T]` is set;", "| I | bool | true, false | `secret_invoked` is set;")],
}


def run(label: str, gdd_file: Path, expect: str, log: Path) -> str:
    cmd = [sys.executable, "-I", "-B", "check_storyline_axes.py", "--gdd", str(gdd_file), "--root", str(root),
           "--bible", str(bible_path)]
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
