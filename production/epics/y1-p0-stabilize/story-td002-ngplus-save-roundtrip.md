# Story TD-002: Test that a v1.2 save survives save → load → NG+ without stacking buffs

> **Epic**: Y1-P0 Stabilize (Sprint 001)
> **Task ID**: TD-002 (`docs/tech-debt-register.md#TD-002`; follow-up of Y1-P0-T07, due before Y1-P0-T15)
> **Status**: Ready
> **Layer**: Feature
> **Type**: Integration
> **Estimate**: 0.5 day (register effort: S)
> **Manifest Version**: N/A — `docs/architecture/control-manifest.md` does not exist
> **Last Updated**: 2026-10-24

## Context

**GDD**: none exists for NG+ or saves. **Design source of record**: `production/decisions/2026-10-audit-decisions.md`
§6 (decision 6A) and the T07 story (`production/epics/y1-p0-stabilize/story-t07-ngplus-buffs.md`), whose fix this
story protects.
**Requirement**: N/A — no TR-ID registered (`docs/architecture/tr-registry.yaml` holds no requirements).

**ADR Governing Implementation**: N/A — a test only; no architectural decision is made.
**ADR Decision Summary**: N/A
**ADR Version**: N/A

**Engine**: Godot 4.6 (4.6.3 at `C:/Godot`) | **Risk**: HIGH (`docs/engine-reference/godot/VERSION.md`, 4.6 row)
**Engine Notes**: no post-cutoff API expected. `load_game()` is a coroutine (it contains `await`), so the test
`await`s it.

**Control Manifest Rules**: NOT ASSESSED — no control manifest.

**Performance**: no impact; test only.

**AGENTS.md protected areas**: save/load and NG+ are protected. **This story changes no production code and no
save format.** The test calls the existing `GameManager.save_game()`, `load_game()` and `start_new_game_plus()`
as they are and only reads what they produce: it never edits a save file, never edits
`scripts/game_manager.gd`, `scripts/choice_consequences.gd` or any other script, and adds no save key. The files it
adds or touches are listed in AC-6. If the test exposes a defect in save/load or NG+, the fix is a separate story
with its own protected-area approval.

### Why T07's tests do not cover this

`tests/unit/ngplus/ngplus_buff_stacking_test.gd` applies buffs and calls `start_new_game_plus()` in memory. The
T07 fix subtracts `ChoiceConsequences.get_total_stat_mods()`, which reads `active_buffs`. A real player saves,
quits and loads before the Chapter 10 ending unlocks NG+, so the fix also depends on `active_buffs` **and** the
buffed `player_stats` both surviving a save and a load. Nothing tests that today (QA-lead, T07 close).

### Audit facts (2026-10-20, re-checked 2026-10-24 in /story-readiness; line numbers approximate)

- `SAVE_VERSION = "1.2.0"` (gm ~35). `save_game()` (gm ~1418-1520) writes
  `choice_consequences = ChoiceConsequences.get_save_data()` = `{active_buffs, party_combat_members}`
  (cc ~485-489) and `player_stats` as-is, as JSON with a `_checksum`, atomically via `.tmp`, after backing up an
  existing file to `.bak` (through `.bak.tmp`).
- `save_game()` refuses when `current_state` is MENU or GAME_OVER, when the manual slot is in COMBAT or CUTSCENE,
  when `current_scene` is missing or its `scene_file_path` is empty or in `NON_RESUMABLE_SCENES` (gm ~513, ~1447).
  T07's `_capture_save()` satisfies this with a dummy `Node` as `current_scene` and EXPLORATION state.
- `load_game()` (gm ~1553-1742): returns false while `SceneTransitions.is_transitioning`; reads and checksum-checks
  the file; a v1.2 save skips `_migrate_save_data()`; `player_stats = _merge_dict(DEFAULT_PLAYER_STATS, saved)`;
  a **non-empty** saved `choice_consequences` goes to `ChoiceConsequences.load_save_data()` (cc ~491-507), which
  appends the saved buff dictionaries **as they are** without re-applying mods; an empty one goes to
  `rebuild_from_flags()` (the TD-001 path, not tested here), which builds **fresh copies** from `CHOICE_BUFFS`.
  `load_game()` also restores `story_flags`, so matching buff ids alone cannot tell the two paths apart.
- `load_game()` calls `Achievements.load_save_data()` (gm ~1677-1679), which ends with an unconditional
  `_save_to_disk()` (achievements.gd ~400-408): every load writes `user://achievements.save`.
- **Scene change**: `load_game()` changes scene only when `ResourceLoader.exists(saved_scene)` is true (gm ~1705-1727),
  after `_sanitize_free_travel_loaded_scene()` (gm ~1405), which rewrites only a free-travel region path to the
  overworld. Player-position restore sits inside the same branch. Then `change_state()` restores EXPLORATION.
