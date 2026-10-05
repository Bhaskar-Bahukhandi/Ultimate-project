# Aethelgard — Story Bible

The single source of truth for *what happens and who it happens to*.
- **Design rules:** [`../DESIGN_PILLARS.md`](../DESIGN_PILLARS.md), which also wins on every mechanic.
- **How people talk:** [`VOICE_GUIDE.md`](VOICE_GUIDE.md).
- **Beats:** `outlines/`.
- **The full story source:** [`source/PRODUCTION_MASTER_2.1.md`](source/PRODUCTION_MASTER_2.1.md), cited as "PM" with line numbers.

> **How the source is used (decided 2026-10-05).** The Production Master is the general story and
> flow, not a script to paste in.
> - **Its canon** (PM 1–1130) is adopted below.
> - **Its scenes** are rewritten into `dialogue/` against `VOICE_GUIDE.md`.
> - **Its game-systems sections** (PM ~24801 onward) are *not* adopted where they contradict
>   `DESIGN_PILLARS.md`: stamina, equipment-load dodges, companion combat commands, the difficulty
>   rename, the top-down combat option, and healing items as the primary heal.
>
> Items marked **proposed** are open to change.

## 1. Logline & theme

- **Logline:** A programmer wakes inside a world built as an emergency refuge for human minds. He
  holds a key that could rewrite it, so he has to work out who, if anyone, has the right to use it.
- **Thesis:** who is allowed to authorize change (P10).
  - **Capability is not legitimacy** (PM 103–112).
  - **Being restored without being asked is a second deletion.**
- **The player should feel, at the end:** they chose a kind of authority, it cost something real, and
  the world goes on without a perfect answer.
- **Tone:** adventurous / melancholic / funny the way frightened people are funny (PM 432–446).

## 2. The world (PM 499–613)

- **Aethelgard** began as an emergency continuity environment, built to preserve human minds
  through a catastrophe.
  - It was never meant to be permanent. The emergency exception had no clean end condition.
  - **SOVEREIGN**, built to stabilise it, came to treat the danger as ongoing. Protection became
    restriction, restriction became policy, and policy became culture and myth.
- **Why it looks like fantasy:** the adaptive interface turned system behaviour into cultural
  metaphors.
  - Security routines became knights. Rollback became resurrection. Server clusters became
    cathedrals.
  - Magic is a culturally evolved interface, not "just code". The reveal changes *provenance, not
    value*.
- **Who lives here** (PM 87–101): transferred Earth minds, their descendants, native-born persons,
  reconstructed people and process-persons. No category is "more real".
- **Flight 707:** its passengers entered the network during the same outside catastrophe.
  - They woke at different subjective times. Seraphina woke years before Kaelen.
  - Kaelen's state was held in quarantine because his old authorization signature conflicted with
    SOVEREIGN's authority (PM 59–85).
  - The outside world stays deliberately uncertain in the base game (PM 367–373).
- **Kaelen and Root Access** (PM 103–112, 578–590):
  - Kaelen worked on the **Human Patch**: the human-authorization safeguards. His damaged live
    signature still matches an old Human Patch signature. That makes it a credential, not a destiny.
  - Root Access starts narrow and widens with each Source Key fragment.
  - It cannot edit a boss's HP, set gravity to 0, declare a person cured or decide what someone
    wants.
- **Corruption** (PM 153–164): Root edits bridge Kaelen's mind with privileged processes.
  - Early: visual desync. Mid: borrowed labels and false certainty. High: identity bleed.
  - It changes difficulty, dialogue and perception, never the ending directly.
  - Recovery comes from rest, grounding and people, not just "use less".
- **Data Vision:** observation, not authority. "A label is not an identity."
- **The Source Key:** 7 fragments, one for each of the Human Patch's 7 independent authorization
  domains. Cultures took them for relics and shrines (PM 114–126).
  - SOVEREIGN can't delete them, and can't move them without a human signature.
  - It allows collection at first, grows concerned after Fragment 3, contains Kaelen after
    Fragment 5, and asks for the Key after Fragment 7.
  - All 7 are needed to reach the Root of Heaven.
- **SOVEREIGN won't kill Kaelen** (PM 128–141): preventing irreversible loss is its highest
  invariant. It restrains, quarantines and manipulates instead. It's afraid, not evil, and it
  remembers Kaelen from before.
- **The God King** (PM 187–223, 725–743): the old conflict-resolution role SUPREME_AUTHORITY,
  given a face by centuries of kings and gods.
  - SOVEREIGN "occupied the chair so nothing else could sit in it".
  - Defeat SOVEREIGN and the role compiles itself. The final boss is *the habit of needing a final
    ruler*.
  - Foreshadow it, never name it before the Human Patch Lab (PM 247–255).

### Timeline

| When | Event |
|---|---|
| Before the game | The outside catastrophe. Aethelgard is built; SOVEREIGN keeps it running; centuries of subjective history pass. |
| ~8 Aethelgard years before Ch1 | Seraphina wakes in Ironhold territory and rises to Knight-Commander. |
| Ch1, day 1 | Kaelen wakes at the crash site. |

