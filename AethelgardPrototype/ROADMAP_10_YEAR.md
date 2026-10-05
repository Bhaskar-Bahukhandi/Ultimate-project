# Aethelgard — 10-Year Production Roadmap (v2)

**Horizon:** Year 1 starts Oct 2026; Year 10 ends Sep 2036.

**Inputs:**
- your vision statement and follow-up answers (2026-10-04);
- `CODE_REVIEW_2026-10-04.md` (≈400 findings, root causes R1–R8, critical issues C1–C19);
- the Pixel Art Engine (PAE) export format.

**What changed in v2:**
- You're full-time (84 h/week available) with no capstone deadline.
- P7 is now defined: open world, a market with auctions and limited editions, gambling and minigames,
  stat changes, deep crafting, and quests whose timing affects the story.
- The early years compress, the scope grows, and the dates move.

---

## 0. How to read this plan

- **Detail fades with distance on purpose.** Year 1 is planned by month, Years 2–3 by quarter, and
  Years 4–10 by year. You re-plan at every **gate** using real measured data.
- **Every gate has pass criteria.** A failed gate forces a choice between re-scoping, extending and
  pivoting. It is not a failure of the project.
- **Every review finding is mapped to the phase that fixes it** (§11).
- **The order is non-negotiable: foundation → proof → production.** Writing content before the
  foundation exists is how the current 10 chapters became unreachable.

---

## 1. Assumptions

