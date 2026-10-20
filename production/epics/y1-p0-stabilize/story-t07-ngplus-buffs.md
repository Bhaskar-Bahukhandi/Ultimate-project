# Story T07: Stop NG+ from stacking choice buffs every cycle

> **Epic**: Y1-P0 Stabilize (Sprint 001)
> **Task ID**: Y1-P0-T07 (`production/plan/_source/Y1-P0.json#Y1-P0-T07`)
> **Status**: In Progress
> **Layer**: Feature
> **Type**: Integration
> **Estimate**: 1 day
> **Manifest Version**: N/A — `docs/architecture/control-manifest.md` does not exist
> **Last Updated**: 2026-10-20

## Context

**GDD**: none exists for NG+. **Design source of record**: `production/decisions/2026-10-audit-decisions.md`
§6 (decision 6A: "At NG+ start, subtract the finishing run's active buff mods from the carried stats; no
save-format change; already-stacked saves are left as they are"), refined by the user's T07 decisions below.
**Requirement**: N/A — no TR-ID registered (`docs/architecture/tr-registry.yaml` holds no requirements).

**ADR Governing Implementation**: N/A — a local fix in `GameManager.start_new_game_plus()` using the existing
`ChoiceConsequences` record; no architectural decision is made.
**ADR Decision Summary**: N/A
**ADR Version**: N/A

**Engine**: Godot 4.6 (4.6.3 at `C:/Godot`) | **Risk**: HIGH (`docs/engine-reference/godot/VERSION.md`, 4.6 row)
**Engine Notes**: no post-cutoff API expected.

**Control Manifest Rules**: NOT ASSESSED — no control manifest.

**Performance**: no impact; runs once when NG+ starts.

**AGENTS.md protected areas** (explicit user approval, 2026-10-20): NG+ is protected. Approved:
`start_new_game_plus()` (`scripts/game_manager.gd` ~531-596) subtracts the finishing run's choice-buff totals
from the carried `base_attack`, `base_defense` and `max_hp` before `reset_game()`. No save-format change; no
other NG+ carry behaviour changes; story flags, combat, saves, Source Key untouched.

### Audit facts (2026-10-20, read-only; line numbers approximate)

- Buffs apply when a story flag in `ChoiceConsequences.CHOICE_BUFFS` is set to true
  (`choice_consequences.gd` `_on_story_flag_updated` ~172-199 → `apply_choice_buff` ~267-287 → `_apply_stat_mods`
  ~205-230, which writes `attack`+`base_attack`, `defense`+`base_defense`, `max_hp` (clamped ≥1) and adjusts `hp`).
  Clearing a flag (exclusive groups, `set_story_flag` gm ~698-710) calls `remove_choice_buff`, which subtracts.
  A buff cannot be applied twice in one run (id guard); load does not re-apply.
- **The record exists already**: `ChoiceConsequences.active_buffs` (cc ~19) holds every buff applied this run
  and is saved and loaded (`choice_consequences` save key). `get_total_stat_mods()` (cc ~294-301) returns the
  summed `{attack, defense, max_hp, soul_gain_bonus}` as **floats**.
- `start_new_game_plus()` (gm ~531-596) reads level, max_hp/max_mp, base_attack/base_defense, half the gold,
  charms, arena stats, lifetime stats and carried items, calls `reset_game()` (~556, which also clears
  `active_buffs` via `ChoiceConsequences.reset()` and resets every story flag), then restores them. Choosing
  the same options again re-applies the same buffs on top: the stacking bug.
- Level-ups add to the same fields (`_apply_level_up` gm ~974-998); equipment and corruption only recompute
  `attack`/`defense` from `base_*`. So subtracting the buff totals removes only the buff part.
- Per run, with one choice per exclusive group: ATK −3 … +36, DEF 0 … +31, MaxHP −15 … +45. The decision doc's
  "+50 / +35 / +20" is the sum over every option, not a per-run figure.
- `ch1_root_purge_used` (−10 MaxHP) is in no exclusive group and is set together with `ch1_knight_spared` on the
  purge route; `ch1_elara_distrusted` is never set by live content.
- `soul_gain_bonus` is not carried by NG+ (read from `active_buffs`), so it does not stack.
- Only the Chapter 10 ending unlocks NG+ (`ch10_ending.gd` ~14-31 → `main_menu.gd` ~109-112, the single caller);
  the plan's "Chapter 3 ending path" does not exist (`ch3_ending.gd` sets `ng_plus_available = false`).

### User decisions (2026-10-20)

1. **Scope**: choice buffs only (decision 6A). The two Chapter 3 one-off max-HP bonuses
   (`ch3_fractured_wastes.gd` ~269 scavenge +5, ~677 mini-boss +3) also stack; recorded as a follow-up.
2. **NG+ after a restart**: NG+ started from the main menu after quitting or restarting begins from default
   GameManager state and carries nothing (level 1). Separate follow-up task (save/load, protected); not T07.
3. **Approval**: the protected NG+ change above is approved. Old saves that already stacked are left as they are.

2026-10-20, after QL-STORY-READY:
4. **Run and observe**: waived for T07 (it changes carried numbers, not a screen); the numbers are asserted by
   tests and tabulated in the evidence folder, and the Phase 0 exit playthrough (Y1-P0-T15) observes NG+ on a
   real build.

**Known limitation**: `_apply_stat_mods` floors `max_hp` at 1 during the run, so subtracting the full buff total
at NG+ could over-correct only if a run's max_hp were ≤ ~14 with a −15 buff. Real max_hp starts at 100 and only
grows (lowest reachable 85), so this is unreachable through play. T7 pins only the floor contract (injected
max_hp values give 2/1/1/1), not an over-correction reached in a real run.

**Known limitation (code review, 2026-10-20)**: saves older than v1.2 are migrated to `choice_consequences = {}`
(`game_manager.gd:2041`), so loading one calls `ChoiceConsequences.rebuild_from_flags()`. That rebuilds
`active_buffs` from flags and the *current* `CHOICE_BUFFS` table without applying the mods to `player_stats`.
If such a save's stats never received the buffs, the NG+ subtraction removes buffs that were never added
(attack/defense have no floor). Whether any pre-v1.2 save exists is unknown. A guard belongs in
`choice_consequences.gd`, which is out of scope here; recorded as a follow-up with a save -> load -> NG+ test.

---

## Acceptance Criteria

- [ ] AC-1 `start_new_game_plus()` reads `ChoiceConsequences.get_total_stat_mods()` **before** `reset_game()` and
      subtracts `int(total.get("attack", 0))` from the carried `base_attack`, likewise `defense` from
      `base_defense` and `max_hp` from `max_hp` (a missing key counts as 0: the function returns `{}` with no
      buffs and only the keys some buff touched); `max_hp` is then clamped to ≥ 1; after the reset, `attack` and
      `defense` are set from the reduced base values (equipment bonuses re-applied as today); `hp` and `mp` are
      refilled to max; all three carried stats are ints.
- [ ] AC-2 Three simulated NG+ cycles that make the same choices end each run with identical `base_attack`,
      `base_defense` and `max_hp`, and the stats carried into each NG+ equal that run's stats minus its buffs
      (i.e. level growth only); `ChoiceConsequences.active_buffs` is empty after each NG+.
- [ ] AC-3 After `start_new_game_plus()`: `level` and `max_mp` equal their pre-call values; `player_stats.gold`
      and `Inventory.gold` both equal `int(pre_gold * 0.5)` (101 → 50); `unlocked_charms`, `equipped_charms`,
      `arena_stats`, `Inventory.equipment` and `Inventory.items` (plus exactly one extra `glitch_stabilizer`) equal
      their pre-call snapshots; lifetime `stats` equal their snapshot except `stats.death_count == 0`;
      `ng_plus_cycle == pre_cycle + 1` (0 → 1, a preset 5 → 6); `ng_plus_available == false`;
      `story_flags.ng_plus_route_recap_available == true`; `hp == max_hp` and `mp == max_mp`. These fields are
      identical between a run with buffs and a no-buff control run at the same level.
- [ ] AC-4 Route coverage: a kill route, a spare route and a purge route (the spare flags plus the unexclusive
      `ch1_root_purge_used`, −10 max_hp) each round-trip with zero stacking; a run whose **max_hp** buff total is
      negative (`ch2_data_wraith_absorbed` alone: −15 max_hp, +10 attack) gets max_hp back to the pre-buff value;
      after a level-up during the run, the carried `level`, `base_attack`, `base_defense`, `max_hp` and `max_mp`
      equal a no-buff control run that earned the same XP.
- [ ] AC-5 An NG+ with no active buffs leaves `base_attack`, `base_defense` and `max_hp` equal to the run's values.
      The sorted top-level keys of the save JSON written by `GameManager.save_game()` (there is no
      `get_save_data()` on GameManager), and the key set of its `choice_consequences` entry, equal a literal list frozen in the test from HEAD before implementation, and are equal before and
      after an NG+ call; `start_new_game_plus()` writes no file in the isolated `user://` save directory. Old saves
      that already stacked are not modified.
- [ ] AC-6 `tests/unit/ngplus/ngplus_buff_stacking_test.gd` exists and passes, with its `.uid`, and is listed in
      `tests/run_all_tests.ps1` and `.github/workflows/ci.yml` (the layout guard
      `tests/integration/meta/test_layout_test.gd` passes); the full suite passes (baseline recorded first);
      `git diff --check` is clean; a table of each route's before-NG+ / after-NG+ / baseline stats is recorded in
      `production/qa/evidence/2026-10-ngplus/`.

---

## Implementation Notes

- Change only `start_new_game_plus()` in `scripts/game_manager.gd`; use the existing
  `ChoiceConsequences.get_total_stat_mods()` (guard with `has_node("/root/ChoiceConsequences")`). Read it before
  `reset_game()` clears `active_buffs`. Do not change `choice_consequences.gd`, saves or flags.
- Buffs are applied in the tests the real way: `GameManager.set_story_flag(flag, true)` (the
  `story_flag_updated` signal drives `apply_choice_buff`), not by writing stats directly.
- A level-up can be driven through the existing level-up path (e.g. `add_xp` past a threshold) so the test
  proves level growth is untouched.
- Add a short CHANGELOG entry. Commit only with the user's OK, with `Task: Y1-P0-T07` in the body.

---

## Out of Scope

- NG+ started after a restart or quit carrying nothing (follow-up; save/load).
- The two Chapter 3 one-off max-HP bonuses (follow-up).
- Side-quest stat boosts re-granted each cycle (no quest with a stat boost can complete today; recorded in T06).
- Clamping or repairing old saves that already stacked.
- Buff values, exclusive groups, `soul_gain_bonus`, enemy scaling per cycle.

---

## QA Test Cases

*Reviewed by qa-lead (QL-STORY-READY, 2026-10-20: GAPS → cases below adopted). SceneTree `_check` style (T06
precedent), isolated `user://`. Helper `_run(flags, xp)`: `reset_game()` → optional `add_xp(xp)` →
`set_story_flag(f, true)` per flag → snapshot E {base_attack, base_defense, max_hp, attack, defense, hp, max_mp,
level} → `start_new_game_plus()` → snapshot P. Baseline B = DEFAULT_PLAYER_STATS (base_attack 15, base_defense 0,
max_hp 100). Every buff case first asserts E ≠ B (the buff really applied) so a flag typo cannot pass silently.
Watch it fail first: T1–T7 must fail on unfixed HEAD; T8–T9 are characterization cases and must pass on HEAD.*

- **T1 kill route, three cycles (AC-1/AC-2)** — kill flags `ch1_knight_killed`, `ch1_elara_cautious`,
  `ch2_seraphina_rejected`, `ch2_data_wraith_absorbed`, `ch3_lyra_recruited`, `ch3_kaelthas_challenged`; for
  N = 1..3: E_1 == E_2 == E_3 (each ≠ B), P_N == B on base_attack/base_defense/max_hp, `ng_plus_cycle == N`,
  `active_buffs` empty, hp == max_hp and mp == max_mp, and the three stats plus attack/defense/hp are TYPE_INT.
- **T2 spare and purge (AC-4)** — spare flags `ch1_knight_spared`, `ch1_elara_trusted`, `ch2_seraphina_stayed`,
  `ch2_data_wraith_restored`, `ch3_lyra_left_alone`, `ch3_kaelthas_refused`; purge = spare + `ch1_root_purge_used`:
  E_purge.max_hp == E_spare.max_hp − 10; P == B for both.
- **T3 negative max_hp total (AC-4)** — flags [`ch2_data_wraith_absorbed`]: E.max_hp == 85; P.max_hp == 100;
  P.base_attack == 15.
- **T4 level-up (AC-4)** — control run C: `add_xp(X)` with X giving level ≥ 3 (assert as precondition); snapshot
  level, base_attack, base_defense, max_hp, max_mp; buff run with the same X and the kill flags → same level;
  after NG+, P equals C on all five; repeat with the flags set before the XP.
- **T5 exclusive-group flip** — `ch1_knight_killed` then `ch1_knight_spared` in the same run: `active_buffs` holds
  only the spared buff, E reflects only it, P == B; a second pair (`ch2_data_wraith_absorbed` →
  `ch2_data_wraith_restored`).
- **T6 duplicate set** — the same flag set true twice: one `active_buffs` entry; P == B.
- **T7 max_hp floor (AC-1)** — buffs with max_hp total T > 0 (read from `get_total_stat_mods()`); overwrite
  `player_stats.max_hp` with T+2, T+1, T, 1 before NG+: P.max_hp is 2, 1, 1, 1; never ≤ 0; hp == max_hp.
- **T8 carry (AC-3)** — no-buff run at level ≥ 3, gold 101, one charm unlocked and equipped (not `null_cloak`),
  one carried item, a non-default arena_stats value, nonzero lifetime stats with `death_count` 4; NG+ from cycle 0
  and from a preset cycle 5: every AC-3 field holds; repeat with the kill flags: all non-buff fields (and
  `max_mp`) equal the no-buff run. Code review added: armor equipped too (defense == base_defense + 5), and the kill
  and spare runs match the no-buff run on base_attack/base_defense/max_hp/attack/defense after NG+.
- **T9 no buffs and partial keys (AC-5)** — no flags: P == E, nothing errors on `{}`; only `ch1_root_purge_used`:
  totals hold only `max_hp`, attack and defense stay at B; save keys (literal list frozen from HEAD) equal before
  and after NG+; the `user://` save directory listing is unchanged.
- **T10 data guard** — every `attack`/`defense`/`max_hp` value in `ChoiceConsequences.CHOICE_BUFFS` is integral, so
  `int()` truncation is exact. Code review added: no entry modifies `max_mp` (NG+ does not subtract it).
- **T11 soul_gain_bonus** — after NG+ with the kill route, `player_stats` has no `soul_gain_bonus` or it is 0.0.
- **T12 NG+ twice (code review, characterization)** — NG+ straight after NG+ with no run between changes nothing
  but the cycle (P2 == P1 on base_attack/base_defense/max_hp/level).
- **AC-6** — layout guard and full suite pass; `git diff --check` clean; evidence table: route | E (before NG+) |
  P (after) | B.

---

## Test Evidence

**Story Type**: Integration
**Required evidence**: `tests/unit/ngplus/ngplus_buff_stacking_test.gd` passing, with a log and the before/after
numbers in `production/qa/evidence/2026-10-ngplus/`.
**Run result**: N/A — waived by the user (decision 4): carried stat numbers only, no new screen; numbers asserted by tests and tabulated in evidence; Y1-P0-T15 observes NG+ on a real build.

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Y1-P0-T02 (done), Y1-P0-T03 (done; decision 6A). No story files for these by sprint decision;
  status in `production/sprint-status.yaml`.
- Unlocks: Y1-P0-T15 (Phase 0 exit playthrough includes NG+).
