# S06a research draft: storyline axes (input to `design/gdd/storyline-axes.md`)

Status: research draft for the user's review. It is not the GDD. Nothing here is decided until the user confirms it.
Story: `production/epics/y1-p0-stabilize/story-s06a-storyline-axes.md`. Date: 2026-11-08.

Citation keys:
- `PM` = `AethelgardPrototype/story/source/PRODUCTION_MASTER_2.1.md`
- `SB` = `AethelgardPrototype/story/STORY_BIBLE.md`
- `RM` = `AethelgardPrototype/ROADMAP_10_YEAR.md`

In the tables, `source` cells use the full file name so the checker can parse them.

Route-code key: PM names standard routes by three letters (Y/S/N, then H/A/C, then R/L/C). L means Release
(YHL "Deleted axis: Release Priority", PM:8982; NCL "No Root + Continuity + Release", PM:11268). C means Choose
(the NCC closing line, "Individual Choice", PM:11208).

---

## 1. Invalidity rules

The sources name exactly three invalid combinations, with the same three in four places: PM:710-723 (validity),
PM:7138-7153 (scene C8-S16), PM:8784 (secret mapping) and PM:11298 (route validation). Each rule removes one
combination.

| rule | combination | quoted contradiction | removes | also at |
|---|---|---|---|---|
| R1 | YOU + HEARTH + RESTORE | "Reason: Hearth will not endorse unilateral compulsory restoration." (PM:714) | 1 | PM:7140-7141 "Hearth delegates refuse compulsory restoration under unilateral Root." |
| R2 | NONE + ARCHIVE + RELEASE | "Reason: Archive will not support abolition of root while mass release destroys unresolved memory appeals." (PM:716) | 1 | PM:7146-7147 "Archive refuses mass release without Root capacity to resolve appeals." |
| R3 | NONE + CONTINUITY + RELEASE | "Reason: Continuity will not support simultaneous abolition of emergency root and irreversible mass release." (PM:718) | 1 | PM:7150-7151 |

The count:
- PM:711-712: "twenty-seven mathematical combinations ... Three combinations are narratively invalid without secret
  intervention."
- PM:8728: "Standard valid combinations = 24."
- PM:11295: "Standard route count: 24."
- PM:8973: "ROUTE MATRIX — 24 STANDARD STORYLINES". This matrix has 24 route headings, and none of them is YHR, NAL or NCL.

`valid_count: 24`. This matches RM:492. No rule was invented to reach it.

**Candidates checked and rejected (the sources do not forbid them):**
- **The other NONE + RELEASE pair (NHL).** It is a standard route, "Mortal Country" (PM:10652).
- **SHARED rows.** PM:8765 says "All nine mathematically possible unless production validity map removes later",
  and no later map removes any of them (PM:11298).
- **NONE + CONTINUITY + RESTORE (NCR).** Continuity "values ... safe restoration" (PM:674), but NCR is a standard
  route, "After the Emergency" (PM:11024).

Invalid rows are intercepted at C8-S16 and never fail at the ending screen. "No invalid route waits until ending screen
to fail." (PM:7153). The player revises one axis (PM:722) or meets a secret route's prerequisites (PM:721).

## 2. The 27-row table

Rows are sorted by authority, then faction, then deleted. For valid rows, `source` is the PM route heading. For invalid
rows, it is the PM validity line.

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

`valid_count: 24` (SOLE 8, BOUND 9, NONE_AUTH 7). CONSENT appears only on the secret Witness row (part 4). Families
follow the authority value (SB:153-157).

## 3. Companion analysis

**No axis combination makes any of the four companions impossible.** The sources say so directly:
- "Companion relationships remain independent. / Faction choice does not force companion ideology." (PM:7529-7530)
- "Every route can include all surviving companions without forcing ideological conversion." (PM:11302)
- "Companions may disagree and remain companions." (PM:491)

