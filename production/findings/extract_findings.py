"""One-time bootstrap for production/findings/findings.csv (story Y1-P0-S05, AC-1).

Reads the 2026-10-04 code review, two open-item lists in the changelog and the Open rows of
the tech-debt register, and writes one CSV row per finding. It fills id, title, source,
section, severity, code_refs, area and milestone. The columns status, evidence, duplicate_of,
plan_task, priority and issue are left empty: other steps fill them by hand.

Area and milestone are decisions, not parsing: they live in the tables below, written by hand
from the story's Milestone map. Titles from this script are only a first draft; the table is
edited by hand afterwards and is then the single source (this script is not re-run).

Usage (from the repo root):
    python -I production/findings/extract_findings.py [--out PATH] [--force]

It refuses to overwrite an existing findings.csv unless --force is given, and even with --force
when any row of the existing table has a non-empty `issue` cell (the table is then published).
"""

import argparse
import csv
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
REVIEW = "AethelgardPrototype/CODE_REVIEW_2026-10-04.md"
CHANGELOG = "AethelgardPrototype/CHANGELOG.md"
REGISTER = "docs/tech-debt-register.md"

COLUMNS = ["id", "title", "source", "section", "severity", "code_refs", "area", "milestone",
           "status", "evidence", "duplicate_of", "plan_task", "priority", "issue"]

P0 = "Y1-P0 Stabilize"
P1 = "Y1-P1 Spine"
P2 = "Y1-P2 Combat foundation"
P3 = "Y1-P3 Art pipeline + Pillar Slice"
P4 = "Y1-P4 Open-world tech + tools"
PP = "Y2-PP Pre-production"
BACKLOG = "Backlog"

# --- Review sections: area per item, in source order (hand-assigned) -------------------------

ROOT_AREA = {"R1": "core", "R2": "combat", "R3": "story", "R4": "save", "R5": "story",
             "R6": "art", "R7": "core", "R8": "tooling"}
ROOT_MILESTONE = {"R1": P1, "R2": P2, "R3": P1, "R4": P1, "R5": P0, "R6": P3, "R7": P1, "R8": P0}

CRIT_AREA = ["story", "regions", "story", "story", "story", "story", "story", "effects", "save",
             "save", "save", "ui", "story", "enemies", "enemies", "combat", "combat", "combat", "tooling"]

HIGH = {  # section -> (milestone, [area per bullet])
    "4.1": (P1, ["save", "save", "save", "save", "save", "economy", "save", "save"]),
    "4.2": (P1, ["ui", "ui", "ui", "ui", "ui", "ui", "input", "ui"]),
    "4.3": (P3, ["economy", "economy", "economy", "economy", "economy", "combat"]),
    "4.4": (P2, ["combat", "combat", "combat", "combat", "combat", "combat", "combat", "ui", "combat"]),
    "4.5": (P2, ["enemies"] * 9),
    "4.6": (PP, ["story", "story", "story", "story", "story", "audio", "story", "story", "story"]),
    "4.7": (P2, ["effects", "effects", "enemies", "effects", "effects", "effects", "effects", "art",
                 "audio", "audio", "audio", "effects"]),
}
HIGH_NAMES = {"4.1": "Save / load / state", "4.2": "Pause, input, menus", "4.3": "Economy & items",
              "4.4": "Combat - player & arena", "4.5": "Enemies & bosses", "4.6": "Story & progression",
              "4.7": "Effects, cutscenes, camera, audio"}
# Section 4.6 calls: the review marks none of these critical, so the test is "blocks New Game ->
# credits". Bullet 2 (admin gate drags current_chapter back to 3) and bullet 7 (a death in chapters
# 4-10 revives the player in the Fractured Wastes) can strand a run; the others cannot.
HIGH_46_P0 = {2, 7}

AUDIT_AREA = ["story", "story", "core", "save", "combat", "art", "tooling", "core", "combat", "combat",
              "combat", "save", "story", "effects", "effects"]
AUDIT_TITLES = ["P0-1 Elara meeting relinked", "P0-2 Ironhold story gates", "P0-3 max_hp inflation",
                "P0-4 load lock", "P0-5 Root Access freeze in arena", "P0-6 change_background",
                "P0-7 'no version control' retracted", "P1-2, P1-3 and P1-8", "P1-6 DDA", "P1-7 _attack_token",
                "P1-9 collision layers", "P1-10 reset_game", "P1-11 choice buffs", "P2-5 CRT needs BackBufferCopy",
                "P2-7 camera is the best file"]

PAE_AREA = ["art"] * 10

