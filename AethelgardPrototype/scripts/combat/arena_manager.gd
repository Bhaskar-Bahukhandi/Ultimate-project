extends Node
class_name ArenaManager

## Arena Manager — Wave-based combat encounters for the Battle Arena.
## Handles tier progression, wave composition, rewards, and announcer dialogue.
## Supports 3 modes: Standard (4 tiers), Time Attack, and Endurance.

signal wave_started(wave_number: int, tier: String)
signal wave_completed(wave_number: int)
signal arena_victory(tier: String)
signal arena_defeat
signal enemy_spawned(enemy: EnemyBase)
signal all_enemies_cleared
signal time_attack_tick(time_left: float)
signal endurance_wave_record(wave: int)

# ── Active run state ────────────────────────────────────────────────────
var current_tier: String = "bronze"
var current_wave: int = 0
var total_waves: int = 3
var enemies_alive: int = 0
var arena_active: bool = false
var spawn_container: Node2D = null
var arena_bounds: Rect2 = Rect2(100, 300, 1080, 200)

# ── Challenge mode state ──────────────────────────────────────────────
enum ArenaMode { STANDARD, TIME_ATTACK, ENDURANCE }
var current_mode: ArenaMode = ArenaMode.STANDARD
var _time_attack_remaining: float = 0.0
var _time_attack_total: float = 0.0
var _endurance_best_wave: int = 0
var _is_processing_timer: bool = false

# ── Tier definitions ────────────────────────────────────────────────────
const TIER_DATA = {
	"bronze": {
		"waves": 3,
		"enemy_types": ["corrupted_rat", "glitch_wolf"],
		"base_count": 2, "count_increase": 1,
		"xp_bonus": 0, "gold_bonus": 0,
		"required_level": 1
	},
	"silver": {
		"waves": 4,
		"enemy_types": ["corrupted_guard", "data_sprite"],
		"base_count": 2, "count_increase": 1,
		"xp_bonus": 20, "gold_bonus": 10,
		"required_level": 3
	},
	"gold": {
		"waves": 5,
		"enemy_types": ["clockwork_soldier", "shadow_wraith"],
		"base_count": 2, "count_increase": 1,
		"xp_bonus": 50, "gold_bonus": 25,
		"required_level": 5
	},
	"platinum": {
		"waves": 5,
		"enemy_types": ["clockwork_soldier", "shadow_wraith", "corrupted_guard"],
		"base_count": 3, "count_increase": 1,
		"xp_bonus": 100, "gold_bonus": 50,
		"required_level": 7
	}
}

# ── Time Attack config ─────────────────────────────────────────────────
const TIME_ATTACK_CONFIG = {
	"bronze":   {"time": 60.0, "bonus_per_sec": 2},   # 60s, 2xp per sec left
	"silver":   {"time": 75.0, "bonus_per_sec": 3},
	"gold":     {"time": 90.0, "bonus_per_sec": 5},
	"platinum": {"time": 100.0, "bonus_per_sec": 8},
}

# ── Endurance config ───────────────────────────────────────────────────
const ENDURANCE_ENEMY_POOL: Array = [
	"corrupted_rat", "glitch_wolf", "corrupted_guard", "data_sprite",
	"clockwork_soldier", "shadow_wraith", "phase_spider", "gear_sentry",
	"corruption_elemental", "mushroom_mimic"
]
const ENDURANCE_BASE_COUNT: int = 2
const ENDURANCE_XP_PER_WAVE: int = 30
const ENDURANCE_GOLD_PER_WAVE: int = 15

