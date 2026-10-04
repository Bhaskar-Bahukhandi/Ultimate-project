extends Node
## ContextStack — the ONE owner of:
##   • which modal UI is open (pause, shop, map, Root Access, credits…),
##   • whether the tree is paused  (get_tree().paused),
##   • Engine.time_scale (hitstop, slow-mo…).
## Nothing else writes `get_tree().paused` or `Engine.time_scale`. Replaces
## UIStack. Review root cause R1: these globals had ~40 writers that kept
## undoing each other (pause screens unpausing Root Access, slow-mo stuck,
## scenes loading paused).
##
## Modals:
##   if ContextStack.push(&"shop", self):   # false = something else is open
##       ...
##   ContextStack.pop(&"shop")
## A context is popped automatically when its `owner` node leaves the tree,
## so a scene that changes while its panel is open can't leave the game paused.
##
## Time scale:
##   ContextStack.request_time_scale(&"hitstop", 0.05, ContextStack.PRIORITY_HITSTOP)
##   ContextStack.release_time_scale(&"hitstop")
## The highest-priority request wins (ties: the slowest). No requests = 1.0.

signal contexts_changed(top: StringName)

const PRIORITY_WOBBLE := 5
const PRIORITY_SLOWMO := 10
const PRIORITY_DRAMATIC := 20
const PRIORITY_HITSTOP := 30

var _stack: Array[Dictionary] = []      # {id, owner, pauses, blocks}
var _time_requests: Dictionary = {}     # StringName -> {scale, priority}
var _last_change_frame: int = -1


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS


# ── Modal contexts ────────────────────────────────────────────────────────

## Open a context. `exclusive` contexts are refused while anything else is
## open; a non-exclusive one (e.g. a tracker opened FROM the pause menu)
## stacks on top. Returns true if the context is (now) open.
func push(id: StringName, owner: Node = null, pauses_tree: bool = true,
		blocks_gameplay: bool = true, exclusive: bool = true) -> bool:
	if is_open(id):
		return true
	if exclusive and not _stack.is_empty():
		if OS.is_debug_build():
			print("[ContextStack] '%s' refused — '%s' is open" % [id, top()])
		return false
	_stack.append({"id": id, "owner": owner, "pauses": pauses_tree, "blocks": blocks_gameplay})
	if owner:
		var cb := _on_owner_exiting.bind(id)
		if not owner.tree_exiting.is_connected(cb):
			owner.tree_exiting.connect(cb, CONNECT_ONE_SHOT)
	_changed()
	return true


## Close a context (no-op if it isn't open).
func pop(id: StringName) -> void:
	for i in range(_stack.size() - 1, -1, -1):
		if _stack[i]["id"] == id:
			_stack.remove_at(i)
			_changed()
			return


func is_open(id: StringName) -> bool:
	return _stack.any(func(c): return c["id"] == id)


func any_open() -> bool:
	return not _stack.is_empty()


func top() -> StringName:
	return _stack.back()["id"] if not _stack.is_empty() else &""


## True while any open context blocks gameplay (movement, combat input,
## random encounters) — including ones that don't pause the tree.
func gameplay_blocked() -> bool:
	return _stack.any(func(c): return c["blocks"])


## True if a context opened or closed during this frame. Used so one key
## press can't both close one menu and open another (e.g. Esc closing the map
## and opening pause).
func changed_this_frame() -> bool:
	return _last_change_frame == Engine.get_process_frames()


## Close everything (New Game, return to title).
func clear() -> void:
	_stack.clear()
	_changed()


func _on_owner_exiting(id: StringName) -> void:
	if is_open(id):
		if OS.is_debug_build():
			print("[ContextStack] '%s' closed because its owner left the tree" % id)
		pop(id)


func _changed() -> void:
	_last_change_frame = Engine.get_process_frames()
	var want_paused := _stack.any(func(c): return c["pauses"])
	if is_inside_tree() and get_tree().paused != want_paused:
		get_tree().paused = want_paused
	contexts_changed.emit(top())


# ── Time scale ────────────────────────────────────────────────────────────

func request_time_scale(owner_id: StringName, scale: float, priority: int = PRIORITY_SLOWMO) -> void:
	_time_requests[owner_id] = {"scale": clampf(scale, 0.0, 4.0), "priority": priority}
	_apply_time_scale()


func release_time_scale(owner_id: StringName) -> void:
	if _time_requests.erase(owner_id):
		_apply_time_scale()


func has_time_request(owner_id: StringName) -> bool:
	return _time_requests.has(owner_id)


## Drop every request (scene changes, death, retry): no slow-mo survives them.
func clear_time_scale() -> void:
	_time_requests.clear()
	_apply_time_scale()


func _apply_time_scale() -> void:
	var best: Variant = null
	for req in _time_requests.values():
		if best == null or req["priority"] > best["priority"] \
				or (req["priority"] == best["priority"] and req["scale"] < best["scale"]):
			best = req
	Engine.time_scale = best["scale"] if best != null else 1.0
