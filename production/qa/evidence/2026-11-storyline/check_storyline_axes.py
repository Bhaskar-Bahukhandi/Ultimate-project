"""Document checker for the storyline axes GDD (story Y1-P0-S06a, AC-7).

Parses ``design/gdd/storyline-axes.md`` and the Story Bible and reports every structural problem it finds:

1. the 8 required H2 headings in order (other H2s: Summary, Cross-References, Open Questions only);
2. the 27-row combination table (axis product, ids, vocabularies, sources, valid_count, companions), with exactly
   3 invalid rows equal to the rules table's combinations and the family split SOLE 8 / BOUND 9 / NONE_AUTH 7;
3. the secret storyline table (exactly the three reserved ids);
4. the Act 1 seed map (exactly the 26 seed flags, each present in game scripts or dialogue; axis seeds are
   ``until:lock:<axis>``, modifier and timing seeds ``no``);
5. the side-storyline table (arcs 01-12, cell vocabularies, pm_line on an "Axis effect:" line);
6. the composer input record (required fields, non-empty cells, axis and secret-route vocabularies);
7. the dated decision line in the Story Bible;
8. none of the stale strings removed by the post-review revision (``PM:3615``, ``C8-S17``, ``ch8_choice_made``).

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
STATUSES = ("valid", "invalid")
FAMILY_BY_AUTHORITY = {"YOU": "SOLE", "SHARED": "BOUND", "NONE": "NONE_AUTH"}
COMPANIONS = frozenset({"Elara", "Seraphina", "Lyra", "Kaelthas"})
# Companions each ending family requires. Story Bible §5: no family needs one. Kept as data so a future
# family that does need a companion is checked without code changes.
FAMILY_NEEDS: dict[str, frozenset[str]] = {
    "SOLE": frozenset(), "BOUND": frozenset(), "NONE_AUTH": frozenset(), "CONSENT": frozenset(),
}
DASHES = ("—", "-", "–")
INVALID_ROWS = 3
FAMILY_COUNTS = {"SOLE": 8, "BOUND": 9, "NONE_AUTH": 7}  # valid rows per family (GDD Formulas, Counts)

SECRET_ROUTES = ("WITNESS", "FIRSTWAKE", "CROWNLESS")
SECRET_ROUTE_ALLOWED = frozenset({"NO_SECRET", *SECRET_ROUTES})  # composer secret_route must allow all of these
SECRET_EXPECTED = {  # id -> (required family or None, scope)
    "SL-SECRET-WITNESS": ("CONSENT", "1.0"),
    "SL-SECRET-FIRSTWAKE": (None, "post-1.0"),
    "SL-SECRET-CROWNLESS": (None, "post-1.0"),
}

# Story S06a, Audit 4 (23 flags; the story's "22" is a miscount) plus the three Aldric-kill flags added by the
# approved post-review revision: 26 flags.
SEED_FLAGS = frozenset({
    "act1_report_local", "act1_report_archive", "act1_report_command",
    "ch2_seraphina_truth", "ch2_seraphina_cautious", "ch2_seraphina_showoff",
    "ch2_seraphina_recruited", "ch2_seraphina_stayed", "ch2_seraphina_rejected",
    "ch2_data_wraith_restored", "ch2_data_wraith_destroyed", "ch2_data_wraith_absorbed",
    "ch1_knight_killed", "ch1_knight_spared", "ch1_root_purge",
    "ch1_aldric_kill_owned", "ch1_aldric_kill_justified", "ch1_aldric_kill_unsure",
    "ch1_root_first_edit", "ch1_root_discovered_unused",
    "ch1_oakhaven_warned_villagers", "ch1_oakhaven_warned_leaders", "ch1_oakhaven_left_quietly",
    "act1_pace_early", "act1_pace_on_time", "act1_pace_late",
})
DIRECTIONS = ("+", "−", "-")  # "−" is U+2212; ASCII hyphen accepted as the same sign.
# Axis seeds hold until their axis's lock scene (lock tokens, not flags); modifier and timing seeds never lock.
OVERTURNABLE = ("no", "until:lock:faction", "until:lock:authority", "until:lock:deleted")

SIDE_ARCS = tuple(f"{n:02d}" for n in range(1, 13))
POST_1_0_ARCS = frozenset({"05", "08", "09"})
SCOPES = ("1.0", "post-1.0")

COMPOSER_FIELDS = ("authority", "faction", "deleted", "secret_route", "companions_present",
                   "regions_completed", "timing_flags", "act1_pace")

REQUIRED_HEADINGS = (("Overview",), ("Player Fantasy",), ("Detailed Rules", "Detailed Design"), ("Formulas",),
                     ("Edge Cases",), ("Dependencies",), ("Tuning Knobs",), ("Acceptance Criteria",))
OPTIONAL_HEADINGS = frozenset({"Summary", "Cross-References", "Open Questions"})

STALE_STRINGS = ("PM:3615", "C8-S17", "ch8_choice_made")

BIBLE_DECISION_PREFIX = "**Decided (2026-11-08, Y1-P0-S06a):**"

# Table headers, matched exactly (after stripping cells and backticks).
H_COMBO = ("id", "authority", "faction", "deleted", "status", "family", "rule", "source", "companions_possible")
H_RULES = ("rule", "combination", "contradiction", "source")
H_SECRET = ("id", "route", "family", "scope", "source")
H_SEED = ("flag", "pushes", "direction", "overturnable", "source")
H_SIDE = ("arc", "title", "primary", "secondary", "scope", "pm_line")
H_COMPOSER = ("field", "type", "allowed", "writer")

# Source files cited by bare name, resolved under the repo root.
SOURCE_ALIASES = {
    "PRODUCTION_MASTER_2.1.md": "AethelgardPrototype/story/source/PRODUCTION_MASTER_2.1.md",
    "STORY_BIBLE.md": "AethelgardPrototype/story/STORY_BIBLE.md",
    "ROADMAP_10_YEAR.md": "AethelgardPrototype/ROADMAP_10_YEAR.md",
}
PM_PATH = SOURCE_ALIASES["PRODUCTION_MASTER_2.1.md"]
SOURCE_RE = re.compile(r"^(?P<file>[\w./\\-]+\.md):(?P<line>\d+)$")
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
    """Resolves ``file:line`` citations under the repo root and caches each file's line count and lines."""

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

    def check(self, cell: str) -> str | None:
        """Return an error message for a malformed or dangling ``file:line`` citation, or None if it is good."""
        match = SOURCE_RE.match(cell)
        if not match:
            return f"source '{cell}' is not <file>:<line>"
        path = self.resolve(match["file"])
        if path is None:
            return f"source file '{match['file']}' not found under the repo"
        content = self.lines(path)
        line = int(match["line"])
        if content is None or not 1 <= line <= len(content):
            return f"source '{cell}' line out of range"
        return None


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
def check_combinations(lines: list[str], src: SourceResolver, probs: Problems) -> None:
    """Check the rules table, the 27-row combination table and the valid_count line."""
    area = "combinations"
    rule_rows = get_table(lines, H_RULES, area, probs)
    rules: dict[str, tuple[str, ...]] = {}
    for lineno, (rule, combo, _text, source) in rule_rows:
        if not re.fullmatch(r"R\d+", rule):
            probs.add(area, f"line {lineno}: rule id '{rule}' is not R<n>")
        triple = tuple(part.strip() for part in combo.split("+"))
        if len(triple) != 3 or any(v not in AXES[n] for n, v in zip(AXES, triple)):
            probs.add(area, f"line {lineno}: rule {rule} combination '{combo}' is not AUTHORITY + FACTION + DELETED")
        if rule in rules:
            probs.add(area, f"line {lineno}: rule {rule} defined twice")
        rules[rule] = triple
        if (err := src.check(source)) is not None:
            probs.add(area, f"line {lineno}: rules table {err}")

    rows = get_table(lines, H_COMBO, area, probs)
    if len(rows) != 27:
        probs.add(area, f"combination table has {len(rows)} rows, expected 27")
    seen_ids: dict[str, int] = {}
    triples: list[tuple[str, str, str]] = []
    valid_rows = 0
    family_counts = {family: 0 for family in FAMILY_COUNTS}
    invalid_triples: list[tuple[str, str, str]] = []
    for lineno, (sl_id, auth, fac, dele, status, family, rule, source, comps) in rows:
        where = f"line {lineno} ({sl_id})"
        if sl_id in seen_ids:
            probs.add(area, f"{where}: duplicate id {sl_id} (first at line {seen_ids[sl_id]})")
        else:
            seen_ids[sl_id] = lineno
        for name, value in (("authority", auth), ("faction", fac), ("deleted", dele)):
            if value not in AXES[name]:
                probs.add(area, f"{where}: {name} '{value}' not in {'/'.join(AXES[name])}")
        triples.append((auth, fac, dele))
        if sl_id != f"SL-{auth}-{fac}-{dele}":
            probs.add(area, f"{where}: id does not match columns (expected SL-{auth}-{fac}-{dele})")
        if status == "valid":
            valid_rows += 1
            if family in family_counts:
                family_counts[family] += 1
            expected = FAMILY_BY_AUTHORITY.get(auth)
            if family != expected:
                probs.add(area, f"{where}: valid row family '{family}', expected {expected}")
            if not is_dash(rule):
                probs.add(area, f"{where}: valid row cites rule '{rule}', expected —")
        elif status == "invalid":
            if not is_dash(family):
                probs.add(area, f"{where}: invalid row family '{family}', expected —")
            invalid_triples.append((auth, fac, dele))
            if rule not in rules:
                probs.add(area, f"{where}: invalid row rule '{rule}' is not in the rules table")
            elif rules[rule] != (auth, fac, dele):
                probs.add(area, f"{where}: invalid row cites {rule}, whose combination is {' + '.join(rules[rule])}")
        else:
            probs.add(area, f"{where}: status '{status}' not in valid/invalid")
        if (err := src.check(source)) is not None:
            probs.add(area, f"{where}: {err}")
        present = {c.strip() for c in comps.split(",") if c.strip() and not is_dash(c.strip())}
        if unknown := present - COMPANIONS:
            probs.add(area, f"{where}: companions_possible has unknown names {sorted(unknown)}")
        if status == "valid":
            if not present:
                probs.add(area, f"{where}: valid row has empty companions_possible")
            if missing := FAMILY_NEEDS.get(family, frozenset()) - present:
                probs.add(area, f"{where}: family {family} needs companions {sorted(missing)} the row omits")

    expected_set = set(itertools.product(AUTHORITY, FACTION, DELETED))
    for triple in sorted(expected_set - set(triples)):
        probs.add(area, f"missing combination {'-'.join(triple)}")
    for triple in sorted(set(triples) - expected_set):
        probs.add(area, f"combination {'-'.join(triple)} is outside the 3x3x3 product")

    if len(invalid_triples) != INVALID_ROWS:
        probs.add(area, f"{len(invalid_triples)} invalid rows, expected exactly {INVALID_ROWS}")
    rule_triples = set(rules.values())
    for triple in sorted(set(invalid_triples) - rule_triples):
        probs.add(area, f"invalid row {'-'.join(triple)} matches no rule combination")
    for triple in sorted(rule_triples - set(invalid_triples)):
        probs.add(area, f"rule combination {'-'.join(triple)} is not an invalid row")
    for family, want in FAMILY_COUNTS.items():
        if family_counts[family] != want:
            probs.add(area, f"family {family} has {family_counts[family]} valid rows, expected {want}")

    # Every 'valid_count: N' mention (the declaration and any restatement) must agree with the table.
    counts = [(n, int(m[1])) for n, line in enumerate(lines, 1) for m in re.finditer(r"valid_count:\s*(\d+)", line)]
    if not counts:
        probs.add(area, "no 'valid_count: N' line")
    for lineno, declared in counts:
        if declared != valid_rows:
            probs.add(area, f"line {lineno}: valid_count: {declared} but the table has {valid_rows} valid rows")


