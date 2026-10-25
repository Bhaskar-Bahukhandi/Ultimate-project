extends Node2D

## Chapter 1, C1-S02 — Elara's house (Y1-P0-S08). Top-down, placeholder shapes.
## Words are in dialogue/ch1/elara_house.dlg: the stew (`start`) plays at her
## table the first time Kaelen walks in; the five things in the room have their
## own inspect nodes. The village's door (Doors/ElaraHouseDoor in
## oakhaven_village.tscn) brings the player here once Elara has invited him;
## this room's Door takes him back to just outside it.
## The walls and the table block (collision read from the scene's shapes, as the
## village does for its buildings); nothing else in the room has collision.

const DLG_FILE := "res://dialogue/ch1/elara_house.dlg"
const VILLAGE_SCENE := "res://scenes/chapter1/oakhaven_village.tscn"
## Where the player stands in the village on the way out: just below the
## village's Doors/ElaraHouseDoor (670, 1172). Keep the two in step.
const VILLAGE_DOOR_OUTSIDE := Vector2(670, 1200)
const STEW_START_DELAY_SEC := 0.6   # the room shows for a moment before Elara speaks
const EVENT_BEAT_SEC := 0.35        # pause on a stage-direction event (same as the village)
## Inspect spot (node name) -> elara_house.dlg node.
const INSPECT_SPOTS := {
	"Bandages": "inspect_bandages",
	"Herbs": "inspect_herbs",
	"Focuses": "inspect_focuses",
	"Cloak": "inspect_cloak",
	"Map": "inspect_map",
}

var in_dialogue: bool = false
var _dlg_depth := 0
var _stew_running := false
var _is_transitioning := false


func _ready() -> void:
	GameManager.change_state(GameManager.GameState.EXPLORATION)
	# Discards any stale return point; the player always starts inside the door
	# (a load places the player itself).
	GameManager.arrive_in_exploration_scene(scene_file_path)
	_add_room_collision()
	_set_camera_limits()
	_bind_area(get_node_or_null("Door") as Area2D, _on_door_interaction)
	for spot_name in INSPECT_SPOTS:
		_bind_area(get_node_or_null(spot_name) as Area2D, _on_inspect.bind(INSPECT_SPOTS[spot_name]))
	if GameManager.has_flag("ch1_stew_done"):
		return
	# Set before the first await: the door stays shut from the moment the room loads.
	_stew_running = true
	await get_tree().create_timer(STEW_START_DELAY_SEC, false).timeout
	if not is_inside_tree(): return
	while SceneTransitions.is_transitioning:
		await get_tree().process_frame
		if not is_inside_tree(): return
	await _play_stew()

# ── Dialogue plumbing (as in ch1_oakhaven_village.gd) ─────────────────────

## Plays one elara_house.dlg node. While any node is playing, in_dialogue is
## true (the door and the inspect spots wait) and the game is in DIALOGUE.
func _run(node: String) -> Dictionary:
	_dlg_depth += 1
	in_dialogue = true
	GameManager.change_state(GameManager.GameState.DIALOGUE)
	var r: Dictionary = await DialogueManager.run(DLG_FILE, node, _on_dlg_event)
	_dlg_depth -= 1
	if _dlg_depth == 0:
		in_dialogue = false
		if is_inside_tree() and not _is_transitioning:
			GameManager.change_state(GameManager.GameState.EXPLORATION)
	return r

func _on_dlg_event(event: String) -> void:
	var parts := event.split(" ", false, 1)
	match parts[0]:
		"elara_serves_stew", "elara_sees_him_look":
			await get_tree().create_timer(EVENT_BEAT_SEC, false).timeout
		_:
			print("[ELARA_HOUSE] unhandled dialogue event: %s" % event)

# ── C1-S02: the stew ──────────────────────────────────────────────────────

## The stew, once. ch1_stew_done (Y1-P0-T05: the breadcrumb moves from step 5
## to step 6 on it) is set here and nowhere else, and only when the run has
## returned while this room is still the current scene: a room left mid-run
## (a load, a quit) never sets it, and nothing sets it before the run returns.
func _play_stew() -> void:
	await _run("start")
	if not is_inside_tree() or get_tree().current_scene != self:
		return
	GameManager.set_story_flag("ch1_stew_done", true)
	_stew_running = false

# ── The room: door, inspect spots ─────────────────────────────────────────

## Something is playing (the stew, an inspect line) or the scene is changing.
func _busy() -> bool:
	return in_dialogue or _stew_running or _is_transitioning

## The player's targeting (player_topdown.gd) asks this before offering a
## prompt: nothing in the room answers while something is playing.
func _can_interact_with(_node: Node) -> bool:
	return not _busy()

## The door out. Shut while the stew plays and during any conversation.
func _on_door_interaction(body: Node) -> void:
	if body.name != "Player" or _busy():
		return
	_leave_house()

func _on_inspect(body: Node, dlg_node: String) -> void:
	if body.name != "Player" or _busy():
		return
	await _run(dlg_node)

## Back to the village, outside the door. The village skips its arrival once
## ch1_stew_done is set and places the player from this return point.
func _leave_house() -> void:
	if _is_transitioning or SceneTransitions.is_transitioning:
		return
	_is_transitioning = true
	GameManager.set_return_point(VILLAGE_SCENE, VILLAGE_DOOR_OUTSIDE)
	SceneTransitions.change_scene(VILLAGE_SCENE)

## Interact with the area runs `handler` (the player calls the
## "interact_handler" meta with itself).
func _bind_area(area: Area2D, handler: Callable) -> void:
	if not area:
		print("[ELARA_HOUSE] interactable node missing")
		return
	area.add_to_group("interactable")
	area.set_meta("interact_handler", handler)

## The walls and the table block; read from their shapes in the scene so the
## collision stays in sync with what is drawn.
func _add_room_collision() -> void:
	var blockers: Array[Node] = []
	var walls := get_node_or_null("Walls")
	if walls:
		blockers.append_array(walls.get_children())
	var table := get_node_or_null("Table")
	if table:
		blockers.append(table)
	for n in blockers:
		var r := n as Control
		if r:
			_add_boundary(r.global_position, r.size, "%sCollision" % r.name)

func _add_boundary(pos: Vector2, size: Vector2, body_name: String) -> void:
	var static_body := StaticBody2D.new()
	static_body.name = body_name
	static_body.position = pos
	var collision_shape := CollisionShape2D.new()
	var rect_shape := RectangleShape2D.new()
	rect_shape.size = size
	collision_shape.shape = rect_shape
	collision_shape.position = size / 2.0
	static_body.add_child(collision_shape)
	add_child(static_body)

## The camera stops at the room's edges (the Floor rect is the room).
func _set_camera_limits() -> void:
	var room := get_node_or_null("Floor") as Control
	var camera := get_node_or_null("Player/Camera2D") as Camera2D
	if not room or not camera:
		return
	var rect := Rect2(room.global_position, room.size)
	camera.limit_left = int(rect.position.x)
	camera.limit_top = int(rect.position.y)
	camera.limit_right = int(rect.end.x)
	camera.limit_bottom = int(rect.end.y)
	camera.reset_smoothing()
