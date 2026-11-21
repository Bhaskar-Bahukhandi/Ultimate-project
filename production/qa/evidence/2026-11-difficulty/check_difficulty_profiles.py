"""Document checker for design/gdd/difficulty-profiles.md (story Y1-P0-S06c, AC-7).

Run:  python -I -B production/qa/evidence/2026-11-difficulty/check_difficulty_profiles.py [--root ROOT] [--gdd PATH]

A document lint: it proves the text is consistent and that the constants map points at real lines; it does not prove
the profile values are good (that is /balance-check's and playtest's job). It reads only; it writes nothing.

Checks (each failure is one problem line):
  1. the 8 required H2 headings, once each, in order (Summary, Cross-References, Open Questions allowed as extras);
  2. the profile table: exact header, the 9 required rows once each, no empty cell, integer values in numeric rows;
  3. every deadline_leniency value is >= 70 and the Chapter 1 bridge margin scale(300, L) - 180 >= 30 holds;
  4. the constants map: exact header; every file_line exists under AethelgardPrototype/ and its line contains token;
     every `becomes` starts with a profile row name or `removed (`;
  5. the old-setting mapping: 0 -> beginner, 1 -> easy, 2 -> medium, 3 -> hard and other/missing -> medium, once each,
     no row to hell, and the line `persistence: per-run`;
  6. balance-check.md exists in this folder and has a Health line.
It does not parse Formulas, Edge Cases or the Acceptance Criteria text: their worked numbers are review items and
Year 1 Phase 2 tests.
"""
from __future__ import annotations

import argparse
import re
import sys
from pathlib import Path

REQUIRED_HEADINGS = [("Overview",), ("Player Fantasy",), ("Detailed Design", "Detailed Rules"), ("Formulas",),
                     ("Edge Cases",), ("Dependencies",), ("Tuning Knobs",), ("Acceptance Criteria",)]
OPTIONAL_HEADINGS = {"Summary", "Cross-References", "Open Questions"}
PROFILES = ["beginner", "easy", "medium", "hard", "hell"]
PROFILE_HEADER = ["parameter", *PROFILES, "unit", "source"]
REQUIRED_ROWS = ["parry_window", "dodge_iframes", "boss_telegraph", "enemy_damage", "deadline_leniency",
                 "boss_patterns", "healing", "dda", "loot"]
NUMERIC_ROWS = {"parry_window", "dodge_iframes", "boss_telegraph", "enemy_damage", "deadline_leniency", "healing"}
MAP_HEADER = ["parameter", "constant", "file_line", "token", "current_value", "becomes"]
OLD_HEADER = ["old_value", "old_name", "profile", "what changes for the player"]
EXPECTED_MAP = {"0": "beginner", "1": "easy", "2": "medium", "3": "hard", "other/missing": "medium"}
CODE_ROOT = "AethelgardPrototype"


class Problems:
    def __init__(self) -> None:
        self.items: list[str] = []

    def add(self, area: str, text: str) -> None:
        self.items.append(f"[{area}] {text}")


def split_row(line: str) -> list[str]:
    body = line.strip()
    if body.startswith("|"):
        body = body[1:]
    if body.endswith("|") and not body.endswith("\\|"):
        body = body[:-1]
    return [c.strip().replace("\\|", "|") for c in re.split(r"(?<!\\)\|", body)]


def tables(lines: list[str]) -> list[dict]:
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


def one_table(all_tables: list[dict], header: list[str], area: str, probs: Problems) -> dict | None:
    found = [t for t in all_tables if t["header"] == header]
    if len(found) != 1:
        probs.add(area, f"expected exactly one table with header {' | '.join(header)}, found {len(found)}")
        return None
    return found[0]


def scale(x: int, pct: int) -> int:
    return (x * pct + 50) // 100


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
        if count != 1:
            probs.add("headings", f"heading '## {names[0]}' appears {count} times, expected 1")
    order = [next(i for i, names in enumerate(REQUIRED_HEADINGS) if text in names) for text in required]
    if order != sorted(order):
        probs.add("headings", "required headings out of order: " + ", ".join(required))


def check_profiles(all_tables: list[dict], probs: Problems) -> dict[str, list[str]]:
    table = one_table(all_tables, PROFILE_HEADER, "profiles", probs)
    rows: dict[str, list[str]] = {}
    if table is None:
        return rows
    for no, cells in table["rows"]:
        if len(cells) != len(PROFILE_HEADER):
            probs.add("profiles", f"line {no}: {len(cells)} cells, expected {len(PROFILE_HEADER)}")
            continue
        name = cells[0]
        if name in rows:
            probs.add("profiles", f"line {no}: row '{name}' appears twice")
        rows[name] = cells[1:6]
        if not all(cells):
            probs.add("profiles", f"line {no}: an empty cell in row '{name}'")
        if name in NUMERIC_ROWS and not all(re.fullmatch(r"\d+", v) for v in cells[1:6]):
            probs.add("profiles", f"line {no}: row '{name}' has a non-integer profile value")
    for name in REQUIRED_ROWS:
        if name not in rows:
            probs.add("profiles", f"required row '{name}' is missing")
    return rows


