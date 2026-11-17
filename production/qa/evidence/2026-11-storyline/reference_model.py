"""Non-shipping reference model of the storyline axes and lifecycle (storyline-axes.md Open Question 16).

Implements, independently of the GDD text (it parses nothing), the Formulas of design/gdd/storyline-axes.md
(rev 10) and storyline-lifecycle.md (rev 6): formula_id, prereqs_met, family, lock_pass, phase_of, load_check
(Edge Case 16: D1, D6-D9, D14-D17) and crisis_offers; then walks the lifecycle transitions T1-T9 breadth-first
for every seed context the game code allows, and asserts:

  A1  every reachable save passes load_check
  A2  every reachable save loads to the phase it was saved in (never DAMAGED); a save inside Root of Heaven
      passes the load-path gate unchanged
  A3  no save is positioned inside a suppression window (I9)
  A4  every reachable non-FINAL state has an event leading to a different state
  A5  a FINAL state is reachable from every reachable state (no soft-lock, I5)
  A6  a stored ID never changes (I3)
  A7  nothing is offered once an ID is stored (I7)
  A8  the live phase is CRISIS only inside C8-S16, and no live state is DAMAGED (I2)
  A9  only T1-T5 change an axis value (I1)
  A10 every entry into Root of Heaven goes through the gate, and only with an ID stored (I4)
  A11 a state without a stored ID is before the C8-S16 commit; every crisis offer reaches a valid row (I5)
  A12 family(stored ID) is the Authority value's family (I8)
  A13 T5 post-conditions (lifecycle L-AC7)
  A14 the walk reaches exactly the 24 valid IDs, takes all 16 crisis offers and plays all 16 beats

plus the unit tables of axes AC5-AC9 and lifecycle L-AC2/L-AC3/L-AC5/L-AC8, a clause-isolation search for the
AC9 one-defect fixtures, a probe for records load_check accepts that play never writes, and negative controls
(defects seeded into the model; each must make at least one assertion fail).

Revision 10 (design review round 10, 2026-11-17): the model implements the rev 10 text (REV10) and keeps the
rev 9 text (LITERAL) as a regression that must still fail (F1, F2, F9). The residuals F5, F7 and F10 are
best-effort by decision (axes Open Question 17): they are reported, not asserted.

Usage: python -I -B reference_model.py [--quick]
Exit status: 0 when every assertion and unit check passes under the rev 10 text, the rev 9 text still fails as
expected, every negative control is caught and every AC9 clause is isolatable (D17's prefix clause is documentation
only); 1 otherwise.
"""
import argparse
import itertools
import sys
import time
from collections import defaultdict, deque, namedtuple

sys.stdout.reconfigure(encoding="utf-8")

# ---------------------------------------------------------------------------------------------------------------
# Constants (storyline-axes.md Core Rules, tables and Tuning Knobs; lifecycle S1-S7)
# ---------------------------------------------------------------------------------------------------------------
UNSET = "UNSET"
LOCK_ORDER = ("faction", "authority", "deleted")
VALUES = {"authority": ("YOU", "SHARED", "NONE"),
          "faction": ("HEARTH", "ARCHIVE", "CONTINUITY"),
          "deleted": ("RESTORE", "RELEASE", "CHOOSE")}
RULES = {"R1": ("YOU", "HEARTH", "RESTORE"), "R2": ("NONE", "ARCHIVE", "RELEASE"),
         "R3": ("NONE", "CONTINUITY", "RELEASE")}          # rows are (authority, faction, deleted)
ROW_RULE = {row: rule for rule, row in RULES.items()}
TRANSFORM = {"R1": "WITNESS", "R2": "CROWNLESS", "R3": "FIRSTWAKE"}
ROUTES = ("WITNESS", "CROWNLESS", "FIRSTWAKE")
SECRET_PREREQS = {
    "WITNESS": ("WITNESS_PROTOCOL_FOUND", "OLD_WITNESS_SIGNATURE", "WITNESS_SEATS"),
    "CROWNLESS": ("CROWN_COORDINATES", "EMPTY_THRONE_FOUND", "CROWN_SNAPSHOT_FOUND", "NO_CROWN_CHARTER"),
    "FIRSTWAKE": ("OLD_HOME_MESSAGE", "FOURTH_HYMN_FOUND", "EXTERNAL_PING_FOUND", "EXTERNAL_CARRIER"),
}
ALL_PREREQ_FLAGS = frozenset(f for fl in SECRET_PREREQS.values() for f in fl)
DEFAULT_KNOBS = {r: False for r in ROUTES}
FAMILY_OF = {"YOU": "SOLE", "SHARED": "BOUND", "NONE": "NONE_AUTH"}
DIGITS = {"faction": 1, "authority": 2, "deleted": 3}   # unused by logic; documents AXIS1/2/3 naming

# Act 1 axis seeds (seed map rows whose `pushes` is an axis). Modifier and timing rows lean nowhere and are not
# read by lock_pass, so the walk leaves them out of the seed contexts.
AXIS_SEEDS = (
    ("act1_report_local", "faction", "HEARTH", "+"),
    ("act1_report_archive", "faction", "ARCHIVE", "+"),
    ("act1_report_command", "faction", "CONTINUITY", "+"),
    ("ch1_knight_killed", "faction", "HEARTH", "-"),
    ("ch1_root_purge", "faction", "HEARTH", "+"),
    ("ch2_data_wraith_restored", "deleted", "RESTORE", "+"),
    ("ch2_data_wraith_destroyed", "deleted", "RELEASE", "+"),
    ("ch2_data_wraith_absorbed", "deleted", "CHOOSE", "+"),
    ("ch1_aldric_kill_owned", "authority", "YOU", "+"),
    ("ch1_aldric_kill_justified", "authority", "YOU", "+"),
    ("ch1_aldric_kill_unsure", "authority", "SHARED", "+"),
    ("ch1_root_first_edit", "authority", "YOU", "+"),
    ("ch1_root_discovered_unused", "authority", "NONE", "+"),
)
# AethelgardPrototype/scripts/game_manager.gd:710-719 (EXCLUSIVE_FLAG_GROUPS)
EXCLUSIVE_GROUPS = (
    ("ch1_elara_trusted", "ch1_elara_cautious", "ch1_elara_distrusted"),
    ("ch1_knight_spared", "ch1_knight_killed"),
    ("ch2_seraphina_recruited", "ch2_seraphina_stayed", "ch2_seraphina_rejected"),
    ("ch2_data_wraith_absorbed", "ch2_data_wraith_restored", "ch2_data_wraith_destroyed"),
    ("ch3_kaelthas_allied", "ch3_kaelthas_refused", "ch3_kaelthas_challenged"),
    ("ch3_sovereign_defiant", "ch3_sovereign_regretful", "ch3_sovereign_doubting"),
    ("ch3_lyra_recruited", "ch3_lyra_left_alone"),
    ("ch1_oakhaven_warned_villagers", "ch1_oakhaven_left_quietly"),
)
# Lifecycle retraction table: what is withdrawn on the record, per axis and superseded value.
WITHDRAWN = {
    "faction": {"HEARTH": "Hearth mutual-defense charter", "ARCHIVE": "Archive public evidence charter",
                "CONTINUITY": "Continuity League emergency operations network"},
    "authority": {"YOU": "Kaelen's vow and chosen commitment", "SHARED": "seven-signature protocol",
                  "NONE": "dismantling commitment"},
    "deleted": {"RESTORE": "restore policy", "RELEASE": "release policy", "CHOOSE": "choose policy"},
}

# Story positions, in story order. *_OPEN = inside a scene before its commit (I9 suppression window).
POSITIONS = ("PRE_C8", "S13_OPEN", "S13_DONE", "S14_OPEN", "S14_DONE", "S15", "S16_OPEN", "S16_DONE", "CH9",
             "ROOT", "ROOT_LEFT", "FINAL_AUTH_OPEN", "FINAL_DONE", "STORY_PLUS", "ROOT_STORY_PLUS")
PIDX = {p: i for i, p in enumerate(POSITIONS)}
SPEC_WINDOWS = frozenset({"S13_OPEN", "S14_OPEN", "S16_OPEN", "FINAL_AUTH_OPEN"})
LOCK_DONE = {"faction": PIDX["S13_DONE"], "authority": PIDX["S14_DONE"], "deleted": PIDX["S16_DONE"]}
ROOT_POSITIONS = frozenset({"ROOT", "FINAL_AUTH_OPEN", "FINAL_DONE", "ROOT_STORY_PLUS"})

