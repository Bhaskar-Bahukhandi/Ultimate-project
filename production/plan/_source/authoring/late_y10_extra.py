"""Extra Y10 families + ordering (3.0.0 release anchored ~70% of the year)."""
from late_common import *


def add_extra(ph):
    # ---------------- PRIMARY ----------------
    ph.spec("primary", "Code health for the new systems", "Coding standards; R7 one owner per concern; security", ["code", "tests", "cleanup", "architecture", "ai"],
            [(f"Regression coverage: {x}", [f"Run `/regression-suite` for {x}", "List fixed bugs lacking tests", "Write missing tests", "Record coverage delta"], f"{x} covered") for x in ("NG+ service", "Story+ extensions", "X1 systems", "X2 systems", "PlatformService", "leaderboards/speedrun")] +
            [(f"Static typing pass: {f}", [f"Type `{f}` fully; warnings as errors", "Run suite", "Record exceptions", "Commit"], f"{f} typed") for f in ("scripts/ngplus/", "scripts/storyplus/", "scripts/expansion1/", "scripts/expansion2/")] +
            [(f"Deprecation sweep {k}", [f"{['Remove dead feature flags', 'Remove unused debug paths (keep debug_test_mode)', 'Collapse duplicate helpers into their owning service', 'Delete orphaned test fixtures (never save fixtures)'][k - 1]}", "Suite + replays green", "Record in cleanup doc", "Commit as `refactor:`"], f"Sweep {k} done") for k in range(1, 5)] +
            [(f"`/security-audit` {x}", [f"Audit {x}", "List tampering/cheat vectors", "Fix or document honestly", "Record"], f"{x} audited") for x in ("save files", "leaderboard submissions", "DLC entitlement checks", "telemetry data exposure")] +
            [(f"Console requirement refresh {p}", [f"Re-check current {n} requirements (check current)", "Fix gaps via partner", "Record", "Archive"], f"{p} refreshed") for p, n in PLATFORMS] +
            [(f"NG+3 load performance {r} {rn}", [f"Profile {r} in NG+3 with remixed markets and full NPC sim", "Fix top hotspot", "Budgets", "Record"], f"{r} NG+3 perf ok") for r, rn, _ in REGIONS] +
            [(f"Nightly bot: NG+ coverage {k}", [f"{['Add NG+1 cells for 27 storylines', 'Add NG+2/NG+3 sample cells', 'Add Story+ extension cells', 'Dashboard and flake handling'][k - 1]}", "Seeded runs", "Record", "Dashboard"], f"NG+ bot {k}") for k in range(1, 5)] +
            [(f"AccessKit menu narration improvements {k}", [f"Extend narration to {['options/remap', 'inventory/equipment', 'market/auction', 'quest log/map'][k - 1]} screens", "Test with a screen reader (check current Godot support)", "Evidence", "Record"], f"Narration {k}") for k in range(1, 5)] +
            [("Telemetry decade report", ["Aggregate 10-year opt-in telemetry", "Charts for the retrospective", "Privacy check", "Record"], "Telemetry report"),
             ("X2 telemetry", ["Add X2 events (opt-in)", "Dashboard", "Privacy check", "Record"], "X2 telemetry live"),
             ("Dependency updates 1", ["Update test addons (gdUnit4) on a branch", "Run suite", "Merge or hold", "Record"], "Deps 1"),
             ("Dependency updates 2", ["Update tools/scripts deps", "Run CI", "Record", "Licence check"], "Deps 2"),
             ("Dependency updates 3", ["Re-verify licences after updates", "Update notices", "Record", "Archive"], "Deps 3")] +
            [(f"Story+ extension bot checks {fid}", [f"Bot paths through {fn} extension cases", "Assert unlocks per storyline", "Record", "Fix"], f"{fid} bot ok") for fid, fn in ENDING_FAMILIES] +
            [(f"Engine LTS upgrade execution {k}", [f"{['Apply upgrade branch per ADR (or skip if ADR froze)', 'Fix API breaks', 'Re-record any replay whose checksum legitimately changed (with review)', 'Partner console build', 'Perf comparison', 'Export all platforms', 'Full matrix run', 'Merge and tag'][k - 1]}", "No gameplay change", "Record", "Archive"], f"LTS step {k}") for k in range(1, 9)],
            ["Upgrade alters determinism"], "production/qa/y10/code_health.md")

    # ---------------- SECONDARY ----------------
    ph.fam("secondary", "NG+ live difficulty review per boss", "P6 after NG+ release", ["difficulty", "combat"], ALL_BOSS_IDS,
           lambda b: f"NG+ live difficulty review {b}",
           lambda b: [f"Read NG+ deaths/attempts for {b} per cycle and difficulty", "Compare with remix spec", "Data-only tuning proposals", f"Record `production/live/difficulty/ngplus_{b}.md`"],
           lambda b: f"{b} NG+ reviewed", ["NG+ data dominated by Hell players"], "production/live/difficulty/", chunk=7)
    ph.spec("secondary", "Y10 live reviews", "P3/P7b live truth", ["story", "economy"],
            [(f"NG+ storyline reach {g[0]['sid']}-{g[-1]['sid']}", ["Read which storylines NG+ players pick", "Compare with first runs", "Note signposting issues", "Record"], "Reviewed") for g in [STORYLINES[i:i + 3] for i in range(0, 27, 3)]] +
            [(f"Economy telemetry review Y10 month {m}", [f"Compare live economy (month {m}) incl. NG+ carryover with the sim", "Alerts", "Data changes", "Record"], f"Y10 month {m} econ") for m in range(1, 9)],
            ["NG+ inflation"], "production/live/")

    # ---------------- ART ----------------
    ph.spec("art", "Y10 art extras", "P8; long-tail quality; handover", ["art", "ui", "docs", "marketing"],
            [(f"Story+ extension slide variants {g[0]['sid']}-{g[-1]['sid']}", ["Produce per-storyline extension slide variants", "Composition seams", "Import", "Capture"], "Variants done") for g in [STORYLINES[i:i + 3] for i in range(0, 27, 3)]] +
            [(f"Art refresh Y10 {r} ({k})", [f"Fix the #{k} reported visual issue in {r}", "Baselines protected", "Capture", "Close"], f"{r} refresh {k}") for r, _, _ in REGIONS for k in (1, 2)] +
            [(f"NG+ title card {cyc}", [f"Produce {cyc} title card", "Readability", "Approve", "Import"], f"{cyc} card") for cyc in NG_CYCLES] +
            [(f"X2 Hell title icons {k}", ["Produce X2 Hell titles", "Readability", "Approve", "Archive"], f"X2 titles {k}") for k in (1, 2, 3)] +
            [(f"Console legibility X2/NG+ {k}", ["Check new screens at TV distance", "Fix", "Capture", "Record"], f"Legibility {k}") for k in range(1, 5)] +
            [(f"Art handover rehearsal {k}", [f"{['Second person rebuilds a tile set from docs', 'Second person imports a sprite via PAE pipeline', 'Fix doc gaps'][k - 1]}", "Record", "Archive", "Review"], f"Handover {k}") for k in (1, 2, 3)] +
            [(f"Decade art book selection {k}", [f"Select and caption art for the decade art book section {k}", "Rights check (contractors)", "Layout draft", "Approve"], f"Art book {k}") for k in range(1, 7)],
            ["Contractor art rights for the art book"], "production/qa/evidence/y10/art/")

    # ---------------- AUDIO ----------------
    ph.spec("audio", "Y10 audio extras", "P8/P9; upkeep; handover", ["audio", "music", "docs"],
            [(f"X2 seasonal ambience {se}", [f"Add {se} layers for X2", "Mix", "Integrate", "Record"], f"X2 {se}") for se in SEASONS] +
            [(f"Story+ extension music variants {g[0]['sid']}-{g[-1]['sid']}", ["Per-storyline cue variants for extension epilogues", "Mix", "Integrate", "Record"], "Variants done") for g in [STORYLINES[i:i + 3] for i in range(0, 27, 3)]] +
            [(f"Audio refresh Y10 {r}", [f"Fix the most-reported audio issue in {r}", "Mix", "Re-test", "Close"], f"{r} refreshed") for r, _, _ in REGIONS] +
            [(f"Console audio upkeep {r}", [f"Re-check {r} audio on consoles after 3.0.0", "Fix banks", "Record", "Archive"], f"{r} console audio ok") for r, _, _ in REGIONS] +
            [(f"Audio handover rehearsal {k}", [f"{'Second person rebuilds a mix snapshot from docs' if k == 1 else 'Fix doc gaps'}", "Record", "Archive", "Review"], f"Audio handover {k}") for k in (1, 2)],
            ["Lost session for an old cue"], "production/qa/y10/audio/")

    # ---------------- WRITING ----------------
    ph.spec("writing", "Y10 writing extras", "P4/P8; zh-Hans consistency; handover", ["dialogue", "npc", "localization", "docs"],
            [(f"NG+ awareness lines {c} ({k})", [f"Write NG+ cycle-aware lines for {c} ({'combat banter' if k == 1 else 'hub dialogue'})", "VOICE_GUIDE", "zh-Hans note", "Commit"], f"{c} NG+ lines {k}") for c in CAST_A for k in (1, 2)] +
            [(f"Tier B NG+ barks {r}", [f"Write NG+ barks for {r} Tier B NPCs", "Avoid repetition", "zh-Hans note", "Commit"], f"{r} NG+ barks") for r, _, _ in REGIONS] +
            [(f"Codex final consistency {r}", [f"Check {r} codex against all expansions and Story+ ext", "Fix contradictions", "zh-Hans", "Commit"], f"{r} codex final") for r, _, _ in REGIONS] +
            [(f"zh-Hans decade consistency {LOC_BATCHES[k][0]}+{LOC_BATCHES[k + 1][0]}", ["Check terminology drift across 10 years of patches", "Fix with glossary", "Spot-check in game", "Commit"], "Consistent") for k in range(0, 20, 2)] +
            [(f"Writing handover pack {k}", [f"{['Index all .dlg and string tables', 'Second person edits a quest from docs', 'Fix doc gaps'][k - 1]}", "Record", "Archive", "Review"], f"Writing handover {k}") for k in (1, 2, 3)],
            ["Glossary term changed mid-decade"], "docs/writing/")

    # ---------------- QA ----------------
    ph.spec("qa", "Y10 QA extras", "Edge cases; security; accessibility; localization", ["tests", "accessibility", "localization"],
            [(f"NG+ exploratory {r} {rn}", [f"Explore NG+ in {r}: remixed events, markets, NPCs", "Odd orders and save/load", "Log", "Report"], f"{r} NG+ charter") for r, rn, _ in REGIONS] +
            [(f"Story+ extension exploratory {fid}", [f"Explore {fn} extension cases", "Odd orders", "Log", "Report"], f"{fid} charter") for fid, fn in ENDING_FAMILIES] +
            [(f"Console cert refresh test {p}", ["Re-run CC01-CC10 on 3.0.x", "Log", "Report", "Archive"], f"{p} refreshed") for p, _ in PLATFORMS] +
            [(f"Security test {x}", [f"Try {x}", "Log findings", "Verify fixes", "Report"], f"{x} tested") for x in ("save tampering", "leaderboard replay forgery", "DLC entitlement bypass", "telemetry payload inspection")] +
            [(f"NG+ soak {k}", [f"{['8 h NG+3 idle with clock', '200 remixed boss retries', '500 NG+ save/load cycles'][k - 1]}", "Record memory", "Log", "Report"], f"NG+ soak {k}") for k in (1, 2, 3)] +
            [(f"Accessibility full regression {SCREENS[k][0]}-{SCREENS[k + 2][0]}", ["All AX settings on these screens", "Evidence", "Log", "Report"], "A11y regression") for k in range(0, 24, 3)] +
            [("Deck re-verification 3.0", ["Deck checklist on 3.0.0", "Log", "Report", "Archive"], "Deck 3.0 ok"),
             ("Deck NG+ performance", ["Profile NG+3 on Deck", "Log", "Report", "Archive"], "Deck NG+ ok"),
             ("NG+ LQA 1", ["LQA NG+ strings in game", "Log", "Report", "Archive"], "NG+ LQA 1"),
             ("NG+ LQA 2", ["Regression after fixes", "Log", "Report", "Archive"], "NG+ LQA 2")] +
            [(f"zh-Hans decade sample {LOC_BATCHES[k][0]}+{LOC_BATCHES[k + 1][0]}", ["Play sample content in zh-Hans", "Check overflow after 10 years of patches", "Log", "Report"], "Sample ok") for k in range(0, 20, 2)],
            ["Security fix breaks old saves (never allowed)"], "production/qa/y10/")


def reorder(ph):
    # 3.0.0 lands ~70% through Y10; retrospective/decision stays in the tail.
    ph.anchor(next(t for t in ph.main["primary"] if t["title"] == "Release 3.0.0"), 0.68)
    for title in ["Long-term support engineering", "Code health for the new systems"]:
        lst = ph.main["primary"]
        t = next(x for x in lst if x["title"] == title)
        lst.remove(t)
        lst.append(t)
