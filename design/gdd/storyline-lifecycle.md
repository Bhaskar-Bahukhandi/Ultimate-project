# Storyline Lifecycle

> **Status**: Draft (revision 10: design review round 14 of `storyline-axes.md`, 2026-11-18 — a legacy save's
> position is derived from its free-travel story scene, its own scene or its chapter, and the scene-to-id map holds no
> hub; revision 9: design review round 13 of `storyline-axes.md`, 2026-11-17 — the NG+ reset sets the
> story position to `PRE_C8`, chapter select is keyed to its entry scene's position, a legacy save's position is
> derived once, `gate_open()` excludes a DAMAGED record, the knob-read scope points to the axes Tuning Knobs, L-AC14
> attribution fixed; revision 8: design review round 12 of `storyline-axes.md`, 2026-11-17 — the gate is one predicate
> on every scene change into Root of Heaven, chapter select past Chapter 8 writes a valid record, every checkpoint
> stores the story position, legacy saves are defaulted before the load check, L-AC19 added; revision 7: design
> review round 11, 2026-11-17 — C9-S18 plays its decrypted
> form when the First Wake leads are complete, the DAMAGED turn-back gets a dev assert and a reload prompt, L-AC8 gets
> the live-crisis cell; revision 6: design review round 10 — the gate gets a row for
> a live DAMAGED record, T6 is documented as defence in depth, L-AC8 matches what the reference model can set up;
> revision 5: Witness Protocol moved post-1.0 with the other secret routes; one commit-and-save rule for every
> transition)
> **Author**: Claude with the project lead
> **Last Updated**: 2026-11-18
> **Implements**: the invariants I1-I9 of `design/gdd/storyline-axes.md`; contract for Y2-PP-T17 (ending composer /
> route data model)
> **Implements Pillar**: P3, P5, P8 (through `storyline-axes.md`)

## Summary

The scenes and transitions that turn the three story axes into one stored storyline ID: the three lock scenes, the
red-line beat, the C8-S16 crisis and its renegotiations, the ID-lock gate on every path, and the final authorization.
`storyline-axes.md` owns the values, the formulas and the record; this document owns when each field is written,
which beats play, and when a save may exist. The secret routes (Witness Protocol, Crownless, First Wake) are post-1.0
(user decision 2026-11-11) and play no part in this contract beyond staying closed.

> **Quick reference** — Layer: `Foundation` · Priority: `Alpha` · Depends on: `storyline-axes.md`

## Overview

Chapter 8 locks Faction (C8-S13), Authority (C8-S14) and Deleted (C8-S16), in that order. A valid row is stored at
once. An invalid row breaks the coalition inside C8-S16, and the scene does not end until it holds again: the player
takes one of the refusing faction's demands, a renegotiation of one axis, and the withdrawn position is answered by
one authored beat. Every transition writes its fields and its beat as one atomic checkpoint, and no save exists
inside a transition. Every entry and re-entry into Root of Heaven runs one gate check, which only ever finds an ID
stored, the locks not yet played, or a live DAMAGED record (a defect, turned back as a data error, S6); a save made
past Chapter 8 before these fields existed is unsupported and does
not load; the final authorization only confirms. There is no state in which a player can be stranded, and no
transition back from a stored ID.

## Player Fantasy

- **A crisis is a negotiation, not an error.** The coalition breaks as "a political crisis rather than a menu error"
  (PM:723). The refusing faction speaks its terms; the player chooses which concession to make, and the concession
  is withdrawn on the record and answered by the person whose position it was (new content, the retraction beats).
- **The warning comes before the break.** One lock before a contradiction, the faction that would refuse says what
  it will not accept, as a value; the player can heed it or test it.
- **No dead ends.** Every unresolved state has a way out that the fiction states.

## Detailed Design

### Inputs and outputs

Reads and writes the composer input record of `storyline-axes.md` (fields `authority`, `faction`, `deleted`,
`storyline_id`, `root_phase`, `axis_revised`, `lock_negotiated`, `retraction_log`, `beats_played`, `story_position`) and the seed
flags. Every field is saved, so a reload restores the retractions and beats exactly. `storyline_phase` is derived
(`storyline-axes.md` Formulas), never stored. Knobs are read only where `storyline-axes.md` Tuning Knobs states (C8-S16,
the gate, and C9-S18's form).

### Scene contracts

**S1 — C8-S13 First Assembly Vote (Faction lock).** Offers all three Faction values as proposals; voices each set
Faction seed as an argument (value, sign); the vote passes for the backed value; `lock_pass` decides whether
`lock_negotiated` gains `faction`. Voices no red line. Plays only with every axis UNSET.

**S2 — C8-S14 Root Authority Hearing (Authority lock).** As S1 for Authority. Plays only with Faction set and
Authority UNSET. When YOU is backed, Kaelen states his commitment (PM:7045-7057); that is the commitment SOVEREIGN
quotes (PM:7059) unless it is later withdrawn.

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
2026-11-10; line ids `red_line_R1`, `red_line_R2`, `red_line_R3`). No line names a secret route or the institution
one needs: the routes are post-1.0 (revision 5 removes the R1 witness clause).

