# Sprint 001 — 2026-10-19 to 2026-11-30 (Y1-P0 Stabilize)

> **Backlog source:** `production/plan/_source/Y1-P0.json` (tasks Y1-P0-T01…T15, S01…S16),
> scheduled day by day in `production/plan/2026/2026-10.md` and `2026-11.md` (Days 0001–0043).
> **Deviation from `/sprint-plan`:** no story files exist under `production/epics/`; by user
> decision (2026-10-18) the sprint plans the Y1-P0 tasks directly. A task gets a story file
> when `/dev-story` first needs one.
> **Milestone:** none defined (`production/milestones/` absent) — planning against the Y1-P0
> goal and exit criteria. **Risk register:** none — risks assessed from the sprint contents only.
> **PR-SPRINT (producer, 2026-10-18): CONCERNS** — user chose **[B] Adjust scope**: T14 and T13 split,
> T14a moved before T13, a named softlock-fix reserve, a human Ch4–10 pass on Day 0035, T15/S16
> dependency fixed, exported build added to T15. Capacity confirmed by the user as real (no coursework cut).
> **QA Plan:** `production/qa/qa-plan-sprint-001-2026-10-18.md` (written 2026-10-18, before implementation).

## Sprint Goal
A human and the bot can play New Game to the credits with no softlock, the repo is clean and
off OneDrive, every open audit decision is closed, and the storyline, time and difficulty
designs are drafted (Y1-P0 goal).

## Capacity
Two work streams per day: Block A (primary, 4 h) Mon–Sat; Block B (secondary, 3 h) every day.
Sundays: Block A is the weekly integration playthrough, not task work.

- Total: 43 days (Mon 19 Oct – Mon 30 Nov 2026) = **80 block-days** (37 Block A + 43 Block B)
- Buffer (20%): **16 block-days** of uncommitted capacity:
  - **5 days: softlock-fix reserve** — late Block B slots (formerly S13/S14), only for fixing
    softlocks the bot or the human pass finds; separate from the gate-check day
  - **11 days: Nice to Have candidates**, taken in listed order only when no slip is pending
- A slipped primary day uses the next free Block B slot (a 3 h slot ≈ 75% of a 4 h day); the plan records the move.
- Committed (Must + Should): **64 block-days**
- Daily load: ~10.5 h scheduled (A 4, B 3, C 1.5, D 1, study 0.5, start/end/hygiene 0.75),
  7 days a week. The buffer does not reduce this — see Risks.
- Energy rule (ROADMAP §1.1): rating 1–5 as the first line of `active.md` each morning; if the
  last 3 are all ≤ 2, that day runs primary + hygiene only and stops by mid-afternoon.

## Tasks

