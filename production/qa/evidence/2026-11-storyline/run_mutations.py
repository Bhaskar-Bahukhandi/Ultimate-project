"""Run the storyline checker on the real GDDs and on mutated copies; write one log per run.

Design review rounds 2-4 (2026-11-10). Every mutation must make the checker FAIL; every control must PASS; the real
documents must PASS. Mutated copies go to <scratch_dir>/mutations (outside the repo); logs go to --log-dir
(default: next to this script).

An edit is (old, new) on storyline-axes.md, or ("life", old, new) on storyline-lifecycle.md. Each ``old`` must occur
exactly once in its document.

Usage: python -I -B run_mutations.py <repo_root> <scratch_dir> [--gdd PATH] [--lifecycle PATH] [--log-dir DIR]
"""
import argparse
import subprocess
import sys
from pathlib import Path

sys.stdout.reconfigure(encoding="utf-8")
parser = argparse.ArgumentParser()
parser.add_argument("root", type=Path)
parser.add_argument("scratch", type=Path)
parser.add_argument("--gdd", type=Path, default=None, help="axes GDD (default: <root>/design/gdd/storyline-axes.md)")
parser.add_argument("--lifecycle", type=Path, default=None,
                    help="lifecycle GDD (default: <root>/design/gdd/storyline-lifecycle.md)")
parser.add_argument("--log-dir", type=Path, default=None, help="where logs go (default: next to this script)")
args = parser.parse_args()
root = args.root
scratch = args.scratch / "mutations"
scratch.mkdir(parents=True, exist_ok=True)
evidence = Path(__file__).resolve().parent
log_dir = args.log_dir or evidence
log_dir.mkdir(parents=True, exist_ok=True)
paths = {"axes": args.gdd or root / "design/gdd/storyline-axes.md",
         "life": args.lifecycle or root / "design/gdd/storyline-lifecycle.md"}
bible_path = root / "AethelgardPrototype/story/STORY_BIBLE.md"
texts = {doc: path.read_text(encoding="utf-8") for doc, path in paths.items()}

