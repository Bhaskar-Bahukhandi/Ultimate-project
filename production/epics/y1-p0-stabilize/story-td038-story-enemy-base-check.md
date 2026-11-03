# Story TD-038: A story-fight row's enemy script must extend EnemyBase

> **Epic**: Y1-P0 Stabilize (Sprint 001)
> **Task ID**: TD-038 (`docs/tech-debt-register.md#TD-038`; raised at the TD-031 close by /code-review and LP-CODE-REVIEW, target "before T13b")
> **Status**: Complete
> **Layer**: Core (combat arena)
> **Type**: Integration
> **Estimate**: 0.5 day (register effort: S; +0.25 for the QL-STORY-READY test additions)
> **Manifest Version**: N/A — `docs/architecture/control-manifest.md` does not exist
> **Last Updated**: 2026-11-01

## Context

**GDD**: none for Chapter 1 combat encounters (as T13a and TD-031). **Source of record**: TD-038 in
`docs/tech-debt-register.md` — "`validate_story_fight` accepts an `enemy_script` that loads as a Script but does not
extend `EnemyBase`; the fight would then fail at `enemy.died.connect` in `_spawn_story_enemy` (`combat_arena.gd`). Check
the script's base class (or a `died` signal) and add a refused-row case. Do before T13b, which adds new enemy scripts".
**Requirement**: N/A — no TR-ID registered.

**ADR Governing Implementation**: N/A — no ADRs exist (`docs/architecture/` holds only `tr-registry.yaml`). One more rule
in TD-031's validator; no architectural decision is made.
**ADR Decision Summary**: N/A
**ADR Version**: N/A

**Engine**: Godot 4.6 (4.6.3 at `C:/Godot`; every run sets `GODOT` to the 4.6.3 console exe, TD-036) | **Risk**: LOW.
APIs are pre-cutoff: `Script.get_base_script()`, `load()`, a `class_name` global (`EnemyBase`).

**Control Manifest Rules**: NOT ASSESSED — no control manifest.

**Performance**: none — the check walks a script's base chain (one or two links today) once when a story fight starts.

**AGENTS.md protected areas — permission asked by this story:** **combat** (`scripts/combat/combat_arena.gd`, the
story-fight validator only). Nothing else changes: no spawn, collision, story flag, save or progression code.

**Files**: `AethelgardPrototype/scripts/combat/combat_arena.gd` (`_validate_story_script` and its doc comment);
`AethelgardPrototype/tests/integration/combat/story_fight_table_test.gd`; `AethelgardPrototype/tests/suite_limits.txt`
(the suite's min_checks); `AethelgardPrototype/CHANGELOG.md`; `docs/tech-debt-register.md` (TD-038 resolved); this
story; its `production/sprint-status.yaml` entry; new evidence folder `production/qa/evidence/2026-11-td038/`.

### Audit facts (2026-11-01, on HEAD `ff428bf`)

1. **The gap.** `_validate_story_script` (`combat_arena.gd:795-805`) refuses a missing path and a non-Script resource
   only. A row whose `enemy_script` is any other script (for example `res://scripts/combat/combat_arena.gd`, which
   extends `Node2D`) passes, and the fight then fails at `enemy.died.connect` in `_spawn_story_enemy`, after the
   tutorial slime is freed.
2. **What the arena needs from the script.** `_spawn_story_enemy`, `_on_story_enemy_died` and `_story_retry` use
   `died`, `loot_table`, `current_state` and `EnemyBase.State`; `set_script` puts the script on a `CharacterBody2D`.
   All of these are `EnemyBase`'s (`scripts/combat/enemy_base.gd`: `extends CharacterBody2D`, `class_name EnemyBase`,
   `signal died` at `:12`). So the rule is "extends EnemyBase", not "has a `died` signal".
3. **Every enemy script today extends EnemyBase directly:** all 17 files in `scripts/combat/enemies/` (slime, the
   regular enemies and the bosses). T13b's guardian and T13c's boar will be new files there.
