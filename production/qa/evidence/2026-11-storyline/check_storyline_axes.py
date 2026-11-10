"""Document checker for the storyline axes GDD (story Y1-P0-S06a, AC-7; GDD acceptance criteria 1-4).

Parses ``design/gdd/storyline-axes.md``, the Story Bible and the production master, and reports every structural
problem it finds:

1. the 8 required H2 headings in order (other H2s: Summary, Cross-References, Open Questions only);
2. the 27-row combination table (axis product, ids, vocabularies, sources on the right production-master lines,
   companions), the rules table (each quoted contradiction on its cited line), the Formulas' ``invalid()`` set, and
   every ``valid_count:`` / ``SOLE n, BOUND n, NONE_AUTH n`` statement against the table;
3. the secret storyline table (exactly the three reserved ids, each transforming the rule and abbreviation the
   production master associates with it), the ``secret_prerequisites`` knob against the production master's
   "Required flag" lists, and ``reachable_1_0``;
4. the Act 1 seed map (exactly the 26 seed flags, each present outside comments in game scripts or dialogue,
   sources resolvable, pushes and direction equal to the approved values; axis seeds ``+``/``−`` and
   ``until:lock:<axis>``, modifiers ``no``, timing ``0`` and ``no``);
5. the side-storyline table (arcs 01-12, cell vocabularies, pm_line on an "Axis effect:" line, in arc order);
6. the composer input record (required fields, non-empty cells, axis vocabularies plus UNSET, secret routes);
7. the ``storyline_id`` signature (exactly ``A, F, D, I``) and body (no timing, pace or companion input), the
   ``transform()`` map, the family map (Core Rule 11 and ``family()``) and the Counts block's arithmetic;
8. the lifecycle structure: Core Rules 1-13 with their titles, the States table and the transition table T1-T12;
9. the runtime acceptance criteria: each names its blocking stories and uses only listed observables;
10. the dated decision line in the Story Bible;
11. none of the stale strings removed by the review revisions.

Usage (from anywhere; defaults point at the real files)::

    python -I -B check_storyline_axes.py [--gdd PATH] [--bible PATH] [--root PATH]

Exit 0 and ``RESULT: PASS (0 problems)`` when clean; otherwise one line per problem, then
``RESULT: FAIL (n problems)`` and exit 1. Exit 2 if an input file cannot be read. Standard library only.
"""

from __future__ import annotations

import argparse
import itertools
import re
import sys
from pathlib import Path

# --- Fixed vocabularies (story AC-2) ------------------------------------------------------------------------------
AUTHORITY = ("YOU", "SHARED", "NONE")
FACTION = ("HEARTH", "ARCHIVE", "CONTINUITY")
DELETED = ("RESTORE", "RELEASE", "CHOOSE")
AXES = {"authority": AUTHORITY, "faction": FACTION, "deleted": DELETED}
UNSET = "UNSET"
STATUSES = ("valid", "invalid")
FAMILY_BY_AUTHORITY = {"YOU": "SOLE", "SHARED": "BOUND", "NONE": "NONE_AUTH"}
# One-letter codes the production master uses in route headings and secret foundations (e.g. YHL, NAL).
ABBR = {"YOU": "Y", "SHARED": "S", "NONE": "N", "HEARTH": "H", "ARCHIVE": "A", "CONTINUITY": "C",
        "RESTORE": "R", "RELEASE": "L", "CHOOSE": "C"}
COMPANIONS = frozenset({"Elara", "Seraphina", "Lyra", "Kaelthas"})
# Companions each ending family requires. Story Bible §5: no family needs one. Kept as data so a future
# family that does need a companion is checked without code changes.
FAMILY_NEEDS: dict[str, frozenset[str]] = {
    "SOLE": frozenset(), "BOUND": frozenset(), "NONE_AUTH": frozenset(), "CONSENT": frozenset(),
}
DASHES = ("—", "-", "–")

SECRET_ROUTES = ("WITNESS", "FIRSTWAKE", "CROWNLESS")
SECRET_ROUTE_ALLOWED = frozenset({"NO_SECRET", *SECRET_ROUTES})  # composer secret_route must allow all of these
SECRET_EXPECTED = {  # id -> (required family or None, scope)
    "SL-SECRET-WITNESS": ("CONSENT", "1.0"),
    "SL-SECRET-FIRSTWAKE": (None, "post-1.0"),
    "SL-SECRET-CROWNLESS": (None, "post-1.0"),
}
# PRODUCTION_MASTER_2.1.md:8784, canonical association of secret route and the invalid row it transforms.
SECRET_FOUNDATION = {"WITNESS": "YHR", "CROWNLESS": "NAL", "FIRSTWAKE": "NCL"}

# Story S06a, Audit 4 (23 flags; the story's "22" is a miscount) plus the three Aldric-kill flags added by the
# approved post-review revision: 26 flags. Each maps to the (pushes, direction) the user approved (2026-11-08/09,
# revision 2 on 2026-11-10: ch2_seraphina_cautious and the pace rows to 0). A change here is a design decision.
SEED_EXPECTED: dict[str, tuple[str, str]] = {
    "act1_report_local": ("faction:HEARTH", "+"),
    "act1_report_archive": ("faction:ARCHIVE", "+"),
    "act1_report_command": ("faction:CONTINUITY", "+"),
    "ch2_seraphina_truth": ("modifier:seraphina_relationship", "+"),
    "ch2_seraphina_cautious": ("modifier:seraphina_relationship", "0"),
    "ch2_seraphina_showoff": ("modifier:seraphina_relationship", "−"),
    "ch2_seraphina_recruited": ("modifier:companions_present", "+"),
    "ch2_seraphina_stayed": ("modifier:companions_present", "−"),
    "ch2_seraphina_rejected": ("modifier:companions_present", "−"),
    "ch2_data_wraith_restored": ("deleted:RESTORE", "+"),
    "ch2_data_wraith_destroyed": ("deleted:RELEASE", "+"),
    "ch2_data_wraith_absorbed": ("deleted:CHOOSE", "+"),
    "ch1_knight_killed": ("faction:HEARTH", "−"),
    "ch1_knight_spared": ("modifier:aldric_restrained", "+"),
    "ch1_root_purge": ("faction:HEARTH", "+"),
    "ch1_aldric_kill_owned": ("authority:YOU", "+"),
    "ch1_aldric_kill_justified": ("authority:YOU", "+"),
    "ch1_aldric_kill_unsure": ("authority:SHARED", "+"),
    "ch1_root_first_edit": ("authority:YOU", "+"),
    "ch1_root_discovered_unused": ("authority:NONE", "+"),
    "ch1_oakhaven_warned_villagers": ("modifier:A1-OAK-SAVED", "+"),
    "ch1_oakhaven_warned_leaders": ("modifier:A1-OAK-SAVED", "+"),
    "ch1_oakhaven_left_quietly": ("modifier:A1-OAK-QUIET", "+"),
    "act1_pace_early": ("timing", "0"),
    "act1_pace_on_time": ("timing", "0"),
    "act1_pace_late": ("timing", "0"),
}
SEED_FLAGS = frozenset(SEED_EXPECTED)
LEAN_DIRECTIONS = ("+", "−", "-")  # "−" is U+2212; ASCII hyphen accepted as the same sign.
NEUTRAL = "0"
DIRECTIONS = (*LEAN_DIRECTIONS, NEUTRAL)
# Axis seeds hold until their axis's lock scene (lock tokens, not flags); modifier and timing seeds never lock.
OVERTURNABLE = ("no", "until:lock:faction", "until:lock:authority", "until:lock:deleted")

