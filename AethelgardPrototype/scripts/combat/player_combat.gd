extends CharacterBody2D
## ==========================================================================
## PLAYER COMBAT — Hollow Knight-style player controller
## ==========================================================================
## Full Mechanics:
##   Movement: Walk, Sprint, Variable Jump, Wall Slide, Wall Jump, Double Jump
##   Offense:  3-Hit Combo Chain, Charged Nail Art, Pogo Strike, Up-Slash
##   Defense:  Dash (i-frames), Parry "Garbage Collection", Block
##   Spells:   Vengeful Spirit, Desolate Dive, Howling Wraiths
##   Healing:  Focus Heal — spend Soul to restore HP
##   Resource: Soul meter (fills on hitting enemies, spent on spells/healing)
## ==========================================================================

signal health_changed(new_health: float, max_health: float)
signal soul_changed(new_soul: float, max_soul: float)
signal died

# ── Movement Constants ────────────────────────────────────────────────────
const SPEED = 330.0
const SPRINT_SPEED = 510.0
const JUMP_VELOCITY = -560.0
const JUMP_VELOCITY_MIN = -280.0
const GRAVITY = 1050.0
const MAX_FALL_SPEED = 950.0
const COYOTE_FRAMES = 9
const JUMP_BUFFER_FRAMES = 8

# ── Jump Feel Tuning ─────────────────────────────────────────────────────
const APEX_GRAVITY_MULT = 0.55
const APEX_VELOCITY_THRESHOLD = 120.0
const FAST_FALL_MULT = 1.6
const GROUND_ACCEL = 0.30
const AIR_ACCEL = 0.18
const GROUND_DECEL = 0.22
const AIR_DECEL = 0.10

# ── Double Jump ───────────────────────────────────────────────────────────
const DOUBLE_JUMP_VELOCITY = -480.0
const MAX_AIR_JUMPS = 1

# ── Dash ──────────────────────────────────────────────────────────────────
const DASH_SPEED = 720.0
const DASH_DURATION = 0.18
const DASH_COOLDOWN = 0.34
const DASH_GHOST_COUNT = 4
const AIR_DASH_ENABLED = true

# ── Wall ──────────────────────────────────────────────────────────────────
const WALL_SLIDE_SPEED = 55.0
const WALL_JUMP_VELOCITY = Vector2(380.0, -500.0)
const WALL_JUMP_LOCK_TIME = 0.10

# ── Attack / Combo ────────────────────────────────────────────────────────
const ATTACK_RANGE = 110.0
const COMBO_WINDOW = 0.46
const ATTACK_COOLDOWN_BASE = 0.22
const COMBO1_STARTUP = 0.07
const COMBO1_ACTIVE = 0.08
const COMBO1_RECOVERY = 0.17
const COMBO2_STARTUP = 0.08
const COMBO2_ACTIVE = 0.08
const COMBO2_RECOVERY = 0.19
const COMBO3_STARTUP = 0.11
const COMBO3_ACTIVE = 0.10
const COMBO3_RECOVERY = 0.26
const CHARGED_ATTACK_STARTUP = 0.16
const CHARGED_ATTACK_ACTIVE = 0.12
const CHARGED_ATTACK_RECOVERY = 0.34
const CHARGED_ATTACK_TIME = 1.2
const CHARGED_ATTACK_RANGE = 180.0
const CHARGED_ATTACK_MULT = 3.5
const POGO_VELOCITY = -500.0
const POGO_DAMAGE_MULT = 1.8

# ── Directional Attack ───────────────────────────────────────────────────
const UPSLASH_RANGE = 90.0
const UPSLASH_DAMAGE_MULT = 1.1
const UPSLASH_STARTUP = 0.08
const UPSLASH_ACTIVE = 0.08
const UPSLASH_RECOVERY = 0.17
const POGO_ACTIVE = 0.07
const AIR_ATTACK_RANGE = 100.0
const AIR_ATTACK_DAMAGE_MULT = 1.15

# ── Input Buffering ──────────────────────────────────────────────────────
const ATTACK_BUFFER_FRAMES = 8
const DASH_BUFFER_FRAMES = 6
const SPELL_BUFFER_FRAMES = 6

# ── Cancel System ────────────────────────────────────────────────────────
const ATTACK_CANCEL_INTO_DASH = true
const ATTACK_CANCEL_INTO_JUMP = true
const DASH_CANCEL_INTO_ATTACK = true
const LANDING_CANCEL = true

# ── Resources (DESIGN_PILLARS.md, decided 2026-10-04) ─────────────────────
# MP pays for normal spells, skills and healing; it regenerates over time and
# from potions. It lives in GameManager.player_stats["mp"] so potions and
# level-ups apply immediately.
# Soul pays for special arts (Glitch Arts) and is earned only by skillful play:
# parries, perfect dodges and kills. It is no longer gained per hit.
const MAX_SOUL = 99.0
const SOUL_PER_PARRY = 25.0
const SOUL_PER_PERFECT_DODGE = 15.0
const SOUL_PER_KILL = 10.0
const SPELL_COST = 15.0  # MP
const HEAL_COST = 20.0  # MP
const MP_REGEN_PER_SEC = 2.0
const HEAL_AMOUNT = 30.0
const HEAL_CHANNEL_TIME = 0.95
const VENGEFUL_SPIRIT_DAMAGE = 45.0
const DESOLATE_DIVE_DAMAGE = 60.0
const VENGEFUL_SPIRIT_SPEED = 750.0
const HOWLING_WRAITHS_DAMAGE = 50.0
const HOWLING_WRAITHS_RANGE = 130.0

# ── Parry / Block ────────────────────────────────────────────────────────
const PARRY_WINDOW = 0.18
const PARRY_COOLDOWN = 0.24
const BLOCK_DAMAGE_REDUCTION = 0.7
## Defense mitigation: damage × DEFENSE_SCALE / (DEFENSE_SCALE + DEF).
## 0 DEF = full damage, 50 DEF = 67%, 100 DEF = 50%. DEF was display-only before.
const DEFENSE_SCALE = 100.0


static func mitigate_by_defense(amount: float, defense: float) -> float:
	return amount * DEFENSE_SCALE / (DEFENSE_SCALE + maxf(defense, 0.0))
const PARRY_FREEZE_TIME = 0.12
const PARRY_COUNTERATTACK_WINDOW = 0.4

# ── Combo Tracking ───────────────────────────────────────────────────────
const COMBO_DECAY_TIME = 3.0
const MAX_AIR_ATTACKS = 3
const LANDING_RECOVERY_TIME = 0.06

# ── Death Tips ────────────────────────────────────────────────────────────
const DEATH_TIPS: Dictionary = {
	"default": [
		"Use Dash (Shift) for i-frames to dodge through attacks.",
		"Focus Heal (C) restores HP using MP.",
		"Parry (F) just before impact for COUNTER opportunities.",
	],
	"boss": [
		"Study the boss telegraph — colored flash means an attack is coming.",
		"Dash through boss attacks, then punish during recovery.",
		"Root Access can hack bosses — but costs corruption.",
	],
	"ranged": [
		"Close the gap quickly with Dash to avoid projectiles.",
		"Jump and air-attack to approach from above.",
	],
	"swarm": [
		"Use Desolate Dive (S+Spell) to hit all nearby enemies.",
		"Pogo strike (down-attack mid-air) to bounce over groups.",
	],
	"heavy_hit": [
		"That was a charged attack — watch for the red telegraph glow.",
		"Block (hold G) reduces heavy hit damage by 50%.",
	],
	"corruption": [
		"Buy Glitch Stabilizers from shops to reduce corruption.",
		"The Firewall charm reduces all corruption gain by 40%.",
	],
}

# ── Exports ───────────────────────────────────────────────────────────────
@export var max_health: float = 100.0
@export var attack_damage: float = 15.0

# ── Runtime State ─────────────────────────────────────────────────────────
var current_health: float = 100.0
var current_soul: float = 0.0
var _perfect_dodge_awarded: bool = false  # one Soul award per dash
var _mp_hud_timer: float = 0.0
var is_dead: bool = false
var facing_direction: float = 1.0

# Combat
var is_attacking: bool = false
var attack_cooldown: float = 0.0
var combo_step: int = 0
var combo_timer: float = 0.0
var is_charging: bool = false
var charge_timer: float = 0.0
var charged_attack_ready: bool = false

# Invulnerability
var invulnerable: bool = false
var invuln_timer: float = 0.0

# Dash
var is_dashing: bool = false
var dash_timer: float = 0.0
var dash_cooldown_timer: float = 0.0
var dash_direction: float = 1.0
var dash_available: bool = true

# Wall
var is_wall_sliding: bool = false
var wall_direction: float = 0.0
var wall_jump_lock_timer: float = 0.0

# Pogo
var is_pogoing: bool = false
var pogo_cooldown: float = 0.0

# Defend / Parry
var is_defending: bool = false
var parry_active: bool = false
var parry_window_timer: float = 0.0
var parry_cooldown_timer: float = 0.0

# Healing
var is_healing: bool = false
var heal_timer: float = 0.0

# Spell
var is_casting: bool = false
var cast_lock_timer: float = 0.0

# Jump
var coyote_timer: float = 0.0
var was_on_floor: bool = false
var jump_buffer_timer: float = 0.0
var jump_held: bool = false
var is_sprinting: bool = false
var air_jumps_remaining: int = MAX_AIR_JUMPS
var has_double_jumped: bool = false

# Directional attack
# var attack_direction: Vector2 = Vector2.RIGHT  # REMOVED: unused (BUG 10)
var is_air_attacking: bool = false
var air_attack_count: int = 0

# Cancel system
var can_cancel_attack: bool = false
var attack_recovery_timer: float = 0.0
## Monotonic attack id. Every attack coroutine captures the value at its start and
## bails after each await if it no longer matches. take_damage() (and anything else
## that cancels an attack) bumps this, which stops an interrupted swing from still
## resolving its hitbox and from writing its recovery state over the NEXT attack.
var _attack_token: int = 0

# Input buffers
var attack_buffer_timer: float = 0.0
var dash_buffer_timer: float = 0.0
var spell_buffer_timer: float = 0.0

# Landing
var just_landed: bool = false
var landing_recovery_timer: float = 0.0

# Parry counter
var parry_counter_active: bool = false
var parry_counter_timer: float = 0.0
var parry_counter_damage_mult: float = 2.0

# Combo style
var total_combo_hits: int = 0
var combo_decay_timer: float = 0.0

# Speed multiplier for time zones
var speed_multiplier: float = 1.0

# Death tracking
var _last_damage_source: String = ""
var _last_damage_type: String = ""

# QA-only combat feel metrics. These are read by scratch playtest harnesses and do not affect gameplay.
var combat_attack_metrics: Dictionary = {}

# HUD references
var _hud_layer: CanvasLayer
var _hp_bar: ProgressBar
var _hp_label: Label
var _soul_bar: ProgressBar
var _soul_label: Label
var _mp_bar: ProgressBar
var _mp_label: Label
var _corruption_label: Label
var _combo_indicator: Label
var _combo_pop_tween: Tween = null
var _hp_flash_tween: Tween = null  # Pass 59: Prevent overlapping HP flash tweens
var _charge_indicator: ProgressBar
var _level_label: Label
var _soul_flashing: bool = false
var _hp_display_value: float = 0.0
var _danger_overlay: ColorRect = null
var _combo_mult_hud: Label = null

# Cached script
var _cached_projectile_script: GDScript = null

# Cached sprite node (set in _ready)
var _sprite: Node = null

# Animation controller
var _anim_controller = null
const _PlayerAnimCtrl = preload("res://scripts/player_animation_controller.gd")


# ══════════════════════════════════════════════════════════════════════════
# LIFECYCLE
# ══════════════════════════════════════════════════════════════════════════

func _ready() -> void:
	collision_layer = 2
	collision_mask = 1
	_reset_combat_attack_metrics()

	# Cache the Sprite child node for performance (avoids repeated get_node calls)
	_sprite = get_node_or_null("Sprite")

	# Choice-consequence stat mods are owned by ChoiceConsequences.apply_choice_buff(),
	# which bakes them into GameManager.player_stats once, at the moment the choice is
	# made. Do NOT re-apply get_total_stat_mods() here: _ready() runs on every combat
	# scene load, so adding them again compounds max_hp permanently (+15 or +10 per
	# scene entry) and silently destroys the balance curve. Read player_stats only.
	max_health = float(GameManager.player_stats.get("max_hp", 100))
	current_health = min(float(GameManager.player_stats.get("hp", max_health)), max_health)
	attack_damage = float(GameManager.player_stats.get("attack", 15))
	current_soul = float(GameManager.player_stats.get("soul", 0))
	GameManager.player_stats["hp"] = int(current_health)
	add_to_group("player")
	health_changed.emit(current_health, max_health)
	soul_changed.emit(current_soul, MAX_SOUL)

	if not GameManager.player_leveled_up.is_connected(_on_player_leveled_up):
		GameManager.player_leveled_up.connect(_on_player_leveled_up)

	_anim_controller = _PlayerAnimCtrl.new()
	_anim_controller.set_mode_combat()
	add_child(_anim_controller)
	_build_combat_hud()
	refresh_visual_references()


func _exit_tree() -> void:
	# Pass 55 L-05: Release all actions to prevent phantom input on death/scene change.
	# These must be the real action names from project.godot. "dash" and "parry" do not
	# exist (they are "sprint" and "defend"), so a held sprint or block was never released
	# and leaked into the next scene as stuck input.
	for action in ["attack", "sprint", "jump", "spell", "heal", "defend", "interact",
			"ui_accept", "move_left", "move_right", "move_up", "move_down",
			"root_access", "perfect_delete", "data_vision"]:
		if InputMap.has_action(action) and Input.is_action_pressed(action):
			Input.action_release(action)
	# Pass 59: Disconnect autoload signals to prevent dangling references
	if GameManager.player_leveled_up.is_connected(_on_player_leveled_up):
		GameManager.player_leveled_up.disconnect(_on_player_leveled_up)