4. **Existing cases.** QA 2 already refuses a missing script and a `.tscn` (`story_fight_table_test.gd:544`, `:556`);
   no case uses a script that is not an EnemyBase.

### Decisions (user, 2026-11-01: D1 and the combat permission approved with the draft; D2 approved after QL-STORY-READY)

- **D1 The rule is inheritance from `EnemyBase`** (directly or through a parent script), checked by walking
  `get_base_script()` and comparing with the `EnemyBase` script, not by looking for a `died` signal (audit fact 2).
- **D2 QL-STORY-READY gaps folded in** (GAPS, 5 items): the walk as a testable helper with an inherited-chain case
  (QA 5), the parse-error case by hand, a ≥ 17 floor on the folder listing, three mutations, a stronger QA 1 check,
  the min_checks bump in AC-3; estimate 0.5 day.

## Acceptance Criteria

- [x] AC-1 **A non-EnemyBase script is refused.** `_validate_story_script` refuses an `enemy_script` that loads as a
      Script but does not extend `EnemyBase` (directly or through a parent script): exactly one message, naming
      `enemy_script` and saying it does not extend EnemyBase. The two existing messages (no script at the path; not a
      Script) are unchanged. The chain walk is its own static helper, `_story_script_extends_enemy_base(script: Script)
      -> bool`, so a test can check it on in-memory scripts. The script is loaded once. Each function stays ≤ 40 lines
      with at most 3 branch points (counted by hand). A script that fails to parse gives exactly one message and no
      crash (checked once by hand, below — a committed broken script would fail the runner's `Parse Error` rule).
- [x] AC-2 **No false refusal.** Every `STORY_FIGHTS` row still validates clean, and every `*.gd` file in
      `res://scripts/combat/enemies/` passes the check as a row's `enemy_script` (the test lists the folder, so a new
      enemy script that does not extend EnemyBase fails the suite). The listing must find at least 17 scripts (the
      count today), so an empty listing fails rather than passing with nothing checked; only `*.gd` files are checked
      (`*.gd.uid` skipped). The listing runs from the project, not an exported build (which lists `.remap` files).
- [x] AC-3 **Tests.** QA cases 1–5 below. Watched failing: QA 1 and QA 5 fail on the code before the change (QA 2 is a
      no-false-refusal check and cannot fail there; it is watched failing through mutation b). Three mutations, one
      per invocation, each caught by the named case: (a) the validator no longer calls the helper → QA 1; (b) the check
      always refuses → QA 2; (c) the walk checks one level only (`get_base_script() == EnemyBase`) → QA 5a. The suite's
      `suite_limits.txt` min_checks is raised to the new count. `story_fight_table_test` (3 runs), `story_fight_test`,
      the full local run on Godot 4.6.3 and CI stay green.

## Implementation Notes

- Walk the chain: `var s: Script = load(path); while s != null: if s == EnemyBase: return ok; s = s.get_base_script()`.
  `EnemyBase` is the global class from `enemy_base.gd`; compare scripts, not file names.
- Keep the message style of the existing ones: `key 'enemy_script': '<path>' does not extend EnemyBase`.
- Update the doc comment above `_validate_story_script` and the line in `validate_story_fight`'s doc comment that lists
  what is refused.

## Out of Scope

- TD-039 (`default_return_scene` / `enemy_name` checks, the non-Dictionary row test) and TD-040 (backdrop complexity,
  moving the schema to its own file).
- Any change to enemy scripts, `EnemyBase`, the spawn path or the encounter and boss modes.
- T13b and T13c themselves.

## QA Test Cases

