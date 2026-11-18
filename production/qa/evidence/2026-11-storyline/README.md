# Y1-P0-S06a evidence: the storyline axes GDD

Story: `production/epics/y1-p0-stabilize/story-s06a-storyline-axes.md`. GDD: `design/gdd/storyline-axes.md`.
Research input: `research_draft.md` (narrative-director, sources cited per row).

## Decisions taken while writing (user)

- 2026-11-08, changeset approved ("Yes, the whole set"): the GDD, this folder, one Story Bible line.
- 2026-11-08, headings: "8 required in order, extras allowed" — Summary, Cross-References and Open Questions kept;
  Visual/Audio, Game Feel and UI Requirements dropped as N/A for a narrative system (small AC-1 deviation).
- 2026-11-08, "Confirm 24 + R1-R3": `valid_count: 24`, rules R1-R3 quoted from the production master (PM:710-723);
  Witness Protocol transforms YHR (in scope, Consent), Crownless NAL and First Wake NCL (reserved, post-1.0).
- 2026-11-08, "All four, note relationships": every valid row lists all four companions; absence comes from
  relationship flags (PM:11302).
- 2026-11-08, "axis:* wildcard; 03 → Witness": arcs 02, 04, 07, 10 record `axis:*`; arc 03 secondary `secret:WITNESS`.
- 2026-11-08, "Mark (J), review in section": the seven judgement-call seed directions stay, marked (J).
- Audit 4 lists 23 flags (the story said 22); the GDD and checker use 23.

## Section approvals (AC-1)

| Section | Date | User's words |
|---|---|---|
| Header, Summary, 1 Overview | 2026-11-08 | "Approve, write it" |
| 2 Player Fantasy (+ pillar line corrected to DESIGN_PILLARS.md) | 2026-11-09 | "Approve, write it" |
| 3 Detailed Design (rules, states, 27 combinations, secret rows, 23-flag seed map incl. the 7 (J) rows, 12 arcs, composer record) | 2026-11-09 | "Approve, write it" |
| 4 Formulas (ID, validity, family, counts) | 2026-11-09 | "Approve, write it" |
| 5 Edge Cases (9 cases; PM line refs corrected to 706, 6990-6991) | 2026-11-09 | "Approve, write it" |
| 6 Dependencies (bidirectional obligations recorded) | 2026-11-09 | "Approve, write it" |
| 7 Tuning Knobs (5 knobs, fixed-by-design list) | 2026-11-09 | "Approve, write it" |
| Cross-References, 8 Acceptance Criteria (9), Open Questions (7) | 2026-11-09 | "Approve, write them" |
| Revision 1 after /design-review (NEEDS REVISION): Detailed Design, Formulas, Edge Cases, Tuning Knobs, Cross-References, Acceptance Criteria, Open Questions, Overview line | 2026-11-09 | "Approve, write it" |

## Design review round 1 (2026-11-09)

