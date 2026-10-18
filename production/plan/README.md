# Aethelgard — the 10-year day-by-day plan

**3653 days, one entry per day:** Day 1 is 2026-10-19 and Day 3653 is 2036-10-18. There is one file per month: `production/plan/<year>/<year>-<month>.md`.

It turns `AethelgardPrototype/ROADMAP_10_YEAR.md` into daily work. The roadmap stays the source of truth for phases, gates, the content budget and the cut order. **If they disagree, the roadmap wins** and this plan is regenerated.

## How to use it

1. **Each morning,** open the month file and find `Day NNNN`.
2. **Start a Claude Code session** with the day's *session brief* line, found at the end of the day.
3. **Work the blocks in order:**
   - Start;
   - A (primary, 4 h);
   - B (secondary, 3 h);
   - team review (from Year 3);
   - C (quality, 1.5 h);
   - D (fun & feel, 1 h);
   - craft study (30 min);
   - hygiene (15 min);
   - end.

   That's about 10 focused hours.
4. **Nothing is written or committed without your OK** (project rules in `CLAUDE.md`). Each day suggests Conventional Commit messages that reference the task ID.
5. **If a day's task finishes early,** start the next day's entry for that stream. If it runs late, it carries forward. The quarterly re-plan absorbs the difference.
6. **Every month file opens with the same *Month-end results* checklist.** It lists every task that finishes that month and the evidence that proves it, plus any gate. It's the same contract whether the month's days were written by hand (Years 1–2) or from templates (Years 3–10). The month-end review ticks it.

## The week, and the energy rule

You chose **7 full working days a week.** The roadmap's risk register rates burnout from long weeks as high-likelihood and fatal, so every day starts with a 1–5 energy check.

**If it is ≤ 2 for three days running:** drop Blocks D and craft study, halve Block A, and raise it at the next month-end review. Protecting the project includes protecting the person making it.

**Day types:**
- **Sunday** is the weekly integration day. Block A is replaced by: build the `.exe`, run every suite, play a route end to end, triage, and fix the top bugs. The secondary stream continues.
- **Month-end, quarterly re-plan and gate days** add a ritual block. It replaces Fun & feel and Craft study that day; the work streams keep moving.

## Detail and honesty

- **Every day has its own specific tasks,** steps, done-criteria and edge cases.
- **The firmness of that detail differs:**
  - **Year 1** is grounded in the repo's real current state;
  - **Year 2** is from the roadmap;
  - **Years 3–10** come from the content budget, using IDs (for example `R4-SQ-03`, `R6-B02`) rather than invented story.
- **The far future will change.** Real speed, playtests and gates will move it, so the plan is regenerated from `_source/` at every **quarterly re-plan** and every **gate**. Days already lived are never rewritten.

## Phases and gates

