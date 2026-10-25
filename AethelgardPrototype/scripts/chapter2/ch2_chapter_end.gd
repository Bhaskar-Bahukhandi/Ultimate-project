extends Control

## Chapter 2 / Act 1 ending — the report, the road out, the outer bridge, then the stats card.
## Words: dialogue/ch2/act1_end.dlg.

var fade_rect: ColorRect
var background: ColorRect
var end_card_visible: bool = false
var skip_timer: bool = false
var _camera: Node = null

func _ready() -> void:
	print("[CH2-ENDING] Initializing Chapter 2 Conclusion")
	GameManager.change_state(GameManager.GameState.DIALOGUE)

	# Play victory music for the chapter ending
	if has_node("/root/MusicManager"):
		MusicManager.play_track("victory")

	# Attempt to grab a camera reference for screen shake
	_camera = get_viewport().get_camera_2d()

	_build_background()

	# Fade in from black over 1.5 seconds
	fade_rect.modulate = Color(1, 1, 1, 1)
	var tween = create_tween()
	tween.tween_property(fade_rect, "modulate:a", 0.0, 1.5)
	await tween.finished
	if not is_inside_tree(): return

	await _start_ending_sequence()
	if not is_inside_tree(): return

func _build_background() -> void:
	# Full black background
	# set_anchors_and_offsets_preset(), not `anchors_preset =`: on a Control made
	# in code the property is ignored (layout mode is Position), leaving size 0.
	background = ColorRect.new()
	background.color = Color(0.02, 0.02, 0.05)
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(background)

	# Fade rect covering screen for transitions
	fade_rect = ColorRect.new()
	fade_rect.color = Color.BLACK
	fade_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	fade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fade_rect.z_index = 50
	add_child(fade_rect)

func _has_elara() -> bool:
	return GameManager.has_elara()

const END_DLG := "res://dialogue/ch2/act1_end.dlg"

## Stats card layout (UI spec: story Y1-P0-T12 AC-2): font tries 20, then 18, then the 16 floor.
const CARD_FONT_SIZES: Array[int] = [20, 18, 16]
const CARD_MARGIN_X := 28
const CARD_MARGIN_Y := 16
const CARD_VIEWPORT_MARGIN := 24

func _start_ending_sequence() -> void:
	## The Act 1 midpoint report, the road out, and the Act 1 end scene on
	## Ironhold's outer bridge (dialogue/ch2/act1_end.dlg). No SOVEREIGN reveal
	## here: why it knows Kaelen is a Chapter 4–9 mystery.
	for node in ["report", "road_out", "end"]:
		await DialogueManager.run(END_DLG, node, _on_dlg_event)
		if not is_inside_tree(): return
	DialogueManager.hide_dialogue()
	await get_tree().create_timer(1.0, false).timeout
	if not is_inside_tree(): return
	await _show_chapter_end_card()

func _on_dlg_event(event: String) -> void:
	match event:
		"seraphina_joins":
			await get_tree().create_timer(0.4, false).timeout
		"sky_seam":
			var seam := ColorRect.new()
			seam.color = Color(0.7, 0.3, 1.0, 0.0)
			seam.size = Vector2(6, 720)
			seam.position = Vector2(900, 0)
			seam.z_index = 40
			add_child(seam)
			var t := create_tween()
			t.tween_property(seam, "color:a", 0.8, 0.4)
			t.tween_property(seam, "color:a", 0.25, 0.8)
			await get_tree().create_timer(0.6, false).timeout
		_:
			print("[CH2-ENDING] unhandled dialogue event: %s" % event)

