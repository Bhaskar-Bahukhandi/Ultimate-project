# Evidence: difficulty profiles GDD (story Y1-P0-S06c)

Story: `production/epics/y1-p0-stabilize/story-s06c-difficulty-profiles.md` · GDD: `design/gdd/difficulty-profiles.md`
(revision 3) · Written 2026-11-19 to 2026-11-21 · Base commit for the no-change check: `5646010`.

This folder holds a document lint, its transcripts and the balance-check report. The checker proves the text is
consistent and that the constants map points at real lines. It does not prove the profile values are good: that is the
balance check's, the review's and, later, playtest's job.

## Files

| file | what it is |
|---|---|
| `check_difficulty_profiles.py` | the checker; run `python -I -B check_difficulty_profiles.py` from anywhere |
| `check_pass.log` | the checker on the GDD as written: `RESULT: PASS (0 problems)` |
| `run_mutations.py` | runs ONE mutation per invocation on a temp copy, writes `mutation_<name>.log`; pass an absolute `--root` |
| `mutation_*.log` | 7 mutations FAIL as expected, 1 control PASS as expected (all re-run on revision 3, 2026-11-21) |
| `balance-check.md` | copy of `design/balance/balance-check-difficulty-profiles-2026-11-21.md` (Health: CONCERNS) |
| `git_diff_game_dirs.log` | the no-change check: 0 files under `scripts`, `scenes`, `dialogue` since `5646010`; `git diff --check` clean |

## AC map

