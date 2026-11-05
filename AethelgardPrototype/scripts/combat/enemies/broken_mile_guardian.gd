extends EnemyBase
class_name BrokenMileGuardian

## The Mosswood Guardian: the corrupted guardian blocking the Broken Mile (Y1-P0-T13b, story fight `ch1_guardian`).
## Two telegraphed attacks, picked by distance, never by a roll: a *stomp* (AttackType.SLAM) when the player is
## within STOMP_RANGE, a *charge* (AttackType.CHARGE) along the ground when between STOMP_RANGE and CHARGE_RANGE.
## Each runs through EnemyBase's TELEGRAPH state first, then one attack and RECOVER (no combo). No contact damage:
## it hurts only through the two attacks. Both can be parried (the player's parry staggers enemies within 120 px).
## Poise (D9): a hit takes HP but never interrupts a telegraph or an attack; only a parry does.
## The arena respawns it on a retry, so it has no reset of its own.

# ── Tuning (every gameplay value of the guardian; D2, D5, D6, D8) ──
## Base HP before EnemyBase's level and DDA scaling (60 under the pins: four 15-damage hits).
const GUARDIAN_MAX_HEALTH: float = 60.0
## The stomp is chosen when the player is this close (also attack_range).
const STOMP_RANGE: float = 70.0
## The charge is chosen, and telegraphed from range, when the player is between STOMP_RANGE and this.
const CHARGE_RANGE: float = 360.0
## Detection circle; at least CHARGE_RANGE so the guardian sees every player it can charge.
const DETECTION_RANGE: float = 420.0
## Telegraph times before the difficulty multiplier (EnemyBase's division and 0.25 s floor still apply).
const STOMP_TELEGRAPH: float = 0.45
const CHARGE_TELEGRAPH: float = 0.6
## Raw damage; _deal_damage_in_attack_hitbox applies get_enemy_damage_multiplier() once.
const STOMP_DAMAGE: float = 12.0
const CHARGE_DAMAGE: float = 14.0
## The stomp's hit box, centred on the guardian: wider than 2 x STOMP_RANGE, so a stomp started at the range edge lands.
const STOMP_HITBOX_SIZE: Vector2 = Vector2(168.0, 96.0)
const STOMP_HITBOX_OFFSET: Vector2 = Vector2(0.0, -24.0)
## The charge's hit box on the side it rushes to: it reaches |offset.x| + size.x / 2 = 110 px from the centre, so a
## parried charge always staggers the guardian (D8: the parry reaches enemies within 120 px).
const CHARGE_HITBOX_SIZE: Vector2 = Vector2(120.0, 74.0)
const CHARGE_HITBOX_OFFSET: Vector2 = Vector2(50.0, -30.0)
## The rush: CHARGE_SPEED x CHARGE_TRAVEL_TIME = 260 px along the ground.
const CHARGE_SPEED: float = 520.0
const CHARGE_TRAVEL_TIME: float = 0.5
## Lifetime of each per-frame hit box swept along the charge (about one physics frame).
const CHARGE_SWEEP_ACTIVE: float = 0.02
## Walking speed between attacks (EnemyBase multiplies it by chase_speed_mult when chasing).
const MOVE_SPEED: float = 60.0
## Closer than this, the guardian stops walking in (it never pushes through the player).
const STANDOFF_DISTANCE: float = 40.0
## RECOVER after each attack, then the cooldown before the next telegraph (divided by the difficulty multiplier).
const RECOVER_TIME: float = 0.8
const ATTACK_COOLDOWN: float = 1.0
## Contact damage is off (D6).
const GUARDIAN_CONTACT_DAMAGE: float = 0.0
## No random dodge on a hit (D9): EnemyBase's 15 % backward hop is off.
const GUARDIAN_DODGE_CHANCE: float = 0.0

## The side the current charge rushes to (-1 left, 1 right), fixed when it launches.
var _charge_dir: float = 1.0
## Seconds since the current charge launched.
var _charge_elapsed: float = 0.0
## True from the charge's launch until it lands its hit (or misses, or is parried).
var _charge_hit_pending: bool = false