SIDE_ARCS = tuple(f"{n:02d}" for n in range(1, 13))
POST_1_0_ARCS = frozenset({"05", "08", "09"})
SCOPES = ("1.0", "post-1.0")

COMPOSER_FIELDS = ("storyline_state", "storyline_id", "authority", "faction", "deleted", "secret_route", "family",
                   "axis_revised", "lock_negotiated", "final_reconsidered", "companions_present", "regions_completed",
                   "timing_flags", "act1_pace")
AXIS_SET_FIELDS = ("axis_revised", "lock_negotiated")  # sets whose allowed values are exactly the three axes
FAMILIES = frozenset({"SOLE", "BOUND", "NONE_AUTH", "CONSENT"})

# Revision 3 (design review round 3): the lifecycle. A change here is a design decision.
CORE_RULE_TITLES = (
    "Three axes, one value each.", "Seeds are arguments, never gates.", "Lock scenes resolve, clean or negotiated.",
    "Red lines (new content).", "An invalid combination is a political crisis, not a fail state.", "Renegotiation.",
    "Secret invocation and signposts.", "A valid row is held to its word.", "Storyline ID and the ID-lock gate.",
    "Final authorization and reconsideration.", "Ending family", "Companions are independent of the axes.",
    "Timing is a modifier.")
STATES = ("LEANING", "PARTLY_LOCKED", "CRISIS", "VALIDATED", "FIXED", "FINAL")
TRANSITIONS = tuple(f"T{n}" for n in range(1, 13))
# Identifiers that would make the storyline ID depend on timing or companions (GDD AC-4, Core Rule 13).
FORBIDDEN_ID_INPUTS = re.compile(r"pace|timing|companion|bridge|medicine|act[1-4]_|ch[0-9]+_|has_", re.IGNORECASE)
KNOWN_STORIES = frozenset({"Y2-PP-T17", "Y1-P1-T05", "Y1-P1-T03", "Y1-P0-S06b"})
FIRST_RUNTIME_AC = 5

STORYLINE_ID_PARAMS = ("A", "F", "D", "I")  # GDD AC-4: no timing or companion input

REQUIRED_HEADINGS = (("Overview",), ("Player Fantasy",), ("Detailed Rules", "Detailed Design"), ("Formulas",),
                     ("Edge Cases",), ("Dependencies",), ("Tuning Knobs",), ("Acceptance Criteria",))
OPTIONAL_HEADINGS = frozenset({"Summary", "Cross-References", "Open Questions"})

# Removed by review revision 1 (2026-11-09) and revision 2 (2026-11-10); must not reappear.
STALE_STRINGS = ("PM:3615", "C8-S17", "ch8_choice_made", "S = T", "Kaelen only executes", "PM:8735",
                 "final authorization, before", "secret_invoked", "PM:7118", "Kaelen may be one witness",
                 "at the final confrontation, to dismantle", "PM:7062-7070")

BIBLE_DECISION_PREFIX = "**Decided (2026-11-08, Y1-P0-S06a):**"

# Table headers, matched exactly (after stripping cells and backticks).
H_COMBO = ("id", "authority", "faction", "deleted", "status", "family", "rule", "source", "danger",
           "companions_possible")
H_RULES = ("rule", "combination", "contradiction", "source")
H_SECRET = ("id", "route", "family", "scope", "source")
H_SEED = ("flag", "pushes", "direction", "overturnable", "source")
H_SIDE = ("arc", "title", "primary", "secondary", "scope", "pm_line")
H_COMPOSER = ("field", "type", "allowed", "writer")
H_STATES = ("State", "storyline_state", "Live ID", "Gate", "Behavior")
H_TRANSITIONS = ("#", "from", "event", "guard", "to", "effects")
H_OBSERVABLES = ("observable", "returns")

# Source files cited by bare name, resolved under the repo root.
SOURCE_ALIASES = {
    "PRODUCTION_MASTER_2.1.md": "AethelgardPrototype/story/source/PRODUCTION_MASTER_2.1.md",
    "STORY_BIBLE.md": "AethelgardPrototype/story/STORY_BIBLE.md",
    "ROADMAP_10_YEAR.md": "AethelgardPrototype/ROADMAP_10_YEAR.md",
}
PM_PATH = SOURCE_ALIASES["PRODUCTION_MASTER_2.1.md"]
SOURCE_RE = re.compile(r"^(?P<file>[\w./\\-]+\.(?:md|dlg|gd)):(?P<line>\d+)$")
JUDGEMENT_SUFFIX = " (J)"
FLAG_RE = re.compile(r"^[a-z][a-z0-9_]*$")

REPO_ROOT = Path(__file__).resolve().parents[4]


class Problems:
    """Collects problem lines in the order they are found."""

    def __init__(self) -> None:
        """Start with no problems."""
        self.items: list[str] = []

    def add(self, area: str, message: str) -> None:
        """Record one problem, prefixed with the area (AC section) it belongs to."""
        self.items.append(f"[{area}] {message}")


def read_lines(path: Path) -> list[str]:
    """Return the file's lines (UTF-8, BOM tolerated) without line endings."""
    return path.read_text(encoding="utf-8-sig").splitlines()


def split_row(line: str) -> list[str]:
    """Split a Markdown table row into stripped cells with backticks removed."""
    body = line.strip()
    if body.startswith("|"):
        body = body[1:]
    if body.endswith("|"):
        body = body[:-1]
    return [cell.strip().replace("`", "") for cell in body.split("|")]


