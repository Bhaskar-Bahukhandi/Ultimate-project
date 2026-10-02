# PHASE 10N-A2.5 HEADED FIRST-3-MINUTE PLAYTEST + 50-VECTOR AUDIT

## 1. Executive verdict

* Headed play happened: No
* Full New Game path tested: No
* Run Current Scene only: No
* First control time: Not captured in headed play. A2.4 validated movement in corrected headless runtime only.
* First objective time: Not captured in headed play. Static code confirms objective text exists.
* First interactable time: Not captured in headed play. A2.4 validated SignalFragment headlessly.
* First danger time: Not captured in headed play. A2.4 validated GlitchPulse flag path headlessly.
* First likely quit moment: NOT VALIDATED. Static/code inference points to the debug-looking crash-site scene, duplicated UI/prompt language, or the harmless GlitchPulse as likely early drop-off points.
* Is A2 ready for A3: No, not until a real manual headed playtest happens.
* Final recommendation: Manual headed playtest is still required. The code/runtime path is promising, but this phase cannot certify feel, readability, screenshots, or retention.

No headed viewport play happened in A2.5

A visible Godot startup was attempted with corrected quoting and a bounded quit-after command. It reached Vulkan and initialized autoloads, but Codex had no OS-level viewport control, no human input path, and no screenshot capture. Therefore this is not a true headed/manual playtest.

## 2. Evidence classification

* HEADED LIVE PLAY EVIDENCE: None. No real manual play occurred.
* HEADED VIEWPORT SCREENSHOT EVIDENCE: None. No real viewport screenshots were captured.
* CORRECTED HEADLESS RUNTIME EVIDENCE: A2.4 probes validated project boot, New Game route target, scene load/instantiate, player movement, SignalFragment interaction, GlitchPulse flag, OakhavenPath completion flags, and smoke path.
* STATIC CODE EVIDENCE: scripts/chapter1/ch1_opening_crash_site_hook.gd, scenes/chapter1/opening_crash_site_hook.tscn, scripts/main_menu.gd, scripts/game_manager.gd, scripts/ui/progression_breadcrumb.gd, scripts/ui/splash_screen.gd, scripts/exploration/player_topdown.gd, scripts/dialogue_manager.gd, scripts/side_quest_manager.gd, scripts/inventory_system.gd, scripts/crafting_system.gd, scripts/shop_system.gd, and project.godot were inspected.
* STATIC SCENE EVIDENCE: scenes/main_menu.tscn and scenes/chapter1/opening_crash_site_hook.tscn were inspected.
* INFERENCE: Retention, boredom, confusion, visual hierarchy, and feel judgments are inferred from code/static structure only.
* NOT VALIDATED: Human player feel, live menu click path, real first-3-minute timing, viewport readability, audio, real screenshots, confused-player path, fast-player path, failure path, and full transition feel.

## 3. First-3-minute timeline

| Event | Timestamp | What happened | Expected player action | Expectation clear | Evidence type |
|---|---:|---|---|---|---|
| game_launch | 0 | Corrected visible startup command launched Godot with Vulkan and project autoloads. | None | Not applicable | LOG EVIDENCE |
| menu_visible | Not captured | Not observed by Codex. Static code says splash transitions to main menu after 3 seconds or any key press. | Click New Game | Not validated | NOT VALIDATED |
| new_game_clicked | Not captured | New Game was not clicked in a headed viewport. | Start fresh game | Not validated | NOT VALIDATED |
| first_visible_scene_after_new_game | Not captured | Opening hook scene loads and instantiates headlessly. | Observe crash site | Not visually validated | CORRECTED HEADLESS RUNTIME EVIDENCE |
| first_player_control | Not captured | Simulated move_right changed player position in A2.4. | Move with WASD | Static objective says Move with WASD | CORRECTED HEADLESS RUNTIME EVIDENCE |
| first_objective_visible | Not captured | Objective text exists in local HUD and breadcrumb code. | Find signal | Likely clear but not headed-validated | STATIC CODE EVIDENCE |
| first_interactable_seen | Not captured | SignalFragment exists as a 36x36 cyan ColorRect and world label. | Press F/E near fragment | Risky due duplicate/mismatched prompt wording | STATIC CODE EVIDENCE |
| first_signal_interaction | Not captured | A2.4 validated Player._interact_with(SignalFragment), flag set, objective updated. | Inspect signal | Headless only | CORRECTED HEADLESS RUNTIME EVIDENCE |
| first_glitch_pulse_danger | Not captured | Pulse arms and danger flag can be set, but effect is message/camera shake only. | Avoid pulse | Not visually validated | CORRECTED HEADLESS RUNTIME EVIDENCE + STATIC CODE EVIDENCE |
| oakhaven_path_transition | Not captured | Completion flags can be set before timer transition. Full headed transition not observed. | Move east | Static objective says move east | CORRECTED HEADLESS RUNTIME EVIDENCE |
| first_confusion | Not captured | Likely confusion point is duplicated objective/prompt UI or wandering off intended route due missing boundaries. | Find signal/route | Unproven | INFERENCE |
| first_boredom | Not captured | Likely boredom point is after discovering the pulse has no real mechanical consequence. | Continue east | Unproven | INFERENCE |
| first_curiosity | Not captured | Curiosity line about Oakhaven death loop and Elara marker exists. | Want to go to Oakhaven | Unproven | STATIC CODE EVIDENCE |
| first_likely_quit_moment | Not captured | Likely quit risk is seeing a primitive debug-looking scene with duplicated UI and a harmless danger pulse. | Continue anyway | Unproven | INFERENCE |

