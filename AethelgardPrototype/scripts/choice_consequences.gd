extends Node
## ==========================================================================
## CHOICE CONSEQUENCES — Gameplay-altering buffs/debuffs from story choices
## ==========================================================================
## Autoload singleton: ChoiceConsequences
## Tracks which choices the player made and applies REAL gameplay effects:
##   - Stat bonuses/penalties
##   - Unlocked abilities
##   - Combat modifiers
##   - Party member combat contributions
## ==========================================================================

signal buff_applied(buff_id: String)
signal buff_removed(buff_id: String)  # Pass 59: Removed @warning_ignore — will emit on clear
signal party_member_action(member: String, action: String)

# ── Active Buffs ──────────────────────────────────────────────────────
# Each buff: {"id": String, "source": String, "stat_mods": {}, "ability": String, "description": String}
var active_buffs: Array[Dictionary] = []
var party_combat_members: Array[String] = []  # NPCs that assist in combat

# ── Buff Definitions ─────────────────────────────────────────────────
# These map story choices to actual gameplay effects
const CHOICE_BUFFS: Dictionary = {
	# ── Chapter 1: Tutorial Knight Choice ──
	"ch1_knight_spared": {
		"id": "guardian_blessing",
		"stat_mods": {"defense": 5, "max_hp": 15},
		"ability": "knight_rally",
		"description": "Aldric's Blessing: +5 DEF, +15 Max HP. Aldric may rally to your aid in boss fights.",
	},
	"ch1_knight_killed": {
		"id": "executioner_edge",
		"stat_mods": {"attack": 8, "soul_gain_bonus": 0.2},
		"ability": "death_strike",
		"description": "Executioner's Edge: +8 ATK, +20% Soul gain. Unlocks Death Strike (double crit on enemies below 25% HP).",
	},
	# Note: ch1_knight_spared via Root Access purge gives BOTH guardian_blessing AND root_mastery
	"ch1_root_purge_used": {
		"id": "root_mastery",
		"stat_mods": {"max_hp": -10},
		"ability": "deep_purge",
		"description": "Root Mastery: -10 Max HP (corruption cost), but Root Access hacks cost 30% less corruption.",
	},

	# ── Chapter 1: Elara Trust Choice ──
	"ch1_elara_trusted": {
		"id": "elara_bond_strong",
		"stat_mods": {"max_hp": 10, "defense": 3},
		"ability": "glitch_shield",
		"description": "Elara's Trust: +10 Max HP, +3 DEF. Elara casts Glitch Shield in combat (blocks 1 hit every 30s).",
	},
	"ch1_elara_cautious": {
		"id": "elara_bond_wary",
		"stat_mods": {"attack": 3},
		"ability": "data_scan",
		"description": "Cautious Alliance: +3 ATK. Elara reveals enemy HP bars and weaknesses.",
	},
	"ch1_elara_distrusted": {
		"id": "lone_wolf",
		"stat_mods": {"attack": 5, "base_defense": -3},
		"ability": "self_reliance",
		"description": "Lone Wolf: +5 ATK, -3 DEF. Solo combat XP increased by 25%.",
	},

	# ── Chapter 2: Seraphina Choice ──
	"ch2_seraphina_recruited": {
		"id": "seraphina_fighter",
		"stat_mods": {"attack": 5, "defense": 3},
		"ability": "arena_combo",
		"description": "Arena Champion: +5 ATK, +3 DEF. Seraphina assists in combat with combo attacks.",
	},
	"ch2_seraphina_stayed": {
		"id": "ironhold_defender",
		"stat_mods": {"defense": 8},
		"ability": "ironhold_supplies",
		"description": "Ironhold Defender: +8 DEF. Seraphina sends supply drops (+2 potions per chapter).",
	},
	"ch2_seraphina_rejected": {
		"id": "hardened_heart",
		"stat_mods": {"attack": 6, "soul_gain_bonus": 0.15},
		"ability": "cold_fury",
		"description": "Hardened Heart: +6 ATK, +15% Soul gain. Soul spells deal 20% more damage.",
	},

	# ── Chapter 2: Data Wraith Choice ──
	"ch2_data_wraith_absorbed": {
		"id": "wraith_power",
		"stat_mods": {"attack": 10, "max_hp": -15},
		"ability": "wraith_dash",
		"description": "Wraith Absorption: +10 ATK, -15 Max HP. Dash phases through enemies dealing damage.",
	},
	"ch2_data_wraith_restored": {
		"id": "wraith_gratitude",
		"stat_mods": {"defense": 5, "max_hp": 10},
		"ability": "spectral_aid",
		"description": "Wraith's Gratitude: +5 DEF, +10 Max HP. Spectral ally occasionally blocks attacks.",
	},
	"ch2_data_wraith_destroyed": {
		"id": "clean_deletion",
		"stat_mods": {"attack": 4, "defense": 4},
		"ability": "efficient_delete",
		"description": "Clean Code: +4 ATK, +4 DEF. Perfect Delete recharges 25% faster.",
	},

	# ── Chapter 3: Lyra Choice ──
	"ch3_lyra_recruited": {
		"id": "ranger_ally",
		"stat_mods": {"attack": 3},
		"ability": "ranged_support",
		"description": "Lyra's Bow: +3 ATK. Lyra fires ranged support shots in combat (15 dmg every 5s).",
	},
	"ch3_lyra_left_alone": {
		"id": "storm_navigator",
		"stat_mods": {"defense": 5},
		"ability": "storm_resistance",
		"description": "Storm Navigator: +5 DEF. 30% reduced environmental damage. Storm map reveals hidden paths.",
	},

	# ── Chapter 3: Kaelthas Choice ──
	"ch3_kaelthas_allied": {
		"id": "forbidden_knowledge",
		"stat_mods": {"attack": -3},
		"ability": "enemy_weakness",
		"description": "Forbidden Knowledge: -3 ATK (trust exploited). But enemy HP reduced by 15% (Kaelthas's intel).",
	},
	"ch3_kaelthas_refused": {
		"id": "independent_mind",
		"stat_mods": {"defense": 5, "attack": 3},
		"ability": "mental_fortitude",
		"description": "Independent Mind: +5 DEF, +3 ATK. Immune to confusion/charm effects.",
	},
	"ch3_kaelthas_challenged": {
		"id": "battle_tested",
		"stat_mods": {"attack": 6, "max_hp": 10},
		"ability": "code_breaker",
		"description": "Battle-Tested: +6 ATK, +10 Max HP. Root Access attacks deal 25% more damage to bosses.",
	},
}