- **Numbers come back as floats**: JSON parses every number as a float, and `_merge_dict` copies them as they are,
  so after a load `base_attack` and the rest are `float`. `start_new_game_plus()` reads them into typed `int`
  locals (gm ~533-537) and writes ints back. Scalar `==` treats `51 == 51.0` as true; `Dictionary`/`Array` `==`
  does not, so the test compares field by field across a load.
- `get_total_stat_mods()` sums into `0.0`, so its values are floats even before a save, and it returns only the
  keys some active buff touches (for example `ch1_knight_killed` adds `attack 8, soul_gain_bonus 0.2`;
  `ch1_root_purge_used` adds only `max_hp -10`).
- `LoreJournal` and charms are not reset by T07's `_reset_all()`; NG+ discovers `root_heaven_ngplus_recap`. No
  asserted field depends on them.
- Since TD-007, both test runners refuse a `*_test.gd` under `res://tests/` with no line in
  `tests/suite_limits.txt`, and fail a suite whose last column-0 `<NAME> RESULT: N passed, F failed` line reports
  fewer than its `min_checks`. The name must be uppercase with no underscores (T07 prints
  `NGPLUS UNIT RESULT: ...`).

---

## Acceptance Criteria

- [ ] AC-1 **The save is a current v1.2 save on the load_save_data path.** For each route, `save_game(1)` returns
      true; the written JSON has `version == "1.2.0"`, `current_scene ==` the dummy path, and a non-empty
      `choice_consequences.active_buffs` whose buff ids, in order, equal `ChoiceConsequences.active_buffs` before
      the save (6 buffs for kill and for spare). Before the save the test adds a marker key
      (`"td002_marker": true`) to the first buff dictionary; after the load that buff still carries it, which only
      `load_save_data()` can produce (`rebuild_from_flags()` builds fresh copies).
- [ ] AC-2 **Load restores both halves.** Before the save, `get_total_stat_mods()` equals literal totals for the
      route (same key set; values `is_equal_approx`), written as constants from the `CHOICE_BUFFS` table, never
      computed by the code under test. After the save the test resets the run (`_reset_all()`) and asserts the
      reset took (`active_buffs` empty; base_attack/base_defense/max_hp == baseline 15/0/100, compared field by
      field), so only the load can restore them. `await load_game(1)` returns true, and then: `active_buffs` ids
      equal the pre-save ids; `get_total_stat_mods()` has the same key set and `is_equal_approx` values as before
      the save; `base_attack`, `base_defense`, `max_hp`, `attack`, `defense`, `hp`, `mp`, `max_mp` and `level` equal
      their pre-save values by scalar `==`, field by field. One route saves with `ng_plus_cycle = 2`: it is 0 after
      the reset and 2 after the load.
- [ ] AC-3 **NG+ after the load does not stack.** `start_new_game_plus()` called straight after the load gives
      base_attack/base_defense/max_hp == 15/0/100 on the kill and the spare route; `active_buffs` is empty;
      `ng_plus_cycle` is 1 (3 on the route that saved with 2); `hp == max_hp`, `mp == max_mp`; and base_attack,
      base_defense, max_hp, attack, defense, hp, max_mp and level are `TYPE_INT`. (That they were floats after the
      load is printed as a note, not asserted.) A second `start_new_game_plus()` right after changes nothing but the
      cycle.
- [ ] AC-4 **Same result as without a save, anchored by literals.** For kill, spare and a levelled kill run, the NG+
      stats after save → load equal the NG+ stats of the same run done in memory with no save (base_attack,
      base_defense, max_hp, attack, defense, hp, max_mp, level), **and** the in-memory P trio is the literal
      15/0/100 for kill and spare (the anchor that fails on pre-fix code; the comparison alone only catches a
      load-specific divergence such as dropped buffs). The levelled kill run also equals a no-buff control that
      earned the same XP and went through the same save → load.
- [ ] AC-5a **No scene change.** Preconditions: `not ResourceLoader.exists(DUMMY)`,
      `get_free_travel_region_id_for_scene(DUMMY)` is empty, `SceneTransitions.is_transitioning == false` before
      each load. After each load `current_scene` is null and the saved JSON's `current_scene` is DUMMY.
- [ ] AC-5b **No leftovers.** After each case the test removes `save_slot_1.save` and its `.bak`, `.bak.tmp`, `.tmp`
      and `.corrupted` siblings. After the suite, the `user://` listing minus the pre-suite listing is empty or
      exactly `{achievements.save}` (written by `Achievements.load_save_data()`; the test removes it if it did not
      exist before the suite), and no `save_slot_1.save*` file remains.
- [ ] AC-5c **No production change.** `git diff --stat -- AethelgardPrototype/scripts AethelgardPrototype/scenes` is
      empty for the story's changes.