# --- 3. Secret storylines ------------------------------------------------------------------------------------------
def check_secrets(lines: list[str], src: SourceResolver, probs: Problems) -> None:
    """Exactly the three secret ids, Witness as CONSENT in 1.0, the other two post-1.0."""
    area = "secrets"
    rows = get_table(lines, H_SECRET, area, probs)
    ids = [cells[0] for _, cells in rows]
    for sl_id in sorted(set(SECRET_EXPECTED) - set(ids)):
        probs.add(area, f"missing secret row {sl_id}")
    for sl_id in sorted(set(ids) - set(SECRET_EXPECTED)):
        probs.add(area, f"unexpected secret row {sl_id}")
    if len(ids) != len(set(ids)):
        probs.add(area, "duplicate secret id")
    for lineno, (sl_id, _route, family, scope, source) in rows:
        if sl_id not in SECRET_EXPECTED:
            continue
        want_family, want_scope = SECRET_EXPECTED[sl_id]
        if want_family is not None and family != want_family:
            probs.add(area, f"line {lineno} ({sl_id}): family '{family}', expected {want_family}")
        if scope != want_scope:
            probs.add(area, f"line {lineno} ({sl_id}): scope '{scope}', expected {want_scope}")
        if (err := src.check(source)) is not None:
            probs.add(area, f"line {lineno} ({sl_id}): {err}")


