"""Fill pools: system deepening, polish and hardening tasks that absorb remaining stream capacity.

Each pool entry is specific to a year, region, system or screen. Pools of different kinds are
interleaved so the filler spreads across kinds instead of exhausting one kind first.
"""
from itertools import zip_longest

from prod_lib import D, REG, W, gen_pool, low

TOOLS = ["quest editor (timing fields)", "NPC schedule editor", "item and recipe editor", "economy dashboard",
         "storyline coverage viewer", "difficulty tuning panel"]


def _reg(kinds, stream, kind, item, home=None):
    kinds.setdefault(stream, {}).setdefault(kind, []).append((item, home))


def _regh(kinds, home, stream, kind, item):
    _reg(kinds, stream, kind, item, home)


def add_pools(ph, regions, systems, screens):
    y = ph.pid
    k = {}
    # ------------------------------------------------------------------ primary
    for sysname in systems:
        topics = [
            D(f"{y} {sysname}: profiling and hot-path review", [f"Profile {sysname} under the {y} content load", "List the top 3 costs and their callers", "Fix the cheapest high-impact one"], f"{sysname} profile note filed"),
            D(f"{y} {sysname}: code-structure cleanup", [f"Split oversized scripts in {sysname}; one owner per concern (R7)", "Static typing on public APIs; doc comments", "Remove dead code paths"], f"{sysname} cleanup merged"),
            D(f"{y} {sysname}: edge-case hardening", [f"List known {sysname} edge cases from bug history", "Add a regression test per fixed bug", "Fix the two oldest open issues"], f"{sysname} edge cases covered"),
            D(f"{y} {sysname}: team tooling", [f"Add the debug inspector view or editor field the team asked for in {sysname}", "Document it in the tools README", "Demo to the team"], f"{sysname} tool shipped"),
            D(f"{y} {sysname}: data validation", [f"Add boot validation for {sysname} data (missing refs, out-of-range values)", "Fail CI on invalid data", "Fix existing violations"], f"{sysname} data validated in CI"),
        ]
        final = D(f"{y} {sysname}: deepening tests and merge", [f"Run the full suite with the {sysname} changes", "Update the ADR or design doc if behaviour changed", "Merge with a Conventional Commit referencing the task"], f"{sysname} deepening merged green")
        _reg(k, "primary", "sys", gen_pool("primary", f"Deepen and harden {sysname} ({y})", f"§7 {y} systems deepened + code quality (R7/R8)",
                                            ["systems", "code", "cleanup", "tests"], topics, final,
                                            [f"{sysname} change breaks an old save", f"{sysname} change alters a replay"], f"tests for {sysname}; CI log"))
    for reg in regions:
        rname = REG[reg][0]
        topics = [D(f"{y} {reg} bug-fix block {i}", [f"Take the top {reg} bugs from `/bug-triage` (block {i})", "Reproduce, fix the root cause, add a regression test", "Verify on the release build"], f"{reg} block {i} bugs closed") for i in range(1, 7)]
        final = D(f"{y} {reg} bug-fix: regression run", ["Run all tests and the bot", "Close fixed issues with evidence", "Update the known-issues list"], f"{reg} bug-fix pass merged")
        _regh(k, reg, "primary", "bug", gen_pool("primary", f"Fix {reg} {rname} bugs ({y})", "§7 DoD: no open critical/high bugs", ["code", "tests", "cleanup"], topics, final,
                                            ["Fix changes a save-relevant field"], f"production/qa/{ph.pl}/{reg.lower()}_fixes.md"))
        topics = [D(f"{y} {reg} fun pass: {t}", [f"Play {rname} focusing on {t}", "Tune data values (not code constants) for feel", "Record before/after notes"], f"{reg} {t} tuned") for t in
                  ["encounter density", "hitstop and shake", "reward pacing", "traversal flow", "NPC reactivity"]]
        final = D(f"{y} {reg} fun pass: replay check", ["Re-run input-replay tests after tuning", "Run `/balance-check`", "Commit tuning data"], f"{reg} fun tuning committed")
        _regh(k, reg, "primary", "fun", gen_pool("primary", f"Fun-factor tuning pass {reg} ({y})", "P2/P9 juice everywhere; fun factor", ["fun", "combat", "difficulty"], topics, final,
                                            ["Tuning shifts a Hell timing window (forbidden)"], f"production/playtests/{ph.pl}/{reg.lower()}_fun.md"))
    # ------------------------------------------------------------------ secondary
    for reg in regions:
        rname = REG[reg][0]
        topics = [D(f"{y} {reg} level polish {i}", [f"Walk {rname} chunk groups {i*2-1}-{i*2} for dead ends and empty space", "Add one discovery or shortcut where flow sags", "Re-run reachability"], f"{reg} polish {i} done") for i in range(1, 7)]
        final = D(f"{y} {reg} level polish: review", ["Full walk of the region on a fresh save", "Screenshot each changed spot", "Sign off"], f"{reg} level polish signed off")
        _regh(k, reg, "secondary", "lvl", gen_pool("secondary", f"Level polish {reg} {rname} ({y})", "P7a exploration density; §7 DoD", ["level", "openworld", "fun"], topics, final,
                                              ["New shortcut skips a gated story beat"], f"{ph.ev(reg)}"))
        topics = [D(f"{y} {reg} art direction review {i}", [f"Review the latest {rname} {a} deliveries against the art bible", "Write numbered notes", "Approve or return"], f"{reg} {a} reviewed")
                  for i, a in enumerate(["tiles", "props", "NPC sprites", "VFX", "UI", "lighting"], 1)]
        final = D(f"{y} {reg} art direction: sign-off", ["Compare live viewport screenshots with the target board", "Record approval", "Archive notes"], f"{reg} art direction signed")
        _regh(k, reg, "secondary", "artdir", gen_pool("secondary", f"Art direction reviews {reg} ({y})", "§7 DoD real art; AGENTS.md screenshot evidence", ["art", "team"], topics, final,
                                                 ["Approval given from a static board instead of a live viewport screenshot"], f"production/reviews/{ph.pl}/{reg.lower()}_art.md"))
        topics = [D(f"{y} {reg} writing review: {t}", [f"Read the writer's {rname} {t} in context in the build", "Mark voice and canon issues against VOICE_GUIDE.md and STORY_BIBLE.md", "Return numbered notes"], f"{reg} {t} reviewed")
                  for t in ["quest dialogue", "NPC barks", "companion lines", "lore and codex"]]
        final = D(f"{y} {reg} writing review: sign-off", ["Re-read revised scenes", "Approve", "Log word count against the year target"], f"{reg} writing signed off")
        _regh(k, reg, "secondary", "wrev", gen_pool("secondary", f"Writing direction reviews {reg} ({y})", "P3 + VOICE_GUIDE.md; §3 ~400k words", ["story", "dialogue", "team"], topics, final,
                                               ["Approved line breaks a flag condition"], f"production/reviews/{ph.pl}/{reg.lower()}_writing.md"))
        topics = [D(f"{y} {reg} localization coordination: {t}", s, f"{reg} {t} done") for t, s in [
            ("string hand-off", [f"Export the {rname} string tables for Simplified Chinese", "Attach glossary and screenshots for context", "Track the hand-off in the localization log"]),
            ("query round", ["Answer translator queries", "Fix ambiguous source strings", "Update the glossary"]),
        ]]
        final = D(f"{y} {reg} localization coordination: import check", ["Import returned strings", "Pseudo-loc and zh-Hans screenshots", "Log issues"], f"{reg} zh-Hans import checked")
        _regh(k, reg, "secondary", "loc", gen_pool("secondary", f"Localization coordination {reg} ({y})", "§3 EN + Simplified Chinese at 1.0", ["localization", "team"], topics, final,
                                              ["Translator works from a stale string table"], f"production/localization/{ph.pl}/{reg.lower()}.md"))
    for sc in screens:
        topics = [D(f"{y} {sc}: {t}", s, f"{sc} {t} done") for t, s in [
            ("UX spec update", [f"Update the {sc} spec with `/ux-design`", "Gamepad and keyboard flows", "Text-scale 200% layout"]),
            ("accessibility review", [f"Review {sc} with the accessibility checklist", "Colourblind and high-contrast check", "Screen-reader labels where supported"]),
            ("localization layout", [f"Check {sc} with Chinese strings", "Fix overflow", "Font coverage"]),
        ]]
        final = D(f"{y} {sc}: /ux-review", [f"Run `/ux-review` on {sc}", "Screenshot each state", "Sign off"], f"{sc} UX approved")
        _reg(k, "secondary", "ux", gen_pool("secondary", f"UX and accessibility review: {sc} ({y})", "UI/UX + accessibility baseline", ["ux", "ui", "accessibility"], topics, final,
                                             ["Focus lost after closing a nested menu"], f"production/qa/evidence/{ph.pl}/ux/{low(sc)}/"))
    topics = [D(f"{y} tools: {t}", [f"Collect the team's top 3 requests for the {t}", "Implement the smallest useful one with Claude", "Document in the tools README"], f"{t} improved") for t in TOOLS]
    final = D(f"{y} tools: release to the team", ["Demo the tool changes", "Note follow-ups", "Commit"], "Tool changes released")
    _reg(k, "secondary", "tools", gen_pool("secondary", f"Content tools improvements ({y})", "§5 Y1 tools kept healthy for a team", ["tools", "team"], topics, final,
                                            ["Tool writes data the boot validation rejects"], "tools README + CI"))
    topics = [D(f"{y} narrative consistency: {t}", [f"Run `/consistency-check` over {t}", "Fix contradictions with the writer", "Update the STORY_BIBLE retcon log if canon changes"], f"{t} consistent") for t in
              ["quest flags vs STORY_BIBLE", "NPC memory facts", "lore entries", "companion lines", "item text"]]
    final = D(f"{y} narrative consistency: report", ["Summarize findings", "File follow-ups", "Commit"], "Consistency report filed")
    _reg(k, "secondary", "cons", gen_pool("secondary", f"Narrative consistency pass ({y})", "P3/P10 canon integrity", ["story", "docs"], topics, final, ["Retcon not logged"], f"production/reviews/{ph.pl}/consistency.md"))
    topics = [D(f"{y} community: {t}", s, f"{t} published") for t, s in [
        ("devlog 1", ["Draft a devlog on this quarter's production", "Pick 3 screenshots from evidence", "Publish after your review (ask first)"]),
        ("store page refresh", ["Update Steam page screenshots and text (check current Steam rules)", "Check the AI-content disclosure is accurate (check current rules)", "Publish after review"]),
        ("devlog 2", ["Draft a devlog on a system deep-dive", "Short clip from the build", "Publish after review"]),
        ("community feedback digest", ["Read Discord/forum feedback", "Tag actionable items", "File issues"]),
    ]]
    final = D(f"{y} community: metrics note", ["Record the wishlist/follower trend as read from the dashboard (no invented numbers)", "Note which posts worked", "Plan next quarter"], "Metrics note filed")
    _reg(k, "secondary", "comm", gen_pool("secondary", f"Marketing and community cadence ({y})", "Business/marketing continuity toward EA and 1.0", ["marketing", "business"], topics, final,
                                           ["Post reveals an unannounced spoiler"], f"production/marketing/{ph.pl}.md"))
    # ------------------------------------------------------------------ art
    for reg in regions:
        rname = REG[reg][0]
        topics = [D(f"{y} {reg} art polish: {t}", [f"Polish {rname} {t}", "Check against a live viewport screenshot", "Import and log"], f"{reg} {t} polished") for t in
                  ["tile seams and repetition", "prop variety", "decal layer", "night palette", "weather overlays", "NPC idle variety", "UI icons in region shops"]]
        final = D(f"{y} {reg} art polish: /asset-audit", ["Run `/asset-audit` on the region's assets", "Fix naming and size issues", "Screenshot tour"], f"{reg} asset audit clean")
        _regh(k, reg, "art", "polish", gen_pool("art", f"Art polish {reg} {rname} ({y})", "§7 DoD real art; P9", ["art", "assets", "vfx"], topics, final, ["Polished tile breaks autotile rules"], f"{ph.ev(reg)}"))
        topics = [D(f"{y} {reg} VFX polish: {t}", [f"Polish {rname} {t} VFX in the pooled particle set", "Stay inside the particle budget", "Photosensitivity check (no rapid full-screen flashes)"], f"{reg} {t} VFX polished") for t in
                  ["combat impact", "Root Access and Data Vision", "weather and ambient", "discovery and reward"]]
        final = D(f"{y} {reg} VFX polish: review", ["Capture before/after clips", "Director review", "Merge"], f"{reg} VFX approved")
        _regh(k, reg, "art", "vfx", gen_pool("art", f"VFX polish {reg} {rname} ({y})", "P9 juice everywhere", ["vfx", "art"], topics, final, ["VFX hides a telegraph"], f"{ph.ev(reg)}vfx/"))
        topics = [D(f"{y} {reg} placeholder hunt: {t}", [f"Find placeholder or procedural {t} still in {rname} (AGENTS.md truth gate)", "Replace with final art or log as accepted baseline", "Record provenance"], f"{reg} {t} placeholders cleared") for t in
                  ["props", "icons", "interiors"]]
        final = D(f"{y} {reg} placeholder hunt: report", ["List remaining placeholders with owners", "Live viewport screenshots", "Commit report"], f"{reg} placeholder report filed")
        _regh(k, reg, "art", "ph", gen_pool("art", f"Placeholder hunt {reg} ({y})", "§7 DoD real art; AGENTS.md art truth gate", ["art", "assets", "cleanup"], topics, final,
                                       ["Accepted baseline replaced without a reason"], f"production/qa/{ph.pl}/{reg.lower()}_placeholders.md"))
    for sc in screens:
        topics = [D(f"{y} UI art: {sc} {t}", [f"{t.capitalize()} for {sc}", "High-contrast variant", "Import"], f"{sc} {t} in") for t in ["layout art", "icons", "animations"]]
        final = D(f"{y} UI art: {sc} review", ["Screenshot each state", "Director review", "Fix notes"], f"{sc} UI art approved")
        _reg(k, "art", "ui", gen_pool("art", f"UI art pass: {sc} ({y})", "UI/UX polish", ["ui", "art"], topics, final, ["Icon unreadable at 1x"], f"production/qa/evidence/{ph.pl}/ux/{low(sc)}/"))
    # ------------------------------------------------------------------ audio
    for reg in regions:
        rname = REG[reg][0]
        topics = [D(f"{y} {reg} audio: {t}", [f"{t.capitalize()} across {rname}", "Check in game at 3 volumes", "Log changes"], f"{reg} {t} done") for t in
                  ["footstep surfaces", "foley for interactables", "NPC crowd walla", "weather layers", "mix balance music vs ambience", "combat mix check"]]
        final = D(f"{y} {reg} audio: mix sign-off", ["Full region play with headphones and TV", "Fix clipping/masking", "Director sign-off"], f"{reg} mix signed")
        _regh(k, reg, "audio", "polish", gen_pool("audio", f"Audio polish {reg} {rname} ({y})", "P9 juice; §7 DoD real audio", ["audio"], topics, final, ["Ambience masks telegraph SFX"], f"production/reviews/{ph.pl}/{reg.lower()}_audio.md"))
        topics = [D(f"{y} {reg} sound captions: {t}", [f"Add sound-cue captions/indicators for {rname} {t}", "Check direction and priority", "Test with sound off"], f"{reg} {t} captioned") for t in
                  ["enemy cues", "ambient danger cues", "NPC calls and alarms"]]
        final = D(f"{y} {reg} sound captions: review", ["Play the region with audio muted", "Fix missing cues", "Log in the accessibility checklist"], f"{reg} captions approved")
        _regh(k, reg, "audio", "cap", gen_pool("audio", f"Sound captions and visual cues {reg} ({y})", "Accessibility pass for audio cues", ["audio", "accessibility"], topics, final,
                                          ["Caption spam in crowded scenes"], f"production/qa/evidence/{ph.pl}/{reg.lower()}_captions/"))
        topics = [D(f"{y} {reg} music transitions: {t}", [f"Test {rname} music transitions for {t}", "Fix seams at bar lines", "Re-bounce if needed"], f"{reg} {t} transitions clean") for t in
                  ["explore to combat", "day to night", "festival and event overrides"]]
        final = D(f"{y} {reg} music transitions: sign-off", ["Record a transition reel", "Director review", "Commit"], f"{reg} transitions signed")
        _regh(k, reg, "audio", "trans", gen_pool("audio", f"Adaptive music transition QA {reg} ({y})", "P9 adaptive music", ["music", "audio"], topics, final,
                                            ["Transition fires during a cinematic"], f"production/reviews/{ph.pl}/{reg.lower()}_music.md"))
    for reg in regions:
        rname = REG[reg][0]
        topics = [D(f"{y} {reg} event audio: {t}", [f"Design {rname} {t}", "Tie to the NPC sim / WorldClock event", "Implement and test with a time skip"], f"{reg} {t} in") for t in
                  ["festival and market-day sound", "crime alarm and guard calls", "town criers and notices", "weather and season transitions", "dynamic event build-ups"]]
        final = D(f"{y} {reg} event audio: review", ["Fast-forward a 28-day month in the region", "Check repetition and priorities", "Director sign-off"], f"{reg} event audio signed")
        _regh(k, reg, "audio", "events", gen_pool("audio", f"NPC-sim and calendar event audio {reg} ({y})", "P4 living world + P9 juice", ["audio", "npc", "time"], topics, final,
                                             ["Alarm loops forever after a jail release"], f"production/reviews/{ph.pl}/{reg.lower()}_event_audio.md"))
    topics = [D(f"{y} loudness compliance: {t}", [f"Measure {t} against the loudness target", "Fix outliers", "Log"], f"{t} compliant") for t in ["music buses", "SFX buses", "cinematics"]]
    final = D(f"{y} loudness compliance: report", ["Bus map documentation update", "Report", "Commit"], "Loudness report filed")
    _reg(k, "audio", "loud", gen_pool("audio", f"Loudness compliance and bus maintenance ({y})", "P9; release-quality mix", ["audio"], topics, final,
                                       ["Limiter pumping on boss stems"], f"production/audio/{ph.pl}_loudness.md"))
    topics = [D(f"{y} audio archive: {t}", [f"Archive {t} with provenance notes", "Check file naming", "Back up off-site"], f"{t} archived") for t in ["music stems and sessions", "SFX source recordings"]]
    final = D(f"{y} audio archive: register update", ["Update music and SFX registers", "Counts toward 45 / 900", "Commit"], "Registers updated")
    _reg(k, "audio", "arch", gen_pool("audio", f"Audio archive and provenance ({y})", "§13 legal/provenance; key-person risk", ["audio", "legal"], topics, final,
                                       ["Session file references a missing sample"], f"production/audio/{ph.pl}_archive.md"))
    topics = [D(f"{y} UI SFX: {sc}", [f"Design UI SFX for {sc}", "Implement on focus/confirm/cancel", "Level-check"], f"{sc} UI SFX in") for sc in screens]
    final = D(f"{y} UI SFX: consistency check", ["Play every menu", "Check one sound family", "Fix outliers"], "UI SFX consistent")
    _reg(k, "audio", "ui", gen_pool("audio", f"UI sound pass ({y})", "P9 juice in menus", ["audio", "ui"], topics, final, ["Double SFX on gamepad confirm"], "assets/audio/ui/"))
    # ------------------------------------------------------------------ writing
    for reg in regions:
        rname = REG[reg][0]
        topics = [D(f"{y} {reg} text: {t}", [f"Write {t} for {rname} (~{W(ph, 400)} words)", "Read against VOICE_GUIDE.md", "Key strings"], f"{reg} {t} in") for t in
                  ["codex history entries", "shop and sign text", "Tier C reaction variants", "notice-board postings", "festival/market-day lines", "crime and witness lines"]]
        final = D(f"{y} {reg} text: revision", ["Revise all new text", "Translator notes", "Dialogue test"], f"{reg} extra text final")
        _regh(k, reg, "writing", "world", gen_pool("writing", f"World text {reg} {rname} ({y})", "§3 ~400k words; P4 reactive world", ["dialogue", "localization"], topics, final,
                                              ["Notice references a removed quest"], f"dialogue/world/{reg.lower()}/"))
        topics = [D(f"{y} {reg} localization support: {t}", s, f"{reg} {t} done") for t, s in [
            ("glossary", [f"Add {rname} names and coined terms to the glossary", "Translator notes for wordplay", "Flag culturally specific lines"]),
            ("string-length review", ["Find lines likely to overflow in zh-Hans", "Offer shorter variants", "Update keys"]),
            ("context screenshots", ["Attach screenshots to ambiguous strings", "Speaker and tone notes", "Commit"]),
        ]]
        final = D(f"{y} {reg} localization support: query answers", ["Answer translator queries", "Fix source typos found", "Close the query log"], f"{reg} queries closed")
        _regh(k, reg, "writing", "loc", gen_pool("writing", f"Localization support {reg} ({y})", "§3 EN + Simplified Chinese", ["localization", "dialogue"], topics, final,
                                            ["Key renamed after hand-off"], f"production/localization/{ph.pl}/{reg.lower()}_queries.md"))
    # ------------------------------------------------------------------ qa
    for reg in regions:
        rname = REG[reg][0]
        topics = [D(f"{y} {reg} QA: {t}", s, f"{reg} {t} logged") for t, s in [
            ("exploratory session", [f"Two-hour exploratory session in {rname}", "Log every oddity", "File bugs"]),
            ("soak test", [f"Run the `/soak-test` protocol in {rname} for 4 hours", "Watch memory and frame time", "Log"]),
            ("min-spec check", [f"Play {rname} on the min-spec machine", "Record fps in 3 spots", "File perf bugs"]),
            ("gamepad-only pass", [f"Play {rname} gamepad-only", "Check every prompt glyph", "File issues"]),
            ("time-skip abuse", [f"Rest/wait repeatedly around {rname} deadlines", "Check signposts appear first", "File issues"]),
            ("economy probe", [f"Buy/sell loops at every {rname} shop", "Check sell ≤ 40% of buy", "File exploits"]),
        ]]
        final = D(f"{y} {reg} QA: report", ["Summarize findings", "Run `/bug-triage`", "Archive evidence"], f"{reg} QA report filed")
        _regh(k, reg, "qa", "sweep", gen_pool("qa", f"Deep QA sweep {reg} {rname} ({y})", "§7 DoD; §8 coverage habits start early", ["tests", "performance"], topics, final,
                                         ["Bug only on 21:9 displays"], f"production/qa/{ph.pl}/{reg.lower()}_sweep.md"))
        topics = [D(f"{y} {reg} automation: {t}", [f"Convert {rname} manual {t} cases into gdUnit4 tests under tests/integration/", "Keep them deterministic (seeded clock and RNG)", "Run in CI"], f"{reg} {t} automated") for t in
                  ["quest", "NPC schedule", "shop and economy", "traversal"]]
        final = D(f"{y} {reg} automation: flakiness check", ["Run the new tests 20 times", "Fix or quarantine flaky ones with an issue", "Report coverage"], f"{reg} automation stable")
        _regh(k, reg, "qa", "auto", gen_pool("qa", f"Test automation {reg} ({y})", "R8 tests forever; §7 bot coverage", ["tests", "tools"], topics, final,
                                        ["Test depends on execution order"], f"tests/integration/{reg.lower()}/"))
        topics = [D(f"{y} {reg} localization QA: {t}", [f"Check {rname} {t} in the zh-Hans build", "Screenshot issues", "File bugs"], f"{reg} {t} checked") for t in
                  ["dialogue boxes", "UI and menus", "item and codex text"]]
        final = D(f"{y} {reg} localization QA: report", ["Summarize linguistic and layout issues", "Hand to localization", "Archive screenshots"], f"{reg} loc QA report")
        _regh(k, reg, "qa", "loc", gen_pool("qa", f"Localization QA {reg} ({y})", "§3 EN + Simplified Chinese", ["tests", "localization"], topics, final,
                                       ["Missing glyph shows as a box"], f"production/qa/{ph.pl}/{reg.lower()}_loc.md"))
        topics = [D(f"{y} {reg} time QA: {t}", [f"Test {rname} {t} with a seeded clock", "Compare with the quest log and signposts", "File issues"], f"{reg} {t} checked") for t in
                  ["day/night schedule edges", "festival and market days", "season changes"]]
        final = D(f"{y} {reg} time QA: report", ["Summarize timing issues", "Attach seeds and saves", "Commit"], f"{reg} time QA report")
        _regh(k, reg, "qa", "time", gen_pool("qa", f"Time and calendar QA {reg} ({y})", "P7f + §12.4 fairness", ["tests", "time"], topics, final,
                                        ["Midnight rollover during a save"], f"production/qa/{ph.pl}/{reg.lower()}_time.md"))
    topics = [D(f"{y} compatibility: {t}", [f"Test on {t}", "Record results in the matrix", "File issues"], f"{t} checked") for t in
              ["min-spec PC", "Steam Deck", "Xbox-style and PlayStation-style pads", "ultrawide and 4K displays"]]
    final = D(f"{y} compatibility: matrix report", ["Publish the matrix", "Open issues", "Commit"], "Compatibility matrix filed")
    _reg(k, "qa", "compat", gen_pool("qa", f"Compatibility matrix ({y})", "§8 Steam Deck and min spec", ["tests", "performance"], topics, final,
                                      ["Pad glyphs wrong on a third-party controller"], f"production/qa/{ph.pl}/compat.md"))
    topics = [D(f"{y} save fuzz: {t}", [f"Fuzz {t}", "Every failure falls back to the .bak or shows 'Damaged save — Restore'", "File issues"], f"{t} fuzzed") for t in
              ["truncated files", "flipped bytes in each block", "saves from future versions"]]
    final = D(f"{y} save fuzz: automate", ["Add the fuzz cases to tests/unit/save/", "Run in CI", "Report"], "Save fuzz automated")
    _reg(k, "qa", "fuzz", gen_pool("qa", f"Save corruption and fuzz tests ({y})", "R4 silent save rejection stays fixed (C11)", ["tests", "save"], topics, final,
                                    ["Backup overwritten by a corrupt save"], "tests/unit/save/test_fuzz.gd"))
    for sc in screens:
        topics = [D(f"{y} QA {sc}: {t}", [f"Test {sc}: {t}", "Keyboard and gamepad", "Log"], f"{sc} {t} logged") for t in ["navigation and focus", "text scale and loc", "save/load around it"]]
        final = D(f"{y} QA {sc}: automate", [f"Add a UI focus test for {sc}", "Run in CI", "Screenshot evidence"], f"{sc} UI test green")
        _reg(k, "qa", "ui", gen_pool("qa", f"UI test pass: {sc} ({y})", "§11 UI focus tests", ["tests", "ui", "accessibility"], topics, final, ["Focus trap"], f"tests/integration/ui/test_{low(sc)}.gd"))
    # interleave kinds per stream
    for stream, kinds in k.items():
        lists = list(kinds.values())
        for group in zip_longest(*lists):
            for item in group:
                if item is not None:
                    (g, mx), home = item
                    ph.pool(stream, g, mx, home if home in ph.seg_names else None)
