# Story T11: Close the combat-feel leftovers — dash i-frames, double hit sounds, the COMBO label, the last-kill slowdown

> **Epic**: Y1-P0 Stabilize (Sprint 001)
> **Task ID**: Y1-P0-T11 (`production/plan/_source/Y1-P0.json#Y1-P0-T11`)
> **Status**: Ready
> **Layer**: Feature
> **Type**: Integration
> **Estimate**: 4 days
> **Manifest Version**: N/A — `docs/architecture/control-manifest.md` does not exist
> **Last Updated**: 2026-10-24

## Context

**GDD**: none (combat-feel fixes). **Source of record**: the plan entry above ("Known leftovers: COMBO label, hitstop
paths, double hit sounds, dash i-frames 0.41 s, last-kill slowdown never runs (P2 combat feel; combat change needs
approval)"; done when "combat_fixes suite passes with 4 new checks; play note written"), and the sprint plan's acceptance
criteria for T11 ("combat_fixes suite +4 checks passes; `production/qa/evidence/2026-11-combat/combo_label.png`; play
note"). **Requirement**: N/A — no TR-ID registered.

**ADR Governing Implementation**: N/A — local fixes inside the existing combat and audio code; no architectural decision.
**ADR Decision Summary**: N/A
**ADR Version**: N/A

**Engine**: Godot 4.6 (4.6.3 at `C:/Godot`) | **Risk**: HIGH (`docs/engine-reference/godot/VERSION.md`, 4.6 row)
**Engine Notes**: no post-cutoff API is added. `get_tree().create_timer(t, true, false, true)` ignores time scale
(already used by `apply_last_kill_slowdown`). `CombatFX` runs with `process_mode = PROCESS_MODE_ALWAYS`
(`combat_effects.gd:66`), so its `_process` (and so a hitstop ending) still runs while the tree is paused. Signals on an
autoload (`SFXManager`) can be connected from a SceneTree test like any node's. `combat_fixes_test.gd`'s `_frames()`
awaits `physics_frame` at a fixed 1/60 s, so frame-stepped checks are deterministic.

**Control Manifest Rules**: NOT ASSESSED — no control manifest.

**Performance**: no hot-path cost: one signal emit per SFX request, one check per hitstop end, one fewer SFX per hit and
per kill. Not measured.

**AGENTS.md protected areas**: **combat is touched, with the user's explicit approval for this task (2026-10-24).** No
collision, hitbox, damage number, save/load schema, story progression, Source Key, NG+ or world-map code changes.
`GameManager.stats` (`highest_combo`, `enemies_killed`, `total_damage_dealt`) is written by the same hit code but its
counting does not change. Files: `scripts/combat/player_combat.gd` (dash i-frames, the `sword_hit` call, the chain label),
`scripts/combat/enemy_base.gd` (the death-sound guard), `scripts/combat/enemies/{corrupted_guard,corrupted_rat,data_sprite,glitch_wolf,tutorial_knight_boss_enemy}.gd`
(their extra `enemy_death` call), `scripts/combat_effects.gd` (`CombatFX`: the deferred last-kill slowdown),
`scripts/sfx_manager.gd` (a `sfx_requested` signal), `scripts/debug/screenshot_tour_runner.gd` (a combat-HUD stop),
`tests/integration/combat/combat_fixes_test.gd` (new checks), `tests/suite_limits.txt` (its count),
`AethelgardPrototype/CHANGELOG.md`, evidence, this story.

### Audit facts (2026-10-24, read-only; key claims re-checked in the main session and by QL-STORY-READY)

**1. Dash i-frames: 0.417 s (confirmed from code).** `_start_dash` sets `invulnerable = true` and
`invuln_timer = DASH_DURATION + 0.05` (`player_combat.gd:1156-1157`, `DASH_DURATION = 0.18` at :43). The timer only counts
down `if invulnerable and not is_dashing` (:385), so it is frozen during the 0.18 s dash (11 frames) and then runs 0.23 s
(14 frames): 25 physics frames in all at 60 fps. The only write of `invulnerable = false` is at :388. A hit during the tail
is absorbed silently (PERFECT DODGE only counts while `is_dashing`, `take_damage` ~:1863-1869). **Bug:** `_start_dash`
overwrites `invuln_timer`, so a dash during the 1.0 s hurt i-frames (~:1969-1970) cuts them to ~0.42 s from the dash start.
Other writers of the flag (spells, flee, parry, death, retry, `late_game_hazard_trial.gd`) are unchanged by this story. The
top-down player has no dash.

**2. Double hit and death sounds (confirmed).** One landed light combo hit requests `sword_hit` twice:
`player_combat.gd:982` (`"critical_hit" if parry_counter_active else "sword_hit"`) and `CombatFX.apply_hit_effects` (called
at :991) → `combat_effects.gd:354` (`"heavy_hit" if is_heavy_hit else "sword_hit"`). A parry counter stacks `critical_hit` +
`heavy_hit`. A kill through `take_damage` requests `enemy_death` twice: `enemy_base.gd:852` → `CombatFX.apply_kill_effects`
→ `combat_effects.gd:411`, and `enemy_base.gd:947` in `die()`. Five enemies add a third: `corrupted_guard.gd:146`,
`corrupted_rat.gd:140`, `data_sprite.gd:216`, `glitch_wolf.gd:168` and `tutorial_knight_boss_enemy.gd:1204` call
`_sfx("enemy_death")` before `super.die()`. `die()` is also reached **without** kill effects — the Root Access hack
(`enemy_base.gd:1117`), the arena kill zone (`combat_arena.gd:122`) and `corruption_elemental.gd:188` — where :947 is the only
death sound. Other hit paths (charged, pogo, directional, spells) call only `apply_hit_effects`. `SFXManager.play`
(`sfx_manager.gd:881`) has no signal or counter.

**3. COMBO label (confirmed text).** `player_combat.gd:2700-2706` sets "COMBO I" / "COMBO II" / "COMBO III !" (light
blue, gold, red; size 14) in the top-left HUD box on CanvasLayer 90, on every swing, hit or miss. Steps 1 and 2 already
clear when `combo_timer` lapses (~:473-475). **Stale:** step 3 zeroes `combo_step` and `combo_timer` (:944-946) after
showing "COMBO III !", so the timer never lapses and the text stays until the next swing or the 3 s hit decay
(~:510-515); `take_damage` zeroes `combo_step` without refreshing the label (~:1902-1903). GameJuice's counter reads
"%d HIT" below 10 hits and "%d HITS!" from 10 (`scripts/effects/game_juice.gd:657`, size 32, gold, at (20, 262), CanvasLayer
95), shown from 2 hits. Screenshot-tour stops live in `scripts/debug/screenshot_tour_runner.gd` (launched by
`tests/screenshot_tour.gd`); none reaches the combat HUD.

**4. Hitstop paths: already one path (confirmed).** Only `scripts/core/context_stack.gd` writes `Engine.time_scale`
(`combat_effects.gd:69` mentions `Engine.time_scale = 0` in a comment only); every time-scale effect requests through
ContextStack (`hitstop` priority 30, `last_kill` 20, `boss_death` 20, GameJuice slowmo 10, wobble 5; highest priority wins,
ties take the slowest scale; `clear_time_scale()` on scene change, death, retry, title, pause → Leave). ContextStack's only
signal is `contexts_changed(top)` (:23). `CombatFX.apply_hitstop` (`combat_effects.gd:95`, ~60 callers) is the single
hitstop entry; it ends through `_end_hitstop` (:128) or the 0.5 s safety `_force_end_hitstop` (:144). `clear_time_scale()`
does not reset `is_hitstop_active`, so a cleared hitstop still "ends" later. Nothing to funnel; this item becomes a guard check.

**5. Last-kill slowdown never runs (confirmed, reproduced by a headless probe).** `enemy_base.gd:851-852` calls
`CombatFX.apply_kill_effects` before `die()`; that starts a 0.18 s hitstop (`combat_effects.gd:412`,
`is_hitstop_active = true`). `die()` then reaches `CombatFX.apply_last_kill_slowdown()` (`enemy_base.gd:964`), which
returns at once: `if get_tree().paused or is_hitstop_active: return` (`combat_effects.gd:495`). Probe: called alone, the
function holds 0.12 for ~50 frames and is back to 1.0 at ~690 ms real (0.4 s hold + ~0.29 s scaled ramp); after
`apply_kill_effects`, or on a real kill of the combat-arena slime, no `last_kill` request is ever made. Bosses hit the same
guard right after `GameJuice.boss_death_sequence`'s hitstop (`game_juice.gd:809`; `tutorial_knight_boss_enemy.gd:1216`, and
bosses through `enemy_base.die` :964); their own `boss_death` slow-motion hides it. The plan's test target "back to 1.0
within 0.2 s" conflicts with the coded timing. Root Access pauses the tree (no slow-time code exists; the plan's
"Root Access slow-time" wording is stale), so a kill while paused drops the effect.