- [ ] AC-6 `tests/unit/ngplus/ngplus_save_roundtrip_test.gd` exists with its `.uid`, passes, prints a final
      `NGPLUS ROUNDTRIP RESULT: N passed, F failed` line (uppercase, no underscore), and has a fixed number of
      checks (no `_check` inside a data-dependent branch). It is registered in all three places:
      `AethelgardPrototype/tests/suite_limits.txt` (`min_checks` = its final check count, `timeout_seconds` ≥ 120),
      `AethelgardPrototype/tests/run_all_tests.ps1` (and its header's suite count 16 → 17), and
      `.github/workflows/ci.yml` (a new step whose `name:` is double-quoted if it contains `: `). The layout guard
      `tests/integration/meta/test_layout_test.gd` passes; the full suite passes (baseline recorded first);
      `git diff --check` is clean; the pre-fix and HEAD logs are in `production/qa/evidence/2026-10-ngplus/`.

---

## Implementation Notes

- **New file**, not a T13 in the T07 file: T07's 192/0 count and its evidence logs stay valid, and the T07 file
  loads no scene and writes saves only in T9. Copy the helpers it needs (`_reset_all`, `_set_flags`, `_snap`,
  `_trio`, `_run_case`, `_listing`, `_remove_save_files` extended with `.bak.tmp`, the isolation guard,
  `KILL_FLAGS` / `SPARE_FLAGS` / `PURGE_FLAG` / `LEVEL_XP`, baseline constants) rather than sharing them; extracting
  a shared helper is out of scope.
- **How the test avoids a scene change** (adapted from T07's `_capture_save()`): before `save_game(1)`, add a
  dummy `Node` as `current_scene` with `scene_file_path = "res://tests/unit/ngplus/__td002_no_such_scene.tscn"`
  (a constant; the file must never exist) and set `current_state` to EXPLORATION. `save_game()` accepts it
  (non-empty, not in `NON_RESUMABLE_SCENES`). Remove and free the dummy and set `current_scene = null` right after
  the save, before the reset. On load, `_sanitize_free_travel_loaded_scene()` returns that path unchanged and
  `ResourceLoader.exists()` is false, so neither `SceneTransitions.change_scene()` nor `change_scene_to_file()`
  runs and no player position is restored. T07's `_capture_save()` used the real overworld path, which is fine for
  a save but would make `load_game()` load the overworld.
- Buffs are applied the real way, `GameManager.set_story_flag(flag, true)`, as in T07.
- **Floats**: compare field by field across a load, never `_snap()` dictionaries or `_trio()` arrays; `_trio(P) ==
  _base_trio()` is fine only on the NG+ side, where the values are ints again.
- **Literal totals**: read the per-route totals by hand from `CHOICE_BUFFS` in `scripts/choice_consequences.gd` and
  write them as constants (T07's header comment gives kill attack +36, max_hp −5, soul_gain_bonus +0.35 and spare
  attack +3, defense +31, max_hp +35; confirm each key set, including whether a key appears with a zero sum).
- **Watch it fail** (`.claude/rules/test-standards.md`): the T07 fix is already in. Run the new test against pre-fix
  code in a throwaway worktree created with `git -c core.longpaths=true worktree add --detach <scratch>/td002pre
  fc5a282~1` (a plain worktree add fails on the long art-source paths here; no stash, reset or branch switch in this
  checkout), copy the test and its `.uid` in, run `Godot --headless --import` there first, then the worktree's own
  `tests/run_phase0_tests.ps1` (the pre-TD-007 runner, no `suite_limits.txt` gate). Expected: the R1/R2/R3/R7/R8
  literal and control NG+ checks and R4's literal anchors **fail**; every round-trip check (AC-1, AC-2) **passes**.
  Then run it on HEAD: all pass. Keep both logs; remove the worktree afterwards.
- If an assertion fails on HEAD for a reason in save/load or NG+ (for example a float leaking through
  `start_new_game_plus()`), stop and report it; do not change production code under this story.
- Commit only with the user's OK, with `Task: TD-002` in the body; set TD-002 to Resolved in
  `docs/tech-debt-register.md` at close.

---

## Out of Scope

- Saves older than v1.2, `_migrate_save_data()` and `rebuild_from_flags()` (TD-001).
- A partial or empty `choice_consequences` in a save: it needs a hand-edited save file, which this story does not
  make; the empty-dictionary path is TD-001.
- NG+ started after a restart or quit carrying nothing (option B memo `77233cc`).
- Restoring the saved scene or player position; the autosave slot; backup recovery and `.corrupted` handling.
- Any change to save keys, save format, `save_game()`, `load_game()`, `start_new_game_plus()` or
  `choice_consequences.gd`.
- `party_combat_members` round trip, `soul_gain_bonus` carry, the Chapter 3 one-off max-HP bonuses, lore and charm
  state between cases.

---

## QA Test Cases

*Reviewed by qa-lead (QL-STORY-READY, 2026-10-24: GAPS G1–G8 → all adopted by the user). SceneTree `_check` style
(T06/T07 precedent), isolated `user://` via `tests/run_phase0_tests.ps1`. Helper `_roundtrip(flags, xp, cycle)`:
`_reset_all()` → optional `add_xp(xp)` → flags → optional `ng_plus_cycle = cycle` → snapshot E, buff ids, totals →
add the marker to buff 0 → save under the dummy scene → read the JSON (AC-1) → `_reset_all()` and assert the
reset field by field → `await load_game(1)` → snapshot L → `start_new_game_plus()` → snapshot P → remove save
files. Expected numbers are literals from `CHOICE_BUFFS` (as in T07), never computed with the code under test. Every
case asserts a precondition that differs from its expected result.*

- **R1 kill route (AC-1/2/3)** — `KILL_FLAGS`, hp 40 and mp below max before the save: E is ATK 51 / DEF 0 / HP 95;
  totals equal the kill literals (key set and values); JSON version 1.2.0, `current_scene` DUMMY, six kill buff ids,
  marker present; after the reset 15/0/100 field by field and no buffs; L == E on the nine fields (hp 40 and mp
  survive), same ids, same totals, marker still on buff 0; P 15/0/100, `active_buffs` empty, cycle 1, hp == max_hp,
  mp == max_mp, eight stats `TYPE_INT`; a second NG+ right after: same stats, cycle 2.
- **R2 spare route, cycle 2 (AC-1/2/3)** — `SPARE_FLAGS`, `ng_plus_cycle = 2`: E is ATK 18 / DEF 31 / HP 135;
  totals equal the spare literals; same checks; cycle 0 after the reset, 2 after the load, 3 after NG+; P 15/0/100.
- **R3 levelled run vs control (AC-4)** — control: no flags, `LEVEL_XP` (700, level ≥ 3 asserted), round trip →
  P_c. Kill flags + `LEVEL_XP`, round trip → P: level, base_attack, base_defense, max_hp, max_mp equal P_c.
- **R4 save vs no save (AC-4)** — for kill, spare and the levelled kill run: P after the round trip equals P from
  `_run_case` with the same inputs on the eight fields; for kill and spare the in-memory P trio is the literal
  15/0/100 (the pre-fix anchor).
- **R5 load_save_data path (AC-1)** — saved `choice_consequences` is a non-empty dictionary whose `active_buffs` ids
  equal the pre-save ids, and the marker on buff 0 survives the load.
- **R6 hygiene (AC-5a/b/c)** — preconditions: dummy path does not exist, is not a free-travel region path,
  `SceneTransitions.is_transitioning` false before each load; `current_scene` null after every load; no
  `.corrupted` file appears; the `user://` diff after the suite is empty or exactly `{achievements.save}` (removed if
  new); the isolation guard refuses to run outside `aeth_phase0_test`.
- **R7 purge only (AC-2/3)** — `ch1_root_purge_used` alone: E max_hp 90 with ATK 15 / DEF 0; totals key set is
  exactly `{max_hp}` with −10.0, before and after the load; P 15/0/100 (missing attack/defense keys after a JSON load).
- **R8 flip before the save (AC-2/3)** — `ch1_knight_killed` then `ch1_knight_spared`: E is 15/5/115 and the save
  holds only `guardian_blessing`; after the load the same single buff; P 15/0/100.
- **R9 second generation (AC-2/3)** — kill route: save → reset → load → save again (from float-typed stats; a
  `.bak` is created) → reset → load → NG+: L2 == E on the nine fields, P 15/0/100; cleanup removes the `.bak`.
- **AC-6** — the result line, the fixed check count, the `suite_limits.txt` entry, the two runner lists, the layout
  guard and the full suite; `git diff --check` clean; pre-fix log (literal and control NG+ checks and R4 anchors
  fail, round-trip checks pass) and HEAD log (all pass) in the evidence folder.

---

## Test Evidence

**Story Type**: Integration
**Required evidence**: `tests/unit/ngplus/ngplus_save_roundtrip_test.gd` passing, with a pre-fix log and a HEAD
log in `production/qa/evidence/2026-10-ngplus/`.
**Run result**: N/A — test-only story with nothing player-observable; Y1-P0-T15 observes NG+ on a real build.

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Y1-P0-T07 (done, `fc5a282`); TD-007 (done, `249cba4`: the `suite_limits.txt` registration rule).
- Unlocks: Y1-P0-T15 (QA-lead: TD-002 before the Phase 0 exit playthrough).
