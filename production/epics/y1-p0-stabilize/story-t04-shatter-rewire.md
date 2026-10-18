# Story T04: Rewire the Chapter 1 shatter scene to shatter.dlg

> **Epic**: Y1-P0 Stabilize (Sprint 001)
> **Task ID**: Y1-P0-T04 (`production/plan/_source/Y1-P0.json#Y1-P0-T04`)
> **Status**: Ready
> **Layer**: Feature
> **Type**: Integration
> **Estimate**: 2 days
> **Manifest Version**: N/A — `docs/architecture/control-manifest.md` does not exist
> **Last Updated**: [set by /dev-story when implementation begins]

## Context

**GDD**: none for Chapter 1 story. Design sources: `production/decisions/2026-10-audit-decisions.md` §3
(decision 3B) and `AethelgardPrototype/story/STORY_BIBLE.md` §5 (Chapter 1 flags).
**Requirement**: `TR-story-???` — WARNING: `docs/architecture/tr-registry.yaml` holds only commented
examples; no TR-ID exists for this work.

**ADR Governing Implementation**: N/A — wires approved dialogue through the existing
`DialogueManager.run(file, node, on_event)` API, the pattern every other Chapter 1 scene uses; no
architectural decision is made.
**ADR Decision Summary**: N/A
**ADR Version**: N/A

**Engine**: Godot 4.6 (4.6.3 at `C:/Godot`) | **Risk**: HIGH (`docs/engine-reference/godot/VERSION.md`, 4.6 row)
**Engine Notes**: no post-cutoff API is expected; await/Callable usage matches `ch1_elara_meeting.gd:194`.

**Control Manifest Rules**: NOT ASSESSED — no control manifest.

**AGENTS.md protected areas**: story progression is protected. This story READS story flags only.
The existing writes in `ch1_shatter_transition.gd` (`ch1_shatter_witnessed`, `ch1_complete`,
`current_chapter`, `ch1_aldric_outcome_reward_claimed`) must stay byte-identical and in the same order.

---

## Acceptance Criteria

*From decision 3B and the T04 plan entry, scoped to this story:*

- [ ] AC-1 The scene holds no spoken story lines before the end card. With
      `const SHATTER_DLG := "res://dialogue/ch1/shatter.dlg"`, it runs four nodes through
      `await DialogueManager.run(SHATTER_DLG, node, _on_dlg_event)`:
      `bridge` in `play_bridge_approach()` (replacing the cutscene `dialogue` beats, after the enter beats
      and before the walk to mid-bridge), `shift` in `play_environmental_shift()`, `reconstruct` in
      `play_the_shatter()` (replacing the System line at :309, screen still black), and `start` in
      `play_post_shatter_dialogue()`. No `DialogueManager.say(` and no `"type": "dialogue"` beat remains in
      those four functions, and their solo/`has_elara` branches and local flag variables are removed.
