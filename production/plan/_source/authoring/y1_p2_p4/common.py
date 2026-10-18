"""Shared helpers for the Y1-P2/P3/P4 work-breakdown generators."""
import json
import os
import sys

OUT_DIR = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "plan_data")

TAGS = set("""code architecture cleanup tests systems combat animation cinematics story dialogue
quests openworld npc economy items ui ux audio music vfx assets art tools performance accessibility
localization save time difficulty fun release marketing legal team docs ai level business""".split())


def d(focus, steps, done):
    assert 3 <= len(steps) <= 6, (focus, len(steps))
    return {"focus": focus, "steps": list(steps), "done": done}


def T(stream, title, why, tags, days, edge_cases, evidence):
    for t in tags:
        assert t in TAGS, (title, t)
    assert stream in ("primary", "secondary"), stream
    assert days, title
    return {"stream": stream, "title": title, "why": why, "tags": list(tags), "days": days,
            "edge_cases": list(edge_cases), "evidence": evidence}


def write_phase(phase_id, title, goal, exit_criteria, tasks, capacity):
    out_tasks = []
    for i, t in enumerate(tasks, 1):
        t2 = {"id": f"{phase_id}-T{i:02d}"}
        t2.update(t)
        out_tasks.append(t2)
    doc = {"phase_id": phase_id, "phase_title": title, "goal": goal,
           "exit_criteria": exit_criteria, "tasks": out_tasks}
    path = os.path.join(OUT_DIR, f"{phase_id}.json")
    with open(path, "w", encoding="utf-8") as f:
        json.dump(doc, f, indent=1, ensure_ascii=False)
    # report
    counts = {}
    for t in out_tasks:
        counts[t["stream"]] = counts.get(t["stream"], 0) + len(t["days"])
    for s, cap in capacity.items():
        n = counts.get(s, 0)
        pct = 100.0 * n / cap
        flag = "OK" if 97.0 <= pct <= 103.0 else "OUT OF RANGE"
        print(f"{phase_id} {s}: {n}/{cap} = {pct:.1f}% {flag}")
    print(f"wrote {path} ({len(out_tasks)} tasks)")
    return path
