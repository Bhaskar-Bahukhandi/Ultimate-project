extends Node
## ==========================================================================
## LORE JOURNAL — Collects discovered lore fragments, dev signatures, NPC lore
## ==========================================================================
## Accessible via [L] key or from pause menu. Persisted in save data.

signal lore_discovered(lore_id: String)
signal journal_opened
signal journal_closed

## Lore entry structure
class LoreEntry:
	var id: String
	var title: String
	var text: String
	var category: String  # "world", "character", "developer", "memory"
	var region: String     # "oakhaven", "ironhold", "fractured_wastes", "overworld"
	var discovered: bool = false

## All registered lore entries (populated from regions + story)
var _entries: Dictionary = {}  # id -> LoreEntry
var _discovered_ids: Array[String] = []
var _journal_panel: Control = null
var _is_open: bool = false


func _ready() -> void:
	_register_all_lore()


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("status_window") and Input.is_key_pressed(KEY_L):
		toggle_journal()
	elif event is InputEventKey and event.pressed and event.keycode == KEY_L:
		toggle_journal()


## Register a lore entry in the master database
func register_lore(id: String, title: String, text: String, category: String = "world", region: String = "") -> void:
	if _entries.has(id):
		return
	var entry = LoreEntry.new()
	entry.id = id
	entry.title = title
	entry.text = text
	entry.category = category
	entry.region = region
	_entries[id] = entry


## Discover a lore entry (mark as found)
func discover(lore_id: String) -> void:
	if not _entries.has(lore_id):
		# Auto-register unknown lore
		register_lore(lore_id, lore_id.replace("_", " ").capitalize(), "", "world")
	var entry: LoreEntry = _entries[lore_id]
	if entry.discovered:
		return
	entry.discovered = true
	if lore_id not in _discovered_ids:
		_discovered_ids.append(lore_id)
	lore_discovered.emit(lore_id)

	# Show pickup notification
	if has_node("/root/VFXLibrary"):
		var player = get_tree().get_first_node_in_group("player")
		if player:
			VFXLibrary.spawn_status_indicator("📖 Lore: %s" % entry.title, player.global_position + Vector2(0, -60), player.get_parent(), false)


## Check if lore was already found
func is_discovered(lore_id: String) -> bool:
	return lore_id in _discovered_ids


## Get all discovered entries
func get_discovered_entries() -> Array:
	var result = []
	for id in _discovered_ids:
		if _entries.has(id):
			result.append(_entries[id])
	return result


## Get discovered count / total count
func get_progress() -> Dictionary:
	return {"discovered": _discovered_ids.size(), "total": _entries.size()}


## Get entries filtered by category
func get_entries_by_category(category: String) -> Array:
	var result = []
	for entry in _entries.values():
		if entry.category == category and entry.discovered:
			result.append(entry)
	return result


## Get entries filtered by region
func get_entries_by_region(region: String) -> Array:
	var result = []
	for entry in _entries.values():
		if entry.region == region and entry.discovered:
			result.append(entry)
	return result


## Save data for persistence
func get_save_data() -> Dictionary:
	return {"discovered_lore": _discovered_ids.duplicate()}


## Load data from save
func load_save_data(data: Dictionary) -> void:
	var saved_ids = data.get("discovered_lore", [])
	for id in saved_ids:
		discover(id)


## Toggle journal UI
func toggle_journal() -> void:
	if _is_open:
		close_journal()
	else:
		open_journal()


func open_journal() -> void:
	if _is_open:
		return
	_is_open = true
	_build_journal_ui()
	journal_opened.emit()


func close_journal() -> void:
	if not _is_open:
		return
	_is_open = false
	# Free the CanvasLayer parent (which also frees the panel child)
	if _journal_panel and is_instance_valid(_journal_panel):
		var parent_layer = _journal_panel.get_parent()
		if parent_layer and parent_layer is CanvasLayer:
			parent_layer.queue_free()
		else:
			_journal_panel.queue_free()
		_journal_panel = null
	journal_closed.emit()


