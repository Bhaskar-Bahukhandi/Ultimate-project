extends Node
## ==========================================================================
## MusicManager — Procedural multi-voice music system (Autoload)
## ==========================================================================
## Manages background music tracks using waveform synthesis. Each track has
## multiple voices (melody, bass, pad, harmony, etc.) that play concurrently.
##
## Usage:
##   MusicManager.play_track("main_menu")
##   MusicManager.play_track("combat")
##   MusicManager.stop()
##   MusicManager.set_music_volume(0.8)
##   MusicManager.set_sfx_volume(0.7)
## ==========================================================================

# ─── CONSTANTS ───────────────────────────────────────────────────────────

const FADE_DURATION = 1.5
const DEFAULT_MUSIC_VOLUME = 0.7
const DEFAULT_SFX_VOLUME = 0.8
const SAMPLE_RATE = 22050
const MAX_CONCURRENT_NOTES = 6  ## Cap voice note children

# ── Pass 55 H-01: Note PCM cache (freq+wave+dur → AudioStreamWAV) ─────
var _note_cache: Dictionary = {}
const MAX_NOTE_CACHE_SIZE: int = 48

# ─── NOTE FREQUENCIES (A4 = 440 Hz) ─────────────────────────────────────

const C3 = 130.81; const Cs3 = 138.59; const D3 = 146.83; const Ds3 = 155.56
const E3 = 164.81; const F3 = 174.61; const Fs3 = 185.0;  const G3 = 196.0
const Gs3 = 207.65; const A3 = 220.0;  const As3 = 233.08; const B3 = 246.94

const C4 = 261.63; const Cs4 = 277.18; const D4 = 293.66; const Ds4 = 311.13
const E4 = 329.63; const F4 = 349.23; const Fs4 = 369.99; const G4 = 392.0
const Gs4 = 415.30; const A4 = 440.0;  const As4 = 466.16; const B4 = 493.88

const C5 = 523.25; const Cs5 = 554.37; const D5 = 587.33; const Ds5 = 622.25
const E5 = 659.25; const F5 = 698.46; const Fs5 = 739.99; const G5 = 783.99
const A5 = 880.0;  const B5 = 987.77

# ─── TRACK DEFINITIONS ──────────────────────────────────────────────────
## Each track has { source, tempo, volume_db, description, voices:{} }.
## Each voice has { notes:[], wave, volume, duration, octave_shift }.

