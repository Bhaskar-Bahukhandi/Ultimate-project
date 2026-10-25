extends Node2D

## Chapter 1, C1-S10 to C1-S12 — the shrine under the old gate (Y1-P0-S08).
## Top-down, placeholder shapes. The arena (ch1_tutorial_knight.gd) changes
## here after the Aldric decision. The altar plays Fragment One
## (fragment_one.dlg `fragment`); after it, the stair door plays the rest of
## Chapter 1: "Oakhaven, after dark", the bridge news if it fell, the village
## meeting, Elara joining, then the Chapter 1 ending (shatter_transition).
## The walls and the altar block (collision read from the scene's shapes, as
## Elara's house does); the gate dressing has no collision.

const FRAGMENT_DLG := "res://dialogue/ch1/fragment_one.dlg"
const NORTH_FIELD_DLG := "res://dialogue/ch1/north_field.dlg"
const ENDING_SCENE := "res://scenes/chapter1/shatter_transition.tscn"
const CARD_WIDTH := 1280.0            # the place card spans the viewport (as it did over the arena)
const CARD_CLEAR_SEC := 0.6           # the arrival card fades back to the room
const EVENT_BEAT_SEC := 0.4           # pause on a stage-direction event (as in the arena)
const FLASH_BEAT_SEC := 0.3
const SHAKE_BEAT_SEC := 0.35
const ENDING_DELAY_SEC := 1.0         # after Elara joins, before the ending

var _arrival_running := false
## Single-fire guards, set before the first await (as the village's _field_running).
var _altar_running := false
var _chain_running := false
## True once this scene has asked for the ending; _exit_tree then leaves the
## game state alone.
var _scene_change_requested := false
var _card_layer: CanvasLayer = null
@onready var player: CharacterBody2D = get_node_or_null("Player") as CharacterBody2D


func _ready() -> void:
	GameManager.change_state(GameManager.GameState.EXPLORATION)
	GameManager.arrive_in_exploration_scene(scene_file_path)
	var fresh := _take_fresh_arrival()
	_add_room_collision()
	_set_camera_limits()
	_show_dressing()
	_bind_area(get_node_or_null("Altar") as Area2D, _on_altar_interaction)
	_bind_area(get_node_or_null("StairDoor") as Area2D, _on_stair_door_interaction)
	# D6: only a walk-in from the arena checkpoints and shows the card; a load does neither.
	if not fresh or GameManager.has_flag("source_key_fragment_1"):
		return
	_arrival_running = true
	_freeze_player(true)   # no walking blind under the black card
	GameManager.auto_save()   # queued until the transition into this room completes
	while SceneTransitions.is_transitioning:
		await get_tree().process_frame
		if not is_inside_tree(): return
	await _location_card("Under the old gate")
	if not is_inside_tree(): return
	await _clear_card()
	if not is_inside_tree(): return
	_freeze_player(false)
	_arrival_running = false

## Reads and clears the arena's hand-off meta (GameManager.SHRINE_FRESH_ARRIVAL_META,
## in TRANSIENT_METAS, so a load never carries it).
func _take_fresh_arrival() -> bool:
	var key := GameManager.SHRINE_FRESH_ARRIVAL_META
	var fresh := GameManager.has_meta(key) and bool(GameManager.get_meta(key))
	if GameManager.has_meta(key):
		GameManager.remove_meta(key)
	return fresh

## Holds the player still while the screen is black but no dialogue line is
## up (player_topdown.gd only stops for an active dialogue, not a game state;
## the arena freezes its player the same way). Call with the room already busy:
## the one refresh below then drops the target and its prompt, which the
## stopped physics loop would otherwise leave on screen.
func _freeze_player(frozen: bool) -> void:
	if not player:
		return
	player.velocity = Vector2.ZERO
	player.set_physics_process(not frozen)
	if frozen and player.has_method("_refresh_interaction_target"):
		player._refresh_interaction_target()