## 4. First-3-minute retention diagnosis

* Exact quit moment: NOT VALIDATED. Without headed play, there is no evidence-based exact quit timestamp.
* Likely quit moment by inference: the player reaches the primitive crash-site scene and sees a ColorRect-built space, duplicated objective/prompt UI, or a GlitchPulse that warns danger but has no meaningful consequence.
* Why player loses interest: the A2 hook improves control timing, but the actual playable beat is still shallow: move, interact once, avoid or touch a harmless pulse, exit east.
* Primary conflict appears fast enough: CODE/RUNTIME says the pulse can appear quickly after signal interaction. It is not yet strong enough mechanically.
* Curiosity gap is strong enough: The Oakhaven death loop / Elara marker line is the strongest narrative element, but it is temporary text, not a playable discovery.
* Player understands what to do: Static objective text is clear, but duplicated UI and prompt wording could undermine clarity. Not headed-validated.

## 5. Player-feel observations

* Movement feel: NOT VALIDATED. A2.4 proves movement changes position, but not whether acceleration, stop distance, or camera smoothing feel good.
* Camera: CORRECTED HEADLESS RUNTIME EVIDENCE confirms a current camera exists. Headed framing is not validated.
* Collision: STATIC CODE EVIDENCE shows no solid opening-hook boundaries or debris collision. This is a real design risk.
* Interact prompt: STATIC CODE EVIDENCE shows local player prompt and world label can duplicate each other, and F/E semantics are muddy.
* Feedback: Signal interaction updates objective and arms pulse. Feedback is mostly text/tween. Audio and tactile feel are not validated.
* GlitchPulse readability: STATIC CODE EVIDENCE shows pulse appears only after signal and sets a flag, but has no real penalty.
* Transition clarity: STATIC CODE EVIDENCE shows a 0.45s timer then overworld transition. The feel of that transition is not validated.

## 6. Visual/UX observations

* Sprite quality: NOT VALIDATED. A2.5 captured no viewport screenshot.
* Fallback art: Visible startup log did not reach the opening scene; A2.4 logs previously noted generated player fallback from AssetManager. This is not an A2.5 visual proof.
* Objective readability: STATIC CODE EVIDENCE says objective text exists, but two objective systems can be visible at once.
* HUD clutter: STATIC CODE EVIDENCE shows local hook HUD at layer 95 and ProgressionBreadcrumb at layer 85. Duplication risk is high.
* Text clarity: STATIC CODE EVIDENCE shows mojibake in several menu/breadcrumb/dialogue strings, including arrows/dashes.
* Prompt placement: NOT VALIDATED visually. Code creates a player-local prompt and world-space label.
* Visual hierarchy: INFERENCE says the critical signal and pulse may not dominate enough because they are simple ColorRects among other ColorRects.

## 7. 50-vector audit matrix

