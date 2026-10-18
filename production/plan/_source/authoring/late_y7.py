"""Y7 Beta (2032-10-01 -> 2033-09-30, Gate 7 RC)."""
from late_common import *
from late_y7_extra import add_extra

CAPS = {"primary": 313, "secondary": 365, "art": 261, "audio": 261, "writing": 261, "qa": 261}


def build():
    ph = Phase("Y7", "Beta",
               "Every boss, storyline, timing path, region and screen is validated on every difficulty and both languages, and the build passes Gate 7 as a release candidate.",
               ["120/120 boss x difficulty tuning days signed off; 24/24 Hell input replays: perfect run wins, every +/-1-frame mutant loses",
                "1000-day headless economy run passes for 27/27 storylines; 0 open arbitrage, sniping or gambling-EV exploits",
                "Nightly bot covers 405/405 storyline x difficulty x timing cells; 0 silent story-critical losses; 40/40 deadlines signposted",
                "60 fps (1% low within budget) on min spec in 8/8 regions with streaming + NPC/market sim; Steam Deck checklist passed (check current criteria)",
                "EN + zh-Hans: 20/20 localization batches through linguistic QA; 24/24 screens and 12/12 accessibility systems passed",
                "Age ratings filed (check current rules), licence + AI-disclosure audit closed, credits complete",
                "Gate 7: 0 critical bugs, high bugs under the agreed threshold, every storyline completable"],
               CAPS)

    # ============================== PRIMARY ==============================
    ph.add("head", "primary", "Open Beta: plan, freeze policy, sprint",
           "ROADMAP §8 Beta; Gate 6 follow-ups", ["release", "team", "docs"],
           [D("Beta kickoff: carry Gate 6 findings into the Beta plan",
              ["Run `/gate-check` output review for Gate 6 and list every CONCERNS item as a Y7 story",
               "Declare content freeze: new content only through approved change requests in `production/change_requests/`",
               "Define the Gate 7 bug threshold (high bugs max) with the team and record it in `production/milestones/gate7.md`",
               "Run `/sprint-plan` for the first two-week Beta sprint"],
              "Gate 7 criteria and freeze policy written; sprint 1 planned"),
            D("Beta kickoff: test infrastructure readiness",
              ["Confirm gdUnit4 CI, `tests/run_all_tests.ps1`, nightly bot and economy sim all run green on main",
               "Inventory test gaps per system with `/regression-suite` and `/test-evidence-review`",
               "Create `production/qa/y7/` folders: replay, econ, matrix, perf, a11y, loc",
               "Book weekly Beta health review (Sunday integration day) in the tracker"],
              "All Y7 harnesses green on main; evidence folders exist")],
           ["CI runner out of disk on nightly artefacts", "Change request bypassing freeze"], "production/milestones/gate7.md")

    ph.add("main", "primary", "Build the Hell input-replay harness",
           "P2/P6: Hell validated by input replay - perfect run wins, one frame off loses (ROADMAP §8, §12.1)",
           ["combat", "difficulty", "tests", "tools"],
           [D("Replay harness design: format and determinism contract",
              ["Write ADR 'Input replay format': per-tick input bitmask at fixed 60 Hz, RNG seed, WorldClock seed, difficulty id, build hash",
               "List every non-deterministic source in combat (timers, physics jitter, unordered dict iteration) from `scripts/combat/`",
               "Define the mutator API: shift input N by +/-k ticks, drop input N, duplicate input N",
               "Define pass/fail: perfect replay ends with boss HP 0 and player alive; checksum of HP timeline stable"],
              "ADR merged; non-determinism list complete"),
            D("Replay harness: recorder",
              ["Add `scripts/core/input_replay_recorder.gd` hooked into `scripts/core/input_service.gd` at the fixed tick",
               "Write `.rpl` files to `tests/fixtures/replays/` with header (build, seed, difficulty, boss id)",
               "Make recording respect `context_stack.gd` pauses (no ticks recorded while paused)",
               "Unit test `tests/unit/replay/test_recorder.gd`: 600 ticks round-trip byte-identical"],
              "Recorder writes and re-reads 600-tick files identically"),
            D("Replay harness: player and checksum",
              ["Add `scripts/core/input_replay_player.gd` that feeds InputService instead of devices",
               "Compute a per-tick checksum of player HP, boss HP, boss state id, RNG counter",
               "Run the same replay 5 times headless; assert identical checksums",
               "Fail loudly with first divergent tick and state dump"],
              "Five headless runs give identical checksums on a B01 sample"),
            D("Replay harness: frame-shift mutator",
              ["Add `tools/replay/mutate.gd` producing +1 and -1 tick variants for every parry/dodge input in a chosen phase",
               "Batch-run all variants headless in parallel (one process per variant)",
               "Report per input: perfect=WIN, mutant=LOSS expected; any mutant WIN is a window-wider-than-spec defect",
               "Test on a synthetic boss with a known 2-frame parry window"],
              "Synthetic boss: perfect wins, all mutants lose"),
            D("Replay harness: CI integration and latency calibration interplay",
              ["Add CI job `hell-replay` that runs every `.rpl` under `tests/fixtures/replays/hell/` per merge",
               "Verify latency-calibration offset is applied before the fixed tick, so replays are offset-independent",
               "Verify the 4-frame input buffer (§12.1) does not widen the effective parry window beyond 2 frames",
               "Document usage in `docs/tools/input_replay.md`"],
              "CI job green; buffer and calibration proven not to widen Hell windows")],
           ["Pause during a recorded parry", "Boss phase transition on the same tick as a parry", "Calibration offset of 0 vs max",
            "Replay recorded on one build replayed on another (must refuse)"],
           "tests/unit/replay/test_recorder.gd + CI job hell-replay + docs/tools/input_replay.md")

    for r, rn, act in REGIONS:
        bs = [b for b in BOSSES if b["rid"] == r]
        days = []
        for b in bs:
            days.append(D(f"Hell input-replay validation: {b['bid']} {b['bname']} ({r} {rn})",
                          [f"Record a perfect Hell run of {b['bid']} (including its Hell-only phase) to `tests/fixtures/replays/hell/{b['bid']}_perfect.rpl`",
                           f"Run `tests/integration/replay/test_hell_replay.gd --boss={b['bid']}` 5x: expect WIN with identical checksums",
                           f"Run `tools/replay/mutate.gd` on every parry and dodge in {b['bid']}'s Hell-only phase: every +/-1 tick mutant must LOSE",
                           f"Check {b['bid']} stat invariants across phases and retries (HP, damage x2.0, 1 healing charge)",
                           f"File any mutant WIN or perfect LOSS against {b['bid']} frame data in `data/bosses/{b['bid']}/`"],
                          f"{b['bid']}: perfect 5/5 WIN, all mutants LOSE; result in production/qa/y7/replay/{b['bid']}_hell.json"))
        days.append(D(f"{r} {rn} Hell replay wrap-up and regression",
                      [f"Re-run all {r} replays after any frame-data fix: {', '.join(b['bid'] for b in bs)}",
                       f"Add the {r} replays to the CI `hell-replay` job",
                       f"Summarise {r} results (wins, mutant losses, fixes) in `production/qa/y7/replay/{r}_summary.md`",
                       "Hand fairness notes to the QA survey sessions for these bosses"],
                      f"{r} replays all in CI and green"))
        ph.add("main", "primary", f"Hell input-replay validation for {r} {rn} bosses",
               "P6: Hell needs 2-frame precision and replay-verified fairness (ROADMAP §8, §12.1)",
               ["combat", "difficulty", "tests"], days,
               ["Hell-only phase entered on a retry with stale state", "Parry input exactly on buffer edge (frame 4)", "Boss killed by environmental hazard"],
               f"production/qa/y7/replay/{r}_summary.md + CI hell-replay")

    ph.add("main", "primary", "Difficulty system rules audit",
           "§12.1 rules: lower but never raise mid-run; no essential item exclusive to Hell; DDA only on Beginner/Easy",
           ["difficulty", "systems", "tests", "items"],
           [D("Audit: difficulty change rules",
              ["Write `tests/unit/difficulty/test_lower_only.gd`: raising mid-run is rejected, lowering keeps progress",
               "Check the save stores difficulty history (for Story+ and leaderboard eligibility) without schema change",
               "Verify UI greys out higher options on SC02/SC03",
               "Run on a save from each act"],
              "Lower-only rule tested on 4 act saves"),
            D("Audit: Hell-exclusive items",
              ["Query ItemDB for items whose source is Hell-only; list them",
               "Confirm each is cosmetic or a title (§12.1 loot row), never essential for any build or quest",
               "Add `tests/unit/items/test_no_essential_hell_items.gd` over ItemDB tags",
               "Fix any violation by adding a non-Hell source"],
              "0 essential Hell-exclusive items; test in CI"),
            D("Audit: DDA and leniency",
              ["Verify DDA gentle on Beginner, on for Easy, off for Medium/Hard/Hell in `data/difficulty/*.tres`",
               "Verify DDA never edits frame windows, only enemy damage/aggression within caps",
               "Verify deadline leniency x1.5/x1.25/x1.0/x1.0/x0.85 applied by WorldClock deadline checks",
               "Unit test each profile value against the §12.1 table"],
              "Profile table test green for all 5 difficulties")],
           ["Difficulty lowered during a boss fight", "Save loaded from a build with an older profile table"],
           "tests/unit/difficulty/ + tests/unit/items/test_no_essential_hell_items.gd")

    # Economy
    ph.add("main", "primary", "Economy: 1000-day headless simulation harness per route",
           "P7b + risk 'economy exploits/inflation': 1000-day sim per route (ROADMAP §8, §12.6)",
           ["economy", "tools", "tests"],
           [D("Econ sim: extend to 1000 days and per-route event tables",
              ["Extend `tools/econ_sim/run_headless.gd` to accept `--route=<storyline id> --days=1000 --seed=<n>`",
               "Load route-specific market events from StoryGraph flags for the chosen storyline",
               "Stream daily rows (prices per commodity group, money supply, sinks, sources) to CSV",
               "Keep the run under 10 minutes headless; profile if slower"],
              "One 1000-day run completes and writes CSV"),
            D("Econ sim: invariant checks",
              ["Assert sell <= 40% of buy for every shop row; crafted value <= 90% of inputs unless skill-upgraded",
               "Assert money supply growth per 28-day month stays inside the band from the economy GDD",
               "Assert each of 12 commodity groups stays inside `data/market/bounds.tres` floor/ceiling",
               "Emit a pass/fail summary JSON next to the CSV"],
              "Invariant checker flags a seeded known-bad table"),
            D("Econ sim: CI and reporting",
              ["Add CI job `econ-1000` running 3 storylines per night in rotation",
               "Generate a chart per run (money supply, CG prices) into `production/qa/y7/econ/`",
               "Document how to reproduce a failing day from its seed",
               "Hook results into the nightly dashboard"],
              "Nightly econ job rotating through storylines")],
           ["Route with zero auction activity", "Festival and limited-edition release on the same day", "Seed producing negative stock"],
           "CI job econ-1000 + production/qa/y7/econ/")

    grp = [STORYLINES[i:i + 3] for i in range(0, 27, 3)]
    for gi, g in enumerate(grp, 1):
        days = []
        for s in g:
            days.append(D(f"1000-day economy run for {s['kind']} {s['sid']}",
                          [f"Run `godot --headless -s tools/econ_sim/run_headless.gd -- --route={s['sid']} --days=1000 --seed=1` and seed=2",
                           f"Check both seeds' summary JSON for {s['sid']}: invariants pass, inflation inside band",
                           f"Check {s['sid']}'s route-specific market events fire on their calendar days and recover within 28 days",
                           f"Record verdict and anomalies in `production/qa/y7/econ/{s['sid']}.md`"],
                          f"{s['sid']}: 2 seeds x 1000 days pass or defects filed"))
        ids = ", ".join(s["sid"] for s in g)
        days.append(D(f"Economy group {gi} ({ids}): fix and re-run",
                      [f"Fix the top economy defect found in {ids} in data (prices, sinks), not code, where possible",
                       "Re-run the affected storylines with the original seeds",
                       "Run `/balance-check` on the changed tables",
                       "Add any new invariant to the checker"],
                      f"Group {gi} green after fixes"))
        ph.add("main", "primary", f"Economy sim per route: group {gi} ({ids})",
               "§8 Beta: 1000-day headless simulation per route", ["economy", "tests"], days,
               ["Route that never reaches the 4th auction house", "Late-pace run where a market event is skipped"],
               f"production/qa/y7/econ/ ({ids})")

    days = []
    for cg in CGS:
        days.append(D(f"Exploit hunt: arbitrage in commodity group {cg}",
                      [f"Run `tools/econ_sim/arbitrage_search.gd --group={cg}` over shops, market and 4 auction houses for buy-sell-craft cycles",
                       f"Check reputation/route price modifiers cannot push {cg} sell price above 40% of buy",
                       f"Write `tests/unit/economy/test_arbitrage_{cg.lower()}.gd` with the worst cycle found as a fixture",
                       "Fix by data change; re-run the search to 0 profitable cycles"],
                      f"{cg}: 0 profitable cycles; regression test added"))
    ph.add("main", "primary", "Exploit hunt: commodity arbitrage (12 groups)",
           "§12.6 anti-exploit rules; review found an infinite-gold loop", ["economy", "tests"], days[:6],
           ["Max reputation + best route modifier", "Seasonal price peak overlapping a festival"], "tests/unit/economy/test_arbitrage_cg01..06.gd")
    ph.add("main", "primary", "Exploit hunt: commodity arbitrage (groups 7-12)",
           "§12.6 anti-exploit rules", ["economy", "tests"], days[6:],
           ["Crafted item using two groups' inputs", "Salvage returning more than input value"], "tests/unit/economy/test_arbitrage_cg07..12.gd")

    days = [D(f"Exploit hunt: auction sniping and listing limits in {ah}",
              [f"Simulate 500 lots in {ah} with a sniping agent bidding in the last tick of each lot",
               "Confirm NPC bidder behaviour caps sniping gains per the §12.6 rule",
               f"Confirm listing limits (3 active lots, weekly cap) and the fee sink hold in {ah}",
               f"Add `tests/integration/economy/test_auction_{ah.lower()}.gd`"],
              f"{ah}: sniping gain inside cap; listing limits enforced") for ah in AHS]
    days += [D(f"Exploit hunt: expected value of gambling game {g} ({gn})",
               [f"Simulate 1,000,000 rounds of {g} headless with seeded RNG; compute player EV and variance",
                f"Confirm the house edge shown in the {gn} UI matches the simulated edge",
                "Confirm daily table limits and that LCK's effect stays inside its cap (§12.8)",
                f"Add `tests/unit/gambling/test_ev_{g.lower()}.gd` with the expected EV band"],
               f"{g}: EV negative for the player as designed; edge disclosed correctly") for g, gn in GAMBLING]
    days.append(D("Exploit hunt: crafting value rule across 6 crafting trees",
                  ["For CT1..CT6 compute crafted value vs inputs' market value at season high and low",
                   "Flag any recipe > 90% of inputs without a skill upgrade",
                   "Check the forge minigame quality bonus cannot chain into arbitrage",
                   "Add the worst recipe per tree to `tests/unit/economy/test_craft_value.gd`"],
                  "Every recipe in CT1..CT6 obeys the 90% rule"))
    ph.add("main", "primary", "Exploit hunt: auctions, gambling EV, crafting",
           "§8: exploit hunting (arbitrage, auction sniping, gambling expected value)", ["economy", "tests"], days,
           ["Auction lot ending during a pause", "Gambling at the daily limit across midnight", "Crafting during a festival price spike"],
           "tests/integration/economy/ + tests/unit/gambling/")

    ph.add("main", "primary", "Economy telemetry from Early Access",
           "§8: telemetry from Early Access; Gate 4 exploit turnaround <= 1 patch", ["economy", "tools", "legal"],
           [D("Telemetry: economy event schema and privacy check",
              ["List events needed: gold sources/sinks per day, auction results, gambling volume, commodity trades",
               "Check the EA privacy notice and current regional privacy rules (check current rules) before adding fields",
               "Keep events opt-in and anonymous; no free text",
               "Write `docs/telemetry/economy_events.md`"],
              "Schema approved; privacy check recorded"),
            D("Telemetry: aggregation and dashboard",
              ["Aggregate EA telemetry into daily money supply and median prices per commodity group",
               "Compare EA curves against the headless sim for the same storylines",
               "Flag divergence > 20% as an investigation",
               "Publish `production/qa/y7/econ/ea_vs_sim.md`"],
              "EA vs sim comparison published"),
            D("Telemetry: exploit alerts",
              ["Add alert: any player with gold growth > 5x the 99th percentile in 7 days",
               "Add alert: auction lot price outliers per house",
               "Route alerts into the bug triage queue",
               "Dry-run the alerts on last month's data"],
              "Alerts fire correctly on historical data")],
           ["Telemetry disabled by player", "Clock-skipped saves distort per-day metrics"], "docs/telemetry/economy_events.md")

    # Time paths
    for prof, pdesc in TIMING:
        days = []
        for seg in ["Act 1 (R1-R2)", "Act 2 (R3-R5)", "Act 3 branches A/B/C (R6-R7)", "Act 4 (R8)", "Story+"]:
            days.append(D(f"Bot timing profile '{prof}' through {seg}",
                          [f"Run `tools/bot/route_bot.gd --profile={prof} --segment=\"{seg}\" --storylines=all --seed=1`",
                           f"Check pace values and timing flags recorded for {seg} match the {pdesc} expectation table",
                           "Assert every deadline failure in the log is preceded by its signpost event (quest log + in-world warning)",
                           "Assert nothing story-critical was lost silently (`tests/integration/time/test_no_silent_loss.gd`)",
                           f"Save bot captures to `production/qa/y7/time/{prof}_{''.join(c for c in seg.split('(')[0] if c.isalnum())}.md`"],
                          f"'{prof}' through {seg}: 0 silent losses, flags as expected"))
        days.append(D(f"Timing profile '{prof}': defect fixes and Story+ timing summary check",
                      [f"Fix the '{prof}' defects found this week (missing signposts, wrong flag)",
                       "Re-run the failing segments",
                       f"Verify SC22 Story+ timing summary lists what the '{prof}' run changed",
                       "Add a regression case per fixed defect"],
                      f"'{prof}' profile green end to end"))
        ph.add("main", "primary", f"Time paths: bot '{prof}' profile across all acts",
               "P7f + §12.4: fast, slow and out-of-order runs; nothing story-critical lost silently", ["time", "tests", "quests", "ai"], days,
               ["Rest that crosses two deadlines", "Season change during a window quest", "Order quest done in reverse"],
               f"production/qa/y7/time/ ({prof})")

    ph.add("main", "primary", "Nightly bot over the QA matrix (storyline x difficulty x timing)",
           "§8 Coverage: QA matrix with the bot running nightly", ["tests", "tools", "ai"],
           [D("QA matrix generator",
              ["Write `tools/bot/qa_matrix.gd` producing 27 storylines x 5 difficulties x 3 timing profiles = 405 cells",
               "Assign each cell a seed and expected ending id from the ending composer table",
               "Split cells into 7 nightly shards (~58 cells) so the matrix completes weekly",
               "Commit the matrix as `tests/fixtures/qa_matrix.json`"],
              "405 cells generated with expected endings"),
            D("Nightly scheduler and results store",
              ["Add CI schedule running one shard per night headless",
               "Store results in `production/qa/y7/matrix/<date>.json` (cell, result, ending, timing flags, duration)",
               "Retry a failed cell once; mark flaky if pass-on-retry",
               "Email/notify the team stream channel on new failures"],
              "First shard runs on schedule"),
            D("Matrix dashboard and flake handling",
              ["Generate `production/qa/y7/matrix/dashboard.md` with a 27x15 grid",
               "Run `/test-flakiness` weekly on matrix results; quarantine nothing without an issue",
               "Link each red cell to its issue",
               "Show trend of green cells per week"],
              "Dashboard renders from real results"),
            D("Matrix: Hell bot assist and completion checks",
              ["Give the bot Hell boss replays as scripted inputs so Hell cells can complete",
               "Add 'every quest completable' check per cell from the quest registry",
               "Add ending-sequence and Story+ state check per cell",
               "Run the full matrix once over a weekend and record duration"],
              "Full 405-cell run recorded")],
           ["Cell blocked by a bug in a shared prefix (cascade)", "Bot stuck in dialogue (R5 regression)"],
           "production/qa/y7/matrix/dashboard.md")

    for r, rn, act in REGIONS:
        ph.add("main", "primary", f"Performance: 60 fps on min spec in {r} {rn}",
               "§8: 60 fps on min spec with streaming and NPC/market simulation; streaming hitches < 2 ms (§12.5)",
               ["performance", "openworld", "npc"],
               [D(f"{r} perf capture on min spec",
                  [f"Run `/perf-profile` on the min-spec machine (spec in the Y6 tech requirements doc) along the {r} {rn} traversal route",
                   "Enable full NPC schedule sim and market sim; record frame time, 1% low, streaming hitch per chunk load",
                   f"Find the worst 5 chunks and the worst seam into/out of {r}",
                   f"Save `production/qa/y7/perf/{r}_capture.json` and screenshots to `production/qa/evidence/y7/perf/{r}_worst.png`"],
                  f"{r} capture with ranked hotspots"),
                D(f"{r} perf fixes",
                  [f"Fix the top 3 {r} hotspots (draw calls, NPC LOD tick, particle counts, script per-frame work)",
                   "Respect simulation LOD: off-screen NPCs only advance schedules; distant towns coarse tick",
                   "Keep visuals identical; compare screenshot tour frames before/after",
                   "Re-profile the fixed chunks"],
                  f"{r} top-3 hotspots fixed"),
                D(f"{r} perf verification and CI budget",
                  [f"Re-run the {r} route 3x; 60 fps with 1% low inside budget; hitches < 2 ms",
                   f"Add {r} route to the CI perf job with thresholds",
                   "Test combat transition (shatter) from the 2 densest chunks: < 1 s, state preserved (P1)",
                   f"Record verdict in `production/qa/y7/perf/{r}.md`"],
                  f"{r} meets budget on min spec; CI guards it")],
               ["Festival day with maximum NPC density", "Auction close and fast travel arrival on the same frame", "Save during streaming"],
               f"production/qa/y7/perf/{r}.md + production/qa/evidence/y7/perf/{r}_worst.png")

    ph.add("main", "primary", "Steam Deck verification",
           "§8: Steam Deck verification", ["performance", "ui", "release"],
           [D("Deck: criteria and baseline",
              ["Read the current Steam Deck compatibility criteria (check current rules)",
               "Map each criterion to our features: default controller config, glyphs, text legibility at 1280x800, launcher, sleep/resume",
               "Install the Beta build on a Deck; run the screenshot tour",
               "List failures in `production/qa/y7/deck.md`"],
              "Criteria map and baseline failures listed"),
            D("Deck: glyphs, text size and controller defaults",
              ["Force gamepad glyphs when a Deck is detected; verify on SC01-SC24",
               "Raise minimum font size where text < the criteria's legibility guidance",
               "Ship a default controller layout matching in-game prompts",
               "Re-run tour"],
              "Glyph and text failures closed"),
            D("Deck: performance and power",
              ["Profile R4 and R8 routes on Deck; set a Deck preset (resolution scale, particle cap)",
               "Verify suspend/resume mid-combat and mid-dialogue (context_stack pause)",
               "Measure battery drain per hour for the notes",
               "Re-run Hell replays on Deck to confirm determinism"],
              "Deck preset holds target frame rate; replays deterministic"),
            D("Deck: on-screen keyboard and file paths",
              ["Verify any text entry (save names) opens the on-screen keyboard",
               "Verify saves and settings paths work on Linux/Proton",
               "Verify zh-Hans font rendering on Deck",
               "Submit for review when criteria pass (check current process)"],
              "Deck checklist all green; submission ready")],
           ["Resume after hours of sleep with WorldClock", "External monitor attached"], "production/qa/y7/deck.md + evidence screenshots")

    ph.add("main", "primary", "Localization engineering for zh-Hans",
           "§3 languages at 1.0: EN + Simplified Chinese", ["localization", "ui", "code"],
           [D("Loc eng: hardcoded string sweep",
              ["Run `/localize` scan over `scripts/` and `scenes/`; list hardcoded player-facing strings",
               "Move each into the string tables with stable keys",
               "Add CI lint failing on new hardcoded strings in UI scenes",
               "Record count before/after"],
              "0 hardcoded player-facing strings; lint in CI"),
            D("Loc eng: CJK font and fallback",
              ["Add a licensed CJK font (licence checked) as fallback in the theme",
               "Verify glyph coverage for all zh-Hans strings via a coverage script",
               "Check dynamic font atlas memory on min spec",
               "Pixel-art font readability check at 1x and 2x scale"],
              "Glyph coverage 100%; memory inside budget"),
            D("Loc eng: line breaking and overflow",
              ["Enable CJK line breaking in labels and RichTextLabels",
               "Write `tests/unit/loc/test_overflow.gd`: render every string key in its widget and flag overflow",
               "Fix widgets to wrap/shrink; never truncate quest deadlines",
               "Run for EN and zh-Hans"],
              "Overflow test green in both languages"),
            D("Loc eng: pseudo-localization and .dlg support",
              ["Add a pseudo-locale (accented + 40% longer) to catch missing keys",
               "Ensure `scripts/dialogue_manager.gd` `.dlg` lines resolve through translation keys with speaker names",
               "Export string tables per batch LB01..LB20 with context columns",
               "Document the pipeline in `docs/localization/pipeline.md`"],
              "Pseudo-locale playthrough of Act 1 shows no raw keys")],
           ["String with embedded variable order differing in zh-Hans", "Dynamic text in ending composer slides"], "docs/localization/pipeline.md + tests/unit/loc/")

    days = []
    for ax, an in A11Y_SYSTEMS:
        days.append(D(f"Accessibility system {ax}: {an}",
                      [f"Compare {ax} implementation against the accessibility spec from `/ux-design` (project-wide accessibility section)",
                       f"Implement missing parts of {ax}; expose settings in SC03 with defaults",
                       f"Add `tests/unit/a11y/test_{ax.lower()}.gd` covering setting persistence and effect",
                       f"Capture before/after in `production/qa/evidence/y7/a11y/{ax}.png`"],
                      f"{ax} complete, tested and saved in settings"))
    ph.add("main", "primary", "Accessibility pass per system (AX01-AX06)", "§8: accessibility pass; Gate 7 accessibility",
           ["accessibility", "ui", "code"], days[:6],
           ["Remap conflict with a system key", "Colourblind mode with glitch overlay at max"], "tests/unit/a11y/ + evidence AX01-AX06")
    ph.add("main", "primary", "Accessibility pass per system (AX07-AX12)", "§8: accessibility pass; Gate 7 accessibility",
           ["accessibility", "ui", "code"], days[6:],
           ["Assist option toggled during Hell (must be unavailable)", "AccessKit not supported on a platform"], "tests/unit/a11y/ + evidence AX07-AX12")

    ph.add("main", "primary", "Save compatibility: EA saves into Beta",
           "Gate 4 rule kept: saves migrate across every patch; R4 silent rejection never returns", ["save", "tests"],
           [D("Collect EA save fixtures",
              ["Collect one save per act and per difficulty from every EA build tag into `tests/fixtures/saves/ea/`",
               "Include saves from opt-in player submissions (anonymised)",
               "Record build, schema version and act per fixture in an index",
               "Add corrupted and truncated variants"],
              "Fixture index complete"),
            D("Migration test run",
              ["Run `SaveService` migration on every fixture into the Beta schema",
               "Assert no silent rejection: failures show the player-facing error and keep a backup",
               "Assert WorldClock, StoryGraph flags, RewardLedger and market positions survive",
               "Write `tests/integration/save/test_ea_to_beta.gd`"],
              "100% fixtures migrate or fail loudly with backup"),
            D("Migration fixes and CI",
              ["Fix each migration failure with a new migration step and test",
               "Add the fixture set to the save-compatibility CI job",
               "Document schema history in `docs/save/schema_history.md`",
               "Re-run full fixture set"],
              "CI save job green on all fixtures")],
           ["Save from mid-auction", "Save during Story+", "Save from a modded build"], "tests/integration/save/test_ea_to_beta.gd")

    ph.add("main", "primary", "Quest completability check per region",
           "Gate 6/7: every quest completable", ["quests", "tests", "ai"],
           [D(f"Quest completability: {r} {rn}",
              [f"Run `tools/bot/quest_bot.gd --region={r}` over every side, secret and time-sensitive quest in {r}",
               "For each quest assert a completion state is reachable on Medium and on Hell leniency (x0.85)",
               "Assert failure states are signposted and do not block the main story",
               f"Log results to `production/qa/y7/quests/{r}.md`"],
              f"Every {r} quest reaches completion in the bot") for r, rn, _ in REGIONS],
           ["Quest giver killed in a crime event", "Quest started in Story+ only"], "production/qa/y7/quests/R1..R8.md")

    ph.add("main", "primary", "Cinematics and cutscene safety audit",
           "§4.7: cutscene timelines; R5 dialogue closes; context_stack owns pause", ["cinematics", "tests", "dialogue"],
           [D(f"Cutscene safety: {a}",
              [f"List every cutscene timeline in {a} and run each with skip at start, middle and last frame",
               "Assert after each: dialogue `is_active == false`, context_stack restored, input returned",
               "Pause and resume mid-cutscene; alt-tab; controller disconnect",
               f"Log to `production/qa/y7/cinematics/{''.join(c for c in a if c.isalnum())}.md`"],
              f"All {a} cutscenes skip and pause safely")
            for a in ["Act 1", "Act 2", "Act 3", "Act 4", "Story+ chapters"]],
           ["Skip on the same frame a choice appears", "Cutscene that triggers a combat transition"], "production/qa/y7/cinematics/")

    ph.add("main", "primary", "Fun and feel pass per weapon class and traversal",
           "P2 + P9 juice everywhere; fun factor before RC", ["fun", "combat", "vfx", "audio"],
           [D(f"Feel pass: {w}",
              [f"Play 20 minutes with {w}; log every hit lacking camera, particle, audio or haptic feedback",
               "Check hitstop tiers and cancel windows feel consistent with frame data in `.tres`",
               "Fix data-only issues; file art/audio requests for the team streams",
               f"Record a 30 s capture for the feel review"],
              f"{w}: no feedback-less hits remain") for w in ["weapon class 1", "weapon class 2", "weapon class 3", "weapon class 4",
                                                               "aerial and pogo game", "tools and abilities", "Root Access slow-time", "overworld traversal"]],
           ["Hitstop stacking on multi-hit", "Haptics on a controller without rumble"], "feel review captures in production/qa/evidence/y7/feel/")

    ph.add("main", "primary", "Licence and dependency audit for release (code side)",
           "§8 ratings and legal: licence audit", ["legal", "code"],
           [D("Code licence audit: addons and tools",
              ["List every addon and tool used in builds with licence",
               "Confirm gdUnit4 and any other test addon are excluded from release exports",
               "Generate `docs/legal/THIRD_PARTY_NOTICES.txt` for the credits/notices screen",
               "Check the CJK font licence permits embedding and distribution"],
              "Notices file generated"),
            D("Code licence audit: release export",
              ["Inspect the exported PCK for unexpected files (tests, art sources, docs)",
               "Tighten export filters in `export_presets.cfg`",
               "Re-export and diff file lists",
               "Record in `docs/legal/export_contents_y7.md`"],
              "Release export contains only shippable files")],
           ["Art source accidentally inside PCK", "Font subset licence"], "docs/legal/THIRD_PARTY_NOTICES.txt")

    every_year(ph, "Y7", "Beta lock (before Gate 7)", [f"EA update U7-{i:02d}" for i in range(1, 13)], triage_n=13)

    ph.add("tail", "primary", "Gate 7 RC: criteria evidence and go/no-go",
           "ROADMAP §10 G7: 0 critical bugs; performance; localization; accessibility", ["release", "tests", "docs"],
           [D("Gate 7 evidence collection",
              ["Run `/gate-check` for Release Candidate",
               "Collect matrix dashboard, replay summaries, econ summaries, perf reports, a11y and loc reports",
               "Count open bugs by severity against the threshold in gate7.md",
               "List any NOT ASSESSED item honestly"],
              "Gate 7 evidence pack assembled"),
            D("Gate 7 RC build",
              ["Cut `release/1.0-rc1`; run every CI job on it",
               "Run the full 405-cell matrix on the RC",
               "Export Windows and Deck builds; run screenshot tour; archive symbols",
               "Write the RC known-issues list"],
              "RC1 built with all CI green"),
            D("Gate 7 decision",
              ["Hold the go/no-go with the team; record decision as an ADR (go / re-scope / slip)",
               "If no-go: list blocking items with owners and dates",
               "Update `ROADMAP` risk register for launch",
               "Run `/retrospective` for Beta"],
              "Gate 7 ADR recorded")],
           ["Critical bug found during the gate run", "Threshold met only by downgrading severity (not allowed)"],
           "production/milestones/gate7.md + ADR Gate 7")

    BD = Filler(
        lambda i: D(f"Beta burn-down BD-{i + 1:03d}: {SYSTEMS[i % 15]} bugs in {REGIONS[(i // 15) % 8][0]} {REGIONS[(i // 15) % 8][1]}",
                    [f"Filter the tracker for open high/medium `{SYSTEMS[i % 15]}` bugs in {REGIONS[(i // 15) % 8][0]} via `/bug-triage`",
                     "Reproduce the top 3 with `scripts/core/debug_test_mode.gd` and save repro saves to `tests/fixtures/saves/bugs/`",
                     f"Fix each with a regression test under `tests/unit/{SYS_SLUG[SYSTEMS[i % 15]]}/`",
                     "Run the matrix cells that touch the fix; close issues with commit hashes"],
                    f"BD-{i + 1:03d}: top 3 {SYSTEMS[i % 15]} bugs in {REGIONS[(i // 15) % 8][0]} fixed with tests"),
        lambda n: f"Beta bug burn-down block {n:02d}", "Gate 7: high bugs under threshold, 0 critical", ["code", "tests", "cleanup"],
        ["Fix in one region regresses a seam with the next", "Bug only reproducible with a specific WorldClock day"],
        "Closed issues with regression tests", "primary")
    ph.set_filler("primary", BD, 5)

    # ============================== SECONDARY ==============================
    ph.add("head", "secondary", "Beta production plan and team sprint setup",
           "ROADMAP §8 Beta; operating rhythm", ["team", "release", "docs"],
           [D("Beta production plan",
              ["Run `/milestone-review` on Alpha and list content defects by region",
               "Allocate team streams for Y7: art polish/marketing, audio master/mix, writing loc/signposts, QA matrix/LQA",
               "Set weekly Beta health review agenda (matrix, replays, econ, perf, loc, a11y)",
               "Publish `production/milestones/y7_plan.md`"],
              "Y7 plan published to the team"),
            D("Beta change control",
              ["Create change request template in `production/change_requests/TEMPLATE.md`",
               "Define who approves (user) and the cost note required",
               "Log any pending Alpha content requests as CRs",
               "Run `/sprint-plan` with the team"],
              "CR process live; sprint 1 planned")],
           ["Team member unavailable for a sprint", "CR that changes save schema"], "production/milestones/y7_plan.md")

    STEPS = {
        "Beginner": lambda b: [
            f"Load `data/difficulty/beginner.tres`; confirm {b['bid']} reads parry 12 f, i-frames 18, telegraph x1.5, damage x0.6, 5 healing charges",
            f"Play {b['bid']} {b['bname']} 3 times with gentle DDA; log attempts and deaths per pattern in `production/qa/y7/balance/{b['bid']}_beginner.md`",
            "Check pattern literacy is still required: every attack has a readable tell; lower difficulty forgives execution, not attention",
            "Adjust only pattern pacing/DDA caps in data; never frame windows",
        ],
        "Easy": lambda b: [
            f"Load `data/difficulty/easy.tres`; confirm {b['bid']} reads parry 9 f, i-frames 15, telegraph x1.25, damage x0.8, 4 charges, DDA on",
            f"Play {b['bid']} 3 times; compare attempts with the Beginner sheet and the target band in the difficulty GDD",
            f"Check DDA adjustments stay inside caps for {b['bid']} (log DDA level per attempt)",
            f"Record `production/qa/y7/balance/{b['bid']}_easy.md`",
        ],
        "Medium": lambda b: [
            f"Load `data/difficulty/medium.tres`; confirm {b['bid']} uses +variants, parry 6 f, i-frames 12, 3 charges",
            f"Play {b['bid']} 3 times; check each variant pattern is learnable within the fight (no first-sight one-shots)",
            f"Run `/balance-check` on {b['bid']}'s damage table vs player build archetypes at the expected level",
            f"Record `production/qa/y7/balance/{b['bid']}_medium.md`",
        ],
        "Hard": lambda b: [
            f"Load `data/difficulty/hard.tres`; confirm {b['bid']} parry 4 f, i-frames 10, telegraph x0.85, damage x1.3, 2 charges",
            f"Play {b['bid']} with 3 different build archetypes; confirm no build trivialises it (stats never change timing windows)",
            "Check telegraphs at x0.85 still read on the busiest arena background",
            f"Record `production/qa/y7/balance/{b['bid']}_hard.md`",
        ],
        "Hell": lambda b: [
            f"Load `data/difficulty/hell.tres`; confirm {b['bid']} parry 2 f, i-frames 8, telegraph x0.7, damage x2.0, 1 charge, Hell-only phase on",
            f"Play the Hell-only phase of {b['bid']} until cleared once; note any tell shorter than its reaction budget",
            f"Confirm {b['bid']}'s Hell rewards are cosmetics/titles only",
            f"Hand the clean run to the primary stream for `{b['bid']}_perfect.rpl` recording; record `production/qa/y7/balance/{b['bid']}_hell.md`",
        ],
    }
    for b in BOSSES:
        days = [D(f"{b['bid']} {b['bname']} ({b['rid']} {b['rname']}, Act {b['act']}) on {d['diff']}",
                  STEPS[d["diff"]](b),
                  f"{b['bid']} {d['diff']} sign-off note committed with attempts, deaths and changes") for d in DIFFS]
        ph.add("main", "secondary", f"Boss tuning: {b['bid']} {b['bname']} on all 5 difficulties",
               "P2/P6: bosses hard on every difficulty; §8 every boss on every difficulty", ["combat", "difficulty", "fun"], days,
               [f"{b['bid']} retried after lowering difficulty mid-fight", "Healing charge refilled by a pickup in arena",
                "Arena generated from an unusual terrain context (P1)"],
               f"production/qa/y7/balance/{b['bid']}_*.md (5 files)")

    ph.add("main", "secondary", "Fairness surveys for bosses and deadlines",
           "§8 fairness surveys; Gate 1 fairness >= 70% carried forward", ["difficulty", "fun", "ux"],
           [D("Fairness survey design",
              ["Write survey items: 'I understood why I died', 'the tell was readable', 'the deadline was announced', 1-5 scale",
               "Define cohorts: new players, EA veterans, Hell players",
               "Prepare session script for QA with build and boss order",
               "Store in `production/qa/y7/fairness/survey.md`"],
              "Survey and script ready"),
            D("Fairness cohort 1: Acts 1-2 bosses", ["Run sessions on B01-B15 with cohort 'new players'", "Collect scores and free comments", "Tag each low score with boss id and pattern id", "Summarise per boss"], "Acts 1-2 fairness scores per boss"),
            D("Fairness cohort 2: Acts 3-4 bosses", ["Run sessions on B16-B24 with cohort 'EA veterans'", "Include SOVEREIGN and the God King Hell phases with Hell cohort", "Tag low scores", "Summarise per boss"], "Acts 3-4 fairness scores per boss"),
            D("Fairness cohort 3: deadlines and missables", ["Run a 2-hour open-world session focused on time-sensitive quests", "Ask whether each missed deadline was announced", "Map complaints to TQ ids", "Summarise"], "Deadline fairness scores per TQ"),
            D("Fairness analysis and actions",
              ["Rank bosses and TQs below 70% fair", "Write an action per item (tell, sound cue, signpost text)",
               "Assign actions to art, audio, writing streams", "Schedule re-survey of the bottom 5"],
              "Action list assigned with owners"),
            D("Fairness re-survey", ["Re-run the bottom 5 items with a fresh cohort", "Compare scores before/after", "Close actions that reached >= 70%", "Report in `production/qa/y7/fairness/report.md`"], "Bottom 5 re-surveyed; report published")],
           ["Cohort mostly Hell players skews results", "Survey taken after a crash"], "production/qa/y7/fairness/report.md")

    ph.add("main", "secondary", "Deadline signposting review per region",
           "§12.2/12.4 rule: nothing important lost silently; every deadline signposted", ["time", "quests", "ux"],
           [D(f"Signposting review: {r} {rn}",
              [f"Walk every time-sensitive quest in {r} ({', '.join(t['tq'] for t in TQS if t['rid'] == r)}) on a slow profile save",
               "Check the quest log shows the deadline with its in-world reason",
               "Check the in-world warning appears before close (NPC bark, notice board or letter)",
               "File missing signposts to the writing stream with TQ id"],
              f"{r}: every TQ has log + in-world signpost or a filed fix") for r, rn, _ in REGIONS],
           ["Deadline in a region the player has not discovered", "Warning bark from an NPC who died"], "production/qa/y7/time/signposts_R1..R8.md")

    days = [D(f"Economy tuning: commodity group {cg}",
              [f"Read sim and EA telemetry curves for {cg} from `production/qa/y7/econ/`",
               f"Adjust {cg} base, seasonality and NPC agent demand in `data/market/{cg.lower()}.tres`",
               "Run `/balance-check` on the market table",
               "Request a 1000-day re-run for 3 representative storylines"],
              f"{cg} prices stable inside bounds") for cg in CGS]
    ph.add("main", "secondary", "Economy tuning: commodity groups 1-6", "P7b market stability", ["economy", "items"], days[:6],
           ["Group with no NPC gatherers in a route"], "data/market diffs + /balance-check output")
    ph.add("main", "secondary", "Economy tuning: commodity groups 7-12", "P7b market stability", ["economy", "items"], days[6:],
           ["Group tied to a limited-edition release"], "data/market diffs + /balance-check output")
    days = [D(f"Auction tuning: {ah}",
              [f"Review NPC bidder budgets and preferences in {ah} against sim results",
               "Tune fee and listing caps to keep the house special (3 active lots, weekly cap)",
               "Check limited-edition auctions in this house are signposted in advance",
               f"Record in `production/qa/y7/econ/{ah}_tuning.md`"], f"{ah} tuned") for ah in AHS]
    days += [D(f"Minigame reward table: {m} {mn}",
               [f"Check {m} rewards obey the economy rules (no gold faster than the best legal loop)",
                f"Check {m} difficulty options and that it is never required for the story",
                "Tune reward table; run `/balance-check`",
                f"Record `production/qa/y7/econ/{m}.md`"], f"{m} reward table signed off") for m, mn in MINIGAMES]
    days += [D(f"Gambling table rules: {g} {gn}",
               [f"Confirm {g} uses in-game currency only, shows its house edge, has daily limits",
                "Confirm no paid randomized items anywhere (§12.7)",
                "Check the table copy is neutral (no pressure language)",
                f"Record `production/qa/y7/econ/{g}.md` for the rating questionnaire"], f"{g} rules documented for ratings") for g, gn in GAMBLING]
    ph.add("main", "secondary", "Auctions, minigames and gambling tuning", "P7b/P7c", ["economy", "fun"], days,
           ["Minigame farmed at the daily reset"], "production/qa/y7/econ/")

    ph.add("main", "secondary", "Localization direction for zh-Hans",
           "§3 languages; §8 linguistic QA", ["localization", "team", "docs"],
           [D("zh-Hans glossary and style guide",
              ["Build glossary: cast names (Kaelen, Elara, Seraphina, Lyra, Kaelthas, Aldric, Rook, Brask, Mara, Bran), SOVEREIGN, God King, Null Court, Source Key, Root Access",
               "Decide transliteration vs translation per term with the translator; record rationale",
               "Write voice notes per Tier A character from `story/VOICE_GUIDE.md`",
               "Store `docs/localization/zh_Hans_glossary.md`"],
              "Glossary and style guide approved"),
            D("Translator brief and batch schedule",
              ["Write the translator brief (context, tone, length limits, placeholders)",
               "Schedule LB01..LB20 with the writing stream's source-freeze dates",
               "Define LQA severity levels (blocker, major, minor, preference)",
               "Decide vendor or freelancer through a quote comparison (no commitment without user approval)"],
              "Batch schedule and LQA rules agreed")],
           ["Term that changes meaning by route (Root Access holders)", "Pun that cannot translate"], "docs/localization/zh_Hans_glossary.md")
    ph.add("main", "secondary", "Localization batch reviews LB01-LB10",
           "§8 localization with linguistic QA", ["localization", "dialogue"],
           [D(f"Review localization batch {lb} ({ln})",
              [f"Read the LQA report for {lb} from the QA stream",
               "Decide each disputed item against the glossary and voice notes",
               f"Spot-check 50 lines of {lb} in game in zh-Hans with screenshots",
               f"Sign off {lb} or return it with a list"], f"{lb} signed off or returned") for lb, ln in LOC_BATCHES[:10]],
           ["Line with gender/number agreement varying by companion"], "production/qa/y7/loc/LB01..LB10_signoff.md")
    ph.add("main", "secondary", "Localization batch reviews LB11-LB20",
           "§8 localization with linguistic QA", ["localization", "dialogue"],
           [D(f"Review localization batch {lb} ({ln})",
              [f"Read the LQA report for {lb} from the QA stream",
               "Decide each disputed item against the glossary and voice notes",
               f"Spot-check 50 lines of {lb} in game in zh-Hans with screenshots",
               f"Sign off {lb} or return it with a list"], f"{lb} signed off or returned") for lb, ln in LOC_BATCHES[10:]],
           ["Ending slide variable insertion order"], "production/qa/y7/loc/LB11..LB20_signoff.md")

    for half, scr in (("SC01-SC12", SCREENS[:12]), ("SC13-SC24", SCREENS[12:])):
        ph.add("main", "secondary", f"Accessibility review per screen ({half})",
               "§8 accessibility pass; Gate 7 accessibility", ["accessibility", "ux", "ui"],
               [D(f"Screen {sc} {sn}: accessibility review",
                  [f"Run `/ux-review` on the {sn} spec and the live screen",
                   f"Check {sn} with text scale 200%, colourblind modes, gamepad-only and keyboard-only",
                   "Check focus order, contrast, and that no info is colour-only",
                   f"Write fixes for {sc} and assign to primary/art; evidence `production/qa/evidence/y7/a11y/{sc}.png`"],
                  f"{sc} review complete with fix list") for sc, sn in scr],
               ["Focus lost after a popup closes", "Screen opened during a cutscene"], f"production/qa/evidence/y7/a11y/ ({half})")

    ph.add("main", "secondary", "Age ratings and regional restrictions",
           "§8/§12.7: simulated gambling raises ratings; some countries restrict it - check current rules", ["legal", "business", "release"],
           [D("Ratings: list the systems and their current processes",
              ["List target markets and the rating system each needs (check current rules for each)",
               "Check whether a digital questionnaire route covers the PC store (check current rules)",
               "List content descriptors likely triggered: violence, simulated gambling, language",
               "Record in `docs/legal/ratings_y7.md`"], "Rating systems per market listed"),
            D("Ratings: content capture",
              ["Collect footage list for gambling tables G1-G3, the most intense boss deaths and any crime/witness content",
               "Ask QA to capture the footage on the RC-candidate build",
               "Write descriptions of gambling (in-game currency only, no real money, no paid random items)",
               "Store package in `production/ratings/`"], "Rating capture package ready"),
            D("Ratings: regional gambling restrictions",
              ["Check current rules on simulated gambling in each target market (check current rules)",
               "Design the region config switch to disable G1-G3 where required without breaking quests",
               "Confirm no quest or achievement requires gambling",
               "Ticket the config implementation to primary"], "Region config spec ticketed"),
            D("Ratings: submit questionnaires",
              ["Fill questionnaires honestly with the package",
               "Record each result and certificate id",
               "Update store page age gates",
               "Archive in `docs/legal/ratings_y7.md`"], "Ratings obtained or pending with dates logged")],
           ["Rating differs between PC and later console", "Market requiring local representative"], "docs/legal/ratings_y7.md")

    ph.add("main", "secondary", "AI-disclosure and asset licence audit, credits",
           "§8 licence and AI-disclosure audit; credits; AGENTS.md art truth gate", ["legal", "assets", "docs"],
           [D(f"Provenance audit: {area}",
              [f"List every {area} asset and its provenance record (tool, ComfyUI evidence bundle if claimed, manual edits)",
               "Flag assets claiming AI generation without the evidence bundle required by `docs/art_pipeline/real_comfyui_generation_requirements.md`",
               "Flag assets with unclear licences",
               f"Write `docs/legal/provenance_{area.replace(' ', '_')}.md`"],
              f"{area} provenance complete or gaps ticketed")
            for area in ["region art", "characters and bosses", "props and decals", "UI and icons", "music", "SFX", "writing and dialogue"]] +
           [D("AI-disclosure statement",
              ["Read current store AI-disclosure rules (check current rules)",
               "Write the disclosure text from the provenance records; no claim without evidence",
               "Have the user approve the text",
               "Store in `docs/legal/ai_disclosure.md`"], "Disclosure text approved"),
            D("Credits compilation",
              ["Compile credits: team, contractors, translators, testers, licences, tools, Godot notice",
               "Confirm each person's name spelling and credit preference by message (user sends)",
               "Hand final text to writing (formatting) and art (credits screen)",
               "Store `docs/legal/credits.md`"], "Credits text final"),
            D("Title trademark and store legal check",
              ["Check current trademark status of the title in target markets (check current records; consult a lawyer if unclear)",
               "Review EULA/privacy text for telemetry",
               "List legal items still open for launch",
               "Record in `docs/legal/launch_legal.md`"], "Open legal items listed with owners")],
           ["Contractor asset with no written licence", "AI-assisted text edited by a writer (how to disclose)"], "docs/legal/ provenance + ai_disclosure.md + credits.md")

    ph.add("main", "secondary", "Launch marketing plan and assets direction",
           "§8 launch marketing; Gate 2 market signal follow-through", ["marketing", "business"],
           [D("Marketing plan for 1.0",
              ["Set goals: wishlists, followers, press coverage targets from EA data (no invented numbers; derive from EA history)",
               "List beats from now to launch: trailer, store page refresh, festival/event participation (check current event rules), press preview",
               "Assign assets to art/audio/writing streams",
               "Write `production/marketing/launch_plan.md`"], "Launch plan written"),
            D("Store page 1.0 refresh",
              ["Rewrite short and long descriptions with writing stream (EN + zh-Hans)",
               "Choose screenshots from the region set; check current capsule and screenshot specs",
               "Add content descriptors from ratings",
               "Stage the update for user approval"], "Store page update staged"),
            D("Trailer script and shot list",
              ["Write a 90 s trailer script hitting P1 transition, P2 combat, P7f time, P3 storylines",
               "Shot list per region with build and save to capture",
               "Music cue request to audio",
               "Store `production/marketing/trailer_1.0.md`"], "Trailer script and shot list ready"),
            D("Press kit and creator kit",
              ["Assemble press kit: fact sheet, logos, key art, screenshots, trailer link",
               "Creator kit: streaming policy, spoiler guidance (endings), music licensing note",
               "Check current key distribution policies before planning keys",
               "Store under `production/marketing/kits/`"], "Kits ready for review"),
            D("Beta community comms",
              ["Write Beta announcement for EA players",
               "Explain what Beta means for saves (migration guarantee)",
               "Set up feedback form fields (no personal data beyond what is needed)",
               "Schedule with the patch cadence"], "Beta comms published")] +
           [D(f"Marketing beat review Q{q}",
              [f"Review Q{q} beats against plan; collect wishlist/follower data",
               "Adjust next quarter's beats",
               "Request next assets from team streams",
               f"Update `production/marketing/launch_plan.md` (Q{q})"], f"Q{q} beat review logged") for q in range(1, 5)],
           ["Festival date moves", "Leak of ending content"], "production/marketing/launch_plan.md + kits")

    ph.add("main", "secondary", "Open world and level polish per region",
           "P7a: discovery, POIs, traversal unlocks; level design is the user's job from Y3", ["level", "openworld"],
           sum([[D(f"{r} {rn} level polish: POIs and discoveries",
                   [f"Walk {r} with the fog-of-war map; list POIs without a reward or with a dull reward",
                    "Check traversal gates are ability-based, never invisible walls",
                    "Check waystation spacing for fast travel",
                    f"Fix layouts in `scenes/regions/{r.lower()}/` chunks"], f"{r} POIs all rewarding"),
                 D(f"{r} {rn} level polish: dynamic events and seams",
                   [f"Trigger each {r} dynamic world event at its calendar time; check readability",
                    f"Walk both seams into and out of {r}; no visual pop or collision snag",
                    "Check terrain context feeds the combat arena generator correctly",
                    f"Capture `production/qa/evidence/y7/level/{r}.png`"], f"{r} events and seams clean")] for r, rn, _ in REGIONS], []),
           ["Event triggered while player is in combat", "Seam crossed during fast travel"], "production/qa/evidence/y7/level/")

    ph.add("main", "secondary", "Story continuity review per storyline",
           "P3: each storyline changes >= 3 scenes, has its own ending and Story+ state", ["story", "cinematics"],
           [D(f"Story review: {s['kind']} {s['sid']}",
              [f"Watch the bot capture set for {s['sid']} (Medium, on-time) from the nightly matrix",
               f"Check {s['sid']} changes at least 3 story scenes, has its ending sequence and Story+ state",
               "Check axis values and companion/timing modifiers appear in ending slides",
               f"File continuity issues against `story/` scripts with {s['sid']} tag"],
              f"{s['sid']} continuity signed off or issues filed") for s in STORYLINES[:14]],
           ["Companion dead but referenced in slides"], "production/qa/y7/story/S01..S14.md")
    ph.add("main", "secondary", "Story continuity review per storyline (part 2)",
           "P3/P8/P10", ["story", "cinematics"],
           [D(f"Story review: {s['kind']} {s['sid']}",
              [f"Watch the bot capture set for {s['sid']} (Medium, on-time) from the nightly matrix",
               f"Check {s['sid']} changes at least 3 story scenes, has its ending sequence and Story+ state",
               "Check the ending is framed by who authorizes change (Sole / Bound / No Authority / Consent)",
               f"File continuity issues against `story/` scripts with {s['sid']} tag"],
              f"{s['sid']} continuity signed off or issues filed") for s in STORYLINES[14:]],
           ["Secret storyline reached on Beginner"], "production/qa/y7/story/S15..SS3.md")

    ph.add("main", "secondary", "Cinematics review per act",
           "§4.7 cutscene timelines; P9 juice", ["cinematics", "story"],
           [D(f"Cinematics review: {a}",
              [f"Watch all {a} cutscenes in EN and zh-Hans",
               "Check timing, camera, music cues and subtitle readability",
               "List polish requests for art/audio",
               "Approve or return each cutscene"], f"{a} cutscenes approved or returned")
            for a in ["Act 1", "Act 2", "Act 3", "Act 4", "Story+"]],
           ["Subtitle overlapping a letterbox"], "production/qa/y7/cinematics/review.md")

    ph.add("main", "secondary", "Monthly team review and burnout check",
           "Risk register: burnout and key-person risk", ["team"],
           [D(f"Y7 month {m:02d} team review",
              ["Run `/sprint-status` and compare against the Y7 plan",
               "Check each person's load and energy (risk register: burnout)",
               "Re-balance work between streams if needed",
               f"Record in `production/team/y7_m{m:02d}.md`"], f"Y7 month {m:02d} review logged") for m in range(1, 13)],
           ["Two team members out in the same month"], "production/team/")

    ph.add("tail", "secondary", "Gate 7 content and production sign-off",
           "ROADMAP §10 G7", ["release", "team"],
           [D("Gate 7: content sign-off",
              ["Confirm every storyline completable from the matrix dashboard", "Confirm loc and a11y sign-offs",
               "Confirm ratings and legal status", "Write content section of gate7.md"], "Content section complete"),
            D("Gate 7: launch readiness preview",
              ["Run `/launch-checklist` in preview mode", "List launch blockers by department", "Agree launch date target ~2034-02-15 or a slip", "Record decision input for the Gate 7 ADR"],
              "Launch readiness preview recorded")],
           ["Storyline completable only on some difficulties"], "production/milestones/gate7.md")

    PF = Filler(
        lambda i: D(f"Playtest feedback PF-{i + 1:03d}: {REGIONS[i % 8][0]} {REGIONS[i % 8][1]} - {['combat pacing', 'quest clarity', 'market UX', 'NPC reactions', 'traversal', 'difficulty spikes', 'story beats', 'reward feel'][(i // 8) % 8]}",
                    [f"Run `/playtest-report` on this week's notes for {REGIONS[i % 8][0]} filtered to {['combat pacing', 'quest clarity', 'market UX', 'NPC reactions', 'traversal', 'difficulty spikes', 'story beats', 'reward feel'][(i // 8) % 8]}",
                     "Group findings; separate bugs from design issues",
                     "Make data-only fixes directly; file the rest with owners",
                     "Note any finding that touches a Gate 7 criterion"],
                    f"PF-{i + 1:03d} findings actioned or filed"),
        lambda n: f"Beta playtest feedback integration {n:02d}", "§8 Beta: fairness, fun and clarity", ["fun", "level", "quests"],
        ["Feedback contradicting a pillar (e.g. 'make Hell easier')"], "production/qa/y7/playtest/", "secondary")
    ph.set_filler("secondary", PF, 5)

    # ============================== ART ==============================
    for g in [BOSSES[i:i + 6] for i in range(0, 24, 6)]:
        ph.add("main", "art", f"Boss telegraph and animation polish {g[0]['bid']}-{g[-1]['bid']}",
               "P2/P6: telegraphs readable at Hell x0.7 speed", ["art", "animation", "vfx"],
               [D(f"Telegraph polish: {b['bid']} {b['bname']} ({b['rid']})",
                  [f"Review {b['bid']} attack tells at x0.7 speed (Hell) on the busiest arena background",
                   "Strengthen anticipation frames or tell VFX without changing frame data length",
                   "Check colourblind modes keep the tell distinct",
                   f"Export through the PAE pipeline; capture `production/qa/evidence/y7/art/{b['bid']}_tell.png`"],
                  f"{b['bid']} tells readable at Hell speed") for b in g],
               ["Tell overlapped by hit-spark of another attack"], "production/qa/evidence/y7/art/")
    ph.add("main", "art", "Region art polish passes", "Shared props/decals P0 targets; accepted baselines protected (AGENTS.md)",
           ["art", "assets", "openworld"],
           sum([[D(f"{r} {rn} art polish: props and decals", [f"List visible prop/decal issues in {r} from QA and fairness notes",
                                                              "Fix only visible, specific issues; do not replace accepted baselines",
                                                              "Keep fallbacks working; run the fallback check",
                                                              f"Capture before/after in `production/qa/evidence/y7/art/{r}_props.png`"], f"{r} prop issues fixed"),
                 D(f"{r} {rn} art polish: seams and readability", [f"Fix tile seams at {r} borders and chunk edges",
                                                                    "Check interactables stand out from background at 1x",
                                                                    "Check night palette readability",
                                                                    f"Capture `production/qa/evidence/y7/art/{r}_seams.png`"], f"{r} seams and readability fixed")]
                 for r, rn, _ in REGIONS], []),
           ["Polish breaks a collision-matched tile (do not change collision)"], "production/qa/evidence/y7/art/")
    ph.add("main", "art", "Player animation polish by clip group", "P2 + §3 ~40 clips + 4-direction set", ["animation", "art"],
           [D(f"Animation polish {ag}: {an}",
              [f"Review {ag} clips frame by frame against frame data (no length changes without primary approval)",
               "Fix silhouette, smear frames and weapon sprite alignment per weapon class",
               "Check palette/overlay armor layers stay aligned",
               f"Export and capture `production/qa/evidence/y7/anim/{ag}.png`"], f"{ag} polished") for ag, an in ANIM_GROUPS],
           ["Overlay layer misaligned on one direction"], "production/qa/evidence/y7/anim/")
    ph.add("main", "art", "Accessibility visuals", "§8 accessibility pass", ["accessibility", "vfx", "art"],
           [D(f"Colourblind-safe variant for VFX family {vf}",
              [f"Check {vf} in protanopia, deuteranopia, tritanopia simulations",
               "Add shape or pattern cue so meaning is never colour-only",
               "Keep particle count inside budget",
               f"Capture `production/qa/evidence/y7/a11y/{vf}.png`"], f"{vf} readable in all modes") for vf in VFX_FAMILIES] +
           [D(f"Reduced-flash variant set {k}",
              [f"Produce reduced-flash variants for glitch overlay and hit flashes (set {k})",
               "Wire to AX05 slider levels",
               "Check against photosensitivity guidance (check current guidance)",
               "Capture comparison"], f"Reduced-flash set {k} done") for k in range(1, 4)] +
           [D("High-contrast UI skin", ["Produce high-contrast theme variant for SC01-SC24", "Check contrast ratios", "Hand theme to primary", "Capture comparison"], "High-contrast skin delivered")],
           ["Glitch aesthetic conflicts with reduced flash"], "production/qa/evidence/y7/a11y/")
    ph.add("main", "art", "zh-Hans art text and font checks", "§3 languages", ["localization", "art", "ui"],
           [D("Text-in-image audit", ["List every image containing text (logos, signs, UI art)", "Decide localize vs keep per item", "Export source layers", "Track in `production/qa/y7/loc/text_in_art.md`"], "Text-in-image list complete"),
            D("Localized art exports batch 1", ["Recreate zh-Hans versions of UI art items 1-15", "Check pixel font readability", "Import with fallbacks", "Capture"], "Batch 1 done"),
            D("Localized art exports batch 2", ["Recreate zh-Hans versions of signage and logo items", "Check against glossary", "Import", "Capture"], "Batch 2 done"),
            D("CJK pixel font review", ["Review CJK fallback font at 1x/2x with the art bible", "Tune outline/shadow", "Check in dialogue box SC08", "Capture"], "Font look approved")],
           ["Logo trademark in zh-Hans"], "production/qa/y7/loc/text_in_art.md")
    ph.add("main", "art", "Marketing art for launch", "§8 launch marketing", ["marketing", "art"],
           [D(f"Marketing art: {x}", [f"Produce {x} per the launch plan", "Check current store spec sizes (check current rules)", "Get user approval", "Export to `production/marketing/assets/`"], f"{x} approved")
            for x in ["key art sketch", "key art final line", "key art final colour", "capsule set small/main", "capsule set header/library",
                      "logo lockups EN/zh-Hans", "press kit art", "social banner set", "trailer title cards", "trailer end card"]] +
           [D(f"Store screenshots {r} {rn}", [f"Stage the best {r} vista and combat shot", "Hide debug UI; use the shipping HUD", "Capture at store resolution", f"Save `production/marketing/assets/{r}_shots/`"], f"{r} shots ready") for r, rn, _ in REGIONS],
           ["Screenshot showing ending spoilers"], "production/marketing/assets/")
    ph.add("main", "art", "Cinematic and credits art polish", "§4.7 cutscenes; credits", ["cinematics", "art"],
           [D(f"Cinematic art polish: {a}", [f"Fix art issues listed in the {a} cinematics review", "Check letterbox and subtitle space", "Re-export frames", "Capture"], f"{a} cinematic art fixed")
            for a in ["Act 1", "Act 2", "Act 3", "Act 4", "Story+"]] +
           [D("Credits screen art", ["Lay out credits roll art per screen", "Check zh-Hans name rendering", "Hand to primary", "Capture"], "Credits art delivered")],
           ["Credits longer than music track"], "production/qa/evidence/y7/cinematics/")
    ph.add("main", "art", "Asset audit per region", "Asset standards; clean folders", ["assets", "cleanup"],
           [D(f"`/asset-audit` {r} {rn}", [f"Run `/asset-audit` on `assets/` for {r}", "Fix naming and size budget violations", "Remove orphans with approval", f"Record `production/qa/y7/assets/{r}.md`"], f"{r} asset audit clean") for r, rn, _ in REGIONS],
           ["Asset shared across regions"], "production/qa/y7/assets/")
    AB = Filler(lambda i: D(f"Art bug batch AB-{i + 1:03d}: {REGIONS[i % 8][0]} {['tiles', 'props', 'NPC sprites', 'enemy sprites', 'UI art', 'VFX', 'icons', 'portraits'][(i // 8) % 8]}",
                            [f"Pull open art bugs for {REGIONS[i % 8][0]} {['tiles', 'props', 'NPC sprites', 'enemy sprites', 'UI art', 'VFX', 'icons', 'portraits'][(i // 8) % 8]}",
                             "Fix the top 4; keep fallbacks; protected baselines untouched",
                             "Run the import and fallback checks",
                             "Capture evidence and close issues"], f"AB-{i + 1:03d} closed"),
                lambda n: f"Art bug batch block {n:02d}", "Gate 7: no high bugs", ["art", "assets"], ["Fix needed in a protected baseline (escalate)"],
                "production/qa/evidence/y7/art/bugs/", "art")
    ph.set_filler("art", AB, 5)

    # ============================== AUDIO ==============================
    for k in range(9):
        g = MUSIC[k * 5:(k + 1) * 5]
        ph.add("main", "audio", f"Music master pass {g[0]}-{g[-1]}", "§3 ~45 tracks; P9 adaptive music", ["music", "audio"],
               [D(f"Master {mt}", [f"Check {mt} loop points and stems for adaptive layers", "Master to the project loudness target (check current platform guidance)",
                                   "Check transitions into combat stingers", f"Export to `assets/audio/music/{mt}`; log in mastering sheet"], f"{mt} mastered") for mt in g],
               ["Loop click at boundary"], "production/qa/y7/audio/mastering.md")
    ph.add("main", "audio", "SFX audit batches (~900 SFX)", "§3 ~900 SFX", ["audio"],
           [D(f"SFX batch {sb} (~50 SFX)", [f"Audit {sb} files: naming, peak, length, variation count", "Fix clipping and dull variations", "Check bus routing",
                                            f"Log `production/qa/y7/audio/{sb}.md`"], f"{sb} audited") for sb in SFXB],
           ["SFX used by both world and arena with different mix"], "production/qa/y7/audio/")
    for g in [BOSSES[i:i + 6] for i in range(0, 24, 6)]:
        ph.add("main", "audio", f"Boss tell audio cues {g[0]['bid']}-{g[-1]['bid']}", "P6 Hell fairness + accessibility (sound tells)", ["audio", "accessibility", "combat"],
               [D(f"Tell audio: {b['bid']} {b['bname']}", [f"Give every {b['bid']} attack a distinct tell cue starting with the visual tell",
                                                           "Check cue audible over music in the arena mix", "Map cue to AX06 visualisation icon",
                                                           f"Log `production/qa/y7/audio/tells_{b['bid']}.md`"], f"{b['bid']} tells have audio") for b in g],
               ["Two attacks with identical cue"], "production/qa/y7/audio/")
    ph.add("main", "audio", "Region mix and adaptive music verification", "P9 adaptive music", ["audio", "music", "openworld"],
           sum([[D(f"{r} {rn} mix pass", [f"Mix ambience, music, SFX in {r} day and night", "Check festival day density", "Check dialogue ducking", f"Log `production/qa/y7/audio/{r}_mix.md`"], f"{r} mix approved"),
                 D(f"{r} {rn} adaptive music check", [f"Trigger explore/tension/combat states in {r}", "Check transitions on the beat", "Check the combat shatter transition", f"Log `production/qa/y7/audio/{r}_adaptive.md`"], f"{r} adaptive music correct")]
                 for r, rn, _ in REGIONS], []),
           ["Music state stuck after interrupted combat"], "production/qa/y7/audio/")
    ph.add("main", "audio", "Audio accessibility and haptics", "§8 accessibility; P9", ["audio", "accessibility"],
           [D(f"Haptics pairing: {h}", [f"Author haptic pattern for {h}", "Tie intensity to AX12", "Test on two controllers", "Log"], f"{h} haptics done")
            for h in ["light hits", "heavy hits", "parry", "dodge", "hurt", "Root Access", "UI confirm", "world events"]] +
           [D("Mono mix and separate volume sliders", ["Add mono downmix check", "Verify music/SFX/voice/UI sliders", "Check AX06 visual cues match", "Log"], "Mono and sliders verified"),
            D("Sound captions list", ["List SFX needing captions (off-screen threats, tells)", "Hand list to writing", "Verify caption timing", "Log"], "Caption list delivered")],
           ["Haptics on unsupported controller"], "production/qa/y7/audio/a11y.md")
    ph.add("main", "audio", "Minigame and gambling audio pass", "P7c", ["audio", "fun"],
           [D(f"Audio pass: {x}", [f"Review {x} feedback sounds", "Fix missing win/lose/near-miss sounds (no manipulative near-miss emphasis)", "Mix", "Log"], f"{x} audio done")
            for x in [f"{m} {mn}" for m, mn in MINIGAMES] + [f"{g} {gn}" for g, gn in GAMBLING]],
           ["Rhythm game latency vs calibration"], "production/qa/y7/audio/minigames.md")
    ph.add("main", "audio", "Trailer, Deck and loudness compliance", "§8 marketing + Deck", ["audio", "marketing"],
           [D(x, [s1, s2, s3, "Log in `production/qa/y7/audio/`"], d) for x, s1, s2, s3, d in [
               ("Trailer music cue edit", "Edit a 90 s cue from approved tracks to the trailer script", "Hit beats on transitions", "Get user approval", "Trailer cue approved"),
               ("Trailer mix", "Mix SFX highlights over the cue", "Check loudness for video platforms (check current guidance)", "Export stems", "Trailer mix delivered"),
               ("Steam Deck speakers mix check", "Play R1, R4, R8 on Deck speakers", "Adjust low-end and dialogue clarity preset", "Check headphones", "Deck mix ok"),
               ("Loudness compliance sweep", "Measure integrated loudness per scene type", "Align to target", "Document target", "Loudness consistent"),
               ("Audio licence and provenance", "List every music/SFX source and licence", "Flag unclear sources", "Feed the legal audit", "Audio provenance complete")]],
           ["Licensed SFX library terms for trailers"], "production/qa/y7/audio/")
    AU = Filler(lambda i: D(f"Audio bug batch AU-{i + 1:03d}: {REGIONS[i % 8][0]} {['ambience', 'footsteps', 'combat SFX', 'UI sounds', 'music transitions', 'NPC barks', 'world events', 'cutscene audio'][(i // 8) % 8]}",
                            [f"Pull open audio bugs for {REGIONS[i % 8][0]} {['ambience', 'footsteps', 'combat SFX', 'UI sounds', 'music transitions', 'NPC barks', 'world events', 'cutscene audio'][(i // 8) % 8]}",
                             "Fix top 4", "Re-test in game", "Close issues"], f"AU-{i + 1:03d} closed"),
                lambda n: f"Audio bug batch block {n:02d}", "Gate 7: no high bugs", ["audio"], ["Bug only on surround output"], "production/qa/y7/audio/bugs/", "audio")
    ph.set_filler("audio", AU, 5)

    # ============================== WRITING ==============================
    for k in range(4):
        g = LOC_BATCHES[k * 5:(k + 1) * 5]
        days = []
        for lb, ln in g:
            days.append(D(f"Source freeze for {lb} ({ln})", [f"Freeze EN source for {lb}; fix typos and voice issues first", "Add context notes per line (speaker, situation, length limit)",
                                                             "Mark placeholders and variables", f"Export {lb} string table for translation"], f"{lb} frozen and exported"))
            days.append(D(f"LQA response for {lb}", [f"Read {lb} LQA issues tagged 'source'", "Fix source ambiguities and update context notes",
                                                     "Confirm glossary terms used consistently", f"Close {lb} source issues"], f"{lb} source issues closed"))
        ph.add("main", "writing", f"Localization source prep and LQA response {g[0][0]}-{g[-1][0]}", "§8 localization", ["localization", "dialogue"], days,
               ["Line reused in two contexts"], "docs/localization/batches/")
    for r, rn, _ in REGIONS:
        tqs = [t for t in TQS if t["rid"] == r]
        ph.add("main", "writing", f"Deadline signpost text for {r} {rn}", "§12.4 fairness: deadline with in-world reason; Story+ shows what timing changed", ["quests", "dialogue", "time"],
               [D(f"Signpost text {t['tq']} ({t['ttype']} quest, {r})",
                  [f"Write the quest-log deadline line for {t['tq']} with its in-world reason (per VOICE_GUIDE)",
                   f"Write the warning bark/notice shown before {t['tq']} closes",
                   f"Write the Story+ line describing what the player's timing changed for {t['tq']}",
                   "Add zh-Hans context note; no new canon beyond the quest's design doc"],
                  f"{t['tq']} signpost text in the string table") for t in tqs],
               ["Deadline text with a variable day count"], f"string tables for {r} TQs")
    ph.add("main", "writing", "Ending slide and Story+ text polish per storyline", "P3/P8", ["story", "dialogue"],
           [D(f"Ending text polish: {s['sid']}", [f"Read {s['sid']}'s composed ending slides from the bot capture", "Fix seams between modular slide texts",
                                                 "Check the authorization framing per bible", f"Commit fixes tagged {s['sid']}"], f"{s['sid']} ending text clean") for s in STORYLINES],
           ["Slide combining contradictory companion states"], "production/qa/y7/story/")
    ph.add("main", "writing", "Captions and accessibility text", "§8 accessibility", ["accessibility", "dialogue"],
           [D(f"Captions and speaker labels: {r} {rn}", [f"Add speaker labels for all {r} dialogue", "Write sound captions from the audio list", "Check caption length", "Commit"], f"{r} captions done") for r, rn, _ in REGIONS],
           ["Unnamed Voice speaker label (Mira, unnamed)"], "string tables")
    ph.add("main", "writing", "Store, press and credits copy", "§8 marketing; credits", ["marketing", "docs"],
           [D(x, [s1, "Match voice guide tone", "Get user approval", "Hand to zh-Hans translation"], d) for x, s1, d in [
               ("Store page short description", "Write 3 options for the short description", "Short description chosen"),
               ("Store page long description", "Write long description with pillars", "Long description chosen"),
               ("Press release draft for 1.0 date", "Draft release text with placeholders for date", "Draft approved"),
               ("Fact sheet copy", "Write fact sheet copy", "Fact sheet done"),
               ("Trailer text cards", "Write trailer cards", "Cards done"),
               ("Credits formatting", "Format credits text", "Credits formatted"),
               ("Beta FAQ", "Write FAQ for EA players about Beta and saves", "FAQ published"),
               ("Fairness survey wording", "Polish survey items for clarity", "Survey wording final")]],
           ["Spoilers in store copy"], "production/marketing/copy/")
    ph.add("main", "writing", "Codex and bestiary text check", "Lore consistency with STORY_BIBLE", ["story", "docs"],
           [D(f"Codex check {r} {rn}", [f"Check {r} codex/bestiary entries against STORY_BIBLE", "Fix contradictions", "Check lengths for zh-Hans", "Commit"], f"{r} codex consistent") for r, rn, _ in REGIONS],
           ["Entry unlocking only in Story+"], "string tables")
    WR = Filler(lambda i: D(f"Text bug batch WR-{i + 1:03d}: {REGIONS[i % 8][0]} {['typos', 'overflow', 'continuity', 'tone', 'missing keys', 'barks', 'item text', 'quest log'][(i // 8) % 8]}",
                            [f"Pull open text bugs: {REGIONS[i % 8][0]} {['typos', 'overflow', 'continuity', 'tone', 'missing keys', 'barks', 'item text', 'quest log'][(i // 8) % 8]}",
                             "Fix in EN; flag zh-Hans updates", "Verify in game", "Close issues"], f"WR-{i + 1:03d} closed"),
                lambda n: f"Text bug batch block {n:02d}", "Gate 7 quality", ["dialogue", "localization"], ["Fix changes a translated line's meaning"], "string table diffs", "writing")
    ph.set_filler("writing", WR, 5)

    # ============================== QA ==============================
    for k in range(0, 27, 9):
        g = STORYLINES[k:k + 9]
        ph.add("main", "qa", f"QA matrix runs {g[0]['sid']}-{g[-1]['sid']}", "§8 coverage: storyline x difficulty x timing", ["tests", "story", "difficulty", "time"],
               [D(f"Matrix row {s['sid']}: 5 difficulties x 3 timing profiles", [f"Review the 15 nightly cells for {s['sid']}; re-run red ones manually",
                                                                                 "Play the ending sequence and Story+ entry on one cell by hand",
                                                                                 "Verify pace/timing flags against the composer table", f"Update dashboard row {s['sid']}"], f"{s['sid']} row verified") for s in g],
               ["Cell passing in bot but failing by hand"], "production/qa/y7/matrix/dashboard.md")
    for g in [BOSSES[i:i + 8] for i in range(0, 24, 8)]:
        ph.add("main", "qa", f"Hell fairness sessions {g[0]['bid']}-{g[-1]['bid']}", "§8 fairness surveys + replay checks", ["difficulty", "tests"],
               [D(f"Hell session {b['bid']} {b['bname']}", [f"Play {b['bid']} on Hell with latency calibration set; attempt Hell-only phase", "Fill fairness survey items",
                                                          "Note any input eaten by buffer or calibration", f"Log `production/qa/y7/fairness/{b['bid']}.md`"], f"{b['bid']} Hell session logged") for b in g],
               ["Controller vs keyboard difference"], "production/qa/y7/fairness/")
    ph.add("main", "qa", "Perf and Steam Deck checks per region", "§8 performance", ["performance", "tests"],
           sum([[D(f"Min-spec playthrough {r} {rn}", [f"Play {r} 1 hour on min spec with FPS overlay", "Log hitches with timestamps and positions", "Attach to perf issues", f"Log `production/qa/y7/perf/{r}_manual.md`"], f"{r} min-spec log done"),
                 D(f"Steam Deck playthrough {r} {rn}", [f"Play {r} 1 hour on Deck", "Check text legibility and glyphs", "Check sleep/resume", f"Log `production/qa/y7/perf/{r}_deck.md`"], f"{r} Deck log done")] for r, rn, _ in REGIONS], []),
           ["Thermal throttling after 40 minutes"], "production/qa/y7/perf/")
    for k in range(0, 20, 5):
        g = LOC_BATCHES[k:k + 5]
        ph.add("main", "qa", f"Linguistic QA {g[0][0]}-{g[-1][0]}", "§8 LQA", ["localization", "tests"],
               sum([[D(f"LQA {lb} in-game pass ({ln})", [f"Play the content of {lb} in zh-Hans", "Log truncation, wrong font, untranslated keys, glossary misuse", "Classify severity per LQA rules", "Screenshot each issue"], f"{lb} in-game pass logged"),
                     D(f"LQA {lb} regression after fixes", [f"Verify fixed {lb} issues", "Spot-check 30 random lines", "Report residual issues", f"Report `production/qa/y7/loc/{lb}_lqa.md`"], f"{lb} LQA report final")] for lb, ln in g], []),
               ["Line only visible on one route"], "production/qa/y7/loc/")
    for half, scr in (("SC01-SC12", SCREENS[:12]), ("SC13-SC24", SCREENS[12:])):
        ph.add("main", "qa", f"Accessibility test pass per screen ({half})", "§8 accessibility", ["accessibility", "tests"],
               [D(f"A11y test {sc} {sn}", [f"Test {sn} gamepad-only, keyboard-only, 200% text", "Test colourblind modes and reduced flash", "Test with remapped controls", f"Evidence `production/qa/evidence/y7/a11y/{sc}_qa.png`"], f"{sc} pass/fail logged") for sc, sn in scr],
               ["Remapped confirm key on popups"], "production/qa/evidence/y7/a11y/")
    ph.add("main", "qa", "Exploit reproduction", "§8 exploit hunting", ["economy", "tests"],
           [D(f"Exploit repro {x}", [f"Try to reproduce known and new exploits manually in {x}", "Record exact steps and save", "Verify primary's fix", "Log"], f"{x} exploit check logged")
            for x in CGS + AHS + [g for g, _ in GAMBLING]],
           ["Exploit across save/load"], "production/qa/y7/econ/manual/")
    for r, rn, _ in REGIONS:
        tqs = [t for t in TQS if t["rid"] == r]
        ph.add("main", "qa", f"Time-sensitive quest verification {r}", "§12.4 fairness", ["time", "quests", "tests"],
               [D(f"Verify {t['tq']} ({t['ttype']})", [f"Play {t['tq']} on Beginner (leniency x1.5) and Hell (x0.85); compute expected days", "Check signpost text and warning timing",
                                                      "Let it fail once; confirm Story+ reflects it", f"Log `production/qa/y7/time/{t['tq']}.md`"], f"{t['tq']} verified") for t in tqs],
               ["Deadline crossing a season change"], "production/qa/y7/time/")
    ph.add("main", "qa", "Ratings capture and save migration checks", "§8 ratings; save safety", ["legal", "save", "tests"],
           [D("Rating footage capture: gambling G1-G3", ["Capture each table session", "Note currency and limits on screen", "Store in `production/ratings/`", "Log"], "Gambling footage stored"),
            D("Rating footage capture: violence peaks", ["Capture B23 and B24 fights and death screens", "Capture crime/witness events", "Store", "Log"], "Violence footage stored"),
            D("Rating footage capture: language and themes", ["Capture dialogue samples flagged by writing", "Store", "Index", "Log"], "Theme footage stored")] +
           [D(f"Manual save migration check: Act {a}", [f"Load EA saves from Act {a} into Beta", "Play 30 minutes", "Check flags, clock, inventory", "Log"], f"Act {a} saves fine") for a in range(1, 5)],
           ["Save from a build with a removed item"], "production/ratings/ + production/qa/y7/save/")
    ph.add("main", "qa", "EA update regression runs", "Live-ops cadence", ["tests", "release"],
           [D(f"Regression for EA update U7-{i:02d}", [f"Run `/regression-suite` checklist on U7-{i:02d} candidate", "Play the critical path 1 hour", "Verify release notes items", "Sign off or block"], f"U7-{i:02d} signed off") for i in range(1, 13)],
           ["Patch downloaded mid-session"], "production/qa/y7/regression/")
    EC = Filler(lambda i: D(f"Exploratory charter EC-{i + 1:03d}: {REGIONS[i % 8][0]} x {SYSTEMS[(i // 8) % 15]}",
                            [f"Timebox 3 h exploring {SYSTEMS[(i // 8) % 15]} in {REGIONS[i % 8][0]} {REGIONS[i % 8][1]}", "Try odd orders, pauses, save/load at awkward moments",
                             "Log bugs with saves and video", "Summarise risk"], f"EC-{i + 1:03d} charter report filed"),
                lambda n: f"Exploratory charters block {n:02d}", "Edge cases before RC", ["tests"], ["Bug requiring 2 systems at once"], "production/qa/y7/charters/", "qa")
    ph.set_filler("qa", EC, 5)
    add_extra(ph)
    return ph


if __name__ == "__main__":
    ph = build()
    print(ph.counts())