**Not in scope, noticed:** `enemy_base.gd:920` logs an engine "no meta 'flash_tween'" error on a hit (cause not
investigated); the hitstop countdown uses `delta / time_scale` (`combat_effects.gd:71`), so one long frame on the kill can
use up the 0.18 s at once (inferred, not run).

### User decisions (2026-10-24)

1. **Dash i-frames = dash + 0.05 s tail** (0.23 s from the dash start), as a named constant, set with `maxf()` so a dash
   never shortens longer i-frames already running (hurt, parry, flee). PERFECT DODGE stays dash-only.
2. **CombatFX owns the hit and kill sounds on a normal kill.** Remove `player_combat.gd:982`; a parry counter keeps
   CombatFX's `heavy_hit` (`critical_hit` no longer plays on top). `SFXManager` gains `signal sfx_requested(sfx_name)` as the
   test seam.
3. **The chain label becomes "STRIKE 1 / 2 / 3"** (same colours) and clears when the chain resets (step 3 included) and
   when the player is hit. GameJuice's counter stays the only combo count.
4. **The last-kill slowdown is deferred until the hitstop ends.** A request during a hitstop is remembered and starts when
   that hitstop is released (either end path); it is dropped if the game is paused, the hitstop request was cleared or the
   scene changed by then. The coded timing stays (0.12 for 0.4 s real, then the ramp).