def check_leniency(rows: dict[str, list[str]], probs: Problems) -> None:
    values = rows.get("deadline_leniency")
    if not values or not all(v.isdigit() for v in values):
        probs.add("leniency", "no integer deadline_leniency row to check")
        return
    for profile, v in zip(PROFILES, values):
        pct = int(v)
        if pct < 70:
            probs.add("leniency", f"{profile}: deadline_leniency {pct} is below 70 (time-model F5)")
        slack = scale(300, pct) - 180
        if slack < 30:
            probs.add("leniency", f"{profile}: bridge slack {slack} < 30 at leniency {pct} (F8)")


def check_constants(all_tables: list[dict], rows: dict[str, list[str]], root: Path, probs: Problems) -> None:
    table = one_table(all_tables, MAP_HEADER, "constants", probs)
    if table is None:
        return
    if not table["rows"]:
        probs.add("constants", "the constants map has no rows")
    for no, cells in table["rows"]:
        if len(cells) != len(MAP_HEADER):
            probs.add("constants", f"line {no}: {len(cells)} cells, expected {len(MAP_HEADER)}")
            continue
        _, _, file_line, token, _, becomes = cells
        m = re.fullmatch(r"(scripts/[\w/.-]+\.gd):(\d+)", file_line)
        if not m:
            probs.add("constants", f"line {no}: file_line '{file_line}' is not scripts/<path>.gd:<line>")
        else:
            path = root / CODE_ROOT / m.group(1)
            if not path.is_file():
                probs.add("constants", f"line {no}: {m.group(1)} does not exist under {CODE_ROOT}/")
            else:
                src = path.read_text(encoding="utf-8", errors="replace").split("\n")
                n = int(m.group(2))
                if not 1 <= n <= len(src):
                    probs.add("constants", f"line {no}: {file_line} is past the end of the file")
                elif not token or token not in src[n - 1]:
                    probs.add("constants", f"line {no}: {file_line} does not contain token '{token}'")
        first = re.split(r"[\s(]", becomes, maxsplit=1)[0]
        if not (becomes.startswith("removed (") or first in rows):
            probs.add("constants", f"line {no}: becomes '{becomes}' is neither a profile row nor 'removed (...)'")


def check_mapping(all_tables: list[dict], lines: list[str], probs: Problems) -> None:
    table = one_table(all_tables, OLD_HEADER, "mapping", probs)
    if table is not None:
        seen: dict[str, int] = {}
        for no, cells in table["rows"]:
            if len(cells) != len(OLD_HEADER):
                probs.add("mapping", f"line {no}: {len(cells)} cells, expected {len(OLD_HEADER)}")
                continue
            old, _, profile, _ = cells
            seen[old] = seen.get(old, 0) + 1
            if profile not in PROFILES:
                probs.add("mapping", f"line {no}: '{profile}' is not a profile id")
            if profile == "hell":
                probs.add("mapping", f"line {no}: an old value maps to hell")
            if old in EXPECTED_MAP and profile != EXPECTED_MAP[old]:
                probs.add("mapping", f"line {no}: old value '{old}' maps to '{profile}', expected {EXPECTED_MAP[old]}")
        for old in ("0", "1", "2", "3", "other/missing"):
            if seen.get(old, 0) != 1:
                probs.add("mapping", f"old value '{old}' appears {seen.get(old, 0)} times, expected 1")
    if not any(l.strip() == "persistence: per-run" for l in lines):
        probs.add("mapping", "no 'persistence: per-run' line (user decision 2026-11-19)")


def check_balance_report(evidence: Path, probs: Problems) -> None:
    report = evidence / "balance-check.md"
    if not report.is_file():
        probs.add("balance", f"{report.name} is missing from the evidence folder")
    elif not re.search(r"Health", report.read_text(encoding="utf-8", errors="replace")):
        probs.add("balance", f"{report.name} has no Health line")


def main() -> int:
    sys.stdout.reconfigure(encoding="utf-8", errors="replace")
    here = Path(__file__).resolve()
    ap = argparse.ArgumentParser()
    ap.add_argument("--root", default=str(here.parents[4]))
    ap.add_argument("--gdd", default=None)
    ap.add_argument("--evidence", default=str(here.parent))
    args = ap.parse_args()
    root = Path(args.root).resolve()
    gdd = Path(args.gdd).resolve() if args.gdd else root / "design/gdd/difficulty-profiles.md"
    print(f"gdd:  {gdd}\nroot: {root}")
    probs = Problems()
    if not gdd.is_file():
        probs.add("input", f"GDD not found at {gdd}")
    else:
        lines = gdd.read_text(encoding="utf-8").split("\n")
        all_tables = tables(lines)
        check_headings(lines, probs)
        rows = check_profiles(all_tables, probs)
        check_leniency(rows, probs)
        check_constants(all_tables, rows, root, probs)
        check_mapping(all_tables, lines, probs)
        check_balance_report(Path(args.evidence), probs)
    for item in probs.items:
        print("PROBLEM", item)
    print(f"RESULT: {'PASS' if not probs.items else 'FAIL'} ({len(probs.items)} problems)")
    return 0 if not probs.items else 1


if __name__ == "__main__":
    sys.exit(main())
