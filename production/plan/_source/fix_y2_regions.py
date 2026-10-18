"""Year 2 pre-production: the region map is settled (2026-10-18, STORY_BIBLE §3),
so the world-bible days describe the locked map instead of reconciling it."""
import json, os, sys

MAP = ("R1 Oakhaven Reach, R2 Ironhold Crown, R3 Fractured Wastes, R4 Forgotten Sectors, "
       "R5 Mirror City, R6 Cathedral Server, R7 Memory Ocean / Saved Assembly, "
       "R8 Rootward Expanse (Human Patch Lab, Root of Heaven)")

REGION_DAYS = {  # task day index (1-based) -> (focus, first step) for Y2-PP-T38
    2: ("World bible region R1 Oakhaven Reach",
        "Write R1 Oakhaven Reach: Act 1; function 'belonging, ordinary stakes'; pressure 'the Fracture is encroaching' (STORY_BIBLE §3)"),
    5: ("World bible region R4 Forgotten Sectors",
        "Write R4 Forgotten Sectors: Act 2; function 'the deleted, the Null Court'; pressure 'who counts when the record says \"removed\"' (STORY_BIBLE §3)"),
    6: ("World bible region R5 Mirror City",
        "Write R5 Mirror City: Act 2; function 'self-confrontation'; pressure 'intentions versus consequences' (STORY_BIBLE §3)"),
    7: ("World bible region R6 Cathedral Server",
        "Write R6 Cathedral Server: Act 3; function 'administrative gods'; pressure 'good intentions without consent' (STORY_BIBLE §3)"),
    8: ("World bible region R7 Memory Ocean / Saved Assembly",
        "Write R7 Memory Ocean / Saved Assembly: Act 3; function 'factions, the revolt'; pressure 'what society survives' (STORY_BIBLE §3)"),
    9: ("World bible region R8 Rootward Expanse",
        "Write R8 Rootward Expanse (Human Patch Lab, Root of Heaven): Act 4; function 'origin and authorization'; pressure 'power without a legitimate owner' (STORY_BIBLE §3)"),
}


def main(data_dir):
    path = os.path.join(data_dir, "Y2-PP.json")
    pj = json.load(open(path, encoding="utf-8"))
    tasks = {t["id"]: t for t in pj["tasks"]}
    n = 0

    d = tasks["Y2-PP-T18"]["days"][1]
    d["steps"] = [s.replace("R6 Memory Ocean and R7 Saved Assembly", "R6 Cathedral Server and R7 Memory Ocean / Saved Assembly") for s in d["steps"]]
    n += 1

    t38 = tasks["Y2-PP-T38"]["days"]
    d = t38[0]
    d["focus"] = "World bible: confirm the region map locked on 2026-10-18"
    keep = [s for s in d["steps"] if "Compare the brief" not in s and "two expansion candidates" not in s]
    d["steps"] = [f"Confirm the 8-region map decided on 2026-10-18 from STORY_BIBLE §3: {MAP}",
                  "List the blueprint's cut kingdoms that remain expansion candidates (Expansion 1's cut kingdoms A and B are chosen at the Y8 expansion planning day); keep the rule 'never name the God King before the Human Patch Lab'"] + keep
    n += 1
    for k, (focus, first) in REGION_DAYS.items():
        d = t38[k - 1]
        d["focus"] = focus
        d["steps"] = [first] + [s for s in d["steps"][1:] if "Act 2 (brief) / Act 3" not in s]
        n += 1

    d = tasks["Y2-PP-T48"]["days"][20]
    d["steps"] = [("Its source region, the Forgotten Sectors, is launch region R4 (decided 2026-10-18): anchor SS-10 there and confirm which axis it feeds"
                   if s.startswith("Resolve: its source region") else s) for s in d["steps"]]
    n += 1

    json.dump(pj, open(path, "w", encoding="utf-8"), ensure_ascii=False, indent=1)
    print(f"Y2-PP: {n} day entries updated")


if __name__ == "__main__":
    main(sys.argv[1])
