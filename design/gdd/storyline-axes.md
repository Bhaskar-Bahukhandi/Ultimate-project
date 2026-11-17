# Storyline Axes

> **Status**: Draft (revision 10, after design review round 10 against the reference model: Edge Case 16 items marked
> load-only or live, AC9 and the gate reconciled with the model, the load-check promise narrowed; static core
> unchanged since revision 4 except the 1.0 scope of the secret storylines)
> **Author**: Claude (narrative-director research) with the project lead
> **Last Updated**: 2026-11-17
> **Last Verified**: 2026-11-11
> **Implements Pillar**: P3 (24 storylines + 3 secret from three story axes), P5 (side storylines feed the main
> story), P8 (Story+, a playable after-story per storyline) — DESIGN_PILLARS.md, ROADMAP §12.2

## Summary

Three story axes — who holds Root (Authority), which society Kaelen backs (Faction), and what happens to the
deleted (Deleted) — combine into 27 configurations; 24 are valid storylines, 3 are contradictions that only a
secret route can transform. The secret routes are post-1.0, so 1.0 ships the 24 and every contradiction is
renegotiated. Ending families carry the depth (three in 1.0, a fourth with the secret routes); Faction and Deleted
modify them. Every save
tracks one stable storyline ID, stored the moment the coalition holds and required at the entry to Root of Heaven;
the ending composer builds the ending from that ID plus companions, regions and timing. This GDD owns the static
model and the invariants; `design/gdd/storyline-lifecycle.md` owns the scenes and transitions that keep them.

> **Quick reference** — Layer: `Foundation` · Priority: `Alpha`

## Overview

Aethelgard's main story does not branch into 27 separately written routes. In Chapter 8, Kaelen's choices lock
three axes: **Authority** (Kaelen alone, shared and auditable, or abolished), **Faction** (Hearth Compact, Archive
Covenant or Continuity League) and **the Deleted** (restore them, release them, or let each person choose). The
three locked values name one of 24 valid storylines (`SL-AUTHORITY-FACTION-DELETED`); three combinations break the
coalition (PM:710-723). A broken coalition is a political crisis that resolves inside the scene where it breaks,
C8-S16: the player renegotiates one axis ("Player must change one axis before final lock.", PM:7143). The three
secret routes that can transform an invalid row — Witness Protocol, Crownless and First Wake — are post-1.0 and will
be designed together as one mechanism (user decision 2026-11-11). The storyline ID is stored the moment the
coalition holds, and the **ID-lock gate** at Root of Heaven stays closed until it is. After the boss, the **final
authorization** (PM:8786-8794) displays the stored structure and the player confirms it; nothing changes it there.
The Authority value picks one of three ending families in 1.0 (Sole, Bound, No Authority; Consent follows with
Witness Protocol), each with its own God King phase, final scene and Story+ arc; Faction and Deleted change a boss
phase, ally lines, epilogue slides and which Story+ cases unlock. Act 1 flags seed the arguments each lock scene
voices and record whether a lock vote passed clean or by negotiation; in 1.0 only a Sole ending makes that record
audible (Core Rule 3). Nine of the twelve side storylines are to push the axes in 1.0 once Y2-PP-T17 maps their
flags (AC15; the seed map holds none yet; arcs 05, 08 and 09 feed post-1.0 routes), and timing changes scenes and
slides without ever changing the storyline ID — so authored cost stays additive.

## Player Fantasy

The player holds a key that could rewrite the world, and the game keeps asking whether they have the right to turn
it (Story Bible §1: "Capability is not legitimacy"). The axes are how that question becomes theirs: not a morality
meter, but three answers they build up through what Kaelen does — who he lets hold Root, whose society he stands
with, and whether the deleted are brought back, let go, or asked.