def find_table(lines: list[str], header: tuple[str, ...]) -> list[tuple[int, list[str]]] | None:
    """Return the body rows (1-based line number, cells) of the first table whose header equals ``header``.

    Returns None if no such header row exists. The separator row after the header is skipped; the body ends at
    the first line that does not start with ``|``.
    """
    for index, line in enumerate(lines):
        if not line.lstrip().startswith("|") or tuple(split_row(line)) != header:
            continue
        rows = []
        for offset in range(index + 2, len(lines)):
            if not lines[offset].lstrip().startswith("|"):
                break
            rows.append((offset + 1, split_row(lines[offset])))
        return rows
    return None


def is_dash(cell: str) -> bool:
    """True if the cell is an empty-value dash."""
    return cell in DASHES


def abbreviation(triple: tuple[str, str, str]) -> str:
    """The production master's three-letter code for an (authority, faction, deleted) triple, e.g. YHR."""
    return "".join(ABBR.get(value, "?") for value in triple)


def get_table(lines: list[str], header: tuple[str, ...], area: str, probs: Problems) -> list[tuple[int, list[str]]]:
    """Find a table, report it if missing, and drop (reporting) rows with the wrong number of cells."""
    rows = find_table(lines, header)
    if rows is None:
        probs.add(area, f"table with header '{' | '.join(header)}' not found")
        return []
    good = []
    for lineno, cells in rows:
        if len(cells) != len(header):
            probs.add(area, f"line {lineno}: {len(cells)} cells, expected {len(header)}")
        else:
            good.append((lineno, cells))
    return good


class SourceResolver:
    """Resolves ``file:line`` citations under the repo root and caches each file's lines."""

    def __init__(self, root: Path) -> None:
        """Bind to a repo root."""
        self.root = root
        self.cache: dict[Path, list[str] | None] = {}

    def resolve(self, name: str) -> Path | None:
        """Return the existing path for a cited file name, or None."""
        candidates = [self.root / SOURCE_ALIASES[name]] if name in SOURCE_ALIASES else []
        candidates += [self.root / name, self.root / "AethelgardPrototype" / name]
        return next((p for p in candidates if p.is_file()), None)

    def lines(self, path: Path) -> list[str] | None:
        """Return a file's lines (cached), or None if unreadable."""
        if path not in self.cache:
            try:
                self.cache[path] = read_lines(path)
            except (OSError, UnicodeDecodeError):
                self.cache[path] = None
        return self.cache[path]

    def line_text(self, cell: str) -> tuple[str | None, str | None]:
        """Return (error, text of the cited line) for a ``file:line`` citation; exactly one is None."""
        match = SOURCE_RE.match(cell)
        if not match:
            return f"source '{cell}' is not <file>:<line>", None
        path = self.resolve(match["file"])
        if path is None:
            return f"source file '{match['file']}' not found under the repo", None
        content = self.lines(path)
        line = int(match["line"])
        if content is None or not 1 <= line <= len(content):
            return f"source '{cell}' line out of range", None
        return None, content[line - 1]

    def check(self, cell: str) -> str | None:
        """Return an error message for a malformed or dangling ``file:line`` citation, or None if it is good."""
        return self.line_text(cell)[0]

    def pm(self) -> list[str] | None:
        """The production master's lines, or None if unreadable."""
        return self.lines(self.root / PM_PATH)


# --- 1. Headings ---------------------------------------------------------------------------------------------------
def check_headings(lines: list[str], probs: Problems) -> None:
    """The 8 required H2 headings appear exactly once each, in order; other H2s are only the allowed extras."""
    headings, in_fence = [], False
    for lineno, line in enumerate(lines, 1):
        if line.lstrip().startswith("```"):
            in_fence = not in_fence
        elif not in_fence and line.startswith("## "):
            headings.append((lineno, line[3:].strip()))
    required = []
    for lineno, text in headings:
        if any(text in names for names in REQUIRED_HEADINGS):
            required.append(text)
        elif text not in OPTIONAL_HEADINGS:
            probs.add("headings", f"line {lineno}: unexpected H2 heading '{text}'")
    for names in REQUIRED_HEADINGS:
        count = sum(text in names for text in required)
        if count == 0:
            probs.add("headings", f"missing heading '## {names[0]}'")
        elif count > 1:
            probs.add("headings", f"heading '## {names[0]}' appears {count} times")
    order = [next(i for i, names in enumerate(REQUIRED_HEADINGS) if text in names) for text in required]
    if order != sorted(order):
        probs.add("headings", f"required headings out of order: {', '.join(required)}")


# --- 2. The 27 combinations ----------------------------------------------------------------------------------------
def check_rules(lines: list[str], src: SourceResolver, probs: Problems) -> dict[str, tuple[str, ...]]:
    """Check the rules table (ids, combinations, quoted text on its cited line); return rule -> triple."""
    area = "combinations"
    rules: dict[str, tuple[str, ...]] = {}
    for lineno, (rule, combo, text, source) in get_table(lines, H_RULES, area, probs):
        if not re.fullmatch(r"R\d+", rule):
            probs.add(area, f"line {lineno}: rule id '{rule}' is not R<n>")
        triple = tuple(part.strip() for part in combo.split("+"))
        if len(triple) != 3 or any(v not in AXES[n] for n, v in zip(AXES, triple)):
            probs.add(area, f"line {lineno}: rule {rule} combination '{combo}' is not AUTHORITY + FACTION + DELETED")
        if rule in rules:
            probs.add(area, f"line {lineno}: rule {rule} defined twice")
        rules[rule] = triple
        err, cited = src.line_text(source)
        if err is not None:
            probs.add(area, f"line {lineno}: rules table {err}")
        elif text.strip('"“” ') not in cited:
            probs.add(area, f"line {lineno}: rule {rule} contradiction text is not on {source}")
    return rules


def check_invalid_formula(lines: list[str], rules: dict[str, tuple[str, ...]], probs: Problems) -> None:
    """The Formulas' ``invalid(A, F, D) = ... ∈ { ... }`` set equals the rules table's combinations."""
    area = "formulas"
    defs = [(n, line) for n, line in enumerate(lines, 1) if line.lstrip().startswith("invalid(A, F, D) =")]
    if len(defs) != 1:
        probs.add(area, f"expected one 'invalid(A, F, D) =' definition, found {len(defs)}")
        return
    lineno, line = defs[0]
    body = line.split("∈", 1)[-1]
    triples = {tuple(v.strip() for v in m.split(",")) for m in re.findall(r"\(([^()]*)\)", body)}
    if triples != set(rules.values()):
        probs.add(area, f"line {lineno}: invalid() set {sorted(triples)} != rules table {sorted(rules.values())}")