## AC-10(e): leaving mid-Fragment or mid-chain (a load, a quit) must not strand
## the game in DIALOGUE or CUTSCENE. Not when this scene asked for the ending.
func _exit_tree() -> void:
	if _scene_change_requested:
		return
	if has_node("/root/GameManager") and GameManager.current_state in [GameManager.GameState.CUTSCENE, GameManager.GameState.DIALOGUE]:
		GameManager.change_state(GameManager.GameState.EXPLORATION)

# ── The room: altar, stair door ───────────────────────────────────────────

## The card, the Fragment or the chain is playing, or the ending was asked for.
func _busy() -> bool:
	return _arrival_running or _altar_running or _chain_running or _scene_change_requested

## The player's targeting (player_topdown.gd) asks this before offering a
## prompt: the altar until Fragment One is taken, the stair door after it.
func _can_interact_with(node: Node) -> bool:
	if _busy():
		return false
	var has_fragment := GameManager.has_flag("source_key_fragment_1")
	if node.name == "Altar":
		return not has_fragment
	if node.name == "StairDoor":
		return has_fragment
	return true

## C1-S10: Fragment One. Once; inactive after source_key_fragment_1 is set.
func _on_altar_interaction(body: Node) -> void:
	if body.name != "Player" or _busy() or GameManager.has_flag("source_key_fragment_1"):
		return
	_altar_running = true
	GameManager.change_state(GameManager.GameState.DIALOGUE)
	await DialogueManager.run(FRAGMENT_DLG, "fragment", _on_dlg_event)
	if not is_inside_tree(): return
	_altar_running = false
	GameManager.change_state(GameManager.GameState.EXPLORATION)

## C1-S11/S12: the rest of Chapter 1. Inactive until Fragment One is taken;
## once. Runs in CUTSCENE, so manual saves and Quick Save are refused.
func _on_stair_door_interaction(body: Node) -> void:
	if body.name != "Player" or _busy() or not GameManager.has_flag("source_key_fragment_1"):
		return
	_chain_running = true
	GameManager.change_state(GameManager.GameState.CUTSCENE)
	_freeze_player(true)   # the chain ends in the shatter; the player never walks again here
	await _play_after_dark()

## Moved unchanged from ch1_tutorial_knight.gd _play_aldric_decision.
func _play_after_dark() -> void:
	# The bridge deadline was "until dark". If it wasn't fixed, it's gone now.
	var bridge_seen := GameManager.has_flag("ch1_bridge_repair_accepted") or GameManager.has_flag("ch1_bridge_evacuated") \
		or GameManager.has_flag("ch1_bridge_ignored")
	if bridge_seen and not GameManager.has_flag("ch1_bridge_saved"):
		GameManager.set_story_flag("ch1_bridge_fell", true)
		await _location_card("Oakhaven, after dark")
		if not is_inside_tree(): return
		await DialogueManager.run(NORTH_FIELD_DLG, "bridge_fell", _on_dlg_event)
		if not is_inside_tree(): return
	else:
		await _location_card("Oakhaven, after dark")
		if not is_inside_tree(): return

	await DialogueManager.run(FRAGMENT_DLG, "meeting", _on_dlg_event)
	if not is_inside_tree(): return
	await DialogueManager.run(FRAGMENT_DLG, "joins", _on_dlg_event)
	if not is_inside_tree(): return
	await get_tree().create_timer(ENDING_DELAY_SEC, false).timeout
	if not is_inside_tree(): return
	# change_scene() ignores a request made mid-transition; committing the guard
	# before a dropped request would leave the player frozen in CUTSCENE.
	while SceneTransitions.is_transitioning:
		await get_tree().process_frame
		if not is_inside_tree(): return
	_scene_change_requested = true
	SceneTransitions.change_scene(ENDING_SCENE, SceneTransitions.TransitionStyle.SHATTER)

