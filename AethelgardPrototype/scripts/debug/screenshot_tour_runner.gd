extends RefCounted
## The screenshot tour, independent of how it's started. It loads the Act 1 scenes
## with a REAL renderer and saves what the player would see, plus layout checks
## the headless tests can't do:
##   1. Scenes: each Act 1 scene, a few seconds after it loads.
##   2. UI: the pause screen and the Controls screen, over Oakhaven.
##      Plus t06_shop_discount: the apothecary after Forge Line Supply's 5 % discount.
##   3. Dialogue stress: for every authored .dlg (prologue, ch1, ch2), the
##      longest line and the longest choice, shown in the real dialogue box.
##      Checked automatically: the box stays on screen, the choices stay on
##      screen and don't cover the box, and no option is wider than the screen.
##   4. Contact sheets (thumbnails of everything) and report.md.
##
## Two ways in, same tour:
##   - from the editor copy: tests/run_screenshots.ps1 (tests/screenshot_tour.gd);
##   - inside an exported debug build: tools/export_windows.ps1 -Tour, which
##     starts the game with "-- --debug-tour" (scripts/core/debug_test_mode.gd).
## Release builds don't contain this file (export_presets.cfg excludes scripts/debug/).
## run() returns the exit code: 0 = no problems, 1 = problems (in report.md), 2 = refused.

const SCENES := [
	["main_menu", "res://scenes/main_menu.tscn", 2.5],
	["ch1_crash_site", "res://scenes/chapter1/opening_crash_site_hook.tscn", 5.0],
	["ch1_elara_meeting", "res://scenes/chapter1/elara_meeting.tscn", 4.0],
	["ch1_broken_mile", "res://scenes/chapter1/path_to_oakhaven.tscn", 4.0],
	["ch1_oakhaven_village", "res://scenes/chapter1/oakhaven_village.tscn", 4.0],
	["ch1_oakhaven_region", "res://scenes/regions/oakhaven_region.tscn", 3.0],
	["ch1_aldric", "res://scenes/chapter1/tutorial_knight_boss.tscn", 4.0],
	["ch1_shatter", "res://scenes/chapter1/shatter_transition.tscn", 3.0],
	["ch2_ironhold_gate", "res://scenes/chapter2/ironhold_gate.tscn", 4.0],
	["ch2_ironhold_region", "res://scenes/regions/ironhold_region.tscn", 3.0],
	["ch2_command_hall", "res://scenes/chapter2/seraphina_encounter.tscn", 4.0],
	["ch2_arena", "res://scenes/chapter2/arena_district.tscn", 4.0],
	["ch2_clock_tower", "res://scenes/chapter2/clock_tower.tscn", 4.0],
	["ch2_underground", "res://scenes/chapter2/underground_network.tscn", 4.0],
	["ch2_proxy", "res://scenes/chapter2/administrator_boss.tscn", 4.0],
	["ch2_fragment_two", "res://scenes/chapter2/seraphina_choice.tscn", 4.0],
	["ch2_act1_end", "res://scenes/chapter2/ch2_ending.tscn", 4.0],
]
## The Chapter 1 shatter scene once per Aldric outcome. Each stop sets the story flags
## aldric.dlg leaves for that route (plus a village flag and the Elara flag the scene
## expects), loads the REAL scene and lets it run: the runner only taps "advance" on each
## line (the same flags DialogueManager._input sets) until the first line of the route's
## shatter.dlg node is on screen, then captures. [id, dlg node, flags]
const SHATTER_SCENE := "res://scenes/chapter1/shatter_transition.tscn"
const SHATTER_DLG := "res://dialogue/ch1/shatter.dlg"
const SHATTER_TIMEOUT := 120.0   # real seconds; the intro (bridge, shift, shatter) is ~25 s
const SHATTER_ROUTES := [
	["ch1_shatter_kill", "after_kill", {
		"ch1_knight_killed": true, "ch1_aldric_kill_owned": true,
		"ch1_oakhaven_warned_villagers": true, "ch1_elara_trusted": true}],
	["ch1_shatter_spare", "after_spare", {
		"ch1_knight_spared": true,
		"ch1_oakhaven_warned_villagers": true, "ch1_elara_trusted": true}],
	["ch1_shatter_purge", "after_purge", {
		"ch1_root_purge": true, "ch1_knight_spared": true,
		"ch1_oakhaven_warned_villagers": true, "ch1_elara_trusted": true}],
]
## Chapter 1 breadcrumb in the HUD (story Y1-P0-T05, AC-9). The breadcrumb only shows in
## EXPLORATION, and the plain scene stops capture mid-dialogue (the crash site hides it for
## its whole run; the Broken Mile never leaves PROLOGUE). This stop presets the flags the
## scenes before Oakhaven leave, plays the REAL village (entrance, then Elara's stew; every
## choice gets the first option, as in chapter1_route_test) and captures the step-6 afternoon
## objective once the player is exploring. ch1_oakhaven_entered and ch1_stew_done are NOT
## preset: the real entrance and stew must set them.
const BREADCRUMB_ID := "ch1_breadcrumb_oakhaven"
const BREADCRUMB_SCENE := "res://scenes/chapter1/oakhaven_village.tscn"
const BREADCRUMB_OBJECTIVE := "Spend the afternoon in Oakhaven. Meet the people here."
const BREADCRUMB_FLAGS := {
	"ch1_opening_hook_started": true, "ch1_crash_trace_seen": true,
	"ch1_opening_hook_complete": true, "elara_met": true, "ch1_elara_trusted": true,
	"ch1_broken_mile_entered": true, "ch1_personal_goal_set": true}
