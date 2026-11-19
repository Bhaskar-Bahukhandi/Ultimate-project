# Time Model

> **Status**: Draft (revision 3, 2026-11-19: round 2's one blocker fixed: the after-dark and tower-bell claims
> narrowed to scenes reached before their target, Edge Case 16 added; no third review round, by user decision.
> Revision 2, after round 1: main-story deadlines close at a fixed time of day and leniency sets the minimum window;
> `advance_until` replaces anchors; same-minute order, stop precedence, pace rows and errata fixed. User decisions
> D1-D3 of 2026-11-19 recorded where they apply)
> **Author**: Claude with the project lead
> **Last Updated**: 2026-11-19
> **Last Verified**: 2026-11-19
> **Implements Pillar**: P7f (time-sensitive world) — ROADMAP §12.4; feeds P3 and P5 through timing flags and pace

## Summary

The time model defines WorldClock: a deterministic, saved, pausable in-game clock (one day = about 24 real minutes, a
28-day month, 4 seasons), the four quest timing types (Window, Deadline, Order, Duration) as data fields, how the two
live deadlines (the Chapter 1 bridge and the Chapter 2 medicine convoy) become clock times, and the pace value
(early / on-time / late) each act feeds to the ending composer. Timing changes scenes, NPC fates and ending slides. It
never changes the storyline ID, and a main-story deadline never fails without a signposted warning.

> **Quick reference** — Layer: `Foundation` · Priority: `MVP (WorldClock v1, Y1-P1)` · Key deps: `ContextStack`,
> `storyline-axes` (reads pace and timing flags), difficulty profiles (S06c: the leniency values)

## Overview

The build has no clock today. The Chapter 1 bridge deadline ("until dark") is settled instantly: accepting the repair
runs a `time_passes` event and sets `ch1_bridge_saved` on the spot. The Chapter 2 medicine deadline ("the evening
bell") is the Clock Tower stopping when the player climbs it. This GDD gives both one shared clock and one
vocabulary, so a quest can say "before dark", "on days 3-5", "A before B" or "the faster you finish, the better" as
data. The player sees every deadline in the quest log with an in-world reason, chooses how to spend the time, and the
world answers: who is present, what is for sale, which ending slide plays. The clock is a function of saved fields
and input, never of real time, so a bot can replay fast, slow and out-of-order runs. It stops under the rules
ContextStack already owns.

## Player Fantasy

The player feels a world that keeps its own time and answers to how they spend it, without ever feeling punished for
exploring. Capability is not legitimacy; likewise a clock is not a trap.

- **Time is something you spend, not a hidden timer.** Every deadline is announced in the world with a reason
  ("Reason: rain is expected overnight", PM:1723; "Until the evening bell. After that the gates close",
  `ironhold_city.dlg:104`) and is in the quest log before it closes (PM:11963; ROADMAP:524). A main-story deadline
  never fails without a signposted warning (ROADMAP:526; Story Bible, Timing), and the player gets a chance to turn
  back first (the Clock Tower gate, `ironhold_city.dlg:237-241`).
- **Every pace is a story; none is a failure.** "No pace is automatically bad. Some NPCs survive because player was
  early. Other opportunities appear only if player spent time." (PM:2872-2874). Early is acknowledged, with its cost
  named (PM:11960). On time plays the intended scene. Late shows concrete consequences "without declaring the
  playthrough failed" (PM:11962).
- **Lower difficulty loosens the clock, never changes its meaning.** Leniency scales; the narrative cause stays the
  same (PM:11964; ROADMAP:525).
- **The clock keeps its word.** The clock is deterministic and saved (PM:11965), so a reload lands on the saved
  minute and the same saved game played the same way reaches the same hour; Story+ shows what your timing changed
  (ROADMAP:527).

What it must not feel like: a countdown the game never mentioned, a penalty for taking a side road, or a main story
that quietly closes.

## Detailed Design

### Core Rules (clock)

1. **Units.** 1 hour = 60 minutes, 1 day = 1440 minutes, 1 month = 28 days, 1 season = 1 month, 1 year = 4 seasons
   = 112 days (SPRING, SUMMER, AUTUMN, WINTER; display names are localisation). One in-game day lasts
   `real_minutes_per_day` real minutes (default 24, ROADMAP:512), so at the default 1 real second = 1 game minute.
   *Season length is a user decision, 2026-11-19: one season is one month.*
2. **Integer time.** The clock keeps `total_minutes` (int) and a tick remainder `tick_acc` (int). It never reads
   wall-clock time. Each running physics tick adds 1440 to `tick_acc`; when `tick_acc` reaches `ticks_per_day` it rolls
   over into one more minute (F1, F2). `tick_rate` is the project's 60 physics ticks per second (`project.godot`
   holds no override; WorldClock v1 reads `Engine.physics_ticks_per_second` rather than assuming it).
3. **Starts with `start_at`.** The clock is NOT_STARTED until `start_at(day, minute_of_day)`. Chapter 1 starts it at
   the bridge warning (C1-S07, PM:1718-1723) with `start_at(1, dusk_min − scale(base_deadline_min))` (F4): 13:00 at
   L 100 %, 10:30 at 150 %, 13:45 at 85 %. `start_at` runs before `quest_start bridge_before_dark` records the
   quest's `start_min`. No deadline exists, and none shows in the quest log, before the clock starts.
