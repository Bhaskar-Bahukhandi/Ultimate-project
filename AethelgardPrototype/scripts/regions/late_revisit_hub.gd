extends Node2D

## Safe free-travel wrapper for late regions.
## Chapter-route scenes stay separate because they can advance story or grant rewards.

const MAP_SIZE := Vector2(1280, 720)
const DEFAULT_SPAWN := Vector2(640, 430)
const OVERWORLD_SCENE := "res://scenes/overworld/overworld.tscn"

const REGION_THEMES: Dictionary = {
	"forgotten_sectors": {
		"title": "Forgotten Sectors",
		"subtitle": "A deleted transit pocket. The Null Court route stays on Resume Story.",
		"background": Color(0.035, 0.09, 0.12),
		"floor": Color(0.09, 0.19, 0.22),
		"accent": Color(0.22, 0.76, 0.82),
	},
	"mirror_city": {
		"title": "Mirror City",
		"subtitle": "A quiet reflection court with no trial scripts attached.",
		"background": Color(0.05, 0.10, 0.16),
		"floor": Color(0.14, 0.22, 0.31),
		"accent": Color(0.65, 0.92, 1.0),
	},
	"cathedral_server": {
		"title": "Cathedral Server",
		"subtitle": "A buffer nave for revisits. Choir doctrine remains on the story route.",
		"background": Color(0.11, 0.08, 0.03),
		"floor": Color(0.22, 0.18, 0.08),
		"accent": Color(0.95, 0.77, 0.28),
	},
	"memory_ocean": {
		"title": "Memory Ocean",
		"subtitle": "A calm backup shoreline. Archive Tide choices are not replayed here.",
		"background": Color(0.01, 0.04, 0.11),
		"floor": Color(0.04, 0.16, 0.29),
		"accent": Color(0.38, 0.85, 1.0),
	},
	"saved_assembly": {
		"title": "Saved Assembly",
		"subtitle": "A civic landing pad after unlock. Assembly requests stay non-repeatable.",
		"background": Color(0.04, 0.10, 0.05),
		"floor": Color(0.12, 0.22, 0.14),
		"accent": Color(0.50, 0.92, 0.48),
	},
	"human_patch_lab": {
		"title": "Human Patch Lab",
		"subtitle": "A sealed antechamber. Lab evidence and truth choices stay on Resume Story.",
		"background": Color(0.12, 0.04, 0.05),
		"floor": Color(0.22, 0.10, 0.12),
		"accent": Color(1.0, 0.48, 0.42),
	},
	"root_of_heaven": {
		"title": "Root of Heaven",
		"subtitle": "Final preparation only. The final sequence cannot be replayed from free travel.",
		"background": Color(0.12, 0.11, 0.05),
		"floor": Color(0.24, 0.22, 0.10),
		"accent": Color(1.0, 0.90, 0.46),
	},
}

const LATE_FARMING_MARKERS: Dictionary = {
	"forgotten_sectors": {
		"zone_id": "forgotten_sectors_cleanup",
		"name": "Null Archive Fracture",
		"label": "Memory Fracture Cleanup",
		"prompt": "[F] Stabilize fracture",
		"start_label": "Start cleanup run",
		"leave_label": "Leave fracture",
		"cooldown_text": "The null archive is sealing. Re-entry opens in %d seconds.",
		"position": Vector2(386, 430),
		"plate_color": Color(0.06, 0.22, 0.25, 0.92),
		"flow_id": "forgotten_cleanup",
	},
	"cathedral_server": {
		"zone_id": "cathedral_firewall_drill",
		"name": "Firewall Node",
		"label": "Doctrine Purge Drill",
		"prompt": "[F] Prime firewall",
		"start_label": "Run firewall drill",
		"leave_label": "Leave node",
		"cooldown_text": "The firewall node is cooling. Re-entry opens in %d seconds.",
		"position": Vector2(874, 430),
		"plate_color": Color(0.34, 0.22, 0.06, 0.94),
		"flow_id": "cathedral_drill",
	},
	"memory_ocean": {
		"zone_id": "memory_ocean_salvage_run",
		"name": "Tide Fragment",
		"label": "Backup Salvage Run",
		"prompt": "[F] Pull salvage",
		"start_label": "Start salvage run",
		"leave_label": "Leave tide",
		"cooldown_text": "The tide fragment is reforming. Re-entry opens in %d seconds.",
		"position": Vector2(874, 430),
		"plate_color": Color(0.04, 0.24, 0.40, 0.92),
		"flow_id": "memory_salvage",
	},
}

