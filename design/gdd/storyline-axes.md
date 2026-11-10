# Storyline Axes

> **Status**: Draft (revision 3, after design review round 3)
> **Author**: Claude (narrative-director research) with the project lead
> **Last Updated**: 2026-11-10
> **Last Verified**: 2026-11-10
> **Implements Pillar**: P3 (24 storylines + 3 secret from three story axes), P5 (side storylines feed the main
> story), P8 (Story+, a playable after-story per storyline) — DESIGN_PILLARS.md, ROADMAP §12.2

## Summary

Three story axes — who holds Root (Authority), which society Kaelen backs (Faction), and what happens to the
deleted (Deleted) — combine into 27 configurations; 24 are valid storylines, 3 are contradictions that only a
secret route can transform. Four ending families carry the depth; Faction and Deleted modify them. Every save
tracks one stable storyline ID, stored the moment the coalition holds and required at the entry to Root of Heaven;
the ending composer builds the ending from that ID plus companions, regions and timing.

> **Quick reference** — Layer: `Foundation` · Priority: `Alpha`

## Overview

Aethelgard's main story does not branch into 27 separately written routes. In Chapter 8, Kaelen's choices lock
three axes: **Authority** (Kaelen alone, shared and auditable, or abolished), **Faction** (Hearth Compact, Archive
Covenant or Continuity League) and **the Deleted** (restore them, release them, or let each person choose). The
three locked values name one of 24 valid storylines (`SL-AUTHORITY-FACTION-DELETED`); three combinations break the
coalition (PM:710-723). A broken coalition is a political crisis that lasts until the player renegotiates one axis
or, having earned a secret route's prerequisites, invokes it in Chapter 9 — Witness Protocol in 1.0, Crownless and
First Wake post-1.0. The storyline ID is stored the moment the coalition holds, and the **ID-lock gate** at the
entry to Root of Heaven stays closed until it is. The **final authorization** (the post-boss scene, PM:8786-8794)
confirms it and may offer one costly reconsideration of Faction or Deleted. The Authority value picks one of four
ending families (Sole, Bound, No Authority; Consent for Witness Protocol), each with its own God King phase, final
scene and Story+ arc; Faction and Deleted change a boss phase, ally lines, epilogue slides and which Story+ cases
unlock. Act 1 flags seed arguments and decide whether a lock vote passes clean or only by negotiation, twelve side
storylines push the axes, and timing changes scenes and slides without ever changing the storyline ID — so authored
cost stays additive.

## Player Fantasy

The player holds a key that could rewrite the world, and the game keeps asking whether they have the right to turn
it (Story Bible §1: "Capability is not legitimacy"). The axes are how that question becomes theirs: not a morality
meter, but three answers they build up through what Kaelen does — who he lets hold Root, whose society he stands
with, and whether the deleted are brought back, let go, or asked.

