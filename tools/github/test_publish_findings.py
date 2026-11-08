"""Unit tests for publish_findings.py (story Y1-P0-S05, AC-4).

Run from the repo root:  python -I -m unittest discover -s tools/github -v

Every test is deterministic: `gh` is a stub that records its calls and returns scripted replies, `sleep` records the
requested waits instead of waiting, the clock is fixed, and the tables are built here by factory functions (the real
production/findings/findings.csv is never read). Nothing touches GitHub; no token is involved.
"""
from __future__ import annotations

import csv
import hashlib
import io
import json
import os
import subprocess
import tempfile
import unittest
from pathlib import Path
from unittest import mock

import publish_findings as pf

USER = "Test Winuser"          # injected Windows user name (not a real person)
HOME = "C:\\Users\\tw-home"     # injected USERPROFILE / HOME; its basename `tw-home` is scanned for
NOW = 1_700_000_000.0          # fixed clock
H40 = "f82daf2" + "0123456789abcdef0123456789abcdef0"[:33]   # a 40-character git hash (hex)
RATE_MSG = "gh: HTTP 403: You have exceeded a secondary rate limit. Please wait a few minutes."


# --------------------------------------------------------------------------------------------- factories
def make_row(i: int, **overrides: str) -> dict[str, str]:
    """One findings row with every column present; `overrides` replace columns."""
    row = {c: "" for c in pf.COLUMNS}
    row.update(
        id=f"CR-C{i:02d}", title=f"Finding number {i}",
        source=f"AethelgardPrototype/CODE_REVIEW_2026-10-04.md:{100 + i}", section="3 Critical",
        severity="critical", code_refs=f"AethelgardPrototype/scripts/core/thing_{i}.gd:{i}",
        area="save", milestone="Y1-P0 Stabilize", status="open",
        evidence="Not fixed at HEAD; the code at the ref was read.",
    )
    row.update(overrides)
    return row


def make_rows(n_open: int = 5, closed: bool = True) -> list[dict[str, str]]:
    """`n_open` open rows, then (optionally) one fixed, one obsolete, one duplicate row."""
    rows = [make_row(i) for i in range(1, n_open + 1)]
    if closed:
        rows += [
            make_row(90, status="fixed", evidence=f"commit {H40}", milestone="Y1-P1 Spine"),
            make_row(91, status="obsolete", evidence="commit abc1234", milestone="Y2-PP Pre-production"),
            make_row(92, status="duplicate", duplicate_of="CR-C01", milestone="Y1-P2 Combat foundation"),
        ]
    return rows


def csv_text(rows: list[dict[str, str]], newline: str = "\n") -> str:
    """The rows as CSV text in schema order (the factory form of a table file)."""
    buf = io.StringIO(newline="")
    writer = csv.writer(buf, lineterminator=newline)
    writer.writerow(pf.COLUMNS)
    for row in rows:
        writer.writerow([row[c] for c in pf.COLUMNS])
    return buf.getvalue()


def gh_lines(text: str) -> list[str]:
    """The `gh ...` call lines of a printed plan or run log."""
    return [line for line in text.splitlines() if line.startswith("gh ")]


class StubGh:
    """Stands in for the gh CLI. Records every call; replies are scripted or default to success."""

    def __init__(self, existing=(), script=None, first_number: int = 101, on_call=None):
        """`existing` is the issue list reply, `script(index, args)` may override a reply, `on_call` observes."""
        self.argvs: list[list[str]] = []
        self.lines: list[str] = []
        self.bodies: list[str | None] = []
        self.body_paths: list[str | None] = []
        self.existing = list(existing)
        self.script = script
        self.on_call = on_call
        self.next_number = first_number

    def run(self, args):
        """Record the call and return the scripted or default reply."""
        args = list(args)
        body = path = None
        if "--body-file" in args:
            path = args[args.index("--body-file") + 1]
            body = Path(path).read_text(encoding="utf-8")
        index = len(self.argvs)
        self.argvs.append(args)
        self.bodies.append(body)
        self.body_paths.append(path)
        self.lines.append(pf.render_call(args, body))
        if self.on_call:
            self.on_call(index, args)
        if self.script:
            reply = self.script(index, args)
            if reply is not None:
                return reply
        if args[:2] == ["issue", "list"]:
            return pf.GhResult(0, json.dumps(self.existing), "")
        if args[:2] == ["issue", "create"]:
            number, self.next_number = self.next_number, self.next_number + 1
            return pf.GhResult(0, f"https://github.com/o/r/issues/{number}\n", "")
        return pf.GhResult(0, "", "")

    def creates(self) -> list[list[str]]:
        """The recorded `gh issue create` calls."""
        return [a for a in self.argvs if a[:2] == ["issue", "create"]]


def title_of(args: list[str]) -> str:
    """The `--title` value of a recorded gh call."""
    return args[args.index("--title") + 1]