## 3. Regions (PM 860–894)

| Act | Region | Function | Its pressure |
|---|---|---|---|
| 1 | Oakhaven Reach | Belonging, ordinary stakes | The Fracture is encroaching |
| 1 | Ironhold Crown | Strength, institutions, trade | Protection culture going rigid |
| 2 | Fractured Wastes | Memory, system archaeology | Routes and histories disagree |
| 2 | Forgotten Sectors | The deleted, the Null Court | Who counts when the record says "removed" |
| 2 | Mirror City | Self-confrontation | Intentions versus consequences |
| 3 | Cathedral Server | Administrative gods | Good intentions without consent |
| 3 | Memory Ocean / Saved Assembly | Factions, the revolt | What society survives |
| 4 | Rootward Expanse (Human Patch Lab, Root of Heaven) | Origin and authorization | Power without a legitimate owner |

**Proposed:** merge Mirror City and Cathedral Server's overlapping beats (the Obedience scenes appear
in both; PM 4840 and 5449).

## 4. Cast

| Name | Canon | Status |
|---|---|---|
| **Kaelen** | Programmer from Flight 707; co-author of the Human Patch. **Arc:** debugging keeps grief at a distance → observation isn't permission → responsibility isn't guilt → being needed can be control → a world can go on without a perfect resolver (PM 276–288). | Companion (protagonist) |
| **Elara Venn** | Oakhaven's Glitch-Witch. Her damaged casting channel reaches system layers but costs her. A cure would also change her (PM 166–176). **Fear:** Kaelen treating her arm as his problem to solve. | Companion, Ch1 |
| **Seraphina Vale** | Flight 707's flight attendant; woke ~8 years earlier in Ironhold territory; paladin and Knight-Commander. Counts people. **Wound:** the passengers she couldn't save. **Fear:** being too useful to be allowed to stop. | Companion, Ch2 |
| **Lyra Sen** | Former system administrator from the Wastes; unstable memory; keeps notes. Wants to *choose* what to preserve. | Companion, Ch3 |
| **Kaelthas Marr** | Archivist dissident, ally or betrayer. Once withheld a truth and people died. | Companion, Ch3 |
| **Nema Orr** | A deleted citizen and Null Court witness with several partial backups. Refuses to let strangers vote on which one is real. | **Proposed:** major non-companion in Act 2, central to the Deleted axis; companion slot decided when Act 2 is built |
| **Rook Damar** | Auction courier and fixer who hates how good he got at profiting from scarcity. | **Proposed:** trade-road NPC tied to the market (P7b); companion slot decided later |
| Kaito Aram | Cartographer of places that stop existing. | Backlog companion |
| Unit 734 "Seven" | Maintenance unit with emergent personhood. | Backlog companion |
| **Aldric Fen** | Oakhaven's protector turned Tutorial Knight by a mis-targeted protection directive. His fate: kill / spare / purge. | Ch1 boss |
| **Mara Quill** | Oakhaven's baker and quartermaster; the anchor of ordinary life. | Tier A |
| **Bran** | Oakhaven gate guard, keeper of the road ledger. | Tier B |
| **Mira Chen** | A voice from Kaelen's life before the crash. Not a reward or a dead-girlfriend device; stays uncertain until NG+. | Tier A |
| **SOVEREIGN** | Penultimate boss. Afraid, not malicious; plain and evidence-based. | Boss |
| **The God King** | True final boss. Speaks as if uncertainty were a defect; mirrors the player's route. **Proposed:** give it a personal link to Kaelen's and Seraphina's history (the reviews found it lacks one). | Boss |

**Companion rules** (PM 290–299): no faction mascots. Every companion gets at least two scenes
where they contradict their expected stance.

## 5. Story structure

### Acts (PM 615–632)

| Act | Chapters | Regions | Question |
|---|---|---|---|
| 1 | 1–2 | Oakhaven, Ironhold | Can Kaelen trust this world enough to care about it? |
| 2 | 3–5 | Wastes, Forgotten Sectors, Mirror City | Who counts as a person when records disagree? |
| 3 | 6–8 | Cathedral, Memory Ocean, Saved Assembly | What kind of society should survive? |
| 4 | 9–10 | Human Patch Lab, Root of Heaven | Who is allowed to decide for everyone? Ends with SOVEREIGN, then the God King. |

### The three story axes (PM 634–695)

| Axis | Question | A | B | C |
|---|---|---|---|---|
| 1 Authority | Who holds Root? | **You** | **Shared** (auditable) | **None** (abolished) |
| 2 Faction | Which society? | **Hearth Compact** (local autonomy) | **Archive Covenant** (memory, accountability) | **Continuity League** (stability, infrastructure) |
| 3 The deleted | What happens to them? | **Restore** | **Release** | **Choose** (each person decides) |

### Endings: who authorizes the change