| Phase | Window | Theme | Goal |
|---|---|---|---|
| Y1-P0 | 2026-10-19 → 2026-11-30 | Stabilize | A human and the bot can play New Game to the credits with no softlock, the repo is clean and off OneDrive, every open audit decision is closed, and the storyline, time and difficulty designs are drafted. |
| Y1-P1 | 2026-12-01 → 2027-01-31 | Spine | Scene changes, saves, flags, rewards, stats and the world clock each have one owner with unit tests under gdUnit4, and the dialogue pipeline is ready for portraits, line IDs and translation. |
| Y1-P2 | 2027-02-01 → 2027-03-31 | Combat foundation | Kaelen and every Chapter 1 fight run on a fixed-tick, data-driven combat stack (states, MoveData, hitboxes, encounters, bosses with poise, 5 difficulty profiles, FeelService, generated arenas) proven by input-replay tests, and the old player_combat.gd and duplicate feel systems are gone. |
| Y1-P3 | 2027-04-01 → 2027-06-30 | Art pipeline + Pillar Slice | Oakhaven runs as an editor-authored, streamed PAE world with living NPCs, items, crafting, market, auction, a limited edition, a gambling game, a minigame, two timed quests, composed endings and Story+, and Gate 1 has been judged on real tester data and a measured cost per asset. |
| Y1-P4 | 2027-07-01 → 2027-09-30 | Open-world tech + tools | Oakhaven and Ironhold form one seamlessly streamed world with simulation LOD, authored content flows through six editor tools, cinematics run on skippable timelines with a defined camera language, and telemetry, crash reporting, localization and an accessibility baseline are in place for the public demo year. |
| Y2-Q1 | 2027-10-01 → 2027-12-31 | Public demo | A free Act 1 demo (prologue, Oakhaven, Ironhold, market and auction, 2 minigames, both Act 1 deadlines) is public on itch.io, the Steam page is public with a trailer, the Steam demo app is ready for Next Fest build review, and a structured playtest program is producing Gate 2 data. |
| Y2-Q2 | 2028-01-01 → 2028-03-31 | Market signal | The demo has been iterated twice from telemetry and playtest data, has run in Steam Next Fest, the legal groundwork (license audit, AI disclosure, title trademark search, gambling rating impact) is documented, and Gate 2 has been decided on 2028-03-31 with an ADR. |
| Y2-PP | 2028-04-01 → 2028-09-30 | Pre-production | The world bible, route architecture (bot-verified for all 27 storylines and every timing branch), economy design (365-day sim within inflation bounds), combat and itemization bibles are locked; legacy systems and stale files are gone; every content pipeline has shipped one final-quality asset; the team and funding plan is decided; and Gate 3 is decided on 2028-09-30. |
| Y3 | 2028-10-01 → 2029-09-30 | Production I: Act 1 (R1-R2) | Act 1 (R1-R2) is shippable on all 5 difficulties with real art and audio, NPC sim v2, the full moveset and training-based stats (M3). |
| Y4 | 2029-10-01 → 2030-09-30 | Production II: Act 2 (R3-R5) + Early Access | Act 2 (R3-R5) is built to the Definition of Done, Early Access has launched (~2030-03-15) with a steady patch cadence, and Gate 4 health criteria are measured. |
| Y5 | 2030-10-01 → 2031-09-30 | Production III: Act 3 branches (R6-R7) | Act 3's three branches across R6-R7 are playable end to end with NPC sim v3, route-specific market events, the 4th auction house and all minigames and gambling games (M5). |
| Y6 | 2031-10-01 → 2032-09-30 | Production IV: R8, Act 4, endings, Story+ | R8 and Act 4 are complete, SOVEREIGN and the God King ship with Hell phases, all 27 endings play through the ending composer, every storyline has Story+, and Gate 6 Alpha passes. |
| Y7 | 2032-10-01 → 2033-09-30 | Beta | Every boss, storyline, timing path, region and screen is validated on every difficulty and both languages, and the build passes Gate 7 as a release candidate. |
| Y8 | 2033-10-01 → 2034-09-30 | 1.0 launch, live support, console ports | Aethelgard 1.0 is live on PC (~2034-02-15) with a working war room, hotfix lane and patch cadence; every save since EA loads in CI; console platforms A and B are port-complete with the chosen partner and C is under way; the launch + 6-month review is done. |
| Y9 | 2034-10-01 → 2035-09-30 | Console launches + Expansion 1 | Aethelgard is live on console platforms A, B and C; Expansion 1 adds cut kingdom A and cut kingdom B with 3 new storylines, new goods and events on every platform; optional Hell leaderboards and a real speedrun timer ship if the ADR says go. |
| Y10 | 2035-10-01 → 2036-10-18 | Expansion 2, NG+ cycles, retrospective | Expansion 2, Story+ extensions for all four ending families and NG+ cycles with remixed bosses and markets ship on every platform; the 10-year retrospective is written and the sequel / new IP / continued-support decision is recorded with a handover-ready codebase. |

| Date | Gate / milestone |
|---|---|
| 2027-06-30 | Gate 1 - Pillar Slice |
| 2028-03-31 | Gate 2 - Market signal |
| 2028-09-30 | Gate 3 - Production greenlight |
| 2029-09-30 | M3 - Act 1 shippable on all 5 difficulties |
| 2030-03-15 | Early Access launch (Acts 1-2) |
| 2030-09-30 | Gate 4 - Early Access health |
| 2031-09-30 | M5 - every Act 3 branch playable end to end |
| 2032-09-30 | Gate 6 - Alpha (content complete) |
| 2033-09-30 | Gate 7 - Release candidate |
| 2034-02-15 | 1.0 launch (PC) |
| 2034-08-15 | Launch + 6-month review |
| 2036-10-18 | 10-year retrospective |

## Decisions and risks this plan raises

Building the plan exposed these. Each one has a decision or check day in the plan, but they are listed here so they aren't buried.

