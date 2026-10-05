# Aethelgard — Design Pillars

The design contract. Every feature must serve a pillar. When this file and an older design doc
disagree, this file wins. The older docs are in `../design_archive/` for reference.

Last updated 2026-10-04. Plan and dates: [`ROADMAP_10_YEAR.md`](ROADMAP_10_YEAR.md).

## The game in one paragraph

A mature, Pokémon-spirited 2D RPG. You explore a **top-down open world**, and every fight switches
to **side-scrolling action combat** with the precision and style of *Hollow Knight: Silksong*.
Kaelen, a programmer, wakes inside Aethelgard, a broken, compiled world, with **Root Access**: the
power to edit the world's code, paid for in corruption. Choices, side stories, secrets and *timing*
reshape the main story into one of 20–30 storylines, each with its own playable after-story (Story+).

## Pillars

The measurable definitions are in roadmap §2.

| ID | Pillar | Never cut? |
|---|---|---|
| P1 | Dual perspective: top-down exploration ↔ side-scroll combat, seamless | ✔ |
| P2 | Stylish, tough combat driven by frame data (Silksong's feel, original moves) | ✔ |
| P3 | 24 storylines + 3 secret, built from three story axes | |
| P4 | Living NPCs: schedules, memory, reactions | |
| P5 | Dense side content: ~150 side quests, 30 secret quests, side storylines that feed the main story | |
| P6 | Five difficulty modes, Beginner → Hell (2-frame windows) | ✔ |
| P7a–f | Hero's Adventure systems: open world, market/auctions/limited editions, gambling and minigames, stat growth, deep crafting, time-sensitive world | P7f ✔ |
| P8 | Story+: a playable after-story per storyline | ✔ |
| P9 | Juice: every action has visual, audio and haptic feedback | |
| P10 | The thesis: who is allowed to authorize change (the Null Court) | ✔ |

## Confirmed decisions

| Decision | Choice | Date |
|---|---|---|
| Market | Single-player, simulated NPC traders and bidders. No online market. | 2026-10-04 |
| Gambling | In-game currency only. No real money and no paid random items. | 2026-10-04 |
| New Game route | Crash-site opening → Elara meeting → path to Oakhaven → village → region. The Flight 707 cinematic plays on NG+. | 2026-10-04 |
| Protagonist | **Kaelen** (not Ren or Kenji) | 2026-10-04 |
| Companions | Canon: **Elara, Seraphina, Lyra, Kaelthas**. **Kaito** and **Unit 734 "Seven"** are on the companion backlog for later chapters (8 companions budgeted). | 2026-10-04 |
| Defense | Real damage reduction: `damage × 100 / (100 + DEF)` (100 DEF = half damage). Implemented in `player_combat.take_damage`. | 2026-10-04 |
| MP | **Normal spells, skills and healing** (spell 15 MP, heal 20 MP). Regenerates ~2 MP/s plus potions and rest. Stored in `player_stats["mp"]`. Implemented. | 2026-10-04 |
| Soul | **Special arts: Glitch Arts and special skills.** Earned only through skillful play: parry +25, perfect dodge (a hit avoided during dash i-frames, once per dash) +15, kill +10. No longer gained per hit. Earning is implemented; spending waits on Glitch Arts. | 2026-10-04 |
| Art | All sprites come from the Pixel Art Engine through an importer (roadmap §6). The temporary art was removed on 2026-10-04. | 2026-10-04 |
| Story source | `story/source/PRODUCTION_MASTER_2.1.md` is the general story and flow. Its canon is in `story/STORY_BIBLE.md`, and its scenes are rewritten into `dialogue/` against `story/VOICE_GUIDE.md`. **This file and the implemented mechanics win** over its systems sections. Not adopted: stamina, equipment-load dodges, companion combat commands, renamed difficulty modes, top-down field combat, and healing items as the main heal. | 2026-10-05 |

## Canon (as built)

- **World:** Aethelgard. A patchwork of incompatible "compiled" realities.
- **Regions in the build:** Oakhaven, Ironhold, Fractured Wastes, Forgotten Sectors, Mirror City,
  Cathedral Server, Memory Ocean, Saved Assembly, Human Patch Lab, Root of Heaven. The full game
  targets 8 connected regions at launch; the blueprint's other kingdoms are expansion candidates.
- **Antagonists:** SOVEREIGN is the penultimate boss. **The God King is the true final boss, fought
  after SOVEREIGN** (decided 2026-10-04; not yet in the build, where the game currently ends at
  SOVEREIGN). A Tutorial Knight (Aldric), an Administrator Proxy and the Data Wraith are earlier
  bosses.
- **Seraphina:** a flight attendant on Flight 707, transported like Kaelen but to a different region.
  There she became a **paladin and the Knight-Commander** of the kingdom she arrived in (decided
  2026-10-04). Chapter 2 and Chapter 3 lines must agree with this.
- **Elara:** the Glitch-Witch guide. Her corrupted arm worsens every time she casts.
- **Lyra:** a former system admin met in the Fractured Wastes.
- **Kaelthas:** the Chapter 3 ally or betrayer.
- **Source Key:** 7 fragments, one per Human Patch authorization domain. All 7 are required to
  reach the Root of Heaven. The full canon is in `story/STORY_BIBLE.md`.

### Endings: framed by *who authorizes the change* (decided 2026-10-04)

Endings are no longer about what happens to SOVEREIGN (the Destroy / Rewrite / Dissolve /
Synthesize split, which mirrored Mass Effect 3). They are about **who is allowed to authorize** the
change to the world. That's the Null Court thesis (P10), and it maps onto story axis 1 (who holds
Root Access). The table below is a working mapping from today's routes; the names and content are
yours to write.

| Today's route | Reframed as: authorized by… | Working title |
|---|---|---|
| Destroy | Kaelen alone (unilateral root) | *Sole Authority* |
| Rewrite under limits | Kaelen bound by rules others can audit | *Bound Authority* |
| Dissolve | No one; root is abolished | *No Authority* |
| Synthesize | The people affected, including the deleted, by consent | *Consent* |

The God King fight and Story+ then play out differently depending on which authority you chose.

### Open canon questions

None right now. Add new ones here as the story deepens.

## Glitch Arts (Soul) — approved starting set (2026-10-04)

Approved as the first set; more and better arts can be added later. They'll be built with the
combat foundation (roadmap Months 5–6), where moves become data. Soul is earned by skillful play, so
these are the "earned" moves. Each uses the Root-Access theme and is distinct from MP spells, which
do damage and healing.

| Art | Effect | Soul | Notes |
|---|---|---|---|
| Noclip Step | Dash through enemies and projectiles (i-frames) | Low | Mobility; doesn't stack with dash i-frames |
| Freeze Frame | Stop one enemy for 1.5 s (bosses: 0.4 s) | Medium | Single target; telegraphed recovery |
| Clone Process | A decoy that draws aggro for 3 s | Medium | Useful against swarms |
| Overwrite | Turn the next enemy projectile into yours | High | Reward for timing |
| Source Peek | Show weak points and timing windows for 5 s | Low | Accessibility-friendly; useful on Hell |

Open points: how Glitch Arts are unlocked (story, training or the P7 Hero's-Adventure progression),
how many can be equipped, and whether using them adds corruption.
