extends Node
## ==========================================================================
## SFXManager — Procedural multi-layer sound effect generator (Autoload)
## ==========================================================================
## Generates all game sound effects using waveform synthesis. No audio files
## needed — everything is created in-memory with optional caching.
##
## Features:
##   - Multi-layer synthesis: combine waveforms per SFX
##   - Resonant filters (lowpass, highpass, bandpass)
##   - Pitch LFO / vibrato for organic feel
##   - Harmonic overtones for richer sounds
##   - ADSR envelope with configurable stages
##   - Soft-clip distortion for warmth
##
## Usage:
##   SFXManager.play("sword_hit")
##   SFXManager.play("footstep", 0.1)        # with pitch variation
##   SFXManager.play_positional("enemy_hurt", enemy_pos, player_pos)
## ==========================================================================

# ─── CONSTANTS ───────────────────────────────────────────────────────────

const SAMPLE_RATE = 22050
const MAX_CONCURRENT_SFX = 12

# ─── STATE ───────────────────────────────────────────────────────────────

## Volume is kept in sync with MusicManager.get_sfx_volume() when available.
var _sfx_volume = 0.8

## Cache generated AudioStreamWAVs so repeated calls skip re-synthesis.
var _cache: Dictionary = {}
const MAX_CACHE_SIZE: int = 64  # Pass 55: Cap SFX cache to prevent unbounded growth

# ─── SFX DEFINITIONS ────────────────────────────────────────────────────
## Each entry defines synthesis parameters:
##   wave     : "sine" | "square" | "saw" | "noise" | "triangle"
##   freq     : Hz float  OR  [start_hz, end_hz] for frequency sweep
##   duration : seconds
##   volume_db: base loudness
##   envelope : "decay"|"pluck"|"sustain"|"burst"|"swell"|"adsr"|"percussive"
##   filter   : (opt) "lowpass" | "highpass" | "bandpass"
##   layers   : (opt) Array of extra layer dicts mixed into the base
##   harmonics: (opt) int — harmonic overtones to add
##   distortion: (opt) float — soft-clip amount (0 = clean)
##   vibrato_hz / vibrato_depth: (opt) pitch-modulation LFO

