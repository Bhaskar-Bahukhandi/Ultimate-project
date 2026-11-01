# TD-031 evidence: the story-fight table holds the whole fight, one enemy-body builder

Story: `production/epics/y1-p0-stabilize/story-td031-story-fight-table.md`. Every run here is on **Godot 4.6.3**
(each log's first line says so), set through `GODOT` because the Windows runner would otherwise pick 4.7.2 (TD-036).
Arena: `AethelgardPrototype/scripts/combat/combat_arena.gd`. Suite:
`AethelgardPrototype/tests/integration/combat/story_fight_table_test.gd` (248 checks at first, 262 after the code-review
fixes; see "Code review round 1" at the end).

## Order of work

1. **Golden values captured on the unchanged arena** (HEAD `b27a318` code): the slime fight's backdrop rects and enemy
   body, two encounter bodies (`Slime_0` level 1, `CorruptedRat_1` level 3) and the `clockwork_automaton` boss body.
   `golden_capture_before.log` (176 values, identical over 3 capture runs and two other case orders), then locked as
   constants: `golden_cases_before_1-3.log` (4.7.2, before TD-036 was found) and `golden_cases_before_463_1-3.log`
   (4.6.3): 185/0 each.
2. **New cases written before the change and watched failing:** `tdd_before_change.log`, 190 passed, 32 failed, exit 1,
   0 script errors. Every golden check passed; every new case had at least one failing check by name.
3. **Refactor**, then the runs below.

## Runs after the change

| Run | Result | Log |
|---|---|---|
| New suite, 3 in a row | 248/0 each, 9–11 s | `after_1-3.log` |
| `story_fight_test`, 3 in a row | 63/0 each, 43–44 s | `story_fight_after_1-3.log` |
| `combat_fixes_test` | 45/0 | `combat_fixes_after.log` |
| `test_layout_test` (every suite runs in CI) | 6/0 | `layout_after.log` |
| Full local run, 26 suites | all passed (chapter1_route 413/0, phase0 82/0, playthrough 172/0, load-all 209/0), 1524 s | `run_all_after.log` |
| Boot check (CI's command and error patterns) | exit 0, 0 matching lines | `boot_after.log` |

## Mutations (AC-8)

`td031_mutate.py` applies one mutation, runs the suite, restores the arena byte for byte (SHA-256 checked) and prints the
result. One mutation per invocation. Every one was caught by the case the story names. The table below is round 1
(on the 248-check suite, logs in `round1_mutations/`); round 2, on the fixed code, is under "Code review round 1".

| Mutation | Expected case | Result |
|---|---|---|
| (a) the defaults merge removed | 4 | 244/4: QA 4 (win timing, win and scene change), QA 9 |
| (b) the builder's mask changed to 2 | 7 | 246/2: QA 7 (`builder.collision_mask is 1`), QA 6 |
| (c) the trees read from a literal again | 5 | 246/2: QA 5 (2-tree count, first trunk) |
| (d) the `Vector2(900, 400)` fallback restored | 9 | 247/1: QA 9 (shards at (894, 378)) |
| (e) the unknown-key check removed | 2 | 245/3: QA 2 (`enemy_spwan`, old key `sky`), QA 3 |
| (f) the retry builds its enemy with mask 2 | 6 | 247/1: QA 6 (fresh enemy mask 2) |
| (g) the encounter sets `zone_level` after `add_child` | 10 | 247/1: QA 10 (`CorruptedRat_1.max_health` 24.519, golden 30.404) — `mutation_g2.log` |
| (g′) variant: the `zone_level` assignment removed | 10 | 244/4: QA 10 (zone levels 0, `max_health`) — `mutation_g_removed.log` |
| (h) the boss body built at the default 48×48 | 11 | 244/4: QA 11 (sprite and shape size and offsets) |
| (i) one `ch1_slime` tree's width changed | 8 | 245/3: QA 8 (trunk[0] size, canopy[0]) |
| (j) `_consume_story_fight_metas` skips the row check | 3 | 247/1: QA 3 (the refused row runs the default mode) |

Note: the golden cases did not catch (b) and (f), because `EnemyBase._ready` sets layer 4 and mask 1 itself; QA 6 reads
the body as it enters the tree, before `_ready`, and QA 7 reads the builder's output directly.

## AC-3 warnings (read from the log)

`after_1.log`: `[STORY FIGHT] Story fight 'td031_invalid' refused, running the default mode: unknown key 'sky'` — one
`push_warning` per problem, as the test's returned messages count them.

## Live screenshots (AC-7)

`story-fight-before.png` (HEAD's `combat_arena.gd` swapped in for the one capture, then restored, SHA-256 checked) and
`story-fight-after.png` (the refactored arena), both from a real 1280x720 window (Godot 4.6.3, Vulkan 1.4.329 Forward+,
NVIDIA GeForce RTX 2050) through the real hand-off path (story metas, `SceneTransitions.change_scene` to the arena),
3 s after the change. Not headless, not the dummy renderer. Script: `td031_capture.gd.txt`, driver
`td031_capture_run.py`, logs `capture_before.log` / `capture_after.log` (slime present, backdrop present, 11 trees).
**The two PNGs are byte-identical** (0 differing pixels, same SHA-256 `4e145df8…`). **Signed off by the user, 2026-11-01.**

## Function lengths (AC-1)

Added or changed story-fight functions, lines including trailing blank lines: `_build_enemy_body` 28,
`_consume_story_fight_metas` 19, `validate_story_fight` 25, `_validate_story_backdrop` 16, `_story_type_message` 4,
`_start_story_fight` 19, `_apply_story_backdrop` 31, `_build_story_trees` 25, `_spawn_story_enemy` 20,
`_on_story_enemy_died` 27. **Over 40:** `_start_random_encounter` 105 and `_start_boss_fight` 92 — both were longer
before (their body setup is now one builder call); splitting them would restructure the encounter and boss flow, which
the story puts out of scope. **User decision 2026-11-01:** recorded as a deviation; splitting them is TD-037.

## Deviations and notes

- **AC-1 source-text check is weak.** The tree data now sits in the `STORY_FIGHTS` table inside the same file, written
  as ints (`[-420, 38, 230]`) and converted with `float()`, so the old literal `[-420.0, 38.0, 230.0]` is absent
  trivially. The real guard for "no layout in code" is QA 5 with mutation (c). **User decision 2026-11-01:** recorded as weak; QA 5 and mutation (c) are the evidence for AC-1's "no layout literal".
- **Files outside the story's list:** `tests/run_all_tests.ps1` (one suite line, required by the layout test; usage
  comment 25 → 26 suites) and `story_fight_table_test.gd.uid` (written by Godot's import).
- `validate_story_fight` also type-checks the backdrop's sub-keys, and a row that is not a Dictionary is refused like an
  unknown id (beyond AC-3's list).
- The 17 `flash_tween` lines in the full run are TD-013 (unchanged by this story).

## Code review round 1 (2026-11-01): CHANGES REQUIRED → fixed

`/code-review` (GDScript specialist and QA tester, findings checked by the orchestrator) found three required changes; the
user chose to fix them and re-review.

1. **The validator passed rows that then failed mid-fight:** a `backdrop.trees` entry of the wrong length or with
   non-numbers (an out-of-bounds read after the tutorial slime is freed), a `flags` entry that is not a non-empty
   String (`set_story_flag` takes a String), an `enemy_script` that exists but is not a Script. Now each is refused,
   one message naming `backdrop.trees[i]`, `flags[i]` or `enemy_script`.
2. **AC-3 branches had no failing case:** added an optional key of the wrong type, `shard_color` not a Color,
   `backdrop` not a Dictionary, `backdrop.sky` and `path` of the wrong type, an unknown backdrop key, the three gaps
   above, and a row with two problems giving two messages.
3. **`validate_story_fight` had a cyclomatic complexity of about 14:** split into `_validate_story_required`,
   `_optional`, `_unknown`, `_script`, `_flags`, `_backdrop` and `_trees` (each 4–19 lines, complexity ≤ 7 by the
   implementer's estimate); the static signature is unchanged.

Suggestions folded in: `story_fight_table`'s doc comment says assign, never mutate (it starts as the read-only const),
and the row is typed at the merge; QA 4b (a row with `shard_count` 0 and `shard_fade` 1.2: no win at 0.9 s, the win at
1185 ms); two checks that were true by construction removed and the AC-1 text check renamed as weak; the test header
lists every private member it reads; the `RectangleShape2D` count check replaced by a per-function body check; QA 4
checks the test row's enemy has no loot table, the `suppress_base_rewards` meta and the row's controls line.

| Run | Result | Log |
|---|---|---|
| New cases before the validator change | 255 passed, 5 failed (exit 1): the trees length, non-numeric trees, `flags [5]`, `flags [""]` and `.tscn` script cases failed by name; the other new cases already held on the old validator | `review_fix_tests_before.log` |
| After, 3 in a row | 262/0 each, 11–15 s | `review_fix_after_1-3.log` |
| `story_fight_test` | 63/0 | `review_fix_story_fight.log` |
| Full local run after the fixes, 26 suites | all passed on 4.6.3 (table 262/0), 1560 s | `run_all_after_review.log` |
| Mutations (a)–(j) on the fixed code | every one caught by the same case as in round 1 (a: QA 4 and 9; b: 6, 7; c: 5; d: 9; e: 2, 3; f: 6; g: 10; h: 11; i: 8; j: 3) | `mutation_<id>.log` |

The checks added for suggestions s2–s6 were written after the before-run and were not watched failing on the old code.

## Story-done gates (2026-11-01)

- **QL-TEST-COVERAGE: GAPS (advisory).** Two gaps it named were closed at once with mutations on the fixed code:
  (l) the win waits a hard-coded 0.6 s instead of the row's `shard_fade` → 261/1, QA 4b fails ("0.9 s after the kill:
  no win signal yet", `mutation_l.log`); (h2) the boss body built at (900, 400) → 261/1, QA 11 fails (`boss.position`,
  `mutation_h2.log`). Its third gap: AC-8 names CI, which has not run this changeset.
- **LP-CODE-REVIEW: CONCERNS.** A new `enemy_type` with no entry in `ENEMY_SIZES` / `ENEMY_COLORS` silently gets the
  48×48 grey fallback (`_spawn_story_enemy`, `combat_arena.gd:941-942`; verified: no guardian or boar entry), so T13b/T13c
  would need an arena edit or ship a grey box.

## Row keys `enemy_size` / `enemy_color` (after LP-CODE-REVIEW, user decision 2026-11-01)

A row may set `enemy_size` (Vector2) and `enemy_color` (Color); `_spawn_story_enemy` uses them, else the
`ENEMY_SIZES` / `ENEMY_COLORS` entry for `enemy_type`. The validator (`_validate_story_enemy_look`) type-checks both and
refuses a row whose size or colour cannot be resolved, so the 48×48 grey fallback is gone from the story spawn. The
keys are declared in `STORY_FIGHT_OPTIONAL` (no default, nothing fake in the config); `ch1_slime` is unchanged, and the
golden cases pass untouched. `_spawn_story_shards`' doc comment now describes the row's shard beat, not "the slime".

| Run | Result | Log |
|---|---|---|
| New checks before the arena change | 262 passed, 15 failed (exit 1): all 15 new checks failed by name (4 in QA 2, 11 in QA 6b) | `rowkeys_tests_before.log` |
| After, 3 in a row | 277/0 each, 10–11 s | `rowkeys_after_1-3.log` |
| `story_fight_test` | 63/0 | `rowkeys_story_fight.log` |
| (m) the story enemy ignores the row's `enemy_size` | 273/4: QA 6b (sprite and shape size and offsets 48×48, not 70×50) | `mutation_m.log` |
| Full local run, final, 26 suites | all passed on 4.6.3 (table 277/0, story_fight 63/0), 1536 s | `run_all_final.log` |
| (e), (f) re-run on this code (their target code changed) | (e) 273/4: QA 2, QA 3; (f) 276/1: QA 6 | `mutation_e.log`, `mutation_f.log` |

## CI (AC-8)

CI run #49 on `973cb7d` (2026-11-01, https://github.com/Bhaskar-Bahukhandi/Ultimate-project/actions/runs/41309580612):
success in 24m54s on Godot 4.6.3 (Linux). Every step passed, including the whitespace and commit-message checks, "Story
fight" (40 s) and the new "Story fight table (TD-031 …)" step (8 s, limit 120 s).
