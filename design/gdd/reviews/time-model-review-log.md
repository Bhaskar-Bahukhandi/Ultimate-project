# Review log: time-model.md

## Review — 2026-11-19 — Verdict: NEEDS REVISION
Scope signal: L
Specialists: game-designer, systems-designer, qa-lead, godot-specialist, narrative-director, creative-director (synthesis)
Blocking items: 7 | Recommended: 6
Summary: Round 1 of 2 under the user's exit rule (a finding blocks only with a failing case, a contradiction in the
text or a false citation). The clock core (units, F1-F3, the stop table), the quest-timing data model, the 40-quest
table and F5/F6 hold, and every worked number was recomputed correct. Most blockers come from one unsettled model:
whether a main-story deadline is a time of day (dusk) or a length scaled by leniency.
Prior verdict resolved: First review
Findings:
- [BLOCKING] Detailed Design C / F4 / Edge Case 3 / AC9: deadlines are both dusk and an L-scaled length (Beginner bridge 20:30, Hell 17:15; Rem asked at 16:00 shows 20:00 but goes late at 18:00); `anchor_forward(13:00)` cannot start the clock (skip 780 > 120 cap)
- [BLOCKING] Detailed Design C: scenes that assert a time contradict the clock (shrine "after dark" card reachable at ~13:05; tower line "That was the evening bell" at 14:30)
- [BLOCKING] Detailed Design C / AC8: the bridge turn-back can never fire (choice offered in the quest_start conversation, >= 255 min left); outcomes overlap (the build sets fell with evacuated)
- [BLOCKING] Detailed Design / Edge Case 5 / AC9 / AC10: same-minute resolution undefined (delivery at exactly 18:00; "ts-number order" uses a field quest_timing lacks; "bell boundary" has no signal)
- [BLOCKING] Core Rule 6 / AC3: stop-reason precedence undefined (default ContextStack push both pauses and blocks); "panels" partly false (status_window pushes false, false)
- [BLOCKING] Pace and timing flags: act 2-4 rule cites PM:1099, which does not say it (false citation; PM has its own pace triples); the Open Question 4 "carried by the flags" sentence hides that a fell bridge removes the caravan, so that player can never be LATE
- [BLOCKING] Acceptance Criteria / Tuning Knobs: AC7 overstates what the checker verifies (knob defaults only); "F6: >= 177" should be 176
- [RECOMMENDED] Formulas: store L as an integer percent (float half-up drift at exact .5 products)
- [RECOMMENDED] Tuning Knobs: require warning_lead_min >= cost + margin (notice currently after the point of no return)
- [RECOMMENDED] Player Fantasy / Dependencies: name an owner for making time visible (HUD clock, dusk cue)
- [RECOMMENDED] Dependencies: give the time_passes handler its real owner (per scene) and define a bare `do time_passes` (north_field.dlg:158)
- [RECOMMENDED] Core Rule 8: add a deadline_min saved row
- [RECOMMENDED] Interface: a tick-injection seam for the fast-replay bot; Edge Case 11 catch-up cap unverified (no Godot reference covers it)
Rejected or downgraded: Core Rule 8 vs Edge Case 2 is not a contradiction; AC9's bronze outcome is stated in Detailed Design; inherited scene timing (shatter at night, Ironhold next morning, "Rain and all" at 16:00) goes to WorldClock v1; safe-range corners are scoped "with the other knobs at their defaults"; clock_tower.dlg:21 is imprecise, not false.
User decision: revise now; round 2 (lean, on the diff) is the last under the 2-round cap.
Reviewed-Content-Hash: design/gdd/time-model.md eb608d71d9bc91ba8c0a1e2b213ad373e0aea0ab
Reviewed-Content-Hash: design/registry/entities.yaml 216ffa67ed4d5d24548df37b2ce899fcba892285

## Review — 2026-11-19 — Verdict: NEEDS REVISION
Scope signal: L
Specialists: none (lean, round 2 of 2, the last under the cap)
Blocking items: 1 | Recommended: 9
Summary: Revision 2 resolves round-1 blockers 1 and 3-7; every worked number was recomputed correct and every
file:line / PM:line citation resolves (bar c: none false). One bar-(a) failing case remains, the late side of round-1
blocker 2: `advance_until` is forward-only, so the lines it is claimed to make true are false when the scene is
reached after its target. Checker: PASS (0 problems).
Prior verdict resolved: Partly (blocker 2 partly; 1, 3-7 yes)
Findings:
- [BLOCKING] Detailed Design C (bridge, convoy): L 100 %, warn at 780, 8 real min in the region/arena/shrine → 1260; advance_until(1140) no-op, Bran's "about an hour ago" 180 min after; Rem at 840, deadline closes 1080 by the clock, tower at 1200 still plays tower_warning and "That was the evening bell" (ch2_medicine_quest_active stays set)
- [RECOMMENDED] Acceptance Criteria AC10: "a completion the jump records at 900" while the jump lands at 980; test a landing on 900
- [RECOMMENDED] Core Rule 6 / AC3: blocks_gameplay false stops nothing only if pauses_tree is also false (no caller today)
- [RECOMMENDED] Interface sketch: say tick(n) obeys the stop table
- [RECOMMENDED] Edge Case 3: "no time is skipped to reach it" vs D2's tower jump; scope to the deadline computation
- [RECOMMENDED] Detailed Design C (convoy): both rem_go_now (:110) and rem_later (:115-116) start the quest
- [RECOMMENDED] Timing types: opens_at optional but F7 needs it
- [RECOMMENDED] Edge Case 14: a legacy Ch2 save before Rem's request never starts the clock
- [RECOMMENDED] Edge Case 15: "16:00" holds only at L 100 % (13:30 at 150 %, 16:45 at 85 %)
- [RECOMMENDED] Signposting rule: state that the bridge's one-shot choice satisfies rule 4
User decision: fix B1 in revision 3 (narrow the two claims, add an edge case); no third review round; the 9 recommended items go to the evidence README "Recommended, not applied".
Reviewed-Content-Hash: design/gdd/time-model.md b6c715a4ca89359491991ed389e8ddf56d74eb5f
Reviewed-Content-Hash: design/registry/entities.yaml 216ffa67ed4d5d24548df37b2ce899fcba892285
