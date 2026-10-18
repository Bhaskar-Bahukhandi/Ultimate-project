"""Aethelgard 10-year day-by-day plan generator.

Turns the work breakdown (one JSON per phase, plus catalogs.json) into one
Markdown file per month: production/plan/<year>/<year>-<month>.md, with one
separate, detailed entry per day from 2026-10-19 (Day 1) to 2036-10-18
(Day 3653), plus production/plan/README.md (how to use it, phases, gates and
the capacity report).

Scheduling rules
- Each stream (primary, secondary; from Y3 also the team streams art, audio,
  writing, qa) works through its phase's tasks in file order, one task-day per
  stream-day.
- primary: every day except Sunday (Sunday is the weekly integration day).
  secondary: every day. Team streams: Monday-Friday only.
- If a phase's stream has more work than days, the rest carries over to the
  start of the next phase (marked "carried over"); if it has fewer, buffer
  tasks (polish, bug bash, tech debt) fill the gap. Both are reported.
- Month-end reviews, quarterly re-plans and gate reviews are an extra ritual
  block that day; they don't stop the work streams.
Deterministic: same inputs, same plan.

Usage: python generate_plan.py <data_dir> <out_dir>
"""
import json, os, sys, re, hashlib
from datetime import date, timedelta

START = date(2026, 10, 19)
NDAYS = 3653
END = START + timedelta(days=NDAYS - 1)

PHASES = [
    ("Y1-P0", "Stabilize", date(2026, 10, 19), date(2026, 11, 30), 1),
    ("Y1-P1", "Spine", date(2026, 12, 1), date(2027, 1, 31), 1),
    ("Y1-P2", "Combat foundation", date(2027, 2, 1), date(2027, 3, 31), 1),
    ("Y1-P3", "Art pipeline + Pillar Slice", date(2027, 4, 1), date(2027, 6, 30), 1),
    ("Y1-P4", "Open-world tech + tools", date(2027, 7, 1), date(2027, 9, 30), 1),
    ("Y2-Q1", "Public demo", date(2027, 10, 1), date(2027, 12, 31), 2),
    ("Y2-Q2", "Market signal", date(2028, 1, 1), date(2028, 3, 31), 2),
    ("Y2-PP", "Pre-production", date(2028, 4, 1), date(2028, 9, 30), 2),
    ("Y3", "Production I: Act 1 (R1-R2)", date(2028, 10, 1), date(2029, 9, 30), 3),
    ("Y4", "Production II: Act 2 (R3-R5) + Early Access", date(2029, 10, 1), date(2030, 9, 30), 4),
    ("Y5", "Production III: Act 3 branches (R6-R7)", date(2030, 10, 1), date(2031, 9, 30), 5),
    ("Y6", "Production IV: R8, Act 4, endings, Story+", date(2031, 10, 1), date(2032, 9, 30), 6),
    ("Y7", "Beta", date(2032, 10, 1), date(2033, 9, 30), 7),
    ("Y8", "1.0 launch, live support, console ports", date(2033, 10, 1), date(2034, 9, 30), 8),
    ("Y9", "Console launches + Expansion 1", date(2034, 10, 1), date(2035, 9, 30), 9),
    ("Y10", "Expansion 2, NG+ cycles, retrospective", date(2035, 10, 1), END, 10),
]

GATES = {
    date(2027, 6, 30): "Gate 1 - Pillar Slice",
    date(2028, 3, 31): "Gate 2 - Market signal",
    date(2028, 9, 30): "Gate 3 - Production greenlight",
    date(2029, 9, 30): "M3 - Act 1 shippable on all 5 difficulties",
    date(2030, 3, 15): "Early Access launch (Acts 1-2)",
    date(2030, 9, 30): "Gate 4 - Early Access health",
    date(2031, 9, 30): "M5 - every Act 3 branch playable end to end",
    date(2032, 9, 30): "Gate 6 - Alpha (content complete)",
    date(2033, 9, 30): "Gate 7 - Release candidate",
    date(2034, 2, 15): "1.0 launch (PC)",
    date(2034, 8, 15): "Launch + 6-month review",
    date(2036, 10, 18): "10-year retrospective",
}