func _ready() -> void:
	enemy_name = "Mosswood Guardian"
	max_health = GUARDIAN_MAX_HEALTH
	current_health = max_health
	contact_damage = GUARDIAN_CONTACT_DAMAGE
	movement_speed = MOVE_SPEED
	# EnemyBase builds its detection and attack circles from these in _ready.
	detection_range = DETECTION_RANGE
	attack_range = STOMP_RANGE
	attacks_available = [AttackType.SLAM, AttackType.CHARGE]
	max_combo = 1
	recover_duration = RECOVER_TIME
	attack_cooldown_base = ATTACK_COOLDOWN
	dodge_chance = GUARDIAN_DODGE_CHANCE
	xp_reward = 0
	gold_reward = 0
	super._ready()


## The attack by distance: the stomp up close, the charge from range. Never a roll.
func _choose_attack() -> int:
	return AttackType.SLAM if distance_to_player() <= STOMP_RANGE else AttackType.CHARGE


## Starts a telegraph anywhere within CHARGE_RANGE once the cooldown is over (EnemyBase only starts one inside
## attack_range); otherwise walks in as EnemyBase does, stopping at STANDOFF_DISTANCE.
func _state_chase(delta: float) -> void:
	if find_player() and attack_cooldown <= 0.0 and distance_to_player() <= CHARGE_RANGE:
		_begin_telegraph()
		return
	super._state_chase(delta)
	if current_state == State.CHASE and distance_to_player() < STANDOFF_DISTANCE:
		velocity.x = 0.0


## EnemyBase's telegraph (state, attack choice, GameJuice cue, tint, "!" marker), then the guardian's own time
## (D10): the attack's telegraph divided by the difficulty multiplier, at least 0.25 s, as EnemyBase scales its
## own; the tint is restarted at that length.
func _begin_telegraph() -> void:
	super._begin_telegraph()
	telegraph_duration = CHARGE_TELEGRAPH if current_attack == AttackType.CHARGE else STOMP_TELEGRAPH
	if has_node("/root/GameManager"):
		telegraph_duration = maxf(telegraph_duration / GameManager.get_difficulty_multiplier(), 0.25)
	var sprite: CanvasItem = get_node_or_null("Sprite")
	if sprite == null:
		return
	# Read while EnemyBase's tween still runs: the colour recorded at rest, not a tint.
	var orig_color: Color = _sprite_rest_modulate(sprite)
	if _telegraph_tween and _telegraph_tween.is_valid():
		_telegraph_tween.kill()
	_telegraph_tween = create_tween()
	_telegraph_tween.tween_property(sprite, "modulate", Color(1.0, 0.4, 0.2, 1.0), telegraph_duration * 0.5)
	_telegraph_tween.tween_property(sprite, "modulate", orig_color, telegraph_duration * 0.3)


## The stomp lands as the telegraph ends, then RECOVER; the charge launches and stays in ATTACK (_state_attack).
func _execute_attack() -> void:
	if current_attack != AttackType.SLAM and current_attack != AttackType.CHARGE:
		super._execute_attack()
		return
	current_state = State.ATTACK
	recover_timer = 0.0
	combo_count = 0
	_sfx("sword_swing", 0.15)
	if current_attack == AttackType.CHARGE:
		_charge_dir = _side(direction_to_player())
		_charge_elapsed = 0.0
		_charge_hit_pending = true
		velocity.x = _charge_dir * CHARGE_SPEED
		return
	_deal_damage_in_attack_hitbox(STOMP_HITBOX_OFFSET, STOMP_HITBOX_SIZE, STOMP_DAMAGE, "slam")
	_vfx("vfx_hit_spark", global_position + Vector2(0.0, 10.0))
	# A parry staggered it inside the call above (STUNNED): RECOVER over it, as EnemyBase does.
	_enter_recover()


