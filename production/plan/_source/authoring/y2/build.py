"""Build Y2-Q1.json, Y2-Q2.json and Y2-PP.json and validate them."""
import importlib
import json
import sys

from common import Phase, report

CAP = {
    "Y2-Q1": {"primary": 79, "secondary": 92},
    "Y2-Q2": {"primary": 78, "secondary": 91},
    "Y2-PP": {"primary": 157, "secondary": 183},
}

PHASES = [
    ("Y2-Q1", "Public demo",
     "A free Act 1 demo (prologue, Oakhaven, Ironhold, market and auction, 2 minigames, both Act 1 deadlines) is public on itch.io, the Steam page is public with a trailer, the Steam demo app is ready for Next Fest build review, and a structured playtest program is producing Gate 2 data.",
     [
         "Demo build 0.1.x public on itch.io; 0 known softlocks; nightly bot green across 5 difficulties x 3 timing profiles",
         "Steam store page public with capsules, screenshots and the trailer; Steam demo app installs from a private branch",
         "Two minigames and the Ironhold auction playable in the demo; 100-in-game-day economy sim on demo content within Gate 1 bounds",
         "Opt-in telemetry and crash reporting live; demo_end events let the completion rate be computed",
         "Playtest cohorts A and B reported with /playtest-report; Discord live; 6 devlogs posted",
         "Next Fest edition, dates and build-review deadlines confirmed from Steam's own pages and recorded",
     ],
     ["q1_primary", "q1_secondary"]),
    ("Y2-Q2", "Market signal",
     "The demo has been iterated twice from telemetry and playtest data, has run in Steam Next Fest, the legal groundwork (license audit, AI disclosure, title trademark search, gambling rating impact) is documented, and Gate 2 has been decided on 2028-03-31 with an ADR.",
     [
         "Demo completion rate measured from opted-in telemetry (Gate 2 target: >= 40%)",
         "Wishlist and follower targets set by the user from comparable indie RPGs before Next Fest, then measured against",
         ">= 70% of surveyed testers state the hook correctly in one sentence (threshold set by the user)",
         "Measured cost per asset compared with roadmap §3 (Gate 2: within +/-30%)",
         "Asset license audit complete: every shipped asset has a provenance entry; Steam AI-content disclosure re-checked against current rules",
         "Title trademark search and simulated-gambling rating memo written, with 'consult a professional' items listed",
         "Gate 2 ADR recorded: pass, or the chosen fallback (rework the hook for a quarter, or a smaller first commercial release)",
     ],
     ["q2_primary", "q2_secondary"]),
    ("Y2-PP", "Pre-production",
     "The world bible, route architecture (bot-verified for all 27 storylines and every timing branch), economy design (365-day sim within inflation bounds), combat and itemization bibles are locked; legacy systems and stale files are gone; every content pipeline has shipped one final-quality asset; the team and funding plan is decided; and Gate 3 is decided on 2028-09-30.",
     [
         "World bible: 8 regions on one map, 3 factions, history, 8-companion roster, SOVEREIGN and the Null Court thesis per act",
         "Route bot reaches all 24 + 3 storylines and every timing branch on stub content before any new content is written (CI report)",
         "365-in-game-day headless economy sim keeps the inflation index within the agreed bounds on every route profile",
         "Combat bible and itemization bible approved (affix tables, crafting trees, sets, limited-edition calendar)",
         "Chapters 1-3 run on the spine with no legacy calls; cutscene_director, cinematic_vfx, TweenAnimator, duplicate feel systems, 3 old item databases and the stale docs/ probes deleted; load_all and route tests green",
         "~97 legacy phase reports collapsed into ADRs plus an archive index",
         "One final-quality asset shipped through each pipeline (character, tileset/chunk, enemy, boss, icon, VFX, UI, music, SFX, dialogue+zh-CN, cinematic)",
         "Roles, hiring steps, funding route, company entity and IP-assignment contracts decided with professional advice; /onboard docs per role",
         "Gate 3 ADR recorded: greenlight, or the smaller-game plan (2-3 regions, ~6 storylines)",
     ],
     ["pp_primary", "pp_secondary"]),
]


def main():
    datas = []
    for pid, title, goal, exits, mods in PHASES:
        p = Phase(pid, title, goal, exits, CAP[pid])
        for m in mods:
            importlib.import_module(m).add(p)
        path, data = p.write()
        json.load(open(path, encoding="utf-8"))
        datas.append(data)
        print("wrote", path)
    ok = report(datas, CAP)
    sys.exit(0 if ok else 1)


if __name__ == "__main__":
    main()