# ── Passive Combat Abilities (checked by combat system) ──────────────
const ABILITY_DESCRIPTIONS: Dictionary = {
	"knight_rally": "Aldric rallies to your aid — deals 30 damage to boss at 50% HP",
	"death_strike": "Enemies below 25% HP take double critical damage",
	"deep_purge": "Root Access hacks cost 30% less corruption",
	"glitch_shield": "Elara's shield blocks one hit every 30 seconds",
	"data_scan": "Enemy HP bars and weaknesses always visible",
	"self_reliance": "Solo XP gain +25%",
	"arena_combo": "Seraphina strikes with you for +15 bonus damage on combos",
	"ironhold_supplies": "+2 health potions at chapter start",
	"cold_fury": "Soul spells deal 20% more damage",
	"wraith_dash": "Dash deals 12 damage to enemies you phase through",
	"spectral_aid": "Spectral ally blocks 1 attack every 20s",
	"efficient_delete": "Perfect Delete recharges 25% faster",
	"ranged_support": "Lyra fires 15 damage shots every 5 seconds",
	"storm_resistance": "30% less environmental damage",
	"enemy_weakness": "All enemies have 15% less HP",
	"mental_fortitude": "Immune to stun/confusion effects",
	"code_breaker": "Root Access deals 25% more damage to bosses",
}


# ══════════════════════════════════════════════════════════════════════
# LIFECYCLE
# ══════════════════════════════════════════════════════════════════════

func _ready() -> void:
	# Listen for story flag changes to apply consequences
	if has_node("/root/GameManager") and GameManager:
		GameManager.story_flag_updated.connect(_on_story_flag_updated)

