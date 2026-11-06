"""Y1-P0-T13c mutation harness: apply ONE mutation (one exact replacement, matched exactly once) to one file, run the
named suite on Godot 4.6.3, restore the file byte for byte, verify its SHA-256 and print the result.
Usage: python -I t13c_mutate.py <a..ac> [tag]; with a tag the log is t13c_mutation_<id>_<tag>.log.
       python -I t13c_mutate.py --check   (no Godot, no file written: every pattern must match exactly once)
Modelled on production/qa/evidence/2026-11-ch1-fights/t13b_mutate.py."""
import hashlib, io, subprocess, sys, os

ROOT = r"C:\Users\BHASKAR BAHUKHANDI\OneDrive\Desktop\Ultimate project"
PROJ = os.path.join(ROOT, "AethelgardPrototype")
EV = os.path.join(ROOT, "production", "qa", "evidence", "2026-11-ch1-fights")
GODOT = r"C:\Godot\Godot_v4.6.3-stable_win64_console.exe"
BOAR = os.path.join(PROJ, "scripts", "combat", "enemies", "field_boar.gd")
ARENA = os.path.join(PROJ, "scripts", "combat", "combat_arena.gd")
VILLAGE = os.path.join(PROJ, "scripts", "chapter1", "ch1_oakhaven_village.gd")
B_SUITE = "res://tests/integration/combat/boar_fight_test.gd"
R_SUITE = "res://tests/integration/story/chapter1_route_test.gd"