# ── Announcer lines ─────────────────────────────────────────────────────
const ANNOUNCER = {
	"wave_start": [
		"Round %d! Let's see what you've got!",
		"Wave %d incoming! Stay sharp!",
		"Here they come! Wave %d!",
		"Round %d — the crowd wants BLOOD!"
	],
	"wave_clear": [
		"Wave cleared! Impressive!",
		"That's how it's done! Next wave!",
		"They didn't stand a chance!",
		"The crowd goes wild!"
	],
	"victory": [
		"VICTORY! What a fighter!",
		"Unbelievable! A flawless performance!",
		"The champion of the arena!",
		"Nobody can stop this warrior!"
	],
	"defeat": [
		"Down goes the challenger!",
		"Better luck next time, fighter.",
		"The arena claims another..."
	],
	"tier_bronze":   ["Bronze tier — where legends begin!", "Welcome to the pit, rookie!"],
	"tier_silver":   ["Silver tier! Things get real from here!", "The silver bracket — only the skilled survive!"],
	"tier_gold":     ["GOLD TIER! The elite proving grounds!", "Gold bracket — prepare for pain!"],
	"tier_platinum": ["PLATINUM! Only the greatest dare enter!", "The platinum crucible — no mercy!"]
}


# ═════════════════════════════════════════════════════════════════════════
# PUBLIC API
# ═════════════════════════════════════════════════════════════════════════

func setup(container: Node2D, bounds: Rect2 = Rect2()) -> void:
	## Initialise arena with a spawn container and optional bounds.
	spawn_container = container
	if bounds.size.x > 0:
		arena_bounds = bounds


func start_arena(tier: String) -> void:
	## Begin a new arena run at the given tier.
	if arena_active:
		return

	var info: Dictionary = TIER_DATA.get(tier, {})
	if info.is_empty():
		push_error("[ARENA] Unknown tier: %s" % tier)
		return

	# Level gate
	if _has_gm() and GameManager.player_stats["level"] < info["required_level"]:
		if _has_dm():
			await DialogueManager.say("Vex",
				"Hold up, fighter! You need to be at least Level %d for the %s bracket. Come back when you've trained more!" \
				% [info["required_level"], tier.capitalize()])
			if not is_inside_tree():
				return
		return

	current_mode = ArenaMode.STANDARD
	current_tier = tier
	total_waves = info["waves"]
	current_wave = 0
	arena_active = true

	# Announcer intro
	var lines: Array = ANNOUNCER.get("tier_" + tier, ["Let's fight!"])
	if _has_dm():
		await DialogueManager.say("Vex", lines[randi() % lines.size()])
		if not is_inside_tree():
			return

	await get_tree().create_timer(1.0, false).timeout
	if not is_inside_tree():
		return
	_start_next_wave()


func abort_arena() -> void:
	## End the arena run early.
	arena_active = false
	_is_processing_timer = false
	_cleanup_enemies()
	if _has_gm():
		GameManager.record_arena_loss()

	# Endurance: show how far they got and award scaled rewards
	if current_mode == ArenaMode.ENDURANCE and _has_dm():
		var end_xp = _endurance_best_wave * ENDURANCE_XP_PER_WAVE
		var end_gold = _endurance_best_wave * ENDURANCE_GOLD_PER_WAVE
		if _has_gm():
			GameManager.add_xp(end_xp)
			GameManager.add_gold(end_gold)
		await DialogueManager.say("Vex", "DOWN at wave %d! Still, what a performance!" % _endurance_best_wave)
		if is_inside_tree():
			await DialogueManager.say("Vex", "Endurance reward: +%d XP, +%d Gold" % [end_xp, end_gold], Color(1, 0.85, 0.1), true)
		arena_defeat.emit()
		return

	if _has_dm():
		var lines: Array = ANNOUNCER["defeat"]
		await DialogueManager.say("Vex", lines[randi() % lines.size()])
		if not is_inside_tree():
			return
	arena_defeat.emit()


func get_tier_info(tier: String) -> Dictionary:
	return TIER_DATA.get(tier, {})


func is_tier_available(tier: String) -> bool:
	var info = TIER_DATA.get(tier, {})
	if not _has_gm():
		return false
	return GameManager.player_stats["level"] >= info.get("required_level", 99)


## ─── TIME ATTACK MODE ──────────────────────────────────────────────────

