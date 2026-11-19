"""Document checker for design/gdd/time-model.md (story Y1-P0-S06b, AC-6).

Run:  python -I -B production/qa/evidence/2026-11-time-model/check_time_model.py [--root ROOT] [--gdd PATH]

This is a document lint. It proves that the text is consistent and that its citations resolve to the files it names;
it does not prove the time model is a good design. It reads only; it writes nothing.

Checks (each failure is one problem line):
  1. the 8 required H2 headings, once each, in order (Summary, Cross-References, Open Questions allowed as extras);
  2. the TS table: TS01-TS40 once each, every type equal to its own `Timing type:` line in the production master,
     counts 15 / 14 / 5 / 6, every pm_line on that quest's `## TSnn` heading;
  3. the quest-field table covers all four timing types;
  4. the outcome flags of the two live deadlines exist in scripts or dialogue (comments stripped);
  5. the pace table: 12 flags matching act{1-4}_pace_(early|on_time|late); `existing` flags found in code,
     `new` flags found in neither scripts nor dialogue; the Open Question 4 decision line is dated;
  6. the bridge and convoy margins (F5, F6) hold at the Tuning Knobs defaults for every leniency percent in that
     table, using scale(x) = (x * L_pct + 50) div 100.
It does not parse the Acceptance Criteria or the Formulas text: their worked numbers are review items and WorldClock v1
unit tests.
"""
from __future__ import annotations

import argparse
import re
import sys
from pathlib import Path

REQUIRED_HEADINGS = [
    ("Overview",),
    ("Player Fantasy",),
    ("Detailed Design", "Detailed Rules"),
    ("Formulas",),
    ("Edge Cases",),
    ("Dependencies",),
    ("Tuning Knobs",),
    ("Acceptance Criteria",),
]
OPTIONAL_HEADINGS = {"Summary", "Cross-References", "Open Questions"}
TYPES = ("Window", "Deadline", "Order", "Duration")
EXPECTED_TYPE_COUNTS = {"Window": 15, "Deadline": 14, "Order": 5, "Duration": 6}
PM_REL = "AethelgardPrototype/story/source/PRODUCTION_MASTER_2.1.md"
CODE_DIRS = ("AethelgardPrototype/scripts", "AethelgardPrototype/dialogue")
TS_HEADER = ["ts", "title", "timing_type", "pm_line"]
FIELD_HEADER = ["field", "type", "allowed", "timing_type"]
PACE_HEADER = ["act", "flag_early", "flag_on_time", "flag_late", "status", "rule", "source"]
PACE_RE = re.compile(r"^act([1-4])_pace_(early|on_time|late)$")


class Problems:
    def __init__(self) -> None:
        self.items: list[str] = []

    def add(self, area: str, text: str) -> None:
        self.items.append(f"[{area}] {text}")


# --- markdown helpers ---------------------------------------------------------------------------------------------

def split_row(line: str) -> list[str]:
    body = line.strip()
    if body.startswith("|"):
        body = body[1:]
    if body.endswith("|") and not body.endswith("\\|"):
        body = body[:-1]
    cells = re.split(r"(?<!\\)\|", body)
    return [c.strip().replace("\\|", "|") for c in cells]


def tables(lines: list[str]) -> list[dict]:
    """Every pipe table outside code fences: {'line': header line no., 'header': [...], 'rows': [(line no., [...])]}."""
    found, in_fence, i = [], False, 0
    while i < len(lines):
        line = lines[i]
        if line.lstrip().startswith("```"):
            in_fence = not in_fence
        if (not in_fence and line.lstrip().startswith("|") and i + 1 < len(lines)
                and re.match(r"^\s*\|[\s:|-]+\|\s*$", lines[i + 1])):
            header, rows, j = split_row(line), [], i + 2
            while j < len(lines) and lines[j].lstrip().startswith("|"):
                rows.append((j + 1, split_row(lines[j])))
                j += 1
            found.append({"line": i + 1, "header": header, "rows": rows})
            i = j
            continue
        i += 1
    return found


def table_with_header(all_tables: list[dict], header: list[str]) -> list[dict]:
    return [t for t in all_tables if t["header"] == header]


# --- 1. headings --------------------------------------------------------------------------------------------------