var TRACKS: Dictionary = {
	# ═══ MAIN MENU — Ethereal, mysterious, inviting ═══
	"main_menu": {
		"source": "procedural", "tempo": 0.55, "volume_db": -12.0,
		"description": "Ethereal main menu — mysterious ambient pad with gentle melody",
		"voices": {
			"melody":   {"notes": [E4, G4, B4, A4, G4, E4, D4, E4, G4, A4, B4, D5, C5, B4, A4, G4],         "wave": "sine",     "volume": 0.6,  "duration": 0.3,  "octave_shift": 0},
			"pad":      {"notes": [E3, E3, A3, A3, G3, G3, D3, D3, E3, E3, A3, A3, G3, G3, C4, C4],         "wave": "triangle", "volume": 0.25, "duration": 0.8,  "octave_shift": 0},
			"harmony":  {"notes": [B4, D5, Fs4, E4, D4, B3, A3, B3, D4, E4, Fs4, A4, G4, Fs4, E4, D4],     "wave": "sine",     "volume": 0.3,  "duration": 0.25, "octave_shift": 0},
			"sub_bass": {"notes": [E3, E3, A3, A3, G3, G3, D3, D3, E3, E3, A3, A3, G3, G3, C3, C3],         "wave": "sine",     "volume": 0.15, "duration": 0.9,  "octave_shift": -1},
		}
	},
	# ═══ EXPLORATION — Calm, warm, peaceful village ═══
	"exploration": {
		"source": "procedural", "tempo": 0.45, "volume_db": -14.0,
		"description": "Warm exploration — folk-like melody over gentle chords",
		"voices": {
			"melody": {"notes": [D4, F4, A4, G4, F4, E4, D4, C4, D4, F4, G4, A4, C5, A4, G4, F4],          "wave": "triangle", "volume": 0.55, "duration": 0.28, "octave_shift": 0},
			"pad":    {"notes": [D3, D3, F3, F3, C4, C4, A3, A3, D3, D3, F3, F3, G3, G3, F3, F3],           "wave": "sine",     "volume": 0.2,  "duration": 0.7,  "octave_shift": 0},
			"arp":    {"notes": [A4, D5, F5, A4, C5, F5, G4, C5, E5, A4, D5, F5, A4, C5, E5, D5],           "wave": "sine",     "volume": 0.18, "duration": 0.15, "octave_shift": 0},
			"bass":   {"notes": [D3, D3, F3, F3, C3, C3, A3, A3, D3, D3, F3, F3, G3, G3, F3, F3],           "wave": "sine",     "volume": 0.2,  "duration": 0.6,  "octave_shift": -1},
		}
	},
	# ═══ EXPLORATION NIGHT — Quieter, atmospheric ═══
	"exploration_night": {
		"source": "procedural", "tempo": 0.6, "volume_db": -16.0,
		"description": "Nocturnal ambient — sparse piano-like notes over deep pad",
		"voices": {
			"melody":  {"notes": [E4, 0, B4, 0, A4, 0, E4, 0, G4, 0, D4, 0, E4, 0, B3, 0],                 "wave": "sine",     "volume": 0.45, "duration": 0.35, "octave_shift": 0},
			"pad":     {"notes": [E3, E3, E3, E3, A3, A3, A3, A3, G3, G3, G3, G3, B3, B3, B3, B3],          "wave": "triangle", "volume": 0.15, "duration": 1.0,  "octave_shift": 0},
			"shimmer": {"notes": [B5, 0, 0, E5, 0, 0, A5, 0, 0, G5, 0, 0, B5, 0, 0, E5],                   "wave": "sine",     "volume": 0.1,  "duration": 0.2,  "octave_shift": 0},
		}
	},
	# ═══ COMBAT — Fast, intense, driving ═══
	"combat": {
		"source": "procedural", "tempo": 0.2, "volume_db": -10.0,
		"description": "Driving combat — aggressive bass riff with sharp melody hits",
		"voices": {
			"melody":     {"notes": [A4, C5, A4, E4, G4, A4, C5, D5, A4, C5, A4, E4, G4, F4, E4, D4],      "wave": "square",   "volume": 0.35, "duration": 0.12, "octave_shift": 0},
			"bass":       {"notes": [A3, A3, E3, E3, G3, G3, D3, D3, A3, A3, F3, F3, G3, G3, E3, E3],       "wave": "saw",      "volume": 0.3,  "duration": 0.18, "octave_shift": -1},
			"percussion": {"notes": [0, 200, 0, 100, 0, 200, 100, 0, 0, 200, 0, 100, 200, 0, 100, 200],     "wave": "noise",    "volume": 0.2,  "duration": 0.06, "octave_shift": 0},
			"harmony":    {"notes": [E4, G4, E4, C4, D4, E4, G4, A4, E4, G4, E4, C4, D4, C4, B3, A3],       "wave": "triangle", "volume": 0.2,  "duration": 0.1,  "octave_shift": 0},
		}
	},
	# ═══ COMBAT INTENSE — Higher intensity variant ═══
	"combat_intense": {
		"source": "procedural", "tempo": 0.17, "volume_db": -9.0,
		"description": "High-intensity combat — rapid arpeggios and heavy bass",
		"voices": {
			"melody":     {"notes": [E5, D5, C5, B4, A4, G4, A4, B4, C5, D5, E5, D5, C5, A4, B4, E5],      "wave": "square",   "volume": 0.35, "duration": 0.1,  "octave_shift": 0},
			"bass":       {"notes": [A3, A3, G3, G3, F3, F3, E3, E3, A3, A3, D3, D3, E3, E3, A3, A3],       "wave": "saw",      "volume": 0.35, "duration": 0.15, "octave_shift": -1},
			"arp":        {"notes": [A4, C5, E5, A4, G4, B4, D5, G4, F4, A4, C5, F4, E4, G4, B4, E4],       "wave": "triangle", "volume": 0.2,  "duration": 0.08, "octave_shift": 0},
			"percussion": {"notes": [200, 0, 100, 200, 0, 200, 100, 0, 200, 100, 0, 200, 100, 200, 0, 200], "wave": "noise",    "volume": 0.22, "duration": 0.05, "octave_shift": 0},
		}
	},
	# ═══ BOSS FIGHT — Epic, powerful, dramatic ═══
	"boss_fight": {
		"source": "procedural", "tempo": 0.22, "volume_db": -8.0,
		"description": "Epic boss battle — powerful bass + dramatic ascending melody",
		"voices": {
			"melody":        {"notes": [C4, E4, G4, C5, B4, G4, A4, B4, C5, E5, D5, C5, B4, A4, G4, E4],       "wave": "square",   "volume": 0.4,  "duration": 0.15, "octave_shift": 0},
			"bass":          {"notes": [C3, C3, G3, G3, A3, A3, E3, E3, C3, C3, F3, F3, G3, G3, C3, C3],        "wave": "saw",      "volume": 0.35, "duration": 0.2,  "octave_shift": -1},
			"pad":           {"notes": [G3, G3, G3, G3, A3, A3, A3, A3, F3, F3, F3, F3, G3, G3, G3, G3],        "wave": "triangle", "volume": 0.2,  "duration": 0.5,  "octave_shift": 0},
			"percussion":    {"notes": [300, 0, 100, 0, 300, 0, 100, 300, 0, 100, 0, 300, 100, 0, 300, 0],      "wave": "noise",    "volume": 0.25, "duration": 0.06, "octave_shift": 0},
			"counter_melody": {"notes": [G4, A4, B4, C5, D5, E5, D5, C5, B4, C5, D5, E5, G5, E5, D5, C5],      "wave": "sine",     "volume": 0.2,  "duration": 0.12, "octave_shift": 0},
		}
	},
	# ═══ BOSS RAGE — Frantic, desperate ═══
	"boss_rage": {
		"source": "procedural", "tempo": 0.14, "volume_db": -7.0,
		"description": "Boss rage phase — frantic tempo with dissonant harmonics",
		"voices": {
			"melody":     {"notes": [E4, Ds4, E4, G4, A4, G4, E4, Ds4, C4, Ds4, E4, G4, A4, B4, A4, G4],       "wave": "square",   "volume": 0.4,  "duration": 0.1,  "octave_shift": 0},
			"bass":       {"notes": [E3, E3, E3, E3, C3, C3, C3, C3, A3, A3, A3, A3, B3, B3, B3, B3],           "wave": "saw",      "volume": 0.38, "duration": 0.12, "octave_shift": -1},
			"alarm":      {"notes": [B5, 0, B5, 0, A5, 0, A5, 0, B5, 0, B5, 0, G5, 0, G5, 0],                   "wave": "square",   "volume": 0.12, "duration": 0.06, "octave_shift": 0},
			"percussion": {"notes": [300, 150, 300, 150, 300, 300, 150, 300, 150, 300, 150, 300, 300, 150, 300, 300], "wave": "noise", "volume": 0.28, "duration": 0.04, "octave_shift": 0},
		}
	},
	# ═══ VICTORY — Triumphant, uplifting ═══
	"victory": {
		"source": "procedural", "tempo": 0.35, "volume_db": -10.0,
		"description": "Triumphant victory fanfare — bright ascending chords",
		"voices": {
			"melody":  {"notes": [C4, E4, G4, C5, E5, G5, E5, C5, G4, C5, E5, G5, C5, E5, G5, C5],             "wave": "triangle", "volume": 0.5,  "duration": 0.25, "octave_shift": 0},
			"harmony": {"notes": [E4, G4, B4, E5, G4, B4, G4, E4, D4, E4, G4, B4, E4, G4, B4, E4],             "wave": "sine",     "volume": 0.35, "duration": 0.22, "octave_shift": 0},
			"bass":    {"notes": [C3, C3, G3, G3, C3, C3, G3, G3, F3, F3, G3, G3, C3, C3, G3, C3],             "wave": "sine",     "volume": 0.25, "duration": 0.4,  "octave_shift": 0},
			"chime":   {"notes": [C5, E5, G5, C5, E5, G5, B4, D5, G5, C5, E5, G5, C5, E5, G5, C5],             "wave": "sine",     "volume": 0.15, "duration": 0.15, "octave_shift": 1},
		}
	},
	# ═══ DIALOGUE — Soft ambient, non-intrusive ═══
	"dialogue": {
		"source": "procedural", "tempo": 0.7, "volume_db": -18.0,
		"description": "Soft dialogue ambience — gentle piano-like arpeggios",
		"voices": {
			"melody": {"notes": [A4, C5, E5, A4, G4, B4, D5, G4, F4, A4, C5, F4, E4, G4, B4, E4],             "wave": "sine",     "volume": 0.35, "duration": 0.3,  "octave_shift": 0},
			"pad":    {"notes": [A3, A3, A3, A3, G3, G3, G3, G3, F3, F3, F3, F3, E3, E3, E3, E3],              "wave": "triangle", "volume": 0.12, "duration": 0.9,  "octave_shift": 0},
		}
	},
	# ═══ GAME OVER — Somber, melancholic ═══
	"game_over": {
		"source": "procedural", "tempo": 0.65, "volume_db": -11.0,
		"description": "Somber game over — descending minor melody with hollow pad",
		"voices": {
			"melody": {"notes": [E4, D4, C4, B3, A3, G3, A3, B3, C4, B3, A3, G3, F3, E3, D3, E3],             "wave": "triangle", "volume": 0.45, "duration": 0.4,  "octave_shift": 0},
			"pad":    {"notes": [A3, A3, G3, G3, F3, F3, E3, E3, A3, A3, G3, G3, D3, D3, E3, E3],              "wave": "sine",     "volume": 0.18, "duration": 0.9,  "octave_shift": 0},
			"drone":  {"notes": [E3, E3, E3, E3, E3, E3, E3, E3, E3, E3, E3, E3, E3, E3, E3, E3],              "wave": "sine",     "volume": 0.12, "duration": 1.2,  "octave_shift": -1},
		}
	},
	# ═══ PROLOGUE — Mysterious, technological, uneasy ═══
	"prologue": {
		"source": "procedural", "tempo": 0.5, "volume_db": -13.0,
		"description": "Flight 707 prologue — tense technological ambience",
		"voices": {
			"melody":  {"notes": [D4, 0, F4, 0, A4, 0, G4, F4, D4, 0, E4, 0, G4, 0, A4, G4],                  "wave": "sine",     "volume": 0.4,  "duration": 0.3,  "octave_shift": 0},
			"pad":     {"notes": [D3, D3, D3, D3, A3, A3, A3, A3, G3, G3, G3, G3, D3, D3, D3, D3],             "wave": "triangle", "volume": 0.18, "duration": 0.8,  "octave_shift": 0},
			"tension": {"notes": [0, Fs4, 0, 0, 0, Cs4, 0, 0, 0, Ds4, 0, 0, 0, As3, 0, 0],                    "wave": "square",   "volume": 0.08, "duration": 0.15, "octave_shift": 0},
		}
	},
	# ═══ CRASH — Chaotic, terrifying, system failure ═══
	"crash": {
		"source": "procedural", "tempo": 0.15, "volume_db": -8.0,
		"description": "Plane crash / system failure — chaotic dissonant noise",
		"voices": {
			"alarm":  {"notes": [A5, 0, A5, 0, G5, 0, G5, 0, A5, 0, A5, 0, F5, 0, F5, 0],                     "wave": "square", "volume": 0.3,  "duration": 0.08, "octave_shift": 0},
			"rumble": {"notes": [80, 60, 80, 100, 60, 80, 100, 60, 80, 60, 100, 80, 60, 80, 60, 80],           "wave": "noise",  "volume": 0.35, "duration": 0.12, "octave_shift": 0},
			"bass":   {"notes": [C3, C3, B3, B3, As3, As3, A3, A3, Gs3, Gs3, G3, G3, Fs3, Fs3, F3, E3],        "wave": "saw",    "volume": 0.3,  "duration": 0.1,  "octave_shift": -1},
		}
	},
	# ═══ GLITCH ZONE — Digital, corrupted, unstable ═══
	"glitch_zone": {
		"source": "procedural", "tempo": 0.3, "volume_db": -12.0,
		"description": "Corrupted area — bitcrushed melody with glitchy artifacts",
		"voices": {
			"melody": {"notes": [E4, 0, G4, E4, 0, Ds4, E4, 0, B4, 0, A4, G4, 0, E4, 0, D4],                  "wave": "square",   "volume": 0.3,  "duration": 0.15, "octave_shift": 0},
			"bass":   {"notes": [E3, E3, 0, E3, Ds3, 0, E3, E3, B3, 0, A3, 0, G3, E3, 0, D3],                  "wave": "saw",      "volume": 0.25, "duration": 0.18, "octave_shift": -1},
			"glitch": {"notes": [0, 2000, 0, 0, 1500, 0, 0, 3000, 0, 1000, 0, 0, 2500, 0, 0, 1800],           "wave": "noise",    "volume": 0.08, "duration": 0.04, "octave_shift": 0},
			"pad":    {"notes": [E3, E3, E3, E3, D3, D3, D3, D3, C3, C3, C3, C3, D3, D3, D3, D3],              "wave": "triangle", "volume": 0.15, "duration": 0.6,  "octave_shift": 0},
		}
	},
	# ═══ IRONHOLD — Industrial, steampunk, mechanical ═══
	"ironhold": {
		"source": "procedural", "tempo": 0.35, "volume_db": -12.0,
		"description": "Ironhold city — industrial steampunk march with gears",
		"voices": {
			"melody": {"notes": [D4, F4, A4, D5, C5, A4, As4, A4, F4, G4, A4, C5, D5, C5, A4, F4],            "wave": "triangle", "volume": 0.45, "duration": 0.2,  "octave_shift": 0},
			"bass":   {"notes": [D3, D3, F3, F3, As3, As3, A3, A3, D3, D3, G3, G3, A3, A3, D3, D3],            "wave": "saw",      "volume": 0.3,  "duration": 0.25, "octave_shift": -1},
			"gear":   {"notes": [0, 300, 0, 150, 300, 0, 150, 0, 300, 0, 150, 300, 0, 150, 0, 300],            "wave": "noise",    "volume": 0.1,  "duration": 0.05, "octave_shift": 0},
			"pad":    {"notes": [D3, D3, D3, D3, As3, As3, As3, As3, G3, G3, G3, G3, A3, A3, A3, A3],          "wave": "sine",     "volume": 0.15, "duration": 0.6,  "octave_shift": 0},
		}
	},
	# ═══ UNDERGROUND — Dark, suspenseful, sneaky ═══
	"underground": {
		"source": "procedural", "tempo": 0.45, "volume_db": -14.0,
		"description": "Underground network — stealthy ambient with dripping echoes",
		"voices": {
			"melody": {"notes": [E4, 0, 0, G4, 0, 0, A4, 0, E4, 0, 0, D4, 0, 0, C4, 0],                      "wave": "sine",     "volume": 0.35, "duration": 0.3,  "octave_shift": 0},
			"drip":   {"notes": [0, 0, C5, 0, 0, 0, E5, 0, 0, 0, 0, G5, 0, 0, D5, 0],                         "wave": "sine",     "volume": 0.2,  "duration": 0.12, "octave_shift": 0},
			"drone":  {"notes": [E3, E3, E3, E3, E3, E3, E3, E3, E3, E3, E3, E3, E3, E3, E3, E3],              "wave": "triangle", "volume": 0.15, "duration": 1.0,  "octave_shift": -1},
		}
	},
	# ═══ CLOCK TOWER — Ticking, mechanical, puzzle ═══
	"clock_tower": {
		"source": "procedural", "tempo": 0.4, "volume_db": -13.0,
		"description": "Clock tower — precise ticking rhythm with music box melody",
		"voices": {
			"melody": {"notes": [G4, B4, D5, G5, D5, B4, G4, A4, B4, D5, G5, Fs5, E5, D5, B4, G4],            "wave": "sine",     "volume": 0.45, "duration": 0.2,  "octave_shift": 0},
			"tick":   {"notes": [800, 400, 800, 400, 800, 400, 800, 400, 800, 400, 800, 400, 800, 400, 800, 400], "wave": "noise", "volume": 0.12, "duration": 0.03, "octave_shift": 0},
			"chime":  {"notes": [0, 0, 0, G5, 0, 0, 0, 0, 0, 0, 0, D5, 0, 0, 0, 0],                            "wave": "sine",     "volume": 0.2,  "duration": 0.5,  "octave_shift": 0},
			"bass":   {"notes": [G3, G3, G3, G3, D3, D3, D3, D3, E3, E3, E3, E3, D3, D3, D3, D3],              "wave": "sine",     "volume": 0.18, "duration": 0.5,  "octave_shift": 0},
		}
	},
	# ═══ ARENA — Energetic, competitive ═══
	"arena": {
		"source": "procedural", "tempo": 0.22, "volume_db": -10.0,
		"description": "Arena district — pumping competitive battle music",
		"voices": {
			"melody": {"notes": [A4, C5, E5, A4, D5, C5, A4, G4, A4, B4, C5, E5, D5, C5, B4, A4],             "wave": "square",   "volume": 0.38, "duration": 0.12, "octave_shift": 0},
			"bass":   {"notes": [A3, A3, A3, E3, D3, D3, A3, A3, A3, A3, E3, E3, G3, G3, A3, A3],              "wave": "saw",      "volume": 0.32, "duration": 0.15, "octave_shift": -1},
			"drums":  {"notes": [250, 0, 100, 250, 0, 250, 100, 0, 250, 0, 100, 250, 100, 250, 0, 250],        "wave": "noise",    "volume": 0.25, "duration": 0.05, "octave_shift": 0},
			"crowd":  {"notes": [300, 300, 0, 0, 300, 300, 0, 0, 300, 300, 0, 0, 300, 300, 300, 0],            "wave": "noise",    "volume": 0.06, "duration": 0.2,  "octave_shift": 0},
		}
	},
	# ═══ SHOP — Cozy, warm, friendly ═══
	"shop": {
		"source": "procedural", "tempo": 0.5, "volume_db": -15.0,
		"description": "Cozy shop — warm gentle melody with wind chime",
		"voices": {
			"melody":  {"notes": [G4, A4, B4, D5, B4, G4, A4, G4, E4, G4, A4, B4, D5, C5, B4, A4],            "wave": "sine",     "volume": 0.45, "duration": 0.25, "octave_shift": 0},
			"harmony": {"notes": [D4, E4, G4, A4, G4, D4, E4, D4, C4, D4, E4, G4, A4, G4, G4, E4],            "wave": "triangle", "volume": 0.2,  "duration": 0.22, "octave_shift": 0},
			"bass":    {"notes": [G3, G3, G3, G3, E3, E3, E3, E3, C3, C3, C3, C3, D3, D3, D3, D3],             "wave": "sine",     "volume": 0.18, "duration": 0.6,  "octave_shift": 0},
		}
	},
	# ═══ MYSTERY — Discovery, wonder, revelation ═══
	"mystery": {
		"source": "procedural", "tempo": 0.55, "volume_db": -13.0,
		"description": "Mystery revelation — ascending wonder with ethereal chords",
		"voices": {
			"melody":  {"notes": [C4, D4, E4, G4, A4, C5, D5, E5, C5, A4, G4, E4, D4, C4, D4, E4],            "wave": "sine",     "volume": 0.45, "duration": 0.3,  "octave_shift": 0},
			"shimmer": {"notes": [E5, G5, C5, E5, G5, A5, E5, G5, C5, E5, A5, G5, E5, C5, E5, G5],            "wave": "sine",     "volume": 0.15, "duration": 0.18, "octave_shift": 0},
			"pad":     {"notes": [C3, C3, C3, C3, F3, F3, F3, F3, G3, G3, G3, G3, C3, C3, C3, C3],             "wave": "triangle", "volume": 0.18, "duration": 0.8,  "octave_shift": 0},
		}
	},
	# ═══ SADNESS — Emotional, heartfelt ═══
	"sadness": {
		"source": "procedural", "tempo": 0.6, "volume_db": -14.0,
		"description": "Emotional sadness — minor key piano-like melody",
		"voices": {
			"melody":  {"notes": [A4, E4, C4, A3, B3, C4, E4, D4, C4, B3, A3, E3, A3, B3, C4, A3],            "wave": "sine",     "volume": 0.5,  "duration": 0.35, "octave_shift": 0},
			"harmony": {"notes": [C4, A3, E3, C3, D3, E3, A3, G3, E3, D3, C3, A3, C3, D3, E3, C3],            "wave": "triangle", "volume": 0.2,  "duration": 0.3,  "octave_shift": 0},
			"bass":    {"notes": [A3, A3, A3, A3, E3, E3, E3, E3, F3, F3, F3, F3, E3, E3, E3, E3],             "wave": "sine",     "volume": 0.15, "duration": 0.8,  "octave_shift": -1},
		}
	},
	# ═══ TENSION — Building dread, pre-boss ═══
	"tension": {
		"source": "procedural", "tempo": 0.35, "volume_db": -12.0,
		"description": "Building tension — rising dissonance before a major encounter",
		"voices": {
			"drone":     {"notes": [E3, E3, F3, F3, E3, E3, F3, F3, E3, E3, Fs3, Fs3, E3, E3, G3, G3],        "wave": "saw",      "volume": 0.2,  "duration": 0.4,  "octave_shift": -1},
			"pulse":     {"notes": [E4, 0, E4, 0, F4, 0, F4, 0, E4, 0, E4, 0, Fs4, 0, G4, 0],                 "wave": "square",   "volume": 0.15, "duration": 0.1,  "octave_shift": 0},
			"heartbeat": {"notes": [100, 0, 80, 0, 0, 0, 100, 0, 80, 0, 0, 0, 100, 0, 80, 0],                 "wave": "noise",    "volume": 0.2,  "duration": 0.08, "octave_shift": 0},
		}
	},
	# ═══ FRACTURED WASTES — Desolate, alien, broken ═══
	"fractured_wastes": {
		"source": "procedural", "tempo": 0.5, "volume_db": -13.0,
		"description": "Fractured wastes — desolate glitched landscape ambience",
		"voices": {
			"melody": {"notes": [Ds4, 0, Gs4, 0, Cs4, 0, Ds4, 0, Fs4, 0, Cs4, 0, Ds4, 0, 0, 0],              "wave": "triangle", "volume": 0.35, "duration": 0.3,  "octave_shift": 0},
			"wind":   {"notes": [200, 150, 180, 200, 160, 140, 180, 200, 150, 170, 190, 200, 160, 150, 180, 170], "wave": "noise", "volume": 0.1,  "duration": 0.4,  "octave_shift": 0},
			"ghost":  {"notes": [0, 0, Gs4, 0, 0, 0, 0, Cs5, 0, 0, Ds5, 0, 0, 0, Gs4, 0],                     "wave": "sine",     "volume": 0.12, "duration": 0.5,  "octave_shift": 0},
			"bass":   {"notes": [Cs3, Cs3, Cs3, Cs3, Ds3, Ds3, Ds3, Ds3, Fs3, Fs3, Fs3, Fs3, Cs3, Cs3, Cs3, Cs3], "wave": "sine", "volume": 0.15, "duration": 0.7,  "octave_shift": -1},
		}
	},
	# ═══ DATA STREAM — Digital, flowing, electric ═══
	"data_stream": {
		"source": "procedural", "tempo": 0.25, "volume_db": -12.0,
		"description": "Data stream — electronic pulses flowing through digital space",
		"voices": {
			"arp":     {"notes": [C4, E4, G4, C5, E5, C5, G4, E4, D4, F4, A4, D5, F5, D5, A4, F4],            "wave": "square",   "volume": 0.25, "duration": 0.1,  "octave_shift": 0},
			"bass":    {"notes": [C3, C3, C3, C3, D3, D3, D3, D3, E3, E3, E3, E3, D3, D3, D3, D3],             "wave": "saw",      "volume": 0.25, "duration": 0.2,  "octave_shift": -1},
			"pulse":   {"notes": [C5, 0, G5, 0, E5, 0, C5, 0, D5, 0, A5, 0, F5, 0, D5, 0],                    "wave": "sine",     "volume": 0.18, "duration": 0.08, "octave_shift": 0},
			"digital": {"notes": [1000, 0, 1500, 0, 800, 0, 1200, 0, 1000, 0, 1800, 0, 900, 0, 1100, 0],      "wave": "noise",    "volume": 0.06, "duration": 0.03, "octave_shift": 0},
		}
	},
	# ═══ CUTSCENE EMOTIONAL — Story climax moments ═══
	"cutscene_emotional": {
		"source": "procedural", "tempo": 0.55, "volume_db": -12.0,
		"description": "Emotional cutscene — sweeping strings-like pads with rising melody",
		"voices": {
			"melody":  {"notes": [E4, G4, A4, B4, C5, D5, E5, D5, C5, B4, A4, G4, A4, B4, C5, E5],            "wave": "sine",     "volume": 0.5,  "duration": 0.35, "octave_shift": 0},
			"strings": {"notes": [C4, C4, D4, D4, E4, E4, G4, G4, A4, A4, G4, G4, E4, E4, C4, C4],            "wave": "triangle", "volume": 0.25, "duration": 0.5,  "octave_shift": 0},
			"bass":    {"notes": [A3, A3, A3, A3, C3, C3, C3, C3, E3, E3, E3, E3, A3, A3, A3, A3],             "wave": "sine",     "volume": 0.2,  "duration": 0.7,  "octave_shift": 0},
		}
	},
	# ═══ SERAPHINA THEME — Fierce, proud, powerful ═══
	"seraphina_theme": {
		"source": "procedural", "tempo": 0.3, "volume_db": -11.0,
		"description": "Seraphina's theme — fierce warrior melody with powerful presence",
		"voices": {
			"melody": {"notes": [A4, C5, D5, E5, D5, C5, A4, G4, A4, C5, E5, G5, E5, D5, C5, A4],             "wave": "triangle", "volume": 0.5,  "duration": 0.2,  "octave_shift": 0},
			"power":  {"notes": [A3, A3, C4, C4, D4, D4, E4, E4, A3, A3, C4, C4, E4, D4, C4, A3],             "wave": "saw",      "volume": 0.2,  "duration": 0.18, "octave_shift": 0},
			"bass":   {"notes": [A3, A3, F3, F3, D3, D3, E3, E3, A3, A3, F3, F3, E3, E3, A3, A3],              "wave": "sine",     "volume": 0.25, "duration": 0.35, "octave_shift": -1},
		}
	},
	# ═══ ADMINISTRATOR — Dark authority, oppressive ═══
	"administrator": {
		"source": "procedural", "tempo": 0.3, "volume_db": -10.0,
		"description": "Administrator — oppressive authoritative power theme",
		"voices": {
			"melody":    {"notes": [E4, 0, E4, Ds4, 0, E4, G4, 0, E4, 0, Ds4, E4, 0, B4, 0, E4],              "wave": "square",   "volume": 0.35, "duration": 0.15, "octave_shift": 0},
			"bass":      {"notes": [E3, E3, E3, E3, Ds3, Ds3, Ds3, Ds3, C3, C3, C3, C3, B3, B3, E3, E3],      "wave": "saw",      "volume": 0.35, "duration": 0.25, "octave_shift": -1},
			"authority": {"notes": [0, 0, B4, 0, 0, 0, E5, 0, 0, 0, B4, 0, 0, 0, G4, 0],                      "wave": "square",   "volume": 0.15, "duration": 0.1,  "octave_shift": 0},
			"pad":       {"notes": [E3, E3, E3, E3, Ds3, Ds3, Ds3, Ds3, C3, C3, C3, C3, E3, E3, E3, E3],      "wave": "triangle", "volume": 0.15, "duration": 0.6,  "octave_shift": 0},
		}
	},
	# ═══ ELARA THEME — Warm, kind, magical ═══
	"elara_theme": {
		"source": "procedural", "tempo": 0.45, "volume_db": -13.0,
		"description": "Elara's theme — warm magical melody with gentle sparkle",
		"voices": {
			"melody":  {"notes": [G4, A4, B4, D5, E5, D5, B4, A4, G4, B4, D5, E5, G5, E5, D5, B4],            "wave": "sine",     "volume": 0.5,  "duration": 0.28, "octave_shift": 0},
			"sparkle": {"notes": [0, D5, 0, G5, 0, B5, 0, D5, 0, E5, 0, G5, 0, B5, 0, D5],                    "wave": "sine",     "volume": 0.15, "duration": 0.12, "octave_shift": 0},
			"pad":     {"notes": [G3, G3, G3, G3, D3, D3, D3, D3, E3, E3, E3, E3, D3, D3, D3, D3],             "wave": "triangle", "volume": 0.18, "duration": 0.7,  "octave_shift": 0},
		}
	},
	# ═══ TITLE SCREEN — Grand, sweeping, epic reveal ═══
	"title_reveal": {
		"source": "procedural", "tempo": 0.4, "volume_db": -10.0,
		"description": "Title reveal — grand sweeping theme for game introduction",
		"voices": {
			"melody":  {"notes": [E4, G4, B4, E5, G5, E5, B4, G4, A4, C5, E5, A5, E5, C5, A4, E4],            "wave": "triangle", "volume": 0.5,  "duration": 0.3,  "octave_shift": 0},
			"harmony": {"notes": [B3, D4, G4, B4, D4, B3, G3, D4, E4, G4, C5, E5, C5, G4, E4, C4],            "wave": "sine",     "volume": 0.3,  "duration": 0.28, "octave_shift": 0},
			"bass":    {"notes": [E3, E3, E3, E3, E3, E3, G3, G3, A3, A3, A3, A3, A3, A3, E3, E3],             "wave": "sine",     "volume": 0.25, "duration": 0.5,  "octave_shift": -1},
			"chime":   {"notes": [0, 0, 0, E5, 0, 0, 0, 0, 0, 0, 0, A5, 0, 0, 0, 0],                          "wave": "sine",     "volume": 0.12, "duration": 0.4,  "octave_shift": 0},
		}
	},
	# ═══ AMBIENT — Atmospheric drone for wasteland / exploration ═══
	"ambient": {
		"source": "procedural", "tempo": 0.25, "volume_db": -14.0,
		"description": "Ambient — low drone with sparse tones for desolate areas",
		"voices": {
			"drone":   {"notes": [C3, C3, C3, C3, D3, D3, C3, C3, C3, C3, C3, C3, D3, D3, C3, C3],             "wave": "sine",     "volume": 0.2,  "duration": 1.2,  "octave_shift": -1},
			"pad":     {"notes": [E4, 0, 0, G4, 0, 0, E4, 0, D4, 0, 0, 0, E4, 0, 0, 0],                       "wave": "sine",     "volume": 0.12, "duration": 0.8,  "octave_shift": 0},
			"texture": {"notes": [0, 0, G5, 0, 0, 0, 0, 0, 0, 0, E5, 0, 0, 0, 0, 0],                          "wave": "triangle", "volume": 0.08, "duration": 0.5,  "octave_shift": 0},
		}
	},
}

