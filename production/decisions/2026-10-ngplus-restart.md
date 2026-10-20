# Decision memo: NG+ started after a restart carries nothing

**Status**: Decided — option B, approved by the user 2026-10-20; implementation not started
**Date**: 2026-10-20 · **Sprint**: 001 (Y1-P0 Stabilize) · **Branch**: fix/phase0-playthrough-blockers
**Related**: Y1-P0-T07 (`story-t07-ngplus-buffs.md`, "Out of scope: NG+ after a restart"), decision 6A
(`2026-10-audit-decisions.md` §6), Y1-P0-T15 (human playthrough on an exported build)
**Protected areas touched**: NG+ (yes, every option except D), save/load (option B extracts code from `load_game()`;
no save-schema change in A, B or D; C changes the schema)

## Problem

`GameManager.start_new_game_plus()` (`scripts/game_manager.gd` ~531-596) builds the carry-over from the
**in-memory** run: `player_stats` (level, max_hp/max_mp, base_attack/base_defense, half gold), `unlocked_charms`,
`equipped_charms`, `ng_plus_cycle`, `arena_stats`, `stats`, `Inventory.items/equipment`, and the ending route from
`story_flags`. Its only caller is `main_menu.gd:109-112`.

The NG+ button appears when `GameManager.ng_plus_available` is true **or** any save slot's `story_flags.ch10_complete`
is true (`main_menu.gd:76-107`). Only the first case has the finished run in memory.

| Path | How memory looks when NG+ is pressed | Result |
|---|---|---|
| Same session: `ch10_ending.gd` → autosave slot 99 → `main_menu` | Finished run still in memory | Correct carry |
| Quit to menu (`pause_screen.gd:1415-1427` calls `reset_game()`) | Defaults | Level 1, nothing carried |
| Restart the game (fresh process) | Autoload defaults | Level 1, nothing carried |

Secondary symptoms of the same root cause, on the restart path:
- `ng_plus_cycle` restarts at 1, so NG++ (cycle 2+, enemy scale +25% per cycle) is unreachable after a restart, and the
  menu label (`main_menu.gd:100`) always reads "NEW GAME+".
- The ending-route recap shows the fallback "unstable root route" instead of the real ending.

## Reproduction (confirmed 2026-10-20)

Headless probe, isolated `user://` via `tests/run_phase0_tests.ps1 -Script <probe>` (probe kept outside the repo).
Seeded an end-game run (level 24, max_hp 420, max_mp 180, atk 66, def 21, 2000 gold, one charm equipped, 7 potions,
destroy route), loaded the real `ch10_ending.tscn` (it autosaved slot 99: level 24, `ch10_complete` true, scene =
`ch10_ending.tscn`), then:

| | cycle | level | max_hp | max_mp | atk | def | gold | charms | extra items | recap |
|---|---|---|---|---|---|---|---|---|---|---|
| Same-session NG+ | 1 | 24 | 420 | 180 | 66 | 21 | 1000 | 1 | potion ×7 | "SOVEREIGN destroyed" |
| After `reset_game()` (= quit to menu; a restart is the same defaults) | 1 | 1 | 100 | 50 | 15 | 0 | 0 | 0 | none | "unstable root route" |

The menu's slot scan still reports the NG+ button as available after the reset.

## Options

**A. Carry from save data directly.** Give `start_new_game_plus()` an optional save dictionary and read each carried
field from it instead of memory.
- Cost: ~80-120 lines in `game_manager.gd` plus menu and test changes, about half a day.
- Risk: each field is read twice, once from memory and once from save data, with load_game's validation (ITEMS check,
  charm checks) copied. That duplication is the same drift that caused this bug. T07's buff subtraction reads
  `ChoiceConsequences` from memory, so it would also need a save-data version.
- Protected areas: NG+ only. No schema change.

**B. Restore the chosen save into memory (no scene change), then call the unchanged `start_new_game_plus()`.
Recommended.** Move the restore block of `load_game()` (everything from `clear_transient_metas()` through the
corruption signals, before `change_scene`) into a private `_restore_state(data)` with no behaviour change, and have
`load_game()` call it. Add `start_new_game_plus_from_slot(slot)`: `_read_valid_save` (checksum-validated) →
`_restore_state` → `start_new_game_plus()`. The menu picks the `ch10_complete` slot (highest `ng_plus_cycle`, then the
latest timestamp) and shows that slot's cycle in the label.
- Why not plain `load_game()`: the ending autosave points at `ch10_ending.tscn`, so loading it replays the ending and
  the credits, autosaves again and returns to the menu.
- Cost: about 40 lines moved and 25 new, plus a regression test that extends the probe above into
  `tests/integration/playthrough/`. About half a day to a day.
- Benefits: both paths go through the same carry code, including T07's buff subtraction, ITEMS and charm validation,
  lore, cycle and route.
- Risks: `load_game()` is protected and used by every load. The move must be a straight extraction, re-verified by the
  existing phase0 load tests. Restoring on the menu runs side effects (`_apply_corruption_effects`, the
  corruption/glitch signals, `RandomEncounterSystem`, `Achievements.load_save_data`) before `reset_game()` clears
  them. The test must assert that no corruption overlay is left behind and that achievements do not move backwards.
- Protected areas: NG+ and save/load code. No schema change, no change to save contents.

**C. Write a dedicated NG+ carry record at the ending** (a new key or a `user://ngplus_carry.save`).
- Benefit: it survives the first NG+ autosave overwriting slot 99.
- Cost: a save-schema change and migration, about a day or more. That is out of proportion for Phase 0.

**D. Stopgap: only offer NG+ when the finished run is in memory.** Drop the slot scan, or keep it but show the button
disabled with "Load your ending save first".
- Cost: about 5 lines.
- Drawback: NG+ is lost after any restart, which is the normal case for players on an exported build.
- Protected areas: NG+ entry point only.

## Recommendation

Option **B**, after T07 lands. T07 changes the body of `start_new_game_plus()`. B only adds a caller and leaves that
body alone, so the two touch the same file but not the same function. Once both are in, T07's buff fix also applies
to the restart path. Option D is a fallback only if B cannot land before T15.

**Acceptance (proposed):**
1. On the restart path, NG+ from slot data equals same-session NG+ for level, max_hp/max_mp, base atk/def (after T07
   buff subtraction), gold (half), charms, equipped charms, inventory, cycle and recap.
2. The existing phase0 load and save tests pass unchanged.
3. After restart-path NG+: no corruption overlay or encounter-rate leak; Achievements unchanged.
4. The menu label shows the save's cycle + 1.
5. No file written by the NG+ call itself.

## Known, out of scope

- The first autosave of the NG+ run overwrites slot 99, the only slot holding `ch10_complete`. Quitting mid-NG+
  therefore removes the NG+ button until the game is beaten again; the previous file stays as `.bak`. This is
  consistent with `ng_plus_available = false` during NG+, but it should be noted for T15.
- Loading the slot-99 ending save from Load Game replays the ending. This is existing behaviour, not changed here.

## Decision

**2026-10-20 — Option B approved by the user**, including the protected-area change (NG+ entry point and the
extraction of the restore block from `load_game()`; no save-schema change). Sequencing: after Y1-P0-T07 lands.
Implementation is a separate story; not started as of this entry.
