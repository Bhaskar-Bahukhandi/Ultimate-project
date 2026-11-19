"""Non-shipping reference model of the storyline axes and lifecycle (storyline-axes.md Open Question 16).

Implements, independently of the GDD text (it parses nothing), the Formulas of design/gdd/storyline-axes.md
(rev 13) and storyline-lifecycle.md (rev 9): formula_id, prereqs_met, family, lock_pass, phase_of, load_check
(Edge Case 16: D0, D1, D6-D9, D14-D17; D0 as far as typed records can express it, see M12), the legacy-save
defaulting (Edge Case 8), the chapter-select record (lifecycle Chapter select) and crisis_offers; then walks the
lifecycle transitions T1-T9 breadth-first from a new game and from chapter select of Chapter 9 or 10, for every seed
context the game code allows, and asserts:

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

Revision 10 (design review round 10, 2026-11-17): the model implemented the rev 10 text (REV10) and kept the
rev 9 text (LITERAL) as a regression that must still fail (F1, F2, F9).
Revision 11 (design review round 11, 2026-11-17): the model implements the rev 11 text (REV11): the live crisis is
scoped to C8-S16 before its commit (axes Open Question 18, F11) and D7 refuses a duplicated retraction entry. The rev 10
text stays a unit-level regression that must still fail on F11, and the rev 9 text a walk-level one. The accepted-
record residuals are non-goals by the inclusion rule (axes Open Question 17): their counts are reported and their
categories asserted against a pinned list (a new category fails the run).
Revision 12 (design review round 12, 2026-11-17): the model implements the rev 12 text (REV12): D0 owns the
one-entry retraction_log cap (D7.multi and D7.duplicate retired), an older save is defaulted before the check, D14
refuses any beat id the lifecycle does not define, the Authority seeds argue against unilateral history
(ch1_aldric_kill_justified and ch2_seraphina_showoff against YOU, ch2_seraphina_truth for SHARED), and chapter select
past Chapter 8 writes SL-SHARED-ARCHIVE-CHOOSE at CH9. The rev 11 text is a unit-level regression that must still
fail (its D7.duplicate clause cannot be isolated behind D0, its legacy save is D0, its seed map passes a justified
kill clean); rev 10 and rev 9 stay as before.

Revision 13 (design review round 13, 2026-11-17): the model implements the rev 13 text (REV13): ch1_root_purge
argues against YOU, D0 caps beats_played at one and type-checks it (D14 owns its ids), chapter select is keyed to the
entry scene's position ("Chapter 8 - Ending" at S16_DONE), the NG+ reset sets PRE_C8, and a legacy save's position
is derived once from its scene. The rev 12 text is a unit-level regression that must still fail on each of these.

Revision 14 (design review round 14, 2026-11-18; scope frozen by Open Question 20): the model implements the rev 14
text (REV14) and covers the whole stored record, not only the lifecycle block: `story_position` is a record field (a
missing or unlisted one is D0), `act1_pace` defaults to UNSET (a new-game save loads), a legacy save's position is
derived from its free-travel story scene, else its own scene (the scene-to-id map holds no hub), else its chapter (a
Chapter 8 save no story scene places is D0.missing), and D0 names its clause ids. The rev 13 text is a unit-level
regression that must still fail on each of these.

Lifecycle review 2026-11-18 (lifecycle revision 11 / axes revision 15 erratum; scope frozen by lifecycle Open
Question 7): the model implements that text (REV15): the record stores kaelen_commitment (D0 refuses it UNSET on a
record that held YOU or set on one that never did), chapter select has one row per Chapter 8-10 main-menu entry
(True Ending FINAL at FINAL_DONE, Final Confrontation rerouted to the boss, Revolt Crisis to C8-S13), the scene
placement table gives the Root of Heaven scene set and a writer for every position (a hub revival writes ROOT_LEFT),
the window table gives every checkpoint transition its window, commit and resume point, take() goes through the T5
handler, and the NG+ reset sets every stored field to a new game's. The rev 14 text (lifecycle revision 10) is a
unit-level regression that must still fail on each of these.

Usage: python -I -B reference_model.py [--quick]
Exit status: 0 when every assertion and unit check passes under the rev 15 text, the rev 14, rev 13, rev 12, rev 11, rev 10 and rev 9 texts
still fail as expected, every negative control is caught, every AC9 clause has a fixture whose only clause it is
(D17.prefix is documentation only) and the residual categories equal the pinned list; 1 otherwise.
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
# Core Rule 3: Authority -> AXIS1_*, Faction -> AXIS2_*, Deleted -> AXIS3_* (the mirror flags; AC11 reads AXIS2_*).
DIGITS = {"authority": 1, "faction": 2, "deleted": 3}   # unused by logic; documents the AXIS1/2/3 naming

# Act 1 axis seeds (seed map rows whose `pushes` is an axis). Modifier and timing rows lean nowhere and are not
# read by lock_pass, so the walk leaves them out of the seed contexts. lock_pass matches a row by (flag, pushes)
# (Formulas, rev 12), so a flag with a modifier row and an axis row enters the test through its axis row only.
AXIS_SEEDS_REV11 = (    # the seed map of revisions 9-11 (regression only)
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
# Rev 12 (user decision 2026-11-17, design review round 12): the Authority seeds read whether Kaelen answered for
# what he did. ch1_aldric_kill_justified now argues against YOU; ch2_seraphina_showoff (against YOU) and
# ch2_seraphina_truth (for SHARED) gain an axis row beside their modifier row. 26 flags in 28 rows; 15 axis rows.
AXIS_SEEDS_REV12 = (    # the seed map of revision 12 (regression only)
    ("act1_report_local", "faction", "HEARTH", "+"),
    ("act1_report_archive", "faction", "ARCHIVE", "+"),
    ("act1_report_command", "faction", "CONTINUITY", "+"),
    ("ch1_knight_killed", "faction", "HEARTH", "-"),
    ("ch1_root_purge", "faction", "HEARTH", "+"),
    ("ch2_data_wraith_restored", "deleted", "RESTORE", "+"),
    ("ch2_data_wraith_destroyed", "deleted", "RELEASE", "+"),
    ("ch2_data_wraith_absorbed", "deleted", "CHOOSE", "+"),
    ("ch1_aldric_kill_owned", "authority", "YOU", "+"),
    ("ch1_aldric_kill_justified", "authority", "YOU", "-"),
    ("ch1_aldric_kill_unsure", "authority", "SHARED", "+"),
    ("ch1_root_first_edit", "authority", "YOU", "+"),
    ("ch1_root_discovered_unused", "authority", "NONE", "+"),
    ("ch2_seraphina_showoff", "authority", "YOU", "-"),
    ("ch2_seraphina_truth", "authority", "SHARED", "+"),
)
# Rev 13 (user decision 2026-11-17, design review round 13): ch1_root_purge argues against YOU (a rewrite of Aldric
# without his consent, power used on others without answering for it), no longer for HEARTH. 15 axis rows.
AXIS_SEEDS = tuple(("ch1_root_purge", "authority", "YOU", "-") if row[0] == "ch1_root_purge" else row
                   for row in AXIS_SEEDS_REV12)
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
                              "retraction_log beats_played kaelen_commitment", defaults=(UNSET,))
Entry = namedtuple("Entry", "axis old new withdrawn_item scene")
EMPTY = Record(UNSET, UNSET, UNSET, "", "OUTSIDE", frozenset(), frozenset(), (), frozenset())
ROOT_PHASES = ("OUTSIDE", "INSIDE", "FINAL")
RETRACTION_LOG_MAX = 1     # D0 (rev 11 and 12): play takes at most one renegotiation (Core Rule 7)
BEATS_PLAYED_MAX = 16      # D0 through rev 12: the lifecycle's 16 retract_* beats (rev 13: one, Reading.beats_max)
# Save schema versions (Edge Case 8, rev 12): a save of a version before the lifecycle fields is defaulted to EMPTY
# before the load check; a current-version save with a field missing is D0.
LEGACY_SCHEMA, CURRENT_SCHEMA = "pre-lifecycle", "current"
MISSING_FIELD = object()   # decode() result for a current-version save whose lifecycle block lacks a field
# Lifecycle rev 8, Chapter select: past Chapter 8 a fixed valid record at CH9, written as one atomic checkpoint.
CHAPTER_SELECT_RECORD = EMPTY._replace(authority="SHARED", faction="ARCHIVE", deleted="CHOOSE",
                                       storyline_id="SL-SHARED-ARCHIVE-CHOOSE",
                                       lock_negotiated=frozenset(LOCK_ORDER))
# Rev 15 (axes erratum, lifecycle S2): the commitment SOVEREIGN quotes, chosen when YOU is backed (PM:7054-7058).
COMMITMENTS = ("LISTEN", "OVERRIDE_IMMEDIATE_LOSS", "CANNOT_PROMISE_NEVER")


def held_you(rec):
    """The record held YOU: Authority is YOU, or a retraction withdrew YOU (the records SOVEREIGN can quote)."""
    log = rec.retraction_log if isinstance(rec.retraction_log, tuple) else ()
    return rec.authority == "YOU" or any(isinstance(e, Entry) and e.axis == "authority" and e.old == "YOU"
                                         for e in log)


def commitment_wrong(rec):
    """Rev 15 D0.enum clause: kaelen_commitment outside its values, UNSET on a record that held YOU, or set on one
    that never did."""
    c = rec.kaelen_commitment
    return c not in COMMITMENTS + (UNSET,) or (c != UNSET) != held_you(rec)


def fit_commitment(rec, choice="LISTEN"):
    """A hand-built fixture with the commitment play would have written (older readings ignore the field)."""
    return rec._replace(kaelen_commitment=choice if held_you(rec) else UNSET)


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


def lock_pass(flags, axis, value, seeds=AXIS_SEEDS):
    plus = any(fl in flags for fl, ax, v, s in seeds if ax == axis and v == value and s == "+")
    minus = any(fl in flags for fl, ax, v, s in seeds if ax == axis and v == value and s == "-")
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
                 gate_damaged_row=False, live_crisis_scoped=False, d7_duplicate=False, d7_multi=True, d0=False,
                 legacy_default=False, chapter_select=False, seeds=AXIS_SEEDS_REV11, beats_max=BEATS_PLAYED_MAX,
                 cs_by_position=False, ngplus_reset=False, legacy_derive=False, rev14=False, life11=False):
        self.name = name
        self.d17_before_commit_live = d17_before_commit_live   # rev 9: D17 clause (a) also tested on live records
        self.d14_match = d14_match                             # strict: beat id must equal beat_for_entry()
        self.d7_reverse = d7_reverse                           # rev 10: a log entry whose axis is not in axis_revised
        self.gate_damaged_row = gate_damaged_row               # rev 10: a live DAMAGED record at the gate is turned back
        self.live_crisis_scoped = live_crisis_scoped           # rev 11 (OQ18): D9/D17(a) skipped only for live_crisis
        self.d7_duplicate = d7_duplicate                       # rev 11 (OQ17): more than one retraction entry
        self.d7_multi = d7_multi                               # rev 9-11: more than one axis (retired in rev 12)
        self.d0 = d0                                           # rev 11-12: the shape check, tested first
        self.legacy_default = legacy_default                   # rev 12: an older save is defaulted before the check
        self.chapter_select = chapter_select                   # lifecycle rev 8: chapter select past Chapter 8
        self.seeds = seeds                                     # the seed map's axis rows of that revision
        self.beats_max = beats_max                             # D0's beats_played cap (rev 13: one)
        self.cs_by_position = cs_by_position                   # lifecycle rev 9: chapter select keyed to entry position
        self.ngplus_reset = ngplus_reset                       # lifecycle rev 9: the NG+ reset sets PRE_C8
        self.legacy_derive = legacy_derive                     # rev 13: a legacy save's position derived once
        self.rev14 = rev14      # rev 14: story_position and act1_pace stored and checked, hub-safe legacy order, D0 ids
        self.life11 = life11    # rev 15 / lifecycle rev 11: commitment, chapter-select rows, windows, take(), NG+

    def clauses(self):
        """The clause ids this text's load_check can report (AC9's one-fixture-per-clause list)."""
        out = ["D1.secret", "D1.unset_axis", "D1.invalid_row", "D1.other_id", "D6", "D7.unnamed", "D7.new_mismatch",
               "D8", "D9", "D14.undefined", "D14.no_entry", "D14.not_played", "D15", "D16", "D17.prefix",
               "D17.before_commit"]
        out += ["D0"] * self.d0 + ["D7.multi"] * self.d7_multi + ["D7.reverse"] * self.d7_reverse
        out += ["D7.duplicate"] * self.d7_duplicate
        return tuple(sorted(out, key=lambda c: (int(c[1:].split(".")[0]), c)))


LITERAL = Reading("rev 9 text, literal")
REV10 = Reading("rev 10 text", d17_before_commit_live=False, d7_reverse=True, gate_damaged_row=True)
REV11 = Reading("rev 11 text", d17_before_commit_live=False, d7_reverse=True, gate_damaged_row=True,
                live_crisis_scoped=True, d7_duplicate=True, d0=True)
REV12 = Reading("rev 12 text", d17_before_commit_live=False, d7_reverse=True, gate_damaged_row=True,
                live_crisis_scoped=True, d7_duplicate=False, d7_multi=False, d0=True, legacy_default=True,
                chapter_select=True, seeds=AXIS_SEEDS_REV12)
REV13 = Reading("rev 13 text", d17_before_commit_live=False, d7_reverse=True, gate_damaged_row=True,
                live_crisis_scoped=True, d7_duplicate=False, d7_multi=False, d0=True, legacy_default=True,
                chapter_select=True, seeds=AXIS_SEEDS, beats_max=1, cs_by_position=True, ngplus_reset=True,
                legacy_derive=True)
REV14 = Reading("rev 14 text", d17_before_commit_live=False, d7_reverse=True, gate_damaged_row=True,
                live_crisis_scoped=True, d7_duplicate=False, d7_multi=False, d0=True, legacy_default=True,
                chapter_select=True, seeds=AXIS_SEEDS, beats_max=1, cs_by_position=True, ngplus_reset=True,
                legacy_derive=True, rev14=True)
REV15 = Reading("rev 15 text (lifecycle rev 11)", d17_before_commit_live=False, d7_reverse=True,
                gate_damaged_row=True, live_crisis_scoped=True, d7_duplicate=False, d7_multi=False, d0=True,
                legacy_default=True, chapter_select=True, seeds=AXIS_SEEDS, beats_max=1, cs_by_position=True,
                ngplus_reset=True, legacy_derive=True, rev14=True, life11=True)


def shape_wrong(rec, beats_max=BEATS_PLAYED_MAX, commitment_rule=False):
    """D0 as far as a typed record can show it: an enum outside its values, an element of the wrong type, a set or
    list over its maximum. A missing field is decode()'s; a set holding one element twice cannot be built (M12)."""
    if any(getattr(rec, ax) not in VALUES[ax] + (UNSET,) for ax in LOCK_ORDER):
        return True
    if not isinstance(rec.storyline_id, str) or rec.root_phase not in ROOT_PHASES:
        return True
    for name in ("axis_revised", "lock_negotiated"):
        v = getattr(rec, name)
        if not isinstance(v, frozenset) or not v <= frozenset(LOCK_ORDER):
            return True
    log = rec.retraction_log
    if not isinstance(log, tuple) or len(log) > RETRACTION_LOG_MAX:
        return True
    for e in log:
        if (not isinstance(e, Entry) or e.axis not in VALUES or e.old not in VALUES[e.axis]
                or e.new not in VALUES[e.axis] or not isinstance(e.withdrawn_item, str)
                or not isinstance(e.scene, str)):
            return True
    beats = rec.beats_played
    if not isinstance(beats, frozenset) or len(beats) > beats_max or any(not isinstance(b, str) for b in beats):
        return True
    return commitment_rule and commitment_wrong(rec)


