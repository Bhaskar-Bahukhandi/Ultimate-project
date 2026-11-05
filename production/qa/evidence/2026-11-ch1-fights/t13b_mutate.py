"""Y1-P0-T13b mutation harness: apply ONE mutation (one exact replacement, matched exactly once) to one file, run the
named suite on Godot 4.6.3, restore the file byte for byte, verify its SHA-256 and print the result.
Usage: python -I t13b_mutate.py <a..t> [tag]; with a tag the log is t13b_mutation_<id>_<tag>.log.
Modelled on production/qa/evidence/2026-11-td038/td038_mutate.py."""
import hashlib, io, subprocess, sys, os

ROOT = r"C:\Users\BHASKAR BAHUKHANDI\OneDrive\Desktop\Ultimate project"
PROJ = os.path.join(ROOT, "AethelgardPrototype")
EV = os.path.join(ROOT, "production", "qa", "evidence", "2026-11-ch1-fights")
GODOT = r"C:\Godot\Godot_v4.6.3-stable_win64_console.exe"
GUARDIAN = os.path.join(PROJ, "scripts", "combat", "enemies", "broken_mile_guardian.gd")
ARENA = os.path.join(PROJ, "scripts", "combat", "combat_arena.gd")
MILE = os.path.join(PROJ, "scripts", "chapter1", "ch1_path_to_oakhaven.gd")
G_SUITE = "res://tests/integration/combat/guardian_fight_test.gd"
R_SUITE = "res://tests/integration/story/chapter1_route_test.gd"

