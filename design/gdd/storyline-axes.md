# Storyline Axes

> **Status**: Draft (revision 15, an erratum after the lifecycle review of 2026-11-18 (user decision 2026-11-19):
> `kaelen_commitment` added to the composer record, the stored-field list, AC3, D0 and AC9, and the protected touchpoints' C9-S18 wording
> corrected; the round-15 approval of revision 14 does not cover these lines. Revision 14, after design review round
> 14, scope frozen to its six blockers (Open Question 20):
> the purge row's reason re-grounded on its own scene, `story_position` a record field with a hub-safe legacy
> derivation, `act1_pace` defaults to UNSET, AC9's clause ids listed, AC11's mirror sentence removed, AC15 Logic with
> a `secret:<route>` push; main-story seeds named as a class (Open Question 21). Revision 13, after design review
> round 13: the purge argues against YOU and the Authority
> seeds state one discriminator, arc 08 pushes Faction in 1.0, the story position is written at every entry point
> (NG+, chapter select by position, legacy saves derived once), D0 type-checks `beats_played` and leaves its
> membership to D14, one knob-read scope, six citation and consistency fixes. Revision 12: Authority seeds against
> unilateral history, Kaelthas outside the 1.0 companion set, the story-position contract, D0's one-entry
> `retraction_log` cap. Static core unchanged since revision 4 except the 1.0 scope of the secret storylines)
> **Author**: Claude (narrative-director research) with the project lead
> **Last Updated**: 2026-11-19
> **Last Verified**: 2026-11-18
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
audible (Core Rule 3). Ten of the twelve side storylines are to push the axes in 1.0 once Y2-PP-T17 maps their
flags (AC15; the seed map holds none yet; arcs 05 and 09 feed only post-1.0 routes), and timing changes scenes and
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
  (ROADMAP §12.2 "nothing important is lost silently"). A player who completes the First Wake leads hears the signal
  decrypt at C9-S18, and it is logged, not answered: the fiction never tells them they found nothing.

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
  (PM:8057-8064). None unlocks a route in 1.0 (Core Rule 6); C9-S18 plays in 1.0 in the form Core Rule 6 states.
- **ID-lock gate**: every entry and re-entry into Root of Heaven (Chapter 10) — the story graph after the Chapter 9
  end, world-map or free travel, and loading a save positioned inside Root of Heaven. It opens only when a
  storyline ID is stored. The stored-ID check is this GDD's mechanism for the sources' "must revise one axis before
  Root of Heaven" (PM:722) and "intercepted before final boss" (PM:11305); it runs before the Chapter 9 End's "Root
  of Heaven gate opens" (PM:8206-8207).
- **Final authorization**: the immediate post-boss scene (PM:8786-8794). The world asks for the authorization
  result, the system displays the chosen structure, and the player confirms execution. It changes nothing.
- **Story position**: the save's place in the story, one id from this ordered list (earliest first): `PRE_C8`
  (anywhere before C8-S13), `S13_OPEN`, `S13_DONE`, `S14_OPEN`, `S14_DONE`, `S15`, `S16_OPEN`, `S16_DONE`, `CH9`,
  `ROOT`, `ROOT_LEFT`, `FINAL_AUTH_OPEN`, `FINAL_DONE`, `STORY_PLUS`, `ROOT_STORY_PLUS`. `<scene>_OPEN` is inside the
  scene before its commit checkpoint; `<scene>_DONE` is the commit checkpoint and everything after it until the next
  id. `ROOT` is inside Root of Heaven before the final authorization, `ROOT_LEFT` outside it after a first entry,
  `ROOT_STORY_PLUS` inside it in Story+. The position is the record field `story_position` (Composer input record),
  written by each commit checkpoint and
  each story-graph step that crosses into the next id, never derived from the current scene file on load; D16 and
  D17 compare it by list index, and every id they compare against precedes `CH9`. The other writers are a new game
  and the NG+ reset (`PRE_C8`) and chapter select (the position of its entry scene; `storyline-lifecycle.md`
  Chapter select). One exception to "never derived": a save of a schema version before these fields holds no
  position, so SaveService derives it once, while defaulting that save (Edge Case 8), in this order: the save's
  free-travel story scene, else its own scene, each through the scene-to-id map, which holds story scenes only and
  never a hub (a hub is visited in every chapter, and a death revives the player in one); else its chapter number,
  below 8 → `PRE_C8` and 9 or above → `CH9`. A Chapter 8 save that no mapped story scene places is left with no
  position, which D0 refuses (user decision 2026-11-18, design review round 14). SaveService (Y1-P1-T05) carries the
  stored position on every save the code writes (a chapter scene, a hub, free travel), and FlagRegistry
  (Y1-P1-T03) checks the scene-to-id map at boot. The list is the reference model's `POSITIONS` (Open Question 16);
  finer ids (a boss id, for candidate D18) may be added inside an id, never across one (user decision 2026-11-17,
  design review round 12).

### Core Rules