| story AC | evidence | status |
|---|---|---|
| AC-1 the GDD, 8 sections approved in turn | headings check (`mutation_missing_heading.log`); approvals table below | met; "approved before the next section" rests on the table below |
| AC-2 five profiles as data | profile table: 9 rows, 5 profiles, no empty cell, integers (`mutation_dropped_profile_row.log`); leniency ≥ 70 and the bridge margin (`mutation_leniency_65.log`); healing unit and `player_dmg` decision in Core Rules 3-4 | met; the values' source column and the decisions are review items |
| AC-3 constants map | 31 rows, each token found on its cited line (`mutation_bad_token.log`); `becomes` is a row or `removed (` | met |
| AC-4 old-setting mapping | 0 → beginner, 1 → easy, 2 → medium, 3 → hard, other/missing → medium, no hell, `persistence: per-run` (`mutation_dropped_mapping_row.log`, `mutation_mapping_swapped.log`, `mutation_persistence_global.log`) | met; the "what changes" column is a review item |
| AC-5 rules | Core Rules 7-8, F9, the pause-screen and Hell-prerequisite tables, Dependencies | met as text, review-only |
| AC-6 balance check | `balance-check.md` (CONCERNS, no outliers; time-to-kill NOT ASSESSED, no enemy data); dispositions in the GDD's Tuning Knobs, "Balance-check notes" | met |
| AC-7 checked, reviewed, evidenced | checker PASS; 7 mutations FAIL (the story's five plus `persistence_global`, `mapping_swapped`), control PASS; no-change log | design review: see Review status |

## Section approvals (AC-1)

Each section was shown to the user as a draft before it was written; the user's answer was the option they picked.

| section | date | user's words |
|---|---|---|
| Header, Summary, 1 Overview | 2026-11-19 | "Approve, write it" |
| 2 Player Fantasy | 2026-11-19 | "Approve, write it" |
| Design decisions before section 3 | 2026-11-19 | "Heal casts per rest (Recommended)"; "Remove it (Recommended)" (player_dmg); "Per-run, stored in the save (Recommended)"; "By name (Recommended)" |
| 3 Detailed Design, part A (profiles, decisions, assist, lower-only) | 2026-11-19 | "Approve, write 3A" |
| 3 Detailed Design, part B (constants map, mapping, states, Hell prerequisites, pause screen) | 2026-11-21 | "Approve" (typed in chat after the question was interrupted) |
| 4 Formulas (F1-F9) | 2026-11-21 | "Approve, write it" |
| 5 Edge Cases (14) | 2026-11-21 | "Approve, write it" |
| 6 Dependencies and 7 Tuning Knobs | 2026-11-21 | "Approve, write both" |
| 8 Acceptance Criteria (AC1-AC12) | 2026-11-21 | "Approve, write it" |
| Balance-check dispositions (Tuning Knobs notes) | 2026-11-21 | "Save; note both in GDD (Recommended)" |

Edits after approval, for the record (none changes a rule; each was disclosed to the user in the next question):
- Part A: two line citations corrected (`pause_screen.gd:1266-1273`, `game_manager.gd:2168-2170`) and the line
  `persistence: per-run` added (the checker reads it; it states the approved decision).
- Edge Case 11: the example changed from a 0.35 s base ("15, not 14", which scales to 15 anyway) to a 20-frame base that
  scales to 14 and is held at 15.
- Tuning Knobs: "All defaults come from ROADMAP:466-474" corrected to say the assist and floor defaults are this GDD's
  proposals.

## Decisions (user)

- Review exit rule (2026-11-19): the Open Question 20 bar from round 1, at most 2 rounds; leftovers go below.
- Readiness gaps (2026-11-19, "Fix the core gaps"): recorded in the story's Decisions.
- Design decisions (2026-11-19): healing = heal casts per rest; `player_dmg` removed; difficulty per run in the save;
  old values mapped by name.
- Balance check (2026-11-21): Hell's healing step kept on purpose; Easy's loot parity accepted.

## Review status

- **Round 1 (2026-11-21, full: game-designer, systems-designer, qa-lead, godot-specialist, ux-designer;
  creative-director synthesis): NEEDS REVISION, 9 blockers.** Log: `design/gdd/reviews/difficulty-profiles-review-log.md`
  (receipt = revision 1). User: "Revise now".
- **User decisions for revision 2 (2026-11-21):** D1 "Timing only, helps only (Recommended)"; D2 "Separate axis, flags
  clear (Recommended)".
- **Revision 2 (blocker → fix):**
  1. Assist vs Rule 4 and the fantasy → assist is timing-only (telegraph length, attack cooldown) and never above 100;
     the player bonus and the multiplier's HP / damage / speed / corruption / soul-drain uses read 100; mapped as
     `removed (decision 2026-11-21)`; F4, F6, F7, AC6, AC12 and the tuning knobs updated.
  2. Accessibility toggles → Core Rule 10 (separate axis, stacks, "(assisted)" record, never a Hell clear); F2 gains
     the +6 term; Edge Cases 10 and 14; AC11 runs with both off.
  3. Dead telegraph constant → the five per-attack lines (`enemy_base.gd:428-436`) and the floor (`:440`) mapped;
     Core Rule 11 says the row scales every enemy.
  4. Hell owners and unlock → fixed tick Y1-P2-T02, latency Y1-P2-T22; one unlock rule (T02, T03, T22); AC10 split
     into pause screen (a) and new-game selector (b).
  5. DASH_DURATION row → "dash length unchanged; F3 derives the tail".
  6. States vs Edge Cases 2-4 → the lowered state lists when each row changes; telegraphs from the next attack.
  7. AC11 → "one frame late".
  8. Settings key → new key `gameplay/difficulty_profile` for the default; the old int key is read only for legacy
     mapping and never written (Core Rule 7, Edge Case 7, pause-screen table).
  9. AC4 checker → requires `per-run` and pins 0-3 → beginner..hard (two new mutations).
  Also applied (recommended, cheap): the lowering confirm line (Core Rule 8), assist disclosure (Core Rule 9), the NG+
  stacking note (Edge Case 8), a plan-divergence note in Dependencies.
- **Round 2 (2026-11-21, lean, the last under the cap): NEEDS REVISION, 2 blockers, 12 recommended.** All 9 round-1
  blockers resolved; every citation re-checked; checker PASS. Blockers: AC9's telegraph number ignored Easy's assist
  at the starting score (46 frames at score 50, not 45); AC11's "one frame late" could still parry inside a 2-frame
  window. User decision: fix both here, no third round; the 12 items go below.
- **Revision 3 (2026-11-21):** AC9 states 46 frames at the starting score 50 (tempo 98) and 45 at a score of 52 or more;
  AC11's reference press is the last frame of the window and the failing press is one frame after it. Not
  independently reviewed, by the user's decision.

## Recommended, not applied

Findings left after the review's second round, or accepted as advisory, are logged here and not fixed in the GDD.
From round 1 (not applied in revision 2; most belong to the Y1-P2 wiring stories T12, T44, T26):
- Re-grep every reader of the assist multiplier and bonus at wiring time; map boss and hazard telegraphs
  (`sovereign_boss.gd`, `tutorial_knight_boss_enemy.gd`, `late_game_hazard_trial.gd`).
- Save-version bump or a missing-key check so the legacy mapping runs (godot-specialist).
- Heal-cast HUD, refusal text and feedback, refill on death or respawn; check max MP lets Beginner's 5 casts be used.
- New-game selection screen and copy (none exists; the Options panel holds the selector today); per-profile description
  size and contrast; the legacy-save notice's text, placement, dismissal and "once" trigger; whether to offer a one-time
  free choice to a mapped Normal player.
- Profile shown in the HUD and save slots; a "lowered" marker; locked-item focus without hover.
- Integer F5 vs float damage at very small bases; safe ranges that allow ties with a second knob; time-model F6 in the
  checker; the old mapping's "what changes" column (DDA on → off, heal cap) for rows 2-3.
- Lower-only costs (one lowered boss forfeits a Hell clear; NG+ keeps the profile) stated in the Player Fantasy.
- Integration tests that set `Difficulty.NORMAL` (`boar_fight_test.gd`, `guardian_fight_test.gd`) need updating when
  the enum changes; the plan's Y1-P2-T26 evidence path says `difficulty.md`.
- Checker: no safe-range or order check, no check that every listed constant has a map row (declined at readiness).

From round 2 (not applied in revision 3):
- Formulas: "All values are integers" vs F1 seconds and F7's raw 98.08 (F7's round() settles it; integer division
  would differ at score 21 on "on": 75 vs 76).