STREAMS = ["primary", "secondary", "art", "audio", "writing", "qa"]
TEAM = ["art", "audio", "writing", "qa"]
TEAM_ROLE = {"art": "Art lead / animator", "audio": "Composer / sound designer",
             "writing": "Writer", "qa": "QA tester"}
TEAM_FROM = date(2028, 10, 1)

WEEKDAY = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"]


def phase_of(d):
    for p in PHASES:
        if p[2] <= d <= p[3]:
            return p
    raise ValueError(d)


def stream_works(stream, d):
    if stream == "primary":
        return d.weekday() != 6
    if stream == "secondary":
        return True
    return d >= TEAM_FROM and d.weekday() < 5


def is_month_end(d):
    return (d + timedelta(days=1)).month != d.month


def is_quarter_start(d):
    return d.day == 1 and d.month in (1, 4, 7, 10)


def next_gate(d):
    for g in sorted(GATES):
        if g >= d:
            return g, GATES[g]
    return None, None


def load(data_dir):
    phases = {}
    for pid, *_ in PHASES:
        path = os.path.join(data_dir, pid + ".json")
        with open(path, encoding="utf-8") as f:
            phases[pid] = json.load(f)
    with open(os.path.join(data_dir, "catalogs.json"), encoding="utf-8") as f:
        cat = json.load(f)
    return phases, cat


def expand_task_days(phase_json):
    """stream -> list of (task, k, n, dayentry)"""
    out = {s: [] for s in STREAMS}
    for t in phase_json.get("tasks", []):
        s = t.get("stream", "primary")
        if s not in out:
            s = "secondary"
        n = len(t.get("days", []))
        for k, d in enumerate(t.get("days", []), 1):
            out[s].append((t, k, n, d))
    return out


def schedule(phases, cat):
    """Returns per-day assignments and a capacity report."""
    days = [START + timedelta(days=i) for i in range(NDAYS)]
    assign = {d: {} for d in days}
    report = []
    carry = {s: [] for s in STREAMS}
    buffers = cat["buffer_tasks"]
    buf_i = 0
    for pid, ptitle, a, b, year in PHASES:
        queues = expand_task_days(phases[pid])
        pdays = [d for d in days if a <= d <= b]
        for s in STREAMS:
            work = [("carried", x) for x in carry[s]] + [("new", x) for x in queues[s]]
            slots = [d for d in pdays if stream_works(s, d)]
            planned = len(queues[s])
            if not slots:
                carry[s] = [x for _, x in work]
                continue
            used = 0
            for d in slots:
                if work:
                    kind, item = work.pop(0)
                    assign[d][s] = {"kind": kind, "item": item}
                    used += 1
                else:
                    bt = buffers[buf_i % len(buffers)]
                    buf_i += 1
                    assign[d][s] = {"kind": "buffer", "item": bt}
            carry[s] = [x for _, x in work]
            report.append({"phase": pid, "stream": s, "slots": len(slots), "planned": planned,
                           "used": used, "buffer": len(slots) - used, "carry_out": len(carry[s])})
    leftover = {s: len(v) for s, v in carry.items() if v}
    return assign, report, leftover


# ── text helpers ────────────────────────────────────────────────────────────

def pick(lst, i, stride=7):
    if not lst:
        return None
    return lst[(i * stride) % len(lst)]


def area_of(entry):
    if not entry:
        return "the current build"
    t, *_ = entry if isinstance(entry, tuple) else (None,)
    return "the current build"


def commit_type(task):
    tags = set(task.get("tags", []))
    title = task.get("title", "").lower()
    if title.startswith("fix") or "bug" in title:
        return "fix"
    if tags & {"cleanup"} and not tags & {"systems", "combat"}:
        return "chore"
    if tags == {"tests"} or title.startswith("test"):
        return "test"
    if tags & {"docs"} and len(tags) <= 2:
        return "docs"
    if tags & {"code", "architecture", "systems", "combat", "tools", "ui", "save", "time",
               "economy", "items", "npc", "openworld", "ai", "performance", "accessibility",
               "localization", "difficulty", "quests"}:
        return "feat"
    return "chore"