class CliCase(unittest.TestCase):
    """Base: a temp dir holding a table and an approval file, and helpers to drive pf.main."""

    def setUp(self) -> None:
        """Create the temp dir that holds the table and the approval file."""
        self._tmp = tempfile.TemporaryDirectory()
        self.addCleanup(self._tmp.cleanup)
        self.dir = Path(self._tmp.name)
        self.table = self.dir / "findings.csv"
        self.approval = self.dir / "publish-approval.txt"
        self.sleeps: list[float] = []

    def write_table(self, rows, newline: str = "\n") -> None:
        """Write `rows` to the temp table with the given line ending."""
        self.table.write_bytes(csv_text(rows, newline).encode("utf-8"))

    def approve(self) -> None:
        """Write the table's current hash into the approval file."""
        self.approval.write_text(pf.table_hash(self.table) + "\n", encoding="utf-8")

    def read_rows(self) -> list[dict[str, str]]:
        """Read the temp table back as dicts."""
        with open(self.table, encoding="utf-8", newline="") as fh:
            return list(csv.DictReader(fh))

    def cli(self, phase: str, *extra: str, dry: bool = False, stub: StubGh | None = None, username: str = USER,
            home: str = HOME):
        """Run the CLI against `stub`; returns (exit_code, printed_text)."""
        stub = stub if stub is not None else StubGh()
        out = io.StringIO()
        argv = [phase, "--table", str(self.table), "--approval", str(self.approval), *extra]
        if dry:
            argv.append("--dry-run")
        code = pf.main(argv, runner=stub, sleep=self.sleeps.append, clock=lambda: NOW, username=username,
                       home=home, out=out)
        return code, out.getvalue()


# --------------------------------------------------------------------------------------------- tests
class ConstantsTest(unittest.TestCase):
    def test_constants(self) -> None:
        self.assertEqual(pf.BATCH_SIZE, 50)
        self.assertEqual(pf.BATCH_PAUSE_S, 30)
        self.assertEqual(tuple(pf.BACKOFF_S), (60, 120, 240))
        self.assertEqual(pf.MAX_RETRIES, 3)

    def test_label_scheme(self) -> None:
        specs = pf.label_specs()
        names = [s[0] for s in specs]
        self.assertEqual(len(names), len(set(names)))
        for area in ("save", "input", "ui", "economy", "combat", "enemies", "encounters", "story", "regions",
                     "effects", "audio", "art", "tooling", "core"):
            self.assertIn(f"area:{area}", names)
        for sev in ("root-cause", "critical", "high", "medium-low", "audit-check", "pipeline", "tech-debt"):
            self.assertIn(f"severity:{sev}", names)
        for src in ("code-review", "changelog", "tech-debt"):
            self.assertIn(f"source:{src}", names)
        for p in ("P1", "P2", "P3", "P4"):
            self.assertIn(f"priority:{p}", names)
        self.assertEqual(len(names), 14 + 7 + 3 + 4)
        for name, color, description in specs:
            self.assertRegex(color, r"^[0-9a-fA-F]{6}$")
            self.assertLessEqual(len(description), 100)

    def test_title_and_body_format(self) -> None:
        row = make_row(1, code_refs="a/b.gd:1; c/d.gd:2", plan_task="Y1-P0-T01")
        self.assertEqual(pf.build_title(row), "[CR-C01] Finding number 1")
        body = pf.build_body(row)
        for needle in (row["source"], "a/b.gd:1", "c/d.gd:2", "critical", "Y1-P0 Stabilize", row["evidence"],
                       "Y1-P0-T01", "save"):
            self.assertIn(needle, body)


class HashTest(CliCase):
    def test_hash_ignores_issue_column_and_line_endings_but_not_content(self) -> None:
        rows = make_rows(3)
        self.write_table(rows)
        base = pf.table_hash(self.table)
        expected = hashlib.sha256(csv_text(rows).encode("utf-8")).hexdigest()
        self.assertEqual(base, expected)
        rows[0]["issue"] = "55"
        self.write_table(rows, "\r\n")
        self.assertEqual(pf.table_hash(self.table), base)
        rows[0]["title"] = "Edited after approval"
        self.write_table(rows)
        self.assertNotEqual(pf.table_hash(self.table), base)

    def test_hash_subcommand_prints_the_hash(self) -> None:
        self.write_table(make_rows(2))
        code, out = self.cli("hash")
        self.assertEqual(code, pf.EXIT_OK)
        self.assertEqual(out.strip(), pf.table_hash(self.table))