ALL4 = "Elara, Seraphina, Lyra, Kaelthas |"
L = "life"
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
    # --- review round 3 (retargeted to revision 4 where the structure moved; see README round 4)
    "r3_transform_map_swap": [("{ R1 → WITNESS, R2 → CROWNLESS, R3 → FIRSTWAKE }", "{ R1 → WITNESS, R2 → FIRSTWAKE, R3 → CROWNLESS }")],
    "r3_family_map_rule": [("(YOU → SOLE, SHARED → BOUND, NONE → NONE_AUTH)", "(YOU → SOLE, SHARED → NONE_AUTH, NONE → BOUND)")],
    "r3_family_map_formula": [("{ YOU → SOLE, SHARED → BOUND, NONE → NONE_AUTH }[A]", "{ YOU → BOUND, SHARED → SOLE, NONE → NONE_AUTH }[A]")],
    "r3_consent_family": [("SL-SECRET-WITNESS                          → CONSENT", "SL-SECRET-WITNESS                          → BOUND")],
    "r3_timing_in_body": [("    if A, F or D is UNSET                        → PENDING", "    if A, F or D is UNSET or act1_pace_late      → PENDING")],
    "r3_companion_in_body": [("    otherwise                                    → CRISIS ", "    if no companion present                      → CRISIS\n    otherwise                                    → CRISIS ")],
    "r3_counts_false_chain": [("valid_count          = 27 − 3 = 24", "valid_count          = 27 − 3 = 25")],
    "r3_counts_line_dropped": [("family_BOUND         = 9\n", "")],
    "r3_deleted_core_rule_3": [("3. **Lock scenes resolve, clean or negotiated.** ", "")],
    "r3_deleted_core_rule_8": [("7. **A valid row is held to its word.** ", "")],  # the rule is number 7 in rev 4
    "r3_core_rule_retitled": [("6. **Secret routes: signposts and invocation.**", "6. **Secret routes.**")],
    "r3_state_renamed": [("| FIXED | an ID stored, inside Root of Heaven |", "| FIX | an ID stored, inside Root of Heaven |")],
    "r3_transition_unknown_state": [(L, "| FINAL | `root_phase` FINAL |", "| DONE | `root_phase` FINAL |")],
    "r3_transition_dropped": [(L, "| T9 | DEFERRED | Root of Heaven entry, any path | — | DEFERRED | LAST_CHANCE scene; leaving returns the player outside |\n", "")],
    "r3_composer_state_vocab": [("| storyline_phase | enum | LEANING, PARTLY_LOCKED, CRISIS, DEFERRED, VALIDATED, FIXED, FINAL |", "| storyline_phase | enum | LEANING, PARTLY_LOCKED, CRISIS, DEFERRED, VALIDATED, FIXED |")],
    "r3_composer_lock_negotiated_vocab": [("| lock_negotiated | set | faction, authority, deleted |", "| lock_negotiated | set | faction, authority |")],
    "r3_composer_field_dropped": [("| storyline_id | string | a storyline ID, or empty while nothing is stored | C8-S16 on a valid row; a renegotiation (C8-S16 or the gate); a confirmed invocation; nothing else |\n", "")],
    "r3_danger_wrong_line": [("PRODUCTION_MASTER_2.1.md:9080 |", "PRODUCTION_MASTER_2.1.md:9081 |")],
    "r3_danger_on_invalid": [("| PRODUCTION_MASTER_2.1.md:715 | — |", "| PRODUCTION_MASTER_2.1.md:715 | PRODUCTION_MASTER_2.1.md:9080 |")],
    "r3_unlock_flag_wrong": [("WITNESS: `SEVEN_WITNESSES_AVAILABLE` (PM:11218)", "WITNESS: `WITNESS_SEATS` (PM:11218)")],
    "r3_prereq_overlap": [("CROWNLESS: `CROWN_COORDINATES`,", "CROWNLESS: `WITNESS_SEATS`, `CROWN_COORDINATES`,")],
    "r3_ac_blocked_missing": [("with the default knobs it is empty. *Blocked by:* Y2-PP-T17, Y1-P1-T03.", "with the default knobs it is empty.")],
    "r3_ac_blocked_unknown": [("→ NO_FAMILY. *Blocked by:* Y2-PP-T17.", "→ NO_FAMILY. *Blocked by:* Y9-XX-T99.")],
    "r3_ac_unknown_observable": [("has `axis()` UNSET", "has `axis_of()` UNSET")],
    "r3_ac_number_gap": [("12. Boot validation", "13. Boot validation")],
    # --- review round 4: the 19 QA survivors re-expressed, and one per new check
    # transitions (lifecycle)
    "r4_t4_to_validated": [(L, "| faction and authority set; the row is invalid | CRISIS |", "| faction and authority set; the row is invalid | VALIDATED |")],
    "r4_t13_to_leaning": [(L, "| the final authorization scene is playing | FINAL |", "| the final authorization scene is playing | LEANING |")],
    "r4_t7_event_changed": [(L, "the invocation is confirmed (C9-S19 or the gate)", "the invocation is confirmed (C9-S19 only)")],
    "r4_t6_guard_dropped": [(L, "| R1; WITNESS enabled; signpost OPEN | DEFERRED |", "| R1 | DEFERRED |")],
    "r4_t5_effect_dropped": [(L, "gain it; retraction recorded; ID stored", "gain it; ID stored")],
    "r4_t14_backward_added": [(L, "| `root_phase` FINAL |\n", "| `root_phase` FINAL |\n| T14 | VALIDATED | a knob changes | WITNESS disabled | CRISIS | ID cleared |\n")],
    "r4_t8_knob_guard": [(L, "| one of the six R1 offers |", "| one of the six R1 offers; WITNESS enabled |")],
    "r4_no_other_transition": [(L, "No other transition exists:", "Other transitions may exist:")],
    # Core Rules (axes)
    "r4_rule7_inverted": [("nothing offers a renegotiation, a deferral or an invocation, and the ID never changes.", "a crisis scene may still offer a renegotiation, and the ID never changes.")],
    "r4_rule7_exception_appended": [("a deferral or an invocation, and the ID never changes.", "a deferral or an invocation, and the ID never changes. A crisis scene may still offer a renegotiation.")],
    "r4_rule9_reconsideration": [("It changes no axis and no ID.", "It may offer one reconsideration of Faction or Deleted.")],
    "r4_rule9_offers_one": [("this design offers none, because", "this design offers one when a trigger holds, because")],
    "r4_rule5_scene_may_end": [("the scene does not end until the coalition holds", "the scene may end before the coalition holds")],
    "r4_rule5_offer_count": [("six for R1, five for R2 or R3", "six for R1, six for R2 or R3")],
    "r4_rule3_counts_seeds": [("The test reads only which flags are set: no count, no weight.", "The test counts the seeds set for each value.")],
    "r4_rule4_pair_swapped": [("Archive when NONE and ARCHIVE are locked (R2", "Archive when SHARED and ARCHIVE are locked (R2")],
    # composer record (axes)
    "r4_composer_authority_final_auth": [("| C8-S14 lock; a renegotiation. Never the final authorization |", "| C8-S14 lock; a renegotiation; the final authorization |")],
    "r4_composer_deferred_cleared": [("the C8-S16 deferral sets it; nothing clears it", "the C8-S16 deferral sets it; a renegotiation clears it")],
    "r4_composer_family_vocab": [("| family | enum | SOLE, BOUND, NONE_AUTH, CONSENT, RESERVED, NO_FAMILY |", "| family | enum | SOLE, BOUND, NONE_AUTH, CONSENT |")],
    "r4_composer_final_reconsidered": [("| axis_revised | set | faction, authority, deleted | a renegotiation |\n", "| axis_revised | set | faction, authority, deleted | a renegotiation |\n| final_reconsidered | bool | true, false | the final authorization |\n")],
    # Tuning Knobs (axes)
    "r4_knob_reconsideration_triggers": [("\n\nNot knobs (fixed by design)", "\n| `reconsideration_triggers` | `[boss_phase_drastic]` | empty or one trigger | whether the final authorization offers a reconsideration | PM:8791 |\n\nNot knobs (fixed by design)")],
    "r4_knob_faction_negotiation": [("\n\nNot knobs (fixed by design)", "\n| `faction_negotiation_allowed` | true | true, false | whether Faction can be renegotiated at C8-S16 | review round 3 |\n\nNot knobs (fixed by design)")],
    "r4_knob_default_flip": [("| `secret_route_enabled.WITNESS` | true |", "| `secret_route_enabled.WITNESS` | false |")],
    "r4_knob_dropped": [("| `secret_route_enabled.CROWNLESS`, `.FIRSTWAKE` | false |", "| `secret_route_enabled.CROWNLESS` | false |")],
    "r4_not_knobs_lock_pass_dropped": [("the `lock_pass` test, ", "")],
    # phase table / gate
    "r4_validated_gate_turns_back": [("| VALIDATED | an ID stored, outside Root of Heaven | open |", "| VALIDATED | an ID stored, outside Root of Heaven | turns the player back |")],
    "r4_phase_row_deleted": [("| DEFERRED | R1, `witness_deferred`, nothing stored | plays the last-chance scene |\n", "")],
    "r4_gate_outcome_wrong": [(L, "| VALIDATED | ROOT_OF_HEAVEN; `root_phase` becomes INSIDE (T11) |", "| VALIDATED | TURNED_BACK; `root_phase` becomes INSIDE (T11) |")],
    "r4_gate_t_ref_wrong": [(L, "becomes INSIDE (T11)", "becomes INSIDE (T12)")],
    # invariants, edge cases (axes)
    "r4_invariant_deleted": [("| I5 | No soft-lock under any knob value or patch: every state without a stored ID either is before the locks or offers a renegotiation that reaches a valid row | 5, 8 |\n", "")],
    "r4_invariant_rule_ref": [("| I7 | A valid row is held to its word | 7 |", "| I7 | A valid row is held to its word | 8 |")],
    "r4_edge_case_16_deleted": [("16. **A damaged record** (a debug or edited save). `SEVEN_WITNESSES_AVAILABLE` alone changes nothing: it is set\n    whenever C9-S19 plays. A record that contradicts the phase table — `secret_invoked` holding a route whose row is\n    not the record's, `secret_invoked` with no ID stored, `witness_deferred` on a row other than R1, `root_phase`\n    INSIDE or FINAL with nothing stored — is reported by SaveService as a data error on load, as for Edge Case 6.\n", "")],
    "r4_edge_case_16_item_dropped": [("`secret_invoked` with no ID stored, ", "")],
    # formula bodies (axes)
    "r4_prereqs_met_dropped": [("    if I and enabled(T) and prereqs_met(T)       →", "    if I and enabled(T)                          →")],
    "r4_not_invalid_inverted": [("    if not invalid(A, F, D)                      →", "    if invalid(A, F, D)                          →")],
    "r4_lock_pass_swapped": [("is set   → CLEAN", "is set   → @@"),
                             ("    otherwise                                                          → NEGOTIATED", "    otherwise                                                          → CLEAN"),
                             ("is set   → @@", "is set   → NEGOTIATED")],
    "r4_phase_branch_order": [("    if A, F or D is UNSET                          → PARTLY_LOCKED\n    if witness_deferred                            → DEFERRED\n",
                               "    if witness_deferred                            → DEFERRED\n    if A, F or D is UNSET                          → PARTLY_LOCKED\n")],
    "r4_family_reserved_changed": [("SL-SECRET-CROWNLESS, SL-SECRET-FIRSTWAKE   → RESERVED", "SL-SECRET-CROWNLESS, SL-SECRET-FIRSTWAKE   → NO_FAMILY")],
    "r4_invalid_not_member": [("invalid(A, F, D) = (A, F, D) ∈ {", "invalid(A, F, D) = (A, F, D) ∉ {")],
    "r4_lock_pass_example_wrong": [("HEARTH with only `ch1_knight_killed` → NEGOTIATED", "HEARTH with only `ch1_knight_killed` → CLEAN")],
    "r4_phase_example_wrong": [("OUTSIDE) → DEFERRED", "OUTSIDE) → CRISIS")],
    # counts (axes)
    "r4_counts_offers_wrong": [("renegotiation_offers = 6 + 5 + 5 = 16", "renegotiation_offers = 6 + 6 + 5 = 17")],
    "r4_counts_offers_terms": [("renegotiation_offers = 6 + 5 + 5 = 16", "renegotiation_offers = 5 + 6 + 5 = 16")],
    "r4_ac5_case_count": [("(128 cases)", "(124 cases)")],
    "r4_seed_intro_count": [("(26 flags)", "(25 flags)")],
    "r4_ac8_lifecycle_observable": [("8. `family(id)` over every id", "8. `storyline_id()` over every id")],
    # crisis offers and red lines (lifecycle)
    "r4_crisis_r2_gains_offer": [(L, "| R2 NONE-ARCHIVE-RELEASE | `revise:authority:YOU`,", "| R2 NONE-ARCHIVE-RELEASE | `revise:faction:CONTINUITY`, `revise:authority:YOU`,")],
    "r4_crisis_r1_loses_offer": [(L, "`revise:faction:CONTINUITY`, `revise:deleted:RELEASE`", "`revise:deleted:RELEASE`")],
    "r4_crisis_r3_defer": [(L, "`revise:deleted:CHOOSE` |\n\n**Retractions", "`revise:deleted:CHOOSE`; plus `defer:WITNESS` when WITNESS is enabled and its signpost is OPEN |\n\n**Retractions")],
    "r4_red_line_pair": [(L, "| NONE + ARCHIVE | Archive delegate | R2 |", "| SHARED + ARCHIVE | Archive delegate | R2 |")],
    "r4_red_line_speaker": [(L, "| NONE + CONTINUITY | Continuity delegate |", "| NONE + CONTINUITY | Archive delegate |")],
    "r4_red_line_extra_row": [(L, "| any other pair | — | — | no red line |", "| SHARED + HEARTH | Hearth delegate | R1 | no shared compulsion |\n| any other pair | — | — | no red line |")],
    "r4_retraction_beats": [(L, "16 beats", "15 beats")],
    # lifecycle formulas, sentences, record
    "r4_life_formula_invalid_dropped": [(L, "v ≠ row[axis], not invalid(row with axis = v)", "v ≠ row[axis]")],
    "r4_life_offer_count_sentence": [(L, "so 16 renegotiation offers in all", "so 17 renegotiation offers in all")],
    "r4_life_crisis_leavable": [(L, "cannot be left, skipped or saved", "can be left but not saved")],
    "r4_life_s8_reconsideration": [(L, "offers no\nreconsideration", "offers one\nreconsideration")],
    "r4_life_own_knob": [(L, "None of its own. It reads", "One of its own, `crisis_retry_limit` (default 3). It reads")],
    "r4_ng_reset_default": [(L, "`witness_deferred` → false", "`witness_deferred` → true")],
    "r4_ng_reset_field_dropped": [(L, "`secret_invoked`, `axis_revised`, `lock_negotiated` →", "`axis_revised`, `lock_negotiated` →")],
    "r4_life_number_word": [(L, "gate's LAST_CHANCE offers the six renegotiations only", "gate's LAST_CHANCE offers the five renegotiations only")],
    "r4_life_edge_case_gap": [(L, "8. **A save in DEFERRED", "9. **A save in DEFERRED")],
    "r4_life_heading": [(L, "## Tuning Knobs\n\nNone of its own", "## Knobs\n\nNone of its own")],
    # L-ACs and the Validation note (lifecycle)
    "r4_lac_no_blocked_by": [(L, "`offers()` empty. *Blocked by:* Y2-PP-T17.", "`offers()` empty.")],
    "r4_lac_unknown_observable": [(L, "makes `signpost(WITNESS)` HIDDEN", "makes `route_state(WITNESS)` HIDDEN")],
    "r4_lac_axes_observable": [(L, "after C8-S16, `storyline_phase()` VALIDATED", "after C8-S16, `phase_of()` VALIDATED")],
    "r4_lac_unknown_story": [(L, "*Blocked by:* Y2-PP-T17, NG+ design.", "*Blocked by:* Y2-PP-T99, NG+ design.")],
    "r4_lac_number_gap": [(L, "- **L-AC18 NG+ reset.**", "- **L-AC19 NG+ reset.**")],
    "r4_lac6_runs": [(L, "its offers (16 runs)", "its offers (15 runs)")],
    "r4_validation_total": [(L, "— 61 runs", "— 62 runs")],
    "r4_validation_term_consistent": [(L, "renegotiation offer (16)", "renegotiation offer (15)"), (L, "— 61 runs", "— 60 runs")],
    "r4_validation_matrix": [(L, "3 paths × 6 storable phases (18)", "3 paths × 7 storable phases (21)"), (L, "— 61 runs", "— 64 runs")],
    # stale revision-3 vocabulary
    "r4_stale_storyline_state": [(L, "(fields `authority`,", "(fields `storyline_state`, `authority`,")],
    "r4_stale_storyline_state_axes": [("implements `storyline_id`, `storyline_phase`,", "implements `storyline_id`, `storyline_state`,")],
    "r4_stale_gate_crisis": [(L, "There is no limit and no penalty.", "There is no limit and no penalty (no GATE_CRISIS).")],
}
# Controls: edits the checker must accept (expected PASS).
CONTROLS = {
    # Revision-3 vocabulary is allowed in storyline-axes.md's Open Questions (the reserved reconsideration).
    "r4_control_open_questions_vocab": [("Cut from this design (user decision 2026-11-10)",
                                         "Cut from this design, with the old `reconsideration_triggers` knob and "
                                         "`final_reconsidered` field (user decision 2026-11-10)")],
}