def check_combinations(lines: list[str], src: SourceResolver, probs: Problems) -> tuple[dict[str, tuple[str, ...]], int]:
    """Check the rules table, the 27-row combination table and the count statements; return (rules, valid rows)."""
    area = "combinations"
    rules = check_rules(lines, src, probs)
    check_invalid_formula(lines, rules, probs)

    rows = get_table(lines, H_COMBO, area, probs)
    if len(rows) != 27:
        probs.add(area, f"combination table has {len(rows)} rows, expected 27")
    seen_ids: dict[str, int] = {}
    triples: list[tuple[str, str, str]] = []
    family_counts = {family: 0 for family in FAMILY_BY_AUTHORITY.values()}
    valid_rows = 0
    invalid_triples: list[tuple[str, str, str]] = []
    pm = src.pm() or []
    for lineno, (sl_id, auth, fac, dele, status, family, rule, source, danger, comps) in rows:
        where = f"line {lineno} ({sl_id})"
        if sl_id in seen_ids:
            probs.add(area, f"{where}: duplicate id {sl_id} (first at line {seen_ids[sl_id]})")
        else:
            seen_ids[sl_id] = lineno
        for name, value in (("authority", auth), ("faction", fac), ("deleted", dele)):
            if value not in AXES[name]:
                probs.add(area, f"{where}: {name} '{value}' not in {'/'.join(AXES[name])}")
        triple = (auth, fac, dele)
        triples.append(triple)
        if sl_id != f"SL-{auth}-{fac}-{dele}":
            probs.add(area, f"{where}: id does not match columns (expected SL-{auth}-{fac}-{dele})")
        err, cited = src.line_text(source)
        if err is not None:
            probs.add(area, f"{where}: {err}")
        if status == "valid":
            valid_rows += 1
            if family in family_counts:
                family_counts[family] += 1
            expected = FAMILY_BY_AUTHORITY.get(auth)
            if family != expected:
                probs.add(area, f"{where}: valid row family '{family}', expected {expected}")
            if not is_dash(rule):
                probs.add(area, f"{where}: valid row cites rule '{rule}', expected —")
            heading = f"# STORYLINE {abbreviation(triple)} "
            if cited is not None and not cited.startswith(heading):
                probs.add(area, f"{where}: source {source} is not the '{heading.strip()}' heading")
            elif cited is not None:
                # The route's own "Primary danger:" line: the first one after its heading, before the next heading.
                start = int(source.rsplit(":", 1)[1])
                first = next((i + 1 for i in range(start, len(pm)) if pm[i].startswith(("Primary danger:", "# "))),
                             None)
                want = None
                if first is not None and pm[first - 1].startswith("Primary danger:"):
                    want = f"{PM_PATH.rsplit('/', 1)[1]}:{first}"
                if want is None or danger != want:
                    probs.add(area, f"{where}: danger '{danger}' is not the route's first 'Primary danger:' line "
                                    f"({want})")
        elif status == "invalid":
            if not is_dash(family):
                probs.add(area, f"{where}: invalid row family '{family}', expected —")
            invalid_triples.append(triple)
            if rule not in rules:
                probs.add(area, f"{where}: invalid row rule '{rule}' is not in the rules table")
            elif rules[rule] != triple:
                probs.add(area, f"{where}: invalid row cites {rule}, whose combination is {' + '.join(rules[rule])}")
            if cited is not None and not cited.startswith("Invalid V"):
                probs.add(area, f"{where}: source {source} is not an 'Invalid V' line")
            if not is_dash(danger):
                probs.add(area, f"{where}: invalid row danger '{danger}', expected —")
        else:
            probs.add(area, f"{where}: status '{status}' not in valid/invalid")
        present = {c.strip() for c in comps.split(",") if c.strip() and not is_dash(c.strip())}
        if unknown := present - COMPANIONS:
            probs.add(area, f"{where}: companions_possible has unknown names {sorted(unknown)}")
        # GDD Core Rule 10: companions are independent of the axes, so every row lists every companion.
        if missing := COMPANIONS - present:
            probs.add(area, f"{where}: companions_possible omits {sorted(missing)} (Core Rule 10)")
        if status == "valid" and (missing := FAMILY_NEEDS.get(family, frozenset()) - present):
            probs.add(area, f"{where}: family {family} needs companions {sorted(missing)} the row omits")

    expected_set = set(itertools.product(AUTHORITY, FACTION, DELETED))
    for triple in sorted(expected_set - set(triples)):
        probs.add(area, f"missing combination {'-'.join(triple)}")
    for triple in sorted(set(triples) - expected_set):
        probs.add(area, f"combination {'-'.join(triple)} is outside the 3x3x3 product")

    if len(invalid_triples) != len(rules):
        probs.add(area, f"{len(invalid_triples)} invalid rows, but the rules table has {len(rules)} rules")
    rule_triples = set(rules.values())
    for triple in sorted(set(invalid_triples) - rule_triples):
        probs.add(area, f"invalid row {'-'.join(triple)} matches no rule combination")
    for triple in sorted(rule_triples - set(invalid_triples)):
        probs.add(area, f"rule combination {'-'.join(triple)} is not an invalid row")

    # Every 'valid_count: N' and 'SOLE n, BOUND n, NONE_AUTH n' statement must agree with the table.
    counts = [(n, int(m[1])) for n, line in enumerate(lines, 1) for m in re.finditer(r"valid_count:\s*(\d+)", line)]
    if not counts:
        probs.add(area, "no 'valid_count: N' line")
    for lineno, declared in counts:
        if declared != valid_rows:
            probs.add(area, f"line {lineno}: valid_count: {declared} but the table has {valid_rows} valid rows")
    splits = [(n, m) for n, line in enumerate(lines, 1)
              for m in re.finditer(r"SOLE (\d+), BOUND (\d+), NONE_AUTH (\d+)", line)]
    if not splits:
        probs.add(area, "no 'SOLE n, BOUND n, NONE_AUTH n' statement")
    for lineno, m in splits:
        stated = {"SOLE": int(m[1]), "BOUND": int(m[2]), "NONE_AUTH": int(m[3])}
        if stated != family_counts:
            probs.add(area, f"line {lineno}: family split {stated} but the table has {family_counts}")
    LAST["family_counts"] = family_counts
    return rules, valid_rows


LAST: dict[str, object] = {"family_counts": {}, "shipped": 0}  # values derived by one check, read by check_counts


