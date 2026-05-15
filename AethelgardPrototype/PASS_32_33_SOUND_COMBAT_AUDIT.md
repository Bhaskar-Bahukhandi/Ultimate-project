# Pass 32 — Sound Design Audit + Pass 33 — Combat Balance Audit

**Date**: 2025-01-XX  
**Scope**: All 78 GDScript files — SFX coverage, pitch variation, stat balance, DDA tuning  
**Files Modified**: 6

---

## PASS 32: SOUND DESIGN

### A. Missing SFX Definitions — 18 FIXED ✅

The following SFX names were called by enemy/combat scripts but had **no matching entry** in `SFX_DEFS` (sfx_manager.gd). The `play()` function would log a `push_warning` and produce silence.

| # | SFX Name | Called By | Fix Applied |
|---|----------|-----------|-------------|
| 1 | `enemy_hop` | slime.gd:90 | Added — low sine sweep with noise burst |
| 2 | `enemy_splat` | slime.gd:104 | Added — wet noise decay |
| 3 | `enemy_lunge` | corrupted_rat.gd:103 | Added — aggressive whoosh |
| 4 | `glitch_teleport` | glitch_wolf.gd:101, tutorial_knight_boss:404, admin_enforcer.gd:56 | Added — glitch crackle with distortion |
| 5 | `enemy_pounce` | glitch_wolf.gd:141 | Added — predatory leap burst |
| 6 | `enemy_attack` | corrupted_guard.gd:117 | Added — metallic swing |
| 7 | `shield_block` | corrupted_guard.gd:135 | Added — metallic clang with harmonics |
| 8 | `shield_hit` | tutorial_knight_boss:387 | Added — shield impact |
| 9 | `projectile_fire` | data_sprite.gd:123 | Added — bolt launch chirp |
| 10 | `wraith_phase` | shadow_wraith.gd:101 | Added — ethereal fade-out with vibrato |
| 11 | `wraith_materialize` | shadow_wraith.gd:116 | Added — swell emergence |
| 12 | `wraith_death` | shadow_wraith.gd:143 | Added — multi-layer ethereal dissipation |
| 13 | `ground_slam` | clockwork_soldier.gd:108 | Added — heavy impact with distortion |
| 14 | `heavy_fall` | clockwork_soldier.gd:144 | Added — low thud with noise |
| 15 | `enforcer_death` | administrator_enforcer.gd:87 | Added — glitch-noise death burst |
| 16 | `counter_hit` | combat_effects.gd (apply_counter_hit_effects) | Added — sharp feedback with harmonics |
| 17 | `dodge_perfect` | combat_effects.gd (apply_perfect_dodge_effects) | Added — quick pluck chirp |
| 18 | `multi_kill` | combat_effects.gd (_check_multi_kill) | Added — ascending celebration tone |

**Location**: sfx_manager.gd lines 735-850 (new `ENEMY-SPECIFIC COMBAT SFX` and `COMBAT FEEDBACK SFX` sections)

### B. Missing SFX Call Sites — 2 FIXED ✅

| Action | File | Issue | Fix |
|--------|------|-------|-----|
| Charged Nail Art release | player_combat.gd `_perform_charged_attack()` | No SFX on release — silent power attack | Added `_sfx("charged_release")` |
| Howling Wraiths cast | player_combat.gd `_cast_howling_wraiths()` | No `spell_cast` SFX (other 2 spells had it) | Added `_sfx("spell_cast")` |

### C. Pitch Variation on Repeated Sounds — 4 FIXED ✅

Repeated identical SFX create "machine gun" monotony. Added random pitch offset to these high-frequency calls:

