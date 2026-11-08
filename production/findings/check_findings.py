"""Reconcile production/findings/findings.csv with its sources (story Y1-P0-S05, AC-1 and AC-2).

The source counts are taken here with this script's own patterns over the source files; nothing
is read from extract_findings.py, so a count can only agree if the table really holds one row
per source item. Rows are matched to sources by their id pattern, not by the `section` text.

Fails (exit 1) on:
  - a source section whose item count (plus declared splits) differs from its row count;
  - a TD- row whose id is not a row of the register at all (one-way: an Open register row with
    no TD- row, or a TD- row whose register row is no longer Open, is printed as INFO only, so
    adding or closing register rows does not fail this check);
  - a row id that matches no source pattern, or an id that repeats;
  - an id family (CR-R, CR-C, CR-H4.n, CR-V, CR-PAE, CR-A-<group>, CL-1004-D, CL-1006-S) whose
    numbers do not run 1..N without a gap (split rows <id>a and <id>b count once);
  - an area, milestone or severity not on its list; a title that is empty, over 100 characters
    or holds a local path or an e-mail address;
  - a status not in open/fixed/obsolete/duplicate (an empty status passes with --allow-pending);
  - a fixed row whose evidence cites no commit or story, an obsolete row that cites no commit,
    a malformed hash after "commit" (under 7 or over 40 hex digits, or upper case), a cited
    story that is missing or not Complete;
  - a duplicate row without duplicate_of, or a duplicate_of that names no row;
  - a leak-scan hit in ANY cell of any row (rules of tools/github/publish_findings.scan_text:
    local paths, the Windows user name and its parts and profile folder, e-mails, token-like
    strings); the hit's position is printed, never its text;
  - once any row holds an issue number: an open row without one, or a non-open row with one,
    or one issue number on two rows (a table before publishing has none and passes);
  - an Open register row whose description cites `GitHub #N` while the table's issue for that
    TD id is not N;
  - an approval file (if it exists) whose first line is not the table's approval hash
    (publish_findings.table_hash: the table with the issue column emptied).

Warns by default, fails with --strict (each prints "WARNING: ..." and the final line counts them):
  - a well-formed cited commit that `git cat-file -e` cannot find (e.g. after a squash merge);
  - the tech-debt register header disagreeing with its table body (counts, effort list);
  - a changelog marker found 0 or 2+ times (that section is reported NOT ASSESSED, not passed);
  - no Windows user name available (USERNAME / USERPROFILE unset, e.g. Linux CI), so the
    windows-user leak rule is not applied.

Usage (from the repo root):
    python -I production/findings/check_findings.py [--csv PATH] [--register PATH]
        [--changelog PATH] [--approval PATH] [--allow-pending] [--strict]
"""

import argparse
import csv
import functools
import os
import re
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
REVIEW = ROOT / "AethelgardPrototype" / "CODE_REVIEW_2026-10-04.md"
CHANGELOG = ROOT / "AethelgardPrototype" / "CHANGELOG.md"
REGISTER = ROOT / "docs" / "tech-debt-register.md"
TABLE = ROOT / "production" / "findings" / "findings.csv"
APPROVAL = ROOT / "production" / "findings" / "publish-approval.txt"

sys.path.insert(0, str(ROOT / "tools" / "github"))
import publish_findings  # noqa: E402  (-I drops the script folder; the leak rules and hash live there)

AREAS = {"save", "input", "ui", "economy", "combat", "enemies", "encounters", "story", "regions",
         "effects", "audio", "art", "tooling", "core"}
MILESTONES = {"Y1-P0 Stabilize", "Y1-P1 Spine", "Y1-P2 Combat foundation",
              "Y1-P3 Art pipeline + Pillar Slice", "Y1-P4 Open-world tech + tools",
              "Y2-PP Pre-production", "Backlog"}
SEVERITIES = {"root-cause", "critical", "high", "medium-low", "audit-check", "pipeline", "tech-debt"}
STATUSES = {"open", "fixed", "obsolete", "duplicate"}