const SFX_DEFS: Dictionary = {
	# ══════ COMBAT — Melee ══════
	"sword_swing": {
		"wave": "noise", "freq": 900.0, "duration": 0.14, "volume_db": -13.0,
		"envelope": "burst", "filter": "highpass",
		"layers": [{"wave": "sine", "freq": [2000.0, 800.0], "volume_mult": 0.2, "envelope": "decay"}]
	},
	"sword_swing_2": {
		"wave": "noise", "freq": 1100.0, "duration": 0.12, "volume_db": -14.0,
		"envelope": "burst", "filter": "highpass",
		"layers": [{"wave": "triangle", "freq": [2400.0, 1000.0], "volume_mult": 0.15, "envelope": "decay"}]
	},
	"sword_swing_3": {
		"wave": "noise", "freq": 700.0, "duration": 0.18, "volume_db": -12.0,
		"envelope": "burst", "filter": "highpass",
		"layers": [{"wave": "saw", "freq": [1800.0, 600.0], "volume_mult": 0.2, "envelope": "decay"}]
	},
	"sword_hit": {
		"wave": "noise", "freq": 400.0, "duration": 0.2, "volume_db": -10.0,
		"envelope": "decay", "filter": "lowpass",
		"layers": [
			{"wave": "square", "freq": [800.0, 200.0], "volume_mult": 0.3, "envelope": "decay"},
			{"wave": "sine",   "freq": 150.0,          "volume_mult": 0.4, "envelope": "percussive"},
		]
	},
	"sword_hit_flesh": {
		"wave": "noise", "freq": 350.0, "duration": 0.18, "volume_db": -11.0,
		"envelope": "decay", "filter": "lowpass",
		"layers": [{"wave": "sine", "freq": [300.0, 100.0], "volume_mult": 0.5, "envelope": "percussive"}]
	},
	"sword_hit_metal": {
		"wave": "sine", "freq": [1800.0, 1200.0], "duration": 0.25, "volume_db": -11.0,
		"envelope": "pluck", "harmonics": 3,
		"layers": [{"wave": "noise", "freq": 600.0, "volume_mult": 0.3, "envelope": "burst"}]
	},
	"heavy_hit": {
		"wave": "noise", "freq": 200.0, "duration": 0.35, "volume_db": -7.0,
		"envelope": "decay", "distortion": 0.3,
		"layers": [
			{"wave": "sine",   "freq": [120.0, 40.0],  "volume_mult": 0.6, "envelope": "decay"},
			{"wave": "square", "freq": [400.0, 100.0], "volume_mult": 0.2, "envelope": "burst"},
		]
	},
	"critical_hit": {
		"wave": "square", "freq": [600.0, 200.0], "duration": 0.3, "volume_db": -7.0,
		"envelope": "decay", "harmonics": 2,
		"layers": [
			{"wave": "noise", "freq": [1200.0, 300.0], "volume_mult": 0.4, "envelope": "burst"},
			{"wave": "sine",  "freq": [800.0, 400.0],  "volume_mult": 0.3, "envelope": "pluck"},
		]
	},
	"heavy_windup": {
		"wave": "sine", "freq": [100.0, 400.0], "duration": 0.45, "volume_db": -10.0,
		"envelope": "swell",
		"layers": [
			{"wave": "noise", "freq": [80.0, 300.0], "volume_mult": 0.2, "envelope": "swell"},
			{"wave": "saw",   "freq": [60.0, 250.0], "volume_mult": 0.3, "envelope": "swell"},
		]
	},
	"sword_slam": {
		"wave": "noise", "freq": [800.0, 150.0], "duration": 0.35, "volume_db": -7.0,
		"envelope": "decay", "distortion": 0.2,
		"layers": [
			{"wave": "sine",  "freq": [300.0, 80.0],  "volume_mult": 0.5, "envelope": "decay"},
			{"wave": "noise", "freq": [600.0, 100.0], "volume_mult": 0.3, "envelope": "burst"},
		]
	},

	# ══════ COMBAT — Parry / Block / Defense ══════
	"parry": {
		"wave": "square", "freq": [1200.0, 800.0], "duration": 0.12, "volume_db": -9.0,
		"envelope": "burst", "harmonics": 2,
		"layers": [{"wave": "sine", "freq": [2000.0, 1500.0], "volume_mult": 0.3, "envelope": "pluck"}]
	},
	"parry_perfect": {
		"wave": "sine", "freq": [1600.0, 1200.0], "duration": 0.25, "volume_db": -7.0,
		"envelope": "pluck", "harmonics": 3,
		"layers": [
			{"wave": "triangle", "freq": [2400.0, 1800.0], "volume_mult": 0.25, "envelope": "pluck"},
			{"wave": "noise",    "freq": 1800.0,           "volume_mult": 0.15, "envelope": "burst"},
		]
	},
	"block": {
		"wave": "noise", "freq": 300.0, "duration": 0.15, "volume_db": -11.0,
		"envelope": "burst",
		"layers": [{"wave": "sine", "freq": 200.0, "volume_mult": 0.5, "envelope": "percussive"}]
	},
	"shield_break": {
		"wave": "noise", "freq": [800.0, 200.0], "duration": 0.4, "volume_db": -8.0,
		"envelope": "decay", "filter": "lowpass",
		"layers": [{"wave": "square", "freq": [600.0, 100.0], "volume_mult": 0.3, "envelope": "decay"}]
	},

	# ══════ COMBAT — Damage / Death ══════
	"enemy_hurt": {
		"wave": "square", "freq": [500.0, 200.0], "duration": 0.18, "volume_db": -11.0,
		"envelope": "decay",
		"layers": [{"wave": "noise", "freq": 400.0, "volume_mult": 0.2, "envelope": "burst"}]
	},
	"enemy_hurt_heavy": {
		"wave": "saw", "freq": [400.0, 100.0], "duration": 0.25, "volume_db": -9.0,
		"envelope": "decay", "distortion": 0.2,
		"layers": [{"wave": "noise", "freq": 200.0, "volume_mult": 0.3, "envelope": "burst"}]
	},
	"enemy_death": {
		"wave": "noise", "freq": [400.0, 80.0], "duration": 0.55, "volume_db": -9.0,
		"envelope": "decay",
		"layers": [
			{"wave": "saw",  "freq": [300.0, 50.0], "volume_mult": 0.35, "envelope": "decay"},
			{"wave": "sine", "freq": [200.0, 40.0], "volume_mult": 0.4,  "envelope": "swell"},
		]
	},
	"enemy_death_boss": {
		"wave": "noise", "freq": [600.0, 40.0], "duration": 1.2, "volume_db": -6.0,
		"envelope": "decay", "distortion": 0.3,
		"layers": [
			{"wave": "saw",    "freq": [400.0, 30.0],  "volume_mult": 0.4,  "envelope": "decay"},
			{"wave": "sine",   "freq": [150.0, 25.0],  "volume_mult": 0.5,  "envelope": "swell"},
			{"wave": "square", "freq": [800.0, 100.0], "volume_mult": 0.15, "envelope": "pluck"},
		]
	},
	"player_hurt": {
		"wave": "saw", "freq": [300.0, 150.0], "duration": 0.25, "volume_db": -9.0,
		"envelope": "decay",
		"layers": [
			{"wave": "noise", "freq": 250.0,          "volume_mult": 0.3, "envelope": "burst"},
			{"wave": "sine",  "freq": [400.0, 200.0], "volume_mult": 0.2, "envelope": "pluck"},
		]
	},
	"player_death": {
		"wave": "saw", "freq": [200.0, 50.0], "duration": 1.0, "volume_db": -7.0,
		"envelope": "decay",
		"layers": [
			{"wave": "sine",  "freq": [150.0, 30.0],  "volume_mult": 0.5,  "envelope": "swell"},
			{"wave": "noise", "freq": [300.0, 60.0],  "volume_mult": 0.25, "envelope": "decay"},
		]
	},

	# ══════ COMBAT — Spells / Abilities ══════
	"heal": {
		"wave": "sine", "freq": [400.0, 800.0], "duration": 0.45, "volume_db": -11.0,
		"envelope": "swell", "harmonics": 2,
		"layers": [
			{"wave": "triangle", "freq": [300.0, 600.0],  "volume_mult": 0.3,  "envelope": "swell"},
			{"wave": "sine",     "freq": [600.0, 1200.0], "volume_mult": 0.15, "envelope": "swell"},
		]
	},
	"spell_cast": {
		"wave": "sine", "freq": [300.0, 900.0], "duration": 0.35, "volume_db": -11.0,
		"envelope": "pluck", "harmonics": 2,
		"layers": [
			{"wave": "triangle", "freq": [200.0, 700.0], "volume_mult": 0.3, "envelope": "swell"},
			{"wave": "noise",    "freq": 1200.0,         "volume_mult": 0.1, "envelope": "burst"},
		]
	},
	"spell_impact": {
		"wave": "noise", "freq": [600.0, 200.0], "duration": 0.3, "volume_db": -9.0,
		"envelope": "decay",
		"layers": [{"wave": "sine", "freq": [500.0, 300.0], "volume_mult": 0.4, "envelope": "pluck"}]
	},
	"pogo_bounce": {
		"wave": "sine", "freq": [200.0, 600.0], "duration": 0.15, "volume_db": -13.0,
		"envelope": "pluck",
		"layers": [{"wave": "triangle", "freq": [150.0, 500.0], "volume_mult": 0.3, "envelope": "pluck"}]
	},
	"charged_release": {
		"wave": "saw", "freq": [300.0, 800.0], "duration": 0.35, "volume_db": -8.0,
		"envelope": "burst", "harmonics": 2,
		"layers": [
			{"wave": "noise", "freq": [600.0, 200.0],  "volume_mult": 0.3, "envelope": "decay"},
			{"wave": "sine",  "freq": [400.0, 1000.0], "volume_mult": 0.3, "envelope": "pluck"},
		]
	},
	"charged_loop": {
		"wave": "sine", "freq": 200.0, "duration": 0.4, "volume_db": -18.0,
		"envelope": "sustain", "vibrato_hz": 6.0, "vibrato_depth": 0.15,
		"layers": [{"wave": "triangle", "freq": 300.0, "volume_mult": 0.2, "envelope": "sustain"}]
	},

	# ══════ COMBAT — Enemy Telegraph / Boss Phase ══════
	"enemy_telegraph": {
		"wave": "square", "freq": [600.0, 900.0], "duration": 0.2, "volume_db": -12.0,
		"envelope": "swell",
		"layers": [
			{"wave": "sine",  "freq": [400.0, 700.0], "volume_mult": 0.4, "envelope": "swell"},
			{"wave": "noise", "freq": 500.0,          "volume_mult": 0.1, "envelope": "burst"},
		]
	},
	"boss_phase": {
		"wave": "saw", "freq": [100.0, 400.0], "duration": 0.8, "volume_db": -7.0,
		"envelope": "swell", "distortion": 0.25, "harmonics": 2,
		"layers": [
			{"wave": "noise",  "freq": [200.0, 1000.0], "volume_mult": 0.3, "envelope": "swell"},
			{"wave": "sine",   "freq": [150.0, 600.0],  "volume_mult": 0.4, "envelope": "swell"},
			{"wave": "square", "freq": [80.0, 300.0],   "volume_mult": 0.2, "envelope": "decay"},
		]
	},
	"boss_roar": {
		"wave": "saw", "freq": [80.0, 200.0], "duration": 0.7, "volume_db": -6.0,
		"envelope": "decay", "distortion": 0.4,
		"layers": [
			{"wave": "noise", "freq": [150.0, 400.0], "volume_mult": 0.4, "envelope": "decay"},
			{"wave": "sine",  "freq": [60.0, 120.0],  "volume_mult": 0.5, "envelope": "swell"},
		]
	},
	"boss_intro": {
		"wave": "sine", "freq": [60.0, 300.0], "duration": 1.5, "volume_db": -8.0,
		"envelope": "swell", "harmonics": 3,
		"layers": [
			{"wave": "saw",   "freq": [40.0, 200.0],  "volume_mult": 0.3,  "envelope": "swell"},
			{"wave": "noise", "freq": [100.0, 500.0], "volume_mult": 0.15, "envelope": "swell"},
		]
	},

	# ══════ MOVEMENT ══════
	"footstep":       {"wave": "noise", "freq": 150.0, "duration": 0.08, "volume_db": -22.0, "envelope": "burst"},
	"footstep_stone": {
		"wave": "noise", "freq": 250.0, "duration": 0.06, "volume_db": -20.0,
		"envelope": "burst",
		"layers": [{"wave": "sine", "freq": 400.0, "volume_mult": 0.15, "envelope": "pluck"}]
	},
	"footstep_grass": {"wave": "noise", "freq": 120.0, "duration": 0.07, "volume_db": -23.0, "envelope": "burst", "filter": "lowpass"},
	"footstep_metal": {
		"wave": "noise", "freq": 350.0, "duration": 0.06, "volume_db": -19.0,
		"envelope": "burst",
		"layers": [{"wave": "sine", "freq": [800.0, 600.0], "volume_mult": 0.2, "envelope": "pluck"}]
	},
	"footstep_wood": {
		"wave": "noise", "freq": 180.0, "duration": 0.07, "volume_db": -21.0,
		"envelope": "burst",
		"layers": [{"wave": "sine", "freq": 300.0, "volume_mult": 0.15, "envelope": "percussive"}]
	},
	"jump": {
		"wave": "sine", "freq": [200.0, 500.0], "duration": 0.15, "volume_db": -15.0,
		"envelope": "pluck",
		"layers": [{"wave": "noise", "freq": 300.0, "volume_mult": 0.15, "envelope": "burst"}]
	},
	"double_jump": {
		"wave": "sine", "freq": [300.0, 700.0], "duration": 0.18, "volume_db": -14.0,
		"envelope": "pluck",
		"layers": [
			{"wave": "triangle", "freq": [250.0, 600.0], "volume_mult": 0.25, "envelope": "pluck"},
			{"wave": "noise",    "freq": 400.0,          "volume_mult": 0.1,  "envelope": "burst"},
		]
	},
	"land": {
		"wave": "noise", "freq": 120.0, "duration": 0.12, "volume_db": -15.0,
		"envelope": "burst",
		"layers": [{"wave": "sine", "freq": 80.0, "volume_mult": 0.4, "envelope": "percussive"}]
	},
	"land_heavy": {
		"wave": "noise", "freq": 80.0, "duration": 0.2, "volume_db": -12.0,
		"envelope": "burst",
		"layers": [
			{"wave": "sine",  "freq": 50.0,  "volume_mult": 0.5, "envelope": "percussive"},
			{"wave": "noise", "freq": 200.0, "volume_mult": 0.2, "envelope": "decay"},
		]
	},
	"dash": {
		"wave": "noise", "freq": [600.0, 200.0], "duration": 0.2, "volume_db": -13.0,
		"envelope": "burst", "filter": "highpass",
		"layers": [{"wave": "sine", "freq": [400.0, 150.0], "volume_mult": 0.2, "envelope": "decay"}]
	},
	"wall_slide": {"wave": "noise", "freq": 100.0, "duration": 0.1, "volume_db": -24.0, "envelope": "sustain"},
	"wall_jump": {
		"wave": "sine", "freq": [250.0, 550.0], "duration": 0.15, "volume_db": -14.0,
		"envelope": "pluck",
		"layers": [{"wave": "noise", "freq": 300.0, "volume_mult": 0.2, "envelope": "burst"}]
	},

	# ══════ UI — Menus / Buttons / Feedback ══════
	"ui_click":   {"wave": "sine", "freq": 800.0, "duration": 0.06, "volume_db": -15.0, "envelope": "pluck"},
	"ui_hover":   {"wave": "sine", "freq": 600.0, "duration": 0.04, "volume_db": -21.0, "envelope": "pluck"},
	"ui_confirm": {
		"wave": "sine", "freq": [500.0, 800.0], "duration": 0.18, "volume_db": -13.0,
		"envelope": "pluck",
		"layers": [{"wave": "triangle", "freq": [400.0, 700.0], "volume_mult": 0.3, "envelope": "pluck"}]
	},
	"ui_cancel": {"wave": "sine", "freq": [600.0, 300.0], "duration": 0.15, "volume_db": -13.0, "envelope": "decay"},
	"ui_error": {
		"wave": "square", "freq": [400.0, 200.0], "duration": 0.22, "volume_db": -13.0,
		"envelope": "decay",
		"layers": [{"wave": "saw", "freq": [350.0, 150.0], "volume_mult": 0.2, "envelope": "decay"}]
	},
	"ui_open": {
		"wave": "sine", "freq": [300.0, 700.0], "duration": 0.2, "volume_db": -15.0,
		"envelope": "pluck",
		"layers": [{"wave": "triangle", "freq": [250.0, 600.0], "volume_mult": 0.2, "envelope": "pluck"}]
	},
	"ui_close":  {"wave": "sine", "freq": [700.0, 300.0], "duration": 0.15, "volume_db": -15.0, "envelope": "decay"},
	"ui_tab":    {"wave": "sine", "freq": 900.0,          "duration": 0.05, "volume_db": -17.0, "envelope": "pluck"},
	"ui_scroll": {"wave": "sine", "freq": 700.0,          "duration": 0.03, "volume_db": -20.0, "envelope": "pluck"},
	"ui_select": {
		"wave": "sine", "freq": [600.0, 900.0], "duration": 0.1, "volume_db": -14.0,
		"envelope": "pluck",
		"layers": [{"wave": "triangle", "freq": [500.0, 800.0], "volume_mult": 0.2, "envelope": "pluck"}]
	},

	# ══════ DIALOGUE ══════
	"text_tick":       {"wave": "square", "freq": 440.0, "duration": 0.03, "volume_db": -25.0, "envelope": "burst"},
	"text_tick_low":   {"wave": "square", "freq": 330.0, "duration": 0.03, "volume_db": -25.0, "envelope": "burst"},
	"text_tick_high":  {"wave": "square", "freq": 550.0, "duration": 0.03, "volume_db": -25.0, "envelope": "burst"},
	"text_tick_glitch": {
		"wave": "noise", "freq": 600.0, "duration": 0.03, "volume_db": -24.0,
		"envelope": "burst",
		"layers": [{"wave": "square", "freq": 500.0, "volume_mult": 0.3, "envelope": "burst"}]
	},
	"dialogue_advance": {"wave": "sine", "freq": [500.0, 700.0], "duration": 0.1, "volume_db": -17.0, "envelope": "pluck"},
	"choice_select": {
		"wave": "sine", "freq": [400.0, 600.0], "duration": 0.12, "volume_db": -15.0,
		"envelope": "pluck",
		"layers": [{"wave": "triangle", "freq": [350.0, 550.0], "volume_mult": 0.2, "envelope": "pluck"}]
	},
	"dialogue_emotion_surprise": {"wave": "sine", "freq": [400.0, 1000.0], "duration": 0.15, "volume_db": -14.0, "envelope": "pluck"},
	"dialogue_emotion_anger":    {"wave": "saw",  "freq": [300.0, 500.0],  "duration": 0.12, "volume_db": -14.0, "envelope": "burst"},

	# ══════ ITEMS / INVENTORY / SHOP ══════
	"item_pickup": {
		"wave": "sine", "freq": [500.0, 900.0], "duration": 0.2, "volume_db": -13.0,
		"envelope": "pluck",
		"layers": [{"wave": "triangle", "freq": [400.0, 750.0], "volume_mult": 0.25, "envelope": "pluck"}]
	},
	"item_pickup_rare": {
		"wave": "sine", "freq": [600.0, 1200.0], "duration": 0.35, "volume_db": -10.0,
		"envelope": "pluck", "harmonics": 2,
		"layers": [
			{"wave": "triangle", "freq": [500.0, 1000.0], "volume_mult": 0.3,  "envelope": "swell"},
			{"wave": "sine",     "freq": [800.0, 1400.0], "volume_mult": 0.15, "envelope": "pluck"},
		]
	},
	"item_equip": {
		"wave": "sine", "freq": [600.0, 400.0], "duration": 0.15, "volume_db": -13.0,
		"envelope": "pluck",
		"layers": [{"wave": "noise", "freq": 300.0, "volume_mult": 0.1, "envelope": "burst"}]
	},
	"item_unequip":    {"wave": "sine", "freq": [500.0, 300.0], "duration": 0.12, "volume_db": -15.0, "envelope": "decay"},
	"gold_pickup": {
		"wave": "sine", "freq": [800.0, 1200.0], "duration": 0.15, "volume_db": -13.0,
		"envelope": "pluck", "harmonics": 2,
		"layers": [{"wave": "triangle", "freq": [700.0, 1100.0], "volume_mult": 0.2, "envelope": "pluck"}]
	},
	"gold_pickup_large": {
		"wave": "sine", "freq": [700.0, 1400.0], "duration": 0.25, "volume_db": -11.0,
		"envelope": "pluck", "harmonics": 3,
		"layers": [
			{"wave": "triangle", "freq": [600.0, 1200.0], "volume_mult": 0.25, "envelope": "swell"},
			{"wave": "sine",     "freq": [900.0, 1500.0], "volume_mult": 0.15, "envelope": "pluck"},
		]
	},
	"shop_buy": {
		"wave": "sine", "freq": [600.0, 1000.0], "duration": 0.25, "volume_db": -11.0,
		"envelope": "pluck",
		"layers": [
			{"wave": "triangle", "freq": [500.0, 900.0],  "volume_mult": 0.2,  "envelope": "pluck"},
			{"wave": "sine",     "freq": [800.0, 1200.0], "volume_mult": 0.15, "envelope": "swell"},
		]
	},
	"shop_sell":            {"wave": "sine", "freq": [1000.0, 600.0], "duration": 0.2, "volume_db": -13.0, "envelope": "decay"},
	"shop_not_enough_gold": {
		"wave": "square", "freq": [300.0, 200.0], "duration": 0.25, "volume_db": -13.0,
		"envelope": "decay",
		"layers": [{"wave": "sine", "freq": [250.0, 150.0], "volume_mult": 0.3, "envelope": "decay"}]
	},
	"potion_use": {
		"wave": "sine", "freq": [300.0, 600.0], "duration": 0.3, "volume_db": -13.0,
		"envelope": "swell",
		"layers": [{"wave": "noise", "freq": 500.0, "volume_mult": 0.1, "envelope": "burst"}]
	},
	"charm_equip": {
		"wave": "sine", "freq": [400.0, 800.0], "duration": 0.3, "volume_db": -12.0,
		"envelope": "pluck", "harmonics": 2,
		"layers": [{"wave": "triangle", "freq": [350.0, 700.0], "volume_mult": 0.3, "envelope": "swell"}]
	},
	"charm_unequip": {"wave": "sine", "freq": [700.0, 350.0], "duration": 0.2, "volume_db": -14.0, "envelope": "decay"},

	# ══════ LEVEL UP / REWARDS / ACHIEVEMENTS ══════
	"level_up": {
		"wave": "sine", "freq": [400.0, 1200.0], "duration": 0.7, "volume_db": -9.0,
		"envelope": "swell", "harmonics": 3,
		"layers": [
			{"wave": "triangle", "freq": [300.0, 1000.0], "volume_mult": 0.3,  "envelope": "swell"},
			{"wave": "sine",     "freq": [600.0, 1400.0], "volume_mult": 0.2,  "envelope": "swell"},
			{"wave": "noise",    "freq": 800.0,           "volume_mult": 0.08, "envelope": "swell"},
		]
	},
	"xp_gain":    {"wave": "sine", "freq": [600.0, 800.0], "duration": 0.12, "volume_db": -17.0, "envelope": "pluck"},
	"source_key": {
		"wave": "sine", "freq": [300.0, 1500.0], "duration": 0.9, "volume_db": -7.0,
		"envelope": "swell", "harmonics": 3,
		"layers": [
			{"wave": "triangle", "freq": [250.0, 1200.0], "volume_mult": 0.3,  "envelope": "swell"},
			{"wave": "sine",     "freq": [400.0, 1800.0], "volume_mult": 0.2,  "envelope": "swell"},
			{"wave": "noise",    "freq": 600.0,           "volume_mult": 0.05, "envelope": "swell"},
		]
	},
	"achievement_unlock": {
		"wave": "sine", "freq": [500.0, 1000.0], "duration": 0.5, "volume_db": -10.0,
		"envelope": "swell", "harmonics": 2,
		"layers": [
			{"wave": "triangle", "freq": [400.0, 900.0],  "volume_mult": 0.3, "envelope": "swell"},
			{"wave": "sine",     "freq": [700.0, 1200.0], "volume_mult": 0.2, "envelope": "pluck"},
		]
	},
	"combo_milestone": {
		"wave": "sine", "freq": [600.0, 1100.0], "duration": 0.2, "volume_db": -12.0,
		"envelope": "pluck", "harmonics": 2,
		"layers": [{"wave": "triangle", "freq": [500.0, 1000.0], "volume_mult": 0.2, "envelope": "pluck"}]
	},
	"powerup": {
		"wave": "sine", "freq": [400.0, 1200.0], "duration": 0.4, "volume_db": -10.0,
		"envelope": "swell", "harmonics": 2,
		"layers": [
			{"wave": "triangle", "freq": [350.0, 1100.0], "volume_mult": 0.3, "envelope": "swell"},
			{"wave": "sine",     "freq": [600.0, 1600.0], "volume_mult": 0.2, "envelope": "pluck"},
		]
	},

	# ══════ GLITCH / CORRUPTION / HACKING ══════
	"glitch_trigger": {
		"wave": "noise", "freq": [600.0, 1800.0], "duration": 0.25, "volume_db": -9.0,
		"envelope": "burst",
		"layers": [
			{"wave": "square", "freq": [400.0, 1200.0], "volume_mult": 0.3, "envelope": "burst"},
			{"wave": "saw",    "freq": [300.0, 900.0],  "volume_mult": 0.2, "envelope": "decay"},
		]
	},
	"glitch_surge": {
		"wave": "noise", "freq": [200.0, 2000.0], "duration": 0.3, "volume_db": -9.0,
		"envelope": "burst",
		"layers": [{"wave": "square", "freq": [150.0, 1500.0], "volume_mult": 0.3, "envelope": "burst"}]
	},
	"glitch_tick":    {"wave": "noise", "freq": 1000.0, "duration": 0.05, "volume_db": -20.0, "envelope": "burst"},
	"glitch_crackle": {
		"wave": "noise", "freq": [800.0, 400.0], "duration": 0.08, "volume_db": -18.0,
		"envelope": "burst",
		"layers": [{"wave": "square", "freq": [600.0, 300.0], "volume_mult": 0.2, "envelope": "burst"}]
	},
	"corruption_rise": {
		"wave": "saw", "freq": [100.0, 800.0], "duration": 0.5, "volume_db": -11.0,
		"envelope": "swell", "distortion": 0.2,
		"layers": [{"wave": "noise", "freq": [200.0, 1000.0], "volume_mult": 0.2, "envelope": "swell"}]
	},
	"corruption_pulse": {
		"wave": "sine", "freq": [150.0, 300.0], "duration": 0.3, "volume_db": -14.0,
		"envelope": "swell", "vibrato_hz": 8.0, "vibrato_depth": 0.2,
		"layers": [{"wave": "noise", "freq": 200.0, "volume_mult": 0.15, "envelope": "burst"}]
	},
	"root_access_open": {
		"wave": "square", "freq": [200.0, 1000.0], "duration": 0.4, "volume_db": -11.0,
		"envelope": "swell",
		"layers": [
			{"wave": "sine",  "freq": [150.0, 800.0], "volume_mult": 0.3, "envelope": "swell"},
			{"wave": "noise", "freq": 600.0,          "volume_mult": 0.1, "envelope": "swell"},
		]
	},
	"root_access_close": {"wave": "square", "freq": [1000.0, 200.0], "duration": 0.3, "volume_db": -13.0, "envelope": "decay"},
	"hack_apply": {
		"wave": "square", "freq": [400.0, 1200.0], "duration": 0.25, "volume_db": -9.0,
		"envelope": "pluck",
		"layers": [
			{"wave": "noise", "freq": 800.0,          "volume_mult": 0.2, "envelope": "burst"},
			{"wave": "sine",  "freq": [300.0, 900.0], "volume_mult": 0.2, "envelope": "pluck"},
		]
	},
	"hack_activate": {
		"wave": "square", "freq": [300.0, 1400.0], "duration": 0.35, "volume_db": -8.0,
		"envelope": "swell", "harmonics": 2,
		"layers": [
			{"wave": "noise", "freq": [400.0, 1200.0], "volume_mult": 0.25, "envelope": "swell"},
			{"wave": "sine",  "freq": [250.0, 1100.0], "volume_mult": 0.3,  "envelope": "pluck"},
		]
	},
	"perfect_delete": {
		"wave": "noise", "freq": [1500.0, 100.0], "duration": 0.7, "volume_db": -5.0,
		"envelope": "decay", "distortion": 0.3,
		"layers": [
			{"wave": "saw",  "freq": [1200.0, 50.0], "volume_mult": 0.3, "envelope": "decay"},
			{"wave": "sine", "freq": [800.0, 30.0],  "volume_mult": 0.4, "envelope": "swell"},
		]
	},
	"data_vision_on": {
		"wave": "sine", "freq": [200.0, 600.0], "duration": 0.3, "volume_db": -13.0,
		"envelope": "swell",
		"layers": [{"wave": "triangle", "freq": [150.0, 500.0], "volume_mult": 0.3, "envelope": "swell"}]
	},
	"data_vision_off": {"wave": "sine", "freq": [600.0, 200.0], "duration": 0.2, "volume_db": -15.0, "envelope": "decay"},
	"reality_shatter": {
		"wave": "noise", "freq": [1000.0, 200.0], "duration": 1.0, "volume_db": -5.0,
		"envelope": "decay", "distortion": 0.4,
		"layers": [
			{"wave": "saw",    "freq": [600.0, 80.0],  "volume_mult": 0.4,  "envelope": "decay"},
			{"wave": "sine",   "freq": [400.0, 50.0],  "volume_mult": 0.5,  "envelope": "swell"},
			{"wave": "square", "freq": [800.0, 100.0], "volume_mult": 0.15, "envelope": "pluck"},
		]
	},

	# ══════ ENVIRONMENT ══════
	"door_open": {
		"wave": "noise", "freq": [200.0, 100.0], "duration": 0.3, "volume_db": -13.0,
		"envelope": "decay",
		"layers": [{"wave": "sine", "freq": [150.0, 80.0], "volume_mult": 0.3, "envelope": "decay"}]
	},
	"door_close": {
		"wave": "noise", "freq": [150.0, 80.0], "duration": 0.25, "volume_db": -13.0,
		"envelope": "burst",
		"layers": [{"wave": "sine", "freq": 100.0, "volume_mult": 0.4, "envelope": "percussive"}]
	},
	"chest_open": {
		"wave": "sine", "freq": [300.0, 600.0], "duration": 0.35, "volume_db": -11.0,
		"envelope": "pluck", "harmonics": 2,
		"layers": [
			{"wave": "triangle", "freq": [250.0, 500.0], "volume_mult": 0.2, "envelope": "pluck"},
			{"wave": "noise",    "freq": 200.0,          "volume_mult": 0.1, "envelope": "burst"},
		]
	},
	"save_point": {
		"wave": "sine", "freq": [400.0, 800.0], "duration": 0.5, "volume_db": -11.0,
		"envelope": "swell", "harmonics": 2,
		"layers": [{"wave": "triangle", "freq": [350.0, 700.0], "volume_mult": 0.25, "envelope": "swell"}]
	},
	"save_complete": {
		"wave": "sine", "freq": [500.0, 1000.0], "duration": 0.4, "volume_db": -12.0,
		"envelope": "pluck", "harmonics": 2,
		"layers": [{"wave": "triangle", "freq": [400.0, 900.0], "volume_mult": 0.2, "envelope": "pluck"}]
	},
	"teleport": {
		"wave": "sine", "freq": [200.0, 2000.0], "duration": 0.5, "volume_db": -9.0,
		"envelope": "swell",
		"layers": [
			{"wave": "noise",    "freq": [300.0, 1500.0], "volume_mult": 0.2, "envelope": "swell"},
			{"wave": "triangle", "freq": [150.0, 1800.0], "volume_mult": 0.2, "envelope": "swell"},
		]
	},
	"water_splash": {"wave": "noise", "freq": [400.0, 150.0], "duration": 0.3, "volume_db": -14.0, "envelope": "decay", "filter": "lowpass"},
	"lever_pull": {
		"wave": "noise", "freq": [200.0, 100.0], "duration": 0.2, "volume_db": -14.0,
		"envelope": "burst",
		"layers": [{"wave": "sine", "freq": [300.0, 150.0], "volume_mult": 0.3, "envelope": "pluck"}]
	},
	"secret_found": {
		"wave": "sine", "freq": [400.0, 1200.0], "duration": 0.6, "volume_db": -10.0,
		"envelope": "swell", "harmonics": 3,
		"layers": [
			{"wave": "triangle", "freq": [350.0, 1000.0], "volume_mult": 0.3,  "envelope": "swell"},
			{"wave": "sine",     "freq": [500.0, 1400.0], "volume_mult": 0.15, "envelope": "pluck"},
		]
	},

	# ══════ SCENE TRANSITIONS ══════
	"transition_whoosh": {"wave": "noise", "freq": [100.0, 1500.0], "duration": 0.4, "volume_db": -11.0, "envelope": "swell", "filter": "highpass"},
	"transition_fade":   {"wave": "sine",  "freq": [800.0, 200.0],  "duration": 0.5, "volume_db": -17.0, "envelope": "decay"},
	"transition_glitch": {
		"wave": "noise", "freq": [500.0, 1500.0], "duration": 0.35, "volume_db": -10.0,
		"envelope": "burst",
		"layers": [{"wave": "square", "freq": [400.0, 1200.0], "volume_mult": 0.3, "envelope": "burst"}]
	},

	# ══════ NOTIFICATIONS / QUESTS ══════
	"quest_update": {
		"wave": "sine", "freq": [500.0, 700.0], "duration": 0.3, "volume_db": -13.0,
		"envelope": "pluck",
		"layers": [{"wave": "triangle", "freq": [450.0, 650.0], "volume_mult": 0.2, "envelope": "pluck"}]
	},
	"quest_complete": {
		"wave": "sine", "freq": [400.0, 800.0], "duration": 0.5, "volume_db": -9.0,
		"envelope": "swell", "harmonics": 2,
		"layers": [
			{"wave": "triangle", "freq": [350.0, 700.0],  "volume_mult": 0.25, "envelope": "swell"},
			{"wave": "sine",     "freq": [600.0, 1000.0], "volume_mult": 0.15, "envelope": "pluck"},
		]
	},
	"warning": {
		"wave": "square", "freq": 440.0, "duration": 0.3, "volume_db": -11.0,
		"envelope": "sustain",
		"layers": [{"wave": "sine", "freq": 440.0, "volume_mult": 0.3, "envelope": "sustain"}]
	},
	"alarm": {
		"wave": "square", "freq": [600.0, 400.0], "duration": 0.4, "volume_db": -9.0,
		"envelope": "sustain",
		"layers": [{"wave": "sine", "freq": [550.0, 350.0], "volume_mult": 0.3, "envelope": "sustain"}]
	},
	"notification_pop": {"wave": "sine", "freq": [700.0, 1000.0], "duration": 0.12, "volume_db": -14.0, "envelope": "pluck"},
	"story_flag": {
		"wave": "sine", "freq": [400.0, 700.0], "duration": 0.3, "volume_db": -13.0,
		"envelope": "pluck", "harmonics": 2,
	},

	# ══════ PROLOGUE / FLIGHT ══════
	"engine_hum": {
		"wave": "sine", "freq": 80.0, "duration": 0.5, "volume_db": -17.0,
		"envelope": "sustain", "harmonics": 2,
		"layers": [{"wave": "triangle", "freq": 120.0, "volume_mult": 0.3, "envelope": "sustain"}]
	},
	"turbulence": {
		"wave": "noise", "freq": [100.0, 500.0], "duration": 0.6, "volume_db": -11.0,
		"envelope": "burst",
		"layers": [{"wave": "sine", "freq": [80.0, 300.0], "volume_mult": 0.3, "envelope": "burst"}]
	},
	"crash_impact": {
		"wave": "noise", "freq": [400.0, 40.0], "duration": 1.2, "volume_db": -3.0,
		"envelope": "decay", "distortion": 0.4,
		"layers": [
			{"wave": "sine", "freq": [200.0, 20.0], "volume_mult": 0.5, "envelope": "decay"},
			{"wave": "saw",  "freq": [300.0, 30.0], "volume_mult": 0.3, "envelope": "decay"},
		]
	},
	"glass_shatter": {
		"wave": "noise", "freq": [2000.0, 500.0], "duration": 0.35, "volume_db": -9.0,
		"envelope": "decay", "filter": "highpass",
		"layers": [{"wave": "sine", "freq": [3000.0, 800.0], "volume_mult": 0.2, "envelope": "pluck"}]
	},
	"explosion_distant": {
		"wave": "noise", "freq": [200.0, 50.0], "duration": 0.8, "volume_db": -10.0,
		"envelope": "decay", "filter": "lowpass",
		"layers": [{"wave": "sine", "freq": [100.0, 30.0], "volume_mult": 0.5, "envelope": "swell"}]
	},
	"wind_gust": {"wave": "noise", "freq": [200.0, 400.0], "duration": 0.5, "volume_db": -16.0, "envelope": "swell", "filter": "highpass"},

	# ══════ ARENA ══════
	"crowd_cheer": {
		"wave": "noise", "freq": 400.0, "duration": 0.8, "volume_db": -13.0,
		"envelope": "swell",
		"layers": [
			{"wave": "noise", "freq": 600.0, "volume_mult": 0.3, "envelope": "swell"},
			{"wave": "noise", "freq": 300.0, "volume_mult": 0.2, "envelope": "swell"},
		]
	},
	"arena_bell": {
		"wave": "sine", "freq": 1200.0, "duration": 0.6, "volume_db": -9.0,
		"envelope": "pluck", "harmonics": 3,
		"layers": [{"wave": "sine", "freq": 2400.0, "volume_mult": 0.15, "envelope": "pluck"}]
	},
	"arena_victory": {
		"wave": "sine", "freq": [400.0, 1000.0], "duration": 0.7, "volume_db": -7.0,
		"envelope": "swell", "harmonics": 2,
		"layers": [
			{"wave": "triangle", "freq": [350.0, 900.0],  "volume_mult": 0.3, "envelope": "swell"},
			{"wave": "sine",     "freq": [600.0, 1200.0], "volume_mult": 0.2, "envelope": "swell"},
		]
	},
	"arena_defeat": {
		"wave": "saw", "freq": [400.0, 150.0], "duration": 0.6, "volume_db": -10.0,
		"envelope": "decay",
		"layers": [{"wave": "sine", "freq": [300.0, 100.0], "volume_mult": 0.4, "envelope": "decay"}]
	},
	"arena_crowd_boo":    {"wave": "noise", "freq": 250.0, "duration": 0.6, "volume_db": -15.0, "envelope": "swell", "filter": "lowpass"},
	"arena_tier_advance": {
		"wave": "sine", "freq": [300.0, 1200.0], "duration": 0.6, "volume_db": -8.0,
		"envelope": "swell", "harmonics": 3,
		"layers": [
			{"wave": "triangle", "freq": [250.0, 1000.0], "volume_mult": 0.3,  "envelope": "swell"},
			{"wave": "noise",    "freq": 800.0,           "volume_mult": 0.08, "envelope": "swell"},
		]
	},

	# ══════ CLOCK TOWER — Chapter 2 ══════
	"clock_tick": {
		"wave": "sine", "freq": 1200.0, "duration": 0.04, "volume_db": -16.0,
		"envelope": "pluck",
		"layers": [{"wave": "noise", "freq": 800.0, "volume_mult": 0.1, "envelope": "burst"}]
	},
	"clock_chime": {
		"wave": "sine", "freq": 800.0, "duration": 0.8, "volume_db": -10.0,
		"envelope": "pluck", "harmonics": 4,
		"layers": [
			{"wave": "sine", "freq": 1600.0, "volume_mult": 0.15, "envelope": "pluck"},
			{"wave": "sine", "freq": 400.0,  "volume_mult": 0.2,  "envelope": "decay"},
		]
	},
	"time_slow": {
		"wave": "sine", "freq": [400.0, 200.0], "duration": 0.4, "volume_db": -12.0,
		"envelope": "swell", "vibrato_hz": 3.0, "vibrato_depth": 0.15,
		"layers": [{"wave": "triangle", "freq": [350.0, 150.0], "volume_mult": 0.3, "envelope": "swell"}]
	},
	"time_fast": {
		"wave": "sine", "freq": [200.0, 600.0], "duration": 0.3, "volume_db": -12.0,
		"envelope": "pluck",
		"layers": [{"wave": "triangle", "freq": [180.0, 550.0], "volume_mult": 0.3, "envelope": "pluck"}]
	},
	"gear_grind": {
		"wave": "noise", "freq": [300.0, 150.0], "duration": 0.25, "volume_db": -14.0,
		"envelope": "sustain",
		"layers": [{"wave": "saw", "freq": [200.0, 100.0], "volume_mult": 0.2, "envelope": "sustain"}]
	},

	# ══════ ENEMY-SPECIFIC COMBAT SFX (Pass 32) ══════
	"enemy_hop": {
		"wave": "sine", "freq": [300.0, 180.0], "duration": 0.15, "volume_db": -14.0,
		"envelope": "pluck",
		"layers": [{"wave": "noise", "freq": 200.0, "volume_mult": 0.15, "envelope": "burst"}]
	},
	"enemy_splat": {
		"wave": "noise", "freq": [400.0, 100.0], "duration": 0.2, "volume_db": -12.0,
		"envelope": "decay",
		"layers": [{"wave": "sine", "freq": [250.0, 80.0], "volume_mult": 0.3, "envelope": "decay"}]
	},
	"enemy_lunge": {
		"wave": "noise", "freq": [800.0, 300.0], "duration": 0.12, "volume_db": -13.0,
		"envelope": "burst",
		"layers": [{"wave": "saw", "freq": [500.0, 200.0], "volume_mult": 0.2, "envelope": "decay"}]
	},
	"glitch_teleport": {
		"wave": "noise", "freq": [2000.0, 400.0], "duration": 0.18, "volume_db": -11.0,
		"envelope": "pluck", "distortion": 0.4,
		"layers": [
			{"wave": "square", "freq": [1200.0, 300.0], "volume_mult": 0.25, "envelope": "burst"},
			{"wave": "sine", "freq": [600.0, 200.0], "volume_mult": 0.15, "envelope": "decay"},
		]
	},
	"enemy_pounce": {
		"wave": "noise", "freq": [600.0, 400.0], "duration": 0.14, "volume_db": -12.0,
		"envelope": "burst",
		"layers": [{"wave": "saw", "freq": [400.0, 250.0], "volume_mult": 0.25, "envelope": "pluck"}]
	},
	"enemy_attack": {
		"wave": "noise", "freq": [900.0, 400.0], "duration": 0.12, "volume_db": -12.0,
		"envelope": "burst",
		"layers": [{"wave": "saw", "freq": [600.0, 300.0], "volume_mult": 0.2, "envelope": "decay"}]
	},
	"shield_block": {
		"wave": "square", "freq": [500.0, 250.0], "duration": 0.1, "volume_db": -10.0,
		"envelope": "pluck", "harmonics": 3,
		"layers": [{"wave": "noise", "freq": 600.0, "volume_mult": 0.3, "envelope": "burst"}]
	},
	"shield_hit": {
		"wave": "square", "freq": [600.0, 300.0], "duration": 0.12, "volume_db": -10.0,
		"envelope": "pluck", "harmonics": 2,
		"layers": [{"wave": "noise", "freq": 700.0, "volume_mult": 0.25, "envelope": "burst"}]
	},
	"projectile_fire": {
		"wave": "sine", "freq": [1200.0, 800.0], "duration": 0.1, "volume_db": -13.0,
		"envelope": "burst",
		"layers": [{"wave": "noise", "freq": 1000.0, "volume_mult": 0.2, "envelope": "burst"}]
	},
	"wraith_phase": {
		"wave": "sine", "freq": [600.0, 200.0], "duration": 0.3, "volume_db": -11.0,
		"envelope": "decay", "vibrato_hz": 6.0, "vibrato_depth": 0.3,
		"layers": [{"wave": "noise", "freq": [400.0, 100.0], "volume_mult": 0.2, "envelope": "decay"}]
	},
	"wraith_materialize": {
		"wave": "sine", "freq": [200.0, 500.0], "duration": 0.25, "volume_db": -11.0,
		"envelope": "swell", "vibrato_hz": 5.0, "vibrato_depth": 0.2,
		"layers": [{"wave": "noise", "freq": [150.0, 400.0], "volume_mult": 0.2, "envelope": "swell"}]
	},
	"wraith_death": {
		"wave": "sine", "freq": [500.0, 100.0], "duration": 0.5, "volume_db": -10.0,
		"envelope": "decay", "vibrato_hz": 8.0, "vibrato_depth": 0.4, "distortion": 0.2,
		"layers": [
			{"wave": "noise", "freq": [600.0, 50.0], "volume_mult": 0.3, "envelope": "decay"},
			{"wave": "triangle", "freq": [300.0, 80.0], "volume_mult": 0.15, "envelope": "decay"},
		]
	},
	"ground_slam": {
		"wave": "sine", "freq": [150.0, 50.0], "duration": 0.3, "volume_db": -8.0,
		"envelope": "decay", "distortion": 0.3,
		"layers": [
			{"wave": "noise", "freq": [300.0, 80.0], "volume_mult": 0.4, "envelope": "burst"},
			{"wave": "square", "freq": [100.0, 40.0], "volume_mult": 0.2, "envelope": "decay"},
		]
	},
	"heavy_fall": {
		"wave": "sine", "freq": [200.0, 60.0], "duration": 0.2, "volume_db": -10.0,
		"envelope": "decay",
		"layers": [{"wave": "noise", "freq": [250.0, 100.0], "volume_mult": 0.35, "envelope": "burst"}]
	},
	"enforcer_death": {
		"wave": "noise", "freq": [1500.0, 200.0], "duration": 0.4, "volume_db": -9.0,
		"envelope": "decay", "distortion": 0.5,
		"layers": [
			{"wave": "square", "freq": [800.0, 100.0], "volume_mult": 0.3, "envelope": "decay"},
			{"wave": "sine", "freq": [400.0, 80.0], "volume_mult": 0.15, "envelope": "decay"},
		]
	},

	# ══════ COMBAT FEEDBACK SFX (Pass 32) ══════
	"counter_hit": {
		"wave": "square", "freq": [800.0, 400.0], "duration": 0.12, "volume_db": -9.0,
		"envelope": "pluck", "harmonics": 3,
		"layers": [
			{"wave": "noise", "freq": 900.0, "volume_mult": 0.3, "envelope": "burst"},
			{"wave": "sine", "freq": [1200.0, 600.0], "volume_mult": 0.15, "envelope": "pluck"},
		]
	},
	"dodge_perfect": {
		"wave": "sine", "freq": [1000.0, 600.0], "duration": 0.1, "volume_db": -12.0,
		"envelope": "pluck",
		"layers": [{"wave": "noise", "freq": 800.0, "volume_mult": 0.1, "envelope": "burst"}]
	},
	"multi_kill": {
		"wave": "sine", "freq": [600.0, 900.0], "duration": 0.25, "volume_db": -9.0,
		"envelope": "pluck", "harmonics": 3,
		"layers": [
			{"wave": "sine", "freq": [900.0, 1200.0], "volume_mult": 0.2, "envelope": "pluck"},
			{"wave": "triangle", "freq": [400.0, 600.0], "volume_mult": 0.15, "envelope": "swell"},
		]
	},
	# ══════ PUZZLE & ENVIRONMENT (added Pass 53) ══════
	"puzzle_solve": {
		"wave": "sine", "freq": [400.0, 800.0], "duration": 0.5, "volume_db": -10.0,
		"envelope": "swell", "harmonics": 3,
		"layers": [
			{"wave": "triangle", "freq": [600.0, 1200.0], "volume_mult": 0.3, "envelope": "pluck"},
			{"wave": "sine", "freq": [800.0, 1600.0], "volume_mult": 0.15, "envelope": "pluck"},
		]
	},
}

