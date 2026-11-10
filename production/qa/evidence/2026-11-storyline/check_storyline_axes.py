"""Document checker for the storyline GDDs (story Y1-P0-S06a, AC-7): storyline-axes.md AC1-AC4 and the
document-level criteria of storyline-lifecycle.md (revision 6 / lifecycle revision 2, design review round 6 / 2;
revision 5 added three composer fields, the protected-touchpoints check and the beat-id derivations; revision 6 adds
the DAMAGED phase, Edge Case 16 items D1-D16, the witness seats and dissenters, the stand-down transition, and pins
for the claims qa-lead found unpinned in round 6: the threshold, the C9-S19 window, the L-AC bodies, the S5 and
Consent tables, the deferral disclosures, the save window and the legacy-flag citations).

Parses ``design/gdd/storyline-axes.md``, ``design/gdd/storyline-lifecycle.md``, the Story Bible and the production
master, and reports every structural problem it finds. Revision 4 pins *bodies*, not only names:

storyline-axes.md
1. the 8 required H2 headings in order (other H2s: Summary, Cross-References, Open Questions only);
2. the 27-row combination table, the rules table (each quoted contradiction on its cited line), the Formulas'
   ``invalid()`` set and shape, the ``valid_count:`` / family-split statements and the Counts block (values derived
   here, including ``renegotiation_offers`` computed from ``invalid()`` per rule);
3. the secret table, the ``secret_prerequisites`` / ``secret_unlock_flag`` knobs against the production master's
   "Required flag" lists, ``reachable_1_0``, ``transform()`` and both family maps;
4. the Act 1 seed map and the side-storyline table;
5. the composer record: exactly the AC3 fields, each with its pinned type, allowed values (derived where possible)
   and writer;
6. the formula bodies of ``storyline_id``, ``prereqs_met``, ``lock_pass``, ``storyline_phase`` and ``family``, the
   ``lock_pass`` and ``storyline_phase`` examples re-computed here, and the results each body can return;
7. Core Rules 1-12 with titles and pinned key sentences (some derived from the rules table), no modal verb in
   Rules 7 and 9, the invariants table I1-I8, the phase table, the Tuning Knobs table (exactly four knobs, defaults
   from the secret table's scopes, no forbidden knob), Edge Case numbering and Edge Case 16's damaged-record list;
8. the acceptance criteria: AC1-AC15 contiguous, each runtime AC names known blocking stories and calls only the
   Observables table; AC5's case counts derived;
storyline-lifecycle.md
9. headings; the Inputs field list and the NG+ reset (fields and defaults derived from the composer record);
10. the red-line table (exactly R1-R3, pairs and speakers derived from the rules table), the crisis offer table
    (= ``crisis_offers`` computed from ``invalid()``), the retraction table's axes and beat count;
11. the gate outcome table (outcomes derived from the axes phase table, T references matching the transitions);
12. transitions T1-T14 pinned cell by cell, phases only from the axes phase table, no transition back from a
    stored ID, every phase reachable, no soft-lock, the gate on every gated phase;
13. the Formulas block, its offer counts, the no-knob Tuning Knobs section, pinned scene sentences;
14. L-AC1..n contiguous, each with known blocking stories and only this doc's observables; derived numbers in
    L-AC3/4/6/16/19; the Validation note's run arithmetic and pass rule;
both
15. the dated decision line in the Story Bible; no stale strings or revision-3 vocabulary in normative sections;
16. (revision 6) the over-promise guard on clean/negotiated, the D-item cross-references between the two documents,
    the legacy storyline flags against the code lines the lifecycle cites, the L-AC key phrases and the forbidden
    non-failing assertions.

Usage (from anywhere; defaults point at the real files)::

    python -I -B check_storyline_axes.py [--gdd PATH] [--lifecycle PATH] [--bible PATH] [--root PATH]

Exit 0 and ``RESULT: PASS (0 problems)`` when clean; otherwise one line per problem, then
``RESULT: FAIL (n problems)`` and exit 1. Exit 2 if an input file cannot be read. Standard library only.
"""

from __future__ import annotations

import argparse
import itertools
import re
import sys
from pathlib import Path

# --- Fixed vocabularies (story AC-2) ------------------------------------------------------------------------------
AUTHORITY = ("YOU", "SHARED", "NONE")
FACTION = ("HEARTH", "ARCHIVE", "CONTINUITY")
DELETED = ("RESTORE", "RELEASE", "CHOOSE")
AXES = {"authority": AUTHORITY, "faction": FACTION, "deleted": DELETED}
UNSET = "UNSET"
FAMILY_BY_AUTHORITY = {"YOU": "SOLE", "SHARED": "BOUND", "NONE": "NONE_AUTH"}
# One-letter codes the production master uses in route headings and secret foundations (e.g. YHL, NAL).
ABBR = {"YOU": "Y", "SHARED": "S", "NONE": "N", "HEARTH": "H", "ARCHIVE": "A", "CONTINUITY": "C",
        "RESTORE": "R", "RELEASE": "L", "CHOOSE": "C"}
COMPANIONS = frozenset({"Elara", "Seraphina", "Lyra", "Kaelthas"})
# Companions each ending family requires. Story Bible §5: no family needs one.
FAMILY_NEEDS: dict[str, frozenset[str]] = {
    "SOLE": frozenset(), "BOUND": frozenset(), "NONE_AUTH": frozenset(), "CONSENT": frozenset(),
}
DASHES = ("—", "-", "–")
NUMBER_WORDS = {1: "one", 2: "two", 3: "three", 4: "four", 5: "five", 6: "six", 7: "seven", 8: "eight", 9: "nine",
                10: "ten"}

SECRET_ROUTES = ("WITNESS", "FIRSTWAKE", "CROWNLESS")
SECRET_EXPECTED = {  # id -> (required family or None, scope)
    "SL-SECRET-WITNESS": ("CONSENT", "1.0"),
    "SL-SECRET-FIRSTWAKE": (None, "post-1.0"),
    "SL-SECRET-CROWNLESS": (None, "post-1.0"),
}
# PRODUCTION_MASTER_2.1.md:8784, canonical association of secret route and the invalid row it transforms.
SECRET_FOUNDATION = {"WITNESS": "YHR", "CROWNLESS": "NAL", "FIRSTWAKE": "NCL"}

# Story S06a, Audit 4 (23 flags) plus the three Aldric-kill flags: 26 flags, each with its approved
# (pushes, direction). A change here is a design decision.
SEED_EXPECTED: dict[str, tuple[str, str]] = {
    "act1_report_local": ("faction:HEARTH", "+"),
    "act1_report_archive": ("faction:ARCHIVE", "+"),
    "act1_report_command": ("faction:CONTINUITY", "+"),
    "ch2_seraphina_truth": ("modifier:seraphina_relationship", "+"),
    "ch2_seraphina_cautious": ("modifier:seraphina_relationship", "0"),
    "ch2_seraphina_showoff": ("modifier:seraphina_relationship", "−"),
    "ch2_seraphina_recruited": ("modifier:companions_present", "+"),
    "ch2_seraphina_stayed": ("modifier:companions_present", "−"),
    "ch2_seraphina_rejected": ("modifier:companions_present", "−"),
    "ch2_data_wraith_restored": ("deleted:RESTORE", "+"),
    "ch2_data_wraith_destroyed": ("deleted:RELEASE", "+"),
    "ch2_data_wraith_absorbed": ("deleted:CHOOSE", "+"),
    "ch1_knight_killed": ("faction:HEARTH", "−"),
    "ch1_knight_spared": ("modifier:aldric_restrained", "+"),
    "ch1_root_purge": ("faction:HEARTH", "+"),
    "ch1_aldric_kill_owned": ("authority:YOU", "+"),
    "ch1_aldric_kill_justified": ("authority:YOU", "+"),
    "ch1_aldric_kill_unsure": ("authority:SHARED", "+"),
    "ch1_root_first_edit": ("authority:YOU", "+"),
    "ch1_root_discovered_unused": ("authority:NONE", "+"),
    "ch1_oakhaven_warned_villagers": ("modifier:A1-OAK-SAVED", "+"),
    "ch1_oakhaven_warned_leaders": ("modifier:A1-OAK-SAVED", "+"),
    "ch1_oakhaven_left_quietly": ("modifier:A1-OAK-QUIET", "+"),
    "act1_pace_early": ("timing", "0"),
    "act1_pace_on_time": ("timing", "0"),
    "act1_pace_late": ("timing", "0"),
}
SEED_FLAGS = frozenset(SEED_EXPECTED)
LEAN_DIRECTIONS = ("+", "−", "-")  # "−" is U+2212; ASCII hyphen accepted as the same sign.
NEUTRAL = "0"
DIRECTIONS = (*LEAN_DIRECTIONS, NEUTRAL)
OVERTURNABLE = ("no", "until:lock:faction", "until:lock:authority", "until:lock:deleted")

SIDE_ARCS = tuple(f"{n:02d}" for n in range(1, 13))
POST_1_0_ARCS = ("05", "08", "09")
SCOPES = ("1.0", "post-1.0")

# --- Revision 4 (design review round 4): the static core and its invariants. A change is a design decision. -----
PHASES = ("LEANING", "PARTLY_LOCKED", "CRISIS", "DEFERRED", "VALIDATED", "FIXED", "FINAL", "DAMAGED")
# Phases no gate runs from and no transition reaches: CRISIS exists only inside C8-S16, DAMAGED is never loaded.
UNGATED_PHASES = ("CRISIS", "DAMAGED")
PHASE_TABLE = {  # phase -> (meaning, gate), backticks removed
    "LEANING": ("every axis UNSET", "turns the player back"),
    "PARTLY_LOCKED": ("one or two axes locked", "turns the player back"),
    "CRISIS": ("three axes locked on an invalid row, nothing stored, not deferred: exists only inside C8-S16, "
               "never saved", "— (inside C8-S16)"),
    "DEFERRED": ("R1, witness_deferred, nothing stored", "plays the last-chance scene"),
    "VALIDATED": ("an ID stored, outside Root of Heaven", "open"),
    "FIXED": ("an ID stored, inside Root of Heaven", "open (re-entry)"),
    "FINAL": ("the final authorization concluded: execution confirmed, or Kaelen stood down after a FAILED witness "
              "vote", "open (Story+)"),
    "DAMAGED": ("the record holds an item of Edge Case 16: never saved by play; a load that yields it is refused",
                "— (never loaded)"),
}
# The gate outcome each axes-doc gate phrase means in the lifecycle doc's gate table.
GATE_OUTCOME = {"turns the player back": "TURNED_BACK", "plays the last-chance scene": "LAST_CHANCE"}
FAMILIES = frozenset({"SOLE", "BOUND", "NONE_AUTH", "CONSENT"})
ID_FAMILY_EXTRA = frozenset({"RESERVED", "NO_FAMILY"})
LOCK_SCENE = {"faction": "C8-S13", "authority": "C8-S14", "deleted": "C8-S16"}
ROOT_PHASES = ("OUTSIDE", "INSIDE", "FINAL")
WITNESS_MANDATES = ("UNDECIDED", "MET", "FAILED")  # first value is the default (NG+ reset, new game)
# The seven seats of PM:8697-8703, in source order (user decision D4: the player fills them in Secret Quest 09).
WITNESS_SEATS = ("active_region", "deleted", "nonhuman", "infrastructure", "archive", "local_community", "rotating")
WITNESS_THRESHOLD = 5  # user decision D4 (2026-11-10): fixed, data-defined, not a knob

# Composer record (GDD AC3): field -> (type, allowed, writer). ``allowed`` is a frozenset (compared as a set of
# comma-separated values) or a str (compared exactly). Derived values come from the vocabularies above.
COMPOSER: dict[str, tuple[str, frozenset[str] | str, str]] = {
    "storyline_phase": ("enum", frozenset(PHASES),
                        "derived: storyline_phase(record) (Formulas); never stored"),
    "storyline_id": ("string", "a storyline ID, or empty while nothing is stored",
                     "C8-S16 on a valid row; a renegotiation (C8-S16 or the gate); a confirmed invocation; nothing else"),
    "witness_deferred": ("bool", frozenset({"true", "false"}), "the C8-S16 deferral sets it; nothing clears it"),
    "root_phase": ("enum", frozenset(ROOT_PHASES),
                   "the gate check on entry with an ID stored (INSIDE); the final authorization concluding, by "
                   "confirmed execution or a stand-down (FINAL)"),
    **{axis: ("enum", frozenset({UNSET, *values}), f"{LOCK_SCENE[axis]} lock; a renegotiation. Never the final "
                                                    "authorization") for axis, values in AXES.items()},
    "secret_route": ("enum", frozenset({"NO_SECRET", *SECRET_ROUTES}),
                     "derived from storyline_id (SL-SECRET-T → T, else NO_SECRET); never stored"),
    "family": ("enum", FAMILIES | ID_FAMILY_EXTRA, "derived: family(storyline_id); never stored"),
    "secret_invoked": ("set", frozenset(SECRET_ROUTES), "a confirmed invocation"),
    "axis_revised": ("set", frozenset(AXES), "a renegotiation"),
    "lock_negotiated": ("set", frozenset(AXES), "the lock scenes by lock_pass; every renegotiation"),
    # Revision 5 (lifecycle review round 1): the retractions, beats and witness vote are saved, not derived.
    "retraction_log": ("list", "entries {axis, old, new, withdrawn_item, scene}, oldest first",
                       "every renegotiation; a confirmed invocation"),
    "beats_played": ("set", "the lifecycle's authored beat ids (retract_*, gate_retcon_*, deferral_*, invoke_witness)",
                     "the scene that plays the beat"),
    # Revision 6 (lifecycle round 2, user decisions D1/D4): the seats the player chose and who dissented are saved.
    "witness_seats": ("map", f"seat → identity for the seats {', '.join(WITNESS_SEATS)} (PM:8697-8703); never Kaelen",
                      "Secret Quest 09"),
    "witness_dissenters": ("set", "seats of witness_seats", "C10-S15"),
    "witness_mandate": ("enum", frozenset(WITNESS_MANDATES), "C10-S15"),
    "companions_present": ("set", COMPANIONS,
                           "AethelgardPrototype/scripts/game_manager.gd (has_elara, exclusive flag groups); "
                           "AethelgardPrototype/dialogue/ch2/fragment_two.dlg"),
    "regions_completed": ("set", "ids of the eight regions", "owner story Y2-PP-T17 (no writer in the code today)"),
    "timing_flags": ("set of flags", "ch1_bridge_saved / _evacuated / _fell, ch2_medicine_early / _on_time / _late",
                     "AethelgardPrototype/dialogue/ch1/north_field.dlg; AethelgardPrototype/dialogue/ch2/act1_end.dlg"),
    "act1_pace": ("enum", frozenset(f for f, (push, _) in SEED_EXPECTED.items() if push == "timing"),
                  "AethelgardPrototype/dialogue/ch2/act1_end.dlg"),
    "act2_pace, act3_pace, act4_pace": ("enum", "names left to S06b", "owner story Y1-P0-S06b"),
}

CORE_RULE_TITLES = (
    "Three axes, one value each.", "Seeds are arguments, never gates.", "Lock scenes resolve, clean or negotiated.",
    "Red lines (new content), as values.", "An invalid combination is a political crisis, resolved at C8-S16.",
    "Secret routes: signposts and invocation.", "A valid row is held to its word.",
    "Storyline ID and the ID-lock gate.", "Final authorization.", "Ending family",
    "Companions are independent of the axes.", "Timing is a modifier.")
