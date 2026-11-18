"""Run the storyline checker on the real GDDs and on mutated copies; write one log per run.

Design review rounds 2-13 (2026-11-10 to 2026-11-17; round 5 is also the lifecycle document's round 1, round 6 its
round 2). Round 9 retired the mutations aimed at the removed Witness design (listed in README.md); their old logs
are left in place, unrefreshed. Every mutation must make the checker FAIL; every control must PASS; the real
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

ALL3 = "Elara, Seraphina, Lyra |"  # revision 12: Kaelthas is outside the 1.0 set
L = "life"
MUTATIONS = {
    # --- the eight from revision 1
    "missing_heading": [("## Tuning Knobs", "## Tuning Values")],
    "wrong_count": [("`valid_count: 24`", "`valid_count: 25`")],
    "duplicate_id": [("| SL-YOU-HEARTH-CHOOSE | YOU | HEARTH | CHOOSE |", "| SL-YOU-HEARTH-RELEASE | YOU | HEARTH | CHOOSE |")],
    "deleted_row": [("| SL-SHARED-ARCHIVE-CHOOSE | SHARED | ARCHIVE | CHOOSE | valid | BOUND | — | PRODUCTION_MASTER_2.1.md:10187 | PRODUCTION_MASTER_2.1.md:10196 | " + ALL3 + "\n", "")],
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
    "companion_removed": [("| SL-NONE-HEARTH-CHOOSE | NONE | HEARTH | CHOOSE | valid | NONE_AUTH | — | PRODUCTION_MASTER_2.1.md:10745 | PRODUCTION_MASTER_2.1.md:10754 | " + ALL3,
                           "| SL-NONE-HEARTH-CHOOSE | NONE | HEARTH | CHOOSE | valid | NONE_AUTH | — | PRODUCTION_MASTER_2.1.md:10745 | PRODUCTION_MASTER_2.1.md:10754 | Elara, Seraphina |")],
    "rule_text_wrong": [('"Hearth will not endorse unilateral compulsory restoration."', '"Hearth will not endorse unilateral voluntary restoration."')],
    "prereq_dropped": [("`OLD_WITNESS_SIGNATURE`, `WITNESS_SEATS` (PM:11215-11217)", "`OLD_WITNESS_SIGNATURE` (PM:11215-11217)")],
    "signature_timing": [("storyline_id(A, F, D, I):", "storyline_id(A, F, D, I, timing):")],
    "composer_no_unset": [("| authority | enum | UNSET, YOU, SHARED, NONE |", "| authority | enum | YOU, SHARED, NONE |")],
    "family_split_prose": [("(SOLE 8, BOUND 9, NONE_AUTH 7)", "(SOLE 9, BOUND 9, NONE_AUTH 6)")],
    "reachable_wrong": [("`reachable_1_0: 24`", "`reachable_1_0: 27`")],
    "timing_direction": [("| act1_pace_early | timing | 0 |", "| act1_pace_early | timing | + |")],
    "stale_s_equals_t": [("if I and enabled(T) and prereqs_met(T)", "if S = T and enabled(T) and prereqs_met(T)")],
    # --- review round 3 (retargeted to revision 4 where the structure moved; see README round 4)
    "r3_transform_map_swap": [("{ R1 → WITNESS, R2 → CROWNLESS, R3 → FIRSTWAKE }", "{ R1 → WITNESS, R2 → FIRSTWAKE, R3 → CROWNLESS }")],
    "r3_family_map_rule": [("(YOU → SOLE, SHARED → BOUND, NONE → NONE_AUTH)", "(YOU → SOLE, SHARED → NONE_AUTH, NONE → BOUND)")],
    "r3_family_map_formula": [("{ YOU → SOLE, SHARED → BOUND, NONE → NONE_AUTH }[A]", "{ YOU → BOUND, SHARED → SOLE, NONE → NONE_AUTH }[A]")],
    "r3_timing_in_body": [("    if A, F or D is UNSET                        → PENDING", "    if A, F or D is UNSET or act1_pace_late      → PENDING")],
    "r3_companion_in_body": [("    otherwise                                    → CRISIS ", "    if no companion present                      → CRISIS\n    otherwise                                    → CRISIS ")],
    "r3_counts_false_chain": [("valid_count          = 27 − 3 = 24", "valid_count          = 27 − 3 = 25")],
    "r3_counts_line_dropped": [("family_BOUND         = 9\n", "")],
    "r3_deleted_core_rule_3": [("3. **Lock scenes resolve, clean or negotiated.** ", "")],
    "r3_deleted_core_rule_8": [("7. **A valid row is held to its word.** ", "")],  # the rule is number 7 in rev 4
    "r3_core_rule_retitled": [("6. **Secret routes are reserved (post-1.0).**", "6. **Secret routes.**")],
    "r3_state_renamed": [("| FIXED | an ID stored, `root_phase` INSIDE", "| FIX | an ID stored, `root_phase` INSIDE")],
    "r3_transition_unknown_state": [(L, "| FINAL | `root_phase` FINAL; checkpoint |", "| DONE | `root_phase` FINAL; checkpoint |")],
    "r3_transition_dropped": [(L, "| T8 | FIXED or FINAL | Root of Heaven entry, any path | — | unchanged | open |\n", "")],
    "r3_composer_state_vocab": [("| storyline_phase | enum | LEANING, PARTLY_LOCKED, CRISIS, VALIDATED, FIXED, FINAL, DAMAGED |", "| storyline_phase | enum | LEANING, PARTLY_LOCKED, CRISIS, VALIDATED, FIXED, DAMAGED |")],
    "r3_composer_lock_negotiated_vocab": [("| lock_negotiated | set | faction, authority, deleted |", "| lock_negotiated | set | faction, authority |")],
    "r3_composer_field_dropped": [("| storyline_id | string | a storyline ID, or empty while nothing is stored | C8-S16 on a valid row; a renegotiation at C8-S16; nothing else |\n", "")],
    "r3_danger_wrong_line": [("PRODUCTION_MASTER_2.1.md:9080 |", "PRODUCTION_MASTER_2.1.md:9081 |")],
    "r3_danger_on_invalid": [("| PRODUCTION_MASTER_2.1.md:715 | — |", "| PRODUCTION_MASTER_2.1.md:715 | PRODUCTION_MASTER_2.1.md:9080 |")],
    "r3_unlock_flag_wrong": [("WITNESS: `SEVEN_WITNESSES_AVAILABLE` (PM:11218)", "WITNESS: `WITNESS_SEATS` (PM:11218)")],
    "r3_prereq_overlap": [("CROWNLESS: `CROWN_COORDINATES`,", "CROWNLESS: `WITNESS_SEATS`, `CROWN_COORDINATES`,")],
    "r3_ac_blocked_missing": [("it is\n    empty. *Blocked by:* Y2-PP-T17, Y1-P1-T03.", "it is\n    empty.")],
    "r3_ac_blocked_unknown": [("→ NO_FAMILY. *Blocked by:* Y2-PP-T17.", "→ NO_FAMILY. *Blocked by:* Y9-XX-T99.")],
    "r3_ac_unknown_observable": [("has `axis()` UNSET", "has `axis_of()` UNSET")],
    "r3_ac_number_gap": [("12. Boot validation", "13. Boot validation")],
    # --- review round 4: the 19 QA survivors re-expressed, and one per new check
    # transitions (lifecycle)
    "r4_t4_to_validated": [(L, "| faction and authority set; the row is invalid | CRISIS |", "| faction and authority set; the row is invalid | VALIDATED |")],
    "r4_t13_to_leaning": [(L, "| the final authorization scene is playing | FINAL |", "| the final authorization scene is playing | LEANING |")],
    "r4_t7_event_changed": [(L, "| a renegotiation is taken |", "| a renegotiation is offered |")],
    "r4_t6_guard_dropped": [(L, "| faction set, authority UNSET |", "| — |")],
    "r4_t5_effect_dropped": [(L, "gain it; retraction recorded; retraction beat played; ID stored", "gain it; ID stored")],
    "r4_t14_backward_added": [(L, "| `root_phase` FINAL; checkpoint |\n", "| `root_phase` FINAL; checkpoint |\n| T10 | VALIDATED | a knob changes | — | CRISIS | ID cleared |\n")],
    "r4_t8_knob_guard": [(L, "| the offer is in the row's offer set |", "| the offer is in the row's offer set; WITNESS enabled |")],
    "r4_no_other_transition": [(L, "No other transition exists:", "Other transitions may exist:")],
    # Core Rules (axes)
    "r4_rule7_inverted": [("offers a renegotiation, and the ID never changes.", "a crisis scene may still offer a renegotiation, and the ID never changes.")],
    "r4_rule7_exception_appended": [("offers a renegotiation, and the ID never changes.", "offers a renegotiation, and the ID never changes. A crisis scene may still offer a renegotiation.")],
    "r4_rule9_reconsideration": [("It changes no axis and no ID.", "It may offer one reconsideration of Faction or Deleted.")],
    "r4_rule9_offers_one": [("this design offers none, because", "this design offers one when a trigger holds, because")],
    "r4_rule5_scene_may_end": [("the scene does not end until the coalition holds", "the scene may end before the coalition holds")],
    "r4_rule5_offer_count": [("five for R2 or R3", "six for R2 or R3")],
    "r4_rule3_counts_seeds": [("The test reads only which flags are set: no count, no weight.", "The test counts the seeds set for each value.")],
    "r4_rule4_pair_swapped": [("Archive when NONE and ARCHIVE are locked (R2", "Archive when SHARED and ARCHIVE are locked (R2")],
    # composer record (axes)
    "r4_composer_authority_final_auth": [("| C8-S14 lock; a renegotiation. Never the final authorization |", "| C8-S14 lock; a renegotiation; the final authorization |")],
    "r4_composer_family_vocab": [("| family | enum | SOLE, BOUND, NONE_AUTH, RESERVED, NO_FAMILY |", "| family | enum | SOLE, BOUND, NONE_AUTH |")],
    "r4_composer_final_reconsidered": [("| axis_revised | set | faction, authority, deleted | a renegotiation |\n", "| axis_revised | set | faction, authority, deleted | a renegotiation |\n| final_reconsidered | bool | true, false | the final authorization |\n")],
    # Tuning Knobs (axes)
    "r4_knob_reconsideration_triggers": [("\n\nNot knobs (fixed by design)", "\n| `reconsideration_triggers` | `[boss_phase_drastic]` | empty or one trigger | whether the final authorization offers a reconsideration | PM:8791 |\n\nNot knobs (fixed by design)")],
    "r4_knob_faction_negotiation": [("\n\nNot knobs (fixed by design)", "\n| `faction_negotiation_allowed` | true | true, false | whether Faction can be renegotiated at C8-S16 | review round 3 |\n\nNot knobs (fixed by design)")],
    "r4_knob_default_flip": [("| `secret_route_enabled.WITNESS` | false |", "| `secret_route_enabled.WITNESS` | true |")],
    "r4_knob_dropped": [("| `secret_route_enabled.CROWNLESS`, `.FIRSTWAKE` | false |", "| `secret_route_enabled.CROWNLESS` | false |")],
    "r4_not_knobs_lock_pass_dropped": [("the `lock_pass` test, ", "")],
    # phase table / gate
    "r4_validated_gate_turns_back": [("| VALIDATED | an ID stored, `root_phase` OUTSIDE | open |", "| VALIDATED | an ID stored, `root_phase` OUTSIDE | turns the player back |")],
    "r4_phase_row_deleted": [("| LEANING | every axis UNSET | turns the player back |\n", "")],
    "r4_gate_outcome_wrong": [(L, "| VALIDATED | ROOT_OF_HEAVEN; `root_phase` becomes INSIDE (T7) |", "| VALIDATED | TURNED_BACK; `root_phase` becomes INSIDE (T7) |")],
    "r4_gate_t_ref_wrong": [(L, "becomes INSIDE (T7)", "becomes INSIDE (T8)")],
    # invariants, edge cases (axes)
    "r4_invariant_deleted": [('| I5 | No soft-lock under any knob value or patch: every state without a stored ID either is before the locks, offers a renegotiation that reaches a valid row, or is a data error refused at the gate (a DAMAGED record, which play never writes) | 5, 8 |\n', '')],
    "r4_invariant_rule_ref": [("| I7 | A valid row is held to its word | 7 |", "| I7 | A valid row is held to its word | 8 |")],
    "r4_edge_case_16_deleted": [("16. **A damaged record** (a debug or edited save, or one made before these fields existed; play never writes one,\n", "")],
    "r4_edge_case_16_item_dropped": [("    - D6 `axis_revised` holding an axis that `lock_negotiated` lacks\n", "")],
    # formula bodies (axes)
    "r4_prereqs_met_dropped": [("    if I and enabled(T) and prereqs_met(T)       →", "    if I and enabled(T)                          →")],
    "r4_not_invalid_inverted": [("    if not invalid(A, F, D)                      →", "    if invalid(A, F, D)                          →")],
    "r4_lock_pass_swapped": [("is set   → CLEAN", "is set   → @@"),
                             ("    otherwise                                                          → NEGOTIATED", "    otherwise                                                          → CLEAN"),
                             ("is set   → @@", "is set   → NEGOTIATED")],
    "r4_phase_branch_order": [("    if A, F and D are all UNSET                        → LEANING\n    if A, F or D is UNSET                              → PARTLY_LOCKED\n", "    if A, F or D is UNSET                              → PARTLY_LOCKED\n    if A, F and D are all UNSET                        → LEANING\n")],
    "r4_family_reserved_changed": [("SL-SECRET-WITNESS, SL-SECRET-CROWNLESS, SL-SECRET-FIRSTWAKE → RESERVED", "SL-SECRET-WITNESS, SL-SECRET-CROWNLESS, SL-SECRET-FIRSTWAKE → NO_FAMILY")],
    "r4_invalid_not_member": [("invalid(A, F, D) = (A, F, D) ∈ {", "invalid(A, F, D) = (A, F, D) ∉ {")],
    "r4_lock_pass_example_wrong": [("HEARTH with only `ch1_knight_killed` → NEGOTIATED", "HEARTH with only `ch1_knight_killed` → CLEAN")],
    "r4_phase_example_wrong": [("`SL-SHARED-ARCHIVE-CHOOSE`, INSIDE) → FIXED", "`SL-SHARED-ARCHIVE-CHOOSE`, INSIDE) → VALIDATED")],
    # counts (axes)
    "r4_counts_offers_wrong": [("renegotiation_offers = 6 + 5 + 5 = 16", "renegotiation_offers = 6 + 6 + 5 = 17")],
    "r4_counts_offers_terms": [("renegotiation_offers = 6 + 5 + 5 = 16", "renegotiation_offers = 5 + 6 + 5 = 16")],
    "r4_ac5_case_count": [("(128 cases)", "(124 cases)")],
    "r4_seed_intro_count": [('(26 flags in 28 rows:', '(25 flags in 28 rows:')],
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
    "r4_ng_reset_default": [(L, "`root_phase` → OUTSIDE", "`root_phase` → INSIDE")],
    "r4_ng_reset_field_dropped": [(L, "`retraction_log`, `beats_played` → empty", "`retraction_log` → empty")],
    "r4_life_number_word": [(L, "offers only its six\n   renegotiations (S5)", "offers only its five\n   renegotiations (S5)")],
    "r4_life_edge_case_gap": [(L, "6. **A crash between two writes", "7. **A crash between two writes")],
    "r4_life_heading": [(L, "## Tuning Knobs\n\nNone of its own", "## Knobs\n\nNone of its own")],
    # L-ACs and the Validation note (lifecycle)
    "r4_lac_no_blocked_by": [(L, "with none. *Blocked by:* Y2-PP-T17.", "with none.")],
    "r4_lac_unknown_observable": [(L, "`signpost()` is HIDDEN for all three routes", "`route_state()` is HIDDEN for all three routes")],
    "r4_lac_axes_observable": [(L, "after C8-S16, `storyline_phase()` VALIDATED", "after C8-S16, `phase_of()` VALIDATED")],
    "r4_lac_unknown_story": [(L, "route. *Blocked by:* Y2-PP-T17.", "route. *Blocked by:* Y2-PP-T99.")],
    "r4_lac_number_gap": [(L, "- **L-AC18 Visual", "- **L-AC19 Visual")],
    "r4_lac6_runs": [(L, "its offers (16 runs)", "its offers (15 runs)")],
    "r4_validation_total": [(L, "— 50 runs", "— 51 runs")],
    "r4_validation_term_consistent": [(L, "at C8-S16 (16)", "at C8-S16 (15)"), (L, "— 50 runs", "— 49 runs")],
    "r4_validation_matrix": [(L, "2 counted paths × 5 storable phases (10)", "3 counted paths × 5 storable phases (15)"), (L, "— 50 runs", "— 55 runs")],
    # stale revision-3 vocabulary
    "r4_stale_storyline_state": [(L, "(fields `authority`,", "(fields `storyline_state`, `authority`,")],
    "r4_stale_storyline_state_axes": [("implements `storyline_id`, `storyline_phase`,", "implements `storyline_id`, `storyline_state`,")],
    "r4_stale_gate_crisis": [(L, "the gate, and C9-S18's form).", "the gate, and C9-S18's form; no GATE_CRISIS).")],
    # --- review round 5 (axes) + round 1 (lifecycle): one per new pin or derived check
    # axes: composer record, Edge Case 16, protected touchpoints, Core Rules 3/6/10, ACs
    "r5_composer_retraction_log_dropped": [('| retraction_log | list | at most one entry {axis, old, new, withdrawn_item, scene}; `withdrawn_item` and `scene` are opaque display text that no code branches on | every renegotiation |\n', '')],
    "r5_ec16_rewrites_id": [("and never rewrites the stored ID or the save", "and then rewrites the stored ID or the save")],
    "r5_protected_area_dropped": [("| NG+ | the reset of the record and the axis, secret and unlock flags | Edge Case 9; lifecycle NG+ reset |\n", "")],
    "r5_protected_area_bogus": [("| collision, hitboxes | none | — |", "| collision, hitboxes, lighting | none | — |")],
    "r5_rule6_chapter10_flag": [("plays only when the stored ID is `SL-SECRET-T`, which no 1.0 record holds", "plays when the unlock flag is set")],
    "r5_rule3_sole_dissent_optional": [("the ending plays `sole_dissent`", "the ending may play `sole_dissent`")],
    "r5_ac_number_gap": [("15. Pillar P5 tracking", "16. Pillar P5 tracking")],
    "r5_ac14_unknown_observable": [('`scene_lines(id, scene)` differs from the base', '`scenes(id, scene)` differs from the base')],
    # lifecycle: transitions, formulas, pinned sentences, derived beats, L-ACs, Validation note
    "r5_formula_domain_guard_dropped": [(L, "crisis_offers(row) = {} if row is not R1, R2 or R3; otherwise", "crisis_offers(row) = for every row:")],
    "r5_retract_id_without_rule": [(L, "`retract_<rule>_<axis>_<new>`, e.g. `retract_R2_authority_YOU`", "`retract_<axis>_<old>_<new>`, e.g. `retract_authority_NONE_YOU`")],
    "r5_shared_offer_count": [(L, "R2 and R3 share five offers", "R2 and R3 share four offers")],
    "r5_ng_transition": [(L, "NG+ starts a new record, not a\ntransition of this table", "NG+ is transition T15 of this\ntable")],
    "r5_loading_fires": [(L, "fires no transition by itself", "may fire any transition")],
    "r5_validation_pass_pair": [(L, "outcome equal the expected triple", "outcome equal the expected pair")],
    "r5_life_edge_case_gap": [(L, "5. **Every Witness lead found in 1.0.**", "4. **Every Witness lead found in 1.0.**")],
    # --- review round 6 (axes) + round 2 (lifecycle)
    # qa-lead's round-6 survivors, re-expressed against the revised text (they PASSED revision 5's checker)
    "r6_qa_lac20_replays": [(L, "`current_scene()` stays `load_menu`, and no lock scene plays.", "`current_scene()` becomes C8-S13, and the lock scenes replay.")],
    "r6_qa_lac15_withdrawn_stated": [(L, "`revise:authority:NONE`) → WITHDRAWN", "`revise:authority:NONE`) → STATED")],
    "r6_qa_rule8_stranded": [("Every save that play writes loads (I9)", "Every save that play writes is stranded (I9)")],
    "r6_qa_ec8_body": [('it\n   is refused by D16 as unsupported', 'it loads LEANING')],
    # axes blocker 1: the damaged-first phase function
    "r6_phase_final_before_damaged": [("    if damaged(record, loaded, flags, position)        → DAMAGED\n    if storyline_id is stored and root_phase is FINAL  → FINAL\n", "    if storyline_id is stored and root_phase is FINAL  → FINAL\n    if damaged(record, loaded, flags, position)        → DAMAGED\n")],
    "r6_phase_final_without_id": [("    if storyline_id is stored and root_phase is FINAL  → FINAL", "    if root_phase is FINAL                             → FINAL")],
    "r6_phase_example_damaged_wrong": [('nothing stored, FINAL) →\nDAMAGED', 'nothing stored, FINAL) → FINAL')],
    "r6_phase_example_crisis_loadable": [('OUTSIDE) → DAMAGED in Chapter 9;', 'OUTSIDE) → CRISIS in Chapter 9;')],
    "r6_phase_row_damaged_dropped": [('| DAMAGED | the record holds an item of Edge Case 16: never saved by play; a load that yields it is refused | a loaded record never reaches the gate; a live one is turned back as a data error with a reload prompt (lifecycle S6) |\n', '')],
    "r6_phase_final_meaning_old": [("| FINAL | the final authorization concluded: execution confirmed |", "| FINAL | execution confirmed |")],
    # axes blocker 2: Edge Case 16
    "r6_ec16_d16_dropped": [('    - D16 a story position (Terms) past the lock scene of an UNSET axis (a save made past Chapter 8 before these\n      fields existed; unsupported, user decision 2026-11-10)\n', '')],
    "r6_ec16_d7_dropped": [("    - D7 `axis_revised` holding an axis that no `retraction_log` entry names (`D7.unnamed`), or a `retraction_log`\n      entry whose axis is not in `axis_revised` (`D7.reverse`; the composer reads `axis_revised`), or a\n      `retraction_log` entry whose `new` value is not the record's value for its axis (`D7.new_mismatch`). The\n      clauses `D7.multi` and `D7.duplicate` of revision 11 are retired (design review round 12): D0 refuses a second\n      entry, so neither could fire, and the revision-11 reason given for `D7.multi` was false: (NONE, HEARTH,\n      RELEASE) admits two consistent Faction retractions, from R2 (ARCHIVE→HEARTH) and from R3 (CONTINUITY→HEARTH),\n      which is now a D0 fixture (AC9)\n", '    - D7 `axis_revised` holding an axis\n')],
    "r6_ec6_cites_boot": [("damaged: SaveService's load check reports it (Edge Case 16, D15)", "damaged: FlagRegistry boot validation (Y1-P1-T03) reports it")],
    "r6_ac9_dlist_short": [('(D0, D1, D6-D9, D14-D17)', '(D0, D1, D6-D9, D14-D16)')],
    # axes blocker 3: the over-promise guard
    "r6_overpromise_fantasy": [("no other 1.0 content reads it.", "elsewhere it colours ally lines and slides.")],
    "r6_overpromise_overview": [("in 1.0 only a Sole ending makes that record\naudible (Core Rule 3)", "a Sole ending names the dissent and ally lines colour it (Core Rule 3)")],
    "r6_overpromise_rule3": [("Nothing else in 1.0 reads\n   `lock_negotiated` (no scene variant, ally line or slide)", "Otherwise it changes ally\n   lines and slides")],
    # axes: record fields and rules forced by D1/D2/D4
    # lifecycle blocker 2: the gate invocation guard
    # lifecycle blocker 3: the save window
    "r6_save_window_dropped": [(L, "autosave and manual save are suppressed from the", "autosave and manual save are allowed from the")],
    "r6_save_checkpoint_late": [(L, "as one atomic checkpoint before that beat plays", "as one checkpoint after C8-S17")],
    "r6_lac5_save_allowed": [(L, "until its commit `try_save()` is false", "until its commit `try_save()` is true")],
    # lifecycle blocker 4: the deferral disclosure
    # lifecycle blocker 5: the FAILED vote
    "r6_t13_unguarded": [(L, "| the final authorization scene is playing | FINAL |", "| — | FINAL |")],
    # Revision 8 (design review round 8): the T13 guard and the D17 item are pinned.
    "r8_d17_dropped": [("    - D17 a lock-order defect, in two clauses. (a) *Before commit (not for the live crisis):* an axis is set while the story\n      position is before its lock scene's commit: no lock scene could play from it (S1 needs every axis UNSET, S2\n      needs Faction set, S4 needs Faction and Authority set), so loading it would strand the player. A position\n      inside a lock scene before its commit counts as before it (no save exists there, I9); the commit checkpoint\n      counts as past it. (b) *Prefix:* the set axes are not a prefix of the lock order (Faction, then Authority,\n      then Deleted). For a loaded record (b) is implied by D16 and (a) (the reference model checked 64 axis triples\n      at 15 positions and found none that fires (b) alone), so it is kept as documentation and has no fixture of its\n      own (AC9)\n\n", '')],
    "r6_t14_executes": [(L, "| `root_phase` FINAL; checkpoint |", "| `root_phase` FINAL; restoration executed |")],
    "r6_lac22_confirm_on_failed": [(L, "else is false with `record_hash()` unchanged. *Blocked", "else gives FINAL. *Blocked")],
    # lifecycle blocker 1: the legacy saves
    "r6_legacy_catchup_restored": [(L, "There is no runtime catch-up.", "A runtime catch-up replays the lock scenes.")],
    "r6_legacy_flag_dropped": [(L, "`true_ending_seen`, `ng_plus_unlocked` (`AethelgardPrototype/scripts/chapter10/ch10_ending.gd:15-16`)", "`ng_plus_unlocked` (`AethelgardPrototype/scripts/chapter10/ch10_ending.gd:15-16`)")],
    "r6_legacy_wrong_lines": [(L, "ch10_ending.gd:15-16", "ch10_ending.gd:20-21")],
    # lifecycle blockers 6-7: fail-capable ACs and evidence
    "r6_nonfailing_assertion": [(L, "In FIXED after the boss: `take()`", "In FIXED after the boss: `offers()` is empty; `take()`")],
    "r6_lac23_kaelen_allowed": [(L, "every `retract_*` id `beat_speaker(id)` is not Kaelen", "every `retract_*` id `beat_speaker(id)` may be Kaelen")],
    "r6_lac23_count": [(L, "defines — the 16 `retract_*`", "defines — the 15 `retract_*`")],
    "r6_lac24_no_signoff": [(L, "`production/qa/evidence/`, with lead sign-off\n  recorded beside them", "`production/qa/evidence/`")],
    "r6_validation_load_cells": [(L, "which pass when the\nload is refused", "which pass when\nTURNED_BACK")],
    # --- review round 7 (axes revision 7 / lifecycle revision 3): the loaded argument, the seven-seats guard, the
    # save precondition, the record-versus-flags rule, AC14's baseline
    "r7_phase_loaded_dropped": [("storyline_phase(record, loaded, flags, position):\n    if damaged(record, loaded, flags, position)", "storyline_phase(record, loaded):\n    if damaged(record, loaded)")],
    "r7_d9_example_in_play": [('OUTSIDE) → CRISIS inside C8-S16 before its\ncommit;', 'OUTSIDE) → DAMAGED inside C8-S16 before its commit;')],
    "r7_inplay_example_dropped": [(' Examples (the live\nrecord in play, `loaded` false): (NONE, ARCHIVE, RELEASE, nothing stored, OUTSIDE) → CRISIS inside C8-S16 before its\ncommit; (NONE, ARCHIVE, RELEASE, nothing stored, OUTSIDE) → DAMAGED in Chapter 9 (D9), which the gate turns back;\n(SHARED, ARCHIVE, CHOOSE, nothing stored, OUTSIDE) → DAMAGED inside C8-S16 before its commit (D9 and D17: a valid\nrow is not `live_crisis`).', '')],
    "r7_loaded_label_flipped": [('Examples (loaded records, `loaded` true,', 'Examples (loaded records, `loaded` false,')],
    "r7_ac9_loaded_dropped": [("called with `loaded` false for CRISIS and true for the others", "called with the same arguments for each")],
    "r7_d16_precondition_dropped": [("\n\n    D16 holds only while no player-facing build has such saves; if one ships before these fields do, the decision is\n    reopened (`storyline-lifecycle.md` Legacy saves).", "")],
    "r7_ec8_precondition_dropped": [("The refusal holds only while no player-facing\n   build has a save past Chapter 8", "The refusal always holds for any\n   build with a save past Chapter 8")],
    "r7_rule8_precondition_dropped": [(' The refusal holds only while no player-facing build has such\n   saves (`storyline-lifecycle.md` Legacy saves).', '')],
    "r7_record_not_authoritative": [("The composer input record is authoritative: these flags,", "The flags are authoritative: these flags,")],
    "r7_ac14_pairwise_restored": [('for every pair of distinct IDs, at least 2 scenes differ between', 'for every pair of distinct IDs, at least 3 scenes differ between')],
    "r7_oq13_dropped": [("**P3 baseline and the storyline cut order.**", "**P3 baseline.**")],
    "r7_decision_label_back": [("`/map-systems` creates it later.", "`/map-systems` creates it later (D3).")],
    # --- design review round 9 (axes revision 9 / lifecycle revision 5): one per new or replaced check
    "r9_secret_witness_1_0": [("| — (reserved; CONSENT when designed) | post-1.0 |", "| CONSENT | 1.0 |")],
    "r9_family_consent": [("SL-SECRET-WITNESS, SL-SECRET-CROWNLESS, SL-SECRET-FIRSTWAKE → RESERVED", "SL-SECRET-WITNESS → CONSENT; SL-SECRET-CROWNLESS, SL-SECRET-FIRSTWAKE → RESERVED")],
    "r9_composer_witness_field": [("| beats_played | set |", "| witness_mandate | enum | UNDECIDED, MET, FAILED | C10-S15 |\n| beats_played | set |")],
    "r9_ac3_field_list": [("lock_negotiated, retraction_log,\n   beats_played,", "lock_negotiated, retraction_log,\n   beats_played, witness_mandate,")],
    "r9_invariant_i9_dropped": [("| I9 | Every transition commits its record writes and its beat id as one atomic checkpoint; no save exists inside a lock scene, the crisis or the final authorization before its commit | 3, 5, 8, 9 |\n", "")],
    "r9_invariant_range_stale": [(L, "the invariants I1-I9 of", "the invariants I1-I8 of")],
    "r9_rule5_secret_offer": [("is post-1.0: no secret-route offer exists in 1.0 (Core Rule 6).", "is offered as a deferral to the witnesses (Core Rule 6).")],
    "r9_rule6_routes_enabled": [("are disabled in 1.0 (user decision 2026-11-11", "are enabled in 1.0 (user decision 2026-11-11")],
    "r9_knob_safe_range": [("| false | false until the post-1.0 secret-route design ships (a GDD revision; never enabled while `family` would be RESERVED) |", "| false | false or true |")],
    "r9_crisis_offer_defer": [(L, "`revise:deleted:CHOOSE` |\n| R2", "`revise:deleted:CHOOSE`, `defer:WITNESS` |\n| R2")],
    "r9_stale_identifier_in_oq": [(L, "the deferral, invocation, witness vote, stand-down and Consent variants of revision 4", "`witness_deferred`, the invocation, witness vote, stand-down and Consent variants of revision 4")],
    "r9_checkpoint_missing": [(L, "| `root_phase` INSIDE; checkpoint |", "| `root_phase` INSIDE |")],
    "r9_commit_list": [(L, "(T1, T2, T3, T5, T7, T9) commits", "(T1, T2, T3, T5, T9) commits")],
    "r9_lac6_list": [(L, "For each record-writing transition (T1, T2, T3, T5, T7, T9)", "For each record-writing transition (T1, T2, T3, T5)")],
    "r9_ec16_retired_reactivated": [("    - D2-D5 retired (revision 9): they checked the Witness record fields, which 1.0 no longer stores", "    - D2-D5 a stored ID on a row other than R1")],
    "r9_ac9_clause_list": [('for each clause of each active Edge Case 16 item (D0, D1,', 'for each active Edge Case 16 item (D1,')],
    "r9_phase_example_lock_order": [("(YOU, HEARTH, UNSET, nothing stored, OUTSIDE) →", "(UNSET, HEARTH, CHOOSE, nothing stored, OUTSIDE) →")],
    "r9_observable_old_name": [('| `scene_lines(id, scene)` |', '| `scene_variants(id)` |')],
    "r9_ac15_blocked": [('*Blocked by:* Y2-PP-T17, Y1-P1-T03 (the arc flags exist in FlagRegistry).', '*Blocked by:* Y1-P1-T03 (the arc flags exist in FlagRegistry).')],
    "r9_ac11_blocked": [('`companions_of(m)`. *Blocked by:* Y2-PP-T17.', '`companions_of(m)`. *Blocked by:* Y2-PP-T17, Y1-P1-T03.')],
    "r9_ac16_testers": [('with at least 12 testers', 'with at least 3 testers')],
    "r9_doc_ac_label": [("(document lint, Config/Data, advisory)", "(Config/Data, advisory)")],
    "r9_ac5_formula_mention": [("so a swapped `transform()` fails", "so `transform()` is covered")],
    "r9_lac2_fixture_wrong": [(L, "`act1_report_local` → not;", "`act1_report_local` → contains;")],
    "r9_s5_unlock_flag": [(L, "`SEVEN_WITNESSES_AVAILABLE`, `CROWNLESS_AVAILABLE`, `FIRST_WAKE_AVAILABLE`) is set", "`SEVEN_WITNESSES_AVAILABLE`, `FIRST_WAKE_AVAILABLE`) is set")],
    "r9_dependency_revision": [(L, 'invariants I1-I9, knobs | revision 14 |', 'invariants I1-I9, knobs | revision 8 |')],
    "r9_content_scope_count": [(L, "| red lines | 3 |", "| red lines | 4 |")],
    "r9_gate_row_dropped": [(L, "| FIXED, FINAL | ROOT_OF_HEAVEN; nothing changes (T8) |\n", "")],
    "r9_life_formula_signpost": [(L, "= HIDDEN while T is disabled", "= OPEN while T is disabled")],
    "r9_ec2_offer_count": [("R1 at C8-S16 offers only its\n   six renegotiations", "R1 at C8-S16 offers only its\n   seven renegotiations")],
    "r9_red_line_names_route": [(L, "No line names a secret route or the institution\none needs", "The R1 line names the witnesses")],
    # --- design review round 10 (2026-11-17): the reference model's findings F1-F9 as pinned text.
    "r10_ac9_crisis_d9_only": [('reports exactly the items {D9, D17}', 'reports exactly the items {D9}')],
    "r10_d17_prefix_fixture": [('documentation (`D17.prefix`), which has no\n   fixture', 'documentation (none), which has no\n   fixture')],
    "r10_live_d17_applies": [('are tested on every record except a `live_crisis` one', 'are tested on a loaded record only')],
    "r10_d9_load_only_unmarked": [('three axes set with nothing stored *(not for the live crisis)*', 'three axes set with nothing stored')],
    "r10_d14_matching_dropped": [(" A beat matches an entry\n      exactly when its id is `retract_<rule>_<axis>_<new>`, rebuilt from the entry (`rule` is the invalid row R1-R3\n      that the record's axes form with the entry's axis set back to `old`)", "")],
    "r10_d7_reverse_dropped": [('or a `retraction_log`\n      entry whose axis is not in `axis_revised` (`D7.reverse`; the composer reads `axis_revised`), ', '')],
    "r10_rule8_stranded_restored": [("no runtime\n   catch-up exists. Every save", "no runtime\n   catch-up exists, so no loaded state is stranded. Every save")],
    "r10_rule8_best_effort_dropped": [('Open Question 17): it never promises edited-save integrity', 'Open Question 17): it promises edited-save integrity')],
    "r10_ec16_not_checked_dropped": [('Not checked, by the inclusion rule (edited or debug saves only; user decision 2026-11-17, Open Question 17):', 'Checked:')],
    "r10_gate_damaged_row_dropped": [(L, '| DAMAGED (a live record) | TURNED_BACK: a data error, no transition; a dev build asserts; the player sees a system-voice prompt (not the Assembly line) to reload the last save that passes the load check |\n', '')],
    "r10_gate_damaged_outcome_wrong": [(L, '| TURNED_BACK: a data error, no transition;', '| ROOT_OF_HEAVEN: a data error, no transition;')],
    "r10_lac8_injection_dropped": [(L, "they run on a live record that the test injects at the gate, and are reported as synthetic", "they run from synthetic fixture saves and are reported as synthetic")],
    "r10_t6_defence_dropped": [(L, "T6 and the\nDAMAGED row are therefore defence in depth", "T6 and the\nDAMAGED row are therefore live paths")],
    # Round 11 (2026-11-17): Open Questions 17 and 18, C9-S18, AC9/AC14/AC16/AC17, Kaelthas trust.
    "r11_live_crisis_unscoped": [('CRISIS is returned only for `live_crisis`.', 'CRISIS is returned for a live record.')],
    "r11_live_crisis_outside_window": [('OUTSIDE) → DAMAGED in Chapter 9 (D9)', 'OUTSIDE) → CRISIS in Chapter 9 (D9)')],
    "r11_live_valid_row_crisis": [('(SHARED, ARCHIVE, CHOOSE, nothing stored, OUTSIDE) → DAMAGED inside C8-S16', '(SHARED, ARCHIVE, CHOOSE, nothing stored, OUTSIDE) → CRISIS inside C8-S16')],
    "r11_loaded_inside_c8s16_crisis": [('OUTSIDE) → DAMAGED inside C8-S16 before its commit (no save exists there', 'OUTSIDE) → CRISIS inside C8-S16 before its commit (no save exists there')],
    "r11_ec16_d0_dropped": [('    - D0 a record whose shape is wrong:', '    - (retired) a record whose shape is wrong:')],
    "r11_inclusion_rule_iii_dropped": [(' (iii) it cannot refuse a record that play writes.', '')],
    "r11_refusal_as_corruption": [('A refusal is never handled as file corruption', 'A refusal is handled as file corruption')],
    "r11_tripwire_dropped": [('Tripwires: the reference model asserts that the categories of accepted records play does not write equal a\n    pinned list', 'The reference model reports accepted records')],
    "r11_i5_gate_refusal_dropped": [(', or is a data error refused at the gate (a DAMAGED record, which play never writes)', '')],
    "r11_arc_scope_post": [('| 05 | The Flight List | secret:FIRSTWAKE | — | 1.0 (feeds post-1.0) |', '| 05 | The Flight List | secret:FIRSTWAKE | — | post-1.0 |')],
    "r11_ac14_pairwise_one": [('for every pair of distinct IDs, at least 2 scenes differ between', 'for every pair of distinct IDs, at least 1 scenes differ between')],
    "r11_ac14_unmasked": [('substituted name, number or faction name alone never counts', 'substituted name counts')],
    "r11_ac16_no_act1_play": [('At least 6 play Act 1 themselves', 'None play Act 1 themselves')],
    "r11_ac17_dropped": [("17. Pillar P5 voiced (a closing condition of Y2-PP-T17, after AC15): for each of the ten 1.0 side arcs that push an axis\n    (01-04, 06-08, 10-12), a fixture record with one of that arc's `side_arc_flags` set makes `lock_arguments()` of the axis\n    the flag pushes contain an argument whose flag is that flag, and the same fixture with every flag of that arc\n    unset gives a `lock_arguments()` that contains none of that arc's flags. Arc 12 is tested for its `deleted:CHOOSE` push only, arc 08 for its Faction push only.\n    *Blocked by:* Y2-PP-T17, Y1-P1-T03.\n\n", '')],
    "r11_ac9_mutation_kill_dropped": [('a copy of `load_check` with that clause deleted fails at least one fixture of this\n   criterion', 'a copy of `load_check` with that clause deleted is noted')],
    "r11_life_c9s18_noise_only": [(L, "keeps the source's condition: with every FIRSTWAKE offer prerequisite set it plays its decrypted form", 'plays only its incomplete form')],
    "r11_life_c9s18_scope_dropped": [(L, '| `c9s18_logged` | 1 | C9-S18 with every FIRSTWAKE offer prerequisite set |\n', '')],
    "r11_life_gate_damaged_assembly_line": [(L, 'the player sees a system-voice prompt (not the Assembly line) to reload the last save that passes the load check', 'the player hears that the Assembly has not decided')],
    "r11_life_lac8_live_crisis_dropped": [(L, 'A live invalid-row record with nothing stored, injected past C8-S16 (in\n  Chapter 9), reads DAMAGED', 'A live invalid-row record with nothing stored, injected past C8-S16 (in Chapter 9), reads CRISIS')],
    "r11_life_lac18_headless": [(L, 'one retained live Godot viewport screenshot each (not a headless or dummy-renderer\n  capture)', 'one retained screenshot each')],
    # Round 12 (2026-11-17): Authority remap, Kaelthas out of 1.0, D0 owns the one-entry cap (D7.multi and
    # D7.duplicate retired), D15 schema scope, the story-position list, legacy defaulting, chapter select,
    # the gate predicate, AC9/AC11/AC14-AC17, Core Rules 3, 8 and 11, PM:7118. Retired this round (target
    # text removed): r11_d7_duplicate_dropped, r11_kaelthas_trust_dropped (logs left in place, unrefreshed).
    "r12_kill_justified_plus": [('| ch1_aldric_kill_justified | authority:YOU | − |', '| ch1_aldric_kill_justified | authority:YOU | + |')],
    "r12_second_axis_row": [('| ch2_seraphina_truth | authority:SHARED | + | until:lock:authority | dialogue/ch2/command_hall.dlg:23 (J) |\n', '| ch2_seraphina_truth | authority:SHARED | + | until:lock:authority | dialogue/ch2/command_hall.dlg:23 (J) |\n| ch2_seraphina_truth | authority:NONE | + | until:lock:authority | dialogue/ch2/command_hall.dlg:23 (J) |\n')],
    "r12_showoff_axis_row_dropped": [('| ch2_seraphina_showoff | authority:YOU | − | until:lock:authority | dialogue/ch2/command_hall.dlg:46 (J) |\n', '')],
    "r12_seed_rows_count": [('(26 flags in 28 rows:', '(26 flags in 27 rows:')],
    "r12_rule3_minus_seeds": [('(`ch1_aldric_kill_justified`,\n   `ch1_root_purge`, `ch2_seraphina_showoff`): power', '(`ch1_aldric_kill_justified`): power')],
    "r12_lock_pass_example_truth": [('SHARED with `ch2_seraphina_truth` set → CLEAN', 'SHARED with `ch2_seraphina_truth` set → NEGOTIATED')],
    "r12_modifier_row_rule_dropped": [(" A seed row is matched by\nits (flag, pushes) pair, so a flag's modifier row never enters the test.", '')],
    "r12_knight_spared_note_dropped": [('`ch1_knight_spared` stays a modifier only: the Purge path sets it too\n  (`dialogue/ch1/aldric.dlg:116`),', '`ch1_knight_spared` stays a modifier only,')],
    "r12_kaelthas_composer_readded": [('| companions_present | set | Elara, Seraphina, Lyra |', '| companions_present | set | Elara, Seraphina, Lyra, Kaelthas |')],
    "r12_kaelthas_row_readded": [('| PRODUCTION_MASTER_2.1.md:10754 | Elara, Seraphina, Lyra |', '| PRODUCTION_MASTER_2.1.md:10754 | Elara, Seraphina, Lyra, Kaelthas |')],
    "r12_rule11_kaelthas_in_set": [('The 1.0 companion set is Elara, Seraphina and Lyra.', 'The 1.0 companion set is Elara, Seraphina, Lyra and Kaelthas.')],
    "r12_ec1_kaelthas_trust": [('Kaelthas is outside the 1.0 companion set:', 'Kaelthas is absent without enough trust:')],
    "r12_ac11_four_companions": [('with all three\n    1.0 companions (Elara, Seraphina, Lyra)', 'with all four companions (Elara, Seraphina, Lyra, Kaelthas)')],
    "r12_oq19_header": [('19. **Kaelthas as a companion (user decision 2026-11-17, design review round 12).**', '19. **Kaelthas as a companion.**')],
    "r12_d7_duplicate_readded": [('(`D7.new_mismatch`). The\n      clauses', '(`D7.new_mismatch`), or more than one `retraction_log` entry (`D7.duplicate`). The clauses')],
    "r12_d0_duplicate_dropped": [('a set holding one element twice (`D0.duplicate`), or a', 'or a')],
    "r12_d0_cap_two": [('(`D0.max`; `retraction_log` one entry: play takes', '(`D0.max`; `retraction_log` two entries: play takes')],
    "r12_d15_schema_scope_dropped": [(", as the groups stood at the save's schema version", '')],
    "r12_d16_terms_dropped": [('D16 a story position (Terms) past', 'D16 a story position past')],
    "r12_ec8_legacy_default_dropped": [('has its whole\n   lifecycle block filled with the defaults (UNSET, empty, OUTSIDE) before the load check runs, so D0 meets no missing field\n   but the position,', 'is D0,')],
    "r12_ec8_chapter_select_dropped": [(" Chapter select writes a valid\n   record before its first save for every entry positioned past C8-S16's commit, keyed to its entry scene's position,\n   not its chapter number (`storyline-lifecycle.md` Chapter select), so it never writes one D16 refuses.", '')],
    "r12_life_legacy_default_dropped": [(L, ' A save of a schema version before these fields has its whole record block filled with\nthe defaults before the load check runs (`storyline-axes.md` Edge Case 8), so the check meets a typed record: at\n`PRE_C8` it loads LEANING, and past a lock scene D16 refuses it.', '')],
    "r12_ac9_doc_clause_multi": [('documentation (`D17.prefix`), which has no\n   fixture', 'documentation (`D7.multi`, `D17.prefix`), which has no\n   fixture')],
    "r12_ac9_two_entry_dropped": [(', a two-entry\n   `retraction_log` (the R2 and R3 Faction retractions of (NONE, HEARTH, RELEASE), each consistent on its own)', '')],
    "r12_ac9_legacy_dropped": [(' Legacy: a save of the\n   previous schema version with no lifecycle block, defaulted before the check (Edge Case 8), gives `load_check()`\n   empty and `phase_of(…, true)` LEANING at `PRE_C8`, and exactly {D16} at `CH9`.', '')],
    "r12_ac9_equivalent_mutants_plural": [('except the documentation clause, which is listed as an equivalent mutant.', 'except the documentation clauses, which are listed as equivalent mutants.')],
    "r12_ac14_most_shared": [("A scene's *base* is `base_lines(scene)`, what it plays with no module selected", "A scene's *base* is the `scene_lines()` value most of the 24 IDs share")],
    "r12_ac14_keyed_family": [('whose `keyed_axis()` is `faction` or `deleted`;', 'whose `keyed_axis()` is `family`;')],
    "r12_ac15_zero_hit_pass": [('(a scan with zero hits is NOT\n    ASSESSED, never a pass)', '(a scan with zero hits passes)')],
    "r12_ac16_six_testers": [('12 new testers, judged alone', '6 new testers, judged alone')],
    "r12_ac16_all_testers_gated": [('(a) of the testers who played Act 1 themselves, at least 70%', '(a) at least 70% of testers')],
    "r12_ac16_early_stop": [(' A run is never stopped early or extended to reach the bar.', '')],
    "r12_ac17_voices_lines": [('makes `lock_arguments()` of the axis\n    the flag pushes contain an argument whose flag is that flag', 'makes the lock scene of the axis the flag pushes voice at least one argument line the route data keys to that flag')],
    "r12_observable_keyed_axis_dropped": [('| `keyed_axis(module_id)` | the axis whose value the route data keys a module to (`authority`, `faction`, `deleted`), `family` for a module keyed to the family, or `none` |\n', '')],
    "r12_runtime_types_dropped": [('AC15 is Logic (BLOCKING), a data scan; AC16 and AC17\nare Integration.', 'AC15-AC17 are advisory.')],
    "r12_rule8_not_damaged_dropped": [('with an ID stored\n   and the phase not DAMAGED the gate is open', 'with an ID stored the gate is open')],
    "r12_rule8_damaged_turned_back_dropped": [(' a DAMAGED record is turned back as a\n   data error whether or not it holds an ID (lifecycle S6);', '')],
    "r12_story_positions_mismatch": [('`ROOT`, `ROOT_LEFT`, `FINAL_AUTH_OPEN`', '`ROOT`, `FINAL_AUTH_OPEN`')],
    "r12_position_derived_on_load": [('never derived from the current scene file on load;', 'derived from the current scene file on load;')],
    "r12_protected_chapter_select_dropped": [(' chapter select past C8-S16 writing a valid record,', '')],
    "r12_oq20_adopted": [('Review exit criteria — adopted (user decision 2026-11-18', 'Review exit criteria — adopted (user decision 2026-11-17')],
    "r12_pm7118_misattributed": [('RELEASE needs staged verification (PM:7118)', 'RELEASE ends involuntary preservation (PM:7118)')],
    "r12_life_commit_position_dropped": [(L, ' Every checkpoint also\nstores the story position it reaches (`storyline-axes.md` Terms, Story position: the commit of C8-S13 writes\n`S13_DONE`, and so on), and a save made anywhere else stores the last position it has crossed (Y1-P1-T05).', '')],
    "r12_s6_predicate_dropped": [(L, 'The check is one predicate, not a list of callers (design review round 12): it runs before every scene\nchange whose target is a Root of Heaven scene, whoever requests it; on load, before any loaded state is applied; and\nbefore free travel unlocks the Root of Heaven region, which stays locked until the predicate passes. A new caller\ntherefore cannot skip it, and setting a chapter-unlock flag alone never opens the gate. ', '')],
    "r12_s6_chapter_select_path_dropped": [(L, 'the Chapter 10 scene chain and chapter select count as\nthis path', 'the Chapter 10 scene chain counts as this path')],
    "r12_chapter_select_dropped": [(L, '**Chapter select (user decisions 2026-11-17, design review rounds 12 and 13).** Chapter select is player-facing. It\nstarts a new record, never edits a loaded one, and each entry is keyed to the story position of its entry scene, not\nto its chapter number (round 13: "Chapter 8 - Ending", `main_menu.gd:655-662`, is a Chapter 8 entry whose\n`ch8_ending` comes after the locks and autosaves on load). An entry positioned before C8-S13 starts LEANING with the\ndefaults (position `PRE_C8`). An entry positioned past C8-S16\'s commit writes, as\none atomic checkpoint before its entry scene loads, a fixed valid record: `SL-SHARED-ARCHIVE-CHOOSE` (SHARED, ARCHIVE, CHOOSE; SHARED\nand CHOOSE appear in no invalid row), `lock_negotiated` = {faction, authority, deleted} (no lock vote was\nplayed, so none passed clean), `axis_revised`, `retraction_log` and `beats_played` empty, `root_phase` OUTSIDE, the\nmatching `AXIS*` and `lock_negotiated_*` mirror flags, and the story position of its entry scene (`S16_DONE` for a\nChapter 8 entry after the locks, `CH9` for Chapter 9 and for every entry into Root of Heaven). An entry into Root of\nHeaven then enters through the gate (T7). No entry is positioned inside the lock scenes (`S13_OPEN` to `S16_OPEN`).\nSo chapter select never writes a save the load check refuses, and its ending is\nBOUND without `sole_dissent`. Changing chapter select is protected story progression: the implementing story needs the\nuser\'s approval.\n\n', '')],
    "r12_chapter_select_record_invalid": [(L, '`SL-SHARED-ARCHIVE-CHOOSE` (SHARED, ARCHIVE, CHOOSE; SHARED\nand CHOOSE appear in no invalid row)', '`SL-YOU-HEARTH-RESTORE` (YOU, HEARTH, RESTORE; YOU and RESTORE appear in no invalid row)')],
    "r12_chapter_select_negotiated_partial": [(L, '`lock_negotiated` = {faction, authority, deleted} (no lock vote', '`lock_negotiated` = {faction, authority} (no lock vote')],
    "r12_chapter_select_family_wrong": [(L, 'its ending is\nBOUND without `sole_dissent`', 'its ending is SOLE without `sole_dissent`')],
    "r12_lac19_dropped": [(L, '- **L-AC19 Gate predicate and chapter select.** For each scene-change request whose target is a Root of Heaven\n  scene, issued from the Chapter 9 end, the Chapter 10 scene chain, world-map "Resume story", free travel and chapter\n  select, with a LEANING or PARTLY_LOCKED injected live record: `enter_root_of_heaven()` is TURNED_BACK and\n  `current_scene()` is not a Root of Heaven scene; with `ch10_unlocked` set and no ID stored, the free-travel Root of\n  Heaven region stays locked. Chapter select of Chapter 9 and of Chapter 10 from the main menu gives\n  `storyline_id()` `SL-SHARED-ARCHIVE-CHOOSE`, `record_field(lock_negotiated)` = {faction, authority, deleted} and\n  `load_errors()` empty for every save written before the first player input; for Chapter 10 the gate gives\n  ROOT_OF_HEAVEN. "Chapter 8 - Ending" gives the same record at `S16_DONE` with `load_errors()` empty for its\n  autosave. A chapter-select entry positioned before C8-S13 gives LEANING. *Blocked by:* Y2-PP-T17, Y1-P1-T05,\n  Y1-P1-T03.\n', '')],
    "r12_lac19_chapter10_turned_back": [(L, 'for Chapter 10 the gate gives\n  ROOT_OF_HEAVEN.', 'for Chapter 10 the gate gives TURNED_BACK.')],
    "r12_lac19_region_unlocks": [(L, 'the free-travel Root of\n  Heaven region stays locked', 'the free-travel Root of Heaven region unlocks')],
    # Design review round 13 (axes revision 13, lifecycle revision 9).
    "r13_purge_hearth_restored": [('| ch1_root_purge | authority:YOU | − | until:lock:authority | dialogue/ch1/aldric.dlg:57 (J) |', '| ch1_root_purge | faction:HEARTH | + | until:lock:faction | PRODUCTION_MASTER_2.1.md:663 (J) |')],
    "r13_discriminator_dropped": [('The discriminator, in one sentence:', 'In short:')],
    "r13_answerable_misquote": [('that "somebody must be accountable." (PM:636)', 'that "someone must be answerable" (PM:636)')],
    "r13_beats_cap_sixteen": [("`beats_played` one, the one entry's beat)", '`beats_played` sixteen)')],
    "r13_d0_membership_beats": [('which are checked for type only:', 'which are checked for allowed values too:')],
    "r13_ac15_nine_arcs": [('each of the ten arcs has at least', 'each of the nine arcs has at least')],
    "r13_arc08_secondary_dropped": [("| 08 | Kaito's False Sky | secret:CROWNLESS | faction:* |", "| 08 | Kaito's False Sky | secret:CROWNLESS | — |")],
    "r13_arc08_p5_dropped": [('Crownless and also pushes Faction in 1.0', 'Crownless only')],
    "r13_terms_exception_dropped": [('One exception to "never derived":', 'Also:')],
    "r13_knob_scope_one_place": [('Knobs are read in exactly two places', 'Knobs are read in exactly one place')],
    "r13_ec13_knob_scope_old": [('Knobs are read only where Tuning Knobs states.', 'Knobs are read only at C8-S16 and the gate.')],
    "r13_oq6_four": [('This GDD uses 3 of the 4 (Elara, Seraphina, Lyra);', 'This GDD uses the 4;')],
    "r13_oq13_pairwise_one": [('pairwise minimum of 2 scenes (rounds 11 and 12)', 'pairwise minimum of 1 scene (round 9)')],
    "r13_ec1_pm788": [('`AethelgardPrototype/scripts/chapter3/ch3_kaelthas_betrayal.gd:157-161`; Core Rule 11', 'PM:788; Core Rule 11')],
    "r13_formulas_example_d9_only": [('(D9 and D17: a valid\nrow is not `live_crisis`).', '(D9).')],
    "r13_rule3_two_minus": [('Authority three, all against YOU', 'Authority two, both against YOU')],
    "r13_lock_pass_example_purge": [('YOU with `ch1_root_first_edit` and `ch1_root_purge` set → NEGOTIATED', 'YOU with `ch1_root_first_edit` and `ch1_root_purge` set → CLEAN')],
    "r13_life_gate_open_id_only": [(L, 'true exactly when an ID is stored and the phase is not DAMAGED', 'true exactly when an ID is stored')],
    "r13_life_overview_damaged_dropped": [(L, 'stored, the locks not yet played, or a live DAMAGED record (a defect, turned back as a data error, S6); a save made', 'stored or the locks not yet played; a save made')],
    "r13_life_ngplus_position_dropped": [(L, ';\n`story_position` → PRE_C8. The story position is reset with the record because a new record left at a Story+ position\nwould be refused by D16 (design review round 13).', '.')],
    "r13_life_chapter_select_by_chapter": [(L, 'each entry is keyed to the story position of its entry scene, not\nto its chapter number', 'each entry is keyed to its chapter number')],
    "r13_life_ch8_entry_wrong_position": [(L, '(`S16_DONE` for a\nChapter 8 entry after the locks,', '(`PRE_C8` for a\nChapter 8 entry after the locks,')],
    "r13_life_lac14_pm3814_restored": [(L, "arc 09's flag and arc 05's Quest 30 flag", "`OLD_HOME_MESSAGE` (arc 09, PM:3814) and arc 05's Quest 30 flag")],
    "r13_life_lac15_position_dropped": [(L, ', the story position `PRE_C8`, `load_errors()` empty for\n  the first save of the new cycle,', ',')],
    "r13_life_lac19_ch8_dropped": [(L, ' "Chapter 8 - Ending" gives the same record at `S16_DONE` with `load_errors()` empty for its\n  autosave.', '')],
    "r13_life_legacy_derive_dropped": [(L, ' Such a save holds no story position, so the\ndefaulting step derives it once, by the order in `storyline-axes.md` Terms (Story position): the free-travel story\nscene, else the save\'s own scene, through the scene-to-id map, which holds no hub; else the chapter number. A\nChapter 8 save that no story scene places is left with no position, which D0 refuses (`D0.missing`).', '')],
    # --- review round 14 (2026-11-18): axes revision 14 / lifecycle revision 10 (scope frozen, Open Question 20)
    "r14_purge_pm663_restored": [('because Kaelen rewrites Aldric before he can say what it will cost', 'because a purge leaves Aldric alive without his agency, which PM:663 names as the condition of his support')],
    "r14_purge_consent_restored": [('a rewrite of Aldric whose cost Kaelen did not', 'a rewrite of Aldric without his consent, whose cost Kaelen did not')],
    "r14_oq10_resolved_restored": [('`ch1_root_purge` → YOU `−` rests on', 'Round 9\'s objection is resolved by revision 13; `ch1_root_purge` → YOU `−` rests on')],
    "r14_story_position_row_dropped": [("| story_position | enum |", "| story_position_note | enum |")],
    "r14_act1_pace_no_unset": [('| act1_pace | enum | UNSET, act1_pace_early', '| act1_pace | enum | act1_pace_early')],
    "r14_legacy_hub_in_map": [('which holds story scenes only and', 'which holds every scene and')],
    "r14_legacy_ch8_pre_c8": [('A Chapter 8 save that no mapped story scene places is left with no', 'A Chapter 8 save that no mapped story scene places is put at PRE_C8, with no')],
    "r14_legacy_position_missing_d0_restored": [('carries the\n  stored position on every save', 'maps every\n  save'), ('in this order: the save\'s', 'from the save\'s own scene through the scene-to-id map; a scene the map does not hold leaves the field missing, which D0 refuses. Order: the save\'s')],
    "r14_ac9_clause_list_dropped": [('The clause ids are exactly:', 'The clause ids include:')],
    "r14_ac9_d7_fixture_old": [('the D7 new-value fixture is (SHARED, ARCHIVE, RELEASE)', 'the D7 new-value fixture changes a retraction entry\'s `new` and renames its beat to match, e.g. (SHARED, ARCHIVE, RELEASE)')],
    "r14_ac9_new_game_dropped": [('New game: the first save of a new game', 'A later save')],
    "r14_ac9_d0_element_fixture_dropped": [('a\n   non-string `beats_played` element (`D0.element`), ', 'a\n   ')],
    "r14_ac11_mirror_restored": [('has Kaelthas in `companions_of(m)`.', 'has Kaelthas in `companions_of(m)`, and its result is the same for the three Faction values of a family\'s fixtures except for modules `module_keys()` keys to a Faction mirror flag (`AXIS2_*`).')],
    "r14_ac11_observable_dropped": [('| `companions_of(module_id)` | the companions the route data places in the party or gives a line in that module |\n', '')],
    "r14_ac15_config_data": [('AC15 is Logic (BLOCKING), a data scan;', 'AC15 is Config/Data;')],
    "r14_seed_secret_push_dropped": [('pushes `secret:<route>` with direction `0`', 'is left out of the map')],
    "r14_d1_order_dropped": [("an ID while the record's axes form an invalid row (`D1.invalid_row`)", 'the ID of an invalid row (`D1.invalid_row`)')],
    "r14_d0_clause_ids_dropped": [('the wrong type (`D0.element`), a set holding', 'the wrong type, a set holding')],
    "r14_oq21_dropped": [('21. **Main-story seeds', '21. **Later seeds')],
    "r14_rule2_main_story_dropped": [('and so do main-story choices after Act 1', 'and so may later choices')],
    "r14_oq20_not_adopted": [('Review exit criteria — adopted', 'Review exit criteria — proposed')],
    "r14_life_legacy_hub": [(L, 'which holds no hub; else', 'which holds every scene; else')],
    "r14_life_inputs_no_position": [(L, '`beats_played`, `story_position`) and the seed', '`beats_played`) and the seed')],
    "r14_life_ngplus_position_not_field": [(L, '`story_position` → PRE_C8.', 'the story position → PRE_C8.')],
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
