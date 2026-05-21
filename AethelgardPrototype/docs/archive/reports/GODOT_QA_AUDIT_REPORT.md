# Godot 4.6 GDScript QA Audit Report — AethelgardPrototype

**Date:** 2025-07-13  
**Scope:** 94 `.gd` files, `export_presets.cfg`, `project.godot`  
**Focus Areas:** Export presets, Memory leaks, `_process` optimization, Signal connections, Resource loading, Autoload overhead

---

## Summary

| Severity | Count |
|----------|-------|
| CRITICAL | 3     |
| HIGH     | 6     |
| MEDIUM   | 7     |
| LOW      | 3     |
| **Total**| **19**|

---

## CRITICAL Bugs

### BUG-01 — Empty Windows Application Icon

**Severity:** CRITICAL  
**File:** `export_presets.cfg` line 30  
**Root Cause:** `application/icon=""` — Windows export will produce an `.exe` with no embedded icon. Some distribution platforms (Steam, itch.io) reject unsigned executables with missing icons. Windows SmartScreen warnings become more aggressive with missing metadata.

```ini
# BEFORE (line 30):
application/icon=""

# AFTER:
application/icon="res://icon.svg"
```

Also fix the console wrapper icon on line 31:
```ini
# BEFORE (line 31):
application/console_wrapper_icon=""

# AFTER:
application/console_wrapper_icon="res://icon.svg"
```

---

### BUG-02 — PWA Icons All Empty (Web Export Broken)

**Severity:** CRITICAL  
**File:** `export_presets.cfg` lines 76–78  
**Root Cause:** PWA is `enabled=true` (line 72) but all three mandatory icon sizes are empty strings. On mobile, the "Add to Home Screen" prompt will fail or show a blank icon. Chrome Lighthouse will flag the PWA as non-installable.

```ini
# BEFORE (lines 76-78):
progressive_web_app/icon_144x144=""
progressive_web_app/icon_180x180=""
progressive_web_app/icon_512x512=""

# AFTER — create these PNGs from icon.svg, then reference them:
progressive_web_app/icon_144x144="res://exports/web/icon_144.png"
progressive_web_app/icon_180x180="res://exports/web/icon_180.png"
progressive_web_app/icon_512x512="res://exports/web/icon_512.png"
```

**Action Required:** Export `icon.svg` to 144×144, 180×180, and 512×512 PNG files and place them at those paths. Alternatively, disable PWA if you don't need it:
```ini
progressive_web_app/enabled=false
```

---

### BUG-03 — AssetManager Synchronously Loads ALL 130+ Assets at Startup

**Severity:** CRITICAL  
**File:** `scripts/asset_manager.gd` lines 446–468  
**Root Cause:** `_ready()` calls `scan_all_assets()` which iterates 130+ entries in `ASSET_PATHS` and calls `load()` on every one synchronously. This blocks the main thread for **several seconds** on startup (especially on Web where I/O latency is high), producing a frozen splash screen. Additionally, `print()` is called for every asset — debug output that should not ship in release builds.

