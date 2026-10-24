"""Seam-only shim for the T11 watch-fail: adds the test hooks to the OLD code in the scratch worktree,
with no behaviour change, so the AC-2 / AC-5 checks measure the old behaviour instead of crashing."""
WT = "C:/Users/BHASKA~1/AppData/Local/Temp/claude/C--Users-BHASKAR-BAHUKHANDI-OneDrive-Desktop-Ultimate-project/38742c26-a8d5-4ddd-be96-9bff07452637/scratchpad/wt_t11_wf/AethelgardPrototype/"


def edit(p, old, new):
    raw = open(WT + p, "rb").read().decode("utf-8")
    nl = "\r\n" if "\r\n" in raw else "\n"
    s = raw.replace("\r\n", "\n")
    assert s.count(old) == 1, (p, old[:60])
    s = s.replace(old, new)
    open(WT + p, "wb").write(s.replace("\n", nl).encode("utf-8"))


# SFXManager: the signal, emitted first in play() (observation only)
edit("scripts/sfx_manager.gd", "# ─── CONSTANTS",
     "signal sfx_requested(sfx_name: String)  # T11 watch-fail shim\n\n# ─── CONSTANTS")
edit("scripts/sfx_manager.gd", "func play(sfx_name: String, pitch_variation: float = 0.0) -> void:\n",
     "func play(sfx_name: String, pitch_variation: float = 0.0) -> void:\n\tsfx_requested.emit(sfx_name)  # T11 watch-fail shim\n")

# CombatFX: the counter and flags the test reads; old guard and behaviour unchanged
edit("scripts/combat_effects.gd", "var is_hitstop_active: bool = false\n",
     "var is_hitstop_active: bool = false\n"
     "var last_kill_started_count := 0  # T11 watch-fail shim\n"
     "var _pending_last_kill := false  # T11 watch-fail shim (never set by old code)\n"
     "var _pending_last_kill_scene_id := 0  # T11 watch-fail shim\n")
edit("scripts/combat_effects.gd",
     "func apply_last_kill_slowdown() -> void:\n\t## Dramatic slowdown when the last enemy in a wave dies — bullet-time finish.\n"
     "\tif get_tree().paused or is_hitstop_active:\n\t\treturn\n",
     "func apply_last_kill_slowdown(_is_boss: bool = false) -> void:  # T11 shim: param ignored, old behaviour\n"
     "\t## Dramatic slowdown when the last enemy in a wave dies — bullet-time finish.\n"
     "\tif get_tree().paused or is_hitstop_active:\n\t\treturn\n"
     "\tlast_kill_started_count += 1  # T11 watch-fail shim\n")
print("ok")