Record = namedtuple("Record", "authority faction deleted storyline_id root_phase axis_revised lock_negotiated "
                              "retraction_log beats_played")
Entry = namedtuple("Entry", "axis old new withdrawn_item scene")
EMPTY = Record(UNSET, UNSET, UNSET, "", "OUTSIDE", frozenset(), frozenset(), (), frozenset())


def row_of(rec):
    return (rec.authority, rec.faction, rec.deleted)


def with_axis(row, axis, value):
    a, f, d = row
    return {"authority": (value, f, d), "faction": (a, value, d), "deleted": (a, f, value)}[axis]


def invalid(a, f, d):
    return (a, f, d) in ROW_RULE


VALID_IDS = tuple(f"SL-{a}-{f}-{d}" for a in VALUES["authority"] for f in VALUES["faction"]
                  for d in VALUES["deleted"] if not invalid(a, f, d))
SECRET_IDS = tuple(f"SL-SECRET-{r}" for r in ROUTES)
INVALID_IDS = tuple(f"SL-{a}-{f}-{d}" for (a, f, d) in RULES.values())

# ---------------------------------------------------------------------------------------------------------------
# Formulas
# ---------------------------------------------------------------------------------------------------------------


def prereqs_met(route, knobs, flags, prereqs=SECRET_PREREQS):
    lst = prereqs[route]
    return len(lst) >= 2 and all(f in flags for f in lst)


def formula_id(a, f, d, invoked, knobs, flags, prereqs=SECRET_PREREQS):
    if UNSET in (a, f, d):
        return "PENDING"
    if not invalid(a, f, d):
        return f"SL-{a}-{f}-{d}"
    route = TRANSFORM[ROW_RULE[(a, f, d)]]
    if invoked and knobs[route] and prereqs_met(route, knobs, flags, prereqs):
        return "SL-SECRET-" + route
    return "CRISIS"


def family(sid):
    if sid in SECRET_IDS:
        return "RESERVED"
    if sid in VALID_IDS:
        return FAMILY_OF[sid.split("-")[1]]
    return "NO_FAMILY"


def lock_pass(flags, axis, value):
    plus = any(fl in flags for fl, ax, v, s in AXIS_SEEDS if ax == axis and v == value and s == "+")
    minus = any(fl in flags for fl, ax, v, s in AXIS_SEEDS if ax == axis and v == value and s == "-")
    return "CLEAN" if plus and not minus else "NEGOTIATED"


def crisis_offers(row):
    if row not in ROW_RULE:
        return ()
    out = []
    for axis in ("authority", "faction", "deleted"):
        cur = row[("authority", "faction", "deleted").index(axis)]
        for v in VALUES[axis]:
            if v != cur and not invalid(*with_axis(row, axis, v)):
                out.append(f"revise:{axis}:{v}")
    return tuple(out)


DEFINED_BEATS = frozenset(f"retract_{rule}_{o.split(':')[1]}_{o.split(':')[2]}"
                          for rule, row in RULES.items() for o in crisis_offers(row))


def beat_for_entry(rec, e):
    """The beat id a retraction entry implies: the rule of the row before the renegotiation."""
    try:
        before = with_axis(row_of(rec), e.axis, e.old)
    except KeyError:
        return None
    rule = ROW_RULE.get(before)
    return f"retract_{rule}_{e.axis}_{e.new}" if rule else None


def red_line(authority, faction):
    """S3: the rule voiced when the locked pair is one Deleted value away from an invalid row."""
    rules = {ROW_RULE[(authority, faction, d)] for d in VALUES["deleted"] if (authority, faction, d) in ROW_RULE}
    return rules


class Reading:
    """Which text the model implements. REV10 is the current text (design review round 10); LITERAL is the revision 9
    text, kept as a regression: the model must still find F1, F2 and F9 in it."""

    def __init__(self, name, d17_before_commit_live=True, d14_match="strict", d7_reverse=False,
                 gate_damaged_row=False):
        self.name = name
        self.d17_before_commit_live = d17_before_commit_live   # rev 9: D17 clause (a) also tested on live records
        self.d14_match = d14_match                             # strict: beat id must equal beat_for_entry()
        self.d7_reverse = d7_reverse                           # rev 10: a log entry whose axis is not in axis_revised
        self.gate_damaged_row = gate_damaged_row               # rev 10: a live DAMAGED record at the gate is turned back


LITERAL = Reading("rev 9 text, literal")
REV10 = Reading("rev 10 text", d17_before_commit_live=False, d7_reverse=True, gate_damaged_row=True)


def load_check_tags(rec, flags, pos, loaded, reading=LITERAL):
    tags = set()
    a, f, d = row_of(rec)
    sid = rec.storyline_id
    pi = PIDX[pos]
    # D1
    if sid:
        if sid.startswith("SL-SECRET-"):
            tags.add("D1.secret")
        elif UNSET in (a, f, d):
            tags.add("D1.unset_axis")
        elif invalid(a, f, d):
            tags.add("D1.invalid_row")
        elif sid != f"SL-{a}-{f}-{d}":
            tags.add("D1.other_id")
    # D6
    if rec.axis_revised - rec.lock_negotiated:
        tags.add("D6")
    # D7
    named = {e.axis for e in rec.retraction_log}
    if rec.axis_revised - named:
        tags.add("D7.unnamed")
    if len(rec.axis_revised) > 1:
        tags.add("D7.multi")
    if any(e.new != getattr(rec, e.axis) for e in rec.retraction_log):
        tags.add("D7.new_mismatch")
    if reading.d7_reverse and any(e.axis not in rec.axis_revised for e in rec.retraction_log):
        tags.add("D7.reverse")
    # D8
    if rec.root_phase in ("INSIDE", "FINAL") and not sid:
        tags.add("D8")
    # D9
    if loaded and UNSET not in (a, f, d) and not sid:
        tags.add("D9")
    # D14
    implied = {beat_for_entry(rec, e) for e in rec.retraction_log}
    for b in rec.beats_played:
        if b.startswith("retract_"):
            if b not in DEFINED_BEATS:
                tags.add("D14.undefined")
            elif b not in implied:
                if reading.d14_match == "strict" or not any(b.split("_")[2] == e.axis for e in rec.retraction_log):
                    tags.add("D14.no_entry")
    for e in rec.retraction_log:
        bid = beat_for_entry(rec, e)
        if bid is None or bid not in rec.beats_played:
            if reading.d14_match == "strict" or not any(b.split("_")[2] == e.axis for b in rec.beats_played
                                                         if b.startswith("retract_")):
                tags.add("D14.not_played")
    # D15
    if any(sum(fl in flags for fl in g) > 1 for g in EXCLUSIVE_GROUPS):
        tags.add("D15")
    # D16
    if any(getattr(rec, ax) == UNSET and pi >= LOCK_DONE[ax] for ax in LOCK_ORDER):
        tags.add("D16")
    # D17
    setmask = [getattr(rec, ax) != UNSET for ax in LOCK_ORDER]
    if setmask not in ([False] * 3, [True, False, False], [True, True, False], [True] * 3):
        tags.add("D17.prefix")
    if loaded or reading.d17_before_commit_live:
        if any(getattr(rec, ax) != UNSET and pi < LOCK_DONE[ax] for ax in LOCK_ORDER):
            tags.add("D17.before_commit")
    return tags


def items(tags):
    return {t.split(".")[0] for t in tags}


def load_check(rec, flags, pos, reading=LITERAL):
    return items(load_check_tags(rec, flags, pos, True, reading))


def phase_of(rec, loaded, flags, pos, reading=LITERAL):
    if load_check_tags(rec, flags, pos, loaded, reading):
        return "DAMAGED"
    sid = rec.storyline_id
    if sid and rec.root_phase == "FINAL":
        return "FINAL"
    if sid and rec.root_phase == "INSIDE":
        return "FIXED"
    if sid:
        return "VALIDATED"
    r = row_of(rec)
    if all(v == UNSET for v in r):
        return "LEANING"
    if UNSET in r:
        return "PARTLY_LOCKED"
    return "CRISIS"


