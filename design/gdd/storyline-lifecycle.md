# Storyline Lifecycle

> **Status**: Draft (revision 1, after design review round 1 of this document, 2026-11-10)
> **Author**: Claude with the project lead
> **Last Updated**: 2026-11-10
> **Implements**: the invariants I1-I8 of `design/gdd/storyline-axes.md`; contract for Y2-PP-T17 (ending composer /
> route data model)
> **Implements Pillar**: P3, P5, P8 (through `storyline-axes.md`)

## Summary

The scenes and transitions that turn the three story axes into one stored storyline ID: the three lock scenes, the
red-line beat, the C8-S16 crisis (renegotiate, or defer to the witnesses on R1), the provisional coalition, the
Witness Protocol invocation and witness vote, the ID-lock gate on every path, the legacy-save catch-up and the final
authorization. `storyline-axes.md` owns the values, the formulas and the record; this document owns when each field
is written and which beats play.

> **Quick reference** — Layer: `Foundation` · Priority: `Alpha` · Depends on: `storyline-axes.md`

## Overview

Chapter 8 locks Faction (C8-S13), Authority (C8-S14) and Deleted (C8-S16), in that order. A valid row is stored at
once. An invalid row breaks the coalition inside C8-S16, and the scene does not end until it holds again: the player
takes one of the refusing faction's demands (a renegotiation of one axis) or, on R1 with the Witness Protocol
signpost open, defers to the witnesses. A deferral is a provisional coalition: Hearth stays in the Assembly but does
not endorse the final act (the irreversible Root act Kaelen executes after the boss) until the player invokes the
protocol at C9-S19 or at the gate; renegotiating at the gate breaks the deferral instead, with a beat that says what
the Act 3 already played under Hearth now means. On Witness Protocol the seven witnesses vote at C10-S15, and the
vote can fail. Every entry and re-entry into Root of Heaven runs one gate check; a save from before these fields
existed replays the lock scenes it is missing; the final authorization only confirms. There is no state in which a
player can be stranded, and no transition back from a stored ID.

## Player Fantasy

- **A crisis is a negotiation, not an error.** The coalition breaks as "a political crisis rather than a menu error"
  (PM:723). The refusing faction speaks its terms; the player chooses which concession to make, and the concession
  is withdrawn on the record and answered by the person whose position it was (new content, the retraction beats).
- **A deferral is a promise you keep or break.** Choosing the witnesses over a concession keeps the coalition
  provisional: the room remembers through Act 3 that Hearth has not endorsed the final act, the player knows what
  still has to be done to earn it, and keeping or breaking the promise each plays its own beat.
- **No dead ends.** Every unresolved state has a way out that the fiction states; a closed door is shown closed.

## Detailed Design

### Inputs and outputs

Reads and writes the composer input record of `storyline-axes.md` (fields `authority`, `faction`, `deleted`,
`storyline_id`, `witness_deferred`, `root_phase`, `secret_invoked`, `axis_revised`, `lock_negotiated`,
`retraction_log`, `beats_played`, `witness_mandate`) and the seed, prerequisite and unlock flags. Every field is
saved, so a reload restores the retractions and beats exactly. `storyline_phase` is derived (`storyline-axes.md`
Formulas), never stored. Knobs are read only at C8-S16, the invocation scenes and the gate.

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
2026-11-10). **Witness clause (R1 only, user decision 2026-11-10):** when `signpost(WITNESS)` is OPEN, the Hearth
delegate's line adds the clause "unless the affected themselves authorize it", grounded in the Witness answer of
the Last Offer ("The affected authorize the act.", PM:8411). It names the institution, never the combination (Core
Rule 6 of `storyline-axes.md`); with the signpost HIDDEN or CLOSED the line has no clause.

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
primary not total winner.", PM:7409). The deferral offer lists the Witness leads still open.

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
| Secret Quest 09 Witness Seats | PM:7517-7519 | unchanged: the Assembly names the seven |
| Act 3 ending | PM:7539-7564 | beat `deferral_act3_end`: the Assembly approves the expedition with Hearth's endorsement still withheld |
| Chapter 9: C9-S01 to C9-S17, the three truth routes, C9-S18, C9-S20, the optional rooms and side quests | PM:7661-8187 | unchanged: the expedition is away from the Assembly; C9-S19 is S6 |