# ─── STATE ───────────────────────────────────────────────────────────────

var _current_track = ""
var _music_player: AudioStreamPlayer = null
var _music_volume = DEFAULT_MUSIC_VOLUME
var _sfx_volume = DEFAULT_SFX_VOLUME
var _is_playing = false
var _procedural_timer = 0.0
var _procedural_note_index = 0
var _procedural_active = false
var _fade_tween: Tween = null
var _stopping = false  ## A fade-out is running; its callback will _force_stop()

## Multi-voice bookkeeping: voice_name → current note index / timer
var _voice_note_indices: Dictionary = {}
var _voice_timers: Dictionary = {}

# ─── LIFECYCLE ───────────────────────────────────────────────────────────

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_music_player = AudioStreamPlayer.new()
	_music_player.name = "MusicPlayer"
	_music_player.bus = "Master"
	add_child(_music_player)
	_load_volume_settings()
	_setup_dynamic_music()


func _process(delta: float) -> void:
	if _procedural_active and _is_playing:
		_update_procedural_music(delta)
	if _dynamic_music_enabled:
		_dynamic_music_timer -= delta
		if _dynamic_music_timer <= 0.0:
			_dynamic_music_timer = DYNAMIC_CHECK_INTERVAL
			_update_dynamic_music()


# ─── DYNAMIC MUSIC SYSTEM ────────────────────────────────────────────────
## Automatically transitions music based on game state and region.
## Respects manual overrides: if a scene explicitly calls play_track(),
## the dynamic system waits until a state change to reassert.

