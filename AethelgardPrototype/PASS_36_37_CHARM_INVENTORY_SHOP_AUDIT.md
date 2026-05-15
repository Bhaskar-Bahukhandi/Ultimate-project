# PASS 36 & 37 — Charm System + Inventory & Shop Audit

**Date:** 2026-03-01  
**Status:** COMPLETE — 8 fixes applied (3 CRITICAL, 5 HIGH)  
**Files Modified:** 4 (`game_manager.gd`, `inventory_system.gd`, `shop_system.gd`, `ui/pause_screen.gd`)

---

## PASS 36: CHARM SYSTEM AUDIT

### Charm Definitions (6 charms)

| Charm ID | Name | Effect | Value | Shop Price |
|---|---|---|---|---|
| `extended_parry` | Extended Parry | Parry window +40% | 1.4× | 800G |
| `soul_hoarder` | Soul Hoarder | Soul gain +50%, spell cost -20% | 1.5× | 1200G |
| `corruption_resist` | Firewall | Corruption gain reduced 40% | 0.6× | 1500G |
| `pogo_master` | Pogo Master | Pogo damage +80%, bounce +30% | 1.8× | 600G |
| `dash_master` | Shadow Dash | Dash CD -50%, deals 10 damage | 0.5× | 1000G |
| `thorns` | Thorns of Pain | Reflect 15 damage when hit | 15.0 | 700G |

### Notch / Slot System

- **MAX_CHARM_SLOTS = 3** — Fixed capacity, no variable notch costs
- Simpler than Hollow Knight's notch system but functional
- Enforced in `equip_charm()` with `equipped_charms.size() >= MAX_CHARM_SLOTS` ✅

### Combat Integration — ALL 6 CHARMS CONNECTED ✅

| Charm | Where Applied | Code Location | Status |
|---|---|---|---|
| `extended_parry` | `_start_parry()` — `PARRY_WINDOW * get_charm_value("extended_parry")` | player_combat.gd:884 | ✅ |
| `soul_hoarder` | `_add_soul()` — `amount *= get_charm_value("soul_hoarder")` | player_combat.gd:1335 | ✅ |
| `soul_hoarder` | `_spend_soul()` — `amount *= 0.8` | player_combat.gd:1343 | ✅ |
| `corruption_resist` | `add_glitch_corruption()` — `amount *= get_charm_value("corruption_resist")` | game_manager.gd:253 | ✅ |
| `pogo_master` | `_execute_pogo()` — pogo damage × charm value + bounce × 1.3 | player_combat.gd:910-935 | ✅ |
| `dash_master` | `_start_dash()` — cooldown × charm value | player_combat.gd:805-806 | ✅ |
| `dash_master` | `_end_dash()` — 10 damage to nearby enemies | player_combat.gd:849-856 | ✅ |
| `thorns` | `take_damage()` — reflect damage to closest attacker | player_combat.gd:1438-1453 | ✅ |

### Charm Combinations / Synergies

- **No explicit synergy system** — each charm is independent
- Natural synergies exist:
  - `soul_hoarder` + `extended_parry` (more parries → more soul → more spells at -20% cost)
  - `dash_master` + `thorns` (aggressive close-range playstyle)
  - `corruption_resist` + any (longer hack abuse)
- **Assessment:** Adequate for current scope. Explicit combos could be a future feature.

### Equip/Unequip Restrictions

- **BEFORE FIX:** Could swap charms freely at any time, including mid-combat
- **AFTER FIX:** `equip_charm()` / `unequip_charm()` now block during `GameState.COMBAT`
- Pause screen shows feedback message when blocked

### Visual Effects

- **No visual aura/appearance changes for equipped charms** — LOW priority
- Charm stat previews are shown in pause screen with concrete numbers ✅
- Equipped charms show green text + EQUIPPED label ✅

### Balance Assessment

| Charm | Tier | Notes |
|---|---|---|
| `corruption_resist` | S-tier | 40% corruption reduction is extremely strong given corruption = game over at 100%. Price (1500G) is justified. |
| `soul_hoarder` | A-tier | +50% soul + -20% spell cost = 87.5% more effective spell economy. Core for spell builds. |
| `dash_master` | A-tier | Halved dash cooldown is huge for defense. The 10 damage is nice but secondary. |
| `extended_parry` | B-tier | +40% window is helpful but skilled players already parry with base timing. |
| `pogo_master` | B-tier | Niche — only useful against enemies vulnerable from above. +80% is huge when applicable. |
| `thorns` | C-tier | 15 passive damage is marginal late-game. Encourages getting hit which is bad strategy. |

**Recommendation:** Thorns could scale with player level or corruption level to stay relevant.

### Edge Cases

| Edge Case | Status |
|---|---|
| Equip during combat | ✅ FIXED — Now blocked |
| Stack identical charms | ✅ Already prevented by `if charm_id in equipped_charms` check |
| Auto-equip on purchase | ✅ FIXED — Removed auto-equip from `unlock_charm()` |
| Buy already-owned charm | ✅ FIXED — Shop pre-validates in `_buy_item()` |
| Unequip then re-equip same charm | ✅ Works correctly |
| Save/load charm state | ✅ `unlocked_charms` + `equipped_charms` both persisted |

