# Changelog

Notable changes to the game. Newest first. Earlier history (Feb–Sep 2026) is in the per-phase
reports under `docs/` and in git history.

## 2026-10-04 — Phase 0: stop-ship fixes

All 19 critical issues from `CODE_REVIEW_2026-10-04.md` are fixed, covered by
`tests/phase0_blockers_test.gd` (73 checks).

**Story & progression**
- New Game now continues from the crash-site opening into Elara's meeting, the path to Oakhaven
  (Data Vision and Root Access unlocks) and Oakhaven village.
- Chapter 3 leads into Chapter 4. A Server Room gate in the Fractured Wastes continues the chapter
  through the Data Stream, Archive and Kaelthas's betrayal to the Chapter 3 ending.
- The Data Stream ride can now finish. A script error used to abort it every frame.
- The Clock Tower floors can be climbed and the Underground boss chamber can be entered. Both
  dungeons' cameras follow the player.
- The Chapter 2 cutscenes are no longer a black screen, and the admin boss can't be skipped with Esc.

**Dialogue**
- Talking to NPCs no longer freezes the player.
- Skipping dialogue never answers a story choice, and choices no longer time out.

**Saves**
- The ending, NG+ unlock and story checkpoints are actually written.
- A damaged save shows "Damaged save — Restore" instead of "Empty", and a bad file can never
  overwrite the good backup.
- No saving from the main menu. Pause no longer opens during cutscenes. Quick Save reports
  whether it worked.

**Combat**
- SOVEREIGN's override attack is capped at 3 (it could end the run from corruption alone).
- The phase spider always comes back down from the ceiling.
- The combat arena has walls, and enemies that fall out die, so fights can always end.
- Root Access can't set gravity to 0 or below, or set a boss's HP.
- The player can move when no character art is loaded.
- Fixed wrong spawn positions and "CANNOT FLEE" lingering after boss fights.
- The Root Access tutorial no longer charges corruption for repeated Apply clicks.

**Tooling**
- Test runners isolate `user://`, so test runs never touch real saves.
- CI on GitHub Actions: boot, load-all, the Phase 0 suite, whitespace.
- `assets/art_sources` is no longer imported. Exports exclude `docs/`, `assets/art_sources/`,
  `tests/` and Markdown files.
