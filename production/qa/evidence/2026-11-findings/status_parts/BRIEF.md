# S05 status check — brief for each part (AC-2)

Read-only on the game. Each part writes ONE file: `status_parts/part<N>.csv` (UTF-8, `newline=''`), header
`id,status,evidence,duplicate_of,plan_task`, one line per row of its id set, written as you go (so a resumed run
keeps earlier rows). Never edit `production/findings/findings.csv` or any other file.

For each row of `production/findings/findings.csv` in your set, read its title, source line in the source file and
`code_refs`, then decide:

- `fixed`: name a commit hash (`git log -S`/`-G`/`--follow` on the refs, or the commit a Complete story names) or a
  Complete story file path, AND read the current code at the item's refs. Evidence form:
  `commit <hash> (<subject, short>); story <path>; now: <what the current code does, file:line>`.
  A story counts only if its file says `Status: Complete`.
- `obsolete`: every file the item points at was deleted or replaced; name the deleting commit.
- `duplicate`: the item repeats an earlier row (same defect, same code); put that row's id in `duplicate_of`;
  evidence says what they share. The earlier row (lower in the table) keeps the content.
- `open`: anything you cannot show fixed. Evidence says what you checked: `checked <refs/commits>; <why open>`.
  "Probably fixed" is `open`.

`plan_task`: the Y1-P0 or Y1-P1 task id (`production/plan/_source/Y1-P0.json`, `Y1-P1.json`, field `id`) the row
belongs to, if one plainly owns it; else empty.

Useful: sprint stories in `production/epics/y1-p0-stabilize/` (their Completion Notes name commits), the
CHANGELOG's dated sections, `git log --oneline -- <file>`. Evidence text: one line, no commas inside unquoted
fields (let the csv module quote), no local user paths, no e-mails. Keep each evidence under 300 characters.

Return a short report: counts by status, rows you were least sure of, and the file path.