```gdscript
# BEFORE (lines 446-468):
func _ready() -> void:
	print("AssetManager initialized - Scanning for assets...")
	scan_all_assets()

func scan_all_assets() -> void:
	for asset_name in ASSET_PATHS:
		var path = ASSET_PATHS[asset_name]
		var exists = ResourceLoader.exists(path)
		assets_available[asset_name] = exists
		if exists:
			var texture = load(path)
			if texture:
				loaded_assets[asset_name] = texture
				print("✓ Asset loaded: ", asset_name)
			else:
				print("✗ Asset failed to load: ", asset_name)
				assets_available[asset_name] = false
		else:
			print("○ Asset not found (using placeholder): ", asset_name)

# AFTER — Threaded background loading with lazy fallback:
var _pending_loads: Array[String] = []
var _scan_complete := false

func _ready() -> void:
	if OS.is_debug_build():
		print("AssetManager initialized - Scanning for assets...")
	scan_all_assets_threaded()

func scan_all_assets_threaded() -> void:
	## Kick off threaded loads for all assets; callers get placeholders until ready.
	for asset_name in ASSET_PATHS:
		var path: String = ASSET_PATHS[asset_name]
		var exists := ResourceLoader.exists(path)
		assets_available[asset_name] = exists
		if exists:
			ResourceLoader.load_threaded_request(path)
			_pending_loads.append(asset_name)
		else:
			if OS.is_debug_build():
				print("○ Asset not found (placeholder): ", asset_name)
	_scan_complete = false
	set_process(true)   # poll completion in _process

func _process(_delta: float) -> void:
	if _scan_complete:
		set_process(false)
		return
	var still_pending: Array[String] = []
	for asset_name in _pending_loads:
		var path: String = ASSET_PATHS[asset_name]
		var status := ResourceLoader.load_threaded_get_status(path)
		if status == ResourceLoader.THREAD_LOAD_LOADED:
			var res = ResourceLoader.load_threaded_get(path)
			if res:
				loaded_assets[asset_name] = res
		elif status == ResourceLoader.THREAD_LOAD_IN_PROGRESS:
			still_pending.append(asset_name)
		else:
			assets_available[asset_name] = false
	_pending_loads = still_pending
	if _pending_loads.is_empty():
		_scan_complete = true
		set_process(false)
		if OS.is_debug_build():
			print("AssetManager: All assets loaded (%d)" % loaded_assets.size())
```

---

## HIGH Bugs

### BUG-04 — MusicManager Connects `state_changed` Without `is_connected` Guard

**Severity:** HIGH  
**File:** `scripts/music_manager.gd` lines 428–429  
**Root Cause:** `_setup_dynamic_music()` directly calls `.connect()` with no `is_connected()` check. If this method is ever called a second time (refactor, hot-reload, or `_ready()` re-entry on scene edge cases), the signal fires the callback twice, causing double music transitions, audio glitches, or layered tracks.

```gdscript
# BEFORE (lines 425-429):
func _setup_dynamic_music() -> void:
	if has_node("/root/GameManager"):
		if GameManager.has_signal("state_changed"):
			GameManager.state_changed.connect(_on_game_state_changed)

# AFTER:
func _setup_dynamic_music() -> void:
	if has_node("/root/GameManager"):
		if GameManager.has_signal("state_changed"):
			if not GameManager.state_changed.is_connected(_on_game_state_changed):
				GameManager.state_changed.connect(_on_game_state_changed)
```

---

### BUG-05 — Region Scripts Run Unthrottled `_process()` Every Frame

**Severity:** HIGH  
**Files:**
- `scripts/regions/oakhaven_region.gd` lines 83–88
- `scripts/regions/ironhold_region.gd` lines 78–83
- `scripts/regions/fractured_wastes_region.gd` lines 93–100

**Root Cause:** All three region scripts call `_update_zone()`, `_clamp_player()`, and `_update_ui()` every single frame (~60 fps). `_update_ui()` (e.g., oakhaven_region.gd line 914) performs string formatting with `%` operator, dictionary lookups into `GameManager.player_stats`, and `has_node()` checks — all per frame. `fractured_wastes_region.gd` additionally runs `_process_storms(delta)` and `_animate_corruption(delta)` every frame.

The UI label (HP, XP, Gold, Zone name) changes only when player stats change — not 60 times per second.

```gdscript
# BEFORE (oakhaven_region.gd lines 83-88):
func _process(_delta: float) -> void:
	if not _player:
		return
	_update_zone(_player.global_position)
	_clamp_player()
	_update_ui()

# AFTER — Throttle UI to 4 Hz, keep movement checks at full rate:
var _ui_timer: float = 0.0
const UI_UPDATE_INTERVAL: float = 0.25  # 4 Hz

func _process(delta: float) -> void:
	if not _player:
		return
	_update_zone(_player.global_position)
	_clamp_player()
	_ui_timer += delta
	if _ui_timer >= UI_UPDATE_INTERVAL:
		_ui_timer = 0.0
		_update_ui()
```

Apply the same pattern to `ironhold_region.gd` and `fractured_wastes_region.gd`. For the wastes, storms and corruption animation should keep running at full framerate since they're visual effects:

```gdscript
# fractured_wastes_region.gd — AFTER:
func _process(delta: float) -> void:
	if not _player:
		return
	_update_zone(_player.global_position)
	_clamp_player()
	_ui_timer += delta
	if _ui_timer >= UI_UPDATE_INTERVAL:
		_ui_timer = 0.0
		_update_ui()
	_process_storms(delta)
	_animate_corruption(delta)
```

---

### BUG-06 — RandomEncounterSystem Calls `get_nodes_in_group("player")` Every Frame

**Severity:** HIGH  
**File:** `scripts/combat/random_encounter_system.gd` lines 300–320  
**Root Cause:** `_process()` calls `get_tree().get_nodes_in_group("player")` on every frame during exploration. This allocates a new `Array` each frame for a group that almost always contains exactly one node. The player reference should be cached.

```gdscript
# BEFORE (lines 318-323):
	var players = get_tree().get_nodes_in_group("player")
	if players.is_empty():
		return
	var player = players[0] as Node2D
	if not is_instance_valid(player):
		return

# AFTER — Cache the player reference:
# Add at class level:
var _cached_player: Node2D = null

# In _process, replace the group lookup:
	if not is_instance_valid(_cached_player):
		var players = get_tree().get_nodes_in_group("player")
		if players.is_empty():
			return
		_cached_player = players[0] as Node2D
	var player := _cached_player
```

---

### BUG-07 — Runtime `load()` on Hot Paths Instead of `preload()`

**Severity:** HIGH  
**Files:**
- `scripts/regions/oakhaven_region.gd` ~line 253
- `scripts/regions/ironhold_region.gd` ~line 263
- `scripts/regions/fractured_wastes_region.gd` ~line 303
- `scripts/combat/arena_manager.gd` ~lines 431–440 (multiple enemy scripts)
- `scripts/music_manager.gd` ~line 591 (audio streams)

**Root Cause:** `load()` is called at runtime for scripts and resources that are known at compile time. `preload()` resolves at parse time and has zero runtime cost. `load()` causes synchronous I/O stalls, especially on Web exports.

For scripts used as part of the game flow (enemy scripts, player_topdown.gd), switch to `preload()`:

```gdscript
# BEFORE (example from a region):
var PlayerTopdown = load("res://scripts/exploration/player_topdown.gd")

# AFTER:
const PlayerTopdown = preload("res://scripts/exploration/player_topdown.gd")
```

For enemy scripts in `arena_manager.gd`:
```gdscript
# BEFORE:
func _get_enemy_script(enemy_type: String):
	match enemy_type:
		"corrupted_rat":
			return load("res://scripts/combat/enemies/corrupted_rat.gd")
		"phase_spider":
			return load("res://scripts/combat/enemies/phase_spider.gd")

# AFTER:
const CorruptedRatScript = preload("res://scripts/combat/enemies/corrupted_rat.gd")
const PhaseSpiderScript = preload("res://scripts/combat/enemies/phase_spider.gd")

func _get_enemy_script(enemy_type: String):
	match enemy_type:
		"corrupted_rat":
			return CorruptedRatScript
		"phase_spider":
			return PhaseSpiderScript
```

For `music_manager.gd` audio streams, use `ResourceLoader.load_threaded_request()` or `preload()` for known tracks.

---

### BUG-08 — `player_topdown.gd` Multi-Group Scan Concatenates 3 Arrays in `_spawn_data_vision_labels()`

**Severity:** HIGH  
**File:** `scripts/exploration/player_topdown.gd` line 294  
**Root Cause:** `get_tree().get_nodes_in_group("interactable") + get_tree().get_nodes_in_group("npc") + get_tree().get_nodes_in_group("enemy")` allocates 3 arrays and concatenates them into a 4th. If this triggers during gameplay with many nodes, it causes a GC spike. Also creates `Label.new()` per visible object, which should be pooled.