**S4 — C8-S16 Axis Three Lock and crisis.** Offers all three Deleted values. On a valid row it stores the ID (T3).
On an invalid row the refusing faction breaks the coalition, naming the combination for the first time
(PM:7138-7153), and the scene becomes the crisis (T4). The crisis cannot be left, skipped or saved until an offer
is taken (PM:7143, PM:7153). Its offers, each voiced as the refusing faction's demand:

| row | offers |
|---|---|
| R1 YOU-HEARTH-RESTORE | `revise:authority:SHARED`, `revise:authority:NONE`, `revise:faction:ARCHIVE`, `revise:faction:CONTINUITY`, `revise:deleted:RELEASE`, `revise:deleted:CHOOSE` |
| R2 NONE-ARCHIVE-RELEASE | `revise:authority:YOU`, `revise:authority:SHARED`, `revise:faction:HEARTH`, `revise:deleted:RESTORE`, `revise:deleted:CHOOSE` |
| R3 NONE-CONTINUITY-RELEASE | `revise:authority:YOU`, `revise:authority:SHARED`, `revise:faction:HEARTH`, `revise:deleted:RESTORE`, `revise:deleted:CHOOSE` |

A Faction offer replaces the refusing faction itself, so it is voiced as that faction stepping down as the
coalition's primary faction and staying in it, never as it demanding its own replacement ("Chosen faction is
primary not total winner.", PM:7409). The source's line that a secret route "may create alternative constitutional
mechanism later" (PM:7144) is not offered in 1.0.

**Commit and save rule (round 9; invariant I9 of `storyline-axes.md`).** Every transition of the table below that
ends a scene's open state (T1, T2, T3, T5, T7, T9) commits all of its effects — every field it writes and the id of the
beat it plays — together with an autosave, as one atomic checkpoint before that beat plays. No save exists between
the start of a scene that ends in such a transition and its commit: autosave and manual save are suppressed from the
start of C8-S13, C8-S14 and C8-S16 until the commit, and from the start of the final authorization until T9. A quit
or crash before the commit reloads the last save before the scene, and the scene replays from its start; a reload
from the checkpoint resumes at the start of the committed beat, and no offer or vote replays. T4 has no checkpoint of
its own: the crisis it opens is part of C8-S16, and its writes are committed with the T5 that closes it. So no save ever
holds a record that is half of a transition, and no save is positioned inside a lock scene. Every checkpoint also
stores the story position it reaches (`storyline-axes.md` Terms, Story position: the commit of C8-S13 writes
`S13_DONE`, and so on), and a save made anywhere else stores the last position it has crossed (Y1-P1-T05).

**Retractions.** A renegotiation withdraws Kaelen's superseded position on the record, and one authored cost beat
plays: a speaker other than Kaelen — the delegate or companion whose position is withdrawn — answers it (beat id
`retract_<rule>_<axis>_<new>`, e.g. `retract_R2_authority_YOU`; 16 beats, one per renegotiation offer, written by
Y2-PP-T17; the rule is part of the id because R2 and R3 share five offers with different speakers). The vote then
passes negotiated.

| axis | withdrawn on the record | source |
|---|---|---|
| Faction | what C8-S13 adopted: Hearth's mutual-defense charter, the Archive's public evidence charter, or the Continuity League's emergency operations network (a network, not a charter). Kaelen's interim role already ended at the Authority lock and is not withdrawn | PM:7003, PM:7010, PM:7021; roles end PM:7006, PM:7017, PM:7027 |
| Authority | Kaelen's C8-S14 position: YOU, his vow and chosen commitment; SHARED, the seven-signature protocol; NONE, the dismantling commitment | PM:7045-7057, PM:7064-7069, PM:7036-7038 |
| Deleted | the policy adopted at C8-S16: restore, release or choose | PM:7093-7095 |

When a renegotiation reaches YOU, Kaelen states his commitment in that scene, and that becomes the quoted one.

