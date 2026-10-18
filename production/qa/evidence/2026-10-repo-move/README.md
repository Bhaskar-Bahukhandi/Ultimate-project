# Repo move off OneDrive — evidence

- **Task:** Y1-P0-S04 · Decide and carry out the repo hygiene calls (decisions: `production/decisions/2026-10-repo-hygiene.md`)
- **From:** `C:\Users\BHASKAR BAHUKHANDI\OneDrive\Desktop\Ultimate project` · **To:** `C:\dev\Aethelgard`
- **How:** framework committed (`ec3e91a`) and pushed (`817801f..85a70c7`), then `git clone --branch fix/phase0-playthrough-blockers` from GitHub (a clone, not a copy). 2,685 files at `85a70c7`.

| Check | Result |
|---|---|
| CI on the pushed framework commit | Run 39125308814 green, incl. the whitespace and commit-message steps |
| `--headless --import` in the clone | Exit 0, no errors, 38 s; `.godot` 14 MB (the OneDrive copy's cache was 140 MB) |
| Full suite in the clone, first run | **Failed:** dialogue_test 45/47. All 82 `.dlg` files were checked out CRLF (system `core.autocrlf=true`, no `eol` rule for `*.dlg`); the lint's `(?m)…(.+)$` kept `\r` on rhythm-clipped node names. The game's parser was unaffected (it strips every line). |
| Fix | `.gitattributes`: `*.dlg`, `*.yaml`, `*.py` → `text eol=lf`; `dialogue_test.gd`: `strip_edges()` on the clipped-node list. Seen passing (47/47) on the CRLF files before re-checking them out as LF. |
| Full suite in the clone, after the fix | **Pass:** 10/10 suites, every count equal to the baseline (layout 6, load_all 206, dialogue 47, context 33, input 52, ch1 46, ch2 49, combat 10, reach 21, phase0 81), 654 s. Log: `run_all.log` |
| Local files carried over (ignored) | session-state, session-logs, `.claude/settings.local.json`, `run_artifacts/` (13 MB), `exports/` (201 MB); sizes match |
| Old copy | Kept at the OneDrive path until the user retires it |
