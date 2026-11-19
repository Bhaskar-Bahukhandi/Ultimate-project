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

## Review — 2026-11-18 — Verdict: NEEDS REVISION
Scope signal: XL
Specialists: game-designer, systems-designer, narrative-director, qa-lead, godot-specialist, creative-director (synthesis)
Blocking items: 13 | Recommended: 9 (plus items routed to Y1-P1-T05, Y1-P1-T03, Y2-PP-T17)
Summary: Full review of revision 10 (HEAD 8187f90), the first standalone lifecycle review since 2026-11-10. The core holds (T1-T9, crisis_offers, red lines, the gate phase table); defects cluster where abstract scene ids meet real scene files (chapter select, Root scene set, position writers, legacy Ch8/Ch10 scenes), where the commit/save rule meets the engine (checkpoint order, resume point, per-transition windows), and in AC observables. The creative-director proposes a scope freeze modelled on axes Open Question 20 (rev 11 changes only items 1-13; model extended to the lifecycle; next round lean on the diff).
Prior verdict resolved: Yes for the 2026-11-10 items (T14 cut, Witness deferral moved post-1.0, one commit rule, Visual/UI evidence, cut order); new defects in later additions (chapter select, story position)
Decisions taken by the user (2026-11-18): revise in a new session.
Findings:
- [BLOCKING] Chapter select: L195 writes CH9 for every Root of Heaven entry; Final Confrontation and True Ending become FIXED without T9; Saved Assembly and Revolt Crisis unplaced; 13 Ch8-10 entries need their own rows, L-AC19 and the model to cover all 13
- [BLOCKING] Scene contracts: no placement table mapping Ch8-10 scene files and hubs to S-ids and positions; Root scene set and load-gate positions unenumerated; writers of CH9, ROOT_LEFT, FINAL_AUTH_OPEN, STORY_PLUS, ROOT_STORY_PLUS unnamed; ch8_revolt_crisis.gd and ch10_sovereign_confrontation.gd not listed as superseded
- [BLOCKING] Chapter select / S6: checkpoints "before its entry scene loads" and "before any loaded state is applied" cannot be written (save_game refuses in MENU and on main_menu, game_manager.gd:1441,1460); state the outcome, route the mechanism to Y1-P1-T05
- [BLOCKING] Acceptance Criteria L-AC6: undefined for T1, T2, T7, T9 (no beat, no offer row, no T7 window); per-transition window table
- [BLOCKING] Observables: take() is false whenever offers() is empty, so L-AC6/9/11 checks outside the crisis cannot fail; route take() through the T5 handler
- [BLOCKING] Acceptance Criteria: observables used but not in the table (story position, region locked, checkpoint exists, C9-S18 form, scenes played, data-error log)
- [BLOCKING] Acceptance Criteria L-AC8: load x VALIDATED counted at L387, excluded at L395/L467
- [BLOCKING] S2 / Retractions / L-AC12: the quoted commitment (PM:7054-7059, three YOU variants) has no record field; add kaelen_commitment (axes record erratum, user decision) or cut the variants
- [BLOCKING] Player Fantasy / Retractions / L-AC16: "answered by the person whose position it was" vs Kaelen forbidden as speaker; define answerer and a cast-independent fallback
- [BLOCKING] Inputs / Tuning Knobs: knob read sites differ (L61 vs L302)
- [BLOCKING] NG+ reset: omits act1-4_pace, timing_flags, companions_present, regions_completed; reset every record field, L-AC15 checks all and mirror flags
- [BLOCKING] S6: TURNED_BACK has no destination (black screen at ch9_ending.gd:28); name the landing per path
- [BLOCKING] Citations: PM:8206 -> 8206-8207; "cannot be saved" is I9 not PM:7143/7153; OQ4 PM:7102-7106 is the RESTORE hearing
- [RECOMMENDED] S7: checkpoint at boss victory, no suppression across the final authorization
- [RECOMMENDED] S4: show the withdrawn item and ending effect before an offer is taken (crisis weight)
- [RECOMMENDED] S3: R2 red line omits "without Root capacity" (PM:7147); sole_dissent excludes the faction that demanded YOU
- [RECOMMENDED] Chapter select: provenance tag so Story+ and NG+ never treat an authorship-free ending as earned (user decision)
- [RECOMMENDED] Content scope: ids for 16 offer voicings, 3 coalition-break lines, withdrawal and restated commitment lines
- [RECOMMENDED] S7 / Open Question 3: confirm order (PM:8790) and line source unsettled while L-AC11 pins one
- [RECOMMENDED] Acceptance Criteria: L-AC2 Authority minus fixtures; L-AC3 testable; L-AC16/cut order 9 texts; L-AC18 total 25 + manifest + load-refusal menu; L-AC14 per-arc fixtures; story type per L-AC; Blocked-by consistency
- [RECOMMENDED] Formulas: variable table and worked example for crisis_offers
- [RECOMMENDED] S6: "a new caller cannot skip it" as a requirement backed by a static scan
- Rulings: PM:8206 precision fix not false citation; commitment field blocking; L-AC6 blocking; C9-S18 decrypted form stays (user decision axes round 11; axes L796 "incomplete form" is a stale axes erratum); TURNED_BACK settled by item 12; L-AC14 recommended
- Routed: Y1-P1-T05 load-refusal plumbing, suppression in save_game and deferred flush, rollback on Leave/quit; Y1-P1-T03 scene-change chokepoint (~107 wrapper calls, ~32 direct sites, 2 string-form deferred calls, screen_transition.gd:264) and free-travel unlock override; Y2-PP-T17 C9-S18 lines with Seraphina-absent fallback, _ready autosaves in superseded scenes
Reviewed-Content-Hash: design/gdd/storyline-lifecycle.md e600bc607b61e4addc57534be82bba4fa7c9c736
Reviewed-Content-Hash: design/registry/entities.yaml 216ffa67ed4d5d24548df37b2ce899fcba892285