```gdscript
# BEFORE (line 294):
	var all_bodies = get_tree().get_nodes_in_group("interactable") + get_tree().get_nodes_in_group("npc") + get_tree().get_nodes_in_group("enemy")

# AFTER — Iterate groups directly without concatenation:
	for group_name in ["interactable", "npc", "enemy"]:
		for obj in get_tree().get_nodes_in_group(group_name):
			if not is_instance_valid(obj) or not obj is Node2D:
				continue
			var dist = global_position.distance_to(obj.global_position)
			if dist > 300:
				continue
			# ... create label ...
```

---

### BUG-09 — TweenAnimator Static Dictionaries Grow Unbounded Across Scene Changes

**Severity:** HIGH  
**File:** `scripts/effects/tween_animator.gd` lines 17–22  
**Root Cause:** `_active_tweens`, `_base_positions`, and `_base_modulates` are `static var` dictionaries keyed by `node.get_instance_id()`. When nodes are freed on scene transitions, their entries remain in these dictionaries as stale keys. Over many scene transitions, memory grows. The `_last_cleanup_frame` on line 24 suggests periodic cleanup exists, but stale entries persist between cleanup intervals.

```gdscript
# FIX — Add a cleanup method and call it on scene transitions:
static func cleanup_stale_entries() -> void:
	## Call from SceneTransitionManager before changing scenes
	var stale_keys: Array = []
	for node_id in _active_tweens:
		if not is_instance_id_valid(node_id):
			stale_keys.append(node_id)
	for key in stale_keys:
		_active_tweens.erase(key)
		_base_positions.erase(key)
		_base_modulates.erase(key)
```

Then in `scene_transition_manager.gd`, call `TweenAnimator.cleanup_stale_entries()` before loading the new scene.

---

## MEDIUM Bugs

### BUG-10 — 29 Autoloads Registered in `project.godot`

**Severity:** MEDIUM  
**File:** `project.godot` lines 15–44  
**Root Cause:** Every autoload is instantiated at engine startup before the first frame renders. With 29 autoloads, the combined `_ready()` cost is significant:
- `AssetManager` alone loads 130+ assets synchronously (BUG-03)
- `SFXManager` defines synthesis tables and possibly pre-generates waveforms
- `MusicManager`, `CombatFX`, `GameJuice`, `VFXLibrary` all create CanvasLayers
- `GlitchOverlay` creates visual overlays
- Several autoloads (`UIStack`, `StatusWindow`, `PauseScreen`) create UI trees that aren't needed until first use

**Recommendation:** Consider lazy-loading pattern for non-critical autoloads:
```gdscript
# Instead of creating all UI in _ready(), defer it:
var _initialized := false

func _ensure_init() -> void:
	if _initialized:
		return
	_initialized = true
	_build_ui()  # expensive work

func show():
	_ensure_init()
	visible = true
```

Candidates for lazy init: `LevelUpUI`, `StatusWindow`, `PauseScreen`, `ShopSystem`, `WorldMapUI`, `CreditsScreen`, `LoreJournal`.

---

### BUG-11 — `game_manager.gd` `_process()` Runs Playtime / DDA / Admin Cooldown Ticks Every Frame

**Severity:** MEDIUM  
**File:** `scripts/game_manager.gd` lines 288–293  
**Root Cause:** `_process()` runs every frame and ticks:
- Playtime counter (float add)
- Speedrun timer (float add)
- Admin cooldown (float subtract)
- DDA window timer (float subtract)

While individually cheap, the `_process` callback overhead itself is unnecessary when none of these systems are active. Use `set_process(false)` when idle.

```gdscript
# In _ready():
	set_process(false)  # start idle

# When any timer becomes active (e.g. admin cooldown starts):
	set_process(true)

# In _process — check if all timers are idle:
	if _admin_cooldown <= 0.0 and _dda_window <= 0.0 and not _speedrun_active:
		set_process(false)
```

---

### BUG-12 — `asset_manager.gd` Debug `print()` Statements in Production

**Severity:** MEDIUM  
**File:** `scripts/asset_manager.gd` lines 447, 462–467  
**Root Cause:** `print("✓ Asset loaded: ...")` runs for every loaded asset (130+) at startup. On Web exports, each `print()` becomes a `console.log()` — observable by users via F12 DevTools and degrades performance with high-volume console output.

