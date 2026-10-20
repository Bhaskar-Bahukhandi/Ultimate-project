# Story T08: Make screen flashes show, fix fragment_4, make the Null Potion do what it says

> **Epic**: Y1-P0 Stabilize (Sprint 001)
> **Task ID**: Y1-P0-T08 (`production/plan/_source/Y1-P0.json#Y1-P0-T08`)
> **Status**: In Progress
> **Layer**: Feature
> **Type**: Integration
> **Estimate**: 2 days
> **Manifest Version**: N/A — `docs/architecture/control-manifest.md` does not exist
> **Last Updated**: 2026-10-20

## Context

**GDD**: none exists for VFX, achievements or items. **Design source of record**:
`production/decisions/2026-10-audit-decisions.md` §7–9 and its Decisions table (7A, 8A, 9A, decided
2026-10-18), refined by the user's T08 decisions below. Approved string: §"Approved strings (S02)".
**Requirement**: N/A — no TR-ID registered (`docs/architecture/tr-registry.yaml` holds no requirements).

**ADR Governing Implementation**: N/A — routes existing scene code to the existing `SceneTransitions.flash()`
autoload and corrects item/achievement data; no architectural decision is made.
**ADR Decision Summary**: N/A
**ADR Version**: N/A

**Engine**: Godot 4.6 (4.6.3 at `C:/Godot`) | **Risk**: HIGH (`docs/engine-reference/godot/VERSION.md`, 4.6 row)
**Engine Notes**: no post-cutoff API expected. Root cause is a Godot 4 Control behaviour: assigning the
`anchors_preset` *property* on a code-built Control in position layout mode does nothing; only
`set_anchors_preset()` sizes it. Verified by probe (below).

**Control Manifest Rules**: NOT ASSESSED — no control manifest.

**Performance**: no impact; flashes are one tween on an existing overlay, item/achievement changes are data.

**AGENTS.md protected areas**: none are changed. The ch3 flash call sites sit next to story-flag writes,
auto-saves and Source Key collection (`ch3_archive_depths.gd` ~330-336, ~427-433, ~495-501, ~579-597,
`ch3_fractured_wastes.gd` ~562); Oakhaven `:133` shares a branch with `GameManager.add_glitch_corruption(5.0)`.
**Only the flash line itself changes**; flags, saves, Source Key and corruption calls stay byte-identical and
in order. `SceneTransitions.flash()` and its combat callers (`player_combat.gd:540`, `ch1_tutorial_knight.gd`
×4) are not edited. `game_manager.gd` is not edited. Item ids are unchanged, so the save schema
(`Inventory.items` as {id: qty}) is untouched.

### Audit facts (2026-10-20, read-only; probe in the session scratchpad; line numbers approximate)

**Flashes (decision 7)**
- Four ch3 copies of `_screen_flash(color, duration)` are byte-identical: `ch3_archive_depths.gd:657`,
  `ch3_fractured_wastes.gd:725`, `ch3_ironhold_departure.gd:132`, `ch3_kaelthas_betrayal.gd:584` (**no callers:
  dead code**). They tween `fade_rect.modulate:a` 0 → 0.8 → 0, then restore its colour and z_index.
- Each `fade_rect` is built in code with `fade_rect.anchors_preset = Control.PRESET_FULL_RECT` (property,
  e.g. archive `:96`). **VERIFIED by probe: size (0,0)** in all four real scenes; `set_anchors_preset()` gives
  1280×720. Pause, time_scale and early free were ruled out.
- Oakhaven `_flash(color)` (`ch1_oakhaven_village.gd:148`, callers `:130` `fracture_spreads`, `:133` `root_edit`,
  reached through `_on_dlg_event(event)` `:115`) uses the .tscn `FadeRect` under a Node2D root: **size (0,0), in
  world space outside the camera view, and its modulate is forced black at `:75`** so the colour never shows.
  Not awaited.
- Callers (colour alpha, duration): archive `:336/:433/:501` (0.3, 0.5 s), `:583` (0.4, 0.8 s), `:597` (0.5,
  1.0 s); wastes `:562` (0.5, 0.8 s); ironhold `:93` (0.4, **0.3 s**); oakhaven `:130` (0.35), `:133` (0.3), both
  **0.35 s**. The ch3 calls are awaited; the next dialogue line waits on them.
