# Storyline Axes

> **Status**: Draft
> **Author**: Claude (narrative-director research) with the project lead
> **Last Updated**: 2026-11-09
> **Last Verified**: 2026-11-08
> **Implements Pillar**: P3 (24 storylines + 3 secret from three story axes), P5 (side storylines feed the main
> story), P8 (Story+, a playable after-story per storyline) — DESIGN_PILLARS.md, ROADMAP §12.2

## Summary

Three story axes — who holds Root (Authority), which society Kaelen backs (Faction), and what happens to the
deleted (Deleted) — combine into 27 configurations; 24 are valid storylines, 3 are contradictions that only a
secret route can transform. Four ending families carry the depth; Faction and Deleted modify them. Every save
tracks one stable storyline ID, and the ending composer builds the ending from that ID plus companions, regions and
timing.

> **Quick reference** — Layer: `Foundation` · Priority: `Alpha`

## Overview

Aethelgard's main story does not branch into 27 separately written routes. From Act 2 on, Kaelen's choices move
three axes: **Authority** (Kaelen alone, shared and auditable, or abolished), **Faction** (Hearth Compact, Archive
Covenant or Continuity League) and **the Deleted** (restore them, release them, or let each person choose). The
three values a player holds at the final authorization, before Root of Heaven, name one of 24 valid storylines
(`SL-AUTHORITY-FACTION-DELETED`); three combinations break the coalition (PM:710-723) unless the player has met a
secret route's prerequisites, which turn that contradiction into Witness Protocol (in 1.0), Crownless or First Wake
(post-1.0). The Authority value picks one of four ending families (Sole, Bound, No Authority; Consent for Witness
Protocol), each with its own God King phase, final scene and Story+ arc; Faction and Deleted change a boss phase,
ally lines, epilogue slides and which Story+ cases unlock. Act 1 flags seed the axes, twelve side storylines push
them, and timing changes scenes and slides without ever changing the storyline ID — so authored cost stays
additive.

## Player Fantasy

The player holds a key that could rewrite the world, and the game keeps asking whether they have the right to turn
it (Story Bible §1: "Capability is not legitimacy"). The axes are how that question becomes theirs: not a morality
meter, but three answers they build up through what Kaelen does — who he lets hold Root, whose society he stands
with, and whether the deleted are brought back, let go, or asked.

- **Authorship, not a menu.** No axis is picked from a list. Values move through scenes, side storylines and Act 1
  choices the player may not have read as political, so the storyline at the end feels arrived at.
- **Costs are real.** Every valid storyline loses something; the three invalid combinations are where a coalition
  refuses to follow, and the game says so in Chapter 8 instead of failing silently at the ending screen (PM:7153).
- **Nobody is forced to agree.** Companions stay possible on every storyline (PM:11302); they argue, they do not
  vanish because the player picked a faction.
- **The world goes on without a perfect answer.** The ending family (who authorized the change) carries the weight;
  Faction and Deleted colour what that authority built; Story+ lets the player walk around in the result.
- **Hidden doors are earned, then signposted.** A secret route appears only after its first prerequisite is found,
  then is signposted like everything else (PM:697-707; ROADMAP §12.2 "nothing important is lost silently").

## Detailed Design

### Core Rules

1. **Three axes, one value each at the final authorization.** Authority ∈ {YOU, SHARED, NONE}; Faction ∈ {HEARTH,
   ARCHIVE, CONTINUITY}; Deleted ∈ {RESTORE, RELEASE, CHOOSE}; each also starts UNSET. At the final authorization
   each axis holds exactly one value (PM:7522-7524, "Axis validation").
2. **Leanings before the locks.** Act 1 seeds, side storylines, companion persuasion and faction support are
   leanings, not values: each leaning makes at least one argument or option available at its axis's lock scene
   ("Player influence can back one. Companion persuasion and side quests matter.", PM:6987-6988). No seed sets a
   value; only the lock scene does ("This sets Faction Axis if vote passes.", PM:6989). The sources define no axis
   score.
3. **Lock scenes.** Faction: C8-S13 First Assembly Vote → `AXIS2_HEARTH` / `_ARCHIVE` / `_CONTINUITY`
   (PM:6980-7027; a player without support can still negotiate, PM:6990). Authority: the Axis 1 lock →
   `AXIS1_YOU` / `_SHARED` / `_NONE` (PM:7042-7087). Deleted: the Deleted Axis hearing (PM:7100-7132). These `AXIS*`
   flags are not in the code yet (owner: Y2-PP-T17). Before the last of the three locks, a signposted warning names
   the coalition that would break if the lock completes an invalid combination.