5. *(from QL-STORY-READY, 2026-10-24)* **`die()` plays `enemy_death` only when kill effects did not**, so Root Access, the
   arena kill zone and the corruption elemental still get exactly one death sound (refines decision 2).
6. **The five subclass `enemy_death` calls are removed here too** (corrupted_guard, corrupted_rat, data_sprite,
   glitch_wolf, tutorial knight boss).
7. **No deferred last-kill slowdown for bosses**: a boss death keeps exactly today's feel (its own `boss_death` slow-motion).
8. Remaining QL-STORY-READY gaps (G1 dash note, G2 AC-1 frames, G5 label clear, G6 tour stop, G7 drop rules and seam,
   AC-6 regex, AC-9 format) adopted.

---

## Acceptance Criteria

- [ ] AC-1 **Dash i-frames.** `player_combat.gd` has `const DASH_IFRAME_TAIL = 0.05` beside `DASH_DURATION`. Frame-stepped in
      the suite (`_frames()`, 60 fps):
      - a dash from rest leaves `invulnerable` true for **13–15** physics frames in total (old code: 25);
      - a hit on the first frame after `is_dashing` turns false is absorbed, with `_perfect_dodge_awarded` false and soul
        unchanged (the plan's "dash into a hit at the last i-frame");
      - a hit on the first frame where `invulnerable` is false lands;
      - a hit while `is_dashing` is still a PERFECT DODGE;
      - a dash started with `invuln_timer` 0.8 (hurt i-frames) leaves it still 0.8 when the dash ends, and `invulnerable`
        still true 0.7 s (42 frames) after that.
- [ ] AC-2 **One sound per hit, one per kill.** `SFXManager` emits `sfx_requested(sfx_name)` at the top of every `play()`
      call (before its player cap). In the suite, using real enemies (`EnemyBase` slime and `corrupted_rat`, not the sound-less
      `_dummy_enemy`):
      - one landed light combo hit → exactly one `sword_hit`;
      - a parry-counter hit → exactly one `heavy_hit`, zero `critical_hit`, zero `sword_hit`;
      - a kill through `take_damage` → exactly one `enemy_death` (slime and `corrupted_rat`);
      - a direct `die()` with no kill effects (the kill-zone / Root Access path) → exactly one `enemy_death`.
      `player_combat.gd:982` and the five subclass `_sfx("enemy_death")` calls are gone; `enemy_base.gd:947` plays only when
      kill effects did not (a flag set in `take_damage` before `apply_kill_effects`); no other `_sfx` / `play` call changes.
- [ ] AC-3 **STRIKE label.** The chain label reads "STRIKE 1", "STRIKE 2", "STRIKE 3" (same colours and size as today).
      After step 3, "STRIKE 3" shows until `attack_cooldown` reaches 0, then the label is empty; right after `take_damage` it
      is empty. Steps 1 and 2 keep clearing when `combo_timer` lapses. Checked in the suite by reading the label's text (the
      step-3 and hurt checks fail on the old code; the step-1/2 checks pass on both). GameJuice's counter is unchanged.
