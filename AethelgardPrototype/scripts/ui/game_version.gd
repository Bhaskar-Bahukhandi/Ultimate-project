class_name GameVersion
extends RefCounted
## The game's version, in one place. The number lives in project.godot (`application/config/version`) and is baked
## into exported builds with the rest of the project settings; the menu label and the pause header both format it
## here, so the two cannot drift. In-fiction version text (splash "KERNEL v0.91", Chapter 3 safety_protocol_v1.0)
## is story text and does not use this.

## Shown when the setting is missing (the test compares with the real setting, so a fallback cannot pass for it).
const FALLBACK := "0.0.0"


## The bare version, e.g. "0.1.0".
static func number() -> String:
	return str(ProjectSettings.get_setting("application/config/version", FALLBACK))


## The player-facing form, e.g. "v0.1.0" (main menu).
static func label() -> String:
	return "v" + number()


## The pause screen header: "AETHELGARD IDE v0.1.0 — PAUSED", or "... — Chapter N" when `chapter` > 0.
static func ide_header(chapter: int = 0) -> String:
	var tail := "PAUSED" if chapter <= 0 else "Chapter %d" % chapter
	return "AETHELGARD IDE %s — %s" % [label(), tail]
