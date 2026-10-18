"""Y9: console launches, Expansion 1 (Human Patch Lab + Forgotten Sectors), optional Hell leaderboards/speedrun (2034-10-01 -> 2035-09-30)."""
from late_common import *
from late_y9_extra import add_extra, reorder

CAPS = {"primary": 312, "secondary": 365, "art": 261, "audio": 261, "writing": 261, "qa": 261}
PATCHES = ["1.6.0", "1.7.0", "1.8.0", "1.9.0", "1.9.1", "2.0.0 + Expansion 1", "2.0.1"]
LE_Y9 = [f"LE-P{k:02d}" for k in range(13, 25)]
CODE_FOLDERS = ["scripts/core", "scripts/combat", "scripts/dialogue", "scripts/overworld", "scripts/regions", "scripts/ui", "scripts/exploration", "scripts/cutscene"]
TIERS = ["fix", "variant"]


def X1R(r):
    return dict(X1_REG)[r]


def build():
    ph = Phase("Y9", "Console launches and Expansion 1",
               "Aethelgard is live on console platforms A, B and C; Expansion 1 adds Human Patch Lab and Forgotten Sectors with 3 new storylines, new goods and events on every platform; optional Hell leaderboards and a real speedrun timer ship if the ADR says go.",
               ["Platforms A, B and C pass certification (check current platform requirements) and launch; crash-free >= 99.5% on each",
                "Expansion 1 ships as DLC on PC + A/B/C: 12 chunk sets, X1-B25..B28 on 5 difficulties with Hell replays, 20 side quests, 6 TQs, 4 secrets, 16 commodities, 8 events, 12 Tier B NPCs",
                "X1-ST1..ST3 reachable by bot on all 5 difficulties x 3 timing profiles; base 27 storylines unaffected (matrix green)",
                "Saves from every release since EA still load (save-compat CI) including DLC-missing cases",
                "Leaderboard/speedrun ADR recorded; if go: IGT timer and replay-verified Hell submissions live",
                "Y9 retrospective done and Expansion 2 region chosen"],
               CAPS)

    # ============================== PRIMARY ==============================
    ph.spec("primary", "Y9 kickoff", "ROADMAP §9 Y9", ["team", "release"], [
        ("Y9 kickoff: console launch order and X1 plan", ["Agree console launch order A, B, C with the chosen partner and platform calendars (check current submission lead times)", "Lay out X1 milestones: tech, content lock, cert for DLC, release",
                                                         "Run `/sprint-plan`", "Publish `production/milestones/y9_plan.md`"], "Y9 plan published"),
        ("Y9 kickoff: risks", ["Update risk register: cert failures, DLC entitlement, X1 scope", "Assign owners", "Set X1 cut list from the budget", "Record"], "Y9 risks owned")],
        ["Platform submission window closes"], "production/milestones/y9_plan.md", where="head")
    pid, pname = PLATFORMS[2]
    ph.spec("primary", f"Console port completion: {pname}", "§9 console ports", ["release", "performance", "tests"],
            [(f"{pid} performance in {r} {rn}", [f"Run the {r} perf route on {pname}", "Fix top hotspot", "Check streaming hitches", f"Record `production/console/{pid}/perf_{r}.md`"], f"{pid} {r} meets target") for r, rn, _ in REGIONS] +
            [(f"{pid} pre-cert {cc}: {cn}", [f"Re-test {cc} on {pname} with current requirements (check current)", "Fix remaining failures", "Partner confirms backend items", "Record"], f"{pid} {cc} pass") for cc, cn in CERT_CATS[5:]] +
            [(f"{pid} DLC entitlement prep", ["Prototype Expansion 1 entitlement check via PlatformService", "Test owned/not owned", "Document", "Record"], f"{pid} DLC path proven"),
             (f"{pid} milestone acceptance", ["Run contract acceptance tests", "Write report", "User signs off", "Archive build"], f"{pid} accepted")],
            ["Requirement updated after pre-cert"], f"production/console/{pid}/")
    for k, (p, n) in enumerate(PLATFORMS):
        t = ph.spec("primary", f"Console launch: {n}", "§9 Y9 console launches", ["release", "tests"], [
            (f"{p} submission build", [f"Cut `release/{p}-1.0` from the current PC release tag", "Run every CI job plus partner's platform checks", "Archive symbols", "Partner submits (check current submission process)"], f"{p} submitted"),
            (f"{p} submission support", ["Answer platform questions with the partner", "Track submission status", "Prepare fix branch", "Record"], f"{p} submission tracked"),
            (f"{p} cert fix round 1", ["Fix reported failures", "Re-run the affected CC cases", "Resubmit via partner", "Record"], f"{p} round 1 fixed"),
            (f"{p} cert fix round 2 (if needed)", ["Fix any remaining failures or use the day for regression", "Confirm approval status", "Record", "Plan day-one patch"], f"{p} approved or round 2 done"),
            (f"{p} day-one patch", ["Collect fixes that missed the submission", "Build, test, submit patch (check current patch process)", "Verify", "Record"], f"{p} day-one patch ready"),
            (f"{p} launch day watch", ["Watch platform crash reports via partner tools", "Triage", "Decide hotfix", "Log in `production/warroom/{0}_day0.md`".format(p)], f"{p} launch day logged"),
            (f"{p} launch +1 watch", ["Watch crash and review data", "Fix top signature", "Log", "Stop at planned time"], f"{p} +1 logged"),
            (f"{p} launch +2 watch", ["Watch data", "Prepare hotfix if needed", "Log", "Stop at planned time"], f"{p} +2 logged"),
            (f"{p} launch +7 review", ["Compare crash-free with PC", "List platform-specific issues", "Plan patch parity", "Record"], f"{p} week-one review done"),
            (f"{p} patch parity setup", ["Add the platform to the patch pipeline (branch, build, partner hand-off)", "Define parity rule: same content, platform patch lag documented", "Test with a no-op patch", "Record"], f"{p} in patch pipeline"),
            (f"{p} save and Hell determinism check after launch", ["Run save-compat fixtures on retail build via partner", "Run 24 Hell replays", "Compare with PC", "Record"], f"{p} saves and replays ok"),
            (f"{p} launch retrospective", ["Collect what slowed cert", "Update runbook for the next platform", "Record ADR changes", "Archive"], f"{p} retro done")],
            ["Cert failure on a requirement changed after pre-cert"], f"production/console/{p}/launch.md")
        ph.anchor(t, [0.12, 0.30, 0.50][k])
    ph.spec("primary", "Console patch parity process", "Live-ops across platforms", ["release", "tools", "docs"], [
        ("Parity: pipeline", ["Extend the release script to produce PC + A/B/C builds from one tag", "Add per-platform hotfix-suite runs", "Document lag expectations", "Record"], "One tag builds all platforms"),
        ("Parity: tracking", ["Add a platform column to patch notes and the tracker", "Report parity status weekly", "Record", "Train team"], "Parity tracked"),
        ("Parity: crash pipeline per platform", ["Ingest partner crash exports into the war-room dashboard", "Group by signature across platforms", "Test", "Record"], "Cross-platform crash view")],
        ["Platform patch rejected while PC is live"], "docs/release/parity.md")

    ph.spec("primary", "Expansion 1: DLC packaging and entitlement", "X1 ADR from Y8", ["release", "architecture", "code"],
            [(f"DLC packaging on {x}", [f"Build the X1 resource pack for {x}", "Gate loading through PlatformService entitlement", "Test owned/not owned/removed", "Record"], f"{x} DLC packaging works") for x in ["PC", "console platform A", "console platform B", "console platform C"]],
            ["Refund removes DLC mid-session"], "docs/expansion1/dlc.md")
    ph.fam("primary", "Expansion 1: chunk-set integration", "P7a one streamed world; §12.5 budgets", ["openworld", "level", "performance"], X1_CS,
           lambda u: f"Integrate {u[0]} ({u[2]}) into the streamed world",
           lambda u: [f"Import the accepted {u[0]} chunks (after controlled production import by art)", "Wire seams to neighbours; streaming hitch < 2 ms", "Place waystation/POI markers in the map with fog of war",
                      f"Run `tests/integration/streaming/test_{u[0].lower().replace('-', '_')}.gd`"],
           lambda u: f"{u[0]} streams seamlessly", ["Seam on a season-variant tile"], "tests/integration/streaming/", chunk=6)
    ph.spec("primary", "Expansion 1: story, market and events", "§12.2 additive storylines; §12.6 market; §12.4 events", ["story", "economy", "time", "systems"],
            [(f"{st} StoryGraph and flags (day {k})", [f"{'Add ' + st + ' nodes and x1_* flags in FlagRegistry' if k == 1 else 'Wire ' + st + ' outcomes into the ending composer and Story+ state'}", "Keep additive (no new multiplicative storylines)", "Add reachability test", "Record"], f"{st} day {k} done") for st in X1_ST for k in (1, 2)] +
            [("Ending composer X1 hooks", ["Add X1 slide hooks per ending family", "Test composition with each base storyline", "No change to base slides", "Record"], "Composer hooks done"),
             ("Ending composer X1 regression", ["Run all 27 base endings with and without X1", "Diff outputs", "Fix", "Record"], "Base endings unchanged without X1")] +
            [(f"Market integration {X1_CM[k]}-{X1_CM[k + 3]}", ["Add commodities to ItemDB and market sim", "Add NPC agents", "Run 1000-day sim on 3 storylines", "Record"], f"{X1_CM[k]}-{X1_CM[k + 3]} integrated") for k in range(0, 16, 4)] +
            [(f"Limited editions {X1_LE[k]}-{X1_LE[k + 1]}", ["Add calendar releases and stock", "Signpost in advance", "Test", "Record"], f"{X1_LE[k]}-{X1_LE[k + 1]} live in data") for k in range(0, 6, 2)] +
            [(f"World event {ev}", [f"Implement {ev} on WorldClock with its conditions", "Apply NPC and market effects", "Add test with seeded clock", "Record"], f"{ev} implemented") for ev in X1_EV] +
            [(f"Auction house integration {ah} for X1 goods", [f"Allow X1 goods in {ah} with NPC bidder preferences", "Check sniping caps", "Test", "Record"], f"{ah} handles X1 goods") for ah in AHS] +
            [("Economy sim regression: 27 storylines + X1", ["Run 1000-day sims for all storylines with X1 owned", "Run without X1", "Compare", "Record"], "Economy stable with/without X1")],
            ["Event triggered while player is in the base world far from X1"], "tests/unit/x1/ + production/qa/y9/econ/")
    ph.spec("primary", "Expansion 1: bosses and enemies", "P2/P6: every boss has a Hell-only phase", ["combat", "difficulty", "ai"],
            [(f"{b} {['frame data and states', 'AI patterns and variants', 'Hell-only phase', 'difficulty wiring and Hell replay'][k - 1]}",
              [f"{['Author ' + b + ' frame data in data/bosses/' + b + '/frame_data.tres', 'Implement ' + b + ' pattern AI with +variants for Medium/Hard', 'Implement ' + b + ' Hell-only phase', 'Wire 5 difficulty profiles; record perfect Hell replay and run mutants'][k - 1]}",
               "Use the fixed tick; no `create_timer` in gameplay code", "Unit/integration test for the step", f"Record in `production/qa/y9/bosses/{b}.md`"], f"{b} step {k} done")
             for b, _ in X1_BOSSES for k in range(1, 5)] +
            [(f"Enemy {e} ({X1R(r)})", [f"Implement {e} frame data, AI and drops", "Spawn test and stat invariants", "Arena context test", "Record"], f"{e} implemented") for e, r in X1_ENEMIES],
            ["Boss phase transition during Root Access slow-time"], "tests/integration/replay/ + production/qa/y9/bosses/")
    ph.spec("primary", "Expansion 1: NPCs, quests, saves, performance", "P4/P5; save safety; perf budgets", ["npc", "quests", "save", "performance"],
            [(f"NPC schedules {X1_NB[k]}-{X1_NB[k + 1]}", ["Implement schedules and memory facts", "Merchants trade on the market", "Sim LOD check", "Record"], f"{X1_NB[k]}-{X1_NB[k + 1]} live") for k in range(0, 12, 2)] +
            [(f"Quest bot coverage {x}", [f"Extend `tools/bot/quest_bot.gd` to {x}", "Assert completion reachable on Medium and Hell leniency", "Assert failures signposted", "Record"], f"{x} bot-covered") for x in ["X1-SQ-01..10", "X1-SQ-11..20", "X1-TQ-01..06", "X1-SC-01..04"]] +
            [("X1 save migration (approved schema change)", ["Confirm explicit approval for the X1 save block", "Implement migration and DLC-missing behaviour", "Fixtures: pre-X1 saves, X1 saves without DLC", "Tests"], "Migration tested"),
             ("X1 save migration: CI", ["Add fixtures to save-compat", "Run on all platforms", "Fix", "Record"], "save-compat green with X1"),
             ("X1 save migration: refund/removal", ["Test DLC removed after X1 progress", "Keep data, block entry, explain", "Test", "Record"], "Removal handled"),
             ("X1 save migration: Story+ interplay", ["Test X1 entered after the final boss (Story+)", "Check Story+ state", "Test", "Record"], "Story+ entry handled")] +
            [(f"X1 perf {X1R(r)} on {x}", [f"Profile {X1R(r)} route on {x}", "Fix top hotspots", "Check budgets", "Record"], f"{X1R(r)} {x} meets budget") for r, _ in X1_REG for x in ("PC min spec", "consoles A/B", "console C")] +
            [("QA matrix extension for X1", ["Add X1-ST1..ST3 x 5 difficulties x 3 timing = 45 cells", "Add X1-owned variants of 27 base cells (sample)", "Nightly", "Record"], "Matrix extended"),
             ("X1 localization engineering", ["Export XLB01..XLB04 string tables", "Check fonts for new glyphs", "Overflow test", "Record"], "X1 strings in loc pipeline"),
             ("X1 accessibility check", ["Run AX01-AX12 checks in X1 content", "Fix", "Evidence", "Record"], "X1 a11y ok")],
            ["NPC from X1 wanders into a base region"], "production/qa/y9/x1/")
    ph.spec("primary", "Expansion 1 release", "§9 Y9", ["release", "tests"], [
        ("X1 release build", ["Cut `release/2.0.0` with X1 packs per platform", "Run every CI job", "Partner submits console DLC (check current process)", "Record"], "2.0.0 built"),
        ("X1 release day watch", ["Watch crash and entitlement errors", "Triage", "Hotfix if needed", "Log"], "Release day logged"),
        ("X1 release +1 watch", ["Watch data", "Fix top issue", "Log", "Stop at planned time"], "+1 logged"),
        ("X1 release +7 review", ["Compare stability with base", "List issues", "Plan 2.0.1", "Record"], "Week-one review done"),
        ("X1 engineering retrospective", ["Run `/retrospective`", "List what to change for Expansion 2", "Record ADRs", "Archive"], "Retro recorded")],
        ["Entitlement service outage on one platform"], "production/releases/2.0.0.md")
    ph.spec("primary", "Optional: Hell leaderboards and speedrun support", "§9 Y9 optional: leaderboards and speedrun (timer exists; make it real); A5 single-player", ["difficulty", "systems", "legal", "tests"], [
        ("Leaderboard/speedrun ADR", ["Decide go/defer with the user: platform leaderboards only, no own servers (A5)", "Privacy: opt-in, display names from platform", "Scope: IGT timer, splits, Hell boss rush board", "Record ADR"], "ADR recorded"),
        ("IGT timer", ["Implement in-game time excluding loads and pauses (ContextStack aware)", "Separate from WorldClock", "Unit tests", "Record"], "IGT timer correct"),
        ("RTA/IGT display and splits", ["Add timer HUD toggle", "Add per-act and per-boss splits", "Export splits file", "Record"], "Splits work"),
        ("Speedrun categories", ["Support any%, per-storyline%, Hell boss rush", "Seeded RNG option for runs", "Document", "Record"], "Categories defined"),
        ("Replay-verified submissions 1", ["Attach the input replay to a Hell boss rush result", "Validate locally by replaying headless before submit", "Reject mismatches", "Record"], "Local validation works"),
        ("Replay-verified submissions 2", ["Upload score + replay to platform leaderboard attachments where supported (check current platform APIs)", "Fallback: score only, flagged unverified", "Test", "Record"], "Upload works"),
        ("Leaderboards on PC", ["Integrate the PC store's leaderboard API via PlatformService (check current docs)", "Opt-in UI", "Test", "Record"], "PC boards live"),
        ("Leaderboards on consoles", ["Partner implements backends", "Run contract tests", "Test", "Record"], "Console boards live"),
        ("Anti-tamper basics", ["Reject results from modified data checksums", "Rate-limit submissions", "Document limits honestly", "Record"], "Basic checks in place"),
        ("Leaderboard UI", ["Add boards screen with filters (difficulty, platform)", "Accessibility check", "Evidence", "Record"], "UI done"),
        ("Leaderboard edge cases", ["Offline play, later sync", "Account change", "Board reset policy", "Tests"], "Edge cases tested"),
        ("Leaderboard launch", ["Ship with 2.0.1", "Watch for abuse", "Community rules via secondary", "Record"], "Boards launched")],
        ["Replay from a different build version (must refuse)", "Platform without leaderboard attachments"], "ADR + tests/unit/speedrun/")
    ph.fam("primary", "Static typing and warnings pass", "Code quality: typed GDScript, warnings as errors", ["code", "cleanup", "tests"], CODE_FOLDERS,
           lambda f: f"Static typing pass: `{f}/`",
           lambda f: [f"Enable warnings-as-errors for untyped declarations in `{f}/`", "Add explicit types and return types; fix inferred-Variant warnings", "Run the full suite", "Record remaining exceptions"],
           lambda f: f"`{f}/` typed and warning-free", ["Dynamic dictionary access in save code (do not change schema)"], "CI warnings report")
    ph.fam("primary", "Console performance patches", "Console quality after launch", ["performance"], [(p, n, k) for p, n in PLATFORMS for k in range(1, 5)],
           lambda u: f"{u[0]} perf patch work {u[2]}",
           lambda u: [f"Take the #{u[2]} worst perf report on {u[1]}", "Reproduce on devkit via partner", "Fix", "Ship in next parity patch"],
           lambda u: f"{u[0]} perf item {u[2]} fixed", ["Fix regresses PC"], "production/console/perf_patches.md", chunk=6)
    ph.fam("primary", "Economy exploit reviews", "Exploit turnaround <= 1 patch", ["economy"], [f"EX-{k:02d}" for k in range(7, 13)],
           lambda e: f"Economy exploit review {e}",
           lambda e: [f"Investigate alert cluster {e}", "Reproduce in sim", "Fix by data + invariant", "Ship within one patch"],
           lambda e: f"{e} closed", ["Exploit only with X1 goods"], "production/live/econ/")
    every_year(ph, "Y9", "the console launch gate", PATCHES, triage_n=13)
    ph.spec("primary", "Expansion 2 technical pre-production", "§9 Y10 Expansion 2", ["architecture", "openworld"], [
        ("X2 tech scope", ["Read the X2 region choice from the Y9 retrospective", "Estimate chunk sets, bosses, systems touched", "Reuse X1 pipeline", "Record"], "X2 tech scope"),
        ("X2 seams and budgets", ["Plan seams and chunk coordinates", "Set budgets", "Record", "Review"], "X2 seams planned"),
        ("NG+ technical design", ["Design NG+ cycle state, carryover rules and remix data hooks", "Flag save schema change for explicit approval", "Write ADR draft", "Record"], "NG+ ADR draft"),
        ("Story+ extension technical design", ["Design Story+ extension state and civic case slots", "Plan composer hooks", "ADR draft", "Record"], "Story+ ext ADR draft"),
        ("Y10 tech epics", ["Run `/create-epics` for X2, NG+, Story+ ext", "Estimate", "Record", "Plan"], "Y10 epics exist"),
        ("Y9 engineering retrospective", ["Run `/retrospective` for Y9 engineering", "List changes", "Record ADRs", "Archive"], "Retro recorded")],
        ["NG+ needs schema change (approval)"], "docs/architecture/ ADR drafts", where="tail")
    ph.set_filler("primary", Filler(
        lambda i: D(f"Live fix LF9-{i + 1:03d}: {SYSTEMS[i % 15]} ({['PC', 'console A', 'console B', 'console C'][(i // 15) % 4]})",
                    [f"Take the oldest open `{SYSTEMS[i % 15]}` bug reported on {['PC', 'console A', 'console B', 'console C'][(i // 15) % 4]}", "Reproduce from save and steps (partner devkit for consoles)",
                     f"Fix with a test under `tests/unit/{SYS_SLUG[SYSTEMS[i % 15]]}/`", "Queue for the next parity patch"],
                    f"LF9-{i + 1:03d} fixed"),
        lambda n: f"Live fixes block {n:02d}", "Live support across platforms", ["code", "tests"], ["Fix behaves differently on one platform"], "Closed issues", "primary"), 5)

    # ============================== SECONDARY ==============================
    ph.spec("secondary", "Y9 kickoff: production plan", "§9 Y9", ["team", "release"], [
        ("Y9 production plan", ["Map X1 content milestones for team streams", "Map console launch marketing", "Run `/sprint-plan`", "Publish"], "Plan published"),
        ("Y9 onboarding", ["Onboard new contractors with `/onboard`", "Assign mentors", "Record", "Review after 2 weeks"], "Onboarding started")],
        ["Contractor start delayed"], "production/milestones/y9_plan.md", where="head")
    for k, (p, n) in enumerate(PLATFORMS):
        t = ph.spec("secondary", f"Console launch marketing and community: {n}", "§9 console launches", ["marketing", "release"], [
            (f"{p} store page final", [f"Finalise {n} store page (check current platform rules)", "zh-Hans", "Submit", "Record"], f"{p} page approved"),
            (f"{p} certification paperwork", ["Fill platform metadata/rating forms with partner (check current)", "Confirm age rating", "Submit", "Record"], f"{p} paperwork done"),
            (f"{p} launch beat L-30", ["Announce date", "Trailer variant", "Post", "Log"], f"{p} L-30 done"),
            (f"{p} launch beat L-7", ["Preview posts", "Creator keys (check current rules)", "Post", "Log"], f"{p} L-7 done"),
            (f"{p} launch day community", ["Post launch", "Watch threads", "Tag issues", "Log"], f"{p} day 0 done"),
            (f"{p} launch +1 community", ["Answer FAQ", "Collect issues", "Post status", "Log"], f"{p} +1 done"),
            (f"{p} launch +3 community", ["Post fixes status", "Collect reviews", "Log", "Plan"], f"{p} +3 done"),
            (f"{p} launch +7 review", ["Sales, reviews, issues summary", "Compare with PC", "Actions", "Record"], f"{p} week review"),
            (f"{p} feedback synthesis 1", [f"Group {n} feedback (controls, text size, performance)", "Prioritise", "Hand to primary/art", "Record"], f"{p} feedback grouped"),
            (f"{p} feedback synthesis 2", ["Verify shipped fixes", "Reply to players", "Archive", "Record"], f"{p} feedback closed")],
            ["Platform storefront feature changes"], f"production/console/{p}/marketing.md")
        ph.anchor(t, [0.10, 0.28, 0.48][k])
    ph.fam("secondary", "X1 level design per chunk set", "P7a; level design is the user's job", ["level", "openworld"], [(cs, r, n, k) for cs, r, n in X1_CS for k in ("block-out", "art pass integration", "polish")],
           lambda u: f"{u[0]} ({u[2]}) {u[3]}",
           lambda u: [f"{'Block out ' + u[0] + ' traversal, POIs and encounter spaces' if u[3] == 'block-out' else ('Integrate accepted art into ' + u[0] + ' keeping collision unchanged' if u[3] == 'art pass integration' else 'Polish ' + u[0] + ' rewards, signage and waystation spacing')}",
                      "Check traversal gates are ability-based", "Walk at day and night", f"Capture `production/qa/evidence/y9/level/{u[0]}_{u[3].split()[0]}.png`"],
           lambda u: f"{u[0]} {u[3]} done", ["Collision change needed (explicit approval)"], "production/qa/evidence/y9/level/", chunk=9)
    ph.fam("secondary", "X1 quest integration", "P5", ["quests", "dialogue"], [q for q, _ in X1_SQ] + [q for q, _ in X1_TQ] + X1_SC,
           lambda q: f"Integrate quest {q}",
           lambda q: [f"Build {q} in the quest tool from its design and the writer's `.dlg`", "Set flags, rewards (RewardLedger) and timing rules", "Play it start to finish on Medium", f"Record `production/qa/y9/quests/{q}.md`"],
           lambda q: f"{q} playable end to end", ["Quest giver killed by a world event"], "production/qa/y9/quests/", chunk=6)
    ph.fam("secondary", "X1 storyline scenes", "P3 additive storylines", ["story", "cinematics"], [(st, k) for st in X1_ST for k in range(1, 5)],
           lambda u: f"{u[0]} scene SCN{u[1]} integration",
           lambda u: [f"Integrate {u[0]}-SCN{u[1]} (dialogue, staging, camera)", "Check flags and axis hooks", "Skip/pause safety", "Record"],
           lambda u: f"{u[0]}-SCN{u[1]} integrated", ["Scene triggers during a deadline window"], "production/qa/y9/story/", chunk=6)
    ph.fam("secondary", "X1 boss tuning on all 5 difficulties", "P2/P6", ["combat", "difficulty", "fun"], [(b, d) for b, _ in X1_BOSSES for d in DIFFS],
           lambda u: f"{u[0]} on {u[1]['diff']}",
           lambda u: [f"Load `data/difficulty/{u[1]['d']}.tres`; confirm {u[0]} reads parry {u[1]['parry']} f, i-frames {u[1]['iframes']}, telegraph {u[1]['tele']}, damage {u[1]['dmg']}, {u[1]['heals']} charges",
                      f"Play {u[0]} 3 times on {u[1]['diff']} ({u[1]['pat']})", "Adjust data only; never frame windows", f"Record `production/qa/y9/balance/{u[0]}_{u[1]['d']}.md`"],
           lambda u: f"{u[0]} {u[1]['diff']} signed off", ["Hell-only phase on retry"], "production/qa/y9/balance/", chunk=5)
    ph.spec("secondary", "X1 economy, NPCs and items", "P7b/P4/P7e", ["economy", "npc", "items"],
            [(f"X1 goods tuning {X1_CM[k]}-{X1_CM[k + 3]}", ["Read sim results", "Tune base/seasonality/demand", "`/balance-check`", "Record"], "Tuned") for k in range(0, 16, 4)] +
            [(f"X1 limited edition {le}", [f"Check {le} stock, place, time and signpost", "Check auction behaviour if auctioned", "Tune", "Record"], f"{le} tuned") for le in X1_LE] +
            [(f"X1 event review {ev}", [f"Trigger {ev} and watch NPC/market reactions", "Check signposting", "Tune", "Record"], f"{ev} reviewed") for ev in X1_EV] +
            [(f"X1 NPC review {X1_NB[k]}-{X1_NB[k + 1]}", ["Watch schedules over 3 days", "Check reactions and memory", "Fix data", "Record"], "NPCs reviewed") for k in range(0, 12, 2)] +
            [(f"X1 item set review {s}", [f"Check {s} bonuses with `/balance-check`", "Check crafting value rule", "Tune", "Record"], f"{s} balanced") for s in X1_IS] +
            [(f"X1 build balance {a}", [f"Check {a} with X1 items", "No trivialisation of bosses", "Tune", "Record"], f"{a} ok") for a in ARCHETYPES],
            ["X1 item dominates a base build"], "production/qa/y9/balance/")
    ph.spec("secondary", "X1 review, playtests and release", "§9 Y9", ["fun", "release", "marketing", "legal"],
            [(f"X1 playtest {cs}", [f"Run `/playtest-report` on external playtest notes for {cs}", "Separate bugs and design", "Act", "Record"], f"{cs} playtest actioned") for cs, _, _ in X1_CS] +
            [(f"X1 fun pass {n}", [f"Play {n} for 3 hours as a new player", "Note pacing and reward feel", "Fix data", "Record"], f"{n} fun pass done") for _, n in X1_REG] +
            [(f"X1 cinematics review {st}", [f"Review {st} cinematics in EN/zh-Hans", "Request fixes", "Approve", "Record"], f"{st} cinematics approved") for st in X1_ST] +
            [(f"X1 loc review {lb}", [f"Sign off {lb} after LQA", "Resolve disputes", "Spot-check", "Record"], f"{lb} signed off") for lb in X1_LB] +
            [("X1 fairness survey", ["Survey on X1 bosses and deadlines", "Analyse", "Actions", "Record"], "Survey done"),
             ("X1 accessibility review", ["Check X1 with AX settings", "Fix list", "Approve", "Record"], "A11y approved"),
             ("X1 ratings check", ["Check if X1 content changes ratings (check current rules)", "Update questionnaires if needed", "Record", "Notify partner"], "Ratings current"),
             ("X1 store pages", ["DLC store pages PC + A/B/C (check current rules)", "zh-Hans", "Submit", "Record"], "Pages approved"),
             ("X1 trailer", ["Script and approve the X1 trailer", "Check footage", "Publish", "Record"], "Trailer live"),
             ("X1 marketing beat L-30", ["Announce date", "Post", "Track", "Log"], "L-30 done"),
             ("X1 marketing beat L-7", ["Previews and keys (check current rules)", "Post", "Track", "Log"], "L-7 done"),
             ("X1 release day community", ["Post", "Watch", "Tag issues", "Log"], "Day 0 done"),
             ("X1 release +3 community", ["Status post", "FAQ", "Log", "Plan"], "+3 done"),
             ("X1 release +7 review", ["Sales and reviews", "Issues", "Actions", "Record"], "+7 review done"),
             ("X1 retrospective", ["Run `/retrospective` for X1 content", "List changes for X2", "Record", "Archive"], "Retro done")],
            ["Embargo leak"], "production/expansion1/")
    ph.fam("secondary", "Post-launch limited-edition calendar (year 2)", "P7b", ["economy", "items"], LE_Y9,
           lambda le: f"Limited-edition release {le} design",
           lambda le: [f"Define {le}: slot, rarity, stock, place and time", "Check economy rules and advance signposting", "Request art/writing", f"Record `design/live/{le}.md`"],
           lambda le: f"{le} designed", ["Collision with an X1 limited edition"], "design/live/")
    ph.spec("secondary", "Leaderboards community and Y9 reviews", "§9 optional leaderboards; operating rhythm", ["marketing", "team", "business"], [
        ("Speedrun community rules", ["Draft category rules with community runners", "Publish", "Set moderation", "Record"], "Rules published"),
        ("Leaderboard comms", ["Announce boards and opt-in", "Explain verification", "Post", "Record"], "Announced"),
        ("Leaderboard moderation review", ["Review flagged entries", "Apply rules", "Record", "Adjust"], "Moderation reviewed"),
        ("Seasonal events review spring", ["Review festival data", "Tune", "Record", "Plan"], "Spring reviewed"),
        ("Seasonal events review summer", ["Review festival data", "Tune", "Record", "Plan"], "Summer reviewed"),
        ("Seasonal events review autumn", ["Review festival data", "Tune", "Record", "Plan"], "Autumn reviewed"),
        ("Seasonal events review winter", ["Review festival data", "Tune", "Record", "Plan"], "Winter reviewed")],
        ["Cheated leaderboard entry"], "production/live/")
    ph.add_series("secondary", [Phase.T("secondary", f"Y9 month {m:02d}: business and team review", "Risk: funding, burnout, key person", ["business", "team"],
                                        [D(f"Y9 month {m:02d} business and team review", [f"Review sales by platform and DLC attach rate for month {m:02d}", "Update runway forecast", "Check team load and energy",
                                                                                         f"Record `production/business/y9_m{m:02d}.md`"], f"Y9 month {m:02d} recorded")],
                                        ["Platform payout delay"], "production/business/") for m in range(1, 13)])
    ph.add_series("secondary", [Phase.T("secondary", f"Y9 dev update #{k}", "Community", ["marketing"],
                                        [D(f"Y9 dev update #{k}", [f"Draft Y9 dev update #{k} with writing", "No uncommitted dates", "Publish EN + zh-Hans", "Collect replies"], f"Y9 update #{k} published")],
                                        ["Update reveals unannounced content"], "production/community/") for k in range(1, 9)])
    ph.spec("secondary", "Y9 retrospective and Expansion 2 choice", "§9 Y10 Expansion 2", ["team", "business", "story"], [
        ("Y9 retrospective", ["Run `/retrospective` for Y9", "Collect team input", "Actions", "Record"], "Retro done"),
        ("Expansion 2 candidates", ["List remaining blueprint kingdoms from `design_archive/`", "Score by canon fit, cost, player demand", "Prepare options", "Record"], "Options ready"),
        ("Expansion 2 decision", ["User chooses the X2 region (becomes X2-R11)", "Record ADR", "Update Y10 plan", "Brief team"], "X2 region chosen"),
        ("Y10 plan draft", ["Draft Y10: X2, Story+ extensions, NG+ cycles, retrospective, sequel decision", "Capacity check", "Record", "Share"], "Y10 plan drafted")],
        ["No canon material for remaining kingdoms"], "production/milestones/y9_retro.md", where="tail")
    ph.set_filler("secondary", Filler(
        lambda i: D(f"Player support follow-up PS9-{i + 1:03d}: {['PC', 'console A', 'console B', 'console C'][i % 4]} {SYSTEMS[(i // 4) % 15]}",
                    [f"Review support tickets for {['PC', 'console A', 'console B', 'console C'][i % 4]} tagged {SYSTEMS[(i // 4) % 15]}", "Answer with workarounds", "Update FAQ", "Tag recurring items for triage"],
                    f"PS9-{i + 1:03d} answered"),
        lambda n: f"Player support follow-up block {n:02d}", "Live support", ["release", "ux"], ["Ticket asking for a save edit (give guidance only)"], "production/community/support/", "secondary"), 5)

    # ============================== ART ==============================
    for p, n in PLATFORMS:
        ph.spec("art", f"Console launch art: {n}", "§9 console launches", ["marketing", "art"], [
            (f"{p} store art final", [f"Finalise {n} store art (check current specs)", "Approve", "Export", "Archive"], f"{p} store art final"),
            (f"{p} launch social set", ["Produce launch images", "EN + zh-Hans", "Approve", "Archive"], f"{p} social set"),
            (f"{p} UI follow-up fixes 1", [f"Fix {n} UI art issues from launch feedback", "Check TV distance", "Capture", "Close"], f"{p} UI fixes 1"),
            (f"{p} UI follow-up fixes 2", ["Fix remaining UI art issues", "Check zh-Hans", "Capture", "Close"], f"{p} UI fixes 2")],
            ["Platform badge rules"], f"production/marketing/console/{p}/")
    ph.fam("art", "X1 tileset production", "AGENTS.md art pipeline: builder, preview, controlled import, acceptance", ["art", "assets", "openworld"], [(cs, r, n, k) for cs, r, n in X1_CS for k in ("final tiles", "props and decals", "night palette")],
           lambda u: f"{u[0]} {u[3]}",
           lambda u: [f"Produce {u[3]} for {u[0]} ({u[2]}) through the controlled builder", "Preview-only Godot validation first", "Record provenance (ComfyUI: Yes/No/Unproven with evidence)", f"Capture `production/qa/evidence/y9/art/{u[0]}_{u[3].split()[0]}.png`"],
           lambda u: f"{u[0]} {u[3]} preview-validated", ["Seam mismatch with base region tiles"], "production/qa/evidence/y9/art/", chunk=9)
    ph.spec("art", "X1 controlled production import and acceptance", "AGENTS.md: controlled import + actual scene acceptance; fallbacks preserved", ["art", "assets", "tests"],
            [(f"{n} controlled production import", [f"Import accepted {n} previews into production with fallbacks", "Run fallback/rollback checks", "Protected baselines untouched", "Record"], f"{n} imported") for _, n in X1_REG] +
            [(f"{n} scene acceptance", [f"Live viewport screenshots of {n} chunk sets", "Distinguish live vs headless captures", "User accepts or returns", "Record"], f"{n} accepted") for _, n in X1_REG],
            ["Rollback needed after import"], "docs/art_pipeline/x1_import.md")
    ph.fam("art", "X1 bosses, enemies and NPCs final art", "P2/P4", ["art", "animation"],
           [(b, k) for b, _ in X1_BOSSES for k in ("final animation set", "Hell phase variant", "hit/hurt polish", "export and import")] + [(e, k) for e, _ in X1_ENEMIES for k in ("final animation", "import and tell check")] +
           [(f"{X1_NB[k]}-{X1_NB[k + 1]}", "final sprites") for k in range(0, 12, 2)],
           lambda u: f"{u[0]} {u[1]}",
           lambda u: [f"Complete {u[1]} for {u[0]}", "Match frame data from primary", "Check colourblind readability", "Capture evidence"],
           lambda u: f"{u[0]} {u[1]} done", ["Animation length differs from frame data"], "production/qa/evidence/y9/art/", chunk=8)
    ph.fam("art", "X1 items, VFX, cinematics and endings", "P7e/P9/P3", ["items", "vfx", "cinematics", "art"],
           [(s, k) for s in X1_IS for k in ("icons", "weapon/overlay sprites")] + [(f"X1 VFX set {k}", "hazards and boss effects") for k in range(1, 9)] +
           [(st, f"cinematic art {k}") for st in X1_ST for k in (1, 2, 3)] + [(st, "ending slide art") for st in X1_ST] + [(st, "Story+ slide art") for st in X1_ST] +
           [(b, "Hell cosmetic/title art") for b, _ in X1_BOSSES],
           lambda u: f"{u[0]} {u[1]}",
           lambda u: [f"Produce {u[1]} for {u[0]}", "Check against bible and readability", "Import with fallback", "Capture"],
           lambda u: f"{u[0]} {u[1]} delivered", ["Reduced-flash variant missing"], "production/qa/evidence/y9/art/", chunk=8)
    ph.spec("art", "X1 marketing, map and accessibility art", "§9 Y9 marketing; UX", ["marketing", "ui", "accessibility"],
            [(f"X1 {x}", [f"Produce X1 {x}", "Check current specs where relevant", "Approve", "Archive"], f"X1 {x} done") for x in ["key art sketch", "key art final", "capsules", "trailer cards", "screenshots Human Patch Lab", "screenshots Forgotten Sectors", "press kit art", "social set"]] +
            [(f"X1 map art {n}", [f"Add {n} to the world map with fog of war", "Waystation and POI markers", "Check colourblind", "Capture"], f"{n} map art") for _, n in X1_REG] +
            [(f"X1 accessibility art check {n}", [f"Check {n} in colourblind and high-contrast modes", "Fix", "Capture", "Record"], f"{n} a11y art ok") for _, n in X1_REG] +
            [(f"X1 asset audit {n}", [f"Run `/asset-audit` on {n} assets", "Fix naming/size", "Remove orphans with approval", "Record"], f"{n} audit clean") for _, n in X1_REG] +
            [("Leaderboard/speedrun UI art", ["Boards screen art", "Timer HUD art", "Approve", "Archive"], "Boards art done")],
            ["Spoiler in X1 key art"], "production/marketing/x1/")
    ph.fam("art", "Limited-edition art (year 2) and social", "P7b; live marketing", ["items", "marketing", "art"], [(le, "item art") for le in LE_Y9] + [(f"month {m:02d}", "social set") for m in range(1, 13)],
           lambda u: f"Y9 {u[0]} {u[1]}",
           lambda u: [f"Produce {u[1]} for {u[0]}", "Check readability / spoilers", "Approve", "Archive"],
           lambda u: f"Y9 {u[0]} {u[1]} done", ["Item art clashes with X1 palette"], "assets/items/live/", chunk=8)
    ph.set_filler("art", Filler(
        lambda i: D(f"Live art fix AF9-{i + 1:03d}: {(REGIONS[i % 8][0] + ' ' + REGIONS[i % 8][1]) if i % 3 else X1_REG[(i // 3) % 2][1]} {['tiles', 'props', 'sprites', 'UI art', 'VFX', 'icons'][(i // 8) % 6]}",
                    [f"Pull reported art issues for {(REGIONS[i % 8][0]) if i % 3 else X1_REG[(i // 3) % 2][1]} {['tiles', 'props', 'sprites', 'UI art', 'VFX', 'icons'][(i // 8) % 6]}", "Fix top 4 (baselines protected)", "Import and fallback check", "Close tickets"],
                    f"AF9-{i + 1:03d} closed"),
        lambda n: f"Live art fixes block {n:02d}", "Live support", ["art", "assets"], ["Fix needs collision change (not allowed)"], "production/qa/evidence/y9/art/", "art"), 5)

    # ============================== AUDIO ==============================
    ph.fam("audio", "X1 music production", "P9 adaptive music; §3 music budget extended", ["music", "audio"],
           [(mt, s) for mt in X1_MT[3:] for s in ("A section", "B section", "adaptive layers", "mix", "master and review")] + [(mt, s) for mt in X1_MT[:3] for s in ("adaptive integration", "final master")] +
           [(b, s) for b, _ in X1_BOSSES for s in ("arena stems", "Hell-phase variant")],
           lambda u: f"{u[0]} {u[1]}",
           lambda u: [f"Work on {u[1]} for {u[0]}", "Check against X1 audio direction", "Export and integrate in preview", "Log provenance"],
           lambda u: f"{u[0]} {u[1]} done", ["Loop seam on layer switch"], "assets/audio/expansion1/", chunk=6)
    ph.fam("audio", "X1 SFX, ambience and boss audio", "P9; P6 audio tells", ["audio", "combat"],
           [(sb, s) for sb in X1_SB for s in ("finalise", "integrate")] + [(f"X1-SB-{k:02d}", s) for k in range(5, 9) for s in ("design", "edit", "mix", "integrate")] +
           [(cs, "ambience integration") for cs, _, _ in X1_CS] + [(cs, "NPC crowd and footsteps") for cs, _, _ in X1_CS] +
           [(b, s) for b, _ in X1_BOSSES for s in ("tell cues", "Hell-phase cues", "hit and death")] + [(e, "enemy audio") for e, _ in X1_ENEMIES] +
           [(f"{X1_EV[k]}-{X1_EV[k + 1]}", "event stingers") for k in range(0, 8, 2)] + [(st, f"cinematic audio {k}") for st in X1_ST for k in (1, 2)] +
           [(n, f"mix pass {k}") for _, n in X1_REG for k in (1, 2, 3)] + [("X1 trailer", s) for s in ("cue edit", "mix", "loudness", "stems")] + [("X1 haptics", s) for s in ("bosses", "hazards", "events", "UI")],
           lambda u: f"{u[0]} {u[1]}",
           lambda u: [f"Do {u[1]} for {u[0]}", "Check audibility over music and AX06 mapping", "Integrate and test in game", "Log provenance"],
           lambda u: f"{u[0]} {u[1]} done", ["Cue masked in a dense event"], "production/qa/y9/audio/", chunk=8)
    ph.fam("audio", "Base game audio refresh and console follow-ups", "Long-tail quality; P7f seasons", ["audio", "music"],
           [(r, f"seasonal music variant {se}") for r, _, _ in REGIONS for se in SEASONS] + [(r, f"audio refresh {k}") for r, _, _ in REGIONS for k in (1, 2)] +
           [(p, f"console audio fixes {k}") for p, _ in PLATFORMS for k in (1, 2)] + [(f"festival {se}", "stingers") for se in ("spring", "summer", "autumn", "winter")] +
           [(f"{m} {mn}", "music refresh") for m, mn in MINIGAMES] + [("speedrun timer", "sounds"), ("leaderboard UI", "sounds"), ("X1 captions list", "hand-off"), ("loudness CI check", "tooling"),
                                                                    ("Story+ extension", "music groundwork 1"), ("Story+ extension", "music groundwork 2"), ("OST vol. 2", "planning"), ("OST vol. 2", "metadata")],
           lambda u: f"{u[0]} {u[1]}",
           lambda u: [f"Work on {u[1]} for {u[0]}", "Check mix against the bus targets", "Integrate/test", "Record"],
           lambda u: f"{u[0]} {u[1]} done", ["Seasonal variant during a festival"], "production/qa/y9/audio/", chunk=8)
    ph.set_filler("audio", Filler(
        lambda i: D(f"Live audio fix AUF9-{i + 1:03d}: {['PC', 'console A', 'console B', 'console C'][i % 4]} {['ambience', 'combat SFX', 'UI sounds', 'music transitions', 'world events', 'cutscene audio'][(i // 4) % 6]}",
                    [f"Pull reported audio issues: {['PC', 'console A', 'console B', 'console C'][i % 4]} {['ambience', 'combat SFX', 'UI sounds', 'music transitions', 'world events', 'cutscene audio'][(i // 4) % 6]}", "Fix top 4", "Re-test on that platform", "Close"],
                    f"AUF9-{i + 1:03d} closed"),
        lambda n: f"Live audio fixes block {n:02d}", "Live support", ["audio"], ["Issue only on TV speakers"], "production/qa/y9/audio/", "audio"), 5)

    # ============================== WRITING ==============================
    ph.fam("writing", "X1 dialogue revision and final text", "P5/P3; VOICE_GUIDE", ["dialogue", "quests", "story"],
           [(q, "revision") for q, _ in X1_SQ] + [(f"{st}-SCN{k}", "final") for st in X1_ST for k in range(1, 5)] + [(st, f"ending slides {k}") for st in X1_ST for k in (1, 2)] +
           [(f"{X1_NB[k]}-{X1_NB[k + 1]}", "barks final") for k in range(0, 12, 2)] + [(f"X1 codex {k}", "final") for k in range(1, 5)] + [(f"{X1_IS[k]}-{X1_IS[k + 1]}", "item text final") for k in range(0, 8, 2)] +
           [(q, "TQ text final") for q, _ in X1_TQ] + [(s, "secret text final") for s in X1_SC] + [(nb, "mini-arc dialogue") for nb in X1_NB] + [(f"X1 quest log and tutorial {k}", "text") for k in range(1, 5)],
           lambda u: f"{u[0]} {u[1]}",
           lambda u: [f"Write/revise {u[1]} for {u[0]} in `.dlg`/string tables", "Check canon and VOICE_GUIDE", "Add zh-Hans context notes", "Commit"],
           lambda u: f"{u[0]} {u[1]} committed", ["Line references a base storyline the player may not have"], "string tables", chunk=8)
    ph.fam("writing", "X1 in base-game Story+ variants", "P8 Story+ reflects state; X1 hooks per storyline", ["story", "dialogue"], STORYLINES,
           lambda s: f"X1 Story+ lines for {s['sid']}",
           lambda s: [f"Write the Story+ slide/bark lines that reflect X1 outcomes in {s['sid']}", "Keep additive: base text unchanged when X1 not owned", "Check composer variables", "Commit"],
           lambda s: f"{s['sid']} X1 lines committed", ["X1 completed after the final boss"], "string tables", chunk=9)
    ph.fam("writing", "X1 localization source prep", "§3 languages", ["localization"], [(lb, k) for lb in X1_LB for k in ("source freeze", "LQA response")],
           lambda u: f"{u[0]} {u[1]}",
           lambda u: [f"{'Freeze and export ' + u[0] + ' with context notes' if u[1] == 'source freeze' else 'Fix source issues from ' + u[0] + ' LQA'}", "Glossary check", "Placeholders check", "Record"],
           lambda u: f"{u[0]} {u[1]} done", ["Term not in glossary"], "docs/localization/batches/")
    ph.fam("writing", "Console, X1 and live copy", "Launch and live comms", ["marketing", "release", "localization"],
           [(p, k) for p, _ in PLATFORMS for k in ("launch copy", "FAQ")] + [("X1", k) for k in ("store copy", "press release", "trailer cards", "FAQ", "support macros", "achievement text")] +
           [(p, "notes + zh-Hans delta") for p in PATCHES] + [(le, "lore text") for le in LE_Y9] + [(f"dev update #{k}", "copy") for k in range(1, 9)] + [("speedrun", "rules text"), ("leaderboards", "opt-in and privacy text")],
           lambda u: f"{u[0]} {u[1]}",
           lambda u: [f"Write {u[1]} for {u[0]}", "Check tone and accuracy with the team", "zh-Hans version", "Hand to secondary"],
           lambda u: f"{u[0]} {u[1]} ready", ["Copy promises a date"], "production/community/", chunk=8)
    ph.fam("writing", "Y10 narrative pre-production", "§9 Y10 Story+ extensions and Expansion 2", ["story", "docs"],
           [(c, "outline") for c, _, _ in SPX] + [(f"X2 structure {k}", "outline") for k in range(1, 7)] + [(n, "voice review") for _, n in X1_REG for _k in (1,)] + [("writing pipeline docs", "update"), ("glossary", "X1 terms final")],
           lambda u: f"{u[0]} {u[1]}",
           lambda u: [f"Draft {u[1]} for {u[0]} (structure and IDs; no new canon without user approval)", "Check against STORY_BIBLE", "List open questions", "Store"],
           lambda u: f"{u[0]} {u[1]} drafted", ["Story+ case contradicts an ending family"], "design/y10/", chunk=8)
    ph.set_filler("writing", Filler(
        lambda i: D(f"Live text fix WF9-{i + 1:03d}: {(REGIONS[i % 8][0]) if i % 3 else X1_REG[(i // 3) % 2][1]} {['typos', 'overflow', 'continuity', 'tone', 'missing keys', 'console terms'][(i // 8) % 6]}",
                    [f"Pull text issues for {(REGIONS[i % 8][0]) if i % 3 else X1_REG[(i // 3) % 2][1]} {['typos', 'overflow', 'continuity', 'tone', 'missing keys', 'console terms'][(i // 8) % 6]}", "Fix EN and zh-Hans", "Verify in game", "Close"],
                    f"WF9-{i + 1:03d} closed"),
        lambda n: f"Live text fixes block {n:02d}", "Live support", ["dialogue", "localization"], ["Fix in an achievement string"], "string tables", "writing"), 5)

    # ============================== QA ==============================
    for k, (p, n) in enumerate(PLATFORMS):
        t = ph.spec("qa", f"Console launch QA: {n}", "§9 console launches", ["tests", "release"], [
            (f"{p} submission run 1", [f"Run all CC01-CC10 cases on the {p} submission build", "Log", "Video evidence", "Report"], f"{p} run 1 done"),
            (f"{p} submission run 2", ["Run critical path Acts 1-2", "Run Hell replay sample", "Log", "Report"], f"{p} run 2 done"),
            (f"{p} submission run 3", ["Run Acts 3-4 + Story+", "Run save-compat sample", "Log", "Report"], f"{p} run 3 done"),
            (f"{p} cert retest 1", ["Retest failed cases", "Log", "Report", "Sign off"], f"{p} retest 1"),
            (f"{p} cert retest 2", ["Retest remaining", "Regression around fixes", "Log", "Sign off"], f"{p} retest 2"),
            (f"{p} retail smoke 1", ["Install retail build", "Smoke test", "Check day-one patch", "Report"], f"{p} retail smoke 1"),
            (f"{p} retail smoke 2", ["Check entitlement, achievements, saves", "Log", "Report", "Archive"], f"{p} retail smoke 2"),
            (f"{p} launch repro day 1", ["Reproduce top reports", "Attach saves", "Log", "Report"], f"{p} repro 1"),
            (f"{p} launch repro day 2", ["Reproduce top reports", "Verify fixes", "Log", "Report"], f"{p} repro 2"),
            (f"{p} launch repro day 3", ["Verify day-one/hotfix", "Regression", "Log", "Report"], f"{p} repro 3")],
            ["Retail firmware newer than devkit"], f"production/console/{p}/qa_launch.md")
        ph.anchor(t, [0.10, 0.28, 0.48][k])
    ph.fam("qa", "X1 content tests", "P5/P3/P6 for X1", ["tests", "quests", "difficulty"],
           [(q, "quest test") for q, _ in X1_SQ] + [(q, "timing test") for q, _ in X1_TQ] + [(s, "secret test") for s in X1_SC] +
           [(st, f"matrix row part {k}") for st in X1_ST for k in (1, 2, 3)] + [(f"{b} {d['diff']}", "boss test") for b, _ in X1_BOSSES for d in DIFFS] +
           [(cs, "traversal and streaming test") for cs, _, _ in X1_CS],
           lambda u: f"X1 {u[1]}: {u[0]}",
           lambda u: [f"Execute the {u[1]} for {u[0]}", "Try odd orders, pauses and save/load at awkward moments", "Log bugs with saves and video", "Record"],
           lambda u: f"X1 {u[0]} {u[1]} done", ["DLC not owned while mid-quest"], "production/qa/y9/x1/", chunk=8)
    ph.fam("qa", "X1 systems, platforms and live regression", "X1 quality on every platform", ["tests", "economy", "save", "localization", "performance"],
           [(p, f"regression {k}") for p in PATCHES for k in (1, 2)] + [(f"{p} patch {k}", "console parity regression") for p, _ in PLATFORMS for k in range(1, 5)] +
           [(f"{p} patch {k}", "console Hell replay check") for p, _ in PLATFORMS[:2] for k in (1, 2)] +
           [(f"{X1_CM[k]}-{X1_CM[k + 3]}", "exploit check") for k in range(0, 16, 4)] + [(f"{X1_EV[k]}-{X1_EV[k + 1]}", "event check") for k in range(0, 8, 2)] +
           [(x, "X1 save migration test") for x in ("pre-X1 saves", "X1 without DLC", "refund case", "Story+ entry")] + [(lb, f"LQA {k}") for lb in X1_LB for k in (1, 2)] +
           [(f"{n} on {x}", "perf check") for _, n in X1_REG for x in ("PC", "A/B", "C", "Deck")] + [(x, "DLC entitlement test") for x in ("PC", "A", "B", "C")] +
           [("X1", "accessibility pass 1"), ("X1", "accessibility pass 2"), ("leaderboards", "test 1"), ("leaderboards", "test 2"), ("speedrun timer", "test 1"), ("speedrun timer", "test 2")] +
           [(f"{g[0]['sid']}-{g[-1]['sid']}", "X1 entry test") for g in [STORYLINES[i:i + 3] for i in range(0, 27, 3)]] +
           [(f"X1 fairness session {k}", "survey") for k in range(1, 5)] + [(hw, "X1 hardware check") for hw in ("low tier GPU", "8 GB RAM", "Deck", "4K TV")],
           lambda u: f"{u[1]}: {u[0]}",
           lambda u: [f"Run the {u[1]} for {u[0]}", "Compare with expected results", "Log bugs with evidence", "Record"],
           lambda u: f"{u[0]} {u[1]} done", ["Patch lands on PC before consoles"], "production/qa/y9/", chunk=8)
    ph.set_filler("qa", Filler(
        lambda i: D(f"Community bug repro CB9-{i + 1:03d}: {['PC', 'console A', 'console B', 'console C'][i % 4]} x {SYSTEMS[(i // 4) % 15]}",
                    [f"Reproduce community reports for {SYSTEMS[(i // 4) % 15]} on {['PC', 'console A', 'console B', 'console C'][i % 4]}", "Add repro steps and saves", "Mark cannot-reproduce with what was tried", "Update triage"],
                    f"CB9-{i + 1:03d} processed"),
        lambda n: f"Community bug repro block {n:02d}", "Live support", ["tests"], ["Report from modded install"], "Issue tracker", "qa"), 5)
    add_extra(ph)
    reorder(ph)
    return ph


if __name__ == "__main__":
    print(build().counts())
