# PASS 34–35: LEVEL DESIGN & SIDE QUEST AUDIT
**Date:** 2026-03-01  
**Files Audited:** 10 scripts + 1 UI file  
**Fixes Applied:** 14 (6 CRITICAL, 8 HIGH)

---

## PASS 34 — LEVEL DESIGN AUDIT

### Area Variety ✅ GOOD
| Area | Theme | Palette | Distinct Mechanics |
|---|---|---|---|
| Oakhaven | Pastoral village — wood/grass/thatch | Green/brown/warm sky | NPC dialogue, quest hub, tutorial combat |
| Ironhold City | Steampunk hub — copper/rust/brass | Orange/industrial/cyan glow | 5 districts, 7+ NPCs, market/arena/tower |
| Underground Network | Dark dungeon — corruption zones | Purple/dark blue/data pipes | Puzzle triggers, corruption hazards, mini-boss |
| Archive Depths | Recursive library — code/documents | Cold blue/white/code-text | 4-floor puzzle dungeon, zero combat, lore reveals |
| Combat Arena | Stone arena — wave-based | Grey/spotlight/iron | 4 tiers, announcer, wave progression |
| Forest Path (Ch1) | Twilight forest — approaching village | Dark green/fireflies/warm glow | Cinematic, Data Vision tutorial, Root Access tutorial |

**BackgroundManager** provides 6+ distinct procedural palettes with 40+ asset paths defined — excellent visual diversity.

### Navigation ⚠️ MEDIUM
- **Ironhold:** Buildings labeled with text, trigger areas for districts (arena, clock tower, underground) — **functional**
- **Underground:** Linear corridor → chamber → corridor → puzzle → boss — **clear progression**
- **Archive:** Floor indicator label at top-left tracks progress — **adequate**
- **Missing:** No minimap, no compass, no waypoint markers. Map tab in pause screen is text-only.
- **Oakhaven:** Small area with boundary walls — hard to get lost.

### Secrets ✅ GOOD
- **SideQuestManager** defines 6 secret collectibles (3 dev signatures, 3 lore fragments) across all chapters
- Debug Room meta-quest triggers on collecting 3 dev signatures
- Secret discovery grants 50 XP + notification
- Hidden paths referenced in Data Vision tutorial (locked door in Ch1 forest)

### Pacing ✅ GOOD
| Chapter | Flow |
|---|---|
| Ch1 | Cinematic → exploration → tutorial combat → village hub |
| Ch2 | City exploration → NPC dialogues → arena fights → story triggers → dungeon |
| Ch3 | Pure puzzle/lore — 4 floors of brain teasers, zero combat, major revelations |

Combat-to-rest ratio is strong. Ch3 is an excellent breather/story dump.

### Environmental Storytelling ✅ EXCELLENT
- Underground: Data pipes, corruption zones, fragment glow — tell the story of abandoned code
- Archive: Recursive geometry, Archivist made of code comments, holographic documents
- Ironhold: Steam vents, district architecture, clock tower "heartbeat"
- Oakhaven: Tree silhouettes with sway animation, fireflies, distant village glow

### Checkpoints ❌→✅ FIXED
**Before:** Only 1 auto-save (underground boss defeat). No saves in Archive Depths (4 puzzle floors = 30+ min content).

**After (FIXED):**
| Location | Checkpoint | File |
|---|---|---|
| Underground entry | Auto-save | `ch2_underground_network.gd` |
| Underground puzzle solved | Auto-save | `ch2_underground_network.gd` |
| Underground boss defeat | Auto-save (existing) | `ch2_underground_network.gd` |
| Archive entry | Auto-save | `ch3_archive_depths.gd` |
| Archive Floor 1 | Auto-save | `ch3_archive_depths.gd` |
| Archive Floor 2 | Auto-save | `ch3_archive_depths.gd` |
| Archive Floor 3 | Auto-save | `ch3_archive_depths.gd` |
| Archive Floor 4 | Auto-save | `ch3_archive_depths.gd` |

### Enemy Placement ✅ GOOD
- **Underground:** Entry corridor (empty) → First chamber (guard + sprite) → Puzzle chamber (wraith + guard) → Boss chamber (Data Wraith mini-boss) — gradual escalation
- **Arena:** Level-gated tiers (Bronze Lv1 → Silver Lv3 → Gold Lv5 → Platinum Lv7), wave count increases per wave, enemy variety per tier
- **Tutorial:** Single slime, introduced with full Root Access tutorial