# Appendix group heading in the review -> id slug used in the table.
GROUP_SLUGS = {"Core": "core", "UI": "ui", "Combat": "combat", "Enemies": "enemies",
               "Encounters": "encounters", "Cutscenes / camera / VFX": "cutscenes", "Audio": "audio",
               "Background / shaders": "background", "Regions": "regions", "Chapters": "chapters",
               "Tooling / repo": "tooling"}

# Declared split list: appendix bullets that name two problems and so own two rows, <id>a and <id>b.
SPLIT_IDS = {"CR-A-core-01", "CR-A-core-02", "CR-A-ui-01", "CR-A-encounters-03", "CR-A-tooling-04"}

CHANGELOG_LISTS = {"CL-1004-D": "**Decisions left for the user, not changed:**",
                   "CL-1006-S": "**Seen, not yet fixed:**"}

HASH_RE = re.compile(r"\b(?=[0-9a-f]*[a-f])(?=[0-9a-f]*[0-9])[0-9a-f]{7,40}\b")
# A hash written after "commit" may be all digits (e.g. 5411533); the letter rule above would miss it.
COMMIT_RE = re.compile(r"\bcommits?\s+([0-9a-f]{7,40})\b")
# Any hex token holding a digit after "commit"; one that COMMIT_RE would not accept is malformed.
COMMIT_TOKEN_RE = re.compile(r"\bcommits?\s+([0-9A-Fa-f]*\d[0-9A-Fa-f]*)\b")
STORY_RE = re.compile(r"production/epics/[\w./-]+?\.md")
# Id families whose numbers must run 1..N; TD- ids follow the register, which has gaps, so they are not here.
FAMILY_RE = re.compile(r"(CR-R|CR-C|CR-H4\.\d-|CR-V|CR-PAE-|CR-A-[a-z]+-|CL-1004-D|CL-1006-S)(\d+)[ab]?")
LOCAL_RE = re.compile(r"[A-Za-z]:\\Users\\|/Users/|BAHUKHANDI|[\w.+-]+@[\w-]+\.[\w.]+", re.I)
GITHUB_REF_RE = re.compile(r"GitHub #(\d+)")


class Outcome:
    """Collects failures and warnings; a soft problem is a warning, or a failure under --strict."""

    def __init__(self, strict):
        """Start empty; `strict` turns every soft problem into a failure."""
        self.strict = strict
        self.fails = []
        self.warns = []

    def fail(self, msg):
        """Record a problem that fails the check in every mode."""
        self.fails.append(msg)

    def soft(self, msg):
        """Record a problem that warns by default and fails with --strict."""
        if self.strict:
            self.fails.append("[strict] " + msg)
        else:
            self.warns.append(msg)


def read_lines(path):
    """Return the lines of a UTF-8 text file."""
    return Path(path).read_text(encoding="utf-8").split("\n")


def between(lines, start_re, stop_re, after=0):
    """Return the lines after the first match of start_re (at or after index `after`) up to stop_re."""
    start = next(i for i in range(after, len(lines)) if re.match(start_re, lines[i]))
    out = []
    for line in lines[start + 1:]:
        if re.match(stop_re, line):
            break
        out.append(line)
    return out


