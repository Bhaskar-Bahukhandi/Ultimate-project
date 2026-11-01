# Story TD-031: The story-fight table holds the whole fight, and one builder makes every enemy body

> **Epic**: Y1-P0 Stabilize (Sprint 001)
> **Task ID**: TD-031 (`docs/tech-debt-register.md#TD-031`; raised at the T13a close by LP-CODE-REVIEW C1 and C2, target "before T13b")
> **Status**: Ready
> **Layer**: Core (combat arena)
> **Type**: Integration
> **Estimate**: 1.5 days (register effort: M; +0.5 day for the golden encounter, boss and slime checks QL-STORY-READY asked for)
> **Manifest Version**: N/A — `docs/architecture/control-manifest.md` does not exist
> **Last Updated**: 2026-11-01

## Context

**GDD**: none for Chapter 1 combat encounters (as T13a). **Source of record**: TD-031 in `docs/tech-debt-register.md` —
"(1) the `STORY_FIGHTS` table does not yet hold the whole fight … T13b and T13c should add rows, not code. (2) The
enemy-body setup (collision, hitbox, sprite or placeholder) is written three times in the arena (encounter, boss, story
fight): one shared builder". **Requirement**: N/A — no TR-ID registered.

**ADR Governing Implementation**: N/A — no ADRs exist (`docs/architecture/` holds only `tr-registry.yaml`). This is a
refactor inside one file that keeps T13a's design; no architectural decision is made.
**ADR Decision Summary**: N/A
**ADR Version**: N/A

**Engine**: Godot 4.6 (4.6.3 at `C:/Godot`) | **Risk**: LOW. APIs used are pre-cutoff (`Dictionary.merged`, 4.2+;
`CharacterBody2D`, `ColorRect`, `RectangleShape2D`). No physics, rendering or input API change.

**Control Manifest Rules**: NOT ASSESSED — no control manifest.

**Performance**: none expected — the same nodes are built once per spawn as today; the defaults merge and the row check
run once per story fight start.