const BREADCRUMB_TIMEOUT := 90.0   # real seconds
## Forge Line Supply discount in the real shop (story Y1-P0-T06, AC-3/AC-7). Garro's quest is
## completed through SideQuestManager.complete_optional_objective, so the 0.05 discount comes
## from its real grant_rewards, not from setting GameManager.shop_discount by hand. The real
## apothecary is then opened over BACKDROP and the health_potion row must read the discounted
## price before the capture; a mismatch is a PROBLEM, never patched up.
const SHOP_DISCOUNT_ID := "t06_shop_discount"
const SHOP_QUEST := "ironhold_blacksmith_material_request"
const SHOP_KIND := "apothecary"
const SHOP_ITEM := "health_potion"
const SHOP_DISCOUNT := 0.05        # Forge Line Supply's shop_discount reward
const SHOP_RAW_PRICE := 30         # ShopSystem.SHOP_ITEMS["health_potion"]["buy_price"]
const SHOP_SHOWN_PRICE := 29       # 30 at 5 % off, as get_buy_price rounds it
const SHOP_GOLD := 999             # enough that the row is affordable (enabled)
## Screen flashes through SceneTransitions.flash() (story Y1-P0-T08, AC-5). Each stop resets the
## run (GameManager.reset_game(), no flags preset), loads the REAL scene, waits out its own 1.5 s
## fade-in, triggers one flash and captures the first rendered frame after it: the ease-out is
## exponential, so at 0.1-0.2 s only ~20-35 % of the peak is left; the overlay alpha read just
## before the capture is written to the notes. [id, scene, how the flash is triggered]
##   ch3_archive_flash: the scene's own floor-4 call sits inside the Source Key coroutine, so the
##     stop calls SceneTransitions.flash with the archive floor-4 arguments; the routing itself is
##     proven by tests/integration/vfx/screen_flash_test.gd F1. Side effects of loading the scene
##     (its _ready): ch3_archive_entered, current_chapter 3, an auto-save into the isolated
##     user:// dir, two Chapter 3 side quests discovered; the next stop's reset_game() clears the
##     GameManager part.
##   ch1_oakhaven_flash: drives the scene's own _on_dlg_event("fracture_spreads") (purple tint).
const FLASH_SETTLE := 1.8          # the scenes' own fade-in is 1.5 s
const FLASH_STOPS := [
	["ch3_archive_flash", "res://scenes/chapter3/archive_depths.tscn", "direct"],
	["ch1_oakhaven_flash", "res://scenes/chapter1/oakhaven_village.tscn", "fracture_spreads"],
]
const ARCHIVE_FLASH_COLOR := Color(0.2, 0.6, 1.0, 0.4)   # ch3_archive_depths.gd floor-4 call
const ARCHIVE_FLASH_SECONDS := 0.8
const FLASH_MIN_SHIFT := 0.01      # mean-colour shift toward the flash colour a flash frame must show
const DLG_DIRS := ["res://dialogue/prologue", "res://dialogue/ch1", "res://dialogue/ch2"]
const BACKDROP := "res://scenes/regions/oakhaven_region.tscn"
const THUMB := Vector2i(320, 180)

var _out := ""
var _only: PackedStringArray = []
var _shots: Array[Dictionary] = []      # {id, file, group, scene, now, notes}
var _thumbs: Dictionary = {}            # id -> Image (thumbnail)
var _problems: Array[String] = []


var tree: SceneTree


func _init(t: SceneTree) -> void:
	tree = t