# Key sentences per Core Rule (normalized: backticks and ** removed, whitespace collapsed). Rules 4 and 5 also get
# sentences derived from the rules table in check_core_rules.
CORE_RULE_KEYS: dict[int, tuple[str, ...]] = {
    1: ("each starts UNSET", "Once a storyline ID is stored, each axis holds exactly one value"),
    2: ("Every lock scene always offers all three values; no seed adds or removes an option.",
        "No seed sets a value; only a lock scene or a renegotiation does", "The sources define no axis score."),
    3: ("A lock vote always passes for the proposal the player backs",
        "clean when at least one seed for the backed value is set with direction + and none with direction −; "
        "otherwise negotiated, and lock_negotiated_<axis> is set",
        "The test reads only which flags are set: no count, no weight.", "it never changes a value or the ID.",
        "The composer input record is authoritative: these flags, axis_revised_<axis>, lock_negotiated_<axis> and "
        "WITNESS_SEATS are mirrors, written in the same step as the record field, never read in its place and "
        "cleared with it.",
        "on a SOLE storyline whose lock_negotiated holds authority, the ending plays sole_dissent",
        "Nothing else in 1.0 reads lock_negotiated (no scene variant, ally line or slide)"),
    4: ("states its red line as a value, never as a combination",
        "No other pair voices a red line, C8-S13 and C8-S14 voice none, and there is no system warning."),
    5: ("the scene does not end until the coalition holds", "Deferring stores no ID and sets witness_deferred"),
    6: ("For all three routes the last offer prerequisite is set in the Act 3 ledger at the end of Chapter 8 "
        "(PM:7586-7588), after C8-S16.", "never the combination it transforms", "it cannot be undone",
        "until they ship, their rows can only be renegotiated at C8-S16, offer no deferral, and show no signpost.",
        "plays only when the stored ID is SL-SECRET-T.",
        "an invocation there also sets T's unlock flag if the invocation scene did not",
        "WITNESS_SEATS mirrors the record (Core Rule 3): Secret Quest 09 sets it in the same step that saves the "
        "seventh seat of witness_seats, so the flag never stands without seven saved seats, and prereqs_met(WITNESS) "
        "also requires the seven seats"),
    7: ("nothing offers a renegotiation, a deferral or an invocation, and the ID never changes.",),
    8: ("Before that nothing is stored.", "A stored ID is never recomputed from flags or knobs",
        "Every entry and re-entry into Root of Heaven runs the gate check",
        "before the three locks it turns the player back in the fiction",
        "is unsupported and does not load (Edge Case 16, D{legacy}; user decision 2026-11-10); no runtime catch-up "
        "exists, so no loaded state is stranded.",
        "The refusal holds only while no player-facing build has such saves"),
    9: ("It changes no axis and no ID.", "this design offers none",
        "Kaelen stands down instead and nothing is executed (Core Rule 10)"),
    10: ("or CONSENT for Witness Protocol", "Kaelen executes and does not authorize",
         "the seven are seven other identities", "which plays only on SL-SECRET-WITNESS",
         "The vote can fall short of the threshold", "the stored ID and the family are unchanged",
         "the act is not executed, because Kaelen stands down at the final authorization",
         f"(fixed at {WITNESS_THRESHOLD},", "the ending plays consent_unauthorized"),
    11: ("a companion leaves through relationship flags (Edge Case 1), never through an axis.",
         "The axis can only waive a trust test, never remove a companion."),
    12: ("change scenes, NPC fates, market events and ending slides through the composer, not the storyline ID",),
}
NO_MODAL_RULES = (7, 9)  # these rules forbid; a "may/can/could" in them is an exception being smuggled in
MODAL_RE = re.compile(r"\b(may|can|could|might)\b", re.IGNORECASE)

INVARIANTS = {  # id -> (invariant, rules), backticks removed
    "I1": ("Axis values come only from lock scenes and renegotiations; never from seeds, flags, knobs or the final "
           "authorization", "2, 3, 5, 9"),
    "I2": ("No crisis outlasts C8-S16; only a deferral does, and only on R1 while Witness Protocol is enabled", "5"),
    "I3": ("The ID is stored the moment the coalition holds, is never recomputed, and never changes once stored",
           "7, 8"),
    "I4": ("Every entry and re-entry into Root of Heaven runs the gate check, on every path", "8"),
    "I5": ("No soft-lock under any knob value or patch: every state without a stored ID either is before the locks or "
           "offers a renegotiation that reaches a valid row", "5, 8"),
    "I6": ("Nothing important is lost silently: a closed route's signpost shows it closed; arcs "
           f"{', '.join(POST_1_0_ARCS)} get a visible epilogue line in 1.0", "6"),
    "I7": ("A valid row is held to its word", "7"),
    "I8": ("Family = the Authority value, or CONSENT on SL-SECRET-WITNESS, where Authority-reading scenes play their "
           "Consent variant", "10"),
}

# Formula bodies, normalized (whitespace collapsed per line; blank lines dropped).
STORYLINE_ID_BODY = (
    "storyline_id(A, F, D, I):",
    "if A, F or D is UNSET → PENDING",
    'if not invalid(A, F, D) → "SL-" + A + "-" + F + "-" + D (I is ignored)',
    "T = transform(A, F, D)",
    'if I and enabled(T) and prereqs_met(T) → "SL-SECRET-" + T',
    "otherwise → CRISIS (Core Rule 5)",
)
PREREQS_MET_LINE = "prereqs_met(T) = secret_prerequisites[T] has at least two flags and every one of them is set"
LOCK_PASS_BODY = (
    "lock_pass(X, v):",
    "if some seed row (X:v, +) is set and no seed row (X:v, −) is set → CLEAN",
    "otherwise → NEGOTIATED",
    "renegotiation vote → NEGOTIATED",
)
STORYLINE_PHASE_BODY = (  # revision 6: damaged-first; FINAL and FIXED need a stored ID; revision 7: the loaded argument
    "storyline_phase(record, loaded):",
    "if damaged(record, loaded) → DAMAGED",
    "if storyline_id is stored and root_phase is FINAL → FINAL",
    "if storyline_id is stored and root_phase is INSIDE → FIXED",
    "if storyline_id is stored → VALIDATED",
    "if A, F and D are all UNSET → LEANING",
    "if A, F or D is UNSET → PARTLY_LOCKED",
    "if witness_deferred → DEFERRED",
    "otherwise → CRISIS",
)
FAMILY_BODY = (
    "family(id):",
    "SL-SECRET-WITNESS → CONSENT",
    "SL-SECRET-CROWNLESS, SL-SECRET-FIRSTWAKE → RESERVED (unreachable while their routes are disabled)",
    '"SL-" + A + "-" + F + "-" + D, not invalid(A, F, D) → { YOU → SOLE, SHARED → BOUND, NONE → NONE_AUTH }[A]',
    "PENDING, CRISIS, an invalid-row id, anything else → NO_FAMILY (not a storyline ID)",
)
INVALID_PREFIX = "invalid(A, F, D) = (A, F, D) ∈ {"

KNOB_HEADER = ("Knob", "Default", "Safe range", "What it affects", "Rationale / source")
# Exactly these four knobs; the two enable rows' defaults are derived from the secret table's scopes.
KNOBS = ("secret_route_enabled.WITNESS", "secret_route_enabled.CROWNLESS, .FIRSTWAKE",
         "secret_prerequisites[route] (list of flags)", "secret_unlock_flag[route]")
FORBIDDEN_KNOBS = ("invalid_combinations", "reconsideration_triggers", "faction_negotiation_allowed",
                   "reconsider_targets")
NOT_KNOB_KEYS = ("the invalid set R1-R3", "the family mapping", "the lock_pass test",
                 "the rule that the final authorization changes nothing",
                 "the rule that every lock scene offers all three values")

# Revision 6: Edge Case 16 is a numbered list D1-D16 (normalized, backticks removed). The D-numbers are cited from
# Core Rule 8, Edge Cases 6 and 8, AC9 and the lifecycle, so a renumbering is caught by the derived checks below.
EC16_ITEMS = (
    "a stored ID that is not the one its axes and secret_invoked name (SL-A-F-D on a valid row, SL-SECRET-T on an "
    "invalid row whose route T is in secret_invoked)",
    "secret_invoked holding a route whose row is not the record's",
    "secret_invoked with no ID stored",
    "witness_deferred with an UNSET axis, or with nothing stored on a row other than R1",
    "witness_deferred on a stored valid row with axis_revised empty",
    "axis_revised holding an axis that lock_negotiated lacks",
    "axis_revised holding an axis that no retraction_log entry names",
    "root_phase INSIDE or FINAL with nothing stored",
    "three axes set with nothing stored and witness_deferred false (tested on load only)",
    "witness_mandate MET or FAILED, or witness_dissenters non-empty, while the stored ID is not SL-SECRET-WITNESS",
    "witness_mandate UNDECIDED on SL-SECRET-WITNESS with root_phase FINAL",
    "witness_mandate other than the value storyline-lifecycle.md's formula gives for witness_dissenters, or "
    "witness_dissenters non-empty while witness_mandate is UNDECIDED",
    "witness_seats seating Kaelen or one identity in two seats, a dissenter that is not one of its seats, or fewer "
    "than seven seats on SL-SECRET-WITNESS",
    "a deferral_* beat in beats_played while witness_deferred is false, or invoke_witness while secret_invoked lacks "
    "WITNESS",
    "two flags of one exclusive group (Edge Case 6)",
    "a story position past the lock scene of an UNSET axis (a save made past Chapter 8 before these fields existed; "
    "unsupported, user decision 2026-11-10)",
)
EC16_EXCLUSIVE = 15  # the D-number of the exclusive-group item (cited by Edge Case 6)
EC16_LEGACY = 16  # the D-number of the pre-axes save item (cited by Core Rule 8, Edge Case 8, the lifecycle)
EC16_CRISIS = 9  # the D-number of the saved-crisis item (cited by AC9)
EC16_KEYS = ("The check compares and never rewrites the stored ID, and reads no knob, so a patch never damages a save.",
             "SaveService's load check reports each item below as a data error on load and refuses the load",
             "witness_deferred on a stored valid row with axis_revised non-empty is the history of a deferral broken "
             "at the gate, not damage.",
             "D16 holds only while no player-facing build has such saves; if one ships before these fields do, the "
             "decision is reopened")
# Round 6 blocker 3: the clean/negotiated difference is promised only as far as sole_dissent delivers it.
NO_OVERPROMISE_KEYS = (
    "in 1.0 only a Sole ending makes that record audible (Core Rule 3)",
    "Whether a vote passed clean or by negotiation is recorded, but the lock scene plays the same either way.",
    "In 1.0 the player hears the difference in exactly one place",
    "no other 1.0 content reads it.",
)
OVERPROMISE_STRINGS = ("colours ally lines", "already with them or has to be negotiated", "otherwise it changes ally",
                       "costs a voice in the room", "elsewhere it colours")
AXES_EDGE_CASES = 16
LIFE_EDGE_CASES = 12
# AethelgardPrototype/AGENTS.md's protected list; the axes Dependencies must name each one (round 5).
PROTECTED_RE = re.compile(r"Do not modify (.+?) unless the prompt explicitly allows it")
H_PROTECTED = ("protected area", "what this design needs there", "where specified")

# Identifiers that would make the storyline ID depend on timing or companions (GDD AC4, Core Rule 12).
FORBIDDEN_ID_INPUTS = re.compile(r"pace|timing|companion|bridge|medicine|act[1-4]_|ch[0-9]+_|has_", re.IGNORECASE)
KNOWN_STORIES = frozenset({"Y2-PP-T17", "Y1-P1-T05", "Y1-P1-T03", "Y1-P0-S06b"})
STORY_RE = re.compile(r"Y\d-[A-Za-z0-9]+-[A-Za-z0-9]+")
FIRST_RUNTIME_AC = 5
AXES_AC_COUNT = 15
STORYLINE_ID_PARAMS = ("A", "F", "D", "I")

# --- storyline-lifecycle.md -----------------------------------------------------------------------------------
TRANSITIONS = {  # id -> (from, event, guard, to, effects), backticks removed
    "T1": ("LEANING", "C8-S13 resolves", "—", "PARTLY_LOCKED", "faction set; lock_negotiated per lock_pass"),
    "T2": ("PARTLY_LOCKED", "C8-S14 resolves", "faction set, authority UNSET", "PARTLY_LOCKED",
           "authority set; lock_negotiated per lock_pass"),
    "T3": ("PARTLY_LOCKED", "C8-S16 resolves", "faction and authority set; the row is valid", "VALIDATED",
           "deleted set; lock_negotiated per lock_pass; ID stored"),
    "T4": ("PARTLY_LOCKED", "C8-S16 resolves", "faction and authority set; the row is invalid", "CRISIS",
           "deleted set; lock_negotiated per lock_pass; the refusing faction breaks the coalition"),
    "T5": ("CRISIS", "a renegotiation is taken", "the offer is in the row's offer set", "VALIDATED",
           "the axis changed; axis_revised, lock_negotiated gain it; retraction recorded; retraction beat played; "
           "ID stored"),
    "T6": ("CRISIS", "the deferral is taken", "R1; WITNESS enabled; signpost OPEN; the four disclosures shown",
           "DEFERRED", "witness_deferred set"),
    # Lifecycle round 2: the gate invokes on prereqs_met and sets the unlock flag itself.
    "T7": ("DEFERRED", "the invocation is confirmed (C9-S19 or the gate)",
           "WITNESS enabled; prerequisites met, seven seats saved",
           "VALIDATED", "secret_invoked gains WITNESS; SL-SECRET-WITNESS stored; SEVEN_WITNESSES_AVAILABLE set if "
           "unset; narrowing retraction recorded; invoke_witness played"),
    "T8": ("DEFERRED", "a renegotiation is taken at the gate", "one of the six R1 offers", "VALIDATED",
           "as T5; gate retcon beat played"),
    "T9": ("DEFERRED", "Root of Heaven entry, any path", "—", "DEFERRED",
           "LAST_CHANCE scene; leaving returns the player outside"),
    "T10": ("LEANING or PARTLY_LOCKED", "Root of Heaven entry, any path", "—", "unchanged", "TURNED_BACK"),
    "T11": ("VALIDATED", "Root of Heaven entry, any path", "—", "FIXED", "root_phase INSIDE"),
    "T12": ("FIXED or FINAL", "Root of Heaven entry, any path", "—", "unchanged", "open"),
    "T13": ("FIXED", "execution confirmed", "the final authorization scene is playing; witness_mandate is not FAILED",
            "FINAL", "root_phase FINAL"),
    # Lifecycle revision 2: the T14 legacy catch-up is cut (user decision D2); T14 is the stand-down (D1).
    "T14": ("FIXED", "Kaelen stands down", "the final authorization scene is playing; witness_mandate FAILED", "FINAL",
            "root_phase FINAL; nothing executed"),
}
GATE_EVENT = "Root of Heaven entry, any path"
STORED_PHASES = ("VALIDATED", "FIXED", "FINAL")
GATE_TABLE = {  # phases cell -> outcome cell, backticks removed
    "LEANING, PARTLY_LOCKED": "TURNED_BACK: the Assembly has not decided",
    "DEFERRED": "LAST_CHANCE: offers the six R1 renegotiations and, when WITNESS is enabled and its prerequisites are "
                "met, invoke:WITNESS; leaving returns the player outside, still DEFERRED",
    "VALIDATED": "ROOT_OF_HEAVEN; root_phase becomes INSIDE (T11)",
    "FIXED, FINAL": "ROOT_OF_HEAVEN; nothing changes (T12)",
}
RED_LINE_VALUES = {"R1": "no one hand compels the deleted back",
                   "R2": "no release that destroys unresolved memory appeals",
                   "R3": "no irreversible release while emergency Root is abolished"}
