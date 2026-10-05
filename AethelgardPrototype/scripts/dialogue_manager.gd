extends Node
## ==========================================================================
## DIALOGUE MANAGER — Universal dialogue display with built-in programmatic UI
## ==========================================================================
## Autoload singleton: DialogueManager
## Primary API:
##   await DialogueManager.say("Speaker", "Text here")
##   var idx = await DialogueManager.show_choices("Prompt?", ["A","B","C"])
##   DialogueManager.hide_dialogue()
## ==========================================================================

# ── Signals ───────────────────────────────────────────────────────────────
signal dialogue_started
signal dialogue_finished
signal dialogue_line_shown
signal choice_selected(choice_index: int)
signal dialogue_skipped

# ── Legacy API state ──────────────────────────────────────────────────────
var current_dialogue: Array = []
var current_index: int = 0
var is_active: bool = false

# ── Built-in UI elements ─────────────────────────────────────────────────
var _ui_layer: CanvasLayer
var _panel: PanelContainer
var _margin: MarginContainer
var _speaker_label: Label
var _text_label: RichTextLabel
var _portrait_rect: ColorRect
var _advance_indicator: Label
var _skip_btn: Label

# ── Internal state ────────────────────────────────────────────────────────
var _is_visible: bool = false
var _is_typing: bool = false
var _advance_requested: bool = false
var _skip_typing: bool = false
var _blocked: bool = false
var _skip_all_requested: bool = false
var _pulse_tween: Tween = null
var _panel_tween: Tween = null
var _last_scene: Node = null
## Bumped by every say()/show_choices() and by force_reset(). A pending
## auto-hide only fires if no newer line started during its grace period.
var _line_seq: int = 0

# ── Dialogue history ──────────────────────────────────────────────────────
var dialogue_history: Array[Dictionary] = []
const MAX_HISTORY_SIZE: int = 100

# ── Choice state ──────────────────────────────────────────────────────────
var _choice_container: VBoxContainer = null
var _choice_result: int = -1
var _awaiting_choice: bool = false

# ── Configuration ─────────────────────────────────────────────────────────
var TYPE_SPEED: float = 35.0
const TYPE_FAST_SPEED: float = 120.0
const ADVANCE_INDICATOR_TEXT = "▼ [{jump}]"   # {action} tokens: InputService.fmt
const TAB_SKIP_THRESHOLD: float = 0.8
var _tab_hold_time: float = 0.0
## A dialogue sequence is considered finished when no new line or choice
## starts within this many seconds of the previous one returning. Consecutive
## `await say()` calls start in the same frame, so they never trip it.
const AUTO_HIDE_GRACE: float = 0.25

const SPEAKER_COLORS: Dictionary = {
	"Kaelen": Color(0.9, 0.95, 1.0),
	"Kaelen (Internal)": Color(0.7, 0.85, 0.95),
	"Kaelen (Internal Monologue)": Color(0.7, 0.85, 0.95),  # Alias for consistency
	"Elara": Color(0.8, 0.5, 1.0),
	"System": Color(0.0, 1.0, 1.0),
	"SYSTEM": Color(0.0, 1.0, 1.0),  # Uppercase alias used by ch3
	"Data Vision": Color(0.0, 1.0, 0.0),
	"Mira": Color(0.9, 0.6, 0.2),
	"Elder": Color(0.7, 0.7, 0.8),
	"Knight": Color(0.4, 0.4, 0.5),
	"Tutorial Knight": Color(0.7, 0.3, 0.3),
	"Corrupted Sentinel": Color(0.7, 0.3, 0.3),  # Same as Tutorial Knight
	"Aldric": Color(0.7, 0.5, 0.3),  # Redeemed knight — warm amber
	"Farmer Jenkins": Color(0.6, 0.8, 0.3),
	"Village Child": Color(1.0, 0.8, 0.5),
	"Village Guard": Color(0.5, 0.6, 0.7),
	"Shopkeeper": Color(0.8, 0.8, 0.5),
	"Stewardess": Color(0.9, 0.7, 0.8),
	"???": Color(0.6, 0.0, 0.8),
	"Seraphina": Color(0.95, 0.55, 0.55),
	"Gate Guard": Color(0.5, 0.5, 0.6),
	"Blacksmith Torval": Color(0.8, 0.5, 0.2),
	"Nyx": Color(0.6, 0.9, 0.8),
	"Pip": Color(1.0, 0.85, 0.4),
	"Null": Color(0.3, 0.3, 0.3),
	"Marcus": Color(0.6, 0.55, 0.5),
	"Vex": Color(1.0, 0.4, 0.6),
	"Crash": Color(1.0, 0.8, 0.0),
	"Data Wraith": Color(0.4, 0.0, 0.6),
	"Clockwork Automaton": Color(0.7, 0.6, 0.3),
	"Administrator Proxy": Color(1.0, 0.0, 0.0),
	"SOVEREIGN": Color(0.8, 0.0, 0.0),
	"Narrator": Color(0.6, 0.65, 0.7),  # Muted silver for narration
	"NARRATOR": Color(0.6, 0.65, 0.7),  # Legacy alias
	"Kaelthas": Color(0.9, 0.2, 0.1),  # Antagonist red
	"The Archivist": Color(0.5, 0.8, 0.9),  # Archive blue
	"Lyra": Color(0.3, 0.9, 0.4),  # Wastes green
	# Prologue + Chapter 1 rewrite (dialogue/prologue, dialogue/ch1)
	"Kaelen (Memory)": Color(0.75, 0.75, 0.85),
	"Flight Attendant": Color(0.95, 0.55, 0.55),  # Seraphina, unnamed — her colour
	"Voice": Color(0.9, 0.6, 0.2),  # Mira, unnamed — her colour
	"Passenger": Color(0.65, 0.65, 0.7),
	"Colleague": Color(0.65, 0.7, 0.8),
	"Bran": Color(0.6, 0.65, 0.5),
	"Mara": Color(0.95, 0.75, 0.45),
	"Old Fen": Color(0.7, 0.68, 0.6),
	"Jessa": Color(0.75, 0.6, 0.8),
	"Tull": Color(0.6, 0.75, 0.4),
	"Wenna": Color(0.7, 0.8, 0.45),
	"Child": Color(1.0, 0.8, 0.5),
	"Mother": Color(0.85, 0.75, 0.6),
	"Farmer": Color(0.6, 0.8, 0.3),
}