# --- 4. Act 1 seed map ---------------------------------------------------------------------------------------------
def load_game_text(root: Path) -> str:
    """Concatenate every ``scripts/**/*.gd`` and ``dialogue/**/*.dlg`` file under AethelgardPrototype."""
    game = root / "AethelgardPrototype"
    files = sorted(game.glob("scripts/**/*.gd")) + sorted(game.glob("dialogue/**/*.dlg"))
    return "\n".join(p.read_text(encoding="utf-8", errors="replace") for p in files)


def flag_exists(flag: str, game_text: str) -> bool:
    """True if ``flag`` occurs as a whole word in the game scripts or dialogue."""
    return re.search(rf"(?<![A-Za-z0-9_]){re.escape(flag)}(?![A-Za-z0-9_])", game_text) is not None


def valid_push(cell: str, allow_wildcard: bool) -> bool:
    """True if ``cell`` is an axis value, a ``modifier:<name>``, ``timing`` or (side arcs) a secret route."""
    if cell == "timing" or re.fullmatch(r"modifier:\S+", cell):
        return True
    axis, _, value = cell.partition(":")
    if axis in AXES:
        return value in AXES[axis] or (allow_wildcard and value == "*")
    return allow_wildcard and axis == "secret" and value in SECRET_ROUTES