def decode(raw, schema, reading):
    """SaveService's read of a save's lifecycle block before load_check. ``raw`` maps field -> value (None: the save
    has no lifecycle block). Rev 12 (Edge Case 8): an older schema is defaulted to EMPTY first; a current-schema save
    with a field missing is D0 (MISSING_FIELD). Texts without D0 (rev 9, 10) read a missing block as the defaults."""
    if schema == LEGACY_SCHEMA and (reading.legacy_default or not reading.d0):
        return EMPTY
    raw = raw or {}
    if set(raw) != set(Record._fields):
        return MISSING_FIELD if reading.d0 else EMPTY._replace(**{k: v for k, v in raw.items()
                                                                  if k in Record._fields})
    return Record(**raw)


def load_check_save(raw, schema, flags, pos, reading):
    """load_check of a save as stored: decode, then the items (a missing field reports exactly {D0})."""
    rec = decode(raw, schema, reading)
    return {"D0"} if rec is MISSING_FIELD else load_check(rec, flags, pos, reading)


def chapter_select(chapter):
    """Lifecycle rev 8, Chapter select: (record, position) written before the chapter's first scene loads. Before
    Chapter 8: the defaults at PRE_C8. Chapter 9 or later: CHAPTER_SELECT_RECORD at CH9 (Chapter 10 then enters
    Root of Heaven through the gate, T7). Chapter 8 itself is named by neither sentence (finding F12); the model
    reads it as the defaults at PRE_C8, the only reading that writes a save the load check accepts."""
    return (EMPTY, "PRE_C8") if chapter <= 8 else (CHAPTER_SELECT_RECORD, "CH9")


# Chapter-select entries as (label, chapter number, story position of the entry scene). "Chapter 8 - Ending"
# (main_menu.gd:655-662) starts at ch8_ending, after the locks, and autosaves on load (design review round 13).
CHAPTER_SELECT_ENTRIES = (("Chapters 1-7", 7, "PRE_C8"), ("Chapter 8 - Ending", 8, "S16_DONE"),
                          ("Chapter 9", 9, "CH9"), ("Chapter 10", 10, "ROOT"))


def chapter_select_entry(chapter, entry_pos, reading):
    """(record, position) of the first save a chapter-select entry writes. Lifecycle rev 9: keyed to the entry
    scene's position: before C8-S13 the defaults at PRE_C8; past C8-S16's commit the fixed record at S16_DONE (a
    Chapter 8 entry after the locks) or CH9 (Chapter 9, and every entry into Root of Heaven, which then passes the
    gate); none inside the lock scenes. Rev 12 keyed it to the chapter number, so a Chapter 8 entry wrote the defaults
    and its scene autosaved them at the scene's own position."""
    if reading.cs_by_position:
        if PIDX[entry_pos] < PIDX["S13_OPEN"]:
            return EMPTY, "PRE_C8"
        if PIDX[entry_pos] >= PIDX["S16_DONE"]:
            return CHAPTER_SELECT_RECORD, ("S16_DONE" if entry_pos == "S16_DONE" else "CH9")
        return None
    rec_, pos_ = chapter_select(chapter)
    return (rec_, pos_) if chapter > 8 else (rec_, entry_pos)


def ng_plus(rec, pos, reading):
    """Lifecycle NG+ reset: a new record (every field at its default). Rev 13 also resets the story position."""
    return EMPTY, ("PRE_C8" if reading.ngplus_reset else pos)


# Scenes of a pre-lifecycle save and the position the scene-to-id map gives them (None: not in the map).
LEGACY_SCENES = {"a hub before Chapter 8": "PRE_C8", "a Chapter 9 scene": "CH9",
                 "a Root of Heaven scene": "ROOT", "a scene the map lacks": None}


def legacy_load(scene, reading):
    """load_check and phase of a pre-lifecycle save from ``scene``. Rev 13: its position is derived once from the
    scene through the scene-to-id map, and a scene the map lacks leaves the field missing (D0). Rev 12 stored no
    position for it and said nothing of deriving one, so the defaulted record sits at the default position PRE_C8."""
    pos = LEGACY_SCENES[scene] if reading.legacy_derive else "PRE_C8"
    if pos is None:
        return {"D0"}, "DAMAGED", pos
    lc = load_check_save(None, LEGACY_SCHEMA, frozenset(), pos, reading)
    rec = decode(None, LEGACY_SCHEMA, reading)
    if rec is MISSING_FIELD:    # rev 11: an older save was D0, not defaulted
        return lc, "DAMAGED", pos
    return lc, phase_of(rec, True, frozenset(), pos, reading), pos


# ---------------------------------------------------------------------------------------------------------------
# Revision 14 (design review round 14): the whole stored record, D0's clause ids, the hub-safe legacy derivation
# ---------------------------------------------------------------------------------------------------------------
ACT1_PACE = ("act1_pace_early", "act1_pace_on_time", "act1_pace_late")
D0_CLAUSE_IDS = ("D0.missing", "D0.type", "D0.enum", "D0.element", "D0.duplicate", "D0.max")
D0_DECODER_ONLY = ("D0.duplicate",)   # a frozenset cannot hold one element twice (M12): SaveService's decoder tests
# The composer record's other closed-list fields (Composer input record): the 1.0 companions and the timing flags.
COMPANIONS_1_0 = frozenset({"Elara", "Seraphina", "Lyra"})
TIMING_FLAGS = frozenset({"ch1_bridge_saved", "ch1_bridge_evacuated", "ch1_bridge_fell", "ch2_medicine_early",
                          "ch2_medicine_on_time", "ch2_medicine_late"})
NEW_GAME_EXTRA = {"act1_pace": UNSET, "story_position": "PRE_C8", "companions_present": frozenset(),
                  "timing_flags": frozenset()}


def d0_clauses(rec, beats_max=1, commitment_rule=False):
    """Rev 14: the D0 clause ids a typed record shows. D0.missing is the decoder's (a field absent from a stored save)
    and D0.duplicate cannot be built from a frozenset (M12). Non-empty exactly when shape_wrong() is true."""
    out = set()
    if (not isinstance(rec.storyline_id, str) or not isinstance(rec.axis_revised, frozenset)
            or not isinstance(rec.lock_negotiated, frozenset) or not isinstance(rec.retraction_log, tuple)
            or not isinstance(rec.beats_played, frozenset)):
        out.add("D0.type")
    if any(getattr(rec, ax) not in VALUES[ax] + (UNSET,) for ax in LOCK_ORDER) or rec.root_phase not in ROOT_PHASES:
        out.add("D0.enum")
    for name in ("axis_revised", "lock_negotiated"):
        v = getattr(rec, name)
        if isinstance(v, frozenset):
            if any(not isinstance(x, str) for x in v):
                out.add("D0.element")
            elif not v <= frozenset(LOCK_ORDER):
                out.add("D0.enum")
    log = rec.retraction_log
    if isinstance(log, tuple):
        if len(log) > RETRACTION_LOG_MAX:
            out.add("D0.max")
        for e in log:
            if not isinstance(e, Entry) or not isinstance(e.withdrawn_item, str) or not isinstance(e.scene, str):
                out.add("D0.element")
            elif e.axis not in VALUES or e.old not in VALUES[e.axis] or e.new not in VALUES[e.axis]:
                out.add("D0.enum")
    beats = rec.beats_played
    if isinstance(beats, frozenset):
        if any(not isinstance(b, str) for b in beats):
            out.add("D0.element")
        if len(beats) > beats_max:
            out.add("D0.max")
    if commitment_rule and commitment_wrong(rec):
        out.add("D0.enum")
    return out


def stored_save_check(raw, extra, flags, reading):
    """load_check of a current-schema save as stored: the lifecycle block ``raw`` plus the record's other stored
    fields ``extra`` (act1_pace, story_position). Rev 14: story_position is a record field, so a missing or unlisted
    one is D0, and act1_pace allows UNSET. Rev 13: the position is not a record field and no item covers a missing or
    unlisted one (returned as UNDEFINED: the composer would meet it), and act1_pace has no UNSET."""
    tags = set()
    if reading.rev14:
        if "story_position" not in extra:
            tags.add("D0.missing")
        elif extra["story_position"] not in PIDX:
            tags.add("D0.enum")
        pace_ok = (UNSET,) + ACT1_PACE
    else:
        if extra.get("story_position") not in PIDX:
            return {"UNDEFINED"}
        pace_ok = ACT1_PACE
    if "act1_pace" not in extra:
        tags.add("D0.missing")
    elif extra["act1_pace"] not in pace_ok:
        tags.add("D0.enum")
    for name, allowed in (("companions_present", COMPANIONS_1_0), ("timing_flags", TIMING_FLAGS)):
        v = extra.get(name)
        if v is None:
            tags.add("D0.missing")
        elif not isinstance(v, frozenset):
            tags.add("D0.type")
        elif any(not isinstance(x, str) for x in v):
            tags.add("D0.element")
        elif not v <= allowed:
            tags.add("D0.enum")
    rec = decode(raw, CURRENT_SCHEMA, reading)
    if rec is MISSING_FIELD:
        tags.add("D0.missing")
    elif reading.rev14:
        tags |= d0_clauses(rec, reading.beats_max, reading.life11)
    elif shape_wrong(rec, reading.beats_max, reading.life11):
        tags.add("D0")
    if tags:
        return tags if reading.rev14 else {"D0"}
    return load_check_tags(rec, flags, extra["story_position"], True, reading)


# Rev 14: the scene-to-id map holds story scenes only (stand-ins for Y1-P1-T03's map), never a hub.
SCENE_TO_ID = {"ch5_mirror_city_intro": "PRE_C8", "ch8_ending": "S16_DONE", "ch9_memory_lab": "CH9",
               "ch10_root_intro": "ROOT"}
HUB_SCENES = frozenset({"overworld", "oakhaven_region", "ironhold_region", "root_of_heaven_prep_hub"})
# Pre-lifecycle saves: (free_travel_story_scene, current_scene, current_chapter) -> expected (load_check, phase).
LEGACY_SAVES = {
    "a Chapter 5 story scene": (("", "ch5_mirror_city_intro", 5), (set(), "LEANING")),
    "a hub in Chapter 3": (("", "oakhaven_region", 3), (set(), "LEANING")),
    "a hub in Chapter 9 with its free-travel story scene": (("ch9_memory_lab", "overworld", 9), ({"D16"}, "DAMAGED")),
    "a hub in Chapter 9 without one": (("", "ironhold_region", 9), ({"D16"}, "DAMAGED")),
    "a hub in Chapter 8": (("", "ironhold_region", 8), ({"D0.missing"}, "DAMAGED")),
    "Chapter 8 - Ending (a mapped story scene)": (("", "ch8_ending", 8), ({"D16"}, "DAMAGED")),
    "a Root of Heaven scene": (("", "ch10_root_intro", 10), ({"D16"}, "DAMAGED")),
}