# ══════════════════════════════════════════════════════════════════════════
# LIFECYCLE
# ══════════════════════════════════════════════════════════════════════════

func _ready() -> void:
	process_mode = PROCESS_MODE_ALWAYS
	_build_ui()
	_hide_immediate()
	_last_scene = get_tree().current_scene


func _process(delta: float) -> void:
	var current_scene = get_tree().current_scene
	if _last_scene != null and current_scene != _last_scene:
		force_reset()
	_last_scene = current_scene
	# PERF: Skip remaining work when dialogue not visible
	if not _is_visible:
		return
	_process_skip(delta)


# ══════════════════════════════════════════════════════════════════════════
# PRIMARY API
# ══════════════════════════════════════════════════════════════════════════

## Display a single dialogue line with typewriter effect. Awaits player
## pressing SPACE (or auto-advances if auto_advance is true).
## The box closes itself once the sequence ends (see AUTO_HIDE_GRACE), so
## callers that never call hide_dialogue() no longer leave is_active stuck.
func say(speaker: String, text: String, color := Color(-1, -1, -1), auto_advance: bool = false) -> void:
	_line_seq += 1
	var seq := _line_seq
	await _say_line(speaker, text, color, auto_advance)
	_schedule_auto_hide(seq)


func _say_line(speaker: String, text: String, color: Color, auto_advance: bool) -> void:
	if _blocked:
		return
	# Respect subtitle_enabled setting — skip display but still record history
	if has_node("/root/GameManager") and not GameManager.get_accessibility("subtitle_enabled", true):
		dialogue_history.append({"speaker": speaker, "text": text, "timestamp": Time.get_ticks_msec()})
		if dialogue_history.size() > MAX_HISTORY_SIZE:
			dialogue_history.pop_front()
		return
	if color == Color(-1, -1, -1):
		# Respect subtitle_speaker_colors setting
		if has_node("/root/GameManager") and not GameManager.get_accessibility("subtitle_speaker_colors", true):
			color = Color(0.9, 0.9, 0.95)  # Uniform white for all speakers
		else:
			color = SPEAKER_COLORS.get(speaker, Color(0.8, 0.8, 0.9))
		if not SPEAKER_COLORS.has(speaker):
			push_warning("[DialogueManager] Unknown speaker '%s' — using default color. Add to SPEAKER_COLORS." % speaker)

	is_active = true
	if not _is_visible:
		_show_panel()
		dialogue_started.emit()

	# Speaker name — instant update, no animation
	_speaker_label.text = speaker
	_speaker_label.modulate = Color.WHITE
	_speaker_label.add_theme_color_override("font_color", color)

	_update_portrait(speaker, color)
	_bounce_portrait()

	_advance_indicator.visible = false
	_advance_indicator.modulate = Color.WHITE
	_skip_typing = false
	_advance_requested = false

	# ── Typewriter ──
	_is_typing = true
	var display_text = _apply_text_effects(InputService.fmt(text))  # {action} tokens -> button names
	_text_label.text = display_text
	_text_label.visible_characters = 0

	var total_chars = _text_label.get_total_character_count()
	var chars_shown = 0

	while chars_shown < total_chars:
		if _skip_typing or _skip_all_requested:
			break
		chars_shown += 1
		_text_label.visible_characters = chars_shown
		if chars_shown % 2 == 0 and has_node("/root/SFXManager"):
			SFXManager.play_random(["text_tick", "text_tick_low", "text_tick_high"])
		var delay = 1.0 / maxf(TYPE_SPEED, 1.0)
		if Input.is_action_pressed("ui_accept") or Input.is_action_pressed("jump"):
			delay = 1.0 / TYPE_FAST_SPEED
		await get_tree().create_timer(delay).timeout
		if not is_inside_tree():
			return

	_text_label.visible_characters = -1
	_is_typing = false

	dialogue_history.append({"speaker": speaker, "text": text, "timestamp": Time.get_ticks_msec()})
	if dialogue_history.size() > MAX_HISTORY_SIZE:
		dialogue_history.pop_front()

	if _skip_all_requested:
		return

	# ── Auto-advance mode ──
	if auto_advance:
		var read_time = clampf(text.length() * 0.035, 2.5, 8.0)
		_advance_indicator.text = InputService.fmt(ADVANCE_INDICATOR_TEXT)
		_advance_indicator.visible = true
		_advance_indicator.modulate = Color.WHITE

		var elapsed = 0.0
		while elapsed < read_time:
			if _skip_all_requested:
				break
			await get_tree().process_frame
			if not is_inside_tree():
				return
			elapsed += get_process_delta_time()
			if Input.is_action_just_pressed("ui_accept") or Input.is_action_just_pressed("jump"):
				break

		_advance_indicator.visible = false
		return

	# ── Wait for manual advance ──
	_advance_indicator.visible = true
	_advance_indicator.modulate = Color.WHITE
	_pulse_indicator()

	_advance_requested = false
	while not _advance_requested and not _skip_all_requested:
		await get_tree().process_frame
		if not is_inside_tree():
			return

	if has_node("/root/SFXManager"):
		SFXManager.play("dialogue_advance")
	_advance_indicator.visible = false
	_kill_pulse_tween()
	_advance_indicator.modulate = Color.WHITE
	dialogue_line_shown.emit()