# Appendix: group order as in the document; (slug, display name, milestone, [area per bullet]).
# A tuple holds the two areas of a bullet that is split into two rows (see SPLITS).
APPENDIX = [
    ("core", "Core", P1, [("save", "save"), ("economy", "economy"), "save", "core", "ui", "core", "ui",
                          "ui", "save", "input", "core"]),
    ("ui", "UI", P4, [("ui", "ui"), "ui", "input", "ui", "ui", "input", "core"]),
    ("combat", "Combat", P2, ["combat", "combat", "combat", "effects", "combat", "input", "combat",
                              "core", "combat", "ui", "combat"]),
    ("enemies", "Enemies", P2, ["enemies"] * 9),
    ("encounters", "Encounters", P2, ["encounters", "ui", ("encounters", "encounters"), "encounters",
                                      "encounters"]),
    ("cutscenes", "Cutscenes / camera / VFX", P2, ["effects"] * 8),
    ("audio", "Audio", P2, ["audio"] * 6),
    ("background", "Background / shaders", P3, ["effects", "art", "effects", "effects", "art", "art", "art"]),
    ("regions", "Regions", P3, ["regions"] * 8),
    ("chapters", "Chapters", PP, ["story"] * 9),
    ("tooling", "Tooling / repo", P0, ["tooling", "tooling", "tooling", ("tooling", "tooling"), "tooling",
                                       "tooling", "tooling", "tooling"]),
]

# Declared split list: appendix bullets that name two distinct problems become two rows (suffix a/b).
# Value: the two row titles. check_findings.py carries its own copy of this list of ids.
SPLITS = {
    "CR-A-core-01": ("LoreJournal leaks between saves", "Runtime lore loses its text on load"),
    "CR-A-core-02": ("Quest stat_boost rewards are wiped by the next equipment recompute",
                     "Nine quest reward IDs do not exist"),
    "CR-A-ui-01": ("Breadcrumb arrow mapping is wrong", "Breadcrumb targets the constant (640,360)"),
    "CR-A-encounters-03": ("Victory is not cancellable and can pull the player out of the main menu",
                           "Fleeing after victory double-transitions"),
    "CR-A-tooling-04": ("S3 generator hardcodes an absolute path", "S3 generator rewrites its own validator"),
}

# --- Changelog lists: area and milestone per bullet (hand-assigned) ---------------------------

CL_DECISIONS = [  # (area, milestone), in source order
    ("combat", P2), ("regions", P3), ("story", PP), ("ui", P4), ("economy", P1), ("save", P1),
    ("effects", P2), ("core", P1), ("economy", P3),
]
CL_SEEN = [("combat", P2), ("regions", P3), ("effects", P2), ("art", P3)]

# --- Tech-debt register: area per Open row (hand-assigned) ------------------------------------

TD_AREA = {
    1: "save", 5: "effects", 6: "effects", 8: "tooling", 11: "tooling", 12: "audio", 13: "enemies",
    14: "combat", 15: "tooling", 16: "tooling", 17: "tooling", 18: "tooling", 19: "ui", 20: "story",
    21: "ui", 23: "story", 24: "combat", 25: "story", 26: "tooling", 27: "save", 28: "tooling",
    29: "story", 30: "tooling", 32: "tooling", 33: "tooling", 34: "art", 35: "combat", 36: "tooling",
    37: "combat", 39: "tooling", 40: "combat", 41: "enemies", 42: "combat", 43: "ui", 44: "encounters",
    45: "enemies", 46: "tooling", 47: "combat",
}

REF_RE = re.compile(r"^[\w./*\-]+\.\w+:\d")


def clean_markdown(text):
    """Return text without markdown markers (bold, italics, backticks) and collapsed whitespace."""
    text = re.sub(r"[`*]", "", text)
    return re.sub(r"\s+", " ", text).strip()


def auto_title(text):
    """Return a first-draft title: the first clause of the item, plain text, at most 100 chars."""
    plain = clean_markdown(text)
    for sep in (" → ", " — ", ". "):
        if sep in plain:
            head = plain.split(sep)[0]
            if len(head) >= 12:
                plain = head
                break
    return plain if len(plain) <= 100 else plain[:97].rstrip() + "..."


def code_refs(text):
    """Return the backticked file:line refs in text, copied exactly and joined with ';'."""
    refs = []
    for span in re.findall(r"`([^`]+)`", text):
        if REF_RE.match(span) and span not in refs:
            refs.append(span)
    return ";".join(refs)