# ─── LIFECYCLE ───────────────────────────────────────────────────────────

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	# Pass 53: Sync volume from MusicManager on startup
	if has_node("/root/MusicManager"):
		_sfx_volume = MusicManager.get_sfx_volume()


func _exit_tree() -> void:
	## Release generated streams and active playback immediately during shutdown.
	## This prevents quit/export QA from reporting procedural SFX as leaked objects.
	for child in get_children():
		if child is AudioStreamPlayer:
			child.stop()
			child.stream = null
			if child.finished.is_connected(child.queue_free):
				child.finished.disconnect(child.queue_free)
			child.free()
	_cache.clear()

# ─── PUBLIC API ──────────────────────────────────────────────────────────

## Play a named procedural sound effect.
## [param pitch_variation]: random pitch offset range (e.g. 0.1 = +/-10%).
func play(sfx_name: String, pitch_variation: float = 0.0) -> void:
	if not SFX_DEFS.has(sfx_name):
		push_warning("SFXManager: Unknown SFX '%s'" % sfx_name)
		return

	# Limit concurrent SFX children
	var active = 0
	for child: Node in get_children():
		if child is AudioStreamPlayer:
			active += 1
	if active >= MAX_CONCURRENT_SFX:
		return

	# Sync volume from MusicManager if available
	if has_node("/root/MusicManager"):
		_sfx_volume = MusicManager.get_sfx_volume()

	var pitch_mult = 1.0
	if pitch_variation > 0.0:
		pitch_mult = 1.0 + randf_range(-pitch_variation, pitch_variation)

	# Try cache first (only for zero-variation calls)
	var cache_key: String = sfx_name if pitch_variation == 0.0 else ""
	var audio: AudioStreamWAV

	if cache_key != "" and _cache.has(cache_key):
		audio = _cache[cache_key]
	else:
		audio = _generate_sfx(sfx_name, pitch_mult)
		if cache_key != "":
			# Pass 55: Evict oldest entry when cache exceeds cap
			if _cache.size() >= MAX_CACHE_SIZE:
				var first_key = _cache.keys()[0]
				_cache.erase(first_key)
			_cache[cache_key] = audio

	if audio == null:
		return

	var player = AudioStreamPlayer.new()
	player.stream = audio
	player.volume_db = 0.0  # volume baked into waveform samples
	player.bus = "SFX" if AudioServer.get_bus_index("SFX") >= 0 else "Master"  # Pass 53: Route to SFX bus
	player.pitch_scale = pitch_mult if (pitch_variation > 0.0 and cache_key == "") else 1.0
	add_child(player)
	player.play()
	player.finished.connect(player.queue_free)