def legacy_position(ft_scene, scene, chapter, reading):
    """Rev 14 (Terms): the free-travel story scene, else the save's own scene, through the scene-to-id map; else the
    chapter (below 8 PRE_C8, 9 or above CH9); a Chapter 8 save neither places has no position. Rev 13: the save's
    own scene only, and its map put every hub at PRE_C8 (the model's 'a hub before Chapter 8')."""
    if reading.rev14:
        for sc in (ft_scene, scene):
            if sc in SCENE_TO_ID:
                return SCENE_TO_ID[sc]
        return "PRE_C8" if chapter < 8 else "CH9" if chapter >= 9 else None
    if scene in SCENE_TO_ID:
        return SCENE_TO_ID[scene]
    return "PRE_C8" if scene in HUB_SCENES else None


def legacy_save_check(ft_scene, scene, chapter, reading):
    """(load_check tags, phase) of a pre-lifecycle save, defaulted (Edge Case 8) with its position derived once."""
    pos = legacy_position(ft_scene, scene, chapter, reading)
    if pos is None:
        return ({"D0.missing"} if reading.rev14 else {"D0"}), "DAMAGED"
    rec = decode(None, LEGACY_SCHEMA, reading)
    if rec is MISSING_FIELD:    # rev 11: an older save was D0, not defaulted
        return {"D0"}, "DAMAGED"
    tags = load_check_tags(rec, frozenset(), pos, True, reading)
    return tags, phase_of(rec, True, frozenset(), pos, reading)


def live_crisis(rec, loaded, pos):
    """axes rev 11, Formulas: a live record inside C8-S16 before its commit, nothing stored, on an invalid row."""
    a, f, d = row_of(rec)
    return (not loaded and pos == "S16_OPEN" and not rec.storyline_id and UNSET not in (a, f, d)
            and invalid(a, f, d))


def load_check_tags(rec, flags, pos, loaded, reading=LITERAL):
    # D0 (rev 11-12): tested first; when it fires no other item runs, so load_check reports exactly {D0}.
    if reading.d0 and shape_wrong(rec, reading.beats_max, reading.life11):
        return {"D0"}
    tags = set()
    a, f, d = row_of(rec)
    sid = rec.storyline_id
    pi = PIDX[pos]
    if reading.live_crisis_scoped:      # rev 11: the two items are skipped for the live crisis only
        d9_on = d17a_on = not live_crisis(rec, loaded, pos)
    else:                               # rev 9 / rev 10: skipped for every live record (rev 9: D9 only)
        d9_on = loaded
        d17a_on = loaded or reading.d17_before_commit_live
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
    if reading.d7_multi and len(rec.axis_revised) > 1:
        tags.add("D7.multi")
    if any(e.new != getattr(rec, e.axis) for e in rec.retraction_log):
        tags.add("D7.new_mismatch")
    if reading.d7_reverse and any(e.axis not in rec.axis_revised for e in rec.retraction_log):
        tags.add("D7.reverse")
    if reading.d7_duplicate and len(rec.retraction_log) > 1:
        tags.add("D7.duplicate")
    # D8
    if rec.root_phase in ("INSIDE", "FINAL") and not sid:
        tags.add("D8")
    # D9
    if d9_on and UNSET not in (a, f, d) and not sid:
        tags.add("D9")
    # D14
    # Rev 12 sync: "a beat id the lifecycle does not define" is any id outside the 16 retract_* beats (the model
    # tested retract_* ids only through rev 11; every revision's text says the same, so this applies to all).
    implied = {beat_for_entry(rec, e) for e in rec.retraction_log}
    for b in rec.beats_played:
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
    if d17a_on:
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


def events(rec, pos, flags, knobs, defects, reading, commitment="LISTEN"):
    """Every event enabled in (rec, pos): (label, kind, new_rec, new_pos, checkpoint). Rev 15: T2 and T5 write the
    commitment chosen when YOU is backed (``commitment``), and a hub revival leaves Root of Heaven."""
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
        for v in VALUES["authority"]:
            new = lock(rec, flags, "authority", v)
            if reading.life11 and v == "YOU":
                new = new._replace(kaelen_commitment=commitment)
            out.append((f"T2 back {v}", "T2", new, "S14_DONE", True))
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
            if reading.life11 and axis == "authority" and v == "YOU":
                new = new._replace(kaelen_commitment=commitment)
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
        if reading.life11:
            out.append(("hub revival", "move", rec, "ROOT_LEFT", False))
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
        if reading.life11:
            out.append(("hub revival", "move", rec, "STORY_PLUS", False))
    return out


def model_windows(defects):
    w = set(SPEC_WINDOWS)
    if "save_in_crisis" in defects:
        w.discard("S16_OPEN")
    if "save_in_final_auth" in defects:
        w.discard("FINAL_AUTH_OPEN")
    return w


# ---------------------------------------------------------------------------------------------------------------
# Lifecycle revision 11 (review 2026-11-18): chapter-select rows, scene placement, windows, take(), the NG+ reset
# ---------------------------------------------------------------------------------------------------------------
CS_FINAL_RECORD = CHAPTER_SELECT_RECORD._replace(root_phase="FINAL")
SUPERSEDED = frozenset({"ch8_revolt_crisis", "ch10_sovereign_confrontation"})
# main_menu.gd's Chapter 8-10 entries in file order: (row, label, the scene main_menu.gd loads today).
CHAPTER_SELECT_ROWS = (
    (1, "Chapter 8 - Revolt Intro", "ch8_revolt_intro"), (2, "Chapter 8 - Saved Assembly", "ch8_saved_assembly"),
    (3, "Chapter 8 - Revolt Crisis", "ch8_revolt_crisis"), (4, "Chapter 8 - Ending", "ch8_ending"),
    (5, "Chapter 9 - Human Patch", "ch9_human_patch_intro"), (6, "Chapter 9 - Memory Lab", "ch9_memory_lab"),
    (7, "Chapter 9 - Creator Trial", "ch9_creator_trial"), (8, "Chapter 9 - Ending", "ch9_ending"),
    (9, "Chapter 10 - Root of Heaven", "ch10_root_intro"), (10, "Chapter 10 - Kernel Descent", "ch10_kernel_descent"),
    (11, "Chapter 10 - Witness Chamber", "ch10_witness_chamber"),
    (12, "Chapter 10 - Final Confrontation", "ch10_sovereign_confrontation"),
    (13, "Chapter 10 - True Ending", "ch10_ending"))
# Scene placement (rev 15): scene -> (story position, in the Root of Heaven scene set, next story scene or None).
PLACEMENT = {
    "ch8_revolt_intro": ("PRE_C8", False, "ch8_saved_assembly"),
    "ch8_saved_assembly": ("PRE_C8", False, "C8-S13"),
    "C8-S13": ("S13_OPEN", False, "C8-S14"), "C8-S14": ("S14_OPEN", False, "C8-S15"),
    "C8-S15": ("S15", False, "C8-S16"), "C8-S16": ("S16_OPEN", False, "ch8_ending"),
    "ch8_revolt_crisis": (None, False, None),
    "ch8_ending": ("S16_DONE", False, "ch9_human_patch_intro"),
    "ch9_human_patch_intro": ("CH9", False, "ch9_memory_lab"), "ch9_memory_lab": ("CH9", False, "ch9_creator_trial"),
    "ch9_creator_trial": ("CH9", False, "C9-S18"), "C9-S18": ("CH9", False, "ch9_ending"),
    "ch9_ending": ("CH9", False, "ch10_root_intro"),
    "ch10_root_intro": ("ROOT", True, "ch10_kernel_descent"),
    "ch10_kernel_descent": ("ROOT", True, "ch10_witness_chamber"),
    "ch10_witness_chamber": ("ROOT", True, "ch10_sovereign_final_trial"),
    "ch10_sovereign_final_trial": ("ROOT", True, "final_authorization"),
    "final_authorization": ("FINAL_AUTH_OPEN", True, "ch10_ending"),
    "ch10_sovereign_confrontation": (None, True, None),
    "ch10_ending": ("FINAL_DONE", True, None),
}
LOAD_GATE_POSITIONS = frozenset({"ROOT", "FINAL_DONE", "ROOT_STORY_PLUS"})
# Rev 15 position writers: position -> the walk events (kind, label prefix) that write it, beside the starts.
WRITERS = {
    "PRE_C8": (), "S13_OPEN": (("move", "start C8-S13"),), "S13_DONE": (("T1", "T1"),),
    "S14_OPEN": (("move", "start C8-S14"),), "S14_DONE": (("T2", "T2"),), "S15": (("move", "start C8-S15"),),
    "S16_OPEN": (("move", "start C8-S16"), ("T4", "T4")), "S16_DONE": (("T3", "T3"), ("T5", "T5")),
    "CH9": (("move", "leave C8-S16"),), "ROOT": (("T7", "story gate"), ("T8", "world_map gate")),
    "ROOT_LEFT": (("move", "leave Root of Heaven"), ("move", "hub revival")),
    "FINAL_AUTH_OPEN": (("move", "defeat the boss"),), "FINAL_DONE": (("T9", "T9"),),
    "STORY_PLUS": (("move", "enter Story+"), ("move", "leave Root of Heaven"), ("move", "hub revival")),
    "ROOT_STORY_PLUS": (("T8", "world_map gate"),),
}
# The window table (rev 15): transition -> (window opens, commit position, resume point). "gate" = the gate check.
WINDOW_TABLE = {"T1": ("S13_OPEN", "S13_DONE", "c8s13_after_vote"), "T2": ("S14_OPEN", "S14_DONE", "c8s14_after_vote"),
                "T3": ("S16_OPEN", "S16_DONE", "c8s16_after_vote"), "T5": ("S16_OPEN", "S16_DONE", "retract_*"),
                "T7": ("gate", "ROOT", "root_entry"), "T9": ("FINAL_AUTH_OPEN", "FINAL_DONE",
                                                           "final_auth_after_confirm")}
# Lifecycle revision 10's commit rule: windows from "the start of its scene"; T7 has no scene, and the rule names no
# resume point for T1, T2, T7 or T9 (the review's L-AC6 finding).
WINDOW_TABLE_REV10 = {"T1": ("S13_OPEN", "S13_DONE", None), "T2": ("S14_OPEN", "S14_DONE", None),
                      "T3": ("S16_OPEN", "S16_DONE", "the committed beat"),
                      "T5": ("S16_OPEN", "S16_DONE", "retract_*"), "T7": (None, "ROOT", None),
                      "T9": ("FINAL_AUTH_OPEN", "FINAL_DONE", None)}
NEW_GAME_FULL = dict(NEW_GAME_EXTRA, regions_completed=frozenset(), act2_pace=UNSET, act3_pace=UNSET, act4_pace=UNSET)


def chapter_select_row(row, reading):
    """(record written, position written, entry scene) for a chapter-select row, or None when the text leaves the
    row unplaced. Rev 15: the lifecycle's table. Rev 14 (lifecycle rev 10): keyed to the entry scene's position by
    one rule (S16_DONE for a Chapter 8 entry after the locks, CH9 for Chapter 9 and every Root of Heaven entry), with
    no placement for the Saved Assembly or the Revolt Crisis, and the legacy scenes loaded as they are."""
    n, _label, scene = CHAPTER_SELECT_ROWS[row - 1]
    if reading.life11:
        if n <= 3:
            return EMPTY, "PRE_C8", ("C8-S13" if n == 3 else scene)
        if n == 4:
            return CHAPTER_SELECT_RECORD, "S16_DONE", scene
        if n == 13:
            return CS_FINAL_RECORD, "FINAL_DONE", scene
        return CHAPTER_SELECT_RECORD, "CH9", ("ch10_sovereign_final_trial" if n == 12 else scene)
    if n == 1:
        return EMPTY, "PRE_C8", scene
    if n in (2, 3):
        return None
    if n == 4:
        return CHAPTER_SELECT_RECORD, "S16_DONE", scene
    return CHAPTER_SELECT_RECORD, "CH9", scene


def first_save(row, reading, flags=frozenset()):
    """(record, position) of the first save after a chapter-select start: the entry scene's autosave, T1's
    checkpoint when the entry scene opens a window at its start (C8-S13), or T7's checkpoint for a Root of Heaven
    entry from CH9."""
    got = chapter_select_row(row, reading)
    if got is None:
        return None
    rec, pos, scene = got
    placed = PLACEMENT.get(scene, (None, False, None))
    if scene == "C8-S13":
        return lock(rec, flags, "faction", "ARCHIVE"), "S13_DONE"
    if placed[1] and pos == "CH9":            # enters through the gate from CH9
        out = gate(rec, flags, "CH9", "ROOT", "chapter select", frozenset(), reading)[0]
        return out[2], out[3]
    return rec, pos


def take(rec, pos, offer, reading, defects=frozenset()):
    """Lifecycle observable take(offer). Rev 15: submitted to the T5 handler (``t5_handler``) in any scene. Rev 14
    (lifecycle rev 10): 'true if the offer is in offers() and was taken; otherwise false', so the handler is never
    called outside the crisis and a handler that takes offers anywhere is invisible."""
    if not reading.life11 and offer not in offers(rec, pos, defects):
        return False, rec
    new = t5_handler(rec, pos, offer, defects)
    return (new is not None), (new if new is not None else rec)