| companion | axis affinity | impossible under | evidence | what does remove them (not an axis) |
|---|---|---|---|---|
| Elara | Hearth (PM:769) | none | "Elara can remain companion on Continuity route." (PM:7532) | `has_elara()` = `ch1_elara_trusted` or `_cautious` (`scripts/game_manager.gd:746-748`) |
| Seraphina | Continuity reformist (PM:778) | none | "Seraphina can remain companion on Hearth route." (PM:7531) | `ch2_seraphina_stayed` / `_rejected` (`dialogue/ch2/fragment_two.dlg:79,84`); PM:4076 "If Seraphina absent." |
| Lyra | Archive critic (PM:786) | none | PM:7530; PM:671 places her "inside" Archive | `ch3_lyra_left_alone` (`scripts/game_manager.gd:717`) |
| Kaelthas | Archive radical (PM:794) | none | "Kaelthas can remain companion outside Archive if trust supports it." (PM:7533) | `ch3_kaelthas_refused` / `_challenged` (`scripts/game_manager.gd:715`); betrayal (PM:788) |

**Check: no valid row depends on an impossible companion.** Every row marks all four companions as possible, and no
family needs a specific companion (SB:153-158). The check passes, but only trivially.

The plan's edge case ("a combination that makes a companion impossible") is real, but the absence comes from
relationship flags, not from the axes. See Decision 4.

## 4. Secret rows

These three rows are added to the 27; they do not replace any of them. Each one transforms one invalid row (PM:8784).

| id | route | family | scope | source |
|---|---|---|---|---|
| SL-SECRET-WITNESS | Witness Protocol (PM "SEVEN WITNESSES"; SEC-01 "Authorized by the Living"; transforms R1 / YHR) | CONSENT | 1.0 | PRODUCTION_MASTER_2.1.md:11211 |
| SL-SECRET-FIRSTWAKE | First Wake (SEC-03 "Hello From Outside"; transforms R3 / NCL) | — (reserved) | post-1.0 | PRODUCTION_MASTER_2.1.md:11266 |
| SL-SECRET-CROWNLESS | Crownless (SEC-02 "No Throne in Heaven"; transforms R2 / NAL) | — (reserved) | post-1.0 | PRODUCTION_MASTER_2.1.md:11238 |

Each mapping is confirmed by PM:11212 ("Secret foundation: YHR"), PM:11239 (NAL) and PM:11267 (NCL). The CONSENT
family comes from SB:158.

## 5. Act 1 seed map

**Count mismatch.** Audit 4 says there are 22 flags, but the list it gives has **23**:
3 report + 3 disclosure + 3 status + 3 Wraith + 3 Aldric + 2 Root + 3 village + 3 pace = 23. All 23 are mapped below,
and every one exists in `dialogue/` (the paths are in the source column).

`until:ch8_choice_made` uses the only Act 3 lock flag that exists in code (`scripts/game_manager.gd:369`). The PM axis
locks (`AXIS2_*`, PM:6989-7027; `AXIS3_*`, PM:7110-7132) are not yet flags in the code.

Rows marked (J) are judgement calls with no explicit PM statement of direction (see Decision 5).

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

**Notes on specific rows:**
- **Report flags.** These are additive, not exclusive: "Kaelen may distribute to more than one through side quests"
  (PM:2859). The code agrees: none of the report flags is in `EXCLUSIVE_FLAG_GROUPS` (`game_manager.gd:710-719`).
  "This is not Axis 1 lock" (PM:2854).
- **Aldric.** "Aldric supports it [Hearth] if he survives with agency intact" (PM:663). Purge leaves him with memory
  gaps (PM:1827), and he "rejects becoming propaganda for Root Access" (PM:1828). Its Hearth effect is therefore left
  unassigned.
- **Overturnable `no`.** These follow the persistence rules "Aldric outcome must persist" and "Data Wraith outcome must
  persist" (PM:2947-2948).

Set sites:
- `dialogue/ch2/act1_end.dlg:15-43`
- `dialogue/ch2/command_hall.dlg:21-39`
- `dialogue/ch2/fragment_two.dlg:72-84`
- `dialogue/ch2/underground.dlg:68-88`
- `dialogue/ch1/aldric.dlg:60-116`
- `dialogue/ch1/broken_mile.dlg:93-115`
- `dialogue/ch1/fragment_one.dlg:37-52`

## 6. Side storylines

The PM gives the effect line for arcs 02, 03, 04, 07 and 10, but it does not name a value. Those cells use
`<axis>:*` (see Decision 6).

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

Arc headings are at PM:1902, 1951, 1979, 2612, 2658, 2693, 3617, 3661, 3685, 4371, 4421 and 4457.