def check_headings(lines: list[str], probs: Problems) -> None:
    headings, in_fence = [], False
    for no, line in enumerate(lines, 1):
        if line.lstrip().startswith("```"):
            in_fence = not in_fence
        elif not in_fence and line.startswith("## "):
            headings.append((no, line[3:].strip()))
    required = []
    for no, text in headings:
        if any(text in names for names in REQUIRED_HEADINGS):
            required.append(text)
        elif text not in OPTIONAL_HEADINGS:
            probs.add("headings", f"line {no}: unexpected H2 heading '{text}'")
    for names in REQUIRED_HEADINGS:
        count = sum(text in names for text in required)
        if count == 0:
            probs.add("headings", f"missing heading '## {names[0]}'")
        elif count > 1:
            probs.add("headings", f"heading '## {names[0]}' appears {count} times")
    order = [next(i for i, names in enumerate(REQUIRED_HEADINGS) if text in names) for text in required]
    if order != sorted(order):
        probs.add("headings", "required headings out of order: " + ", ".join(required))


# --- 2. the TS table ----------------------------------------------------------------------------------------------

def read_pm(root: Path, probs: Problems) -> tuple[list[str], dict[str, dict]]:
    path = root / PM_REL
    if not path.is_file():
        probs.add("ts", f"production master not found at {PM_REL}")
        return [], {}
    pm_lines = path.read_text(encoding="utf-8").split("\n")
    quests: dict[str, dict] = {}
    current = None
    for no, line in enumerate(pm_lines, 1):
        m = re.match(r"^## (TS\d\d) — (.+)$", line)
        if m:
            current = m.group(1)
            quests[current] = {"title": m.group(2).strip(), "line": no, "type": None}
        elif line.startswith("# "):
            current = None
        elif current and line.startswith("Timing type:") and quests[current]["type"] is None:
            quests[current]["type"] = line.split(":", 1)[1].strip().rstrip(".")
    return pm_lines, quests


def check_ts_table(all_tables: list[dict], root: Path, probs: Problems) -> None:
    pm_lines, quests = read_pm(root, probs)
    found = table_with_header(all_tables, TS_HEADER)
    if len(found) != 1:
        probs.add("ts", f"expected exactly one table with header {' | '.join(TS_HEADER)}, found {len(found)}")
        return
    rows = found[0]["rows"]
    seen: dict[str, int] = {}
    counts = {t: 0 for t in TYPES}
    for no, cells in rows:
        if len(cells) != 4:
            probs.add("ts", f"line {no}: {len(cells)} cells, expected 4")
            continue
        ts, title, ttype, pm_line = cells
        if not re.fullmatch(r"TS\d\d", ts):
            probs.add("ts", f"line {no}: '{ts}' is not a TSnn id")
            continue
        seen[ts] = seen.get(ts, 0) + 1
        if ttype not in TYPES:
            probs.add("ts", f"line {no}: {ts} has type '{ttype}', not one of {', '.join(TYPES)}")
        else:
            counts[ttype] += 1
        src = quests.get(ts)
        if src is None:
            probs.add("ts", f"line {no}: {ts} is not a quest in the production master")
            continue
        if src["type"] != ttype:
            probs.add("ts", f"line {no}: {ts} is '{ttype}' but PM:{src['line']} says 'Timing type: {src['type']}'")
        if src["title"] != title:
            probs.add("ts", f"line {no}: {ts} title '{title}' differs from the PM heading '{src['title']}'")
        if not pm_line.isdigit():
            probs.add("ts", f"line {no}: pm_line '{pm_line}' is not a number")
        else:
            n = int(pm_line)
            ok = 1 <= n <= len(pm_lines) and re.match(rf"^## {ts} — ", pm_lines[n - 1]) is not None
            if not ok:
                probs.add("ts", f"line {no}: pm_line {n} is not the '## {ts}' heading (it is PM:{src['line']})")
    expected_ids = [f"TS{n:02d}" for n in range(1, 41)]
    for ts in expected_ids:
        if seen.get(ts, 0) == 0:
            probs.add("ts", f"{ts} is missing from the table")
        elif seen[ts] > 1:
            probs.add("ts", f"{ts} appears {seen[ts]} times")
    extra = sorted(set(seen) - set(expected_ids))
    if extra:
        probs.add("ts", "unexpected ids: " + ", ".join(extra))
    if len(rows) != 40:
        probs.add("ts", f"{len(rows)} rows, expected 40")
    if counts != EXPECTED_TYPE_COUNTS:
        probs.add("ts", f"type counts {counts}, expected {EXPECTED_TYPE_COUNTS}")