| ID | Vector | Severity | Evidence type | Observation | Fix direction | Recommended phase |
|---:|---|---|---|---|---|---|
| 1 | Hook & retention | Not validated | NOT VALIDATED | No headed/manual play occurred, so the exact human drop-off moment is not proven. Static/code evidence says the hook now starts playable quickly after New Game, but the conflict is a text line plus a non-damaging pulse. | Run true headed play first, then tighten the first visible conflict around signal, pulse, and Oakhaven pull. | Manual headed playtest still required |
| 2 | Interactive loop | P1 critical retention risk | CORRECTED HEADLESS RUNTIME EVIDENCE + STATIC CODE EVIDENCE | Movement, SignalFragment interaction, pulse flag, and path completion work headlessly. The actual loop is move, press interact, avoid/enter pulse, exit. The pulse has no damage, failure, knockback, resource cost, or hard consequence. | Add one readable consequence/feedback beat without broad combat changes, and make each micro-action visibly change the route. | 10N-A2.6 first-minute headed micro-polish |
| 3 | Structural pacing | P2 major improvement | STATIC CODE EVIDENCE + INFERENCE | A2 removes the long passive prologue from New Game, but after the 0.45s OakhavenPath completion it hands control back to the existing overworld/Oakhaven route. That post-hook pacing is still unvalidated. | After manual A2 validation, redesign objective handoff from crater to Oakhaven as a single clear first quest chain. | 10N-A3 objective clarity and first quest redesign |
| 4 | Ludonarrative dissonance | P2 major improvement | STATIC CODE EVIDENCE | The script warns that the memory scar is dangerous, but the pulse handler only sets a flag, shows text, and shakes camera. | Add harmless but real gameplay consequence: short knockback, route distortion, screen static, or temporary control disruption. | 10N-A2.6 first-minute headed micro-polish |
| 5 | Quest design/objectives | P1 critical retention risk | STATIC CODE EVIDENCE | The first objective is clear, but objective state is split between local HUD text and ProgressionBreadcrumb flag logic. Completion sets four compatibility flags at once. | Define one first-quest state machine and one visible objective source for the opening handoff. | 10N-A3 objective clarity and first quest redesign |
| 6 | Tutorial integration | P2 major improvement | STATIC CODE EVIDENCE | The opening teaches movement via text: Move with WASD. Inspect the broken signal fragment. The prompt is functional but not embedded in the environment. | Use spatial staging: player wakes facing the fragment, route ping activates after movement, prompt appears only near the object. | 10N-A2.6 first-minute headed micro-polish |
| 7 | Exploration value/level design | P1 critical retention risk | STATIC CODE EVIDENCE | The hook builds visual ColorRects but no StaticBody2D boundaries or debris collision. A confused player can likely wander through or beyond the intended space while the camera limits clamp. | Add non-art blocking and route shaping with existing collision primitives, then validate with headed play. | 10N-A2.6 first-minute headed micro-polish |
| 8 | Save/retry loops | Not validated | NOT VALIDATED + STATIC CODE EVIDENCE | No headed save/retry test happened. The hook completion sets flags and transitions, but no checkpoint/autosave call is visible in the opening hook. | After headed validation, decide whether first Oakhaven arrival should autosave or checkpoint. | 10N-A3 objective clarity and first quest redesign |
| 9 | Dialogue UX | P2 major improvement | STATIC CODE EVIDENCE | The hook uses transient message labels, not DialogueManager. DialogueManager has typewriter/skip/choices, but the first minute does not teach dialogue controls. | Add persistent inspect log or repeatable signal text before the first true dialogue scene. | 10N-A3 objective clarity and first quest redesign |
| 10 | Narrative momentum | P2 major improvement | STATIC CODE EVIDENCE + INFERENCE | The Oakhaven death loop / Elara marker line is the strongest curiosity gap, but it is one temporary text message with no character present. | Turn the signal into a repeatable micro-discovery that points to a visible next mystery. | 10N-A3 objective clarity and first quest redesign |
| 11 | Choice agency/consequence | P2 major improvement | STATIC CODE EVIDENCE | The opening hook has no meaningful choice. Later Oakhaven has warn/quietly style choices, but they are not seeded in the first playable minute. | Add a small Chapter 1 dilemma after the first objective, not inside the unvalidated hook. | 10N-A3 objective clarity and first quest redesign |
| 12 | Emotional anchoring | P1 critical retention risk | STATIC CODE EVIDENCE + INFERENCE | The hook has no visible NPC or companion. Elara is a name in a signal line, and the protagonist has only one internal message. | Use the first quest to make Elara or another anchor visible through action, not exposition. | 10N-A3 objective clarity and first quest redesign |
| 13 | Multi-ending seeding | P3 future scalability risk | STATIC CODE EVIDENCE | Many ending and route flags exist later in GameManager, but no early action visibly teaches that choices will matter. | Seed one small tracked Chapter 1 choice with clear later-readable consequences. | 10N-A3 state/quest architecture repair |
| 14 | Permanent consequence architecture | P3 future scalability risk | STATIC CODE EVIDENCE | GameManager has a large string-flag dictionary and some mutual-exclusion handling, but consequence state appears spread across scripts. | Introduce documented choice groups and validation assertions before expanding branches. | 10N-A3 state/quest architecture repair |
| 15 | Combat/encounter satisfaction | Not validated | NOT VALIDATED + STATIC CODE EVIDENCE | The first three minutes did not reach combat in headed play. The hook pulse is not combat and does not teach attack/defense. | Do not add combat to A2; redesign the first true encounter as its own phase. | 10N-A4 first encounter redesign |
| 16 | Progression sense | P1 critical retention risk | STATIC CODE EVIDENCE + INFERENCE | The opening hook has no XP, item, skill, permanent unlock, or visible reward beyond route progression. | Add a first reward beat after the Oakhaven signal or first quest, preferably information plus a small usable mechanic. | 10N-A3 objective clarity and first quest redesign |
| 17 | Economy/resource scarcity | Not validated | STATIC CODE EVIDENCE | Inventory autoload grants starter items at startup. The hook does not introduce resources, gold, scarcity, or why items matter. | Delay economy teaching until the first Oakhaven problem gives consumables/materials a reason to exist. | 10N-A3 objective clarity and first quest redesign |
| 18 | Crafting utility/hook | P3 future scalability risk | STATIC CODE EVIDENCE | Crafting uses hardcoded recipes and materials in CraftingSystem, and it is not introduced in the opening. | Do not teach crafting in minute one; attach it to a later Chapter 1 obstacle. | 10N-A5 dialogue/quest/state cleanup |
| 19 | Shop economy/balancing | P3 future scalability risk | STATIC CODE EVIDENCE | ShopSystem is global and feature-rich, with buy/sell/filter/sort, but shop data is mostly in code dictionaries. | Later move shop catalogs/prices to data resources after early quest flow is fixed. | Future economy pass |
| 20 | Level-up dopamine/impact | Not validated | NOT VALIDATED | No headed play reached XP or level-up. The opening hook does not award XP or show a build promise. | Make the first combat/reward phase teach one future build hook. | 10N-A4 first encounter redesign |
| 21 | Material distribution scarcity | P3 future scalability risk | STATIC CODE EVIDENCE | Materials exist in CraftingSystem, but early distribution and grind pressure were not live tested. | Audit material drops only after the first quest and first encounter are stable. | Future Chapter 1 economy pass |
| 22 | Inventory weight/caps | OK for now | STATIC CODE EVIDENCE | Inventory has stack caps but no weight system, avoiding early burden. Max stack checks exist. | Leave weight/caps alone until core first-hour retention works. | Do not fix yet |
| 23 | Skill tree extrapolation | P2 major improvement | STATIC CODE EVIDENCE + INFERENCE | Root Access/Data Vision exist in input and player code, but the opening hook does not give a controlled taste of build direction. | Use the first quest or first encounter to preview one signature ability, not the whole system. | 10N-A3 objective clarity and first quest redesign |
| 24 | Dynamic price/faction influence | P3 future scalability risk | STATIC CODE EVIDENCE | Faction/choice impact on shops is not visible in early systems. Shop prices are mostly fixed code data. | Defer until Chapter 1 choices are stable, then wire one visible price/consequence example. | Future economy/faction pass |
| 25 | Shop system scalability | P3 future scalability risk | STATIC CODE EVIDENCE | Shop UI is programmatic and centralized, which is useful, but item catalogs and pricing remain hardcoded. | Later split shop content data from UI code. | Future economy architecture pass |
| 26 | Crafting dependency loops | P3 future scalability risk | STATIC CODE EVIDENCE | Recipes include early consumables and late material outputs, but the dependency loop is not tied to the first quest yet. | Design Chapter 1 recipes around a concrete player problem before expanding. | Future crafting pass |
| 27 | Cooldown/resource architecture | P3 future scalability risk | STATIC CODE EVIDENCE | Player stamina and combat cooldown-style systems exist, but the opening does not teach resource pressure. | Teach only one resource constraint at a time, starting after the hook. | 10N-A4 first encounter redesign |
| 28 | Technical foundation | P2 major improvement | STATIC CODE EVIDENCE | The opening hook is reversible and scoped, but it runtime-builds a full scene and duplicates HUD/prompt concepts already present globally. | Keep A2 hook, then consolidate first-minute objective/prompt ownership in A3/A5. | 10N-A5 dialogue/quest/state cleanup |
| 29 | Dialogue branching architecture | P3 future scalability risk | STATIC CODE EVIDENCE | DialogueManager supports choices, but Oakhaven dialogue content is hardcoded arrays inside scene scripts. | Move Chapter 1 dialogue data to resources/JSON only after the playable flow is fixed. | 10N-A5 dialogue/quest/state cleanup |
| 30 | State management/flag tracking | P1 critical retention risk | STATIC CODE EVIDENCE | A2 completion sets several legacy compatibility flags directly. Breadcrumbs, GameManager, and scene scripts read overlapping flags. | Document a Chapter 1 state contract and add validation probes for stale/objective flags. | 10N-A3 state/quest architecture repair |
| 31 | Multiple-ending tracking | P3 future scalability risk | STATIC CODE EVIDENCE | Ending and NG+ flags exist as many string booleans. There is not yet a typed route ledger for long-play consequences. | Do not solve now; introduce typed route summaries before adding new endings. | Future narrative systems pass |
| 32 | Collision/hitbox layers | P1 critical retention risk | STATIC CODE EVIDENCE | Opening hook creates Area2D interactables/hazards but no solid map collision. Player collision exists, but there are no authored solids in the hook scene. | Add minimal opening-only StaticBody2D boundaries and validate confused-player wandering. | 10N-A2.6 first-minute headed micro-polish |
| 33 | Global variable conflicts | P3 future scalability risk | STATIC CODE EVIDENCE | GameManager centralizes state, travel, flags, stats, saves, NG+, and free travel. This is practical but high coupling. | Do not refactor broadly now; add small contracts/tests around Chapter 1 state. | 10N-A3 state/quest architecture repair |
| 34 | Meta-progression/NG+ prep | OK for now | STATIC CODE EVIDENCE | NG+ still routes to the legacy prologue and has dedicated state setup. A2 did not redirect NG+ into the new hook. | Leave NG+ untouched until the base opening is proven headed. | Do not fix yet |
| 35 | Performance/scene management | P3 future scalability risk | HEADED LAUNCH LOG + STATIC CODE EVIDENCE | Corrected visible startup reached Vulkan on RTX 2050 and initialized autoloads. Exit logs reported leaked Texture/RID warnings. Many global systems initialize before play. | After gameplay flow stabilizes, audit autoload startup cost and exit cleanup. | Future PC optimization pass |
| 36 | Input buffering/responsiveness | Not validated | CORRECTED HEADLESS RUNTIME EVIDENCE + NOT VALIDATED | Headless movement moved the player 28.586 px under simulated move_right. Actual feel, acceleration, camera smoothing, and keyboard latency were not headed-tested. | Manual headed play must judge movement, stop distance, camera smoothing, and prompt range. | Manual headed playtest still required |
| 37 | PC input/keybind flexibility | P2 major improvement | STATIC CODE EVIDENCE | Options supports key rebinding, but the opening prompt says F interact/E inspect while player code treats both interact/root_access as the same interaction call near an object. | Align first-minute prompt labels with actual action behavior and expose controls cleanly. | 10N-A2.6 first-minute headed micro-polish |
| 38 | Display/resolution/aspect ratio | P3 future scalability risk | STATIC CODE EVIDENCE | Project viewport is 1280x720 with viewport stretch. 21:9, 4K, pixel scaling, and text fitting were not headed-tested. | After headed 16:9 pass, test 1366x768, 1920x1080, ultrawide, and scaling. | Future PC UX pass |
| 39 | Framerate scaling | P3 future scalability risk | STATIC CODE EVIDENCE | Movement uses physics delta and tweens/timers are common. Combat effects manipulate Engine.time_scale. | Later test 60/144/240 Hz with movement/combat probes. | Future PC optimization pass |
| 40 | Hardware access/modding readiness | P3 future scalability risk | STATIC CODE EVIDENCE | Large data sets for quests, shops, crafting, flags, and free travel are embedded in scripts. | Do not refactor now; migrate only after early-game flow stabilizes. | Future data architecture pass |
| 41 | Discord/Steam API hooks | Not validated | NOT VALIDATED | No platform integration was inspected beyond save file structure and achievements logs. | Defer until core first hour is worth retaining. | Do not fix yet |
| 42 | Asset pooling/garbage collection | P3 future scalability risk | STATIC CODE EVIDENCE + LOG EVIDENCE | ObjectPool exists and CombatEffects reserves damage label pooling, but startup/exit logs include texture/RID leak warnings. | Audit pooling/cleanup after gameplay priority fixes. | Future PC optimization pass |
| 43 | Pathfinding/enemy AI steering | Not validated | NOT VALIDATED | No headed play reached NPC/enemy pathfinding. Enemy scripts exist but were not validated in this phase. | Validate with the first encounter redesign, not now. | 10N-A4 first encounter redesign |
| 44 | Async loading/transition buffering | P2 major improvement | STATIC CODE EVIDENCE | Opening completion waits 0.45s and calls SceneTransitions/change_scene. No async loading or transition interception was headed-tested. | Validate transition feel in headed play, then add a clear route/arrival beat if needed. | 10N-A2.6 first-minute headed micro-polish |
| 45 | Crash logging/telemetry foundation | P2 major improvement | LOG EVIDENCE + STATIC CODE EVIDENCE | A2.3/A2.4 needed explicit --log-file to avoid startup command issues. There is no player-facing crash report path in the inspected code. | Add a documented local log collection flow later; do not change runtime now. | Future PC readiness pass |
| 46 | Menu/inventory cohesion | P2 major improvement | STATIC SCENE EVIDENCE + STATIC CODE EVIDENCE | The main menu includes New Game, Skip Prologue, Load, Options, Chapter Select, Credits, Completion, Quit, and a debug legacy button in debug builds. Fresh-player menu may look like a developer build. | For player builds, hide debug/chapter completion shortcuts behind an explicit debug menu. | 10N-A2.6 first-minute headed micro-polish |
| 47 | UI information density | P1 critical retention risk | STATIC CODE EVIDENCE | The opening can show a local top-left objective panel and global top-right breadcrumb for the same task. Player prompt plus world label can duplicate interaction text. Several strings in menu/breadcrumb show mojibake sequences. | Choose one objective surface for the hook, fix key labels, and repair text encoding artifacts. | 10N-A2.6 first-minute headed micro-polish |
| 48 | Save/cloud compatibility | P3 future scalability risk | STATIC CODE EVIDENCE | Save uses user:// save slots with tmp/backup handling and save version merge. Steam Cloud/Alt-F4 corruption behavior was not tested. | Keep current save schema untouched; later test cloud-friendly path and crash-safe writes. | Future PC readiness pass |
| 49 | Modular settings/graphics toggles | OK for now | STATIC CODE EVIDENCE | Options include fullscreen, VSync, resolution, accessibility toggles, text size, colorblind mode, difficulty, and key rebinding. | Do not expand settings until manual UI testing identifies actual friction. | Do not fix yet |
| 50 | Soundscape/dynamic audio | Not validated | NOT VALIDATED + STATIC CODE EVIDENCE | No headed audio playback was observed. Main menu calls MusicManager, but opening hook does not call music/SFX for signal, pulse, or transition. | After visual/manual validation, add minimal existing SFX cues if available; do not generate audio. | 10N-A2.6 first-minute headed micro-polish |

