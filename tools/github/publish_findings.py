#!/usr/bin/env python3
"""Publish the review-findings table to GitHub through the `gh` CLI (story Y1-P0-S05, AC-3 to AC-6).

The table `production/findings/findings.csv` is the single source. This script builds ONE action plan from it and
either prints it (`--dry-run`: no call is made) or executes the same plan. It writes exactly one column back, `issue`,
and never reads, prints or stores a token: it runs `gh`, which uses the login the user made with `gh auth login`.

Phases (sub-commands)
    labels      create the label scheme and the milestones of the `open` rows (idempotent: `--force`, and an
                "already exists" milestone reply counts as done)
    issues      create one issue per `open` row that has no issue number yet; ONE batch (default 50) per invocation
    priorities  set `priority:P1..P4` on the issues of `open` rows from the `priority` column (idempotent); ONE
                batch per invocation like `issues`, but nothing is written back, so reach later batches with a
                larger `--batches` (earlier ones are re-applied, harmlessly)
    hash        print the table's approval hash (see below)

Usage (from the repo root; every real run needs the user's OK for that step)
    python tools/github/publish_findings.py labels --dry-run
    python tools/github/publish_findings.py issues --dry-run [--batch-size 50] [--batches 1] [--show-bodies]
    python tools/github/publish_findings.py issues --repo Bhaskar-Bahukhandi/Ultimate-project
    python tools/github/publish_findings.py hash

Safety rules
    * Approval: a real run refuses unless `production/findings/publish-approval.txt` holds the table's SHA-256.
      The hash is taken over the table with the `issue` column emptied and the rows re-serialised canonically
      (columns in schema order, QUOTE_MINIMAL, `\\n` line ends). This script writes the `issue` column after every
      create, so a hash of the raw file would go stale after the first row; this one stays valid until a human edits
      any other cell. The file may hold the bare hash, `sha256:<hash>` or `sha256sum` output; `#` lines are ignored.
    * Body scan (dry run and real run, before any call): every title and body is checked for
      - local paths: `<drive>:\\Users\\` or `<drive>:/users/` (any case), `Users\\<name>` anywhere (any case, so
        `\\\\host\\C$\\Users\\bob` too), `Users/<name>` anywhere (`/Users/bob`, `/mnt/c/Users/bob`), `/home/<name>/`;
      - the user name: the login name (USERNAME / USER) and the basename of the home folder (USERPROFILE / HOME),
        each whole and as each whitespace-separated part of 3+ characters, case-insensitive, as a whole word;
      - e-mail addresses; token prefixes `ghp_`, `gho_`, `ghu_`, `ghs_`, `ghr_`, `github_pat_`, `sk-ant-`, and
        `AKIA` + 16 upper-case letters or digits (an AWS access key id);
      - hex runs of 32+ characters (no exemption: a short commit hash is below the limit, a 32+ hex run is a hit
        even after the word `commit`);
      - alphanumeric runs of 32+ characters that mix upper case, lower case and a digit, and of 40+ characters
        whatever their case (pure hex is left to the hex rule).
      Printed results give row id, field, line, column and length, never the matched text.
      Limits: base64 runs are split at `/`, `_` and `-`, so a secret broken up by those is only caught by its prefix;
      a single user-name part such as a first name may also match ordinary words.
    * Rate limits: a failed `gh` call whose output mentions a rate limit, abuse detection, "too many requests", an
      HTTP 429 or a Retry-After is waited out: the longer of the server's hint (Retry-After, "try again in N",
      X-RateLimit-Reset, at most MAX_SERVER_WAIT_S) and the backoff 60, 120, 240 s, then retried. After 3 failed
      retries the run stops with exit code 3 and names the row it reached. A plain HTTP 403 (permissions) is not a
      rate limit. Known limit: a create that GitHub accepted but reported as limited would be retried; the AC-5 check
      of unique `[<id>]` titles catches such a duplicate.
    * Resume: the issue number is written into the row, atomically (temp file + replace), right after each create or
      adopt. Once per batch, `gh issue list --state all --limit 1000 --json number,title` is read and an issue whose
      title starts with `[<id>] ` is adopted instead of created. A list of exactly 1000 issues is refused as
      possibly truncated.
    * Bodies are passed with `--body-file` (a temp file), never as a shell-quoted argument.

Exit codes: 0 ok, 2 refused (table invalid, scan hit, approval missing or stale), 3 rate-limit stop, 4 other failure.

Observed on GitHub: `gh issue edit --remove-label` for labels the issue does not carry is a no-op. The 19 priority
edits of 2026-11-08 ran clean with three such removals each
(production/qa/evidence/2026-11-findings/publish_priorities.log).
"""
from __future__ import annotations

import argparse
import csv
import dataclasses
import getpass
import hashlib
import io
import json
import math
import os
import re
import shlex
import subprocess
import sys
import tempfile
import time
from collections.abc import Callable, Iterable, Sequence
from pathlib import Path
from typing import Protocol, TextIO

# ----------------------------------------------------------------------------------------------- constants
BATCH_SIZE = 50                      # issues per batch (one batch per invocation by default)
BATCH_PAUSE_S = 30                   # pause between two batches of one run
BACKOFF_S = (60, 120, 240)           # waits before retry 1, 2, 3 after a rate-limit reply
MAX_RETRIES = 3                      # failed retries before the run stops
MAX_SERVER_WAIT_S = 3700             # ceiling for a server-supplied wait (a primary limit resets within an hour)
ISSUE_LIST_LIMIT = 1000              # `gh issue list --limit`; a list this long may be truncated
TITLE_MAX = 256                      # GitHub's issue title limit
BODY_MAX = 60000                     # below GitHub's 65536-character body limit
REPLACE_ATTEMPTS = 5                 # os.replace retries on PermissionError (OneDrive / virus scanners)