class DryRunTest(CliCase):
    def test_dry_run_calls_nothing_and_equals_real_issue_call_log(self) -> None:
        self.write_table(make_rows(4))
        self.approve()
        dry_stub = StubGh()
        code, dry_out = self.cli("issues", dry=True, stub=dry_stub)
        self.assertEqual(code, pf.EXIT_OK)
        self.assertEqual(dry_stub.argvs, [])
        self.assertEqual(self.sleeps, [])
        real_stub = StubGh()
        code, real_out = self.cli("issues", stub=real_stub)
        self.assertEqual(code, pf.EXIT_OK)
        self.assertEqual(len(real_stub.lines), 1 + 4)   # one issue list, four creates
        self.assertEqual(gh_lines(dry_out), real_stub.lines)
        self.assertEqual(gh_lines(real_out), real_stub.lines)

    def test_dry_run_equals_real_label_and_milestone_call_log(self) -> None:
        self.write_table(make_rows(3))
        self.approve()
        dry_stub = StubGh()
        _, dry_out = self.cli("labels", dry=True, stub=dry_stub)
        self.assertEqual(dry_stub.argvs, [])
        real_stub = StubGh()
        code, _ = self.cli("labels", stub=real_stub)
        self.assertEqual(code, pf.EXIT_OK)
        # all labels of the scheme, then the milestones of the open rows (here one)
        self.assertEqual(len(real_stub.lines), len(pf.label_specs()) + 1)
        self.assertEqual(gh_lines(dry_out), real_stub.lines)

    def test_dry_run_equals_real_priority_call_log(self) -> None:
        rows = make_rows(3)
        for n, row in enumerate(rows[:3]):
            row["issue"] = str(10 + n)
            row["priority"] = "P2"
        self.write_table(rows)
        self.approve()
        dry_stub = StubGh()
        _, dry_out = self.cli("priorities", dry=True, stub=dry_stub)
        self.assertEqual(dry_stub.argvs, [])
        real_stub = StubGh()
        code, _ = self.cli("priorities", stub=real_stub)
        self.assertEqual(code, pf.EXIT_OK)
        self.assertEqual(len(real_stub.lines), 3)
        self.assertEqual(gh_lines(dry_out), real_stub.lines)

    def test_dry_run_prints_scan_result_and_works_without_approval(self) -> None:
        self.write_table(make_rows(2))
        code, out = self.cli("issues", dry=True)       # no approval file exists
        self.assertEqual(code, pf.EXIT_OK)
        self.assertIn("body scan: PASS", out)
        self.assertIn("approval", out.lower())


class PlanTest(CliCase):
    def test_only_open_rows_are_planned(self) -> None:
        rows = make_rows(3)
        plan = pf.build_plan(rows, "issues", 50, 1, None)
        creates = [a.row_id for a in plan.actions if a.kind == "create-issue"]
        self.assertEqual(creates, ["CR-C01", "CR-C02", "CR-C03"])
        label_plan = pf.build_plan(rows, "labels", 50, 1, None)
        milestone_args = [a.args for a in label_plan.actions if a.kind == "milestone"]
        self.assertEqual(len(milestone_args), 1)
        self.assertIn("title=Y1-P0 Stabilize", milestone_args[0])

    def test_resume_skips_rows_with_an_issue_number(self) -> None:
        rows = make_rows(5, closed=False)
        rows[0]["issue"], rows[1]["issue"] = "11", "12"
        self.write_table(rows)
        self.approve()
        stub = StubGh()
        code, _ = self.cli("issues", stub=stub)
        self.assertEqual(code, pf.EXIT_OK)
        self.assertEqual([title_of(a).split("]")[0] for a in stub.creates()], ["[CR-C03", "[CR-C04", "[CR-C05"])
        after = self.read_rows()
        self.assertEqual([r["issue"] for r in after], ["11", "12", "101", "102", "103"])

    def test_non_open_rows_never_get_an_issue(self) -> None:
        self.write_table(make_rows(2))
        self.approve()
        code, _ = self.cli("issues", stub=StubGh())
        self.assertEqual(code, pf.EXIT_OK)
        by_status = {r["status"]: r["issue"] for r in self.read_rows() if r["status"] != "open"}
        self.assertEqual(by_status, {"fixed": "", "obsolete": "", "duplicate": ""})

    def test_batches(self) -> None:
        self.write_table([make_row(i, id=f"CR-X{i:03d}") for i in range(1, 121)])
        self.approve()
        stub = StubGh()
        self.assertEqual(self.cli("issues", stub=stub)[0], pf.EXIT_OK)    # default: ONE batch of 50
        self.assertEqual(len(stub.creates()), 50)
        self.assertEqual([a[:2] for a in stub.argvs].count(["issue", "list"]), 1)
        self.assertEqual(self.sleeps, [])
        stub = StubGh(first_number=500)
        self.assertEqual(self.cli("issues", "--batches", "3", stub=stub)[0], pf.EXIT_OK)
        self.assertEqual(len(stub.creates()), 70)          # 50 left in batch 2 + 20 in batch 3: resume after batch 1
        self.assertEqual([a[:2] for a in stub.argvs].count(["issue", "list"]), 2)
        self.assertEqual(self.sleeps, [30])
        self.assertTrue(all(r["issue"] for r in self.read_rows()))

    def test_batch_size_option_and_pause_between_batches(self) -> None:
        self.write_table(make_rows(5, closed=False))
        self.approve()
        stub = StubGh()
        self.assertEqual(self.cli("issues", "--batch-size", "2", "--batches", "3", stub=stub)[0], pf.EXIT_OK)
        self.assertEqual(len(stub.creates()), 5)
        self.assertEqual(self.sleeps, [pf.BATCH_PAUSE_S, pf.BATCH_PAUSE_S])

    def test_priorities_only_for_open_rows_with_an_issue_and_a_priority(self) -> None:
        rows = make_rows(4)
        rows[0].update(issue="11", priority="P1")
        rows[1].update(issue="12", priority="P3")
        rows[2].update(issue="", priority="P2")          # no issue yet: skipped
        rows[3].update(issue="14", priority="")          # no priority: skipped
        rows[4].update(issue="15", priority="P1")        # fixed row: skipped
        self.write_table(rows)
        self.approve()
        stub = StubGh()
        self.assertEqual(self.cli("priorities", stub=stub)[0], pf.EXIT_OK)
        self.assertEqual(len(stub.argvs), 2)
        first = stub.argvs[0]
        self.assertEqual(first[:5], ["issue", "edit", "11", "--add-label", "priority:P1"])
        for other in ("P2", "P3", "P4"):
            self.assertIn(f"priority:{other}", first)
        self.assertNotIn("--body-file", first)

    def test_priorities_pause_between_batches(self) -> None:
        rows = make_rows(5, closed=False)
        for n, row in enumerate(rows):
            row.update(issue=str(20 + n), priority="P4")
        self.write_table(rows)
        self.approve()
        self.assertEqual(self.cli("priorities", "--batch-size", "2", "--batches", "3")[0], pf.EXIT_OK)
        self.assertEqual(self.sleeps, [30, 30])

    def test_priorities_honour_batches_like_issues(self) -> None:
        rows = make_rows(5, closed=False)
        for n, row in enumerate(rows):
            row.update(issue=str(20 + n), priority="P3")
        self.write_table(rows)
        self.approve()
        stub = StubGh()
        code, out = self.cli("priorities", "--batch-size", "2", stub=stub)    # default: ONE batch
        self.assertEqual(code, pf.EXIT_OK)
        self.assertEqual([a[2] for a in stub.argvs], ["20", "21"])
        self.assertEqual(self.sleeps, [])
        self.assertIn("3 left", out)
        stub = StubGh()
        self.assertEqual(self.cli("priorities", "--batch-size", "2", "--batches", "2", stub=stub)[0], pf.EXIT_OK)
        self.assertEqual([a[2] for a in stub.argvs], ["20", "21", "22", "23"])
        self.assertEqual(self.sleeps, [30])