1. **Three axes, one value each.** Authority ∈ {YOU, SHARED, NONE}; Faction ∈ {HEARTH, ARCHIVE, CONTINUITY};
   Deleted ∈ {RESTORE, RELEASE, CHOOSE}; each starts UNSET (SaveService writes UNSET for a new game, and for a save
   of a schema version before these fields, which the load check then refuses if it is positioned past a lock scene:
   Edge Case 16, D16). Once a storyline ID is stored, each axis holds exactly one value (PM:7522-7524, "Axis
   validation").
2. **Seeds are arguments, never gates.** Act 1 seeds are the leanings mapped for 1.0 (the 26 flags below);
   side storylines, companion persuasion and faction support become leanings the same way once Y2-PP-T17 maps their
   flags (AC15), and so do main-story choices after Act 1 (main-story seeds; the first known is the Chapter 4 Null
   Court promise, `AethelgardPrototype/scripts/chapter4/ch4_null_court.gd:125-136`, mapped by Open Question 21): each axis seed makes its lock scene voice an argument for (`+`) or against (`−`) its value
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
   through negotiations.", PM:6990). The test reads only which flags are set: no count, no weight. Faction has one
   `−` seed (`ch1_knight_killed`, against HEARTH) and Authority three, all against YOU (`ch1_aldric_kill_justified`,
   `ch1_root_purge`, `ch2_seraphina_showoff`): power used on others without answering for it argues against keeping
   Root alone (Story Bible §1, "Capability is not legitimacy"; user decisions 2026-11-17, design review rounds 12 and
   13). Deleted has
   none, so a Deleted vote is clean exactly when the one wraith seed backs its value. Side-storyline flags join the
   test once Y2-PP-T17 maps them per flag. In 1.0 `lock_negotiated`
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
   at C8-S16; the journal shows no signpost or hint for it; its invocation scene does not unlock it and its unlock
   flag is never set. C9-S18 keeps the source's condition (PM:8027-8043; user decision 2026-11-17, design review
   round 11): with every FIRSTWAKE offer prerequisite set it plays its decrypted form (the packet, "HELLO", the
   checksum, Seraphina's beat) and ends with the signal logged, not answered, in place of "This unlocks secret path"
   (new content, owner Y2-PP-T17); otherwise the packet remains noise (PM:8043). C9-S19 and C9-S20 do not play. Its Chapter
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
   the final authorization concludes. Every entry and re-entry into Root of Heaven runs the gate check: with an ID stored
   and the phase not DAMAGED the gate is open (also after the boss and in Story+); a DAMAGED record is turned back as a
   data error whether or not it holds an ID (lifecycle S6); before the three locks it turns the player back in the fiction
   (the Assembly has not decided; `storyline-lifecycle.md` S6). In 1.0 that turn-back is defence in depth: Root of
   Heaven is entered only after the Chapter 9 end, so a record at the gate with an UNSET axis is already refused on
   load (D16), and a live one is a story-graph defect that the gate turns back as well (lifecycle T6; the reference
   model's walk never fires it). A save positioned past a lock scene with that axis UNSET (one made before these
   fields existed) is unsupported and does not load (Edge Case 16, D16; user decision 2026-11-10); no runtime
   catch-up exists. Every save that play writes loads (I9), and the load check keeps a loaded record consistent with
   the lock order (D16, D17). What the check refuses follows one inclusion rule (Edge Case 16; user decision
   2026-11-17, Open Question 17): it never promises edited-save integrity, only that no accepted record crashes the
   composer, strands the player or breaks an invariant. The refusal holds only while no player-facing build has such
   saves (`storyline-lifecycle.md` Legacy saves).
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
    (PM:7529-7537, PM:11302); a companion leaves through relationship flags (Edge Case 1), never through an axis, and
    no axis is read for presence. The 1.0 companion set is Elara, Seraphina and Lyra. Kaelthas is not in it: Chapter
    3 always ends his alliance in betrayal (`AethelgardPrototype/scripts/chapter3/ch3_kaelthas_betrayal.gd:35,89`
    set `ch3_kaelthas_betrayed` on the allied path, and nothing clears it), so the source's "can remain companion
    outside Archive if trust supports it" (PM:7533) has no 1.0 save to apply to. That rule, the only axis read a
    companion would have, is reserved for redemption content (Open Question 19; user decision 2026-11-17, design
    review round 12, superseding the trust condition `ch3_kaelthas_allied` set and `ch3_kaelthas_betrayed` unset
    decided in round 11). Kaelthas's own Chapter 9 and 10 lines, which read `ch3_kaelthas_allied`, are unaffected.
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
| I5 | No soft-lock under any knob value or patch: every state without a stored ID either is before the locks, offers a renegotiation that reaches a valid row, or is a data error refused at the gate (a DAMAGED record, which play never writes) | 5, 8 |
| I6 | Nothing important is lost silently: no hint points at an unshipped route; arcs 05, 08, 09 get a visible epilogue line in 1.0 | 6 |
| I7 | A valid row is held to its word | 7 |
| I8 | Family = the Authority value; a secret storyline's family is RESERVED until its route ships | 10 |
| I9 | Every transition commits its record writes and its beat id as one atomic checkpoint; no save exists inside a lock scene, the crisis or the final authorization before its commit | 3, 5, 8, 9 |

`storyline_phase` is derived, never stored (Formulas), as are `secret_route` and `family`; of the lifecycle fields
the record stores the axes, `storyline_id`, `root_phase`, `axis_revised`, `lock_negotiated`, `retraction_log`,
`beats_played`, `kaelen_commitment` and `story_position`; the Edge Case 16 check reads all of them with the saved flags, and once it
passes the phase depends only on the axes, `storyline_id` and `root_phase`.

| phase | meaning | gate |
|---|---|---|
| LEANING | every axis UNSET | turns the player back |
| PARTLY_LOCKED | one or two axes locked | turns the player back |
| CRISIS | three axes locked on an invalid row, nothing stored: exists only inside C8-S16, never saved | — (inside C8-S16) |
| VALIDATED | an ID stored, `root_phase` OUTSIDE | open |
| FIXED | an ID stored, `root_phase` INSIDE (first entered Root of Heaven; stays INSIDE if the player leaves) | open (re-entry) |
| FINAL | the final authorization concluded: execution confirmed | open (Story+) |
| DAMAGED | the record holds an item of Edge Case 16: never saved by play; a load that yields it is refused | a loaded record never reaches the gate; a live one is turned back as a data error with a reload prompt (lifecycle S6) |

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
| SL-YOU-HEARTH-RESTORE | YOU | HEARTH | RESTORE | invalid | — | R1 | PRODUCTION_MASTER_2.1.md:713 | — | Elara, Seraphina, Lyra |
| SL-YOU-HEARTH-RELEASE | YOU | HEARTH | RELEASE | valid | SOLE | — | PRODUCTION_MASTER_2.1.md:8978 | PRODUCTION_MASTER_2.1.md:8987 | Elara, Seraphina, Lyra |
| SL-YOU-HEARTH-CHOOSE | YOU | HEARTH | CHOOSE | valid | SOLE | — | PRODUCTION_MASTER_2.1.md:9071 | PRODUCTION_MASTER_2.1.md:9080 | Elara, Seraphina, Lyra |
| SL-YOU-ARCHIVE-RESTORE | YOU | ARCHIVE | RESTORE | valid | SOLE | — | PRODUCTION_MASTER_2.1.md:9164 | PRODUCTION_MASTER_2.1.md:9173 | Elara, Seraphina, Lyra |
| SL-YOU-ARCHIVE-RELEASE | YOU | ARCHIVE | RELEASE | valid | SOLE | — | PRODUCTION_MASTER_2.1.md:9257 | PRODUCTION_MASTER_2.1.md:9266 | Elara, Seraphina, Lyra |
| SL-YOU-ARCHIVE-CHOOSE | YOU | ARCHIVE | CHOOSE | valid | SOLE | — | PRODUCTION_MASTER_2.1.md:9350 | PRODUCTION_MASTER_2.1.md:9359 | Elara, Seraphina, Lyra |
| SL-YOU-CONTINUITY-RESTORE | YOU | CONTINUITY | RESTORE | valid | SOLE | — | PRODUCTION_MASTER_2.1.md:9443 | PRODUCTION_MASTER_2.1.md:9452 | Elara, Seraphina, Lyra |
| SL-YOU-CONTINUITY-RELEASE | YOU | CONTINUITY | RELEASE | valid | SOLE | — | PRODUCTION_MASTER_2.1.md:9536 | PRODUCTION_MASTER_2.1.md:9545 | Elara, Seraphina, Lyra |
| SL-YOU-CONTINUITY-CHOOSE | YOU | CONTINUITY | CHOOSE | valid | SOLE | — | PRODUCTION_MASTER_2.1.md:9629 | PRODUCTION_MASTER_2.1.md:9638 | Elara, Seraphina, Lyra |
| SL-SHARED-HEARTH-RESTORE | SHARED | HEARTH | RESTORE | valid | BOUND | — | PRODUCTION_MASTER_2.1.md:9722 | PRODUCTION_MASTER_2.1.md:9731 | Elara, Seraphina, Lyra |
| SL-SHARED-HEARTH-RELEASE | SHARED | HEARTH | RELEASE | valid | BOUND | — | PRODUCTION_MASTER_2.1.md:9815 | PRODUCTION_MASTER_2.1.md:9824 | Elara, Seraphina, Lyra |
| SL-SHARED-HEARTH-CHOOSE | SHARED | HEARTH | CHOOSE | valid | BOUND | — | PRODUCTION_MASTER_2.1.md:9908 | PRODUCTION_MASTER_2.1.md:9917 | Elara, Seraphina, Lyra |
| SL-SHARED-ARCHIVE-RESTORE | SHARED | ARCHIVE | RESTORE | valid | BOUND | — | PRODUCTION_MASTER_2.1.md:10001 | PRODUCTION_MASTER_2.1.md:10010 | Elara, Seraphina, Lyra |
| SL-SHARED-ARCHIVE-RELEASE | SHARED | ARCHIVE | RELEASE | valid | BOUND | — | PRODUCTION_MASTER_2.1.md:10094 | PRODUCTION_MASTER_2.1.md:10103 | Elara, Seraphina, Lyra |
| SL-SHARED-ARCHIVE-CHOOSE | SHARED | ARCHIVE | CHOOSE | valid | BOUND | — | PRODUCTION_MASTER_2.1.md:10187 | PRODUCTION_MASTER_2.1.md:10196 | Elara, Seraphina, Lyra |
| SL-SHARED-CONTINUITY-RESTORE | SHARED | CONTINUITY | RESTORE | valid | BOUND | — | PRODUCTION_MASTER_2.1.md:10280 | PRODUCTION_MASTER_2.1.md:10289 | Elara, Seraphina, Lyra |
| SL-SHARED-CONTINUITY-RELEASE | SHARED | CONTINUITY | RELEASE | valid | BOUND | — | PRODUCTION_MASTER_2.1.md:10373 | PRODUCTION_MASTER_2.1.md:10382 | Elara, Seraphina, Lyra |
| SL-SHARED-CONTINUITY-CHOOSE | SHARED | CONTINUITY | CHOOSE | valid | BOUND | — | PRODUCTION_MASTER_2.1.md:10466 | PRODUCTION_MASTER_2.1.md:10475 | Elara, Seraphina, Lyra |
| SL-NONE-HEARTH-RESTORE | NONE | HEARTH | RESTORE | valid | NONE_AUTH | — | PRODUCTION_MASTER_2.1.md:10559 | PRODUCTION_MASTER_2.1.md:10568 | Elara, Seraphina, Lyra |
| SL-NONE-HEARTH-RELEASE | NONE | HEARTH | RELEASE | valid | NONE_AUTH | — | PRODUCTION_MASTER_2.1.md:10652 | PRODUCTION_MASTER_2.1.md:10661 | Elara, Seraphina, Lyra |
| SL-NONE-HEARTH-CHOOSE | NONE | HEARTH | CHOOSE | valid | NONE_AUTH | — | PRODUCTION_MASTER_2.1.md:10745 | PRODUCTION_MASTER_2.1.md:10754 | Elara, Seraphina, Lyra |
| SL-NONE-ARCHIVE-RESTORE | NONE | ARCHIVE | RESTORE | valid | NONE_AUTH | — | PRODUCTION_MASTER_2.1.md:10838 | PRODUCTION_MASTER_2.1.md:10847 | Elara, Seraphina, Lyra |
| SL-NONE-ARCHIVE-RELEASE | NONE | ARCHIVE | RELEASE | invalid | — | R2 | PRODUCTION_MASTER_2.1.md:715 | — | Elara, Seraphina, Lyra |
| SL-NONE-ARCHIVE-CHOOSE | NONE | ARCHIVE | CHOOSE | valid | NONE_AUTH | — | PRODUCTION_MASTER_2.1.md:10931 | PRODUCTION_MASTER_2.1.md:10940 | Elara, Seraphina, Lyra |
| SL-NONE-CONTINUITY-RESTORE | NONE | CONTINUITY | RESTORE | valid | NONE_AUTH | — | PRODUCTION_MASTER_2.1.md:11024 | PRODUCTION_MASTER_2.1.md:11033 | Elara, Seraphina, Lyra |
| SL-NONE-CONTINUITY-RELEASE | NONE | CONTINUITY | RELEASE | invalid | — | R3 | PRODUCTION_MASTER_2.1.md:717 | — | Elara, Seraphina, Lyra |
| SL-NONE-CONTINUITY-CHOOSE | NONE | CONTINUITY | CHOOSE | valid | NONE_AUTH | — | PRODUCTION_MASTER_2.1.md:11117 | PRODUCTION_MASTER_2.1.md:11126 | Elara, Seraphina, Lyra |

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

Every flag below is set in `AethelgardPrototype/dialogue` or `scripts` (26 flags in 28 rows: a flag may push a
modifier and an axis, one row each, never two axes). `direction` for an axis seed:
`+` makes the axis's lock scene voice an argument for the value, `−` an argument against it (the other two values
are unaffected). For a modifier, `+` / `−` is the sign of the change the flag records (for a set such as
`companions_present`, in or out of the set). `0`: the flag is read as it is and leans nowhere (timing selectors and
neutral choices). `overturnable`: an axis seed's argument is voiced until its axis's lock scene resolves
(`until:lock:faction`, `until:lock:authority`, `until:lock:deleted`); it never holds a value. A modifier or timing
row is `no`. A flag that feeds only a post-1.0 secret route (Core Rule 6) pushes `secret:<route>` with direction `0`
and `no`; the Act 1 map holds none, and side-arc flags join this way under AC15. Rows marked (J) are judgement calls with no explicit source statement of direction, approved by the
user.