EXIT_OK = 0
EXIT_REFUSED = 2
EXIT_RATE_LIMIT = 3
EXIT_ERROR = 4

COLUMNS = ("id", "title", "source", "section", "severity", "code_refs", "area", "milestone", "status",
           "evidence", "duplicate_of", "plan_task", "priority", "issue")
AREAS = ("save", "input", "ui", "economy", "combat", "enemies", "encounters", "story", "regions", "effects",
         "audio", "art", "tooling", "core")
SEVERITIES = ("root-cause", "critical", "high", "medium-low", "audit-check", "pipeline", "tech-debt")
SOURCE_BY_PREFIX = {"CR-": "code-review", "CL-": "changelog", "TD-": "tech-debt"}
PRIORITIES = ("P1", "P2", "P3", "P4")
STATUSES = ("open", "fixed", "obsolete", "duplicate")
PHASES = ("labels", "issues", "priorities", "hash")

ROOT = Path(__file__).resolve().parents[2]
DEFAULT_TABLE = ROOT / "production" / "findings" / "findings.csv"
DEFAULT_APPROVAL = ROOT / "production" / "findings" / "publish-approval.txt"
BODY_FILE_TOKEN = "<body-file>"      # placeholder in a plan; replaced by the temp file's path at call time
_ID_RE = re.compile(r"^[A-Za-z0-9][A-Za-z0-9._-]*$")
_ISSUE_RE = re.compile(r"^#?(\d+)$")


# ----------------------------------------------------------------------------------------------- errors
class PublishError(Exception):
    """A run that cannot continue; `exit_code` is the process exit code."""

    exit_code = EXIT_ERROR


class Refused(PublishError):
    """The run was refused before any call (bad table, scan hit, missing or stale approval)."""

    exit_code = EXIT_REFUSED


class RateLimitStop(PublishError):
    """Three retries after a rate-limit reply all failed."""

    exit_code = EXIT_RATE_LIMIT


# ----------------------------------------------------------------------------------------------- gh runner
@dataclasses.dataclass
class GhResult:
    """What one `gh` call returned."""

    returncode: int
    stdout: str = ""
    stderr: str = ""


class GhRunner(Protocol):
    """Anything that can run `gh <args>`; the default shells out, tests inject a stub."""

    def run(self, args: Sequence[str]) -> GhResult:  # pragma: no cover - protocol
        """Run `gh <args>` and return what it printed."""
        ...


class SubprocessGh:
    """Runs the real `gh` CLI with an argument list (never through a shell, never reading a token)."""

    def __init__(self, timeout_s: int = 180) -> None:
        """Store the injected collaborators."""
        self.timeout_s = timeout_s

    def run(self, args: Sequence[str]) -> GhResult:
        """Run `gh <args>`; a missing executable or a timeout is returned as a failed result."""
        env = dict(os.environ)
        env["GH_PROMPT_DISABLED"] = "1"
        try:
            done = subprocess.run(["gh", *args], capture_output=True, text=True, encoding="utf-8",
                                  errors="replace", stdin=subprocess.DEVNULL, check=False, env=env,
                                  timeout=self.timeout_s)
        except FileNotFoundError:
            return GhResult(127, "", "gh was not found on PATH: install GitHub CLI and run `gh auth login`")
        except subprocess.TimeoutExpired:
            return GhResult(124, "", f"gh did not answer within {self.timeout_s} s")
        return GhResult(done.returncode, done.stdout or "", done.stderr or "")


# ----------------------------------------------------------------------------------------------- rate limits
_RATE_RE = re.compile(r"rate[ -]?limit|abuse detection|too many requests|retry-after|http[ :]*429", re.I)
_RETRY_AFTER_RE = re.compile(r"retry-after[:=\s]+(\d+)", re.I)
_RETRY_PHRASE_RE = re.compile(r"(?:retry after|try again in)\s+(\d+)\s*(seconds?|secs?|s|minutes?|mins?|m)\b", re.I)
_RESET_RE = re.compile(r"x-ratelimit-reset[:=\s]+(\d{9,11})", re.I)


def is_rate_limited(result: GhResult) -> bool:
    """True when a failed `gh` call was refused for a rate limit (primary, secondary, abuse detection, 429)."""
    if result.returncode == 0:
        return False
    return bool(_RATE_RE.search(f"{result.stderr}\n{result.stdout}"))


def parse_server_wait(result: GhResult, now: float) -> float | None:
    """Seconds the server asked us to wait (Retry-After, "try again in N", X-RateLimit-Reset), or None."""
    text = f"{result.stderr}\n{result.stdout}"
    waits: list[float] = []
    for match in _RETRY_AFTER_RE.finditer(text):
        waits.append(float(match.group(1)))
    for match in _RETRY_PHRASE_RE.finditer(text):
        waits.append(float(match.group(1)) * (60 if match.group(2).lower().startswith("m") else 1))
    for match in _RESET_RE.finditer(text):
        waits.append(max(0.0, math.ceil(float(match.group(1)) - now)))
    if not waits:
        return None
    return min(max(waits), float(MAX_SERVER_WAIT_S))


# ----------------------------------------------------------------------------------------------- the table
@dataclasses.dataclass
class Table:
    """The findings table as read from disk; `newline` is the file's own line ending, kept on write."""

    path: Path
    header: list[str]
    rows: list[dict[str, str]]
    newline: str