def check_seed_map(lines: list[str], game_text: str, probs: Problems) -> None:
    """The seed map covers exactly the seed flags, each in the game; overturnable follows the pushes column."""
    area = "seed map"
    rows = get_table(lines, H_SEED, area, probs)
    flags = [cells[0] for _, cells in rows]
    for flag in sorted(SEED_FLAGS - set(flags)):
        probs.add(area, f"seed flag '{flag}' missing from the seed map")
    for flag in sorted(set(flags) - SEED_FLAGS):
        probs.add(area, f"flag '{flag}' is not a seed flag")
    for flag in sorted({f for f in flags if flags.count(f) > 1}):
        probs.add(area, f"flag '{flag}' listed {flags.count(flag)} times")
    for lineno, (flag, pushes, direction, overturn, _source) in rows:
        where = f"line {lineno} ({flag})"
        if not FLAG_RE.match(flag) or not flag_exists(flag, game_text):
            probs.add(area, f"{where}: flag not found in AethelgardPrototype/scripts or dialogue")
        if not valid_push(pushes, allow_wildcard=False):
            probs.add(area, f"{where}: pushes '{pushes}' is not an axis value, modifier:<name> or timing")
        if direction not in DIRECTIONS:
            probs.add(area, f"{where}: direction '{direction}' not + or −")
        axis = pushes.partition(":")[0]
        want = f"until:lock:{axis}" if axis in AXES else "no"
        if overturn not in OVERTURNABLE:
            probs.add(area, f"{where}: overturnable '{overturn}' not in {', '.join(OVERTURNABLE)}")
        elif overturn != want:
            probs.add(area, f"{where}: overturnable '{overturn}' for pushes '{pushes}', expected {want}")


# --- 5. Side storylines --------------------------------------------------------------------------------------------
def check_side_arcs(lines: list[str], src: SourceResolver, probs: Problems) -> None:
    """Arcs 01-12, valid primary/secondary/scope cells, and pm_line on an 'Axis effect:' line of the PM."""
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
    pm = src.lines(src.root / PM_PATH)
    if pm is None:
        probs.add(area, f"cannot read {PM_PATH}")
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
        elif pm is not None:
            n = int(pm_line)
            if not (1 <= n <= len(pm) and pm[n - 1].strip().startswith("Axis effect:")):
                probs.add(area, f"{where}: PRODUCTION_MASTER_2.1.md:{n} is not an 'Axis effect:' line")


# --- 6. Composer input record --------------------------------------------------------------------------------------
def check_composer(lines: list[str], probs: Problems) -> None:
    """Required fields present with non-empty cells; axis fields allow exactly the axis vocabularies."""
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
        if field in AXES:
            allowed = {v.strip() for v in cells[2].split(",")}
            if allowed != set(AXES[field]):
                probs.add(area, f"line {lineno} ({field}): allowed {sorted(allowed)} != {list(AXES[field])}")
        if field == "secret_route":
            allowed = {v.strip() for v in cells[2].split(",")}
            if missing := SECRET_ROUTE_ALLOWED - allowed:
                probs.add(area, f"line {lineno} (secret_route): allowed lacks {sorted(missing)}")


# --- 7. Story Bible ------------------------------------------------------------------------------------------------
def check_bible(bible_lines: list[str], probs: Problems) -> None:
    """The Story Bible holds the dated S06a decision line."""
    if not any(line.startswith(BIBLE_DECISION_PREFIX) for line in bible_lines):
        probs.add("story bible", f"no line starting '{BIBLE_DECISION_PREFIX}'")


# --- 8. Stale strings ---------------------------------------------------------------------------------------------
def check_stale(lines: list[str], probs: Problems) -> None:
    """None of the strings the post-review revision removed may reappear in the GDD."""
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
    check_headings(gdd, probs)
    check_combinations(gdd, src, probs)
    check_secrets(gdd, src, probs)
    check_seed_map(gdd, game_text, probs)
    check_side_arcs(gdd, src, probs)
    check_composer(gdd, probs)
    check_bible(bible, probs)
    check_stale(gdd, probs)
    for item in probs.items:
        print(f"FAIL {item}")
    n = len(probs.items)
    print(f"RESULT: {'PASS' if n == 0 else 'FAIL'} ({n} problems)")
    return 0 if n == 0 else 1


if __name__ == "__main__":
    sys.exit(main())