## 7. Composer input record

**Status: PARTLY INCOMPLETE.** The writers for `regions_completed` and the Ch1/Ch2 timing flags were not verified in
code, and no script yet writes the three axes or the secret route.

| field | type | allowed | writer |
|---|---|---|---|
| authority | enum | YOU, SHARED, NONE | owner story TBD: Ch8 Axis 1 lock (PM:7029-7087); no script sets it today |
| faction | enum | HEARTH, ARCHIVE, CONTINUITY | owner story TBD: Ch8 faction vote (PM:6980-7027); seeds from `dialogue/ch2/act1_end.dlg` |
| deleted | enum | RESTORE, RELEASE, CHOOSE | owner story TBD: Ch8 Deleted lock (PM:7089-7153) |
| secret_route | enum or empty | WITNESS, FIRSTWAKE, CROWNLESS, none | owner story TBD (Witness Protocol); FIRSTWAKE/CROWNLESS reserved |
| companions_present | set | Elara, Seraphina, Lyra, Kaelthas | `scripts/game_manager.gd` (`has_elara`, `EXCLUSIVE_FLAG_GROUPS`); `dialogue/ch2/fragment_two.dlg` |
| regions_completed | set | INCOMPLETE: region ids not verified | INCOMPLETE: writer not located |
| timing_flags | set of flags | `ch1_bridge_*`, `ch2_medicine_*` (SB:169-170) | INCOMPLETE: SB:169 names `dialogue/ch1/north_field.dlg`; not re-verified |
| act1_pace | enum | act1_pace_early, act1_pace_on_time, act1_pace_late | `dialogue/ch2/act1_end.dlg:37-43` |
| act2_pace..act4_pace | enum | left to S06b | Y1-P0-S06b |

Rule: timing changes modules, never the storyline ID (RM:490, RM:493-494; PM:8735, PM:11301).

## 8. Decisions for the user

1. **Valid count.** `valid_count: 24`, using R1-R3 exactly as PM:713-718 states them. Confirm.
2. **Audit 4 says 22 flags, but its list has 23.** Should the story be corrected to 23?
3. **Secret families.** Witness Protocol is CONSENT (SB:158), even though its PM foundation is YHR, where "Kaelen
   retains technical execution" (PM:11213). FIRSTWAKE and CROWNLESS are left at `—`. Confirm both.
4. **Companion edge case.** By the sources, every row has all four companions, so the AC-7 companion check is trivially
   true. Options:
   - accept it, or
   - add a non-axis companion-state section, built from the flags in part 3.
5. **Seed directions marked (J).** Please confirm each:
   - Seraphina disclosure counts as a relationship modifier;
   - Wraith restored/destroyed counts as `deleted:RESTORE` ±;
   - Wraith absorbed counts as corruption;
   - `ch1_knight_killed` counts as `faction:HEARTH −`;
   - `_warned_leaders` falls under A1-OAK-SAVED (the PM has only SAVED and QUIET modules).
6. **Unvalued arc effects.** Arcs 02, 03, 04, 07 and 10 are written as `<axis>:*`. Is a wildcard allowed in the AC-4
   vocabulary? Is arc 03's "consent" best read as `secret:WITNESS`, or as `deleted:CHOOSE`?
7. **`until:ch8_choice_made`.** This stands in for the PM axis locks until real `AXIS*` flags exist. Confirm.

**Source contradictions found (logged here, not fixed):**
- **Fourth axis.** RM:489 says secret quests "add hidden 4th axis values". PM:698-699 says they "do not add a normal
  fourth multiplication layer" and instead "replace three impossible ... combinations".
- **YHR title.** PM:8743 gives a title to Y-H-R01 ("The Hand on the Root"), even though YHR is invalid (PM:713,
  PM:8752).
- **Late pace.** `dialogue/ch2/act1_end.dlg:34,43` sets late pace for the caravan route. PM:2871 sets it for "many rests
  missed convoy or ignored warnings".
- **Village flags.** `EXCLUSIVE_FLAG_GROUPS` (`game_manager.gd:718`) leaves out `ch1_oakhaven_warned_leaders`.
  `ch8_saved_assembly.gd:326-331` and `ch2_chapter_end.gd:224-226` never read it.
