"""Shared framework + rosters for the Y7-Y10 work-breakdown expander.

Emits JSON in the BRIEF.md schema. Every stream is filled to exactly its capacity by a
per-stream filler roster whose days are still unit-specific (IDs, region, system).
"""
import json
import os

OUT = os.path.dirname(os.path.abspath(__file__))
STREAMS = ["primary", "secondary", "art", "audio", "writing", "qa"]
TAGS = set("""code architecture cleanup tests systems combat animation cinematics story dialogue
quests openworld npc economy items ui ux audio music vfx assets art tools performance accessibility
localization save time difficulty fun release marketing legal team docs ai level business""".split())

# ----------------------------------------------------------------------------------------------
# Rosters (IDs are plan IDs; content behind them is defined by the Y2 world bible / Y3-Y6 GDDs)
# ----------------------------------------------------------------------------------------------
REGIONS = [
    ("R1", "Oakhaven", 1), ("R2", "Ironhold", 1), ("R3", "Fractured Wastes", 2),
    ("R4", "Mirror City", 2), ("R5", "Cathedral Server", 2), ("R6", "Memory Ocean", 3),
    ("R7", "Saved Assembly", 3), ("R8", "Root of Heaven", 4),
]
RNAME = {r: n for r, n, _ in REGIONS}
RACT = {r: a for r, _, a in REGIONS}

_BOSS_NAMES = {"B03": "Aldric Fen (Ch1 boss)", "B06": "Administrator Proxy (Ch2)",
               "B23": "SOVEREIGN", "B24": "the God King (true final boss)"}
BOSSES = []
_n = 1
for _r, _cnt in [("R1", 3), ("R2", 3), ("R3", 3), ("R4", 3), ("R5", 3), ("R6", 3), ("R7", 3), ("R8", 3)]:
    for _k in range(_cnt):
        bid = f"B{_n:02d}"
        BOSSES.append({"bid": bid, "rid": _r, "rname": RNAME[_r], "act": RACT[_r],
                       "bname": _BOSS_NAMES.get(bid, f"{_r} boss #{_k + 1}")})
        _n += 1

DIFFS = [
    {"diff": "Beginner", "d": "beginner", "parry": 12, "iframes": 18, "tele": "x1.5", "dmg": "x0.6", "heals": 5, "dda": "gentle DDA", "pat": "base patterns", "lean": "x1.5", "loot": "base loot"},
    {"diff": "Easy", "d": "easy", "parry": 9, "iframes": 15, "tele": "x1.25", "dmg": "x0.8", "heals": 4, "dda": "DDA on", "pat": "base patterns", "lean": "x1.25", "loot": "base loot"},
    {"diff": "Medium", "d": "medium", "parry": 6, "iframes": 12, "tele": "x1.0", "dmg": "x1.0", "heals": 3, "dda": "DDA off", "pat": "+variants", "lean": "x1.0", "loot": "+rare"},
    {"diff": "Hard", "d": "hard", "parry": 4, "iframes": 10, "tele": "x0.85", "dmg": "x1.3", "heals": 2, "dda": "DDA off", "pat": "+variants", "lean": "x1.0", "loot": "+epic"},
    {"diff": "Hell", "d": "hell", "parry": 2, "iframes": 8, "tele": "x0.7", "dmg": "x2.0", "heals": 1, "dda": "DDA off", "pat": "+Hell-only phase", "lean": "x0.85", "loot": "+Hell cosmetics/titles"},
]

STORYLINES = [{"sid": f"S{i:02d}", "kind": "storyline"} for i in range(1, 25)] + \
             [{"sid": f"SS{i}", "kind": "secret storyline"} for i in range(1, 4)]
TIMING = [("fast", "fast (early pace on every act)"), ("slow", "slow (late pace, waits and rests)"),
          ("ooo", "out-of-order (optional content before main beats, reversed quest order)")]

TQS = []
for _r, _c in [("R1", 5), ("R2", 5), ("R3", 4), ("R4", 4), ("R5", 4), ("R6", 5), ("R7", 5), ("R8", 8)]:
    for _k in range(1, _c + 1):
        TQS.append({"tq": f"{_r}-TQ-{_k:02d}", "rid": _r, "rname": RNAME[_r], "act": RACT[_r],
                    "ttype": ["window", "deadline", "order", "duration"][(len(TQS)) % 4]})

CGS = [f"CG{i:02d}" for i in range(1, 13)]          # 12 commodity groups x ~10 = ~120 commodities
AHS = [f"AH{i}" for i in range(1, 5)]                # 4 auction houses
GAMBLING = [("G1", "dice game"), ("G2", "card game"), ("G3", "arena-fight betting")]
MINIGAMES = [("M1", "fishing"), ("M2", "Root Access hacking puzzle"), ("M3", "forge timing game"),
             ("M4", "courier run"), ("M5", "festival rhythm game")]