## Close the box if no newer line or choice started during the grace period.
func _schedule_auto_hide(seq: int) -> void:
	if not is_inside_tree():
		return
	await get_tree().create_timer(AUTO_HIDE_GRACE).timeout
	if not is_inside_tree() or seq != _line_seq:
		return
	if _awaiting_choice or _is_typing or not is_active:
		return
	hide_dialogue()


## Hide the dialogue box and reset skip state.
func hide_dialogue() -> void:
	var was_active := is_active
	if _is_visible:
		_hide_panel()
	is_active = false
	_skip_all_requested = false
	if _skip_btn:
		_skip_btn.visible = false
	if was_active:
		dialogue_finished.emit()


## Skip the entire remaining dialogue sequence.
func skip_all() -> void:
	_skip_all_requested = true
	_skip_typing = true
	_advance_requested = true
	dialogue_skipped.emit()


## Returns true if the player requested a skip (used by scene scripts).
func is_skip_requested() -> bool:
	return _skip_all_requested


## Completely reset all dialogue state. Call before scene transitions.
func force_reset() -> void:
	_run_gen += 1  # stop any .dlg run still in progress
	_line_seq += 1  # Cancel any pending auto-hide from the previous scene
	_hide_immediate()
	is_active = false
	_is_typing = false
	_skip_typing = true
	_advance_requested = true
	_skip_all_requested = false
	_awaiting_choice = false
	_blocked = false
	_choice_result = -1
	current_dialogue.clear()
	current_index = 0
	_destroy_choice_buttons()


## Block all dialogue from showing.
func block() -> void:
	_blocked = true
	hide_dialogue()


## Unblock dialogue display.
func unblock() -> void:
	_blocked = false


# ══════════════════════════════════════════════════════════════════════════
# CHOICE SYSTEM
# ══════════════════════════════════════════════════════════════════════════

## Display a branching choice prompt. Returns the 0-based index selected.
func show_choices(prompt: String, choices: Array, speaker: String = "System") -> int:
	_line_seq += 1
	var seq := _line_seq
	var result: int = await _show_choices_impl(prompt, choices, speaker)
	_schedule_auto_hide(seq)
	return result