**S5 — Secret-route scenes in 1.0.** Every secret route is disabled (`storyline-axes.md` Tuning Knobs), so: C9-S18
keeps the source's condition: with every FIRSTWAKE offer prerequisite set it plays its decrypted form and ends with
the signal logged, not answered (`c9s18_logged`, new content), and otherwise the packet remains noise ("If
prerequisites incomplete packet remains noise.", PM:8043); either way it sets no flag and offers nothing; C9-S19
and C9-S20 do not play; no secret unlock flag (`SEVEN_WITNESSES_AVAILABLE`, `CROWNLESS_AVAILABLE`, `FIRST_WAKE_AVAILABLE`) is set;
C10-S13, C10-S14 and C10-S15 play only when the stored ID is their route's, which no 1.0 record holds. Secret
prerequisite flags that content sets are kept and transform nothing, and the journal shows no signpost for any route
(`storyline-axes.md` Edge Cases 2-3).

**S6 — The ID-lock gate.** Runs on every entry and re-entry into Root of Heaven, by each path: `story` (after the
Chapter 9 end, before PM:8206 "Root of Heaven gate opens"; the Chapter 10 scene chain and chapter select count as
this path), `world_map` (world map or free travel, including "Resume story" and the free-travel Root of Heaven
region; protected logic, needs the user's approval when implemented) and `load` (a save positioned inside Root of
Heaven). The check is one predicate, not a list of callers (design review round 12): it runs before every scene
change whose target is a Root of Heaven scene, whoever requests it; on load, before any loaded state is applied; and
before free travel unlocks the Root of Heaven region, which stays locked until the predicate passes. A new caller
therefore cannot skip it, and setting a chapter-unlock flag alone never opens the gate. The stored-ID
check is necessary, not sufficient: the story path reaches the gate only after the Chapter 9 end, and the world-map
path only once Root of Heaven is on the map. Outcome by phase:

| phase | outcome |
|---|---|
| LEANING, PARTLY_LOCKED | TURNED_BACK: the Assembly has not decided |
| DAMAGED (a live record) | TURNED_BACK: a data error, no transition; a dev build asserts; the player sees a system-voice prompt (not the Assembly line) to reload the last save that passes the load check |
| VALIDATED | ROOT_OF_HEAVEN; `root_phase` becomes INSIDE (T7) |
| FIXED, FINAL | ROOT_OF_HEAVEN; nothing changes (T8) |

The `load` path never meets LEANING, PARTLY_LOCKED or DAMAGED: a save positioned inside Root of Heaven with an UNSET
axis is past Chapter 8 and is refused on load (`storyline-axes.md` Edge Case 16, D16). Neither does the `story` path
in play: Root of Heaven is entered only after the Chapter 9 end, so every record at the gate is positioned past C8-S16
and, with an UNSET axis, is DAMAGED (D16 applies to a live record too), not LEANING or PARTLY_LOCKED. T6 and the
DAMAGED row are therefore defence in depth against a story-graph defect that FlagRegistry's boot check should
already have caught; the reference model's walk never fires T6. They are kept so the gate has an outcome for every
phase (invariant I5) and for the source's "intercepted before final boss" (PM:11305). CRISIS never reaches the
gate: `storyline_phase` returns it only for a live record inside C8-S16 before its commit (`live_crisis`), and a
live invalid-row record with nothing stored anywhere else reads DAMAGED (`storyline-axes.md` Open Question 18). The
DAMAGED turn-back repairs nothing: the last save that passes the load check is before C8-S16 (I9), so reloading
replays the lock scenes; the gate check runs as a predicate before the scene change, never from Root of Heaven's
own scene. A VALIDATED save positioned inside Root of Heaven cannot be written by play (T7
is atomic) but loads, and the load-path gate then runs T7.

**Legacy saves (user decision 2026-11-10).** There is no runtime catch-up. A save positioned past a lock scene with
that axis UNSET (any save made past Chapter 8 before these fields exist) is unsupported: the load check reports it
(`storyline-axes.md` Edge Case 16, D16) and the load is refused. This holds only while no player-facing build has
such saves; if one ships before these fields do, the decision is reopened. The project's own fixture saves past
Chapter 8 are rewritten once by a dev-fixture migration, a tool script that is not shipped and is not part of this
state machine (owner Y2-PP-T17 with Y1-P1-T05): the test author gives each fixture explicit axis values and an ID
consistent with the branch flags it already holds. The legacy storyline flags the code sets today are superseded,
not migrated (Dependencies). A save of a schema version before these fields has its whole record block filled with
the defaults before the load check runs (`storyline-axes.md` Edge Case 8), so the check meets a typed record: at
`PRE_C8` it loads LEANING, and past a lock scene D16 refuses it. Such a save holds no story position, so the
defaulting step derives it once, by the order in `storyline-axes.md` Terms (Story position): the free-travel story
scene, else the save's own scene, through the scene-to-id map, which holds no hub; else the chapter number. A
Chapter 8 save that no story scene places is left with no position, which D0 refuses (`D0.missing`).

**Chapter select (user decisions 2026-11-17, design review rounds 12 and 13).** Chapter select is player-facing. It
starts a new record, never edits a loaded one, and each entry is keyed to the story position of its entry scene, not
to its chapter number (round 13: "Chapter 8 - Ending", `main_menu.gd:655-662`, is a Chapter 8 entry whose
`ch8_ending` comes after the locks and autosaves on load). An entry positioned before C8-S13 starts LEANING with the
defaults (position `PRE_C8`). An entry positioned past C8-S16's commit writes, as
one atomic checkpoint before its entry scene loads, a fixed valid record: `SL-SHARED-ARCHIVE-CHOOSE` (SHARED, ARCHIVE, CHOOSE; SHARED
and CHOOSE appear in no invalid row), `lock_negotiated` = {faction, authority, deleted} (no lock vote was
played, so none passed clean), `axis_revised`, `retraction_log` and `beats_played` empty, `root_phase` OUTSIDE, the
matching `AXIS*` and `lock_negotiated_*` mirror flags, and the story position of its entry scene (`S16_DONE` for a
Chapter 8 entry after the locks, `CH9` for Chapter 9 and for every entry into Root of Heaven). An entry into Root of
Heaven then enters through the gate (T7). No entry is positioned inside the lock scenes (`S13_OPEN` to `S16_OPEN`).
So chapter select never writes a save the load check refuses, and its ending is
BOUND without `sole_dissent`. Changing chapter select is protected story progression: the implementing story needs the
user's approval.

**S7 — Final authorization (PM:8786-8794).** After the boss: displays the stored structure, offers no
reconsideration, and `confirm_execution` sets `root_phase` FINAL (T9); nothing else changes. Before the confirm,
Kaelen says his three route lines ("If player maintains route", PM:8795, always holds): Authority (PM:8797-8799),
Deleted (PM:8800-8802) and Faction (PM:8803-8805).

### Content scope and cut order

Authored content this contract asks of Y2-PP-T17 beyond the source scenes:

| content | count | plays on |
|---|---|---|
| retraction beats `retract_*` | 16 | every renegotiation at C8-S16 |
| red lines | 3 | C8-S15 |
| `sole_dissent` | 1 | a SOLE ending after a negotiated Authority vote |
| `c9s18_logged` | 1 | C9-S18 with every FIRSTWAKE offer prerequisite set |
| arc epilogue lines | 3 | arcs 05, 08, 09 |

Cut order, first cut first. A cut never removes an invariant, a transition, a record field or an id: it replaces
authored text with shared text behind the same ids, so the content-completeness criterion (L-AC16) still holds.
1. Retraction beats → one shared text per (axis, new value) behind the 16 ids (R2 and R3 then share five texts).

**Producer sign-off:** required before Y2-PP-T17 is scheduled, on this reduced scope; not given by this revision.

### States and Transitions

The phases are `storyline-axes.md`'s phase table. Transitions:

| # | from | event | guard | to | effects |
|---|---|---|---|---|---|
| T1 | LEANING | C8-S13 resolves | — | PARTLY_LOCKED | faction set; `lock_negotiated` per `lock_pass`; checkpoint |
| T2 | PARTLY_LOCKED | C8-S14 resolves | faction set, authority UNSET | PARTLY_LOCKED | authority set; `lock_negotiated` per `lock_pass`; checkpoint |
| T3 | PARTLY_LOCKED | C8-S16 resolves | faction and authority set; the row is valid | VALIDATED | deleted set; `lock_negotiated` per `lock_pass`; ID stored; checkpoint |
| T4 | PARTLY_LOCKED | C8-S16 resolves | faction and authority set; the row is invalid | CRISIS | deleted set; `lock_negotiated` per `lock_pass`; the refusing faction breaks the coalition; no checkpoint |
| T5 | CRISIS | a renegotiation is taken | the offer is in the row's offer set | VALIDATED | the axis changed; `axis_revised`, `lock_negotiated` gain it; retraction recorded; retraction beat played; ID stored; checkpoint |
| T6 | LEANING or PARTLY_LOCKED | Root of Heaven entry, any path | — | unchanged | TURNED_BACK |
| T7 | VALIDATED | Root of Heaven entry, any path | — | FIXED | `root_phase` INSIDE; checkpoint |
| T8 | FIXED or FINAL | Root of Heaven entry, any path | — | unchanged | open |
| T9 | FIXED | execution confirmed | the final authorization scene is playing | FINAL | `root_phase` FINAL; checkpoint |

No other transition exists: nothing leads from VALIDATED, FIXED or FINAL to an earlier phase or to CRISIS — not a
knob change, not a flag, not loading. The story graph never starts C8-S14 before C8-S13 resolves or C8-S16 before
C8-S14 resolves; a graph that could break that order is a data error FlagRegistry reports at boot (Y1-P1-T03).
Loading restores the record, runs the damaged-record check (a DAMAGED record does not load), and derives the phase; it
fires no transition by itself, and a save positioned inside Root of Heaven then runs the gate check (T6-T8) as its
entry.

**NG+ reset** (until NG+ design decides carry-over): `authority`, `faction`, `deleted` → UNSET; `storyline_id` →
empty; `root_phase` → OUTSIDE; `axis_revised`, `lock_negotiated`, `retraction_log`, `beats_played` → empty;
`story_position` → PRE_C8. The story position is reset with the record because a new record left at a Story+ position
would be refused by D16 (design review round 13). The
`AXIS*`, `axis_revised_*` and `lock_negotiated_*` flags and the secret routes' prerequisite and unlock flags are
cleared with the record; the Act 1 seed flags follow NG+'s own flag reset. NG+ starts a new record, not a
transition of this table: the previous cycle's record is kept for Story+ under its own ID (PM:11300, PM:11303);
where it is kept and how it is load-checked is Open Question 5.

## Formulas

```
crisis_offers(row) = {} if row is not R1, R2 or R3; otherwise
                     { "revise:" + axis + ":" + v : axis locked, v ≠ row[axis], not invalid(row with axis = v) }
signpost(T)        = HIDDEN while T is disabled (every secret route in 1.0)
```

`invalid` and the row notation are `storyline-axes.md`'s. Counts: |crisis_offers| is 6 for R1 and 5 for R2 and R3,
so 16 renegotiation offers in all; |crisis_offers| is 0 for every valid row. The OPEN and CLOSED signpost states, and
when a route's invocation is offered, belong to the post-1.0 secret-route design (`storyline-axes.md` Open Question
15).

