# TD-038 evidence: a story-fight row's enemy script must extend EnemyBase

Story: `production/epics/y1-p0-stabilize/story-td038-story-enemy-base-check.md`. Every run here is on **Godot 4.6.3**
(`GODOT` set to the 4.6.3 console exe, TD-036; each log's Godot line says so). Arena:
`AethelgardPrototype/scripts/combat/combat_arena.gd`. Suite:
`AethelgardPrototype/tests/integration/combat/story_fight_table_test.gd` (303 checks, was 277).

## What changed

- `_story_script_extends_enemy_base(script: Script) -> bool` (static, 7 lines, 2 branch points) walks
  `get_base_script()` and compares with the `EnemyBase` script.
- `_validate_story_script` (8 lines, 2 branch points) loads the path once and hands the resource to
  `_validate_story_script_class` (6 lines, 2 branch points), which keeps the "is not a Script" message and adds
  `key 'enemy_script': '<path>' does not extend EnemyBase`. **Deviation:** the story named one function; adding the
  refusal gave it 4 branch points, so it was split to keep each at 3 or fewer. The two existing messages are unchanged.

## Runs

| Run | Result | Log |
|---|---|---|
| New cases before the change (unchanged arena) | 295 passed, 5 failed (exit 1): TD-038 QA 1, QA 5 (helper missing), 5a, 5b, 5c failed by name; QA 2 passed, as a no-false-refusal check must | `tdd_before_change.log` |
| After, 3 in a row | 300/0 each | `after_1-3.log` |
| `story_fight_test` | 63/0 | `story_fight_after.log` |
| Full local run, 26 suites | all passed on 4.6.3 (table 300/0, story_fight 63/0), 1577 s | `run_all_after.log` |

## Mutations (AC-3)

`td038_mutate.py` (TD-031's harness with this story's three mutations): one mutation per invocation, the arena restored
byte for byte (SHA-256 checked).

| Mutation | Expected case | Result |
|---|---|---|
| (a) the validator no longer uses the EnemyBase helper | QA 1 | 299/1: QA 1 (`mutation_a.log`) |
| (b) the EnemyBase check always refuses | QA 2 | 108/177: all 17 QA 2 enemy scripts, plus the slime fight and every row case (`mutation_b.log`) |
| (c) the walk checks one level only | QA 5a | 299/1: QA 5a, `slime.gd`'s child (EnemyBase two levels up) (`mutation_c.log`) |

## QA case 6, by hand (not in the suite)

`td038_parse_check.gd.txt`, run headless on 4.6.3 with an isolated `user://`: it wrote
`user://td038_parse_error.gd` (`extends EnemyBase` with a syntax error), validated a copy of the `ch1_slime` row
pointing at it, and deleted the file. Result (`qa6_parse_error_by_hand.log`): **exactly one message, no crash**, the
temp file removed, no Godot process left. The message is `… does not extend EnemyBase`, not `… is not a Script`:
Godot 4.6.3 returns a Script object for the broken file (its `reload()` fails, so it has no base script), and prints
its own `Parse Error` beside it. A committed broken script would fail the runner's `Parse Error` rule (TD-003), so
this stays a hand check.

## Notes

- QA 2 lists the folder from the project (`DirAccess.get_files_at`), 17 `*.gd` files today (floor 17; `*.gd.uid`
  skipped). An exported build lists `.remap` files; the suite only runs from the project.
  The listing is not recursive (`DirAccess.get_files_at`): a new enemy script must sit directly in
  `scripts/combat/enemies/` to be checked (T13b's `broken_mile_guardian.gd` and T13c's `field_boar.gd` are planned
  there). Code review, 2026-11-01: noted here rather than recursing.
- QA 2 proves validation only: a boss script passing the check says nothing about whether it works as a story enemy.
- Run result: N/A — nothing on screen changes; the `ch1_slime` golden checks stay green in the suite.

## Code review (2026-11-01): APPROVED WITH SUGGESTIONS, applied

`/code-review` (GDScript specialist and QA tester, findings checked by the orchestrator): no required change. Applied:
the `validate_story_fight` doc comment rewrapped to ≤ 120 chars; the three in-memory script sources use `\n` escapes;
QA 5 pins the chain shape (5a's base is `slime.gd`, 5b's script can instantiate, 5c's base is the arena script); two
long test lines wrapped; the non-recursive folder listing noted above. Suite 303/0 ×3 on 4.6.3
(`review_fix_after_1-3.log`); arena code unchanged by the fixes.

## Story-done gates (2026-11-01)

- **QL-TEST-COVERAGE: ADEQUATE.** Every AC and QA case covered; watched-failing evidence ties to the named cases
  (mutation b also fails older cases because it refuses the slime row too; QA 2 still names all 17 scripts).
- **LP-CODE-REVIEW: CONCERNS (minor), fixed.** A script with a parse error got "does not extend EnemyBase", which would
  send an author after the wrong problem. The message is now `… does not extend EnemyBase (or failed to compile; see
  Godot's error above)`. A first wording that named the engine's parse-error text failed the runner's TD-003 rule
  (QA 1 prints the message) and was reverted. Its logs were overwritten by the final wording's runs, so no log of the
  failed attempt is kept.
  With the final wording: 303/0 ×3, no `RUNNER FAIL` (`wording_after_1-3.log`); mutation (a) re-run, still caught by
  QA 1 (`mutation_a.log`); QA 6 redone by hand, one message with the new wording, temp file removed
  (`qa6_parse_error_by_hand_v2.log`).
- The full local run (`run_all_after.log`, 26/26) was on the code before the review fixes and the wording change; those
  touched only this suite's TD-038 cases, one doc comment and one message string, re-verified by the runs above.

## CI (AC-3)

CI run #51 on `bbc45b2` (2026-11-01 23:59 UTC, https://github.com/Bhaskar-Bahukhandi/Ultimate-project/actions/runs/41364767402):
success in 24m48s on Godot 4.6.3 (Linux). Every step passed, including the whitespace and commit-message checks, "Story
fight" (40 s) and "Story fight table (TD-031 …)" (9 s, limit 120 s).