# --- 3. the quest-field table -------------------------------------------------------------------------------------

def check_field_table(all_tables: list[dict], probs: Problems) -> None:
    found = table_with_header(all_tables, FIELD_HEADER)
    if len(found) != 1:
        probs.add("fields", f"expected exactly one table with header {' | '.join(FIELD_HEADER)}, found {len(found)}")
        return
    covered: set[str] = set()
    for no, cells in found[0]["rows"]:
        if len(cells) != 4:
            probs.add("fields", f"line {no}: {len(cells)} cells, expected 4")
            continue
        if not all(cells):
            probs.add("fields", f"line {no}: an empty cell")
        for token in (t.strip() for t in cells[3].split(",")):
            if token in TYPES:
                covered.add(token)
            elif token != "all":
                probs.add("fields", f"line {no}: unknown timing_type token '{token}'")
    for t in TYPES:
        if t not in covered:
            probs.add("fields", f"no row of the field table is specific to the {t} type")


# --- 4 + 5. flags in code -----------------------------------------------------------------------------------------

def code_text(root: Path, strip_comments: bool) -> str:
    chunks = []
    for rel in CODE_DIRS:
        base = root / rel
        if not base.is_dir():
            continue
        for p in sorted(base.rglob("*")):
            if p.suffix not in (".gd", ".dlg") or not p.is_file():
                continue
            for line in p.read_text(encoding="utf-8", errors="replace").split("\n"):
                if strip_comments and line.lstrip().startswith("#"):
                    continue
                chunks.append(line)
    return "\n".join(chunks)


def has_word(text: str, word: str) -> bool:
    return re.search(rf"(?<![A-Za-z0-9_]){re.escape(word)}(?![A-Za-z0-9_])", text) is not None


def outcome_flags(lines: list[str]) -> list[tuple[int, str]]:
    """Backticked ch<N>_... flags inside each '- Outcomes (existing flags):' bullet (the bullet runs to the next
    bullet, bold line or blank line)."""
    flags, i = [], 0
    while i < len(lines):
        if lines[i].startswith("- Outcomes (existing flags):"):
            j = i
            while True:
                for tok in re.findall(r"`(ch\d_[a-z0-9_]+)`", lines[j]):
                    flags.append((j + 1, tok))
                j += 1
                if j >= len(lines) or not lines[j].strip() or lines[j].startswith("- ") or lines[j].startswith("**"):
                    break
            i = j
        else:
            i += 1
    return flags


def check_flags(lines: list[str], all_tables: list[dict], root: Path, probs: Problems) -> None:
    live = code_text(root, strip_comments=True)
    everything = code_text(root, strip_comments=False)
    if not live:
        probs.add("flags", "no .gd or .dlg text found under AethelgardPrototype/scripts and dialogue")
        return
    outs = outcome_flags(lines)
    if len({f for _, f in outs}) < 6:
        probs.add("flags", f"found {len({f for _, f in outs})} outcome flags in the two 'Outcomes (existing flags)' bullets, expected at least 6")
    for no, flag in outs:
        if not has_word(live, flag):
            probs.add("flags", f"line {no}: outcome flag '{flag}' is not in scripts or dialogue")
    found = table_with_header(all_tables, PACE_HEADER)
    if len(found) != 1:
        probs.add("pace", f"expected exactly one table with header {' | '.join(PACE_HEADER)}, found {len(found)}")
        return
    names: list[str] = []
    acts_seen: list[str] = []
    for no, cells in found[0]["rows"]:
        if len(cells) != 7:
            probs.add("pace", f"line {no}: {len(cells)} cells, expected 7")
            continue
        act, fe, fo, fl, status, rule, source = cells
        acts_seen.append(act)
        if status not in ("existing", "new"):
            probs.add("pace", f"line {no}: status '{status}' is not existing or new")
        if not rule or not source:
            probs.add("pace", f"line {no}: empty rule or source")
        for flag, suffix in ((fe, "early"), (fo, "on_time"), (fl, "late")):
            names.append(flag)
            m = PACE_RE.match(flag)
            if not m or m.group(1) != act or m.group(2) != suffix:
                probs.add("pace", f"line {no}: '{flag}' does not match act{act}_pace_{suffix}")
                continue
            if status == "existing" and not has_word(live, flag):
                probs.add("pace", f"line {no}: existing flag '{flag}' is not in scripts or dialogue")
            if status == "new" and has_word(everything, flag):
                probs.add("pace", f"line {no}: new flag '{flag}' already appears in scripts or dialogue")
    if acts_seen != ["1", "2", "3", "4"]:
        probs.add("pace", f"acts in the table are {acts_seen}, expected ['1', '2', '3', '4']")
    if len(names) != 12 or len(set(names)) != 12:
        probs.add("pace", f"{len(names)} flags ({len(set(names))} distinct), expected 12 distinct")
    text = "\n".join(lines)
    if not re.search(r"Open Question 4 decision[^\n]*\n?[^\n]*user decision, \d{4}-\d{2}-\d{2}", text):
        probs.add("pace", "the Open Question 4 decision line is missing or is not marked 'user decision, <date>'")