### Must Have (Critical Path)
| ID | Task | Agent/Owner | Est. Days | Dependencies | Acceptance Criteria |
|----|------|-------------|-----------|-------------|-------------------|
| Y1-P0-T01 | Clean the junk out of the repo root | you + Claude (devops-engineer) | 1 | — | **Done 2026-10-18**, commit `1484435`; evidence `production/qa/evidence/2026-10-repo-hygiene/root-cleanup.md` |
| Y1-P0-S01 | Plan the Phase 0 sprint | you + Claude (producer) | 1 | — | This file, `production/sprint-status.yaml`, `production/session-state/active.md` |
| Y1-P0-T02 | Move the tests into tests/unit and tests/integration | you + Claude (devops-engineer, qa-lead) | 3 | — | 9/9 suites pass locally (log `production/qa/evidence/2026-10-test-layout/run_all.log`); CI green; layout guard committed |
| Y1-P0-S02 | Write the replacement Ch1 text: shatter scene, breadcrumbs, item and quest strings | you + Claude (writer) | 4 (was 2; +2 by decision 3, from the buffer) | T03 (null_potion text and reward strings only) | `dialogue/ch1/shatter.dlg`; dialogue_test lint passes; **user-approved** string list |
| Y1-P0-S03 | Evidence folder, session checkpoint, Conventional Commits hook | you + Claude (devops-engineer) | 2 | — | `.githooks/commit-msg` rejects `stuff`, accepts `chore: add commit-msg hook`; `production/qa/evidence/README.md`; CI check green |
| Y1-P0-T03 | Decision memo for the 7 open audit decisions (the day plan's title says "3–5"; the record covers all 7) | **you decide** + Claude (producer) | 1 | — | Decision record with 7 dated decisions (or explicit "defer to phase X") |
| Y1-P0-S04 | Repo hygiene calls: OneDrive, LFS, sprite archive, context.txt | **you decide** + Claude (devops-engineer) | 3 | T02 (clean, green suite to compare) | Decision record; `git lfs track` output; fresh clone passes load_all. Move done at the **start of a day on a clean, committed tree**; updating the OneDrive path in `AGENTS.md` and checking Claude Code starts in the new folder are listed steps (user approval) |
| Y1-P0-T04 | Rewire the Ch1 shatter scene to the rewritten story | you + Claude (gameplay-programmer) | 2 | T03, S02, T02 | chapter1_route_test covers kill/spare/purge and passes; `production/qa/evidence/2026-10-shatter/{kill,spare,purge}.png` |
| Y1-P0-S05 | Turn every review finding into a GitHub Issue | **you approve publishing** + Claude (producer) | 3 | S03 | Findings CSV with issue numbers; Phase 0 milestone triaged; `.github/ISSUE_TEMPLATE` |
| Y1-P0-T05 | Fix the stale Ch1 breadcrumb objectives | you + Claude (gameplay-programmer) | 1 | T03, S02 | chapter1_route_test passes with 10 new breadcrumb assertions |
| Y1-P0-T06 | Make the side quests completable and their rewards real | you + Claude (gameplay-programmer) | 3 | T03, S02, T02 | `tests/unit/quests/side_quest_rewards_test.gd` + `tests/integration/quests/act1_quests_completable_test.gd` pass; no unknown reward ids |
| Y1-P0-S06 | Draft storyline axes, time model, difficulty values | you + Claude (game-designer, systems-designer) | 4 | — | `design/gdd/{storyline-axes,time-model,difficulty-profiles}.md` drafted with `/design-review` results |
| Y1-P0-T07 | Stop NG+ from stacking choice buffs every cycle | you + Claude (gameplay-programmer) | 1 | T03, T02 | `tests/unit/ngplus/ngplus_buff_stacking_test.gd`: 3 simulated cycles, identical buff totals |
| Y1-P0-T08 | Fix screen flashes, fragment_4 achievement, null_potion text | you + Claude (technical-artist, ui-programmer) | 2 | T03, S02 | `production/qa/evidence/2026-11-flash/archive_flash.png`; achievement + `null_potion_consistency_test` pass |
| Y1-P0-T09 | Remove the unused InteractionPrompt and ObjectPool autoloads | you + Claude (godot-gdscript-specialist) | 1 | T02 | project.godot 32 → 30 autoloads; all suites pass |
| Y1-P0-T10 | Fix log spam, growing `_bound_texts`, leaked texture RID | you + Claude (engine-programmer) | 2 | T02 | `tests/unit/input/input_bound_texts_prune_test.gd`; clean exit log `production/qa/evidence/2026-11-exit-leak/exit.log` |
| Y1-P0-T11 | Close the combat-feel leftovers | you + Claude (gameplay-programmer) | 4 | T02 | combat_fixes suite +4 checks passes; `production/qa/evidence/2026-11-combat/combo_label.png`; play note |
| Y1-P0-S08 | Build Elara's house and the shrine as real rooms | you + Claude (level-designer, gameplay-programmer) | 4 | T04 | `production/qa/evidence/2026-11-rooms/{elara_house,shrine}.png`; route tests green |
| Y1-P0-T12 | Fix the UI and region leftovers | you + Claude (ui-programmer) | 4 | T02 | `production/qa/evidence/2026-11-ui/{menu_version,pause_version,stats_card,clock_tower}.png`; reachability log |
| Y1-P0-T14a | Playthrough bot: Chapter 3 exit → credits (Ch4–10 legs) | you + Claude (qa-tester) | 3 | T06, T12 | `full_playthrough_test.gd` drives Ch4–10 headless; softlocks found are logged by ~Day 0033. **Runs before T13** |
| Y1-P0-T13a | Slime as a real side-scroll fight | you + Claude (gameplay-programmer, ai-programmer) | 2 | T11, T04 | Route test covers fight + non-fight branch; `production/qa/evidence/2026-11-ch1-fights/slime.png` |
| Y1-P0-T13b | Guardian as a real side-scroll fight | you + Claude (gameplay-programmer, ai-programmer) | 2 | T13a | As T13a; `…/guardian.png` |
| Y1-P0-T13c | Boar as a real side-scroll fight | you + Claude (gameplay-programmer, ai-programmer) | 2 | T13a | As T13a; `…/boar.png` |
| Y1-P0-T14b | Playthrough bot: Ch1 fight legs + CI step | you + Claude (qa-tester, devops-engineer) | 1 | T13a–c, T14a | `tests/integration/playthrough/full_playthrough_test.gd` passes New Game → credits headless in CI |
| Y1-P0-T15 | Phase 0 exit: a human plays New Game to the credits | **you play** + Claude (qa-lead) | 3 | T14b, S08, every other Must Have except S16 | Playthrough on an **exported Windows build** (`tools/export_windows.ps1`); `production/qa/playtest-2026-11-phase0.md` with 0 open softlocks; smoke-check + gate-check reports |
| Y1-P0-S16 | Review Phase 0 and plan the spine | you + Claude (producer) | 1 | T15 | `production/milestones/y1-p0-review.md`; retro; P1 goal drafted |

Must Have total: 58 block-days (T01 + S01 done/in progress today). T14 grew 3 → 4 days (T14a 3 + T14b 1),
per the producer's finding that Ch4–10 cannot be scripted in the original blocks.

### Should Have
| ID | Task | Agent/Owner | Est. Days | Dependencies | Acceptance Criteria |
|----|------|-------------|-----------|-------------|-------------------|
| Y1-P0-S07 | Playtest Act 1 for fun and fix the worst pacing problems | **you play** + Claude (game-designer) | 4 | T04, T05, T06 | `production/qa/playtest-2026-10-act1-fun.md`; before/after timings; route tests green |
| Y1-P0-S11 | Catalogue every Act 1 cutscene and what a timeline system must do | you + Claude (technical-director) | 2 | — | `design/cinematics/act1_cutscene_catalogue.md` with counts per need |

Should Have total: 6 block-days.

### Nice to Have (candidates for the 11 free buffer days, in this order — start only if no slip is pending)
| ID | Task | Agent/Owner | Est. Days | Dependencies | Acceptance Criteria |
|----|------|-------------|-----------|-------------|-------------------|
| Y1-P0-S09 | Write side arc 04, Iron Owes (quests 19–24) | you + Claude (writer, narrative-director) | 5 | S06 | `story/outlines/side_arc_04_iron_owes.md`; `dialogue/side/iron_owes.dlg` passes dialogue_test; user-approved |
| Y1-P0-S10 | Start the Ch3 rewrite into .dlg in the same voice | you + Claude (writer) | 4 | S02 | `story/outlines/ch3_fractured_wastes.md`; first six scenes user-reviewed |
| Y1-P0-S12 | Lay the groundwork for the art bible | you + Claude (art-director) | 2 | — | `design/art/art-bible.md` draft sections |
| Y1-P0-S15 | Inventory the audio Act 1 uses today | you + Claude (audio-director) | 1 | — | `design/audio/act1_audio_inventory.md` with source/licence column |

Candidates total 12 block-days for 11 free days, so at least one will not fit. Unstarted items move to
Phase 1 by name at S16.

**Deferred to Phase 1 (out of this sprint):** Y1-P0-S13 First PAE test sprites: Kaelen (3 d);
Y1-P0-S14 Animation clip list (2 d) — their slots became the softlock-fix reserve.

## Schedule changes against the day-by-day plan
The daily files `production/plan/2026/2026-10.md` and `2026-11.md` predate this sprint. Where they
disagree, this sprint plan wins until the plan is re-generated:
- **Day 0007 (Sun 25 Oct):** add a 15-minute velocity check: actual time vs estimate for T01, T02, S02, S03; re-plan if T02 or S02 overran.
- **T14a** runs straight after T12, **before** T13; **T13a–c** follow; **T14b** after T13c.
- **Day 0035 (Sun 22 Nov):** the weekly integration becomes a **human pass through Chapters 4–10** (any difficulty).
- **Former S13/S14 slots (late-November Block B):** softlock-fix reserve.
- **Day 0043:** gate-check and S16 only; softlock fixes belong in the reserve, not here.
- **S02 waits on T03 (found 2026-10-18):** the shatter text (done, `35b67e0`) and the 10 breadcrumb lines
  (approved) are written; the null_potion description and quest reward strings depend on T03's decisions
  (null_potion effect, reward mapping), so S02 closes on or after Day 0005, not Day 0003.
- **T03 decided 2026-10-18** (`production/decisions/2026-10-audit-decisions.md`): all seven items took the
  recommended option. Decision 3 (rewrite the whole shatter scene) adds ~2 d to S02, taken from the buffer:
  the 11 free buffer days become 9 (the 5-day softlock-fix reserve is untouched).

## User-decision days (must not be skipped)
| Day | Date | Task | Decision |
|-----|------|------|----------|
| 0002–0003 | Tue 20 – Wed 21 Oct | S02 | Approve the Ch1 replacement string list |
| 0005 | Fri 23 Oct | T03 | The 7 audit decisions: shatter text, breadcrumbs, quests, NG+, flashes, fragment_4, null_potion |
| 0006–0008 | Sat 24 – Mon 26 Oct | S04 | OneDrive move, Git LFS, sprite archive, context.txt |
| 0009–0011 | Tue 27 – Thu 29 Oct | S05 | OK to publish issues to GitHub (outward-facing) |
| before T13a starts | ~mid Nov | T13 | Which fight gives way first (slime / guardian / boar) if the tail slips |
| 0035 | Sun 22 Nov | — | Human pass through Chapters 4–10 |
| 0040, 0041, 0043 | 27, 28, 30 Nov | T15 | Human playthrough to the credits on an exported build |

If a decision is not taken on its day, the dependent tasks (T04–T08 for T03) move and the plan
records the move; work does not proceed on an assumed answer.

## Carryover from Previous Sprint
| Task | Reason | New Estimate |
|------|--------|-------------|
| — | First sprint | — |

## Risks
| Risk | Probability | Impact | Mitigation |
|------|------------|--------|------------|
| ~10.5 h/day, 7 days/week for 43 days → fatigue, slips, burnout (ROADMAP §1.1) | High | High | Daily energy rule; 16-day buffer; Sunday Block A is play, not task work; cut Block C/D/study before Block A |
| Primary stream has no slack inside Block A (38 task-days on 37 slots after the T14 re-estimate) | High | High | Primary slips take the next free Block B slot; Nice to Have never starts while a slip is pending; Day 0007 velocity check |
| Risky work clusters in the last 14 days (T13 → T14b → T15); Ch4–10 softlocks found late | Medium | High | T14a moved before T13; human Ch4–10 pass Day 0035; 5-day softlock-fix reserve; give-way order agreed before T13a |
| Estimates uncalibrated (first sprint, no history) | High | Medium | Day 0007 velocity check; re-plan at each Sunday review |
| An audit decision (T03) or hygiene call (S04) not taken on its day blocks T04–T08 / later work | Medium | High | Decision days listed above; dependent task moves, plan records it |
| S04 OneDrive move / LFS mid-sprint breaks paths, `.uid` refs or the clone | Medium | High | Do it on a clean tree with all suites green; fresh-clone load_all as acceptance; rollback = keep the OneDrive copy until the clone passes |
| T02 test move breaks `res://` paths, `.uid` links or CI steps (Day 0001 edge case) | Medium | Medium | Move with `.uid` files; run full suite + CI before and after; layout guard test |
| T06, T07, T11, T13 touch protected areas in AGENTS.md (combat, save/load schema, story progression, NG+) | High | Medium | Each prompt explicitly names the protected area it may change; route + regression tests per task |
| T13 (6 d) is the largest and least-known estimate (new side-scroll fights) | Medium | High | Split into T13a–c (one per enemy); T13a proves the pattern before b/c; give-way order agreed in advance |
| Test runner is custom scripts, not gdUnit4 (CI command in coding standards assumes gdUnit4) | Medium | Low | T02 decides the runner; until then `run_all_tests.ps1` is the gate |

## Dependencies on External Factors
- Godot 4.6.3 console editor at `C:\Godot` (headless tests)
- GitHub: Actions CI for T02/S03/T14; Issues + milestone for S05 (needs explicit user OK to publish)
- Git LFS installed for S04
- OneDrive sync until S04 moves the repo off it
- PAE (pixel-art engine) for S13 — Nice to Have only

## Definition of Done for this Sprint
- [ ] All Must Have tasks completed
- [ ] All tasks pass acceptance criteria
- [ ] QA plan exists (`production/qa/qa-plan-[sprint-slug]-[date].md`, from `/qa-plan sprint`)
- [ ] All Logic/Integration tasks have passing unit/integration tests
- [ ] Visual/UI tasks have retained screenshots in `production/qa/evidence/`
- [ ] Smoke check passed (`/smoke-check sprint`)
- [ ] QA sign-off report: APPROVED or APPROVED WITH CONDITIONS (`/team-qa sprint`)
- [ ] No S1 or S2 bugs in delivered features
- [ ] Design documents updated for any deviations
- [ ] Code reviewed and merged
