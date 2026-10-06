extends SceneTree
## Can the player still reach everything? For each top-down map, this finds
## every spot the player's real collision shape fits (a 16 px grid, asking the
## physics engine), flood-fills from where the player spawns, and checks that
## every trigger area (NPCs, shops, lore, gates, exits, story triggers) can be
## touched from a reachable spot. Written before building/prop collision was
## added, so that collision can't silently wall off a door or an NPC.
## Maps with randomly placed props are loaded several times.
## Run: tests/run_phase0_tests.ps1 -Script res://tests/reachability_test.gd

const MAPS := [
	{"path": "res://scenes/chapter1/oakhaven_village.tscn", "size": Vector2(2500, 2000), "loads": 1},
	{"path": "res://scenes/regions/oakhaven_region.tscn", "size": Vector2(3200, 2400), "loads": 3},
	{"path": "res://scenes/regions/ironhold_region.tscn", "size": Vector2(3600, 2800), "loads": 3},
	{"path": "res://scenes/overworld/overworld.tscn", "size": Vector2(3000, 2200), "loads": 3},
	# Control: wall Jessa in on purpose; the test must catch it.
	{"path": "res://scenes/chapter1/oakhaven_village.tscn", "size": Vector2(2500, 2000), "loads": 1, "seal": "NPCs/Jessa"},
]
const CELL := 16.0

var _passes := 0
var _failures: Array[String] = []


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	await process_frame
	if not OS.get_user_data_dir().contains("aeth_phase0_test"):
		push_error("Refusing to run: user data dir is not isolated. Use tests/run_phase0_tests.ps1.")
		quit(2)
		return
	for m in MAPS:
		for i in m["loads"]:
			await _check_map(m["path"], m["size"], i + 1, m.get("seal", ""))
	print("")
	print("REACH RESULT: %d passed, %d failed" % [_passes, _failures.size()])
	for f in _failures:
		print("  FAIL: " + f)
	quit(0 if _failures.is_empty() else 1)


func _check(cond: bool, name: String) -> void:
	if cond:
		_passes += 1
		print("  PASS: " + name)
	else:
		_failures.append(name)
		print("  FAIL: " + name)


func _check_map(path: String, size: Vector2, load_no: int, seal: String = "") -> void:
	get_root().get_node("GameManager").reset_game()
	get_root().get_node("DialogueManager").force_reset()
	change_scene_to_file(path)
	for i in 6:
		await physics_frame
	await process_frame
	get_root().get_node("DialogueManager").force_reset()
	var scene := current_scene
	var player := _find_player(scene)
	var label := "%s (load %d)" % [path.get_file().get_basename(), load_no]
	if player == null:
		_check(false, "%s: no top-down player found" % label)
		return
	var body := player.get_node_or_null("CollisionShape2D") as CollisionShape2D
	if body == null or body.shape == null:
		_check(false, "%s: player has no body shape" % label)
		return
	if seal != "":
		var sealed := scene.get_node_or_null(seal) as Area2D
		if sealed == null:
			_check(false, "%s: control target %s not found" % [label, seal])
			return
		_wall_in(scene, _area_box(sealed).grow(40.0))
		for i in 3:
			await physics_frame
	var space := player.get_world_2d().direct_space_state
	var cols := int(ceil(size.x / CELL))
	var rows := int(ceil(size.y / CELL))

	# Free cells: the player's body fits there without touching a static body.
	var q := PhysicsShapeQueryParameters2D.new()
	q.shape = body.shape
	q.collide_with_bodies = true
	q.collide_with_areas = false
	q.collision_mask = player.collision_mask
	q.exclude = [player.get_rid()]
	var free := PackedByteArray()
	free.resize(cols * rows)
	var blocked := 0
	for y in rows:
		for x in cols:
			q.transform = Transform2D(0.0, _cell_pos(x, y) + body.position)
			var ok := space.intersect_shape(q, 1).is_empty()
			free[y * cols + x] = 1 if ok else 0
			if not ok:
				blocked += 1

	# The player must not spawn inside something solid (it would be stuck).
	q.transform = Transform2D(0.0, player.global_position + body.position)
	var spawn_clear := space.intersect_shape(q, 1).is_empty()
	if seal == "":
		_check(spawn_clear, "%s: the player spawns in free space at %s" % [label, Vector2i(player.global_position)])

	# Flood fill from the spawn point (or the nearest free cell to it).
	var start := _nearest_free(free, cols, rows, player.global_position)
	if start < 0:
		_check(false, "%s: the player spawns with no free space around it" % label)
		return
	var reach := PackedByteArray()
	reach.resize(cols * rows)
	var queue: Array[int] = [start]
	reach[start] = 1
	var reached := 1
	while not queue.is_empty():
		var c: int = queue.pop_back()
		var cx := c % cols
		var cy := c / cols
		for d in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
			var nx: int = cx + d.x
			var ny: int = cy + d.y
			if nx < 0 or ny < 0 or nx >= cols or ny >= rows:
				continue
			var n := ny * cols + nx
			if free[n] == 1 and reach[n] == 0:
				reach[n] = 1
				reached += 1
				queue.append(n)

	# Every trigger area must be touchable by the player's body from a reachable cell.
	var a := PhysicsShapeQueryParameters2D.new()
	a.shape = body.shape
	a.collide_with_bodies = false
	a.collide_with_areas = true
	a.collision_mask = 0xFFFFFFFF
	var unreachable: Array[String] = []
	var targets := _targets(scene, player)
	for area in targets:
		var box := _area_box(area).grow(48.0)
		var found := false
		var x0 := clampi(int(box.position.x / CELL), 0, cols - 1)
		var x1 := clampi(int(box.end.x / CELL), 0, cols - 1)
		var y0 := clampi(int(box.position.y / CELL), 0, rows - 1)
		var y1 := clampi(int(box.end.y / CELL), 0, rows - 1)
		for y in range(y0, y1 + 1):
			for x in range(x0, x1 + 1):
				if found or reach[y * cols + x] == 0:
					continue
				a.transform = Transform2D(0.0, _cell_pos(x, y) + body.position)
				for hit in space.intersect_shape(a, 32):
					if hit.get("collider") == area:
						found = true
						break
		if not found:
			unreachable.append("%s at %s" % [area.name, Vector2i(_area_box(area).get_center())])
	print("  %s: %d targets, %d/%d cells free, %d reachable" % [label, targets.size(), cols * rows - blocked, cols * rows, reached])
	if seal != "":
		var caught := unreachable.size() == 1 and unreachable[0].begins_with(seal.get_file())
		_check(caught, "%s: control - the test catches a deliberately walled-in %s %s" % [label, seal.get_file(), unreachable])
		return
	_check(unreachable.is_empty(), "%s: every trigger area is reachable %s" % [label, unreachable])