func _on_player_leveled_up(new_level: int) -> void:
	max_health = float(GameManager.player_stats.get("max_hp", 100))
	current_health = float(GameManager.player_stats.get("hp", max_health))
	attack_damage = float(GameManager.player_stats.get("attack", 15))
	health_changed.emit(current_health, max_health)
	_update_hud()
	if has_node("/root/VFXLibrary"):
		VFXLibrary.spawn("vfx_glitch_sparkle", global_position, get_parent())
		VFXLibrary.spawn_status_indicator("LEVEL UP! Lv.%d" % new_level, global_position + Vector2(0, -50), get_parent(), false)


# ══════════════════════════════════════════════════════════════════════════
# MAIN PHYSICS LOOP
# ══════════════════════════════════════════════════════════════════════════

func _physics_process(delta: float) -> void:
	if is_dead:
		return
	_regen_mp(delta)

	# Block combat input during dialogue/cutscene
	if _is_dialogue_active() or GameManager.current_state == GameManager.GameState.CUTSCENE:
		velocity.x = lerp(velocity.x, 0.0, GROUND_DECEL)
		if not is_on_floor():
			velocity.y += GRAVITY * delta
		move_and_slide()
		return

	# ── Invulnerability flicker ──
	if invulnerable and not is_dashing:
		invuln_timer -= delta
		if invuln_timer <= 0.0:
			invulnerable = false
			set_meta("local_retry_disable_flicker", false)
			_set_sprite_alpha(1.0)
		elif bool(get_meta("local_retry_disable_flicker", false)):
			_set_sprite_alpha(1.0)
		else:
			var flicker = 0.35 + 0.65 * absf(sin(invuln_timer * 14.0))
			_set_sprite_alpha(flicker)

	# ── Floor / Coyote / Landing ──
	just_landed = false
	if is_on_floor():
		if not was_on_floor:
			just_landed = true
			_sfx("land")
			landing_recovery_timer = LANDING_RECOVERY_TIME
			if _sprite:
				TweenAnimator.play_land(_sprite)
			_vfx("vfx_dust_puff", global_position + Vector2(0, 5))
			if has_node("/root/GameJuice"):
				GameJuice.on_player_land(self)
			if LANDING_CANCEL and attack_buffer_timer > 0.0 and not is_attacking and attack_cooldown <= 0.0:
				attack_buffer_timer = 0.0
				_perform_combo_attack()
		coyote_timer = float(COYOTE_FRAMES) / 60.0
		was_on_floor = true
		dash_available = true
		is_wall_sliding = false
		air_jumps_remaining = MAX_AIR_JUMPS
		has_double_jumped = false
		air_attack_count = 0
	else:
		if was_on_floor:
			was_on_floor = false
		coyote_timer -= delta

	if jump_buffer_timer > 0.0:
		jump_buffer_timer -= delta
	if wall_jump_lock_timer > 0.0:
		wall_jump_lock_timer -= delta
	if landing_recovery_timer > 0.0:
		landing_recovery_timer -= delta

	# ── Gravity (apex hang, fast-fall, corruption) ──
	if not is_on_floor() and not is_dashing:
		var grav_mult = GameManager.get_corruption_gravity_multiplier()
		var gravity_frame = GRAVITY * grav_mult
		if absf(velocity.y) < APEX_VELOCITY_THRESHOLD and not is_wall_sliding:
			gravity_frame *= APEX_GRAVITY_MULT
		if Input.is_action_pressed("move_down") and velocity.y > 0.0:
			gravity_frame *= FAST_FALL_MULT
		if is_wall_sliding:
			velocity.y = move_toward(velocity.y, WALL_SLIDE_SPEED, GRAVITY * delta * 2.0)
		else:
			velocity.y = minf(velocity.y + gravity_frame * delta, MAX_FALL_SPEED)

	# ── Cooldown timers ──
	if attack_cooldown > 0.0:
		attack_cooldown -= delta
		if attack_cooldown <= 0.0 and attack_buffer_timer > 0.0 and not is_attacking and not is_dashing and not is_healing and not is_casting:
			attack_buffer_timer = 0.0
			_perform_combo_attack()
	if dash_cooldown_timer > 0.0:
		dash_cooldown_timer -= delta
		if dash_cooldown_timer <= 0.0 and dash_buffer_timer > 0.0 and not is_dashing:
			dash_buffer_timer = 0.0
			_start_dash()
	if pogo_cooldown > 0.0:
		pogo_cooldown -= delta
	if parry_cooldown_timer > 0.0:
		parry_cooldown_timer -= delta
	if cast_lock_timer > 0.0:
		cast_lock_timer -= delta

	# ── Input buffers ──
	if attack_buffer_timer > 0.0:
		attack_buffer_timer -= delta
	if dash_buffer_timer > 0.0:
		dash_buffer_timer -= delta
	if spell_buffer_timer > 0.0:
		spell_buffer_timer -= delta

	# ── Combo timer ──
	if combo_timer > 0.0:
		combo_timer -= delta
		if combo_timer <= 0.0:
			combo_step = 0
			_update_combo_indicator()

	# ── Parry window ──
	if parry_active:
		parry_window_timer -= delta
		if parry_window_timer <= 0.0:
			parry_active = false

	# ── Dash ──
	if is_dashing:
		dash_timer -= delta
		if dash_timer <= 0.0:
			_end_dash()

	# ── Charge attack ──
	if is_charging:
		charge_timer += delta
		_update_charge_indicator()
		if charge_timer >= CHARGED_ATTACK_TIME:
			charged_attack_ready = true
			_set_sprite_color(Color(1.0, 0.9, 0.4) if int(charge_timer * 6) % 2 == 0 else Color(1.0, 1.0, 0.8))

	# ── Cancel system ──
	if attack_recovery_timer > 0.0:
		attack_recovery_timer -= delta
		can_cancel_attack = true
	else:
		can_cancel_attack = false

	# ── Parry counter window ──
	if parry_counter_active:
		parry_counter_timer -= delta
		if parry_counter_timer <= 0.0:
			parry_counter_active = false

	# ── Combo decay ──
	if total_combo_hits > 0:
		combo_decay_timer -= delta
		if combo_decay_timer <= 0.0:
			total_combo_hits = 0
			_update_combo_indicator()

	# ── Handle input ──
	_handle_movement(delta)
	_handle_wall_slide()
	_handle_directional_attack()
	_handle_jump()
	_handle_variable_jump()
	_handle_attack()
	_handle_charged_attack()
	_handle_dash()
	_handle_defend()
	_handle_pogo()
	_handle_spell()
	_handle_heal()
	_handle_flee_combat()

	if speed_multiplier != 1.0 and not is_dashing:
		velocity.x *= speed_multiplier

	move_and_slide()

	# Death plane
	if global_position.y > 2000.0:
		global_position = Vector2(640.0, 100.0)
		velocity = Vector2.ZERO
		take_damage(15.0, Vector2.ZERO, "The Void", "fall")
		if has_node("/root/SceneTransitions"):
			SceneTransitions.flash(Color.WHITE, 0.3)
		_screen_shake(8.0, 0.3)

	if _anim_controller:
		_anim_controller.update_animation(delta)

	_update_danger_overlay()
	_update_combo_mult_hud()


# ══════════════════════════════════════════════════════════════════════════
# MOVEMENT
# ══════════════════════════════════════════════════════════════════════════

func _handle_movement(_delta: float) -> void:
	if is_dashing or is_healing or is_casting:
		return
	if wall_jump_lock_timer > 0.0:
		return

	var direction = Input.get_axis("move_left", "move_right")

	if direction != 0.0:
		facing_direction = signf(direction)
		_apply_sprite_facing()

	if direction != 0.0 and not is_attacking and not is_defending:
		is_sprinting = Input.is_action_pressed("sprint")
		var move_speed = SPRINT_SPEED if is_sprinting else SPEED
		var target_vx = direction * move_speed
		var accel = GROUND_ACCEL if is_on_floor() else AIR_ACCEL
		velocity.x = lerp(velocity.x, target_vx, accel)
	else:
		is_sprinting = false
		var decel = GROUND_DECEL if is_on_floor() else AIR_DECEL
		velocity.x = lerp(velocity.x, 0.0, decel)


# ══════════════════════════════════════════════════════════════════════════
# WALL SLIDE & WALL JUMP
# ══════════════════════════════════════════════════════════════════════════

## Flip the visual to match facing. The "Sprite" node is a ColorRect when no
## art is loaded (the fallback), which has no flip_h: setting it raised a
## script error that aborted movement, so the player couldn't move sideways.
func _apply_sprite_facing() -> void:
	# is_instance_valid first: AssetManager swaps the Sprite node at runtime, so
	# _sprite can briefly point at a freed node.
	if not is_instance_valid(_sprite):
		return
	if _sprite is Sprite2D or _sprite is AnimatedSprite2D:
		_sprite.flip_h = facing_direction < 0.0


func _handle_wall_slide() -> void:
	if is_on_floor() or is_dashing:
		is_wall_sliding = false
		return

	var touching_left = is_on_wall() and Input.is_action_pressed("move_left")
	var touching_right = is_on_wall() and Input.is_action_pressed("move_right")

	if (touching_left or touching_right) and velocity.y > 0.0:
		is_wall_sliding = true
		wall_direction = -1.0 if touching_left else 1.0
		if _sprite:
			_sprite.rotation_degrees = -8.0 * wall_direction
	else:
		is_wall_sliding = false
		if _sprite:
			_sprite.rotation_degrees = 0.0


func _handle_jump() -> void:
	# Skip jump during dialogue (Space is shared with ui_accept)
	if _is_dialogue_active():
		return

	if Input.is_action_just_pressed("jump"):
		jump_buffer_timer = float(JUMP_BUFFER_FRAMES) / 60.0
		jump_held = true

	# Wall jump
	if is_wall_sliding and Input.is_action_just_pressed("jump"):
		velocity.x = -wall_direction * WALL_JUMP_VELOCITY.x
		velocity.y = WALL_JUMP_VELOCITY.y
		is_wall_sliding = false
		wall_jump_lock_timer = WALL_JUMP_LOCK_TIME
		facing_direction = -wall_direction
		_apply_sprite_facing()
		if _sprite:
			_sprite.rotation_degrees = 0.0
		_vfx("vfx_dust_puff", global_position + Vector2(wall_direction * 15.0, 0.0))
		_sfx("jump", 0.1)
		if has_node("/root/GameJuice"):
			GameJuice.on_wall_jump(self)
		jump_buffer_timer = 0.0
		coyote_timer = 0.0
		return

	# Ground jump (coyote + buffer)
	var can_jump = is_on_floor() or coyote_timer > 0.0
	if jump_buffer_timer > 0.0 and can_jump and not is_attacking and not is_defending and not is_healing:
		velocity.y = JUMP_VELOCITY
		jump_buffer_timer = 0.0
		coyote_timer = 0.0
		_sfx("jump")
		_vfx("vfx_dust_puff", global_position + Vector2(0.0, 10.0))
		if has_node("/root/GameJuice"):
			GameJuice.on_jump(self)
		if ATTACK_CANCEL_INTO_JUMP and can_cancel_attack:
			is_attacking = false
			attack_recovery_timer = 0.0

	# Double jump
	elif Input.is_action_just_pressed("jump") and not is_on_floor() and not is_wall_sliding and air_jumps_remaining > 0 and not is_healing:
		velocity.y = DOUBLE_JUMP_VELOCITY
		air_jumps_remaining -= 1
		has_double_jumped = true
		_sfx("jump", 0.15)
		_vfx("vfx_glitch_sparkle", global_position)
		_vfx("vfx_dust_puff", global_position + Vector2(0.0, 10.0))
		if has_node("/root/GameJuice"):
			GameJuice.on_double_jump(self)
		if ATTACK_CANCEL_INTO_JUMP and (is_attacking or can_cancel_attack):
			is_attacking = false
			attack_recovery_timer = 0.0


func _handle_variable_jump() -> void:
	if Input.is_action_just_released("jump"):
		jump_held = false
		if velocity.y < JUMP_VELOCITY_MIN:
			velocity.y = JUMP_VELOCITY_MIN


# ══════════════════════════════════════════════════════════════════════════
# 3-HIT COMBO CHAIN
# ══════════════════════════════════════════════════════════════════════════

func _reset_combat_attack_metrics() -> void:
	combat_attack_metrics = {
		"attempted": 0,
		"started": 0,
		"ignored_recovery": 0,
		"buffered_combo": 0,
		"hitbox_active_duration": {},
		"last_attack_timing": {}
	}


func get_combat_attack_metrics() -> Dictionary:
	return combat_attack_metrics.duplicate(true)


func _metric_inc(key: String, amount: int = 1) -> void:
	if not combat_attack_metrics.has(key):
		combat_attack_metrics[key] = 0
	combat_attack_metrics[key] = int(combat_attack_metrics[key]) + amount


func _metric_attack_window(attack_name: String, startup: float, active: float, recovery: float, combo_window_start: float) -> void:
	_metric_inc("started")
	var active_map: Dictionary = combat_attack_metrics.get("hitbox_active_duration", {})
	active_map[attack_name] = float(active_map.get(attack_name, 0.0)) + active
	combat_attack_metrics["hitbox_active_duration"] = active_map
	combat_attack_metrics["last_attack_timing"] = {
		"attack": attack_name,
		"startup": startup,
		"active": active,
		"recovery": recovery,
		"combo_cancel_window": recovery,
		"combo_window_start": combo_window_start
	}


