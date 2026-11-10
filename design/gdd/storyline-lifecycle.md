# Storyline Lifecycle

> **Status**: Draft (new, 2026-11-10; split from `storyline-axes.md` revision 3 after design review round 4)
> **Author**: Claude with the project lead
> **Last Updated**: 2026-11-10
> **Implements**: the invariants I1-I8 of `design/gdd/storyline-axes.md`; contract for Y2-PP-T17 (ending composer /
> route data model)
> **Implements Pillar**: P3, P5, P8 (through `storyline-axes.md`)

## Summary

The scenes and transitions that turn the three story axes into one stored storyline ID: the three lock scenes, the
red-line beat, the C8-S16 crisis (renegotiate, or defer to the witnesses on R1), the provisional coalition, the
Witness Protocol invocation, the ID-lock gate on every path and the final authorization. `storyline-axes.md` owns
the values, the formulas and the record; this document owns when each field is written.

> **Quick reference** — Layer: `Foundation` · Priority: `Alpha` · Depends on: `storyline-axes.md`

## Overview

Chapter 8 locks Faction (C8-S13), Authority (C8-S14) and Deleted (C8-S16), in that order. A valid row is stored at
once. An invalid row breaks the coalition inside C8-S16, and the scene does not end until it holds again: the player
takes one of the refusing faction's demands (a renegotiation of one axis) or, on R1 with the Witness Protocol
signpost showing, defers to the witnesses. A deferral is a provisional coalition: Hearth stays in the Assembly but
withholds endorsement of the final act until C9-S19 convenes the seven witnesses, or until the player renegotiates
at the gate. Every entry and re-entry into Root of Heaven runs one gate check; the final authorization only
confirms. There is no state in which a player can be stranded, and no transition back from a stored ID.

## Player Fantasy

- **A crisis is a negotiation, not an error.** The refusing faction speaks its terms; the player chooses which
  concession to make, and the concession is said aloud, on the record, by someone who loses by it (PM:723).
- **A deferral is a promise you keep or break.** Choosing the witnesses over a concession keeps the coalition
  provisional: the room remembers through Act 3 that Hearth has not endorsed the final act, and the player knows
  what still has to be done to earn it.
- **No dead ends.** Every unresolved state has a way out that the fiction states; a closed door is shown closed.

## Detailed Design

### Inputs and outputs

Reads and writes the composer input record of `storyline-axes.md` (fields `authority`, `faction`, `deleted`,
`storyline_id`, `witness_deferred`, `root_phase`, `secret_invoked`, `axis_revised`, `lock_negotiated`) and the
seed, prerequisite and unlock flags. `storyline_phase` is derived (`storyline-axes.md` Formulas), never stored.
Knobs are read only at C8-S16, the invocation scenes and the gate.

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
2026-11-10).

**S4 — C8-S16 Axis Three Lock and crisis.** Offers all three Deleted values. On a valid row it stores the ID (T3).
On an invalid row the refusing faction breaks the coalition, naming the combination for the first time
(PM:7138-7153), and the scene becomes the crisis (T4). The crisis cannot be left, skipped or saved until an offer
is taken (PM:7143, PM:7153). Its offers, each voiced as the refusing faction's demand:

| row | offers |
|---|---|
| R1 YOU-HEARTH-RESTORE | `revise:authority:SHARED`, `revise:authority:NONE`, `revise:faction:ARCHIVE`, `revise:faction:CONTINUITY`, `revise:deleted:RELEASE`, `revise:deleted:CHOOSE`; plus `defer:WITNESS` when WITNESS is enabled and its signpost is OPEN |
| R2 NONE-ARCHIVE-RELEASE | `revise:authority:YOU`, `revise:authority:SHARED`, `revise:faction:HEARTH`, `revise:deleted:RESTORE`, `revise:deleted:CHOOSE` |
| R3 NONE-CONTINUITY-RELEASE | `revise:authority:YOU`, `revise:authority:SHARED`, `revise:faction:HEARTH`, `revise:deleted:RESTORE`, `revise:deleted:CHOOSE` |

**Retractions.** A renegotiation withdraws Kaelen's superseded position on the record, and one authored cost beat
plays: a speaker other than Kaelen — the delegate or companion whose position is withdrawn — answers it (beat id
`retract_<axis>_<old>_<new>`, 16 beats, written by Y2-PP-T17). The vote then passes negotiated.

