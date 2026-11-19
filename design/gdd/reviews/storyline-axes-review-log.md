# Review log: storyline-axes.md

## Review — 2026-11-09 — Verdict: NEEDS REVISION
Scope signal: M
Specialists: game-designer, systems-designer, narrative-director, qa-lead, creative-director (synthesis)
Blocking items: 6 | Recommended: 8
Summary: The core holds (three axes, R1-R3, 24 valid, four families, companions independent, timing as modifier).
The defects are lock timing (secret prerequisites land in the Chapter 9 ledger and revision runs before Root of
Heaven), self-contradicting formulas, and a seed map with no Authority seeds and a misread knight row.
Prior verdict resolved: First review
Findings:
- [BLOCKING] Detailed Design / Formulas / Acceptance Criteria: storyline ID fixed at Chapter 8 instead of before Root of Heaven (PM:722, PM:8188-8200)
- [BLOCKING] Formulas: ID formula ignores validity and the enable knob; no UNSET value; NONE token overloaded
- [BLOCKING] Detailed Design (seed map): no Authority seeds; ch1_knight_spared misreads PM:663; until:ch8_choice_made unsound; "−" undefined
- [BLOCKING] Acceptance Criteria: AC 2/3/4/9 not testable; checker misses rules table, R1-R3 exactness, 8/9/7 split, Edge Case 2
- [BLOCKING] Citations: C8-S17 is PM:7155 Revolution Name (Axis validation is PM:7522); PM:3615 local; Story Bible :187/:203 now :190/:206
- [BLOCKING] Detailed Design: Witness/CONSENT vs Bound/SHARED undefined
- [RECOMMENDED] Detailed Design: warning before the third lock
- [RECOMMENDED] Detailed Design (seed map): Data Wraith absorb ≈ CHOOSE, destroy ≈ RELEASE
- [RECOMMENDED] Detailed Design (side storylines): arc 12 also deleted:CHOOSE; arc 03 → Witness unsourced
- [RECOMMENDED] Detailed Design (seed map): Oakhaven flags lack faction mapping
- [RECOMMENDED] Formulas: "27" wording ambiguous (27 combinations vs 24 + 3)
- [RECOMMENDED] Edge Cases: drop the "first in table order" tie-break (data error for FlagRegistry)
- [RECOMMENDED] Story Bible: "loses health bar" belongs to Crownless (PM:11247), not Consent
- [RECOMMENDED] Composer record: truth-strategy module (PM:8739) — owner Y2-PP-T17
Reviewed-Content-Hash: design/gdd/storyline-axes.md d494fa55489384cfc2d178e4c064b25447525e55
Reviewed-Content-Hash: design/registry/entities.yaml 216ffa67ed4d5d24548df37b2ce899fcba892285

## Review — 2026-11-10 — Verdict: NEEDS REVISION
Scope signal: M
Specialists: game-designer, systems-designer, narrative-director, qa-lead, creative-director (synthesis)
Blocking items: 5 | Recommended: 6
Summary: The round-1 core holds (axes, R1-R3, 24 valid, families, companions independent, timing as modifier).
Revision 1 opened one contained cluster: the crisis state machine, the ID-fix point (named with the source's
post-boss "final authorization" term, PM:8786-8794) and the secret transformation (S undefined, UNSET overloaded).
A one-section rewrite, not a redesign.
Prior verdict resolved: Partly (Authority seeds, Bound/Witness, UNSET, most citations fixed; ID-fix move introduced the cluster above)
Decisions taken by the user (2026-11-10): include the PM:8791 post-boss reconsideration (one axis, valid rows only,
at most once, not for a secret storyline; offered only on a data-defined drastic-change trigger); revision sets a
composer-read flag with no weight; in-fiction faction red lines replace the system warning; a valid row cannot be
revised before the gate; P5 met in 1.0 by nine arcs (05/08/09 feed post-1.0 routes), stated in the GDD.
Findings:
- [BLOCKING] Detailed Design / Formulas: "final authorization" is PM's post-boss Chapter 10 scene (PM:8786-8794); rename the fix point (ID-lock gate at Root of Heaven entry); immutability cite is PM:11303
- [BLOCKING] Formulas / States and Transitions: S undefined, contradicts Core Rule 5, last-writer-wins; UNSET means both Leaning and Crisis; missing transitions; prereqs_met(empty) true; family() returns SOLE for an invalid-row id
- [BLOCKING] Core Rules 2-3 / AC12: a lock scene may withhold a value (softlock with R2/R3 disabled); seeds must add arguments, never gate options
- [BLOCKING] Citations and canon: PM:663 does not support ch1_root_purge / ch1_knight_killed; Kaelen may be a witness, threshold not unanimity (PM:8704-8706); Consent vs NONE undistinguished; Deleted lock is C8-S16 (PM:7134); Chapter 9 holds the last Witness prerequisite, not the first; Crownless/First Wake prerequisites exist (PM:11242-11246, 11270-11274)
- [BLOCKING] Acceptance Criteria: AC8/AC12 lack observables; AC9/AC10 vacuous by signature; AC11 "all 26 together" violates exclusive groups; no crisis-transition AC; composer allowed lists exclude UNSET
- [RECOMMENDED] Formulas / Counts: 1.0 ships 25 storylines; 8/9/7 split is derived, not stated
- [RECOMMENDED] Detailed Design (seed map): define or drop "−"; pace rows; re-check (J) rows kill_unsure, wraith_destroyed, seraphina_cautious; arc 12 deleted:CHOOSE unsourced
- [RECOMMENDED] Detailed Design (27-row table): companions_possible constant; Nema, Seven, Rook, Kaito (PM:7531-7537)
- [RECOMMENDED] Acceptance Criteria (checker): mutations still PASS (invalid() set, R-label swap, seed direction, pm_line swap); hard-coded vocabularies
- [RECOMMENDED] Acceptance Criteria: legacy and mid-crisis save AC
- [RECOMMENDED] Detailed Design: SHARED/CHOOSE are never invalid (known safe pick)
Reviewed-Content-Hash: design/gdd/storyline-axes.md 3f906963c4a84374ec420a0d0f590556fba0a24e
Reviewed-Content-Hash: design/registry/entities.yaml 216ffa67ed4d5d24548df37b2ce899fcba892285

