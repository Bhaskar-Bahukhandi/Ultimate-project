# Story T10: Fix the fallback-warning spam, the growing `_bound_texts` list and the cursor texture leaked at exit

> **Epic**: Y1-P0 Stabilize (Sprint 001)
> **Task ID**: Y1-P0-T10 (`production/plan/_source/Y1-P0.json#Y1-P0-T10`)
> **Status**: Ready
> **Layer**: Foundation
> **Type**: Integration
> **Estimate**: 2 days
> **Manifest Version**: N/A — `docs/architecture/control-manifest.md` does not exist
> **Last Updated**: 2026-10-24

## Context

**GDD**: none (stability cleanup). **Source of record**: the plan entry above ("Known leftovers: fallback-slot
push_warning spam, input_service `_bound_texts` growth, 'Texture leaked at exit'"; done when "Route-test log warnings
drop to one per slot; bound-text test passes" and "Clean exit log with no leaked RID line, saved as evidence"), and
`production/qa/evidence/2026-10-test-layout/README.md:15` ("the tour's exit prints '1 RID allocations … leaked at
exit' (Y1-P0-T10)").
**Requirement**: N/A — no TR-ID registered.

**ADR Governing Implementation**: N/A — three local fixes (a warn-once guard, list pruning, one lifecycle hook); no
architectural decision is made.
**ADR Decision Summary**: N/A
**ADR Version**: N/A

**Engine**: Godot 4.6 (4.6.3 at `C:/Godot`) | **Risk**: HIGH (`docs/engine-reference/godot/VERSION.md`, 4.6 row)
**Engine Notes**: no post-cutoff API is added. `Input.set_custom_mouse_cursor(null, Input.CURSOR_ARROW)` restores the
default cursor (verified on 4.6.3 in a scratch worktree, below). `WeakRef.get_ref()` keeps returning a
`queue_free()`d node until the end of that frame; only `free()` clears it at once. Renderer leaks are reported only
with a real renderer: the headless/dummy driver used by CI and the test runners never prints them.

**Control Manifest Rules**: NOT ASSESSED — no control manifest.

**Performance**: `bind_text()` already walks the whole list to de-duplicate; pruning in that same pass adds no extra
walk. The warn-once guard is one dictionary lookup per fallback warning. No hot-path change; not measured.

**AGENTS.md protected areas**: none touched. Fallback behaviour of production art is preserved: only the
`push_warning` calls change; every fallback return value, slot dictionary and load path stays as it is. The
`game_manager.gd` change is one new `_exit_tree()` that resets the cursor; no save, story, NG+, Source Key or world-map
code is edited. Files: `AethelgardPrototype/scripts/asset_manager.gd`, `scripts/core/input_service.gd`,
`scripts/game_manager.gd` (new `_exit_tree()` only), `tests/unit/input/input_bound_texts_prune_test.gd` and its
`.uid` (new), `tests/suite_limits.txt`, `tests/run_all_tests.ps1`, `.github/workflows/ci.yml` (one test step),
`tests/run_exit_scan.ps1` (new, local only), `AethelgardPrototype/CHANGELOG.md`, `docs/tech-debt-register.md`
(TD-012), evidence, this story.

### Audit facts (2026-10-24, read-only, re-checked in the main session)

**1. Fallback-warning spam (`scripts/asset_manager.gd`)**
- `production/qa/evidence/2026-10-autoloads/run_all.log` (full suite, 17 suites, this checkout) has **494** `WARNING`
  lines, **463** of them `WARNING: [AssetManager] …`, only **26 distinct** messages. Per suite (total / AssetManager /
  distinct AssetManager): chapter1_route 78 / 73 / 14, phase0_blockers 107 / 97 / 22, chapter2_route 88 / 87 / 14,
  reachability 82 / 81 / 12, act1_quests 75 / 74 / 14. Ten suites print AssetManager warnings at all (lines per
  suite: phase0_blockers 97, chapter2_route 87, reachability 81, act1_quests 74, chapter1_route 73, context_stack 25,
  input 11, screen_flash 8, combat_fixes 5, dialogue 2). Top repeats: V3 prop atlas missing 134, V3 decal atlas missing
  98, V2 top-down player sheet missing 77, V2 combat sheet 22, Ironhold tileset fallback 18, NPC sheet (Elara) 17.
  Projected full-suite total after a per-message guard: about 102.
- The production art these slots point at was removed from this checkout by commit `abcf40c` (2026-10-04), so the
  counts above are valid for this art-less checkout only; with the art present most of these warnings never fire.
- `asset_manager.gd` has 26 `push_warning` sites. **Four** already warn once through `var _missing_production_art_warned
  := {}` (:445): `_warn_missing_production_art` (func :1133, `push_warning` :1137, keyed by `production_path`) and the
  three Oakhaven helpers (`push_warning` :1227, :1234, :1241, keyed by composite strings). The other **22** warn on
  every call: :930, :992, :994, :1007, :1009, :1032, :1051, :1074, :1112, :1207, :1211, :1283, :1287, :1337, :1341,
  :1384, :1409, :1513, :1518, :1532, :1553, :1569 (some pairs are two branches of one site). Two of them stay loud
  (below), so **20** are converted.
- **Key collision**: `_warn_missing_production_art` is keyed by `production_path` alone, and both
  `_try_load_ironhold_production_tileset` (:1275) and the Fractured Wastes loader (:1329) call it when that path is
  empty, so whichever runs second is silenced although its slot label differs.
- Two sites flag code or data bugs rather than missing art and must stay loud: :930 (`Cannot get Image from texture
  for sheet slicing`) and :1513 (`Unknown V3 environment visual: <id>`). Neither appears in `run_all.log`.

**2. `_bound_texts` growth (`scripts/core/input_service.gd`)**
- `var _bound_texts: Array = []` (:99) holds `{ref: WeakRef, template, property}`. `_refresh_bound_texts()` (:281)
  already drops dead entries, but it runs only on a device switch (:127, :132, :167), a rebind (:452),
  `reset_to_defaults()` (:461) and `load_bindings()` (:573, once from `_ready` :110). `bind_text()` (:269, append at :277) never
  prunes, so in a keyboard-only session every UI rebuild appends entries for nodes that are later freed and nothing
  removes them until the player touches a gamepad.
- 39 `bind_text` calls in 16 files, all in scene/UI build code. `tests/integration/input/input_test.gd:257-279`
  binds a label, frees it, and checks only `_check(true, "freed bound labels are dropped safely")`.
- Tests reach the service as the live autoload (`get_root().get_node("InputService")`, `input_test.gd:66`), so other
  autoloads' bindings may already be in the list when a test starts.

**3. Texture RID leaked at exit (`scripts/game_manager.gd`)**
- With a real renderer, a plain boot, a boot to the main menu, and the full screenshot tour each end with:
  `ERROR: 1 RID allocations of type 'N10RendererRD14TextureStorage7TextureE' were leaked at exit.`,
  `ERROR: Parameter "RenderingServer::get_singleton()" is null.` (at `~ImageTexture`, `image_texture.cpp:230`) and
  `WARNING: 2 RIDs of type "Texture" were leaked.` (at `finalize`, `rendering_device.cpp:7505`).
- Root cause: `GameManager._setup_custom_cursor()` (:2114, called from `_ready` :644) builds an `ImageTexture` and
  passes it to `Input.set_custom_mouse_cursor(tex, Input.CURSOR_ARROW, …)` (:2147-2148). `Input` keeps that reference
  past `RenderingServer` teardown. `GameManager` has no `_exit_tree()` or `_notification()`; no other script calls
  `set_custom_mouse_cursor`.
- In a scratch worktree, adding `func _exit_tree() -> void: Input.set_custom_mouse_cursor(null, Input.CURSOR_ARROW)`
  removed all three lines from the plain boot, the main-menu boot and the full 59-shot tour. Dropping the cursor code
  also removed them, but changes what players see.
- A separate shutdown leak (`Leaked instance: AudioStream…`, `ObjectDB instances leaked at exit`) appears in some
  runs (14 such lines in `run_all.log`). It is audio, not this texture, and goes to the register as TD-012.

### User decisions (2026-10-24)

1. **Leak**: keep the custom cursor; reset it in a new `GameManager._exit_tree()`.
2. **Warn once per message, per run**: route the repeating `push_warning` calls through one helper keyed by the
   formatted message, reusing `_missing_production_art_warned` (which also ends the empty-key collision). :930 and
   :1513 stay loud. No exit summary line. Fallback return values untouched.
3. **`_bound_texts`**: prune in `bind_text()`; the new suite reads `InputService._bound_texts` directly (no new public
   API).
4. **Exit-leak proof**: a local real-renderer exit scan kept as evidence (CI is headless and cannot see renderer
   leaks); the AudioStream/ObjectDB leak is logged as its own tech-debt item.

---

## Acceptance Criteria

- [ ] AC-1 **Warn once per message.** `asset_manager.gd` has a helper (e.g. `_warn_once(message: String) -> bool`)
      that prints `push_warning(message)` the first time a message is seen in a run and returns `true`, and returns
      `false` without printing afterwards; it stores its keys in `_missing_production_art_warned`. Every
      `push_warning` site listed in audit fact 1 goes through it except :930 and :1513, which are unchanged. The four
      existing guarded helpers keep their behaviour and are keyed by message (so an empty `production_path` no longer
      silences a different slot). `git diff` of `asset_manager.gd` changes only warning lines, the helper, and the
      has/set guard lines inside the four existing helpers: no return value, slot dictionary key, load call or
      condition changes. The Oakhaven helpers' keys widen from (resolved state, path) to the full message, which also
      includes `requested`; once-per-message still holds.
- [ ] AC-2 **Spam gone from the logs.** For each of the 10 suites with AssetManager lines (audit fact 1), the number
      of `WARNING: [AssetManager]` lines after the change equals that suite's distinct-message count before, no message
      text appears twice in a suite, and each suite's distinct set is unchanged. Counts come from the before log
      (`production/qa/evidence/2026-10-autoloads/run_all.log`) and the after full-suite log with
      `awk '/^=== res:\/\//{s=$2} /WARNING: \[AssetManager\]/{c[s]++}'` (lines) and the same keyed on the message text
      (distinct), saved as `warning_counts.log`. The full-suite totals are recorded: `WARNING: [AssetManager]` 463 before,
      all `WARNING` 494 before, and both after. Any message present after but not before is named and explained.
- [ ] AC-3 **`bind_text` prunes.** `bind_text()` drops entries whose `WeakRef` is dead in the same pass that looks
      for a duplicate, before appending. The de-duplicate behaviour (same node + property → update the template, no
      new entry) and `_refresh_bound_texts()` are unchanged.
- [ ] AC-4 **Prune test.** New suite `tests/unit/input/input_bound_texts_prune_test.gd` (result line
      `BOUNDTEXTS RESULT: N passed, F failed`) checks the `aeth_phase0_test` isolation guard first, uses the
      `_initialize() -> _run.call_deferred()` shape of `context_stack_test.gd` so it can `await`, and runs against the
      live `InputService`. `base_live` = the number of entries whose `ref.get_ref()` is non-null at the start of each
      case; each case frees what it created.
      1. Bind 1,000 unparented `Label`s, `free()` them, call `_refresh_bound_texts()` → `size == base_live` and no
         entry's `ref.get_ref()` is null.
      2. Bind 1,000 labels, `free()` them, then `bind_text()` one new label with **no** refresh → `size == base_live + 1`
         (the watch-fail case).
      3. Bind label L twice with the same property and different templates → one entry for L, holding the second
         template, and `L.text == fmt(second)`.
      4. Bind L, `L.queue_free()`: L's ref is still non-null and its entry still in the list; `await process_frame` →
         the ref is null; `bind_text()` a new label M → L's entry gone and `size == base_live + 1` (the plan's same-frame
         edge case).
      5. Bind A, D, B in that order (A and B live), `free()` D, then `bind_text(A, new_template)` → D pruned, B still
         present and live, A's template updated, `size == base_live + 2` (guards against an early `return` that drops
         entries after A).
      Watch-fail: in a scratch worktree at the pre-change commit the prune-without-refresh case fails. Registered:
      `.uid` beside it, `suite_limits.txt` line with its count, `run_all_tests.ps1` (header "all 18 suites"),
      `ci.yml` step with a double-quoted name if it contains `: `. `load_all` stays `LOADALL ok=204 bad=0` (it walks
      `scripts/` and `scenes/` only).
