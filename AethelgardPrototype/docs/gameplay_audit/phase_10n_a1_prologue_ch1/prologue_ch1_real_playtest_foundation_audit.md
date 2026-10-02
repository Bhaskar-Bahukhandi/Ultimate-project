# PHASE 10N-A1 PROLOGUE / CHAPTER 1 REAL PLAYTEST FOUNDATION AUDIT

## 1. Executive verdict

- Is the opening retention-safe? **No.** `[HEADLESS RUNTIME EVIDENCE]` New Game reaches `res://scenes/prologue/flight_707.tscn`, and `[CODE EVIDENCE]` the route then runs long cinematic/prologue scenes before stable movement.
- Would a new player continue after 3 minutes? **Probably no.** `[INFERENCE]` The first minutes are dominated by splash, menu, title cards, plane dialogue, crash/system boot text, and not player-owned action.
- Would a new player continue after 20 minutes? **Unreliable.** `[INFERENCE]` A lore-invested player may continue, but the broader retention risk is high because reward, movement, combat, and objective clarity arrive late and inconsistently.
- Is the foundation strong enough to keep building chapters? **No, not before the opening route is reconciled.** `[CODE EVIDENCE]` Chapter 1 has both a curated cinematic chain and a merged overworld/Oakhaven region path, and those paths do not line up cleanly.
- Brutal one-sentence diagnosis: **The game opens like a lore demo and systems showcase, not like a playable RPG hook.** `[INFERENCE]`

## 2. Evidence classification

- What was live-played: **None.** `Live viewport unavailable — no true visual playtest claim`. `[NOT VALIDATED]`
- What was headless-run only: Godot version, short project boot, scene instantiation, fresh-start New Game route probe, scene node scans, and input movement probes. `[HEADLESS RUNTIME EVIDENCE]`
- What was screenshot-verified: **None.** Headless viewport capture failed for every scene with `failed_empty_image` / dummy renderer `Parameter "t" is null`. `[HEADLESS RUNTIME EVIDENCE]`
- What was code-inspected: `project.godot`, `scripts/ui/splash_screen.gd`, `scripts/main_menu.gd`, `scripts/prologue/flight_707_cinematic.gd`, `scripts/prologue/crash_sequence.gd`, `scripts/chapter1/*.gd`, `scripts/overworld/overworld.gd`, `scripts/regions/oakhaven_region.gd`, `scripts/exploration/player_topdown.gd`, `scripts/combat/player_combat.gd`, `scripts/dialogue_manager.gd`, `scripts/game_manager.gd`, `scripts/ui/pause_screen.gd`, `scripts/ui/progression_breadcrumb.gd`, inventory/crafting/shop systems, and scene transition code. `[CODE EVIDENCE]`
- What was inferred: retention risk, boredom points, pacing quality, player motivation, and whether players would continue. `[INFERENCE]`
- What was not validated: headed rendering, real visual glitch state, actual controller feel, true live combat, true dialogue advancement by hand, death/retry under player pressure, save/load from UI, and full Chapter 1 completion by play. `[NOT VALIDATED]`

## 3. Fresh-start route map

