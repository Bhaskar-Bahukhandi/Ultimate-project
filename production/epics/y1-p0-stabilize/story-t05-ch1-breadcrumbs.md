# Story T05: Make the Chapter 1 breadcrumb objectives follow the rewritten route

> **Epic**: Y1-P0 Stabilize (Sprint 001)
> **Task ID**: Y1-P0-T05 (`production/plan/_source/Y1-P0.json#Y1-P0-T05`)
> **Status**: Ready
> **Layer**: Feature
> **Type**: Integration
> **Estimate**: 1.5 days (plan said 1; the two new flags, the resolver change and the scene-aware arrows add ~0.5)
> **Manifest Version**: N/A — `docs/architecture/control-manifest.md` does not exist
> **Last Updated**: [set by /dev-story when implementation begins]

## Context

**GDD**: none exists for Chapter 1 objectives. **Design source of record**:
`production/decisions/2026-10-audit-decisions.md` §4 (decision 4A: the flag-driven table in
`progression_breadcrumb.gd` is the source) and its "Approved strings" table (the 10 objective lines,
user-approved 2026-10-18), refined by the user's T05 decisions below.
**Requirement**: N/A — no TR-ID registered (`docs/architecture/tr-registry.yaml` holds no requirements).

**ADR Governing Implementation**: N/A — extends the existing objective table and its resolver; no
architectural decision is made.
**ADR Decision Summary**: N/A
**ADR Version**: N/A

**Engine**: Godot 4.6 (4.6.3 at `C:/Godot`) | **Risk**: HIGH (`docs/engine-reference/godot/VERSION.md`, 4.6 row)
**Engine Notes**: no post-cutoff API expected.

**Control Manifest Rules**: NOT ASSESSED — no control manifest.

**Performance**: no measurable impact expected. The table (42 entries) is resolved on the existing 2 s
Timer; the new resolver must not allocate per frame, and the arrow's scene check uses the scene path and
target node cached at refresh, not a per-frame lookup in `_process`.

**AGENTS.md protected areas**: story progression is protected. This story ADDS exactly two flag writes,
`ch1_broken_mile_entered` and `ch1_stew_done` (explicitly approved by the user 2026-10-19). Every other
flag write, combat, saves, Source Key and NG+ stay untouched.

### User decisions

2026-10-19:
1. **New flags**: add `ch1_broken_mile_entered` (a `set` line in `dialogue/ch1/broken_mile.dlg`, first node
   `tree_flicker`) and `ch1_stew_done` (set by `ch1_oakhaven_village.gd` after the stew run returns),
   registered in `story/STORY_BIBLE.md` §5 first. No dialogue text changes.
2. **Refuse path**: refusing the alarm skips step 7 and goes straight to step 8. Step 7 ends on
   `ch1_corrupted_boar_defeated` (`ch1_oakhaven_village.gd:426`), not the three `ch1_boar_*` flags.
3. **Hints**: Chapter 1 entries have no hint; the panel omits the empty hint line.
4. **Step 0**: keep "Find the plane. Look for survivors." (`crash_site.dlg:13`) before the 10 approved lines.

2026-10-20 (after QL-STORY-READY):
5. **Old saves**: a save made before T05 (no `ch1_stew_done`) shows step 5 until the alarm; there are no
   public saves yet.
6. **Chapter 1 end**: step 10 stays until `ch1_complete` (set in the shatter scene), not `ch1_elara_joined`.
7. **Arrows**: each Chapter 1 entry that has an arrow names its scene (`res://` path) and a target node path;
   the arrow aims at that node and hides in any other scene or when the node is missing.

### The Chapter 1 table (11 entries)