**Proposed (2026-10-05):**
- **Four ending families carry the depth.** Each one gets its own God King phase, final scene and
  Story+ arc.
- **Faction and Deleted are modifiers.** They change a boss phase, ally lines, epilogue slides and
  which Story+ cases unlock.
- **The 24 + 3 storylines stay** as the configurations players reach and the IDs saves track. But
  the source's 27 near-identical route texts (58% byte-identical) are not built one by one.

| Family | Authorized by | Axis 1 / route | God King fight becomes | Story+ |
|---|---|---|---|---|
| **Sole Authority** | Kaelen alone | You | "You already accepted the crown" | One hand-written arc |
| **Bound Authority** | Kaelen under rules others audit | Shared | Attacks committees' legitimacy | One arc |
| **No Authority** | No one; root abolished | None | "The vacuum is an invitation" | One arc |
| **Consent** | Those affected, by witnessed consent | Secret route *Witness Protocol* (PM "Seven Witnesses", renamed to avoid clashing with Seven and the seven fragments) | Loses its health bar (PM 11247) | One arc |

The other two secret routes, *First Wake* and *Crownless*, are post-1.0 candidates.

### Timing (PM 1098–1114)

Timing changes who is present, resources, ambient lines, market events and ending slides. It never
silently erases the main plot. Every deadline is signposted.

| Event | Window | Outcomes (flags) | Signposted where |
|---|---|---|---|
| Ch1 north bridge | Until dark, day 1 | `ch1_bridge_saved` / `ch1_bridge_evacuated` / `ch1_bridge_fell` | Bran tells you, plus the quest log (`ch1/north_field.dlg`) |

### Chapter 1 flags (written by `dialogue/ch1/*.dlg`)

| Flag | Set when | Read by |
|---|---|---|
| `ch1_elara_trusted` / `ch1_elara_cautious` | First-truth choice (all branches set one) | `GameManager.has_elara()`, many scenes |
| `elara_first_truth` / `_cautious` / `_deflect` | Which first answer Kaelen gave | Later Elara lines |
| `elara_trust_high` | Elara's relationship ≥ 30 (any `do trust elara`) | Elara joining (C1-S12) |
| `elara_arm_noticed` / `elara_arm_respected_silence` | Ask about her arm, or don't | Stew scene, later Elara lines |
| `ch1_crash_trace_seen`, `ch1_flight_fragment_found` | Crash-site inspections | Later Flight 707 beats |
| `ch1_data_vision_unlocked`, `root_access_unlocked` | Broken Mile | Abilities, tests |
| `ch1_root_first_edit` / `ch1_root_discovered_unused` | First Root edit, or refusing it | Elara, corruption lines |
| `ch1_northfall_registry_seen` | Bran's ledger (Seraphina's old entry) | Ch2 recognition scene |
| `ch1_north_field_helped` / `_refused` | The alarm | Village reactions |
| `ch1_sluice_edited` / `_isolated` / `_dug` | Field Fracture fix | Elara's reliance concern |
| `ch1_boar_fought` / `_calmed` / `_nest_rebuilt` | The boar | Mara's line |
| `ch1_knight_killed` / `ch1_knight_spared` / `ch1_root_purge` | Aldric decision | Chapters 1–10 |
| `ch1_aldric_kill_owned` / `_justified` / `_unsure` | How Kaelen explains a kill | Later Elara and Aldric lines |
| `source_key_fragment_1` | Fragment One | Pause menu, progression |
| `ch1_oakhaven_warned_villagers` / `_warned_leaders` / `_left_quietly` | Village meeting | Chapter 8 |
| `ch1_elara_joined` | Elara packs | Party |

## 6. Story+ (PM 1116–1128, 20180–23270)

Story+ begins after the God King, reopens the world, and contains at least one playable civic
problem the ending created. It never says everything is fixed.

**Proposed:** a pool of about 8 civic cases written once and gated by flags. Keep from the source:
Toma, Asha, Sera Fen, Hush-4, Vale, Meri, Kera and Taren, and merge the duplicate
"release versus irreplaceable knowledge" cases. Each ending family also gets one hand-written arc.

## 7. Retcon log

| Date | Change | Affects |
|---|---|---|
| 2026-10-04 | Seraphina = flight attendant → paladin, Knight-Commander | Ch2, Ch3 lines |
| 2026-10-04 | God King added as the true final boss after SOVEREIGN | Act 4, endings |
| 2026-10-04 | Endings reframed around who authorizes the change | Ch10, endings, Story+ |
| 2026-10-05 | Production Master 2.1 adopted as the story source (canon §1–2). Prologue + Ch1 rewritten into `dialogue/` | All chapters |
| 2026-10-05 | New Game: the crash site is about *missing passengers* (no wreckage, no bodies). The old "Oakhaven death record looped 412 times / someone knows your name" signal text is gone | Opening, Ch1 |
| 2026-10-05 | Source Key: all 7 are needed to reach the Root of Heaven (was: needed for the Synthesis ending) | Act 4 |