def t5_handler(rec, pos, offer, defects=frozenset()):
    """The production T5 handler the crisis screen calls: the renegotiated record, or None if it refuses. Defect
    ``handler_ignores_scene``: it applies any offer whose result is a valid row, in any scene."""
    _, axis, v = offer.split(":")
    if offer in offers(rec, pos, defects):
        new = rec._replace(**{axis: v})
        return new._replace(storyline_id=f"SL-{new.authority}-{new.faction}-{new.deleted}")
    if "handler_ignores_scene" in defects and UNSET not in row_of(rec) and getattr(rec, axis) != v:
        new = rec._replace(**{axis: v})
        if not invalid(*row_of(new)):
            return new._replace(storyline_id=f"SL-{new.authority}-{new.faction}-{new.deleted}")
    return None


def ng_plus_full(rec, extra, pos, reading):
    """The NG+ reset of the whole stored record: (record, other stored fields). Rev 15: every field to a new game's
    default. Rev 14 (lifecycle rev 10): the lifecycle block and the position only; companions_present,
    regions_completed, timing_flags and the paces keep the old cycle's values."""
    new_rec, new_pos = ng_plus(rec, pos, reading)
    if reading.life11:
        return new_rec, dict(NEW_GAME_FULL, story_position=new_pos)
    return new_rec, dict(extra, story_position=new_pos)


def quoted_commitment(rec):
    """Lifecycle observable quoted_commitment(): (status, commitment)."""
    if rec.authority == "YOU":
        return "STATED", rec.kaelen_commitment
    if held_you(rec):
        return "WITHDRAWN", rec.kaelen_commitment
    return "NONE", rec.kaelen_commitment


def life11_checks(reading, contexts_sample):
    """Unit checks of lifecycle revision 11 (rev 15). Every check starts with a prefix the regression names."""
    res = []

    def chk(cid, ok, detail=""):
        res.append((cid, bool(ok), detail))

    flags0 = contexts_sample[0]
    # 1. Chapter select: 13 rows, each placed, none at a window or a superseded scene, each first save loading to
    # its phase, True Ending FINAL, Final Confrontation reaching T9, the Root of Heaven entries through T7.
    bad = []
    for n, label, _scene in CHAPTER_SELECT_ROWS:
        got = chapter_select_row(n, reading)
        if got is None:
            bad.append(f"row {n} {label}: unplaced")
            continue
        rec, pos, scene = got
        if scene in SUPERSEDED:
            bad.append(f"row {n} {label}: enters the superseded {scene}")
        if pos in SPEC_WINDOWS or (PIDX["S13_OPEN"] <= PIDX[pos] < PIDX["S16_DONE"]):
            bad.append(f"row {n}: starts at {pos}")
        fs = first_save(n, reading, flags0)
        frec, fpos = fs
        extra = dict(NEW_GAME_EXTRA, story_position=fpos)
        lc = stored_save_check(frec._asdict(), extra, flags0, reading)
        ph = phase_of(frec, True, flags0, fpos, reading) if not lc else "DAMAGED"
        want = {13: "FINAL"}.get(n, "FIXED" if PLACEMENT.get(scene, (0, False))[1] else
                                 "PARTLY_LOCKED" if n == 3 else "LEANING" if n <= 2 else "VALIDATED")
        if lc or ph != want:
            bad.append(f"row {n} {label}: first save at {fpos} {sorted(lc)} loads {ph}, expected {want}")
        if fpos in LOAD_GATE_POSITIONS:
            g = gate(frec, flags0, fpos, fpos, "load", frozenset(), reading)[0]
            if not g[0].endswith("ROOT_OF_HEAVEN"):
                bad.append(f"row {n}: load-path gate {g[0]}")
    # Final Confrontation: the walk from its first save reaches T9.
    fc = first_save(12, reading, flags0)
    seen, edges, _ = walk(flags0, DEFAULT_KNOBS, frozenset(), reading)
    t9_from_fc = fc is not None and any(e[2] == "T9" for e in edges) and fc in seen
    chk("Chapter select rows (rev 15): the 13 Chapter 8-10 entries are each placed, none starts in a window or "
        "enters a superseded scene, each first save loads to its phase (True Ending FINAL, Root of Heaven entries "
        "FIXED through T7), and Final Confrontation reaches T9", not bad and t9_from_fc, "; ".join(bad[:4]))
    # 2. Root of Heaven positions and the scene placement: the set, the load-gate positions, writers for every
    # position, no story step into a superseded scene, every walk edge writing its target through a named writer.
    root_pos = {p for s, (p, inr, _) in PLACEMENT.items() if inr and p} | {"ROOT_STORY_PLUS"}
    pbad = []
    if not reading.life11:
        pbad.append("no placement table, Root of Heaven scene set or position writers (lifecycle rev 10)")
    if root_pos != ROOT_POSITIONS:
        pbad.append(f"Root scene positions {sorted(root_pos)} != ROOT_POSITIONS")
    if ROOT_POSITIONS - SPEC_WINDOWS != LOAD_GATE_POSITIONS:
        pbad.append("load-gate positions differ")
    if set(WRITERS) != set(POSITIONS):
        pbad.append("a position has no writer row")
    if any(nxt in SUPERSEDED for _, _, nxt in PLACEMENT.values()):
        pbad.append("a story step leads into a superseded scene")
    for (s, label, kind, t, ck) in edges:
        if t[1] == s[1]:
            continue
        ok = any(kind == k and label.startswith(pre) for k, pre in WRITERS.get(t[1], ()))
        if not ok:
            pbad.append(f"'{label}' ({kind}) writes {t[1]}, which names no such writer")
            break
    revival = [e for e in edges if e[1] == "hub revival"]
    if reading.life11 and (not revival or any(e[3][0] != e[0][0] or e[3][1] not in ("ROOT_LEFT", "STORY_PLUS")
                                              for e in revival)):
        pbad.append("a hub revival changes the record or lands elsewhere")
    chk("Root positions (rev 15): the Root of Heaven scene set gives ROOT_POSITIONS, the load gate runs at ROOT, "
        "FINAL_DONE and ROOT_STORY_PLUS, every position has a writer and every walk step uses one, a hub revival "
        "writes ROOT_LEFT/STORY_PLUS only, and no story step reaches a superseded scene", not pbad,
        "; ".join(pbad[:3]))
    # 3. Windows: every checkpoint transition has a window with an opening, a commit and a resume point; each
    # checkpoint edge goes from its opening to its commit; nothing of that kind replays from the commit.
    table = WINDOW_TABLE if reading.life11 else WINDOW_TABLE_REV10
    wbad = []
    kinds = {e[2] for e in edges if e[4]}
    if kinds != set(table):
        wbad.append(f"checkpoint kinds {sorted(kinds)} != window rows {sorted(table)}")
    for k, (opens, commit, resume) in table.items():
        if opens is None or resume is None:
            wbad.append(f"{k}: no window opening or resume point")
    resumes = [r for _, _, r in table.values()]
    if len(set(resumes)) != len(resumes):
        wbad.append("resume points not distinct")
    out_by = defaultdict(list)
    for e in edges:
        out_by[e[0]].append(e)
    for (s, label, kind, t, ck) in edges:
        if not ck or kind not in table:
            continue
        opens, commit, _ = table[kind]
        src_ok = (s[1] not in ROOT_POSITIONS) if opens == "gate" else s[1] == opens
        if not src_ok or t[1] != commit:
            wbad.append(f"{kind} checkpoint {s[1]} -> {t[1]}, table {opens} -> {commit}")
        if any(e[2] == kind or (kind in ("T3", "T5") and e[2] in ("T5", "LATE_OFFER")) for e in out_by[t]):
            wbad.append(f"{kind} replays after its commit at {t[1]}")
    if any(e[2] in ("T4", "T6", "T8") and e[4] for e in edges):
        wbad.append("T4, T6 or T8 writes a checkpoint")
    chk("Windows (rev 15): every checkpoint transition (T1, T2, T3, T5, T7, T9) has a window opening, a commit and "
        "a distinct resume point; each checkpoint goes from its opening to its commit and never replays",
        not wbad, "; ".join(list(dict.fromkeys(wbad))[:3]))
    # 4. take() through the T5 handler: outside the crisis every offer is refused with the record unchanged, and a
    # handler that ignores the scene is caught.
    all_offers = sorted({o for row in RULES.values() for o in crisis_offers(row)})

    def take_holds(defects):
        for rec, pos in seen:
            in_crisis = bool(offers(rec, pos, frozenset()))
            for o in all_offers:
                ok, new = take(rec, pos, o, reading, defects)
                if in_crisis:
                    if ok != (o in offers(rec, pos, frozenset())):
                        return False
                elif ok or new != rec:
                    return False
        return True
    clean, caught = take_holds(frozenset()), not take_holds(frozenset({"handler_ignores_scene"}))
    chk("take() via the T5 handler (rev 15): outside the crisis take() of each of the 16 offers is false with the "
        "record unchanged, and a handler that takes offers in any scene fails that check", clean and caught,
        f"clean {clean}, defect caught {caught}")
    # 5. The NG+ reset of every stored field.
    full = fit_commitment(EMPTY._replace(
        authority="YOU", faction="ARCHIVE", deleted="RELEASE", storyline_id="SL-YOU-ARCHIVE-RELEASE",
        root_phase="FINAL", axis_revised=frozenset({"authority"}), lock_negotiated=frozenset(LOCK_ORDER),
        retraction_log=(Entry("authority", "NONE", "YOU", WITHDRAWN["authority"]["NONE"], "C8-S16"),),
        beats_played=frozenset({"retract_R2_authority_YOU"})), "CANNOT_PROMISE_NEVER")
    extra = {"act1_pace": "act1_pace_late", "story_position": "STORY_PLUS", "companions_present": frozenset({"Elara"}),
             "timing_flags": frozenset({"ch1_bridge_saved"}), "regions_completed": frozenset({"oakhaven"}),
             "act2_pace": "act2_pace_s06b", "act3_pace": "act3_pace_s06b", "act4_pace": "act4_pace_s06b"}
    pre = stored_save_check(full._asdict(), extra, frozenset(), reading)
    nrec, nextra = ng_plus_full(full, extra, "STORY_PLUS", reading)
    same = nrec == EMPTY and nextra == NEW_GAME_FULL
    post = stored_save_check(nrec._asdict(), nextra, frozenset(), reading)
    chk("NG+ full reset (rev 15): from a FINAL Story+ record with every field set, the new cycle's record equals a "
        "new game's field for field and its first save loads LEANING", not pre and same and not post,
        f"before {sorted(pre)}, equal {same}, after {sorted(post)}, kept "
        f"{sorted(k for k in NEW_GAME_FULL if nextra.get(k) != NEW_GAME_FULL[k])}")
    # 6. The commitment: each choice is written by T2/T5 and survives; D0 refuses the inconsistent records;
    # quoted_commitment follows L-AC12.
    cbad = []
    for choice in COMMITMENTS:
        s2, e2, saves2 = walk(flags0, DEFAULT_KNOBS, frozenset(), reading, choice)
        fails2 = []
        stats2 = defaultdict(set)
        for k in ("states", "saves", "edges"):
            stats2[k] = 0
        check_walk(flags0, s2, e2, saves2, reading, fails2, stats2)
        if fails2:
            cbad.append(f"{choice}: {fails2[0]}")
        if any(r.authority == "YOU" and r.kaelen_commitment != choice for r, _ in saves2):
            cbad.append(f"{choice}: a YOU save does not hold it")
    you = fit_commitment(_PLAIN)
    d0 = {"YOU, UNSET": load_check(you._replace(kaelen_commitment=UNSET), frozenset(), "S16_DONE", reading),
          "SHARED, LISTEN": load_check(CHAPTER_SELECT_RECORD._replace(kaelen_commitment="LISTEN"), frozenset(), "CH9",
                                       reading),
          "YOU, BOGUS": load_check(you._replace(kaelen_commitment="BOGUS"), frozenset(), "S16_DONE", reading),
          "YOU, LISTEN": load_check(you, frozenset(), "S16_DONE", reading)}
    if d0 != {"YOU, UNSET": {"D0"}, "SHARED, LISTEN": {"D0"}, "YOU, BOGUS": {"D0"}, "YOU, LISTEN": set()}:
        cbad.append(f"D0 {d0}")
    withdrawn = fit_commitment(EMPTY._replace(
        authority="SHARED", faction="HEARTH", deleted="RESTORE", storyline_id="SL-SHARED-HEARTH-RESTORE",
        axis_revised=frozenset({"authority"}), lock_negotiated=frozenset(LOCK_ORDER),
        retraction_log=(Entry("authority", "YOU", "SHARED", WITHDRAWN["authority"]["YOU"], "C8-S16"),),
        beats_played=frozenset({"retract_R1_authority_SHARED"})))
    qc = (quoted_commitment(you)[0], quoted_commitment(withdrawn)[0], quoted_commitment(CHAPTER_SELECT_RECORD)[0])
    if qc != ("STATED", "WITHDRAWN", "NONE") or load_check(withdrawn, frozenset(), "S16_DONE", reading):
        cbad.append(f"quoted {qc}, withdrawn record {sorted(load_check(withdrawn, frozenset(), 'S16_DONE', reading))}")
    chk("Commitment (rev 15): T2 and T5 store each of the three commitments and every YOU save holds the chosen one "
        "(A1-A14 hold per choice); D0 refuses UNSET on a YOU record, a commitment on a never-YOU record and an "
        "unlisted value; a withdrawn YOU keeps it and reads WITHDRAWN", not cbad, "; ".join(cbad[:3]))
    return res