| axis | withdrawn on the record | source |
|---|---|---|
| Faction | what C8-S13 adopted: Hearth's mutual-defense charter, the Archive's public evidence charter, or the Continuity League's emergency operations network (a network, not a charter). Kaelen's interim role already ended at the Authority lock and is not withdrawn | PM:7003, PM:7010, PM:7021; roles end PM:7006, PM:7017, PM:7027 |
| Authority | Kaelen's C8-S14 position: YOU, his vow and chosen commitment; SHARED, the seven-signature protocol; NONE, the dismantling commitment | PM:7045-7057, PM:7064-7069, PM:7036-7038 |
| Deleted | the policy adopted at C8-S16: restore, release or choose | PM:7093-7095 |

When a renegotiation reaches YOU, Kaelen states his commitment in that scene, and that becomes the quoted one.

**S5 — Provisional coalition (DEFERRED only).** Two authored beats show that Hearth takes part but withholds
endorsement of the final act (PM:7144): at C8-S17 Revolution Name (PM:7155-7163; Hearth joins the naming and says
what it has not endorsed) and at the Act 3 ending, where the Assembly approves the expedition (PM:7540). Beat ids
`deferral_c8s17`, `deferral_act3_end`. No other Chapter 8 or 9 content changes; Secret Quest 09 (PM:7517-7519) is
where the Assembly names the seven.

**S6 — C9-S19 Seven Witness Protocol (invocation).** Plays when every Witness offer prerequisite is set
(PM:8047) and sets `SEVEN_WITNESSES_AVAILABLE` on every storyline (PM:8055, PM:8200). If the phase is DEFERRED and
WITNESS is enabled, it offers `invoke:WITNESS`; confirming (T7) is irreversible. Declining keeps the deferral.