## 8. Top 15 fixes by priority

| Priority | Issue | Player impact | Fix direction | Phase | Risk |
|---:|---|---|---|---|---|
| 1 | Run true headed/manual playtest with screenshots | Cannot honestly judge fun, readability, or retention without it | Manual New Game playthrough from splash/menu through OakhavenPath | Manual headed playtest still required | Low |
| 2 | Add opening-only route boundaries | Confused players may wander through/beyond a debug-looking scene | StaticBody2D boundaries/debris blockers using existing primitives | 10N-A2.6 first-minute headed micro-polish | Low-medium |
| 3 | Remove duplicate first-minute objective surfaces | Top-left local objective plus top-right breadcrumb can split attention | Choose one authoritative opening objective UI | 10N-A2.6 first-minute headed micro-polish | Low |
| 4 | Fix F/E prompt mismatch | First interactable teaches unreliable controls | Align prompt text with actual input actions and behavior | 10N-A2.6 first-minute headed micro-polish | Low |
| 5 | Make GlitchPulse mechanically legible | Danger currently reads as fake because consequence is only text/shake | Add harmless but real feedback such as knockback/static/control hiccup | 10N-A2.6 first-minute headed micro-polish | Low-medium |
| 6 | Repair mojibake in visible UI strings | Corrupted text in menus/objectives makes the game look broken | Normalize encoding in user-facing UI strings only | 10N-A2.6 first-minute headed micro-polish | Low |
| 7 | Make SignalFragment more readable without new art | A 36x36 ColorRect may not read as critical object | Pulse/outline/route staging with existing primitives | 10N-A2.6 first-minute headed micro-polish | Low |
| 8 | Simplify fresh-player main menu | Skip Prologue/Chapter Select/Completion/debug route can look like a dev build | Hide non-player shortcuts behind explicit debug/build condition | 10N-A2.6 first-minute headed micro-polish | Medium |
| 9 | Clarify OakhavenPath transition | Player may not understand why/where the scene changes | Add clear arrival/route text and validate full transition headed | 10N-A2.6 first-minute headed micro-polish | Low |
| 10 | Define Chapter 1 objective-state contract | Compatibility flags can drift and create stale objectives | Document one state ladder and validate it | 10N-A3 state/quest architecture repair | Medium |
| 11 | Add first reward/ability promise | No progression dopamine in first three minutes | Reward signal discovery with useful information or ability preview | 10N-A3 objective clarity and first quest redesign | Medium |
| 12 | Create an emotional anchor action | Elara/name-drop is not enough to care | Make first Oakhaven objective involve a person or consequence | 10N-A3 objective clarity and first quest redesign | Medium |
| 13 | Design first real encounter separately | The pulse does not teach combat | Build a low-risk conflict with readable tactical answer | 10N-A4 first encounter redesign | Medium |
| 14 | Audit save/checkpoint after hook | Early progress persistence is unclear | Validate save after Oakhaven arrival before changing schema | 10N-A6 UI/save/retry polish | Medium |
| 15 | Consolidate dialogue/quest/UI ownership | Hardcoded dialogue and split quest systems will scale poorly | After first quest stabilizes, move toward data-driven Chapter 1 contracts | 10N-A5 dialogue/quest/state cleanup | Medium-high |

