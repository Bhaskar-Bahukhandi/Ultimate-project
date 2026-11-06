extends EnemyBase
class_name FieldBoar

## The north-field boar: the corrupted boar of Oakhaven's fields (Y1-P0-T13c, story fight `ch1_boar`).
## One telegraphed attack, the charge (AttackType.CHARGE), never chosen by a roll: after its cooldown it telegraphs,
## wherever the player stands, then runs toward the side the player was on at launch and cannot turn. The player
## jumps it. It is armoured: outside DIZZY a hit does nothing (no HP, no hit-stun, no knockback, no flash). A charge
## that meets an arena wall leaves it dizzy for DIZZY_TIME, the only time hits hurt it (a pogo or attacks); one that
## runs CHARGE_MAX_TIME without a wall ends in RECOVER instead. A parry blocks the charge and staggers it (the armour
## holds). No contact damage. The arena respawns it on a retry, so it has no reset of its own.

# ── Tuning (every gameplay value of the boar; D2, D5, D7, D8) ──
## Base HP before EnemyBase's level and DDA scaling (45 under the pins: three 15-damage hits).
const BOAR_MAX_HEALTH: float = 45.0
## Telegraph time before the difficulty multiplier (EnemyBase's division and 0.25 s floor still apply).
const CHARGE_TELEGRAPH: float = 0.6
## Raw damage; _deal_damage_in_attack_hitbox applies get_enemy_damage_multiplier() once.
const CHARGE_DAMAGE: float = 14.0
## The rush: CHARGE_SPEED x CHARGE_MAX_TIME = 1470 px, more than the 1232 px between the arena walls' inner faces for
## a 48-px body, so every charge that starts in the arena reaches a wall.
const CHARGE_SPEED: float = 420.0
const CHARGE_MAX_TIME: float = 3.5
## How long a wall leaves it dizzy (game time).
const DIZZY_TIME: float = 2.0
## RECOVER after a charge, then the cooldown before the next telegraph (divided by the difficulty multiplier).
const RECOVER_TIME: float = 0.8
const ATTACK_COOLDOWN: float = 1.2
## Detection circle: at least the arena's width (1280), so it sees the player wherever they stand.
const DETECTION_RANGE: float = 1280.0
## The attack circle EnemyBase builds in _ready; the charge starts wherever the player stands, so it only has to exist.
const ATTACK_RANGE: float = 60.0
## It does not walk between charges.
const MOVE_SPEED: float = 0.0
## The charge's hit box on the side it rushes to: it reaches |offset.x| + size.x / 2 = 60 px from the centre, within
## the parry's 120 px, and stands no higher than the 40-px body, so a jump clears it.
const CHARGE_HITBOX_SIZE: Vector2 = Vector2(60.0, 36.0)
const CHARGE_HITBOX_OFFSET: Vector2 = Vector2(30.0, -20.0)
## Lifetime of each per-frame hit box swept along the charge (about one physics frame).
const CHARGE_SWEEP_ACTIVE: float = 0.02
## Contact damage is off; no random dodge on a hit (EnemyBase's 15 % backward hop is off).
const BOAR_CONTACT_DAMAGE: float = 0.0
const BOAR_DODGE_CHANCE: float = 0.0
## The dizzy cue (D10): a small label of stars above the 40-px body, shown only while dizzy. It changes no modulate.
const DIZZY_CUE_TEXT: String = "* * *"
const DIZZY_CUE_OFFSET: Vector2 = Vector2(-16.0, -66.0)

## The side the current charge rushes to (-1 left, 1 right), fixed when it launches.
var _charge_dir: float = 1.0
## Seconds since the current charge launched.
var _charge_elapsed: float = 0.0
## True from the charge's launch until it lands its hit (or misses, or is parried).
var _charge_hit_pending: bool = false
## True while a wall has left it dizzy: the only time a hit hurts it.
var _dizzy: bool = false
## The stars shown while dizzy (D10); built in _ready.
var _dizzy_cue: Label = null