def slug(s, n=48):
    s = re.sub(r"[^a-z0-9 \-]+", "", s.lower()).strip()
    return re.sub(r"\s+", " ", s)[:n].strip()


def scope_of(task, pid):
    for t in task.get("tags", []):
        if t not in ("code", "docs", "tests", "cleanup"):
            return t
    return pid.lower()


def fmt_work(label, hours, a, pid):
    """Block for a primary/secondary assignment."""
    lines = []
    if a is None:
        return lines, None
    kind, item = a["kind"], a["item"]
    if kind == "buffer":
        area = "this phase's newest content"
        title = item["title"].replace("{area}", area)
        lines.append(f"### {label} · {hours} · {title} *(spare capacity: buffer task)*")
        for i, s in enumerate(item.get("steps", []), 1):
            lines.append(f"{i}. {s.replace('{area}', area)}")
        lines.append("**Done when:** the pass is logged in today's session log with what changed.")
        return lines, {"title": title, "tags": item.get("tags", []), "edge_cases": [], "evidence": "session log"}
    task, k, n, d = item
    carried = " *(carried over from the previous phase)*" if kind == "carried" else ""
    lines.append(f"### {label} · {hours} · {task['title']} — day {k} of {n}{carried}")
    lines.append(f"*Task {task['id']} · {d.get('focus', '')}*")
    lines.append("")
    if k == 1 and task.get("why"):
        lines.append(f"*Why:* {task['why']}")
    for i, s in enumerate(d.get("steps", []), 1):
        lines.append(f"{i}. {s}")
    lines.append(f"**Done when:** {d.get('done', '')}")
    if k == n:
        lines.append(f"**Task complete when:** {task.get('evidence', 'evidence recorded')}")
    return lines, task