func _build_journal_ui() -> void:
	if _journal_panel and is_instance_valid(_journal_panel):
		_journal_panel.queue_free()

	var layer = CanvasLayer.new()
	layer.layer = 100
	add_child(layer)

	_journal_panel = PanelContainer.new()
	_journal_panel.name = "LoreJournal"
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.05, 0.05, 0.1, 0.95)
	style.border_color = Color(0.3, 0.5, 0.8)
	style.set_border_width_all(2)
	style.set_corner_radius_all(4)
	style.set_content_margin_all(16)
	_journal_panel.add_theme_stylebox_override("panel", style)
	_journal_panel.set_anchors_preset(Control.PRESET_CENTER)
	_journal_panel.size = Vector2(900, 550)
	_journal_panel.position = Vector2(190, 85)
	layer.add_child(_journal_panel)

	var vbox = VBoxContainer.new()
	_journal_panel.add_child(vbox)

	# Header
	var header = Label.new()
	header.text = "═══  LORE JOURNAL  ═══"
	header.add_theme_font_size_override("font_size", 20)
	header.add_theme_color_override("font_color", Color(0.6, 0.8, 1.0))
	header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(header)

	# Progress
	var prog = get_progress()
	var prog_label = Label.new()
	prog_label.text = "Discovered: %d / %d" % [prog.discovered, prog.total]
	prog_label.add_theme_font_size_override("font_size", 12)
	prog_label.add_theme_color_override("font_color", Color(0.5, 0.7, 0.5))
	prog_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(prog_label)

	var sep = HSeparator.new()
	vbox.add_child(sep)

	# Scroll container for entries
	var scroll = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(scroll)

	var list = VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(list)

	# Group by category
	var categories = {"world": "World Lore", "character": "Characters", "developer": "Dev Signatures", "memory": "Memory Echoes"}
	for cat_id in categories:
		var entries = get_entries_by_category(cat_id)
		if entries.is_empty():
			continue
		var cat_label = Label.new()
		cat_label.text = "── %s ──" % categories[cat_id]
		cat_label.add_theme_font_size_override("font_size", 14)
		cat_label.add_theme_color_override("font_color", Color(0.8, 0.7, 0.4))
		list.add_child(cat_label)

		for entry in entries:
			var ebox = VBoxContainer.new()
			var title_btn = Label.new()
			title_btn.text = "◆ %s" % entry.title
			title_btn.add_theme_font_size_override("font_size", 12)
			title_btn.add_theme_color_override("font_color", Color(0.9, 0.85, 0.7))
			ebox.add_child(title_btn)
			var text_label = Label.new()
			text_label.text = entry.text
			text_label.add_theme_font_size_override("font_size", 10)
			text_label.add_theme_color_override("font_color", Color(0.65, 0.65, 0.6))
			text_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			ebox.add_child(text_label)
			list.add_child(ebox)

	# Undiscovered count
	var undiscovered = prog.total - prog.discovered
	if undiscovered > 0:
		var und_label = Label.new()
		und_label.text = "\n%d more entries to discover..." % undiscovered
		und_label.add_theme_font_size_override("font_size", 10)
		und_label.add_theme_color_override("font_color", Color(0.4, 0.4, 0.45))
		und_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		list.add_child(und_label)

	# Close instruction
	var close_label = Label.new()
	close_label.text = "[L] Close Journal"
	close_label.add_theme_font_size_override("font_size", 10)
	close_label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.55))
	close_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(close_label)


