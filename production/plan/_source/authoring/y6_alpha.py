"""Y6 whole-game Alpha tasks (Gate 6: content complete, every storyline/timing branch, every quest)."""
from prod_lib import D, REG, W, low

ACTS = [("Act 1", "R1-R2"), ("Act 2", "R3-R5"), ("Act 3", "R6-R7 branches A/B/C"), ("Act 4", "R8")]
BOSSES = (["R1-B01", "R1-B02", "R1-B03", "R2-B01", "R2-B02", "R2-B03"] + [f"R{r}-B0{b}" for r in (3, 4, 5) for b in (1, 2, 3)]
          + [f"R{r}-B0{b}" for r in (6, 7) for b in (1, 2, 3)] + ["R8-B01", "R8-B02", "R8-B03"])


def y6_alpha(ph):
    why = "Gate 6 Alpha (§10): content complete; bot reaches every storyline and timing branch; every quest completable"
    ph.add("primary", "Timing modifiers wired into every ending", "§7 Y6 systems: timing modifiers in every ending; §12.4", ["time", "story", "systems", "tests"], [
        D(f"Timing → composer: {a} pace and flags", [f"List every {a} pace value and named timing flag ({r})", "Map each to composer slides, scenes and NPC fates",
                                                     "Golden-output test per flag"], f"{a} timing wired")
        for a, r in ACTS] + [
        D("Timing → composer: fairness audit", ["Every deadline has a quest-log reason and a signpost (§12.4)", "Nothing story-critical lost silently", "Fix gaps"], "Fairness audit clean"),
        D("Timing → composer: tests", ["`tests/integration/endings/test_timing_modifiers.gd`", "Bot fast/slow/out-of-order into each ending family", "CI"], "Timing ending tests green"),
    ], ["Two timing flags select contradictory slides"], "tests/integration/endings/test_timing_modifiers.gd")
    ph.add("primary", "Alpha-scale bot coverage", "Gate 6 bot coverage; §8 nightly matrix starts here", ["tests", "tools", "performance"], [
        D("Bot at scale: matrix definition", ["Matrix = storyline (27) × difficulty (5) × timing profile (3)", "Pick the nightly sample and the weekly full run", "ADR"], "Matrix defined"),
        D("Bot at scale: sharding", ["Shard runs across processes", "Deterministic seeds per shard", "Merge reports"], "Sharded runs merge"),
        D("Bot at scale: runtime budget", ["Headless fast-forward of travel and dialogue", "Set the nightly runtime target", "Profile"], "Nightly fits budget"),
        D("Bot at scale: quest completion sweep", ["Bot completes every quest in the roster", "List bot-unreachable quests for manual QA", "Report"], "Quest sweep report"),
        D("Bot at scale: failure triage", ["Auto-file failures with seed and save", "Dedupe by stack", "Dashboard"], "Failures auto-filed"),
        D("Bot at scale: coverage report", ["Storyline and timing-branch coverage %", "Publish to production/qa/", "CI artifact"], "Coverage report published"),
    ], ["Bot passes because a debug flag skipped content"], "production/qa/y6/bot_coverage.md")
    ph.add("primary", "Full-world performance pass with Story+ states", "§8 performance target (60 fps min spec) starts at Alpha", ["performance", "openworld"], [
        D(f"World perf: {r} {REG[r][0]}", [f"`/perf-profile` the busiest {r} chunk on market day in a Story+ state", "Streaming hitch < 2 ms", "Fix the top cost"], f"{r} within budget")
        for r in REG] + [
        D("World perf: cross-region travel", ["Fast-travel chains across all 8 regions", "Memory high-water mark", "Fix leaks"], "Travel within budget"),
        D("World perf: report", ["Min-spec table per region", "Open issues for Beta", "Commit"], "Perf report"),
    ], ["Story+ state doubles NPC count in a town"], "production/qa/y6/perf_report.md")
    ph.add("primary", "Save migration chain audit (every release → Alpha)", "Gate 4/6: saves migrate across every patch", ["save", "tests", "release"], [
        D("Save chain: fixture inventory", ["List fixtures for every Y3 release and EA patch", "Fill missing fixtures from tagged builds", "Commit"], "Fixtures complete"),
        D("Save chain: migrate all to Alpha", ["Run every fixture through the full migration chain", "Diff key state after migration", "Fix"], "All migrate"),
        D("Save chain: Story+ and ending blocks", ["Migration for composer and Story+ blocks", "Old saves enter Act 4 correctly", "Test"], "New blocks migrate"),
        D("Save chain: CI gate", ["Make the chain a required check", "Document how to add a fixture per release", "Commit"], "Chain is a required check"),
    ], ["Save from EA-P01 inside a now-moved chunk"], "tests/unit/save/test_migration_chain.gd")
    ph.add("primary", "Full-game string extraction and freeze prep", "§3 EN + Simplified Chinese; §8 localization", ["localization", "tools", "code"], [
        D(f"Strings: {a} extraction", [f"`/localize` extraction over {a} ({r})", "0 hardcoded strings", "Key-naming lint"], f"{a} extracted") for a, r in ACTS] + [
        D("Strings: endings and Story+", ["Extract composer and Story+ strings", "Context comments", "Lint"], "Endings extracted"),
        D("Strings: freeze plan", ["Define the string-freeze date for Beta", "Change process after the freeze", "ADR"], "Freeze plan ADR"),
    ], ["Concatenated strings in the composer"], "production/localization/y6/extraction_report.md")
    ph.add("primary", "Full-game accessibility pass", "§8 accessibility pass begins at Alpha", ["accessibility", "ui", "code"], [
        D("A11y: remap and presets", ["One-handed and accessibility presets", "Hold/toggle for every hold action", "Test"], "Presets shipped"),
        D("A11y: text and colour", ["200% text everywhere", "Colourblind modes on every telegraph", "Fix"], "Text/colour pass"),
        D("A11y: subtitles and captions", ["Every line subtitled", "Sound captions on", "Fix"], "Captions complete"),
        D("A11y: difficulty and assists", ["Lower-difficulty-anytime check", "Latency calibration everywhere", "Fix"], "Assists checked"),
        D("A11y: report", ["Checklist per screen", "Issues for Beta", "Commit"], "A11y report"),
    ], ["Remap conflict in a minigame"], "production/qa/y6/a11y_report.md")
    for a, r in ACTS:
        ph.add("primary", f"Content-complete defect burn-down: {a}", why, ["code", "tests", "cleanup"], [
            D(f"{a} burn-down: triage", [f"`/bug-triage` for {a} ({r})", "Rank by severity × reach", "Assign"], f"{a} triaged"),
            D(f"{a} burn-down: critical fixes", ["Fix critical bugs with regression tests", "Verify on the release build", "Close"], f"{a} criticals closed"),
            D(f"{a} burn-down: high fixes", ["Fix high bugs", "Regression tests", "Close"], f"{a} highs closed"),
            D(f"{a} burn-down: verification", ["Bot over the act", "Manual check of fixed areas", "Report"], f"{a} burn-down verified"),
        ], ["Fix in a shared system breaks another act"], f"production/qa/y6/{low(a)}_burndown.md")
    pairs = [BOSSES[i:i + 2] for i in range(0, len(BOSSES), 2)]
    ph.add("primary", "Hell re-validation of all 24 bosses on final systems", "P6 Hell replay-verified; §8", ["difficulty", "combat", "tests"], [
        D(f"Hell re-baseline {p[0]} and {p[1]}", [f"Re-run the Hell reference replays for {p[0]} and {p[1]} on the Alpha build",
                                                  "Re-record only if frame data changed on purpose (log why)", "One-frame-off must still lose"], f"{p[0]}/{p[1]} re-validated")
        for p in pairs
    ], ["Replay drift from a FeelService change"], "tests/integration/bosses/*_replay.gd")
    ph.add("primary", "Five-profile balance across all acts", "P6 + §12.1 starting values tuned by playtest", ["difficulty", "combat", "economy"], [
        D(f"Profile balance: {d}", [f"Play-sample each act on {d}", "Compare deaths and time with targets", "Adjust profile data only"], f"{d} balanced")
        for d in ["Beginner", "Easy", "Medium", "Hard", "Hell"]
    ], ["A Hell-only loot item becomes essential"], "production/balance/y6_profiles.md")
    ph.add("primary", "Economy sim per storyline", "§12.6 headless sim in CI; §8 per-route sims", ["economy", "tests"], [
        D("Economy per storyline: fixtures", ["One economy fixture per ending family and faction", "365-day sim each", "Report bounds"], "Fixtures run"),
        D("Economy per storyline: Story+ economy", ["Simulate Story+ markets", "Sources and sinks", "Fix"], "Story+ economy stable"),
        D("Economy per storyline: exploit hunt", ["Arbitrage, auction sniping, gambling EV per route", "Fix", "Tests"], "No exploit open"),
        D("Economy per storyline: CI", ["Nightly per-route sim", "Thresholds fail the build", "Commit"], "Per-route sim in CI"),
    ], ["Route event pushes a price past the clamp"], "tests/integration/economy/test_route_sims.gd")
    # ---- secondary
    for r in REG:
        ph.add("secondary", f"Alpha level pass {r} {REG[r][0]} in Story+ states", why, ["level", "openworld", "story"], [
            D(f"{r} Story+ level pass", [f"Walk {r} in each family's Story+ state", "Check placement of Story+ cases and arcs", "Note fixes"], f"{r} Story+ walked"),
            D(f"{r} completeness check", [f"Every {r} POI, event, waystation and quest reachable", "No placeholder art in a live viewport", "Sign off"], f"{r} complete"),
        ], ["Story+ case giver stands in a blocked area"], f"production/reviews/y6/{r.lower()}_alpha.md")
    for a, r in ACTS:
        ph.add("secondary", f"Narrative read-through: {a}", "P3/P10 canon integrity at content complete", ["story", "docs"], [
            D(f"{a} read-through: main story", [f"Play/read the {a} main story ({r}) in order", "Check flags against STORY_BIBLE", "Notes"], f"{a} main read"),
            D(f"{a} read-through: side content", [f"Read {a} side storylines and companion lines", "Check axis feeds", "Notes"], f"{a} side read"),
            D(f"{a} read-through: fixes", ["Agree fixes with the writer", "Update the retcon log", "Close"], f"{a} fixes agreed"),
        ], ["Contradiction between acts"], f"production/reviews/y6/{low(a)}_readthrough.md")
        ph.add("secondary", f"Difficulty tuning review: {a}", "P6", ["difficulty", "fun"], [
            D(f"{a} tuning: Beginner-Medium", [f"Play {a} bosses on Beginner and Medium", "Pattern-literacy check", "Notes"], f"{a} low tiers reviewed"),
            D(f"{a} tuning: Hard-Hell", [f"Play {a} bosses on Hard and Hell", "Fairness notes", "Notes"], f"{a} high tiers reviewed"),
        ], ["Beginner boss beaten by mashing"], f"production/balance/y6_{low(a)}.md")
    ph.add("secondary", "Act 4 finale direction", "§7 Y6 Act 4", ["story", "cinematics", "level"], [
        D("Finale: pacing map", ["Map Act 4 from the Human Patch Lab to the God King", "Checkpoints and rests", "Notes"], "Pacing map"),
        D("Finale: point of no return", ["Signpost before SOVEREIGN", "Story+ reopens the world", "Review"], "Signposted"),
        D("Finale: credits flow", ["Composer → credits → Story+", "Skip rules", "Review"], "Credits flow approved"),
        D("Finale: full playthrough", ["Play Act 4 on Medium", "Notes", "Sign off"], "Finale signed"),
    ], ["Credits unskippable on repeat"], "production/reviews/y6/finale.md")
    ph.add("secondary", "Credits, licences and legal audit prep", "§8 ratings/legal; §13 legal risk", ["legal", "business", "docs"], [
        D("Legal prep: credits", ["Credits list for team and contractors", "Third-party licences", "Draft"], "Credits drafted"),
        D("Legal prep: provenance", ["Asset provenance and AI-disclosure records (check current rules)", "Gaps list", "Owner per gap"], "Provenance gaps listed"),
        D("Legal prep: gambling rating check plan", ["Simulated gambling: check current rating and regional rules before Beta", "Region config review", "Plan"], "Rating plan"),
    ], ["Asset without a licence record"], "production/legal/y6_audit_prep.md")
    ph.add("secondary", "1.0 runway marketing and Beta planning", "§8 launch marketing; team plan", ["marketing", "business", "team"], [
        D("Runway: 1.0 trailer direction", ["Shot list from Alpha", "Spoiler policy for endings", "Brief the team"], "Trailer brief"),
        D("Runway: store page for 1.0", ["Update the page plan (check current Steam rules)", "Screenshot list from live builds", "Draft"], "Store plan"),
        D("Runway: Beta plan", ["Beta scope per §8", "Hiring need (economy/systems designer per §6)", "Budget check with your own figures"], "Beta plan drafted"),
        D("Runway: Gate 7 prep", ["List Gate 7 evidence", "Owners", "Calendar"], "Gate 7 prep"),
    ], ["Trailer spoils an ending"], "production/marketing/y6_runway.md")
    # ---- art
    ph.add("art", "Alpha art completeness", why, ["art", "assets", "cleanup"], [
        D(f"Art completeness: {a}", [f"`/asset-audit` over {a} ({r})", "Replace remaining placeholders", "Live viewport screenshots"], f"{a} art complete")
        for a, r in ACTS] + [D("Art completeness: report", ["Placeholder count 0, or each accepted with a reason", "Evidence index", "Commit"], "Art completeness report")],
        ["Procedural board mistaken for final art"], "production/qa/y6/art_completeness.md")
    ph.add("art", "1.0 runway marketing art", "§8 launch marketing", ["art", "marketing"], [
        D("Runway art: key art", ["Key art concept", "Render", "Review"], "Key art"),
        D("Runway art: screenshots", ["Stage 12 spoiler-safe screenshots", "Live builds only", "Archive"], "Screenshots"),
        D("Runway art: trailer captures", ["Capture per the shot list", "Clean UI", "Hand off"], "Captures"),
    ], ["Screenshot from a build with a debug overlay"], "production/marketing/y6_art/")
    # ---- qa
    for a, r in ACTS:
        ph.add("qa", f"Alpha full regression: {a}", why, ["tests", "release"], [
            D(f"{a} regression: main path", [f"Full {a} main path ({r}) on Medium", "Every boss", "Log"], f"{a} main path logged"),
            D(f"{a} regression: side content", [f"All {a} side storylines and timed quests", "Fast and slow profiles", "Log"], f"{a} side logged"),
            D(f"{a} regression: saves and loc", [f"Load old fixtures into {a}", "zh-Hans spot-check", "Log"], f"{a} saves/loc logged"),
        ], ["Regression only on a migrated save"], f"production/qa/y6/{low(a)}_regression.md")
    ph.add("qa", "Storyline × difficulty × timing sampling", "§8 QA matrix starts at Alpha", ["tests", "story", "time", "difficulty"], [
        D(f"Matrix sample: {f}", [f"Manual run of a {f} storyline on a random difficulty and timing profile", "Compare with the bot result", "Log"], f"{f} sample logged")
        for f in ["Sole Authority", "Bound Authority", "No Authority", "Consent (secret)"]] + [
        D("Matrix sample: report", ["Bot vs manual discrepancies", "File bugs", "Commit"], "Matrix sample report"),
    ], ["Bot and human reach different endings from the same choices"], "production/qa/y6/matrix_sample.md")
    ph.add("qa", "Accessibility and localization QA (full game)", "§8", ["tests", "accessibility", "localization"], [
        D("Full a11y QA: controls", ["Presets, remap, hold/toggle across all minigames", "Log", "File"], "Controls logged"),
        D("Full a11y QA: visuals and captions", ["Colourblind, high contrast, text scale", "Captions", "Log"], "Visuals logged"),
        D("Full loc QA: pseudo-loc sweep", ["Pseudo-loc build full run", "Overflow hunt", "File"], "Pseudo-loc logged"),
        D("Full loc QA: zh-Hans spot checks", ["Spot-check each region", "Font coverage", "File"], "zh-Hans logged"),
    ], ["Caption missing for a God King phase cue"], "production/qa/y6/a11y_loc.md")
    # ---- writing
    ph.add("writing", "Whole-game continuity and codex completion", "P3 canon integrity; §3 ~400k words", ["dialogue", "story", "localization"], [
        D(f"Continuity: {a}", [f"Read {a} ({r}) lines for continuity", "Fix contradictions", "Retcon log"], f"{a} continuity fixed") for a, r in ACTS] + [
        D("Codex completion: missing entries", [f"Write missing codex entries (~{W(ph, 1200)} words)", "Cross-links", "Keys"], "Codex complete"),
        D("Glossary and translator notes final", ["Glossary complete for all regions", "Translator notes for endings", "Commit"], "Glossary final"),
        D("Continuity: report", ["Summarize changes", "Hand to QA", "Commit"], "Continuity report"),
    ], ["Fix changes a flag-bearing line"], "production/reviews/y6/continuity.md")
    # ---- audio
    ph.add("audio", "Alpha audio completeness", why, ["audio", "music"], [
        D(f"Audio completeness: {a}", [f"Find silent events and placeholder sounds in {a} ({r})", "Replace or log", "Mix check"], f"{a} audio complete") for a, r in ACTS] + [
        D("Audio completeness: register reconcile", ["Reconcile the music register with ~45 tracks and the SFX register with ~900", "List gaps", "Commit"], "Registers reconciled"),
        D("Audio completeness: loudness and master mix", ["Global loudness check", "Bus balance", "Sign off"], "Master mix signed"),
    ], ["Placeholder SFX still in a Story+ case"], "production/audio/y6_completeness.md")