def load_table(path: Path | str) -> Table:
    """Read the table (UTF-8, optional BOM); raises Refused if it is unreadable or lacks the schema's columns."""
    path = Path(path)
    try:
        text = path.read_bytes().decode("utf-8-sig")
    except (OSError, UnicodeDecodeError) as exc:
        raise Refused(f"cannot read the table {_display_path(path)}: {exc}") from exc
    crlf = text.count("\r\n")
    newline = "\r\n" if crlf > text.count("\n") - crlf else "\n"
    reader = csv.reader(io.StringIO(text, newline=""))
    header: list[str] | None = None
    rows: list[dict[str, str]] = []
    for record in reader:
        if not record:
            continue
        if header is None:
            header = record
            missing = [c for c in COLUMNS if c not in header]
            extra = [c for c in header if c not in COLUMNS]
            if missing or extra or len(set(header)) != len(header):
                raise Refused(f"the table's columns differ from the schema (missing: {missing}, "
                              f"unexpected or repeated: {extra or 'none'})")
            continue
        if len(record) != len(header):
            raise Refused(f"table line {reader.line_num} has {len(record)} fields, expected {len(header)}")
        rows.append(dict(zip(header, record)))
    if header is None:
        raise Refused("the table is empty")
    return Table(path, header, rows, newline)


def _serialize(header: Sequence[str], rows: Iterable[dict[str, str]], newline: str, blank_issue: bool = False) -> str:
    """The rows as CSV text in `header` order; `blank_issue` empties the issue column (hash form)."""
    buf = io.StringIO(newline="")
    writer = csv.writer(buf, lineterminator=newline)
    writer.writerow(header)
    for row in rows:
        writer.writerow(["" if (blank_issue and col == "issue") else row[col] for col in header])
    return buf.getvalue()


def table_hash(path: Path | str) -> str:
    """The approval hash: SHA-256 of the table with the `issue` column emptied, in canonical CSV form."""
    table = load_table(path)
    canonical = _serialize(COLUMNS, table.rows, "\n", blank_issue=True)
    return hashlib.sha256(canonical.encode("utf-8")).hexdigest()


def _write_atomic(path: Path, text: str, sleep: Callable[[float], None]) -> None:
    """Write `text` (UTF-8, newline untouched) next to `path`, then replace `path`; never leaves a half file."""
    fd, tmp_name = tempfile.mkstemp(prefix=path.name + ".", suffix=".tmp", dir=str(path.parent))
    tmp = Path(tmp_name)
    try:
        with os.fdopen(fd, "w", encoding="utf-8", newline="") as handle:
            handle.write(text)
            handle.flush()
            os.fsync(handle.fileno())
        for attempt in range(REPLACE_ATTEMPTS):
            try:
                os.replace(tmp, path)
                return
            except PermissionError:
                if attempt == REPLACE_ATTEMPTS - 1:
                    raise
                sleep(0.5)
    except BaseException:
        tmp.unlink(missing_ok=True)
        raise


def set_issue(path: Path | str, row_id: str, number: int, sleep: Callable[[float], None] = time.sleep) -> None:
    """Write `number` into the `issue` cell of row `row_id` (fresh read, atomic replace); other cells untouched."""
    table = load_table(path)
    for row in table.rows:
        if row["id"] == row_id:
            row["issue"] = str(number)
            break
    else:
        raise PublishError(f"row {row_id} is no longer in the table; cannot write issue #{number}")
    _write_atomic(table.path, _serialize(table.header, table.rows, table.newline), sleep)


def _issue_number(cell: str) -> int | None:
    """The issue number in a cell written as `12` or `#12`, else None."""
    match = _ISSUE_RE.match(cell.strip())
    return int(match.group(1)) if match else None


def validate_rows(rows: Sequence[dict[str, str]]) -> list[str]:
    """Problems that make the table unusable for publishing; every message names the row id."""
    errors: list[str] = []
    seen: set[str] = set()
    for n, row in enumerate(rows, start=2):
        rid = row["id"]
        tag = rid or f"table line {n}"
        if not _ID_RE.match(rid):
            errors.append(f"{tag}: id is empty or has characters outside letters, digits, . _ -")
        elif rid in seen:
            errors.append(f"{rid}: id repeats")
        seen.add(rid)
        if _ID_RE.match(rid) and not any(rid.startswith(p) for p in SOURCE_BY_PREFIX):
            errors.append(f"{rid}: id prefix must be one of {', '.join(SOURCE_BY_PREFIX)}")
        if row["status"] not in STATUSES:
            errors.append(f"{tag}: status {row['status']!r} is not one of {', '.join(STATUSES)}")
        if row["issue"].strip() and _issue_number(row["issue"]) is None:
            errors.append(f"{tag}: issue {row['issue']!r} is not a number")
        if row["priority"].strip() and row["priority"] not in PRIORITIES:
            errors.append(f"{tag}: priority {row['priority']!r} is not one of {', '.join(PRIORITIES)}")
        if row["status"] != "open":
            continue
        if not row["title"].strip() or "\n" in row["title"] or "\r" in row["title"]:
            errors.append(f"{tag}: title is empty or spans lines")
        elif len(build_title(row)) > TITLE_MAX:
            errors.append(f"{tag}: issue title is longer than {TITLE_MAX} characters")
        if row["area"] not in AREAS:
            errors.append(f"{tag}: area {row['area']!r} is not on the area list")
        if row["severity"] not in SEVERITIES:
            errors.append(f"{tag}: severity {row['severity']!r} is not on the severity list")
        if not row["milestone"].strip():
            errors.append(f"{tag}: milestone is empty")
        if len(build_body(row)) > BODY_MAX:
            errors.append(f"{tag}: issue body is longer than {BODY_MAX} characters")
    return errors


