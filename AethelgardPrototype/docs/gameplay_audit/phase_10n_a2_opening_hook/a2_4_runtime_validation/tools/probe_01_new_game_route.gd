extends SceneTree

const OUT := "res://docs/gameplay_audit/phase_10n_a2_opening_hook/a2_4_runtime_validation/diagnostics/probe_01_new_game_route.json"
const MAIN_MENU_SCRIPT := "res://scripts/main_menu.gd"
const OPENING_HOOK := "res://scenes/chapter1/opening_crash_site_hook.tscn"
const LEGACY_PROLOGUE := "res://scenes/prologue/flight_707.tscn"

var result := {
	"phase": "10N-A2.4",
	"probe": "probe_01_new_game_route",
	"evidence_type": "STATIC CODE EVIDENCE / CORRECTED HEADLESS RUNTIME EVIDENCE",
	"start_marker_printed": false,
	"status": "started"
}

func _initialize() -> void:
	print("A2_4_PROBE_01_START")
	result["start_marker_printed"] = true
	_write()
	var source := ""
	var file := FileAccess.open(MAIN_MENU_SCRIPT, FileAccess.READ)
	if file:
		source = file.get_as_text()
		file.close()
	result["main_menu_script_read"] = not source.is_empty()
	result["opening_hook_const_found"] = source.find('const OPENING_HOOK_SCENE := "' + OPENING_HOOK + '"') >= 0
	result["legacy_const_found"] = source.find('const LEGACY_PROLOGUE_SCENE := "' + LEGACY_PROLOGUE + '"') >= 0
	result["new_game_calls_reset"] = source.find("func _on_new_game_pressed") >= 0 and source.find("GameManager.reset_game()") >= 0
	result["new_game_uses_opening_target"] = source.find("var target_scene := OPENING_HOOK_SCENE") >= 0
	result["fallback_to_legacy_present"] = source.find("target_scene = LEGACY_PROLOGUE_SCENE") >= 0
	result["legacy_function_present"] = source.find("func _start_legacy_cinematic_prologue") >= 0
	result["opening_hook_resource_exists"] = ResourceLoader.exists(OPENING_HOOK)
	result["legacy_resource_exists"] = ResourceLoader.exists(LEGACY_PROLOGUE)
	var ok: bool = result["opening_hook_const_found"] and result["legacy_const_found"] and result["new_game_calls_reset"] and result["new_game_uses_opening_target"] and result["fallback_to_legacy_present"] and result["legacy_function_present"] and result["opening_hook_resource_exists"] and result["legacy_resource_exists"]
	_finish(ok, "main menu route inspected without pressing UI")

func _finish(ok: bool, notes: String) -> void:
	result["status"] = "pass" if ok else "fail"
	result["notes"] = notes
	_write()
	print("A2_4_PROBE_01_DONE %s" % result["status"])
	quit(0 if ok else 1)

func _write() -> void:
	var file := FileAccess.open(OUT, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(result, "  "))
		file.close()


