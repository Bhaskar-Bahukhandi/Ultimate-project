extends Control

## Chapter 3: The Source Code
## Sequence 3: The Data Stream — On-Rails Action Segment
## Genre shift: auto-scrolling dodge/collect game. Root Access disabled.
## Elara becomes the primary navigator.

# ─── Constants ────────────────────────────────────────────────────────
const LANE_COUNT: int = 3
const LANE_Y: Array = [300, 420, 540]  # Top, Middle, Bottom lane Y positions
const SCROLL_SPEED: float = 200.0
const OBSTACLE_INTERVAL: float = 1.2
const DATA_FRAGMENT_INTERVAL: float = 0.8
const SEGMENT_DURATION: float = 45.0  # Total ride time in seconds

# ─── State ────────────────────────────────────────────────────────────
var current_lane: int = 1  # 0=top, 1=mid, 2=bottom
var elapsed_time: float = 0.0
var score: int = 0
var hits_taken: int = 0
var rider_node: ColorRect
var lane_switch_cooldown: float = 0.0
var obstacles: Array = []
var data_fragments: Array = []
var spawn_timer_obstacle: float = 0.0
var spawn_timer_data: float = 0.0
var stream_active: bool = false
var intro_done: bool = false
var fade_rect: ColorRect
var score_label: Label
var stream_bg: ColorRect
var _scroll_lines: Array = []

func _ready() -> void:
	print("[CH3-STREAM] Initializing Data Stream")
	GameManager.change_state(GameManager.GameState.DIALOGUE)
	GameManager.set_story_flag("ch3_data_stream_entered", true)
	GameManager.current_chapter = 3

	if has_node("/root/MusicManager"):
		MusicManager.play_track("data_stream")  # Pass 53: Use dedicated track

	_build_visuals()

	# Fade in
	fade_rect.modulate = Color(1, 1, 1, 1)
	var tween = create_tween()
	tween.tween_property(fade_rect, "modulate:a", 0.0, 1.0)
	await tween.finished
	if not is_inside_tree(): return

	await _intro_dialogue()
	if not is_inside_tree(): return

func _build_visuals() -> void:
	# Dark blue streaming background
	stream_bg = ColorRect.new()
	stream_bg.color = Color(0.02, 0.04, 0.12)
	stream_bg.anchors_preset = Control.PRESET_FULL_RECT
	stream_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(stream_bg)

	# Scrolling data lines (cosmetic)
	for i in range(20):
		var line = ColorRect.new()
		line.size = Vector2(randf_range(60, 200), 1)
		line.position = Vector2(randf_range(0, 1280), randf_range(0, 720))
		line.color = Color(0.1, 0.3, 0.7, randf_range(0.1, 0.3))
		line.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(line)
		_scroll_lines.append(line)

	# Lane dividers
	for y_pos in LANE_Y:
		var divider = ColorRect.new()
		divider.size = Vector2(1280, 1)
		divider.position = Vector2(0, y_pos - 50)
		divider.color = Color(0.15, 0.25, 0.5, 0.3)
		divider.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(divider)

	# Player rider
	rider_node = ColorRect.new()
	rider_node.size = Vector2(30, 40)
	rider_node.color = Color(0.3, 0.8, 1.0)
	rider_node.position = Vector2(150, LANE_Y[current_lane] - 20)
	rider_node.z_index = 10
	rider_node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(rider_node)

	# Score display
	score_label = Label.new()
	score_label.text = "DATA: 0  |  TIME: 0s"
	score_label.add_theme_font_size_override("font_size", 18)
	score_label.add_theme_color_override("font_color", Color(0.5, 0.8, 1.0))
	score_label.position = Vector2(20, 20)
	score_label.z_index = 40
	add_child(score_label)

	# Fade rect
	fade_rect = ColorRect.new()
	fade_rect.color = Color.BLACK
	fade_rect.anchors_preset = Control.PRESET_FULL_RECT
	fade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fade_rect.z_index = 50
	add_child(fade_rect)

