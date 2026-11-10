# Storyline Lifecycle

> **Status**: Draft (revision 2, after design review round 2 of this document, 2026-11-10)
> **Author**: Claude with the project lead
> **Last Updated**: 2026-11-10
> **Implements**: the invariants I1-I8 of `design/gdd/storyline-axes.md`; contract for Y2-PP-T17 (ending composer /
> route data model)
> **Implements Pillar**: P3, P5, P8 (through `storyline-axes.md`)

## Summary

The scenes and transitions that turn the three story axes into one stored storyline ID: the three lock scenes, the
red-line beat, the C8-S16 crisis (renegotiate, or defer to the witnesses on R1), the provisional coalition, the
Witness Protocol invocation and witness vote, the ID-lock gate on every path, and the final authorization (confirm,
or stand down after a failed vote). `storyline-axes.md` owns the values, the formulas and the record; this document
owns when each field is written and which beats play.

> **Quick reference** — Layer: `Foundation` · Priority: `Alpha` · Depends on: `storyline-axes.md`

## Overview

Chapter 8 locks Faction (C8-S13), Authority (C8-S14) and Deleted (C8-S16), in that order. A valid row is stored at
once. An invalid row breaks the coalition inside C8-S16, and the scene does not end until it holds again: the player
takes one of the refusing faction's demands (a renegotiation of one axis) or, on R1 with the Witness Protocol
signpost open, defers to the witnesses after the offer has said what deferring costs. A deferral is a provisional
coalition: Hearth stays in the Assembly but does not endorse the final act (the irreversible Root act Kaelen
executes after the boss) until the player invokes the protocol at C9-S19 or at the gate; renegotiating at the gate
breaks the deferral instead, with a beat that says what the Act 3 already played under Hearth now means. On Witness
Protocol the seven witnesses the player seated vote at C10-S15; a vote that falls short is not executed, and Kaelen
stands down. Every entry and re-entry into Root of Heaven runs one gate check; a save made past Chapter 8 before
these fields existed is unsupported and does not load; the final authorization only confirms or stands down. There
is no state in which a player can be stranded, and no transition back from a stored ID.

## Player Fantasy

- **A crisis is a negotiation, not an error.** The coalition breaks as "a political crisis rather than a menu error"
  (PM:723). The refusing faction speaks its terms; the player chooses which concession to make, and the concession
  is withdrawn on the record and answered by the person whose position it was (new content, the retraction beats).
- **A deferral is a promise you keep or break, knowingly.** Before the player defers, the offer says what it costs;
  the room remembers through Act 3 that Hearth has not endorsed the final act, the player knows what still has to
  be done to earn it, and keeping or breaking the promise each plays its own beat.
- **A vote you can read.** The player chooses who sits as a witness and sees where each one stands; the vote names
  every dissent, and a vote that falls short stops the act instead of being overruled.
- **No dead ends.** Every unresolved state has a way out that the fiction states; a closed door is shown closed.

## Detailed Design

### Inputs and outputs

Reads and writes the composer input record of `storyline-axes.md` (fields `authority`, `faction`, `deleted`,
`storyline_id`, `witness_deferred`, `root_phase`, `secret_invoked`, `axis_revised`, `lock_negotiated`,
`retraction_log`, `beats_played`, `witness_seats`, `witness_dissenters`, `witness_mandate`) and the seed,
prerequisite and unlock flags. Every field is saved, so a reload restores the retractions and beats exactly.
`storyline_phase` is derived (`storyline-axes.md` Formulas), never stored. Knobs are read only at C8-S16, the
invocation scenes and the gate.

### Scene contracts

**S1 — C8-S13 First Assembly Vote (Faction lock).** Offers all three Faction values as proposals; voices each set
Faction seed as an argument (value, sign); the vote passes for the backed value; `lock_pass` decides whether
`lock_negotiated` gains `faction`. Voices no red line. Plays only with every axis UNSET.

**S2 — C8-S14 Root Authority Hearing (Authority lock).** As S1 for Authority. Plays only with Faction set and
Authority UNSET. When YOU is backed, Kaelen states his commitment (PM:7045-7057); that is the commitment SOVEREIGN
quotes (PM:7059) unless it is later withdrawn or narrowed.

**S3 — C8-S15 hearings (red-line beat).** Plays with Faction and Authority set. If the locked pair is one Deleted
value away from an invalid row, the delegate of the faction that would refuse states its red line as a value, never
naming the combination:

| locked pair | speaker | rule | the value voiced |
|---|---|---|---|
| YOU + HEARTH | Hearth delegate | R1 | no one hand compels the deleted back |
| NONE + ARCHIVE | Archive delegate | R2 | no release that destroys unresolved memory appeals |
| NONE + CONTINUITY | Continuity delegate | R3 | no irreversible release while emergency Root is abolished |
| any other pair | — | — | no red line |

The canon refusals behind each line are PM:7141, PM:7147 and PM:7151; the lines are new content (user approval
2026-11-10; line ids `red_line_R1`, `red_line_R2`, `red_line_R3`). **Witness clause (R1 only, user decision
2026-11-10):** when `signpost(WITNESS)` is OPEN, the Hearth delegate's line adds the clause "unless the affected
themselves authorize it" (line id `red_line_R1_clause`), grounded in the Witness answer of the Last Offer ("The
affected authorize the act.", PM:8411). It names the institution, never the combination (Core Rule 6 of
`storyline-axes.md`); with the signpost HIDDEN or CLOSED the line has no clause.

**S4 — C8-S16 Axis Three Lock and crisis.** Offers all three Deleted values. On a valid row it stores the ID (T3).
On an invalid row the refusing faction breaks the coalition, naming the combination for the first time
(PM:7138-7153), and the scene becomes the crisis (T4). The crisis cannot be left, skipped or saved until an offer
is taken (PM:7143, PM:7153). Its offers, each voiced as the refusing faction's demand:

| row | offers |
|---|---|
| R1 YOU-HEARTH-RESTORE | `revise:authority:SHARED`, `revise:authority:NONE`, `revise:faction:ARCHIVE`, `revise:faction:CONTINUITY`, `revise:deleted:RELEASE`, `revise:deleted:CHOOSE`; plus `defer:WITNESS` when WITNESS is enabled and its signpost is OPEN |
| R2 NONE-ARCHIVE-RELEASE | `revise:authority:YOU`, `revise:authority:SHARED`, `revise:faction:HEARTH`, `revise:deleted:RESTORE`, `revise:deleted:CHOOSE` |
| R3 NONE-CONTINUITY-RELEASE | `revise:authority:YOU`, `revise:authority:SHARED`, `revise:faction:HEARTH`, `revise:deleted:RESTORE`, `revise:deleted:CHOOSE` |

A Faction offer replaces the refusing faction itself, so it is voiced as that faction stepping down as the
coalition's primary faction and staying in it, never as it demanding its own replacement ("Chosen faction is
primary not total winner.", PM:7409).