| flag | pushes | direction | overturnable | source |
|---|---|---|---|---|
| act1_report_local | faction:HEARTH | + | until:lock:faction | PRODUCTION_MASTER_2.1.md:2856 |
| act1_report_archive | faction:ARCHIVE | + | until:lock:faction | PRODUCTION_MASTER_2.1.md:2857 |
| act1_report_command | faction:CONTINUITY | + | until:lock:faction | PRODUCTION_MASTER_2.1.md:2858 |
| ch2_seraphina_truth | modifier:seraphina_relationship | + | no | dialogue/ch2/command_hall.dlg:22 |
| ch2_seraphina_truth | authority:SHARED | + | until:lock:authority | dialogue/ch2/command_hall.dlg:23 (J) |
| ch2_seraphina_cautious | modifier:seraphina_relationship | 0 | no | dialogue/ch2/command_hall.dlg:31 |
| ch2_seraphina_showoff | modifier:seraphina_relationship | − | no | dialogue/ch2/command_hall.dlg:40 |
| ch2_seraphina_showoff | authority:YOU | − | until:lock:authority | dialogue/ch2/command_hall.dlg:46 (J) |
| ch2_seraphina_recruited | modifier:companions_present | + | no | PRODUCTION_MASTER_2.1.md:3123 |
| ch2_seraphina_stayed | modifier:companions_present | − | no | PRODUCTION_MASTER_2.1.md:3125 |
| ch2_seraphina_rejected | modifier:companions_present | − | no | PRODUCTION_MASTER_2.1.md:3127 |
| ch2_data_wraith_restored | deleted:RESTORE | + | until:lock:deleted | dialogue/ch2/underground.dlg:63 |
| ch2_data_wraith_destroyed | deleted:RELEASE | + | until:lock:deleted | dialogue/ch2/underground.dlg:64 (J) |
| ch2_data_wraith_absorbed | deleted:CHOOSE | + | until:lock:deleted | PRODUCTION_MASTER_2.1.md:2468 (J) |
| ch1_knight_killed | faction:HEARTH | − | until:lock:faction | PRODUCTION_MASTER_2.1.md:663 (J) |
| ch1_knight_spared | modifier:aldric_restrained | + | no | PRODUCTION_MASTER_2.1.md:1806 |
| ch1_root_purge | authority:YOU | − | until:lock:authority | dialogue/ch1/aldric.dlg:57 (J) |
| ch1_aldric_kill_owned | authority:YOU | + | until:lock:authority | PRODUCTION_MASTER_2.1.md:1801 (J) |
| ch1_aldric_kill_justified | authority:YOU | − | until:lock:authority | dialogue/ch1/aldric.dlg:85 (J) |
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
- `ch1_knight_killed`: PM:663 says only that Aldric supports Hearth "if he survives with agency intact"; it names
  no kill. The mapping is an inference approved by the user (2026-11-09, re-confirmed 2026-11-10): the kill removes
  his support. `ch1_root_purge` argued for Hearth until revision 13; it now argues against YOU (user decision
  2026-11-17, design review round 13), because Kaelen rewrites Aldric before he can say what it will cost: asked how
  much memory it may take, he answers "I don't know. I honestly don't know.", and Elara replies "Then that's what
  you say first. Before you do it." (`dialogue/ch1/aldric.dlg:104-107`). PM:663 is not cited for this row: the purge
  leaves Aldric lucid (`dialogue/ch1/aldric.dlg:119-122`), so its "agency intact" condition does not argue against
  the purge (design review round 14).
- `ch2_seraphina_cautious` changes no trust value (`dialogue/ch2/command_hall.dlg:31-36`; truth and showoff do),
  hence `0`.