## Play a random SFX from the given list.
func play_random(sfx_names: Array, pitch_variation: float = 0.0) -> void:
	if sfx_names.is_empty():
		return
	play(sfx_names[randi() % sfx_names.size()], pitch_variation)


## Play SFX with volume falloff based on distance from listener.
func play_positional(sfx_name: String, world_pos: Vector2, listener_pos: Vector2, max_dist: float = 800.0) -> void:
	var dist = world_pos.distance_to(listener_pos)
	if dist > max_dist:
		return
	var falloff = 1.0 - (dist / max_dist)
	# Pass 53: Apply falloff on the AudioStreamPlayer instead of mutating shared _sfx_volume
	play(sfx_name)
	# Find last-spawned player and apply distance attenuation
	for i in range(get_child_count() - 1, -1, -1):
		var child = get_child(i)
		if child is AudioStreamPlayer:
			child.volume_db += linear_to_db(maxf(falloff, 0.01))
			break


## Play a random variant of a base SFX (e.g. "sword_swing" → _2, _3).
func play_varied(base_sfx_name: String, pitch_variation: float = 0.1) -> void:
	var variants: Array[String] = [base_sfx_name]
	for i: int in range(2, 5):
		var variant = "%s_%d" % [base_sfx_name, i]
		if SFX_DEFS.has(variant):
			variants.append(variant)
	play_random(variants, pitch_variation)