func _ready() -> void:
	enemy_name = "Corrupted Boar"
	max_health = BOAR_MAX_HEALTH
	current_health = max_health
	contact_damage = BOAR_CONTACT_DAMAGE
	movement_speed = MOVE_SPEED
	# EnemyBase builds its detection and attack circles from these in _ready.
	detection_range = DETECTION_RANGE
	attack_range = ATTACK_RANGE
	attacks_available = [AttackType.CHARGE]
	max_combo = 1
	recover_duration = RECOVER_TIME
	attack_cooldown_base = ATTACK_COOLDOWN
	dodge_chance = BOAR_DODGE_CHANCE
	xp_reward = 0
	gold_reward = 0
	super._ready()
	_build_dizzy_cue()


## The dizzy cue: a child Label named DizzyCue, hidden until a wall leaves the boar dizzy.
func _build_dizzy_cue() -> void:
	_dizzy_cue = Label.new()
	_dizzy_cue.name = "DizzyCue"
	_dizzy_cue.text = DIZZY_CUE_TEXT
	_dizzy_cue.position = DIZZY_CUE_OFFSET
	_dizzy_cue.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_dizzy_cue.visible = false
	add_child(_dizzy_cue)


func _show_dizzy_cue(shown: bool) -> void:
	if _dizzy_cue != null and is_instance_valid(_dizzy_cue):
		_dizzy_cue.visible = shown


## Off-screen culling is off: with no notifier _is_on_screen stays true, so the AI runs every physics frame wherever
## the camera is (EnemyBase otherwise runs it every third frame off-screen).
func _setup_screen_notifier() -> void:
	pass


## The one attack, never a roll.
func _choose_attack() -> int:
	return AttackType.CHARGE


## Starts a telegraph wherever the player stands once the cooldown is over; it never walks.
func _state_chase(_delta: float) -> void:
	velocity.x = 0.0
	if find_player() and attack_cooldown <= 0.0:
		_begin_telegraph()


## EnemyBase's telegraph (state, attack choice, GameJuice cue, tint, "!" marker), then the boar's own time: the
## charge's telegraph divided by the difficulty multiplier, at least 0.25 s, as EnemyBase scales its own; the tint is
## restarted at that length.
func _begin_telegraph() -> void:
	super._begin_telegraph()
	telegraph_duration = CHARGE_TELEGRAPH
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


## The charge launches toward the side the player is on and stays in ATTACK (_state_attack).
func _execute_attack() -> void:
	current_state = State.ATTACK
	recover_timer = 0.0
	combo_count = 0
	_sfx("sword_swing", 0.15)
	_charge_dir = _side(direction_to_player())
	_charge_elapsed = 0.0
	_charge_hit_pending = true
	velocity.x = _charge_dir * CHARGE_SPEED


## The charge: runs in its launch direction without turning. After EnemyBase's minimum travel time it sweeps its hit
## box each physics frame until it lands once. A wall it ran into (is_on_wall() after the last move_and_slide() with
## the wall in its way) leaves it dizzy; CHARGE_MAX_TIME without one, or a parry, sends it to RECOVER.
func _state_attack(delta: float) -> void:
	if _charge_elapsed > 0.0 and is_on_wall() and get_wall_normal().x * _charge_dir < 0.0:
		_enter_dizzy()
		return
	_charge_elapsed += delta
	velocity.x = _charge_dir * CHARGE_SPEED
	if _charge_hit_pending and _charge_elapsed >= CHARGE_MIN_TRAVEL_TIME:
		# Each frame's box lives CHARGE_SWEEP_ACTIVE and keeps its own hit list, so an earlier frame's box can still
		# report the player after this one has hit: only the player's invulnerability after a hit stops a second one.
		var offset := Vector2(_charge_dir * CHARGE_HITBOX_OFFSET.x, CHARGE_HITBOX_OFFSET.y)
		if _deal_damage_in_attack_hitbox(offset, CHARGE_HITBOX_SIZE, CHARGE_DAMAGE, "charge", CHARGE_SWEEP_ACTIVE):
			_charge_hit_pending = false
	if _stun_active or _charge_elapsed >= CHARGE_MAX_TIME:
		velocity.x = 0.0
		_enter_recover()


## Armour (D2, D5): outside dizzy a hit does nothing (no HP, no flash, no hit-stun, no knockback). While dizzy it is
## EnemyBase's normal damage (the pogo's x 1.8 included), but the boar stays where the wall left it (D7).
func take_damage(amount: float, knockback_source: Vector2 = Vector2.ZERO) -> void:
	if current_state == State.DEAD or not _dizzy:
		return
	super.take_damage(amount, knockback_source)
	velocity = Vector2.ZERO