**Deferral disclosure (round 2).** Before `defer:WITNESS` can be taken, the offer states four things in the
fiction, each with a disclosure id: the Witness leads still open, including Secret Quest 09, which has not played
yet (`leads_open`); that invoking the protocol narrows Kaelen's YOU commitment on the record, so that he keeps
execution, not final permission, and deferring does not keep YOU whole (`you_narrowed`); that the rest of Act 3
plays with Hearth as primary faction and its endorsement of the final act withheld (`act3_as_hearth`); and that a
renegotiation at the gate breaks the deferral instead, after which the Assembly states what that Act 3 now means
(`gate_retcon`). Until all four have been shown, `defer:WITNESS` cannot be taken.

**Save window (round 2).** No save exists between the start of C8-S16 and its commit. The commit is the
transition that ends the scene's open state (T3, T5 or T6); it writes every field of that transition's effects,
including the id of the beat it plays, together with an autosave, as one atomic checkpoint before the beat plays. A
quit or crash before the commit reloads the last save before C8-S16 (PARTLY_LOCKED) and the scene replays from its
start; a reload from the checkpoint resumes at the start of the committed beat, and the offer never replays.

**Retractions.** A renegotiation withdraws Kaelen's superseded position on the record, and one authored cost beat
plays: a speaker other than Kaelen — the delegate or companion whose position is withdrawn — answers it (beat id
`retract_<rule>_<axis>_<new>`, e.g. `retract_R2_authority_YOU`; 16 beats, one per renegotiation offer, written by
Y2-PP-T17; the rule is part of the id because R2 and R3 share five offers with different speakers). The same beat
plays for an R1 offer taken at the gate. The vote then passes negotiated.

| axis | withdrawn on the record | source |
|---|---|---|
| Faction | what C8-S13 adopted: Hearth's mutual-defense charter, the Archive's public evidence charter, or the Continuity League's emergency operations network (a network, not a charter). Kaelen's interim role already ended at the Authority lock and is not withdrawn | PM:7003, PM:7010, PM:7021; roles end PM:7006, PM:7017, PM:7027 |
| Authority | Kaelen's C8-S14 position: YOU, his vow and chosen commitment; SHARED, the seven-signature protocol; NONE, the dismantling commitment | PM:7045-7057, PM:7064-7069, PM:7036-7038 |
| Deleted | the policy adopted at C8-S16: restore, release or choose | PM:7093-7095 |

When a renegotiation reaches YOU, Kaelen states his commitment in that scene, and that becomes the quoted one.

**S5 — Provisional coalition (DEFERRED only).** From the deferral to its end (T7 or T8) the axes stay YOU, HEARTH,
RESTORE and every scene reads them as locked; Hearth takes part but does not endorse the final act. That Hearth
withholds endorsement is new content, an interpretation of PM:7144, not a source line: its beat texts need the
user's approval when Y2-PP-T17 writes them. The deferral's scope, scene by scene:

| content | source | under DEFERRED |
|---|---|---|
| C8-S17 Revolution Name | PM:7155-7163 | beat `deferral_c8s17`: Hearth joins the naming and says what it has not endorsed |
| C8-S18, C8-S19 Siege (B20) | PM:7165-7218 | unchanged; the boss reads YOU, HEARTH, RESTORE as locked |
| Act 3 Branch A — Hearth Compact, H-S01 to H-S04, The Steward (B21H) | PM:7220-7281 | beat `deferral_branch_h` in H-S01: home settlements ask why Hearth has not endorsed; the rest unchanged |
| C8-S20 The Human Patch Door | PM:7414-7432 | beat `deferral_c8s20`: Kaelen signs the expedition (PM:7424-7426) and the Hearth delegates witness it without co-signing |
| Secret Quest 09 Witness Seats | PM:7517-7519 | the player seats the seven witnesses (S9); unchanged otherwise |
| Act 3 ending | PM:7539-7564 | beat `deferral_act3_end`: the Assembly approves the expedition with Hearth's endorsement still withheld |
| Chapter 9: C9-S01 to C9-S17, the three truth routes, C9-S18, C9-S20, the optional rooms and side quests | PM:7661-8187 | unchanged: the expedition is away from the Assembly; C9-S19 is S6 |

The deferral ends in one of two beats: kept — `invoke_witness` (S6 or the gate: Kaelen narrows his commitment on
the record and Hearth endorses the act through the witnesses); broken — the retraction beat and the gate retcon
beat of the renegotiation taken (S7). No other content changes.

**S6 — C9-S19 Seven Witness Protocol (invocation).** Available from its slot in Chapter 9 until the Chapter 9 end:
it plays once, at the first point in that window at which every Witness offer prerequisite is set (its slot, or
later in Chapter 9 if the last prerequisite completes after the slot; PM:8047), and sets
`SEVEN_WITNESSES_AVAILABLE` on every storyline (PM:8055, PM:8200). After the Chapter 9 end it cannot play, so a
prerequisite still unset then is unreachable and the signpost shows CLOSED. If the phase is DEFERRED and WITNESS is
enabled, it offers `invoke:WITNESS`; confirming (T7) is irreversible. Declining keeps the deferral. If the window
passes without C9-S19 playing while every prerequisite is set, nothing is lost: the gate offers the invocation and
sets the unlock flag itself (S7). While FIRSTWAKE and CROWNLESS are disabled, C9-S18 plays only its incomplete form
("If prerequisites incomplete packet remains noise.", PM:8043), C9-S20 does not play, and neither sets its unlock
flag.