def new_row(rid, title, source, section, severity, refs, area, milestone):
    """Return a row dict with the filled columns set and the hand-filled columns empty."""
    row = {c: "" for c in COLUMNS}
    row.update(id=rid, title=title, source=source, section=section, severity=severity,
               code_refs=refs, area=area, milestone=milestone)
    return row


def parse_review(lines):
    """Walk the review once and return a list of (key, start_line, text) items in source order.

    key is "R", "C", "H4.n", "V", "PAE" or ("A", group display name).
    """
    items = []
    sec = None
    group = None
    pae_on = False
    cur = None

    def flush():
        """Append the item being collected (if any) to `items` and start afresh."""
        nonlocal cur
        if cur:
            items.append(cur)
        cur = None

    for no, line in enumerate(lines, 1):
        if line.startswith("## ") or line.startswith("### ") or line.strip() == "---":
            flush()
            if line.startswith("## 2."):
                sec = "R"
            elif line.startswith("## 3."):
                sec = "C"
            elif line.startswith("### 4."):
                sec = "H" + re.match(r"### (4\.\d)", line).group(1)
            elif line.startswith("## 5."):
                sec = "V"
            elif line.startswith("## 6."):
                sec, pae_on = "PAE", False
            elif line.startswith("## Appendix"):
                sec = "A"
            elif line.startswith("## "):
                sec = None
            continue
        if sec in ("R", "C", "V"):
            if line.startswith("| ") and not line.startswith("| #") and not line.startswith("| Item"):
                items.append((sec, no, line))
            continue
        if sec == "PAE":
            if line.startswith("**Importer design"):
                pae_on = True
            if pae_on and re.match(r"\d+\. ", line):
                flush()
                cur = ("PAE", no, line)
            elif cur and pae_on and line.startswith(" "):
                cur = (cur[0], cur[1], cur[2] + " " + line.strip())
            continue
        if sec == "A":
            gm = re.match(r"\*\*(.+)\.\*\*$", line)
            if gm:
                flush()
                group = gm.group(1)
                continue
        if sec and (sec.startswith("H") or sec == "A"):
            if line.startswith("- "):
                flush()
                cur = (("A", group) if sec == "A" else sec, no, line[2:])
            elif cur and line.startswith(" ") and line.strip():
                cur = (cur[0], cur[1], cur[2] + " " + line.strip())
            elif not line.strip():
                flush()
    flush()
    return items


def table_cells(line):
    """Return the stripped cells of a markdown table row."""
    return [c.strip() for c in line.strip().strip("|").split("|")]


def review_rows(items):
    """Build the CSV rows for every review item."""
    rows = []
    counters = {}
    for key, no, text in items:
        src = "%s:%d" % (REVIEW, no)
        if key == "R":
            cells = table_cells(text)
            rid = cells[0]
            rows.append(new_row("CR-" + rid, auto_title(cells[1]), src, "§2 Root causes", "root-cause",
                                code_refs(text), ROOT_AREA[rid], ROOT_MILESTONE[rid]))
        elif key == "C":
            cells = table_cells(text)
            n = int(cells[0][1:])
            title = cells[2].split(" → ")[0]
            rows.append(new_row("CR-C%02d" % n, auto_title(title), src, "§3 Critical", "critical",
                                code_refs(text), CRIT_AREA[n - 1], P0))
        elif key == "V":
            n = counters.get("V", 0) + 1
            counters["V"] = n
            rows.append(new_row("CR-V%02d" % n, AUDIT_TITLES[n - 1], src, "§5 Audit checks", "audit-check",
                                code_refs(text), AUDIT_AREA[n - 1], P0))
        elif key == "PAE":
            n = int(re.match(r"(\d+)\.", text).group(1))
            rows.append(new_row("CR-PAE-%02d" % n, auto_title(re.sub(r"^\d+\.\s*", "", text)), src,
                                "§6 PAE items", "pipeline", code_refs(text), PAE_AREA[n - 1], P3))
        elif isinstance(key, tuple):
            rows.extend(appendix_rows(key[1], no, text, src, counters))
        else:
            sec = key[1:]
            n = counters.get(key, 0) + 1
            counters[key] = n
            miles, areas = HIGH[sec]
            if sec == "4.6" and n in HIGH_46_P0:
                miles = P0
            rows.append(new_row("CR-H%s-%02d" % (sec, n), auto_title(text), src,
                                "§%s %s" % (sec, HIGH_NAMES[sec]), "high", code_refs(text),
                                areas[n - 1], miles))
    return rows