CRAFT_TREES = [f"CT{i}" for i in range(1, 7)]

LOC_BATCHES = [
    ("LB01", "UI, menus, options, tutorials"), ("LB02", "items, affixes, sets, commodities"),
    ("LB03", "R1 Oakhaven main story + prologue"), ("LB04", "R1 side quests and barks"),
    ("LB05", "R2 Ironhold main story (Ch2)"), ("LB06", "R2 side quests, arena, Clock Tower"),
    ("LB07", "R3 Fractured Wastes"), ("LB08", "R4 Mirror City"), ("LB09", "R5 Cathedral Server"),
    ("LB10", "Act 2 side quests and side storylines"), ("LB11", "R6 Memory Ocean / Act 3 branch A"),
    ("LB12", "R7 Saved Assembly / Act 3 branch B"), ("LB13", "Act 3 branch C"),
    ("LB14", "Act 3 side quests and secret quests"), ("LB15", "R8 Root of Heaven / Act 4"),
    ("LB16", "ending composer slides (27 storylines)"), ("LB17", "Story+ chapters"),
    ("LB18", "Tier B / Tier C NPC barks and schedules"), ("LB19", "codex, bestiary, lore, secrets"),
    ("LB20", "store page, credits, legal, patch-note templates"),
]

SCREENS = [
    ("SC01", "main menu"), ("SC02", "difficulty select"), ("SC03", "options / settings"),
    ("SC04", "controls remap"), ("SC05", "latency calibration"), ("SC06", "overworld HUD"),
    ("SC07", "side-scroll combat HUD"), ("SC08", "dialogue box and choices"), ("SC09", "inventory"),
    ("SC10", "equipment (8 slots)"), ("SC11", "crafting / forge"), ("SC12", "stats and respec"),
    ("SC13", "quest log and deadlines"), ("SC14", "world map and fast travel"), ("SC15", "shop"),
    ("SC16", "market (commodities)"), ("SC17", "auction house"), ("SC18", "gambling tables"),
    ("SC19", "minigame hub"), ("SC20", "save / load"), ("SC21", "codex and bestiary"),
    ("SC22", "Story+ timing summary"), ("SC23", "pause menu"), ("SC24", "credits"),
]
A11Y_SYSTEMS = [
    ("AX01", "full input remapping (keyboard + gamepad), hold/toggle"),
    ("AX02", "subtitles, speaker labels, size and background"),
    ("AX03", "text scaling 100-200% across all UI"),
    ("AX04", "colourblind modes for telegraphs, rarity colours and map"),
    ("AX05", "screen shake / flash / glitch-overlay intensity"),
    ("AX06", "sound-cue visualisation for off-screen threats and boss tells"),
    ("AX07", "latency calibration and input-buffer display"),
    ("AX08", "deadline visibility: quest-log timers, warnings, signposts"),
    ("AX09", "one-handed presets and hold-to-confirm alternatives"),
    ("AX10", "assist options per the accessibility GDD (never alters Hell timing)"),
    ("AX11", "menu narration via Godot's AccessKit integration (feasibility + core menus)"),
    ("AX12", "haptics intensity and off switch"),
]
SYSTEMS = ["combat", "traversal", "streaming seams", "NPC schedules", "market", "auction",
           "crafting", "dialogue", "quest log", "save/load", "UI focus", "audio triggers",
           "cutscenes", "world clock", "Story+ state"]
SYS_SLUG = {s: s.replace("/", "_").replace(" ", "_").replace("+", "plus").lower() for s in SYSTEMS}
ANIM_GROUPS = [
    ("AN01", "locomotion (idle/walk/run/turn)"), ("AN02", "jump, fall, land"),
    ("AN03", "light attack chain"), ("AN04", "heavy attacks"), ("AN05", "aerial and pogo"),
    ("AN06", "parry and dodge"), ("AN07", "tools and abilities"), ("AN08", "Root Access slow-time"),
    ("AN09", "hurt, death, revive"), ("AN10", "interact, emotes, 4-direction top-down set"),
]
VFX_FAMILIES = [f"VF{i:02d}" for i in range(1, 11)]
MUSIC = [f"MT{i:02d}" for i in range(1, 46)]
SFXB = [f"SB{i:02d}" for i in range(1, 19)]
CAST_A = ["Kaelen", "Elara", "Seraphina", "Lyra", "Kaelthas", "Aldric", "Rook", "Brask", "Mara", "Bran"]
ENDING_FAMILIES = [("SOLE", "Sole Authority"), ("BOUND", "Bound Authority"),
                   ("NOAUTH", "No Authority"), ("CONSENT", "Consent (Witness Protocol)")]