## Edge Cases

1. **Crash or quit inside a lock scene or the crisis.** Before the commit no save exists, so the player reloads the
   last save before the scene and it replays from its start; after the commit, the checkpoint resumes at the start of
   the committed beat and the offer never replays (commit and save rule).
2. **Leaving Root of Heaven mid-boss and re-entering.** FIXED → T8: open, nothing changes; the boss restarts per the
   combat system.
3. **Story+ re-entry after execution.** FINAL → T8: open.
4. **A save made past Chapter 8 before these fields existed.** The load is refused (`storyline-axes.md` Edge Case
   16, D16) and the player returns to the load menu; no lock scene replays.
5. **Every Witness lead found in 1.0.** `WITNESS_PROTOCOL_FOUND`, `OLD_WITNESS_SIGNATURE` and `WITNESS_SEATS` stay
   set; C9-S19 does not play, no unlock flag is set, the signpost stays HIDDEN, and R1 at C8-S16 offers only its six
   renegotiations (S5).
6. **A crash between two writes of one transition.** Not possible: the transition's writes and its beat id are one
   atomic checkpoint, so a save holds the record before the transition or after it, never between (I9).

## Dependencies

| System | Direction | What flows | Status |
|---|---|---|---|
| Storyline axes (`design/gdd/storyline-axes.md`) | this ← axes | values, formulas, record, invariants I1-I9, knobs | revision 14 |
| SaveService (Y1-P1-T05) | this → save | record writes, including `retraction_log` and `beats_played`; save suppression inside lock scenes, the crisis and the final authorization; one atomic checkpoint per transition; the damaged-record check and load refusal | no GDD |
| FlagRegistry / StoryGraph (Y1-P1-T03) | this ← registry | flags; scene order check at boot; the story position for Edge Case 16 D16-D17 | no GDD |
| World map / free travel (protected) | this → world map | the gate check on the `world_map` path | no GDD — needs the user's approval when implemented |
| Ending composer (Y2-PP-T17) | this → composer | retractions, beats played, `sole_dissent`, the epilogue lines | not designed |
| Combat / boss (Root of Heaven) | this → boss | the re-entry rule | no GDD — combat is protected |
| Legacy storyline flags (protected: story progression, true ending, NG+) | superseded by this contract | `ch8_revolt_led`, `ch8_council_formed`, `ch8_witness_network_created`, `ending_route_ch8_lead`, `ending_route_ch8_council`, `ending_route_ch8_witness` (set in `AethelgardPrototype/scripts/chapter8/ch8_revolt_crisis.gd:114-128`); `ch10_destroy_sovereign`, `ch10_rewrite_sovereign` (`AethelgardPrototype/scripts/chapter10/ch10_sovereign_confrontation.gd:224-228`); `true_ending_seen`, `ng_plus_unlocked` (`AethelgardPrototype/scripts/chapter10/ch10_ending.gd:15-16`); all declared in `AethelgardPrototype/scripts/game_manager.gd:371-401` | not migrated; retirement owned by Y1-P1-T03 and needs the user's explicit approval |