const FARMING_SUPPORT_INTERACTIONS: Dictionary = {
	"forgotten_sectors": {
		"name": "DeletedCaseFile",
		"label": "Deleted Case File",
		"prompt": "[F] Review case",
		"speaker": "Case File 19-B",
		"text": "A citizen record survives in three layers: a name gap, a child's route sketch, and the court note that called both disposable.",
		"lore_id": "ch4_null_court_dossiers",
		"position": Vector2(790, 402),
	},
	"cathedral_server": {
		"name": "DoctrineConsole",
		"label": "Calibration Console",
		"prompt": "[F] Read doctrine",
		"speaker": "Firewall Console",
		"text": "Calibration excerpt: obedience reduces panic quickly. Consent reduces damage slowly. The console flags only one as efficient.",
		"lore_id": "ch6_doctrine_trial_notes",
		"position": Vector2(390, 402),
	},
	"memory_ocean": {
		"name": "TideWarningGauge",
		"label": "Tide Warning",
		"prompt": "[F] Check tide",
		"speaker": "Tide Gauge",
		"text": "The gauge reads salvageable, unstable, and not yours. A backup fragment can be carried out; a whole rejected life cannot.",
		"lore_id": "ch7_archive_tide_warning",
		"position": Vector2(390, 402),
	},
}

const SAFE_SIDE_INTERACTIONS: Dictionary = {
	"mirror_city": {
		"name": "ReflectionTerminal",
		"label": "Memory Mirror",
		"prompt": "[F] Read reflection",
		"speaker": "Memory Mirror",
		"text": "One reflection remains outside the trial route: regret is evidence, not a command to replay the choice.",
		"lore_id": "mirror_city_lost_reflection",
		"position": Vector2(640, 430),
		"kind": "mirror_reflection",
	},
	"saved_assembly": {
		"name": "SupplyBoard",
		"label": "Supply Board",
		"prompt": "[F] Review requests",
		"speaker": "Supply Board",
		"text": "Faction requests stay posted here as logistics, not a new route: medicine, ore, witness records, and room to refuse.",
		"lore_id": "saved_assembly_supply_pact",
		"position": Vector2(640, 430),
		"kind": "assembly_supply_board",
	},
	"human_patch_lab": {
		"name": "AetherCorpRecordTerminal",
		"label": "AetherCorp Record",
		"prompt": "[F] Read terminal",
		"speaker": "Record Terminal",
		"text": "The antechamber record repeats one caution: emergency access is not ownership, and a patch meant to expire must remain answerable.",
		"lore_id": "human_patch_redaction_note",
		"position": Vector2(640, 430),
		"kind": "human_patch_record",
	},
	"root_of_heaven": {
		"name": "FinalPrepTerminal",
		"label": "Final Prep Terminal",
		"prompt": "[F] Read reminder",
		"speaker": "Prep Terminal",
		"text": "Preparation buffer only. Resume Story carries the final witnesses and choices; this gate will not replay them.",
		"lore_id": "ch10_witness_preparation_manifest",
		"position": Vector2(640, 430),
		"kind": "root_prep_terminal",
	},
}

const HUB_PROP_DATA: Dictionary = {
	"forgotten_sectors": [
		{"name": "CaseShelf", "position": Vector2(166, 254), "size": Vector2(176, 22), "label": "ERASED CASES"},
		{"name": "ArchiveSeal", "position": Vector2(862, 520), "size": Vector2(156, 20), "label": "SEAL QUEUE"},
		{"name": "MissingNameStrip", "position": Vector2(500, 324), "size": Vector2(278, 10), "label": ""},
	],
	"mirror_city": [
		{"name": "MirrorLaneWest", "position": Vector2(278, 248), "size": Vector2(18, 240), "label": ""},
		{"name": "MirrorLaneEast", "position": Vector2(984, 248), "size": Vector2(18, 240), "label": ""},
		{"name": "WitnessPlinth", "position": Vector2(546, 520), "size": Vector2(188, 18), "label": "REFLECTION COURT"},
	],
	"cathedral_server": [
		{"name": "FirewallRibWest", "position": Vector2(242, 266), "size": Vector2(24, 242), "label": ""},
		{"name": "FirewallRibEast", "position": Vector2(1016, 266), "size": Vector2(24, 242), "label": ""},
		{"name": "DoctrineRail", "position": Vector2(454, 532), "size": Vector2(372, 12), "label": "DOCTRINE DRILL BUFFER"},
	],
	"memory_ocean": [
		{"name": "SalvageIslandWest", "position": Vector2(212, 474), "size": Vector2(202, 30), "label": "TIDE SHELF"},
		{"name": "SalvageIslandEast", "position": Vector2(878, 280), "size": Vector2(188, 28), "label": "BACKUP FRAGMENTS"},
	],
	"saved_assembly": [
		{"name": "SupplyTableWest", "position": Vector2(238, 320), "size": Vector2(184, 24), "label": "MEDICINE"},
		{"name": "SupplyTableEast", "position": Vector2(858, 320), "size": Vector2(184, 24), "label": "REPAIR STOCK"},
		{"name": "CivicRail", "position": Vector2(470, 532), "size": Vector2(340, 12), "label": "SHARED LEDGER"},
	],
	"human_patch_lab": [
		{"name": "RedactionWallWest", "position": Vector2(230, 286), "size": Vector2(120, 160), "label": "REDACTED"},
		{"name": "RedactionWallEast", "position": Vector2(930, 286), "size": Vector2(120, 160), "label": "CONSENT"},
		{"name": "AuditStrip", "position": Vector2(488, 526), "size": Vector2(304, 12), "label": ""},
	],
	"root_of_heaven": [
		{"name": "WitnessRailWest", "position": Vector2(248, 286), "size": Vector2(22, 208), "label": ""},
		{"name": "WitnessRailEast", "position": Vector2(1010, 286), "size": Vector2(22, 208), "label": ""},
		{"name": "PrepChecklist", "position": Vector2(472, 530), "size": Vector2(336, 14), "label": "FINAL PREP ONLY"},
	],
}

