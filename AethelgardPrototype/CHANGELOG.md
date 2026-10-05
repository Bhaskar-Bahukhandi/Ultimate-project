# Changelog

Notable changes to the game. Newest first. Earlier history (Feb–Sep 2026) is in the per-phase
reports under `docs/` and in git history.

## 2026-10-05 — Screenshot tour: the game, actually rendered

Every earlier test ran `--headless`, with no renderer: it proved flags and flow, never what's on
screen. `tests/run_screenshots.ps1` runs `tests/screenshot_tour.gd` with a real renderer (a game
window opens for about two minutes; audio is muted; user:// is isolated as in the other tests).

- **Shots:** the 17 Act 1 scenes, the pause screen, the Controls screen, and, for each of the 19
  authored `.dlg` files, its longest line and its longest choice in the real dialogue box. 49 in
  all.
- **Checked automatically:**
  - the dialogue box and choice list stay on screen;
  - the choices don't cover the box;
  - no option is wider than the screen;
  - no frame is one flat colour.
  Exit code 1 if anything is found.
- **Output:** `run_artifacts/screenshots/<timestamp>/` (git-ignored; a `.gdignore` keeps Godot
  from importing the PNGs), with one PNG per shot, `contact_scenes.png`, `contact_dialogue.png`,
  `report.md` and `tour.log`. Use `-Only main_menu,ch2_,dlg_ch1` for a subset.

**Bugs it found, both fixed:**
- **Every 3+ option choice covered the speaker's name.** The choice list sat in a 140 px slot,
  needed about 180 px, and grew *downward* into the dialogue box. It now grows upward
  (`dialogue_manager.gd`).
- **New Game kept the old "ACTIVE QUESTS" panel.** `SideQuestManager.reset()` cleared the quests
  but never refreshed its HUD, so after quitting to the menu and starting over, the previous
  quest stayed on screen. It now refreshes on reset.

**Seen but not fixed (listed for later):**
- Hardcoded key hints the input guard misses: "[Hold ESC to skip]" in the cutscene scripts, the
  world map footer, and the combat arena help.
- Overlapping HUD elements: two HUDs drawn over each other in the Chapter 2 side-scrollers, and
  "HP: 84/100" over its bar in the village.
- "[Hold Tab to skip]" sits under the objective tracker.
- The bottom-left HUD is hidden behind the dialogue box.
- On exit, a rendered run (a plain game boot too, not just the tour) reports "1 RID allocations
  … Texture … leaked at exit". Something global keeps a texture alive past renderer shutdown.
  It's harmless at quit, but worth finding.

## 2026-10-05 — Breathing pass on the prologue and Chapters 1–2

Too many lines were one to three words, so conversations read like ping-pong. Every authored
`.dlg` in the prologue, Chapter 1 and Chapter 2 was gone over. Lines were lengthened where a
person would naturally say a little more: a reason, a detail, the rest of the thought. Rapid-fire
beats that work *because* they're short were kept.

- **Before → after (771 spoken lines):**
  - average 6.4 → 8.0 words;
  - short lines (≤ 3 words) 34% → 18%;
  - one-word lines 11% → 6%;
  - Kaelen 4.7 → 7.3 words, and 46% → 15% short.
  - The worst file is now 20% short; it was 63%.
- **Unchanged:** every node, choice order, option count, flag, condition and `do` event, and
  every line the route tests look for.
- **New rhythm lint** in `tests/dialogue_test.gd` (2 checks):
  - at most 30% short lines per file (for files of 12+ lines);
  - at most 4 short lines in a row.
  - Machine speakers are exempt. A deliberately clipped node is exempted with
    `# rhythm: clipped <node …>`, which must name real nodes.
  - Exempted nodes: Old Fen, the Spirits/Runes beat, Aldric under the directive, the seat
    interrogation, Seraphina's convoy count, the Wraith "destroy" exchange, and "Break it."
- `story/VOICE_GUIDE.md` §5 documents the rule and per-speaker target lengths.

## 2026-10-05 — Chapter 2 rewritten and wired (Ironhold, the end of Act 1)

Chapter 2 now plays the new story from the road to Ironhold to the Act 1 ending (8 `.dlg` files in
`dialogue/ch2/`).

**The reunion and the city**
- **On the road:** Kaelen recognises Seraphina's cabin-crew voice ("keep the centre open") at a
  convoy. She tests him: what seat, window or aisle. "We died together." Fixed from the source:
  he knows her voice, not her face.
- **The gate:** Seraphina vouches for him, replacing the old forged-token hack. Rook appears,
  arguing about tariff codes.
- **Ironhold has new people:** Rook (the market), Rem (the infirmary), Garro, Doss, Sol the
  auctioneer, the street preacher, Nori and the paladins, the dice host, and Ina. Seraphina has six
  off-duty conversations with Kaelen and Elara, unlocked as the chapter goes on.
  - The old "Engineer Mira" (a clash with Mira Chen) and the pre-meeting Seraphina who called
    Root Access dishonourable are gone.
- **The Command Hall:** with Commander Brask present, you choose how much to tell them: the truth,
  part of it, or a show of Root Access. This sets the existing truth / cautious / show-off flags,
  and Seraphina remembers.

**The medicine convoy (timed)**
- Rem's fever medicine is stuck on the west road. Its deadline is the evening bell, which is the
  Clock Tower stopping.
- You're warned before going up the tower and can turn back.
- Early, on time or late changes Rem's lines, who helps in the Proxy fight, and the Act 1 ending.
  If you've told the truth, Seraphina says "one hundred and eighty-six".

**The arena and the Clock Tower**
- **The arena:** Vex's welcome, corner advice from Elara and Seraphina, and the memorial wall.
  Winning the bronze bracket opens the Clock Tower.
- **The Clock Tower:** the bell rings thirteen times, then Data Vision traces. On the way up there's
  a scratched map mark (a seed for Kaito), then the Minute Hand.
- **The missing shift:** rescue now, scout first, or seal the tunnels until morning. Each costs
  something different.

**The Underground and the Proxy**
- **The Underground:** workers stuck in repeating shifts. The Wraith speaks through the lights
  before it appears. The source's "MARA" is now a missing worker's name.
- **The Wraith choice:** restore it (Iven: "Don't lose it."), destroy it, or absorb it. Fragment
  Two is no longer handed out here.
- **The Administrator Proxy:** "ACCEPTABLE CENTRALIZATION COST" / "You mean people." / "Break it."
  It's reachable only after the tunnels are cleared.

**Fragment Two and the end of Act 1**
- **Fragment Two and the wall:** the second memory flash, then the Flight 707 scene on the upper
  wall (the laptop, the coffee stain, "Don't apologise for the crash unless you remember causing
  it").
- **Seraphina decides for herself:** she isn't a menu choice. She joins unless Ironhold can't spare
  her (late medicine, sealed tunnels) or Kaelen has lost her trust.
- **The Act 1 end:** who gets your report (councils, archivists or command), which road to the
  Wastes (this sets Act 1's pace), and the outer bridge, with lines that depend on Oakhaven's bridge
  and the medicine.
- **Removed:** the early SOVEREIGN reveal and the fake 72-hour countdown, both against the new
  canon.
- **Tests:** `tests/chapter2_route_test.gd` (49 checks, in CI) plays a careful route (Seraphina
  joins) and a reckless one (she refuses).

## 2026-10-05 — Chapter 1 plays the rewritten story, start to finish

New Game now runs entirely on the new dialogue, from the crash site to the Chapter 1 ending.
- **Elara meeting:** the sword, the slime that breaks into polygons, "Hands where I can see them",
  and the first-truth choice. The glitch-bridge demo is gone; Elara's first spell is now the cart.
- **Broken Mile:** the flickering tree, the passenger manifest, the cart and Elara's arm (ask, or
  say nothing), Data Vision labels, and the guardian.
  - **First Root Access edit:** change its target filter from ALL to FRACTURE_ENTITIES, turn its
    aggression down, or refuse and fight. Each choice gets its own reaction.
- **Oakhaven:**
  - **Arrival:** Bran and the road ledger (the Northfall entry), then stew at Elara's, with each
    question asked once.
  - **A normal afternoon:** Old Fen, Jessa, Tull and Wenna's water argument, Pebbles the chicken,
    the child's lost wooden sword ("my uncle Aldric's a knight"), Mara's shop and the Whispering
    Stone.
  - **The alarm** comes after three conversations, or sooner if you walk to the north field or
    the bridge. Then the uphill water (two edits or digging by hand) and the boar (fight, calm it
    or rebuild its nest).
  - **The bridge deadline:** fix it, keep people off it, or leave it.
- **Aldric:**
  - **Fight:** "Uncle Aldric!" and "Someone who should be dead", then the fight with barks taken
    from the data file.
  - **Decision:** kill (and how Kaelen owns it), spare, or purge (with a confirmation).
- **The chapter close:** Fragment One's memory flash, the bridge falling if you didn't fix it
  (whether anyone was hurt depends on whether you warned them), the village meeting (tell everyone,
  tell the council, or say it's handled), and Elara packing. The joining line depends on her trust.
- **Staged for now:** the boar, the guardian, the slime and the shrine are still staged, not
  playable fights or rooms.
- **Fixed:** in the village, walking to the bridge between two north-field conversations could
  leave the village mid-sequence.
- **Tests:** `tests/chapter1_route_test.gd` (33 checks, in CI) plays New Game through the Chapter 1
  ending on two choice paths, plus a free-roam afternoon.

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