- Entry point: `project.godot` uses `run/main_scene="res://scenes/splash_screen.tscn"`. `[CODE EVIDENCE]`
- Splash: `scripts/ui/splash_screen.gd` shows a 3.0 second splash unless skipped. `[CODE EVIDENCE]`
- Main menu: `scripts/main_menu.gd::_on_new_game_pressed()` calls `GameManager.reset_game()` and transitions to `res://scenes/prologue/flight_707.tscn`. `[CODE EVIDENCE]`
- Fresh-start probe: calling the main menu New Game handler in headless runtime reached `res://scenes/prologue/flight_707.tscn` / `Flight707Cinematic`; flags remained false immediately after the call. `[HEADLESS RUNTIME EVIDENCE]`
- Prologue scene order: `flight_707.tscn` -> `crash_sequence.tscn` -> `glitch_crater_awakening.tscn`. `[CODE EVIDENCE]`
- Current first stable playable scene: likely `res://scenes/overworld/overworld.tscn`, because `scripts/chapter1/ch1_glitch_crater.gd::transition_to_elara_meeting()` currently transitions to the overworld after setting `ch1_awakening_complete` and `ch1_glitch_crater_complete`. `[CODE EVIDENCE]`
- Headless movement proof: `overworld.tscn`, `oakhaven_region.tscn`, and legacy `oakhaven_village.tscn` all loaded, found a player, and moved when `move_right` was pressed in headless runtime. `[HEADLESS RUNTIME EVIDENCE]`
- Objective order mismatch: `ProgressionBreadcrumb.OBJECTIVES` starts with blocker `tutorial_completed`, but the observed route sets `ch1_awakening_complete` / `ch1_glitch_crater_complete`; `tutorial_completed` is set in `ch1_tutorial_knight.gd`, far later. `[CODE EVIDENCE]`
- NPC/dialogue order: the newer active path appears to move from overworld into `scenes/regions/oakhaven_region.tscn`; the older cinematic chain `elara_meeting.tscn` -> `path_to_oakhaven.tscn` -> `oakhaven_village.tscn` exists but is not clearly on the fresh-start route. `[CODE EVIDENCE] [INFERENCE]`
- Combat/conflict order: memory-combat overlay in `ch1_glitch_crater.gd`, random/region traversal in overworld/Oakhaven, then tutorial knight from `oakhaven_region.gd::_enter_boss_arena()`. `[CODE EVIDENCE]`
- Save/checkpoint order: `GameManager.auto_save()` is called on tutorial knight defeat; manual saves are available through pause UI but blocked in combat/cutscene/game over. `[CODE EVIDENCE]`

## 4. First 3 minutes timeline

- 0-3 seconds: splash screen with studio/name text; player can skip, but this is not a meaningful game action. `[CODE EVIDENCE]`
- 3-8 seconds: main menu fade/animation and button discovery. `[CODE EVIDENCE]`
- After New Game: transition into `Flight707Cinematic`. `[HEADLESS RUNTIME EVIDENCE]`
- Flight 707 opening: title/subtitle fade, waits, scene fade, and cutscene dialogue before player-owned movement. `[CODE EVIDENCE]`
- Crash sequence: boot/system text sequence with skip support, still not stable play. `[CODE EVIDENCE]`
- Glitch crater: title, internal monologue, BSOD, fade, UI boot, status window, and only then a short memory-combat overlay. `[CODE EVIDENCE]`
- Exact quit-risk moment: the likely quit point is after pressing New Game and realizing the game is still not giving control, only more timed text and cinematic setup. `[INFERENCE]`
- Fastest hook fix: start in the crash site with control within 10 seconds, show one interactable broken object, one threatening anomaly, and one forced movement/dodge/action before any lore explanation. `[INFERENCE]`

## 5. First 20 minutes retention map

- Current experience: cinematic setup -> lore/system text -> limited memory combat -> overworld drop -> large region flow -> tutorial knight later. `[CODE EVIDENCE]`
- Dead zones: splash/menu/Flight 707/crash/glitch-crater title/boot/status sections stack into a long passive runway. `[CODE EVIDENCE] [INFERENCE]`
- Unclear goals: objective systems disagree: breadcrumbs say "Survive the crash site" until `tutorial_completed`, pause tickets say "Reach Oakhaven Village", overworld says enter Oakhaven gate, status window says "Path to Oakhaven" after `ch1_glitch_crater_complete`. `[CODE EVIDENCE]`
- Reward droughts: first meaningful XP is memory combat `+25` or `+10`, then later slime/root access, Oakhaven extras, and tutorial knight `+200 XP`/`+500G`; these are not front-loaded enough. `[CODE EVIDENCE] [INFERENCE]`
- Revised tighter sequence: 0-10s movement in crater, 10-40s first anomaly interaction, 40-90s first danger/dodge or attack, 90-150s Elara interruption or voice contact, 3-5 min first choice, 5-8 min first real reward, 8-12 min Oakhaven gate. `[INFERENCE]`