The deferral ends in one of two beats: kept — `invoke_witness` (S6 or the gate: Kaelen narrows his commitment on
the record and Hearth endorses the act through the witnesses); broken — the retraction beat and the gate retcon
beat of the renegotiation taken (S7). No other content changes.

**S6 — C9-S19 Seven Witness Protocol (invocation).** Available from its slot in Chapter 9 until the Chapter 9 end;
it plays the first time the player reaches it with every Witness offer prerequisite set (PM:8047) and sets
`SEVEN_WITNESSES_AVAILABLE` on every storyline (PM:8055, PM:8200). After the Chapter 9 end it cannot play, so a
prerequisite still unset then is unreachable and the signpost shows CLOSED. If the phase is DEFERRED and WITNESS is
enabled, it offers `invoke:WITNESS`; confirming (T7) is irreversible. Declining keeps the deferral. While
FIRSTWAKE and CROWNLESS are disabled, C9-S18 plays only its incomplete form ("If prerequisites incomplete packet
remains noise.", PM:8043), C9-S20 does not play, and neither sets its unlock flag.

**S7 — The ID-lock gate.** Runs on every entry and re-entry into Root of Heaven, by each path: `story` (after the
Chapter 9 end, before PM:8206 "Root of Heaven gate opens"), `world_map` (world map or free travel; protected logic,
needs the user's approval when implemented) and `load` (a save positioned inside Root of Heaven). The stored-ID
check is necessary, not sufficient: the story path reaches the gate only after the Chapter 9 end, and the world-map
path only once Root of Heaven is on the map. Outcome by phase:

| phase | outcome |
|---|---|
| LEANING, PARTLY_LOCKED | TURNED_BACK: the Assembly has not decided |
| DEFERRED | LAST_CHANCE: offers the six R1 renegotiations and, when `SEVEN_WITNESSES_AVAILABLE` is set, WITNESS is enabled and its prerequisites are met, `invoke:WITNESS`; leaving returns the player outside, still DEFERRED |
| VALIDATED | ROOT_OF_HEAVEN; `root_phase` becomes INSIDE (T11) |
| FIXED, FINAL | ROOT_OF_HEAVEN; nothing changes (T12) |

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

**Legacy saves.** A save whose story position (StoryGraph, Y1-P1-T03) is past an axis's lock scene while that axis
is UNSET — every save made past Chapter 8 before these fields exist — replays the missing lock scenes on load, in
order, as one Assembly session (T14), before play resumes at the saved position. The lock scenes stay the only
writers of the axes (I1); for I5 such a save is before the locks. A crisis in the catch-up resolves as in S4; with
no Witness flags in the save its signpost is HIDDEN and it offers renegotiations only.

**S8 — Final authorization (PM:8786-8794).** After the boss: displays the stored structure, offers no
reconsideration, and `confirm_execution` sets `root_phase` FINAL (T13); nothing else changes. Before the confirm,
Kaelen says his three route lines ("If player maintains route", PM:8795, always holds): Authority (PM:8797-8799;
on `SL-SECRET-WITNESS` its Consent line, new content), Deleted (PM:8800-8802) and Faction (PM:8803-8805).

**S9 — C10-S15 Secret Route Seven Witnesses (the witness vote).** Plays only on `SL-SECRET-WITNESS`: the source's
guard "If SEVEN_WITNESSES_AVAILABLE." (PM:8693) is set on every storyline by C9-S19, so this design gates the
scene on the stored ID. It is the Crown phase's route interaction (PM:8617-8618). The seven witnesses are the ones
Secret Quest 09 named, one per requirement (PM:8697-8703), and are seven identities other than Kaelen: a design
narrowing of PM:8704, which lets Kaelen be one of them (Core Rule 10 of `storyline-axes.md`). Each witness assents
or dissents, the scene names every dissent (PM:8705-8709), and the vote sets `witness_mandate` (Formulas). MET: the
ending plays "Authorized by the Living" (PM:8784) with the dissenters named. FAILED (user decision 2026-11-10): the
ending plays the failed-mandate module `consent_failed_mandate` ("authorized over dissent"); what it shows is
authored by Y2-PP-T17 within two limits — Kaelen does not authorize in the witnesses' place, and nothing changes the
stored ID, the family or the axes. C10-S13 and C10-S14 follow the same rule for their routes when those ship.

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
PM:7034-7040). Scenes that played before the invocation keep their YOU form as history (S7's history rule).

### States and Transitions

The phases are `storyline-axes.md`'s phase table. Transitions:

| # | from | event | guard | to | effects |
|---|---|---|---|---|---|
| T1 | LEANING | C8-S13 resolves | — | PARTLY_LOCKED | faction set; `lock_negotiated` per `lock_pass` |
| T2 | PARTLY_LOCKED | C8-S14 resolves | faction set, authority UNSET | PARTLY_LOCKED | authority set; `lock_negotiated` per `lock_pass` |
| T3 | PARTLY_LOCKED | C8-S16 resolves | faction and authority set; the row is valid | VALIDATED | deleted set; `lock_negotiated` per `lock_pass`; ID stored |
| T4 | PARTLY_LOCKED | C8-S16 resolves | faction and authority set; the row is invalid | CRISIS | deleted set; `lock_negotiated` per `lock_pass`; the refusing faction breaks the coalition |
| T5 | CRISIS | a renegotiation is taken | the offer is in the row's offer set | VALIDATED | the axis changed; `axis_revised`, `lock_negotiated` gain it; retraction recorded; retraction beat played; ID stored |
| T6 | CRISIS | the deferral is taken | R1; WITNESS enabled; signpost OPEN | DEFERRED | `witness_deferred` set |
| T7 | DEFERRED | the invocation is confirmed (C9-S19 or the gate) | `SEVEN_WITNESSES_AVAILABLE` set; WITNESS enabled; prerequisites met | VALIDATED | `secret_invoked` gains WITNESS; `SL-SECRET-WITNESS` stored; narrowing retraction recorded; `invoke_witness` played |
| T8 | DEFERRED | a renegotiation is taken at the gate | one of the six R1 offers | VALIDATED | as T5; gate retcon beat played |
| T9 | DEFERRED | Root of Heaven entry, any path | — | DEFERRED | LAST_CHANCE scene; leaving returns the player outside |
| T10 | LEANING or PARTLY_LOCKED | Root of Heaven entry, any path | — | unchanged | TURNED_BACK |
| T11 | VALIDATED | Root of Heaven entry, any path | — | FIXED | `root_phase` INSIDE |
| T12 | FIXED or FINAL | Root of Heaven entry, any path | — | unchanged | open |
| T13 | FIXED | execution confirmed | the final authorization scene is playing | FINAL | `root_phase` FINAL |
| T14 | LEANING or PARTLY_LOCKED | a save loads | its story position is past the lock scene of an UNSET axis | unchanged | lock catch-up: the missing lock scenes play in order, then T1-T6 as usual |

No other transition exists: nothing leads from VALIDATED, FIXED or FINAL to an earlier phase or to DEFERRED or
CRISIS — not a knob change, not a flag, not loading. The story graph never starts C8-S14 before C8-S13 resolves or
C8-S16 before C8-S14 resolves, except in the T14 catch-up, which keeps that order; a graph that could break it is a
data error FlagRegistry reports at boot (Y1-P1-T03). Loading restores the record and derives the phase; apart from
the T14 catch-up it fires no transition by itself, and a save positioned inside Root of Heaven then runs the gate
check (T9-T12) as its entry. `witness_mandate` is written once, by C10-S15, and changes no phase.

**NG+ reset** (until NG+ design decides carry-over): `authority`, `faction`, `deleted` → UNSET; `storyline_id` →
empty; `witness_deferred` → false; `root_phase` → OUTSIDE; `secret_invoked`, `axis_revised`, `lock_negotiated`,
`retraction_log`, `beats_played` → empty; `witness_mandate` → UNDECIDED. The `AXIS*`, `axis_revised_*` and
`lock_negotiated_*` flags and the secret routes' prerequisite and unlock flags are cleared with the record; the Act
1 seed flags follow NG+'s own flag reset. NG+ starts a new record, not a transition of this table: the previous
cycle's record is kept for Story+ under its own ID (PM:11300, PM:11303).

## Formulas

```
crisis_offers(row) = {} if row is not R1, R2 or R3; otherwise
                     { "revise:" + axis + ":" + v : axis locked, v ≠ row[axis], not invalid(row with axis = v) }
                     ∪ { "defer:WITNESS" : row = R1, enabled(WITNESS), signpost(WITNESS) = OPEN }
last_chance_offers  = crisis_offers(R1) without "defer:WITNESS"
                     ∪ { "invoke:WITNESS" : SEVEN_WITNESSES_AVAILABLE set, enabled(WITNESS), prereqs_met(WITNESS) }
signpost(T)         = HIDDEN  if none of T's offer prerequisites is set, or T is reserved (post-1.0) and disabled
                      CLOSED  if T is disabled, an ID is stored and it is not "SL-SECRET-" + T,
                              or an unset offer prerequisite of T is unreachable
                      OPEN    otherwise
witness_mandate     = MET     if 7 − dissent ≥ witness_threshold
                      FAILED  otherwise
```

`invalid`, `enabled`, `prereqs_met` and the row notation are `storyline-axes.md`'s. `unreachable(flag)`: StoryGraph
(Y1-P1-T03) reports that no content still ahead of the player sets the flag. The tests run top to bottom, so a
reserved route is hidden even with its arc flags set, and a shipped route that a patch disables or whose lead is
missed shows CLOSED, never HIDDEN (invariant I6). Because the deferral needs the signpost OPEN, it is never offered
when a Witness lead can no longer be completed. `dissent` (0-7) is the number of witnesses who dissent at C10-S15;
`witness_threshold` is the number of assents the protocol needs, 4-6 ("threshold not unanimity", PM:8706; a
majority floor by design), which the player helps define (PM:8707) in a scene Y2-PP-T17 writes (Open Question 4).

Counts: |crisis_offers| is 6 for R1 (7 with the deferral), 5 for R2 and R3, so 16 renegotiation offers in all;
|last_chance_offers| is 6 or 7. |crisis_offers| is 0 for every valid row.

## Edge Cases

1. **Crash or quit during C8-S16.** No save exists inside the scene (autosave is suppressed in it), so the player
   reloads the last save before it (PARTLY_LOCKED) and the scene replays.
2. **Deferred, but Secret Quest 09 is never completed.** C9-S19 does not play, `SEVEN_WITNESSES_AVAILABLE` stays
   unset, the signpost shows CLOSED once the quest is unreachable, and the gate's LAST_CHANCE offers the six
   renegotiations only.
3. **Deferred, the player declines at C9-S19.** Still DEFERRED; LAST_CHANCE offers the invocation again.
4. **Deferred, and a patch disables WITNESS** (outside its safe range; a 1.0 build that does it fails boot
   validation). The signpost shows CLOSED; LAST_CHANCE offers the six renegotiations only (I5, I6).
5. **The player leaves LAST_CHANCE repeatedly.** Each exit returns them outside the gate, still DEFERRED; Chapter 9
   content already played stays played. There is no limit and no penalty.
6. **Leaving Root of Heaven mid-boss and re-entering.** FIXED → T12: open, nothing changes; the boss restarts per
   the combat system. A C10-S15 vote already taken keeps its `witness_mandate`.
7. **Story+ re-entry after execution.** FINAL → T12: open.
8. **A save in DEFERRED is loaded after C9-S19 already played with the invocation declined.**
   `SEVEN_WITNESSES_AVAILABLE` is in the save; LAST_CHANCE offers the invocation.
9. **A deferral, then a renegotiation at the gate.** `witness_deferred` stays true on a valid row that is not R1;
   with `axis_revised` non-empty that is the T8 history, not a damaged record (`storyline-axes.md` Edge Case 16).
10. **A legacy save inside Root of Heaven.** T14 replays the missing lock scenes first; the stored ID that results
    then runs the `load` gate check (T11).
11. **All seven witnesses dissent.** `witness_mandate` FAILED; the ID stays `SL-SECRET-WITNESS`, the family CONSENT,
    and the failed-mandate module plays (S9).

## Dependencies

| System | Direction | What flows | Status |
|---|---|---|---|
| Storyline axes (`design/gdd/storyline-axes.md`) | this ← axes | values, formulas, record, invariants I1-I8, knobs | revision 5 |
| SaveService (Y1-P1-T05) | this → save | record writes, including `retraction_log`, `beats_played`, `witness_mandate`; autosave suppression in C8-S16; damaged-record check on load; the T14 legacy check | no GDD |
| FlagRegistry / StoryGraph (Y1-P1-T03) | this ← registry | flags; scene order check at boot; `unreachable(flag)`; the story position for T14 | no GDD |
| World map / free travel (protected) | this → world map | the gate check on the `world_map` path | no GDD — needs the user's approval when implemented |
| Ending composer (Y2-PP-T17) | this → composer | `witness_deferred`, retractions, beats played, `witness_mandate`, the Consent variants, the history rule | not designed |
| Combat / boss (Root of Heaven) | this → boss | the Consent variants of B22 and B23; C10-S15 in the Crown phase; re-entry rule | no GDD — combat is protected |

Bidirectional rule: `storyline-axes.md` names this document in its Dependencies; each doc above written later must
too. The protected areas this contract touches are listed in `storyline-axes.md` Dependencies.

## Tuning Knobs

None of its own. It reads `secret_route_enabled`, `secret_prerequisites` and `secret_unlock_flag` from
`storyline-axes.md`, only at C8-S16, C9-S19 and the gate. Not knobs: the scene order, the offer sets (derived from
`invalid`), the rule that C8-S16 cannot be left with a crisis open, and the rule that a stored ID never changes.
`witness_threshold` is not a knob either: the player helps define it in play (PM:8707).

## Acceptance Criteria

**Document-level — checked by `production/qa/evidence/2026-11-storyline/check_storyline_axes.py`:** the transition
table has rows T1-T14 exactly as pinned (from, guard, to, effects); every from/to value is a phase of
`storyline-axes.md`; the crisis offer table equals `crisis_offers` computed from `invalid()` for R1-R3; the red-line
table names exactly R1-R3 with their pairs; every L-AC below names its blocking stories and uses only observables
from the table below.

**Scene-level observables** — every one returns the stated value outside its scene:

| observable | returns | outside its scene |
|---|---|---|
| `storyline_phase()` | the derived phase of the current record | — |
| `storyline_id()` | the stored ID | empty string when nothing is stored |
| `axis(name)` | the record's `authority`, `faction` or `deleted` | — |
| `gate_open()` | true exactly when an ID is stored (the gate check passes; the path to the gate is story progression) | — |
| `enter_root_of_heaven(path)` | for path `story`, `world_map` or `load`: ROOT_OF_HEAVEN, LAST_CHANCE or TURNED_BACK | — |
| `current_scene()` | the id of the playing scene | — |
| `lock_options(axis)` | in that axis's lock scene, the values offered | empty |
| `lock_arguments(axis)` | in that axis's lock scene, the (flag, value, sign) arguments voiced | empty |
| `red_lines_voiced(scene)` | the rule ids voiced the last time that scene played | empty if it never played |
| `red_line_clause()` | whether the last R1 line voiced at C8-S15 carried the witness clause | false if it never played |
| `offers()` | in the C8-S16 crisis, at C9-S19 while it offers the invocation, or in LAST_CHANCE: the current offer set | empty in every other scene |
| `take(offer)` | true if the offer is in `offers()` and was taken; otherwise false and nothing changes | false |
| `decline()` | in C9-S19 or LAST_CHANCE with `invoke:WITNESS` offered: true, invocation declined | false |
| `retraction_log()` | the saved `retraction_log`: every retraction as {axis, old, new, withdrawn_item, scene}, oldest first | — |
| `beats_played()` | the saved `beats_played`: the authored beat ids played (`retract_*`, `gate_retcon_*`, `deferral_*`, `invoke_witness`) | — |
| `signpost(route)` | HIDDEN, OPEN or CLOSED (Formulas) | — |
| `quoted_commitment()` | the commitment SOVEREIGN quotes and its status: STATED, WITHDRAWN or NARROWED | NONE if Authority was never YOU |
| `consent_variant(scene)` | true when the scene plays its Consent variant | false for a scene not yet played |
| `witnesses()` | at C10-S15, the seven witness identities | empty |
| `route_lines()` | in the final authorization, the source line ids Kaelen says | empty |
| `ending_modules()` | the ending module ids the composer selected for the current record | — |
| `confirm_execution()` | in the final authorization: confirms, returns true | false |
| `load_errors()` | the data errors found by the last load | empty |
| `epilogue_lines()` | the arc ids that get an epilogue line | — |
| `record_field(name)` | the current value of a stored record field (`lock_negotiated`, `axis_revised`, `witness_deferred`, `secret_invoked`, `root_phase`, `witness_mandate`) | — |
| `flag_set(name)` | whether the named story flag is set | — |

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
- **L-AC5 Crisis offers.** On each invalid row, inside C8-S16, `offers()` equals the crisis offer table's set (R1
  with `defer:WITNESS` only when WITNESS is enabled and `signpost(WITNESS)` is OPEN); `current_scene()` stays C8-S16
  and no save can be made until an offer is taken. *Blocked by:* Y2-PP-T17, Y1-P1-T05.
- **L-AC6 Renegotiation.** From each invalid-row fixture with `record_field(lock_negotiated)` and
  `record_field(axis_revised)` empty, for each of its offers (16 runs): `take()` true; `storyline_phase()`
  VALIDATED; `storyline_id()` the new row's ID; `axis(name)` the new value; `record_field(axis_revised)` and
  `record_field(lock_negotiated)` contain the axis; the last `retraction_log()` entry has the axis, old and new
  values, the table's withdrawn item and scene C8-S16; `beats_played()` gains `retract_<rule>_<axis>_<new>`, and the
  16 runs yield 16 distinct beat ids. `take()` of a value not offered (the same value; the other invalid row) is
  false and changes nothing. *Blocked by:* Y2-PP-T17.
- **L-AC7 Deferral.** On R1 with WITNESS enabled and the signpost OPEN, `take(defer:WITNESS)` gives DEFERRED,
  `storyline_id()` empty, `gate_open()` false, `record_field(witness_deferred)` true; with the signpost HIDDEN or
  CLOSED, or WITNESS disabled, `defer:WITNESS` is not in `offers()`; it is never offered on R2 or R3. A DEFERRED run
  to the gate gains `deferral_c8s17`, `deferral_branch_h`, `deferral_c8s20` and `deferral_act3_end` in
  `beats_played()`; a record VALIDATED by T3 or T5 gains none of them. *Blocked by:* Y2-PP-T17.
- **L-AC8 Invocation.** From DEFERRED with the three Witness offer prerequisites set: C9-S19 makes
  `flag_set(SEVEN_WITNESSES_AVAILABLE)` true and `offers()` contains `invoke:WITNESS`; `take(invoke:WITNESS)` gives
  VALIDATED, `storyline_id()` `SL-SECRET-WITNESS`, `record_field(secret_invoked)` {WITNESS}, a `retraction_log()`
  entry (authority, YOU, YOU, "final permission", C9-S19) and `invoke_witness` in `beats_played()`. After `decline()`
  the phase stays DEFERRED and LAST_CHANCE's `offers()` contains `invoke:WITNESS`. On a VALIDATED record C9-S19
  still makes `flag_set(SEVEN_WITNESSES_AVAILABLE)` true, `offers()` there is empty and the ID is unchanged. With
  FIRSTWAKE and CROWNLESS disabled and all their prerequisites set, `flag_set(FIRST_WAKE_AVAILABLE)` and
  `flag_set(CROWNLESS_AVAILABLE)` stay false after Chapter 9. *Blocked by:* Y2-PP-T17, Y1-P1-T03.
- **L-AC9 The gate.** For each path in `story`, `world_map`, `load` and each phase: LEANING and PARTLY_LOCKED →
  TURNED_BACK; DEFERRED → LAST_CHANCE with `offers()` exactly the six R1 renegotiations plus `invoke:WITNESS` when
  its guard holds, and leaving returns the player outside with the phase DEFERRED; VALIDATED → ROOT_OF_HEAVEN and
  FIXED; FIXED and FINAL → ROOT_OF_HEAVEN, phase unchanged. Cells impossible in play (for example LEANING on the
  `story` path) run from synthetic fixture saves and are reported as synthetic. *Blocked by:* Y2-PP-T17; the
  `world_map` path also the approved world-map change.
- **L-AC10 Held to its word.** From VALIDATED records reached by T3, T5, T7 and T8 (one per family, CONSENT
  included) and from FIXED and FINAL records: at C9-S19 and at the gate on each path `offers()` is empty and
  `enter_root_of_heaven()` is ROOT_OF_HEAVEN; after setting every prerequisite and unlock flag, disabling WITNESS and
  emptying `secret_prerequisites[WITNESS]`, `storyline_id()` and `storyline_phase()` are unchanged. *Blocked by:*
  Y2-PP-T17.
- **L-AC11 Patch while deferred.** From DEFERRED, disabling WITNESS makes `signpost(WITNESS)` CLOSED and
  LAST_CHANCE's `offers()` exactly the six renegotiations. *Blocked by:* Y2-PP-T17.
- **L-AC12 Signposts.** `signpost(WITNESS)` is HIDDEN with no offer prerequisite set, OPEN once one is set, CLOSED
  once an ID other than `SL-SECRET-WITNESS` is stored, and CLOSED when an unset prerequisite becomes unreachable
  (Secret Quest 09 skipped past its last chance); `signpost` of CROWNLESS and FIRSTWAKE is HIDDEN while disabled,
  even with all their flags set. *Blocked by:* Y2-PP-T17, Y1-P1-T03.
- **L-AC13 Final authorization.** In FIXED after the boss, the final authorization offers nothing,
  `route_lines()` is the stored row's Authority, Deleted and Faction lines (PM:8797-8805; the Consent Authority line
  on `SL-SECRET-WITNESS`), and `confirm_execution()` gives FINAL with `storyline_id()` unchanged;
  `confirm_execution()` anywhere else is false and changes nothing. *Blocked by:* Y2-PP-T17.