**Decided on 2026-10-18:**
1. **Region map (resolved).** It follows `story/STORY_BIBLE.md` §3:
   - Act 1: R1 Oakhaven Reach, R2 Ironhold Crown.
   - Act 2: R3 Fractured Wastes, R4 Forgotten Sectors (the Null Court), R5 Mirror City.
   - Act 3: R6 Cathedral Server, R7 Memory Ocean / Saved Assembly.
   - Act 4: R8 Rootward Expanse (Human Patch Lab, Root of Heaven).

   Expansion 1's two kingdoms are *cut kingdom A / B*, chosen from the blueprint's cut kingdoms at the Y8 expansion planning day.
2. **Side quests (resolved and increased).** They go from 128 scheduled (ROADMAP §7's yearly figures summed to 120) to the full **150** budget in §3:
   - Y3: 40 (R1 19, R2 21).
   - Y4: 50 (R3 17, R4 17, R5 16).
   - Y5: 45 (R6 22, R7 23).
   - Y6: 15 (R8).

   Every one is a real scheduled quest with design, writing, implementation and QA days. The extra work replaced filler days, not calendar time.
5. **Early Access scope (resolved).** EA launches ~2030-03-15 with Act 1 + R3. R4 (`EA-U1`) and R5 (`EA-U2`) follow as EA content updates before Gate 4 (2030-09-30), so all of Acts 1–2 are in players' hands for the health review. ROADMAP_10_YEAR.md says the same.
6. **Y4 art load (accepted).** Y4 is the tightest year (three regions plus EA), with art as the bottleneck. Accepted as planned on 2026-10-18.

**Still open:**
3. **Secret endings:** the bible defers First Wake and Crownless to after 1.0, while §7 asks for all 27 endings in Y6. A decision step is planned.
4. **Kaito:** the Chapter 3 source uses him, but the bible keeps him on the backlog. A decision is planned in Y1-P1.

7. **Art pace:** 40 Kaelen clips in 18 days (Y1-P3) is aggressive. Cost per asset is logged from Y1-P2, so Gate 1 shows the real rate. The Ch1 guardian fight has no sprite budgeted through Y1-P4.
8. **Hell leaderboards** conflict with the offline-only assumption (A5), so they are planned as an optional ADR using platform leaderboards only.

**Things to check before relying on them:**
9. Steam Next Fest 2028 dates (not announced when this was written).
10. Steam AI-content rules, rating-board rules for simulated gambling, console certification rules. The steps say "check current rules"; nothing is assumed.

**Limits of the plan itself:**
11. **Streams are scheduled independently.** Tasks that depend on another stream's output were ordered to line up, but the scheduler can't enforce it. Check at each re-plan.
12. **Detail varies:**
    - Years 1–2 were written task by task.
    - Years 3–10 were expanded from per-unit templates, so those days are shorter. In the late years, 13–35% of the team streams are live-fix and polish blocks.
    - IDs used in Y7–Y10 (bosses, storylines, quests) must be matched to the Y3–Y6 registries at the first re-plan.
13. **Protected areas:** many tasks touch areas `AGENTS.md` protects (combat, collision, save schema, story progression). Each has an explicit approval step; a slow decision slips the schedule.
14. **Capacity trims:** to fit the calendar exactly, a few phases had two days of one task merged into one fuller day, and four late live-fix blocks lost a day. `_source/fix_capacity.py` lists each one.

## Capacity report

**Columns:**
- **Stream-days available:** how many days the stream works in that phase.
- **Planned:** the work authored for the phase.
- **Buffer:** spare days, filled with polish, bug bashes and tech debt.
- **Carry-out:** work that didn't fit and moves to the next phase. A carry-out is a scheduling risk to resolve at the next re-plan.

| Phase | Stream | Stream-days | Planned | Buffer | Carry-out |
|---|---|---|---|---|---|
| Y1-P0 | primary | 37 | 37 | 0 | 0 |
| Y1-P0 | secondary | 43 | 43 | 0 | 0 |
| Y1-P1 | primary | 53 | 53 | 0 | 0 |
| Y1-P1 | secondary | 62 | 62 | 0 | 0 |
| Y1-P2 | primary | 51 | 51 | 0 | 0 |
| Y1-P2 | secondary | 59 | 59 | 0 | 0 |
| Y1-P3 | primary | 78 | 78 | 0 | 0 |
| Y1-P3 | secondary | 91 | 91 | 0 | 0 |
| Y1-P4 | primary | 79 | 79 | 0 | 0 |
| Y1-P4 | secondary | 92 | 92 | 0 | 0 |
| Y2-Q1 | primary | 79 | 78 | 1 | 0 |
| Y2-Q1 | secondary | 92 | 92 | 0 | 0 |
| Y2-Q2 | primary | 78 | 78 | 0 | 0 |
| Y2-Q2 | secondary | 91 | 91 | 0 | 0 |
| Y2-PP | primary | 157 | 157 | 0 | 0 |
| Y2-PP | secondary | 183 | 183 | 0 | 0 |
| Y3 | primary | 312 | 312 | 0 | 0 |
| Y3 | secondary | 365 | 365 | 0 | 0 |
| Y3 | art | 260 | 260 | 0 | 0 |
| Y3 | audio | 260 | 260 | 0 | 0 |
| Y3 | writing | 260 | 260 | 0 | 0 |
| Y3 | qa | 260 | 260 | 0 | 0 |
| Y4 | primary | 313 | 313 | 0 | 0 |
| Y4 | secondary | 365 | 365 | 0 | 0 |
| Y4 | art | 261 | 261 | 0 | 0 |
| Y4 | audio | 261 | 261 | 0 | 0 |
| Y4 | writing | 261 | 261 | 0 | 0 |
| Y4 | qa | 261 | 261 | 0 | 0 |
| Y5 | primary | 313 | 313 | 0 | 0 |
| Y5 | secondary | 365 | 365 | 0 | 0 |
| Y5 | art | 261 | 261 | 0 | 0 |
| Y5 | audio | 261 | 261 | 0 | 0 |
| Y5 | writing | 261 | 261 | 0 | 0 |
| Y5 | qa | 261 | 261 | 0 | 0 |
| Y6 | primary | 314 | 314 | 0 | 0 |
| Y6 | secondary | 366 | 366 | 0 | 0 |
| Y6 | art | 262 | 262 | 0 | 0 |
| Y6 | audio | 262 | 262 | 0 | 0 |
| Y6 | writing | 262 | 262 | 0 | 0 |
| Y6 | qa | 262 | 262 | 0 | 0 |
| Y7 | primary | 313 | 313 | 0 | 0 |
| Y7 | secondary | 365 | 365 | 0 | 0 |
| Y7 | art | 261 | 261 | 0 | 0 |
| Y7 | audio | 261 | 261 | 0 | 0 |
| Y7 | writing | 261 | 261 | 0 | 0 |
| Y7 | qa | 261 | 261 | 0 | 0 |
| Y8 | primary | 313 | 313 | 0 | 0 |
| Y8 | secondary | 365 | 365 | 0 | 0 |
| Y8 | art | 260 | 260 | 0 | 0 |
| Y8 | audio | 260 | 260 | 0 | 0 |
| Y8 | writing | 260 | 260 | 0 | 0 |
| Y8 | qa | 260 | 260 | 0 | 0 |
| Y9 | primary | 312 | 312 | 0 | 0 |
| Y9 | secondary | 365 | 365 | 0 | 0 |
| Y9 | art | 260 | 260 | 0 | 0 |
| Y9 | audio | 260 | 260 | 0 | 0 |
| Y9 | writing | 260 | 260 | 0 | 0 |
| Y9 | qa | 260 | 260 | 0 | 0 |
| Y10 | primary | 330 | 330 | 0 | 0 |
| Y10 | secondary | 384 | 384 | 0 | 0 |
| Y10 | art | 275 | 274 | 1 | 0 |
| Y10 | audio | 275 | 274 | 1 | 0 |
| Y10 | writing | 275 | 274 | 1 | 0 |
| Y10 | qa | 275 | 274 | 1 | 0 |

## Regenerating

`_source/` holds:
- the work breakdown, one JSON per phase;
- `catalogs.json`;
- `generate_plan.py`.

To re-plan:
1. Edit the JSON for the phases ahead.
2. Run `python production/plan/_source/fix_capacity.py production/plan/_source` to fit each phase to its calendar.
3. Run `python production/plan/_source/generate_plan.py production/plan/_source production/plan`.
4. Review the diff of future months only.
5. Commit with your OK.

`_source/authoring/` keeps the scripts that expanded the templates (Years 1–10 and the catalogs), for reference. They were run from a scratch layout, so point their output paths at `_source/` before running them again.

*Generated files: 121 month files plus this README.*