def appendix_rows(group_name, no, text, src, counters):
    """Return one row, or two rows for a declared split, for an appendix bullet."""
    slug, display, miles, areas = next(g for g in APPENDIX if g[1] == group_name)
    key = "A" + slug
    n = counters.get(key, 0) + 1
    counters[key] = n
    base = "CR-A-%s-%02d" % (slug, n)
    section = "Appendix: " + display
    area = areas[n - 1]
    if base in SPLITS:
        out = []
        for suffix, title, a in zip("ab", SPLITS[base], area):
            out.append(new_row(base + suffix, title, src, section, "medium-low", code_refs(text), a, miles))
        return out
    return [new_row(base, auto_title(text), src, section, "medium-low", code_refs(text), area, miles)]


def changelog_rows(lines):
    """Return rows for the 2026-10-04 'Decisions left' and 2026-10-06 'Seen, not yet fixed' lists."""
    rows = []
    for marker, date, prefix, section, table in (  # date: label only
            ("**Decisions left for the user, not changed:**", "2026-10-04", "CL-1004-D",
             "Changelog 2026-10-04 decisions", CL_DECISIONS),
            ("**Seen, not yet fixed:**", "2026-10-06", "CL-1006-S",
             "Changelog 2026-10-06 seen, not fixed", CL_SEEN)):
        starts = [i for i, ln in enumerate(lines) if ln.strip() == marker]
        if len(starts) != 1:
            sys.exit("expected exactly one %r in the changelog, found %d" % (marker, len(starts)))
        pos = starts[0]
        n = 0
        for j in range(pos + 1, len(lines)):
            if not lines[j].strip():
                break
            if lines[j].startswith("- "):
                n += 1
                area, miles = table[n - 1]
                rows.append(new_row("%s%d" % (prefix, n), auto_title(lines[j][2:]),
                                    "%s:%d" % (CHANGELOG, j + 1), section, "medium-low",
                                    code_refs(lines[j]), area, miles))
        if n != len(table):
            sys.exit("changelog list %s has %d bullets, table has %d" % (date, n, len(table)))
    return rows


def register_rows(lines):
    """Return one row per Open TD- row of the register, counted from the table body."""
    rows = []
    for no, line in enumerate(lines, 1):
        if not line.startswith("| TD-"):
            continue
        cells = [c.strip() for c in line.strip().strip("|").split(" | ")]
        if len(cells) != 10 or cells[7] != "Open":
            continue
        n = int(cells[0][3:])
        rows.append(new_row(cells[0], auto_title(cells[2]), "%s:%d" % (REGISTER, no),
                            "Tech-debt register (Open)", "tech-debt", code_refs(cells[2]), TD_AREA[n],
                            BACKLOG))
    return rows


def read_lines(rel):
    """Return the lines of a repo file, read as UTF-8."""
    return (ROOT / rel).read_text(encoding="utf-8").split("\n")


def published_rows(path):
    """Return the ids of the rows of an existing table whose `issue` cell is not empty."""
    with open(path, encoding="utf-8-sig", newline="") as fh:
        return [r.get("id", "?") for r in csv.DictReader(fh) if (r.get("issue") or "").strip()]


def main():
    """Parse the sources and write findings.csv; return the process exit code."""
    ap = argparse.ArgumentParser(description=__doc__.split("\n")[0])
    ap.add_argument("--out", default=str(ROOT / "production" / "findings" / "findings.csv"))
    ap.add_argument("--force", action="store_true", help="overwrite an existing findings.csv")
    args = ap.parse_args()
    out = Path(args.out)
    if out.exists() and not args.force:
        print("refusing to overwrite %s (hand-edited table); pass --force to replace it" % out)
        return 1
    if out.exists():
        published = published_rows(out)
        if published:
            print("refusing to overwrite %s even with --force: %d row(s) hold an issue number (first: %s); "
                  "the table is published and is the single source" % (out, len(published), published[0]))
            return 1
    rows = review_rows(parse_review(read_lines(REVIEW)))
    rows += changelog_rows(read_lines(CHANGELOG))
    rows += register_rows(read_lines(REGISTER))
    with open(out, "w", encoding="utf-8", newline="") as fh:
        writer = csv.DictWriter(fh, fieldnames=COLUMNS, lineterminator="\n")
        writer.writeheader()
        writer.writerows(rows)
    counts = {}
    for r in rows:
        counts[r["section"]] = counts.get(r["section"], 0) + 1
    for sec, n in counts.items():
        print("%4d  %s" % (n, sec))
    print("%4d  total -> %s" % (len(rows), out))
    return 0


if __name__ == "__main__":
    sys.exit(main())
