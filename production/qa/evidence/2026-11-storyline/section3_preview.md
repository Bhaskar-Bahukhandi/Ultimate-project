### Core Rules

1. **Three axes, one value each.** Authority ∈ {YOU, SHARED, NONE}; Faction ∈ {HEARTH, ARCHIVE, CONTINUITY};
   Deleted ∈ {RESTORE, RELEASE, CHOOSE}. After the Chapter 8 locks each axis holds exactly one value
   (PM:7522-7525, C8-S17 "Axis validation").
2. **Before the locks, values are leanings, not scores.** Act 1 seeds, side storylines, companion persuasion and
   faction support make arguments and options available; there is no moral score (PM:3615). A value is set only by
   its lock scene.
3. **Lock scenes.** Faction: C8-S13 First Assembly Vote → `AXIS2_HEARTH` / `_ARCHIVE` / `_CONTINUITY`
   (PM:6980-7027; "options are proposals not Kaelen menu labels"; a player without support can still negotiate).
   Authority: the Axis 1 lock → `AXIS1_YOU` / `_SHARED` / `_NONE` (PM:7042-7087). Deleted: the Deleted Axis hearing
   (PM:7100-7132). These `AXIS*` flags are not in the code yet (owner: Y2-PP-T17).
4. **Invalid combinations are intercepted, never silently failed.** If the three locked values form an invalid row
   (rules R1-R3 below), the coalition refuses at C8-S16 and the player must change one axis before the final lock,
   or meet that secret route's prerequisites (PM:7138-7153: "No invalid route waits until ending screen to fail").
5. **Secret transformation.** With a secret route's prerequisites met, its invalid row becomes the secret storyline
   instead (Secret storylines below). Witness Protocol is in 1.0; Crownless and First Wake are reserved (post-1.0):
   until they ship, their rows can only be revised.
