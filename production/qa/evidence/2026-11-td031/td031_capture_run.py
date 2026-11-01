"""Run td031_capture.gd in a live 1280x720 window on Godot 4.6.3. Usage: python -I td031_capture_run.py before|after
'before' swaps HEAD's combat_arena.gd in for the one capture and restores the working file byte for byte."""
import hashlib, io, os, subprocess, sys

ROOT = r"C:\Users\BHASKAR BAHUKHANDI\OneDrive\Desktop\Ultimate project"
PROJ = os.path.join(ROOT, "AethelgardPrototype")
ARENA = os.path.join(PROJ, "scripts", "combat", "combat_arena.gd")
EV = os.path.join(ROOT, "production", "qa", "evidence", "2026-11-td031")
GODOT = r"C:\Godot\Godot_v4.6.3-stable_win64_console.exe"
HERE = os.path.dirname(os.path.abspath(__file__))
ISO = os.path.join(HERE, "aeth_phase0_test_td031_capture")

which = sys.argv[1]
raw = io.open(ARENA, "rb").read()
digest = hashlib.sha256(raw).hexdigest()
os.makedirs(ISO, exist_ok=True)
png = os.path.join(EV, f"story-fight-{which}.png")
log = os.path.join(EV, f"capture_{which}.log")
try:
    if which == "before":
        head = subprocess.run(["git", "show", "HEAD:AethelgardPrototype/scripts/combat/combat_arena.gd"],
                              cwd=ROOT, capture_output=True, check=True).stdout
        io.open(ARENA, "wb").write(head)
    env = dict(os.environ, APPDATA=ISO)
    with io.open(log, "w", encoding="utf-8", newline="") as fh:
        rc = subprocess.run([GODOT, "--path", PROJ, "--resolution", "1280x720", "--script",
                             os.path.join(HERE, "td031_capture.gd"), "--", "--out=" + png.replace("\\", "/")],
                            env=env, stdout=fh, stderr=subprocess.STDOUT, timeout=120).returncode
finally:
    io.open(ARENA, "wb").write(raw)
restored = hashlib.sha256(io.open(ARENA, "rb").read()).hexdigest() == digest
out = io.open(log, encoding="utf-8", errors="replace").read().splitlines()
print(f"capture {which} exit={rc} restored={restored}")
for l in out:
    if l.startswith(("Godot Engine", "Vulkan", "SCENE", "SLIME", "SHOT")) or "ERROR" in l:
        print("  " + l)