Bidirectional rule: `storyline-axes.md` names this document in its Dependencies; each doc above written later must
too. The protected areas this contract touches are listed in `storyline-axes.md` Dependencies.

## Tuning Knobs

None of its own. It reads `secret_route_enabled` from `storyline-axes.md`, only at C8-S16 and the gate. Not knobs:
the scene order, the offer sets (derived from `invalid`), the commit and save rule, the rule that C8-S16 cannot be
left with a crisis open, and the rule that a stored ID never changes.

## Acceptance Criteria

**Document-level — document lint, checked by `production/qa/evidence/2026-11-storyline/check_storyline_axes.py`:**
the transition table has rows T1-T9 exactly as pinned (from, guard, to, effects); every from/to value is a phase of
`storyline-axes.md`; the crisis offer table equals `crisis_offers` computed from `invalid()` for R1-R3; the red-line
table names exactly R1-R3 with their pairs; every L-AC below names its blocking stories and uses only observables from
the table below. Lint shows the text matches its pins; it is not evidence that the state machine is correct
(`storyline-axes.md` Acceptance Criteria).

**Scene-level observables** — every one returns the stated value outside its scene:

| observable | returns | outside its scene |
|---|---|---|
| `storyline_phase()` | the derived phase of the current record (`loaded` false; after a load that passed the check the value is the same either way) | — |
| `storyline_id()` | the stored ID | empty string when nothing is stored |
| `axis(name)` | the record's `authority`, `faction` or `deleted` | — |
| `gate_open()` | true exactly when an ID is stored and the phase is not DAMAGED (the gate check passes; the path to the gate is story progression) | — |
| `enter_root_of_heaven(path)` | for path `story`, `world_map` or `load`: ROOT_OF_HEAVEN or TURNED_BACK | — |
| `current_scene()` | the id of the playing scene, or `load_menu` | — |
| `current_beat()` | the id of the authored beat playing and whether it is at its start | empty |
| `lock_options(axis)` | in that axis's lock scene, the values offered | empty |
| `lock_arguments(axis)` | in that axis's lock scene, the (flag, value, sign) arguments voiced | empty |
| `red_lines_voiced(scene)` | the rule ids voiced the last time that scene played | empty if it never played |
| `offers()` | in the C8-S16 crisis: the current offer set | empty in every other scene |
| `take(offer)` | true if the offer is in `offers()` and was taken; otherwise false and nothing changes | false |
| `record_hash()` | a hash over every stored field of the record | — |
| `try_save()` | requests a save now: true if a save file was written, false if saving is suppressed | — |
| `retraction_log()` | the saved `retraction_log`: every retraction as {axis, old, new, withdrawn_item, scene}, oldest first | — |
| `beats_played()` | the saved `beats_played`: the authored beat ids played (`retract_*`) | — |
| `beat_text(id)` | the route data's text for a beat, line or module id | empty for an unknown id |
| `beat_speaker(id)` | the route data's speaker for that id | empty for an unknown id |
| `signpost(route)` | HIDDEN (Formulas) | — |
| `quoted_commitment()` | the commitment SOVEREIGN quotes and its status: STATED or WITHDRAWN | NONE if Authority was never YOU |
| `route_lines()` | in the final authorization, the source line ids Kaelen says | empty |
| `ending_modules()` | the ending module ids the composer selected for the current record | — |
| `confirm_execution()` | in the final authorization: confirms, returns true | false |
| `load_errors()` | the data errors found by the last load | empty |
| `save_bytes(slot)` | the bytes of a save slot | — |
| `epilogue_lines()` | the arc ids that get an epilogue line | — |
| `record_field(name)` | the current value of a stored record field (`lock_negotiated`, `axis_revised`, `root_phase`) | — |
| `flag_set(name)` | whether the named story flag is set | — |