6. **Storyline ID.** Fixed once at the final lock: `SL-{authority}-{faction}-{deleted}` for a valid row, or
   `SL-SECRET-{route}`. Saved, stable, never changed by timing (PM:11301 "Every route must save a stable storyline
   ID"; PM:8735).
7. **Ending family** = the Authority value (YOU → SOLE, SHARED → BOUND, NONE → NONE_AUTH), or CONSENT for Witness
   Protocol (Story Bible §5). Faction and Deleted are modifiers: a boss phase, ally lines, epilogue slides, Story+
   cases.
8. **Companions are independent of the axes.** Every storyline can include every surviving companion
   (PM:7529-7533, PM:11302); a companion leaves through relationship flags (Edge Cases), never through an axis.
9. **Timing is a modifier.** Pace values and timing flags change scenes, NPC fates, market events and ending slides
   through the composer, not the storyline ID (ROADMAP §12.4; PM:7527).

### States and Transitions

| State | Entry Condition | Exit Condition | Behavior |
|-------|----------------|----------------|----------|
| Leaning | New Game (Acts 1-3, Chapter 8 before the locks) | The Chapter 8 lock scenes begin | Seeds and side storylines shape options and support; no axis value set |
| Partly locked | One or two of the three lock scenes done | All three locked | Locked axes fixed; the rest still lean |
| Intercepted (C8-S16) | All three locked, the combination invalid, no secret prerequisites met | The player revises one axis, or meets the secret's prerequisites | The coalition refuses; crisis scene; the final lock is withheld |
| Validated (C8-S17) | All three locked and valid, or a secret transformation applied | Final lock | Each axis has exactly one value |
| Storyline fixed | Final lock | Never, for this playthrough | Storyline ID saved; the composer reads it |

### The 27 combinations

Invalidity rules (each removes one combination; quoted from PRODUCTION_MASTER_2.1.md:710-723):

| rule | combination | contradiction | source |
|---|---|---|---|
| R1 | YOU + HEARTH + RESTORE | "Hearth will not endorse unilateral compulsory restoration." | PRODUCTION_MASTER_2.1.md:714 |
| R2 | NONE + ARCHIVE + RELEASE | "Archive will not support abolition of root while mass release destroys unresolved memory appeals." | PRODUCTION_MASTER_2.1.md:716 |
| R3 | NONE + CONTINUITY + RELEASE | "Continuity will not support simultaneous abolition of emergency root and irreversible mass release." | PRODUCTION_MASTER_2.1.md:718 |

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

Added to the 27, not replacing any row; each transforms one invalid row (PM:697-699, PM:8784).

| id | route | family | scope | source |
|---|---|---|---|---|
| SL-SECRET-WITNESS | Witness Protocol (PM "SEVEN WITNESSES"; SEC-01 "Authorized by the Living"; transforms R1 / YHR) | CONSENT | 1.0 | PRODUCTION_MASTER_2.1.md:11211 |
| SL-SECRET-FIRSTWAKE | First Wake (SEC-03 "Hello From Outside"; transforms R3 / NCL) | — (reserved) | post-1.0 | PRODUCTION_MASTER_2.1.md:11266 |
| SL-SECRET-CROWNLESS | Crownless (SEC-02 "No Throne in Heaven"; transforms R2 / NAL) | — (reserved) | post-1.0 | PRODUCTION_MASTER_2.1.md:11238 |

### Act 1 seed map

Every flag below exists in `AethelgardPrototype/dialogue` or `scripts` (23 flags). `until:ch8_choice_made`
stands in for the production master's `AXIS*` locks, which are not flags in the code yet
(`scripts/game_manager.gd:369`). Rows marked (J) are judgement calls with no explicit source statement of
direction.

| flag | pushes | direction | overturnable | source |
|---|---|---|---|---|
| act1_report_local | faction:HEARTH | + | until:ch8_choice_made | PRODUCTION_MASTER_2.1.md:2856 |
| act1_report_archive | faction:ARCHIVE | + | until:ch8_choice_made | PRODUCTION_MASTER_2.1.md:2857 |
| act1_report_command | faction:CONTINUITY | + | until:ch8_choice_made | PRODUCTION_MASTER_2.1.md:2858 |
| ch2_seraphina_truth | modifier:seraphina_relationship | + | no | STORY_BIBLE.md:203 (J) |
| ch2_seraphina_cautious | modifier:seraphina_relationship | + | no | STORY_BIBLE.md:203 (J) |
| ch2_seraphina_showoff | modifier:seraphina_relationship | − | no | STORY_BIBLE.md:203 (J) |
| ch2_seraphina_recruited | modifier:companions_present | + | no | PRODUCTION_MASTER_2.1.md:3123 |
| ch2_seraphina_stayed | modifier:companions_present | − | no | PRODUCTION_MASTER_2.1.md:3125 |
| ch2_seraphina_rejected | modifier:companions_present | − | no | PRODUCTION_MASTER_2.1.md:3127 |
| ch2_data_wraith_restored | deleted:RESTORE | + | until:ch8_choice_made | PRODUCTION_MASTER_2.1.md:3117 (J) |
| ch2_data_wraith_destroyed | deleted:RESTORE | − | until:ch8_choice_made | PRODUCTION_MASTER_2.1.md:3119 (J) |
| ch2_data_wraith_absorbed | modifier:corruption | + | no | PRODUCTION_MASTER_2.1.md:3121 (J) |
| ch1_knight_killed | faction:HEARTH | − | no | PRODUCTION_MASTER_2.1.md:663 (J) |
| ch1_knight_spared | faction:HEARTH | + | no | PRODUCTION_MASTER_2.1.md:663 |
| ch1_root_purge | modifier:corruption | + | no | PRODUCTION_MASTER_2.1.md:1820 |
| ch1_root_first_edit | modifier:corruption | + | no | STORY_BIBLE.md:187 |
| ch1_root_discovered_unused | modifier:corruption | − | no | STORY_BIBLE.md:187 |
| ch1_oakhaven_warned_villagers | modifier:A1-OAK-SAVED | + | no | PRODUCTION_MASTER_2.1.md:3105 |
| ch1_oakhaven_warned_leaders | modifier:A1-OAK-SAVED | + | no | PRODUCTION_MASTER_2.1.md:3105 (J) |
| ch1_oakhaven_left_quietly | modifier:A1-OAK-QUIET | + | no | PRODUCTION_MASTER_2.1.md:3107 |
| act1_pace_early | timing | + | no | PRODUCTION_MASTER_2.1.md:2869 |
| act1_pace_on_time | timing | + | no | PRODUCTION_MASTER_2.1.md:2870 |
| act1_pace_late | timing | + | no | PRODUCTION_MASTER_2.1.md:2871 |

### Side storylines

`axis:*` means the arc's own choices set that axis's value either way. Arc 13 onward are not among the 12
(PM:5837).

| arc | title | primary | secondary | scope | pm_line |
|---|---|---|---|---|---|
| 01 | The Baker of Oakhaven | faction:HEARTH | — | 1.0 | 1904 |
| 02 | Knight's Debt | authority:* | — | 1.0 | 1953 |
| 03 | Glitch-Witch's Price | authority:* | secret:WITNESS | 1.0 | 1981 |
| 04 | Iron Owes | faction:* | — | 1.0 | 2614 |
| 05 | The Flight List | secret:FIRSTWAKE | — | post-1.0 | 2660 |
| 06 | Three Auctions and a Funeral | faction:CONTINUITY | faction:HEARTH | 1.0 | 2695 |
| 07 | Things Lyra Forgot | deleted:* | faction:ARCHIVE | 1.0 | 3619 |
| 08 | Kaito's False Sky | secret:CROWNLESS | — | post-1.0 | 3663 |
| 09 | The Last Error | secret:FIRSTWAKE | — | post-1.0 | 3687 |
| 10 | The Names We Keep | deleted:* | — | 1.0 | 4373 |
| 11 | The Clerk Who Stayed | authority:SHARED | — | 1.0 | 4423 |
| 12 | A Person in Three Places | secret:WITNESS | — | 1.0 | 4459 |

### Composer input record

| field | type | allowed | writer |
|---|---|---|---|
| authority | enum | YOU, SHARED, NONE | owner story Y2-PP-T17 (route architecture data model); lock scene PM:7042-7087 |
| faction | enum | HEARTH, ARCHIVE, CONTINUITY | owner story Y2-PP-T17; lock scene C8-S13 (PM:6980-7027) |
| deleted | enum | RESTORE, RELEASE, CHOOSE | owner story Y2-PP-T17; Deleted hearing PM:7100-7132 |
| secret_route | enum or empty | WITNESS, FIRSTWAKE, CROWNLESS, empty | owner story Y2-PP-T17 (FIRSTWAKE and CROWNLESS reserved) |
| companions_present | set | Elara, Seraphina, Lyra, Kaelthas | `AethelgardPrototype/scripts/game_manager.gd` (`has_elara`, exclusive flag groups); `AethelgardPrototype/dialogue/ch2/fragment_two.dlg` |
| regions_completed | set | ids of the eight regions | owner story Y2-PP-T17 (no writer in the code today) |
| timing_flags | set of flags | `ch1_bridge_saved` / `_evacuated` / `_fell`, `ch2_medicine_early` / `_on_time` / `_late` | `AethelgardPrototype/dialogue/ch1/north_field.dlg`; `AethelgardPrototype/dialogue/ch2/act1_end.dlg` |
| act1_pace | enum | act1_pace_early, act1_pace_on_time, act1_pace_late | `AethelgardPrototype/dialogue/ch2/act1_end.dlg` |
| act2_pace, act3_pace, act4_pace | enum | names left to S06b | owner story Y1-P0-S06b |

### Interactions with Other Systems

- **FlagRegistry / StoryGraph (Y1-P1-T03):** owns the seed flags and, later, the `AXIS*` lock flags; this GDD names
  them, it does not write them.
- **SaveService (Y1-P1-T05):** stores the storyline ID and the composer input record; the ID never changes once
  fixed.
- **Time model (S06b):** supplies pace values per act and the timing flags the composer reads.
- **Ending composer (owner Y2-PP-T17):** reads the record and assembles modular sequences; authored cost additive.
- **Companion system:** reads relationship flags for presence; never reads an axis to remove a companion.
- **Side storylines (arcs 01-12):** write seeds into axes or modifiers per the table above.
