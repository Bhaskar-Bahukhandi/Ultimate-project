# Difficulty Profiles

> **Status**: Draft (revision 3, 2026-11-21: round 2's two AC blockers fixed (AC9's telegraph at the starting assist
> score, AC11's reference press on the window's last frame); no third review round, by user decision. Revision 2,
> after design review round 1 of 2 on 2026-11-21: assist is timing-only and only
> helps (D1); accessibility toggles are a separate axis that marks a clear assisted (D2); telegraph constants, Hell
> owners and unlock rule, the dash row, lowering timing, AC10/AC11 and the settings key fixed)
> **Author**: Claude with the project lead
> **Last Updated**: 2026-11-21
> **Last Verified**: 2026-11-19
> **Implements Pillar**: P6 (five difficulty modes, Beginner to Hell with 2-frame windows) — ROADMAP §12.1; a
> never-cut pillar (`game-concept.md:278`)

## Summary

The difficulty profiles define the five modes (Beginner, Easy, Medium, Hard, Hell) as one table of data: parry window,
dodge i-frames, boss telegraph, enemy damage, healing, assist (DDA), quest-deadline leniency and loot. The GDD maps
each value to the constant in today's code that it replaces, maps the build's four old difficulties onto the five
profiles, and fixes the rules for changing difficulty mid-run and for what each profile's assist may do. Lower
difficulties forgive execution, not attention.

> **Quick reference** — Layer: `Foundation` · Priority: `MVP (Year 1 Phase 2 combat wiring)` · Key deps:
> `time-model.md` (leniency), the combat scripts, GameManager's settings

## Overview

Today the game has four difficulties (Story, Easy, Normal, Hard) wired as two damage multipliers and an always-on
dynamic-difficulty assist; the parry window, the dodge i-frames and the boss telegraphs are single constants that no
difficulty changes. The ROADMAP wants five profiles that change what execution demands (how tight the parry, how long
the i-frames, how readable the telegraph) while every boss still demands pattern literacy. This GDD is the single table
those profiles live in, written so that the combat work in Year 1 Phase 2 can wire each row to the exact constant it
replaces, and so that a player's saved choice from the old four-value setting lands on a sensible profile. It also
settles four rules the code does not follow today: five profiles instead of four, difficulty can only be lowered
mid-run, assist is on only where the profile says, and healing means something in a game that heals with MP.

## Player Fantasy

The player picks how much the game asks of their hands and never has to give up what the game asks of their eyes. A
Beginner player still has to read every boss: "Beginner is still tough because every boss demands pattern literacy.
Lower difficulties forgive execution, not attention." (ROADMAP:476-477; `game-concept.md:203`). A Hell player earns
mastery (`game-concept.md:189`): a 2-frame parry that is fair because it is the same pattern they already learned,
played on a tick that does not move.

- **Easier is wider, never different.** The parry window, the dodge i-frames, the telegraph length and the damage
  change by profile; the boss's patterns, the story and the endings do not. No profile removes a pattern a player has
  to understand (Beginner and Easy get the base patterns, ROADMAP:470).
- **Harder is tighter, and promises fairness.** Hell's 2-frame windows come with a fixed tick, a 4-frame input buffer,
  latency calibration and replay-verified fairness (ROADMAP:478-479). "Hell mode feeling unfair" is a named risk
  (`game-concept.md:287`), so every Hell row below is a number a replay can check.
- **A choice you can walk back.** You can lower the difficulty mid-run but never raise it (ROADMAP:480): a player who
  is stuck is never trapped, and a Hell clear cannot be faked by starting low.
- **Help that tells you it is helping.** Assist (DDA) is on only where a profile says so, and a profile that has it
  says so in the settings, so a Beginner player is not quietly carried and a Hard player is not quietly eased.

What it must not feel like: a hidden rubber band under a mode that promised none, a Hell fight lost to input latency,
or an easy mode that skips the part of the boss that was the point.

## Detailed Design

### Core Rules

1. **Five profiles, one table.** The profile ids are beginner, easy, medium, hard, hell. Every value below lives in one
   DifficultyProfile resource per profile (Year 1 Phase 2, Y1-P2-T12); no gameplay code branches on the profile id.
2. **The table.** Frames are at 60 fps; percents are integers (100 = unchanged), so the time model's `scale()` and the
   checker read them exactly.