- Authority (user decisions 2026-11-17, design review rounds 12 and 13, narrative-director): YOU's philosophy is
  that "somebody must be accountable." (PM:636); Kaelen's own case for it is "Because someone has to be answerable
  when this goes wrong." (PM:7048), and the source tracks his explanation apart from his act ("Flags track
  explanation separately from action.", PM:1804). The discriminator, in one sentence: an Authority seed records
  either Kaelen's first relation to the Key itself (`ch1_root_first_edit`, using it, argues for YOU;
  `ch1_root_discovered_unused`, leaving it unused, argues for NONE) or whether he answered for power used on others
  (owned → YOU `+`, unowned → YOU `−`, disclosed or doubted → SHARED `+`). `ch1_aldric_kill_owned` ("I ended his
  life.", PM:1801) argues for YOU; `ch1_aldric_kill_justified` ("I stopped the threat.", PM:1802, after which Elara
  reminds him "He was ours before he was a threat. Remember that part too.", `dialogue/ch1/aldric.dlg:85`) argues
  against it, as do `ch2_seraphina_showoff`, a Root edit performed for the council ("It sounds similar from the
  outside.", `dialogue/ch2/command_hall.dlg:46`), and `ch1_root_purge`, a rewrite of Aldric whose cost Kaelen did not
  state before acting.
  `ch2_seraphina_truth`, Kaelen disclosing the key and its cost to the council (`dialogue/ch2/command_hall.dlg:23`),
  argues for SHARED. A player who purges Aldric and makes the first edit therefore reaches a negotiated YOU vote
  (`lock_pass`) and hears `sole_dissent`. One `−` seed makes a vote negotiated whatever `+` seeds are set; this is
  intended (no weights, Core Rule 3). `ch1_knight_spared` stays a modifier only: the Purge path sets it too
  (`dialogue/ch1/aldric.dlg:116`), so as a SHARED seed it would argue for shared authority on behalf of a
  non-consensual rewrite.

### Side storylines

`axis:*` means the arc's own choices push that axis toward a value either way; no arc sets a value (Core Rule 2).
Arc 13 onward are not among the 12 (PM:5837). Arc 12's secondary `deleted:CHOOSE` and the primary/secondary order
of arc 06 ("Continuity or Hearth", PM:2695) are judgement calls (J). Arc 08's secondary `faction:*` is its Quest 48
faction effect (PM:3681-3682), not its "Axis effect:" line.

**Pillar P5 in 1.0.** Arcs 05 and 09 feed only the post-1.0 secret routes; in 1.0 they push no axis. Arc 08 feeds
Crownless and also pushes Faction in 1.0: Quest 48's choice to leave a protected place blank on the public map
argues against ARCHIVE and for HEARTH ("Archive faction dislikes omission." / "Hearth may support privacy.",
PM:3681-3682; user decision 2026-11-17, design review round 13). P5 ("side storylines feed the main story") is to
be met in 1.0 by the ten arcs that push an axis, once Y2-PP-T17 maps their flags into the seed map (AC15); today the
seed map holds no side-arc flag, so P5 is planned, not yet covered. Arc 12 ships
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
| 05 | The Flight List | secret:FIRSTWAKE | — | 1.0 (feeds post-1.0) | 2660 |
| 06 | Three Auctions and a Funeral | faction:CONTINUITY | faction:HEARTH | 1.0 | 2695 |
| 07 | Things Lyra Forgot | deleted:* | faction:ARCHIVE | 1.0 | 3619 |
| 08 | Kaito's False Sky | secret:CROWNLESS | faction:* | 1.0 (feeds post-1.0) | 3663 |
| 09 | The Last Error | secret:FIRSTWAKE | — | 1.0 (feeds post-1.0) | 3687 |
| 10 | The Names We Keep | deleted:* | — | 1.0 | 4373 |
| 11 | The Clerk Who Stayed | authority:SHARED | — | 1.0 | 4423 |
| 12 | A Person in Three Places | secret:WITNESS | deleted:CHOOSE | 1.0 | 4459 |

### Composer input record

SaveService (Y1-P1-T05) stores the record and owns serialisation, the schema version and the defaults for a new
game or a save without these fields (UNSET, empty, OUTSIDE, `PRE_C8`; a legacy save's position is derived, Terms). Every writer named below is a scene
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
| retraction_log | list | at most one entry {axis, old, new, withdrawn_item, scene}; `withdrawn_item` and `scene` are opaque display text that no code branches on | every renegotiation |
| beats_played | set | the lifecycle's authored beat ids (`retract_*`) | the scene that plays the beat |
| kaelen_commitment | enum | UNSET, LISTEN, OVERRIDE_IMMEDIATE_LOSS, CANNOT_PROMISE_NEVER (PM:7054-7058); UNSET exactly when the record never held YOU (Authority is not YOU and no `retraction_log` entry has `old` YOU) | C8-S14 when YOU is backed; a renegotiation to YOU at C8-S16; UNSET from a new game, the NG+ reset and chapter select (user decision 2026-11-19) |
| story_position | enum | the story position ids of Terms (Story position), `PRE_C8` to `ROOT_STORY_PLUS` | each commit checkpoint and story-graph step that crosses into the next id; a new game, the NG+ reset and chapter select; SaveService once for a legacy save (Terms) |
| companions_present | set | Elara, Seraphina, Lyra | `AethelgardPrototype/scripts/game_manager.gd` (`has_elara`, exclusive flag groups); `AethelgardPrototype/dialogue/ch2/fragment_two.dlg` |
| regions_completed | set | ids of the eight regions | owner story Y2-PP-T17 (no writer in the code today) |
| timing_flags | set of flags | `ch1_bridge_saved` / `_evacuated` / `_fell`, `ch2_medicine_early` / `_on_time` / `_late` | `AethelgardPrototype/dialogue/ch1/north_field.dlg`; `AethelgardPrototype/dialogue/ch2/act1_end.dlg` |
| act1_pace | enum | UNSET, act1_pace_early, act1_pace_on_time, act1_pace_late | `AethelgardPrototype/dialogue/ch2/act1_end.dlg` (UNSET until it plays) |
| act2_pace, act3_pace, act4_pace | enum | UNSET and the names S06b defines | owner story Y1-P0-S06b |

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
NEGOTIATED; YOU with `ch1_root_first_edit` set → CLEAN; YOU with `ch1_root_first_edit` and
`ch1_aldric_kill_justified` set → NEGOTIATED; YOU with `ch1_root_first_edit` and `ch1_root_purge` set → NEGOTIATED;
SHARED with `ch2_seraphina_truth` set → CLEAN. A seed row is matched by
its (flag, pushes) pair, so a flag's modifier row never enters the test.

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
story flags saved with the record and `position` the record's `story_position`, passed as its own argument (ids
owned by Y1-P1-T03, stored by Y1-P1-T05); the other fields alone cannot show D15-D17, so the check takes them. `damaged(record, loaded, flags, position)` is true when
the inputs hold an item of Edge Case 16, with one exemption, the live crisis: `live_crisis(record, loaded, position)`
is true when `loaded` is false, the position is inside C8-S16 before its commit checkpoint, nothing is stored, and A,
F and D are set with `invalid(A, F, D)`. D9 and the before-commit clause of D17 are tested on every record except a `live_crisis` one, because inside C8-S16
the live record is the crisis itself: an invalid row with its Deleted value set and nothing stored, before the
commit. Every other item applies to every record (user decision 2026-11-17, Open Question 18). For a record that
passed the load check the two calls agree. `loaded` stays an input: the same (record, position) at C8-S16 is the
crisis when live and a save that cannot exist (I9) when loaded.
The check runs first, so a record that contradicts the phase table is never classified as a playable phase: FINAL
and FIXED need a stored ID, and CRISIS is returned only for `live_crisis`. Any other record with three axes set and
nothing stored is DAMAGED: a loaded one (a crisis is never saved), a live one positioned outside C8-S16, and a live
valid row (a valid row is stored in the same step that sets its last axis). Examples (loaded records, `loaded` true,
consistent flags; a record is written (authority, faction, deleted, stored ID, `root_phase`), followed by its
position): (YOU, HEARTH, UNSET, nothing stored, OUTSIDE) → PARTLY_LOCKED at C8-S15; (SHARED, ARCHIVE, CHOOSE,
`SL-SHARED-ARCHIVE-CHOOSE`, INSIDE) → FIXED inside Root of Heaven; (YOU, HEARTH, UNSET, nothing stored, FINAL) →
DAMAGED at C8-S15; (NONE, ARCHIVE, RELEASE, nothing stored, OUTSIDE) → DAMAGED in Chapter 9; (NONE, ARCHIVE,
RELEASE, nothing stored, OUTSIDE) → DAMAGED inside C8-S16 before its commit (no save exists there, I9). Examples (the live
record in play, `loaded` false): (NONE, ARCHIVE, RELEASE, nothing stored, OUTSIDE) → CRISIS inside C8-S16 before its
commit; (NONE, ARCHIVE, RELEASE, nothing stored, OUTSIDE) → DAMAGED in Chapter 9 (D9), which the gate turns back;
(SHARED, ARCHIVE, CHOOSE, nothing stored, OUTSIDE) → DAMAGED inside C8-S16 before its commit (D9 and D17: a valid
row is not `live_crisis`).

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
   `ch2_seraphina_stayed` / `_rejected`, Lyra on `ch3_lyra_left_alone`. Kaelthas is outside the 1.0 companion set:
   every Chapter 3 branch ends with him refused, fought or gone after his betrayal (the allied path ends in a boss
   fight at the Archive exit, `AethelgardPrototype/scripts/chapter3/ch3_kaelthas_betrayal.gd:157-161`; Core Rule 11,
   Open Question 19). The storyline is unchanged: no ending family needs a companion (Story Bible §5), so every valid storyline stays
   reachable with any companion — or none — present; the composer omits that companion's modules.
2. **Every Witness Protocol lead found in 1.0.** The route is reserved (Core Rule 6): R1 at C8-S16 offers only its
   six renegotiations, C9-S19 does not play, `SEVEN_WITNESSES_AVAILABLE` is never set, and the lead flags stay set
   and transform nothing (`storyline-lifecycle.md` S5 and its Edge Case 5).
3. **Any invalid row before the secret routes ship.** R1, R2 and R3 can only be renegotiated at C8-S16. Any flags
   their side arcs set (05, 08, 09, and arc 12's Witness feed) are kept but never transform a row, and no signpost or
   hint for an unshipped route is shown; the epilogue lines of arcs 05, 08 and 09 still play (invariant I6). With
   every FIRSTWAKE offer prerequisite set, C9-S18 plays its decrypted form and ends logged, not answered; it sets no
   unlock flag and offers nothing (Core Rule 6).
4. **No support for the value the player wants.** The vote still passes, negotiated (PM:6990; Core Rule 3); no
   faction becomes unavailable without warning (PM:6991). The same holds for every lock and renegotiation vote.
5. **Contradictory seeds** (e.g. `act1_report_local` with `ch1_knight_killed`). Both arguments are voiced; the lock
   scene decides, and the vote passes negotiated (`lock_pass`). No error, no tie-break.
6. **Two flags of one exclusive group.** Setting a flag clears the other flags of its group with a warning
   (`AethelgardPrototype/scripts/game_manager.gd:709-728`), so play never holds two. A save that does hold two is
   damaged: SaveService's load check reports it (Edge Case 16, D15); this system defines no tie-break.
7. **Timing that goes badly** (`ch1_bridge_fell`, `act1_pace_late`). The storyline ID never changes; the composer
   picks different scene and slide modules (Core Rule 12).
8. **A save from before the coalition holds.** A save of the current schema version made before the coalition
   holds loads LEANING or PARTLY_LOCKED with nothing stored; seeds already in the save are read as they are. No save
   is made in CRISIS: the crisis resolves inside C8-S16. A save of a schema version before these fields has its whole
   lifecycle block filled with the defaults (UNSET, empty, OUTSIDE) before the load check runs, so D0 meets no missing field
   but the position, and its story position is derived once (Terms, Story position; a Chapter 8 save no story scene places has none and is
   D0); positioned before C8-S13
   (`PRE_C8`) it then loads LEANING, and positioned past a lock scene (chapters 9 and 10 exist in the code today) it
   is refused by D16 as unsupported (the project's own fixture saves are migrated once, `storyline-lifecycle.md`
   Legacy saves). A save of the current schema version with a field missing is D0. Chapter select writes a valid
   record before its first save for every entry positioned past C8-S16's commit, keyed to its entry scene's position,
   not its chapter number (`storyline-lifecycle.md` Chapter select), so it never writes one D16 refuses. A save
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
13. **A knob changes mid-playthrough** (e.g. a patch). Knobs are read only where Tuning Knobs states. With an ID
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
    no transition fires and no gate runs, and the player returns to the load menu, which names the data error and
    offers the most recent save that passes the check. A refusal is never handled as file corruption: the refused
    save is kept as it is and no older save is loaded silently in its place. `load_check` always tests a loaded
    record, so it runs every item, and reports clause ids (e.g. `D7.unnamed`); its item is the part before the dot.
    `storyline_phase` runs the same items on the live record, except that the two marked *(not for the live crisis)*
    are skipped for a `live_crisis` record (Formulas, Storyline phase): inside C8-S16 the live record is the crisis,
    an invalid row with its Deleted value set before the commit. A position inside a lock scene counts as before the
    commit, so the CRISIS fixture of AC9 reports {D9, D17}.

    **Inclusion rule (user decision 2026-11-17, Open Question 17).** An item is in this list only if all three hold:
    (i) accepting the record would crash the composer, strand the player, or break an invariant I1-I9 or the phase
    table; (ii) the refusal is decidable from the record, the saved flags and the position alone, and stays stable
    across patches and a growing seed map; (iii) it cannot refuse a record that play writes.
    - D0 a record whose shape is wrong: a field missing from a save of the current schema version, or a legacy
      save left with no story position (an older save is defaulted first, Edge Case 8) (`D0.missing`), a field of
      the wrong type (`D0.type`), an enum string outside its allowed values (`D0.enum`), a set or list element of
      the wrong type (`D0.element`), a set holding one element twice (`D0.duplicate`), or a set or list longer than
      its maximum (`D0.max`; `retraction_log` one entry: play takes at most one renegotiation, Core Rule 7, and a
      second entry would play a cost beat twice; `beats_played` one, the one entry's beat). Allowed values are
      checked for every field the composer record gives a closed list of values (and `retraction_log`'s `axis`,
      `old` and `new`), except `storyline_id` and `beats_played`, which are checked for type only: which strings
      they may hold is D1's and D14's (its undefined-beat clause). `kaelen_commitment` is also outside its allowed
      values (`D0.enum`) when it is UNSET on a record that held YOU (Authority YOU, or a `retraction_log` entry with
      `old` YOU) or set on one that never did: play writes it exactly when SOVEREIGN can quote it (lifecycle S2;
      user decision 2026-11-19). D0 is tested first; when it fires no other item
      runs, so `load_check` reports only D0 clauses and its items are exactly {D0}. It exists so that no later item
      and no composer read meets a value of the wrong type or count; it is not an integrity check
    - D1 a stored ID that is not `SL-A-F-D` for its axes on a valid row, tested in this order and reported as the
      first clause that holds: any `SL-SECRET-*` ID (`D1.secret`; no 1.0 play stores one), an ID with an UNSET axis
      (`D1.unset_axis`), an ID while the record's axes form an invalid row (`D1.invalid_row`), or any other ID
      (`D1.other_id`, which includes an invalid row's ID stored on a valid row)
    - D2-D5 retired (revision 9): they checked the Witness record fields, which 1.0 no longer stores
    - D6 `axis_revised` holding an axis that `lock_negotiated` lacks
    - D7 `axis_revised` holding an axis that no `retraction_log` entry names (`D7.unnamed`), or a `retraction_log`
      entry whose axis is not in `axis_revised` (`D7.reverse`; the composer reads `axis_revised`), or a
      `retraction_log` entry whose `new` value is not the record's value for its axis (`D7.new_mismatch`). The
      clauses `D7.multi` and `D7.duplicate` of revision 11 are retired (design review round 12): D0 refuses a second
      entry, so neither could fire, and the revision-11 reason given for `D7.multi` was false: (NONE, HEARTH,
      RELEASE) admits two consistent Faction retractions, from R2 (ARCHIVE→HEARTH) and from R3 (CONTINUITY→HEARTH),
      which is now a D0 fixture (AC9)
    - D8 `root_phase` INSIDE or FINAL with nothing stored
    - D9 three axes set with nothing stored *(not for the live crisis)*
    - D10-D13 retired (revision 9): they checked the witness vote fields
    - D14 a `retract_*` beat in `beats_played` with no matching `retraction_log` entry, or a `retraction_log` entry
      whose beat is not in `beats_played`, or a beat id the lifecycle does not define. A beat matches an entry
      exactly when its id is `retract_<rule>_<axis>_<new>`, rebuilt from the entry (`rule` is the invalid row R1-R3
      that the record's axes form with the entry's axis set back to `old`)
    - D15 two flags of one exclusive group, as the groups stood at the save's schema version (Edge Case 6): a group
      added or widened by a later patch never refuses an older save (inclusion rule (ii) and (iii); Open Question 5's
      `ch1_oakhaven_warned_leaders` is the known case)
    - D16 a story position (Terms) past the lock scene of an UNSET axis (a save made past Chapter 8 before these
      fields existed; unsupported, user decision 2026-11-10)
    - D17 a lock-order defect, in two clauses. (a) *Before commit (not for the live crisis):* an axis is set while the story
      position is before its lock scene's commit: no lock scene could play from it (S1 needs every axis UNSET, S2
      needs Faction set, S4 needs Faction and Authority set), so loading it would strand the player. A position
      inside a lock scene before its commit counts as before it (no save exists there, I9); the commit checkpoint
      counts as past it. (b) *Prefix:* the set axes are not a prefix of the lock order (Faction, then Authority,
      then Deleted). For a loaded record (b) is implied by D16 and (a) (the reference model checked 64 axis triples
      at 15 positions and found none that fires (b) alone), so it is kept as documentation and has no fixture of its
      own (AC9)

    D16 holds only while no player-facing build has such saves; if one ships before these fields do, the decision is
    reopened (`storyline-lifecycle.md` Legacy saves).

    Not checked, by the inclusion rule (edited or debug saves only; user decision 2026-11-17, Open Question 17):
    - `lock_negotiated` against `lock_pass` of the saved seeds (fails (ii): `lock_pass` reads the seeds at lock
      time, and a seed map that grows (AC15) would make a save play wrote look damaged). Permanent non-goal.
    - The coupling of `root_phase` to the story position, a FINAL record before the boss or a non-FINAL record after
      it (fails (i): neither crashes nor strands; reference model F7). Permanent non-goal, except as below.
    - A retraction entry's `withdrawn_item` and `scene`: opaque display text that no code branches on (composer
      record), so neither can crash the composer.
    - A non-FINAL record positioned after the final authorization (reference model F10): its count rests on modelling
      choice M8, which is lifecycle Open Question 2. If Story+ cannot reach the final authorization, such a record
      strands and passes (i); it then becomes one item, candidate D18 (`root_phase` FINAL exactly when the position is
      at or after the final authorization's commit checkpoint), needing only the boss and final-authorization
      positions from Y1-P1-T03.

    Tripwires: the reference model asserts that the categories of accepted records play does not write equal a
    pinned list (a new category fails the run; counts are reported, not asserted), and AC9 holds one negative fixture
    per non-goal that loads. This rule is revisited when Y1-P1-T03 defines the story positions or lifecycle Open
    Question 2 is decided.

## Dependencies

| System | Direction | What flows | Status of its design doc |
|---|---|---|---|
| Storyline lifecycle (`design/gdd/storyline-lifecycle.md`, Y2-PP-T17) | this → lifecycle | the axes, formulas, record and invariants I1-I9 the scenes must keep | revision 11 (chapter select per entry, scene placement, windows, `kaelen_commitment`, the full NG+ reset; lifecycle Open Question 7); needs re-review |
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
| story progression | the lock-scene order, the C8-S16 crisis, the gate on the `story` path and on every scene change into Root of Heaven, chapter select past C8-S16 writing a valid record, the stored story position, the secret-route scenes kept closed (C9-S18 in the form Core Rule 6 states, decrypted and logged with every FIRSTWAKE prerequisite set and noise otherwise; C9-S19, C9-S20, C10-S13 to C10-S15 gated on the stored ID), the superseded legacy Chapter 8 and Chapter 10 flags | Core Rules 3-9; lifecycle S1-S7, Dependencies |
| world-map / free-travel logic | the gate check on the `world_map` path | Core Rule 8; lifecycle S6 |
| combat | none beyond the source: boss phases read the stored axes (PM:8611-8616); the re-entry rule | Core Rule 9; lifecycle Edge Case 2 |
| NG+ | the reset of the record and the axis, secret and unlock flags | Edge Case 9; lifecycle NG+ reset |
| true ending | none: no storyline is called the true ending ("Secret route is not called true ending.", PM:11221); the family endings and modules are new composer content | Core Rule 10 |
| Source Key logic | none expected: the final authorization confirms execution and changes no Source Key rule; if Y2-PP-T17 routes it through Source Key code, that needs approval | Core Rule 9 |
| collision, hitboxes | none | — |

## Tuning Knobs

Knobs are read in exactly two places, and this is the one statement of where (Edge Case 13 and the lifecycle point
here): every knob at C8-S16 and the gate, never once an ID is stored (Core Rule 8); and
`secret_prerequisites[FIRSTWAKE]` at C9-S18, to choose its decrypted or noise form (Core Rule 6), which sets no
field and changes no ID.
FlagRegistry checks the
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
state machine is correct. Correctness evidence is runtime ACs 5-17, starting with a non-shipping reference model of
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
   beats_played, kaelen_commitment, story_position, companions_present, regions_completed, timing_flags, act1_pace and act2_pace/act3_pace/act4_pace,
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
| `stored_id(record)` | the record's stored `storyline_id`, or empty while nothing is stored |
| `companions_of(module_id)` | the companions the route data places in the party or gives a line in that module |
| `keyed_axis(module_id)` | the axis whose value the route data keys a module to (`authority`, `faction`, `deleted`), `family` for a module keyed to the family, or `none` |
| `base_lines(scene)` | the ordered (authored line id, masked-text hash) pairs a scene plays with no module selected, masked as in `scene_lines()` |
| `lock_arguments(axis)` | the lifecycle's scene-level observable (`storyline-lifecycle.md` L-AC2): in that axis's lock scene, the (flag, value, sign) arguments voiced |
| `composer_modules(record, flags)` | the module ids the composer selects (ids defined by Y2-PP-T17) |
| `module_keys(flag)` | the module ids the route data keys to a flag |
| `ending_render(id)` | the ordered (ending module id, masked-text hash) pairs the route data plays for a storyline ID, masked as in `scene_lines()` |
| `story_plus_state(id)` | the set of Story+ unlock cases the route data creates for a storyline ID |
| `boot_errors(knobs, flags, build)` | the data errors FlagRegistry finds at boot for a build (`1.0` or later) |
| `load_check(record, flags, position)` | the clause ids of the data errors SaveService's load check reports for a save's record, flags and story position (Edge Case 16), e.g. `D7.unnamed`; a clause id's item is its part before the dot |
| `scene_lines(id, scene)` | for a storyline ID and a scene, the ordered (authored line id, masked-text hash) pairs the route data plays, where the masked text replaces every interpolation slot the route data declares (`{faction_name}`, numbers, names) with one constant token and normalises whitespace and case |

**Runtime — each criterion names the stories that must land before it can run.** Story types and gates
(`.claude/docs/coding-standards.md`): ACs 5-14 are Logic (BLOCKING), automated in the project's own SceneTree test
harness (`AethelgardPrototype/tests/`, each test listed in `tests/suite_limits.txt`; gdUnit4 is not installed), with
`load_check` and `phase_of` as static functions so no scene is needed, and with golden vectors exported from the
reference model so the GDScript and the model cannot drift; AC15 is Logic (BLOCKING), a data scan; AC16 and AC17
are Integration. The
retained screenshots of the lock scenes, the gate turn-back and the three family endings are lifecycle L-AC18; three
endings evidence the families, not the 24 ending sequences, which AC14 tests as data.

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
   `loaded` and position, and for one fixture per phase other than DAMAGED (LEANING, PARTLY_LOCKED, CRISIS,
   VALIDATED, FIXED, FINAL), called with `loaded` false for CRISIS and true for the others; `load_check()` is empty
   for each of those six fixtures except CRISIS, which sits inside C8-S16 and so reports exactly the items {D9, D17},
   and `phase_of` of the CRISIS fixture with `loaded` true is DAMAGED. The live crisis is bounded (Open Question 18):
   with `loaded` false, the CRISIS fixture's record positioned in Chapter 9 and at C8-S16's commit checkpoint gives
   DAMAGED; a valid row with nothing stored inside C8-S16 gives DAMAGED; a record with a valid stored ID inside
   C8-S16 before its commit gives DAMAGED; the D9 fixture and the D17 before-commit fixture give DAMAGED. Clause
   isolation: for each clause of each active Edge Case 16 item (D0, D1, D6-D9, D14-D17), a hand-built fixture that
   differs from a valid fixture by that defect (a defect may change the several fields that keep the other items
   satisfied, e.g. the D7 new-value fixture is (SHARED, ARCHIVE, RELEASE) stored as its own ID with the entry
   {authority, NONE → YOU} and its beat `retract_R2_authority_YOU`) gives `phase_of(…, true)` DAMAGED and
   `load_check()` exactly {that clause id}, except the clause listed as documentation (`D17.prefix`), which has no
   fixture. The clause ids are exactly: `D0.missing`, `D0.type`, `D0.enum`, `D0.element`, `D0.duplicate`,
   `D0.max`, `D1.secret`, `D1.unset_axis`, `D1.invalid_row`, `D1.other_id`, `D6`, `D7.unnamed`, `D7.reverse`,
   `D7.new_mismatch`, `D8`, `D9`, `D14.undefined`, `D14.no_entry`, `D14.not_played`, `D15`, `D16`,
   `D17.before_commit` and `D17.prefix`. The D0 fixtures include a missing field in a current-version save, a
   Chapter 8 legacy save that no story scene places (`D0.missing`), a non-string `storyline_id` (`D0.type`), an
   out-of-range `root_phase`, a retraction entry whose `old` is outside its axis's values and a YOU record with
   `kaelen_commitment` UNSET (`D0.enum`), a
   non-string `beats_played` element (`D0.element`), a set holding one element twice (`D0.duplicate`), a two-entry
   `retraction_log` (the R2 and R3 Faction retractions of (NONE, HEARTH, RELEASE), each consistent on its own) and
   a two-element `beats_played` (`D0.max`), and a D0 defect together with a D1 defect, whose items are exactly
   {D0}; the D14 fixtures include a `beats_played` holding one undefined `retract_*` id, which reports D14, not D0.
   New game: the first save of a new game (every field at its default, `act1_pace` UNSET, at `PRE_C8`) gives
   `load_check()` empty and `phase_of(…, true)` LEANING.
   Mutation kill: for each clause, a copy of `load_check` with that clause deleted fails at least one fixture of this
   criterion, except the documentation clause, which is listed as an equivalent mutant. Legacy: a save of the
   previous schema version with no lifecycle block, defaulted before the check (Edge Case 8), gives `load_check()`
   empty and `phase_of(…, true)` LEANING at `PRE_C8`, and exactly {D16} at `CH9`. Non-goals load: one fixture per
   non-goal of Edge Case 16 (an edited `lock_negotiated`, an edited `withdrawn_item`, an edited `scene`, a FINAL
   record before the final authorization) gives `load_check()` empty. `load_check()` gives the same result with every
   knob flipped. Fixtures use the position ids of Terms (Story position). *Blocked by:* Y2-PP-T17, Y1-P1-T05,
   Y1-P1-T03 (the scene-to-position map).
10. Seeds never lock: a record holding any one of the 26 seed flags in `flags`, or one flag from each exclusive group,
    positioned before C8-S13 with no lock scene played, has `axis()` UNSET for all three axes and `phase_of` LEANING;
    no input of `phase_of` or `axis()` but the record's own fields sets an axis (the scene-level counterpart, a lock
    vote keeping the backed value whatever seeds are set, is `storyline-lifecycle.md` L-AC2). *Blocked by:*
    Y2-PP-T17, Y1-P1-T03.
11. Companions and timing: for one VALIDATED record per 1.0 family, the records with no companion and with all three
    1.0 companions (Elara, Seraphina, Lyra), each with no timing flag and with each of `act1_pace_early`,
    `act1_pace_late`, `ch1_bridge_saved` and `ch1_bridge_fell` added alone, keep `stored_id()` and `family()`
    unchanged; every module m in `composer_modules()` has `companions_of(m)` within the record's present companions;
    and adding one timing flag f changes `composer_modules()` by exactly `module_keys(f)` (symmetric difference, per
    flag, so a module keyed to two flags cannot false-fail). Kaelthas (Core Rule 11): on every such record, with any
    combination of `ch3_kaelthas_allied`, `_refused`, `_challenged` and `_betrayed` set, no module m in
    `composer_modules()` has Kaelthas in `companions_of(m)`. *Blocked by:* Y2-PP-T17.
12. Boot validation: `boot_errors(knobs, flags, build)` names the route when a `secret_prerequisites` list has fewer
    than two flags, two lists share a flag, a flag is unknown to FlagRegistry, an unlock flag appears in a
    prerequisites list, or any secret route is enabled in a `1.0` build; with the default knobs and build `1.0` it is
    empty. *Blocked by:* Y2-PP-T17, Y1-P1-T03.
13. Sole dissent (Core Rule 3): for one VALIDATED fixture per 1.0 family, each with `lock_negotiated` = {authority},
    {faction, deleted} and {}, and one SOLE fixture reached by renegotiation to YOU (`axis_revised` and
    `lock_negotiated` = {authority}): `composer_modules()` contains `sole_dissent` exactly for the SOLE fixtures whose
    `lock_negotiated` holds `authority`; `stored_id()` and `family()` are the same across a family's fixtures.
    *Blocked by:* Y2-PP-T17.
14. Pillar P3 (ROADMAP §2: a storyline changes ≥ 3 story scenes, has its own ending sequence and its own Story+
    state), over the 24 storylines reachable in 1.0, by authored lines with interpolation masked, not by ids or raw
    text. A scene's *base* is `base_lines(scene)`, what it plays with no module selected (user decision 2026-11-17,
    design review round 12; revision 11's most-shared baseline made `SL-SHARED-ARCHIVE-CHOOSE` the most-shared
    variant of every scene keyed to one axis, so that ID could never differ). An ID *differs in a scene* when
    `scene_lines(id, scene)` differs from the base in at least one authored line id or masked-text hash; a
    substituted name, number or faction name alone never counts, and the checker lints that every substitution in a
    rendered line is a declared slot. Pass: for every ID, at least 3 story scenes (a `C<n>-S<m>` or boss id; the
    ending sequence does not count) differ from their base, and at least one of those differences comes from a module
    whose `keyed_axis()` is `faction` or `deleted`; for every pair of distinct IDs, at least 2 scenes differ between
    them, at least one of them a story scene, `ending_render()` differs in at least one masked-text hash, and
    `story_plus_state()` differs. Seeded defects, each of which must fail the criterion: route data in which two IDs
    differ only by a faction name substituted into otherwise shared scenes; route data in which every module's
    `keyed_axis()` is `family`. A one-word edit under a new line id passes by construction, so for the pair with the
    smallest count two raters confirm that its differing lines differ in content, not only wording; that result and
    the smallest pairwise count are reported, and a threshold above 2 is Open Question 13. *Blocked by:* Y2-PP-T17.
15. Pillar P5 tracking (a closing condition of Y2-PP-T17): Y2-PP-T17 lists every flag the ten 1.0 side arcs that push an axis
    (01-04, 06-08, 10-12) set in a `side_arc_flags` table (arc, flag, source line); each of the ten arcs has at least
    one row; every flag
    that the arc's own scripts or dialogue under `AethelgardPrototype/` set is a row (a scan with zero hits is NOT
    ASSESSED, never a pass); the set of those flags minus the flags of the seed map (or its successor table) is
    empty, so every one of them has a seed-map row with a `pushes` target (an axis, a modifier, timing or
    `secret:<route>`, Act 1 seed map) and a direction, and the checker's flag list includes it.
    *Blocked by:* Y2-PP-T17, Y1-P1-T03 (the arc flags exist in FlagRegistry).