def build_day(i, d, assign, phases, cat):
    pid, ptitle, pa, pb, year = phase_of(d)
    a = assign.get(d, {})
    out = []
    dn = i + 1
    week = i // 7 + 1
    g, gname = next_gate(d)
    special = []
    if d in GATES:
        special.append("gate")
    if is_quarter_start(d):
        special.append("replan")
    if is_month_end(d):
        special.append("monthly")
    sunday = d.weekday() == 6

    out.append(f"## Day {dn:04d} — {WEEKDAY[d.weekday()]} {d.day} {d.strftime('%B %Y')}")
    tag = []
    if sunday:
        tag.append("weekly integration day")
    if "gate" in special:
        tag.append(f"**{GATES[d]}**")
    if "replan" in special:
        tag.append("quarterly re-plan")
    if "monthly" in special:
        tag.append("month-end review")
    head = f"**Year {year} · {pid} {ptitle} · week {week} · day {dn} of {NDAYS}**"
    if g and g != d:
        head += f" · next: {gname} in {(g - d).days} days"
    out.append(head)
    if tag:
        out.append("")
        out.append("*" + " · ".join(tag) + "*")
    out.append("")

    # Start of day
    sod = cat["start_of_day"]
    out.append("### Start of day · 15 min")
    for j in range(3):
        out.append(f"- {sod[(i + j * 3) % len(sod)]}")
    out.append("")

    tasks_today = []
    # Block A
    if sunday:
        integ = cat["integration_days"][(week - 1) % len(cat["integration_days"])]
        out.append(f"### Block A · 4 h · Weekly integration: {integ['focus']}")
        for j, s in enumerate(integ["steps"], 1):
            out.append(f"{j}. {s}")
        out.append(f"**Done when:** {integ.get('done', '')}")
    else:
        lines, t = fmt_work("Block A — primary", "4 h", a.get("primary"), pid)
        out += lines
        if t:
            tasks_today.append(t)
    out.append("")
    lines, t = fmt_work("Block B — secondary", "3 h", a.get("secondary"), pid)
    out += lines
    if t:
        tasks_today.append(t)
    out.append("")

    # Team
    team_lines = []
    for s in TEAM:
        x = a.get(s)
        if not x:
            continue
        if x["kind"] == "buffer":
            team_lines.append(f"- **{TEAM_ROLE[s]}:** {x['item']['title'].replace('{area}', 'their latest deliverables')} (spare capacity)")
            continue
        task, k, n, dd = x["item"]
        steps = "; ".join(dd.get("steps", [])[:3])
        team_lines.append(f"- **{TEAM_ROLE[s]}:** {task['title']} — day {k}/{n} ({dd.get('focus', '')}): {steps}. *Done:* {dd.get('done', '')}")
        tasks_today.append(task)
    if team_lines:
        out.append("### Team today")
        out += team_lines
        out.append("- **You, 17:00:** review each team deliverable above; approve it or write notes in the tracker.")
        out.append("")

    # Ritual block
    if special:
        out.append("### Ritual block · replaces Fun & feel and Craft study today")
        if "gate" in special:
            gr = cat["gate_review"]
            out.append(f"**{GATES[d]}** — run `/gate-check` against ROADMAP §10:")
            for j, s in enumerate(gr["steps"], 1):
                out.append(f"{j}. {s}")
            out.append(f"**Done when:** {gr.get('done', '')}")
        if "replan" in special:
            qr = cat["quarterly_replan"]
            out.append("**Quarterly re-plan** — measure real speed and regenerate the coming months:")
            for j, s in enumerate(qr["steps"], 1):
                out.append(f"{j}. {s}")
            out.append(f"**Done when:** {qr.get('done', '')}")
        if "monthly" in special:
            mr = cat["monthly_review"]
            out.append("**Month-end review** — `/milestone-review`. First tick every item in this file's "
                       "*Month-end results* list (top of the file). Anything unticked goes onto next month's list by name.")
            for j, s in enumerate(mr["steps"], 1):
                out.append(f"{j}. {s}")
            out.append(f"**Done when:** {mr.get('done', '')}")
        out.append("")

    # Quality
    out.append("### Block C — Quality · 1.5 h")
    edges = []
    for t in tasks_today[:2]:
        ec = t.get("edge_cases", []) or []
        if ec:
            edges.append(ec[(i) % len(ec)])
        if len(ec) > 1:
            edges.append(ec[(i + 1) % len(ec)])
    tagpool = []
    for t in tasks_today:
        tagpool += t.get("tags", [])
    ecat = cat["edge_cases"]
    for j, tg in enumerate(dict.fromkeys(tagpool)):
        if tg in ecat and ecat[tg] and len(edges) < 5:
            edges.append(ecat[tg][(i + j * 5) % len(ecat[tg])])
    if not edges:
        allk = sorted(ecat)
        tg = allk[i % len(allk)]
        edges.append(ecat[tg][i % len(ecat[tg])])
    out.append("- **Edge cases to test for today's work:**")
    for e in dict.fromkeys(edges):
        out.append(f"  - {e}")
    ev = [t.get("evidence") for t in tasks_today if t.get("evidence")]
    out.append(f"- **Tests:** turn the edge cases above into checks next to {ev[0] if ev else 'the owning system'}; the full suite stays green.")
    cq = cat["code_quality"][(i * 11) % len(cat["code_quality"])]
    out.append(f"- **Code quality:** {cq['item']} — *check:* {cq['check']} — *fix:* {cq['fix']}")
    out.append("")

    # Fun
    if not special:
        lens = cat["fun_lenses"][(i * 13) % len(cat["fun_lenses"])]
        area = tasks_today[0]["title"] if tasks_today else "the current build"
        out.append(f"### Block D — Fun & feel · 1 h · Lens: {lens['lens']}")
        out.append(f"Play what today's work touched (*{area}*) through this lens and log answers in `production/qa/playtest-{d.isoformat()}.md`:")
        for q in lens["questions"]:
            out.append(f"- {q}")
        out.append("")
        st = cat["study"][(i * 17) % len(cat["study"])]
        out.append(f"### Craft study · 30 min · {st['domain']}: {st['topic']}")
        out.append(f"- Exercise: {st['exercise']}")
        if st.get("resource"):
            out.append(f"- Resource: {st['resource']}")
        out.append("")

    # Hygiene: skip a chore that repeats today's own task (e.g. Day 1's junk clean-up).
    titles = " ".join(t.get("title", "").lower() for t in tasks_today)
    for s in ("primary", "secondary"):
        x = a.get(s)
        if x and x["kind"] != "buffer":
            dd = x["item"][3]
            titles += " " + dd.get("focus", "") + " " + " ".join(dd.get("steps", []))
    words = lambda s: {w for w in re.findall(r"[a-z]{5,}", s.lower())}
    for off in range(len(cat["hygiene"])):
        hy = cat["hygiene"][(i * 19 + off) % len(cat["hygiene"])]
        if len(words(hy["chore"]) & words(titles)) < 2:
            break
    out.append(f"### Hygiene · 15 min · {hy['chore']}")
    out.append(f"- How: {hy['how']}")
    out.append(f"- Done: {hy['done']}")
    out.append("")

    # End of day
    eod = cat["end_of_day"]
    out.append("### End of day · 15 min")
    for j in range(3):
        out.append(f"- {eod[(i + j * 2) % len(eod)]}")
    commits = []
    for t in tasks_today[:2]:
        if t.get("id"):
            commits.append(f"`{commit_type(t)}({scope_of(t, pid)}): {slug(t['title'])}` (body: `Task: {t['id']}`)")
    if commits:
        out.append("- Suggested commit(s), **only with your OK**: " + "; ".join(commits))
    out.append(f"- Session brief for Claude: *Day {dn} ({d.isoformat()}): read `production/plan/{d.year}/{d.strftime('%Y-%m')}.md` → Day {dn:04d}; work Blocks A–C with me; ask before writing files or committing.*")
    out.append("")
    return "\n".join(out)


