extends SceneTree

const OPENING_SCENE := "res://scenes/chapter1/opening_crash_site_hook.tscn"
const OUT := "res://docs/gameplay_audit/phase_10n_a2_opening_hook/a2_2_crash_isolation/diagnostics/probe_05_interactable_only.json"

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	print("A2_2_PROBE_05_START")
	_write({"probe": "05_interactable_only", "last_marker": "start", "status": "running"})
	await process_frame
	var packed := ResourceLoader.load(OPENING_SCENE) as PackedScene
	if not packed:
		_write({"probe": "05_interactable_only", "last_marker": "packed_load_failed", "status": "fail"})
		quit(1)
		return
	var scene := packed.instantiate()
	root.add_child(scene)
	current_scene = scene
	for _i in range(5):
		await process_frame
	var signal_node := scene.get_node_or_null("SignalFragment")
	var objective_label := scene.get_node_or_null("OpeningHookHUD/FirstMinuteObjectivePanel/VBoxContainer/ObjectiveLabel")
	var result := {
		"signal_fragment_exists": signal_node != null,
		"signal_fragment_interactable": signal_node != null and signal_node.is_in_group("interactable"),
		"objective_label_exists": objective_label != null,
		"objective_text": str(objective_label.text) if objective_label else "",
		"glitch_pulse_exists": scene.get_node_or_null("GlitchPulse") != null,
		"oakhaven_path_exists": scene.get_node_or_null("OakhavenPath") != null
	}
	var passed := result["signal_fragment_exists"] and result["signal_fragment_interactable"] and result["objective_label_exists"] and str(result["objective_text"]).contains("Stand up. Find a signal")
	print("A2_2_PROBE_05_RESULT %s" % JSON.stringify(result))
	_write({"probe": "05_interactable_only", "last_marker": "interactable_check_complete", "status": "pass" if passed else "fail", "result": result})
	quit(0 if passed else 1)

func _write(data: Dictionary) -> void:
	var file := FileAccess.open(OUT, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(data, "\t"))
		file.close()