| # | Objective (exact text) | Shown from | Until (any of) |
|---|---|---|---|
| 0 | Find the plane. Look for survivors. | `ch1_opening_hook_started` | `ch1_crash_trace_seen` |
| 1 | Find people. A settlement east may know what happened to Flight 707. | `ch1_crash_trace_seen` | `elara_met` |
| 2 | Reach Oakhaven. Follow the first lead on the missing passengers. | `elara_met` | `ch1_broken_mile_entered` |
| 3 | Get through the Broken Mile with Elara. | `ch1_broken_mile_entered` | `ch1_personal_goal_set` |
| 4 | Ask about Flight 707. Find a safe route to Ironhold. | `ch1_personal_goal_set` | `ch1_oakhaven_entered` |
| 5 | Go to Elara's house. She's making stew. | `ch1_oakhaven_entered` | `ch1_stew_done` |
| 6 | Spend the afternoon in Oakhaven. Meet the people here. | `ch1_stew_done` | `ch1_north_field_helped`, `ch1_north_field_refused` |
| 7 | Answer the alarm in the north field. | `ch1_north_field_helped` | `ch1_corrupted_boar_defeated` |
| 8 | Deal with the north bridge before dark. | `ch1_corrupted_boar_defeated` or `ch1_north_field_refused` | `ch1_bridge_repair_accepted`, `ch1_bridge_evacuated`, `ch1_bridge_ignored` |
| 9 | Stop Aldric. | any of step 8's end flags | `ch1_tutorial_knight_defeated` |
| 10 | Go down to the shrine. Then decide what to tell the village. | `ch1_tutorial_knight_defeated` | `ch1_complete` |

Cumulative flag sets used by the tests: S0 = {`ch1_opening_hook_started`}; S1 = S0 + `ch1_crash_trace_seen`;
S2 = S1 + `elara_met`; S3 = S2 + `ch1_broken_mile_entered`; S4 = S3 + `ch1_personal_goal_set`;
S5 = S4 + `ch1_oakhaven_entered`; S6 = S5 + `ch1_stew_done`; S7 = S6 + `ch1_north_field_helped`;
S8 = S7 + `ch1_corrupted_boar_defeated`; S9 = S8 + `ch1_bridge_repair_accepted`;
S10 = S9 + `ch1_tutorial_knight_defeated`.

---

## Acceptance Criteria

*From decision 4A, the approved strings and the user's T05 decisions:*

- [ ] AC-1 The 3 stale opening-hook entries ("Stand up. Find a signal.", "Follow the Oakhaven signal.",
      "Reach Oakhaven." with "a village that should not know your name") and the 3 stale "Chapter 1"
      entries ("Survive the crash site", "Defeat the Corrupted Sentinel", "Explore Oakhaven & find Elara")
      are replaced by the 11 entries above, text exactly as written. Every flag named in the table has at
      least one writer in `dialogue/` or `scripts/`.
- [ ] AC-2 An entry's `required` and blocker conditions accept an "any of" list of flags. For every Chapter 2+
      entry, the resolved (text, hint, target) for a fixed set of flag sets is identical before and after T05
      (golden baseline captured from HEAD before any edit), and a set containing `ch1_complete` resolves to
      Chapter 2, never to a Chapter 1 step.
- [ ] AC-3 Chapter 1 resolves from the **latest** end flag backwards: the shown step is the one after the
      last step whose end flag is set (so S10 with `ch1_stew_done` removed still shows step 10). An alarm that
      fires early (walking to the north field or the bridge) moves the breadcrumb with it. A save made before
      T05 (no `ch1_stew_done`, no afternoon end flag) shows step 5 until the alarm (decision 5).
- [ ] AC-4 An entry with an empty hint shows only the objective line: no `[i]`, no empty second line, no
      trailing line break. An entry with a hint renders byte-for-byte as before.
- [ ] AC-5 Each Chapter 1 entry either has no arrow, or names its scene (`res://` path) and a target node path
      in that scene; the arrow aims at that node, and is hidden when the current scene is not the entry's
      scene or the node is missing. Chapter 2+ arrows behave as before.
- [ ] AC-6 `ch1_broken_mile_entered` is set by a `set` line in the first node of `broken_mile.dlg`
      (`tree_flicker`), before any choice. `ch1_stew_done` is set by `ch1_oakhaven_village.gd` when the stew
      dialogue run returns while the village scene is still current, on every path: topics then "(Just eat.)",
      "(Just eat.)" straight away, and a skip-all; it is not set if the scene is left mid-run, and not before
      the run returns. Both are listed in `STORY_BIBLE.md` §5. At the end of the kill route and the refuse
      route, the final flag set differs from the pre-T05 one by exactly these two flags.
- [ ] AC-7 Exactly four `do objective` lines exist in `dialogue/ch1/*.dlg`, and each equals the table text of
      its step: `crash_site.dlg:13` = step 0, `crash_site.dlg:36` = step 1, `elara_meeting.dlg:90` = step 2,
      `broken_mile.dlg:151` = step 4. No `.dlg` spoken text changes.