DEFER_CONDITION = "plus defer:{route} when {route} is enabled and its signpost is OPEN"
# Revision 5: crisis_offers has a domain guard; signpost tests CLOSED before falling through to OPEN and hides only a
# reserved, disabled route (I6); the witness vote is a formula.
LIFE_FORMULAS = (
    "crisis_offers(row) = {} if row is not R1, R2 or R3; otherwise",
    '{ "revise:" + axis + ":" + v : axis locked, v ≠ row[axis], not invalid(row with axis = v) }',
    '∪ { "defer:WITNESS" : row = R1, enabled(WITNESS), signpost(WITNESS) = OPEN }',
    'last_chance_offers = crisis_offers(R1) without "defer:WITNESS"',
    '∪ { "invoke:WITNESS" : enabled(WITNESS), prereqs_met(WITNESS) }',
    "signpost(T) = HIDDEN if none of T's offer prerequisites is set, or T is reserved (post-1.0) and disabled",
    'CLOSED if T is disabled, an ID is stored and it is not "SL-SECRET-" + T,',
    "or an unset offer prerequisite of T is unreachable",
    "OPEN otherwise",
    f"witness_threshold = {WITNESS_THRESHOLD}",
    "witness_dissenters = { seat in witness_seats : the seated witness's assent condition is false at C10-S15 }",
    "witness_mandate = MET if 7 − |witness_dissenters| ≥ witness_threshold",
    "FAILED otherwise",
)
LIFE_KEYS = (  # normalized sentences the lifecycle doc must keep
    "The crisis cannot be left, skipped or saved until an offer is taken",
    "confirming (T7) is irreversible. Declining keeps the deferral.",
    "displays the stored structure, offers no reconsideration, and confirm_execution sets root_phase FINAL (T13); "
    "nothing else changes.",
    "No other transition exists: nothing leads from VALIDATED, FIXED or FINAL to an earlier phase or to DEFERRED or "
    "CRISIS — not a knob change, not a flag, not loading.",
    "Loading restores the record, runs the damaged-record check (a DAMAGED record does not load), and derives the "
    "phase; it fires no transition by itself",
    "None of its own.",
    "Not knobs: the scene order, the offer sets (derived from invalid), the rule that C8-S16 cannot be left with a "
    "crisis open, and the rule that a stored ID never changes.",
    # Revision 5 (lifecycle review round 1 and the user's Q1-Q4)
    "Every field is saved, so a reload restores the retractions and beats exactly.",
    "Plays only on SL-SECRET-WITNESS",
    "Kaelen does not authorize in the witnesses' place, and nothing changes the stored ID, the family or the axes.",
    'the Hearth delegate\'s line adds the clause "unless the affected themselves authorize it"',
    "with the signpost HIDDEN or CLOSED the line has no clause.",
    "LAST_CHANCE keeps all six R1 renegotiations.",
    "is read by the composer as what the provisional coalition did, never as the current axis value.",
    "never as it demanding its own replacement",
    "NG+ starts a new record, not a transition of this table",
    # Revision 2 (lifecycle round 2 and the user's D1-D4); qa-lead's round-6 survivors are pinned here and in the
    # derived checks of check_life_revision2.
    "Available from its slot in Chapter 9 until the Chapter 9 end: it plays once, at the first point in that window "
    "at which every Witness offer prerequisite is set",
    "After the Chapter 9 end it cannot play, so a prerequisite still unset then is unreachable and the signpost shows "
    "CLOSED.",
    "the gate offers the invocation and sets the unlock flag itself (S7).",
    "The gate's invoke:WITNESS does not need SEVEN_WITNESSES_AVAILABLE (round 2): the invocation sets it.",
    "Until all four have been shown, defer:WITNESS cannot be taken.",
    "No save exists between the start of C8-S16 and its commit.",
    "as one atomic checkpoint before the beat plays",
    "a reload from the checkpoint resumes at the start of the committed beat, and the offer never replays.",
    "There is no runtime catch-up.",
    "On SL-SECRET-WITNESS with witness_mandate FAILED, confirm_execution is not offered",
    "stand_down sets root_phase FINAL (T14) with nothing executed. The restoration does not happen, and the stored "
    "ID, the family and the axes are unchanged.",
    "Kaelen sits in none",
    "the player sees each seated witness's current stance (would assent or would dissent, and why)",
    "Content rule: the candidate data never lets a playthrough seat seven witnesses whose conditions cannot fail",
    "C10-S15 evaluates each seated witness's condition once, writes witness_dissenters and witness_mandate (Formulas) "
    "once, and names every dissenter",
    f"witness_threshold is fixed at {WITNESS_THRESHOLD} (user decision 2026-11-10): it is data-defined in the route "
    "data, not a knob and not a player choice",
    f"witness_threshold is not a knob either: it is fixed at {WITNESS_THRESHOLD} (Formulas).",
    "Cut order, first cut first. A cut never removes an invariant, a transition, a record field or an id",
)
# The four deferral disclosures (lifecycle round 2, blocker 4): ids, in the order S4 states them.
DISCLOSURES = ("leads_open", "you_narrowed", "act3_as_hearth", "gate_retcon")
# S5 deferral scope table (content, source, under DEFERRED), backticks removed: qa-lead found it unpinned.
S5_ROWS = (
    ("C8-S17 Revolution Name", "PM:7155-7163",
     "beat deferral_c8s17: Hearth joins the naming and says what it has not endorsed"),
    ("C8-S18, C8-S19 Siege (B20)", "PM:7165-7218", "unchanged; the boss reads YOU, HEARTH, RESTORE as locked"),
    ("Act 3 Branch A — Hearth Compact, H-S01 to H-S04, The Steward (B21H)", "PM:7220-7281",
     "beat deferral_branch_h in H-S01: home settlements ask why Hearth has not endorsed; the rest unchanged"),
    ("C8-S20 The Human Patch Door", "PM:7414-7432",
     "beat deferral_c8s20: Kaelen signs the expedition (PM:7424-7426) and the Hearth delegates witness it without "
     "co-signing"),
    ("Secret Quest 09 Witness Seats", "PM:7517-7519", "the player seats the seven witnesses (S9); unchanged otherwise"),
    ("Act 3 ending", "PM:7539-7564",
     "beat deferral_act3_end: the Assembly approves the expedition with Hearth's endorsement still withheld"),
    ("Chapter 9: C9-S01 to C9-S17, the three truth routes, C9-S18, C9-S20, the optional rooms and side quests",
     "PM:7661-8187", "unchanged: the expedition is away from the Assembly; C9-S19 is S6"),
)
H_S5 = ("content", "source", "under DEFERRED")
# Consent variants table (scene, source, Consent variant), backticks removed: feeds L-AC14.
CONSENT_ROWS = (
    ('C10-S06 Axis One Argument, "If AXIS1_YOU"', "PM:8347-8352", "new content"),
    ("C10-S09 Last Offer, Kaelen's answer", "PM:8408 → PM:8411", 'the source\'s "Secret Witness" line'),
    ("B22 SOVEREIGN, axis-specific tools", "PM:8438", 'new content (no "direct Root clashes")'),
    ("C10-S11 The Empty Role", "PM:8495", "new content (the role is not written as KAELEN)"),
    ("B23 God King, AXIS1 YOU route mechanics", "PM:8533-8543",
     "the SEC-01 distinction: the God King tries to collapse the witnesses into Kaelen as executor (PM:11219)"),
    ("B23 base phase 4 Final Permission and its YOU dialogue", "PM:8615-8616, PM:8638-8645",
     "the witnesses authorize, Kaelen executes"),
    ("B23 base phase 5 Crown, ending route interaction", "PM:8617-8618", "S9"),
    ("SOVEREIGN's quote of the commitment", "PM:7059", "quoted as narrowed"),
    ("Final authorization, Authority route line", "PM:8797", "new content (S8)"),
    ('Tier B NPC reactions, "Reaction AXIS1_YOU" (70 NPCs)', "PM:12483-14779", "new content, one line per NPC"),
    ("Companion secret-route reactions", "PM:11229-11236", "the source's lines"),
)
H_CONSENT = ("scene", "source", "Consent variant")
# Key phrases of the L-AC bodies (normalized). qa-lead (round 6) found the bodies mutable beyond their call names.
LAC_KEYS: dict[int, tuple[str, ...]] = {
    5: ("Before the commit current_scene() stays C8-S16 and try_save() is false.",
        "reloading it gives the committed record_hash(), replays the committed beat from its start, and take() of "
        "every offer of that row is false."),
    7: ("before the offer has shown its disclosures take(defer:WITNESS) is false and record_hash() is unchanged",
        "With the signpost HIDDEN or CLOSED, or WITNESS disabled, and on R2 and R3, take(defer:WITNESS) is false and "
        "record_hash() is unchanged."),
    8: ('(authority, YOU, YOU, "final permission", C9-S19)',
        "and take(invoke:WITNESS) there is false with record_hash() unchanged"),
    9: ("LEANING and PARTLY_LOCKED on the story path → TURNED_BACK",
        "on the load path the load is refused with load_errors() naming D{legacy} and no gate entry",
        "DEFERRED → LAST_CHANCE with offers() exactly the six R1 renegotiations plus invoke:WITNESS when WITNESS is "
        "enabled and its prerequisites are met (with and without flag_set(SEVEN_WITNESSES_AVAILABLE))",
        "VALIDATED → ROOT_OF_HEAVEN and FIXED; FIXED and FINAL → ROOT_OF_HEAVEN, phase unchanged"),
    10: ("take() of each of the eight offer strings is false with record_hash() unchanged",),
    13: ("take() of each of the eight offer strings is false with record_hash() unchanged",
         "stand_down() is false; confirm_execution() gives FINAL with storyline_id() unchanged"),
    14: ("record_field(witness_dissenters) is exactly the seats whose condition is false",
         "dissent_named() is exactly their identities",
         "ending_modules() contains consent_unauthorized exactly when it is FAILED",
         "C10-S15 does not become current_scene() again"),
    15: ("YOU locked at C8-S14 and never revised → STATED, the C8-S14 commitment",
         "YOU reached by a renegotiation (from R2 or R3) → STATED, that scene's commitment",
         "YOU withdrawn by a renegotiation from R1 at C8-S16 or at the gate → WITHDRAWN",
         "Authority never YOU → NONE"),
    16: ("(D1-D{ec16})", "and the load is refused (current_scene() stays load_menu)"),
    19: ("beats_played() contains both retract_R1_<axis>_<new> and gate_retcon_<axis>_<new>",
         "retraction_log() gains an entry with scene LAST_CHANCE"),
    20: ("on load load_errors() names D{legacy}, current_scene() stays load_menu, and no lock scene plays.",),
    21: ("once after decline() at C9-S19 and once with C9-S19 never played",
         '(authority, YOU, YOU, "final permission", LAST_CHANCE)',
         "With one prerequisite unset, take(invoke:WITNESS) is false with record_hash() unchanged.",
         "The same holds with all three set and record_field(witness_seats) holding six of the seven seats",
         "offers() then lacks invoke:WITNESS"),
    22: ("confirm_execution() is false with record_hash() unchanged; route_lines() is empty; stand_down() gives FINAL "
         "with storyline_id() and each axis() unchanged; ending_modules() contains consent_unauthorized",
         "With witness_mandate MET, stand_down() is false and confirm_execution() gives FINAL."),
    23: ("beat_text(id) is non-empty and beat_speaker(id) is non-empty",
         "for every retract_* id beat_speaker(id) is not Kaelen"),
    24: ("one retained screenshot each in production/qa/evidence/, with lead sign-off recorded beside them",),
}
# Assertions that cannot fail (offers() is empty in every non-offer scene): forbidden in the L-ACs (round 2).
NON_FAILING = ("offers() is empty", "offers nothing", "offers() there is empty")
# Legacy storyline flags (lifecycle round 2, D2): each must be listed in the lifecycle Dependencies and occur in the
# code lines that row cites (setter and the game_manager declaration).
LEGACY_FLAGS = ("ch8_revolt_led", "ch8_council_formed", "ch8_witness_network_created", "ending_route_ch8_lead",
                "ending_route_ch8_council", "ending_route_ch8_witness", "ch10_destroy_sovereign",
                "ch10_rewrite_sovereign", "true_ending_seen", "ng_plus_unlocked")
LIFE_REQUIRED_PATHS = 3  # cross-checked against the S7 path list and the Validation note

REQUIRED_HEADINGS = (("Overview",), ("Player Fantasy",), ("Detailed Rules", "Detailed Design"), ("Formulas",),
                     ("Edge Cases",), ("Dependencies",), ("Tuning Knobs",), ("Acceptance Criteria",))
OPTIONAL_HEADINGS = frozenset({"Summary", "Cross-References", "Open Questions"})

# Removed by review revisions 1-2; must not reappear. ("secret_invoked" left this list in revision 4: it is the
# composer set of confirmed invocations again, GDD AC3.) "C8-S17" is the mis-cited final scene in the axes doc;
# the lifecycle doc cites the real C8-S17 Revolution Name (PM:7155-7163), so it is exempt there.
STALE_STRINGS = ("PM:3615", "C8-S17", "ch8_choice_made", "S = T", "Kaelen only executes", "PM:8735",
                 "final authorization, before", "PM:7118", "Kaelen may be one witness",
                 "at the final confrontation, to dismantle", "PM:7062-7070",
                 # revision 6 / lifecycle revision 2
                 "consent_failed_mandate", "failed-mandate", "authorized over dissent", "lock catch-up",
                 "T14 catch-up", "legacy-save catch-up")
STALE_LIFECYCLE_EXEMPT = frozenset({"C8-S17"})
# Revision-3 vocabulary removed by revision 4; allowed only in storyline-axes.md's Open Questions.
STALE_VOCAB = ("storyline_state", "final_reconsidered", "reconsider_targets", "reconsideration_triggers",
               "GATE_CRISIS", "crisis_endured", "renegotiations_valid", "faction_negotiation_allowed",
               "invalid_combinations")

BIBLE_DECISION_PREFIX = "**Decided (2026-11-08, Y1-P0-S06a):**"

# Table headers, matched exactly (after stripping cells and backticks).
H_COMBO = ("id", "authority", "faction", "deleted", "status", "family", "rule", "source", "danger",
           "companions_possible")
H_RULES = ("rule", "combination", "contradiction", "source")
H_SECRET = ("id", "route", "family", "scope", "source")
H_SEED = ("flag", "pushes", "direction", "overturnable", "source")
H_SIDE = ("arc", "title", "primary", "secondary", "scope", "pm_line")
H_COMPOSER = ("field", "type", "allowed", "writer")
H_INVARIANTS = ("#", "invariant", "rules")
H_PHASES = ("phase", "meaning", "gate")
H_OBSERVABLES = ("observable", "returns")
H_LIFE_OBSERVABLES = ("observable", "returns", "outside its scene")
H_TRANSITIONS = ("#", "from", "event", "guard", "to", "effects")
H_GATE = ("phase", "outcome")
H_RED_LINES = ("locked pair", "speaker", "rule", "the value voiced")
H_OFFERS = ("row", "offers")
H_RETRACTIONS = ("axis", "withdrawn on the record", "source")

SOURCE_ALIASES = {
    "PRODUCTION_MASTER_2.1.md": "AethelgardPrototype/story/source/PRODUCTION_MASTER_2.1.md",
    "STORY_BIBLE.md": "AethelgardPrototype/story/STORY_BIBLE.md",
    "ROADMAP_10_YEAR.md": "AethelgardPrototype/ROADMAP_10_YEAR.md",
}
PM_PATH = SOURCE_ALIASES["PRODUCTION_MASTER_2.1.md"]
SOURCE_RE = re.compile(r"^(?P<file>[\w./\\-]+\.(?:md|dlg|gd)):(?P<line>\d+)$")
JUDGEMENT_SUFFIX = " (J)"
FLAG_RE = re.compile(r"^[a-z][a-z0-9_]*$")

REPO_ROOT = Path(__file__).resolve().parents[4]


class Problems:
    """Collects problem lines in the order they are found."""

    def __init__(self) -> None:
        """Start with no problems."""
        self.items: list[str] = []

    def add(self, area: str, message: str) -> None:
        """Record one problem, prefixed with the area it belongs to."""
        self.items.append(f"[{area}] {message}")


def read_lines(path: Path) -> list[str]:
    """Return the file's lines (UTF-8, BOM tolerated) without line endings."""
    return path.read_text(encoding="utf-8-sig").splitlines()


def split_row(line: str) -> list[str]:
    """Split a Markdown table row into stripped cells with backticks removed."""
    body = line.strip()
    if body.startswith("|"):
        body = body[1:]
    if body.endswith("|"):
        body = body[:-1]
    return [cell.strip().replace("`", "") for cell in body.split("|")]


def norm(text: str) -> str:
    """Prose normalization for pinned sentences: drop backticks and ``**``, collapse whitespace."""
    return re.sub(r"\s+", " ", text.replace("`", "").replace("**", "")).strip()


def norm_code(line: str) -> str:
    """Code normalization for pinned formula lines: collapse whitespace."""
    return re.sub(r"\s+", " ", line).strip()


def find_table(lines: list[str], header: tuple[str, ...]) -> list[tuple[int, list[str]]] | None:
    """Return the body rows (1-based line number, cells) of the first table whose header equals ``header``."""
    for index, line in enumerate(lines):
        if not line.lstrip().startswith("|") or tuple(split_row(line)) != header:
            continue
        rows = []
        for offset in range(index + 2, len(lines)):
            if not lines[offset].lstrip().startswith("|"):
                break
            rows.append((offset + 1, split_row(lines[offset])))
        return rows
    return None


def is_dash(cell: str) -> bool:
    """True if the cell is an empty-value dash."""
    return cell in DASHES


def abbreviation(triple: tuple[str, ...]) -> str:
    """The production master's three-letter code for an (authority, faction, deleted) triple, e.g. YHR."""
    return "".join(ABBR.get(value, "?") for value in triple)


def get_table(lines: list[str], header: tuple[str, ...], area: str, probs: Problems) -> list[tuple[int, list[str]]]:
    """Find a table, report it if missing, and drop (reporting) rows with the wrong number of cells."""
    rows = find_table(lines, header)
    if rows is None:
        probs.add(area, f"table with header '{' | '.join(header)}' not found")
        return []
    good = []
    for lineno, cells in rows:
        if len(cells) != len(header):
            probs.add(area, f"line {lineno}: {len(cells)} cells, expected {len(header)}")
        else:
            good.append((lineno, cells))
    return good


def section(lines: list[str], heading: str) -> tuple[int, int] | None:
    """Return (first body index, end index) of the section whose heading line equals ``heading``.

    The section ends at the next heading of the same or a higher level.
    """
    try:
        start = lines.index(heading)
    except ValueError:
        return None
    level = len(heading) - len(heading.lstrip("#"))
    for n in range(start + 1, len(lines)):
        m = re.match(r"^(#+) ", lines[n])
        if m and len(m[1]) <= level:
            return start + 1, n
    return start + 1, len(lines)


def code_body(lines: list[str], prefix: str) -> tuple[int, list[str]] | None:
    """The normalized lines of the code block starting at the line that begins with ``prefix``.

    The block runs to the first blank line or code fence. Returns (1-based line of the definition, lines), or None.
    """
    for index, line in enumerate(lines):
        if line.lstrip().startswith(prefix):
            body = []
            for n in range(index, len(lines)):
                if not lines[n].strip() or lines[n].lstrip().startswith("```"):
                    break
                body.append(norm_code(lines[n]))
            return index + 1, body
    return None


def paragraph_after_fence(lines: list[str], lineno: int) -> str:
    """The prose paragraph after the code fence that contains 1-based line ``lineno``."""
    n = lineno
    while n < len(lines) and not lines[n].lstrip().startswith("```"):
        n += 1
    n += 1
    while n < len(lines) and not lines[n].strip():
        n += 1
    text = []
    while n < len(lines) and lines[n].strip():
        text.append(lines[n])
        n += 1
    return " ".join(text)