16. Comprehension (Player Fantasy, "Authorship, not a menu" and "Costs are real"; playtest, Integration): a blind
    playtest of Chapter 8 with at least 12 testers. At least 6 play Act 1 themselves, with at least one day between
    Act 1 and Chapter 8; the rest start from fixture saves with differing Act 1 seeds. At least 2 testers per invalid
    row (R1, R2, R3) start from a fixture that reaches that crisis. Each fixture has a written answer key (the Act 1
    choices its arguments refer to; for a crisis, the refusing faction and the value it refused), and two raters who
    did not run the session score the transcripts against it; a disagreement goes to the lower score. After each lock
    scene the tester is first asked, unprompted, why the Assembly argued as it did, then asked to name the earlier
    choice behind an argument. Pass: (a) of the testers who played Act 1 themselves, at least 70% name an earlier
    choice behind an argument in at least 2 of the lock scenes whose `lock_arguments()` was non-empty for them,
    unprompted or prompted (a tester with fewer than 2 such scenes counts as a fail); the unprompted rate is reported
    beside it, and the fixture-save testers' rate is reported, not gated, because they never made the choices;
    (b) at least 75% of crisis testers name both the refusing faction and the value it refused. Reported measures
    with no verdict effect: (c) every tester's 1-5 answers to "did you feel you had a choice at the crisis?" and "did
    the crisis feel foreshadowed?"; (d) which crisis offer each crisis tester took, with any offer taken by more than
    60% of crisis testers flagged to the narrative-director. The report gives counts with 95% Wilson intervals beside
    every rate, and is retained at `production/qa/evidence/<date>-storyline-playtest/` with the fixture list and
    answer keys. A run is never stopped early or extended to reach the bar. Failure action: the seed arguments or the
    red lines are revised, not the bar, and the playtest is re-run as a fresh run of this whole criterion (at least
    12 new testers, judged alone, never pooled with a failed run); after two failed runs the result goes to the
    narrative-director and creative-director. *Blocked by:*
    Y2-PP-T17, Y1-P1-T05 (fixture saves), Y1-P1-T03 (seed flags).