# ---------------------------------------------------------------------------------------------------------------
# Walk
# ---------------------------------------------------------------------------------------------------------------
def walk(flags, knobs=DEFAULT_KNOBS, defects=frozenset(), reading=LITERAL, commitment="LISTEN"):
    # A new game starts at PRE_C8; lifecycle rev 8 adds chapter select of Chapter 9 or 10 (its record at CH9; a
    # Chapter 10 select then runs the gate from CH9, which is the walk's story gate). Before Chapter 8 (and, as the
    # model reads F12, Chapter 8 itself) chapter select writes the new-game start.
    starts = [(EMPTY, "PRE_C8")] + ([chapter_select(9)] if reading.chapter_select else [])
    if reading.cs_by_position:   # lifecycle rev 9: "Chapter 8 - Ending" starts at S16_DONE with the fixed record
        cs8 = chapter_select_entry(8, "S16_DONE", reading)
        if cs8 not in starts:
            starts.append(cs8)
    if reading.life11:           # lifecycle rev 11, chapter-select row 13: True Ending, FINAL at FINAL_DONE
        starts.append((CS_FINAL_RECORD, "FINAL_DONE"))
    seen = set(starts)
    q = deque(starts)
    edges = []
    while q:
        s = q.popleft()
        for label, kind, nrec, npos, ckpt in events(*s, flags, knobs, defects, reading, commitment):
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
    """Every subset of the axis seeds the code allows (exclusive groups: at most one Data Wraith flag)."""
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
    sd = reading.seeds
    lp_bad = [(sorted(fl), ax, v, lock_pass(fl, ax, v, sd)) for fl, ax, v, exp in lp if lock_pass(fl, ax, v, sd) != exp]
    chk("lock_pass: Formulas examples + L-AC2 fixtures (13)", not lp_bad, str(lp_bad))
    # Rev 12 (round 12, P10): the Formulas' new examples, and a justified kill or a show-off edit argues against YOU,
    # so a player who acted alone and called it justified hears sole_dissent. A modifier row never enters the test.
    p10 = [({"ch1_root_first_edit", "ch1_aldric_kill_justified"}, "authority", "YOU", "NEGOTIATED"),
           ({"ch2_seraphina_truth"}, "authority", "SHARED", "CLEAN"),
           ({"ch1_aldric_kill_owned"}, "authority", "YOU", "CLEAN"),
           ({"ch1_aldric_kill_owned", "ch1_aldric_kill_justified"}, "authority", "YOU", "NEGOTIATED"),
           ({"ch1_root_first_edit", "ch2_seraphina_showoff"}, "authority", "YOU", "NEGOTIATED"),
           ({"ch2_seraphina_truth", "ch2_seraphina_showoff"}, "authority", "YOU", "NEGOTIATED"),
           ({"ch1_knight_spared", "ch2_seraphina_cautious"}, "authority", "SHARED", "NEGOTIATED")]
    p10_bad = [(sorted(fl), ax, v, lock_pass(fl, ax, v, sd)) for fl, ax, v, exp in p10
               if lock_pass(fl, ax, v, sd) != exp]
    chk("P10 lock_pass (rev 12 Authority seeds): a justified kill or a show-off edit makes a YOU vote negotiated; "
        "ch2_seraphina_truth backs SHARED clean; modifier rows never enter the test", not p10_bad, str(p10_bad))
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
        return fit_commitment(EMPTY._replace(authority=a, faction=f, deleted=d, storyline_id=sid, root_phase=root,
                                             **kw))
    ex = [(rec("YOU", "HEARTH", UNSET), True, "S15", "PARTLY_LOCKED"),
          (rec("SHARED", "ARCHIVE", "CHOOSE", "SL-SHARED-ARCHIVE-CHOOSE", "INSIDE",
               lock_negotiated=frozenset(LOCK_ORDER)), True, "ROOT", "FIXED"),
          (rec("YOU", "HEARTH", UNSET, root="FINAL"), True, "S15", "DAMAGED"),
          (rec("NONE", "ARCHIVE", "RELEASE"), True, "CH9", "DAMAGED"),
          (rec("NONE", "ARCHIVE", "RELEASE"), True, "S16_OPEN", "DAMAGED"),
          (rec("NONE", "ARCHIVE", "RELEASE"), False, "S16_OPEN", "CRISIS"),
          # rev 11 (OQ18): the live crisis is bounded
          (rec("NONE", "ARCHIVE", "RELEASE"), False, "CH9", "DAMAGED"),
          (rec("SHARED", "ARCHIVE", "CHOOSE"), False, "S16_OPEN", "DAMAGED")]
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
    # rev 11 (OQ18): AC9's bounded live crisis, each with loaded=false
    revd = rec("YOU", "HEARTH", "RELEASE", axis_revised=frozenset({"deleted"}), lock_negotiated=frozenset(LOCK_ORDER),
               retraction_log=(Entry("deleted", "RESTORE", "RELEASE", WITHDRAWN["deleted"]["RESTORE"], "C8-S16"),),
               beats_played=frozenset({"retract_R1_deleted_RELEASE"}))
    bounded = {"CRISIS fixture in Chapter 9": (cr, "CH9"),
               "CRISIS fixture at C8-S16's commit checkpoint": (cr, "S16_DONE"),
               "valid row, nothing stored, inside C8-S16": (rec("SHARED", "ARCHIVE", "CHOOSE",
                                                                lock_negotiated=frozenset(LOCK_ORDER)), "S16_OPEN"),
               "valid stored ID inside C8-S16 before its commit": (fx["VALIDATED"][0], "S16_OPEN"),
               "D9 fixture": (revd._replace(storyline_id=""), "S16_DONE"),
               "D17 before-commit fixture": (revd._replace(storyline_id="SL-YOU-HEARTH-RELEASE"), "PRE_C8")}
    bad_b = [k for k, (r_, pos) in bounded.items() if phase_of(r_, False, frozenset(), pos, reading) != "DAMAGED"]
    chk("AC9 bounded live crisis (loaded=false): Chapter 9, the commit checkpoint, a live valid row, a stored ID "
        "before the commit, the D9 and D17 fixtures are DAMAGED", not bad_b, str(bad_b))
    # rev 11 (OQ17): one fixture per non-goal loads (load_check empty)
    good = revd._replace(storyline_id="SL-YOU-HEARTH-RELEASE")
    nongoals = {"edited lock_negotiated": (good._replace(lock_negotiated=frozenset({"authority", "deleted"})),
                                           "S16_DONE"),
                "edited withdrawn_item": (good._replace(retraction_log=(good.retraction_log[0]._replace(
                    withdrawn_item="something else"),)), "S16_DONE"),
                "edited scene": (good._replace(retraction_log=(good.retraction_log[0]._replace(
                    scene="C8-S13"),)), "S16_DONE"),
                "FINAL record before the final authorization": (good._replace(root_phase="FINAL"), "CH9")}
    bad_n = [k for k, (r_, pos) in nongoals.items() if load_check(r_, frozenset(), pos, reading)]
    chk("AC9 non-goals load: an edited lock_negotiated, withdrawn_item and scene, and a FINAL record before the final "
        "authorization give load_check empty", not bad_n, str(bad_n))
    # AC9 clause isolation, hand-built fixtures: each gives load_check tags exactly {its clause} under this text.
    hand = {c: fx_ for c, fx_ in HAND_FIXTURES.items() if c in reading.clauses()}
    bad_h = {c: sorted(load_check_tags(r_, frozenset(), pos, True, reading)) for c, (r_, pos) in hand.items()
             if load_check_tags(r_, frozenset(), pos, True, reading) != {c}}
    chk(f"AC9 hand-built clause fixtures ({', '.join(hand)}) each give exactly their clause", not bad_h, str(bad_h))
    # Rev 12 (round 12): D0 owns the one-entry cap. The two-entry fixture holds the R2 and R3 Faction retractions of
    # (NONE, HEARTH, RELEASE); each entry alone is a consistent record play writes.
    two = TWO_ENTRY_RECORD
    singles = [two._replace(retraction_log=(e,), beats_played=frozenset({beat_for_entry(two, e)}))
               for e in two.retraction_log]
    single_lc = [sorted(load_check(r_, frozenset(), "S16_DONE", reading)) for r_ in singles]
    chk("AC9 D0 two-entry retraction_log: the R2 and R3 Faction retractions of (NONE, HEARTH, RELEASE) are each "
        "consistent alone, and together give load_check exactly {D0}",
        load_check_tags(two, frozenset(), "S16_DONE", True, reading) == {"D0"} and single_lc == [[], []]
        and {beat_for_entry(two, e) for e in two.retraction_log} == {"retract_R2_faction_HEARTH",
                                                                       "retract_R3_faction_HEARTH"},
        f"together {sorted(load_check_tags(two, frozenset(), 'S16_DONE', True, reading))}, alone {single_lc}")
    d0_bad = {k: sorted(load_check_save(raw, schema, frozenset(), pos, reading))
              for k, (raw, schema, pos) in D0_FIXTURES.items()
              if load_check_save(raw, schema, frozenset(), pos, reading) != {"D0"}}
    chk(f"AC9 D0 fixtures ({', '.join(D0_FIXTURES)}) each give exactly {{D0}} (a set holding one element twice is "
        "not modelled, M12)", not d0_bad, str(d0_bad))
    # Rev 12 (Edge Case 8): a save of the previous schema version with no lifecycle block is defaulted first.
    leg_pre = load_check_save(None, LEGACY_SCHEMA, frozenset(), "PRE_C8", reading)
    leg_ph = phase_of(decode(None, LEGACY_SCHEMA, reading), True, frozenset(), "PRE_C8", reading) \
        if decode(None, LEGACY_SCHEMA, reading) is not MISSING_FIELD else "D0"
    leg_ch9 = load_check_save(None, LEGACY_SCHEMA, frozenset(), "CH9", reading)
    chk("AC9 legacy: a pre-lifecycle save, defaulted before the check, loads LEANING with load_check empty at PRE_C8 "
        "and gives exactly {D16} at CH9", not leg_pre and leg_ph == "LEANING" and leg_ch9 == {"D16"},
        f"PRE_C8 {sorted(leg_pre)} {leg_ph}; CH9 {sorted(leg_ch9)}")
    # Rev 12 sync: D14 refuses any beat id the lifecycle does not define, not only a malformed retract_* id.
    undef = {b: sorted(load_check_tags(_PLAIN._replace(beats_played=frozenset({b})), frozenset(), "S16_DONE", True,
                                       reading))
             for b in ("retract_R9_faction_NOWHERE", "sole_dissent", "red_line_R1")}
    chk("D14 refuses any beat id the lifecycle does not define (retract_R9_faction_NOWHERE, sole_dissent, "
        "red_line_R1 each give exactly {D14.undefined})", all(v == ["D14.undefined"] for v in undef.values()),
        str(undef))
    # Lifecycle rev 8, Chapter select and L-AC19 (the gate is one predicate on every scene change into Root of Heaven).
    if reading.chapter_select:
        cs_rec, cs_pos = chapter_select(9)
        cs10 = gate(cs_rec, frozenset(), cs_pos, "ROOT", "chapter select", frozenset(), reading)[0]
        early = [chapter_select(c) for c in range(1, 8 if reading.cs_by_position else 9)]
        chk("Chapter select: Chapter 9 or 10 writes SL-SHARED-ARCHIVE-CHOOSE at CH9 with lock_negotiated all three, "
            "load_check empty, VALIDATED, family BOUND (no sole_dissent); Chapter 10's gate runs T7; Chapters 1-8 "
            "start LEANING at PRE_C8 (Chapter 8: F12)",
            cs_pos == "CH9" and cs_rec.storyline_id == "SL-SHARED-ARCHIVE-CHOOSE"
            and cs_rec.lock_negotiated == frozenset(LOCK_ORDER) and not cs_rec.axis_revised
            and not cs_rec.retraction_log and not cs_rec.beats_played and cs_rec.root_phase == "OUTSIDE"
            and not load_check(cs_rec, frozenset(), cs_pos, reading)
            and phase_of(cs_rec, True, frozenset(), cs_pos, reading) == "VALIDATED"
            and family(cs_rec.storyline_id) == "BOUND" and cs10[1] == "T7" and cs10[2].root_phase == "INSIDE"
            and all(r_ == EMPTY and p_ == "PRE_C8" and phase_of(r_, True, frozenset(), p_, reading) == "LEANING"
                    for r_, p_ in early),
            f"{short(cs_rec)} at {cs_pos}: load_check {sorted(load_check(cs_rec, frozenset(), cs_pos, reading))}, "
            f"gate {cs10[0]} ({cs10[1]})")
        paths = ("Chapter 9 end", "Chapter 10 scene chain", "world-map Resume story", "free travel", "chapter select")
        inj = {"LEANING": EMPTY, "PARTLY_LOCKED": fx["PARTLY_LOCKED"][0]}
        # Injected at CH9 (every path's request is issued past C8-S16), the LEANING-shaped and PARTLY_LOCKED-shaped
        # records read DAMAGED by D16, so the turn-back comes from the gate's DAMAGED row, not T6 (finding F13).
        lac19 = [(p, ph, gate(r_, frozenset(), "CH9", "ROOT", p, frozenset(), reading)[0])
                 for p in paths for ph, r_ in inj.items()]
        lac19_bad = [(p, ph, g[0]) for p, ph, g in lac19 if ":TURNED_BACK" not in g[0] or g[3] != "CH9"]
        rows = sorted({g[1] for _, _, g in lac19})
        chk("L-AC19 gate predicate: an injected live LEANING- or PARTLY_LOCKED-shaped record is TURNED_BACK and stays "
            "outside Root of Heaven from each of the five paths (one predicate, so the free-travel region stays locked "
            f"with no ID stored); gate rows used: {', '.join(rows)}", not lac19_bad, str(lac19_bad))
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
    # rev 11 (OQ18, lifecycle rev 7): a live invalid-row record with nothing stored, injected in Chapter 9
    cres = gate(cr, frozenset(), "CH9", "ROOT", "story", frozenset(), reading)[0]
    lc_cr = load_check(cr, frozenset(), "CH9", reading)
    chk("L-AC8 live crisis injected past C8-S16: DAMAGED with load_check {D9}, TURNED_BACK, record unchanged, not a "
        "gate error", cres[1] == "GATE_DAMAGED" and cres[2] == cr and lc_cr == {"D9"},
        f"{cres[0]} ({cres[1]}), load_check {sorted(lc_cr)}")
    # Rev 13 (design review round 13). P10: a purge is power used on another without answering for it, so with the
    # first edit it makes a YOU vote negotiated and sole_dissent plays; HEARTH no longer has it as a + seed.
    p10p = [({"ch1_root_first_edit", "ch1_root_purge"}, "authority", "YOU", "NEGOTIATED"),
            ({"ch1_root_purge"}, "faction", "HEARTH", "NEGOTIATED"),
            ({"act1_report_local", "ch1_root_purge"}, "faction", "HEARTH", "CLEAN")]
    p10p_bad = [(sorted(fl), ax, v, lock_pass(fl, ax, v, reading.seeds)) for fl, ax, v, exp in p10p
                if lock_pass(fl, ax, v, reading.seeds) != exp]
    chk("P10 purge (rev 13): a purge with the first edit makes a YOU vote negotiated; it no longer argues for HEARTH",
        not p10p_bad, str(p10p_bad))
    # Chapter select keyed to the entry scene's position: every entry's first save passes the load check.
    cs_bad = []
    for label, chapter, entry_pos in CHAPTER_SELECT_ENTRIES:
        got = chapter_select_entry(chapter, entry_pos, reading)
        if got is None:
            cs_bad.append((label, "not offered"))
            continue
        r_, p_ = got
        lc = load_check(r_, frozenset(), p_, reading)
        if lc:
            cs_bad.append((label, p_, sorted(lc)))
        elif entry_pos == "ROOT" and gate(r_, frozenset(), p_, "ROOT", "chapter select", frozenset(),
                                          reading)[0][1] != "T7":
            cs_bad.append((label, "gate does not run T7"))
    chk("Chapter select by entry position (lifecycle rev 9): every entry's first save passes load_check; "
        "'Chapter 8 - Ending' writes the fixed record at S16_DONE; Chapter 10 passes the gate by T7",
        not cs_bad, str(cs_bad))
    # NG+ reset: from a FINAL record at every position after the final authorization, the new record loads LEANING.
    ng_bad = []
    for p_ in ("FINAL_DONE", "STORY_PLUS", "ROOT_STORY_PLUS"):
        r_, np_ = ng_plus(fx["FINAL"][0], p_, reading)
        lc = load_check(r_, frozenset(), np_, reading)
        ph = phase_of(r_, True, frozenset(), np_, reading)
        if lc or ph != "LEANING" or np_ != "PRE_C8":
            ng_bad.append((p_, np_, sorted(lc), ph))
    chk("NG+ reset (lifecycle L-AC15): a new cycle started from FINAL_DONE, STORY_PLUS or ROOT_STORY_PLUS is at "
        "PRE_C8, LEANING, load_check empty", not ng_bad, str(ng_bad))
    # Legacy position: derived once from the save's scene; past a lock D16, unmapped D0, before Chapter 8 LEANING.
    leg = {sc: legacy_load(sc, reading) for sc in LEGACY_SCENES}
    leg_ok = (leg["a hub before Chapter 8"][:2] == (set(), "LEANING")
              and leg["a Chapter 9 scene"][0] == {"D16"} and leg["a Root of Heaven scene"][0] == {"D16"}
              and leg["a scene the map lacks"][0] == {"D0"})
    chk("Legacy position (Terms, Edge Case 8): a pre-lifecycle save's position is derived from its scene: before "
        "Chapter 8 LEANING, Chapter 9 or Root of Heaven exactly {D16}, a scene the map lacks exactly {D0}",
        leg_ok, str({k: (sorted(v[0]), v[1], v[2]) for k, v in leg.items()}))
    # D0 owns the beats_played cap of one; it type-checks beats_played only, so an undefined id is D14's.
    two_beats = _REVD._replace(beats_played=_REVD.beats_played | {"retract_R1_authority_SHARED"})
    d0d1 = _PLAIN._replace(root_phase="SIDEWAYS", storyline_id="SL-BOGUS")
    d0b = {"two beats": sorted(load_check_tags(two_beats, frozenset(), "S16_DONE", True, reading)),
           "D0 with D1": sorted(load_check_tags(d0d1, frozenset(), "S16_DONE", True, reading)),
           "one undefined beat": sorted(load_check_tags(_PLAIN._replace(beats_played=frozenset({"retract_R9_x_Y"})),
                                                        frozenset(), "S16_DONE", True, reading))}
    chk("AC9 D0 (rev 13): a two-element beats_played and a D0 defect with a D1 defect each give exactly {D0}; one "
        "undefined retract_* id gives D14, not D0",
        d0b["two beats"] == ["D0"] and d0b["D0 with D1"] == ["D0"] and d0b["one undefined beat"] == ["D14.undefined"],
        str(d0b))
    # Rev 14 (design review round 14). Blocker 3: a new-game save (every field at its default, act1_pace UNSET, at
    # PRE_C8) loads LEANING.
    ng = stored_save_check(EMPTY._asdict(), NEW_GAME_EXTRA, frozenset(), reading)
    ng_ph = phase_of(EMPTY, True, frozenset(), "PRE_C8", reading) if not ng else "DAMAGED"
    chk("New game (rev 14): the first save of a new game, act1_pace UNSET at PRE_C8, gives load_check empty and loads "
        "LEANING", not ng and ng_ph == "LEANING", f"{sorted(ng)} {ng_ph}")
    # Blocker 2: story_position is a record field, so D0 covers a missing or unlisted position.
    pf = {"missing": stored_save_check(_REVD_RAW, {k: v for k, v in NEW_GAME_EXTRA.items() if k != "story_position"},
                                     frozenset(), reading),
          "unlisted": stored_save_check(_REVD_RAW, dict(NEW_GAME_EXTRA, act1_pace="act1_pace_late", story_position="S99"),
                                        frozenset(), reading),
          "listed": stored_save_check(_REVD_RAW, dict(NEW_GAME_EXTRA, act1_pace="act1_pace_late", story_position="S16_DONE"),
                                      frozenset(), reading)}
    chk("Position field (rev 14): a current-schema save with no story_position gives exactly {D0.missing}, an unlisted "
        "one exactly {D0.enum}, a listed one passes",
        pf["missing"] == {"D0.missing"} and pf["unlisted"] == {"D0.enum"} and pf["listed"] == set(),
        str({k: sorted(v) for k, v in pf.items()}))
    # Blocker 2: legacy derivation order; no hub in the scene-to-id map; a Chapter 8 save no story scene places is D0.
    lh = {name: legacy_save_check(*args, reading) for name, (args, _) in LEGACY_SAVES.items()}
    lh_bad = {name: (sorted(lh[name][0]), lh[name][1]) for name, (_, want) in LEGACY_SAVES.items()
              if (lh[name][0], lh[name][1]) != want}
    chk("Legacy hub (rev 14): a pre-lifecycle save's position comes from its free-travel story scene, else its own "
        "scene (no hub in the map), else its chapter; a Chapter 8 hub save is exactly {D0.missing}", not lh_bad,
        str(lh_bad))
    # Blocker 5: one fixture per D0 clause id, each giving exactly that clause (D0.duplicate is the decoder's, M12).
    d0_fx = {
        "D0.missing": stored_save_check({k: v for k, v in _REVD_RAW.items() if k != "lock_negotiated"},
                                        dict(NEW_GAME_EXTRA, story_position="S16_DONE"), frozenset(), reading),
        "D0.type": stored_save_check(dict(_REVD_RAW, storyline_id=5),
                                     dict(NEW_GAME_EXTRA, story_position="S16_DONE"), frozenset(), reading),
        "D0.enum": stored_save_check(dict(_REVD_RAW, root_phase="SIDEWAYS"),
                                     dict(NEW_GAME_EXTRA, story_position="S16_DONE"), frozenset(), reading),
        "D0.element": stored_save_check(dict(_REVD_RAW, beats_played=frozenset({7})),
                                        dict(NEW_GAME_EXTRA, story_position="S16_DONE"), frozenset(), reading),
        "D0.max": stored_save_check(TWO_ENTRY_RECORD._asdict(),
                                    dict(NEW_GAME_EXTRA, story_position="S16_DONE"), frozenset(), reading),
    }
    entry_enum = stored_save_check(dict(_REVD_RAW, retraction_log=(_REVD.retraction_log[0]._replace(old="PURPLE"),)),
                                   dict(NEW_GAME_EXTRA, story_position="S16_DONE"), frozenset(), reading)
    agree = all(bool(d0_clauses(r_)) == shape_wrong(r_, 1) for r_ in (
        _REVD, _REVD._replace(storyline_id=5), _REVD._replace(root_phase="SIDEWAYS"),
        _REVD._replace(beats_played=frozenset({7})), TWO_ENTRY_RECORD))
    d0_ids_ok = (reading.rev14 and all(v == {k} for k, v in d0_fx.items()) and entry_enum == {"D0.enum"} and agree
                 and set(d0_fx) | set(D0_DECODER_ONLY) == set(D0_CLAUSE_IDS))
    chk("AC9 D0 clause ids (rev 14): one fixture per D0 clause gives exactly that clause (a retraction entry's old "
        "outside its axis is D0.enum; D0.duplicate is the decoder's, M12); d0_clauses agrees with shape_wrong",
        d0_ids_ok, str({k: sorted(v) for k, v in d0_fx.items()}) + f" entry old {sorted(entry_enum)} agree {agree}")
    # Blocker 5: the D7 new-value fixture. The rev 13 construction on Faction also fires D14.undefined (qa-lead).
    d7 = EMPTY._replace(authority="SHARED", faction="ARCHIVE", deleted="RELEASE",
                        storyline_id="SL-SHARED-ARCHIVE-RELEASE", axis_revised=frozenset({"authority"}),
                        lock_negotiated=frozenset(LOCK_ORDER),
                        retraction_log=(Entry("authority", "NONE", "YOU", WITHDRAWN["authority"]["NONE"], "C8-S16"),),
                        beats_played=frozenset({"retract_R2_authority_YOU"}))
    d7_tags = load_check_tags(d7, frozenset(), "S16_DONE", True, reading)
    old_way = TWO_ENTRY_RECORD._replace(retraction_log=TWO_ENTRY_RECORD.retraction_log[:1],
                                        beats_played=frozenset({"retract_R2_faction_HEARTH"}))
    e0 = old_way.retraction_log[0]
    old_way = old_way._replace(retraction_log=(e0._replace(new="CONTINUITY"),),
                               beats_played=frozenset({"retract_R2_faction_CONTINUITY"}))
    old_tags = load_check_tags(old_way, frozenset(), "S16_DONE", True, reading)
    chk("AC9 D7 new-value fixture (rev 14): (SHARED, ARCHIVE, RELEASE) with {authority, NONE -> YOU} and "
        "retract_R2_authority_YOU gives exactly {D7.new_mismatch}; the rev 13 Faction construction gives two clauses",
        d7_tags == {"D7.new_mismatch"} and old_tags == {"D7.new_mismatch", "D14.undefined"},
        f"new {sorted(d7_tags)}, old {sorted(old_tags)}")
    # Open Question 20 (every closed-list field): companions_present and timing_flags are checked against their lists.
    cl = {"all three companions and a timing flag": stored_save_check(
              _REVD_RAW, dict(NEW_GAME_EXTRA, story_position="S16_DONE", companions_present=COMPANIONS_1_0,
                              timing_flags=frozenset({"ch1_bridge_fell"})), frozenset(), reading),
          "Kaelthas present": stored_save_check(
              _REVD_RAW, dict(NEW_GAME_EXTRA, story_position="S16_DONE",
                              companions_present=frozenset({"Elara", "Kaelthas"})), frozenset(), reading),
          "an unknown timing flag": stored_save_check(
              _REVD_RAW, dict(NEW_GAME_EXTRA, story_position="S16_DONE",
                              timing_flags=frozenset({"ch1_bridge_bogus"})), frozenset(), reading),
          "companions as a list": stored_save_check(
              _REVD_RAW, dict(NEW_GAME_EXTRA, story_position="S16_DONE", companions_present=["Elara"]),
              frozenset(), reading),
          "no timing_flags field": stored_save_check(
              _REVD_RAW, {k: v for k, v in dict(NEW_GAME_EXTRA, story_position="S16_DONE").items()
                          if k != "timing_flags"}, frozenset(), reading)}
    want_cl = ({"all three companions and a timing flag": set(), "Kaelthas present": {"D0.enum"},
                "an unknown timing flag": {"D0.enum"}, "companions as a list": {"D0.type"},
                "no timing_flags field": {"D0.missing"}} if reading.rev14 else
               {"all three companions and a timing flag": set(), "Kaelthas present": {"D0"},
                "an unknown timing flag": {"D0"}, "companions as a list": {"D0"}, "no timing_flags field": {"D0"}})
    chk("Closed-list fields (rev 14): companions_present holds only Elara, Seraphina and Lyra, timing_flags only the six "
        "timing flags; a wrong value, type or a missing field is D0",
        cl == want_cl, str({k: sorted(v) for k, v in cl.items()}))
    return res