@export var region_id: String = ""

var _player: CharacterBody2D = null
var _theme: Dictionary = {}
var _near_farming_marker: Area2D = null
var _near_side_marker: Area2D = null


func _ready() -> void:
	_theme = REGION_THEMES.get(region_id, {})
	if _theme.is_empty():
		push_error("[LateRevisitHub] Unknown free-travel region: %s" % region_id)
		return

	GameManager.change_state(GameManager.GameState.EXPLORATION)
	GameManager.current_region = region_id
	if has_node("/root/RandomEncounterSystem"):
		RandomEncounterSystem.set_zone("overworld_wilderness")
	_build_environment()
	_spawn_player()
	_restore_return_position()
	_create_return_gate()
	_create_future_marker()
	_create_optional_content_marker()
	_create_ui()
	_show_returning_farming_result()


func _process(_delta: float) -> void:
	if not _player:
		return
	_player.global_position.x = clampf(_player.global_position.x, 48.0, MAP_SIZE.x - 48.0)
	_player.global_position.y = clampf(_player.global_position.y, 76.0, MAP_SIZE.y - 48.0)


func _build_environment() -> void:
	var bg := ColorRect.new()
	bg.name = "Background"
	bg.color = _theme["background"]
	bg.size = MAP_SIZE
	bg.z_index = -30
	add_child(bg)

	var floor := Polygon2D.new()
	floor.name = "TransitFloor"
	floor.color = Color(_theme["floor"].r, _theme["floor"].g, _theme["floor"].b, 0.76)
	floor.polygon = PackedVector2Array([
		Vector2(168, 188), Vector2(376, 146), Vector2(932, 150),
		Vector2(1122, 238), Vector2(1090, 518), Vector2(878, 594),
		Vector2(320, 582), Vector2(154, 476),
	])
	floor.z_index = -24
	add_child(floor)

	var spine := ColorRect.new()
	spine.name = "TransitSpine"
	spine.color = Color(_theme["accent"].r, _theme["accent"].g, _theme["accent"].b, 0.025)
	spine.position = Vector2(636, 190)
	spine.size = Vector2(8, 346)
	spine.z_index = -20
	add_child(spine)

	for pos in [
		Vector2(152, 182),
		Vector2(1010, 182),
		Vector2(212, 500),
		Vector2(950, 500),
		Vector2(376, 280),
		Vector2(804, 280),
	]:
		_add_signal_pillar(pos)

	for i in range(3):
		var band := ColorRect.new()
		band.name = "BufferBand%d" % i
		band.color = Color(_theme["accent"].r, _theme["accent"].g, _theme["accent"].b, 0.045 + float(i % 2) * 0.02)
		band.position = Vector2(236 + i * 262, 434 - (i % 2) * 54)
		band.size = Vector2(138, 8)
		band.rotation = -0.08 + float(i) * 0.04
		band.z_index = -18
		add_child(band)
	_add_hub_identity_props()
	_add_v3_hub_polish()


func _add_signal_pillar(pos: Vector2) -> void:
	var pillar := ColorRect.new()
	pillar.color = Color(_theme["accent"].r, _theme["accent"].g, _theme["accent"].b, 0.05)
	pillar.position = pos
	pillar.size = Vector2(14, 46)
	pillar.z_index = -16
	add_child(pillar)

	var cap := ColorRect.new()
	cap.color = Color(_theme["accent"].r, _theme["accent"].g, _theme["accent"].b, 0.18)
	cap.position = Vector2(-3, -3)
	cap.size = Vector2(20, 4)
	pillar.add_child(cap)


func _add_hub_identity_props() -> void:
	for prop_data in HUB_PROP_DATA.get(region_id, []):
		var prop := ColorRect.new()
		prop.name = prop_data.get("name", "LateHubProp")
		prop.color = Color(_theme["accent"].r, _theme["accent"].g, _theme["accent"].b, 0.10)
		prop.position = prop_data.get("position", Vector2.ZERO)
		prop.size = prop_data.get("size", Vector2(120, 18))
		prop.z_index = -14
		add_child(prop)

		var edge := ColorRect.new()
		edge.name = "Edge"
		edge.color = Color(_theme["accent"].r, _theme["accent"].g, _theme["accent"].b, 0.24)
		edge.position = Vector2.ZERO
		edge.size = Vector2(prop.size.x, 3)
		prop.add_child(edge)

		var label_text: String = prop_data.get("label", "")
		if label_text.is_empty():
			continue
		var label := Label.new()
		label.name = "Label"
		label.text = label_text
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.add_theme_font_size_override("font_size", 8)
		label.add_theme_color_override("font_color", Color(0.88, 0.95, 1.0, 0.92))
		label.position = Vector2(4, 4)
		label.size = Vector2(prop.size.x - 8, maxf(14.0, prop.size.y - 4.0))
		prop.add_child(label)