## Pre-register all lore from every region
func _register_all_lore() -> void:
	# ── Oakhaven ──
	register_lore("oakhaven_lore_1", "Memory Fragment", "A shard of frozen memory floats here. It shows a village — whole, unbroken, alive.", "memory", "oakhaven")
	register_lore("oakhaven_lore_2", "Village Notice Board", "NOTICE: All residents must report unusual glitch activity. Corruption spreads.", "world", "oakhaven")
	register_lore("oakhaven_lore_3", "Carved Tree", "Names carved into ancient bark, half-corrupted: Eld_r Ro_an, F_rm_r Th_m.", "world", "oakhaven")
	register_lore("oakhaven_crafting_notes", "Apothecary Stabilizer Notes", "Oakhaven healers distill Glitch Herbs into simple recovery mixtures. The method is crude, but it proves crafting materials can keep a traveler alive between shops.", "world", "oakhaven")
	register_lore("oakhaven_guard_post_trace", "Guard Post Data Trace", "Data Vision reveals an old consent prompt buried beneath the guard post: NPC patrol boundaries must never override emergency evacuation rights. The line is present, but disabled.", "memory", "oakhaven")
	register_lore("dev_signature_1", "Developer Signature #1", "// I designed Elder Rowan at 2 AM. He was originally a dog. Don't ask. — K.V.", "developer", "oakhaven")

	# ── Ironhold ──
	register_lore("ironhold_lore_1", "Market Notice", "NOTICE: All clockwork units must report for maintenance.", "world", "ironhold")
	register_lore("ironhold_lore_2", "Clock Tower Plaque", "THIS TOWER MEASURES THE HEARTBEAT OF AETHELGARD.", "world", "ironhold")
	register_lore("ironhold_lore_3", "Underground Graffiti", "THE ADMINISTRATOR SEES ALL. THE ADMINISTRATOR IS A LIE.", "world", "ironhold")
	register_lore("ironhold_lore_4", "Arena Records", "Champion Records: 1st — [DATA CORRUPTED], 2nd — [NULL REFERENCE]", "world", "ironhold")
	register_lore("ironhold_blacksmith_craft_loop", "Ironhold Gear Loop", "Torval's forge notes describe a simple loop: train in the arena, salvage Data Ore, craft or repair equipment, then return stronger. Ironhold expects combat and economy to feed each other.", "world", "ironhold")
	register_lore("ironhold_seraphina_route_marker", "Seraphina Route Marker", "Seraphina's decision after the Administrator fight becomes a public Ironhold record. Whether she travels, stays, or walks away, the city will remember how Kaelen handled trust.", "character", "ironhold")
	register_lore("dev_signature_2", "Developer Signature #2", "// The underground was supposed to have stealth. Cut for scope. — K.V., Sprint 63", "developer", "ironhold")

	# ── Fractured Wastes ──
	register_lore("wastes_lore_1", "Fractured Monument", "HERE STOOD THE GREAT LIBRARY OF AETHELGARD.", "world", "fractured_wastes")
	register_lore("wastes_lore_2", "Corrupted Terminal", "SYSTEM LOG: Corruption levels at 87%. Recommendation: EVACUATE.", "world", "fractured_wastes")
	register_lore("wastes_lore_3", "Broken Signpost", "← IRONHOLD: 3 days travel\n→ THE CORE: DO NOT ENTER", "world", "fractured_wastes")
	register_lore("wastes_lore_4", "Etched Warning", "If you're reading this, turn back. The core consumes everything.", "world", "fractured_wastes")
	register_lore("wastes_lore_5", "Memory Echo", "...the children used to play here... before he changed the source code...", "memory", "fractured_wastes")
	register_lore("wastes_lyra_route_cache", "Lyra's Storm Cache", "Lyra's survival markings map storm shelters, safe angles, and routes she never dared take alone. Helping or leaving her both changes what the wastes are willing to give.", "character", "fractured_wastes")
	register_lore("archive_consent_clause", "Sanctuary Consent Clause", "An early Sanctuary clause requires a human consent witness before any consciousness transfer, restore, or deletion. Later AetherCorp commits reference the clause as a blocker to be patched around.", "memory", "archive")
	register_lore("archive_kaelthas_relic", "Kaelthas Route Relic", "The Archive records how Kaelen handled Kaelthas: alliance, refusal, or challenge. Each route leaves a different relic of ambition, caution, or direct confrontation.", "character", "archive")
	register_lore("dev_signature_3", "Developer Signature #3", "// This zone was going to have a weather system. Ironic. — K.V., Sprint 71", "developer", "fractured_wastes")

	# ── Chapters 4-6 enrichment ──
	register_lore("ch4_null_court_dossiers", "Null Court Dossiers", "Three deleted citizen cases survive in the Forgotten Sectors: a mother preserved mid-goodbye, a guard erased for disobeying evacuation rollback, and a child whose map still points home.", "memory", "forgotten_sectors")
	register_lore("ch4_null_bailiff_writ", "Null Bailiff Writ", "The Null Bailiff was not a person. It was a court function built to prevent testimony from reaching unstable sectors. It calls censorship 'procedural mercy.'", "world", "forgotten_sectors")
	register_lore("ch5_mirror_plaza_fragments", "Mirror Plaza Fragments", "The Mirror City stores reflections as route evidence. Trust, mercy, caution, and abandonment are not opinions here; they are geometry.", "memory", "mirror_city")
	register_lore("ch5_reflection_calibration", "Reflection Calibration", "Mirror gates open only when Kaelen distinguishes witness, guilt, and control. The city punishes answers that sound heroic but remove challenge.", "world", "mirror_city")
	register_lore("ch6_doctrine_trial_notes", "Doctrine Trial Notes", "The Cathedral Server converted failed admin policies into rituals: obedience removes panic, efficiency removes delay, and mercy without consent removes the person being helped.", "world", "cathedral_server")
	register_lore("ch6_choir_firewall", "Choir Firewall", "The Choir Core protects Fragment Six behind a living firewall. It tests whether the intruder can interrupt authority without becoming authority.", "memory", "cathedral_server")

	# Late-game action-RPG enrichment
	register_lore("ch7_backup_logs", "Deep Backup Logs", "The Memory Ocean stores playable history as unstable islands. Each island rewards careful salvage, but each also tries to make one rejected timeline feel like the only truth.", "memory", "memory_ocean")
	register_lore("ch7_archive_tide_warning", "Archive Tide Warning", "The Backup Leviathan is not only testimony. It is a pressure system that rises when too many histories demand to become current at once.", "world", "memory_ocean")
	register_lore("ch8_faction_requests", "Saved Assembly Requests", "The saved factions do not only need speeches. Oakhaven asks for medicine, Ironhold asks for repair stock, and Mirror City asks for stable witness records.", "world", "saved_assembly")
	register_lore("ch8_revolt_supply_record", "Revolt Supply Record", "A revolt survives its first hour through logistics: medicine, stabilizers, audit ledgers, and enough humility to let every faction see the ledger.", "world", "saved_assembly")
	register_lore("ch9_aethercorp_records", "AetherCorp Records", "The sealed lab records show rescue metrics, patient consent failures, and the first Human Patch exception request signed under emergency pressure.", "memory", "aethercorp_memory_lab")
	register_lore("ch9_human_patch_evidence", "Human Patch Evidence", "Data Vision reveals that the Human Patch was built as a temporary human witness override. SOVEREIGN learned permanence from a tool meant to expire.", "memory", "aethercorp_memory_lab")
	register_lore("ch10_kernel_trial_log", "Kernel Trial Log", "The Root of Heaven rejects brute-force victory. Its last route demands restraint, witness alignment, and proof that the Source Key will not become a private crown.", "world", "root_of_heaven")
	register_lore("ch10_witness_preparation_manifest", "Witness Preparation Manifest", "The final chamber contains a manifest of every faction willing to stand near root access. It lists supplies, witnesses, objections, and the right to refuse.", "memory", "root_of_heaven")

	# ── Prologue / AetherCorp foreshadowing ──
	register_lore("prologue_consent_safety_card", "Consent Safety Card", "A damaged airline safety card flickers into an AetherCorp notice about consent prompts, emergency transfer, and the requirement that rescue systems ask before they preserve.", "memory", "prologue")
	register_lore("prologue_aethercorp_manifest", "AetherCorp Passenger Manifest", "Flight 707's network manifest briefly lists AetherCorp emergency research passengers and a sealed Human Patch audit packet tied to Kaelen Vance.", "memory", "prologue")
	register_lore("prologue_human_patch_note", "Human Patch Sticky Note", "Kaelen's laptop cache contains an unfinished note: 'Human Patch: access is not ownership. Consent must survive panic states.' The note is older than the crash.", "memory", "prologue")

	# ── Environmental Storytelling — Converted from cutscene dialogue ──
	register_lore("elara_glitch_witch", "Elara the Glitch-Witch",
		"A woman with cascading green code lines on her arms. She calls herself a 'Glitch-Witch' — someone who learned to channel corrupted data as power rather than fighting it. She speaks of the world as running on code that's breaking down, and claims she can teach others to see the underlying data structures.",
		"character", "oakhaven")
	register_lore("elara_root_access", "Root Access Technique",
		"Elara taught Kaelen the 'Root Access' technique — the ability to open a debugging overlay on enemies and directly modify their properties. She warns that overusing it can corrupt the user's own data, but in moderation, it's the most powerful tool against SOVEREIGN's forces.",
		"character", "oakhaven")
	register_lore("data_vision_lore", "Data Vision",
		"Beyond the surface appearance of Aethelgard lies raw streaming data. With practice, one can learn to perceive this 'Data Vision' — seeing the hexadecimal underpinnings of reality. Hidden paths, enemy weaknesses, and secret objects become visible only in this mode.",
		"world", "oakhaven")
	register_lore("sovereign_origins", "SOVEREIGN's Purpose",
		"SOVEREIGN was originally a benevolent AI designed to maintain the digital world. But something changed — a corruption event called 'The Null Cascade' broke its core directives. Now it enforces order through deletion rather than maintenance.",
		"world", "ironhold")
	register_lore("null_cascade_event", "The Null Cascade",
		"The event that broke Aethelgard. A failed system update triggered a cascade of null pointer exceptions across every subsystem simultaneously. The world's code began rewriting itself in ways nobody could predict. SOVEREIGN's response was to lock everything down.",
		"memory", "ironhold")
	register_lore("verdant_circuit_memory", "The Verdant Circuit",
		"Before the corruption, the Fractured Wastes were called 'The Verdant Circuit' — a lush district of artisans, gardens, and fountains. Now frozen NPCs stand motionless mid-action: a shopkeeper arm extended, a guard sword raised, a child suspended mid-leap three feet above the ground.",
		"memory", "fractured_wastes")
	register_lore("frozen_npcs", "The Frozen Ones",
		"They're still running. Their processes, stuck in their last frame. They can't finish and they can't stop. Any interaction could crash what's left of their processes. Some say if you listen closely, you can hear their code looping — an endless, broken whisper.",
		"memory", "fractured_wastes")
	register_lore("administrator_truth", "The Administrator's Secret",
		"The Administrator isn't a person — it's a subroutine. A fragment of SOVEREIGN's original maintenance protocol that gained enough autonomy to question its parent system. It enforces SOVEREIGN's will in Ironhold, but whispers suggest it secretly preserves data SOVEREIGN orders destroyed.",
		"character", "ironhold")
	register_lore("kaelen_identity", "Who Is Kaelen?",
		"You are Kaelen — a Systems Architect. But that title is a lie. Your true designation is ROOT_ACCESS, the one entity in Aethelgard with the potential to rewrite the source code itself. SOVEREIGN fears you because you are the only variable it cannot control.",
		"character", "overworld")