- [ ] AC-2 `_on_dlg_event(event: String)` handles:
      `desaturate` (starts the existing modulate tween to `Color(0.6, 0.6, 0.7)` over 3.0 s, **not
      awaited** at the event, but awaited before `play_environmental_shift()` returns, as today);
      `shake` (the existing `camera.shake(4.0, 0.5)` plus its 1.5 s wait);
      `pan_ironhold` (hide dialogue, `camera.move_to(Vector2(640, 320), 2.0)`, wait 2.5 s, as the old beat did);
      `look_back` (a visible beat, e.g. a short camera nudge toward the left/Oakhaven side; the exact move is
      the programmer's call, but it must not be a no-op). Any other event pushes a warning and returns at once
      (no hang). Each effect exists once: the old inline tween/shake calls are moved, not duplicated.
- [ ] AC-3 `chapter1_route_test` gains a **spare route** to the shatter scene (today only kill and purge
      reach it).
- [ ] AC-4 For the kill, spare and purge routes, the test asserts the first line of `after_kill` /
      `after_spare` / `after_purge` is shown, and that **purge never shows `after_spare`'s first line**.
- [ ] AC-5 Routing check of `shatter.dlg` with flags preset (no full route): the 4 Aldric routes ×
      4 village routes (`warned_villagers`, `warned_leaders`, `left_quietly`, none) each reach `onward` and END.
- [ ] AC-6 Old save: no Aldric flag and no village flag → `after_none` + `village_none`; the scene continues
      to the end card.
- [ ] AC-7 Purge cancelled ("No. Not like this. Hold him instead." in `aldric.dlg`) → only
      `ch1_knight_spared` is set (not `ch1_root_purge`) → the shatter scene plays `after_spare`.
- [ ] AC-8 Hold-to-skip during the `.dlg` run: the run stops (`ok = false`), `ch1_shatter_witnessed` and
      `ch1_complete` are set, the Aldric reward is granted exactly once, and the scene changes exactly once.
- [ ] AC-9 On every route, no shown line contains "412", "iterations", "at that bridge", "AetherCorp",
      "Chapter 1", "side-scroll", "top-down", "gravity", "Welcome to" or a `*stage direction*`.
- [ ] AC-12 Hold-to-skip during `bridge`, `shift` or `reconstruct` behaves as AC-8 (run stops, flags set,
      reward once, one scene change), and no later node starts after the skip.
- [ ] AC-10 `dialogue_test` passes; the full suite (`run_all_tests.ps1`, 10 suites) passes; `git diff --check` is clean.
- [ ] AC-11 Evidence: `production/qa/evidence/2026-10-shatter/{kill,spare,purge}.png` from a **live
      renderer**, each showing a line from that route's Aldric node, retained via
      `run_screenshots.ps1 -Evidence 2026-10-shatter`.

---

## Implementation Notes

- Pattern to copy: `ch1_elara_meeting.gd:194–207` (`run` + `_on_dlg_event`).
- `run()` stops itself when the scene exits or `force_reset()` is called (`dialogue_manager.gd:485–491`);
  `_on_skip_cutscene` already calls `force_reset()`, so after the await, check
  `is_inside_tree() and cinematic_active` as the old code did.
- The existing tour stop `ch1_shatter` (`scripts/debug/screenshot_tour_runner.gd:28`) shoots at 3.0 s,
  during the bridge approach. AC-11 needs new stops (e.g. `ch1_shatter_kill` / `_spare` / `_purge`) that
  preset the flags and capture during the Aldric node. Adding tour stops is in scope.
- Add a short CHANGELOG entry. Commit only with the user's OK:
  `fix(story): shatter scene follows the Ch1 rewrite` with `Task: Y1-P0-T04` in the body.

---

## Out of Scope

- The end card text and rewards (`play_chapter_end_card`: "Corrupted Sentinel", "RAM: 13GB"): stale, but
  not part of decision 3. Bug-list candidate (S05).
- The `has_elara` checks outside `play_post_shatter_dialogue()`, any story flag write, the Chapter 2 scenes.
- Editing `shatter.dlg` text (approved 2026-10-18, commits `45e90d0` post-shatter and `efe1861`
  pre-shatter; any change goes back to the user).
- Which bridge this is (the bible's deadline "north bridge" vs Bran's "The bridge is south",
  `oakhaven_village.dlg:107`): an open lore/layout question. The lines never mention a repair, so they hold
  on every `ch1_bridge_*` outcome.

---

## QA Test Cases

*qa-lead QL-STORY-READY gate NOT RUN; these were drafted by the orchestrator from the ACs. Run
`/story-readiness` before `/dev-story` to have qa-lead review them.*

- **AC-4**
  - Given: a New Game driven through `aldric.dlg` with [kill | spare | purge_confirm]
  - When: the shatter scene's dialogue starts
  - Then: the lines captured from `dialogue_line_shown` include that node's first line
  - Edge cases: purge → assert `after_spare`'s first line is absent
- **AC-5**
  - Given: story flags preset per combination
  - When: `shatter.dlg` runs from `start`
  - Then: the result is `ok = true` and the last line shown is `onward`'s last line
- **AC-7**
  - Given: `aldric.dlg` at the purge prompt
  - When: choice 2 is taken
  - Then: `ch1_root_purge` is false, `ch1_knight_spared` is true, and the shatter scene shows `after_spare`
- **AC-8**
  - Given: the scene inside the `.dlg` run
  - When: `ui_cancel` is held 1.5 s
  - Then: the scene changes once to `ironhold_gate.tscn`, the flags are set and the reward count rises by one

---

## Test Evidence

**Story Type**: Integration
**Required evidence**: `tests/integration/story/chapter1_route_test.gd` (extended) passing, with a log
in `production/qa/evidence/2026-10-shatter/`; the three PNGs in AC-11.

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Y1-P0-T02 (done), Y1-P0-T03 (done), Y1-P0-S02 shatter text (approved and lint-green
  2026-10-18, `45e90d0` + `efe1861`). There are no story files for these; their status is in `production/sprint-status.yaml`.
- Unlocks: Y1-P0-S08, Y1-P0-T13a