## Dizzy: the charge is over, it stands still and starts nothing for DIZZY_TIME of game time (a connected timer: no
## EnemyBase state ticks one), then RECOVER and the cooldown.
func _enter_dizzy() -> void:
	if current_state == State.DEAD or _dizzy:
		return
	_charge_hit_pending = false
	_dizzy = true
	_stun_active = true
	current_state = State.STUNNED
	velocity = Vector2.ZERO
	_show_dizzy_cue(true)
	get_tree().create_timer(DIZZY_TIME, false, true).timeout.connect(_end_dizzy)


func _end_dizzy() -> void:
	if current_state == State.DEAD or not _dizzy:
		return
	_dizzy = false
	_stun_active = false
	_hitstun_frozen = false
	_show_dizzy_cue(false)
	_enter_recover()


## The cue goes with the boar's death (a kill is only possible while dizzy); then EnemyBase's death.
func die() -> void:
	_show_dizzy_cue(false)
	super.die()


## The charge hits at most once (AC-1). Each per-frame charge box lives CHARGE_SWEEP_ACTIVE, a little over one
## physics frame, and an earlier frame's box can report the player through body_entered after a later one has
## hit: with the player's invulnerability cleared that landed up to three hits (t13c_boar_fight_fix2_dev1.log).
## So a charge box hits only while the charge's hit is still pending, and its hit clears it. Other boxes run as
## EnemyBase's.
func _on_enemy_attack_hitbox_body_entered(body: Node, hitbox: Area2D) -> void:
	if str(hitbox.get_meta("damage_type", "")) != "charge":
		super._on_enemy_attack_hitbox_body_entered(body, hitbox)
		return
	if current_state == State.DEAD or not _charge_hit_pending:
		return
	var target = _resolve_player_collider(body)
	if target and _damage_player_from_attack_hitbox(target, hitbox):
		_charge_hit_pending = false


## A parry's stagger (PlayerCombat staggers enemies within 120 px). It can arrive outside _state_attack, so a staggered
## telegraph or charge is ended here and goes to RECOVER over STUNNED, as the guardian's does; the armour holds (a
## stagger is not dizzy) and the cooldown follows the stagger. EnemyBase.stagger only clears its tint when the state is
## still STUNNED, so the boar clears it itself when the stagger ends. A boar already dizzy ignores it. A stagger that
## interrupts nothing (RECOVER or CHASE) ends with the cooldown up (D9): EnemyBase sends it to CHASE, which would
## otherwise telegraph at once.
func stagger(duration: float = 1.0) -> void:
	if current_state == State.DEAD or _stun_active:
		return
	var interrupted: bool = current_state == State.TELEGRAPH or current_state == State.ATTACK
	super.stagger(duration)   # not awaited: it runs up to its timer and goes on from there by itself
	_charge_hit_pending = false
	velocity.x = 0.0
	if interrupted:
		if _telegraph_tween and _telegraph_tween.is_valid():
			_telegraph_tween.kill()
		_enter_recover()
	else:
		attack_cooldown = maxf(attack_cooldown, _scaled_attack_cooldown())
	get_tree().create_timer(duration, false).timeout.connect(_clear_stagger_tint)


func _clear_stagger_tint() -> void:
	var sprite: CanvasItem = get_node_or_null("Sprite")
	if current_state == State.DEAD or sprite == null:
		return
	sprite.modulate = Color(1.0, 0.7, 1.0, 1.0) if is_hacked else Color.WHITE


## The cooldown EnemyBase's RECOVER sets: attack_cooldown_base (ATTACK_COOLDOWN) divided by the difficulty
## multiplier (D9 uses it, as the guardian's).
func _scaled_attack_cooldown() -> float:
	if has_node("/root/GameManager"):
		return attack_cooldown_base / maxf(GameManager.get_difficulty_multiplier(), 0.1)
	return attack_cooldown_base


## One charge, then RECOVER (no combo).
func _enter_recover() -> void:
	_charge_hit_pending = false
	current_state = State.RECOVER
	recover_timer = 0.0
	combo_count = 0