### Backtracking ⚠️ MEDIUM
- Underground returns to Ironhold after completion ✅
- Clock tower is flag-gated (requires `ch2_underground_complete`) ✅
- Arena entrance gated by Vex dialogue ✅
- No ability-gated Metroidvania areas — acceptable for this game's structure (linear chapter progression with hub re-entry)

---

## PASS 35 — SIDE QUEST AUDIT

### Quest Database Summary
| Quest | Chapter | Type | Rewards |
|---|---|---|---|
| Lost Memories | 1 | Collection (3 items) | 150 XP, 75 Gold, Memory Crystal |
| Corrupted Cellar | 1 | Boss fight | 200 XP, 100 Gold, Forge Heart, +3 ATK |
| Herbalist's Favor | 1 | Fetch (3 herbs) | 100 XP, 50 Gold, Null Heal Potion |
| Arena Legend | 2 | Challenge (5 tiers) | 500 XP, 300 Gold, Arena Veteran charm, Title |
| Data Hoard | 2 | Exploration (5 caches) | 300 XP, 200 Gold, Lore fragment |
| Merchant Guild | 2 | Negotiate/Fight | 200 XP, 150 Gold, 15% shop discount |
| Echo Hunter | 3 | Tracking (3 wraiths) | 350 XP, 150 Gold, Echo Sense ability |
| Survivor's Cache | 3 | Puzzle | 250 XP, 200 Gold, Stabilizer Mk2, +5 DEF, +20 HP |
| Lyra's Past | 3 | Relationship | 200 XP, Lyra +15 relationship, Power Shot ability |
| Debug Room | Cross | Meta (3 dev sigs) | 1000 XP, 500 Gold, Developer Insight charm, Title |

**Quest Variety: ✅ EXCELLENT** — Collection, boss, fetch, challenge, exploration, negotiation, tracking, puzzle, relationship, meta.

### Quest Tracking ❌→✅ FIXED

**CRITICAL FIX 1 — Pause screen now shows SideQuestManager quests:**
- Active quests show name, step progress (X/Y), and current objective text
- Discovered quests show name + discovery hint
- Completed quests shown in greyed-out section
- Color-coded by priority (EPIC/HIGH/MEDIUM/LOW)
- File: `scripts/ui/pause_screen.gd` → `_refresh_tickets_tab()`

**CRITICAL FIX 2 — HUD Quest Tracker added:**
- Persistent on-screen panel (top-right) showing up to 3 active quests
- Shows quest name, step count, and current objective
- Auto-hides when no quests are active
- Updates on every quest start/advance/complete
- File: `scripts/side_quest_manager.gd` → `_create_hud_tracker()`, `_update_hud_tracker()`

**CRITICAL FIX 3 — Completionist tracker added:**
- Bottom of tickets tab shows "Side Quests: X/10 | Secrets: X/6 | Completion: X%"
- Purple-colored for visibility
- File: `scripts/ui/pause_screen.gd` → `_refresh_tickets_tab()`

### NPC Interactions ❌→✅ FIXED

**Before:** Quests auto-discovered on scene `_ready()` with no NPC involvement.

**CRITICAL FIX 4 — NPC-driven quest starts:**
| NPC | Quest | Trigger | File |
|---|---|---|---|
| Flickering NPC | Lost Memories | Area2D interaction | `oakhaven.gd` |
| Blacksmith | Corrupted Cellar | Area2D interaction | `oakhaven.gd` |
| Apothecary | Herbalist's Favor | Area2D interaction | `oakhaven.gd` |
| Elara | Lost Memories hint | First-meet dialogue | `oakhaven.gd` |
| Vex | Arena Legend | First dialogue | `ch2_ironhold_city.gd` |
| Entry trigger | Data Hoard | Dungeon entry | `ch2_underground_network.gd` |
| Scene entry | Echo/Survivor/Lyra | Ch3 discovery | `ch3_archive_depths.gd` |

### Quest Lifecycle ❌→✅ FIXED

**CRITICAL FIX 5 — Quests are now properly started and advanced:**

**Before:** `start_quest()` and `advance_quest()` were defined but NEVER called. Quests stayed in DISCOVERED state forever.

**After:**
- NPC interactions call `start_quest()` to move DISCOVERED → ACTIVE
- Arena tier completions call `advance_quest("ironhold_arena_legend")`
- Underground puzzle/boss events call `advance_quest("ironhold_underground_data")`
- `start_quest()` now shows objective notification
- `advance_quest()` now shows next step notification
- `start_quest()` guards against restarting completed quests

