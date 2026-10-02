extends SceneTree

const SCENE_PATH := "res://scenes/chapter1/opening_crash_site_hook.tscn"
const DIAG_DIR := "res://docs/gameplay_audit/phase_10n_a2_6_first_minute_micro_polish/diagnostics"
const DIAG_PATH := DIAG_DIR + "/probe_04_glitch_pulse_consequence.json"


func _initialize() -> void:
	_run()


func _run() -> void:
	print("A2_6_PROBE_04_START")
	var data := {
		"probe": "probe_04_glitch_pulse_consequence",
		"evidence_type": "CORRECTED HEADLESS RUNTIME EVIDENCE",
		"pulse_visible_after_signal": false,
		"danger_flag": false,
		"position_before_pulse": {},
		"position_after_pulse": {},
		"knockback_delta": {},
		"feedback_triggered": false,
		"hp_before": null,
		"hp_after": null,
		"pass": false,
		"errors": [],
	}
	_write_json(data)
	_clear_opening_flags()
	var scene := _instantiate_scene(data)
	if not scene:
		_write_json(data)
		quit(1)
		return
	await process_frame
	await physics_frame
	var player := scene.get_node_or_null("Player") as CharacterBody2D
	var signal_node := scene.get_node_or_null("SignalFragment")
	var pulse := scene.get_node_or_null("GlitchPulse") as Area2D
	if not player or not signal_node or not pulse:
		data["errors"].append("player, signal, or pulse missing")
		_write_json(data)
		quit(1)
		return
	var gm := get_root().get_node_or_null("GameManager")
	if gm:
		data["hp_before"] = gm.player_stats.get("hp", null)
	if player.has_method("_interact_with"):
		player.call("_interact_with", signal_node)
	await process_frame
	data["pulse_visible_after_signal"] = pulse.visible and pulse.monitoring
	player.global_position = pulse.global_position + Vector2(6, 0)
	data["position_before_pulse"] = _v(player.global_position)
	if scene.has_method("_on_glitch_pulse_body_entered"):
		scene.call("_on_glitch_pulse_body_entered", player)
	await process_frame
	data["position_after_pulse"] = _v(player.global_position)
	data["knockback_delta"] = _v(scene.get("_last_pulse_knockback_delta"))
	data["feedback_triggered"] = scene.get("_last_pulse_feedback_triggered") == true
	if gm:
		data["danger_flag"] = gm.call("get_story_flag", "ch1_opening_hook_danger_seen")
		data["hp_after"] = gm.player_stats.get("hp", null)
	var moved := Vector2(data["position_after_pulse"]["x"], data["position_after_pulse"]["y"]).distance_to(Vector2(data["position_before_pulse"]["x"], data["position_before_pulse"]["y"])) > 1.0
	if not data["pulse_visible_after_signal"]:
		data["errors"].append("pulse did not arm after signal")
	if not data["danger_flag"]:
		data["errors"].append("danger flag not set")
	if not data["feedback_triggered"] or not moved:
		data["errors"].append("pulse consequence did not move/mark feedback")
	if data["hp_before"] != data["hp_after"]:
		data["errors"].append("pulse changed HP; consequence must stay harmless")
	data["pass"] = data["errors"].is_empty()
	scene.queue_free()
	_write_json(data)
	print("A2_6_PROBE_04_DONE")
	quit(0 if data["pass"] else 1)


func _instantiate_scene(data: Dictionary) -> Node:
	var packed := load(SCENE_PATH) as PackedScene
	if not packed:
		data["errors"].append("failed to load PackedScene")
		return null
	var scene := packed.instantiate()
	get_root().add_child(scene)
	return scene


func _clear_opening_flags() -> void:
	var gm := get_root().get_node_or_null("GameManager")
	if not gm:
		return
	for flag in ["ch1_opening_hook_signal_found", "ch1_opening_hook_danger_seen", "ch1_opening_hook_complete", "plane_crash_completed", "ch1_awakening_complete", "ch1_glitch_crater_complete"]:
		gm.call("set_story_flag", flag, false)


func _v(value: Vector2) -> Dictionary:
	return {"x": snappedf(value.x, 0.001), "y": snappedf(value.y, 0.001)}


func _write_json(data: Dictionary) -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(DIAG_DIR))
	data["timestamp"] = Time.get_datetime_string_from_system()
	var file := FileAccess.open(DIAG_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(data, "\t"))
		file.close()