## 6. Visual/glitch QA

- Screenshots: none validated; every headless capture failed. `Live viewport unavailable — no true visual playtest claim`. `[HEADLESS RUNTIME EVIDENCE]`
- Placeholder/asset-demo risk: `flight_707`, `glitch_crater_awakening`, `elara_meeting`, and `path_to_oakhaven` contain many `ColorRect` procedural blocks and UI labels; without live screenshots this is not visual proof, but static scene structure strongly suggests placeholder presentation. `[STATIC SCENE EVIDENCE]`
- Missing production visual slots: headless load warned that Kaelen top-down, Kaelen combat, Elara, Tutorial Knight, environment prop atlas, and environment decal atlas fell back to generated assets. `[HEADLESS RUNTIME EVIDENCE]`
- Text encoding risk: static/headless labels include mojibake such as `â€”`, `â–²`, and malformed box/arrow glyphs in menu, status, auction, objective, and dialogue text. `[HEADLESS RUNTIME EVIDENCE] [CODE EVIDENCE]`
- UI density risk: Oakhaven scene headless scan found visible HUD, dialogue box labels, shop panel labels, auction panel labels, NPC labels, and controls text simultaneously in node data; live overlap is not validated but the scene is UI-heavy. `[HEADLESS RUNTIME EVIDENCE] [INFERENCE]`
- Interaction prompt risk: `player_topdown.gd` creates prompt range with a 50px circle and text `[F] Talk [E] Inspect`, but no live multi-angle prompt test occurred. `[CODE EVIDENCE] [NOT VALIDATED]`
- Camera risk: camera nodes exist in headless scans for prologue/chapter scenes and region scenes, but follow behavior was not live-validated. `[HEADLESS RUNTIME EVIDENCE]`
- Accepted baseline status: no Oakhaven/Ironhold/Fractured Wastes/Mirror City production baseline was modified or visually validated in live viewport. `[NOT VALIDATED]`

## 7. Brutal design critique

- Hook: too slow. A plane crash could be immediate danger, but it is delivered as cinematic text before agency. `[CODE EVIDENCE] [INFERENCE]`
- Interactivity: the first real micro-action is not early enough; pressing Space through dialogue is not a satisfying RPG loop. `[INFERENCE]`
- Pacing: the opening repeats "system malfunction" beats across splash, flight, crash, and glitch crater before the player proves anything. `[CODE EVIDENCE] [INFERENCE]`
- Narrative: strong concepts are over-explained. The game tells the player "this world is broken" many times before letting them discover it through play. `[CODE EVIDENCE] [INFERENCE]`
- Player agency: early Elara trust and Aldric outcomes are meaningful on paper, but they arrive after too much passive runway. `[CODE EVIDENCE] [INFERENCE]`
- Combat: memory combat is a lightweight overlay, the slime is a Root Access panel sequence, and the boar is dialogue simulation; the first robust combat is delayed to the tutorial knight. `[CODE EVIDENCE]`
- Progression: the first 20 minutes do not create a clean build promise. XP/gold/rewards exist, but the player may not know what they are building toward. `[CODE EVIDENCE] [INFERENCE]`
- Exploration: the merged Oakhaven region has NPCs, lore, shops, boss gate, secrets, farming, and exits, but that is a lot to dump after a confusing opening. `[CODE EVIDENCE]`
- Economy: starting inventory gives potions/stabilizers, skip prologue grants 100 gold, shops sell many items, and Oakhaven may grant more resources; scarcity is weak. `[CODE EVIDENCE] [INFERENCE]`
- Tutorial: control labels exist, but the teaching is text-heavy and split across memory combat, Root Access panels, overworld labels, pause menus, and status systems. `[CODE EVIDENCE]`
- UI/UX: early menus expose map, status, inventory, crafting, functions, tickets, charms, save, options, completion, chapter select; this is too much before the core loop is fun. `[CODE EVIDENCE] [INFERENCE]`
- Emotional anchor: Elara and Aldric have useful emotional material, but Elara may be off-route in the current fresh-start path and Aldric is too late. `[CODE EVIDENCE] [INFERENCE]`

