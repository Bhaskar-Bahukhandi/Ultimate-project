"""Tests for check_findings.py (story Y1-P0-S05): mutated copies of the real table, register, changelog and
approval file are fed through the script's path arguments, and each planted fault must FAIL (or WARN by default
and FAIL under --strict) with its own message, while the real files PASS.

Run from the repo root:
    python -I -m unittest discover -s production/findings -v
"""

import contextlib
import csv
import io
import re
import shutil
import sys
import tempfile
import unittest
from pathlib import Path

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE))

import check_findings  # noqa: E402  (path set above; -I drops the script folder from sys.path)

REAL_CSV = HERE / "findings.csv"
REAL_REGISTER = check_findings.REGISTER
REAL_CHANGELOG = check_findings.CHANGELOG
REAL_APPROVAL = HERE / "publish-approval.txt"
# A made-up user name, so the windows-user rule is deterministic and independent of who runs the tests.
TEST_USER = ["--user-name", "Qzx Vremlo", "--home", "/home/qzxv"]


def run_check(*args):
    """Run check_findings.main with args; return (exit code, captured stdout)."""
    buf = io.StringIO()
    with contextlib.redirect_stdout(buf):
        code = check_findings.main(list(args) + TEST_USER)
    return code, buf.getvalue()


def read_rows():
    """Return (fieldnames, rows) of the real table."""
    with open(REAL_CSV, encoding="utf-8", newline="") as fh:
        reader = csv.DictReader(fh)
        return reader.fieldnames, list(reader)


def first(rows, **want):
    """Return the first row whose columns equal every given value."""
    return next(r for r in rows if all(r[k] == v for k, v in want.items()))


