# Story S06b: The time model GDD — WorldClock, the four quest timing types, the two live deadlines and pace per act

> **Epic**: Y1-P0 Stabilize (Sprint 001)
> **Task ID**: Y1-P0-S06b (`production/plan/_source/Y1-P0.json#Y1-P0-S06`, day 3; sprint plan row Y1-P0-S06)
> **Status**: Complete
> **Layer**: Foundation (design)
> **Type**: Integration
> **Estimate**: 1 day in the plan; budget 2 days. S06a's 2-day estimate ran to 11 days over 16 review rounds, so this
> story sets its review exit rule before the first review (AC-6).
> **Manifest Version**: N/A — `docs/architecture/control-manifest.md` does not exist
> **Last Updated**: 2026-11-19

## Context

**GDD**: this story writes `design/gdd/time-model.md` (new). **Source of record**: the plan entry (S06 day 3, "Time
model: WorldClock and quest timing types"; done "Time model doc that WorldClock v1 (Y1-P1) can implement directly";
edge case "Deadline leniency ×0.85 on Hell must not make the Ch1 bridge impossible"), `ROADMAP_10_YEAR.md` §12.4 and
§12.1 (leniency row), `AethelgardPrototype/story/STORY_BIBLE.md` Timing (lines 165-173), and the production master's
TIME-SENSITIVE QUEST INDEX (PM:11953-12473). **Requirement**: N/A — no TR-ID registered.

**ADR Governing Implementation**: N/A — a design document; no architectural decision. The WorldClock contract it
defines is input to WorldClock v1 (Y1-P1), not an implementation.

**Engine**: N/A — no engine API. **Control Manifest Rules**: NOT ASSESSED — no control manifest.

**Performance**: none — documentation only.

**AGENTS.md protected areas**: none touched. No file under `AethelgardPrototype/scripts`, `scenes` or `dialogue`
changes. The bridge stays instant to fix and the bell stays event-driven in the build; the GDD describes how they move
onto the clock, it does not move them. Story progression and save/load are described, not changed.

### Audit (2026-11-19, read-only; HEAD `f745aeb`)

1. **ROADMAP §12.4** (ROADMAP:511-528): day/night, days, a ~28-day month, 4 seasons; one in-game day ≈ 24 real
   minutes (tunable); deterministic and saved; waiting or resting advances it. Timing types Window / Deadline / Order /
   Duration. Each act tracks a pace value (early / on-time / late) and named timing flags, which change scenes, NPC
   fates, market events and ending slides through the composer but never create storylines. Fairness: deadlines in the
   quest log with an in-world reason; difficulty scales leniency (§12.1); main-story deadlines never fail without a
   signposted warning; Story+ shows what timing changed. Testing: seeded RNG and clock, a bot running fast, slow and
   out-of-order profiles. ROADMAP:241 — WorldClock v1 is "deterministic, saved, pausable, and owned by ContextStack's
   time rules"; ROADMAP:235 — "Move the bridge deadline onto the WorldClock (fixing it is instant today)".
2. **Leniency** (ROADMAP §12.1): quest deadline leniency ×1.5 / ×1.25 / ×1.0 / ×1.0 / ×0.85 (Beginner → Hell).
   `storyline-axes.md:790` says deadline leniency belongs to the time model; the values belong to S06c.
3. **Pause owner**: `scripts/core/context_stack.gd` is the only writer of `get_tree().paused` and
   `Engine.time_scale` (`push`/`pop`, `gameplay_blocked()`, `request_time_scale`). No WorldClock exists in code.
4. **The two live deadlines**:
   - **Ch1 north bridge** (C1-S07, PM:1718-1730, TS02 at PM:11967 "Timing type: Deadline", "Before overnight rain";
     Story Bible "Until dark, day 1"). Today: accepting the repair runs a `time_passes` event and sets
     `ch1_bridge_saved` on the spot (`ch1_oakhaven_village.gd:600-602`); "after dark" in `ch1_shrine.gd:128-136` sets
     `ch1_bridge_fell` if the bridge was seen and not saved. Flags `ch1_bridge_saved` / `_evacuated` / `_fell`
     (and `_repair_accepted`, `_ignored`).
   - **Ch2 medicine convoy** (C2-S06, PM:2264 "Deadline visible: before next evening bell", TS05 at PM:12006). Today
     the bell is the Clock Tower stopping when the player climbs it (`ironhold_city.dlg:93-97`); the tower gate warns
     first with a chance to turn back (`ironhold_region.gd:643-647`). Flags `ch2_medicine_early` / `_on_time` /
     `_late`.
