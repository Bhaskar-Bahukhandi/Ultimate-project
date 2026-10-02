extends SceneTree

const OUT := "res://docs/gameplay_audit/phase_10n_a2_opening_hook/a2_2_crash_isolation/diagnostics/probe_00_quit_only.json"

func _init() -> void:
	print("A2_2_PROBE_00_START")
	_write({"probe": "00_quit_only", "last_marker": "start", "status": "running"})
	print("A2_2_PROBE_00_BEFORE_QUIT")
	_write({"probe": "00_quit_only", "last_marker": "before_quit", "status": "pass"})
	quit(0)

func _write(data: Dictionary) -> void:
	var file := FileAccess.open(OUT, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(data, "\t"))
		file.close()

