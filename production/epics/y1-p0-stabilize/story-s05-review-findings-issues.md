# Story S05: Every review finding and open tech-debt row becomes a GitHub Issue

> **Epic**: Y1-P0 Stabilize (Sprint 001)
> **Task ID**: Y1-P0-S05 (`production/plan/_source/Y1-P0.json#Y1-P0-S05`; sprint plan row Y1-P0-S05)
> **Status**: Complete
> **Layer**: Production tooling
> **Type**: Integration
> **Estimate**: 3 days (sprint row: 3). Day 1 the findings table and its status column; day 2 the publish script and
> its tests, then labels, milestones and issues with the user's OK per step; day 3 links back, triage, templates.
> **Manifest Version**: N/A — `docs/architecture/control-manifest.md` does not exist
> **Last Updated**: 2026-11-08

## Context

**GDD**: none (production tooling). **Source of record**: the plan entry (title "Turn every review finding into a
GitHub Issue"; done "Every open finding has an issue number", "Phase 0 milestone triaged; issue templates in
.github/ISSUE_TEMPLATE"; edge cases "Duplicate findings across review sections", "Findings that point at files since
deleted", "GitHub API rate limit mid-batch: the script must resume") and the sprint row ("Findings CSV with issue
numbers; Phase 0 milestone triaged; `.github/ISSUE_TEMPLATE`"). `ROADMAP_10_YEAR.md` §11 asks for "One GitHub Issue
per item" and maps each review section to a roadmap phase. **Requirement**: N/A — no TR-ID registered.

**ADR Governing Implementation**: N/A — production tooling; no architectural decision.

**Engine**: N/A — no engine API. The publish script is Python 3 and calls the GitHub CLI (`gh`).

**Control Manifest Rules**: NOT ASSESSED — no control manifest.

**Performance**: no game cost. GitHub's limits apply to the publish run (batches with pauses; resume on a limit).

**Outward-facing.** The repo `Bhaskar-Bahukhandi/Ultimate-project` is public: every label, milestone and issue is
visible to anyone. Nothing is created on GitHub without the user's OK for that step (labels and milestones; then each
batch of issues). Claude never signs in: the user installs `gh` and runs `gh auth login` themselves; the script uses
the CLI's stored login and never reads, prints or stores a token.

**AGENTS.md protected areas**: none touched. No file under `AethelgardPrototype/scripts`, `scenes` or `dialogue`
changes. `ROADMAP_10_YEAR.md` §11 gets issue numbers only with the user's OK (day 3).

### Audit (2026-11-07, read-only; HEAD `f82daf2`)

1. **The review** (`AethelgardPrototype/CODE_REVIEW_2026-10-04.md`, 566 lines) holds about 190 discrete items, not
   the plan's "≈400": §2 root causes R1–R8 (8), §3 critical C1–C19 (19), §4.1–4.7 highs (61 bullets: 8, 8, 6, 9, 9, 9,
   12), §5 checks of the previous audit's "FIXED" items (15 rows), §6 PAE readiness (items 1–10 are pipeline work,
   §11 "§6 PAE pipeline items 1–10"), and the appendix (89 bullets in 11 system groups: Core, UI, Combat, Enemies,
   Encounters, Chapters, Regions, Cutscenes / camera / VFX, Audio, Background / shaders, Tooling / repo). The preface
   (Scope, Method), §1 verdict, §7 scorecard, §8 roadmap and §9 scope check are not findings. Some appendix bullets
   name two problems in one line.
2. **The changelog's open items** (`AethelgardPrototype/CHANGELOG.md`): 2026-10-04 "Decisions left for the user, not
   changed" (9 bullets, from :384) and 2026-10-06 "Seen, not yet fixed" (4 bullets, from :455). The 9 decisions were
   taken in T03 and most were built by T04–T08 and T11.
3. **The tech-debt register** (`docs/tech-debt-register.md`): 47 `TD-` rows, 38 of them Open, every Open row's
   `Sprint` is `Backlog`. Its header is stale ("Total items: 42 (33 open)").
4. **Fixed already.** Phase 0 (148 commits) fixed many of the above: C1–C19 per §11 and the sprint's stories, the
   decisions above, some highs and appendix items. No table records which.
5. **GitHub state** (public API, no sign-in): 0 milestones; the 9 default labels; 1 item on the issues endpoint (the
   open pull request "Fix/phase0 playthrough blockers"); no `.github/ISSUE_TEMPLATE`.
