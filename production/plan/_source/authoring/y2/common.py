"""Shared helpers for the Y2 work-breakdown generator (Y2-Q1, Y2-Q2, Y2-PP)."""
import json
import os

OUT_DIR = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "plan_data")

TAGS = set("""code architecture cleanup tests systems combat animation cinematics story dialogue
quests openworld npc economy items ui ux audio music vfx assets art tools performance accessibility
localization save time difficulty fun release marketing legal team docs ai level business""".split())


def D(focus, steps, done):
    assert 3 <= len(steps) <= 6, (focus, len(steps))
    return {"focus": focus, "steps": list(steps), "done": done}


class Phase:
    def __init__(self, phase_id, title, goal, exit_criteria, capacity):
        self.phase_id = phase_id
        self.title = title
        self.goal = goal
        self.exit_criteria = exit_criteria
        self.capacity = capacity
        self.tasks = []

    def T(self, stream, title, why, tags, days, edge_cases, evidence):
        for t in tags:
            assert t in TAGS, (title, t)
        assert days, title
        assert edge_cases, title
        tid = f"{self.phase_id}-T{len(self.tasks) + 1:02d}"
        self.tasks.append({
            "id": tid, "stream": stream, "title": title, "why": why, "tags": list(tags),
            "days": days, "edge_cases": list(edge_cases), "evidence": evidence,
        })
        return tid

    def ordered(self):
        # Primary tasks first, then secondary, keeping authoring order inside each stream.
        order = {"primary": 0, "secondary": 1}
        tasks = sorted(self.tasks, key=lambda t: order[t["stream"]])
        for i, t in enumerate(tasks, 1):
            t["id"] = f"{self.phase_id}-T{i:02d}"
        return tasks

    def write(self):
        data = {
            "phase_id": self.phase_id,
            "phase_title": self.title,
            "goal": self.goal,
            "exit_criteria": self.exit_criteria,
            "tasks": self.ordered(),
        }
        path = os.path.join(OUT_DIR, f"{self.phase_id}.json")
        with open(path, "w", encoding="utf-8") as f:
            json.dump(data, f, indent=1, ensure_ascii=False)
        return path, data


def report(datas, capacities):
    seen = {}
    ids = set()
    ok = True
    for data in datas:
        pid = data["phase_id"]
        counts = {}
        for t in data["tasks"]:
            assert t["id"] not in ids, t["id"]
            ids.add(t["id"])
            counts[t["stream"]] = counts.get(t["stream"], 0) + len(t["days"])
            for d in t["days"]:
                key = json.dumps(d, sort_keys=True)
                if key in seen:
                    print("DUPLICATE DAY", t["id"], seen[key], d["focus"])
                    ok = False
                seen[key] = t["id"]
                if len(d["steps"]) != len(set(d["steps"])):
                    print("REPEATED STEP INSIDE DAY", t["id"], d["focus"])
        for stream, cap in capacities[pid].items():
            n = counts.get(stream, 0)
            pct = 100.0 * n / cap
            flag = "OK" if 97 <= pct <= 103 else "OUT OF RANGE"
            if flag != "OK":
                ok = False
            print(f"{pid:6s} {stream:9s} {n:4d} / {cap:4d} = {pct:6.1f}% {flag}")
    # Focus-level duplicates are also worth flagging (not fatal).
    focuses = {}
    for data in datas:
        for t in data["tasks"]:
            for d in t["days"]:
                focuses.setdefault(d["focus"], []).append(t["id"])
    dup_focus = {k: v for k, v in focuses.items() if len(v) > 1}
    if dup_focus:
        print("Repeated focus strings (not fatal):", len(dup_focus))
        for k, v in list(dup_focus.items())[:20]:
            print("   ", k, v)
    print("ALL OK" if ok else "PROBLEMS FOUND")
    return ok
