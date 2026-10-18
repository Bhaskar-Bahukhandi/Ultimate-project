"""Extra Y7 team/primary/secondary families (kept separate for readability); called from late_y7.build()."""
from late_common import *


def add_extra(ph):
    # ---------------- ART ----------------
    for g in [ENEMIES[i:i + 10] for i in range(0, 50, 10)]:
        ph.add("main", "art", f"Enemy type readability polish {g[0]['eid']}-{g[-1]['eid']}", "§3 50 enemy types; P2 readable tells", ["art", "animation", "vfx"],
               [D(f"Enemy {e['eid']} ({e['rid']} {e['rname']}) tell and silhouette polish",
                  [f"Check {e['eid']} silhouette against {e['rid']} day and night backgrounds",
                   f"Check {e['eid']} attack tells at Hell telegraph x0.7",
                   "Fix anticipation frames/tell VFX without changing frame counts",
                   f"Capture `production/qa/evidence/y7/art/{e['eid']}.png`"], f"{e['eid']} readable") for e in g],
               ["Enemy palette clash in colourblind mode"], "production/qa/evidence/y7/art/enemies/")
    for g in [BOSSES[i:i + 6] for i in range(0, 24, 6)]:
        ph.add("main", "art", f"Hell-only phase VFX polish {g[0]['bid']}-{g[-1]['bid']}", "§3 every boss has a Hell-only phase; P9 juice", ["vfx", "art", "difficulty"],
               [D(f"Hell phase VFX: {b['bid']} {b['bname']}", [f"Review {b['bid']} Hell-only phase VFX for clarity at 2-frame parry demands",
                                                              "Remove VFX noise that hides tells", "Check reduced-flash variant",
                                                              f"Capture `production/qa/evidence/y7/art/{b['bid']}_hell.png`"], f"{b['bid']} Hell VFX clear") for b in g],
               ["Screen-filling effect during parry window"], "production/qa/evidence/y7/art/")
    ph.add("main", "art", "Tier A portraits and Tier B sprite consistency", "P4 living NPCs; art bible consistency", ["art", "npc"],
           [D(f"Tier A portrait set: {c}", [f"Check {c}'s portrait expressions against the art bible", "Fix inconsistencies across acts",
                                           "Check zh-Hans dialogue box framing", f"Capture `production/qa/evidence/y7/art/portrait_{c.lower()}.png`"], f"{c} portraits consistent") for c in CAST_A] +
           [D(f"Tier B sprite consistency {r} {rn}", [f"Line up all {r} Tier B NPC sprites", "Fix scale/palette outliers",
                                                      "Check schedule poses (work, rest, festival)", "Capture lineup"], f"{r} Tier B lineup consistent") for r, rn, _ in REGIONS],
           ["NPC appearing in two regions with different palettes"], "production/qa/evidence/y7/art/npc/")
    ph.add("main", "art", "Item icon review (~450 items)", "P7e deep itemization; rarity readability", ["items", "art", "ui"],
           [D(f"Icon review {ib} ({iname})", [f"Review icons for {iname} at 1x in inventory SC09", "Check rarity frames readable in colourblind modes",
                                             "Fix duplicates and unclear silhouettes", f"Log `production/qa/y7/art/icons_{ib}.md`"], f"{ib} icons approved") for ib, iname in ITEM_BATCHES],
           ["Limited-edition variant indistinguishable from base"], "production/qa/y7/art/icons_*.md")
    ph.add("main", "art", "Minigame, gambling and Deck UI art", "P7c + Deck", ["art", "ui", "fun"],
           [D(f"Art polish: {x}", [f"Review {x} art against the art bible", "Fix readability issues", "Check Deck 1280x800 scale", "Capture"], f"{x} art polished")
            for x in [f"{m} {mn}" for m, mn in MINIGAMES] + [f"{g} {gn}" for g, gn in GAMBLING] + [f"Deck UI scale set {k}" for k in range(1, 5)]],
           ["Card faces unreadable on Deck"], "production/qa/evidence/y7/art/ui/")
    ph.add("main", "art", "Monthly social assets", "§8 launch marketing cadence", ["marketing", "art"],
           [D(f"Social asset set Y7 month {m:02d}", [f"Produce the month {m:02d} social set from the marketing beat list", "Use only non-spoiler content",
                                                    "Export EN and zh-Hans text versions", "Get approval"], f"Month {m:02d} set approved") for m in range(1, 13)],
           ["Asset accidentally shows debug overlay"], "production/marketing/assets/social/")

    # ---------------- AUDIO ----------------
    for g in [ENEMIES[i:i + 10] for i in range(0, 50, 10)]:
        ph.add("main", "audio", f"Enemy audio identity pass {g[0]['eid']}-{g[-1]['eid']}", "P9 juice; P6 audio tells", ["audio", "combat"],
               [D(f"Enemy audio: {g[j]['eid']} and {g[j + 1]['eid']}", [f"Check {g[j]['eid']} and {g[j + 1]['eid']} have distinct idle, tell, hit and death sounds",
                                                                     "Check tells audible under music", "Fix variation counts", "Log"], f"{g[j]['eid']}/{g[j + 1]['eid']} audio ok") for j in range(0, 10, 2)],
               ["Two enemies with identical tell sound in one arena"], "production/qa/y7/audio/enemies.md")
    for half, scr in (("SC01-SC12", SCREENS[:12]), ("SC13-SC24", SCREENS[12:])):
        ph.add("main", "audio", f"UI sound pass per screen ({half})", "P9 juice everywhere", ["audio", "ui"],
               [D(f"UI sounds: {sc} {sn}", [f"Check navigate/confirm/cancel/error sounds on {sn}", "Check volume against the UI bus",
                                           "Remove repeated-trigger spam", "Log"], f"{sc} sounds ok") for sc, sn in scr],
               ["Held direction repeating sounds"], "production/qa/y7/audio/ui.md")
    for g in [BOSSES[i:i + 6] for i in range(0, 24, 6)]:
        ph.add("main", "audio", f"Boss music phase transitions {g[0]['bid']}-{g[-1]['bid']}", "P9 adaptive music; Hell-only phases", ["music", "audio"],
               [D(f"Boss music: {b['bid']} {b['bname']}", [f"Check {b['bid']} music phase changes including the Hell-only phase", "Fix transition timing to phase change",
                                                          "Check retry restarts music cleanly", "Log"], f"{b['bid']} music transitions clean") for b in g],
               ["Death during phase-change stinger"], "production/qa/y7/audio/boss_music.md")
    ph.add("main", "audio", "Cinematic audio and seasonal ambience", "§4.7 + P7f seasons", ["audio", "cinematics"],
           [D(f"Cinematic audio {a} pass {k}", [f"{'Sync SFX to frames' if k == 1 else 'Mix music and SFX'} in {a} cutscenes", "Check skip leaves no hanging audio",
                                               "Check pause mutes correctly", "Log"], f"{a} cinematic audio pass {k} done")
            for a in ["Act 1", "Act 2", "Act 3", "Act 4", "Story+"] for k in (1, 2)] +
           [D(f"Seasonal ambience {r} {se}", [f"Play {r} in {se} days and nights", "Check ambience layers change with season", "Check festival layers", "Log"], f"{r} {se} ambience ok")
            for r, _, _ in REGIONS for se in SEASONS],
           ["Season changes while in a cutscene"], "production/qa/y7/audio/")

    # ---------------- WRITING ----------------
    ph.add("main", "writing", "Tier B bark review per region", "P4 living NPCs", ["npc", "dialogue"],
           [D(f"Tier B bark review {r} {rn}", [f"Read all {r} Tier B barks keyed to player state and time", "Fix repetition and tone per VOICE_GUIDE",
                                              "Check barks reference correct calendar events", "Commit"], f"{r} barks clean") for r, rn, _ in REGIONS],
           ["Bark referencing a dead NPC"], "string tables")
    ph.add("main", "writing", "Side quest text pass (150 quests)", "P5", ["quests", "dialogue"],
           [D(f"Side quest text {qb} ({qn})", [f"Read {qn} start to finish in the quest log and dialogue", "Fix unclear objectives and missing reasons",
                                              "Check axis/timing hooks are described consistently", "Commit"], f"{qb} text clean") for qb, qn in SIDE_QUEST_BATCHES],
           ["Quest text that spoils a secret storyline"], "string tables")
    ph.add("main", "writing", "Secret quests and side storylines text pass", "P5 + §12.2", ["quests", "story"],
           [D(f"Secret quest text {sb} ({sn})", [f"Read {sn}", "Check hints are fair but not explicit", "Check secret storyline flags in text", "Commit"], f"{sb} clean") for sb, sn in SECRET_BATCHES] +
           [D(f"Side storyline text {ssl}", [f"Read every quest in {ssl}", "Check it writes into its axis/timing modifier clearly", "Fix continuity", "Commit"], f"{ssl} clean") for ssl in SIDE_STORYLINES],
           ["Side storyline completed out of order"], "string tables")
    ph.add("main", "writing", "Item, UI and market text", "P7b/P7e + UX clarity", ["items", "ui", "economy"],
           [D(f"Item text {ib} ({iname})", [f"Check names and descriptions for {iname}", "Check affix text matches data", "Check lengths for zh-Hans", "Commit"], f"{ib} text clean") for ib, iname in ITEM_BATCHES] +
           [D(f"UI text clarity {SCREENS[k][0]} + {SCREENS[k + 1][0]}", [f"Read every label on {SCREENS[k][1]} and {SCREENS[k + 1][1]}", "Fix jargon and ambiguity", "Check tooltips", "Commit"],
              f"{SCREENS[k][0]}/{SCREENS[k + 1][0]} text clear") for k in range(0, 24, 2)] +
           [D(f"Disclosure text: {x}", [f"Write clear house-edge/limit/fee text for {x}", "Avoid pressure language", "Check with ratings notes", "Commit"], f"{x} disclosure text done")
            for x in ["G1-G3 tables", "AH1-AH4 fees and caps", "limited-edition notices", "market price tooltips"]],
           ["Affix text with two variables"], "string tables")
    ph.add("main", "writing", "Patch note translations", "Live-ops cadence in EN + zh-Hans", ["localization", "release"],
           [D(f"zh-Hans patch notes for EA update U7-{i:02d}", [f"Translate or review U7-{i:02d} notes into zh-Hans", "Check glossary terms", "Check numbers and item names", "Hand to secondary"],
              f"U7-{i:02d} zh-Hans notes ready") for i in range(1, 13)],
           ["Note referencing a renamed item"], "production/community/")

    # ---------------- QA ----------------
    ph.add("main", "qa", "Critical path, hardware and minigame passes", "Gate 7: every storyline completable; edge cases", ["tests", "fun"],
           [D(f"Critical path full run on {d['diff']} (part {k})", [f"Play the critical path {'Acts 1-2' if k == 1 else 'Acts 3-4 + Story+'} on {d['diff']}", "Log blockers and softlocks",
                                                                   f"Check deadlines with leniency {d['lean']}", "Log"], f"{d['diff']} part {k} logged")
            for d in DIFFS for k in (1, 2)] +
           [D(f"Hardware compatibility: {hw}", [f"Install and play 1 hour on {hw}", "Check controllers, resolution, alt-tab", "Check crash logs", "Log"], f"{hw} logged")
            for hw in ["GPU vendor A low tier", "GPU vendor A mid tier", "GPU vendor B low tier", "GPU vendor B mid tier", "integrated GPU laptop",
                       "ultrawide monitor", "144 Hz monitor", "4K TV via HDMI"]] +
           [D(f"Minigame/gambling test {x}", [f"Test {x} rules, rewards and limits", "Test difficulty options", "Test pause/save mid-game", "Log"], f"{x} tested")
            for x in [m for m, _ in MINIGAMES] + [g for g, _ in GAMBLING]],
           ["High refresh rate breaks the fixed tick"], "production/qa/y7/")

    # ---------------- PRIMARY ----------------
    ph.add("main", "primary", "Simulation, transition and stability checks", "P1 + P4 + crash-free", ["npc", "openworld", "performance", "tests"],
           [D(f"NPC sim and combat transition: {r} {rn}", [f"Run 30 in-game days in {r} headless; assert Tier A/B schedules, festivals and market days fire",
                                                          f"Trigger combat transitions in 5 {r} terrain contexts; assert arena matches biome and returns to the same position",
                                                          "Assert transition < 1 s with world state preserved", f"Log `production/qa/y7/sim/{r}.md`"], f"{r} sim and transitions verified") for r, rn, _ in REGIONS] +
           [D("Gambling region config implementation", ["Implement region config that disables G1-G3 per the ratings spec", "Ensure quests and achievements never need gambling", "Test with each region flag", "Document"], "Region config tested"),
            D("Gambling region config edge cases", ["Load a save made in an enabled region in a disabled one", "Keep gambling item rewards obtainable elsewhere", "Hide tables cleanly in UI", "Add tests"], "Edge cases tested"),
            D("Crash reporting hardening", ["Verify the crash handler writes logs on Windows and Deck", "Strip personal paths from logs", "Upload only with consent", "Test with a forced crash"], "Crash reporting verified"),
            D("Soak test 1: 8-hour open-world idle", ["Run `/soak-test` protocol: 8 h idle in R4 with the clock running", "Record memory and node counts hourly", "Flag growth", "File leaks"], "Soak 1 report"),
            D("Soak test 2: 200 combat transitions", ["Bot-loop 200 combat transitions", "Record memory and orphan nodes", "Fix leaks found", "Re-run"], "Soak 2 report"),
            D("Soak test 3: 1000 save/load cycles", ["Automate save/load across regions", "Check file handles and memory", "Check no save corruption", "Log"], "Soak 3 report")],
           ["Arena generation on a seam between two biomes"], "production/qa/y7/sim/ + soak reports")

    # ---------------- SECONDARY ----------------
    ph.add("main", "secondary", "Build archetype balance and NPC reaction review", "P7d stats never change timing; P4 reactions", ["systems", "npc", "fun"],
           [D(f"Balance: {a}", [f"Run `/balance-check` for {a} at Act 1, 2, 3, 4 levels", "Check no archetype trivialises bosses (timing stays skill)", "Check respec cost", "Record"], f"{a} balanced") for a in ARCHETYPES] +
           [D(f"NPC reactions review {r} {rn}", [f"Commit a crime, attend a festival and fail a deadline in {r}", "Check Tier A/B reactions and memory facts", "File missing reactions", "Record"], f"{r} reactions reviewed")
            for r, rn, _ in REGIONS],
           ["Witness NPC asleep during the crime"], "production/qa/y7/balance/archetypes.md")