func run() -> int:
	await tree.process_frame
	if DisplayServer.get_name() == "headless":
		push_error("The screenshot tour needs a renderer. Run it without --headless.")
		return 2
	if not OS.get_user_data_dir().contains("aeth_phase0_test"):
		push_error("Refusing to run: user data dir is not isolated. Use tests/run_screenshots.ps1 or tools/export_windows.ps1 -Tour.")
		return 2
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):
			_out = arg.trim_prefix("--out=")
		elif arg.begins_with("--only="):
			_only = arg.trim_prefix("--only=").split(",", false)
	if _out == "":
		_out = OS.get_user_data_dir().path_join("screenshots")
	DirAccess.make_dir_recursive_absolute(_out)
	AudioServer.set_bus_mute(0, true)
	print("Screenshot tour → %s" % _out)

	for s in SCENES:
		if _wanted(s[0]):
			await _scene_shot(s[0], s[1], s[2])
	for r in SHATTER_ROUTES:
		if _wanted(r[0]):
			await _shatter_route_shot(r[0], r[1], r[2])
	if _wanted(BREADCRUMB_ID):
		await _breadcrumb_shot(BREADCRUMB_ID)
	if _wanted("ui"):
		await _ui_shots()
	if _wanted(SHOP_DISCOUNT_ID):
		await _shop_discount_shot(SHOP_DISCOUNT_ID)
	for f in FLASH_STOPS:
		if _wanted(f[0]):
			await _flash_shot(f[0], f[1], f[2])
	if _wanted("dlg"):
		await _dialogue_shots()
	await _contact_sheet("contact_scenes.png", _shots.filter(func(x): return x["group"] != "dialogue"))
	await _contact_sheet("contact_dialogue.png", _shots.filter(func(x): return x["group"] == "dialogue"))
	_write_report()
	print("TOUR RESULT: %d screenshots, %d problems" % [_shots.size(), _problems.size()])
	for p in _problems:
		print("  PROBLEM: " + p)
	# Free the scene and the thumbnails while the renderer is still up. (The
	# "1 RID allocations … leaked at exit" error that follows also appears on a
	# plain game boot with --quit-after: it's the game's, not the tour's.)
	_dm().force_reset()
	_thumbs.clear()
	if tree.current_scene:
		tree.current_scene.queue_free()
	for i in 3:
		await tree.process_frame
	return 0 if _problems.is_empty() else 1


func _wanted(id: String) -> bool:
	if _only.is_empty():
		return true
	# "ch2_" picks every Chapter 2 scene; "dlg_ch1" also switches the "dlg" group on.
	for o in _only:
		if id.begins_with(o) or o.begins_with(id):
			return true
	return false


func _gm() -> Node: return tree.root.get_node("GameManager")
func _dm() -> Node: return tree.root.get_node("DialogueManager")


## Real-time wait that keeps going while the tree is paused (menus pause it).
func _wait(seconds: float) -> void:
	var until := Time.get_ticks_msec() + int(seconds * 1000.0)
	while Time.get_ticks_msec() < until:
		await tree.process_frame


func _load_scene(path: String, settle: float) -> void:
	_dm().force_reset()
	tree.change_scene_to_file(path)
	for i in 3:
		await tree.process_frame
	var transitions := tree.root.get_node_or_null("SceneTransitions")
	var deadline := Time.get_ticks_msec() + 10000
	while transitions and transitions.get("is_transitioning") and Time.get_ticks_msec() < deadline:
		await tree.process_frame
	await _wait(settle)


func _scene_shot(id: String, path: String, settle: float) -> void:
	_gm().reset_game()
	await _load_scene(path, settle)
	var now: String = tree.current_scene.scene_file_path if tree.current_scene else "(none)"
	var notes: Array[String] = []
	if now != path:
		notes.append("scene moved on to %s" % now.get_file())
	await _capture(id, "scene", path, notes)


## Plays the real shatter scene with `flags` set and captures the first line of `dlg_node`
## (after_kill / after_spare / after_purge) while it waits for the player. Nothing is
## faked: if that line never shows (timeout, scene moved on) the shot is flagged as a
## PROBLEM and shows whatever was on screen.
func _shatter_route_shot(id: String, dlg_node: String, flags: Dictionary) -> void:
	var dm := _dm()
	var script = load("res://scripts/dialogue/dialogue_script.gd").load_file(SHATTER_DLG, false)
	var target := ""
	for step in script.nodes.get(dlg_node, []):
		if step["type"] == "line":
			target = step["text"]
			break
	_gm().reset_game()
	for f in flags:
		_gm().set_story_flag(f, flags[f])
	await _load_scene(SHATTER_SCENE, 0.0)
	dm.dialogue_history.clear()
	var notes: Array[String] = ["real scene run; first line of shatter.dlg `%s`" % dlg_node]
	var started := Time.get_ticks_msec()
	var reached := false
	while target != "" and (Time.get_ticks_msec() - started) < int(SHATTER_TIMEOUT * 1000.0):
		var scene_now: String = tree.current_scene.scene_file_path if tree.current_scene else ""
		if scene_now != SHATTER_SCENE:
			break
		if not dm.dialogue_history.is_empty() and dm.dialogue_history.back()["text"] == target:
			reached = true   # fully typed and now waiting for the advance key
			break
		if dm._is_visible:
			if dm._is_typing:
				dm._skip_typing = true
			else:
				dm._advance_requested = true
		await _wait(0.12)
	if reached:
		await _wait(0.4)   # nothing taps advance now, so the line stays up
		if not dm.dialogue_history.is_empty() and dm.dialogue_history.back()["text"] != target:
			reached = false
	if reached:
		_check_inside(id, "dialogue box", dm._panel, notes)
	else:
		var why := "the `%s` line never appeared" % dlg_node
		notes.append("PROBLEM: " + why)
		_problems.append("%s: %s" % [id, why])
	await _capture(id, "scene", SHATTER_SCENE, notes)