# id: (description, file, suite, expected catching check, old text, new text). Texts use "\n"; converted for CRLF files.
MUTATIONS = {
    "a": ("the charge turns toward the player mid-run (_charge_dir re-read every frame)", BOAR, B_SUITE,
          "C1 the charge keeps its launch direction when the player crosses behind it",
          "\t_charge_elapsed += delta\n\tvelocity.x = _charge_dir * CHARGE_SPEED\n",
          "\t_charge_elapsed += delta\n\t_charge_dir = _side(direction_to_player())\n"
          "\tvelocity.x = _charge_dir * CHARGE_SPEED\n"),
    "b": ("the telegraph left at EnemyBase's 0.55 s (the CHARGE_TELEGRAPH assignment removed)", BOAR, B_SUITE,
          "C1 the player near: telegraph then CHARGE, 0.6 s +- one frame",
          "\tsuper._begin_telegraph()\n\ttelegraph_duration = CHARGE_TELEGRAPH\n",
          "\tsuper._begin_telegraph()\n"),
    "c": ("the charge deals CHARGE_DAMAGE * 1.6 instead of CHARGE_DAMAGE", BOAR, B_SUITE,
          "C1 a player in the path loses exactly 14, once per charge",
          "CHARGE_HITBOX_SIZE, CHARGE_DAMAGE, \"charge\", CHARGE_SWEEP_ACTIVE)",
          "CHARGE_HITBOX_SIZE, CHARGE_DAMAGE * 1.6, \"charge\", CHARGE_SWEEP_ACTIVE)"),
    "d": ("no dizzy at the wall: the charge that meets a wall goes to RECOVER instead", BOAR, B_SUITE,
          "C1 at the wall `_dizzy` and `_stun_active` are both true",
          "\t\t_enter_dizzy()\n\t\treturn\n\t_charge_elapsed += delta\n",
          "\t\tvelocity.x = 0.0\n\t\t_enter_recover()\n\t\treturn\n\t_charge_elapsed += delta\n"),
    "e": ("the armour removed: a hit outside dizzy always takes HP", BOAR, B_SUITE,
          "C1 outside dizzy a 15-damage hit leaves HP at 45",
          "\tif current_state == State.DEAD or not _dizzy:\n\t\treturn\n\tsuper.take_damage(",
          "\tif current_state == State.DEAD:\n\t\treturn\n\tsuper.take_damage("),
    "f": ("the armour also blocks hits while dizzy (take_damage always returns)", BOAR, B_SUITE,
          "C1 a hit while dizzy takes 15, leaves x unchanged",
          "\tif current_state == State.DEAD or not _dizzy:\n\t\treturn\n\tsuper.take_damage(",
          "\tif current_state == State.DEAD or _dizzy or not _dizzy:\n\t\treturn\n\tsuper.take_damage("),
    "g": ("a parry stagger counts as dizzy for the armour (_stun_active lets hits through)", BOAR, B_SUITE,
          "C1 a hit during the parry stagger leaves HP unchanged",
          "\tif current_state == State.DEAD or not _dizzy:\n\t\treturn\n\tsuper.take_damage(",
          "\tif current_state == State.DEAD or not (_dizzy or _stun_active):\n\t\treturn\n\tsuper.take_damage("),
    "h": ("the damage multiplier applied twice (CHARGE_DAMAGE * get_enemy_damage_multiplier())", BOAR, B_SUITE,
          "C1 scaled: the charge takes 14 x get_enemy_damage_multiplier()",
          "CHARGE_HITBOX_SIZE, CHARGE_DAMAGE, \"charge\", CHARGE_SWEEP_ACTIVE)",
          "CHARGE_HITBOX_SIZE, CHARGE_DAMAGE * get_enemy_damage_multiplier(), \"charge\", CHARGE_SWEEP_ACTIVE)"),
    "i": ("the telegraph not divided by the difficulty multiplier (0.25 s floor kept)", BOAR, B_SUITE,
          "C1 scaled: the charge telegraphs 0.6 / the difficulty multiplier",
          "telegraph_duration = maxf(telegraph_duration / GameManager.get_difficulty_multiplier(), 0.25)",
          "telegraph_duration = maxf(telegraph_duration, 0.25)"),
    "j": ("dodge_chance left at EnemyBase's 0.15 (the assignment in _ready removed)", BOAR, B_SUITE,
          "C1 dodge_chance is 0: no random dodge on a hit",
          "\tdodge_chance = BOAR_DODGE_CHANCE\n",
          ""),
    "k": ("calm hands off to the arena too", VILLAGE, B_SUITE,
          "C3 calm: no arena (no story meta, no scene change) and the field resolves in the village",
          "\tif GameManager.has_flag(\"ch1_boar_fought\"):\n\t\t# Y1-P0-T13c: the arena plays the fight",
          "\tif GameManager.has_flag(\"ch1_boar_fought\") or GameManager.has_flag(\"ch1_boar_calmed\"):\n"
          "\t\t# Y1-P0-T13c: the arena plays the fight"),
    "l": ("the resume ignores ch1_corrupted_boar_defeated (a reload after the win pays twice)", VILLAGE, B_SUITE,
          "C5 a save there and a load: no boar_fight_after, no payment",
          "if GameManager.has_flag(\"ch1_boar_fight_won\") and not "
          "GameManager.has_flag(\"ch1_corrupted_boar_defeated\"):",
          "if GameManager.has_flag(\"ch1_boar_fight_won\"):"),
    "m": ("the ch1_boar row's flags left empty", ARENA, B_SUITE,
          "C4 ch1_boar_fight_won is set",
          "\"flags\": [\"ch1_boar_fight_won\"],",
          "\"flags\": [],"),
    "n": ("the village plays boar_fight_staged before the hand-off", VILLAGE, B_SUITE,
          "C3 the boar trigger: the change to the arena starts within 0.5 s of the choice",
          "\t\t_hand_off_to_boar_fight()\n\t\treturn\n",
          "\t\tawait _run(\"north_field\", \"boar_fight_staged\")\n\t\tif not is_inside_tree(): return\n"
          "\t\t_hand_off_to_boar_fight()\n\t\treturn\n"),
    "o": ("the village sets ch1_boar_fight_won itself (first line of _resume_after_boar_fight)", VILLAGE, R_SUITE,
          "[T13c ch1_boar_fight_won has one writer and is in the bible]: the village reads it with has_flag and never"
          " sets it",
          "func _resume_after_boar_fight(fade_tween: Tween) -> void:\n\t_field_running = true\n",
          "func _resume_after_boar_fight(fade_tween: Tween) -> void:\n"
          "\tGameManager.set_story_flag(\"ch1_boar_fight_won\", true)\n\t_field_running = true\n"),
    "p": ("the bridge trigger carries on after a hand-off (the _is_transitioning stop removed)", VILLAGE, B_SUITE,
          "C3 the bridge trigger: no bridge line, no ch1_bridge_* flag, _bridge_done unchanged",
          "\t\tif not is_inside_tree() or _is_transitioning: return\n\tif not _bridge_done:\n",
          "\t\tif not is_inside_tree(): return\n\tif not _bridge_done:\n"),
    "q": ("the reload fix removed (D6: a load no longer marks a closed field resolved)", VILLAGE, B_SUITE,
          "C5 a save there and a load: no boar_fight_after, no payment; the boar trigger does nothing"
          " (also C5 after calm / nest, a save and a load)",
          "\tif GameManager.has_flag(\"ch1_corrupted_boar_defeated\"):\n\t\t_field_resolved = true\n",
          "\tif false and GameManager.has_flag(\"ch1_corrupted_boar_defeated\"):\n\t\t_field_resolved = true\n"),
    "r": ("the off-screen override removed (renamed, so EnemyBase's _setup_screen_notifier runs)", BOAR, B_SUITE,
          "C1 off-screen culling is off: no ScreenNotifier child and no notifier reference",
          "func _setup_screen_notifier() -> void:\n\tpass\n",
          "func _setup_screen_notifier_removed() -> void:\n\tpass\n"),
    "s": ("knockback while dizzy: velocity not zeroed after the hit in take_damage (only there; _enter_dizzy and"
          " _end_dizzy untouched)", BOAR, B_SUITE,
          "C1 a hit while dizzy takes 15, leaves x unchanged (... px) and velocity at 0",
          "\tsuper.take_damage(amount, knockback_source)\n\tvelocity = Vector2.ZERO\n",
          "\tsuper.take_damage(amount, knockback_source)\n"),
    "t": ("CHARGE_MAX_TIME back to 2.5 s", BOAR, B_SUITE,
          "C1 a charge launched at the left wall reaches the right wall and ends dizzy",
          "const CHARGE_MAX_TIME: float = 3.5",
          "const CHARGE_MAX_TIME: float = 2.5"),
    "u": ("D9 removed: a stagger outside an attack leaves the cooldown as it is", BOAR, B_SUITE,
          "C1 a parry stagger in RECOVER: no telegraph within 0.9 x ATTACK_COOLDOWN after it ends (D9",
          "\t\t_enter_recover()\n\telse:\n\t\tattack_cooldown = maxf(attack_cooldown, _scaled_attack_cooldown())\n",
          "\t\t_enter_recover()\n"),
    "v": ("D10 removed: the dizzy cue never shown", BOAR, B_SUITE,
          "C1 the dizzy cue (D10) is hidden before the wall, shown while dizzy and hidden after"
          " / C4 the dizzy cue is shown while dizzy and hidden when the boar dies",
          "\t_show_dizzy_cue(true)\n",
          "\t_show_dizzy_cue(false)\n"),
    "w": ("Mara's handler carries on after a hand-off (or _is_transitioning removed from its guard)", VILLAGE, B_SUITE,
          "C3 Mara as the third beat, fight: arena reached, shop shut, tree not paused",
          "\t\tif not is_inside_tree() or _is_transitioning: return\n\t\tawait open_shop()\n",
          "\t\tif not is_inside_tree(): return\n\t\tawait open_shop()\n"),
    "x": ("BOAR_CONTACT_DAMAGE set to 8", BOAR, B_SUITE,
          "C1 within 30 px of the boar for 1.0 s with physics running and no charge: HP unchanged",
          "const BOAR_CONTACT_DAMAGE: float = 0.0",
          "const BOAR_CONTACT_DAMAGE: float = 8.0"),
    "y": ("a parried charge not sent to RECOVER (stagger's interrupted branch keeps the tween kill only)", BOAR,
          B_SUITE,
          "C1 the parried charge: the boar is staggered",
          "\t\t\t_telegraph_tween.kill()\n\t\t_enter_recover()\n\telse:\n",
          "\t\t\t_telegraph_tween.kill()\n\telse:\n"),
    "z": ("the sweep keeps querying after a hit (its _charge_hit_pending condition dropped)", BOAR, B_SUITE,
          "C1 once per charge with the player's invulnerability cleared every frame: exactly one hit",
          "\tif _charge_hit_pending and _charge_elapsed >= CHARGE_MIN_TRAVEL_TIME:\n",
          "\tif _charge_elapsed >= CHARGE_MIN_TRAVEL_TIME:\n"),
    "aa": ("the return beat does not wait for the fade-in (await fade_tween.finished removed)", VILLAGE, B_SUITE,
           "C5 the return beat starts only after the fade-in",
           "\tif fade_tween:\n\t\tawait fade_tween.finished\n",
           "\tif fade_tween:\n\t\tpass\n"),
    "ab": ("a hit during the telegraph or the charge starts a hit-stun (outside dizzy: hit-stun, no HP)", BOAR,
           B_SUITE,
           "C1 hits on the first TELEGRAPH and first ATTACK frames take no HP and start no hit-stun",
           "\tif current_state == State.DEAD or not _dizzy:\n\t\treturn\n\tsuper.take_damage(",
           "\tif current_state == State.DEAD:\n\t\treturn\n\tif not _dizzy:\n\t\t_apply_hitstun(amount)\n"
           "\t\treturn\n\tsuper.take_damage("),
    "ac": ("the arena's win heals the player to full (one line in _on_story_enemy_died)", ARENA, B_SUITE,
           "C4 the player's HP is kept",
           "\t\tplayer.invuln_timer = 1.0e9\n",
           "\t\tplayer.invuln_timer = 1.0e9; player.current_health = player.max_health;"
           " GameManager.player_stats[\"hp\"] = int(player.max_health)\n"),
}