# ----------------------------------------------------------------------------------------------- issue text
def source_label(row: dict[str, str]) -> str:
    """`source:*` label name of a row, taken from its id prefix (CR- code review, CL- changelog, TD- tech debt)."""
    for prefix, name in SOURCE_BY_PREFIX.items():
        if row["id"].startswith(prefix):
            return f"source:{name}"
    raise PublishError(f"{row['id']}: no source label for this id prefix")


def build_title(row: dict[str, str]) -> str:
    """Issue title: `[<id>] <title>`."""
    return f"[{row['id']}] {row['title'].strip()}"


def _code(text: str) -> str:
    """`text` in backticks unless it already holds a backtick."""
    return text if "`" in text else f"`{text}`"


def build_body(row: dict[str, str]) -> str:
    """Issue body: id, source, section, severity, area, milestone, plan task, code refs and evidence."""
    refs = [r.strip() for r in re.split(r"[;\n]", row["code_refs"]) if r.strip()]
    lines = [
        f"- **Finding:** `{row['id']}`",
        f"- **Source:** {_code(row['source']) if row['source'].strip() else 'not recorded'}",
        f"- **Section:** {row['section'] or 'not recorded'}",
        f"- **Severity:** {row['severity']}",
        f"- **Area:** {row['area']}",
        f"- **Milestone:** {row['milestone']}",
    ]
    if row["plan_task"].strip():
        lines.append(f"- **Plan task:** {row['plan_task'].strip()}")
    lines += ["", "**Code refs**", ""]
    lines += [f"- {_code(r)}" for r in refs] or ["- none recorded"]
    lines += ["", "**Evidence**", "", row["evidence"].strip() or "None recorded.", "",
              "---", "_Filed from the review-findings table (story Y1-P0-S05)._", ""]
    return "\n".join(lines)


# ----------------------------------------------------------------------------------------------- body scan
SCAN_RULES = ("local-path", "windows-user", "email", "token-prefix", "hex-run", "base64-run")
NAME_PART_MIN = 3                    # a user-name part shorter than this is not scanned for on its own
LONG_RUN_MIN = 40                    # an alphanumeric run this long is a hit whatever its letter case
_LOCAL_PATH = re.compile(
    r"(?<![A-Za-z0-9])[A-Za-z]:[\\/]+(?i:users)[\\/]"      # C:\Users\  c:/users/  (drive letter, any case)
    r"|(?<![A-Za-z0-9])(?i:users)\\+(?=[^\s\\/])"           # Users\<name>  \users\<name>  \\host\C$\Users\<name>
    r"|(?<![A-Za-z0-9])Users/+(?=[^\s\\/])"                 # /Users/<name>  /mnt/c/Users/<name>  Users/<name>
    r"|(?<![\w.:/-])/home/[A-Za-z0-9._-]+/"                 # /home/<name>/  (not res://home/ or a URL path)
)
_EMAIL = re.compile(r"(?<![\w.+-])[\w.+-]+@[A-Za-z0-9-]+(?:\.[A-Za-z0-9-]+)+")
_TOKEN = re.compile(r"\bgh[pousr]_[A-Za-z0-9]+|\bgithub_pat_[A-Za-z0-9_]+"
                    r"|\bAKIA[0-9A-Z]{16}(?![0-9A-Za-z])|\bsk-ant-[A-Za-z0-9_-]+")
_HEX_RUN = re.compile(r"(?<![A-Za-z0-9])[0-9a-fA-F]{32,}(?![A-Za-z0-9])")
_ALNUM_RUN = re.compile(r"(?<![A-Za-z0-9+])[A-Za-z0-9+]{32,}={0,2}")


def user_name_terms(username: str, home: str = "") -> list[str]:
    """What the windows-user rule looks for: the user name and the basename of the home folder, each whole and as
    its whitespace-separated parts of NAME_PART_MIN+ characters; case-insensitive duplicates dropped."""
    base = re.split(r"[\\/]", home.strip().rstrip("\\/"))[-1] if home.strip() else ""
    terms: dict[str, str] = {}
    for name in (username, base):
        parts = name.split()
        whole = " ".join(parts)
        for term in [whole] + parts:
            if len(term) >= NAME_PART_MIN:
                terms.setdefault(term.lower(), term)
    return list(terms.values())


def _user_name_regex(username: str, home: str) -> re.Pattern | None:
    """One case-insensitive regex over every user-name term (longest first, so one place gives one hit)."""
    terms = sorted(user_name_terms(username, home), key=len, reverse=True)
    if not terms:
        return None
    body = "|".join(r"\s+".join(re.escape(p) for p in term.split()) for term in terms)
    return re.compile(r"(?<![A-Za-z0-9])(?:" + body + r")(?![A-Za-z0-9])", re.I)


def scan_text(text: str, username: str = "", home: str = "") -> list[tuple[str, int, int]]:
    """Leak scan of one string; returns (rule, start, end) per hit, rules named in SCAN_RULES.

    `username` is the login name and `home` the home folder path (USERPROFILE or HOME); both are injected so the
    scan is deterministic under test.
    """
    hits: list[tuple[str, int, int]] = []
    hits += [("local-path", m.start(), m.end()) for m in _LOCAL_PATH.finditer(text)]
    name_re = _user_name_regex(username, home)
    if name_re is not None:
        hits += [("windows-user", m.start(), m.end()) for m in name_re.finditer(text)]
    hits += [("email", m.start(), m.end()) for m in _EMAIL.finditer(text)]
    hits += [("token-prefix", m.start(), m.end()) for m in _TOKEN.finditer(text)]
    hits += [("hex-run", m.start(), m.end()) for m in _HEX_RUN.finditer(text)]
    for m in _ALNUM_RUN.finditer(text):
        run = m.group(0).rstrip("=")
        if re.fullmatch(r"[0-9a-fA-F]+", run):
            continue                                  # pure hex is the hex-run rule's business
        mixed = bool(re.search(r"\d", run) and re.search(r"[a-z]", run) and re.search(r"[A-Z]", run))
        if mixed or len(run) >= LONG_RUN_MIN:
            hits.append(("base64-run", m.start(), m.end()))
    return sorted(hits, key=lambda h: (h[1], h[0]))