def numbered_items(lines: list[str], bounds: tuple[int, int] | None,
                   pattern: str = r"^(\d+)\. \*\*(.+?)\*\*") -> list[tuple[int, int, str, str]]:
    """Numbered bold-titled items in ``bounds``: (1-based line, number, title, full normalized text)."""
    if bounds is None:
        return []
    start, end = bounds
    items: list[tuple[int, int, str, list[str]]] = []
    for n in range(start, end):
        if m := re.match(pattern, lines[n]):
            items.append((n + 1, int(m[1]), m[2], [lines[n]]))
        elif items and lines[n].strip() and not lines[n].startswith("#"):
            items[-1][3].append(lines[n])
    return [(ln, num, title, norm(" ".join(text))) for ln, num, title, text in items]


class SourceResolver:
    """Resolves ``file:line`` citations under the repo root and caches each file's lines."""

    def __init__(self, root: Path) -> None:
        """Bind to a repo root."""
        self.root = root
        self.cache: dict[Path, list[str] | None] = {}

    def resolve(self, name: str) -> Path | None:
        """Return the existing path for a cited file name, or None."""
        candidates = [self.root / SOURCE_ALIASES[name]] if name in SOURCE_ALIASES else []
        candidates += [self.root / name, self.root / "AethelgardPrototype" / name]
        return next((p for p in candidates if p.is_file()), None)

    def lines(self, path: Path) -> list[str] | None:
        """Return a file's lines (cached), or None if unreadable."""
        if path not in self.cache:
            try:
                self.cache[path] = read_lines(path)
            except (OSError, UnicodeDecodeError):
                self.cache[path] = None
        return self.cache[path]

    def line_text(self, cell: str) -> tuple[str | None, str | None]:
        """Return (error, text of the cited line) for a ``file:line`` citation; exactly one is None."""
        match = SOURCE_RE.match(cell)
        if not match:
            return f"source '{cell}' is not <file>:<line>", None
        path = self.resolve(match["file"])
        if path is None:
            return f"source file '{match['file']}' not found under the repo", None
        content = self.lines(path)
        line = int(match["line"])
        if content is None or not 1 <= line <= len(content):
            return f"source '{cell}' line out of range", None
        return None, content[line - 1]

    def check(self, cell: str) -> str | None:
        """Return an error message for a malformed or dangling ``file:line`` citation, or None if it is good."""
        return self.line_text(cell)[0]

    def pm(self) -> list[str] | None:
        """The production master's lines, or None if unreadable."""
        return self.lines(self.root / PM_PATH)


# --- Reference semantics, computed here from first principles -------------------------------------------------
def crisis_offers(rules: dict[str, tuple[str, ...]]) -> dict[str, set[str]]:
    """Per rule: the renegotiations ``revise:<axis>:<v>`` whose new row is valid (lifecycle ``crisis_offers``)."""
    invalid = set(rules.values())
    offers: dict[str, set[str]] = {}
    for rule, triple in rules.items():
        offers[rule] = set()
        for index, (axis, values) in enumerate(AXES.items()):
            for value in values:
                new = tuple(value if i == index else x for i, x in enumerate(triple))
                if value != triple[index] and new not in invalid:
                    offers[rule].add(f"revise:{axis}:{value}")
    return offers


def py_lock_pass(axis: str, value: str, flags: set[str]) -> str:
    """``lock_pass`` over the approved seed map: CLEAN iff some (axis:value, +) seed and no (axis:value, −) seed."""
    target = f"{axis}:{value}"
    plus = any(SEED_EXPECTED.get(f) == (target, "+") for f in flags)
    minus = any(SEED_EXPECTED.get(f) == (target, "−") for f in flags)
    return "CLEAN" if plus and not minus else "NEGOTIATED"


def py_phase(a: str, f: str, d: str, stored: bool, deferred: bool, root: str,
             deferral_row: tuple[str, ...] = ("YOU", "HEARTH", "RESTORE"), loaded: bool = True) -> str:
    """The phase of a record: the Edge Case 16 items decidable from these six fields first (D4, D8, and D9 only when
    ``loaded``), then FINAL > FIXED > VALIDATED (each needing a stored ID) > unlocked > deferred."""
    unset = [v == UNSET for v in (a, f, d)]
    if not stored and root in ("INSIDE", "FINAL"):
        return "DAMAGED"  # D8
    if deferred and (any(unset) or (not stored and (a, f, d) != deferral_row)):
        return "DAMAGED"  # D4
    if loaded and not stored and not any(unset) and not deferred:
        return "DAMAGED"  # D9 (a loaded record only: in play this record is the crisis inside C8-S16)
    if stored:
        return "FINAL" if root == "FINAL" else "FIXED" if root == "INSIDE" else "VALIDATED"
    if all(unset):
        return "LEANING"
    if any(unset):
        return "PARTLY_LOCKED"
    return "DEFERRED" if deferred else "CRISIS"


CTX: dict[str, object] = {}  # values derived by one check and read by a later one


# --- 1. Headings ---------------------------------------------------------------------------------------------------
def check_headings(lines: list[str], area: str, probs: Problems) -> None:
    """The 8 required H2 headings appear exactly once each, in order; other H2s are only the allowed extras."""
    headings, in_fence = [], False
    for lineno, line in enumerate(lines, 1):
        if line.lstrip().startswith("```"):
            in_fence = not in_fence
        elif not in_fence and line.startswith("## "):
            headings.append((lineno, line[3:].strip()))
    required = []
    for lineno, text in headings:
        if any(text in names for names in REQUIRED_HEADINGS):
            required.append(text)
        elif text not in OPTIONAL_HEADINGS:
            probs.add(area, f"line {lineno}: unexpected H2 heading '{text}'")
    for names in REQUIRED_HEADINGS:
        count = sum(text in names for text in required)
        if count == 0:
            probs.add(area, f"missing heading '## {names[0]}'")
        elif count > 1:
            probs.add(area, f"heading '## {names[0]}' appears {count} times")
    order = [next(i for i, names in enumerate(REQUIRED_HEADINGS) if text in names) for text in required]
    if order != sorted(order):
        probs.add(area, f"required headings out of order: {', '.join(required)}")


# --- 2. The 27 combinations ----------------------------------------------------------------------------------------
def check_rules(lines: list[str], src: SourceResolver, probs: Problems) -> dict[str, tuple[str, ...]]:
    """Check the rules table (ids, combinations, quoted text on its cited line); return rule -> triple."""
    area = "combinations"
    rules: dict[str, tuple[str, ...]] = {}
    for lineno, (rule, combo, text, source) in get_table(lines, H_RULES, area, probs):
        if not re.fullmatch(r"R\d+", rule):
            probs.add(area, f"line {lineno}: rule id '{rule}' is not R<n>")
        triple = tuple(part.strip() for part in combo.split("+"))
        if len(triple) != 3 or any(v not in AXES[n] for n, v in zip(AXES, triple)):
            probs.add(area, f"line {lineno}: rule {rule} combination '{combo}' is not AUTHORITY + FACTION + DELETED")
        if rule in rules:
            probs.add(area, f"line {lineno}: rule {rule} defined twice")
        rules[rule] = triple
        err, cited = src.line_text(source)
        if err is not None:
            probs.add(area, f"line {lineno}: rules table {err}")
        elif text.strip('"“” ') not in cited:
            probs.add(area, f"line {lineno}: rule {rule} contradiction text is not on {source}")
    return rules


def check_invalid_formula(lines: list[str], rules: dict[str, tuple[str, ...]], probs: Problems) -> None:
    """The Formulas' ``invalid(A, F, D) = (A, F, D) ∈ { ... }`` has that shape and the rules table's set."""
    area = "formulas"
    defs = [(n, line.strip()) for n, line in enumerate(lines, 1) if line.lstrip().startswith("invalid(A, F, D) =")]
    if len(defs) != 1:
        probs.add(area, f"expected one 'invalid(A, F, D) =' definition, found {len(defs)}")
        return
    lineno, line = defs[0]
    if not norm_code(line).startswith(INVALID_PREFIX) or not line.endswith("}"):
        probs.add(area, f"line {lineno}: invalid() is not '{INVALID_PREFIX} ... }}'")
    body = line.split("∈", 1)[-1]
    triples = {tuple(v.strip() for v in m.split(",")) for m in re.findall(r"\(([^()]*)\)", body)}
    if triples != set(rules.values()):
        probs.add(area, f"line {lineno}: invalid() set {sorted(triples)} != rules table {sorted(rules.values())}")


def check_combinations(lines: list[str], src: SourceResolver, probs: Problems) -> tuple[dict[str, tuple[str, ...]], int]:
    """Check the rules table, the 27-row combination table and the count statements; return (rules, valid rows)."""
    area = "combinations"
    rules = check_rules(lines, src, probs)
    check_invalid_formula(lines, rules, probs)

    rows = get_table(lines, H_COMBO, area, probs)
    if len(rows) != 27:
        probs.add(area, f"combination table has {len(rows)} rows, expected 27")
    seen_ids: dict[str, int] = {}
    triples: list[tuple[str, str, str]] = []
    family_counts = {family: 0 for family in FAMILY_BY_AUTHORITY.values()}
    valid_rows = 0
    invalid_triples: list[tuple[str, str, str]] = []
    pm = src.pm() or []
    for lineno, (sl_id, auth, fac, dele, status, family, rule, source, danger, comps) in rows:
        where = f"line {lineno} ({sl_id})"
        if sl_id in seen_ids:
            probs.add(area, f"{where}: duplicate id {sl_id} (first at line {seen_ids[sl_id]})")
        else:
            seen_ids[sl_id] = lineno
        for name, value in (("authority", auth), ("faction", fac), ("deleted", dele)):
            if value not in AXES[name]:
                probs.add(area, f"{where}: {name} '{value}' not in {'/'.join(AXES[name])}")
        triple = (auth, fac, dele)
        triples.append(triple)
        if sl_id != f"SL-{auth}-{fac}-{dele}":
            probs.add(area, f"{where}: id does not match columns (expected SL-{auth}-{fac}-{dele})")
        err, cited = src.line_text(source)
        if err is not None:
            probs.add(area, f"{where}: {err}")
        if status == "valid":
            valid_rows += 1
            if family in family_counts:
                family_counts[family] += 1
            expected = FAMILY_BY_AUTHORITY.get(auth)
            if family != expected:
                probs.add(area, f"{where}: valid row family '{family}', expected {expected}")
            if not is_dash(rule):
                probs.add(area, f"{where}: valid row cites rule '{rule}', expected —")
            heading = f"# STORYLINE {abbreviation(triple)} "
            if cited is not None and not cited.startswith(heading):
                probs.add(area, f"{where}: source {source} is not the '{heading.strip()}' heading")
            elif cited is not None:
                start = int(source.rsplit(":", 1)[1])
                first = next((i + 1 for i in range(start, len(pm)) if pm[i].startswith(("Primary danger:", "# "))),
                             None)
                want = None
                if first is not None and pm[first - 1].startswith("Primary danger:"):
                    want = f"{PM_PATH.rsplit('/', 1)[1]}:{first}"
                if want is None or danger != want:
                    probs.add(area, f"{where}: danger '{danger}' is not the route's first 'Primary danger:' line "
                                    f"({want})")
        elif status == "invalid":
            if not is_dash(family):
                probs.add(area, f"{where}: invalid row family '{family}', expected —")
            invalid_triples.append(triple)
            if rule not in rules:
                probs.add(area, f"{where}: invalid row rule '{rule}' is not in the rules table")
            elif rules[rule] != triple:
                probs.add(area, f"{where}: invalid row cites {rule}, whose combination is {' + '.join(rules[rule])}")
            if cited is not None and not cited.startswith("Invalid V"):
                probs.add(area, f"{where}: source {source} is not an 'Invalid V' line")
            if not is_dash(danger):
                probs.add(area, f"{where}: invalid row danger '{danger}', expected —")
        else:
            probs.add(area, f"{where}: status '{status}' not in valid/invalid")
        present = {c.strip() for c in comps.split(",") if c.strip() and not is_dash(c.strip())}
        if unknown := present - COMPANIONS:
            probs.add(area, f"{where}: companions_possible has unknown names {sorted(unknown)}")
        # GDD Core Rule 11: companions are independent of the axes, so every row lists every companion.
        if missing := COMPANIONS - present:
            probs.add(area, f"{where}: companions_possible omits {sorted(missing)} (Core Rule 11)")
        if status == "valid" and (missing := FAMILY_NEEDS.get(family, frozenset()) - present):
            probs.add(area, f"{where}: family {family} needs companions {sorted(missing)} the row omits")

    expected_set = set(itertools.product(AUTHORITY, FACTION, DELETED))
    for triple in sorted(expected_set - set(triples)):
        probs.add(area, f"missing combination {'-'.join(triple)}")
    for triple in sorted(set(triples) - expected_set):
        probs.add(area, f"combination {'-'.join(triple)} is outside the 3x3x3 product")

    if len(invalid_triples) != len(rules):
        probs.add(area, f"{len(invalid_triples)} invalid rows, but the rules table has {len(rules)} rules")
    rule_triples = set(rules.values())
    for triple in sorted(set(invalid_triples) - rule_triples):
        probs.add(area, f"invalid row {'-'.join(triple)} matches no rule combination")
    for triple in sorted(rule_triples - set(invalid_triples)):
        probs.add(area, f"rule combination {'-'.join(triple)} is not an invalid row")

    counts = [(n, int(m[1])) for n, line in enumerate(lines, 1) for m in re.finditer(r"valid_count:\s*(\d+)", line)]
    if not counts:
        probs.add(area, "no 'valid_count: N' line")
    for lineno, declared in counts:
        if declared != valid_rows:
            probs.add(area, f"line {lineno}: valid_count: {declared} but the table has {valid_rows} valid rows")
    splits = [(n, m) for n, line in enumerate(lines, 1)
              for m in re.finditer(r"SOLE (\d+), BOUND (\d+), NONE_AUTH (\d+)", line)]
    if not splits:
        probs.add(area, "no 'SOLE n, BOUND n, NONE_AUTH n' statement")
    for lineno, m in splits:
        stated = {"SOLE": int(m[1]), "BOUND": int(m[2]), "NONE_AUTH": int(m[3])}
        if stated != family_counts:
            probs.add(area, f"line {lineno}: family split {stated} but the table has {family_counts}")
    CTX["family_counts"] = family_counts
    return rules, valid_rows


# --- 3. Secret storylines ------------------------------------------------------------------------------------------
def pm_required_flags(pm: list[str]) -> dict[str, list[str]]:
    """Map each secret route to the 'Required flag:' lines of its SEC block in the production master."""
    by_route: dict[str, list[str]] = {}
    route: str | None = None
    for line in pm:
        text = line.strip()
        if text == "---":
            route = None
        elif m := re.fullmatch(r"Secret foundation: ([A-Z]{3})\.", text):
            route = next((r for r, f in SECRET_FOUNDATION.items() if f == m[1]), None)
            if route is not None:
                by_route.setdefault(route, [])
        elif route is not None and (m := re.fullmatch(r"Required flag: ([A-Z0-9_]+)\.", text)):
            by_route[route].append(m[1])
    return by_route