func start_time_attack(tier: String) -> void:
	## Standard tier but with a countdown — bonus rewards for time remaining.
	if arena_active:
		return
	var info: Dictionary = TIER_DATA.get(tier, {})
	if info.is_empty():
		return
	if _has_gm() and GameManager.player_stats["level"] < info["required_level"]:
		if _has_dm():
			await DialogueManager.say("Vex", "You need Level %d for Time Attack %s!" % [info["required_level"], tier.capitalize()])
		return

	current_mode = ArenaMode.TIME_ATTACK
	var ta_config = TIME_ATTACK_CONFIG.get(tier, {"time": 60.0, "bonus_per_sec": 2})
	_time_attack_remaining = ta_config["time"]
	_time_attack_total = ta_config["time"]

	current_tier = tier
	total_waves = info["waves"]
	current_wave = 0
	arena_active = true

	if _has_dm():
		await DialogueManager.say("Vex", "TIME ATTACK! %s tier — you have %.0f seconds! GO GO GO!" % [tier.capitalize(), _time_attack_total])
		if not is_inside_tree(): return

	_is_processing_timer = true
	await get_tree().create_timer(0.5, false).timeout
	if not is_inside_tree(): return
	_start_next_wave()


func _process(delta: float) -> void:
	if not _is_processing_timer or current_mode != ArenaMode.TIME_ATTACK:
		return
	if not arena_active:
		_is_processing_timer = false
		return
	_time_attack_remaining -= delta
	time_attack_tick.emit(_time_attack_remaining)
	if _time_attack_remaining <= 0.0:
		_is_processing_timer = false
		_time_attack_timeout()


func _time_attack_timeout() -> void:
	arena_active = false
	_cleanup_enemies()
	if _has_dm():
		await DialogueManager.say("Vex", "TIME'S UP! So close! Better luck next time, fighter!")
		if not is_inside_tree(): return
	arena_defeat.emit()


## ─── ENDURANCE MODE ────────────────────────────────────────────────────

func start_endurance() -> void:
	## Infinite waves of increasing difficulty. Lasts until player dies.
	if arena_active:
		return
	if _has_gm() and GameManager.player_stats["level"] < 5:
		if _has_dm():
			await DialogueManager.say("Vex", "Endurance mode? You need at least Level 5 for that, rookie!")
		return

	current_mode = ArenaMode.ENDURANCE
	current_tier = "endurance"
	current_wave = 0
	total_waves = 9999  # Effectively infinite
	arena_active = true
	_endurance_best_wave = 0

	if _has_dm():
		await DialogueManager.say("Vex", "ENDURANCE MODE! How long can you survive? The crowd wants to know!")
		if not is_inside_tree(): return

	await get_tree().create_timer(1.0, false).timeout
	if not is_inside_tree(): return
	_start_next_wave()


func _get_endurance_wave_enemies() -> Array:
	## Returns enemy types and count for the current endurance wave.
	var wave = current_wave
	var count = ENDURANCE_BASE_COUNT + int(wave / 2)  # +1 enemy every 2 waves
	count = mini(count, 8)  # Cap at 8 enemies

	# Unlock harder enemies as waves progress
	var pool_size = mini(4 + int(wave / 3), ENDURANCE_ENEMY_POOL.size())
	var available = ENDURANCE_ENEMY_POOL.slice(0, pool_size)

	var enemies: Array = []
	for i in count:
		enemies.append(available[randi() % available.size()])
	return enemies


# ═════════════════════════════════════════════════════════════════════════
# WAVE MANAGEMENT
# ═════════════════════════════════════════════════════════════════════════