## Review — 2026-11-10 — Verdict: NEEDS REVISION
Scope signal: L
Specialists: game-designer, systems-designer, narrative-director, qa-lead, creative-director (synthesis)
Blocking items: 10 | Recommended: 8
Summary: The static core (axes, R1-R3, 27-row table, seed map, formulas, counts 27/24/25 and 8+9+7) has held for
three rounds; all blockers sit in the lifecycle layer added by revisions 1-2 (crisis, invocation, gate,
reconsideration), where each patch opened new contradictions. Next revision: one contained lifecycle rewrite (Core
Rules 4-9, a transition table, composer writers, Edge Cases 2/10/11/13, AC9-15 + an Observables table), not a
redesign; if round 4 still finds state-machine contradictions, move the lifecycle into a Y2-PP-T17 contract.
Prior verdict resolved: Mostly (ID-lock gate named, S replaced by I, UNSET/PENDING/CRISIS split, all three values
always offered, witness/threshold canon fixed); revision 2's lifecycle layer opened the cluster below.
Open user decisions: reconsideration scope (a keep round-2 rule / b Faction-Deleted only / c Faction-Deleted,
epilogue+slides only — CD recommends / d any axis with bridge scene); seed clean-vs-negotiated pass as a boolean flag
test (GD1, CD recommends); Root status after Consent (PM:7034 vs PM:705). CD rulings: Witness invoked at C9-S19 plus a
gate-as-last-crisis-scene guard; invocation irreversible with an in-fiction confirm.
Findings:
- [BLOCKING] Detailed Design (Core Rule 5): Witness circular/unreachable — C9-S19 (PM:8045-8055) is the invocation scene and outputs SEVEN_WITNESSES_AVAILABLE (PM:8200); ledger is followed directly by the gate (PM:8207); no signpost spec; threshold (PM:8707) and C10-S15 undefined
- [BLOCKING] States and Transitions: Rule 5 "renegotiation clears secret_invoked" unreachable under Rule 6 (AC9 asserts it); missing gate-in-CRISIS, reconsideration and Validated→Crisis transitions; "final: Never" vs Rule 8; reconsideration replaces ID but not axes
- [BLOCKING] Edge Cases (10): no softlock guard at the gate; entry via story graph / world map / save-load untested
- [BLOCKING] Tuning Knobs / Core Rule 7: knob patch during Chapter 9 flips a live SL-SECRET-WITNESS to CRISIS; snapshot on resolution
- [BLOCKING] Core Rule 4: withdrawal list cites faction roles that end at the Axis1 lock (PM:7006/7017/7027); per-axis retraction table; SOVEREIGN quote after retraction
- [BLOCKING] Core Rule 8: post-boss Authority change contradicts the Axis1-specific boss phase (PM:8615) — scope is a user decision
- [BLOCKING] Core Rule 9: Root status after Consent and executor/witness separation (PM:7034 vs 705; 8054, 8694, 8704, 11219) — user decision
- [BLOCKING] Acceptance Criteria: runtime observables undefined outside ACs; no AC for red lines, retractions, signposts, EC13, Consent, family() over all ids; AC10 negative-only; AC15 tautological
- [BLOCKING] Citations: PM:7118 wrong (Open Q 10); "at the final confrontation" vs PM:7036 "after final crisis"; red lines are new content (canon refusals PM:7141/7147/7151); Kaelthas/Archive PM:7533
- [BLOCKING] Acceptance Criteria (checker): 13 scratch mutations still PASS (transform map, family map, timing in formula body, prose numbers, deleted Core Rules 3/6); AC11 vacuous until Y1-P1-T03
- [RECOMMENDED] Core Rule 4: renegotiation price beyond the flag
- [RECOMMENDED] Composer record: derive secret_route from the live ID, do not persist
- [RECOMMENDED] Tuning Knobs: boot-validate secret_prerequisites (≥2, disjoint, known, signpost keyed to enabled)
- [RECOMMENDED] Composer record: list every axis-field writer; SaveService owns UNSET default
- [RECOMMENDED] Formulas: reconsider_targets domain guard
- [RECOMMENDED] Acceptance Criteria: AC5 all 64 triples; AC12 persistence; AC14 dead in 1.0; AC9 revise-back; 18 crisis bot runs; per-AC blocked-by tags
- [RECOMMENDED] Edge Cases (11): unreachable for Witness; WITNESS_SEATS timing unstated
- [RECOMMENDED] Detailed Design (27-row table): cite each route's "Primary danger" line (24 exist, e.g. PM:9731) as its authored loss; invariant + T17 AC
Reviewed-Content-Hash: design/gdd/storyline-axes.md 1751765248a5a7151249bf7937431c06bbaaaa69
Reviewed-Content-Hash: design/registry/entities.yaml 216ffa67ed4d5d24548df37b2ce899fcba892285

## Review — 2026-11-10 — Verdict: MAJOR REVISION NEEDED
Scope signal: L (borderline XL)
Specialists: game-designer, systems-designer, narrative-director, qa-lead, creative-director (synthesis)
Blocking items: 6 | Recommended: 12
Summary: The static core (axes, R1-R3, 27 rows, seed map, arcs, invalid/family, counts 27/24/25 and 8/9/7) is ready
and stays. The round-3 tripwire fired: the lifecycle still has state-machine holes, and its crisis model contradicts
canon (PM:7143 resolves the crisis at C8-S16; C8-S17 onward assumes a named coalition). Next revision: user decisions,
then the GDD keeps the static core plus lifecycle invariants and a new Y2-PP-T17 contract
(`design/gdd/storyline-lifecycle.md`) takes the transitions, scenes and runtime ACs.
Prior verdict resolved: Partly (round-3 citations, retraction table, gate paths, Consent executor split applied);
the lifecycle rewrite opened the cluster below.
Decisions taken by the user (2026-11-10): B1 crisis resolves inside C8-S16, except R1 with the Witness signpost may
"defer to the witnesses" (provisional coalition; invocation at C9-S19, fallback at the gate); red lines become one
value-phrased line at C8-S15 from the faction one choice away (replaces the S13/S14 triple voicing); post-boss
reconsideration cut to a reserved Open Question (PM:8791); SEVEN_WITNESSES_AVAILABLE set at C9-S19 per PM, a separate
secret_invoked_WITNESS is I; Consent narrows Kaelen's YOU commitment on the record (family-keyed scene variants, no
permanent Root ownership, Kaelen may be a witness but not also executor per PM:8704); P3 sign-off: 1.0 ships 25, arcs
05/08/09 get a visible epilogue line; contract lives at design/gdd/storyline-lifecycle.md; checker pins rule bodies.
Findings:
- [BLOCKING] Detailed Design (Core Rules 5-7): crisis persists past C8-S16 against PM:7143/7153 and C8-S17+ canon; Witness is a blind irreversible bet (WITNESS_SEATS after S16); no content or price between S16 and the gate
- [BLOCKING] Detailed Design (Core Rule 11): SL-SECRET-WITNESS keeps YOU-keyed scenes (PM:7034, 7059, 8408, 8638-8645) unspecified under Consent
- [BLOCKING] Citations: PM:8704 "Kaelen may be one but cannot fill multiple roles" cited as excluding Kaelen
- [BLOCKING] States and Transitions / Tuning Knobs: knob preamble vs reconsideration_triggers; invalid_combinations knob vs fixed transform/counts; R2-removal patch soft-locks a mid-crisis save; FIXED/FINAL re-entry undefined; T3/T4 guard with an UNSET axis; "loading fires no transition" vs the load path
- [BLOCKING] Core Rule 10: reconsideration contradicts Faction/Deleted boss phases (PM:8611-8614)
- [BLOCKING] Acceptance Criteria: storyline_id() has no args (AC5-8); no axis observable; AC12 minus-fixtures impossible; EC6 vs game_manager.gd; undefined out-of-scene returns; 19 lifecycle mutations survive the checker
- [RECOMMENDED] Composer record: derive storyline_state from axes + stored ID
- [RECOMMENDED] States and Transitions: guard T12; NG+ reset list; family enum RESERVED/none
- [RECOMMENDED] Tuning Knobs: faction_negotiation_allowed has one safe value
- [RECOMMENDED] Core Rule 3: lock_pass invisible to the player; ledger Variants/Policies unused (PM:7569-7582)
- [RECOMMENDED] Detailed Design (seed map): YOU has 4 + seeds vs 1 each for SHARED/NONE
- [RECOMMENDED] Core Rule 7: signpost persists after the route is dead
- [RECOMMENDED] Core Rule 11: witness composition (Quest 09 needs Nema witness state, Seven free-person status, PM:7518)
- [RECOMMENDED] Core Rule 12: Kaelthas PM:7533 conditioned on Faction=ARCHIVE; companion reactions unhooked (PM:7534-7537, 11229-11236)
- [RECOMMENDED] Core Rule 6: PM:7021 is not a charter; retractions carry no authored price
- [RECOMMENDED] Core Rule 6: the two R2<->R3 Faction swaps are trap offers
- [RECOMMENDED] Acceptance Criteria (checker): pin rule bodies, transitions, writers, knob defaults
- [RECOMMENDED] Player Fantasy / Counts: explicit P3 sign-off for 25 storylines in 1.0
Reviewed-Content-Hash: design/gdd/storyline-axes.md 2fa718542f3c4bb8c944e420661f79de78bd0ddf
Reviewed-Content-Hash: design/registry/entities.yaml 216ffa67ed4d5d24548df37b2ce899fcba892285