ENEMIES = []
for _r, _c in [("R1", 6), ("R2", 6), ("R3", 7), ("R4", 7), ("R5", 6), ("R6", 6), ("R7", 6), ("R8", 6)]:
    for _k in range(_c):
        ENEMIES.append({"eid": f"E{len(ENEMIES) + 1:02d}", "rid": _r, "rname": RNAME[_r]})
ITEM_BATCHES = [(f"IB{i:02d}", f"items {(i - 1) * 25 + 1}-{i * 25}") for i in range(1, 19)]   # ~450 items
SIDE_QUEST_BATCHES = [(f"SQB{i:02d}", f"side quests {(i - 1) * 10 + 1}-{i * 10}") for i in range(1, 16)]  # 150
SECRET_BATCHES = [(f"SCB{i}", f"secret quests {(i - 1) * 5 + 1}-{i * 5}") for i in range(1, 7)]  # 30
SIDE_STORYLINES = [f"SSL{i:02d}" for i in range(1, 13)]
ARCHETYPES = [f"build archetype {i}" for i in range(1, 7)]
SEASONS = ["spring/summer", "autumn/winter"]

# ---- Console port (partner unnamed: "chosen partner"; platforms anonymised A/B/C) ----
PLATFORMS = [("CPA", "console platform A"), ("CPB", "console platform B"), ("CPC", "console platform C")]
CERT_CATS = [("CC01", "save data integrity and storage-full handling"), ("CC02", "user/account changes and sign-out"),
             ("CC03", "suspend/resume and backgrounding"), ("CC04", "controller disconnect and reassignment"),
             ("CC05", "offline / network-absent states"), ("CC06", "achievements/trophies"),
             ("CC07", "store, entitlements and DLC"), ("CC08", "age rating display and parental controls"),
             ("CC09", "platform terminology and button names"), ("CC10", "performance, load times, crash-free")]

# ---- Expansion 1: the two cut kingdoms ----
X1_REG = [("X1-R9", "Human Patch Lab"), ("X1-R10", "Forgotten Sectors")]
X1_CS = [(f"{r}-CS{k:02d}", r, n) for r, n in X1_REG for k in range(1, 7)]
X1_BOSSES = [("X1-B25", "X1-R9"), ("X1-B26", "X1-R9"), ("X1-B27", "X1-R10"), ("X1-B28", "X1-R10")]
X1_ENEMIES = [(f"X1-E{n}", "X1-R9" if n < 54 else "X1-R10") for n in range(51, 57)]
X1_ST = ["X1-ST1", "X1-ST2", "X1-ST3"]
X1_SQ = [(f"X1-SQ-{k:02d}", "X1-R9" if k <= 10 else "X1-R10") for k in range(1, 21)]
X1_TQ = [(f"X1-TQ-{k:02d}", ["window", "deadline", "order", "duration"][(k - 1) % 4]) for k in range(1, 7)]
X1_SC = [f"X1-SC-{k:02d}" for k in range(1, 5)]
X1_CM = [f"X1-CM-{k:02d}" for k in range(1, 17)]
X1_LE = [f"X1-LE-{k:02d}" for k in range(1, 7)]
X1_EV = [f"X1-EV-{k:02d}" for k in range(1, 9)]
X1_NB = [f"X1-NB-{k:02d}" for k in range(1, 13)]
X1_IS = [f"X1-IS-{k:02d}" for k in range(1, 9)]
X1_MT = [f"X1-MT-{k:02d}" for k in range(1, 7)]
X1_SB = [f"X1-SB-{k:02d}" for k in range(1, 5)]
X1_LB = [f"XLB{k:02d}" for k in range(1, 5)]

# ---- Expansion 2 (region chosen at the Y9 retrospective from the remaining blueprint kingdoms) ----
X2_CS = [f"X2-R11-CS{k:02d}" for k in range(1, 9)]
X2_BOSSES = ["X2-B29", "X2-B30", "X2-B31"]
X2_ENEMIES = [f"X2-E{n}" for n in range(57, 61)]
X2_ST = ["X2-ST1", "X2-ST2"]
X2_SQ = [f"X2-SQ-{k:02d}" for k in range(1, 16)]
X2_TQ = [f"X2-TQ-{k:02d}" for k in range(1, 6)]
X2_CM = [f"X2-CM-{k:02d}" for k in range(1, 13)]
X2_EV = [f"X2-EV-{k:02d}" for k in range(1, 7)]
X2_NB = [f"X2-NB-{k:02d}" for k in range(1, 11)]
X2_IS = [f"X2-IS-{k:02d}" for k in range(1, 7)]
X2_MT = [f"X2-MT-{k:02d}" for k in range(1, 6)]
X2_LB = [f"X2LB{k:02d}" for k in range(1, 4)]
SPX = [(f"SPX-{fid}-C{c}", fid, fname) for fid, fname in ENDING_FAMILIES for c in range(1, 4)]
NG_CYCLES = ["NG+1", "NG+2", "NG+3"]
ALL_BOSS_IDS = [b["bid"] for b in BOSSES] + [b for b, _ in X1_BOSSES]
LE_POST = [f"LE-P{k:02d}" for k in range(1, 13)]
QOL = [f"QoL-{k:02d}" for k in range(1, 9)]