## Review — 2026-11-19 — Verdict: APPROVED
Scope signal: XL (unchanged from 2026-11-18; producer to verify)
Specialists: none (lean, round 16; single-session review under the lifecycle Open Question 7 bar)
Blocking items: 1 (fixed in this session) | Recommended: 4
Summary: Round 16 ran lean on the revision-11 diff against 8187f90 and on the axes revision-15 erratum. A finding blocks only with a failing model case, a contradiction in the text or a false citation. All 13 blockers of 2026-11-18 are fixed. The new PM and code citations resolve: PM:7036-7038, 7045-7059, 7064-7069, 7078-7087, 7102-7106, 7138-7153, 8206-8207 and 8786-8806; game_manager.gd:1441 and 1348-1357; main_menu.gd:655-662; the ch8, ch9 and ch10 scene lines; the boss scene autosaves through late_game_hazard_trial.gd:44. One contradiction that revision 11 introduced was fixed with the user's approval: the new story-position writer table has T8 write `ROOT`/`ROOT_STORY_PLUS`, while S6's FIXED/FINAL row and Edge Case 2 said T8 changes nothing. Both now say that nothing changes but the story position, and the checker pin and the r9_gate_row_dropped target follow them. Re-verified on the final text: checker PASS (0 problems); 383 mutations FAIL / 1 control PASS / 0 unexpected; reference model RESULT PASS in 392.8 s (rev 9-14 texts still fail); git diff --check clean. Logs were written to the scratchpad and copied in. Approval holds under the user-adopted bar; it is not an adversarial specialist sign-off, and routed items stay open.
Prior verdict resolved: Yes (13/13: chapter select 13 rows; scene placement and writers; outcome-stated checkpoints; window table; take() through T5; observables; L-AC8 load x VALIDATED counted; kaelen_commitment; delegate answerer; one knob statement; full NG+ reset; turn-back landings; citation errata)
Findings:
- [BLOCKING, FIXED] S6 outcome table / Edge Case 2: "nothing changes (T8)" contradicted the writer table's T8 position writes; now "nothing changes but the story position"
- [RECOMMENDED] Legacy saves: the dev-fixture migration names axis values and an ID but not `kaelen_commitment`; a YOU fixture left UNSET is refused by D0.enum
- [RECOMMENDED] L-AC19: "every save before the first player input" is vacuous for row 3 (its first save, T1's checkpoint, follows the vote); name the checked save per row (row 3: S13_DONE, PARTLY_LOCKED)
- [RECOMMENDED] Chapter select: "every save written after a chapter-select start, from the first, holds ... the row's position" reads as every later save; restrict it to the first save
- [RECOMMENDED] Observables: `quoted_commitment()`'s NONE value sits in the "outside its scene" column; move it to "returns"
- Routed, still open: Y1-P1-T05 (chapter-select record, load-path gate, T7 checkpoint, suppression); Y1-P1-T03 (scene-change chokepoint); Y2-PP-T17 (lock scenes, final authorization, C9-S18, retraction beats, placement-range confirmation); protected-area approvals per implementing story; the 9 recommended items of 2026-11-18; systems-index entry (producer)
Reviewed-Content-Hash: design/gdd/storyline-lifecycle.md b74291b34c5c6b4359b2b8d6c2fa9ec0c7797598
Reviewed-Content-Hash: design/registry/entities.yaml 216ffa67ed4d5d24548df37b2ce899fcba892285