- [ ] AC-8 `chapter1_route_test` covers: the pure-resolver sweep S0..S10 (steps 0–10, exact text); the kill
      route sampled at each step's start flag (state forced to EXPLORATION); the refuse route (step 6 → step 8;
      `ch1_north_field_helped` never set) and the hesitate-then-help path (step 7); each of the three bridge
      end flags (step 9); and the load cases of AC-3.
- [ ] AC-9 `dialogue_test` and the full suite (`run_all_tests.ps1`) pass; `git diff --check` is clean; a
      **live-renderer** screenshot of a Chapter 1 breadcrumb in the HUD is retained under
      `production/qa/evidence/2026-10-breadcrumbs/` (a headless/dummy-renderer capture does not count).

---

## Implementation Notes

- **Assertion surface.** `_refresh_objective()` (`progression_breadcrumb.gd` ~461) returns before updating
  `_current_objective` when `GameManager.current_state != EXPLORATION` (~466–469), so inside the
  dialogue-driven route harness `get_current_objective()` can be stale and `force_refresh()` does nothing.
  Add a public, doc-commented pure resolver, e.g. `resolve_objective(flags: Dictionary) -> Dictionary`
  returning `{text, hint, scene, target}`, used by `_refresh_objective()` and by the tests. Integration reads
  force `current_state = EXPLORATION` before `force_refresh()`. Add a read accessor for the rendered label
  text for AC-4 (the label is private).
- **Resolver.** Add list forms (e.g. `required_any`, `blockers`) and keep the old keys (`required`,
  `blocker`, `blocker_alt`) working for Chapter 2+. AC-3 can be a dedicated Chapter 1 pass or latest-first
  ordering with "any later end flag" as an extra blocker — the programmer's call, as long as AC-3 holds.
- **Golden baseline (AC-2).** Before changing the resolver, capture (text, hint, target) for: each Chapter 2+
  entry's `required` flag with its blockers unset; the chapter-jump presets in `main_menu.gd` (~427–472); and
  {`ch1_complete`, `ch1_oakhaven_entered`, `ch1_tutorial_knight_defeated`}. Store it beside the test.
- **Arrows (AC-5).** `region` is ignored by `_refresh_objective()`/`_process()` today. Chapter 1 entries gain
  `scene` + `target_node`; resolve the node's position at refresh and cache it. Steps 1–3 run in the crash
  site, Elara meeting and Broken Mile scenes; entries whose scene has no sensible target get no arrow.
- **Flow facts.** The alarm and the whole field run in one go (`_run_north_field`, `ch1_oakhaven_village.gd`
  ~399): refusing runs `field_refused_aftermath` and sets no boar flag; walking to the bridge first runs the
  field first (`_on_bridge_trigger`, ~434). Refusing takes two choices: "This isn't my..." (index 1) then
  "I'm staying here." (index 1), i.e. picks `[1, 1]`; gate and stew choices also consume picks, so queue
  them only after the village entrance is done.
- Add a short CHANGELOG entry. Commit only with the user's OK, with `Task: Y1-P0-T05` in the body.

---

## Out of Scope

- Chapter 2+ objective text and targets (only the shared resolver/display changes touch them, and AC-2
  keeps them identical).
- The separate `do objective` HUD system and the quest log.
- Any `.dlg` spoken text (only the one `set` line in `broken_mile.dlg`).
- Other flag writes, combat, saves, NG+ (AGENTS.md).

---

## QA Test Cases

*Reviewed by qa-lead (QL-STORY-READY, 2026-10-20: GAPS → cases below adopted). The route test is the
project's custom SceneTree suite (`_check`, `_start`), not gdUnit4: keep its `_test_*` style, one function
per case group. Watch each new case fail against the unchanged resolver before trusting it.*

- **AC-1a table text** — Given `reset_game()` and each of S0..S10 in turn; When `resolve_objective()` runs;
  Then the text equals the step's exact table text (from a constant in the test), and none of the six stale
  strings exists in `OBJECTIVES`.
- **AC-1b flag writers** — Given every flag named in the table; When `dialogue/ch1/*.dlg` (`set <flag>`) and
  `scripts/` (`set_story_flag("<flag>"`) are scanned; Then each flag has at least one writer.
- **AC-2a regression** — Given the golden baseline; When the new resolver runs on each set; Then (text, hint,
  target) matches for every set, and the `ch1_complete` set resolves to the Chapter 2 entry.
- **AC-2b any-of** — Given a synthetic entry with `required_any = [A, B]` and a two-flag `blockers` list;
  Then it is eligible with only B set, not with neither; and blocked by either blocker flag.