## 9. What not to fix yet

* Do not generate or import art.
* Do not touch ComfyUI.
* Do not redesign Chapter 2+.
* Do not refactor GameManager broadly.
* Do not rewrite combat before the first manual headed pass proves the opening path.
* Do not alter save schema.
* Do not touch production art, generated_v2, generated_v3, or accepted region baselines.
* Do not expand crafting, shops, or economy until the first quest has a real reason to use them.
* Do not build late-game platform/Steam/Discord integration until the first hour retains players.

## 10. Scorecards

### Scorecard 1: First 3 minutes

| Category | Score | Evidence type | Notes |
|---|---:|---|---|
| hook_strength | 4/10 | INFERENCE | Curiosity line exists, but no headed proof and no emotional anchor. |
| first_control_timing | 6/10 | CORRECTED HEADLESS RUNTIME EVIDENCE | Scene/player movement works headlessly; full menu-to-control timing untested. |
| movement_feel | 5/10 | CORRECTED HEADLESS RUNTIME EVIDENCE | Position changes under simulated input; feel not validated. |
| objective_clarity | 6/10 | STATIC CODE EVIDENCE | Objective text is concise, but duplicate HUD/breadcrumb risk exists. |
| interaction_clarity | 4/10 | STATIC CODE EVIDENCE | Signal exists, but F/E prompt wording is inconsistent and duplicated. |
| danger_readability | 3/10 | STATIC CODE EVIDENCE | Pulse is visible in code but consequence is weak. |
| ui_readability | 4/10 | STATIC CODE EVIDENCE | Potential duplicate objective panels and mojibake artifacts. |
| visual_presentation | 2/10 | STATIC CODE EVIDENCE | Runtime ColorRect prototype scene, no headed screenshot. |
| audio_impact | 2/10 | NOT VALIDATED | No headed audio; opening hook has no clear SFX/music calls. |
| retention_likelihood | 3/10 | INFERENCE | A2 improves structure but cannot be called retention-safe. |