- Verdict NEEDS REVISION (game-designer, systems-designer, narrative-director, qa-lead; creative-director synthesis); log `design/gdd/reviews/storyline-axes-review-log.md`.
- User decisions for the revision: Aldric "Purge Hearth+, spare neutral, kill Hearth−" (re-approval of the misread row); Authority seeds "All five as proposed"; overturnable "Lock tokens"; extras: Data Wraith remap, arcs 12 and 03, warning + 27 wording, drop the tie-break.
- The seed map is now 26 flags; `until:lock:<axis>` tokens replace `until:<flag>` (deviation from the story's AC-3/AC-7 wording, approved).

## Design review round 2 (2026-11-10)

- Verdict NEEDS REVISION (same four specialists; creative-director synthesis); log entry with findings in
  `design/gdd/reviews/storyline-axes-review-log.md`.
- User decisions for revision 2: include the PM:8791 post-boss reconsideration (one axis, valid rows only, at most
  once, never for a secret storyline, only when a data-defined trigger holds — empty by default); renegotiation sets
  a composer-read `axis_revised_<axis>` flag, no weight; in-fiction faction red lines replace the system warning;
  a valid row cannot be renegotiated; P5 met in 1.0 by nine arcs (stated in the GDD); Aldric purge/kill seeds kept
  as approved and marked (J) with the inference stated; `ch2_seraphina_cautious` → direction `0` (no trust change
  in `command_hall.dlg`), `kill_unsure` / `wraith_destroyed` kept, objections in Open Question 10.
- Changeset approved ("Yes, the whole set"): GDD revision 2 (all sections touched; ACs 13 → 15), hardened checker,
  this section, the logs below.
- Checker hardening: rule text on its PM line; Formulas `invalid()` set = rules table; valid-row sources are their
  own `# STORYLINE` heading; prose family split and `reachable_1_0`; secret foundations per PM:8784 and
  prerequisites = the PM "Required flag" lists; seed pushes/direction pinned to the approved values (a change is a
  design decision); timing rows `0`; seed sources resolve (`.dlg` allowed); flags must occur outside `#` comments;
  every row lists all four companions; side-arc `pm_line` in arc order; composer axis fields allow UNSET;
  `storyline_id(A, F, D, I)` signature; family counts and invalid-row count derived instead of hard-coded.
- Evidence: `check_pass.log` (real GDD, PASS) and 24 `mutation_*.log` (8 re-run from revision 1, qa-lead M1-M3,
  and one per new check), all FAIL as expected. Reproduce with
  `python -I -B run_mutations.py <repo_root> <scratch_dir>` (mutated copies go to the scratch dir).
- Not mutation-tested: the comment-stripping in `flag_exists` (needs a mutated game tree, not a mutated GDD).

## Design review round 3 (2026-11-10)

- Verdict NEEDS REVISION (10 blocking, 8 recommended, all in the lifecycle layer); log entry in
  `design/gdd/reviews/storyline-axes-review-log.md`.
- User decisions for revision 3: reconsideration option c (Faction or Deleted only, never Authority; family never
  changes); the seed clean-vs-negotiated pass as a boolean flag test (`lock_pass`, `lock_negotiated_<axis>`);
  Consent: Kaelen keeps technical execution only, any later Root act needs the witnesses again.
- Approved with the changeset ("Yes, the whole set"), as derived calls: the ID is stored when the coalition holds
  (snapshot, so knob patches cannot flip it); `SEVEN_WITNESSES_AVAILABLE` (and each route's last "Required flag")
  is the invocation record, split into `secret_unlock_flag`; C8-S16 never offers an invocation (last offer
  prerequisite is PM:7586-7588); Story+ follows a reconsidered ID; Kaelen is the executor, not a witness.
- Revision 3: Core Rules 1-13 rewritten around the lifecycle; `storyline_state` with States T1-T12; gate check on
  every entry path; per-axis retraction table; red lines labelled new content; `danger` column (each route's
  "Primary danger" line); Observables table; runtime ACs 5-21 with *Blocked by:* tags; citation fixes.
- Checker hardening: `danger` column; prerequisites + unlock flag = the PM "Required flag" list, ≥ 2 offer
  prerequisites, disjoint lists; `transform()` map and both family maps; `storyline_id` body reads no timing, pace or
  companion input; the Counts block's arithmetic and values; Core Rules 1-13 with their titles; States table and
  T1-T12 over known states; composer `storyline_state`, `family`, `lock_negotiated` vocabularies; each runtime AC
  has known blocking stories and uses only listed observables; AC numbering contiguous; more stale strings.
- `run_mutations.py` now takes `--gdd` and passes `--root` / `--bible` explicitly (so it can test a draft outside the
  repo). Evidence: `check_pass.log` (PASS) and 51 `mutation_*.log` (24 retargeted from rounds 1-2, 27 `r3_*`), all
  FAIL as expected.

## Design review round 4 (2026-11-10): checker rework

- `storyline-axes.md` revision 4 keeps the static core byte-identical and moves the lifecycle to the new
  `design/gdd/storyline-lifecycle.md`. The round-3 checker failed on revision 4 (12 problems: `storyline_state`,
  `final_reconsidered`, Core Rules 1-13, States/T1-T12, `renegotiations*`, and `secret_invoked`, which was a
  round-2 stale string and is now a composer field again). A QA review also found 19 lifecycle mutations the old
  checker let through, because it pinned names, not bodies.
- **What is checked now** (`check_storyline_axes.py`, new `--lifecycle PATH`; derived = computed by the checker,
  pinned = a constant in the checker, so a change is a design decision):
  - axes AC1-AC2: as before, plus the seed map's "(26 flags)".
  - axes AC3: as before, plus the composer record has exactly its 17 rows, each with pinned type, allowed values
    (derived from the vocabularies: phases, axes + UNSET, families + RESERVED/NO_FAMILY, secret routes, the three
    `act1_pace_*` timing seeds) and writer (axis writers built from the lock scene per axis + "Never the final
    authorization").
  - axes AC4: pinned bodies of `storyline_id`, `prereqs_met`, `lock_pass`, `storyline_phase`, `family`; the shape
    of `invalid()` (`∈`); the results `storyline_phase` and `family` can return equal the record's vocabularies;
    the `lock_pass` and `storyline_phase` examples recomputed (seed map / phase semantics); Core Rules 1-12 titles
    and pinned key sentences (Rule 4's three red-line pairs and Rule 5's "six for R1, five for R2 or R3" derived from
    the rules table); no `may/can/could/might` in Rules 7 and 9; invariants I1-I8 pinned row by row; the phase table
    pinned; Tuning Knobs exactly the four knobs, enable defaults derived from the secret table scopes, none of
    `invalid_combinations` / `reconsideration_triggers` / `faction_negotiation_allowed` / `reconsider_targets`, and
    the pinned "Not knobs" items; Counts incl. `renegotiation_offers = 6 + 5 + 5 = 16` (each term computed from
    `invalid()` per rule); Edge Cases 1-16 and Edge Case 16's four damaged records; AC1-AC12 contiguous; runtime
    AC5-AC12 call only the axes Observables table; AC5's 64/128/24/37/3 derived.
  - lifecycle document-level AC: headings; T1-T13 pinned cell by cell (from, event, guard, to, effects), every
    from/to a phase of the axes table, no transition from VALIDATED/FIXED/FINAL to an earlier phase or to
    CRISIS/DEFERRED, every phase reachable from LEANING, CRISIS and DEFERRED each have a knob-free way to VALIDATED
    (I5), the gate event starts from every phase except CRISIS exactly once (I4); the crisis offer table equals
    `crisis_offers` computed from `invalid()`, `defer:WITNESS` only on the row Witness transforms; the red-line table
    names exactly R1-R3 with pair and speaker derived from each combination; the gate outcome table derived from the
    axes phase table's gate column, its `(Tn)` references matching the transitions; the Formulas block pinned and
    its offer-count sentence derived; "16 beats" and the retraction table's axes; the Inputs fields and the NG+
    reset (same field set, defaults derived from the field types); pinned sentences (crisis cannot be left; no
    reconsideration; no other transition; no knobs of its own); Edge Cases 1-8; L-AC1-L-AC18 contiguous, each with
    known blocking stories and only lifecycle observables; L-AC3/4/6/16 numbers derived; the Validation note's
    24 + 1 + 16 + 2 + 18 = 61 with every term derived (valid rows, 1.0 secret routes, offers, 2 per deferral route,
    S7's paths × storable phases).
  - both docs: every "the six (R1) renegotiations/offers" phrase states the computed R1 count; old stale strings
    (C8-S17 exempt in the lifecycle doc, where it is the real Revolution Name scene, PM:7155); revision-3 vocabulary
    (`storyline_state`, `final_reconsidered`, `reconsider_targets`, `reconsideration_triggers`, `GATE_CRISIS`,
    `crisis_endured`, `renegotiations_valid`, `faction_negotiation_allowed`, `invalid_combinations`) everywhere
    except `storyline-axes.md` Open Questions.
- `run_mutations.py`: edits may target the lifecycle doc (`("life", old, new)`), controls (expected PASS) are
  supported, and `--lifecycle` / `--log-dir` were added.
- **Result** (2026-11-10): real docs `RESULT: PASS (0 problems)`; 124 mutations, all FAIL as expected; 1 control
  PASS as expected; 0 unexpected. Reproduce with
  `python -I -B run_mutations.py <repo_root> <scratch_dir>` (absolute `<repo_root>`).
- **Round-4 mutations** (75, all FAIL; logs `mutation_r4_*.log`). QA survivors re-expressed: `r4_t4_to_validated`,
  `r4_t13_to_leaning`, `r4_rule7_inverted`, `r4_rule9_reconsideration`, `r4_composer_authority_final_auth`,
  `r4_knob_reconsideration_triggers`, `r4_knob_faction_negotiation`, `r4_validated_gate_turns_back`,
  `r4_edge_case_16_deleted`, `r4_crisis_r2_gains_offer`, `r4_prereqs_met_dropped`, `r4_not_invalid_inverted`,
  `r4_lock_pass_swapped`, `r4_phase_branch_order`, `r4_lac_no_blocked_by`, `r4_lac_unknown_observable`,
  `r4_validation_total`, `r4_red_line_pair`, `r4_invariant_deleted`, `r4_stale_storyline_state`. One per new
  check: transitions `r4_t7_event_changed`, `r4_t6_guard_dropped`, `r4_t5_effect_dropped`, `r4_t14_backward_added`,
  `r4_t8_knob_guard`, `r4_no_other_transition`; Core Rules `r4_rule7_exception_appended`, `r4_rule9_offers_one`,
  `r4_rule5_scene_may_end`, `r4_rule5_offer_count`, `r4_rule3_counts_seeds`, `r4_rule4_pair_swapped`; composer
  `r4_composer_deferred_cleared`, `r4_composer_family_vocab`, `r4_composer_final_reconsidered`; knobs
  `r4_knob_default_flip`, `r4_knob_dropped`, `r4_not_knobs_lock_pass_dropped`; phases / gate `r4_phase_row_deleted`,
  `r4_gate_outcome_wrong`, `r4_gate_t_ref_wrong`; invariants / edge cases `r4_invariant_rule_ref`,
  `r4_edge_case_16_item_dropped`; formulas `r4_family_reserved_changed`, `r4_invalid_not_member`,
  `r4_lock_pass_example_wrong`, `r4_phase_example_wrong`; counts / ACs `r4_counts_offers_wrong`,
  `r4_counts_offers_terms`, `r4_ac5_case_count`, `r4_seed_intro_count`, `r4_ac8_lifecycle_observable`; lifecycle
  `r4_crisis_r1_loses_offer`, `r4_crisis_r3_defer`, `r4_red_line_speaker`, `r4_red_line_extra_row`,
  `r4_retraction_beats`, `r4_life_formula_invalid_dropped`, `r4_life_offer_count_sentence`,
  `r4_life_crisis_leavable`, `r4_life_s8_reconsideration`, `r4_life_own_knob`, `r4_ng_reset_default`,
  `r4_ng_reset_field_dropped`, `r4_life_number_word`, `r4_life_edge_case_gap`, `r4_life_heading`,
  `r4_lac_axes_observable`, `r4_lac_unknown_story`, `r4_lac_number_gap`, `r4_lac6_runs`,
  `r4_validation_term_consistent`, `r4_validation_matrix`, `r4_stale_storyline_state_axes`, `r4_stale_gate_crisis`.
  Control: `r4_control_open_questions_vocab` (revision-3 words in axes Open Questions) PASS.
- **Kept from rounds 1-3**: 49. Retargeted to revision-4 text (same name, same intent): `r3_counts_false_chain`,
  `r3_counts_line_dropped` (Counts alignment), `r3_deleted_core_rule_8` (the rule is now number 7),
  `r3_core_rule_retitled` (Rule 6), `r3_state_renamed` (phase table), `r3_transition_unknown_state` (lifecycle T13),
  `r3_transition_dropped` (lifecycle T9), `r3_composer_state_vocab` (`storyline_phase`), `r3_composer_field_dropped`,
  `r3_ac_blocked_unknown` (AC8), `r3_ac_unknown_observable` (AC10), `r3_ac_number_gap` (AC12).
- **Retired** (target removed structure): `r3_counts_wrong_value` (`renegotiations_valid` no longer exists; replaced
  by `r4_counts_offers_wrong`), `r3_stale_secret_invoked` (`secret_invoked` is a legitimate field in revision 4).
  Their old logs are left in place, unrefreshed.
- **Logs not refreshed this round**: `check_pass.log` and the 51 round-1-3 `mutation_*.log` still show revision 3;
  this round only wrote new `mutation_r4_*.log` (the full run's logs went to a scratch dir via `--log-dir`).
  Re-running without `--log-dir` refreshes them.
- **Still NOT checked**: prose outside the pinned sentences (Overview, Player Fantasy, Terms, scene contracts
  S1-S3/S5/S6, Consent variants, the retraction table's withdrawn items and sources); Edge Case bodies other than
  axes 16 (numbering only); L-AC bodies beyond blocking stories, call names and the derived numbers; the
  observables' return descriptions; Dependencies and Cross-References; PM line references in prose (only table
  source cells are resolved); the seven `storyline_id` and the `family` examples (not recomputed); the lifecycle
  `signpost` / `last_chance_offers` formulas are pinned, not executed; backticked record fields read directly in
  L-ACs (`lock_negotiated`, `axis_revised`, `witness_deferred`, `secret_invoked`) — only `name(` calls are checked
  against the Observables table; and, as before, the comment-stripping in `flag_exists`. Pinned writers and
  sentences make harmless rewording FAIL: that is intended (a change is a design decision), not a defect.

## Design review round 5 (axes) and round 1 (lifecycle), 2026-11-10: revision 5 checks

- Revision 5 of `storyline-axes.md` keeps the static core unchanged (27 rows, R1-R3, counts, seed map, arcs, the
  five formula bodies, invariants I1-I8, phase table, knobs); the lifecycle document got its revision 1. The
  round-4 checker failed on them with 21 problems, every one a pin the review asked to change (composer fields,
  Edge Case 16, AC count, T5/T7/T8 effects, T14, the lifecycle Formulas block and two pinned sentences, Edge Case
  count, the Validation note terms). It also caught one real error in the draft: the lifecycle said R2 and R3
  "share four offers"; computed from `invalid()` they share five (four beat ids collided under the old
  `retract_<axis>_<old>_<new>` format because the Faction swap's old value differs). Fixed in the document.
- **New or changed checks**:
  - axes: composer record now 20 rows (`retraction_log`, `beats_played`, `witness_mandate` with
    UNDECIDED/MET/FAILED); Edge Case 16's seven damaged records pinned, plus the "compares and never rewrites,
    reads no knob" and "T8 history is not damage" sentences; Core Rule 3 (`sole_dissent`, user Q1), Rule 6
    (Chapter 10 secret scene only on `SL-SECRET-T`) and Rule 10 (C10-S15 only on `SL-SECRET-WITNESS`; the vote can
    fail; ID and family unchanged, user Q2) key sentences; AC1-AC15 contiguous; a new `check_protected`: the
    Dependencies' protected-touchpoints table names exactly the areas the "Do not modify ..." line of
    `AethelgardPrototype/AGENTS.md` lists (read from that file, not pinned here).
  - lifecycle: T1-T14 pinned (T14 = legacy-save catch-up; T5/T7/T8 effects name their beats); the Formulas block
    with the `crisis_offers` domain guard, the reordered `signpost` (HIDDEN only for no lead or a reserved
    disabled route; CLOSED for disabled, other ID stored, or an unreachable lead) and `witness_mandate`; derived
    beat checks: `retract_<rule>_<axis>_<new>` gives 16 distinct ids, "R2 and R3 share five offers" computed, the
    six `gate_retcon_*` ids equal the Witness row's renegotiations (user Q3); pinned sentences for the red-line
    witness clause (user Q4), S9's gate on the stored ID and its two limits, the gate keeping all six
    renegotiations, the history rule, the NG+ "new record" statement, the saved retractions and beats, and the
    T14 exception to "loading fires no transition"; NG+ reset default `witness_mandate` → UNDECIDED; Edge Cases
    1-11; L-AC19's "six R1 offers" derived; the Validation note is now 24 + 1 + 16 + 1 + 6 + 18 = 66 (gate
    invocation and one gate run per R1 renegotiation added) and must compare the expected *triple* (phase, ID,
    gate outcome).
- `run_mutations.py`: 10 round-4 mutations retargeted to revision-5 text (same name, same intent):
  `r4_t5_effect_dropped`, `r4_edge_case_16_deleted`, `r4_crisis_r3_defer`, `r4_ng_reset_field_dropped`,
  `r4_life_number_word`, `r4_lac_no_blocked_by`, `r4_lac_unknown_observable`, `r4_validation_total`,
  `r4_validation_term_consistent`, `r4_validation_matrix`. 33 new `r5_*` mutations, one per new pin or derived
  check; each was confirmed to fail on the check it targets, not incidentally.
- **Result** (2026-11-10): real docs `RESULT: PASS (0 problems)`; 157 mutations, all FAIL as expected; 1 control
  PASS; 0 unexpected. All logs in this folder were refreshed by this run (`check_pass.log`, every
  `mutation_*.log` named in `run_mutations.py`); the two retired round-3 logs are unchanged.
- **Still NOT checked** (in addition to the round-4 list): the Consent variants table's rows and the S5 deferral
  scope table (prose tables, not pinned); the PM line numbers cited in prose; the gate retcon history-rule flag
  list; the `witness_threshold` range; the L-AC14/L-AC17/L-AC20 bodies beyond call names.

## Design review round 6 (axes) and round 2 (lifecycle), 2026-11-10: revision 6 / lifecycle revision 2 checks

Scope: the blocking findings of both review logs' latest entries plus the user's decisions D1-D4 (FAILED vote not
executed, Kaelen stands down; T14 cut to a dev-fixture migration; deferral kept on probation; `witness_threshold`
fixed at 5, the player choosing the witnesses in Secret Quest 09, stances shown). Round-6 RECOMMENDED items were
not applied; they are listed in `storyline-lifecycle.md` Open Question 7.

- `check_storyline_axes.py`:
  - axes: the phase table and `PHASES` gain DAMAGED (never gated, never a transition's source or target); FINAL's
    meaning covers the stand-down; the `storyline_phase` body is damaged-first, FINAL and FIXED need a stored ID;
    `py_phase` returns DAMAGED for the D4/D8/D9 records decidable from six fields, and the doc must give a DAMAGED
    example; Edge Case 16 is pinned as items D1-D16 (text and numbering), with derived cross-references (Edge
    Case 6 cites the exclusive-group item D15, Edge Case 8 and Core Rule 8 the pre-axes item D16, AC9 covers
    "(D1-D16)" and names D9 for the CRISIS fixture); Edge Case 8's "is unsupported and does not load" pinned; the
    composer record gains `witness_seats` (seat vocabulary pinned in PM:8697-8703 order) and `witness_dissenters`,
    and `root_phase`'s writer covers the stand-down; Core Rules 3, 6, 8, 9 and 10 gain pinned sentences; an
    over-promise guard: four sentences required, five phrases ("colours ally lines", ...) forbidden.
  - lifecycle: T6 (disclosures), T7 (no `SEVEN_WITNESSES_AVAILABLE` guard; sets it), T13 (guard on
    `witness_mandate`) and the new T14 stand-down pinned; the gate DEFERRED outcome; the Formulas block with
    `witness_threshold = 5`, `witness_dissenters` and the gate invocation without the unlock flag; 18 new pinned
    sentences (the C9-S19 window, the save window and checkpoint, no runtime catch-up, the stand-down, the seats,
    stances and content rule, the vote written once, the threshold, the cut order); the S5 and Consent variants
    tables pinned row by row; the four disclosure ids in order; the S9 seats equal the record's; the legacy flags
    must be listed in the Dependencies row and occur in the code lines it cites (read from the files); L-AC key
    phrases for L-AC5, 7-10, 13-16 and 19-24; L-AC14's MET/FAILED split derived from the threshold; L-AC23's beat
    counts derived; L-AC7's deferral beats equal the S5 table's; "offers() is empty" / "offers nothing" forbidden
    in the L-ACs (they cannot fail); Edge Cases 1-12; the Validation note is 24 + 1 + 16 + 1 + 6 + 12 = 60 with the
    `world_map` path's 6 cells blocked and uncounted, and its pass rule pinned for every run, including the
    refused `load` cells; stale strings `consent_failed_mandate`, `failed-mandate`, `authorized over dissent` and
    the catch-up wording.
- `run_mutations.py`: 23 earlier mutations retargeted to the revised text (same name, same intent); 60 new `r6_*`
  mutations: qa-lead's round-6 survivors re-expressed (`r6_qa_*`: threshold range and prose, L-AC14 inequality and
  range, the S6 window, L-AC20, L-AC9's DEFERRED outcome, L-AC15 WITHDRAWN, a Consent row deleted, a `deferral_*`
  id renamed, S9 stripped of `witness_mandate`, L-AC19's retcon beat, Core Rule 8 "is stranded", Edge Case 8's
  body) and one per new pin or derived check. Each was confirmed to fail on the check it targets, not
  incidentally (first FAIL line of every `mutation_r6_*.log`).
- **Result** (2026-11-10): real docs `RESULT: PASS (0 problems)`; 217 mutations, all FAIL as expected; 1 control
  PASS; 0 unexpected. `check_pass.log` and every `mutation_*.log` named in `run_mutations.py` were refreshed.
- **Still NOT checked**: the PM line numbers cited in prose (other than the tables the checker resolves); the
  witness candidate data and the S9 content rule (data that does not exist yet, Y2-PP-T17); the cut order's effect
  on the ACs; producer sign-off (pending, a person's decision); the gate retcon history-rule flag list; L-AC17's
  body.

## Design review round 7 (axes, lean mode), 2026-11-10: revision 7 / lifecycle revision 3 checks

Scope: the two blocking findings of the round-7 review plus three recommended items the user folded in (user
decisions 2026-11-10: the seven-seats guard is not a tripwire event; `phase_of` takes a `loaded` argument; fold in
the D2/D3 labels with the D16 precondition, the record-authoritative rule, and AC14's baseline with the concept cut
order). No specialists ran (`--review lean`). The other round-7 RECOMMENDED items are logged in the axes review log.

- `check_storyline_axes.py`:
  - the `storyline_phase` body is pinned as `storyline_phase(record, loaded)` / `damaged(record, loaded)`; `py_phase`
    takes `loaded` and applies D9 only when it is true; the phase examples are read per "Example(s) (...):" label
    (`loaded` true by default, `loaded false` for the in-play example) and an in-play CRISIS example is required;
  - T7's guard is pinned as "WITNESS enabled; prerequisites met, seven seats saved";
  - new pinned sentences: Core Rule 3 (the record is authoritative, flags are mirrors), Core Rule 6 (`WITNESS_SEATS`
    is set in the step that saves the seventh seat; `prereqs_met(WITNESS)` also needs seven seats), Core Rule 8 and
    Edge Case 8 (the save refusal's precondition), Edge Case 16 (the D16 precondition), L-AC21 (six seats);
  - `check_revision7` pins the AC9 wording, the Observables row `phase_of(record, loaded)`, the `prereqs_met` seats
    clause, AC6's six-seat case, AC14's baseline and Open Question 13, and forbids the old all-pairs AC14 and the
    undefined labels `D2` and `D3` in Tuning Knobs and Open Question 7.
- `run_mutations.py`: 3 mutations retargeted to the revised text (`r5_ac14_unknown_observable`,
  `r6_phase_final_before_damaged`, `r6_t7_guard_needs_flag`); the log of `r6_phase_example_crisis_loadable` was
  refreshed because its failure message now names `loaded`; 16 new `r7_*` mutations, one per new pin (first FAIL line of each `mutation_r7_*.log` names the check it targets).
- **Result** (2026-11-10): real docs `RESULT: PASS (0 problems)`; 233 mutations, all FAIL as expected; 1 control
  PASS; 0 unexpected. `check_pass.log`, the four retargeted logs and the 16 `mutation_r7_*.log` files were refreshed;
  the other logs were not regenerated (their verdicts are unchanged in the run).
- **Still NOT checked**: whether Secret Quest 09 is actually authored to set `WITNESS_SEATS` with the seventh seat
  (a Y2-PP-T17 content fact); the mirror rule for the `AXIS*`, `axis_revised_*` and `lock_negotiated_*` flags has no
  divergence test until FlagRegistry exists; AC14's baseline reading is an interpretation awaiting the user's
  confirmation (Open Question 13).

## Design review round 9 (2026-11-11): axes revision 9 / lifecycle revision 5 checks

Revision 8 (round 8: T13 guard, Edge Case 16 D17) was never committed and had no README section; its two checker
pins carried into this round. User decisions 2026-11-11:

- Witness Protocol moves post-1.0 with Crownless and First Wake; the three are designed later as one mechanism
  (axes Open Question 15). Removed: the R1 deferral, DEFERRED and LAST_CHANCE, gate renegotiation, the invocation,
  the witness vote (threshold, seats, dissenters, mandate), the stand-down, the Consent variants, the deferral
  disclosures, the R1 red-line witness clause, and the `gate_retcon_*` / `deferral_*` / `invoke_witness` beats. Record
  fields `witness_deferred`, `secret_invoked`, `witness_seats`, `witness_dissenters`, `witness_mandate` are gone.
- `secret_route_enabled.WITNESS` defaults to false; `family()` maps all three `SL-SECRET-*` ids to RESERVED (no
  CONSENT in 1.0); `reachable_1_0 = 24 + 0 = 24`. New invariant I9 (one atomic checkpoint per transition).
- Lifecycle: T1-T9 with checkpoints, a 3-row gate table, S1-S7, 6 edge cases, L-AC1-L-AC18. Axes: AC1-AC16 (AC16 is a
  playtest), Observables table changed, Edge Case 16 with D2-D5 and D10-D13 retired as single entries.
- Process: the next review runs against a non-shipping reference model (axes Open Question 16).

**What the checker is.** Document lint (Config/Data, advisory): it proves that the text matches constants pinned in
the checker or values it derives from other parts of the text. It does not show that the state machine is correct;
that is the reference model of axes Open Question 16.

**Checks removed** (their material no longer exists): the deferral row, DEFERRED/LAST_CHANCE phase and gate rows,
T6-T14 (old numbering), the S5 deferral-scope and Consent-variant tables, the disclosure ids, the S9 seats, the
witness threshold and vote arithmetic (L-AC14), the gate-retcon beats, the stand-down line, the old L-AC5-L-AC24 key
phrases, Core Rule 5/6/9/10 witness sentences, Edge Case 16 D2-D5 and D10-D13 bodies, the seven-seats `prereqs_met`
clause.

**Checks replaced** (same property, new form): no deferral offer → every crisis-offer row holds only `revise:*`
offers and Core Rule 5 says no secret-route offer exists in 1.0; enable defaults derived from scopes → plus every
enable knob is false, covers all three routes and is "never enabled while `family` would be RESERVED";
`family()` → CONSENT → all three secret ids → RESERVED, CONSENT neither in `family()` nor in the composer vocabulary;
the secret table → each row post-1.0 with a pinned reserved family cell; invariants I1-I8 → I1-I9; phase table,
composer record (17 rows), formula bodies (`storyline_phase(record, loaded, flags, position)`), Core Rules 5-10 and
Edge Case 16 → re-pinned to revision 9; `py_phase` → five fields, also decides D1 and D17's lock-order clause; AC9's
"(D1-D16)" → its active-item list and multi-clause list, derived from Edge Case 16; R1's offer count is derived from
`invalid()` (`odd_rule`), no longer from the Witness route.

**Checks added**: AC3's field list = the composer record; AC1-AC16 with each runtime AC's blocking stories pinned
(AC11: Y2-PP-T17; AC15: Y1-P1-T03); the axes and lifecycle Observables tables pinned row by row; AC4's I1-I9 / 1-12 /
four knobs derived; AC5's per-route rows derived from the secret table; AC14 and AC16 key phrases; the document-level
AC label; every "I1-In" in both docs names the invariant count; each doc's Dependencies row names the other's
revision; lifecycle Inputs = the fields the axes doc says the record stores; the checkpoint set (I9) equal in the
transition table, the commit and save rule and L-AC6, T4 "no checkpoint"; the commit and save sentences; the gate
table has exactly its 3 rows; the content-scope counts (16, 3, 1, 3) derived; S5's unlock flags and lifecycle Edge
Case 5's Witness leads derived from the axes knobs; L-AC2's Faction fixtures recomputed with `lock_pass`; the
Validation note 24 + 16 + 10 = 50; the removed identifiers (`witness_*`, `secret_invoked`, `LAST_CHANCE`, `DEFERRED`,
`defer:`, `invoke:`, `gate_retcon`, `deferral_`, `stand_down`, `consent_unauthorized`, `scene_variants`, ...) are
forbidden everywhere in both docs, Open Questions included.

**One explicit exception**: axes AC5 names `transform()` ("so a swapped `transform()` fails"), a formula, not an
observable. The checker accepts that exact phrase only (and requires it); reported to the author as a doc nit.

- `run_mutations.py`: 54 mutations retired (they targeted removed material: the deferral, invocation, witness vote,
  seats, stand-down, Consent tables, disclosures, gate retcon, `witness_*` fields and the old T13/T14 guards):
  `r3_consent_family`, `r4_composer_deferred_cleared`, `r5_composer_mandate_vocab`, `r5_ec16_old_item`,
  `r5_ec16_t8_history_dropped`, `r5_rule10_c10s15_flag_gate`, `r5_rule10_threshold_cannot_fail`, `r5_t14_dropped`,
  `r5_t8_retcon_dropped`, `r5_signpost_hidden_first`, `r5_mandate_unanimity`, `r5_red_line_clause_dropped`,
  `r5_gate_keeps_authority_only`, `r5_retcon_beat_missing`, `r5_history_as_current`, `r5_s9_flag_gate`,
  `r5_s9_failed_changes_id`, `r5_ng_mandate_default`, `r5_lac19_count`, `r5_validation_gate_terms`, the ten
  `r6_qa_*` threshold/window/vote/Consent/deferral/seat/retcon mutations, `r6_ec16_d10_inverted`,
  `r6_composer_seats_dropped`, `r6_composer_seat_order`, `r6_composer_dissenters_writer`, `r6_rule9_executes_anyway`,
  `r6_rule10_failed_executed`, `r6_rule6_gate_needs_flag`, `r6_gate_formula_needs_flag`, `r6_t7_guard_needs_flag`,
  `r6_gate_table_needs_flag`, `r6_lac21_scene_wrong`, `r6_disclosure_dropped`, `r6_disclosure_optional`,
  `r8_t13_guard_reverted`, `r6_standdown_executes`, `r6_kaelen_seated`, `r6_stances_hidden`,
  `r6_content_rule_dropped`, `r6_seat_order_s9`, `r6_old_module_name`, `r7_seats_prereq_dropped`,
  `r7_t7_seats_guard_dropped`, `r7_mirror_timing_changed`, `r7_lac21_six_seats_dropped`. As in round 4, their old
  logs are left in place, unrefreshed. 69 mutations retargeted to revision-9 text (same name, same intent, e.g.
  `r4_t13_to_leaning` now moves T9, `r6_ac9_dlist_short` shortens AC9's active list, `r8_d17_dropped` drops the new
  D17 text). 31 new `r9_*` mutations, one per new or replaced check.
- **Result** (2026-11-11): checker `RESULT: PASS (0 problems)`; `run_mutations.py`: "212 mutations, 1 controls; 0
  unexpected results" (every mutation FAILs, the control PASSes). `check_pass.log` and every `mutation_*.log` named in
  `run_mutations.py` were refreshed by the run.
- **Still NOT checked**: whether the docs' state machine is sound (Open Question 16's reference model); prose outside
  the pinned sentences; PM line numbers cited in prose; the L-AC bodies beyond their pinned phrases; whether the
  retired Edge Case 16 numbers are ever reused by a later revision (only the current list is pinned).

## Reference model (axes Open Question 16, 2026-11-17)

- User decisions (2026-11-17): build the model in this folder, with its log and this section; no GDD edits. Where the
  spec is ambiguous the model takes the literal reading and reports a finding ("Pick + report").
- `reference_model.py` (stdlib only, never shipped): an independent re-implementation (it parses no GDD text) of
  `formula_id`, `prereqs_met`, `family`, `lock_pass`, `phase_of`, `load_check` (D1, D6-D9, D14-D17) and
  `crisis_offers`. It walks T1-T9 breadth-first for every seed context the code allows (13 axis seeds, at most one
  Data Wraith flag: 4096 contexts, 256 distinct `lock_pass` signatures). It asserts A1-A14 (every reachable save
  passes `load_check` and reloads in its phase; no save inside a suppression window; a way forward and FINAL
  reachable from every state; I1-I5, I7-I9; T5 = L-AC7; 24 IDs, 16 offers, 16 beats) and runs the unit tables of
  axes AC5-AC9 and lifecycle L-AC2, L-AC3, L-AC5 and L-AC8. It also searches for one AC9 fixture per D clause and
  probes the records `load_check` accepts that play never writes, then walks forward from each of them.
- 12 negative controls (defects seeded into the model) each fail at least one assertion; without them a PASS would
  prove nothing.
- Reproduce: `python -I -B reference_model.py > reference_model.log` (about 5 min; `--quick` skips the probe).
- **Result** (2026-11-17, axes rev 9 / lifecycle rev 5): `RESULT: FAIL (literal reading; 10 finding(s))`. All 12
  controls are CAUGHT. With F1's candidate repair (D17's before-commit clause tested on loaded records only),
  A1-A14 pass. Findings for round 10, in `reference_model.log`:
  F1 D17 makes every live crisis DAMAGED (the Formulas' own CRISIS example fails);
  F2 AC9's CRISIS fixture gives {D9, D17}, not {D9};
  F3 D17's prefix clause never fires without D16 or D17's other clause;
  F4 D7's `new` clause cannot be isolated, because D14 does not define "matching";
  F5 `lock_negotiated` is not checked against the saved seeds, and a retraction's item and scene are not checked;
  F6 D7 is one-directional (an entry without `axis_revised` loads);
  F7 nothing ties `root_phase` to the position (saves inside suppression windows load too);
  F8 L-AC8 has no VALIDATED load cell;
  F9 T6 TURNED_BACK is dead (any record at the gate with an UNSET axis is DAMAGED by D16), so L-AC8's two
  synthetic story cells cannot be set up;
  F10 an edited save with `root_phase` not FINAL positioned in Story+ never reaches FINAL (this depends on M8: Story+
  cannot replay the final authorization).
  F1, F2 and F9 contradict the docs' own examples or ACs. F3-F8 and F10 concern debug or edited saves, or AC wording.
- **Not modelled**: side-arc flags (AC15), the secret routes (all disabled; formula level only), NG+ carry-over,
  scene content (P3/AC14, L-AC16), the time model. The model's positions are coarse (Chapter 9 is one position, the
  boss one event). Modelling choices M1-M9 are listed in the log.

## Round 10 sync (axes rev 10 / lifecycle rev 6, 2026-11-17)

- User decisions (2026-11-17, design review round 10): keep T6 as defence in depth with a DAMAGED gate row; narrow the
  load-check promise to "every save play writes loads" (F5, F7, F10 stay best-effort, axes Open Question 17); define
  D14 "matching" strictly and keep D7's new-value clause with a coordinated two-field fixture; edit both GDDs and sync
  this folder.
- `check_storyline_axes.py`: pins updated for Core Rule 8, the phase table's DAMAGED gate cell, the Formulas
  `storyline_phase` paragraph, Edge Case 16 (D7, D9, D14, D17 and the "load only" and "Not checked" sentences), AC9,
  the lifecycle gate table (a fourth row, `DAMAGED (a live record)`, via `LIVE_GATED`) and L-AC8. Result: `RESULT: PASS
  (0 problems)`.
- `run_mutations.py`: six mutations re-aimed at the changed text (`r6_qa_rule8_stranded`,
  `r6_phase_row_damaged_dropped`, `r6_ec16_d7_dropped`, `r8_d17_dropped`, `r9_ac9_clause_list`,
  `r9_dependency_revision`) and 13 added (`r10_*`). Result: "225 mutations, 1 controls; 0 unexpected results". Every
  `mutation_*.log` was rewritten by the run, so the diff is large and mostly the header lines.
- `reference_model.py`: the current text is `REV10`; the revision 9 text is kept as `LITERAL`, a regression that must
  still fail (F1 as A8, the AC9 CRISIS fixture and L-AC8). New: D7's reverse clause, the gate's DAMAGED row, the
  coordinated D7 fixture (the entry's `new` and its beat renamed), L-AC8's injected live cells and its VALIDATED-on-load
  cell. F5, F7 and F10 are reported, not asserted. The log is regenerated; the revision 9 log is in git (3c1bffb).
- New finding F11 (axes Open Question 18): with D9 and D17's before-commit clause exempt for every live record, a live
  CRISIS record positioned past C8-S16 reads CRISIS and reaches a gate with no CRISIS row. No play path produces it
  (I2). Not changed in revision 10; the candidate is to exempt only a live record positioned inside C8-S16.

## Round 11 sync (axes rev 11 / lifecycle rev 7, 2026-11-17)

Design review round 11 (full: game-designer, systems-designer, qa-lead, narrative-director, godot-specialist,
creative-director) gave NEEDS REVISION with 9 blockers; the user settled Open Questions 17 and 18, chose C9-S18 option
(b), the Kaelthas allied-flag trust condition and the full AC16 playtest. All 9 were fixed in the same session.

- `check_storyline_axes.py`: re-pinned to rev 11 / rev 7 (live_crisis wording, D0, D7 clause ids and duplicate clause,
  inclusion rule, I5, arcs 05/08/09 scope, AC9/AC14/AC16/AC17, observables `scene_lines`, C9-S18, S6 DAMAGED copy,
  L-AC8/L-AC10/L-AC18). `py_phase` takes the live-crisis window, parsed from each Formulas example's position.
  Result: PASS (`check_pass.log`).
- `run_mutations.py`: 28 mutations retargeted to the rev 11 text, 22 round-11 mutations added (`r11_*`).
  Result: 247 mutations FAIL, 1 control PASS, 0 unexpected.
- `reference_model.py`: REV11 reading (`live_crisis` scoping, `D7.duplicate`); AC9 bounded-live-crisis and non-goal
  fixtures; L-AC8 live-crisis cell; hand-built fixtures for D7.unnamed, D14.no_entry, D14.not_played, D7.duplicate;
  D7.multi and D17.prefix listed as documentation (equivalent mutants); residual categories asserted against a pinned
  list. The rev 10 text is a unit-level regression (must still fail on F11), the rev 9 text a walk-level one.
  Result: PASS in 328.9 s (`reference_model.log`). D0 (shape) is not modelled (typed records; SaveService tests it).
- Still not evidence of: the composer, the scenes, SaveService's save suppression and refusal path (routed to
  Y1-P1-T05), or anything a player sees.

## Design review round 12 (2026-11-17): axes revision 12 / lifecycle revision 8 sync

User decisions (2026-11-17, design review round 12; changeset approved: "Yes, the whole set"):

- Authority remap: the seeds read whether Kaelen answered for what he did. `ch1_aldric_kill_justified` → authority:YOU
  `−`; `ch2_seraphina_showoff` gains an authority:YOU `−` row and `ch2_seraphina_truth` an authority:SHARED `+` row,
  each beside its modifier row (26 flags in 28 rows; `lock_pass` matches a row by (flag, pushes)). `ch1_knight_spared`
  was proposed for SHARED and dropped, because the Purge path sets it too (`dialogue/ch1/aldric.dlg:116`).
- Kaelthas is out of the 1.0 companion set (Elara, Seraphina, Lyra); his redemption is axes Open Question 19.
- Chapter select past Chapter 8 seeds `SL-SHARED-ARCHIVE-CHOOSE` at `CH9` with `lock_negotiated` = all three axes.
- `ch2_data_wraith_destroyed` → RELEASE is kept (`+`, (J)) despite the narrative-director's new objection.
- Revise now, in this round; the whole changeset approved.

The tooling was synced without editing either GDD.

- `check_storyline_axes.py`: `SEED_EXPECTED` became `SEED_ROWS` (flag, pushes, direction); the flag set is still
  exactly 26, a flag may have at most one axis row and one modifier/timing row, and every approved row must be present.
  `COMPANIONS` has no Kaelthas. Re-pinned to the new text: Core Rules 3 (the `−` seeds per axis, derived from the seed
  rows), 8 ("and the phase not DAMAGED", a DAMAGED record turned back) and 11 (the companion set, derived); Edge Case 1;
  Edge Case 8 (legacy defaulting, D0 for a current-schema missing field, chapter select); Edge Case 16 D0 (one-entry
  cap, duplicate element), D7 (clause ids exactly `unnamed`, `reverse`, `new_mismatch`; the retirement sentence), D15
  (schema scope), D16 (Terms); AC9 (one documentation clause, D0 fixtures with the R2/R3 two-entry record, legacy,
  edited `scene`), AC11, AC14 (`base_lines`, three story scenes, `keyed_axis`, two seeded defects), AC15 (every arc a
  row, zero-hit scan NOT ASSESSED, blocked by Y2-PP-T17 too), AC16 (Act-1 subgroup gate, (c)/(d) reported, no early
  stop, fresh re-run of at least 12), AC17 (`lock_arguments`), the four new observables, the Runtime story-type
  paragraph. New `check_revision12`: the Terms story-position list equals `POSITIONS` read from `reference_model.py`
  (by `ast`, not executed); the protected story-progression row; Open Questions 10, 17, 19, 20; the chapter-select
  record derived (a valid row, its Authority and Deleted values in no invalid row, family BOUND, all three axes
  negotiated, L-AC19 expects its ID); every `PM:7118` citation must be the supported claim "RELEASE needs staged
  verification" (the blanket stale string `PM:7118` from round 2, which cited it for "involuntary preservation", is
  now that old phrase only). Lifecycle: the stored story position, the one-predicate gate (chapter select and the
  Chapter 10 chain on the `story` path, free travel locked), legacy defaulting, chapter select, L-AC1-L-AC19.
- `run_mutations.py`: 15 mutations retargeted to the rev 12 text (same name, same intent: `deleted_row` and `companion_removed` with the
  three-companion cell, `r4_seed_intro_count`, `r5_ac14_unknown_observable`, `r6_qa_ec8_body`, `r6_ec16_d16_dropped`,
  `r6_ec16_d7_dropped`, `r7_ac14_pairwise_restored`, `r9_ac15_blocked`, `r9_ac11_blocked`, `r9_dependency_revision`,
  `r10_d17_prefix_fixture`, `r11_ec16_d0_dropped`, `r11_ac14_pairwise_one`, `r11_ac14_unmasked`, `r11_ac17_dropped`,
  `r11_ac9_mutation_kill_dropped`); 2 retired because their target text is gone (`r11_d7_duplicate_dropped`,
  `r11_kaelthas_trust_dropped`; old logs left in place, unrefreshed); 52 `r12_*` added, one per new pin (Authority
  seed flip, a second axis row, Kaelthas re-added in the composer, the table, Core Rule 11, Edge Case 1 and AC11,
  `D7.duplicate` re-added, D0's cap and duplicate clause, D15 scope, AC14 back to the most-shared baseline, AC16 back to
  6 re-run testers, Core Rule 8 without "and the phase not DAMAGED", the chapter-select paragraph, the S6 predicate,
  both legacy-defaulting sentences, the story-position list, PM:7118 misattributed, L-AC19, ...). Each first FAIL
  line names the check it targets. Final result, against the real documents after the main session's fixes below:
  **297 mutations FAIL, 1 control PASS, 0 unexpected**; `check_pass.log` is the real documents, **PASS (0 problems)**.
- `reference_model.py`: REV12 reading. D0 modelled (enum and type shape, `retraction_log` over one entry,
  `beats_played` over sixteen, a current-schema missing field via `decode()`); "a set holding one element twice" is
  not modelled (a frozenset cannot hold one; M12). Legacy saves defaulted before the check (LEANING at `PRE_C8`,
  {D16} at `CH9`). `D7.multi` and `D7.duplicate` retired; the duplicate case is the D0 two-entry fixture (the R2 and
  R3 Faction retractions of (NONE, HEARTH, RELEASE), each consistent alone). D14 refuses any beat id outside the 16
  `retract_*` ids (the model checked malformed `retract_*` ids only; fixed for every reading). `AXIS_SEEDS` has the
  15 rev-12 axis rows (16384 contexts, still 256 `lock_pass` signatures). `DIGITS` now reads Authority=AXIS1,
  Faction=AXIS2, Deleted=AXIS3 (Core Rule 3). Chapter select is the walk's second start (CH9) and has its own unit
  check; L-AC19 is checked on five paths. Kaelthas was never modelled as a companion (M14). The rev 11 text is a new
  unit-level regression that must still fail: its `D7.duplicate` fixture gives {D0}, its legacy save is D0, and its
  seed map passes a justified kill clean. Result: `RESULT: PASS` in 367.4 s (`reference_model.log`): unit tables, A1-A14 in every signature, 12/12 negative
  controls caught, every active clause isolated (D17.prefix documentation only), residual categories equal the pinned
  list; the rev 11, rev 10 and rev 9 texts still fail as expected. New reported findings: F12, chapter select of
  Chapter 8 itself is named by neither sentence of lifecycle Chapter select ("before Chapter 8" / "Chapter 9 or
  later"); the model reads it as the new-game start. F13, L-AC19's "LEANING or PARTLY_LOCKED injected live record"
  reads DAMAGED (D16) at every past-C8-S16 request, so its TURNED_BACK comes from the DAMAGED row, not T6; the
  assertion still holds.
- GDD findings from the sync, fixed in the main session (2026-11-17) and re-verified: the lifecycle Dependencies row "| Storyline axes (`design/gdd/storyline-axes.md`) | this ← axes | values,
  formulas, record, invariants I1-I9, knobs | revision 11 |" names axes revision 11; the axes document is revision
  12, so the checker's cross-revision check (round 9) fails on the real text. Plus the two model findings F12 and F13
  above (wording gaps, no failing assertion). Fixes: the cell now names revision 12; lifecycle Chapter select and
  L-AC19 now say "Chapter 8 or earlier" (F12 resolved in the text; the model's F12 line is a fixed report string and
  still reads as before); the two checker pins and the mutation `r12_chapter_select_dropped` were retargeted to that
  wording. F13 stands as a note. Re-runs on the final text: checker PASS (0 problems); 297 mutations FAIL / 1 control
  PASS / 0 unexpected; reference model `RESULT: PASS` (rev 11, rev 10, rev 9 texts still fail; residual categories
  asserted), 384.4 s. `check_pass_lifecycle_depfix.log` was removed as obsolete.

## Design review round 13 (2026-11-17)

- Verdict NEEDS REVISION (game-designer, systems-designer, qa-lead, narrative-director, godot-specialist;
  creative-director synthesis): 6 substantive and 9 one-line blockers, none touching the static core; log entry in
  `design/gdd/reviews/storyline-axes-review-log.md`. The creative-director stated the blocking bar (a play save refused
  or stranded, or an AC that cannot pass; two rules in contradiction; a citation that does not say what it is cited
  for) and the exit conditions for round 14.
- User decisions (2026-11-17): revise now; `ch1_root_purge` moves from `faction:HEARTH +` to `authority:YOU −`
  (power used on others without answering for it; resolves round 9's PM:663 objection); arc 08 is mapped to Faction
  (secondary `faction:*`, PM:3681-3682), so ten arcs push an axis in 1.0.
- Axes revision 13 / lifecycle revision 9: the Authority seed note states one discriminator and quotes PM:636 and
  PM:7048 verbatim, citing PM:1804; the story position is written at every entry point (new game and NG+ reset at
  `PRE_C8`, chapter select keyed to its entry scene's position, so "Chapter 8 - Ending" writes the fixed record at
  `S16_DONE`; a legacy save's position derived once from its scene, a scene the map lacks is D0); D0 caps
  `beats_played` at one and type-checks it, so D14's undefined-beat clause is no longer shadowed; one knob-read
  statement in Tuning Knobs (C8-S16 and the gate, plus `secret_prerequisites[FIRSTWAKE]` at C9-S18); `gate_open()`
  excludes DAMAGED; Open Questions 6 and 13, Edge Case 1 (code citation), L-AC14 (PM:3814 is the Chapter 3 End
  ledger) and the Formulas example ({D9, D17}) corrected. Recommended and routed items were not applied (exit
  condition: fix only the blocking list).
- Checker: `SEED_ROWS` purge row; Core Rule 3's derived sentence says "all" for three `−` seeds; D0, Edge Case 8,
  AC9/15/17, lifecycle chapter-select and L-AC19 pins retargeted; new `check_revision13` (pinned sentences, retired
  wording, the side-storyline secondary column).
- Mutations: 13 targets moved by revision 13 were retargeted; 26 `r13_*` mutations added. Result: 323 mutations FAIL /
  1 control PASS / 0 unexpected; `check_pass.log` PASS.
- Reference model: `REV13` is the current reading (seed map with the purge row, `beats_max` 1, chapter select by entry
  position with "Chapter 8 - Ending" as a third walk start, NG+ reset to `PRE_C8`, legacy position derived from
  `LEGACY_SCENES`); new unit checks P10 purge, Chapter select by entry position, NG+ reset, Legacy position and AC9 D0
  (rev 13). NG+ is a unit check, not a walk edge (M15: an NG+ edge would trip A6 across cycles). The rev 12 text is a
  new regression that must still fail on each of those five. F12 resolved. Result: `RESULT: PASS` in 369.1 s
  (`reference_model.log`; rev 12, 11, 10 and 9 texts still fail as expected; residual categories asserted).

## Design review round 14 (2026-11-18)

- Verdict NEEDS REVISION (game-designer, systems-designer, qa-lead, narrative-director, godot-specialist;
  creative-director synthesis) under the round-13 bar: 6 blockers, the static core intact for a sixth round; log entry
  in `design/gdd/reviews/storyline-axes-review-log.md`. Two blockers (`act1_pace`, `story_position`) were invisible to
  the model because it modelled only the lifecycle block. Round 13's README entry says the purge move "resolves round
  9's PM:663 objection"; round 14 found that rationale inverted (the purge leaves Aldric lucid, `aldric.dlg:119-122`).
- User decisions (2026-11-18): revise now; adopt Open Question 20 with a scope freeze (revision 14 fixes only the
  blockers; round 15 runs lean on the diff and the model log); a Chapter 8 legacy save no story scene places is
  refused (`D0.missing`); main-story seeds named as a class, the Chapter 4 Null Court mapping deferred to Open
  Question 21 (seed map and its 26-flag list unchanged).
- Axes revision 14 / lifecycle revision 10: the purge row rests on `aldric.dlg:104-107` and PM:663 is no longer cited
  for it; `story_position` is a record field, a legacy position is derived from the free-travel story scene, else the
  save's own scene (no hub in the scene-to-id map), else the chapter; `act1_pace` (and acts 2-4) allow UNSET; D0 and D1
  name their clause ids and AC9 lists every clause id, with one D0 fixture per clause, a new-game fixture and the D7
  fixture (SHARED, ARCHIVE, RELEASE) with {authority, NONE → YOU}; AC11's mirror-flag sentence removed and
  `companions_of(module_id)` added; AC15 Logic (BLOCKING) with a `secret:<route>` push; Open Questions 20 (adopted)
  and 21. Recommended and routed items were not applied (scope freeze).
- Checker: composer pins (`act1_pace` UNSET, `story_position` row), D0/D1, AC9/AC11/AC15, Observables, Edge Case 8,
  Formulas and lifecycle pins retargeted; NG+ reset default for `story_position` (`PRE_C8`); new `check_revision14`
  (pinned sentences and retired wording). A first mutation run found one pin lost in the AC9 rewrite (the two-entry
  `retraction_log` fixture; `r12_ac9_two_entry_dropped` passed) and it was restored.
- Mutations: 14 targets moved by revision 14 were retargeted; 24 `r14_*` mutations added. Result: 347 mutations FAIL /
  1 control PASS / 0 unexpected; `check_pass.log` PASS. Logs were written to the session scratchpad and copied here,
  because a OneDrive write lock (`Errno 22`) interrupted one run that wrote here directly.
- Reference model: `REV14` is the current reading; new `stored_save_check` (the lifecycle block plus `act1_pace` and
  `story_position`), `d0_clauses` (D0 clause ids; `D0.duplicate` stays the decoder's, M12), `legacy_position` /
  `LEGACY_SAVES` (hub-safe order, `SCENE_TO_ID` and `HUB_SCENES` stand in for the map and the game's hubs, M16); new
  unit checks New game, Position field, Legacy hub, AC9 D0 clause ids and AC9 D7 new-value fixture (rev 14). The rev 13
  text is a new regression that must still fail on the first four. Result: `RESULT: PASS` in 279.9 s
  (rev 13, 12, 11, 10 and 9 texts still fail as expected; residual categories asserted).
- Before round 15 (user request, 2026-11-18): Open Question 20 says the model covers every closed-list field, so
  `stored_save_check` now also checks `companions_present` (Elara, Seraphina, Lyra) and `timing_flags` (the six timing
  flags) against their allowed values, with a new unit check "Closed-list fields (rev 14)". `regions_completed` has no
  enumerated list in the GDD and the act 2-4 paces wait for S06b's names (M16). Re-run: `RESULT: PASS` in 213.1 s
  (`reference_model.log`; regressions and residual categories as before); checker PASS. No GDD text changed, so the
  mutation logs stand.
