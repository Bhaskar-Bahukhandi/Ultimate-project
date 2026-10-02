# Aethelgard — Cold Audit & Fix Plan

Audit date: 2026-09-29 · Godot 4.6 · 202 GDScript files / 77,605 lines · 74 scenes · 1,582 PNGs

Findings marked **[V]** were verified directly against the files on disk during this audit.

> **Status: Phase 0 + the mechanical half of Phase 2 applied 2026-09-29.**
> P0-1 … P0-6 and the unambiguous P1 defects are fixed in code; each carries a `FIXED`
> note saying exactly what changed. **P0-7 was wrong** — see the correction there.
> Still open and marked **OPEN (design call)**: P1-1 defense, P1-4 power curve,
> P1-5 pogo/block/parry, P1-12 MP — these change how the game *plays*, so they need
> your decision, not a patch. All of section 4 (presentation) and 5 (story) untouched.
> Nothing has been run in Godot. Changes are unstaged; review with `git diff`.

---

## 1. The verdict, plainly

You set out to build "an RPG with a unique story and the best possible graphics, cutscenes
and animations." Measured against that:

**The graphics do not exist yet.** Not "are rough" — do not exist. Across all 74 scene files:

| Node type in `.tscn` | Count |
|---|---|
| ColorRect | 107 |
| Label | 95 |
| **Sprite2D** | **0** |
| **AnimatedSprite2D** | **0** |
| **TextureRect** | **0** |
| **TileMap / TileMapLayer** | **0** |
| **AnimationPlayer** | **0** |
| **AudioStreamPlayer** | **0** |

**[V]** Also: 0 audio files, 0 font files, 0 `.tres` resources in the entire project.
`ColorRect.new()` appears 487 times in the scripts, `Label.new()` 342 times, `Sprite2D.new()` 35.

So what a player actually sees is coloured rectangles and default-font text, generated at
runtime by `_ready()`. 51 of your 74 scenes contain exactly one node — an empty `Control`
with a script attached. `scenes/chapter1/tutorial_knight_boss.tscn` is 1 node backed by a
1,609-line script.

**This is not a criticism of effort — it is a diagnosis of where the effort went.**
You have built, with real care, the *fallback branch* of an asset pipeline. Your own code
says so: `asset_manager.gd:4` — "Falls back to placeholder ColorRects if assets not found."
`background_manager.gd:3` — "Procedural placeholder backgrounds... Auto-upgrades to real PNG
assets when dropped into `assets/backgrounds/`." **[V]** That folder is empty. The upgrade
path has never fired, and roughly 11,000 lines were spent making the placeholder branch
elaborate instead of making the real branch exist.