**S7 — The ID-lock gate.** Runs on every entry and re-entry into Root of Heaven, by each path: `story` (after the
Chapter 9 end, before PM:8206 "Root of Heaven gate opens"), `world_map` (world map or free travel; protected logic,
needs the user's approval when implemented) and `load` (a save positioned inside Root of Heaven). The stored-ID
check is necessary, not sufficient: the story path reaches the gate only after the Chapter 9 end, and the world-map
path only once Root of Heaven is on the map. Outcome by phase:

| phase | outcome |
|---|---|
| LEANING, PARTLY_LOCKED | TURNED_BACK: the Assembly has not decided |
| DEFERRED | LAST_CHANCE: offers the six R1 renegotiations and, when WITNESS is enabled and its prerequisites are met, invoke:WITNESS; leaving returns the player outside, still DEFERRED |
| VALIDATED | ROOT_OF_HEAVEN; `root_phase` becomes INSIDE (T11) |
| FIXED, FINAL | ROOT_OF_HEAVEN; nothing changes (T12) |

The `load` path never meets LEANING or PARTLY_LOCKED: a save positioned inside Root of Heaven with an UNSET axis is
past Chapter 8 and is refused on load (`storyline-axes.md` Edge Case 16, D16). An invocation at LAST_CHANCE (T7)
needs no earlier C9-S19: it sets `SEVEN_WITNESSES_AVAILABLE` if C9-S19 did not, records the narrowing retraction
with scene LAST_CHANCE and plays `invoke_witness`.

**Gate renegotiation and retcon (user decision 2026-11-10).** LAST_CHANCE keeps all six R1 renegotiations. Taking
one (T8) plays its retraction beat and then its retcon beat `gate_retcon_<axis>_<new>` (six beats:
`gate_retcon_authority_SHARED`, `gate_retcon_authority_NONE`, `gate_retcon_faction_ARCHIVE`,
`gate_retcon_faction_CONTINUITY`, `gate_retcon_deleted_RELEASE`, `gate_retcon_deleted_CHOOSE`; written by
Y2-PP-T17), in which the Assembly states what the Act 3 played under the provisional coalition now means. History
rule: every flag set while DEFERRED — the Act 3 ledger (PM:7565-7591: the `YOU_*` variants, the `HEARTH_*` policies,
`STEWARD_DEFEATED`, `WITNESS_SEATS`), the Chapter 9 ledger (PM:8188-8204) and the C8-S20 signature — stays set and
is read by the composer as what the provisional coalition did, never as the current axis value. From the gate on,
Chapter 10, the boss and the ending read the new stored axes. A composer module keyed on the new Faction that needs
that faction's Act 3 branch (`CURATOR_DEFEATED`, `DIRECTOR_DEFEATED`) is not selected; the retcon beat stands in
for it.

**Legacy saves (user decision 2026-11-10).** There is no runtime catch-up. A save positioned past a lock scene with
that axis UNSET (any save made past Chapter 8 before these fields exist) is unsupported: the load check reports it
(`storyline-axes.md` Edge Case 16, D16) and the load is refused. This holds only while no player-facing build has
such saves; if one ships before these fields do, the decision is reopened. The project's own fixture saves past
Chapter 8 are rewritten once by a dev-fixture migration, a tool script that is not shipped and is not part of this
state machine (owner Y2-PP-T17 with Y1-P1-T05): the test author gives each fixture explicit axis values and an ID
consistent with the branch flags it already holds. The legacy storyline flags the code sets today are superseded,
not migrated (Dependencies).

**S8 — Final authorization (PM:8786-8794).** After the boss: displays the stored structure, offers no
reconsideration, and `confirm_execution` sets `root_phase` FINAL (T13); nothing else changes. Before the confirm,
Kaelen says his three route lines ("If player maintains route", PM:8795, always holds): Authority (PM:8797-8799;
on `SL-SECRET-WITNESS` its Consent line, new content), Deleted (PM:8800-8802) and Faction (PM:8803-8805).
**Stand-down (user decision 2026-11-10).** On `SL-SECRET-WITNESS` with `witness_mandate` FAILED,
`confirm_execution` is not offered: the screen displays the structure and the failed vote, Kaelen says the
stand-down line (line id `stand_down_line`, new content) instead of the route lines, and `stand_down` sets
`root_phase` FINAL (T14) with nothing executed. The restoration does not happen, and the stored ID, the family and
the axes are unchanged. `stand_down` is offered only on a FAILED vote.

**S9 — C10-S15 Secret Route Seven Witnesses (the witness vote).** Plays only on `SL-SECRET-WITNESS`: the source's
guard "If SEVEN_WITNESSES_AVAILABLE." (PM:8693) is set on every storyline by C9-S19, so this design gates the
scene on the stored ID. It is the Crown phase's route interaction (PM:8617-8618), and it plays once: leaving and
re-entering Root of Heaven or restarting the boss never replays it.

*Seats and stances (user decisions 2026-11-10).* The seven witnesses are the ones the player seats in Secret Quest
09, one identity per seat, saved in `witness_seats`: `active_region`, `deleted`, `nonhuman`, `infrastructure`,
`archive`, `local_community`, `rotating` (PM:8697-8703). Kaelen sits in none: a design narrowing of PM:8704
decided by the user on 2026-11-10, so that execution and authorization stay separate (PM:11219). If no nonhuman
person is available (Seven has not consented, PM:8051), the `nonhuman` seat takes a second Assembly pick from the
`rotating` candidates. Each candidate carries a data-defined assent condition over story flags (trust, prior side
quests, and whether the mechanism respects the value that person defended; the model is PM:11229-11236), authored
by Y2-PP-T17. While choosing, and in the journal from then on, the player sees each seated witness's current stance
(would assent or would dissent, and why): choosing who sits is the player's part in the threshold (PM:8707).
Content rule: the candidate data never lets a playthrough seat seven witnesses whose conditions cannot fail ("No
“everyone agrees” fantasy.", PM:8709).

*The vote.* C10-S15 evaluates each seated witness's condition once, writes `witness_dissenters` and
`witness_mandate` (Formulas) once, and names every dissenter (PM:8705-8709). MET: the ending plays "Authorized by
the Living" (PM:8784) and names the dissenters. FAILED (user decision 2026-11-10): the act is not executed (S8
stand-down), and the ending plays `consent_unauthorized`, authored by Y2-PP-T17 within two limits — Kaelen does not
authorize in the witnesses' place, and nothing changes the stored ID, the family or the axes. C10-S13 and C10-S14
follow the same rule for their routes when those ship.

**Consent variants.** On `SL-SECRET-WITNESS` the axes stay YOU, HEARTH, RESTORE, so every scene that reads
Authority as YOU after the invocation plays its Consent variant instead (Core Rule 10 of `storyline-axes.md`):

| scene | source | Consent variant |
|---|---|---|
| C10-S06 Axis One Argument, "If AXIS1_YOU" | PM:8347-8352 | new content |
| C10-S09 Last Offer, Kaelen's answer | PM:8408 → PM:8411 | the source's "Secret Witness" line |
| B22 SOVEREIGN, axis-specific tools | PM:8438 | new content (no "direct Root clashes") |
| C10-S11 The Empty Role | PM:8495 | new content (the role is not written as KAELEN) |
| B23 God King, AXIS1 YOU route mechanics | PM:8533-8543 | the SEC-01 distinction: the God King tries to collapse the witnesses into Kaelen as executor (PM:11219) |
| B23 base phase 4 Final Permission and its YOU dialogue | PM:8615-8616, PM:8638-8645 | the witnesses authorize, Kaelen executes |
| B23 base phase 5 Crown, ending route interaction | PM:8617-8618 | S9 |
| SOVEREIGN's quote of the commitment | PM:7059 | quoted as narrowed |
| Final authorization, Authority route line | PM:8797 | new content (S8) |
| Tier B NPC reactions, "Reaction AXIS1_YOU" (70 NPCs) | PM:12483-14779 | new content, one line per NPC |
| Companion secret-route reactions | PM:11229-11236 | the source's lines |

The invocation records the narrowing as a retraction (`authority`, YOU → YOU, withdrawn item "final permission",
PM:7034-7040, scene C9-S19 or LAST_CHANCE). Scenes that played before the invocation keep their YOU form as history
(S7's history rule).

### Content scope and cut order

Authored content this contract asks of Y2-PP-T17 beyond the source scenes (round-2 scope finding):

| content | count | plays on |
|---|---|---|
| retraction beats `retract_*` | 16 | every renegotiation (C8-S16; R1 also at the gate) |
| gate retcon beats `gate_retcon_*` | 6 | an R1 deferral broken at the gate |
| deferral beats `deferral_*` | 4 | an R1 deferral |
| `invoke_witness` | 1 | Witness Protocol |
| red lines and the R1 witness clause | 4 | C8-S15 |
| deferral disclosures | 4 | the C8-S16 deferral offer |
| Consent variants that are new content | 6 scenes + 70 Tier B lines | `SL-SECRET-WITNESS` |
| witness candidates: assent conditions and stance texts | 7 seats | Secret Quest 09, the journal, C10-S15 |
| `sole_dissent`, `consent_unauthorized`, `stand_down_line` | 3 | rare endings |
| arc epilogue lines | 3 | arcs 05, 08, 09 |

Cut order, first cut first. A cut never removes an invariant, a transition, a record field or an id: it replaces
authored text with shared text behind the same ids, so the content-completeness criterion (L-AC23) still holds.
1. Tier B "Reaction AXIS1_YOU" Consent lines → one templated line per NPC tier.
2. Gate retcon beats → one shared text per axis behind the six ids.
3. `deferral_c8s17` and `deferral_branch_h` → one shared line behind both ids.

If the budget is still exceeded after step 3, the next cut is the deferral itself (moved post-1.0), which needs a
GDD revision. **Producer sign-off: pending.** It is required before Y2-PP-T17 is scheduled and is not given by this
revision.

### States and Transitions

The phases are `storyline-axes.md`'s phase table. Transitions:

| # | from | event | guard | to | effects |
|---|---|---|---|---|---|
| T1 | LEANING | C8-S13 resolves | — | PARTLY_LOCKED | faction set; `lock_negotiated` per `lock_pass` |
| T2 | PARTLY_LOCKED | C8-S14 resolves | faction set, authority UNSET | PARTLY_LOCKED | authority set; `lock_negotiated` per `lock_pass` |
| T3 | PARTLY_LOCKED | C8-S16 resolves | faction and authority set; the row is valid | VALIDATED | deleted set; `lock_negotiated` per `lock_pass`; ID stored |
| T4 | PARTLY_LOCKED | C8-S16 resolves | faction and authority set; the row is invalid | CRISIS | deleted set; `lock_negotiated` per `lock_pass`; the refusing faction breaks the coalition |
| T5 | CRISIS | a renegotiation is taken | the offer is in the row's offer set | VALIDATED | the axis changed; `axis_revised`, `lock_negotiated` gain it; retraction recorded; retraction beat played; ID stored |
| T6 | CRISIS | the deferral is taken | R1; WITNESS enabled; signpost OPEN; the four disclosures shown | DEFERRED | `witness_deferred` set |
| T7 | DEFERRED | the invocation is confirmed (C9-S19 or the gate) | WITNESS enabled; prerequisites met | VALIDATED | `secret_invoked` gains WITNESS; `SL-SECRET-WITNESS` stored; `SEVEN_WITNESSES_AVAILABLE` set if unset; narrowing retraction recorded; `invoke_witness` played |
| T8 | DEFERRED | a renegotiation is taken at the gate | one of the six R1 offers | VALIDATED | as T5; gate retcon beat played |
| T9 | DEFERRED | Root of Heaven entry, any path | — | DEFERRED | LAST_CHANCE scene; leaving returns the player outside |
| T10 | LEANING or PARTLY_LOCKED | Root of Heaven entry, any path | — | unchanged | TURNED_BACK |
| T11 | VALIDATED | Root of Heaven entry, any path | — | FIXED | `root_phase` INSIDE |
| T12 | FIXED or FINAL | Root of Heaven entry, any path | — | unchanged | open |
| T13 | FIXED | execution confirmed | the final authorization scene is playing; `witness_mandate` is not FAILED | FINAL | `root_phase` FINAL |
| T14 | FIXED | Kaelen stands down | the final authorization scene is playing; `witness_mandate` FAILED | FINAL | `root_phase` FINAL; nothing executed |

No other transition exists: nothing leads from VALIDATED, FIXED or FINAL to an earlier phase or to DEFERRED or
CRISIS — not a knob change, not a flag, not loading. The story graph never starts C8-S14 before C8-S13 resolves or
C8-S16 before C8-S14 resolves; a graph that could break that order is a data error FlagRegistry reports at boot
(Y1-P1-T03). Loading restores the record, runs the damaged-record check (a DAMAGED record does not load), and
derives the phase; it fires no transition by itself, and a save positioned inside Root of Heaven then runs the gate
check (T9-T12) as its entry. `witness_seats` is written by Secret Quest 09, and `witness_dissenters` and
`witness_mandate` once each by C10-S15; none of them changes a phase.

**NG+ reset** (until NG+ design decides carry-over): `authority`, `faction`, `deleted` → UNSET; `storyline_id` →
empty; `witness_deferred` → false; `root_phase` → OUTSIDE; `secret_invoked`, `axis_revised`, `lock_negotiated`,
`retraction_log`, `beats_played`, `witness_seats`, `witness_dissenters` → empty; `witness_mandate` → UNDECIDED. The
`AXIS*`, `axis_revised_*` and `lock_negotiated_*` flags and the secret routes' prerequisite and unlock flags are
cleared with the record; the Act 1 seed flags follow NG+'s own flag reset. NG+ starts a new record, not a
transition of this table: the previous cycle's record is kept for Story+ under its own ID (PM:11300, PM:11303).

## Formulas

```
crisis_offers(row) = {} if row is not R1, R2 or R3; otherwise
                     { "revise:" + axis + ":" + v : axis locked, v ≠ row[axis], not invalid(row with axis = v) }
                     ∪ { "defer:WITNESS" : row = R1, enabled(WITNESS), signpost(WITNESS) = OPEN }
last_chance_offers  = crisis_offers(R1) without "defer:WITNESS"
                     ∪ { "invoke:WITNESS" : enabled(WITNESS), prereqs_met(WITNESS) }
signpost(T)         = HIDDEN  if none of T's offer prerequisites is set, or T is reserved (post-1.0) and disabled
                      CLOSED  if T is disabled, an ID is stored and it is not "SL-SECRET-" + T,
                              or an unset offer prerequisite of T is unreachable
                      OPEN    otherwise
witness_threshold   = 5
witness_dissenters  = { seat in witness_seats : the seated witness's assent condition is false at C10-S15 }
witness_mandate     = MET     if 7 − |witness_dissenters| ≥ witness_threshold
                      FAILED  otherwise
```

`invalid`, `enabled`, `prereqs_met` and the row notation are `storyline-axes.md`'s. `unreachable(flag)`: StoryGraph
(Y1-P1-T03) reports that no content still ahead of the player sets the flag. The tests run top to bottom, so a
reserved route is hidden even with its arc flags set, and a shipped route that a patch disables or whose lead is
missed shows CLOSED, never HIDDEN (invariant I6). Because the deferral needs the signpost OPEN, it is never offered
when a Witness lead can no longer be completed. The gate's `invoke:WITNESS` does not need
`SEVEN_WITNESSES_AVAILABLE` (round 2): the invocation sets it.

`witness_threshold` is fixed at 5 (user decision 2026-11-10): it is data-defined in the route data, not a knob and
not a player choice, and changing it is a GDD revision. It is a majority floor ("threshold not unanimity",
PM:8706) that survives two dissents. The assent conditions are evaluated once, at C10-S15, and the result is saved,
never recomputed; `|witness_dissenters|` is 0-7, so MET needs at most two dissenters.

Counts: |crisis_offers| is 6 for R1 (7 with the deferral), 5 for R2 and R3, so 16 renegotiation offers in all;
|last_chance_offers| is 6 or 7. |crisis_offers| is 0 for every valid row.

## Edge Cases

1. **Crash or quit during C8-S16.** Before the commit no save exists, so the player reloads the last save before
   C8-S16 (PARTLY_LOCKED) and the scene replays from its start; after the commit, the checkpoint resumes at the
   start of the committed beat and the offer never replays (S4 save window).
2. **Deferred, but Secret Quest 09 is never completed.** C9-S19 does not play, `SEVEN_WITNESSES_AVAILABLE` stays
   unset, the signpost shows CLOSED once the quest is unreachable, and the gate's LAST_CHANCE offers the six
   renegotiations only.
3. **Deferred, the player declines at C9-S19.** Still DEFERRED; LAST_CHANCE offers the invocation again.
4. **Deferred, and a patch disables WITNESS** (outside its safe range; a 1.0 build that does it fails boot
   validation). The signpost shows CLOSED; LAST_CHANCE offers the six renegotiations only (I5, I6).
5. **The player leaves LAST_CHANCE repeatedly.** Each exit returns them outside the gate, still DEFERRED; Chapter 9
   content already played stays played. There is no limit and no penalty.
6. **Leaving Root of Heaven mid-boss and re-entering.** FIXED → T12: open, nothing changes; the boss restarts per
   the combat system. A C10-S15 vote already taken keeps its `witness_dissenters` and `witness_mandate`, and the
   vote never replays.
7. **Story+ re-entry after execution or a stand-down.** FINAL → T12: open.
8. **A save in DEFERRED is loaded after C9-S19 already played with the invocation declined.**
   `SEVEN_WITNESSES_AVAILABLE` is in the save; LAST_CHANCE offers the invocation.
9. **A deferral, then a renegotiation at the gate.** `witness_deferred` stays true on a valid row that is not R1;
   with `axis_revised` non-empty that is the T8 history, not a damaged record (`storyline-axes.md` Edge Case 16).
10. **Deferred with every prerequisite set, but C9-S19 never played.** LAST_CHANCE offers `invoke:WITNESS`; taking
    it sets `SEVEN_WITNESSES_AVAILABLE` (T7).
11. **All seven witnesses dissent.** `witness_mandate` FAILED; Kaelen stands down (T14), nothing is executed, the
    ID stays `SL-SECRET-WITNESS`, the family CONSENT, and `consent_unauthorized` plays (S8, S9).
12. **A save made past Chapter 8 before these fields existed.** The load is refused (`storyline-axes.md` Edge Case
    16, D16) and the player returns to the load menu; no lock scene replays.

## Dependencies

| System | Direction | What flows | Status |
|---|---|---|---|
| Storyline axes (`design/gdd/storyline-axes.md`) | this ← axes | values, formulas, record, invariants I1-I8, knobs | revision 6 |
| SaveService (Y1-P1-T05) | this → save | record writes, including `retraction_log`, `beats_played`, `witness_seats`, `witness_dissenters`, `witness_mandate`; autosave suppression in C8-S16 and the commit checkpoint; the damaged-record check and load refusal | no GDD |
| FlagRegistry / StoryGraph (Y1-P1-T03) | this ← registry | flags; scene order check at boot; `unreachable(flag)`; the story position for Edge Case 16 D16 | no GDD |
| World map / free travel (protected) | this → world map | the gate check on the `world_map` path | no GDD — needs the user's approval when implemented |
| Ending composer (Y2-PP-T17) | this → composer | `witness_deferred`, retractions, beats played, `witness_dissenters`, `witness_mandate`, the Consent variants, the history rule, `consent_unauthorized` | not designed |
| Combat / boss (Root of Heaven) | this → boss | the Consent variants of B22 and B23; C10-S15 in the Crown phase; re-entry rule | no GDD — combat is protected |
| Journal / quest UI | this → journal | signpost states and leads, the deferral disclosures, the seated witnesses' stances | no GDD — UI evidence in L-AC24 |
| Legacy storyline flags (protected: story progression, true ending, NG+) | superseded by this contract | `ch8_revolt_led`, `ch8_council_formed`, `ch8_witness_network_created`, `ending_route_ch8_lead`, `ending_route_ch8_council`, `ending_route_ch8_witness` (set in `AethelgardPrototype/scripts/chapter8/ch8_revolt_crisis.gd:114-128`); `ch10_destroy_sovereign`, `ch10_rewrite_sovereign` (`AethelgardPrototype/scripts/chapter10/ch10_sovereign_confrontation.gd:224-228`); `true_ending_seen`, `ng_plus_unlocked` (`AethelgardPrototype/scripts/chapter10/ch10_ending.gd:15-16`); all declared in `AethelgardPrototype/scripts/game_manager.gd:371-401` | not migrated; retirement owned by Y1-P1-T03 and needs the user's explicit approval |

Bidirectional rule: `storyline-axes.md` names this document in its Dependencies; each doc above written later must
too. The protected areas this contract touches are listed in `storyline-axes.md` Dependencies.

## Tuning Knobs

None of its own. It reads `secret_route_enabled`, `secret_prerequisites` and `secret_unlock_flag` from
`storyline-axes.md`, only at C8-S16, C9-S19 and the gate. Not knobs: the scene order, the offer sets (derived from
`invalid`), the rule that C8-S16 cannot be left with a crisis open, and the rule that a stored ID never changes.
`witness_threshold` is not a knob either: it is fixed at 5 (Formulas).

## Acceptance Criteria

**Document-level — checked by `production/qa/evidence/2026-11-storyline/check_storyline_axes.py`:** the transition
table has rows T1-T14 exactly as pinned (from, guard, to, effects); every from/to value is a phase of
`storyline-axes.md`; the crisis offer table equals `crisis_offers` computed from `invalid()` for R1-R3; the red-line
table names exactly R1-R3 with their pairs; the S5 and Consent variants tables, the deferral disclosures, the
witness seats and the threshold are as pinned; every L-AC below names its blocking stories and uses only
observables from the table below.

**Scene-level observables** — every one returns the stated value outside its scene:

| observable | returns | outside its scene |
|---|---|---|
| `storyline_phase()` | the derived phase of the current record | — |
| `storyline_id()` | the stored ID | empty string when nothing is stored |
| `axis(name)` | the record's `authority`, `faction` or `deleted` | — |
| `gate_open()` | true exactly when an ID is stored (the gate check passes; the path to the gate is story progression) | — |
| `enter_root_of_heaven(path)` | for path `story`, `world_map` or `load`: ROOT_OF_HEAVEN, LAST_CHANCE or TURNED_BACK | — |
| `current_scene()` | the id of the playing scene, or `load_menu` | — |
| `lock_options(axis)` | in that axis's lock scene, the values offered | empty |
| `lock_arguments(axis)` | in that axis's lock scene, the (flag, value, sign) arguments voiced | empty |
| `red_lines_voiced(scene)` | the rule ids voiced the last time that scene played | empty if it never played |
| `red_line_clause()` | whether the last R1 line voiced at C8-S15 carried the witness clause | false if it never played |
| `offers()` | in the C8-S16 crisis, at C9-S19 while it offers the invocation, or in LAST_CHANCE: the current offer set | empty in every other scene |
| `offer_disclosures(offer)` | in the C8-S16 crisis, the disclosure ids the offer has shown | empty |
| `take(offer)` | true if the offer is in `offers()` and was taken; otherwise false and nothing changes | false |
| `decline()` | in C9-S19 or LAST_CHANCE with `invoke:WITNESS` offered: true, invocation declined | false |
| `record_hash()` | a hash over every stored field of the record | — |
| `try_save()` | requests a save now: true if a save file was written, false if saving is suppressed | — |
| `retraction_log()` | the saved `retraction_log`: every retraction as {axis, old, new, withdrawn_item, scene}, oldest first | — |
| `beats_played()` | the saved `beats_played`: the authored beat ids played (`retract_*`, `gate_retcon_*`, `deferral_*`, `invoke_witness`) | — |
| `beat_text(id)` | the route data's text for a beat, line, disclosure or module id | empty for an unknown id |
| `beat_speaker(id)` | the route data's speaker for that id | empty for an unknown id |
| `signpost(route)` | HIDDEN, OPEN or CLOSED (Formulas) | — |
| `quoted_commitment()` | the commitment SOVEREIGN quotes and its status: STATED, WITHDRAWN or NARROWED | NONE if Authority was never YOU |
| `consent_variant(scene)` | true when the scene plays its Consent variant | false for a scene not yet played |
| `stances()` | in Secret Quest 09 and in the journal after it: seat → (identity, would assent or would dissent) for the seated witnesses | empty before Secret Quest 09 |
| `witnesses()` | at C10-S15, the seven witness identities | empty |
| `dissent_named()` | the identities C10-S15 named as dissenting the last time it played | empty if it never played |
| `route_lines()` | in the final authorization, the source line ids Kaelen says | empty |
| `ending_modules()` | the ending module ids the composer selected for the current record | — |
| `confirm_execution()` | in the final authorization with `witness_mandate` not FAILED: confirms, returns true | false |
| `stand_down()` | in the final authorization with `witness_mandate` FAILED: Kaelen stands down, returns true | false |
| `load_errors()` | the data errors found by the last load | empty |
| `epilogue_lines()` | the arc ids that get an epilogue line | — |
| `record_field(name)` | the current value of a stored record field (`lock_negotiated`, `axis_revised`, `witness_deferred`, `secret_invoked`, `root_phase`, `witness_seats`, `witness_dissenters`, `witness_mandate`) | — |
| `flag_set(name)` | whether the named story flag is set | — |

The eight offer strings are the six R1 renegotiations, `defer:WITNESS` and `invoke:WITNESS`. "Nothing is offered"
is tested as: `take()` of each of the eight is false and `record_hash()` is unchanged.

**Runtime criteria:**

- **L-AC1 Lock order and options.** For each axis `lock_options(axis)` is all three values with no seed set and with
  one seed per exclusive group set; from a record with Faction UNSET, C8-S14 never becomes `current_scene()`; with
  Authority UNSET, C8-S16 never does. *Blocked by:* Y2-PP-T17, Y1-P1-T03.
- **L-AC2 Arguments and lock pass.** `lock_arguments(axis)` is exactly the set axis seeds of that axis with value and
  sign. Faction backing HEARTH, four fixtures: no seed → `record_field(lock_negotiated)` contains faction;
  `act1_report_local` → not; `act1_report_local` + `ch1_knight_killed` → contains; only `ch1_knight_killed` →
  contains. Authority and Deleted, two fixtures each: no seed → contains; one `+` seed for the backed value → not.
  Each result survives a save and reload. *Blocked by:* Y2-PP-T17, Y1-P1-T03, Y1-P1-T05.
- **L-AC3 Red lines.** `red_lines_voiced(C8-S13)` and `(C8-S14)` are empty; `(C8-S15)` is {R1} after YOU + HEARTH,
  {R2} after NONE + ARCHIVE, {R3} after NONE + CONTINUITY and empty for each of the other six pairs;
  `(C8-S16)` is the row's rule on each invalid row and empty on a valid row. After YOU + HEARTH,
  `red_line_clause()` is true when `signpost(WITNESS)` is OPEN and false when it is HIDDEN or CLOSED; after NONE +
  ARCHIVE and NONE + CONTINUITY it is false. *Blocked by:* Y2-PP-T17.
- **L-AC4 Valid at C8-S16.** For each of the 24 valid rows: after C8-S16, `storyline_phase()` VALIDATED,
  `storyline_id()` the row's ID, `gate_open()` true, `beats_played()` with no `retract_*` beat. *Blocked by:*
  Y2-PP-T17.
- **L-AC5 Crisis offers and the save window.** On each invalid row, inside C8-S16, `offers()` equals the crisis
  offer table's set (R1 with `defer:WITNESS` only when WITNESS is enabled and `signpost(WITNESS)` is OPEN). Before
  the commit `current_scene()` stays C8-S16 and `try_save()` is false. After the commit (T3, T5 or T6) a checkpoint
  exists: reloading it gives the committed `record_hash()`, replays the committed beat from its start, and `take()`
  of every offer of that row is false. *Blocked by:* Y2-PP-T17, Y1-P1-T05.
- **L-AC6 Renegotiation.** From each invalid-row fixture with `record_field(lock_negotiated)` and
  `record_field(axis_revised)` empty, for each of its offers (16 runs): `take()` true; `storyline_phase()`
  VALIDATED; `storyline_id()` the new row's ID; `axis(name)` the new value; `record_field(axis_revised)` and
  `record_field(lock_negotiated)` contain the axis; the last `retraction_log()` entry has the axis, old and new
  values, the table's withdrawn item and scene C8-S16; `beats_played()` gains `retract_<rule>_<axis>_<new>`, and the
  16 runs yield 16 distinct beat ids. `take()` of a value not offered (the same value; the other invalid row) is
  false and `record_hash()` is unchanged. *Blocked by:* Y2-PP-T17.
- **L-AC7 Deferral.** On R1 with WITNESS enabled and the signpost OPEN, before the offer has shown its disclosures
  `take(defer:WITNESS)` is false and `record_hash()` is unchanged; once `offer_disclosures(defer:WITNESS)` is
  {`leads_open`, `you_narrowed`, `act3_as_hearth`, `gate_retcon`}, `take(defer:WITNESS)` gives DEFERRED,
  `storyline_id()` empty, `gate_open()` false and `record_field(witness_deferred)` true. With the signpost HIDDEN
  or CLOSED, or WITNESS disabled, and on R2 and R3, `take(defer:WITNESS)` is false and `record_hash()` is
  unchanged. A DEFERRED run to the gate gains `deferral_c8s17`, `deferral_branch_h`, `deferral_c8s20` and
  `deferral_act3_end` in `beats_played()`; a record VALIDATED by T3 or T5 gains none of them. *Blocked by:*
  Y2-PP-T17.
- **L-AC8 Invocation at C9-S19.** From DEFERRED with the three Witness offer prerequisites set: C9-S19 makes
  `flag_set(SEVEN_WITNESSES_AVAILABLE)` true and `offers()` contains `invoke:WITNESS`; `take(invoke:WITNESS)` gives
  VALIDATED, `storyline_id()` `SL-SECRET-WITNESS`, `record_field(secret_invoked)` {WITNESS}, a `retraction_log()`
  entry (authority, YOU, YOU, "final permission", C9-S19) and `invoke_witness` in `beats_played()`. After `decline()`
  the phase stays DEFERRED and LAST_CHANCE's `offers()` contains `invoke:WITNESS`. On a VALIDATED record C9-S19
  still makes `flag_set(SEVEN_WITNESSES_AVAILABLE)` true, and `take(invoke:WITNESS)` there is false with
  `record_hash()` unchanged. With FIRSTWAKE and CROWNLESS disabled and all their prerequisites set,
  `flag_set(FIRST_WAKE_AVAILABLE)` and `flag_set(CROWNLESS_AVAILABLE)` stay false after Chapter 9. *Blocked by:*
  Y2-PP-T17, Y1-P1-T03.
- **L-AC9 The gate.** For the `story` and `load` paths and each storable phase: LEANING and PARTLY_LOCKED on the
  `story` path → TURNED_BACK; on the `load` path the load is refused with `load_errors()` naming D16 and no gate
  entry; DEFERRED → LAST_CHANCE with `offers()` exactly the six R1 renegotiations plus `invoke:WITNESS` when WITNESS
  is enabled and its prerequisites are met (with and without `flag_set(SEVEN_WITNESSES_AVAILABLE)`), and leaving
  returns the player outside with the phase DEFERRED; VALIDATED → ROOT_OF_HEAVEN and FIXED; FIXED and FINAL →
  ROOT_OF_HEAVEN, phase unchanged. Cells impossible in play (the `story` cells of LEANING and PARTLY_LOCKED) run
  from synthetic fixture saves and are reported as synthetic. The `world_map` path repeats the `story` cells once
  the protected world-map change is approved. *Blocked by:* Y2-PP-T17, Y1-P1-T03, Y1-P1-T05.
- **L-AC10 Held to its word.** From VALIDATED records reached by T3, T5, T7 and T8 and from FIXED and FINAL
  records: at C9-S19 and at the gate on the `story` and `load` paths, `take()` of each of the eight offer strings is
  false with `record_hash()` unchanged, and `enter_root_of_heaven()` is ROOT_OF_HEAVEN; after setting every
  prerequisite and unlock flag, disabling WITNESS and emptying `secret_prerequisites[WITNESS]`, `storyline_id()` and
  `storyline_phase()` are unchanged. *Blocked by:* Y2-PP-T17.
- **L-AC11 Patch while deferred.** From DEFERRED, disabling WITNESS makes `signpost(WITNESS)` CLOSED and
  LAST_CHANCE's `offers()` exactly the six renegotiations. *Blocked by:* Y2-PP-T17, Y1-P1-T03.
- **L-AC12 Signposts.** `signpost(WITNESS)` is HIDDEN with no offer prerequisite set, OPEN once one is set, CLOSED
  once an ID other than `SL-SECRET-WITNESS` is stored, and CLOSED when an unset prerequisite becomes unreachable
  (Secret Quest 09 skipped past its last chance); `signpost` of CROWNLESS and FIRSTWAKE is HIDDEN while disabled,
  even with all their flags set. *Blocked by:* Y2-PP-T17, Y1-P1-T03.
- **L-AC13 Final authorization.** In FIXED after the boss with `witness_mandate` not FAILED: `take()` of each of the
  eight offer strings is false with `record_hash()` unchanged; `route_lines()` is the stored row's Authority,
  Deleted and Faction lines (PM:8797-8805; the Consent Authority line on `SL-SECRET-WITNESS`); `stand_down()` is
  false; `confirm_execution()` gives FINAL with `storyline_id()` unchanged. `confirm_execution()` anywhere else is
  false with `record_hash()` unchanged. *Blocked by:* Y2-PP-T17.
- **L-AC14 Consent and the witness vote.** On `SL-SECRET-WITNESS`, `consent_variant()` is true for every scene of the
  Consent variants table, and `quoted_commitment()` is NARROWED. `stances()` after Secret Quest 09 has the seven
  seats of `record_field(witness_seats)`, and `witnesses()` holds those seven identities, none of them Kaelen, the
  `deleted` seat a deleted citizen (PM:8698). For eight fixtures whose seated witnesses' conditions give 0 to 7
  dissenters: `record_field(witness_dissenters)` is exactly the seats whose condition is false,
  `dissent_named()` is exactly their identities, and `record_field(witness_mandate)` is MET for 0, 1 and 2
  dissenters and FAILED for 3 to 7 (7 − dissenters ≥ 5); `ending_modules()` contains `consent_unauthorized` exactly
  when it is FAILED; `storyline_id()` is unchanged. After a save and reload, and after leaving and re-entering
  mid-boss, both fields are unchanged and C10-S15 does not become `current_scene()` again. On every SOLE storyline,
  with `flag_set(SEVEN_WITNESSES_AVAILABLE)` true, `consent_variant()` is false for the same scenes and C10-S15
  never becomes `current_scene()`. *Blocked by:* Y2-PP-T17, Y1-P1-T05.
- **L-AC15 Quoted commitment.** YOU locked at C8-S14 and never revised → STATED, the C8-S14 commitment; YOU reached
  by a renegotiation (from R2 or R3) → STATED, that scene's commitment; YOU withdrawn by a renegotiation from R1 at
  C8-S16 or at the gate → WITHDRAWN; Authority never YOU → NONE. *Blocked by:* Y2-PP-T17.
- **L-AC16 Saves.** A save in each storable phase (LEANING, PARTLY_LOCKED, DEFERRED, VALIDATED, FIXED, FINAL)
  reloads with the same `storyline_phase()`, `storyline_id()`, `retraction_log()`, `beats_played()` and
  `record_hash()`, with `load_errors()` empty, even after a knob is flipped; a save with no axis data positioned
  before C8-S13 loads LEANING with `load_errors()` empty; a DEFERRED-then-T8 record loads with `load_errors()` empty;
  each damaged record of `storyline-axes.md` Edge Case 16 (D1-D16) gives a `load_errors()` naming its item, and the
  load is refused (`current_scene()` stays `load_menu`). *Blocked by:* Y2-PP-T17, Y1-P1-T05.
- **L-AC17 Epilogue lines.** With the completion flags of arcs 05, 08 and 09 set — `CROWN_COORDINATES` (arc 08,
  PM:3683), `OLD_HOME_MESSAGE` (arc 09, PM:3814) and arc 05's Quest 30 flag, which the sources do not name
  (PM:2690-2691) and Y2-PP-T17 names before this runs — `epilogue_lines()` contains all three arcs on every 1.0
  storyline, and contains none of them with no flag set. *Blocked by:* Y2-PP-T17.
- **L-AC18 NG+ reset.** Starting NG+ from a FINAL record gives LEANING, every axis UNSET, `storyline_id()` empty,
  the reset fields at their defaults, and `flag_set()` false for `SEVEN_WITNESSES_AVAILABLE` and every Witness
  offer prerequisite. *Blocked by:* Y2-PP-T17.
- **L-AC19 Gate renegotiation and history.** From a DEFERRED record that played the Hearth branch and C8-S20, for
  each of the six R1 offers at LAST_CHANCE: `take()` gives VALIDATED with the new row's ID; `beats_played()`
  contains both `retract_R1_<axis>_<new>` and `gate_retcon_<axis>_<new>`; `retraction_log()` gains an entry with
  scene LAST_CHANCE; `flag_set(STEWARD_DEFEATED)` and the `HEARTH_*` policy flags stay as they were; `axis()` reads
  the new value; after a Faction offer `ending_modules()` holds no module that needs the new faction's branch boss
  flag. *Blocked by:* Y2-PP-T17.
- **L-AC20 Unsupported legacy saves.** A save with no axis data positioned in Chapter 9, and one positioned inside
  Root of Heaven: on load `load_errors()` names D16, `current_scene()` stays `load_menu`, and no lock scene plays.
  *Blocked by:* Y2-PP-T17, Y1-P1-T03, Y1-P1-T05.
- **L-AC21 Invocation at the gate.** From DEFERRED with the three Witness offer prerequisites set, at LAST_CHANCE on
  the `story` path, once after `decline()` at C9-S19 and once with C9-S19 never played: `offers()` contains
  `invoke:WITNESS`; `take(invoke:WITNESS)` gives VALIDATED, `storyline_id()` `SL-SECRET-WITNESS`,
  `flag_set(SEVEN_WITNESSES_AVAILABLE)` true, a `retraction_log()` entry (authority, YOU, YOU, "final permission",
  LAST_CHANCE) and `invoke_witness` in `beats_played()`. With one prerequisite unset, `take(invoke:WITNESS)` is false
  with `record_hash()` unchanged. *Blocked by:* Y2-PP-T17, Y1-P1-T03.
- **L-AC22 Stand-down.** On `SL-SECRET-WITNESS` in FIXED after the boss with `witness_mandate` FAILED:
  `confirm_execution()` is false with `record_hash()` unchanged; `route_lines()` is empty; `stand_down()` gives
  FINAL with `storyline_id()` and each `axis()` unchanged; `ending_modules()` contains `consent_unauthorized`. With
  `witness_mandate` MET, `stand_down()` is false and `confirm_execution()` gives FINAL. *Blocked by:* Y2-PP-T17.
- **L-AC23 Content completeness.** For every id this contract defines — the 16 `retract_*`, the 6 `gate_retcon_*`,
  the 4 `deferral_*`, `invoke_witness`, `red_line_R1`, `red_line_R2`, `red_line_R3`, `red_line_R1_clause`, the four
  disclosures, `sole_dissent`, `consent_unauthorized`, `stand_down_line` — `beat_text(id)` is non-empty and
  `beat_speaker(id)` is non-empty; for every `retract_*` id `beat_speaker(id)` is not Kaelen. *Blocked by:*
  Y2-PP-T17.
- **L-AC24 Visual and UI evidence.** These beats and screens are player-observable (Visual/Feel and UI, BLOCKING in
  the project's Testing Standards): one retained screenshot each in `production/qa/evidence/`, with lead sign-off
  recorded beside them (narrative-director for beats and lines, ux-designer for screens). The items are the C8-S15
  red line on R1 with and without the clause, and on R2 and R3; the C8-S16 crisis screen for each invalid row; the
  deferral offer with its four disclosures; one retraction beat per axis; one gate retcon beat; each deferral beat;
  the invocation at C9-S19 and at LAST_CHANCE; the LAST_CHANCE screen; the journal signpost HIDDEN, OPEN and CLOSED;
  the Secret Quest 09 seating screen with stances and the journal stance view; C10-S15 naming a dissent; the final
  authorization's confirm and stand-down; `sole_dissent`; `consent_unauthorized`; and the three arc epilogue lines.
  *Blocked by:* Y2-PP-T17.

**Validation note:** the route bot of ROADMAP §12.4 starts from Chapter 8 fixture saves once the locks exist (owner
Y2-PP-T17): one run per valid row through C8-S16 (24), one Witness run through the deferral and C9-S19 (1), one per
renegotiation offer at C8-S16 (16), one deferral-then-LAST_CHANCE invocation (1), one deferral-then-LAST_CHANCE run
per R1 renegotiation (6), and the gate matrix of 2 counted paths × 6 storable phases (12) — 60 runs. The
`world_map` path's 6 cells run the same way once the protected world-map change is approved; until then they are
blocked and not counted. Pass rule: every run other than a gate-matrix cell ends with one `story`-path gate entry
from its own record (the bot may skip from its last scripted scene to the Chapter 9 end with the record unchanged)
and passes when the observed `storyline_phase()` after that entry, `storyline_id()` and `enter_root_of_heaven()`
outcome equal the expected triple. A gate-matrix cell passes on the same triple from its fixture, except the `load`
cells of LEANING and PARTLY_LOCKED, which pass when the load is refused with `load_errors()` naming D16 and no gate
entry happens. Cells impossible in play run from synthetic fixtures, count, and are listed as synthetic in the run
report. The bot is a smoke check of the phase, the ID and the gate; the retractions, beats and the vote are
evidenced by L-AC6, L-AC7, L-AC14, L-AC19 and L-AC21 to L-AC24.

## Open Questions

1. **Beat texts:** the 16 `retract_*`, the six `gate_retcon_*`, the four `deferral_*` beats and `invoke_witness` are
   written by Y2-PP-T17; which companion answers each retraction (Nema on a NONE withdrawal, PM:7078-7087, is the
   obvious first) is decided there. The `deferral_*` texts need the user's approval (S5: new content).
2. **More Chapter 9 reactions under a deferral:** this contract changes none of Chapter 9 (S5); whether later passes
   add any is for Y2-PP-T17.
3. **Boss restart on re-entry** belongs to the combat system; this contract only says the stored ID,
   `witness_dissenters` and `witness_mandate` are unchanged.
4. **Witness candidate data:** the candidates per seat, their assent conditions and stance texts, and how the
   content rule of S9 is checked against that data, are Y2-PP-T17's.
5. **Gate retcon after a Faction change:** which composer modules stand in for the new faction's unplayed Act 3
   branch beyond the retcon beat is for Y2-PP-T17 (S7 history rule).
6. **Story+ after a stand-down:** what the Story+ state of `SL-SECRET-WITNESS` shows when nothing was executed is
   for Y2-PP-T17 (it changes neither the ID nor the family).
7. **Round-2 recommendations not applied in revision 2** (blocking items only): offers voiced as the faction
   conceding or brokered (PM:7102-7106, 7141); the Faction retraction versus "steps down and stays in" (PM:7003,
   7409); the S3 clause in Hearth's own voice (PM:8411); LAST_CHANCE as a remote Assembly link with a re-entry cost
   (PM:8393); the Chapter 9 axis-reading scenes (PM:7958, 8021-8025, 8133) and PM:8475, PM:8457-8459 in the Consent
   variants; `deferral_c8s20` hooked to PM:7280; B22 to combat; companion reactions as 4 templated + 4 specific;
   signpost HIDDEN versus CLOSED with an ID stored; I5's wording while DEFERRED; context for `retract_R1_*`; where
   NG+ keeps the previous record.
