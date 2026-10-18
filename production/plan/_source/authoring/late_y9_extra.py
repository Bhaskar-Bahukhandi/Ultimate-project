"""Extra Y9 families."""
from late_common import *

CODE_FOLDERS = ["scripts/core", "scripts/combat", "scripts/dialogue", "scripts/overworld", "scripts/regions", "scripts/ui", "scripts/exploration", "scripts/cutscene"]


def add_extra(ph):
    # ---------------- PRIMARY ----------------
    ph.fam("primary", "Data-driven values audit", "Coding standards: gameplay values data-driven, never hardcoded", ["code", "cleanup", "systems"], CODE_FOLDERS,
           lambda f: f"Hardcoded gameplay values audit: `{f}/`",
           lambda f: [f"Scan `{f}/` for numeric literals used as gameplay values (damage, timings, prices, durations)", "Move each into the owning `.tres`/config with a doc comment",
                      "Keep behaviour identical: tests and Hell replays must stay green", "Record exceptions (true constants) in `docs/tech-debt-register.md`"],
           lambda f: f"`{f}/` gameplay values data-driven", ["Literal that is a frame window (move but do not change value)"], "CI + Hell replays green")
    ph.fam("primary", "Regression coverage per system", "R8: tests forever; /regression-suite", ["tests", "code"], SYSTEMS,
           lambda s: f"Regression coverage: {s}",
           lambda s: [f"Run `/regression-suite` for {s}: map GDD critical paths to tests", f"List fixed `{s}` bugs lacking a regression test", f"Write the missing tests under `tests/unit/{SYS_SLUG[s]}/`", "Record coverage delta"],
           lambda s: f"{s}: every fixed bug has a regression test", ["Bug only reproducible with platform hardware"], "tests/unit/ + coverage report", chunk=5)
    ph.spec("primary", "X1 combat arenas, crafting and telemetry", "P1 arenas from terrain; P7e crafting; telemetry", ["combat", "openworld", "items", "tools"],
            [(f"Arena generator rules for {n} (part {k})", [f"{'Add terrain-context rules (biome, shape, hazards) for ' + n if k == 1 else 'Test 20 contact points across ' + n + ' and check arenas match'}", "Keep transition < 1 s and return to the same position", "Add test", "Record"], f"{n} arenas part {k}")
             for _, n in X1_REG for k in (1, 2)] +
            [(f"Crafting tree extension for {X1_IS[k]}-{X1_IS[k + 1]}", ["Add recipes to the crafting trees", "Check 90% value rule and salvage sink", "Test", "Record"], "Recipes added") for k in range(0, 8, 2)] +
            [("X1 telemetry events", ["Add X1 progress and economy events (opt-in)", "Dashboards", "Privacy check", "Record"], "X1 telemetry live"),
             ("X1 telemetry review", ["Read first-month X1 data", "Find drop-off points", "Hand to secondary", "Record"], "X1 data reviewed")] +
            [(f"Accessibility follow-up Y9-{k}", [f"Implement accessibility request #{k} from console players", "Test with a11y suite", "Evidence", "Record"], f"A11y Y9-{k} shipped") for k in range(1, 5)] +
            [(f"Platform feature requirements {p}", [f"Check current platform-specific feature requirements for {n} (check current)", "Implement any missing ones via PlatformService", "Test", "Record"], f"{p} features done") for p, n in PLATFORMS],
            ["Arena on an X1 seam with base biome"], "production/qa/y9/x1/")

    # ---------------- SECONDARY ----------------
    ph.fam("secondary", "Console-era difficulty review per boss", "P6: fair on every difficulty and platform", ["difficulty", "combat"], BOSSES,
           lambda b: f"Console-era difficulty review {b['bid']} {b['bname']}",
           lambda b: [f"Compare {b['bid']} deaths/attempts on consoles vs PC per difficulty", "Check controller latency calibration usage", "Propose data-only tuning if outside band", f"Record `production/live/difficulty/y9_{b['bid']}.md`"],
           lambda b: f"{b['bid']} reviewed", ["TV latency inflates deaths"], "production/live/difficulty/", chunk=6)
    ph.spec("secondary", "Console-era storyline reach and economy reviews", "P3/P7b live truth", ["story", "economy"],
            [(f"Storyline reach (consoles) {g[0]['sid']}-{g[-1]['sid']}", ["Read console reach data", "Compare with PC", "Check signposting", "Record"], f"{g[0]['sid']}-{g[-1]['sid']} console reach reviewed") for g in [STORYLINES[i:i + 3] for i in range(0, 27, 3)]] +
            [(f"Economy telemetry review Y9 month {m}", [f"Compare live money supply (month {m}) with the sim incl. X1 goods", "Check alerts", "Decide data changes", "Record"], f"Y9 month {m} economy reviewed") for m in range(1, 9)] +
            [(f"As-built X1 docs {k}", [f"Run `/reverse-document` for X1 {['level and quests', 'economy and events', 'bosses and enemies', 'storylines'][k - 1]}", "Update design docs", "Archive", "Record"], f"X1 docs {k}") for k in range(1, 5)],
            ["Console players skew to lower difficulties"], "production/live/")

    # ---------------- ART ----------------
    ph.spec("art", "Base game art refresh, console legibility and Y10 groundwork", "Long-tail quality; Y10 prep", ["art", "ui", "assets"],
            [(f"Art refresh {r} {rn} ({k})", [f"Fix the #{k} most-reported visual issue in {r}", "Baselines protected; fallbacks kept", "Capture", "Close"], f"{r} refresh {k}") for r, rn, _ in REGIONS for k in (1, 2)] +
            [(f"4K TV legibility {SCREENS[k][0]}-{SCREENS[k + 2][0]}", ["Check UI art at TV distance", "Adjust icon/frame weights", "Capture", "Record"], "Legibility fixed") for k in range(0, 24, 3)] +
            [(f"X1 seasonal variant {n} {se}", [f"Produce {se} tile variants for {n}", "Preview validation", "Record", "Archive"], f"{n} {se} done") for _, n in X1_REG for se in SEASONS] +
            [(f"Hell title icon set {k}", ["Produce Hell title/cosmetic icons for leaderboards", "Readability", "Approve", "Archive"], f"Title icons {k}") for k in range(1, 5)] +
            [(f"Art maintainer docs {k}", [f"Document {['PAE pipeline and palettes', 'controlled builder + import steps', 'provenance records', 'asset naming and budgets'][k - 1]}", "Store in `docs/art_pipeline/`", "Review", "Link"], f"Art docs {k}") for k in range(1, 5)] +
            [(f"Story+ extension concepts {fid}", [f"Concept key visuals for Story+ extension family {fn}", "Canon check", "Approve", "Store"], f"{fid} concepts") for fid, fn in ENDING_FAMILIES],
            ["Refresh request on accepted baseline (escalate)"], "production/qa/evidence/y9/art/")

    # ---------------- AUDIO ----------------
    ph.spec("audio", "Y10 groundwork and console audio upkeep", "Y10 prep; console quality", ["audio", "music", "docs"],
            [(f"NG+ remix sketch {b['bid']}", [f"Sketch an NG+ remix direction for {b['bid']}'s theme", "Keep tell cues intact", "Store", "Review"], f"{b['bid']} remix sketch") for b in BOSSES[:8]] +
            [(f"Story+ extension music sketch {fid}", [f"Sketch Story+ extension cue for {fn}", "Review", "Store", "Iterate"], f"{fid} sketch") for fid, fn in ENDING_FAMILIES] +
            [(f"Console audio memory re-check {r}", [f"Re-check audio memory in {r} on consoles after patches", "Fix banks", "Record", "Archive"], f"{r} audio memory ok") for r, _, _ in REGIONS] +
            [(f"X1 seasonal ambience {n} {se}", [f"Add {se} ambience layers for {n}", "Mix", "Integrate", "Record"], f"{n} {se} ambience") for _, n in X1_REG for se in SEASONS] +
            [("X1 audio accessibility", ["Map X1 cues to AX06", "Check mono", "Fix", "Record"], "X1 audio a11y ok"),
             ("X1 caption review", ["Check X1 sound captions timing", "Fix", "Record", "Archive"], "Captions ok"),
             ("Audio maintainer docs update", ["Update `docs/audio/` for X1 banks", "Review", "Link", "Archive"], "Docs updated"),
             ("Audio archive check", ["Archive X1 stems and sessions", "Verify restore", "Record", "Checksum"], "Archive verified")],
            ["Remix masks a tell"], "production/qa/y9/audio/")

    # ---------------- WRITING ----------------
    ph.spec("writing", "Console text, codex and Y10 groundwork", "Long-tail quality; Y10 prep", ["dialogue", "story", "localization"],
            [(f"Console text overflow review {r} {rn}", [f"Check {r} text at TV distance and console fonts", "Fix overflow/terms", "zh-Hans", "Commit"], f"{r} console text ok") for r, rn, _ in REGIONS] +
            [(f"Base codex X1 cross-references {k}", ["Add X1 lore cross-references to base codex", "Canon check", "zh-Hans note", "Commit"], f"Codex xref {k}") for k in range(1, 5)] +
            [(f"NG+ text groundwork {k}", [f"Draft {['NG+ cycle intro text', 'remix codex template', 'NG+ titles list', 'carryover explanation text'][k - 1]}", "Check tone", "Store", "Review"], f"NG+ text {k}") for k in range(1, 5)] +
            [(f"Story+ extension beat sheet {c}", [f"Write the beat sheet for {c} ({fn})", "Use IDs where canon is open", "List questions for the user", "Store"], f"{c} beat sheet") for c, fid, fn in SPX],
            ["Beat sheet contradicts Story+ base arc"], "design/y10/")

    # ---------------- QA ----------------
    ph.spec("qa", "Console X1 cert and extra checks", "Console DLC cert; a11y; regression", ["tests", "release", "accessibility"],
            [(f"{p} X1 DLC cert run {k}", [f"Run DLC-related CC07 cases for X1 on {n} (check current requirements)", "Log", "Video", "Report"], f"{p} X1 run {k}") for p, n in PLATFORMS for k in (1, 2)] +
            [(f"{PLATFORMS[2][0]} accessibility {SCREENS[k][0]}-{SCREENS[k + 5][0]}", ["Test screens on console C", "Text scale and glyphs", "Log", "Evidence"], "C a11y logged") for k in range(0, 24, 6)] +
            [(f"Regression coverage verification {k}", ["Run new regression tests manually where flaky", "Confirm they fail on the old bug", "Log", "Report"], f"Coverage check {k}") for k in range(1, 5)] +
            [("X1 Deck verification", ["Run Deck checklist in X1", "Log", "Report", "Archive"], "X1 Deck ok"),
             ("X1 Deck performance", ["Profile X1 on Deck", "Log", "Report", "Archive"], "X1 Deck perf ok")] +
            [(f"X1 zh-Hans full play {k}", [f"Play {'Human Patch Lab' if k == 1 else ('Forgotten Sectors' if k == 2 else 'X1 storylines endings')} in zh-Hans", "Log", "Screenshots", "Report"], f"X1 zh-Hans {k}") for k in (1, 2, 3)],
            ["DLC purchased mid-session"], "production/qa/y9/")