func _on_dlg_event(event: String) -> void:
	var parts := event.split(" ", false, 1)
	match parts[0]:
		"elara_packs", "village_gathers", "elara_watches", "kaelen_recoils", "flash_ends":
			await get_tree().create_timer(EVENT_BEAT_SEC, false).timeout
		"memory_flash", "touch_fragment":
			if has_node("/root/SceneTransitions"):
				SceneTransitions.flash(Color(1, 1, 1, 0.6), 0.25)
			await get_tree().create_timer(FLASH_BEAT_SEC, false).timeout
		"villagers_panic":
			if has_node("/root/CombatFX"):
				CombatFX.apply_screen_shake(9.0, 0.35)
			await get_tree().create_timer(SHAKE_BEAT_SEC, false).timeout
		"fragment_acquired":
			GameManager.collect_source_key(int(parts[1]) if parts.size() > 1 else 1)
			if has_node("/root/VFXLibrary") and player:
				VFXLibrary.spawn_status_indicator("SOURCE KEY 1/7", player.global_position + Vector2(0, -90), self, true)
		"elara_joins_party":
			pass   # Elara is already travelling with Kaelen; ch1_elara_joined marks it
		_:
			print("[SHRINE] unhandled dialogue event: %s" % event)

## A black card with a place name (moved from the arena). Sits under the
## dialogue box (layer 100), over the room.
func _location_card(text: String) -> void:
	if _card_layer == null:
		_card_layer = CanvasLayer.new()
		_card_layer.layer = 95
		add_child(_card_layer)
		var black := ColorRect.new()
		black.name = "Black"
		black.color = Color.BLACK
		black.set_anchors_preset(Control.PRESET_FULL_RECT)
		black.mouse_filter = Control.MOUSE_FILTER_IGNORE
		black.modulate.a = 0.0
		_card_layer.add_child(black)
		var label := Label.new()
		label.name = "Place"
		label.set_anchors_preset(Control.PRESET_CENTER_TOP)
		label.position = Vector2(0, 200)
		label.size = Vector2(CARD_WIDTH, 40)
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.add_theme_font_size_override("font_size", 22)
		label.add_theme_color_override("font_color", Color(0.85, 0.85, 0.9))
		_card_layer.add_child(label)
	var black_rect := _card_layer.get_node("Black") as ColorRect
	var place := _card_layer.get_node("Place") as Label
	place.text = text
	place.modulate.a = 0.0
	var t := create_tween()
	t.tween_property(black_rect, "modulate:a", 1.0, 0.6)
	t.tween_property(place, "modulate:a", 1.0, 0.4)
	t.tween_interval(1.0)
	t.tween_property(place, "modulate:a", 0.0, 0.4)
	await t.finished

## The arrival card fades back to the room (over the arena the card's black
## stayed up for the rest of the chapter; here the player walks the room).
func _clear_card() -> void:
	if _card_layer == null:
		return
	var t := create_tween()
	t.tween_property(_card_layer.get_node("Black"), "modulate:a", 0.0, CARD_CLEAR_SEC)
	await t.finished

## AC-5: at most one gate dressing, for the Aldric outcome. Purge is checked
## first (a purge also sets ch1_knight_spared).
func _show_dressing() -> void:
	var shown := ""
	if GameManager.has_flag("ch1_root_purge"):
		shown = "DressingPurged"
	elif GameManager.has_flag("ch1_knight_killed"):
		shown = "DressingKilled"
	elif GameManager.has_flag("ch1_knight_spared"):
		shown = "DressingSpared"
	for n in ["DressingPurged", "DressingKilled", "DressingSpared"]:
		var node := get_node_or_null(n) as CanvasItem
		if node:
			node.visible = n == shown

## Interact with the area runs `handler` (the player calls the
## "interact_handler" meta with itself).
func _bind_area(area: Area2D, handler: Callable) -> void:
	if not area:
		print("[SHRINE] interactable node missing")
		return
	area.add_to_group("interactable")
	area.set_meta("interact_handler", handler)

## The walls and the altar stone block; read from their shapes in the scene
## so the collision stays in sync with what is drawn.
func _add_room_collision() -> void:
	var blockers: Array[Node] = []
	var walls := get_node_or_null("Walls")
	if walls:
		blockers.append_array(walls.get_children())
	var stone := get_node_or_null("Altar/Stone")
	if stone:
		blockers.append(stone)
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
