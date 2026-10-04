extends CanvasLayer
## Completion tracker — unified % view of quests, lore, secrets, achievements.
## Accessible from the main menu and pause screen.

const CAT_ORDER := ["story", "quests", "secrets", "lore", "achievements"]
const CAT_LABELS := {
	"story": "📖  Story Progress",
	"quests": "⚔️  Side Quests",
	"secrets": "🔍  Secrets",
	"lore": "📜  Lore Entries",
	"achievements": "🏆  Achievements",
}
const CAT_COLORS := {
	"story": Color(0.4, 0.8, 1.0),
	"quests": Color(1.0, 0.8, 0.3),
	"secrets": Color(0.6, 1.0, 0.5),
	"lore": Color(0.9, 0.6, 1.0),
	"achievements": Color(1.0, 0.6, 0.4),
}
const TOTAL_CHAPTERS := 3  # Prologue + Ch1 + Ch2 + Ch3 → 3 chapters complete

var _panel: PanelContainer
var _visible := false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 115  # above the pause screen (110), which it's opened from
	visible = false

# ─── Public API ───────────────────────────────────────────────────────
func show_tracker() -> void:
	# Non-exclusive: it stacks on top of the pause menu it's opened from.
	ContextStack.push(&"completion_tracker", self, true, true, false)
	_build_ui()
	visible = true
	_visible = true

func hide_tracker() -> void:
	visible = false
	_visible = false
	ContextStack.pop(&"completion_tracker")
	# Clean up children
	for c in get_children():
		c.queue_free()

# ─── Data Collection ──────────────────────────────────────────────────
func _get_completion_data() -> Dictionary:
	var data := {}

	# Story: based on current_chapter (max 3 chapters)
	var chapter := clampi(GameManager.current_chapter, 1, TOTAL_CHAPTERS)
	var ch_complete := 0
	if GameManager.story_flags.get("ch3_complete", false):
		ch_complete = TOTAL_CHAPTERS
	elif GameManager.story_flags.get("ch2_complete", false):
		ch_complete = 2
	elif GameManager.story_flags.get("ch1_complete", false):
		ch_complete = 1
	data["story"] = {"done": ch_complete, "total": TOTAL_CHAPTERS}

	# Side Quests
	var q_done := 0
	var q_total: int = SideQuestManager.QUEST_DATABASE.size()
	for qid in SideQuestManager.quests:
		if SideQuestManager.quests[qid].get("state", 0) == SideQuestManager.QuestState.COMPLETED:
			q_done += 1
	data["quests"] = {"done": q_done, "total": q_total}

	# Secrets
	var s_done: int = SideQuestManager.secrets_found.size()
	var s_total: int = SideQuestManager.SECRETS_DATABASE.size()
	data["secrets"] = {"done": s_done, "total": s_total}

	# Lore
	var lore_prog: Dictionary = LoreJournal.get_progress()
	data["lore"] = {"done": lore_prog.get("discovered", 0), "total": lore_prog.get("total", 0)}

	# Achievements
	var a_done: int = Achievements.unlocked.size()
	var a_total: int = Achievements.ACHIEVEMENTS.size()
	data["achievements"] = {"done": a_done, "total": a_total}

	return data

func _calc_overall(data: Dictionary) -> float:
	var total_done := 0
	var total_all := 0
	for cat in data:
		total_done += data[cat]["done"]
		total_all += data[cat]["total"]
	if total_all == 0:
		return 0.0
	return clampf(float(total_done) / float(total_all), 0.0, 1.0)

