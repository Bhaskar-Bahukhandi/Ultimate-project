"""Y10: Expansion 2, Story+ extensions, NG+ cycles, retrospective, sequel decision (2035-10-01 -> 2036-10-18)."""
from late_common import *
from late_y10_extra import add_extra, reorder

CAPS = {"primary": 330, "secondary": 384, "art": 274, "audio": 274, "writing": 274, "qa": 274}
PATCHES = ["2.1.0", "2.2.0", "2.3.0", "2.4.0", "2.5.0", "3.0.0 (Expansion 2 + Story+ ext + NG+)", "3.0.1", "3.1.0"]
LE_Y10 = [f"LE-P{k:02d}" for k in range(25, 37)]
X2N = "X2-R11 (region chosen at the Y9 retrospective)"


def build():
    ph = Phase("Y10", "Expansion 2, Story+ extensions, NG+ cycles and the decade decision",
               "Expansion 2, Story+ extensions for all four ending families and NG+ cycles with remixed bosses and markets ship on every platform; the 10-year retrospective is written and the sequel / new IP / continued-support decision is recorded with a handover-ready codebase.",
               ["3.0.0 ships on PC + A/B/C: X2-R11 (8 chunk sets, X2-B29..B31, X2-E57..E60, 15 side quests, 5 TQs, 12 goods, 6 events, 10 Tier B NPCs), 12 Story+ extension cases, NG+1..NG+3",
                "28 remixed bosses validated by Hell input replay in every NG+ cycle (perfect wins, +/-1 frame loses)",
                "1000-day economy sim passes for every storyline in NG+1..NG+3 with remixed markets",
                "Save-compat CI loads every save since EA (10-year fixture archive) incl. NG+ carryover saves",
                "10-year retrospective published; decision ADR (sequel / new IP / continued support) recorded",
                "Handover pack: runbooks verified on a clean machine, backups restored, maintainer docs complete"],
               CAPS)

    # ============================== PRIMARY ==============================
    ph.spec("primary", "Y10 kickoff", "ROADMAP §9 Y10", ["team", "release"], [
        ("Y10 kickoff: plan", ["Confirm Y10 scope: X2, Story+ extensions, NG+ cycles, retrospective, decision", "Set 3.0.0 target window with the partner's console lead times (check current)", "Run `/sprint-plan`", "Publish `production/milestones/y10_plan.md`"], "Y10 plan published"),
        ("Y10 kickoff: risks and cut list", ["Update risk register (burnout in year 10, key-person risk)", "Cut list: X2 side quests 15 -> 10, NG+3 optional", "Assign owners", "Record"], "Risks and cuts recorded")],
        ["Partner capacity reduced"], "production/milestones/y10_plan.md", where="head")
    ph.spec("primary", "NG+ cycle framework", "§9 Y10: NG+ cycles with remixed bosses and markets", ["systems", "save", "difficulty", "architecture", "time"], [
        ("NG+ ADR final", ["Finalise ADR: NG+1..NG+3 cycle counter, carryover (stats/items/titles), what resets (story, WorldClock, market)", "Difficulty interaction: cycle stacks remix, never narrows Hell frame windows below 2 f", "Get explicit approval for the save schema change", "Merge ADR"], "ADR approved"),
        ("NG+ cycle state", ["Implement `NgPlusService` owning cycle number and carryover rules", "Expose remix hooks for bosses and markets", "Unit tests", "Doc comments"], "Service implemented"),
        ("NG+ save migration", ["Add the NG+ save block with migration and fixtures", "Old saves load with cycle 0", "save-compat CI updated", "Tests"], "Migration green"),
        ("NG+ start flow", ["Start NG+ from Story+ or the final save", "Confirm screen lists carryover/reset", "ContextStack-safe transition", "Test"], "Flow works"),
        ("NG+ StoryGraph reset", ["Reset StoryGraph/FlagRegistry with carryover flags whitelisted", "Keep Story+ history for titles", "Reachability test across 27 storylines", "Record"], "Reset correct"),
        ("NG+ edge cases", ["NG+ started mid-deadline", "X1/X2 DLC owned/not owned", "Difficulty lowered in NG+", "Tests"], "Edge cases tested")],
        ["Carryover item that breaks the economy", "NG+ started on a platform without DLC"], "docs/architecture/ADR NG+ + tests/unit/ngplus/")
    ph.fam("primary", "Expansion 2: chunk sets", "§9 Y10 Expansion 2; P7a", ["openworld", "level", "performance"], X2_CS,
           lambda cs: f"Integrate {cs} into the streamed world",
           lambda cs: [f"Import accepted {cs} chunks after controlled production import", "Wire seams; streaming hitch < 2 ms", "Map markers and waystation", f"Test `tests/integration/streaming/test_{cs.lower().replace('-', '_')}.gd`"],
           lambda cs: f"{cs} streams seamlessly", ["Seam with an X1 region"], "tests/integration/streaming/")
    ph.spec("primary", "Expansion 2: bosses, enemies, story and market", "P2/P6/P3/P7b for X2", ["combat", "difficulty", "story", "economy"],
            [(f"{b} {['frame data', 'AI and variants', 'Hell-only phase', 'difficulty wiring + Hell replay'][k - 1]}", [f"{['Author frame data for ' + b, 'Implement ' + b + ' patterns and +variants', 'Implement ' + b + ' Hell-only phase', 'Wire 5 profiles; record perfect Hell replay; run mutants'][k - 1]}", "Fixed tick; no `create_timer`", "Test", f"Record `production/qa/y10/bosses/{b}.md`"], f"{b} step {k} done") for b in X2_BOSSES for k in range(1, 5)] +
            [(f"Enemy {e}", [f"Implement {e} frame data, AI, drops", "Spawn test + invariants", "Arena context test", "Record"], f"{e} done") for e in X2_ENEMIES] +
            [(f"World event {ev}", [f"Implement {ev} on WorldClock", "NPC/market effects", "Seeded test", "Record"], f"{ev} done") for ev in X2_EV] +
            [(f"Market goods {X2_CM[k]}-{X2_CM[k + 3]}", ["Add to ItemDB/market sim with agents", "Check anti-exploit rules", "1000-day sim on 3 storylines", "Record"], "Goods integrated") for k in range(0, 12, 4)] +
            [(f"{st} StoryGraph (day {k})", [f"{'Nodes and x2_* flags for ' + st if k == 1 else 'Composer and Story+ hooks for ' + st}", "Additive only", "Reachability test", "Record"], f"{st} day {k}") for st in X2_ST for k in (1, 2)] +
            [("X2 save migration (approved)", ["Confirm approval", "Add X2 block, DLC-missing behaviour", "Fixtures", "Tests"], "Migration tested"),
             ("X2 save migration CI", ["Add fixtures to save-compat", "Run on all platforms", "Fix", "Record"], "CI green"),
             ("X2 save + NG+ interplay", ["NG+ with X2 progress", "Carryover rules", "Test", "Record"], "Interplay tested"),
             ("X2 save refund/removal", ["DLC removed after progress", "Keep data, block entry", "Test", "Record"], "Removal handled")] +
            [(f"X2 DLC packaging {x}", [f"Build X2 pack for {x}", "Entitlement via PlatformService", "Test owned/not owned", "Record"], f"{x} pack ok") for x in ("PC", "console A", "console B", "console C")] +
            [(f"X2 performance {x}", [f"Profile {X2N} on {x}", "Fix hotspots", "Budgets", "Record"], f"X2 {x} perf ok") for x in ("PC min spec", "consoles A/B", "console C and Deck")] +
            [("QA matrix extension X2", ["Add X2-ST1..ST2 x 5 x 3 cells", "Nightly", "Record", "Dashboard"], "Matrix extended"),
             ("X2 arena generator rules", ["Add terrain-context rules for X2 biomes", "Test 20 contact points", "Transition < 1 s", "Record"], "X2 arenas ok")],
            ["X2 boss on an NG+ cycle"], "production/qa/y10/x2/")
    ph.spec("primary", "Story+ extensions", "P8 Story+; §9 Y10 Story+ extensions", ["story", "systems", "quests"],
            [("Story+ extension framework 1", ["Implement extension state per ending family (Sole/Bound/No Authority/Consent)", "Civic case slots", "Unit tests", "Doc comments"], "Framework part 1"),
             ("Story+ extension framework 2", ["Composer hooks for extension epilogue slides", "Timing flags feed extension scenes", "Tests", "Record"], "Framework part 2"),
             ("Story+ extension framework 3", ["Unlock rules per storyline", "Save block (approved) and migration", "Tests", "Record"], "Framework part 3"),
             ("Story+ extension framework 4", ["Bot support for extension cases", "Reachability test", "Record", "Docs"], "Framework part 4")] +
            [(f"Story+ case {c} ({fn})", [f"Implement {c} scripting hooks, flags and rewards", "Hook into the family's Story+ state", "Bot path test", "Record"], f"{c} implemented") for c, fid, fn in SPX] +
            [(f"Story+ wiring {g[0]['sid']}-{g[-1]['sid']}", [f"Wire extension unlocks and variants for {', '.join(s['sid'] for s in g)}", "Check timing flags shown", "Bot test per storyline", "Record"], f"{g[0]['sid']}-{g[-1]['sid']} wired") for g in [STORYLINES[i:i + 3] for i in range(0, 27, 3)]],
            ["Extension case reached in NG+ with stale flags"], "tests/integration/storyplus/")
    ph.fam("primary", "NG+ remixed bosses", "§9 Y10 NG+ remixed bosses; P6 replay-verified fairness", ["combat", "difficulty", "tests"], ALL_BOSS_IDS,
           lambda b: f"NG+ remix for {b}",
           lambda b: [f"Implement {b}'s NG+ remix (pattern order/combination changes from the secondary spec) in `data/bosses/{b}/ngplus.tres`", "Keep Hell parry 2 f and telegraph rules; remix never shortens a tell below its Hell value",
                      f"Record perfect NG+ Hell replay `tests/fixtures/replays/ngplus/{b}.rpl`; run +/-1 mutants", "Record"],
           lambda b: f"{b} NG+ remix replay-validated", ["Remix pattern unreachable on Beginner"], "tests/fixtures/replays/ngplus/", chunk=7)
    ph.spec("primary", "NG+ remixed markets", "§9 Y10 NG+ remixed markets; §12.6 rules", ["economy", "tests"],
            [(f"Market remix {ah}", [f"Implement NG+ remix config for {ah} (bidder pools, lot calendar)", "Anti-sniping caps intact", "Test", "Record"], f"{ah} remix done") for ah in AHS] +
            [(f"Market remix {cg}", [f"Implement NG+ price/seasonality remix for {cg}", "Sell <= 40% buy rule intact", "Sim check", "Record"], f"{cg} remix done") for cg in CGS] +
            [("Market remix X1 goods", ["Remix X1-CM-01..16", "Rules intact", "Sim", "Record"], "X1 goods remixed"),
             ("Market remix X2 goods", ["Remix X2-CM-01..12", "Rules intact", "Sim", "Record"], "X2 goods remixed")] +
            [(f"NG+ economy sim {cyc} group {k}", [f"Run 1000-day sims for storylines group {k} in {cyc}", "Check inflation with carryover gold", "Fix data", "Record"], f"{cyc} group {k} stable") for cyc in NG_CYCLES for k in (1, 2, 3)] +
            [("NG+ difficulty interaction 1", ["Check NG+ remix on all 5 difficulties", "Leniency values per §12.1", "Test", "Record"], "Interaction checked"),
             ("NG+ difficulty interaction 2", ["DDA behaviour in NG+ Beginner/Easy", "Test", "Record", "Docs"], "DDA ok in NG+")],
            ["Carryover gold triggers exploit alert"], "production/qa/y10/econ/")
    ph.spec("primary", "Console 3.0.0 certification", "Console parity", ["release", "tests"],
            [(f"{p} 3.0.0 {k}", [f"{['Submit 3.0.0 + X2 DLC via partner (check current process)', 'Fix cert feedback', 'Verify approval and release plan'][k - 1]} for {n}", "Run CC07 DLC cases", "Record", "Archive"], f"{p} 3.0.0 step {k}") for p, n in PLATFORMS for k in (1, 2, 3)],
            ["One platform approves late"], "production/console/")
    ph.spec("primary", "Release 3.0.0", "§9 Y10", ["release", "tests"], [
        ("3.0.0 release build", ["Cut `release/3.0.0` with X2, Story+ ext, NG+", "All CI jobs incl. NG+ replays and save-compat", "Archive symbols", "Record"], "3.0.0 built"),
        ("3.0.0 release day", ["Watch crashes, entitlements", "Triage", "Hotfix if needed", "Log"], "Day 0 logged"),
        ("3.0.0 +1", ["Watch data", "Fix top issue", "Log", "Stop at planned time"], "+1 logged"),
        ("3.0.0 +7 review", ["Stability vs 2.x", "Issues list", "Plan 3.0.1", "Record"], "Week review"),
        ("3.0.0 engineering retro", ["Run `/retrospective`", "Changes", "ADRs", "Archive"], "Retro done")],
        ["NG+ save from 3.0.0 loaded in 2.x"], "production/releases/3.0.0.md")
    ph.spec("primary", "Long-term support engineering", "Key-person risk; continued support option", ["tools", "tests", "docs", "code"], [
        ("Test flakiness sweep 1", ["Run `/test-flakiness` over 3 months of CI", "List flaky tests", "Fix root causes", "Record"], "Flaky list fixed part 1"),
        ("Test flakiness sweep 2", ["Fix remaining flaky tests", "No quarantine without an issue", "Record", "CI green 30 runs"], "Flakes cleared"),
        ("CI modernisation 1", ["Review CI runtime per job", "Parallelise slow jobs", "Cache imports", "Record"], "CI faster"),
        ("CI modernisation 2", ["Pin runner images", "Document CI secrets handling (no secrets in repo)", "Record", "Test"], "CI pinned"),
        ("One-command build 1", ["Single script: clone -> import -> test -> export", "Works on a clean machine", "Record", "Docs"], "Script works"),
        ("One-command build 2", ["Add console hand-off step for the partner", "Docs", "Test", "Record"], "Partner hand-off scripted"),
        ("10-year save fixture archive", ["Archive every save fixture since EA with checksums", "Verify all load in HEAD", "Store off-site", "Record"], "Archive verified"),
        ("10-year save fixture docs", ["Document fixture provenance", "Link from schema history", "Review", "Record"], "Docs done"),
        ("Save compat long-term test", ["Load 10 random fixtures per CI run as a smoke", "Alert on failure", "Record", "Docs"], "Smoke added"),
        ("NG+ performance 1", ["Profile remixed boss fights with extra effects", "Fix hotspots", "Record", "Test"], "NG+ perf ok 1"),
        ("NG+ performance 2", ["Profile NG+3 late-game market sim load", "Fix", "Record", "Test"], "NG+ perf ok 2"),
        ("Speedrun/leaderboard maintenance 1", ["Add NG+ categories if ADR allows", "Replay verification for NG+", "Test", "Record"], "NG+ categories"),
        ("Speedrun/leaderboard maintenance 2", ["Review flagged entries tooling", "Fix", "Record", "Docs"], "Tooling ok"),
        ("Speedrun/leaderboard maintenance 3", ["Board reset policy for 3.0.0", "Communicate via secondary", "Record", "Test"], "Policy applied")] +
        [(f"Economy exploit review EX-{k:02d}", [f"Investigate EX-{k:02d}", "Reproduce in sim", "Fix data + invariant", "Ship within one patch"], f"EX-{k:02d} closed") for k in range(13, 21)] +
        [(f"Accessibility follow-up Y10-{k}", [f"Implement request #{k}", "Test", "Evidence", "Record"], f"A11y Y10-{k}") for k in range(1, 5)] +
        [(f"Long-term engine upgrade evaluation {k}", [f"{['Evaluate the newest stable Godot for long-term support (check current)', 'Port branch and run full suite + replays', 'Partner check for console templates', 'Measure perf deltas', 'Record ADR: upgrade or freeze for support'][k - 1]}", "No change to main without ADR", "Record", "Archive"], f"Engine LTS step {k}") for k in range(1, 6)],
        ["Upgrade breaks determinism of replays"], "docs/release/ + ADRs")
    every_year(ph, "Y10", "the 3.0.0 release gate", PATCHES, triage_n=14)
    ph.spec("primary", "Decade retrospective, decision support and handover", "§9 Y10: retrospective, then sequel / new IP / continued support", ["docs", "business", "team", "release"], [
        ("Retrospective data: engineering", ["Collect 10-year metrics: velocity, bug trends, crash-free, save-compat history", "Charts", "Write engineering section", "Record"], "Engineering data written"),
        ("Retrospective data: architecture", ["Review ADRs: which held, which were reversed", "List lessons", "Write", "Record"], "Architecture lessons written"),
        ("Retrospective data: tools", ["Review tools (bot, replay, econ sim) value", "Keep/retire list", "Write", "Record"], "Tools lessons written"),
        ("Decision support: tech reuse", ["Assess what code/tools a sequel or new IP could reuse", "Estimate effort", "Write", "Record"], "Reuse assessment"),
        ("Decision support: support-mode cost", ["Estimate continued-support engineering cost per year", "Risks", "Write", "Record"], "Support cost"),
        ("Decision support: engine path", ["Summarise engine LTS ADR for the decision", "Write", "Record", "Share"], "Engine path summary"),
        ("Support-mode plan", ["Define patch cadence in support mode", "On-call rules", "Write `docs/release/support_mode.md`", "Record"], "Support plan"),
        ("Support-mode tooling", ["Automate crash digest", "Automate save-compat smoke", "Test", "Record"], "Tooling automated"),
        ("Support-mode handover rehearsal", ["A second person runs build, test, release from docs", "Fix gaps", "Record", "Archive"], "Handover rehearsed"),
        ("Archive: source and builds", ["Tag final decade build", "Archive sources, builds, symbols, PAE projects off-site", "Restore test", "Record"], "Archive restored"),
        ("Archive: documents", ["Archive design docs, ADRs, evidence folders", "Index", "Restore test", "Record"], "Docs archived"),
        ("Archive: legal", ["Archive licences, provenance, contracts (private storage)", "Index", "Record", "Verify"], "Legal archived"),
        ("Final engineering sign-off", ["Review handover checklist", "User sign-off", "Record ADR", "Archive"], "Signed off")],
        ["Archive restore fails on one medium"], "production/retrospective/engineering.md", where="tail")
    ph.set_filler("primary", Filler(
        lambda i: D(f"Live fix LF10-{i + 1:03d}: {SYSTEMS[i % 15]} ({['PC', 'console A', 'console B', 'console C'][(i // 15) % 4]})",
                    [f"Take the oldest open `{SYSTEMS[i % 15]}` bug on {['PC', 'console A', 'console B', 'console C'][(i // 15) % 4]}", "Reproduce from save and steps",
                     f"Fix with a test under `tests/unit/{SYS_SLUG[SYSTEMS[i % 15]]}/`", "Queue for the next parity patch"],
                    f"LF10-{i + 1:03d} fixed"),
        lambda n: f"Live fixes block {n:02d}", "Live support", ["code", "tests"], ["Fix behaves differently in NG+"], "Closed issues", "primary"), 5)

    # ============================== SECONDARY ==============================
    ph.spec("secondary", "Y10 kickoff: production plan", "§9 Y10", ["team", "release"], [
        ("Y10 production plan", ["Map X2, Story+ ext and NG+ content to team streams", "Set 3.0.0 content lock", "`/sprint-plan`", "Publish"], "Plan published"),
        ("Y10 decision timeline", ["Plan the retrospective and decision dates", "List inputs needed", "Assign", "Record"], "Timeline set")],
        ["Team member leaving in Y10"], "production/milestones/y10_plan.md", where="head")
    ph.fam("secondary", "X2 level design", "P7a", ["level", "openworld"], [(cs, k) for cs in X2_CS for k in ("block-out", "art pass integration", "polish")],
           lambda u: f"{u[0]} {u[1]}",
           lambda u: [f"{u[1].capitalize()} for {u[0]} in {X2N}", "Traversal gates ability-based", "Day and night walk", f"Capture `production/qa/evidence/y10/level/{u[0]}_{u[1].split()[0]}.png`"],
           lambda u: f"{u[0]} {u[1]} done", ["Collision change needed (explicit approval)"], "production/qa/evidence/y10/level/", chunk=8)
    ph.fam("secondary", "X2 quests and storylines", "P5/P3", ["quests", "story"], X2_SQ + X2_TQ + [f"{st}-SCN{k}" for st in X2_ST for k in range(1, 5)],
           lambda q: f"Integrate {q}",
           lambda q: [f"Build {q} from design + writer `.dlg`", "Flags, rewards and timing rules", "Play end to end on Medium", f"Record `production/qa/y10/quests/{q}.md`"],
           lambda q: f"{q} playable", ["Quest start blocked in NG+"], "production/qa/y10/quests/", chunk=7)
    ph.fam("secondary", "X2 boss tuning", "P2/P6", ["combat", "difficulty"], [(b, d) for b in X2_BOSSES for d in DIFFS],
           lambda u: f"{u[0]} on {u[1]['diff']}",
           lambda u: [f"Confirm {u[0]} reads parry {u[1]['parry']} f, i-frames {u[1]['iframes']}, telegraph {u[1]['tele']}, damage {u[1]['dmg']}, {u[1]['heals']} charges", f"Play 3 times on {u[1]['diff']} ({u[1]['pat']})", "Data-only changes", f"Record `production/qa/y10/balance/{u[0]}_{u[1]['d']}.md`"],
           lambda u: f"{u[0]} {u[1]['diff']} signed off", ["Hell-only phase on retry"], "production/qa/y10/balance/", chunk=5)
    ph.spec("secondary", "X2 economy, NPCs, items, cinematics", "P7b/P4/P7e", ["economy", "npc", "items", "cinematics"],
            [(f"X2 goods tuning {X2_CM[k]}-{X2_CM[k + 3]}", ["Read sim", "Tune", "`/balance-check`", "Record"], "Tuned") for k in range(0, 12, 4)] +
            [(f"X2 events review {X2_EV[k]}-{X2_EV[k + 1]}", ["Trigger and watch", "Signposting", "Tune", "Record"], "Reviewed") for k in range(0, 6, 2)] +
            [(f"X2 NPCs {X2_NB[k]}-{X2_NB[k + 1]}", ["Schedules over 3 days", "Reactions", "Fix data", "Record"], "Reviewed") for k in range(0, 10, 2)] +
            [(f"X2 item set {s}", [f"Balance {s}", "Crafting rule", "Tune", "Record"], f"{s} ok") for s in X2_IS] +
            [(f"X2 cinematics {st} {k}", [f"Review {st} cinematics pass {k}", "EN/zh-Hans", "Approve/return", "Record"], f"{st} cin {k}") for st in X2_ST for k in (1, 2)],
            ["X2 item dominates NG+ builds"], "production/qa/y10/")
    ph.spec("secondary", "Story+ extension direction", "P8", ["story", "cinematics", "quests"],
            [(f"{c} {k}", [f"{'Design review of ' + c + ' (' + fn + '): civic case structure, flags, rewards' if k == 'design' else 'Play review of ' + c + ': pacing, tone, family framing'}", "Check STORY_BIBLE and the authorization framing", "Return notes", "Record"], f"{c} {k} done") for c, fid, fn in SPX for k in ("design", "play review")] +
            [(f"Story+ extension review {s['sid']}", [f"Play {s['sid']}'s Story+ with extensions", "Check timing flags and family framing", "File issues", "Record"], f"{s['sid']} reviewed") for s in STORYLINES],
            ["Extension contradicts the base Story+ arc"], "production/qa/y10/storyplus/")
    ph.fam("secondary", "NG+ remix design per boss", "§9 Y10 remixed bosses", ["combat", "difficulty", "fun"], ALL_BOSS_IDS,
           lambda b: f"NG+ remix spec {b}",
           lambda b: [f"Spec {b}'s NG+ remix: pattern recombination, new openers, no new unreadable tells", "Per-cycle intensity (NG+1/2/3)", "Hell constraints kept", f"Record `design/ngplus/{b}.md`"],
           lambda b: f"{b} remix spec ready", ["Remix makes Beginner unwinnable"], "design/ngplus/", chunk=7)
    ph.spec("secondary", "NG+ markets, rules and balance", "§9 Y10", ["economy", "systems", "difficulty"],
            [(f"Market remix spec {ah}", [f"Spec NG+ {ah} remix", "Bidder pools/lots", "Anti-exploit", "Record"], f"{ah} spec") for ah in AHS] +
            [(f"Market remix spec {CGS[k]}-{CGS[k + 1]}", ["Spec seasonality/price remix", "Rules", "Sim request", "Record"], "Spec") for k in range(0, 12, 2)] +
            [(f"{cyc} rules {k}", [f"{'Define ' + cyc + ' carryover/reset rules' if k == 1 else 'Review ' + cyc + ' rules against economy and pillars'}", "Never-cut pillars respected", "Record", "Share"], f"{cyc} rules {k}") for cyc in NG_CYCLES for k in (1, 2)] +
            [(f"NG+ balance on {d['diff']}", [f"Play NG+1 openings on {d['diff']}", "Check carryover power vs remix", "Tune", "Record"], f"NG+ {d['diff']} ok") for d in DIFFS] +
            [(f"NG+ playtest {cyc} {k}", [f"Run `/playtest-report` on {cyc} playtest notes", "Actions", "Record", "Share"], f"{cyc} playtest {k}") for cyc in NG_CYCLES for k in (1, 2)],
            ["Carryover trivialises NG+1"], "design/ngplus/")
    ph.spec("secondary", "X2/Story+/NG+ review and 3.0.0 release", "§9 Y10", ["fun", "release", "marketing", "legal"],
            [(f"X2 playtest {cs}", [f"`/playtest-report` for {cs}", "Bugs vs design", "Act", "Record"], f"{cs} playtest") for cs in X2_CS] +
            [(f"Story+ extension playtest {k}", ["Playtest extension cases", "Collect notes", "Act", "Record"], f"Story+ playtest {k}") for k in range(1, 5)] +
            [(f"X2 {x}", [f"X2 {x}", "Compare with X1 results", "Actions", "Record"], f"X2 {x} done") for x in ("fairness survey", "loc review XLB 1", "loc review XLB 2", "loc review XLB 3", "build balance A", "build balance B", "build balance C")] +
            [("3.0.0 ratings check", ["Check if X2/NG+ content changes ratings (check current rules)", "Update", "Record", "Notify partner"], "Ratings current"),
             ("3.0.0 store pages", ["DLC pages PC + A/B/C", "zh-Hans", "Submit", "Record"], "Pages approved"),
             ("3.0.0 trailer", ["Script/approve trailer", "Check footage", "Publish", "Record"], "Trailer live"),
             ("3.0.0 beat L-30", ["Announce", "Post", "Track", "Log"], "L-30"),
             ("3.0.0 beat L-7", ["Previews/keys (check rules)", "Post", "Track", "Log"], "L-7"),
             ("3.0.0 release day community", ["Post", "Watch", "Tag issues", "Log"], "Day 0"),
             ("3.0.0 +3 community", ["Status", "FAQ", "Log", "Plan"], "+3"),
             ("3.0.0 +7 review", ["Sales/reviews", "Issues", "Actions", "Record"], "+7"),
             ("3.0.0 content retro", ["`/retrospective` for 3.0.0 content", "Lessons", "Record", "Archive"], "Retro done")],
            ["Embargo leak"], "production/expansion2/")
    ph.fam("secondary", "Limited-edition calendar (year 3)", "P7b", ["economy", "items"], LE_Y10,
           lambda le: f"Limited-edition release {le} design",
           lambda le: [f"Define {le}: slot, rarity, stock, place, time", "Economy rules + signposting", "Request art/writing", f"Record `design/live/{le}.md`"],
           lambda le: f"{le} designed", ["Clash with NG+ remix calendar"], "design/live/")
    ph.add_series("secondary", [Phase.T("secondary", f"Y10 month {m:02d}: business and team review", "Risk: funding, burnout, key person", ["business", "team"],
                                        [D(f"Y10 month {m:02d} business and team review", [f"Review sales by platform and DLC for month {m:02d}", "Update runway", "Check team load and energy", f"Record `production/business/y10_m{m:02d}.md`"], f"Y10 month {m:02d} recorded")],
                                        ["Revenue tail lower than forecast"], "production/business/") for m in range(1, 14)])
    ph.add_series("secondary", [Phase.T("secondary", f"Y10 dev update #{k}", "Community", ["marketing"],
                                        [D(f"Y10 dev update #{k}", [f"Draft Y10 dev update #{k}", "No uncommitted dates", "Publish EN + zh-Hans", "Collect replies"], f"Y10 update #{k} published")],
                                        ["Update hints at the undecided sequel"], "production/community/") for k in range(1, 9)])
    ph.spec("secondary", "10-year retrospective and the decade decision", "§9 Y10: retrospective, then sequel / new IP / continued support", ["business", "team", "docs", "story"], [
        ("Retro data: players", ["Collect 10-year player data: sales, reviews, completion, storyline reach, difficulty mix", "Charts", "Write player section", "Record"], "Player section"),
        ("Retro data: production", ["Collect planned vs actual per year from milestones", "Cut order usage", "Write", "Record"], "Production section"),
        ("Retro data: pillars", ["Score each pillar P1-P10 against its measurable definition", "Evidence links", "Write", "Record"], "Pillar scorecard"),
        ("Team retrospective", ["Run `/retrospective` with the whole team", "Collect anonymous input", "Write", "Record"], "Team retro"),
        ("Player-facing retrospective", ["Draft a public 'ten years' post", "Approve", "Publish", "Record"], "Public post"),
        ("Retrospective write-up", ["Assemble `production/retrospective/decade.md`", "Review with team", "Finalise", "Archive"], "Retro written"),
        ("Decision option: sequel", ["Assess sequel: canon threads, reuse, team, cost, market signal", "Risks", "Write option paper", "Record"], "Sequel option"),
        ("Decision option: new IP", ["Run `/brainstorm` for 3 new-IP concepts", "Assess reuse, cost, market", "Write option paper", "Record"], "New IP option"),
        ("Decision option: continued support", ["Assess support mode: cadence, revenue, cost, team", "Risks", "Write option paper", "Record"], "Support option"),
        ("Decision financial model", ["Model funding and runway for each option", "Scenarios", "Record", "Share"], "Model ready"),
        ("Decision prototype plan", ["If sequel/new IP: plan `/prototype` scope for the first 3 months", "Gate criteria", "Record", "Share"], "Prototype plan"),
        ("Decision meeting", ["Present options to the user and team", "User decides", "Record ADR 'After Aethelgard'", "Archive"], "Decision ADR"),
        ("Decision communication 1", ["Tell the team; plan transitions", "Contracts (user)", "Record", "Schedule"], "Team informed"),
        ("Decision communication 2", ["Public announcement draft (if appropriate)", "Approve", "Publish", "Record"], "Announced or deferred"),
        ("Design archive 1", ["Archive GDDs, quick designs, balance sheets", "Index", "Record", "Verify"], "Design archive 1"),
        ("Design archive 2", ["Archive story bible, voice guide, loc glossary", "Index", "Record", "Verify"], "Design archive 2"),
        ("Design archive 3", ["Archive marketing and community records", "Index", "Record", "Verify"], "Design archive 3"),
        ("Design archive 4", ["Final production log", "User sign-off", "Record", "Archive"], "Production archive signed")],
        ["Team split on the decision"], "production/retrospective/decade.md + ADR", where="tail")
    ph.set_filler("secondary", Filler(
        lambda i: D(f"Player support follow-up PS10-{i + 1:03d}: {['PC', 'console A', 'console B', 'console C'][i % 4]} {SYSTEMS[(i // 4) % 15]}",
                    [f"Review tickets for {['PC', 'console A', 'console B', 'console C'][i % 4]} tagged {SYSTEMS[(i // 4) % 15]}", "Answer with workarounds", "Update FAQ", "Tag recurring items"],
                    f"PS10-{i + 1:03d} answered"),
        lambda n: f"Player support follow-up block {n:02d}", "Live support", ["release", "ux"], ["Ticket asks for a save edit (guidance only)"], "production/community/support/", "secondary"), 5)

    # ============================== ART ==============================
    ph.spec("art", "X2 art pre-production", "§9 Y10 Expansion 2", ["art", "assets"],
            [("X2 art bible extension", ["`/art-bible` extension for X2-R11", "Canon only", "Approve", "Store"], "Bible ext"),
             ("X2 asset specs", ["`/asset-spec` for X2 classes", "Truth gate: mark ComfyUI vs PAE vs hand", "Estimate", "Store"], "Specs")] +
            [(f"X2 concept {t}", [f"Concept {t} for {X2N}", "Review", "Iterate", "Store in `assets/art_sources/expansion2/`"], f"{t} concept") for t in ("tiles", "props", "landmarks", "palettes", "bosses", "enemies")],
            ["Concept contradicts canon"], "assets/art_sources/expansion2/")
    ph.fam("art", "X2 tileset production", "AGENTS.md pipeline", ["art", "assets", "openworld"], [(cs, k) for cs in X2_CS for k in ("final tiles", "props and decals", "night palette", "seasonal variant")],
           lambda u: f"{u[0]} {u[1]}",
           lambda u: [f"Produce {u[1]} for {u[0]} via the controlled builder", "Preview-only validation first", "Provenance record (ComfyUI Yes/No/Unproven + evidence)", "Capture"],
           lambda u: f"{u[0]} {u[1]} preview-validated", ["Seam with X1 tiles"], "production/qa/evidence/y10/art/", chunk=8)
    ph.spec("art", "X2 controlled import and acceptance", "AGENTS.md", ["art", "tests"], [
        ("X2 controlled production import", ["Import accepted previews with fallbacks", "Fallback/rollback checks", "Protected baselines untouched", "Record"], "Imported"),
        ("X2 scene acceptance 1", ["Live viewport screenshots CS01-CS04", "Distinguish live vs headless", "User review", "Record"], "Accepted 1"),
        ("X2 scene acceptance 2", ["Live viewport screenshots CS05-CS08", "Distinguish live vs headless", "User review", "Record"], "Accepted 2")],
        ["Rollback after import"], "docs/art_pipeline/x2_import.md")
    ph.fam("art", "X2 characters, items and VFX", "P2/P4/P7e/P9", ["art", "animation", "vfx", "items"],
           [(b, k) for b in X2_BOSSES for k in ("key poses", "attack set", "Hell phase", "hit/hurt polish", "export")] + [(e, k) for e in X2_ENEMIES for k in ("animation", "import")] +
           [(f"{X2_NB[k]}-{X2_NB[k + 1]}", "sprites") for k in range(0, 10, 2)] + [(s, k) for s in X2_IS for k in ("icons", "weapon/overlay")] + [(f"X2 VFX set {k}", "effects") for k in range(1, 7)] +
           [(st, f"cinematic art {k}") for st in X2_ST for k in (1, 2, 3)] + [("X2", "map art"), ("X2", "accessibility check 1"), ("X2", "accessibility check 2"), ("X2", "asset audit")],
           lambda u: f"{u[0]} {u[1]}",
           lambda u: [f"Produce {u[1]} for {u[0]}", "Match frame data / bible", "Colourblind and reduced-flash check", "Capture"],
           lambda u: f"{u[0]} {u[1]} done", ["Animation length vs frame data"], "production/qa/evidence/y10/art/", chunk=8)
    ph.fam("art", "Story+ extension art", "P8", ["art", "cinematics"], [(c, k) for c, _, _ in SPX for k in ("scene art", "epilogue slides")],
           lambda u: f"{u[0]} {u[1]}",
           lambda u: [f"Produce {u[1]} for {u[0]}", "Family framing consistent", "Import", "Capture"],
           lambda u: f"{u[0]} {u[1]} done", ["Slide variant for a companion state missing"], "production/qa/evidence/y10/storyplus/", chunk=8)
    ph.fam("art", "NG+ remix visuals and cosmetics", "§9 Y10 NG+", ["art", "vfx", "difficulty"], ALL_BOSS_IDS + [f"NG+ cosmetic set {k}" for k in range(1, 7)],
           lambda b: f"NG+ visuals: {b}",
           lambda b: [f"Produce {'palette/VFX remix for ' + b if b.startswith(('B', 'X1')) else b}", "Tells stay readable (never hidden by remix VFX)", "Reduced-flash variant", "Capture"],
           lambda b: f"{b} NG+ visuals done", ["Remix palette breaks colourblind mode"], "production/qa/evidence/y10/ngplus/", chunk=7)
    ph.fam("art", "Live art: limited editions, social, marketing, archive", "P7b; marketing; archive", ["items", "marketing", "art", "docs"],
           [(le, "item art") for le in LE_Y10] + [(f"month {m:02d}", "social set") for m in range(1, 13)] + [("3.0.0", x) for x in ("key art", "capsules", "trailer cards", "screenshots", "press kit")] +
           [("art archive", x) for x in ("PAE projects", "art bible final", "source layers", "provenance index")],
           lambda u: f"{u[0]} {u[1]}",
           lambda u: [f"Do {u[1]} for {u[0]}", "Check specs/spoilers (check current store specs)", "Approve", "Archive"],
           lambda u: f"{u[0]} {u[1]} done", ["Spoiler in key art"], "production/marketing/ + archive", chunk=8)
    ph.set_filler("art", Filler(
        lambda i: D(f"Live art fix AF10-{i + 1:03d}: {(REGIONS[i % 8][0]) if i % 3 else ('X1' if (i // 3) % 2 else 'X2')} {['tiles', 'props', 'sprites', 'UI art', 'VFX', 'icons'][(i // 8) % 6]}",
                    [f"Pull reported art issues for {(REGIONS[i % 8][0]) if i % 3 else ('X1' if (i // 3) % 2 else 'X2')} {['tiles', 'props', 'sprites', 'UI art', 'VFX', 'icons'][(i // 8) % 6]}", "Fix top 4 (baselines protected)", "Import and fallback check", "Close"],
                    f"AF10-{i + 1:03d} closed"),
        lambda n: f"Live art fixes block {n:02d}", "Live support", ["art", "assets"], ["Fix needs collision change (not allowed)"], "production/qa/evidence/y10/art/", "art"), 5)

    # ============================== AUDIO ==============================
    ph.fam("audio", "X2 music, SFX and ambience", "P9", ["music", "audio"],
           [(mt, s) for mt in X2_MT for s in ("A section", "B section", "adaptive layers", "mix", "master")] + [(f"X2-SB-{k:02d}", s) for k in range(1, 6) for s in ("design", "edit", "mix", "integrate")] +
           [(cs, "ambience") for cs in X2_CS] + [(b, s) for b in X2_BOSSES for s in ("tell cues", "Hell-phase cues", "hit/death")] + [(e, "enemy audio") for e in X2_ENEMIES] +
           [(f"{X2_EV[k]}-{X2_EV[k + 1]}", "event stingers") for k in range(0, 6, 2)] + [("X2", f"mix pass {k}") for k in (1, 2, 3)] + [("X2 trailer", s) for s in ("cue", "mix", "loudness")] +
           [(p, "X2 console audio check") for p, _ in PLATFORMS] + [("X2", "audio accessibility"), ("X2", "captions")],
           lambda u: f"{u[0]} {u[1]}",
           lambda u: [f"Do {u[1]} for {u[0]}", "Check against audio direction and AX06", "Integrate and test", "Log provenance"],
           lambda u: f"{u[0]} {u[1]} done", ["Loop seam on layer switch"], "assets/audio/expansion2/", chunk=8)
    ph.fam("audio", "Story+ extension audio", "P8/P9", ["music", "audio", "cinematics"], [(fid, s) for fid, _ in ENDING_FAMILIES for s in ("theme compose", "theme arrange", "theme mix", "theme master", "ambience A", "ambience B")] + [(c, "scene cue") for c, _, _ in SPX],
           lambda u: f"Story+ extension {u[0]} {u[1]}",
           lambda u: [f"Do {u[1]} for {u[0]}", "Match family framing and base Story+ music", "Integrate", "Record"],
           lambda u: f"{u[0]} {u[1]} done", ["Cue overlaps slide music"], "assets/audio/storyplus/", chunk=8)
    ph.fam("audio", "NG+ remix audio", "§9 Y10 NG+; P6 tells stay fair", ["music", "audio", "difficulty"],
           [(b, "boss theme remix") for b in ALL_BOSS_IDS] + [(f"{ALL_BOSS_IDS[k]}/{ALL_BOSS_IDS[k + 1]}", "tell audio check") for k in range(0, 28, 2)] + [(r, f"NG+ world music {k}") for r, _, _ in REGIONS for k in (1, 2)] + [("NG+ UI", "sounds"), ("NG+ market", "sounds"), ("NG+ start", "stinger")],
           lambda u: f"NG+ {u[0]} {u[1]}",
           lambda u: [f"Do {u[1]} for {u[0]}", "Tell cues unchanged in timing", "Mix and integrate", "Record"],
           lambda u: f"{u[0]} {u[1]} done", ["Remix masks a tell"], "assets/audio/ngplus/", chunk=8)
    ph.fam("audio", "Live audio, OST and archive", "Live; business; archive", ["audio", "business", "docs"],
           [(le, "stinger") for le in LE_Y10[:6]] + [(f"OST vol. 2 {k}", "mastering") for k in range(1, 7)] + [(f"music archive {MUSIC[k]}-{MUSIC[k + 4]}", "re-master archive") for k in range(0, 45, 5)] + [("audio docs", f"final {k}") for k in (1, 2, 3, 4)],
           lambda u: f"{u[0]} {u[1]}",
           lambda u: [f"Do {u[1]} for {u[0]}", "Check rights/metadata where relevant", "Archive with checksums", "Record"],
           lambda u: f"{u[0]} {u[1]} done", ["Missing session file for an old track"], "production/ost/ + archive", chunk=8)
    ph.set_filler("audio", Filler(
        lambda i: D(f"Live audio fix AUF10-{i + 1:03d}: {['PC', 'console A', 'console B', 'console C'][i % 4]} {['ambience', 'combat SFX', 'UI sounds', 'music transitions', 'world events', 'cutscene audio'][(i // 4) % 6]}",
                    [f"Pull audio issues: {['PC', 'console A', 'console B', 'console C'][i % 4]} {['ambience', 'combat SFX', 'UI sounds', 'music transitions', 'world events', 'cutscene audio'][(i // 4) % 6]}", "Fix top 4", "Re-test", "Close"],
                    f"AUF10-{i + 1:03d} closed"),
        lambda n: f"Live audio fixes block {n:02d}", "Live support", ["audio"], ["Issue only on one platform"], "production/qa/y10/audio/", "audio"), 5)

    # ============================== WRITING ==============================
    ph.fam("writing", "X2 narrative", "§9 Y10 Expansion 2", ["story", "dialogue", "quests"],
           [("X2 bible", f"structure {k}") for k in (1, 2, 3)] + [(st, f"{x}") for st in X2_ST for x in ("outline", "SCN1", "SCN2", "SCN3", "SCN4", "ending/Story+ hooks")] +
           [(q, x) for q in X2_SQ for x in ("first draft", "revision")] + [(q, "TQ text and signposts") for q in X2_TQ] + [(nb, "profile and barks") for nb in X2_NB] +
           [(s, "item text") for s in X2_IS] + [(f"X2 codex {k}", "entries") for k in range(1, 5)] + [(f"X2 barks {k}", "pass") for k in range(1, 6)] + [(lb, x) for lb in X2_LB for x in ("source freeze", "LQA response")],
           lambda u: f"{u[0]} {u[1]}",
           lambda u: [f"Write {u[1]} for {u[0]}", "Canon and VOICE_GUIDE check; no new canon without approval", "zh-Hans context notes", "Commit"],
           lambda u: f"{u[0]} {u[1]} committed", ["Line assumes X1 owned"], "string tables", chunk=8)
    ph.fam("writing", "Story+ extension scripts", "P8", ["story", "dialogue"], [(c, x) for c, _, _ in SPX for x in ("draft", "revision", "polish")] + [(s["sid"], "Story+ extension variant lines") for s in STORYLINES],
           lambda u: f"{u[0]} {u[1]}",
           lambda u: [f"Write {u[1]} for {u[0]}", "Authorization framing per bible", "Composer variables check", "Commit"],
           lambda u: f"{u[0]} {u[1]} committed", ["Variant line for an invalid axis combo"], "string tables", chunk=9)
    ph.fam("writing", "NG+, live and decade copy", "Live; Y10 decision comms", ["dialogue", "marketing", "docs", "localization"],
           [("NG+", x) for x in ("cycle intro text", "remix codex entries 1", "remix codex entries 2", "titles text", "carryover screen text", "zh-Hans pass")] +
           [(p, "notes + zh-Hans delta") for p in PATCHES] + [(f"dev update #{k}", "copy") for k in range(1, 9)] + [(le, "lore text") for le in LE_Y10] +
           [("3.0.0", x) for x in ("store copy", "press release", "trailer cards", "FAQ")] + [("decade", x) for x in ("public retrospective draft", "decision announcement draft", "writing style guide final", "glossary final", "writing archive index")],
           lambda u: f"{u[0]} {u[1]}",
           lambda u: [f"Write {u[1]} for {u[0]}", "Accuracy check with the team", "zh-Hans version where player-facing", "Hand off / archive"],
           lambda u: f"{u[0]} {u[1]} done", ["Copy implies a decision not yet made"], "production/community/ + docs/writing/", chunk=8)
    ph.set_filler("writing", Filler(
        lambda i: D(f"Live text fix WF10-{i + 1:03d}: {(REGIONS[i % 8][0]) if i % 3 else ('X1' if (i // 3) % 2 else 'X2')} {['typos', 'overflow', 'continuity', 'tone', 'missing keys', 'NG+ text'][(i // 8) % 6]}",
                    [f"Pull text issues: {(REGIONS[i % 8][0]) if i % 3 else ('X1' if (i // 3) % 2 else 'X2')} {['typos', 'overflow', 'continuity', 'tone', 'missing keys', 'NG+ text'][(i // 8) % 6]}", "Fix EN and zh-Hans", "Verify in game", "Close"],
                    f"WF10-{i + 1:03d} closed"),
        lambda n: f"Live text fixes block {n:02d}", "Live support", ["dialogue", "localization"], ["Fix in an achievement string"], "string tables", "writing"), 5)

    # ============================== QA ==============================
    ph.fam("qa", "X2 tests", "P5/P3/P6 for X2", ["tests", "quests", "difficulty"],
           [(q, "quest test") for q in X2_SQ] + [(q, "timing test") for q in X2_TQ] + [(st, f"matrix row part {k}") for st in X2_ST for k in (1, 2, 3)] +
           [(f"{b} {d['diff']}", "boss test") for b in X2_BOSSES for d in DIFFS] + [(cs, "traversal test") for cs in X2_CS] + [(lb, f"LQA {k}") for lb in X2_LB for k in (1, 2)] +
           [(x, "X2 perf check") for x in ("PC", "A/B", "C", "Deck")] + [(x, "X2 DLC test") for x in ("PC", "A", "B", "C")] +
           [(f"{g[0]['sid']}-{g[-1]['sid']}", "X2 entry test") for g in [STORYLINES[i:i + 3] for i in range(0, 27, 3)]] + [("X2", f"fairness session {k}") for k in (1, 2, 3)] + [("X2", f"hardware check {k}") for k in range(1, 5)] + [("X2", "accessibility pass"), ("X2", "accessibility regression")],
           lambda u: f"X2 {u[1]}: {u[0]}",
           lambda u: [f"Execute {u[1]} for {u[0]}", "Odd orders, pauses, save/load at awkward moments", "Log bugs with saves and video", "Record"],
           lambda u: f"X2 {u[0]} {u[1]} done", ["DLC not owned mid-quest"], "production/qa/y10/x2/", chunk=8)
    ph.fam("qa", "Story+ extension and NG+ tests", "P8; NG+", ["tests", "story", "difficulty", "economy"],
           [(c, "Story+ case test") for c, _, _ in SPX] + [(f"{g[0]['sid']}-{g[-1]['sid']}", "Story+ extension check") for g in [STORYLINES[i:i + 3] for i in range(0, 27, 3)]] +
           [(f"{cyc} {d['diff']}", "NG+ cycle run") for cyc in NG_CYCLES for d in DIFFS] + [(b, "NG+ remix boss test") for b in ALL_BOSS_IDS] +
           [(f"{cyc} market", "remix sim check") for cyc in NG_CYCLES] + [(f"{x}", "NG+ remix market manual check") for x in ("AH1-AH2", "AH3-AH4", "CG01-CG12")] +
           [(f"{g[0]['sid']}-{g[-1]['sid']}", "NG+ carryover save test") for g in [STORYLINES[i:i + 3] for i in range(0, 27, 3)]] + [(f"Story+ x NG+ combo {k}", "test") for k in range(1, 7)],
           lambda u: f"{u[1]}: {u[0]}",
           lambda u: [f"Execute {u[1]} for {u[0]}", "Compare with spec and replays", "Log bugs with evidence", "Record"],
           lambda u: f"{u[0]} {u[1]} done", ["NG+ started from an X2 save without DLC"], "production/qa/y10/ngplus/", chunk=8)
    ph.fam("qa", "Live regression and decade archive", "Live; save-compat forever", ["tests", "release", "save"],
           [(p, f"regression {k}") for p in PATCHES for k in (1, 2)] + [(f"{p} 3.x", "console parity regression") for p, _ in PLATFORMS for k in (1,)] + [(f"{p} 3.x", "console Hell/NG+ replay check") for p, _ in PLATFORMS] +
           [(f"10-year save archive {k}", "manual load sample") for k in range(1, 5)],
           lambda u: f"{u[1]}: {u[0]}",
           lambda u: [f"Run {u[1]} for {u[0]}", "Compare with expected", "Log", "Record"],
           lambda u: f"{u[0]} {u[1]} done", ["Patch lands on PC before consoles"], "production/qa/y10/", chunk=8)
    ph.set_filler("qa", Filler(
        lambda i: D(f"Community bug repro CB10-{i + 1:03d}: {['PC', 'console A', 'console B', 'console C'][i % 4]} x {SYSTEMS[(i // 4) % 15]}",
                    [f"Reproduce reports for {SYSTEMS[(i // 4) % 15]} on {['PC', 'console A', 'console B', 'console C'][i % 4]}", "Add steps and saves", "Mark cannot-reproduce with what was tried", "Update triage"],
                    f"CB10-{i + 1:03d} processed"),
        lambda n: f"Community bug repro block {n:02d}", "Live support", ["tests"], ["Report from modded install"], "Issue tracker", "qa"), 5)
    add_extra(ph)
    reorder(ph)
    return ph


if __name__ == "__main__":
    print(build().counts())