## Clear the cache between major scenes to free memory.
func clear_cache() -> void:
	_cache.clear()

# ─── SYNTHESIS ENGINE ────────────────────────────────────────────────────

## Generate an AudioStreamWAV from an SFX_DEFS entry with multi-layer support.
func _generate_sfx(sfx_name: String, pitch_mult: float = 1.0) -> AudioStreamWAV:
	var def: Dictionary = SFX_DEFS[sfx_name]
	var duration: float    = def.get("duration", 0.2)
	var volume_db: float   = def.get("volume_db", -12.0)
	var wave_type: String  = def.get("wave", "sine")
	var envelope_type: String = def.get("envelope", "decay")
	var filter_type: String = def.get("filter", "")
	var num_harmonics: int = def.get("harmonics", 0)
	var distortion_amt: float = def.get("distortion", 0.0)
	var vibrato_hz: float  = def.get("vibrato_hz", 0.0)
	var vibrato_depth: float = def.get("vibrato_depth", 0.0)
	var layers: Array      = def.get("layers", [])

	var num_samples = int(SAMPLE_RATE * duration)
	if num_samples < 1:
		return null

	# Parse frequency (constant or sweep array)
	var freq_start: float
	var freq_end: float
	var freq_val = def.get("freq", 440.0)
	if freq_val is Array:
		freq_start = float(freq_val[0]) * pitch_mult
		freq_end   = float(freq_val[1]) * pitch_mult
	else:
		freq_start = float(freq_val) * pitch_mult
		freq_end   = freq_start

	var audio = AudioStreamWAV.new()
	audio.mix_rate = SAMPLE_RATE
	audio.format = AudioStreamWAV.FORMAT_16_BITS
	audio.stereo = false

	var data = PackedByteArray()
	data.resize(num_samples * 2)

	var vol_linear: float = db_to_linear(volume_db) * _sfx_volume
	var phase = 0.0

	# Harmonic overtone phases
	var harmonic_phases: Array[float] = []
	for _h: int in range(num_harmonics):
		harmonic_phases.append(0.0)

	# Layer state
	var layer_phases: Array[float] = []
	var layer_freq_starts: Array[float] = []
	var layer_freq_ends: Array[float] = []
	for layer: Dictionary in layers:
		layer_phases.append(0.0)
		var lf = layer.get("freq", 440.0)
		if lf is Array:
			layer_freq_starts.append(float(lf[0]) * pitch_mult)
			layer_freq_ends.append(float(lf[1]) * pitch_mult)
		else:
			layer_freq_starts.append(float(lf) * pitch_mult)
			layer_freq_ends.append(float(lf) * pitch_mult)

	for i: int in range(num_samples):
		var t: float = float(i) / float(SAMPLE_RATE)
		var t_norm: float = float(i) / float(num_samples)

		# Frequency interpolation (sweep)
		var freq: float = lerpf(freq_start, freq_end, t_norm)

		# Apply vibrato LFO
		if vibrato_hz > 0.0:
			freq *= 1.0 + sin(TAU * vibrato_hz * t) * vibrato_depth

		# Envelope
		var env: float = _get_envelope(envelope_type, t_norm)

		# Primary waveform
		var sample: float = _get_waveform(wave_type, phase)

		# Harmonic overtones
		for h: int in range(num_harmonics):
			var harm_mult = float(h + 2)
			var harm_amp = 1.0 / (harm_mult * 1.5)
			sample += _get_waveform(wave_type, harmonic_phases[h]) * harm_amp
			harmonic_phases[h] += freq * harm_mult / float(SAMPLE_RATE)
			if harmonic_phases[h] > 1.0:
				harmonic_phases[h] -= 1.0

		# Normalize after harmonics
		if num_harmonics > 0:
			var total_amp = 1.0
			for h: int in range(num_harmonics):
				total_amp += 1.0 / (float(h + 2) * 1.5)
			sample /= total_amp

		# Advance primary phase
		phase += freq / float(SAMPLE_RATE)
		if phase > 1.0:
			phase -= 1.0

		# Mix in layers
		for li: int in range(layers.size()):
			var layer: Dictionary = layers[li]
			var l_wave: String = layer.get("wave", "sine")
			var l_vol: float = layer.get("volume_mult", 0.3)
			var l_env_type: String = layer.get("envelope", envelope_type)
			var l_env: float = _get_envelope(l_env_type, t_norm)
			var l_freq: float = lerpf(layer_freq_starts[li], layer_freq_ends[li], t_norm)

			sample += _get_waveform(l_wave, layer_phases[li]) * l_vol * l_env

			layer_phases[li] += l_freq / float(SAMPLE_RATE)
			if layer_phases[li] > 1.0:
				layer_phases[li] -= 1.0

		# Distortion (soft clip)
		if distortion_amt > 0.0:
			sample = _soft_clip(sample, distortion_amt)

		# Apply envelope and volume
		sample *= env * vol_linear

		var sample_int = clampi(int(sample * 32767.0), -32768, 32767)
		data[i * 2] = sample_int & 0xFF
		data[i * 2 + 1] = (sample_int >> 8) & 0xFF

	# Post-process filter
	if filter_type != "":
		data = _apply_filter(data, num_samples, filter_type)

	audio.data = data
	return audio