# ---------------------------------------------------------------------------------------------------------------
# Lifecycle transitions (storyline-lifecycle.md States and Transitions)
# ---------------------------------------------------------------------------------------------------------------
DEFECTS = {
    "t4_checkpoint": "T4 writes a checkpoint (a save inside the crisis)",
    "save_in_crisis": "manual save allowed inside C8-S16",
    "save_in_final_auth": "manual save allowed inside the final authorization",
    "t3_no_store": "T3 sets the Deleted value but does not store the ID",
    "r2_no_offers": "the crisis offers nothing on R2",
    "r1_drops_offer": "the crisis drops revise:deleted:CHOOSE on R1",
    "offers_after_store": "C8-S16 still offers renegotiations after the ID is stored",
    "t5_no_axis_revised": "T5 does not add the axis to axis_revised",
    "t5_no_beat": "T5 records the retraction but plays no beat",
    "lock_order_skip": "the story graph can start C8-S16 straight after C8-S13",
    "gate_skip_world_map": "the world-map path enters Root of Heaven without the gate check",
    "id_recomputed_at_gate": "the gate recomputes the ID from the axes with the Deleted value swapped",
}


def offers(rec, pos, defects):
    if pos == "S16_OPEN" and not rec.storyline_id and UNSET not in row_of(rec):
        out = crisis_offers(row_of(rec))
        if "r2_no_offers" in defects and row_of(rec) == RULES["R2"]:
            out = ()
        if "r1_drops_offer" in defects and row_of(rec) == RULES["R1"]:
            out = tuple(o for o in out if o != "revise:deleted:CHOOSE")
        return out
    if "offers_after_store" in defects and pos == "S16_DONE" and rec.storyline_id:
        return tuple(f"revise:deleted:{v}" for v in VALUES["deleted"]
                     if v != rec.deleted and not invalid(*with_axis(row_of(rec), "deleted", v)))
    return ()


def lock(rec, flags, axis, value):
    neg = rec.lock_negotiated | {axis} if lock_pass(flags, axis, value) == "NEGOTIATED" else rec.lock_negotiated
    return rec._replace(**{axis: value, "lock_negotiated": frozenset(neg)})


def gate(rec, flags, pos, target, kind_prefix, defects, reading):
    ph = phase_of(rec, False, flags, pos, reading)
    if ph in ("LEANING", "PARTLY_LOCKED"):
        return [(kind_prefix + ":TURNED_BACK", "T6", rec, pos, False)]
    if ph == "VALIDATED":
        new = rec._replace(root_phase="INSIDE")
        if "id_recomputed_at_gate" in defects:
            alt = [v for v in VALUES["deleted"] if v != rec.deleted
                   and not invalid(*with_axis(row_of(rec), "deleted", v))][0]
            new = new._replace(storyline_id=f"SL-{rec.authority}-{rec.faction}-{alt}")
        return [(kind_prefix + ":ROOT_OF_HEAVEN", "T7", new, target, True)]
    if ph in ("FIXED", "FINAL"):
        return [(kind_prefix + ":ROOT_OF_HEAVEN", "T8", rec, target, False)]
    if ph == "DAMAGED" and reading.gate_damaged_row:   # rev 10, lifecycle S6: a data error, no transition
        return [(kind_prefix + ":TURNED_BACK:DAMAGED", "GATE_DAMAGED", rec, pos, False)]
    return [(kind_prefix + ":GATE_ERROR:" + ph, "GATE_ERROR", rec, pos, False)]


def events(rec, pos, flags, knobs, defects, reading):
    """Every event enabled in (rec, pos): (label, kind, new_rec, new_pos, checkpoint)."""
    out = []
    a, f, d = row_of(rec)
    if pos == "PRE_C8":
        out.append(("start C8-S13", "move", rec, "S13_OPEN", False))
    elif pos == "S13_OPEN" and (a, f, d) == (UNSET,) * 3:
        out += [(f"T1 back {v}", "T1", lock(rec, flags, "faction", v), "S13_DONE", True)
                for v in VALUES["faction"]]
    elif pos == "S13_DONE":
        out.append(("start C8-S14", "move", rec, "S14_OPEN", False))
        if "lock_order_skip" in defects:
            out.append(("start C8-S16 (skip)", "move", rec, "S16_OPEN", False))
    elif pos == "S14_OPEN" and f != UNSET and a == UNSET:
        out += [(f"T2 back {v}", "T2", lock(rec, flags, "authority", v), "S14_DONE", True)
                for v in VALUES["authority"]]
    elif pos == "S14_DONE":
        out.append(("start C8-S15", "move", rec, "S15", False))
    elif pos == "S15":
        out.append(("start C8-S16", "move", rec, "S16_OPEN", False))
    elif pos == "S16_OPEN" and f != UNSET and d == UNSET:
        for v in VALUES["deleted"]:
            new = lock(rec, flags, "deleted", v)
            if UNSET in row_of(new):
                continue                     # no row: the scene cannot resolve (only reachable by a defect)
            if not invalid(*row_of(new)):
                sid = "" if "t3_no_store" in defects else formula_id(*row_of(new), False, knobs, flags)
                out.append((f"T3 back {v}", "T3", new._replace(storyline_id=sid), "S16_DONE", True))
            else:
                out.append((f"T4 back {v}", "T4", new, "S16_OPEN", "t4_checkpoint" in defects))
    elif pos == "S16_OPEN" and not rec.storyline_id and UNSET not in (a, f, d):
        rule = ROW_RULE[(a, f, d)]
        for o in offers(rec, pos, defects):
            _, axis, v = o.split(":")
            old = getattr(rec, axis)
            new = rec._replace(**{axis: v})
            entry = Entry(axis, old, v, WITHDRAWN[axis][old], "C8-S16")
            beats = rec.beats_played if "t5_no_beat" in defects else rec.beats_played | {f"retract_{rule}_{axis}_{v}"}
            revised = rec.axis_revised if "t5_no_axis_revised" in defects else rec.axis_revised | {axis}
            new = new._replace(axis_revised=frozenset(revised), lock_negotiated=rec.lock_negotiated | {axis},
                               retraction_log=rec.retraction_log + (entry,), beats_played=frozenset(beats),
                               storyline_id=formula_id(*row_of(new), False, knobs, flags))
            out.append((f"T5 take {o}", "T5", new, "S16_DONE", True))
    elif pos == "S16_DONE":
        out.append(("leave C8-S16", "move", rec, "CH9", False))
        for o in offers(rec, pos, defects):
            _, axis, v = o.split(":")
            new = rec._replace(**{axis: v})
            new = new._replace(storyline_id=formula_id(*row_of(new), False, knobs, flags))
            out.append((f"late take {o}", "LATE_OFFER", new, "S16_DONE", True))
    elif pos == "CH9":
        out += gate(rec, flags, pos, "ROOT", "story gate", defects, reading)
    elif pos == "ROOT":
        out.append(("leave Root of Heaven", "move", rec, "ROOT_LEFT", False))
        out.append(("defeat the boss", "move", rec, "FINAL_AUTH_OPEN", False))
    elif pos == "ROOT_LEFT":
        if "gate_skip_world_map" in defects:
            out.append(("world_map enter (no gate)", "move", rec, "ROOT", False))
        else:
            out += gate(rec, flags, pos, "ROOT", "world_map gate", defects, reading)
    elif pos == "FINAL_AUTH_OPEN":
        out.append(("T9 confirm_execution", "T9", rec._replace(root_phase="FINAL"), "FINAL_DONE", True))
    elif pos == "FINAL_DONE":
        out.append(("enter Story+", "move", rec, "STORY_PLUS", False))
    elif pos == "STORY_PLUS":
        out += gate(rec, flags, pos, "ROOT_STORY_PLUS", "world_map gate", defects, reading)
    elif pos == "ROOT_STORY_PLUS":
        out.append(("leave Root of Heaven", "move", rec, "STORY_PLUS", False))
    return out


def model_windows(defects):
    w = set(SPEC_WINDOWS)
    if "save_in_crisis" in defects:
        w.discard("S16_OPEN")
    if "save_in_final_auth" in defects:
        w.discard("FINAL_AUTH_OPEN")
    return w


# ---------------------------------------------------------------------------------------------------------------
# Walk
# ---------------------------------------------------------------------------------------------------------------
def walk(flags, knobs=DEFAULT_KNOBS, defects=frozenset(), reading=LITERAL):
    start = (EMPTY, "PRE_C8")
    seen = {start}
    q = deque([start])
    edges = []
    while q:
        s = q.popleft()
        for label, kind, nrec, npos, ckpt in events(*s, flags, knobs, defects, reading):
            t = (nrec, npos)
            edges.append((s, label, kind, t, ckpt))
            if t not in seen:
                seen.add(t)
                q.append(t)
    windows = model_windows(defects)
    saves = {s for s in seen if s[1] not in windows} | {e[3] for e in edges if e[4]}
    return seen, edges, saves


