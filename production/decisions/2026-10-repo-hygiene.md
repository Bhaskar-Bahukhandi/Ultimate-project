# Repo hygiene decisions — OneDrive, LFS, sprite archive, context.txt

- **Task:** Y1-P0-S04 · Decide and carry out the repo hygiene calls
- **Decided by:** the user, 2026-10-18 (plan Day 0006, worked early); all four took the recommended option
- **Evidence date:** 2026-10-18, `fix/phase0-playthrough-blockers` @ `a416fe1`

## Facts measured

| Item | Measurement |
|---|---|
| `.git` | 188 MB on disk: one 98 MB pack plus 84 MB of loose objects never packed (`git count-objects -vH`); GitHub reports 177 MB for the repo |
| Blobs by type (all history) | PNG 150.7 MB in 1,979 blobs; Markdown 21.9 MB; extensionless 20.6 MB; GDScript 14.1 MB |
| Largest blobs (history) | `docs/archive/qa_logs/godot_stderr.txt` 9.6 MB; `P top down.png` 6.1 MB; `Mysprites/Unity samples/particlePack_samples.unitypackage` 5.3 MB |
| Binaries in the current tree | 518 PNGs, 139.9 MB, all review-only (`assets/art_sources/` 457, `docs/` 60) plus one evidence shot; no shipping art is tracked |
| `Mysprites/` | Removed from the tree in `abcf40c`; still 706 blobs, 13.7 MB uncompressed, in history. Archive: `Desktop\Aethelgard sprite archive` (61 MB), inside OneDrive |
| `context.txt` | The same document as `Blueprint_and_roadmap.txt` (32,925 vs 32,426 bytes). After normalising whitespace and the U+FFFE hyphen artifacts, 32 word-level differences, all PDF-extraction artifacts in `context.txt` (dropped hyphens, URLs split across lines) |
| Path length | Repo root 62 characters; longest tracked path 182 characters; deepest file ≈ 244 of Windows' 260 |
| OneDrive references | None in `.import`, `.tscn`, `.tres`, `project.godot` or `.cfg` files. Named in `AethelgardPrototype/AGENTS.md` (to update) and in older docs and art manifests (history, left as they are) |
| A fresh clone lacks | `.claude/` (4.2 MB), `CLAUDE.md`, `design/`, root `docs/` (532 KB), `project.yaml`, `production/project-stage-report.md`, `production/stage.txt`: all untracked |
| Git LFS | git-lfs 3.5.1 installed. GitHub Free: 10 GB storage and 10 GB bandwidth a month; downloads by GitHub Actions count; going over blocks LFS until next month without a payment method ([LFS billing](https://docs.github.com/billing/managing-billing-for-git-large-file-storage/about-billing-for-git-large-file-storage), [usage per plan](https://docs.github.com/en/billing/reference/product-usage-included), read 2026-10-18) |

## Decisions (2026-10-18)

| Call | Decision | Steps |
|---|---|---|
| **OneDrive** | **Move the repo off OneDrive, committing the framework files first.** Target `C:\dev\Aethelgard`. | 1. Review and commit `.claude/`, `CLAUDE.md`, `design/`, `docs/`, `project.yaml` and the `.gitignore` framework block (the repo is public: scanned for secrets first). 2. Push. 3. `git clone` (not copy) to the target. 4. Copy the ignored-but-useful local files the user picks (e.g. `production/session-state/`, `session-logs/`). 5. `--headless --import`, then the full suite, from the new path. 6. Update `AGENTS.md`'s path (user approval). 7. Start Claude Code in the new folder (hooks and project memory are tied to the folder). 8. The OneDrive folder stays until the clone passes; removing it is the user's call and action. |
| **Git LFS** | **Not yet.** `git gc` locally to pack the loose objects. *Done 2026-10-18: 2,301 loose objects packed; `.git` 188 → 176 MB (the loose objects were mostly PNGs, which barely compress); `git fsck --connectivity-only` clean.* | Adopt LFS for new binaries (`*.png`, `*.wav`, `*.ogg`, `*.psd`, `*.aseprite`) at the **first production-art import phase**, deciding then how CI fetches them (bandwidth). History is not migrated. This replaces the plan's "`git lfs track` output" evidence with this recorded deferral. |
| **Sprite archive** | **Keep it where it is; no history purge.** | None. The archive is inside OneDrive, so it is already cloud-backed. 13.7 MB of history doesn't justify a rewrite and force-push. |
| **context.txt** | **Retire it.** | `git rm design_archive/context.txt`; `Blueprint_and_roadmap.txt` keeps the content; git history keeps the file. |
