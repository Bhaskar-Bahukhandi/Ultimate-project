"""Run the storyline checker on the real GDDs and on mutated copies; write one log per run.

Design review rounds 2-6 (2026-11-10; round 5 is also the lifecycle document's round 1, round 6 its round 2). Every mutation must make the checker FAIL; every control must PASS; the real
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
    "r3_composer_state_vocab": [("| storyline_phase | enum | LEANING, PARTLY_LOCKED, CRISIS, DEFERRED, VALIDATED, FIXED, FINAL, DAMAGED |", "| storyline_phase | enum | LEANING, PARTLY_LOCKED, CRISIS, DEFERRED, VALIDATED, FIXED, DAMAGED |")],
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
    "r4_t13_to_leaning": [(L, "| the final authorization scene is playing; `witness_mandate` is not FAILED | FINAL |", "| the final authorization scene is playing; `witness_mandate` is not FAILED | LEANING |")],
    "r4_t7_event_changed": [(L, "the invocation is confirmed (C9-S19 or the gate)", "the invocation is confirmed (C9-S19 only)")],
    "r4_t6_guard_dropped": [(L, "| R1; WITNESS enabled; signpost OPEN; the four disclosures shown | DEFERRED |", "| R1 | DEFERRED |")],
    "r4_t5_effect_dropped": [(L, "gain it; retraction recorded; retraction beat played; ID stored", "gain it; ID stored")],
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
    "r4_edge_case_16_deleted": [("16. **A damaged record** (a debug or edited save, or one made before these fields existed; play never writes one).\n", "")],
    "r4_edge_case_16_item_dropped": [("    - D3 `secret_invoked` with no ID stored\n", "")],
    # formula bodies (axes)
    "r4_prereqs_met_dropped": [("    if I and enabled(T) and prereqs_met(T)       →", "    if I and enabled(T)                          →")],
    "r4_not_invalid_inverted": [("    if not invalid(A, F, D)                      →", "    if invalid(A, F, D)                          →")],
    "r4_lock_pass_swapped": [("is set   → CLEAN", "is set   → @@"),
                             ("    otherwise                                                          → NEGOTIATED", "    otherwise                                                          → CLEAN"),
                             ("is set   → @@", "is set   → NEGOTIATED")],
    "r4_phase_branch_order": [("    if A, F or D is UNSET                              → PARTLY_LOCKED\n    if witness_deferred                                → DEFERRED\n", "    if witness_deferred                                → DEFERRED\n    if A, F or D is UNSET                              → PARTLY_LOCKED\n")],
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
    "r4_crisis_r3_defer": [(L, "`revise:deleted:CHOOSE` |\n\nA Faction offer", "`revise:deleted:CHOOSE`; plus `defer:WITNESS` when WITNESS is enabled and its signpost is OPEN |\n\nA Faction offer")],
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
    "r4_ng_reset_field_dropped": [(L, "OUTSIDE; `secret_invoked`, `axis_revised`, `lock_negotiated`,\n", "OUTSIDE; `axis_revised`, `lock_negotiated`,\n")],
    "r4_life_number_word": [(L, "LAST_CHANCE offers the six renegotiations only (I5, I6)", "LAST_CHANCE offers the five renegotiations only (I5, I6)")],
    "r4_life_edge_case_gap": [(L, "8. **A save in DEFERRED", "9. **A save in DEFERRED")],
    "r4_life_heading": [(L, "## Tuning Knobs\n\nNone of its own", "## Knobs\n\nNone of its own")],
    # L-ACs and the Validation note (lifecycle)
    "r4_lac_no_blocked_by": [(L, "exactly the six renegotiations. *Blocked by:* Y2-PP-T17, Y1-P1-T03.", "exactly the six renegotiations.")],
    "r4_lac_unknown_observable": [(L, "makes `signpost(WITNESS)` CLOSED", "makes `route_state(WITNESS)` CLOSED")],
    "r4_lac_axes_observable": [(L, "after C8-S16, `storyline_phase()` VALIDATED", "after C8-S16, `phase_of()` VALIDATED")],
    "r4_lac_unknown_story": [(L, "offer prerequisite. *Blocked by:* Y2-PP-T17.", "offer prerequisite. *Blocked by:* Y2-PP-T99.")],
    "r4_lac_number_gap": [(L, "- **L-AC18 NG+ reset.**", "- **L-AC19 NG+ reset.**")],
    "r4_lac6_runs": [(L, "its offers (16 runs)", "its offers (15 runs)")],
    "r4_validation_total": [(L, "— 60 runs", "— 61 runs")],
    "r4_validation_term_consistent": [(L, "renegotiation offer at C8-S16 (16)", "renegotiation offer at C8-S16 (15)"), (L, "— 60 runs", "— 59 runs")],
    "r4_validation_matrix": [(L, "2 counted paths × 6 storable phases (12)", "3 counted paths × 6 storable phases (18)"), (L, "— 60 runs", "— 66 runs")],
    # stale revision-3 vocabulary
    "r4_stale_storyline_state": [(L, "(fields `authority`,", "(fields `storyline_state`, `authority`,")],
    "r4_stale_storyline_state_axes": [("implements `storyline_id`, `storyline_phase`,", "implements `storyline_id`, `storyline_state`,")],
    "r4_stale_gate_crisis": [(L, "There is no limit and no penalty.", "There is no limit and no penalty (no GATE_CRISIS).")],
    # --- review round 5 (axes) + round 1 (lifecycle): one per new pin or derived check
    # axes: composer record, Edge Case 16, protected touchpoints, Core Rules 3/6/10, ACs
    "r5_composer_mandate_vocab": [("| witness_mandate | enum | UNDECIDED, MET, FAILED |", "| witness_mandate | enum | MET, FAILED |")],
    "r5_composer_retraction_log_dropped": [("| retraction_log | list | entries {axis, old, new, withdrawn_item, scene}, oldest first | every renegotiation; a confirmed invocation |\n", "")],
    "r5_ec16_old_item": [("    - D4 `witness_deferred` with an UNSET axis, or with nothing stored on a row other than R1", "    - D4 `witness_deferred` on a row other than R1")],
    "r5_ec16_t8_history_dropped": [("is the history of a deferral broken at\n    the gate, not damage.", "is damaged too.")],
    "r5_ec16_rewrites_id": [("The check compares and never rewrites the stored ID", "The check compares and then rewrites the stored ID")],
    "r5_protected_area_dropped": [("| NG+ | the reset of the record and the axis, secret and unlock flags | Edge Case 9; lifecycle NG+ reset |\n", "")],
    "r5_protected_area_bogus": [("| collision, hitboxes | none | — |", "| collision, hitboxes, lighting | none | — |")],
    "r5_rule10_c10s15_flag_gate": [("and vote at C10-S15, which plays\n    only on `SL-SECRET-WITNESS`", "and vote at C10-S15, which plays\n    when `SEVEN_WITNESSES_AVAILABLE` is set")],
    "r5_rule10_threshold_cannot_fail": [("The vote can fall short of the\n    threshold", "The vote cannot fall short of the\n    threshold")],
    "r5_rule6_chapter10_flag": [("plays only when the stored ID is `SL-SECRET-T`.", "plays when the unlock flag is set.")],
    "r5_rule3_sole_dissent_optional": [("the ending plays `sole_dissent`", "the ending may play `sole_dissent`")],
    "r5_ac_number_gap": [("15. Pillar P5 tracking", "16. Pillar P5 tracking")],
    "r5_ac14_unknown_observable": [("`scene_variants(id)` holds at least 3", "`scenes(id)` holds at least 3")],
    # lifecycle: transitions, formulas, pinned sentences, derived beats, L-ACs, Validation note
    "r5_t14_dropped": [(L, "| T14 | FIXED | Kaelen stands down | the final authorization scene is playing; `witness_mandate` FAILED | FINAL | `root_phase` FINAL; nothing executed |\n", "")],
    "r5_t8_retcon_dropped": [(L, "| as T5; gate retcon beat played |", "| as T5 |")],
    "r5_formula_domain_guard_dropped": [(L, "crisis_offers(row) = {} if row is not R1, R2 or R3; otherwise", "crisis_offers(row) = for every row:")],
    "r5_signpost_hidden_first": [(L, "HIDDEN  if none of T's offer prerequisites is set, or T is reserved (post-1.0) and disabled", "HIDDEN  if T is disabled or none of T's offer prerequisites is set")],
    "r5_mandate_unanimity": [(L, "MET     if 7 − |witness_dissenters| ≥ witness_threshold", "MET     if |witness_dissenters| = 0")],
    "r5_red_line_clause_dropped": [(L, 'line adds the clause "unless the affected', 'line adds no clause "unless the affected')],
    "r5_gate_keeps_authority_only": [(L, "LAST_CHANCE keeps all six R1 renegotiations.", "LAST_CHANCE keeps the Authority renegotiations only.")],
    "r5_retcon_beat_missing": [(L, "`gate_retcon_deleted_RELEASE`, `gate_retcon_deleted_CHOOSE`; written by", "`gate_retcon_deleted_RELEASE`; written by")],
    "r5_retract_id_without_rule": [(L, "`retract_<rule>_<axis>_<new>`, e.g. `retract_R2_authority_YOU`", "`retract_<axis>_<old>_<new>`, e.g. `retract_authority_NONE_YOU`")],
    "r5_shared_offer_count": [(L, "R2 and R3 share five offers", "R2 and R3 share four offers")],
    "r5_history_as_current": [(L, "never as the current axis value.", "and as the current axis value.")],
    "r5_s9_flag_gate": [(L, "Plays only on `SL-SECRET-WITNESS`: the source's", "Plays whenever `SEVEN_WITNESSES_AVAILABLE` is set: the source's")],
    "r5_s9_failed_changes_id": [(L, "witnesses' place, and nothing changes the", "witnesses' place, and the vote may change the")],
    "r5_ng_transition": [(L, "NG+ starts a new record, not a\ntransition of this table", "NG+ is transition T15 of this\ntable")],
    "r5_ng_mandate_default": [(L, "`witness_mandate` → UNDECIDED", "`witness_mandate` → MET")],
    "r5_loading_fires": [(L, "it fires no transition by itself", "it may fire any transition")],
    "r5_lac19_count": [(L, "each of the six R1 offers at LAST_CHANCE", "each of the five R1 offers at LAST_CHANCE")],
    "r5_validation_pass_pair": [(L, "outcome equal the expected triple", "outcome equal the expected pair")],
    "r5_validation_gate_terms": [(L, "per R1 renegotiation (6), and", "per R1 renegotiation (5), and"), (L, "— 60 runs", "— 59 runs")],
    "r5_life_edge_case_gap": [(L, "11. **All seven witnesses dissent.**", "12. **All seven witnesses dissent.**")],
    # --- review round 6 (axes) + round 2 (lifecycle)
    # qa-lead's round-6 survivors, re-expressed against the revised text (they PASSED revision 5's checker)
    "r6_qa_threshold_range": [(L, "witness_threshold   = 5", "witness_threshold   = 1..7")],
    "r6_qa_threshold_prose": [(L, "`witness_threshold` is fixed at 5 (user decision", "`witness_threshold` is 4-6 (user decision")],
    "r6_qa_lac14_inequality": [(L, "(7 − dissenters ≥ 5)", "(7 − dissenters > 5)")],
    "r6_qa_lac14_failed_range": [(L, "FAILED for 3 to 7", "FAILED for 4 to 7")],
    "r6_qa_s6_window_deleted": [(L, "Available from its slot in Chapter 9 until the Chapter 9 end:", "Available from its slot in Chapter 9:")],
    "r6_qa_lac20_replays": [(L, "`current_scene()` stays `load_menu`, and no lock scene plays.", "`current_scene()` becomes C8-S13, and the lock scenes replay.")],
    "r6_qa_lac9_deferred_outcome": [(L, "DEFERRED → LAST_CHANCE with `offers()` exactly", "DEFERRED → TURNED_BACK with `offers()` exactly")],
    "r6_qa_lac15_withdrawn_stated": [(L, "or at the gate → WITHDRAWN", "or at the gate → STATED")],
    "r6_qa_consent_row_deleted": [(L, "| Companion secret-route reactions | PM:11229-11236 | the source's lines |\n", "")],
    "r6_qa_deferral_id_renamed": [(L, "beat `deferral_c8s20`:", "beat `deferral_c8_s20`:")],
    "r6_qa_s9_mandate_stripped": [(L, "writes `witness_dissenters` and\n`witness_mandate` (Formulas) once", "writes `witness_dissenters` once")],
    "r6_qa_lac19_retcon_dropped": [(L, "contains both `retract_R1_<axis>_<new>` and `gate_retcon_<axis>_<new>`", "contains `retract_R1_<axis>_<new>`")],
    "r6_qa_rule8_stranded": [("no runtime catch-up exists, so\n   no loaded state is stranded.", "the save\n   is stranded.")],
    "r6_qa_ec8_body": [("one\n   positioned past a lock scene (chapters 9 and 10 exist in the code today) is unsupported and does not load (Edge",
                        "one\n   positioned past a lock scene (chapters 9 and 10 exist in the code today) replays the lock scenes (Edge")],
    # axes blocker 1: the damaged-first phase function
    "r6_phase_final_before_damaged": [("    if damaged(record, loaded)                         → DAMAGED\n    if storyline_id is stored and root_phase is FINAL  → FINAL\n",
                                       "    if storyline_id is stored and root_phase is FINAL  → FINAL\n    if damaged(record, loaded)                         → DAMAGED\n")],
    "r6_phase_final_without_id": [("    if storyline_id is stored and root_phase is FINAL  → FINAL", "    if root_phase is FINAL                             → FINAL")],
    "r6_phase_example_damaged_wrong": [("UNSET, nothing stored, false, FINAL) → DAMAGED", "UNSET, nothing stored, false, FINAL) → FINAL")],
    "r6_phase_example_crisis_loadable": [("(NONE, ARCHIVE, RELEASE, nothing stored, false, OUTSIDE) → DAMAGED", "(NONE, ARCHIVE, RELEASE, nothing stored, false, OUTSIDE) → CRISIS")],
    "r6_phase_row_damaged_dropped": [("| DAMAGED | the record holds an item of Edge Case 16: never saved by play; a load that yields it is refused | — (never loaded) |\n", "")],
    "r6_phase_final_meaning_old": [("| FINAL | the final authorization concluded: execution confirmed, or Kaelen stood down after a FAILED witness vote |", "| FINAL | execution confirmed |")],
    # axes blocker 2: Edge Case 16
    "r6_ec16_d10_inverted": [("while the stored ID is not\n      `SL-SECRET-WITNESS`", "while the stored ID is\n      `SL-SECRET-WITNESS`")],
    "r6_ec16_d16_dropped": [("    - D16 a story position past the lock scene of an UNSET axis (a save made past Chapter 8 before these fields\n      existed; unsupported, user decision 2026-11-10)\n", "")],
    "r6_ec16_d7_dropped": [("    - D7 `axis_revised` holding an axis that no `retraction_log` entry names\n", "    - D7 `axis_revised` holding an axis\n")],
    "r6_ec6_cites_boot": [("damaged: SaveService's load check reports it (Edge Case 16, D15)", "damaged: FlagRegistry boot validation (Y1-P1-T03) reports it")],
    "r6_ac9_dlist_short": [("item (D1-D16)", "item (D1-D15)")],
    # axes blocker 3: the over-promise guard
    "r6_overpromise_fantasy": [("no other 1.0 content reads it.", "elsewhere it colours ally lines and slides.")],
    "r6_overpromise_overview": [("in 1.0 only a Sole ending makes that record audible (Core Rule 3)", "a Sole ending names the dissent and ally lines colour it (Core Rule 3)")],
    "r6_overpromise_rule3": [("Nothing else in 1.0 reads\n   `lock_negotiated` (no scene variant, ally line or slide)", "Otherwise it changes ally\n   lines and slides")],
    # axes: record fields and rules forced by D1/D2/D4
    "r6_composer_seats_dropped": [("| witness_seats | map |", "| witness_seat | map |")],
    "r6_composer_seat_order": [("deleted, nonhuman, infrastructure, archive, local_community, rotating (PM:8697-8703)", "deleted, nonhuman, infrastructure, local_community, archive, rotating (PM:8697-8703)")],
    "r6_composer_dissenters_writer": [("| witness_dissenters | set | seats of `witness_seats` | C10-S15 |", "| witness_dissenters | set | seats of `witness_seats` | C10-S15; a reload |")],
    "r6_rule9_executes_anyway": [("Kaelen\n   stands down instead and nothing is executed", "Kaelen\n   executes anyway")],
    "r6_rule10_failed_executed": [("the act is not executed, because Kaelen stands down at the final\n    authorization", "the act is executed over the failed vote")],
    "r6_rule6_gate_needs_flag": [("an invocation there also sets T's unlock\n     flag if the invocation scene did not", "an invocation there needs T's unlock\n     flag")],
    # lifecycle blocker 2: the gate invocation guard
    "r6_gate_formula_needs_flag": [(L, '∪ { "invoke:WITNESS" : enabled(WITNESS), prereqs_met(WITNESS) }', '∪ { "invoke:WITNESS" : SEVEN_WITNESSES_AVAILABLE set, enabled(WITNESS), prereqs_met(WITNESS) }')],
    "r6_t7_guard_needs_flag": [(L, "| WITNESS enabled; prerequisites met, seven seats saved |", "| `SEVEN_WITNESSES_AVAILABLE` set; WITNESS enabled; prerequisites met, seven seats saved |")],
    "r6_gate_table_needs_flag": [(L, "when WITNESS is enabled and its prerequisites are met, invoke:WITNESS;", "when SEVEN_WITNESSES_AVAILABLE is set, WITNESS is enabled and its prerequisites are met, invoke:WITNESS;")],
    "r6_lac21_scene_wrong": [(L, 'YOU, "final permission",\n  LAST_CHANCE)', 'YOU, "final permission",\n  C9-S19)')],
    # lifecycle blocker 3: the save window
    "r6_save_window_dropped": [(L, "No save exists between the start of C8-S16 and its commit.", "Saving is allowed once the offers are shown.")],
    "r6_save_checkpoint_late": [(L, "as one atomic checkpoint before the beat plays", "as one checkpoint after C8-S17")],
    "r6_lac5_save_allowed": [(L, "`try_save()` is false", "`try_save()` is true")],
    # lifecycle blocker 4: the deferral disclosure
    "r6_disclosure_dropped": [(L, "\n(`gate_retcon`).", "\n.")],
    "r6_disclosure_optional": [(L, "Until all four have been shown, `defer:WITNESS` cannot be taken.", "The disclosures may be skipped.")],
    # lifecycle blocker 5: the FAILED vote
    "r6_t13_unguarded": [(L, "| the final authorization scene is playing; `witness_mandate` is not FAILED | FINAL |", "| the final authorization scene is playing | FINAL |")],
    "r6_t14_executes": [(L, "| `root_phase` FINAL; nothing executed |", "| `root_phase` FINAL; restoration executed |")],
    "r6_standdown_executes": [(L, "with nothing executed. The restoration does not happen,", "and the restoration executes anyway,")],
    "r6_kaelen_seated": [(L, "Kaelen sits in none", "Kaelen may sit in one")],
    "r6_stances_hidden": [(L, "the player sees each seated witness's current stance", "the player never sees a witness's stance")],
    "r6_content_rule_dropped": [(L, "Content rule: the candidate data never lets a playthrough seat seven witnesses whose conditions cannot fail", "Content rule: none")],
    "r6_seat_order_s9": [(L, "`archive`, `local_community`, `rotating`", "`local_community`, `archive`, `rotating`")],
    "r6_lac22_confirm_on_failed": [(L, "`confirm_execution()` is false with `record_hash()` unchanged; `route_lines()` is empty", "`confirm_execution()` gives FINAL; `route_lines()` is empty")],
    "r6_old_module_name": [(L, "the ending plays `consent_unauthorized`, authored", "the ending plays `consent_failed_mandate`, authored")],
    # lifecycle blocker 1: the legacy saves
    "r6_legacy_catchup_restored": [(L, "There is no runtime catch-up.", "A runtime catch-up replays the lock scenes.")],
    "r6_legacy_flag_dropped": [(L, "`true_ending_seen`, `ng_plus_unlocked` (`AethelgardPrototype/scripts/chapter10/ch10_ending.gd:15-16`)", "`ng_plus_unlocked` (`AethelgardPrototype/scripts/chapter10/ch10_ending.gd:15-16`)")],
    "r6_legacy_wrong_lines": [(L, "ch10_ending.gd:15-16", "ch10_ending.gd:20-21")],
    # lifecycle blockers 6-7: fail-capable ACs and evidence
    "r6_nonfailing_assertion": [(L, "In FIXED after the boss with `witness_mandate` not FAILED:", "In FIXED after the boss with `witness_mandate` not FAILED: `offers()` is empty;")],
    "r6_lac23_kaelen_allowed": [(L, "for every `retract_*` id `beat_speaker(id)` is not Kaelen", "for every `retract_*` id `beat_speaker(id)` may be Kaelen")],
    "r6_lac23_count": [(L, "the 4 `deferral_*`", "the 3 `deferral_*`")],
    "r6_lac24_no_signoff": [(L, "`production/qa/evidence/`, with lead sign-off\n  recorded beside them", "`production/qa/evidence/`")],
    "r6_validation_load_cells": [(L, "which pass when the load is refused", "which pass when TURNED_BACK")],
    # --- review round 7 (axes revision 7 / lifecycle revision 3): the loaded argument, the seven-seats guard, the
    # save precondition, the record-versus-flags rule, AC14's baseline
    "r7_phase_loaded_dropped": [("storyline_phase(record, loaded):\n    if damaged(record, loaded)", "storyline_phase(record):\n    if damaged(record)")],
    "r7_d9_example_in_play": [("(NONE, ARCHIVE, RELEASE, nothing stored, false, OUTSIDE) → CRISIS; the same", "(NONE, ARCHIVE, RELEASE, nothing stored, false, OUTSIDE) → DAMAGED; the same")],
    "r7_inplay_example_dropped": [(" Example (the live record in play, `loaded`\nfalse): (NONE, ARCHIVE, RELEASE, nothing stored, false, OUTSIDE) → CRISIS; the same record with `loaded` true is the\nlast DAMAGED example above.", "")],
    "r7_loaded_label_flipped": [("Examples (loaded records, `loaded` true):", "Examples (loaded records, `loaded` false):")],
    "r7_ac9_loaded_dropped": [("called with `loaded` false for CRISIS and true for the others", "called with the same arguments for each")],
    "r7_seats_prereq_dropped": [("see above; for WITNESS also false unless `witness_seats` holds seven seats", "see above")],
    "r7_t7_seats_guard_dropped": [(L, "prerequisites met, seven seats saved", "prerequisites met")],
    "r7_mirror_timing_changed": [("Secret Quest 09 sets it in the same step that saves the seventh", "Secret Quest 09 sets it when the quest starts, before the seventh")],
    "r7_lac21_six_seats_dropped": [(L, "The same holds with all three set and `record_field(witness_seats)` holding six of", "The same holds with all three set and `record_field(witness_seats)` holding any of")],
    "r7_d16_precondition_dropped": [("\n\n    D16 holds only while no player-facing build has such saves; if one ships before these fields do, the decision is\n    reopened (`storyline-lifecycle.md` Legacy saves).", "")],
    "r7_ec8_precondition_dropped": [("The refusal holds only while no player-facing\n   build has a save past Chapter 8", "The refusal always holds for any\n   build with a save past Chapter 8")],
    "r7_rule8_precondition_dropped": [(" The refusal holds only while no player-facing build has such saves\n   (`storyline-lifecycle.md` Legacy saves).", "")],
    "r7_record_not_authoritative": [("The composer input record is authoritative: these flags,", "The flags are authoritative: these flags,")],
    "r7_ac14_pairwise_restored": [('The baseline for "changes" is the shared variant of a scene (the one every storyline plays): over the 25', "For every pair of distinct IDs `scene_variants()` differ in at least 3 scenes: over the 25")],
    "r7_oq13_dropped": [("**P3 baseline and the storyline cut order.**", "**P3 baseline.**")],
    "r7_decision_label_back": [("`/map-systems` creates it later.", "`/map-systems` creates it later (D3).")],
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
