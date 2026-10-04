# Aethelgard — Full Code Review & AAA Foundation Plan

Review date: 2026-10-04 · Godot 4.6.3 · commit `6468280` · read-only review (no project files changed)

**Scope.** Every line was read in all ~135 gameplay scripts (≈65k lines), all 74 `.tscn` files, 5 shaders,
`project.godot`, `export_presets.cfg` and `.gitignore`. All 75 tooling `.gd` probes under `docs/` were read
too. The 10 Python tools were pattern-scanned for dangerous operations; they were not read line by line.
Image content was not reviewed, because the sprites are temporary.

**Method.** 12 parallel reviewers each owned one slice. Several ran headless Godot probes in scratch
directories to confirm behaviour at runtime. The lead re-read the code behind every finding marked **✔**.
Findings marked *(probe)* were reproduced in headless Godot. Everything else is static analysis with exact
line references.

**Relationship to `AUDIT_AND_FIX_PLAN.md`.** This report supersedes it. The audit's fixes were
re-verified; see §5. Several "FIXED" items are only partly fixed, and two audit claims were wrong.

---

## 1. Verdict

**Foundation level: 3/10. This is a late prototype with wide feature coverage and a weak core.**

The project has many systems: combat with coyote time, buffers, cancels and hitstop; Root Access;
corruption; DDA; crafting; shops; quests; achievements; free travel; NG+; 10 chapters; and
multiple endings. The individual ideas are often good. The problem is the layer underneath them.
There is no single owner for pause, time scale, game state, input focus, scene hand-off, saving or
story progression. Every feature writes those globals directly, so the features break each other.

What a real playthrough does today:

| Step | What happens |
|---|---|
| New Game | Goes to the opening hook, then **straight to the overworld**. The prologue, crash, crater and **Elara** are skipped. Only NG+ gets the full route. ✔ |
| Talk to the first NPC in Oakhaven | `DialogueManager.is_active` is never cleared and the **player can never move again**. The only escape is world-map fast travel. ✔ *(probe)* |
| Chapter 2 | Clock Tower: the player spawns **sealed in a box**. Underground: the boss chamber is **sealed**. The admin boss can be **skipped with ESC**. Both cutscenes may render **black**: an opaque `ScreenTransition` ColorRect covers the characters. ✔ (static; not rendered) |
| Chapter 3 → 4 | **Hard stop.** Beating SOVEREIGN sets only `ch3_complete`. Only the unreachable `ch3_ending` writes `ch4_unlocked`. ✔ |
| Chapters 4–10 | Reachable **only through debug Chapter Select**. About 27 of 74 scenes are reachable in a real run. |
| Ending | `ch10_complete` and NG+ are **never written to disk**, because saves during a transition are rejected. ✔ |

None of this was caught because there is no automated test, nobody has written down a playthrough, and the
existing probes test scenes one at a time rather than the path between them.

---

## 2. Root causes (fix these and most findings disappear)

| # | Root cause | Symptoms it produces |
|---|---|---|
| R1 | **Nobody owns `get_tree().paused`, `Engine.time_scale`, `GameState` or input focus.** About 70 manual `change_state` calls. ESC is bound to both `pause_menu` and `ui_cancel`, and 5+ `_input` handlers compete for it. | Pause opens on the main menu and in cutscenes. Root Access and pause unpause each other. Pause menus open and close in the same frame. The world map passes input through to gameplay. Hitstop and slowmo fight each other. |
| R2 | **Fire-and-forget coroutines on `SceneTreeTimer` and `process_frame`.** These ignore pause and cannot be cancelled. | Boss attacks land while paused. Stale attacks hit after a flinch, parry or phase change. The hazard trial damages the player while paused. Rewards land after a scene change. Scenes load already paused. |
| R3 | **Story progression is untyped string flags plus `set_meta` hand-offs, with no schema.** | Chapter 4 is unreachable. Flags have no reachable writer (Data Vision, Root Access unlock). `return_position` and `boss_fight_id` leak across scenes, causing wrong spawns and "CANNOT FLEE" forever. Re-entering a scene re-grants rewards. |
| R4 | **The save system rejects saves silently, and the UI says they succeeded.** | Every `_ready()` autosave is rejected because a transition is still in progress. Every checkpoint in DIALOGUE, COMBAT or CUTSCENE is rejected too. The ending is never saved. A corrupt save shows as "Empty", and the next save overwrites the good backup. |
| R5 | **Dialogue state is never closed.** `say()` sets `is_active` and only `hide_dialogue()` clears it. Regions and chapters 3–10 never call it. A skip silently answers choices with option 0. | Permanent freeze after talking to any region NPC. The pause menu is unreachable in chapters 4–10. ESC in the final scene silently picks **Destroy**. |
| R6 | **The world is built in `_ready()` from ColorRects. Hitboxes, colliders and offsets are sized from placeholder rects.** | Regions have no collision. Layouts change on every load because of unseeded `randi`. Most of the art-swap risks in §6 come from this. |
| R7 | **Duplication instead of shared systems.** 3 item databases, 2 transition systems, 6 full-screen flash implementations, 3 shake systems, 2 damage-number systems, 4 region scripts (≈50% identical), 29 near-identical chapter scenes (structural similarity 0.83–0.93). | Fixes have to be applied N times, and some copies get missed. |
| R8 | **No tests, no CI, no playthrough logs.** The only smoke probe can overwrite the player's real autosave (slot 99). | Every finding in this report. |

