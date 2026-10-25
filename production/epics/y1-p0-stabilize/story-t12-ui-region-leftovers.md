# Story T12: Fix the UI and region leftovers — one version string, a stats card that fits, no lore titles as speakers, a Clock Tower pre-boss trigger on the path

> **Epic**: Y1-P0 Stabilize (Sprint 001)
> **Task ID**: Y1-P0-T12 (`production/plan/_source/Y1-P0.json#Y1-P0-T12`)
> **Status**: In Progress
> **Layer**: Feature
> **Type**: Integration
> **Estimate**: 4 days (one per item below)
> **Manifest Version**: N/A — `docs/architecture/control-manifest.md` does not exist
> **Last Updated**: 2026-10-25

## Context

**GDD**: none (UI and region cleanup). **Source of record**: the plan entry above ("Known leftovers: version labels,
chapter-end stats card, lore titles as speakers, Ironhold dead fallback, Clock Tower pre_boss trigger off the path"; its
four day-plans and edge cases: "Version label in exported builds reads the same as in the editor", "Stats card with a very
long region or flag name", "Player dashes past the pre_boss trigger in one frame"), and the sprint plan's acceptance
criteria for T12 ("`production/qa/evidence/2026-11-ui/{menu_version,pause_version,stats_card,clock_tower}.png`;
reachability log"). **Requirement**: N/A — no TR-ID registered.

**ADR Governing Implementation**: N/A — local fixes in existing UI, dialogue and region scripts; no architectural decision.
**ADR Decision Summary**: N/A
**ADR Version**: N/A

**Engine**: Godot 4.6 (4.6.3 at `C:/Godot`) | **Risk**: HIGH (`docs/engine-reference/godot/VERSION.md`, 4.6 row)
**Engine Notes**: no post-cutoff API is planned. `ProjectSettings.get_setting("application/config/version", "")` is
baked into exported builds with the rest of `project.godot`. Container layout (`PanelContainer`, `HBoxContainer`,
`VBoxContainer`) settles one frame after the nodes are added; measure with `get_global_rect()` /
`get_combined_minimum_size()` after `await get_tree().process_frame`. `PhysicsDirectSpaceState2D.intersect_shape` with an
Area2D-only query (`collide_with_areas = true`, `collide_with_bodies = false`) is how `reachability_test.gd` already tests
"touchable". `SceneTree.debug_collisions_hint` has to be set before the shapes enter the tree to draw them — verify in the
first screenshot run. The dialogue text is a `RichTextLabel` (`dialogue_manager.gd:918`); check `bbcode_enabled` before
formatting the lore title.

**Control Manifest Rules**: NOT ASSESSED — no control manifest.

**Performance**: no hot-path cost (one-time label text, a container layout built once at the chapter end, one shape swap).
Not measured.

**AGENTS.md protected areas** (user decisions, 2026-10-25):
- **Collision — allowed for this task, for the Clock Tower `BossTrigger` shape only** (decision D4): the circle becomes a
  band across floor 5. No wall, floor, platform, lift or hitbox changes.
- **Combat entry — allowed for this task, for Ironhold `_interact_boss` only** (decision D5): the unreachable
  `combat_arena.tscn` fallback is removed and a missing `scene_path` stops the gate with an error before anything is set.
- **Save/load**: no schema change. Fractured Wastes starts recording its lore through the existing
  `LoreJournal.discover_lore()`, whose entries are already saved under the existing `lore_journal` key
  (`game_manager.gd:1497`); the save version `1.2.0` is not touched (it is not the game version).
- Not touched: story progression (the `dev_signature_*_found` flags stay as they are), Source Keys, true ending, NG+,
  world-map / free-travel, hitboxes, accepted region art baselines, production art.

### Audit (2026-10-25, verified by reading the code)

1. **Version.** `project.godot` has no `application/config/version`. `scenes/main_menu.tscn:98` `VersionLabel` hard-codes
   `text = "v1.0"`. `scripts/ui/pause_screen.gd:886` builds the header as `"AETHELGARD IDE v0.1.1 — PAUSED"`, and
   `_refresh_header()` (:197) overwrites it with `"AETHELGARD IDE v0.1.%d — Chapter %d" % [chapter, chapter]`, so the
   pause version changes with the chapter. `export_presets.cfg` has `application/file_version=""` and
   `product_version=""` in both presets (:32-33, :112-113). `tools/export_windows.ps1` prints the Godot version, not the
   game's. In-fiction strings (`splash_screen.gd:10` "KERNEL v0.91 [CORRUPTED]", the Chapter 3 `safety_protocol_v1.0`
   lines) are story text, not the game version.
2. **Chapter 2 end card.** `ch2_chapter_end.gd` `_show_chapter_end_card()` (:88) adds a full-rect black `ColorRect` and
   one full-rect `Label` (font 20, centred) holding `_build_chapter_stats_text()` (:165-297): 35 lines, 36 with the arena
   line (4 rules, 9 blank, ~22 text) — about 900-1080 px against the 720 px viewport (`project.godot:58-60`,
   `stretch/mode="viewport"`, no aspect setting, no minimum window size), so the top and bottom are cut off. The continue
   prompt is `"Press {ui_accept} to continue."` through `InputService.fmt` (:295); comments at :125 and :322 still say
   "Space" (ui_accept is Enter / KP Enter / pad A). Chapter 1's card (`shatter_transition.tscn:202-233`) is a centred
   700x400 `PanelContainer` and fits. No test asserts on the Chapter 2 card (`chapter2_route_test.gd:98-99` only reads
   `end_card_visible`).
3. **Titles as speakers.** Six region calls pass a title as the speaker: lore pickups at `oakhaven_region.gd:967`,
   `ironhold_region.gd:969`, `fractured_wastes_region.gd:862` (`DialogueManager.say(title, text)`), and secret pickups at
   `oakhaven_region.gd:753`, `ironhold_region.gd:802`, `fractured_wastes_region.gd:752`
   (`say(data.get("title", "SECRET"), msg)`). `say()` writes the speaker straight into the name plate
   (`dialogue_manager.gd:225`) and warns "Unknown speaker" (:214), since titles are not in `SPEAKER_COLORS` (:74).
   Fractured Wastes never calls `LoreJournal.discover_lore()` (Oakhaven and Ironhold do). The chapter 7-10
   `_discover_lore()` helpers only call `LoreJournal.discover()` and show no dialogue (not affected). The voice lint
   (`dialogue_test.gd` `_test_voice_lint()`, :224) checks authored `.dlg` speakers only. Runtime literal speakers today
   (regex `DialogueManager\.say\(\s*"([^"]*)"`, `\s` taking line breaks): 82 names in 317 calls are not in
   `SPEAKER_COLORS` (chapters 4-10: echoes, delegates, mirrors, …); `_show_dialogue("…")` has 424 literal calls whose
   13 speakers are all registered.
4. **Ironhold dead fallback.** Not at :518 (`_place_boss_gates()`, whose comment says the fallback is gone) but in
   `_interact_boss` (:1137) at :1158-1159: `if scene_path.is_empty(): scene_path = "res://scenes/combat/combat_arena.tscn"`.
   Unreachable: only `_create_boss_gate` makes "boss" gates (:558), and its one caller (:523-525) passes
   `res://scenes/chapter2/administrator_boss.tscn`. The comment at :589-591 still mentions "the generic arena boss gate".
   Callers of `_interact_boss`: the dispatcher (:921) and `chapter2_route_test.gd:124`.
5. **Clock Tower trigger.** `ch2_clock_tower.gd:393-402`: `BossTrigger`, a `CircleShape2D` r=50 at
   `(400, FLOOR_Y[5] + 60)` = (400, -90), covering x 350-450, y -140..-40. Floors at y 900/650/400/150/-150
   (`FLOOR_HEIGHT` 250); the floor 4→5 steps sit at y -40 (x 450-800) and y 40 (x 550-800); the lift runs x 450-550,
   y 120..-120; the player body is 20x32. By the coordinates (inferred, to be measured): standing on floor 5 leaves ~10 px
   between the body and the circle, the step's left end misses by ~3 px, the lift by ~90 px — so `_pre_boss_dialogue()`
   (clock_tower.dlg `pre_boss`, 4 lines, camera pan; the fight does not depend on it) can be skipped silently.
   `reachability_test.gd` flood-fills top-down maps (no gravity) and does not list the tower, so it cannot test this
   side-view room as written; `chapter2_route_test.gd` never touches `BossTrigger`.

### Decisions (user, 2026-10-25)

- **D1 version:** `0.1.0`. The pause header keeps its in-fiction wording with the real version:
  `AETHELGARD IDE v0.1.0 — Chapter N` (and `— PAUSED` before the first refresh).
- **D2 titles:** a registered `"Journal"` speaker for all six lore and secret calls, the title on the first line of the
  text; Fractured Wastes records its lore in the journal like the other regions.
- **D3 lint:** ratchet plus title ban — no `say()` may take a title; every literal runtime speaker is registered or on a
  frozen baseline of today's 82 names; registering them is logged as tech debt.
- **D4 Clock Tower:** a band trigger across floor 5, proven by a measurement of today's miss first.
- **D5 Ironhold:** remove the dead branch; a missing `scene_path` fails loudly.
- **D6 stats card:** two columns in a centred panel, no scrolling.
- **QL-STORY-READY (GAPS, all adopted by the user, 2026-10-25):** evidence stays in `2026-10-ui/` (the sprint plan, QA
  plan and plan JSON say `2026-11-ui/`; October folders are the convention) and keeps a `reachability_test` log; card
  font floor 16; bold lore title, asserted on BBCode-stripped text; the lint scans `say(` and `_show_dialogue(` with a
  stated regex; band geometry and a dash step; mutations (i) and (j). `reachability_test` does **not** gain `pre_boss`
  (the QA plan's line 283 says it does; it cannot model a side-view room — AC-6 replaces it).

---

## Acceptance Criteria

- [ ] AC-1 **One version string.** `project.godot` sets `application/config/version="0.1.0"`. The main menu's
      `VersionLabel` and the pause screen header both read it from `ProjectSettings` at runtime (one shared helper, e.g.
      a static function, so the format lives in one place): the menu shows `v0.1.0`; the pause header shows
      `AETHELGARD IDE v0.1.0 — PAUSED` when built and `AETHELGARD IDE v0.1.0 — Chapter N` after `_refresh_header()` for any
      chapter. No `"v1.0"` remains in `main_menu.tscn` and no `IDE v0.1.` literal remains in `pause_screen.gd`. Both export
      presets set `application/file_version` and `application/product_version` to `0.1.0.0`, and
      `tools/export_windows.ps1` prints `Aethelgard <version>` read from `project.godot` before exporting. In-fiction
      version text (splash, Chapter 3) is unchanged. The test also asserts: the setting matches `^\d+\.\d+\.\d+$`; both
      presets' `file_version` and `product_version` equal `<setting>.0` (so the three cannot drift); the pause header is
      right for chapters 1 and 3 and when `current_chapter` is 0 / unset (today's `if … else 1` fallback). DEFERRED to the
      first exported build (T15 makes one): a capture or log from the exported exe shows `v0.1.0`.
- [ ] AC-2 **Stats card fits.** The Chapter 2 end card is a centred panel: header (the "CHAPTER 2 COMPLETE" block and
      act lines), two columns (left: Source Keys, corruption, level, playtime, gold, arena line, relationships; right:
      Chapter 1 and Chapter 2 choices, report destination), footer (the Act 2 lines, the thank-you line, the continue
      prompt). Every value and line of today's card appears, with the same wording: before the refactor the test's golden is
      captured from today's `_build_chapter_stats_text()` under the worst-case fixture, and afterwards the card's labels,
      joined in reading order (header, left, right, footer), equal it line for line, rules and blank lines aside.
      Worst-case fixture: arena line on (wins, losses and best streak in three digits), playtime over an hour, gold and
      corruption at their largest plausible widths (6 and 3 digits), and the longest string each status branch can
      produce (Elara status, Seraphina display, knight, village, Seraphina approach, wraith and Seraphina choices, report
      destination). Under that fixture, after layout: the panel's global rect lies inside the 1280x720 viewport with at
      least 24 px on every side; every label's `get_line_count()` equals its `get_visible_line_count()` and its rect lies
      inside its column; font size is at least 16. The prompt still
      comes from `InputService.fmt("Press {ui_accept} to continue.")`; the "Space" comments are corrected. The card's 12 s
      auto-advance, skip input and the `show_choices` hand-off are unchanged (`chapter2_route_test` still passes).
      With `stretch/mode="viewport"` a smaller window scales the same 1280x720 layout, so one capture at 1280x720 is the
      check (recorded in the evidence README).
- [ ] AC-3 **No titles in the name plate.** `SPEAKER_COLORS` gains `"Journal"`. The three lore pickups and the three
      secret pickups call `DialogueManager.say("Journal", …)` with the title, in bold, as the first line of the text and
      the body after it; a secret with no title keeps today's fallback, `SECRET`, as that first line. Fractured Wastes' lore pickup calls `LoreJournal.discover_lore(lore_id, title, text, "world",
      "fractured_wastes")`. A test drives one lore pickup per region and one secret pickup per region: the name plate
      reads `Journal`; the dialogue text with BBCode stripped (`get_parsed_text()`) starts with the title and then the
      body; once the line has finished typing, `visible_ratio` is 1 (the whole text is shown); and (lore) the journal
      holds the entry for all three regions. The Wastes entry survives a save and load (`GameManager` save to an isolated
      slot, then load), and the saved JSON's `version` is still `1.2.0`. The `dev_signature_*_found` flags are still set as
      today.
- [ ] AC-4 **Voice lint covers runtime calls.** `dialogue_test.gd` scans `scripts/**/*.gd` for literal speakers with
      `(DialogueManager\.say|_show_dialogue)\(\s*"([^"]*)"` (`\s` matches line breaks, so a call split after the bracket
      is read) and for title speakers with `(DialogueManager\.say|_show_dialogue)\(\s*(title|data\.get\("title")`. It fails
      when (a) any call takes a title as its speaker, or (b) a literal speaker is neither in `SPEAKER_COLORS` nor in
      `tests/integration/dialogue/runtime_speaker_baseline.txt` (one name per line, header comment naming the regex;
      generated by that regex — 82 names today), or (c) a baseline name is now registered or no longer used (the list only
      shrinks). Each failure prints file:line. The lint checks that the scan read at least 800 literal calls (today 1281),
      so a broken regex cannot pass by reading nothing. Non-literal speakers (variables from `.dlg` data, NPC names) are
      out of the scan and the header says so. Its new checks raise `dialogue_test`'s `suite_limits.txt` minimum to the
      new count.
- [ ] AC-5 **Ironhold dead branch gone.** In `_interact_boss`, the `combat_arena.tscn` fallback is deleted and an empty
      `scene_path` is checked first: `push_error` and return before the level warning, the return point or any meta is
      set. The stale comment at :589-591 is corrected. A test calls `_interact_boss` with an empty-path gate: no
      `transition_started`, no `boss_fight_id` meta set; `chapter2_route_test` (AdminBossGate) still passes.
- [ ] AC-6 **Clock Tower trigger on the path.** First, a headless measurement against today's circle records, for a
      player body standing on floor 5 at x = 50, 100, …, 750, at the left end of the floor 4→5 step and on the lift at its
      top, whether it overlaps `BossTrigger` (expected: no or almost no overlap; the result goes in the evidence log either
      way). Then the circle is replaced by a `RectangleShape2D` band: x from the tower's inner left to inner right wall
      (floor 5's whole standing width), y from the floor 5 top surface up by one player-body height (32 px), derived from
      `FLOOR_Y[5]`, `TOWER_WIDTH` and the body size. A player body standing anywhere on floor 5 overlaps it by at least
      8 px vertically; no standing position on floor 4 or on the floor 4→5 steps overlaps it; the lift-top sample is
      measured and recorded (it is the floor 5 arrival point, so overlapping there is allowed and expected). The test
      re-runs the samples against the band, then: drops the real player onto floor 5 from the step and from the lift and
      steps physics frames — `_pre_boss_done` becomes true and the `pre_boss` dialogue starts, in both cases; and places
      the player standing on floor 5 at x = 20 with the dash velocity and steps 30 physics frames — `_pre_boss_done` is
      true. The `body_entered` handler, the dialogue and the boss setup are unchanged.
- [ ] AC-7 **Suite, screenshots and records.** A new suite `tests/integration/ui/ui_region_leftovers_test.gd` (its own
      column-0 result line, `.uid`, `tests/suite_limits.txt` entry at its final count and 3x its measured time, listed in
      `run_all_tests.ps1` — 20 suites — and in `ci.yml` with a quoted step name) holds AC-1, AC-2, AC-3, AC-5 and AC-6;
      AC-4 lives in `dialogue_test.gd`. Watch-fail in a scratch worktree after a green control, one mutation per run, each
      failing its own checks: (a) the menu label back to `"v1.0"`; (b) `_refresh_header` back to `v0.1.%d`; (c) the card
      back to one full-rect label; (d) one lore call back to `say(title, text)` (fails AC-3 and the lint); (e) Wastes'
      `discover_lore` removed; (f) a new unregistered literal speaker added; (g) `BossTrigger` back to the circle;
      (h) the empty-`scene_path` check removed; (i) the band narrowed to half the floor width (a floor 5 sample fails);
      (j) a registered speaker left on the baseline (check (c) fails). For (a) the menu label must fail whether it reads
      `v1.0` or the helper's `v0.0.0` fallback (the test compares with the project setting, which must be non-empty). Full suite 20/20 with `GODOT` unset, every count equal to its minimum,
      no `RUNNER WARN`; `load_all`, `reachability_test`, `chapter1_route` and `chapter2_route` green; the runner self-test
      green. Live-renderer screenshots (`tests/run_screenshots.ps1 -Evidence ui`, new tour stops where needed):
      `menu_version.png`, `pause_version.png`, `stats_card.png` (arena line present), `clock_tower.png` (debug collision
      shapes visible, the band in view), retained in `production/qa/evidence/2026-10-ui/` with a README mapping each AC to
      its file and saying which images are live-renderer captures, plus the `reachability_test` log (the sprint row's
      "reachability log"; it must stay green with the lore and trigger changes); CHANGELOG entry; `git diff --check`
      clean; the 82-name speaker registration logged in `docs/tech-debt-register.md`.

---

## Implementation Notes

- Order: the Clock Tower measurement first (it decides how big the band must be), then version, card, titles + lint,
  Ironhold, the suite, mutations, screenshots, the full suite.
- Version helper: one static function (e.g. on an existing autoload or a small `class_name` script) returning
  `"v" + ProjectSettings.get_setting("application/config/version", "0.0.0")`; `main_menu.gd` sets `VersionLabel.text`
  in `_ready`; `pause_screen.gd` uses it at :886 and :197. Keep the `.tscn` placeholder text or clear it — the script
  owns the value.
- Stats card: capture the golden from today's `_build_chapter_stats_text()` under the worst-case fixture first; then
  build the columns from the same values it computes (split it into header / left / right / footer parts rather than
  parsing the string); drop to font 18, then 16, only if the fixture does not fit at 20; keep `InputService.fmt` on the prompt; reuse the
  Chapter 1 card's panel look where it is cheap.
- Journal formatting: `"[b]%s[/b]\n%s"` if the dialogue `RichTextLabel` has BBCode on (check `bbcode_enabled`),
  otherwise `"%s\n%s"`; the test reads `get_parsed_text()` either way. The typewriter must still reveal the whole text.
- Lint baseline: generate the 82 names once with the same regex the lint uses (the count may move by a few if other
  work lands first — the file, not the story, is the source), commit the file, and make the lint print
  the offending file:line for each failure.
- Ironhold: the empty-path check is the first statement of `_interact_boss`.
- Clock Tower band: derive its rect from `FLOOR_Y[5]`, `TOWER_WIDTH` and the player body height, not literals; keep the
  node name `BossTrigger` and the `body_entered` connection.
- Test driving: reuse the drivers other suites use for dialogue (answering or skipping lines) and region interacts
  (calling the region's interact function on the found Area2D), as `ch3_flash_runtime_test.gd` and
  `chapter2_route_test.gd` do.
- Commit only with the user's OK: `fix(ui): …` / `fix(level): …` as the changes split, `Task: Y1-P0-T12` in the body.

---

## Out of Scope

- Registering the 82 runtime speakers (tech debt), any dialogue or lore wording change, non-literal speaker checks.
- Back-filling the journal for saves that already took a Fractured Wastes lore pickup (they gain it on the next pickup
  only if the pickup can be taken again; otherwise not).
- Making `reachability_test.gd` understand side-view rooms or listing `pre_boss` in it (the QA plan's wording; the
  Clock Tower is checked by AC-6's physics test instead).
- The splash screen, Chapter 3 in-fiction version strings, the save schema version, the Chapter 1 end card.
- Any other trigger, wall, floor or lift in the Clock Tower; any other combat code.

---

## QA Test Cases

*Reviewed by qa-lead (QL-STORY-READY, 2026-10-25: GAPS → 7 gaps adopted by the user).*

- **C1 version (AC-1)** — menu label and pause header (built; refreshed for chapters 0/unset, 1 and 3) equal the
  project setting; setting format; presets equal `<setting>.0`; no stale literals; export script print; exported-build
  check deferred to T15.
- **C2 card (AC-2)** — worst-case fixture; golden text equal; panel inside the viewport with 24 px margins; line counts
  equal visible line counts; labels inside columns; font >= 16; prompt token; route test unchanged.
- **C3 titles (AC-3)** — six pickups show `Journal`, title first in the parsed text, whole text revealed, `SECRET`
  fallback; three regions journal their lore; the Wastes entry survives save/load at version 1.2.0; flags unchanged.
- **C4 lint (AC-4)** — title ban; ratchet both ways; multi-line calls read; `_show_dialogue` scanned; scanned-call
  floor; file:line reported.
- **C5 Ironhold (AC-5)** — empty path stops first; route test still enters the Administrator Proxy.
- **C6 Clock Tower (AC-6)** — before/after overlap samples (floor 5 >= 8 px, floor 4 and steps none, lift top
  recorded); drop from step and lift fires `pre_boss`; dash from x=20 for 30 frames fires it.
- **C7 suite and records (AC-7)** — mutations a-j; 20/20; screenshots retained and labelled; reachability log kept.

---

## Test Evidence

**Story Type**: Integration
**Required evidence**: `tests/integration/ui/ui_region_leftovers_test.gd` and the `dialogue_test.gd` lint (passing);
`production/qa/evidence/2026-10-ui/`: `menu_version.png`, `pause_version.png`, `stats_card.png`, `clock_tower.png`
(live renderer), the Clock Tower measurement log, the stats-card golden, the `reachability_test` log, the mutation log,
the full-suite log, and a README mapping each AC to its file.
**Run result**: to be recorded by /dev-story (OBSERVED with the retained screenshots).

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Y1-P0-T02 (done).
- Unlocks: Y1-P0-T14a (Chapter 3 exit → credits playthrough legs; sprint plan order: T14a runs straight after T12).
