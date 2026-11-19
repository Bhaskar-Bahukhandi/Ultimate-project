# Evidence: time model GDD (story Y1-P0-S06b)

Story: `production/epics/y1-p0-stabilize/story-s06b-time-model.md` · GDD: `design/gdd/time-model.md` (revision 3) ·
Written 2026-11-19 · Base commit for the no-change check: `f745aeb`.

This folder holds a document lint and its transcripts. The checker proves the text is consistent and that its
citations resolve to the files it names. It does not prove the time model is a good design: that is the review's job
and, later, playtest's.

## Files

| file | what it is |
|---|---|
| `check_time_model.py` | the checker; run `python -I -B check_time_model.py` from anywhere (it derives the repo root) |
| `check_pass.log` | the checker on the GDD as written: `RESULT: PASS (0 problems)` |
| `run_mutations.py` | runs ONE mutation per invocation on a temp copy, writes `mutation_<name>.log`; pass an absolute `--root` |
| `mutation_*.log` | 9 mutations FAIL as expected, 1 control PASS as expected, all run against the final scripts |
| `git_diff_game_dirs.log` | the no-change check: 0 files differ under `scripts`, `scenes`, `dialogue` since `f745aeb`; `git diff --check` clean |

## AC map

| story AC | evidence | status |
|---|---|---|
| AC-1 the GDD, 8 sections approved in turn | headings check (`mutation_missing_heading.log`); approvals table below | met; the "approved before the next section" part rests on the table below, not on a machine check |
| AC-2 WorldClock contract | GDD Detailed Design (Core Rules 1-8, stop table, saved-fields table), Formulas F1-F3 with worked examples | met as text, review-only: no checker covers it. The GDD's AC1-AC6 and AC8-AC11 are WorldClock v1 unit and integration tests; only AC7, AC12 and AC13 run now |
| AC-3 timing types as data | field table (all four types covered: `mutation_field_type_removed.log`); 40-row TS table (`mutation_dropped_ts_row.log`, `mutation_ts_type_swapped.log`, `mutation_pm_line_off_by_one.log`) | met |
| AC-4 the two live deadlines | bridge and convoy sections; outcome flags found in code (`mutation_bogus_flag.log`); margins for the five leniency values (`mutation_margin_broken.log`) | met; the flags and the F5/F6 margins are checker-covered, the start events, clock times, signposts, what stays authored and the worked numbers (F4-F8, AC8) are review-only |
| AC-5 pace and timing flags | pace table: 12 flags, 3 `existing` found in code, 9 `new` absent (`mutation_missing_pace_name.log`, `mutation_renamed_pace_flag.log`); the Open Question 4 decision is dated | met for act 1; the act 2-4 rule is left open by user decision D3 (2026-11-19), so the story's "rule that sets each act's pace" holds only for act 1 |
| AC-6 checked, reviewed, evidenced | checker PASS; the eight named mutations plus one extra (`margin_broken`) FAIL, control PASS; no-change log | met by "concerns fixed or accepted by the user": rounds 1 and 2 returned NEEDS REVISION; revision 3 fixed round 2's blocker and was not independently reviewed (user decision, 2-round cap) |

## Section approvals (AC-1)

Each section was shown to the user as a draft before it was written. The user's answer was the option they picked.

| section | date | user's words |
|---|---|---|
| Header, Summary, 1 Overview | 2026-11-19 | "Approve, write it" |
| 2 Player Fantasy | 2026-11-19 | "Approve, write it" |
| 3 Detailed Design, part A (clock contract); season = one 28-day month | 2026-11-19 | "Approve, write 3A"; "Season = one 28-day month (Recommended)" |
| 3 Detailed Design, part B (timing types, 40 PM quests) | 2026-11-19 | "Approve, write 3B" |
| 3 Detailed Design, part C (the two deadlines, pace, flags, signposting); Open Question 4 = option A | 2026-11-19 | "Approve, write 3C"; "A: road choice only (Recommended)" |
| 4 Formulas (F1-F8) | 2026-11-19 | "Approve, write it" |
| 5 Edge Cases (14), plus the skip-cap sentence added to Core Rule 4 | 2026-11-19 | "Approve, write it" |
| 6 Dependencies and 7 Tuning Knobs, together | 2026-11-19 | "Approve, write both" |
| 8 Acceptance Criteria (AC1-AC14) | 2026-11-19 | "Approve, write it" |

Edits after approval, for the record (neither was in the draft the user approved):
- Section 7 gained one sentence (safe ranges hold with the other knobs at default; F5 and F6 are the pass test for a
  combination). It was disclosed to the user in the next question, not before it was written.
- AC7's wording was tightened: "same for the convoy" became "the convoy fails for L 0.60 (slack 24)", because the
  convoy still passes at L 0.65 (slack 36). This was not shown to the user before it was written.

Core Rule 4's skip cap was shown and approved together with Edge Cases.

## Decisions (user, 2026-11-19)

- Review exit rule: the Open Question 20 bar from round 1, at most 2 rounds; what remains after round 2 goes to the
  section below, not into the GDD.
- Season length: one season is one month (year = 112 days).
- Open Question 4 (what sets Act 1's pace): road choice only, as built; missed deadlines are carried by timing flags.
- Readiness gaps (QL-STORY-READY, "Fix the core gaps"): fixed in the story; the README approval-row count, the pinned
  AC-2 tables and a `file:line` citation resolver were not built.

## Review status

- **Round 1 (2026-11-19, full: game-designer, systems-designer, qa-lead, godot-specialist, narrative-director;
  creative-director synthesis): NEEDS REVISION, 7 blockers.** Log: `design/gdd/reviews/time-model-review-log.md`
  (receipt = revision 1). User: "Revise now".
- **User decisions for revision 2 (2026-11-19):** D1 "Fixed dusk, L = min window (Recommended)"; D2 "Climb jumps to
  dusk (Recommended)" (applied as: the climb moves the clock to the medicine's `deadline_min`, the quest's own evening
  bell); D3 "Leave the rule open (Recommended)".
