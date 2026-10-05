extends SceneTree
## Visual tour: loads the Act 1 scenes with a REAL renderer and saves what the
## player would see, plus layout checks the headless tests can't do.
##
##   1. Scenes: each Act 1 scene, a few seconds after it loads.
##   2. UI: the pause screen and the Controls screen, over Oakhaven.
##   3. Dialogue stress: for every authored .dlg (prologue, ch1, ch2), the
##      longest line and the longest choice, shown in the real dialogue box.
##      Checked automatically: the box stays on screen, the choices stay on
##      screen and don't cover the box, and no option is wider than the screen.
##   4. Contact sheets (thumbnails of everything) and report.md.
##
## Run: tests/run_screenshots.ps1 [-Only main_menu,ch1_crash_site]
## A game window opens for about two minutes. Audio is muted.
## Exit code: 0 = no problems found, 1 = problems (listed in report.md), 2 = refused.

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
const DLG_DIRS := ["res://dialogue/prologue", "res://dialogue/ch1", "res://dialogue/ch2"]
const BACKDROP := "res://scenes/regions/oakhaven_region.tscn"
const THUMB := Vector2i(320, 180)

var _out := ""
var _only: PackedStringArray = []
var _shots: Array[Dictionary] = []      # {id, file, group, scene, now, notes}
var _thumbs: Dictionary = {}            # id -> Image (thumbnail)
var _problems: Array[String] = []


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	await process_frame
	if DisplayServer.get_name() == "headless":
		push_error("The screenshot tour needs a renderer. Run it without --headless (tests/run_screenshots.ps1).")
		quit(2)
		return
	if not OS.get_user_data_dir().contains("aeth_phase0_test"):
		push_error("Refusing to run: user data dir is not isolated. Use tests/run_screenshots.ps1.")
		quit(2)
		return
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
	if _wanted("ui"):
		await _ui_shots()
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
	if current_scene:
		current_scene.queue_free()
	for i in 3:
		await process_frame
	quit(0 if _problems.is_empty() else 1)


func _wanted(id: String) -> bool:
	if _only.is_empty():
		return true
	# "ch2_" picks every Chapter 2 scene; "dlg_ch1" also switches the "dlg" group on.
	for o in _only:
		if id.begins_with(o) or o.begins_with(id):
			return true
	return false


func _gm() -> Node: return get_root().get_node("GameManager")
func _dm() -> Node: return get_root().get_node("DialogueManager")


## Real-time wait that keeps going while the tree is paused (menus pause it).
func _wait(seconds: float) -> void:
	var until := Time.get_ticks_msec() + int(seconds * 1000.0)
	while Time.get_ticks_msec() < until:
		await process_frame


func _load_scene(path: String, settle: float) -> void:
	_dm().force_reset()
	change_scene_to_file(path)
	for i in 3:
		await process_frame
	var transitions := get_root().get_node_or_null("SceneTransitions")
	var deadline := Time.get_ticks_msec() + 10000
	while transitions and transitions.get("is_transitioning") and Time.get_ticks_msec() < deadline:
		await process_frame
	await _wait(settle)


func _scene_shot(id: String, path: String, settle: float) -> void:
	_gm().reset_game()
	await _load_scene(path, settle)
	var now: String = current_scene.scene_file_path if current_scene else "(none)"
	var notes: Array[String] = []
	if now != path:
		notes.append("scene moved on to %s" % now.get_file())
	await _capture(id, "scene", path, notes)


func _ui_shots() -> void:
	_gm().reset_game()
	await _load_scene(BACKDROP, 2.5)
	var pause := get_root().get_node("PauseScreen")
	pause.toggle_pause()
	await _wait(0.8)
	await _capture("ui_pause", "ui", BACKDROP, [])
	pause.toggle_pause()
	await _wait(0.5)
	# Loaded at runtime: naming the class here would compile before autoloads exist.
	var menu: Node = load("res://scripts/ui/controls_menu.gd").open(get_root())
	await _wait(0.6)
	await _capture("ui_controls", "ui", BACKDROP, [])
	if is_instance_valid(menu):
		menu.queue_free()
	await _wait(0.3)


# ── Dialogue stress ─────────────────────────────────────────────────────────

func _dialogue_shots() -> void:
	_gm().reset_game()
	await _load_scene(BACKDROP, 2.0)
	var parser = load("res://scripts/dialogue/dialogue_script.gd")
	var input_service := get_root().get_node("InputService")
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
	await process_frame
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
	await process_frame
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
		var screen_w: float = get_root().get_visible_rect().size.x
		for btn in box.get_children():
			if btn is Button and btn.get_combined_minimum_size().x > screen_w - 40.0:
				notes.append("PROBLEM: option wider than the screen: %s" % btn.text.strip_edges().left(40))
				_problems.append("%s: an option is wider than the screen" % id)
	await _capture(id, "dialogue", path, notes)
	dm.force_reset()


func _check_inside(id: String, what: String, c: Control, notes: Array[String]) -> void:
	var screen: Rect2 = get_root().get_visible_rect()
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
	var img: Image = get_root().get_texture().get_image()
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
	get_root().add_child(vp)
	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw
	vp.get_texture().get_image().save_png(_out.path_join(file))
	vp.queue_free()
	await process_frame


func _write_report() -> void:
	var md := PackedStringArray()
	md.append("# Screenshot tour — %s" % Time.get_datetime_string_from_system(false, true))
	md.append("")
	md.append("Godot %s, renderer `%s`, %s. Window %s." % [Engine.get_version_info()["string"],
		RenderingServer.get_current_rendering_method(), RenderingServer.get_video_adapter_name(),
		str(get_root().get_visible_rect().size)])
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