class AdoptTest(CliCase):
    def test_existing_id_title_is_adopted_not_created(self) -> None:
        self.write_table(make_rows(4, closed=False))
        self.approve()
        existing = [{"number": 77, "title": "[CR-C02] Finding number 2"},
                    {"number": 78, "title": "[CR-C030] a different id with the same start"}]
        stub = StubGh(existing=existing)
        code, out = self.cli("issues", stub=stub)
        self.assertEqual(code, pf.EXIT_OK)
        created = [title_of(a) for a in stub.creates()]
        self.assertEqual(len(created), 3)
        self.assertNotIn("[CR-C02] Finding number 2", created)
        self.assertIn("[CR-C03] Finding number 3", created)       # [CR-C030] must not capture CR-C03
        self.assertEqual([r["issue"] for r in self.read_rows()], ["101", "77", "102", "103"])
        self.assertIn("adopt", out)

    def test_truncated_issue_list_is_not_trusted(self) -> None:
        self.write_table(make_rows(2, closed=False))
        self.approve()
        full = [{"number": n, "title": f"[ZZ-{n}] other"} for n in range(1, 1001)]
        stub = StubGh(existing=full)
        code, out = self.cli("issues", stub=stub)
        self.assertEqual(code, pf.EXIT_ERROR)
        self.assertEqual(stub.creates(), [])
        self.assertIn("1000", out)