func _add_v3_hub_polish() -> void:
	if not has_node("/root/AssetManager"):
		return
	match region_id:
		"forgotten_sectors":
			AssetManager.add_v3_environment_decal(self, "archive_seals", Vector2(640, 430), Vector2(520, 390), "V3ForgottenArchiveSeals", -17, Color(0.92, 1.0, 1.0, 0.88))
			AssetManager.add_v3_environment_prop(self, "archive_shelves", Vector2(220, 338), Vector2(270, 164), "V3ForgottenShelfWest", -11)
			AssetManager.add_v3_environment_prop(self, "archive_shelves", Vector2(1046, 340), Vector2(270, 164), "V3ForgottenShelfEast", -11, Color(0.98, 0.99, 1.0, 0.90))
			AssetManager.add_v3_environment_prop(self, "dossier_stack", Vector2(792, 448), Vector2(70, 92), "V3ForgottenDossiers", -10)
			AssetManager.add_v3_environment_prop(self, "null_seal", Vector2(386, 430), Vector2(122, 134), "V3ForgottenFractureSeal", -9, Color(0.96, 1.0, 1.0, 0.92))
		"mirror_city":
			AssetManager.add_v3_environment_decal(self, "mirror_ripples", Vector2(640, 430), Vector2(690, 334), "V3MirrorRipples", -17, Color(0.90, 1.0, 1.0, 0.92))
			AssetManager.add_v3_environment_prop(self, "mirror_plinth", Vector2(640, 414), Vector2(188, 184), "V3MirrorPlinth", -9)
			AssetManager.add_v3_environment_prop(self, "mirror_plinth", Vector2(262, 290), Vector2(122, 118), "V3MirrorShardWest", -11, Color(0.84, 0.94, 1.0, 0.62))
		"cathedral_server":
			AssetManager.add_v3_environment_decal(self, "cathedral_circuit", Vector2(640, 430), Vector2(784, 314), "V3CathedralCircuit", -17, Color(1.0, 0.94, 0.72, 0.88))
			AssetManager.add_v3_environment_prop(self, "server_console", Vector2(348, 390), Vector2(238, 122), "V3CathedralConsole", -10)
			AssetManager.add_v3_environment_prop(self, "firewall_panel", Vector2(874, 418), Vector2(252, 136), "V3CathedralFirewall", -9)
		"memory_ocean":
			AssetManager.add_v3_environment_decal(self, "memory_tide", Vector2(640, 438), Vector2(778, 438), "V3MemoryTide", -17, Color(0.86, 0.98, 1.0, 0.90))
			AssetManager.add_v3_environment_prop(self, "salvage_shelf", Vector2(874, 430), Vector2(230, 152), "V3MemorySalvageShelf", -9)
			AssetManager.add_v3_environment_prop(self, "tide_buoy", Vector2(390, 418), Vector2(88, 130), "V3MemoryTideGauge", -9)
			AssetManager.add_v3_environment_prop(self, "ocean_cache", Vector2(248, 300), Vector2(178, 144), "V3MemoryCache", -11, Color(0.96, 1.0, 1.0, 0.84))
		"saved_assembly":
			AssetManager.add_v3_environment_decal(self, "ironhold_road", Vector2(640, 438), Vector2(728, 196), "V3AssemblyFloorPlates", -17, Color(0.92, 1.0, 0.88, 0.78))
			AssetManager.add_v3_environment_prop(self, "crates", Vector2(316, 344), Vector2(300, 82), "V3AssemblyCratesWest", -10)
			AssetManager.add_v3_environment_prop(self, "crates", Vector2(972, 344), Vector2(300, 82), "V3AssemblyCratesEast", -10, Color(0.98, 1.0, 0.94, 0.88))
		"human_patch_lab":
			AssetManager.add_v3_environment_decal(self, "cathedral_circuit", Vector2(640, 430), Vector2(716, 286), "V3LabFloorCircuit", -17, Color(0.92, 0.98, 1.0, 0.56))
			AssetManager.add_v3_environment_prop(self, "lab_console", Vector2(640, 420), Vector2(220, 158), "V3LabRecordConsole", -9)
			AssetManager.add_v3_environment_prop(self, "memory_tank", Vector2(272, 382), Vector2(126, 140), "V3LabTankWest", -10)
			AssetManager.add_v3_environment_prop(self, "memory_tank", Vector2(1008, 382), Vector2(126, 140), "V3LabTankEast", -10, Color(1.0, 0.86, 0.86, 0.88))
		"root_of_heaven":
			AssetManager.add_v3_environment_decal(self, "root_veins", Vector2(640, 446), Vector2(560, 430), "V3RootVeins", -17, Color(1.0, 0.98, 0.82, 0.72))
			AssetManager.add_v3_environment_prop(self, "root_circuit_rail", Vector2(640, 374), Vector2(650, 148), "V3RootCircuitRail", -10)