STREAM_LABEL = {"primary": "Primary (you + Claude)", "secondary": "Secondary (you + Claude)",
                "art": "Team: art", "audio": "Team: audio", "writing": "Team: writing", "qa": "Team: QA"}


def month_end_results(lst, assign):
    """The same section in every month file, however detailed its days are:
    every task that finishes this month (its last day falls in the month), with
    the evidence that proves it, plus any gate or milestone. The month-end
    review ticks this list; anything unticked is carried over explicitly."""
    last = lst[-1][1]
    out = [f"## Month-end results — due by {WEEKDAY[last.weekday()]} {last.day} {last.strftime('%B %Y')}", "",
           "Everything below must exist and be proven by the last day of the month. The month-end review "
           "ticks each item; anything unticked moves to next month's list by name.", ""]
    gates = [(d, GATES[d]) for _, d in lst if d in GATES]
    if gates:
        out.append("**Gates and milestones**")
        for d, g in gates:
            out.append(f"- [ ] {g} ({d.isoformat()})")
        out.append("")
    total = 0
    for s in STREAMS:
        items = []
        for _, d in lst:
            x = assign.get(d, {}).get(s)
            if not x or x["kind"] == "buffer":
                continue
            task, k, n, _day = x["item"]
            if k == n:
                items.append(f"- [ ] **{task['id']}** {task['title']} — *evidence:* {task.get('evidence', 'recorded in the session log')}")
        if items:
            out.append(f"**{STREAM_LABEL[s]}** ({len(items)})")
            out += items
            out.append("")
            total += len(items)
    if total == 0 and not gates:
        out += ["- [ ] No task finishes this month; the review checks progress on the tasks in flight.", ""]
    return out


def month_files(assign, phases, cat, out_dir):
    days = [START + timedelta(days=i) for i in range(NDAYS)]
    by_month = {}
    for i, d in enumerate(days):
        by_month.setdefault((d.year, d.month), []).append((i, d))
    hashes = {}
    dups = 0
    written = []
    for (y, m), lst in sorted(by_month.items()):
        first, last = lst[0][1], lst[-1][1]
        pids = sorted({phase_of(d)[0] for _, d in lst}, key=lambda p: [x[0] for x in PHASES].index(p))
        body = [f"# {first.strftime('%B %Y')} · Days {lst[0][0] + 1:04d}–{lst[-1][0] + 1:04d}",
                "",
                f"Phase(s): {', '.join(p + ' ' + next(x[1] for x in PHASES if x[0] == p) for p in pids)}. "
                "Generated from `production/plan/_source/`; see `production/plan/README.md` for how to use this plan "
                "and how it is re-planned each quarter.", ""]
        for pid in pids:
            pj = phases[pid]
            body.append(f"**{pid} goal:** {pj.get('goal', '')}")
            ex = pj.get("exit_criteria", [])
            if ex:
                body.append("")
                body.append(f"**{pid} exit criteria:** " + "; ".join(ex))
            body.append("")
        body += month_end_results(lst, assign)
        body.append("---")
        body.append("")
        for i, d in lst:
            txt = build_day(i, d, assign, phases, cat)
            body.append(txt)
            body.append("---")
            body.append("")
        path = os.path.join(out_dir, str(y), f"{y}-{m:02d}.md")
        os.makedirs(os.path.dirname(path), exist_ok=True)
        with open(path, "w", encoding="utf-8", newline="\n") as f:
            f.write("\n".join(body))
        written.append(path)
    return written, dups