class WriteBackTest(CliCase):
    def test_number_is_written_right_after_each_create_and_adopt(self) -> None:
        self.write_table(make_rows(4, closed=False))
        self.approve()
        seen: list[list[str]] = []

        def on_call(index: int, args: list[str]) -> None:
            """Record the issue column at each create."""
            if args[:2] == ["issue", "create"]:
                seen.append([r["issue"] for r in self.read_rows()])

        stub = StubGh(existing=[{"number": 77, "title": "[CR-C02] x"}], on_call=on_call)
        self.assertEqual(self.cli("issues", stub=stub)[0], pf.EXIT_OK)
        # at each create the numbers of everything handled before it are already in the file
        self.assertEqual(seen, [["", "", "", ""], ["101", "77", "", ""], ["101", "77", "102", ""]])

    def test_write_is_atomic_and_keeps_crlf_unicode_and_other_columns(self) -> None:
        rows = make_rows(2, closed=False)
        rows[0]["title"] = "Gr\u00f6\u00dfe \u2014 \u65e5\u672c\u8a9e, with \"quotes\" and, commas"
        self.write_table(rows, "\r\n")
        self.approve()
        self.assertEqual(self.cli("issues", stub=StubGh())[0], pf.EXIT_OK)
        raw = self.table.read_bytes()
        self.assertFalse(raw.startswith(b"\xef\xbb\xbf"))
        self.assertNotIn(b"\n", raw.replace(b"\r\n", b""))
        after = self.read_rows()
        self.assertEqual(after[0]["title"], rows[0]["title"])
        for before, now in zip(rows, after):
            self.assertEqual({k: v for k, v in before.items() if k != "issue"},
                             {k: v for k, v in now.items() if k != "issue"})
        self.assertEqual(sorted(p.name for p in self.dir.iterdir()), ["findings.csv", "publish-approval.txt"])

    def test_failed_replace_leaves_table_untouched_and_no_temp_file(self) -> None:
        self.write_table(make_rows(2, closed=False))
        self.approve()
        before = self.table.read_bytes()
        with mock.patch("publish_findings.os.replace", side_effect=OSError("disk says no")):
            code, _ = self.cli("issues", stub=StubGh())
        self.assertEqual(code, pf.EXIT_ERROR)
        self.assertEqual(self.table.read_bytes(), before)
        self.assertEqual(sorted(p.name for p in self.dir.iterdir()), ["findings.csv", "publish-approval.txt"])

    def test_body_goes_through_body_file_not_the_command_line(self) -> None:
        nasty = 'He said "no"; `tick` $HOME %PATH% & | > < \'single\' \u00e9\u4e2d\nsecond line'
        rows = make_rows(1, closed=False)
        rows[0]["evidence"] = nasty
        self.write_table(rows)
        self.approve()
        stub = StubGh()
        self.assertEqual(self.cli("issues", stub=stub)[0], pf.EXIT_OK)
        create = stub.creates()[0]
        for flag in ("--body", "-b"):
            self.assertNotIn(flag, create)
        self.assertIn("--body-file", create)
        index = stub.argvs.index(create)
        self.assertEqual(stub.bodies[index], pf.build_body(rows[0]))
        self.assertIn(nasty, stub.bodies[index])
        self.assertFalse(Path(stub.body_paths[index]).exists())      # temp file is removed
        self.assertNotIn(nasty, " ".join(create))