17. Pillar P5 voiced (a closing condition of Y2-PP-T17, after AC15): for each of the ten 1.0 side arcs that push an axis
    (01-04, 06-08, 10-12), a fixture record with one of that arc's `side_arc_flags` set makes `lock_arguments()` of the axis
    the flag pushes contain an argument whose flag is that flag, and the same fixture with every flag of that arc
    unset gives a `lock_arguments()` that contains none of that arc's flags. Arc 12 is tested for its `deleted:CHOOSE` push only, arc 08 for its Faction push only.
    *Blocked by:* Y2-PP-T17, Y1-P1-T03.

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
   secret-route reactions (PM:11229-11236). This GDD uses 3 of the 4 (Elara, Seraphina, Lyra); Kaelthas is reserved
   (Core Rule 11, Open Question 19). `companions_present` grows when the others are confirmed.
7. **Systems index:** `design/gdd/systems-index.md` does not exist; `/map-systems` creates it later.
8. **Story Bible §5** gives the Consent family the God King "loses its health bar" fight, which the production
   master gives to Crownless (PM:11247); a separate Story Bible fix.
9. **Truth strategy** (Seraphina's disclosure) is its own composer module in the production master (PM:8739); owner
   Y2-PP-T17.
10. **Seed readings kept despite review objections (2026-11-10):** `ch1_aldric_kill_unsure` → SHARED may read as
    deferral ("don't decide it tonight", `aldric.dlg:90`); `ch2_data_wraith_destroyed` → RELEASE is a unilateral
    destruction while RELEASE ends involuntary preservation (PM:686, PM:7094); `ch2_data_wraith_absorbed` → CHOOSE is unilateral and held
    in Kaelen's own Root layer (PM:2468), which could argue for YOU. Revision 12 (user decision 2026-11-17, design review round 12) moved
    Authority's arguments from whether Kaelen acted to whether he answered for it, and revision 13 (user decision
    2026-11-17, design review round 13) moved `ch1_root_purge` from HEARTH `+` to YOU `−` and stated the one
    discriminator (Act 1 seed map notes): YOU has two `+` seeds (`ch1_aldric_kill_owned`, `ch1_root_first_edit`) and
    three `−` (`ch1_aldric_kill_justified`, `ch2_seraphina_showoff`, `ch1_root_purge`), SHARED two `+`
    (`ch1_aldric_kill_unsure`, `ch2_seraphina_truth`), NONE one; HEARTH keeps one `+` (`act1_report_local`). A player
    who kills Aldric and calls it justified, or purges him, and keeps Root alone now hears `sole_dissent`; before
    revision 12 the first passed clean and only a restrained player heard it, which inverted P10, and before revision
    13 the second passed clean. `sole_dissent` is reached three ways: a YOU vote with no `+`
    seed, a YOU vote with a `−` seed, and a renegotiation to YOU at C8-S16 (R2 and R3 offer it, and every
    renegotiation sets `lock_negotiated`). `ch1_knight_spared` was proposed for SHARED and dropped, because the
    Purge path sets it too (`dialogue/ch1/aldric.dlg:116`). New evidence against `ch2_data_wraith_destroyed` →
    RELEASE (round 12, narrative-director): RELEASE needs staged verification (PM:7118), while destroying the wraith
    loses anyone still recoverable (`dialogue/ch2/underground.dlg:64`); the user kept the row (2026-11-17). Deleted has at most one `+` seed (one exclusive group), so a Deleted lock is the most often
    negotiated and is never audible in 1.0. `ch1_root_purge` → YOU `−` rests on `dialogue/ch1/aldric.dlg:104-107`
    (revision 14); PM:663 is not cited for it, since the purge leaves Aldric lucid. Revisit the rest in a narrative
    pass, with the AC16 playtest as evidence.
