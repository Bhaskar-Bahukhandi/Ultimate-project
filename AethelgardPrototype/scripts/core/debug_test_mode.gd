extends Node
## Debug test mode: lets an exported DEBUG build run the screenshot tour, since
## exported builds ignore --script. Start the game with
##     Aethelgard.console.exe -- --debug-tour [--out=DIR] [--only=ch1_,ui]
## (tools/export_windows.ps1 -Tour does this with an isolated user:// directory).
##
## It does nothing unless ALL of these hold:
##   - this is a debug build (OS.is_debug_build(): editor runs and debug exports);
##   - "--debug-tour" was passed after "--" on the command line;
##   - the runner script is in the build. Release presets exclude scripts/debug/,
##     so a release build can't run it even when given the flag
##     (tools/export_windows.ps1 checks this on every release build).

const FLAG := "--debug-tour"
const RUNNER := "res://scripts/debug/screenshot_tour_runner.gd"
const MAIN_MENU := "res://scenes/main_menu.tscn"

var _runner: RefCounted


func _ready() -> void:
	if not OS.is_debug_build() or not FLAG in OS.get_cmdline_user_args():
		return
	if not ResourceLoader.exists(RUNNER):
		push_warning("[DebugTestMode] %s given, but this build doesn't include the tour runner." % FLAG)
		return
	_start.call_deferred()


func _start() -> void:
	print("[DebugTestMode] waiting for the main menu, then running the screenshot tour")
	# The splash screen moves on to the main menu by itself; starting earlier
	# would race it for the current scene.
	var tree := get_tree()
	var deadline := Time.get_ticks_msec() + 30000
	while Time.get_ticks_msec() < deadline:
		if tree.current_scene and tree.current_scene.scene_file_path == MAIN_MENU:
			break
		await tree.process_frame
	_runner = load(RUNNER).new(tree)
	var code: int = await _runner.run()
	tree.quit(code)