| SFX | File | Old | New | Reason |
|-----|------|-----|-----|--------|
| `enemy_hurt` | enemy_base.gd `take_damage()` | `_sfx("enemy_hurt")` | `_sfx("enemy_hurt", 0.15)` | ±15% pitch on every hit |
| `enemy_death` | enemy_base.gd `die()` | `_sfx("enemy_death")` | `_sfx("enemy_death", 0.1)` | ±10% per enemy death |
| `player_hurt` | player_combat.gd `take_damage()` | `_sfx("player_hurt")` | `_sfx("player_hurt", 0.1)` | ±10% on player hits |
| `sword_hit`/`heavy_hit` | combat_effects.gd `apply_hit_effects()` | `_play_sfx(...)` | `_play_sfx(..., 0.12)` | ±12% on combat hit feedback |

Also updated `_play_sfx()` signature in combat_effects.gd to accept an optional `variation` parameter.

### D. Boss SFX Coverage — Noted (No Change)

| Boss | Has Unique SFX | Notes |
|------|---------------|-------|
| Tutorial Knight | ✅ 8 calls | `boss_roar`, `sword_swing`, `heavy_windup`, `sword_slam`, `dash`, `shield_hit`, `glitch_teleport`, `enemy_death` — excellent coverage |
| Clockwork Automaton | ⚠️ 1 call | Only `boss_roar` — inherits base class `sword_swing` and `enemy_hurt`/`enemy_death`. Relies on base class. Acceptable but could use gear/steam SFX in future. |
| Data Wraith | ⚠️ 0 calls | Fully relies on enemy_base.gd inherited SFX. **Recommend** adding `wraith_phase`/`wraith_materialize` calls in future pass. |
| Administrator Proxy | ⚠️ 0 calls | Fully relies on enemy_base.gd inherited SFX. **Recommend** adding `glitch_teleport`, `boss_roar` calls in future pass. |

### E. SFX Coverage Summary

**Before**: 127 SFX definitions, 18 orphan call sites (silent)  
**After**: 145 SFX definitions, 0 orphan call sites ✅

---

## PASS 33: COMBAT BALANCE

### A. Hits-to-Kill Analysis (Base Attack = 15)

Player attack scales: `15 + (level-1) × 3`. Combo steps: ×1.0 → ×1.25 → ×1.5.

| Enemy | HP | Armor | At Lv1 (15 dmg) | At Intended Lv | Intent Lv | Hits@IntLv | Verdict |
|-------|-----|-------|-----------------|----------------|-----------|------------|---------|
| Slime | 30 | 0 | 2 hits | 2 hits | 1 | 2 | ✅ Fodder |
| Corrupted Rat | 25 | 0 | 2 hits | 2 hits | 1 | 2 | ✅ Fast fodder |
| Glitch Wolf | 40 | 0 | 3 hits | 2-3 hits | 2 | 2 | ✅ Quick threat |
| Data Sprite | 35 | 0 | 3 hits | 2 hits | 2 | 2 | ✅ Evasive |
| Corrupted Guard | 80 | 5 | 8 hits (10/hit) | 5 hits (16/hit) | 3 (Silver) | 5 | ✅ Tanky |
| Shadow Wraith | 65 | 0 | 5 hits + phases | 3-4 hits | 4 (Gold) | 3 | ✅ Phasing adds eff. HP |
| Clockwork Soldier | 120 | ~~10~~ **8** | ~~24~~ **17 hits** | **6 hits** (19/hit) | 5 (Gold) | 6 | ✅ FIXED — was 24 @Lv1 |
| Admin Enforcer | 100 | 0 | 7 hits | 4 hits | 5+ | 4 | ✅ Punishment enemy |

**Fix Applied**: Clockwork Soldier armor reduced from **10 → 8**. At its intended encounter level (5+), this gives 6 clean hits to kill — still beefy, but the Lv1 worst case drops from 24 to a more reasonable 17. Combo scaling and spells further reduce this in practice.

### B. Hits-to-Die Analysis (Player HP)

Player HP scales: `100 + (level-1) × 20`.