func _intro_dialogue() -> void:
	await _show_dialogue("NARRATOR", "The Data Stream stretches before them — a river of raw information flowing between Aethelgard's regions. Glowing characters cascade through the current: numbers, symbols, fragments of code.")

	await _show_dialogue("SYSTEM", "// WARNING: Data Stream environment detected. Root Access DISABLED. Code velocity exceeds read/write threshold.")

	await _show_dialogue("Kaelen", "My Root Access... I can't read the code. It's moving too fast, like trying to read a book thrown off a building.")

	if _has_elara():
		await _show_dialogue("Elara", "But I can FEEL it. The data... it's speaking to me. The fragment amplified my connection. Let me guide us.")
		await _show_dialogue("NARRATOR", "Elara's eyes glow with cascading blue light. Her glitched arm extends, fingers tracing patterns in the flowing data. For the first time, SHE is the one with power here.")
		await _show_dialogue("Elara", "Hold on to something. I'm going to ride the stream.")
	else:
		await _show_dialogue("Kaelen (Internal)", "No Root Access. No companion. Just raw data moving faster than thought. The engineer in me wants to analyze it — but the only way through is to ride it blind.")
		await _show_dialogue("Kaelen", "If I can't READ the data, I'll just have to feel where it's going. Here goes nothing.")

	if _has_flag("ch3_lyra_recruited"):
		await _show_dialogue("Lyra", "This is what the world looks like under the skin. It's... terrifying. And beautiful. Mostly terrifying.")

	await _show_dialogue("SYSTEM", "// Dodge RED data packets (corruption). Collect BLUE fragments (data).")
	await _show_dialogue("SYSTEM", "// Controls: UP/DOWN to change lanes. The stream carries you forward automatically.")

	# Start the on-rails segment
	stream_active = true
	intro_done = true
	GameManager.change_state(GameManager.GameState.EXPLORATION)

func _process(delta) -> void:
	if not stream_active or not intro_done:
		return

	elapsed_time += delta
	lane_switch_cooldown = max(lane_switch_cooldown - delta, 0.0)

	# Scroll cosmetic lines
	for line in _scroll_lines:
		if is_instance_valid(line):
			line.position.x -= SCROLL_SPEED * 0.5 * delta
			if line.position.x < -250:
				line.position.x = 1300 + randf_range(0, 200)
				line.position.y = randf_range(0, 720)

	# Spawn obstacles and data
	spawn_timer_obstacle -= delta
	spawn_timer_data -= delta

	if spawn_timer_obstacle <= 0:
		spawn_timer_obstacle = OBSTACLE_INTERVAL * randf_range(0.7, 1.3)
		_spawn_obstacle()

	if spawn_timer_data <= 0:
		spawn_timer_data = DATA_FRAGMENT_INTERVAL * randf_range(0.8, 1.2)
		_spawn_data_fragment()

	# Move obstacles and fragments
	_update_objects(delta)

	# Collision detection
	_check_collisions()

	# Update HUD
	if is_instance_valid(score_label):
		score_label.text = "DATA: %d  |  TIME: %ds  |  HITS: %d" % [score, int(elapsed_time), hits_taken]

	# Move rider to target lane smoothly
	if is_instance_valid(rider_node):
		var target_y := float(LANE_Y[current_lane] - 20)
		# lerpf: lerp() rejects mixing the int lane Y with the float position, and
		# the resulting script error aborted _process before the segment-end check,
		# so the ride could never complete.
		rider_node.position.y = lerpf(rider_node.position.y, target_y, delta * 15.0)

	# Segment end
	if elapsed_time >= SEGMENT_DURATION:
		stream_active = false
		_complete_stream()

func _input(event) -> void:
	if not stream_active:
		if event.is_action_pressed("ui_cancel") and has_node("/root/PauseScreen"):
			PauseScreen.toggle_pause()
		return

	if lane_switch_cooldown > 0:
		return

	if event.is_action_pressed("ui_up") or event.is_action_pressed("jump"):
		if current_lane > 0:
			current_lane -= 1
			lane_switch_cooldown = 0.15
			if has_node("/root/SFXManager"):
				SFXManager.play("ui_hover")
	elif event.is_action_pressed("ui_down") or event.is_action_pressed("crouch"):
		if current_lane < LANE_COUNT - 1:
			current_lane += 1
			lane_switch_cooldown = 0.15
			if has_node("/root/SFXManager"):
				SFXManager.play("ui_hover")