### Scorecard 2: Full project foundation

| Category | Score | Evidence type | Notes |
|---|---:|---|---|
| narrative_systems | 5/10 | STATIC CODE EVIDENCE | Good themes/flags, hardcoded delivery. |
| quest_systems | 4/10 | STATIC CODE EVIDENCE | Breadcrumbs and side quests exist but are split and flag-heavy. |
| combat_foundation | 5/10 | STATIC CODE EVIDENCE | Many systems exist; first encounter not validated. |
| economy_foundation | 4/10 | STATIC CODE EVIDENCE | Inventory/shop/crafting exist but early purpose is weak. |
| progression_foundation | 3/10 | STATIC CODE EVIDENCE | Opening lacks reward/build promise. |
| ui_ux_foundation | 4/10 | STATIC CODE EVIDENCE | Feature-rich but dense and duplicated. |
| save_state_foundation | 5/10 | STATIC CODE EVIDENCE | Versioned saves and backups exist; flag sprawl risk. |
| pc_readiness | 4/10 | LOG EVIDENCE + STATIC CODE EVIDENCE | Vulkan starts; exit leak warnings and display not validated. |
| extensibility | 4/10 | STATIC CODE EVIDENCE | Centralized systems, hardcoded data. |
| production_readiness | 3/10 | INFERENCE | Playable pieces exist, but no headed proof/polish. |