## Loads `path` after a reset, waits out its fade-in, triggers one flash (`trigger` "direct":
## SceneTransitions.flash with the archive floor-4 arguments; anything else: that dialogue event
## through the scene's own _on_dlg_event) and captures near the peak. A flash that never starts
## (overlay alpha still 0) or a scene that moved on is a PROBLEM on the shot. A baseline frame
## `<id>_before` is captured just before the trigger; the mean colour of the two frames must move
## toward the flash colour, so the evidence does not depend on judging a tint by eye.
func _flash_shot(id: String, path: String, trigger: String) -> void:
	_gm().reset_game()
	await _load_scene(path, FLASH_SETTLE)
	var notes: Array[String] = []
	var scene := tree.current_scene
	var transitions := tree.root.get_node_or_null("SceneTransitions")
	var overlay: ColorRect = transitions.get_node_or_null("FlashOverlay") if transitions else null
	var why := ""
	if scene == null or scene.scene_file_path != path:
		why = "the scene moved on to %s before the flash" % (scene.scene_file_path.get_file() if scene else "(none)")
	elif overlay == null:
		why = "SceneTransitions/FlashOverlay not found"
	if why == "":
		await _capture(id + "_before", "scene", path, ["baseline: same scene, no flash yet"] as Array[String])
	var flash_color := ARCHIVE_FLASH_COLOR
	if why != "":
		pass  # already a PROBLEM; nothing to trigger
	elif trigger == "direct":
		notes.append("SceneTransitions.flash(%s, %s) called by the stop (scene call is inside the Source Key coroutine; routing proven by screen_flash_test F1)" % [ARCHIVE_FLASH_COLOR, ARCHIVE_FLASH_SECONDS])
		transitions.flash(ARCHIVE_FLASH_COLOR, ARCHIVE_FLASH_SECONDS)
	elif scene.has_method("_on_dlg_event"):
		notes.append("real scene _on_dlg_event(\"%s\")" % trigger)
		scene._on_dlg_event(trigger)
		flash_color = overlay.color
	else:
		why = "the scene has no _on_dlg_event"
	if why == "" and overlay.modulate.a <= 0.0:
		why = "the flash overlay did not start (modulate.a %s)" % overlay.modulate.a
	if why == "":
		notes.append("overlay colour %s, modulate.a %.3f just before the capture" % [overlay.color, overlay.modulate.a])
	else:
		notes.append("PROBLEM: " + why)
		_problems.append("%s: %s" % [id, why])
	await _capture(id, "scene", path, notes)
	if why == "":
		_check_flash_shift(id, flash_color, notes)


## Compares the mean colour of `<id>_before.png` and `<id>.png`: the flash frame must have moved
## toward `flash_color` (positive projection of the shift on the direction to the flash colour,
## at least FLASH_MIN_SHIFT). The numbers go into the shot's notes; no shift is a PROBLEM.
func _check_flash_shift(id: String, flash_color: Color, notes: Array[String]) -> void:
	var before := Image.load_from_file(_out.path_join(id + "_before.png"))
	var after := Image.load_from_file(_out.path_join(id + ".png"))
	if before == null or after == null or before.is_empty() or after.is_empty():
		notes.append("PROBLEM: could not reload the before/after frames")
		_problems.append("%s: could not reload the before/after frames" % id)
		return
	var b := _mean_rgb(before)
	var a := _mean_rgb(after)
	var to_flash := Vector3(flash_color.r - b.x, flash_color.g - b.y, flash_color.b - b.z)
	var shift := a - b
	var along := shift.dot(to_flash.normalized()) if to_flash.length() > 0.0001 else 0.0
	var line := "mean RGB before %s -> flash frame %s; shift toward the flash colour %.3f (min %.3f)" % [
			_fmt3(b), _fmt3(a), along, FLASH_MIN_SHIFT]
	notes.append(line)
	print("  shot %-34s %s" % [id, line])
	if along < FLASH_MIN_SHIFT:
		notes.append("PROBLEM: the flash frame did not move toward the flash colour")
		_problems.append("%s: the flash frame did not move toward the flash colour (%.3f)" % [id, along])