## 8. Plot holes and narrative contradictions

| Issue | Severity | Evidence | Fix suggestion |
|---|---:|---|---|
| The fresh-start path appears to skip the Elara meeting/path cinematic chain and drops to overworld after glitch crater. | High | `[CODE EVIDENCE]` `ch1_glitch_crater.gd` transitions to overworld, while `elara_meeting.gd` and `path_to_oakhaven.gd` form a separate chain. | Decide one canonical route and remove/retire the other from early progression. |
| Objective systems disagree about Chapter 1 state. | High | `[CODE EVIDENCE]` `ProgressionBreadcrumb` waits for `tutorial_completed`; pause tickets use `ch1_oakhaven_entered`; status uses `ch1_glitch_crater_complete`. | Create one Chapter 1 route state enum or single source of truth. |
| Kaelen is a normal programmer but has combat reflex memory early. | Medium | `[CODE EVIDENCE]` memory combat says his hands remember fighting. | Make this the first mystery through play, not a narrated explanation. |
| Root Access is framed as costly, but early tutorial panels can feel mechanically free/scripted. | Medium | `[CODE EVIDENCE]` slime and knight Root Access sequences are guided panel/dialogue beats. | Add a small, visible cost and a second-order consequence immediately. |
| Oakhaven NPCs are supposed to be trapped in loops, but the game also exposes shops, auctions, crafting, and standard RPG systems early. | Medium | `[CODE EVIDENCE]` Oakhaven village/region systems. | Make one NPC loop mechanically interruptible before exposing shops. |
| The tutorial knight is named "tutorial" in code/UI while the story wants Aldric to be a person. | Medium | `[CODE EVIDENCE]` `TutorialKnightBoss`, "TUTORIAL KNIGHT", then Aldric reveal. | Rename externally visible boss title earlier to "Corrupted Sentinel" or "Aldric". |
| Player can skip prologue to overworld with flags set and 100 gold. | Medium | `[CODE EVIDENCE]` `main_menu.gd::_on_skip_prologue_pressed()`. | Treat this as debug/secondary and label it clearly or hide it for first-time players. |
| Main menu chapter select can expose future content/flags before the opening earns trust. | Medium | `[CODE EVIDENCE]` `main_menu.gd` chapter select data includes late chapters. | Gate chapter select behind dev/debug or completion. |
| Mojibake undermines tone. | High | `[HEADLESS RUNTIME EVIDENCE]` visible labels include broken encoded characters. | Normalize files to UTF-8 and replace decorative glyphs in UI strings. |
| World travel appears before the first grounded motivation is fully established. | Medium | `[CODE EVIDENCE]` glitch crater transitions to overworld immediately. | Keep player in a compact authored crash site before world map access. |

## 9. Technical architecture critique

- Dialogue: `DialogueManager.say()` and `show_choices()` are feature-rich, but scene scripts chain enormous `await DialogueManager.say(...)` sequences, creating brittle pacing and hard-to-test locks. `[CODE EVIDENCE]`
- Quest/state flags: many early flags exist (`tutorial_completed`, `ch1_awakening_complete`, `ch1_glitch_crater_complete`, `ch1_oakhaven_entered`, `ch1_data_vision_unlocked`, etc.) without one canonical Chapter 1 progression object. `[CODE EVIDENCE]`
- Save/load: `GameManager.save_game()` has useful blocking and atomic write behavior, but early manual save was not live-tested; boot reads user data. `[CODE EVIDENCE] [NOT VALIDATED]`
- Combat modularity: `player_combat.gd` is large and capable, but early "combat" is split between a memory overlay, dialogue simulation, random encounters, and a boss arena. `[CODE EVIDENCE]`
- Input: input actions exist for movement, attack, defend, interact, pause, map, status, root access, data vision, heal, flee. Headless movement responds. `[HEADLESS RUNTIME EVIDENCE]`
- UI: pause/status/world-map systems are dense and built programmatically, which increases layout and regression risk. `[CODE EVIDENCE]`
- Scene transitions: `SceneTransitions.change_scene()` centralizes transitions, but multiple systems call it directly with story flags and metadata. `[CODE EVIDENCE]`
- Scalability: Chapter scripts contain long monolithic sequences and many hardcoded strings; this will slow future iteration and make localization/branching fragile. `[CODE EVIDENCE]`
- Headless audit warning: freeing active cinematic scenes caused lambda capture errors and leaked ObjectDB instances after the audit script queued scenes and freed them. This is not a live gameplay crash proof, but it is a cleanup smell in timed/tween-heavy scenes. `[HEADLESS RUNTIME EVIDENCE]`