func _start_next_wave() -> void:
	if not arena_active:
		return

	current_wave += 1

	# Endurance mode: infinite waves
	if current_mode == ArenaMode.ENDURANCE:
		var endurance_enemies = _get_endurance_wave_enemies()
		enemies_alive = endurance_enemies.size()

		if current_wave > _endurance_best_wave:
			_endurance_best_wave = current_wave
			endurance_wave_record.emit(current_wave)

		# Per-wave endurance rewards
		if _has_gm():
			var wave_xp = ENDURANCE_XP_PER_WAVE + (current_wave * 5)
			var wave_gold = ENDURANCE_GOLD_PER_WAVE + (current_wave * 3)
			GameManager.add_xp(wave_xp)
			GameManager.add_gold(wave_gold)

		if _has_dm():
			if current_wave % 5 == 0:
				await DialogueManager.say("Vex", "WAVE %d! The crowd is going INSANE!" % current_wave, Color(-1, -1, -1), true)
			else:
				var lines: Array = ANNOUNCER["wave_start"]
				await DialogueManager.say("Vex", lines[randi() % lines.size()] % current_wave, Color(-1, -1, -1), true)
			if not is_inside_tree(): return

		wave_started.emit(current_wave, "endurance")

		for etype in endurance_enemies:
			var pos = Vector2(
				randf_range(arena_bounds.position.x, arena_bounds.position.x + arena_bounds.size.x),
				arena_bounds.position.y
			)
			if not arena_active: return
			_spawn_enemy(etype, pos)
			await get_tree().create_timer(0.25, false).timeout
			if not is_inside_tree(): return
		return

	# Standard / Time Attack: use tier data
	if not TIER_DATA.has(current_tier):
		_arena_win()
		return

	if current_wave > total_waves:
		_arena_win()
		return

	var info: Dictionary = TIER_DATA[current_tier]
	var count: int = info["base_count"] + (current_wave - 1) * info["count_increase"]
	enemies_alive = count

	# Announcer
	if _has_dm():
		var lines: Array = ANNOUNCER["wave_start"]
		var line: String = lines[randi() % lines.size()] % current_wave
		await DialogueManager.say("Vex", line, Color(-1, -1, -1), true)
		if not is_inside_tree():
			return

	wave_started.emit(current_wave, current_tier)

	# Spawn enemies
	var types: Array = info["enemy_types"]
	for i in count:
		# Stop spawning into an arena that was aborted or timed out mid-wave.
		if not arena_active:
			return
		var etype: String = types[randi() % types.size()]
		var pos = Vector2(
			randf_range(arena_bounds.position.x, arena_bounds.position.x + arena_bounds.size.x),
			arena_bounds.position.y
		)
		_spawn_enemy(etype, pos)
		await get_tree().create_timer(0.3, false).timeout
		if not is_inside_tree():
			return

	# Safety: skip if no enemies actually spawned
	if enemies_alive <= 0:
		push_warning("[ARENA] All enemies failed to spawn — skipping wave")
		all_enemies_cleared.emit()
		await get_tree().create_timer(1.0, false).timeout
		if not is_inside_tree():
			return
		_start_next_wave()


func _spawn_enemy(etype: String, pos: Vector2) -> void:
	var enemy: EnemyBase = _make_enemy(etype)
	if not enemy:
		push_error("[ARENA] Failed to create enemy: %s" % etype)
		enemies_alive -= 1
		return

	enemy.global_position = pos
	var parent: Node = spawn_container if spawn_container else get_parent()
	parent.add_child(enemy)

	_setup_enemy_visual(enemy, etype)

	enemy.died.connect(_on_enemy_died)
	enemy.health_changed.connect(func(hp: float, max_hp: float) -> void:
		var hb = enemy.get_node_or_null("HealthBar") as ProgressBar
		if hb and max_hp > 0:
			hb.value = (hp / max_hp) * 100.0
	)

	enemy_spawned.emit(enemy)
	if has_node("/root/VFXLibrary"):
		VFXLibrary.spawn("vfx_glitch_sparkle", pos, parent)


func _make_enemy(etype: String) -> EnemyBase:
	var enemy: EnemyBase = null
	match etype:
		"corrupted_rat":         enemy = CorruptedRat.new()
		"glitch_wolf":           enemy = GlitchWolf.new()
		"corrupted_guard":       enemy = CorruptedGuard.new()
		"data_sprite":           enemy = DataSprite.new()
		"clockwork_soldier":     enemy = ClockworkSoldier.new()
		"shadow_wraith":         enemy = ShadowWraith.new()
		"phase_spider":
			var script = load("res://scripts/combat/enemies/phase_spider.gd")
			if script: enemy = script.new()
		"gear_sentry":
			var script = load("res://scripts/combat/enemies/gear_sentry.gd")
			if script: enemy = script.new()
		"corruption_elemental":
			var script = load("res://scripts/combat/enemies/corruption_elemental.gd")
			if script: enemy = script.new()
		"mushroom_mimic":
			var script = load("res://scripts/combat/enemies/mushroom_mimic.gd")
			if script: enemy = script.new()
		_:
			push_error("[ARENA] Unknown enemy type: %s" % etype)
			return null
	if enemy:
		enemy.name = etype + "_" + str(randi() % 9999)
	return enemy