11. **Reserved: post-boss reconsideration.** PM:8791 allows "one last lawful reconsideration" if final circumstances
    changed drastically. Cut from this design (user decision 2026-11-10) because boss phases 2-4 already read every
    axis (PM:8611-8616). If Y2-PP-T17 ever authors a trigger, it needs a GDD revision, and can change at most the
    epilogue and Story+ state.
12. **Deferred to Y2-PP-T17:** the `sole_dissent` module text; whether the ledger Variants and Policies
    (PM:7569-7582) later make `lock_negotiated` visible beyond `sole_dissent`. The Witness items of revision 8 (the
    witness institution, signposts, candidates, the vote, the stand-down) moved to Open Question 15.
13. **P3 baseline and the storyline cut order.** (a) AC14 now tests rendered text: ≥ 3 story scenes per ID that
    differ from their base, and a pairwise minimum of 2 scenes (rounds 11 and 12). The all-pairs ≥ 3 test stays dropped because the design never shows that
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
    Round 11 ran in full against it (F11 found by the model, settled as Open Question 18). From revision 11 a re-run
    of the model, the checker and the mutation runner is required for every revision that changes the Formulas, Edge
    Case 16, the invariants or the lifecycle transitions, and the run must report PASS with its residual categories
    asserted (Open Question 17). Still open: the owner of re-running it after the GDDs are approved (proposed: Y1, the
    story that lands SaveService's load check).
17. **Load-check scope — settled (user decisions 2026-11-17, design review rounds 10 and 11).** The load check
    promises that every save play writes loads, that a loaded record is consistent with the lock order (D16, D17),
    and that no accepted record crashes the composer, strands the player or breaks an invariant; it never promises
    edited-save integrity. Edge Case 16 states the inclusion rule, the items it added (D0; `D7.duplicate` was folded
    into D0's one-entry cap in revision 12), the
    non-goals (`lock_negotiated` against `lock_pass`; `root_phase` against position; `withdrawn_item` and `scene` as
    opaque text) and the tripwires. The one part still waiting is the reference model's F10 (non-FINAL records after
    the final authorization), which rests on modelling choice M8 = lifecycle Open Question 2: when that is decided, or
    when Y1-P1-T03 defines the story positions, decide whether candidate D18 is added.
18. **A live CRISIS record outside C8-S16 — settled (user decision 2026-11-17, design review round 11).** The live
    exemption of D9 and D17's before-commit clause is scoped to `live_crisis` (Formulas): a live record positioned
    inside C8-S16 before its commit, nothing stored, on an invalid row. Any other record with three axes set and
    nothing stored is DAMAGED, and a live DAMAGED record at the gate is turned back as a data error (a dev assert and
    a system-voice prompt to reload, `storyline-lifecycle.md` S6); I5 names that case. A CRISIS row at the gate was
    rejected because it would legitimise a state the phase table, I2 and S6 call impossible; a gate that replays
    C8-S16 was rejected as a runtime catch-up (user decision 2026-11-10).
19. **Kaelthas as a companion (user decision 2026-11-17, design review round 12).** No 1.0 save has Kaelthas in the
    party past Chapter 3: the allied path always sets `ch3_kaelthas_betrayed` (`AethelgardPrototype/scripts/chapter3/
    ch3_kaelthas_betrayal.gd:35,89`) and every other branch is a boss fight. He is outside the 1.0 companion set, and
    PM:7533 ("can remain companion outside Archive if trust supports it") is reserved. Redemption content that lets
    him rejoin needs: a flag that marks it (never a relationship number), its owner and scope (a Y2-PP-T17 content
    request with producer sign-off), the protected story-progression approval for Chapter 3-7 changes, and a GDD
    revision that restores the Archive waiver and its AC11 rows.
20. **Review exit criteria — adopted (user decision 2026-11-18, design review round 14; proposed by the
    creative-director in round 12).** Revision 14 changes only the six round-14 blockers and Open Question 21's
    class, each in one place. The reference model covers the whole stored record (every closed-list field,
    `story_position`, legacy derivation including hub saves, a new-game save), and the model, the checker and the
    mutations are re-run and pass. Round 15 runs lean on the revision-14 diff and the model log; a finding blocks only
    with a failing model case, a contradiction in the text or a false citation, and is otherwise routed or
    recommended. If round 15 finds only blockers with one-line fixes, they are fixed and verified in that session and
    the GDD is approved, with no round 16.
21. **Main-story seeds (user decision 2026-11-18, design review round 14).** Main-story choices after Act 1 become
    seeds the same way side arcs do (Core Rule 2). The first known is the Chapter 4 Null Court promise
    (`ch4_choice_preserve_deleted`, `_release_deleted`, `_bargain_deleted`, set at
    `AethelgardPrototype/scripts/chapter4/ch4_null_court.gd:125-136` and read in Chapters 5 to 10), which no axis
    reads today, so a player who promised the deleted something in Chapter 4 hears only the Chapter 2 wraith at the
    Deleted lock. The narrative-director proposes the mappings before Y2-PP-T17 writes C8-S15 and C8-S16, with their
    AC rows; note that the code's "release the backups" returns the deleted, which is closer to RESTORE than to the
    axis's RELEASE (PM:686). Also to decide: whether a locked Deleted value overrides Chapter 10 lines keyed to
    `ch4_choice_*` where the two conflict. Owner Y2-PP-T17; the seed map and its 26-flag list are unchanged until
    then.