# --- 3. Secret storylines ------------------------------------------------------------------------------------------
def pm_required_flags(pm: list[str]) -> dict[str, list[str]]:
    """Map each secret route to the 'Required flag:' lines of its SEC block in the production master."""
    by_route: dict[str, list[str]] = {}
    route: str | None = None
    for line in pm:
        text = line.strip()
        if text == "---":
            route = None
        elif m := re.fullmatch(r"Secret foundation: ([A-Z]{3})\.", text):
            route = next((r for r, f in SECRET_FOUNDATION.items() if f == m[1]), None)
            if route is not None:
                by_route.setdefault(route, [])
        elif route is not None and (m := re.fullmatch(r"Required flag: ([A-Z0-9_]+)\.", text)):
            by_route[route].append(m[1])
    return by_route


def check_secrets(lines: list[str], src: SourceResolver, rules: dict[str, tuple[str, ...]], valid_rows: int,
                  probs: Problems) -> None:
    """Exactly the three secret ids with the right foundations, prerequisites matching the PM, reachable_1_0."""
    area = "secrets"
    rows = get_table(lines, H_SECRET, area, probs)
    ids = [cells[0] for _, cells in rows]
    for sl_id in sorted(set(SECRET_EXPECTED) - set(ids)):
        probs.add(area, f"missing secret row {sl_id}")
    for sl_id in sorted(set(ids) - set(SECRET_EXPECTED)):
        probs.add(area, f"unexpected secret row {sl_id}")
    if len(ids) != len(set(ids)):
        probs.add(area, "duplicate secret id")
    if len(rows) != len(rules):
        probs.add(area, f"{len(rows)} secret rows, but the rules table has {len(rules)} invalid rows to transform")
    shipped = 0
    for lineno, (sl_id, route, family, scope, source) in rows:
        if sl_id not in SECRET_EXPECTED:
            continue
        where = f"line {lineno} ({sl_id})"
        want_family, want_scope = SECRET_EXPECTED[sl_id]
        shipped += scope == "1.0"
        if want_family is not None and family != want_family:
            probs.add(area, f"{where}: family '{family}', expected {want_family}")
        if scope != want_scope:
            probs.add(area, f"{where}: scope '{scope}', expected {want_scope}")
        if (err := src.check(source)) is not None:
            probs.add(area, f"{where}: {err}")
        foundation = SECRET_FOUNDATION[sl_id.removeprefix("SL-SECRET-")]
        m = re.search(r"transforms (R\d+) / ([A-Z]{3})", route)
        if m is None:
            probs.add(area, f"{where}: route cell lacks 'transforms R<n> / <abbreviation>'")
            continue
        if m[2] != foundation:
            probs.add(area, f"{where}: transforms {m[2]}, but PM:8784 associates it with {foundation}")
        if m[1] not in rules:
            probs.add(area, f"{where}: transforms unknown rule {m[1]}")
        elif abbreviation(rules[m[1]]) != foundation:
            probs.add(area, f"{where}: {m[1]} is {abbreviation(rules[m[1]])}, not {foundation}")

    LAST["shipped"] = shipped
    # reachable_1_0 = valid rows + secret rows shipped in 1.0
    reach = [(n, int(m[1])) for n, line in enumerate(lines, 1) for m in re.finditer(r"reachable_1_0:\s*(\d+)", line)]
    if not reach:
        probs.add(area, "no 'reachable_1_0: N' statement")
    for lineno, declared in reach:
        if declared != valid_rows + shipped:
            probs.add(area, f"line {lineno}: reachable_1_0: {declared}, expected {valid_rows} + {shipped}")

    # secret_prerequisites knob == the production master's Required flag lists
    pm = src.pm()
    knob = [line for line in lines if line.lstrip().startswith("| `secret_prerequisites[")]
    if len(knob) != 1:
        probs.add(area, f"expected one secret_prerequisites knob row, found {len(knob)}")
        return
    unlock = [line for line in lines if line.lstrip().startswith("| `secret_unlock_flag[")]
    if len(unlock) != 1:
        probs.add(area, f"expected one secret_unlock_flag knob row, found {len(unlock)}")
        return
    # Read only the Default cell, so flags named in the Safe range cell are not taken for the default list.
    route_re = r"(WITNESS|CROWNLESS|FIRSTWAKE): ((?:`[A-Z0-9_]+`(?:,\s*)?)+)"
    stated = {m[1]: re.findall(r"[A-Z0-9_]+", m[2]) for m in re.finditer(route_re, knob[0].split("|")[2])}
    unlocks = {m[1]: re.findall(r"[A-Z0-9_]+", m[2]) for m in re.finditer(route_re, unlock[0].split("|")[2])}
    expected = pm_required_flags(pm) if pm is not None else {}
    seen: dict[str, str] = {}
    for route in SECRET_ROUTES:
        if route not in stated or route not in unlocks:
            probs.add(area, f"secret_prerequisites / secret_unlock_flag lists no flags for {route}")
            continue
        if len(unlocks[route]) != 1:
            probs.add(area, f"secret_unlock_flag {route} has {len(unlocks[route])} flags, expected 1")
        if len(stated[route]) < 2:
            probs.add(area, f"secret_prerequisites {route} has {len(stated[route])} flags, expected at least 2")
        for flag in stated[route]:
            if flag in seen:
                probs.add(area, f"secret_prerequisites flag {flag} is listed for {seen[flag]} and {route}")
            seen[flag] = route
        if route not in expected:
            probs.add(area, f"production master has no SEC block for {route}")
        elif stated[route] + unlocks[route] != expected[route]:
            probs.add(area, f"secret_prerequisites + secret_unlock_flag {route} {stated[route] + unlocks[route]} "
                            f"!= production master {expected[route]}")


# --- 4. Act 1 seed map ---------------------------------------------------------------------------------------------
def load_game_text(root: Path) -> str:
    """Concatenate every ``scripts/**/*.gd`` and ``dialogue/**/*.dlg`` file, dropping whole-line ``#`` comments."""
    game = root / "AethelgardPrototype"
    files = sorted(game.glob("scripts/**/*.gd")) + sorted(game.glob("dialogue/**/*.dlg"))
    kept = []
    for path in files:
        for line in path.read_text(encoding="utf-8", errors="replace").splitlines():
            if not line.lstrip().startswith("#"):
                kept.append(line)
    return "\n".join(kept)


def flag_exists(flag: str, game_text: str) -> bool:
    """True if ``flag`` occurs as a whole word in the (comment-free) game scripts or dialogue."""
    return re.search(rf"(?<![A-Za-z0-9_]){re.escape(flag)}(?![A-Za-z0-9_])", game_text) is not None


