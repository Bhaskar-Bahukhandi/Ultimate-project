"""Expand Y3-Y6 production rosters into Y3.json .. Y6.json (see BRIEF.md).

Run:  python expand_production.py
Sources: ROADMAP_10_YEAR.md §3, §7, §12; story/STORY_BIBLE.md. Unit IDs, not invented plot.
"""
import datetime as dt
import json
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from prod_lib import (  # noqa: E402
    AXES, D, Phase, REG, STREAMS, auction_house, boss, cinematic, commodity_batch, companion, crowd,
    enemy, gen_pool, item_batch, low, minigame, music_track, npc_b_batch, player_clip, quest,
    region_dod, region_package, sfx_batch, side_storyline, tier_a, W,
)
from prod_pools import add_pools  # noqa: E402
from y6_alpha import y6_alpha  # noqa: E402

OUT = os.path.dirname(os.path.abspath(__file__))
D8 = dt.date

ARCH = ["ground melee", "ranged", "flying", "armored", "swarm", "ambusher", "caster", "shielded",
        "charger", "hazard-user", "summoner", "mimic"]
STRUCTS = ["investigation", "delivery", "combat encounter", "Root Access puzzle", "social (dialogue checks)",
           "escort", "exploration", "crafting request", "market errand", "rescue"]
TRIGGERS = ["Data Vision inspection of an odd object", "an NPC memory fact set earlier", "a world-clock window at night",
            "an off-path POI", "a Root Access edit others ignore", "an auction lot bought and examined",
            "a festival-day-only visitor", "a waystation visited in a set order"]
TIMINGS = ["deadline", "window", "order", "duration"]
LOCAL_FEEDS = ["local reputation (NPC sim)", "faction reputation seed (axis 2 input)", "a market event",
               "companion trust", "a named timing flag"]
ITEM_CATS = ["weapons", "armor (palette/overlay)", "accessories", "consumables", "crafting materials",
             "craftable gear", "set pieces", "uniques", "tools", "limited editions"]
COM_CATS = ["raw materials", "food", "textiles", "ores and metals", "data relics", "luxury goods", "medicine",
            "festival goods", "fuel", "salvage"]
ROLES = ["merchant, farmer, guard, healer, courier", "smith, innkeeper, trader, scribe, hunter",
         "auction runner, clerk, mechanic, cook, watch", "archivist, scavenger, broker, medic, guide"]


def quest_roster(reg, n_side, n_sec, ts_side, ts_sec, ss_members, hidden, tcur, scur):
    """ss_members: {quest_id: (ss_id, feeds)}; ts_*: indexes made time-sensitive; hidden: secret idx feeding H."""
    out = []
    li = 0
    for i in range(1, n_side + 1):
        qid = f"{reg}-SQ-{i:02d}"
        q = {"id": qid, "reg": reg, "kind": "side", "structure": STRUCTS[(scur + i) % len(STRUCTS)]}
        if qid in ss_members:
            q["ss"], q["feeds"] = ss_members[qid]
        else:
            q["feeds"] = LOCAL_FEEDS[li % len(LOCAL_FEEDS)]
            li += 1
        if i in ts_side:
            q["timing"] = TIMINGS[tcur[0] % 4]
            tcur[0] += 1
        out.append(q)
    for i in range(1, n_sec + 1):
        qid = f"{reg}-SEC-{i:02d}"
        q = {"id": qid, "reg": reg, "kind": "secret", "structure": STRUCTS[(scur + 3 * i) % len(STRUCTS)],
             "trigger": TRIGGERS[(scur + i) % len(TRIGGERS)]}
        q["feeds"] = "H" if i in hidden else "local reputation (NPC sim)"
        if i in ts_sec:
            q["timing"] = TIMINGS[tcur[0] % 4]
            tcur[0] += 1
        out.append(q)
    return out


def region_spec(reg, n_groups, n_pois=10, n_devs=5, n_ws=4):
    return {"reg": reg, "groups": [f"{reg}-G{i:02d}" for i in range(1, n_groups + 1)],
            "pois": [f"{reg}-POI-{i:02d}" for i in range(1, n_pois + 1)],
            "devs": [f"{reg}-DEV-{i:02d}" for i in range(1, n_devs + 1)],
            "ws": [f"{reg}-WS-{i:02d}" for i in range(1, n_ws + 1)]}


def items_and_writing(ph, first, n_batches, reg_of, cat_offset=0):
    """10-item batches; descriptions and QA grouped 2 batches per day."""
    batches = []
    for b in range(n_batches):
        lo = first + b * 10
        bid = f"ITM-{lo:03d}..{lo + 9:03d}"
        batches.append({"id": bid, "cat": ITEM_CATS[(b + cat_offset) % len(ITEM_CATS)], "reg": reg_of(b)})
    for i, b in enumerate(batches):
        pair = None
        if i % 2 == 1:
            pair = f"ITM-{first + (i - 1) * 10:03d}..{first + i * 10 + 9:03d}"
        item_batch(ph, b, pair, pair)


def balance_reviews(ph, ranges):
    for r in ranges:
        ph.add("secondary", f"Balance review {r}", "P7e + §12.6 anti-exploit rules; /balance-check", ["economy", "items"], [
            D(f"{r}: /balance-check", [f"Run `/balance-check` on {r}", "Compare against the itemization bible tiers", "Return outliers to primary with numbers"], f"{r} balance notes filed"),
        ], ["Set bonus breaks the damage curve"], f"production/reviews/{ph.pl}/balance.md")


def monthly_secondary(ph, months):
    for (y, m) in months:
        lab = dt.date(y, m, 1).strftime("%Y-%m")
        ph.add("secondary", f"Sprint planning and production review {lab}", "§14 operating rhythm: monthly review, risk register, energy check",
               ["team", "docs", "business"], [
            D(f"{lab}: sprint plan and risk register", [f"Run `/sprint-status` on last month, then `/sprint-plan` for {lab} across all 6 streams",
                                                         "Update the risk register (§13) and the burnout/energy line",
                                                         "Compare measured days per unit with this phase's templates; note drift"],
              f"{lab} sprint plan committed in production/sprints/"),
        ], ["A stream overbooked by more than 10%"], f"production/sprints/{lab}.md", anchor=D8(y, m, 1))
        ph.add("secondary", f"External playtest {lab}", "§14 weekly playable build; P2/P6 fairness, P7f timing fairness",
               ["fun", "tests", "team"], [
            D(f"{lab}: playtest session and report", [f"Run the {lab} playtest with 3-5 testers on the latest build",
                                                       "Collect fairness ratings for deaths on Hard/Hell and 'did you notice the time' answers",
                                                       "Write it up with `/playtest-report` and file the top 5 issues"],
              f"production/playtests/{lab}.md written"),
        ], ["Tester runs an old build"], f"production/playtests/{lab}.md", anchor=D8(y, m, 15))


def monthly_qa(ph, months):
    for (y, m) in months:
        lab = dt.date(y, m, 1).strftime("%Y-%m")
        ph.add("qa", f"Sprint QA plan and regression {lab}", "§7 DoD: no open critical/high; CI tests stay green",
               ["tests", "team"], [
            D(f"{lab}: /qa-plan and regression sweep", [f"Run `/qa-plan` for the {lab} sprint stories",
                                                         "Run `/regression-suite` and `/smoke-check` on the sprint build",
                                                         "Run `/test-evidence-review` on stories closing this month"],
              f"{lab} QA plan and regression log filed"),
        ], ["Flaky test hides a regression"], f"production/qa/{ph.pl}/{lab}_regression.md", anchor=D8(y, m, 3))


def quarter_replan(ph, dates):
    for d in dates:
        lab = d.isoformat()
        ph.add("primary", f"Quarterly tech-debt and architecture review {lab}", "R7 one owner per concern; code quality feeding the quarterly re-plan ritual",
               ["architecture", "cleanup", "docs", "code"], [
            D(f"Quarter code review {lab}: debt register and ADRs", ["Run `/tech-debt` and rank the register by risk to the next region",
                                                                    "Run `/code-review` on the two systems that changed most this quarter",
                                                                    "Record any architecture change as an ADR with `/architecture-decision`",
                                                                    "Check the Godot pin (upgrade only at gates) and hand the debt list to the re-plan ritual"],
              f"Debt register and ADRs for {lab} committed"),
        ], ["Debt item blocks the next region"], f"docs/architecture/ + production/tech_debt/{lab}.md", anchor=d)


def team_onboarding(ph):
    ph.add("secondary", "Onboard the production team", "Team from Gate 3 (§6); key-person risk (§13)", ["team", "docs"], [
        D("Team onboarding: docs and access", ["Run `/onboard` for art lead/animator, composer/sound designer, writer and QA",
                                               "Walk through CLAUDE.md, AGENTS.md, art bible, VOICE_GUIDE.md and the test runners",
                                               "Set up repo access and LFS for each (no shared passwords; each person uses their own account)"],
          "Each team member has an onboarding doc and a working checkout"),
        D("Team onboarding: pipelines", ["Art lead imports one test sprite through the PAE importer",
                                         "Composer drops one stem set into the adaptive music manager",
                                         "Writer adds one `.dlg` scene that passes tests/dialogue_test.gd", "QA runs tests/run_phase0_tests.ps1"],
          "Every pipeline has been run once by its owner"),
        D("Team onboarding: review cadence", ["Agree the weekly review slot per stream and the Sunday integration build",
                                              "Define sign-off checklists per deliverable type", "Write `production/team/cadence.md`"],
          "Review cadence documented"),
    ], ["Contract IP assignment missing for a contributor (check before first commit)"], "production/team/cadence.md")
    for s, steps in {
        "art": ["Read the art bible and redraw one existing Oakhaven prop to calibrate", "Run the PAE importer on it and check pixel snap",
                "Review with the director"],
        "audio": ["Read the audio direction doc and the bus layout", "Re-mix one existing track's stems as a calibration",
                  "Review with the director"],
        "writing": ["Read STORY_BIBLE.md, VOICE_GUIDE.md and DIALOGUE_FORMAT.md", "Rewrite one bark pool in voice as a calibration",
                    "Run tests/dialogue_test.gd"],
        "qa": ["Read the test standards and the run_phase0_tests / run_screenshots runners", "Run the full suite and the screenshot tour",
               "Write the first bug with /bug-report as a calibration"],
    }.items():
        ph.add(s, f"Onboarding and calibration ({s})", "Team joins after Gate 3 (§6)", ["team", "docs"], [
            D(f"{ph.pid} {s} onboarding: tools and canon", steps, f"{s} owner calibrated on one real asset"),
            D(f"{ph.pid} {s} onboarding: pipeline dry run", [f"Ship one {s} deliverable end to end through review", "Note friction in the pipeline",
                                                            "Agree the definition of done for {s} deliverables".replace("{s}", s)],
              f"{s} pipeline dry run done"),
        ], ["Tool licence not available on the contributor's machine"], f"production/team/{s}_onboarding.md")


def milestone_close(ph, name, criteria, date):
    lab = name
    ph.add("primary", f"{lab}: technical close", f"ROADMAP §7/§10 {lab}", ["release", "tests", "save", "performance"], [
        D(f"{lab}: full test suite and coverage", ["Run gdUnit4 suite, reachability bot and all route tests on the release build",
                                                   "Run the bot over every storyline/timing branch available so far",
                                                   "Fix or record any red test"], f"{lab} suite green"),
        D(f"{lab}: save and performance proof", ["Load every historical save fixture", "Min-spec 60 fps capture in the busiest town",
                                                 "Export build with tools/export_windows.ps1 -Tour"], f"{lab} build exported and toured"),
        D(f"{lab}: evidence pack", [f"Collect evidence for: {criteria}", "Write the technical section of the milestone report",
                                    "Tag the build"], f"{lab} technical evidence in production/milestones/"),
    ], ["Tour screenshot differs from the last accepted baseline"], f"production/milestones/{ph.pl}/{low(lab)}.md", anchor=date)
    ph.add("secondary", f"{lab}: review and decision", f"ROADMAP §10 {lab}", ["release", "team", "business", "docs"], [
        D(f"{lab}: sign-offs and evidence index", [f"Collect art, audio, writing and QA sign-offs against: {criteria}",
                                                   "Build the evidence index (tests, live viewport screenshots, reports) for the gate ritual's `/gate-check`",
                                                   "List blockers with owners"], f"{lab} evidence index ready"),
        D(f"{lab}: decision record", ["Go / re-scope / pivot decision as an ADR", "Update the risk register and cut order status",
                                      "Plan the next phase's first sprint"], f"{lab} decision ADR committed"),
    ], ["Gate passed with a waived criterion not recorded"], f"docs/architecture/adr-{low(lab)}.md", anchor=date)
    ph.add("qa", f"{lab}: QA sign-off", f"ROADMAP §10 {lab}", ["tests", "release"], [
        D(f"{lab}: final bug triage", ["Run `/bug-triage`; confirm 0 critical/high open", "Run `/test-evidence-review` on all closed stories",
                                       "Write the QA section of the milestone report"], f"{lab} QA sign-off"),
    ], ["Unreproduced crash left open"], f"production/qa/{ph.pl}/{low(lab)}_signoff.md", anchor=date)


# =============================================================================================
# Y3
# =============================================================================================