def _prepare(mid):
    """Reads the target, returns (desc, path, suite, case, raw, digest, text, crlf, o, n, count)."""
    desc, path, suite, case, old, new = MUTATIONS[mid]
    raw = io.open(path, "rb").read()
    digest = hashlib.sha256(raw).hexdigest()
    text = raw.decode("utf-8")
    crlf = "\r\n" in text
    o, n = (old.replace("\n", "\r\n"), new.replace("\n", "\r\n")) if crlf else (old, new)
    return desc, path, suite, case, raw, digest, text, crlf, o, n, text.count(o)


def check():
    bad = 0
    for mid in sorted(MUTATIONS):
        desc, path, _s, _c, _r, _d, _t, crlf, _o, _n, count = _prepare(mid)
        ok = count == 1
        bad += 0 if ok else 1
        print(f"{'OK  ' if ok else 'FAIL'} {mid}: {count} match(es) in {os.path.basename(path)} (crlf {crlf}) - {desc}")
    print(f"{len(MUTATIONS) - bad} of {len(MUTATIONS)} patterns match exactly once")
    sys.exit(1 if bad else 0)


def main():
    if len(sys.argv) < 2:
        print(__doc__)
        sys.exit(2)
    if sys.argv[1] == "--check":
        check()
    mid = sys.argv[1]
    tag = ("_" + sys.argv[2]) if len(sys.argv) > 2 else ""
    if mid not in MUTATIONS:
        print(f"unknown mutation id {mid!r}; ids: {', '.join(sorted(MUTATIONS))}")
        sys.exit(2)
    desc, path, suite, case, raw, digest, text, crlf, o, n, count = _prepare(mid)
    if count != 1:
        print(f"MUTATION {mid} NOT APPLIED: pattern found {count} times in {os.path.basename(path)}; file untouched")
        sys.exit(2)
    log = os.path.join(EV, f"t13c_mutation_{mid}{tag}.log")
    rel = os.path.relpath(path, PROJ)
    try:
        io.open(path, "wb").write(text.replace(o, n).encode("utf-8"))
        env = dict(os.environ, GODOT=GODOT)
        with io.open(log, "w", encoding="utf-8", newline="") as fh:
            fh.write(f"# T13c mutation ({mid}): {desc}\n# file: {rel} (sha256 before {digest}, crlf {crlf})\n"
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