def check_secrets(lines: list[str], src: SourceResolver, rules: dict[str, tuple[str, ...]], valid_rows: int,
                  probs: Problems) -> None:
    """Exactly the three secret ids with the right foundations, prerequisites matching the PM, reachable_1_0."""
    area = "secrets"
    rows = get_table(lines, H_SECRET, area, probs)
    ids = [cells[0] for _, cells in rows]
    for sl_id in sorted(set(SECRET_EXPECTED) - set(ids)):
        probs.add(area, f"missing secret row {sl_id}")
    for sl_id in sorted(set(ids) - set(SECRET_EXPECTED)):
        probs.add(area, f"unexpected secret row {sl_id}")
    if len(ids) != len(set(ids)):
        probs.add(area, "duplicate secret id")
    if len(rows) != len(rules):
        probs.add(area, f"{len(rows)} secret rows, but the rules table has {len(rules)} invalid rows to transform")
    shipped = 0
    route_rule: dict[str, str] = {}
    for lineno, (sl_id, route, family, scope, source) in rows:
        if sl_id not in SECRET_EXPECTED:
            continue
        where = f"line {lineno} ({sl_id})"
        want_family, want_scope = SECRET_EXPECTED[sl_id]
        shipped += scope == "1.0"
        if want_family is not None and family != want_family:
            probs.add(area, f"{where}: family '{family}', expected {want_family}")
        if scope != want_scope:
            probs.add(area, f"{where}: scope '{scope}', expected {want_scope}")
        if (err := src.check(source)) is not None:
            probs.add(area, f"{where}: {err}")
        name = sl_id.removeprefix("SL-SECRET-")
        foundation = SECRET_FOUNDATION[name]
        m = re.search(r"transforms (R\d+) / ([A-Z]{3})", route)
        if m is None:
            probs.add(area, f"{where}: route cell lacks 'transforms R<n> / <abbreviation>'")
            continue
        route_rule[name] = m[1]
        if m[2] != foundation:
            probs.add(area, f"{where}: transforms {m[2]}, but PM:8784 associates it with {foundation}")
        if m[1] not in rules:
            probs.add(area, f"{where}: transforms unknown rule {m[1]}")
        elif abbreviation(rules[m[1]]) != foundation:
            probs.add(area, f"{where}: {m[1]} is {abbreviation(rules[m[1]])}, not {foundation}")

    CTX["shipped"] = shipped
    CTX["route_rule"] = route_rule
    reach = [(n, int(m[1])) for n, line in enumerate(lines, 1) for m in re.finditer(r"reachable_1_0:\s*(\d+)", line)]
    if not reach:
        probs.add(area, "no 'reachable_1_0: N' statement")
    for lineno, declared in reach:
        if declared != valid_rows + shipped:
            probs.add(area, f"line {lineno}: reachable_1_0: {declared}, expected {valid_rows} + {shipped}")

    pm = src.pm()
    knob = [line for line in lines if line.lstrip().startswith("| `secret_prerequisites[")]
    if len(knob) != 1:
        probs.add(area, f"expected one secret_prerequisites knob row, found {len(knob)}")
        return
    unlock = [line for line in lines if line.lstrip().startswith("| `secret_unlock_flag[")]
    if len(unlock) != 1:
        probs.add(area, f"expected one secret_unlock_flag knob row, found {len(unlock)}")
        return
    route_re = r"(WITNESS|CROWNLESS|FIRSTWAKE): ((?:`[A-Z0-9_]+`(?:,\s*)?)+)"
    stated = {m[1]: re.findall(r"[A-Z0-9_]+", m[2]) for m in re.finditer(route_re, knob[0].split("|")[2])}
    unlocks = {m[1]: re.findall(r"[A-Z0-9_]+", m[2]) for m in re.finditer(route_re, unlock[0].split("|")[2])}
    expected = pm_required_flags(pm) if pm is not None else {}
    seen: dict[str, str] = {}
    for route in SECRET_ROUTES:
        if route not in stated or route not in unlocks:
            probs.add(area, f"secret_prerequisites / secret_unlock_flag lists no flags for {route}")
            continue
        if len(unlocks[route]) != 1:
            probs.add(area, f"secret_unlock_flag {route} has {len(unlocks[route])} flags, expected 1")
        if len(stated[route]) < 2:
            probs.add(area, f"secret_prerequisites {route} has {len(stated[route])} flags, expected at least 2")
        for flag in stated[route]:
            if flag in seen:
                probs.add(area, f"secret_prerequisites flag {flag} is listed for {seen[flag]} and {route}")
            seen[flag] = route
        if route not in expected:
            probs.add(area, f"production master has no SEC block for {route}")
        elif stated[route] + unlocks[route] != expected[route]:
            probs.add(area, f"secret_prerequisites + secret_unlock_flag {route} {stated[route] + unlocks[route]} "
                            f"!= production master {expected[route]}")


# --- 4. Act 1 seed map and side storylines -------------------------------------------------------------------------
def load_game_text(root: Path) -> str:
    """Concatenate every ``scripts/**/*.gd`` and ``dialogue/**/*.dlg`` file, dropping whole-line ``#`` comments."""
    game = root / "AethelgardPrototype"
    files = sorted(game.glob("scripts/**/*.gd")) + sorted(game.glob("dialogue/**/*.dlg"))
    kept = []
    for path in files:
        for line in path.read_text(encoding="utf-8", errors="replace").splitlines():
            if not line.lstrip().startswith("#"):
                kept.append(line)
    return "\n".join(kept)


def flag_exists(flag: str, game_text: str) -> bool:
    """True if ``flag`` occurs as a whole word in the (comment-free) game scripts or dialogue."""
    return re.search(rf"(?<![A-Za-z0-9_]){re.escape(flag)}(?![A-Za-z0-9_])", game_text) is not None


def valid_push(cell: str, allow_wildcard: bool) -> bool:
    """True if ``cell`` is an axis value, a ``modifier:<name>``, ``timing`` or (side arcs) a secret route."""
    if cell == "timing" or re.fullmatch(r"modifier:\S+", cell):
        return True
    axis, _, value = cell.partition(":")
    if axis in AXES:
        return value in AXES[axis] or (allow_wildcard and value == "*")
    return allow_wildcard and axis == "secret" and value in SECRET_ROUTES


def check_seed_map(lines: list[str], game_text: str, src: SourceResolver, probs: Problems) -> None:
    """The seed map covers exactly the seed flags, each in the game; direction and overturnable follow pushes."""
    area = "seed map"
    rows = get_table(lines, H_SEED, area, probs)
    flags = [cells[0] for _, cells in rows]
    for flag in sorted(SEED_FLAGS - set(flags)):
        probs.add(area, f"seed flag '{flag}' missing from the seed map")
    for flag in sorted(set(flags) - SEED_FLAGS):
        probs.add(area, f"flag '{flag}' is not a seed flag")
    for flag in sorted({f for f in flags if flags.count(f) > 1}):
        probs.add(area, f"flag '{flag}' listed {flags.count(flag)} times")
    for lineno, (flag, pushes, direction, overturn, source) in rows:
        where = f"line {lineno} ({flag})"
        if not FLAG_RE.match(flag) or not flag_exists(flag, game_text):
            probs.add(area, f"{where}: flag not found outside comments in AethelgardPrototype/scripts or dialogue")
        if not valid_push(pushes, allow_wildcard=False):
            probs.add(area, f"{where}: pushes '{pushes}' is not an axis value, modifier:<name> or timing")
        axis = pushes.partition(":")[0]
        if direction not in DIRECTIONS:
            probs.add(area, f"{where}: direction '{direction}' not +, − or 0")
        elif axis in AXES and direction not in LEAN_DIRECTIONS:
            probs.add(area, f"{where}: axis seed direction '{direction}', expected + or −")
        elif pushes == "timing" and direction != NEUTRAL:
            probs.add(area, f"{where}: timing row direction '{direction}', expected 0")
        want = f"until:lock:{axis}" if axis in AXES else "no"
        if overturn not in OVERTURNABLE:
            probs.add(area, f"{where}: overturnable '{overturn}' not in {', '.join(OVERTURNABLE)}")
        elif overturn != want:
            probs.add(area, f"{where}: overturnable '{overturn}' for pushes '{pushes}', expected {want}")
        if (err := src.check(source.removesuffix(JUDGEMENT_SUFFIX))) is not None:
            probs.add(area, f"{where}: {err}")
        if flag in SEED_EXPECTED:
            want_push, want_dir = SEED_EXPECTED[flag]
            if pushes != want_push or direction.replace("-", "−") != want_dir:
                probs.add(area, f"{where}: '{pushes} {direction}' differs from the approved '{want_push} {want_dir}'")
    if not any(f"({len(SEED_EXPECTED)} flags)" in line for line in lines):
        probs.add(area, f"seed map intro does not state '({len(SEED_EXPECTED)} flags)'")


def check_side_arcs(lines: list[str], src: SourceResolver, probs: Problems) -> None:
    """Arcs 01-12, valid cells, and pm_line on an 'Axis effect:' line of the PM, increasing in arc order."""
    area = "side storylines"
    rows = get_table(lines, H_SIDE, area, probs)
    arcs = [cells[0] for _, cells in rows]
    for arc in SIDE_ARCS:
        if arc not in arcs:
            probs.add(area, f"arc {arc} missing")
    for arc in sorted(set(arcs) - set(SIDE_ARCS)):
        probs.add(area, f"unexpected arc '{arc}'")
    for arc in sorted({a for a in arcs if arcs.count(a) > 1}):
        probs.add(area, f"arc {arc} listed {arcs.count(arc)} times")
    pm = src.pm()
    if pm is None:
        probs.add(area, f"cannot read {PM_PATH}")
    by_arc: dict[str, int] = {}
    for lineno, (arc, title, primary, secondary, scope, pm_line) in rows:
        where = f"line {lineno} (arc {arc})"
        if not title:
            probs.add(area, f"{where}: empty title")
        if not primary or is_dash(primary) or not valid_push(primary, allow_wildcard=True):
            probs.add(area, f"{where}: primary '{primary}' is not an axis value, modifier, secret route or timing")
        if not (is_dash(secondary) or valid_push(secondary, allow_wildcard=True)):
            probs.add(area, f"{where}: secondary '{secondary}' is not a valid effect or —")
        want_scope = "post-1.0" if arc in POST_1_0_ARCS else "1.0"
        if scope not in SCOPES or scope != want_scope:
            probs.add(area, f"{where}: scope '{scope}', expected {want_scope}")
        if not pm_line.isdigit():
            probs.add(area, f"{where}: pm_line '{pm_line}' is not a line number")
            continue
        n = int(pm_line)
        by_arc[arc] = n
        if pm is not None and not (1 <= n <= len(pm) and pm[n - 1].strip().startswith("Axis effect:")):
            probs.add(area, f"{where}: PRODUCTION_MASTER_2.1.md:{n} is not an 'Axis effect:' line")
    ordered = [by_arc[a] for a in SIDE_ARCS if a in by_arc]
    if ordered != sorted(ordered) or len(set(ordered)) != len(ordered):
        probs.add(area, "pm_line values are not strictly increasing in arc order (arcs appear in PM order)")


# --- 5. Composer input record --------------------------------------------------------------------------------------
def check_composer(lines: list[str], probs: Problems) -> None:
    """Exactly the AC3 fields, each with its pinned type, allowed values and writer."""
    area = "composer"
    rows = get_table(lines, H_COMPOSER, area, probs)
    fields = [cells[0] for _, cells in rows]
    for field in sorted({f for f in fields if fields.count(f) > 1}):
        probs.add(area, f"field '{field}' listed {fields.count(field)} times")
    for field in fields:
        if field not in COMPOSER:
            probs.add(area, f"unexpected field '{field}' (AC3 lists exactly {len(COMPOSER)} rows)")
    by_field = {cells[0]: (lineno, cells) for lineno, cells in rows}
    for field, (want_type, want_allowed, want_writer) in COMPOSER.items():
        if field not in by_field:
            probs.add(area, f"required field '{field}' missing")
            continue
        lineno, (_, typ, allowed, writer) = by_field[field]
        where = f"line {lineno} ({field})"
        if typ != want_type:
            probs.add(area, f"{where}: type '{typ}', expected '{want_type}'")
        if isinstance(want_allowed, str):
            if allowed != want_allowed:
                probs.add(area, f"{where}: allowed '{allowed}', expected '{want_allowed}'")
        elif {v.strip() for v in allowed.split(",")} != set(want_allowed):
            probs.add(area, f"{where}: allowed {sorted(v.strip() for v in allowed.split(','))} != "
                            f"{sorted(want_allowed)}")
        if writer != want_writer:
            probs.add(area, f"{where}: writer '{writer}', expected '{want_writer}'")


# --- 6. Formulas ---------------------------------------------------------------------------------------------------
def pin_body(lines: list[str], prefix: str, want: tuple[str, ...], area: str, probs: Problems) -> tuple[int, list[str]]:
    """Compare the code block starting with ``prefix`` with its pinned lines; report the first difference."""
    found = code_body(lines, prefix)
    if found is None:
        probs.add(area, f"no '{prefix}' definition")
        return 0, []
    lineno, body = found
    if tuple(body) != want:
        diff = next((i for i, (a, b) in enumerate(zip(body, want)) if a != b), min(len(body), len(want)))
        got = body[diff] if diff < len(body) else "<missing>"
        exp = want[diff] if diff < len(want) else "<nothing>"
        probs.add(area, f"line {lineno + diff}: {prefix.split('(')[0]} body differs from the pinned body: "
                        f"'{got}' (expected '{exp}')")
    return lineno, body


def check_formulas(lines: list[str], rules: dict[str, tuple[str, ...]], probs: Problems) -> None:
    """Pinned bodies; storyline_id signature and inputs; the bodies' result sets; lock_pass and phase examples."""
    area = "formulas"
    defs = [(n, m) for n, line in enumerate(lines, 1) if (m := re.match(r"^\s*storyline_id\(([^)]*)\):\s*$", line))]
    if not defs:
        probs.add(area, "no 'storyline_id(...):' definition")
    for lineno, m in defs:
        params = tuple(p.strip() for p in m[1].split(","))
        if params != STORYLINE_ID_PARAMS:
            probs.add(area, f"line {lineno}: storyline_id{params} != storyline_id{STORYLINE_ID_PARAMS}")
        for n in range(lineno, len(lines)):
            if lines[n].lstrip().startswith("```"):
                break
            code = lines[n].split("#", 1)[0]
            if (hit := FORBIDDEN_ID_INPUTS.search(code)) is not None:
                probs.add(area, f"line {n + 1}: storyline_id body reads '{hit[0]}' (timing/companion input)")
    pin_body(lines, "storyline_id(", STORYLINE_ID_BODY, area, probs)
    prereq = [line for line in lines if line.lstrip().startswith("prereqs_met(T) =")]
    if [norm_code(p) for p in prereq] != [PREREQS_MET_LINE]:
        probs.add(area, f"prereqs_met definition {[norm_code(p) for p in prereq]} != ['{PREREQS_MET_LINE}']")
    lock_line, _ = pin_body(lines, "lock_pass(X, v):", LOCK_PASS_BODY, area, probs)
    phase_line, phase_body = pin_body(lines, "storyline_phase(record, loaded):", STORYLINE_PHASE_BODY, area, probs)
    _, family_body = pin_body(lines, "family(id):", FAMILY_BODY, area, probs)

    # The results each body can return must be exactly the vocabulary the record allows.
    phase_results = [m for line in phase_body[1:] for m in re.findall(r"→ ([A-Z_]+)\s*$", line)]
    if sorted(phase_results) != sorted(PHASES):
        probs.add(area, f"storyline_phase returns {phase_results}, expected each of {list(PHASES)} once")
    family_results = {m for line in family_body[1:] for m in re.findall(r"→ ([A-Z_]+)", line)}
    if family_results != FAMILIES | ID_FAMILY_EXTRA:
        probs.add(area, f"family() returns {sorted(family_results)}, expected {sorted(FAMILIES | ID_FAMILY_EXTRA)}")

    # lock_pass examples, recomputed over the approved seed map.
    if lock_line:
        text = paragraph_after_fence(lines, lock_line)
        examples = text.split("Examples:", 1)[1] if "Examples:" in text else ""
        value_axis = {v: axis for axis, values in AXES.items() for v in values}
        checked, value = 0, None
        for clause in re.split(r"[;.]\s", examples):
            words = [w for w in re.findall(r"[A-Z_]+", clause.split("→")[0]) if w in value_axis]
            value = words[0] if words else value
            m = re.search(r"→\s*(CLEAN|NEGOTIATED)", clause)
            if m is None or value is None:
                continue
            flags = set(re.findall(r"`([a-z0-9_]+)`", clause))
            got = py_lock_pass(value_axis[value], value, flags)
            checked += 1
            if got != m[1]:
                probs.add(area, f"lock_pass example '{norm(clause)}' states {m[1]}, the seed map gives {got}")
        if checked < 4:
            probs.add(area, f"lock_pass has {checked} parseable examples, expected at least 4")

    # storyline_phase examples, recomputed (revision 6: "Examples (loaded records):", DAMAGED examples included).
    if phase_line:
        text = paragraph_after_fence(lines, phase_line)
        # Revision 7: each "Example(s) (...):" label says whether its examples are loaded records or the live record.
        segments = re.split(r"(Examples?[^:]*):", text)
        labelled = [(label.replace("`", ""), body) for label, body in zip(segments[1::2], segments[2::2])]
        examples = " ".join(body for _, body in labelled)
        want = (f"damaged(record, loaded) is true when the record holds an item D1-D{len(EC16_ITEMS)} of Edge Case 16; "
                f"D{EC16_CRISIS} is tested on a loaded record only (loaded true)")
        if want not in norm(text):
            probs.add(area, f"storyline_phase paragraph lacks '{want}'")
        if "FINAL and FIXED need a stored ID" not in norm(text):
            probs.add(area, "storyline_phase paragraph no longer says 'FINAL and FIXED need a stored ID'")
        deferral_row = rules.get(CTX.get("route_rule", {}).get("WITNESS", "R1"), ("YOU", "HEARTH", "RESTORE"))
        if not any(r == "DAMAGED" for _, r in re.findall(r"\(([^()]*)\) → ([A-Z_]+)", examples.replace("`", ""))):
            probs.add(area, "storyline_phase has no DAMAGED example")
        found = [(fields, stated, "loaded false" not in label)
                 for label, body in labelled
                 for fields, stated in re.findall(r"\(([^()]*)\) → ([A-Z_]+)", body.replace("`", ""))]
        if len(found) < 3:
            probs.add(area, f"storyline_phase has {len(found)} parseable examples, expected at least 3")
        if not any(not is_loaded and stated == "CRISIS" for _, stated, is_loaded in found):
            probs.add(area, "storyline_phase has no in-play (loaded false) CRISIS example")
        for fields, stated, is_loaded in found:
            parts = [p.strip() for p in fields.split(",")]
            if len(parts) != 6:
                probs.add(area, f"storyline_phase example '({fields})' does not have 6 fields")
                continue
            a, f, d, sid, deferred, root = parts
            got = py_phase(a, f, d, sid != "nothing stored", deferred == "true", root, deferral_row, is_loaded)
            if got != stated:
                probs.add(area, f"storyline_phase example '({fields})' (loaded {str(is_loaded).lower()}) states "
                                f"{stated}, the phase table gives {got}")