## Mean colour of a 64x36 downscale, as a Vector3 (r, g, b).
func _mean_rgb(img: Image) -> Vector3:
	var small: Image = img.duplicate()
	small.convert(Image.FORMAT_RGBA8)
	small.resize(64, 36, Image.INTERPOLATE_BILINEAR)
	var sum := Vector3.ZERO
	for y in small.get_height():
		for x in small.get_width():
			var p := small.get_pixel(x, y)
			sum += Vector3(p.r, p.g, p.b)
	return sum / float(small.get_width() * small.get_height())


func _fmt3(v: Vector3) -> String:
	return "(%.3f, %.3f, %.3f)" % [v.x, v.y, v.z]


## Plays the real BREADCRUMB_SCENE with BREADCRUMB_FLAGS set and captures the HUD breadcrumb
## once the player is exploring with BREADCRUMB_OBJECTIVE shown. Like _shatter_route_shot,
## nothing is faked: on timeout (or if the scene moves on) the shot is flagged as a PROBLEM
## and shows whatever was on screen.
func _breadcrumb_shot(id: String) -> void:
	var dm := _dm()
	var gm := _gm()
	var bc := tree.root.get_node("ProgressionBreadcrumb")
	# Looked up at runtime: naming the GameManager autoload here would compile before it exists.
	var exploration: int = gm.get_script().get_script_constant_map()["GameState"]["EXPLORATION"]
	gm.reset_game()
	for f in BREADCRUMB_FLAGS:
		gm.set_story_flag(f, BREADCRUMB_FLAGS[f])
	await _load_scene(BREADCRUMB_SCENE, 0.0)
	var notes: Array[String] = ["real scene run; Chapter 1 step-6 breadcrumb"]
	var started := Time.get_ticks_msec()
	var reached := false
	var why := ""
	var choices_answered := 0
	while (Time.get_ticks_msec() - started) < int(BREADCRUMB_TIMEOUT * 1000.0):
		var scene_now: String = tree.current_scene.scene_file_path if tree.current_scene else ""
		if scene_now != BREADCRUMB_SCENE:
			why = "the scene moved on to %s before the breadcrumb showed" % scene_now.get_file()
			break
		bc.force_refresh()   # it refreshes itself only every 2 s
		if gm.current_state == exploration and not dm._is_visible \
				and bc.get_current_objective() == BREADCRUMB_OBJECTIVE \
				and _breadcrumb_panel_shown(bc):
			reached = true
			break
		if dm._awaiting_choice:
			# First option, the way chapter1_route_test's fake player answers.
			if dm._choice_result == -1 and dm._choice_container != null:
				dm._on_choice_pressed(0)
				choices_answered += 1
		elif dm._is_visible:
			if dm._is_typing:
				dm._skip_typing = true
			else:
				dm._advance_requested = true
		await _wait(0.12)
	notes.append("%d choice(s) answered with option 1" % choices_answered)
	if reached:
		await _wait(0.5)   # nothing taps advance now; let the arrow update and the pulse settle
		bc.force_refresh()
		if gm.current_state != exploration or bc.get_current_objective() != BREADCRUMB_OBJECTIVE \
				or not _breadcrumb_panel_shown(bc):
			reached = false
			why = "the breadcrumb left the screen during the 0.5 s settle"
	elif why == "":
		why = "no EXPLORATION + `%s` breadcrumb within %d s (state %d, objective `%s`)" % [
			BREADCRUMB_OBJECTIVE, int(BREADCRUMB_TIMEOUT), int(gm.current_state), bc.get_current_objective()]
	if reached:
		var arrow: String = bc.get_arrow_text()
		notes.append("objective `%s`" % bc.get_current_objective())
		notes.append("ch1_stew_done set by the real stew: %s; ch1_oakhaven_entered: %s" % [
			gm.get_story_flag("ch1_stew_done"), gm.get_story_flag("ch1_oakhaven_entered")])
		notes.append("arrow target cached: %s; arrow text %s" % [bc.has_arrow_target(),
			"`%s`" % arrow.strip_edges() if arrow.strip_edges() != "" else "EMPTY"])
		var panel = bc.get("_objective_panel")
		if panel is Control:
			_check_inside(id, "breadcrumb panel", panel, notes)
		else:
			notes.append("breadcrumb panel node not reachable; on-screen check skipped")
	else:
		notes.append("PROBLEM: " + why)
		_problems.append("%s: %s" % [id, why])
	await _capture(id, "scene", BREADCRUMB_SCENE, notes)