def check_walk(flags, seen, edges, saves, reading, fails, stats):
    """Assertions A1-A13 over one walk; append (assertion, message) to fails."""
    def fail(code, msg):
        fails.append((code, msg))

    for rec, pos in saves:
        lc = load_check(rec, flags, pos, reading)
        if lc:
            fail("A1", f"save at {pos} {short(rec)} -> load_check {sorted(lc)}")
            continue
        lp = phase_of(rec, True, flags, pos, reading)
        live = phase_of(rec, False, flags, pos, reading)
        if lp == "DAMAGED" or lp != live:
            fail("A2", f"save at {pos} {short(rec)} loads {lp}, saved as {live}")
        if pos in ROOT_POSITIONS and lp not in ("FIXED", "FINAL"):
            fail("A2", f"save inside Root of Heaven at {pos} {short(rec)} loads {lp}: the load-path gate would not "
                       f"pass it unchanged")
        if pos in SPEC_WINDOWS:
            fail("A3", f"save inside suppression window {pos} {short(rec)}")
    out = defaultdict(list)
    for e in edges:
        out[e[0]].append(e)
    phase = {s: phase_of(s[0], False, flags, s[1], reading) for s in seen}
    for s in seen:
        if phase[s] != "FINAL" and not any(e[3] != s for e in out[s]):
            fail("A4", f"no way forward from {s[1]} {short(s[0])} (phase {phase[s]})")
    # A5: reverse reachability from FINAL states
    rev = defaultdict(list)
    for e in edges:
        rev[e[3]].append(e[0])
    good = {s for s in seen if phase[s] == "FINAL"}
    q = deque(good)
    while q:
        t = q.popleft()
        for s in rev[t]:
            if s not in good:
                good.add(s)
                q.append(s)
    for s in seen - good:
        fail("A5", f"FINAL unreachable from {s[1]} {short(s[0])} (phase {phase[s]})")
    for s, label, kind, t, ck in edges:
        if s[0].storyline_id and t[0].storyline_id != s[0].storyline_id:
            fail("A6", f"stored ID changed {s[0].storyline_id} -> {t[0].storyline_id!r} by '{label}'")
        if kind == "GATE_ERROR":
            fail("A10", f"gate met phase {label.split(':')[-1]} at {s[1]} {short(s[0])}")
        if row_of(s[0]) != row_of(t[0]) and kind not in ("T1", "T2", "T3", "T4", "T5"):
            fail("A9", f"axis changed by '{label}' ({kind}) at {s[1]}")
        if t[1] in ROOT_POSITIONS and s[1] not in ROOT_POSITIONS:
            if kind not in ("T7", "T8") or not t[0].storyline_id:
                fail("A10", f"Root of Heaven entered by '{label}' ({kind}) from {s[1]} {short(s[0])}")
        if kind == "T5":
            check_t5(s[0], label, t[0], fail)
    for (rec, pos), ph in phase.items():
        if rec.storyline_id and (offer_list := [e for e in out[(rec, pos)] if e[2] in ("T5", "LATE_OFFER")]):
            fail("A7", f"{len(offer_list)} offer(s) at {pos} with {rec.storyline_id} stored")
        if ph == "DAMAGED":
            fail("A8", f"live state at {pos} {short(rec)} is DAMAGED "
                       f"({sorted(load_check_tags(rec, flags, pos, False, reading))})")
        if ph == "CRISIS" and pos != "S16_OPEN":
            fail("A8", f"CRISIS outside C8-S16 at {pos}")
        if not rec.storyline_id:
            if PIDX[pos] > PIDX["S16_OPEN"]:
                fail("A11", f"no stored ID at {pos} {short(rec)}")
            if UNSET not in row_of(rec) and pos == "S16_OPEN":
                takes = [e for e in out[(rec, pos)] if e[2] == "T5"]
                if not takes:
                    fail("A11", f"crisis on {row_of(rec)} has no offer")
                taken = {e[1].split(" ")[-1] for e in takes}
                if taken != set(crisis_offers(row_of(rec))):
                    fail("A11", f"crisis on {row_of(rec)} offers {sorted(taken)}, crisis_offers() gives "
                                f"{sorted(crisis_offers(row_of(rec)))}")
                for e in takes:
                    if e[3][0].storyline_id not in VALID_IDS:
                        fail("A11", f"offer '{e[1]}' reaches {e[3][0].storyline_id!r}")
        if rec.storyline_id and family(rec.storyline_id) != FAMILY_OF.get(rec.authority):
            fail("A12", f"family({rec.storyline_id}) = {family(rec.storyline_id)}, authority {rec.authority}")
    for rec, pos in seen:
        if rec.storyline_id:
            stats["ids"].add(rec.storyline_id)
    for s, label, kind, t, ck in edges:
        stats["kinds"].add(kind)
        if kind == "T3":
            stats["ids_t3"].add(t[0].storyline_id)
        if kind == "T5":
            stats["ids_t5"].add(t[0].storyline_id)
            stats["beats"] |= t[0].beats_played
            stats["offers_taken"].add((row_of(s[0]), label))
    stats["states"] += len(seen)
    stats["saves"] += len(saves)
    stats["edges"] += len(edges)
    for rec, pos in saves:
        stats["lock_negotiated_sets"].add(tuple(sorted(rec.lock_negotiated)))
        if rec.storyline_id and rec.authority == "YOU" and "authority" in rec.lock_negotiated:
            stats["sole_dissent"].add("by T5" if "authority" in rec.axis_revised else "by seeds")


def check_t5(before, label, after, fail):
    """Lifecycle L-AC7 post-conditions for one renegotiation."""
    _, axis, v = label.split(" ")[-1].split(":")
    others = [ax for ax in LOCK_ORDER if ax != axis]
    rule = ROW_RULE[row_of(before)]
    probs = []
    if getattr(after, axis) != v:
        probs.append("axis value")
    if any(getattr(after, ax) != getattr(before, ax) for ax in others):
        probs.append("other axes changed")
    if after.storyline_id != f"SL-{after.authority}-{after.faction}-{after.deleted}":
        probs.append("ID")
    if axis not in after.axis_revised:
        probs.append("axis_revised")
    if axis not in after.lock_negotiated:
        probs.append("lock_negotiated")
    last = after.retraction_log[-1] if after.retraction_log else None
    if last != Entry(axis, getattr(before, axis), v, WITHDRAWN[axis][getattr(before, axis)], "C8-S16"):
        probs.append("retraction_log")
    if f"retract_{rule}_{axis}_{v}" not in after.beats_played:
        probs.append("beat")
    if probs:
        fail("A13", f"T5 {label} from {row_of(before)}: {', '.join(probs)}")


def short(rec):
    bits = [f"{rec.authority}/{rec.faction}/{rec.deleted}"]
    if rec.storyline_id:
        bits.append(rec.storyline_id)
    bits.append(rec.root_phase)
    if rec.axis_revised:
        bits.append("rev=" + ",".join(sorted(rec.axis_revised)))
    if rec.lock_negotiated:
        bits.append("neg=" + ",".join(sorted(rec.lock_negotiated)))
    return "(" + " ".join(bits) + ")"


# ---------------------------------------------------------------------------------------------------------------
# Seed contexts
# ---------------------------------------------------------------------------------------------------------------
def seed_contexts():
    """Every subset of the 13 axis seeds the code allows (exclusive groups: at most one Data Wraith flag)."""
    fac = [s[0] for s in AXIS_SEEDS if s[1] == "faction"]
    aut = [s[0] for s in AXIS_SEEDS if s[1] == "authority"]
    wraith = [None] + [s[0] for s in AXIS_SEEDS if s[1] == "deleted"]
    for fbits in itertools.product((0, 1), repeat=len(fac)):
        for abits in itertools.product((0, 1), repeat=len(aut)):
            for w in wraith:
                fl = {x for x, b in zip(fac, fbits) if b} | {x for x, b in zip(aut, abits) if b}
                if w:
                    fl.add(w)
                yield frozenset(fl)


def signature(flags):
    return tuple(lock_pass(flags, ax, v) for ax in LOCK_ORDER for v in VALUES[ax])