1. A row with `enemy_script` = `res://scripts/combat/combat_arena.gd` → `validate_story_fight` returns exactly one
   message, and that message contains both `enemy_script` and `EnemyBase` (an explicit check, not only the QA 2
   loop's `contains(key)`).
2. For each `*.gd` in `res://scripts/combat/enemies/`, a valid test row with that `enemy_script` (and `enemy_size` /
   `enemy_color` set, so a type without a table entry is not refused for its look) → no message.
3. Every `STORY_FIGHTS` row → no message (QA 1, unchanged).
4. The existing missing-path and `.tscn` cases → still exactly one message each (QA 2, unchanged).
5. The chain walk, on in-memory scripts (`GDScript.new()`, `source_code`, `reload()`; no fixture file): (5a) a script
   whose source is `extends "res://scripts/combat/enemies/slime.gd"` (EnemyBase two levels up) →
   `_story_script_extends_enemy_base` true; (5b) a script `extends Node2D` → false; (5c) a script that extends
   `res://scripts/combat/combat_arena.gd` → false.
6. By hand, recorded in the evidence README (not in the suite): a temporary `user://td038_parse_error.gd` with a syntax
   error as `enemy_script` → exactly one message, no crash; the file is deleted afterwards.

## Test Evidence

**Story Type**: Integration
**Required evidence**: `AethelgardPrototype/tests/integration/combat/story_fight_table_test.gd` passing locally and in
CI; `production/qa/evidence/2026-11-td038/` — `README.md` (AC map), the suite's log before the change (new checks
failing), the three mutation logs, the after logs (×3), `story_fight_test`, the full local run, and the hand check
of QA case 6. The README also notes that QA 2 proves validation only: a boss script passing the check says nothing
about whether it works as a story enemy.
**Run result**: N/A — nothing on screen changes (a validator rule for rows that do not exist yet; the `ch1_slime` fight
is untouched, and its golden checks stay in the suite).

## Dependencies

- Depends on: TD-031 (done 2026-11-01; CI #49 green on `973cb7d`).
- Unlocks: Y1-P0-T13b (guardian) and Y1-P0-T13c (boar), whose new enemy scripts this check covers.

---

## Completion Notes
**Completed**: 2026-11-01
**Verdict**: COMPLETE WITH NOTES
**Criteria**: 3/3 passing; AC-3's CI was DEFERRED at close (local full run 26/26 on Godot 4.6.3) and is now met (CI #51, below).
**Deviations** (advisory, user-accepted):
- `_validate_story_script` is split into `_validate_story_script_class` to keep each function at ≤ 3 branch points (the story named one function); the two existing messages are unchanged.
- The refusal message ends "(or failed to compile; see Godot's error above)" (LP-CODE-REVIEW, user decision), because a script that fails to parse has no base script and gets this message. A first wording that named the engine's parse-error text tripped the runner's TD-003 rule (QA 1 prints the message) and was reverted.
- The full local run (`run_all_after.log`) predates the review fixes and the wording change; those touched only this suite's TD-038 cases, one doc comment and one message string, re-verified by the suite runs (303/0 ×3).
**Test Evidence**: Integration test `AethelgardPrototype/tests/integration/combat/story_fight_table_test.gd` (303 checks, 29 TD-038): watched failing before the change (`tdd_before_change.log` 295/5); mutations (a) → QA 1, (b) → QA 2, (c) → QA 5a; QA 6 (parse error) by hand, one message, no crash; `story_fight_test` 63/0. All in `production/qa/evidence/2026-11-td038/` (README maps it).
**Code Review**: Complete — `/code-review` APPROVED WITH SUGGESTIONS (applied: doc-comment rewrap, `\n` escapes, chain-shape checks in QA 5, README note on the non-recursive listing); QL-TEST-COVERAGE ADEQUATE; LP-CODE-REVIEW CONCERNS (fixed: the message wording).
**Tech debt logged**: none. Noted in the README: the QA 2 folder listing is not recursive, so a new enemy script must sit directly in `scripts/combat/enemies/`.
**Known after close**: CI run #51 on `bbc45b2` (2026-11-01 23:59 UTC, run 41364767402) is green, 24m48s; "Story fight table" took 9 s, "Story fight" 40 s. AC-3's deferred CI check is met.