- [ ] AC-5 **Cursor released at exit.** `GameManager` gains `_exit_tree()` that calls
      `Input.set_custom_mouse_cursor(null, Input.CURSOR_ARROW)`, with a one-line comment saying why; nothing else in
      `game_manager.gd` changes (`git diff` shows only the new function).
- [ ] AC-6 **Clean exit log (real renderer).** New `tests/run_exit_scan.ps1` boots the project with the console
      executable and the default (non-headless) renderer, an isolated `APPDATA` (`aeth_phase0_test_*`), `--verbose`,
      `--fixed-fps 60 --quit-after 300` (past the 3 s splash into the main menu), saves the log, and exits 1 if it
      contains `RID allocations of type`, `RIDs of type "Texture" were leaked` or `RenderingServer::get_singleton()" is
      null`. Before the change the scan fails on the three lines in audit fact 3; after it, it passes, and the log shows
      `res://scenes/main_menu.tscn` loading. The full tour (`tests/run_screenshots.ps1`) after the change has none of
      the three lines in its exit output. Logs in `production/qa/evidence/2026-10-exit-leak/` (`exit.log` is the
      after-scan). The script is local only: CI is headless and cannot see renderer leaks (said in its header). It merges
      stderr into the log (`2>&1`) and also exits 1 if Godot's exit code is non-zero, the log is empty, or the log has
      no line showing `res://scenes/main_menu.tscn` loaded, so a crashed boot cannot pass. The before-scan at the
      pre-change commit (scratch worktree) must exit 1 on the leak lines: that is the positive control.