def run(label: str, docs: dict, expect: str, log: Path) -> str:
    cmd = [sys.executable, "-I", "-B", "check_storyline_axes.py", "--gdd", str(docs["axes"]),
           "--lifecycle", str(docs["life"]), "--root", str(root), "--bible", str(bible_path)]
    proc = subprocess.run(cmd, cwd=evidence, capture_output=True, text=True, encoding="utf-8")
    log.write_text(f"# {label} (expected {expect})\n$ python -I -B check_storyline_axes.py --gdd {docs['axes']} "
                   f"--lifecycle {docs['life']}\n{proc.stdout}{proc.stderr}exit code: {proc.returncode}\n",
                   encoding="utf-8", newline="\n")
    got = "PASS" if proc.returncode == 0 else "FAIL" if proc.returncode == 1 else f"ERROR({proc.returncode})"
    first = [line for line in proc.stdout.splitlines() if line.startswith("FAIL ")]
    print(f"{label:44} expected {expect:4} got {got:5} {'OK ' if got == expect else 'BAD'} {first[0] if first else ''}")
    return got


def mutate(name: str, edits: list) -> dict | None:
    """Apply the edits to copies of the documents; return the paths to check, or None if an edit target is bad."""
    out = dict(texts)
    for edit in edits:
        doc, old, new = edit if len(edit) == 3 else ("axes", *edit)
        if out[doc].count(old) != 1:
            print(f"{name}: edit target occurs {out[doc].count(old)} times in {doc}, not 1: {old[:70]!r}")
            return None
        out[doc] = out[doc].replace(old, new)
    docs = {}
    for doc, text in out.items():
        if text == texts[doc]:
            docs[doc] = paths[doc]
        else:
            docs[doc] = scratch / f"{paths[doc].stem}.{name}.md"
            docs[doc].write_text(text, encoding="utf-8", newline="\n")
    return docs


bad = 0
bad += run("Real GDDs and Story Bible", paths, "PASS", log_dir / "check_pass.log") != "PASS"
for group, expect in ((MUTATIONS, "FAIL"), (CONTROLS, "PASS")):
    for name, edits in group.items():
        docs = mutate(name, edits)
        if docs is None:
            bad += 1
            continue
        kind = "Mutation" if expect == "FAIL" else "Control"
        bad += run(f"{kind} '{name}'", docs, expect, log_dir / f"mutation_{name}.log") != expect
print(f"\n{len(MUTATIONS)} mutations, {len(CONTROLS)} controls; {bad} unexpected results")
sys.exit(1 if bad else 0)