# ---------------------------------------------------------------------------------------------------------------
# Unit tables
# ---------------------------------------------------------------------------------------------------------------
def unit_checks(reading):
    res = []   # (id, ok, detail)

    def chk(cid, ok, detail=""):
        res.append((cid, bool(ok), detail))

    allflags = ALL_PREREQ_FLAGS
    vals = {ax: VALUES[ax] + (UNSET,) for ax in VALUES}
    counts = defaultdict(int)
    bad = []
    for a in vals["authority"]:
        for f in vals["faction"]:
            for d in vals["deleted"]:
                for inv in (False, True):
                    r = formula_id(a, f, d, inv, DEFAULT_KNOBS, allflags)
                    exp = ("PENDING" if UNSET in (a, f, d) else "CRISIS" if invalid(a, f, d) else f"SL-{a}-{f}-{d}")
                    counts[("PENDING" if r == "PENDING" else "CRISIS" if r == "CRISIS" else "ID")] += 1
                    if r != exp:
                        bad.append((a, f, d, inv, r))
    chk("AC5 default knobs, 128 cases", not bad and counts == {"ID": 48, "PENDING": 74, "CRISIS": 6},
        f"ID {counts['ID']//2} triples, PENDING {counts['PENDING']//2}, CRISIS {counts['CRISIS']//2}; bad {bad[:3]}")
    swapped = []
    for route in ROUTES:
        knobs = {r: r == route for r in ROUTES}
        for rule, row in RULES.items():
            r = formula_id(*row, True, knobs, allflags)
            exp = "SL-SECRET-" + route if TRANSFORM[rule] == route else "CRISIS"
            if r != exp:
                swapped.append((route, rule, r))
    chk("AC5 one route enabled at a time (synthetic)", not swapped, str(swapped))
    bad6 = []
    for rule, row in RULES.items():
        route = TRANSFORM[rule]
        knobs = {r: r == route for r in ROUTES}
        lst = SECRET_PREREQS[route]
        for miss in lst:
            if formula_id(*row, True, knobs, frozenset(lst) - {miss}) != "CRISIS":
                bad6.append((route, "missing " + miss))
        if formula_id(*row, True, knobs, frozenset(lst)) != "SL-SECRET-" + route:
            bad6.append((route, "all set"))
        if formula_id(*row, True, DEFAULT_KNOBS, frozenset(lst)) != "CRISIS":
            bad6.append((route, "disabled"))
    chk("AC6 prerequisite subsets", not bad6, str(bad6))
    p = {"X": (), "Y": ("F1",), "Z": ("F1", "F2")}
    chk("AC7 prereqs_met list lengths",
        not prereqs_met("X", None, {"F1", "F2"}, p) and not prereqs_met("Y", None, {"F1"}, p)
        and prereqs_met("Z", None, {"F1", "F2"}, p) and not prereqs_met("Z", None, {"F1"}, p))
    fam_bad = [i for i in VALID_IDS if family(i) != FAMILY_OF[i.split("-")[1]]]
    fam_bad += [i for i in SECRET_IDS if family(i) != "RESERVED"]
    fam_bad += [i for i in ("PENDING", "CRISIS", "", "SL-SECRET-BOGUS", VALID_IDS[0].lower(), VALID_IDS[0] + "x")
                + INVALID_IDS if family(i) != "NO_FAMILY"]
    split = defaultdict(int)
    for i in VALID_IDS:
        split[family(i)] += 1
    chk("AC8 family over every id; split SOLE 8, BOUND 9, NONE_AUTH 7",
        not fam_bad and dict(split) == {"SOLE": 8, "BOUND": 9, "NONE_AUTH": 7}, f"{dict(split)} {fam_bad}")
    # lock_pass: Formulas examples and lifecycle L-AC2 fixtures
    lp = [(set(), "faction", "HEARTH", "NEGOTIATED"), ({"act1_report_local"}, "faction", "HEARTH", "CLEAN"),
          ({"act1_report_local", "ch1_knight_killed"}, "faction", "HEARTH", "NEGOTIATED"),
          ({"ch1_knight_killed"}, "faction", "HEARTH", "NEGOTIATED"),
          ({"act1_report_archive"}, "faction", "HEARTH", "NEGOTIATED"),
          (set(), "faction", "ARCHIVE", "NEGOTIATED"), ({"ch1_root_first_edit"}, "authority", "YOU", "CLEAN"),
          (set(), "authority", "SHARED", "NEGOTIATED"), ({"ch1_aldric_kill_unsure"}, "authority", "SHARED", "CLEAN"),
          ({"ch1_aldric_kill_owned"}, "authority", "SHARED", "NEGOTIATED"),
          (set(), "deleted", "CHOOSE", "NEGOTIATED"), ({"ch2_data_wraith_absorbed"}, "deleted", "CHOOSE", "CLEAN"),
          ({"ch2_data_wraith_restored"}, "deleted", "CHOOSE", "NEGOTIATED")]
    lp_bad = [(sorted(fl), ax, v, lock_pass(fl, ax, v)) for fl, ax, v, exp in lp if lock_pass(fl, ax, v) != exp]
    chk("lock_pass: Formulas examples + L-AC2 fixtures (13)", not lp_bad, str(lp_bad))
    # crisis offers
    co = {r: crisis_offers(row) for r, row in RULES.items()}
    chk("crisis_offers: 6/5/5 = 16; R2 and R3 share the five strings; 0 on every valid row",
        [len(co[r]) for r in ("R1", "R2", "R3")] == [6, 5, 5] and co["R2"] == co["R3"]
        and all(not crisis_offers((a, f, d)) for a in VALUES["authority"] for f in VALUES["faction"]
                for d in VALUES["deleted"] if not invalid(a, f, d)),
        "; ".join(f"{r}: {', '.join(v)}" for r, v in co.items()))
    chk("crisis_offers: the R2/R3 Faction swap is not offered",
        "revise:faction:CONTINUITY" not in co["R2"] and "revise:faction:ARCHIVE" not in co["R3"])
    chk("16 distinct retraction beat ids", len(DEFINED_BEATS) == 16, str(len(DEFINED_BEATS)))
    # red lines (L-AC3), derived from 'one Deleted value away from an invalid row'
    rl = {(a, f): red_line(a, f) for a in VALUES["authority"] for f in VALUES["faction"]}
    exp_rl = {("YOU", "HEARTH"): {"R1"}, ("NONE", "ARCHIVE"): {"R2"}, ("NONE", "CONTINUITY"): {"R3"}}
    chk("L-AC3 red lines: exactly YOU+HEARTH R1, NONE+ARCHIVE R2, NONE+CONTINUITY R3; six pairs none",
        all(rl[k] == exp_rl.get(k, set()) for k in rl), str({k: v for k, v in rl.items() if v}))
    # phase_of: Formulas examples
    def rec(a, f, d, sid="", root="OUTSIDE", **kw):
        return EMPTY._replace(authority=a, faction=f, deleted=d, storyline_id=sid, root_phase=root, **kw)
    ex = [(rec("YOU", "HEARTH", UNSET), True, "S15", "PARTLY_LOCKED"),
          (rec("SHARED", "ARCHIVE", "CHOOSE", "SL-SHARED-ARCHIVE-CHOOSE", "INSIDE",
               lock_negotiated=frozenset(LOCK_ORDER)), True, "ROOT", "FIXED"),
          (rec("YOU", "HEARTH", UNSET, root="FINAL"), True, "S15", "DAMAGED"),
          (rec("NONE", "ARCHIVE", "RELEASE"), True, "CH9", "DAMAGED"),
          (rec("NONE", "ARCHIVE", "RELEASE"), False, "S16_OPEN", "CRISIS")]
    for r_, loaded, pos, exp in ex:
        got = phase_of(r_, loaded, frozenset(), pos, reading)
        chk(f"Formulas example {short(r_)} loaded={loaded} at {pos} -> {exp}", got == exp,
            f"got {got} {sorted(load_check_tags(r_, frozenset(), pos, loaded, reading))}")
    # AC9 per-phase fixtures
    fx = {"LEANING": (EMPTY, True, "PRE_C8"),
          "PARTLY_LOCKED": (rec(UNSET, "HEARTH", UNSET, lock_negotiated=frozenset({"faction"})), True, "S13_DONE"),
          "CRISIS": (rec("NONE", "ARCHIVE", "RELEASE", lock_negotiated=frozenset(LOCK_ORDER)), False, "S16_OPEN"),
          "VALIDATED": (rec("SHARED", "ARCHIVE", "CHOOSE", "SL-SHARED-ARCHIVE-CHOOSE",
                            lock_negotiated=frozenset(LOCK_ORDER)), True, "CH9"),
          "FIXED": (rec("SHARED", "ARCHIVE", "CHOOSE", "SL-SHARED-ARCHIVE-CHOOSE", "INSIDE",
                        lock_negotiated=frozenset(LOCK_ORDER)), True, "ROOT"),
          "FINAL": (rec("SHARED", "ARCHIVE", "CHOOSE", "SL-SHARED-ARCHIVE-CHOOSE", "FINAL",
                        lock_negotiated=frozenset(LOCK_ORDER)), True, "STORY_PLUS")}
    for ph, (r_, loaded, pos) in fx.items():
        got = phase_of(r_, loaded, frozenset(), pos, reading)
        lc = load_check(r_, frozenset(), pos, reading)
        # rev 10 (F2): the CRISIS fixture sits inside C8-S16, so D17's before-commit clause fires with D9
        exp_lc = {"D9", "D17"} if ph == "CRISIS" else set()
        chk(f"AC9 fixture {ph}: phase_of(loaded={loaded}) {ph}, load_check {sorted(exp_lc) or '{}'}",
            got == ph and lc == exp_lc, f"phase {got}, load_check {sorted(lc)}")
    cr = fx["CRISIS"][0]
    chk("AC9 CRISIS fixture with loaded=true is DAMAGED",
        phase_of(cr, True, frozenset(), "S16_OPEN", reading) == "DAMAGED")
    # L-AC8 gate matrix (story and load paths x storable phases), revision 10. The story cells of LEANING and
    # PARTLY_LOCKED run on a live record injected before C8-S16 (T6); the same record injected past C8-S16 reads
    # DAMAGED (D16) and a live DAMAGED record is turned back by the gate's DAMAGED row; a VALIDATED save positioned
    # inside Root of Heaven loads and the load-path gate runs T7 (F8).
    gm = []
    storable = {"LEANING": (EMPTY, "PRE_C8"), "PARTLY_LOCKED": (fx["PARTLY_LOCKED"][0], "S13_DONE"),
                "VALIDATED": (fx["VALIDATED"][0], "CH9"), "FIXED": (fx["FIXED"][0], "CH9"),
                "FINAL": (fx["FINAL"][0], "CH9")}
    for ph, (r_, spos) in storable.items():
        story = gate(r_, frozenset(), spos, "ROOT", "story", frozenset(), reading)[0]
        exp = "TURNED_BACK" if ph in ("LEANING", "PARTLY_LOCKED") else "ROOT_OF_HEAVEN"
        exp_kind = {"VALIDATED": "T7", "FIXED": "T8", "FINAL": "T8"}.get(ph, "T6")
        if exp not in story[0] or story[1] != exp_kind:
            gm.append(("story", ph, story[0]))
        lpos = "ROOT_STORY_PLUS" if ph == "FINAL" else "ROOT"
        lc = load_check(r_, frozenset(), lpos, reading)
        if ph in ("LEANING", "PARTLY_LOCKED"):
            past = gate(r_, frozenset(), "CH9", "ROOT", "story", frozenset(), reading)[0]
            if ":TURNED_BACK" not in past[0] or past[2] != r_:
                gm.append(("story, injected past C8-S16", ph, past[0]))
            if "D16" not in lc:
                gm.append(("load", ph, sorted(lc)))
        else:
            res_ = gate(r_, frozenset(), lpos, lpos, "load", frozenset(), reading)[0] if not lc else None
            want_kind = "T7" if ph == "VALIDATED" else "T8"
            if lc or res_[1] != want_kind:
                gm.append(("load", ph, sorted(lc), res_[1] if res_ else None))
    damaged_live = rec("YOU", "HEARTH", UNSET, root="FINAL")   # FINAL with nothing stored: D8 (and D16), live too
    dres = gate(damaged_live, frozenset(), "CH9", "ROOT", "story", frozenset(), reading)[0]
    if ":TURNED_BACK" not in dres[0] or dres[1] != "GATE_DAMAGED" or dres[2] != damaged_live:
        gm.append(("story, live DAMAGED", "DAMAGED", dres[0]))
    chk("L-AC8 gate matrix: story cells (injected live records), live DAMAGED turned back, load cells "
        "(LEANING/PARTLY_LOCKED refused with D16, VALIDATED runs T7)", not gm, str(gm))
    return res