4. **An invalid combination is a political crisis, not a fail state.** If the three locked values form an invalid
   row (R1-R3 below), the coalition breaks before the final authorization (C8-S16, PM:7138-7153), "presented as a
   political crisis rather than a menu error" (PM:723). The player revises one axis — replaying that axis's lock as
   a scene — at any point before Root of Heaven, or meets that secret route's prerequisites (PM:721-722). A revision
   that lands on another invalid row starts the crisis again. Root of Heaven cannot be entered during a crisis.
5. **Secret transformation.** A secret route's prerequisites come from Chapter 9 at the earliest (the Chapter 9
   consequence ledger sets `SEVEN_WITNESSES_AVAILABLE`, PM:8188-8200). If every prerequisite of the route that
   transforms the current invalid row is met before Root of Heaven and the route is enabled, that row becomes the
   secret storyline (Secret storylines below). Witness Protocol is in 1.0; Crownless and First Wake are reserved
   (post-1.0): until they ship, their rows can only be revised.
6. **Storyline ID.** Fixed at the final authorization, before Root of Heaven: `SL-{authority}-{faction}-{deleted}`
   for a valid row, or `SL-SECRET-{route}` (Formulas). Until then it is UNSET. Once fixed it is saved and never
   changes (PM:11301; PM:8735).
7. **Ending family** = the Authority value (YOU → SOLE, SHARED → BOUND, NONE → NONE_AUTH), or CONSENT for Witness
   Protocol (Story Bible §5). **Bound** is a standing institution: Kaelen gives up unilateral final commit to a
   seven-signature protocol with rotating seats and public audit (PM:7062-7070). **Consent** is a single act: seven
   affected witnesses authorize one transformation without permanent Root ownership, and Kaelen only executes
   (PM:705; PM:11211-11219). Faction and Deleted are modifiers: a boss phase, ally lines, epilogue slides, Story+
   cases.
8. **Companions are independent of the axes.** Every storyline can include every surviving companion
   (PM:7529-7533, PM:11302); a companion leaves through relationship flags (Edge Cases), never through an axis.
9. **Timing is a modifier.** Pace values and timing flags change scenes, NPC fates, market events and ending slides
   through the composer, not the storyline ID (ROADMAP §12.4; PM:7527).

### States and Transitions

| State | Entry Condition | Exit Condition | Behavior |
|-------|----------------|----------------|----------|
| Leaning | New Game | The first Chapter 8 lock scene | Seeds and side storylines make options and arguments available; every axis UNSET |
| Partly locked | One or two lock scenes done | All three locked | Locked axes hold a value; the warning precedes the third lock if it could complete an invalid row |
| Crisis (C8-S16) | All three locked; the combination is invalid; its secret route not enabled or not all prerequisites met | A revision makes the combination valid, or every prerequisite of the enabled secret route is met (Chapter 9 at the earliest) | The coalition is broken; political-crisis scenes; any locked axis can be revised by replaying its lock scene; Root of Heaven is closed |
| Validated | All three locked and valid, or a secret transformation applied | Final authorization | Each axis holds exactly one value |
| Storyline fixed | Final authorization, before Root of Heaven | Never, for this playthrough | Storyline ID saved; the composer reads it |

### The 27 combinations

Invalidity rules (each removes one combination; quoted from PRODUCTION_MASTER_2.1.md:710-723):

| rule | combination | contradiction | source |
|---|---|---|---|
| R1 | YOU + HEARTH + RESTORE | "Hearth will not endorse unilateral compulsory restoration." | PRODUCTION_MASTER_2.1.md:714 |
| R2 | NONE + ARCHIVE + RELEASE | "Archive will not support abolition of root while mass release destroys unresolved memory appeals." | PRODUCTION_MASTER_2.1.md:716 |
| R3 | NONE + CONTINUITY + RELEASE | "Continuity will not support simultaneous abolition of emergency root and irreversible mass release." | PRODUCTION_MASTER_2.1.md:718 |

27 combinations: 24 valid and 3 invalid; each invalid one can become one of the 3 secret storylines, so there are
24 + 3 = 27 storylines in all.