def count_review(out):
    """Return {section key: (source count, id regex)} for every countable section of the review."""
    lines = read_lines(REVIEW)
    found = {}
    body = between(lines, r"## 2\. ", r"## 3\. ")
    found["review §2"] = (sum(bool(re.match(r"\| R\d+ \|", x)) for x in body), r"CR-R\d+")
    body = between(lines, r"## 3\. ", r"## 4\. ")
    found["review §3"] = (sum(bool(re.match(r"\| C\d+ \|", x)) for x in body), r"CR-C\d\d")
    for n in range(1, 8):
        body = between(lines, r"### 4\.%d " % n, r"(#{2,3} |---$)")
        found["review §4.%d" % n] = (sum(x.startswith("- ") for x in body), r"CR-H4\.%d-\d\d" % n)
    body = between(lines, r"## 5\. ", r"(## |---$)")
    table = [x for x in body if x.startswith("|")]
    found["review §5"] = (max(len(table) - 2, 0), r"CR-V\d\d")  # minus header and separator rows
    body = between(lines, r"## 6\. ", r"## 7\. ")
    design = between(body, r"\*\*Importer design", r"---$")
    numbers = [int(m.group(1)) for m in (re.match(r"(\d+)\. ", x) for x in design) if m]
    if numbers != list(range(1, len(numbers) + 1)):
        out.fail("review §6 importer items are not numbered 1..N: %s" % numbers)
    found["review §6 items"] = (len(numbers), r"CR-PAE-\d\d")
    appendix = between(lines, r"## Appendix", r"## ")
    group = None
    counts = {}
    for line in appendix:
        m = re.match(r"\*\*(.+)\.\*\*\s*$", line)
        if m:
            group = m.group(1)
            counts[group] = 0
        elif line.startswith("- ") and group:
            counts[group] += 1
    for name, n in counts.items():
        slug = GROUP_SLUGS.get(name, "UNKNOWN-" + name)
        splits = sum(s.startswith("CR-A-%s-" % slug) for s in SPLIT_IDS)
        label = "appendix %s" % name + (" (%d + %d split)" % (n, splits) if splits else "")
        found[label] = (n + splits, r"CR-A-%s-\d\d[ab]?" % slug)
    return found


def count_changelog(path, out):
    """Return {section key: (source count or None if NOT ASSESSED, id regex)} for the changelog lists."""
    lines = read_lines(path)
    found = {}
    for prefix, marker in CHANGELOG_LISTS.items():
        hits = [i for i, x in enumerate(lines) if x.strip() == marker]
        n = None
        if len(hits) == 1:
            n = 0
            for x in lines[hits[0] + 1:]:
                if not x.strip():
                    break
                n += x.startswith("- ")
        else:
            out.soft("changelog marker %r found %d times (want 1); %s count NOT ASSESSED"
                     % (marker, len(hits), prefix))
        found["changelog %s" % prefix] = (n, re.escape(prefix) + r"\d+")
    return found


def register_body(path):
    """Return (header lines, [(id, effort, status, description)]) parsed from the tech-debt register."""
    lines = read_lines(path)
    rows = []
    for x in lines:
        m = re.match(r"\|\s*(TD-\d{3})\s*\|", x)
        if m:
            cells = [c.strip() for c in x.strip()[1:-1].split(" | ")]
            rows.append((m.group(1), cells[4] if len(cells) > 4 else "?", cells[7] if len(cells) > 7 else "?",
                         cells[2] if len(cells) > 2 else ""))
    return lines[:4], rows


def check_register(path, out):
    """Compare the register header with its body (soft); return (all TD ids, Open TD ids, body rows)."""
    header, rows = register_body(path)
    total = len(rows)
    open_ids = {r[0] for r in rows if r[2] == "Open"}
    efforts = [r[1] for r in rows]
    line = next((x for x in header if x.startswith("Total items:")), "")
    m = re.match(r"Total items: (\d+) \((\d+) open\) \| Estimated total effort: (.*)$", line)
    if not m:
        out.soft("register header has no 'Total items: N (M open) | Estimated total effort: ...' line")
    else:
        if (int(m.group(1)), int(m.group(2))) != (total, len(open_ids)):
            out.soft("register header says %s (%s open), body has %d (%d open)"
                     % (m.group(1), m.group(2), total, len(open_ids)))
        if [e.strip() for e in m.group(3).split("+")] != efforts:
            out.soft("register header effort list does not match the body's Effort column")
    print("register body: %d TD rows, %d Open" % (total, len(open_ids)))
    return {r[0] for r in rows}, open_ids, rows


def check_td_rows(idset, register_ids, open_ids, out):
    """One-way TD check: fail on a table TD- id the register lacks; print drift from the Open set as INFO."""
    td_rows = {i for i in idset if re.fullmatch(r"TD-\d{3}", i)}
    for rid in sorted(td_rows - register_ids):
        out.fail("%s: in the table but not a row of the tech-debt register" % rid)
    for rid in sorted((td_rows & register_ids) - open_ids):
        print("INFO: %s is in the table but its register row is no longer Open" % rid)
    for rid in sorted(open_ids - td_rows):
        print("INFO: %s is Open in the register but has no table row (not a failure)" % rid)
    return td_rows