func _buffer_attack_input() -> void:
	if attack_buffer_timer <= 0.0:
		attack_buffer_timer = float(ATTACK_BUFFER_FRAMES) / 60.0
		_metric_inc("buffered_combo")
	else:
		_metric_inc("ignored_recovery")


func _consume_attack_buffer_if_ready() -> void:
	if attack_buffer_timer <= 0.0:
		return
	if is_attacking or is_dashing or is_defending or is_healing or is_casting or attack_cooldown > 0.0:
		return
	attack_buffer_timer = 0.0
	call_deferred("_perform_combo_attack")


func _handle_attack() -> void:
	var attack_pressed := Input.is_action_just_pressed("attack")
	if attack_pressed:
		_metric_inc("attempted")
	if is_dashing or is_defending or is_healing or is_casting:
		if attack_pressed:
			_metric_inc("ignored_recovery")
		return
	if is_attacking:
		if attack_pressed:
			_buffer_attack_input()
		return

	if attack_pressed and attack_cooldown <= 0.0:
		if Input.is_action_pressed("move_up"):
			return
		if not is_on_floor() and Input.is_action_pressed("move_down"):
			return
		is_charging = true
		charge_timer = 0.0
		charged_attack_ready = false
	elif attack_pressed and attack_cooldown > 0.0:
		_buffer_attack_input()

	if Input.is_action_just_released("attack") and is_charging:
		if charged_attack_ready:
			_perform_charged_attack()
		else:
			_perform_combo_attack()
		is_charging = false
		charge_timer = 0.0
		charged_attack_ready = false
		_set_sprite_color(Color.WHITE)
		_update_charge_indicator()


func _get_enemies_in_melee_hitbox(center_offset: Vector2, size: Vector2, debug_color: Color = Color(1.0, 0.85, 0.2, 0.2)) -> Array:
	var enemies: Array = []
	var world := get_world_2d()
	if not world:
		return enemies

	var shape := RectangleShape2D.new()
	shape.size = size

	var params := PhysicsShapeQueryParameters2D.new()
	params.shape = shape
	params.transform = Transform2D(0.0, global_position + center_offset)
	params.collide_with_bodies = true
	params.collide_with_areas = true
	params.collision_mask = 0xFFFFFFFF
	params.exclude = [get_rid()]

	var hit_rect := Rect2(global_position + center_offset - size * 0.5, size)
	var hits := world.direct_space_state.intersect_shape(params, 32)
	for hit in hits:
		var collider = hit.get("collider")
		var enemy = _resolve_enemy_collider(collider)
		if enemy and hit_rect.has_point(enemy.global_position) and _enemy_matches_melee_hitbox(enemy, center_offset, enemies):
			enemies.append(enemy)

	if enemies.is_empty():
		for candidate in get_tree().get_nodes_in_group("enemies"):
			if not is_instance_valid(candidate):
				continue
			if hit_rect.has_point(candidate.global_position) and _enemy_matches_melee_hitbox(candidate, center_offset, enemies):
				enemies.append(candidate)

	_spawn_melee_hitbox_debug(center_offset, size, debug_color)
	return enemies


func _enemy_matches_melee_hitbox(enemy, center_offset: Vector2, already_hit: Array) -> bool:
	if enemy in already_hit or not enemy.has_method("take_damage"):
		return false
	if center_offset.x > 0.0 and enemy.global_position.x < global_position.x:
		return false
	if center_offset.x < 0.0 and enemy.global_position.x > global_position.x:
		return false
	return true


func _resolve_enemy_collider(collider: Object):
	var node = collider as Node
	while node:
		if node.is_in_group("enemies"):
			return node
		node = node.get_parent()
	return null


func _spawn_melee_hitbox_debug(center_offset: Vector2, size: Vector2, color: Color) -> void:
	if not OS.is_debug_build():
		return
	if has_node("/root/GameManager") and GameManager.get_meta("combat_debug_hitboxes", false) != true:
		return

	var parent := get_parent()
	if not parent:
		return

	var area := Area2D.new()
	area.name = "MeleeHitboxDebug"
	area.collision_layer = 0
	area.collision_mask = 0
	area.modulate = Color(1.0, 1.0, 1.0, color.a)

	var collision := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = size
	collision.shape = shape
	area.add_child(collision)

	var polygon := Polygon2D.new()
	var half_size := size * 0.5
	polygon.color = color
	polygon.polygon = PackedVector2Array([
		Vector2(-half_size.x, -half_size.y),
		Vector2(half_size.x, -half_size.y),
		Vector2(half_size.x, half_size.y),
		Vector2(-half_size.x, half_size.y)
	])
	area.add_child(polygon)

	parent.add_child(area)
	area.global_position = global_position + center_offset
	var tween := area.create_tween()
	tween.tween_property(area, "modulate:a", 0.0, 0.08)
	tween.tween_callback(area.queue_free)


func _perform_combo_attack() -> void:
	if attack_cooldown > 0.0 or is_attacking:
		return

	_attack_token += 1
	var my_token: int = _attack_token
	is_attacking = true
	combo_step += 1
	if combo_step > 3:
		combo_step = 1
	combo_timer = COMBO_WINDOW

	var damage = attack_damage
	var range_mult = 1.0
	var startup = COMBO1_STARTUP
	var active_window = COMBO1_ACTIVE
	var recovery = COMBO1_RECOVERY
	var lunge_force = 0.0

	match combo_step:
		1:
			damage *= 1.0
			startup = COMBO1_STARTUP
			active_window = COMBO1_ACTIVE
			recovery = COMBO1_RECOVERY
			lunge_force = 40.0
		2:
			damage *= 1.25
			range_mult = 1.2
			startup = COMBO2_STARTUP
			active_window = COMBO2_ACTIVE
			recovery = COMBO2_RECOVERY
			lunge_force = 65.0
		3:
			damage *= 1.5
			range_mult = 1.4
			startup = COMBO3_STARTUP
			active_window = COMBO3_ACTIVE
			recovery = COMBO3_RECOVERY
			lunge_force = 145.0

	var total_commitment = startup + active_window + recovery
	attack_cooldown = total_commitment
	_update_combo_indicator()
	# Reset combo step AFTER updating indicator so step 3 text shows
	if combo_step == 3:
		combo_step = 0
		combo_timer = 0.0
	_sfx("sword_swing", 0.1)

	var facing = facing_direction
	var anim_step = combo_step if combo_step > 0 else 3
	var anim_target = _sprite if _sprite else self
	TweenAnimator.play_attack_combo(anim_target, facing, anim_step)
	_metric_attack_window("slash_%d" % anim_step, startup, active_window, recovery, startup + active_window)

	velocity.x = facing * lunge_force * 0.45

	var slash_offset = Vector2(45.0 * facing, -10.0)
	_vfx("vfx_slash_arc", global_position + slash_offset)
	await get_tree().create_timer(startup).timeout
	# Interrupted (e.g. by take_damage) — do not resolve this attack any further.
	if _attack_token != my_token:
		return
	if not is_inside_tree() or is_dead:
		return

	var hit_count = 0
	var hitbox_size := Vector2(ATTACK_RANGE * range_mult, 76.0)
	var hitbox_offset := Vector2(facing * hitbox_size.x * 0.5, -12.0)
	var enemies = _get_enemies_in_melee_hitbox(hitbox_offset, hitbox_size, Color(1.0, 0.8, 0.15, 0.22))
	var counter_mult = parry_counter_damage_mult if parry_counter_active else 1.0
	var combo_mult = _get_combo_multiplier()
	var final_damage = damage * counter_mult * combo_mult
	if has_node("/root/GameManager"):
		final_damage *= GameManager.get_player_dda_bonus()

	for enemy in enemies:
		if not is_instance_valid(enemy):
			continue
		if enemy.has_method("take_damage"):
			enemy.take_damage(final_damage, global_position)
			hit_count += 1
			_sfx("critical_hit" if parry_counter_active else "sword_hit")
			if has_node("/root/GameJuice"):
				GameJuice.on_hit_connect(self, enemy, final_damage, parry_counter_active)
			total_combo_hits += 1
			combo_decay_timer = COMBO_DECAY_TIME
			if total_combo_hits > GameManager.stats.get("highest_combo", 0):
				GameManager.stats["highest_combo"] = total_combo_hits
			GameManager.stats["total_damage_dealt"] = GameManager.stats.get("total_damage_dealt", 0) + int(final_damage)
			if has_node("/root/CombatFX"):
				CombatFX.apply_hit_effects(final_damage, enemy.global_position, parry_counter_active)
			_vfx("vfx_hit_spark", enemy.global_position)
			var dmg_color = Color(1.0, 0.85, 0.0) if parry_counter_active else Color.WHITE
			_spawn_damage_number(int(final_damage), enemy.global_position + Vector2(0, -30), parry_counter_active, dmg_color)
			if combo_step == 0:
				if has_node("/root/CombatFX"):
					CombatFX.apply_hitstop(CombatFX.HITSTOP_HEAVY)
					var hit_dir = (enemy.global_position - global_position).normalized()
					CombatFX.apply_directional_shake(12.0, 0.2, hit_dir)
					CombatFX.apply_zoom_pulse(1.06, 0.25)
			else:
				# Graduated hitstop per combo step for escalating impact
				if has_node("/root/CombatFX"):
					match anim_step:
						1: CombatFX.apply_hitstop(CombatFX.HITSTOP_LIGHT)
						2: CombatFX.apply_hitstop(CombatFX.HITSTOP_NORMAL)
						3: CombatFX.apply_hitstop(CombatFX.HITSTOP_HEAVY)

	if hit_count == 0:
		_sfx("sword_swing", 0.05)
		_screen_shake(1.5, 0.06)
		_vfx("vfx_dust_puff", global_position + Vector2(facing * 30.0, 8.0))
	else:
		_screen_shake(5.0 + combo_step * 2.5, 0.12)
		if parry_counter_active:
			parry_counter_active = false

	await get_tree().create_timer(active_window).timeout
	# Interrupted (e.g. by take_damage) — do not resolve this attack any further.
	if _attack_token != my_token:
		return
	if not is_inside_tree():
		return
	can_cancel_attack = true
	attack_recovery_timer = recovery
	await get_tree().create_timer(recovery).timeout
	# Interrupted (e.g. by take_damage) — do not resolve this attack any further.
	if _attack_token != my_token:
		return
	if not is_inside_tree():
		return
	can_cancel_attack = false
	is_attacking = false
	_consume_attack_buffer_if_ready()


func _handle_charged_attack() -> void:
	pass


func _perform_charged_attack() -> void:
	_attack_token += 1
	var my_token: int = _attack_token
	is_attacking = true
	attack_cooldown = CHARGED_ATTACK_STARTUP + CHARGED_ATTACK_ACTIVE + CHARGED_ATTACK_RECOVERY
	combo_step = 0
	combo_timer = 0.0

	var damage = attack_damage * CHARGED_ATTACK_MULT * _get_combo_multiplier()
	var facing = facing_direction

	_sfx("charged_release")
	_screen_shake(15.0, 0.3)
	if has_node("/root/CombatFX"):
		CombatFX.apply_hitstop(0.1)

	# Charged attack animation — dramatic lunge + flash
	var anim_target = _sprite if _sprite else self
	TweenAnimator.play_charged_attack(anim_target, facing)
	_request_combat_visual("charged_slash", attack_cooldown)

	var slash_pos = global_position + Vector2(60.0 * facing, -15.0)
	_vfx("vfx_slash_arc", slash_pos)
	_vfx("vfx_glitch_sparkle", slash_pos)
	_metric_attack_window("charged_slash", CHARGED_ATTACK_STARTUP, CHARGED_ATTACK_ACTIVE, CHARGED_ATTACK_RECOVERY, CHARGED_ATTACK_STARTUP + CHARGED_ATTACK_ACTIVE)

	velocity.x = facing * 90.0
	await get_tree().create_timer(CHARGED_ATTACK_STARTUP).timeout
	# Interrupted (e.g. by take_damage) — do not resolve this attack any further.
	if _attack_token != my_token:
		return
	if not is_inside_tree() or is_dead:
		return

	var hit_count := 0
	var hitbox_size := Vector2(CHARGED_ATTACK_RANGE, 96.0)
	var hitbox_offset := Vector2(facing * hitbox_size.x * 0.5, -8.0)
	var enemies = _get_enemies_in_melee_hitbox(hitbox_offset, hitbox_size, Color(0.3, 0.85, 1.0, 0.25))
	for enemy in enemies:
		if not is_instance_valid(enemy):
			continue
		if enemy.has_method("take_damage"):
			enemy.take_damage(damage, global_position)
			hit_count += 1
			# Track combo for charged attacks
			total_combo_hits += 1
			combo_decay_timer = COMBO_DECAY_TIME
			if total_combo_hits > GameManager.stats.get("highest_combo", 0):
				GameManager.stats["highest_combo"] = total_combo_hits
			GameManager.stats["total_damage_dealt"] = GameManager.stats.get("total_damage_dealt", 0) + int(damage)
			if has_node("/root/GameJuice"):
				GameJuice.on_hit_connect(self, enemy, damage, true)
			if has_node("/root/CombatFX"):
				CombatFX.apply_hit_effects(damage, enemy.global_position, true)
				CombatFX.apply_hitstop(CombatFX.HITSTOP_HEAVY)
				var hit_dir = (enemy.global_position - global_position).normalized()
				CombatFX.apply_directional_shake(14.0, 0.25, hit_dir)
				CombatFX.apply_zoom_pulse(1.08, 0.3)
			_vfx("vfx_hit_spark", enemy.global_position)
			_spawn_damage_number(int(damage), enemy.global_position + Vector2(0, -40), true, Color(1.0, 0.85, 0.2))

	if hit_count > 0:
		_screen_shake(18.0, 0.3)

	await get_tree().create_timer(CHARGED_ATTACK_ACTIVE).timeout
	# Interrupted (e.g. by take_damage) — do not resolve this attack any further.
	if _attack_token != my_token:
		return
	if not is_inside_tree():
		return
	can_cancel_attack = true
	attack_recovery_timer = CHARGED_ATTACK_RECOVERY
	await get_tree().create_timer(CHARGED_ATTACK_RECOVERY).timeout
	# Interrupted (e.g. by take_damage) — do not resolve this attack any further.
	if _attack_token != my_token:
		return
	if not is_inside_tree():
		return
	can_cancel_attack = false
	is_attacking = false
	_consume_attack_buffer_if_ready()