```gdscript
# Wrap all debug prints:
if OS.is_debug_build():
	print("✓ Asset loaded: ", asset_name)
```

This applies to ALL `print()` calls in the file. (Already addressed in BUG-03 fix.)

---

### BUG-13 — `glitch_overlay.gd` No `_exit_tree()` Disconnect

**Severity:** MEDIUM (mitigated — autoload)  
**File:** `scripts/glitch_overlay.gd` lines 67–70  
**Root Cause:** Connects to `GameManager.glitch_meter_changed` but has no `_exit_tree()`. This is **mitigated** because `GlitchOverlay` is an autoload and persists for the app lifetime. However, if this script is ever moved off autoload or instantiated in a scene, the signal leak will manifest.

```gdscript
# DEFENSIVE FIX — Add _exit_tree for future-proofing:
func _exit_tree() -> void:
	if has_node("/root/GameManager"):
		if GameManager.glitch_meter_changed.is_connected(_on_glitch_changed):
			GameManager.glitch_meter_changed.disconnect(_on_glitch_changed)
```

---

### BUG-14 — Web Export Missing `offline.html` Page

**Severity:** MEDIUM  
**File:** `export_presets.cfg` line 73  
**Root Cause:** `progressive_web_app/offline_page="offline.html"` references a file that likely doesn't exist in the project (no HTML files were found in the workspace). The PWA service worker will fail to cache the offline page, causing broken offline behavior.

**Fix:** Either create `res://offline.html` with a minimal "No connection" page, or set the value to `""` to use Godot's default.

---

### BUG-15 — `enemy_base.gd` Enemies Cache Not Invalidated

**Severity:** MEDIUM  
**File:** `scripts/combat/enemy_base.gd` line 1536  
**Root Cause:** `_enemies_cache = get_tree().get_nodes_in_group("enemies")` is stored as a static cache. If enemies are spawned/despawned after caching, stale references persist. Any code iterating this cached array must guard with `is_instance_valid()`.

```gdscript
# Ensure cache is refreshed when enemies change:
# Add to _ready():
	get_tree().node_added.connect(_invalidate_enemy_cache)
	get_tree().node_removed.connect(_invalidate_enemy_cache)

static func _invalidate_enemy_cache(_node: Node) -> void:
	_enemies_cache.clear()
```

---

### BUG-16 — `SFXManager` Cache Unbounded in Long Sessions

**Severity:** MEDIUM  
**File:** `scripts/sfx_manager.gd` line 35  
**Root Cause:** `MAX_CACHE_SIZE = 64` is declared but it's unclear whether eviction is enforced when the cache exceeds 64 entries. If synthesis variants (pitch randomization) produce unique cache keys, the cache could grow beyond 64 in long play sessions.

**Action:** Verify that the cache eviction logic exists and triggers when `_cache.size() > MAX_CACHE_SIZE`.

---

## LOW Bugs

### BUG-17 — `combat_effects.gd` and `game_juice.gd` `_process()` Could Use `set_process(false)`

**Severity:** LOW  
**Files:**
- `scripts/combat_effects.gd` lines 68–97
- `scripts/effects/game_juice.gd` lines 83–86

**Root Cause:** Both scripts have good early-return guards when idle (no hitstop, no combo, no slowmo). However, the `_process()` callback itself still fires every frame even when idle, invoking the virtual function dispatch overhead. Using `set_process(false)` and only enabling it when effects start would eliminate the idle overhead entirely.

```gdscript
# In _ready():
	set_process(false)

# When effect starts (e.g., hitstop):
	set_process(true)

# At end of _process when all effects cleared:
	if _all_idle():
		set_process(false)
```

---

### BUG-18 — Web Export Uses Forward Plus Renderer

**Severity:** LOW  
**File:** `project.godot` line 12 (`config/features=PackedStringArray("4.6", "Forward Plus")`)  
**Root Cause:** Forward Plus is the desktop-class renderer. For Web (WebGL2) targets, the `Compatibility` renderer is recommended by the Godot documentation due to WebGL2 limitations. The current config may work, but could cause visual glitches or performance issues on mobile browsers.