4. **Authored time (`advance_until`).** A story scene may move the clock forward to an absolute minute:
   `advance_until(target_min, reason)` jumps to `target_min` if it is ahead and does nothing otherwise. It never moves
   backward and has no cap. It resolves every boundary it crosses (Rule 5); if it would cross an open main-story
   deadline that the scene does not own, it asks first (Signposting rule 4). It keeps scenes that state a time true
   when they are reached before their target (the shrine's after-dark chain and the Clock Tower bell, part C); a scene
   reached later follows Edge Case 16.
5. **Authored jumps.** Dialogue and cutscenes run no clock time of their own. Elapsed time inside them is authored:
   the dialogue event `time_passes <minutes>` calls `advance_minutes(minutes, reason)` (n ≥ 0). Today `time_passes`
   is a fade with no duration, handled per scene (`ch1_oakhaven_village.gd:177-180`); a bare `time_passes` with no
   minutes stays a fade and advances nothing (e.g. `north_field.dlg:158`). Waiting and resting call
   `advance_minutes`. A jump fires every minute, day and deadline boundary it crosses, in the order of Rule 9.
6. **When it runs** (table below): only while the clock is started, the game is in EXPLORATION or COMBAT, the tree is
   not paused, `ContextStack.gameplay_blocked()` is false, no scene change is in progress and no time-scale request
   is active. Hitstop and slow-mo are presentation, not game time. WorldClock only reads these values; ContextStack
   stays the sole writer of pause and time scale (`context_stack.gd:1-9`). WorldClock v1 adds a read-only ContextStack
   query for "any time-scale request active" instead of comparing the float `Engine.time_scale` with 1.0.
7. **Scene changes** add no time. A destination that costs travel time declares `travel_minutes` in data and the
   clock jumps on arrival; no 1.0 destination declares one.
8. **Saved and replayable.** The saved state is the clock's `started`, `total_minutes` and `tick_acc`, plus each
   active timed quest's `start_min` and `deadline_min` (table below); the same saved state plus the same ticks and
   jumps gives the same time (PM:11965). `real_minutes_per_day` is config, not saved: a save made at another value
   continues in game minutes.
9. **Same-minute order.** A quest completed at minute t meets a deadline D when t ≤ D. When a jump lands on D, a
   completion the jump causes is recorded before D's closure. At each minute boundary the order is: completions,
   `minute_changed`, `day_changed` (on a new day), then the closures due at that minute in `ts` order (quests without
   a `ts` after those with one, then by `quest_id`).

When several stop reasons hold at once, the reason reported is the first in table order.

| state | clock advances | reason id when stopped |
|---|---|---|
| clock not started | no | NOT_STARTED |
| tree paused (pause menu) | no | PAUSED |
| `gameplay_blocked()`: a context pushed with `blocks_gameplay` true (the default push, e.g. pause, shop); a context pushed with it false does not stop the clock (`status_window.gd:64`) | no | BLOCKED |
| scene change in progress (`SceneTransitions.is_transitioning`, `scene_transition_manager.gd:44`; covers only changes made through SceneTransitions) | no | TRANSITION |
| `GameState` DIALOGUE, CUTSCENE, PROLOGUE, ROOT_ACCESS_MODE, MENU, GAME_OVER | no (authored jumps only) | STATE |
| a time-scale request is active (hitstop, slow-mo) | no | TIME_SCALE |
| `GameState` EXPLORATION, COMBAT with none of the above | yes | — |

The `GameState` values are the enum at `game_manager.gd:22-31`; each scene sets DIALOGUE and CUTSCENE itself, so the
STATE row is as reliable as each scene's discipline.

| saved field | type | range | default |
|---|---|---|---|
| started | bool | false, true | false |
| total_minutes | int | 0 and up | 0 |
| tick_acc | int | 0 to ticks_per_day − 1 | 0 |
| start_min (per active timed quest) | int | 0 and up | — |
| deadline_min (per active Deadline quest) | int | ≥ start_min | — |

### States and Transitions

| State | Entry condition | Exit condition | Behavior |
|---|---|---|---|
| NOT_STARTED | a new game; the NG+ reset | `start_at` | no time exists; no deadline can be created; jumps do nothing |
| RUNNING | `start_at`; a stop reason clears | any stop reason in the table above | ticks accumulate (F2); minute, day and deadline boundaries fire (Rule 9) |
| STOPPED(reason) | a stop reason holds | all stop reasons clear | no ticks accumulate; authored jumps still apply |

There is no way back to NOT_STARTED except a new game or the NG+ reset.

### Interface sketch (WorldClock v1 implements; names are not binding)

Methods: `start_at(day, minute_of_day)`, `advance_until(target_min, reason)`, `advance_minutes(n, reason)`,
`now_minutes()`, `calendar()` (day, hour, minute, day_of_month, season, year), and a test seam `tick(n)` that feeds n
running ticks without the engine, for unit tests and the fast-replay bot. Signals: `clock_started`, `minute_changed`,
`day_changed`, `deadline_reached(quest_id)`, `clock_stopped(reason)`.

### Timing types as data (quest fields)

Every timed quest carries a `quest_timing` record. Per-type fields are required only for that type.

| field | type | allowed | timing_type |
|---|---|---|---|
| quest_id | StringName | the quest's id (e.g. `bridge_before_dark`, `ch1/north_field.dlg:107`) | all |
| ts | int | optional; the PM index number (TS02 is 2); orders same-minute closures (Rule 9) | all |
| timing_type | enum | Window, Deadline, Order, Duration | all |
| reason_key | string key | non-empty; the in-world reason shown in the quest log | all |
| warning_key | string key | non-empty; the signpost line, shown before closure (PM:11963) | all |
| outcomes | list of {outcome_id, flag} | at least 2; flags follow the naming rule (part C) | all |
| leniency_applies | bool | default true; always false for Order | Window, Deadline, Duration |
| warning_lead_min | int | >= 0 game minutes before closure | Window, Deadline, Duration |
| opens_at, closes_at | absolute minute (`total_minutes`) or event id | `closes_at` required; `closes_at` > `opens_at` when both are minutes | Window |
| start_event | event id | the event that starts the quest | Deadline, Duration |
| window_min | int | > 0, base length in game minutes; with `closes_at_time` set, the minimum window | Deadline |
| closes_at_time | minute of day | optional, 0 to 1439; set for a main-story deadline that closes at a named time (dusk) | Deadline |
| fast_min, slow_min | int | 0 < `fast_min` < `slow_min` | Duration |
| first_step, then_step | step id | two different steps | Order |
| start_min (saved per active quest) | int | the clock's `total_minutes` when `start_event` fired | Deadline, Duration |
| deadline_min (saved per active quest) | int | fixed at start by F4 | Deadline |

- **Window** (15 quests): available only between `opens_at` and `closes_at`. **Deadline** (14): closes at
  `deadline_min`, fixed at start by F4: either `window_min` after start, or, with `closes_at_time`, the first time of
  day `closes_at_time` at least `window_min` after start (user decision D1, 2026-11-19). **Order** (5): doing `first_step` before `then_step` changes
  the second; no clock field. **Duration** (6): elapsed time to finish picks the outcome: at most `fast_min` is the
  early outcome, at most `slow_min` on time, longer late.
- **Leniency** (ROADMAP:525, PM:11964): the difficulty multiplier L, stored as an integer percent, scales a Deadline's
  `window_min`, a Duration's `fast_min` and `slow_min`, and a Window's length (absolute minutes only, `opens_at`
  fixed), each by `scale()` (Formulas). For a deadline with `closes_at_time`, leniency changes the guaranteed window,
  never the closing time: "dark" stays dark on every difficulty. It never applies to an Order or to an event-bound
  Window close. A quest tied to a calendar or market schedule sets `leniency_applies` false in its data. The L values
  belong to S06c (provisional, ROADMAP:473: 150, 125, 100, 100, 85 percent).
- **Outcome flags** keep the three PM variants (EARLY, ON_TIME, LATE) or the quest's own named outcomes (the bridge:
  saved, evacuated, fell). The PM's "Timing condition:" text becomes field values when each quest is built.