func _on_story_flag_updated(flag_name: String, value: bool) -> void:
	if not value:
		return
	if CHOICE_BUFFS.has(flag_name):
		apply_choice_buff(flag_name)

	# Track party members for combat assist
	match flag_name:
		"ch2_seraphina_recruited":
			if "seraphina" not in party_combat_members:
				party_combat_members.append("seraphina")
		"ch3_lyra_recruited":
			if "lyra" not in party_combat_members:
				party_combat_members.append("lyra")
		"ch1_elara_trusted", "ch1_elara_cautious":
			if "elara" not in party_combat_members:
				party_combat_members.append("elara")


# ══════════════════════════════════════════════════════════════════════
# BUFF APPLICATION
# ══════════════════════════════════════════════════════════════════════

func apply_choice_buff(flag_name: String) -> void:
	var buff_data: Dictionary = CHOICE_BUFFS[flag_name]
	var buff_id: String = buff_data["id"]

	# Don't apply duplicates
	for existing in active_buffs:
		if existing["id"] == buff_id:
			return

	var buff: Dictionary = buff_data.duplicate(true)
	buff["source_flag"] = flag_name
	active_buffs.append(buff)

	# Apply stat modifications
	var mods: Dictionary = buff.get("stat_mods", {})
	for stat_name in mods:
		var mod_value = mods[stat_name]
		match stat_name:
			"attack":
				GameManager.player_stats["attack"] = GameManager.player_stats.get("attack", 15) + mod_value
				GameManager.player_stats["base_attack"] = GameManager.player_stats.get("base_attack", 15) + mod_value
			"defense":
				GameManager.player_stats["defense"] = GameManager.player_stats.get("defense", 0) + mod_value
				GameManager.player_stats["base_defense"] = GameManager.player_stats.get("base_defense", 0) + mod_value
			"max_hp":
				GameManager.player_stats["max_hp"] = GameManager.player_stats.get("max_hp", 100) + mod_value
				if mod_value > 0:
					GameManager.player_stats["hp"] = min(
						GameManager.player_stats.get("hp", 100) + mod_value,
						GameManager.player_stats.get("max_hp", 100)
					)
			"max_mp":
				GameManager.player_stats["max_mp"] = GameManager.player_stats.get("max_mp", 50) + mod_value
			"soul_gain_bonus":
				GameManager.player_stats["soul_gain_bonus"] = GameManager.player_stats.get("soul_gain_bonus", 0.0) + mod_value

	print("[CHOICE-FX] Applied buff: %s — %s" % [buff_id, buff.get("description", "")])
	buff_applied.emit(buff_id)

	# Show notification to player
	_show_buff_notification(buff)


# ══════════════════════════════════════════════════════════════════════
# COMBAT QUERIES — Called by player_combat.gd and enemy_base.gd
# ══════════════════════════════════════════════════════════════════════

func get_total_stat_mods() -> Dictionary:
	## Returns a dictionary of all stat modifications from active buffs
	var result: Dictionary = {}
	for buff in active_buffs:
		var mods: Dictionary = buff.get("stat_mods", {})
		for key in mods:
			result[key] = result.get(key, 0.0) + mods[key]
	return result

func has_ability(ability_name: String) -> bool:
	for buff in active_buffs:
		if buff.get("ability", "") == ability_name:
			return true
	return false

func get_stat_modifier(stat_name: String) -> float:
	## Returns total stat modification from all active buffs
	var total: float = 0.0
	for buff in active_buffs:
		var mods: Dictionary = buff.get("stat_mods", {})
		total += mods.get(stat_name, 0.0)
	return total

func get_soul_gain_multiplier() -> float:
	## Returns total soul gain multiplier (1.0 = normal)
	var bonus: float = 0.0
	for buff in active_buffs:
		var mods: Dictionary = buff.get("stat_mods", {})
		bonus += mods.get("soul_gain_bonus", 0.0)
	return 1.0 + bonus