## Review — 2026-11-10 — Verdict: NEEDS REVISION
Scope signal: L
Specialists: game-designer, systems-designer, narrative-director, qa-lead, creative-director (synthesis)
Blocking items: 6 | Recommended: 6
Summary: The static core (axes, R1-R3, 27 rows, counts 24/25 and 8/9/7, invalid/family/lock_pass, seed map, arcs)
holds for the fifth round and is frozen. The blockers are cross-document drift with the new lifecycle contract
(T8 record vs Edge Case 16, signpost wording), the C10-S15 gate, protected touchpoints and a seed count. Next
revision is confined to these items, with no new rules; confirm with the checker plus one reviewer.
Prior verdict resolved: Yes (round-4 decisions implemented; lifecycle split out to storyline-lifecycle.md)
Findings:
- [BLOCKING] Edge Cases (16): lifecycle T8 (deferral then gate renegotiation) leaves witness_deferred on a non-R1 row, which EC16 calls damaged; restate as stored ID != f(axes, secret_invoked)
- [BLOCKING] Edge Cases (13): signpost "closes" vs lifecycle EC4/L-AC11 HIDDEN
- [BLOCKING] Core Rule 6/10: C10-S15 is gated on SEVEN_WITNESSES_AVAILABLE (PM:8693), set on every storyline at C9-S19; gate it on storyline_id == SL-SECRET-WITNESS
- [BLOCKING] Dependencies: AGENTS.md also protects save/load schema, story progression, true ending, NG+; only world map flagged
- [BLOCKING] Open Questions (10): YOU has three + seeds, not four
- [BLOCKING] Core Rule 10 / Edge Cases 2, 10, 13, 15: scene behaviour duplicated from the lifecycle contract; cut and point to it
- [RECOMMENDED] Overview / Player Fantasy: clean vs negotiated promised as perceptible, Rule 3 says no scene reads it in 1.0 (user Q1)
- [RECOMMENDED] Side storylines: tracking AC that the nine 1.0 arcs' flags are mapped before T17 closes (P5)
- [RECOMMENDED] Acceptance Criteria: no AC for the P3 test (>=3 scenes, own ending and Story+)
- [RECOMMENDED] Overview / Core Rules 6, 10: witness convening point stated three ways (Chapter 9, C9-S19, C10-S15)
- [RECOMMENDED] Acceptance Criteria: AC5 feeds I=true where I is defined false; AC12 misses reserved-route-enabled and WITNESS-disabled boot errors
- [RECOMMENDED] Edge Cases (16): damaged-record list partial (ID with UNSET axis, ID not matching axes, axis_revised without lock_negotiated)
Reviewed-Content-Hash: design/gdd/storyline-axes.md 1a55a672fb9e3dcda4b535ac5e4308bee16fc291
Reviewed-Content-Hash: design/registry/entities.yaml 216ffa67ed4d5d24548df37b2ce899fcba892285

## Review — 2026-11-10 — Verdict: NEEDS REVISION
Scope signal: S
Specialists: game-designer, systems-designer, narrative-director, qa-lead, creative-director (synthesis)
Blocking items: 3 | Recommended: 4
Summary: The static core holds for a sixth round and stays frozen; checker PASS. Remaining blockers are local: a
damaged-first phase derivation, damaged-record rules for the three new record fields (retraction_log, beats_played,
witness_mandate), and cutting the clean-vs-negotiated promise to what Q1c delivers. Next revision: these items only,
confirmed by the checker plus one reviewer.
Prior verdict resolved: Yes (round-5 items fixed); revision 5 added record fields beyond "no new rules", accepted by CD
Decisions taken by the user (2026-11-10, with the lifecycle round 2): a FAILED witness vote is not executed (Kaelen
stands down at the final authorization; ID and family unchanged); T14 legacy catch-up cut to a dev-fixture migration;
the Witness deferral stays in 1.0 on probation (any further state defect in T6-T9 / S5-S7 moves it post-1.0); the
witness threshold is fixed at 5 (data-defined), the player's part being the choice of witnesses in Secret Quest 09.
Findings:
- [BLOCKING] Formulas (storyline_phase): FINAL tested before "ID stored"; INSIDE/FINAL with nothing stored classify as FINAL/CRISIS; damaged-first, explicit DAMAGED
- [BLOCKING] Edge Cases (16): no damaged-record rules for witness_mandate, retraction_log, beats_played, deferral/invoke beats, witness_deferred with UNSET axis, EC6 double-flag save
- [BLOCKING] Overview / Player Fantasy: clean vs negotiated still promised as perceptible; Q1c delivers only sole_dissent
- [RECOMMENDED] Detailed Design (Interactions): record authoritative, AXIS*/axis_revised_*/lock_negotiated_* flags derived mirrors
- [RECOMMENDED] Citations: PM:7144 is not "provisional coalition"; "never the combination" is a house rule; Kaelen exclusion cites the 2026-11-10 decision + PM:11219, not PM:8704
- [RECOMMENDED] Core Rule 4: anchor the R1 red line on PM:7114
- [RECOMMENDED] Acceptance Criteria: AC14 "scene" undefined, maybe unsatisfiable; AC15 vacuous; AC13 SOLE-via-renegotiation fixtures; AC7 true side; Kaelthas-on-ARCHIVE uncovered
Reviewed-Content-Hash: design/gdd/storyline-axes.md cb5f0c2ae12dbc19ed8c0cc6d8ccabb0c90d442f
Reviewed-Content-Hash: design/registry/entities.yaml 216ffa67ed4d5d24548df37b2ce899fcba892285