_STEP_EXPAND = {
    "Record": "Record the result and date in {ev}",
    "Commit": "Commit with a Conventional Commits message citing the task ID (ask before committing)",
    "Close": "Close the fixed tickets with commit hashes",
    "Log": "Log findings with build id, platform and repro save in the tracker",
    "Capture": "Capture before/after screenshots into production/qa/evidence/",
    "Archive": "Archive the outputs with the build id next to {ev}",
    "Store": "Store the draft under {ev}",
    "Approve": "Get the user's approval before integrating",
    "Report": "Summarise results in the Sunday integration note",
    "Review": "Review with the user and note decisions",
    "Iterate": "Iterate once on the review notes",
    "Test": "Test in a debug build with debug_test_mode",
    "Fix": "Fix the issues found, data-first",
    "Mix": "Mix against the bus loudness targets",
    "Integrate": "Integrate into the build and play it once",
    "Tune": "Tune the data values and note each change",
    "zh-Hans": "Prepare the zh-Hans version",
    "Export": "Export to the project path following naming rules",
    "Preview": "Validate in a preview-only Godot scene",
    "Evidence": "Save evidence screenshots under production/qa/evidence/",
    "Act": "Act on the top three findings",
    "Actions": "Write actions with owners",
    "Track": "Track the result in the marketing log",
    "Post": "Post in the EN and zh-Hans channels",
    "Plan": "Plan the follow-up in the tracker",
    "Share": "Share the summary with the team",
    "Publish": "Publish after the user approves",
    "Schedule": "Schedule in the content calendar",
    "Index": "Index the archive contents",
    "Verify": "Verify against the acceptance criteria",
    "Docs": "Update the docs for this change",
    "Tests": "Add unit/integration tests for the change",
    "Deliver": "Deliver to the requesting stream",
    "Link": "Link the doc from docs/README.md",
    "Checksum": "Record checksums for the archive",
    "Video": "Attach a video of each failure",
    "Screenshots": "Take screenshots of each issue",
    "Status": "Post a status update",
    "FAQ": "Update the FAQ",
    "Lock": "Lock the mix and note the version",
    "Sign off": "Sign off in the QA log",
}


def expand_step(step, ev):
    s = _STEP_EXPAND.get(step)
    return s.format(ev=ev) if s else step


def D(focus, steps, done):
    assert 3 <= len(steps) <= 6, (focus, len(steps))
    return {"focus": focus, "steps": list(steps), "done": done}