# ═════════════════════════════════════════════════════════════════════════
# ENEMY VISUAL SETUP
# ═════════════════════════════════════════════════════════════════════════

const TYPE_ASSET = {
	"corrupted_rat": "corrupted_rat",   "glitch_wolf": "glitch_wolf",
	"corrupted_guard": "corrupted_guard", "data_sprite": "data_sprite",
	"clockwork_soldier": "clockwork_soldier", "shadow_wraith": "shadow_wraith",
	"phase_spider": "phase_spider", "gear_sentry": "gear_sentry",
	"corruption_elemental": "corruption_elemental", "mushroom_mimic": "mushroom_mimic",
	"slime": "slime_green", "boar": "boar_corrupted",
}

const TYPE_SIZE = {
	"corrupted_rat": Vector2(25, 18),  "glitch_wolf": Vector2(40, 30),
	"corrupted_guard": Vector2(35, 50), "data_sprite": Vector2(20, 20),
	"clockwork_soldier": Vector2(40, 55), "shadow_wraith": Vector2(30, 45),
	"phase_spider": Vector2(35, 25), "gear_sentry": Vector2(30, 40),
	"corruption_elemental": Vector2(28, 36), "mushroom_mimic": Vector2(22, 22),
	"slime": Vector2(64, 64), "boar": Vector2(48, 40),
}


func _setup_enemy_visual(enemy: EnemyBase, etype: String) -> void:
	var target_size: Vector2 = TYPE_SIZE.get(etype, Vector2(32, 32))
	var asset_name: String = TYPE_ASSET.get(etype, etype)

	if _has_am() and AssetManager.is_asset_available(asset_name):
		var sprite = Sprite2D.new()
		sprite.name = "Sprite"
		sprite.texture = AssetManager.get_sprite(asset_name)
		sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		var ts = sprite.texture.get_size()
		if ts.x > 0 and ts.y > 0:
			var s = minf(target_size.x / ts.x, target_size.y / ts.y) * 2.0
			sprite.scale = Vector2(s, s)
			sprite.offset = Vector2(0, -ts.y / 2.0)
		enemy.add_child(sprite)
	else:
		var rect = ColorRect.new()
		rect.name = "Sprite"
		rect.size = target_size
		rect.position = Vector2(-target_size.x / 2.0, -target_size.y)
		rect.color = AssetManager.get_placeholder_color(asset_name) if _has_am() else Color(0.6, 0.2, 0.2)
		rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		enemy.add_child(rect)

	# Effective visual size
	var vis_size = target_size
	var spr = enemy.get_node_or_null("Sprite")
	if spr is Sprite2D and spr.texture:
		vis_size = spr.texture.get_size() * spr.scale

	# Collision
	var col = CollisionShape2D.new()
	var shape = RectangleShape2D.new()
	shape.size = vis_size
	col.shape = shape
	col.position = Vector2(0, -vis_size.y * 0.5)
	enemy.add_child(col)

	# Health bar: EnemyBase._setup_health_bar() already built "HealthBar" in _ready.
	# A second bar added here got auto-renamed and was never updated (stuck at 100%).


# ═════════════════════════════════════════════════════════════════════════
# EVENT HANDLERS
# ═════════════════════════════════════════════════════════════════════════

func _on_enemy_died() -> void:
	if not arena_active:
		return
	enemies_alive -= 1
	if enemies_alive <= 0:
		all_enemies_cleared.emit()

		if _has_dm():
			var lines: Array = ANNOUNCER["wave_clear"]
			await DialogueManager.say("Vex", lines[randi() % lines.size()], Color(-1, -1, -1), true)
			if not is_inside_tree():
				return

		wave_completed.emit(current_wave)

		# Per-wave bonus (endurance has no TIER_DATA entry; it pays per wave in _start_next_wave)
		var info: Dictionary = TIER_DATA.get(current_tier, {})
		if _has_gm():
			if info.get("xp_bonus", 0) > 0:
				GameManager.add_xp(info["xp_bonus"])
			if info.get("gold_bonus", 0) > 0:
				GameManager.add_gold(info["gold_bonus"])

		await get_tree().create_timer(2.0, false).timeout
		if not is_inside_tree():
			return
		_start_next_wave()