## Review — 2026-11-10 — Verdict: NEEDS REVISION
Scope signal: L
Specialists: none (--review lean, single-session analysis; the senior creative-director pass did not run)
Blocking items: 2 | Recommended: 8
Summary: The static core holds for a seventh round and the checker passed on revision 6. Both blockers are fallout of
the round-6 fixes: damaged-first left phase_of unable to return CRISIS and DAMAGED for the D9 record, and the new D13
exposed that the WITNESS_SEATS flag was never tied to seven saved seats. Both were fixed in revision 7 in the same
session (checker PASS, 233/233 mutations FAIL, 1 control PASS); a fresh re-review is still owed.
Prior verdict resolved: Yes (round-6 blockers: damaged-first phase, record fields D10-D14, perceptibility cut); the fixes opened the two blockers below
Decisions taken by the user (2026-11-10): the seven-seats guard is not a tripwire event (the deferral stays in 1.0 on
probation); phase_of and storyline_phase take a `loaded` argument; fold in the D2/D3 labels with the D16 precondition,
the record-authoritative rule, and AC14's baseline with the concept cut order (AC14's reading awaits confirmation,
Open Question 13).
Findings:
- [BLOCKING] Formulas / AC9 / Observables: phase_of(record) cannot return CRISIS for the CRISIS fixture and DAMAGED for the D9 fixture, which is the same record; no loaded-or-in-play argument (fixed: loaded argument)
- [BLOCKING] Core Rules 6 and 10 / Edge Case 16 D13 / T7: WITNESS_SEATS flag not tied to seven saved seats, so an invocation could store SL-SECRET-WITNESS with a short table that D13 then refuses on load (fixed: mirror rule, prereqs_met and T7 guard, AC6 and L-AC21 cases)
- [RECOMMENDED] Core Rule 3 / Interactions: record versus AXIS*/axis_revised_*/lock_negotiated_* flags had no stated authority (fixed)
- [RECOMMENDED] Core Rule 8 / Edge Cases 8 and 16: the save-refusal precondition "no player-facing build has such saves" lived only in the lifecycle (fixed)
- [RECOMMENDED] Acceptance Criteria 14: all-pairs 3-scene test is stronger than the P3 test and not shown feasible (fixed: shared-variant baseline, pairwise reported; user to confirm)
- [RECOMMENDED] Core Rule 2 / Player Fantasy / seed map: side-storyline and companion seeds claimed but only 26 Act 1 flags are mapped; lock-argument lines missing from the lifecycle content scope (open)
- [RECOMMENDED] Cross-document game-concept.md: "storylines 27→18" cut order has no mechanism in this design (logged as Open Question 13)
- [RECOMMENDED] Tuning Knobs / Open Question 7: labels D2 and D3 undefined and colliding with Edge Case 16 (fixed: removed, original definitions not recoverable)
- [RECOMMENDED] Core Rule 5: renegotiation offers voiced as the refusing faction's demand (lifecycle round-2 recommendation, still deferred)
- [RECOMMENDED] Counts and registry: design/registry/entities.yaml has no entry for this system (open)
Reviewed-Content-Hash: design/gdd/storyline-axes.md 0cdf9866eb4a0709015ef8d5d82550456aedcc96 (revision 6 as reviewed, HEAD a1cf409; revision 7 differs, so the next run re-reviews in full)
Reviewed-Content-Hash: design/registry/entities.yaml 216ffa67ed4d5d24548df37b2ce899fcba892285

## Review — 2026-11-10 — Verdict: NEEDS REVISION
Scope signal: L
Specialists: none (--review lean, single-session analysis; the senior creative-director pass did not run)
Blocking items: 1 | Recommended: 7
Summary: The static core holds for an eighth round; the checker passed on revision 7 and the round-7 fixes landed. The one
blocker is a cross-document guard mismatch: lifecycle T13 admitted FINAL on SL-SECRET-WITNESS with witness_mandate
UNDECIDED, a record Edge Case 16 D11 refuses on load. It and four recommended items were fixed in revision 8 in the same
session (checker PASS, 235/235 mutations FAIL, 1 control PASS); a fresh re-review is still owed.
Prior verdict resolved: Yes (round-7 blockers: phase_of loaded argument, WITNESS_SEATS mirror rule)
Decisions taken by the user (2026-11-10): T13 requires MET on SL-SECRET-WITNESS; Player Fantasy and Core Rule 2 re-scoped to
the mapped Act 1 flags (arc and companion seeds join with AC15); AC14 becomes a module-list and unlock-case test.
Findings:
- [BLOCKING] Lifecycle T13 / L-AC13 vs Edge Case 16 D11: guard "not FAILED" admits FINAL with witness_mandate UNDECIDED on SL-SECRET-WITNESS (fixed: T13 needs MET on that ID; S8 offers neither confirm nor stand-down on UNDECIDED; L-AC13 synthetic cell)
- [RECOMMENDED] Edge Case 16: out-of-order lock sets (an axis set while the axis before it is UNSET, or before its lock scene) load as PARTLY_LOCKED and no lock scene can play (fixed: D17, fixtures in AC9 and L-AC16)
- [RECOMMENDED] Player Fantasy / Core Rule 2: side-storyline and companion seeds claimed but only 26 Act 1 flags mapped (fixed: re-scoped; the lifecycle content scope still lacks the seed-argument texts, open)
- [RECOMMENDED] Acceptance Criteria 14: "own ending and Story+ state" met by distinct id strings (fixed: module-list and unlock-case test; pairwise scene minimum stays report-only, Open Question 13)
- [RECOMMENDED] Core Rule 5 vs lifecycle S4: Faction offers are voiced as stepping down, not as a demand (fixed)
- [RECOMMENDED] Overview: "Twelve side storylines push the axes" vs arcs 05, 08, 09 pushing none in 1.0 (fixed)
- [RECOMMENDED] design/registry/entities.yaml still has no entry for this system; systems-index.md does not exist (open)
- [RECOMMENDED] Witness deferral: authored scope (4 deferral beats, 6 gate retcons, 4 disclosures, invoke_witness, R1 clause, 7 candidates with stances, 6 Consent scenes, 70 Tier B lines) against a route few players reach, no success measure, producer sign-off still pending (open)
Reviewed-Content-Hash: design/gdd/storyline-axes.md 01ae4c8eff6a18ee6fa9096f49c770a1c32b2bfb (revision 7 as reviewed, HEAD 084ccb0; revision 8 differs, so the next run re-reviews in full)
Reviewed-Content-Hash: design/registry/entities.yaml 216ffa67ed4d5d24548df37b2ce899fcba892285