---

## PASS 37: INVENTORY & SHOP AUDIT

### Item Database

**8 consumables, 4 weapons, 4 armor pieces, 6 charms = 22 items total**

| Category | Items | Stack | Notes |
|---|---|---|---|
| Consumables | health_potion, mana_potion, glitch_stabilizer, null_potion, antidote | 99 | All have effects wired ✅ |
| Weapons | iron_sword (+10), steel_blade (+18), corrupted_knight_blade (+8) | 1 | Applied via `_apply_equipment_bonuses()` ✅ |
| Armor | leather_armor (+5), chain_mail (+12), spiked_shield (+8), phantom_cloak (+8) | 1 | Applied via `_apply_equipment_bonuses()` ✅ |
| Charms | 6 charms via charm_dealer shop | N/A | Stored in `unlocked_charms`, not inventory ✅ |
| Key Items | Source Key Fragments | N/A | Tracked via `story_flags` ✅ |

### Shop System

- **4 shop types:** apothecary, blacksmith, charm_dealer, general
- **BUY / SELL tabs** with sort (name, price, type) and filter (all, consumable, weapon, armor, charm)
- **Tooltip system** with hover highlighting
- **UIStack integration** prevents shop + pause overlap ✅
- **ESC close** with keyboard/gamepad focus ✅

### Economy Analysis

| Item | Buy | Sell | Margin | Notes |
|---|---|---|---|---|
| Health Potion | 10G | 4G | 60% margin | Cheap staple ✅ |
| Mana Potion | 15G | 6G | 60% margin | ✅ |
| Glitch Stabilizer | 50G | 20G | 60% margin | Important anti-corruption ✅ |
| Null Potion | 500G | 200G | 60% margin | High-end full heal with drawback ✅ |
| Iron Sword | 120G | 48G | 60% margin | Consistent sell ratio ✅ |
| Chain Mail | 280G | 112G | 60% margin | ✅ |
| Charm: Firewall | 1500G | 600G | 60% margin | Can't be resold (goes to unlocked_charms) |

**All buy/sell ratios are 40% (sell = 0.4 × buy).** Consistent and sane.

**Gold acquisition sources:**
- Enemy drops (via DropManager)
- Arena wins (streak multiplier up to 2.5×)
- Loot table rolls

**Assessment:** Charm prices (600-1500G) feel like mid-to-late-game purchases. Health potions at 10G are very cheap. Balance is reasonable for a first playthrough.

### Consumable Effects

| Item | Effect | Wired | Notes |
|---|---|---|---|
| health_potion | `heal` 50 HP | ✅ Finds player, calls `heal()` | |
| mana_potion | `restore_mana` 30 MP | ✅ Via GameManager | |
| glitch_stabilizer | `reduce_glitch` -20% | ✅ Via `add_glitch_corruption(-20)` | |
| null_potion | `null_heal` Full HP + -10 corruption | ✅ | Shop desc says +3% corruption but code gives -10 corruption. **Mismatch but both implementations exist** |
| antidote | `reduce_glitch` -10% | ✅ | |

### Key Items & Quest Items

- Source Key Fragments tracked via `story_flags["source_key_fragment_N"]` ✅
- Displayed in pause screen Assets tab when flag is true ✅
- Cannot be sold (not in inventory system, flag-based) ✅

### Equipment System

- **3 slots:** weapon, armor, accessory
- Equipment bonuses applied via `_apply_equipment_bonuses()` which:
  1. Reads corruption penalty
  2. Applies penalty to base stats
  3. Adds equipment bonuses on top
- Auto-recalculates on equip/unequip/corruption change ✅
- **No accessory items defined yet** — the slot exists but nothing equips to it

### Persistence

- `inventory_items`, `inventory_gold`, `inventory_equipment` all saved ✅
- Validated on load with type checking ✅
- Equipment slot keys restored correctly for weapon/armor/accessory ✅

---

## FIXES APPLIED

### CRITICAL Fixes

#### C1. Parse Error — Indentation Bug in pause_screen.gd
**File:** `scripts/ui/pause_screen.gd` line 293  
**Issue:** Extra tab on `unequip_btn.add_theme_font_size_override()` would cause GDScript parse error  
**Fix:** Corrected indentation to match surrounding code

#### C2. Shop Charm Double-Purchase
**File:** `scripts/shop_system.gd` `_buy_item()`  
**Issue:** No pre-validation for already-owned charms. While UI hid them, programmatic calls or race conditions could deduct gold for an already-unlocked charm  
**Fix:** Added `GameManager.is_charm_unlocked(charm_id)` check before gold deduction