def valid_push(cell: str, allow_wildcard: bool) -> bool:
    """True if ``cell`` is an axis value, a ``modifier:<name>``, ``timing`` or (side arcs) a secret route."""
    if cell == "timing" or re.fullmatch(r"modifier:\S+", cell):
        return True
    axis, _, value = cell.partition(":")
    if axis in AXES:
        return value in AXES[axis] or (allow_wildcard and value == "*")
    return allow_wildcard and axis == "secret" and value in SECRET_ROUTES


def check_seed_map(lines: list[str], game_text: str, src: SourceResolver, probs: Problems) -> None:
    """The seed map covers exactly the seed flags, each in the game; direction and overturnable follow pushes."""
    area = "seed map"
    rows = get_table(lines, H_SEED, area, probs)
    flags = [cells[0] for _, cells in rows]
    for flag in sorted(SEED_FLAGS - set(flags)):
        probs.add(area, f"seed flag '{flag}' missing from the seed map")
    for flag in sorted(set(flags) - SEED_FLAGS):
        probs.add(area, f"flag '{flag}' is not a seed flag")
    for flag in sorted({f for f in flags if flags.count(f) > 1}):
        probs.add(area, f"flag '{flag}' listed {flags.count(flag)} times")
    for lineno, (flag, pushes, direction, overturn, source) in rows:
        where = f"line {lineno} ({flag})"
        if not FLAG_RE.match(flag) or not flag_exists(flag, game_text):
            probs.add(area, f"{where}: flag not found outside comments in AethelgardPrototype/scripts or dialogue")
        if not valid_push(pushes, allow_wildcard=False):
            probs.add(area, f"{where}: pushes '{pushes}' is not an axis value, modifier:<name> or timing")
        axis = pushes.partition(":")[0]
        if direction not in DIRECTIONS:
            probs.add(area, f"{where}: direction '{direction}' not +, − or 0")
        elif axis in AXES and direction not in LEAN_DIRECTIONS:
            probs.add(area, f"{where}: axis seed direction '{direction}', expected + or −")
        elif pushes == "timing" and direction != NEUTRAL:
            probs.add(area, f"{where}: timing row direction '{direction}', expected 0")
        want = f"until:lock:{axis}" if axis in AXES else "no"
        if overturn not in OVERTURNABLE:
            probs.add(area, f"{where}: overturnable '{overturn}' not in {', '.join(OVERTURNABLE)}")
        elif overturn != want:
            probs.add(area, f"{where}: overturnable '{overturn}' for pushes '{pushes}', expected {want}")
        if (err := src.check(source.removesuffix(JUDGEMENT_SUFFIX))) is not None:
            probs.add(area, f"{where}: {err}")
        if flag in SEED_EXPECTED:
            want_push, want_dir = SEED_EXPECTED[flag]
            if pushes != want_push or direction.replace("-", "−") != want_dir:
                probs.add(area, f"{where}: '{pushes} {direction}' differs from the approved '{want_push} {want_dir}'")


# --- 5. Side storylines --------------------------------------------------------------------------------------------
def check_side_arcs(lines: list[str], src: SourceResolver, probs: Problems) -> None:
    """Arcs 01-12, valid cells, and pm_line on an 'Axis effect:' line of the PM, increasing in arc order."""
    area = "side storylines"
    rows = get_table(lines, H_SIDE, area, probs)
    arcs = [cells[0] for _, cells in rows]
    for arc in SIDE_ARCS:
        if arc not in arcs:
            probs.add(area, f"arc {arc} missing")
    for arc in sorted(set(arcs) - set(SIDE_ARCS)):
        probs.add(area, f"unexpected arc '{arc}'")
    for arc in sorted({a for a in arcs if arcs.count(a) > 1}):
        probs.add(area, f"arc {arc} listed {arcs.count(arc)} times")
    pm = src.pm()
    if pm is None:
        probs.add(area, f"cannot read {PM_PATH}")
    by_arc: dict[str, int] = {}
    for lineno, (arc, title, primary, secondary, scope, pm_line) in rows:
        where = f"line {lineno} (arc {arc})"
        if not title:
            probs.add(area, f"{where}: empty title")
        if not primary or is_dash(primary) or not valid_push(primary, allow_wildcard=True):
            probs.add(area, f"{where}: primary '{primary}' is not an axis value, modifier, secret route or timing")
        if not (is_dash(secondary) or valid_push(secondary, allow_wildcard=True)):
            probs.add(area, f"{where}: secondary '{secondary}' is not a valid effect or —")
        want_scope = "post-1.0" if arc in POST_1_0_ARCS else "1.0"
        if scope not in SCOPES or scope != want_scope:
            probs.add(area, f"{where}: scope '{scope}', expected {want_scope}")
        if not pm_line.isdigit():
            probs.add(area, f"{where}: pm_line '{pm_line}' is not a line number")
            continue
        n = int(pm_line)
        by_arc[arc] = n
        if pm is not None and not (1 <= n <= len(pm) and pm[n - 1].strip().startswith("Axis effect:")):
            probs.add(area, f"{where}: PRODUCTION_MASTER_2.1.md:{n} is not an 'Axis effect:' line")
    ordered = [by_arc[a] for a in SIDE_ARCS if a in by_arc]
    if ordered != sorted(ordered) or len(set(ordered)) != len(ordered):
        probs.add(area, "pm_line values are not strictly increasing in arc order (arcs appear in PM order)")


# --- 6. Composer input record --------------------------------------------------------------------------------------
def check_composer(lines: list[str], probs: Problems) -> None:
    """Required fields present with non-empty cells; axis fields allow exactly UNSET plus the axis vocabulary."""
    area = "composer"
    rows = get_table(lines, H_COMPOSER, area, probs)
    by_field = {cells[0]: (lineno, cells) for lineno, cells in rows}
    for field in COMPOSER_FIELDS:
        if field not in by_field:
            probs.add(area, f"required field '{field}' missing")
            continue
        lineno, cells = by_field[field]
        for name, cell in zip(H_COMPOSER, cells):
            if not cell or is_dash(cell):
                probs.add(area, f"line {lineno} ({field}): empty '{name}' cell")
        allowed = {v.strip() for v in cells[2].split(",")}
        if field in AXES and allowed != {UNSET, *AXES[field]}:
            probs.add(area, f"line {lineno} ({field}): allowed {sorted(allowed)} != {[UNSET, *AXES[field]]}")
        if field == "secret_route" and (missing := SECRET_ROUTE_ALLOWED - allowed):
            probs.add(area, f"line {lineno} (secret_route): allowed lacks {sorted(missing)}")
        if field in AXIS_SET_FIELDS and allowed != set(AXES):
            probs.add(area, f"line {lineno} ({field}): allowed {sorted(allowed)} != {sorted(AXES)}")
        if field == "storyline_state" and allowed != set(STATES):
            probs.add(area, f"line {lineno} (storyline_state): allowed {sorted(allowed)} != {sorted(STATES)}")
        if field == "family" and allowed != FAMILIES:
            probs.add(area, f"line {lineno} (family): allowed {sorted(allowed)} != {sorted(FAMILIES)}")