## 11. Screenshots / artifacts

No headed viewport screenshots were captured.

Artifacts created in this phase:

* docs/gameplay_audit/phase_10n_a2_5_headed_vector_review/logs/headed_launch_attempt.json
* docs/gameplay_audit/phase_10n_a2_5_headed_vector_review/logs/visible_startup_quit_after.json
* docs/gameplay_audit/phase_10n_a2_5_headed_vector_review/logs/visible_startup_quit_after_stdout.txt
* docs/gameplay_audit/phase_10n_a2_5_headed_vector_review/logs/visible_startup_quit_after_stderr.txt
* docs/gameplay_audit/phase_10n_a2_5_headed_vector_review/logs/visible_startup_quoted_quit_after.json
* docs/gameplay_audit/phase_10n_a2_5_headed_vector_review/logs/visible_startup_quoted_quit_after.log
* docs/gameplay_audit/phase_10n_a2_5_headed_vector_review/logs/visible_startup_quoted_quit_after_stdout.txt
* docs/gameplay_audit/phase_10n_a2_5_headed_vector_review/logs/visible_startup_quoted_quit_after_stderr.txt
* docs/gameplay_audit/phase_10n_a2_5_headed_vector_review/first3_timeline.json
* docs/gameplay_audit/phase_10n_a2_5_headed_vector_review/vector_score_matrix.json
* docs/gameplay_audit/phase_10n_a2_5_headed_vector_review/headed_first3_vector_audit.md