- [ ] AC-7 **Cursor still shows.** `git diff` shows `_setup_custom_cursor()` unchanged and `_exit_tree()` as the only
      new code in `game_manager.gd`. The user runs a windowed build (`godot --path AethelgardPrototype`), reaches the
      main menu, and confirms the green crosshair cursor shows; recorded as "[user], manual, build [commit]" in the
      evidence README. Screenshots cannot show the OS cursor (the tour captures `root.get_texture().get_image()`,
      `screenshot_tour_runner.gd:623`) and Godot has no getter for the custom cursor, so none is claimed. DEFERRED to
      the user's check; the story cannot close until it is recorded.
- [ ] AC-8 **Suites and records.** Full suite passes (`run_all_tests.ps1`, 18 suites, no `-Quick`) with every existing
      suite's count equal to `production/qa/evidence/2026-10-autoloads/run_all.log`; `git diff --check` is clean;
      a dated CHANGELOG entry; TD-012 (AudioStream/ObjectDB leak at exit) added to `docs/tech-debt-register.md`.

---

## Implementation Notes

- Order: record the before numbers first (full-suite warning counts from the T09 `run_all.log`; fresh before logs for
  chapter1_route and phase0_blockers; a before exit scan). Then input_service + the new suite (watch-fail in a scratch
  worktree), then asset_manager, then game_manager, then the after scans, the tour and the full suite.