### The 40 PM time-sensitive quests (PM:11953-12473)

Types are copied from each quest's own `Timing type:` line: 15 Window, 14 Deadline, 5 Order, 6 Duration. `pm_line` is
the quest's `## TSnn` heading in `AethelgardPrototype/story/source/PRODUCTION_MASTER_2.1.md`.

| ts | title | timing_type | pm_line |
|---|---|---|---|
| TS01 | Flour Before Rain | Window | 11954 |
| TS02 | Bridge Before Dark | Deadline | 11967 |
| TS03 | North Field Irrigation | Duration | 11980 |
| TS04 | Aldric at the Gate | Order | 11993 |
| TS05 | Medicine Convoy | Deadline | 12006 |
| TS06 | Arena Memorial | Window | 12019 |
| TS07 | Missing Shift | Duration | 12032 |
| TS08 | Auction Lot Seventeen | Window | 12045 |
| TS09 | Fourth Shift Vote | Deadline | 12058 |
| TS10 | Limited Blade Release | Window | 12071 |
| TS11 | Wastes Storm | Window | 12084 |
| TS12 | Stranded Caravan | Deadline | 12097 |
| TS13 | House That Moved First | Order | 12110 |
| TS14 | Archive Purge | Deadline | 12123 |
| TS15 | Data Stream Sync | Window | 12136 |
| TS16 | Null Hearing | Window | 12149 |
| TS17 | Appeal Migration | Deadline | 12162 |
| TS18 | Pilot Reintegration | Duration | 12175 |
| TS19 | Three Nemas | Order | 12188 |
| TS20 | Orange Caravan | Window | 12201 |
| TS21 | Mirror Bleed | Duration | 12214 |
| TS22 | Passenger Echo | Window | 12227 |
| TS23 | Healthy Arm Projection | Order | 12240 |
| TS24 | Reflection That Stayed | Deadline | 12253 |
| TS25 | Fourth Road Rescue | Duration | 12266 |
| TS26 | Choir Awakening | Deadline | 12279 |
| TS27 | Relief Bell | Window | 12292 |
| TS28 | Last Maintenance Window | Window | 12305 |
| TS29 | Seven Downtime | Duration | 12318 |
| TS30 | Cathedral Evacuation | Deadline | 12331 |
| TS31 | Memory Low Tide | Window | 12344 |
| TS32 | Tovin Kitchen | Window | 12357 |
| TS33 | Dormant Consent | Order | 12370 |
| TS34 | Archive Tide | Deadline | 12383 |
| TS35 | Last Train | Window | 12396 |
| TS36 | Assembly East Gate | Deadline | 12409 |
| TS37 | Missing Delegate | Deadline | 12422 |
| TS38 | Sunset Clause | Deadline | 12435 |
| TS39 | Truth Release Day | Window | 12448 |
| TS40 | Root Seal Failure | Deadline | 12461 |