**Recommendation:** For Web exports, consider overriding the renderer in the Web export preset or using the Compatibility renderer project-wide if desktop visual fidelity is not required.

---

### BUG-19 — No Linux / macOS Export Presets

**Severity:** LOW  
**File:** `export_presets.cfg`  
**Root Cause:** Only Windows Desktop and Web presets are defined. If the game is intended for cross-platform release, additional presets are needed.

---

## Quick-Reference Fix Matrix

| Bug   | Fix Effort | Impact | File(s) |
|-------|-----------|--------|---------|
| BUG-01 | 1 min | CRITICAL | `export_presets.cfg` L30–31 |
| BUG-02 | 10 min | CRITICAL | `export_presets.cfg` L76–78 + create PNGs |
| BUG-03 | 30 min | CRITICAL | `scripts/asset_manager.gd` L446–468 |
| BUG-04 | 1 min | HIGH | `scripts/music_manager.gd` L429 |
| BUG-05 | 5 min | HIGH | 3 region scripts |
| BUG-06 | 3 min | HIGH | `scripts/combat/random_encounter_system.gd` L318 |
| BUG-07 | 15 min | HIGH | 5+ files |
| BUG-08 | 5 min | HIGH | `scripts/exploration/player_topdown.gd` L294 |
| BUG-09 | 10 min | HIGH | `scripts/effects/tween_animator.gd` + scene_transition_manager |
| BUG-10 | 60 min | MEDIUM | `project.godot` + 7 autoload scripts |
| BUG-11 | 5 min | MEDIUM | `scripts/game_manager.gd` L288 |
| BUG-12 | 5 min | MEDIUM | `scripts/asset_manager.gd` (all prints) |
| BUG-13 | 2 min | MEDIUM | `scripts/glitch_overlay.gd` |
| BUG-14 | 5 min | MEDIUM | Create `offline.html` or fix config |
| BUG-15 | 10 min | MEDIUM | `scripts/combat/enemy_base.gd` L1536 |
| BUG-16 | 5 min | MEDIUM | `scripts/sfx_manager.gd` |
| BUG-17 | 5 min | LOW | `combat_effects.gd` + `game_juice.gd` |
| BUG-18 | 2 min | LOW | `project.godot` renderer config |
| BUG-19 | 10 min | LOW | `export_presets.cfg` |

---

## Positive Patterns Observed

These well-implemented patterns should be maintained:

1. **Signal disconnect guards** — `player_combat.gd`, `combat_arena.gd`, `enemy_base.gd`, `ch1_oakhaven_village.gd` all properly disconnect from autoload signals in `_exit_tree()` with `is_connected()` checks. 
2. **Off-screen culling** — `enemy_base.gd` `_physics_process()` (line ~220) skips 2 of 3 frames when enemies are off-screen.  
3. **Cached projectile script** — `player_combat.gd` caches the `GDScript.new()` result in a `static var` to avoid re-creating it.  
4. **Threaded scene loading** — `scene_transition_manager.gd` uses `ResourceLoader.load_threaded_request()`.  
5. **Timer-based polling** — `achievements.gd` uses Timer nodes instead of `_process()` polling.  
6. **`is_connected()` guards** — Many autoload signal connections use guards (e.g., `achievements.gd`, `combat_arena.gd`, `enemy_base.gd`).  
7. **`CombatFX`/`GameJuice` early returns** — Both have good idle detection in their `_process()` loops.

---

## Recommended Fix Priority

**Sprint 1 (Ship-blockers):**
- BUG-01 + BUG-02: Fix export icons (15 min)
- BUG-03: Async asset loading (30 min)

**Sprint 2 (Performance):**
- BUG-04: MusicManager guard (1 min)
- BUG-05: Region `_process` throttling (10 min)
- BUG-06: Cache player reference (3 min)
- BUG-07: `preload()` conversion (15 min)

**Sprint 3 (Polish):**
- BUG-08 through BUG-12 (remaining medium/high items)

**Backlog:**
- BUG-13 through BUG-19