## Review — 2026-11-11 — Verdict: MAJOR REVISION NEEDED
Scope signal: L (M with Witness Protocol post-1.0)
Specialists: game-designer, systems-designer, narrative-director, qa-lead, creative-director (synthesis)
Blocking items: 5 | Recommended: 9
Summary: The static core (axes, R1-R3, 27 rows, counts, family, lock_pass) holds for a ninth round; checker PASS on
revision 8. The process is the problem: each prose revision of the state layer opened the next round's defect, and the
checker pins text rather than proving the state machine. Round 9 found a missing save-atomicity rule inside T7/T8, so the
Witness deferral probation tripwire fires. Next: a scope decision, a short revision of blockers 2-4, a non-shipping
reference model with a transition walk, then a lean round 10 against the model's output.
Prior verdict resolved: Yes (round-8 T13 guard fixed); a new state defect opened inside the probation list
Decisions taken by the user (2026-11-11): Witness Protocol moves post-1.0 (all three secret routes ship post-1.0 as one
mechanism; R1 resolves by renegotiation only); revise now.
Findings:
- [BLOCKING] Lifecycle T7/T8 / probation: multi-field writes with no atomic save rule; an autosave mid-transition writes a save that D3/D6/D7/D14 refuse (tripwire fires)
- [BLOCKING] Lifecycle save window: atomic checkpoint defined only for C8-S16; C10-S15 and checkpoints inside C8-S13/S14 after the axis write are uncovered (neither D16 nor D17 catches them)
- [BLOCKING] Acceptance Criteria (Observables, AC9): phase_of/load_check cannot evaluate D15-D17 (flags, story position not inputs); AC9 passes a load_check that returns every item
- [BLOCKING] Acceptance Criteria (AC14): satisfiable by per-ID module ids with no content difference; pairwise minimum report-only
- [BLOCKING] Core Rule 10 / lifecycle S8, S9 (if Witness stays): PM:7519 Assembly names the witnesses; route-specific final-authorization lines (PM:8990); UNDECIDED soft-lock past S8; signpost CLOSED precedence; mandate formula hardcodes 7
- [RECOMMENDED] Acceptance Criteria: no comprehension/playtest criterion that players link lock arguments to their Act 1 choices
- [RECOMMENDED] Acceptance Criteria 1-4: the checker is document lint (text pins), not correctness evidence; build a reference model
- [RECOMMENDED] Acceptance Criteria: AC10 tautological; AC7 no boundary at 2; transform() R2/R3 never run; AC12 no build input; AC13 SOLE-via-renegotiation and AC11 Kaelthas trust fixtures (open since round 6); AC15 self-contradictory
- [RECOMMENDED] Acceptance Criteria: no screenshot evidence planned for lock scenes, family endings, Story+
- [RECOMMENDED] Overview: "Nine of the twelve side storylines push the axes" overstates a seed map with no side-arc flags
- [RECOMMENDED] Invariant I8 / lifecycle OQ7: Consent variants table incomplete; NG+ previous-cycle record unstated
- [RECOMMENDED] Core Rule 10 (Consent): 5-of-7 can override the deleted seat (partly answered by PM:7093); Story+ after stand-down undefined
- [RECOMMENDED] Lifecycle S9: witness vote is a solved puzzle (stances visible at seating)
- [RECOMMENDED] Registry entry missing; S06b must name this GDD
Reviewed-Content-Hash: design/gdd/storyline-axes.md 8c45d3d240ebe1dbec12adcce983487ff86e2e40
Reviewed-Content-Hash: design/registry/entities.yaml 216ffa67ed4d5d24548df37b2ce899fcba892285

## Review — 2026-11-17 — Verdict: NEEDS REVISION
Scope signal: L
Specialists: none (--review lean, single-session analysis against production/qa/evidence/2026-11-storyline/reference_model.log; the senior creative-director pass did not run)
Blocking items: 3 | Recommended: 7
Summary: Round 10 ran against the non-shipping reference model (Open Question 16). The static core holds for a tenth round, and the round-9 atomic-checkpoint fix holds (A1-A14 pass under the repaired reading). The three blockers were text defects the model exposed: two acceptance criteria that could not pass and a dead transition with no gate row. All were fixed in revision 10 (lifecycle revision 6) in the same session and verified: checker PASS, 225 mutations / 1 control / 0 unexpected, model RESULT PASS with the rev 9 text still failing as a regression. A fresh re-review is still owed.
Prior verdict resolved: Yes (round-9 blockers: I9 atomic checkpoint, save windows, phase_of/load_check inputs, AC14, Witness scope); the AC9 rewrite re-opened as F2
Decisions taken by the user (2026-11-17): keep T6 as defence in depth with a DAMAGED gate row; narrow the load-check promise to saves play writes (F5, F7, F10 best-effort, Open Question 17); strict D14 matching with a coordinated two-field D7 fixture; sync the checker, mutations and model.
Findings:
- [BLOCKING] Formulas storyline_phase / Edge Case 16 D17: before-commit clause applied to live records made every live crisis DAMAGED (F1) (fixed: D9 and D17(a) load-only, each item marked)
- [BLOCKING] Acceptance Criteria 9: CRISIS fixture expected {D9}, but the fixture sits inside C8-S16 so D17 fires too (F2) (fixed: {D9, D17})
- [BLOCKING] Lifecycle T6 / S6 gate table / L-AC8: T6 dead in play, no gate row for a live DAMAGED record, L-AC8 story cells could not be set up (F9) (fixed: DAMAGED row, T6 as defence in depth, injected live cells)
- [RECOMMENDED] Edge Case 16 D14: "matching" undefined, D7 new-value clause not isolatable by one field (F4) (fixed: strict match, coordinated fixture)
- [RECOMMENDED] Edge Case 16 D7: one-directional (F6) (fixed: reverse clause)
- [RECOMMENDED] Edge Case 16 D17: prefix clause never fires alone (F3) (fixed: documentation, no fixture)
- [RECOMMENDED] Core Rule 8: "no loaded state is stranded" unproven for edited saves; rests on modelling choice M8 (F5, F7, F10) (fixed: promise narrowed, Open Question 17)
- [RECOMMENDED] Lifecycle L-AC8: no VALIDATED-on-load cell (F8) (fixed)
- [RECOMMENDED] Acceptance Criteria 14: rendered-text hash passes on an interpolated token difference (open)
- [RECOMMENDED] Registry entry and systems-index.md still missing (open)
- New during the fix: F11, a live CRISIS record positioned past C8-S16 reaches a gate with no CRISIS row (Open Question 18, not changed)
Reviewed-Content-Hash: design/gdd/storyline-axes.md 4e1de86eea4481976742f9ffba10284177ecd941 (revision 9 as reviewed, HEAD 3c1bffb; revision 10 differs, so the next run re-reviews in full)
Reviewed-Content-Hash: design/registry/entities.yaml 216ffa67ed4d5d24548df37b2ce899fcba892285