---

## 3. CRITICAL — the game breaks, softlocks or loses saves

| # | Where | Problem → consequence |
|---|---|---|
| C1 | `regions/*.gd` (oak 921/963, iron 869/884, wastes 788/806, late hub 832/954), `dialogue_manager.gd:148,244`, `player_topdown.gd:190` | `is_active` is never cleared after region dialogue → **the player is frozen permanently** after any NPC, lore, secret or farming interaction. ✔ *(probe)* |
| C2 | `fractured_wastes_region.gd:338-345` | The storm calls `say()` every 20–45 s without hiding it → the player freezes in the storm, which drains HP to 1. *(probe)* |
| C3 | `main_menu.gd:115-125`, `ch1_opening_crash_site_hook.gd:466-486` | The public New Game skips the prologue, crater and **Elara meeting**. The Elara flags are read in about 80 places and are always false. The P0-1 fix only helps NG+ players. ✔ |
| C4 | `ch3_ironhold_departure.gd:124`, `ch3_fractured_wastes.gd:108-122`, `sovereign_boss.gd:743` | **Chapter 3 is a dead end.** `ch4_unlocked` and `current_chapter=4` are written only in the unreachable `ch3_ending`. Chapters 4–10, 5 source keys and every ending need debug Chapter Select. ✔ |
| C5 | `ch2_clock_tower.gd:117-121` | Every floor is a full-width slab with no gaps, so the player spawns sealed in floor 1. The boss can't be reached and the gate stays forever. |
| C6 | `ch2_underground_network.gd:114-117` | The boss chamber is a closed box, so the Data Wraith, `source_key_fragment_2` and the Wraith choice can only be reached through the melee-through-walls bug. |
| C7 | `ch2_administrator_boss.gd:513-518` | Pressing ESC before the boss spawns skips the Chapter 2 final boss. `ch2_administrator_proxy_defeated` is never set. |
| C8 | `scenes/chapter2/ironhold_gate.tscn:37-44`, `seraphina_encounter.tscn` | The `ScreenTransition` node is an opaque black ColorRect on layer 0, drawn over CharactersLayer. The script only fades its child, never itself. ✔ Static analysis says both Ch2 cutscenes render black with only dialogue visible; nobody has seen it rendered. |
| C9 | `game_manager.gd:1373` + `scene_transition_manager.gd:94→148` | `is_transitioning` stays true through the new scene's `_ready`, so **every `_ready()` autosave is rejected**. That is about 30 scenes, including `ch10_ending`. **The game's completion and NG+ are never saved.** ✔ *(probe)* |
| C10 | `game_manager.gd:1702` | `auto_save()` refuses DIALOGUE, COMBAT and CUTSCENE, which are exactly the states its checkpoints run in. Chapter 2 end, the 5 Archive floors, the boss-defeat saves and the Ch2 finale are lost. "Saving…" and its sound still play. ✔ |
| C11 | `game_manager.gd:1678`, `:1824` | A corrupt save shows as "Empty" with no Load button. The next save copies the corrupt file **over the good `.bak`** without checking it, and the save is gone for good. ✔ |
| C12 | `pause_screen.gd:102-113` + `game_manager.gd:1368` | ESC on the **main menu** opens pause, and the Save Slot buttons work there, so a real save can be overwritten with blank default state. ✔ *(probe)* |
| C13 | `dialogue_manager.gd:346,357-366` | After a skip (ESC×2, or holding TAB, which is also Data Vision), **every later `show_choices` returns 0 without being shown**. That silently picks Trust Elara, Spare the Knight, Destroy SOVEREIGN, and so on. *(probe)* |
| C14 | `sovereign_boss.gd:473-487` | Phase 4 adds +5 corruption **every attempt with no cap**; `MAX_OVERRIDE_ATTEMPTS` only appears in the text ("ATTEMPT 7/3"). A long phase ends in a 100%-corruption game over. ✔ |
| C15 | `phase_spider.gd:89-90,120-133` | The spider jumps to the ceiling while chasing and never comes back down, so it can't be killed and the encounter or arena can't be won. ✔ *(probe)* |
| C16 | `combat_arena.tscn:21-30` | The arena has no walls and no enemy kill plane. An enemy knocked off the edge falls forever and the fight can't end; boss fights block fleeing. |
| C17 | `combat_arena.gd:670-700` | The Root Access gravity SpinBox has its default range 0–100. With gravity 0, a hit launches the enemy upward forever, which softlocks boss mode. *(probe)* |
| C18 | `player_combat.gd:545-546,599-600` | `flip_h` is set on the node named "Sprite". With no art loaded, that node is a ColorRect, the script errors, and **the player cannot move horizontally**. Deleting the temporary sprites triggers this. ✔ *(probe)* |
| C19 | `docs/visual_review/phase10mm/phase10mm_validation.gd` | The best smoke test loads `underground_network`, which autosaves into the developer's **real slot 99**. |

---

## 4. HIGH — wrong gameplay, exploits, state leaks (grouped by system)

### 4.1 Save / load / state
- `game_manager.gd:1387,1616` — A save stores only the scene path, and loading replays the scene from
  `_ready` with no claimed-reward guard. **`ch4_null_court` gives +350 XP / +150 gold on every reload.**
- `game_manager.gd:1438-1463` — The "atomic" save isn't atomic on Windows. A missing main save never
  falls back to the `.bak`, and a checksum mismatch only logs a warning.