### Rewards ❌→✅ FIXED

**HIGH FIX 6 — Missing reward handlers added to `complete_quest()`:**

| Reward Type | Before | After |
|---|---|---|
| `xp` | ✅ Handled | ✅ Handled |
| `gold` | ✅ Handled | ✅ Handled |
| `item` | ✅ Handled | ✅ Handled |
| `stat_boost` | ✅ Handled | ✅ Handled |
| `relationship` | ✅ Handled | ✅ Handled |
| `charm` | ✅ Handled | ✅ Handled |
| `title` | ❌ Ignored | ✅ Stored in `GameManager.titles_earned` |
| `shop_discount` | ❌ Ignored | ✅ Stored in `GameManager.shop_discount` |
| `unlock` | ❌ Ignored | ✅ Sets story flag `unlocked_<name>` |
| `ability` | ❌ Ignored | ✅ Sets story flag `ability_<name>` |
| `lore` | ❌ Ignored | ✅ Sets story flag `lore_<name>` |

### Optional Content ✅ GOOD
- All side quests are truly optional — no main story dependency
- `requires_flag` system on `wastes_lyra_past` properly gates conditional quests
- Debug Room cross-chapter quest rewards thorough exploration

### Bug Checking ✅ FIXED
- Quests can no longer get permanently stuck in DISCOVERED state (NPC triggers start them)
- `start_quest()` now guards against restarting already-completed quests
- `_data_wraith_choice()` already has fallback default case for invalid choice index
- Save/load system preserves quest state and secrets

---

## FULL FIX INVENTORY

| # | Severity | Category | Description | File(s) |
|---|---|---|---|---|
| 1 | **CRITICAL** | Side Quest | Pause screen tickets tab now integrates SideQuestManager | `pause_screen.gd` |
| 2 | **CRITICAL** | Side Quest | HUD quest tracker shows active objectives on-screen | `side_quest_manager.gd` |
| 3 | **CRITICAL** | Side Quest | `start_quest()` / `advance_quest()` now called from game scripts | `oakhaven.gd`, `ch2_ironhold_city.gd`, `ch2_underground_network.gd`, `arena_manager.gd`, `ch3_archive_depths.gd` |
| 4 | **CRITICAL** | Side Quest | NPC interactions start quests (not auto-discover on entry) | `oakhaven.gd` |
| 5 | **CRITICAL** | Level Design | Auto-save checkpoints at dungeon entry + progression | `ch2_underground_network.gd`, `ch3_archive_depths.gd` |
| 6 | **CRITICAL** | Side Quest | Missing reward handlers (title, shop_discount, unlock, ability, lore) | `side_quest_manager.gd` |
| 7 | **HIGH** | Side Quest | Discovery hints shown in notification on quest discover | `side_quest_manager.gd` |
| 8 | **HIGH** | Side Quest | Quest start shows objective notification | `side_quest_manager.gd` |
| 9 | **HIGH** | Side Quest | Quest advance shows next step notification | `side_quest_manager.gd` |
| 10 | **HIGH** | Side Quest | Completionist tracker (quests + secrets percentage) | `pause_screen.gd` |
| 11 | **HIGH** | Side Quest | Arena tier completion advances arena legend quest | `arena_manager.gd` |
| 12 | **HIGH** | Side Quest | Underground events advance data hoard quest | `ch2_underground_network.gd` |
| 13 | **HIGH** | Side Quest | Ch3 quests discovered on archive entry | `ch3_archive_depths.gd` |
| 14 | **HIGH** | Side Quest | `start_quest()` guards against restarting completed quests | `side_quest_manager.gd` |

---

## REMAINING ITEMS (MEDIUM/LOW — Not blocking)

| Severity | Description |
|---|---|
| MEDIUM | No minimap or compass — map tab is text-only placeholder |
| MEDIUM | No healing stations in dungeons (only potion items) |
| MEDIUM | No ability-gated Metroidvania backtracking |
| LOW | Ch3 archive floors have no ambient enemy presence (by design — puzzle dungeon) |
| LOW | Underground corruption zones have no visual warning indicator before entry |
| LOW | No "quest abandoned/failed" mechanic for timed or exclusive quests |

**Status: PASS 34 & 35 COMPLETE — All CRITICAL and HIGH issues resolved.**
