extends SceneTree

const OUT := "res://docs/gameplay_audit/phase_10n_a2_opening_hook/a2_4_runtime_validation/diagnostics/probe_02_load_opening_scene.json"
const SCENE_PATH := "res://scenes/chapter1/opening_crash_site_hook.tscn"

var result := {"phase":"10N-A2.4","probe":"probe_02_load_opening_scene","evidence_type":"CORRECTED HEADLESS RUNTIME EVIDENCE","start_marker_printed":false,"status":"started"}

func _initialize() -> void:
	print("A2_4_PROBE_02_START")
	result["start_marker_printed"] = true
	_write()
	result["resource_exists"] = ResourceLoader.exists(SCENE_PATH)
	var packed := ResourceLoader.load(SCENE_PATH)
	result["loaded"] = packed != null
	result["is_packed_scene"] = packed is PackedScene
	_finish(result["resource_exists"] and result["is_packed_scene"], "PackedScene load check only; not instantiated")

func _finish(ok: bool, notes: String) -> void:
	result["status"] = "pass" if ok else "fail"
	result["notes"] = notes
	_write()
	print("A2_4_PROBE_02_DONE %s" % result["status"])
	quit(0 if ok else 1)

func _write() -> void:
	var file := FileAccess.open(OUT, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(result, "  "))
		file.close()