@dataclasses.dataclass(frozen=True)
class Hit:
    """One scan finding: where, never what."""

    row_id: str
    field: str
    rule: str
    line: int
    column: int
    length: int


def scan_rows(rows: Iterable[dict[str, str]], username: str, home: str = "") -> tuple[int, list[Hit]]:
    """Scan the title and body of each given row; returns (rows scanned, hits). See scan_text for the arguments."""
    hits: list[Hit] = []
    count = 0
    for row in rows:
        count += 1
        for field, text in (("title", build_title(row)), ("body", build_body(row))):
            for rule, start, end in scan_text(text, username, home):
                line = text.count("\n", 0, start) + 1
                column = start - (text.rfind("\n", 0, start) + 1) + 1
                hits.append(Hit(row["id"], field, rule, line, column, end - start))
    return count, hits


def redact(text: str) -> str:
    """Mask token-like strings in text echoed from gh."""
    return _TOKEN.sub("<redacted-token>", text)


# ----------------------------------------------------------------------------------------------- the plan
def render_call(args: Sequence[str], body: str | None = None) -> str:
    """One `gh ...` line; the value after `--body-file` is shown as the body's length and hash when `body` is known."""
    shown: list[str] = []
    previous = ""
    for arg in args:
        if previous == "--body-file" and body is not None:
            digest = hashlib.sha256(body.encode("utf-8")).hexdigest()[:12]
            shown.append(f"<body {len(body)} chars sha256:{digest}>")
        else:
            shown.append(shlex.quote(arg))
        previous = arg
    return "gh " + " ".join(shown)


@dataclasses.dataclass(frozen=True)
class Action:
    """One step of a plan. kinds: label, milestone, list-issues, create-issue, edit-priority, pause."""

    kind: str
    args: tuple[str, ...] = ()
    row_id: str = ""
    body: str = ""
    label: str = ""
    seconds: int = 0

    def display(self) -> str:
        """The line shown for this step in a dry run and in a run log."""
        if self.kind == "pause":
            return f"# pause {self.seconds} s between batches"
        return render_call(self.args, self.body if self.kind == "create-issue" else None)


@dataclasses.dataclass
class Plan:
    """The ordered steps of one phase plus the header notes that explain them."""

    phase: str
    actions: list[Action]
    notes: list[str]


def label_specs() -> list[tuple[str, str, str]]:
    """The approved label scheme as (name, colour, description)."""
    specs = [(f"area:{a}", "1d76db", f"Area: {a}") for a in AREAS]
    specs += [(f"severity:{s}", "b60205", f"Review severity: {s}") for s in SEVERITIES]
    specs += [(f"source:{name}", "5319e7", f"Source: {name.replace('-', ' ')}") for name in SOURCE_BY_PREFIX.values()]
    specs += [(f"priority:{p}", "fbca04", f"Triage priority {p}") for p in PRIORITIES]
    return specs


def _repo_args(repo: str | None) -> tuple[str, ...]:
    """`--repo OWNER/REPO` when a repo was given, else nothing (gh then uses the current git remote)."""
    return ("--repo", repo) if repo else ()


def _chunks(items: list, size: int) -> list[list]:
    """`items` cut into consecutive lists of at most `size`."""
    return [items[i:i + size] for i in range(0, len(items), size)]


def _plan_labels(opened: Sequence[dict[str, str]], repo: str | None) -> tuple[list[Action], str]:
    """labels phase: every label of the scheme, then one milestone per distinct milestone of the open rows."""
    actions: list[Action] = []
    for name, colour, description in label_specs():
        actions.append(Action("label", ("label", "create", name, "--color", colour, "--description",
                                        description, "--force", *_repo_args(repo)), label=name))
    path = f"repos/{repo}/milestones" if repo else "repos/{owner}/{repo}/milestones"
    for title in dict.fromkeys(r["milestone"] for r in opened):
        actions.append(Action("milestone", ("api", "--method", "POST", path, "-f", f"title={title}",
                                            "-f", "state=open", "-f",
                                            "description=Findings milestone (story Y1-P0-S05)"),
                              label=f"milestone {title}"))
    note = (f"# labels phase: {len(label_specs())} labels, "
            f"{sum(1 for a in actions if a.kind == 'milestone')} milestone(s) from the open rows")
    return actions, note


def _plan_issues(opened: Sequence[dict[str, str]], batch_size: int, batches: int,
                 repo: str | None) -> tuple[list[Action], str]:
    """issues phase: up to `batches` batches of creates for open rows without a number, each after an issue list."""
    actions: list[Action] = []
    pending = [r for r in opened if _issue_number(r["issue"]) is None]
    chosen = _chunks(pending, batch_size)[:batches]
    planned = sum(len(c) for c in chosen)
    for k, chunk in enumerate(chosen):
        if k:
            actions.append(Action("pause", seconds=BATCH_PAUSE_S))
        actions.append(Action("list-issues", ("issue", "list", "--state", "all", "--limit",
                                              str(ISSUE_LIST_LIMIT), "--json", "number,title",
                                              *_repo_args(repo)), label="issue list"))
        for row in chunk:
            args = ["issue", "create", "--title", build_title(row), "--body-file", BODY_FILE_TOKEN,
                    "--label", f"area:{row['area']}", "--label", f"severity:{row['severity']}",
                    "--label", source_label(row), "--milestone", row["milestone"], *_repo_args(repo)]
            actions.append(Action("create-issue", tuple(args), row_id=row["id"], body=build_body(row),
                                  label=f"row {row['id']}"))
    note = (f"# issues phase: {len(opened)} open rows, {len(opened) - len(pending)} already numbered, "
            f"{len(pending)} pending; this run: {planned} row(s) in {len(chosen)} batch(es) of up to "
            f"{batch_size}; {len(pending) - planned} left for later")
    return actions, note


