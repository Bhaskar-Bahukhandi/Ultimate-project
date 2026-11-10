# Storyline Axes

> **Status**: Draft (revision 2, after design review round 2)
> **Author**: Claude (narrative-director research) with the project lead
> **Last Updated**: 2026-11-10
> **Last Verified**: 2026-11-10
> **Implements Pillar**: P3 (24 storylines + 3 secret from three story axes), P5 (side storylines feed the main
> story), P8 (Story+, a playable after-story per storyline) — DESIGN_PILLARS.md, ROADMAP §12.2

## Summary

Three story axes — who holds Root (Authority), which society Kaelen backs (Faction), and what happens to the
deleted (Deleted) — combine into 27 configurations; 24 are valid storylines, 3 are contradictions that only a
secret route can transform. Four ending families carry the depth; Faction and Deleted modify them. Every save
tracks one stable storyline ID, fixed at the entry to Root of Heaven, and the ending composer builds the ending
from that ID plus companions, regions and timing.

> **Quick reference** — Layer: `Foundation` · Priority: `Alpha`

## Overview

Aethelgard's main story does not branch into 27 separately written routes. In Chapter 8, Kaelen's choices lock
three axes: **Authority** (Kaelen alone, shared and auditable, or abolished), **Faction** (Hearth Compact, Archive
Covenant or Continuity League) and **the Deleted** (restore them, release them, or let each person choose). The
three locked values name one of 24 valid storylines (`SL-AUTHORITY-FACTION-DELETED`); three combinations break the
coalition (PM:710-723), and the player must renegotiate one axis before Root of Heaven unless they have met a
secret route's prerequisites, which turn that contradiction into Witness Protocol (in 1.0), Crownless or First Wake
(post-1.0). The storyline ID is fixed at the **ID-lock gate** (the entry to Root of Heaven) and confirmed at the
**final authorization** (the post-boss scene, PM:8786-8794), which may offer one costly reconsideration. The
Authority value picks one of four ending families (Sole, Bound, No Authority; Consent for Witness Protocol), each
with its own God King phase, final scene and Story+ arc; Faction and Deleted change a boss phase, ally lines,
epilogue slides and which Story+ cases unlock. Act 1 flags seed arguments, twelve side storylines push them, and
timing changes scenes and slides without ever changing the storyline ID — so authored cost stays additive.

## Player Fantasy

The player holds a key that could rewrite the world, and the game keeps asking whether they have the right to turn
it (Story Bible §1: "Capability is not legitimacy"). The axes are how that question becomes theirs: not a morality
meter, but three answers they build up through what Kaelen does — who he lets hold Root, whose society he stands
with, and whether the deleted are brought back, let go, or asked.

