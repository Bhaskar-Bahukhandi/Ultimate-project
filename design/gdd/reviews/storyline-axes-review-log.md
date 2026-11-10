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