`valid_count: 24` (SOLE 8, BOUND 9, NONE_AUTH 7), as the source states (PM:711-712, PM:8728, PM:11295). For a valid
row `source` is its route heading in the production master's route matrix; for an invalid row, its validity line.

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

### Secret storylines

Added to the 27 combinations as storylines, not replacing a table row; each transforms one invalid row (PM:697-699,
PM:8784).

| id | route | family | scope | source |
|---|---|---|---|---|
| SL-SECRET-WITNESS | Witness Protocol (PM "SEVEN WITNESSES"; SEC-01 "Authorized by the Living"; transforms R1 / YHR) | CONSENT | 1.0 | PRODUCTION_MASTER_2.1.md:11211 |
| SL-SECRET-FIRSTWAKE | First Wake (SEC-03 "Hello From Outside"; transforms R3 / NCL) | — (reserved) | post-1.0 | PRODUCTION_MASTER_2.1.md:11266 |
| SL-SECRET-CROWNLESS | Crownless (SEC-02 "No Throne in Heaven"; transforms R2 / NAL) | — (reserved) | post-1.0 | PRODUCTION_MASTER_2.1.md:11238 |

### Act 1 seed map

Every flag below exists in `AethelgardPrototype/dialogue` or `scripts` (26 flags). `direction`: `+` leans toward
the value, `−` leans away from it (the other two values of that axis are unaffected); for a modifier, `+` raises and
`−` lowers it. `overturnable`: an axis seed holds until its axis's lock scene settles the value
(`until:lock:faction`, `until:lock:authority`, `until:lock:deleted`); a modifier is `no`. Rows marked (J) are
judgement calls with no explicit source statement of direction, approved by the user.

| flag | pushes | direction | overturnable | source |
|---|---|---|---|---|
| act1_report_local | faction:HEARTH | + | until:lock:faction | PRODUCTION_MASTER_2.1.md:2856 |
| act1_report_archive | faction:ARCHIVE | + | until:lock:faction | PRODUCTION_MASTER_2.1.md:2857 |
| act1_report_command | faction:CONTINUITY | + | until:lock:faction | PRODUCTION_MASTER_2.1.md:2858 |
| ch2_seraphina_truth | modifier:seraphina_relationship | + | no | STORY_BIBLE.md:206 (J) |
| ch2_seraphina_cautious | modifier:seraphina_relationship | + | no | STORY_BIBLE.md:206 (J) |
| ch2_seraphina_showoff | modifier:seraphina_relationship | − | no | STORY_BIBLE.md:206 (J) |
| ch2_seraphina_recruited | modifier:companions_present | + | no | PRODUCTION_MASTER_2.1.md:3123 |
| ch2_seraphina_stayed | modifier:companions_present | − | no | PRODUCTION_MASTER_2.1.md:3125 |
| ch2_seraphina_rejected | modifier:companions_present | − | no | PRODUCTION_MASTER_2.1.md:3127 |
| ch2_data_wraith_restored | deleted:RESTORE | + | until:lock:deleted | PRODUCTION_MASTER_2.1.md:3117 |
| ch2_data_wraith_destroyed | deleted:RELEASE | + | until:lock:deleted | PRODUCTION_MASTER_2.1.md:3119 (J) |
| ch2_data_wraith_absorbed | deleted:CHOOSE | + | until:lock:deleted | PRODUCTION_MASTER_2.1.md:2468 (J) |
| ch1_knight_killed | faction:HEARTH | − | until:lock:faction | PRODUCTION_MASTER_2.1.md:663 (J) |
| ch1_knight_spared | modifier:aldric_restrained | + | no | PRODUCTION_MASTER_2.1.md:1806 |
| ch1_root_purge | faction:HEARTH | + | until:lock:faction | PRODUCTION_MASTER_2.1.md:663 |
| ch1_aldric_kill_owned | authority:YOU | + | until:lock:authority | PRODUCTION_MASTER_2.1.md:1801 |
| ch1_aldric_kill_justified | authority:YOU | + | until:lock:authority | STORY_BIBLE.md:196 (J) |
| ch1_aldric_kill_unsure | authority:SHARED | + | until:lock:authority | STORY_BIBLE.md:196 (J) |
| ch1_root_first_edit | authority:YOU | + | until:lock:authority | STORY_BIBLE.md:190 (J) |
| ch1_root_discovered_unused | authority:NONE | + | until:lock:authority | STORY_BIBLE.md:190 (J) |
| ch1_oakhaven_warned_villagers | modifier:A1-OAK-SAVED | + | no | PRODUCTION_MASTER_2.1.md:3105 |
| ch1_oakhaven_warned_leaders | modifier:A1-OAK-SAVED | + | no | PRODUCTION_MASTER_2.1.md:3105 (J) |
| ch1_oakhaven_left_quietly | modifier:A1-OAK-QUIET | + | no | PRODUCTION_MASTER_2.1.md:3107 |
| act1_pace_early | timing | + | no | PRODUCTION_MASTER_2.1.md:2869 |
| act1_pace_on_time | timing | + | no | PRODUCTION_MASTER_2.1.md:2870 |
| act1_pace_late | timing | + | no | PRODUCTION_MASTER_2.1.md:2871 |