6. **Tooling**: `gh` is not installed on this machine; there is no `tools/` folder. Python 3.13 is installed.
   `.github/workflows/ci.yml` runs no Python. `/bug-triage` reads only `production/qa/bugs/` (its `SKILL.md:49-59`),
   not GitHub.
7. **Roadmap months to plan phases** (`ROADMAP_10_YEAR.md:140-291`): Months 1–2 = Y1-P0, 3–4 = Y1-P1, 5–6 = Y1-P2,
   7–9 = Y1-P3, 10–12 = Y1-P4. The plan has no Y2-Q3/Q4 phase (`production/plan/_source/` holds Y1-P0..P4, Y2-PP,
   Y2-Q1, Y2-Q2, Y3..Y10), though §11 names "Y2-Q3/Q4" for R7's deletion pass and the appendix's leftovers.

### Decisions (user, 2026-11-07)

- **D1 publishing:** the user installs GitHub CLI and signs in with `gh auth login` themselves. Claude builds the
  table and a resumable script, shows each step, and runs it only after the user's OK for that step.
- **D2 fixed findings:** a finding already fixed gets its evidence (commit or story) in the table and **no** issue.
  Only open findings become issues.
- **D3 tech debt:** every Open row of the tech-debt register gets an issue too (`source:tech-debt`), and its issue
  number is written into the register.

### Milestone map (proposed; the user approves it at AC-3)

One milestone per plan phase that a row lands in, named by the plan's phase id and title (for example
"Y1-P0 Stabilize"), plus "Backlog". A §11 row that names several phases goes to the **first** phase it names (when
the fix starts), except where the table says otherwise.

| Source rows | Milestone | From §11 |
|---|---|---|
| C1–C19, R5, R8, §5, Tooling / repo / docs | Y1-P0 Stabilize | Months 1–2 (Tooling: Months 1–4) |
| R1, R3, R4, R7, §4.1, §4.2 | Y1-P1 Spine | Months 3–4 (R7: 3–6; §4.2: 3–4 then 10–12) |
| R2, §4.4, §4.5, §4.7 | Y1-P2 Combat foundation | Months 5–6 (§4.7: 5–9) |
| R6, §4.3, §6 PAE items 1–10 | Y1-P3 Art pipeline + Pillar Slice | Months 7–9 (R6: 7–12) |
| §4.6 rows the review marks critical or that block New Game → credits | Y1-P0 Stabilize | "Months 1–2 critical" |
| other §4.6 rows | Y2-PP Pre-production | "Y2 route architecture" |
| Appendix, by group: Core | Y1-P1 Spine | owning system replaced in the spine |
| Appendix: UI | Y1-P4 Open-world tech + tools | "Months 10–12 authored menus" |
| Appendix: Combat, Enemies, Encounters, Cutscenes / camera / VFX, Audio | Y1-P2 Combat foundation | §4.4/4.5/4.7 rows |
| Appendix: Regions, Background / shaders | Y1-P3 Art pipeline + Pillar Slice | R6, PAE |
| Appendix: Chapters | Y2-PP Pre-production | §4.6 "Y2 route architecture" |
| Appendix: Tooling / repo | Y1-P0 Stabilize | Tooling row |
| Changelog open items | the milestone of the review section they belong to (Y1-P0 if none) | — |
| Tech-debt rows | Backlog | the register's `Sprint` column |

No "Y2-Q3/Q4 cleanup" milestone is created (no such plan phase); an appendix row whose owning system is not
replaced in Year 1 keeps its group's milestone above and can be moved at a later re-plan.

---

## Acceptance Criteria

- [ ] AC-1 **One table of every item.** `production/findings/findings.csv` (UTF-8, one row per item) holds every item
      from: `AethelgardPrototype/CODE_REVIEW_2026-10-04.md` §2, §3, §4.1–4.7, §5, §6 items 1–10 and the appendix's 11
      groups; `AethelgardPrototype/CHANGELOG.md`'s two open-item lists (:384, :455); and every Open `TD-` row of
      `docs/tech-debt-register.md` (counted from the table body, not its header; the header is corrected to the body's
      counts in the same pass). Columns: `id` (stable: `CR-R1`, `CR-C01`, `CR-H4.1-03`, `CR-V05`, `CR-PAE-03`,
      `CR-A-core-02`, `CL-1004-D3`, `CL-1006-S2`, `TD-043`), `title`, `source` (file and line of the item), `section`,
      `severity` (root-cause / critical / high / medium-low / audit-check / pipeline / tech-debt), `code_refs`,
      `area` (exactly one of: save, input, ui, economy, combat, enemies, encounters, story, regions, effects, audio,
      art, tooling, core), `milestone` (from the milestone map), `status`, `evidence`, `duplicate_of`, `plan_task`
      (the Y1-P0 / Y1-P1 plan task id the row belongs to, if any), `priority` (Phase 0 rows), `issue`. An appendix
      bullet that names two problems is split into two rows. `production/findings/check_findings.py` prints, per
      source section, the item count in the source and the row count in the table, and fails if they differ, if an
      `id` repeats, or if an `area` or `milestone` is not on its list.