class RateLimitTest(CliCase):
    @staticmethod
    def limit_on(row_id: str, times: int, message: str = RATE_MSG):
        """A stub script that answers the create of `row_id` with a rate-limit reply `times` times."""
        state = {"left": times}

        def script(index: int, args: list[str]):
            """Scripted gh reply for one call (None: the stub's default)."""
            if args[:2] == ["issue", "create"] and title_of(args).startswith(f"[{row_id}] ") and state["left"] > 0:
                state["left"] -= 1
                return pf.GhResult(1, "", message)
            return None
        return script

    def test_rate_limit_waits_the_backoff_then_continues(self) -> None:
        self.write_table(make_rows(4, closed=False))
        self.approve()
        stub = StubGh(script=self.limit_on("CR-C02", 1))
        code, out = self.cli("issues", stub=stub)
        self.assertEqual(code, pf.EXIT_OK)
        self.assertEqual(self.sleeps, [60])
        self.assertEqual([r["issue"] for r in self.read_rows()], ["101", "102", "103", "104"])
        self.assertEqual(len(stub.creates()), 5)           # CR-C02 was tried twice
        self.assertIn("rate limit", out.lower())

    def test_second_consecutive_limit_waits_longer(self) -> None:
        self.write_table(make_rows(2, closed=False))
        self.approve()
        stub = StubGh(script=self.limit_on("CR-C01", 2))
        self.assertEqual(self.cli("issues", stub=stub)[0], pf.EXIT_OK)
        self.assertEqual(self.sleeps, [60, 120])

    def test_wait_is_the_longer_of_retry_after_and_backoff(self) -> None:
        cases = [("Retry-After: 90", 90), ("Retry-After: 10", 60), ("retry-after: 500", 500),
                 (f"X-RateLimit-Reset: {int(NOW) + 300}", 300), ("no hint at all", 60)]
        for hint, expected in cases:
            with self.subTest(hint=hint):
                self.sleeps.clear()
                self.write_table(make_rows(1, closed=False))
                self.approve()
                stub = StubGh(script=self.limit_on("CR-C01", 1, f"{RATE_MSG} {hint}"))
                self.assertEqual(self.cli("issues", stub=stub)[0], pf.EXIT_OK)
                self.assertEqual(self.sleeps, [expected])

    def test_stop_after_three_failed_retries_leaves_the_table_consistent(self) -> None:
        rows = make_rows(5, closed=False)
        self.write_table(rows)
        self.approve()
        stub = StubGh(script=self.limit_on("CR-C03", 99))
        code, out = self.cli("issues", stub=stub)
        self.assertEqual(code, pf.EXIT_RATE_LIMIT)
        self.assertEqual(self.sleeps, [60, 120, 240])
        attempts = [a for a in stub.creates() if title_of(a).startswith("[CR-C03] ")]
        self.assertEqual(len(attempts), 4)                 # first try + 3 retries
        self.assertEqual(len(stub.creates()), 6)           # CR-C01, CR-C02 and the 4 attempts; nothing after
        self.assertIn("CR-C03", out)
        self.assertIn("stopped", out.lower())
        after = self.read_rows()
        self.assertEqual([r["issue"] for r in after], ["101", "102", "", "", ""])
        for before, now in zip(rows, after):
            self.assertEqual({k: v for k, v in before.items() if k != "issue"},
                             {k: v for k, v in now.items() if k != "issue"})
        # the table is the resume point: approval still valid, the next run starts at CR-C03
        stub2 = StubGh(first_number=103)
        self.assertEqual(self.cli("issues", "--batch-size", "10", stub=stub2)[0], pf.EXIT_OK)
        self.assertEqual([title_of(a)[:8] for a in stub2.creates()], ["[CR-C03]", "[CR-C04]", "[CR-C05]"])
        self.assertEqual([r["issue"] for r in self.read_rows()], ["101", "102", "103", "104", "105"])

    def test_other_failures_are_not_retried(self) -> None:
        self.write_table(make_rows(3, closed=False))
        self.approve()
        bad = self.limit_on("CR-C02", 99, "gh: HTTP 422: Validation Failed (label not found)")
        stub = StubGh(script=bad)
        code, out = self.cli("issues", stub=stub)
        self.assertEqual(code, pf.EXIT_ERROR)
        self.assertEqual(self.sleeps, [])
        self.assertEqual(len(stub.creates()), 2)
        self.assertIn("Validation Failed", out)
        self.assertEqual([r["issue"] for r in self.read_rows()], ["101", "", ""])

    def test_plain_403_is_not_a_rate_limit(self) -> None:
        self.assertFalse(pf.is_rate_limited(pf.GhResult(1, "", "gh: HTTP 403: Resource not accessible")))

    def test_rate_limit_detection(self) -> None:
        yes = ["API rate limit exceeded for user ID 1", "You have exceeded a secondary rate limit",
               "gh: HTTP 429: Too Many Requests", "HTTP 403: abuse detection mechanism", "Retry-After: 12",
               "gh: HTTP 403: API Rate Limit Exceeded"]
        for text in yes:
            with self.subTest(text=text):
                self.assertTrue(pf.is_rate_limited(pf.GhResult(1, "", text)))
        self.assertFalse(pf.is_rate_limited(pf.GhResult(0, "", "rate limit")))     # exit code 0 is success
        self.assertFalse(pf.is_rate_limited(pf.GhResult(1, "", "HTTP 404: Not Found")))
        self.assertFalse(pf.is_rate_limited(pf.GhResult(1, "", "issue #429 not found")))

    def test_parse_server_wait(self) -> None:
        cases = [("Retry-After: 120", 120), ("retry after 45 seconds", 45), ("try again in 2 minutes", 120),
                 (f"x-ratelimit-reset: {int(NOW) + 61}", 61), (f"x-ratelimit-reset: {int(NOW) - 5}", 0)]
        for text, expected in cases:
            with self.subTest(text=text):
                self.assertEqual(pf.parse_server_wait(pf.GhResult(1, "", text), NOW), expected)
        self.assertIsNone(pf.parse_server_wait(pf.GhResult(1, "", "nothing here"), NOW))

    def test_existing_milestone_is_tolerated(self) -> None:
        self.write_table(make_rows(2))
        self.approve()

        def script(index: int, args: list[str]):
            """Scripted gh reply for one call (None: the stub's default)."""
            if args[0] == "api":
                return pf.GhResult(1, "", 'gh: Validation Failed (HTTP 422) {"code":"already_exists"}')
            return None
        code, _ = self.cli("labels", stub=StubGh(script=script))
        self.assertEqual(code, pf.EXIT_OK)