### Side storylines

`axis:*` means the arc's own choices push that axis toward a value either way; no arc sets a value (Core Rule 2).
Arc 13 onward are not among the 12 (PM:5837).

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
| authority | enum | YOU, SHARED, NONE | owner story Y2-PP-T17 (route architecture data model); lock scene PM:7042-7087 |
| faction | enum | HEARTH, ARCHIVE, CONTINUITY | owner story Y2-PP-T17; lock scene C8-S13 (PM:6980-7027) |
| deleted | enum | RESTORE, RELEASE, CHOOSE | owner story Y2-PP-T17; Deleted hearing PM:7100-7132 |
| secret_route | enum | NO_SECRET, WITNESS, FIRSTWAKE, CROWNLESS | owner story Y2-PP-T17 (FIRSTWAKE and CROWNLESS reserved) |
| companions_present | set | Elara, Seraphina, Lyra, Kaelthas | `AethelgardPrototype/scripts/game_manager.gd` (`has_elara`, exclusive flag groups); `AethelgardPrototype/dialogue/ch2/fragment_two.dlg` |
| regions_completed | set | ids of the eight regions | owner story Y2-PP-T17 (no writer in the code today) |
| timing_flags | set of flags | `ch1_bridge_saved` / `_evacuated` / `_fell`, `ch2_medicine_early` / `_on_time` / `_late` | `AethelgardPrototype/dialogue/ch1/north_field.dlg`; `AethelgardPrototype/dialogue/ch2/act1_end.dlg` |
| act1_pace | enum | act1_pace_early, act1_pace_on_time, act1_pace_late | `AethelgardPrototype/dialogue/ch2/act1_end.dlg` |
| act2_pace, act3_pace, act4_pace | enum | names left to S06b | owner story Y1-P0-S06b |

### Interactions with Other Systems

- **FlagRegistry / StoryGraph (Y1-P1-T03):** owns the seed flags and, later, the `AXIS*` lock flags; validates
  exclusive groups; this GDD names them, it does not write them.
- **SaveService (Y1-P1-T05):** stores the storyline ID, the family and the composer input record; the ID never
  changes once fixed.
- **Time model (S06b):** supplies pace values per act and the timing flags the composer reads.
- **Ending composer / route data model (owner Y2-PP-T17):** implements `storyline_id` (Formulas), the lock scenes,
  the crisis scenes, the secret prerequisites and the modules; authored cost additive.
- **Companion system:** reads relationship flags for presence; never reads an axis to remove a companion.
- **Side storylines (arcs 01-12):** push leanings into axes or modifiers per the table above.

## Formulas

The storyline system defines no balance numbers: the sources define no axis score, and values come only from the
lock scenes (PM:6987-6989, PM:7522-7524). Its formulas are exact rules that saves, tests and the composer compute.

### Storyline ID

```
storyline_id(A, F, D, S):
    if A, F or D is UNSET                        → UNSET
    if not invalid(A, F, D)                      → "SL-" + A + "-" + F + "-" + D      (S is ignored)
    T = transform(A, F, D)                       # R1 → WITNESS, R2 → CROWNLESS, R3 → FIRSTWAKE
    if S = T and enabled(T) and prereqs_met(T)   → "SL-SECRET-" + T
    otherwise                                    → UNSET                              (crisis, Core Rule 4)
```