func _show_choices_impl(prompt: String, choices: Array, speaker: String) -> int:
	if _blocked:
		return 0
	if choices.is_empty():
		push_warning("[DIALOGUE] show_choices() called with empty choices")
		return 0

	is_active = true
	_awaiting_choice = true
	_choice_result = -1
	# Skipping fast-forwards text only. A skip in progress ends here, so the
	# player always sees and makes every choice (it used to auto-pick option 0).
	var was_skipping := _skip_all_requested
	_skip_all_requested = false

	if not _is_visible:
		_show_panel()

	var color: Color = SPEAKER_COLORS.get(speaker, Color(0.8, 0.8, 0.9))
	_speaker_label.text = speaker
	_speaker_label.add_theme_color_override("font_color", color)
	_update_portrait(speaker, color)

	# Typewriter the prompt
	_advance_indicator.visible = false
	_is_typing = true
	_skip_typing = was_skipping
	var display_prompt = _apply_text_effects(InputService.fmt(prompt))
	_text_label.text = display_prompt
	_text_label.visible_characters = 0

	var total_chars = _text_label.get_total_character_count()
	var chars_shown = 0
	while chars_shown < total_chars:
		if _skip_typing or _skip_all_requested:
			break
		chars_shown += 1
		_text_label.visible_characters = chars_shown
		if chars_shown % 2 == 0 and has_node("/root/SFXManager"):
			SFXManager.play_random(["text_tick", "text_tick_low", "text_tick_high"])
		var delay = 1.0 / maxf(TYPE_SPEED, 1.0)
		if Input.is_action_pressed("ui_accept") or Input.is_action_pressed("jump"):
			delay = 1.0 / TYPE_FAST_SPEED
		await get_tree().create_timer(delay).timeout
		if not is_inside_tree():
			return -1
	_text_label.visible_characters = -1
	_is_typing = false

	_build_choice_buttons(choices)

	# Wait for the player's selection. No timeout: story choices are permanent,
	# so an AFK player must never have one made for them.
	while _choice_result == -1:
		await get_tree().process_frame
		if not is_inside_tree() or not _awaiting_choice:
			return -1
		if _choice_container == null or not is_instance_valid(_choice_container):
			push_error("[DIALOGUE] Choice buttons vanished before a selection was made")
			break

	var result = _choice_result
	_destroy_choice_buttons()
	_awaiting_choice = false

	if result < 0 or result >= choices.size():
		push_warning("[DIALOGUE] Invalid choice index %d, defaulting to 0" % result)
		result = 0

	# Record the choice to dialogue history (was previously missing)
	dialogue_history.append({
		"speaker": speaker,
		"text": prompt,
		"choice": choices[result],
		"choice_index": result,
		"timestamp": Time.get_ticks_msec()
	})
	if dialogue_history.size() > MAX_HISTORY_SIZE:
		dialogue_history.pop_front()

	return result


# ══════════════════════════════════════════════════════════════════════════
# DIALOGUE FILES (.dlg) — story/DIALOGUE_FORMAT.md
# ══════════════════════════════════════════════════════════════════════════

const DialogueScriptRes := preload("res://scripts/dialogue/dialogue_script.gd")
const RUN_MAX_STEPS := 10000  # guards against "=> a" / "=> b" loops

## Play `node` of a .dlg file through say()/show_choices(), applying its
## `set` flags and `[if ...]` conditions. `on_event` receives each `do name`
## and is awaited, so a scene can run camera moves or effects mid-dialogue.
## Returns {"ok": bool, "choices": [{node, index, target}], "end_node": String}.
## A run belongs to the scene that started it: if that scene is left (or
## force_reset() is called), the run stops instead of carrying on into the
## next scene. A stopped run returns ok = false.
func run(file_path: String, node: String = "start", on_event: Callable = Callable()) -> Dictionary:
	var gen := _run_gen
	var scene: Node = get_tree().current_scene if is_inside_tree() else null
	var cancel := _cancel_run.bind(gen)
	# A run started from inside another run's event (same scene, same
	# generation) shares the outer run's hook.
	var owns_hook := scene != null and not scene.tree_exiting.is_connected(cancel)
	if owns_hook:
		scene.tree_exiting.connect(cancel, CONNECT_ONE_SHOT)
	var result: Dictionary = await _run_impl(file_path, node, on_event, gen)
	if owns_hook and is_instance_valid(scene) and scene.tree_exiting.is_connected(cancel):
		scene.tree_exiting.disconnect(cancel)
	return result


var _run_gen := 0   # bumped by force_reset(); runs from an older generation stop


func _cancel_run(gen: int) -> void:
	if gen == _run_gen:
		force_reset()


func _run_impl(file_path: String, node: String, on_event: Callable, gen: int) -> Dictionary:
	var script = DialogueScriptRes.load_file(file_path)
	var result := {"ok": false, "choices": [], "end_node": node}
	if not script.errors.is_empty():
		for e in script.errors:
			push_error("[Dialogue] " + e)
		return result
	if not script.nodes.has(node):
		push_error("[Dialogue] %s has no node '%s'" % [file_path, node])
		return result
	var current := node
	var index := 0
	var guard := 0
	while true:
		guard += 1
		if guard > RUN_MAX_STEPS:
			push_error("[Dialogue] %s: step limit reached (jump loop?) at node '%s'" % [file_path, current])
			return result
		var steps: Array = script.nodes[current]
		if index >= steps.size():
			break  # falling off the end of a node ends the dialogue
		var step: Dictionary = steps[index]
		index += 1
		if not _conditions_met(step["cond"]):
			continue
		match step["type"]:
			"line":
				await say(step["speaker"], step["text"])
				if not is_inside_tree() or gen != _run_gen:
					return result
			"set":
				if has_node("/root/GameManager"):
					GameManager.set_story_flag(step["flag"], step["value"])
			"do":
				if await _run_builtin_event(step["event"], file_path):
					if not is_inside_tree() or gen != _run_gen:
						return result
				elif on_event.is_valid():
					await on_event.call(step["event"])
					if not is_inside_tree() or gen != _run_gen:
						return result
				else:
					push_warning("[Dialogue] %s: 'do %s' but no on_event handler" % [file_path, step["event"]])
			"jump":
				if step["target"] == DialogueScriptRes.END:
					break
				current = step["target"]
				index = 0
			"choice":
				var visible: Array = []
				for opt in step["options"]:
					if _conditions_met(opt["cond"]):
						visible.append(opt)
				if visible.is_empty():
					continue
				var prompt: Variant = step["prompt"]
				var texts: Array = visible.map(func(o): return o["text"])
				var picked: int = await show_choices(
					prompt["text"] if prompt != null else "",
					texts,
					prompt["speaker"] if prompt != null else "Kaelen")
				if picked < 0 or not is_inside_tree() or gen != _run_gen:
					return result  # scene changed while the choice was open
				var chosen: Dictionary = visible[picked]
				result["choices"].append({"node": current, "index": picked, "target": chosen["target"]})
				if chosen["target"] == DialogueScriptRes.END:
					break
				current = chosen["target"]
				index = 0
	result["ok"] = true
	result["end_node"] = current
	return result


