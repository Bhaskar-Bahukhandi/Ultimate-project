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
