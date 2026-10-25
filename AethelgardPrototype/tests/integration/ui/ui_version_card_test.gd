extends SceneTree
## Tests for story Y1-P0-T12 (production/epics/y1-p0-stabilize/story-t12-ui-region-leftovers.md), AC-1 and AC-2:
## one version string, and a Chapter 2 stats card that fits the 1280x720 viewport. Expected values come from the
## project setting, the export presets and a golden captured BEFORE the card refactor, never from the code under test.
##
##   AC-1  application/config/version is set and matches ^\d+\.\d+\.\d+$; both export presets' file_version and
##         product_version equal "<setting>.0"; the real main menu's VersionLabel reads "v<setting>"; a fresh pause
##         screen's header reads "AETHELGARD IDE v<setting> — PAUSED" when built and "... — Chapter N" after
##         _refresh_header() for current_chapter 1, 3 and 0 (0 falls back to Chapter 1); the stale literals are gone
##         ("v1.0" from main_menu.tscn, "IDE v0.1." from pause_screen.gd); the splash's in-fiction "KERNEL v0.91" stays.
##         Every expected string is built here from ProjectSettings, not by GameVersion.
##   AC-2  under the worst-case fixture (WORST_* below: arena line on with 3-digit wins / losses / streak, playtime
##         99h 59m 59s, gold 999999, corruption 100, the longest string of every status branch), the card built by the
##         real ch2_chapter_end.gd: its labels joined in reading order (header, left, right, footer), rule (═) and
##         blank lines aside, equal GOLDEN line for line; _build_chapter_stats_text() equals GOLDEN exactly; the panel
##         lies inside the viewport with >= 24 px on every side; every label shows all its lines and lies inside its
##         parent, the two columns do not overlap; font size >= 16.
##
## GOLDEN: captured on 2026-10-25 from the pre-refactor _build_chapter_stats_text() (HEAD e77727a) under exactly
## this fixture, headless, keyboard prompts (so {ui_accept} printed "Enter"). Not regenerated: it is the frozen
## "same wording" baseline.
##
## ISOLATION COSTS (named, accepted):
##   - The card is reached by instancing the real ch2_ending.tscn with its script detached, adding it to the tree,
##     then attaching the script and calling the PRIVATE _show_chapter_end_card() without awaiting it (so _ready's
##     dialogue sequence never runs). The scene is freed during the card's 2 s fade-in, so the log may show
##     "Resumed function ... after await, but class instance is gone" (not a SCRIPT ERROR).
##   - The fixture writes GameManager fields and story_flags directly (set_story_flag would clear the mutually
##     exclusive Seraphina flags the worst case combines); GameManager.reset_game() restores the state afterwards.
##   - A fresh pause_screen.gd instance is built for the header checks (the PauseScreen autoload is not touched).
##   - Each Godot boot logs 6 "Can't use get_node() with absolute paths" ERROR lines before any test code (pre-existing).
## Run: tests/run_phase0_tests.ps1 -Script res://tests/integration/ui/ui_version_card_test.gd

const MENU_SCENE := "res://scenes/main_menu.tscn"
const PAUSE_SCRIPT := "res://scripts/ui/pause_screen.gd"
const SPLASH_SCRIPT := "res://scripts/ui/splash_screen.gd"
const ENDING_SCENE := "res://scenes/chapter2/ch2_ending.tscn"
const ENDING_SCRIPT := "res://scripts/chapter2/ch2_chapter_end.gd"
const PRESETS_FILE := "res://export_presets.cfg"
const VIEWPORT := Vector2(1280, 720)
const MIN_EDGE := 24.0
const MIN_FONT := 16
const TOLERANCE := 0.5
const FADE_OUT_Z := 100   # ch2_chapter_end.gd sets fade_rect.z_index = 100 before the fade to black


## A CanvasItem's z as drawn: its own z_index plus its parents' while z_as_relative is on.
func _effective_z(node: CanvasItem) -> int:
	var z := 0
	var n: Node = node
	while n is CanvasItem:
		z += (n as CanvasItem).z_index
		if not (n as CanvasItem).z_as_relative:
			break
		n = n.get_parent()
	return z

