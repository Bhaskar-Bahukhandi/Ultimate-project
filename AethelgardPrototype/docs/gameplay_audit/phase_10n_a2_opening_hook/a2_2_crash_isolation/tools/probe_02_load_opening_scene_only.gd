extends SceneTree

const OPENING_SCENE := "res://scenes/chapter1/opening_crash_site_hook.tscn"
const OUT := "res://docs/gameplay_audit/phase_10n_a2_opening_hook/a2_2_crash_isolation/diagnostics/probe_02_load_opening_scene_only.json"

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	print("A2_2_PROBE_02_START")
	_write({"probe": "02_load_opening_scene_only", "last_marker": "start", "status": "running", "scene": OPENING_SCENE})
	await process_frame
	var exists := ResourceLoader.exists(OPENING_SCENE)
	print("A2_2_PROBE_02_EXISTS %s" % str(exists))
	_write({"probe": "02_load_opening_scene_only", "last_marker": "resource_exists_checked", "status": "running", "exists": exists})
	var packed := ResourceLoader.load(OPENING_SCENE) as PackedScene
	var loaded := packed != null
	print("A2_2_PROBE_02_LOADED %s" % str(loaded))
	_write({"probe": "02_load_opening_scene_only", "last_marker": "packed_scene_load_complete", "status": "pass" if loaded else "fail", "exists": exists, "loaded": loaded})
	quit(0 if loaded else 1)

func _write(data: Dictionary) -> void:
	var file := FileAccess.open(OUT, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(data, "\t"))
		file.close()