# ══════════════════════════════════════════════════════════════════════════
# DASH (i-frames)
# ══════════════════════════════════════════════════════════════════════════

func _handle_dash() -> void:
	if Input.is_action_just_pressed("sprint") and not is_healing and not is_casting:
		if dash_cooldown_timer > 0.0 or is_dashing:
			dash_buffer_timer = float(DASH_BUFFER_FRAMES) / 60.0
			return
		if not is_on_floor() and (not AIR_DASH_ENABLED or not dash_available):
			return
		if is_attacking and ATTACK_CANCEL_INTO_DASH and can_cancel_attack:
			is_attacking = false
			attack_recovery_timer = 0.0
		if not is_attacking:
			_start_dash()


func _start_dash() -> void:
	is_dashing = true
	is_healing = false
	_sfx("dash")
	if has_node("/root/GameJuice"):
		GameJuice.on_dash_start(self)
	dash_timer = DASH_DURATION
	var dc = DASH_COOLDOWN
	if GameManager.has_charm("dash_master"):
		dc *= GameManager.get_charm_value("dash_master", 1.0)
	dash_cooldown_timer = dc
	dash_direction = facing_direction
	_perfect_dodge_awarded = false

	invulnerable = true
	invuln_timer = DASH_DURATION + 0.05
	dash_cooldown_timer = maxf(dash_cooldown_timer, DASH_DURATION + 0.06)

	velocity.x = dash_direction * DASH_SPEED
	velocity.y = 0.0

	for i in DASH_GHOST_COUNT:
		_spawn_dash_ghost(i * 0.04)

	_vfx("vfx_dust_puff", global_position)
	_set_sprite_color(Color(0.4, 0.7, 1.0, 0.6))


func _spawn_dash_ghost(delay: float) -> void:
	if not is_inside_tree():
		return
	await get_tree().create_timer(delay).timeout
	if not is_inside_tree():
		return

	var ghost = ColorRect.new()
	ghost.size = Vector2(30, 48)
	ghost.position = global_position + Vector2(-15, -40)
	ghost.color = Color(0.3, 0.6, 1.0, 0.5)
	ghost.z_index = -1
	ghost.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var parent_node = get_parent()
	if parent_node:
		parent_node.add_child(ghost)
		var tween = ghost.create_tween()
		tween.set_parallel(true)
		tween.tween_property(ghost, "modulate:a", 0.0, 0.25).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		tween.tween_property(ghost, "scale", Vector2(0.8, 1.1), 0.25).set_trans(Tween.TRANS_SINE)
		tween.chain().tween_callback(ghost.queue_free)
	_vfx("vfx_dust_puff", global_position)


func _end_dash() -> void:
	is_dashing = false
	if not is_on_floor():
		dash_available = false
	_set_sprite_color(Color.WHITE)
	if has_node("/root/GameJuice"):
		GameJuice.on_dash_end(self)

	if DASH_CANCEL_INTO_ATTACK and attack_buffer_timer > 0.0:
		attack_buffer_timer = 0.0
		_perform_combo_attack()

	if GameManager.has_charm("dash_master"):
		var enemies = get_tree().get_nodes_in_group("enemies")
		for enemy in enemies:
			if is_instance_valid(enemy) and global_position.distance_to(enemy.global_position) < 80.0:
				if enemy.has_method("take_damage"):
					enemy.take_damage(10.0, global_position)
					_vfx("vfx_hit_spark", enemy.global_position)
					_spawn_damage_number(10, enemy.global_position + Vector2(0, -30), false, Color(0.4, 0.7, 1.0))


# ══════════════════════════════════════════════════════════════════════════
# DEFEND / PARRY
# ══════════════════════════════════════════════════════════════════════════

func _handle_defend() -> void:
	if Input.is_action_just_pressed("defend") and parry_cooldown_timer <= 0.0 and not is_attacking and not is_dashing and not is_healing and not is_casting:
		_start_parry()
	is_defending = Input.is_action_pressed("defend") and not is_attacking and not is_dashing and not is_healing and not is_casting


func _start_parry() -> void:
	parry_active = true
	_sfx("parry")
	var pw = PARRY_WINDOW * GameManager.get_charm_value("extended_parry", 1.0)
	# Pass 57: Accessibility assist — extended parry window
	if has_node("/root/GameManager") and GameManager.get_accessibility("extended_parry_window", false):
		pw += 0.10
	parry_window_timer = pw
	parry_cooldown_timer = PARRY_COOLDOWN

	_set_sprite_color(Color(0.3, 1.0, 0.5))
	await get_tree().create_timer(pw).timeout  # Pass 57: Use computed pw instead of raw constant
	if not is_inside_tree():
		return
	if is_instance_valid(self):
		_set_sprite_color(Color(0.6, 0.6, 0.9) if is_defending else Color.WHITE)


# ══════════════════════════════════════════════════════════════════════════
# POGO STRIKE
# ══════════════════════════════════════════════════════════════════════════

func _handle_pogo() -> void:
	if not is_on_floor() and pogo_cooldown <= 0.0:
		var manual_pogo = Input.is_action_pressed("move_down") and Input.is_action_just_pressed("attack")
		var auto_pogo_enabled = false
		if has_node("/root/GameManager"):
			auto_pogo_enabled = GameManager.get_accessibility("auto_pogo", false)
		var auto_pogo = auto_pogo_enabled and Input.is_action_pressed("move_down") and Input.is_action_pressed("attack")
		if manual_pogo or auto_pogo:
			_execute_pogo()


func _execute_pogo() -> void:
	is_pogoing = true
	pogo_cooldown = 0.2
	_request_combat_visual("downslash", maxf(POGO_ACTIVE, 0.18))
	_metric_attack_window("pogo", 0.0, POGO_ACTIVE, 0.0, 0.0)
	# Don't set downward velocity here — only bounce on hit

	var pogo_mult = POGO_DAMAGE_MULT
	if GameManager.has_charm("pogo_master"):
		pogo_mult *= GameManager.get_charm_value("pogo_master", 1.0)
	var combo_mult = _get_combo_multiplier()
	var pogo_dmg = attack_damage * pogo_mult * combo_mult

	var enemies = _get_enemies_in_melee_hitbox(Vector2(0.0, 55.0), Vector2(90.0, 105.0), Color(0.95, 0.95, 1.0, 0.22))
	for enemy in enemies:
		if not is_instance_valid(enemy):
			continue
		var diff = enemy.global_position - global_position
		if diff.y > 0.0 and diff.y < 100.0 and absf(diff.x) < 65.0:
			if enemy.has_method("take_damage"):
				var pre_hp: float = enemy.current_health if "current_health" in enemy else -1.0
				enemy.take_damage(pogo_dmg, global_position)
				var post_hp: float = enemy.current_health if "current_health" in enemy else -1.0
				if pre_hp > 0.0 and post_hp <= 0.0:
					if has_node("/root/Achievements"):
						Achievements.try_unlock("pogo_kill")

			var bounce_vel = POGO_VELOCITY
			if GameManager.has_charm("pogo_master"):
				bounce_vel *= 1.3
			velocity.y = bounce_vel
			dash_available = true
			coyote_timer = float(COYOTE_FRAMES) / 60.0
			air_jumps_remaining = MAX_AIR_JUMPS
			has_double_jumped = false
			# Pogo VFX + damage number
			_vfx("vfx_hit_spark", enemy.global_position + Vector2(0, -10))
			_spawn_damage_number(int(pogo_dmg), enemy.global_position + Vector2(0, -40))
			# ── Pogo bounce squash-stretch animation ──
			var pogo_anim_target = _sprite if _sprite else self
			TweenAnimator.play_pogo_bounce(pogo_anim_target)
			# ── Hollow Knight pogo feel: hitstop + directional shake via GameJuice ──
			if has_node("/root/GameJuice"):
				GameJuice.on_pogo_bounce(self, enemy, pogo_dmg)
			else:
				_sfx("pogo_bounce")
				_screen_shake(10.0, 0.2)
				if has_node("/root/CombatFX"):
					CombatFX.apply_hit_effects(pogo_dmg, enemy.global_position, false)
			is_pogoing = false
			return

	is_pogoing = false


# ══════════════════════════════════════════════════════════════════════════
# SPELLS
# ══════════════════════════════════════════════════════════════════════════

func _handle_spell() -> void:
	if is_casting or is_healing or is_dashing or is_attacking or cast_lock_timer > 0.0:
		return
	if Input.is_action_just_pressed("spell"):
		if not _has_mp(SPELL_COST):
			_flash_mp_bar()
			return
		if Input.is_action_pressed("move_down") and not is_on_floor():
			_cast_desolate_dive()
		elif Input.is_action_pressed("move_up"):
			_cast_howling_wraiths()
		else:
			_cast_vengeful_spirit()


func _cast_vengeful_spirit() -> void:
	if has_node("/root/GameJuice"):
		GameJuice.on_spell_cast(self, "vengeful_spirit")
	is_casting = true
	cast_lock_timer = 0.4
	_spend_mp(SPELL_COST)
	_sfx("spell_cast")

	# IMP 15: Spell cast animation
	var spell_anim_target = _sprite if _sprite else self
	TweenAnimator.play_spell_cast(spell_anim_target, "vengeful_spirit")

	if has_node("/root/CombatFX"):
		CombatFX.apply_hitstop(0.06)
	_screen_shake(10.0, 0.2)

	var proj = _create_spell_projectile()
	proj.global_position = global_position + Vector2(30.0 * facing_direction, -5.0)
	get_parent().add_child(proj)

	_vfx("vfx_glitch_sparkle", global_position + Vector2(20.0 * facing_direction, 0.0))
	_set_sprite_color(Color(0.6, 0.8, 1.0))

	await get_tree().create_timer(0.3).timeout
	if not is_inside_tree():
		return
	is_casting = false
	if is_instance_valid(self):
		_set_sprite_color(Color.WHITE)


func _create_spell_projectile() -> Area2D:
	var projectile = Area2D.new()
	projectile.name = "VengefulSpirit"
	projectile.add_to_group("player_projectiles")
	projectile.collision_layer = 0
	projectile.collision_mask = 4

	var shape = CollisionShape2D.new()
	var capsule = CapsuleShape2D.new()
	capsule.radius = 12.0
	capsule.height = 40.0
	shape.shape = capsule
	shape.rotation_degrees = 90.0
	projectile.add_child(shape)

	var visual = ColorRect.new()
	visual.color = Color(0.4, 0.7, 1.0, 0.9)
	visual.size = Vector2(40, 20)
	visual.position = Vector2(-20, -10)
	visual.mouse_filter = Control.MOUSE_FILTER_IGNORE
	projectile.add_child(visual)

	var trail = ColorRect.new()
	trail.color = Color(0.3, 0.6, 1.0, 0.4)
	trail.size = Vector2(60, 14)
	trail.position = Vector2(-40.0 if facing_direction > 0.0 else 0.0, -7.0)
	trail.mouse_filter = Control.MOUSE_FILTER_IGNORE
	projectile.add_child(trail)

	var direction = facing_direction
	var spd = VENGEFUL_SPIRIT_SPEED
	var damage = VENGEFUL_SPIRIT_DAMAGE

	projectile.body_entered.connect(func(body: Node2D) -> void:
		# BUG 10 FIX: Guard against dual-free (projectile may already be freed)
		if not is_instance_valid(projectile): return
		if not is_instance_valid(self): return  # Pass 55: Guard stale player ref
		if body.is_in_group("enemies") and body.has_method("take_damage"):
			body.take_damage(damage, projectile.global_position)
			# Track combo for spell hits
			total_combo_hits += 1
			combo_decay_timer = COMBO_DECAY_TIME
			if has_node("/root/GameJuice"):
				GameJuice.on_hit_connect(self, body, damage, true)
			if has_node("/root/CombatFX"):
				CombatFX.apply_hit_effects(damage, body.global_position, true)
			if has_node("/root/VFXLibrary"):
				VFXLibrary.spawn("vfx_hit_spark", body.global_position, get_parent())
				VFXLibrary.spawn_damage_number(int(damage), body.global_position + Vector2(0, -30), get_parent(), true, Color(0.4, 0.8, 1.0))
			projectile.queue_free()
	)

	projectile.set_meta("direction", direction)
	projectile.set_meta("speed", spd)
	projectile.set_meta("lifetime", 2.0)
	projectile.set_script(_get_projectile_script())
	return projectile


func _get_projectile_script() -> GDScript:
	if _cached_projectile_script != null:
		return _cached_projectile_script
	var script = GDScript.new()
	script.source_code = """extends Area2D
var lifetime: float = 2.0
var dir: float = 1.0
var spd: float = 700.0
func _ready():
	lifetime = get_meta("lifetime", 2.0)
	dir = get_meta("direction", 1.0)
	spd = get_meta("speed", 700.0)
func _process(delta):
	position.x += dir * spd * delta
	lifetime -= delta
	if lifetime <= 0:
		queue_free()
"""
	script.reload()
	_cached_projectile_script = script
	return script