func get_spell_damage_multiplier() -> float:
	## Cold Fury: soul spells deal 20% more damage
	if has_ability("cold_fury"):
		return 1.2
	return 1.0

func get_enemy_hp_multiplier() -> float:
	## Forbidden Knowledge (Kaelthas allied): enemies have 15% less HP
	if has_ability("enemy_weakness"):
		return 0.85
	return 1.0

func get_xp_multiplier() -> float:
	## Lone Wolf: solo XP increased by 25%
	if has_ability("self_reliance") and party_combat_members.size() == 0:
		return 1.25
	return 1.0

func get_root_access_corruption_multiplier() -> float:
	## Root Mastery: hacks cost 30% less corruption
	if has_ability("deep_purge"):
		return 0.7
	return 1.0

func get_boss_damage_multiplier() -> float:
	## Code Breaker: Root Access deals 25% more to bosses
	if has_ability("code_breaker"):
		return 1.25
	return 1.0

func should_death_strike(enemy_hp_pct: float) -> bool:
	## Executioner's Edge: double crit below 25% HP
	return has_ability("death_strike") and enemy_hp_pct < 0.25

func is_immune_to_stun() -> bool:
	## Mental Fortitude: immune to stun/confusion
	return has_ability("mental_fortitude")

func get_dash_damage() -> float:
	## Wraith Dash: dash deals 12 damage
	if has_ability("wraith_dash"):
		return 12.0
	return 0.0

func get_environmental_damage_multiplier() -> float:
	## Storm Resistance: 30% less environmental damage
	if has_ability("storm_resistance"):
		return 0.7
	return 1.0


# ══════════════════════════════════════════════════════════════════════
# PARTY COMBAT ASSIST — Timed NPC actions during combat
# ══════════════════════════════════════════════════════════════════════

var _party_cooldowns: Dictionary = {}  # member_name: float (seconds until next action)

func tick_party_combat(delta: float, player_node: Node = null) -> void:
	## Called each frame during combat to trigger party member assists
	for member in party_combat_members:
		_party_cooldowns[member] = _party_cooldowns.get(member, 0.0) - delta
		if _party_cooldowns[member] <= 0.0:
			_trigger_party_action(member, player_node)

func _trigger_party_action(member: String, player_node: Node) -> void:
	match member:
		"elara":
			if has_ability("glitch_shield"):
				_party_cooldowns["elara"] = 30.0
				party_member_action.emit("elara", "glitch_shield")
				if player_node and player_node.has_method("apply_shield"):
					player_node.apply_shield(1)
				print("[PARTY] Elara casts Glitch Shield!")
			elif has_ability("data_scan"):
				_party_cooldowns["elara"] = 20.0
				party_member_action.emit("elara", "data_scan")
				print("[PARTY] Elara scans enemy weaknesses!")
		"seraphina":
			if has_ability("arena_combo"):
				_party_cooldowns["seraphina"] = 8.0
				party_member_action.emit("seraphina", "arena_combo")
				print("[PARTY] Seraphina strikes for 15 bonus damage!")
		"lyra":
			if has_ability("ranged_support"):
				_party_cooldowns["lyra"] = 5.0
				party_member_action.emit("lyra", "ranged_support")
				print("[PARTY] Lyra fires a support shot for 15 damage!")

func reset_party_cooldowns() -> void:
	_party_cooldowns.clear()


# ══════════════════════════════════════════════════════════════════════
# SUPPLY DROPS — Chapter start bonus items
# ══════════════════════════════════════════════════════════════════════

func apply_chapter_start_supplies() -> void:
	## Called when entering a new chapter — provides bonus items from choices
	if has_ability("ironhold_supplies"):
		if has_node("/root/Inventory"):
			Inventory.add_item("health_potion", 2)
			print("[CHOICE-FX] Seraphina sent 2 health potions!")
			_show_supply_notification("Seraphina's Supply Drop: +2 Health Potions")


# ══════════════════════════════════════════════════════════════════════
# NOTIFICATIONS
# ══════════════════════════════════════════════════════════════════════