func _spawn_player() -> void:
	var player_script = load("res://scripts/exploration/player_topdown.gd")
	if not player_script:
		push_error("[LateRevisitHub] Failed to load player_topdown.gd")
		return

	_player = CharacterBody2D.new()
	_player.name = "Player"
	_player.set_script(player_script)

	var body := ColorRect.new()
	body.name = "BodySprite"
	body.color = Color(0.2, 0.7, 0.9)
	body.size = Vector2(20, 28)
	body.position = Vector2(-10, -28)
	_player.add_child(body)

	var indicator := ColorRect.new()
	indicator.name = "DirectionIndicator"
	indicator.color = Color(0.9, 0.9, 0.2)
	indicator.size = Vector2(6, 6)
	indicator.position = Vector2(-3, -32)
	_player.add_child(indicator)

	var spawn_point := GameManager.get_free_travel_spawn_point(region_id)
	_player.global_position = spawn_point if spawn_point != Vector2.ZERO else DEFAULT_SPAWN
	add_child(_player)

	var camera := Camera2D.new()
	camera.name = "LateHubCamera"
	camera.zoom = Vector2(1.8, 1.8)
	camera.position_smoothing_enabled = true
	camera.position_smoothing_speed = 5.0
	camera.limit_left = 0
	camera.limit_top = 0
	camera.limit_right = int(MAP_SIZE.x)
	camera.limit_bottom = int(MAP_SIZE.y)
	_player.add_child(camera)


func _create_return_gate() -> void:
	var gate := Area2D.new()
	gate.name = "ReturnGate"
	gate.position = Vector2(MAP_SIZE.x * 0.5, MAP_SIZE.y - 40)

	var marker := ColorRect.new()
	marker.color = Color(_theme["accent"].r, _theme["accent"].g, _theme["accent"].b, 0.72)
	marker.position = Vector2(-130, -18)
	marker.size = Vector2(260, 28)
	gate.add_child(marker)

	var label := Label.new()
	label.text = "Return to World Map"
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 13)
	label.add_theme_color_override("font_color", Color(1.0, 1.0, 0.86))
	label.position = Vector2(-120, -40)
	label.size = Vector2(240, 22)
	gate.add_child(label)

	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(280, 58)
	shape.shape = rect
	gate.add_child(shape)
	gate.body_entered.connect(_on_return_gate_body_entered)
	add_child(gate)


func _create_future_marker() -> void:
	var marker := ColorRect.new()
	marker.name = "FutureRoutesMarker"
	marker.color = Color(0.02, 0.02, 0.03, 0.34)
	marker.position = Vector2(522, 112)
	marker.size = Vector2(236, 28)
	add_child(marker)

	var text := Label.new()
	if LATE_FARMING_MARKERS.has(region_id):
		text.text = "Revisit hub. Farming stays local."
	elif SAFE_SIDE_INTERACTIONS.has(region_id):
		text.text = "Revisit hub. Story route stays separate."
	else:
		text.text = "Revisit hub. Story route stays separate."
	text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	text.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	text.add_theme_font_size_override("font_size", 9)
	text.add_theme_color_override("font_color", Color(0.82, 0.86, 0.92))
	text.position = Vector2(8, 3)
	text.size = Vector2(220, 22)
	marker.add_child(text)


func _create_ui() -> void:
	var layer := CanvasLayer.new()
	layer.name = "LateHubUI"
	layer.layer = 10
	add_child(layer)

	var title := Label.new()
	title.text = _theme["title"]
	title.add_theme_font_size_override("font_size", 24)
	title.add_theme_color_override("font_color", _theme["accent"])
	title.position = Vector2(28, 22)
	title.size = Vector2(760, 34)
	layer.add_child(title)

	var subtitle := Label.new()
	subtitle.text = _theme["subtitle"]
	subtitle.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	subtitle.add_theme_font_size_override("font_size", 13)
	subtitle.add_theme_color_override("font_color", Color(0.88, 0.89, 0.92))
	subtitle.position = Vector2(30, 58)
	subtitle.size = Vector2(820, 54)
	layer.add_child(subtitle)

	var controls := Label.new()
	controls.text = "[F] Interact   [M] World Map   South gate returns to overworld   Resume Story continues chapter route"
	controls.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	controls.add_theme_font_size_override("font_size", 11)
	controls.add_theme_color_override("font_color", Color(0.72, 0.76, 0.82))
	controls.position = Vector2(386, 28)
	controls.size = Vector2(866, 20)
	layer.add_child(controls)