# ---------------------------------------------------------------------------------------------------------------
# Clause isolation and the accepted-but-unreachable probe
# ---------------------------------------------------------------------------------------------------------------
ALL_CLAUSES = REV13.clauses()
# rev 12: AC9 lists D17.prefix as documentation (an equivalent mutant): it never fires alone on a loaded record
# (exhaustive check below). D7.multi and D7.duplicate are retired: D0 refuses a second entry first.
DOCUMENTATION_ONLY = ("D17.prefix",)
_REVD = fit_commitment(EMPTY._replace(
    authority="YOU", faction="HEARTH", deleted="RELEASE", storyline_id="SL-YOU-HEARTH-RELEASE",
    axis_revised=frozenset({"deleted"}), lock_negotiated=frozenset(LOCK_ORDER),
    retraction_log=(Entry("deleted", "RESTORE", "RELEASE", WITHDRAWN["deleted"]["RESTORE"], "C8-S16"),),
    beats_played=frozenset({"retract_R1_deleted_RELEASE"})))
_PLAIN = _REVD._replace(axis_revised=frozenset(), retraction_log=(), beats_played=frozenset())
# rev 11 (round 11, qa-lead): hand-built fixtures for the clauses that single-field changes cannot isolate. The
# D7.duplicate fixture stays for the rev 11 regression: under that text D0 fires first, so it is never isolated.
HAND_FIXTURES = {
    "D7.unnamed": (_PLAIN._replace(axis_revised=frozenset({"deleted"})), "S16_DONE"),
    "D14.no_entry": (_PLAIN._replace(beats_played=frozenset({"retract_R1_deleted_RELEASE"})), "S16_DONE"),
    "D14.not_played": (_REVD._replace(beats_played=frozenset()), "S16_DONE"),
    "D14.undefined": (_PLAIN._replace(beats_played=frozenset({"sole_dissent"})), "S16_DONE"),
    "D7.duplicate": (_REVD._replace(retraction_log=_REVD.retraction_log * 2), "S16_DONE"),
}
# Rev 12, AC9's two-entry D0 fixture: (NONE, HEARTH, RELEASE) reached from R2 (ARCHIVE -> HEARTH) and from R3
# (CONTINUITY -> HEARTH); each entry alone is consistent, which the rev 11 reason for D7.multi denied.
TWO_ENTRY_RECORD = EMPTY._replace(
    authority="NONE", faction="HEARTH", deleted="RELEASE", storyline_id="SL-NONE-HEARTH-RELEASE",
    axis_revised=frozenset({"faction"}), lock_negotiated=frozenset(LOCK_ORDER),
    retraction_log=(Entry("faction", "ARCHIVE", "HEARTH", WITHDRAWN["faction"]["ARCHIVE"], "C8-S16"),
                    Entry("faction", "CONTINUITY", "HEARTH", WITHDRAWN["faction"]["CONTINUITY"], "C8-S16")),
    beats_played=frozenset({"retract_R2_faction_HEARTH", "retract_R3_faction_HEARTH"}))
