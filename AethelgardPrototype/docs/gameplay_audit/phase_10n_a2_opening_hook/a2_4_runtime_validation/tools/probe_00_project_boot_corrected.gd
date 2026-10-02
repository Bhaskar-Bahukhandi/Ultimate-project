extends SceneTree

const OUT := "res://docs/gameplay_audit/phase_10n_a2_opening_hook/a2_4_runtime_validation/diagnostics/probe_00_project_boot_corrected.json"

var result := {
	"phase": "10N-A2.4",
	"probe": "probe_00_project_boot_corrected",
	"evidence_type": "CORRECTED HEADLESS RUNTIME EVIDENCE",
	"start_marker_printed": false,
	"autoloads": {},
	"status": "started"
}

func _initialize() -> void:
	print("A2_4_PROBE_00_START")
	result["start_marker_printed"] = true
	_write()
	await process_frame
	await process_frame
	for name in ["GameManager", "SceneTransitions", "ProgressionBreadcrumb", "AssetManager", "Inventory"]:
		result["autoloads"][name] = root.get_node_or_null(name) != null
	var ok: bool = true
	for value in result["autoloads"].values():
		ok = ok and bool(value)
	_finish(ok, "autoload boot check complete")

func _finish(ok: bool, notes: String) -> void:
	result["status"] = "pass" if ok else "fail"
	result["notes"] = notes
	_write()
	print("A2_4_PROBE_00_DONE %s" % result["status"])
	quit(0 if ok else 1)

func _write() -> void:
	var file := FileAccess.open(OUT, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(result, "  "))
		file.close()



