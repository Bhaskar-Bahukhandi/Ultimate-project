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

## Review — 2026-11-10 — Verdict: NEEDS REVISION
Scope signal: L (M once T14 is cut)
Specialists: game-designer, systems-designer, narrative-director, qa-lead, creative-director (synthesis)
Blocking items: 8 | Recommended: 7
Summary: T1-T13 are sound. The round-1 tripwire fired on T14, the author-added legacy catch-up (legacy code already
sets its own ch8/ch10 storyline flags: ch8_revolt_crisis.gd:127-128, game_manager.gd:371-401), which is cut to a
dev-fixture migration. The deferral stays in 1.0 on probation once the gate guard, the offer disclosure and the save
window are fixed; the FAILED vote needs an S8 guard, persisted threshold/dissenters, an assent source and a rename;
ACs need fail-capable assertions, a gate-invocation AC and Visual/UI evidence.
Prior verdict resolved: Partly (Q1-Q4 implemented; Consent list, record fields, beats, signpost order addressed); the
author's own additions (T14, C9-S19 window, FAILED vote) opened the cluster below.
Tripwire ruling (CD, user-confirmed): fired on T14, not the deferral; any further state defect in T6-T9 / S5-S7 moves
the deferral post-1.0 without debate.
Decisions taken by the user (2026-11-10): (1) a FAILED witness vote is not executed: restoration does not happen,
Kaelen stands down at S8 (FINAL, not executed), ID and family unchanged; (2) T14 cut to a dev-fixture migration, saves
past Chapter 8 declared unsupported (valid while no player-facing build has such saves); (3) deferral kept in 1.0 on
probation; (4) witness_threshold fixed at 5, data-defined; the player's part (PM:8707) is choosing the witnesses in
Secret Quest 09, which drives dissent.
Findings:
- [BLOCKING] States and Transitions (T14) / Legacy saves: completed legacy saves stranded (never FINAL), faction picked against played branch, C8-S15 skipped, T10/T14 overlap, impossible L-AC9 cells, L-AC20 disjunction
- [BLOCKING] S6/S7 (gate invoke guard): needs SEVEN_WITNESSES_AVAILABLE, set only by C9-S19; invoke on prereqs_met and set the flag at the gate
- [BLOCKING] S4 / Edge Case 1 / L-AC5: save window defined three ways; one atomic checkpoint at the commit
- [BLOCKING] S4 (deferral offer): blind bet; disclose YOU narrowing, Act 3 as Hearth, gate retcon
- [BLOCKING] S8/S9 (FAILED vote): no assent source, threshold and dissenters not saved, confirm_execution unguarded, "authorized over dissent" misnamed
- [BLOCKING] Acceptance Criteria: L-AC8/10/13 offers()-empty cannot fail; no gate-invocation AC; L-AC19 order on a set; route-bot pass rule undefined for 41/66 runs; world_map cells
- [BLOCKING] Acceptance Criteria: no Visual/UI evidence or sign-off for player-observable beats and screens; no content-completeness test
- [BLOCKING] Scope: ~27 beats + 70 Tier B lines + rare-path modules; cut order and producer sign-off
- [RECOMMENDED] S4: offers voiced as the faction's demand break canon voices (PM:7102-7106, 7141); voice as conceding or brokered
- [RECOMMENDED] S4 retraction table: Faction retraction withdraws the charter (PM:7003) vs "steps down and stays in"; PM:7409 analogy only
- [RECOMMENDED] S3: witness clause is Kaelen's PM:8411 line; reword in Hearth's voice
- [RECOMMENDED] S7: LAST_CHANCE delegates absent (remote link, PM:8393); unlimited re-entry plays as a menu
- [RECOMMENDED] S5/S7: Chapter 9 axis-reading scenes (PM:7958, 8021-8025, 8133); Consent variants miss PM:8475, 8457-8459
- [RECOMMENDED] S5/Consent: deferral_c8s20 hook to H-S04 PM:7280; B22 to combat; companion reactions 4 templated + 4 specific
- [RECOMMENDED] Formulas/Invariants: signpost HIDDEN vs CLOSED with ID stored; I5 wording while DEFERRED; retract_R1_* context; NG+ previous-record location
Reviewed-Content-Hash: design/gdd/storyline-lifecycle.md 285b8aa5c31a29c1ace0805b96a56cef0fc7ec6c
Reviewed-Content-Hash: design/registry/entities.yaml 216ffa67ed4d5d24548df37b2ce899fcba892285
