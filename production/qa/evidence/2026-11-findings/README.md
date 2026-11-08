# Y1-P0-S05 evidence: review findings and open tech debt as GitHub Issues

Story: `production/epics/y1-p0-stabilize/story-s05-review-findings-issues.md`. Table:
`production/findings/findings.csv`. Tools: `production/findings/extract_findings.py` (one-time bootstrap),
`production/findings/check_findings.py` (reconciliation), `tools/github/publish_findings.py` (+ its tests).
Everything below ran locally on Windows, Python 3.13, 2026-11-07..08. Published to GitHub on 2026-11-08 (28 labels,
7 milestones, issues #2-#173), each step after the user's OK.

## AC map

| AC | What shows it | Where |
|---|---|---|
| AC-1 one table | 265 rows (258 at first; TD-048..054 added on the second approval); per-section source count = row count (counted independently of the extractor); 5 appendix bullets split a/b; ids unique; area and milestone on their lists; register header corrected to its body (47 rows, 38 open; now 54 rows, 45 open) | `check_skeleton.log`, `check_merged.log`, `check_watched_failure.log` |
| AC-2 status from evidence | open 172, fixed 87, duplicate 6; every cited commit exists, every cited story Complete, every `duplicate_of` resolves; seeded hand check of 20 fixed rows, then a strict re-check of the other 75 (see below) | `status_parts/part1..5.csv`, `hand_check_sample.txt`, `hand_check_20_a.md`, `hand_check_20_b.md`, `recheck_1..4.md`, `check_merged.log` |
| AC-3 scheme approved | the user's approval (below); `production/findings/publish-approval.txt` holds the table's hash | this README; `publish-approval.txt` |
| AC-4 publish script | 48 unit tests against a stubbed `gh` (45 first, watched failing 45 of 45 on stubs; 3 added in the code review, the new scan cases watched failing first); dry runs of the labels and issues phases on the final table (265 rows, body scan 0 hits, approval OK) | `unittest_first_fail.log`, `unittest_pass.log`, `review_fix_first_fail.log`, `review_fix_pass.log`, `dryrun_labels.log`, `dryrun_issues.log` |
| AC-5 published | 28 labels, 7 milestones, issues #2-#173 (one per open row), each batch after the user's OK; `api_check.py` (public API, PRs excluded): 15/15 PASS — one issue per open row, `[id]` unique, none closed, milestones and labels match, per-milestone counts match | `publish_labels.log`, `publish_batch1..4.log`, `api_check.py`, `api_check.log`, `api_issues.json`, `api_milestones.json` |
| AC-6 linked and triaged | Y1-P0 priorities proposed and approved (P1 #39; P2 #8 #9 #50 #53 #55 #56; P3 #51 #52 #54 #57 #58; P4 #59 #119-#124), labels set and checked on the API (19 issues, one priority label each); ROADMAP §11 (20 rows) and the register (45 open TD rows) carry the issue numbers; `plan_task` column links rows to plan tasks; issue forms `bug.yml`, `playtest.yml`, `config.yml` | `publish_priorities.log`, `AethelgardPrototype/ROADMAP_10_YEAR.md`, `docs/tech-debt-register.md`, `.github/ISSUE_TEMPLATE/` |
| AC-7 evidence and CI | this folder; CI step "Findings table and publish script" runs `check_findings.py` and both unit suites (green on CI #62, below). After the /story-done gates, `check_findings.py` gained `--strict` (unreachable commit hashes, register-header drift and changelog-marker counts are warnings by default so ordinary doc edits or a squash merge cannot turn CI red; each warning is printed by name) and always-on offline checks: a leak scan of every cell, open-row/issue pairing, register `#N` = table issue, approval hash = table; 20 tests of its own, watched failing first | `.github/workflows/ci.yml`, `production/findings/test_check_findings.py`, `check_tests_first_fail.log`, `check_tests_pass.log`, `check_merged.log` |

## Status checking (AC-2)

- Five agents checked their sections (`status_parts/BRIEF.md`): part 1 R/C/§5/changelog, part 2 highs and PAE, part 3
  appendix core/ui/combat/enemies/encounters, part 4 the other appendix groups, part 5 the TD rows. Merged
  2026-11-08; three rows the parts called fixed while saying part of the defect remained (CR-H4.4-06, CR-H4.5-09,
  CR-H4.7-07) were set to open by the merge rule.
- **Hand check** (seed 20261108, 20 of the 95 fixed rows): 15 CONFIRMED, 5 PARTIAL (CR-C12, CR-H4.6-03, CR-H4.7-03,
  CR-R4, CR-A-ui-03), 0 WRONG. The five were set to open. A 25% miss rate meant a wrong "fixed" row would lose a
  finding (fixed rows get no issue), so the user chose a strict re-check of every other fixed row instead of the
  story's single re-draw.
- **Strict re-check** of the other 75 fixed rows (every part of the stated defect gone in today's code, every named
  region checked): 72 CONFIRMED, 3 PARTIAL (CR-A-tooling-05, CL-1004-D2, CL-1004-D3), set to open. Every fixed row
  in the table has now been confirmed by a second reader: 87 rows.
- `check_findings.py` fix during the merge: its hash pattern required a letter, so all-digit short hashes
  (`5411533`) were missed; a hash written after "commit" is now accepted.

## Approval (AC-3)

- **2026-11-08, the user: "Approve as is"** — the findings table (258 rows: 165 open, 87 fixed, 6 duplicate), the
  7-milestone map (Y1-P0 19, Y1-P1 20, Y1-P2 44, Y1-P3 30, Y1-P4 3, Y2-PP 11, Backlog 38 open issues) and the 28
  labels (14 `area:*`, 7 `severity:*`, 3 `source:*`, `priority:P1..P4`).
- Approved table hash: `2dad25ce451e47d74df080ccc388516e664b50c239699ce3a98aab613e14306e`
  (`publish_findings.py hash`: SHA-256 of the table with the `issue` column emptied, so the hash survives the
  script writing issue numbers back). Any other edit to the table needs a new approval; the script refuses a real
  run on a stale hash.
- **2026-11-08, the user: "Approve additions"** — TD-048..TD-054 (the new findings below) added to the register
  and the table: 265 rows, 172 open (Backlog now 45), 87 fixed, 6 duplicate. New approved hash:
  `6be5f0759a56ee892dedee8bc124fb4d7fa893ce571832ca397c97a3bd32b9e9` (the first hash went stale on that edit and the
  script refused it, as designed).
- **2026-11-08, the user: "Approve as proposed"** — the 19 Y1-P0 priorities (P1 #39; P2 #8 #9 #50 #53 #55 #56; P3
  #51 #52 #54 #57 #58; P4 #59 #119-#124). Approved table hash:
  `31cc973ee56f9ed186c6a9052e2502d1b0f82aa2cf3ca2873257ff7289e09369` (current).

## Deviations from the story text

- Approval hash taken over the table with `issue` emptied (above), not the raw file.
- A plain HTTP 403 counts as a rate limit only when its text says rate limit, abuse or retry.
- AC-2's single re-draw replaced by the strict re-check of all fixed rows (user decision, 2026-11-08).
- Changelog rows carry `severity:medium-low` (AC-1's severity list has no changelog value).

## New findings seen during the re-check

The re-check agents noted about ten problems the review does not list. The user chose to log them as tech-debt
rows (2026-11-08); see `new_findings.md`. Seven held up in today's code and became TD-048..TD-054 (register and
table); the rest were already covered, already fixed, or not defects.

## CI (AC-7)

CI #61 on `b57fad9` (2026-11-08, https://github.com/Bhaskar-Bahukhandi/Ultimate-project/actions/runs/42467461633): the
new step "Findings table and publish script" passed (2 s); the job failed at "Runner self-test", case ignore_term
(runner took 20 s, limit 17 s). Cause, from the step log (read with the user's `gh`, read-only): ubuntu-latest had
become ubuntu-26.04, whose `timeout` is uutils coreutils 0.10.0; its `-k 10` KILL did not stop the TERM-ignoring stub.
CI #60 on ubuntu-24.04 had passed. Not an S05 defect: TD-055, and `ci.yml` pins `runs-on: ubuntu-24.04` (`28d78d5`).

CI #62 on `28d78d5` (2026-11-08, https://github.com/Bhaskar-Bahukhandi/Ultimate-project/actions/runs/42472674780):
success in 30m31s (job limit 45 minutes). "Findings table and publish script" 2 s (check_findings.py and both unit
suites), "Runner self-test" 18 s, "Playthrough bot" 169 s; every step passed. AC-7's "CI green" is met.