def _plan_priorities(opened: Sequence[dict[str, str]], batch_size: int, batches: int,
                     repo: str | None) -> tuple[list[Action], str]:
    """priorities phase: up to `batches` batches of label edits for open rows with an issue number and a priority.

    Nothing is written back, so a later run starts again at the first batch; the edits are idempotent, and the rest
    is reached with a larger `--batches`.
    """
    actions: list[Action] = []
    todo = [r for r in opened if _issue_number(r["issue"]) is not None and r["priority"] in PRIORITIES]
    chosen = _chunks(todo, batch_size)[:batches]
    planned = sum(len(c) for c in chosen)
    for k, chunk in enumerate(chosen):
        if k:
            actions.append(Action("pause", seconds=BATCH_PAUSE_S))
        for row in chunk:
            args = ["issue", "edit", str(_issue_number(row["issue"])), "--add-label", f"priority:{row['priority']}"]
            for other in PRIORITIES:
                if other != row["priority"]:
                    args += ["--remove-label", f"priority:{other}"]
            actions.append(Action("edit-priority", tuple(args) + _repo_args(repo), row_id=row["id"],
                                  label=f"row {row['id']}"))
    left = len(todo) - planned
    note = (f"# priorities phase: {len(todo)} issue(s) get a priority label; this run: {planned} in {len(chosen)} "
            f"batch(es) of up to {batch_size}; {left} left"
            + (" (re-run with a larger --batches: earlier batches are re-applied, which is harmless)" if left else "")
            + f"; {len(opened) - len(todo)} open row(s) skipped (no issue number yet or no priority)")
    return actions, note


def build_plan(rows: Sequence[dict[str, str]], phase: str, batch_size: int, batches: int,
               repo: str | None) -> Plan:
    """The single action plan of `phase` from the table; a dry run prints it, a real run executes it."""
    opened = [r for r in rows if r["status"] == "open"]
    notes: list[str] = []
    stray = [r["id"] for r in rows if r["status"] != "open" and r["issue"].strip()]
    if stray:
        notes.append(f"# WARNING: {len(stray)} row(s) that are not open carry an issue number (AC-5 expects none): "
                     + ", ".join(stray[:5]) + (" ..." if len(stray) > 5 else ""))
    if phase == "labels":
        actions, note = _plan_labels(opened, repo)
    elif phase == "issues":
        actions, note = _plan_issues(opened, batch_size, batches, repo)
    elif phase == "priorities":
        actions, note = _plan_priorities(opened, batch_size, batches, repo)
    else:
        raise PublishError(f"no plan for phase {phase!r}")
    notes.append(note)
    return Plan(phase, actions, notes)


# ----------------------------------------------------------------------------------------------- execution
def _display_path(path: Path | str) -> str:
    """A path for printing: relative to the repo root, else only the file name (no local path)."""
    path = Path(path)
    try:
        return path.resolve().relative_to(ROOT).as_posix()
    except (ValueError, OSError):
        return path.name


_ISSUE_URL_RE = re.compile(r"/issues/(\d+)")
_TITLE_ID_RE = re.compile(r"^\[([^\]\s]+)\] ")
_EXISTS_RE = re.compile(r"already_exists|already exists", re.I)


