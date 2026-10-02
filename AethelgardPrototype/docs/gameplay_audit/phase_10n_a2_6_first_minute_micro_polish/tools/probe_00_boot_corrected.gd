extends SceneTree

const DIAG_DIR := "res://docs/gameplay_audit/phase_10n_a2_6_first_minute_micro_polish/diagnostics"
const DIAG_PATH := DIAG_DIR + "/probe_00_boot_corrected.json"


func _initialize() -> void:
	_run()


func _run() -> void:
	print("A2_6_PROBE_00_START")
	var root := get_root()
	var data := {
		"probe": "probe_00_boot_corrected",
		"evidence_type": "CORRECTED HEADLESS RUNTIME EVIDENCE",
		"started": true,
		"autoloads": {},
		"pass": false,
		"errors": [],
	}
	_write_json(data)
	var required := ["GameManager", "ProgressionBreadcrumb", "SceneTransitions"]
	for name in required:
		data["autoloads"][name] = root.get_node_or_null(name) != null
		if not data["autoloads"][name]:
			data["errors"].append("missing autoload: %s" % name)
	data["pass"] = data["errors"].is_empty()
	data["completed"] = true
	_write_json(data)
	print("A2_6_PROBE_00_DONE")
	quit(0 if data["pass"] else 1)


func _write_json(data: Dictionary) -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(DIAG_DIR))
	data["timestamp"] = Time.get_datetime_string_from_system()
	var file := FileAccess.open(DIAG_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(data, "\t"))
		file.close()