## True when the breadcrumb HUD layer and its panel are both visible with label text.
## (The panel node is private to ProgressionBreadcrumb; read through get() so a rename
## degrades to "not shown" rather than a script error.)
func _breadcrumb_panel_shown(bc: Node) -> bool:
	var layer = bc.get("_hud_layer")
	var panel = bc.get("_objective_panel")
	if not (layer is CanvasLayer and panel is Control):
		return bc.get_objective_label_text() != ""
	return layer.visible and panel.visible and bc.get_objective_label_text() != ""


func _ui_shots() -> void:
	_gm().reset_game()
	await _load_scene(BACKDROP, 2.5)
	var pause := tree.root.get_node("PauseScreen")
	pause.toggle_pause()
	await _wait(0.8)
	await _capture("ui_pause", "ui", BACKDROP, [])
	pause.toggle_pause()
	await _wait(0.5)
	# Loaded at runtime: naming the class here would compile before autoloads exist.
	var menu: Node = load("res://scripts/ui/controls_menu.gd").open(tree.root)
	await _wait(0.6)
	await _capture("ui_controls", "ui", BACKDROP, [])
	if is_instance_valid(menu):
		menu.queue_free()
	await _wait(0.3)


## Completes Forge Line Supply through the real SideQuestManager API, opens the real
## ShopSystem apothecary over BACKDROP and captures it once the health_potion row is checked:
## its button must read "BUY <SHOP_SHOWN_PRICE>G" and get_buy_price must agree. Any mismatch
## is a PROBLEM on the shot. The shop is closed with its own close_shop afterwards.
func _shop_discount_shot(id: String) -> void:
	var gm := _gm()
	var sqm := tree.root.get_node("SideQuestManager")
	var shop := tree.root.get_node("ShopSystem")
	var inv := tree.root.get_node("Inventory")
	gm.reset_game()
	await _load_scene(BACKDROP, 2.0)
	sqm.complete_optional_objective(SHOP_QUEST)
	# Inventory.gold and GameManager.player_stats["gold"] are separate fields.
	gm.player_stats["gold"] = SHOP_GOLD
	inv.gold = SHOP_GOLD
	var notes: Array[String] = []
	var discount: float = gm.shop_discount
	var completed: int = sqm.get_script().get_script_constant_map()["QuestState"]["COMPLETED"]
	var quest_state: int = int(sqm.quests.get(SHOP_QUEST, {}).get("state", -1))
	notes.append("discount %.2f from Forge Line Supply (quest state %s)" % [discount,
		"COMPLETED" if quest_state == completed else str(quest_state)])
	if quest_state != completed:
		_shop_problem(id, notes, "Forge Line Supply did not complete (state %d)" % quest_state)
	if not is_equal_approx(discount, SHOP_DISCOUNT):
		_shop_problem(id, notes, "shop_discount is %.2f, expected %.2f" % [discount, SHOP_DISCOUNT])
	shop.open_shop(SHOP_KIND)
	await _wait(0.6)   # rows built on open; 0.25 s pop-in tween
	if not shop._is_open:
		_shop_problem(id, notes, "the %s shop did not open" % SHOP_KIND)
	else:
		var raw: int = int(shop.SHOP_ITEMS[SHOP_ITEM]["buy_price"])
		var priced: int = shop.get_buy_price(SHOP_ITEM)
		var btn := _shop_buy_button(shop, SHOP_ITEM)
		var shown: String = btn.text if btn != null else "(no row)"
		notes.append("%s raw %dG, get_buy_price %dG, button `%s`" % [SHOP_ITEM, raw, priced, shown])
		if raw != SHOP_RAW_PRICE:
			_shop_problem(id, notes, "raw %s price is %d, expected %d" % [SHOP_ITEM, raw, SHOP_RAW_PRICE])
		if priced != SHOP_SHOWN_PRICE:
			_shop_problem(id, notes, "get_buy_price(%s) is %d, expected %d" % [SHOP_ITEM, priced, SHOP_SHOWN_PRICE])
		if btn == null:
			_shop_problem(id, notes, "no %s row in the %s shop" % [SHOP_ITEM, SHOP_KIND])
		else:
			if btn.text != "BUY %dG" % SHOP_SHOWN_PRICE:
				_shop_problem(id, notes, "%s button reads `%s`, expected `BUY %dG`" % [SHOP_ITEM, btn.text, SHOP_SHOWN_PRICE])
			if btn.disabled:
				_shop_problem(id, notes, "%s button is disabled with %d gold" % [SHOP_ITEM, SHOP_GOLD])
		if shop._panel is Control:
			_check_inside(id, "shop panel", shop._panel, notes)
	await _capture(id, "ui", BACKDROP, notes)
	shop.close_shop()
	await _wait(0.5)   # close fade; the shop also releases the pause it took


func _shop_problem(id: String, notes: Array[String], why: String) -> void:
	notes.append("PROBLEM: " + why)
	_problems.append("%s: %s" % [id, why])