func _spawn_obstacle() -> void:
	var lane = randi() % LANE_COUNT
	var obs = ColorRect.new()
	obs.size = Vector2(25, 35)
	obs.color = Color(1.0, 0.2, 0.2, 0.9)
	obs.position = Vector2(1320, LANE_Y[lane] - 17)
	obs.z_index = 5
	obs.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(obs)
	obstacles.append({"node": obs, "lane": lane})

func _spawn_data_fragment() -> void:
	var lane = randi() % LANE_COUNT
	# Don't spawn in same lane as recent obstacle
	var frag = ColorRect.new()
	frag.size = Vector2(15, 15)
	frag.color = Color(0.3, 0.7, 1.0, 0.9)
	frag.position = Vector2(1320, LANE_Y[lane] - 7)
	frag.z_index = 5
	frag.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(frag)
	data_fragments.append({"node": frag, "lane": lane})

func _update_objects(delta) -> void:
	# Move obstacles
	var obs_to_remove: Array = []
	for i in range(obstacles.size()):
		var obs = obstacles[i]
		if is_instance_valid(obs["node"]):
			obs["node"].position.x -= SCROLL_SPEED * delta
			if obs["node"].position.x < -50:
				obs["node"].queue_free()
				obs_to_remove.append(i)
	for i in range(obs_to_remove.size() - 1, -1, -1):
		obstacles.remove_at(obs_to_remove[i])

	# Move data fragments
	var frag_to_remove: Array = []
	for i in range(data_fragments.size()):
		var frag = data_fragments[i]
		if is_instance_valid(frag["node"]):
			frag["node"].position.x -= SCROLL_SPEED * delta
			if frag["node"].position.x < -50:
				frag["node"].queue_free()
				frag_to_remove.append(i)
	for i in range(frag_to_remove.size() - 1, -1, -1):
		data_fragments.remove_at(frag_to_remove[i])

func _check_collisions() -> void:
	if not is_instance_valid(rider_node):
		return

	var rider_rect = Rect2(rider_node.position, rider_node.size)

	# Check obstacles
	var obs_hit: Array = []
	for i in range(obstacles.size()):
		var obs = obstacles[i]
		if not is_instance_valid(obs["node"]):
			continue
		var obs_rect = Rect2(obs["node"].position, obs["node"].size)
		if rider_rect.intersects(obs_rect):
			obs_hit.append(i)
			_on_obstacle_hit()

	for i in range(obs_hit.size() - 1, -1, -1):
		if is_instance_valid(obstacles[obs_hit[i]]["node"]):
			obstacles[obs_hit[i]]["node"].queue_free()
		obstacles.remove_at(obs_hit[i])

	# Check data fragments
	var frag_hit: Array = []
	for i in range(data_fragments.size()):
		var frag = data_fragments[i]
		if not is_instance_valid(frag["node"]):
			continue
		var frag_rect = Rect2(frag["node"].position, frag["node"].size)
		if rider_rect.intersects(frag_rect):
			frag_hit.append(i)
			_on_data_collected()

	for i in range(frag_hit.size() - 1, -1, -1):
		if is_instance_valid(data_fragments[frag_hit[i]]["node"]):
			data_fragments[frag_hit[i]]["node"].queue_free()
		data_fragments.remove_at(frag_hit[i])

func _on_obstacle_hit() -> void:
	hits_taken += 1
	GameManager.player_stats["hp"] = max(int(GameManager.player_stats.get("hp", 100) - 8), 1)

	if has_node("/root/SFXManager"):
		SFXManager.play("player_hurt")
	if has_node("/root/GlitchOverlay"):
		GlitchOverlay.flash_glitch(0.15)

	# Flash rider red briefly
	if is_instance_valid(rider_node):
		rider_node.color = Color(1.0, 0.3, 0.3)
		var tw = create_tween()
		tw.tween_property(rider_node, "color", Color(0.3, 0.8, 1.0), 0.3)

	# BUG-21-15: Guard autoload call
	if has_node("/root/CombatFX"):
		CombatFX.apply_screen_shake(6.0, 0.15)