| Variable | Type | Range | Source | Description |
|---|---|---|---|---|
| A | enum | YOU, SHARED, NONE, UNSET | Axis 1 lock | Authority |
| F | enum | HEARTH, ARCHIVE, CONTINUITY, UNSET | C8-S13 vote | Faction |
| D | enum | RESTORE, RELEASE, CHOOSE, UNSET | Deleted hearing | The deleted |
| S | enum | NO_SECRET, WITNESS, FIRSTWAKE, CROWNLESS | owner Y2-PP-T17 | The secret route the player pursues |
| enabled(T) | bool | `secret_route_enabled.T` (Tuning Knobs) | data | Whether route T ships |
| prereqs_met(T) | bool | every flag in `secret_prerequisites[T]` set | data | e.g. WITNESS: PM:11215-11218 |

Examples:
- (SHARED, ARCHIVE, CHOOSE, NO_SECRET) → `SL-SHARED-ARCHIVE-CHOOSE`.
- (SHARED, ARCHIVE, CHOOSE, WITNESS) → `SL-SHARED-ARCHIVE-CHOOSE` (a secret never applies to a valid row).
- (YOU, HEARTH, RESTORE, NO_SECRET) → UNSET: crisis.
- (YOU, HEARTH, RESTORE, WITNESS), enabled, all four Witness flags set → `SL-SECRET-WITNESS`.
- (YOU, HEARTH, RESTORE, WITNESS), three of four flags set → UNSET: crisis continues.
- (NONE, CONTINUITY, RELEASE, FIRSTWAKE), FIRSTWAKE disabled → UNSET: the row can only be revised.
- (UNSET, HEARTH, CHOOSE, NO_SECRET) → UNSET.

### Validity

```
invalid(A, F, D) = (A, F, D) ∈ { (YOU, HEARTH, RESTORE), (NONE, ARCHIVE, RELEASE), (NONE, CONTINUITY, RELEASE) }
```

The set is the three rules R1-R3; it is defined only for three set values.

### Ending family

```
family(id):
    UNSET                                 → UNSET
    SL-SECRET-WITNESS                     → CONSENT
    SL-SECRET-CROWNLESS, SL-SECRET-FIRSTWAKE → RESERVED   (no family until those routes are designed)
    SL-A-F-D                              → { YOU → SOLE, SHARED → BOUND, NONE → NONE_AUTH }[A]
```

Example: `SL-NONE-HEARTH-CHOOSE` → NONE_AUTH.

### Counts

combinations = |A| × |F| × |D| = 3 × 3 × 3 = 27 (set values only); valid_count = 27 − |invalid set| = 24; secret
storylines = 3 (one per invalid row); storylines in all = 24 + 3 = 27 (ROADMAP §12.2; PM:11295-11297). Per family:
SOLE = 9 − 1 (R1) = 8; BOUND = 9; NONE_AUTH = 9 − 2 (R2, R3) = 7.

## Edge Cases