- **AC-3a old save** — Given {`ch1_oakhaven_entered`, `ch1_personal_goal_set`, `elara_met`, `ch1_mara_met`},
  no `ch1_stew_done`, no `ch1_broken_mile_entered`; Then step 5's exact text (decision 5).
- **AC-3b early alarm** — Given S6 + `ch1_north_field_helped`, no boar flag; Then step 7. Given the same +
  `ch1_corrupted_boar_defeated`; Then step 8. Integration: village entrance done, picks `[0]`, no afternoon
  beats; When `_on_bridge_trigger(player)` (or `_run_north_field()`); Then `ch1_corrupted_boar_defeated` is
  set and a forced refresh shows step 8.
- **AC-3c later flag wins** — Given S10 with `ch1_stew_done` removed; Then step 10.
- **AC-3d chapter end** — Given S10 + `ch1_elara_joined`, no `ch1_complete`; Then step 10. Given + `ch1_complete`;
  Then the Chapter 2 entry.
- **AC-4 empty hint** — Given a Chapter 1 entry current, state EXPLORATION; When the display updates; Then the
  label text has the objective line and no `[i]`, `[/i]` or trailing `\n`. Given a Chapter 2 entry with a
  hint; Then the label text equals the old format string byte for byte.
- **AC-5 arrow** — Given each Chapter 1 entry with a target and its scene loaded; Then the target node exists
  and the arrow is non-empty when the player is more than 100 px away. Given the same entry with a different
  scene current, or the node missing, or an entry with no target; When one `_process` frame runs; Then the
  arrow text is "".
- **AC-6a broken mile flag** — Given `reset_game()`; When `broken_mile.dlg` runs from `tree_flicker`; Then
  `ch1_broken_mile_entered` is set before the first choice. Running any other node first does not set it.
- **AC-6b stew flag** — One case per path: topics then "(Just eat.)"; "(Just eat.)" straight away; skip-all.
  Then `ch1_stew_done` is set after the run returns and not before. Given the scene is left mid-run; Then it
  is not set.
- **AC-6c no other flag changes** — Given the final flag sets at the end of the kill and refuse routes,
  captured on HEAD before T05; Then after T05 they differ by exactly {`ch1_broken_mile_entered`,
  `ch1_stew_done`}; and both appear in `STORY_BIBLE.md` §5.
- **AC-7 do-objective lines** — Given all `^do objective (.+)$` lines in `dialogue/ch1/*.dlg`; Then exactly
  four exist and each equals its step's text (0, 1, 2, 4).
- **AC-8a kill route** — Given the kill-route driver; When each step's start flag is set (state forced to
  EXPLORATION); Then steps 0–10 show in order with exact text.
- **AC-8b refuse route** — Given village entrance done, `_start([1, 1])`, then the alarm; When
  `ch1_north_field_refused` is set and the aftermath ends; Then `ch1_north_field_helped` is not set and a
  forced refresh shows step 8 (it showed step 6 before the alarm). Pure case: S6 + refused → step 8. Do not
  assert "step 7 never shown" from `objective_changed` history (refresh is suppressed outside EXPLORATION, so
  it would pass vacuously). Hesitate-then-help (`[1, 0]`): helped set → step 7.
- **AC-8c bridge flags** — Given S8 with each of `ch1_bridge_repair_accepted`, `ch1_bridge_evacuated`,
  `ch1_bridge_ignored` in turn, and S6 + refused + each; Then step 9 every time.
- **AC-9** — the suites pass and `git diff --check` is clean (mechanical); the live-renderer HUD screenshot is
  taken in `/dev-story` Phase 6 and must be on disk before Done.

---

## Test Evidence

**Story Type**: Integration
**Required evidence**: `tests/integration/story/chapter1_route_test.gd` (extended) passing, with the golden
baseline beside it and a log in `production/qa/evidence/2026-10-breadcrumbs/`; the HUD screenshot in AC-9.

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Y1-P0-T03 (done), Y1-P0-S02 breadcrumb lines (approved 2026-10-18; S02 itself stays in progress
  for the T06/T08 strings), Y1-P0-T04 (Complete; shares `chapter1_route_test.gd`). T03 and S02 have no story
  files by sprint decision; their status is in `production/sprint-status.yaml`.
- Unlocks: Y1-P0-S07 (Act 1 playtest).