"Nothing is offered" is tested as: `take()` of each of the 16 renegotiation offer strings is false and
`record_hash()` is unchanged.

**Runtime criteria:**

- **L-AC1 Lock order and options.** For each axis `lock_options(axis)` is all three values with no seed set and with
  one seed per exclusive group set; from a record with Faction UNSET, C8-S14 never becomes `current_scene()`; with
  Authority UNSET, C8-S16 never does. *Blocked by:* Y2-PP-T17, Y1-P1-T03.
- **L-AC2 Arguments and lock pass.** `lock_arguments(axis)` is exactly the set axis seeds of that axis with value and
  sign. Faction backing HEARTH, five fixtures: no seed → `record_field(lock_negotiated)` contains faction;
  `act1_report_local` → not; `act1_report_local` + `ch1_knight_killed` → contains; only `ch1_knight_killed` →
  contains; only `act1_report_archive` (a `+` seed for another value) → contains. In each, `axis(faction)` is HEARTH
  afterwards, whatever seeds are set. Authority and Deleted, three fixtures each: no seed → contains; one `+` seed for
  the backed value → not; one `+` seed for another value only → contains. Each result survives a save and reload.
  *Blocked by:* Y2-PP-T17, Y1-P1-T03, Y1-P1-T05.
- **L-AC3 Red lines.** `red_lines_voiced(C8-S13)` and `(C8-S14)` are empty; `(C8-S15)` is {R1} after YOU + HEARTH,
  {R2} after NONE + ARCHIVE, {R3} after NONE + CONTINUITY and empty for each of the other six pairs;
  `(C8-S16)` is the row's rule on each invalid row and empty on a valid row; `beat_text(red_line_R1)` names no secret
  route. *Blocked by:* Y2-PP-T17.
- **L-AC4 Valid at C8-S16.** For each of the 24 valid rows: after C8-S16, `storyline_phase()` VALIDATED,
  `storyline_id()` the row's ID, `gate_open()` true, `beats_played()` with no `retract_*` beat. *Blocked by:*
  Y2-PP-T17.
- **L-AC5 Crisis offers.** On each invalid row, inside C8-S16, `offers()` equals the crisis offer table's set, with
  every secret prerequisite flag set and with none. *Blocked by:* Y2-PP-T17.
- **L-AC6 Commit and save rule.** For each record-writing transition (T1, T2, T3, T5, T7, T9): from the start of its
  scene until its commit `try_save()` is false and `current_scene()` stays that scene; a quit before the commit and a
  reload give the `record_hash()` of the last save before the scene and `current_scene()` its start; after the commit
  a checkpoint exists, and reloading it gives the committed `record_hash()`, `current_beat()` the committed beat at
  its start, and `take()` of every offer of that row false. For T5 the crisis (T4) is inside the window: `try_save()`
  is false throughout. *Blocked by:* Y2-PP-T17, Y1-P1-T05.
- **L-AC7 Renegotiation.** From each invalid-row fixture with `record_field(lock_negotiated)` and
  `record_field(axis_revised)` empty, for each of its offers (16 runs): `take()` true; `storyline_phase()`
  VALIDATED; `storyline_id()` the new row's ID; `axis(name)` the new value and the other two axes unchanged;
  `record_field(axis_revised)` and `record_field(lock_negotiated)` contain the axis; the last `retraction_log()` entry
  has the axis, old and new values, the table's withdrawn item and scene C8-S16; `beats_played()` gains
  `retract_<rule>_<axis>_<new>`, and the 16 runs yield 16 distinct beat ids. `take()` of a value not offered (the same
  value; the other invalid row) is false and `record_hash()` is unchanged. *Blocked by:* Y2-PP-T17.