3. **Healing (user decision 2026-11-19).** The healing row is *heal casts per rest*: a cap layered on top of the MP
   model (a heal still costs MP and heals as built; `player_combat.gd:109-112`). The count refills at a rest or save
   point; the exact trigger belongs to the heal state (Y1-P2-T08).
4. **Player damage (user decision 2026-11-19).** Profiles scale enemy damage only. The build's `player_dmg` knob is
   removed: scaling the player's damage shortens fights and reduces pattern exposure, against "forgive execution, not
   attention". The assist's player bonus goes with it (D1, below).
5. **Boss patterns.** Beginner and Easy get the base patterns, Medium and Hard add variants, Hell adds a Hell-only
   phase (ROADMAP:470). No profile removes a base pattern, and no essential item is exclusive to Hell (ROADMAP:385).
6. **Leniency** is the time model's deadline leniency, as integer percents (`time-model.md` F4, F5); every main-story
   value must be at least 70 so the Chapter 1 bridge stays repairable: `scale(300) − 180 ≥ 30`.
7. **Per-run difficulty (user decision 2026-11-19).** A new game picks a profile; the save stores it (`difficulty`, one
   of the five ids); loading restores it. The new-game default is stored under a new settings key,
   `gameplay/difficulty_profile` (one of the five ids). The old key `gameplay/difficulty` (an int 0-3) is read only to
   map a legacy save and is never written again, so its old meaning cannot change; lowering mid-run writes the save,
   never the default. The save-schema change is protected: its implementing story (SaveService, Y1-P1-T05) needs the
   user's approval.
8. **Lower-only.** The order is beginner < easy < medium < hard < hell. A run's profile may move down at any time and
   never up (ROADMAP:480). Today the pause screen lists all four values and `set_difficulty` accepts any direction
   (`pause_screen.gd:1266-1273`, `game_manager.gd:2168-2170`); it must list only the run's current profile and lower
   ones, and confirm a lowering first: "You can lower the difficulty again later, but never raise it this run." The
   main-menu selector applies to new games only.
9. **Disclosure.** The new-game selector and the pause screen show, for each profile, whether it has assist and what
   it does ("slows telegraphs a little when you struggle" for gentle, "slows telegraphs when you struggle" for on,
   "no assist" for off), so help is never silent.
10. **Accessibility toggles are a separate axis (user decision D2, 2026-11-21).** `extended_parry_window` (+0.10 s, 6
    frames, `player_combat.gd:1242-1243`, labelled an assist at `game_manager.gd:450`) and `invincibility_mode`
    (`player_combat.gd:1881`) stay available on every profile and stack on it (F2). A run in which either was ever on
    is recorded as "<profile> (assisted)" (the save stores `assisted: true`), so it is never a Hell clear. Their detailed
    rules belong to the combat accessibility spec (Y1-P2-T44).
11. **Scope of `boss_telegraph`.** The row scales every enemy's telegraph, not only bosses' (the base enemy sets one per
    attack, `enemy_base.gd:426-436`).

persistence: per-run

| parameter | beginner | easy | medium | hard | hell | unit | source |
|---|---|---|---|---|---|---|---|
| parry_window | 12 | 9 | 6 | 4 | 2 | frames | ROADMAP:466 |
| dodge_iframes | 18 | 15 | 12 | 10 | 8 | frames | ROADMAP:467 |
| boss_telegraph | 150 | 125 | 100 | 85 | 70 | percent of base | ROADMAP:468 |
| enemy_damage | 60 | 80 | 100 | 130 | 200 | percent | ROADMAP:469 |
| deadline_leniency | 150 | 125 | 100 | 100 | 85 | percent | ROADMAP:473; time-model.md |
| boss_patterns | base | base | variants | variants | variants+hell_phase | set | ROADMAP:470 |
| healing | 5 | 4 | 3 | 2 | 1 | heal casts per rest | ROADMAP:471; decision 2026-11-19 |
| dda | gentle | on | off | off | off | mode | ROADMAP:472 |
| loot | base | base | rare | epic | hell_cosmetics | set | ROADMAP:474 |