## Relationship value at which "<name>_trust_high" turns on (same units as
## GameManager.relationships, where a big story choice is worth 10–25).
const TRUST_HIGH := 30

## `do` events every .dlg can use without the scene handling them:
##   do trust <companion> <delta>   change GameManager.relationships[companion],
##                                  and keep the flag <companion>_trust_high in step
##   do pause <seconds>             a beat of silence (0–10 s)
## Returns true if the event was one of these.
func _run_builtin_event(event: String, file_path: String) -> bool:
	var parts := event.split(" ", false)
	if parts.is_empty():
		return false
	match parts[0]:
		"trust":
			if parts.size() != 3 or not parts[2].is_valid_int():
				push_warning("[Dialogue] %s: expected 'do trust <companion> <delta>', got 'do %s'" % [file_path, event])
				return true
			if has_node("/root/GameManager"):
				var who := parts[1]
				var value: int = int(GameManager.relationships.get(who, 0)) + int(parts[2])
				GameManager.relationships[who] = value
				GameManager.set_story_flag("%s_trust_high" % who, value >= TRUST_HIGH)
			return true
		"pause":
			var seconds := 1.0
			if parts.size() > 1 and parts[1].is_valid_float():
				seconds = clampf(float(parts[1]), 0.0, 10.0)
			await get_tree().create_timer(seconds).timeout
			return true
	return false


func _conditions_met(cond: Array) -> bool:
	for term in cond:
		var value: bool
		if term["flag"] == "has_elara":
			value = has_node("/root/GameManager") and GameManager.has_elara()
		else:
			value = has_node("/root/GameManager") and GameManager.has_flag(term["flag"])
		if value == term["negate"]:
			return false
	return true


func _build_choice_buttons(choices: Array) -> void:
	_destroy_choice_buttons()

	_choice_container = VBoxContainer.new()
	_choice_container.name = "ChoiceContainer"
	_choice_container.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	_choice_container.offset_top = -340
	_choice_container.offset_bottom = -200
	_choice_container.offset_left = 80
	_choice_container.offset_right = -80
	_choice_container.add_theme_constant_override("separation", 8)
	_ui_layer.add_child(_choice_container)

	var header = Label.new()
	header.text = "  CHOOSE YOUR PATH  "
	header.add_theme_color_override("font_color", Color(1.0, 0.85, 0.2))
	header.add_theme_font_size_override("font_size", 14)
	header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_choice_container.add_child(header)

	var buttons: Array[Button] = []
	for i in range(choices.size()):
		var btn = _create_choice_button(choices[i], i)
		_choice_container.add_child(btn)
		buttons.append(btn)

	# Fade in
	_choice_container.modulate.a = 0.0
	var tween = create_tween()
	tween.tween_property(_choice_container, "modulate:a", 1.0, 0.3)

	# Grace period: prevent stale Space from auto-confirming
	await get_tree().create_timer(0.5).timeout
	if not is_inside_tree():
		return
	while is_inside_tree() and (Input.is_action_pressed("ui_accept") or Input.is_action_pressed("jump")):
		await get_tree().process_frame
	if not is_inside_tree():
		return
	for btn in buttons:
		if is_instance_valid(btn):
			btn.focus_mode = Control.FOCUS_ALL
	if not buttons.is_empty() and is_instance_valid(buttons[0]):
		buttons[0].grab_focus()