func _restore_return_position() -> void:
	if not _player or not GameManager.has_meta("return_position"):
		return
	_player.global_position = GameManager.get_meta("return_position")
	GameManager.remove_meta("return_position")


func _create_optional_content_marker() -> void:
	if LATE_FARMING_MARKERS.has(region_id):
		_create_late_farming_marker(LATE_FARMING_MARKERS[region_id])
		if FARMING_SUPPORT_INTERACTIONS.has(region_id):
			_create_side_marker(FARMING_SUPPORT_INTERACTIONS[region_id])
	elif SAFE_SIDE_INTERACTIONS.has(region_id):
		_create_side_marker(SAFE_SIDE_INTERACTIONS[region_id])


func _create_late_farming_marker(data: Dictionary) -> void:
	var marker := Area2D.new()
	marker.name = "%sMarker" % data.get("zone_id", "LateFarming")
	marker.position = data.get("position", Vector2(640, 430))
	marker.set_meta("farming_zone_id", data.get("zone_id", ""))
	marker.set_meta("marker_data", data.duplicate(true))

	var plate := Polygon2D.new()
	plate.color = data.get("plate_color", Color(0.08, 0.16, 0.24, 0.92))
	plate.polygon = PackedVector2Array([
		Vector2(-50, -18), Vector2(-22, -34), Vector2(34, -28),
		Vector2(54, 4), Vector2(30, 30), Vector2(-38, 24),
	])
	marker.add_child(plate)

	for pulse_pos in [Vector2(-28, -12), Vector2(8, -18), Vector2(20, 8)]:
		var pulse := ColorRect.new()
		pulse.color = Color(_theme["accent"].r, _theme["accent"].g, _theme["accent"].b, 0.84)
		pulse.position = pulse_pos
		pulse.size = Vector2(16, 16)
		pulse.rotation = randf_range(-0.16, 0.16)
		marker.add_child(pulse)

	var label := Label.new()
	label.text = data.get("label", "Late Farming")
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 10)
	label.add_theme_color_override("font_color", Color(1.0, 0.96, 0.76))
	label.position = Vector2(-92, -56)
	label.size = Vector2(184, 20)
	marker.add_child(label)

	var node_note := Label.new()
	node_note.text = data.get("name", "Resource Node")
	node_note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	node_note.add_theme_font_size_override("font_size", 7)
	node_note.add_theme_color_override("font_color", _theme["accent"])
	node_note.position = Vector2(-82, -36)
	node_note.size = Vector2(164, 16)
	marker.add_child(node_note)

	var prompt := Label.new()
	prompt.name = "Prompt"
	prompt.text = data.get("prompt", "[F] Interact")
	prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	prompt.add_theme_font_size_override("font_size", 8)
	prompt.add_theme_color_override("font_color", Color(1.0, 0.92, 0.56))
	prompt.position = Vector2(-84, 34)
	prompt.size = Vector2(168, 18)
	prompt.visible = false
	marker.add_child(prompt)

	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 72.0
	shape.shape = circle
	marker.add_child(shape)
	marker.body_entered.connect(_on_farming_marker_entered.bind(marker))
	marker.body_exited.connect(_on_farming_marker_exited.bind(marker))
	add_child(marker)


func _create_side_marker(data: Dictionary) -> void:
	var marker := Area2D.new()
	marker.name = data.get("name", "SafeSideMarker")
	marker.position = data.get("position", Vector2(640, 430))
	marker.set_meta("side_data", data.duplicate(true))

	var plate := Polygon2D.new()
	plate.color = Color(0.04, 0.04, 0.07, 0.90)
	plate.polygon = PackedVector2Array([
		Vector2(-44, -22), Vector2(-18, -36), Vector2(34, -24),
		Vector2(44, 14), Vector2(12, 32), Vector2(-38, 20),
	])
	marker.add_child(plate)

	var core := ColorRect.new()
	core.color = Color(_theme["accent"].r, _theme["accent"].g, _theme["accent"].b, 0.88)
	core.position = Vector2(-12, -20)
	core.size = Vector2(24, 34)
	marker.add_child(core)

	var label := Label.new()
	label.text = data.get("label", "Safe Marker")
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 10)
	label.add_theme_color_override("font_color", Color(0.94, 0.97, 1.0))
	label.position = Vector2(-96, -58)
	label.size = Vector2(192, 20)
	marker.add_child(label)

	var prompt := Label.new()
	prompt.name = "Prompt"
	prompt.text = data.get("prompt", "[F] Read")
	prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	prompt.add_theme_font_size_override("font_size", 8)
	prompt.add_theme_color_override("font_color", Color(1.0, 0.92, 0.56))
	prompt.position = Vector2(-84, 34)
	prompt.size = Vector2(168, 18)
	prompt.visible = false
	marker.add_child(prompt)

	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 68.0
	shape.shape = circle
	marker.add_child(shape)
	marker.body_entered.connect(_on_side_marker_entered.bind(marker))
	marker.body_exited.connect(_on_side_marker_exited.bind(marker))
	add_child(marker)