func _show_buff_notification(buff: Dictionary) -> void:
	## Show a floating notification when a buff is applied
	var notif = Label.new()
	notif.text = "CHOICE EFFECT: %s" % buff.get("description", "Unknown effect")
	notif.add_theme_font_size_override("font_size", 14)
	notif.add_theme_color_override("font_color", Color(1.0, 0.85, 0.3))
	notif.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	notif.position = Vector2(200, 620)
	notif.z_index = 100

	var viewport = get_viewport()
	if viewport and viewport.get_window():
		get_tree().root.add_child(notif)
		var tw = create_tween()
		tw.tween_property(notif, "position:y", 550, 2.0).set_trans(Tween.TRANS_SINE)
		tw.parallel().tween_property(notif, "modulate:a", 0.0, 2.0).set_delay(3.0)
		tw.tween_callback(notif.queue_free)

func _show_supply_notification(text: String) -> void:
	var notif = Label.new()
	notif.text = text
	notif.add_theme_font_size_override("font_size", 16)
	notif.add_theme_color_override("font_color", Color(0.3, 1.0, 0.5))
	notif.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	notif.position = Vector2(300, 620)
	notif.z_index = 100

	get_tree().root.add_child(notif)
	var tw = create_tween()
	tw.tween_property(notif, "position:y", 560, 1.5)
	tw.parallel().tween_property(notif, "modulate:a", 0.0, 2.0).set_delay(3.5)
	tw.tween_callback(notif.queue_free)


# ══════════════════════════════════════════════════════════════════════
# SAVE / LOAD
# ══════════════════════════════════════════════════════════════════════

func get_save_data() -> Dictionary:
	return {
		"active_buffs": active_buffs.duplicate(true),
		"party_combat_members": party_combat_members.duplicate(),
	}

func load_save_data(data: Dictionary) -> void:
	# Pass 59: Emit buff_removed for each buff before clearing
	for buff in active_buffs:
		buff_removed.emit(buff.get("id", ""))
	active_buffs.clear()
	var saved_buffs = data.get("active_buffs", [])
	if saved_buffs is Array:
		for buff in saved_buffs:
			if buff is Dictionary and buff.has("id"):
				active_buffs.append(buff)
	party_combat_members.clear()
	var saved_party = data.get("party_combat_members", [])
	if saved_party is Array:
		for member in saved_party:
			if member is String and member not in party_combat_members:
				party_combat_members.append(member)
	_party_cooldowns.clear()

func rebuild_from_flags() -> void:
	## Reconstruct active_buffs and party_combat_members from story flags.
	## Does NOT re-apply stat mods (they are already baked into player_stats).
	## Used as fallback when loading older saves without choice_consequences data.
	active_buffs.clear()
	party_combat_members.clear()
	_party_cooldowns.clear()
	for flag_name in CHOICE_BUFFS.keys():
		if GameManager.story_flags.get(flag_name, false):
			var buff_data: Dictionary = CHOICE_BUFFS[flag_name]
			var buff: Dictionary = buff_data.duplicate(true)
			buff["source_flag"] = flag_name
			active_buffs.append(buff)
	# Rebuild party members
	if GameManager.story_flags.get("ch1_elara_trusted", false) or GameManager.story_flags.get("ch1_elara_cautious", false):
		if "elara" not in party_combat_members:
			party_combat_members.append("elara")
	if GameManager.story_flags.get("ch2_seraphina_recruited", false):
		if "seraphina" not in party_combat_members:
			party_combat_members.append("seraphina")
	if GameManager.story_flags.get("ch3_lyra_recruited", false):
		if "lyra" not in party_combat_members:
			party_combat_members.append("lyra")
	if OS.is_debug_build():
		print("[CHOICE-FX] Rebuilt %d buffs and %d party members from flags" % [active_buffs.size(), party_combat_members.size()])

func get_active_buff_summary() -> String:
	## Returns a formatted string of all active buffs for the status window
	if active_buffs.is_empty():
		return "No choice effects active."
	var lines: Array[String] = []
	for buff in active_buffs:
		lines.append("• %s" % buff.get("description", buff.get("id", "Unknown")))
	return "\n".join(lines)
