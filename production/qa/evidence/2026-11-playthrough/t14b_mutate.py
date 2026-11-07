"""Y1-P0-T14b mutation harness (story AC-7): apply ONE mutation (one exact replacement, matched exactly once) to the
playthrough bot, run its suite on Godot 4.6.3, restore the file byte for byte, verify its SHA-256 and print the result.
Usage: python -I t14b_mutate.py <id>   (one mutation per invocation; the log is t14b_mutation_<id>.log)
       python -I t14b_mutate.py --check   (no Godot, no file written: every pattern must match exactly once)
Modelled on production/qa/evidence/2026-11-ch1-fights/t13c_mutate.py. Only the bot file is ever patched."""
import hashlib, io, subprocess, sys, os

ROOT = r"C:\Users\BHASKAR BAHUKHANDI\OneDrive\Desktop\Ultimate project"
PROJ = os.path.join(ROOT, "AethelgardPrototype")
EV = os.path.join(ROOT, "production", "qa", "evidence", "2026-11-playthrough")
GODOT = r"C:\Godot\Godot_v4.6.3-stable_win64_console.exe"
BOT = os.path.join(PROJ, "tests", "integration", "playthrough", "full_playthrough_test.gd")
SUITE = "res://tests/integration/playthrough/full_playthrough_test.gd"

