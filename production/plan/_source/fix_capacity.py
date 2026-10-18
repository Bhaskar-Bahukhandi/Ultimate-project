"""Make every phase's stream fit its calendar exactly, so nothing cascades.

Overbooked streams (found by generate_plan.py's capacity report) are trimmed:
- Years 1-2: the last tasks are gate and exit days, which must stay. Instead,
  the longest ordinary task in the stream has its last two days merged into
  one denser day (all steps kept, up to 6; the later day's done-when).
- Live-ops filler ("... fixes block", "... repro block", "... extras"): the
  last day of the last such task is dropped.
Run once before generate_plan.py; it reports what it changed.
"""
import json, os, sys
from datetime import date, timedelta

sys.path.insert(0, os.path.dirname(__file__))
from generate_plan import PHASES, stream_works, STREAMS  # noqa: E402

KEEP = ("gate", "exit", "decision", "review", "devlog", "launch", "retrospective")
FILLER = ("fixes block", "repro block", "regression extras")


def slots(pid, s):
    for p in PHASES:
        if p[0] == pid:
            a, b = p[2], p[3]
            n = (b - a).days + 1
            return sum(1 for i in range(n) if stream_works(s, a + timedelta(days=i)))
    raise KeyError(pid)


def main(data_dir):
    changes = []
    for pid, *_ in PHASES:
        path = os.path.join(data_dir, pid + ".json")
        with open(path, encoding="utf-8") as f:
            pj = json.load(f)
        dirty = False
        for s in STREAMS:
            tasks = [t for t in pj["tasks"] if t.get("stream") == s]
            if not tasks:
                continue
            over = sum(len(t["days"]) for t in tasks) - slots(pid, s)
            while over > 0:
                filler = [t for t in tasks if any(k in t["title"].lower() for k in FILLER) and t["days"]]
                if filler:
                    t = filler[-1]
                    if len(t["days"]) > 1:
                        t["days"].pop()
                    else:
                        pj["tasks"].remove(t)
                        tasks.remove(t)
                    changes.append(f"{pid}/{s}: dropped one day of filler task {t['id']}")
                else:
                    # One merge per task, so no task gets squeezed (a second
                    # merge on the same task would drop steps past the 6 cap).
                    cands = [t for t in tasks if len(t["days"]) >= 3 and not t.get("_merged")
                             and not any(k in t["title"].lower() for k in KEEP)]
                    t = max(cands, key=lambda x: len(x["days"]))
                    a, b = t["days"][-2], t["days"].pop()
                    a["focus"] = f"{a['focus']} + {b['focus']}"
                    a["steps"] = a["steps"] + b["steps"]   # a fuller day; nothing dropped
                    a["done"] = b["done"]
                    t["_merged"] = True
                    changes.append(f"{pid}/{s}: merged the last two days of {t['id']} ({t['title']})")
                over -= 1
                dirty = True
        if dirty:
            for t in pj["tasks"]:
                t.pop("_merged", None)
            with open(path, "w", encoding="utf-8") as f:
                json.dump(pj, f, ensure_ascii=False, indent=1)
    for c in changes:
        print(c)
    print(f"{len(changes)} change(s)")


if __name__ == "__main__":
    main(sys.argv[1])