class ApprovalTest(CliCase):
    def test_missing_approval_refuses_before_any_call(self) -> None:
        self.write_table(make_rows(3))
        for phase in ("labels", "issues", "priorities"):
            with self.subTest(phase=phase):
                stub = StubGh()
                code, out = self.cli(phase, stub=stub)
                self.assertEqual(code, pf.EXIT_REFUSED)
                self.assertEqual(stub.argvs, [])
                self.assertIn("approval", out.lower())

    def test_stale_approval_refuses(self) -> None:
        rows = make_rows(3)
        self.write_table(rows)
        self.approve()
        rows[1]["title"] = "Edited after the user approved the table"
        self.write_table(rows)
        stub = StubGh()
        code, out = self.cli("issues", stub=stub)
        self.assertEqual(code, pf.EXIT_REFUSED)
        self.assertEqual(stub.argvs, [])
        self.assertIn("approval", out.lower())

    def test_garbage_approval_refuses(self) -> None:
        self.write_table(make_rows(3))
        self.approval.write_text("looks approved to me\n", encoding="utf-8")
        stub = StubGh()
        self.assertEqual(self.cli("issues", stub=stub)[0], pf.EXIT_REFUSED)
        self.assertEqual(stub.argvs, [])

    def test_approval_survives_the_scripts_own_issue_write_backs(self) -> None:
        self.write_table(make_rows(5, closed=False))
        self.approve()
        for expected_total in (2, 4, 5):          # three invocations, each ONE batch of 2
            code, _ = self.cli("issues", "--batch-size", "2", stub=StubGh(first_number=100 + expected_total))
            self.assertEqual(code, pf.EXIT_OK)
            self.assertEqual(sum(1 for r in self.read_rows() if r["issue"]), expected_total)

    def test_approval_file_accepts_sha256sum_style_line(self) -> None:
        self.write_table(make_rows(2))
        self.approval.write_text(f"# approved by the user\n{pf.table_hash(self.table).upper()}  findings.csv\n",
                                 encoding="utf-8")
        self.assertEqual(self.cli("labels")[0], pf.EXIT_OK)

    def test_invalid_table_refuses(self) -> None:
        for field, value in (("area", "gameplay"), ("status", "wontfix"), ("severity", "blocker"),
                             ("milestone", ""), ("issue", "abc"), ("priority", "P9")):
            with self.subTest(field=field):
                rows = make_rows(3)
                rows[1][field] = value
                self.write_table(rows)
                self.approve()
                stub = StubGh()
                code, out = self.cli("issues", stub=stub)
                self.assertEqual(code, pf.EXIT_REFUSED)
                self.assertEqual(stub.argvs, [])
                self.assertIn("CR-C02", out)

    def test_duplicate_id_refuses(self) -> None:
        rows = make_rows(2)
        rows[1]["id"] = rows[0]["id"]
        self.write_table(rows)
        self.approve()
        self.assertEqual(self.cli("issues")[0], pf.EXIT_REFUSED)