## Worst-case fixture (story AC-2).
const WORST_CORRUPTION := 100.0
const WORST_LEVEL := 99
const WORST_GOLD := 999999
const WORST_PLAYTIME := 359999.0    # 99h 59m 59s
const WORST_ARENA := 999            # wins, losses and best streak
const WORST_RELATIONSHIP := 100
const WORST_KEYS := 7
## The longest branch of each status: Elara "REJECTED (Solo Path)", Oakhaven "LEFT IN SILENCE", Seraphina display
## "REJECTED", Seraphina choice "RECRUITED" (checked before rejected), approach "Told the Truth", wraith "DESTROYED",
## report "the Wastes archivists"; the knight has no flag ("DEFEATED", its longest).
const WORST_FLAGS: Array[String] = [
	"ch1_elara_distrusted", "ch1_oakhaven_left_quietly", "ch2_seraphina_rejected", "ch2_seraphina_recruited",
	"ch2_seraphina_truth", "ch2_data_wraith_destroyed", "act1_report_archive",
]

const GOLDEN: Array[String] = [
	"═══════════════════════════════════",
	"CHAPTER 2 COMPLETE",
	"═══════════════════════════════════",
	"",
	"ACT 1: ARRIVAL AND BELONGING",
	"IRONHOLD CROWN",
	"",
	"Source Key Fragments: 7/7",
	"Corruption Level: 100%",
	"Player Level: 99",
	"Playtime: 99h 59m 59s",
	"Gold: 999999",
	"Arena: 999W / 999L (Best Streak: 999)",
	"",
	"Relationships:",
	"  Elara: +100 [REJECTED (Solo Path)]",
	"  Seraphina: REJECTED",
	"",
	"Chapter 1 Choices:",
	"  - Knight Aldric: [DEFEATED]",
	"  - Oakhaven: [LEFT IN SILENCE]",
	"",
	"Chapter 2 Choices:",
	"  - Seraphina Encounter: [Told the Truth]",
	"  - Data Wraith: [DESTROYED]",
	"  - Seraphina: [RECRUITED]",
	"",
	"Act 1 report sent to: the Wastes archivists",
	"",
	"═══════════════════════════════════",
	"ACT 2: MEMORY AND LEGITIMACY",
	"THE JOURNEY CONTINUES...",
	"═══════════════════════════════════",
	"",
	"Thank you for playing the Aethelgard Prototype!",
	"Press Enter to continue.",
]

var _passes := 0
var _failures: Array[String] = []
var _version := ""


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	await process_frame
	await process_frame
	if not OS.get_user_data_dir().contains("aeth_phase0_test"):
		push_error("Refusing to run: user data dir is not isolated. Use tests/run_phase0_tests.ps1.")
		quit(2)
		return
	_check(OS.get_user_data_dir().contains("aeth_phase0_test"), "isolation: user:// is the aeth_phase0_test directory (%s)" % OS.get_user_data_dir())
	_check(get_root().get_node_or_null("GameManager") != null, "isolation: GameManager autoload present")
	_version = str(ProjectSettings.get_setting("application/config/version", ""))
	test_version_setting_is_semver()
	test_export_presets_match_setting()
	await test_main_menu_label_shows_setting()
	await test_pause_header_shows_setting()
	test_stale_version_literals_removed()
	await test_stats_card_fits_viewport_with_golden_text()
	print("")
	print("UI VERSION CARD RESULT: %d passed, %d failed" % [_passes, _failures.size()])
	for f in _failures:
		print("  FAIL: " + f)
	quit(0 if _failures.is_empty() else 1)


func _check(cond: bool, name: String) -> void:
	if cond:
		_passes += 1
		print("  PASS: " + name)
	else:
		_failures.append(name)
		print("  FAIL: " + name)


func _read(path: String) -> String:
	var f := FileAccess.open(path, FileAccess.READ)
	return f.get_as_text() if f else ""


# ── AC-1 ─────────────────────────────────────────────────────────────────────

func test_version_setting_is_semver() -> void:
	var re := RegEx.create_from_string("^\\d+\\.\\d+\\.\\d+$")
	_check(_version != "" and re.search(_version) != null, "AC-1 application/config/version is set and matches ^\\d+\\.\\d+\\.\\d+$ ('%s')" % _version)