**S7 — The ID-lock gate.** Runs on every entry and re-entry into Root of Heaven, by each path: `story` (after the
Chapter 9 end, before PM:8206 "Root of Heaven gate opens"), `world_map` (world map or free travel; protected logic,
needs the user's approval when implemented) and `load` (a save positioned inside Root of Heaven). Outcome by phase:

| phase | outcome |
|---|---|
| LEANING, PARTLY_LOCKED | TURNED_BACK: the Assembly has not decided |
| DEFERRED | LAST_CHANCE: offers the six R1 renegotiations and, when `SEVEN_WITNESSES_AVAILABLE` is set, WITNESS is enabled and its prerequisites are met, `invoke:WITNESS`; leaving returns the player outside, still DEFERRED |
| VALIDATED | ROOT_OF_HEAVEN; `root_phase` becomes INSIDE (T11) |
| FIXED, FINAL | ROOT_OF_HEAVEN; nothing changes (T12) |

**S8 — Final authorization (PM:8786-8794).** After the boss: displays the stored structure, offers no
reconsideration, and `confirm_execution` sets `root_phase` FINAL (T13). Nothing else.

**Consent variants.** On `SL-SECRET-WITNESS`, every scene that reads the Authority value plays its Consent variant:
boss phase 4 (PM:8615-8616, PM:8638-8645), C10-S06 and C10-S09 (PM:8408), and SOVEREIGN's quote of the commitment
(PM:7059), quoted as narrowed. The invocation records the narrowing as a retraction (`authority`, YOU → YOU,
withdrawn item "final permission", PM:7034-7040).

### States and Transitions

The phases are `storyline-axes.md`'s phase table. Transitions:

| # | from | event | guard | to | effects |
|---|---|---|---|---|---|
| T1 | LEANING | C8-S13 resolves | — | PARTLY_LOCKED | faction set; `lock_negotiated` per `lock_pass` |
| T2 | PARTLY_LOCKED | C8-S14 resolves | faction set, authority UNSET | PARTLY_LOCKED | authority set; `lock_negotiated` per `lock_pass` |
| T3 | PARTLY_LOCKED | C8-S16 resolves | faction and authority set; the row is valid | VALIDATED | deleted set; `lock_negotiated` per `lock_pass`; ID stored |
| T4 | PARTLY_LOCKED | C8-S16 resolves | faction and authority set; the row is invalid | CRISIS | deleted set; `lock_negotiated` per `lock_pass`; the refusing faction breaks the coalition |
| T5 | CRISIS | a renegotiation is taken | the offer is in the row's offer set | VALIDATED | the axis changed; `axis_revised`, `lock_negotiated` gain it; retraction recorded; ID stored |
| T6 | CRISIS | the deferral is taken | R1; WITNESS enabled; signpost OPEN | DEFERRED | `witness_deferred` set |
| T7 | DEFERRED | the invocation is confirmed (C9-S19 or the gate) | `SEVEN_WITNESSES_AVAILABLE` set; WITNESS enabled; prerequisites met | VALIDATED | `secret_invoked` gains WITNESS; `SL-SECRET-WITNESS` stored; narrowing retraction recorded |
| T8 | DEFERRED | a renegotiation is taken at the gate | one of the six R1 offers | VALIDATED | as T5 |
| T9 | DEFERRED | Root of Heaven entry, any path | — | DEFERRED | LAST_CHANCE scene; leaving returns the player outside |
| T10 | LEANING or PARTLY_LOCKED | Root of Heaven entry, any path | — | unchanged | TURNED_BACK |
| T11 | VALIDATED | Root of Heaven entry, any path | — | FIXED | `root_phase` INSIDE |
| T12 | FIXED or FINAL | Root of Heaven entry, any path | — | unchanged | open |
| T13 | FIXED | execution confirmed | the final authorization scene is playing | FINAL | `root_phase` FINAL |

No other transition exists: nothing leads from VALIDATED, FIXED or FINAL to an earlier phase or to DEFERRED or
CRISIS — not a knob change, not a flag, not loading. The story graph never starts C8-S14 before C8-S13 resolves or
C8-S16 before C8-S14 resolves; a graph that could is a data error FlagRegistry reports at boot (Y1-P1-T03). Loading
restores the record and derives the phase; it fires no transition by itself, and a save positioned inside Root of
Heaven then runs the gate check (T9-T12) as its entry.

**NG+ reset** (until NG+ design decides carry-over): `authority`, `faction`, `deleted` → UNSET; `storyline_id` →
empty; `witness_deferred` → false; `root_phase` → OUTSIDE; `secret_invoked`, `axis_revised`, `lock_negotiated` →
empty. The previous cycle's record is kept for Story+ under its own ID (PM:11300, PM:11303).

## Formulas

```
crisis_offers(row) = { "revise:" + axis + ":" + v : axis locked, v ≠ row[axis], not invalid(row with axis = v) }
                     ∪ { "defer:WITNESS" : row = R1, enabled(WITNESS), signpost(WITNESS) = OPEN }
last_chance_offers  = crisis_offers(R1) without "defer:WITNESS"
                     ∪ { "invoke:WITNESS" : SEVEN_WITNESSES_AVAILABLE set, enabled(WITNESS), prereqs_met(WITNESS) }
signpost(T)         = HIDDEN  if T is disabled or none of T's offer prerequisites is set
                      CLOSED  if an ID is stored and it is not "SL-SECRET-" + T
                      OPEN    otherwise
```

`invalid`, `enabled`, `prereqs_met` and the row notation are `storyline-axes.md`'s. Counts: |crisis_offers| is 6 for
R1 (7 with the deferral), 5 for R2 and R3, so 16 renegotiation offers in all; |last_chance_offers| is 6 or 7.

## Edge Cases

1. **Crash or quit during C8-S16.** No save exists inside the scene (autosave is suppressed in it), so the player
   reloads the last save before it (PARTLY_LOCKED) and the scene replays.
2. **Deferred, but Secret Quest 09 is never completed.** C9-S19 does not play, `SEVEN_WITNESSES_AVAILABLE` stays
   unset, and the gate's LAST_CHANCE offers the six renegotiations only.
3. **Deferred, the player declines at C9-S19.** Still DEFERRED; LAST_CHANCE offers the invocation again.
4. **Deferred, and a patch disables WITNESS.** The signpost becomes HIDDEN; LAST_CHANCE offers the six
   renegotiations only (I5).
5. **The player leaves LAST_CHANCE repeatedly.** Each exit returns them outside the gate, still DEFERRED; Chapter 9
   content already played stays played. There is no limit and no penalty.
6. **Leaving Root of Heaven mid-boss and re-entering.** FIXED → T12: open, nothing changes; the boss restarts per
   the combat system.
7. **Story+ re-entry after execution.** FINAL → T12: open.
8. **A save in DEFERRED is loaded after C9-S19 already played with the invocation declined.**
   `SEVEN_WITNESSES_AVAILABLE` is in the save; LAST_CHANCE offers the invocation.

## Dependencies

| System | Direction | What flows | Status |
|---|---|---|---|
| Storyline axes (`design/gdd/storyline-axes.md`) | this ← axes | values, formulas, record, invariants I1-I8, knobs | revision 4 |
| SaveService (Y1-P1-T05) | this → save | record writes; autosave suppression in C8-S16; damaged-record check on load | no GDD |
| FlagRegistry / StoryGraph (Y1-P1-T03) | this ← registry | flags; scene order check at boot | no GDD |
| World map / free travel (protected) | this → world map | the gate check on the `world_map` path | no GDD — needs the user's approval when implemented |
| Ending composer (Y2-PP-T17) | this → composer | `witness_deferred`, retractions, beats played, Consent variants | not designed |
| Combat / boss (Root of Heaven) | this → boss | Consent variant of phase 4; re-entry rule | no GDD |

Bidirectional rule: `storyline-axes.md` names this document in its Dependencies; each doc above written later must
too.

## Tuning Knobs

None of its own. It reads `secret_route_enabled`, `secret_prerequisites` and `secret_unlock_flag` from
`storyline-axes.md`, only at C8-S16, C9-S19 and the gate. Not knobs: the scene order, the offer sets (derived from
`invalid`), the rule that C8-S16 cannot be left with a crisis open, and the rule that a stored ID never changes.

## Acceptance Criteria

**Document-level — checked by `production/qa/evidence/2026-11-storyline/check_storyline_axes.py`:** the transition
table has rows T1-T13 exactly as pinned (from, guard, to, effects); every from/to value is a phase of
`storyline-axes.md`; the crisis offer table equals `crisis_offers` computed from `invalid()` for R1-R3; the red-line
table names exactly R1-R3 with their pairs; every L-AC below names its blocking stories and uses only observables
from the table below.

**Scene-level observables** — every one returns the stated value outside its scene:

| observable | returns | outside its scene |
|---|---|---|
| `storyline_phase()` | the derived phase of the current record | — |
| `storyline_id()` | the stored ID | empty string when nothing is stored |
| `axis(name)` | the record's `authority`, `faction` or `deleted` | — |
| `gate_open()` | true exactly when an ID is stored | — |
| `enter_root_of_heaven(path)` | for path `story`, `world_map` or `load`: ROOT_OF_HEAVEN, LAST_CHANCE or TURNED_BACK | — |
| `current_scene()` | the id of the playing scene | — |
| `lock_options(axis)` | in that axis's lock scene, the values offered | empty |
| `lock_arguments(axis)` | in that axis's lock scene, the (flag, value, sign) arguments voiced | empty |
| `red_lines_voiced(scene)` | the rule ids voiced the last time that scene played | empty if it never played |
| `offers()` | in the C8-S16 crisis or LAST_CHANCE, the current offer set | empty |
| `take(offer)` | true if the offer is in `offers()` and was taken; otherwise false and nothing changes | false |
| `decline()` | in C9-S19 or LAST_CHANCE with `invoke:WITNESS` offered: true, invocation declined | false |
| `retraction_log()` | every retraction so far as {axis, old, new, withdrawn_item, scene}, oldest first | — |
| `beats_played()` | the authored beat ids played so far (`retract_*`, `deferral_*`) | — |
| `signpost(route)` | HIDDEN, OPEN or CLOSED (Formulas) | — |
| `quoted_commitment()` | the commitment SOVEREIGN quotes and its status: STATED, WITHDRAWN or NARROWED | NONE if Authority was never YOU |
| `consent_variant(scene)` | true when the scene plays its Consent variant | false for a scene not yet played |
| `witnesses()` | at C10-S15, the seven witness identities | empty |
| `confirm_execution()` | in the final authorization: confirms, returns true | false |
| `load_errors()` | the data errors found by the last load | empty |
| `epilogue_lines()` | the arc ids that get an epilogue line | — |
| `record_field(name)` | the current value of a stored record field (`lock_negotiated`, `axis_revised`, `witness_deferred`, `secret_invoked`, `root_phase`) | — |
| `flag_set(name)` | whether the named story flag is set | — |

**Runtime criteria:**

- **L-AC1 Lock order and options.** For each axis `lock_options(axis)` is all three values with no seed set and with
  one seed per exclusive group set; from a record with Faction UNSET, C8-S14 never becomes `current_scene()`; with
  Authority UNSET, C8-S16 never does. *Blocked by:* Y2-PP-T17, Y1-P1-T03.
- **L-AC2 Arguments and lock pass.** `lock_arguments(axis)` is exactly the set axis seeds of that axis with value and
  sign. Faction backing HEARTH, four fixtures: no seed → `record_field(lock_negotiated)` contains faction; `act1_report_local` →
  not; `act1_report_local` + `ch1_knight_killed` → contains; only `ch1_knight_killed` → contains. Authority and
  Deleted, two fixtures each: no seed → contains; one `+` seed for the backed value → not. Each result survives a
  save and reload. *Blocked by:* Y2-PP-T17, Y1-P1-T03, Y1-P1-T05.
- **L-AC3 Red lines.** `red_lines_voiced(C8-S13)` and `(C8-S14)` are empty; `(C8-S15)` is {R1} after YOU + HEARTH,
  {R2} after NONE + ARCHIVE, {R3} after NONE + CONTINUITY and empty for each of the other six pairs;
  `(C8-S16)` is the row's rule on each invalid row and empty on a valid row. *Blocked by:* Y2-PP-T17.
- **L-AC4 Valid at C8-S16.** For each of the 24 valid rows: after C8-S16, `storyline_phase()` VALIDATED,
  `storyline_id()` the row's ID, `gate_open()` true, `offers()` empty. *Blocked by:* Y2-PP-T17.
- **L-AC5 Crisis offers.** On each invalid row, inside C8-S16, `offers()` equals the crisis offer table's set (R1
  with `defer:WITNESS` only when WITNESS is enabled and `signpost(WITNESS)` is OPEN); `current_scene()` stays C8-S16
  and no save can be made until an offer is taken. *Blocked by:* Y2-PP-T17, Y1-P1-T05.
