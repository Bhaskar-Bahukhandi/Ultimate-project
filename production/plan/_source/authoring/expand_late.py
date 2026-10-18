"""Expander for Y7-Y10: builds every phase, writes JSON, validates per BRIEF.md.

Usage: python expand_late.py [--show KEYWORD]
"""
import json
import os
import sys
import importlib

from late_common import OUT, STREAMS, TAGS

PHASES = ["late_y7", "late_y8", "late_y9", "late_y10"]


def main():
    show = sys.argv[sys.argv.index("--show") + 1] if "--show" in sys.argv else None
    seen = {}
    ids = set()
    ok = True
    for modname in PHASES:
        try:
            mod = importlib.import_module(modname)
        except ModuleNotFoundError:
            print(f"skip {modname} (not written yet)")
            continue
        ph = mod.build()
        doc, positions = ph.finalize()
        path = os.path.join(OUT, f"{ph.pid}.json")
        json.load(open(path, encoding="utf-8"))  # parse check
        counts = {s: 0 for s in STREAMS}
        for t in doc["tasks"]:
            assert t["id"] not in ids, t["id"]
            ids.add(t["id"])
            assert t["stream"] in STREAMS
            assert all(tag in TAGS for tag in t["tags"]), t["tags"]
            assert t["days"] and t["edge_cases"] and t["evidence"]
            counts[t["stream"]] += len(t["days"])
            for d in t["days"]:
                assert 3 <= len(d["steps"]) <= 6
                key = json.dumps(d, sort_keys=True)
                if key in seen:
                    ok = False
                    print("DUPLICATE day:", t["id"], "==", seen[key], d["focus"])
                seen[key] = t["id"]
        print(f"{ph.pid}: tasks={len(doc['tasks'])}")
        for s in STREAMS:
            cap = ph.caps[s]
            pct = 100.0 * counts[s] / cap
            flag = "" if 97 <= pct <= 103 else "  <-- OUT OF RANGE"
            if flag:
                ok = False
            print(f"   {s:9s} {counts[s]:4d}/{cap:4d} = {pct:5.1f}%{flag}")
        if show:
            for s, lst in positions.items():
                for cum, title in lst:
                    if show.lower() in title.lower():
                        print(f"   [{s}] day {cum + 1:4d}: {title}")
    # also check duplicates of focus text alone (informational)
    print("unique day entries:", len(seen), "| task ids:", len(ids), "| OK" if ok else "| PROBLEMS")
    return 0 if ok else 1


if __name__ == "__main__":
    sys.exit(main())
