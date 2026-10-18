"""Align the plan's region names with story/STORY_BIBLE.md §3 (decided 2026-10-18).

The IDs R1-R8 keep their act split (Act 1 = R1-R2, Act 2 = R3-R5,
Act 3 = R6-R7, Act 4 = R8); only the names change:
  R4 Mirror City      -> R4 Forgotten Sectors (the Null Court)
  R5 Cathedral Server -> R5 Mirror City
  R6 Memory Ocean     -> R6 Cathedral Server
  R7 Saved Assembly   -> R7 Memory Ocean / Saved Assembly
  R8 Root of Heaven   -> R8 Rootward Expanse (Human Patch Lab, Root of Heaven)
Human Patch Lab and Forgotten Sectors are launch regions now, so Expansion 1's
kingdoms become provisional X1-A / X1-B (chosen from the blueprint's cut
kingdoms at the Y8 expansion planning day).

Usage: python fix_regions.py <data_dir> [--apply]   (default: report only)
"""
import json, os, re, sys

PHASE_FILES = ["Y3", "Y4", "Y5", "Y6", "Y7", "Y8", "Y9", "Y10"]
OLD = {"R4": "Mirror City", "R5": "Cathedral Server", "R6": "Memory Ocean",
       "R7": "Saved Assembly", "R8": "Root of Heaven"}
NEW = {"R4": "Forgotten Sectors", "R5": "Mirror City", "R6": "Cathedral Server",
       "R7": "Memory Ocean / Saved Assembly", "R8": "Rootward Expanse"}
EXPANSION = {"Human Patch Lab": "cut kingdom A", "Forgotten Sectors": "cut kingdom B"}


def fix_text(s, pid):
    # 1. Names written with their ID ("R6 Memory Ocean"), via tokens so the
    #    rotation (Mirror City moves from R4 to R5) doesn't chain.
    for rid, name in OLD.items():
        s = s.replace(f"{rid} {name}", f"⟦{rid}⟧")
        s = s.replace(f"{rid} ({name})", f"⟦{rid}⟧")
    # 2. Expansion kingdoms (Y8+ only; in Y6 "Human Patch Lab" is canon Act 4).
    if pid in ("Y8", "Y9", "Y10"):
        for old, new in EXPANSION.items():
            s = s.replace(old, new)
    # 3. Bare old names left over: map by which region they named in the old
    #    plan (Y3-Y10 used the old mapping throughout).
    for rid, name in OLD.items():
        if rid == "R8":
            continue   # bare "Root of Heaven" stays: it is a place inside R8 in the bible
        s = s.replace(name, f"⟦bare{rid}⟧")
    for rid in OLD:
        s = s.replace(f"⟦{rid}⟧", f"{rid} {NEW[rid]}")
        s = s.replace(f"⟦bare{rid}⟧", NEW[rid])
    return s


def main(data_dir, apply):
    for pid in PHASE_FILES:
        path = os.path.join(data_dir, pid + ".json")
        raw = open(path, encoding="utf-8").read()
        fixed = fix_text(raw, pid)
        json.loads(fixed)  # still valid JSON
        before = {n: raw.count(n) for n in list(OLD.values()) + list(EXPANSION)}
        after = {n: fixed.count(n) for n in list(NEW.values()) + ["cut kingdom A", "cut kingdom B"]}
        print(pid, "old:", {k: v for k, v in before.items() if v}, "-> new:", {k: v for k, v in after.items() if v})
        if apply and fixed != raw:
            open(path, "w", encoding="utf-8").write(fixed)


if __name__ == "__main__":
    main(sys.argv[1], "--apply" in sys.argv)