## The live buy button of `item` in the open shop: the row whose first Label is the item's
## shop name (same lookup as tests/integration/quests/act1_quests_completable_test.gd).
func _shop_buy_button(shop: Node, item: String) -> Button:
	var want: String = shop.SHOP_ITEMS[item]["name"]
	for row in shop._item_container.get_children():
		if row.is_queued_for_deletion() or not row is PanelContainer:
			continue
		var labels: Array = row.find_children("*", "Label", true, false)
		if labels.is_empty() or labels[0].text != want:
			continue
		var buttons: Array = row.find_children("*", "Button", true, false)
		if not buttons.is_empty():
			return buttons[0]
	return null


# ── Dialogue stress ─────────────────────────────────────────────────────────

func _dialogue_shots() -> void:
	_gm().reset_game()
	await _load_scene(BACKDROP, 2.0)
	var parser = load("res://scripts/dialogue/dialogue_script.gd")
	var input_service := tree.root.get_node("InputService")
	for dir in DLG_DIRS:
		for file in DirAccess.get_files_at(dir):
			if not file.ends_with(".dlg"):
				continue
			var path: String = dir.path_join(file)
			var stem := "dlg_%s_%s" % [dir.get_file(), file.get_basename()]
			if not _wanted(stem):
				continue
			var script = parser.load_file(path, false)
			var longest_line: Dictionary = {}
			var longest_choice: Dictionary = {}
			for node_name in script.nodes:
				for step in script.nodes[node_name]:
					if step["type"] == "line":
						var t: String = input_service.fmt(step["text"])
						if longest_line.is_empty() or t.length() > longest_line["text"].length():
							longest_line = {"speaker": step["speaker"], "text": t, "at": step["line"]}
					elif step["type"] == "choice":
						var opts: Array = step["options"].map(func(o): return o["text"])
						var total := 0
						for o in opts:
							total += String(o).length()
						if longest_choice.is_empty() or total > longest_choice["total"]:
							var prompt = step["prompt"]
							longest_choice = {"opts": opts, "total": total, "at": step["line"],
								"prompt": prompt["text"] if prompt != null else "",
								"speaker": prompt["speaker"] if prompt != null else "Kaelen"}
			if not longest_line.is_empty():
				await _line_shot(stem + "_line", path, longest_line)
			if not longest_choice.is_empty():
				await _choice_shot(stem + "_choice", path, longest_choice)


func _line_shot(id: String, path: String, line: Dictionary) -> void:
	var dm := _dm()
	dm.force_reset()
	await tree.process_frame
	dm.say(line["speaker"], line["text"])   # not awaited: it waits for a key press
	dm._skip_typing = true
	await _wait(0.6)                         # panel slide-in
	var notes: Array[String] = ["%s:%d, %d chars" % [path.get_file(), line["at"], line["text"].length()]]
	_check_inside(id, "dialogue box", dm._panel, notes)
	await _capture(id, "dialogue", path, notes)
	dm.force_reset()


func _choice_shot(id: String, path: String, choice: Dictionary) -> void:
	var dm := _dm()
	dm.force_reset()
	await tree.process_frame
	dm.show_choices(choice["prompt"], choice["opts"], choice["speaker"])   # not awaited
	dm._skip_typing = true
	await _wait(0.9)                         # prompt, then the 0.3 s fade-in
	var notes: Array[String] = ["%s:%d, %d options" % [path.get_file(), choice["at"], choice["opts"].size()]]
	var box: Control = dm._choice_container
	if box == null or not is_instance_valid(box):
		notes.append("PROBLEM: no choice buttons appeared")
		_problems.append("%s: no choice buttons appeared" % id)
	else:
		_check_inside(id, "choice list", box, notes)
		var a: Rect2 = box.get_global_rect()
		var b: Rect2 = dm._panel.get_global_rect()
		var overlap := a.intersection(b)
		if overlap.size.y > 2.0:
			notes.append("PROBLEM: choices cover %d px of the dialogue box" % int(overlap.size.y))
			_problems.append("%s: choices cover %d px of the dialogue box" % [id, int(overlap.size.y)])
		var screen_w: float = tree.root.get_visible_rect().size.x
		for btn in box.get_children():
			if btn is Button and btn.get_combined_minimum_size().x > screen_w - 40.0:
				notes.append("PROBLEM: option wider than the screen: %s" % btn.text.strip_edges().left(40))
				_problems.append("%s: an option is wider than the screen" % id)
	await _capture(id, "dialogue", path, notes)
	dm.force_reset()


func _check_inside(id: String, what: String, c: Control, notes: Array[String]) -> void:
	var screen: Rect2 = tree.root.get_visible_rect()
	var r: Rect2 = c.get_global_rect()
	var grown := screen.grow(1.0)
	if not grown.encloses(r):
		var msg := "%s goes off screen (%d,%d %dx%d on a %dx%d screen)" % [what,
			int(r.position.x), int(r.position.y), int(r.size.x), int(r.size.y), int(screen.size.x), int(screen.size.y)]
		notes.append("PROBLEM: " + msg)
		_problems.append("%s: %s" % [id, msg])