func _create_choice_button(text: String, index: int) -> Button:
	var btn = Button.new()
	btn.text = "  %s  " % InputService.fmt(text)
	btn.custom_minimum_size = Vector2(0, 48)
	btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn.focus_mode = Control.FOCUS_NONE  # enabled after grace period

	var normal_style = StyleBoxFlat.new()
	normal_style.bg_color = Color(0.06, 0.06, 0.15, 0.95)
	normal_style.border_color = Color(0.0, 0.6, 0.9, 0.6)
	normal_style.set_border_width_all(2)
	normal_style.set_corner_radius_all(4)
	normal_style.content_margin_left = 16
	normal_style.content_margin_right = 16
	normal_style.content_margin_top = 8
	normal_style.content_margin_bottom = 8
	btn.add_theme_stylebox_override("normal", normal_style)

	var hover_style = normal_style.duplicate() as StyleBoxFlat
	hover_style.bg_color = Color(0.1, 0.1, 0.25, 0.98)
	hover_style.border_color = Color(0.0, 0.85, 1.0, 1.0)
	btn.add_theme_stylebox_override("hover", hover_style)

	var pressed_style = normal_style.duplicate() as StyleBoxFlat
	pressed_style.bg_color = Color(0.15, 0.15, 0.35, 1.0)
	pressed_style.border_color = Color(1.0, 0.85, 0.0, 1.0)
	btn.add_theme_stylebox_override("pressed", pressed_style)

	var focus_style = normal_style.duplicate() as StyleBoxFlat
	focus_style.bg_color = Color(0.08, 0.08, 0.22, 0.98)
	focus_style.border_color = Color(0.0, 0.85, 1.0, 1.0)
	focus_style.set_border_width_all(3)
	btn.add_theme_stylebox_override("focus", focus_style)

	btn.add_theme_color_override("font_color", Color(0.85, 0.9, 1.0))
	btn.add_theme_color_override("font_hover_color", Color(1.0, 1.0, 1.0))
	btn.add_theme_color_override("font_pressed_color", Color(1.0, 0.9, 0.4))
	btn.add_theme_font_size_override("font_size", 16)

	btn.pressed.connect(_on_choice_pressed.bind(index))
	return btn


func _on_choice_pressed(index: int) -> void:
	if _choice_result != -1:
		return  # Prevent double-selection race condition
	_choice_result = index
	choice_selected.emit(index)
	if has_node("/root/SFXManager"):
		SFXManager.play("ui_confirm")


func _destroy_choice_buttons() -> void:
	if _choice_container and is_instance_valid(_choice_container):
		_choice_container.queue_free()
		_choice_container = null


# ══════════════════════════════════════════════════════════════════════════
# LEGACY API — for backward compatibility
# ══════════════════════════════════════════════════════════════════════════

func start_dialogue(dialogue_data: Array) -> void:
	current_dialogue = dialogue_data
	current_index = 0
	is_active = true
	dialogue_started.emit()

func get_current_line() -> Dictionary:
	if current_index < current_dialogue.size():
		return current_dialogue[current_index]
	return {}

func advance() -> void:
	current_index += 1
	if current_index >= current_dialogue.size():
		end_dialogue()

func end_dialogue() -> void:
	is_active = false
	current_dialogue = []
	current_index = 0
	hide_dialogue()
	dialogue_finished.emit()

func select_choice(choice_index: int) -> void:
	choice_selected.emit(choice_index)
	advance()


# ══════════════════════════════════════════════════════════════════════════
# INPUT
# ══════════════════════════════════════════════════════════════════════════

func _process_skip(delta: float) -> void:
	# Skipping never applies to an open choice.
	if not _is_visible or _awaiting_choice:
		_tab_hold_time = 0.0
		return

	if Input.is_action_pressed("skip"):
		_tab_hold_time += delta
		if _skip_btn:
			var progress = clampf(_tab_hold_time / TAB_SKIP_THRESHOLD, 0.0, 1.0)
			var filled = int(progress * 5)
			_skip_btn.text = InputService.fmt("[Hold {skip} to skip %s]") % ("█".repeat(filled) + "░".repeat(5 - filled))
			_skip_btn.add_theme_color_override("font_color",
				Color(0.4 + progress * 0.6, 0.4, 0.5 - progress * 0.3, 0.6 + progress * 0.4))
		if _tab_hold_time >= TAB_SKIP_THRESHOLD:
			skip_all()
			_tab_hold_time = 0.0
	else:
		_tab_hold_time = 0.0
		if _skip_btn and _skip_btn.visible:
			_skip_btn.text = InputService.fmt("[Hold {skip} to skip]")
			_skip_btn.add_theme_color_override("font_color", Color(0.4, 0.4, 0.5, 0.6))


func _input(event: InputEvent) -> void:
	if not _is_visible:
		return

	# Don't process dialogue input while the tree is paused (e.g. pause menu open)
	if get_tree().paused:
		return

	# While choices are shown, block Space/Jump to prevent accidental selection.
	# Pad A is both jump and ui_accept: let it through so the focused choice
	# button can take it.
	if _awaiting_choice:
		if event.is_action_pressed("jump") and not event.is_action_pressed("ui_accept"):
			get_viewport().set_input_as_handled()
			return
		return

	# ESC: first press completes current line typing, second press skips all
	if event.is_action_pressed("ui_cancel"):
		if _is_typing:
			_skip_typing = true  # Complete current line
		else:
			skip_all()  # Skip entire sequence
		get_viewport().set_input_as_handled()
		return

	if event.is_action_pressed("ui_accept") or event.is_action_pressed("jump"):
		if _is_typing:
			_skip_typing = true
		else:
			_advance_requested = true
		get_viewport().set_input_as_handled()


# ══════════════════════════════════════════════════════════════════════════
# UI CONSTRUCTION
# ══════════════════════════════════════════════════════════════════════════