class ScanTest(CliCase):
    SECRETS = {
        "windows path": "see C:\\Users\\Someone\\project\\x.gd for details",
        "windows path forward slashes": "see C:/Users/Someone/project/x.gd",
        "mac path": "see /Users/someone/project/x.gd",
        "windows user name": f"seen on the machine of {USER.lower()} yesterday",
        "e-mail": "ask dev.person@example.com about it",
        "ghp token": "token ghp_" + "A1b2C3d4E5" * 4,
        "fine-grained token": "token github_pat_" + "A1b2C3d4E5" * 4,
        "40-hex without commit": "see 0123456789abcdef0123456789abcdef01234567 for it",
        "64-hex": "digest " + "ab12" * 16,
        "base64 run": "key aGVsbG8gd29ybGQgdGhpcyBpcyBhIHNlY3JldDE2Mzc4OTA0NTY3ODkw",
        "hash on another line than the word commit": f"commit abc1234\n{H40}",
        "64-hex after commit": "commit " + "ab12" * 16,
        "40-hex after commit": f"fixed in commit {H40}",
        "40-hex among short commit hashes": f"commits abc1234, {H40} and 1234567",
        "wsl path": "see /mnt/c/Users/bob/project/x.gd",
        "unc path": "see \\\\host\\C$\\Users\\bob\\x.gd",
        "path without drive": "copied from Users\\bob\\Desktop\\x.gd",
        "lower-case windows path": "see d:\\users\\bob\\x.gd",
        "linux home": "see /home/bob/project/x.gd",
        "first part of the user name": "ask Test about it",
        "last part of the user name": "ask WINUSER about it",
        "home folder name": "found under tw-home earlier",
        "aws access key": "key AKIA" + "ABCDEFGHIJ234567",
        "anthropic key": "key sk-ant-api03-" + "Ab1_" * 5,
        "40+ lower-case run": "id " + "abcdefghij0123456789" * 2 + "k",
        "40+ upper-case run": "id " + "ABCDEFGHIJKLMNOPQRSTUVWXYZ" * 2,
    }

    def test_planted_secret_refuses_in_dry_and_real_runs(self) -> None:
        for label, planted in self.SECRETS.items():
            for field in ("evidence", "title"):
                with self.subTest(case=label, field=field):
                    if field == "title" and "\n" in planted:
                        continue
                    rows = make_rows(3)
                    rows[1][field] = planted
                    self.write_table(rows)
                    self.approve()
                    for dry in (True, False):
                        stub = StubGh()
                        code, out = self.cli("issues", dry=dry, stub=stub)
                        self.assertEqual(code, pf.EXIT_REFUSED)
                        self.assertEqual(stub.argvs, [])
                        self.assertIn("body scan: FAIL", out)
                        self.assertIn("CR-C02", out)
                        self.assertEqual(gh_lines(out), [])       # no plan is printed for a refused table
                        # the printed result locates the hit but never repeats the secret
                        for fragment in ("Someone", "dev.person", "ghp_", "github_pat_", "0123456789abcdef",
                                         "aGVsbG8", "bob", "WINUSER", "tw-home", "AKIA", "sk-ant",
                                         "abcdefghij", "ABCDEFGHIJ", "f82daf2"):
                            self.assertNotIn(fragment, out)

    def test_secret_in_any_phase_refuses_before_the_first_call(self) -> None:
        rows = make_rows(2)
        rows[0]["evidence"] = "mail me: someone@example.com"
        self.write_table(rows)
        self.approve()
        for phase in ("labels", "priorities"):
            with self.subTest(phase=phase):
                stub = StubGh()
                self.assertEqual(self.cli(phase, stub=stub)[0], pf.EXIT_REFUSED)
                self.assertEqual(stub.argvs, [])

    def test_clean_text_is_not_flagged(self) -> None:
        clean = [
            "commits abc1234, f82daf2 and 1234567",
            "commit abc1234",
            "Commit `a144ad2`",
            "AethelgardPrototype/scripts/ui/MainMenu2.gd:120",
            "res://assets/art_sources/oakhaven_village_background_layer_far_01.png",
            "docs/art_pipeline/real_comfyui_generation_requirements.md",
            "@export var speed := 4  # @onready",
            "https://github.com/Bhaskar-Bahukhandi/Ultimate-project/issues",
            "highs_score and ghost_mode",
            "Y1-P0 Stabilize",
            "AethelgardPrototype/scripts/combat/EnemyAttackPatternController/phase_two_helper.gd",
            "the Users folder and UserSettings/x.cfg",
            "https://example.com/home/page/ and res://home/menu/",
            "id " + ("abcdefghij0123456789" * 2)[:39],          # 39 characters: below the long-run limit
            "AKIA alone and sk-ant mentioned in prose",
        ]
        for text in clean:
            with self.subTest(text=text):
                self.assertEqual(pf.scan_text(text, USER, HOME), [])

    def test_scan_rules_are_named(self) -> None:
        rules = {}
        for label, planted in self.SECRETS.items():
            rules[label] = {hit[0] for hit in pf.scan_text(planted, USER, HOME)}
            self.assertTrue(rules[label], label)
        self.assertIn("local-path", rules["windows path"])
        self.assertIn("local-path", rules["mac path"])
        self.assertIn("windows-user", rules["windows user name"])
        self.assertIn("email", rules["e-mail"])
        self.assertIn("token-prefix", rules["ghp token"])
        self.assertIn("token-prefix", rules["fine-grained token"])
        self.assertIn("hex-run", rules["40-hex without commit"])
        self.assertIn("hex-run", rules["40-hex after commit"])
        for label in ("wsl path", "unc path", "path without drive", "lower-case windows path", "linux home"):
            self.assertIn("local-path", rules[label], label)
        for label in ("first part of the user name", "last part of the user name", "home folder name"):
            self.assertIn("windows-user", rules[label], label)
        self.assertIn("token-prefix", rules["aws access key"])
        self.assertIn("token-prefix", rules["anthropic key"])
        self.assertIn("base64-run", rules["40+ lower-case run"])
        self.assertIn("base64-run", rules["40+ upper-case run"])

    def test_user_name_parts_shorter_than_three_are_ignored(self) -> None:
        self.assertEqual(pf.scan_text("Ab and Ox went home", "Ab Ox"), [])
        self.assertEqual([h[0] for h in pf.scan_text("ask ab ox", "Ab Ox")], ["windows-user"])

    def test_home_folder_name_is_read_from_the_environment_when_not_injected(self) -> None:
        rows = make_rows(2)
        rows[0]["evidence"] = "seen under envhome on the build box"
        self.write_table(rows)
        out = io.StringIO()
        argv = ["issues", "--table", str(self.table), "--approval", str(self.approval), "--dry-run"]
        env = {"USERPROFILE": "C:\\Users\\envhome", "HOME": "/home/envhome"}
        with mock.patch.dict(os.environ, env):
            code = pf.main(argv, runner=StubGh(), sleep=self.sleeps.append, clock=lambda: NOW, username="",
                           out=out)
        self.assertEqual(code, pf.EXIT_REFUSED)
        self.assertIn("rule=windows-user", out.getvalue())
        self.assertNotIn("envhome", out.getvalue())

    def test_an_empty_user_name_does_not_flag_everything(self) -> None:
        self.assertEqual(pf.scan_text("ordinary text", ""), [])


class SubprocessGhTest(unittest.TestCase):
    def test_runs_gh_without_a_shell_and_without_reading_a_token(self) -> None:
        done = subprocess.CompletedProcess(["gh"], 0, stdout="ok", stderr="")
        with mock.patch("publish_findings.subprocess.run", return_value=done) as run:
            result = pf.SubprocessGh().run(["issue", "list", "--state", "all"])
        args, kwargs = run.call_args
        self.assertEqual(args[0], ["gh", "issue", "list", "--state", "all"])
        self.assertFalse(kwargs.get("shell", False))
        self.assertEqual(kwargs.get("stdin"), subprocess.DEVNULL)
        self.assertEqual((result.returncode, result.stdout), (0, "ok"))

    def test_missing_gh_is_a_clear_result_not_a_crash(self) -> None:
        with mock.patch("publish_findings.subprocess.run", side_effect=FileNotFoundError()):
            result = pf.SubprocessGh().run(["issue", "list"])
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("gh", result.stderr)


if __name__ == "__main__":
    unittest.main()