**The story is half-original, and you under-built the original half.** Chapters 1–3 are a
competent but heavily derivative programmer-isekai (the closest comparison is *Death March
to the Parallel World Rhapsody*, almost beat for beat; the ending structure is Mass Effect
3's Destroy/Control/Synthesis plus a flag-gated fourth). Chapters 4–10 contain the genuinely
new idea — the Null Court, where deleted citizens argue that *being restored without being
asked is a second deletion* — and that is the thing worth protecting. But chapters 1–3 hold
**79% of your script lines** while chapters 4–10 hold the original thesis and have **no
playable combat in chapters 4, 5, 8, 9 at all**.

**[V]** Chapter line/dialogue distribution:

| | Ch1 | Ch2 | Ch3 | Ch4 | Ch5 | Ch6 | Ch7 | Ch8 | Ch9 | Ch10 |
|---|---|---|---|---|---|---|---|---|---|---|
| script lines | 6,277 | 4,359 | 2,959 | **541** | 903 | 747 | 835 | 898 | 759 | 1,424 |
| dialogue lines | 176 | 387 | 436 | 59 | 106 | 81 | 100 | 117 | 94 | 163 |

**[V]** The final boss is a three-question multiple-choice quiz
(`chapter10/ch10_sovereign_confrontation.gd:134-184`) in which **option 0 is the correct
answer all three times**, and failing it costs 150 XP and nothing else.

---

## 2. P0 — Things that break the game right now

### P0-1. Your main companion is cut from the shipped game **[V]**
`scenes/chapter1/elara_meeting.tscn` has **zero references in `scripts/`**. The function that
should reach it, `ch1_glitch_crater.gd:1116 transition_to_elara_meeting()`, is misnamed —
line 1137 calls `SceneTransitions.change_scene("res://scenes/overworld/overworld.tscn")`.

Consequences: the flags `ch1_elara_trusted` / `_cautious` / `_distrusted` are written only
inside that orphaned scene (`ch1_elara_meeting.gd:652/672/689`) but **read in ~25 places**
across ch1, ch2, ch5, ch9, ch10, `late_revisit_hub.gd`, `achievements.gd` and the completion
calculation (`game_manager.gd:1218`). Every one resolves false in a real playthrough. Elara's
123 written lines and all three of her `CHOICE_BUFFS` are dead weight in the build.

**FIXED.** `ch1_glitch_crater.gd:1137` now targets `elara_meeting.tscn`. The rest of the chain
was already intact and needed no edits: `elara_meeting → path_to_oakhaven`
(`ch1_elara_meeting.gd:721`) `→ oakhaven_village` (`ch1_path_to_oakhaven.gd:922`)
`→ oakhaven_region` (`ch1_oakhaven_village.gd:595`) `→ overworld`
(`oakhaven_region.gd:868`). The misleading function comment and print were corrected.
Verified: all 11 `@onready` node paths in `ch1_elara_meeting.gd` resolve against
`elara_meeting.tscn`, and none of the three re-linked scenes has a blocking flag prerequisite.

### P0-2. Chapter 2's hub is orphaned; 57% of Chapter 2 is unreachable **[V]**
`scenes/chapter2/ironhold_city.tscn` has **zero references anywhere**. It is the only caller of
`clock_tower.tscn` (`ch2_ironhold_city.gd:633`), `underground_network.tscn` (`:641`) and
`seraphina_encounter.tscn` (`:650`). That strands **219 of Chapter 2's 387 dialogue lines**.

Knock-on damage: Seraphina is *introduced* in the orphaned encounter, so the reachable
`ch2_seraphina_choice.tscn` opens mid-relationship — "I watched you fight that thing" — about
a fight the player never had. And `ch2_data_wraith_*` is set only in the orphaned
`ch2_underground_network.gd`, so Ch4/Ch5/Ch10 always take the "no clear testimony" fallback.

**FIXED — but via the region hub, not `ironhold_city`.** Investigation changed the fix:
all three orphaned spokes already `change_scene` back to **`ironhold_region.tscn`**
(`ch2_clock_tower.gd:656`, `ch2_underground_network.gd:429`, `ch2_seraphina_encounter.gd:336`),
which means `ironhold_region` superseded `ironhold_city` as the hub (exactly as
`oakhaven_region` superseded `exploration/oakhaven`) and the spokes simply never got entry
points. Re-inserting `ironhold_city` would have sent the player out of one hub and back into
a different one.

What changed in `scripts/regions/ironhold_region.gd`:
- New `"story"` interaction kind: `_place_story_gates()`, `_create_story_gate()`,
  `_interact_story()`, plus `"story"` at the top of the `_unhandled_input` priority chain.
- Three gates, each self-hiding on its completion flag and appearing only on its unlock flag:
  **Seraphina** (until `ch2_seraphina_met`), **Underground Network** (needs
  `ch2_underground_unlocked`, until `ch2_underground_complete`), **Clock Tower** (until
  `ch2_clock_tower_complete`).
- `ClockworkBossGate` is now suppressed once `ch2_clockwork_automaton_defeated` is set, so the
  authored multi-floor `clock_tower.tscn` and the generic `combat_arena.tscn` version of the
  same boss can't both be fought.
- `_interact_story()` clears any stale `boss_fight_id` meta, which otherwise permanently
  disables fleeing from later encounters (`player_combat.gd:1555`).

Scene reachability went from **59/74 to 71/74**. Still unreachable, and now a deliberate
content decision rather than a bug: `chapter2/ironhold_city.tscn` (64 hub-only dialogue lines),
`exploration/oakhaven.tscn`, `exploration/oakhaven_post_combat.tscn` — all three superseded by
their region equivalents. Salvage the lines or delete the scenes.

### P0-3. Max HP inflates permanently on every combat scene load **[V]**
`choice_consequences.gd:219-225` bakes the `max_hp` modifier into `GameManager.player_stats`.
Then `player_combat.gd:290-301` reads `player_stats["max_hp"]`, **adds
`get_total_stat_mods()["max_hp"]` again**, and writes the result back to `player_stats`.
Every entry into a combat scene adds another +15 (guardian_blessing) or +10 (Elara), forever.
This silently destroys your entire balance curve.

**FIXED.** `ChoiceConsequences.apply_choice_buff()` is now the single owner. `player_combat._ready`
no longer calls `get_total_stat_mods()`; it reads `player_stats` and clamps `hp` to `max_hp`.
The dead `mods.get("atk", 0)` line (the key is `"attack"`) was removed with it, and a comment
records the ownership rule so it isn't re-added.

⚠️ **Existing saves are not repaired.** Any save made before this fix still carries an inflated
`max_hp`. Decide whether to add a migration in `_migrate_save_data` or just start a new game.

### P0-4. Failing a load permanently disables loading **[V]**
`game_manager.gd:1612` and `:1614` do `if not is_inside_tree(): return true` — returning
*before* `_load_in_progress = false` at the end of the function. Line 1436 then refuses every
subsequent `load_game()` for the rest of the session.

**FIXED.** Both early returns now clear `_load_in_progress` before returning. Every other exit
path in `load_game()` already did; these two were the only leaks.

### P0-5. Root Access freezes the game in the combat arena **[V]**
`combat_arena.gd:661` sets `get_tree().paused = true`. `scenes/combat/combat_arena.tscn:154`
declares `RootAccessPanel` as a plain `PanelContainer` with **no script**, and **no node in
any scene sets `process_mode`** — so its Apply/Cancel buttons cannot process input while the
tree is paused. `scripts/ui/root_access_panel.gd:43` *does* set `PROCESS_MODE_ALWAYS`, but
that script is only used by chapters that build the panel in code
(`ch2_administrator_boss.gd:496` etc.), never by the arena scene.

**FIXED.** `scenes/combat/combat_arena.tscn` now sets `process_mode = 3`
(`PROCESS_MODE_ALWAYS`) on `UI/RootAccessPanel`; the whole subtree inherits it, so the
SpinBoxes and both buttons receive input while paused. `_open_root_access()` additionally
gives `CancelButton` keyboard focus, so there is a way out without the mouse.

### P0-6. Guaranteed runtime error on any `background` cutscene beat **[V]**
`cutscene_manager.gd:709` calls `BackgroundManager.change_background(...)`.
`grep -rn "func change_background" scripts/` returns nothing. Any cutscene using
`{"type": "background", ...}` throws *Invalid call*.

**FIXED.** `BackgroundManager.change_background(location, parent = null)` now exists. It
defaults `parent` to `get_tree().current_scene`, frees any existing `Background_*` node under
it (so repeated beats don't stack layers — `create_background()` alone would), then delegates
to `create_background()`. The `cutscene_manager.gd` call site needed no change.

### ~~P0-7. There is no version control~~ — **CORRECTION: this was wrong**
The repository exists. It is at the **`Ultimate project`** root, one level above
`AethelgardPrototype/`, with 16 commits (most recent `b2a604e`, 2026-06-11) and a `.gitignore`
that already covers `.godot/`, `export_presets.cfg` and the `tmpclaude-*` files. The original
audit check was scoped to `AethelgardPrototype/`, which has no `.git` of its own, and drew the
wrong conclusion from that. Apologies — that was a careless check on an important point.

Two real notes that stand:
1. **The tree was already dirty before this work** — ~261 changed/untracked entries, including
   pre-existing edits to `asset_manager.gd`, `main_menu.gd`, `regions/late_revisit_hub.gd` and
   `ui/progression_breadcrumb.gd` that are **yours, not from this pass**. `git diff` will show
   mine and yours mixed together; the Phase 0 files are listed in the status block at the top.
2. **A stale `.git/index.lock` needs deleting.** A `git status` run from the Linux sandbox
   created it and could not remove it (OneDrive blocks unlink there). Git on Windows will
   refuse to commit until you delete it. Also delete the stray `.git/.__writetest`:

```
del ".git\index.lock" ".git\.__writetest"
```

---

## 3. P1 — Core systems that are wrong

### P1-1. Defense is a non-functional stat — **OPEN (design call)** **[V]**
`grep -n "defense" scripts/combat/player_combat.gd` returns **nothing**. `take_damage`
(`:1708-1813`) applies block and parry and nothing else. `defense` is only ever *written*
(`inventory_system.gd:490`, `game_manager.gd:934`, `choice_consequences.gd:217`) and
*displayed* (`ui/status_window.gd:157`). Every DEF item (+5 to +40), every DEF choice buff and
every point of DEF from levelling is cosmetic. Enemies have no defense stat either.

**Left open deliberately** — implementing mitigation changes every damage number in the game;
deleting DEF changes 12 item descriptions and 9 choice buffs. Either is a balance decision, not
a bug fix. The plumbing around it (P1-2, P1-11) is now correct, so whichever you choose will
behave predictably. A visible stat that does nothing is still worse than no stat.

### P1-2. Level DEF is wiped on every load
`game_manager.gd:934` adds `DEF_PER_LEVEL` to `defense` but never to `base_defense`.
`inventory_system.gd:482-490` and `game_manager.gd:752` both recompute
`defense = base_defense * penalty + equipment`, and `_apply_corruption_effects()` runs
unconditionally on load (`:1600`) — so all level DEF is gone on every load.

**FIXED.** `_apply_level_up` now writes `DEF_PER_LEVEL` to **both** `base_defense` and
`defense`, so the recompute preserves it. Still cosmetic until P1-1 is decided, but the
number will now survive a load.

### P1-3. Level cap is 19, not 20 **[V]**
`_check_level_up` (`game_manager.gd:915`) loops `while current_level < XP_THRESHOLDS.size() - 1`.
`XP_THRESHOLDS[19] = 51000` is unreachable dead data while the stat curves are generated
`for i in range(20)`. Off-by-one across three systems.

**FIXED.** `XP_THRESHOLDS[i]` is the XP needed to reach level `i+1`, so the cap is `size()`
(20), not `size() - 1`. Corrected in `_check_level_up` and in `get_xp_for_next_level` /
`get_xp_progress` so all three agree. Level 20 is reachable at 51,000 XP and `_hp_curve[19]`
is no longer dead data.

### P1-4. The power curve is degenerate past mid-game — **OPEN (design call)**
Worked from the constants: the player goes from 15 attack at L1 to 60 (95 with `null_edge`)
at the cap — **~6.3×**. The hardest zone content scales at 12% per zone level
(`enemy_base.gd:1396`) — **2.44×**. The toughest enemy in the game dies in 2–3 light hits at
cap. There is no content tuned for the top half of your level range.

### P1-5. Pogo strictly dominates every other attack — **OPEN (design call)**
`player_combat.gd:1155-1219`: `_execute_pogo` never sets `is_attacking` and never touches
`attack_cooldown`; its only gate is `pogo_cooldown = 0.2`. That is ~135 DPS (243 with
`pogo_master`) against the combo chain's ~57. It also grants soul per bounce (`:1201`) and
refunds dash/air-jumps (`:1197-1200`), and `_handle_pogo` checks none of
`is_dashing`/`is_attacking`/`is_healing` — so dash-pogo is an invulnerable infinite-soul kill
loop. Block is a free flat −70% with no stamina and no cooldown; parry has 0.18s window on a
0.24s cooldown, i.e. 75% free uptime.

### P1-6. DDA rubber-bands off a handful of hits and buffs enemies mid-fight
`record_dda_hit_taken` counts **0.3 "deaths" per hit** (`game_manager.gd:1104`), so four
unanswered hits floor the score. Separately, every enemy connects `difficulty_adjusted`
(`enemy_base.gd:208`) to `_apply_level_scaling`, which multiplies `max_health` and
`contact_damage` — so clearing three mobs of a pack makes the survivors visibly gain ~7% HP
and damage mid-fight, health bars jumping. Also `get_player_dda_bonus` returns 1.0875 at the
*neutral* score of 50, contradicting its own docstring.

**FIXED (both).** `_on_difficulty_adjusted` now refuses to re-scale an enemy that is dead,
engaged (CHASE/ATTACK/TELEGRAPH/RECOVER/STUNNED) or already damaged — only untouched, unaware
enemies re-tune, so numbers never move mid-fight. And `get_player_dda_bonus` returns exactly
1.0 at or above the neutral score (new `DDA_SCORE_NEUTRAL = 50.0`) and ramps to the documented
1.25 at the floor. **This removes a silent +8.75% to all damage, soul and healing that you have
had from the first frame of every test — the game will feel harder.**

*Still open:* `record_dda_hit_taken` counts 0.3 "deaths" per hit, so four unanswered hits still
floor the score. That is a tuning value; set it after playing the corrected build.

### P1-7. Stale attack coroutines corrupt the next attack
`take_damage` clears `is_attacking`, `attack_cooldown` and `combo_step`
(`player_combat.gd:1737-1745`) while `_perform_combo_attack` is parked on
`await create_timer(startup)` (`:884`). The old coroutine then still resolves its hitbox
(`:891-902`) *and* overwrites the state of whatever attack you started after being hit
(`:944-951`). Same shape in `_perform_charged_attack` and `_perform_upslash`. This is a
double-hit and an attack-speed exploit.

**FIXED.** Added `_attack_token`, a monotonic id. Each of the three attack coroutines captures
it on entry and returns after every `await` if it no longer matches; `take_damage` bumps it
(and clears `can_cancel_attack` / `attack_recovery_timer`) when it cancels an attack. An
interrupted swing can no longer land its hitbox or overwrite the next attack's recovery state.
9 guard points across `_perform_combo_attack`, `_perform_charged_attack`, `_perform_upslash`.

### P1-8. `_exit_tree` releases actions that do not exist
`player_combat.gd:319` releases `"dash"` and `"parry"`. `project.godot` defines `sprint` and
`defend`. A held block or sprint leaks as phantom input into the next scene.

**FIXED.** The list now uses real action names and covers all movement and ability actions.

### P1-9. Projectiles can never hit scene-placed enemies
`EnemyBase._ready` never sets `collision_layer`, so scene-placed enemies sit on layer 1, while
code-spawned ones get layer 4 (`combat_arena.gd:248,372`). The Vengeful Spirit projectile uses
`collision_mask = 4` (`player_combat.gd:1277`). Melee only works because it queries with mask
`0xFFFFFFFF` plus a group fallback — and that fallback uses `Rect2.has_point` with no
line-of-sight, so **melee hits through walls** while enemies correctly raycast.

**PARTLY FIXED.** `EnemyBase._ready` now sets `collision_layer = 4` / `collision_mask = 1`, so
scene-placed enemies sit on the enemy layer and projectiles can hit them. This also fixes
`_on_body_entered`'s `body.collision_layer & 1` terrain test, which was matching other enemies.
*Still open:* the melee group fallback is still line-of-sight-free, so melee can hit through
walls. Fixing that needs a raycast plus a judgement about how forgiving you want melee to be.

### P1-10. `reset_game()` is not a full reset
Does not clear `boss_checkpoints` (boss mercy-HP carries into a new game),
`ChoiceConsequences.active_buffs`, or `RandomEncounterSystem` — whose `reset()`
(`random_encounter_system.gd:1013`) has **zero callers**. `start_new_game_plus` inherits all of it.

**FIXED.** `reset_game()` now clears `boss_checkpoints` and calls a new
`ChoiceConsequences.reset()` (buffs, party roster, cooldowns) plus the previously uncalled
`RandomEncounterSystem.reset()`. `start_new_game_plus` routes through `reset_game()`, so NG+
inherits the fix.

### P1-11. The "choices change gameplay" layer is mostly dead code
Zero callers for `should_death_strike`, `get_spell_damage_multiplier`,
`get_boss_damage_multiplier`, `get_dash_damage`, `is_immune_to_stun`, `get_xp_multiplier`,
`apply_chapter_start_supplies` and ~10 more. Of the 8 choices wired to `CHOICE_BUFFS`, **6 are
in the scenes orphaned by P0-1 and P0-2**. In a real playthrough only the Tutorial Knight
choice and two Chapter 3 choices change anything but words.

Also: `choice_consequences.gd:61` uses the key `base_defense`, which the `match` at `:212-229`
has no case for — the lone_wolf penalty silently never applies. And exclusive flags clear the
flag but not the buff (`game_manager.gd:645-657` vs `choice_consequences.gd:172-173`), so
taking `ch1_elara_trusted` then `ch1_elara_distrusted` leaves both buffs active.

**FIXED (both).** `lone_wolf` now uses the `"defense"` key, which the match handles. The
stat-mod loop was extracted into `_apply_stat_mods(mods, dir)` so it can run backwards, and a
new `remove_choice_buff()` undoes a buff when its flag is cleared — `_on_story_flag_updated`
now acts on `value == false` instead of returning early.

*Still open:* the ~17 advertised choice abilities with zero callers. That is content to write
or delete, not a defect to patch.

### P1-12. MP is a dead resource — **OPEN (design call)**
`player_stats["mp"]` is restored by items, treasure, rest and level-up, and **never spent** —
spells cost Soul. Mana potions and MP-per-level are noise. Also `inventory_system.gd:80-89`
describes `null_potion` as "Adds 3% corruption", but `:382` calls `add_glitch_corruption(-10.0)`.

---

## 4. P2 — Presentation layer

### P2-1. 66 referenced asset paths do not exist **[V]**
Every `assets/backgrounds/**` PNG (9 prologue, 9 ch1, 7 ch2, plus overlays and weather),
all of `assets/production_art/characters/**` (player, 5 NPCs, 3 enemies, the tutorial knight),
`production_art/props/environment_prop_atlas.png`, `production_art/backgrounds/environment_decal_atlas.png`,
6 tilesets, 9 `mysprites_ui` panels, and 2 `.ogg` files (`cutscene_manager.gd`).
`assets/production_art/` contains README files and 6 tileset PNGs — nothing else.

### P2-2. Every named character is a renamed Kenney alien
MD5-identical: `characters/elara.png` = `alienPink_stand.png`; `mira.png` = `alienYellow_stand.png`;
`elder.png` = `alienBeige_stand.png`; `seraphina.png` = `alienPink_badge1.png`;
`tutorial_knight.png` = `alienBeige_badge2.png`. **Elara's dialogue portrait is the pink alien
in its duck pose.** And `asset_manager.gd:1795-1817` adds a `Label` with the character's name
above the placeholder — so your cutscene cast is coloured aliens with name tags floating over
their heads.

### P2-3. The protagonist's portrait is 1024×1024 crushed into 72×72
`portraits/kaelen.png` = `player/player.png` = `P before ch 1.png`, all 1.44 MB. It goes into
a `TextureRect` with `custom_minimum_size = Vector2(72,72)` and `TEXTURE_FILTER_NEAREST`
(`dialogue_manager.gd:619, 753-761`). ~4 MB of VRAM, aliased to mush, sitting next to 47px aliens.
`P top down.png` (2048×2048, 6.4 MB) and `Character sprites.png` (2.3 MB) are imported into the
export and effectively unused.

### P2-4. Animation exists for 10 entities, from ~30 KB of art
`asset_manager.gd:923-973` does real spritesheet slicing into `SpriteFrames` — good code. The
art behind it: the player's combat sheet is **256×768, 25 KB**; each enemy sheet is 192×240,
~6 KB; each NPC's full idle/talk/walk set is **1.9 KB**. Everyone else is a static sprite bobbed
by a tween: `tween_animator.gd:1262-1290` moves `position:y` by 3 px, squashes scale 0.97/1.04
and rocks rotation ±2°. That is the animation system, and it is 1,312 lines long.

`asset_manager.gd:515-533 create_animated_sprite()` builds a `SpriteFrames` with **exactly one
frame** (`:526`) and calls `play()`. Frames are also re-sliced with `Image.get_region()` +
`ImageTexture.create_from_image()` **per frame, per spawn** — 48 CPU→GPU uploads every time a
player is instantiated, never cached.

### P2-5. The CRT shader samples an empty buffer
`crt_effect.gdshader` reads `hint_screen_texture`, and is applied to
`BackgroundLayer/Background` at `layer = -100` (`flight_707.tscn:34-38`) — i.e. it samples the
screen *before anything is drawn*. There is **not one `BackBufferCopy` node in the project**.
2 of your 5 shaders (`atmospheric_light`, `hologram`) have zero references anywhere.
`advanced_glitch.gdshader:32` hardcodes `color.a = 1.0`, so the alpha tween at
`flight_707_cinematic.gd:556` is a no-op.

### P2-6. Duplicated machinery
Two transition systems (`screen_transition.gd` + `scene_transition_manager.gd`) with
overlapping enums — and 7 of `ScreenTransition`'s 12 types just call `fade_out`;
`pixelate_out` allocates a `ShaderMaterial` into a discarded local with the comment
"Would load pixelate shader here." Two damage-number systems
(`vfx_library.gd:885`, `combat_effects.gd:249`). Three shake systems. **Two `Engine.time_scale`
owners** negotiating a global by convention flags (`combat_effects.gd:133`, `game_juice.gd:742`)
— drop a flag and the game freezes or fast-forwards.

Fully orphaned: `cutscene/cutscene_director.gd` (**892 lines**, a complete fluent cutscene API
that nothing has ever called) and `effects/cinematic_vfx.gd` (214 lines).

### P2-7. `cinematic_camera.gd` is the best file in the project — and is used in 7 of 74 scenes
Real follow with dead zone, look-ahead, bounds clamping, trauma shake with quadratic falloff,
dolly, dutch, whip pan, letterbox. Chapters 3–10 (45 scenes) use none of it.

### P2-8. Leaks and per-frame waste
- `cutscene_manager.gd:386-401` polls with `await create_timer(0.05)` — 20 `SceneTreeTimer`
  allocations/second for every parallel beat.
- `cutscene_manager.gd:879` parents flash effects to `get_tree().root`; a scene change mid-flash
  leaves a permanent tint.
- `cutscene_manager.gd:298-301` chains the entrance tween **sequentially**, so every character
  entrance takes 1.5× its authored duration and never actually fades.
- `flight_707_cinematic.gd:611-621` and `crash_sequence.gd:105-118` call `add_theme_color_override`
  **inside `_process()`**, every frame, forever.
- `background_manager.gd:1224-1242` instantiates one `TextureRect` **per tile** — 231 nodes for
  one brick wall.
- `tween_animator.gd:153` keeps `static var bs: Vector2` as shared mutable state; its static
  tween tables are cleared by one caller only (`scene_transition_manager.gd:110`).

---

## 5. P3 — Story and structure

- **Docs no longer describe the game.** `lore.txt` says Kaelen "Kenji"; `Character_design_refrence.md`
  says "REN". Seraphina is a paladin in one doc, an Oracle Mage in another, and a fellow Earth
  crash survivor in the code. The designed companions **Unit 734 "Seven"** and **Kaito** have
  **zero lines in the codebase**; the shipped companions **Lyra** and **Kaelthas** appear in no
  document. "God King" appears 0 times in `scripts/`; the antagonist is SOVEREIGN. The entire
  post-game (fishing, marriage, Data Lake, hex-editing) has zero implementation.
- **Voice collapses after Chapter 3.** Ch1–2 characters are distinct — Elara has a consistent
  nervous-warm register, and Aldric's "...my name... was Aldric. Before the loop."
  (`ch1_tutorial_knight.gd:1477`) earns its moment. From Ch4 on, every speaker produces the same
  clipped antithesis: "Loneliness is efficient." / "Good. Tyranny is fast." / "Distributed
  failure. Very modern." Individually good lines; collectively one writer wearing eleven
  nameplates. The late cast is abstractions — "Echo Mirror", "Backup Historian", "Ironhold
  Delegate" — not people.
- **Chapter 3 is 48% System/Narrator text** (202 of 436 lines) delivered through the dialogue box.
- **Six endings differing by ~3 lines each** (`ch10_ending.gd:104-119`). Real branching, thin payoff.
- **Rename the endings.** Destroy / Rewrite-under-limits / Dissolve + a flag-gated "Synthesize"
  is Mass Effect 3's structure by name. Your own thesis supplies a better axis: not *what happens
  to SOVEREIGN*, but *who is allowed to authorize it*.

---

## 6. The plan

### Phase 0 — Stop the bleeding — **CODE DONE, NOT YET PLAYTESTED**
P0-1 … P0-6 are applied across 7 files:
`chapter1/ch1_glitch_crater.gd`, `regions/ironhold_region.gd`, `combat/player_combat.gd`,
`game_manager.gd`, `combat/combat_arena.gd`, `background_manager.gd`,
`scenes/combat/combat_arena.tscn`.

Static checks run after the edits: brackets balanced and indentation consistent in all 7;
every `@onready` path in the 7 re-linked scenes resolves against its `.tscn`; no new broken
`res://` references anywhere in `scripts/` or `scenes/`; reachability 59/74 → 71/74.

**None of this has been run in Godot.** Static analysis cannot catch a runtime type error, a
signal that never fires, or a scene that loads but plays badly. What remains for you:

1. Delete the stale `.git/index.lock` (see the P0-7 correction), then open the project in
   Godot and check the Output panel for parse errors before anything else.
2. **Play the prologue through the end of Chapter 2.** Specifically confirm: the crater now
   leads into the Elara meeting; the three new Ironhold gates appear, work, and disappear once
   cleared; the Clockwork Automaton can only be fought once; Root Access opens and closes in
   the combat arena without freezing.
3. Start a **new** game rather than loading an old save — old saves carry the inflated `max_hp`.
4. Write down every place you were confused or bored. You have 169 markdown reports in `docs/`
   (24,527 lines) and not one playthrough log. That ratio is the problem in miniature.

### Phase 1 — Prove the art pipeline on ONE scene (1–2 weeks)
This is the decision that determines whether the project is finishable.

Pick **Oakhaven**. Build it as a scene a designer authored, not a scene `_ready()` emitted:
- One real tileset with terrain sets and autotiling — not the current
  `posmod(cell_x*17 + cell_y*31 + ...)` hash scatter (`asset_manager.gd:1444`) that sprinkles
  roofs and water across the floor.
- 3–4 real character sprites at a consistent resolution, with a real spritesheet.
- One `AnimationPlayer` with hand-keyed animations, replacing `TweenAnimator` for those characters.
- One music track and ~10 sound effects as actual files.
- One font.

Then compare it side by side against the current rectangle version. **If you cannot produce
one scene that looks good, 74 scenes will not save you.** If you can, you have a template and
a per-scene cost estimate — and only then does it make sense to touch the other 73.

Concretely decide, before you start: are you doing pixel art or painted 2D? At what resolution?
Who or what is making it? The ComfyUI experiments in `assets/art_sources/` (381 images) suggest
you have been exploring this — finish that exploration into a locked style guide first.

### Phase 2 — Make the systems honest — **MECHANICAL HALF DONE**
Applied: P1-2, P1-3, P1-6 (both halves), P1-7, P1-8, P1-9 (partly), P1-10, P1-11 (both halves).
Files touched beyond Phase 0: `choice_consequences.gd`, `combat/enemy_base.gd`,
plus further edits to `game_manager.gd` and `combat/player_combat.gd`.

**Be aware before you next play:** removing the DDA neutral bonus takes ~8.75% off all of your
damage, soul gain and healing, and the token fix removes a free extra hit whenever you were
struck mid-swing. Combat will feel harder than every test you have run so far. That is the
correct baseline — do not re-tune upward until you have played it.

**Still yours to decide** (these change how the game plays, so I did not guess):
- **P1-1 Defense** — implement mitigation in `take_damage`, or delete DEF everywhere.
- **P1-12 MP** — give spells an MP cost, or delete MP and the mana potions.
- **P1-5 Pogo / block / parry** — pogo is ~135 DPS versus the combo chain's ~57, and both
  defensive options are free. Cooldowns and costs are a feel decision.
- **P1-4 The curve** — either build content for levels 15–20 or lower the cap to where the
  content ends. Lowering the cap is the cheaper, more honest option.

The principle for the rest: **either implement it or delete it.**
- Defense: implement mitigation in `take_damage`, or remove DEF from items/buffs/UI.
- MP: give spells an MP cost, or delete MP.
- The 17 advertised choice abilities: wire 3–4 of them properly, delete the rest.
- Pogo, block and parry need cooldowns/costs that make the combo chain worth using.
- Retune the scaling curve so level 15–19 has content, or lower the cap to where content ends.

Delete, don't keep: `cutscene_director.gd` (892 orphaned lines), `cinematic_vfx.gd`, one of the
two transition systems, one of the two damage-number systems, two of the three shake systems.
This is ~2,000 lines of removal and it will make everything after it faster to change.

### Phase 3 — Rebalance the story budget (2 weeks)
- Cut Chapters 1–3 by ~30%. Move the exposition Kaelen speaks aloud
  (`ch2_ironhold_gate.gd:217` "...injecting forged token...") into what the player *sees*.
- Spend that budget on Chapters 4–10, which hold your only original idea and are one-twelfth
  the size.
- Replace the final quiz with an actual encounter, or make the quiz answers non-obvious —
  right now option 0 wins three times out of three.
- Give the late cast names and bodies instead of role labels.
- Update the design docs to describe the game you actually built, or delete them. They currently
  misinform anyone who reads them, including you in six months.

### What to stop doing
You have 169 markdown status reports (24,527 lines) and 28 log files documenting an art pipeline
that produced 6 tileset PNGs. The reports are not progress; they are a record of exploration that
never landed. **One finished scene is worth more than all of them.** Until a single scene exists
that was designed rather than generated, the other 73 are liability, not inventory.

### Honest scope check
77,605 lines of working systems code is real and substantial work — the camera, the spritesheet
slicer, the `glitch_effect` shader, `late_game_hazard_trial.gd`, and the Chapter 1–2 dialogue are
all genuinely good. But "best possible graphics, cutscenes and animations" is an art-production
problem, and art production for a 10-chapter RPG is not something code volume can substitute for.

The realistic path is to **shrink the container to fit the art you can actually make**: take the
prologue plus Chapter 1 — one town, one dungeon, one boss, one companion — and finish it to a
standard you would show someone. A polished 45-minute vertical slice is a portfolio piece and a
fundable pitch. Ten chapters of rectangles is neither.