**AGENTS.md protected areas — permission asked by this story:** **combat** (`scripts/combat/combat_arena.gd`) and
**collision/hitboxes** (the enemy bodies' `CollisionShape2D`, `collision_layer`, `collision_mask` setup moves into one
builder). **No value changes**: every size, colour, layer (4), mask (1), shape offset and spawn position stays as it is.
Not touched: save/load schema, story progression (the slime's flags and return scene are the same data), Source Key, true
ending, NG+, world map, region baselines. Production-art fallback: not affected (placeholder `ColorRect` bodies only).

**Files**: `AethelgardPrototype/scripts/combat/combat_arena.gd`; new
`AethelgardPrototype/tests/integration/combat/story_fight_table_test.gd`; `AethelgardPrototype/tests/suite_limits.txt`
(one new line); `.github/workflows/ci.yml` (one new step: the layout test requires every suite to run in CI);
`AethelgardPrototype/CHANGELOG.md`; `docs/tech-debt-register.md` (TD-031 resolved, header counts); this story; its
`production/sprint-status.yaml` entry; new evidence folder `production/qa/evidence/2026-11-td031/`.

### Audit facts (2026-11-01, on HEAD `b27a318`)

1. **Tree layout in code.** `_apply_story_backdrop` (`combat_arena.gd:701-748`, 48 lines, over the 40-line rule) holds
   an 11-tree literal `[[x, width, height], …]`; only the colours and the margin come from the row.
2. **Kit gated by mode.** `_input` (:967), `_open_root_access` (:984) and `_use_perfect_delete` (:1083) refuse Root
   Access and Perfect Delete whenever `_story_id` is set. Their target selection knows only the boss, the encounter list
   and the tutorial `slime`; a story enemy is never a target, and a Perfect Delete kill frees the enemy without the
   story-resolution path. Allowing the kit in a story fight is gameplay work, not a key.
3. **Shard keys required.** `_spawn_story_shards` and `_on_story_enemy_died` index `shard_color`, `shard_count`,
   `shard_fade`, `shard_size`, `shard_z` directly: a row without them errors at the win.
4. **Hard-coded fallback.** `_on_story_enemy_died` uses `Vector2(900, 400)` as the shard origin when the enemy is
   already freed (:818); the row's `enemy_spawn` (760, 400) is the right fallback.
5. **No row check.** `_consume_story_fight_metas` checks only that the id is a key. A row with a missing or misspelt key
   fails mid-fight, not at the start.
6. **Three body setups.** Encounter (:321-353), boss (:441-466) and story (:777-797) each build a `CharacterBody2D`
   with a `Sprite` `ColorRect` (size, `(-w/2, -h)`, colour, mouse ignore) and a `CollisionShape2D` with a
   `RectangleShape2D` (size, `(0, -h/2)`), layer 4, mask 1. The only differences: the encounter sets the
   `pending_zone_level` meta before `set_script` and `zone_level` after it; the boss uses `BOSS_SIZES`/`BOSS_COLORS`
   and spawns at (800, 400).
7. **One enemy per fight.** `_story_enemy` is a single node; the plan's guardian (T13b) and boar (T13c) are one enemy
   each.
8. **No test reads the table.** No suite under `tests/` references `STORY_FIGHTS` or its keys; `story_fight_test.gd`
   checks behaviour (spawn, retry, win, flags, return, pause, pad), which this story must not change.
9. **Encounter and boss bodies are untested** (QL-STORY-READY, verified): no suite references `pending_zone_level`,
   `get_boss_retry_hp_fraction` or `_boss_initial_hp`, so the other suites staying green says nothing about the two
   setups this story moves. `pending_zone_level` is set (`:326`) but read nowhere in `scripts/`; the stat scaling
   comes from the `zone_level` property, set after `set_script` and before `add_child`, so `_ready` sees it.
10. **Other shapes in the file.** `RectangleShape2D.new()` also builds the arena walls (`:155`) and the kill zone
    (`:167`); they are not enemy bodies and stay as they are.
11. **`STORY_FIGHTS` is a `const`.** A test cannot add a row to it; it needs the arena's table as a variable, set
    before the arena enters the tree (its `_ready` consumes the metas).

### Decisions (user, 2026-11-01; D3 and the combat/collision permission approved with the draft)

- **D1 One enemy per fight stays** (the guardian and the boar are one enemy each). The limit is recorded, not built.
- **D2 TD-034 (1), the slime's colour, stays in TD-034.** This story changes nothing visible.
- **D3 The kit stays refused in every story fight.** Audit fact 2: an "allow" key would need
  story-enemy targeting and a Perfect Delete resolution path that no planned fight uses (Root Access unlocks after
  Chapter 1). The refusal is documented as the rule in the table's doc comment, and TD-031's kit item closes as decided.
- **D4 QL-STORY-READY gaps folded in.** The qa-lead gate returned GAPS twice (9, then 4 plus an optional mutation);
  the user chose to fold all of them in: audit facts 9-11, QA cases 10-11, golden values, mutations (d)-(j), test
  isolation, estimate 1.5 days.

## Acceptance Criteria

- [ ] AC-1 **The backdrop is data.** The `ch1_slime` row's flat keys `sky`, `ground`, `path`, `tree` and
      `backdrop_margin` move into one `backdrop` dictionary: `sky`, `ground`, `tree` (colours), `margin` (Vector2, was
      `backdrop_margin`), `trees` (array of `[x, width, height]`, the 11 trees from the code) and an optional `path`
      colour. Every value is unchanged. No tree position, width or height literal is left in the arena's code (checked by
      a source-text assertion: the old literal's first entry `[-420.0, 38.0, 230.0]` no longer appears in
      `combat_arena.gd`). A row with `backdrop` `{}` leaves `Background` and `Ground/GroundSprite` as the scene has them
      and adds no `StoryFightBackdrop` node; a backdrop without `path` adds no `StoryFightPath`. Every function this story
      adds or changes is at most 40 lines (line counts recorded in the evidence README).
- [ ] AC-2 **Optional keys have defaults.** A `STORY_FIGHT_DEFAULTS` constant gives every optional key its value:
      `shard_count` 0 (no shard beat), `shard_fade` 0.6, `shard_size` 12.0, `shard_z` 20, `shard_color` `Color(1, 1, 1)`,
      `backdrop` `{}`. The active config is the row merged over the defaults. With `shard_count` 0 the win still waits
      `shard_fade` real seconds: `story_fight_resolved("win")` is not emitted before it and is emitted after, then the
      arena leaves.
- [ ] AC-3 **A row is checked before the fight starts.** A static `validate_story_fight(row: Dictionary) ->
      PackedStringArray` returns one message per problem, naming the key:
      - a missing required key (`enemy_script` String, `enemy_type` String, `enemy_name` String, `enemy_spawn` Vector2,
        `player_spawn` Vector2, `default_return_scene` String, `flags` Array, `controls` String);
      - a required or optional key of the wrong type, where a number key (`shard_count`, `shard_fade`, `shard_size`,
        `shard_z`) accepts int or float, `shard_color` is a Color and `backdrop` a Dictionary;
      - an unknown key: the allowed keys are the required keys plus the keys of `STORY_FIGHT_DEFAULTS`, so the old flat
        backdrop keys are refused;
      - an `enemy_script` path that does not exist;
      - a non-empty `backdrop` missing `sky`, `ground`, `tree`, `margin` or `trees`, or holding a key outside those
        and `path`.
      A row with problems is refused like an unknown id: one `push_warning` per problem, the metas are still removed, and
      the arena runs its default mode. The test checks the returned messages; the warnings are checked by reading the
      suite's log and recorded in the evidence.