- [ ] AC-2 **Status from evidence.** Every row's `status` is one of `open`, `fixed`, `obsolete`, `duplicate`:
      `fixed` names a commit hash or a Complete story **and** the current code at the item's refs was read;
      `obsolete` names the commit that deleted or replaced every file the item points at; `duplicate` names the row
      it repeats in `duplicate_of` (the earlier row keeps the content). A row whose fix cannot be shown stays `open`
      with what was checked in `evidence` ("unverified" is not "fixed"). `check_findings.py` also confirms every
      cited hash exists (`git cat-file -e`), every cited story file exists with `Status: Complete`, and every
      `duplicate_of` names an existing row; it prints counts by status and source. A hand check of 20 `fixed` rows
      (chosen by a fixed seed, listed in the evidence) re-reads the code; any wrong row is corrected and the sample
      re-drawn once.
- [ ] AC-3 **Scheme approved before anything is created.** Labels: `area:<area>` for each area above,
      `severity:<severity>`, `source:code-review` / `source:changelog` / `source:tech-debt`, and
      `priority:P1`..`priority:P4`. Milestones: per the milestone map. Each issue: title `[<id>] <title>`, body with the
      source, code refs, severity, milestone and evidence. The user reviews the table, the milestone map and the label
      list. Their approval (date and wording) is recorded in the evidence README, and
      `production/findings/publish-approval.txt` holds the approved table's SHA-256: the script refuses a real run when
      the file is missing or the table's hash differs (an edit after approval needs a new approval).