- **L-AC6 Renegotiation.** From each invalid-row fixture with `record_field(lock_negotiated)` and `record_field(axis_revised)` empty, for each of
  its offers (16 runs): `take()` true; `storyline_phase()` VALIDATED; `storyline_id()` the new row's ID;
  `axis(name)` the new value; `record_field(axis_revised)` and `record_field(lock_negotiated)` contain the axis; the last `retraction_log()`
  entry has the axis, old and new values, the table's withdrawn item and scene C8-S16; `beats_played()` gains
  `retract_<axis>_<old>_<new>`. `take()` of a value not offered (the same value; the other invalid row) is false
  and changes nothing. *Blocked by:* Y2-PP-T17.
- **L-AC7 Deferral.** On R1 with WITNESS enabled and the signpost OPEN, `take(defer:WITNESS)` gives DEFERRED,
  `storyline_id()` empty, `gate_open()` false, `record_field(witness_deferred)` true; with the signpost HIDDEN or WITNESS
  disabled `defer:WITNESS` is not in `offers()`; it is never offered on R2 or R3. In DEFERRED, `beats_played()`
  gains `deferral_c8s17` and `deferral_act3_end`; on any VALIDATED record it gains neither. *Blocked by:* Y2-PP-T17.
- **L-AC8 Invocation.** From DEFERRED with the three Witness offer prerequisites set: C9-S19 makes
  `flag_set(SEVEN_WITNESSES_AVAILABLE)` true and `offers()` contains `invoke:WITNESS`; `take(invoke:WITNESS)` gives VALIDATED,
  `storyline_id()` `SL-SECRET-WITNESS`, `record_field(secret_invoked)` {WITNESS} and a `retraction_log()` entry (authority, YOU,
  YOU, "final permission", C9-S19). After `decline()` the phase stays DEFERRED and LAST_CHANCE's `offers()`
  contains `invoke:WITNESS`. On a VALIDATED record C9-S19 still makes `flag_set(SEVEN_WITNESSES_AVAILABLE)` true, `offers()` is empty and the ID
  is unchanged. *Blocked by:* Y2-PP-T17, Y1-P1-T03.