func test_export_presets_match_setting() -> void:
	var cfg := ConfigFile.new()
	_check(cfg.load(PRESETS_FILE) == OK, "AC-1 export_presets.cfg loads")
	var found := 0
	for section in cfg.get_sections():
		if not section.ends_with(".options") or not cfg.has_section_key(section, "application/file_version"):
			continue
		found += 1
		for key in ["application/file_version", "application/product_version"]:
			var value := str(cfg.get_value(section, key, ""))
			_check(value == _version + ".0", "AC-1 [%s] %s == '%s.0' (got '%s')" % [section, key, _version, value])
	_check(found == 2, "AC-1 both Windows presets carry file/product versions (found %d)" % found)


func test_main_menu_label_shows_setting() -> void:
	var menu: Node = (load(MENU_SCENE) as PackedScene).instantiate()
	get_root().add_child(menu)
	await process_frame
	await process_frame
	var label := menu.get_node_or_null("VersionLabel") as Label
	var text := label.text if label else "<no VersionLabel>"
	_check(_version != "" and text == "v" + _version, "AC-1 main menu VersionLabel == 'v%s' (got '%s')" % [_version, text])
	menu.queue_free()
	await process_frame


func test_pause_header_shows_setting() -> void:
	var gm: Node = get_root().get_node("GameManager")
	var saved_chapter: int = gm.current_chapter
	var pause: Node = load(PAUSE_SCRIPT).new()
	get_root().add_child(pause)
	await process_frame
	var header: Label = pause.header_label
	var built := header.text if header else "<no header>"
	_check(built == "AETHELGARD IDE v%s — PAUSED" % _version, "AC-1 pause header when built == 'AETHELGARD IDE v%s — PAUSED' (got '%s')" % [_version, built])
	for c in [[1, 1], [3, 3], [0, 1]]:
		gm.current_chapter = c[0]
		pause._refresh_header()
		var want := "AETHELGARD IDE v%s — Chapter %d" % [_version, c[1]]
		var got := header.text if header else "<no header>"
		_check(got == want, "AC-1 pause header for current_chapter %d == '%s' (got '%s')" % [c[0], want, got])
	gm.current_chapter = saved_chapter
	pause.queue_free()
	await process_frame


func test_stale_version_literals_removed() -> void:
	var menu_tscn := _read(MENU_SCENE)
	var pause_gd := _read(PAUSE_SCRIPT)
	_check(menu_tscn != "" and not menu_tscn.contains("v1.0"), "AC-1 no 'v1.0' left in main_menu.tscn")
	_check(pause_gd != "" and not pause_gd.contains("IDE v0.1."), "AC-1 no 'IDE v0.1.' literal left in pause_screen.gd (covers v0.1.%d and v0.1.1)")
	_check(_read(SPLASH_SCRIPT).contains("KERNEL v0.91"), "AC-1 in-fiction splash text 'KERNEL v0.91' unchanged")


# ── AC-2 ─────────────────────────────────────────────────────────────────────

func _apply_worst_case(gm: Node) -> void:
	gm.reset_game()
	gm.glitch_meter = WORST_CORRUPTION
	gm.player_stats["level"] = WORST_LEVEL
	gm.player_stats["gold"] = WORST_GOLD
	gm.relationships["elara"] = WORST_RELATIONSHIP
	gm.relationships["seraphina"] = WORST_RELATIONSHIP
	gm.source_key_count = WORST_KEYS
	gm.playtime_seconds = WORST_PLAYTIME
	for key in ["total_wins", "total_losses", "best_streak"]:
		gm.arena_stats[key] = WORST_ARENA
	for f in WORST_FLAGS:
		gm.story_flags[f] = true


## Rule (═) and blank lines are layout, not content: the panel may draw them differently.
func _content_lines(lines: Array) -> Array[String]:
	var out: Array[String] = []
	for l in lines:
		var s := str(l).strip_edges()
		if s != "" and not s.begins_with("═"):
			out.append(str(l))
	return out