- `game_manager.gd:517-553` — NG+ re-applies choice buffs that are already baked into the stats, so
  **stats grow every cycle**. NG+ resets XP to 0 but keeps the level, so the XP bar stays empty.
  `main_menu.gd:77-113`: after a fresh launch, NG+ copies default in-memory state (level 1).
- `game_manager.gd:1639` — Load restores the saved state *after* the scene's `_ready`. That can leave
  the game in DIALOGUE with no dialogue running (map, encounters and autosave disabled), or in
  EXPLORATION in the middle of a trial.
- `game_manager.gd:1616-1621` — If the saved scene is missing, the state is loaded but the scene doesn't
  change, and load returns true.
- `game_manager.gd:1080` + `combat_arena.gd:485-519` — Every boss death pays up to 30% of the boss's
  rewards, so **dying is farmable**.
- Metas `return_position`, `boss_fight_id`, `boss_return_scene`, `pending_encounter` and others are never
  cleared by reset or load. Consequences: wrong spawns (Ironhold first arrival lands in the Clock Tower
  district) and **"CANNOT FLEE" in every encounter** after the admin gate.
- `game_over.gd:112-129` — "Load Last Save" prefers slot 99 and never compares timestamps, so it can
  load an older save. `main_menu.gd:313-344` — "Del" has no confirmation and also deletes `.bak`.

### 4.2 Pause, input, menus
- `pause_screen.gd:108-111` — looks for `/root/CutsceneManager`, which never exists, so the cutscene
  block always clears and pause opens during every cutscene. ✔ (`shop_system.gd:482` has the same
  dead lookup.)
- `root_access_panel.gd`, `pause_screen.gd`, `shop_system.gd` each write `get_tree().paused` directly,
  so opening one modal can unpause another.
- `world_map_ui.gd:117-159` — The world map isn't modal. Movement, F, ESC and random encounters all
  pass through it, and you can fast-travel out of the middle of a boss fight
  (`ch2_underground_network.gd:17`).
- Chapter 3 scripts call `PauseScreen.toggle_pause()` on `ui_cancel`, so pause opens and closes in the
  same press.
- `status_window.gd:53-56` — The status window can't be closed if it was opened before Oakhaven
  flags existed, which blocks pause and shops.
- `ch1_oakhaven_village.gd:441` — `ShopSystem.open_shop()` can silently refuse while the caller
  awaits `shop_closed` forever, which softlocks the shop.
- `main_menu.gd` — It never calls `grab_focus`, so menus can't be used with keyboard or pad alone.
  Rebinding loses alternate keys, and display and text-speed settings are saved but never loaded.
- `credits_screen.gd:200-232` — The first time Credits opens each session, it closes instantly.
  *(probe)*

### 4.3 Economy & items
- `inventory_system.gd:419-448` — Equip and unequip ignore the result of `add_item`, so items with
  max stack 1 are **destroyed**. *(probe)*
- `drop_manager.gd:60-70` + `enemy_base.gd:1640` — **Every kill pays gold twice**: once directly and
  once as a pickup.
- `crafting_system.gd` + `shop_system.gd:808` — Crafting then selling is an infinite gold source
  (2 ore worth 24 → a sword that sells for 100).
- `pause_screen.gd:254-270` — Potions can be used from the paused menu during combat, giving
  unlimited risk-free healing. In exploration they don't work at all.
- There are three item databases with conflicting prices and names (`inventory_system`,
  `shop_system`, `crafting_system`). `ItemResource` is unused.
- `perfect_delete_charges` is never refilled, and the buff that "recharges faster" acts on nothing.

### 4.4 Combat — player & arena
- Dash i-frames last 0.41 s but the cooldown is 0.34 s, so **timed dashes give permanent
  invulnerability** (`player_combat.gd:363,1092`).
- `player_combat.gd:510` — `velocity.x *= speed_multiplier` runs every frame. A 2.0× zone launches the
  player at thousands of px/s, and a 0.4× zone actually settles at 0.17×.
- Melee only hits when the enemy's **origin point** is inside the slash rect. Grounded enemies whose
  origin is at their feet are missed, and pogo is impossible on large enemies (`:756-768`).
- The player is frozen during dialogue but enemies are not, so "AMBUSH!" lines give enemies free hits.
- `combat_arena.gd:724-782` — Perfect Delete has no in-progress guard. Pressing X repeatedly pays
  out the encounter 2–3×, and on a boss it spends a charge and does nothing.
- Root Access exposes `current_health` (range 0..max), so **any boss can be killed instantly** for
  2–5% corruption. `is_hostile=false` makes regular enemies passive but still pays full rewards.
  *(probe)*
- `arena_manager.gd:165` — `abort_arena()` has no callers, so the win streak never resets and the
  2.5× reward multiplier is permanent.
- The HP bar's "smooth lerp" starts at 0 and only advances on events, so it shows near-empty at
  full HP.
- Opening Root Access during a death or victory window changes scene **while paused**, so the next
  scene loads frozen.

### 4.5 Enemies & bosses
- Every enemy writes `movement_speed`, `gravity_scale` and similar fields before `super._ready()`.
  That triggers the hack setters, so **every enemy spawns with `is_hacked=true`**, "HACKED" popups
  and a permanent pink tint. *(probe)*