- **L-AC14 Consent and the witness vote.** On `SL-SECRET-WITNESS`, `consent_variant()` is true for every scene of the
  Consent variants table, and `quoted_commitment()` is NARROWED; `witnesses()` holds seven distinct identities, none
  of them Kaelen, including a deleted citizen (PM:8698). For each `witness_threshold` fixture 4, 5 and 6 and each
  `dissent` fixture 0 to 7: `record_field(witness_mandate)` is MET exactly when 7 − dissent ≥ the threshold,
  `ending_modules()` contains `consent_failed_mandate` exactly when it is FAILED, and `storyline_id()` is unchanged.
  On every SOLE storyline, with `flag_set(SEVEN_WITNESSES_AVAILABLE)` true, `consent_variant()` is false for the
  same scenes and C10-S15 never becomes `current_scene()`. *Blocked by:* Y2-PP-T17.
- **L-AC15 Quoted commitment.** YOU locked at C8-S14 and never revised → STATED, the C8-S14 commitment; YOU reached
  by a renegotiation (from R2 or R3) → STATED, that scene's commitment; YOU withdrawn by a renegotiation from R1 at
  C8-S16 or at the gate → WITHDRAWN; Authority never YOU → NONE. *Blocked by:* Y2-PP-T17.
- **L-AC16 Saves.** A save in each storable phase (LEANING, PARTLY_LOCKED, DEFERRED, VALIDATED, FIXED, FINAL)
  reloads with the same `storyline_phase()`, `storyline_id()`, `retraction_log()`, `beats_played()` and record,
  with `load_errors()` empty, even after a knob is flipped; a save with no axis data positioned before C8-S13 loads
  LEANING with `load_errors()` empty; a DEFERRED-then-T8 record loads with `load_errors()` empty; each damaged
  record of `storyline-axes.md` Edge Case 16 gives a non-empty `load_errors()`. *Blocked by:* Y2-PP-T17,
  Y1-P1-T05.
