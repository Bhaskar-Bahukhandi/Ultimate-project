# Review log: storyline-lifecycle.md

## Review — 2026-11-10 — Verdict: NEEDS REVISION
Scope signal: L
Specialists: game-designer, systems-designer, narrative-director, qa-lead, creative-director (synthesis)
Blocking items: 8 | Recommended: 13
Summary: The approach is sound and the state machine has no in-play soft-lock; T8 is the one real contradiction.
The blockers are canon content missing from the Consent and deferral scope, save-record gaps, the I5 hole for saves
past Chapter 8, missing deferral-resolution beats and weak ACs. Open user decisions: Q1 visible clean/negotiated
(CD: ledger Variants/Policies, PM:7569-7582), Q2 witness threshold failure (CD: ID unchanged, "authorized over
dissent" module), Q3 gate renegotiation scope (CD: Authority only plus invocation), Q4 R1 red-line clause when the
Witness signpost is OPEN (CD: clause grounded in PM:8411). Tripwire: if the second review finds new state-machine
contradictions, move the deferral to post-1.0.
Prior verdict resolved: First review
Decisions taken by the user (2026-11-10): Q1 (c) clean vs negotiated becomes visible through a SOLE-family dissent module keyed on lock_negotiated (authority); Q2 (b) the witness threshold can fail at C10-S15, the stored ID is unchanged and an "authorized over dissent" / failed-mandate ending module plays; Q3 (c) LAST_CHANCE keeps all six R1 renegotiations, each with an explicit retcon beat for Act 3 content already played as HEARTH/RESTORE; Q4 (b) when signpost(WITNESS) is OPEN the C8-S15 Hearth red line adds a clause grounded in PM:8411 ("unless the affected themselves authorize it").
Findings:
- [BLOCKING] Consent variants / S8: list misses PM:8411, 8438, 8495, 8533-8542, 8617-8618, 8797 and AXIS1_YOU companion reactions; S8 omits route lines PM:8795-8805
- [BLOCKING] Consent (L-AC14): threshold has no failure case; 7/7 dissent still yields "Authorized by the Living" (user Q2)
- [BLOCKING] S5 deferral: ignores Hearth branch PM:7220+, C8-S20 signing PM:7424-7426, ~19 Chapter 9 scenes; "final act" undefined
- [BLOCKING] Inputs and outputs: retraction_log and beats_played not in the saved record; withdrawn item lost on reload
- [BLOCKING] S7 / I5: a save past C8-S16 with axes UNSET loads LEANING and is TURNED_BACK forever (chapters 1-10 exist in code)
- [BLOCKING] S5-S7: no beat when the deferral is kept or broken, no narrowing beat
- [BLOCKING] Acceptance Criteria: offers() undefined in C9-S19 and vacuous elsewhere; L-AC14 no threshold; L-AC16 no load_errors() empty; L-AC7 false for T7/T8; route-bot pass rule blind to gate outcome; checker lets 21 of 22 mutations survive
- [BLOCKING] S4 retractions: "16 beats" are 12 distinct ids (R2/R3 collide on four)
- [RECOMMENDED] S5: "Hearth withholds endorsement" is new content, not PM:7144; label and approve
- [RECOMMENDED] Player Fantasy: PM:723 does not support "said by someone who loses by it"
- [RECOMMENDED] S4: faction-swap demands incoherent (Hearth demanding ARCHIVE)
- [RECOMMENDED] Consent: PM:8704 "Kaelen may be one" exclusion is a design narrowing; state it
- [RECOMMENDED] Formulas: crisis_offers has no domain guard (valid row returns six offers)
- [RECOMMENDED] States and Transitions: NG+ is an undeclared backward transition (T14); reset list leaks seed/unlock flags
- [RECOMMENDED] Formulas: signpost tests HIDDEN before CLOSED; a patch hides a closed entry (I6)
- [RECOMMENDED] S6: C9-S18 / C9-S20 behaviour while their routes are disabled
- [RECOMMENDED] S6: C9-S19 timing when prerequisites complete after its slot
- [RECOMMENDED] S7: gate_open() true in Chapter 8; stored-ID check necessary, not sufficient
- [RECOMMENDED] L-AC9: about 10 of 18 gate-matrix cells impossible in play; label synthetic
- [RECOMMENDED] L-AC17: arc 05/08/09 flags not named
- [RECOMMENDED] S4/T6: deferral may be a trap when an Act 2 prerequisite is already missable
Reviewed-Content-Hash: design/gdd/storyline-lifecycle.md 854a645aaf420b8a28d5d7698253c2b99c98936f
Reviewed-Content-Hash: design/registry/entities.yaml 216ffa67ed4d5d24548df37b2ce899fcba892285