# ─── WAVEFORM GENERATORS ────────────────────────────────────────────────

## Single-sample waveform at the given phase (0 – 1).
func _get_waveform(wave_type: String, phase: float) -> float:
	var p = fmod(phase, 1.0)
	match wave_type:
		"sine":
			return sin(TAU * p)
		"square":
			return 0.95 if p < 0.5 else -0.95
		"saw":
			return 2.0 * p - 1.0
		"triangle":
			return 4.0 * absf(p - 0.5) - 1.0
		"noise":
			return randf_range(-1.0, 1.0)
		_:
			return sin(TAU * p)


## Envelope value at normalised time (0 – 1).
func _get_envelope(env_type: String, t_norm: float) -> float:
	match env_type:
		"decay":
			var e = 1.0 - t_norm
			return e * e
		"pluck":
			var e = maxf(0.0, 1.0 - t_norm * 3.0)
			return e * e * e
		"burst":
			if t_norm < 0.1:
				return 1.0
			return maxf(0.0, 1.0 - (t_norm - 0.1) / 0.9) * 0.5
		"sustain":
			if t_norm < 0.05:
				return t_norm / 0.05
			elif t_norm > 0.85:
				return (1.0 - t_norm) / 0.15
			return 1.0
		"swell":
			if t_norm < 0.4:
				return t_norm / 0.4
			return maxf(0.0, 1.0 - (t_norm - 0.4) / 0.6)
		"percussive":
			if t_norm < 0.02:
				return t_norm / 0.02
			var e = 1.0 - (t_norm - 0.02) / 0.98
			return e * e * e
		"adsr":
			if t_norm < 0.1:
				return t_norm / 0.1
			elif t_norm < 0.3:
				return 1.0 - (t_norm - 0.1) / 0.2 * 0.3
			elif t_norm < 0.8:
				return 0.7
			else:
				return 0.7 * (1.0 - (t_norm - 0.8) / 0.2)
		_:
			return 1.0 - t_norm