**Assist (DDA) per profile (user decision D1, 2026-11-21).** Today DDA is on for every difficulty:
`get_difficulty_multiplier()` remaps the performance score to 75 to 125 percent (`game_manager.gd:1078-1079`), and the
same multiplier also scales enemy max HP, contact damage and movement speed (`enemy_base.gd:1486-1500`), corruption gain
(`game_manager.gd:790`) and soul drain (`enemies/shadow_wraith.gd:38`); `get_player_dda_bonus()` adds up to 125 percent
to the player's damage, healing and Soul (`player_combat.gd:982, 1612, 1772`; `game_manager.gd:977`). Under the
profiles, assist changes **timing only** — telegraph length (F4) and attack cooldown — and **only ever helps**: the
tempo never goes above 100, so a telegraph is never shorter than the profile's. Every other reader of the multiplier
reads 100, and the player bonus is removed (Core Rule 4's reason applies to it). The reader inventory is re-grepped
when Y1-P2-T12 wires it. Proposed values, tuned by playtest:

| dda mode | tempo range (percent) | direction |
|---|---|---|
| gentle | 90 to 100 | slows telegraphs and cooldowns a little when the player struggles |
| on | 75 to 100 | slows them more when the player struggles |
| off | 100 to 100 | none; the score is still tracked for the debug string |

### Constants map (what each profile row replaces)

Paths are under `AethelgardPrototype/`. `token` is a literal substring the cited line contains. `becomes` is a profile
row, or `removed (decision <date>)`; a row marked "(unchanged)" stays as built and the cap is added beside it.

| parameter | constant | file_line | token | current_value | becomes |
|---|---|---|---|---|---|
| parry_window | PARRY_WINDOW | scripts/combat/player_combat.gd:120 | PARRY_WINDOW | 0.18 s (about 11 frames); the extended_parry charm still multiplies it (:1240) | parry_window |
| dodge_iframes | DASH_DURATION | scripts/combat/player_combat.gd:43 | DASH_DURATION | 0.18 s | dodge_iframes (dash length unchanged; F3 derives the tail) |
| dodge_iframes | DASH_IFRAME_TAIL | scripts/combat/player_combat.gd:44 | DASH_IFRAME_TAIL | 0.05 s (total 0.23 s, about 14 frames) | dodge_iframes |
| boss_telegraph | SLASH telegraph | scripts/combat/enemy_base.gd:428 | telegraph_duration = 0.35 | 0.35 s (21 frames; the 0.45 default at :71 is overwritten per attack) | boss_telegraph |
| boss_telegraph | THRUST telegraph | scripts/combat/enemy_base.gd:430 | telegraph_duration = 0.5 | 0.5 s (30 frames) | boss_telegraph |
| boss_telegraph | SLAM telegraph | scripts/combat/enemy_base.gd:432 | telegraph_duration = 0.6 | 0.6 s (36 frames) | boss_telegraph |
| boss_telegraph | CHARGE telegraph | scripts/combat/enemy_base.gd:434 | telegraph_duration = 0.55 | 0.55 s (33 frames) | boss_telegraph |
| boss_telegraph | PROJECTILE telegraph | scripts/combat/enemy_base.gd:436 | telegraph_duration = 0.4 | 0.4 s (24 frames) | boss_telegraph |
| boss_telegraph | telegraph floor and assist divide | scripts/combat/enemy_base.gd:440 | 0.25 | divides by the multiplier, floor 0.25 s | boss_telegraph (floor: min_telegraph_frames; tempo: F7) |
| boss_telegraph | CHARGE_TELEGRAPH (boar) | scripts/combat/enemies/field_boar.gd:16 | CHARGE_TELEGRAPH | 0.6 s | boss_telegraph |
| boss_telegraph | STOMP_TELEGRAPH (guardian) | scripts/combat/enemies/broken_mile_guardian.gd:22 | STOMP_TELEGRAPH | 0.45 s | boss_telegraph |
| boss_telegraph | CHARGE_TELEGRAPH (guardian) | scripts/combat/enemies/broken_mile_guardian.gd:23 | CHARGE_TELEGRAPH | 0.6 s | boss_telegraph |
| enemy_damage | DIFFICULTY_MULTS enemy_dmg | scripts/game_manager.gd:486 | "enemy_dmg" | 0.5 / 0.75 / 1.0 / 1.3 on lines 486-489 | enemy_damage |
| enemy_damage | enemy damage read | scripts/game_manager.gd:2176 | "enemy_dmg" | reads the table above | enemy_damage |
| player damage | DIFFICULTY_MULTS player_dmg | scripts/game_manager.gd:486 | "player_dmg" | 1.5 / 1.25 / 1.0 / 0.85 on lines 486-489 | removed (decision 2026-11-19) |
| player damage | player damage read | scripts/game_manager.gd:2179 | "player_dmg" | reads the table above | removed (decision 2026-11-19) |
| dda | DIFFICULTY_MULTS dda_floor | scripts/game_manager.gd:486 | "dda_floor" | never read | removed (decision 2026-11-19) |
| dda | DIFFICULTY_MULTS dda_ceil | scripts/game_manager.gd:486 | "dda_ceil" | never read | removed (decision 2026-11-19) |
| dda | DDA_SCORE_FLOOR | scripts/game_manager.gd:50 | DDA_SCORE_FLOOR | 20.0 | dda (score bounds stay; limits come from the dda table) |
| dda | DDA_SCORE_CEILING | scripts/game_manager.gd:51 | DDA_SCORE_CEILING | 85.0 | dda (score bounds stay; limits come from the dda table) |
| dda | DDA remap | scripts/game_manager.gd:1079 | remap( | 0.75 to 1.25 | dda |
| dda | DDA consumers | scripts/combat/enemy_base.gd:557 | get_difficulty_multiplier() | attack cooldown divided by the tempo | dda |
| dda | enemy stats from the multiplier | scripts/combat/enemy_base.gd:1486 | dda_mult | scales max HP, contact damage and speed | removed (decision 2026-11-21) |
| dda | corruption from the multiplier | scripts/game_manager.gd:790 | get_difficulty_multiplier() | scales corruption gain | removed (decision 2026-11-21) |
| player bonus | assist damage bonus | scripts/combat/player_combat.gd:982 | get_player_dda_bonus() | up to 1.25 | removed (decision 2026-11-21) |
| player bonus | assist heal bonus | scripts/combat/player_combat.gd:1612 | get_player_dda_bonus() | up to 1.25 | removed (decision 2026-11-21) |
| player bonus | assist Soul bonus | scripts/combat/player_combat.gd:1772 | get_player_dda_bonus() | up to 1.25 | removed (decision 2026-11-21) |
| player bonus | assist Soul bonus | scripts/game_manager.gd:977 | get_player_dda_bonus() | up to 1.25 | removed (decision 2026-11-21) |
| healing | HEAL_COST | scripts/combat/player_combat.gd:109 | HEAL_COST | 20.0 MP | healing (unchanged; the cast cap is added beside it) |
| healing | HEAL_AMOUNT | scripts/combat/player_combat.gd:111 | HEAL_AMOUNT | 30.0 HP | healing (unchanged) |
| healing | MP_REGEN_PER_SEC | scripts/combat/player_combat.gd:110 | MP_REGEN_PER_SEC | 2.0 | healing (unchanged) |

Other `get_difficulty_multiplier()` readers found by grep on 2026-11-21, for the wiring story (which re-greps):
`enemy_base.gd:439`, `:1473`; `field_boar.gd:120`, `:253`; `broken_mile_guardian.gd:101`, `:200`;
`enemies/shadow_wraith.gd:38` (soul drain: reads 100 under D1); `game_manager.gd:1097`, `:1205` (debug string and the
`difficulty_adjusted` signal). Boss and hazard telegraphs (`sovereign_boss.gd`, `tutorial_knight_boss_enemy.gd`,
`late_game_hazard_trial.gd`) are mapped by the wiring story.

### Old-setting mapping (by name, user decision 2026-11-19)

| old_value | old_name | profile | what changes for the player |
|---|---|---|---|
| 0 | STORY | beginner | enemy damage 50 to 60 percent; parry about 11 to 12 frames |
| 1 | EASY | easy | enemy damage 75 to 80 percent; parry about 11 to 9 frames |
| 2 | NORMAL | medium | enemy damage unchanged; parry about 11 to 6 frames (nearly halved); dodge i-frames about 14 to 12 |
| 3 | HARD | hard | enemy damage unchanged at 130 percent; parry about 11 to 4 frames; player damage 85 percent to 100 |
| other/missing | — | medium | the build's own default is NORMAL (`game_manager.gd:484`) |

Hell has no old value. On the first load after the change, a legacy save with no `difficulty` field takes the profile
mapped from the global setting once, stores it, and the game says so once.

### States and Transitions

| State | Entry condition | Exit condition | Behavior |
|---|---|---|---|
| profile P | a new game picks P; a load restores P; a legacy save maps once | the player lowers to Q below P | all rows read from P |
| lowered to Q | the player confirms Q below P in the pause screen | the player lowers again | parry, i-frames, damage and assist read Q from the next frame; telegraphs from the next attack; boss patterns from the next phase; heal casts from the next rest; started deadlines keep theirs (Edge Cases 2-4); P is never available again in this run |

### Hell prerequisites (ROADMAP:478-479)

| prerequisite | needed because | owner |
|---|---|---|
| fixed tick | a 2-frame window must not depend on frame rate | Y1-P2-T02 (the fixed-tick combat clock, `production/plan/2027/2027-02.md:15`) |
| 4-frame input buffer | jump, attack, parry and dash must survive a 4-frame early press | Y1-P2-T03 |
| latency calibration in options | input lag is part of a 33 ms window | Y1-P2-T22, Block A "Latency calibration and measurement" (`production/plan/2027/2027-03.md:1638`) |
| replay-verified fairness | a perfect run must win and a run one frame late must lose (ROADMAP:384-385) | Y1-P2-T22 |

Hell unlocks when Y1-P2-T02, T03 and T22 are done (T22 includes the latency offset); the same condition applies in
Edge Case 9 and AC10.

### Pause-screen change

| item | today | required |
|---|---|---|
| pause-screen selector (`pause_screen.gd:1266-1273`) | lists all four old values; any direction | lists the run's profile and lower ones only |
| `GameManager.set_difficulty` (`game_manager.gd:2168-2170`) | accepts any value | rejects a profile above the run's |
| main-menu selector (`main_menu.gd:1187`) | sets the global value | picks the new game's profile; becomes the default |
| `user://game_settings.cfg` (`game_manager.gd:2181-2193`) | the difficulty store (`gameplay/difficulty`, int) | the new-game default only, under `gameplay/difficulty_profile`; the old key is read for legacy mapping and never written |

## Formulas

All values are integers. `scale(x, p) = (x × p + 50) div 100` (x × p percent, rounded half up; the time model's
`scale()`). A profile value is read as `P.row`.

**F1 frames to time.** `seconds = frames / 60`; `ms = frames × 1000 / 60`. Range 1 to 60 frames. Example: Medium parry
6 frames = 0.1 s = 100 ms; Hell 2 frames = 33 ms.

**F2 parry window.** `window_frames = P.parry_window`; with the extended_parry charm multiplier c (1.0 without the
charm, 1.4 with it; `player_combat.gd:1240`, `game_manager.gd:69`) and the accessibility toggle a (6 frames when
`extended_parry_window` is on, else 0; `player_combat.gd:1242-1243`): `window_frames' = floor(window_frames × c + 0.5)
+ a`. Range 2 to 12 from the profile; up to 23 with both. Examples: Hard 4, no charm, no toggle → 4 (67 ms); Hard with
the charm → 6, the same as bare Medium; Hell with the toggle → 8, a run recorded "hell (assisted)" (Core Rule 10).

**F3 dodge i-frames.** `iframes = P.dodge_iframes`, counted from the dash's first frame. `dash_frames =
round(DASH_DURATION × 60) = 11`; `tail = max(0, iframes − dash_frames)`. Examples: Beginner 18 → tail 7; Medium 12 →
tail 1; Hell 8 → the i-frames end on dash frame 8 of 11 (tail 0).

**F4 telegraph.** `base = round(base_s × 60)`; `t = scale(base, P.boss_telegraph)`; with the assist tempo `tempo`
(percent, F7): `t' = max(min_telegraph_frames, (t × 100 + tempo div 2) div tempo)`. Example, the boar charge (0.6 s =
36 frames): Beginner 54, Easy 45, Medium 36, Hard 31, Hell 25 frames. Assist only lengthens it: Easy (on) at tempo 75
gives (4500 + 37) div 75 = 60 frames; no tempo is above 100 (F7). `min_telegraph_frames` 15 (0.25 s, today's floor,
`enemy_base.gd:440`, `field_boar.gd:120`).

**F5 enemy damage.** `dmg = scale(base_dmg, P.enemy_damage)`. Range 60 to 200 percent. Example, a 10-damage hit: 6 / 8
/ 10 / 13 / 20.

**F6 heal casts.** At each rest `casts = P.healing`. A heal is allowed iff `casts > 0` and `mp >= HEAL_COST` (20); it
spends 1 cast and 20 MP and heals `HEAL_AMOUNT` (30), with no assist bonus (D1). Most healing between rests =
`casts × 30`: 150 / 120 / 90 / 60 / 30 HP.

**F7 assist clamp.** `raw = 75 + (clamp(score, 20, 85) − 20) × 50 / 65` (today's remap, `game_manager.gd:1079`, in
percent); `tempo = clamp(round(raw), lo, hi)` with (lo, hi) from the dda table: gentle (90, 100), on (75, 100), off
(100, 100). There is no player bonus (D1). Examples: score 85 → raw 125 → 100 in every mode; score 50 → raw 98.08 → 98
gentle and on, 100 off; score 20 → raw 75 → gentle 90, on 75, off 100.

**F8 bridge margin (time-model F5).** For each profile, `scale(300, P.deadline_leniency) − 180 ≥ 30`: 270 / 195 / 120
/ 120 / 75. Leniency floor 70 (slack exactly 30).

**F9 lower-only.** `rank` beginner 0, easy 1, medium 2, hard 3, hell 4. A change from the run's profile R to Q is
allowed iff `rank(Q) ≤ rank(R)`; Q = R is a no-op. Example: a Hard run may move to Medium, Easy or Beginner, never to
Hell.

## Edge Cases

1. **Hell leniency vs the bridge (the plan's edge case).** F8 gives slack 75 at Hell's 85, so the Chapter 1 bridge
   stays repairable; the floor is 70. No profile may set a main-story leniency below 70; the checker evaluates F8 for
   all five.
2. **Lowering mid-fight.** Parry, i-frames, damage and assist read the new profile from the next frame. A telegraph is
   set once per attack (`enemy_base.gd:438-440`), so the new length applies from the next attack. The boss pattern
   set is read at the start of each phase, so a lowered player meets the new set at the next phase.
3. **Lowering and heal casts.** Casts left stay as they are; the new profile's count applies from the next rest.
   Lowering never refills.
4. **Lowering during a timed quest.** A started deadline keeps the `deadline_min` it was given (time-model Edge Case
   13); the new leniency applies to quests started afterwards.
5. **Raising.** Refused by F9 everywhere: the pause screen does not offer it and `set_difficulty` rejects it. A raise
   needs a new game.
6. **Legacy save (no `difficulty` field).** On the first load it takes the profile mapped from the global setting
   (old-setting mapping), stores it in the save and says so once; later loads read the save.
7. **Bad global setting.** A missing, non-integer or out-of-range old key (anything but 0-3) maps a legacy save to
   medium (today it is clamped to NORMAL, `game_manager.gd:2190-2193`). The new key holds a profile id, never an int,
   so a Hell default can never be read as an old value.
8. **NG+.** A new cycle continues the run: it keeps the run's profile and the lower-only rule. Picking a higher profile
   needs a new game. NG+ also multiplies enemy stats by 1 + 0.25 per cycle (`game_manager.gd:632-634`,
   `enemy_base.gd:180`); that stacks with the profile's enemy damage (Hell in cycle 2: 200 × 1.5 = 300 percent).
9. **Hell before its prerequisites exist.** Hell is not selectable until Y1-P2-T02, T03 and T22 are done (T22 includes
   the latency offset); until then the new-game selector shows it locked with that reason. The pause screen never
   lists it unless the run is already Hell.
10. **Charm and accessibility toggle on Hell.** The extended_parry charm multiplies the window on every profile (F2),
    Hell included; it is a player choice, not an assist, and a run with it can still be a Hell clear. The accessibility
    toggle adds 6 frames on every profile; a run that used it is "(assisted)" (Core Rule 10).
11. **Telegraph floor.** No telegraph falls below `min_telegraph_frames` (15, 0.25 s): a 20-frame base (0.33 s) at
    Hell's 70 percent scales to 14 and is held at 15.
12. **Assist mode change.** Lowering into a profile with gentle or on uses the score tracked so far; moving to off
    applies 100 at once.
13. **Heal with no casts left.** The heal is refused with a message; MP is not spent.
14. **Clears and loot.** Loot follows the profile at drop time; a credits clear counts for the profile the run holds at
    the credits, marked "(assisted)" if an accessibility toggle was ever on, so neither a run lowered from Hell nor an
    assisted one is a Hell clear.

## Dependencies

| system | direction | what flows | status / owner |
|---|---|---|---|
| `time-model.md` | it reads this | `deadline_leniency` as integer percents; this GDD keeps every main-story value ≥ 70 (F8) | exists; it already names this GDD as its leniency source |
| Player combat (`player_combat.gd`) | it reads this | `parry_window`, `dodge_iframes`, healing casts | wiring Y1-P2-T12 (profiles), Y1-P2-T08 (heal state) |
| Enemies (`enemy_base.gd`, `field_boar.gd`, `broken_mile_guardian.gd`, `enemies/shadow_wraith.gd`) | it reads this | `boss_telegraph`, `enemy_damage`, the assist tempo (F4, F5, F7) | Y1-P2-T10, T11, T12 |
| GameManager (`game_manager.gd`) | this replaces part of it | the Difficulty enum, `DIFFICULTY_MULTS`, the DDA remap and the settings file become the profile table and the dda modes | Y1-P2-T12 |
| SaveService (Y1-P1-T05) | it stores this | the run's `difficulty` id; a legacy save maps once (Edge Case 6) | not built; save schema is protected: needs the user's approval |
| Pause screen and main menu (`pause_screen.gd:1266-1273`, `main_menu.gd:1187`) | they show this | the lower-only selector (F9) and the new-game pick | Y1-P2-T12 |
| Hell prerequisites | this needs them | fixed tick, input buffer, replay validation, latency calibration | Y1-P2-T02, T03, T22 (T22 owns the latency offset) |
| Boss and loot content | they read this | `boss_patterns` and `loot` sets | BossDef Y1-P2-T11; loot unowned |
| Combat accessibility spec (Y1-P2-T44) | it reads this | the toggles' stacking and the "(assisted)" record (Core Rule 10) | not written |
| Plan note | — | Y1-P2-T12's plan step says "migration default 'medium'"; this GDD's newer user decision maps legacy saves by name (Core Rule 7) | the plan follows this GDD when T12 is built |

## Tuning Knobs

Defaults are beginner / easy / medium / hard / hell. Each safe range holds with the other knobs at their defaults;
within a row the five values must keep their order (falling or rising as noted).

| knob | default | safe range (B / E / M / H / Hell) | affects | rule |
|---|---|---|---|---|
| parry_window (frames) | 12 / 9 / 6 / 4 / 2 | 10-15 / 7-11 / 5-8 / 3-5 / 2-3 | parry precision | falls; Hell ≥ 2 |
| dodge_iframes (frames) | 18 / 15 / 12 / 10 / 8 | 15-21 / 12-17 / 10-14 / 8-12 / 6-10 | dodge forgiveness | falls; ≥ 6 |
| boss_telegraph (percent) | 150 / 125 / 100 / 85 / 70 | 130-170 / 110-140 / 100 / 80-95 / 65-80 | time to read an attack | falls; medium is the base |
| enemy_damage (percent) | 60 / 80 / 100 / 130 / 200 | 50-80 / 70-90 / 100 / 115-150 / 150-250 | punishment per hit | rises; medium is the base |
| deadline_leniency (percent) | 150 / 125 / 100 / 100 / 85 | 125-175 / 110-150 / 100 / 100 / 70-100 | quest deadline time | does not rise; ≥ 70 (F8) |
| healing (casts per rest) | 5 / 4 / 3 / 2 / 1 | 4-6 / 3-5 / 2-4 / 1-3 / 1-2 | recovery between rests | does not rise; ≥ 1 |
| gentle tempo floor (percent) | 90 | 85-95 | how much gentle can lengthen telegraphs and cooldowns | ≤ 100; above on's floor |
| on tempo floor (percent) | 75 | 70-90 | how much on can lengthen them | ≤ 100 |
| min_telegraph_frames | 15 | 12-18 | the shortest readable telegraph | applies after F4 |

Fixed by design: 60 frames per second, the five profile ids and their order, medium as the 100 base. The profile
defaults come from ROADMAP:466-474; the assist and floor defaults are this GDD's proposals. All are tuned by playtest.

### Balance-check notes (2026-11-21)

`/balance-check` (report: `design/balance/balance-check-difficulty-profiles-2026-11-21.md`, copied to
`production/qa/evidence/2026-11-difficulty/balance-check.md`) returned CONCERNS: no outliers (all 30 numeric values
inside their safe ranges); time-to-kill not assessed (no enemy data yet). Dispositions (user decision 2026-11-21):

- **Hell's healing budget falls hardest** (one rest's healing covers 1.5 Hell hits, against 4.6 on Hard): kept on
  purpose. Hell trades recovery for mastery; the 1-2 safe range lets playtest raise it to 2 if Y1-P2-T22's sessions
  show the step is unfair.
- **Easy gives no loot reward over Beginner** (both `base`): accepted as ROADMAP:474 states. Easy is chosen for its
  challenge, not its rewards.

## Acceptance Criteria

Now = checked by `production/qa/evidence/2026-11-difficulty/check_difficulty_profiles.py`. Y1-P2 = a test in the
story that wires the profiles (Y1-P2-T12 unless named).

| id | type | criterion | verified by | when |
|---|---|---|---|---|
| AC1 | Config | The profile table has the 9 rows (parry_window, dodge_iframes, boss_telegraph, enemy_damage, deadline_leniency, boss_patterns, healing, dda, loot) and the 5 profile columns, with no empty cell. | checker | Now |
| AC2 | Config | Every deadline_leniency value is an integer ≥ 70, and `scale(300, L) − 180 ≥ 30` for each profile (F8: 270 / 195 / 120 / 120 / 75). | checker | Now |
| AC3 | Config | Every constants-map row's token is on its cited line, and every `becomes` starts with a profile row or `removed (`. | checker | Now |
| AC4 | Config | The old-setting mapping maps 0 → beginner, 1 → easy, 2 → medium, 3 → hard and `other/missing` → medium, no row to hell, and the GDD has the line `persistence: per-run`. | checker | Now |
| AC5 | Config | `balance-check.md` is in the evidence folder with a Health line, and every outlier it names has a disposition in this GDD. | checker (file) and review | Now |
| AC6 | Logic | F2-F7 return their worked examples: parry Hard 4, Hard with the charm 6, Hell with the toggle 8; dodge tail 7 / 1 / 0 for Beginner / Medium / Hell; boar telegraph 54 / 45 / 36 / 31 / 25 frames and 60 for Easy at tempo 75; a 10-damage hit 6 / 8 / 10 / 13 / 20; with healing n and enough MP, n heals of 30 succeed and the next is refused with MP unchanged; the assist tempo at score 85 is 100 in every mode, at score 50 is 98 / 98 / 100 and at score 20 is 90 / 75 / 100 (gentle / on / off). | unit test | Y1-P2 |
| AC7 | Logic | F9: from each profile the allowed targets are exactly the equal-or-lower ranks; `set_difficulty` rejects a raise. | unit test | Y1-P2 |
| AC8 | Integration | A new game at hard saves `difficulty` hard and a load restores it; a legacy save with no field and global setting 2 loads as medium, stores it and shows the notice once; global setting 7 loads as medium. | integration test | Y1-P1-T05 with Y1-P2 |
| AC9 | Integration | Lowering from hard to easy mid-fight changes the parry window from 4 to 9 frames on the next frame, the next telegraph (boar charge 31 → 46 frames at the starting assist score of 50, where Easy's tempo is 98 by F7; 45 frames at a score of 52 or more, tempo 100) and the next hit (10-damage hit 13 → 8); the boss pattern set changes at the next phase; heal casts left are not refilled. | integration test | Y1-P2 |
| AC10 | UI | (a) The pause screen on a hard run lists hard, medium, easy and beginner and nothing above, and asks to confirm a lowering; (b) the new-game selector shows Hell locked with its reason until Y1-P2-T02, T03 and T22 are done, and shows each profile's assist line (Core Rule 9). A retained screenshot of each state. | manual, screenshots | Y1-P2 |
| AC11 | Integration | On Hell, with both accessibility toggles off, a recorded run whose every parry is pressed on the last frame of its 2-frame window wins, and the same run with each of those presses one frame later (outside the window) loses (ROADMAP:384-385). | input-replay test | Y1-P2-T22 |
| AC12 | Logic | With assist off the tempo is 100 for every score; with gentle or on it is never above 100; enemy HP, contact damage, speed, corruption, soul drain and the player's damage, healing and Soul read 100 in every mode; a run with an accessibility toggle ever on is recorded "(assisted)". | unit test | Y1-P2 |