def build_y3():
    # brief says 261 team days; the calendar has 260 weekdays in this window, so plan 260 (99.6%) to avoid carry-over
    cap = {"primary": 312, "secondary": 365, "art": 260, "audio": 260, "writing": 260, "qa": 260}
    ph = Phase("Y3", "Production I: Act 1 (R1 Oakhaven, R2 Ironhold)",
               "Act 1 (R1-R2) is shippable on all 5 difficulties with real art and audio, NPC sim v2, the full moveset and training-based stats (M3).",
               ["6 Act 1 bosses (R1-B01..R2-B03) each with a Hell-only phase; replay tests green",
                "40 side, 6 secret (10 time-sensitive) quests and SS-01..03 completable by the bot under fast/slow/out-of-order profiles",
                "25 Tier B NPCs, 3 Tier A, 3 companions, ~55 Tier C live on calendar schedules",
                "ITM-001..120 and COM-001..030 in ItemDB/market; 365-day economy sim within bounds",
                "AH-01, MG-01, MG-02, GMB-01 shipped and exploit-tested",
                "NPC sim v2 (factions, reputation, crime/witness, daily events), full moveset, training-based stat growth merged with tests",
                "R1 and R2 pass the §7 Definition of Done; M3 gate-check recorded on 2029-09-30"],
               D8(2028, 10, 1), D8(2029, 9, 30), cap)
    ph.blocks = [(D8(2029, 3, 31), ["kickoff", "systems", "R1", "R1-dod"], "R1"), (D8(2029, 9, 30), ["R2", "R2-dod", "close"], "R2")]
    ph.segment("kickoff")
    ph.add("primary", "Production kickoff: Act 1 plan and build pipeline", "§7 production rules; Gate 3 handoff", ["release", "tools", "team", "docs"], [
        D("Y3 kickoff: Act 1 epics and stories", ["Run `/create-epics` from the Act 1 GDDs and route table", "Run `/create-stories` for the first R1 epic",
                                                  "Check `/story-readiness` on the first sprint"], "Act 1 epics and first stories exist"),
        D("Y3 kickoff: CI for a team", ["Add branch protection and required checks (tests, lint, git diff --check)",
                                        "Add a nightly bot run with all timing profiles", "Add a per-PR export smoke via tools/export_windows.ps1"], "CI runs on every PR and nightly"),
        D("Y3 kickoff: content validation gates", ["Boot validation for quests, NPC schedules, items and dialogue keys in CI",
                                                   "Lint: no `paused =`/`time_scale =` outside ContextStack; no `create_timer` in gameplay",
                                                   "Document the content-add checklist for the team"], "Content gates fail CI on bad data"),
    ], ["Team member's PR bypasses checks"], "CI config + docs/production/content_checklist.md")
    team_onboarding(ph)
    ph.segment("systems")
    ph.add("primary", "NPC sim v2: factions, reputation, crime/witness, daily events", "§7 Y3 systems deepened; P4 + §12.3", ["npc", "systems", "ai", "time", "save", "tests"], [
        D("NPC sim v2: design and ADR", ["Run `/design-system` for `design/gdd/npc_sim_v2.md`: factions, reputation scale, crimes, witnesses, daily events",
                                          "Record the data model in an ADR via `/architecture-decision`", "List v1 behaviours that must not regress"], "npc_sim_v2.md reviewed; ADR committed"),
        D("NPC sim v2: faction data", ["Faction resources for Hearth Compact, Archive Covenant, Continuity League plus R1/R2 local factions",
                                       "Relations matrix and starting standings", "Load-time validation"], "Faction data loads"),
        D("NPC sim v2: reputation model", ["Per-faction and per-town reputation with event log", "Decay on the WorldClock", "Shop prices modified by reputation (§12.6)"], "Reputation changes prices in a test shop"),
        D("NPC sim v2: dialogue and bark selectors", ["Reputation bands exposed to dialogue conditions", "Bark selector reads band and time", "Unit tests for band edges"], "Barks change by band"),
        D("NPC sim v2: crime definitions", ["Crime list in data (finalized in the design doc)", "Severity and bounty values as tuning knobs", "Crime events through one bus"], "Crimes emit events"),
        D("NPC sim v2: witness perception", ["Sight cones and hearing radius per NPC tier", "Report delay on the WorldClock", "Witness memory fact written"], "Witnesses report after the delay"),
        D("NPC sim v2: consequences", ["Bounty, guard response, fine or jail, merchant refusal", "No consequence may block the main story; jail releases with a signposted cost",
                                       "Pay-off and reputation repair paths"], "Consequence loop works end to end"),
        D("NPC sim v2: daily events generator", ["Calendar events: market days, festivals, patrol changes", "Event → schedule overrides", "Seeded generation"], "Daily events alter schedules"),
        D("NPC sim v2: simulation LOD", ["Off-screen: schedule advance only", "Distant towns on a coarse tick", "Budget: N active NPCs per chunk"], "LOD within budget"),
        D("NPC sim v2: save block and migration", ["Serialize reputation, crimes, bounties, witness facts", "Migration test from the Y2 save version", "Corruption fallback"], "Save round-trips"),
        D("NPC sim v2: debug inspector", ["Inspector panel: NPC facts, schedule, reputation", "Time-scrub preview", "Team docs"], "Inspector usable by the team"),
        D("NPC sim v2: tests", ["`tests/unit/npc/test_reputation.gd`, `test_witness.gd`", "30-day headless soak in `tests/integration/npc/test_sim_v2_soak.gd`",
                                "Add to CI nightly"], "NPC sim v2 tests green"),
    ], ["Witness and victim are the same NPC", "Crime during a cutscene", "Reputation at both caps", "Save during a pending report"],
        "tests/unit/npc/*, tests/integration/npc/test_sim_v2_soak.gd")
    moves = [("ANM-P-04..06", "ground combo chain with cancel windows"), ("ANM-P-07..08", "aerial attack and pogo down-strike"),
             ("ANM-P-09..10", "parry and riposte (windows 12/9/6/4/2 from DifficultyProfile)"), ("ANM-P-11", "dodge (i-frames 18/15/12/10/8)"),
             ("ANM-P-15", "tool use slot"), ("ANM-P-16", "Root Access tactical slow-time via ContextStack time-scale request"),
             ("ANM-P-12..14", "hurt, death/respawn, heal (charges 5/4/3/2/1)"), ("ANM-P-17", "Data Vision scan (observation only)")]
    pdays = [D("Full moveset: plan against the combat bible", ["List every Act 1 move with its MoveData id and clip id ANM-P-01..18",
                                                               "Define cancel graph and hitstop tier per move", "Agree clip delivery order with the art lead"], "Moveset plan in design/gdd/moveset.md")]
    for ids, mv in moves:
        pdays.append(D(f"Full moveset: {mv}", [f"Implement {mv} as MoveData/AttackSpec `.tres` ({ids})", "State machine transitions on the fixed tick",
                                               "FeelService hitstop/shake/rumble per hit", f"Input-replay test for {ids}"], f"{ids} playable and replay-tested"))
    pdays += [
        D("Full moveset: input buffer and latency calibration", ["4-frame input buffer for jump, attack, parry, dodge", "Latency calibration screen in options",
                                                                  "Unit test buffer expiry on the fixed tick"], "Buffer and calibration shipped"),
        D("Full moveset: stats never change timing", ["Invariant test: parry/dodge windows identical at min and max stats", "Same for every item affix",
                                                       "Add to CI"], "Timing invariant test green"),
        D("Full moveset: tuning and balance", ["Run `/balance-check` on move damage", "Playtest Hard/Hell for fairness", "Commit tuning data"], "Moveset tuned"),
        D("Full moveset: integration tests", ["`tests/integration/combat/test_moveset_replay.gd` covering all moves", "Run on every difficulty",
                                              "Screenshot evidence"], "Moveset replay suite green"),
    ]
    ph.add("primary", "Full moveset (P2)", "§7 Y3 systems deepened: full moveset; §12.10", ["combat", "animation", "code", "tests"], pdays,
           ["Parry and dodge pressed on the same frame", "Pogo on a hazard tile", "Slow-time requested during hitstop (priority order)"], "tests/integration/combat/test_moveset_replay.gd")
    ph.add("primary", "Training-based stat growth (P7d)", "§7 Y3 systems deepened; §12.8", ["systems", "economy", "save", "tests"], [
        D("Stats: finalize the model", ["Finalize STR/AGI/VIT/INT/SPI/LCK (proposal in §12.8) in `design/gdd/stats.md`",
                                        "Growth sources: level points, training and use, choices, items/buffs", "Run `/design-review`"], "stats.md approved"),
        D("Stats: use counters", ["Count stat-relevant actions per stat", "Daily training caps to prevent grind exploits", "Unit tests"], "Use counters live"),
        D("Stats: growth curves", ["Curve data with diminishing returns", "Tuning knobs exposed in the difficulty tuning panel", "Graph in the debug view"], "Curves tunable"),
        D("Stats: trainers on the calendar", ["Trainer NPC sessions with cost and schedule", "Session minigame-free (pure time/cost)", "Integration with Tier B trainers"], "Trainers work"),
        D("Stats: derived stats stack", ["Damage, health, resources, crafting quality, haggling, gambling luck (small, capped)", "Modifier stack order documented", "Unit tests"], "Derived stats computed"),
        D("Stats: respec", ["Respec at a cost; UI context", "Refund rules for training gains", "Save and migration"], "Respec works and saves"),
        D("Stats: tests", ["`tests/unit/stats/test_growth.gd` and `test_timing_invariant.gd`", "Grind exploit test (cap holds)", "CI"], "Stat tests green"),
    ], ["Respec during a timed quest", "Training cap reset at midnight abused by rest"], "tests/unit/stats/*")
    clips_y3 = ([{"id": f"ANM-P-{i:02d}", "name": n, "days": d} for i, (n, d) in enumerate([
            ("side idle", 1), ("run", 1), ("jump and fall", 2), ("ground combo 1", 2), ("ground combo 2", 2), ("ground combo 3", 2),
            ("aerial attack", 2), ("pogo down-strike", 2), ("parry", 2), ("parry riposte", 2), ("dodge", 2), ("hurt", 1), ("death and respawn", 2),
            ("heal", 1), ("tool use", 2), ("Root Access cast", 2), ("Data Vision scan", 1), ("interact and pick up", 1)], 1)]
            + [{"id": f"ANM-TD-{i:02d}", "name": f"top-down 4-direction {n}", "days": 2} for i, n in enumerate(["idle", "walk", "run", "interact"], 1)])
    for c in clips_y3[:11]:
        player_clip(ph, c)
    ph.add("qa", "Moveset and stats test pass", "P2 + P7d", ["tests", "combat"], [
        D("Moveset QA: every move on every difficulty", ["Run each move's replay on all 5 profiles", "Manual cancel-window checks", "Log"], "Move cases logged"),
        D("Moveset QA: input devices", ["Keyboard, Xbox-style and PlayStation-style pads", "Latency calibration at 0/+2/+4", "Log"], "Device cases logged"),
        D("Stats QA: growth and respec", ["Train each stat to cap", "Respec; check refunds", "Timing invariant spot-check"], "Stats cases logged"),
    ], ["Buffered input survives a pause (should not)"], "production/qa/y3/moveset.md")
    tc = [0]
    # ---------------- R1
    ph.segment("R1")
    region_package(ph, region_spec("R1", 12))
    for e in [{"id": f"EN-{i:02d}", "reg": "R1", "arch": ARCH[i - 1]} for i in range(1, 8)]:
        enemy(ph, e)
    ph.add("secondary", "Encounter placement EN-01..07 (R1)", "P2 + §12.5 enemies visible in world", ["level", "combat"], [
        D("EN-01..04: patrol placement R1", ["Place EN-01..04 patrols in R1 chunk groups", "Aggro radius vs path width", "Playtest"], "EN-01..04 placed"),
        D("EN-05..07: patrol placement R1", ["Place EN-05..07 patrols", "Night-only spawns on the WorldClock", "Playtest"], "EN-05..07 placed"),
    ], ["Patrol blocks a quest giver"], "production/reviews/y3/encounters.md")
    ph.add("writing", "Bestiary EN-01..14", "§3 enemy types; codex", ["dialogue"], [
        D("Bestiary EN-01..07", [f"Codex entries for EN-01..07 (~{W(ph, 700)} words)", "Data Vision labels (a label is not an identity)", "Key strings"], "EN-01..07 entries in"),
        D("Bestiary EN-08..14", [f"Codex entries for EN-08..14 (~{W(ph, 700)} words)", "Cross-link regions", "Key strings"], "EN-08..14 entries in"),
    ], ["Codex spoils a boss"], "dialogue/codex/bestiary.dlg")
    ms = [("prologue/before_the_ground.dlg", "prologue"), ("ch1/crash_site.dlg", "crash site (missing passengers)"), ("ch1/elara_meeting.dlg", "Elara meeting"),
          ("ch1/elara_house.dlg", "Elara's house"), ("ch1/broken_mile.dlg", "Broken Mile"), ("ch1/oakhaven_gate.dlg", "Oakhaven gate (Bran's ledger)"),
          ("ch1/oakhaven_village.dlg", "village"), ("ch1/north_field.dlg", "north field / bridge timing"), ("ch1/aldric.dlg", "Aldric"),
          ("ch1/fragment_one.dlg", "Fragment One")]
    ph.add("writing", "Act 1 main-story final pass: prologue and Chapter 1", "P3 + §7 DoD; existing dialogue/ files are the base", ["dialogue", "story", "localization"], [
        D(f"Main-story pass `dialogue/{f}` ({nm})", [f"Final pass on `dialogue/{f}` against VOICE_GUIDE.md (~{W(ph, 600)} new/revised words)",
                                                    "Check every flag it writes against STORY_BIBLE §5 Chapter 1 table", "Key strings; run tests/dialogue_test.gd"], f"{f} final")
        for f, nm in ms], ["Revised line drops a flag write"], "dialogue/prologue, dialogue/ch1")
    ph.add("qa", "Act 1 main-story regression: Chapter 1", "R5 dialogue closes; C-items stay fixed", ["tests", "story"], [
        D("Chapter 1 route: every branch", ["Run tests/chapter1_route_test.gd", "Manual: kill/spare/purge Aldric branches", "Bridge saved/evacuated/fell"], "Ch1 branches pass"),
        D("Chapter 1: flags audit", ["Dump flags at Act 1 checkpoints", "Compare with STORY_BIBLE table", "File mismatches"], "Ch1 flags match"),
    ], ["Skip answers a choice (C13 regression)"], "production/qa/y3/ch1_regression.md")
    r1q = quest_roster("R1", 19, 3, {3, 7, 12, 15}, {2}, {"R1-SQ-02": ("SS-01", "A3"), "R1-SQ-06": ("SS-01", "A3"), "R1-SQ-11": ("SS-01", "A3"),
                                                           "R1-SQ-15": ("SS-02", "T")}, {3}, tc, 0)
    for q in r1q:
        quest(ph, q)
    side_storyline(ph, {"id": "SS-01", "regs": ["R1"], "feeds": "A3", "members": ["R1-SQ-02", "R1-SQ-06", "R1-SQ-11"]})
    for b in [{"id": "NPC-B-01..05", "reg": "R1", "ids": [f"NPC-B-{i:02d}" for i in range(1, 6)], "roles": "gate guard (NPC-B-01 = Bran), " + ROLES[0]},
              {"id": "NPC-B-06..10", "reg": "R1", "ids": [f"NPC-B-{i:02d}" for i in range(6, 11)], "roles": ROLES[1]}]:
        npc_b_batch(ph, b)
    tier_a(ph, {"id": "NPC-A-01", "reg": "R1", "name": "Mara Quill"})
    tier_a(ph, {"id": "NPC-A-02", "reg": "R1", "name": "Mira Chen, the Voice", "voice_only": True})
    companion(ph, {"id": "CMP-01", "name": "Elara Venn", "reg": "R1"})
    crowd(ph, {"id": "CRW-R1", "reg": "R1", "n": 25})
    for b in [boss for boss in []]:
        pass
    boss(ph, {"id": "R1-B01", "reg": "R1", "name": "Aldric Fen, the Tutorial Knight",
              "flags": "ch1_knight_killed / ch1_knight_spared / ch1_root_purge and source_key_fragment_1 downstream"})
    boss(ph, {"id": "R1-B02", "reg": "R1"})
    boss(ph, {"id": "R1-B03", "reg": "R1"})
    items_and_writing(ph, 1, 6, lambda b: "R1")
    commodity_batch(ph, {"id": "COM-001..010", "cat": COM_CATS[0]})
    commodity_batch(ph, {"id": "COM-011..020", "cat": COM_CATS[1]})
    balance_reviews(ph, ["ITM-001..030", "ITM-031..060"])
    minigame(ph, {"id": "MG-01", "reg": "R1", "kind": "fishing (§12.7 example)"})
    minigame(ph, {"id": "GMB-01", "reg": "R1", "kind": "dice game (§12.7 example)"}, gambling=True)
    for m in [("MUS-01", "R1 exploration, day"), ("MUS-02", "R1 exploration, night variant"), ("MUS-03", "R1 battle"), ("MUS-04", "Oakhaven town"),
              ("MUS-05", "Act 1 boss base theme (adaptive)")]:
        music_track(ph, {"id": m[0], "fn": m[1]})
    for i, dom in enumerate(["player moveset", "R1 enemies", "UI and menus", "NPC sim (crowd, crime, witness)", "R1 interactables and foley"], 1):
        sfx_batch(ph, {"id": f"SFX-batch-{i:02d}", "domain": dom}, f"SFX-batch-{i-1:02d}/{i:02d}" if i % 2 == 0 else None)
    cins1 = [("CIN-A1-01", "prologue: before the ground"), ("CIN-A1-02", "crash site: missing passengers"), ("CIN-A1-03", "Elara meeting"),
             ("CIN-A1-04", "Broken Mile: Data Vision and Root Access"), ("CIN-A1-05", "north bridge outcome (saved / evacuated / fell)"),
             ("CIN-A1-06", "Aldric decision (kill / spare / purge)"), ("CIN-A1-07", "Fragment One"), ("CIN-A1-08", "village meeting and Elara joins")]
    for i, (cid, beat) in enumerate(cins1):
        cinematic(ph, {"id": cid, "beat": beat, "reg": "R1"}, "CIN-A1-01..04" if i == 3 else ("CIN-A1-05..08" if i == 7 else None))
    ph.segment("R1-dod")
    region_dod(ph, "R1", "REL-Y3-1")
    # ---------------- R2
    ph.segment("R2")
    for c in clips_y3[11:]:
        player_clip(ph, c)
    region_package(ph, region_spec("R2", 14))
    for e in [{"id": f"EN-{i:02d}", "reg": "R2", "arch": ARCH[(i - 1) % len(ARCH)]} for i in range(8, 15)]:
        enemy(ph, e)
    ph.add("secondary", "Encounter placement EN-08..14 (R2)", "P2 + §12.5", ["level", "combat"], [
        D("EN-08..11: placement R2", ["Place EN-08..11 in R2 chunk groups and the Clock Tower", "One-way floor checks (C5/C6 stay fixed)", "Playtest"], "EN-08..11 placed"),
        D("EN-12..14: placement R2", ["Place EN-12..14 in the Underground and roads", "Convoy-route patrols", "Playtest"], "EN-12..14 placed"),
    ], ["Enemy spawns inside a one-way floor"], "production/reviews/y3/encounters.md")
    ms2 = [("ch2/ironhold_arrival.dlg", "Ironhold arrival"), ("ch2/ironhold_city.dlg", "Ironhold city"), ("ch2/command_hall.dlg", "Command Hall"),
           ("ch2/arena.dlg", "arena brackets"), ("ch2/clock_tower.dlg", "Clock Tower"), ("ch2/underground.dlg", "Underground"),
           ("ch2/administrator_proxy.dlg", "Administrator Proxy"), ("ch2/fragment_two.dlg", "Fragment Two"), ("ch2/act1_end.dlg", "Act 1 end card")]
    ph.add("writing", "Act 1 main-story final pass: Chapter 2", "P3 + §7 DoD", ["dialogue", "story", "localization"], [
        D(f"Main-story pass `dialogue/{f}` ({nm})", [f"Final pass on `dialogue/{f}` against VOICE_GUIDE.md (~{W(ph, 600)} words)",
                                                    "Check flags against STORY_BIBLE §5 Chapter 2 table (medicine timing, Wraith choice, report, pace)",
                                                    "Key strings; run tests/dialogue_test.gd"], f"{f} final") for f, nm in ms2]
        + [D("Act 1 pace and timing variants", [f"Write act1_pace_early/_on_time/_late arrival variants (~{W(ph, 700)} words)",
                                                 "Medicine convoy early/on-time/late reactions", "Dialogue test"], "Pace variants in")],
        ["Pace variant contradicts the medicine timing flag"], "dialogue/ch2")
    ph.add("qa", "Act 1 main-story regression: Chapter 2", "R5; §12.4 timing fairness", ["tests", "story", "time"], [
        D("Chapter 2 route: every branch", ["Run tests/chapter2_route_test.gd", "Wraith restored/destroyed/absorbed", "Seraphina recruited/stayed/rejected"], "Ch2 branches pass"),
        D("Chapter 2: medicine timing", ["Early/on-time/late runs", "Warning at the tower gate appears", "Signposts per STORY_BIBLE timing table"], "Medicine timing verified"),
    ], ["Bell stops while in a menu"], "production/qa/y3/ch2_regression.md")
    r2q = quest_roster("R2", 21, 3, {2, 6, 11, 16}, {3}, {"R2-SQ-03": ("SS-02", "T"), "R2-SQ-08": ("SS-02", "T"), "R2-SQ-05": ("SS-03", "A2"),
                                                           "R2-SQ-10": ("SS-03", "A2"), "R2-SQ-14": ("SS-03", "A2"), "R2-SQ-17": ("SS-03", "A2")}, {1}, tc, 4)
    for q in r2q:
        quest(ph, q)
    side_storyline(ph, {"id": "SS-02", "regs": ["R1", "R2"], "feeds": "T", "members": ["R1-SQ-15", "R2-SQ-03", "R2-SQ-08"],
                        "note": " (Act 1 pace value)"})
    side_storyline(ph, {"id": "SS-03", "regs": ["R2"], "feeds": "A2", "members": ["R2-SQ-05", "R2-SQ-10", "R2-SQ-14", "R2-SQ-17"]})
    for b in [{"id": "NPC-B-11..15", "reg": "R2", "ids": [f"NPC-B-{i:02d}" for i in range(11, 16)], "roles": "medicine runner (NPC-B-11 = Rem), " + ROLES[2]},
              {"id": "NPC-B-16..20", "reg": "R2", "ids": [f"NPC-B-{i:02d}" for i in range(16, 21)], "roles": ROLES[1]},
              {"id": "NPC-B-21..25", "reg": "R2", "ids": [f"NPC-B-{i:02d}" for i in range(21, 26)], "roles": ROLES[3]}]:
        npc_b_batch(ph, b)
    tier_a(ph, {"id": "NPC-A-03", "reg": "R2", "name": "Ironhold Tier A slot (candidate Brask; confirm in the world bible)"})
    companion(ph, {"id": "CMP-02", "name": "Seraphina Vale", "reg": "R2"})
    companion(ph, {"id": "CMP-03", "name": "third Act 1 slot per the Y2 world bible", "reg": "R2"})
    crowd(ph, {"id": "CRW-R2", "reg": "R2", "n": 30})
    boss(ph, {"id": "R2-B01", "reg": "R2", "name": "Clockwork Automaton", "flags": "ch2_clockwork_automaton_defeated / ch2_clock_tower_complete"})
    boss(ph, {"id": "R2-B02", "reg": "R2", "name": "Data Wraith", "flags": "ch2_data_wraith_restored / _destroyed / _absorbed (+ _defeated)"})
    boss(ph, {"id": "R2-B03", "reg": "R2", "name": "Administrator Proxy", "flags": "ch2_administrator_proxy_defeated / source_key_fragment_2"})
    items_and_writing(ph, 61, 6, lambda b: "R2", 6)
    commodity_batch(ph, {"id": "COM-021..030", "cat": COM_CATS[2]})
    balance_reviews(ph, ["ITM-061..090", "ITM-091..120"])
    auction_house(ph, {"id": "AH-01", "reg": "R2"})
    minigame(ph, {"id": "MG-02", "reg": "R2", "kind": "forge/crafting timing game (§12.7 example)"})
    for m in [("MUS-06", "R2 exploration"), ("MUS-07", "Ironhold city"), ("MUS-08", "R2 battle"), ("MUS-09", "Clock Tower and Underground"),
              ("MUS-10", "auction house"), ("MUS-11", "tavern / gambling loop")]:
        music_track(ph, {"id": m[0], "fn": m[1]})
    for i, dom in enumerate(["R2 enemies", "Act 1 bosses shared layer", "market and auction", "minigames and gambling", "R2 interactables and foley"], 6):
        sfx_batch(ph, {"id": f"SFX-batch-{i:02d}", "domain": dom}, f"SFX-batch-{i-1:02d}/{i:02d}" if i % 2 == 0 else None)
    cins2 = [("CIN-A1-09", "convoy on the road: Seraphina met"), ("CIN-A1-10", "Ironhold gate"), ("CIN-A1-11", "Command Hall disclosure"),
             ("CIN-A1-12", "the wall: Seraphina's count"), ("CIN-A1-13", "Clock Tower bell stops"), ("CIN-A1-14", "Underground: the missing shift"),
             ("CIN-A1-15", "Fragment Two and Seraphina decides"), ("CIN-A1-16", "Act 1 card: report and pace")]
    for i, (cid, beat) in enumerate(cins2):
        cinematic(ph, {"id": cid, "beat": beat, "reg": "R2"}, "CIN-A1-09..12" if i == 3 else ("CIN-A1-13..16" if i == 7 else None))
    ph.segment("R2-dod")
    region_dod(ph, "R2", "REL-Y3-2")
    ph.segment("close")
    milestone_close(ph, "M3 Act 1 shippable", "Act 1 shippable on all 5 difficulties; DoD for R1 and R2; bot coverage incl. time-skip", D8(2029, 9, 24))
    # recurring
    monthly_secondary(ph, [(2028, m) for m in (10, 11, 12)] + [(2029, m) for m in range(1, 10)])
    monthly_qa(ph, [(2028, m) for m in (11, 12)] + [(2029, m) for m in range(1, 10)])
    quarter_replan(ph, [D8(2029, 1, 2), D8(2029, 4, 2), D8(2029, 7, 2)])
    # pools (assigned to the R1/R2 segments so polish lands inside the vertical slices)
    ph.segment("R2")
    add_pools(ph, ["R1", "R2"], ["NPC sim v2", "moveset and FeelService", "stats model", "quest/timing pipeline", "economy and auction"],
              ["training and stats screen", "auction bid screen", "quest log with deadlines", "map and fast travel"])
    ph.word_target = 90000
    return ph