class Executor:
    """Runs a plan through a GhRunner; owns rate-limit waiting, adoption and the write-back of issue numbers."""

    def __init__(self, table_path: Path, runner: GhRunner, sleep: Callable[[float], None],
                 clock: Callable[[], float], say: Callable[[str], None]) -> None:
        """Store the injected collaborators."""
        self.table_path = table_path
        self.runner = runner
        self.sleep = sleep
        self.clock = clock
        self.say = say
        self.existing: dict[str, int] = {}
        self.counts = {"created": 0, "adopted": 0, "labels": 0, "milestones": 0, "edited": 0}

    def execute(self, plan: Plan) -> None:
        """Run every action of the plan in order; raises PublishError (or a subclass) on the first problem."""
        for action in plan.actions:
            if action.kind == "pause":
                self.say(action.display())
                self.sleep(action.seconds)
            elif action.kind == "list-issues":
                self.say(action.display())
                self._list_issues(action)
            elif action.kind == "create-issue":
                self._create(action)
            elif action.kind == "milestone":
                self.say(action.display())
                self._call(action.args, action, tolerate=_EXISTS_RE)
                self.counts["milestones"] += 1
            else:
                self.say(action.display())
                self._call(action.args, action)
                self.counts["labels" if action.kind == "label" else "edited"] += 1

    def _call(self, args: Sequence[str], action: Action, tolerate: re.Pattern | None = None) -> GhResult:
        """Run one gh call; wait out rate limits (backoff or server hint), raise on other failures."""
        attempt = 0
        while True:
            result = self.runner.run(args)
            if result.returncode == 0:
                return result
            if tolerate is not None and tolerate.search(result.stderr + result.stdout):
                self.say("#   already exists: treated as done")
                return result
            where = action.label or action.kind
            if not is_rate_limited(result):
                detail = redact((result.stderr or result.stdout).strip())[:600]
                hint = " (run `gh auth login` first)" if re.search(r"auth login|not logged in", detail, re.I) else ""
                raise PublishError(f"gh failed (exit {result.returncode}) at {where}: {detail}{hint}")
            if attempt >= MAX_RETRIES:
                raise RateLimitStop(f"rate limit: stopped after {MAX_RETRIES} failed retries at {where}")
            server = parse_server_wait(result, self.clock())
            wait = max(server or 0, BACKOFF_S[attempt])
            self.say(f"#   rate limit at {where}: waiting {wait:g} s (retry {attempt + 1} of {MAX_RETRIES})")
            self.sleep(wait)
            attempt += 1

    def _list_issues(self, action: Action) -> None:
        """Read the repo's issues and index the `[<id>] ` titles for adoption."""
        result = self._call(action.args, action)
        try:
            items = json.loads(result.stdout or "[]")
            index: dict[str, int] = {}
            for item in items:
                match = _TITLE_ID_RE.match(str(item["title"]))
                if match:
                    index[match.group(1)] = min(int(item["number"]), index.get(match.group(1), 1 << 60))
        except (ValueError, KeyError, TypeError) as exc:
            raise PublishError(f"gh issue list did not return the expected JSON: {exc}") from exc
        if len(items) >= ISSUE_LIST_LIMIT:
            raise PublishError(f"gh issue list returned {len(items)} issues, the {ISSUE_LIST_LIMIT} limit: the list "
                               "may be truncated, so adoption cannot be trusted; stopped before creating anything")
        self.existing = index
        self.say(f"#   {len(items)} issue(s) in the repo, {len(index)} with a [<id>] title")

    def _write_issue(self, row_id: str, number: int) -> None:
        """Write an issue number into its row; an OSError becomes a PublishError naming the resume."""
        try:
            set_issue(self.table_path, row_id, number, self.sleep)
        except OSError as exc:
            raise PublishError(f"could not write issue #{number} into row {row_id}: {exc}; the issue exists and "
                               "the next run adopts it by its [<id>] title") from exc

    def _create(self, action: Action) -> None:
        """Adopt an existing `[<id>]` issue or create one from a temp body file, then write its number."""
        number = self.existing.get(action.row_id)
        if number is not None:
            self._write_issue(action.row_id, number)
            self.counts["adopted"] += 1
            self.say(f"# adopt [{action.row_id}] -> #{number} (an issue with this id already exists; not created)")
            return
        self.say(action.display())
        with tempfile.TemporaryDirectory(prefix="findings-body-") as tmp:
            body_path = Path(tmp) / "body.md"
            body_path.write_text(action.body, encoding="utf-8", newline="\n")
            args = tuple(str(body_path) if a == BODY_FILE_TOKEN else a for a in action.args)
            result = self._call(args, action)
        found = _ISSUE_URL_RE.findall(result.stdout)
        if not found:
            raise PublishError(f"gh created an issue for {action.row_id} but printed no issue URL; the next run "
                               "adopts it by its [<id>] title")
        self._write_issue(action.row_id, int(found[-1]))
        self.counts["created"] += 1
        self.say(f"#   created #{found[-1]} for {action.row_id}")


# ----------------------------------------------------------------------------------------------- approval
def check_approval(table_path: Path, approval_path: Path) -> tuple[bool, str]:
    """(ok, message): does the approval file hold the table's current hash?"""
    shown = _display_path(approval_path)
    try:
        text = Path(approval_path).read_text(encoding="utf-8")
    except FileNotFoundError:
        return False, f"approval file {shown} is missing"
    except (OSError, UnicodeDecodeError) as exc:
        return False, f"approval file {shown} is unreadable: {exc}"
    token = ""
    for line in text.splitlines():
        line = line.strip()
        if line and not line.startswith("#"):
            token = line.split()[0]
            break
    token = re.sub(r"(?i)^sha-?256[:=]?", "", token).lower()
    if not re.fullmatch(r"[0-9a-f]{64}", token):
        return False, f"approval file {shown} does not hold a SHA-256"
    current = table_hash(table_path)
    if token != current:
        return False, (f"approval file {shown} holds a different hash than the table now has (table edited after "
                       f"approval; current hash {current}); a new approval is needed")
    return True, f"approval OK (table hash {current})"


# ----------------------------------------------------------------------------------------------- CLI
def _default_username() -> str:
    """The login name from USERNAME or USER, else getpass; empty when none is available."""
    for key in ("USERNAME", "USER"):
        if os.environ.get(key):
            return os.environ[key]
    try:
        return getpass.getuser()
    except Exception:  # noqa: BLE001 - no user name available
        return ""


def _default_home() -> str:
    """The home folder path from USERPROFILE (Windows) or HOME; empty when neither is set."""
    for key in ("USERPROFILE", "HOME"):
        if os.environ.get(key):
            return os.environ[key]
    return ""


def _parser() -> argparse.ArgumentParser:
    """The command-line parser."""
    parser = argparse.ArgumentParser(prog="publish_findings.py", description=__doc__.split("\n\n")[0])
    parser.add_argument("phase", choices=PHASES, help="labels | issues | priorities | hash")
    parser.add_argument("--table", default=str(DEFAULT_TABLE), help="findings CSV (default production/findings)")
    parser.add_argument("--approval", default=str(DEFAULT_APPROVAL), help="approval file holding the table hash")
    parser.add_argument("--dry-run", action="store_true", help="print the plan; call nothing")
    parser.add_argument("--batch-size", type=int, default=BATCH_SIZE, help=f"rows per batch (default {BATCH_SIZE})")
    parser.add_argument("--batches", type=int, default=1,
                        help="batches of issues or priority edits per invocation (default 1; a pause "
                             "separates batches)")
    parser.add_argument("--repo", default=None, help="OWNER/REPO (default: the repo of the current git remote)")
    parser.add_argument("--show-bodies", action="store_true", help="dry run: also print each issue body")
    return parser