# id: (description, file, suite, expected catching check, old text, new text). Texts use "\n"; converted for CRLF files.
MUTATIONS = {
    "a": ("_choose_attack picks by randf() instead of distance", GUARDIAN, G_SUITE,
          "C1 the player at 50 px / 200 px: telegraph then SLAM / CHARGE",
          "return AttackType.SLAM if distance_to_player() <= STOMP_RANGE else AttackType.CHARGE",
          "return AttackType.SLAM if randf() < 0.5 else AttackType.CHARGE"),
    "b": ("the charge's telegraph left at EnemyBase's 0.55 s (not CHARGE_TELEGRAPH)", GUARDIAN, G_SUITE,
          "C1 the charge's telegraph is 0.6 s",
          "telegraph_duration = CHARGE_TELEGRAPH if current_attack == AttackType.CHARGE else STOMP_TELEGRAPH",
          "telegraph_duration = telegraph_duration if current_attack == AttackType.CHARGE else STOMP_TELEGRAPH"),
    "c": ("the stomp deals STOMP_DAMAGE * 1.6 (EnemyBase's SLAM factor) instead of STOMP_DAMAGE", GUARDIAN, G_SUITE,
          "C1 the stomp takes exactly 12 HP",
          "_deal_damage_in_attack_hitbox(STOMP_HITBOX_OFFSET, STOMP_HITBOX_SIZE, STOMP_DAMAGE, \"slam\")",
          "_deal_damage_in_attack_hitbox(STOMP_HITBOX_OFFSET, STOMP_HITBOX_SIZE, STOMP_DAMAGE * 1.6, \"slam\")"),
    "d": ("the filter choice hands off to the arena too (hand-off call before the turn-away)", MILE, G_SUITE,
          "C3 filter: no story meta and no scene change up to rest_stop",
          "\t\t\"filter\":\n\t\t\tawait _guardian_turns_away()",
          "\t\t\"filter\":\n\t\t\t_hand_off_to_guardian_fight()\n\t\t\tawait _guardian_turns_away()"),
    "e": ("the panel's give-up never fires (timeout branch disabled: the panel just keeps waiting)", MILE, G_SUITE,
          "C3 the give-up: ... at the hand-off / within 1.1 s",
          "if waited > root_panel_timeout and not guardian_resolved:",
          "if false and waited > root_panel_timeout and not guardian_resolved:"),
    "f": ("the resume check on ch1_guardian_fought in start_path_sequence disabled", MILE, G_SUITE,
          "C5 the first line shown is root_refused's first",
          "\tif GameManager.has_flag(\"ch1_guardian_fought\"):\n\t\tawait _resume_after_guardian_fight()",
          "\tif false and GameManager.has_flag(\"ch1_guardian_fought\"):\n\t\tawait _resume_after_guardian_fight()"),
    "g": ("the ch1_guardian row's flags left empty", ARENA, G_SUITE,
          "C4 ch1_guardian_fought is set",
          "\"flags\": [\"ch1_guardian_fought\"],",
          "\"flags\": [],"),
    "h": ("the old staging before the hand-off: 3 x (0.1 + 0.35 s) shake/flash, then the guardian faded out over 0.8 s"
          " (2.15 s)", MILE, G_SUITE,
          "C3 ...: the change to the arena starts within 0.5 s / the staged guardian is still fully visible",
          "\t_is_handing_off_to_fight = true\n",
          "\t_is_handing_off_to_fight = true\n"
          "\tfor i in 3:\n"
          "\t\tcamera.shake(6.0, 0.2)\n"
          "\t\tflash_overlay.color = Color(1, 1, 1, 0.4)\n"
          "\t\tflash_overlay.modulate.a = 0.5\n"
          "\t\tawait get_tree().create_timer(0.1, false).timeout\n"
          "\t\tif not is_inside_tree(): return\n"
          "\t\tflash_overlay.modulate.a = 0.0\n"
          "\t\tawait get_tree().create_timer(0.35, false).timeout\n"
          "\t\tif not is_inside_tree(): return\n"
          "\tif _guardian:\n"
          "\t\tvar t := create_tween()\n"
          "\t\tt.tween_property(_guardian, \"modulate:a\", 0.0, 0.8)\n"
          "\t\tawait t.finished\n"),
    "i": ("the _state_chase override reduced to calling super only", GUARDIAN, G_SUITE,
          "C1 the charge is telegraphed from range",
          "func _state_chase(delta: float) -> void:\n"
          "\tif find_player() and attack_cooldown <= 0.0 and distance_to_player() <= CHARGE_RANGE:\n"
          "\t\t_begin_telegraph()\n"
          "\t\treturn\n"
          "\tsuper._state_chase(delta)\n"
          "\tif current_state == State.CHASE and distance_to_player() < STANDOFF_DISTANCE:\n"
          "\t\tvelocity.x = 0.0\n",
          "func _state_chase(delta: float) -> void:\n"
          "\tsuper._state_chase(delta)\n"),
    "j": ("contact damage left at 8 (GUARDIAN_CONTACT_DAMAGE = 8.0)", GUARDIAN, G_SUITE,
          "C1 within 30 px of the guardian for 1.0 s ... HP unchanged",
          "const GUARDIAN_CONTACT_DAMAGE: float = 0.0",
          "const GUARDIAN_CONTACT_DAMAGE: float = 8.0"),
    "k": ("the arena's enemy.set(\"loot_table\", null) line replaced by pass", ARENA, G_SUITE,
          "C4 no item or gold pickup in the arena and the loot table is null",
          "\tenemy.set(\"loot_table\", null)\n",
          "\tpass\n"),
    "l": ("the guardian's _apply_hitstun override disabled (renamed, so EnemyBase's runs: poise gone)", GUARDIAN,
          G_SUITE, "C1 a hit during the telegraph ... does not stun it / the stomp still lands on time",
          "func _apply_hitstun(amount: float) -> void:",
          "func _apply_hitstun_removed(amount: float) -> void:"),
    "m": ("the Broken Mile sets ch1_guardian_fought itself (first line of _resume_after_guardian_fight)", MILE, R_SUITE,
          "the Broken Mile reads ch1_guardian_fought with has_flag and never sets it (_test_t13b_flag_registered)",
          "func _resume_after_guardian_fight() -> void:\n\tcamera.global_position = Vector2(640, 360)",
          "func _resume_after_guardian_fight() -> void:\n\tGameManager.set_story_flag(\"ch1_guardian_fought\", true)\n"
          "\tcamera.global_position = Vector2(640, 360)"),
    "n": ("the stomp also multiplies its damage by get_enemy_damage_multiplier() (applied twice)", GUARDIAN, G_SUITE,
          "C1 scaled (R3): the stomp takes raw x get_enemy_damage_multiplier()",
          "STOMP_HITBOX_SIZE, STOMP_DAMAGE, \"slam\")",
          "STOMP_HITBOX_SIZE, STOMP_DAMAGE * get_enemy_damage_multiplier(), \"slam\")"),
    "o": ("the telegraph not divided by the difficulty multiplier (0.25 s floor kept)", GUARDIAN, G_SUITE,
          "C1 scaled (R3): the stomp / charge telegraphs raw / difficulty multiplier",
          "telegraph_duration = maxf(telegraph_duration / GameManager.get_difficulty_multiplier(), 0.25)",
          "telegraph_duration = maxf(telegraph_duration, 0.25)"),
    "p": ("the charge's velocity not zeroed at its travel end (only when staggered, as before rev2)", GUARDIAN, G_SUITE,
          "C1 RECOVER after the charge adds no slide",
          "\tif _stun_active or _charge_elapsed >= CHARGE_TRAVEL_TIME:\n\t\tvelocity.x = 0.0\n",
          "\tif _stun_active or _charge_elapsed >= CHARGE_TRAVEL_TIME:\n"
          "\t\tif _stun_active:\n\t\t\tvelocity.x = 0.0\n"),
    "q": ("the cooldown raised after every hit-stun, not only one from RECOVER (R1 reverted)", GUARDIAN, G_SUITE,
          "C1 hit every 0.9 s while it walks in, it still starts a telegraph (R1)",
          "if not stuns or not from_recover or not is_inside_tree()",
          "if not stuns or not is_inside_tree()"),
    "r": ("the give-up fires even when a choice was applied during its last tick (R2 reverted)", MILE, G_SUITE,
          "C3 filter in the give-up's last tick: ...",
          "if waited > root_panel_timeout and not guardian_resolved:",
          "if waited > root_panel_timeout:"),
    "s": ("a die() override keeps the dead guardian's attack running (physics back on, state put back)", GUARDIAN,
          G_SUITE, "C4 the guardian killed mid-charge: the player's HP is unchanged after the kill",
          "## One attack, then RECOVER (no combo).\n",
          "func die() -> void:\n\tvar was: int = current_state\n\tsuper.die()\n\tset_physics_process(true)\n"
          "\tcurrent_state = was\n\n\n## One attack, then RECOVER (no combo).\n"),
    "t": ("Apply's guardian_resolved guard removed (a second click charges corruption again)", MILE, G_SUITE,
          "C3 filter in the give-up's last tick: corruption was added once",
          "\t# repeat clicks in that window used to charge corruption each time.\n"
          "\tif not root_access_tutorial_active or guardian_resolved:",
          "\t# repeat clicks in that window used to charge corruption each time.\n"
          "\tif not root_access_tutorial_active:"),
}