func _cast_desolate_dive() -> void:
	if has_node("/root/GameJuice"):
		GameJuice.on_spell_cast(self, "desolate_dive")
	is_casting = true
	cast_lock_timer = 0.5
	_spend_mp(SPELL_COST)
	_sfx("spell_cast")

	# IMP 15: Spell cast animation
	var spell_anim_target = _sprite if _sprite else self
	TweenAnimator.play_spell_cast(spell_anim_target, "desolate_dive")

	velocity.y = 800.0
	velocity.x = 0.0

	var timeout = 0.0
	while not is_on_floor() and timeout < 1.5 and is_casting:
		await get_tree().process_frame
		if not is_inside_tree():
			return
		timeout += get_process_delta_time()

	if not is_on_floor():
		is_casting = false
		return

	_sfx("heavy_hit")
	_screen_shake(25.0, 0.4)
	if has_node("/root/CombatFX"):
		CombatFX.apply_hitstop(0.12)
	_vfx("vfx_glitch_sparkle", global_position)
	_vfx("vfx_dust_puff", global_position + Vector2(-30, 5))
	_vfx("vfx_dust_puff", global_position + Vector2(30, 5))

	var enemies = get_tree().get_nodes_in_group("enemies")
	for enemy in enemies:
		if not is_instance_valid(enemy):
			continue
		var dist = global_position.distance_to(enemy.global_position)
		if dist < 180.0:
			if enemy.has_method("take_damage"):
				var dmg = maxf(DESOLATE_DIVE_DAMAGE * (1.0 - dist / 300.0), DESOLATE_DIVE_DAMAGE * 0.5)
				enemy.take_damage(dmg, global_position)
				total_combo_hits += 1
				combo_decay_timer = COMBO_DECAY_TIME
				if has_node("/root/GameJuice"):
					GameJuice.on_hit_connect(self, enemy, dmg, true)
				if has_node("/root/CombatFX"):
					CombatFX.apply_hit_effects(dmg, enemy.global_position, true)
				_vfx("vfx_hit_spark", enemy.global_position)
				_spawn_damage_number(int(dmg), enemy.global_position + Vector2(0, -30), true, Color(1.0, 0.6, 0.2))

	invulnerable = true
	invuln_timer = 0.3

	await get_tree().create_timer(0.4).timeout
	if not is_inside_tree():
		return
	is_casting = false


func _cast_howling_wraiths() -> void:
	if has_node("/root/GameJuice"):
		GameJuice.on_spell_cast(self, "howling_wraiths")
	is_casting = true
	cast_lock_timer = 0.4
	_spend_mp(SPELL_COST)
	_sfx("spell_cast")

	# IMP 15: Spell cast animation
	var spell_anim_target = _sprite if _sprite else self
	TweenAnimator.play_spell_cast(spell_anim_target, "howling_wraiths")

	invulnerable = true
	invuln_timer = 0.25

	if has_node("/root/CombatFX"):
		CombatFX.apply_hitstop(0.08)
	_screen_shake(15.0, 0.3)
	_vfx("vfx_glitch_sparkle", global_position + Vector2(0, -30))
	_vfx("vfx_glitch_sparkle", global_position + Vector2(-20, -60))
	_vfx("vfx_glitch_sparkle", global_position + Vector2(20, -60))

	var enemies = get_tree().get_nodes_in_group("enemies")
	for enemy in enemies:
		if not is_instance_valid(enemy):
			continue
		var diff = enemy.global_position - global_position
		var dist = diff.length()
		if dist < HOWLING_WRAITHS_RANGE and diff.y < 30.0:
			if enemy.has_method("take_damage"):
				var dmg = maxf(HOWLING_WRAITHS_DAMAGE * (1.0 - dist / (HOWLING_WRAITHS_RANGE * 1.5)), HOWLING_WRAITHS_DAMAGE * 0.5)
				enemy.take_damage(dmg, global_position)
				total_combo_hits += 1
				combo_decay_timer = COMBO_DECAY_TIME
				if has_node("/root/GameJuice"):
					GameJuice.on_hit_connect(self, enemy, dmg, true)
				if has_node("/root/CombatFX"):
					CombatFX.apply_hit_effects(dmg, enemy.global_position, true)
				_vfx("vfx_hit_spark", enemy.global_position)
				_spawn_damage_number(int(dmg), enemy.global_position + Vector2(0, -30), true, Color(0.8, 0.5, 1.0))

	_set_sprite_color(Color(0.8, 0.5, 1.0))
	await get_tree().create_timer(0.35).timeout
	if not is_inside_tree():
		return
	is_casting = false
	if is_instance_valid(self):
		_set_sprite_color(Color.WHITE)


# ══════════════════════════════════════════════════════════════════════════
# HEAL
# ══════════════════════════════════════════════════════════════════════════

func _handle_heal() -> void:
	# Hollow Knight style: HOLD heal button to channel, release or damage cancels
	if is_healing:
		# Currently channeling — check for release or completion
		if not Input.is_action_pressed("heal"):
			_cancel_heal()
			return
		heal_timer += get_physics_process_delta_time()
		# Visual feedback: pulse green while channeling
		var pulse = 0.5 + 0.5 * sin(heal_timer * 8.0)
		_set_sprite_color(Color(0.3, 0.5 + pulse * 0.5, 0.3))
		# Channel complete — heal!
		if heal_timer >= HEAL_CHANNEL_TIME:
			_complete_heal()
			is_healing = false
			heal_timer = 0.0
		return

	# Start channeling
	if Input.is_action_just_pressed("heal") and not is_dashing and not is_attacking and not is_casting:
		if _has_mp(HEAL_COST) and current_health < max_health:
			is_healing = true
			heal_timer = 0.0
			velocity.x = 0.0  # Stand still while channeling
			_sfx("heal")
			_spawn_status("Channeling...")
		elif not _has_mp(HEAL_COST):
			_flash_mp_bar()
			_spawn_status("Need %d MP!" % int(_get_effective_cost(HEAL_COST)))
		elif current_health >= max_health:
			_spawn_status("HP Full!")


func _complete_heal() -> void:
	_spend_mp(HEAL_COST)
	_sfx("heal")

	var heal_amount = minf(HEAL_AMOUNT, max_health - current_health)
	if has_node("/root/GameManager"):
		heal_amount *= GameManager.get_player_dda_bonus()
		heal_amount = minf(heal_amount, max_health - current_health)
	current_health += heal_amount
	GameManager.player_stats["hp"] = int(current_health)
	health_changed.emit(current_health, max_health)
	_update_hud()

	_vfx("vfx_heal_ring", global_position + Vector2(0, -20))
	_vfx("vfx_glitch_sparkle", global_position + Vector2(0, -30))
	_spawn_status("+%d HP" % int(heal_amount))
	if has_node("/root/GameJuice"):
		GameJuice.on_heal(self)

	_set_sprite_color(Color(0.5, 1.5, 0.5))
	_screen_shake(3.0, 0.1)
	await get_tree().create_timer(0.12).timeout
	if not is_inside_tree():
		return
	_set_sprite_color(Color.WHITE)


func _cancel_heal() -> void:
	is_healing = false
	heal_timer = 0.0
	_set_sprite_color(Color.WHITE)
	# Audio/visual feedback for interrupted heal
	_sfx("sword_swing", 0.05)
	_vfx("vfx_dust_puff", global_position + Vector2(0, -10))
	_spawn_status("Heal Interrupted!", Vector2(0, -60))


# ══════════════════════════════════════════════════════════════════════════
# FLEE COMBAT (Random encounters only — cannot flee boss fights)
# ══════════════════════════════════════════════════════════════════════════

var _flee_cooldown: float = 0.0

func _handle_flee_combat() -> void:
	if _flee_cooldown > 0.0:
		_flee_cooldown -= get_physics_process_delta_time()
		return
	if not Input.is_action_just_pressed("flee_combat"):
		return
	# Cannot flee boss fights
	if GameManager.has_meta("boss_fight_id") and GameManager.get_meta("boss_fight_id") != "":
		_spawn_status("CANNOT FLEE!")
		_flee_cooldown = 1.5
		return
	# Check if RandomEncounterSystem is available for flee chance
	if not has_node("/root/RandomEncounterSystem"):
		_spawn_status("No escape!")
		return

	var flee_result = RandomEncounterSystem.attempt_flee()
	if flee_result:
		_spawn_status("ESCAPED!")
		_sfx("sword_swing", 0.1)
		# Brief invuln then exit combat
		invulnerable = true
		invuln_timer = 1.0
		await get_tree().create_timer(0.5).timeout
		if not is_inside_tree():
			return
		RandomEncounterSystem.end_encounter(false)
	else:
		_spawn_status("FLEE FAILED!")
		_flee_cooldown = 2.0
		# Enemies get a free hit window — flash warning
		_set_sprite_color(Color(1.0, 0.5, 0.5))
		await get_tree().create_timer(0.2).timeout
		if not is_inside_tree():
			return
		_set_sprite_color(Color.WHITE)


# ══════════════════════════════════════════════════════════════════════════
# DIRECTIONAL ATTACK
# ══════════════════════════════════════════════════════════════════════════

func _handle_directional_attack() -> void:
	if is_dashing or is_defending or is_healing or is_casting or is_charging:
		return
	if Input.is_action_just_pressed("attack") and Input.is_action_pressed("move_up") and attack_cooldown <= 0.0:
		_perform_upslash()


func _perform_upslash() -> void:
	if attack_cooldown > 0.0 or is_attacking:
		return

	_attack_token += 1
	var my_token: int = _attack_token
	is_attacking = true
	attack_cooldown = UPSLASH_STARTUP + UPSLASH_ACTIVE + UPSLASH_RECOVERY
	_sfx("sword_swing", 0.1)

	var damage = attack_damage * UPSLASH_DAMAGE_MULT
	var counter_mult = parry_counter_damage_mult if parry_counter_active else 1.0
	var combo_mult = _get_combo_multiplier()
	var final_damage = damage * counter_mult * combo_mult

	var anim_target = _sprite if _sprite else self
	TweenAnimator.play_upslash(anim_target, facing_direction)
	_request_combat_visual("upslash", attack_cooldown)
	_vfx("vfx_slash_arc", global_position + Vector2(0, -50))
	_metric_attack_window("upslash", UPSLASH_STARTUP, UPSLASH_ACTIVE, UPSLASH_RECOVERY, UPSLASH_STARTUP + UPSLASH_ACTIVE)
	await get_tree().create_timer(UPSLASH_STARTUP).timeout
	# Interrupted (e.g. by take_damage) — do not resolve this attack any further.
	if _attack_token != my_token:
		return
	if not is_inside_tree() or is_dead:
		return

	var hit_count = 0
	var enemies = _get_enemies_in_melee_hitbox(Vector2(0.0, -UPSLASH_RANGE * 0.5), Vector2(90.0, UPSLASH_RANGE), Color(0.55, 0.75, 1.0, 0.22))
	for enemy in enemies:
		if not is_instance_valid(enemy):
			continue
		var diff = enemy.global_position - global_position
		if diff.y < 0.0 and diff.y > -UPSLASH_RANGE and absf(diff.x) < 60.0:
			if enemy.has_method("take_damage"):
				enemy.take_damage(final_damage, global_position)
				hit_count += 1
				total_combo_hits += 1
				combo_decay_timer = COMBO_DECAY_TIME
				if has_node("/root/CombatFX"):
					CombatFX.apply_hit_effects(final_damage, enemy.global_position, parry_counter_active)
				_vfx("vfx_hit_spark", enemy.global_position)
				_spawn_damage_number(int(final_damage), enemy.global_position + Vector2(0, -30), parry_counter_active)

	if hit_count > 0:
		_screen_shake(8.0, 0.15)
		if has_node("/root/CombatFX"):
			CombatFX.apply_hitstop(0.06)

	await get_tree().create_timer(UPSLASH_ACTIVE).timeout
	# Interrupted (e.g. by take_damage) — do not resolve this attack any further.
	if _attack_token != my_token:
		return
	if not is_inside_tree():
		return
	can_cancel_attack = true
	attack_recovery_timer = UPSLASH_RECOVERY
	await get_tree().create_timer(UPSLASH_RECOVERY).timeout
	# Interrupted (e.g. by take_damage) — do not resolve this attack any further.
	if _attack_token != my_token:
		return
	if not is_inside_tree():
		return
	can_cancel_attack = false
	is_attacking = false
	_consume_attack_buffer_if_ready()


# ══════════════════════════════════════════════════════════════════════════
# SOUL MANAGEMENT
# ══════════════════════════════════════════════════════════════════════════

func _add_soul(amount: float) -> void:
	if has_node("/root/GameManager"):
		amount = int(amount * GameManager.get_player_dda_bonus())
	if has_node("/root/GameManager") and GameManager.has_charm("soul_hoarder"):  # Pass 55: Guard autoload
		amount *= GameManager.get_charm_value("soul_hoarder", 1.0)
	# Apply choice consequence soul gain multiplier
	if has_node("/root/ChoiceConsequences"):
		amount *= ChoiceConsequences.get_soul_gain_multiplier()
	current_soul = minf(current_soul + amount, MAX_SOUL)
	GameManager.player_stats["soul"] = int(current_soul)
	soul_changed.emit(current_soul, MAX_SOUL)
	_update_hud()


func _spend_soul(amount: float) -> void:
	amount = _get_effective_cost(amount)
	current_soul = maxf(0.0, current_soul - amount)
	GameManager.player_stats["soul"] = int(current_soul)
	soul_changed.emit(current_soul, MAX_SOUL)
	_update_hud()


## Called by EnemyBase when this player's damage kills an enemy.
func on_enemy_killed() -> void:
	_add_soul(SOUL_PER_KILL)