- **L-AC8 The gate.** For the `story` and `load` paths and each storable phase (LEANING, PARTLY_LOCKED, VALIDATED,
  FIXED, FINAL): LEANING and PARTLY_LOCKED on the `story` path → TURNED_BACK; on the `load` path the load is refused
  with `load_errors()` naming D16 and no gate entry; VALIDATED → ROOT_OF_HEAVEN and FIXED; FIXED and FINAL →
  ROOT_OF_HEAVEN, phase unchanged. The `story` cells of LEANING and PARTLY_LOCKED are impossible in play and cannot
  come from a fixture save (a save positioned past C8-S16 with an UNSET axis is refused on load, D16, and a live one
  reads DAMAGED): they run on a live record that the test injects at the gate, and are reported as synthetic. The
  same injection with a live DAMAGED record → TURNED_BACK, `record_hash()` unchanged and a data error logged. The
  LEANING and PARTLY_LOCKED cells inject the record before C8-S16; injected past it, an UNSET axis reads DAMAGED
  (D16) and the DAMAGED case applies. A live invalid-row record with nothing stored, injected past C8-S16 (in
  Chapter 9), reads DAMAGED with `load_check` {D9} and gives TURNED_BACK, `record_hash()` unchanged and a data error
  naming D9, not a gate error (synthetic, outside the 10 counted cells). A VALIDATED fixture save positioned inside Root of Heaven loads, and the load-path gate gives ROOT_OF_HEAVEN and
  FIXED. The `world_map` path repeats the `story` cells once the protected world-map change is approved.
  *Blocked by:* Y2-PP-T17, Y1-P1-T03, Y1-P1-T05.
- **L-AC9 Held to its word.** From VALIDATED records reached by T3 and T5 and from FIXED and FINAL records: at the gate
  on the `story` and `load` paths, `take()` of each of the 16 renegotiation offers is false with `record_hash()`
  unchanged, and `enter_root_of_heaven()` is ROOT_OF_HEAVEN; after setting every secret prerequisite flag and flipping
  every knob, `storyline_id()` and `storyline_phase()` are unchanged. *Blocked by:* Y2-PP-T17.
- **L-AC10 Secret routes closed.** With every secret prerequisite flag set and the default knobs: through Chapter 9
  and 10 on one record per family, C9-S19, C9-S20, C10-S13, C10-S14 and C10-S15 never become `current_scene()`,
  C9-S18 plays `c9s18_logged` (and, on a second record with one FIRSTWAKE prerequisite unset, its noise form), `flag_set()` is false for `SEVEN_WITNESSES_AVAILABLE`, `CROWNLESS_AVAILABLE` and
  `FIRST_WAKE_AVAILABLE`, and `signpost()` is HIDDEN for all three routes. *Blocked by:* Y2-PP-T17, Y1-P1-T03.
- **L-AC11 Final authorization.** In FIXED after the boss: `take()` of each renegotiation offer is false with
  `record_hash()` unchanged; `route_lines()` is the stored row's Authority, Deleted and Faction lines
  (PM:8797-8805); `confirm_execution()` gives FINAL with `storyline_id()` unchanged. `confirm_execution()` anywhere
  else is false with `record_hash()` unchanged. *Blocked by:* Y2-PP-T17.
- **L-AC12 Quoted commitment.** YOU locked at C8-S14 and never revised → STATED, the C8-S14 commitment; YOU reached
  by a renegotiation (from R2 or R3) → STATED, that scene's commitment; YOU withdrawn by a renegotiation from R1
  (`revise:authority:SHARED`, `revise:authority:NONE`) → WITHDRAWN; YOU kept through any other R1 renegotiation
  (Faction or Deleted) → STATED, the C8-S14 commitment; Authority never YOU → NONE. *Blocked by:* Y2-PP-T17.
- **L-AC13 Saves.** A save in each storable phase (LEANING, PARTLY_LOCKED, VALIDATED, FIXED, FINAL) reloads with the
  same `storyline_phase()`, `storyline_id()`, `retraction_log()`, `beats_played()` and `record_hash()`, with
  `load_errors()` empty, even after a knob is flipped; a save with no axis data positioned before C8-S13 loads LEANING
  with `load_errors()` empty; each damaged-record fixture of `storyline-axes.md` AC9 gives `load_errors()` exactly its
  item, the load is refused (`current_scene()` stays `load_menu`), and `save_bytes()` of its slot is unchanged.
  *Blocked by:* Y2-PP-T17, Y1-P1-T05.
- **L-AC14 Epilogue lines.** With the completion flags of arcs 05, 08 and 09 set — `CROWN_COORDINATES` (arc 08,
  PM:3683), arc 09's flag and arc 05's Quest 30 flag — `epilogue_lines()` contains all three arcs on every 1.0
  storyline, and contains none of them with no flag set. The sources name neither arc 05's flag (PM:2690-2691) nor
  arc 09's: `OLD_HOME_MESSAGE` is set in the Chapter 3 End ledger (PM:3814), not by arc 09's own quests
  (PM:3685-3707), so it would mark a player who never finished the arc; Y2-PP-T17 names both flags before this runs.
  *Blocked by:* Y2-PP-T17.
- **L-AC15 NG+ reset.** Starting NG+ from a FINAL record positioned at `STORY_PLUS` gives LEANING, every axis UNSET,
  `storyline_id()` empty, the reset fields at their defaults, the story position `PRE_C8`, `load_errors()` empty for
  the first save of the new cycle, and `flag_set()` false for every secret prerequisite and unlock flag.
  *Blocked by:* Y2-PP-T17.
