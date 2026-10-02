extends SceneTree

const OPENING_SCENE := "res://scenes/chapter1/opening_crash_site_hook.tscn"
const OUT := "res://docs/gameplay_audit/phase_10n_a2_opening_hook/a2_2_crash_isolation/diagnostics/probe_04_player_movement_only.json"

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	print("A2_2_PROBE_04_START")
	_write({"probe": "04_player_movement_only", "last_marker": "start", "status": "running"})
	await process_frame
	var packed := ResourceLoader.load(OPENING_SCENE) as PackedScene
	if not packed:
		_write({"probe": "04_player_movement_only", "last_marker": "packed_load_failed", "status": "fail"})
		quit(1)
		return
	var scene := packed.instantiate()
	root.add_child(scene)
	current_scene = scene
	for _i in range(4):
		await physics_frame
	var player := scene.get_node_or_null("Player") as CharacterBody2D
	_write({"probe": "04_player_movement_only", "last_marker": "player_lookup_complete", "status": "running", "player_exists": player != null})
	if not player:
		quit(1)
		return
	var start_pos := player.global_position
	print("A2_2_PROBE_04_START_POS %s" % str(start_pos))
	Input.action_press("move_right")
	for _i in range(30):
		await physics_frame
	Input.action_release("move_right")
	var end_pos := player.global_position
	var moved := end_pos.distance_to(start_pos) > 4.0
	print("A2_2_PROBE_04_END_POS %s MOVED %s" % [str(end_pos), str(moved)])
	_write({"probe": "04_player_movement_only", "last_marker": "movement_complete", "status": "pass" if moved else "fail", "player_exists": true, "start_pos": str(start_pos), "end_pos": str(end_pos), "distance": end_pos.distance_to(start_pos), "moved": moved})
	quit(0 if moved else 1)

func _write(data: Dictionary) -> void:
	var file := FileAccess.open(OUT, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(data, "\t"))
		file.close()