## Review — 2026-11-17 — Verdict: NEEDS REVISION
Scope signal: L
Specialists: game-designer, systems-designer, qa-lead, narrative-director, godot-specialist, creative-director (synthesis)
Blocking items: 9 | Recommended: 6 (plus items routed to Y1-P1-T05, the producer, the lifecycle and Y2-PP-T17)
Summary: Round 11 ran in full against reference_model.log (rev 10 run, PASS). The static core holds for an eleventh round, the round-10 fixes hold, and the model, not a reviewer, found the one new state defect (F11), so the evidence process works; the remaining defects are scoping, not structure. The round-9 tripwire concern is reduced but live until a model and checker re-run with asserted residuals is mandatory per state-layer revision. All 9 blockers were fixed in revision 11 (lifecycle revision 7) in the same session and verified: checker PASS, 247 mutations / 1 control / 0 unexpected, reference model RESULT PASS (rev 10 and rev 9 texts still fail as regressions; residual categories asserted); Open Question 16 now makes that re-run mandatory. A fresh re-review is still owed.
Prior verdict resolved: Yes (round-10 blockers F1, F2, F9 fixed in rev 10 and confirmed by the model)
Decisions taken by the user (2026-11-17): revise now; Open Question 18 settled by position-scoping (live_crisis; any other three-set, nothing-stored record DAMAGED; DAMAGED gate turn-back with dev assert and system-voice reload prompt; I5 amended); Open Question 17 settled by the three-part inclusion rule (D0 shape check and a D7 duplicate-entry clause added; F5a and F7 permanent non-goals; withdrawn_item and scene opaque; F10 waits on lifecycle OQ2; tripwires); C9-S18 option (b), the decrypted beat ending "logged, not answered".
Findings:
- [BLOCKING] Core Rule 6 / I6 / lifecycle S5: C9-S18 plays its "noise" form unconditionally, but PM:8043 reserves it for incomplete prerequisites (option b chosen)
- [BLOCKING] Formulas storyline_phase / Edge Case 16: the D9 and D17(a) live exemption is unscoped, so CRISIS is returned at any position (F11) and two other live records are misread (settled: live_crisis)
- [BLOCKING] Edge Case 16 / Open Question 17: no inclusion rule for the load check; no shape check (D0); D7 accepts a duplicated retraction entry; "reported, not asserted" untestable (settled: inclusion rule, tripwires)
- [BLOCKING] Acceptance Criteria 14: passes on an interpolated token and on family modules shared by 8 IDs
- [BLOCKING] Acceptance Criteria 9: "one fixture per clause" overclaims (D7 and D14 clause pairs; D7.multi redundant); needs Y1-P1-T03
- [BLOCKING] Acceptance Criteria 16: n=5 at 70% cannot evidence the fantasy; crisis denominator undefined; fixture saves skip Act 1
- [BLOCKING] Acceptance Criteria (P5): no runtime criterion that the nine 1.0 arcs voice an argument
- [BLOCKING] Core Rule 11 / AC11: the Kaelthas trust condition is undefined
- [BLOCKING] Open Question 10: "sole_dissent least likely" ignores renegotiation to YOU
- [RECOMMENDED] Lifecycle cut order: the 16 cost beats are the only cut step
- [RECOMMENDED] Crisis offers: log picks (advisory tripwire > 60% on one offer); present as one ask first
- [RECOMMENDED] Side storylines: arcs 05/08/09 marked post-1.0 though they ship with epilogue lines
- [RECOMMENDED] Counts / P3: state that 1.0 delivers 24, pending Open Question 14; game-concept.md "27" is a separate fix
- [RECOMMENDED] Formulas examples need positions; checker pins the old exemption wording
- [RECOMMENDED] Routed: SaveService gaps to Y1-P1-T05 (save suppression, deferred saves, commit rollback, store_* return, Windows rename, refusal off the .bak path); Blocked-by stories in no sprint (producer); L-AC18 live viewport and S6 turn-back (lifecycle); sole_dissent naming and ch1_root_purge (Y2-PP-T17)
Reviewed-Content-Hash: design/gdd/storyline-axes.md 8d750656cc21da4b3c3d4a5992f4f40e13419c05 (revision 10 as reviewed, HEAD 3e0c554; revision 11 differs, so the next run re-reviews in full)
Reviewed-Content-Hash: design/registry/entities.yaml 216ffa67ed4d5d24548df37b2ce899fcba892285

## Review — 2026-11-17 — Verdict: NEEDS REVISION
Scope signal: L
Specialists: game-designer, systems-designer, qa-lead, narrative-director, godot-specialist, creative-director (synthesis)
Blocking items: 8 | Recommended: 9 (plus items routed to Y1-P1-T05, the lifecycle, Y2-PP-T17, Y1-P1-T03 and the producer)
Summary: Round 12 ran in full on revision 11 (HEAD 01bda7f). The static core holds for a twelfth round and the round-11 fixes hold; every blocker is fixable without touching it. The two that matter most are content: Authority dissent is aimed at the restrained player rather than the unilateral one, inverting P10, and Kaelthas can never be present because the Chapter 3 allied path always sets ch3_kaelthas_betrayed. The rest are internal contradictions (D0 shadows D7.duplicate), an AC14 baseline that cannot pass, and play paths (chapter select, no story position) that write saves the load check refuses. The creative-director proposes pre-declared exit criteria for round 13: lean, scoped to the rev-12 diff plus a model re-run with D0 modelled; a new finding blocks only with a failing model case, a textual contradiction or a false citation.
Prior verdict resolved: Yes (round-11 blockers fixed in rev 11; the round-11 Kaelthas fix exposed the code consequence above)
Decisions taken by the user (2026-11-17): revise now.
Findings:
- [BLOCKING] Edge Case 16 / AC9: D0's one-entry cap on retraction_log runs first and exclusively, so D7.duplicate never fires; the D7.multi justification is false ((NONE,HEARTH,RELEASE) admits R2 and R3 faction retractions); the model hides it (D0 not modelled, M11)
- [BLOCKING] Core Rules 1 and 8 / Edge Cases 8 and 16 / L-AC13: legacy-save rule inconsistent (D0 missing field vs LEANING load; Core Rule 1 vs D16); gate "open with an ID stored" ignores live DAMAGED
- [BLOCKING] Acceptance Criteria 14: plurality baseline makes SL-SHARED-ARCHIVE-CHOOSE modal in every single-axis scene; ">= 3 scenes" met by ending scenes alone; no keyed-axis observable
- [BLOCKING] Act 1 seed map / Core Rule 3: all Authority seeds are +, unilateral history gives a clean YOU vote and no sole_dissent; the restrained player hears dissent (inverts P10)
- [BLOCKING] Core Rule 11 / Edge Case 1 / AC11 / 27-row table: ch3_kaelthas_betrayal.gd:35,89 always sets betrayed on the allied path, so the settled trust condition never holds; every Kaelthas companions_possible cell is false
- [BLOCKING] Formulas storyline_phase / Edge Case 16 D16-D17 / Core Rule 8: no story position exists in code; player-facing chapter select writes Ch9/10 state with UNSET axes and ch10_root_intro autosaves a D16-refused save; gate entry paths beyond story/world_map unlisted
- [BLOCKING] Acceptance Criteria 16: (a) pools fixture testers and can pass at 0% unprompted; re-run ">= 6 new" contradicts settled >= 12; (c)/(d) not criteria; no stopping rule
- [BLOCKING] Act 1 seed map: citations fail (PM:1801 states no direction; STORY_BIBLE:206 is a read-by cell; PM:3117/3119 are composer visuals)
- [RECOMMENDED] Core Rule 5 / lifecycle Retractions: costs not felt after C8-S16 (nothing reads retraction_log); offers should reuse seed argument lines; SHARED/CHOOSE beats carry source costs
- [RECOMMENDED] Edge Case 16 D15: scope to the save's schema version (fails inclusion rule ii/iii if a group is fixed later)
- [RECOMMENDED] Edge Case 16 D14 / composer record: text vs model scope; beats_played list vs set
- [RECOMMENDED] Lifecycle invariants / header: "phase depends on the first three" wrong; Last Verified stale; model DIGITS comment contradicts AXIS1=Authority
- [RECOMMENDED] Acceptance Criteria 9: split into 9a-9e; declare story type and real test path per AC (gdUnit4 absent; SceneTree harness)
- [RECOMMENDED] Acceptance Criteria 11/13/17: observables (bare storyline_id; AC17 needs lock_arguments); AC11 per-flag rewrite; mirror-flag AC
- [RECOMMENDED] Acceptance Criteria 15: require >= 1 row per arc
- [RECOMMENDED] Side storylines: arc 08 has source faction effects (PM:3681-3682)
- [RECOMMENDED] Core Rule 10 / AC14: record within-family "colour only" as deliberate, or one Deleted-keyed beat per family
Reviewed-Content-Hash: design/gdd/storyline-axes.md 7b0f9cb6c6fe0e6e3796052800bcdcaf9c27abbd (revision 11 as reviewed, HEAD 01bda7f)
Reviewed-Content-Hash: design/registry/entities.yaml 216ffa67ed4d5d24548df37b2ce899fcba892285