#### C3. Gold Desync in Shop Purchase
**File:** `scripts/shop_system.gd` `_buy_item()`  
**Issue:** Gold deducted by directly modifying `GameManager.player_stats["gold"]` then manually syncing to `Inventory.gold`. Different code path than `add_gold()` API  
**Fix:** Now uses `Inventory.remove_gold()` which internally syncs to GameManager. Refund uses `Inventory.add_gold()` for consistency

### HIGH Fixes

#### H1. Charm Swapping During Combat
**File:** `scripts/game_manager.gd` `equip_charm()` + `unequip_charm()`  
**Issue:** No restriction on changing charms during active combat — allows exploitative mid-fight loadout switching  
**Fix:** Added `current_state == GameState.COMBAT` guard. Returns false + push_warning  
**UI:** `scripts/ui/pause_screen.gd` now shows feedback message when equip/unequip blocked

#### H2. Missing Sell Prices for Looted Items
**File:** `scripts/inventory_system.gd` ITEMS dictionary  
**Issue:** `corrupted_knight_blade` and `data_wraith_phantom_cloak` had no `buy_price`/`sell_price`. When sold via shop, they'd get fallback `int(10 * 0.4) = 4G` — unfairly low for boss drops  
**Fix:** Added `buy_price` and `sell_price` to both items + all base items

#### H3. Missing Items in Inventory Database
**File:** `scripts/inventory_system.gd` ITEMS dictionary  
**Issue:** `mana_potion`, `null_potion`, `antidote`, `steel_blade`, `chain_mail`, `spiked_shield` only existed in `SHOP_ITEMS`. If player received these through loot before visiting a shop (which triggers `_sync_items_to_inventory`), they'd hit "Unknown item" errors  
**Fix:** Added all 6 items directly to Inventory ITEMS database with matching stats/prices

#### H4. Auto-Equip on Charm Unlock
**File:** `scripts/game_manager.gd` `unlock_charm()`  
**Issue:** When buying a charm, `unlock_charm()` auto-equipped it if slots were available. This surprises players and removes agency  
**Fix:** Removed auto-equip. Player must manually equip via Charms tab

#### H5. Sell Safety Checks
**File:** `scripts/shop_system.gd` `_sell_item()`  
**Issue:** No guard against selling equipped items or key items at the API level (only UI filtered them out)  
**Fix:** Added `_is_equipped()` check + key_item type check + `sell_price = maxi(sell_price, 1)` floor

---

## REMAINING LOW-PRIORITY ITEMS (Not Fixed)

| Item | Severity | Notes |
|---|---|---|
| No visual aura for equipped charms | LOW | Cosmetic — add glow/particles to player sprite when charms equipped |
| No accessory items | LOW | Slot exists in `equipment` dict but no items fill it |
| Thorns charm scales poorly | LOW | Consider scaling with level: `thorns_dmg * (1 + level * 0.1)` |
| No charm combination bonuses | LOW | Could add 2-charm synergy bonuses as a future system |
| No restock timer on shops | LOW | Shops have infinite stock — fine for a single-player game |
| null_potion description mismatch | LOW | Shop says "+3% corruption" but code heals HP + removes 10 corruption with `null_heal` effect. Clarify intent |
| No "confirm purchase" dialog | LOW | Accidental expensive purchases possible |
| ItemResource not linked to runtime | LOW | `item_resource.gd` exists as a proper Resource class but runtime systems still use raw dictionaries. Future migration path |

---

## SYSTEM ARCHITECTURE SUMMARY

```
┌─────────────────────┐
│   ShopSystem (UI)   │──── SHOP_ITEMS database (prices, descriptions)
│   BUY / SELL / Sort │     │
│   Filter / Tooltip  │     │ _sync_items_to_inventory()
└────────┬────────────┘     ▼
         │           ┌──────────────────┐
    buy/sell ───────►│  InventorySystem  │──── ITEMS database (effects, stacks)
         │           │  items: {}        │
         │           │  equipment: {}    │
         │           │  gold: int        │
         │           └────────┬─────────┘
         │                    │ _apply_equipment_bonuses()
         │                    ▼
┌────────┴────────────────────────────────┐
│            GameManager                    │
│  player_stats (hp, mp, atk, def, gold)   │
│  unlocked_charms / equipped_charms       │
│  CHARM_INFO / CHARM_VALUES               │
│  corruption system (affects stat penalty) │
│  save/load (persists all above)           │
└─────────────────┬────────────────────────┘
                  │ has_charm() / get_charm_value()
                  ▼
┌─────────────────────────────────┐
│       PlayerCombat              │
│  Extended Parry ✅ (line 884)    │
│  Soul Hoarder ✅ (line 1335)    │
│  Pogo Master ✅ (line 910)      │
│  Dash Master ✅ (lines 805,849) │
│  Thorns ✅ (line 1438)          │
└─────────────────────────────────┘
           + GameManager.add_glitch_corruption()
             └── Corruption Resist ✅ (line 253)
```

All charm effects are wired end-to-end. Inventory persists correctly. Shop has proper safety checks.