func _show_returning_farming_result() -> void:
	if not has_node("/root/RandomEncounterSystem") or not LATE_FARMING_MARKERS.has(region_id):
		return
	var marker_data: Dictionary = LATE_FARMING_MARKERS[region_id]
	RandomEncounterSystem.show_pending_farming_result(marker_data.get("zone_id", ""), self)


func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed("interact"):
		return
	if _near_farming_marker and is_instance_valid(_near_farming_marker):
		_interact_with_late_farming(_near_farming_marker)
		return
	if _near_side_marker and is_instance_valid(_near_side_marker):
		_interact_with_side_marker(_near_side_marker)


func _on_farming_marker_entered(body: Node2D, marker: Area2D) -> void:
	if body.is_in_group("player"):
		_near_farming_marker = marker
		var prompt := marker.get_node_or_null("Prompt")
		if prompt:
			prompt.visible = true


func _on_farming_marker_exited(body: Node2D, marker: Area2D) -> void:
	if body.is_in_group("player") and _near_farming_marker == marker:
		_near_farming_marker = null
		var prompt := marker.get_node_or_null("Prompt")
		if prompt:
			prompt.visible = false


func _on_side_marker_entered(body: Node2D, marker: Area2D) -> void:
	if body.is_in_group("player"):
		_near_side_marker = marker
		var prompt := marker.get_node_or_null("Prompt")
		if prompt:
			prompt.visible = true


func _on_side_marker_exited(body: Node2D, marker: Area2D) -> void:
	if body.is_in_group("player") and _near_side_marker == marker:
		_near_side_marker = null
		var prompt := marker.get_node_or_null("Prompt")
		if prompt:
			prompt.visible = false


func _interact_with_late_farming(marker: Area2D) -> void:
	if not has_node("/root/RandomEncounterSystem"):
		return
	var zone_id: String = marker.get_meta("farming_zone_id", "")
	var marker_data: Dictionary = marker.get_meta("marker_data", {})
	var farming_data: Dictionary = RandomEncounterSystem.get_farming_zone_data(zone_id)
	var run_context := {}
	var should_start := true
	if has_node("/root/DialogueManager"):
		GameManager.change_state(GameManager.GameState.DIALOGUE)
		var choice_result: Dictionary = await _choose_late_farming_run(marker_data, farming_data)
		should_start = choice_result.get("start", false)
		run_context = choice_result.get("context", {})
		GameManager.change_state(GameManager.GameState.EXPLORATION)
	if not should_start:
		return

	var started := RandomEncounterSystem.start_farming_encounter(
		zone_id,
		_player.global_position if _player else marker.global_position,
		get_tree().current_scene.scene_file_path,
		run_context
	)
	if started or not has_node("/root/DialogueManager"):
		return

	var cooldown_seconds := RandomEncounterSystem.get_farming_cooldown_seconds(zone_id)
	GameManager.change_state(GameManager.GameState.DIALOGUE)
	await DialogueManager.say(
		"SYSTEM",
		marker_data.get("cooldown_text", "Re-entry opens in %d seconds.") % cooldown_seconds
	)
	GameManager.change_state(GameManager.GameState.EXPLORATION)