# ---------------------------------------------------------------------------------------------------------------
# Clause isolation and the accepted-but-unreachable probe
# ---------------------------------------------------------------------------------------------------------------
ALL_CLAUSES = ("D1.secret", "D1.unset_axis", "D1.invalid_row", "D1.other_id", "D6", "D7.unnamed", "D7.multi",
               "D7.new_mismatch", "D7.reverse", "D8", "D9", "D14.undefined", "D14.no_entry", "D14.not_played", "D15",
               "D16", "D17.prefix", "D17.before_commit")
DOCUMENTATION_ONLY = ("D17.prefix",)   # rev 10: AC9 has no fixture of its own for D17's prefix clause


def mutations(rec, pos, flags):
    for sid in VALID_IDS + SECRET_IDS + INVALID_IDS + ("", "SL-UNSET-HEARTH-CHOOSE"):
        if sid != rec.storyline_id:
            yield "storyline_id", rec._replace(storyline_id=sid), pos, flags
    for ax in LOCK_ORDER:
        for v in VALUES[ax] + (UNSET,):
            if v != getattr(rec, ax):
                yield f"axis {ax}", rec._replace(**{ax: v}), pos, flags
    for rp in ("OUTSIDE", "INSIDE", "FINAL"):
        if rp != rec.root_phase:
            yield "root_phase", rec._replace(root_phase=rp), pos, flags
    for ax in LOCK_ORDER:
        yield "axis_revised toggle", rec._replace(axis_revised=rec.axis_revised ^ {ax}), pos, flags
        yield "lock_negotiated toggle", rec._replace(lock_negotiated=rec.lock_negotiated ^ {ax}), pos, flags
    for i, e in enumerate(rec.retraction_log):
        log = list(rec.retraction_log)
        yield "retraction entry dropped", rec._replace(retraction_log=tuple(log[:i] + log[i + 1:])), pos, flags
        b_old = beat_for_entry(rec, e)
        for v in VALUES[e.axis]:
            if v != e.new:
                yield "retraction new", rec._replace(retraction_log=tuple(log[:i] + [e._replace(new=v)]
                                                                           + log[i + 1:])), pos, flags
                # the coordinated two-field edit of AC9's D7 new-value fixture: the entry's `new` and its beat
                b_new = beat_for_entry(rec, e._replace(new=v))
                if b_new in DEFINED_BEATS and b_old in rec.beats_played:
                    yield "retraction new + beat renamed", rec._replace(
                        retraction_log=tuple(log[:i] + [e._replace(new=v)] + log[i + 1:]),
                        beats_played=frozenset((rec.beats_played - {b_old}) | {b_new})), pos, flags
            if v != e.old:
                yield "retraction old", rec._replace(retraction_log=tuple(log[:i] + [e._replace(old=v)]
                                                                           + log[i + 1:])), pos, flags
        for ax in LOCK_ORDER:
            if ax != e.axis:
                yield "retraction axis", rec._replace(retraction_log=tuple(log[:i] + [e._replace(axis=ax)]
                                                                            + log[i + 1:])), pos, flags
        yield "retraction withdrawn_item", rec._replace(retraction_log=tuple(
            log[:i] + [e._replace(withdrawn_item="something else")] + log[i + 1:])), pos, flags
        yield "retraction scene", rec._replace(retraction_log=tuple(
            log[:i] + [e._replace(scene="C8-S13")] + log[i + 1:])), pos, flags
    if not rec.retraction_log and UNSET not in row_of(rec):
        for ax in LOCK_ORDER:
            for v in VALUES[ax]:
                if v != getattr(rec, ax):
                    yield "retraction entry added", rec._replace(retraction_log=(
                        Entry(ax, v, getattr(rec, ax), WITHDRAWN[ax][v], "C8-S16"),)), pos, flags
    for b in sorted(DEFINED_BEATS) + ["retract_R9_faction_NOWHERE"]:
        yield "beats_played toggle", rec._replace(beats_played=rec.beats_played ^ {b}), pos, flags
    for p in POSITIONS:
        if p != pos:
            yield f"position", rec, p, flags
    for fl, *_ in AXIS_SEEDS:
        yield "seed flag toggle", rec, pos, flags ^ {fl}
    for g in EXCLUSIVE_GROUPS:
        present = [x for x in g if x in flags]
        add = [x for x in g if x not in flags]
        if present and add:
            yield "second flag of an exclusive group", rec, pos, flags | {add[0]}