# id: (description, expected catching check, old text, new text). Texts use "\n" (the bot file is LF). old and new
# may be equal-length lists: each pair is one replacement and each old text must match exactly once.
MUTATIONS = {
    "a": ("the slime row's win flags emptied by a runtime override inside the test (the arena's merged _story_cfg)",
          "AC-2 leg 02 combat_arena.tscn (ch1_slime): the row's win flags [...] are set after the finish",
          "\t\t_fight_stage = 1\n",
          "\t\t_fight_stage = 1\n\t\tif want == \"ch1_slime\":\n\t\t\ts._story_cfg[\"flags\"] = []   # MUTATION a\n"),
    # (b) v2, after the boar-flake fix: the window is 3 s of game time AND the enemy out of IDLE.
    "b": ("a fight finished before the alive window (the window's wait removed)",
          "AC-2 leg 02 combat_arena.tscn (ch1_slime): the alive window reached 3 s of game time",
          "\tif (_fight_alive_s < FIGHT_ALIVE_S or not _fight_left_idle) and wall_s < FIGHT_ALIVE_WALL_S:\n",
          "\tif false and wall_s < FIGHT_ALIVE_WALL_S:   # MUTATION b\n"),
    "c": ("the bot presses the Root Access panel (a target-filter edit, then Apply)",
          "AC-2 leg 04 path_to_oakhaven.tscn: the game's _root_choice is 'fight' at the hand-off",
          "the bot gives it no input (D2)\" % str(_root_open_glitch))\n",
          "the bot gives it no input (D2)\" % str(_root_open_glitch))\n"
          "\ts._target_filter.select(1)   # MUTATION c\n\ts._on_root_access_apply()\n"),
    "d": ("the shatter skipped by input (ui_cancel held from the scene's start)",
          "AC-3 leg 15 shatter_transition.tscn: played through / no skip",
          "\tvar card = s.get(\"chapter_end_card\")\n",
          "\tif not _end_card_pressed and s.get(\"cinematic_active\") == true:   # MUTATION d\n"
          "\t\t_end_card_pressed = true\n\t\tvar mut := InputEventAction.new()\n\t\tmut.action = &\"ui_cancel\"\n"
          "\t\tmut.pressed = true\n\t\tInput.parse_input_event(mut)\n"
          "\tvar card = s.get(\"chapter_end_card\")\n"),
    # (e) second definition (coordinator, 2026-11-07): the first, steps only, was refused by the game itself
    # (tower_warning's option 0 "Not yet. The convoy first.", ironhold_city.dlg:239-241) and hit leg 19's cap; its log
    # is t14b_mutation_e_first_def_game_refuses.log. Now the bot also answers option 1 at that one prompt.
    "e": ("Rem skipped: the Clock Tower first, and option 1 'We go up now.' at the tower_warning choice only",
          "AC-5 leg 19 ironhold_region.tscn: flags set at the hand-off [...] (missing [... ch2_medicine_early ...])",
          ["{\"steps\": [\"talk:Rem\", \"gate:WestRoadGate\", \"bronze\", \"gate:ClockTowerGate\"]}",
           "\t\t\t\tdm._on_choice_pressed(0)\n"],
          ["{\"steps\": [\"bronze\", \"gate:ClockTowerGate\"]}",
           "\t\t\t\tdm._on_choice_pressed(1 if prompt.begins_with(\"Go up anyway\") else 0)   # MUTATION e\n"]),
    "f": ("the knight hop done by a direct scene change (SceneTransitions.change_scene, not the region's handler)",
          "AC-3 leg 12 oakhaven_region.tscn: boss_return_scene is oakhaven_region.tscn when the knight is handed off",
          "\t_press(&\"interact\")\n",
          "\t_st().change_scene(KNIGHT)   # MUTATION f\n"),
    "f2": ("the knight hop done by change_scene_to_file (no SceneTransitions hand-off at all)",
           "AC-6 leg 12 oakhaven_region.tscn hands off within its cap (softlock report)",
           "\t_press(&\"interact\")\n",
           "\tchange_scene_to_file(KNIGHT)   # MUTATION f2\n"),
    "g": ("a 1 s cap on the guardian leg (leg 04)",
          "AC-6 leg 04 path_to_oakhaven.tscn hands off within its 1 s cap + SOFTLOCK REPORT naming leg 4",
          "\"root_access_unlocked\"], CAP_GUARDIAN, {\"root_giveup\": true}],",
          "\"root_access_unlocked\"], 1.0, {\"root_giveup\": true}],"),
    "h": ("leg 07's scene made wrong in the table (elara_house instead of oakhaven_village)",
          "AC-5 after leg 06 (path_to_oakhaven.tscn) the game goes to elara_house.tscn (got oakhaven_village.tscn)",
          "\t[VILLAGE, \"room\", [\"ch1_oakhaven_entered\", \"ch1_northfall_registry_seen\"], CAP_CH1],\n",
          "\t[HOUSE, \"room\", [\"ch1_oakhaven_entered\", \"ch1_northfall_registry_seen\"], CAP_CH1],\n"),
    "i": ("leg 08's expected flag ch1_stew_asked_where swapped for a flag the game never sets",
          "AC-5 leg 08 elara_house.tscn: flags set at the hand-off [...] (missing [\"ch1_t14b_never_set\"])",
          "[HOUSE, \"room\", [\"ch1_stew_done\", \"ch1_stew_asked_where\", \"ch1_elara_arm_talked\"], CAP_CH1],",
          "[HOUSE, \"room\", [\"ch1_stew_done\", \"ch1_t14b_never_set\", \"ch1_elara_arm_talked\"], CAP_CH1],"),
    "j": ("a ContextStack entry pushed before the hook's hand-off (not pausing the tree)",
          "AC-5 leg 00 opening_crash_site_hook.tscn: no ContextStack entry open at the hand-off",
          "\t\t\t\thook._complete_opening_hook()\n",
          "\t\t\t\t_cs().push(&\"t14b_mutation_j\", null, false)   # MUTATION j\n"
          "\t\t\t\thook._complete_opening_hook()\n"),
    "l": ("the player killed in the slime fight's alive window (the arena player's own die())",
          "AC-2 leg 02 combat_arena.tscn (ch1_slime): the player stays alive through the alive window"
          " + SOFTLOCK REPORT: the player died",
          "\tvar retries: int = int(s.get(\"story_fight_retries\"))\n",
          "\tif is_instance_valid(p) and not dead:   # MUTATION l\n\t\tp.die()\n"
          "\t\tdead = p.get(\"is_dead\") == true\n"
          "\tvar retries: int = int(s.get(\"story_fight_retries\"))\n"),
}