def readme(report, leftover, phases, out_dir, nfiles):
    L = ["# Aethelgard — the 10-year day-by-day plan", "",
         f"**{NDAYS} days, one entry per day:** Day 1 is {START.isoformat()} and Day {NDAYS} is {END.isoformat()}. "
         "There is one file per month: `production/plan/<year>/<year>-<month>.md`.", "",
         "It turns `AethelgardPrototype/ROADMAP_10_YEAR.md` into daily work. The roadmap stays the source of truth "
         "for phases, gates, the content budget and the cut order. **If they disagree, the roadmap wins** and this "
         "plan is regenerated.", "",
         "## How to use it", "",
         "1. **Each morning,** open the month file and find `Day NNNN`.",
         "2. **Start a Claude Code session** with the day's *session brief* line, found at the end of the day.",
         "3. **Work the blocks in order:**",
         "   - Start;",
         "   - A (primary, 4 h);",
         "   - B (secondary, 3 h);",
         "   - team review (from Year 3);",
         "   - C (quality, 1.5 h);",
         "   - D (fun & feel, 1 h);",
         "   - craft study (30 min);",
         "   - hygiene (15 min);",
         "   - end.",
         "",
         "   That's about 10 focused hours.",
         "4. **Nothing is written or committed without your OK** (project rules in `CLAUDE.md`). Each day suggests "
         "Conventional Commit messages that reference the task ID.",
         "5. **If a day's task finishes early,** start the next day's entry for that stream. If it runs late, it "
         "carries forward. The quarterly re-plan absorbs the difference.",
         "6. **Every month file opens with the same *Month-end results* checklist.** It lists every task that "
         "finishes that month and the evidence that proves it, plus any gate. It's the same contract whether the "
         "month's days were written by hand (Years 1–2) or from templates (Years 3–10). The month-end review "
         "ticks it.", "",
         "## The week, and the energy rule", "",
         "You chose **7 full working days a week.** The roadmap's risk register rates burnout from long weeks as "
         "high-likelihood and fatal, so every day starts with a 1–5 energy check.",
         "",
         "**If it is ≤ 2 for three days running:** drop Blocks D and craft study, halve Block A, and raise it at the "
         "next month-end review. Protecting the project includes protecting the person making it.", "",
         "**Day types:**",
         "- **Sunday** is the weekly integration day. Block A is replaced by: build the `.exe`, run every suite, "
         "play a route end to end, triage, and fix the top bugs. The secondary stream continues.",
         "- **Month-end, quarterly re-plan and gate days** add a ritual block. It replaces Fun & feel and Craft "
         "study that day; the work streams keep moving.", "",
         "## Detail and honesty", "",
         "- **Every day has its own specific tasks,** steps, done-criteria and edge cases.",
         "- **The firmness of that detail differs:**",
         "  - **Year 1** is grounded in the repo's real current state;",
         "  - **Year 2** is from the roadmap;",
         "  - **Years 3–10** come from the content budget, using IDs (for example `R4-SQ-03`, `R6-B02`) rather "
         "than invented story.",
         "- **The far future will change.** Real speed, playtests and gates will move it, so the plan is "
         "regenerated from `_source/` at every **quarterly re-plan** and every **gate**. "
         "Days already lived are never rewritten.", "",
         "## Phases and gates", "",
         "| Phase | Window | Theme | Goal |", "|---|---|---|---|"]
    for pid, t, a, b, y in PHASES:
        L.append(f"| {pid} | {a.isoformat()} → {b.isoformat()} | {t} | {phases[pid].get('goal', '')} |")
    L += ["", "| Date | Gate / milestone |", "|---|---|"]
    for g in sorted(GATES):
        L.append(f"| {g.isoformat()} | {GATES[g]} |")
    L += ["", "## Decisions and risks this plan raises", "",
          "Building the plan exposed these. Each one has a decision or check day in the plan, but they are "
          "listed here so they aren't buried.", "",
          "**Decided on 2026-10-18:**",
          "1. **Region map (resolved).** It follows `story/STORY_BIBLE.md` §3:",
          "   - Act 1: R1 Oakhaven Reach, R2 Ironhold Crown.",
          "   - Act 2: R3 Fractured Wastes, R4 Forgotten Sectors (the Null Court), R5 Mirror City.",
          "   - Act 3: R6 Cathedral Server, R7 Memory Ocean / Saved Assembly.",
          "   - Act 4: R8 Rootward Expanse (Human Patch Lab, Root of Heaven).",
          "",
          "   Expansion 1's two kingdoms are *cut kingdom A / B*, chosen from the blueprint's cut kingdoms at "
          "the Y8 expansion planning day.",
          "2. **Side quests (resolved and increased).** They go from 128 scheduled (ROADMAP §7's yearly "
          "figures summed to 120) to the full **150** budget in §3:",
          "   - Y3: 40 (R1 19, R2 21).",
          "   - Y4: 50 (R3 17, R4 17, R5 16).",
          "   - Y5: 45 (R6 22, R7 23).",
          "   - Y6: 15 (R8).",
          "",
          "   Every one is a real scheduled quest with design, writing, implementation and QA days. The extra "
          "work replaced filler days, not calendar time.",
          "5. **Early Access scope (resolved).** EA launches ~2030-03-15 with Act 1 + R3. R4 (`EA-U1`) and R5 "
          "(`EA-U2`) follow as EA content updates before Gate 4 (2030-09-30), so all of Acts 1–2 are in "
          "players' hands for the health review. ROADMAP_10_YEAR.md says the same.",
          "6. **Y4 art load (accepted).** Y4 is the tightest year (three regions plus EA), with art as the "
          "bottleneck. Accepted as planned on 2026-10-18.", "",
          "**Still open:**",
          "3. **Secret endings:** the bible defers First Wake and Crownless to after 1.0, while §7 asks for all "
          "27 endings in Y6. A decision step is planned.",
          "4. **Kaito:** the Chapter 3 source uses him, but the bible keeps him on the backlog. A decision is "
          "planned in Y1-P1.", "",
          "7. **Art pace:** 40 Kaelen clips in 18 days (Y1-P3) is aggressive. Cost per asset is logged from Y1-P2, "
          "so Gate 1 shows the real rate. The Ch1 guardian fight has no sprite budgeted through Y1-P4.",
          "8. **Hell leaderboards** conflict with the offline-only assumption (A5), so they are planned as an "
          "optional ADR using platform leaderboards only.", "",
          "**Things to check before relying on them:**",
          "9. Steam Next Fest 2028 dates (not announced when this was written).",
          "10. Steam AI-content rules, rating-board rules for simulated gambling, console certification rules. "
          "The steps say \"check current rules\"; nothing is assumed.", "",
          "**Limits of the plan itself:**",
          "11. **Streams are scheduled independently.** Tasks that depend on another stream's output were "
          "ordered to line up, but the scheduler can't enforce it. Check at each re-plan.",
          "12. **Detail varies:**",
          "    - Years 1–2 were written task by task.",
          "    - Years 3–10 were expanded from per-unit templates, so those days are shorter. In the late "
          "years, 13–35% of the team streams are live-fix and polish blocks.",
          "    - IDs used in Y7–Y10 (bosses, storylines, quests) must be matched to the Y3–Y6 registries at "
          "the first re-plan.",
          "13. **Protected areas:** many tasks touch areas `AGENTS.md` protects (combat, collision, save schema, "
          "story progression). Each has an explicit approval step; a slow decision slips the schedule.",
          "14. **Capacity trims:** to fit the calendar exactly, a few phases had two days of one task merged into "
          "one fuller day, and four late live-fix blocks lost a day. `_source/fix_capacity.py` lists each one.",
          "", "## Capacity report", "",
          "**Columns:**",
          "- **Stream-days available:** how many days the stream works in that phase.",
          "- **Planned:** the work authored for the phase.",
          "- **Buffer:** spare days, filled with polish, bug bashes and tech debt.",
          "- **Carry-out:** work that didn't fit and moves to the next phase. A carry-out is a scheduling risk to "
          "resolve at the next re-plan.", "",
          "| Phase | Stream | Stream-days | Planned | Buffer | Carry-out |", "|---|---|---|---|---|---|"]
    for r in report:
        if r["slots"] == 0 and r["planned"] == 0:
            continue
        L.append(f"| {r['phase']} | {r['stream']} | {r['slots']} | {r['planned']} | {r['buffer']} | {r['carry_out']} |")
    if leftover:
        L += ["", f"**Work left unscheduled after Day {NDAYS}:** " +
              ", ".join(f"{s}: {n} days" for s, n in leftover.items()) +
              ". It belongs to the next re-plan."]
    L += ["", "## Regenerating", "",
          "`_source/` holds:",
          "- the work breakdown, one JSON per phase;",
          "- `catalogs.json`;",
          "- `generate_plan.py`.",
          "",
          "To re-plan:",
          "1. Edit the JSON for the phases ahead.",
          "2. Run `python production/plan/_source/fix_capacity.py production/plan/_source` to fit each "
          "phase to its calendar.",
          "3. Run `python production/plan/_source/generate_plan.py production/plan/_source production/plan`.",
          "4. Review the diff of future months only.",
          "5. Commit with your OK.", "",
          "`_source/authoring/` keeps the scripts that expanded the templates (Years 1–10 and the catalogs), "
          "for reference. They were run from a scratch layout, so point their output paths at `_source/` "
          "before running them again.", "",
          f"*Generated files: {nfiles} month files plus this README.*"]
    with open(os.path.join(out_dir, "README.md"), "w", encoding="utf-8", newline="\n") as f:
        f.write("\n".join(L) + "\n")