# --- 6. the margins -----------------------------------------------------------------------------------------------

def scale(x: int, pct: int) -> int:
    """x * L rounded half up, with L as an integer percent (the GDD's Formulas header)."""
    return (x * pct + 50) // 100


def check_margins(all_tables: list[dict], probs: Problems) -> None:
    knobs = [t for t in all_tables if t["header"][:1] == ["knob"]]
    if len(knobs) != 1:
        probs.add("margins", f"expected exactly one knob table, found {len(knobs)}")
        return
    values: dict[str, int] = {}
    leniency: list[int] = []
    for no, cells in knobs[0]["rows"]:
        if len(cells) < 5:
            probs.add("margins", f"line {no}: {len(cells)} cells, expected 5")
            continue
        name = cells[0]
        if name.startswith("leniency L"):
            m = re.search(r"provisional ((?:\d+(?:, )?)+)", cells[4])
            if m:
                leniency = [int(v) for v in re.findall(r"\d+", m.group(1))]
            continue
        m = re.match(r"^(\d+)", cells[1])
        if not m:
            continue
        key = {"`base_deadline_min` (bridge)": "bridge_base", "`repair_duration_min`": "repair",
               "`base_deadline_min` (medicine)": "medicine_base", "`convoy_trip_min`": "trip",
               "`margin_min`": "margin"}.get(name)
        if key:
            values[key] = int(m.group(1))
    for key in ("bridge_base", "repair", "medicine_base", "trip", "margin"):
        if key not in values:
            probs.add("margins", f"the Tuning Knobs table has no default for '{key}'")
    if len(leniency) != 5:
        probs.add("margins", f"found {len(leniency)} integer leniency percents, expected 5 (ROADMAP:473)")
    if probs.items and any(i.startswith("[margins]") for i in probs.items):
        return
    for name, base, cost in (("bridge", values["bridge_base"], values["repair"]),
                             ("convoy", values["medicine_base"], values["trip"])):
        for lv in leniency:
            slack = scale(base, lv) - cost
            if slack < values["margin"]:
                probs.add("margins", f"{name}: leniency {lv} % leaves slack {slack} < margin {values['margin']}"
                                     f" (base {base}, cost {cost})")


# --- driver -------------------------------------------------------------------------------------------------------

def main() -> int:
    sys.stdout.reconfigure(encoding="utf-8", errors="replace")
    here = Path(__file__).resolve()
    ap = argparse.ArgumentParser()
    ap.add_argument("--root", default=str(here.parents[4]), help="repository root (default: derived from this file)")
    ap.add_argument("--gdd", default=None, help="GDD path (default: <root>/design/gdd/time-model.md)")
    args = ap.parse_args()
    root = Path(args.root).resolve()
    gdd = Path(args.gdd).resolve() if args.gdd else root / "design/gdd/time-model.md"
    print(f"gdd:  {gdd}\nroot: {root}")
    probs = Problems()
    if not gdd.is_file():
        probs.add("input", f"GDD not found at {gdd}")
    else:
        lines = gdd.read_text(encoding="utf-8").split("\n")
        all_tables = tables(lines)
        check_headings(lines, probs)
        check_ts_table(all_tables, root, probs)
        check_field_table(all_tables, probs)
        check_flags(lines, all_tables, root, probs)
        check_margins(all_tables, probs)
    for item in probs.items:
        print("PROBLEM", item)
    print(f"RESULT: {'PASS' if not probs.items else 'FAIL'} ({len(probs.items)} problems)")
    return 0 if not probs.items else 1


if __name__ == "__main__":
    sys.exit(main())