| # | Assumption | If wrong… |
|---|---|---|
| A1 | **Solo and full-time from day one.** You have 84 h/week available; the plan budgets **60 focused development hours/week** (§1.1). A small core team joins after **Gate 3** (late 2028). | If you stay solo forever, cut the content budget in §3 by about 60%. Even 84 h/week can't produce the art, music and roughly 400k words of this scope alone. |
| A2 | **Godot 4.x with GDScript**, with the version pinned and upgraded only at gates. | The blueprint's C# plan isn't needed: Root Access works through Godot's property reflection. |
| A3 | **Art comes from PAE** under your art direction. A contract animator may join after Gate 3 for the hero and bosses. | Gate 1 will show whether PAE reaches the quality bar. |
| A4 | **PC (Steam) first.** Consoles come after 1.0 through a Godot porting partner. | — |
| A5 | ✅ **Confirmed 2026-10-04: the market is single-player and simulated** (NPC traders and bidders, as in the blueprint's agent-based model). **No online player market.** | Reopen only at Gate 3. An online market adds servers, anti-cheat, live operations and legal work, which is roughly a second product (§12.6). |
| A6 | ✅ **Confirmed 2026-10-04: gambling uses in-game currency only.** No real money and no paid random items. | Not reopened. Real-money mechanics would change the legal and rating picture entirely. |
| A7 | **Self-funded until Gate 2**; publisher, grants or crowdfunding are decided at Gate 3. | — |
| A8 | **No external deadline.** The Year-1 Pillar Slice still doubles as a portfolio piece. | — |

### 1.1 About the 84 hours

Sustained 80+ hour weeks are what the games industry calls **crunch**. Over months they reliably lower
the quality of decisions, increase bugs, and cause burnout, and burnout is the most common way solo
projects die. This plan therefore budgets **60 focused development hours/week across 6 days**, and
treats the rest of your time as:
- learning (art, animation, music, game design reading);
- playing reference games critically;
- playtesting with notes;
- rest.

One rest day a week is in the plan on purpose. If you consistently deliver more than the plan
assumes, Gate 1 will show it in the measured cost per asset, and the plan accelerates from real data,
not from optimism.

---

## 2. Vision pillars (the contract every feature must serve)

| ID | Pillar | Measurable definition |
|---|---|---|
| P1 | **Dual perspective** | Top-down open world ↔ side-scroll combat. Transition under 1 s, no loading screen, world state preserved. Combat arenas generated from the terrain where the fight starts. |
| P2 | **Stylish, tough combat** (inspired by Silksong's feel, original moveset) | Every attack driven by frame data. Input-to-action latency ≤ 3 frames. Bosses hard on every difficulty. |
| P3 | **Consequential narrative: 20–30 storylines** | A *storyline* is a reachable combination of major outcomes that (a) changes ≥ 3 story scenes, (b) has its own ending sequence, (c) has its own Story+ state. Target: **24 + 3 secret = 27**. |
| P4 | **Living NPCs** (RDR2 spirit) | Schedules, memory, reactions and world events, in three tiers (§12.3). |
| P5 | **Dense side content** | About 150 side quests, 30 secret quests (10 change storylines), and **side storylines that feed the main story axes**. |
| P6 | **Five difficulty modes** | Beginner → Hell, each a data profile (§12.1). Hell needs 2-frame precision in boss fights. |
| P7a | **Open world & adventure** | One seamless, streamed 2D world. Discovery rewards, points of interest, dynamic events, free roaming from Act 1 onward (§12.5). |
| P7b | **Marketplace, auctions, limited editions** | Dynamic market prices; an auction house with NPC bidders on the world clock; player auctions with limited listings; limited-edition items released on the calendar (§12.6). |
| P7c | **Gambling & minigames** | 3 gambling games + 5 minigames at launch. Optional, never needed for the story, in-game currency only (§12.7). |
| P7d | **Stats & builds** | Stats change through levels, training and use, choices, and items. Respec available. Stats affect damage and resources, **never timing windows** (§12.8). |
| P7e | **Deep itemization** | About 450 items: rarities, affixes, crafting trees, upgrades, sets, limited editions (§12.9). |
| P7f | **Time-sensitive world** | A world clock and calendar. Quests have windows, deadlines and order effects. **When and how fast** you do things changes the main story (§12.4). |
| P8 | **Story+ (after-story)** | A playable epilogue after the final boss, with world state reflecting your storyline. |
| P9 | **Juice everywhere** | Every action gives visual, audio and haptic feedback; adaptive music; visibly reactive NPCs. |
| P10 | **Original thesis** | Keep the Null Court idea; endings organized around *who is allowed to authorize* change. |

**Cut order** if time runs short (cut from the top first):
1. Online anything (already excluded).
2. Minigames 5 → 3.
3. World size 8 → 6 regions.
4. Side quests 150 → 100.
5. Items 450 → 300.
6. Tier B NPCs 60 → 40.
7. Storylines 27 → 18.
8. Console ports.
9. Extra languages.

**Never cut:** P1, P2, P6, P7f, P8, P10.

---

## 3. Content budget (planning targets; re-baseline at Gate 3 from measured cost per asset)

| Content | Target | Notes |
|---|---|---|
| World | **8 connected regions** in one streamed open world | The blueprint's 15 kingdoms become 8 at launch; the rest are expansion candidates. |
| Playtime | Main 35–45 h · completionist 100+ h | Open world, market and minigames carry the completionist hours. |
| Acts | 4 + Story+ | Act 3 splits into 3 branches. |
| Storylines | 24 + 3 secret | 3 axes × 3 outcomes, plus timing modifiers (§12.2, §12.4). |
| Side storylines | 12 multi-quest arcs | Each one writes into a main-story axis or a timing modifier. |
| Side / secret / time-sensitive quests | 150 / 30 / 40 | The 40 time-sensitive quests overlap with the side and secret ones. |
| Bosses / enemy types | 24 / 50 | Every boss has a Hell-only phase. |
| NPCs | Tier A 10 · Tier B 70 · Tier C ~200 | Includes merchants, auctioneers and gambling hosts. |
| Companions | 8 | — |
| Items | ~450 | ~180 craftable, ~40 limited-edition, ~60 sets/uniques. |
| Market | ~120 tradable commodities, 1 auction house per major city (4) | — |
| Gambling / minigames | 3 / 5 | — |
| Player animations | ~40 clips + 4-direction top-down set | Equipment shown through the weapon sprite and palette/overlay layers, not a full paper-doll (§12.9). |
| Music / SFX | ~45 tracks (~3 h) / ~900 SFX | — |
| Dialogue | ~400k words | Needs data-driven dialogue, modular endings and a writer from Gate 3. |
| Languages at 1.0 | EN + Simplified Chinese | — |

---

## 4. Timeline at a glance

| Period | Calendar | Theme | Ends with |
|---|---|---|---|
| **Y1** | Oct 2026 – Sep 2027 | Stabilize, foundation, art pipeline, Pillar Slice; start open-world tech | **Gate 1 (Jun 2027)** |
| **Y2** | Oct 2027 – Sep 2028 | Public demo, tools, open-world streaming, economy and time systems at scale, pre-production | **Gate 2 (Mar 2028)** · **Gate 3 (Sep 2028)** |
| **Y3** | Oct 2028 – Sep 2029 | Production I: Act 1 (regions 1–2), team onboarding | M3 |
| **Y4** | Oct 2029 – Sep 2030 | Production II: Act 2 (regions 3–5) → **Early Access (~Mar 2030)** | **Gate 4: EA health** |
| **Y5** | Oct 2030 – Sep 2031 | Production III: Act 3 branches (regions 6–7), full market and auctions, all minigames | M5 |
| **Y6** | Oct 2031 – Sep 2032 | Production IV: region 8, Act 4, endings, Story+, secrets → **Alpha** | **Gate 6: Content complete** |
| **Y7** | Oct 2032 – Sep 2033 | Beta: balance (difficulty, economy, time paths), localization, accessibility, performance | **Gate 7: Release candidate** |
| **Y8** | Oct 2033 – Sep 2034 | **1.0 launch on PC (~Q1 2034)**, live support, console port production | Launch + 6-month review |
| **Y9** | Oct 2034 – Sep 2035 | Console launches; **Expansion 1** (cut kingdoms) | — |
| **Y10** | Oct 2035 – Sep 2036 | Expansion 2 / Story+ extensions / NG+ cycles; sequel decision | Retrospective |

Compared with v1, full-time work pulls 1.0 forward by about a year, even after absorbing the P7 scope.
Years 9–10 become post-launch growth instead of the launch itself.

---

## 5. Year 1 — Stabilize + Foundation (by month)

### Months 1–2 (Oct–Nov 2026): Stop the bleeding, lock the contract

**Engineering — Review Phase 0** (every critical issue C1–C19):
*Status 2026-10-04: all engineering items below are done and covered by `tests/phase0_blockers_test.gd`
(branch `fix/phase0-playthrough-blockers`). Still open for this phase: the human playthrough, the
design items, and production hygiene.*
- [x] **C1/C2/R5:** dialogue always closes (`say()` auto-hides when no line follows within 0.25 s).
- [x] **C13:** skipping fast-forwards text only and never answers a choice. 120 s auto-pick removed.
- [x] **C9/C10:** saves queue during transitions instead of being dropped; story checkpoints work in
  dialogue, cutscenes and combat; the UI reports the real result. The ending and NG+ persist.
- [x] **C11:** a corrupt save shows "Damaged save — Restore". Files are validated before they become
  the backup. Load falls back to the `.bak` on any failure.
- [x] **C12:** no saving in MENU/GAME_OVER. The pause screen finds the scene's CutsceneManager
  (the shop's dead lookup is left alone — enabling it would softlock callers awaiting `shop_closed`).
- [x] **C3:** New Game = opening hook → Elara → path → village → Oakhaven (chosen 2026-10-04).
  **C4:** Fractured Wastes "Server Room" gate resumes Chapter 3 → … → `ch3_ending` → Chapter 4.
- [x] **C5/C6:** Clock Tower floors one-way + ceiling raised; Underground doorways; both cameras follow
  the player. **C7:** admin-boss ESC skip only after defeat. **C8:** `ScreenTransition` is a plain Control.
- [x] **C14:** SOVEREIGN overrides capped at 3. **C15:** spider always drops from the ceiling.
  **C16:** arena walls + enemy kill zone. **C17:** gravity ≥ 0.2, speed ≥ 0, no boss HP hacking.
- [x] **C18:** `flip_h` type-guarded. **C19:** `tests/run_phase0_tests.ps1 -Script …` isolates user://;
  `phase10mm_validation` refuses to run without it.
- [x] Return points are scene-tagged; boss context is cleared on arrival, New Game and load.
- Found and fixed along the way: Data Stream `lerp()` crash that made the ride endless; Root Access
  tutorial charged +10% corruption per repeat click.

**Design**
- [x] `DESIGN_PILLARS.md` written. Old design docs moved to `design_archive/`. Canon: Kaelen; Elara,
  Seraphina, Lyra, Kaelthas (Kaito and Seven on the backlog). Open: Seraphina's identity, how the
  endings are framed.
- [x] **A5** (simulated, single-player market) and **A6** (in-game-currency gambling only):
  confirmed 2026-10-04.
- [ ] Draft the storyline axes (§12.2), the time model (§12.4) and the difficulty values (§12.1).

**Production hygiene**
- [x] `.gdignore` on `assets/art_sources/` (`docs/` stays importable for probes; excluded from
  exports instead). Export `exclude_filter` set. `export_presets.cfg` committed. `origin` remote fixed.
  Root logs and the 9.6 MB stderr log removed.
- [ ] **Your call:** move the repo off OneDrive; enable Git LFS (history rewrite + GitHub LFS quota);
  delete or relocate `Mysprites/`; retire the duplicate `context.txt`.
- [x] README rewritten; `CHANGELOG.md` started. (Collapsing the 97 phase reports into ADRs: later.)
- [ ] Turn **every review finding into a GitHub Issue** tagged with its phase (§11) — needs your OK
  to create issues on GitHub.
- [x] CI workflow: import, boot (fails on script errors), load-all, Phase 0 suite, `git diff --check`.
  Runs once the branch is pushed. Playthrough bot v0 covers New Game → Oakhaven and Ch3 → Ch4;
  extending it to the credits is still open.

**Exit:** a human can play New Game → credits with no softlock; the bot passes; you've written one
playthrough log.

### Months 3–4 (Dec 2026 – Jan 2027): The spine (fixes R1, R3, R4, R5)
- [x] **ContextStack** (2026-10-04): the only writer of `paused` and `Engine.time_scale`. UIStack is
  gone. Pause, shop, status, map, Root Access (both panels), journal, credits and tracker are contexts;
  owner-bound contexts close when their scene goes. Time scale is per-owner requests with priorities
  (hitstop > dramatic > slow-mo > wobble), cleared on scene change, New Game and retry. Input: no
  double-handling of one key press; the world map and journal are modal. `tests/context_stack_test.gd`
  (32 checks).
- [x] **InputService** (2026-10-04): the only code that changes the InputMap at runtime.
  - Defaults for keyboard and gamepad live in project.godot.
  - Per-action "modes" decide which buttons may be shared, and rebinding swaps keys inside those
    rules.
  - Rebinds are saved to `user://input.cfg` (only actions that differ from the defaults), and old
    keyboard rebinds are migrated.
  - Prompts are generated from the bindings and follow the last-used device and pad family:
    `fmt` / `bind_text`, plus `{action}` tokens in dialogue.
  - The Controls screen is reachable from the main menu and the pause menu.
  - The game pauses when the pad disconnects, and menus get a focus fallback for gamepads.
  - `tests/input_test.gd` (52 checks, including a guard against new hardcoded keys).
  - Still to do: input buffers (combat foundation), glyph icons instead of text labels, hold and
    toggle options, and one-handed and accessibility presets.
- [ ] **TransitionService:** `go(path, TravelContext)` consumed exactly once. Queue, re-entrancy
  guard, input lock.
- [ ] **SaveService:** versioned schema, per-system serializers, atomic write with validated rotating
  backups, migration tests. **Saves include the world clock, market state and auction state.**
- [ ] **StoryGraph + FlagRegistry + RewardLedger (`grant_once`)**, with boot validation that every
  read has a reachable writer.
- [x] **Dialogue as data** — done first (2026-10-04) so the story rewrite goes straight into data. An
  in-house `.dlg` format replaced the Nathan Hoad plugin: v4.x requires Godot 4.7, and its
  `DialogueManager` autoload name clashes with the game's (1,545 call sites). Includes nodes, choices,
  conditions, flags, `do` scene hooks, optional `[#id]` line IDs, a validator, an extractor and tests.
  Still to do: a speaker registry (portraits), an ID-stamping tool, and a localization string-table
  export.
- [x] **Story source and first rewrite** (2026-10-05).
  - Production Master 2.1 was adopted as the story source; its canon is in `story/STORY_BIBLE.md`.
  - Voice sheets plus an automatic voice lint.
  - The prologue and Chapter 1 are rewritten as 10 `.dlg` files, and the crash site plays them.
  - **Chapter 1 fully wired** (2026-10-05); `tests/chapter1_route_test.gd` checks it end to end.
  - **Chapter 2 fully wired** (2026-10-05), which completes Act 1; `tests/chapter2_route_test.gd`
    checks it.
    - Not built yet: side arcs 04–06 (Iron Owes, the Flight List, Three Auctions and a Funeral),
      market hoarding consequences, and the Wraith-absorbed whispers.
    - Combat isn't exercised by the test.
  - Still to do:
    - Make the boar, the guardian and the opening slime real side-scroll fights.
    - Build Elara's house and the shrine as rooms.
    - Move the bridge deadline onto the WorldClock (fixing it is instant today).
    - Then Chapter 2 onward, in the same voice.
- [ ] **Stats model:** `final = base + level + training + Σ modifiers`. Decided 2026-10-04: DEF is
  mitigation (`×100/(100+DEF)`, done); MP pays for spells and healing, regenerating ~2/s (done); Soul
  is earned from parries, perfect dodges and kills (done) and pays for Glitch Arts (proposal in
  DESIGN_PILLARS.md, awaiting review).
- [ ] **WorldClock v1** (§12.4): deterministic, saved, pausable, and owned by ContextStack's time
  rules.
- [ ] Adopt **gdUnit4** (or GUT); every service gets unit tests.

### Months 5–6 (Feb–Mar 2027): Combat foundation (fixes R2; P2, P6)
- [ ] Player **node state machine** on a fixed tick with no `await` timers.
- [ ] **MoveData / AttackSpec** `.tres` resources tied to animation frames.
- [ ] Hitbox/Hurtbox components on named physics layers.
- [ ] **EnemyDef / BossDef / PhaseDef** resources; BossController with poise.
- [ ] **CombatEncounter** with one idempotent `resolve()`.
- [ ] **DifficultyProfile × 5** (§12.1).
- [ ] Root Access from per-enemy capability definitions.
- [ ] **FeelService:** one shake system, pooled numbers and particles.
- [ ] **Input buffers** (jump, attack, parry, dash) on the fixed tick. Gamepad, the remap UI and
  generated prompts were done early (InputService, 2026-10-04).
- [ ] **Arena generation v1:** the side-scroll arena is built from the terrain context where the
  fight starts (forest, bridge, cave), using prefab chunks first and WFC later if it's needed.
- [ ] Replace the review §4.4–4.5 bugs as each system is rewritten.

### Months 7–9 (Apr–Jun 2027): Art pipeline + Pillar Slice
- [ ] **PAE importer** (review §6, items 1–10) and the **CharacterVisual** component.
- [ ] Pixel-perfect config: integer scaling, pixel snap, integer zoom, renderer decision.
- [ ] **Art bible v1.** PAE sprites: Kaelen (~40 clips), Elara, 4 NPCs (one a merchant), 2 enemies,
  1 boss, the Oakhaven tileset and ~40 item icons.
- [ ] **Oakhaven as an editor-authored, streamed chunk set:** TileMapLayers with collision,
  Interactables, `RegionBase`.
- [ ] **NPC sim v1:** schedules on the WorldClock, memory, barks (5 NPCs).
- [ ] **ItemDB v1** (one database, `.tres`), equipment, **crafting v1** (10 recipes).
- [ ] **Market v1:** one shop with dynamic prices and the anti-arbitrage rule. **Auction v1:** NPC
  bidders, 3 lots, timed on the WorldClock. **1 limited-edition item** on a calendar date.
- [ ] **1 minigame + 1 gambling game** (e.g. a dice game in the tavern).
- [ ] **2 time-sensitive quests:** one with a deadline, one where the order you do it in changes the
  outcome.
- [ ] **Ending composer v1 + Story+ v1** for the slice's outcomes.
- [ ] **Audio:** bus layout, file-based SFX, 4 adaptive tracks, ~70 SFX. UI Theme and font.

**🚦 Gate 1: Pillar Slice (end of June 2027).** Every pillar, P7a–f included, is proven once in one
town.

Pass criteria:
- 10+ external testers; 0 softlocks.
- At least 70% notice the town reacting to their choice **and** to the time they took.
- At least 70% of Hard/Hell testers rate deaths "fair".
- A headless economy test (100 in-game days) keeps gold supply within bounds.
- 60 fps on minimum spec.
- All C-items closed.
- **Cost per asset measured.**

If it fails: fix and re-run once (+2 months); if it fails again, re-scope §3.

### Months 10–12 (Jul–Sep 2027): Open-world tech + tools
- [ ] **World streaming:** chunk loading and unloading, a seamless boundary between 2 regions,
  simulation LOD for off-screen NPCs and the market.
- [ ] **Migrate Ironhold** as the second region (proves the pipeline repeats).
- [ ] **Tools:**
  - quest editor with timing fields;
  - NPC schedule editor;
  - item and recipe editor;
  - economy dashboard (price history, sources and sinks);
  - storyline coverage viewer;
  - difficulty tuning panel.
- [ ] Opt-in telemetry and crash reporting. Localization pipeline (string tables, CJK font coverage).
  Accessibility baseline.

---

## 6. Year 2 — Demo, systems at scale, pre-production

**Q1 (Oct–Dec 2027): public demo**
- Demo contents: prologue, Oakhaven, Ironhold, market and auction, 2 minigames, time-sensitive
  quests.
- Release on itch.io first, then **Steam Next Fest**.
- Steam page, trailer, Discord, devlog, structured playtest program.

**Q2 (Jan–Mar 2028): market signal**
- Iterate on the demo from data.
- Legal groundwork:
  - asset license audit;
  - **Steam AI-content disclosure** for PAE and AI-assisted assets (check current rules);
  - trademark search for the title;
  - **simulated-gambling rating impact** (§12.7).

**🚦 Gate 2 (Mar 2028).**
- Demo completion rate of at least 40%.
- Wishlist and follower targets, set by you from comparable indie RPGs.
- Testers can explain the hook in one sentence.
- Measured cost per asset supports §3 within ±30%.

If it fails, rework the hook for one quarter, or plan a smaller first commercial release.

**Q3–Q4 (Apr–Sep 2028): pre-production**
- **World bible:** 8 regions forming one map, factions, history, the companion roster, SOVEREIGN, and
  the Null Court thesis throughout.
- **Route architecture locked:** 3 axes, Act 3 branches, timing modifiers, the 12 side storylines and
  which axis each feeds. The ending composer table and Story+ structure. The **bot proves all
  27 storylines and every timing branch reachable before any content is written.**
- **Economy design locked:** commodities, sources and sinks, auction rules, the limited-edition
  calendar, gambling house edges. A headless 365-in-game-day simulation shows inflation within bounds.
- **Combat bible** and **itemization bible** (affix tables, crafting trees, sets).
- **Legacy cleanup:**
  - Chapters 1–3 rebuilt on the spine; the best Chapter 4–10 writing salvaged into dialogue data.
  - Delete the orphaned systems: `cutscene_director`, `cinematic_vfx`, TweenAnimator, the duplicate
    flash, shake and number systems, the 3 old item databases, and the stale probes.
- **Team and funding:**
  - Roles: art lead/animator, composer and sound, writer, QA, later an economy/systems designer.
  - Funding route chosen.
  - Company entity, contracts with IP assignment.

**🚦 Gate 3 (Sep 2028): Production greenlight.**
- Funding covers ≥ 24 months of the team plan.
- Routes and timing are bot-verified.
- Every pipeline has shipped one final-quality asset.

If it fails, ship a **smaller game**: 2–3 regions, about 6 storylines, market and minigames, as a
complete commercial product.

---

## 7. Years 3–6 — Production

| Year | Content | Systems deepened | Milestone |
|---|---|---|---|
| **Y3** (Oct 2028 – Sep 2029) | **Act 1**, regions 1–2: 6 bosses, 35 side quests, 6 secret quests, 10 time-sensitive quests, 3 side storylines, 25 Tier B NPCs, 3 companions, ~120 items, 1 auction house, 2 minigames + 1 gambling game | NPC sim v2 (factions, reputation, crime/witness, daily events); full moveset; training-based stat growth | **M3:** Act 1 shippable on all 5 difficulties |
| **Y4** (Oct 2029 – Sep 2030) | **Act 2**, regions 3–5: 9 bosses, 45 side quests, 10 secret quests, 12 time-sensitive quests, 4 side storylines, 25 Tier B NPCs, 3 companions, ~150 items, 2 auction houses, limited-edition calendar v1 | Companion synergies; market agents at scale; adaptive music at scale | **Early Access ~Mar 2030** (Acts 1–2). **🚦 Gate 4:** review and retention targets, crash-free ≥ 99.5%, saves migrate across every patch, no economy exploit open for more than 1 patch |
| **Y5** (Oct 2030 – Sep 2031) | **Act 3: 3 branches**, regions 6–7: 6 bosses, 40 side quests, 8 secret quests, 10 time-sensitive quests, 3 side storylines, 20 Tier B NPCs, 2 companions, ~120 items, 4th auction house, remaining minigames and gambling | NPC sim v3: towns change per route **and per elapsed time**; route-specific market events | **M5:** all branches playable end to end |
| **Y6** (Oct 2031 – Sep 2032) | Region 8 + **Act 4**; SOVEREIGN then **the God King** (true final boss), each with a Hell phase; **all 27 endings** (framed by who authorizes the change);  **Story+ for every storyline**; remaining secrets and 2 side storylines; ~60 items | Ending composer and Story+ world state complete; timing modifiers wired into every ending | **🚦 Gate 6: Alpha.** Content complete; bot reaches every storyline and timing branch; every quest completable |

**Production rules (Years 3–6):**
- **Vertical, not horizontal:** finish one region to shippable quality before starting the next.
- **Definition of Done:**
  - real art and audio;
  - all 5 difficulties tuned;
  - strings extracted;
  - bot coverage, including time-skip paths;
  - saves migrate;
  - the economy sim stays stable;
  - no open critical or high bugs.
- **Quarterly re-plan** against measured speed.

---

## 8. Year 7 — Beta

- **Difficulty:** every boss on every difficulty. Hell validated by input replay (a perfect run must
  win; one frame window off must lose). Fairness surveys. No essential item exclusive to Hell.
- **Economy:** a 1000-day headless simulation per route; exploit hunting (arbitrage, auction
  sniping, gambling expected value); telemetry from Early Access.
- **Time paths:** the bot plays fast, slow and out-of-order runs. Every deadline is signposted.
  Nothing story-critical is lost silently (rule from the review).
- **Coverage:** QA matrix of storyline × difficulty × timing profile; the bot runs nightly.
- **Performance:** 60 fps on min spec with streaming and NPC/market simulation. Steam Deck
  verification.
- **Localization:** EN + Simplified Chinese with linguistic QA. **Accessibility pass.**
- **Ratings and legal:** age ratings (simulated gambling raises them in most systems, and some
  countries restrict it, so check before Beta), credits, license and AI-disclosure audit. Launch
  marketing.

**🚦 Gate 7 (Sep 2033): Release candidate.** 0 critical bugs, high bugs under threshold, every
storyline completable, performance budgets met.

---

## 9. Years 8–10 — Launch and beyond

- **Y8:**
  - **1.0 launch on PC (~Q1 2034)**, with a launch war room, hotfix process and patch cadence.
  - Long-term save compatibility guaranteed in CI.
  - Console ports start with a licensed Godot porting partner (Godot can't publicly ship console
    export templates). Certification prep.
- **Y9:**
  - Console launches.
  - **Expansion 1:** 2 of the cut kingdoms, new storylines, new market goods and events.
  - Optional: Hell-mode leaderboards and speedrun support (the timer exists; make it real).
- **Y10:**
  - **Expansion 2** and Story+ extensions.
  - NG+ cycles with remixed bosses and markets.
  - Retrospective, then decide on a sequel, new IP or continued support.

---

## 10. Gate summary

| Gate | When | Must show |
|---|---|---|
| G1 Pillar Slice | Jun 2027 | All pillars proven once; 0 softlocks; fairness ≥ 70%; economy stable over 100 days; cost per asset measured |
| G2 Market signal | Mar 2028 | Demo completion ≥ 40%; wishlist targets; hook understood |
| G3 Greenlight | Sep 2028 | Funding ≥ 24 months; routes and timing bot-verified; every pipeline proven |
| G4 Early Access health | ~Sep 2030 | Review/retention targets; crash-free ≥ 99.5%; save migration 100%; exploit turnaround ≤ 1 patch |
| G6 Alpha | Sep 2032 | Content complete; every storyline and timing branch reachable by bot |
| G7 Release candidate | Sep 2033 | 0 critical bugs; performance; localization; accessibility |

---

## 11. Traceability — where every review finding gets fixed

| Review item | Fixed in | How it stays fixed |
|---|---|---|
| **C1–C19** (all critical) | Y1 Months 1–2 (Phase 0) | Spine re-implements them (Months 3–6). Bot plus a regression test per C-item. |
| **R1** no owner for pause/time/state/input | Months 3–4 ContextStack | Lint: no direct `paused =` or `time_scale =` outside the service. |
| **R2** fire-and-forget coroutines | Months 5–6 state machines, fixed tick | Lint: no `create_timer` in gameplay code; pause-safety tests. |
| **R3** string flags, meta hand-offs | Months 3–4 StoryGraph, FlagRegistry, TravelContext | Boot validation; reachability test. |
| **R4** silent save rejection | Months 3–4 SaveService | Round-trip, corruption and migration tests. |
| **R5** dialogue never closes; skip answers choices | Months 1–2 fix → Months 3–4 DialogueRunner | Test: after every scene, `is_active == false`. |
| **R6** world built from ColorRects | Months 7–12 authored and streamed chunks, PAE pipeline | Rule: no gameplay geometry built in code. |
| **R7** duplicated systems | Months 3–6 replacements; Y2-Q3/Q4 deletion pass | One owner per concern (ADRs). |
| **R8** no tests, CI or playtests | Months 1–2 CI and bot → forever | Gates require test and playtest evidence. |
| §4.1 save/state highs | Months 3–4 SaveService, RewardLedger, Stats model | Tests per item. |
| §4.2 pause/input/menus | Months 3–4 ContextStack; Months 10–12 authored menus | UI focus tests; gamepad-only playtest. |
| §4.3 economy (item loss, double gold, craft arbitrage, paused potions, 3 item DBs) | Months 7–9 ItemDB, Market v1; Y2 economy design | Headless economy simulation in CI. |
| §4.4 player combat | Months 5–6 | Input-replay tests. |
| §4.5 enemies/bosses | Months 5–6 | Spawn tests; stat invariants across phases and retries. |
| §4.6 story/progression | Months 1–2 critical; Y2 route architecture; Y6 endings | Bot over every storyline and timing branch; missables signposted. |
| §4.7 effects/camera/audio | Months 5–9 FeelService and audio; Months 10–12 cutscene timelines | Export-build smoke test in CI. |
| §5 audit re-verification | Months 1–2 | Covered by the tests above. |
| §6 PAE pipeline items 1–10 | Months 7–9 | Importer tests; import-settings lint. |
| Appendix medium/low | When the owning system is replaced; the rest in the Y2-Q3/Q4 cleanup | One GitHub Issue per item. |
| Tooling/repo/docs | Months 1–4; Y2 cleanup | CI plus a hygiene checklist at every gate. |

---

## 12. System specifications

### 12.1 Difficulty profiles (P6) — starting values, tuned by playtest
| | Beginner | Easy | Medium | Hard | Hell |
|---|---|---|---|---|---|
| Parry window (frames at 60 fps) | 12 (200 ms) | 9 | 6 | 4 | **2 (33 ms)** |
| Dodge i-frames | 18 | 15 | 12 | 10 | 8 |
| Boss telegraph | ×1.5 | ×1.25 | ×1.0 | ×0.85 | ×0.7 |
| Enemy damage | ×0.6 | ×0.8 | ×1.0 | ×1.3 | ×2.0 |
| Boss patterns | base | base | +variants | +variants | **+Hell-only phase** |
| Healing charges | 5 | 4 | 3 | 2 | 1 |
| DDA | gentle | on | off | off | off |
| Quest deadline leniency | ×1.5 | ×1.25 | ×1.0 | ×1.0 | ×0.85 |
| Loot | base | base | +rare | +epic | +Hell cosmetics/titles |

- Beginner is still tough because every boss demands **pattern literacy**. Lower difficulties forgive
  *execution*, not *attention*.
- Hell's 2-frame windows need a fixed tick, a 4-frame input buffer, latency calibration in options,
  and replay-verified fairness.
- You can lower difficulty mid-run but never raise it.

### 12.2 Storyline architecture (P3, P5, P8)
```
Act 1 ─► Act 2 (axis choices) ─► Act 3 [Branch A | B | C] ─► Act 4 (bottleneck + variants) ─► Ending ─► Story+
   Axis 1: Who holds Root Access?          (you / shared / no one)
   Axis 2: Which faction do you back?       (3 factions)
   Axis 3: What happens to the deleted?     (restore / release / let them choose)   ← Null Court thesis
   Side storylines (12): each writes into one axis or a timing modifier.
   Secret quests: add hidden 4th axis values → 3 secret storylines.
   Timing modifiers (§12.4): change scenes and ending slides, but do not multiply storylines.
```
- 3 × 3 × 3 = 27 combinations; the invalid ones are removed, giving **24 storylines + 3 secret**.
- The **ending composer** assembles modular sequences (axis values + companions + regions + timing),
  so authored cost is additive.
- **Story+** is a playable post-ending chapter in the open world, with its state driven by axes and
  timing.
- **Rule:** nothing important is lost silently. Every missable item, quest or storyline is signposted
  in the world before it closes.

### 12.3 Living NPCs (P4)
| Tier | Count | Schedule | Memory | Reactions | Arc |
|---|---|---|---|---|---|
| A | 10 | Full, calendar-aware | 20+ facts | Contextual dialogue, combat banter | Full arc + Story+ |
| B | 70 | Daily, calendar-aware | 5–10 facts | Barks to player state and time | Mini-arc or quest; merchants trade on the market |
| C | ~200 | Simple | Reputation only | Barks | — |

- Crime and witnesses; festivals and market days on the calendar.
- **Simulation LOD:** off-screen NPCs only advance their schedule, and distant towns update at a
  coarse tick.

### 12.4 Time-sensitive world (P7f)
- **WorldClock:** day/night, days, a ~28-day month, 4 seasons. One in-game day lasts about 24 real
  minutes (tunable). Deterministic and saved. Waiting or resting advances it.
- **Quest timing types:**
  - **Window:** available only on days X–Y or during an event.
  - **Deadline:** complete within N days.
  - **Order:** doing A before B changes B.
  - **Duration:** a faster or slower completion changes the outcome.
- **Effect on the main story:** each act tracks a **pace value** (early / on-time / late) and named
  **timing flags**, such as "the bridge fell before you arrived". These change scenes, NPC fates,
  market events and ending slides through the composer. They don't create new storylines, which
  keeps the cost additive.
- **Fairness:**
  - Deadlines appear in the quest log with an in-world reason.
  - Difficulty scales leniency (§12.1).
  - Main-story deadlines never fail without a signposted warning.
  - Story+ shows what your timing changed.
- **Testing:** a seeded RNG and clock, plus a bot that runs fast, slow and out-of-order profiles.

### 12.5 Open world & exploration (P7a, P1)
- One continuous 2D world made of **streamed chunks** (TileMapLayer per chunk, ~32×32 tiles).
  Regions blend at authored seams; there are no loading screens.
- Points of interest, discoveries (lore, caches, secrets), dynamic world events tied to the clock,
  traversal unlocks (gated by abilities, not invisible walls), map with fog of war, fast travel
  between discovered waystations.
- **Combat transition:** enemies are visible in the world. Contact starts the shatter transition into
  a side-scroll arena generated from the terrain context (biome, terrain shape, hazards), then returns
  you to the same world position.
- Budgets: streaming hitches under 2 ms; at most N active simulated NPCs per chunk.

### 12.6 Marketplace, auctions, limited editions (P7b)
- **Shops:** fixed catalogs per NPC merchant, with prices modified by reputation and route.
- **Market:** ~120 commodities. Price = base + seasonality(calendar) + demand(player + NPC agents) +
  noise. This is the blueprint's formula, now running on the WorldClock. A simulated population of
  NPC traders (gatherers, merchants, collectors) buys and sells on schedules.
- **Auction house** (4 cities):
  - Lots run on in-game time; NPC bidders have budgets and preferences.
  - The player can bid or list. **Listings are limited** (e.g. 3 active lots, per-week caps) so the
    auction stays special.
  - A fee, as a currency sink.
- **Limited editions:** a calendar of releases (festival weapons, numbered artifacts, season-only
  cosmetics), sold in limited stock at specific places and times, sometimes only by auction. Some
  can be missed, and are signposted in advance.
- **Anti-exploit rules** (the review found an infinite-gold loop):
  - Sell price ≤ 40% of buy price.
  - A crafted item's value is ≤ 90% of its inputs' market value unless upgraded by skill.
  - Auction sniping is capped by NPC behaviour.
  - Sources and sinks are tracked; the headless economy sim runs in CI.
- **Single-player** (A5). An online market is explicitly out of scope unless you change A5 at Gate 3.

### 12.7 Gambling & minigames (P7c)
- **Gambling (3):** e.g. a dice game, a card game, and betting on arena fights. In-game currency
  only, a visible house edge, daily table limits, never needed for progress. **No real money and no
  paid randomized items.** Simulated gambling raises age ratings in most rating systems and some
  countries restrict it, so verify before Beta.
- **Minigames (5):** e.g.
  - fishing (it was already in the lore's post-game);
  - a Root Access hacking puzzle (fits the theme);
  - a forge/crafting timing game (better crafts);
  - racing or a courier run (time-sensitive);
  - a rhythm or festival game.

  Each one gets a one-page design, a reward table that respects the economy rules, and difficulty
  options.

### 12.8 Stats & builds (P7d)
- **Primary stats** (proposal, to be finalized): STR, AGI, VIT, INT, SPI, LCK. They grow through
  level points, **training and use** (the stats you exercise grow faster), choices, and items or
  buffs.
- Derived stats come from the modifier stack: damage, health, resources, crafting quality, market
  haggling, gambling luck (small, capped).
- **Rule:** stats change damage, resources and economy. **They never change parry or dodge frame
  windows.** Skill stays central, especially on Hell.
- Respec at a cost; build archetypes documented for balance.

### 12.9 Items & crafting (P7e)
- **ItemDB** (`.tres`): ~450 items, rarities, affix tables, sets, uniques, limited editions.
- 8 equipment slots. Crafting trees, refine and upgrade, salvage (a sink), and quality driven by the
  forge minigame and stats.
- **Visuals:** the weapon sprite changes per weapon class. Armor shows through palette swaps and a
  small set of overlay layers. A full paper-doll would multiply PAE animation work by every armor
  piece, so it is not recommended.

### 12.10 Combat feel (P2)
- Frame data in `.tres`, hitstop tiers, cancel windows, an aerial and pogo game, tools and abilities,
  and Root Access as tactical slow-time.
- Every hit gives camera, particle, audio and controller feedback.
- Inspired by Silksong's feel, but **original moves and visuals**.

---

## 13. Risk register (top 14)

| Risk | Likelihood | Impact | Mitigation |
|---|---|---|---|
| Scope creep / never finishing | High | Fatal | Gates, cut order, vertical production, re-baselines |
| **Burnout from 84 h/week over years** | **High** | **Fatal** | 60 h focused plan, 1 rest day, team from G3, track energy as seriously as bugs |
| PAE art can't reach the quality or consistency bar | Medium | High | Art bible and G1 test; contract animator after G3 |
| Narrative combinatorial explosion | High | High | Axes + composer + additive timing modifiers; bot-verified before writing |
| **Economy exploits / inflation** | High | High | Anti-exploit rules, headless economy sim in CI, telemetry from EA |
| **Time-system complexity** (untestable branches, frustrating misses) | High | High | Deterministic clock, bot timing profiles, signposting rule, leniency per difficulty |
| Open-world streaming performance | Medium | High | Chunk budgets, simulation LOD, performance tests in CI |
| Hell mode feels unfair | Medium | Medium | Replay-verified windows, input buffer, latency calibration |
| Save breakage across EA patches | Medium | High | SaveService migrations and CI from Month 3 |
| **Gambling content: ratings and regional restrictions** | Medium | Medium | In-game currency only, rating check before Beta, region config |
| Godot version drift | Medium | Medium | Pin per gate; upgrade branch with the full suite |
| Funding gap at G3 | Medium | High | Smaller-game fallback; Early Access revenue |
| Legal (licenses, AI disclosure, title trademark) | Medium | High | Audits in Y2 and Y7; provenance records |
| Key-person risk | High | High | ADRs, tests, onboarding docs, shared ownership once the team exists |

---

## 14. Operating rhythm

- **Daily:** 2 focused blocks of about 4–5 h, plus a short log of what changed and what's blocked.
- **Weekly (6 days on, 1 off):** a playable build, a playtest note, the tracker updated.
- **Monthly:** milestone review against this plan; update the risk register.
- **Quarterly:** re-plan; compare measured speed with the budget.
- **At each gate:** a go / re-scope / pivot decision, recorded as an ADR.
- **Every change:** Conventional Commits and green CI before merge.
- **Backups:** Git remote, an off-site LFS copy, and PAE project files.

---

## 15. Next two weeks

1. ~~Confirm A5 and A6~~ (confirmed 2026-10-04). All assumptions in §1 are now settled.
2. Repo hygiene: move off OneDrive, enable LFS, fix the `origin` remote, add `.gdignore` and export
   filters.
3. Convert every review finding into GitHub Issues tagged by phase (§11).
4. Start Phase 0 with the three fixes that unblock playtesting: **dialogue close (C1/C2)**, **save
   rejection (C9/C10)**, **Chapter 3 → 4 exit (C4)**.
5. Write `DESIGN_PILLARS.md` from §2 and retire the outdated docs.