- [ ] AC-4 **Label evidence.** A new stop `t11_combat_hud` in `scripts/debug/screenshot_tour_runner.gd` (`_wanted()`-gated
      like the others) sets up a high-HP slime, lands two strikes and checks its preconditions — `combo_step == 2`, the label
      reads "STRIKE 2", GameJuice's counter reads "2 HIT" — reporting a PROBLEM on any mismatch; a second shot after
      `take_damage` shows the label empty. Live-renderer captures (`tests/run_screenshots.ps1 -Only t11_combat_hud -Evidence combat`)
      retained in `production/qa/evidence/2026-10-combat/`; the report shows 0 problems. (The plan named `2026-11-combat/`;
      the work is in October.)
- [ ] AC-5 **Last-kill slowdown runs.** `CombatFX` keeps a pending flag and a test seam `last_kill_started_count`. In the
      suite:
      - (a) after `apply_kill_effects` + `apply_last_kill_slowdown`, no `last_kill` request exists while the hitstop is active;
      - (b) when that hitstop is released — by `_end_hitstop` and, separately, by `_force_end_hitstop` —
        `ContextStack.has_time_request(&"last_kill")` is true, `Engine.time_scale` is 0.12 and the count rose by 1;
      - (c) the request is released again within 2.0 s real (polled each frame; a hang guard, the real hold is ~0.69 s);
      - (d) at release time the pending request is dropped (count unchanged, no `last_kill` request) if the tree is paused,
        if `ContextStack.has_time_request(&"hitstop")` is false because `clear_time_scale()` ran, or if `current_scene`
        changed since the request — checked statelessly at consume time, no new signal;
      - (e) two real slimes in a bare stage dying on the same frame give one slowdown (count +1);
      - (f) a kill while the tree is paused (Root Access) leaves nothing pending, and `apply_hitstop` while paused makes no
        request;
      - (g) a boss kill does not start a deferred last-kill (count unchanged; its `boss_death` request still appears);
      - end-to-end: killing the combat-arena slime with `take_damage(99999)` makes `Engine.time_scale` reach 0.12 on at least
        one frame within 1.0 s real (watched failing on the pre-change code).
- [ ] AC-6 **One time-scale writer.** A suite check reads every `.gd` under `res://scripts`, strips `#` comments, and fails
      if any line outside `scripts/core/context_stack.gd` matches `Engine\.time_scale\s*[+\-*/]?=[^=]`; passes today.
- [ ] AC-7 **Watch-fail.** In a scratch worktree at the pre-change commit, the new checks for AC-1 (frame count), AC-2 (one
      `sword_hit`, one `enemy_death`), AC-3 (step-3 / hurt clear) and AC-5 (end-to-end) fail; the log is kept.
- [ ] AC-8 **Suites and records.** `combat_fixes_test.gd` passes with its new checks (`suite_limits.txt` minimum set to the
      new count); `context_stack_test.gd`, both route suites and the full suite (`run_all_tests.ps1`, 18 suites, no
      `-Quick`) pass with every other suite's count equal to `production/qa/evidence/2026-10-exit-leak/run_all.log`;
      `git diff --check` clean; a dated CHANGELOG entry.
- [ ] AC-9 **Play note.** The user plays the Aldric fight and the arena bronze bracket once on the changed build and records
      `production/qa/evidence/2026-10-combat/play_note.md`: the commit hash, then one line each for the dash window, the hit
      sound, the STRIKE label and the last-kill slowdown, each tagged **better / same / worse**. A "worse" opens a follow-up
      story; it does not block this one. DEFERRED to the user's play session; the story cannot close until it is recorded.

---

## Implementation Notes

- Order: record before-values first (the new checks run against the old code in a scratch worktree, AC-7). Then
  SFXManager's signal and the sound changes, the dash constant, the label, the CombatFX deferral, the tour stop, then the
  suites, captures and the play note.