# =============================================================================================
# Y4
# =============================================================================================

def ea_tasks(ph):
    pre = D8(2030, 1, 20)
    ph.add("primary", "Early Access build readiness", "§7 Y4: Early Access ~2030-03-15 with Act 1 + R3; R4 (EA-U1) and R5 (EA-U2) follow as EA updates before Gate 4", ["release", "save", "performance", "code"], [
        D("EA readiness: release branch and feature flags", ["Create the EA release branch policy (trunk + release tags)", "Feature-flag unfinished R4/R5 content out of the EA build",
                                                             "Version stamp in build and save header"], "EA build excludes unfinished content"),
        D("EA readiness: save compatibility guarantee", ["Fixture saves from every internal release since Y3 in `tests/fixtures/saves/`", "CI loads and migrates every fixture",
                                                         "Gate 4 target: saves migrate across every patch"], "All fixtures migrate in CI"),
        D("EA readiness: crash reporting (opt-in)", ["Opt-in crash reporter with symbol upload", "Privacy note for what is collected (check current rules)", "Test crash path"], "Crash report received from a test crash"),
        D("EA readiness: telemetry (opt-in)", ["Events for retention, economy sources/sinks, deaths per boss, timing profile", "Off by default; consent screen", "Dashboard queries"], "Telemetry visible on the dashboard"),
        D("EA readiness: performance and min spec", ["`/perf-profile` on Acts 1 and R3", "60 fps min spec; fix top offenders", "Record min-spec numbers for the store page"], "Min-spec numbers recorded"),
        D("EA readiness: Steam build pipeline", ["Depot config and build upload script around tools/export_windows.ps1 (check current Steamworks docs)",
                                                 "Branch for beta testers", "Dry-run upload to a private branch"], "Private-branch build installs and runs"),
        D("EA readiness: release candidate soak", ["24-hour soak of the RC", "Fix leaks found", "Run `/release-checklist`"], "RC passes the release checklist"),
    ], ["Save from a feature-flagged area loaded in EA build", "Telemetry sends before consent"], "production/release/ea/readiness.md", anchor=pre)
    ph.add("secondary", "Early Access launch preparation", "§7 Y4 Early Access; marketing, legal, business", ["release", "marketing", "legal", "business"], [
        D("EA prep: scope and roadmap", ["Write what EA contains: Act 1 + R3 at launch, then R4 (EA-U1) and R5 (EA-U2) as content updates before Gate 4; publish that roadmap", "Your decision: price and EA duration (no numbers invented here)", "Record as an ADR"], "EA scope ADR"),
        D("EA prep: store page", ["Update Steam page for EA (check current Steam EA rules and questions)", "Screenshots from live viewport evidence only", "Capsule art review"], "Store page draft ready"),
        D("EA prep: legal", ["AI-content disclosure accurate for PAE/AI-assisted assets (check current rules)", "Simulated gambling: check current rating and regional rules", "EULA/privacy text for telemetry"], "Legal checklist filled"),
        D("EA prep: trailer direction", ["Shot list from the build", "Direct capture with art and audio", "Cut review"], "EA trailer cut approved"),
        D("EA prep: press kit and community", ["Press kit page", "Discord EA channels and bug-report template", "Community guidelines"], "Press kit and channels live"),
        D("EA prep: /launch-checklist", ["Run `/launch-checklist`", "Assign owners per item", "Go/no-go date set"], "Launch checklist owned"),
    ], ["Store text promises unbuilt content"], "production/release/ea/launch_checklist.md", anchor=pre)
    ph.add("art", "Early Access marketing art", "§7 Y4 EA", ["art", "marketing"], [
        D("EA art: capsule and header", ["Draw capsule/header art in the required sizes (check current Steam specs)", "Logo lockup", "Review"], "Capsules delivered"),
        D("EA art: screenshots", ["Stage 10 screenshots in live builds", "No mock-ups", "Archive with evidence"], "Screenshots delivered"),
        D("EA art: trailer captures", ["Capture trailer shots from the shot list", "Clean UI variants", "Hand to edit"], "Trailer shots delivered"),
    ], ["Screenshot shows content flagged out of EA"], "production/release/ea/art/", anchor=pre)
    ph.add("audio", "Early Access trailer audio", "§7 Y4 EA", ["audio", "marketing"], [
        D("EA audio: trailer edit", ["Trailer music edit from existing tracks", "SFX sweeten", "Loudness for web"], "Trailer audio final"),
        D("EA audio: launch mix check", ["Full Act 1 mix check", "Fix masking", "Sign off"], "Launch mix signed"),
    ], ["Licensed sample without provenance record"], "production/release/ea/audio/", anchor=pre)
    ph.add("writing", "Early Access text", "§7 Y4 EA", ["dialogue", "marketing", "release"], [
        D("EA text: store copy", [f"Store description and EA answers (~{W(ph, 800)} words)", "No promises beyond the roadmap ADR", "Loc for Simplified Chinese hand-off"], "Store copy final"),
        D("EA text: in-game EA notice", ["Title-screen EA notice and roadmap text", "Feedback-link text", "Key strings"], "EA notice in"),
        D("EA text: FAQ and known issues", ["FAQ page", "Known-issues list", "Patch notes template"], "FAQ published after review"),
    ], ["FAQ contradicts store page"], "production/release/ea/text/", anchor=pre)
    ph.add("qa", "Early Access certification-style pass", "§7 Y4 EA; Gate 4 crash-free ≥ 99.5%", ["tests", "release", "performance"], [
        D("EA QA: full Act 1 playthrough x3 difficulties", ["Beginner, Medium, Hell full runs", "Log softlocks (target 0)", "File bugs"], "Act 1 runs logged"),
        D("EA QA: R3 slice playthrough", ["Full R3 slice on Medium", "Feature flags hide R4/R5", "Log"], "R3 slice run logged"),
        D("EA QA: install and hardware matrix", ["Clean install on 3 machines incl. min spec", "Steam Deck check", "Controller matrix"], "Matrix logged"),
        D("EA QA: save migration", ["Load every fixture", "Play 30 minutes on a migrated save", "Log"], "Migration verified"),
        D("EA QA: soak", ["`/soak-test` 8 hours", "Memory and frame time", "Log"], "Soak clean"),
        D("EA QA: go/no-go", ["Run `/smoke-check` on the RC", "Bug triage: 0 critical/high", "Sign"], "QA go"),
    ], ["Crash on first launch without a controller"], "production/qa/y4/ea_cert.md", anchor=pre)
    # launch days
    launch = D8(2030, 3, 14)
    ph.add("primary", "Early Access launch days (war room)", "§7 Y4 EA ~2030-03-15", ["release", "code"], [
        D("EA launch day -1: final build", ["Upload the signed-off RC to the default branch (do not publish until you say go)", "Verify install from Steam", "Prepare hotfix branch"], "Build staged"),
        D("EA launch day: war room", ["Watch crash reports and Discord", "Triage incoming bugs every 2 hours", "Hotfix only critical"], "Launch day log"),
        D("EA launch day +1: hotfix EA-H01", ["Fix top crash/blocker", "Save migration test", "Release EA-H01 after QA smoke"], "EA-H01 shipped"),
        D("EA launch day +2: stabilization", ["Second triage pass", "Crash-free rate from dashboard", "Plan EA-P01"], "Stabilization note"),
    ], ["Hotfix breaks old saves"], "production/release/ea/launch_log.md", anchor=launch)
    ph.add("secondary", "Early Access launch days (comms)", "§7 Y4 EA", ["release", "marketing", "business"], [
        D("EA launch: publish and announce", ["Publish when you say go", "Announcement post and devlog", "Pin known issues"], "EA live"),
        D("EA launch +1: community triage", ["Read reviews and Discord", "Tag issues for triage", "Reply with known-issue links"], "Community digest"),
        D("EA launch +2: retrospective", ["Launch retrospective with the team", "Update risk register", "Plan comms cadence"], "Launch retro filed"),
    ], ["Review bombing over a misunderstanding"], "production/release/ea/comms.md", anchor=launch)
    ph.add("qa", "Early Access launch days (live QA)", "§7 Y4 EA", ["tests", "release"], [
        D("EA launch: live smoke", ["Install from Steam and smoke", "Repro top player reports", "Log"], "Live smoke logged"),
        D("EA launch +1: hotfix verification", ["Verify EA-H01", "Save migration check", "Sign"], "EA-H01 verified"),
    ], ["Repro only on non-English OS locale"], "production/qa/y4/ea_launch.md", anchor=launch)
    # patch cadence
    for i, d in enumerate([D8(2030, 4, 15), D8(2030, 5, 15), D8(2030, 6, 15), D8(2030, 7, 15), D8(2030, 8, 15), D8(2030, 9, 8)], 1):
        pid = f"EA-P{i:02d}"
        ph.add("primary", f"Early Access patch {pid}", "Gate 4: exploit turnaround ≤ 1 patch; saves migrate across every patch", ["release", "code", "save", "economy"], [
            D(f"{pid}: triage and fixes", ["Run `/bug-triage` on EA reports", "Fix top crashes and any open economy exploit (≤ 1 patch rule)", "Regression tests per fix"], f"{pid} fixes merged"),
            D(f"{pid}: migration and release", [f"Add `SaveService.migrate` step for {pid} with fixture", "Export, upload to beta branch, QA smoke", "Release after your go"], f"{pid} released"),
        ], ["Exploit fix invalidates items players already own"], f"tests/unit/save/test_migration_{low(pid)}.gd", anchor=d)
        ph.add("secondary", f"Patch notes and comms {pid}", "§7 Y4 EA cadence", ["release", "marketing"], [
            D(f"{pid}: /patch-notes and community", ["Run `/patch-notes` from the changelog", "Post after review", "Read crash-free and retention dashboards (record, do not invent)"], f"{pid} notes published"),
        ], ["Notes omit a balance change"], f"production/release/ea/{low(pid)}.md", anchor=d)
        ph.add("qa", f"Patch verification {pid}", "Gate 4 save migration 100%", ["tests", "release", "save"], [
            D(f"{pid}: regression and migration", ["`/regression-suite` + `/smoke-check`", "Load every save fixture", "Verify each fixed bug"], f"{pid} verified"),
        ], ["Patch reintroduces a fixed exploit"], f"production/qa/y4/{low(pid)}.md", anchor=d)


