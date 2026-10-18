"""Extra Y8 families."""
from late_common import *

PATCHES_LIVE = ["1.0.4", "1.1.0", "1.2.0", "1.3.0", "1.4.0", "1.5.0"]


def add_extra(ph):
    # ---------------- pre-launch additions and ordering ----------------
    ph.spec("secondary", "Gold content review per region", "Gate 7 follow-up: content quality on the gold build", ["level", "story", "quests"],
            [(f"Gold review {r} {rn}", [f"Play {r} on the gold candidate for 3 hours (main beats, 3 side quests, 1 TQ)", "Check signposts, NPC reactions and market prices against Beta sign-offs",
                                         "File only launch-blocking issues; queue the rest for 1.0.4", f"Record `production/qa/y8/gold_{r}.md`"], f"{r} gold review done") for r, rn, _ in REGIONS] +
            [("Achievement list review", ["Check every achievement is reachable on all 5 difficulties where intended", "Check none needs gambling or a missable without signposting", "Fix data", "Record"], "Achievements reviewed"),
             ("Missable items final review", ["List every missable item/quest/storyline gate", "Confirm each is signposted before it closes (§12.2 rule)", "Fix gaps", "Record"], "Missables all signposted")],
            ["Achievement requiring a cut feature"], "production/qa/y8/gold_*.md")
    ph.move_before("secondary", "Gold content review per region", "Launch war room: community")
    ph.move_before("secondary", "Expansion 1 pre-production (part 1)", "Gold content review per region")
    ph.anchor(next(t for t in ph.main["secondary"] if t["title"] == "Gold content review per region"), 0.33)
    ph.anchor(next(t for t in ph.main["qa"] if t["title"] == "RC and gold verification (3/3)"), 0.21)
    ph.move_before("primary", "Pre-launch verification on the gold candidate", "Day-one build 1.0.0")
    ph.anchor(next(t for t in ph.main["primary"] if t["title"] == "Pre-launch verification on the gold candidate"), 0.31)
    ph.spec("qa", "Gold launch-readiness passes", "Gate 7 follow-up on gold", ["tests", "release", "localization"],
            [(f"Gold critical path on {d['diff']}", [f"Play the critical path on {d['diff']} on the gold build (abridged with debug_test_mode skips between acts)", "Check deadlines with leniency " + d["lean"], "Log any blocker to the war-room intake", "Record"], f"Gold {d['diff']} pass done") for d in DIFFS] +
            [("Store build compliance check", ["Install from the store's private branch", "Check version string, notices screen, credits", "Check uninstall/reinstall keeps saves", "Record"], "Store build compliant"),
             ("Store page vs build check", ["Compare store claims (languages, controller support, Deck) against the build", "Log mismatches", "Hand to secondary", "Record"], "Claims match build")] +
            [(f"Gold check: {x}", [f"Run the {x} on the gold build", "Compare with the Beta sign-off record", "Log differences to the intake", "Record"], f"Gold {x} done")
             for x in ["Deck checklist", "Deck sleep/resume and controller config", "Deck zh-Hans legibility", "manual save-compat sample (EA saves)", "manual save-compat sample (Beta saves)",
                       "manual save-compat sample (cloud conflict)", "accessibility smoke on SC01-SC08", "accessibility smoke on SC09-SC16", "accessibility smoke on SC17-SC24"]] +
            [(f"Launch {x} store-build check", [f"Install the store build on launch {x}", "Smoke: boot, new game, load save, quit", "Check build hash matches release notes", "Report to war room"], f"Launch {x} check done") for x in ["L-3", "L-2 (default branch staged)"]] +
            [(f"Gold ending check {g[0]['sid']}-{g[-1]['sid']}", [f"Load the pre-ending fixture saves for {', '.join(s['sid'] for s in g)} on gold", "Play each ending sequence and enter Story+",
                                                                  "Compare slides with the Beta capture set", "Record"], f"{g[0]['sid']}-{g[-1]['sid']} endings verified on gold")
             for g in [STORYLINES[i:i + 3] for i in range(0, 27, 3)]] +
            [(f"Gold zh-Hans pass {k}", [f"Play {'Acts 1-2' if k == 1 else ('Acts 3-4' if k == 2 else 'Story+ and menus')} in zh-Hans on gold", "Log overflow and untranslated keys", "Screenshot", "Record"], f"zh-Hans gold pass {k}") for k in (1, 2, 3)],
            ["Store branch serves an older build"], "production/qa/y8/gold/")
    ph.move_before("qa", "Gold launch-readiness passes", "War room repro")
    ph.anchor(next(t for t in ph.main["qa"] if t["title"] == "Gold launch-readiness passes"), 0.24)
    # ---------------- PRIMARY ----------------
    pid, pname = PLATFORMS[2]
    ph.spec("primary", f"Console port continuation: {pname}", "§9 Y8 console port production", ["release", "code", "performance"], [
        (f"{pid} suspend/resume", [f"Test suspend in combat, dialogue, save and streaming on {pname}", "Verify ContextStack pause and WorldClock freeze", "Fix", "Record"], f"{pid} suspend safe"),
        (f"{pid} memory reductions", ["Apply art/audio budget reductions from the team streams", "Re-profile R4 and R8", "Fix remaining peaks", "Record"], f"{pid} under budget"),
        (f"{pid} achievements mapping", [f"Map achievements to {pname} (check current requirements)", "Implement via PlatformService", "Test", "Record"], f"{pid} achievements mapped"),
        (f"{pid} localization on device", ["Boot in zh-Hans", "Check fonts and overflow", "Check language detection", "Record"], f"{pid} zh-Hans ok"),
        (f"{pid} accessibility on device", ["Check AX01-AX12", "Check platform accessibility interplay", "Fix", "Record"], f"{pid} a11y ok")] +
        [(f"{pid} pre-cert {cc}: {cn}", [f"Read current {pname} requirements for {cn} (check current platform requirements)", f"Test against {cc}", "Fix or escalate to partner", f"Record `production/console/{pid}/{cc}.md`"], f"{pid} {cc} pass") for cc, cn in CERT_CATS[:5]],
        ["Platform C firmware differs from A/B assumptions"], f"production/console/{pid}/")
    ph.spec("primary", "Post-launch engineering follow-ups", "Live support: performance, accessibility, economy", ["performance", "accessibility", "economy", "code"], [
        ("Telemetry pipeline maintenance 1", ["Check telemetry ingestion after launch load", "Fix dropped events", "Verify opt-in respected", "Record"], "Telemetry healthy"),
        ("Telemetry pipeline maintenance 2", ["Add launch-specific dashboards (completion by act, difficulty mix)", "Validate numbers", "Share", "Record"], "Dashboards added"),
        ("Telemetry pipeline maintenance 3", ["Archive raw data per retention policy", "Delete beyond retention", "Document", "Record"], "Retention applied")] +
        [(f"Low-spec preset step {k}", [f"{['Profile the bottom 10% hardware tier from telemetry', 'Design a low preset (resolution scale, particles, NPC LOD)', 'Implement preset', 'Verify on the 8 GB / older CPU machines', 'Ship and measure'][k - 1]}", "Keep gameplay identical (fixed tick unaffected)", "Record", "Update docs"], f"Low preset step {k} done") for k in range(1, 6)] +
        [(f"Accessibility follow-up {k}", [f"Implement the #{k} accessibility request from launch feedback", "Test with the a11y suite", "Capture evidence", "Record"], f"A11y follow-up {k} shipped") for k in range(1, 5)] +
        [(f"Economy exploit review EX-{k:02d}", [f"Investigate telemetry alert cluster EX-{k:02d}", "Reproduce in the headless sim", "Fix by data change and add an invariant", "Ship within one patch"], f"EX-{k:02d} closed") for k in range(1, 7)] +
        [("Steam Deck re-verification after 1.0", ["Re-run the Deck checklist on 1.0.x", "Fix regressions", "Record", "Update store info if needed"], "Deck still verified"),
         ("Steam Deck re-verification after 1.3.0", ["Re-run the Deck checklist on 1.3.0", "Fix regressions", "Record", "Archive"], "Deck checked on 1.3.0")] +
        [(f"X1 prototype: {x}", [f"Prototype {x} on a branch", "Measure", "Record findings in the X1 ADRs", "Delete prototype branch after notes"], f"{x} prototype measured")
         for x in ["DLC resource-pack loading", "DLC-missing save behaviour", "X1 seam chunk streaming", "entitlement check stub", "X1 flag namespace in FlagRegistry", "X1 market goods in sim", "X1 world events on WorldClock"]],
        ["Low preset breaks a puzzle readability"], "production/live/eng_followups.md")

    # ---------------- SECONDARY ----------------
    ph.spec("secondary", "Live design reviews: storylines, quests and deadlines", "P3/P5/P7f live truth", ["story", "quests", "time"], [
        (f"Storyline reach review {g[0]['sid']}-{g[-1]['sid']}", [f"Read how many players reach {', '.join(s['sid'] for s in g)}", "Check the gating choices are signposted", "Note surprises", "Record"], f"{g[0]['sid']}-{g[-1]['sid']} reviewed")
        for g in [STORYLINES[i:i + 3] for i in range(0, 27, 3)]] +
        [(f"Side quest completion review {r} {rn}", [f"Read completion and abandon rates for {r} side quests", "Find drop-off points", "Propose fixes (text, markers)", "Record"], f"{r} quest review done") for r, rn, _ in REGIONS] +
        [(f"Missed-deadline review {r} {rn}", [f"Read miss rates for {', '.join(t['tq'] for t in TQS if t['rid'] == r)}", "Check signpost visibility for high-miss TQs", "Propose fixes", "Record"], f"{r} deadline review done") for r, rn, _ in REGIONS],
        ["Rates skewed by Story+ completionists"], "production/live/design/")
    ph.spec("secondary", "Live programme reviews", "Live support, team, business", ["team", "business", "accessibility", "localization"], [
        ("Leaderboard and speedrun research", ["Collect community requests for Hell leaderboards/speedrun timer", "Check A5 single-player rule and platform leaderboard options (check current)", "Draft options", "Record for Y9 decision"], "Options drafted"),
        ("Leaderboard decision input", ["Estimate cost and risk (cheating, privacy)", "Recommend optional/defer", "User decides direction", "Record"], "Direction recorded"),
        ("Community fairness survey 1", ["Publish a short fairness survey (bosses, deadlines)", "No personal data", "Collect", "Record"], "Survey 1 collected"),
        ("Community fairness survey 2", ["Analyse results", "Compare with Beta fairness", "Actions", "Record"], "Survey 2 analysed"),
        ("Community fairness survey 3", ["Close actions", "Post summary", "Archive", "Record"], "Survey loop closed"),
        ("Accessibility feedback review 1", ["Collect a11y feedback", "Group by AX system", "Prioritise", "Record"], "A11y feedback grouped"),
        ("Accessibility feedback review 2", ["Write follow-up specs", "Hand to primary", "Track", "Record"], "A11y specs handed"),
        ("Accessibility feedback review 3", ["Verify shipped follow-ups", "Reply to players", "Archive", "Record"], "A11y loop closed"),
        ("zh-Hans player feedback review 1", ["Collect zh-Hans reviews and reports", "Group issues", "Prioritise with writing", "Record"], "zh-Hans feedback grouped"),
        ("zh-Hans player feedback review 2", ["Track fixes", "Reply", "Update glossary", "Record"], "zh-Hans loop closed"),
        ("zh-Hans player feedback review 3", ["Measure review trend", "Plan improvements", "Archive", "Record"], "zh-Hans trend recorded"),
        ("Y9 staffing plan 1", ["List Y9 needs: console launches, X1 production", "Contractor vs hire options", "Budget", "Record"], "Needs listed"),
        ("Y9 staffing plan 2", ["User decides", "Prepare contracts (user)", "Plan onboarding with `/onboard`", "Record"], "Staffing decided"),
        ("Y9 staffing plan 3", ["Schedule onboarding", "Assign mentors", "Update team docs", "Record"], "Onboarding scheduled"),
        ("Y9 staffing plan 4", ["Review key-person risk coverage", "Assign backups per system", "Record", "Share"], "Backups assigned")] +
        [(f"Seasonal calendar events review ({se} {k})", ["Review in-game festivals/market days for this season from telemetry", "Check participation and reward value", "Tune data", "Record"], f"{se} {k} reviewed")
         for se in ("spring", "summer", "autumn", "winter") for k in (1,)],
        ["Survey brigading"], "production/live/")

    # ---------------- ART ----------------
    ph.spec("art", "Expansion 1 art production start", "§9 Y9 Expansion 1 (preview-only until controlled import)", ["art", "animation", "assets"],
            [(f"X1 boss sprites {b} pass {k}", [f"{['Block poses and key frames', 'Animate attack set incl. Hell phase', 'Clean up and export to preview'][k - 1]} for {b}", "Check against frame-data targets", "Preview only (no production import)", "Record"], f"{b} pass {k}") for b, _ in X1_BOSSES for k in (1, 2, 3)] +
            [(f"X1 enemy sprites {e} pass {k}", [f"{'Key poses' if k == 1 else 'Full animation and export'} for {e}", "Check tells", "Preview only", "Record"], f"{e} pass {k}") for e, _ in X1_ENEMIES for k in (1, 2)] +
            [(f"X1 NPC sprites {X1_NB[k]}-{X1_NB[k + 1]}", ["Produce schedule poses", "Check palette", "Preview", "Record"], f"{X1_NB[k]}-{X1_NB[k + 1]} sprites") for k in range(0, 12, 2)] +
            [(f"X1 item icons {s}", [f"Produce icons for {s}", "Check rarity readability", "Preview", "Record"], f"{s} icons") for s in X1_IS] +
            [(f"X1 tileset second pass {cs}", [f"Refine {cs} tiles", "Seam validation", "Preview-only Godot validation", "Record"], f"{cs} second pass") for cs, _, _ in X1_CS],
            ["Boss animation exceeds frame budget"], "assets/art_sources/expansion1/")
    ph.spec("art", "Console marketing and accessibility art", "Console launches; a11y", ["marketing", "accessibility", "art"],
            [(f"{p} key art variant", [f"Adapt key art for {n} (check current specs)", "Approve", "Export", "Archive"], f"{p} key art") for p, n in PLATFORMS] +
            [(f"{p} trailer frames", [f"Adapt trailer cards for {n}", "Approve", "Export", "Archive"], f"{p} trailer frames") for p, n in PLATFORMS] +
            [(f"Colourblind feedback fix {k}", [f"Fix colourblind issue #{k} reported after launch", "Check all modes", "Capture", "Close"], f"CB fix {k}") for k in range(1, 5)],
            ["Platform forbids certain imagery"], "production/marketing/console/")

    # ---------------- AUDIO ----------------
    ph.spec("audio", "Expansion 1 audio production start", "§9 Y9 Expansion 1", ["audio", "music"],
            [(f"X1 SFX batch {sb} day {k}", [f"{['Record/design sources', 'Edit and variations', 'Mix and name', 'Integrate in preview'][k - 1]} for {sb}", "Follow the X1 SFX list", "Log provenance", "Record"], f"{sb} day {k}") for sb in X1_SB for k in range(1, 5)] +
            [(f"X1 music {mt} day {k}", [f"{['Compose A section', 'Compose B section', 'Adaptive layers', 'Mix', 'Master and review'][k - 1]} for {mt}", "Check direction", "Export", "Record"], f"{mt} day {k}") for mt in X1_MT[:3] for k in range(1, 6)] +
            [(f"X1 ambience {cs}", [f"Build ambience bed for {cs}", "Day/night layers", "Preview", "Record"], f"{cs} ambience") for cs, _, _ in X1_CS],
            ["Ambience loop audible"], "assets/audio/expansion1/")
    ph.spec("audio", "Live audio improvements", "P9; console; maintainability", ["audio", "accessibility", "docs"],
            [(f"{p} audio accessibility {k}", [f"{'Check mono and caption sync' if k == 1 else 'Check volume sliders and AX06 cues'} on {n}", "Fix", "Record", "Archive"], f"{p} a11y audio {k}") for p, n in PLATFORMS for k in (1, 2)] +
            [(f"Ending music polish {fid} ({fn})", ["Review ending music for this family", "Polish transitions into Story+", "Mix", "Record"], f"{fid} ending music polished") for fid, fn in ENDING_FAMILIES] +
            [(f"Ending music polish {fid} pass 2", ["Check modular slide timing with music", "Fix cue points", "Mix", "Record"], f"{fid} pass 2 done") for fid, _ in ENDING_FAMILIES] +
            [(f"Minigame/gambling audio on console {x}", [f"Check {x} audio on console builds", "Fix latency for rhythm game if relevant", "Mix", "Record"], f"{x} console audio ok") for x in [m for m, _ in MINIGAMES] + [g for g, _ in GAMBLING]] +
            [(f"Combat audio feel {w}", [f"Review {w} hit audio from feedback", "Add weight/variation", "Mix", "Record"], f"{w} audio feel done") for w in ["weapon class 1", "weapon class 2", "weapon class 3", "weapon class 4", "aerial/pogo", "tools", "Root Access", "parry/dodge"]] +
            [("OST release prep", ["Check music rights for OST release (check current distributor terms)", "Prepare metadata and art request", "User approves", "Record"], "OST ready"),
             ("Audio maintainer docs 1", ["Document bus layout and mix snapshots", "Document adaptive music system", "Store in `docs/audio/`", "Review"], "Audio docs 1"),
             ("Audio maintainer docs 2", ["Document SFX naming and import settings", "Document provenance logging", "Store", "Review"], "Audio docs 2")],
            ["Rhythm game latency on TV"], "production/qa/y8/audio/")

    # ---------------- WRITING ----------------
    ph.spec("writing", "Expansion 1 dialogue first drafts", "§9 Y9 Expansion 1", ["dialogue", "quests"],
            [(f"Dialogue first draft {q} ({rg})", [f"Draft all {q} dialogue in `.dlg` format from its outline", "Check VOICE_GUIDE and canon", "Mark choices and flags", "Store for review"], f"{q} drafted") for q, rg in X1_SQ] +
            [(f"TQ dialogue {q} ({t})", [f"Draft {q} dialogue and signposts", "Check deadline wording", "Store", "zh-Hans note"], f"{q} drafted") for q, t in X1_TQ],
            ["Choice with no flag"], "design/expansion1/dialogue/")
    ph.spec("writing", "Community and maintainer writing", "Community; key-person risk", ["docs", "marketing"],
            [(f"Community Q&A prep {k}", [f"Collect top questions for Q&A {k}", "Draft answers with the team", "zh-Hans", "Publish via secondary"], f"Q&A {k} ready") for k in range(1, 5)] +
            [(f"Writing pipeline docs {k}", [f"{['Document .dlg conventions and tools', 'Document string table + loc batch workflow', 'Document ending composer text rules'][k - 1]}", "Store in `docs/writing/`", "Review", "Link from onboarding"], f"Writing docs {k}") for k in range(1, 4)],
            ["Answer reveals unannounced content"], "docs/writing/")

    # ---------------- QA ----------------
    ph.spec("qa", "Live regression extras", "Live quality", ["tests", "localization", "accessibility", "performance"],
            [(f"{PLATFORMS[2][0]} pre-cert test {cc}", [f"Execute {cc} ({cn}) cases on {PLATFORMS[2][1]}", "Use current requirement list (check current)", "Log", "Record"], f"{PLATFORMS[2][0]} {cc} tested") for cc, cn in CERT_CATS[5:]] +
            [(f"{p} Deck re-check", [f"Re-run Deck checklist for {p}", "Log", "Compare", "Record"], f"{p} Deck ok") for p in PATCHES_LIVE] +
            [(f"{p} accessibility regression", [f"Run the a11y smoke for {p}", "Check SC03/SC04/SC13", "Log", "Record"], f"{p} a11y ok") for p in PATCHES_LIVE] +
            [(f"{p} zh-Hans LQA delta", [f"LQA the string delta for {p}", "Check overflow", "Log", "Record"], f"{p} LQA ok") for p in PATCHES_LIVE + ["1.0.1", "1.0.2", "1.0.3"]] +
            [(f"{p} performance regression", [f"Run the perf routes on {p}", "Compare with gold", "Log", "Record"], f"{p} perf ok") for p in PATCHES_LIVE],
            ["Patch regresses Deck preset"], "production/qa/y8/live/")