- **L-AC16 Content completeness.** For every id this contract defines — the 16 `retract_*`, `red_line_R1`,
  `red_line_R2`, `red_line_R3`, `sole_dissent`, `c9s18_logged` — `beat_text(id)` and `beat_speaker(id)` are non-empty and the text is
  not the route data's placeholder token; texts are pairwise distinct except where the cut order shares them; for
  every `retract_*` id `beat_speaker(id)` is not Kaelen. *Blocked by:* Y2-PP-T17.
- **L-AC17 Unsupported legacy saves.** A save with no axis data positioned in Chapter 9, and one positioned inside
  Root of Heaven: on load `load_errors()` names D16, `current_scene()` stays `load_menu`, and no lock scene plays.
  *Blocked by:* Y2-PP-T17, Y1-P1-T03, Y1-P1-T05.
- **L-AC18 Visual and UI evidence.** These beats and screens are player-observable (Visual/Feel and UI, BLOCKING in
  the project's Testing Standards): one retained live Godot viewport screenshot each (not a headless or dummy-renderer
  capture) in `production/qa/evidence/`, with lead sign-off
  recorded beside them (narrative-director for beats and lines, ux-designer for screens). The items are each lock
  scene with at least one voiced argument; the C8-S15 red line on R1, R2 and R3; the C8-S16 crisis screen for each
  invalid row; one retraction beat per axis; the final authorization; one ending per family (SOLE, BOUND, NONE_AUTH)
  and `sole_dissent`; one Story+ screen per family; the three arc epilogue lines; C9-S18's logged form; and the S6
  turn-back prompt for a live DAMAGED record (from an injected record in a dev build). *Blocked by:* Y2-PP-T17.

- **L-AC19 Gate predicate and chapter select.** For each scene-change request whose target is a Root of Heaven
  scene, issued from the Chapter 9 end, the Chapter 10 scene chain, world-map "Resume story", free travel and chapter
  select, with a LEANING or PARTLY_LOCKED injected live record: `enter_root_of_heaven()` is TURNED_BACK and
  `current_scene()` is not a Root of Heaven scene; with `ch10_unlocked` set and no ID stored, the free-travel Root of
  Heaven region stays locked. Chapter select of Chapter 9 and of Chapter 10 from the main menu gives
  `storyline_id()` `SL-SHARED-ARCHIVE-CHOOSE`, `record_field(lock_negotiated)` = {faction, authority, deleted} and
  `load_errors()` empty for every save written before the first player input; for Chapter 10 the gate gives
  ROOT_OF_HEAVEN. "Chapter 8 - Ending" gives the same record at `S16_DONE` with `load_errors()` empty for its
  autosave. A chapter-select entry positioned before C8-S13 gives LEANING. *Blocked by:* Y2-PP-T17, Y1-P1-T05,
  Y1-P1-T03.

**Validation note:** the route bot of ROADMAP §12.4 starts from Chapter 8 fixture saves once the locks exist (owner
Y2-PP-T17): one run per valid row through C8-S16 (24), one per renegotiation offer at C8-S16 (16), and the gate
matrix of 2 counted paths × 5 storable phases (10) — 50 runs. The `world_map` path's 5 cells run the same way once
the protected world-map change is approved; until then they are blocked and not counted. Pass rule: every run other
than a gate-matrix cell ends with one `story`-path gate entry from its own record (the bot may skip from its last
scripted scene to the Chapter 9 end with the record unchanged) and passes when the observed `storyline_phase()` after
that entry, `storyline_id()` and `enter_root_of_heaven()` outcome equal the expected triple. A gate-matrix cell
passes on the same triple from its fixture, except the `load` cells of LEANING and PARTLY_LOCKED, which pass when the
load is refused with `load_errors()` naming D16 and no gate entry happens. Cells impossible in play (the `story`
cells of LEANING and PARTLY_LOCKED) run on an injected live record, count, and are listed as synthetic in the run
report; the live-DAMAGED and VALIDATED-on-load checks of L-AC8 are unit-level, outside the 10 counted cells. The bot is a smoke check of the phase, the
ID and the gate; the retractions, beats and saves are evidenced by L-AC6, L-AC7 and L-AC13 to L-AC18.

## Open Questions

1. **Beat texts:** the 16 `retract_*` beats are written by Y2-PP-T17; which companion answers each retraction (Nema
   on a NONE withdrawal, PM:7078-7087, is the obvious first) is decided there.
2. **Boss restart on re-entry** belongs to the combat system; this contract only says the stored ID is unchanged.
3. **Route-specific final-authorization lines:** S7 uses the per-axis lines of PM:8797-8805; each route-matrix entry
   also has its own "Final authorization line" (e.g. PM:8990). Which one Kaelen says, or both, is for Y2-PP-T17.
4. **Round-2 recommendations still open:** offers voiced as the faction conceding or brokered (PM:7102-7106, 7141);
   context for `retract_R1_*`.
5. **NG+ previous record:** where the previous cycle's record is kept for Story+, and whether the load check runs on
   it, is for the NG+ design (with Y1-P1-T05).
6. **Secret routes post-1.0:** the deferral, invocation, witness vote, stand-down and Consent variants of revision 4
   are removed, not deferred as written; the post-1.0 design starts from `storyline-axes.md` Open Question 15 (the
   revision-4 text is in git at commit 084ccb0).