## Warm analog-style soft-clip distortion.
func _soft_clip(sample: float, amount: float) -> float:
	var gain = 1.0 + amount * 4.0
	sample *= gain
	if sample > 1.0:
		sample = 1.0 - exp(-sample + 1.0) * 0.3
	elif sample < -1.0:
		sample = -1.0 + exp(sample + 1.0) * 0.3
	return sample / gain * (1.0 + amount)


## Simple one-pole filter applied to raw PCM data.
func _apply_filter(data: PackedByteArray, num_samples: int, filter_type: String) -> PackedByteArray:
	var alpha: float
	match filter_type:
		"lowpass":  alpha = 0.15
		"highpass": alpha = 0.85
		"bandpass": alpha = 0.5
		_: return data

	var prev_sample = 0.0
	var prev_input = 0.0

	for i: int in range(num_samples):
		var raw = data[i * 2] | (data[i * 2 + 1] << 8)
		if raw > 32767:
			raw -= 65536
		var sample = float(raw) / 32767.0

		match filter_type:
			"lowpass":
				sample = prev_sample + alpha * (sample - prev_sample)
			"highpass":
				var filtered = alpha * (prev_sample + sample - prev_input)
				prev_input = sample
				sample = filtered
			"bandpass":
				var lp = prev_sample + 0.3 * (sample - prev_sample)
				sample = 0.7 * (lp - prev_sample) + prev_sample

		prev_sample = sample
		var s_int = clampi(int(sample * 32767.0), -32768, 32767)
		data[i * 2] = s_int & 0xFF
		data[i * 2 + 1] = (s_int >> 8) & 0xFF

	return data
