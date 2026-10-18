# Evidence

Proof that a task's acceptance criteria hold, kept in git so it is still here when the task is
reviewed. "Retained" means committed: a screenshot that was taken and thrown away is a claim, not
evidence (`.claude/docs/coding-standards.md`).

## Folder pattern

One folder per topic, named `YYYY-MM-<topic>/` with a lowercase, hyphenated topic:
`2026-10-test-layout/`, `2026-10-shatter/`, `2026-11-ch1-fights/`. The month is when the evidence
was captured. The task and the sprint QA plan name the exact folder; use that name.

Each folder holds a short `README.md` (or `<item>-evidence.md` for Visual/Feel sign-off) that maps
every acceptance item to its file, plus the files themselves.

## What counts as evidence

| Kind | Counts when | Example |
|---|---|---|
| Test log | It is the full output of the named run, with the command, branch and commit | `2026-10-test-layout/run_all.log` |
| CI run | The note gives the run URL, the commit and the result | link in a folder `README.md` |
| Screenshot | It shows the acceptance item and says how it was captured (below) | `2026-10-shatter/spare.png` |
| Sign-off | A dated note says who looked, what they checked, and what they decided | `y1-p0-t11-evidence.md` |
| Playtest notes | Written with `/playtest-report`; they live in `production/qa/playtest-*.md`, not here | — |

Not evidence on their own: a passing test nobody has seen fail, a description of a screen
without the screenshot, a file under `run_artifacts/` (git-ignored, so it is gone on the next
clean), or a summary of a log without the log.

## How a screenshot was captured (AGENTS.md)

Every screenshot's note states which of these it is. Visual and UI acceptance needs a **live**
capture; the others support it but don't replace it.

- **Live viewport**: the running game in a real window (the editor run or the exported build).
- **Real-renderer tour**: `tests/run_screenshots.ps1`, a real renderer in a window driven by the
  tour script. Counts as live for layout and text; say "tour" in the note.
- **Headless / dummy renderer**: `--headless` runs. Shows node state, not what a player sees.
- **Board or sheet**: contact sheets, crop-contract sheets, deterministic boards. Comparison only.

Art evidence also follows the Art Generation Truth Gate in `AethelgardPrototype/AGENTS.md`
(whether ComfyUI was used: Yes / No / Unproven, with its evidence bundle).

## Copying tour screenshots here

```
powershell -File AethelgardPrototype/tests/run_screenshots.ps1 -Only ch1_shatter -Evidence shatter
```

copies the run's PNGs and `report.md` into `production/qa/evidence/<YYYY-MM>-shatter/` and writes
`capture.md` there with the command, commit and renderer. It copies nothing if the tour failed.

## Size

Keep a folder under ~5 MB. Prefer PNG screenshots at 1280×720; logs stay whole (a full suite run
is about 300 KB). No raw video unless the acceptance item is about motion, and then a short clip.