# ─── UI Construction (code-driven) ───────────────────────────────────
func _build_ui() -> void:
	# Clear old
	for c in get_children():
		c.queue_free()

	var data := _get_completion_data()
	var overall := _calc_overall(data)

	# Dim backdrop
	var bg := ColorRect.new()
	bg.color = Color(0, 0, 0, 0.75)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	# Panel
	_panel = PanelContainer.new()
	_panel.set_anchors_preset(Control.PRESET_CENTER)
	_panel.offset_left = -320
	_panel.offset_top = -260
	_panel.offset_right = 320
	_panel.offset_bottom = 260
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.08, 0.12, 0.95)
	style.border_color = Color(0.0, 1.0, 0.6, 0.6)
	style.set_border_width_all(2)
	style.set_corner_radius_all(8)
	style.set_content_margin_all(20)
	_panel.add_theme_stylebox_override("panel", style)
	add_child(_panel)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	_panel.add_child(vbox)

	# Title
	var title := Label.new()
	title.text = "COMPLETION TRACKER"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 24)
	title.add_theme_color_override("font_color", Color(0.0, 1.0, 0.6))
	vbox.add_child(title)

	# Overall %
	var overall_pct := Label.new()
	overall_pct.text = "Overall: %d%%" % roundi(overall * 100.0)
	overall_pct.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	overall_pct.add_theme_font_size_override("font_size", 18)
	overall_pct.add_theme_color_override("font_color", Color(1, 1, 1, 0.9))
	vbox.add_child(overall_pct)

	# Overall bar
	_add_progress_bar(vbox, overall, Color(0.0, 1.0, 0.6))

	# Separator
	var sep := HSeparator.new()
	sep.add_theme_constant_override("separation", 10)
	vbox.add_child(sep)

	# Category rows
	for cat in CAT_ORDER:
		var d: Dictionary = data.get(cat, {"done": 0, "total": 0})
		var pct := 0.0
		if d["total"] > 0:
			pct = float(d["done"]) / float(d["total"])

		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 10)
		vbox.add_child(row)

		# Label
		var lbl := Label.new()
		lbl.text = CAT_LABELS.get(cat, cat)
		lbl.custom_minimum_size.x = 200
		lbl.add_theme_font_size_override("font_size", 15)
		lbl.add_theme_color_override("font_color", CAT_COLORS.get(cat, Color.WHITE))
		row.add_child(lbl)

		# Bar container
		var bar_box := VBoxContainer.new()
		bar_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(bar_box)
		_add_progress_bar(bar_box, pct, CAT_COLORS.get(cat, Color.WHITE))

		# Count
		var count_lbl := Label.new()
		count_lbl.text = "%d / %d" % [d["done"], d["total"]]
		count_lbl.custom_minimum_size.x = 60
		count_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		count_lbl.add_theme_font_size_override("font_size", 14)
		count_lbl.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8, 0.9))
		row.add_child(count_lbl)

	# NG+ indicator
	if GameManager.ng_plus_cycle > 0:
		var ng_label := Label.new()
		ng_label.text = "🔄 New Game+ Cycle: %d" % GameManager.ng_plus_cycle
		ng_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		ng_label.add_theme_font_size_override("font_size", 14)
		ng_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.3))
		vbox.add_child(ng_label)

	# Close hint
	var hint := Label.new()
	InputService.bind_text(hint, "Press {ui_cancel} or any button to close")
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_font_size_override("font_size", 12)
	hint.add_theme_color_override("font_color", Color(0.4, 0.4, 0.5, 0.6))
	vbox.add_child(hint)

func _add_progress_bar(parent: Control, pct: float, color: Color) -> void:
	# Background track
	var track := ColorRect.new()
	track.custom_minimum_size = Vector2(0, 12)
	track.color = Color(0.15, 0.15, 0.2)
	track.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parent.add_child(track)

	# Fill — use deferred sizing after layout
	var fill := ColorRect.new()
	fill.color = color
	fill.color.a = 0.85
	fill.custom_minimum_size = Vector2(0, 12)
	fill.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	track.add_child(fill)
	# Set fill width after one frame so track has its actual size
	fill.set_meta("_pct", pct)
	fill.resized.connect(_on_fill_resized.bind(fill))

func _on_fill_resized(fill: ColorRect) -> void:
	var pct: float = fill.get_meta("_pct", 0.0)
	var parent_w: float = fill.get_parent().size.x
	fill.size = Vector2(parent_w * pct, 12)
	fill.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN

func _unhandled_input(event: InputEvent) -> void:
	if not _visible:
		return
	if event is InputEventKey or event is InputEventMouseButton or event is InputEventJoypadButton:
		if event.is_pressed():
			hide_tracker()
			get_viewport().set_input_as_handled()
