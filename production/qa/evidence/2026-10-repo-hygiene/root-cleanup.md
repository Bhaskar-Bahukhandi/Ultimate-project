# Repo root cleanup — evidence

- **Task:** Y1-P0-T01 · Clean the junk out of the repo root
- **Plan day:** Day 0001 (planned Mon 19 Oct 2026; worked Sun 18 Oct 2026)
- **Branch / base commit:** `fix/phase0-playthrough-blockers` @ `4ad3fc0`

## Why this file exists

The plan asks for the evidence in `production/session-logs/session-log.md`, but
`production/session-logs/` is gitignored (pending `.gitignore` diff on this
branch). The deleted files were themselves gitignored, so deleting them produces
no git diff. This tracked file is the committed evidence for T01.

## Before

`ls -a` at the repo root: the expected entries plus 35 stray files.

```text
.claude  .git  .gitattributes  .github  .gitignore  .vscode  AethelgardPrototype
CLAUDE.md  design  design_archive  docs  nul  production  project.yaml
tmpclaude-0a15-cwd tmpclaude-0a48-cwd tmpclaude-1feb-cwd tmpclaude-23d2-cwd
tmpclaude-23f7-cwd tmpclaude-24dd-cwd tmpclaude-2ff0-cwd tmpclaude-3388-cwd
tmpclaude-3a10-cwd tmpclaude-43ae-cwd tmpclaude-4a7a-cwd tmpclaude-51bc-cwd
tmpclaude-5851-cwd tmpclaude-5a03-cwd tmpclaude-61d4-cwd tmpclaude-6b53-cwd
tmpclaude-6be3-cwd tmpclaude-7eca-cwd tmpclaude-8e52-cwd tmpclaude-9b0e-cwd
tmpclaude-9e3c-cwd tmpclaude-a3e1-cwd tmpclaude-abd8-cwd tmpclaude-b8e0-cwd
tmpclaude-c7ca-cwd tmpclaude-c8b1-cwd tmpclaude-d44c-cwd tmpclaude-d5bd-cwd
tmpclaude-de40-cwd tmpclaude-deb5-cwd tmpclaude-e260-cwd tmpclaude-e787-cwd
tmpclaude-f19d-cwd tmpclaude-f518-cwd
```

Checks before deleting:

| Check | Result |
|---|---|
| Count of `tmpclaude-*-cwd` | 34 |
| Content | each 62 bytes, the repo path only; `nul` 0 bytes |
| Dates | 14–23 Feb 2026 — none recent, so no live session held them |
| Git state (`git status --porcelain --ignored`) | all 35 `!!` (ignored), not untracked |
| `git grep tmpclaude` | no code reference; only `.gitignore`, archive docs naming different old files, and the plan |
| Ignore rules (`git check-ignore -v`) | `.gitignore:2 /nul`, `.gitignore:5 **/tmpclaude-*-cwd` — plan step 4 was already in place |
| Scripts redirecting to `nul` | none found (`>nul` / `2>nul` in .sh/.ps1/.py/.bat/.cmd/.md/.json) |

## Commands run (Git Bash, user approved)

```bash
rm -v tmpclaude-*-cwd                 # 34 removed
cmd //c 'del "\\?\%CD%\nul"'          # FAILED: "The directory name is invalid." (exit 11)
rm -v ./nul                           # removed './nul', exit 0
```

## After

```text
.claude  .git  .gitattributes  .github  .gitignore  .vscode  AethelgardPrototype
CLAUDE.md  design  design_archive  docs  production  project.yaml
```

`git status --short` is identical before and after (the tracked tree did not
change). `git status --short --ignored` lost exactly 35 lines, all
`tmpclaude-*-cwd` / `nul`. One ignored entry appeared, `.claude/settings.local.json`,
written by the Claude Code app when commands were approved; it is unrelated.

## Edge cases checked

| Edge case (from the Day 0001 plan) | Observed |
|---|---|
| `nul` survives a normal `rm` and needs the `\\?\` prefix | **Not true from Git Bash**: plain `rm ./nul` worked. The `cmd //c del "\\?\%CD%\nul"` form the plan prescribes fails when launched from Git Bash. Use `rm ./nul` in Git Bash, or `Remove-Item -LiteralPath "\\?\$PWD\nul"` in PowerShell (not run). |
| A tmpclaude file held open by a running session | Not hit: all files dated Feb 2026; the count stayed 34 across this session's own commands |
| Tool run on a dirty tree mixes outputs with code changes | Quick suite run before and after: `git status` unchanged |

## Baseline tests (same session, before commit)

`powershell -File AethelgardPrototype/tests/run_all_tests.ps1 -Quick` → exit 0,
"All suites passed."

| Suite | Result |
|---|---|
| load_all_test | ok=206 bad=0 |
| dialogue_test | 47 passed, 0 failed |
| context_stack_test | 32 passed, 0 failed |
| input_test | 52 passed, 0 failed |
| combat_fixes_test | 10 passed, 0 failed |
| reachability_test | 21 passed, 0 failed |
| chapter1_route_test, chapter2_route_test, phase0_blockers_test | skipped (`-Quick`) |

## Recurrence

`.gitignore` keeps both patterns out of git status but does not stop the files
being created. `tmpclaude-*-cwd` files appear to be working-directory markers
left by earlier Claude Code Bash sessions on Windows (name pattern; content is
the cwd path) — inferred, not confirmed. None were created this session.
`nul` is what Git Bash makes from a Windows-style `2>nul` redirect; use
`/dev/null` in Bash.