- **Revision 2 (blocker → fix):**
  1. Deadline both dusk and L-scaled → `closes_at_time` field; F4 closes at the first dusk at least `scale(window)`
     after start; the bridge starts the clock at `dusk_min − scale(300)`; anchors and `max_anchor_skip_min` removed.
  2. Scenes stating a time → `advance_until(target_min)` (uncapped, forward only, prompts before crossing a deadline
     the scene does not own); shrine uses bridge `deadline_min + 60`, tower uses medicine `deadline_min`.
  3. Bridge turn-back / overlap → the one-shot fix/warn/wait choice is the turn-back (F5 guarantees it);
     `evacuated` co-occurs with `fell` as built; AC8 rewritten.
  4. Same-minute order → Core Rule 9 (completion at t ≤ D meets D; completions before closures; `ts` field).
  5. AC3 precedence → stop table reordered, first matching row reported; `blocks_gameplay` false does not stop.
  6. Pace rows → acts 2-4 rule open with the PM's own triples cited; the OQ4 consequences stated.
  7. Errata → AC7 scoped to what the checker checks; F6 floor 176; L as integer percents (`scale()`).
  Also applied (recommended, cheap): `deadline_min` saved row, tick-injection seam `tick(n)`, `time_passes` owner,
  Player Fantasy replay wording, Edge Case 11 marked unverified, Edge Case 15 (inherited scene times).
- **Round 2 (2026-11-19, lean, the last under the cap): NEEDS REVISION, 1 blocker, 9 recommended.** Revision 2
  resolved round-1 blockers 1 and 3-7; every worked number recomputed correct; no false citation. Blocker: the late
  side of round-1 blocker 2 (`advance_until` is forward-only, so the after-dark and tower-bell lines are false when the
  scene is reached after its target). User decision: fix it in revision 3, no third round; the 9 recommended items go
  below.
- **Revision 3 (2026-11-19):** the two claims in Detailed Design C and Core Rule 4 are narrowed to scenes reached
  before their target; Edge Case 16 states what happens after it (the clock's outcome stands, the scene must not
  assert elapsed time or replay the bell; WorldClock v1 gates the lines, with the user's approval for the protected
  dialogue). Not re-reviewed, by the user's decision.

## Recommended, not applied

Findings left after the review's second round, or accepted as advisory, are logged here and not fixed in the GDD.
From round 1 (not applied in revision 2):
- `warning_lead_min` ≥ cost + margin, so the notice comes before the point of no return (game-designer, CD).
- An owner for making time visible to the player: HUD clock, dusk cue, wait and rest as actions (game-designer, CD).
- Real-time slack: at `real_minutes_per_day` 6 and Hell, 75 game minutes is 18.75 real seconds (systems-designer).
- F8 bands can collapse for tiny Durations (fast 3, slow 4 at 85 %) (systems-designer).
- Safe-range corners combine badly; the ranges are scoped to "other knobs at default" (systems-designer).
- `tick_acc` on a `real_minutes_per_day` change should rescale (`acc × new div old`), not `mod` (systems-designer).
- Edge Case 7: a boss-checkpoint retry is not a load (godot-specialist).
- JSON save reloads integers as floats; `int()` on load; per-quest timing needs a named save owner (godot-specialist).
- The medicine's on-time path (arena bracket then convoy) needs its real duration measured (game-designer).
- Uppercase PM timing names that do not match their scene lines (narrative-director).

From round 2 (not applied in revision 3):
- AC10: "a completion the jump records at 900" while that jump lands at 980; test a jump that lands on 900.
- Core Rule 6 / AC3: a context with `blocks_gameplay` false stops nothing only if `pauses_tree` is also false (no
  caller does that today).
- Interface sketch: say that `tick(n)` obeys the stop table.
- Edge Case 3: "no time is skipped to reach it" sits beside D2's tower jump; scope it to the deadline computation.
- Convoy: both `rem_go_now` (`ironhold_city.dlg:110`) and `rem_later` (`:115-116`) start the quest; name both.
- Timing types: `opens_at` is optional, but F7 needs it.
- Edge Case 14: a legacy Chapter 2 save from before Rem's request never starts the clock.
- Edge Case 15: "16:00" holds only at L 100 % (13:30 at 150 %, 16:45 at 85 %).
- Signposting rule: state that the bridge's one-shot choice satisfies rule 4.

## Known limits of the checker

- It does not check that the provisional numbers (300, 180, 240, 120, 30, 60, 120, 1080) are good, only that they
  satisfy F5 and F6 together with the five leniency values.
- `file:line` citations in the GDD prose are not resolved by the checker (only `pm_line` and flag names are).
- The Acceptance Criteria and Formulas text are never parsed: their worked numbers (AC1-AC6, AC8-AC11) are review
  items and WorldClock v1 tests. F5 and F6 are evaluated only at the Tuning Knobs defaults (AC7).
- Section approvals, worked examples and the signposting rule are review items.
- Comment stripping for flag lookup removes only whole-line `#` comments; the `new`-flag check ignores that and
  rejects any occurrence, including in comments.
- Everything marked "WorldClock v1" in the GDD's Acceptance Criteria is unverified until that story builds the clock.