const DYNAMIC_CHECK_INTERVAL: float = 1.0  # Check every second

var _dynamic_music_enabled: bool = true
var _dynamic_music_timer: float = 0.0
var _dynamic_override: bool = false  # True when scene explicitly set a track
var _last_game_state: int = -1
var _last_region: String = ""

# Region → Track mapping
const REGION_TRACKS: Dictionary = {
	"oakhaven": "exploration",
	"ironhold": "ironhold",
	"fractured_wastes": "fractured_wastes",
	"ironhold_underground": "underground",
	"ironhold_clock_tower": "ironhold",
	"ironhold_city": "ironhold",
	"ironhold_outskirts": "ironhold",
	"oakhaven_village": "exploration",
	"oakhaven_outskirts": "exploration",
	"oakhaven_forest": "exploration",
	"wasteland_core": "fractured_wastes",
	"wasteland_storm": "glitch_zone",
	"wasteland_void": "fractured_wastes",
}

# Combat intensity thresholds (based on combo count)
const COMBAT_INTENSE_COMBO: int = 10

func _setup_dynamic_music() -> void:
	# Connect to GameManager state changes if available
	if has_node("/root/GameManager"):
		if GameManager.has_signal("state_changed"):
			GameManager.state_changed.connect(_on_game_state_changed)