_REVD_RAW = _REVD._asdict()
# Rev 12, AC9's D0 fixtures as stored saves: (raw lifecycle block, schema, position). The fifth, a set holding one
# element twice, cannot be built from a frozenset (M12); SaveService's decoder owns it.
D0_FIXTURES = {
    "missing field (current schema)": ({k: v for k, v in _REVD_RAW.items() if k != "lock_negotiated"},
                                       CURRENT_SCHEMA, "S16_DONE"),
    "wrong-typed field": (dict(_REVD_RAW, retraction_log=list(_REVD.retraction_log)), CURRENT_SCHEMA, "S16_DONE"),
    "out-of-range enum string": (dict(_REVD_RAW, root_phase="OUTSIDE_ISH"), CURRENT_SCHEMA, "S16_DONE"),
    "two-entry retraction_log": (TWO_ENTRY_RECORD._asdict(), CURRENT_SCHEMA, "S16_DONE"),
}


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
        yield "retraction entry duplicated", rec._replace(retraction_log=tuple(log + [e])), pos, flags
    if not rec.retraction_log and UNSET not in row_of(rec):
        for ax in LOCK_ORDER:
            for v in VALUES[ax]:
                if v != getattr(rec, ax):
                    yield "retraction entry added", rec._replace(retraction_log=(
                        Entry(ax, v, getattr(rec, ax), WITHDRAWN[ax][v], "C8-S16"),)), pos, flags
    for b in sorted(DEFINED_BEATS) + ["retract_R9_faction_NOWHERE", "sole_dissent"]:
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


