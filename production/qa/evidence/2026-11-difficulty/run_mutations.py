"""Watch check_difficulty_profiles.py fail (story Y1-P0-S06c, AC-7): one mutation per invocation.

Run:  python -I -B run_mutations.py <name> --root <ABSOLUTE repo root>
      python -I -B run_mutations.py --list

Each run copies design/gdd/difficulty-profiles.md to a temp directory, applies ONE mutation to the copy, runs the checker on
the copy, and writes the transcript to mutation_<name>.log beside this file. The repository GDD is never touched.
The control mutation changes nothing and must PASS; every other mutation must FAIL. Pass an absolute --root:
a relative one makes every run error out the same way and looks like success.
"""
from __future__ import annotations

import argparse
import difflib
import subprocess
import sys
import tempfile
from pathlib import Path

HERE = Path(__file__).resolve().parent
CHECKER = HERE / "check_difficulty_profiles.py"


def drop_line(text: str, prefix: str) -> str:
    lines = text.split("\n")
    hits = [i for i, l in enumerate(lines) if l.startswith(prefix)]
    assert len(hits) == 1, f"{len(hits)} lines start with {prefix!r}"
    del lines[hits[0]]
    return "\n".join(lines)


def replace_once(text: str, old: str, new: str) -> str:
    assert text.count(old) == 1, f"{text.count(old)} occurrences of {old!r}"
    return text.replace(old, new)


def replace_in_line(text: str, line_prefix: str, old: str, new: str) -> str:
    lines = text.split("\n")
    hits = [i for i, l in enumerate(lines) if l.startswith(line_prefix)]
    assert len(hits) == 1, f"{len(hits)} lines start with {line_prefix!r}"
    assert old in lines[hits[0]], f"{old!r} not in the line"
    lines[hits[0]] = lines[hits[0]].replace(old, new, 1)
    return "\n".join(lines)


MUTATIONS = {
    "control": ("no change; must PASS", lambda t: t),
    "missing_heading": ("delete the '## Formulas' heading", lambda t: drop_line(t, "## Formulas")),
    "dropped_profile_row": ("delete the healing row of the profile table", lambda t: drop_line(t, "| healing | 5 |")),
    "leniency_65": ("hell deadline_leniency 85 -> 65", lambda t: replace_once(
        t, "| deadline_leniency | 150 | 125 | 100 | 100 | 85 |", "| deadline_leniency | 150 | 125 | 100 | 100 | 65 |")),
    "bad_token": ("constants map: PARRY_WINDOW cited at :121 instead of :120", lambda t: replace_once(
        t, "scripts/combat/player_combat.gd:120 | PARRY_WINDOW", "scripts/combat/player_combat.gd:121 | PARRY_WINDOW")),
    "dropped_mapping_row": ("delete the old value 2 (NORMAL) mapping row", lambda t: drop_line(t, "| 2 | NORMAL |")),
    "persistence_global": ("persistence: per-run -> persistence: global", lambda t: replace_in_line(
        t, "persistence: per-run", "per-run", "global")),
    "mapping_swapped": ("old value 2 maps to hard instead of medium", lambda t: replace_once(
        t, "| 2 | NORMAL | medium |", "| 2 | NORMAL | hard |")),
}


def main() -> int:
    sys.stdout.reconfigure(encoding="utf-8", errors="replace")
    ap = argparse.ArgumentParser()
    ap.add_argument("name", nargs="?")
    ap.add_argument("--root", default=None)
    ap.add_argument("--list", action="store_true")
    args = ap.parse_args()
    if args.list:
        for name, (what, _) in MUTATIONS.items():
            print(f"{name}: {what}")
        return 0
    if args.name not in MUTATIONS or not args.root:
        print("usage: run_mutations.py <name> --root <absolute repo root>   (or --list)")
        return 2
    root = Path(args.root)
    if not root.is_absolute():
        print(f"ERROR: --root must be absolute, got {args.root!r}")
        return 2
    source = root / "design/gdd/difficulty-profiles.md"
    original = source.read_text(encoding="utf-8")
    what, mutate = MUTATIONS[args.name]
    mutated = mutate(original)
    changed = [l for l in difflib.unified_diff(original.split("\n"), mutated.split("\n"), lineterm="", n=0)
               if l[:1] in "+-" and l[:3] not in ("+++", "---")]
    if args.name != "control" and not changed:
        print("ERROR: the mutation changed nothing")
        return 2
    with tempfile.TemporaryDirectory() as tmp:
        copy = Path(tmp) / "difficulty-profiles.md"
        copy.write_text(mutated, encoding="utf-8")
        run = subprocess.run([sys.executable, "-I", "-B", str(CHECKER), "--root", str(root), "--gdd", str(copy),
                              "--evidence", str(HERE)],
                             capture_output=True, text=True)
    out = [f"mutation: {args.name} — {what}", f"command:  python -I -B check_difficulty_profiles.py --root {root} --gdd <mutated copy>"]
    out += [f"changed:  {l}" for l in changed] or ["changed:  (nothing)"]
    out += run.stdout.rstrip().split("\n")
    if run.stderr.strip():
        out += ["stderr: " + run.stderr.strip()]
    expected_pass = args.name == "control"
    got_pass = run.returncode == 0
    verdict = "AS EXPECTED" if got_pass == expected_pass else "UNEXPECTED"
    out.append(f"expected {'PASS' if expected_pass else 'FAIL'}, checker exit {run.returncode}: {verdict}")
    text = "\n".join(out) + "\n"
    print(text, end="")
    try:
        (HERE / f"mutation_{args.name}.log").write_text(text, encoding="utf-8")
    except OSError as err:
        print(f"WARNING: could not write the log: {err}")
    return 0 if verdict == "AS EXPECTED" else 1


if __name__ == "__main__":
    sys.exit(main())