class Phase:
    def __init__(self, pid, title, goal, exit_criteria, caps):
        self.pid, self.title, self.goal, self.exit = pid, title, goal, exit_criteria
        self.caps = caps
        self.head = {s: [] for s in STREAMS}
        self.main = {s: [] for s in STREAMS}
        self.series = {s: [] for s in STREAMS}
        self.tail = {s: [] for s in STREAMS}
        self.filler = {}

    @staticmethod
    def T(stream, title, why, tags, days, edge, evidence):
        for t in tags:
            assert t in TAGS, t
        assert days, title
        return {"stream": stream, "title": title, "why": why, "tags": tags, "days": days,
                "edge_cases": edge, "evidence": evidence}

    def move_before(self, stream, title, before_title):
        lst = self.main[stream]
        t = next(x for x in lst if x["title"] == title)
        lst.remove(t)
        idx = next(i for i, x in enumerate(lst) if x["title"] == before_title)
        lst.insert(idx, t)

    def anchor(self, task, frac):
        """Pin a main task to start near `frac` of the stream's capacity (e.g. a launch date)."""
        task["_anchor"] = frac
        return task

    def add(self, where, stream, *a, **k):
        t = self.T(stream, *a, **k)
        getattr(self, where)[stream].append(t)
        return t

    def fam(self, stream, title, why, tags, units, focus, steps, done, edge, evidence, where="main", chunk=None):
        """One task (or several of `chunk` days) whose days are generated per unit."""
        days = [D(focus(u), steps(u), done(u)) for u in units]
        if chunk is None:
            return self.add(where, stream, title, why, tags, days, edge, evidence)
        for k in range(0, len(days), chunk):
            part = days[k:k + chunk]
            self.add(where, stream, f"{title} ({k // chunk + 1}/{(len(days) + chunk - 1) // chunk})", why, tags, part, edge, evidence)

    def spec(self, stream, title, why, tags, rows, edge, evidence, where="main"):
        """rows: list of (focus, [steps], done)."""
        return self.add(where, stream, title, why, tags, [D(f, s, d) for f, s, d in rows], edge, evidence)

    def add_series(self, stream, tasks):
        if tasks:
            self.series[stream].append(tasks)

    def set_filler(self, stream, fn, chunk=5):
        self.filler[stream] = (fn, chunk)

    def counts(self):
        out = {}
        for s in STREAMS:
            n = sum(len(t["days"]) for grp in (self.head, self.main, self.tail) for t in grp[s])
            n += sum(len(t["days"]) for ser in self.series[s] for t in ser)
            out[s] = n
        return out

    def finalize(self):
        base = self.counts()
        ordered_all = []
        positions = {}
        for s in STREAMS:
            gap = self.caps[s] - base[s]
            if gap < 0:
                raise SystemExit(f"{self.pid} {s}: over capacity by {-gap} (base {base[s]} cap {self.caps[s]})")
            flex = []
            if gap > 0:
                fn, chunk = self.filler[s]
                days = [fn(i) for i in range(gap)]
                for c in range(0, gap, chunk):
                    flex.append(fn.task(days[c:c + chunk], c // chunk + 1))
            # Greedy weave: main tasks in order; dated series by evenly spaced targets; flexible filler
            # spread evenly but pulled forward when an anchored main task (e.g. launch) needs its date.
            total = sum(len(t["days"]) for t in self.main[s]) + sum(len(t["days"]) for ser in self.series[s] for t in ser) + gap
            head_days = sum(len(t["days"]) for t in self.head[s])
            fixed = []
            for si, ser in enumerate(self.series[s]):
                k = len(ser)
                fixed += [(((j + 0.5) / k) * total, si, j, t) for j, t in enumerate(ser)]
            fixed.sort(key=lambda x: (x[0], x[1], x[2]))
            body = []
            state = {"pos": 0, "flex_base": 0.0, "flex_n": len(flex)}

            def emit(t):
                body.append(t)
                state["pos"] += len(t["days"])

            def flex_target():
                done = state["flex_n"] - len(flex)
                span = total - state["flex_base"]
                return state["flex_base"] + (done + 0.5) * span / max(1, state["flex_n"])

            def drain(limit):
                while True:
                    ft = flex_target() if flex else None
                    xt = fixed[0][0] if fixed else None
                    cands = [c for c in ((xt, "x"), (ft, "f")) if c[0] is not None and c[0] <= limit]
                    if not cands:
                        return
                    if min(cands)[1] == "x":
                        emit(fixed.pop(0)[3])
                    else:
                        emit(flex.pop(0))

            for t in self.main[s]:
                if "_anchor" in t:
                    goal = t["_anchor"] * self.caps[s] - head_days
                    while state["pos"] < goal and (flex or (fixed and fixed[0][0] < goal)):
                        if fixed and fixed[0][0] <= state["pos"]:
                            emit(fixed.pop(0)[3])
                        elif flex:
                            emit(flex.pop(0))
                        else:
                            emit(fixed.pop(0)[3])
                    # re-spread the remaining filler after the anchor
                    state["flex_base"], state["flex_n"] = float(state["pos"]), len(flex)
                else:
                    drain(state["pos"])
                emit(t)
            drain(float("inf"))
            body += flex
            seq0 = self.head[s] + body + self.tail[s]
            seq = []
            for t in seq0:   # keep tasks to <= 12 days (brief: typically 1-12)
                n = len(t["days"])
                if n <= 12:
                    seq.append(t)
                    continue
                parts = -(-n // 12)
                size = -(-n // parts)
                for k in range(parts):
                    u = dict(t)
                    u["days"] = t["days"][k * size:(k + 1) * size]
                    u["title"] = f"{t['title']} (part {k + 1}/{parts})"
                    seq.append(u)
            cum = 0
            for t in seq:
                positions.setdefault(s, []).append((cum, t["title"]))
                cum += len(t["days"])
            ordered_all.extend(seq)
        for i, t in enumerate(ordered_all, 1):
            t["id"] = f"{self.pid}-T{i:03d}"
            ev = t["evidence"]
            t["days"] = [dict(d, steps=[expand_step(s, ev) for s in d["steps"]]) for d in t["days"]]
        tasks = [{"id": t["id"], "stream": t["stream"], "title": t["title"], "why": t["why"],
                  "tags": t["tags"], "days": t["days"], "edge_cases": t["edge_cases"],
                  "evidence": t["evidence"]} for t in ordered_all]
        doc = {"phase_id": self.pid, "phase_title": self.title, "goal": self.goal,
               "exit_criteria": self.exit, "tasks": tasks}
        path = os.path.join(OUT, f"{self.pid}.json")
        with open(path, "w", encoding="utf-8") as f:
            json.dump(doc, f, ensure_ascii=False, indent=1)
        return doc, positions


class Filler:
    """Callable day generator with a task factory for the filler roster."""

    def __init__(self, day_fn, title_fn, why, tags, edge, evidence, stream):
        self.day_fn, self.title_fn = day_fn, title_fn
        self.why, self.tags, self.edge, self.evidence, self.stream = why, tags, edge, evidence, stream

    def __call__(self, i):
        return self.day_fn(i)

    def task(self, days, n):
        return Phase.T(self.stream, self.title_fn(n), self.why, self.tags, days, self.edge, self.evidence)


# ----------------------------------------------------------------------------------------------
# "Every year" maintenance block, shared by Y7-Y10 (year-specific IDs keep days unique)
# ----------------------------------------------------------------------------------------------
def every_year(ph, Y, gate_label, patches, triage_n=12):
    """Adds live-ops cadence, tech debt, engine branch, deps/licences, backups, cleanliness, docs."""
    # Engine upgrade branch at the gate (primary, main, early)
    ph.add("main", "primary", f"{Y}: engine upgrade branch at {gate_label}",
           "Risk register: Godot version drift -> pin per gate, upgrade branch with the full suite (ROADMAP §13)",
           ["code", "architecture", "tests"],
           [D(f"{Y} engine branch: decide the candidate Godot version for {gate_label}",
              [f"Read the release notes and migration guide of the newest stable Godot release (check current docs; the pin is 4.6.x until changed by ADR)",
               f"List breaking changes that touch our code: grep `AethelgardPrototype/scripts/` for every API named in the migration notes",
               f"Create branch `engine/{Y.lower()}-candidate` from main; record the candidate and risks in `docs/architecture/engine-pin-{Y.lower()}.md`",
               "Confirm export templates for the candidate exist for every shipped platform (porting partner confirms console templates separately)"],
              f"`engine/{Y.lower()}-candidate` exists and the risk list in engine-pin-{Y.lower()}.md is complete"),
            D(f"{Y} engine branch: run the full suite on the candidate",
              ["Open the project once in the candidate editor headless to re-import; commit only `.import`/`.uid` churn on the branch",
               "Run `tests/run_all_tests.ps1`, the gdUnit4 suite and the nightly bot shard 1 on the branch",
               "Run `tools/export_windows.ps1 -Tour` on the branch and diff the screenshot tour against main's tour",
               "Run `/perf-profile` on the R4 Mirror City worst chunk on both builds; record frame-time deltas"],
              f"Test, tour and perf deltas for the {Y} candidate are recorded side by side"),
            D(f"{Y} engine branch: decide upgrade or hold, record the ADR",
              [f"Write `/architecture-decision` ADR 'Engine pin for {gate_label}': upgrade, hold, or defer, with the measured deltas",
               "If upgrading: list follow-up fixes as stories; if holding: delete nothing, keep the branch tagged for the next gate",
               "Update `docs/engine-reference/godot/VERSION.md` only if the pin changes; update CI's editor path",
               "Notify the team streams of any editor change (art/audio import settings re-check)"],
              f"ADR for the {Y} engine pin merged; CI points at the pinned editor")],
           ["Re-import changes `.uid` files in bulk", "A platform template lags the desktop release", "gdUnit4 incompatibility with the candidate"],
           f"docs/architecture/ADR engine pin {Y} + CI log of the candidate run")

    # Dependency and licence check (primary, main)
    ph.add("main", "primary", f"{Y}: dependency and licence check",
           "Risk register: legal (licences, AI disclosure) - audits recur yearly (ROADMAP §13)",
           ["legal", "code", "docs"],
           [D(f"{Y} dependency inventory",
              ["List every addon under `AethelgardPrototype/addons/`, every font, shader include and tool script dependency with version",
               "Diff against last year's `docs/legal/third_party_inventory.csv`; mark added, removed, upgraded",
               "For each new item record licence, source URL and who added it; flag unknown provenance",
               "Check Godot's own licence and third-party notices are still bundled in the export (verify against current Godot docs)"],
              f"{Y} third_party_inventory.csv updated with zero 'unknown' rows or each one has an owner"),
            D(f"{Y} licence compliance and AI-provenance spot check",
              ["Verify each licence's obligations (attribution, notice files, no-modification terms) are met in the credits and notices screen",
               "Spot-check 20 random assets under `assets/` against their provenance records (generator used, manual edits, licence)",
               "Run the AI-disclosure checklist against current store rules (check current Steam and platform rules)",
               "Write findings to `docs/legal/licence_audit_" + Y.lower() + ".md`; open issues for any gap"],
              f"Licence audit {Y} written; every gap has an issue")],
           ["An addon relicensed between versions", "Font licence forbids embedding in some platforms", "Asset with missing provenance record"],
           f"docs/legal/licence_audit_{Y.lower()}.md")

    # Tech debt: quarterly 2-day tasks (series)
    tasks = []
    for q in range(1, 5):
        tasks.append(Phase.T("primary", f"{Y} Q{q}: tech-debt scan and paydown",
                             "Coding standards + risk register (key-person risk): keep the codebase maintainable",
                             ["code", "cleanup", "architecture"],
                             [D(f"{Y} Q{q} tech-debt scan with /tech-debt",
                                ["Run `/tech-debt` over `AethelgardPrototype/scripts/` and update `docs/tech-debt-register.md`",
                                 "Re-run the R1/R2 lints: no `paused =` or `Engine.time_scale =` outside `scripts/core/context_stack.gd`, no `create_timer` in gameplay code",
                                 "Rank items by interest paid this quarter (bugs traced to them, time lost)",
                                 f"Pick the top item for {Y} Q{q} and write its acceptance test first"],
                                f"{Y} Q{q} register updated; one item selected with a failing test"),
                              D(f"{Y} Q{q} tech-debt paydown of the selected item",
                                ["Refactor behind the existing public API; keep doc comments on public functions",
                                 "Make the new test pass; run `tests/run_all_tests.ps1` and nightly bot shard on the branch",
                                 "Delete the replaced code path and any orphaned scene or resource it used",
                                 f"Mark the item closed in the register with the commit hash ({Y} Q{q})"],
                                f"{Y} Q{q} item closed, suite green, no dead path left")],
                             ["Refactor changes save data layout (needs explicit approval)", "Lint false positive in test code"],
                             f"docs/tech-debt-register.md diff for {Y} Q{q}"))
    ph.add_series("primary", tasks)

    # Archive and backup checks: quarterly 1 day (series, primary)
    tasks = []
    for q in range(1, 5):
        tasks.append(Phase.T("primary", f"{Y} Q{q}: archive and backup restore check",
                             "Operating rhythm: Git remote, off-site LFS copy and PAE project files (ROADMAP §14)",
                             ["tools", "release", "docs"],
                             [D(f"{Y} Q{q} restore drill from backups",
                                ["Clone the Git remote into an empty folder outside OneDrive and run `git lfs fetch --all`; compare object counts",
                                 "Restore the off-site LFS copy and the PAE project archive; verify checksums against `production/backup_manifest.csv`",
                                 "Open the restored project headless and run `tests/run_phase0_tests.ps1` from the restored copy",
                                 f"Archive this quarter's release builds and symbols; log the drill in `production/backup_log.md` ({Y} Q{q})"],
                                f"Restored copy boots and passes the smoke suite; {Y} Q{q} drill logged")],
                             ["LFS pointer without object", "Backup older than 7 days", "Symbol files missing for a shipped build"],
                             f"production/backup_log.md entry {Y} Q{q}"))
    ph.add_series("primary", tasks)

    # Codebase cleanliness pass (primary, main) + maintainer docs (primary, tail-ish main)
    ph.add("main", "primary", f"{Y}: codebase and project-folder cleanliness pass",
           "Clean project folder + code structure (user priority; CLAUDE.md directory rules)",
           ["cleanup", "code", "tests"],
           [D(f"{Y} cleanliness: orphan scan",
              ["List scenes, scripts and resources not referenced from any scene, autoload or test (extend `tests/load_all_test.gd` report)",
               "List `.uid` files without a sibling and import files without a source",
               "Compare top-level folders against `.claude/docs/directory-structure.md`; list strays",
               f"Write the candidate deletion list to `production/cleanup_{Y.lower()}.md` for approval"],
              f"cleanup_{Y.lower()}.md lists every orphan with a keep/delete proposal"),
            D(f"{Y} cleanliness: remove approved orphans",
              ["Delete only the approved entries; keep review-only art under `assets/art_sources` per AGENTS.md",
               "Run `tests/run_all_tests.ps1` and the export build to prove nothing referenced them",
               "Move misplaced docs into `docs/` subfolders and fix links",
               "Commit as `chore: cleanliness pass " + Y + "`"],
              f"Approved orphans removed; suite and export green"),
            D(f"{Y} cleanliness: naming and structure lint",
              ["Run the naming lint (snake_case files, PascalCase classes) over `scripts/` and `scenes/`",
               "Check every autoload has one owner and a doc comment (R7: one owner per concern)",
               "Check tests live under `tests/unit` or `tests/integration` with the per-system folder",
               "Record remaining exceptions with reasons in the cleanup doc"],
              f"Naming/structure lint clean or exceptions documented for {Y}")],
           ["Resource loaded by string path at runtime (not visible to static scan)", "Asset referenced only by a localized string table"],
           f"production/cleanup_{Y.lower()}.md + green CI run")

    ph.add("main", "primary", f"{Y}: maintainer documentation refresh",
           "Risk register: key-person risk -> ADRs, tests, onboarding docs (ROADMAP §13)",
           ["docs", "team"],
           [D(f"{Y} maintainer docs: architecture and runbooks",
              ["Refresh `docs/architecture/overview.md` with this year's systems and owners",
               "Update runbooks: build (`tools/export_windows.ps1`), release, hotfix, save migration, backup restore",
               "Verify each runbook by following it literally on a clean checkout",
               "Link every runbook from `docs/README.md`"],
              f"{Y} runbooks verified on a clean checkout"),
            D(f"{Y} maintainer docs: onboarding and system index",
              ["Run `/onboard` for the roles 'gameplay programmer' and 'content designer' and fold the output into `docs/onboarding/`",
               "Update the system index: each autoload/service, its tests and its ADRs",
               "List open questions a new maintainer would hit; answer or ticket each",
               "Ask a team member to follow the onboarding doc for 1 hour and note friction"],
              f"{Y} onboarding doc tested by a second person")],
           ["Runbook step depends on a local path under OneDrive", "Doc references a deleted script"],
           f"docs/onboarding/ + docs/architecture/overview.md ({Y})")

    # Live ops: patches -> primary build day + secondary patch notes day (series)
    prim, sec = [], []
    for p in patches:
        prim.append(Phase.T("primary", f"Ship {p}", "Live-ops cadence: green CI, migrated saves, honest notes (ROADMAP §9, Gate 4 rules)",
                            ["release", "tests", "save"],
                            [D(f"Build, verify and release {p}",
                               [f"Cut `release/{p}` from main; run `/smoke-check` and `/regression-suite` on it",
                                f"Run the save-compatibility CI job: load every fixture under `tests/fixtures/saves/` into {p}; 100% must migrate",
                                f"Export with `tools/export_windows.ps1`; run the screenshot tour on the export; archive symbols",
                                f"Publish {p} to a beta branch first, then default after 24 h of clean crash data (check current store tooling)"],
                               f"{p} live; save migration 100%; crash-free rate logged")],
                            ["Hot path regression only visible on export build", "Save from an abandoned beta branch"],
                            f"CI run for release/{p} + production/releases/{p}.md"))
        sec.append(Phase.T("secondary", f"Patch notes and community post for {p}", "Live-ops cadence: player communication (/patch-notes)",
                           ["release", "marketing", "docs"],
                           [D(f"{p}: patch notes and community update",
                              [f"Run `/patch-notes` over the `release/{p}` commits and the changelog",
                               "Rewrite developer terms into player language; call out economy or difficulty changes explicitly",
                               "Get the zh-Hans translation of the notes from the writing stream and check names against the glossary",
                               f"Post notes; pin known issues; log community questions in `production/community/{p}.md`"],
                              f"{p} notes published in EN and zh-Hans")],
                           ["Patch changes a missable deadline (must be called out)", "Fix that alters an exploit players rely on"],
                           f"production/community/{p}.md"))
    ph.add_series("primary", prim)
    ph.add_series("secondary", sec)

    tri = []
    for w in range(1, triage_n + 1):
        tri.append(Phase.T("secondary", f"{Y} bug triage round {w:02d}", "Live-ops cadence: /bug-triage keeps severity honest",
                           ["release", "tests", "team"],
                           [D(f"{Y} triage round {w:02d}",
                              ["Run `/bug-triage` over all open issues; re-score severity vs priority",
                               "Merge duplicates from community reports into existing issues with repro steps",
                               f"Assign round {w:02d} fixes to the next patch; anything critical goes to the hotfix lane",
                               "Note systemic trends (same system 3+ times) in `production/qa/trends.md`"],
                              f"{Y} round {w:02d}: no untriaged issue older than the last round")],
                           ["Report from a modded install", "Bug only on zh-Hans locale"],
                           f"production/qa/trends.md ({Y} round {w:02d})"))
    ph.add_series("secondary", tri)