- **L-AC9 The gate.** For each path in `story`, `world_map`, `load` and each phase: LEANING and PARTLY_LOCKED →
  TURNED_BACK; DEFERRED → LAST_CHANCE with `offers()` exactly the six R1 renegotiations plus `invoke:WITNESS` when
  its guard holds, and leaving returns the player outside with the phase DEFERRED; VALIDATED → ROOT_OF_HEAVEN and
  FIXED; FIXED and FINAL → ROOT_OF_HEAVEN, phase unchanged. A renegotiation at LAST_CHANCE gives VALIDATED, and the
  next entry gives FIXED. *Blocked by:* Y2-PP-T17; the `world_map` path also the approved world-map change.
- **L-AC10 Held to its word.** From VALIDATED records reached by T3, T5 and T7 (one per family, CONSENT included)
  and from FIXED and FINAL records: in every Chapter 9 scene and at the gate on each path `offers()` is empty; after
  setting every prerequisite and unlock flag, disabling WITNESS and emptying `secret_prerequisites[WITNESS]`,
  `storyline_id()` and `storyline_phase()` are unchanged. *Blocked by:* Y2-PP-T17.
- **L-AC11 Patch while deferred.** From DEFERRED, disabling WITNESS makes `signpost(WITNESS)` HIDDEN and
  LAST_CHANCE's `offers()` exactly the six renegotiations. *Blocked by:* Y2-PP-T17.