- 12 enemy subclasses override `_ai_behavior` without calling super, so `is_hostile=false` does
  nothing once they're engaged.
- Boss phase changes and retries set **absolute** stats, discarding zone, NG+ and DDA scaling, so
  bosses get weaker each phase (Clockwork contact damage 134→50). *(probe)*
- Bosses inherit generic hitstun, and pogo every 0.2 s stun-locks them, freezing all of their timers.
- In-flight boss attack coroutines are never cancelled by flinch, parry, phase change or retry.
- `enemy_base.gd:717` calls `AssetManager.get_asset()`, which doesn't exist, so **ranged enemies never
  fire**. *(probe)*
- `corruption_elemental.gd:101` adds 2.4% corruption per second just from standing near it.
- `administrator_enforcer` (the 75%-corruption punishment) spawns with no sprite and no collision. It
  is invisible and falls forever.
- `end_boss_fight()` is called twice for the Knight and the Administrator, and never for SOVEREIGN.
  Administrator corruption is applied twice (+16 while the text says +8).

### 4.6 Story & progression
- `ch1_path_to_oakhaven.gd:580,880` are the only real writers of `ch1_data_vision_unlocked` and
  `root_access_unlocked`, and that scene is skipped. **Data Vision stays locked for the whole game.**
- `ironhold_region.gd:505-512` — The admin gate has no prerequisite, so all Chapter 2 spokes are
  optional. It's also replayable on free-travel revisits, which re-grants 1200 XP / 600 gold, re-runs
  the Seraphina choice, and **drags `current_chapter` back to 3**.
- Source key #2 can be missed, and Synthesis requires 7/7, so the best ending can be **permanently
  lost without any warning**. Many lines hardcode "7/7".
- Every ending is labelled "TRUE ENDING". The final quiz, the kernel trial and Archive Tide all have
  option 0 correct 3 out of 3 times; the other "trials" can't be failed.
- Chapter 4–5 route flags aren't exclusive, so replays stack conflicting flags.
- `ch10_sovereign_confrontation.gd:86` plays `"final_boss"`, which doesn't exist, so the final fight
  uses the previous track.
- `get_revival_scene` only knows chapters 1–3, so a death in chapters 4–10 revives you in the
  Fractured Wastes.
- `fractured_wastes_region.gd:557-590` — SOVEREIGN, the final antagonist, is an optional Chapter 3
  arena boss.
- Region Lyra overwrites the Chapter 3 Lyra choice on every 4th conversation.

### 4.7 Effects, cutscenes, camera, audio
- `cutscene_manager.gd:898` — `stop_cutscene()` emits finished while beats are still running. After a
  skip, `GameState` can stay stuck in CUTSCENE, which blocks combat input and saving.
- `tween_animator.gd:505-529` — Getting hit again during a flash captures the flash colour as the
  "original", so the **sprite stays tinted red or white permanently**.
- `enemy_base.gd:816,928` tweens the **physics body** (position, scale, rotation) instead of the
  sprite. This cancels knockback and scales the collision shape down to 0.02.
- `cinematic_camera.gd:146` — The shake decay overshoots, so "massive" shakes last 1 frame.
  `move_to` and `zoom_to` ignore their duration, so the 39 authored durations are dead.
  `ignore_rotation` defaults to true, so dutch angles do nothing. *(probe)*
- `game_juice.gd` — `add_trauma` only exists on cinematic cameras, so **all combat screen shake is a
  no-op**.
- `vfx_library.gd:857` — Full-screen flashes are 0×0 under Node2D roots. *(probe)*
- `asset_manager.gd:2011-2099` — VFX textures are never loaded, so all 8 `spawn_oneshot_vfx` calls do
  nothing. *(probe)*
- `asset_manager.gd:1514`, `background_manager.gd:116` — `FileAccess.file_exists("res://…png")`
  returns false in exported builds, so **all props and decals disappear in the .exe**.
- `sfx_manager.gd:903` — Any pitch variation re-synthesises audio on the main thread
  (25–295 ms hitches at every swing, kill and boss death). *(measured)*
- There is no audio bus layout, so SFX volume gets baked into cached audio and the slider breaks.
- `music_manager.gd` — Dynamic music overrides explicitly chosen tracks within 1 s, and the music
  clock slows during hitstop.
- `glitch_overlay.gd` — `flash_glitch` and `trigger_glitch` last at most 66 ms whatever duration
  you pass (54 story call sites). *(probe)*

---

## 5. Verification of the previous audit's "FIXED" items