def check_maps(lines: list[str], rules: dict[str, tuple[str, ...]], probs: Problems) -> None:
    """transform() maps each rule to the route PM:8784 gives its combination; both family maps are the fixed one."""
    area = "formulas"
    defs = [(n, line) for n, line in enumerate(lines, 1) if line.lstrip().startswith("transform(A, F, D) =")]
    if len(defs) != 1:
        probs.add(area, f"expected one 'transform(A, F, D) =' definition, found {len(defs)}")
    else:
        lineno, line = defs[0]
        stated = dict(re.findall(r"(R\d+) → ([A-Z]+)", line))
        want = {rule: next((r for r, f in SECRET_FOUNDATION.items() if f == abbreviation(triple)), "?")
                for rule, triple in rules.items()}
        if stated != want:
            probs.add(area, f"line {lineno}: transform() map {stated} != {want} (rules table and PM:8784)")
    maps = [(n, m) for n, line in enumerate(lines, 1)
            for m in re.finditer(r"YOU → (\w+), SHARED → (\w+), NONE → (\w+)", line)]
    if len(maps) < 2:
        probs.add(area, f"expected the family map in Core Rule 10 and in family(), found {len(maps)}")
    for lineno, m in maps:
        stated = {"YOU": m[1], "SHARED": m[2], "NONE": m[3]}
        if stated != FAMILY_BY_AUTHORITY:
            probs.add(area, f"line {lineno}: family map {stated} != {FAMILY_BY_AUTHORITY}")
    witness = [n for n, line in enumerate(lines, 1) if re.match(r"\s*SL-SECRET-WITNESS\s+→ CONSENT\s*$", line)]
    if len(witness) != 1:
        probs.add(area, "family() does not map SL-SECRET-WITNESS → CONSENT exactly once")


def eval_arith(expr: str) -> int | None:
    """Evaluate an integer expression of digits, ×, −, + and spaces; None if it holds anything else."""
    expr = expr.replace("×", "*").replace("−", "-").strip()
    if not re.fullmatch(r"[\d\s*+-]+", expr):
        return None
    total, sign = 0, 1
    for term in re.split(r"\s*([+-])\s*", expr):
        if term in ("+", "-"):
            sign = 1 if term == "+" else -1
            continue
        product = 1
        for factor in term.split("*"):
            product *= int(factor)
        total += sign * product
    return total


def check_counts(lines: list[str], rules: dict[str, tuple[str, ...]], valid_rows: int, probs: Problems) -> None:
    """Every 'name = a = b' line of the Counts block is arithmetically true and equals the value derived here."""
    area = "counts"
    try:
        start = lines.index("### Counts")
    except ValueError:
        probs.add(area, "no '### Counts' section")
        return
    family_counts = CTX.get("family_counts", {})
    shipped = CTX.get("shipped", 0)
    offers = crisis_offers(rules)
    per_rule = [len(offers[rule]) for rule in rules]
    want = {"combinations": len(AUTHORITY) * len(FACTION) * len(DELETED), "valid_count": valid_rows,
            "secret_storylines": len(SECRET_EXPECTED), "design_storylines": valid_rows + len(SECRET_EXPECTED),
            "reachable_1_0": valid_rows + shipped, "family_SOLE": family_counts.get("SOLE"),
            "family_BOUND": family_counts.get("BOUND"), "family_NONE_AUTH": family_counts.get("NONE_AUTH"),
            "renegotiation_offers": sum(per_rule)}
    seen = set()
    for n in range(start + 1, len(lines)):
        if lines[n].startswith("## "):
            break
        m = re.match(r"^(\w+)\s*=\s*(.+)$", lines[n])
        if not m:
            continue
        if m[1] not in want:
            probs.add(area, f"line {n + 1}: unexpected Counts line '{m[1]}'")
            continue
        seen.add(m[1])
        parts = m[2].split("=")
        values = [eval_arith(part) for part in parts]
        if None in values or len(set(values)) != 1:
            probs.add(area, f"line {n + 1}: '{lines[n].strip()}' is not a true chain of equal integers")
        elif values[-1] != want[m[1]]:
            probs.add(area, f"line {n + 1}: {m[1]} = {values[-1]}, but the tables give {want[m[1]]}")
        if m[1] == "renegotiation_offers":
            terms = [int(t) for t in re.findall(r"\d+", parts[0])]
            if terms != per_rule:
                probs.add(area, f"line {n + 1}: renegotiation_offers terms {terms} != per-rule offers {per_rule} "
                                f"({', '.join(rules)}) computed from invalid()")
    for name in sorted(set(want) - seen):
        probs.add(area, f"Counts block has no '{name} = ...' line")


# --- 7. Core Rules, invariants, phases, knobs, edge cases ----------------------------------------------------------
def check_core_rules(lines: list[str], rules: dict[str, tuple[str, ...]], probs: Problems) -> None:
    """Core Rules 1-12 with their titles and pinned key sentences; no modal verbs in Rules 7 and 9."""
    area = "core rules"
    items = numbered_items(lines, section(lines, "### Core Rules"))
    numbers = [num for _, num, _, _ in items]
    if numbers != list(range(1, len(CORE_RULE_TITLES) + 1)):
        probs.add(area, f"Core Rules numbered {numbers}, expected 1-{len(CORE_RULE_TITLES)}")
    offers = crisis_offers(rules)
    route_rule = CTX.get("route_rule", {})
    witness_rule = route_rule.get("WITNESS", "?")
    keys = {n: [k.replace("{legacy}", str(EC16_LEGACY)) for k in v] for n, v in CORE_RULE_KEYS.items()}
    # Rule 4: each rule's red line is voiced by its faction when its Authority and Faction are locked.
    for rule, (a, f, _) in rules.items():
        keys[4].append(f"{f.capitalize()} when {a} and {f} are locked ({rule}")
    # Rule 5: offer counts and the deferral row, derived from invalid() and the secret table.
    others = [r for r in rules if r != witness_rule]
    if witness_rule in offers and others and len({len(offers[r]) for r in others}) == 1:
        keys[5].append(f"{NUMBER_WORDS[len(offers[witness_rule])]} for {witness_rule}, "
                       f"{NUMBER_WORDS[len(offers[others[0]])]} for {' or '.join(others)}")
    keys[5].append(f"Deferral to the witnesses: only on {witness_rule}, only while Witness Protocol is enabled and "
                   "its signpost shows")
    for lineno, num, title, text in items:
        if 1 <= num <= len(CORE_RULE_TITLES) and title != CORE_RULE_TITLES[num - 1]:
            probs.add(area, f"line {lineno}: Core Rule {num} title '{title}', expected '{CORE_RULE_TITLES[num - 1]}'")
        for key in keys.get(num, ()):
            if key not in text:
                probs.add(area, f"line {lineno}: Core Rule {num} lacks the pinned sentence '{key}'")
        if num in NO_MODAL_RULES and (m := MODAL_RE.search(text)):
            probs.add(area, f"line {lineno}: Core Rule {num} uses '{m[0]}' (it states a prohibition; no exceptions)")


def check_invariants(lines: list[str], probs: Problems) -> None:
    """The invariants table has exactly rows I1-I8 as pinned, each citing existing Core Rules."""
    area = "invariants"
    rows = get_table(lines, H_INVARIANTS, area, probs)
    ids = [cells[0] for _, cells in rows]
    if ids != list(INVARIANTS):
        probs.add(area, f"invariant ids {ids} != {list(INVARIANTS)}")
    for lineno, (inv, text, cited) in rows:
        if inv not in INVARIANTS:
            continue
        want_text, want_rules = INVARIANTS[inv]
        if text != want_text:
            probs.add(area, f"line {lineno} ({inv}): '{text}' differs from the pinned invariant")
        if cited != want_rules:
            probs.add(area, f"line {lineno} ({inv}): rules '{cited}', expected '{want_rules}'")
        if any(not 1 <= int(r) <= len(CORE_RULE_TITLES) for r in re.findall(r"\d+", cited)):
            probs.add(area, f"line {lineno} ({inv}): cites a Core Rule outside 1-{len(CORE_RULE_TITLES)}")


def check_phases(lines: list[str], probs: Problems) -> dict[str, str]:
    """The phase table is exactly the pinned phases in order; return phase -> gate cell."""
    area = "phases"
    rows = get_table(lines, H_PHASES, area, probs)
    phases = [cells[0] for _, cells in rows]
    if tuple(phases) != PHASES:
        probs.add(area, f"phase table {phases} != {list(PHASES)}")
    gates: dict[str, str] = {}
    for lineno, (phase, meaning, gate) in rows:
        gates[phase] = gate
        if phase in PHASE_TABLE and (meaning, gate) != PHASE_TABLE[phase]:
            probs.add(area, f"line {lineno} ({phase}): '{meaning} | {gate}' differs from the pinned "
                            f"'{' | '.join(PHASE_TABLE[phase])}'")
    if "storyline_phase is derived, never stored" not in norm(" ".join(lines)):
        probs.add(area, "no 'storyline_phase is derived, never stored' statement")
    return gates


def gate_outcome(gate: str) -> str | None:
    """The lifecycle gate outcome an axes-doc gate cell means (None: no gate in that phase)."""
    if gate.startswith("open"):
        return "ROOT_OF_HEAVEN"
    return GATE_OUTCOME.get(gate)


def check_knobs(lines: list[str], probs: Problems) -> None:
    """Exactly the four pinned knobs with derived defaults; no forbidden knob; the not-knobs list pinned."""
    area = "tuning knobs"
    rows = get_table(lines, KNOB_HEADER, area, probs)
    knobs = [cells[0] for _, cells in rows]
    if tuple(knobs) != KNOBS:
        probs.add(area, f"knobs {knobs} != the pinned {list(KNOBS)}")
    scope_of = {sl.removeprefix("SL-SECRET-"): scope for sl, (_, scope) in SECRET_EXPECTED.items()}
    for lineno, cells in rows:
        knob, default = cells[0], cells[1]
        if m := re.match(r"secret_route_enabled\.(\w+)", knob):
            routes = [m[1], *re.findall(r",\s*\.(\w+)", knob)]
            want = {"true" if scope_of.get(r) == "1.0" else "false" for r in routes}
            if len(want) != 1 or default != want.pop():
                probs.add(area, f"line {lineno} ({knob}): default '{default}' does not follow the secret table scopes")
        for name in FORBIDDEN_KNOBS:
            if name in " ".join(cells):
                probs.add(area, f"line {lineno}: '{name}' is fixed by design, not a knob")
    bounds = section(lines, "## Tuning Knobs")
    text = norm(" ".join(lines[bounds[0]:bounds[1]])) if bounds else ""
    for name in FORBIDDEN_KNOBS:
        if name in text:
            probs.add(area, f"Tuning Knobs section names '{name}'")
    for key in NOT_KNOB_KEYS:
        if key not in text:
            probs.add(area, f"Tuning Knobs 'Not knobs' list lacks '{key}'")


def check_edge_cases(lines: list[str], count: int, area: str, probs: Problems) -> list[tuple[int, int, str, str]]:
    """Edge Cases numbered 1..count contiguously; return the items."""
    items = numbered_items(lines, section(lines, "## Edge Cases"))
    numbers = [num for _, num, _, _ in items]
    if numbers != list(range(1, count + 1)):
        probs.add(area, f"Edge Cases numbered {numbers}, expected 1-{count}")
    return items


def check_axes_edge_cases(lines: list[str], probs: Problems) -> None:
    """Edge Cases 1-16; Edge Case 16 lists exactly D1-D16 as pinned; the D-numbers cited elsewhere resolve."""
    area = "edge cases"
    items = check_edge_cases(lines, AXES_EDGE_CASES, area, probs)
    ec16 = [i for i in items if i[1] == 16]
    if not ec16 or not ec16[0][2].startswith("A damaged record"):
        probs.add(area, "Edge Case 16 'A damaged record' missing")
        return
    lineno, _, _, text = ec16[0]
    found = re.findall(r"- D(\d+) (.+?)(?= - D\d+ | witness_deferred on a stored valid row with axis_revised "
                       r"non-empty|$)", text)
    numbers = [int(n) for n, _ in found]
    if numbers != list(range(1, len(EC16_ITEMS) + 1)):
        probs.add(area, f"line {lineno}: Edge Case 16 items numbered {numbers}, expected D1-D{len(EC16_ITEMS)}")
    for (num, item), want in zip(found, EC16_ITEMS):
        if item.strip() != want:
            probs.add(area, f"line {lineno}: Edge Case 16 D{num} '{item.strip()}' differs from the pinned '{want}'")
    for key in EC16_KEYS:
        if key not in text:
            probs.add(area, f"line {lineno}: Edge Case 16 lacks the pinned sentence '{key}'")
    # Cross-references: the items cited by number must be the ones meant.
    if "exclusive group" not in EC16_ITEMS[EC16_EXCLUSIVE - 1] or "story position" not in EC16_ITEMS[EC16_LEGACY - 1]:
        probs.add(area, "EC16_EXCLUSIVE / EC16_LEGACY do not point at the exclusive-group / story-position items")
    ec = {num: t for _, num, _, t in items}
    if f"(Edge Case 16, D{EC16_EXCLUSIVE})" not in ec.get(6, ""):
        probs.add(area, f"Edge Case 6 does not cite '(Edge Case 16, D{EC16_EXCLUSIVE})', the exclusive-group item")
    if f"(Edge Case 16, D{EC16_LEGACY};" not in ec.get(8, ""):
        probs.add(area, f"Edge Case 8 does not cite 'Edge Case 16, D{EC16_LEGACY}', the pre-axes save item")
    if "is unsupported and does not load" not in ec.get(8, ""):
        probs.add(area, "Edge Case 8 no longer says a pre-axes save past a lock scene 'is unsupported and does not load'")
    if "holds only while no player-facing build has a save past Chapter 8" not in ec.get(8, ""):
        probs.add(area, "Edge Case 8 lost the precondition 'holds only while no player-facing build has a save past "
                        "Chapter 8' (design review round 7)")
    # Round 6 blocker 3: the over-promise guard on clean/negotiated.
    whole = norm(" ".join(lines))
    for key in NO_OVERPROMISE_KEYS:
        if key not in whole:
            probs.add("over-promise", f"storyline-axes.md lacks '{key}'")
    for bad in OVERPROMISE_STRINGS:
        if bad in whole:
            probs.add("over-promise", f"storyline-axes.md promises more than sole_dissent: '{bad}'")
    # AC9 and the composer's seats agree with the D-list and the seat vocabulary.
    if f"(D1-D{len(EC16_ITEMS)})" not in whole:
        probs.add(area, f"no acceptance criterion covers '(D1-D{len(EC16_ITEMS)})' (AC9)")
    if f"except CRISIS, for which it names D{EC16_CRISIS}" not in whole:
        probs.add(area, f"AC9 does not say the CRISIS fixture's load_check names D{EC16_CRISIS}")


REVISION7_AXES_KEYS = (  # design review round 7 (2026-11-10): the loaded argument, the seven-seats guard, AC14's baseline
    "| phase_of(record, loaded) | the Formulas' storyline_phase |",
    "called with loaded false for CRISIS and true for the others",
    "phase_of of the CRISIS fixture with loaded true is DAMAGED",
    "phase_of(record, true) is DAMAGED",
    "for WITNESS also false unless witness_seats holds seven seats",
    "seats holding six of the seven seats",
    'The baseline for "changes" is the shared variant of a scene (the one every storyline plays)',
    "The smallest number of scenes in which two distinct IDs differ is reported, with no threshold (Open Question 13)",
    "P3 baseline and the storyline cut order",
    "`loaded` is true for a record just read from a save and false for the live record in play.".replace("`", ""),
)
REVISION7_AXES_FORBIDDEN = ("for every pair of distinct IDs", "(D2)", "D2;", "(D3)")
REVISION7_LIFE_KEYS = (
    "the quest sets WITNESS_SEATS in the step that saves the seventh seat, a mirror of the record",
    "loaded false; after a load that passed the check the value is the same either way",
)


def check_revision7(gdd: list[str], life: list[str], probs: Problems) -> None:
    """Design review round 7: the loaded argument, the seven-seats guard, the D-label cleanup, AC14's baseline."""
    area = "revision 7"
    whole, life_whole = norm(" ".join(gdd)), norm(" ".join(life))
    for key in REVISION7_AXES_KEYS:
        if key not in whole:
            probs.add(area, f"storyline-axes.md lacks '{key}'")
    for bad in REVISION7_AXES_FORBIDDEN:
        if bad in whole:
            probs.add(area, f"storyline-axes.md still has '{bad}'")
    for key in REVISION7_LIFE_KEYS:
        if key not in life_whole:
            probs.add(area, f"storyline-lifecycle.md lacks '{key}'")