## The charge: rushes CHARGE_TRAVEL_TIME along the ground; after EnemyBase's minimum travel time it sweeps its hit box
## each physics frame until it lands once. It stops dead at its travel end (no slide in RECOVER) and at once when
## parried. Any other attack runs EnemyBase's state.
func _state_attack(delta: float) -> void:
	if current_attack != AttackType.CHARGE:
		super._state_attack(delta)
		return
	_charge_elapsed += delta
	velocity.x = _charge_dir * CHARGE_SPEED
	if _charge_hit_pending and _charge_elapsed >= CHARGE_MIN_TRAVEL_TIME:
		# Each frame's box lives CHARGE_SWEEP_ACTIVE and keeps its own hit list, so an earlier frame's box can still
		# report the player after this one has hit: only the player's invulnerability after a hit (1.0 s, 0.4 s after
		# a parry) stops that second hit landing.
		var offset := Vector2(_charge_dir * CHARGE_HITBOX_OFFSET.x, CHARGE_HITBOX_OFFSET.y)
		if _deal_damage_in_attack_hitbox(offset, CHARGE_HITBOX_SIZE, CHARGE_DAMAGE, "charge", CHARGE_SWEEP_ACTIVE):
			_charge_hit_pending = false
	if _stun_active or _charge_elapsed >= CHARGE_TRAVEL_TIME:
		velocity.x = 0.0
		_enter_recover()


## A parry's stagger (PlayerCombat staggers enemies within 120 px). It can arrive outside _state_attack (an
## earlier frame's charge hit box reports the player on its own), so the attack is ended here: a staggered
## telegraph or attack goes to RECOVER over STUNNED, as EnemyBase's _execute_attack does after a parry, and the
## cooldown follows the stagger. EnemyBase.stagger only clears its tint when the state is still STUNNED, so the
## guardian clears it itself when the stagger ends.
func stagger(duration: float = 1.0) -> void:
	if current_state == State.DEAD or _stun_active:
		return
	var interrupted: bool = current_state == State.TELEGRAPH or current_state == State.ATTACK
	super.stagger(duration)   # not awaited: it runs up to its timer and goes on from there by itself
	_charge_hit_pending = false
	if interrupted:
		if _telegraph_tween and _telegraph_tween.is_valid():
			_telegraph_tween.kill()
		_enter_recover()
	get_tree().create_timer(duration, false).timeout.connect(_clear_stagger_tint)


func _clear_stagger_tint() -> void:
	var sprite: CanvasItem = get_node_or_null("Sprite")
	if current_state == State.DEAD or sprite == null:
		return
	sprite.modulate = Color(1.0, 0.7, 1.0, 1.0) if is_hacked else Color.WHITE


## Poise (D9): a hit during a telegraph or an attack takes HP (EnemyBase.take_damage) but does not stun, so the
## attack goes on. In any other state the light hit-stun runs as EnemyBase's. A stun that starts in RECOVER ends
## with the attack cooldown set, so a hit never lets the guardian skip its cooldown. One that starts in CHASE or
## IDLE leaves the cooldown alone: EnemyBase does not tick the cooldown during a hit-stun, so raising it there let
## steady hits stop the guardian ever telegraphing (/code-review R1). A parry still interrupts it (stagger()).
func _apply_hitstun(amount: float) -> void:
	if current_state == State.TELEGRAPH or current_state == State.ATTACK:
		return
	var stuns: bool = not _stun_active   # EnemyBase returns at once when a stun already runs
	var from_recover: bool = current_state == State.RECOVER
	await super._apply_hitstun(amount)
	if not stuns or not from_recover or not is_inside_tree() or current_state == State.DEAD:
		return
	attack_cooldown = maxf(attack_cooldown, _scaled_attack_cooldown())


## The cooldown EnemyBase's RECOVER sets: attack_cooldown_base divided by the difficulty multiplier.
func _scaled_attack_cooldown() -> float:
	if has_node("/root/GameManager"):
		return attack_cooldown_base / maxf(GameManager.get_difficulty_multiplier(), 0.1)
	return attack_cooldown_base


## One attack, then RECOVER (no combo).
func _enter_recover() -> void:
	_charge_hit_pending = false
	current_state = State.RECOVER
	recover_timer = 0.0
	combo_count = 0