- **Authorship, not a menu.** Each lock is a vote between proposals, never a picker of labels ("Options are
  proposals not Kaelen menu labels", PM:6983), and the scene argues with the player's own history: the Act 1
  choices they may not have read as political come back as the arguments for and against each proposal, so the
  storyline at the end feels arrived at. In 1.0 only the mapped Act 1 flags voice arguments; side-storyline and
  companion seeds join once Y2-PP-T17 maps them (AC15). Whether a vote passed clean or by negotiation is
  recorded, but the lock scene plays the same either way. In 1.0 the player hears the difference in exactly one
  place: a player who keeps Root alone after a negotiated Authority vote hears the Assembly members who never
  endorsed it named in the Sole ending (`sole_dissent`); no other 1.0 content reads it.
- **Costs are real.** Every valid storyline loses something (its route's "Primary danger"); the three invalid
  combinations are where a coalition refuses to follow. In the last hearing, the faction a choice would break says
  what it will not accept — as a value, not a formula; the coalition breaks in Chapter 8 instead of failing
  silently at the ending screen (PM:7153), and a renegotiation is withdrawn on the record and answered by one
  authored beat.
- **Nobody is forced to agree.** Companions stay possible on every storyline (PM:11302); they argue, they do not
  vanish because the player picked a faction.
- **The world goes on without a perfect answer.** The ending family (who authorized the change) carries the weight;
  Faction and Deleted colour what that authority built; Story+ lets the player walk around in the result.
- **Hidden doors (post-1.0).** When the secret routes ship, a route appears only after its first prerequisite is
  found and is signposted by the institution it needs, never by the answer (PM:697-707). 1.0 shows no hint of a
  door it does not ship, and what the player did on the arcs that feed one is acknowledged in an epilogue line
  (ROADMAP §12.2 "nothing important is lost silently").

## Detailed Design

### Terms

- **Lock scene**: the scene that sets one axis — Faction: C8-S13 First Assembly Vote (PM:6980-7027); Authority:
  C8-S14 Root Authority Hearing (PM:7029-7087); Deleted: the C8-S15 hearings (PM:7089-7132) end in C8-S16 Axis
  Three Lock (PM:7134-7137). The source runs them in this order, and the lifecycle enforces it.
- **Clean / negotiated**: how a lock vote passes (Core Rule 3).
- **Crisis scene**: C8-S16 when the third lock completes an invalid row (PM:7138-7153). The crisis resolves inside
  it (Core Rule 5); no crisis outlasts the scene and none is ever saved.
- **Invocation scene**: a secret route's Chapter 9 scene, which in the source plays when the route's prerequisites
  are complete: First Wake C9-S18 (PM:8027-8043), Witness Protocol C9-S19 (PM:8045-8055), Crownless C9-S20
  (PM:8057-8064). None unlocks a route in 1.0 (Core Rule 6).
- **ID-lock gate**: every entry and re-entry into Root of Heaven (Chapter 10) — the story graph after the Chapter 9
  end, world-map or free travel, and loading a save positioned inside Root of Heaven. It opens only when a
  storyline ID is stored. The stored-ID check is this GDD's mechanism for the sources' "must revise one axis before
  Root of Heaven" (PM:722) and "intercepted before final boss" (PM:11305); it runs before the Chapter 9 End's "Root
  of Heaven gate opens" (PM:8206-8207).
- **Final authorization**: the immediate post-boss scene (PM:8786-8794). The world asks for the authorization
  result, the system displays the chosen structure, and the player confirms execution. It changes nothing.

### Core Rules

1. **Three axes, one value each.** Authority ∈ {YOU, SHARED, NONE}; Faction ∈ {HEARTH, ARCHIVE, CONTINUITY};
   Deleted ∈ {RESTORE, RELEASE, CHOOSE}; each starts UNSET (SaveService writes UNSET for a new game and for a save
   with no axis data). Once a storyline ID is stored, each axis holds exactly one value (PM:7522-7524, "Axis
   validation").
2. **Seeds are arguments, never gates.** Act 1 seeds are the leanings mapped for 1.0 (the 26 flags below);
   side storylines, companion persuasion and faction support become leanings the same way once Y2-PP-T17 maps their
   flags (AC15): each axis seed makes its lock scene voice an argument for (`+`) or against (`−`) its value
   ("Player influence can back one. Companion persuasion and side quests matter.", PM:6987-6988). Every lock scene
   always offers all three values; no seed adds or removes an option. No seed sets a value; only a lock scene or a
   renegotiation does ("This sets Faction Axis if vote passes.", PM:6989). The sources define no axis score.
3. **Lock scenes resolve, clean or negotiated.** Faction → `AXIS2_HEARTH` / `_ARCHIVE` / `_CONTINUITY`; Authority →
   `AXIS1_YOU` / `_SHARED` / `_NONE`; Deleted → `AXIS3_RESTORE` / `_RELEASE` / `_CHOOSE`. These flags are not in the
   code yet (owner: Y2-PP-T17). The composer input record is authoritative: these flags, `axis_revised_<axis>`,
   `lock_negotiated_<axis>` are mirrors, written in the same step as the record field, never
   read in its place and cleared with it. A lock vote always passes for the proposal the player backs (PM:6990-6991; a fixed
   rule, not a knob), so no vote leaves an axis UNSET. How it passes is recorded (`lock_pass`, Formulas): **clean**
   when at least one seed for the backed value is set with direction `+` and none with direction `−`; otherwise
   **negotiated**, and `lock_negotiated_<axis>` is set ("If player lacks support choice may still be possible
   through negotiations.", PM:6990). The test reads only which flags are set: no count, no weight. Only Faction has
   a `−` seed today (`ch1_knight_killed`), so for Authority and Deleted clean means at least one `+` seed for the
   backed value. Side-storyline flags join the test once Y2-PP-T17 maps them per flag. In 1.0 `lock_negotiated`
   feeds only the composer. One module makes it visible (user decision 2026-11-10): on a SOLE storyline whose
   `lock_negotiated` holds `authority`, the ending plays `sole_dissent`, in which the Assembly members who never
   endorsed Kaelen keeping Root are named on the record (new content, owner Y2-PP-T17). Nothing else in 1.0 reads
   `lock_negotiated` (no scene variant, ally line or slide), and it never changes a value or the ID.
4. **Red lines (new content), as values.** In the C8-S15 hearings, before the Deleted lock, if the locked Authority
   and Faction values are one Deleted value away from an invalid row, the delegate of the faction that would refuse
   states its red line as a value, never as a combination: Hearth when YOU and HEARTH are locked (R1, against one
   hand compelling the deleted back), Archive when NONE and ARCHIVE are locked (R2, against destroying unresolved
   memory appeals), Continuity when NONE and CONTINUITY are locked (R3, against irreversible release with no
   emergency Root left). No other pair voices a red line, C8-S13 and C8-S14 voice none, and there is no system
   warning. The combination itself is named only when the coalition breaks at C8-S16 (canon refusals PM:7141,
   PM:7147, PM:7151). New content approved by the user (2026-11-10), owner Y2-PP-T17.
5. **An invalid combination is a political crisis, resolved at C8-S16.** If the three locked values form an
   invalid row (R1-R3), the refusing faction breaks the coalition at C8-S16 (PM:7138-7153), "presented as a
   political crisis rather than a menu error" (PM:723), and the scene does not end until the coalition holds
   ("Player must change one axis before final lock.", PM:7143; "No invalid route waits until ending screen to
   fail.", PM:7153). It offers **renegotiations**: each locked axis's other values that form a valid row — six for
   R1, five for R2 or R3 (the Faction swap between R2 and R3 would break the coalition again and is not offered).
   Each is voiced as the refusing faction's demand, except a Faction offer, which is voiced as that faction stepping
   down and staying (`storyline-lifecycle.md` S4). Taking one: Kaelen withdraws the superseded position on the
   record, the Assembly votes again, the vote passes negotiated, `axis_revised_<axis>` and `lock_negotiated_<axis>`
   are set, and the withdrawal costs an authored beat (the retraction table and costs are in
   `storyline-lifecycle.md`). The source's "Secret SEVEN_WITNESSES may create alternative constitutional mechanism
   later." (PM:7144) is post-1.0: no secret-route offer exists in 1.0 (Core Rule 6).

   When a renegotiation reaches YOU, Kaelen states his commitment in that scene, and that is the answer SOVEREIGN
   later quotes (PM:7059); a withdrawn commitment is quoted only as withdrawn.
6. **Secret routes are reserved (post-1.0).** Each secret route T has offer prerequisites
   (`secret_prerequisites[T]`) and an unlock flag (`secret_unlock_flag[T]`); together, in that order, they are the
   production master's "Required flag" list for T (PM:11215-11218, PM:11242-11246, PM:11270-11274). All three
   routes — Witness Protocol, Crownless, First Wake — are disabled in 1.0 (user decision 2026-11-11, design review
   round 9; Witness Protocol was in 1.0 until then). While T is disabled: its invalid row can only be renegotiated
   at C8-S16; the journal shows no signpost or hint for it; its invocation scene does not unlock it (C9-S18 plays
   only its incomplete form, PM:8043; C9-S19 and C9-S20 do not play) and its unlock flag is never set; its Chapter
   10 scene (C10-S13 to C10-S15) plays only when the stored ID is `SL-SECRET-T`, which no 1.0 record holds; and the
   prerequisite flags that content sets are kept and transform nothing. When the routes ship they are designed
   together as one mechanism, in a GDD revision that defines the signposts, where an invocation is offered (in the
   source each route's last prerequisite is set after C8-S16, PM:7586-7588) and the Consent family (Open Question
   15).
7. **A valid row is held to its word.** Once an ID is stored — a valid row at C8-S16 or a renegotiation — nothing
   offers a renegotiation, and the ID never changes.
8. **Storyline ID and the ID-lock gate.** The moment the coalition holds, the live ID (Formulas) is stored:
   `SL-{authority}-{faction}-{deleted}` or `SL-SECRET-{route}`. Before that nothing is stored. A stored ID is never
   recomputed from flags or knobs ("Every route must save a stable storyline ID.", PM:11303) and is final once
   the final authorization concludes. Every entry and re-entry into Root of Heaven runs the gate check: with an ID stored the
   gate is open (also after the boss and in Story+); before the three locks it turns the player back in the fiction
   (the Assembly has not decided; `storyline-lifecycle.md` S6). In 1.0 that turn-back is defence in depth: Root of
   Heaven is entered only after the Chapter 9 end, so a record at the gate with an UNSET axis is already refused on
   load (D16), and a live one is a story-graph defect that the gate turns back as well (lifecycle T6; the reference
   model's walk never fires it). A save positioned past a lock scene with that axis UNSET (one made before these
   fields existed) is unsupported and does not load (Edge Case 16, D16; user decision 2026-11-10); no runtime
   catch-up exists. Every save that play writes loads (I9), and the load check keeps a loaded record consistent with
   the lock order (D16, D17). Beyond Edge Case 16's list the check is best-effort: the integrity of an edited save and
   the coupling of `root_phase` to the story position are not promised until the story positions exist (Y1-P1-T03;
   Open Question 17; user decision 2026-11-17). The refusal holds only while no player-facing build has such saves
   (`storyline-lifecycle.md` Legacy saves).
9. **Final authorization.** The post-boss scene displays the stored structure, with no generic menu
   (PM:8788-8789), and the player confirms execution. It changes no axis and no ID. The source's "one last lawful
   reconsideration" (PM:8791) is reserved (Open Questions): this design offers none, because boss phases 2-4
   already read Faction, Deleted and Authority (PM:8611-8616).
10. **Ending family** = the Authority value (YOU → SOLE, SHARED → BOUND, NONE → NONE_AUTH); the secret storylines'
    families are reserved until their routes ship (Story Bible §5 names CONSENT for Witness Protocol). **Bound** is
    a standing institution: Kaelen gives up unilateral final commit to a seven-signature protocol with rotating
    seats and public audit (PM:7064-7069). **No Authority**: the Assembly adopts abolition at C8-S14; Kaelen uses
    the Key once, after the final crisis, to dismantle permanent Root capability, and it cannot execute before the
    final confrontation (PM:7036-7038). **Consent (post-1.0)**: seven affected witnesses authorize one irreversible
    act (PM:705, PM:8047-8054, PM:11213), "a temporary legitimacy mechanism" (PM:8054). Its rules are designed with
    the secret routes (Open Question 15), including the points design review round 9 raised: the Assembly names the
    witnesses (PM:7519); whether the deleted seat can refuse a restoration it dissents from (PM:714, PM:7093,
    PM:11235); who holds Root after the act (PM:705); the threshold the player helped define (PM:8707); and what a
    vote that falls short leaves to Story+. Faction and Deleted are modifiers: a boss phase, ally lines, epilogue
    slides, Story+ cases.
11. **Companions are independent of the axes.** Every storyline can include every surviving companion
    (PM:7529-7537, PM:11302); a companion leaves through relationship flags (Edge Case 1), never through an axis.
    The one axis read: Kaelthas "can remain companion outside Archive if trust supports it" (PM:7533), so on a
    storyline whose Faction is not ARCHIVE his presence also needs that trust condition; on an ARCHIVE storyline
    it does not. The axis can only waive a trust test, never remove a companion.
12. **Timing is a modifier.** Pace values and timing flags change scenes, NPC fates, market events and ending slides
    through the composer, not the storyline ID (ROADMAP §12.4; PM:7527).

### Lifecycle invariants

The scenes and transitions are specified in `design/gdd/storyline-lifecycle.md` (the Y2-PP-T17 contract). They must
keep these invariants; a contract that breaks one is wrong, not this GDD:

| # | invariant | rules |
|---|---|---|
| I1 | Axis values come only from lock scenes and renegotiations; never from seeds, flags, knobs or the final authorization | 2, 3, 5, 9 |
| I2 | No crisis outlasts C8-S16 | 5 |
| I3 | The ID is stored the moment the coalition holds, is never recomputed, and never changes once stored | 7, 8 |
| I4 | Every entry and re-entry into Root of Heaven runs the gate check, on every path | 8 |
| I5 | No soft-lock under any knob value or patch: every state without a stored ID either is before the locks or offers a renegotiation that reaches a valid row | 5, 8 |
| I6 | Nothing important is lost silently: no hint points at an unshipped route; arcs 05, 08, 09 get a visible epilogue line in 1.0 | 6 |
| I7 | A valid row is held to its word | 7 |
| I8 | Family = the Authority value; a secret storyline's family is RESERVED until its route ships | 10 |
| I9 | Every transition commits its record writes and its beat id as one atomic checkpoint; no save exists inside a lock scene, the crisis or the final authorization before its commit | 3, 5, 8, 9 |

`storyline_phase` is derived, never stored (Formulas), as are `secret_route` and `family`; of the lifecycle fields
the record stores the axes, `storyline_id`, `root_phase`, `axis_revised`, `lock_negotiated`, `retraction_log` and
`beats_played`; the phase depends on the first three, after the Edge Case 16 check.

| phase | meaning | gate |
|---|---|---|
| LEANING | every axis UNSET | turns the player back |
| PARTLY_LOCKED | one or two axes locked | turns the player back |
| CRISIS | three axes locked on an invalid row, nothing stored: exists only inside C8-S16, never saved | — (inside C8-S16) |
| VALIDATED | an ID stored, `root_phase` OUTSIDE | open |
| FIXED | an ID stored, `root_phase` INSIDE (first entered Root of Heaven; stays INSIDE if the player leaves) | open (re-entry) |
| FINAL | the final authorization concluded: execution confirmed | open (Story+) |
| DAMAGED | the record holds an item of Edge Case 16: never saved by play; a load that yields it is refused | a loaded record never reaches the gate; a live one is turned back (lifecycle S6) |

### The 27 combinations

Invalidity rules (each removes one combination; quoted from PRODUCTION_MASTER_2.1.md:710-723):

| rule | combination | contradiction | source |
|---|---|---|---|
| R1 | YOU + HEARTH + RESTORE | "Hearth will not endorse unilateral compulsory restoration." | PRODUCTION_MASTER_2.1.md:714 |
| R2 | NONE + ARCHIVE + RELEASE | "Archive will not support abolition of root while mass release destroys unresolved memory appeals." | PRODUCTION_MASTER_2.1.md:716 |
| R3 | NONE + CONTINUITY + RELEASE | "Continuity will not support simultaneous abolition of emergency root and irreversible mass release." | PRODUCTION_MASTER_2.1.md:718 |

27 combinations: 24 valid and 3 invalid; each invalid one can become one of the 3 secret storylines, so the design
has 24 + 3 = 27 storylines in all, of which 24 are reachable in 1.0 (Counts).

`valid_count: 24`, as the source states (PM:711-712, PM:8728); the family split (SOLE 8, BOUND 9, NONE_AUTH 7) is
derived (Counts). For a valid row `source` is its route heading in the production master's route matrix and
`danger` its "Primary danger" line, the loss that route's ending must show (owner Y2-PP-T17); for an invalid row,
`source` is its validity line and `danger` is —. `companions_possible` is the same in every row by design (Core
Rule 11).

| id | authority | faction | deleted | status | family | rule | source | danger | companions_possible |
|---|---|---|---|---|---|---|---|---|---|
| SL-YOU-HEARTH-RESTORE | YOU | HEARTH | RESTORE | invalid | — | R1 | PRODUCTION_MASTER_2.1.md:713 | — | Elara, Seraphina, Lyra, Kaelthas |
| SL-YOU-HEARTH-RELEASE | YOU | HEARTH | RELEASE | valid | SOLE | — | PRODUCTION_MASTER_2.1.md:8978 | PRODUCTION_MASTER_2.1.md:8987 | Elara, Seraphina, Lyra, Kaelthas |
| SL-YOU-HEARTH-CHOOSE | YOU | HEARTH | CHOOSE | valid | SOLE | — | PRODUCTION_MASTER_2.1.md:9071 | PRODUCTION_MASTER_2.1.md:9080 | Elara, Seraphina, Lyra, Kaelthas |
| SL-YOU-ARCHIVE-RESTORE | YOU | ARCHIVE | RESTORE | valid | SOLE | — | PRODUCTION_MASTER_2.1.md:9164 | PRODUCTION_MASTER_2.1.md:9173 | Elara, Seraphina, Lyra, Kaelthas |
| SL-YOU-ARCHIVE-RELEASE | YOU | ARCHIVE | RELEASE | valid | SOLE | — | PRODUCTION_MASTER_2.1.md:9257 | PRODUCTION_MASTER_2.1.md:9266 | Elara, Seraphina, Lyra, Kaelthas |
| SL-YOU-ARCHIVE-CHOOSE | YOU | ARCHIVE | CHOOSE | valid | SOLE | — | PRODUCTION_MASTER_2.1.md:9350 | PRODUCTION_MASTER_2.1.md:9359 | Elara, Seraphina, Lyra, Kaelthas |
| SL-YOU-CONTINUITY-RESTORE | YOU | CONTINUITY | RESTORE | valid | SOLE | — | PRODUCTION_MASTER_2.1.md:9443 | PRODUCTION_MASTER_2.1.md:9452 | Elara, Seraphina, Lyra, Kaelthas |
| SL-YOU-CONTINUITY-RELEASE | YOU | CONTINUITY | RELEASE | valid | SOLE | — | PRODUCTION_MASTER_2.1.md:9536 | PRODUCTION_MASTER_2.1.md:9545 | Elara, Seraphina, Lyra, Kaelthas |
| SL-YOU-CONTINUITY-CHOOSE | YOU | CONTINUITY | CHOOSE | valid | SOLE | — | PRODUCTION_MASTER_2.1.md:9629 | PRODUCTION_MASTER_2.1.md:9638 | Elara, Seraphina, Lyra, Kaelthas |
| SL-SHARED-HEARTH-RESTORE | SHARED | HEARTH | RESTORE | valid | BOUND | — | PRODUCTION_MASTER_2.1.md:9722 | PRODUCTION_MASTER_2.1.md:9731 | Elara, Seraphina, Lyra, Kaelthas |
| SL-SHARED-HEARTH-RELEASE | SHARED | HEARTH | RELEASE | valid | BOUND | — | PRODUCTION_MASTER_2.1.md:9815 | PRODUCTION_MASTER_2.1.md:9824 | Elara, Seraphina, Lyra, Kaelthas |
| SL-SHARED-HEARTH-CHOOSE | SHARED | HEARTH | CHOOSE | valid | BOUND | — | PRODUCTION_MASTER_2.1.md:9908 | PRODUCTION_MASTER_2.1.md:9917 | Elara, Seraphina, Lyra, Kaelthas |
| SL-SHARED-ARCHIVE-RESTORE | SHARED | ARCHIVE | RESTORE | valid | BOUND | — | PRODUCTION_MASTER_2.1.md:10001 | PRODUCTION_MASTER_2.1.md:10010 | Elara, Seraphina, Lyra, Kaelthas |
| SL-SHARED-ARCHIVE-RELEASE | SHARED | ARCHIVE | RELEASE | valid | BOUND | — | PRODUCTION_MASTER_2.1.md:10094 | PRODUCTION_MASTER_2.1.md:10103 | Elara, Seraphina, Lyra, Kaelthas |
| SL-SHARED-ARCHIVE-CHOOSE | SHARED | ARCHIVE | CHOOSE | valid | BOUND | — | PRODUCTION_MASTER_2.1.md:10187 | PRODUCTION_MASTER_2.1.md:10196 | Elara, Seraphina, Lyra, Kaelthas |
| SL-SHARED-CONTINUITY-RESTORE | SHARED | CONTINUITY | RESTORE | valid | BOUND | — | PRODUCTION_MASTER_2.1.md:10280 | PRODUCTION_MASTER_2.1.md:10289 | Elara, Seraphina, Lyra, Kaelthas |
| SL-SHARED-CONTINUITY-RELEASE | SHARED | CONTINUITY | RELEASE | valid | BOUND | — | PRODUCTION_MASTER_2.1.md:10373 | PRODUCTION_MASTER_2.1.md:10382 | Elara, Seraphina, Lyra, Kaelthas |
| SL-SHARED-CONTINUITY-CHOOSE | SHARED | CONTINUITY | CHOOSE | valid | BOUND | — | PRODUCTION_MASTER_2.1.md:10466 | PRODUCTION_MASTER_2.1.md:10475 | Elara, Seraphina, Lyra, Kaelthas |
| SL-NONE-HEARTH-RESTORE | NONE | HEARTH | RESTORE | valid | NONE_AUTH | — | PRODUCTION_MASTER_2.1.md:10559 | PRODUCTION_MASTER_2.1.md:10568 | Elara, Seraphina, Lyra, Kaelthas |
| SL-NONE-HEARTH-RELEASE | NONE | HEARTH | RELEASE | valid | NONE_AUTH | — | PRODUCTION_MASTER_2.1.md:10652 | PRODUCTION_MASTER_2.1.md:10661 | Elara, Seraphina, Lyra, Kaelthas |
| SL-NONE-HEARTH-CHOOSE | NONE | HEARTH | CHOOSE | valid | NONE_AUTH | — | PRODUCTION_MASTER_2.1.md:10745 | PRODUCTION_MASTER_2.1.md:10754 | Elara, Seraphina, Lyra, Kaelthas |
| SL-NONE-ARCHIVE-RESTORE | NONE | ARCHIVE | RESTORE | valid | NONE_AUTH | — | PRODUCTION_MASTER_2.1.md:10838 | PRODUCTION_MASTER_2.1.md:10847 | Elara, Seraphina, Lyra, Kaelthas |
| SL-NONE-ARCHIVE-RELEASE | NONE | ARCHIVE | RELEASE | invalid | — | R2 | PRODUCTION_MASTER_2.1.md:715 | — | Elara, Seraphina, Lyra, Kaelthas |
| SL-NONE-ARCHIVE-CHOOSE | NONE | ARCHIVE | CHOOSE | valid | NONE_AUTH | — | PRODUCTION_MASTER_2.1.md:10931 | PRODUCTION_MASTER_2.1.md:10940 | Elara, Seraphina, Lyra, Kaelthas |
| SL-NONE-CONTINUITY-RESTORE | NONE | CONTINUITY | RESTORE | valid | NONE_AUTH | — | PRODUCTION_MASTER_2.1.md:11024 | PRODUCTION_MASTER_2.1.md:11033 | Elara, Seraphina, Lyra, Kaelthas |
| SL-NONE-CONTINUITY-RELEASE | NONE | CONTINUITY | RELEASE | invalid | — | R3 | PRODUCTION_MASTER_2.1.md:717 | — | Elara, Seraphina, Lyra, Kaelthas |
| SL-NONE-CONTINUITY-CHOOSE | NONE | CONTINUITY | CHOOSE | valid | NONE_AUTH | — | PRODUCTION_MASTER_2.1.md:11117 | PRODUCTION_MASTER_2.1.md:11126 | Elara, Seraphina, Lyra, Kaelthas |

SHARED and CHOOSE appear in no invalid row, so any row holding one of them can never reach a crisis: a known safe
pick.

### Secret storylines

Added to the 27 combinations as storylines, not replacing a table row; each transforms one invalid row (PM:697-699,
PM:8783-8784).

| id | route | family | scope | source |
|---|---|---|---|---|
| SL-SECRET-WITNESS | Witness Protocol (PM "SEVEN WITNESSES"; SEC-01 "Authorized by the Living"; transforms R1 / YHR) | — (reserved; CONSENT when designed) | post-1.0 | PRODUCTION_MASTER_2.1.md:11211 |
| SL-SECRET-FIRSTWAKE | First Wake (SEC-03 "Hello From Outside"; transforms R3 / NCL) | — (reserved) | post-1.0 | PRODUCTION_MASTER_2.1.md:11266 |
| SL-SECRET-CROWNLESS | Crownless (SEC-02 "No Throne in Heaven"; transforms R2 / NAL) | — (reserved) | post-1.0 | PRODUCTION_MASTER_2.1.md:11238 |

### Act 1 seed map

Every flag below is set in `AethelgardPrototype/dialogue` or `scripts` (26 flags). `direction` for an axis seed:
`+` makes the axis's lock scene voice an argument for the value, `−` an argument against it (the other two values
are unaffected). For a modifier, `+` / `−` is the sign of the change the flag records (for a set such as
`companions_present`, in or out of the set). `0`: the flag is read as it is and leans nowhere (timing selectors and
neutral choices). `overturnable`: an axis seed's argument is voiced until its axis's lock scene resolves
(`until:lock:faction`, `until:lock:authority`, `until:lock:deleted`); it never holds a value. A modifier or timing
row is `no`. Rows marked (J) are judgement calls with no explicit source statement of direction, approved by the
user.

| flag | pushes | direction | overturnable | source |
|---|---|---|---|---|
| act1_report_local | faction:HEARTH | + | until:lock:faction | PRODUCTION_MASTER_2.1.md:2856 |
| act1_report_archive | faction:ARCHIVE | + | until:lock:faction | PRODUCTION_MASTER_2.1.md:2857 |
| act1_report_command | faction:CONTINUITY | + | until:lock:faction | PRODUCTION_MASTER_2.1.md:2858 |
| ch2_seraphina_truth | modifier:seraphina_relationship | + | no | STORY_BIBLE.md:206 (J) |
| ch2_seraphina_cautious | modifier:seraphina_relationship | 0 | no | dialogue/ch2/command_hall.dlg:31 |
| ch2_seraphina_showoff | modifier:seraphina_relationship | − | no | STORY_BIBLE.md:206 (J) |
| ch2_seraphina_recruited | modifier:companions_present | + | no | PRODUCTION_MASTER_2.1.md:3123 |
| ch2_seraphina_stayed | modifier:companions_present | − | no | PRODUCTION_MASTER_2.1.md:3125 |
| ch2_seraphina_rejected | modifier:companions_present | − | no | PRODUCTION_MASTER_2.1.md:3127 |
| ch2_data_wraith_restored | deleted:RESTORE | + | until:lock:deleted | PRODUCTION_MASTER_2.1.md:3117 |
| ch2_data_wraith_destroyed | deleted:RELEASE | + | until:lock:deleted | PRODUCTION_MASTER_2.1.md:3119 (J) |
| ch2_data_wraith_absorbed | deleted:CHOOSE | + | until:lock:deleted | PRODUCTION_MASTER_2.1.md:2468 (J) |
| ch1_knight_killed | faction:HEARTH | − | until:lock:faction | PRODUCTION_MASTER_2.1.md:663 (J) |
| ch1_knight_spared | modifier:aldric_restrained | + | no | PRODUCTION_MASTER_2.1.md:1806 |
| ch1_root_purge | faction:HEARTH | + | until:lock:faction | PRODUCTION_MASTER_2.1.md:663 (J) |
| ch1_aldric_kill_owned | authority:YOU | + | until:lock:authority | PRODUCTION_MASTER_2.1.md:1801 |
| ch1_aldric_kill_justified | authority:YOU | + | until:lock:authority | STORY_BIBLE.md:196 (J) |
| ch1_aldric_kill_unsure | authority:SHARED | + | until:lock:authority | STORY_BIBLE.md:196 (J) |
| ch1_root_first_edit | authority:YOU | + | until:lock:authority | STORY_BIBLE.md:190 (J) |
| ch1_root_discovered_unused | authority:NONE | + | until:lock:authority | STORY_BIBLE.md:190 (J) |
| ch1_oakhaven_warned_villagers | modifier:A1-OAK-SAVED | + | no | PRODUCTION_MASTER_2.1.md:3105 |
| ch1_oakhaven_warned_leaders | modifier:A1-OAK-SAVED | + | no | PRODUCTION_MASTER_2.1.md:3105 (J) |
| ch1_oakhaven_left_quietly | modifier:A1-OAK-QUIET | + | no | PRODUCTION_MASTER_2.1.md:3107 |
| act1_pace_early | timing | 0 | no | PRODUCTION_MASTER_2.1.md:2869 |
| act1_pace_on_time | timing | 0 | no | PRODUCTION_MASTER_2.1.md:2870 |
| act1_pace_late | timing | 0 | no | PRODUCTION_MASTER_2.1.md:2871 |

Notes on the (J) rows:
- `ch1_root_purge` and `ch1_knight_killed`: PM:663 says only that Aldric supports Hearth "if he survives with
  agency intact"; it names neither purge nor kill. The mapping is an inference approved by the user (2026-11-09,
  re-confirmed 2026-11-10): the purge keeps Aldric alive, so his support can argue for Hearth; the kill removes it.
  The purge is also a non-consensual rewrite of a person ("even if it takes his memory with it",
  `dialogue/ch1/aldric.dlg:57`); that reading is recorded in Open Questions.
- `ch2_seraphina_cautious` changes no trust value (`dialogue/ch2/command_hall.dlg:31-36`; truth and showoff do),
  hence `0`.

### Side storylines

`axis:*` means the arc's own choices push that axis toward a value either way; no arc sets a value (Core Rule 2).
Arc 13 onward are not among the 12 (PM:5837). Arc 12's secondary `deleted:CHOOSE` and the primary/secondary order
of arc 06 ("Continuity or Hearth", PM:2695) are judgement calls (J).

**Pillar P5 in 1.0.** Arcs 05, 08 and 09 feed only the post-1.0 secret routes; in 1.0 they push no axis. P5
("side storylines feed the main story") is to be met in 1.0 by the other nine arcs, once Y2-PP-T17 maps their flags
into the seed map (AC15); today the seed map holds no side-arc flag, so P5 is planned, not yet covered. Arc 12 ships
in 1.0 and pushes `deleted:CHOOSE`; its Witness Protocol feed waits for that route. Flags of arcs 05, 08, 09 and of
arc 12's Witness feed are kept and never transform a row; no hint points at an unshipped route (Edge Case 3), but
each of arcs 05, 08 and 09 gets one visible epilogue line in 1.0 acknowledging what the player did (owner
Y2-PP-T17), so nothing is lost silently (invariant I6).

| arc | title | primary | secondary | scope | pm_line |
|---|---|---|---|---|---|
| 01 | The Baker of Oakhaven | faction:HEARTH | — | 1.0 | 1904 |
| 02 | Knight's Debt | authority:* | — | 1.0 | 1953 |
| 03 | Glitch-Witch's Price | authority:* | — | 1.0 | 1981 |
| 04 | Iron Owes | faction:* | — | 1.0 | 2614 |
| 05 | The Flight List | secret:FIRSTWAKE | — | post-1.0 | 2660 |
| 06 | Three Auctions and a Funeral | faction:CONTINUITY | faction:HEARTH | 1.0 | 2695 |
| 07 | Things Lyra Forgot | deleted:* | faction:ARCHIVE | 1.0 | 3619 |
| 08 | Kaito's False Sky | secret:CROWNLESS | — | post-1.0 | 3663 |
| 09 | The Last Error | secret:FIRSTWAKE | — | post-1.0 | 3687 |
| 10 | The Names We Keep | deleted:* | — | 1.0 | 4373 |
| 11 | The Clerk Who Stayed | authority:SHARED | — | 1.0 | 4423 |
| 12 | A Person in Three Places | secret:WITNESS | deleted:CHOOSE | 1.0 | 4459 |

### Composer input record

SaveService (Y1-P1-T05) stores the record and owns serialisation, the schema version and the defaults for a new
game or a save without these fields (UNSET, empty, OUTSIDE). Every writer named below is a scene
owned by Y2-PP-T17 and specified in `storyline-lifecycle.md`; no other code writes these fields.

| field | type | allowed | writer |
|---|---|---|---|
| storyline_phase | enum | LEANING, PARTLY_LOCKED, CRISIS, VALIDATED, FIXED, FINAL, DAMAGED | derived: `storyline_phase(record, loaded, flags, position)` (Formulas); never stored |
| storyline_id | string | a storyline ID, or empty while nothing is stored | C8-S16 on a valid row; a renegotiation at C8-S16; nothing else |
| root_phase | enum | OUTSIDE, INSIDE, FINAL | the gate check on entry with an ID stored (INSIDE); the final authorization concluding by confirmed execution (FINAL) |
| authority | enum | UNSET, YOU, SHARED, NONE | C8-S14 lock; a renegotiation. Never the final authorization |
| faction | enum | UNSET, HEARTH, ARCHIVE, CONTINUITY | C8-S13 lock; a renegotiation. Never the final authorization |
| deleted | enum | UNSET, RESTORE, RELEASE, CHOOSE | C8-S16 lock; a renegotiation. Never the final authorization |
| secret_route | enum | NO_SECRET, WITNESS, FIRSTWAKE, CROWNLESS | derived from `storyline_id` (`SL-SECRET-T` → T, else NO_SECRET); never stored |
| family | enum | SOLE, BOUND, NONE_AUTH, RESERVED, NO_FAMILY | derived: `family(storyline_id)`; never stored |
| axis_revised | set | faction, authority, deleted | a renegotiation |
| lock_negotiated | set | faction, authority, deleted | the lock scenes by `lock_pass`; every renegotiation |
| retraction_log | list | entries {axis, old, new, withdrawn_item, scene}, oldest first | every renegotiation |
| beats_played | set | the lifecycle's authored beat ids (`retract_*`) | the scene that plays the beat |
| companions_present | set | Elara, Seraphina, Lyra, Kaelthas | `AethelgardPrototype/scripts/game_manager.gd` (`has_elara`, exclusive flag groups); `AethelgardPrototype/dialogue/ch2/fragment_two.dlg` |
| regions_completed | set | ids of the eight regions | owner story Y2-PP-T17 (no writer in the code today) |
| timing_flags | set of flags | `ch1_bridge_saved` / `_evacuated` / `_fell`, `ch2_medicine_early` / `_on_time` / `_late` | `AethelgardPrototype/dialogue/ch1/north_field.dlg`; `AethelgardPrototype/dialogue/ch2/act1_end.dlg` |
| act1_pace | enum | act1_pace_early, act1_pace_on_time, act1_pace_late | `AethelgardPrototype/dialogue/ch2/act1_end.dlg` |
| act2_pace, act3_pace, act4_pace | enum | names left to S06b | owner story Y1-P0-S06b |

### Interactions with Other Systems

- **Storyline lifecycle (`design/gdd/storyline-lifecycle.md`, Y2-PP-T17):** the scenes and transitions that write
  this record and keep invariants I1-I9.
- **FlagRegistry / StoryGraph (Y1-P1-T03):** owns the seed flags and, later, the `AXIS*`, `axis_revised_*`,
  `lock_negotiated_*` flags and the secret routes' prerequisite and unlock flags; validates exclusive groups and
  the secret-route knobs at boot; supplies the story position the load check reads; this GDD names them, it does not
  write them. The `AXIS*`, `axis_revised_*` and `lock_negotiated_*` flags are mirrors of the record (Core Rule 3),
  which stays authoritative.
- **SaveService (Y1-P1-T05):** stores the composer input record; a stored ID is never recomputed; loading restores
  the record, runs the load check and derives the phase; one atomic checkpoint per transition (I9).
- **Time model (S06b):** supplies pace values per act and the timing flags the composer reads.
- **Ending composer / route data model (owner Y2-PP-T17):** implements `storyline_id`, `storyline_phase`,
  `lock_pass` and `family` (Formulas), the modules and the epilogue lines; authored cost additive.
- **World map / free travel:** must run the gate check on entry to Root of Heaven (Core Rule 8). World-map and
  free-travel logic is protected (`AethelgardPrototype/AGENTS.md`): that change needs the user's explicit approval
  when it is implemented.
- **Companion system:** reads relationship flags for presence; never reads an axis to remove a companion.
- **Side storylines (arcs 01-12):** push arguments into axes or modifiers per the table above.

## Formulas

The storyline system defines no balance numbers: the sources define no axis score, and values come only from the
lock scenes and renegotiations (PM:6987-6989, PM:7522-7524). Its formulas are exact rules that saves, tests and the
composer compute.

### Storyline ID

```
storyline_id(A, F, D, I):
    if A, F or D is UNSET                        → PENDING
    if not invalid(A, F, D)                      → "SL-" + A + "-" + F + "-" + D      (I is ignored)
    T = transform(A, F, D)
    if I and enabled(T) and prereqs_met(T)       → "SL-SECRET-" + T
    otherwise                                    → CRISIS                             (Core Rule 5)

transform(A, F, D) = { R1 → WITNESS, R2 → CROWNLESS, R3 → FIRSTWAKE }[the rule whose combination is (A, F, D)]
prereqs_met(T) = secret_prerequisites[T] has at least two flags and every one of them is set
```

| Variable | Type | Range | Source | Description |
|---|---|---|---|---|
| A | enum | YOU, SHARED, NONE, UNSET | `authority` field | Authority |
| F | enum | HEARTH, ARCHIVE, CONTINUITY, UNSET | `faction` field | Faction |
| D | enum | RESTORE, RELEASE, CHOOSE, UNSET | `deleted` field | The deleted |
| I | bool | true, false | in 1.0 always false: no route is enabled and the record holds no invocation (the post-1.0 secret-route design adds its source); as a formula input it is free, and the body reads it only on an invalid row | The player confirmed the invocation of the route that transforms this row |
| enabled(T) | bool | `secret_route_enabled.T` (Tuning Knobs) | data | Whether route T ships; false for all three in 1.0 |
| prereqs_met(T) | bool | see above | data | e.g. WITNESS: PM:11215-11217 |

The formula gives the live value while no ID is stored. The value stored when the coalition holds is the formula's
result at that moment; afterwards the stored ID is read, never recomputed (Core Rule 8). The unlock flags
(`SEVEN_WITNESSES_AVAILABLE` and the others) are not inputs; no 1.0 scene sets one (Core Rule 6). The secret branch
is kept so the post-1.0 routes need no change to this formula; with the default knobs it never fires.

Examples (default knobs unless stated):
- (SHARED, ARCHIVE, CHOOSE, false) → `SL-SHARED-ARCHIVE-CHOOSE`.
- (SHARED, ARCHIVE, CHOOSE, true) → `SL-SHARED-ARCHIVE-CHOOSE` (a secret never applies to a valid row).
- (YOU, HEARTH, RESTORE, false) → CRISIS.
- (YOU, HEARTH, RESTORE, true), all three offer prerequisites set → CRISIS: WITNESS is disabled, so the row can
  only be renegotiated.
- (YOU, HEARTH, RESTORE, true), WITNESS enabled (a post-1.0 knob value), all three offer prerequisites set →
  `SL-SECRET-WITNESS`; with two of the three set → CRISIS.
- (NONE, CONTINUITY, RELEASE, true), FIRSTWAKE disabled → CRISIS: the row can only be renegotiated.
- (UNSET, HEARTH, CHOOSE, false) → PENDING.

### Validity

```
invalid(A, F, D) = (A, F, D) ∈ { (YOU, HEARTH, RESTORE), (NONE, ARCHIVE, RELEASE), (NONE, CONTINUITY, RELEASE) }
```

The set is the three rules R1-R3; it is defined only for three set values. It is fixed by design, not a knob.

### Lock pass

```
lock_pass(X, v):
    if some seed row (X:v, +) is set and no seed row (X:v, −) is set   → CLEAN
    otherwise                                                          → NEGOTIATED
renegotiation vote                                                     → NEGOTIATED
```

X is the axis being locked, v the value the player backs; a seed row is a row of the Act 1 seed map. NEGOTIATED sets
`lock_negotiated_<X>`. Examples: HEARTH with `act1_report_local` set → CLEAN; with `act1_report_local` and
`ch1_knight_killed` set → NEGOTIATED; HEARTH with only `ch1_knight_killed` → NEGOTIATED; ARCHIVE with no seed set →
NEGOTIATED; YOU with `ch1_root_first_edit` set → CLEAN.

### Storyline phase

```
storyline_phase(record, loaded, flags, position):
    if damaged(record, loaded, flags, position)        → DAMAGED
    if storyline_id is stored and root_phase is FINAL  → FINAL
    if storyline_id is stored and root_phase is INSIDE → FIXED
    if storyline_id is stored                          → VALIDATED
    if A, F and D are all UNSET                        → LEANING
    if A, F or D is UNSET                              → PARTLY_LOCKED
    otherwise                                          → CRISIS
```

`loaded` is true for a record just read from a save and false for the live record in play. `flags` is the set of
story flags saved with the record and `position` the story position of the save (owned by Y1-P1-T03 and Y1-P1-T05);
the record alone cannot show D15-D17, so the check takes them. `damaged(record, loaded, flags, position)` is true when
the inputs hold an item of Edge Case 16. Two items are tested on a loaded record only (`loaded` true): D9 and the
before-commit clause of D17, because inside C8-S16 the live record is the crisis itself: an invalid row with its
Deleted value set and nothing stored, before the commit. Every other item applies to the live record too (Edge Case
16 marks each item). For a record that passed the load check the two calls agree.
The check runs first, so a record that contradicts the phase table is never classified as a playable phase: FINAL
and FIXED need a stored ID, and a loaded record that would read CRISIS is DAMAGED, because a crisis is never saved. A
valid row is stored in the same step that sets its last axis, so "three axes set, nothing stored" is, in play, always
an invalid row inside C8-S16. Examples (loaded records, `loaded` true, consistent flags and position; a record is
written (authority, faction, deleted, stored ID, `root_phase`)): (YOU, HEARTH, UNSET, nothing stored, OUTSIDE) →
PARTLY_LOCKED; (SHARED, ARCHIVE, CHOOSE, `SL-SHARED-ARCHIVE-CHOOSE`, INSIDE) → FIXED; (YOU, HEARTH, UNSET, nothing
stored, FINAL) → DAMAGED; (NONE, ARCHIVE, RELEASE, nothing stored, OUTSIDE) → DAMAGED. Example (the live record in
play, `loaded` false): (NONE, ARCHIVE, RELEASE, nothing stored, OUTSIDE) → CRISIS; the same record with `loaded` true
is the last DAMAGED example above.

### Ending family

```
family(id):
    SL-SECRET-WITNESS, SL-SECRET-CROWNLESS, SL-SECRET-FIRSTWAKE → RESERVED   (unreachable while their routes are disabled)
    "SL-" + A + "-" + F + "-" + D, not invalid(A, F, D) → { YOU → SOLE, SHARED → BOUND, NONE → NONE_AUTH }[A]
    PENDING, CRISIS, an invalid-row id, anything else    → NO_FAMILY (not a storyline ID)
```

Example: `SL-NONE-HEARTH-CHOOSE` → NONE_AUTH; `SL-YOU-HEARTH-RESTORE` → NO_FAMILY.

### Counts

Per family the split is derived, not stated by the source; the design total follows ROADMAP §12.2 and
PM:8728-8729. With the default knobs no secret route is enabled: `reachable_1_0: 24`. **P3 scope (user,
2026-11-11, superseding the 2026-11-10 sign-off of 25):** P3's "24 + 3" is the design total; 1.0 ships the 24 valid
storylines in three families, and the three secret storylines follow post-1.0 (Open Question 14).

```
combinations         = 3 × 3 × 3 = 27
valid_count          = 27 − 3 = 24
secret_storylines    = 3
design_storylines    = 24 + 3 = 27
reachable_1_0        = 24 + 0 = 24
family_SOLE          = 9 − 1 = 8
family_BOUND         = 9
family_NONE_AUTH     = 9 − 2 = 7
renegotiation_offers = 6 + 5 + 5 = 16
```

`valid_count` subtracts the three invalid rows; SOLE loses R1, NONE_AUTH loses R2 and R3. R1 offers six
renegotiations, R2 and R3 five each (the Faction swap between them is not offered).

## Edge Cases

1. **A companion leaves (the plan's edge case).** A companion is absent through relationship flags, never an axis:
   Elara when `has_elara()` is false (`ch1_elara_trusted` and `_cautious` both unset), Seraphina on
   `ch2_seraphina_stayed` / `_rejected`, Lyra on `ch3_lyra_left_alone`, Kaelthas on `ch3_kaelthas_refused` /
   `_challenged`, his betrayal (PM:788), or, outside the Archive, too little trust (PM:7533; Core Rule 11). The
   storyline is unchanged: no ending family needs a companion (Story Bible §5), so every valid storyline stays
   reachable with any companion — or none — present; the composer omits that companion's modules.
2. **Every Witness Protocol lead found in 1.0.** The route is reserved (Core Rule 6): R1 at C8-S16 offers only its
   six renegotiations, C9-S19 does not play, `SEVEN_WITNESSES_AVAILABLE` is never set, and the lead flags stay set
   and transform nothing (`storyline-lifecycle.md` S5 and its Edge Case 5).
3. **Any invalid row before the secret routes ship.** R1, R2 and R3 can only be renegotiated at C8-S16. Any flags
   their side arcs set (05, 08, 09, and arc 12's Witness feed) are kept but never transform a row, and no signpost or
   hint for an unshipped route is shown; the epilogue lines of arcs 05, 08 and 09 still play (invariant I6).
4. **No support for the value the player wants.** The vote still passes, negotiated (PM:6990; Core Rule 3); no
   faction becomes unavailable without warning (PM:6991). The same holds for every lock and renegotiation vote.
5. **Contradictory seeds** (e.g. `act1_report_local` with `ch1_knight_killed`). Both arguments are voiced; the lock
   scene decides, and the vote passes negotiated (`lock_pass`). No error, no tie-break.
6. **Two flags of one exclusive group.** Setting a flag clears the other flags of its group with a warning
   (`AethelgardPrototype/scripts/game_manager.gd:709-728`), so play never holds two. A save that does hold two is
   damaged: SaveService's load check reports it (Edge Case 16, D15); this system defines no tie-break.
7. **Timing that goes badly** (`ch1_bridge_fell`, `act1_pace_late`). The storyline ID never changes; the composer
   picks different scene and slide modules (Core Rule 12).
8. **A save from before the coalition holds** (every save today). It loads LEANING or PARTLY_LOCKED with nothing
   stored; seeds already in the save are read as they are. No save is made in CRISIS: the crisis resolves
   inside C8-S16. A save with no axis data positioned before C8-S13 loads LEANING with all axes UNSET; one
   positioned past a lock scene (chapters 9 and 10 exist in the code today) is unsupported and does not load (Edge
   Case 16, D16; the project's own fixture saves are migrated once, `storyline-lifecycle.md` Legacy saves). A save
   made after the coalition holds reloads its stored ID unchanged. The refusal holds only while no player-facing
   build has a save past Chapter 8; if one ships before these fields do, the decision is reopened.
9. **NG+.** Whether axis leanings or the previous storyline carry into a new cycle is not decided here (Open
   Questions); until decided, NG+ starts LEANING with the reset list in `storyline-lifecycle.md`.
10. **Reaching Root of Heaven without a stored ID.** Every path runs the gate check (Core Rule 8); LEANING,
    PARTLY_LOCKED or a live DAMAGED record is turned back (defence in depth: no play path reaches these, Core Rule
    8), and no other phase lacks an ID outside C8-S16. Outcomes per path and phase: `storyline-lifecycle.md` S6.
11. **Secret prerequisites and the locks.** In the source each route's last offer prerequisite is set after C8-S16,
    in the Act 3 ledger (PM:7586-7588), so no route could be invoked at the crisis. In 1.0 this changes nothing (all
    routes reserved); the post-1.0 design must decide where an invocation is offered (Open Question 15).
12. **A renegotiation to the same value, or to the other invalid row.** Neither is offered: a renegotiation offers
    only other values that form a valid row.
13. **A knob changes mid-playthrough** (e.g. a patch). Knobs are read only at C8-S16 and the gate. With an ID
    stored, nothing changes (Core Rule 8). Enabling a secret route needs the post-1.0 GDD revision (Core Rule 6); a
    1.0 build that enables one fails boot validation (AC12).
14. **The final authorization.** It displays the stored structure and the player confirms (PM:8788-8790); it
    offers no reconsideration and changes no field except `root_phase` (Core Rule 9).
15. **A crash or quit inside a lock scene, the crisis or the final authorization.** No save exists there before the
    commit (I9): the player reloads the last save before the scene and it replays from its start; after the commit
    the checkpoint resumes at the committed beat (`storyline-lifecycle.md` commit and save rule).
16. **A damaged record** (a debug or edited save, or one made before these fields existed; play never writes one,
    because every transition is one atomic checkpoint, I9). A secret unlock flag alone changes nothing. The check
    reads the record, the saved flags and the story position (`load_check(record, flags, position)`); it compares
    and never rewrites the stored ID or the save, and reads no knob, so a patch never damages a save. SaveService's
    load check reports each item below as a data error on load and refuses the load (`storyline_phase` DAMAGED):
    the player returns to the load menu, no transition fires and no gate runs. `load_check` always tests a loaded
    record, so it runs every item. `storyline_phase` runs the same items on the live record, except the two marked
    *(load only)*: inside C8-S16 the live record is the crisis, an invalid row with its Deleted value set before the
    commit (Formulas, Storyline phase). A position inside a lock scene counts as before the commit, so the CRISIS
    fixture of AC9 reports {D9, D17}.
    - D1 a stored ID that is not `SL-A-F-D` for its axes on a valid row: any other ID, an ID with an UNSET axis,
      the ID of an invalid row, or any `SL-SECRET-*` ID (no 1.0 play stores one)
    - D2-D5 retired (revision 9): they checked the Witness record fields, which 1.0 no longer stores
    - D6 `axis_revised` holding an axis that `lock_negotiated` lacks
    - D7 `axis_revised` holding an axis that no `retraction_log` entry names, or a `retraction_log` entry whose
      axis is not in `axis_revised` (the composer reads `axis_revised`), or more than one axis, or a
      `retraction_log` entry whose `new` value is not the record's value for its axis
    - D8 `root_phase` INSIDE or FINAL with nothing stored
    - D9 three axes set with nothing stored *(load only)*
    - D10-D13 retired (revision 9): they checked the witness vote fields
    - D14 a `retract_*` beat in `beats_played` with no matching `retraction_log` entry, or a `retraction_log` entry
      whose beat is not in `beats_played`, or a beat id the lifecycle does not define. A beat matches an entry
      exactly when its id is `retract_<rule>_<axis>_<new>`, rebuilt from the entry (`rule` is the invalid row R1-R3
      that the record's axes form with the entry's axis set back to `old`)
    - D15 two flags of one exclusive group (Edge Case 6)
    - D16 a story position past the lock scene of an UNSET axis (a save made past Chapter 8 before these fields
      existed; unsupported, user decision 2026-11-10)
    - D17 a lock-order defect, in two clauses. (a) *Before commit (load only):* an axis is set while the story
      position is before its lock scene's commit: no lock scene could play from it (S1 needs every axis UNSET, S2
      needs Faction set, S4 needs Faction and Authority set), so loading it would strand the player. A position
      inside a lock scene before its commit counts as before it (no save exists there, I9); the commit checkpoint
      counts as past it. (b) *Prefix:* the set axes are not a prefix of the lock order (Faction, then Authority,
      then Deleted). For a loaded record (b) is implied by D16 and (a) (the reference model checked 64 axis triples
      at 15 positions and found none that fires (b) alone), so it is kept as documentation and has no fixture of its
      own (AC9)

    D16 holds only while no player-facing build has such saves; if one ships before these fields do, the decision is
    reopened (`storyline-lifecycle.md` Legacy saves).

    Not checked (best-effort, edited or debug saves only; user decision 2026-11-17, Open Question 17):
    `lock_negotiated` against `lock_pass` of the saved seeds, a retraction entry's `withdrawn_item` and `scene`
    against the lifecycle's retraction table, and the coupling of `root_phase` to the story position (a FINAL record
    before the boss, a non-FINAL record after it).

## Dependencies

| System | Direction | What flows | Status of its design doc |
|---|---|---|---|
| Storyline lifecycle (`design/gdd/storyline-lifecycle.md`, Y2-PP-T17) | this → lifecycle | the axes, formulas, record and invariants I1-I9 the scenes must keep | revision 6 (gate row for a live DAMAGED record, L-AC8 reconciled with the reference model); needs re-review |
| Time model (`design/gdd/time-model.md`, Y1-P0-S06b) | this ← time model | per-act pace values (`act1_pace_*` exists; acts 2-4 named there), timing flags | not written yet — S06b must list this GDD as a dependent |
| FlagRegistry / StoryGraph (Y1-P1-T03) | this ← registry | seed flags, the future `AXIS*`, `axis_revised_*`, `lock_negotiated_*` flags, secret prerequisite and unlock flags, exclusive-group and secret-knob validation | no GDD (an ADR/tech design later) — must cite this GDD's seed map |
| SaveService (Y1-P1-T05) | this → save | the composer input record, saved and versioned; the damaged-record check | no GDD — must store the fields in the composer record |
| Ending composer / route data model (Y2-PP-T17) | this → composer | the composer input record, the family map, `sole_dissent`, the epilogue lines | not designed — consumes this GDD and the lifecycle contract |
| World map / free travel (protected, `AethelgardPrototype/AGENTS.md`) | this → world map | the gate check on entry to Root of Heaven | no GDD — implementation needs the user's explicit approval |
| Companion presence (relationship flags) | this ← companions | `companions_present` | no GDD — must never remove a companion by axis (Core Rule 11) |
| Side storylines (arcs 01-12, `story/source/PRODUCTION_MASTER_2.1.md`) | this ← arcs | seeds into axes, modifiers, secret routes | authored in the production master; S09 (arc 04) and Y1-P1-S04/S05 write into this table |
| Story Bible §5 (`AethelgardPrototype/story/STORY_BIBLE.md`) | both | axes, families, timing table | records the four-family decision (AC-6 line); its 1.0 scope (three families) is Open Question 14 |
| Difficulty profiles (Y1-P0-S06c) | none | — | deadline leniency belongs to the time model, not here |

Bidirectional rule: each doc above that is written later must name `design/gdd/storyline-axes.md` in its own
Dependencies section.

**Protected touchpoints.** `AethelgardPrototype/AGENTS.md` protects collision, hitboxes, combat, save/load schema,
story progression, Source Key logic, true ending, NG+ and world-map/free-travel logic. Implementing this design and
`storyline-lifecycle.md` changes the following; each change needs the user's explicit approval in the prompt of
the story that implements it:

| protected area | what this design needs there | where specified |
|---|---|---|
| save/load schema | the composer record fields, defaults, the damaged-record check and load refusal, one atomic checkpoint per transition and save suppression inside lock scenes, the dev-fixture migration | Composer input record; Edge Cases 8, 15, 16; I9; lifecycle commit and save rule, Legacy saves |
| story progression | the lock-scene order, the C8-S16 crisis, the gate on the `story` path, the secret-route scenes kept closed (C9-S18 incomplete form; C9-S19, C9-S20, C10-S13 to C10-S15 gated on the stored ID), the superseded legacy Chapter 8 and Chapter 10 flags | Core Rules 3-9; lifecycle S1-S7, Dependencies |
| world-map / free-travel logic | the gate check on the `world_map` path | Core Rule 8; lifecycle S6 |
| combat | none beyond the source: boss phases read the stored axes (PM:8611-8616); the re-entry rule | Core Rule 9; lifecycle Edge Case 2 |
| NG+ | the reset of the record and the axis, secret and unlock flags | Edge Case 9; lifecycle NG+ reset |
| true ending | none: no storyline is called the true ending ("Secret route is not called true ending.", PM:11221); the family endings and modules are new composer content | Core Rule 10 |
| Source Key logic | none expected: the final authorization confirms execution and changes no Source Key rule; if Y2-PP-T17 routes it through Source Key code, that needs approval | Core Rule 9 |
| collision, hitboxes | none | — |

## Tuning Knobs

Knobs are read only at C8-S16 and the gate, and never once an ID is stored (Core Rule 8). FlagRegistry checks the
secret-route knobs at boot; a failure is a boot error naming the route (Y1-P1-T03).

| Knob | Default | Safe range | What it affects | Rationale / source |
|---|---|---|---|---|
| `secret_route_enabled.WITNESS` | false | false until the post-1.0 secret-route design ships (a GDD revision; never enabled while `family` would be RESERVED) | whether R1 can transform into Witness Protocol | user decision 2026-11-11, design review round 9 (Counts) |
| `secret_route_enabled.CROWNLESS`, `.FIRSTWAKE` | false | false until their post-1.0 content ships and their family is designed (never enabled while `family` would be RESERVED) | whether R2 / R3 can transform | Story Bible §5 "post-1.0 candidates"; user decision 2026-11-11 (Counts) |
| `secret_prerequisites[route]` (list of flags) | WITNESS: `WITNESS_PROTOCOL_FOUND`, `OLD_WITNESS_SIGNATURE`, `WITNESS_SEATS` (PM:11215-11217); CROWNLESS: `CROWN_COORDINATES`, `EMPTY_THRONE_FOUND`, `CROWN_SNAPSHOT_FOUND`, `NO_CROWN_CHARTER` (PM:11242-11245); FIRSTWAKE: `OLD_HOME_MESSAGE`, `FOURTH_HYMN_FOUND`, `EXTERNAL_PING_FOUND`, `EXTERNAL_CARRIER` (PM:11270-11273) | ≥ 2 flags per route ("multiple secret quests"); the three lists disjoint; every flag known to FlagRegistry; no unlock flag in any list | how hard a secret route is to reach; when its signpost and invocation scene appear | PM:706; the production master's "Required flag" lines |
| `secret_unlock_flag[route]` | WITNESS: `SEVEN_WITNESSES_AVAILABLE` (PM:11218); CROWNLESS: `CROWNLESS_AVAILABLE` (PM:11246); FIRSTWAKE: `FIRST_WAKE_AVAILABLE` (PM:11274) | the route's last "Required flag"; set when the route's invocation scene plays | which flag records that the invocation scene played | PM:8055; PM:8199-8201 (Chapter 9 ledger "Secret unlock" lines) |

Not knobs (fixed by design): the three axes and their values, the invalid set R1-R3 (changing it needs a GDD
revision: it changes the counts, `transform()` and the ROADMAP §12.2 / Story Bible counts), the storyline ID format,
the family mapping, the `lock_pass` test, the rule that a lock or renegotiation vote always passes (PM:6990-6991),
the rule that timing never changes the storyline ID, the rule that the final authorization changes nothing, and the
rule that every lock scene offers all three values. No seed has a numeric weight; values come only from the lock
scenes and renegotiations (PM:6987-6989).

## Cross-References

- `design/gdd/storyline-lifecycle.md` — the Y2-PP-T17 lifecycle contract (scenes, transitions, runtime ACs)
- `AethelgardPrototype/story/STORY_BIBLE.md` §4 (cast, companion status), §5 (axes, ending families, timing,
  Act 1 flag tables)
- `AethelgardPrototype/ROADMAP_10_YEAR.md` §12.2 (storyline architecture), §12.4 (time-sensitive world)
- `AethelgardPrototype/story/source/PRODUCTION_MASTER_2.1.md`: axes 634-695, secret axis 697-707, validity 709-723,
  side arcs 1902-4459, Chapter 8 locks 6980-7153, Secret Quest 09 7517-7519, axis validation 7522-7537, Act 3
  ledger 7565-7590, invocation scenes 8027-8064, Chapter 9 ledger and end 8188-8213, boss phases 8610-8645, C10-S15
  seven-witness protocol 8691-8710, final authorization 8786-8800, route matrix 8973-11126, secret routes
  11211-11274, route matrix validation 11293-11306
- Also cited: 686 (RELEASE), 6987-6991 (vote influence), 7034-7040 (Kaelen's final permission under YOU), 7036-7069
  (Authority proposals and locks), 7093-7095 (Deleted proposals), 8408 (C10-S06/S09 YOU lines), 5981 / 6664 / 7588
  (Witness offer prerequisites)
- `AethelgardPrototype/DESIGN_PILLARS.md` P3, P5, P8; `AethelgardPrototype/AGENTS.md` (protected world-map logic)
- Research input: `production/qa/evidence/2026-11-storyline/research_draft.md`

## Acceptance Criteria

**Document-level (document lint, Config/Data, advisory) — checked today by
`production/qa/evidence/2026-11-storyline/check_storyline_axes.py`.** The checker compares the text with constants
pinned by the same author; it shows the document is internally consistent and unchanged where pinned, not that the
state machine is correct. Correctness evidence is runtime ACs 5-16, starting with a non-shipping reference model of
the Formulas and a walk of the lifecycle transitions (Open Question 16).

1. The 27-row table's (authority, faction, deleted) set equals the 3×3×3 product; each id is
   `SL-{authority}-{faction}-{deleted}`; the invalid rows are exactly the rules table's combinations, and the
   Formulas' `invalid(A, F, D)` set equals them too; each rule's quoted contradiction appears on its cited PM line;
   each valid row's source line is its own `# STORYLINE <abbreviation>` heading and its danger line the first
   "Primary danger:" line after that heading; each invalid row's source is an `Invalid V` line and its danger —;
   every `valid_count:` and `SOLE n, BOUND n, NONE_AUTH n` statement, and every line of the Counts block, equals the
   table and its own arithmetic.
2. The seed map's flag set equals the checker's 26-flag list; each flag occurs outside a comment in
   `AethelgardPrototype/scripts` or `dialogue`; every source cell resolves; axis seeds have direction `+` or `−` and
   `overturnable` = `until:lock:<its axis>`; modifier rows have `no`; timing rows have direction `0` and `no`.
3. The secret table has exactly the three secret ids, each naming the rule and abbreviation it transforms per
   PM:8784 (WITNESS ↔ YHR, CROWNLESS ↔ NAL, FIRSTWAKE ↔ NCL) with that rule's combination, and `transform()` maps
   the same rules to the same routes; each route's `secret_prerequisites` followed by its `secret_unlock_flag`
   equals the production master's "Required flag" list for it; the family map in Core Rule 10 and in `family()`
   equals {YOU → SOLE, SHARED → BOUND, NONE → NONE_AUTH}; the side-storyline table has arcs 01-12, each `pm_line` an
   "Axis effect:" line, in arc order; the composer record has exactly the fields storyline_phase, storyline_id,
   root_phase, authority, faction, deleted, secret_route, family, axis_revised, lock_negotiated, retraction_log,
   beats_played, companions_present, regions_completed, timing_flags, act1_pace and act2_pace/act3_pace/act4_pace,
   each with its pinned allowed values and writer; `storyline_phase` allows exactly the phase table's values;
   `reachable_1_0` equals the valid rows plus the 1.0 secret rows (none).
4. The Formulas define `storyline_id(A, F, D, I)` with exactly those four inputs and its pinned body, which names no
   timing, pace or companion input; `invalid`, `lock_pass`, `storyline_phase` and `family` match their pinned
   bodies; the Core Rules are numbered 1-12 with their titles and pinned key sentences; the invariants table has
   rows I1-I9 as pinned; the Tuning Knobs table has exactly the four pinned knobs and defaults; every runtime
   criterion below names its blocking stories and uses only observables from the Observables table.

**Runtime observables** — pure functions over a composer record; the scene-level observables are in
`storyline-lifecycle.md`:

| observable | returns |
|---|---|
| `formula_id(A, F, D, I, knobs, flags)` | the Formulas' `storyline_id` for those inputs (no record, no stored ID) |
| `prereqs_met(T, knobs, flags)` | the Formulas' `prereqs_met` |
| `family(id)` | the Formulas' `family` |
| `phase_of(record, loaded, flags, position)` | the Formulas' `storyline_phase` |
| `axis(record, name)` | the record's value for `authority`, `faction` or `deleted` |
| `composer_modules(record, flags)` | the module ids the composer selects (ids defined by Y2-PP-T17) |
| `module_keys(flag)` | the module ids the route data keys to a flag |
| `scene_render(id)` | for a storyline ID, each story scene the route data plays (a production-master Scene ID `C<n>-S<m>` or boss id `B<n>`) mapped to a hash of its rendered text; a scene's shared hash is the one it has for every storyline |
| `ending_render(id)` | the ordered (ending module id, rendered-text hash) pairs the route data plays for a storyline ID |
| `story_plus_state(id)` | the set of Story+ unlock cases the route data creates for a storyline ID |
| `boot_errors(knobs, flags, build)` | the data errors FlagRegistry finds at boot for a build (`1.0` or later) |
| `load_check(record, flags, position)` | the data errors SaveService's load check reports for a save's record, flags and story position (Edge Case 16) |

**Runtime — each criterion names the stories that must land before it can run:**

5. For every (A, F, D) over {its three values, UNSET} (64 triples) and I ∈ {false, true} as a free formula input
   (128 cases), with every offer prerequisite set: with the default knobs, `formula_id` is `SL-A-F-D` for the 24
   valid triples whatever I, PENDING for the 37 triples with an UNSET axis whatever I, and CRISIS for the 3 invalid
   triples whatever I; with one route enabled at a time (synthetic knobs, formula level only), I true gives
   `SL-SECRET-<route>` for that route's own row (WITNESS on R1, CROWNLESS on R2, FIRSTWAKE on R3) and CRISIS for the
   other two invalid rows, so a swapped `transform()` fails. *Blocked by:* Y2-PP-T17 (unit-testable before the
   scenes exist).
6. For each invalid row with its route T enabled (synthetic knobs) and I true: each single-flag-missing subset of
   `secret_prerequisites[T]` → CRISIS; all set → `SL-SECRET-T`; all set with T disabled → CRISIS. *Blocked by:*
   Y2-PP-T17, Y1-P1-T03.
7. `prereqs_met` is false for a route whose list has fewer than two flags (including none) with every flag set, true
   for a list of exactly two flags with both set, and false for that list with one unset. *Blocked by:* Y2-PP-T17,
   Y1-P1-T03.
8. `family(id)` over every id: the 24 valid IDs per the family map; `SL-SECRET-WITNESS`, `SL-SECRET-CROWNLESS` and
   `SL-SECRET-FIRSTWAKE` → RESERVED; PENDING, CRISIS, the 3 invalid-row ids, the empty string, `SL-SECRET-BOGUS`, a
   lower-case valid id and a valid id with trailing characters → NO_FAMILY. *Blocked by:* Y2-PP-T17.
9. `phase_of(record, loaded, flags, position)` returns the stated phase for each Formulas example with its stated
   `loaded`, and for one fixture per phase other than DAMAGED (LEANING, PARTLY_LOCKED, CRISIS, VALIDATED, FIXED,
   FINAL), called with `loaded` false for CRISIS and true for the others; `load_check()` is empty for each of those
   six fixtures except CRISIS, which sits inside C8-S16 and so reports exactly {D9, D17}, and `phase_of` of the
   CRISIS fixture with `loaded` true is DAMAGED. For each active Edge Case 16 item (D1, D6-D9, D14-D17; D1, D7 and
   D14 one fixture per clause; D17 one fixture, for its before-commit clause, because its prefix clause is
   documentation) a fixture that differs from a valid fixture by exactly that one defect (a defect may change the
   several fields that keep the other items satisfied: the D7 new-value fixture changes a retraction entry's `new`
   and renames its beat to match) gives `phase_of(…, true)` DAMAGED and `load_check()` exactly {that item};
   `load_check()` gives the same result with every knob flipped. *Blocked by:*
   Y2-PP-T17, Y1-P1-T05, Y1-P1-T03.
10. Seeds never lock: a record holding any one of the 26 seed flags in `flags`, or one flag from each exclusive group,
    positioned before C8-S13 with no lock scene played, has `axis()` UNSET for all three axes and `phase_of` LEANING;
    no input of `phase_of` or `axis()` but the record's own fields sets an axis (the scene-level counterpart, a lock
    vote keeping the backed value whatever seeds are set, is `storyline-lifecycle.md` L-AC2). *Blocked by:*
    Y2-PP-T17, Y1-P1-T03.
11. Companions and timing: for one VALIDATED record per 1.0 family, the records with no companion and with all four,
    crossed with the timing sets {`act1_pace_early`, `ch1_bridge_saved`} and {`act1_pace_late`, `ch1_bridge_fell`},
    keep `storyline_id` and `family()` unchanged; `composer_modules()` holds no module of an absent companion; and
    the symmetric difference of `composer_modules()` between the two timing sets equals the union of
    `module_keys()` of the four timing flags. Kaelthas (Core Rule 11): with his trust condition false he is present
    on an ARCHIVE record and absent on a HEARTH and a CONTINUITY record; with it true he is present on all three.
    *Blocked by:* Y2-PP-T17.
12. Boot validation: `boot_errors(knobs, flags, build)` names the route when a `secret_prerequisites` list has fewer
    than two flags, two lists share a flag, a flag is unknown to FlagRegistry, an unlock flag appears in a
    prerequisites list, or any secret route is enabled in a `1.0` build; with the default knobs and build `1.0` it is
    empty. *Blocked by:* Y2-PP-T17, Y1-P1-T03.
13. Sole dissent (Core Rule 3): for one VALIDATED fixture per 1.0 family, each with `lock_negotiated` = {authority},
    {faction, deleted} and {}, and one SOLE fixture reached by renegotiation to YOU (`axis_revised` and
    `lock_negotiated` = {authority}): `composer_modules()` contains `sole_dissent` exactly for the SOLE fixtures whose
    `lock_negotiated` holds `authority`; `storyline_id` and `family()` are the same across a family's fixtures.
    *Blocked by:* Y2-PP-T17.
14. Pillar P3 (ROADMAP §2: a storyline changes ≥ 3 story scenes, has its own ending sequence and its own Story+
    state), over the 24 storylines reachable in 1.0, by rendered text, not by ids: for every ID at least 3 scenes of
    `scene_render(id)` differ from that scene's shared hash; for every pair of distinct IDs at least 1 scene of
    `scene_render()` differs, `ending_render()` differs in at least one rendered-text hash (different module ids with
    the same text do not count), and `story_plus_state()` differs. The smallest number of scenes in which two
    distinct IDs differ is reported; a pairwise threshold above 1 is Open Question 13. *Blocked by:* Y2-PP-T17.
15. Pillar P5 tracking (a closing condition of Y2-PP-T17): Y2-PP-T17 lists every flag the nine 1.0 side arcs set
    in a `side_arc_flags` table (arc, flag, source line); the set of those flags minus the flags of the seed map (or
    its successor table) is empty, each such row has a `pushes` target and a direction, and the checker's flag list
    includes it. *Blocked by:* Y1-P1-T03 (the arc flags exist in FlagRegistry).
16. Comprehension (Player Fantasy, "Authorship, not a menu"; playtest, Integration): in a blind playtest of
    Chapter 8 with at least 5 testers, each starting from a fixture save with a different set of Act 1 seeds, at
    least 70% of testers, asked after each lock scene, name the earlier choice that at least one voiced argument
    referred to; and at least 70% of testers who meet the C8-S16 crisis say in their own words which faction refused
    and what it would not accept. The report is retained in `production/qa/` with the fixture list. The 70% bar
    follows the concept's Gate 1 test style; below it, the seed arguments or red lines are revised, not the bar.
    *Blocked by:* Y2-PP-T17.

The scene-level criteria (locks, red lines, crisis, the commit and save rule, renegotiation, gate, secret routes
closed, final authorization, saves, visual evidence, the route bot) are `storyline-lifecycle.md` L-AC1 onward.

## Open Questions

1. **NG+ carry-over:** do axis leanings or the previous storyline affect a new cycle? (NG+ design, owner open.)
2. **ROADMAP §12.2 wording:** it says secret quests "add hidden 4th axis values"; the production master says they
   replace the three invalid combinations (PM:697-699). Correct the ROADMAP line? (Needs the user's OK.)
3. **PM:8743** gives YOU + HEARTH + RESTORE a route title although that combination is invalid; keep it as the
   crisis scene's name, or drop it?
4. **Act 1 late pace:** `dialogue/ch2/act1_end.dlg` sets `act1_pace_late` for taking the caravan route; PM:2871 ties
   late to missed rests and ignored warnings. Resolve in S06b (time model).
5. **`ch1_oakhaven_warned_leaders`** is missing from the exclusive flag groups and no script reads it; logged, not
   fixed (protected story code). The Oakhaven flags have no faction mapping yet.
6. **Companion count:** ROADMAP names 8 companions; the Story Bible has 4 with Companion status. The production
   master also lets Nema, Seven, Rook and Kaito stay or leave on any route (PM:7534-7537), with per-companion
   secret-route reactions (PM:11229-11236). This GDD uses the 4; `companions_present` grows when the others are
   confirmed.
7. **Systems index:** `design/gdd/systems-index.md` does not exist; `/map-systems` creates it later.
8. **Story Bible §5** gives the Consent family the God King "loses its health bar" fight, which the production
   master gives to Crownless (PM:11247); a separate Story Bible fix.
9. **Truth strategy** (Seraphina's disclosure) is its own composer module in the production master (PM:8739); owner
   Y2-PP-T17.
10. **Seed readings kept despite review objections (2026-11-10):** `ch1_aldric_kill_unsure` → SHARED may read as
    deferral ("don't decide it tonight", `aldric.dlg:90`); `ch2_data_wraith_destroyed` → RELEASE is a unilateral
    destruction while RELEASE ends involuntary preservation (PM:686, PM:7094); `ch1_root_purge` is a non-consensual
    rewrite that could argue for YOU instead of Hearth; `ch2_data_wraith_absorbed` → CHOOSE is unilateral and held
    in Kaelen's own Root layer (PM:2468), which could argue for YOU. YOU also has three `+` seeds against one each
    for SHARED and NONE, so YOU passes clean most easily, and `sole_dissent` (the one audible negotiated result)
    is the least likely case. Round 9 (narrative-director): `ch1_root_purge` → HEARTH contradicts its own source
    (PM:663, "if he survives with agency intact"), and `ch1_knight_spared` fits it better. Revisit in a narrative
    pass, with the AC16 playtest as evidence.
11. **Reserved: post-boss reconsideration.** PM:8791 allows "one last lawful reconsideration" if final circumstances
    changed drastically. Cut from this design (user decision 2026-11-10) because boss phases 2-4 already read every
    axis (PM:8611-8616). If Y2-PP-T17 ever authors a trigger, it needs a GDD revision, and can change at most the
    epilogue and Story+ state.
12. **Deferred to Y2-PP-T17:** the `sole_dissent` module text; whether the ledger Variants and Policies
    (PM:7569-7582) later make `lock_negotiated` visible beyond `sole_dissent`. The Witness items of revision 8 (the
    witness institution, signposts, candidates, the vote, the stand-down) moved to Open Question 15.
13. **P3 baseline and the storyline cut order.** (a) AC14 now tests rendered text: ≥ 3 non-shared scenes per ID and
    a pairwise minimum of 1 scene (round 9). The all-pairs ≥ 3 test stays dropped because the design never shows that
    a single Faction or Deleted value touches three scenes; set a higher pairwise threshold once Y2-PP-T17 counts the
    scenes each axis value varies (PM:8975 promises five changes per route). (b) `design/gdd/game-concept.md` lists "storylines 27→18" in the cut order and "~6 storylines" for the
    smaller game. The axes, their values and R1-R3 are not knobs here, so neither cut has a mechanism: collapsing one
    Deleted value would give 3 × 3 × 2 = 18 combinations but changes R1-R3, `transform()` and every count. Decide the
    mechanism, or drop the cut, before a budget cut can invoke it.
14. **1.0 scope of the families and P3 (user decision 2026-11-11).** 1.0 ships 24 storylines in three families;
    the Story Bible §5 decision line ("the four-family model below is adopted; ... the 24 + 3 storyline IDs") and
    P3's "24 + 3" stay the design total. Whether the Story Bible and `DESIGN_PILLARS.md` should say that Consent and
    the secret storylines are post-1.0 is a separate edit for the user (not made in revision 9).
15. **Secret routes, post-1.0, designed as one mechanism.** Revision 8's Witness design (the R1 deferral, the
    invocation at C9-S19 or the gate, the witness vote at C10-S15 with threshold 5, the stand-down, the Consent
    variants) was removed in revision 9 after design review round 9 found a further state defect in it (git commit
    084ccb0 holds it). The post-1.0 design must answer, for all three routes at once: where an invocation is offered,
    given that each route's last prerequisite is set after C8-S16 (PM:7586-7588) — moving Secret Quest 09's
    prerequisites before C8-S16 would let the crisis offer the invocation directly; whether a provisional coalition
    can hold without the refusing faction (PM:7144, PM:7153); who names the witnesses (PM:7519: the Assembly) and the
    player's part in the threshold (PM:8707); whether the deleted seat can refuse a restoration (PM:714, PM:7093,
    PM:11235); who holds Root after a Consent act (PM:705); what a vote that falls short leaves to Story+ (PM:11220);
    and how a witness vote avoids being a solved puzzle when stances are visible.
16. **Reference model (round 9 process decision).** Built 2026-11-17 (non-shipping,
    `production/qa/evidence/2026-11-storyline/reference_model.py`, log `reference_model.log`): `formula_id`,
    `lock_pass`, `phase_of`, `load_check` and `crisis_offers`, with a breadth-first walk of the lifecycle transitions.
    Round 10 ran lean against its output (findings F1-F10; F1, F2, F3, F4, F6 and F9 are reflected in revision 10).
    Still open: the owner of re-running it (proposed: Y1, the story that lands SaveService's load check), a fixture
    for the coordinated D7 new-value edit, and a seeded defect for each item added since the log.
17. **Load-check scope (user decision 2026-11-17).** The load check promises that every save play writes loads and
    that a loaded record is consistent with the lock order (D16, D17). Not promised: edited-save integrity (reference
    model F5: `lock_negotiated` against `lock_pass`, a retraction entry's `withdrawn_item` and `scene`) and the
    coupling of `root_phase` to the story position (F7). The model found 61,440 accepted records that cannot reach
    FINAL (a record whose `root_phase` is not FINAL, positioned after the final authorization), but that count rests
    on its modelling choice M8 (Story+ has no route back to the final authorization), which is lifecycle Open
    Question 2. Revisit when Y1-P1-T03 defines real story positions and combat settles Story+ replay: then decide
    whether a `root_phase`-versus-position item (candidate D18) is worth its fixtures.
18. **A live CRISIS record outside C8-S16 (reference model, found while repairing F1).** `storyline_phase` exempts
    D9 and D17's before-commit clause from every live record, so a live record with an invalid row, nothing stored
    and a story position past C8-S16 reads CRISIS, not DAMAGED, and reaches the gate, whose table has no CRISIS row
    (the model returns a gate error). No play path produces it (I2: the crisis cannot be left), so it is the same
    defence-in-depth class as T6. Decide whether the exemption should read "a live record positioned inside C8-S16"
    instead of "a live record", so that such a record is DAMAGED and the gate's DAMAGED row turns it back. Not
    changed in revision 10.
