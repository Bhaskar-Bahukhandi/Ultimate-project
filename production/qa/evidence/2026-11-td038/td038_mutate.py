"""TD-038 mutation harness: apply ONE mutation to combat_arena.gd, run the table suite on Godot 4.6.3,
restore the file byte for byte, and print the result. Usage: python -I td031_mutate.py <a|b|c>"""
import hashlib, io, subprocess, sys, os

ROOT = r"C:\Users\BHASKAR BAHUKHANDI\OneDrive\Desktop\Ultimate project"
PROJ = os.path.join(ROOT, "AethelgardPrototype")
ARENA = os.path.join(PROJ, "scripts", "combat", "combat_arena.gd")
EV = os.path.join(ROOT, "production", "qa", "evidence", "2026-11-td038")
GODOT = r"C:\Godot\Godot_v4.6.3-stable_win64_console.exe"

# id: (description, expected catching case, old text, new text)
MUTATIONS = {
    "a": ("the validator no longer uses the EnemyBase helper", "QA 1",
          "if not _story_script_extends_enemy_base(resource):",
          "if false and not _story_script_extends_enemy_base(resource):"),
    "b": ("the EnemyBase check always refuses", "QA 2",
          "if not _story_script_extends_enemy_base(resource):",
          "if true or not _story_script_extends_enemy_base(resource):"),
    "c": ("the walk checks one level only (the script and its direct parent)", "QA 5a",
          "current = current.get_base_script()",
          "current = current.get_base_script() if current == script else null"),
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
            fh.write(f"# TD-038 mutation ({mid}): {desc}; expected to be caught by QA case {case}\n")
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