func _choose_late_farming_run(marker_data: Dictionary, farming_data: Dictionary) -> Dictionary:
	var flow_id: String = marker_data.get("flow_id", "")
	match flow_id:
		"forgotten_cleanup":
			await DialogueManager.say(
				"Deleted Case File",
				"The fracture keeps a citizen case in pieces. Seal it carefully: restoration and purge both clear residue, neither rewrites the Null Court route."
			)
			var forgotten_choice = await DialogueManager.show_choices(
				"%s\n%s" % [
					farming_data.get("difficulty_tier", "Late archive cleanup"),
					farming_data.get("objective", "Stabilize the case residue."),
				],
				[
					"Restore the named residue",
					"Purge volatile residue",
					marker_data.get("leave_label", "Leave fracture"),
				]
			)
			if forgotten_choice == 0:
				return {
					"start": true,
					"context": {
						"run_label": "Restore residue",
						"resource_node": "Case Seal",
						"result_text": "A deleted case regains a readable edge. The source record stays outside story mutation.",
					},
				}
			if forgotten_choice == 1:
				return {
					"start": true,
					"context": {
						"run_label": "Purge residue",
						"resource_node": "Archive Seal",
						"result_text": "The volatile residue clears before it can shred another witness line.",
					},
				}
		"cathedral_drill":
			await DialogueManager.say(
				"Firewall Console",
				"Charge-up warning: calibration opens a narrow drill window. The Choir Core trial remains locked to Resume Story."
			)
			var cathedral_choice = await DialogueManager.show_choices(
				"%s\n%s" % [
					farming_data.get("difficulty_tier", "Late doctrine drill"),
					"Calibrate the node, hold the firewall pulse, and let the verifier-grade drill begin.",
				],
				[
					"Start calibration drill",
					marker_data.get("leave_label", "Leave node"),
				]
			)
			if cathedral_choice == 0:
				return {
					"start": true,
					"context": {
						"run_label": "Calibration pulse",
						"resource_node": "Firewall Console",
						"result_text": "The drill cools under a clean buffer seal; doctrine pressure does not touch the Choir Core route.",
					},
				}
		"memory_salvage":
			await DialogueManager.say(
				"Tide Gauge",
				"Tide warning: deeper salvage exposes richer backups and sharper echoes. Retreat is always valid before the pull starts."
			)
			var salvage_choice = await DialogueManager.show_choices(
				"%s\n%s" % [
					farming_data.get("difficulty_tier", "Late tide salvage"),
					farming_data.get("objective", "Choose the salvage depth before the tide commits."),
				],
				[
					"Skim shoreline fragment",
					"Dive tethered backup",
					"Retreat from tide",
				]
			)
			if salvage_choice == 0:
				return {
					"start": true,
					"context": {
						"run_label": "Shoreline skim",
						"resource_node": "Tide Shelf",
						"result_text": "A light fragment clears the surf. The dangerous histories settle below the route line.",
					},
				}
			if salvage_choice == 1:
				return {
					"start": true,
					"context": {
						"run_label": "Tethered dive",
						"resource_node": "Backup Tether",
						"result_text": "The tether brings back salvage, not a replayed Archive Tide choice.",
					},
				}
		_:
			var default_choice = await DialogueManager.show_choices(
				"%s\n%s" % [
					farming_data.get("difficulty_tier", "Late farming"),
					farming_data.get("objective", "Start the repeatable run."),
				],
				[
					marker_data.get("start_label", "Start run"),
					marker_data.get("leave_label", "Leave"),
				]
			)
			if default_choice == 0:
				return {"start": true, "context": {}}
	return {"start": false, "context": {}}


func _interact_with_side_marker(marker: Area2D) -> void:
	var side_data: Dictionary = marker.get_meta("side_data", {})
	if has_node("/root/DialogueManager"):
		GameManager.change_state(GameManager.GameState.DIALOGUE)
		await DialogueManager.say(
			side_data.get("speaker", "Terminal"),
			_get_side_interaction_text(side_data)
		)
		GameManager.change_state(GameManager.GameState.EXPLORATION)
	var lore_id: String = side_data.get("lore_id", "")
	if has_node("/root/LoreJournal") and not lore_id.is_empty():
		LoreJournal.discover(lore_id)


func _get_side_interaction_text(side_data: Dictionary) -> String:
	match side_data.get("kind", ""):
		"mirror_reflection":
			return "%s\n\n%s" % [
				side_data.get("text", "The mirror stays quiet."),
				_get_mirror_choice_reflection(),
			]
		"assembly_supply_board":
			return "%s\n\n%s" % [
				side_data.get("text", "The board stays quiet."),
				_get_supply_board_status(),
			]
		"human_patch_record":
			if GameManager.has_flag("ch9_human_patch_evidence"):
				return "%s\n\nEvidence already exists in the route record. The revisit terminal repeats the warning without changing it." % side_data.get("text", "")
			return "%s\n\nThe route record is still sealed here; Resume Story is the only path that can expose its evidence." % side_data.get("text", "")
		"root_prep_terminal":
			return "%s\n\nChecklist: Source Key %d/7 observed. Return gate stays safe. Final witnesses and ending choices remain Resume Story only." % [
				side_data.get("text", ""),
				GameManager.source_key_count,
			]
	return side_data.get("text", "The marker stays quiet.")


func _get_mirror_choice_reflection() -> String:
	if GameManager.has_flag("ch1_elara_trusted"):
		return "Oakhaven reflection: you trusted Elara early. The mirror records that trust as responsibility, not entitlement."
	if GameManager.has_flag("ch1_elara_cautious"):
		return "Oakhaven reflection: you stayed cautious with Elara. The mirror keeps the hesitation and the care in the same frame."
	if GameManager.has_flag("ch1_elara_distrusted"):
		return "Oakhaven reflection: you withheld trust from Elara. The mirror remembers the distance without forcing a new verdict."
	return "Oakhaven reflection is incomplete. The mirror marks missing choice evidence instead of inventing it."


func _get_supply_board_status() -> String:
	if not has_node("/root/Inventory") or not Inventory.has_method("get_item_count"):
		return "The civic ledger stays observational in this revisit buffer; no supply is taken."
	return "Current carried repair stock: Data Ore x%d, Memory Shards x%d. The board notes shortages, but it accepts no material mutation here." % [
		Inventory.get_item_count("data_ore"),
		Inventory.get_item_count("memory_shard"),
	]


func _on_return_gate_body_entered(body: Node2D) -> void:
	if not body.is_in_group("player"):
		return
	if has_node("/root/SceneTransitions"):
		SceneTransitions.change_scene(OVERWORLD_SCENE)
	else:
		get_tree().change_scene_to_file(OVERWORLD_SCENE)