func _on_game_state_changed(new_state: int) -> void:
	_dynamic_override = false  # Reset override on state change
	_update_dynamic_music()

func _update_dynamic_music() -> void:
	if not has_node("/root/GameManager"):
		return
	if _dynamic_override:
		return

	var state = GameManager.current_state if "current_state" in GameManager else -1

	# Combat states
	if state == GameManager.GameState.COMBAT:
		var is_boss = GameManager.get("boss_fight_active")
		if is_boss:
			# Boss fight: check rage phase
			var boss_hp_ratio = _get_boss_hp_ratio()
			if boss_hp_ratio < 0.3:
				_dynamic_play("boss_rage")
			else:
				_dynamic_play("boss_fight")
		else:
			# Regular combat: check intensity
			var combo = 0
			if has_node("/root/GameJuice"):
				combo = GameJuice.get_combo_count()
			if combo >= COMBAT_INTENSE_COMBO:
				_dynamic_play("combat_intense")
			else:
				_dynamic_play("combat")
		return

	# Dialogue: soft ambient
	if state == GameManager.GameState.DIALOGUE:
		# Don't change music during short dialogue — only for cutscenes
		return

	# Exploration: region-based music
	if state == GameManager.GameState.EXPLORATION:
		var region = _get_current_region()
		if REGION_TRACKS.has(region):
			_dynamic_play(REGION_TRACKS[region])
		elif _current_track.is_empty() or _current_track == "combat" or _current_track == "combat_intense" or _current_track == "boss_fight" or _current_track == "boss_rage":
			_dynamic_play("exploration")