5. **Act 1 pace**: `dialogue/ch2/act1_end.dlg:31-43` sets `act1_pace_early` / `_on_time` / `_late` from the road
   choice (server road / safe road / caravan). PM:2869-2871 defines LATE as "many rests missed convoy or ignored
   warnings" — the open mismatch `storyline-axes.md` Open Question 4 hands to S06b. PM:2872 "No pace is automatically
   bad."
6. **Time-sensitive quests**: PM:11953 lists 40 (TS01-TS40), each with a `Timing type:` line: 15 Window, 14
   Deadline, 5 Order, 6 Duration. Each also states the quest-log warning, a difficulty rule and a save rule.
7. **Downstream contract**: `storyline-axes.md:469-471` — the composer record holds `timing_flags`, `act1_pace`, and
   `act2_pace` / `act3_pace` / `act4_pace` with "UNSET and the names S06b defines", owner Y1-P0-S06b; `:782` — "S06b
   must list this GDD as a dependent". PM acts: ACT 1 (PM:1130), ACT 2 (:3131), ACT 3 (:6710), ACT 4 (:7654).

---

## Acceptance Criteria

- [ ] AC-1 **The GDD.** `design/gdd/time-model.md`, written from `.claude/docs/templates/game-design-document.md`, has
      exactly these H2 headings in order: Overview, Player Fantasy, Detailed Rules (or Detailed Design), Formulas, Edge
      Cases, Dependencies, Tuning Knobs, Acceptance Criteria. Each section is shown to the user and approved before the
      next; the evidence README records each approval (section, date, the user's words).
- [ ] AC-2 **WorldClock contract.** The GDD states: the clock's units and their sizes (minute, hour, day, a 28-day
      month, 4 seasons) with one in-game day = `real_minutes_per_day` (default 24, a Tuning Knob with a safe range);
      the saved fields (a table `field | type | range | default`); that the clock reads no wall-clock time and advances
      only from a fixed per-frame step, waiting and resting; exactly when it stops, by `ContextStack` state
      (`get_tree().paused`, `gameplay_blocked()`), and whether `Engine.time_scale` (hitstop, slow-mo) scales it; what
      cutscenes, dialogue and scene transitions do to it. Formulas give every conversion with variables, ranges and
      one worked example each.
- [ ] AC-3 **Timing types as data.** A table `field | type | allowed | timing_type` defines the quest fields for
      Window, Deadline, Order and Duration (each type's required fields; leniency applies to Deadline only, or the GDD
      says which others and why). A second table `ts | title | timing_type | pm_line` lists all 40 PM time-sensitive
      quests, each `timing_type` equal to its PM `Timing type:` line (15 / 14 / 5 / 6) and `pm_line` pointing at that
      quest's heading.
- [ ] AC-4 **The two live deadlines in clock terms.** For the Ch1 bridge (TS02) and the Ch2 medicine convoy (TS05):
      the start event, the deadline as a clock time, each outcome's existing flag name, the signpost (who says it, the
      quest-log line), what today's event trigger (`time_passes`; the Clock Tower bell) becomes on the clock, and
      what stays authored. The plan's edge case as numbers: the GDD states `base_deadline_min` (start event to dark),
      `repair_duration_min` and `margin_min` for the bridge, and the inequality
      `base_deadline_min × L − repair_duration_min ≥ margin_min`, evaluated for L ∈ {1.5, 1.25, 1.0, 1.0, 0.85} with
      every result shown (§12.1 values cited as provisional inputs; S06c owns them). The checker evaluates it and
      fails if any L breaks it.