def check_id_gaps(idset, out):
    """Fail when an id family's numbers do not run 1..N (a split <id>a/<id>b counts as one number)."""
    families = {}
    for rid in idset:
        m = FAMILY_RE.fullmatch(rid)
        if m:
            families.setdefault(m.group(1), set()).add(int(m.group(2)))
    for prefix, numbers in sorted(families.items()):
        missing = sorted(set(range(1, max(numbers) + 1)) - numbers)
        if missing:
            out.fail("id family %s: numbers run to %d but %s missing"
                     % (prefix, max(numbers), ", ".join(str(n) for n in missing)))
    print("id families checked for gaps: %d" % len(families))


@functools.lru_cache(maxsize=None)
def git_has_commit(sha):
    """Return True if `git cat-file -e <sha>^{commit}` accepts sha in this repo (False if git cannot run)."""
    try:
        res = subprocess.run(["git", "-C", str(ROOT), "cat-file", "-e", sha + "^{commit}"],
                             capture_output=True)
    except OSError:
        return False
    return res.returncode == 0


def story_complete(rel):
    """Return True if the story file exists and its header says Status: Complete."""
    path = ROOT / rel
    if not path.is_file():
        return False
    return any(re.match(r">\s*\*\*Status\*\*:\s*Complete\b", x) for x in read_lines(path)[:15])


def check_row(row, ids, allow_pending, out):
    """Record every per-row problem of one table row."""
    rid = row["id"]
    if row["area"] not in AREAS:
        out.fail("%s: area %r not on the list" % (rid, row["area"]))
    if row["milestone"] not in MILESTONES:
        out.fail("%s: milestone %r not on the list" % (rid, row["milestone"]))
    if row["severity"] not in SEVERITIES:
        out.fail("%s: severity %r not on the list" % (rid, row["severity"]))
    title = row["title"]
    if not title or len(title) > 100 or LOCAL_RE.search(title):
        out.fail("%s: title empty, over 100 chars, or holds a local path or e-mail" % rid)
    status = row["status"]
    if status == "" and allow_pending:
        pass
    elif status not in STATUSES:
        out.fail("%s: status %r not in %s" % (rid, status, sorted(STATUSES)))
    evidence = row["evidence"]
    if status in ("fixed", "obsolete"):
        for token in COMMIT_TOKEN_RE.findall(evidence):
            if not re.fullmatch(r"[0-9a-f]{7,40}", token):
                out.fail("%s: malformed commit hash %r (want 7-40 lower-case hex digits)" % (rid, token))
        hashes = sorted(set(HASH_RE.findall(evidence)) | set(COMMIT_RE.findall(evidence)))
        stories = STORY_RE.findall(evidence)
        if status == "obsolete" and not hashes:
            out.fail("%s: obsolete but evidence names no commit" % rid)
        if status == "fixed" and not hashes and not stories:
            out.fail("%s: fixed but evidence names no commit or story" % rid)
        for sha in hashes:
            if not git_has_commit(sha):
                out.soft("%s: commit %s not found by git cat-file -e (squash-merged or not fetched?)" % (rid, sha))
        for rel in stories:
            if not story_complete(rel):
                out.fail("%s: story %s missing or not Status: Complete" % (rid, rel))
    dup = row["duplicate_of"]
    if status == "duplicate" and not dup:
        out.fail("%s: duplicate but duplicate_of is empty" % rid)
    if dup and (dup not in ids or dup == rid):
        out.fail("%s: duplicate_of %r names no other row" % (rid, dup))