func _cell_pos(x: int, y: int) -> Vector2:
	return Vector2((x + 0.5) * CELL, (y + 0.5) * CELL)


func _nearest_free(free: PackedByteArray, cols: int, rows: int, pos: Vector2) -> int:
	var px := clampi(int(pos.x / CELL), 0, cols - 1)
	var py := clampi(int(pos.y / CELL), 0, rows - 1)
	for r in range(0, 12):
		for y in range(py - r, py + r + 1):
			for x in range(px - r, px + r + 1):
				if x < 0 or y < 0 or x >= cols or y >= rows:
					continue
				if free[y * cols + x] == 1:
					return y * cols + x
	return -1


func _find_player(scene: Node) -> CharacterBody2D:
	for n in get_nodes_in_group("player"):
		if n is CharacterBody2D and scene.is_ancestor_of(n):
			return n
	return null


## Monitoring Area2Ds with at least one enabled shape, except the player's own
## (its InteractionArea) and anything under an enemy.
func _targets(scene: Node, player: Node) -> Array[Area2D]:
	var out: Array[Area2D] = []
	var stack: Array[Node] = [scene]
	while not stack.is_empty():
		var n: Node = stack.pop_back()
		for c in n.get_children():
			stack.append(c)
		var area := n as Area2D
		if area == null or not area.monitoring or player.is_ancestor_of(area):
			continue
		if area.get_parent() is CharacterBody2D:
			continue   # enemy hit/detection areas move with their owner
		var has_shape := false
		for c in area.get_children():
			if c is CollisionShape2D and c.shape and not c.disabled:
				has_shape = true
		if has_shape:
			out.append(area)
	return out


func _area_box(area: Area2D) -> Rect2:
	var box := Rect2(area.global_position, Vector2.ZERO)
	for c in area.get_children():
		if c is CollisionShape2D and c.shape:
			var r: Rect2 = c.shape.get_rect()
			box = box.merge(c.global_transform * r)
	return box


## Four static walls around `box`, for the control check.
func _wall_in(scene: Node, box: Rect2) -> void:
	var t := 12.0
	for r in [Rect2(box.position.x - t, box.position.y - t, box.size.x + 2 * t, t),
			Rect2(box.position.x - t, box.end.y, box.size.x + 2 * t, t),
			Rect2(box.position.x - t, box.position.y, t, box.size.y),
			Rect2(box.end.x, box.position.y, t, box.size.y)]:
		var body := StaticBody2D.new()
		body.position = r.get_center()
		var col := CollisionShape2D.new()
		var shape := RectangleShape2D.new()
		shape.size = r.size
		col.shape = shape
		body.add_child(col)
		scene.add_child(body)