func _show_chapter_end_card() -> void:
	end_card_visible = true

	# Full black background for the card
	var card_bg = ColorRect.new()
	card_bg.color = Color.BLACK
	card_bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	card_bg.z_index = 80
	card_bg.name = "ChapterEndCard"
	add_child(card_bg)

	# The stats card: a centred panel (header, two columns, footer) so all of it fits the 1280x720 viewport.
	var parts: Dictionary = _chapter_stats_parts()
	var center := CenterContainer.new()
	center.name = "CardCenter"
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	# No z_index of its own: z is relative, so the card's 80 is inherited and the fade_rect (100) still covers
	# the whole card when it fades out (an own 81 made it 161 and left the stats drawn over the black).
	card_bg.add_child(center)

	var panel := PanelContainer.new()
	panel.name = "CardPanel"
	center.add_child(panel)
	var margin := MarginContainer.new()
	for side in ["left", "right"]:
		margin.add_theme_constant_override("margin_" + side, CARD_MARGIN_X)
	for side in ["top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, CARD_MARGIN_Y)
	panel.add_child(margin)
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	margin.add_child(vbox)

	var header := _card_label("HeaderLabel", parts["header"], HORIZONTAL_ALIGNMENT_CENTER)
	vbox.add_child(header)
	var columns := HBoxContainer.new()
	columns.name = "Columns"
	columns.add_theme_constant_override("separation", 48)
	vbox.add_child(columns)
	columns.add_child(_card_label("LeftColumn", parts["left"], HORIZONTAL_ALIGNMENT_LEFT))
	columns.add_child(_card_label("RightColumn", parts["right"], HORIZONTAL_ALIGNMENT_LEFT))
	var footer := _card_label("FooterLabel", parts["footer"], HORIZONTAL_ALIGNMENT_CENTER)
	vbox.add_child(footer)
	_fit_card_font(panel, [header, columns.get_child(0), columns.get_child(1), footer])

	# Fade the card in over 2 seconds
	card_bg.modulate = Color(1, 1, 1, 0)
	var fade_tween = create_tween()
	fade_tween.tween_property(card_bg, "modulate:a", 1.0, 2.0)
	await fade_tween.finished
	if not is_inside_tree(): return

	# Set story flags for chapter completion
	# (ch2_sovereign_revealed is no longer set: SOVEREIGN is revealed later.)
	GameManager.set_story_flag("ch2_complete", true)
	print("[CH2-ENDING] Chapter 2 complete")

	# Wait 12 seconds or until the player presses ui_accept (Enter / KP Enter / gamepad A)
	skip_timer = false
	var wait_elapsed: float = 0.0
	while wait_elapsed < 12.0 and not skip_timer:
		await get_tree().create_timer(0.1, false).timeout
		if not is_inside_tree(): return
		wait_elapsed += 0.1

	# Fade to black
	fade_rect.z_index = 100
	fade_rect.modulate = Color(1, 1, 1, 0)
	var out_tween = create_tween()
	out_tween.tween_property(fade_rect, "modulate:a", 1.0, 1.5)
	await out_tween.finished
	if not is_inside_tree(): return

	await get_tree().create_timer(1.0, false).timeout
	if not is_inside_tree(): return

	# Auto-save the completed state before returning to menu
	GameManager.auto_save()
	print("[CH2-ENDING] Auto-saved completed chapter state")

	# Offer to continue to Chapter 3 or return to menu
	var ch_choice = await DialogueManager.show_choices(
		"What would you like to do?",
		[
			"Continue to Chapter 3 — The Source Code",
			"Return to main menu"
		]
	)

	if ch_choice == 0:
		print("[CH2-ENDING] Continuing to Chapter 3")
		SceneTransitions.change_scene("res://scenes/chapter3/ironhold_departure.tscn")
	else:
		print("[CH2-ENDING] Returning to main menu")
		GameManager.reset_game()
		SceneTransitions.change_scene("res://scenes/main_menu.tscn")

func _chapter_stats_parts() -> Dictionary:
	## The card text in four parts (header, left column, right column, footer), each a plain string with its
	## internal blank lines. The panel shows one label per part; _build_chapter_stats_text() joins them.
	# Gather data from GameManager
	var corruption_level: int = int(GameManager.glitch_meter) if GameManager.get("glitch_meter") != null else 0
	var player_level: int = GameManager.player_stats.get("level", 1) if GameManager.get("player_stats") != null else 1
	var elara_rel: int = GameManager.relationships.get("elara", 0) if GameManager.get("relationships") != null else 0
	var seraphina_rel_value = GameManager.relationships.get("seraphina", 0) if GameManager.get("relationships") != null else 0
	var source_keys: int = GameManager.source_key_count if GameManager.get("source_key_count") != null else 2

	# === CH1 Choices ===
	# Elara companion status
	var elara_status: String
	if _has_flag("ch1_elara_trusted"):
		elara_status = "TRUSTED ALLY"
	elif _has_flag("ch1_elara_cautious"):
		elara_status = "CAUTIOUS PARTNER"
	elif _has_flag("ch1_elara_distrusted"):
		elara_status = "REJECTED (Solo Path)"
	else:
		elara_status = "UNKNOWN"

	# Knight Aldric status
	var knight_status: String
	if _has_flag("ch1_knight_spared"):
		knight_status = "FREED"
	elif _has_flag("ch1_knight_killed"):
		knight_status = "SLAIN"
	else:
		knight_status = "DEFEATED"

	# Oakhaven village
	var village_status: String
	if _has_flag("ch1_oakhaven_warned_villagers"):
		village_status = "WARNED"
	elif _has_flag("ch1_oakhaven_left_quietly"):
		village_status = "LEFT IN SILENCE"
	else:
		village_status = "DEPARTED"

	# === CH2 Choices ===
	# Seraphina relationship display
	var seraphina_display: String
	if _has_flag("ch2_seraphina_rejected"):
		seraphina_display = "REJECTED"
	else:
		seraphina_display = "+%d" % seraphina_rel_value

	# Data Wraith choice
	var wraith_choice: String
	if _has_flag("ch2_data_wraith_restored"):
		wraith_choice = "RESTORED"
	elif _has_flag("ch2_data_wraith_destroyed"):
		wraith_choice = "DESTROYED"
	elif _has_flag("ch2_data_wraith_absorbed"):
		wraith_choice = "ABSORBED"
	else:
		wraith_choice = "UNKNOWN"

	# Seraphina choice
	var seraphina_choice: String
	if _has_flag("ch2_seraphina_recruited"):
		seraphina_choice = "RECRUITED"
	elif _has_flag("ch2_seraphina_stayed"):
		seraphina_choice = "STAYED"
	elif _has_flag("ch2_seraphina_rejected"):
		seraphina_choice = "REJECTED"
	else:
		seraphina_choice = "UNKNOWN"

	# Seraphina encounter approach
	var seraphina_approach: String
	if _has_flag("ch2_seraphina_truth"):
		seraphina_approach = "Told the Truth"
	elif _has_flag("ch2_seraphina_cautious"):
		seraphina_approach = "Downplayed"
	elif _has_flag("ch2_seraphina_showoff"):
		seraphina_approach = "Showed Off"
	else:
		seraphina_approach = "—"

	var header := "═══════════════════════════════════\n"
	header += "CHAPTER 2 COMPLETE\n"
	header += "═══════════════════════════════════\n"
	header += "\n"
	header += "ACT 1: ARRIVAL AND BELONGING\n"
	header += "IRONHOLD CROWN"

	var left := "Source Key Fragments: %d/7\n" % source_keys
	left += "Corruption Level: %d%%\n" % corruption_level
	left += "Player Level: %d\n" % player_level
	var playtime = GameManager.playtime_seconds if GameManager.get("playtime_seconds") != null else 0.0
	@warning_ignore("integer_division")
	var minutes = int(playtime) / 60
	@warning_ignore("integer_division")
	var hours = minutes / 60
	var mins_rem = minutes % 60
	var secs = int(playtime) % 60
	if hours > 0:
		left += "Playtime: %dh %02dm %02ds\n" % [hours, mins_rem, secs]
	else:
		left += "Playtime: %dm %02ds\n" % [mins_rem, secs]
	var gold = GameManager.player_stats.get("gold", 0)
	left += "Gold: %d\n" % gold
	var arena_wins = GameManager.arena_stats.get("total_wins", 0)
	var arena_losses = GameManager.arena_stats.get("total_losses", 0)
	var best_streak = GameManager.arena_stats.get("best_streak", 0)
	if arena_wins > 0 or arena_losses > 0:
		left += "Arena: %dW / %dL (Best Streak: %d)\n" % [arena_wins, arena_losses, best_streak]
	left += "\n"
	left += "Relationships:\n"
	left += "  Elara: +%d [%s]\n" % [elara_rel, elara_status]
	left += "  Seraphina: %s" % seraphina_display

	var right := "Chapter 1 Choices:\n"
	right += "  - Knight Aldric: [%s]\n" % knight_status
	right += "  - Oakhaven: [%s]\n" % village_status
	right += "\n"
	right += "Chapter 2 Choices:\n"
	right += "  - Seraphina Encounter: [%s]\n" % seraphina_approach
	right += "  - Data Wraith: [%s]\n" % wraith_choice
	right += "  - Seraphina: [%s]\n" % seraphina_choice
	right += "\n"
	right += "Act 1 report sent to: %s" % _report_destination()

	var footer := "═══════════════════════════════════\n"
	footer += "ACT 2: MEMORY AND LEGITIMACY\n"
	footer += "THE JOURNEY CONTINUES...\n"
	footer += "═══════════════════════════════════\n"
	footer += "\n"
	footer += "Thank you for playing the Aethelgard Prototype!\n"
	footer += "Press {ui_accept} to continue."

	return {"header": header, "left": left, "right": right, "footer": InputService.fmt(footer)}

func _build_chapter_stats_text() -> String:
	## The whole card as one string (the pre-panel layout's text, kept so a test can compare it to its golden).
	var parts: Dictionary = _chapter_stats_parts()
	return "%s\n\n%s\n\n%s\n\n%s" % [parts["header"], parts["left"], parts["right"], parts["footer"]]

## One text block of the card: no wrapping (a clipped or wrapped line would hide text), tinted like the old label.
func _card_label(node_name: String, text: String, align: HorizontalAlignment) -> Label:
	var label := Label.new()
	label.name = node_name
	label.text = text
	label.horizontal_alignment = align
	label.autowrap_mode = TextServer.AUTOWRAP_OFF
	label.add_theme_font_size_override("font_size", CARD_FONT_SIZES[0])
	label.add_theme_color_override("font_color", Color(0.85, 0.9, 1.0))
	return label

## Starts at the first CARD_FONT_SIZES entry and steps down only while the panel is taller or wider than the
## viewport minus CARD_VIEWPORT_MARGIN on every side; the last entry (16) is the floor.
func _fit_card_font(panel: Control, labels: Array) -> void:
	var avail: Vector2 = get_viewport_rect().size - Vector2.ONE * (2.0 * CARD_VIEWPORT_MARGIN)
	for font_size in CARD_FONT_SIZES:
		for label: Label in labels:
			label.add_theme_font_size_override("font_size", font_size)
		var need: Vector2 = panel.get_combined_minimum_size()
		if need.x <= avail.x and need.y <= avail.y:
			return
	push_warning("[CH2-ENDING] Stats card is %s at the %d px font floor; it does not fit %s with %d px margins." % [
		panel.get_combined_minimum_size(), CARD_FONT_SIZES[-1], get_viewport_rect().size, CARD_VIEWPORT_MARGIN])

# ---------------------------------------------------------------------------
# Helper: conditional checks
# ---------------------------------------------------------------------------

func _is_seraphina_recruited() -> bool:
	return _has_flag("ch2_seraphina_recruited")

func _has_flag(flag_name: String) -> bool:
	return GameManager.has_flag(flag_name)

# ---------------------------------------------------------------------------
# Screen-shake fallback when no camera with shake() is available
# ---------------------------------------------------------------------------

func _simulate_screen_shake() -> void:
	var original_pos = position
	var shake_tween = create_tween()
	for i in range(10):
		var offset = Vector2(randf_range(-8, 8), randf_range(-8, 8))
		shake_tween.tween_property(self, "position", original_pos + offset, 0.05)
	shake_tween.tween_property(self, "position", original_pos, 0.05)

# ---------------------------------------------------------------------------
# Input: ui_accept (Enter / KP Enter / gamepad A) skips the end-card wait timer
# ---------------------------------------------------------------------------

func _input(event: InputEvent) -> void:
	if not end_card_visible:
		return
	if event.is_action_pressed("ui_accept"):
		skip_timer = true
		get_viewport().set_input_as_handled()

func _report_destination() -> String:
	if _has_flag("act1_report_local"):
		return "the councils"
	if _has_flag("act1_report_archive"):
		return "the Wastes archivists"
	if _has_flag("act1_report_command"):
		return "Ironhold command"
	return "no one"