def reorder(ph):
    A, B, C = [n for _, n in PLATFORMS]
    ph.move_before("primary", f"Console launch: {B}", "Expansion 1: story, market and events")
    ph.move_before("primary", f"Console launch: {C}", "Expansion 1: NPCs, quests, saves, performance")
    ph.move_before("secondary", f"Console launch marketing and community: {B}", "X1 quest integration (1/5)")
    ph.move_before("secondary", f"Console launch marketing and community: {C}", "X1 economy, NPCs and items")
    for k in range(1, 12):
        ph.move_before("qa", f"X1 systems, platforms and live regression ({k}/11)", "X1 content tests (1/9)")
    ph.move_before("qa", f"Console launch QA: {B}", "X1 systems, platforms and live regression (5/11)")
    ph.move_before("qa", f"Console launch QA: {C}", "X1 systems, platforms and live regression (9/11)")
    for k in range(1, 10):
        ph.move_before("qa", f"X1 content tests ({k}/9)", "X1 systems, platforms and live regression (9/11)")
    for title in ["Static typing and warnings pass", "Data-driven values audit", "Regression coverage per system (1/3)", "Regression coverage per system (2/3)", "Regression coverage per system (3/3)"]:
        ph.move_before("primary", title, "Expansion 1 release")
    ph.anchor(next(t for t in ph.main["primary"] if t["title"] == "Expansion 1 release"), 0.78)
    ph.anchor(next(t for t in ph.main["secondary"] if t["title"] == "X1 review, playtests and release"), 0.70)
    ph.move_before("art", f"Console launch art: {B}", "X1 controlled production import and acceptance")
    ph.move_before("art", f"Console launch art: {C}", "X1 items, VFX, cinematics and endings (1/6)")
    for k, n in enumerate([A, B, C]):
        ph.anchor(next(t for t in ph.main["art"] if t["title"] == f"Console launch art: {n}"), [0.09, 0.27, 0.47][k])