## Review — 2026-11-17 — Verdict: NEEDS REVISION
Scope signal: M
Specialists: game-designer, systems-designer, qa-lead, narrative-director, godot-specialist, creative-director (synthesis)
Blocking items: 15 (6 substantive, 9 one-line) | Recommended: 10 (plus items routed to Y1-P1-T05, Y2-PP-T17, the producer and the lifecycle)
Summary: Round 13 ran in full on revision 12 (HEAD 01bda7f, uncommitted rev 12). The static core holds for a fifth round running; most blockers were introduced by revision 12's own new text (the story-position contract, the D0 cap, the Authority seeds) or a fix not carried into the lifecycle (gate_open). The Authority seed map still contradicts its own answered-not-acted principle, so a purge-and-edit player passes YOU clean. The creative-director states a blocking bar (a refused or stranded play save or an AC that cannot pass; a rule contradiction; a citation that does not say what it is cited for) and exit conditions for round 14 (adopt OQ20, fix only the list, one canonical statement per repeated rule, model re-run with full D0 and entry positions). All 15 blockers were fixed in revision 13 (lifecycle revision 9) in the same session and verified: checker PASS, 323 mutations / 1 control / 0 unexpected, reference model RESULT PASS (rev 12, 11, 10 and 9 texts still fail as regressions; residual categories asserted). Recommended and routed items were not applied. A fresh re-review is still owed.
Prior verdict resolved: Yes (round-12 blockers fixed in rev 12; three of its fixes opened new defects)
Decisions taken by the user (2026-11-17): revise now; ch1_root_purge moves from faction:HEARTH+ to authority:YOU−; arc 08 is mapped to Faction (ten 1.0 seed arcs).
Findings:
- [BLOCKING] Act 1 seed map / Core Rule 3: ch1_root_first_edit (act) and ch1_root_discovered_unused (non-act) contradict the answered-not-acted principle; purge has no Authority seed (P10 inversion relocated)
- [BLOCKING] Lifecycle NG+ reset: story position not reset; NG+ record refused by D16, L-AC15 cannot pass, I9 broken
- [BLOCKING] Terms story position / Edge Case 8 / D16: a pre-schema save holds no position, yet position is "never derived"; Edge Case 8 first sentence contradicts its third
- [BLOCKING] Edge Case 8 / lifecycle Chapter select: rule keyed to chapter number; "Chapter 8 - Ending" (main_menu.gd:655-662) starts past the locks and ch8_ending.gd:15 autosaves a D16-refused save
- [BLOCKING] Edge Case 16 D0 / D14: D0's enum check on beats_played shadows D14.undefined; beats_played cap 16 is dead (model only type-checks beats_played)
- [BLOCKING] Side storylines: arc 08 "pushes no axis" contradicts PM:3681-3682 (faction effects)
- [BLOCKING] Lifecycle gate_open(): "true exactly when an ID is stored" ignores a live DAMAGED record
- [BLOCKING] Act 1 seed map notes: "someone must be answerable" is verbatim at neither PM:636 nor PM:7048
- [BLOCKING] Open Question 6: "uses the 4" companions contradicts Core Rule 11's three
- [BLOCKING] Lifecycle L-AC14: PM:3814 is the Chapter 3 end ledger, not arc 09 completion
- [BLOCKING] Open Question 13: pairwise minimum 1 contradicts AC14's 2
- [BLOCKING] Edge Case 13 / Tuning Knobs: "knobs read only at C8-S16 and the gate" contradicts C9-S18 reading secret_prerequisites[FIRSTWAKE]
- [BLOCKING] Formulas storyline_phase example: (SHARED, ARCHIVE, CHOOSE) live in C8-S16 fires {D9, D17}, not D9
- [BLOCKING] Act 1 seed map notes: aldric.dlg:85 is a reminder, not a rebuke
- [BLOCKING] Edge Case 1: PM:788 says only "ally or betrayer"
- [RECOMMENDED] AC9: knob-flip clause vacuous; split 9a-9e; D0 precedence fixture
- [RECOMMENDED] AC10: wording contradicts the phase_of signature
- [RECOMMENDED] AC11: no module-to-companion observable; Kaelthas combinations mostly unreachable
- [RECOMMENDED] AC14: rater rubric; AC15 wording; AC17 (flag, value, sign)
- [RECOMMENDED] AC16(a): passable at 0% unprompted; Wilson bound unused
- [RECOMMENDED] Lifecycle L-AC11: assert no field but root_phase changes
- [RECOMMENDED] Player Fantasy "Costs are real": no AC that an ending shows its danger line
- [RECOMMENDED] Player Fantasy "Nobody is forced to agree": no companion dissent line
- [RECOMMENDED] Core Rule 6 / I6: define "hint" as a journal or UI signpost (C9-S18, arc 12 quest log)
- [RECOMMENDED] Interactions: one gate chokepoint and a ROOT_SCENES list; I9 reopened by GDD revision if Y1-P1-T05 cannot build it
- Routed: save API checkpoint/suppression and refusal-as-corruption (Y1-P1-T05); Root entry callers and change_scene bypasses (Y2-PP-T17 with Y1-P1-T05); Y1-P1-T03 scope and T03/T05/T17 in no sprint (producer); end-to-end seeds-to-sole_dissent test (lifecycle L-AC, Y2-PP-T17)
Reviewed-Content-Hash: design/gdd/storyline-axes.md 74b86ac0766c77d43b319acdaec07e50a293c573 (revision 12 as reviewed, uncommitted on HEAD 01bda7f; revision 13 differs, so the next run re-reviews in full)
Reviewed-Content-Hash: design/registry/entities.yaml 216ffa67ed4d5d24548df37b2ce899fcba892285