# ── Capture, contact sheets, report ─────────────────────────────────────────

func _capture(id: String, group: String, scene: String, notes: Array[String]) -> void:
	await RenderingServer.frame_post_draw
	var img: Image = tree.root.get_texture().get_image()
	var file := id + ".png"
	if img == null or img.is_empty():
		_problems.append("%s: the renderer returned no image" % id)
		_shots.append({"id": id, "file": "", "group": group, "scene": scene, "notes": notes})
		return
	img.save_png(_out.path_join(file))
	if _is_flat(img):
		notes.append("PROBLEM: the frame is one flat colour (black screen?)")
		_problems.append("%s: the frame is one flat colour" % id)
	var thumb: Image = img.duplicate()
	thumb.resize(THUMB.x, THUMB.y, Image.INTERPOLATE_BILINEAR)
	_thumbs[id] = thumb
	_shots.append({"id": id, "file": file, "group": group, "scene": scene, "notes": notes})
	print("  shot %-34s %s" % [id, "; ".join(notes)])


## True if every pixel of a 32×18 downscale is within a hair of the first one.
func _is_flat(img: Image) -> bool:
	var small: Image = img.duplicate()
	small.resize(32, 18, Image.INTERPOLATE_BILINEAR)
	var first := small.get_pixel(0, 0)
	for y in small.get_height():
		for x in small.get_width():
			var p := small.get_pixel(x, y)
			if absf(p.r - first.r) + absf(p.g - first.g) + absf(p.b - first.b) > 0.03:
				return false
	return true


func _contact_sheet(file: String, shots: Array) -> void:
	shots = shots.filter(func(s): return _thumbs.has(s["id"]))
	if shots.is_empty():
		return
	var cols := 4
	var label_h := 22
	var rows := int(ceil(shots.size() / float(cols)))
	var vp := SubViewport.new()
	vp.size = Vector2i(cols * THUMB.x, rows * (THUMB.y + label_h))
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	vp.transparent_bg = false
	var bg := ColorRect.new()
	bg.color = Color(0.08, 0.08, 0.1)
	bg.size = Vector2(vp.size)
	vp.add_child(bg)
	for i in shots.size():
		var cell := Vector2((i % cols) * THUMB.x, (i / cols) * (THUMB.y + label_h))
		var tex := TextureRect.new()
		tex.texture = ImageTexture.create_from_image(_thumbs[shots[i]["id"]])
		tex.position = cell
		vp.add_child(tex)
		var lbl := Label.new()
		var flagged: bool = shots[i]["notes"].any(func(n): return String(n).begins_with("PROBLEM"))
		lbl.text = ("⚠ " if flagged else "") + shots[i]["id"]
		lbl.position = cell + Vector2(6, THUMB.y + 2)
		lbl.add_theme_font_size_override("font_size", 13)
		lbl.add_theme_color_override("font_color", Color(1.0, 0.55, 0.4) if flagged else Color(0.85, 0.85, 0.9))
		vp.add_child(lbl)
	tree.root.add_child(vp)
	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw
	vp.get_texture().get_image().save_png(_out.path_join(file))
	vp.queue_free()
	await tree.process_frame


func _write_report() -> void:
	var md := PackedStringArray()
	md.append("# Screenshot tour — %s" % Time.get_datetime_string_from_system(false, true))
	md.append("")
	md.append("Godot %s, renderer `%s`, %s. Window %s." % [Engine.get_version_info()["string"],
		RenderingServer.get_current_rendering_method(), RenderingServer.get_video_adapter_name(),
		str(tree.root.get_visible_rect().size)])
	md.append("")
	md.append("Game state is reset before each scene, so scenes show their default (fresh-save) state.")
	md.append("")
	if _problems.is_empty():
		md.append("**No layout problems found.**")
	else:
		md.append("## Problems (%d)" % _problems.size())
		md.append("")
		for p in _problems:
			md.append("- " + p)
	md.append("")
	md.append("Contact sheets: `contact_scenes.png`, `contact_dialogue.png`.")
	md.append("")
	md.append("| Shot | Scene / source | Notes |")
	md.append("|---|---|---|")
	for s in _shots:
		md.append("| `%s` | %s | %s |" % [s["file"] if s["file"] != "" else s["id"],
			String(s["scene"]).get_file(), "; ".join(s["notes"]).replace("|", "\\|")])
	var f := FileAccess.open(_out.path_join("report.md"), FileAccess.WRITE)
	if f:
		f.store_string("\n".join(md) + "\n")
		f.close()