- `SceneTransitions.flash(color, duration)` (`effects/scene_transition_manager.gd:169`, autoload, CanvasLayer
  200 above dialogue's 100, `PROCESS_MODE_ALWAYS`, overlay sized with `set_anchors_preset` at `:65`) is already
  used live and renders. It sets `modulate.a = 0.8` synchronously and eases out, so the visible peak is
  0.8 × `color.a` (≤ 0.4 for every caller above). `CinematicVFX.screen_flash()` has no callers and is not an
  autoload.
- The same zero-size `fade_rect` also drives each scene's fade-in/fade-out from black, which has never been
  visible either. **Out of scope** (see below); routing the flashes does not change it.
- The screenshot tour (`scripts/debug/screenshot_tour_runner.gd`) has no Chapter 3 stop and no stop near a flash.

**fragment_4 (decision 8)**
- `scripts/ui/achievements.gd:29` "Key Collector" / "Collect all available Source Key Fragments.";
  unlock check `:169` `if GameManager.source_key_count >= 2: _try_unlock("fragment_4")` (should be 4).
- The check runs from a 1 s timer (`:101-106` → `_check_stat_achievements()` `:123`). Achievements persist in
  `user://achievements.save`; load replaces/merges `unlocked` without re-checking thresholds, so **an
  earlier unlock at 2 is kept** (load paths verified by reading). No test covers achievements today.

**Null Potion (decision 9)**
- Three definitions: village fallback `ch1_oakhaven_village.gd:42` (dead data: `open_shop()` always uses
  ShopSystem, the fallback only prints a list), `inventory_system.gd:80-89` (`var ITEMS`, 500/200, effect at
  `:375-383`: `heal(100)` flat and corruption **−10**), `shop_system.gd:56-63` (`const SHOP_ITEMS`, 800/320).
- What runs today: the shop sells it for **800** (price from `SHOP_ITEMS`), and using it always runs the
  **inventory** effect (+100 HP, −10 corruption). The shop's `null_heal` branch in `_apply_consumable_effect()`
  (`shop_system.gd:1164`, the full heal + 3 that 9A adopts) has **no caller** anywhere.
- "Blinds for 5s" appears only in those three .gd files. Corruption is `GameManager.add_glitch_corruption(n)`,
  1 point = 1 %; positive amounts are scaled by the corruption-resist charm (factor 0.6, `game_manager.gd:69`,
  `:743-744`); reaching `>= 100.0` triggers the corruption game over (`:746-749`).
- The only caller of `Inventory.use_item` is the pause screen (`ui/pause_screen.gd:290`), which shows
  "Cannot use that now." whenever it returns false.
- The herbalist quest already rewards `null_potion` (T06, `91d7240`; asserted by
  `tests/unit/quests/side_quest_rewards_test.gd:27`). No quest change needed; the id must stay `null_potion`.

### User decisions (2026-10-20)

1. **Flash helper**: route the live ch3 and Oakhaven flashes to `SceneTransitions.flash()` unchanged; delete
   the dead Kaelthas copy and the now-unused per-scene `_screen_flash` / `_flash` functions. (Deviation from
   7A's wording, which named `cinematic_vfx.gd screen_flash()`: it has no callers and is not an autoload.)
2. **Soft flashes**: 7A's "alpha ≤ 0.5" means the opacity the player sees (0.8 × `color.a`); "≥ 0.5 s" applies:
   Ironhold `:93` and both Oakhaven flashes become 0.5 s. A TODO points to the Y1-P1 reduce-flash option.
3. **Null Potion**: one definition in `Inventory.ITEMS` (buy 500, sell 200, desc "Full heal. Adds 3%
   corruption.", `corruption_cost: 3.0` as data). `SHOP_ITEMS` becomes a `var` and the shop copies the
   `null_potion` entry from `Inventory.ITEMS` at `_ready`. The inventory effect becomes heal to max HP + the
   corruption cost. The village fallback line and the shop's dead `null_heal` branch are deleted.
4. **Corruption edge case**: if drinking would bring corruption to 100, the potion is refused: not consumed,
   no heal, corruption unchanged.

2026-10-20, after QL-STORY-READY (GAPS → adopted):

5. **Refusal message**: Inventory emits `item_use_refused(item_id, reason)`; the pause screen keeps its generic
   "Cannot use that now." in T08, and showing the specific reason is a T12 (UI leftovers) item. No UI change here.
6. **Full HP**: using a Null Potion at full HP is refused too (not consumed, no corruption).
7. **Flash test**: Oakhaven is tested in the real scene through `_on_dlg_event`; the ch3 flashes are proven by the
   static routing scan plus the AC-5 live screenshot (they sit inside dialogue / Source Key coroutines).
8. **Cost check**: Inventory reproduces `add_glitch_corruption`'s charm arithmetic locally
   (`amount *= get_charm_value("corruption_resist")` when the charm is equipped, then `>= 100.0`); a parity test
   proves it agrees with the real add. `game_manager.gd` is not edited.

---

## Acceptance Criteria

**Flashes (7A)**
- [ ] AC-1 Every live per-scene flash call (`ch3_archive_depths.gd` ×5, `ch3_fractured_wastes.gd` ×1,
      `ch3_ironhold_departure.gd` ×1, `ch1_oakhaven_village.gd` ×2) calls `SceneTransitions.flash(color, duration)`
      with literal arguments; the ch3 calls keep their `await` and colour; Oakhaven stays fire-and-forget. No
      `func _screen_flash` remains in `scripts/chapter*/` (Kaelthas copy deleted) and Oakhaven's `_flash` is gone.
- [ ] AC-2 Soft: every routed call has `color.a ≤ 0.625` (visible peak 0.8 × a ≤ 0.5) and `duration ≥ 0.5`;
      Ironhold `:93` and the two Oakhaven calls use 0.5 s; other durations unchanged. Each of the four touched
      scene files has one `# TODO(<owner>): Y1-P1 reduce-flash option` above its first routed call (review
      checklist item, not an automated assertion). `scene_transition_manager.gd` is not edited.
- [ ] AC-3 In the real Oakhaven scene (isolated runner, after its 1.5 s fade-in), calling
      `_on_dlg_event("fracture_spreads")` and `_on_dlg_event("root_edit")` makes `SceneTransitions`' flash overlay
      show the requested colour: right after the call `modulate.a == 0.8` and the overlay colour equals the
      literal (purple / green), and its global rect covers `get_viewport().get_visible_rect()`. On today's code
      this fails because the scene never calls `SceneTransitions` (overlay alpha stays 0, colour unchanged); the
      size check is a regression guard. After `duration` + margin the overlay is back to `modulate.a == 0`, also
      while the tree is paused; with `Engine.time_scale = 0` (hitstop) the flash finishes once time_scale is
      restored (characterization; `flash()` is not changed). The `root_edit` event still adds 5.0 corruption.
- [ ] AC-4 The flags, auto-saves, Source Key collection and `add_glitch_corruption(5.0)` lines next to the flash
      calls are byte-identical and in the same order (a frozen list from HEAD, asserted in order).
- [ ] AC-5 Evidence: **live-renderer** screenshots taken mid-flash, retained in
      `production/qa/evidence/2026-10-flash/` via new tour stops (`run_screenshots.ps1 -Only <stop> -Evidence
      2026-10-flash`) that wait out the scene's fade-in, trigger the flash and capture near its peak:
      `ch3_archive_flash.png` (the stop loads the archive scene and calls `SceneTransitions.flash` with the archive
      `:583` arguments, because the scene's own call sits inside the Source Key coroutine; the evidence note says
      so, and the routing itself is proven by F1) and `ch1_oakhaven_flash.png` (the stop drives
      `_on_dlg_event("fracture_spreads")`, showing the purple tint).

**fragment_4 (8A)**
- [ ] AC-6 `fragment_4` unlocks at `source_key_count >= 4` (not at 2 or 3), named "Halfway to Root" with
      description "Collect four Source Key fragments."; id, icon and category unchanged; `fragment_1` (≥ 1) and
      `source_key_complete` (≥ 7) unchanged.
- [ ] AC-7 A player whose `achievements.save` already holds `fragment_4` (unlocked at 2) keeps it after load from
      a real fixture file and after a check at count 2 or 3 (regression guard: passes on today's code too).

**Null Potion (9A)**
- [ ] AC-8 `Inventory.ITEMS["null_potion"]` is the one definition: buy 500, sell 200, desc
      "Full heal. Adds 3% corruption.", `corruption_cost` 3.0. The shop's `null_potion` entry equals it on
      name, desc, buy and sell price and is a copy (shop listing and `get_buy_price` read it; T06 `shop_discount`
      still applies). The village fallback list has no `null_potion` line, `shop_system.gd` has no `null_heal`
      branch, and no "Blinds" text remains in `scripts/`.
- [ ] AC-9 Using a Null Potion below max HP heals the player to max HP (`player_combat.heal()`: `current_health`,
      `GameManager.player_stats.hp`, `health_changed`), adds the cost through `add_glitch_corruption` (3.0; 1.8
      with the corruption-resist charm), and consumes one potion. Buying one through `ShopSystem` costs 500 gold
      (450 with a 10 % `shop_discount`).
- [ ] AC-10 The potion is refused (`use_item` returns false, it is not consumed, HP and corruption are unchanged,
      no game over: `current_state != GAME_OVER`) and `Inventory.item_use_refused("null_potion", reason)` is
      emitted with a literal reason, when any of:
      (a) `glitch_meter + effective_cost >= 100.0` → "Corruption would reach 100%." (97.0 refused; 96.9 allowed
      → 99.9; 96.0 allowed → 99.0; with the charm 98.5 refused, 98.0 allowed → 99.8);
      (b) HP is already full → "HP is already full.";
      (c) no node in group `player` → "No one to heal." (today the potion is consumed anyway).
      The local cost check agrees with the real `add_glitch_corruption` game-over path for a sweep of values, with
      and without the charm.
- [ ] AC-11 The herbalist quest still rewards `null_potion` (`side_quest_rewards_test` passes unchanged).

**All**
- [ ] AC-12 New tests pass and are registered (`.uid`, `tests/run_all_tests.ps1`, `.github/workflows/ci.yml`;
      layout guard passes); each watch-fail case was seen failing on unfixed code; the full suite passes;
      `git diff --check` clean; CHANGELOG entry.

---

## Implementation Notes

- Flash call shape: `await SceneTransitions.flash(Color(r, g, b, a), duration)` in ch3;
  `SceneTransitions.flash(Color(...), 0.5)` without await in Oakhaven. Guard with
  `has_node("/root/SceneTransitions")` as the codebase does for autoloads.
- After routing, the ch3 `_screen_flash` colour/z restore lines go with the function; `fade_rect` keeps its
  fade role (unchanged, still zero-size: out of scope).
- `SceneTransitions.flash()` has an unused `_flash_tween` field; overlapping flashes fight over
  `modulate:a`. Not fixed here (it is shared with combat callers); record if a test shows it.
- Null Potion effect: `heal(player.max_health)` on the `player` group node (`max_health` is an export defaulting
  to 100.0; check it agrees with `player_stats.max_hp`). Read the cost from `item_data.corruption_cost`. Refusal
  check (decision 8): `var cost: float = item_data.corruption_cost`, then
  `if GameManager.has_charm("corruption_resist"): cost *= GameManager.get_charm_value("corruption_resist")`,
  refuse if `GameManager.glitch_meter + cost >= 100.0`. Order of checks: no player → full HP → corruption.
- Refusal message (decision 5): new signal `item_use_refused(item_id: String, reason: String)` on Inventory; the
  pause screen (`ui/pause_screen.gd:290`, the only `use_item` caller) is not edited; record the visible reason as
  a T12 item.
- Tests use the isolated `user://` runner (`tests/run_phase0_tests.ps1`, one `-Script` per suite), so
  `achievements.save` writes are safe. Suggested files: `tests/integration/vfx/screen_flash_test.gd`,
  `tests/unit/achievements/fragment_achievement_test.gd`, `tests/unit/items/null_potion_test.gd`.
- Add a CHANGELOG entry. Commit only with the user's OK:
  `fix: flashes show, fragment_4 at four, null potion matches its text` with `Task: Y1-P0-T08` in the body.

---

## Out of Scope

- The dormant scene fade-in/fade-out from black in the ch3 scenes and Oakhaven (same zero-size `fade_rect`):
  turning them on is a visible change; separate follow-up.
- Combat flashes (`vfx_library.gd _spawn_flash`, `combat_effects.gd`): likely broken the same way (unverified);
  combat is protected. Follow-up.
- Editing `SceneTransitions.flash()` itself, `CinematicVFX`, `cutscene_director.flash`, `flight_707_cinematic`,
  `game_manager.gd`, `pause_screen.gd` (the specific refusal reason on screen is T12).
- The reduce-flash accessibility option (Y1-P1). Other Source Key or achievement changes; the non-atomic
  `achievements.save` write. Other village fallback items (`red_potion`/`blue_potion` stale ids). Item balance
  beyond the Null Potion.

---

## QA Test Cases

*Reviewed by qa-lead (QL-STORY-READY, 2026-10-20: GAPS → cases below adopted). SceneTree `_check` style,
isolated `user://` (`tests/run_phase0_tests.ps1`, one `-Script` per suite). Expected values are literals; every
case asserts its precondition differs from the expected result. Watch-fail: F1, F2, A1, N1, N2, N3, N5, N6, N7 fail
on unfixed code; A2, F2b and the parity sweep are regression guards / characterization.*

- **F1 routing (AC-1/AC-2)** — static scan: no `func _screen_flash` in `scripts/chapter*/`, no `func _flash` in
  Oakhaven; each listed call site calls `SceneTransitions.flash` with **literal** arguments matching a literal
  table (colour, duration); ch3 lines start with `await`, Oakhaven lines do not; every `color.a ≤ 0.625`, every
  duration ≥ 0.5.
- **F2 Oakhaven renders (AC-3)** — real `oakhaven_village` scene, wait > 1.5 s; precondition: overlay
  `modulate.a == 0` and overlay colour preset to a white sentinel; call `_on_dlg_event("fracture_spreads")`:
  synchronously `modulate.a == 0.8` and colour `is_equal_approx` the literal; one frame later `0 < a ≤ 0.8`;
  rect ⊇ `get_viewport().get_visible_rect()`; after 0.5 s + margin `a == 0`. Same for `root_edit` (green; glitch
  rises by 5.0). Waits via `process_frame` / `create_timer(t, true)`; the test node is `PROCESS_MODE_ALWAYS`.
- **F2b paused / hitstop (AC-3, characterization)** — with `get_tree().paused = true` the flash still ends; with
  `Engine.time_scale = 0` it holds, and ends after time_scale is restored to 1.
- **F3 neighbours untouched (AC-4)** — frozen list (from HEAD) of the flag / auto-save / Source Key / corruption
  lines around each call site, asserted present and in order; Oakhaven's `add_glitch_corruption(5.0)` stays before
  the `root_edit` flash line.
- **A1 threshold (AC-6)** — clean `unlocked`; call `_check_stat_achievements()` directly: count 2 → absent; 3 →
  absent; 4 → present; name "Halfway to Root", desc, icon "🔑", category "story" literals; `fragment_1` at 1 and
  `source_key_complete` at 7 unchanged.
- **A2 kept (AC-7, regression guard)** — write an `achievements.save` fixture holding `fragment_4`, load it, check at
  count 2 and 3 → still present.
- **N1 one definition (AC-8)** — Inventory literals (500/200, desc, `corruption_cost` 3.0); `SHOP_ITEMS["null_potion"]`
  equals it on name/desc/buy/sell and is a copy, not the same Dictionary; shop listing price 500; `get_buy_price`
  500 and 450 with a 10 % discount (literal from the rounding rule); scan: no `"Blinds"` in `scripts/`, no
  `null_potion` in the village fallback list, no `null_heal` branch in `shop_system.gd`.
- **N2 effect (AC-9)** — with a real `player_combat` instance in group `player` (max_health and `player_stats.max_hp`
  both 170, hp 10), glitch 20 → use → `current_health` 170, `player_stats.hp` 170, `health_changed` emitted, glitch
  23.0, count −1; with the charm glitch 21.8 (approx).
- **N3 corruption refusal (AC-10a)** — count set explicitly, state not GAME_OVER: 97.0 → refused (false, count, hp,
  glitch unchanged, no game over, signal with the literal reason); 96.9 → allowed (99.9); 96.0 → allowed (99.0);
  charm 98.5 refused, 98.0 allowed (99.8). Parity sweep: for glitch values across 95–100 with and without the charm,
  "refused" equals "a real `add_glitch_corruption(3.0)` on a scratch state would reach game over".
- **N4 quest (AC-11)** — `side_quest_rewards_test` in the full suite.
- **N5 no player (AC-10c)** — no node in group `player`: false, not consumed, glitch unchanged, signal "No one to heal.".
- **N6 full HP (AC-10b)** — hp == max: false, not consumed, glitch unchanged, signal "HP is already full.".
- **N7 shop buy (AC-9)** — gold 1000 → buy through `ShopSystem` → gold 500, one `null_potion` added; with a 10 %
  discount → 550.
- **AC-12** — layout guard, full suite, `git diff --check`, watched-fail logs retained.

---

## Test Evidence

**Story Type**: Integration
**Required evidence**: the three suites above passing, logs (including the watched-fail runs) in
`production/qa/evidence/2026-10-flash/`, and the two live-renderer screenshots in AC-5.
**Run result**: required: the flashes are player-visible (AC-5 screenshots). No UI screen changes (decision 5).

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Y1-P0-T03 (done; decisions 7–9), Y1-P0-S02 (done; the approved string), Y1-P0-T06 (done;
  herbalist reward). No story files for T03/S02 by sprint decision; status in `production/sprint-status.yaml`.
- Unlocks: Y1-P0-T15 (Phase 0 exit playthrough).