# ═════════════════════════════════════════════════════════════════════════
# VICTORY / CLEANUP
# ═════════════════════════════════════════════════════════════════════════

func _arena_win() -> void:
	arena_active = false
	_is_processing_timer = false

	if not _has_gm():
		arena_victory.emit(current_tier)
		return

	GameManager.record_arena_win()
	var mult = GameManager.get_arena_streak_multiplier()

	var base_xp = 50
	var base_gold = 30
	match current_tier:
		"silver":   base_xp = 100;  base_gold = 60
		"gold":     base_xp = 200;  base_gold = 120
		"platinum": base_xp = 400;  base_gold = 250

	var final_xp = int(base_xp * mult)
	var final_gold = int(base_gold * mult)

	# Time Attack bonus: extra rewards for remaining time
	var time_bonus_xp: int = 0
	var time_bonus_gold: int = 0
	if current_mode == ArenaMode.TIME_ATTACK and _time_attack_remaining > 0:
		var ta_config = TIME_ATTACK_CONFIG.get(current_tier, {"bonus_per_sec": 2})
		time_bonus_xp = int(_time_attack_remaining * ta_config["bonus_per_sec"])
		time_bonus_gold = int(_time_attack_remaining * ta_config["bonus_per_sec"] * 0.6)
		final_xp += time_bonus_xp
		final_gold += time_bonus_gold

	GameManager.add_xp(final_xp)
	GameManager.add_gold(final_gold)

	# Tier completion flags
	match current_tier:
		"bronze":   GameManager.set_story_flag("ch2_arena_bronze_complete", true)
		"silver":   GameManager.set_story_flag("ch2_arena_silver_complete", true)
		"gold":     GameManager.set_story_flag("ch2_arena_gold_complete", true)
		"platinum": GameManager.set_story_flag("ch2_arena_platinum_complete", true)

	# PASS-35 FIX: Advance arena legend side quest on tier completion
	if has_node("/root/SideQuestManager") and SideQuestManager.is_quest_active("ironhold_arena_legend"):
		SideQuestManager.advance_quest("ironhold_arena_legend")

	if _has_dm():
		var lines: Array = ANNOUNCER["victory"]
		await DialogueManager.say("Vex", lines[randi() % lines.size()])
		if not is_inside_tree():
			return
		var reward_text = "+%d XP, +%d Gold" % [final_xp, final_gold]
		if mult > 1.0:
			reward_text += " (x%.1f streak bonus!)" % mult
		if time_bonus_xp > 0:
			reward_text += "\nTIME BONUS: +%d XP, +%d Gold (%.1fs remaining!)" % [time_bonus_xp, time_bonus_gold, _time_attack_remaining]
		await DialogueManager.say("Vex", reward_text, Color(1, 0.85, 0.1), true)
		if not is_inside_tree():
			return
		var streak: int = GameManager.arena_stats["win_streak"]
		if streak >= 3:
			await DialogueManager.say("Vex", "Win streak: %d! Keep it up for even bigger rewards!" % streak, Color(-1, -1, -1), true)
			if not is_inside_tree():
				return

	arena_victory.emit(current_tier)


func _cleanup_enemies() -> void:
	if not spawn_container:
		return
	for child in spawn_container.get_children():
		if child is EnemyBase:
			child.queue_free()


# ═════════════════════════════════════════════════════════════════════════
# AUTOLOAD GUARDS
# ═════════════════════════════════════════════════════════════════════════

func _has_gm() -> bool:
	return has_node("/root/GameManager")

func _has_dm() -> bool:
	return has_node("/root/DialogueManager")

func _has_am() -> bool:
	return has_node("/root/AssetManager")
