extends SceneTree

const OUT := "res://docs/gameplay_audit/phase_10n_a2_opening_hook/a2_2_crash_isolation/diagnostics/probe_01_project_boot_only.json"

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	print("A2_2_PROBE_01_START")
	_write({"probe": "01_project_boot_only", "last_marker": "start", "status": "running"})
	await process_frame
	var autoloads := {}
	for node_name in ["GameManager", "SceneTransitions", "ProgressionBreadcrumb", "AssetManager", "DialogueManager"]:
		autoloads[node_name] = root.get_node_or_null(node_name) != null
	print("A2_2_PROBE_01_AUTOLOADS %s" % JSON.stringify(autoloads))
	_write({"probe": "01_project_boot_only", "last_marker": "autoload_check_complete", "status": "pass", "autoloads": autoloads})
	quit(0)

func _write(data: Dictionary) -> void:
	var file := FileAccess.open(OUT, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(data, "\t"))
		file.close()