- [ ] AC-4 **No hard-coded fallback.** When the enemy is already freed at the win, the shard origin is the row's
      `enemy_spawn`; `Vector2(900, 400)` is gone.
- [ ] AC-5 **One enemy-body builder.** `_build_enemy_body(node_name: String, size: Vector2, color: Color, pos: Vector2)
      -> CharacterBody2D` returns an unscripted body with the `Sprite` `ColorRect` and `CollisionShape2D` exactly as audit
      fact 6, layer 4, mask 1, at `pos`. The encounter, boss and story spawns (the story retry included) all use it.
      `CharacterBody2D.new()` appears once in `combat_arena.gd`, inside `_build_enemy_body`; no spawn function creates a
      `RectangleShape2D` or a `"Sprite"` `ColorRect` (checked by source-text counts; the walls' and kill zone's shapes,
      audit fact 10, are not enemy bodies and stay). The encounter body still carries the `pending_zone_level` meta
      (QA case 10) and gets `zone_level` after `set_script` and before `add_child` (case 10 through `max_health`, mutation
      g). The meta's place before `set_script` and every caller's `set_script` before `add_child` have no observable
      effect today (audit fact 9) and are checked at code review.
- [ ] AC-6 **A new fight is a row.** The arena reads its table through a public `story_fight_table: Dictionary`
      (default `STORY_FIGHTS`), which a test assigns before `add_child` (audit fact 11). In the new test, a row defined
      only in the test — required keys only, a different enemy script, no backdrop — runs a whole fight with no arena code
      for it: spawn at its `enemy_spawn`, the player at its `player_spawn`, kill → its flags set,
      `story_fight_resolved("win")` once, the change to its return scene; a death → retry with a fresh enemy.