| Enemy | Contact Dmg | Special Dmg | Player Lv Encountered | Player HP | Hits to Die | Verdict |
|-------|------------|-------------|----------------------|-----------|------------|---------|
| Slime | 8 | — | 1 | 100 | 12.5 | ✅ Very safe |
| Corrupted Rat | 12 | — | 1 | 100 | 8.3 | ✅ Safe |
| Glitch Wolf | 15 | — | 2 | 120 | 8.0 | ✅ Fair |
| Data Sprite | 8 (12 bolt) | 12 bolt | 2 | 120 | 10.0 | ✅ Ranged pressure |
| Corrupted Guard | 18 | 27 counter | 3 | 140 | 7.8 (5.2 counter) | ✅ Punishes aggression |
| Shadow Wraith | 14 | 5/tick drain | 4 | 160 | 11.4 | ✅ Sustained drain |
| Clockwork Soldier | 22 | 30 slam | 5 | 180 | 8.2 (6.0 slam) | ✅ Telegraphed danger |
| Admin Enforcer | 25 | — | 5+ | 180 | 7.2 | ✅ Punishing but fair |

### C. Boss TTK and Survivability

| Boss | HP | Player Lv | Player Dmg | Avg Hits to Kill | Contact Dmg | Hits to Die | Est. Duration |
|------|-----|-----------|-----------|-----------------|-------------|-------------|---------------|
| Tutorial Knight | 250 | 3-5 | 21-27 | 10-12 + 4 phases | 15 | 9-12 | 2-4 min ✅ |
| Data Wraith | 200 | 4-5 | 24-27 | 8-10 + 2 phases | 35 | 4-6 | 1.5-3 min ✅ |
| Clockwork Automaton | 320 | 5-7 | 27-33 | 10-12 + 3 phases | 35→50 | 4-5 | 3-5 min ✅ |
| Administrator Proxy | 500 | 8-10 | 36-42 | 12-14 + 4 phases | 50→60 | 4-5 | 4-6 min ✅ |

**Verdict**: Boss durations are well-calibrated for an action game. The Tutorial Knight is appropriately easy for a first boss; the Administrator Proxy is demanding but survivable with mastery.

### D. Spell Damage Economy

| Spell | Damage | Soul Cost | Hits Equivalent | DPS vs Basic Attack |
|-------|--------|-----------|-----------------|---------------------|
| Vengeful Spirit | 45 | 33 (3 hits) | 3.0 basic hits | 150% efficiency — correct incentive to land hits first |
| Desolate Dive | 30-60 (falloff) | 33 | 2-4 hits | AoE compensates — fair |
| Howling Wraiths | 25-50 (falloff) | 33 | 1.7-3.3 hits | Upward AoE niche — fair |
| Focus Heal | 30 HP | 33 | — | 0.85s channel risk = balanced |

**No issues found.** Soul economy is well-balanced: 3 hits to earn a spell cast (11 soul/hit, 33 cost), rewarding aggressive play.

### E. DDA Tuning — 1 FIX ✅

**Current system review**:
- Window: 120 seconds, halving decay → adapts in 2-4 min ✅
- Difficulty multiplier: score [20, 85] → [0.75, 1.25] ✅
- Enemy telegraph: scaled by `1/difficulty_mult` → struggling = 33% slower telegraphs ✅
- 3 hits ≈ 1 death weighting ✅

**Fix Applied**: `get_player_dda_bonus()` max bonus increased from **1.25× → 1.35×** at floor score.

**Rationale**: At DDA score 20 (severely struggling), the old 25% damage/soul/heal boost wasn't enough to close the difficulty gap for new players. A 35% boost gives struggling players ~1 fewer hit to kill each enemy, making the safety net more meaningful without trivializing combat for average players (who sit at 50-70 and get 0-15% boost).

| DDA Score | Old Bonus | New Bonus | Effect |
|-----------|-----------|-----------|--------|
| 20 (floor) | 1.25× | **1.35×** | Struggling players deal 35% more damage |
| 40 | 1.125× | 1.175× | Minor help |
| 50 | 1.0625× | 1.0875× | Minimal |
| 60+ | 1.0× | 1.0× | No change for competent players |

### F. Arena Tier Balance