# ── MP (spells, skills, healing) ──────────────────────────────────────────

func _get_mp() -> float:
	return float(GameManager.player_stats.get("mp", 0))


func _get_max_mp() -> float:
	return float(GameManager.player_stats.get("max_mp", 50))


func _has_mp(base_cost: float) -> bool:
	return _get_mp() >= _get_effective_cost(base_cost)


func _spend_mp(base_cost: float) -> void:
	GameManager.player_stats["mp"] = maxf(0.0, _get_mp() - _get_effective_cost(base_cost))
	_update_hud()


func _regen_mp(delta: float) -> void:
	var max_mp := _get_max_mp()
	var mp := _get_mp()
	if mp >= max_mp:
		return
	GameManager.player_stats["mp"] = minf(max_mp, mp + MP_REGEN_PER_SEC * delta)
	_mp_hud_timer -= delta
	if _mp_hud_timer <= 0.0:
		_mp_hud_timer = 0.25
		_update_hud()


func _flash_mp_bar() -> void:
	if not _mp_bar:
		return
	var fill := _mp_bar.get_theme_stylebox("fill") as StyleBoxFlat
	if fill == null:
		return
	var normal := fill.bg_color
	fill.bg_color = Color(1.0, 0.2, 0.2)
	await get_tree().create_timer(0.25).timeout
	if is_instance_valid(self) and fill:
		fill.bg_color = normal


func _get_effective_cost(base_cost: float) -> float:
	## Returns the actual MP cost after charm discounts (soul_hoarder = 0.8x).
	if has_node("/root/GameManager") and GameManager.has_charm("soul_hoarder"):
		return base_cost * 0.8
	return base_cost


func _flash_soul_bar() -> void:
	if _soul_bar and not _soul_flashing:
		_soul_flashing = true
		var original_style = _soul_bar.get_theme_stylebox("fill")
		var flash_style = StyleBoxFlat.new()
		flash_style.bg_color = Color(1.0, 0.2, 0.2)
		flash_style.set_corner_radius_all(3)
		_soul_bar.add_theme_stylebox_override("fill", flash_style)
		await get_tree().create_timer(0.15).timeout
		if not is_inside_tree():
			return
		if is_instance_valid(self) and _soul_bar:
			_soul_bar.add_theme_stylebox_override("fill", original_style)
		_soul_flashing = false


# ══════════════════════════════════════════════════════════════════════════
# DAMAGE & DEATH
# ══════════════════════════════════════════════════════════════════════════

func take_damage(amount: float, source_position: Vector2 = Vector2.ZERO, source_name: String = "", damage_type: String = "") -> void:
	if is_dead:
		return
	if invulnerable:
		# A hit that arrives during the dash's i-frames is a perfect dodge (Soul).
		if is_dashing and not _perfect_dodge_awarded:
			_perfect_dodge_awarded = true
			_add_soul(SOUL_PER_PERFECT_DODGE)
			_spawn_status("PERFECT DODGE")
		return
	# Pass 57: Invincibility assist mode
	if has_node("/root/GameManager") and GameManager.get_accessibility("invincibility_mode", false):
		return
	# Pass 57: Difficulty-based enemy damage scaling
	if has_node("/root/GameManager"):
		amount *= GameManager.get_enemy_damage_mult()
		# Read DEF live so equipment changed mid-fight counts immediately.
		amount = mitigate_by_defense(amount, float(GameManager.player_stats.get("defense", 0)))

	if source_name != "":
		_last_damage_source = source_name
	_last_damage_type = damage_type

	# Perfect parry
	if parry_active:
		_on_successful_parry(amount, source_position)
		return

	# Block
	if is_defending:
		amount *= (1.0 - BLOCK_DAMAGE_REDUCTION)
		_sfx("block")
		_vfx("vfx_hit_spark", global_position + Vector2(facing_direction * 20.0, -10.0))

	if is_healing:
		_cancel_heal()

	# Reset attack state — prevents getting stuck in attack after being hit.
	# Bumping the token also invalidates any attack coroutine still parked on an
	# await, so it cannot land a hit or clobber the next attack's state.
	_attack_token += 1
	is_attacking = false
	can_cancel_attack = false
	attack_recovery_timer = 0.0
	combo_step = 0
	combo_timer = 0.0
	attack_cooldown = 0.0
	is_charging = false
	charge_timer = 0.0
	charged_attack_ready = false
	is_casting = false
	cast_lock_timer = 0.0

	current_health = maxf(current_health - amount, 0.0)
	GameManager.player_stats["hp"] = int(current_health)
	GameManager.stats["total_damage_taken"] = GameManager.stats.get("total_damage_taken", 0) + int(amount)
	if has_node("/root/GameManager"):
		GameManager.record_dda_hit_taken(amount)
	# HP bar damage flash
	if _hp_bar:
		if _hp_flash_tween and _hp_flash_tween.is_valid():
			_hp_flash_tween.kill()  # Pass 59: Kill previous flash to prevent tween leak
		_hp_flash_tween = create_tween()
		_hp_flash_tween.tween_property(_hp_bar, "modulate", Color(1, 0.3, 0.3), 0.05)
		_hp_flash_tween.tween_property(_hp_bar, "modulate", Color.WHITE, 0.15)
	# Track boss fight damage for flawless achievement
	if GameManager.boss_fight_active:
		GameManager.record_boss_hit_taken()
	health_changed.emit(current_health, max_health)
	_update_hud()

	_sfx("player_hurt", 0.1)
	_screen_shake(20.0, 0.4)
	if has_node("/root/CombatFX"):
		CombatFX.apply_hitstop(0.08)
	var hurt_target = _sprite if _sprite else self
	TweenAnimator.play_hurt(hurt_target)
	_request_combat_visual("hurt", 0.25)
	_vfx("vfx_hit_spark", global_position)
	_spawn_damage_number(int(amount), global_position + Vector2(0, -30), false, Color(1.0, 0.3, 0.3))
	# ── GameJuice player hurt: red screen flash + camera trauma + combo reset ──
	if has_node("/root/GameJuice"):
		GameJuice.on_player_hurt(self, amount)

	# Thorns charm
	if GameManager.has_charm("thorns") and source_position != Vector2.ZERO:
		var thorns_dmg = GameManager.get_charm_value("thorns", 15.0)
		var enemies = get_tree().get_nodes_in_group("enemies")
		var closest_enemy: Node2D = null
		var closest_dist: float = 200.0
		for enemy in enemies:
			if not is_instance_valid(enemy) or not enemy.has_method("take_damage"):
				continue
			var dist = source_position.distance_to(enemy.global_position)
			if dist < closest_dist:
				closest_dist = dist
				closest_enemy = enemy
		if closest_enemy:
			closest_enemy.take_damage(thorns_dmg, global_position)
			_vfx("vfx_hit_spark", closest_enemy.global_position)
			_spawn_damage_number(int(thorns_dmg), closest_enemy.global_position + Vector2(0, -30), false, Color(1.0, 0.5, 0.0))

	# Knockback
	var knockback_dir = -1.0
	if source_position != Vector2.ZERO:
		knockback_dir = signf(global_position.x - source_position.x)
	elif velocity.x != 0.0:
		knockback_dir = -signf(velocity.x)
	velocity.x = knockback_dir * 400.0
	velocity.y = -220.0

	invulnerable = true
	invuln_timer = 1.0
	var iframe_target = _sprite if _sprite else self
	if has_node("/root/GameJuice"):
		GameJuice.flash_invincibility(iframe_target, 1.0)
		GameJuice.reset_combo()

	if current_health <= 0.0:
		die()


func apply_knockback(force: Vector2) -> void:
	velocity += force


func _on_successful_parry(damage: float, _source_position: Vector2) -> void:
	parry_active = false
	_sfx("parry_perfect")
	GameManager.stats["parries_landed"] = GameManager.stats.get("parries_landed", 0) + 1

	if has_node("/root/CombatFX"):
		CombatFX.apply_hitstop(PARRY_FREEZE_TIME)
	_screen_shake(18.0, 0.3)
	if has_node("/root/GameJuice"):
		GameJuice.on_parry(self)

	_set_sprite_color(Color(1.0, 1.0, 0.5))
	_add_soul(SOUL_PER_PARRY)
	_spawn_status("+SOUL")

	parry_counter_active = true
	parry_counter_timer = PARRY_COUNTERATTACK_WINDOW
	_spawn_status("COUNTER!", Vector2(0, -80))

	total_combo_hits += 1
	combo_decay_timer = COMBO_DECAY_TIME

	var enemies = get_tree().get_nodes_in_group("enemies")
	for enemy in enemies:
		if not is_instance_valid(enemy):
			continue
		if global_position.distance_to(enemy.global_position) < 120.0:
			if enemy.has_method("stagger"):
				enemy.stagger(1.2)
			elif enemy.has_method("take_damage"):
				enemy.take_damage(damage * 0.5, global_position)

	_vfx("vfx_hit_spark", global_position + Vector2(facing_direction * 30.0, -10.0))
	_vfx("vfx_parry_flash", global_position + Vector2(facing_direction * 30.0, -10.0))
	_spawn_damage_number(int(damage), global_position + Vector2(0, -40), false, Color(0.3, 1.0, 0.3))

	invulnerable = true
	invuln_timer = 0.4

	await get_tree().create_timer(0.12).timeout
	if not is_inside_tree():
		return
	if is_instance_valid(self):
		_set_sprite_color(Color.WHITE)


func die() -> void:
	if is_dead:
		return
	is_dead = true
	invulnerable = true
	_sfx("player_death")
	died.emit()

	var die_target = _sprite if _sprite else self
	TweenAnimator.play_die(die_target)
	_request_combat_visual("die", 1.0)
	_vfx("vfx_data_dissolve", global_position)
	# ── Death screen flash (white) + dramatic zoom + slowmo ──
	if has_node("/root/VFXLibrary"):
		VFXLibrary.spawn("vfx_flash_red", Vector2.ZERO, get_parent())
	if has_node("/root/CombatFX"):
		CombatFX.apply_zoom_pulse(1.12, 0.5)
	if has_node("/root/GameJuice"):
		GameJuice.slowmo_moment(0.8, 0.2)
	_screen_shake(25.0, 0.6)

	await get_tree().create_timer(1.0).timeout
	if not is_inside_tree():
		return
	if bool(get_meta("local_boss_retry_enabled", false)):
		return
	await _on_death_complete()


func _on_death_complete() -> void:
	GameManager.set_story_flag("player_died", true)
	GameManager.add_death_corruption()

	if GameManager.glitch_meter >= 100.0:
		await get_tree().create_timer(0.5).timeout
		if not is_inside_tree():
			return
		if has_node("/root/SceneTransitions"):
			# BUG 14 FIX: Defer scene change to avoid changing scene from dying node
			SceneTransitions.call_deferred("change_scene", "res://scenes/game_over.tscn", SceneTransitions.TransitionStyle.GLITCH)
		return

	GameManager.player_stats["hp"] = int(GameManager.player_stats.get("max_hp", 100) * 0.5)

	var death_msg = "[DEATH DETECTED — CONSCIOUSNESS FRAGMENTED]\n"
	if _last_damage_source != "":
		death_msg += "[Terminated by: %s]\n" % _last_damage_source
	death_msg += "[CORRUPTION +1%% — Total: %.0f%%]\n" % GameManager.glitch_meter
	death_msg += "\n[TIP] %s" % _get_death_tip()
	death_msg += "\n[Reviving at last visited village...]"

	if has_node("/root/DialogueManager"):
		await DialogueManager.say("System", death_msg, Color(1, 0, 0), true)
		if not is_inside_tree():
			return
		DialogueManager.hide_dialogue()
	else:
		await get_tree().create_timer(2.0).timeout
		if not is_inside_tree():
			return

	await get_tree().create_timer(0.5).timeout
	if not is_inside_tree():
		return

	var revival_scene = GameManager.get_revival_scene()
	if has_node("/root/SceneTransitions"):
		# BUG 14 FIX: Defer scene change to avoid changing scene from dying node
		SceneTransitions.call_deferred("change_scene", revival_scene, SceneTransitions.TransitionStyle.FLASH_WHITE)
	else:
		get_tree().call_deferred("change_scene_to_file", revival_scene)


func _get_death_tip() -> String:
	var tip_pool: Array = []
	if GameManager.glitch_meter >= 75.0:
		tip_pool.append_array(DEATH_TIPS["corruption"])
	if _last_damage_type in DEATH_TIPS:
		tip_pool.append_array(DEATH_TIPS[_last_damage_type])
	var src_lower = _last_damage_source.to_lower()
	if "boss" in src_lower or "knight" in src_lower or "automaton" in src_lower or "wraith" in src_lower or "administrator" in src_lower:
		tip_pool.append_array(DEATH_TIPS["boss"])
	if tip_pool.is_empty():
		tip_pool = DEATH_TIPS["default"]
	return tip_pool[randi() % tip_pool.size()]


func heal(amount: float) -> void:
	current_health = minf(current_health + amount, max_health)
	GameManager.player_stats["hp"] = int(current_health)
	health_changed.emit(current_health, max_health)
	_update_hud()


func set_speed_multiplier(mult: float) -> void:
	speed_multiplier = clampf(mult, 0.1, 3.0)


# ══════════════════════════════════════════════════════════════════════════
# SPRITE HELPERS
# ══════════════════════════════════════════════════════════════════════════

func _set_sprite_alpha(alpha: float) -> void:
	_refresh_sprite_cache_if_needed()
	if _sprite:
		_sprite.modulate.a = alpha


func _set_sprite_color(color: Color) -> void:
	_refresh_sprite_cache_if_needed()
	if _sprite:
		_sprite.modulate = color