- **L-AC17 Epilogue lines.** With the completion flags of arcs 05, 08 and 09 set — `CROWN_COORDINATES` (arc 08,
  PM:3683), `OLD_HOME_MESSAGE` (arc 09, PM:3814) and arc 05's Quest 30 flag, which the sources do not name
  (PM:2690-2691) and Y2-PP-T17 names before this runs — `epilogue_lines()` contains all three arcs on every 1.0
  storyline, and contains none of them with no flag set. *Blocked by:* Y2-PP-T17.
- **L-AC18 NG+ reset.** Starting NG+ from a FINAL record gives LEANING, every axis UNSET, `storyline_id()` empty,
  the reset fields at their defaults, and `flag_set()` false for `SEVEN_WITNESSES_AVAILABLE` and every Witness
  offer prerequisite. *Blocked by:* Y2-PP-T17, NG+ design.
- **L-AC19 Gate renegotiation and history.** From a DEFERRED record that played the Hearth branch and C8-S20, for
  each of the six R1 offers at LAST_CHANCE: `take()` gives VALIDATED with the new row's ID; `beats_played()` gains
  `retract_R1_<axis>_<new>` and then `gate_retcon_<axis>_<new>`; `retraction_log()` gains an entry with scene
  LAST_CHANCE; `flag_set(STEWARD_DEFEATED)` and the `HEARTH_*` policy flags stay as they were; `axis()` reads the
  new value; after a Faction offer `ending_modules()` holds no module that needs the new faction's branch boss flag.
  *Blocked by:* Y2-PP-T17.
