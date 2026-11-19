"""Watch check_time_model.py fail (story Y1-P0-S06b, AC-6): one mutation per invocation.

Run:  python -I -B run_mutations.py <name> --root <ABSOLUTE repo root>
      python -I -B run_mutations.py --list

Each run copies design/gdd/time-model.md to a temp directory, applies ONE mutation to the copy, runs the checker on
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
CHECKER = HERE / "check_time_model.py"


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
    "dropped_ts_row": ("delete the TS17 row", lambda t: drop_line(t, "| TS17 |")),
    "ts_type_swapped": ("TS04 Order -> Window", lambda t: replace_once(
        t, "| TS04 | Aldric at the Gate | Order | 11993 |", "| TS04 | Aldric at the Gate | Window | 11993 |")),
    "bogus_flag": ("ch1_bridge_fell -> ch1_bridge_fall in the bridge Outcomes bullet", lambda t: replace_once(
        t, "`ch1_bridge_fell` (dusk reached", "`ch1_bridge_fall` (dusk reached")),
    "missing_pace_name": ("delete the act 4 pace row", lambda t: drop_line(t, "| 4 | act4_pace_early")),
    "field_type_removed": ("delete the only Order-specific field row", lambda t: drop_line(
        t, "| first_step, then_step |")),
    "pm_line_off_by_one": ("TS10 pm_line 12071 -> 12072", lambda t: replace_once(
        t, "| TS10 | Limited Blade Release | Window | 12071 |", "| TS10 | Limited Blade Release | Window | 12072 |")),
    "renamed_pace_flag": ("act2_pace_late -> act2_pace_slow in the pace row", lambda t: replace_in_line(
        t, "| 2 | act2_pace_early", "act2_pace_late", "act2_pace_slow")),
    "margin_broken": ("bridge base_deadline_min default 300 -> 200", lambda t: replace_once(
        t, "| `base_deadline_min` (bridge) | 300 |", "| `base_deadline_min` (bridge) | 200 |")),
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
    source = root / "design/gdd/time-model.md"
    original = source.read_text(encoding="utf-8")
    what, mutate = MUTATIONS[args.name]
    mutated = mutate(original)
    changed = [l for l in difflib.unified_diff(original.split("\n"), mutated.split("\n"), lineterm="", n=0)
               if l[:1] in "+-" and l[:3] not in ("+++", "---")]
    if args.name != "control" and not changed:
        print("ERROR: the mutation changed nothing")
        return 2
    with tempfile.TemporaryDirectory() as tmp:
        copy = Path(tmp) / "time-model.md"
        copy.write_text(mutated, encoding="utf-8")
        run = subprocess.run([sys.executable, "-I", "-B", str(CHECKER), "--root", str(root), "--gdd", str(copy)],
                             capture_output=True, text=True)
    out = [f"mutation: {args.name} — {what}", f"command:  python -I -B check_time_model.py --root {root} --gdd <mutated copy>"]
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