func _build_ui() -> void:
	_ui_layer = CanvasLayer.new()
	_ui_layer.layer = 100
	_ui_layer.name = "DialogueUILayer"
	add_child(_ui_layer)

	# Bottom-of-screen margin
	_margin = MarginContainer.new()
	_margin.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	_margin.offset_top = -190
	_margin.offset_bottom = -8
	_margin.offset_left = 30
	_margin.offset_right = -30
	_margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ui_layer.add_child(_margin)

	# Dark panel
	_panel = PanelContainer.new()
	_panel.name = "DialoguePanel"
	_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.03, 0.03, 0.08, 1.0)
	style.border_color = Color(0.0, 0.7, 1.0, 0.5)
	style.set_border_width_all(2)
	style.set_corner_radius_all(6)
	style.content_margin_left = 18
	style.content_margin_right = 18
	style.content_margin_top = 12
	style.content_margin_bottom = 12
	_panel.add_theme_stylebox_override("panel", style)
	_margin.add_child(_panel)

	var hbox = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 16)
	hbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_panel.add_child(hbox)

	# Portrait placeholder
	_portrait_rect = ColorRect.new()
	_portrait_rect.custom_minimum_size = Vector2(72, 72)
	_portrait_rect.color = Color(0.3, 0.3, 0.4)
	_portrait_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hbox.add_child(_portrait_rect)

	# Text area
	var vbox = VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hbox.add_child(vbox)

	_speaker_label = Label.new()
	_speaker_label.add_theme_color_override("font_color", Color(0.0, 0.9, 1.0))
	var _txt_scale: float = 1.0
	if has_node("/root/GameManager"):
		_txt_scale = GameManager.get_text_size_scale()
	_speaker_label.add_theme_font_size_override("font_size", int(18 * _txt_scale))
	_speaker_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(_speaker_label)

	_text_label = RichTextLabel.new()
	_text_label.bbcode_enabled = true
	_text_label.fit_content = true
	_text_label.scroll_active = false
	_text_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_text_label.add_theme_color_override("default_color", Color(0.88, 0.88, 0.92))
	var _subtitle_px: int = int(15 * _txt_scale)
	if has_node("/root/GameManager"):
		_subtitle_px = int(GameManager.get_subtitle_size_px() * _txt_scale)
	_text_label.add_theme_font_size_override("normal_font_size", _subtitle_px)
	_text_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(_text_label)

	_advance_indicator = Label.new()
	_advance_indicator.text = InputService.fmt(ADVANCE_INDICATOR_TEXT)
	_advance_indicator.add_theme_color_override("font_color", Color(0.45, 0.45, 0.55))
	_advance_indicator.add_theme_font_size_override("font_size", int(12 * _txt_scale))
	_advance_indicator.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_advance_indicator.visible = false
	_advance_indicator.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(_advance_indicator)

	# Skip hint — top-right corner
	_skip_btn = Label.new()
	_skip_btn.text = InputService.fmt("[Hold {skip} to skip]")
	_skip_btn.add_theme_color_override("font_color", Color(0.4, 0.4, 0.5, 0.6))
	_skip_btn.add_theme_font_size_override("font_size", 11)
	_skip_btn.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	_skip_btn.offset_left = -180
	_skip_btn.offset_top = 8
	_skip_btn.offset_right = -12
	_skip_btn.visible = false
	_skip_btn.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ui_layer.add_child(_skip_btn)


# ══════════════════════════════════════════════════════════════════════════
# UI ANIMATION HELPERS
# ══════════════════════════════════════════════════════════════════════════

func _hide_immediate() -> void:
	_kill_all_tweens()
	if _panel:
		_panel.modulate.a = 0.0
	_is_visible = false
	_awaiting_choice = false
	_blocked = false
	_destroy_choice_buttons()
	if _skip_btn:
		_skip_btn.visible = false


func _show_panel() -> void:
	_is_visible = true
	_skip_all_requested = false
	_kill_all_tweens()
	# Pass 53: Play dialogue open SFX
	if has_node("/root/SFXManager"):
		SFXManager.play("ui_open")
	if _panel:
		_panel.modulate.a = 0.0
		_panel.scale = Vector2(1.0, 0.85)
		_panel_tween = create_tween()
		_panel_tween.set_parallel(true)
		_panel_tween.tween_property(_panel, "modulate:a", 1.0, 0.2) \
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		_panel_tween.tween_property(_panel, "scale", Vector2(1.0, 1.0), 0.25) \
			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	if _skip_btn:
		_skip_btn.visible = true


func _hide_panel() -> void:
	_is_visible = false
	_kill_all_tweens()
	# Pass 53: Play dialogue close SFX
	if has_node("/root/SFXManager"):
		SFXManager.play("ui_close")
	if _skip_btn:
		_skip_btn.visible = false
	if _panel:
		_panel_tween = create_tween()
		_panel_tween.set_parallel(true)
		_panel_tween.tween_property(_panel, "modulate:a", 0.0, 0.18) \
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
		_panel_tween.tween_property(_panel, "scale:y", 0.9, 0.18) \
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)


func _bounce_portrait() -> void:
	if not _portrait_rect:
		return
	_portrait_rect.scale = Vector2(0.8, 0.8)
	_portrait_rect.modulate.a = 0.7
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(_portrait_rect, "scale", Vector2(1.0, 1.0), 0.25) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(_portrait_rect, "modulate:a", 1.0, 0.15) \
		.set_trans(Tween.TRANS_SINE)