## 10. 30-point scorecard

| Category | Score 0-10 | Evidence type | Biggest issue | Severity | Recommended fix |
|---|---:|---|---|---|---|
| Opening hook | 2 | `[CODE EVIDENCE]` | Too much pre-control text | High | Interactive crash within 10s |
| First meaningful input | 2 | `[CODE EVIDENCE]` | Space/New Game is not meaningful play | High | Give movement/action immediately |
| Fresh-start route clarity | 3 | `[HEADLESS RUNTIME EVIDENCE]` | Route reaches prologue, later path split | High | One canonical route |
| Movement responsiveness | 6 | `[HEADLESS RUNTIME EVIDENCE]` | Movement works headlessly, feel unvalidated | Medium | Live feel pass after route fix |
| Camera behavior | 5 | `[HEADLESS RUNTIME EVIDENCE]` | Cameras exist, follow unvalidated | Medium | Headed camera tests |
| Interaction prompts | 4 | `[CODE EVIDENCE]` | Range/prompt not live-angle tested | Medium | Prompt UX pass |
| Dialogue pacing | 2 | `[CODE EVIDENCE]` | Long chained exposition | High | Cut 60-70 percent before first reward |
| Objective clarity | 2 | `[CODE EVIDENCE]` | Conflicting flags/objectives | High | Single route-state source |
| First conflict | 3 | `[CODE EVIDENCE]` | Memory overlay, not core gameplay | High | Real micro-encounter early |
| Combat teaching | 4 | `[CODE EVIDENCE]` | Split across overlay/text/boss | Medium | One teach-practice-test flow |
| Boss encounter | 6 | `[CODE EVIDENCE]` | Good dilemma, delayed too far | Medium | Move emotional version earlier |
| Failure/retry | 5 | `[CODE EVIDENCE]` | Boss retry code exists, unplayed | Medium | Live death/retry validation |
| Save/checkpoint | 5 | `[CODE EVIDENCE]` | Logic exists, not live validated | Medium | First save point before risk |
| UI density | 3 | `[CODE EVIDENCE]` | Too many menus/systems early | High | Hide advanced systems |
| Quest log | 4 | `[CODE EVIDENCE]` | Ticket/objective mismatch | High | Rewrite first quest tracking |
| Economy | 4 | `[CODE EVIDENCE]` | Too much starting safety/resource noise | Medium | Make one scarce choice matter |
| Crafting | 3 | `[CODE EVIDENCE]` | Adds menu burden before need | Medium | Delay until after first damage pressure |
| Shop | 4 | `[CODE EVIDENCE]` | Broad catalog early | Medium | Use one essential purchase |
| Progression reward | 4 | `[CODE EVIDENCE]` | Rewards exist but not motivating early | Medium | First skill/upgrade promise at minute 5 |
| Exploration value | 5 | `[CODE EVIDENCE]` | Region has content, route unclear | Medium | Compact authored crash site first |
| Visual readability | 3 | `[STATIC SCENE EVIDENCE]` | Many ColorRect placeholder/procedural elements | High | Visual cleanup after route fix |
| Text encoding | 1 | `[HEADLESS RUNTIME EVIDENCE]` | Mojibake visible | High | UTF-8 cleanup |
| Player/NPC readability | 4 | `[HEADLESS RUNTIME EVIDENCE]` | Generated fallbacks active, no live screenshot | Medium | Headed screenshot QA |
| Narrative motivation | 4 | `[CODE EVIDENCE]` | Motivation told more than played | High | Playable survival/moral hook |
| Emotional anchor | 5 | `[CODE EVIDENCE]` | Elara/Aldric strong but late/off-route | Medium | Put one anchor in first 3 minutes |
| Choice consequence | 6 | `[CODE EVIDENCE]` | Meaningful later, delayed | Medium | One small early consequence |
| Sequence-break risk | 3 | `[CODE EVIDENCE]` | Skip/chapter select/flags can bypass setup | High | Debug-gate nonstandard starts |
| Performance/cleanup | 4 | `[HEADLESS RUNTIME EVIDENCE]` | Lambda/leak warnings in audit loads | Medium | Scene cleanup audit |
| Input discoverability | 5 | `[CODE EVIDENCE]` | Labels exist but scattered | Medium | Teach one input at a time |
| Retention safety | 2 | `[INFERENCE]` | Passive opening | High | Phase 10N-A2 first-minute rebuild |

