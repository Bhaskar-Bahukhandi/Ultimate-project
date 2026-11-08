"""AC-5 check for story Y1-P0-S05: the repo's public issues match the findings table.

Uses the unauthenticated public GitHub API only (no token). Saves the raw JSON next to this file and prints one
line per check. Exit 0 when every check passes, 1 otherwise.

Usage: python -I production/qa/evidence/2026-11-findings/api_check.py
"""
import csv
import json
import pathlib
import re
import sys
import urllib.request
from collections import Counter

REPO = "Bhaskar-Bahukhandi/Ultimate-project"
HERE = pathlib.Path(__file__).resolve().parent
ROOT = HERE.parents[3]
TABLE = ROOT / "production" / "findings" / "findings.csv"
SOURCE_LABEL = {"CR": "source:code-review", "CL": "source:changelog", "TD": "source:tech-debt"}
PRIORITY_LABELS = {f"priority:{p}" for p in ("P1", "P2", "P3", "P4")}


def get_all(path):
    """Return every item of a paginated public API list (100 per page)."""
    items, page = [], 1
    while True:
        url = f"https://api.github.com/repos/{REPO}/{path}{'&' if '?' in path else '?'}per_page=100&page={page}"
        req = urllib.request.Request(url, headers={"Accept": "application/vnd.github+json",
                                                   "User-Agent": "aethelgard-s05-api-check"})
        with urllib.request.urlopen(req, timeout=30) as resp:
            batch = json.load(resp)
        items.extend(batch)
        if len(batch) < 100:
            return items
        page += 1


def issue_number(cell):
    """The issue number in a table cell written as `12` or `#12`, else None."""
    m = re.fullmatch(r"#?(\d+)", cell.strip())
    return int(m.group(1)) if m else None


def expected_priority(row):
    """The priority label set a row should carry: one `priority:Pn` label, or none when the column is empty."""
    return {f"priority:{row['priority'].strip()}"} if row["priority"].strip() else set()


def expected_labels(row):
    """The label set the publish script gives a row."""
    return {f"area:{row['area']}", f"severity:{row['severity']}", SOURCE_LABEL[row["id"].split("-")[0]]}


def main():
    """Run the AC-5 checks and print the result."""
    rows = list(csv.DictReader(open(TABLE, encoding="utf-8", newline="")))
    open_rows = [r for r in rows if r["status"] == "open"]
    other_rows = [r for r in rows if r["status"] != "open"]
    raw_issues = get_all("issues?state=all")
    milestones = get_all("milestones?state=all")
    (HERE / "api_issues.json").write_text(json.dumps(raw_issues, indent=1), encoding="utf-8")
    (HERE / "api_milestones.json").write_text(json.dumps(milestones, indent=1), encoding="utf-8")
    issues = [i for i in raw_issues if "pull_request" not in i]
    by_num = {i["number"]: i for i in issues}
    fails = []

    def check(ok, text):
        """Print PASS or FAIL for one check and remember a failure."""
        print(("PASS  " if ok else "FAIL  ") + text)
        if not ok:
            fails.append(text)

    print(f"# {len(raw_issues)} items from the issues endpoint, {len(raw_issues) - len(issues)} pull request(s) "
          f"excluded, {len(issues)} issues; {len(open_rows)} open rows in the table")
    ids_in_titles = Counter(i["title"].split("]")[0] + "]" for i in issues if i["title"].startswith("["))
    check(all(issue_number(r["issue"]) for r in open_rows), "every open row holds an issue number")
    check(not any(r["issue"].strip() for r in other_rows),
          "no fixed / obsolete / duplicate row holds an issue number")
    check(len(issues) == len(open_rows), f"one issue per open row ({len(issues)} issues, {len(open_rows)} rows)")
    check(all(n == 1 for n in ids_in_titles.values()), "each [<id>] title prefix is unique")
    check(not [i for i in issues if i["state"] != "open"], "no issue is closed")
    bad_title, bad_ms, bad_labels, bad_prio = [], [], [], []
    for r in open_rows:
        num = issue_number(r["issue"])
        i = by_num.get(num) if num else None
        if not i or not i["title"].startswith(f"[{r['id']}] "):
            bad_title.append(r["id"])
            continue
        if (i.get("milestone") or {}).get("title") != r["milestone"]:
            bad_ms.append(r["id"])
        names = {lab["name"] for lab in i["labels"]}
        if names - PRIORITY_LABELS != expected_labels(r):
            bad_labels.append(r["id"])
        if names & PRIORITY_LABELS != expected_priority(r):
            bad_prio.append(r["id"])
    check(not bad_title, f"each row's issue number points at its [<id>] issue {bad_title[:5]}")
    check(not bad_ms, f"each issue is on its row's milestone {bad_ms[:5]}")
    check(not bad_labels, f"each issue carries its row's area, severity and source labels {bad_labels[:5]}")
    n_prio = sum(1 for r in open_rows if r["priority"].strip())
    check(not bad_prio, f"each issue's priority:* labels equal its row's priority column ({n_prio} rows with a "
                        f"priority, none on the others) {bad_prio[:5]}")
    want = Counter(r["milestone"] for r in open_rows)
    got = {m["title"]: m["open_issues"] for m in milestones}
    for title, n in sorted(want.items()):
        check(got.get(title) == n, f"milestone '{title}': {got.get(title)} open issues, table has {n}")
    print("RESULT: %s (%d failing check(s))" % ("PASS" if not fails else "FAIL", len(fails)))
    return 0 if not fails else 1


if __name__ == "__main__":
    sys.exit(main())