| Item | Status | Notes |
|---|---|---|
| P0-1 Elara meeting relinked | **Code OK, ineffective** | The crater → Elara chain works, but New Game no longer goes through the crater (C3). |
| P0-2 Ironhold story gates | **Partly broken** | Clock Tower and Underground can't be completed (C5, C6). Spokes are optional. The Clockwork boss can be fought twice if you do the arena first. The admin gate leaks `boss_fight_id`. Replayable on revisit. "71/74 reachable" counts scenes that are referenced somewhere, not scenes you can finish; a real playthrough reaches about 27/74. |
| P0-3 max_hp inflation | OK | It does cause NG+ stacking (§4.1). |
| P0-4 load lock | OK | A runtime type error inside `load_game` can still leave the lock set. |
| P0-5 Root Access freeze in arena | Partly | The panel works now. It can still open during death or victory, and the scene can change while paused. |
| P0-6 `change_background` | Partly broken | Repeating the same location stacks layers. A `.tscn` path as the location produces the "Unknown location" grey screen. |
| P0-7 "no version control" | Correctly retracted | — |
| P1-2, P1-3, P1-8 | OK | — |
| P1-6 DDA | OK as coded | The audit's correction is wrong: **one** hit before the first kill floors DDA, not four. Blocked chip damage also counts as a hit. |
| P1-7 `_attack_token` | OK, incomplete | Jump, double-jump and dash cancels don't bump the token. Spell coroutines have the same stale-state problem. |
| P1-9 collision layers | OK | Melee still hits through walls. Projectiles ignore walls. |
| P1-10 `reset_game` | Incomplete | LoreJournal, the quest HUD, metas, UIStack, pause abilities and RES load state are still not reset. |
| P1-11 choice buffs | OK | Clearing a flag doesn't remove the party member. 17 advertised abilities still have no callers. |
| P2-5 "CRT needs BackBufferCopy" | **Audit wrong** | Godot 4 copies the screen automatically. The real bug is draw order plus the procedural background covering the CRT layer. |
| P2-7 "camera is the best file" | **Audit overstated** | The follow, dead-zone and bounds code has zero callers. |

---

## 6. Art swap to Pixel Art Engine (PAE) — readiness: 2/10

**PAE exports** a PNG sheet with fixed cells (one row per animation, one column per step) plus
`pae-sheet` v1 JSON. The JSON has `frameWidth/Height`, and for each animation `{view, loop,
frames:[{x,y,w,h,durationMs}]}`, plus an optional `tiles{size,columns,map}`. **It contains no pivot,
no anchor and no hitbox data.**

**What happens today if you delete the temporary sprites:** there is no crash at load, and everything
falls back to ColorRects. Two exceptions:
1. **The player can't move horizontally in combat (C18).**
2. Many fallbacks are silent (72 of 363 asset paths are already missing, and nothing reports it).

Also delete the `.png.import` files, or the cached `.ctex` files may keep "deleted" art alive.

**Why the current loader can't read PAE output:**
- No JSON is parsed anywhere.
- Paths are hardcoded per character.
- Frame count is hardcoded to 4, and cell sizes per call site (64/32/96/48).
- Row order is fixed by const tables.
- `durationMs` is ignored, and everything plays at a uniform fps.
- Direction names differ (`down/up/left/right` vs PAE's `south/north/west/east`; side views use
  flip instead of `side_left`).
- Pivots are inconsistent: centre, −16, −24, −48 and −8 offsets are used in different places.
- Scales are non-integer, which makes pixel art shimmer.
- `fix_alpha_border=true` on all 1518 imports breaks PAE's exact RGBA.
- Hitboxes and attack timings are hardcoded constants, independent of animation frames.

**Importer design (build this before making any art):**
1. **Offline import.** Write an `EditorImportPlugin` (or a `@tool` script) for `*.pae.json` with
   `format=="pae-sheet"`. It should validate the version, the sheet size against the PNG, and that
   every rect is in bounds.
2. **SpriteFrames output.** Generate a `SpriteFrames.tres` with one `AtlasTexture` per frame, all
   sharing one sheet texture (no per-frame `ImageTexture`). Use animation speed 1.0 and per-frame
   duration `durationMs/1000`, and take `loop` from the JSON.
3. **Clip naming.** Name clips `<anim>_<dir>` with `south→down, north→up, east/side_right→right,
   west/side_left→left, none→""`.
4. **Sidecar file.** PAE has no pivot or hitbox data, so add a `<name>.rig.json` with a feet pivot
   (bottom-centre by default, auto-detected from the lowest opaque row), hurtbox rects, and
   per-attack active-frame hitboxes.
5. **Import settings.** Lossless, no mipmaps, `fix_alpha_border=false`, nearest filtering.
6. **Tilesets.** Turn `tiles.size` into a `TileSet.tres` and `tiles.map` into a `TileMapLayer` scene.
7. **Registry.** A manifest maps game IDs to `.tres` files. AssetManager loads by ID, warns once per
   missing ID, and shows a **magenta checkerboard** in debug builds instead of silently using a
   ColorRect.
8. **One `CharacterVisual` component.** It handles pivot, integer scale and the state+facing → clip
   lookup with fallbacks, and exposes clip length and active frames to combat. It replaces the 4
   animation-name contracts and the 3 parallel sprite systems.
9. **Pixel-perfect setup.**
   - `scale_mode=integer` and `snap_2d_transforms_to_pixel`.
   - Integer camera zooms (today 2.2 and 1.8 are used).
   - Use the Compatibility renderer, or document why Forward+ is needed. The Web export silently
     uses Compatibility, so the look differs between builds.
10. **Export filters.** Add `include_filter="*.json"` so the sidecars ship in exports.

---

## 7. Foundation scorecard (1–10, averaged from the 12 slice reviews)

| Subsystem | Arch | Robust | Data-driven | Testable | Perf | Art-ready |
|---|---|---|---|---|---|---|
| Core state / save / dialogue | 3 | 2 | 2 | 2 | 6 | 4 |
| Economy / items / menus | 3 | 3 | 2 | 2 | 5 | 2 |
| Asset pipeline / audio | 3 | 4 | 3 | 3 | 3 | 2 |
| Player combat | 3 | 3 | 2 | 3 | 5 | 2 |
| Enemies / bosses | 3 | 3 | 2–3 | 2 | 6 | 2 |
| Effects / cutscenes / camera | 3 | 2 | 4 | 2 | 5 | 2 |
| Chapters 1–10 | 3 | 2–3 | 2 | 2 | 5–6 | 2 |
| Regions / config | 3 | 2 | 3 | 2 | 6 | 2 |
| Tooling / CI / docs / repo | — | — | — | 2 (tests), 1 (CI) | — | — |