func _update_portrait(speaker: String, color: Color) -> void:
	if not _portrait_rect:
		return

	var tex: Texture2D = null
	if has_node("/root/AssetManager"):
		tex = AssetManager.get_portrait_texture(speaker)

	if tex:
		var existing_tex = _portrait_rect.get_node_or_null("PortraitTexture") as TextureRect
		if existing_tex:
			existing_tex.texture = tex
		else:
			var tex_rect = TextureRect.new()
			tex_rect.name = "PortraitTexture"
			tex_rect.texture = tex
			tex_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
			tex_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			tex_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			tex_rect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			tex_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
			_portrait_rect.add_child(tex_rect)
		var old_initial = _portrait_rect.get_node_or_null("PortraitInitial")
		if old_initial:
			old_initial.queue_free()
		_portrait_rect.color = Color(0, 0, 0, 0)
	else:
		# Try Kenney alien character sprite as portrait fallback
		var kenney_tex: Texture2D = null
		if has_node("/root/AssetManager"):
			var kenney_color := "beige"
			if speaker in AssetManager.CHARACTER_KENNEY_FALLBACK:
				kenney_color = AssetManager.CHARACTER_KENNEY_FALLBACK[speaker]
			else:
				# Deterministic color from name hash
				var colors = ["blue", "green", "pink", "yellow", "beige"]
				kenney_color = colors[speaker.hash() % colors.size()]
			var kenney_key = "kenney_char_" + kenney_color
			if AssetManager.is_asset_available(kenney_key):
				kenney_tex = AssetManager.get_sprite(kenney_key)
		
		if kenney_tex:
			var existing_tex = _portrait_rect.get_node_or_null("PortraitTexture") as TextureRect
			if existing_tex:
				existing_tex.texture = kenney_tex
			else:
				var tex_rect = TextureRect.new()
				tex_rect.name = "PortraitTexture"
				tex_rect.texture = kenney_tex
				tex_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
				tex_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
				tex_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
				tex_rect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
				tex_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
				_portrait_rect.add_child(tex_rect)
			_portrait_rect.color = color.darkened(0.6)
			var old_initial = _portrait_rect.get_node_or_null("PortraitInitial")
			if old_initial:
				old_initial.queue_free()
		else:
			_portrait_rect.color = color.darkened(0.4)
			var existing_tex = _portrait_rect.get_node_or_null("PortraitTexture")
			if existing_tex:
				existing_tex.queue_free()
			var initial = _portrait_rect.get_node_or_null("PortraitInitial") as Label
			if not initial:
				initial = Label.new()
				initial.name = "PortraitInitial"
				initial.add_theme_font_size_override("font_size", 26)
				initial.add_theme_color_override("font_color", Color(1, 1, 1, 0.6))
				initial.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
				initial.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
				initial.set_anchors_preset(Control.PRESET_FULL_RECT)
				initial.mouse_filter = Control.MOUSE_FILTER_IGNORE
				_portrait_rect.add_child(initial)
			initial.text = speaker.substr(0, 1).to_upper() if speaker != "???" else "?"


func _pulse_indicator() -> void:
	if not _advance_indicator or not _advance_indicator.visible:
		return
	_kill_pulse_tween()
	_pulse_tween = create_tween().set_loops()
	_pulse_tween.tween_property(_advance_indicator, "modulate:a", 0.3, 0.45)
	_pulse_tween.tween_property(_advance_indicator, "modulate:a", 1.0, 0.45)


func _kill_pulse_tween() -> void:
	if _pulse_tween and _pulse_tween.is_valid():
		_pulse_tween.kill()
		_pulse_tween = null


func _kill_all_tweens() -> void:
	_kill_pulse_tween()
	if _panel_tween and _panel_tween.is_valid():
		_panel_tween.kill()
		_panel_tween = null


# ══════════════════════════════════════════════════════════════════════════
# TEXT EFFECTS — custom shorthand tags → BBCode
# ══════════════════════════════════════════════════════════════════════════

func _apply_text_effects(text: String) -> String:
	var result = text
	result = result.replace("[wave]", "[wave amp=30 freq=6.0 connected=1]")
	result = result.replace("[shake]", "[shake rate=12.0 level=6 connected=1]")
	result = result.replace("[rainbow]", "[rainbow freq=0.5 sat=0.7 val=0.95]")
	result = result.replace("[glitch]", "[shake rate=30.0 level=10 connected=1]")
	result = result.replace("[pulse]", "[wave amp=15 freq=2.0 connected=1]")
	result = result.replace("[/glitch]", "[/shake]")
	result = result.replace("[/pulse]", "[/wave]")
	return result


# ══════════════════════════════════════════════════════════════════════════
# DIALOGUE HISTORY
# ══════════════════════════════════════════════════════════════════════════

func get_dialogue_history() -> Array[Dictionary]:
	return dialogue_history

func clear_dialogue_history() -> void:
	dialogue_history.clear()
