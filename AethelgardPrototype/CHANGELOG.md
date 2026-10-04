# Changelog

Notable changes to the game. Newest first. Earlier history (Feb–Sep 2026) is in the per-phase
reports under `docs/` and in git history.

## 2026-10-04 — Dialogue as data, writing templates

- **New dialogue format (`.dlg`):** plain-text files with nodes, lines, choices, `[if …]`
  conditions, `set` flags, jumps and `do` events for scene hooks. They play through
  `DialogueManager.run(file, node)` with the existing dialogue box. Validation errors give the file
  and line. Writer's guide: `story/DIALOGUE_FORMAT.md`.
- **Extracted dialogue:** `tools/extract_dialogue.gd` copied all 1,967 lines and 74 choice blocks
  currently written inside scripts into `dialogue/_extracted/` (61 files) as rewrite material.
- **Writing templates:** `story/STORY_BIBLE.md`, `story/VOICE_GUIDE.md`,
  `story/outlines/ACT_TEMPLATE.md`.
- **Combat:** DEF reduces damage. MP pays for spells and healing and regenerates over time. Soul is
  earned from parries, perfect dodges and kills, for Glitch Arts.
- Tests: `tests/dialogue_test.gd` (32 checks) added to CI.

## 2026-10-04 — Temporary art removed

All temporary in-game art (`assets/sprites`, `generated`, `generated_v2`, `generated_v3`, `vfx`,
`tilesets`, `production_art`, `ui`, and `P after ch 1.png`) and the third-party `Mysprites/` packs
were moved out of the repo to `Desktop/Aethelgard sprite archive/`, with the same folder layout.
The game now runs entirely on placeholder shapes until the Pixel Art Engine sprites are imported.
Generator scripts, manifests and the `production_art` slot READMEs stay in the repo. All 73 Phase 0
checks pass without the art.

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