func _dynamic_play(track_name: String) -> void:
	if track_name == _current_track and _is_playing:
		return
	if TRACKS.has(track_name):
		play_track(track_name)

func _get_current_region() -> String:
	if has_node("/root/RandomEncounterSystem"):
		return RandomEncounterSystem.current_zone_id
	return ""

func _get_boss_hp_ratio() -> float:
	# Try to find the boss in the current scene
	var tree = get_tree()
	if not tree or not tree.current_scene:
		return 1.0
	var bosses = tree.get_nodes_in_group("boss")
	if bosses.is_empty():
		return 1.0
	var boss = bosses[0]
	# EnemyBase stores HP in current_health (there is no `health` property).
	if "current_health" in boss and "max_health" in boss and float(boss.max_health) > 0.0:
		return float(boss.current_health) / float(boss.max_health)
	return 1.0

## Disable dynamic music (for scenes that manage their own music)
func disable_dynamic_music() -> void:
	_dynamic_music_enabled = false

## Re-enable dynamic music
func enable_dynamic_music() -> void:
	_dynamic_music_enabled = true
	_dynamic_override = false

## Set a manual override (used when play_track is called explicitly by scenes)
func set_dynamic_override(enabled: bool = true) -> void:
	_dynamic_override = enabled

# ─── PUBLIC API ──────────────────────────────────────────────────────────