def build_y4():
    cap = {"primary": 313, "secondary": 365, "art": 261, "audio": 261, "writing": 261, "qa": 261}
    ph = Phase("Y4", "Production II: Act 2 (R3-R5) and Early Access",
               "Act 2 (R3-R5) is built to the Definition of Done, Early Access has launched (~2030-03-15) with a steady patch cadence, and Gate 4 health criteria are measured.",
               ["9 Act 2 bosses (R3-B01..R5-B03) with Hell phases and green replay tests",
                "50 side, 10 secret (12 time-sensitive) quests and SS-04..07 completable by the bot",
                "25 Tier B (NPC-B-26..50), 3 Tier A, 3 companions (CMP-04..06), ~70 Tier C",
                "ITM-121..270, COM-031..070, AH-02, AH-03 and limited-edition calendar v1 live; economy sim stable",
                "Companion synergies, market agents at scale, adaptive music at scale merged with tests",
                "Early Access launched; EA-H01 and EA-P01..P06 shipped with save migration each",
                "Gate 4 on 2030-09-30: review/retention targets read from real data, crash-free ≥ 99.5%, save migration 100%, exploit turnaround ≤ 1 patch"],
               D8(2029, 10, 1), D8(2030, 9, 30), cap)
    ph.lean = True  # three regions in one year: compressed templates (flagged as a risk)
    ph.blocks = [(D8(2030, 1, 31), ["kickoff", "systems", "R3", "R3-dod"], "R3"), (D8(2030, 6, 15), ["R4", "R4-dod"], "R4"),
                 (D8(2030, 9, 30), ["R5", "R5-dod", "close"], "R5")]
    ph.segment("kickoff")
    ph.add("primary", "Y4 kickoff: Act 2 epics and EA plan", "§7 Y4", ["release", "docs", "team"], [
        D("Y4 kickoff: Act 2 epics and EA technical plan", ["Run `/create-epics` for R3-R5 from the GDDs and the route table; stories for R3 sprint 1",
                                                            "List EA blockers: feature flags, crash reporting, telemetry, depots, migration fixtures",
                                                            "Schedule them against 2030-03-15 and record the plan as an ADR"], "Act 2 epics and the EA technical plan ADR exist"),
    ], ["EA date slips: decide what moves, not crunch"], "docs/architecture/adr-ea-plan.md")
    ph.segment("systems")
    ph.add("primary", "Companion synergies", "§7 Y4 systems deepened", ["combat", "npc", "systems", "tests"], [
        D("Synergies: design", ["`/design-system` for `design/gdd/companion_synergies.md`: pair effects for CMP-01..06", "Synergy is data (SynergyDef), never a companion command menu (STORY_BIBLE rule)", "Run `/design-review`"], "companion_synergies.md approved"),
        D("Synergies: data model", ["SynergyDef `.tres`: pair, trigger, effect, cooldown", "Relationship gate", "Validation"], "SynergyDef loads"),
        D("Synergies: triggers in combat", ["Trigger on parry/pogo/Root Access events", "Respect hitstop priority", "FeelService"], "Synergies trigger"),
        D("Synergies: overworld effects", ["Traversal or discovery synergies", "No invisible walls", "Bot reachability"], "Overworld synergies work"),
        D("Synergies: balance", ["`/balance-check` against Hell", "No timing window changes", "Tune"], "Synergy balance noted"),
        D("Synergies: save", ["Unlocked synergies saved", "Migration test", "Load mid-fight checkpoint"], "Synergy saves round-trip"),
        D("Synergies: tests", ["`tests/integration/companions/test_synergies.gd`", "Replay with synergies", "CI"], "Synergy tests green"),
    ], ["Synergy fires with a companion who just left", "Two synergies same frame"], "tests/integration/companions/test_synergies.gd")
    ph.add("primary", "Market agents at scale", "§7 Y4 systems deepened; §12.6", ["economy", "ai", "performance", "tests"], [
        D("Market agents: scale plan", ["Set target agent counts for R1-R5 markets", "Coarse tick for markets outside the player's region", "Record as an ADR"], "Market-agent scale ADR committed"),
        D("Market agents: trader roles", ["Gatherer, merchant and collector behaviours for R3-R5 commodities COM-031..070", "Inter-region trade routes between AH-01..03 cities", "Validate role data at boot"], "Trader roles cover R1-R5"),
        D("Market agents: performance", ["Batch agent updates; profile with all 5 regions loaded", "Set a ms-per-tick budget for the market sim", "Fix the top offender"], "Market sim within its ms budget"),
        D("Market agents: price stability", ["Price = base + seasonality(calendar) + demand + noise (§12.6) across 5 regions", "Clamp rules per commodity class", "365-day headless sim"], "R1-R5 prices stay inside clamps for 365 days"),
        D("Market agents: exploit probes", ["Arbitrage between R1-R5 markets", "Auction sniping caps with NPC bidders", "Fix any loop and add a regression test"], "No cross-region loop found"),
        D("Market agents: dashboard and tests", ["Economy dashboard: per-region price history and sources/sinks", "`tests/integration/economy/test_agents_scale.gd` with the 365-day sim in CI", "Team docs"], "Dashboard updated and agent tests green"),
    ], ["All agents buy the same commodity on market day"], "tests/integration/economy/test_agents_scale.gd")
    ph.add("primary", "Adaptive music at scale (engine side)", "§7 Y4 systems deepened; P9", ["audio", "music", "systems", "code"], [
        D("Adaptive music: state model", ["States per region: explore / tension / combat / boss / day / night", "Transition rules at bar lines in the music manager", "Record as an ADR"], "Adaptive music ADR committed"),
        D("Adaptive music: streaming and memory", ["Stream stems per chunk group", "Set a memory budget for loaded stems", "Profile a fast-travel chain"], "Stem streaming within the memory budget"),
        D("Adaptive music: event hooks and tests", ["Hooks from boss phases, dynamic events and festivals with priority rules", "Unit test transitions and pause/resume sync", "Add to CI"], "Hooks fire and music tests green"),
    ], ["Two transitions requested in one bar"], "tests/unit/audio/test_adaptive_music.gd")
    ph.add("primary", "Limited-edition calendar v1", "§7 Y4; §12.6 limited editions", ["economy", "time", "items", "tests"], [
        D("LE calendar: data model", ["LE-01..LE-16 entries: date window, place, stock, auction-only flag", "Signpost rules (announced before release)", "Validation"], "LE data loads"),
        D("LE calendar: release logic", ["Stock and sell-out on the WorldClock", "Auction-only lots into AH-01..03", "Missable but signposted"], "LE releases work"),
        D("LE calendar: save, migration and tests", ["Save stock and purchase records with a migration test", "`tests/integration/economy/test_le_calendar.gd`: bot visits each LE on time and late; load across a release date", "Add to CI"], "LE save round-trips and LE tests green"),
    ], ["LE date falls on a day the player is jailed"], "tests/integration/economy/test_le_calendar.gd")
    ph.add("secondary", "Limited-edition calendar v1 design", "§12.6", ["economy", "time", "level"], [
        D("LE calendar: festival map", ["Map LE-01..LE-16 to festivals/market days across R1-R5", "Signposting plan", "Review with economy rules"], "Calendar drafted"),
        D("LE calendar: review", ["Play a 28-day month with LEs", "Check nothing story-critical is LE-only", "Sign off"], "Calendar approved"),
    ], ["Two LEs same day in different regions"], "design/gdd/le_calendar_v1.md")
    ph.add("audio", "Adaptive music at scale (content side)", "§7 Y4; P9", ["music", "audio"], [
        D("Adaptive retrofit: MUS-01..05", ["Re-stem MUS-01..05 for the new state model", "Bar-line transitions", "Implement"], "MUS-01..05 retrofitted"),
        D("Adaptive retrofit: MUS-06..11", ["Re-stem MUS-06..11", "Festival variants", "Implement"], "MUS-06..11 retrofitted"),
        D("Adaptive retrofit: review", ["Play Act 1 for transitions", "Fix seams", "Sign off"], "Retrofit signed"),
    ], ["Old stems out of tempo grid"], "production/audio/music_register.md")
    ph.add("qa", "Y4 systems QA (synergies, agents, LE calendar)", "§7 Y4", ["tests", "economy"], [
        D("Systems QA: synergies", ["Every pair synergy", "Hell replay unaffected", "Log"], "Synergy cases"),
        D("Systems QA: market agents", ["Cross-region arbitrage hunt", "Market-day spikes", "Log"], "Agent cases"),
        D("Systems QA: LE calendar", ["Each LE early/on time/late", "Signpost before release", "Log"], "LE cases"),
    ], ["LE sold out before player could know"], "production/qa/y4/systems.md")
    ph.add("writing", "Limited-edition and synergy text", "§12.6; companion synergies", ["dialogue", "items"], [
        D("LE text: announcements", [f"Announcement and signpost lines for LE-01..LE-16 (~{W(ph, 900)} words)", "Notice boards and merchants", "Key strings"], "LE text in"),
        D("Synergy text: pair barks", [f"Pair barks for CMP-01..06 synergies (~{W(ph, 900)} words)", "Rotation pools", "Key strings"], "Synergy barks in"),
    ], ["Announcement leaks a secret quest"], "dialogue/economy/le_calendar.dlg")
    for c in [{"id": f"ANM-P-{i:02d}", "name": n, "days": 2 if i % 2 else 1} for i, n in enumerate(
            ["synergy strike A", "synergy strike B", "synergy traversal", "companion-assisted pogo", "Root Access chain cast", "tool variant 2",
             "heavy charge attack", "finisher"], 19)]:
        player_clip(ph, c)
    ea_tasks(ph)
    tc = [0]
    regs = [("R3", 12, 17, 3, {2, 6, 10, 14}, set(), {"R3-SQ-03": ("SS-04", "A1"), "R3-SQ-07": ("SS-04", "A1"), "R3-SQ-12": ("SS-04", "A1"),
                                                                     "R3-SQ-09": ("SS-05", "A2"), "R3-SQ-15": ("SS-05", "A2")}, {2}, 15, 26, 35, "CMP"),
            ("R4", 12, 17, 4, {3, 8, 13}, {4}, {"R4-SQ-02": ("SS-05", "A2"), "R4-SQ-05": ("SS-06", "A3"), "R4-SQ-10": ("SS-06", "A3"),
                                                 "R4-SQ-14": ("SS-06", "A3")}, {1, 3}, 20, 36, 45, None),
            ("R5", 12, 16, 3, {1, 5, 9, 12}, set(), {"R5-SQ-04": ("SS-07", "T"), "R5-SQ-08": ("SS-07", "T"), "R5-SQ-13": ("SS-07", "T")}, set(), 25, 46, 50, None)]
    en = 15
    itm = 121
    mus = 12
    sfx = 11
    cin = 1
    bosses_done = 0
    for ri, (reg, ng, nsq, nsec, ts_side, ts_sec, ssm, hidden, en_start, nb_lo, nb_hi, _) in enumerate(regs):
        rname = REG[reg][0]
        ph.segment(reg)
        region_package(ph, region_spec(reg, ng))
        n_en = 6 if reg == "R3" else 5
        for i in range(en, en + n_en):
            enemy(ph, {"id": f"EN-{i:02d}", "reg": reg, "arch": ARCH[(i - 1) % len(ARCH)]})
        ph.add("secondary", f"Encounter placement EN-{en:02d}..{en + n_en - 1:02d} ({reg})", "P2 + §12.5", ["level", "combat"], [
            D(f"EN-{en:02d}..{en + n_en - 1:02d}: placement {reg}", [f"Place EN-{en:02d}..{en + n_en - 1:02d} in {rname} chunk groups", "Day/night spawn rules on the WorldClock", "Playtest each patrol once"], f"EN-{en:02d}..{en + n_en - 1:02d} placed in {reg}"),
        ], ["Patrol overlaps a dynamic event area"], "production/reviews/y4/encounters.md")
        ph.add("writing", f"Bestiary EN-{en:02d}..{en + n_en - 1:02d}", "§3 enemy types; codex", ["dialogue"], [
            D(f"Bestiary EN-{en:02d}..{en + n_en - 1:02d}", [f"Codex entries for EN-{en:02d}..{en + n_en - 1:02d} (~{W(ph, 600)} words)", "Data Vision labels (a label is not an identity)", "Key strings"], f"EN-{en:02d}..{en + n_en - 1:02d} codex entries in"),
        ], ["Codex spoils a boss"], "dialogue/codex/bestiary.dlg")
        en += n_en
        for q in quest_roster(reg, nsq, nsec, ts_side, ts_sec, ssm, hidden, tc, ri * 3):
            quest(ph, q)
        if reg == "R3":
            side_storyline(ph, {"id": "SS-04", "regs": ["R3"], "feeds": "A1", "members": ["R3-SQ-03", "R3-SQ-07", "R3-SQ-12"]})
        if reg == "R4":
            side_storyline(ph, {"id": "SS-05", "regs": ["R3", "R4"], "feeds": "A2", "members": ["R3-SQ-09", "R3-SQ-15", "R4-SQ-02"],
                                "note": " (Flight 707 manifest arc seeded in Ch2, STORY_BIBLE §5)"})
            side_storyline(ph, {"id": "SS-06", "regs": ["R4"], "feeds": "A3", "members": ["R4-SQ-05", "R4-SQ-10", "R4-SQ-14"]})
        if reg == "R5":
            side_storyline(ph, {"id": "SS-07", "regs": ["R5"], "feeds": "T", "members": ["R5-SQ-04", "R5-SQ-08", "R5-SQ-13"], "note": " (Act 2 pace value)"})
        for lo in range(nb_lo, nb_hi + 1, 5):
            npc_b_batch(ph, {"id": f"NPC-B-{lo:02d}..{lo + 4:02d}", "reg": reg, "ids": [f"NPC-B-{i:02d}" for i in range(lo, lo + 5)],
                             "roles": ROLES[(lo // 5) % len(ROLES)]})
        tier_a(ph, {"id": f"NPC-A-{4 + ri:02d}", "reg": reg, "name": f"{reg} Tier A slot per the Y2 world bible"})
        if reg == "R3":
            companion(ph, {"id": "CMP-04", "name": "Lyra Sen", "reg": "R3"})
            companion(ph, {"id": "CMP-05", "name": "Kaelthas Marr", "reg": "R3"})
        if reg == "R4":
            companion(ph, {"id": "CMP-06", "name": "Act 2 slot (Nema Orr or Rook Damar, decided when Act 2 is built)", "reg": "R4"})
        crowd(ph, {"id": f"CRW-{reg}", "reg": reg, "n": 25 if reg != "R5" else 20})
        for b in range(1, 4):
            boss(ph, {"id": f"{reg}-B0{b}", "reg": reg})
        items_and_writing(ph, itm, 5, lambda b, r=reg: r, ri * 5)
        balance_reviews(ph, [f"ITM-{itm:03d}..{itm + 49:03d}"])
        itm += 50
        for k in range(ri, 4, 3):
            pass
        com_ranges = {"R3": ["COM-031..040", "COM-041..050"], "R4": ["COM-051..060"], "R5": ["COM-061..070"]}[reg]
        for ci, cr in enumerate(com_ranges):
            commodity_batch(ph, {"id": cr, "cat": COM_CATS[(3 + ri * 2 + ci) % len(COM_CATS)]})
        if reg == "R4":
            auction_house(ph, {"id": "AH-02", "reg": "R4"})
        if reg == "R5":
            auction_house(ph, {"id": "AH-03", "reg": "R5"})
        fns = {"R3": ["R3 exploration", "R3 battle", "R3 ruins/dungeon", "Act 2 boss base theme"],
               "R4": ["R4 exploration", "Mirror City streets", "R4 battle", "AH-02 / AH-03 auction variant", "festival / limited-edition day"],
               "R5": ["R5 exploration", "Cathedral Server interior", "R5 battle", "Act 2 finale"]}[reg]
        for fn in fns:
            music_track(ph, {"id": f"MUS-{mus:02d}", "fn": fn})
            mus += 1
        doms = {"R3": ["R3 enemies", "R3 interactables and foley", "companion synergies", "Act 2 bosses shared layer"],
                "R4": ["R4 enemies", "R4 interactables and foley", "auction AH-02/AH-03 and LE releases", "dynamic events"],
                "R5": ["R5 enemies", "R5 interactables and foley", "UI and EA-era polish"]}[reg]
        for dom in doms:
            sfx_batch(ph, {"id": f"SFX-batch-{sfx:02d}", "domain": dom}, f"SFX-batch-{sfx-1:02d}/{sfx:02d}" if sfx % 2 == 0 else None)
            sfx += 1
        for k in range(4):
            cid = f"CIN-A2-{cin:02d}"
            cinematic(ph, {"id": cid, "beat": f"Act 2 beat {cin:02d} in {rname} (per story/outlines Act 2 outline)", "reg": reg},
                      f"CIN-A2-{cin - 3:02d}..{cin:02d}" if k == 3 else None)
            cin += 1
        ph.segment(f"{reg}-dod")
        region_dod(ph, reg, {"R3": "EA-0.1", "R4": "EA-U1", "R5": "EA-U2"}[reg])
    ph.segment("close")
    milestone_close(ph, "Gate 4 Early Access health", "review/retention targets (set by you, read from data), crash-free ≥ 99.5%, saves migrate across every patch, no economy exploit open > 1 patch", D8(2030, 9, 23))
    monthly_secondary(ph, [(2029, m) for m in (10, 11, 12)] + [(2030, m) for m in range(1, 10)])
    monthly_qa(ph, [(2029, m) for m in (10, 11, 12)] + [(2030, m) for m in range(1, 10)])
    quarter_replan(ph, [D8(2030, 1, 2), D8(2030, 4, 2), D8(2030, 7, 2)])
    ph.segment("R4")
    add_pools(ph, ["R3", "R4", "R5"], ["companion synergies", "market agents", "adaptive music", "EA telemetry and crash pipeline", "limited-edition calendar"],
              ["companion and synergy screen", "market price history", "EA feedback and options", "auction listing screen"])
    ph.word_target = 120000
    return ph


# =============================================================================================
# Y5
# =============================================================================================

def build_y5():
    cap = {"primary": 313, "secondary": 365, "art": 261, "audio": 261, "writing": 261, "qa": 261}
    ph = Phase("Y5", "Production III: Act 3 branches A/B/C (R6-R7)",
               "Act 3's three branches across R6-R7 are playable end to end with NPC sim v3, route-specific market events, the 4th auction house and all minigames and gambling games (M5).",
               ["6 Act 3 bosses (R6-B01..R7-B03) with Hell phases and replay tests green",
                "45 side, 8 secret (10 time-sensitive) quests and SS-08..10 completable by the bot on each branch",
                "20 Tier B (NPC-B-51..70), 3 Tier A, CMP-07 and CMP-08 live",
                "ITM-271..390, COM-071..100, AH-04, MG-03..05, GMB-02..03 shipped and exploit-tested",
                "NPC sim v3: towns R1-R7 change per route and per elapsed time; route-specific market events live",
                "R6 and R7 pass the §7 Definition of Done",
                "M5: the bot plays branches A, B and C end to end on fast/slow/out-of-order profiles"],
               D8(2030, 10, 1), D8(2031, 9, 30), cap)
    ph.blocks = [(D8(2031, 3, 31), ["kickoff", "systems", "R6", "R6-dod"], "R6"), (D8(2031, 9, 30), ["R7", "R7-dod", "close"], "R7")]
    ph.segment("kickoff")
    ph.add("primary", "Y5 kickoff: Act 3 branch epics", "§7 Y5", ["docs", "story", "team"], [
        D("Y5 kickoff: branch epics", ["`/create-epics` for Act 3 branches A/B/C from the route table", "Shared vs branch-only content list", "Story readiness"], "Branch epics exist"),
        D("Y5 kickoff: branch test harness", ["Bot entry points that start Act 3 on branch A, B or C from fixture saves", "Nightly job per branch", "CI"], "Branch harness in CI"),
    ], ["Fixture save from Y4 no longer migrates"], "tests/fixtures/saves/act3_*")
    ph.segment("systems")
    pdays = [D("NPC sim v3: design", ["`/design-system` for `design/gdd/npc_sim_v3.md`: town state = f(route, elapsed time)", "State matrix towns R1-R7 × branch A/B/C × pace", "ADR"], "v3 design approved")]
    for reg in ["R1", "R2", "R3", "R4", "R5", "R6", "R7"]:
        pdays.append(D(f"NPC sim v3: {reg} {REG[reg][0]} town states", [f"Author {reg} town state deltas per branch A/B/C (schedules, shops, crowd mood)",
                                                                       f"Elapsed-time stages for {reg} (early/on-time/late arrival)", "Unit test state selection"], f"{reg} states selectable"))
    pdays += [
        D("NPC sim v3: transitions without pop-in", ["State changes apply off-screen or at rest", "Signpost visible changes", "Test"], "No visible pop-in"),
        D("NPC sim v3: save and migration", ["Town state block saved", "Migration from Y4 saves", "Fixture tests"], "Saves migrate"),
        D("NPC sim v3: performance", ["Profile the 7-town sim (R1-R7) with v3 state deltas", "Coarse tick for distant towns", "Fix the top offender"], "7-town sim within budget"),
        D("NPC sim v3: tests", ["`tests/integration/npc/test_sim_v3_states.gd` all branch × pace combos", "Nightly", "Evidence"], "v3 tests green"),
    ]
    ph.add("primary", "NPC sim v3: towns change per route and per elapsed time", "§7 Y5 systems deepened; P4/P7f", ["npc", "systems", "time", "save", "tests"], pdays,
           ["Branch switch impossible but save edited", "Town state when Story+ later reopens"], "tests/integration/npc/test_sim_v3_states.gd")
    pdays = [D("Route market events: design", ["Write `design/gdd/route_market_events.md`: MKT-EV-A/B/C-01..03 per branch", "Economy bounds per event", "Run `/design-review`"], "route_market_events.md approved")]
    for br in "ABC":
        for k in (1, 2, 3):
            pdays.append(D(f"Market event MKT-EV-{br}-0{k}", [f"Implement MKT-EV-{br}-0{k} (branch {br}) on the WorldClock: affected commodities and duration",
                                                              "Signpost through notice boards", "Economy sim with the event"], f"MKT-EV-{br}-0{k} live"))
    pdays.append(D("Route market events: tests", ["`tests/integration/economy/test_route_events.gd`", "365-day sim per branch", "CI"], "Event tests green"))
    ph.add("primary", "Route-specific market events", "§7 Y5 systems deepened; §12.6", ["economy", "time", "systems", "tests"], pdays,
           ["Two events stack on one commodity"], "tests/integration/economy/test_route_events.gd")
    ph.add("secondary", "Act 3 branch structure direction", "§12.2 Act 3 [A|B|C]", ["story", "level", "docs"], [
        D("Branch map: shared vs branch content", ["Map every R6/R7 unit to shared/A/B/C", "Check each branch has ≥ 3 changed scenes (P3 rule)", "Review with the writer"], "Branch map approved"),
        D("Branch map: town-state review", ["Review NPC sim v3 state matrix", "Visible changes list", "Sign off"], "Town states approved"),
        D("Branch map: market events review", ["Review MKT-EV-A/B/C-01..03", "Signposting", "Sign off"], "Events approved"),
    ], ["A branch with no unique boss or scene"], "design/act3_branch_map.md")
    ph.add("writing", "Town-state and market-event text (v3)", "§7 Y5", ["dialogue", "npc", "economy"], [
        D(f"Town-state barks R1-R3 per branch", [f"Branch/pace reaction barks for R1-R3 towns (~{W(ph, 1200)} words)", "Keyed by state", "Key strings"], "R1-R3 barks in"),
        D(f"Town-state barks R4-R5 per branch", [f"Branch/pace barks for R4-R5 (~{W(ph, 1000)} words)", "Keyed by state", "Key strings"], "R4-R5 barks in"),
        D(f"Town-state barks R6-R7 per branch", [f"Branch/pace barks for R6-R7 (~{W(ph, 1000)} words)", "Keyed by state", "Key strings"], "R6-R7 barks in"),
        D("Market-event notices", [f"Notices for MKT-EV-A/B/C-01..03 (~{W(ph, 700)} words)", "Merchant lines", "Key strings"], "Notices in"),
    ], ["Bark references a town state from another branch"], "dialogue/world/v3/")
    ph.add("art", "Town-state art deltas (NPC sim v3)", "§7 Y5", ["art", "openworld"], [
        D("Town deltas: R1-R2", ["Branch-specific props/decals for Oakhaven and Ironhold", "Swap sets", "Import"], "R1-R2 deltas in"),
        D("Town deltas: R3-R5", ["Branch props for R3-R5 towns", "Swap sets", "Import"], "R3-R5 deltas in"),
        D("Town deltas: R6-R7", ["Branch props for R6-R7", "Swap sets", "Import"], "R6-R7 deltas in"),
        D("Town deltas: review", ["Screenshot each town × branch", "Director review", "Fix"], "Deltas approved"),
    ], ["Delta prop blocks a path"], "production/qa/evidence/y5/town_states/")
    ph.add("audio", "Town-state audio deltas (NPC sim v3) and market-event stingers", "§7 Y5; P9 reactive world", ["audio", "npc"], [
        D("Town audio deltas: R1-R2", ["Branch A/B/C ambience and crowd-mood variants for Oakhaven and Ironhold", "Elapsed-time stage variants", "Implement on town state"], "R1-R2 audio deltas in"),
        D("Town audio deltas: R3-R5", ["Branch variants for R3-R5 towns", "Elapsed-time stage variants", "Implement"], "R3-R5 audio deltas in"),
        D("Town audio deltas: R6-R7", ["Branch variants for R6-R7", "Elapsed-time stage variants", "Implement"], "R6-R7 audio deltas in"),
        D("Market-event stingers MKT-EV-A/B/C", ["Stingers and crier calls for the 9 route market events", "Notice-board read SFX", "Implement"], "Event stingers in"),
        D("Town audio deltas: review", ["Visit each town on A/B/C fixtures", "Mix check", "Director sign-off"], "Town audio deltas approved"),
    ], ["Ambience reverts after load"], "assets/audio/ambience/v3/")
    ph.add("qa", "NPC sim v3 and market events QA", "§7 Y5", ["tests", "npc", "economy"], [
        D("v3 QA: towns per branch", ["Visit each town on A, B, C fixtures", "Check deltas and barks", "Log"], "Branch towns logged"),
        D("v3 QA: elapsed time", ["Early/on-time/late arrival fixtures", "Check stages", "Log"], "Time stages logged"),
        D("v3 QA: market events", ["Trigger each MKT-EV", "Arbitrage hunt", "Log"], "Event cases logged"),
    ], ["Town state reverts after load"], "production/qa/y5/sim_v3.md")
    for c in [{"id": f"ANM-P-{i:02d}", "name": n, "days": 2} for i, n in enumerate(
            ["branch ability A", "branch ability B", "branch ability C", "traversal unlock move", "underwater/memory-current movement", "Root Access widened cast", "corruption-desync variant"], 27)]:
        player_clip(ph, c)
    tc = [0]
    en = 31
    itm = 271
    mus = 25
    sfx = 22
    regs = [("R6", 14, 22, 4, {2, 7, 12, 17}, {1}, {"R6-SQ-03": ("SS-08", "A1"), "R6-SQ-09": ("SS-08", "A1"), "R6-SQ-15": ("SS-08", "A1"),
                                                     "R6-SQ-18": ("SS-10", "A3")}, {2, 4}, 51, 60),
            ("R7", 14, 23, 4, {3, 8, 13, 18}, {2}, {"R7-SQ-04": ("SS-09", "A2"), "R7-SQ-10": ("SS-09", "A2"), "R7-SQ-16": ("SS-09", "A2"),
                                                     "R7-SQ-06": ("SS-10", "A3"), "R7-SQ-12": ("SS-10", "A3")}, {3}, 61, 70)]
    bmap = {"R6": [("R6-B01", "shared"), ("R6-B02", "branch A"), ("R6-B03", "branch B")],
            "R7": [("R7-B01", "branch C"), ("R7-B02", "shared"), ("R7-B03", "shared convergence")]}
    for ri, (reg, ng, nsq, nsec, ts_side, ts_sec, ssm, hidden, nb_lo, nb_hi) in enumerate(regs):
        rname = REG[reg][0]
        ph.segment(reg)
        region_package(ph, region_spec(reg, ng))
        for i in range(en, en + 6):
            enemy(ph, {"id": f"EN-{i:02d}", "reg": reg, "arch": ARCH[(i + 3) % len(ARCH)]})
        ph.add("secondary", f"Encounter placement EN-{en:02d}..{en + 5:02d} ({reg})", "P2 + §12.5", ["level", "combat"], [
            D(f"EN-{en:02d}..{en + 2:02d}: placement {reg}", [f"Place EN-{en:02d}..{en + 2:02d} in shared {rname} chunk groups", "Day/night rules", "Playtest"], f"EN-{en:02d}..{en + 2:02d} placed"),
            D(f"EN-{en + 3:02d}..{en + 5:02d}: placement {reg} per branch", [f"Branch-specific patrols for EN-{en + 3:02d}..{en + 5:02d}", "Check each branch A/B/C has fights", "Playtest"], f"EN-{en + 3:02d}..{en + 5:02d} placed"),
        ], ["Branch-only enemy appears on the wrong branch"], "production/reviews/y5/encounters.md")
        ph.add("writing", f"Bestiary EN-{en:02d}..{en + 5:02d}", "§3 enemy types; codex", ["dialogue"], [
            D(f"Bestiary EN-{en:02d}..{en + 5:02d}", [f"Codex entries for EN-{en:02d}..{en + 5:02d} (~{W(ph, 600)} words)", "Data Vision labels", "Key strings"], f"EN-{en:02d}..{en + 5:02d} codex entries in"),
        ], ["Codex spoils a branch"], "dialogue/codex/bestiary.dlg")
        en += 6
        for q in quest_roster(reg, nsq, nsec, ts_side, ts_sec, ssm, hidden, tc, 2 + ri * 5):
            quest(ph, q)
        if reg == "R6":
            side_storyline(ph, {"id": "SS-08", "regs": ["R6"], "feeds": "A1", "members": ["R6-SQ-03", "R6-SQ-09", "R6-SQ-15"]})
        else:
            side_storyline(ph, {"id": "SS-09", "regs": ["R7"], "feeds": "A2", "members": ["R7-SQ-04", "R7-SQ-10", "R7-SQ-16"]})
            side_storyline(ph, {"id": "SS-10", "regs": ["R6", "R7"], "feeds": "A3", "members": ["R6-SQ-18", "R7-SQ-06", "R7-SQ-12"]})
        for lo in range(nb_lo, nb_hi + 1, 5):
            npc_b_batch(ph, {"id": f"NPC-B-{lo:02d}..{lo + 4:02d}", "reg": reg, "ids": [f"NPC-B-{i:02d}" for i in range(lo, lo + 5)],
                             "roles": ROLES[(lo // 5 + 1) % len(ROLES)]})
        tier_a(ph, {"id": f"NPC-A-{7 + ri:02d}", "reg": reg, "name": f"{reg} Tier A slot per the Y2 world bible"})
        if reg == "R7":
            tier_a(ph, {"id": "NPC-A-09", "reg": reg, "name": "Act 3 cross-branch Tier A slot per the Y2 world bible"})
        companion(ph, {"id": f"CMP-0{7 + ri}", "name": ("backlog slot (candidate Kaito Aram, per world bible)" if ri == 0
                                                         else "backlog slot (candidate Unit 734 'Seven', per world bible)"), "reg": reg})
        crowd(ph, {"id": f"CRW-{reg}", "reg": reg, "n": 25})
        for bid, br in bmap[reg]:
            boss(ph, {"id": bid, "reg": reg, "name": f"{br}; branch assignment provisional per route table"})
        items_and_writing(ph, itm, 6, lambda b, r=reg: r, 2 + ri * 6)
        balance_reviews(ph, [f"ITM-{itm:03d}..{itm + 29:03d}", f"ITM-{itm + 30:03d}..{itm + 59:03d}"])
        itm += 60
        for cr in ({"R6": ["COM-071..080", "COM-081..090"], "R7": ["COM-091..100"]}[reg]):
            commodity_batch(ph, {"id": cr, "cat": COM_CATS[(int(cr[4:7]) // 10) % len(COM_CATS)]})
        if reg == "R6":
            minigame(ph, {"id": "MG-03", "reg": "R6", "kind": "Root Access hacking puzzle (§12.7 example)"})
            minigame(ph, {"id": "GMB-02", "reg": "R6", "kind": "card game (§12.7 example)"}, gambling=True)
        else:
            auction_house(ph, {"id": "AH-04", "reg": "R7"})
            minigame(ph, {"id": "MG-04", "reg": "R7", "kind": "courier run, time-sensitive (§12.7 example)"})
            minigame(ph, {"id": "MG-05", "reg": "R7", "kind": "festival rhythm game (§12.7 example)"})
            minigame(ph, {"id": "GMB-03", "reg": "R7", "kind": "betting on arena fights (§12.7 example)"}, gambling=True)
        fns = {"R6": ["R6 exploration", "R6 battle", "branch A theme layer", "branch B theme layer", "Memory Ocean depths", "Act 3 boss base theme"],
               "R7": ["R7 exploration", "Saved Assembly hall", "branch C theme layer", "R7 battle", "Act 3 convergence"]}[reg]
        for fn in fns:
            music_track(ph, {"id": f"MUS-{mus:02d}", "fn": fn})
            mus += 1
        doms = {"R6": ["R6 enemies", "R6 interactables and foley", "MG-03 and GMB-02", "Act 3 bosses shared layer", "branch A/B events"],
                "R7": ["R7 enemies", "R7 interactables and foley", "AH-04, MG-04, MG-05, GMB-03", "branch C events and convergence"]}[reg]
        for dom in doms:
            sfx_batch(ph, {"id": f"SFX-batch-{sfx:02d}", "domain": dom}, f"SFX-batch-{sfx-1:02d}/{sfx:02d}" if sfx % 2 == 0 else None)
            sfx += 1
        cl = {"R6": [("CIN-A3-S-01", "Act 3 opening (shared)"), ("CIN-A3-S-02", "branch split (shared)"), ("CIN-A3-A-01", "branch A beat 1"),
                     ("CIN-A3-A-02", "branch A beat 2"), ("CIN-A3-B-01", "branch B beat 1"), ("CIN-A3-B-02", "branch B beat 2"),
                     ("CIN-A3-A-03", "branch A beat 3"), ("CIN-A3-B-03", "branch B beat 3")],
              "R7": [("CIN-A3-C-01", "branch C beat 1"), ("CIN-A3-C-02", "branch C beat 2"), ("CIN-A3-C-03", "branch C beat 3"),
                     ("CIN-A3-A-04", "branch A Act 3 end"), ("CIN-A3-B-04", "branch B Act 3 end"), ("CIN-A3-C-04", "branch C Act 3 end"),
                     ("CIN-A3-S-03", "convergence toward Act 4 (shared)"), ("CIN-A3-S-04", "Act 3 card: pace and axis summary")]}[reg]
        for k, (cid, beat) in enumerate(cl):
            cinematic(ph, {"id": cid, "beat": f"{beat} in {rname} (per the Act 3 outline)", "reg": reg},
                      f"{cl[k-3][0]}..{cid}" if k % 4 == 3 else None)
        ph.segment(f"{reg}-dod")
        region_dod(ph, reg, {"R6": "REL-Y5-1", "R7": "REL-Y5-2"}[reg])
    ph.segment("close")
    ph.add("qa", "M5 branch runs A/B/C", "§7 M5 all branches end to end", ["tests", "story", "time"], [
        D("M5: branch A full run", ["Act 1 → Act 3 end on branch A, Medium", "Fast timing profile", "Log"], "Branch A run"),
        D("M5: branch B full run", ["Branch B, Hard", "Slow timing profile", "Log"], "Branch B run"),
        D("M5: branch C full run", ["Branch C, Beginner", "Out-of-order profile", "Log"], "Branch C run"),
    ], ["Branch locked by a missed secret"], "production/qa/y5/m5_runs.md", anchor=D8(2031, 9, 8))
    milestone_close(ph, "M5 all branches playable", "branches A, B, C end to end; R6-R7 DoD; NPC sim v3 + route events; all minigames and gambling shipped", D8(2031, 9, 22))
    monthly_secondary(ph, [(2030, m) for m in (10, 11, 12)] + [(2031, m) for m in range(1, 10)])
    monthly_qa(ph, [(2030, m) for m in (10, 11, 12)] + [(2031, m) for m in range(1, 10)])
    quarter_replan(ph, [D8(2031, 1, 2), D8(2031, 4, 2), D8(2031, 7, 2)])
    for i, d in enumerate([D8(2030, 11, 15), D8(2031, 1, 15), D8(2031, 3, 15), D8(2031, 5, 15), D8(2031, 7, 15)], 7):
        pid = f"EA-P{i:02d}"
        ph.add("primary", f"Early Access patch {pid}", "EA cadence continues; saves migrate across every patch", ["release", "save", "code"], [
            D(f"{pid}: fixes and migration", ["`/bug-triage` of EA reports; fix top issues", f"`SaveService.migrate` step for {pid} + fixture", "Release after QA and your go"], f"{pid} released"),
        ], ["Fix changes a field an older save relies on"], f"tests/unit/save/test_migration_{low(pid)}.gd", anchor=d)
        ph.add("qa", f"Patch verification {pid}", "Save migration 100%", ["tests", "release"], [
            D(f"{pid}: verification", ["`/regression-suite` + `/smoke-check`", "Every save fixture", "Verify fixes"], f"{pid} verified"),
        ], ["Regression in an Act 1 boss"], f"production/qa/y5/{low(pid)}.md", anchor=d)
        ph.add("secondary", f"Patch notes {pid}", "EA cadence", ["release", "marketing"], [
            D(f"{pid}: notes and comms", ["`/patch-notes`", "Post after review", "Record dashboard numbers as read"], f"{pid} notes out"),
        ], ["Notes mention a branch spoiler"], f"production/release/ea/{low(pid)}.md", anchor=d)
    ph.segment("R7")
    add_pools(ph, ["R6", "R7"], ["NPC sim v3", "route market events", "branch harness and bot", "minigame framework", "auction houses (4)"],
              ["minigame hub and records", "card and betting tables", "branch summary / journal", "world map with town states"])
    ph.word_target = 110000
    return ph


# =============================================================================================
# Y6
# =============================================================================================

FAM = {"A": "Sole Authority (Kaelen alone)", "B": "Bound Authority (Kaelen under audited rules)", "C": "No Authority (root abolished)"}
FAC = {1: "Hearth Compact", 2: "Archive Covenant", 3: "Continuity League"}
DEL = {1: "restore", 2: "release", 3: "choose"}
SECRET_ENDINGS = [("END-S-WP", "Consent / Witness Protocol"), ("END-S-FW", "First Wake"), ("END-S-CR", "Crownless")]
SP_CASES = ["Toma", "Asha", "Sera Fen", "Hush-4", "Vale", "Meri", "Kera", "Taren"]


def final_boss(ph, bid, name, why, phases, design_q):
    il = low(bid)
    ev = ph.ev(bid)
    pdays = [
        D(f"{bid} {name}: design doc", [f"Run `/design-system` for `design/gdd/bosses/{il}.md`", f"Settle the design question: {design_q}",
                                         "Phase list: " + "; ".join(phases), "Run `/design-review`"], f"{il}.md approved"),
        D(f"{bid} {name}: frame data", [f"AttackSpec `.tres` for every {name} attack under `resources/combat/bosses/{il}/`", "BossDef and PhaseDef per phase",
                                         f"Unit test `tests/unit/bosses/test_{il}_frame_data.gd`"], f"{bid} frame data green"),
    ]
    for p in phases:
        pdays.append(D(f"{bid} {name}: {p} AI", [f"Implement {p} states on the fixed tick in `scripts/combat/bosses/{il}_ai.gd`", "Seeded pattern selection",
                                                  "Phase-transition invariants (HP, poise, buffs)", "Debug overlay for the phase"], f"{bid} {p} playable"))
    pdays += [
        D(f"{bid} {name}: arena", [f"{name} arena from the Root of Heaven terrain context", "Hazards and kill zone on named layers", "Return-to-world rules (Story+ follows the ending)"], f"{bid} arena builds"),
        D(f"{bid} {name}: ending composer hook", ["Fight outcome → composer inputs (axes, companions, timing flags)", "No outcome lost on retry or load", "Golden-output test"], f"{bid} outcome reaches the composer"),
        D(f"{bid} {name}: difficulty data", ["Five DifficultyProfiles plus the Hell-only phase", "Healing charges and DDA rules", "Rewards via `grant_once`"], f"{bid} profiles wired"),
        D(f"{bid} {name}: replay tests", [f"`tests/integration/bosses/test_{il}_replay.gd` per phase", "One-frame-off loses on Hell", "Retry invariants"], f"{bid} replays green"),
        D(f"{bid} {name}: integration", ["World trigger, cinematics and save checkpoints", "Run `/smoke-check`", f"Evidence to {ev}"], f"{bid} integrated end to end"),
    ]
    ph.add("primary", f"Build final boss {bid} ({name})", why, ["combat", "ai", "difficulty", "story", "tests"], pdays,
           ["Retry after a family-specific phase", "Pause during the composer hand-off", "Load a pre-fight save from an older patch"], f"tests/integration/bosses/test_{il}_replay.gd")
    ph.add("secondary", f"Direct final boss {bid} ({name})", why, ["level", "cinematics", "story"], [
        D(f"{bid}: arena and approach", [f"Lay out the approach to {name} and its last checkpoint", "Signpost the point of no return (Story+ reopens the world)", "Playtest the walk-back"], f"{bid} approach approved"),
        D(f"{bid}: cinematic direction", [f"Storyboard CIN-{bid}-IN/OUT", "Per-family variants of the outro", "Brief art, audio and writing"], f"CIN-{bid} shot lists out"),
        D(f"{bid}: phase readability review", [f"Play each {name} phase", "Check telegraph readability in colourblind and high-contrast modes", "Return numbered notes"], f"{bid} readability notes filed"),
        D(f"{bid}: sign-off", ["Medium and Hell runs on the release build", "Mix and art review in the fight", f"Sign off in production/reviews/y6/{il}.md"], f"{bid} signed off"),
    ], ["Point of no return not signposted"], f"production/reviews/y6/{il}.md")
    adays = [D(f"{bid}: turnaround and palette", [f"Draw the {name} turnaround and palette", "Scale and silhouette check in the arena", "Director approval"], f"{bid} turnaround approved")]
    for p in phases:
        adays.append(D(f"{bid}: {p} animation", [f"Animate {name} {p} attacks and idle", "Tag active frames to AttackSpec names", "Import and run the frame-data test"], f"{bid} {p} animated"))
    adays += [D(f"{bid}: VFX", [f"Telegraph and impact VFX for {name}", "Stay inside the particle budget", "Shape cues, not colour only"], f"{bid} VFX in"),
              D(f"{bid}: cinematic keyframes", [f"Keyframes for CIN-{bid}-IN/OUT variants", "Stage in the timeline", "Director review"], f"{bid} keyframes in")]
    ph.add("art", f"Animate final boss {bid} ({name})", why, ["art", "animation", "vfx"], adays, ["Phase visuals too similar"], f"{ev}")
    ph.add("audio", f"Score final boss {bid} ({name})", why, ["music", "audio"], [
        D(f"{bid}: theme and stems", [f"{name} theme with per-phase stems", "Hell intensity layer", "Bounce to assets/audio/music/bosses/"], f"{bid} stems bounced"),
        D(f"{bid}: per-family variations", ["Variations for the family-specific phases", "Bar-line transitions between phases", "Implement"], f"{bid} variations in"),
        D(f"{bid}: SFX", [f"Telegraph SFX per {name} attack", "Impacts and phase stingers", "Implement"], f"{bid} SFX in"),
        D(f"{bid}: mix", ["Fight mix with telegraphs on top", "Cinematic sound pass", "Director sign-off"], f"{bid} mix signed"),
    ], ["Telegraph masked by a dense music layer"], "assets/audio/music/bosses/")
    ph.add("writing", f"Write final boss {bid} ({name})", why, ["dialogue", "story"], [
        D(f"{bid}: voice study", [f"Re-read STORY_BIBLE §2 and VOICE_GUIDE.md for {name}", "List what it must never say", "Director approval"], f"{bid} voice notes approved"),
        D(f"{bid}: intro scene", [f"Write the {name} intro in `dialogue/bosses/{il}.dlg` (~{W(ph, 900)} words)", "Branch on route and companions", "Run tests/dialogue_test.gd"], f"{bid} intro drafted"),
        D(f"{bid}: phase lines", [f"Phase and retry lines (~{W(ph, 900)} words)", "Per-family variants", "Key strings"], f"{bid} phase lines in"),
        D(f"{bid}: outro scenes", [f"Outro per ending family (~{W(ph, 1000)} words)", "Hand-off lines into the composer", "Run tests/dialogue_test.gd"], f"{bid} outros drafted"),
        D(f"{bid}: revision", ["Revise against VOICE_GUIDE.md", "Translator notes", "Hand to QA"], f"{bid} text final"),
    ], ["Line implies SOVEREIGN would kill Kaelen (canon: it never does)"], f"dialogue/bosses/{il}.dlg")
    ph.add("qa", f"Test final boss {bid} ({name})", why, ["tests", "difficulty", "combat"], [
        D(f"{bid}: Beginner/Easy", [f"3 runs each of {name} on Beginner and Easy", "Check DDA engages", "Log deaths and causes"], f"{bid} Beginner/Easy logged"),
        D(f"{bid}: Medium/Hard", [f"3 runs each of {name} on Medium and Hard", "Check the +variants appear", "Log"], f"{bid} Medium/Hard logged"),
        D(f"{bid}: Hell replay", [f"Run test_{il}_replay.gd on the release build", "Manual Hell run with latency calibration at 0 and +2", "Log fairness notes"], f"{bid} Hell validated"),
        D(f"{bid}: per-family phases", ["Load one fixture per ending family", "Check each family phase appears", "Check the composer receives the outcome"], f"{bid} family phases verified"),
    ], ["Wrong family phase on a Bound route"], f"production/qa/y6/{il}.md")


def build_y6():
    cap = {"primary": 314, "secondary": 366, "art": 262, "audio": 262, "writing": 262, "qa": 262}
    ph = Phase("Y6", "Production IV: R8, Act 4, all endings, Story+ (Alpha)",
               "R8 and Act 4 are complete, SOVEREIGN and the God King ship with Hell phases, all 27 endings play through the ending composer, every storyline has Story+, and Gate 6 Alpha passes.",
               ["R8-B01, SOVEREIGN (R8-B02) and the God King (R8-B03, 4 family phases) with Hell phases and replay tests green",
                "All 27 storylines (24 + 3 secret) reach an ending through the composer, framed by who authorizes change; timing modifiers wired into every ending",
                "Story+ state for every storyline: 4 family arcs and 8 civic cases gated by flags",
                "Remaining 6 secret quests, SS-11/SS-12 and 8 time-sensitive quests completable; ITM-391..450 and COM-101..120 live",
                "R8 passes the §7 Definition of Done",
                "Gate 6 Alpha on 2032-09-30: content complete; bot reaches every storyline and timing branch; every quest completable"],
               D8(2031, 10, 1), D8(2032, 9, 30), cap)
    ph.blocks = [(D8(2032, 3, 31), ["kickoff", "systems", "R8"], "R8"), (D8(2032, 6, 30), ["endings", "storyplus"], "storyplus"),
                 (D8(2032, 9, 30), ["R8-dod", "alpha", "close"], "alpha")]
    ph.segment("kickoff")
    ph.add("primary", "Y6 kickoff: Act 4 and endings epics", "§7 Y6", ["docs", "story", "team"], [
        D("Y6 kickoff: epics", ["`/create-epics` for R8, Act 4, composer, Story+", "Story readiness", "Gate 6 evidence list"], "Epics exist"),
        D("Y6 kickoff: content-complete tracker", ["`/content-audit` against §3 targets", "Confirm side quests 150 of 150 (§3: R1-R8 = 19/21/17/17/16/22/23/15)", "Decision memo for you"], "Gap memo written"),
    ], ["Gap hidden by counting cut content"], "production/milestones/y6/content_audit.md")
    ph.segment("systems")
    pdays = [D("Ending composer: final architecture", ["Review composer v1 from the Pillar Slice; ADR for final module model", "Inputs: axis 1-3, hidden axis, companions, regions, pace, timing flags",
                                                       "Mark the 3 combinations the Y2 route table removes; map the 3 secret endings"], "Composer ADR")]
    for t in ["axis-1 family modules (Sole/Bound/None) and the Consent secret family", "axis-2 faction modifiers", "axis-3 deleted modifiers",
              "companion modules CMP-01..08", "region slide modules R1-R8", "timing modifier slides (act pace values and named timing flags)",
              "Tier A fate slides NPC-A-01..10", "side storyline slides SS-01..12"]:
        pdays.append(D(f"Ending composer: {t}", [f"Implement {t} as composable sequences", "Unit test selection rules", "Coverage viewer shows each module"], f"{t} composed"))
    pdays += [D("Ending composer: playback and skip", ["Playback via cinematic timeline; skip rules", "Credits hand-off", "Story+ hand-off"], "Playback works"),
              D("Ending composer: bot over 27 storylines", ["Bot reaches each storyline from Act 3 fixtures", "Every timing branch variant", "Coverage report"], "27/27 reached"),
              D("Ending composer: tests", ["`tests/integration/endings/test_composer.gd`", "Golden outputs per storyline", "CI nightly"], "Composer tests green")]
    ph.add("primary", "Ending composer complete (all 27 storylines + timing)", "§7 Y6 systems: ending composer; §12.2; P3/P10", ["story", "systems", "cinematics", "tests"], pdays,
           ["Missing companion module when a companion died/left", "Contradictory timing flags", "Hidden axis value with a non-Consent family"], "tests/integration/endings/test_composer.gd")
    pdays = [D("Story+ world state: design", ["`/design-system` for `design/gdd/story_plus.md`: state from axes + timing", "8 civic cases gating", "ADR"], "Story+ design approved")]
    for reg in REG:
        pdays.append(D(f"Story+ world state: {reg} {REG[reg][0]}", [f"{reg} post-ending state per family and faction", "Town state via NPC sim v3 extensions", "Test"], f"{reg} Story+ state"))
    pdays += [D("Story+: shows what timing changed", ["Story+ summary of timing effects (§12.4 fairness)", "UI hook", "Test"], "Timing summary works"),
              D("Story+: save and NG+ hooks", ["Story+ save block; NG+ carry-over rules untouched unless approved", "Migration", "Test"], "Saves migrate"),
              D("Story+: tests", ["`tests/integration/story_plus/test_world_state.gd` per storyline", "Bot enters Story+ from each ending", "CI"], "Story+ tests green")]
    ph.add("primary", "Story+ world state for every storyline", "§7 Y6; P8; §12.2", ["story", "openworld", "systems", "save", "tests"], pdays,
           ["Story+ with a region never visited", "Quest from Act 2 still open in Story+"], "tests/integration/story_plus/test_world_state.gd")
    for c in [{"id": f"ANM-P-{i:02d}", "name": n, "days": 2} for i, n in enumerate(
            ["Root Access full-authority cast", "final-boss counter move", "Act 4 traversal", "ending pose set", "Story+ idle variants", "corruption high-bleed variant", "victory/credits pose"], 34)]:
        player_clip(ph, c)
    ph.segment("R8")
    region_package(ph, region_spec("R8", 14))
    for i in range(43, 51):
        enemy(ph, {"id": f"EN-{i:02d}", "reg": "R8", "arch": ARCH[(i + 5) % len(ARCH)]})
    ph.add("secondary", "Encounter placement EN-43..50 (R8)", "P2 + §12.5", ["level", "combat"], [
        D("EN-43..46: placement R8", ["Place EN-43..46 in the Human Patch Lab and approach chunks", "Day/night rules", "Playtest"], "EN-43..46 placed"),
        D("EN-47..50: placement R8", ["Place EN-47..50 in the Root of Heaven chunks", "Final gauntlet pacing with checkpoints", "Playtest"], "EN-47..50 placed"),
    ], ["Gauntlet with no checkpoint"], "production/reviews/y6/encounters.md")
    ph.add("writing", "Bestiary EN-43..50", "codex", ["dialogue"], [
        D("Bestiary EN-43..50", [f"Codex entries for EN-43..50 (~{W(ph, 700)} words)", "Data Vision labels", "Key strings"], "EN-43..50 codex entries in"),
    ], ["Codex names the God King early (forbidden before the Human Patch Lab)"], "dialogue/codex/bestiary.dlg")
    tc = [0]
    r8q = quest_roster("R8", 15, 3, {1, 3, 5, 7}, {1, 2}, {"R8-SQ-01": ("SS-11", "T"), "R8-SQ-02": ("SS-11", "T"), "R8-SQ-03": ("SS-11", "T"),
                                                          "R8-SQ-04": ("SS-11", "T"), "R8-SQ-05": ("SS-12", "A1"), "R8-SQ-06": ("SS-12", "A1"),
                                                          "R8-SQ-07": ("SS-12", "A1"), "R8-SQ-08": ("SS-12", "A1")}, {1}, tc, 1)
    wq = []
    for i in range(1, 4):
        wq.append({"id": f"SEC-W-{i:02d}", "reg": ["R3", "R5", "R7"][i - 1], "kind": "secret", "structure": STRUCTS[(i * 3) % len(STRUCTS)],
                   "trigger": TRIGGERS[(i + 4) % len(TRIGGERS)], "feeds": "H", **({"timing": "window"} if i == 2 else {})})
    for q in r8q + wq:
        quest(ph, q)
    side_storyline(ph, {"id": "SS-11", "regs": ["R8"], "feeds": "T", "members": ["R8-SQ-01", "R8-SQ-02", "R8-SQ-03", "R8-SQ-04"], "note": " (Act 4 pace)"})
    side_storyline(ph, {"id": "SS-12", "regs": ["R8"], "feeds": "A1", "members": ["R8-SQ-05", "R8-SQ-06", "R8-SQ-07", "R8-SQ-08"]})
    tier_a(ph, {"id": "NPC-A-10", "reg": "R8", "name": "Act 4 Tier A slot per the Y2 world bible"})
    crowd(ph, {"id": "CRW-R8", "reg": "R8", "n": 30})
    boss(ph, {"id": "R8-B01", "reg": "R8", "name": "Act 4 gate boss per the combat bible"})
    final_boss(ph, "R8-B02", "SOVEREIGN", "§7 Y6: SOVEREIGN with a Hell phase; STORY_BIBLE §2 (afraid, not evil; never kills Kaelen)",
               ["phase 1 restraint", "phase 2 quarantine", "phase 3 containment", "Hell-only phase"],
               "what losing means when SOVEREIGN never kills (STORY_BIBLE §2)")
    final_boss(ph, "R8-B03", "the God King", "§7 Y6: true final boss with a Hell phase; STORY_BIBLE endings table (one phase per family)",
               ["opening phase (mirrors the player's route)", "Sole Authority phase", "Bound Authority phase", "No Authority phase",
                "Consent phase (loses its health bar)", "Hell-only phase"],
               "how each family phase changes the fight without multiplying authored cost")
    items_and_writing(ph, 391, 6, lambda b: "R8", 4)
    balance_reviews(ph, ["ITM-391..420", "ITM-421..450", "ITM-001..450 full-set /balance-check"])
    commodity_batch(ph, {"id": "COM-101..110", "cat": COM_CATS[7]})
    commodity_batch(ph, {"id": "COM-111..120", "cat": COM_CATS[8]})
    for i, fn in enumerate(["R8 exploration", "Human Patch Lab", "Root of Heaven ascent", "R8 battle", "SOVEREIGN theme", "God King theme",
                            "ending composer underscore set", "Story+ world (day)", "Story+ world (night)", "credits"], 36):
        music_track(ph, {"id": f"MUS-{i:02d}", "fn": fn})
    for i, dom in enumerate(["R8 enemies", "R8 interactables and foley", "final bosses", "endings and composer", "Story+ world", "final polish gaps from /asset-audit"], 31):
        sfx_batch(ph, {"id": f"SFX-batch-{i:02d}", "domain": dom}, f"SFX-batch-{i-1:02d}/{i:02d}" if i % 2 == 0 else None)
    cins = [("CIN-A4-01", "Act 4 opening"), ("CIN-A4-02", "Human Patch Lab arrival (God King may be foreshadowed, not named, before here)"),
            ("CIN-A4-03", "Human Patch Lab reveal"), ("CIN-A4-04", "SOVEREIGN asks for the Key"), ("CIN-A4-05", "ascent to the Root of Heaven"),
            ("CIN-A4-06", "SOVEREIGN confrontation"), ("CIN-A4-07", "the role compiles itself"), ("CIN-A4-08", "God King reveal"),
            ("CIN-A4-09", "post-fight decision frame"), ("CIN-A4-10", "Story+ opening")]
    for k, (cid, beat) in enumerate(cins):
        cinematic(ph, {"id": cid, "beat": beat, "reg": "R8"}, (f"{cins[k-4][0]}..{cid}" if k in (4, 9) else None))
    ph.segment("endings")
    # ---- 27 endings by coordinate: 9 faction×family groups + 3 secret endings
    for fam in "ABC":
        for fac in (1, 2, 3):
            grp = f"END-{fam}-{fac}-1..3"
            names = [f"END-{fam}-{fac}-{d}" for d in (1, 2, 3)]
            why = f"§7 Y6 all 27 endings; family {FAM[fam]}, faction {FAC[fac]} (§12.2 composer: additive cost)"
            note = "If the Y2 route table marks this combination invalid, spend the day on the secret ending that replaces it"
            ph.add("writing", f"Write endings {grp} ({FAM[fam].split(' (')[0]} / {FAC[fac]})", why, ["story", "dialogue", "cinematics"], [
                D(f"{n}: {FAM[fam].split(' (')[0]} / {FAC[fac]} / {DEL[d]} slides and lines", [f"Write the {n} composer slides and closing lines (~{W(ph, 900)} words)",
                                                                                               "Frame it by who authorizes the change; no perfect answer (STORY_BIBLE §1)", note, "Key strings; dialogue test"], f"{n} text drafted")
                for n, d in zip(names, (1, 2, 3))], ["Slide contradicts a timing flag"], f"dialogue/endings/{low(grp)}.dlg")
            ph.add("secondary", f"Direct endings {grp}", why, ["story", "cinematics"], [
                D(f"{grp}: composition review", [f"Assemble {', '.join(names)} in the composer", "Check axis-3 differences are visible", "Notes"], f"{grp} composed"),
                D(f"{grp}: sign-off playback", ["Play each from fixture saves", "Timing-variant slides", "Sign off"], f"{grp} signed"),
            ], ["Two endings indistinguishable"], f"production/reviews/y6/endings.md")
            ph.add("qa", f"Test endings {grp}", why, ["tests", "story"], [
                D(f"{n}: reach, playback and timing variants", [f"Bot reaches {n} on fast and slow timing profiles", "Playback with and without skip; credits and Story+ hand-off",
                                                                 "Composer golden output matches; timing slides match the flags"], f"{n} verified")
                for n in names], ["Ending reached with wrong faction modifier"], f"production/qa/y6/endings.md")
            ph.add("art", f"Ending slide art {grp}", why, ["art", "cinematics"], [
                D(f"{n}: slide illustrations ({DEL[d]})", [f"Illustrate the {n} slides: {FAC[fac]} under {FAM[fam].split(' (')[0]}, deleted = {DEL[d]}",
                                                           "Reuse modular backgrounds; only the changed elements are new (additive cost)", "Import and check in the composer"], f"{n} slides in")
                for n, d in zip(names, (1, 2, 3))], ["Slide shows a companion who left"], f"{ph.ev('endings')}")
            ph.add("audio", f"Ending cues {grp}", why, ["audio", "music"], [
                D(f"{grp}: underscore and faction tint", [f"Underscore cue for {FAM[fam].split(' (')[0]} with the {FAC[fac]} tint", "Variants for restore/release/choose",
                                                          "Implement in the composer and duck under text"], f"{grp} cues in"),
            ], ["Cue cut short when slides are skipped"], "assets/audio/endings/")
    for sid, nm in SECRET_ENDINGS:
        why = f"§7 Y6 all 27 endings; secret route {nm} (STORY_BIBLE endings table; hidden axis)"
        ph.add("writing", f"Write secret ending {sid} ({nm})", why, ["story", "dialogue"], [
            D(f"{sid}: structure", [f"Outline {sid} from the hidden-axis inputs", "Confirm with you: STORY_BIBLE lists First Wake and Crownless as post-1.0 candidates; ROADMAP §7 says all 27 in Y6",
                                    "Approval"], f"{sid} outline approved"),
            D(f"{sid}: scenes", [f"Write {sid} scenes (~{W(ph, 1500)} words)", "Witnessed-consent framing where relevant", "Dialogue test"], f"{sid} drafted"),
            D(f"{sid}: revision", ["Revise", "Keys", "QA hand-off"], f"{sid} final"),
        ], ["Secret reached without all witnesses"], f"dialogue/endings/{low(sid)}.dlg")
        ph.add("secondary", f"Direct secret ending {sid}", why, ["story", "cinematics"], [
            D(f"{sid}: direction", ["Storyboard", "Composer assembly", "Review"], f"{sid} directed"),
        ], ["Secret ending spoils itself in UI"], "production/reviews/y6/endings.md")
        ph.add("qa", f"Test secret ending {sid}", why, ["tests", "story"], [
            D(f"{sid}: reach", ["Secret-hunt bot profile", "Manual run from fixture", "Log"], f"{sid} reached"),
            D(f"{sid}: negative cases", ["Miss one hidden-axis requirement; the secret must not trigger", "Save/load between witnesses", "Log"], f"{sid} negatives logged"),
        ], ["Hidden axis value lost on load"], "production/qa/y6/endings.md")
        ph.add("art", f"Secret ending art {sid}", why, ["art", "cinematics"], [
            D(f"{sid}: keyframes", [f"Keyframes for the {nm} ending", "Stage in the composer", "Review"], f"{sid} keyframes in"),
            D(f"{sid}: slides", [f"Slide illustrations for {sid}", "Modular backgrounds", "Import"], f"{sid} slides in"),
        ], ["Secret art visible in a gallery before unlock"], f"{ph.ev(sid)}")
        ph.add("audio", f"Secret ending audio {sid}", why, ["audio", "music"], [
            D(f"{sid}: cue", [f"Cue for {nm}", "Witness motif variation where it fits", "Implement"], f"{sid} cue in"),
        ], ["Cue plays on the wrong ending"], "assets/audio/endings/")
    ph.segment("storyplus")
    fams = [("SP-SOLE", "Sole Authority"), ("SP-BOUND", "Bound Authority"), ("SP-NONE", "No Authority"), ("SP-CONSENT", "Consent")]
    for sid, nm in fams:
        why = "P8 Story+; STORY_BIBLE §6: one hand-written arc per ending family"
        ph.add("writing", f"Write Story+ arc {sid} ({nm})", why, ["story", "dialogue"], [
            D(f"{sid}: arc outline", [f"Outline the {nm} Story+ arc: one playable civic problem the ending created", "Never says everything is fixed", "Approval"], f"{sid} outline"),
            D(f"{sid}: opening scenes", [f"Draft `dialogue/story_plus/{low(sid)}/opening.dlg` (~{W(ph, 1200)} words)", "Faction and deleted-axis modifiers as branches", "Run tests/dialogue_test.gd"], f"{sid} opening drafted"),
            D(f"{sid}: middle scenes", [f"Draft `dialogue/story_plus/{low(sid)}/middle.dlg` (~{W(ph, 1200)} words)", "Companion presence variants (CMP-01..08)", "Run tests/dialogue_test.gd"], f"{sid} middle drafted"),
            D(f"{sid}: resolution", [f"Draft `dialogue/story_plus/{low(sid)}/resolution.dlg` (~{W(ph, 1000)} words)", "Lines that show what the player's timing changed (§12.4)", "Run tests/dialogue_test.gd"], f"{sid} resolution drafted"),
            D(f"{sid}: revision", [f"Revise all {sid} scenes against VOICE_GUIDE.md", "Key strings and translator notes", "Hand to QA"], f"{sid} final"),
        ], ["Arc references a region state that differs per faction"], f"dialogue/story_plus/{low(sid)}/")
        ph.add("primary", f"Implement Story+ arc {sid}", why, ["story", "quests", "code", "tests"], [
            D(f"{sid}: quest graph", [f"Author `data/quests/story_plus/{low(sid)}.tres`: stages, flags, rewards via `grant_once`", f"Gate it on the {nm} ending family in StoryGraph", "Add the bot path from each matching ending"], f"{sid} graph live and bot-reachable"),
            D(f"{sid}: tests", [f"Write `tests/integration/story_plus/test_{low(sid)}.gd`", "Cover each faction modifier and each deleted-axis value", "Add to CI nightly"], f"{sid} tests green"),
        ], ["Story+ arc started twice"], f"tests/integration/story_plus/test_{low(sid)}.gd")
        ph.add("secondary", f"Direct Story+ arc {sid}", why, ["story", "level"], [
            D(f"{sid}: staging", [f"Stage the {nm} arc in the reopened world", "Signpost its start from the nearest waystation", "Playtest the opening"], f"{sid} staged"),
            D(f"{sid}: sign-off", [f"Play {sid} end to end on Medium", "Check it never claims everything is fixed (STORY_BIBLE §6)", "Sign off in production/reviews/y6/story_plus.md"], f"{sid} signed off"),
        ], ["Arc giver absent in some town states"], "production/reviews/y6/story_plus.md")
        ph.add("qa", f"Test Story+ arc {sid}", why, ["tests", "story"], [
            D(f"{sid}: faction fixtures", ["Run the arc from each faction fixture", "Check modifiers", "Log"], f"{sid} faction cases logged"),
            D(f"{sid}: deleted-axis fixtures", ["Run restore/release/choose fixtures", "Check civic problem variant", "Log"], f"{sid} deleted cases logged"),
            D(f"{sid}: save, timing and completion", ["Save/load mid-arc", "Timing summary correct", "Complete and abandon"], f"{sid} completion logged"),
        ], ["Arc unreachable on a secret ending"], "production/qa/y6/story_plus.md")
        ph.add("art", f"Story+ arc art {sid}", why, ["art", "openworld"], [
            D(f"{sid}: arc locations", [f"Location dressing for the {nm} arc", "Swap sets", "Import"], f"{sid} locations dressed"),
            D(f"{sid}: arc characters and props", ["Arc-specific NPC variants and props", "Portraits", "Import"], f"{sid} characters in"),
        ], ["Arc prop appears in other families"], f"{ph.ev(sid)}")
        ph.add("audio", f"Story+ arc audio {sid}", why, ["audio", "music"], [
            D(f"{sid}: arc theme variation", [f"Variation of the Story+ world theme for {nm}", "Stems", "Implement"], f"{sid} theme in"),
            D(f"{sid}: arc SFX and ambience", ["Arc-specific ambience and SFX", "Mix", "Implement"], f"{sid} ambience in"),
        ], ["Theme variation clashes with town ambience"], "assets/audio/story_plus/")
    for i, nm in enumerate(SP_CASES, 1):
        cid = f"SP-CASE-{i:02d}"
        why = "P8 Story+; STORY_BIBLE §6 civic case pool (kept from the source)"
        ph.add("writing", f"Write Story+ civic case {cid} ({nm})", why, ["story", "dialogue", "quests"], [
            D(f"{cid} ({nm}): outline", [f"Outline {nm}'s case from STORY_BIBLE §6 and the Production Master source", "List the flags that gate it", "Director approval"], f"{cid} outline approved"),
            D(f"{cid} ({nm}): draft", [f"Draft `dialogue/story_plus/{low(cid)}.dlg` (~{W(ph, 1300)} words)", "Variants by ending family", "Run tests/dialogue_test.gd"], f"{cid} drafted"),
            D(f"{cid} ({nm}): revision", ["Revise; merge duplicate release-vs-knowledge content per the bible note", "Key strings and translator notes", "Hand to QA"], f"{cid} final"),
        ], ["Case contradicts the family arc"], f"dialogue/story_plus/{low(cid)}.dlg")
        ph.add("primary", f"Implement Story+ civic case {cid} ({nm})", why, ["story", "quests", "code"], [
            D(f"{cid}: gating and graph", [f"Author `data/quests/story_plus/{low(cid)}.tres` gated by its flags", "Add the bot path from 3 endings", f"Write `tests/integration/story_plus/test_{low(cid)}.gd`"], f"{cid} live and tested"),
        ], ["Case gated by a flag nobody writes"], f"tests/integration/story_plus/test_{low(cid)}.gd")
        ph.add("qa", f"Test Story+ civic case {cid}", why, ["tests", "story"], [
            D(f"{cid}: reach cases", ["Reach from 3 different endings", "Gate flags respected", "Log"], f"{cid} reach logged"),
            D(f"{cid}: outcome cases", ["Complete and fail paths", "Save/load mid-case", "Log"], f"{cid} outcomes logged"),
        ], ["Case visible on wrong ending"], "production/qa/y6/story_plus.md")
        ph.add("art", f"Story+ civic case art {cid}", why, ["art"], [
            D(f"{cid} ({nm}): case art", [f"Character variant and props for {nm}'s case", "Portrait", "Import"], f"{cid} art in"),
        ], ["Character variant reused from a different case"], f"{ph.ev(cid)}")
        ph.add("audio", f"Story+ civic case audio {cid}", why, ["audio"], [
            D(f"{cid} ({nm}): case audio", ["Short motif or stinger", "Case SFX", "Implement"], f"{cid} audio in"),
        ], ["Stinger collides with quest jingle"], "assets/audio/story_plus/")
        ph.add("secondary", f"Place Story+ civic case {cid}", why, ["story", "level"], [
            D(f"{cid}: placement", [f"Place {nm}'s case in the reopened world", "Signpost it from a Story+ notice board", "Playtest the find"], f"{cid} placed"),
        ], ["Placed in a region locked post-ending"], "production/reviews/y6/story_plus.md")
    for grp, ids in (("companions CMP-01..08", [f"CMP-0{i}" for i in range(1, 9)]), ("Tier A NPC-A-01..10", [f"NPC-A-{i:02d}" for i in range(1, 11)])):
        ph.add("writing", f"Ending and Story+ reactions: {grp}", "P8; composer companion and Tier A modules", ["dialogue", "story", "npc"], [
            D(f"{cid}: ending and Story+ reactions", [f"Write {cid}'s ending slide lines and Story+ reactions per family (~{W(ph, 800)} words)", "Respect the companion rules (no faction mascots)", "Key strings"], f"{cid} reactions in")
            for cid in ids
        ], ["Reaction for a companion who never joined"], "dialogue/endings/companions/")
    for part in ("towns", "landscape"):
        ph.add("art", f"Story+ world art states: {part}", "P8", ["art", "openworld"], [
            D(f"Story+ art: {reg} {REG[reg][0]} {part}", [f"Post-ending {part} art for {reg} per family", "Swap sets via town state", "Import and screenshot"], f"{reg} Story+ {part} in")
            for reg in REG
        ], ["Story+ swap not applied after load"], "production/qa/evidence/y6/story_plus/")
    ph.add("art", "Epilogue portraits: companions and Tier A", "P8; composer companion and Tier A modules", ["art", "npc"], [
        D(f"Epilogue portraits {grp}", [f"Draw epilogue portrait variants for {grp} per ending family", "Match existing portrait sets", "Import into the composer"], f"{grp} epilogue portraits in")
        for grp in ["CMP-01..02", "CMP-03..04", "CMP-05..06", "CMP-07..08", "NPC-A-01..03", "NPC-A-04..06", "NPC-A-07..08", "NPC-A-09..10"]
    ], ["Portrait for a companion who died or left"], "production/qa/evidence/y6/epilogue/")
    ph.add("art", "Corruption identity-bleed visuals (final)", "STORY_BIBLE §2 corruption stages; P9", ["art", "vfx", "accessibility"], [
        D("Corruption visuals: early desync", ["Final visual desync effect", "Photosensitivity-safe", "Option to reduce"], "Early stage final"),
        D("Corruption visuals: borrowed labels", ["Data Vision label distortions", "Readable at 200% text", "Implement"], "Mid stage final"),
        D("Corruption visuals: identity bleed", ["High-stage overlay", "Never hides telegraphs", "Review"], "High stage final"),
    ], ["Effect hides an enemy telegraph"], "production/qa/evidence/y6/corruption/")
    ph.add("audio", "Story+ town-state audio", "P8, P9", ["audio"], [
        D(f"Story+ audio: {reg} {REG[reg][0]}", [f"Ambience and crowd variants for {reg} per family", "Implement on town state", "Mix"], f"{reg} Story+ ambience in") for reg in REG
    ], ["Old ambience persists after the ending"], "assets/audio/story_plus/")
    ph.add("audio", "Soundtrack mastering pass (MUS-01..45)", "§3 ~45 tracks; release-quality audio", ["music", "audio"], [
        D(f"Mastering {a}..{b}", [f"Re-master {a}..{b} to the final loudness and EQ target", "Check stems still sum correctly", "Archive masters"], f"{a}..{b} mastered")
        for a, b in [(f"MUS-{i:02d}", f"MUS-{min(i + 4, 45):02d}") for i in range(1, 46, 5)]
    ], ["Re-master changes loop points"], "production/audio/music_register.md")
    ph.add("writing", "Story+ town barks per region", "P8 + P4 reactive world", ["dialogue", "npc"], [
        D(f"Story+ barks: {reg} {REG[reg][0]}", [f"Post-ending barks for {reg} per family (~{W(ph, 500)} words)", "Never says everything is fixed", "Key strings"], f"{reg} Story+ barks in") for reg in REG
    ], ["Bark contradicts the faction modifier"], "dialogue/story_plus/barks/")
    ph.segment("R8-dod")
    region_dod(ph, "R8", "REL-Y6-1")
    ph.segment("alpha")
    y6_alpha(ph)
    ph.segment("close")
    ph.add("qa", "Gate 6 coverage: every storyline and timing branch", "Gate 6: bot reaches every storyline and timing branch; every quest completable", ["tests", "story", "time", "quests"], [
        D("Gate 6: storyline matrix", ["Bot run over 27 storylines", "Record coverage %", "File gaps"], "Matrix report"),
        D("Gate 6: timing branches", ["Fast/slow/out-of-order over every act", "Every named timing flag hit", "File gaps"], "Timing report"),
        D("Gate 6: every quest completable", ["Bot completes all quests in the roster (side, secret, time-sensitive, Story+)", "Manual check on bot-unreachable ones", "File gaps"], "Quest report"),
        D("Gate 6: difficulty spot matrix", ["Each of 24 bosses on Medium and Hell", "Replay suite on release build", "Log"], "Boss matrix"),
    ], ["Coverage counts a storyline reached only via debug flags"], "production/qa/y6/gate6_coverage.md", anchor=D8(2032, 9, 1))
    milestone_close(ph, "Gate 6 Alpha", "content complete; every storyline and timing branch reachable by bot; every quest completable", D8(2032, 9, 22))
    monthly_secondary(ph, [(2031, m) for m in (10, 11, 12)] + [(2032, m) for m in range(1, 10)])
    monthly_qa(ph, [(2031, m) for m in (10, 11, 12)] + [(2032, m) for m in range(1, 10)])
    quarter_replan(ph, [D8(2032, 1, 2), D8(2032, 4, 2), D8(2032, 7, 2)])
    for i, d in enumerate([D8(2031, 11, 15), D8(2032, 1, 15), D8(2032, 3, 15), D8(2032, 5, 15), D8(2032, 7, 15)], 12):
        pid = f"EA-P{i:02d}"
        ph.add("primary", f"Early Access patch {pid}", "EA cadence; saves migrate across every patch", ["release", "save", "code"], [
            D(f"{pid}: fixes and migration", ["`/bug-triage`; fix top issues", f"`SaveService.migrate` step for {pid} + fixture", "Release after QA and your go"], f"{pid} released"),
        ], ["Patch alters an ending flag in old saves"], f"tests/unit/save/test_migration_{low(pid)}.gd", anchor=d)
        ph.add("qa", f"Patch verification {pid}", "Save migration 100%", ["tests", "release"], [
            D(f"{pid}: verification", ["`/regression-suite` + `/smoke-check`", "Every save fixture", "Verify fixes"], f"{pid} verified"),
        ], ["Regression in Act 3 branch"], f"production/qa/y6/{low(pid)}.md", anchor=d)
        ph.add("secondary", f"Patch notes {pid}", "EA cadence", ["release", "marketing"], [
            D(f"{pid}: notes and comms", ["`/patch-notes`", "Post after review (no ending spoilers)", "Record dashboard numbers as read"], f"{pid} notes out"),
        ], ["Notes spoil an ending"], f"production/release/ea/{low(pid)}.md", anchor=d)
    ph.segment("R8")
    add_pools(ph, ["R8", "R1", "R2", "R3", "R4", "R5", "R6", "R7"], ["ending composer", "Story+ world state", "final bosses", "save migration chain", "bot coverage tooling"],
              ["ending and credits flow", "Story+ timing summary", "journal storyline tracker", "options and accessibility"])
    ph.word_target = 80000
    return ph


# =============================================================================================

BRIEF_CAPS = {
    "Y3": {"primary": 312, "secondary": 365, "art": 261, "audio": 261, "writing": 261, "qa": 261},
    "Y4": {"primary": 313, "secondary": 365, "art": 261, "audio": 261, "writing": 261, "qa": 261},
    "Y5": {"primary": 313, "secondary": 365, "art": 261, "audio": 261, "writing": 261, "qa": 261},
    "Y6": {"primary": 314, "secondary": 366, "art": 262, "audio": 262, "writing": 262, "qa": 262},
}


def validate(paths, caps):
    caps = BRIEF_CAPS
    seen = {}
    ids = set()
    ok = True
    report = []
    for p in paths:
        doc = json.load(open(p, encoding="utf-8"))
        tot = {s: 0 for s in STREAMS}
        for t in doc["tasks"]:
            assert t["id"] not in ids, t["id"]
            ids.add(t["id"])
            tot[t["stream"]] += len(t["days"])
            for d in t["days"]:
                assert 3 <= len(d["steps"]) <= 6
                k = (d["focus"].strip().lower(), tuple(x.strip().lower() for x in d["steps"]))
                if k in seen:
                    ok = False
                    report.append(f"DUP day in {t['id']} == {seen[k]}: {d['focus']}")
                seen[k] = t["id"]
        cap = caps[doc["phase_id"]]
        line = [doc["phase_id"]]
        for s in STREAMS:
            pct = 100.0 * tot[s] / cap[s]
            line.append(f"{s}={tot[s]}/{cap[s]} ({pct:.1f}%)")
            if not 97 <= pct <= 103:
                ok = False
        report.append(" ".join(line) + f" tasks={len(doc['tasks'])}")
    return ok, report


def main():
    paths = []
    caps = {}
    for b in (build_y3, build_y4, build_y5, build_y6):
        ph = b()
        ph.fill()
        for (st, bi, target, content) in ph.block_report:
            print(f"  {ph.pid} {st:9s} block{bi+1}: target cum {target:4d}  content before fill {content:4d}")
        p = os.path.join(OUT, f"{ph.pid}.json")
        ph.write(p)
        paths.append(p)
        caps[ph.pid] = ph.cap
        fills = sum(1 for x in ph.tasks if "(" + ph.pid + ")" in x[3]["title"])
        print(f"{ph.pid}: words base={ph.words_emitted:.0f} scale={ph.word_scale:.2f} -> {ph.word_target}; fill tasks={fills}")
    ok, rep = validate(paths, caps)
    print("\n".join(rep))
    print("VALID" if ok else "INVALID")
    return 0 if ok else 1


if __name__ == "__main__":
    sys.exit(main())