def check_protected(lines: list[str], root: Path, probs: Problems) -> None:
    """The axes Dependencies list every area AethelgardPrototype/AGENTS.md protects (review round 5)."""
    area = "protected"
    try:
        agents = (root / "AethelgardPrototype/AGENTS.md").read_text(encoding="utf-8")
    except (OSError, UnicodeDecodeError):
        probs.add(area, "cannot read AethelgardPrototype/AGENTS.md")
        return
    m = PROTECTED_RE.search(agents)
    if m is None:
        probs.add(area, "AGENTS.md has no 'Do not modify ... unless the prompt explicitly allows it' line")
        return

    def key(name: str) -> str:
        return re.sub(r"\s*/\s*", "/", name.strip().removeprefix("or ").strip()).lower()

    want = {key(n) for n in m[1].split(",")}
    rows = get_table(lines, H_PROTECTED, area, probs)
    named = {key(n) for _, cells in rows for n in cells[0].split(",")}
    if missing := sorted(want - named):
        probs.add(area, f"protected touchpoints table lacks {missing} (AGENTS.md protects them)")
    if extra := sorted(named - want):
        probs.add(area, f"protected touchpoints table names {extra}, which AGENTS.md does not protect")
    deps = section(lines, "## Dependencies")
    if deps is None or not any(lines[n].startswith("| protected area |") for n in range(*deps)):
        probs.add(area, "the protected touchpoints table is not in the Dependencies section")


# --- 8. Acceptance criteria ----------------------------------------------------------------------------------------
def observables(lines: list[str], header: tuple[str, ...], area: str, probs: Problems) -> set[str]:
    """The function names in an observables table's first column."""
    found: set[str] = set()
    for _, cells in get_table(lines, header, area, probs):
        found.update(re.findall(r"(\w+)\(", cells[0]))
    return found


def check_blocked_and_calls(label: str, text: str, allowed: set[str], area: str, probs: Problems) -> None:
    """One criterion names known blocking stories and calls only ``allowed`` observables."""
    m = re.search(r"\*Blocked by:\*\s*(.+)$", text)
    if m is None:
        probs.add(area, f"{label}: no '*Blocked by:*' tag")
    else:
        named = set(STORY_RE.findall(m[1]))
        if not named or named - KNOWN_STORIES:
            probs.add(area, f"{label}: blocked-by names {sorted(named)}, expected stories from {sorted(KNOWN_STORIES)}")
    for call in re.findall(r"`(\w+)\(", text):
        if call not in allowed:
            probs.add(area, f"{label}: uses '{call}()', which its Observables table does not list")


def check_axes_acs(lines: list[str], valid_rows: int, rules: dict[str, tuple[str, ...]], probs: Problems) -> None:
    """AC1-AC12 contiguous; runtime ACs name blocking stories and call only the axes observables; AC5 counts."""
    area = "acceptance"
    allowed = observables(lines, H_OBSERVABLES, area, probs)
    try:
        start = lines.index("## Acceptance Criteria")
    except ValueError:
        return
    acs: dict[int, list[str]] = {}
    current = None
    for n in range(start + 1, len(lines)):
        line = lines[n]
        if line.startswith("## "):
            break
        if m := re.match(r"^(\d+)\. ", line):
            current = int(m[1])
            acs[current] = [line]
        elif current is not None and line.startswith("   "):
            acs[current].append(line)
        else:
            current = None
    numbers = sorted(acs)
    if numbers != list(range(1, AXES_AC_COUNT + 1)):
        probs.add(area, f"acceptance criteria numbered {numbers}, expected 1-{AXES_AC_COUNT}")
    texts = {k: " ".join(v) for k, v in acs.items()}
    for number, text in sorted(texts.items()):
        if number >= FIRST_RUNTIME_AC:
            check_blocked_and_calls(f"AC {number}", text, allowed, area, probs)
    # AC5's case counts, from the axis vocabularies and the table.
    triples = (len(AUTHORITY) + 1) ** 3
    want5 = (f"({triples} triples)", f"({triples * 2} cases)", f"the {valid_rows} valid triples",
             f"the {triples - 27} triples with an UNSET axis", f"the {len(rules)} invalid triples")
    for key in want5:
        if key not in norm(texts.get(5, "")):
            probs.add(area, f"AC 5 lacks '{key}' (derived from the vocabularies and the table)")
    if f"the {len(SEED_EXPECTED)} seed flags" not in norm(texts.get(10, "")):
        probs.add(area, f"AC 10 does not say 'the {len(SEED_EXPECTED)} seed flags'")


# --- 9-14. storyline-lifecycle.md ----------------------------------------------------------------------------------
def check_life_record(life: list[str], probs: Problems) -> None:
    """The Inputs field list and the NG+ reset name only composer fields; the reset defaults follow their types."""
    area = "lifecycle record"
    bounds = section(life, "### Inputs and outputs")
    text = " ".join(life[bounds[0]:bounds[1]]) if bounds else ""
    m = re.search(r"\(fields (.+?)\)", text)
    inputs = re.findall(r"`(\w+)`", m[1]) if m else []
    if not inputs:
        probs.add(area, "Inputs and outputs names no '(fields ...)' list")
    for field in inputs:
        if field not in COMPOSER:
            probs.add(area, f"Inputs field '{field}' is not a composer record field")
    reset = next((n for n, line in enumerate(life) if line.startswith("**NG+ reset**")), None)
    if reset is None:
        probs.add(area, "no '**NG+ reset**' paragraph")
        return
    para = []
    for line in life[reset:]:
        if not line.strip():
            break
        para.append(line)
    body = " ".join(para).split(":", 1)[-1].split(". ", 1)[0]
    stated: dict[str, str] = {}
    for group in body.split(";"):
        if "→" not in group:
            continue
        names, default = group.split("→", 1)
        for field in re.findall(r"`(\w+)`", names):
            stated[field] = default.strip().rstrip(".")
    for field, default in stated.items():
        if field not in COMPOSER:
            probs.add(area, f"NG+ reset field '{field}' is not a composer record field")
            continue
        typ, allowed, _ = COMPOSER[field]
        want = ("UNSET" if field in AXES else ROOT_PHASES[0] if field == "root_phase"
                else WITNESS_MANDATES[0] if field == "witness_mandate" else "false" if typ == "bool" else "empty")
        if default != want:
            probs.add(area, f"NG+ reset {field} → '{default}', expected '{want}'")
    if set(stated) != set(inputs):
        probs.add(area, f"NG+ reset fields {sorted(stated)} != Inputs fields {sorted(inputs)}")


def check_red_lines(life: list[str], rules: dict[str, tuple[str, ...]], probs: Problems) -> None:
    """The red-line table names exactly the rules, with the pair and speaker derived from each combination."""
    area = "red lines"
    rows = get_table(life, H_RED_LINES, area, probs)
    named = [cells[2] for _, cells in rows if not is_dash(cells[2])]
    if sorted(named) != sorted(rules) or len(named) != len(set(named)):
        probs.add(area, f"red-line rules {named} != {sorted(rules)}")
    others = [cells for _, cells in rows if is_dash(cells[2])]
    if others != [["any other pair", "—", "—", "no red line"]]:
        probs.add(area, f"red-line table catch-all rows {others} != one 'any other pair | — | — | no red line'")
    for lineno, (pair, speaker, rule, value) in rows:
        if rule not in rules:
            continue
        a, f, _ = rules[rule]
        if pair != f"{a} + {f}":
            probs.add(area, f"line {lineno} ({rule}): pair '{pair}', expected '{a} + {f}' (the rule's combination)")
        if speaker != f"{f.capitalize()} delegate":
            probs.add(area, f"line {lineno} ({rule}): speaker '{speaker}', expected '{f.capitalize()} delegate'")
        if value != RED_LINE_VALUES.get(rule):
            probs.add(area, f"line {lineno} ({rule}): value voiced '{value}' differs from the pinned value")


def check_offer_table(life: list[str], rules: dict[str, tuple[str, ...]], probs: Problems) -> None:
    """The crisis offer table equals crisis_offers computed from invalid(); the deferral only on the Witness row."""
    area = "crisis offers"
    offers = crisis_offers(rules)
    witness_rule = CTX.get("route_rule", {}).get("WITNESS")
    rows = get_table(life, H_OFFERS, area, probs)
    seen = []
    for lineno, (row, cell) in rows:
        m = re.fullmatch(r"(R\d+) (\w+)-(\w+)-(\w+)", row)
        if m is None or m[1] not in rules:
            probs.add(area, f"line {lineno}: row '{row}' is not '<rule> A-F-D' for a known rule")
            continue
        rule = m[1]
        seen.append(rule)
        if (m[2], m[3], m[4]) != rules[rule]:
            probs.add(area, f"line {lineno}: {rule} combination {m[2]}-{m[3]}-{m[4]} != rules table "
                            f"{'-'.join(rules[rule])}")
        stated = re.findall(r"(?:revise|defer|invoke):[\w:]+", cell)
        revise = {o for o in stated if o.startswith("revise:")}
        if revise != offers[rule] or len(revise) != sum(o.startswith("revise:") for o in stated):
            probs.add(area, f"line {lineno} ({rule}): offers {sorted(revise)} != crisis_offers {sorted(offers[rule])}")
        defers = [o for o in stated if not o.startswith("revise:")]
        want_defer = ["defer:WITNESS"] if rule == witness_rule else []
        if defers != want_defer:
            probs.add(area, f"line {lineno} ({rule}): non-renegotiation offers {defers}, expected {want_defer}")
        if want_defer and DEFER_CONDITION.format(route="WITNESS") not in cell:
            probs.add(area, f"line {lineno} ({rule}): deferral condition is not "
                            f"'{DEFER_CONDITION.format(route='WITNESS')}'")
    if sorted(seen) != sorted(rules) or len(seen) != len(set(seen)):
        probs.add(area, f"crisis offer rows {seen} != {sorted(rules)}")
    total = sum(len(v) for v in offers.values())
    text = norm(" ".join(life))
    if f"{total} beats" not in text:
        probs.add(area, f"Retractions do not state '{total} beats' (one per renegotiation offer)")
    retractions = [cells[0] for _, cells in get_table(life, H_RETRACTIONS, area, probs)]
    if sorted(retractions) != sorted(a.capitalize() for a in AXES):
        probs.add(area, f"retraction table axes {retractions} != {[a.capitalize() for a in AXES]}")
    # Revision 5: beat ids carry the rule, so the beats are distinct; the shared-offer count is derived.
    if "beat id retract_<rule>_<axis>_<new>" not in text:
        probs.add(area, "Retractions do not name the beat id 'retract_<rule>_<axis>_<new>'")
    ids = {f"retract_{rule}_{o.split(':')[1]}_{o.split(':')[2]}" for rule, v in offers.items() for o in v}
    if len(ids) != total:
        probs.add(area, f"retract_<rule>_<axis>_<new> gives {len(ids)} ids for {total} offers")
    others = [r for r in rules if r != witness_rule]
    if len(others) == 2:
        shared = len(offers[others[0]] & offers[others[1]])
        want = f"{others[0]} and {others[1]} share {NUMBER_WORDS[shared]} offers"
        if want not in text:
            probs.add(area, f"Retractions do not say '{want}' (derived from invalid())")
    # The six gate retcon beats are exactly the Witness row's renegotiations (user Q3, 2026-11-10).
    if witness_rule in offers:
        want_retcon = {f"gate_retcon_{o.split(':')[1]}_{o.split(':')[2]}" for o in offers[witness_rule]}
        got_retcon = set(re.findall(r"gate_retcon_[a-z]+_[A-Z]+", text))
        if got_retcon != want_retcon:
            probs.add(area, f"gate retcon beats {sorted(got_retcon)} != one per {witness_rule} renegotiation "
                            f"{sorted(want_retcon)}")
        if f"({NUMBER_WORDS[len(want_retcon)]} beats:" not in text:
            probs.add(area, f"gate retcon paragraph does not say '({NUMBER_WORDS[len(want_retcon)]} beats:'")


def check_gate_table(life: list[str], gates: dict[str, str], probs: Problems) -> None:
    """Gate outcomes as pinned and derived from the axes phase table; each gated phase once; T refs match."""
    area = "gate"
    rows = get_table(life, H_GATE, area, probs)
    covered: list[str] = []
    for lineno, (phases_cell, outcome) in rows:
        phases = [p.strip() for p in phases_cell.split(",")]
        covered += phases
        token = re.match(r"[A-Z_]+", outcome)
        for phase in phases:
            if phase not in PHASES:
                probs.add(area, f"line {lineno}: '{phase}' is not a phase of storyline-axes.md")
                continue
            want = gate_outcome(gates.get(phase, ""))
            if token is None or token[0] != want:
                probs.add(area, f"line {lineno} ({phase}): outcome '{token[0] if token else outcome}', but the axes "
                                f"phase table's gate '{gates.get(phase)}' means {want}")
        if GATE_TABLE.get(phases_cell) != outcome:
            probs.add(area, f"line {lineno} ({phases_cell}): outcome '{outcome}' differs from the pinned outcome")
        for ref in re.findall(r"\((T\d+)\)", outcome):
            frm = TRANSITIONS.get(ref, ("",))[0]
            if sorted(re.findall(r"[A-Z_]{4,}", frm)) != sorted(phases):
                probs.add(area, f"line {lineno}: cites {ref}, whose from-phases are '{frm}', not {phases_cell}")
    gated = [p for p in PHASES if gate_outcome(gates.get(p, "")) is not None]
    if sorted(covered) != sorted(gated):
        probs.add(area, f"gate table covers {covered}, expected each gated phase once: {gated}")


def check_transitions(life: list[str], probs: Problems) -> None:
    """T1-T13 pinned cell by cell; phases only; no way back from a stored ID; reachability; no soft-lock."""
    area = "transitions"
    rows = get_table(life, H_TRANSITIONS, area, probs)
    ids = [cells[0] for _, cells in rows]
    if ids != list(TRANSITIONS):
        probs.add(area, f"transition ids {ids} != {list(TRANSITIONS)} in order")
    edges: list[tuple[str, str, str, str]] = []  # (id, from, to, guard)
    entry_from: list[str] = []
    order = {p: i for i, p in enumerate(PHASES)}
    for lineno, cells in rows:
        tid = cells[0]
        if tid in TRANSITIONS:
            for name, got, want in zip(H_TRANSITIONS[1:], cells[1:], TRANSITIONS[tid]):
                if got != want:
                    probs.add(area, f"line {lineno} ({tid}): {name} '{got}', pinned '{want}'")
        frm = [p for p in re.split(r"\s+or\s+|,\s*", cells[1]) if p]
        to = cells[4]
        for phase in frm + ([] if to == "unchanged" else [to]):
            if phase not in PHASES:
                probs.add(area, f"line {lineno} ({tid}): '{phase}' is not a phase of storyline-axes.md")
        for phase in frm:
            target = phase if to == "unchanged" else to
            edges.append((tid, phase, target, cells[3]))
            if phase in STORED_PHASES and target in order and order[target] < order[phase]:
                probs.add(area, f"line {lineno} ({tid}): leads back from {phase} to {target} (a stored ID never "
                                f"returns to an earlier phase)")
            if phase in STORED_PHASES and target in ("CRISIS", "DEFERRED"):
                probs.add(area, f"line {lineno} ({tid}): leads from {phase} to {target}")
        if cells[2] == GATE_EVENT:
            entry_from += frm
    # DAMAGED is never a transition's source or target: a damaged record does not load.
    for tid, frm, to, _ in edges:
        if "DAMAGED" in (frm, to):
            probs.add(area, f"{tid}: a transition touches DAMAGED (a damaged record never loads)")
    # Every phase is reachable from LEANING (except DAMAGED).
    reached, frontier = {"LEANING"}, ["LEANING"]
    while frontier:
        here = frontier.pop()
        for _, frm, to, _ in edges:
            if frm == here and to not in reached:
                reached.add(to)
                frontier.append(to)
    if missing := [p for p in PHASES if p not in reached and p != "DAMAGED"]:
        probs.add(area, f"phases unreachable from LEANING: {missing}")
    # No soft-lock (I5): each unresolved post-lock phase has a knob-free way to VALIDATED.
    for phase in ("CRISIS", "DEFERRED"):
        if not any(frm == phase and to == "VALIDATED" and "enabled" not in guard for _, frm, to, guard in edges):
            probs.add(area, f"{phase} has no transition to VALIDATED that holds under every knob value (I5)")
    # The gate runs from every phase except the one that exists only inside C8-S16 (I4), once each.
    gated = [p for p in PHASES if p not in UNGATED_PHASES]
    if sorted(entry_from) != sorted(gated):
        probs.add(area, f"'{GATE_EVENT}' transitions start from {entry_from}, expected each of {gated} once")