## Play a named music track. Crossfades if already playing something else.
func play_track(track_name: String, fade_in: bool = true) -> void:
	if track_name == _current_track and _is_playing and not _stopping:
		return
	if not TRACKS.has(track_name):
		push_warning("MusicManager: Unknown track '%s'" % track_name)
		return
	# Cancel a pending fade-out, or its _force_stop callback silences this track.
	if _stopping and _fade_tween:
		_fade_tween.kill()
	_stopping = false

	var track: Dictionary = TRACKS[track_name]
	_current_track = track_name

	if track.get("source", "") == "file" and track.has("path"):
		_play_file_track(track, fade_in)
	else:
		_start_procedural_track(track, fade_in)


## Stop the current track with optional fade-out.
func stop(fade_out: bool = true) -> void:
	if not _is_playing:
		return
	if fade_out:
		_fade_out_and_stop()
	else:
		_force_stop()


## Set music volume (0.0 – 1.0) and persist to disk.
func set_music_volume(vol: float) -> void:
	_music_volume = clampf(vol, 0.0, 1.0)
	_apply_music_volume()
	_save_volume_settings()


## Set SFX volume (0.0 – 1.0) and persist to disk.
func set_sfx_volume(vol: float) -> void:
	_sfx_volume = clampf(vol, 0.0, 1.0)
	var bus_idx = AudioServer.get_bus_index("SFX")
	if bus_idx >= 0:
		var db = linear_to_db(_sfx_volume) if _sfx_volume > 0.0 else -80.0
		AudioServer.set_bus_volume_db(bus_idx, db)
	_save_volume_settings()


## Returns the current music volume (0.0 – 1.0).
func get_music_volume() -> float:
	return _music_volume


## Returns the current SFX volume (0.0 – 1.0).
func get_sfx_volume() -> float:
	return _sfx_volume


## Returns the current track name, or "" if nothing is playing.
func get_current_track() -> String:
	return _current_track


## True when a track is actively playing.
func is_playing() -> bool:
	return _is_playing


## Returns all available track names as an Array of Strings.
func get_track_list() -> Array[String]:
	var names: Array[String] = []
	for k: String in TRACKS.keys():
		names.append(k)
	return names

# ─── FILE PLAYBACK ──────────────────────────────────────────────────────

func _play_file_track(track: Dictionary, fade_in: bool) -> void:
	_procedural_active = false
	var stream: AudioStream = load(track.path) as AudioStream
	if stream == null:
		push_warning("MusicManager: Could not load '%s'" % track.path)
		return

	_music_player.stream = stream
	var target_db: float = track.get("volume_db", -10.0)
	_music_player.volume_db = -40.0 if fade_in else target_db + _volume_to_db_offset()
	_music_player.play()
	_is_playing = true

	if fade_in:
		if _fade_tween:
			_fade_tween.kill()
		_fade_tween = create_tween()
		_fade_tween.tween_property(
			_music_player, "volume_db",
			target_db + _volume_to_db_offset(), FADE_DURATION
		)

# ─── PROCEDURAL MULTI-VOICE ENGINE ──────────────────────────────────────

func _start_procedural_track(track: Dictionary, _fade_in: bool) -> void:
	# BUG 1+6 FIX: Stop file-based playback and crossfade stale note players
	if _music_player and _music_player.playing:
		_music_player.stop()
	# Pass 53: Crossfade existing procedural notes instead of instant kill
	if _procedural_active:
		for child in get_children():
			if child is AudioStreamPlayer and child != _music_player:
				var tw = child.create_tween()
				tw.tween_property(child, "volume_db", -40.0, FADE_DURATION * 0.4)
				tw.tween_callback(child.queue_free)
	else:
		for child in get_children():
			if child is AudioStreamPlayer and child != _music_player:
				child.stop()
				child.queue_free()
	_procedural_active = true
	_procedural_note_index = 0
	_procedural_timer = 0.0
	_is_playing = true
	_voice_note_indices.clear()
	_voice_timers.clear()
	if track.has("voices"):
		for voice_name: String in track.voices:
			_voice_note_indices[voice_name] = 0
			_voice_timers[voice_name] = 0.0


func _update_procedural_music(delta: float) -> void:
	if _current_track.is_empty() or not TRACKS.has(_current_track):
		return
	var track: Dictionary = TRACKS[_current_track]
	var tempo: float = track.get("tempo", 0.5)

	if track.has("voices"):
		for voice_name: String in track.voices:
			var voice: Dictionary = track.voices[voice_name]
			var voice_tempo: float = voice.get("tempo_mult", 1.0) * tempo
			if not _voice_timers.has(voice_name):
				_voice_timers[voice_name] = 0.0
				_voice_note_indices[voice_name] = 0

			_voice_timers[voice_name] += delta
			if _voice_timers[voice_name] >= voice_tempo:
				_voice_timers[voice_name] -= voice_tempo
				var notes: Array = voice.notes
				var idx: int = _voice_note_indices.get(voice_name, 0)
				var freq: float = float(notes[idx])
				if freq > 0.0:
					var vol_mult: float = voice.get("volume", 0.5)
					var wave_type: String = voice.get("wave", "sine")
					var dur: float = voice.get("duration", 0.2)
					var octave: int = voice.get("octave_shift", 0)
					if octave != 0:
						freq *= pow(2.0, float(octave))
					_play_voice_note(freq, track.get("volume_db", -10.0), vol_mult, wave_type, dur)
				_voice_note_indices[voice_name] = (idx + 1) % notes.size()
	else:
		# Legacy single-voice fallback
		var notes: Array = track.get("notes", [])
		if notes.is_empty():
			return
		_procedural_timer += delta
		if _procedural_timer >= tempo:
			_procedural_timer -= tempo
			var freq: float = float(notes[_procedural_note_index])
			if freq > 0.0:
				_play_voice_note(freq, track.get("volume_db", -10.0), 0.5, "sine", 0.15)
			_procedural_note_index = (_procedural_note_index + 1) % notes.size()