func _flash_red() -> void:
	_refresh_sprite_cache_if_needed()
	if not is_inside_tree() or not _sprite:
		return
	var sprite = _sprite
	sprite.modulate = Color.RED
	await get_tree().create_timer(0.1).timeout
	if not is_inside_tree() or not is_instance_valid(sprite):
		return
	sprite.modulate = Color.WHITE


func refresh_visual_references() -> void:
	## Re-cache the active Sprite child after scenes replace placeholder art.
	_sprite = get_node_or_null("Sprite")
	if _anim_controller and _anim_controller.has_method("on_sprite_replaced"):
		_anim_controller.on_sprite_replaced()
	_remember_retry_visual_baseline()


func _request_combat_visual(animation_name: String, hold_time: float) -> void:
	## The animation controller owns visual overrides; combat timing stays here.
	if _anim_controller and _anim_controller.has_method("request_combat_visual"):
		_anim_controller.request_combat_visual(animation_name, hold_time)


func force_restore_after_death_retry(spawn_position: Vector2) -> Dictionary:
	## Hard reset used by local boss retries. This kills death tweens on both
	## the root player and active visual child so a late fade cannot re-hide us.
	ContextStack.clear_time_scale()  # drop any hitstop/slow-mo
	_refresh_sprite_cache_if_needed()
	TweenAnimator._kill_existing(self)
	_restore_retry_canvas_item(self, false)

	global_position = spawn_position
	velocity = Vector2.ZERO
	is_dead = false
	invulnerable = true
	invuln_timer = 0.75
	set_meta("local_retry_disable_flicker", true)
	is_attacking = false
	is_dashing = false
	is_defending = false
	is_healing = false
	is_casting = false
	is_charging = false
	parry_active = false
	parry_counter_active = false
	charged_attack_ready = false
	attack_cooldown = 0.0
	attack_recovery_timer = 0.0
	attack_buffer_timer = 0.0
	dash_timer = 0.0
	dash_cooldown_timer = 0.0
	heal_timer = 0.0
	cast_lock_timer = 0.0
	combo_timer = 0.0
	charge_timer = 0.0
	combo_step = 0
	dash_available = true
	air_jumps_remaining = 1

	current_health = max_health
	GameManager.player_stats["hp"] = int(current_health)
	GameManager.player_stats["soul"] = int(current_soul)
	health_changed.emit(current_health, max_health)
	soul_changed.emit(current_soul, MAX_SOUL)

	collision_layer = 2
	collision_mask = 1
	for child in get_children():
		if child is CollisionShape2D:
			child.disabled = false

	if _sprite and is_instance_valid(_sprite):
		_restore_retry_visual_tree(_sprite)
		if _sprite is AnimatedSprite2D:
			var animated := _sprite as AnimatedSprite2D
			if animated.sprite_frames and animated.sprite_frames.has_animation("idle"):
				animated.play("idle")

	if _anim_controller:
		_anim_controller.on_sprite_replaced()
		_anim_controller.current_anim = ""
		_anim_controller.last_anim = ""

	set_process(true)
	set_physics_process(true)
	set_process_input(true)
	set_process_unhandled_input(true)
	if has_method("_update_hud"):
		_update_hud()

	return get_retry_visual_debug_state()


func get_retry_visual_debug_state() -> Dictionary:
	_refresh_sprite_cache_if_needed()
	var sprite_visible := false
	var sprite_alpha := -1.0
	var sprite_self_alpha := -1.0
	var sprite_scale := -1.0
	if _sprite and is_instance_valid(_sprite) and _sprite is CanvasItem:
		var canvas := _sprite as CanvasItem
		sprite_visible = canvas.visible
		sprite_alpha = canvas.modulate.a
		sprite_self_alpha = canvas.self_modulate.a
		if "scale" in canvas:
			sprite_scale = (canvas.get("scale") as Vector2).length()
	var collision_enabled := true
	for child in get_children():
		if child is CollisionShape2D and child.disabled:
			collision_enabled = false
	return {
		"player_visible": visible,
		"sprite_visible": sprite_visible,
		"player_alpha": modulate.a,
		"player_self_alpha": self_modulate.a,
		"sprite_alpha": sprite_alpha,
		"sprite_self_alpha": sprite_self_alpha,
		"sprite_scale": sprite_scale,
		"collision_enabled": collision_enabled,
		"input_enabled": is_processing_input(),
		"process_enabled": is_processing(),
		"physics_enabled": is_physics_processing(),
		"is_dead": is_dead,
		"hp": current_health,
		"time_scale": Engine.time_scale
	}


func _refresh_sprite_cache_if_needed() -> void:
	if _sprite == null or not is_instance_valid(_sprite) or (_sprite is Node and _sprite.get_parent() != self):
		_sprite = get_node_or_null("Sprite")


func _remember_retry_visual_baseline() -> void:
	_store_retry_canvas_baseline(self)
	_refresh_sprite_cache_if_needed()
	if _sprite and is_instance_valid(_sprite):
		_store_retry_visual_baseline_tree(_sprite)


func _store_retry_visual_baseline_tree(node: Node) -> void:
	if node is CanvasItem:
		_store_retry_canvas_baseline(node as CanvasItem)
	for child in node.get_children():
		_store_retry_visual_baseline_tree(child)


func _store_retry_canvas_baseline(item: CanvasItem) -> void:
	item.set_meta("retry_base_visible", item.visible)
	item.set_meta("retry_base_modulate", item.modulate)
	item.set_meta("retry_base_self_modulate", item.self_modulate)
	if item.material:
		item.set_meta("retry_base_material", item.material)
	if "position" in item:
		item.set_meta("retry_base_position", item.get("position"))
	if "rotation" in item:
		item.set_meta("retry_base_rotation", item.get("rotation"))
	if "scale" in item:
		item.set_meta("retry_base_scale", item.get("scale"))


func _restore_retry_visual_tree(node: Node) -> void:
	if node is CanvasItem:
		_restore_retry_canvas_item(node as CanvasItem, true)
	for child in node.get_children():
		_restore_retry_visual_tree(child)


func _restore_retry_canvas_item(item: CanvasItem, restore_transform: bool) -> void:
	TweenAnimator._kill_existing(item)
	item.visible = true
	var base_modulate: Color = item.get_meta("retry_base_modulate", Color.WHITE)
	base_modulate.a = 1.0
	item.modulate = base_modulate
	var base_self_modulate: Color = item.get_meta("retry_base_self_modulate", Color.WHITE)
	base_self_modulate.a = 1.0
	item.self_modulate = base_self_modulate
	if item.has_meta("retry_base_material"):
		item.material = item.get_meta("retry_base_material")
	if restore_transform:
		if "position" in item:
			item.set("position", item.get_meta("retry_base_position", item.get("position")))
		if "rotation" in item:
			item.set("rotation", item.get_meta("retry_base_rotation", item.get("rotation")))
		if "scale" in item:
			item.set("scale", item.get_meta("retry_base_scale", item.get("scale")))


# ══════════════════════════════════════════════════════════════════════════
# AUTOLOAD HELPER WRAPPERS — safe access to singletons
# ══════════════════════════════════════════════════════════════════════════

func _is_dialogue_active() -> bool:
	if has_node("/root/DialogueManager"):
		return DialogueManager.get("is_active") == true
	return false


func _sfx(sound_name: String, variation: float = 0.0) -> void:
	if has_node("/root/SFXManager"):
		if variation > 0.0:
			SFXManager.play(sound_name, variation)
		else:
			SFXManager.play(sound_name)


func _vfx(effect_name: String, pos: Vector2) -> void:
	if has_node("/root/VFXLibrary"):
		VFXLibrary.spawn(effect_name, pos, get_parent())
	# Layer Kenney sprite VFX on top for richer visuals
	if has_node("/root/AssetManager"):
		var kenney_cat := ""
		var kenney_size := Vector2(32, 32)
		var kenney_fps := 12.0
		match effect_name:
			"vfx_slash_arc":
				kenney_cat = "slash"
				kenney_size = Vector2(48, 48)
				kenney_fps = 18.0
			"vfx_hit_spark":
				kenney_cat = "spark"
				kenney_size = Vector2(28, 28)
				kenney_fps = 20.0
			"vfx_glitch_sparkle":
				kenney_cat = "magic"
				kenney_size = Vector2(40, 40)
				kenney_fps = 14.0
			"vfx_dust_puff":
				kenney_cat = "smoke"
				kenney_size = Vector2(24, 24)
				kenney_fps = 16.0
		if kenney_cat != "":
			AssetManager.spawn_oneshot_vfx(get_parent(), kenney_cat, pos, kenney_size, kenney_fps)


func _screen_shake(intensity: float, duration: float) -> void:
	## Routes through CombatFX which respects accessibility shake multiplier.
	if has_node("/root/CombatFX"):
		CombatFX.apply_screen_shake(intensity, duration)


func _spawn_damage_number(amount: int, pos: Vector2, is_crit: bool = false, color: Color = Color.WHITE) -> void:
	if has_node("/root/GameManager") and not GameManager.get_accessibility("show_damage_numbers", true):
		return
	if has_node("/root/VFXLibrary"):
		VFXLibrary.spawn_damage_number(amount, pos, get_parent(), is_crit, color)


func _spawn_status(text: String, offset: Vector2 = Vector2(0, -50)) -> void:
	if has_node("/root/VFXLibrary"):
		VFXLibrary.spawn_status_indicator(text, global_position + offset, get_parent(), false)


func _get_combo_multiplier() -> float:
	if has_node("/root/GameJuice"):
		return GameJuice.get_combo_multiplier()
	return 1.0


# ══════════════════════════════════════════════════════════════════════════
# COMBAT HUD
# ══════════════════════════════════════════════════════════════════════════