def main(argv: Sequence[str] | None = None, *, runner: GhRunner | None = None,
         sleep: Callable[[float], None] = time.sleep, clock: Callable[[], float] = time.time,
         username: str | None = None, home: str | None = None, out: TextIO | None = None) -> int:
    """Run one phase. Injected: `runner` wraps gh, `sleep` and `clock` stand for time, `username` the Windows user,
    `home` the home folder path (default USERPROFILE or HOME; its basename is scanned for like the user name)."""
    out = out if out is not None else sys.stdout
    user = _default_username() if username is None else username
    home_dir = _default_home() if home is None else home
    masks = {str(ROOT): "<repo>", str(ROOT).replace("\\", "/"): "<repo>"}

    def say(text: str = "") -> None:
        """Print one line with the repo root masked as <repo>."""
        for raw, mask in masks.items():
            text = text.replace(raw, mask)
        print(text, file=out, flush=True)

    try:
        opts = _parser().parse_args(list(argv) if argv is not None else None)
    except SystemExit as exc:
        return int(exc.code) if isinstance(exc.code, int) else EXIT_REFUSED
    if opts.batch_size < 1 or opts.batches < 1:
        say("REFUSED: --batch-size and --batches must be at least 1")
        return EXIT_REFUSED
    table_path = Path(opts.table)
    try:
        return _run(opts, table_path, Path(opts.approval), runner or SubprocessGh(), sleep, clock, user,
                    home_dir, say)
    except PublishError as exc:
        label = "REFUSED" if isinstance(exc, Refused) else ("STOPPED" if isinstance(exc, RateLimitStop) else "ERROR")
        say(f"{label}: {exc}")
        if not isinstance(exc, Refused):
            _report_consistency(table_path, say)
        return exc.exit_code


def _report_consistency(table_path: Path, say: Callable[[str], None]) -> None:
    """Print how many open rows already hold an issue number (the resume point after a stop)."""
    try:
        rows = load_table(table_path).rows
    except PublishError as exc:
        say(f"table state unknown: {exc}")
        return
    opened = [r for r in rows if r["status"] == "open"]
    done = sum(1 for r in opened if _issue_number(r["issue"]) is not None)
    say(f"table consistent: {done} of {len(opened)} open rows hold an issue number; every number written so far is in "
        "the file; run the same command again to resume")


def _run(opts: argparse.Namespace, table_path: Path, approval_path: Path, runner: GhRunner,
         sleep: Callable[[float], None], clock: Callable[[], float], user: str, home: str,
         say: Callable[[str], None]) -> int:
    """Validate, scan and approve, then print (dry run) or execute the phase's plan; raises PublishError."""
    if opts.phase == "hash":
        say(table_hash(table_path))
        return EXIT_OK
    table = load_table(table_path)
    problems = validate_rows(table.rows)
    if problems:
        say(f"table check: FAIL ({len(problems)} problem(s))")
        for problem in problems[:50]:
            say(f"#   {problem}")
        raise Refused("the table is not valid for publishing; fix it and get a new approval")
    opened = [r for r in table.rows if r["status"] == "open"]
    mode = "DRY RUN (no gh call is made)" if opts.dry_run else "REAL RUN"
    say(f"# publish_findings {opts.phase}: {mode}; table {_display_path(table_path)}; {len(table.rows)} rows, "
        f"{len(opened)} open")
    scanned, hits = scan_rows(opened, user, home)
    say(f"# body scan: {scanned} issue title+body pair(s) checked; rules: {', '.join(SCAN_RULES)}")
    if hits:
        say(f"# body scan: FAIL ({len(hits)} hit(s); the matched text is not printed)")
        for hit in hits[:50]:
            say(f"#   {hit.row_id} {hit.field} line {hit.line} col {hit.column} len {hit.length} rule={hit.rule}")
        raise Refused("a title or body would publish a local path, a user name, an e-mail address or a token-like "
                      "string; fix the row and get a new approval")
    say("# body scan: PASS (0 hits)")
    approved, message = check_approval(table_path, approval_path)
    if opts.dry_run:
        say(f"# {message if approved else message + ' (a real run would refuse)'}")
    elif not approved:
        raise Refused(message)
    else:
        say(f"# {message}")
    plan = build_plan(table.rows, opts.phase, opts.batch_size, opts.batches, opts.repo)
    for note in plan.notes:
        say(note)
    if not plan.actions:
        say("# nothing to do")
        return EXIT_OK
    if opts.dry_run:
        for action in plan.actions:
            say(action.display())
            if opts.show_bodies and action.kind == "create-issue":
                for line in action.body.splitlines():
                    say(f"#| {line}")
        say(f"# dry run complete: {sum(1 for a in plan.actions if a.kind != 'pause')} call(s) planned, none made")
        return EXIT_OK
    executor = Executor(table_path, runner, sleep, clock, say)
    executor.execute(plan)
    c = executor.counts
    say(f"# done: created {c['created']}, adopted {c['adopted']}, labels {c['labels']}, milestones "
        f"{c['milestones']}, priority edits {c['edited']}")
    _report_consistency(table_path, say)
    return EXIT_OK


if __name__ == "__main__":
    for stream in (sys.stdout, sys.stderr):
        if hasattr(stream, "reconfigure"):
            stream.reconfigure(encoding="utf-8")
    sys.exit(main())