def duplicate_work(phases):
    """Day entries (focus + steps) that appear more than once anywhere in the
    work breakdown. Each day's work must be its own."""
    seen, dups = {}, []
    for pid, pj in phases.items():
        for t in pj.get("tasks", []):
            for k, d in enumerate(t.get("days", []), 1):
                key = (d.get("focus", "").strip().lower(), tuple(s.strip().lower() for s in d.get("steps", [])))
                if key in seen:
                    dups.append(f"{t['id']} day {k} = {seen[key]}")
                else:
                    seen[key] = f"{t['id']} day {k}"
    return dups


def main():
    data_dir, out_dir = sys.argv[1], sys.argv[2]
    phases, cat = load(data_dir)
    dup_list = duplicate_work(phases)
    assign, report, leftover = schedule(phases, cat)
    files, _ = month_files(assign, phases, cat, out_dir)
    dups = len(dup_list)
    for x in dup_list[:10]:
        print("  duplicate day entry:", x)
    # Coverage: scheduled task-days per tag (the areas the user named).
    tagdays = {}
    for d, streams in assign.items():
        for s, x in streams.items():
            if x["kind"] == "buffer":
                continue
            for tg in x["item"][0].get("tags", []):
                tagdays[tg] = tagdays.get(tg, 0) + 1
    print("  task-days per tag:", dict(sorted(tagdays.items(), key=lambda kv: -kv[1])))
    os.makedirs(os.path.join(out_dir, "_source"), exist_ok=True)
    with open(os.path.join(out_dir, "_source", "_coverage.json"), "w", encoding="utf-8") as f:
        json.dump({"task_days_per_tag": tagdays, "duplicate_day_entries": dup_list}, f, indent=1)
    readme(report, leftover, phases, out_dir, len(files))
    print(f"wrote {len(files)} month files; duplicate day bodies: {dups}")
    for r in report:
        if r["carry_out"] or r["buffer"] > max(5, r["slots"] * 0.05):
            print("  capacity:", r)
    if leftover:
        print("  unscheduled after end:", leftover)


if __name__ == "__main__":
    main()