def probe(rep_by_sig, saves_by_sig, reading):
    """Clause isolation (AC9) and records load_check accepts that play never writes."""
    exact = {}      # clause -> example where load_check is exactly {its item}
    alone = {}      # clause -> example where the tags are exactly {clause}
    accepted = defaultdict(lambda: [0, None, defaultdict(int)])
    accepted_states = {}
    for sig, flags in rep_by_sig.items():
        for rec, pos in saves_by_sig[sig]:
            for kind, r2, p2, f2 in mutations(rec, pos, flags):
                tags = load_check_tags(r2, f2, p2, True, reading)
                its = items(tags)
                if not tags:
                    sig2 = signature(f2)
                    if (r2, p2) not in saves_by_sig.get(sig2, ()):
                        accepted[kind][0] += 1
                        if kind == "position":
                            accepted[kind][2][f"{pos}->{p2}"] += 1
                        if accepted[kind][1] is None:
                            accepted[kind][1] = f"from {pos} {short(rec)}: {short(r2)} at {p2}"
                        accepted_states.setdefault((sig2, r2, p2), (kind, f2))
                    continue
                for c in tags:
                    if its == {c.split(".")[0]} and c not in exact:
                        exact[c] = f"{kind}: {short(r2)} at {p2} -> tags {sorted(tags)}"
                    if tags == {c} and c not in alone:
                        alone[c] = f"{kind}: {short(r2)} at {p2}"
    return exact, alone, accepted, accepted_states


def liveness_of_accepted(accepted_states, reading):
    """From every accepted-but-unwritten record: load (the load-path gate inside Root of Heaven), then walk
    forward. Returns (records checked, stranded examples by kind). Memoised over (signature, record, position)."""
    good = {}
    stranded = defaultdict(list)
    for key, (kind, flags) in accepted_states.items():
        sig, rec, pos = key
        if pos in ROOT_POSITIONS:
            label, tk, nrec, _, _ = gate(rec, flags, pos, pos, "load gate", frozenset(), reading)[0]
            if tk not in ("T7", "T8"):
                stranded[kind].append(f"{short(rec)} at {pos}: {label}")
                continue
            rec = nrec
        start = (sig, rec, pos)
        if start not in good:
            nodes, succ, q = {start}, defaultdict(list), deque([start])
            while q:
                s = q.popleft()
                if s in good:
                    continue
                for e in events(s[1], s[2], flags, DEFAULT_KNOBS, frozenset(), reading):
                    t = (sig, e[2], e[3])
                    succ[s].append(t)
                    if t not in nodes:
                        nodes.add(t)
                        q.append(t)
            ok = {n for n in nodes if good.get(n) or phase_of(n[1], False, flags, n[2], reading) == "FINAL"}
            changed = True
            while changed:
                changed = False
                for n in nodes:
                    if n not in ok and any(t in ok for t in succ[n]):
                        ok.add(n)
                        changed = True
            for n in nodes:
                good.setdefault(n, n in ok)
        if not good[start]:
            stranded[kind].append(f"{short(rec)} at {pos} (phase {phase_of(rec, False, flags, pos, reading)})")
    return len(accepted_states), stranded


def d17_prefix_redundancy():
    """Exhaustive: does D17's prefix clause ever fire without D16 or D17's before-commit clause?"""
    hits = []
    for a in VALUES["authority"] + (UNSET,):
        for f in VALUES["faction"] + (UNSET,):
            for d in VALUES["deleted"] + (UNSET,):
                for p in POSITIONS:
                    r = EMPTY._replace(authority=a, faction=f, deleted=d)
                    t = load_check_tags(r, frozenset(), p, True)
                    if "D17.prefix" in t and not ({"D16", "D17.before_commit"} & t):
                        hits.append((a, f, d, p))
    return hits


# ---------------------------------------------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------------------------------------------
def run_suite(contexts, reading, defects=frozenset(), collect=False):
    fails = []
    stats = defaultdict(set)
    for k in ("states", "saves", "edges"):
        stats[k] = 0
    sig_done = {}
    saves_by_sig = {}
    rep_by_sig = {}
    for flags in contexts:
        sig = signature(flags)
        if sig in sig_done:          # the lifecycle reads seeds only through lock_pass
            continue
        seen, edges, saves = walk(flags, DEFAULT_KNOBS, defects, reading)
        f0 = len(fails)
        check_walk(flags, seen, edges, saves, reading, fails, stats)
        sig_done[sig] = len(fails) - f0
        if collect:
            saves_by_sig[sig] = saves
            rep_by_sig[sig] = flags
    # A14 (global): the walk reaches exactly the 24 valid IDs and takes each of the 16 offers, playing 16 beats
    if set(stats["ids"]) != set(VALID_IDS):
        fails.append(("A14", f"reachable IDs {len(stats['ids'])}, expected the 24 valid IDs"))
    if len(stats["offers_taken"]) != 16 or stats["beats"] != DEFINED_BEATS:
        fails.append(("A14", f"offers taken {len(stats['offers_taken'])}, beats {len(stats['beats'])}; expected 16"))
    return fails, stats, sig_done, saves_by_sig, rep_by_sig