- [ ] AC-5 **Pace and timing flags.** A table `act | flag_early | flag_on_time | flag_late | status | rule | source`
      with one row per act 1-4: every flag matches `act{1-4}_pace_(early|on_time|late)`; `status` is `existing`
      (act 1, the names in `act1_end.dlg`) or `new` (acts 2-4); `rule` says what sets the act's pace. One line records
      the decision on Open Question 4 (Act 1 late: road choice, PM:2871's missed rests and ignored warnings, or both),
      marked "user decision, <date>". The GDD also states the timing-flag naming rule and the signposting rule (what
      counts as a warning, when it must appear, the turn-back chance). Dependencies list `storyline-axes.md` as a
      dependent that reads these names; any edit to `storyline-axes.md` itself is a separate change with its own OK.
- [ ] AC-6 **Checked, reviewed, evidenced.** `production/qa/evidence/2026-11-time-model/check_time_model.py` (run with
      `python -I -B`) fails unless: the 8 headings are present in order; the TS table has TS01-TS40 once each, with
      types matching their PM `Timing type:` lines and each `pm_line` on that quest's `## TSnn` heading; the AC-3 field
      table covers the four types; the AC-4 outcome flags and the AC-5 rows marked `existing` are found in
      `AethelgardPrototype/scripts` or `dialogue`, and the rows marked `new` are found in neither; the AC-5 table has
      12 flags matching the pattern; the AC-4 inequality holds for all five L. Watched failing once per mutation, one
      per run, transcripts kept: a missing heading, a dropped TS row, a TS type swapped, a bogus flag, a missing pace
      name, a timing type removed from the field table, a `pm_line` off by one, a renamed pace flag; an unmutated
      control run PASSes. The `git diff` result below is kept as a log in the evidence folder. **Review exit rule, set before round 1:** `/design-review design/gdd/time-model.md` returns
      APPROVED, or its concerns are fixed or accepted by the user, under the review exit rule in Decisions (the
      Open Question 20 bar, at most 2 rounds). The review is kept with a README mapping the ACs. `git diff --name-only f745aeb --
      AethelgardPrototype/scripts AethelgardPrototype/scenes AethelgardPrototype/dialogue` is empty; `git diff --check`
      clean.

### Decisions (user, 2026-11-19)

- **Review exit rule (2026-11-19, "OQ20 bar, max 2 rounds"):** S06a's Open Question 20 bar applies from round 1 — a
  finding blocks only with a failing check, a contradiction in the text, or a false citation. At most 2 review
  rounds; anything left after round 2 is logged as recommended, not fixed, in a "Recommended, not applied" section
  of the evidence README.
- **Readiness gaps (2026-11-19, "Fix the core gaps"):** QL-STORY-READY returned GAPS; the AC-6 contradiction
  (new act 2-4 names cannot exist in code yet), AC-4's unquantified edge case, AC-5's unstructured pace output and
  the mutation set were fixed in this story. Not applied: a README approval-row count, pinned AC-2 tables and a
  `file:line` citation resolver; AC-1's section approvals and AC-2's worked examples stay review items.

---

## Implementation Notes

- Author section by section from the template; show each section before writing the next (design-docs rule).
- Every rule cites its source (`file:line`); a choice with no source is marked as the user's decision with a date.
- The clock is deterministic: its state is a function of saved fields and inputs, never of real time, so the
  ROADMAP's fast / slow / out-of-order bot can replay it.
- Timing changes scenes, NPC fates and slides, never the storyline ID (ROADMAP §12.4, `storyline-axes.md` Edge Case 7).
- Keep the checker small: the eight named mutations and one control, no reference model.

---

## Out of Scope

- Implementing WorldClock or moving the bridge and bell onto it (WorldClock v1, Y1-P1).
- The difficulty values themselves and the constants map (S06c); this GDD only says how leniency applies.
- NPC schedules, market and auction timing, limited editions (later ROADMAP items).
- Per-quest clock values for the other 38 TS quests (typed here, timed when each quest is built).
- Any change to scripts, scenes, dialogue, or to `storyline-axes.md`.
- No second GDD and no reference model (S06a grew both); a need for either is raised with the user, not built.

---

## QA Test Cases

*From QL-STORY-READY (qa-lead, 2026-11-19), written against the revised ACs:*

- **C1 (AC-1)**
  - Given: the GDD and the evidence README
  - When: the checker runs
  - Then: the 8 H2 headings appear in order; the README has one approval entry per section (section, date, words)
  - Edge cases: a swapped or missing heading fails
- **C2 (AC-2)**
  - Given: the saved-fields table and the stop rules
  - When: the checker runs and the reviewer reads Formulas
  - Then: the table header is `field | type | range | default`; `real_minutes_per_day` defaults to 24 with a range;
    paused, `gameplay_blocked`, `time_scale`, cutscene, dialogue and transition each have a stated clock behaviour;
    each conversion has a worked example (review item)
  - Edge cases: no rule for `Engine.time_scale` is a review finding
- **C3 (AC-3)**
  - Given: the type-field table and the TS table
  - When: the checker runs
  - Then: all 4 types are covered; TS01-TS40 appear once each; types match PM; counts are 15 / 14 / 5 / 6; each
    `pm_line` is on its `## TSnn` heading
  - Edge cases: a duplicate TS, a swapped type, a `pm_line` off by one, a type removed from the field table
- **C4 (AC-4)**
  - Given: the TS02 and TS05 sections
  - When: the checker runs
  - Then: the outcome flags exist in code or dialogue; the bridge inequality holds for all five L, Hell's numbers shown
  - Edge cases: a value that makes L = 0.85 negative fails
- **C5 (AC-5)**
  - Given: the pace table
  - When: the checker runs
  - Then: 12 flags match `act{1-4}_pace_(early|on_time|late)`; `existing` rows are in code; `new` rows are not; the
    OQ4 decision line is present
  - Edge cases: `act3_pace_slow` fails the pattern; a renamed pace flag fails
- **C6 (AC-6)**
  - Given: the eight mutations and the control
  - When: each runs alone
  - Then: each mutation logs RESULT FAIL and the control PASS; the kept `git diff --name-only f745aeb --
    AethelgardPrototype/scripts scenes dialogue` log is empty; `git diff --check` is clean; `/design-review` reaches
    APPROVED within 2 rounds or its remaining items are in the README's "Recommended, not applied" section

---

## Test Evidence

**Story Type**: Integration
**Required evidence**: `production/qa/evidence/2026-11-time-model/check_time_model.py` (passing, watched failing on
each named mutation), the `/design-review` report, and the evidence README (AC map, per-section approvals).
**Run result**: N/A — a design document; nothing in the game changes.

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Y1-P0-S06a (done 2026-11-19) — the composer record's `timing_flags` and pace fields this story names.
- Unlocks: Y1-P0-S06c (difficulty profiles: the leniency rule it fills with values), WorldClock v1 (Y1-P1).

---

## Completion Notes
**Completed**: 2026-11-19 (verdict COMPLETE WITH NOTES; closed by the user: "Close the story")
**Criteria**: 6/6 met (none deferred). AC-1's "approved before the next section" rests on the evidence README's
approvals table (option labels picked by the user), not on a machine check. AC-2 and parts of AC-4 (start events, clock
times, signposts, worked numbers) are review-only; the checker covers headings, the TS and field tables, flags, the
pace table and the F5/F6 margins at the Tuning Knobs defaults.
**Verified 2026-11-19 at revision 3**: `check_time_model.py` RESULT PASS (0 problems); 9 mutations FAIL as expected
(the story's eight plus `margin_broken`), control PASS; `git_diff_game_dirs.log`: 0 files under `scripts`, `scenes`,
`dialogue` since `f745aeb`; `git diff --check` clean.
**Design review**: round 1 (full, 5 specialists + creative-director) NEEDS REVISION, 7 blockers, fixed in revision 2;
round 2 (lean, the last under the cap) NEEDS REVISION, 1 blocker, fixed in revision 3. **Revision 3 was not
independently reviewed** (user decision, 2-round cap); the review-log receipt is of revision 2. The WorldClock v1
story (Y1-P1) must re-read Edge Case 16 and Core Rule 4 first. 19 recommended items are in the evidence README,
"Recommended, not applied".
**Deviations** (ADVISORY, each approved by the user on 2026-11-19; the AC text above was not amended):
- AC-5: the act 2-4 pace rule is left open (D3); only act 1's rule is stated.
- AC-2 / AC-4: anchors were replaced by `advance_until` and fixed-dusk deadlines (D1, D2), after review round 1.
- Leniency is stored as integer percents (`scale()`), not decimals.
- AC-6: one extra mutation (`margin_broken`) beyond the eight named.
- Not built from the readiness gate: a README approval-row count, pinned AC-2 tables, a `file:line` resolver.
- Estimate 1 day (budget 2); actual 1 day, 2026-11-19, including 2 review rounds.
**Test Evidence**: Integration — `production/qa/evidence/2026-11-time-model/` (checker, mutation logs, no-change log,
README with AC map, approvals, review status and known limits); review log `design/gdd/reviews/time-model-review-log.md`.
**QA coverage gate (QL-TEST-COVERAGE, qa-lead)**: GAPS, all advisory, on the condition that this note records the
un-reviewed revision 3 (done above). Gaps: AC-2 review-only; AC-4's worked numbers can change without the checker
noticing (start_min/deadline_min in AC8 were corrupted in a probe and the checker passed); the GDD's Edge Cases and most
of its ACs have no current test (WorldClock v1); section approvals are conversational evidence. The README AC map was
qualified at close to match.
**Code Review**: Skipped — LP-CODE-REVIEW not run: no game implementation files; the Python files are non-shipping
evidence tooling.
**Handed to later stories**: S06c must keep every main-story leniency ≥ 70 % (F5) and list `time-model.md` as a
dependency; WorldClock v1 (Y1-P1) implements the clock, the touchpoints and Edge Case 16's gated lines (protected
dialogue: user approval needed there); SaveService (Y1-P1-T05) stores the clock and per-quest fields.