## 11. Top 10 blockers

| # | Symptom | Player reaction | Root cause | File/system involved | Fix | Risk | Validation needed |
|---:|---|---|---|---|---|---|---|
| 1 | New Game does not quickly become play. | "When do I control this?" | Cinematic chain before agency | `splash_screen.gd`, `main_menu.gd`, prologue/ch1 scripts | First playable crash-site minute | Medium | Headed fresh-start playtest |
| 2 | Chapter 1 route is split. | Confusion, broken continuity | Cinematic chain vs overworld/Oakhaven region path | `ch1_glitch_crater.gd`, `overworld.gd`, `oakhaven_region.gd` | Pick canonical route | High | Scene transition trace |
| 3 | Objectives disagree. | Does not know what matters | Multiple flag systems | `ProgressionBreadcrumb`, `PauseScreen`, `StatusWindow`, `GameManager` | Single route-state table | Medium | Objective screenshot tests |
| 4 | First conflicts are not mostly real mechanics. | Feels fake/scripted | Dialogue simulations and overlay combat | `ch1_glitch_crater.gd`, `ch1_path_to_oakhaven.gd`, `ch1_oakhaven_village.gd` | Real micro-encounter | Medium | Input/combat test |
| 5 | Text encoding is visibly broken. | Amateur presentation | Mojibake in strings | Many `.gd` UI/dialogue files | UTF-8 cleanup | Low | UI text sweep |
| 6 | Too many systems unlocked/exposed early. | Menu fatigue | Inventory/crafting/status/map/tickets/shop before loop | `PauseScreen`, `StatusWindow`, `ShopSystem` | Hide until taught | Medium | Menu availability checks |
| 7 | Visual identity is asset-demo-like in early scenes. | Low trust | ColorRect/procedural staging in cinematics | Prologue/Chapter 1 scenes | Cleanup after route lock | Medium | Live screenshot QA |
| 8 | Skip/chapter select can bypass foundation. | Spoilers/sequence breaks | Main menu exposes shortcuts | `main_menu.gd` | Gate or clearly mark debug paths | Low | Menu tests |
| 9 | Save/retry is not proven early. | Fear of lost progress | Save UI exists but first reliable checkpoint unclear | `GameManager`, `PauseScreen`, boss scripts | First explicit checkpoint | Medium | Save/load smoke |
| 10 | Narrative tells player what to feel. | Low emotional buy-in | Exposition precedes playable discovery | Prologue/ch1 dialogue scripts | Playable emotional hook | Medium | 3-minute retention test |

## 12. Revised Prologue + Chapter 1 blueprint