- **L-AC12 Signposts.** `signpost(WITNESS)` is HIDDEN with no offer prerequisite set, OPEN once one is set, and
  CLOSED once an ID other than `SL-SECRET-WITNESS` is stored; `signpost` of CROWNLESS and FIRSTWAKE is HIDDEN while
  disabled, even with all their flags set. *Blocked by:* Y2-PP-T17, Y1-P1-T03.
- **L-AC13 Final authorization.** In FIXED after the boss, the final authorization offers nothing and
  `confirm_execution()` gives FINAL with `storyline_id()` unchanged; `confirm_execution()` anywhere else is false and
  changes nothing. *Blocked by:* Y2-PP-T17.
- **L-AC14 Consent.** On `SL-SECRET-WITNESS`, `consent_variant()` is true for boss phase 4, C10-S06, C10-S09 and
  the SOVEREIGN quote, and `quoted_commitment()` is NARROWED; `witnesses()` holds seven distinct identities, none of
  them Kaelen, including a deleted citizen (PM:8050); `storyline_id()` is unchanged after C10-S15 for every number
  of dissenting witnesses from 0 to 7 (a fixture input). On every SOLE storyline `consent_variant()` is false for
  the same scenes. *Blocked by:* Y2-PP-T17.
- **L-AC15 Quoted commitment.** YOU locked at C8-S14 and never revised → STATED, the C8-S14 commitment; YOU reached
  by a renegotiation (from R2 or R3) → STATED, that scene's commitment; YOU withdrawn by a renegotiation from R1 →
  WITHDRAWN; Authority never YOU → NONE. *Blocked by:* Y2-PP-T17.
- **L-AC16 Saves.** A save in each storable phase (LEANING, PARTLY_LOCKED, DEFERRED, VALIDATED, FIXED, FINAL)
  reloads with the same `storyline_phase()`, `storyline_id()` and record, even after a knob is flipped; a save with
  no axis data loads LEANING with `load_errors()` empty; each damaged record of `storyline-axes.md` Edge Case 16
  gives a non-empty `load_errors()`. *Blocked by:* Y2-PP-T17, Y1-P1-T05.
- **L-AC17 Epilogue lines.** With the flags of arcs 05, 08 and 09 set, `epilogue_lines()` contains all three on
  every 1.0 storyline. *Blocked by:* Y2-PP-T17.
- **L-AC18 NG+ reset.** Starting NG+ from a FINAL record gives LEANING, every axis UNSET, `storyline_id()` empty and
  the reset fields at their defaults. *Blocked by:* Y2-PP-T17, NG+ design.

**Validation note:** the route bot of ROADMAP §12.4 starts from Chapter 8 fixture saves once the locks exist (owner
Y2-PP-T17): one run per valid row through C8-S16 (24), one Witness run through the deferral and C9-S19 (1), one per
renegotiation offer (16), one deferral-then-LAST_CHANCE invocation and one deferral-then-LAST_CHANCE renegotiation
(2), and the gate matrix of 3 paths × 6 storable phases (18) — 61 runs. A run passes when the observed
(`storyline_phase()`, `storyline_id()`) equals the expected pair.

## Open Questions

1. **Cost-beat texts:** the 16 `retract_*` beats and the two `deferral_*` beats are written by Y2-PP-T17; which
   companion answers each retraction (Nema on a NONE withdrawal, PM:7078-7087, is the obvious first) is decided
   there.
2. **Chapter 9 under a deferral:** only S5's two beats change in this contract; whether more Chapter 9 scenes react
   to Hearth's withheld endorsement is for Y2-PP-T17.
3. **Boss restart on re-entry** belongs to the combat system; this contract only says the stored ID is unchanged.
