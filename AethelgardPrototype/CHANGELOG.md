# Changelog

Notable changes to the game. Newest first. Earlier history (Feb–Sep 2026) is in the per-phase
reports under `docs/` and in git history.

## 2026-10-05 — New story source; prologue and Chapter 1 rewritten

- **Story source adopted:** `story/source/PRODUCTION_MASTER_2.1.md` (your general story and flow).
  - Its canon is now in `story/STORY_BIBLE.md`: the emergency refuge, SOVEREIGN, the Human Patch,
    why the Source Key is scattered, and the God King as "the habit of needing a final ruler".
  - Proposed: four ending families (Sole / Bound / No Authority / Consent), with faction and the
    deleted as modifiers.
  - `DESIGN_PILLARS.md` records that the implemented mechanics win over the source's systems
    sections.
- **Prologue + Chapter 1 as `.dlg`** (10 files in `dialogue/prologue/` and `dialogue/ch1/`).
  - Covers the crash site, Elara, the Broken Mile (Data Vision, first Root edit), Oakhaven's gate
    and road ledger, stew, a normal afternoon, the north field, the boar, the bridge deadline,
    Aldric (kill / spare / purge), Fragment One, the village meeting and Elara joining.
  - Rewritten against new per-character voice sheets (`story/VOICE_GUIDE.md`): contractions, real
    questions, distinct voices, none of the source's repeated tics.
- **Playable now:** New Game opens with the black-screen prologue (Flight 707), then the rewritten
  crash site.
  - The crater has six things to look at, and Kaelen calls out for survivors.
  - The fused metal gives the trace that points east.
  - The old "Oakhaven death record looped 412 times" text is gone.
- **Dialogue system:**
  - `.dlg` files can use `do trust <companion> <delta>` and `do pause <seconds>` without scene
    code.
  - A dialogue run stops when its scene is left, so lines no longer spill into the next scene.
  - Opening prompts no longer hardcode "[F/E]".
- **Voice lint** in the dialogue tests (45 checks now). It flags questions without question marks,
  the banned tics, hardcoded key names, unregistered speakers, and long files with no contractions.

## 2026-10-04 — Gamepad support and full remapping (InputService)

- **Gamepad:** every action has a controller default, and no two actions that can be used at the
  same time share a button. Menus can be confirmed with A and backed out of with B. A gamepad
  press in a menu with nothing selected selects its first button. Disconnecting the controller
  mid-play pauses the game.
- **Controls screen** (Options → Controls…, in the main menu and the pause menu): rebind
  keyboard and gamepad separately. Taking a key from another action swaps them, and it can't
  break pause, menu navigation or movement. Reset to Defaults is included. Bindings are saved
  to `user://input.cfg`, and old keyboard rebinds are migrated.
- **Prompts follow the player:** about 100 hardcoded key hints ("[F] Talk", "Press SPACE",
  "[Hold TAB to skip]") now show the player's real key or button. They switch between keyboard
  and gamepad labels as you play (Xbox, PlayStation or Nintendo names). Dialogue text can use
  `{interact}`-style tokens.
- **Fixed:** the level-up popup, arena rematch and chapter-end screens said "Press Space", but
  only Enter worked; they now name the right key. Dialogue choices can be picked with pad A. The
  lore journal (L / pad Y) and dialogue skip (Tab / pad View) are real actions now, so they work
  on a gamepad and can be rebound. The journal opens only while exploring. The tutorial's
  "Skip" hint no longer shows raw `[color]` tags.

## 2026-10-04 — One owner for pause, menus and game speed (ContextStack)

- **Menus no longer fight each other.** Root Access and the pause menu can't unpause each other. The
  pause menu can't open over the map, shop, journal or Root Access. One Esc press closes the map
  without also opening pause.
- **The world map is modal:** it pauses the world (no walking, encounters or storms underneath),
  and keys no longer leak through to the game.
- **Lore journal:** opens only during play (not on the title screen or mid-dialogue), pauses, and
  closes with L or Esc.
- **No more "stuck paused":** changing scenes with a panel open (e.g. Root Access) resumes the game.
- **Slow-mo works:** parry wobble and dramatic slow-mo no longer get cancelled after one frame.
  Hitstop, slow-mo and wobble stack by priority, and scene changes and retries clear any leftover
  slow-mo.
- The status window can always be closed. A shop that can't open no longer softlocks the scene that
  asked for it. The completion tracker shows above the pause menu.

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
