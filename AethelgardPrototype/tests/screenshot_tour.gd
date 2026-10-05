extends SceneTree
## Runs the screenshot tour (scripts/debug/screenshot_tour_runner.gd) from the
## editor copy of the project. The tour itself, and what it checks, is documented
## in the runner; the same runner also runs inside exported debug builds
## (tools/export_windows.ps1 -Tour).
## Run: tests/run_screenshots.ps1 [-Only main_menu,ch1_crash_site]
## A game window opens for about two minutes. Audio is muted.

var _runner: RefCounted   # kept alive while the tour's coroutines run


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	# Loaded at runtime: naming the class here would compile before autoloads exist.
	_runner = load("res://scripts/debug/screenshot_tour_runner.gd").new(self)
	var code: int = await _runner.run()
	quit(code)