- Warn-once helper: keep the message text exactly as today so before/after logs compare by string. Convert the four
  existing helpers to call it (message-keyed) rather than leaving two keying schemes in one dictionary.
- `bind_text`: build an `alive` array in the existing loop (same shape as `_refresh_bound_texts`) and finish the whole
  pass before deciding whether to update a duplicate or append; an early `return` on a duplicate would drop every live
  entry after it.
- The prune test touches the shared autoload: compute `base_live` at the start of each case (raw size can include
  entries that were already dead), free everything it creates, and never call `_bound_texts.clear()`.
- Watch-fail and the before exit scan run in scratch worktrees (`git -c core.longpaths=true worktree add --detach
  <scratch> <rev>`, `--import`, run, `worktree remove --force`, `worktree prune`), never by swapping files in this
  checkout.
- Commit only with the user's OK: `fix(performance): warn once per fallback, prune bound texts, release the cursor
  texture` with `Task: Y1-P0-T10` in the body.

---

## Out of Scope

- Restoring the production art removed in `abcf40c`, or changing which slots fall back.
- The loud code-bug warnings (:930, :1513) and the non-AssetManager warnings (31 lines in `run_all.log`).
- The AudioStream/ObjectDB shutdown leak (TD-012).
- Rewriting `input_test.gd`'s vacuous `_check(true, …)` (the new suite covers the case); any other input-service
  change; any new public API.
- A CI renderer job; making `run_screenshots.ps1` fail on leak lines.
- The cursor's look, size or the `_setup_custom_cursor()` code.

---

## QA Test Cases

*Reviewed by qa-lead (QL-STORY-READY, 2026-10-24: GAPS → G1-G5 adopted by the user; G6, a separate warn-once unit
suite, declined: AC-2's per-suite log counts are the warn-once evidence).*

- **C1 warn-once helper (AC-1)** — `git diff` of `asset_manager.gd`: only warning lines and the helper; :930 and :1513
  untouched; a grep shows no remaining bare `push_warning` outside the helper, :930 and :1513.
- **C2 logs (AC-2)** — `warning_counts.log`: for all 10 suites, lines after = distinct before, no message twice,
  distinct sets equal; full-suite totals before and after; any new message named.
- **C3 bind_text (AC-3, AC-4)** — the new suite's five cases pass against `base_live`; the watch-fail log shows the prune-without-refresh case
  failing on the old code; existing `input_test.gd` still 52.
- **C4 exit scan (AC-5, AC-6)** — before scan exits 1 with the three lines (positive control); after scan exits 0, has
  a non-empty log with stderr merged, a zero Godot exit code and the `main_menu.tscn` load line; tour exit clean;
  `game_manager.gd` diff is the new function only.
- **C5 cursor (AC-7)** — the user's recorded windowed check; `_setup_custom_cursor()` diff empty.
- **C6 suites (AC-8)** — 18/18, counts equal to the T09 run apart from the new suite.

---

## Test Evidence

**Story Type**: Integration
**Required evidence**: `tests/unit/input/input_bound_texts_prune_test.gd` (passing) and its watch-fail log;
`production/qa/evidence/2026-10-exit-leak/`: before/after exit scans (`exit.log` = after), the tour's exit output,
`warning_counts.log` (per-suite lines and distinct messages, before and after), the full-suite log, the user's manual
cursor check, and a README mapping each AC to its file. (The plan named `2026-11-exit-leak/`; the work is in October.)
**Run result**: required: the main menu after boot with the real renderer (AC-6 scan log; AC-7 the user's windowed
check — no screenshot can show the OS cursor).

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Y1-P0-T02 (done: the test layout and `test_layout_test` registration rules). TD-007 (done:
  `suite_limits.txt`).
- Unlocks: quieter logs for every later story's evidence; a clean exit before Y1-P0-T15.