# rev 11 (OQ17 tripwire): the categories of accepted records play does not write. A new one fails the run.
PINNED_RESIDUAL_KINDS = frozenset({"position", "seed flag toggle", "lock_negotiated toggle", "root_phase",
                                   "retraction withdrawn_item", "retraction scene", "axis faction", "axis authority"})


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
    for c, (r2, p2) in HAND_FIXTURES.items():   # rev 11: AC9 asks for exactly {that clause id}
        tags = load_check_tags(r2, frozenset(), p2, True, reading)
        if tags == {c}:
            alone.setdefault(c, f"hand-built: {short(r2)} at {p2}")
            exact.setdefault(c, f"hand-built: {short(r2)} at {p2} -> tags {sorted(tags)}")
    for name, (raw, schema, p2) in D0_FIXTURES.items():   # rev 12: the D0 fixtures, as stored saves
        if load_check_save(raw, schema, frozenset(), p2, reading) == {"D0"}:
            alone.setdefault("D0", f"hand-built D0 fixture: {name} at {p2}")
            exact.setdefault("D0", f"hand-built D0 fixture: {name} at {p2}")
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
    print("Storyline reference model (storyline-axes.md OQ16) — axes rev 15, lifecycle rev 11")
    print(f"Seed contexts: {len(contexts)} ({len(AXIS_SEEDS)} axis seeds; one Data Wraith flag at most), "
          f"{len(sigs)} distinct lock_pass signatures walked")
    print(f"Positions: {', '.join(POSITIONS)}; suppression windows: {', '.join(sorted(SPEC_WINDOWS))}")
    print()
    overall_ok = True

    print("== Unit tables (" + REV15.name + ") ==")
    units = unit_checks(REV15) + life11_checks(REV15, contexts)
    for cid, ok, detail in units:
        print(f"  [{'PASS' if ok else 'FAIL'}] {cid}" + (f"  — {detail}" if detail and not ok else ""))
        overall_ok &= ok
    print()

    print("== Walk, " + REV15.name + " (default knobs, no defects) ==")
    fails, stats, sig_fails, saves_by_sig, rep_by_sig = run_suite(contexts, REV15, collect=True)
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

    print("== Regression: the " + REV10.name + " (what design review round 11 found; must still fail) ==")
    r10bad = [u[0] for u in unit_checks(REV10) if not u[1]]
    for u in r10bad:
        print(f"      {u}")
    r10_ok = any(u.startswith("L-AC8 live crisis") for u in r10bad) and \
        any(u.startswith("AC9 bounded live crisis") for u in r10bad)
    print(f"  [{'CAUGHT' if r10_ok else 'MISSED'}] the model still finds F11 (L-AC8 live crisis, AC9 bounded live "
          "crisis) on the rev 10 text")
    overall_ok &= r10_ok
    print()

    print("== Regression: the " + REV11.name + " (what design review round 12 found; must still fail) ==")
    r11bad = [u[0] for u in unit_checks(REV11) if not u[1]]
    for u in r11bad:
        print(f"      {u}")
    r11_ok = (any(u.startswith("AC9 hand-built clause fixtures") for u in r11bad)
              and any(u.startswith("AC9 legacy") for u in r11bad) and any(u.startswith("P10") for u in r11bad))
    print(f"  [{'CAUGHT' if r11_ok else 'MISSED'}] the model still finds, on the rev 11 text: D7.duplicate has no "
          "fixture of its own (D0's one-entry cap fires first), a pre-lifecycle save at PRE_C8 is D0 instead of "
          "LEANING, and a justified Aldric kill passes a YOU vote clean (P10)")
    overall_ok &= r11_ok
    print()

    print("== Regression: the " + REV12.name + " (what design review round 13 found; must still fail) ==")
    r12bad = [u[0] for u in unit_checks(REV12) if not u[1]]
    for u in r12bad:
        print(f"      {u}")
    r12_ok = all(any(u.startswith(k) for u in r12bad)
                 for k in ("P10 purge", "Chapter select by entry position", "NG+ reset", "Legacy position",
                           "AC9 D0 (rev 13)"))
    print(f"  [{'CAUGHT' if r12_ok else 'MISSED'}] the model still finds, on the rev 12 text: a purge with the first "
          "edit passes YOU clean (P10), 'Chapter 8 - Ending' autosaves a D16-refused save, a new NG+ cycle is "
          "refused by D16, a legacy Chapter 9 save loads LEANING at PRE_C8, and a two-element beats_played is not D0")
    overall_ok &= r12_ok
    print()

    print("== Regression: the " + REV13.name + " (what design review round 14 found; must still fail) ==")
    r13bad = [u[0] for u in unit_checks(REV13) if not u[1]]
    for u in r13bad:
        print(f"      {u}")
    r13_ok = all(any(u.startswith(k) for u in r13bad)
                 for k in ("New game (rev 14)", "Position field (rev 14)", "Legacy hub (rev 14)",
                           "AC9 D0 clause ids (rev 14)"))
    print(f"  [{'CAUGHT' if r13_ok else 'MISSED'}] the model still finds, on the rev 13 text: a new-game save is D0 "
          "(act1_pace has no UNSET), a missing or unlisted story position is refused by no item, a Chapter 9 or "
          "Chapter 8 hub save loads LEANING at PRE_C8, and D0 names no clause ids")
    overall_ok &= r13_ok
    print()

    print("== Regression: the " + REV14.name + " (lifecycle rev 10; what the lifecycle review of 2026-11-18 "
          "found; must still fail) ==")
    r14bad = [u[0] for u in unit_checks(REV14) + life11_checks(REV14, contexts) if not u[1]]
    for u in r14bad:
        print(f"      {u}")
    r14_ok = all(any(u.startswith(k) for u in r14bad)
                 for k in ("Chapter select rows (rev 15)", "Root positions (rev 15)", "Windows (rev 15)",
                           "take() via the T5 handler (rev 15)", "NG+ full reset (rev 15)", "Commitment (rev 15)"))
    print(f"  [{'CAUGHT' if r14_ok else 'MISSED'}] the model still finds, on the rev 14 text: chapter-select rows "
          "unplaced or ending FIXED or in a superseded scene, no Root scene set or position writers, windows "
          "without an opening or resume point, take() blind to a handler that ignores the scene, an NG+ reset that "
          "keeps companions, regions, timing and paces, and no stored commitment")
    overall_ok &= r14_ok
    print()

    print("== Negative controls (each seeded defect must fail at least one assertion; " + REV15.name + ") ==")
    base_codes = {c for c, _ in fails}
    all_caught = True
    for name, desc in DEFECTS.items():
        dfails, *_ = run_suite(contexts, REV15, frozenset({name}))
        codes = sorted({c for c, _ in dfails} - base_codes, key=lambda c: int(c[1:]))
        caught = bool(codes)
        all_caught &= caught
        print(f"  [{'CAUGHT' if caught else 'MISSED'}] {name}: {desc} -> {', '.join(codes) or 'no new failure'}")
    overall_ok &= all_caught
    print()

    print("== Clause isolation (AC9 rev 15: one fixture per clause with load_check exactly {that clause id}; the D0 "
          "clause ids are the unit table 'AC9 D0 clause ids') ==")
    exact, alone, accepted, accepted_states = (probe(rep_by_sig, saves_by_sig, REV15) if not args.quick
                                               else ({}, {}, {}, {}))
    redund = []
    if args.quick:
        print("  skipped (--quick)")
    else:
        for c in ALL_CLAUSES:
            st = ("alone" if c in alone else "documentation only" if c in DOCUMENTATION_ONLY
                  else "item-exact only" if c in exact else "NOT ISOLATABLE")
            print(f"  [{st}] {c}" + (f"  — {alone[c]}" if c in alone else f"  — {exact[c]}" if c in exact else ""))
        missing = [c for c in ALL_CLAUSES if c not in alone and c not in DOCUMENTATION_ONLY]
        overall_ok &= not missing
        doc_alone = [c for c in DOCUMENTATION_ONLY if c in alone]
        print(f"  mutation kill: each clause above marked 'alone' has a fixture whose only clause it is, so a "
              f"load_check with that clause deleted fails that fixture; documentation clauses found alone: "
              f"{doc_alone or 'none'}")
        overall_ok &= not doc_alone
        redund = d17_prefix_redundancy()
        print(f"  D17.prefix without D16 or D17.before_commit, exhaustive over 64 axis triples x "
              f"{len(POSITIONS)} positions: {len(redund)} case(s)")
        overall_ok &= not redund
    print()

    print("== Residual: records load_check accepts that no play in that seed context writes (single-field changes "
          "of reachable saves; non-goals by the inclusion rule, Open Question 17: counts reported, categories "
          "asserted) ==")
    stranded = {}
    n_live = 0
    if not args.quick:
        for k, (n, ex, pairs) in sorted(accepted.items(), key=lambda kv: -kv[1][0]):
            print(f"  {n:7d}  {k}  e.g. {ex}")
            if pairs:
                top = sorted(pairs.items(), key=lambda kv: (-kv[1], kv[0]))
                print(f"           {len(top)} from->to pairs: " + ", ".join(p for p, _ in top))
        n_live, stranded = liveness_of_accepted(accepted_states, REV15)
        cats = set(accepted)
        cats_ok = cats == PINNED_RESIDUAL_KINDS
        print(f"  [{'PASS' if cats_ok else 'FAIL'}] residual categories equal the pinned list"
              + ("" if cats_ok else f": new {sorted(cats - PINNED_RESIDUAL_KINDS)}, gone "
                                    f"{sorted(PINNED_RESIDUAL_KINDS - cats)}"))
        overall_ok &= cats_ok
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

    print("== ROUND-10 TO ROUND-14 AND LIFECYCLE 2026-11-18 FINDINGS: status under the rev 15 text ==")
    ac9_crisis = next((u[1] for u in units if u[0].startswith("AC9 fixture CRISIS")), False)
    lac8 = next((u[1] for u in units if u[0].startswith("L-AC8")), False)
    formula_crisis = next((u[1] for u in units if "loaded=False at S16_OPEN -> CRISIS" in u[0]), False)
    st = []
    st.append(("F1", "resolved" if "A8" in {c for c, _ in lfails} and not fails and formula_crisis else "OPEN",
               "D17's before-commit clause is skipped for the live crisis only (rev 11); the live crisis is CRISIS"))
    st.append(("F2", "resolved" if ac9_crisis else "OPEN", "AC9's CRISIS fixture reports {D9, D17}"))
    st.append(("F3", "documented" if not args.quick and not redund else "UNVERIFIED",
               "D17's prefix clause never fires alone; kept as documentation, no fixture"))
    st.append(("F4", "resolved" if "D7.new_mismatch" in exact else "OPEN" if not args.quick else "UNVERIFIED",
               "strict 'matching' plus the coordinated two-field fixture isolates D7's new-value clause"))
    st.append(("F5", "non-goal (OQ17, settled)",
               "; ".join(f"{k} {acc(k)}" for k in ("retraction withdrawn_item", "retraction scene",
                                                   "lock_negotiated toggle", "seed flag toggle", "axis faction",
                                                   "axis authority") if acc(k)) or "none accepted"))
    st.append(("F6", "resolved" if "D7.reverse" in exact and not acc("axis_revised toggle")
               else "OPEN" if not args.quick else "UNVERIFIED",
               f"D7 runs both ways; accepted axis_revised toggles: {acc('axis_revised toggle')}"))
    st.append(("F7", "non-goal (OQ17, settled)",
               f"{acc('position')} position and {acc('root_phase')} root_phase changes accepted; none is promised"))
    st.append(("F8", "resolved" if lac8 else "OPEN", "L-AC8 has a VALIDATED-on-load cell (T7)"))
    st.append(("F9", "resolved" if lac8 else "OPEN",
               "T6 kept as defence in depth, a DAMAGED gate row, injected live cells in L-AC8"))
    st.append(("F10", "waits on lifecycle OQ2 (candidate D18)",
               f"{sum(len(v) for v in stranded.values())} accepted records cannot reach FINAL (rests on M8)"))
    # F11 (round 10, settled in round 11 as OQ18): a live crisis record past C8-S16 reads DAMAGED and is turned back.
    crisis_gate = gate(EMPTY._replace(authority="NONE", faction="ARCHIVE", deleted="RELEASE"), frozenset(), "CH9",
                       "ROOT", "story", frozenset(), REV15)[0][0]
    st.append(("F11", "resolved (OQ18)" if crisis_gate.endswith(":TURNED_BACK:DAMAGED") else "OPEN",
               f"a live crisis record past C8-S16 at the story gate: {crisis_gate}"))
    # Round 12: D0 owns the one-entry cap (D7.duplicate and D7.multi retired); the duplicated entry is refused as D0.
    two_entry = next((u[1] for u in units if u[0].startswith("AC9 D0 two-entry")), False)
    st.append(("R12-D0", "resolved" if two_entry and ("D0" in alone or args.quick)
               and not acc("retraction entry duplicated") else "OPEN",
               "D0 refuses a second retraction entry (the R2/R3 two-entry fixture gives {D0}); accepted duplicates: "
               f"{acc('retraction entry duplicated')}"))
    st.append(("R12-legacy", "resolved" if next((u[1] for u in units if u[0].startswith("AC9 legacy")), False)
               else "OPEN", "an older save is defaulted before the check: LEANING at PRE_C8, {D16} at CH9"))
    st.append(("R12-D14", "resolved" if next((u[1] for u in units if u[0].startswith("D14 refuses any")), False)
               and ("D14.undefined" in alone or args.quick) else "OPEN",
               "D14 refuses any beat id the lifecycle does not define (the model checked retract_* ids only before)"))
    st.append(("R12-P10", "resolved" if next((u[1] for u in units if u[0].startswith("P10")), False) else "OPEN",
               f"sole_dissent reachable {sorted(stats['sole_dissent'])}; a justified kill makes a YOU vote negotiated"))
    st.append(("R12-chapter-select", "resolved" if next((u[1] for u in units if u[0].startswith("Chapter select")),
                                                        False) and not fails else "OPEN",
               "chapter select of Chapter 9/10 writes a record the load check accepts; the walk from it holds A1-A14"))
    st.append(("F12", "resolved" if next((u[1] for u in units if u[0].startswith("Chapter select by entry")),
                                          False) else "OPEN",
               "chapter select is keyed to the entry scene's position (lifecycle rev 9): 'Chapter 8 - Ending' writes "
               "the fixed record at S16_DONE, which the walk starts from"))
    for fid, prefix, note in (
            ("R13-P10-purge", "P10 purge", "a purge with the first edit makes a YOU vote negotiated (sole_dissent)"),
            ("R13-NG+", "NG+ reset", "the NG+ reset sets PRE_C8, so a new cycle loads LEANING"),
            ("R13-legacy-position", "Legacy position", "a legacy save's position is derived once from its scene"),
            ("R13-D0-D14", "AC9 D0 (rev 13)", "beats_played capped at one; D0 type-checks it, D14 owns its ids"),
            ("R14-new-game", "New game (rev 14)", "act1_pace defaults to UNSET, so a new-game save loads LEANING"),
            ("R14-position-field", "Position field (rev 14)", "story_position is a record field; D0 covers it"),
            ("R14-legacy-hub", "Legacy hub (rev 14)", "a legacy hub save is placed by its free-travel story scene "
             "or chapter; a Chapter 8 one is D0.missing"),
            ("R14-D0-ids", "AC9 D0 clause ids (rev 14)", "D0 names its clause ids, one fixture each"),
            ("R14-D7-fixture", "AC9 D7 new-value fixture (rev 14)", "the D7 fixture isolates D7.new_mismatch"),
            ("L11-1 chapter select", "Chapter select rows (rev 15)", "13 rows placed; True Ending FINAL; Final "
             "Confrontation reaches T9; no superseded scene"),
            ("L11-2 Root positions", "Root positions (rev 15)", "Root scene set, load-gate positions, a writer for "
             "every position, hub revival"),
            ("L11-4 windows", "Windows (rev 15)", "a window, commit and resume point for T1, T2, T3, T5, T7, T9"),
            ("L11-5 take()", "take() via the T5 handler (rev 15)", "take() calls the T5 handler in every scene"),
            ("L11-8 commitment", "Commitment (rev 15)", "kaelen_commitment stored, D0 on the inconsistent records"),
            ("L11-11 NG+", "NG+ full reset (rev 15)", "every stored field reset to a new game's")):
        st.append((fid, "resolved" if next((u[1] for u in units if u[0].startswith(prefix)), False) else "OPEN",
                   note))
    st.append(("F13", "reported (lifecycle L-AC19)",
               "a LEANING- or PARTLY_LOCKED-shaped record injected at a past-C8-S16 request reads DAMAGED (D16), so "
               "L-AC19's TURNED_BACK comes from the DAMAGED row, not T6; the assertion holds"))
    for fid, status, note in st:
        print(f"  {fid}: {status} — {note}")
        if status == "OPEN":
            overall_ok = False
    print()

    print("== Modelling choices (where the GDDs leave the model a reading) ==")
    for m in (
        f"M1 Seed contexts hold the {len(AXIS_SEEDS)} axis-seed rows' flags only (rev 12): modifier and timing rows "
        "are not read by lock_pass (it matches a row by (flag, pushes)) or load_check (except D15, which play cannot "
        "reach because set_story_flag clears the group). The three Aldric-kill flags and the three Seraphina "
        "command-hall flags are branches of one choice each but no exclusive group, so the contexts are a superset "
        "of what play sets. Seeds are fixed before C8-S13 (Act 1); side-arc flags join after Y2-PP-T17 maps them "
        "(AC15) and are not modelled. Walks use the rev 12 seed map for every reading; the earlier texts' seed maps "
        "are read only by the unit tables.",
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
        "M11 'Inside C8-S16 before its commit' is the position S16_OPEN (rev 11, live_crisis).",
        "M12 D0 (rev 12) is modelled as far as a typed record can express it: an axis, root_phase or retraction "
        "enum outside its values, an element of the wrong type, retraction_log over one entry, beats_played over "
        "sixteen (rev 12) or one (rev 13); a missing field through decode() of a current-schema save. 'A set holding one element twice' is "
        "NOT modelled: a frozenset cannot hold one, so that D0 fixture belongs to SaveService's decoder tests. "
        "D0 checks only that beats_played elements are strings; which beat ids exist is D14's (Edge Case 16).",
        "M13 A save of the schema version before the lifecycle fields has no lifecycle block; decode() fills it "
        "with EMPTY before load_check (Edge Case 8); rev 13 derives its position from its scene (LEGACY_SCENES stands "
        "in for the scene-to-id map). Chapter select writes its record at CH9 as the walk's second start, and rev 13 "
        "adds 'Chapter 8 - Ending' at S16_DONE as a third (CHAPTER_SELECT_ENTRIES stands in for main_menu.gd).",
        "M15 NG+ is a unit check, not a walk edge: an NG+ edge would start a new record and so trip A6 (a stored ID "
        "never changes), which holds within one cycle. The unit starts a new cycle from every position after the "
        "final authorization.",
        "M14 Kaelthas is outside the 1.0 companion set (Core Rule 11); the model never modelled companions, and "
        "the ch3_kaelthas_* exclusive group stays because it is game code that D15 reads.",
        "M16 Rev 14 covers the whole stored record at the save level (stored_save_check): the lifecycle block plus "
        "act1_pace, story_position, companions_present (the three 1.0 companions) and timing_flags (the six timing "
        "flags), each against its allowed values. The walk's Record stays the lifecycle block with the position "
        "beside it. regions_completed is not modelled (the GDD gives 'ids of the eight regions', no enumerated list) "
        "and the act2-4 paces wait for S06b's names; derived fields (storyline_phase, secret_route, family) are never "
        "stored. SCENE_TO_ID and HUB_SCENES stand in for Y1-P1-T03's scene-to-id map "
        "(story scenes only) and the game's hubs. load_check_tags keeps reporting D0 as one item for every text; "
        "d0_clauses gives rev 14's clause ids.",
        "M17 Rev 15 (lifecycle rev 11): kaelen_commitment is a Record field with default UNSET (older readings never "
        "write it and do not check it). The main walk chooses LISTEN whenever YOU is backed; the unit 'Commitment' "
        "walks one seed context per choice. The accepted-record probe does not toggle the commitment (its D0 rule "
        "refuses every inconsistent value; a change between two of the three choices on a YOU record is accepted "
        "and is a non-goal like the other display-level fields). Chapter-select rows, the scene placement, the "
        "position writers and the window table are stand-ins for the lifecycle tables (the checker compares the "
        "tables with main_menu.gd and the scene files); a hub revival is a walk edge from ROOT and ROOT_STORY_PLUS. "
        "take() and the T5 handler are modelled for the 16 offers over one walk; the negative control "
        "handler_ignores_scene is checked inside that unit, not in the A1-A14 walk.",
    ):
        print("  " + m)
    print()
    print(f"RESULT: {'PASS' if overall_ok else 'FAIL'} ({REV15.name}; the rev 14 text still fails as expected: "
          f"{'yes' if r14_ok else 'NO'}; the rev 13 text still fails as expected: "
          f"{'yes' if r13_ok else 'NO'}; the rev 12 text still fails as expected: "
          f"{'yes' if r12_ok else 'NO'}; the rev 11 text still fails as expected: "
          f"{'yes' if r11_ok else 'NO'}; the rev 10 text still fails as expected: {'yes' if r10_ok else 'NO'}; "
          f"the rev 9 text still fails as expected: {'yes' if regression_ok else 'NO'}; "
          f"residual counts reported, categories asserted); {time.time() - t0:.1f} s")
    return 0 if overall_ok else 1


if __name__ == "__main__":
    sys.exit(main())