def summarize_fails(fails, limit=3):
    by = defaultdict(list)
    for code, msg in fails:
        by[code].append(msg)
    lines = []
    for code in sorted(by, key=lambda c: int(c[1:])):
        uniq = list(dict.fromkeys(by[code]))
        lines.append(f"  {code}: {len(by[code])} violation(s), {len(uniq)} distinct")
        for m in uniq[:limit]:
            lines.append(f"      e.g. {m}")
    return lines


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--quick", action="store_true", help="skip the accepted-record probe")
    args = ap.parse_args()
    t0 = time.time()
    contexts = list(seed_contexts())
    sigs = {signature(c) for c in contexts}
    print("Storyline reference model (storyline-axes.md OQ16) — axes rev 10, lifecycle rev 6")
    print(f"Seed contexts: {len(contexts)} (13 axis seeds; one Data Wraith flag at most), "
          f"{len(sigs)} distinct lock_pass signatures walked")
    print(f"Positions: {', '.join(POSITIONS)}; suppression windows: {', '.join(sorted(SPEC_WINDOWS))}")
    print()
    overall_ok = True

    print("== Unit tables (" + REV10.name + ") ==")
    units = unit_checks(REV10)
    for cid, ok, detail in units:
        print(f"  [{'PASS' if ok else 'FAIL'}] {cid}" + (f"  — {detail}" if detail and not ok else ""))
        overall_ok &= ok
    print()

    print("== Walk, " + REV10.name + " (default knobs, no defects) ==")
    fails, stats, sig_fails, saves_by_sig, rep_by_sig = run_suite(contexts, REV10, collect=True)
    print(f"  states {stats['states']}, edges {stats['edges']}, saves {stats['saves']} "
          f"(summed over {len(sig_fails)} signatures)")
    print(f"  stored IDs reachable: {len(stats['ids'])} (by T3: {len(stats['ids_t3'])}, by T5: "
          f"{len(stats['ids_t5'])}); retraction beats played: {len(stats['beats'])}; distinct (row, offer) taken: "
          f"{len(stats['offers_taken'])}")
    print(f"  lock_negotiated sets seen in saves: {len(stats['lock_negotiated_sets'])}; sole_dissent reachable: "
          f"{sorted(stats['sole_dissent']) or 'no'}")
    print(f"  transition kinds fired: {', '.join(sorted(stats['kinds']))}"
          f"{'' if 'T6' in stats['kinds'] else '  (T6 TURNED_BACK never fires in play: defence in depth, lifecycle S6)'}")
    if fails:
        overall_ok = False
        print(f"  [FAIL] {len(fails)} violation(s) in {sum(1 for v in sig_fails.values() if v)} signature(s):")
        print("\n".join(summarize_fails(fails)))
    else:
        print("  [PASS] A1-A14 hold in every signature")
    print()

    print("== Regression: the " + LITERAL.name + " (what design review round 10 found; must still fail) ==")
    lfails, _, _, _, _ = run_suite(contexts, LITERAL)
    lbad = [u[0] for u in unit_checks(LITERAL) if not u[1]]
    if lfails:
        print("\n".join(summarize_fails(lfails)))
    print(f"  unit tables failing on the rev 9 text: {len(lbad)}")
    for u in lbad:
        print(f"      {u}")
    regression_ok = bool(lfails) and any(u.startswith("AC9 fixture CRISIS") for u in lbad) \
        and any(u.startswith("L-AC8") for u in lbad)
    print(f"  [{'CAUGHT' if regression_ok else 'MISSED'}] the model still finds F1 (A8), F2/F1 (AC9 CRISIS fixture) "
          "and F9 (L-AC8) on the rev 9 text")
    overall_ok &= regression_ok
    print()

    print("== Negative controls (each seeded defect must fail at least one assertion; " + REV10.name + ") ==")
    base_codes = {c for c, _ in fails}
    all_caught = True
    for name, desc in DEFECTS.items():
        dfails, *_ = run_suite(contexts, REV10, frozenset({name}))
        codes = sorted({c for c, _ in dfails} - base_codes, key=lambda c: int(c[1:]))
        caught = bool(codes)
        all_caught &= caught
        print(f"  [{'CAUGHT' if caught else 'MISSED'}] {name}: {desc} -> {', '.join(codes) or 'no new failure'}")
    overall_ok &= all_caught
    print()

    print("== Clause isolation (AC9: one fixture per clause with load_check exactly {that item}) ==")
    exact, alone, accepted, accepted_states = (probe(rep_by_sig, saves_by_sig, REV10) if not args.quick
                                               else ({}, {}, {}, {}))
    redund = []
    if args.quick:
        print("  skipped (--quick)")
    else:
        for c in ALL_CLAUSES:
            st = "exact" if c in exact else ("documentation only" if c in DOCUMENTATION_ONLY else "NOT ISOLATABLE")
            print(f"  [{st}] {c}" + (f"  — {exact[c]}" if c in exact else "")
                  + ("" if c in alone or c not in exact else "  (never the only clause firing)"))
        missing = [c for c in ALL_CLAUSES if c not in exact and c not in DOCUMENTATION_ONLY]
        overall_ok &= not missing
        redund = d17_prefix_redundancy()
        print(f"  D17.prefix without D16 or D17.before_commit, exhaustive over 64 axis triples x "
              f"{len(POSITIONS)} positions: {len(redund)} case(s)")
        overall_ok &= not redund
    print()

    print("== Residual: records load_check accepts that no play in that seed context writes (single-field changes "
          "of reachable saves; best-effort by design, Open Question 17: reported, not asserted) ==")
    stranded = {}
    n_live = 0
    if not args.quick:
        for k, (n, ex, pairs) in sorted(accepted.items(), key=lambda kv: -kv[1][0]):
            print(f"  {n:7d}  {k}  e.g. {ex}")
            if pairs:
                top = sorted(pairs.items(), key=lambda kv: (-kv[1], kv[0]))
                print(f"           {len(top)} from->to pairs: " + ", ".join(p for p, _ in top))
        n_live, stranded = liveness_of_accepted(accepted_states, REV10)
        n_str = sum(len(v) for v in stranded.values())
        print(f"  [INFO] from each of {n_live} distinct accepted records (load-path gate inside Root of Heaven, then "
              f"forward walk), FINAL is reachable except {n_str} (modelling choice M8: no route back to the final "
              "authorization from Story+)")
        for k, v in stranded.items():
            print(f"      {k}: {len(v)}, e.g. {v[0]}")
    else:
        print("  skipped (--quick)")
    print()

    def acc(k):
        return accepted.get(k, [0])[0]

    print("== ROUND-10 FINDINGS: status under the rev 10 text ==")
    ac9_crisis = next((u[1] for u in units if u[0].startswith("AC9 fixture CRISIS")), False)
    lac8 = next((u[1] for u in units if u[0].startswith("L-AC8")), False)
    formula_crisis = next((u[1] for u in units if "loaded=False at S16_OPEN -> CRISIS" in u[0]), False)
    st = []
    st.append(("F1", "resolved" if "A8" in {c for c, _ in lfails} and not fails and formula_crisis else "OPEN",
               "D17's before-commit clause is load-only; the live crisis is CRISIS again"))
    st.append(("F2", "resolved" if ac9_crisis else "OPEN", "AC9's CRISIS fixture reports {D9, D17}"))
    st.append(("F3", "documented" if not args.quick and not redund else "UNVERIFIED",
               "D17's prefix clause never fires alone; kept as documentation, no fixture"))
    st.append(("F4", "resolved" if "D7.new_mismatch" in exact else "OPEN" if not args.quick else "UNVERIFIED",
               "strict 'matching' plus the coordinated two-field fixture isolates D7's new-value clause"))
    st.append(("F5", "open, best-effort (OQ17)",
               "; ".join(f"{k} {acc(k)}" for k in ("retraction withdrawn_item", "retraction scene",
                                                   "lock_negotiated toggle", "seed flag toggle", "axis faction",
                                                   "axis authority") if acc(k)) or "none accepted"))
    st.append(("F6", "resolved" if "D7.reverse" in exact and not acc("axis_revised toggle")
               else "OPEN" if not args.quick else "UNVERIFIED",
               f"D7 runs both ways; accepted axis_revised toggles: {acc('axis_revised toggle')}"))
    st.append(("F7", "open, best-effort (OQ17)",
               f"{acc('position')} position and {acc('root_phase')} root_phase changes accepted; none is promised"))
    st.append(("F8", "resolved" if lac8 else "OPEN", "L-AC8 has a VALIDATED-on-load cell (T7)"))
    st.append(("F9", "resolved" if lac8 else "OPEN",
               "T6 kept as defence in depth, a DAMAGED gate row, injected live cells in L-AC8"))
    st.append(("F10", "open, best-effort (OQ17)",
               f"{sum(len(v) for v in stranded.values())} accepted records cannot reach FINAL (rests on M8)"))
    # F11 (new in round 10, from the F1 repair): D9 and D17(a) are exempt for every live record, so a live record
    # with an invalid row and nothing stored, positioned past C8-S16, reads CRISIS and reaches a gate with no row.
    crisis_gate = gate(EMPTY._replace(authority="NONE", faction="ARCHIVE", deleted="RELEASE"), frozenset(), "CH9",
                       "ROOT", "story", frozenset(), REV10)[0][0]
    st.append(("F11", "new, open (OQ18)" if "GATE_ERROR" in crisis_gate else "none",
               f"a live crisis record past C8-S16 at the story gate: {crisis_gate}"))
    for fid, status, note in st:
        print(f"  {fid}: {status} — {note}")
        if status == "OPEN":
            overall_ok = False
    print()

    print("== Modelling choices (where the GDDs leave the model a reading) ==")
    for m in (
        "M1 Seed contexts hold the 13 axis-seed flags only: modifier and timing rows are not read by lock_pass or "
        "load_check (except D15, which play cannot reach because set_story_flag clears the group). Seeds are fixed "
        "before C8-S13 (Act 1); side-arc flags join after Y2-PP-T17 maps them (AC15) and are not modelled.",
        "M2 Contexts are walked once per lock_pass signature: the transitions read seeds only through lock_pass.",
        "M3 A save is any reachable state outside the four suppression windows, plus every checkpoint. A quit "
        "or crash reloads an earlier save, which is a reachable state already in the walk, so reload edges add no "
        "states; A1/A2 check every save's load.",
        "M4 The `world_map` path is modelled only for re-entry (after leaving Root of Heaven, and from Story+); "
        "before the Chapter 9 end Root of Heaven is not on the map (lifecycle S6).",
        "M5 Positions are coarse: Chapter 9 is one position; the boss is one event (ROOT -> final authorization). "
        "A crisis-time save would sit at S16_OPEN.",
        "M6 D14 'matching' = the beat id retract_<rule of the row before the renegotiation>_<axis>_<new>, now "
        "stated in Edge Case 16 (rev 10); D1's four clauses are tagged in the order secret, UNSET axis, invalid row, "
        "other ID.",
        "M7 In 1.0 the invocation input I is always false (no source exists); every knob is false. Knob values "
        "are read only by formula_id at C8-S16 and the gate, so A6 also covers a mid-play knob patch.",
        "M8 Story+ (after T9) offers no route back to the boss or the final authorization; re-entering Root of "
        "Heaven from Story+ is T8 only. Whether Story+ can replay the boss belongs to the combat system "
        "(lifecycle Open Question 2).",
        "M9 The accepted-record probe applies one field change to every reachable save (both readings' saves are "
        "the same); 'accepted' means load_check is empty and no play in the mutated seed signature writes that "
        "(record, position). The D7 new-value fixture is the one two-field edit (the entry's `new` and its beat).",
        "M10 A live DAMAGED record at the gate is TURNED_BACK by the gate's DAMAGED row and is not a transition "
        "(kind GATE_DAMAGED); the walk never produces one (A8), so L-AC8's cells inject it.",
    ):
        print("  " + m)
    print()
    print(f"RESULT: {'PASS' if overall_ok else 'FAIL'} ({REV10.name}; the rev 9 text still fails as expected: "
          f"{'yes' if regression_ok else 'NO'}; best-effort residuals F5, F7, F10 reported, not asserted); "
          f"{time.time() - t0:.1f} s")
    return 0 if overall_ok else 1


if __name__ == "__main__":
    sys.exit(main())