- Old-setting mapping: the STORY and EASY rows omit player damage 150 → 100 and 125 → 100.
- Core Rule 7: the new-game default when `gameplay/difficulty_profile` is absent is unstated.
- Core Rule 7 / Dependencies: `assisted: true` is a second save field; only `difficulty` is listed.
- Core Rules 9-10: "assist" names both the DDA and the "(assisted)" record; say a gentle/on DDA run is not
  "(assisted)".
- Detailed Design (assist): `get_player_dda_bonus()` "adds up to 125 percent" should read "multiplies by up to 1.25".
- Formulas: no formula for attack cooldown under assist; untested in AC6/AC12.
- AC6: the boar telegraph values are at tempo 100; say so.
- Edge Case 8: NG+ carry-over is a protected-area decision; the restart-path NG+ bug would drop the profile; the ×1.5
  stacks on contact damage and HP only (`enemy_base.gd:180-183`).
- Core Rule 9: the disclosure copy mentions telegraphs only; assist also lengthens cooldowns.
- Core Rule 1: the Hell lock and clear recording need rank and lock as profile data, not id branches.
- Evidence README AC map said the constants map had 20 rows; it has 31 (fixed here).

## Known limits of the checker

- It does not parse Formulas, Edge Cases or the Acceptance Criteria text: their worked numbers (AC6-AC12 of the GDD)
  are review items and Year 1 Phase 2 tests.
- It checks the profile values' presence, type and the leniency/bridge rule, not their safe ranges or order (the
  balance check judged those) and not that they match the ROADMAP (the `source` column is a review item).
- `file:line` citations in the GDD prose are not resolved; only the constants map's are.
- The balance report is checked for existence and a Health line only.
