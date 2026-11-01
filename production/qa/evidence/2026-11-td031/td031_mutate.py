"""TD-031 mutation harness: apply ONE mutation to combat_arena.gd, run the table suite on Godot 4.6.3,
restore the file byte for byte, and print the result. Usage: python -I td031_mutate.py <a..j>"""
import hashlib, io, subprocess, sys, os

ROOT = r"C:\Users\BHASKAR BAHUKHANDI\OneDrive\Desktop\Ultimate project"
PROJ = os.path.join(ROOT, "AethelgardPrototype")
ARENA = os.path.join(PROJ, "scripts", "combat", "combat_arena.gd")
EV = os.path.join(ROOT, "production", "qa", "evidence", "2026-11-td031")
GODOT = r"C:\Godot\Godot_v4.6.3-stable_win64_console.exe"

# id: (description, expected catching case, old text, new text)
MUTATIONS = {
    "a": ("the defaults merge removed", "4",
          "_story_cfg = row.merged(STORY_FIGHT_DEFAULTS)",
          "_story_cfg = row"),
    "b": ("the builder's mask changed to 2", "7",
          "body.collision_mask = 1   # Collide with world",
          "body.collision_mask = 2   # Collide with world"),
    "c": ("the trees read from a literal again", "5",
          'for t in data["trees"]:',
          'for t in [[-420, 38, 230], [-180, 34, 215], [50, 40, 240], [180, 35, 220], [350, 30, 210], '
          '[800, 38, 230], [950, 42, 225], [1100, 36, 235], [1200, 32, 220], [1420, 36, 225], [1660, 40, 235]]:'),
    "d": ("the Vector2(900, 400) fallback restored", "9",
          'var origin: Vector2 = _story_cfg["enemy_spawn"]',
          'var origin: Vector2 = Vector2(900, 400)'),
    "e": ("the unknown-key check removed", "2",
          "problems.append(\"unknown key '%s'\" % key)",
          "pass"),
    "f": ("the retry builds its enemy without the builder (mask 2)", "6",
          "\tenemy.set_script(enemy_script)\n\tenemies_node.add_child(enemy)",
          "\tif story_fight_retries > 0:\n\t\tenemy.collision_mask = 2\n\tenemy.set_script(enemy_script)\n\tenemies_node.add_child(enemy)"),
    "g": ("the encounter's zone_level assignment removed (variant)", "10",
          "\t\t\tenemy_node.zone_level = enemy_level",
          "\t\t\tpass"),
    "g2": ("the encounter sets zone_level after add_child", "10",
           "\t\tif \"zone_level\" in enemy_node:\n\t\t\tenemy_node.zone_level = enemy_level\n\n\t\t# Add to scene\n\t\tenemies_node.add_child(enemy_node)",
           "\t\t# Add to scene\n\t\tenemies_node.add_child(enemy_node)\n\t\tif \"zone_level\" in enemy_node:\n\t\t\tenemy_node.zone_level = enemy_level"),
    "h": ("the boss body built with ENEMY_SIZES' default size", "11",
          "BOSS_SIZES.get(boss_id, Vector2(80, 100))",
          "Vector2(48, 48)"),
    "h2": ("the boss body built at (900, 400)", "11",
           "\t\tVector2(800, 400))",
           "\t\tVector2(900, 400))"),
    "l": ("the win waits a hard-coded 0.6 s, not the row's shard_fade (QL-TEST-COVERAGE gap 1)", "4b",
          'create_timer(float(_story_cfg["shard_fade"]), false, false, true)',
          'create_timer(0.6, false, false, true)'),
    "m": ("the story enemy ignores the row's enemy_size (grey-fallback lookup again)", "6b",
          'var size: Vector2 = _story_cfg["enemy_size"] if _story_cfg.has("enemy_size") else ENEMY_SIZES[enemy_type]',
          'var size: Vector2 = ENEMY_SIZES.get(enemy_type, Vector2(48, 48))'),
    "i": ("one ch1_slime tree's width changed", "8",
          "[[-420, 38, 230],",
          "[[-420, 39, 230],"),
    "j": ("_consume_story_fight_metas skips validate_story_fight", "3",
          "var problems := validate_story_fight(story_fight_table[id])",
          "var problems := PackedStringArray()"),
}


def main():
    mid = sys.argv[1]
    desc, case, old, new = MUTATIONS[mid]
    raw = io.open(ARENA, "rb").read()
    digest = hashlib.sha256(raw).hexdigest()
    text = raw.decode("utf-8")
    crlf = "\r\n" in text
    o, n = (old.replace("\n", "\r\n"), new.replace("\n", "\r\n")) if crlf else (old, new)
    count = text.count(o)
    if count != 1:
        print(f"MUTATION {mid} NOT APPLIED: pattern found {count} times")
        sys.exit(2)
    log = os.path.join(EV, f"mutation_{mid}.log")
    try:
        io.open(ARENA, "wb").write(text.replace(o, n).encode("utf-8"))
        env = dict(os.environ, GODOT=GODOT)
        with io.open(log, "w", encoding="utf-8", newline="") as fh:
            fh.write(f"# TD-031 mutation ({mid}): {desc}; expected to be caught by QA case {case}\n")
            fh.flush()
            proc = subprocess.run(["powershell", "-NoProfile", "-File", "tests/run_phase0_tests.ps1", "-Script",
                                   "res://tests/integration/combat/story_fight_table_test.gd"],
                                  cwd=PROJ, env=env, stdout=fh, stderr=subprocess.STDOUT, timeout=300)
        rc = proc.returncode
    finally:
        io.open(ARENA, "wb").write(raw)
    restored = hashlib.sha256(io.open(ARENA, "rb").read()).hexdigest() == digest
    lines = io.open(log, encoding="utf-8", errors="replace").read().splitlines()
    result = [l for l in lines if " RESULT:" in l and l[:1].isupper()]
    fails = [l.strip() for l in lines if l.strip().startswith("FAIL:")]
    print(f"mutation {mid} ({desc}) exit={rc} restored={restored}")
    print("  " + (result[-1] if result else "NO RESULT LINE"))
    for f in fails[:8]:
        print("  " + f)
    if len(fails) > 8:
        print(f"  ... {len(fails) - 8} more")


main()