## Review — 2026-11-18 — Verdict: NEEDS REVISION
Scope signal: L
Specialists: game-designer, systems-designer, qa-lead, narrative-director, godot-specialist, creative-director (synthesis)
Blocking items: 6 | Recommended: 11 (plus items routed to Y1-P1-T05 and Y2-PP-T17)
Summary: Round 14 ran in full on revision 13 (uncommitted on HEAD 01bda7f) under the round-13 bar. The static core holds for a sixth round running; five of the six blockers sit in text added in revisions 12-13 or in the ACs, and two (act1_pace, story_position) were invisible to the reference model because it models only the lifecycle fields. The creative-director's most important creative finding is below the bar: the Chapter 4 Null Court promise (ch4_choice_*_deleted, read in Chapters 5 and 10) is not a Deleted seed. The creative-director recommended adopting Open Question 20 with a scope freeze; the user adopted it.
Prior verdict resolved: Yes (round-13 blockers hold, except that the rev-13 purge rationale inverts its source)
Decisions taken by the user (2026-11-18): revise now; adopt Open Question 20 with a scope freeze (revision 14 fixes only the blockers, the reference model is extended to the full record, round 15 runs lean on the diff and is the last if it finds only one-line blockers).
Findings:
- [BLOCKING] Act 1 seed map notes / Open Question 10: purge rationale cites PM:663 "agency intact" but the purge path leaves Aldric lucid (aldric.dlg:119-133); PM:1806 is the spare path; "without his consent" not in dlg:57
- [BLOCKING] Terms story position / Edge Case 8 / D0: position is not a record field yet "missing → D0 refuses"; legacy scene map cannot place a hub save (hubs autosave)
- [BLOCKING] Composer record / D0: act1_pace has no UNSET, so D0 refuses every save before the end of Act 1 (I9)
- [BLOCKING] Acceptance Criteria 11: Faction sentence contradicts Core Rule 3 and AC14; companion/Kaelthas clauses have no observable
- [BLOCKING] Acceptance Criteria 9: mutation kill unmeetable (D0 sub-clauses without fixtures or ids); D7.new_mismatch construction reports two clauses
- [BLOCKING] Acceptance Criteria 15: arcs 08/12 secret-only flags have no pushes type; closing condition filed as advisory
- [RECOMMENDED] Acceptance Criteria: no lock_pass AC with an Authority − seed; seeds → sole_dissent untested end to end (top priority)
- [RECOMMENDED] Act 1 seed map: YOU clean ~27% (estimate) so sole_dissent is the YOU default; sole_dissent should name its seed
- [RECOMMENDED] Player Fantasy: "vote between proposals" overclaims; "always passes" is a tightening of PM:6990
- [RECOMMENDED] Acceptance Criteria: no AC that an ending shows its danger line; companion "they argue" has no content; S13/S14 source arguer is Kaelthas
- [RECOMMENDED] Act 1 seed map notes: Authority discriminator is a table with exceptions; purge-then-disclose negotiated YOU intended
- [RECOMMENDED] Player Fantasy: line 73 "no hint" vs line 76 C9-S18; STORY_BIBLE:109 still lists Kaelthas
- [RECOMMENDED] Detailed Design (Side storylines / seeds): Chapter 4 Null Court Deleted choice unmapped (needs user decision)
- [RECOMMENDED] Chapter select / Tuning Knobs / D1 / prereqs: True Ending entry writes FINAL; knob read site; D1 id; distinct prerequisite flags; variable tables
- [RECOMMENDED] Acceptance Criteria hygiene: split AC9; AC16 Wilson bound; AC17 tuple; AC10; AC5 mutant; AC12; re-block ACs 5-9 on T03/T05
- [RECOMMENDED] Header: P5/P8 "implements" → "supplies state for"
- [RECOMMENDED] Formulas: lock_pass, storyline_phase, family, Counts lack variable tables
- Routed (Y1-P1-T05 / Y2-PP-T17): save suppression inside save_game and the deferred flush (pause-menu save in the crisis); load_check outside _read_valid_save; JSON type pinning; static scan for gate bypasses; ROOT_LEFT writer
Reviewed-Content-Hash: design/gdd/storyline-axes.md 530341eb71de5d5b58d81cf0318b73c51abfd54c
Reviewed-Content-Hash: design/registry/entities.yaml 216ffa67ed4d5d24548df37b2ce899fcba892285

## Review — 2026-11-18 — Verdict: APPROVED
Scope signal: XL (earlier rounds logged L; 9 dependencies and protected save/story/world-map touchpoints put it at XL by the rubric; producer to verify)
Specialists: none (lean; single-session review under the Open Question 20 bar)
Blocking items: 0 | Recommended: 6
Summary: Round 15 ran lean on revision 14 (HEAD 8187f90) under the Open Question 20 bar: a finding blocks only with a failing model case, a contradiction in the text or a false citation. The checker was re-run and passes (0 problems); the reference model log (PASS on the rev-14 text, rev 9-13 still fail) is newer than both GDDs and was not re-run in this session. The rev-14 citations resolve against the dialogue, code and PM lines. Approval is under the user-adopted bar, not an adversarial specialist sign-off; routed items stay open.
Prior verdict resolved: Yes (the six round-14 blockers hold)
Findings:
- [RECOMMENDED] Act 1 seed map notes / Open Question 10: the purge rationale says Kaelen did not state the cost before acting, but aldric.dlg:106 shows "I don't know" before the choice (:109) and :132 "Mostly, I think"; under the table's own "disclosed or doubted -> SHARED +" rule the cited evidence points the other way (reword to "states it to Elara, never to Aldric", or let AC16 decide)
- [RECOMMENDED] Core Rule 11 / Edge Case 1 / Open Question 19: ch3_kaelthas_betrayal.gd:35,89 reads as two set sites; :35 is the branch, :89 the set
- [RECOMMENDED] Edge Case 16 D14: clause ids (undefined, no_entry, not_played) used by AC9 are not tagged in the item text
- [RECOMMENDED] game-concept.md:264,345,349 say 27 endings at Alpha; the GDD ships 24 in 1.0 (already routed)
- [RECOMMENDED] Carried from round 14 (frozen): lock_pass golden-vector AC with an Authority - seed; seeds -> sole_dissent end to end; header P5/P8 wording; variable tables for lock_pass, storyline_phase, family, Counts; PM:6990 tightening
- [RECOMMENDED] Tuning Knobs secret_unlock_flag: add "(post-1.0)" to "set when the invocation scene plays"
- Routed, still open: Y1-P1-T05 save checkpoint/suppression and refusal-as-corruption; Y2-PP-T17 Root entry callers/ROOT_SCENES; T03/T05/T17 in no sprint (producer); protected-area approvals per implementing story
Reviewed-Content-Hash: design/gdd/storyline-axes.md e9a26b2b82f7f447648eec27f3cbc581dee453df
Reviewed-Content-Hash: design/registry/entities.yaml 216ffa67ed4d5d24548df37b2ce899fcba892285

## Review — 2026-11-19 — Verdict: APPROVED (erratum lines, lifecycle round 16)
Scope signal: XL (unchanged)
Specialists: none (lean; covered by the lifecycle round-16 review under lifecycle Open Question 7)
Blocking items: 0 | Recommended: 1
Summary: Revision 15 is an erratum after the lifecycle review of 2026-11-18 (user decision 2026-11-19). Its new lines are the status header, the `kaelen_commitment` composer row, the stored-field sentence, the AC3 field list, the D0 commitment clause, the AC9 fixture, the lifecycle Dependencies row and the C9-S18 protected-touchpoints wording. The round-15 receipt (e9a26b2) does not cover them. Lifecycle round 16 reviewed them: the commitment invariant (UNSET exactly when the record never held YOU) agrees with lifecycle S2, T2, T5, L-AC12, chapter select and the NG+ reset; PM:7054-7059 resolves; the C9-S18 wording now matches Core Rule 6 and lifecycle S5. Checker PASS, 383 mutations / 0 unexpected, reference model REV15 PASS. The rest of the document is unchanged since round 15.
Prior verdict resolved: Yes (round 15 APPROVED stands for the unchanged lines)
Findings:
- [RECOMMENDED] Header: "Last Verified" still reads 2026-11-18 after the revision-15 erratum
Reviewed-Content-Hash: design/gdd/storyline-axes.md 775318b641bd5c85d0af8da2eb91bc2d9a6ccaee
Reviewed-Content-Hash: design/registry/entities.yaml 216ffa67ed4d5d24548df37b2ce899fcba892285