- Cold open: fade in already in the glitch crater, no plane title card first. `[INFERENCE]`
- First input within 10 seconds: player stands, moves three steps, and touches a broken object. `[INFERENCE]`
- First curiosity gap: object displays one impossible line: "This NPC has already died 412 times." `[INFERENCE]`
- First danger: corrupted fragment crosses the path; player must dodge or strike once. `[INFERENCE]`
- First meaningful choice: restore a trapped villager's loop for a cost or leave them stable but unaware. `[INFERENCE]`
- First NPC/emotional anchor: Elara appears because the player's action destabilized the scene, not because a cutscene says she does. `[INFERENCE]`
- First combat/conflict: a real, tiny version of Root Access: disable one enemy property, then survive a physical follow-up. `[INFERENCE]`
- First reward: unlock one visible ability promise, not just XP text: Data Vision pings one hidden path. `[INFERENCE]`
- First save/retry point: a corrupted checkpoint/rest point before the Oakhaven gate. `[INFERENCE]`
- Chapter 1 ending hook: Aldric's outcome should alter Chapter 2's opening reaction and appear in the objective log immediately. `[INFERENCE]`

## 13. Implementation roadmap

### 10N-A2: opening hook and first playable minute
- Likely files touched: `scripts/prologue/flight_707_cinematic.gd`, `scripts/prologue/crash_sequence.gd`, `scripts/chapter1/ch1_glitch_crater.gd`, possibly one new small preview/audit scene under `scenes/chapter1` only if approved.
- Exact goal: make New Game reach movement or a meaningful action within 10 seconds.
- Rollback plan: keep original scenes callable behind a debug/legacy flag.
- Validation checklist: headed fresh start, first input time, movement, camera, one interactable, no protected art changes.
- Stop condition: if route changes require broad story/flag rewrites.

### 10N-A3: objective clarity and first quest redesign
- Likely files touched: `GameManager`, `ProgressionBreadcrumb`, `PauseScreen`, `StatusWindow`, early Chapter 1 route scripts.
- Exact goal: one canonical objective state from crash site to Oakhaven.
- Rollback plan: preserve existing flags as compatibility aliases.
- Validation checklist: objective text at every route beat, save/load flag restore, no stale objective.
- Stop condition: if save migration risk becomes broad.

### 10N-A4: first encounter redesign
- Likely files touched: `ch1_glitch_crater.gd`, `player_topdown.gd`, maybe one small enemy script.
- Exact goal: replace the first passive/scripted lesson with a real micro-action.
- Rollback plan: keep memory combat overlay disabled behind a flag until validated.
- Validation checklist: attack, dodge/move, failure/retry, prompt clarity.
- Stop condition: if combat controller changes would affect later bosses.

### 10N-A5: dialogue/quest/state cleanup
- Likely files touched: dialogue scripts and manager calls in prologue/Chapter 1.
- Exact goal: cut early exposition, move lore into optional interactions, reduce hardcoded branch sprawl.
- Rollback plan: old dialogue arrays kept in backup data doc or legacy branch.
- Validation checklist: dialogue advance, skip, choice persistence, no softlock.
- Stop condition: if branch rewrite touches Chapter 2+ consequence logic.

### 10N-A6: UI/save/retry polish
- Likely files touched: `PauseScreen`, `StatusWindow`, `GameManager`, tutorial retry code.
- Exact goal: reduce early menu overload and prove save/retry.
- Rollback plan: feature toggles for advanced tabs.
- Validation checklist: save slot, autosave, death retry, pause/map/status locks.
- Stop condition: if save schema changes become necessary.

### 10N-A7: visual/glitch cleanup for Prologue/Chapter 1 only
- Likely files touched: early scenes and UI text only; no new art generation unless separately approved.
- Exact goal: remove placeholder-looking blocks, broken text encoding, overlapping UI.
- Rollback plan: no production asset replacement; visual/layout edits scoped to early scenes.
- Validation checklist: live screenshots desktop/mobile-like sizes, label readability, no art pipeline writes.
- Stop condition: if it tempts broader tileset/sprite work.

## 14. Do-not-touch list