- [ ] AC-7 **Nothing else changes.** The kit stays refused in every story fight (D3; the doc comment says so).
      - **The slime fight:** golden values captured from the code before the change (each `StoryFightTrunk` and
        `StoryFightCanopy` rect's position, size and colour; the `Background`, `GroundSprite` and `StoryFightPath`
        rects; the story enemy's body) are equal after it, and `story_fight_test` stays 63/0. A live before/after
        screenshot pair is retained for the user's sign-off.
      - **The encounter and boss bodies:** golden values captured before the change are equal after it (QA cases 10,
        11).
- [ ] AC-8 **Tests.** `story_fight_table_test.gd` covers AC-1 to AC-7 through QA cases 1-11, including: every row of
      `STORY_FIGHTS` validates clean; the builder's node shape; a test backdrop of 2 trees makes exactly 2 trunks.
      **Watched failing:** the golden cases (8, 10, 11) are captured on and pass against the code before the change;
      every other case is watched failing against the code before the change. Every case is watched failing against at
      least one of these mutations, each caught by the case named:
      - (a) the defaults merge removed → 4;
      - (b) the builder's mask changed to 2 → 7;
      - (c) the trees read from a literal again → 5;
      - (d) the `Vector2(900, 400)` fallback restored → 9;
      - (e) the unknown-key check removed → 2;
      - (f) the retry builds its enemy without the builder (mask 2) → 6;
      - (g) the encounter sets `zone_level` after `add_child` → 10 (an enemy of level ≥ 2, so `max_health` differs);
      - (h) the boss body built with `ENEMY_SIZES`' default size or at (900, 400) → 11;
      - (i) one `ch1_slime` tree's width changed → 8;
      - (j) `_consume_story_fight_metas` skips `validate_story_fight` → 3.
      **Isolation:** cases 10 and 11 pin, in setup, `GameManager`'s difficulty, `player_stats.level` and (case 11) the
      boss checkpoint (attempts 3, best phase 3, so the fraction is 0.8), and restore them in teardown; case 11 also
      removes the `boss_fight_id` meta, which `_start_boss_fight` leaves set (`:411`).
      Suites that must stay green: `story_fight_test` (63/0 ×3), `combat_fixes_test`, `chapter1_route_test`,
      `phase0_blockers_test`, `full_playthrough_test`, the load-every-script step, the boot check; then the full local run
      and CI.

## Implementation Notes

- `_start_story_fight` takes the config from `story_fight_table[id].merged(STORY_FIGHT_DEFAULTS)` (row wins).
- Split the backdrop into the colour/size part and a `_build_story_trees(backdrop) -> Node2D` helper to meet the
  40-line rule. Keep the node names (`StoryFightBackdrop`, `StoryFightTrunk`, `StoryFightCanopy`, `StoryFightPath`).
- `validate_story_fight` is static so the test can check rows without an arena; the type checks use `typeof`
  (`TYPE_INT` or `TYPE_FLOAT` for number keys).
- Capture the golden values first, on the unchanged code: write QA cases 10, 11 and the slime golden check, run them
  against HEAD, paste the observed values into the test as constants, and keep that log as evidence.
- The builder keeps the comments that explain each part today (the encounter's "EnemyBase expects a Sprite child",
  "required for CharacterBody2D physics", the layer names).

## Out of Scope

- More than one enemy per story fight (D1); the slime's colour and the grey void in the other modes (TD-034, D2).
- Allowing Root Access or Perfect Delete in a story fight (D3).
- TD-032 (test gaps) and TD-033 (private state, the `invuln_timer` write); TD-035 (the Windows crash watch).
- The guardian and the boar themselves (T13b, T13c): their enemy scripts, rows and story hand-offs.
- Any change to `ENEMY_COLORS`, `ENEMY_SIZES`, `BOSS_*`, spawn positions, rewards or the encounter/boss flow.

## QA Test Cases

1. Every `STORY_FIGHTS` row → `validate_story_fight` returns no messages. `STORY_FIGHT_DEFAULTS` holds the AC-2
   values exactly.
2. A row missing `flags`; one with `enemy_spawn` as a String; one with a key `enemy_spwan`; one with the old flat key
   `sky`; one whose `enemy_script` does not exist; one whose `backdrop` lacks `trees` → one message each, naming the key.
   A row with `shard_size` 12 (int) and one with `shard_count` 3.0 (float) → no message.
3. The arena given an invalid row through `story_fight_table` and the metas → default mode (the tutorial slime is there,
   no story enemy), the metas removed.
4. A test row with required keys only → no `StoryFightBackdrop`, `Background` colour unchanged; enemy at the row's
   spawn; kill → the row's flags, the win signal not emitted before `shard_fade` (0.6 s real) and emitted once after,
   the return-scene change; no shard nodes.
5. A test row with a 2-tree backdrop and no `path` → 2 `StoryFightTrunk`, no `StoryFightPath`. A source-text check:
   `[-420.0, 38.0, 230.0]` does not appear in `combat_arena.gd`.
6. A test row → player death → retry: a fresh enemy at the spawn with layer 4 and mask 1, `story_fight_retries` 1.
7. `_build_enemy_body("X", Vector2(30, 20), red, Vector2(5, 6))` → children `Sprite` (ColorRect 30×20 at (-15, -20),
   red, mouse ignore) and a `CollisionShape2D` (rect 30×20 at (0, -10)); layer 4, mask 1, position (5, 6), no script.
   Source-text counts per AC-5.
8. The `ch1_slime` fight → its backdrop rects and story enemy body equal the golden values captured before the change.
9. A test row with `shard_count` 3 and `enemy_spawn` (300, 400) → the win with `_story_enemy` already freed → 3 shards
   start at (300 - size/2, 400 - 22), not at (900, 400).
10. An encounter entered through the `GameManager` meta `pending_encounter` (read at `:193` and `:275`), with two
    explicit enemy entries of different types that `RandomEncounterSystem.ENEMY_SCRIPTS` resolves, one at level ≥ 2
    → each body's name, position, `zone_level`, `max_health`, `pending_zone_level` meta, sprite size and colour, shape size and
    offset, layer and mask equal the golden values captured before the change.
11. A boss fight (the `boss_fight_id` meta) with the pinned checkpoint giving `get_boss_retry_hp_fraction` 0.8
    → after the arena's two awaited frames, `_boss_node` is the body, `current_health` = `max_health` × the fraction, `_boss_initial_hp` = `max_health`,
    and the body's sprite, shape, layer, mask and position (800, 400) equal the golden values.

## Test Evidence

**Story Type**: Integration
**Required evidence**: `AethelgardPrototype/tests/integration/combat/story_fight_table_test.gd` passing locally and in
CI; `production/qa/evidence/2026-11-td031/` — `README.md` (AC map, watched-fail record, function line counts, the
AC-3 warning lines read from the log), the golden-capture log on the unchanged code, the new test's logs (before the
change, mutations a-j, after ×3), the regression suite logs, the full local run log, and
`story-fight-before.png` / `story-fight-after.png` from the live renderer (AC-7), for the user's sign-off.
**Run result**: not yet run.

## Dependencies

- Depends on: Y1-P0-T13a (done 2026-10-30; CI #48 green on `b27a318`).
- Unlocks: Y1-P0-T13b (guardian) and Y1-P0-T13c (boar) as rows plus their enemy scripts.

---

## Completion Notes

(empty until /story-done)