def check_life_formulas(life: list[str], rules: dict[str, tuple[str, ...]], probs: Problems) -> None:
    """The Formulas block is the pinned one; the offer counts sentence is derived from invalid()."""
    area = "lifecycle formulas"
    found = code_body(life, "crisis_offers(row) =")
    if found is None or tuple(found[1]) != LIFE_FORMULAS:
        body = found[1] if found else []
        diff = next((i for i, (a, b) in enumerate(zip(body, LIFE_FORMULAS)) if a != b),
                    min(len(body), len(LIFE_FORMULAS)))
        probs.add(area, f"Formulas block differs from the pinned block at its line {diff + 1}: "
                        f"'{body[diff] if diff < len(body) else '<missing>'}'")
    offers = crisis_offers(rules)
    witness_rule = CTX.get("route_rule", {}).get("WITNESS", "R1")
    others = [r for r in rules if r != witness_rule]
    c1 = len(offers.get(witness_rule, ()))
    c2 = len(offers[others[0]]) if others else 0
    total = sum(len(v) for v in offers.values())
    want = (f"|crisis_offers| is {c1} for {witness_rule} ({c1 + 1} with the deferral), {c2} for "
            f"{' and '.join(others)}, so {total} renegotiation offers in all; |last_chance_offers| is {c1} or {c1 + 1}.")
    if want not in norm(" ".join(life)):
        probs.add(area, f"offer counts sentence is not '{want}'")


def check_life_keys(life: list[str], probs: Problems) -> None:
    """Pinned lifecycle sentences; no knob table of its own."""
    area = "lifecycle rules"
    text = norm(" ".join(life))
    for key in LIFE_KEYS:
        if key not in text:
            probs.add(area, f"lacks the pinned sentence '{key}'")
    if find_table(life, KNOB_HEADER) is not None:
        probs.add(area, "has a knob table; it owns no knobs")
    for name in FORBIDDEN_KNOBS:
        if name in text:
            probs.add(area, f"names '{name}'")


def check_number_words(lines: list[str], doc: str, rules: dict[str, tuple[str, ...]], probs: Problems) -> None:
    """Every 'the <n> (R1) renegotiations/offers' phrase states the Witness row's offer count."""
    offers = crisis_offers(rules)
    witness_rule = CTX.get("route_rule", {}).get("WITNESS", "R1")
    want = NUMBER_WORDS.get(len(offers.get(witness_rule, ())))
    words = "|".join(NUMBER_WORDS.values())
    for lineno, line in enumerate(lines, 1):
        for m in re.finditer(rf"\bthe ({words}) (?:{witness_rule} )?(?:renegotiations|offers)\b", line):
            if m[1] != want:
                probs.add("counts", f"{doc} line {lineno}: '{m[0]}', but {witness_rule} has {want} offers")


def check_life_acs(life: list[str], valid_rows: int, rules: dict[str, tuple[str, ...]], probs: Problems) -> None:
    """L-AC1..n contiguous; Blocked by; only this doc's observables; derived numbers; the Validation note."""
    area = "lifecycle acceptance"
    allowed = observables(life, H_LIFE_OBSERVABLES, area, probs)
    bounds = section(life, "## Acceptance Criteria")
    if bounds is None:
        probs.add(area, "no '## Acceptance Criteria' section")
        return
    acs: dict[int, list[str]] = {}
    order: list[int] = []
    current = None
    note: list[str] = []
    in_note = False
    for n in range(*bounds):
        line = life[n]
        if line.startswith("**Validation note"):
            in_note, current = True, None
        if in_note:
            if not line.strip():
                in_note = False
            else:
                note.append(line)
            continue
        if m := re.match(r"^- \*\*L-AC(\d+) ", line):
            current = int(m[1])
            order.append(current)
            acs[current] = [line]
        elif current is not None and line.startswith("  "):
            acs[current].append(line)
        else:
            current = None
    if not order or order != list(range(1, len(order) + 1)):
        probs.add(area, f"L-ACs numbered {order}, expected 1-{len(order)}")
    texts = {k: norm(" ".join(v)) for k, v in acs.items()}
    raw = {k: " ".join(v) for k, v in acs.items()}
    for number in order:
        check_blocked_and_calls(f"L-AC{number}", raw[number], allowed, area, probs)
    # Derived numbers.
    pairs = len(AUTHORITY) * len(FACTION)
    total = sum(len(v) for v in crisis_offers(rules).values())
    storable = [p for p in PHASES if "never saved" not in PHASE_TABLE[p][0]]
    witness_rule = CTX.get("route_rule", {}).get("WITNESS", "R1")
    c1 = len(crisis_offers(rules).get(witness_rule, ()))
    derived = {3: f"each of the other {NUMBER_WORDS[pairs - len(rules)]} pairs",
               4: f"For each of the {valid_rows} valid rows", 6: f"({total} runs)",
               16: f"each storable phase ({', '.join(storable)})",
               19: f"for each of the {NUMBER_WORDS[c1]} {witness_rule} offers at LAST_CHANCE"}
    # Revision 2: the vote's arithmetic, derived from the threshold.
    met = [k for k in range(len(WITNESS_SEATS) + 1) if len(WITNESS_SEATS) - k >= WITNESS_THRESHOLD]
    derived[14] = (f"MET for {', '.join(map(str, met[:-1]))} and {met[-1]} dissenters and FAILED for {met[-1] + 1} to "
                   f"{len(WITNESS_SEATS)} ({len(WITNESS_SEATS)} − dissenters ≥ {WITNESS_THRESHOLD})")
    deferral_ids = sorted({b for _, cells in find_table(life, H_S5) or [] for b in re.findall(r"deferral_\w+",
                                                                                              " ".join(cells))})
    derived[23] = (f"the {total} retract_*, the {c1} gate_retcon_*, the {len(deferral_ids)} deferral_*")
    for number, key in derived.items():
        if key not in texts.get(number, ""):
            probs.add(area, f"L-AC{number} lacks '{key}' (derived)")
    for number, keys in LAC_KEYS.items():
        for key in keys:
            key = key.replace("{legacy}", str(EC16_LEGACY)).replace("{ec16}", str(len(EC16_ITEMS)))
            if key not in texts.get(number, ""):
                probs.add(area, f"L-AC{number} lacks the pinned phrase '{key}'")
    for number in order:
        for bad in NON_FAILING:
            if bad in texts[number]:
                probs.add(area, f"L-AC{number} asserts '{bad}', which cannot fail; assert take() false and "
                                "record_hash() unchanged")
    # L-AC7 names exactly the disclosures, and the deferral run gains exactly the S5 table's beats.
    if set(re.findall(r"\b(" + "|".join(DISCLOSURES) + r")\b", texts.get(7, ""))) != set(DISCLOSURES):
        probs.add(area, f"L-AC7 does not name the disclosures {list(DISCLOSURES)}")
    if sorted(set(re.findall(r"deferral_\w+", texts.get(7, "")))) != deferral_ids:
        probs.add(area, f"L-AC7 deferral beats {sorted(set(re.findall(r'deferral_\w+', texts.get(7, ''))))} != the "
                        f"S5 table's {deferral_ids}")
    # The Validation note: (valid rows) + (1.0 secret routes) + (offers) + (2 per 1.0 deferral route) + paths × phases.
    text = norm(" ".join(note))
    if not text:
        probs.add(area, "no Validation note")
        return
    s7_start = next((n for n, line in enumerate(life) if line.startswith("**S7")), len(life))
    s7 = []
    for line in life[s7_start:]:
        if not line.strip():
            break
        s7.append(line)
    paths = re.findall(r"`(\w+)` \(", " ".join(s7))
    if len(paths) != LIFE_REQUIRED_PATHS:
        probs.add(area, f"S7 names paths {paths}, expected {LIFE_REQUIRED_PATHS}")
    shipped = CTX.get("shipped", 0)
    # Revision 5: every R1 renegotiation is also run at LAST_CHANCE (user Q3), one per offer of the Witness row.
    # Lifecycle revision 2: the protected world_map path is blocked and not counted until its change is approved.
    counted = [p for p in paths if p != "world_map"]
    want_terms = [valid_rows, shipped, total, shipped, shipped * c1, len(counted) * len(storable)]
    terms = [int(t) for t in re.findall(r"\((\d+)\)", text)]
    if terms != want_terms:
        probs.add(area, f"Validation note terms {terms} != derived {want_terms} (valid rows, 1.0 secret routes, "
                        f"offers, gate invocations, gate renegotiations, paths × storable phases)")
    for key in ("equal the expected triple", "every run other than a gate-matrix cell ends with one story-path gate "
                "entry from its own record",
                f"which pass when the load is refused with load_errors() naming D{EC16_LEGACY} and no gate entry "
                "happens",
                f"The world_map path's {len(storable)} cells run the same way once the protected world-map change is "
                "approved; until then they are blocked and not counted."):
        if key not in text:
            probs.add(area, f"Validation note lacks '{key}'")
    m = re.search(r"(\d+) counted paths × (\d+) storable phases", text)
    if m is None or (int(m[1]), int(m[2])) != (len(counted), len(storable)):
        probs.add(area, f"Validation note gate matrix is not '{len(counted)} counted paths × {len(storable)} storable "
                        "phases'")
    m = re.search(r"— (\d+) runs", text)
    if m is None or int(m[1]) != sum(want_terms) or int(m[1]) != sum(terms):
        probs.add(area, f"Validation note total {m[1] if m else None} != {sum(want_terms)} "
                        f"(sum of its terms {sum(terms)})")


def check_life_revision2(life: list[str], root: Path, probs: Problems) -> None:
    """Lifecycle revision 2 pins: the S5 and Consent tables, the disclosures, the seats, the legacy-flag citations."""
    area = "lifecycle revision 2"
    for header, want, name in ((H_S5, S5_ROWS, "S5 deferral scope"), (H_CONSENT, CONSENT_ROWS, "Consent variants")):
        rows = [tuple(cells) for _, cells in get_table(life, header, area, probs)]
        if rows != list(want):
            diff = next((i for i, (a, b) in enumerate(zip(rows, want)) if a != b), min(len(rows), len(want)))
            probs.add(area, f"{name} table differs from the pinned table at row {diff + 1}: "
                            f"{rows[diff] if diff < len(rows) else '<missing>'}")
    text = norm(" ".join(life))
    # The disclosure paragraph names the four ids, in order, and says "four".
    para = next((norm(line) for line in [" ".join(life[n:n + 9]) for n, line in enumerate(life)
                                         if line.startswith("**Deferral disclosure")]), "")
    got = re.findall(r"\((" + "|".join(DISCLOSURES) + r")\)", para)
    if tuple(got) != DISCLOSURES:
        probs.add(area, f"Deferral disclosure ids {got} != {list(DISCLOSURES)} in order")
    if f"the offer states {NUMBER_WORDS[len(DISCLOSURES)]} things in the fiction" not in para:
        probs.add(area, f"Deferral disclosure does not say 'the offer states {NUMBER_WORDS[len(DISCLOSURES)]} things'")
    # The seats in S9 are the record's seats, in order.
    s9 = next((n for n, line in enumerate(life) if line.startswith("*Seats and stances")), None)
    seats = re.findall(r"`(\w+)`", " ".join(life[s9:s9 + 4])) if s9 is not None else []
    seats = [x for x in seats if x in WITNESS_SEATS or x == "witness_seats"]
    if [x for x in seats if x != "witness_seats"] != list(WITNESS_SEATS):
        probs.add(area, f"S9 seats {seats} != {list(WITNESS_SEATS)} (PM:8697-8703 order)")
    # Legacy flags: listed in the Dependencies row and present in the code lines it cites.
    rows = [cells for _, cells in get_table(life, ("System", "Direction", "What flows", "Status"), area, probs)
            if cells[0].startswith("Legacy storyline flags")]
    if len(rows) != 1:
        probs.add(area, "Dependencies has no single 'Legacy storyline flags' row")
        return
    cell = rows[0][2]
    for flag in LEGACY_FLAGS:
        if flag not in cell:
            probs.add(area, f"legacy flag '{flag}' is not listed in the Dependencies row")
    cited = re.findall(r"(AethelgardPrototype/[\w/]+\.gd):(\d+)-(\d+)", cell)
    if not cited:
        probs.add(area, "the legacy-flag row cites no code lines")
    covered: set[str] = set()
    for path, lo, hi in cited:
        try:
            code = (root / path).read_text(encoding="utf-8").splitlines()[int(lo) - 1:int(hi)]
        except OSError:
            probs.add(area, f"legacy-flag citation {path} cannot be read")
            continue
        joined = "\n".join(code)
        here = {f for f in LEGACY_FLAGS if f'"{f}"' in joined}
        if not here:
            probs.add(area, f"{path}:{lo}-{hi} holds none of the legacy flags")
        covered |= here
    if missing := [f for f in LEGACY_FLAGS if f not in covered]:
        probs.add(area, f"legacy flags {missing} occur in none of the cited code lines")
    if "the stand-down line (line id stand_down_line" not in text:
        probs.add(area, "S8 does not define the line id stand_down_line")


# --- 15. Story Bible and stale strings ------------------------------------------------------------------------------
def check_bible(bible_lines: list[str], probs: Problems) -> None:
    """The Story Bible holds the dated S06a decision line."""
    if not any(line.startswith(BIBLE_DECISION_PREFIX) for line in bible_lines):
        probs.add("story bible", f"no line starting '{BIBLE_DECISION_PREFIX}'")


def check_stale(lines: list[str], doc: str, probs: Problems, exempt_section: str | None = None,
                exempt_strings: frozenset[str] = frozenset()) -> None:
    """No stale string or revision-3 vocabulary, except revision-3 vocabulary inside ``exempt_section``."""
    bounds = section(lines, exempt_section) if exempt_section else None
    for lineno, line in enumerate(lines, 1):
        for stale in STALE_STRINGS:
            if stale not in exempt_strings and stale in line:
                probs.add("stale", f"{doc} line {lineno}: stale string '{stale}' present")
        if bounds and bounds[0] <= lineno - 1 < bounds[1]:
            continue
        for word in STALE_VOCAB:
            if word in line:
                probs.add("stale", f"{doc} line {lineno}: revision-3 vocabulary '{word}' present")


def main(argv: list[str] | None = None) -> int:
    """Run every check and print the problems and the RESULT line; return the exit code."""
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument("--gdd", type=Path, default=REPO_ROOT / "design/gdd/storyline-axes.md")
    parser.add_argument("--lifecycle", type=Path, default=REPO_ROOT / "design/gdd/storyline-lifecycle.md")
    parser.add_argument("--bible", type=Path, default=REPO_ROOT / "AethelgardPrototype/story/STORY_BIBLE.md")
    parser.add_argument("--root", type=Path, default=REPO_ROOT)
    args = parser.parse_args(argv)
    if hasattr(sys.stdout, "reconfigure"):
        sys.stdout.reconfigure(encoding="utf-8")
    try:
        gdd = read_lines(args.gdd)
        life = read_lines(args.lifecycle)
        bible = read_lines(args.bible)
        game_text = load_game_text(args.root)
    except (OSError, UnicodeDecodeError) as exc:
        print(f"ERROR: cannot read input: {exc}")
        return 2
    print(f"gdd:       {args.gdd}\nlifecycle: {args.lifecycle}\nbible:     {args.bible}\nroot:      {args.root}")
    probs = Problems()
    src = SourceResolver(args.root)
    if src.pm() is None:
        print(f"ERROR: cannot read input: {args.root / PM_PATH}")
        return 2
    CTX.clear()
    # storyline-axes.md
    check_headings(gdd, "headings", probs)
    rules, valid_rows = check_combinations(gdd, src, probs)
    check_secrets(gdd, src, rules, valid_rows, probs)
    check_seed_map(gdd, game_text, src, probs)
    check_side_arcs(gdd, src, probs)
    check_composer(gdd, probs)
    check_formulas(gdd, rules, probs)
    check_maps(gdd, rules, probs)
    check_counts(gdd, rules, valid_rows, probs)
    check_core_rules(gdd, rules, probs)
    check_invariants(gdd, probs)
    gates = check_phases(gdd, probs)
    check_knobs(gdd, probs)
    check_axes_edge_cases(gdd, probs)
    check_revision7(gdd, life, probs)
    check_protected(gdd, args.root, probs)
    check_axes_acs(gdd, valid_rows, rules, probs)
    check_number_words(gdd, "axes", rules, probs)
    # storyline-lifecycle.md
    check_headings(life, "lifecycle headings", probs)
    check_life_record(life, probs)
    check_red_lines(life, rules, probs)
    check_offer_table(life, rules, probs)
    check_gate_table(life, gates, probs)
    check_transitions(life, probs)
    check_life_formulas(life, rules, probs)
    check_life_keys(life, probs)
    check_edge_cases(life, LIFE_EDGE_CASES, "lifecycle edge cases", probs)
    check_life_acs(life, valid_rows, rules, probs)
    check_life_revision2(life, args.root, probs)
    check_number_words(life, "lifecycle", rules, probs)
    # both
    check_bible(bible, probs)
    check_stale(gdd, "axes", probs, exempt_section="## Open Questions")
    check_stale(life, "lifecycle", probs, exempt_strings=STALE_LIFECYCLE_EXEMPT)
    for item in probs.items:
        print(f"FAIL {item}")
    n = len(probs.items)
    print(f"RESULT: {'PASS' if n == 0 else 'FAIL'} ({n} problems)")
    return 0 if n == 0 else 1


if __name__ == "__main__":
    sys.exit(main())