- Do not touch art generation, ComfyUI, production art imports, `assets/art_sources`, `assets/production_art`, `assets/generated_v2`, or `assets/generated_v3` in the next gameplay phase.
- Do not touch Oakhaven/Ironhold/Fractured Wastes/Mirror City baselines.
- Do not touch late-hub art/staging.
- Do not touch Chapter 2+ content except through read-only consequence checks.
- Do not touch combat balance broadly before the first minute route is fixed.
- Do not touch save schema unless a later state-cleanup phase explicitly approves it.
- Do not touch Source Key, true ending, NG+, world travel, farming, or region-wide systems in A2.

## 15. Final recommendation

Choose **10N-A2: opening hook and first playable minute** next. `[INFERENCE]`

Do not start by polishing art, writing more lore, or redesigning all Chapter 1. The immediate blocker is that a new player is asked to wait too long before doing anything meaningful, and the current opening route has unclear ownership between cinematic scenes and the merged overworld/Oakhaven flow. Fix the first minute first, validate it live, then repair objectives.

## Validation appendix

- AGENTS.md read: yes. `[CODE EVIDENCE]`
- Godot version: `4.6.3.stable.official.7d41c59c4`. `[HEADLESS RUNTIME EVIDENCE]`
- Project boot: completed headless for 3 seconds; autoloads initialized and user settings/achievements were read from `user://`. `[HEADLESS RUNTIME EVIDENCE]`
- Headless audit script: `docs/gameplay_audit/phase_10n_a1_prologue_ch1/tools/opening_runtime_audit.gd`. `[HEADLESS RUNTIME EVIDENCE]`
- Diagnostics: `docs/gameplay_audit/phase_10n_a1_prologue_ch1/diagnostics/opening_runtime_audit.json`. `[HEADLESS RUNTIME EVIDENCE]`
- Live play: no. `Live viewport unavailable — no true visual playtest claim`. `[NOT VALIDATED]`
- Viewport screenshots: no valid screenshots; dummy renderer returned empty images. `[HEADLESS RUNTIME EVIDENCE]`
- Input sent: yes, `move_right` was sent in headless probes for overworld, Oakhaven region, and legacy Oakhaven village. `[HEADLESS RUNTIME EVIDENCE]`
- Player moved: yes, in all three headless movement probes. `[HEADLESS RUNTIME EVIDENCE]`
- Camera followed: not validated live; cameras were found in scene scans. `[HEADLESS RUNTIME EVIDENCE] [NOT VALIDATED]`
- Interaction prompts appeared: not live validated; prompt nodes/code exist. `[CODE EVIDENCE] [NOT VALIDATED]`
- Dialogue advanced: not live validated; dialogue manager/code exists and waits on input. `[CODE EVIDENCE] [NOT VALIDATED]`
- Combat triggered: not live validated; tutorial knight scene loaded and combat nodes existed. `[HEADLESS RUNTIME EVIDENCE] [NOT VALIDATED]`
- Menus opened: not live validated; main menu and pause/status/menu code inspected. `[CODE EVIDENCE] [NOT VALIDATED]`
- Save/checkpoint/retry reached: not live validated; code paths exist. `[CODE EVIDENCE] [NOT VALIDATED]`
- Production/import/art generation: none performed. `[CODE EVIDENCE]`
- Rollback path: only docs/audit outputs were created; delete `docs/gameplay_audit/phase_10n_a1_prologue_ch1/` to remove this phase. `[CODE EVIDENCE]`

Protected path status observed during audit:

- Pre-existing dirty protected files included `scripts/asset_manager.gd`, `scripts/regions/late_revisit_hub.gd`, production-art import metadata, and `assets/production_art/tilesets/mirror_city/`. `[HEADLESS RUNTIME EVIDENCE]`
- This phase did not intentionally modify `assets/production_art`, `assets/generated_v2`, `assets/generated_v3`, `scenes`, or `scripts`. `[CODE EVIDENCE]`
- Final `git diff --check`: exit code 0. Git printed CRLF normalization warnings for pre-existing files `docs/art_pipeline/art_replacement_manifest.md` and `scripts/asset_manager.gd`. `[HEADLESS RUNTIME EVIDENCE]`
