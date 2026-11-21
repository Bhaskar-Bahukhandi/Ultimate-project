# Review log: difficulty-profiles.md

## Review — 2026-11-21 — Verdict: NEEDS REVISION
Scope signal: L
Specialists: game-designer, systems-designer, qa-lead, godot-specialist, ux-designer, creative-director (synthesis)
Blocking items: 9 | Recommended: 4 (plus the specialists' remaining recommendations, logged in the evidence README)
Summary: Round 1 of 2 under the user's exit rule (OQ20 bar). The profile table, every formula's worked example and all
27 constants-map tokens hold. The blockers are text fixes: the assist (DDA) contradicts Rule 4 and the Player Fantasy
(player bonus kept, "on" makes Easy harder, the multiplier silently scales HP, damage, speed, corruption), the
accessibility toggles are unaddressed, and several citations, tables and ACs disagree.
Prior verdict resolved: First review
Findings:
- [BLOCKING] Detailed Design (dda table) / F6 / F7 / AC6 / AC12: player bonus contradicts Rule 4 (Easy heals 150, not 120); "on" lets Easy reach Medium's telegraph; the multiplier also scales enemy HP, contact damage, speed (enemy_base.gd:1486-1500), corruption (game_manager.gd:790), soul drain
- [BLOCKING] F2 / Edge Case 10 / Edge Case 14 / AC11: the extended_parry_window toggle (+6 frames, player_combat.gd:1242-1243) and invincibility_mode are unaddressed; Hell's parry becomes 8 frames; an invincible run counts as a Hell clear
- [BLOCKING] Constants map: enemy_base.gd:71 (0.45 s) is overwritten per attack at :428-436; the :440 floor is unmapped
- [BLOCKING] Hell prerequisites / Edge Case 9 / AC10: fixed tick is Y1-P2-T02 not T04; latency calibration is owned by T22 not "unowned"; three different unlock conditions; AC10 shows locked Hell in a pause screen that lists only lower profiles
- [BLOCKING] Constants map vs F3: DASH_DURATION "becomes dodge_iframes" but F3 keeps the dash at 11 frames
- [BLOCKING] States and Transitions vs Edge Cases 2-4 / AC9: "next frame" vs next phase, next rest, kept deadline; telegraphs are set once per attack
- [BLOCKING] AC11: "one frame off" defeated by the 4-frame input buffer; must be "one frame late"
- [BLOCKING] Old-setting mapping / Core Rule 7 / Edge Case 7: the legacy mapping reads a settings key the new build also writes (a Hell default of 4 reads as Hell or medium)
- [BLOCKING] AC4 / checker: the checker accepts "persistence: global"
- [RECOMMENDED] checker: pin the old mapping 0->beginner .. 3->hard
- [RECOMMENDED] Player Fantasy: a rule and AC for "help that tells you it is helping"
- [RECOMMENDED] Edge Cases: NG+ +25% enemy damage per cycle stacks with Hell's 200%
- [RECOMMENDED] Core Rule 8: a confirm line before lowering ("cannot be raised again this run")
Rejected or downgraded: telegraph-floor ties (the "falls" rule covers knob values); charm rounding (no .5 case); the plan's "migration default medium" (the plan differs from a newer user decision); checker range/row checks (declined at readiness); AC5 disposition of a non-outlier recommendation; "mapping notice is false" (resolved by D2).
User decision: revise now. D1 "Timing only, helps only" (assist changes telegraph length and attack cooldown, only ever slower; player bonus removed). D2 "Separate axis, flags clear" (accessibility toggles stack on every profile; a run that used one is recorded "<profile> (assisted)"; AC11 runs with both off).
Reviewed-Content-Hash: design/gdd/difficulty-profiles.md 770b02b818d4fa0752a0a5b8e7db27a11581d67d
Reviewed-Content-Hash: design/registry/entities.yaml 216ffa67ed4d5d24548df37b2ce899fcba892285

## Review — 2026-11-21 — Verdict: NEEDS REVISION
Scope signal: L
Specialists: none (lean, single session)
Blocking items: 2 | Recommended: 12
Summary: Round 2 of 2 (last) under the user's exit rule (OQ20 bar), on revision 2. All 9 round-1 blockers are
resolved; the checker passes; every file:line, ROADMAP and plan citation was re-checked and holds. The two blockers are
acceptance-criteria wording: AC9's telegraph number ignores Easy's assist at the starting score, and AC11's "one frame
late" can still parry. User decision: the starting session fixes both ACs; no third round.
Prior verdict resolved: Yes
Findings:
- [BLOCKING] Acceptance Criteria AC9 (bar a/b): "boar charge 31 → 45 frames" after lowering to Easy; Edge Case 12 keeps the score, which starts at 50.0 (game_manager.gd:496), so F7 gives tempo 98 and F4 gives (4500 + 49) div 98 = 46; 45 holds only at score ≥ 52
- [BLOCKING] Acceptance Criteria AC11 (bar a): a 2-frame window parries on frames H−1 and H; a recorded run pressing on H−1 still parries one frame late, so a correct build fails; the reference press must be the last frame that parries
- [RECOMMENDED] Formulas: "All values are integers" vs F1 seconds and F7 "raw 98.08" (F7's round() settles it; integer div differs at score 21, on: 75 vs 76)
- [RECOMMENDED] Old-setting mapping: STORY/EASY rows omit player damage 150 → 100 and 125 → 100
- [RECOMMENDED] Core Rule 7: new-game default when `gameplay/difficulty_profile` is absent is unstated
- [RECOMMENDED] Core Rule 7 / Dependencies: `assisted: true` is a second save field; only `difficulty` is listed
- [RECOMMENDED] Core Rules 9-10: "assist" names both DDA and the "(assisted)" record; say a gentle/on DDA run is not "(assisted)"
- [RECOMMENDED] Detailed Design (assist): get_player_dda_bonus() "adds up to 125 percent" → multiplies by up to 1.25
- [RECOMMENDED] Formulas: no formula for attack cooldown under assist; untested in AC6/AC12
- [RECOMMENDED] Acceptance Criteria AC6: the boar telegraph values are at tempo 100; say so
- [RECOMMENDED] Edge Case 8: an NG+ carry-over decision (protected area); the restart-path NG+ bug would drop the profile; ×1.5 stacks on contact damage/HP only (enemy_base.gd:180-183)
- [RECOMMENDED] Core Rule 9: the disclosure copy mentions telegraphs only; assist also lengthens cooldowns
- [RECOMMENDED] Core Rule 1: Hell lock and clear recording need rank/lock as profile data, not id branches
- [RECOMMENDED] Evidence README AC map: says the constants map has 20 rows; it has 31
Checker: check_difficulty_profiles.py RESULT: PASS (0 problems)
Reviewed-Content-Hash: design/gdd/difficulty-profiles.md c9e4916d92bdb59797e514670866491060370dda
Reviewed-Content-Hash: design/registry/entities.yaml 216ffa67ed4d5d24548df37b2ce899fcba892285