def check_leaks(rows, username, home, out):
    """Leak-scan every cell of every row with publish_findings.scan_text; report positions, never text."""
    if not publish_findings.user_name_terms(username, home):
        out.soft("no Windows user name (USERNAME / USERPROFILE unset): windows-user leak rule NOT APPLIED")
    cells = 0
    for row in rows:
        for column, text in row.items():
            if column is None or not text:
                continue
            cells += 1
            for rule, start, end in publish_findings.scan_text(text, username, home):
                out.fail("%s: column %s: %s hit at character %d, length %d (text not printed)"
                         % (row.get("id", "?"), column, rule, start + 1, end - start))
    print("leak scan: %d non-empty cells, rules %s" % (cells, ", ".join(publish_findings.SCAN_RULES)))


def check_issue_numbers(rows, out):
    """Pair status with issue numbers once any number exists; return {id: issue number or None}."""
    numbers = {}
    for row in rows:
        cell = row.get("issue", "").strip()
        num = publish_findings._issue_number(cell)  # noqa: SLF001 - same parsing as the publisher
        if cell and num is None:
            out.fail("%s: issue cell %r is not an issue number" % (row["id"], cell))
        numbers[row["id"]] = num
    if not any(n is not None for n in numbers.values()):
        print("issue numbers: no issue number yet (pre-publish table; open/issue pairing not required)")
        return numbers
    seen = {}
    for row in rows:
        num = numbers[row["id"]]
        if row["status"] == "open" and num is None:
            out.fail("%s: is open but has no issue number (table already holds issue numbers)" % row["id"])
        elif row["status"] != "open" and num is not None:
            out.fail("%s: is %s but has issue number %d" % (row["id"], row["status"] or "(empty)", num))
        if num is not None:
            seen.setdefault(num, []).append(row["id"])
    for num, owners in sorted(seen.items()):
        if len(owners) > 1:
            out.fail("issue #%d is held by %d rows: %s" % (num, len(owners), ", ".join(owners)))
    print("issue numbers: %d rows hold one; open/issue pairing checked" % len(seen))
    return numbers


def check_register_issues(reg_rows, numbers, out):
    """Fail when an Open register row's `GitHub #N` differs from the table's issue for that TD id."""
    checked = 0
    for rid, _effort, status, desc in reg_rows:
        refs = sorted({int(n) for n in GITHUB_REF_RE.findall(desc)})
        if status != "Open" or not refs:
            continue
        checked += 1
        have = numbers.get(rid)
        if rid not in numbers:
            out.fail("register %s cites GitHub #%s but the table has no %s row"
                     % (rid, ", #".join(map(str, refs)), rid))
        elif refs != [have]:
            out.fail("register %s cites GitHub #%s but the table's issue is %s"
                     % (rid, ", #".join(map(str, refs)), "#%d" % have if have else "empty"))
    print("register GitHub #N references checked against the table: %d" % checked)


def check_approval_file(approval, table, out):
    """If the approval file exists, fail unless its first line is the table's approval hash."""
    path = Path(approval)
    if not path.is_file():
        print("approval file: absent, not checked")
        return
    first = path.read_text(encoding="utf-8").split("\n")[0].strip()
    token = re.sub(r"(?i)^sha-?256[:=]?", "", first.split()[0] if first else "").lower()
    try:
        want = publish_findings.table_hash(table)
    except publish_findings.PublishError as exc:
        out.fail("approval hash not computable: %s" % exc)
        return
    if token != want:
        out.fail("approval file first line does not equal the table's approval hash %s" % want)
    else:
        print("approval file: first line equals the table's approval hash")


def parse_args(argv):
    """Parse the command line (argv None means sys.argv)."""
    ap = argparse.ArgumentParser(description=__doc__.split("\n")[0])
    ap.add_argument("--csv", default=str(TABLE))
    ap.add_argument("--register", default=str(REGISTER))
    ap.add_argument("--changelog", default=str(CHANGELOG))
    ap.add_argument("--approval", default=str(APPROVAL), help="checked only if the file exists")
    ap.add_argument("--allow-pending", action="store_true", help="accept an empty status (skeleton stage)")
    ap.add_argument("--strict", action="store_true", help="turn every WARNING into a failure")
    ap.add_argument("--user-name", default=os.environ.get("USERNAME", ""),
                    help="Windows user name for the leak scan (default: USERNAME)")
    ap.add_argument("--home", default=os.environ.get("USERPROFILE", ""),
                    help="profile folder for the leak scan (default: USERPROFILE)")
    return ap.parse_args(argv)