def main():
    mid = sys.argv[1]
    tag = ("_" + sys.argv[2]) if len(sys.argv) > 2 else ""
    desc, path, suite, case, old, new = MUTATIONS[mid]
    raw = io.open(path, "rb").read()
    digest = hashlib.sha256(raw).hexdigest()
    text = raw.decode("utf-8")
    crlf = "\r\n" in text
    o, n = (old.replace("\n", "\r\n"), new.replace("\n", "\r\n")) if crlf else (old, new)
    count = text.count(o)
    if count != 1:
        print(f"MUTATION {mid} NOT APPLIED: pattern found {count} times in {os.path.basename(path)}; file untouched")
        sys.exit(2)
    log = os.path.join(EV, f"t13b_mutation_{mid}{tag}.log")
    rel = os.path.relpath(path, PROJ)
    try:
        io.open(path, "wb").write(text.replace(o, n).encode("utf-8"))
        env = dict(os.environ, GODOT=GODOT)
        with io.open(log, "w", encoding="utf-8", newline="") as fh:
            fh.write(f"# T13b mutation ({mid}): {desc}\n# file: {rel} (sha256 before {digest}, crlf {crlf})\n"
                     f"# suite: {suite}\n# expected to be caught by: {case}\n")
            fh.flush()
            # No Python timeout: the runner enforces the suite's own limit from tests/suite_limits.txt.
            proc = subprocess.run(["powershell", "-NoProfile", "-File", "tests/run_phase0_tests.ps1", "-Script", suite],
                                  cwd=PROJ, env=env, stdout=fh, stderr=subprocess.STDOUT)
        rc = proc.returncode
    finally:
        io.open(path, "wb").write(raw)
    after = hashlib.sha256(io.open(path, "rb").read()).hexdigest()
    restored = after == digest
    with io.open(log, "a", encoding="utf-8", newline="") as fh:
        fh.write(f"# restore: sha256 after {after}, matches before: {restored}\n")
    lines = io.open(log, encoding="utf-8", errors="replace").read().splitlines()
    result = [l for l in lines if " RESULT:" in l and l[:1].isupper()]
    fails = [l.strip() for l in lines if l.strip().startswith("FAIL:")]
    runner = [l.strip() for l in lines if l.startswith("RUNNER ")]
    errs = sum(1 for l in lines if "SCRIPT" + " ERROR" in l or "Parse" + " Error" in l)
    print(f"mutation {mid} ({desc}) file={rel} exit={rc}")
    print(f"  sha256 before={digest}")
    print(f"  sha256 after ={after} restored={restored}")
    print("  " + (result[-1] if result else "NO RESULT LINE"))
    print(f"  engine error lines in log: {errs}")
    for r in runner:
        print("  " + r.replace("script error", "s.e.").replace("SCRIPT", "S.").replace("Parse", "P."))
    seen = set()
    for f in fails:
        if f not in seen:
            seen.add(f)
            print("  " + f[:260])


main()