- **L-AC20 Legacy saves.** A save with no axis data positioned in Chapter 9 and one positioned inside Root of Heaven:
  on load, `current_scene()` becomes C8-S13, then C8-S14 and C8-S16 in order; after them the phase is VALIDATED (or
  the crisis plays, with `defer:WITNESS` not offered) and play resumes at the saved position, through the `load`
  gate check for the second save. `load_errors()` is empty for both. *Blocked by:* Y2-PP-T17, Y1-P1-T03,
  Y1-P1-T05.

**Validation note:** the route bot of ROADMAP §12.4 starts from Chapter 8 fixture saves once the locks exist (owner
Y2-PP-T17): one run per valid row through C8-S16 (24), one Witness run through the deferral and C9-S19 (1), one per
renegotiation offer at C8-S16 (16), one deferral-then-LAST_CHANCE invocation (1), one deferral-then-LAST_CHANCE run
per R1 renegotiation (6), and the gate matrix of 3 paths × 6 storable phases (18) — 66 runs. A run passes when the
observed (`storyline_phase()`, `storyline_id()`, `enter_root_of_heaven()` outcome of its last gate entry) equals
the expected triple; gate-matrix cells impossible in play are reported as synthetic.

## Open Questions

1. **Beat texts:** the 16 `retract_*`, the six `gate_retcon_*`, the four `deferral_*` beats and `invoke_witness` are
   written by Y2-PP-T17; which companion answers each retraction (Nema on a NONE withdrawal, PM:7078-7087, is the
   obvious first) is decided there. The `deferral_*` texts need the user's approval (S5: new content).
2. **More Chapter 9 reactions under a deferral:** this contract changes none of Chapter 9 (S5); whether later passes
   add any is for Y2-PP-T17.
3. **Boss restart on re-entry** belongs to the combat system; this contract only says the stored ID and
   `witness_mandate` are unchanged.
4. **Where the player helps define `witness_threshold`** (PM:8707): no source scene does it. Proposed: Secret Quest
   09, when the Assembly names the seven, with 4-6 as the range (Formulas). Needs the user's OK with Y2-PP-T17.
5. **Gate retcon after a Faction change:** which composer modules stand in for the new faction's unplayed Act 3
   branch beyond the retcon beat is for Y2-PP-T17 (S7 history rule).