- [ ] AC-4 **The publish script.** `tools/github/publish_findings.py` builds one action plan (labels, milestones, one
      issue per `open` row) from the table; `--dry-run` prints that plan and calls nothing, a real run executes the
      same plan. Constants, each asserted by a test: batch size 50; 30 s between batches; on a rate-limit reply wait
      the longer of the reply's `Retry-After` / reset time and a backoff of 60, 120, 240 s, then stop after 3 failed
      retries with the row it reached. Once per batch it lists the repo's issues
      (`gh issue list --state all --limit 1000 --json number,title`) and adopts an issue whose title starts with
      `[<id>] ` instead of creating it (no duplicate after a crash between create and write-back). It writes the
      issue number into the row right after each create or adopt (the table is the resume point). Before any real
      call, and in every dry run, it scans every title and body for local paths (`C:\Users\`, `/Users/`, the Windows
      user name), e-mail addresses and token-like strings (`ghp_`, `github_pat_`, 32+ character hex or base64 runs)
      and refuses to publish on a hit; the scan's output is kept as evidence. It never handles a token (it runs
      `gh`, which uses the user's login). Unit tests (`tools/github/test_publish_findings.py`,
      `python -m unittest discover -s tools/github`) drive it against a stubbed `gh`: the dry-run output equals the
      stub's call log from a real run of the same table; resume skips rows with an issue; an existing `[<id>]` title
      is adopted; a rate-limit reply waits then continues; the stop leaves the table consistent; a missing or stale
      approval file refuses; a planted path, e-mail or token in a body refuses. Each test watched failing before
      passing.
- [ ] AC-5 **Published with the user's OK.** After the user's OK: labels and milestones; then each batch of issues,
      each batch after its own OK. Every `open` row has an issue number; every `fixed`, `obsolete` and `duplicate`
      row has none. A check through the public API (items with a `pull_request` key excluded; raw JSON saved)
      confirms: one issue per `open` row; each title's `[<id>]` unique; no issue closed; each on its row's milestone
      with its row's labels; the open-issue count of each milestone equals the table's `open` rows for it.
- [ ] AC-6 **Linked and triaged.** With the user's OK: the issue numbers go into ROADMAP §11's rows (a range or list
      per row) and into the tech-debt register (a `#N` per TD row). The plan sources are not edited: the table's
      `plan_task` column is the link from rows to plan tasks. Triage of the Y1-P0 milestone happens in the table:
      Claude proposes a `priority` (P1–P4, with a one-line reason) for each Y1-P0 row, the user approves or changes
      it, and the script sets the `priority:*` labels (the approved table is the triage record; `/bug-triage` is not
      used, it reads only `production/qa/bugs/`). Issue templates `.github/ISSUE_TEMPLATE/bug.yml` and
      `playtest.yml` (GitHub issue forms: steps, expected, actual, build, evidence for bugs; build, route, notes for
      playtests) plus `config.yml`; they show on the repo's "New issue" page.
- [ ] AC-7 **Evidence and CI.** `production/qa/evidence/2026-11-findings/` holds a README with the AC map and the
      recorded approval, the `check_findings.py` output, the status counts, the 20-row hand check, the body scan,
      the dry-run log, the publish log (per batch), the API check's raw JSON and result, and a snapshot of the
      milestones. `.github/workflows/ci.yml` gets a step running `python -m unittest discover -s tools/github` and
      `python production/findings/check_findings.py`; CI green. CHANGELOG entry; `git diff --check` clean; no file
      under `AethelgardPrototype/scripts`, `scenes` or `dialogue` changes.

---

## Implementation Notes

- Extraction is semi-automatic: a parser splits the review's tables and bullets into rows; every row is read and
  corrected by hand (a bullet's title is written short and plain; its code refs copied exactly).
- Status checking (AC-2) is the long part of day 1. Use `git log -S`/`-G` on the item's code refs and the stories'
  Completion Notes; open the current code at each ref. Report the share left `open — unverified`.
- The table is the single source: the script writes only the `issue` column; everything else is edited by hand.
- `gh` calls: `gh label create --force`, `gh api repos/{owner}/{repo}/milestones`, `gh issue create --title --body-file
  --label --milestone`, `gh issue list --state all --limit 1000 --json number,title` (once per batch; GitHub search
  is not used: it is limited to about 30 calls a minute and lags behind a create).
- Windows: the script writes the CSV with `newline=''` and UTF-8; bodies go through `--body-file` (no shell quoting).
- AC-5 and AC-6's GitHub-side checks need the user's sign-in; if the user has not signed in by close, they are
  DEFERRED (not failed) and recorded after.

---

## Out of Scope

- Fixing any finding (S05 only records and files them).
- Creating issues for fixed, obsolete or duplicate rows (D2).
- Signing in to GitHub, or handling any token (D1).
- GitHub Projects boards, automation workflows on issues, and assigning people.
- Editing the plan sources (`production/plan/_source/*.json`) or the review document; the register gains issue
  numbers and a corrected header only.

---

## QA Test Cases

- **C1 (AC-1)** — `check_findings.py`: per section, source count = row count; split bullets listed; ids unique;
  every area and milestone on its list; the register header matches its body.
- **C2 (AC-2)** — status counts; every cited hash exists and every cited story is Complete; every `duplicate_of`
  resolves; the 20-row hand check.
- **C3 (AC-3)** — the recorded approval and `publish-approval.txt` matching the table's hash.
- **C4 (AC-4)** — the unit tests (dry-run = call log, resume, adopt, rate-limit, stop, approval, body scan) green,
  each watched failing.
- **C5 (AC-5)** — the API check: issues = open rows, unique `[<id>]`, none closed, milestones and labels match, PRs
  excluded.
- **C6 (AC-6/7)** — ROADMAP §11 and the register carry issue numbers; the Y1-P0 rows' approved priorities match
  their labels; the templates show on "New issue"; the CI step green; evidence README complete.

---

## Test Evidence

**Story Type**: Integration
**Required evidence**: `tools/github/test_publish_findings.py` (passing locally and in CI),
`production/findings/check_findings.py` output, the dry-run and publish logs, the public-API check, and
`production/qa/evidence/2026-11-findings/` (README with the AC map and the recorded approval).
**Run result**: N/A — no game change; the issues on GitHub and the API check are the observation.

---

## Dependencies

- Depends on: Y1-P0-S03 (Complete: Conventional Commits and the evidence folder). User step: install GitHub CLI and
  run `gh auth login` before day 2.
- Unlocks: issue-numbered traceability for Phase 1 planning (S16) and the bug/playtest templates for T15.

---

## Completion Notes

**Completed**: 2026-11-08

**Criteria**: 7/7 met. AC-7's "CI green" was DEFERRED at close and is now met (CI #62, below).

**Known after close**: CI #61 on `b57fad9` (2026-11-08) ran the new findings step green (2 s) but failed at the runner
self-test: ubuntu-latest had moved to ubuntu-26.04, whose uutils `timeout` did not KILL a TERM-ignoring suite (case
ignore_term, 20 s against 17 s); unrelated to S05, logged as TD-055 and worked around by pinning `runs-on: ubuntu-24.04`
(`28d78d5`). CI #62 on `28d78d5` (run 42472674780) is green in 30m31s against the 45-minute limit: "Findings table and
publish script" 2 s, runner self-test 18 s, playthrough bot 169 s.

**Result**: `production/findings/findings.csv` 265 rows: 172 open, 87 fixed, 6 duplicate. Every fixed row was confirmed
by a second reader (seeded hand check of 20: 5 PARTIAL; strict re-check of the other 75: 3 PARTIAL; all 8 reopened).
Published 2026-11-08 to the public repo, each step after the user's OK: 28 labels, 7 milestones, issues #2-#173;
`api_check.py` 15/15 PASS through the public API (one issue per open row, `[id]` unique, none closed, milestones, labels
and priorities match). A scan of every published body found no local path, user name, e-mail or token. 19 Y1-P0
priorities set (P1 #39). ROADMAP §11 (20 rows) and the register (45 open TD rows) carry the issue numbers. Bug and
playtest issue forms added.

**Deviations** (advisory, user decisions):
- AC-2: the single 20-row re-draw was replaced by a strict re-check of every fixed row (8 partial fixes found and
  reopened).
- AC-3: three approvals (the table as is; TD-048..054 added; the Y1-P0 priorities), each recorded in the evidence README
  and `publish-approval.txt`. The approval hash is taken with the `issue` column emptied so the script's write-back does
  not stale it. Changelog rows carry `severity:medium-low` (AC-1's list has no changelog value).
- AC-4: a plain HTTP 403 counts as a rate limit only when its text says so; the commit-hash exemption in the body scan
  was removed (the hex rule starts at 32 characters, so short hashes never match).
- AC-6: triage in the table (Claude proposed, the user approved), not `/bug-triage`, which reads only
  `production/qa/bugs/`.
- Scope added: seven new findings seen during the re-check became TD-048..TD-054 (register, table, issues #167-#173).
- Beyond the story: `check_findings.py` gained `--strict`; unreachable commit hashes (19 of 24 cited hashes are not yet
  on `main`), register-header drift and changelog-marker counts are warnings by default so a squash merge or an ordinary
  doc edit cannot turn CI red; always-on offline checks (leak scan of every cell, open-row/issue pairing, register `#N`,
  approval hash) and 20 tests of its own; a second CI unittest line runs them.

**Test Evidence**: Integration: `tools/github/test_publish_findings.py` (48 tests),
`production/findings/test_check_findings.py` (20 tests), `production/findings/check_findings.py`, and
`production/qa/evidence/2026-11-findings/` (README with the AC map and the recorded approvals). Run result: N/A, no game
change; the issues on GitHub and the API check are the observation.

**Code Review**: Complete. /code-review round 1 CHANGES REQUIRED (scan path and user-name misses; two-way TD check;
commit the tools with the CI change), fixed, then APPROVED WITH SUGGESTIONS. /story-done gates: QL-TEST-COVERAGE GAPS
and LP-CODE-REVIEW CONCERNS, acted on (README/CHANGELOG refreshed, dry runs re-saved on the final table, check_findings
hardened and tested).

**Open suggestions and known gaps** (not logged as debt): long or complex functions in one-shot tooling (`_run`,
`check_findings.main`, `parse_review`, `validate_rows`); the AC-4 first failing run failed on stubs, so it shows the
tests reach the code but not that each assertion catches its bug (no mutation check); `label create --force` resets
existing label colour and description; `priorities` does not write back progress; `extract_findings.py` would raise a
KeyError on TD-048..054 if re-run on an unpublished table (guarded: it refuses once issues exist); the issue forms'
rendering on GitHub and the ROADMAP §11 link accuracy are checked by hand only (no screenshot kept); on Linux CI the
user-name leak rule is not applied (announced as a warning).