def main(argv=None):
    """Run every check, print the counts, and return 0 on success or 1 on any failure."""
    args = parse_args(argv)
    out = Outcome(args.strict)
    with open(args.csv, encoding="utf-8", newline="") as fh:
        rows = list(csv.DictReader(fh))
    ids = [r["id"] for r in rows]
    for rid in sorted({i for i in ids if ids.count(i) > 1}):
        out.fail("id %s repeats %d times" % (rid, ids.count(rid)))
    idset = set(ids)

    sections = count_review(out)
    sections.update(count_changelog(args.changelog, out))
    register_ids, open_ids, reg_rows = check_register(args.register, out)
    check_td_rows(idset, register_ids, open_ids, out)
    check_id_gaps(idset, out)
    td_key = "register Open TD rows (INFO only)"
    sections[td_key] = (len(open_ids), r"TD-\d{3}")

    for sid in sorted(SPLIT_IDS):
        have = sorted(i for i in idset if re.fullmatch(re.escape(sid) + r"[a-z]?", i))
        if have != [sid + "a", sid + "b"]:
            out.fail("declared split %s: want rows %sa and %sb, table has %s" % (sid, sid, sid, have))
    for rid in sorted(i for i in idset if re.fullmatch(r"CR-A-.+-\d\d[a-z]", i)):
        if rid[:-1] not in SPLIT_IDS:
            out.fail("%s: suffixed id that is not on the declared split list" % rid)

    print("\n%-40s %7s %7s" % ("source section", "source", "table"))
    matched = set()
    for key, (n_src, pattern) in sections.items():
        hit = [r for r in rows if re.fullmatch(pattern, r["id"])]
        matched.update(r["id"] for r in hit)
        if n_src is None:
            print("%-40s %7s %7d  NOT ASSESSED (see WARNING)" % (key, "?", len(hit)))
            continue
        flag = "" if n_src == len(hit) else ("  differs (INFO)" if key == td_key else "  MISMATCH")
        print("%-40s %7d %7d%s" % (key, n_src, len(hit), flag))
        if flag and key != td_key:
            out.fail("%s: source has %d items, table has %d rows" % (key, n_src, len(hit)))
    for rid in sorted(idset - matched):
        out.fail("%s: id matches no source section" % rid)
    print("%-40s %7d %7d" % ("total", sum(v[0] or 0 for v in sections.values()), len(rows)))

    for row in rows:
        check_row(row, idset, args.allow_pending, out)
    check_leaks(rows, args.user_name, args.home, out)
    numbers = check_issue_numbers(rows, out)
    check_register_issues(reg_rows, numbers, out)
    check_approval_file(args.approval, args.csv, out)

    by_source = {}
    by_status = {}
    for row in rows:
        src = row["source"].split(":")[0]
        by_source[src] = by_source.get(src, 0) + 1
        st = row["status"] or "(empty)"
        by_status[st] = by_status.get(st, 0) + 1
    print("\nrows per source file:")
    for src, n in sorted(by_source.items()):
        print("  %4d  %s" % (n, src))
    print("rows per status:")
    for st, n in sorted(by_status.items()):
        print("  %4d  %s" % (n, st))

    print()
    for w in out.warns:
        print("WARNING: " + w)
    mode = " (--strict: soft checks count as failures)" if args.strict else ""
    if out.fails:
        print("FAIL: %d problem(s)" % len(out.fails))
        for f in out.fails:
            print("  - " + f)
        print("FAIL: %d problem(s), %d warning(s)%s" % (len(out.fails), len(out.warns), mode))
        return 1
    print("PASS: %d rows reconcile with their sources%s; %d warning(s)%s"
          % (len(rows), " (pending statuses allowed)" if args.allow_pending else "", len(out.warns), mode))
    return 0


if __name__ == "__main__":
    sys.stdout.reconfigure(encoding="utf-8")
    sys.exit(main())