### The two live deadlines in clock terms

Shared: `dusk_min` = 1080 (18:00). Both main-story deadlines set `closes_at_time` = `dusk_min`: the Chapter 1 "dark" and
the Chapter 2 "evening bell" are dusk on every difficulty, and leniency sets the guaranteed window instead (user
decision D1, 2026-11-19). The values below are provisional Tuning Knobs (section 7); the script-level wiring is listed
for WorldClock v1 under Dependencies.

**Chapter 1 bridge (TS02, PM:11967; C1-S07, PM:1718-1730)**

- Start: the bridge warning starts the clock with `start_at(1, dusk_min − scale(base_deadline_min))` (Core Rule 3),
  then `do quest_start bridge_before_dark` (`north_field.dlg:107`) records `start_min`. Bran: "Until dark. I've
  written it down, so it's official." (`north_field.dlg:106`).
- Deadline: F4 with `window_min` = `base_deadline_min` 300 and `closes_at_time` = dusk: always 18:00 of day 1, and the
  window is exactly `scale(300)` (450 / 375 / 300 / 300 / 255 minutes). The repair takes `repair_duration_min` 180;
  `margin_min` is 30.
- The choice is the turn-back: fix / warn / wait is offered once, in the conversation that starts the quest
  (`north_field.dlg:106-111`; one-shot, `ch1_oakhaven_village.gd:595-597`). At that moment the full window is left, so
  by F5 the repair is always possible and no later prompt is needed while the choice stays one-shot. If a later version
  makes the choice repeatable, Signposting rule 4 applies to it.
- Outcomes (existing flags): `ch1_bridge_saved` (repair accepted: the 180-minute jump lands at or before the deadline,
  Core Rule 9), `ch1_bridge_fell` (dusk reached with the bridge not saved). `ch1_bridge_evacuated` is the warn choice
  and co-occurs with `ch1_bridge_fell`, as the build does (`ch1_shrine.gd:130-133`; `north_field.dlg:132` reads both);
  the PM lists the three as exclusive (PM:1728-1730) and this GDD keeps the build. `ch1_bridge_repair_accepted` and
  `ch1_bridge_ignored` stay the choice flags.
- Signpost: Bran in the scene; a quest-log line with the reason (rain tonight) and the deadline; a log notice when
  `warning_lead_min` (60) remains.
- Today's trigger becomes: the instant fade after the repair choice (`ch1_oakhaven_village.gd:600-602`) becomes
  `time_passes 180`. When the bridge quest has started, the shrine's after-dark chain (`ch1_shrine.gd:128-140`, both
  branches) first calls `advance_until(deadline_min + 60)`. Reached before that minute, the jump makes the "Oakhaven,
  after dark" card and Bran's "Heard it go about an hour ago" (`north_field.dlg:131`) true, and in the not-saved branch
  it crosses the deadline, which resolves `ch1_bridge_fell`. Reached later, the jump does nothing: the card is still
  true, but Bran's "an hour ago" is not, and Edge Case 16 applies. The scene owns this deadline, so it asks nothing.
- Stays authored: Bran's lines, the repair / warn / ignore choice, the location card and the cart lines
  (`north_field.dlg:130-133`).

**Chapter 2 medicine convoy (TS05, PM:12006; C2-S06, PM:2259-2268)**

- Start: Rem's request (`set ch2_medicine_quest_active`, `ironhold_city.dlg:110`) records `start_min`; there is no
  anchor. Rem: "Until the evening bell." (`ironhold_city.dlg:104`); the PM: "before next evening bell" (PM:2264).
- Deadline: F4 with `window_min` = `base_deadline_min` 240 and `closes_at_time` = dusk: the first 18:00 at least
  `scale(240)` after the request. At L 100 %, asked at 14:00 it closes at 18:00 that day; asked at 16:00, at 18:00 the
  next day. The convoy trip is `convoy_trip_min` 120; `margin_min` is 30.
- Outcomes (existing flags): `ch2_medicine_early` (delivered by the deadline while the arena bronze bracket is not yet
  won) and `ch2_medicine_on_time` (delivered by the deadline after it is won), as `ironhold_region.gd:1195-1199`;
  `ch2_medicine_late` (the deadline closes first). Delivery at exactly `deadline_min` is on time (Core Rule 9).
- The Clock Tower is the bell (user decision D2, 2026-11-19): climbing the tower while the medicine deadline is still
  open (active, undelivered, `deadline_min` not yet reached) calls `advance_until(deadline_min)` behind the existing
  tower-gate prompt (`ironhold_city.dlg:237-241`), so Seraphina's "That was the evening bell" (`clock_tower.dlg:20`)
  is true and the deadline resolves late, as today (`ironhold_region.gd:648-652`). With the medicine done or not
  started, the climb moves no time. Once the clock has already closed the deadline, the gate prompt and line 20 no
  longer apply, although `ch2_medicine_quest_active` is still set; Edge Case 16 applies.
- Signpost: Rem, Seraphina in the Command Hall, the quest log with the deadline, the 60-minute notice, and the
  tower-gate turn-back. Committing to the convoy with less than `convoy_trip_min` left asks first.