1. **A companion leaves (the plan's edge case).** A companion is absent through relationship flags, never an axis:
   Elara when `has_elara()` is false (`ch1_elara_trusted` and `_cautious` both unset), Seraphina on
   `ch2_seraphina_stayed` / `_rejected`, Lyra on `ch3_lyra_left_alone`, Kaelthas on `ch3_kaelthas_refused` /
   `_challenged` or his betrayal (PM:788). The storyline is unchanged: no ending family needs a companion
   (Story Bible §5), so every valid storyline stays reachable with any companion — or none — present; the composer
   omits that companion's modules.
2. **An invalid combination with a secret route half-met.** The crisis continues (Core Rule 4): `storyline_id`
   returns UNSET until every prerequisite of the transforming route is met ("Secret routes require multiple secret
   quests", PM:706), which is Chapter 9 at the earliest (PM:8188-8200). The player can still revise one axis instead
   at any point before Root of Heaven.
3. **R2 or R3 before Crownless / First Wake ship.** Those secret routes are reserved (post-1.0): their invalid rows
   can only be revised. Any flags their side arcs set (05, 08, 09) are kept but never transform a row, and no hint
   for an unshipped route is shown.
4. **No support for the faction the player wants.** The C8-S13 vote can still pass through negotiation (PM:6990);
   no faction becomes unavailable without warning (PM:6991).
5. **Contradictory seeds** (e.g. `act1_report_local` with `ch1_knight_killed`). Seeds are leanings, not values; the
   lock scenes decide. No error, no tie-break.
6. **Two flags of one exclusive group set** (e.g. two `act1_report_*`). A data error: FlagRegistry boot validation
   (Y1-P1-T03) reports it and refuses the save; this system defines no tie-break.
7. **Timing that goes badly** (`ch1_bridge_fell`, `act1_pace_late`). The storyline ID never changes; the composer
   picks different scene and slide modules (Core Rule 9).
8. **A save from before the final authorization** (every save today). Its storyline ID is UNSET; the ID is computed
   at the final authorization. Seeds already in the save are read as they are.
9. **NG+.** Whether axis leanings or the previous storyline carry into a new cycle is not decided here (Open
   Questions); until decided, NG+ starts in the Leaning state.
10. **Reaching Root of Heaven during a crisis.** Impossible: the final authorization is required to enter it
    (PM:722); the crisis scenes keep offering the revision.

## Dependencies

| System | Direction | What flows | Status of its design doc |
|---|---|---|---|
| Time model (`design/gdd/time-model.md`, Y1-P0-S06b) | this ← time model | per-act pace values (`act1_pace_*` exists; acts 2-4 named there), timing flags | not written yet — S06b must list this GDD as a dependent |
| FlagRegistry / StoryGraph (Y1-P1-T03) | this ← registry | seed flags, the future `AXIS*` lock flags, exclusive-group validation | no GDD (an ADR/tech design later) — must cite this GDD's seed map |
| SaveService (Y1-P1-T05) | this → save | storyline ID and the composer input record, saved and versioned | no GDD — must store the fields in the composer record |
| Ending composer / route data model (Y2-PP-T17) | this → composer | the composer input record | not designed — consumes this GDD as its input contract |
| Companion presence (relationship flags) | this ← companions | `companions_present` | no GDD — must never remove a companion by axis (Core Rule 8) |
| Side storylines (arcs 01-12, `story/source/PRODUCTION_MASTER_2.1.md`) | this ← arcs | seeds into axes, modifiers, secret routes | authored in the production master; S09 (arc 04) and Y1-P1-S04/S05 write into this table |
| Story Bible §5 (`AethelgardPrototype/story/STORY_BIBLE.md`) | both | axes, families, timing table | records the four-family decision (AC-6 line) |
| Difficulty profiles (Y1-P0-S06c) | none | — | deadline leniency belongs to the time model, not here |

Bidirectional rule: each doc above that is written later must name `design/gdd/storyline-axes.md` in its own
Dependencies section.

## Tuning Knobs

| Knob | Default | Safe range | What it affects | Rationale / source |
|---|---|---|---|---|
| `invalid_combinations` (data table) | R1-R3 (3 rows) | only combinations a source contradiction forbids; R1-R3 stay while their secret routes exist (removing a row orphans its route) | `valid_count` (27 − rows), the C8-S16 interceptions | PM:710-723; changing it also changes ROADMAP §12.2 / Story Bible counts |
| `secret_route_enabled.WITNESS` | true | true for 1.0 | whether R1 can transform into Witness Protocol | D2; Story Bible §5 (Consent family in 1.0) |
| `secret_route_enabled.CROWNLESS`, `.FIRSTWAKE` | false | false until their post-1.0 content ships | whether R2 / R3 can transform | D2; Story Bible §5 "post-1.0 candidates" |
| `secret_prerequisites[route]` (list of flags) | WITNESS: `WITNESS_PROTOCOL_FOUND`, `OLD_WITNESS_SIGNATURE`, `WITNESS_SEATS`, `SEVEN_WITNESSES_AVAILABLE` (PM:11215-11218); others defined with their routes | ≥ 2 flags per route ("multiple secret quests") | how hard a secret route is to reach | PM:706 |
| `faction_negotiation_allowed` | true | true (a false value would let a faction vanish without warning) | whether a player without support can still pass a C8-S13 vote | PM:6990-6991 |

Not knobs (fixed by design): the three axes and their values, the storyline ID format, the family mapping, and the
rule that timing never changes the storyline ID. No seed has a numeric weight; values come only from the lock
scenes (PM:6987-6989).

## Cross-References

- `AethelgardPrototype/story/STORY_BIBLE.md` §4 (cast, companion status), §5 (axes, ending families, timing,
  Act 1 flag tables)
- `AethelgardPrototype/ROADMAP_10_YEAR.md` §12.2 (storyline architecture), §12.4 (time-sensitive world)
- `AethelgardPrototype/story/source/PRODUCTION_MASTER_2.1.md`: axes 634-695, secret axis 697-707, validity 709-723,
  side arcs 1902-4459, Chapter 8 locks 6980-7153, axis validation 7522-7533, route matrix 8973-11117, secret routes
  11211-11267, route matrix validation 11293-11302
- Also cited: 6987-6991 (vote influence), 7062-7070 (shared protocol), 8188-8200 (Chapter 9 ledger),
  11215-11219 (Witness prerequisites)
- `AethelgardPrototype/DESIGN_PILLARS.md` P3, P5, P8
- Research input: `production/qa/evidence/2026-11-storyline/research_draft.md`

## Acceptance Criteria

**Document-level — checked today by `production/qa/evidence/2026-11-storyline/check_storyline_axes.py`:**

1. The 27-row table's (authority, faction, deleted) set equals the 3×3×3 product; each id is
   `SL-{authority}-{faction}-{deleted}`; exactly 3 rows are invalid and they are exactly the R1-R3 combinations of the
   rules table; `valid_count: 24`; the family split is SOLE 8, BOUND 9, NONE_AUTH 7.
2. The seed map covers exactly the 26 flags listed; each exists in `AethelgardPrototype/scripts` or `dialogue`;
   every axis seed's `overturnable` is `until:lock:<its axis>` and every modifier's is `no`.
3. The secret table has exactly the three secret ids; the side-storyline table has arcs 01-12 with real "Axis
   effect:" lines; the composer record has its required fields and the axis vocabularies.

**Runtime — testable once Y2-PP-T17 provides `storyline_id` and the lock scenes (and Y1-P1-T05 the saves):**

4. For each of the 27 triples with S = NO_SECRET, `storyline_id` returns `SL-A-F-D` for the 24 valid triples and
   UNSET for the 3 invalid ones.
5. For (YOU, HEARTH, RESTORE) with S = WITNESS, `secret_route_enabled.WITNESS` true and the four Witness flags
   (PM:11215-11218) all set, `storyline_id` returns `SL-SECRET-WITNESS` and `family` returns CONSENT; with any one of
   the four unset it returns UNSET (Edge Case 2).
6. For (NONE, ARCHIVE, RELEASE) with S = CROWNLESS and (NONE, CONTINUITY, RELEASE) with S = FIRSTWAKE, both routes
   disabled, `storyline_id` returns UNSET whatever flags are set (Edge Case 3).
7. For (SHARED, ARCHIVE, CHOOSE) with S = WITNESS, `storyline_id` returns `SL-SHARED-ARCHIVE-CHOOSE`.
8. Crisis: for each invalid triple with no transforming route met, the final-authorization flag stays unset and
   entering Root of Heaven is refused; after one axis is revised to a valid triple, the final authorization
   succeeds (Core Rule 4, Edge Case 10).
9. Timing: (SHARED, ARCHIVE, CHOOSE) saved with `act1_pace_early` and `ch1_bridge_saved`, and again with
   `act1_pace_late` and `ch1_bridge_fell`, yields the same storyline ID.
10. Companions: for the 24 valid triples, each with every single companion absent and with all four absent,
    `storyline_id` returns `SL-A-F-D`.
11. Seeds never lock: each of the 26 seed flags alone, and all 26 together, with no lock scene played, leaves all
    three axes UNSET.
12. Leaning contract: for each axis, at least one seed makes an option or argument available at that axis's lock
    scene that is absent without it (Core Rule 2).
13. Saves: a save made after the final authorization reloads with the same storyline ID, family and composer record.

**Validation note:** the route bot of ROADMAP §12.4 runs one playthrough per valid storyline ID and one per crisis
triple once the Chapter 8 locks exist (owner Y2-PP-T17).

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
6. **Companion count:** ROADMAP names 8 companions; the Story Bible has 4 with Companion status plus proposed and
   backlog characters. This GDD uses the 4.
7. **Systems index:** `design/gdd/systems-index.md` does not exist; `/map-systems` creates it later (D3).
8. **Story Bible §5** gives the Consent family the God King "loses its health bar" fight, which the production
   master gives to Crownless (PM:11247); a separate Story Bible fix.
9. **Truth strategy** (Seraphina's disclosure) is its own composer module in the production master (PM:8739); owner
   Y2-PP-T17.