- Dash: in `_start_dash` set `invuln_timer = maxf(invuln_timer, DASH_IFRAME_TAIL)` (0.05) and keep the frozen-while-dashing
  countdown at :385, so the total is 0.18 + 0.05 = 0.23 s and a longer running timer is never shortened. (Not
  `DASH_DURATION + DASH_IFRAME_TAIL`: with the frozen countdown that is the 0.41 s bug again.) The constant matches the
  file's `const DASH_*` style (the coding standard's data-driven rule is not applied: every other dash value is a script
  constant).
- Sounds: emit `sfx_requested` at the top of `SFXManager.play()`. In `enemy_base.take_damage`, set a `_kill_fx_played` flag
  just before `CombatFX.apply_kill_effects`; in `die()`, call `_sfx("enemy_death")` only if it is false.
- Label: one helper sets the text from `combo_step` and clears it at 0; call it from the step-3 path once `attack_cooldown`
  reaches 0, from the timeout path and from `take_damage`.
- Last-kill: in `apply_last_kill_slowdown()`, if paused → return (nothing pending); if a hitstop is active → set
  `_pending_last_kill`, remember `current_scene`, return; else start as today and increment `last_kill_started_count`. In
  `_end_hitstop` / `_force_end_hitstop`, consume the flag: start only if the tree is unpaused,
  `has_time_request(&"hitstop")` was still held and `current_scene` is unchanged; else drop. Bosses: drop at consume time if
  ContextStack holds a `boss_death` request; if the boss sequence's order makes that unreliable, pass an explicit boss flag
  from the two boss call sites instead, and say which in the completion notes.
- Tests reuse `combat_fixes_test.gd`'s `_bare_stage()` and `_frames()` helpers; the kill and sound checks need real enemy
  scenes. Real-time bounds appear only for the real-time timer (AC-5c) and the end-to-end check.
- Watch-fail and captures follow the T10 pattern (scratch worktrees under the session scratchpad, `--import`, remove after).
- Commit only with the user's OK: `fix(combat): dash i-frames, one hit sound, STRIKE label, last-kill slowdown` with
  `Task: Y1-P0-T11` in the body.

---

## Out of Scope

- Damage numbers, hitboxes, collision, enemy AI, boss death sequences (their own `boss_death` slow-motion stays), Root
  Access, other i-frame writers (spells, flee, parry, death, retry, hazard trial).
- The `enemy_base.gd:920` "flash_tween" meta error and the hitstop countdown's `delta / time_scale` hitch (log as tech debt
  at close if still present).
- GameJuice's combo counter, its tiers and multiplier; any new sound assets; `GameManager.stats` counting.
- The top-down player (no dash).

---

## QA Test Cases

*Reviewed by qa-lead (QL-STORY-READY, 2026-10-24: GAPS → adopted by the user).*

- **C1 dash window (AC-1)** — frame-stepped dash from rest: 13–15 invulnerable frames; tail hit absorbed without a
  perfect dodge; first vulnerable frame lands; in-dash hit is a perfect dodge; dash during hurt i-frames keeps 0.8.
- **C2 sounds (AC-2)** — `sfx_requested` spy with real enemies: light hit → one `sword_hit`; parry counter → one
  `heavy_hit` only; kill (slime, corrupted_rat) → one `enemy_death`; direct `die()` → one `enemy_death`.
- **C3 label (AC-3, AC-4)** — STRIKE text per step; step-3 clear on `attack_cooldown`; hurt clear; tour stop with
  precondition checks, two live captures, 0 problems.
- **C4 last-kill (AC-5)** — deferral; release via both end paths; 0.12 and count +1; released within 2.0 s; dropped when
  paused / cleared / scene changed; one slowdown for two kills; nothing pending while paused; none for a boss; end-to-end
  slime kill.
- **C5 single writer (AC-6)** — comment-stripped static scan of `res://scripts`.
- **C6 watch-fail and suites (AC-7, AC-8)** — old-code failures kept; full suite 18/18.
- **C7 play note (AC-9)** — the user's tagged note on disk.

---

## Test Evidence

**Story Type**: Integration
**Required evidence**: `tests/integration/combat/combat_fixes_test.gd` (new checks, passing) and its watch-fail log;
`production/qa/evidence/2026-10-combat/`: the two HUD captures and their report, the full-suite log, the play note, and a
README mapping each AC to its file.
**Run result**: required: the combat HUD with the STRIKE label (AC-4).

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Y1-P0-T02 (done: test layout). TD-007 (done: `suite_limits.txt`).
- Unlocks: Y1-P0-T13a (real side-scroll fights depend on T11 per the sprint plan).