- Stays authored: the convoy and escort scenes, the arena-bronze rule, the named NPCs who fall ill when late
  (PM:2265-2267).

**The plan's edge case, as numbers.** The bridge stays possible when
`scale(base_deadline_min) − repair_duration_min ≥ margin_min` for every leniency L (F5). With 300, 180 and 30: L 150 %
→ 270, 125 % → 195, 100 % → 120, 100 % → 120, Hell 85 % → 75; all are at least 30. Constraint handed to S06c: L must
stay at or above 70 % (the medicine floor is 63 %, F6).

### Pace and timing flags

Each act records pace EARLY, ON_TIME or LATE, and specific timing flags matter more than raw pace when a named event is
involved (PM:1098-1100). Pace is one coarse record per act; the flags carry the named events.

| act | flag_early | flag_on_time | flag_late | status | rule | source |
|---|---|---|---|---|---|---|
| 1 | act1_pace_early | act1_pace_on_time | act1_pace_late | existing | Road Out route choice: old server road early, safe road on time, caravan route late (`act1_end.dlg:31-43`) | PM:2862-2872 |
| 2 | act2_pace_early | act2_pace_on_time | act2_pace_late | new | open: set by the act's closing scene; the rule is chosen when the act is built (user decision D3, 2026-11-19) | PM:3810-3812 and PM:6659-6661 (two PM sets; their merge is decided when Act 2 is built) |
| 3 | act3_pace_early | act3_pace_on_time | act3_pace_late | new | open, as act 2 | PM:7589-7591 |
| 4 | act4_pace_early | act4_pace_on_time | act4_pace_late | new | open, as act 2 | PM:8202-8204 |

**Open Question 4 decision (axes GDD): option A, road choice only (user decision, 2026-11-19).** Act 1's pace stays
the route choice as built and never reads the clock. Its consequences, stated rather than hidden: PM:2869-2871's
"completed quickly", "moderate detours" and "many rests" are not measured; a player whose bridge fell cannot take the
caravan (`act1_end.dlg:34`), the only LATE road, so that player's pace is EARLY or ON_TIME, while a player who saved the
bridge and takes the caravan is LATE; missed deadlines are recorded only by their timing flags (`ch1_bridge_fell`,
`ch2_medicine_late`), and Story+, which reflects act pace (PM:1123), must read both. The act 2-4 names are defined
here; their rules and closing scenes belong to each act's content.

**Timing-flag naming.** `<scene prefix>_<subject>_<outcome>`, lowercase snake_case, named for the event, not the act:
`ch1_bridge_saved`, `ch2_medicine_on_time`. The outcome suffix is `_early`, `_on_time`, `_late` for the PM's three
variants, or the quest's own verb. `act<N>_pace_*` is reserved for pace. The PM's uppercase examples (PM:1101-1108,
e.g. OAK_BRIDGE_FELL for `ch1_bridge_fell`) are the kind of event a timing flag names; each gets its lowercase name
when that event is built.

**Signposting rule.** A main-story deadline closes only after: (1) its in-world reason at start; (2) a quest-log entry
from start showing the reason and the deadline; (3) a notice when `warning_lead_min` remains; (4) a turn-back prompt
before any action or jump that would cross it; (5) concrete consequences, with no invisible deaths (PM:2268).

## Formulas

All values are integers. The leniency L is an integer percent `L_pct` (S06c). `scale(x) = (x × L_pct + 50) div 100`:
x × L rounded half up, exact in integers.

**F1 ticks per day.** `ticks_per_day = real_minutes_per_day × 60 × tick_rate`. `real_minutes_per_day` 6 to 60
(default 24), `tick_rate` 60. Range 21600 to 216000. Example: 24 → 86400. Real seconds per game minute =
`real_minutes_per_day / 24`: 1.0 at the default, 0.25 at 6, 2.5 at 60.

**F2 tick accumulation (each running tick).** `tick_acc += 1440; if tick_acc >= ticks_per_day:
total_minutes += tick_acc div ticks_per_day; tick_acc = tick_acc mod ticks_per_day`. `tick_acc` stays in 0 to
`ticks_per_day − 1`; at most one minute per tick because `ticks_per_day` ≥ 1440. Examples: at 24,
`ticks_per_day / 1440` = 60, so every 60th tick adds exactly one minute and `tick_acc` returns to 0. At 25,
`ticks_per_day` = 90000: after 62 ticks `tick_acc` = 89280 (no minute); the 63rd gives 90720, so +1 minute and
`tick_acc` = 720.

**F3 calendar from `total_minutes`.** `day = total_minutes div 1440 + 1`; `minute_of_day = total_minutes mod 1440`;
`hour = minute_of_day div 60`; `minute = minute_of_day mod 60`; `day_of_month = (day − 1) mod 28 + 1`;
`season_index = ((day − 1) div 28) mod 4` (0 SPRING, 1 SUMMER, 2 AUTUMN, 3 WINTER); `year = (day − 1) div 112 + 1`.
Example: `total_minutes` 44285 → day 31, 18:05, `day_of_month` 3, `season_index` 1 (SUMMER), year 1.