- **Authorship, not a menu.** Each lock is a vote between proposals, never a picker of labels ("Options are
  proposals not Kaelen menu labels", PM:6983), and the scene argues with the player's own history: the Act 1
  choices and side storylines they may not have read as political come back as the arguments for and against each
  proposal, so the storyline at the end feels arrived at.
- **Costs are real.** Every valid storyline loses something; the three invalid combinations are where a coalition
  refuses to follow. Faction leaders say where their red lines are before the last lock, the coalition breaks in
  Chapter 8 instead of failing silently at the ending screen (PM:7153), and a renegotiation is remembered.
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
- **Crisis scene**: C8-S16 when the third lock completes an invalid row (PM:7138-7153), and every later Assembly
  scene that offers a renegotiation while the crisis lasts (owner Y2-PP-T17).
- **ID-lock gate**: the entry to Root of Heaven (Chapter 10). The storyline ID is computed and stored here; the
  gate is closed while the live ID is PENDING or CRISIS (PM:722; PM:11305 "intercepted before final boss").
- **Final authorization**: the immediate post-boss scene (PM:8786-8794). The world asks for the authorization
  result, the system displays the chosen structure, and the player confirms execution.

### Core Rules

1. **Three axes, one value each at the gate.** Authority ∈ {YOU, SHARED, NONE}; Faction ∈ {HEARTH, ARCHIVE,
   CONTINUITY}; Deleted ∈ {RESTORE, RELEASE, CHOOSE}; each starts UNSET. At the ID-lock gate each axis holds exactly
   one value (PM:7522-7524, "Axis validation").
2. **Seeds are arguments, never gates.** Act 1 seeds, side storylines, companion persuasion and faction support
   are leanings: each axis seed makes its lock scene voice an argument for (`+`) or against (`−`) its value
   ("Player influence can back one. Companion persuasion and side quests matter.", PM:6987-6988). Every lock scene
   always offers all three values; no seed adds or removes an option. No seed sets a value; only the lock scene
   does ("This sets Faction Axis if vote passes.", PM:6989). The sources define no axis score.
3. **Lock scenes resolve.** Faction → `AXIS2_HEARTH` / `_ARCHIVE` / `_CONTINUITY`; Authority → `AXIS1_YOU` /
   `_SHARED` / `_NONE`; Deleted → `AXIS3_RESTORE` / `_RELEASE` / `_CHOOSE`. These flags are not in the code yet
   (owner: Y2-PP-T17). A lock vote always passes for the proposal the player backs, through support or negotiation
   (PM:6990-6991; knob `faction_negotiation_allowed`), so no vote leaves an axis UNSET. **Red lines:** in C8-S13 and
   C8-S14 each faction's delegate says, in the fiction, which combination their faction will refuse (R1-R3 below).
   There is no system warning before the third lock; the conflict becomes visible at C8-S16 (PM:7138).
4. **An invalid combination is a political crisis, not a fail state.** If the three locked values form an invalid
   row (R1-R3), the coalition breaks at C8-S16 (PM:7138-7153), "presented as a political crisis rather than a menu
   error" (PM:723). The crisis may last through Chapter 9. In any crisis scene before the gate, the player may
   renegotiate one locked axis to one of its two other values: Kaelen retracts his earlier position on the record
   and the Assembly votes again. The superseded commitments (Kaelen's Authority vow, PM:7045-7050, and the answer
   SOVEREIGN later quotes, PM:7059-7060; a faction role or charter, PM:7006-7027) are explicitly withdrawn in that
   scene, never silently erased, and `axis_revised_<axis>` is set for the composer (no numeric weight). A
   renegotiation that lands on another invalid row keeps the crisis open. Root of Heaven cannot be entered during a
   crisis.
5. **Secret invocation.** If the route T that transforms the current invalid row is enabled and every one of its
   prerequisites is met, each crisis scene offers the player the secret mechanism (for Witness Protocol, convening
   the seven witnesses); invoking it sets `secret_invoked` and transforms the row into `SL-SECRET-T`. The player
   may renegotiate instead. Any renegotiation clears `secret_invoked`. A route's remaining requirements are
   signposted once its first prerequisite is found (PM:707; PM:11214). The last Witness prerequisite,
   `SEVEN_WITNESSES_AVAILABLE`, is set in the Chapter 9 consequence ledger (PM:8200); the other three are set
   earlier (PM:5981, PM:6664, PM:7588). Witness Protocol is in 1.0; Crownless and First Wake are reserved
   (post-1.0): until they ship, their rows can only be renegotiated.
6. **A valid row is held to its word.** Once the three locks form a valid row (or a secret transformation
   applies), no renegotiation is offered before the gate.
7. **Storyline ID.** At the ID-lock gate the live ID (Formulas) is stored: `SL-{authority}-{faction}-{deleted}` or
   `SL-SECRET-{route}`. Before the gate it is PENDING or CRISIS and nothing is stored. Once stored, the ID is never
   recomputed from flags or knobs; it changes at most once, at the final authorization (rule 8), and is final once
   execution is confirmed (PM:11303, "Every route must save a stable storyline ID").
8. **Final authorization and reconsideration.** The post-boss scene displays the stored structure with no generic
   menu (PM:8788-8789). If a condition in `reconsideration_triggers` holds ("if final circumstances changed
   drastically", PM:8791), it offers one last lawful reconsideration: exactly one axis may change, only to a value
   that forms another valid row, at most once per playthrough, never for a secret storyline. It is on the record
   ("It cannot silently switch", PM:8794), sets `final_reconsidered` for the composer ("Reconsideration is not
   free. It may break coalition.", PM:8792-8793), and replaces the stored ID. Then the player confirms execution.
9. **Ending family** = the Authority value (YOU → SOLE, SHARED → BOUND, NONE → NONE_AUTH), or CONSENT for Witness
   Protocol (Story Bible §5). **Bound** is a standing institution: Kaelen gives up unilateral final commit to a
   seven-signature protocol with rotating seats and public audit (PM:7062-7070). **No Authority**: the Assembly
   adopts abolition at C8-S14, and Kaelen uses the Key once, at the final confrontation, to dismantle permanent
   Root capability (PM:7036-7038). **Consent** keeps Root capability (Kaelen-held for execution, PM:11213) but
   moves the authority for one named transition — the restoration — to seven affected witnesses, without permanent
   Root ownership (PM:705). The protocol requires a threshold, not unanimity; witnesses can dissent and the scene
   names it; Kaelen may be one witness but cannot fill multiple roles (PM:8704-8708). Consent differs from No
   Authority (Root is not abolished; one act is authorized) and from Bound (the ending authorizes one act; it does
   not set up a standing signature protocol). For `SL-SECRET-WITNESS` the axes keep their locked values (YOU,
   HEARTH, RESTORE); the family is CONSENT. Faction and Deleted are modifiers: a boss phase, ally lines, epilogue
   slides, Story+ cases.
10. **Companions are independent of the axes.** Every storyline can include every surviving companion
    (PM:7529-7533, PM:11302); a companion leaves through relationship flags (Edge Cases), never through an axis.
11. **Timing is a modifier.** Pace values and timing flags change scenes, NPC fates, market events and ending slides
    through the composer, not the storyline ID (ROADMAP §12.4; PM:7527).

### States and Transitions

| State | Entry Condition | Exit Condition | Behavior |
|-------|----------------|----------------|----------|
| Leaning | New Game | C8-S13 resolves | Every axis UNSET; live ID PENDING; seeds and side storylines collect arguments |
| Partly locked | One or two lock scenes resolved | C8-S16 resolves | Live ID PENDING; faction delegates state their red lines (Core Rule 3) |
| Crisis | C8-S16, or a renegotiation, yields an invalid row | A renegotiation yields a valid row → Validated; a renegotiation yields another invalid row → Crisis; the player invokes the enabled, fully met transforming route → Validated | Live ID CRISIS; coalition broken; every crisis scene offers renegotiation of any locked axis (its two other values) and, when Core Rule 5 holds, the secret invocation; the gate is closed. If the route's prerequisites were met before the locks, C8-S16 offers the invocation at once |
| Validated | C8-S16 yields a valid row, or a renegotiation does, or the secret invocation | The player enters the ID-lock gate | Live ID is a storyline ID; no renegotiation offered (Core Rule 6) |
| Storyline fixed | The ID-lock gate | Final authorization confirmed | Stored ID read by the boss phases and the composer; lock and crisis scenes closed |
| Storyline final | Execution confirmed (after at most one reconsideration) | Never, for this playthrough | Stored ID never changes |

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
derived (Counts). For a valid row `source` is its route heading in the production master's route matrix; for an
invalid row, its validity line. `companions_possible` is the same in every row by design (Core Rule 10).

| id | authority | faction | deleted | status | family | rule | source | companions_possible |
|---|---|---|---|---|---|---|---|---|
| SL-YOU-HEARTH-RESTORE | YOU | HEARTH | RESTORE | invalid | — | R1 | PRODUCTION_MASTER_2.1.md:713 | Elara, Seraphina, Lyra, Kaelthas |
| SL-YOU-HEARTH-RELEASE | YOU | HEARTH | RELEASE | valid | SOLE | — | PRODUCTION_MASTER_2.1.md:8978 | Elara, Seraphina, Lyra, Kaelthas |
| SL-YOU-HEARTH-CHOOSE | YOU | HEARTH | CHOOSE | valid | SOLE | — | PRODUCTION_MASTER_2.1.md:9071 | Elara, Seraphina, Lyra, Kaelthas |
| SL-YOU-ARCHIVE-RESTORE | YOU | ARCHIVE | RESTORE | valid | SOLE | — | PRODUCTION_MASTER_2.1.md:9164 | Elara, Seraphina, Lyra, Kaelthas |
| SL-YOU-ARCHIVE-RELEASE | YOU | ARCHIVE | RELEASE | valid | SOLE | — | PRODUCTION_MASTER_2.1.md:9257 | Elara, Seraphina, Lyra, Kaelthas |
| SL-YOU-ARCHIVE-CHOOSE | YOU | ARCHIVE | CHOOSE | valid | SOLE | — | PRODUCTION_MASTER_2.1.md:9350 | Elara, Seraphina, Lyra, Kaelthas |
| SL-YOU-CONTINUITY-RESTORE | YOU | CONTINUITY | RESTORE | valid | SOLE | — | PRODUCTION_MASTER_2.1.md:9443 | Elara, Seraphina, Lyra, Kaelthas |
| SL-YOU-CONTINUITY-RELEASE | YOU | CONTINUITY | RELEASE | valid | SOLE | — | PRODUCTION_MASTER_2.1.md:9536 | Elara, Seraphina, Lyra, Kaelthas |
| SL-YOU-CONTINUITY-CHOOSE | YOU | CONTINUITY | CHOOSE | valid | SOLE | — | PRODUCTION_MASTER_2.1.md:9629 | Elara, Seraphina, Lyra, Kaelthas |
| SL-SHARED-HEARTH-RESTORE | SHARED | HEARTH | RESTORE | valid | BOUND | — | PRODUCTION_MASTER_2.1.md:9722 | Elara, Seraphina, Lyra, Kaelthas |
| SL-SHARED-HEARTH-RELEASE | SHARED | HEARTH | RELEASE | valid | BOUND | — | PRODUCTION_MASTER_2.1.md:9815 | Elara, Seraphina, Lyra, Kaelthas |
| SL-SHARED-HEARTH-CHOOSE | SHARED | HEARTH | CHOOSE | valid | BOUND | — | PRODUCTION_MASTER_2.1.md:9908 | Elara, Seraphina, Lyra, Kaelthas |
| SL-SHARED-ARCHIVE-RESTORE | SHARED | ARCHIVE | RESTORE | valid | BOUND | — | PRODUCTION_MASTER_2.1.md:10001 | Elara, Seraphina, Lyra, Kaelthas |
| SL-SHARED-ARCHIVE-RELEASE | SHARED | ARCHIVE | RELEASE | valid | BOUND | — | PRODUCTION_MASTER_2.1.md:10094 | Elara, Seraphina, Lyra, Kaelthas |
| SL-SHARED-ARCHIVE-CHOOSE | SHARED | ARCHIVE | CHOOSE | valid | BOUND | — | PRODUCTION_MASTER_2.1.md:10187 | Elara, Seraphina, Lyra, Kaelthas |
| SL-SHARED-CONTINUITY-RESTORE | SHARED | CONTINUITY | RESTORE | valid | BOUND | — | PRODUCTION_MASTER_2.1.md:10280 | Elara, Seraphina, Lyra, Kaelthas |
| SL-SHARED-CONTINUITY-RELEASE | SHARED | CONTINUITY | RELEASE | valid | BOUND | — | PRODUCTION_MASTER_2.1.md:10373 | Elara, Seraphina, Lyra, Kaelthas |
| SL-SHARED-CONTINUITY-CHOOSE | SHARED | CONTINUITY | CHOOSE | valid | BOUND | — | PRODUCTION_MASTER_2.1.md:10466 | Elara, Seraphina, Lyra, Kaelthas |
| SL-NONE-HEARTH-RESTORE | NONE | HEARTH | RESTORE | valid | NONE_AUTH | — | PRODUCTION_MASTER_2.1.md:10559 | Elara, Seraphina, Lyra, Kaelthas |
| SL-NONE-HEARTH-RELEASE | NONE | HEARTH | RELEASE | valid | NONE_AUTH | — | PRODUCTION_MASTER_2.1.md:10652 | Elara, Seraphina, Lyra, Kaelthas |
| SL-NONE-HEARTH-CHOOSE | NONE | HEARTH | CHOOSE | valid | NONE_AUTH | — | PRODUCTION_MASTER_2.1.md:10745 | Elara, Seraphina, Lyra, Kaelthas |
| SL-NONE-ARCHIVE-RESTORE | NONE | ARCHIVE | RESTORE | valid | NONE_AUTH | — | PRODUCTION_MASTER_2.1.md:10838 | Elara, Seraphina, Lyra, Kaelthas |
| SL-NONE-ARCHIVE-RELEASE | NONE | ARCHIVE | RELEASE | invalid | — | R2 | PRODUCTION_MASTER_2.1.md:715 | Elara, Seraphina, Lyra, Kaelthas |
| SL-NONE-ARCHIVE-CHOOSE | NONE | ARCHIVE | CHOOSE | valid | NONE_AUTH | — | PRODUCTION_MASTER_2.1.md:10931 | Elara, Seraphina, Lyra, Kaelthas |
| SL-NONE-CONTINUITY-RESTORE | NONE | CONTINUITY | RESTORE | valid | NONE_AUTH | — | PRODUCTION_MASTER_2.1.md:11024 | Elara, Seraphina, Lyra, Kaelthas |
| SL-NONE-CONTINUITY-RELEASE | NONE | CONTINUITY | RELEASE | invalid | — | R3 | PRODUCTION_MASTER_2.1.md:717 | Elara, Seraphina, Lyra, Kaelthas |
| SL-NONE-CONTINUITY-CHOOSE | NONE | CONTINUITY | CHOOSE | valid | NONE_AUTH | — | PRODUCTION_MASTER_2.1.md:11117 | Elara, Seraphina, Lyra, Kaelthas |

SHARED and CHOOSE appear in no invalid row, so any row holding one of them can never reach a crisis: a known safe
pick. Each storyline's own loss is authored per route (owner Y2-PP-T17; Open Questions).

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

`storyline_id` and `family` are stored beside this record by SaveService (Y1-P1-T05), which owns serialisation and
the schema version.

| field | type | allowed | writer |
|---|---|---|---|
| authority | enum | UNSET, YOU, SHARED, NONE | owner story Y2-PP-T17 (route architecture data model); lock scene C8-S14 (PM:7029-7087) |
| faction | enum | UNSET, HEARTH, ARCHIVE, CONTINUITY | owner story Y2-PP-T17; lock scene C8-S13 (PM:6980-7027) |
| deleted | enum | UNSET, RESTORE, RELEASE, CHOOSE | owner story Y2-PP-T17; lock scene C8-S16 (PM:7134-7137) |
| secret_route | enum | NO_SECRET, WITNESS, FIRSTWAKE, CROWNLESS | derived from the stored ID (`SL-SECRET-T` → T, else NO_SECRET); never written on its own |
| axis_revised | set | faction, authority, deleted | crisis renegotiation scenes (Core Rule 4); owner Y2-PP-T17 |
| final_reconsidered | bool | true, false | final authorization scene (Core Rule 8); owner Y2-PP-T17 |
| companions_present | set | Elara, Seraphina, Lyra, Kaelthas | `AethelgardPrototype/scripts/game_manager.gd` (`has_elara`, exclusive flag groups); `AethelgardPrototype/dialogue/ch2/fragment_two.dlg` |
| regions_completed | set | ids of the eight regions | owner story Y2-PP-T17 (no writer in the code today) |
| timing_flags | set of flags | `ch1_bridge_saved` / `_evacuated` / `_fell`, `ch2_medicine_early` / `_on_time` / `_late` | `AethelgardPrototype/dialogue/ch1/north_field.dlg`; `AethelgardPrototype/dialogue/ch2/act1_end.dlg` |
| act1_pace | enum | act1_pace_early, act1_pace_on_time, act1_pace_late | `AethelgardPrototype/dialogue/ch2/act1_end.dlg` |
| act2_pace, act3_pace, act4_pace | enum | names left to S06b | owner story Y1-P0-S06b |

### Interactions with Other Systems

- **FlagRegistry / StoryGraph (Y1-P1-T03):** owns the seed flags and, later, the `AXIS*`, `axis_revised_*`,
  `secret_invoked` and `final_reconsidered` flags; validates exclusive groups; this GDD names them, it does not
  write them.
- **SaveService (Y1-P1-T05):** stores the storyline ID, the family and the composer input record; a stored ID is
  never recomputed.
- **Time model (S06b):** supplies pace values per act and the timing flags the composer reads.
- **Ending composer / route data model (owner Y2-PP-T17):** implements `storyline_id` (Formulas), the lock,
  crisis and renegotiation scenes, the red lines, the secret prerequisites and invocation, the gate, the final
  authorization and the modules; authored cost additive.
- **Companion system:** reads relationship flags for presence; never reads an axis to remove a companion.
- **Side storylines (arcs 01-12):** push arguments into axes or modifiers per the table above.

## Formulas

The storyline system defines no balance numbers: the sources define no axis score, and values come only from the
lock scenes (PM:6987-6989, PM:7522-7524). Its formulas are exact rules that saves, tests and the composer compute.

### Storyline ID

```
storyline_id(A, F, D, I):
    if A, F or D is UNSET                        → PENDING
    if not invalid(A, F, D)                      → "SL-" + A + "-" + F + "-" + D      (I is ignored)
    T = transform(A, F, D)                       # R1 → WITNESS, R2 → CROWNLESS, R3 → FIRSTWAKE
    if I and enabled(T) and prereqs_met(T)       → "SL-SECRET-" + T
    otherwise                                    → CRISIS                             (Core Rule 4)

prereqs_met(T) = secret_prerequisites[T] is non-empty and every flag in it is set
```

| Variable | Type | Range | Source | Description |
|---|---|---|---|---|
| A | enum | YOU, SHARED, NONE, UNSET | C8-S14 lock | Authority |
| F | enum | HEARTH, ARCHIVE, CONTINUITY, UNSET | C8-S13 lock | Faction |
| D | enum | RESTORE, RELEASE, CHOOSE, UNSET | C8-S16 lock | The deleted |
| I | bool | true, false | `secret_invoked`, written only by a crisis scene (Core Rule 5) | The player invoked the transforming route; cleared by any renegotiation |
| enabled(T) | bool | `secret_route_enabled.T` (Tuning Knobs) | data | Whether route T ships |
| prereqs_met(T) | bool | see above | data | e.g. WITNESS: PM:11215-11218 |

The live value is evaluated while nothing is stored. At the ID-lock gate it must be a storyline ID (the gate is
closed for PENDING and CRISIS) and is stored; from then on the stored ID is read, never recomputed (Core Rule 7).

Examples:
- (SHARED, ARCHIVE, CHOOSE, false) → `SL-SHARED-ARCHIVE-CHOOSE`.
- (SHARED, ARCHIVE, CHOOSE, true) → `SL-SHARED-ARCHIVE-CHOOSE` (a secret never applies to a valid row).
- (YOU, HEARTH, RESTORE, false) → CRISIS.
- (YOU, HEARTH, RESTORE, true), WITNESS enabled, all four Witness flags set → `SL-SECRET-WITNESS`.
- (YOU, HEARTH, RESTORE, true), three of four flags set → CRISIS (the invocation is not offered, so I stays false
  in play; the formula still returns CRISIS).
- (NONE, CONTINUITY, RELEASE, true), FIRSTWAKE disabled → CRISIS: the row can only be renegotiated.
- (UNSET, HEARTH, CHOOSE, false) → PENDING.

### Validity

```
invalid(A, F, D) = (A, F, D) ∈ { (YOU, HEARTH, RESTORE), (NONE, ARCHIVE, RELEASE), (NONE, CONTINUITY, RELEASE) }
```

The set is the three rules R1-R3; it is defined only for three set values.

### Reconsideration targets

```
reconsider_targets(id):
    if id is SL-SECRET-*, or final_reconsidered, or no condition in reconsideration_triggers holds → ∅
    else → { "SL-" + A' + "-" + F' + "-" + D' : exactly one of (A', F', D') differs from id's axes,
                                                 and not invalid(A', F', D') }
```

Example: `SL-YOU-HEARTH-RELEASE` with a trigger holding → six single-axis changes minus `SL-YOU-HEARTH-RESTORE`
(R1) = 5 targets.

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

combinations = |A| × |F| × |D| = 3 × 3 × 3 = 27 (set values only); valid_count = 27 − |invalid set| = 24; secret
storylines = 3 (one per invalid row); storylines in the design = 24 + 3 = 27 (ROADMAP §12.2; PM:8728-8729).
With the default knobs only Witness Protocol is enabled: `reachable_1_0: 25` (24 + 1). Per family (derived, not
stated by the source): SOLE = 9 − 1 (R1) = 8; BOUND = 9; NONE_AUTH = 9 − 2 (R2, R3) = 7.

## Edge Cases

1. **A companion leaves (the plan's edge case).** A companion is absent through relationship flags, never an axis:
   Elara when `has_elara()` is false (`ch1_elara_trusted` and `_cautious` both unset), Seraphina on
   `ch2_seraphina_stayed` / `_rejected`, Lyra on `ch3_lyra_left_alone`, Kaelthas on `ch3_kaelthas_refused` /
   `_challenged` or his betrayal (PM:788). The storyline is unchanged: no ending family needs a companion
   (Story Bible §5), so every valid storyline stays reachable with any companion — or none — present; the composer
   omits that companion's modules.
2. **An invalid combination with a secret route half-met.** The crisis continues (Core Rule 4): no invocation is
   offered and the live ID is CRISIS until every prerequisite of the transforming route is met ("Secret routes
   require multiple secret quests", PM:706). The last Witness prerequisite lands in the Chapter 9 ledger (PM:8200).
   The player can renegotiate instead at any point before the gate.
3. **R2 or R3 before Crownless / First Wake ship.** Those secret routes are reserved (post-1.0): their invalid rows
   can only be renegotiated. Any flags their side arcs set (05, 08, 09) are kept but never transform a row, and no
   hint for an unshipped route is shown.
4. **No support for the faction the player wants.** The C8-S13 vote still passes through negotiation (PM:6990);
   no faction becomes unavailable without warning (PM:6991). The same holds for every lock and renegotiation vote
   (Core Rule 3).
5. **Contradictory seeds** (e.g. `act1_report_local` with `ch1_knight_killed`). Both arguments are voiced; the lock
   scene decides. No error, no tie-break.
6. **Two flags of one exclusive group set** (e.g. two `act1_report_*`). A data error: FlagRegistry boot validation
   (Y1-P1-T03) reports it and refuses the save; this system defines no tie-break.
7. **Timing that goes badly** (`ch1_bridge_fell`, `act1_pace_late`). The storyline ID never changes; the composer
   picks different scene and slide modules (Core Rule 11).
8. **A save from before the gate** (every save today). Its live ID is PENDING (or CRISIS mid-crisis) and nothing
   is stored; seeds already in the save are read as they are. A save with no axis data loads as all axes UNSET.
9. **NG+.** Whether axis leanings or the previous storyline carry into a new cycle is not decided here (Open
   Questions); until decided, NG+ starts in the Leaning state.
10. **Reaching Root of Heaven during a crisis.** Impossible: the gate is closed while the live ID is CRISIS (PM:722,
    PM:11305); the crisis scenes keep offering the renegotiation.
11. **Prerequisites met before the locks.** The crisis still opens at C8-S16 — the coalition still breaks — and the
    same scene offers the secret invocation at once (States table).
12. **A renegotiation to the same value.** Not offered: a renegotiation offers only the axis's two other values.
13. **A knob changes after a save stored its ID** (e.g. a patch disables WITNESS). The stored ID is never
    recomputed (Core Rule 7); the knobs act only while nothing is stored. Content for a stored secret storyline
    must stay shippable (a risk logged for Y2-PP-T17).
14. **Final circumstances do not change.** With no reconsideration trigger holding, the final authorization offers
    no reconsideration; the player confirms the stored structure (PM:8788-8790).

## Dependencies

| System | Direction | What flows | Status of its design doc |
|---|---|---|---|
| Time model (`design/gdd/time-model.md`, Y1-P0-S06b) | this ← time model | per-act pace values (`act1_pace_*` exists; acts 2-4 named there), timing flags | not written yet — S06b must list this GDD as a dependent |
| FlagRegistry / StoryGraph (Y1-P1-T03) | this ← registry | seed flags, the future `AXIS*`, `axis_revised_*`, `secret_invoked`, `final_reconsidered` flags, exclusive-group validation | no GDD (an ADR/tech design later) — must cite this GDD's seed map |
| SaveService (Y1-P1-T05) | this → save | storyline ID and the composer input record, saved and versioned | no GDD — must store the fields in the composer record |
| Ending composer / route data model (Y2-PP-T17) | this → composer | the composer input record; the lock, crisis, gate and final authorization contract | not designed — consumes this GDD as its input contract |
| Companion presence (relationship flags) | this ← companions | `companions_present` | no GDD — must never remove a companion by axis (Core Rule 10) |
| Side storylines (arcs 01-12, `story/source/PRODUCTION_MASTER_2.1.md`) | this ← arcs | seeds into axes, modifiers, secret routes | authored in the production master; S09 (arc 04) and Y1-P1-S04/S05 write into this table |
| Story Bible §5 (`AethelgardPrototype/story/STORY_BIBLE.md`) | both | axes, families, timing table | records the four-family decision (AC-6 line) |
| Difficulty profiles (Y1-P0-S06c) | none | — | deadline leniency belongs to the time model, not here |

Bidirectional rule: each doc above that is written later must name `design/gdd/storyline-axes.md` in its own
Dependencies section.

## Tuning Knobs

All knobs act only while no storyline ID is stored; a stored ID is never recomputed (Core Rule 7).

| Knob | Default | Safe range | What it affects | Rationale / source |
|---|---|---|---|---|
| `invalid_combinations` (data table) | R1-R3 (3 rows) | only combinations a source contradiction forbids; R1-R3 stay while their secret routes exist (removing a row orphans its route) | `valid_count` (27 − rows), the C8-S16 crises | PM:710-723; changing it also changes ROADMAP §12.2 / Story Bible counts |
| `secret_route_enabled.WITNESS` | true | true for 1.0 | whether R1 can transform into Witness Protocol | D2; Story Bible §5 (Consent family in 1.0) |
| `secret_route_enabled.CROWNLESS`, `.FIRSTWAKE` | false | false until their post-1.0 content ships and their family is designed (never enabled while `family` would be RESERVED) | whether R2 / R3 can transform | D2; Story Bible §5 "post-1.0 candidates" |
| `secret_prerequisites[route]` (list of flags) | WITNESS: `WITNESS_PROTOCOL_FOUND`, `OLD_WITNESS_SIGNATURE`, `WITNESS_SEATS`, `SEVEN_WITNESSES_AVAILABLE` (PM:11215-11218); CROWNLESS: `CROWN_COORDINATES`, `EMPTY_THRONE_FOUND`, `CROWN_SNAPSHOT_FOUND`, `NO_CROWN_CHARTER`, `CROWNLESS_AVAILABLE` (PM:11242-11246); FIRSTWAKE: `OLD_HOME_MESSAGE`, `FOURTH_HYMN_FOUND`, `EXTERNAL_PING_FOUND`, `EXTERNAL_CARRIER`, `FIRST_WAKE_AVAILABLE` (PM:11270-11274) | ≥ 2 flags per route ("multiple secret quests"); an empty list never counts as met | how hard a secret route is to reach | PM:706; the production master's "Required flag" lines |
| `reconsideration_triggers` (list of conditions) | empty | conditions defined by Y2-PP-T17 as "final circumstances changed drastically" (PM:8791); empty means no reconsideration is ever offered | whether the final authorization offers the one reconsideration | Core Rule 8; user decision 2026-11-10 |
| `faction_negotiation_allowed` | true | true (a false value would let a faction vanish without warning) | whether a player without support can still pass a lock or renegotiation vote | PM:6990-6991 |

Not knobs (fixed by design): the three axes and their values, the storyline ID format, the family mapping, the rule
that timing never changes the storyline ID, and the rule that every lock scene offers all three values. No seed has
a numeric weight; values come only from the lock scenes (PM:6987-6989).

## Cross-References

- `AethelgardPrototype/story/STORY_BIBLE.md` §4 (cast, companion status), §5 (axes, ending families, timing,
  Act 1 flag tables)
- `AethelgardPrototype/ROADMAP_10_YEAR.md` §12.2 (storyline architecture), §12.4 (time-sensitive world)
- `AethelgardPrototype/story/source/PRODUCTION_MASTER_2.1.md`: axes 634-695, secret axis 697-707, validity 709-723,
  side arcs 1902-4459, Chapter 8 locks 6980-7153, axis validation 7522-7537, seven-witness protocol 8700-8708,
  final authorization 8786-8794, route matrix 8973-11117, secret routes 11211-11274, route matrix validation
  11293-11305
- Also cited: 6987-6991 (vote influence), 7062-7070 (shared protocol), 8188-8200 (Chapter 9 ledger),
  5981 / 6664 / 7588 (earlier Witness prerequisites)
- `AethelgardPrototype/DESIGN_PILLARS.md` P3, P5, P8
- Research input: `production/qa/evidence/2026-11-storyline/research_draft.md`

## Acceptance Criteria

**Document-level — checked today by `production/qa/evidence/2026-11-storyline/check_storyline_axes.py`:**

1. The 27-row table's (authority, faction, deleted) set equals the 3×3×3 product; each id is
   `SL-{authority}-{faction}-{deleted}`; the invalid rows are exactly the rules table's combinations, and the
   Formulas' `invalid(A, F, D)` set equals them too; each rule's quoted contradiction appears on its cited PM line;
   each valid row's source line is its own `# STORYLINE <abbreviation>` heading and each invalid row's an
   `Invalid V` line; every `valid_count:` and `SOLE n, BOUND n, NONE_AUTH n` statement equals the table.
2. The seed map's flag set equals the checker's 26-flag list; each flag occurs outside a comment in
   `AethelgardPrototype/scripts` or `dialogue`; every source cell resolves; axis seeds have direction `+` or `−` and
   `overturnable` = `until:lock:<its axis>`; modifier rows have `no`; timing rows have direction `0` and `no`.
3. The secret table has exactly the three secret ids, each naming the rule and abbreviation it transforms per
   PM:8784 (WITNESS ↔ YHR, CROWNLESS ↔ NAL, FIRSTWAKE ↔ NCL) with that rule's combination; each route's
   `secret_prerequisites` equals the production master's "Required flag" list for it; the side-storyline table has
   arcs 01-12, each `pm_line` an "Axis effect:" line, in arc order; the composer record has the fields authority,
   faction, deleted, secret_route, axis_revised, final_reconsidered, companions_present, regions_completed,
   timing_flags and act1_pace, with each axis field allowing exactly UNSET plus its three values;
   `reachable_1_0` equals the valid rows plus the 1.0 secret rows.
4. The Formulas define `storyline_id(A, F, D, I)` with exactly those four inputs: no timing or companion input.

**Runtime — testable once Y2-PP-T17 provides `storyline_id`, the lock, crisis and gate scenes (and Y1-P1-T05 the
saves). Observables named here are the contract for those stories:**

5. For each of the 27 triples with I = false, `storyline_id` returns `SL-A-F-D` for the 24 valid triples and CRISIS
   for the 3 invalid ones; with any one axis UNSET (each of the three, and all three) it returns PENDING.
6. For each of the 24 valid triples with I = true, `storyline_id` returns `SL-A-F-D`.
7. For (YOU, HEARTH, RESTORE) with `secret_route_enabled.WITNESS` true: with I = true and all four of
   `WITNESS_PROTOCOL_FOUND`, `OLD_WITNESS_SIGNATURE`, `WITNESS_SEATS`, `SEVEN_WITNESSES_AVAILABLE` set it returns
   `SL-SECRET-WITNESS` and `family` returns CONSENT; with I = true and each of the four single-flag-missing subsets
   it returns CRISIS; with all four set and I = false it returns CRISIS and `crisis_offers_invocation()` is true.
8. For (NONE, ARCHIVE, RELEASE) and (NONE, CONTINUITY, RELEASE) with both routes disabled, I = true and all five of
   each route's prerequisite flags set, `storyline_id` returns CRISIS; `prereqs_met` of a route with an empty list
   returns false.
9. Crisis: for each invalid triple, `gate_open()` is false and `storyline_id()` is CRISIS. For each of the 18
   renegotiations (3 triples × 3 axes × 2 other values), after `revise(axis, v)`: `axis_revised_<axis>` is set,
   `secret_invoked` is false, and `storyline_id()` / `gate_open()` equal the formula's result — a storyline ID and
   true for 16, CRISIS and false for the 2 Faction changes between R2 and R3. `revise(axis, current value)` is
   refused.
10. Valid rows are held: in the Validated state `revise_offered(axis)` is false for all three axes.
11. Seeds never lock: each of the 26 seed flags alone, and one flag from each exclusive group FlagRegistry defines
    (Y1-P1-T03) set together, with no lock scene played, leave all three axes UNSET and `storyline_id()` PENDING.
12. Options and arguments: for each axis, `lock_options(axis)` is all three values both with no seed set and with
    every axis seed of that axis set; for each axis seed row, the flag's name is in `lock_arguments(axis)` exactly
    when the flag is set, marked for (`+`) or against (`−`) its value.
13. Saves: a save made after the gate reloads with the same stored ID, family and composer record; a save with no
    axis data (every save today) loads with all axes UNSET, `storyline_id()` PENDING and no error; a save made
    mid-crisis reloads with CRISIS and `gate_open()` false.
14. Reconsideration: with `reconsideration_triggers` empty the final authorization offers none; with a test
    trigger holding it offers exactly `reconsider_targets(id)` for a valid stored ID and none for
    `SL-SECRET-WITNESS`; after one reconsideration `final_reconsidered` is true, the stored ID equals the chosen
    target and no second offer appears; after execution is confirmed the stored ID never changes.
15. Companions and timing (composer, owner Y2-PP-T17): for one valid triple per family, each of the 16 subsets of
    the four companions present, crossed with the timing sets {`act1_pace_early`, `ch1_bridge_saved`} and
    {`act1_pace_late`, `ch1_bridge_fell`}, yields the same stored ID and family, and the composer's module list
    differs between the two timing sets.

**Validation note:** the route bot of ROADMAP §12.4 starts from Chapter 8 fixture saves (not full playthroughs)
once the locks exist (owner Y2-PP-T17): one run per 1.0 storyline (24 valid + `SL-SECRET-WITNESS` = 25) and one per
crisis triple ending in a renegotiation exit; a run passes when the stored ID equals the expected one (PM:11304).

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
    destruction while RELEASE ends involuntary preservation (PM:7118); `ch1_root_purge` is a non-consensual rewrite
    that could argue for YOU instead of Hearth. Revisit in a narrative pass.
11. **Chapter 9 with a broken coalition:** how Chapter 9 plays while a crisis lasts (scenes, ally reactions) is
    for Y2-PP-T17.
12. **Deferred to Y2-PP-T17:** each storyline's authored loss, the Story+ "rotating witness institution"
    (PM:11220), and the concrete `reconsideration_triggers`.