func _build_combat_hud() -> void:
	_hud_layer = CanvasLayer.new()
	_hud_layer.layer = 90
	_hud_layer.name = "CombatHUD"
	add_child(_hud_layer)

	# Top-left: HP bar
	var hp_container = VBoxContainer.new()
	hp_container.position = Vector2(20, 16)
	hp_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_hud_layer.add_child(hp_container)

	var hp_header = Label.new()
	hp_header.text = "KAELEN"
	hp_header.add_theme_color_override("font_color", Color(0.6, 0.85, 1.0))
	hp_header.add_theme_font_size_override("font_size", 13)
	hp_header.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hp_container.add_child(hp_header)

	_hp_bar = ProgressBar.new()
	_hp_bar.custom_minimum_size = Vector2(220, 18)
	_hp_bar.max_value = max_health
	_hp_bar.value = current_health
	_hp_bar.show_percentage = false
	var hp_bg = StyleBoxFlat.new()
	hp_bg.bg_color = Color(0.15, 0.05, 0.05, 0.85)
	hp_bg.set_corner_radius_all(3)
	_hp_bar.add_theme_stylebox_override("background", hp_bg)
	var hp_fill = StyleBoxFlat.new()
	hp_fill.bg_color = Color(0.2, 0.8, 0.3)
	hp_fill.set_corner_radius_all(3)
	_hp_bar.add_theme_stylebox_override("fill", hp_fill)
	hp_container.add_child(_hp_bar)

	_hp_label = Label.new()
	_hp_label.text = "%d / %d" % [int(current_health), int(max_health)]
	_hp_label.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9))
	_hp_label.add_theme_font_size_override("font_size", 11)
	_hp_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hp_container.add_child(_hp_label)

	# MP bar — spells, skills and healing
	var mp_header = Label.new()
	mp_header.text = "MP"
	mp_header.add_theme_color_override("font_color", Color(0.4, 0.85, 1.0))
	mp_header.add_theme_font_size_override("font_size", 11)
	mp_header.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hp_container.add_child(mp_header)

	_mp_bar = ProgressBar.new()
	_mp_bar.custom_minimum_size = Vector2(180, 14)
	_mp_bar.max_value = _get_max_mp()
	_mp_bar.value = _get_mp()
	_mp_bar.show_percentage = false
	var mp_bg = StyleBoxFlat.new()
	mp_bg.bg_color = Color(0.03, 0.08, 0.12, 0.85)
	mp_bg.set_corner_radius_all(3)
	_mp_bar.add_theme_stylebox_override("background", mp_bg)
	var mp_fill = StyleBoxFlat.new()
	mp_fill.bg_color = Color(0.2, 0.7, 1.0)
	mp_fill.set_corner_radius_all(3)
	_mp_bar.add_theme_stylebox_override("fill", mp_fill)
	hp_container.add_child(_mp_bar)

	_mp_label = Label.new()
	_mp_label.text = "%d / %d" % [int(_get_mp()), int(_get_max_mp())]
	_mp_label.add_theme_color_override("font_color", Color(0.6, 0.9, 1.0))
	_mp_label.add_theme_font_size_override("font_size", 10)
	_mp_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hp_container.add_child(_mp_label)

	# Soul bar — special arts (Glitch Arts); earned by parries, perfect dodges, kills
	var soul_header = Label.new()
	soul_header.text = "SOUL"
	soul_header.add_theme_color_override("font_color", Color(0.6, 0.7, 1.0))
	soul_header.add_theme_font_size_override("font_size", 11)
	soul_header.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hp_container.add_child(soul_header)

	_soul_bar = ProgressBar.new()
	_soul_bar.custom_minimum_size = Vector2(180, 14)
	_soul_bar.max_value = MAX_SOUL
	_soul_bar.value = current_soul
	_soul_bar.show_percentage = false
	var soul_bg = StyleBoxFlat.new()
	soul_bg.bg_color = Color(0.05, 0.05, 0.15, 0.85)
	soul_bg.set_corner_radius_all(3)
	_soul_bar.add_theme_stylebox_override("background", soul_bg)
	var soul_fill = StyleBoxFlat.new()
	soul_fill.bg_color = Color(0.4, 0.5, 1.0)
	soul_fill.set_corner_radius_all(3)
	_soul_bar.add_theme_stylebox_override("fill", soul_fill)
	hp_container.add_child(_soul_bar)

	_soul_label = Label.new()
	_soul_label.text = "%d / %d" % [int(current_soul), int(MAX_SOUL)]
	_soul_label.add_theme_color_override("font_color", Color(0.7, 0.7, 1.0))
	_soul_label.add_theme_font_size_override("font_size", 10)
	_soul_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hp_container.add_child(_soul_label)

	# XP progress bar
	var xp_header = Label.new()
	xp_header.text = "XP"
	xp_header.add_theme_color_override("font_color", Color(0.9, 0.75, 0.3))
	xp_header.add_theme_font_size_override("font_size", 10)
	xp_header.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hp_container.add_child(xp_header)

	var xp_bar = ProgressBar.new()
	xp_bar.name = "XPBar"
	xp_bar.custom_minimum_size = Vector2(180, 8)
	var max_xp = GameManager.player_stats.get("xp_to_next", 100)
	var cur_xp = GameManager.player_stats.get("current_xp", 0)
	xp_bar.max_value = max_xp
	xp_bar.value = cur_xp
	xp_bar.show_percentage = false
	var xp_bg = StyleBoxFlat.new()
	xp_bg.bg_color = Color(0.08, 0.06, 0.02, 0.85)
	xp_bg.set_corner_radius_all(2)
	xp_bar.add_theme_stylebox_override("background", xp_bg)
	var xp_fill = StyleBoxFlat.new()
	xp_fill.bg_color = Color(0.9, 0.75, 0.3)
	xp_fill.set_corner_radius_all(2)
	xp_bar.add_theme_stylebox_override("fill", xp_fill)
	hp_container.add_child(xp_bar)

	# Combo indicator
	_combo_indicator = Label.new()
	_combo_indicator.text = ""
	_combo_indicator.add_theme_color_override("font_color", Color(1.0, 0.85, 0.3))
	_combo_indicator.add_theme_font_size_override("font_size", 14)
	_combo_indicator.position = Vector2(20, 130)
	_combo_indicator.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_hud_layer.add_child(_combo_indicator)

	# Charge indicator
	_charge_indicator = ProgressBar.new()
	_charge_indicator.custom_minimum_size = Vector2(120, 8)
	_charge_indicator.max_value = CHARGED_ATTACK_TIME
	_charge_indicator.value = 0
	_charge_indicator.show_percentage = false
	_charge_indicator.position = Vector2(20, 152)
	_charge_indicator.visible = false
	var charge_bg = StyleBoxFlat.new()
	charge_bg.bg_color = Color(0.1, 0.1, 0.1, 0.7)
	charge_bg.set_corner_radius_all(2)
	_charge_indicator.add_theme_stylebox_override("background", charge_bg)
	var charge_fill = StyleBoxFlat.new()
	charge_fill.bg_color = Color(1.0, 0.8, 0.2)
	charge_fill.set_corner_radius_all(2)
	_charge_indicator.add_theme_stylebox_override("fill", charge_fill)
	_hud_layer.add_child(_charge_indicator)

	# Top-right: stats (responsive positioning)
	var stats_container = VBoxContainer.new()
	var vp_w = get_viewport().get_visible_rect().size.x if get_viewport() else 1280.0
	stats_container.position = Vector2(vp_w - 220, 16)
	stats_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_hud_layer.add_child(stats_container)

	_level_label = Label.new()
	_level_label.name = "LevelLabel"
	_level_label.text = "Lv.%d  |  %dG" % [GameManager.player_stats.get("level", 1), GameManager.player_stats.get("gold", 0)]
	_level_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.3))
	_level_label.add_theme_font_size_override("font_size", 13)
	_level_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stats_container.add_child(_level_label)

	_corruption_label = Label.new()
	_corruption_label.text = "Corruption: %.0f%%" % GameManager.glitch_meter
	_corruption_label.add_theme_color_override("font_color", Color(1.0, 0.3, 0.3) if GameManager.glitch_meter > 50.0 else Color(0.8, 0.6, 1.0))
	_corruption_label.add_theme_font_size_override("font_size", 12)
	_corruption_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stats_container.add_child(_corruption_label)

	# Action buttons
	var btn_bar = HBoxContainer.new()
	btn_bar.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	btn_bar.offset_top = -70
	btn_bar.offset_bottom = -12
	btn_bar.offset_left = 40
	btn_bar.offset_right = -40
	btn_bar.alignment = BoxContainer.ALIGNMENT_CENTER
	btn_bar.add_theme_constant_override("separation", 12)
	_hud_layer.add_child(btn_bar)

	_add_action_button(btn_bar, "JUMP [Space]", "jump", Color(0.3, 0.8, 1.0))
	_add_action_button(btn_bar, "DASH [Shift]", "sprint", Color(0.3, 1.0, 0.5))
	_add_action_button(btn_bar, "ATK [J]", "attack", Color(1.0, 0.4, 0.3))
	_add_action_button(btn_bar, "DEF [K]", "defend", Color(0.6, 0.6, 1.0))
	_add_action_button(btn_bar, "SPELL [Q]", "spell", Color(0.8, 0.5, 1.0))
	_add_action_button(btn_bar, "HEAL [C]", "heal", Color(0.4, 1.0, 0.6))


func _add_action_button(parent: HBoxContainer, label_text: String, action: String, color: Color) -> void:
	var btn = Button.new()
	btn.text = label_text
	btn.custom_minimum_size = Vector2(110, 44)

	var style_normal = StyleBoxFlat.new()
	style_normal.bg_color = Color(color.r * 0.2, color.g * 0.2, color.b * 0.2, 0.8)
	style_normal.border_color = color
	style_normal.set_border_width_all(2)
	style_normal.set_corner_radius_all(6)
	style_normal.content_margin_left = 6
	style_normal.content_margin_right = 6
	btn.add_theme_stylebox_override("normal", style_normal)

	var style_pressed = StyleBoxFlat.new()
	style_pressed.bg_color = Color(color.r * 0.5, color.g * 0.5, color.b * 0.5, 0.9)
	style_pressed.border_color = Color(1, 1, 1, 0.8)
	style_pressed.set_border_width_all(2)
	style_pressed.set_corner_radius_all(6)
	style_pressed.content_margin_left = 6
	style_pressed.content_margin_right = 6
	btn.add_theme_stylebox_override("pressed", style_pressed)

	var style_hover = StyleBoxFlat.new()
	style_hover.bg_color = Color(color.r * 0.3, color.g * 0.3, color.b * 0.3, 0.85)
	style_hover.border_color = Color(color.r, color.g, color.b, 0.9)
	style_hover.set_border_width_all(2)
	style_hover.set_corner_radius_all(6)
	style_hover.content_margin_left = 6
	style_hover.content_margin_right = 6
	btn.add_theme_stylebox_override("hover", style_hover)

	btn.add_theme_color_override("font_color", color)
	btn.add_theme_color_override("font_pressed_color", Color.WHITE)
	btn.add_theme_font_size_override("font_size", 12)

	btn.button_down.connect(func() -> void: Input.action_press(action))
	btn.button_up.connect(func() -> void: Input.action_release(action))
	parent.add_child(btn)


func _update_hud() -> void:
	if _hp_bar:
		_hp_bar.max_value = max_health
		# Smooth HP bar lerp for visual polish
		_hp_display_value = lerpf(_hp_display_value, current_health, 0.15)
		if absf(_hp_display_value - current_health) < 0.5:
			_hp_display_value = current_health
		_hp_bar.value = _hp_display_value
		var hp_pct = current_health / max_health if max_health > 0.0 else 1.0
		var fill_style = _hp_bar.get_theme_stylebox("fill") as StyleBoxFlat
		if fill_style:
			if hp_pct > 0.5:
				fill_style.bg_color = Color(0.2, 0.8, 0.3)
			elif hp_pct > 0.25:
				fill_style.bg_color = Color(1.0, 0.8, 0.2)
			else:
				fill_style.bg_color = Color(1.0, 0.2, 0.2)
	if _hp_label:
		_hp_label.text = "%d / %d" % [int(current_health), int(max_health)]
	if _mp_bar:
		_mp_bar.max_value = _get_max_mp()
		_mp_bar.value = _get_mp()
	if _mp_label:
		_mp_label.text = "%d / %d" % [int(_get_mp()), int(_get_max_mp())]
	if _soul_bar:
		_soul_bar.value = current_soul
	if _soul_label:
		_soul_label.text = "%d / %d" % [int(current_soul), int(MAX_SOUL)]
	if _corruption_label:
		_corruption_label.text = "Corruption: %.0f%%" % GameManager.glitch_meter
		_corruption_label.add_theme_color_override("font_color", Color(1.0, 0.3, 0.3) if GameManager.glitch_meter > 50.0 else Color(0.8, 0.6, 1.0))
	if _level_label:
		_level_label.text = "Lv.%d  |  %dG" % [GameManager.player_stats.get("level", 1), GameManager.player_stats.get("gold", 0)]


func _update_combo_indicator() -> void:
	if not _combo_indicator:
		return
	# BUG 7 FIX: Only show attack chain step here. Hit count & style rank live in GameJuice HUD.
	var combo_text = ""
	var combo_color = Color.WHITE
	match combo_step:
		0:
			_combo_indicator.text = ""
			return
		1:
			combo_text = "COMBO I"
			combo_color = Color(0.7, 0.9, 1.0)
		2:
			combo_text = "COMBO II"
			combo_color = Color(1.0, 0.85, 0.3)
		3:
			combo_text = "COMBO III !"
			combo_color = Color(1.0, 0.4, 0.3)

	var old_text = _combo_indicator.text
	_combo_indicator.text = combo_text
	_combo_indicator.add_theme_color_override("font_color", combo_color)

	if _combo_indicator.text != old_text and _combo_indicator.text != "":
		_combo_indicator.pivot_offset = _combo_indicator.size / 2.0
		if _combo_pop_tween and _combo_pop_tween.is_valid():
			_combo_pop_tween.kill()
		_combo_pop_tween = _combo_indicator.create_tween()
		_combo_pop_tween.tween_property(_combo_indicator, "scale", Vector2(1.5, 1.5), 0.06).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		_combo_pop_tween.tween_property(_combo_indicator, "scale", Vector2(1.0, 1.0), 0.18).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)


func _update_charge_indicator() -> void:
	if not _charge_indicator:
		return
	if is_charging:
		_charge_indicator.visible = true
		_charge_indicator.value = charge_timer
		if charged_attack_ready:
			var fill = _charge_indicator.get_theme_stylebox("fill") as StyleBoxFlat
			if fill:
				fill.bg_color = Color(1.0, 0.4, 0.1) if int(charge_timer * 4) % 2 == 0 else Color(1.0, 0.85, 0.2)
	else:
		_charge_indicator.visible = false
		_charge_indicator.value = 0


# ══════════════════════════════════════════════════════════════════════════
# DANGER OVERLAY
# ══════════════════════════════════════════════════════════════════════════

func _setup_danger_overlay() -> void:
	var layer = CanvasLayer.new()
	layer.layer = 85
	layer.name = "DangerOverlayLayer"
	add_child(layer)
	_danger_overlay = ColorRect.new()
	_danger_overlay.name = "DangerOverlay"
	_danger_overlay.color = Color(0.8, 0.0, 0.0, 0.0)
	_danger_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	_danger_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(_danger_overlay)


func _update_danger_overlay() -> void:
	if not _danger_overlay:
		_setup_danger_overlay()
	var hp_pct = current_health / max_health if max_health > 0.0 else 1.0
	if hp_pct <= 0.25 and not is_dead:
		var max_alpha = remap(hp_pct, 0.0, 0.25, 0.25, 0.08)
		var pulse = absf(sin(Time.get_ticks_msec() / 800.0)) * max_alpha
		_danger_overlay.color = Color(0.8, 0.0, 0.0, pulse)
	else:
		_danger_overlay.color.a = 0.0


# ══════════════════════════════════════════════════════════════════════════
# COMBO MULTIPLIER HUD
# ══════════════════════════════════════════════════════════════════════════

func _setup_combo_mult_hud() -> void:
	_combo_mult_hud = Label.new()
	_combo_mult_hud.name = "ComboMultHUD"
	_combo_mult_hud.text = ""
	_combo_mult_hud.add_theme_font_size_override("font_size", 16)
	_combo_mult_hud.add_theme_color_override("font_color", Color(1.0, 0.6, 0.2))
	_combo_mult_hud.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.7))
	_combo_mult_hud.add_theme_constant_override("shadow_offset_x", 1)
	_combo_mult_hud.add_theme_constant_override("shadow_offset_y", 1)
	_combo_mult_hud.position = Vector2(20, 170)
	_combo_mult_hud.modulate.a = 0.0
	_combo_mult_hud.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if _hud_layer:
		_hud_layer.add_child(_combo_mult_hud)


func _update_combo_mult_hud() -> void:
	if not _combo_mult_hud:
		_setup_combo_mult_hud()
	var mult = _get_combo_multiplier()
	if mult > 1.0:
		_combo_mult_hud.text = "DMG x%.2f" % mult
		_combo_mult_hud.modulate.a = 1.0
		if mult >= 2.0:
			_combo_mult_hud.add_theme_color_override("font_color", Color(1.0, 0.2, 0.2))
		elif mult >= 1.5:
			_combo_mult_hud.add_theme_color_override("font_color", Color(1.0, 0.5, 0.1))
		else:
			_combo_mult_hud.add_theme_color_override("font_color", Color(1.0, 0.7, 0.2))
	else:
		_combo_mult_hud.modulate.a = 0.0