**F4 deadline.** `w = max(1, scale(window_min))`; `earliest = start_min + w`. Without `closes_at_time`:
`deadline_min = earliest`. With `closes_at_time` c: `deadline_min = (earliest div 1440) × 1440 + c`, plus 1440 if that
is below `earliest`. Examples, the bridge (c 1080, `window_min` 300): L 100 % → start 780, `earliest` 1080, deadline
1080 (18:00); Hell 85 % → start 825 (13:45), `earliest` 825 + 255 = 1080, deadline 1080; Beginner 150 % → start 630
(10:30), deadline 1080. The medicine (c 1080, `window_min` 240) at 100 %: requested at 840 → 1080; requested at 960 →
`earliest` 1200 → 2520 (day 2, 18:00).

**F5 bridge margin.** `slack = scale(base_deadline_min) − repair_duration_min` must be ≥ `margin_min` for every L in
the difficulty table. With 300, 180, 30: 150 % → 270, 125 % → 195, 100 % → 120, 100 % → 120, 85 % → 75; all are at
least 30. Floor: the least `L_pct` with `scale(300)` ≥ 210 is 70 (300 × 70 + 50 = 21050, div 100 = 210); at 69 it is
207. A leniency below 70 % makes the repair impossible.

**F6 convoy margin.** The same form on the guaranteed window: `scale(240) − 120 ≥ 30`: 150 % → 240, 125 % → 180,
100 % → 120, 85 % → 84. Floor 63 % (240 × 63 + 50 = 15170 → 151, slack 31; at 62, 149, slack 29). The real window is
never shorter, because F4 closes at the first dusk at or after `earliest`.

**F7 Window length with leniency.** `closes_at' = opens_at + scale(closes_at − opens_at)`, absolute minutes only, when
`leniency_applies`. Example: a 2880-minute window at 150 % → 4320 minutes.

**F8 Duration outcome.** `elapsed = now_minutes − start_min`; early if `elapsed ≤ scale(fast_min)`, on time if
`elapsed ≤ scale(slow_min)`, else late. Example: `fast_min` 120, `slow_min` 300 at 85 % → early up to 102 minutes, on
time up to 255 (elapsed 102 is early, 103 on time).

## Edge Cases

1. **Hell leniency vs the bridge (the plan's edge case).** F5 gives slack 75 at 85 %, so the bridge stays
   repairable; the floor is 70 %. S06c must not set any leniency below 70 % for a main-story deadline; the checker
   evaluates F5 and F6 at the Tuning Knobs defaults for all five difficulty values.
2. **Save and load.** The save holds `started`, `total_minutes`, `tick_acc` and, per active timed quest, `start_min` and
   its fixed `deadline_min`. Load restores them exactly and re-evaluates the stop reasons; no wall-clock time is read,
   so time spent outside the game never counts. If `real_minutes_per_day` differs at load, `tick_acc` becomes
   `tick_acc mod` the new `ticks_per_day` (F1).
3. **Late requests.** A deadline with `closes_at_time` never closes sooner than its guaranteed window: Rem asked at
   16:00 closes at the next day's 18:00 (26 hours), asked at 14:00 at 18:00 (4 hours). The evening bell is always
   18:00, and no time is skipped to reach it.
4. **Resting or waiting across a deadline.** A jump fires every boundary it crosses in order, so the outcome resolves
   at the deadline's minute. A main-story deadline asks first (Signposting rule 4); if the player confirms, the late
   outcome applies.
5. **Several deadlines at once.** Each quest has its own `start_min` and `deadline_min`. Closures fire in
   `deadline_min` order; at the same minute, in the order of Core Rule 9. Deterministic.
6. **Deadline while the clock is stopped.** A stopped clock does not reach it. Only a jump can cross it, and then every
   boundary fires in order.
7. **Death, retry, reload.** The clock returns to the last save's `total_minutes`; there is no time penalty for dying.
8. **NG+.** The clock resets to NOT_STARTED and every quest timing record is cleared. Timing flags and `act<N>_pace_*`
   follow the storyline lifecycle's NG+ reset (T9), not this GDD.
9. **Window or deadline before the clock starts.** It cannot exist (Core Rule 3). No quest-log line, no warning.
10. **Long play.** A year is 112 days = 161280 minutes; `total_minutes` is an integer, and year 2 and beyond follow F3
    with no special case. Season and year changes only emit `day_changed`.
11. **Frame hitches.** Time is counted in physics ticks, not seconds, so a slow frame never adds game time. The engine
    may cap catch-up steps per frame, in which case a long hitch loses ticks rather than adding them. This is not
    covered by `docs/engine-reference/godot/`; WorldClock v1 checks it in the editor.
12. **Slow-mo and hitstop.** No time passes while a time-scale request is active (a 3-second boss slow-mo is 0 game
    minutes).
13. **Difficulty lowered mid-run.** A started deadline keeps the `deadline_min` it was given at start; the new
    leniency applies to quests started afterwards. Raising difficulty is not allowed (ROADMAP:480).
14. **Legacy saves.** A save with no clock fields loads NOT_STARTED. An unresolved bridge or medicine deadline in it
    falls back to today's event resolution (the shrine's after-dark check, `ch1_shrine.gd:128-136`; the tower bell,
    `ironhold_region.gd:648-652`) until WorldClock v1 migrates it.
15. **Scene times between the deadlines.** Content that states a time outside the two deadlines (`bridge_saved`'s
    "Rain and all" at 16:00, `north_field.dlg:128`; the shatter at night; reaching Ironhold the next morning) is
    inherited content timing. This GDD does not set it; WorldClock v1 places it scene by scene with `advance_until` or
    `time_passes`.
