# Story S06c: The difficulty profiles GDD — five profiles as data, the constants map and the old-setting mapping

> **Epic**: Y1-P0 Stabilize (Sprint 001)
> **Task ID**: Y1-P0-S06c (`production/plan/_source/Y1-P0.json#Y1-P0-S06`, day 4; sprint plan row Y1-P0-S06)
> **Status**: Complete
> **Layer**: Foundation (design)
> **Type**: Integration
> **Estimate**: 1 day in the plan; budget 2. The review exit rule is set before the first review (Decisions).
> **Manifest Version**: N/A — `docs/architecture/control-manifest.md` does not exist
> **Last Updated**: 2026-11-21

## Context

**GDD**: this story writes `design/gdd/difficulty-profiles.md` (new). **Source of record**: the plan entry (S06 day 4,
"Difficulty values: five profiles as data"; steps: write the GDD from ROADMAP §12.1, list the current code constants
each value replaces "so P2 can wire them", define the lower-only mid-run change rule and DDA scope for Beginner/Easy,
run `/balance-check`; done "Difficulty doc with a constants map and balance-check notes"; edge case "Deadline leniency
×0.85 on Hell must not make the Ch1 bridge impossible"), `ROADMAP_10_YEAR.md` §12.1 (ROADMAP:463-480), and
`design/gdd/time-model.md` (revision 3), which already constrains leniency. **Requirement**: N/A — no TR-ID registered.

**ADR Governing Implementation**: N/A — a design document; no architectural decision. The constants map is input to the
Year 1 Phase 2 combat work, not an implementation.

**Engine**: N/A — no engine API. **Control Manifest Rules**: NOT ASSESSED — no control manifest.

**Performance**: none — documentation only.

**AGENTS.md protected areas**: combat is protected. This story only describes combat values and where they live; no
file under `AethelgardPrototype/scripts`, `scenes` or `dialogue` changes. The pause menu, the DDA and the settings
file are described, not changed.

### Audit (2026-11-19, read-only; HEAD `5646010`)

1. **ROADMAP §12.1** (ROADMAP:463-480): five profiles Beginner / Easy / Medium / Hard / Hell. Parry window 12 / 9 / 6 /
   4 / 2 frames at 60 fps; dodge i-frames 18 / 15 / 12 / 10 / 8; boss telegraph ×1.5 / ×1.25 / ×1.0 / ×0.85 / ×0.7;
   enemy damage ×0.6 / ×0.8 / ×1.0 / ×1.3 / ×2.0; boss patterns base / base / +variants / +variants / +Hell-only phase;
   healing charges 5 / 4 / 3 / 2 / 1; DDA gentle / on / off / off / off; quest deadline leniency ×1.5 / ×1.25 / ×1.0 /
   ×1.0 / ×0.85; loot base / base / +rare / +epic / +Hell cosmetics. "Lower difficulties forgive execution, not
   attention." Hell needs a fixed tick, a 4-frame input buffer, latency calibration and replay-verified fairness. "You
   can lower difficulty mid-run but never raise it" (ROADMAP:480).
2. **The build has four difficulties, not five**: `enum Difficulty { STORY, EASY, NORMAL, HARD }`
   (`game_manager.gd:483`) with `DIFFICULTY_MULTS` (`:485-490`): `enemy_dmg` 0.5 / 0.75 / 1.0 / 1.3, `player_dmg`
   1.5 / 1.25 / 1.0 / 0.85 (a knob §12.1 does not have), and `dda_floor` / `dda_ceil` values that nothing reads.
3. **Where it is stored**: a global setting, not part of a save: `user://game_settings.cfg`, section `gameplay`, key
   `difficulty`, an int 0-3 (`game_manager.gd:2181-2193`, clamped on load). Chosen in the main menu
   (`main_menu.gd:1187`) and changeable any time, either direction, in the pause screen (`pause_screen.gd:1265-1272`),
   which the lower-only rule forbids.
4. **DDA is always on**: `get_difficulty_multiplier()` remaps a performance score to 0.75-1.25 on every difficulty
   (`game_manager.gd:1078-1079`); enemies divide telegraph and cooldown by it (`field_boar.gd:120, 253`;
   `broken_mile_guardian.gd:101, 200`; `enemy_base.gd:557`). §12.1 says DDA is off from Medium up.
5. **Constants the profiles replace** (`player_combat.gd` unless noted): `PARRY_WINDOW = 0.18` s (:120, about 11
   frames, scaled by the `extended_parry` charm at :1240); dash i-frames `DASH_DURATION = 0.18` + `DASH_IFRAME_TAIL =
   0.05` s (:43-44, about 14 frames); `telegraph_duration = 0.45` (`enemy_base.gd:71`), `CHARGE_TELEGRAPH = 0.6`
   (`field_boar.gd:16`), `STOMP_TELEGRAPH = 0.45` and `CHARGE_TELEGRAPH = 0.6` (`broken_mile_guardian.gd:22-23`).
6. **Healing conflict**: §12.1 lists healing *charges*, but healing costs MP (`HEAL_COST = 20.0`, `HEAL_AMOUNT = 30.0`,
   `player_combat.gd:109-111`; `MP_REGEN_PER_SEC = 2.0`, :110), as decided 2026-10-04 (ROADMAP:238). The GDD must say
   what the healing row means in an MP model.
7. **Downstream contract**: `time-model.md` takes leniency as integer percents and requires every main-story value
   ≥ 70 % (F5; the convoy floor is 63 %, F6); its Dependencies say "S06c must list this GDD as a dependent".

---

## Acceptance Criteria

- [ ] AC-1 **The GDD.** `design/gdd/difficulty-profiles.md`, written from the template, has these H2 headings in
      order: Overview, Player Fantasy, Detailed Rules (or Detailed Design), Formulas, Edge Cases, Dependencies, Tuning
      Knobs, Acceptance Criteria; the only other H2 headings allowed are Summary, Cross-References and Open Questions
      (decisions go under Detailed Design as H3). Each section is shown to the user and approved before the next; the evidence README
      records each approval (section, date, the user's words).
- [ ] AC-2 **Five profiles as data.** A table `parameter | beginner | easy | medium | hard | hell | unit | source` with
      at least the rows `parry_window`, `dodge_iframes` (frames at 60 fps), `boss_telegraph`, `enemy_damage`,
      `deadline_leniency` (integer percents), `boss_patterns`, `healing`, `dda`, `loot`. Every cell is filled; every
      `source` is a ROADMAP line or a dated user decision. Each `deadline_leniency` value is ≥ 70 (time-model F5), and for
      every profile the Chapter 1 bridge keeps its margin: `scale(300) − 180 ≥ 30` with `scale(x) = (x × L + 50) div
      100` (time-model F5; at L 70 the slack is exactly 30). The `healing` row names its unit in the MP model (Audit 6),
      and the GDD holds one dated decision line on whether the build's `player_dmg` knob stays.
- [ ] AC-3 **Constants map.** A table `parameter | constant | file_line | token | current_value | becomes` listing every
      constant in Audit 5, the healing constants (`HEAL_COST`, `HEAL_AMOUNT`, `MP_REGEN_PER_SEC`), each
      `DIFFICULTY_MULTS` entry (`"enemy_dmg"`, `"player_dmg"`, `"dda_floor"`, `"dda_ceil"`), the DDA score bounds
      (`DDA_SCORE_FLOOR`, `DDA_SCORE_CEILING`, `game_manager.gd:50-51`) and the DDA remap (`game_manager.gd:1079`).
      `token` is a literal substring that the cited line contains (e.g. `PARRY_WINDOW`, `"enemy_dmg"`, `remap(`);
      `becomes` names the AC-2 row that replaces the constant, or reads `removed (decision <date>)`.
- [ ] AC-4 **Old-setting mapping.** A table `old_value | old_name | profile` with one row each for 0-3 (`STORY`,
      `EASY`, `NORMAL`, `HARD`) and a row `other/missing | — | medium`; Hell has no old value. The rationale states
      what the mapping changes for a player (for example, build Normal's parry is about 11 frames against Medium's
      6). One line `persistence: global` or `persistence: per-run` says whether difficulty stays a global setting or
      becomes part of each run's save, because the lower-only rule needs to know what a "run" is.
- [ ] AC-5 **Rules.** The lower-only mid-run change rule (ROADMAP:480), including what the pause screen does today
      (Audit 3) and what it must do; the DDA scope per profile against the build's always-on DDA (Audit 4); Hell's
      prerequisites (fixed tick, input buffer, latency calibration, replay fairness) each named with an owner story or
      marked unowned. Dependencies list `time-model.md` (leniency) and the combat scripts in Audit 5.
- [ ] AC-6 **Balance check.** Before the run, Tuning Knobs states a safe range for every AC-2 numeric row, so
      `/balance-check` has targets. `/balance-check design/gdd/difficulty-profiles.md` is run, its report saved (its
      option B) and copied to the evidence folder as `balance-check.md` with its Health line. Every outlier it raises is
      fixed or has a disposition line in the GDD; a NOT ASSESSED health result names its reason.
- [ ] AC-7 **Checked, reviewed, evidenced.** `production/qa/evidence/2026-11-difficulty/check_difficulty_profiles.py`
      (run with `python -I -B`) fails unless: the 8 headings are present in order; the AC-2 table has the five profile
      columns and every required row with no empty cell; every `deadline_leniency` value is an integer ≥ 70; every
      AC-3 `file_line` resolves to a line that contains its `token`; the bridge margin holds for every profile; the
      AC-4 table maps 0, 1, 2 and 3 exactly once plus the `other/missing` row, and the `persistence:` line is present;
      `balance-check.md` exists in the evidence folder with a Health line.
      Watched failing once per mutation, one per run, transcripts kept: a missing heading, a dropped profile row, a
      leniency of 65, a constants-map line that does not contain its token, a dropped mapping row; an unmutated
      control run PASSes. `/design-review design/gdd/difficulty-profiles.md` returns APPROVED, or its concerns are fixed
      or accepted by the user, under the review exit rule in Decisions. The review is kept with a README mapping the
      ACs. `git diff --name-only 5646010 -- AethelgardPrototype/scripts AethelgardPrototype/scenes
      AethelgardPrototype/dialogue` is empty and kept as a log; `git diff --check` clean.

### Decisions (user, 2026-11-19)

- **Readiness gaps (2026-11-19, "Fix the core gaps"):** QL-STORY-READY returned GAPS. Fixed here: AC-3's
  unsatisfiable "line contains the named constant" (now a `token` column, the healing and DDA constants added,
  `removed (decision)` allowed); AC-6's target-less balance check; AC-1's extra-heading rule; AC-4's missing-value row
  and persistence line; the bridge margin per profile (AC-2). Not applied: pinning the 9×5 ROADMAP values in a
  fixture, monotonicity checks per row, checked Hell-prerequisite and pause-screen tables, and reading cited files
  via `git show 5646010` (the no-change log covers drift on this branch). Settle healing and `player_dmg` with the
  user before drafting section 3.
- **Review exit rule (2026-11-19, "Same as S06b"):** the Open Question 20 bar from round 1 — a finding blocks only with
  a failing check, a contradiction in the text, or a false citation. At most 2 review rounds; anything left after round
  2 is logged in the evidence README's "Recommended, not applied", not fixed.

---

## Implementation Notes

- Author section by section from the template; show each section before writing the next.
- Values are integers (frames, percents) so the time model's `scale()` and the checker read them exactly.
- "Lower difficulties forgive execution, not attention" (ROADMAP §12.1) is the test for every row: a row that removes a
  boss pattern or a telegraph on easy profiles needs a stated reason.
- Healing and `player_dmg` are design decisions for the user inside section 3, not for the story.
- Keep the checker small: the five named mutations and one control, no reference model.

---

## Out of Scope

- Wiring the profiles into code, the pause menu, the DDA or the save (Year 1 Phase 2 combat work; save is protected).
- Hell's fixed tick, input buffer, latency calibration and replay verification (named with owners, not designed here).
- Boss variants and the Hell-only phase content; loot tables (named as rows, not designed).
- Any change to scripts, scenes, dialogue, `time-model.md` or `storyline-axes.md`.
- No second GDD and no reference model.

---

## QA Test Cases

*Written by Claude from the QL-STORY-READY findings of 2026-11-19 against the revised ACs (the gate withheld its own
block because its verdict was GAPS); re-run `/qa-plan` to replace them with qa-lead specs if wanted.*

- **C1 (AC-1)**
  - Given: the GDD and the evidence README
  - When: the checker runs
  - Then: the 8 required H2 headings appear once each, in order; any other H2 is Summary, Cross-References or Open
    Questions; the README has one approval entry per section
  - Edge cases: a missing or swapped heading fails; an extra `## Decisions` fails
- **C2 (AC-2)**
  - Given: the profile table
  - When: the checker runs
  - Then: the columns are `parameter | beginner | easy | medium | hard | hell | unit | source`; the 9 required rows
    exist with no empty cell; every `deadline_leniency` value is an integer ≥ 70; `scale(300) − 180 ≥ 30` for each
    profile's leniency; a dated `player_dmg` decision line exists
  - Edge cases: leniency 65 fails; leniency 70 passes with slack exactly 30; a dropped row fails
- **C3 (AC-3)**
  - Given: the constants map and the files at HEAD
  - When: the checker runs
  - Then: every `file_line` exists and its line contains `token`; every `becomes` is an AC-2 row or
    `removed (decision <date>)`
  - Edge cases: a token moved to another line fails; a `becomes` naming no row fails
- **C4 (AC-4)**
  - Given: the mapping table
  - When: the checker runs
  - Then: 0, 1, 2 and 3 each appear once; an `other/missing` row maps to medium; no row maps to hell; a
    `persistence:` line is present
  - Edge cases: a dropped row fails; a duplicate old value fails
- **C5 (AC-5)**
  - Given: the Detailed Design and Dependencies sections
  - When: the reviewer reads them
  - Then: the lower-only rule, the pause screen's current and required behaviour, DDA per profile, and Hell's four
    prerequisites each with an owner or `unowned` are stated; Dependencies name `time-model.md`
  - Edge cases: review item, not a checker item
- **C6 (AC-6)**
  - Given: safe ranges in Tuning Knobs
  - When: `/balance-check` runs and its report is copied to the evidence folder
  - Then: `balance-check.md` exists with a Health line; each outlier is fixed or has a disposition line in the GDD
  - Edge cases: a NOT ASSESSED health result must name its reason
- **C7 (AC-7)**
  - Given: the mutations and the control
  - When: each runs alone
  - Then: each mutation logs RESULT FAIL and the control PASS; the kept `git diff --name-only 5646010 --
    AethelgardPrototype/scripts scenes dialogue` log is empty; `git diff --check` is clean; the design review ends
    within 2 rounds or its remaining items are in the README's "Recommended, not applied"

---

## Test Evidence

**Story Type**: Integration
**Required evidence**: `production/qa/evidence/2026-11-difficulty/check_difficulty_profiles.py` (passing, watched
failing on each named mutation), the `/balance-check` report, the `/design-review` report, and the evidence README (AC
map, per-section approvals).
**Run result**: N/A — a design document; nothing in the game changes.

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Y1-P0-S06b (done 2026-11-19) — the leniency contract (integer percents, ≥ 70 %).
- Unlocks: Year 1 Phase 2 combat wiring (the constants map); T15 is not blocked by it.

---

## Completion Notes
**Completed**: 2026-11-21 (verdict COMPLETE WITH NOTES; closed by the user: "Close the story")
**Criteria**: 7/7 met (none deferred). AC-1's per-section approvals rest on the evidence README's table (the user's
picked options), not on a machine check. AC-2's healing unit and dated `player_dmg` decision, AC-5's rules and AC-6's
dispositions are review items; the checker covers headings, the profile table, leniency and the bridge margin, the
constants-map tokens, the old mapping and `persistence: per-run`, and the presence of the balance report.
**Verified 2026-11-21 at revision 3**: `check_difficulty_profiles.py` RESULT PASS (0 problems); 7 mutations FAIL as
expected (the story's five plus `persistence_global`, `mapping_swapped`), control PASS; `git_diff_game_dirs.log`: 0
files under `scripts`, `scenes`, `dialogue` since `5646010`; `git diff --check` clean; `/balance-check` CONCERNS (no
outliers; time-to-kill NOT ASSESSED, no enemy data), dispositions in the GDD.
**Design review**: reviewed at revision 2; revision 3 accepted by the user. Round 1 (full, 5 specialists +
creative-director) NEEDS REVISION, 9 blockers, fixed in revision 2 with user decisions D1 (assist timing-only, helps
only) and D2 (accessibility toggles a separate axis, "(assisted)" clears). Round 2 (lean, the last under the cap) NEEDS
REVISION, 2 acceptance-criteria blockers (AC9, AC11), fixed in revision 3 without a third round by user decision;
revision 3 changed only AC9, AC11 and the status line. The review-log receipt is of revision 2. **Y1-P2-T12 and
Y1-P2-T22 must have AC9 and AC11 checked by someone other than the author before using them as test specs.** 12
round-2 and the round-1 leftover recommendations are in the evidence README, "Recommended, not applied".
**Deviations** (ADVISORY, approved by the user; the AC text above was not amended):
- AC-2: healing is "heal casts per rest" (a cap on the MP heal), not the ROADMAP's free-standing charges.
- AC-2: the assist (DDA) ranges, the telegraph floor and the old-setting "what changes" column are this GDD's
  proposals, not ROADMAP values.
- AC-7: two extra mutations beyond the five named.
- Not built from the readiness gate: a pinned ROADMAP-value fixture, per-row order checks, checked Hell and
  pause-screen tables, `git show` reads of cited files.
- Estimate 1 day (budget 2); actual 2026-11-19 to 2026-11-21, including 2 review rounds and a balance check.
**Test Evidence**: Integration — `production/qa/evidence/2026-11-difficulty/` (checker, mutation logs, no-change log,
balance report copy, README with AC map, approvals, review status, known limits); review log
`design/gdd/reviews/difficulty-profiles-review-log.md`; balance report `design/balance/balance-check-difficulty-profiles-2026-11-21.md`.
**QA coverage gate (QL-TEST-COVERAGE, qa-lead)**: GAPS, all advisory, on the condition that this note says revision 3
was accepted, not reviewed (done above). Gaps: the checker does not parse Formulas, Edge Cases or the GDD's ACs, where
round 2's blockers sat (the README's Known limits says so); GDD AC6-AC12 and the 14 Edge Cases have no executable test
until the Y1-P2 stories carry them; the balance-report check only looks for "Health"; some checker branches (`becomes`
validation, a mapping to hell, a missing report, an extra H2) have no mutation. The stale README revision line and GDD
header dates were corrected at close.
**Code Review**: Skipped — LP-CODE-REVIEW not run: no game implementation files; the Python files are non-shipping
evidence tooling.
**Handed to later stories**: Y1-P2-T12 (wire the profiles: re-grep every assist reader, boss and hazard telegraphs,
the settings key, the lower-only selector, disclosure), Y1-P2-T44 (accessibility axis and "(assisted)"), Y1-P2-T22
(Hell validation incl. latency), Y1-P2-T02/T03 (fixed tick, input buffer), Y1-P1-T05 (save `difficulty` and `assisted`,
legacy mapping; protected schema). Integration tests that set `Difficulty.NORMAL` need updating when the enum changes.