func test_stats_card_fits_viewport_with_golden_text() -> void:
	var gm: Node = get_root().get_node("GameManager")
	_apply_worst_case(gm)
	var screen := get_root().get_visible_rect()
	_check(screen.size == VIEWPORT, "AC-2 viewport is %s (got %s)" % [VIEWPORT, screen.size])

	# Arrange: the real ending scene, script detached while it enters the tree so _ready's sequence never starts.
	var scene: Control = (load(ENDING_SCENE) as PackedScene).instantiate()
	scene.set_script(null)
	get_root().add_child(scene)
	await process_frame
	scene.set_script(load(ENDING_SCRIPT))
	_check(scene.get("background") == null, "AC-2 harness: _ready did not run (no dialogue sequence)")
	var whole: String = scene._build_chapter_stats_text()
	_check(whole == "\n".join(GOLDEN), "AC-2 _build_chapter_stats_text() equals the pre-refactor golden exactly")

	# Act: build the card (not awaited: the coroutine goes on with the fade-in and the 12 s wait).
	scene._show_chapter_end_card()
	await process_frame
	await process_frame

	var panel := scene.find_child("CardPanel", true, false) as Control
	var names := ["HeaderLabel", "LeftColumn", "RightColumn", "FooterLabel"]
	var labels: Array[Label] = []
	for n in names:
		var found := scene.find_child(n, true, false) as Label
		_check(found != null, "AC-2 card has the %s label" % n)
		if found:
			labels.append(found)
	_check(panel != null, "AC-2 card has a centred panel (CardPanel)")
	if panel == null or labels.size() != names.size():
		scene.queue_free()
		gm.reset_game()
		await process_frame
		return

	# Assert: same wording, in reading order.
	var shown: Array = []
	for l in labels:
		shown.append_array(l.text.split("\n"))
	var got := _content_lines(shown)
	var want := _content_lines(GOLDEN)
	var first_diff := -1
	for i in maxi(got.size(), want.size()):
		if i >= got.size() or i >= want.size() or got[i] != want[i]:
			first_diff = i
			break
	_check(first_diff == -1, "AC-2 card labels (header, left, right, footer) equal the golden line for line, rules and blanks aside (%d vs %d lines; first difference at %d: '%s' vs '%s')" % [
		got.size(), want.size(), first_diff,
		got[first_diff] if first_diff >= 0 and first_diff < got.size() else "",
		want[first_diff] if first_diff >= 0 and first_diff < want.size() else ""])

	# Assert: the panel fits with the margin on every side, centred.
	var r := panel.get_global_rect()
	var inner := Rect2(screen.position + Vector2.ONE * MIN_EDGE, screen.size - Vector2.ONE * (2.0 * MIN_EDGE))
	_check(inner.encloses(r), "AC-2 panel %s lies inside the viewport with >= %d px on every side (left %.0f, top %.0f, right %.0f, bottom %.0f)" % [
		r, int(MIN_EDGE), r.position.x, r.position.y, screen.size.x - r.end.x, screen.size.y - r.end.y])
	_check(absf(r.get_center().x - screen.get_center().x) <= 1.0 and absf(r.get_center().y - screen.get_center().y) <= 1.0, "AC-2 panel is centred (centre %s)" % r.get_center())

	# Assert: every label shows all its lines, sits inside its parent and the panel, and uses a readable font.
	for l in labels:
		_check(l.get_line_count() == l.get_visible_line_count(), "AC-2 %s shows all its lines (%d of %d)" % [l.name, l.get_visible_line_count(), l.get_line_count()])
		var lr := l.get_global_rect()
		var parent_rect := (l.get_parent() as Control).get_global_rect().grow(TOLERANCE)
		_check(parent_rect.encloses(lr) and r.grow(TOLERANCE).encloses(lr), "AC-2 %s rect %s lies inside its column and the panel" % [l.name, lr])
		_check(l.size.x + TOLERANCE >= l.get_minimum_size().x, "AC-2 %s is as wide as its longest line (%.0f >= %.0f)" % [l.name, l.size.x, l.get_minimum_size().x])
		var fs := l.get_theme_font_size("font_size")
		_check(fs >= MIN_FONT, "AC-2 %s font size %d >= %d" % [l.name, fs, MIN_FONT])
	_check(labels[1].get_global_rect().end.x <= labels[2].get_global_rect().position.x, "AC-2 left and right columns do not overlap")
	# The fade-out (fade_rect.z_index = FADE_OUT_Z, ch2_chapter_end.gd) must cover the whole card (code review R4).
	var deepest := 0
	for n in [panel] + labels:
		deepest = maxi(deepest, _effective_z(n))
	_check(deepest < FADE_OUT_Z, "AC-2 every card node draws below the fade-out (highest effective z %d < %d)" % [deepest, FADE_OUT_Z])
	print("  INFO: card font size %d, panel %s" % [labels[0].get_theme_font_size("font_size"), r])

	scene.queue_free()
	gm.reset_game()
	await process_frame