func _on_data_collected() -> void:
	score += 1

	if has_node("/root/SFXManager"):
		SFXManager.play("item_pickup")

	# Brief flash on rider
	if is_instance_valid(rider_node):
		rider_node.color = Color(0.8, 1.0, 1.0)
		var tw = create_tween()
		tw.tween_property(rider_node, "color", Color(0.3, 0.8, 1.0), 0.2)

	# Every 10 data fragments = small XP reward
	if score % 10 == 0:
		GameManager.add_xp(15)
		if has_node("/root/VFXLibrary"):
			VFXLibrary.spawn_status_indicator("+15 XP", Vector2(640, 350), self, false)

func _complete_stream() -> void:
	GameManager.change_state(GameManager.GameState.DIALOGUE)
	GameManager.set_story_flag("ch3_data_stream_complete", true)

	# Clean up remaining objects
	for obs in obstacles:
		if is_instance_valid(obs["node"]):
			obs["node"].queue_free()
	obstacles.clear()
	for frag in data_fragments:
		if is_instance_valid(frag["node"]):
			frag["node"].queue_free()
	data_fragments.clear()

	await get_tree().create_timer(0.5).timeout
	if not is_inside_tree(): return

	# Score rewards
	var xp_reward = score * 3
	var gold_reward = score * 2
	GameManager.add_xp(xp_reward)
	GameManager.add_gold(gold_reward)

	# Post-stream dialogue
	await _show_dialogue("SYSTEM", "// Data Stream traversal complete. Data collected: %d. Damage taken: %d." % [score, hits_taken])
	await _show_dialogue("NARRATOR", "The stream slows, depositing the party at the edge of an impossible structure — a building that stretches into recursive infinity.")

	await _show_dialogue("Kaelen", "That was... there was a moment I felt what Elara feels. The code underneath everything, flowing like water.")

	if _has_elara():
		await _show_dialogue("Elara", "Now you understand. The world isn't MADE of code, Kaelen. The world IS code. And so are we.")
		await _show_dialogue("NARRATOR", "Elara's eyes still glow faintly from the data stream immersion. Her connection to Aethelgard's infrastructure has deepened — permanently.")

	# Discovery about SOVEREIGN
	await _show_dialogue("Kaelen", "I noticed something in the stream. Every piece of data was tagged... monitored. Everything flows through the stream and SOVEREIGN SEES ALL OF IT.")
	await _show_dialogue("Kaelen", "The Data Stream isn't just a river. It's SOVEREIGN's nervous system — its eyes and ears across every region.")

	if _has_flag("ch3_lyra_recruited"):
		await _show_dialogue("Lyra", "So we just swam through a god's brain. Cool. Normal. Totally fine.")

	await _show_dialogue("NARRATOR", "Before them stands The Archive — a structure of impossible geometry. Its entrance is a door that contains copies of itself, recursing to infinity.")

	await _show_dialogue("SYSTEM", "// LOCATION: THE ARCHIVE — Repository of original source code. Clearance: INSUFFICIENT. Override: possible.")
	if not is_inside_tree(): return

	# Transition
	await get_tree().create_timer(1.0).timeout
	if not is_inside_tree(): return
	await _fade_to_black(1.5)
	SceneTransitions.change_scene("res://scenes/chapter3/archive_depths.tscn")

# ─── Utility ─────────────────────────────────────────────────────────

func _has_elara() -> bool:
	return GameManager.has_elara()

func _has_flag(flag_name: String) -> bool:
	return GameManager.has_flag(flag_name)

func _show_dialogue(speaker: String, text: String) -> void:
	await DialogueManager.say(speaker, text)
	if not is_inside_tree(): return

func _fade_to_black(duration: float) -> void:
	if not is_instance_valid(fade_rect): return
	fade_rect.z_index = 100
	fade_rect.color = Color.BLACK
	fade_rect.modulate = Color(1, 1, 1, 0)
	var tw = create_tween()
	tw.tween_property(fade_rect, "modulate:a", 1.0, duration)
	await tw.finished
	if not is_inside_tree(): return