# --- 7. storyline_id signature -------------------------------------------------------------------------------------
def check_signature(lines: list[str], probs: Problems) -> None:
    """Every ``storyline_id(...)`` definition line in the GDD takes exactly A, F, D, I (GDD AC-4)."""
    defs = [(n, m) for n, line in enumerate(lines, 1) if (m := re.match(r"^\s*storyline_id\(([^)]*)\):\s*$", line))]
    if not defs:
        probs.add("formulas", "no 'storyline_id(...):' definition")
    for lineno, m in defs:
        params = tuple(p.strip() for p in m[1].split(","))
        if params != STORYLINE_ID_PARAMS:
            probs.add("formulas", f"line {lineno}: storyline_id{params} != storyline_id{STORYLINE_ID_PARAMS}")
        # The body runs to the end of the code fence; it may not read timing, pace or companion state.
        for n in range(lineno, len(lines)):
            if lines[n].lstrip().startswith("```"):
                break
            code = lines[n].split("#", 1)[0]
            if (hit := FORBIDDEN_ID_INPUTS.search(code)) is not None:
                probs.add("formulas", f"line {n + 1}: storyline_id body reads '{hit[0]}' (timing/companion input)")


def check_maps(lines: list[str], rules: dict[str, tuple[str, ...]], probs: Problems) -> None:
    """transform() maps each rule to the route PM:8784 gives its combination; both family maps are the fixed one."""
    area = "formulas"
    defs = [(n, line) for n, line in enumerate(lines, 1) if line.lstrip().startswith("transform(A, F, D) =")]
    if len(defs) != 1:
        probs.add(area, f"expected one 'transform(A, F, D) =' definition, found {len(defs)}")
    else:
        lineno, line = defs[0]
        stated = dict(re.findall(r"(R\d+) → ([A-Z]+)", line))
        want = {rule: next((r for r, f in SECRET_FOUNDATION.items() if f == abbreviation(triple)), "?")
                for rule, triple in rules.items()}
        if stated != want:
            probs.add(area, f"line {lineno}: transform() map {stated} != {want} (rules table and PM:8784)")
    maps = [(n, m) for n, line in enumerate(lines, 1)
            for m in re.finditer(r"YOU → (\w+), SHARED → (\w+), NONE → (\w+)", line)]
    if len(maps) < 2:
        probs.add(area, f"expected the family map in Core Rule 11 and in family(), found {len(maps)}")
    for lineno, m in maps:
        stated = {"YOU": m[1], "SHARED": m[2], "NONE": m[3]}
        if stated != FAMILY_BY_AUTHORITY:
            probs.add(area, f"line {lineno}: family map {stated} != {FAMILY_BY_AUTHORITY}")
    witness = [n for n, line in enumerate(lines, 1) if re.match(r"\s*SL-SECRET-WITNESS\s+→ CONSENT\s*$", line)]
    if len(witness) != 1:
        probs.add(area, "family() does not map SL-SECRET-WITNESS → CONSENT exactly once")


def eval_arith(expr: str) -> int | None:
    """Evaluate an integer expression of digits, ×, −, + and spaces; None if it holds anything else."""
    expr = expr.replace("×", "*").replace("−", "-").strip()
    if not re.fullmatch(r"[\d\s*+-]+", expr):
        return None
    total, sign = 0, 1
    for term in re.split(r"\s*([+-])\s*", expr):
        if term in ("+", "-"):
            sign = 1 if term == "+" else -1
            continue
        product = 1
        for factor in term.split("*"):
            product *= int(factor)
        total += sign * product
    return total


def check_counts(lines: list[str], rules: dict[str, tuple[str, ...]], valid_rows: int, family_counts: dict[str, int],
                 secret_rows: int, shipped: int, probs: Problems) -> None:
    """Every 'name = a = b' line of the Counts block is arithmetically true and equals the value derived here."""
    area = "counts"
    try:
        start = lines.index("### Counts")
    except ValueError:
        probs.add(area, "no '### Counts' section")
        return
    invalid = set(rules.values())
    renegotiations = len(rules) * sum(len(values) - 1 for values in AXES.values())
    to_invalid = sum(1 for triple in invalid for axis, values in enumerate(AXES.values()) for v in values
                     if v != triple[axis] and tuple(v if i == axis else x for i, x in enumerate(triple)) in invalid)
    want = {"combinations": len(AUTHORITY) * len(FACTION) * len(DELETED), "valid_count": valid_rows,
            "secret_storylines": secret_rows, "design_storylines": valid_rows + secret_rows,
            "reachable_1_0": valid_rows + shipped, "family_SOLE": family_counts.get("SOLE"),
            "family_BOUND": family_counts.get("BOUND"), "family_NONE_AUTH": family_counts.get("NONE_AUTH"),
            "renegotiations": renegotiations, "renegotiations_valid": renegotiations - to_invalid}
    seen = set()
    for n in range(start + 1, len(lines)):
        if lines[n].startswith("## "):
            break
        m = re.match(r"^(\w+)\s*=\s*(.+)$", lines[n])
        if not m or m[1] not in want:
            continue
        seen.add(m[1])
        values = [eval_arith(part) for part in m[2].split("=")]
        if None in values or len(set(values)) != 1:
            probs.add(area, f"line {n + 1}: '{lines[n].strip()}' is not a true chain of equal integers")
        elif values[-1] != want[m[1]]:
            probs.add(area, f"line {n + 1}: {m[1]} = {values[-1]}, but the tables give {want[m[1]]}")
    for name in sorted(set(want) - seen):
        probs.add(area, f"Counts block has no '{name} = ...' line")