Two other numbers: game-feel infrastructure 5/10 (it has buffers, coyote time and cancels, but no
frame data), and cinematic tooling 2/10 (a designer can't author a cutscene without writing code).

**Strengths to keep:**
- The movement feel layer: coyote time, jump, attack and dash buffers, variable jump, apex hang.
- The spritesheet-to-SpriteFrames idea in AssetManager.
- The production-then-fallback slot layering, with deduplicated warnings.
- The `glitch_effect` shader.
- The Chapter 1–2 dialogue voice.
- The Null Court thesis (Chapters 4–10).
- The `late_game_hazard_trial` concept.
- The a2_8 first-minute probes and `phase10mm_validation`, which can become a real test suite.

---

## 8. Roadmap to an AAA-grade foundation

"AAA foundation" here means **studio-grade architecture**: single ownership of global state, data-driven
content, deterministic saves, cancellable gameplay actions, an art pipeline you can import into without
touching code, and automated verification. It does not mean AAA content volume. These are separate
problems; the second one comes down to scope, which §9 covers.

**Strategy recommendation: rebuild the core, then migrate a vertical slice onto it.** Don't patch
roughly 400 findings across 10 chapters. Most of them come from R1–R8. Fixing the roots once and moving
content onto the new core is cheaper than fixing every symptom in every copy. Patch only the Phase 0
items in the old code.

### Phase 0 — Stop-ship fixes on the current code (about 1 week)
Make the current build playable end to end so that the playtest is real.
1. C1/C2 — make `say()` callers end their dialogue, either by having `say()` auto-hide when no further
   line is queued, or with a scoped `await DialogueManager.run(lines)`.
2. C13 — skipping must never answer a choice; remove the 120 s auto-pick.
3. C9/C10/C11 — save: queue a checkpoint until the transition or dialogue ends instead of rejecting
   it; make the UI report the real result; validate files before backing them up; treat a corrupt
   save as "corrupt — restore backup", not "Empty".
4. C12 + pause lookups — no pause or saving in MENU; drop the dead `/root/CutsceneManager` lookup.
5. C3/C4 — route New Game through the full Chapter 1, or move Elara into the hook path; add the
   Chapter 3 → 4 exit (write `ch4_unlocked` and `current_chapter=4` on SOVEREIGN defeat, or add an
   exit gate to the Wastes region).
6. C5–C8 — open the Clock Tower floors and the Underground chamber; guard the admin ESC skip; fix the
   black `ScreenTransition` colour.
7. C14–C17 — cap SOVEREIGN override attempts; fix the spider ceiling lock; add arena walls and an
   enemy kill plane; clamp Root Access ranges and remove `current_health` from bosses.
8. C18 — guard `flip_h` with `if _sprite is Sprite2D or _sprite is AnimatedSprite2D`. **Do this before
   deleting any sprites.**
9. Clear `return_position`, `boss_fight_id` and the other metas on every consume, reset and load.
10. Then **play from New Game to the credits once and write down everything that goes wrong.**

### Phase 1 — The spine (2–4 weeks)
| Service | Replaces | Contract |
|---|---|---|
| **ContextStack** (input/pause/time) | Every direct write to `paused` and `time_scale`, UIStack, the 70 `change_state` calls | Push/pop contexts (`Gameplay`, `Dialogue`, `Menu`, `Cutscene`, `Map`, `RootAccess`) that declare `pauses_tree`, `blocks_input` and `allowed_actions`. Only this service writes `paused`. `time_scale` is a priority stack (hitstop > slowmo > wobble). It consumes the input that opened a context. |
| **TransitionService** | 2 transition systems, all `set_meta` hand-offs | `go(path, TravelContext{spawn_id, return_to, boss_id})`, consumed exactly once by the destination. It has a queue and re-entrancy guard, an input lock, tweens that run while paused and ignore `time_scale`, and resets `paused`/`time_scale` at the midpoint. |
| **SaveService** | `game_manager.gd` save/load | A versioned schema. Each autoload implements `reset_for_new_game()`, `to_save()` and `from_save()` (typed, with validation). Writes go to a temp file, which is flushed, re-parsed and renamed. N rotating backups, each validated. Any failure falls back to a backup. `request_checkpoint()` is deferred until it's safe and returns its result. The user-data directory can be injected for tests. |
| **StoryGraph + FlagRegistry + RewardLedger** | Loose string flags, chapter routing in 3 places | StoryGraph: a `.tres` graph of story nodes (scene, requires, sets, exits). FlagRegistry: `StringName` constants with exclusive groups. RewardLedger: `grant_once(reward_id)`, persisted. Boot-time validation checks that every read has a writer and every flag has a reachable writer. |
| **DialogueRunner** | 29 hand-built chapter scenes and the dialogue held in GDScript arrays | Dialogue as data: the Dialogue Manager plugin by Nathan Hoad, which the blueprint already names, or JSON. Stable line and speaker IDs, a speaker registry that maps IDs to portraits, companion gating via `requires:`. Skipping fast-forwards text only. |
| **Stats model** | Stats baked into `player_stats` | `final = base + level + Σ modifiers` (equipment, buffs, quests, corruption), recomputed whenever modifiers change. Defense either reduces damage or is deleted. MP is either spent or deleted. |

### Phase 2 — Combat foundation (3–5 weeks, parallel with Phase 3)
- Split `player_combat.gd` (2,639 lines) into a **node state machine**: Locomotion, Air, Attack, Dash,
  Parry, Block, Heal, Cast, Hurt and Dead. Each state ticks in `_physics_process` with no `await`
  timers, which removes the race-condition bug class entirely.
- **MoveData / AttackSpec `.tres`**: animation name, active-frame range (from PAE `durationMs`),
  hitbox rects per frame (from the rig sidecar), cancel windows, damage/soul/hitstop/knockback.
- **Hitbox/Hurtbox Area2D components** on named physics layers, tested shape against shape with a
  hit registry and line-of-sight.
- **EnemyDef / BossDef / PhaseDef `.tres`**. A shared `BossController` with poise instead of hitstun,
  phase modifiers applied as multipliers on scaled stats, and exactly one `end_boss_fight`.
- **CombatEncounter**: `Intro → Fighting → Resolved{Victory|Defeat|Fled}` with one idempotent
  `resolve()`. Gate Perfect Delete and Root Access on `Fighting`. Enemies freeze during dialogue.
  Arena bounds and a kill plane.
- **Root Access** built from per-enemy capability definitions with safe ranges; bosses can't edit HP.
  Use it as a slowed-time combat state rather than tree pause.
- **FeelService** with one shake/trauma component on every camera, one pooled damage-number system,
  and GPUParticles2D VFX presets pooled through ObjectPool. Delete GameJuice's failsafe, the duplicate
  flash, shake and number systems, and TweenAnimator (after the art lands).

### Phase 3 — Art pipeline for PAE (1–2 weeks to build, then ongoing)
Build §6 items 1–10. Then prove it on **one scene**: Oakhaven as an editor-authored `.tscn` with
TileMapLayers, terrain sets and collision; Marker2D spawns and exits; Kaelen, Elara and 2 NPCs as PAE
SpriteFrames; one music track and about 10 SFX as files; one font; and a shared `Theme`. Compare it
side by side with the current version, and only then convert other scenes.

### Phase 4 — Content as data (ongoing)
- One `ItemDefinition` database (shops and recipes reference it), with a sell-price rule that removes
  arbitrage.
- Quests, achievements, lore and choice buffs as `.tres`, with every ID validated at boot.
- Menus and HUD as authored scenes with focus neighbours, prompts generated from InputMap, and
  gamepad bindings.
- Regions: one `RegionBase` plus an `Interactable` component (kind, priority, `requires_flag`,
  `completed_flag`). Delete the 4 duplicated scripts and the unseeded random layout.

### Phase 5 — Production infrastructure (start in Phase 1, keep forever)
- **gdUnit4 (or GUT)** in `res://tests/`. Convert `phase10mm_validation`, the a2_8 probes and the
  asset-slot checks into tests, and delete about 50 stale or duplicate probes.
- A **playthrough bot**: a headless test that drives `_advance_requested` and `_choice_result` from
  New Game to every ending. It should assert scene reachability, all 7 keys, save round-trips and
  NG+ persistence. That one test would have caught C3, C4, C5, C6, C9, C10 and C13.
- **CI** (GitHub Actions): import, boot, scene-load sweep that fails on any `push_error`, tests,
  `gdlint`/`gdformat`, `git diff --check`.
- **Repo**:
  - Git LFS for PNGs and other binaries (git-lfs 3.5 is installed but unused; 207 MB tracked).
  - `.gdignore` in `docs/` and `assets/art_sources/`, and export `exclude_filter`, so the 127 MB of
    review art doesn't ship.
  - Commit `export_presets.cfg`.
  - Move the repo out of OneDrive.
  - Delete `Mysprites/`, the root logs and the duplicate `context.txt`.
- **Docs**: collapse 97 phase reports into one `CHANGELOG.md` plus a few ADRs, and rewrite the
  README (it currently says Godot 4.3, Space to interact, "no save/load"). Use descriptive commit
  messages.
- **project.godot**: named physics layers, `default_bus_layout.tres` (Master/Music/SFX/UI), joypad
  InputMap plus a remap UI, top-down `motion_mode=FLOATING`, valid UIDs for `splash_screen` and
  `opening_crash_site_hook`.

---

## 9. Scope check

AAA *architecture* is achievable solo in roughly 2–3 months of focused work. AAA *content* for
10 chapters is not. The engine is not the bottleneck; art, animation, audio and level design per scene
are. A sensible target is:
**prologue + Chapter 1 + Ironhold, rebuilt on the Phase 1–3 foundation, with real PAE art, finished
to a standard you would show anyone.** That makes a strong portfolio or capstone piece and a credible
pitch. Chapters 4–10, which hold the original Null Court idea, can then be added on a foundation that
won't break as content grows.

Before Phase 1, decide and write down how you will measure success. Examples:
- "A tester can finish the slice from New Game with zero softlocks."
- "Every save/load round-trip test passes."
- "Average session length X."
- "N of M playtesters can explain what Root Access does."

---

## Appendix — Medium/low findings by system (condensed)

**Core.**
- LoreJournal leaks between saves, and runtime lore loses its text on load.
- Quest `stat_boost` rewards are wiped by the next equipment recompute; 9 reward IDs don't exist.
- JSON loads ints as floats, so quest-state comparisons fail.
- Two completion formulas disagree.
- Completion-tracker bars render empty (0 px). *(probe)*
- `completion_100`, `all_quests` and `all_secrets` can't be unlocked.
- Toasts are parented to `/root` and drift off-screen with the camera.
- Turning subtitles off removes all story text (there is no audio).
- `achievements.save` is written non-atomically.
- The lore journal opens on raw `KEY_L` in any context.
- ObjectPool has zero callers but creates 39 nodes at boot.

**UI.**
- The breadcrumb arrow mapping is wrong, and the breadcrumb targets a constant (640,360).
- Status, pause and map are hardcoded to Chapters 1–2 and list non-existent regions.
- Key labels are hardcoded, so they're wrong after rebinding.
- "Press Space" in the level-up popup, but Space is jump.
- CompletionTracker opens behind the pause screen.
- The shop list rebuild loses keyboard focus.
- `InteractionPrompt` has zero callers but runs `_process`.

**Combat.**
- An uncharged release leaves `is_charging` stuck.
- i-frames are assigned rather than max'd.
- Hitstop stacks from 2–3 requests per hit.
- The GameJuice failsafe kills slowmo.
- The combo finisher plays `slash_1`.
- HUD buttons can receive focus, which injects phantom actions.
- "Fight again" only heals cosmetically.
- The damage multiplier lives in a VFX autoload.
- About 20 nodes are allocated per dash.
- Death tips show the wrong keys.
- Gravity ranges disagree in 3 places.

**Enemies.**
- The scale tweens on slime, rat and elemental shrink V2 sprites permanently.
- Flat special-attack damage ignores scaling.
- Teleports have no geometry check.
- Data-sprite clones never get the zone level and pay 3× XP.
- Projectiles, webs and gears freeze or leak when their owner dies.
- Corrupted Guard's counter can't be reacted to.
- Off-screen AI runs timers at 1/3 speed.
- Telegraph and hit-flash colours become permanent.
- AnimatedSprite2D enemies are double-flipped, so they face backwards.

**Encounters.**
- The zone is never cleared, so encounters fire inside story dungeons.
- The "DANGER" HUD persists into menus.
- Victory isn't cancellable and can pull the player out of the main menu; flee after victory
  double-transitions.
- Farming context survives death.
- The kill count is doubled.

**Cutscenes / camera / VFX.**
- 16 of the 25 beat types are unused or untested.
- Unknown beats and missing actors fail silently.
- The entrance tween is sequential (1.5× duration, no fade).
- `wipe_out` LEFT/UP only cover off-screen space.
- `ScreenTransition` is on layer 0 under the camera transform.
- `vfx_pickup_burst` is undefined.
- 36 of 58 TweenAnimator functions are unused.
- `cutscene_director.gd` (892 lines) and `cinematic_vfx.gd` are orphaned.

**Audio.**
- Pitch variation is applied twice.
- `play_positional` attenuates the wrong player.
- Note caps drop critical sounds.
- One AudioStreamPlayer is created per music note.
- `music.stop(fade)` kills the next track.
- Boss HP is read from the wrong field, so `boss_rage` never triggers.

**Background / shaders.**
- The procedural background covers the flight_707 CRT and particle layers.
- 7 locations have no `BG_ASSETS` key.
- The CRT shader overwrites R and B with raw samples (magenta edges).
- `filter_linear_mipmap` on screen textures.
- One TextureRect per tile (317 nodes).
- 1280×720 CPU gradients.
- About 150 ms of dead `set_pixel` parallax code.

**Regions.**
- Interactions re-run during open dialogue: 3 presses of F gave +150 gold instead of +50. *(probe)*
- Shops are shadowed by NPC talk radii.
- No collision at all.
- The Seraphina NPC is present before you meet her.
- Wastes lore never reaches the journal.
- "Storm map −30%" is not implemented.
- Region layouts are unseeded random and rebuilt on every load.
- The Mirror City floor is built with per-pixel image operations (69 ms).

**Chapters.**
- Chapter 3 `_ready` handlers never hide dialogue.
- About 46% of Chapter 2–3 lines are unreachable in normal play (city hub 717, dead Wastes code ~628,
  data_stream→ending chain 2,048).
- 78 of 87 late-game speakers have no colour or portrait entry.
- Synthesis needs 5 specific earlier picks and is first hinted at in Chapter 10.
- Menu "boss fights" in Chapter 3 can't be lost.
- Chapter 1: the Oakhaven boar fight is System text with +100 gold and no input.
- Chapter 1: NPCs replay full dialogue on every `body_entered`.
- Chapter 1: "+15 fragments" is announced but never granted.
- Chapter 1: the shatter skip loses the Aldric reward.

**Tooling / repo.**
- r1/r2/q1/q2 validators would fail today (stale).
- 13 probes always exit 0.
- More than 5k of the 10k tooling lines are copy-paste.
- The S3 generator hardcodes an absolute path and rewrites its own validator.
- `assets/generated` v1 is dead.
- The largest tracked file is a 9.6 MB stderr log.
- `context.txt` duplicates `Blueprint_and_roadmap.txt`.
- README, QUICKSTART and SCENE_SETUP_GUIDE are wrong about the engine version, controls and features.