def _prepare(mid):
    desc, case, old, new = MUTATIONS[mid]
    olds, news = (old, new) if isinstance(old, list) else ([old], [new])
    raw = io.open(BOT, "rb").read()
    digest = hashlib.sha256(raw).hexdigest()
    text = raw.decode("utf-8")
    crlf = "\r\n" in text
    if crlf:
        olds = [x.replace("\n", "\r\n") for x in olds]
        news = [x.replace("\n", "\r\n") for x in news]
    counts = [text.count(x) for x in olds]
    count = 1 if all(c == 1 for c in counts) else (0 if 0 in counts else max(counts))
    return desc, case, raw, digest, text, crlf, olds, news, count


def check():
    bad = 0
    for mid in sorted(MUTATIONS):
        desc, _c, _r, _d, _t, crlf, _o, _n, count = _prepare(mid)
        ok = count == 1
        bad += 0 if ok else 1
        print(f"{'OK  ' if ok else 'FAIL'} {mid}: {count} match(es) (crlf {crlf}) - {desc}")
    print(f"{len(MUTATIONS) - bad} of {len(MUTATIONS)} patterns match exactly once")
    sys.exit(1 if bad else 0)


def main():
    if len(sys.argv) < 2:
        print(__doc__)
        sys.exit(2)
    if sys.argv[1] == "--check":
        check()
    mid = sys.argv[1]
    if mid not in MUTATIONS:
        print(f"unknown mutation id {mid!r}; ids: {', '.join(sorted(MUTATIONS))}")
        sys.exit(2)
    desc, case, raw, digest, text, crlf, o, n, count = _prepare(mid)
    if count != 1:
        print(f"MUTATION {mid} NOT APPLIED: pattern found {count} times; file untouched")
        sys.exit(2)
    log = os.path.join(EV, f"t14b_mutation_{mid}.log")
    rel = os.path.relpath(BOT, PROJ)
    try:
        mutated = text
        for a, b in zip(o, n):
            mutated = mutated.replace(a, b)
        io.open(BOT, "wb").write(mutated.encode("utf-8"))
        env = dict(os.environ, GODOT=GODOT)
        with io.open(log, "w", encoding="utf-8", newline="") as fh:
            fh.write(f"# T14b mutation ({mid}): {desc}\n# file: {rel} (sha256 before {digest}, crlf {crlf})\n"
                     f"# suite: {SUITE}\n# expected to be caught by: {case}\n")
            fh.flush()
            # No Python timeout: the runner enforces the suite's own limit from tests/suite_limits.txt.
            proc = subprocess.run(["powershell", "-NoProfile", "-File", "tests/run_phase0_tests.ps1", "-Script", SUITE],
                                  cwd=PROJ, env=env, stdout=fh, stderr=subprocess.STDOUT)
        rc = proc.returncode
    finally:
        io.open(BOT, "wb").write(raw)
    after = hashlib.sha256(io.open(BOT, "rb").read()).hexdigest()
    restored = after == digest
    with io.open(log, "a", encoding="utf-8", newline="") as fh:
        fh.write(f"# restore: sha256 after {after}, matches before: {restored}\n")
    lines = io.open(log, encoding="utf-8", errors="replace").read().splitlines()
    result = [l for l in lines if " RESULT:" in l and l[:1].isupper()]
    fails = [l.strip() for l in lines if l.strip().startswith("FAIL:")]
    soft = [l.strip() for l in lines if "SOFTLOCK REPORT" in l or l.startswith("    leg ")]
    runner = [l.strip() for l in lines if l.startswith("RUNNER ")]
    errs = sum(1 for l in lines if "SCRIPT" + " ERROR" in l or "Parse" + " Error" in l)
    print(f"mutation {mid} ({desc}) exit={rc}")
    print(f"  sha256 before={digest}")
    print(f"  sha256 after ={after} restored={restored}")
    print("  " + (result[-1] if result else "NO RESULT LINE"))
    print(f"  engine error lines in log: {errs}")
    for r in runner:
        print("  " + r.replace("script error", "s.e.").replace("SCRIPT", "S.").replace("Parse", "P.")[:200])
    for x in soft[:4]:
        print("  " + x[:200])
    seen = set()
    for f in fails:
        if f not in seen:
            seen.add(f)
            print("  " + f[:260])


main()