# --- 8. Lifecycle structure ----------------------------------------------------------------------------------------
def check_lifecycle(lines: list[str], probs: Problems) -> None:
    """Core Rules 1-13 in order with their titles; States table = STATES; transitions T1-T12 over those states."""
    area = "lifecycle"
    try:
        start = lines.index("### Core Rules")
        end = lines.index("### States and Transitions", start)
    except ValueError:
        probs.add(area, "no '### Core Rules' / '### States and Transitions' sections")
        return
    rules = [(n + 1, m) for n in range(start, end) if (m := re.match(r"^(\d+)\. \*\*(.+?)\*\*", lines[n]))]
    numbers = [int(m[1]) for _, m in rules]
    if numbers != list(range(1, len(CORE_RULE_TITLES) + 1)):
        probs.add(area, f"Core Rules numbered {numbers}, expected 1-{len(CORE_RULE_TITLES)}")
    for (lineno, m), title in zip(rules, CORE_RULE_TITLES):
        if m[2] != title:
            probs.add(area, f"line {lineno}: Core Rule {m[1]} title '{m[2]}', expected '{title}'")
    states = [cells[1] for _, cells in get_table(lines, H_STATES, area, probs)]
    if tuple(states) != STATES:
        probs.add(area, f"States table storyline_state values {states} != {list(STATES)}")
    rows = get_table(lines, H_TRANSITIONS, area, probs)
    if tuple(cells[0] for _, cells in rows) != TRANSITIONS:
        probs.add(area, f"transition ids {[cells[0] for _, cells in rows]} != T1-T12 in order")
    for lineno, cells in rows:
        for name, cell in (("from", cells[1]), ("to", cells[4])):
            if name == "to" and cell == "unchanged":
                continue
            named = re.findall(r"[A-Z][A-Z_]{3,}", cell)
            if not named or any(s not in STATES for s in named):
                probs.add(area, f"line {lineno} ({cells[0]}): '{name}' cell '{cell}' names no state or an unknown one")


# --- 9. Runtime acceptance criteria ---------------------------------------------------------------------------------
def check_runtime_acs(lines: list[str], probs: Problems) -> None:
    """Each runtime AC names known blocking stories and only calls observables listed in the Observables table."""
    area = "acceptance"
    observed: set[str] = set()
    for _, cells in get_table(lines, H_OBSERVABLES, area, probs):
        observed.update(re.findall(r"(\w+)\(", cells[0]))
    try:
        start = lines.index("## Acceptance Criteria")
    except ValueError:
        return
    acs: dict[int, list[str]] = {}
    current = None
    for n in range(start + 1, len(lines)):
        line = lines[n]
        if line.startswith("## ") or line.startswith("**Validation note"):
            break
        if m := re.match(r"^(\d+)\. ", line):
            current = int(m[1])
            acs[current] = [line]
        elif current is not None and line.startswith("   "):
            acs[current].append(line)
        else:
            current = None
    runtime = {k: " ".join(v) for k, v in acs.items() if k >= FIRST_RUNTIME_AC}
    if not runtime:
        probs.add(area, "no runtime acceptance criteria found")
    numbers = sorted(acs)
    if numbers != list(range(1, len(numbers) + 1)):
        probs.add(area, f"acceptance criteria numbered {numbers}, expected 1-{len(numbers)}")
    allowed_calls = observed | {"storyline_id", "family", "reconsider_targets", "lock_pass", "prereqs_met"}
    for number, text in sorted(runtime.items()):
        m = re.search(r"\*Blocked by:\*\s*(.+)$", text)
        if m is None:
            probs.add(area, f"AC {number}: no '*Blocked by:*' tag")
        else:
            named = set(re.findall(r"Y\d-[A-Za-z0-9]+-[A-Za-z0-9]+", m[1]))
            if not named or named - KNOWN_STORIES:
                probs.add(area, f"AC {number}: blocked-by names {sorted(named)}, expected stories from "
                                f"{sorted(KNOWN_STORIES)}")
        for call in re.findall(r"`(\w+)\(", text):
            if call not in allowed_calls:
                probs.add(area, f"AC {number}: uses '{call}()', which the Observables table does not list")


# --- 10. Story Bible ------------------------------------------------------------------------------------------------
def check_bible(bible_lines: list[str], probs: Problems) -> None:
    """The Story Bible holds the dated S06a decision line."""
    if not any(line.startswith(BIBLE_DECISION_PREFIX) for line in bible_lines):
        probs.add("story bible", f"no line starting '{BIBLE_DECISION_PREFIX}'")


# --- 11. Stale strings ---------------------------------------------------------------------------------------------
def check_stale(lines: list[str], probs: Problems) -> None:
    """None of the strings the review revisions removed may reappear in the GDD."""
    for lineno, line in enumerate(lines, 1):
        for stale in STALE_STRINGS:
            if stale in line:
                probs.add("stale", f"line {lineno}: stale string '{stale}' present")


def main(argv: list[str] | None = None) -> int:
    """Run every check and print the problems and the RESULT line; return the exit code."""
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument("--gdd", type=Path, default=REPO_ROOT / "design/gdd/storyline-axes.md")
    parser.add_argument("--bible", type=Path, default=REPO_ROOT / "AethelgardPrototype/story/STORY_BIBLE.md")
    parser.add_argument("--root", type=Path, default=REPO_ROOT)
    args = parser.parse_args(argv)
    if hasattr(sys.stdout, "reconfigure"):
        sys.stdout.reconfigure(encoding="utf-8")
    try:
        gdd = read_lines(args.gdd)
        bible = read_lines(args.bible)
        game_text = load_game_text(args.root)
    except (OSError, UnicodeDecodeError) as exc:
        print(f"ERROR: cannot read input: {exc}")
        return 2
    print(f"gdd:   {args.gdd}\nbible: {args.bible}\nroot:  {args.root}")
    probs = Problems()
    src = SourceResolver(args.root)
    if src.pm() is None:
        print(f"ERROR: cannot read input: {args.root / PM_PATH}")
        return 2
    check_headings(gdd, probs)
    rules, valid_rows = check_combinations(gdd, src, probs)
    check_secrets(gdd, src, rules, valid_rows, probs)
    check_seed_map(gdd, game_text, src, probs)
    check_side_arcs(gdd, src, probs)
    check_composer(gdd, probs)
    check_signature(gdd, probs)
    check_maps(gdd, rules, probs)
    check_counts(gdd, rules, valid_rows, LAST["family_counts"], len(SECRET_EXPECTED), LAST["shipped"], probs)
    check_lifecycle(gdd, probs)
    check_runtime_acs(gdd, probs)
    check_bible(bible, probs)
    check_stale(gdd, probs)
    for item in probs.items:
        print(f"FAIL {item}")
    n = len(probs.items)
    print(f"RESULT: {'PASS' if n == 0 else 'FAIL'} ({n} problems)")
    return 0 if n == 0 else 1


if __name__ == "__main__":
    sys.exit(main())