- **Authorship, not a menu.** Each lock is a vote between proposals, never a picker of labels ("Options are
  proposals not Kaelen menu labels", PM:6983), and the scene argues with the player's own history: the Act 1
  choices and side storylines they may not have read as political come back as the arguments for and against each
  proposal, and decide whether the room is already with them or has to be negotiated, so the storyline at the end
  feels arrived at.
- **Costs are real.** Every valid storyline loses something (its route's "Primary danger"); the three invalid
  combinations are where a coalition refuses to follow. Faction leaders say where their red lines are before the
  last lock, the coalition breaks in Chapter 8 instead of failing silently at the ending screen (PM:7153), and a
  renegotiation is remembered.
- **Nobody is forced to agree.** Companions stay possible on every storyline (PM:11302); they argue, they do not
  vanish because the player picked a faction.
- **The world goes on without a perfect answer.** The ending family (who authorized the change) carries the weight;
  Faction and Deleted colour what that authority built; Story+ lets the player walk around in the result.
- **Hidden doors are earned, then signposted.** A secret route appears only after its first prerequisite is found,
  then is signposted like everything else (PM:697-707; ROADMAP §12.2 "nothing important is lost silently").

## Detailed Design

### Terms

- **Lock scene**: the scene that sets one axis — Faction: C8-S13 First Assembly Vote (PM:6980-7027); Authority:
  C8-S14 Root Authority Hearing (PM:7029-7087); Deleted: the C8-S15 hearings (PM:7089-7132) end in C8-S16 Axis
  Three Lock (PM:7134-7137). The source runs them in this order.
- **Clean / negotiated**: how a lock vote passes (Core Rule 3).
- **Crisis scene**: a scene that, while the live ID is CRISIS, offers the renegotiations (Core Rule 6) and, when
  Core Rule 7 allows, the invocation. The contract requires two: C8-S16 when the third lock completes an invalid row
  (PM:7138-7153), and the ID-lock gate, which plays as the last crisis scene. Y2-PP-T17 may add Chapter 9 Assembly
  scenes; each must offer the same.
- **Invocation scene**: a secret route's Chapter 9 scene, which plays when the route's prerequisites are complete:
  First Wake C9-S18 (PM:8027-8043), Witness Protocol C9-S19 (PM:8045-8055), Crownless C9-S20 (PM:8057-8064).
- **ID-lock gate**: every entry into Root of Heaven (Chapter 10) — the story graph after the Chapter 9 end
  (PM:8206-8207), world-map or free travel, and loading a save positioned inside Root of Heaven. It opens only when a
  storyline ID is stored (PM:722; PM:11305 "intercepted before final boss").
- **Final authorization**: the immediate post-boss scene (PM:8786-8794). The world asks for the authorization
  result, the system displays the chosen structure, and the player confirms execution.

### Core Rules

1. **Three axes, one value each.** Authority ∈ {YOU, SHARED, NONE}; Faction ∈ {HEARTH, ARCHIVE, CONTINUITY};
   Deleted ∈ {RESTORE, RELEASE, CHOOSE}; each starts UNSET (SaveService writes UNSET for a new game and for a save
   with no axis data). Once a storyline ID is stored, each axis holds exactly one value (PM:7522-7524, "Axis
   validation").
2. **Seeds are arguments, never gates.** Act 1 seeds, side storylines, companion persuasion and faction support
   are leanings: each axis seed makes its lock scene voice an argument for (`+`) or against (`−`) its value
   ("Player influence can back one. Companion persuasion and side quests matter.", PM:6987-6988). Every lock scene
   always offers all three values; no seed adds or removes an option. No seed sets a value; only a lock scene, a
   renegotiation or a reconsideration does ("This sets Faction Axis if vote passes.", PM:6989). The sources define
   no axis score.
3. **Lock scenes resolve, clean or negotiated.** Faction → `AXIS2_HEARTH` / `_ARCHIVE` / `_CONTINUITY`; Authority →
   `AXIS1_YOU` / `_SHARED` / `_NONE`; Deleted → `AXIS3_RESTORE` / `_RELEASE` / `_CHOOSE`. These flags are not in the
   code yet (owner: Y2-PP-T17). A lock vote always passes for the proposal the player backs (PM:6990-6991; knob
   `faction_negotiation_allowed`), so no vote leaves an axis UNSET. How it passes is recorded (`lock_pass`,
   Formulas): **clean** when at least one seed for the backed value is set with direction `+` and none with direction
   `−`; otherwise **negotiated**, and `lock_negotiated_<axis>` is set ("If player lacks support choice may still be
   possible through negotiations.", PM:6990). The test reads only which flags are set: no count, no weight.
   Side-storyline flags join it once Y2-PP-T17 maps them per flag (the arc table below names axes, not flags). The
   composer reads `lock_negotiated` (ally lines, slides); it never changes a value or the ID.
4. **Red lines (new content).** In C8-S13 and again in C8-S14, each faction's delegate states in the fiction the one
   combination their faction will refuse: Hearth R1, Archive R2, Continuity R3. Their text basis is the canon
   refusals at C8-S16 (PM:7141, PM:7147, PM:7151); stating them before the third lock is new content approved by the
   user (2026-11-10), owner Y2-PP-T17. There is no system warning; the conflict itself becomes visible at C8-S16
   (PM:7138).
5. **An invalid combination is a political crisis, not a fail state.** If the three locked values form an invalid
   row (R1-R3), the refusing faction breaks the coalition at C8-S16 (PM:7138-7153), "presented as a political crisis
   rather than a menu error" (PM:723). The crisis lasts until a renegotiation reaches a valid row (Core Rule 6) or
   the transforming secret route is invoked (Core Rule 7), through Chapter 9 if need be ("may create alternative
   constitutional mechanism later", PM:7144). Root of Heaven cannot be entered during a crisis.
6. **Renegotiation.** Every crisis scene offers each locked axis's two other values (six offers). Choosing one is a
   renegotiation: Kaelen withdraws the superseded position on the record (table below), the Assembly votes again,
   and the vote always passes negotiated. It sets `axis_revised_<axis>` and `lock_negotiated_<axis>`: allies and
   slides remember both, with no numeric weight. A renegotiation that reaches a valid row resolves the crisis; one
   that reaches another invalid row (only Faction between R2 and R3) keeps it open, and the player may renegotiate
   again, including back to an earlier value.

   | axis | withdrawn on the record | source |
   |---|---|---|
   | Faction | the charter adopted at C8-S13: Hearth's mutual-defense charter, the Archive's public evidence charter, or the Continuity League's emergency operations network. Kaelen's interim role (Root liaison, access witness, technical coordinator) already ended at the Authority lock and is not withdrawn | PM:7003, PM:7010, PM:7021; roles end PM:7006, PM:7017, PM:7027 |
   | Authority | Kaelen's C8-S14 position: YOU, his vow and chosen commitment; SHARED, the seven-signature protocol; NONE, the dismantling commitment | PM:7045-7057, PM:7064-7069, PM:7036-7038 |
   | Deleted | the policy adopted at C8-S16: restore, release or choose | PM:7093-7095 |

   When a renegotiation reaches YOU, Kaelen states his commitment in that scene, and that is the answer SOVEREIGN
   later quotes (PM:7059); a withdrawn commitment is quoted only as withdrawn.
7. **Secret invocation and signposts.** Each secret route T has offer prerequisites (`secret_prerequisites[T]`)
   and an unlock flag (`secret_unlock_flag[T]`); together, in that order, they are the production master's
   "Required flag" list for T (PM:11215-11218, PM:11242-11246, PM:11270-11274). For all three routes the last offer
   prerequisite is set in the Act 3 consequence ledger at the end of Chapter 8 (PM:7586-7588), after C8-S16. While T
   is enabled:
   - **Signpost.** When the first of T's offer prerequisites is set, the journal gains T's signpost: the remaining
     prerequisites as in-fiction leads, and the coalition the route can transform (PM:707; PM:11214; PM:11306).
   - **Invocation scene.** T's invocation scene plays once every offer prerequisite is set ("If secret prerequisites
     complete.", PM:8047). If the live ID is CRISIS on the invalid row T transforms, the scene offers the invocation
     (for Witness Protocol, convening the seven witnesses). After an in-fiction confirm, invoking sets T's unlock
     flag (`SEVEN_WITNESSES_AVAILABLE` for Witness Protocol, recorded in the Chapter 9 ledger, PM:8200) and
     resolves the crisis into `SL-SECRET-T`; it cannot be undone. On any other row the scene plays as lore and
     offers no invocation, and the unlock flag stays unset.
   - **At the gate.** The gate, as the last crisis scene, offers the invocation too when the same conditions hold, so
     a player who declined it in Chapter 9 is not locked out of a route they earned.

   Witness Protocol is in 1.0; Crownless and First Wake are reserved (post-1.0): until they ship, their rows can
   only be renegotiated, and they show no signpost.
8. **A valid row is held to its word.** Once the coalition holds — a valid row at C8-S16, a renegotiation that
   reaches one, or an invocation — no crisis scene plays, and nothing offers a renegotiation or an invocation, before
   the final authorization.
9. **Storyline ID and the ID-lock gate.** The moment the coalition holds, the live ID (Formulas) is stored:
   `SL-{authority}-{faction}-{deleted}` or `SL-SECRET-{route}`. Before that it is PENDING or CRISIS and nothing is
   stored. A stored ID is never recomputed from flags or knobs ("Every route must save a stable storyline ID.",
   PM:11303): it changes at most once, at the final authorization (Core Rule 10), and is final once execution is
   confirmed. The ID-lock gate opens only when an ID is stored. With the live ID CRISIS it plays the last crisis
   scene; with PENDING it turns the player back in the fiction (the Assembly has not decided). Every path into Root
   of Heaven runs the same check (Edge Case 10).
10. **Final authorization and reconsideration.** The post-boss scene displays the stored structure, with no generic
    menu (PM:8788-8789). If a condition in `reconsideration_triggers` holds ("If final circumstances changed
    drastically there may be one last lawful reconsideration.", PM:8791) and the stored ID is a valid-row ID, it
    offers that reconsideration: exactly one of Faction or Deleted may change, only to a value that forms another
    valid row, at most once per playthrough. Authority never changes here: it already shaped the boss's Final
    Permission phase (PM:8615-8616), so the family never changes either. A secret storyline is never reconsidered.
    The reconsideration is on the record ("It cannot silently switch.", PM:8794), sets `final_reconsidered`
    ("Reconsideration is not free. It may break coalition.", PM:8792-8793), and writes the changed axis and the new
    stored ID together. Only what plays after the post-boss scene follows the new ID: Kaelen's route line
    (PM:8795-8800), the ending sequence, the epilogue slides and the Story+ state (one ID per save, PM:11303; each
    route has its own Story+ state, PM:11300). Then the player confirms execution.
11. **Ending family** = the Authority value (YOU → SOLE, SHARED → BOUND, NONE → NONE_AUTH), or CONSENT for Witness
    Protocol (Story Bible §5). **Bound** is a standing institution: Kaelen gives up unilateral final commit to a
    seven-signature protocol with rotating seats and public audit (PM:7064-7069). **No Authority**: the Assembly
    adopts abolition at C8-S14; Kaelen uses the Key once, after the final crisis, to dismantle permanent Root
    capability, and it cannot execute before the final confrontation (PM:7036-7038). **Consent**: Kaelen keeps
    technical execution but holds no authority to use Root alone; seven affected witnesses authorize the one
    restoration (PM:705, PM:11213), and any later Root act needs the witness protocol again, which Story+ builds into
    a rotating witness institution (PM:11220; user decision 2026-11-10). Kaelen is the executor, so he is not one of
    the seven: he "cannot fill multiple roles" (PM:8704), and execution and authorization stay mechanically separate
    (PM:11219). The protocol needs a threshold, not unanimity; witnesses can dissent, and the scene names it
    (PM:8705-8708). Consent differs from No Authority (Root is not abolished) and from Bound (it authorizes one act,
    not a standing signature protocol). For `SL-SECRET-WITNESS` the axes keep their locked values (YOU, HEARTH,
    RESTORE); the family is CONSENT. Faction and Deleted are modifiers: a boss phase, ally lines, epilogue slides,
    Story+ cases.
12. **Companions are independent of the axes.** Every storyline can include every surviving companion
    (PM:7529-7537, PM:11302); a companion leaves through relationship flags (Edge Case 1), never through an axis.
    Kaelthas stays outside the Archive "if trust supports it" (PM:7533): a relationship condition, not the Faction
    value.
13. **Timing is a modifier.** Pace values and timing flags change scenes, NPC fates, market events and ending slides
    through the composer, not the storyline ID (ROADMAP §12.4; PM:7527).

### States and Transitions

`storyline_state` is saved (composer record) and changes only through the transitions below.

| State | storyline_state | Live ID | Gate | Behavior |
|---|---|---|---|---|
| Leaning | LEANING | PENDING | turns the player back | Every axis UNSET; seeds and side storylines collect arguments |
| Partly locked | PARTLY_LOCKED | PENDING | turns the player back | One or two axes locked; delegates have voiced their red lines (Core Rule 4) |
| Crisis | CRISIS | CRISIS | plays the last crisis scene | Coalition broken; crisis scenes offer the six renegotiations and, under Core Rule 7, the invocation |
| Validated | VALIDATED | the stored ID | open | Nothing offers a renegotiation or an invocation (Core Rule 8) |
| Fixed | FIXED | the stored ID | — (inside Root of Heaven) | Boss phases and the composer read the stored ID |
| Final | FINAL | the stored ID | — | Execution confirmed; the stored ID never changes |

| # | from | event | guard | to | effects |
|---|---|---|---|---|---|
| T1 | LEANING | C8-S13 resolves | — | PARTLY_LOCKED | faction set; `lock_negotiated_faction` per `lock_pass` |
| T2 | PARTLY_LOCKED | C8-S14 resolves | — | PARTLY_LOCKED | authority set; `lock_negotiated_authority` per `lock_pass` |
| T3 | PARTLY_LOCKED | C8-S16 resolves | the row is valid | VALIDATED | deleted set; `lock_negotiated_deleted` per `lock_pass`; ID stored |
| T4 | PARTLY_LOCKED | C8-S16 resolves | the row is invalid | CRISIS | deleted set; `lock_negotiated_deleted` per `lock_pass`; the refusing faction breaks the coalition |
| T5 | CRISIS | a renegotiation | the new row is valid | VALIDATED | the axis changed; `axis_revised_<axis>`, `lock_negotiated_<axis>`; retraction recorded; ID stored |
| T6 | CRISIS | a renegotiation | the new row is invalid | CRISIS | the axis changed; `axis_revised_<axis>`, `lock_negotiated_<axis>`; retraction recorded |
| T7 | CRISIS | an invocation, confirmed | Core Rule 7 | VALIDATED | the route's unlock flag set; `SL-SECRET-T` stored |
| T8 | CRISIS | Root of Heaven entry, any path | — | CRISIS | the gate plays the last crisis scene (T5-T7 may follow); leaving it returns the player outside |
| T9 | LEANING or PARTLY_LOCKED | Root of Heaven entry, any path | — | unchanged | turned back in the fiction |
| T10 | VALIDATED | Root of Heaven entry, any path | — | FIXED | — |
| T11 | FIXED | a reconsideration at the final authorization | Core Rule 10 | FIXED | Faction or Deleted changed; new ID stored; `final_reconsidered` |
| T12 | FIXED | execution confirmed | — | FINAL | — |

No other transition exists. In particular nothing leads from VALIDATED, FIXED or FINAL back to CRISIS or an earlier
state: not a knob change (Tuning Knobs), not a flag being set, not loading a save. Loading restores the saved state
and fires no transition.

### The 27 combinations

Invalidity rules (each removes one combination; quoted from PRODUCTION_MASTER_2.1.md:710-723):

| rule | combination | contradiction | source |
|---|---|---|---|
| R1 | YOU + HEARTH + RESTORE | "Hearth will not endorse unilateral compulsory restoration." | PRODUCTION_MASTER_2.1.md:714 |
| R2 | NONE + ARCHIVE + RELEASE | "Archive will not support abolition of root while mass release destroys unresolved memory appeals." | PRODUCTION_MASTER_2.1.md:716 |
| R3 | NONE + CONTINUITY + RELEASE | "Continuity will not support simultaneous abolition of emergency root and irreversible mass release." | PRODUCTION_MASTER_2.1.md:718 |

27 combinations: 24 valid and 3 invalid; each invalid one can become one of the 3 secret storylines, so the design
has 24 + 3 = 27 storylines in all, of which 25 are reachable in 1.0 (Counts).

`valid_count: 24`, as the source states (PM:711-712, PM:8728); the family split (SOLE 8, BOUND 9, NONE_AUTH 7) is
derived (Counts). For a valid row `source` is its route heading in the production master's route matrix and
`danger` its "Primary danger" line, the loss that route's ending must show (owner Y2-PP-T17); for an invalid row,
`source` is its validity line and `danger` is —. `companions_possible` is the same in every row by design (Core
Rule 12).

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
| SL-SECRET-WITNESS | Witness Protocol (PM "SEVEN WITNESSES"; SEC-01 "Authorized by the Living"; transforms R1 / YHR) | CONSENT | 1.0 | PRODUCTION_MASTER_2.1.md:11211 |
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
("side storylines feed the main story") is met in 1.0 by the other nine arcs; arcs 05, 08 and 09 feed their routes
when those ship. Their flags are kept, never transform a row, and show no hint (Edge Case 3).

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
game or a save without these fields (LEANING, UNSET, empty sets, false). Every writer named below is a scene or
transition owned by Y2-PP-T17; no other code writes these fields.

| field | type | allowed | writer |
|---|---|---|---|
| storyline_state | enum | LEANING, PARTLY_LOCKED, CRISIS, VALIDATED, FIXED, FINAL | transitions T1-T12 only (States and Transitions) |
| storyline_id | string | a storyline ID, or empty while nothing is stored | T3, T5, T7 store it; T11 replaces it; nothing else |
| authority | enum | UNSET, YOU, SHARED, NONE | C8-S14 lock (T2); a renegotiation (T5, T6). Never the final authorization |
| faction | enum | UNSET, HEARTH, ARCHIVE, CONTINUITY | C8-S13 lock (T1); a renegotiation (T5, T6); a reconsideration (T11) |
| deleted | enum | UNSET, RESTORE, RELEASE, CHOOSE | C8-S16 lock (T3, T4); a renegotiation (T5, T6); a reconsideration (T11) |
| secret_route | enum | NO_SECRET, WITNESS, FIRSTWAKE, CROWNLESS | derived from `storyline_id` (`SL-SECRET-T` → T, else NO_SECRET); never stored |
| family | enum | SOLE, BOUND, NONE_AUTH, CONSENT | derived: `family(storyline_id)`; never stored |
| axis_revised | set | faction, authority, deleted | a renegotiation (T5, T6) |
| lock_negotiated | set | faction, authority, deleted | the lock scenes (T1-T4) by `lock_pass`; every renegotiation (T5, T6) |
| final_reconsidered | bool | true, false | a reconsideration (T11) |
| companions_present | set | Elara, Seraphina, Lyra, Kaelthas | `AethelgardPrototype/scripts/game_manager.gd` (`has_elara`, exclusive flag groups); `AethelgardPrototype/dialogue/ch2/fragment_two.dlg` |
| regions_completed | set | ids of the eight regions | owner story Y2-PP-T17 (no writer in the code today) |
| timing_flags | set of flags | `ch1_bridge_saved` / `_evacuated` / `_fell`, `ch2_medicine_early` / `_on_time` / `_late` | `AethelgardPrototype/dialogue/ch1/north_field.dlg`; `AethelgardPrototype/dialogue/ch2/act1_end.dlg` |
| act1_pace | enum | act1_pace_early, act1_pace_on_time, act1_pace_late | `AethelgardPrototype/dialogue/ch2/act1_end.dlg` |
| act2_pace, act3_pace, act4_pace | enum | names left to S06b | owner story Y1-P0-S06b |

### Interactions with Other Systems

- **FlagRegistry / StoryGraph (Y1-P1-T03):** owns the seed flags and, later, the `AXIS*`, `axis_revised_*`,
  `lock_negotiated_*`, `final_reconsidered` flags and the secret routes' prerequisite and unlock flags; validates
  exclusive groups and the secret-route knobs at boot; this GDD names them, it does not write them.
- **SaveService (Y1-P1-T05):** stores the composer input record (with `storyline_state` and `storyline_id`); a
  stored ID is never recomputed; loading fires no transition.
- **Time model (S06b):** supplies pace values per act and the timing flags the composer reads.
- **Ending composer / route data model (owner Y2-PP-T17):** implements `storyline_id`, `lock_pass` and
  `reconsider_targets` (Formulas), the lock, crisis, invocation and gate scenes, the red lines, the retractions, the
  signposts, the final authorization and the modules; authored cost additive.
- **World map / free travel:** must run the gate check on entry to Root of Heaven (Edge Case 10). World-map and
  free-travel logic is protected (`AethelgardPrototype/AGENTS.md`): that change needs the user's explicit approval
  when it is implemented.
- **Companion system:** reads relationship flags for presence; never reads an axis to remove a companion.
- **Side storylines (arcs 01-12):** push arguments into axes or modifiers per the table above.

## Formulas

The storyline system defines no balance numbers: the sources define no axis score, and values come only from the
lock scenes, renegotiations and the reconsideration (PM:6987-6989, PM:7522-7524). Its formulas are exact rules that
saves, tests and the composer compute.

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
| I | bool | true, false | `secret_unlock_flag[T]` is set; written only by an invocation (Core Rule 7) | The player invoked the route that transforms this row |
| enabled(T) | bool | `secret_route_enabled.T` (Tuning Knobs) | data | Whether route T ships |
| prereqs_met(T) | bool | see above | data | e.g. WITNESS: PM:11215-11217 |

The formula gives the live value while no ID is stored. The value stored when the coalition holds (T3, T5, T7) is
the formula's result at that moment; afterwards the stored ID is read, never recomputed (Core Rule 9).

Examples:
- (SHARED, ARCHIVE, CHOOSE, false) → `SL-SHARED-ARCHIVE-CHOOSE`.
- (SHARED, ARCHIVE, CHOOSE, true) → `SL-SHARED-ARCHIVE-CHOOSE` (a secret never applies to a valid row).
- (YOU, HEARTH, RESTORE, false) → CRISIS.
- (YOU, HEARTH, RESTORE, true), WITNESS enabled, all three offer prerequisites set → `SL-SECRET-WITNESS`.
- (YOU, HEARTH, RESTORE, true), two of the three set → CRISIS (in play the invocation is not offered, so I stays
  false; the formula still returns CRISIS).
- (NONE, CONTINUITY, RELEASE, true), FIRSTWAKE disabled → CRISIS: the row can only be renegotiated.
- (UNSET, HEARTH, CHOOSE, false) → PENDING.

### Validity

```
invalid(A, F, D) = (A, F, D) ∈ { (YOU, HEARTH, RESTORE), (NONE, ARCHIVE, RELEASE), (NONE, CONTINUITY, RELEASE) }
```

The set is the three rules R1-R3; it is defined only for three set values.

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
NEGOTIATED.

### Reconsideration targets

```
reconsider_targets(id):
    if id is not a valid-row storyline ID, or final_reconsidered,
       or no condition in reconsideration_triggers holds                 → ∅
    (A, F, D) = the axes of id
    → { "SL-" + A + "-" + F' + "-" + D : F' ≠ F, not invalid(A, F', D) }
      ∪ { "SL-" + A + "-" + F + "-" + D' : D' ≠ D, not invalid(A, F, D') }
```

The domain guard excludes PENDING, CRISIS, invalid-row ids and every `SL-SECRET-*`. Authority is never a target, so
`family` is unchanged. Examples with a trigger holding: `SL-YOU-HEARTH-RELEASE` → `SL-YOU-ARCHIVE-RELEASE`,
`SL-YOU-CONTINUITY-RELEASE`, `SL-YOU-HEARTH-CHOOSE` (3; `SL-YOU-HEARTH-RESTORE` is R1); `SL-NONE-HEARTH-RELEASE` →
`SL-NONE-HEARTH-RESTORE`, `SL-NONE-HEARTH-CHOOSE` (2; both Faction changes are R2 and R3).

### Ending family

```
family(id):
    SL-SECRET-WITNESS                          → CONSENT
    SL-SECRET-CROWNLESS, SL-SECRET-FIRSTWAKE   → RESERVED   (unreachable while their routes are disabled)
    "SL-" + A + "-" + F + "-" + D, not invalid(A, F, D) → { YOU → SOLE, SHARED → BOUND, NONE → NONE_AUTH }[A]
    PENDING, CRISIS, an invalid-row id, anything else    → no family (not a storyline ID)
```

Example: `SL-NONE-HEARTH-CHOOSE` → NONE_AUTH; `SL-YOU-HEARTH-RESTORE` → no family.

### Counts

Per family the split is derived, not stated by the source; the design total follows ROADMAP §12.2 and
PM:8728-8729. With the default knobs only Witness Protocol is enabled: `reachable_1_0: 25`.

```
combinations       = 3 × 3 × 3 = 27
valid_count        = 27 − 3 = 24
secret_storylines  = 3
design_storylines  = 24 + 3 = 27
reachable_1_0      = 24 + 1 = 25
family_SOLE        = 9 − 1 = 8
family_BOUND       = 9
family_NONE_AUTH   = 9 − 2 = 7
renegotiations     = 3 × 6 = 18
renegotiations_valid = 18 − 2 = 16
```

`valid_count` subtracts the three invalid rows; SOLE loses R1, NONE_AUTH loses R2 and R3. Each invalid row offers six
renegotiations; only the two Faction changes between R2 and R3 stay invalid.

## Edge Cases

1. **A companion leaves (the plan's edge case).** A companion is absent through relationship flags, never an axis:
   Elara when `has_elara()` is false (`ch1_elara_trusted` and `_cautious` both unset), Seraphina on
   `ch2_seraphina_stayed` / `_rejected`, Lyra on `ch3_lyra_left_alone`, Kaelthas on `ch3_kaelthas_refused` /
   `_challenged`, his betrayal (PM:788), or, outside the Archive, too little trust (PM:7533). The storyline is
   unchanged: no ending family needs a companion (Story Bible §5), so every valid storyline stays reachable with any
   companion — or none — present; the composer omits that companion's modules.
2. **An invalid combination with a secret route half-met.** The crisis continues (Core Rule 5); the signpost lists
   the leads still missing; the invocation scene does not play until every offer prerequisite is set ("Secret routes
   require multiple secret quests", PM:706). The last offer prerequisite lands at the end of Chapter 8
   (PM:7586-7588) and the invocation scenes are in Chapter 9. The player can renegotiate instead at any crisis scene.
3. **R2 or R3 before Crownless / First Wake ship.** Those secret routes are reserved (post-1.0): their invalid rows
   can only be renegotiated. Any flags their side arcs set (05, 08, 09) are kept but never transform a row, and no
   signpost or hint for an unshipped route is shown.
4. **No support for the value the player wants.** The vote still passes, negotiated (PM:6990; Core Rule 3); no
   faction becomes unavailable without warning (PM:6991). The same holds for every lock and renegotiation vote.
5. **Contradictory seeds** (e.g. `act1_report_local` with `ch1_knight_killed`). Both arguments are voiced; the lock
   scene decides, and the vote passes negotiated (`lock_pass`). No error, no tie-break.
6. **Two flags of one exclusive group set** (e.g. two `act1_report_*`). A data error: FlagRegistry boot validation
   (Y1-P1-T03) reports it and refuses the save; this system defines no tie-break.
7. **Timing that goes badly** (`ch1_bridge_fell`, `act1_pace_late`). The storyline ID never changes; the composer
   picks different scene and slide modules (Core Rule 13).
8. **A save from before the coalition holds** (every save today). It loads in LEANING, PARTLY_LOCKED or CRISIS with
   nothing stored; seeds already in the save are read as they are. A save with no axis data loads as LEANING with
   all axes UNSET. A save made after the coalition holds reloads its stored ID unchanged.
9. **NG+.** Whether axis leanings or the previous storyline carry into a new cycle is not decided here (Open
   Questions); until decided, NG+ starts in the Leaning state.
10. **Reaching Root of Heaven without a stored ID.** Every path runs the gate check: the story graph after the
    Chapter 9 end (PM:8206-8207), world-map or free travel, and loading a save positioned inside Root of Heaven.
    With the live ID CRISIS the gate plays the last crisis scene; it always offers renegotiations that reach a valid
    row (all six for R1, five for R2 or R3), so the player cannot be soft-locked, and leaving the scene returns them
    outside the gate with Chapter 9 intact. With PENDING the player is turned back. A save inside Root of Heaven with
    nothing stored (impossible in play; a damaged or edited save) loads at the gate.
11. **Prerequisites met before the locks.** Not possible for any route: each route's last offer prerequisite is set
    after C8-S16, in the Act 3 ledger (PM:7586-7588). C8-S16 never offers the invocation; if a later change moved a
    prerequisite earlier, the invocation would still wait for the route's invocation scene or the gate.
12. **A renegotiation to the same value.** Not offered: a renegotiation offers only the axis's two other values.
13. **A knob changes mid-playthrough** (e.g. a patch disables WITNESS). With an ID stored, nothing changes (Core Rule
    9). During a crisis the change applies at the next crisis or invocation scene: a disabled route loses its
    signpost and its invocation; flags already set are kept. Content for a stored secret storyline must stay
    shippable (a risk logged for Y2-PP-T17).
14. **Final circumstances do not change.** With no reconsideration trigger holding, the final authorization offers
    no reconsideration; the player confirms the stored structure (PM:8788-8790). With the default (empty) trigger
    list this is every 1.0 playthrough.
15. **The player declines the invocation.** The crisis continues; the gate offers it again (Core Rule 7). Once
    confirmed, an invocation cannot be undone.
16. **An unlock flag set without an invocation** (a debug or damaged save). On a valid row it is ignored (`I` is
    ignored for valid rows). With `storyline_state` CRISIS and the transforming route's unlock flag set, the save is
    inconsistent: SaveService reports a data error on load, as for Edge Case 6.

## Dependencies

| System | Direction | What flows | Status of its design doc |
|---|---|---|---|
| Time model (`design/gdd/time-model.md`, Y1-P0-S06b) | this ← time model | per-act pace values (`act1_pace_*` exists; acts 2-4 named there), timing flags | not written yet — S06b must list this GDD as a dependent |
| FlagRegistry / StoryGraph (Y1-P1-T03) | this ← registry | seed flags, the future `AXIS*`, `axis_revised_*`, `lock_negotiated_*`, `final_reconsidered` flags, secret prerequisite and unlock flags, exclusive-group and secret-knob validation | no GDD (an ADR/tech design later) — must cite this GDD's seed map |
| SaveService (Y1-P1-T05) | this → save | the composer input record, with `storyline_state` and `storyline_id`, saved and versioned | no GDD — must store the fields in the composer record |
| Ending composer / route data model (Y2-PP-T17) | this → composer | the composer input record; the lock, crisis, invocation, gate and final authorization contract | not designed — consumes this GDD as its input contract |
| World map / free travel (protected, `AethelgardPrototype/AGENTS.md`) | this → world map | the gate check on entry to Root of Heaven | no GDD — implementation needs the user's explicit approval |
| Companion presence (relationship flags) | this ← companions | `companions_present` | no GDD — must never remove a companion by axis (Core Rule 12) |
| Side storylines (arcs 01-12, `story/source/PRODUCTION_MASTER_2.1.md`) | this ← arcs | seeds into axes, modifiers, secret routes | authored in the production master; S09 (arc 04) and Y1-P1-S04/S05 write into this table |
| Story Bible §5 (`AethelgardPrototype/story/STORY_BIBLE.md`) | both | axes, families, timing table | records the four-family decision (AC-6 line) |
| Difficulty profiles (Y1-P0-S06c) | none | — | deadline leniency belongs to the time model, not here |

Bidirectional rule: each doc above that is written later must name `design/gdd/storyline-axes.md` in its own
Dependencies section.

## Tuning Knobs

All knobs act only while no storyline ID is stored; a stored ID is never recomputed (Core Rule 9). During a crisis
a change applies at the next crisis or invocation scene (Edge Case 13). FlagRegistry checks the secret-route knobs
at boot; a failure is a boot error naming the route (Y1-P1-T03).

| Knob | Default | Safe range | What it affects | Rationale / source |
|---|---|---|---|---|
| `invalid_combinations` (data table) | R1-R3 (3 rows) | only combinations a source contradiction forbids; R1-R3 stay while their secret routes exist (removing a row orphans its route) | `valid_count` (27 − rows), the C8-S16 crises | PM:710-723; changing it also changes ROADMAP §12.2 / Story Bible counts |
| `secret_route_enabled.WITNESS` | true | true for 1.0 | whether R1 can transform into Witness Protocol | D2; Story Bible §5 (Consent family in 1.0) |
| `secret_route_enabled.CROWNLESS`, `.FIRSTWAKE` | false | false until their post-1.0 content ships and their family is designed (never enabled while `family` would be RESERVED) | whether R2 / R3 can transform | D2; Story Bible §5 "post-1.0 candidates" |
| `secret_prerequisites[route]` (list of flags) | WITNESS: `WITNESS_PROTOCOL_FOUND`, `OLD_WITNESS_SIGNATURE`, `WITNESS_SEATS` (PM:11215-11217); CROWNLESS: `CROWN_COORDINATES`, `EMPTY_THRONE_FOUND`, `CROWN_SNAPSHOT_FOUND`, `NO_CROWN_CHARTER` (PM:11242-11245); FIRSTWAKE: `OLD_HOME_MESSAGE`, `FOURTH_HYMN_FOUND`, `EXTERNAL_PING_FOUND`, `EXTERNAL_CARRIER` (PM:11270-11273) | ≥ 2 flags per route ("multiple secret quests"); the three lists disjoint; every flag known to FlagRegistry; no unlock flag in any list | how hard a secret route is to reach; when its signpost and invocation scene appear | PM:706; the production master's "Required flag" lines |
| `secret_unlock_flag[route]` | WITNESS: `SEVEN_WITNESSES_AVAILABLE` (PM:11218); CROWNLESS: `CROWNLESS_AVAILABLE` (PM:11246); FIRSTWAKE: `FIRST_WAKE_AVAILABLE` (PM:11274) | the route's last "Required flag"; written only by its invocation | which flag records the invocation (`I`) | PM:8199-8201 (Chapter 9 ledger "Secret unlock" lines) |
| `reconsideration_triggers` (list of conditions) | empty | conditions defined by Y2-PP-T17 as "final circumstances changed drastically" (PM:8791); empty means no reconsideration is ever offered | whether the final authorization offers the one reconsideration | Core Rule 10; user decision 2026-11-10 |
| `faction_negotiation_allowed` | true | true (a false value would let a faction vanish without warning) | whether a player without support can still pass a lock or renegotiation vote | PM:6990-6991 |

Not knobs (fixed by design): the three axes and their values, the storyline ID format, the family mapping, the
`lock_pass` test, the rule that timing never changes the storyline ID, the rule that Authority is never reconsidered,
and the rule that every lock scene offers all three values. No seed has a numeric weight; values come only from the
lock scenes, renegotiations and the reconsideration (PM:6987-6989).

## Cross-References

- `AethelgardPrototype/story/STORY_BIBLE.md` §4 (cast, companion status), §5 (axes, ending families, timing,
  Act 1 flag tables)
- `AethelgardPrototype/ROADMAP_10_YEAR.md` §12.2 (storyline architecture), §12.4 (time-sensitive world)
- `AethelgardPrototype/story/source/PRODUCTION_MASTER_2.1.md`: axes 634-695, secret axis 697-707, validity 709-723,
  side arcs 1902-4459, Chapter 8 locks 6980-7153, axis validation 7522-7537, Act 3 ledger 7565-7590, invocation
  scenes 8027-8064, Chapter 9 ledger and end 8188-8213, boss phases 8610-8620, C10-S15 seven-witness protocol
  8691-8710, final authorization 8786-8800, route matrix 8973-11126, secret routes 11211-11274, route matrix
  validation 11293-11306
- Also cited: 686 (RELEASE), 6987-6991 (vote influence), 7003-7027 (faction charters and interim roles), 7036-7069
  (Authority proposals and locks), 7093-7095 (Deleted proposals), 5981 / 6664 / 7588 (Witness offer prerequisites)
- `AethelgardPrototype/DESIGN_PILLARS.md` P3, P5, P8; `AethelgardPrototype/AGENTS.md` (protected world-map logic)
- Research input: `production/qa/evidence/2026-11-storyline/research_draft.md`

## Acceptance Criteria

**Document-level — checked today by `production/qa/evidence/2026-11-storyline/check_storyline_axes.py`:**

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
   equals the production master's "Required flag" list for it; the family map in Core Rule 11 and in `family()`
   equals {YOU → SOLE, SHARED → BOUND, NONE → NONE_AUTH}; the side-storyline table has arcs 01-12, each `pm_line` an
   "Axis effect:" line, in arc order; the composer record has the fields storyline_state, storyline_id, authority,
   faction, deleted, secret_route, family, axis_revised, lock_negotiated, final_reconsidered, companions_present,
   regions_completed, timing_flags and act1_pace, with each axis field allowing exactly UNSET plus its three values
   and `storyline_state` exactly the States table's values; `reachable_1_0` equals the valid rows plus the 1.0
   secret rows.
4. The Formulas define `storyline_id(A, F, D, I)` with exactly those four inputs, and its body names no timing,
   pace or companion input; the Core Rules are numbered 1-13 with their titles; the transition table has rows T1-T12
   using only the States table's values; every runtime criterion below names its blocking stories and uses only
   observables from the Observables table.

**Runtime observables** — the contract Y2-PP-T17 (and Y1-P1-T05 for saves) must expose to tests:

| observable | returns |
|---|---|
| `storyline_state()` | the saved `storyline_state` |
| `storyline_id()` | the stored ID if one is stored, else the live formula value (PENDING or CRISIS) |
| `family(id)` | the Formulas' `family` |
| `gate_open()` | true exactly when an ID is stored |
| `enter_root_of_heaven(path)` | for path story, world_map or load: the scene that plays — ROOT_OF_HEAVEN, GATE_CRISIS or TURNED_BACK |
| `crisis_offers()` | in a crisis scene, the offers `revise:<axis>:<value>` and `invoke:<route>`; empty elsewhere |
| `revise(axis, value)` | true if the renegotiation was offered and taken; false (and no change) otherwise |
| `invocation_offered(route)` | in the route's invocation scene or the gate, whether the invocation is offered |
| `invoke(route)` | true if the invocation was offered and confirmed; false otherwise |
| `retraction(axis)` | the commitment the last renegotiation of that axis withdrew (names the old value), or empty |
| `lock_options(axis)` | the values the axis's lock scene offers |
| `lock_arguments(axis)` | the (flag, value, sign) arguments the lock scene voices |
| `lock_negotiated(axis)`, `axis_revised(axis)`, `final_reconsidered()` | the composer record's values |
| `red_lines_voiced(scene)` | the rule ids whose red line or refusal the scene voices |
| `signpost_shown(route)` | whether the journal shows the route's signpost |
| `quoted_commitment()` | the YOU commitment SOVEREIGN quotes |
| `reconsider_offers()` | at the final authorization, the target IDs offered |
| `reconsider(id)`, `confirm_execution()` | take the reconsideration; confirm execution |
| `witnesses()` | the seven witness identities at C10-S15 |
| `composer_modules()` | the module ids the composer selects |
| `boot_errors()` | the data errors found at boot |

**Runtime — each criterion names the stories that must land before it can run:**

5. For every (A, F, D) over {its three values, UNSET} (64 triples) with I = false, `storyline_id()` is `SL-A-F-D`
   for the 24 valid triples, CRISIS for the 3 invalid ones and PENDING for the 37 with an UNSET axis. *Blocked by:*
   Y2-PP-T17.
6. For each of the 24 valid triples with I = true, `storyline_id()` is `SL-A-F-D`. *Blocked by:* Y2-PP-T17.
7. For (YOU, HEARTH, RESTORE) with WITNESS enabled: I = true and all three of `WITNESS_PROTOCOL_FOUND`,
   `OLD_WITNESS_SIGNATURE`, `WITNESS_SEATS` set → `SL-SECRET-WITNESS` and `family(id)` CONSENT; I = true with each
   of the three single-flag-missing subsets → CRISIS; all three set and I = false → CRISIS. *Blocked by:* Y2-PP-T17.
8. For (NONE, ARCHIVE, RELEASE) and (NONE, CONTINUITY, RELEASE) with both routes disabled, I = true and every offer
   prerequisite set → CRISIS; `prereqs_met` of a route whose list has fewer than two flags (including none) is
   false. *Blocked by:* Y2-PP-T17.
9. Crisis and renegotiation, from a C8-S16 fixture save for each invalid triple: `storyline_state()` CRISIS,
   `gate_open()` false, `crisis_offers()` exactly the six `revise:` offers (no `invoke:`). For each of the 18
   renegotiations `revise()` is true; `axis_revised(axis)` and `lock_negotiated(axis)` are true; `retraction(axis)`
   names the old value; and the state is VALIDATED with `storyline_id()` the new row's ID and `gate_open()` true for
   16 of them, CRISIS with `gate_open()` false for the 2 Faction changes between R2 and R3. Revising back
   (NONE-ARCHIVE-RELEASE → Faction CONTINUITY → Faction ARCHIVE) ends in CRISIS on R2. `revise(axis, current
   value)` is false and changes nothing. *Blocked by:* Y2-PP-T17.
10. Valid rows are held: from one VALIDATED fixture per family, `crisis_offers()` is empty and `revise()` and
    `invoke()` are false for every axis, value and route; after every secret prerequisite and unlock flag is set and
    every knob is flipped, `storyline_id()` and `storyline_state()` are unchanged. *Blocked by:* Y2-PP-T17.
11. Seeds never lock: each of the 26 seed flags alone, with no lock scene played, leaves all three axes UNSET,
    `storyline_state()` LEANING and `storyline_id()` PENDING. The same holds with one flag from each exclusive
    group set together. *Blocked by:* Y2-PP-T17; the exclusive-group half also Y1-P1-T03.
12. Lock options, arguments and pass: for each axis `lock_options(axis)` is all three values with no seed set and
    with every seed of that axis set; `lock_arguments(axis)` is exactly the set axis seeds of that axis with their
    value and sign; `lock_negotiated(axis)` follows `lock_pass` on four fixtures (no seed → true; one `+` seed →
    false; a `+` and a `−` seed → true; only a `−` seed → true) and survives a save and reload. *Blocked by:*
    Y2-PP-T17, Y1-P1-T05.
13. Saves: a save made after the coalition holds reloads with the same `storyline_id()`, `storyline_state()` and
    composer record, even after a knob is flipped; a save with no axis data (every save today) loads LEANING, all
    axes UNSET, `storyline_id()` PENDING, no error; a mid-crisis save reloads CRISIS with `gate_open()` false.
    *Blocked by:* Y2-PP-T17, Y1-P1-T05.
14. The gate on every path: for each path in story, world_map, load — in CRISIS `enter_root_of_heaven(path)` is
    GATE_CRISIS, no Root of Heaven scene loads, `crisis_offers()` holds at least five `revise:` offers that reach a
    valid row, and leaving returns the player outside in CRISIS; in LEANING or PARTLY_LOCKED it is TURNED_BACK; in
    VALIDATED it is ROOT_OF_HEAVEN and the state becomes FIXED. *Blocked by:* Y2-PP-T17; the world_map path also the
    approved world-map change.
15. Signposts and invocation: `signpost_shown(WITNESS)` is false with no offer prerequisite set and true once any
    one is set; `signpost_shown` of CROWNLESS and FIRSTWAKE is false while disabled, even with all their flags set.
    With the three Witness offer prerequisites set: on R1 in CRISIS, `invocation_offered(WITNESS)` is true at C9-S19
    and `invoke(WITNESS)` sets `SEVEN_WITNESSES_AVAILABLE`, the state VALIDATED and `storyline_id()`
    `SL-SECRET-WITNESS`; on a valid row C9-S19 plays with `invocation_offered(WITNESS)` false and the unlock flag
    unset; after declining at C9-S19, the gate's `crisis_offers()` includes `invoke:WITNESS`; C8-S16 never offers an
    invocation. *Blocked by:* Y2-PP-T17.
16. Red lines and retractions: `red_lines_voiced()` of C8-S13 and of C8-S14 is {R1, R2, R3}; at C8-S16 on each
    invalid row it is that row's rule alone (Hearth R1, Archive R2, Continuity R3). After a renegotiation reaches
    YOU (from NONE-ARCHIVE-RELEASE), `quoted_commitment()` is the commitment stated in that renegotiation scene.
    *Blocked by:* Y2-PP-T17.
17. Final authorization: with `reconsideration_triggers` empty (every 1.0 configuration) `reconsider_offers()` is
    empty for all 25 storylines, so the rest of this criterion runs only with a test trigger. With one holding,
    `reconsider_offers()` equals `reconsider_targets(id)` for each of the 24 valid IDs (none changes Authority) and
    is empty for `SL-SECRET-WITNESS`; after one `reconsider()`, `final_reconsidered()` is true, `storyline_id()` is
    the target, the changed axis field matches it, `family()` is unchanged and `reconsider_offers()` is empty; after
    `confirm_execution()` the state is FINAL and `storyline_id()` never changes. *Blocked by:* Y2-PP-T17.
18. Consent: on `SL-SECRET-WITNESS`, `family(id)` is CONSENT and the axes are YOU, HEARTH, RESTORE; at C10-S15
    `witnesses()` holds seven identities, none of them Kaelen, including a deleted citizen (PM:8698);
    `storyline_id()` is unchanged after C10-S15 whatever the number of dissenting witnesses. *Blocked by:*
    Y2-PP-T17.
19. `family(id)` over every id: the 24 valid IDs per the family map; `SL-SECRET-WITNESS` → CONSENT;
    `SL-SECRET-CROWNLESS` and `SL-SECRET-FIRSTWAKE` → RESERVED; PENDING, CRISIS, the 3 invalid-row ids and the empty
    string → no family. *Blocked by:* Y2-PP-T17.
20. Companions and timing: from one Chapter 8 fixture per family, playing the same lock choices with each of the 16
    subsets of the four companions present, crossed with the timing sets {`act1_pace_early`, `ch1_bridge_saved`}
    and {`act1_pace_late`, `ch1_bridge_fell`}, the resulting `storyline_id()` and `family()` are the expected ones;
    `composer_modules()` differs between the two timing sets and holds no module of an absent companion.
    *Blocked by:* Y2-PP-T17, Y1-P0-S06b.
21. Boot validation: `boot_errors()` names the route when a `secret_prerequisites` list has fewer than two flags,
    two lists share a flag, a flag is unknown to FlagRegistry, or an unlock flag appears in a prerequisites list;
    with the default knobs it is empty. *Blocked by:* Y2-PP-T17, Y1-P1-T03.

**Validation note:** the route bot of ROADMAP §12.4 starts from Chapter 8 fixture saves (not full playthroughs)
once the locks exist (owner Y2-PP-T17): one run per 1.0 storyline (24 valid + `SL-SECRET-WITNESS` through C9-S19 =
25), one per crisis renegotiation (18) and one per gate path (3); a run passes when the stored ID equals the
expected one (PM:11304).

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
   master also lets Nema, Seven, Rook and Kaito stay or leave on any route (PM:7534-7537). This GDD uses the 4;
   `companions_present` grows when the others are confirmed.
7. **Systems index:** `design/gdd/systems-index.md` does not exist; `/map-systems` creates it later (D3).
8. **Story Bible §5** gives the Consent family the God King "loses its health bar" fight, which the production
   master gives to Crownless (PM:11247); a separate Story Bible fix.
9. **Truth strategy** (Seraphina's disclosure) is its own composer module in the production master (PM:8739); owner
   Y2-PP-T17.
10. **Seed readings kept despite review objections (2026-11-10):** `ch1_aldric_kill_unsure` → SHARED may read as
    deferral ("don't decide it tonight", `aldric.dlg:90`); `ch2_data_wraith_destroyed` → RELEASE is a unilateral
    destruction while RELEASE ends involuntary preservation (PM:686, PM:7094); `ch1_root_purge` is a non-consensual
    rewrite that could argue for YOU instead of Hearth. Revisit in a narrative pass.
11. **Chapter 9 with a broken coalition:** how Chapter 9 plays while a crisis lasts (scenes, ally reactions), and
    whether it adds crisis scenes between C8-S16 and the gate, is for Y2-PP-T17.
12. **Deferred to Y2-PP-T17:** the Story+ rotating witness institution (PM:11220); the concrete
    `reconsideration_triggers`; the signpost texts; the witness threshold ("Player previously helped define
    threshold", PM:8707 — no scene in the sources defines it) and whether C10-S15 can fall short of it (if it can,
    only modules change, never the stored ID).