16. **A scene reached after its target time.** `advance_until` never moves backward, so a line that states how long
    ago something happened is true only when its scene is reached before the target. Two cases exist today. (a) At
    L 100 %, a player warns at 13:00 (780) and spends 8 real minutes in the region, arena and shrine, reaching the
    after-dark chain at 21:00 (1260): the jump to 19:00 (1140) does nothing, the bridge fell at dusk (1080), three hours
    earlier, and Bran's "about an hour ago" is wrong. (b) Rem asked at 14:00 (840) gives a deadline of 18:00 (1080) that
    the clock closes; climbing the tower at 20:00 (1200) finds the quest still flagged active. Rule: once a scene's
    target minute has passed, the outcome is the one the clock already resolved, and the scene must not assert the
    elapsed time or replay the bell. WorldClock v1 gates the timed lines on the clock: Bran's line on `now ≤
    deadline_min + 60`, and the tower prompt and `clock_tower.dlg:20` on the deadline still being open. Those line
    changes are protected story content and need the user's approval in that story.

## Dependencies

| system | direction | what flows | status / obligation |
|---|---|---|---|
| ContextStack (`AethelgardPrototype/scripts/core/context_stack.gd`) | this reads it | `get_tree().paused`, `gameplay_blocked()`, and a read-only "time-scale request active" query to add (Core Rule 6) | exists. ContextStack stays the sole writer (header, lines 1-9); its header should name WorldClock as a reader (ROADMAP:241: owned by ContextStack's time rules) |
| GameManager (`AethelgardPrototype/scripts/game_manager.gd`) | this reads and writes | reads `GameState` (22-31); writes timing flags with `set_story_flag` | exists |
| SaveService (Y1-P1-T05) | it stores this | `started`, `total_minutes`, `tick_acc`, per active quest `start_min` and `deadline_min` (Edge Case 2); legacy saves load NOT_STARTED (Edge Case 14) | not built. Save/load schema is a protected area: the implementing story needs the user's approval |
| `storyline-axes.md` | it reads this | the act 2-4 pace names and the timing-flag naming (its composer record, lines 469-471, says "the names S06b defines") | exists. Dependent: it lists this GDD (lines 484, 782). Any edit to it is a separate change with the user's OK |
| `storyline-lifecycle.md` | it resets this | the NG+ reset (T9) clears timing flags and paces (lines 371-376); the clock is saved state outside the composer record, so the NG+ implementation must also reset it (Edge Case 8) | exists. Obligation recorded here, not edited there |
| Difficulty profiles (S06c) | it supplies | the leniency values as integer percents; this GDD constrains them: ≥ 70 % for the bridge (F5), ≥ 63 % for the convoy (F6) | not written. S06c must list this GDD as a dependent |
| Scene dialogue-event handlers (each scene's `_on_dlg_event`, e.g. `ch1_oakhaven_village.gd:177-180`; `ironhold_region.gd` has no `time_passes` arm) | needs a change | `time_passes <minutes>` takes a duration; the convoy needs `time_passes 120`; the shrine and the tower call `advance_until` | WorldClock v1 |
| Quest log / quest events (`quest_start`, `ch1_oakhaven_village.gd:160`, `ironhold_region.gd:1207`) | it reads this | `quest_timing` records, deadline lines and the lead notice | not built; no quest-timing owner exists yet |
| Ending composer (Y2-PP-T17) | reads via axes | timing flags and act pace | not built |
| Playthrough bot and tests | it needs this | a deterministic clock, for fast, slow and out-of-order profiles (ROADMAP:528) | not built |

**Touchpoints WorldClock v1 will change, each a protected story-progression area needing the user's approval:**
`ch1_oakhaven_village.gd` (bridge, `start_at`, `time_passes 180`), `ch1_shrine.gd` (after dark, `advance_until`),
`ironhold_region.gd` (convoy, tower bell, `advance_until`), `ironhold_city.dlg` and `clock_tower.dlg` (medicine, bell),
`act1_end.dlg` (pace), and the inherited scene times of Edge Case 15.

## Tuning Knobs

| knob | default | safe range | affects | constraint / rationale |
|---|---|---|---|---|
| `real_minutes_per_day` | 24 | 6 to 60 | how fast game time passes; a deadline's real length is `window_min × real_minutes_per_day / 24` seconds | ROADMAP:512 ("tunable") |
| `dusk_min` | 1080 (18:00) | 960 to 1200 | when "dark" and "the evening bell" fall | provisional; both live deadlines end here |
| `base_deadline_min` (bridge) | 300 | 250 to 450 | how long the bridge warning leaves the player | F5: ≥ 247 at 85 %; the clock starts at `dusk_min − scale(base_deadline_min)` (13:00 at 100 %) |
| `repair_duration_min` | 180 | 120 to 210 | how much time the repair takes | F5: ≤ 225 at 85 % with base 300 |
| `base_deadline_min` (medicine) | 240 | 180 to 360 | the convoy's guaranteed window | F6: ≥ 176 at 85 %; the deadline is the first dusk at least `scale(240)` after the request |
| `convoy_trip_min` | 120 | 60 to 150 | the convoy trip's cost | F6 |
| `margin_min` | 30 | 15 to 60 | the least spare time a deadline must leave | F5, F6 |
| `warning_lead_min` | 60 | 30 to 120 | when the quest-log notice appears before closure | Signposting rule 3 |
| leniency L (five integer percents) | S06c | each ≥ 70 for main-story deadlines | quest-deadline pressure by difficulty | ROADMAP:473 as percents, provisional 150, 125, 100, 100, 85 |

Each safe range holds with the other knobs at their defaults; the pass test for a combination is F5 and F6 on the
final values. Fixed by design (changing them changes F3 and saved data): 60 minutes per hour, 24 hours per day, 28 days
per month, 4 seasons, one season per month, `tick_rate` 60. All numeric defaults above are provisional and settled by
playtest, not by this GDD.

## Acceptance Criteria

Now = checked by the S06b checker (`production/qa/evidence/2026-11-time-model/check_time_model.py`). WorldClock v1 = a
test in the Y1-P1 story that builds the clock.

| id | type | criterion | verified by | when |
|---|---|---|---|---|
| AC1 | Logic | At `real_minutes_per_day` 24, every 60th running tick adds one minute and `tick_acc` returns to 0; 86400 ticks = 1440 minutes. At 25, the 63rd tick adds a minute leaving `tick_acc` 720 (F1, F2). | unit test | WorldClock v1 |
| AC2 | Logic | `total_minutes` 44285 gives day 31, 18:05, `day_of_month` 3, SUMMER, year 1; 161279 gives day 112, 23:59, WINTER, year 1; 161280 gives day 113, SPRING, year 2, `day_of_month` 1 (F3). | unit test | WorldClock v1 |
| AC3 | Logic | With the clock started, for each stop row `tick(600)` leaves `total_minutes` unchanged and reports that row's reason id; with a default `push` (PAUSED and BLOCKED both hold) PAUSED is reported; a context pushed with `blocks_gameplay` false does not stop the clock; in EXPLORATION and COMBAT `tick(600)` adds 10 minutes at the default rate; jumps still apply while STOPPED and do nothing while NOT_STARTED. | unit test | WorldClock v1 |
| AC4 | Logic | The same saved state plus the same tick and jump sequence gives identical `total_minutes` and `tick_acc` in two runs; saving at tick N, reloading and continuing equals the uninterrupted run. | unit test | WorldClock v1 |
| AC5 | Integration | Saved while STOPPED(PAUSED) with an active deadline, then reloaded: `deadline_min` is unchanged and the clock resumes; a save with no clock fields loads NOT_STARTED (Edge Cases 2, 14). | integration test | WorldClock v1 |
| AC6 | Logic | F4-F8 return their worked examples: the bridge deadline is 1080 at 150, 100 and 85 % (starts 630, 780, 825); the medicine requested at 960 closes at 2520; F5 slack is 15 at 65 % and F6 slack 24 at 60 %; a 2880-minute window at 150 % gives 4320; `fast_min` 120 / `slow_min` 300 at 85 % gives 102 / 255 (elapsed 102 early, 103 on time). | unit test | WorldClock v1 |
| AC7 | Config | At the Tuning Knobs defaults, `scale(base_deadline_min) − repair_duration_min ≥ margin_min` (F5) and `scale(240) − 120 ≥ 30` (F6) hold for the five provisional L values. | checker | Now |
| AC8 | Integration | Bridge at 100 %: the warning calls `start_at(1, 780)` before `quest_start`, so `start_min` 780 and `deadline_min` 1080; fix → `time_passes 180` lands at 960 and sets `ch1_bridge_saved`; warn → at 1080 `ch1_bridge_evacuated` and `ch1_bridge_fell` are both set; wait → `ch1_bridge_ignored` and `ch1_bridge_fell`; entering the shrine's after-dark chain at 1000 moves the clock to 1140. | integration test | WorldClock v1 |
| AC9 | Integration | Medicine at 100 %: requested at 840 → `deadline_min` 1080; at 960 → 2520. Delivered at a minute ≤ `deadline_min` → `ch2_medicine_early` if `ch2_arena_bronze_complete` is false, `ch2_medicine_on_time` if true; delivered exactly at `deadline_min` → on time; undelivered at `deadline_min` → `ch2_medicine_late`; climbing the tower while it is active and undelivered moves the clock to `deadline_min` behind the gate prompt and sets late; climbing with it done moves no time. | integration test | WorldClock v1 |
| AC10 | Logic | From 780, quests A (`ts` 2), B (`ts` 5) and C (no `ts`), all undelivered with `deadline_min` 900: `advance_minutes(200)` fires at minute 900 `minute_changed`, then the closures of A, B, C, and ends at 980; a completion the jump records at 900 counts as met (Core Rule 9). | unit test | WorldClock v1 |
| AC11 | Logic | `advance_until(1140)` at 1000 moves to 1140 and fires the boundaries in between; at 1200 it does nothing; it never moves backward; if it would cross an open main-story deadline the scene does not own, a prompt comes first and declining moves no time. | unit test | WorldClock v1 |
| AC12 | Config | The 40-row TS table matches the production master: each `timing_type` equals its `Timing type:` line (15 / 14 / 5 / 6) and each `pm_line` is on its `## TSnn` heading. | checker | Now |
| AC13 | Config | The pace table's 12 flags match `act{1-4}_pace_(early\|on_time\|late)`; the 3 `existing` flags are found in code or dialogue and the 9 `new` flags are in neither. | checker | Now |
| AC14 | UI | For each main-story deadline the quest log shows the reason and the deadline from start, a notice at `warning_lead_min`, and a turn-back prompt before a crossing action; a retained screenshot of each. | manual, screenshots | WorldClock v1 |
