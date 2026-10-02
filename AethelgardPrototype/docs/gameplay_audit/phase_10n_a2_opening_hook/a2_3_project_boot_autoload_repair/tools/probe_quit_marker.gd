extends SceneTree

const RESULT_PATH := "res://docs/gameplay_audit/phase_10n_a2_opening_hook/a2_3_project_boot_autoload_repair/diagnostics/probe_quit_marker.json"

func _initialize() -> void:
	print("A2_3_PROBE_START")
	var result := {
		"phase": "10N-A2.3",
		"probe": "probe_quit_marker",
		"marker_start_printed": true,
		"marker_before_quit_printed": false,
		"status": "started"
	}
	_write_result(result)
	print("A2_3_PROBE_BEFORE_QUIT")
	result["marker_before_quit_printed"] = true
	result["status"] = "quit_requested"
	_write_result(result)
	quit(0)

func _write_result(result: Dictionary) -> void:
	var file := FileAccess.open(RESULT_PATH, FileAccess.WRITE)
	if file == null:
		push_error("A2_3_PROBE_WRITE_FAILED: %s" % RESULT_PATH)
		return
	file.store_string(JSON.stringify(result, "  "))
	file.close()