class CheckFindingsTest(unittest.TestCase):
    """Each test plants one fault in a temp copy and checks the script's verdict and message."""

    def setUp(self):
        """Make a temp folder; by default the approval check points at a file that does not exist there."""
        self.tmp = Path(tempfile.mkdtemp(prefix="check_findings_"))
        self.no_approval = str(self.tmp / "absent-approval.txt")

    def tearDown(self):
        """Remove the temp folder."""
        shutil.rmtree(self.tmp, ignore_errors=True)

    def table(self, mutate):
        """Write the real table, changed in place by mutate(rows), to the temp folder; return its path."""
        fields, rows = read_rows()
        mutate(rows)
        path = self.tmp / "findings.csv"
        with open(path, "w", encoding="utf-8", newline="") as fh:
            writer = csv.DictWriter(fh, fieldnames=fields, lineterminator="\n")
            writer.writeheader()
            writer.writerows(rows)
        return str(path)

    def text_copy(self, src, name, old_re, new):
        """Copy a text file to the temp folder with the first match of old_re replaced; return its path."""
        text = Path(src).read_text(encoding="utf-8")
        changed, n = re.subn(old_re, new, text, count=1, flags=re.M)
        self.assertEqual(n, 1, "fixture pattern %r not found in %s" % (old_re, src))
        path = self.tmp / name
        path.write_text(changed, encoding="utf-8", newline="")
        return str(path)

    def assert_fails(self, needle, *args):
        """Run with args and assert exit 1 with needle in the output."""
        code, out = run_check(*args, "--approval", self.no_approval) if "--approval" not in args \
            else run_check(*args)
        self.assertEqual(code, 1, out[-1500:])
        self.assertIn(needle, out)
        return out

    def assert_warns_then_strict_fails(self, needle, *args):
        """Default run: exit 0, a named WARNING holding needle, final line counting 1 warning; --strict: exit 1."""
        args = args + ("--approval", self.no_approval)
        code, out = run_check(*args)
        self.assertEqual(code, 0, out[-1500:])
        self.assertTrue(any(x.startswith("WARNING: ") and needle in x for x in out.splitlines()), out[-1500:])
        self.assertIn("1 warning(s)", out.strip().splitlines()[-1])
        code, out = run_check(*args, "--strict")
        self.assertEqual(code, 1, out[-1500:])
        self.assertIn(needle, out)

    # ------------------------------------------------------------------ real data
    def test_real_files_pass_with_no_warnings(self):
        """Today's table, register, changelog and approval pass, with and without --strict."""
        for extra in ([], ["--strict"]):
            code, out = run_check(*extra)
            self.assertEqual(code, 0, out[-1500:])
            last = out.strip().splitlines()[-1]
            self.assertTrue(last.startswith("PASS:"), last)
            self.assertIn("0 warning(s)", last)

    # ------------------------------------------------------------------ always-fail faults
    def test_repeated_id_fails(self):
        """A row that appears twice fails."""
        self.assert_fails("repeats", "--csv", self.table(lambda rows: rows.append(dict(first(rows, status="fixed")))))

    def test_off_list_area_fails(self):
        """An area that is not on the list fails."""
        self.assert_fails("area 'graphics' not on the list",
                          "--csv", self.table(lambda rows: rows[0].update(area="graphics")))

    def test_off_list_milestone_fails(self):
        """A milestone that is not on the list fails."""
        self.assert_fails("milestone 'Y9 Someday' not on the list",
                          "--csv", self.table(lambda rows: rows[0].update(milestone="Y9 Someday")))

    def test_bad_status_fails(self):
        """A status outside open/fixed/obsolete/duplicate fails."""
        self.assert_fails("status 'closed' not in",
                          "--csv", self.table(lambda rows: first(rows, status="fixed").update(status="closed")))

    def test_duplicate_of_nowhere_fails(self):
        """A duplicate_of naming no row fails."""
        self.assert_fails("duplicate_of 'CR-X99' names no other row", "--csv",
                          self.table(lambda rows: first(rows, status="duplicate").update(duplicate_of="CR-X99")))

    def test_id_gap_fails(self):
        """Removing a middle row of an id family leaves a gap and fails."""
        self.assert_fails("id family CR-V: numbers run to",
                          "--csv", self.table(lambda rows: rows.remove(first(rows, id="CR-V02"))))

    def test_source_count_mismatch_fails(self):
        """Removing the last row of a family (no gap) still fails on the section count."""
        def drop_last_v(rows):
            """Drop the highest-numbered CR-V row."""
            rows.remove(max((r for r in rows if r["id"].startswith("CR-V")), key=lambda r: r["id"]))
        out = self.assert_fails("review §5: source has", "--csv", self.table(drop_last_v))
        self.assertNotIn("id family CR-V", out)

    def test_planted_local_path_in_evidence_fails(self):
        """A local Windows path in an evidence cell fails the leak scan, and the text is not echoed."""
        def plant(rows):
            """Append a local path to the first fixed row's evidence."""
            row = first(rows, status="fixed")
            row["evidence"] += r"; log at C:\Users\someone\notes.txt"
        out = self.assert_fails("column evidence: local-path hit", "--csv", self.table(plant))
        self.assertNotIn("someone", out)

    def test_planted_user_name_part_fails(self):
        """A part of the (injected) user name in any cell fails the leak scan."""
        self.assert_fails("column code_refs: windows-user hit",
                          "--csv", self.table(lambda rows: rows[3].update(code_refs="see vremlo's notes")))

    def test_malformed_commit_hash_fails_without_strict(self):
        """A too-short hash after 'commit' fails even without --strict."""
        def plant(rows):
            """Cite a 5-character hash in a fixed row."""
            first(rows, status="fixed")["evidence"] += "; commit 12ab3"
        self.assert_fails("malformed commit hash '12ab3'", "--csv", self.table(plant))

    def test_open_row_without_issue_fails_after_publish(self):
        """Once issue numbers exist, an open row without one fails."""
        self.assert_fails("is open but has no issue number",
                          "--csv", self.table(lambda rows: first(rows, status="open").update(issue="")))

    def test_closed_row_with_issue_fails(self):
        """A non-open row that holds an issue number fails."""
        self.assert_fails("is fixed but has issue number",
                          "--csv", self.table(lambda rows: first(rows, status="fixed").update(issue="9999")))

    def test_table_before_publishing_passes_pairing(self):
        """With no issue number anywhere (and a register citing none), open rows without issues pass."""
        def blank(rows):
            """Empty every issue cell."""
            for r in rows:
                r["issue"] = ""
        register = self.tmp / "register.md"
        register.write_text(re.sub(r" ?GitHub #\d+", "", REAL_REGISTER.read_text(encoding="utf-8")),
                            encoding="utf-8", newline="")
        code, out = run_check("--csv", self.table(blank), "--register", str(register),
                              "--approval", self.no_approval)
        self.assertEqual(code, 0, out[-1500:])
        self.assertIn("no issue number yet", out)

    def test_register_issue_number_mismatch_fails(self):
        """An Open register row whose GitHub #N differs from the table's issue fails."""
        register = self.text_copy(REAL_REGISTER, "register.md",
                                  r"(^\|\s*TD-\d{3}\s*\|[^\n]*?GitHub #)\d+(?=[^\n]*\|\s*Open\s*\|)", r"\g<1>99999")
        self.assert_fails("cites GitHub #99999", "--register", register)

    def test_stale_approval_fails(self):
        """The real approval file no longer matches once any non-issue cell is edited."""
        approval = self.tmp / "publish-approval.txt"
        shutil.copyfile(REAL_APPROVAL, approval)
        table = self.table(lambda rows: rows[0].update(title=rows[0]["title"] + " (edited)"))
        self.assert_fails("does not equal the table's approval hash", "--csv", table, "--approval", str(approval))

    def test_approval_with_wrong_hash_fails(self):
        """An approval file whose first line is another hash fails against the real table."""
        approval = self.tmp / "publish-approval.txt"
        approval.write_text("0" * 64 + "\n", encoding="utf-8")
        self.assert_fails("does not equal the table's approval hash", "--approval", str(approval))

    # ------------------------------------------------------------------ soft checks (warn, fail with --strict)
    def test_unreachable_commit_warns_then_strict_fails(self):
        """A well-formed hash git cannot find is a WARNING by default and a failure with --strict."""
        def plant(rows):
            """Cite a commit that does not exist in this repo."""
            first(rows, status="fixed")["evidence"] += "; commit deadbee1"
        self.assert_warns_then_strict_fails("commit deadbee1 not found by git cat-file -e",
                                            "--csv", self.table(plant))

    def test_register_header_drift_warns_then_strict_fails(self):
        """A register header whose total disagrees with its body warns by default and fails with --strict."""
        text = REAL_REGISTER.read_text(encoding="utf-8")
        total = int(re.search(r"^Total items: (\d+)", text, re.M).group(1))
        register = self.text_copy(REAL_REGISTER, "register.md", r"^Total items: \d+", "Total items: %d" % (total + 1))
        self.assert_warns_then_strict_fails("register header says", "--register", register)

    def test_changelog_marker_missing_warns_not_assessed(self):
        """A changelog marker found 0 times warns, reports its section NOT ASSESSED, and fails with --strict."""
        changelog = self.text_copy(REAL_CHANGELOG, "CHANGELOG.md", r"^\*\*Seen, not yet fixed:\*\*$", "**Seen:**")
        self.assert_warns_then_strict_fails("changelog marker", "--changelog", changelog)
        _, out = run_check("--changelog", changelog, "--approval", self.no_approval)
        self.assertTrue(any("CL-1006-S" in x and "NOT ASSESSED" in x for x in out.splitlines()), out[-1500:])


if __name__ == "__main__":
    unittest.main()