## Generate and play a single waveform note with harmonics.
func _play_voice_note(frequency: float, base_volume_db: float, vol_mult: float, wave_type: String, duration: float) -> void:
	var num_samples = int(SAMPLE_RATE * duration)
	if num_samples < 1:
		return

	# Cap concurrent note players to prevent audio pile-up
	var active = 0
	for child: Node in get_children():
		if child is AudioStreamPlayer and child != _music_player:
			active += 1
	if active >= MAX_CONCURRENT_NOTES:
		return

	# Pass 55 H-01: Check note cache before generating PCM data
	var cache_key = "%s_%.1f_%.2f" % [wave_type, frequency, duration]
	var audio: AudioStreamWAV
	if _note_cache.has(cache_key):
		audio = _note_cache[cache_key]
	else:
		audio = _generate_note_pcm(frequency, wave_type, duration, num_samples)
		if _note_cache.size() >= MAX_NOTE_CACHE_SIZE:
			var first_key = _note_cache.keys()[0]
			_note_cache.erase(first_key)
		_note_cache[cache_key] = audio

	var vol_db_offset: float = base_volume_db + linear_to_db(maxf(_music_volume * vol_mult, 0.001))

	var note_player = AudioStreamPlayer.new()
	note_player.stream = audio
	note_player.volume_db = vol_db_offset  # Pass 55: Apply volume via player, not baked into PCM
	add_child(note_player)
	note_player.play()
	note_player.finished.connect(note_player.queue_free)


## Pass 55 H-01: Extracted note PCM generation for caching (envelope-only, no volume baked).
func _generate_note_pcm(frequency: float, wave_type: String, _duration: float, num_samples: int) -> AudioStreamWAV:
	var audio = AudioStreamWAV.new()
	audio.mix_rate = SAMPLE_RATE
	audio.format = AudioStreamWAV.FORMAT_16_BITS
	audio.stereo = false

	var data = PackedByteArray()
	data.resize(num_samples * 2)

	var phase = 0.0
	for i: int in range(num_samples):
		var t: float = float(i) / float(SAMPLE_RATE)
		var t_norm: float = float(i) / float(num_samples)

		var envelope: float
		var attack_t = 0.02
		var release_start = 0.6
		if t < attack_t:
			envelope = t / attack_t
		elif t_norm < release_start:
			envelope = 1.0
		else:
			envelope = maxf(0.0, 1.0 - (t_norm - release_start) / (1.0 - release_start))
		envelope *= envelope

		var sample = 0.0
		match wave_type:
			"sine":
				sample = sin(TAU * frequency * t) * 0.75
				sample += sin(TAU * frequency * 2.0 * t) * 0.18
				sample += sin(TAU * frequency * 3.0 * t) * 0.07
			"triangle":
				var p = fmod(phase, 1.0)
				sample = (4.0 * absf(p - 0.5) - 1.0) * 0.8
				sample += sin(TAU * frequency * t) * 0.2
			"square":
				sample = (0.95 if fmod(phase, 1.0) < 0.5 else -0.95) * 0.5
				sample += sin(TAU * frequency * t) * 0.3
				sample += sin(TAU * frequency * 3.0 * t) * 0.15
				sample += sin(TAU * frequency * 5.0 * t) * 0.05
			"saw":
				var p = fmod(phase, 1.0)
				sample = (2.0 * p - 1.0) * 0.5
				sample += sin(TAU * frequency * t) * 0.3
				sample += sin(TAU * frequency * 2.0 * t) * 0.15
			"noise":
				sample = randf_range(-1.0, 1.0) * 0.5
			_:
				sample = sin(TAU * frequency * t)

		phase += frequency / float(SAMPLE_RATE)
		if phase > 1.0:
			phase -= 1.0

		sample *= envelope
		var sample_int = clampi(int(sample * 32767.0), -32768, 32767)
		data[i * 2] = sample_int & 0xFF
		data[i * 2 + 1] = (sample_int >> 8) & 0xFF

	audio.data = data
	return audio

# ─── FADE / VOLUME ──────────────────────────────────────────────────────

func _fade_out_and_stop() -> void:
	_procedural_active = false
	_stopping = true
	# Pass 53: Also fade out any lingering procedural note players
	for child in get_children():
		if child is AudioStreamPlayer and child != _music_player:
			var tw = child.create_tween()
			tw.tween_property(child, "volume_db", -40.0, FADE_DURATION * 0.5)
			tw.tween_callback(child.queue_free)
	if _fade_tween:
		_fade_tween.kill()
	_fade_tween = create_tween()
	_fade_tween.tween_property(_music_player, "volume_db", -40.0, FADE_DURATION)
	_fade_tween.tween_callback(_force_stop)


func _force_stop() -> void:
	_music_player.stop()
	_is_playing = false
	_stopping = false
	_procedural_active = false
	_current_track = ""
	_voice_note_indices.clear()
	_voice_timers.clear()


func _apply_music_volume() -> void:
	if _music_player == null or not _is_playing:
		return
	var base_db = -10.0
	if TRACKS.has(_current_track):
		base_db = TRACKS[_current_track].get("volume_db", -10.0)
	_music_player.volume_db = base_db + _volume_to_db_offset()


## Convert 0.0 – 1.0 slider value to a dB offset.
func _volume_to_db_offset() -> float:
	if _music_volume <= 0.01:
		return -80.0
	return linear_to_db(_music_volume)

# ─── SETTINGS PERSISTENCE ───────────────────────────────────────────────

func _save_volume_settings() -> void:
	var config = ConfigFile.new()
	var _err = config.load("user://audio_settings.cfg")
	config.set_value("audio", "music_volume", _music_volume)
	config.set_value("audio", "sfx_volume", _sfx_volume)
	config.save("user://audio_settings.cfg")


func _load_volume_settings() -> void:
	var config = ConfigFile.new()
	if config.load("user://audio_settings.cfg") == OK:
		_music_volume = config.get_value("audio", "music_volume", DEFAULT_MUSIC_VOLUME)
		_sfx_volume = config.get_value("audio", "sfx_volume", DEFAULT_SFX_VOLUME)