The first visible launch attempt had bad PowerShell argument quoting for the path containing a space, so it is logged only as a failed attempt. The corrected quoted startup reached Vulkan and initialized project autoloads.

## 12. Protected path status

Required checks run:

* git status --short
* git diff --check

A2.5 did not edit:

* assets/art_sources
* assets/production_art
* assets/generated_v2
* assets/generated_v3
* scenes
* scripts
* project.godot
* AssetManager
* save schema
* Chapter 2+

Pre-existing dirty/protected files remain from earlier phases, including prior art outputs, production-art imports, scripts/asset_manager.gd, scripts/game_manager.gd, scripts/main_menu.gd, scripts/regions/late_revisit_hub.gd, scripts/ui/progression_breadcrumb.gd, scenes/chapter1/opening_crash_site_hook.tscn, and scripts/chapter1/ch1_opening_crash_site_hook.gd.

git diff --check exited successfully. It reported only CRLF normalization warnings for pre-existing files:

* docs/art_pipeline/art_replacement_manifest.md
* scripts/asset_manager.gd

No Godot process remained running after validation attempts.

## 13. Next recommended phase

Manual headed playtest still required

The next action should be a human-controlled headed playtest from splash/menu through New Game and the first OakhavenPath transition, with screenshots. Do not proceed to A3 until the real viewport path is observed.

FINAL DECISION: No headed viewport play happened — manual playtest still required