| Tier | Enemies | Req Lv | Waves | Reward XP | Reward Gold | Balance |
|------|---------|--------|-------|-----------|-------------|---------|
| Bronze | Rat + Wolf | 1 | 3 | 50 | 30 | ✅ ~50% of Lv2 threshold |
| Silver | Guard + Sprite | 3 | 4 | 100 | 60 | ✅ Good mid-game XP |
| Gold | Soldier + Wraith | 5 | 5 | 200 | 120 | ✅ Strong reward for difficulty |
| Platinum | Soldier + Wraith + Guard | 7 | 5 | 400 | 250 | ✅ End-game challenge |

Streak multiplier caps at 2.5× (10+ wins) — multiplicative with base rewards. A 10-streak Platinum run yields 1000 XP / 625 gold — appropriate for high-skill farming.

### G. Charm Balance Review

| Charm | Effect | Impact on Balance |
|-------|--------|-------------------|
| extended_parry | +40% parry window (0.18→0.25s) | ✅ Generous but not broken — skill still required |
| soul_hoarder | +50% soul gain, -20% cost | ⚠️ Strong — effectively 1.875× soul efficiency. Borderline but acceptable as earned upgrade |
| corruption_resist | -40% corruption gain | ✅ Quality of life, no combat impact |
| pogo_master | +80% pogo damage, +30% bounce | ✅ High skill reward — pogo is inherently risky |
| dash_master | -50% cooldown + 10 dmg on dash-through | ✅ Defensive + small offensive bonus |
| thorns | 15 reflect damage | ✅ Passive — 1 basic hit equivalent per hit taken |

**No changes needed.** Charm effects are individually significant but not build-defining, matching the intended Hollow Knight influence.

---

## FILES MODIFIED

| File | Changes |
|------|---------|
| [scripts/sfx_manager.gd](scripts/sfx_manager.gd) | +18 SFX definitions (enemy_hop, enemy_splat, enemy_lunge, glitch_teleport, enemy_pounce, enemy_attack, shield_block, shield_hit, projectile_fire, wraith_phase, wraith_materialize, wraith_death, ground_slam, heavy_fall, enforcer_death, counter_hit, dodge_perfect, multi_kill) |
| [scripts/combat/enemy_base.gd](scripts/combat/enemy_base.gd) | Pitch variation: enemy_hurt ±15%, enemy_death ±10% |
| [scripts/combat/player_combat.gd](scripts/combat/player_combat.gd) | Added `_sfx("charged_release")` to charged attack, `_sfx("spell_cast")` to Howling Wraiths, pitch variation on player_hurt ±10% |
| [scripts/combat_effects.gd](scripts/combat_effects.gd) | Updated `_play_sfx()` to accept variation parameter, added ±12% variation to hit SFX, ±10% to death SFX |
| [scripts/combat/enemies/clockwork_soldier.gd](scripts/combat/enemies/clockwork_soldier.gd) | Armor reduced 10 → 8 |
| [scripts/game_manager.gd](scripts/game_manager.gd) | DDA player bonus max raised 1.25× → 1.35× |

## REMAINING RECOMMENDATIONS (Future Passes)

1. **Data Wraith Boss** and **Administrator Proxy Boss** have zero unique `_sfx()` calls — they rely entirely on enemy_base.gd's inherited `enemy_hurt`/`enemy_death`. Adding boss-specific attack SFX would greatly improve fight identity.
2. **Clockwork Automaton Boss** only calls `boss_roar`. Consider adding `gear_grind`, `ground_slam` for its attacks.
3. **Wall slide** has no continuous SFX. The `wall_slide` SFX definition exists but is never called during the `is_wall_sliding` state in player_combat.gd.
4. **Footstep SFX** during exploration scenes — no calls found outside movement code. Consider adding surface-based footstep calls in exploration scripts.
5. **Environmental ambient SFX** (water, wind, machinery) — definitions exist but scene integration depends on level design (not auditable from scripts alone).
