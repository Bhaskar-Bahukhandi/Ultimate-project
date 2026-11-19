"""Document checker for the storyline GDDs (story Y1-P0-S06a, AC-7): storyline-axes.md AC1-AC4 and the
document-level criteria of storyline-lifecycle.md (axes revision 9 / lifecycle revision 5, design review round 9,
user decisions 2026-11-11: Witness Protocol moved post-1.0 with the other two secret routes, so the deferral,
invocation, witness vote, stand-down and Consent variants are gone; invariant I9, one atomic checkpoint per
transition; transitions T1-T9; Edge Case 16 with D2-D5 and D10-D13 retired and D17 added; AC16). Synced to axes
revision 12 / lifecycle revision 8 (design review round 12, user decisions 2026-11-17): a seed flag may have one
modifier row and one axis row (26 flags in 28 rows; the Authority remap), Kaelthas outside the 1.0 companion set,
D0 owning the one-entry retraction_log cap (D7.multi and D7.duplicate retired), D15 scoped to the save's schema
version, the Terms story-position list equal to the reference model's POSITIONS, legacy defaulting, chapter select,
the gate predicate, L-AC19, and AC9/AC11/AC14-AC17 rewritten (check_revision12 and the pins marked "Revision 12").
Synced to axes revision 15 (erratum) / lifecycle revision 11 (lifecycle review 2026-11-18, 13 blockers; scope frozen
by lifecycle Open Question 7): the composer's kaelen_commitment and its D0 clause, the NG+ reset against every stored
composer field, and check_revision15 (the chapter-select table against main_menu.gd's 13 Chapter 8-10 entries, the
scene placement table against the scene files, the position writers against the model's POSITIONS, the window table
against the checkpoint transitions, the turn-back landings, take() through the T5 handler, the commitment values
against PM:7055-7057, and an observables lint: every call in an L-AC, backticked or not, is in the Observables
table, and prose that names an observable — story position, region locked, saves written, C9-S18's form, scenes
played, a data error — comes with its call).

This is document lint: it proves that the text matches constants pinned here (or values derived here from other
parts of the text), not that the state machine is correct. The reference model that would show the latter is
storyline-axes.md Open Question 16.

Parses ``design/gdd/storyline-axes.md``, ``design/gdd/storyline-lifecycle.md``, the Story Bible and the production
master, and reports every structural problem it finds. It pins *bodies*, not only names:

storyline-axes.md
1. the 8 required H2 headings in order (other H2s: Summary, Cross-References, Open Questions only);
2. the 27-row combination table, the rules table (each quoted contradiction on its cited line), the Formulas'
   ``invalid()`` set and shape, the ``valid_count:`` / family-split statements and the Counts block (values derived
   here, including ``renegotiation_offers`` computed from ``invalid()`` per rule);
3. the secret table (every route post-1.0, family reserved), the ``secret_prerequisites`` / ``secret_unlock_flag``
   knobs against the production master's "Required flag" lists, ``reachable_1_0``, ``transform()`` and both family
   maps; ``family()`` maps all three secret ids to RESERVED and never returns CONSENT;
4. the Act 1 seed map and the side-storyline table;
5. the composer record: exactly the AC3 fields (and AC3's own list), each with its pinned type, allowed values
   (derived where possible) and writer;
6. the formula bodies of ``storyline_id``, ``prereqs_met``, ``lock_pass``, ``storyline_phase`` and ``family``, the
   ``lock_pass`` and ``storyline_phase`` examples re-computed here, and the results each body can return;
7. Core Rules 1-12 with titles and pinned key sentences (some derived from the rules table), no modal verb in
   Rules 7 and 9, the invariants table I1-I9, the phase table, the Tuning Knobs table (exactly four knobs, every
   enable default false as the secret table's scopes give), Edge Case numbering and Edge Case 16's item list
   (active and retired entries, cross-references derived);
8. the acceptance criteria: AC1-AC17 contiguous, each runtime AC names its pinned blocking stories and calls only
   the pinned Observables table; AC5's case counts derived; AC9's active-item list derived from Edge Case 16;
storyline-lifecycle.md
9. headings; the Inputs field list (= the fields the axes doc says the record stores) and the NG+ reset (fields and
   defaults derived from the composer record);
10. the red-line table (exactly R1-R3, pairs and speakers derived from the rules table), the crisis offer table
    (= ``crisis_offers`` computed from ``invalid()``, no secret-route offer on any row), the retraction table's axes
    and beat count, the content-scope counts;
11. the gate outcome table (outcomes derived from the axes phase table, T references matching the transitions);
12. transitions T1-T9 pinned cell by cell, phases only from the axes phase table, no transition back from a stored
    ID, every phase reachable, no soft-lock, the gate on every gated phase; the checkpoint set (I9) equal in the
    table, the commit and save rule and L-AC6;
13. the Formulas block, its offer counts, the no-knob Tuning Knobs section, pinned scene sentences; S5's unlock
    flags and Edge Case 5's Witness leads derived from the axes knobs;
14. L-AC1-L-AC19 contiguous, each with known blocking stories and only the pinned observables; derived numbers and
    key phrases; L-AC2's lock-pass fixtures recomputed; the Validation note's run arithmetic and pass rule;
both
15. the dated decision line in the Story Bible; no stale strings, revision-3 vocabulary or revision-8 secret-route
    identifiers; every "I1-In" names the invariant count; each doc's Dependencies row names the other's revision;
16. the over-promise guard on clean/negotiated and the legacy storyline flags against the code lines the lifecycle
    cites; the forbidden non-failing assertions.

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
# Revision 12 (user decision 2026-11-17, design review round 12): Kaelthas is outside the 1.0 companion set.
COMPANION_ORDER = ("Elara", "Seraphina", "Lyra")
COMPANIONS = frozenset(COMPANION_ORDER)
# Companions each ending family requires. Story Bible §5: no family needs one. (Revision 9: no CONSENT in 1.0.)
FAMILY_NEEDS: dict[str, frozenset[str]] = {
    "SOLE": frozenset(), "BOUND": frozenset(), "NONE_AUTH": frozenset(),
}
DASHES = ("—", "-", "–")
NUMBER_WORDS = {1: "one", 2: "two", 3: "three", 4: "four", 5: "five", 6: "six", 7: "seven", 8: "eight", 9: "nine",
                10: "ten"}

SECRET_ROUTES = ("WITNESS", "FIRSTWAKE", "CROWNLESS")
SECRET_EXPECTED = {  # id -> (family cell, scope). Revision 9 (user, 2026-11-11): all three post-1.0, family reserved.
    "SL-SECRET-WITNESS": ("— (reserved; CONSENT when designed)", "post-1.0"),
    "SL-SECRET-FIRSTWAKE": ("— (reserved)", "post-1.0"),
    "SL-SECRET-CROWNLESS": ("— (reserved)", "post-1.0"),
}
# PRODUCTION_MASTER_2.1.md:8784, canonical association of secret route and the invalid row it transforms.
SECRET_FOUNDATION = {"WITNESS": "YHR", "CROWNLESS": "NAL", "FIRSTWAKE": "NCL"}

# Story S06a, Audit 4 (23 flags) plus the three Aldric-kill flags: 26 flags, each row with its approved
# (pushes, direction). A change here is a design decision. Revision 12 (user decision 2026-11-17, design review
# round 12): a flag may have one modifier row and one axis row, never two axis rows; ch1_aldric_kill_justified
# argues against YOU, ch2_seraphina_showoff (against YOU) and ch2_seraphina_truth (for SHARED) gain axis rows.
# lock_pass matches a row by (flag, pushes), so a modifier row never enters it. 26 flags in 28 rows.
# Revision 13 (user decision 2026-11-17, design review round 13): ch1_root_purge argues against YOU (not for HEARTH).
SEED_ROWS: tuple[tuple[str, str, str], ...] = (
    ("act1_report_local", "faction:HEARTH", "+"),
    ("act1_report_archive", "faction:ARCHIVE", "+"),
    ("act1_report_command", "faction:CONTINUITY", "+"),
    ("ch2_seraphina_truth", "modifier:seraphina_relationship", "+"),
    ("ch2_seraphina_truth", "authority:SHARED", "+"),
    ("ch2_seraphina_cautious", "modifier:seraphina_relationship", "0"),
    ("ch2_seraphina_showoff", "modifier:seraphina_relationship", "−"),
    ("ch2_seraphina_showoff", "authority:YOU", "−"),
    ("ch2_seraphina_recruited", "modifier:companions_present", "+"),
    ("ch2_seraphina_stayed", "modifier:companions_present", "−"),
    ("ch2_seraphina_rejected", "modifier:companions_present", "−"),
    ("ch2_data_wraith_restored", "deleted:RESTORE", "+"),
    ("ch2_data_wraith_destroyed", "deleted:RELEASE", "+"),
    ("ch2_data_wraith_absorbed", "deleted:CHOOSE", "+"),
    ("ch1_knight_killed", "faction:HEARTH", "−"),
    ("ch1_knight_spared", "modifier:aldric_restrained", "+"),
    ("ch1_root_purge", "authority:YOU", "−"),  # revision 13 (round 13): was faction:HEARTH +
    ("ch1_aldric_kill_owned", "authority:YOU", "+"),
    ("ch1_aldric_kill_justified", "authority:YOU", "−"),
    ("ch1_aldric_kill_unsure", "authority:SHARED", "+"),
    ("ch1_root_first_edit", "authority:YOU", "+"),
    ("ch1_root_discovered_unused", "authority:NONE", "+"),
    ("ch1_oakhaven_warned_villagers", "modifier:A1-OAK-SAVED", "+"),
    ("ch1_oakhaven_warned_leaders", "modifier:A1-OAK-SAVED", "+"),
    ("ch1_oakhaven_left_quietly", "modifier:A1-OAK-QUIET", "+"),
    ("act1_pace_early", "timing", "0"),
    ("act1_pace_on_time", "timing", "0"),
    ("act1_pace_late", "timing", "0"),
)
SEED_FLAGS = frozenset(flag for flag, _, _ in SEED_ROWS)
SEED_FLAG_COUNT = len(SEED_FLAGS)  # 26 (AC2, AC10, the seed map intro)
LEAN_DIRECTIONS = ("+", "−", "-")  # "−" is U+2212; ASCII hyphen accepted as the same sign.
NEUTRAL = "0"
DIRECTIONS = (*LEAN_DIRECTIONS, NEUTRAL)
OVERTURNABLE = ("no", "until:lock:faction", "until:lock:authority", "until:lock:deleted")

SIDE_ARCS = tuple(f"{n:02d}" for n in range(1, 13))
POST_1_0_ARCS = ("05", "08", "09")
FEEDS_POST_1_0 = "1.0 (feeds post-1.0)"  # revision 11 (round 11): these arcs ship in 1.0 with epilogue lines
SCOPES = ("1.0", "post-1.0", FEEDS_POST_1_0)

# --- Revision 4 (design review round 4): the static core and its invariants. A change is a design decision. -----
# Revision 9: DEFERRED is gone (no deferral in 1.0).
PHASES = ("LEANING", "PARTLY_LOCKED", "CRISIS", "VALIDATED", "FIXED", "FINAL", "DAMAGED")
# Phases no gate runs from and no transition reaches: CRISIS exists only inside C8-S16, DAMAGED is never loaded.
UNGATED_PHASES = ("CRISIS", "DAMAGED")
PHASE_TABLE = {  # phase -> (meaning, gate), backticks removed
    "LEANING": ("every axis UNSET", "turns the player back"),
    "PARTLY_LOCKED": ("one or two axes locked", "turns the player back"),
    "CRISIS": ("three axes locked on an invalid row, nothing stored: exists only inside C8-S16, never saved",
               "— (inside C8-S16)"),
    "VALIDATED": ("an ID stored, root_phase OUTSIDE", "open"),
    "FIXED": ("an ID stored, root_phase INSIDE (first entered Root of Heaven; stays INSIDE if the player leaves)",
              "open (re-entry)"),
    "FINAL": ("the final authorization concluded: execution confirmed", "open (Story+)"),
    "DAMAGED": ("the record holds an item of Edge Case 16: never saved by play; a load that yields it is refused",
                "a loaded record never reaches the gate; a live one is turned back as a data error with a reload "
                "prompt (lifecycle S6)"),
}
# The gate outcome each axes-doc gate phrase means in the lifecycle doc's gate table.
GATE_OUTCOME = {"turns the player back": "TURNED_BACK"}
# Revision 10 (design review round 10, reference model F9): a live DAMAGED record at the gate is turned back as a data
# error (defence in depth). The lifecycle gate table lists it as "DAMAGED (a live record)"; no transition fires.
LIVE_GATED = {"DAMAGED": "a live one is turned back"}
LIVE_QUALIFIER = " (a live record)"
# Revision 9: the 1.0 families. CONSENT is post-1.0 and must not be a value family() can return.
FAMILIES = frozenset(FAMILY_BY_AUTHORITY.values())
POST_1_0_FAMILY = "CONSENT"
ID_FAMILY_EXTRA = frozenset({"RESERVED", "NO_FAMILY"})
LOCK_SCENE = {"faction": "C8-S13", "authority": "C8-S14", "deleted": "C8-S16"}
ROOT_PHASES = ("OUTSIDE", "INSIDE", "FINAL")
# The storyline_phase signature (Formulas), the composer writer and the Observables row all use it.
PHASE_SIGNATURE = "storyline_phase(record, loaded, flags, position)"
DAMAGED_SIGNATURE = "damaged(record, loaded, flags, position)"

# Composer record (GDD AC3): field -> (type, allowed, writer). ``allowed`` is a frozenset (compared as a set of
# comma-separated values) or a str (compared exactly). Derived values come from the vocabularies above.
# Revision 9: witness_deferred, secret_invoked, witness_seats, witness_dissenters and witness_mandate are removed.
COMPOSER: dict[str, tuple[str, frozenset[str] | str, str]] = {
    "storyline_phase": ("enum", frozenset(PHASES), f"derived: {PHASE_SIGNATURE} (Formulas); never stored"),
    "storyline_id": ("string", "a storyline ID, or empty while nothing is stored",
                     "C8-S16 on a valid row; a renegotiation at C8-S16; nothing else"),
    "root_phase": ("enum", frozenset(ROOT_PHASES),
                   "the gate check on entry with an ID stored (INSIDE); the final authorization concluding by "
                   "confirmed execution (FINAL)"),
    **{axis: ("enum", frozenset({UNSET, *values}), f"{LOCK_SCENE[axis]} lock; a renegotiation. Never the final "
                                                    "authorization") for axis, values in AXES.items()},
    "secret_route": ("enum", frozenset({"NO_SECRET", *SECRET_ROUTES}),
                     "derived from storyline_id (SL-SECRET-T → T, else NO_SECRET); never stored"),
    "family": ("enum", FAMILIES | ID_FAMILY_EXTRA, "derived: family(storyline_id); never stored"),
    "axis_revised": ("set", frozenset(AXES), "a renegotiation"),
    "lock_negotiated": ("set", frozenset(AXES), "the lock scenes by lock_pass; every renegotiation"),
    # Revision 5 (lifecycle review round 1): the retractions and beats are saved, not derived.
    "retraction_log": ("list", "at most one entry {axis, old, new, withdrawn_item, scene}; withdrawn_item and scene "
                       "are opaque display text that no code branches on", "every renegotiation"),
    "beats_played": ("set", "the lifecycle's authored beat ids (retract_*)", "the scene that plays the beat"),
    # Revision 15 (erratum after the lifecycle review of 2026-11-18, user decision 2026-11-19): the commitment
    # SOVEREIGN quotes (PM:7054-7059) is stored; its UNSET rule is D0's.
    "kaelen_commitment": ("enum", "UNSET, LISTEN, OVERRIDE_IMMEDIATE_LOSS, CANNOT_PROMISE_NEVER (PM:7054-7058); UNSET "
                          "exactly when the record never held YOU (Authority is not YOU and no retraction_log entry "
                          "has old YOU)",
                          "C8-S14 when YOU is backed; a renegotiation to YOU at C8-S16; UNSET from a new game, the NG+ "
                          "reset and chapter select (user decision 2026-11-19)"),
    # Revision 14 (round 14): the story position is a record field, so D0 covers a missing or unlisted one.
    "story_position": ("enum", "the story position ids of Terms (Story position), PRE_C8 to ROOT_STORY_PLUS",
                       "each commit checkpoint and story-graph step that crosses into the next id; a new game, the "
                       "NG+ reset and chapter select; SaveService once for a legacy save (Terms)"),
    "companions_present": ("set", COMPANIONS,
                           "AethelgardPrototype/scripts/game_manager.gd (has_elara, exclusive flag groups); "
                           "AethelgardPrototype/dialogue/ch2/fragment_two.dlg"),
    "regions_completed": ("set", "ids of the eight regions", "owner story Y2-PP-T17 (no writer in the code today)"),
    "timing_flags": ("set of flags", "ch1_bridge_saved / _evacuated / _fell, ch2_medicine_early / _on_time / _late",
                     "AethelgardPrototype/dialogue/ch1/north_field.dlg; AethelgardPrototype/dialogue/ch2/act1_end.dlg"),
    # Revision 14 (round 14): act1_pace defaults to UNSET, so D0 accepts a save made before the end of Act 1.
    "act1_pace": ("enum", frozenset({UNSET} | {f for f, push, _ in SEED_ROWS if push == "timing"}),
                  "AethelgardPrototype/dialogue/ch2/act1_end.dlg (UNSET until it plays)"),
    "act2_pace, act3_pace, act4_pace": ("enum", "UNSET and the names S06b defines", "owner story Y1-P0-S06b"),
}

CORE_RULE_TITLES = (
    "Three axes, one value each.", "Seeds are arguments, never gates.", "Lock scenes resolve, clean or negotiated.",
    "Red lines (new content), as values.", "An invalid combination is a political crisis, resolved at C8-S16.",
    "Secret routes are reserved (post-1.0).", "A valid row is held to its word.",
    "Storyline ID and the ID-lock gate.", "Final authorization.", "Ending family",
    "Companions are independent of the axes.", "Timing is a modifier.")
# Key sentences per Core Rule (normalized: backticks and ** removed, whitespace collapsed). Rules 4 and 5 also get
# sentences derived from the rules table in check_core_rules. Revision 9 rewrote Rules 5-10 around the post-1.0
# secret routes: the deferral, invocation, witness vote and stand-down sentences are gone; the replacements below
# pin the property each guarded (no secret-route offer, routes closed, family reserved).
CORE_RULE_KEYS: dict[int, tuple[str, ...]] = {
    1: ("each starts UNSET", "Once a storyline ID is stored, each axis holds exactly one value"),
    2: ("Every lock scene always offers all three values; no seed adds or removes an option.",
        "No seed sets a value; only a lock scene or a renegotiation does", "The sources define no axis score."),
    3: ("A lock vote always passes for the proposal the player backs",
        "clean when at least one seed for the backed value is set with direction + and none with direction −; "
        "otherwise negotiated, and lock_negotiated_<axis> is set",
        "The test reads only which flags are set: no count, no weight.", "it never changes a value or the ID.",
        "The composer input record is authoritative: these flags, axis_revised_<axis>, lock_negotiated_<axis> are "
        "mirrors, written in the same step as the record field, never read in its place and cleared with it.",
        "on a SOLE storyline whose lock_negotiated holds authority, the ending plays sole_dissent",
        "Nothing else in 1.0 reads lock_negotiated (no scene variant, ally line or slide)"),
    4: ("states its red line as a value, never as a combination",
        "No other pair voices a red line, C8-S13 and C8-S14 voice none, and there is no system warning."),
    5: ("the scene does not end until the coalition holds",
        "(the Faction swap between R2 and R3 would break the coalition again and is not offered)",
        "Each is voiced as the refusing faction's demand, except a Faction offer, which is voiced as that faction "
        "stepping down and staying",
        "is post-1.0: no secret-route offer exists in 1.0 (Core Rule 6)."),
    6: ("together, in that order, they are the production master's \"Required flag\" list for T",
        "All three routes — Witness Protocol, Crownless, First Wake — are disabled in 1.0 (user decision 2026-11-11",
        "While T is disabled: its invalid row can only be renegotiated at C8-S16; the journal shows no signpost or "
        "hint for it; its invocation scene does not unlock it",
        "and its unlock flag is never set",
        "plays only when the stored ID is SL-SECRET-T, which no 1.0 record holds",
        "the prerequisite flags that content sets are kept and transform nothing.",
        "When the routes ship they are designed together as one mechanism"),
    7: ("nothing offers a renegotiation, and the ID never changes.",),
    8: ("Before that nothing is stored.", "A stored ID is never recomputed from flags or knobs",
        "Every entry and re-entry into Root of Heaven runs the gate check",
        "before the three locks it turns the player back in the fiction",
        "is unsupported and does not load (Edge Case 16, D{legacy}; user decision 2026-11-10); no runtime catch-up "
        "exists.",
        # Revision 10 (round 10, F5/F7/F10): the promise is every save that play writes, not every loaded state.
        "In 1.0 that turn-back is defence in depth",
        "Every save that play writes loads (I9)",
        # Revision 11 (round 11, Open Question 17): one inclusion rule, never edited-save integrity.
        "What the check refuses follows one inclusion rule (Edge Case 16",
        "it never promises edited-save integrity, only that no accepted record crashes the composer, strands the "
        "player or breaks an invariant",
        "The refusal holds only while no player-facing build has such saves",
        # Revision 12 (round 12): the gate opens on a stored ID only when the phase is not DAMAGED.
        "with an ID stored and the phase not DAMAGED the gate is open (also after the boss and in Story+)",
        "a DAMAGED record is turned back as a data error whether or not it holds an ID (lifecycle S6)"),
    9: ("It changes no axis and no ID.", "this design offers none", "and the player confirms execution."),
    10: ("the secret storylines' families are reserved until their routes ship",
         "Consent (post-1.0): seven affected witnesses authorize one irreversible act",
         "Its rules are designed with the secret routes (Open Question 15)",
         "Faction and Deleted are modifiers"),
    # Revision 12 (round 12): Kaelthas is outside the 1.0 companion set; the round-11 trust condition is superseded.
    # The companion-set sentence is derived from COMPANION_ORDER in check_core_rules.
    11: ("a companion leaves through relationship flags (Edge Case 1), never through an axis, and no axis is read for "
         "presence.",
         "Kaelthas is not in it: Chapter 3 always ends his alliance in betrayal",
         "is reserved for redemption content (Open Question 19; user decision 2026-11-17, design review round 12, "
         "superseding the trust condition ch3_kaelthas_allied set and ch3_kaelthas_betrayed unset decided in round 11)",
         "Kaelthas's own Chapter 9 and 10 lines, which read ch3_kaelthas_allied, are unaffected."),
    12: ("change scenes, NPC fates, market events and ending slides through the composer, not the storyline ID",),
}
NO_MODAL_RULES = (7, 9)  # these rules forbid; a "may/can/could" in them is an exception being smuggled in
MODAL_RE = re.compile(r"\b(may|can|could|might)\b", re.IGNORECASE)

INVARIANTS = {  # id -> (invariant, rules), backticks removed
    "I1": ("Axis values come only from lock scenes and renegotiations; never from seeds, flags, knobs or the final "
           "authorization", "2, 3, 5, 9"),
    "I2": ("No crisis outlasts C8-S16", "5"),
    "I3": ("The ID is stored the moment the coalition holds, is never recomputed, and never changes once stored",
           "7, 8"),
    "I4": ("Every entry and re-entry into Root of Heaven runs the gate check, on every path", "8"),
    # Revision 11 (round 11, Open Question 18): a DAMAGED record refused at the gate is named.
    "I5": ("No soft-lock under any knob value or patch: every state without a stored ID either is before the locks, "
           "offers a renegotiation that reaches a valid row, or is a data error refused at the gate (a DAMAGED record, "
           "which play never writes)", "5, 8"),
    "I6": ("Nothing important is lost silently: no hint points at an unshipped route; arcs "
           f"{', '.join(POST_1_0_ARCS)} get a visible epilogue line in 1.0", "6"),
    "I7": ("A valid row is held to its word", "7"),
    "I8": ("Family = the Authority value; a secret storyline's family is RESERVED until its route ships", "10"),
    # Revision 9 (design review round 9): one atomic checkpoint per transition.
    "I9": ("Every transition commits its record writes and its beat id as one atomic checkpoint; no save exists "
           "inside a lock scene, the crisis or the final authorization before its commit", "3, 5, 8, 9"),
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
STORYLINE_PHASE_BODY = (  # revision 6: damaged-first; revision 7: loaded; revision 9: flags, position, no DEFERRED
    f"{PHASE_SIGNATURE}:",
    f"if {DAMAGED_SIGNATURE} → DAMAGED",
    "if storyline_id is stored and root_phase is FINAL → FINAL",
    "if storyline_id is stored and root_phase is INSIDE → FIXED",
    "if storyline_id is stored → VALIDATED",
    "if A, F and D are all UNSET → LEANING",
    "if A, F or D is UNSET → PARTLY_LOCKED",
    "otherwise → CRISIS",
)
FAMILY_BODY = (  # revision 9: all three secret ids are RESERVED; no CONSENT
    "family(id):",
    "SL-SECRET-WITNESS, SL-SECRET-CROWNLESS, SL-SECRET-FIRSTWAKE → RESERVED (unreachable while their routes are "
    "disabled)",
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

# Edge Case 16 entries (normalized, backticks removed): (first D-number, last D-number, text). Revision 9 retired
# D2-D5 and D10-D13 as single entries, so the numbering stays stable for every cross-reference. The D-numbers are
# cited from Core Rule 8, Edge Cases 6 and 8, AC9 and the lifecycle; the derived checks below catch a renumbering.
EC16_RETIRED_PREFIX = "retired (revision 9):"
EC16_ENTRIES = (
    # Revision 11 (round 11, Open Question 17): D0, the shape check, tested first.
    # Revision 13 (round 13): beats_played capped at one; D0 type-checks storyline_id and beats_played only, so it no
    # longer shadows D14's undefined-beat clause.
    # Revision 12 (round 12): D0 owns the one-entry retraction_log cap and refuses a set holding an element twice; a
    # missing field is D0 only for a current-schema save (an older one is defaulted first, Edge Case 8).
    # Revision 14 (round 14): D0 and D1 name their clause ids (AC9's clause-id list).
    (0, 0, "a record whose shape is wrong: a field missing from a save of the current schema version, or a legacy "
           "save left with no story position (an older save is defaulted first, Edge Case 8) (D0.missing), a field of "
           "the wrong type (D0.type), an enum string outside its allowed values (D0.enum), a set or list element of the "
           "wrong type (D0.element), a set holding one element twice (D0.duplicate), or a set or list longer than its "
           "maximum (D0.max; retraction_log one entry: play takes at most one renegotiation, Core Rule 7, and a second "
           "entry would play a cost beat twice; beats_played one, the one entry's beat). Allowed values are checked for "
           "every field the composer record gives a closed list of values (and retraction_log's axis, old and new), "
           "except storyline_id and beats_played, which are checked for type only: which strings they may hold is D1's "
           "and D14's (its undefined-beat clause). kaelen_commitment is also outside its allowed values (D0.enum) "
           "when it is UNSET on a record that held YOU (Authority YOU, or a retraction_log entry with old YOU) or set "
           "on one that never did: play writes it exactly when SOVEREIGN can quote it (lifecycle S2; user decision "
           "2026-11-19). D0 is tested first; when it fires no other item runs, so load_check "
           "reports only D0 clauses and its items are exactly {D0}. It exists so that no later item and no composer "
           "read meets a value of the wrong type or count; it is not an integrity check"),
    (1, 1, "a stored ID that is not SL-A-F-D for its axes on a valid row, tested in this order and reported as the "
           "first clause that holds: any SL-SECRET-* ID (D1.secret; no 1.0 play stores one), an ID with an UNSET axis "
           "(D1.unset_axis), an ID while the record's axes form an invalid row (D1.invalid_row), or any other ID "
           "(D1.other_id, which includes an invalid row's ID stored on a valid row)"),
    (2, 5, "retired (revision 9): they checked the Witness record fields, which 1.0 no longer stores"),
    (6, 6, "axis_revised holding an axis that lock_negotiated lacks"),
    # Revision 10 (round 10, F6): D7 also runs the other way (the composer reads axis_revised).
    # Revision 11 (round 11): clause ids, and the duplicate-entry clause.
    # Revision 12 (round 12): D7.multi and D7.duplicate retired (D0 refuses a second entry first).
    (7, 7, "axis_revised holding an axis that no retraction_log entry names (D7.unnamed), or a retraction_log entry "
           "whose axis is not in axis_revised (D7.reverse; the composer reads axis_revised), or a retraction_log entry "
           "whose new value is not the record's value for its axis (D7.new_mismatch). The clauses D7.multi and "
           "D7.duplicate of revision 11 are retired (design review round 12): D0 refuses a second entry, so neither "
           "could fire, and the revision-11 reason given for D7.multi was false: (NONE, HEARTH, RELEASE) admits two "
           "consistent Faction retractions, from R2 (ARCHIVE→HEARTH) and from R3 (CONTINUITY→HEARTH), which is now a "
           "D0 fixture (AC9)"),
    (8, 8, "root_phase INSIDE or FINAL with nothing stored"),
    (9, 9, "three axes set with nothing stored *(not for the live crisis)*"),
    (10, 13, "retired (revision 9): they checked the witness vote fields"),
    # Revision 10 (round 10, F4): 'matching' is defined, so a changed entry value is also a beat mismatch.
    (14, 14, "a retract_* beat in beats_played with no matching retraction_log entry, or a retraction_log entry whose "
             "beat is not in beats_played, or a beat id the lifecycle does not define. A beat matches an entry "
             "exactly when its id is retract_<rule>_<axis>_<new>, rebuilt from the entry (rule is the invalid row "
             "R1-R3 that the record's axes form with the entry's axis set back to old)"),
    # Revision 12 (round 12): D15 is scoped to the groups at the save's schema version; D16 cites Terms.
    (15, 15, "two flags of one exclusive group, as the groups stood at the save's schema version (Edge Case 6): a "
             "group added or widened by a later patch never refuses an older save (inclusion rule (ii) and (iii); Open "
             "Question 5's ch1_oakhaven_warned_leaders is the known case)"),
    (16, 16, "a story position (Terms) past the lock scene of an UNSET axis (a save made past Chapter 8 before these "
             "fields existed; unsupported, user decision 2026-11-10)"),
    # Revision 8 (design review round 8), clarified in revision 9: out-of-order lock sets are damaged.
    # Revision 10 (round 10, F1/F3): clause (a) is load-only (the live crisis is set before its commit); clause (b) is
    # implied for a loaded record, so it is documentation with no fixture of its own.
    (17, 17, "a lock-order defect, in two clauses. (a) *Before commit (not for the live crisis):* an axis is set while the story "
             "position is before its lock scene's commit: no lock scene could play from it (S1 needs every axis "
             "UNSET, S2 needs Faction set, S4 needs Faction and Authority set), so loading it would strand the "
             "player. A position inside a lock scene before its commit counts as before it (no save exists there, "
             "I9); the commit checkpoint counts as past it. (b) *Prefix:* the set axes are not a prefix of the lock "
             "order (Faction, then Authority, then Deleted). For a loaded record (b) is implied by D16 and (a) (the "
             "reference model checked 64 axis triples at 15 positions and found none that fires (b) alone), so it is "
             "kept as documentation and has no fixture of its own (AC9)"),
)
EC16_LAST = EC16_ENTRIES[-1][1]
EC16_ACTIVE = tuple(lo for lo, hi, text in EC16_ENTRIES if not text.startswith(EC16_RETIRED_PREFIX))
EC16_TEXT = {lo: text for lo, hi, text in EC16_ENTRIES if lo == hi}
EC16_EXCLUSIVE = 15  # the D-number of the exclusive-group item (cited by Edge Case 6)
EC16_LEGACY = 16  # the D-number of the pre-axes save item (cited by Core Rule 8, Edge Case 8, the lifecycle)
EC16_CRISIS = 9  # the D-number of the saved-crisis item (cited by AC9)
EC16_ORDER = 17  # the D-number of the lock-order item (the record alone cannot show D15-D17)
EC16_D7_CLAUSES = ("unnamed", "reverse", "new_mismatch")  # revision 12: multi and duplicate retired
EC16_DOC_CLAUSES = ("D17.prefix",)  # revision 12: the one documentation clause (AC9), an equivalent mutant
EC16_KEYS = ("it compares and never rewrites the stored ID or the save, and reads no knob, so a patch never damages "
             "a save.",
             "SaveService's load check reports each item below as a data error on load and refuses the load",
             "play never writes one, because every transition is one atomic checkpoint, I9",
             "A secret unlock flag alone changes nothing.",
             "The check reads the record, the saved flags and the story position (load_check(record, flags, position))",
             "D16 holds only while no player-facing build has such saves; if one ships before these fields do, the "
             "decision is reopened",
             # Revision 10 (round 10): which items run on a live record, and what the check does not promise.
             "load_check always tests a loaded record, so it runs every item, and reports clause ids",
             # Revision 11 (round 11, Open Questions 17 and 18).
             "storyline_phase runs the same items on the live record, except that the two marked *(not for the live "
             "crisis)* are skipped for a live_crisis record",
             "so the CRISIS fixture of AC9 reports {D9, D17}.",
             "A refusal is never handled as file corruption",
             "Inclusion rule (user decision 2026-11-17, Open Question 17).",
             "(iii) it cannot refuse a record that play writes.",
             "Not checked, by the inclusion rule (edited or debug saves only; user decision 2026-11-17, Open Question 17)",
             "Tripwires: the reference model asserts that the categories of accepted records play does not write equal "
             "a pinned list")
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
LIFE_EDGE_CASES = 6  # lifecycle revision 5
# AethelgardPrototype/AGENTS.md's protected list; the axes Dependencies must name each one (round 5).
PROTECTED_RE = re.compile(r"Do not modify (.+?) unless the prompt explicitly allows it")
H_PROTECTED = ("protected area", "what this design needs there", "where specified")

# Identifiers that would make the storyline ID depend on timing or companions (GDD AC4, Core Rule 12).
FORBIDDEN_ID_INPUTS = re.compile(r"pace|timing|companion|bridge|medicine|act[1-4]_|ch[0-9]+_|has_", re.IGNORECASE)
KNOWN_STORIES = frozenset({"Y2-PP-T17", "Y1-P1-T05", "Y1-P1-T03", "Y1-P0-S06b"})
STORY_RE = re.compile(r"Y\d-[A-Za-z0-9]+-[A-Za-z0-9]+")
FIRST_RUNTIME_AC = 5
AXES_AC_COUNT = 17  # revision 9: AC16 is the playtest comprehension criterion; revision 11: AC17 is P5 voiced
STORYLINE_ID_PARAMS = ("A", "F", "D", "I")
# Revision 9: each runtime AC's blocking stories are pinned (a change is a planning decision).
AXES_AC_BLOCKED = {
    5: {"Y2-PP-T17"}, 6: {"Y2-PP-T17", "Y1-P1-T03"}, 7: {"Y2-PP-T17", "Y1-P1-T03"}, 8: {"Y2-PP-T17"},
    9: {"Y2-PP-T17", "Y1-P1-T05", "Y1-P1-T03"}, 10: {"Y2-PP-T17", "Y1-P1-T03"}, 11: {"Y2-PP-T17"},
    # Revision 12 (round 12): AC15 is also blocked by Y2-PP-T17 (it lists the arc flags).
    12: {"Y2-PP-T17", "Y1-P1-T03"}, 13: {"Y2-PP-T17"}, 14: {"Y2-PP-T17"}, 15: {"Y2-PP-T17", "Y1-P1-T03"},
    16: {"Y2-PP-T17", "Y1-P1-T05", "Y1-P1-T03"}, 17: {"Y2-PP-T17", "Y1-P1-T03"},
}
# Revision 9: the axes Observables table's first column, in order (scene_variants and ending_sequence removed;
# module_keys, scene_render, ending_render added; phase_of / load_check take flags and position).
AXES_OBSERVABLES = (
    "formula_id(A, F, D, I, knobs, flags)", "prereqs_met(T, knobs, flags)", "family(id)",
    "phase_of(record, loaded, flags, position)", "axis(record, name)",
    # Revision 12 (round 12): AC11/AC13 read stored_id, AC14 keyed_axis and base_lines, AC16/AC17 lock_arguments.
    # Revision 14 (round 14): AC11 reads companions_of.
    "stored_id(record)", "companions_of(module_id)", "keyed_axis(module_id)", "base_lines(scene)",
    "lock_arguments(axis)",
    "composer_modules(record, flags)",
    "module_keys(flag)", "ending_render(id)", "story_plus_state(id)",
    "boot_errors(knobs, flags, build)", "load_check(record, flags, position)",
    "scene_lines(id, scene)",  # revision 11 (round 11): masked authored lines replace scene_render
)
# A runtime AC may name a formula (not an observable) only in this exact phrase: AC5 states which defect its cases
# detect. Reported to the author as a doc nit (storyline-axes.md AC5); the phrase itself is pinned in AC5.
AC5_FORMULA_MENTION = "so a swapped `transform()` fails"
# Key phrases of the axes ACs (normalized). {reach} is the 1.0-reachable count, derived.
AXES_AC_KEYS: dict[int, tuple[str, ...]] = {
    5: ("with one route enabled at a time (synthetic knobs, formula level only)",
        "so a swapped transform() fails"),
    9: ("called with loaded false for CRISIS and true for the others",
        "phase_of of the CRISIS fixture with loaded true is DAMAGED",
        "gives phase_of(…, true) DAMAGED and load_check() exactly {that clause id}",
        # Revision 11 (round 11): the live crisis is bounded; mutation kill; non-goals load.
        "The live crisis is bounded (Open Question 18)",
        "at C8-S16's commit checkpoint gives DAMAGED",
        "a copy of load_check with that clause deleted fails at least one fixture of this criterion",
        # Revision 12 (round 12): one documentation clause; the D0 fixtures; the legacy fixture; an edited scene.
        "except the documentation clause, which is listed as an equivalent mutant",
        # Revision 14 (round 14): the clause-id list, one D0 fixture per clause, the D7 fixture, a new game.
        "The clause ids are exactly: D0.missing, D0.type, D0.enum, D0.element, D0.duplicate, D0.max, D1.secret, "
        "D1.unset_axis, D1.invalid_row, D1.other_id, D6, D7.unnamed, D7.reverse, D7.new_mismatch, D8, D9, "
        "D14.undefined, D14.no_entry, D14.not_played, D15, D16, D17.before_commit and D17.prefix.",
        "a Chapter 8 legacy save that no story scene places (D0.missing), a non-string storyline_id (D0.type)",
        "a non-string beats_played element (D0.element), a set holding one element twice (D0.duplicate)",
        "a two-entry retraction_log (the R2 and R3 Faction retractions of (NONE, HEARTH, RELEASE), each consistent on "
        "its own) and a two-element beats_played (D0.max)",
        "the D7 new-value fixture is (SHARED, ARCHIVE, RELEASE) stored as its own ID with the entry {authority, NONE "
        "→ YOU} and its beat retract_R2_authority_YOU",
        "New game: the first save of a new game (every field at its default, act1_pace UNSET, at PRE_C8) gives "
        "load_check() empty and phase_of(…, true) LEANING.",
        # Revision 13 (round 13): D0 no longer shadows D14's undefined-beat clause.
        "the D14 fixtures include a beats_played holding one undefined retract_* id, which reports D14, not D0",
        "Legacy: a save of the previous schema version with no lifecycle block, defaulted before the check (Edge Case "
        "8), gives load_check() empty and phase_of(…, true) LEANING at PRE_C8, and exactly {D16} at CH9",
        "Non-goals load: one fixture per non-goal of Edge Case 16 (an edited lock_negotiated, an edited "
        "withdrawn_item, an edited scene, a FINAL record before the final authorization)",
        "load_check() gives the same result with every knob flipped",
        "Fixtures use the position ids of Terms (Story position)."),
    # Revision 12 (round 12): the three 1.0 companions, timing per flag, stored_id, Kaelthas never placed.
    11: ("the records with no companion and with all three 1.0 companions (Elara, Seraphina, Lyra)",
         "keep stored_id() and family() unchanged",
         "adding one timing flag f changes composer_modules() by exactly module_keys(f)",
         # Revision 14 (round 14): the mirror-flag sentence is gone; companions_of is the observable.
         "every module m in composer_modules() has companions_of(m) within the record's present companions",
         "no module m in composer_modules() has Kaelthas in companions_of(m)"),
    12: ("or any secret route is enabled in a 1.0 build; with the default knobs and build 1.0 it is empty",),
    # Revision 11 (round 11): masked authored lines, pairwise 2. Revision 12 (round 12): the base is base_lines(),
    # three story scenes, keyed_axis(), two seeded defects, the raters on the smallest pair.
    14: ("over the {reach} storylines reachable in 1.0, by authored lines with interpolation masked, not by ids or raw "
         "text",
         "a substituted name, number or faction name alone never counts",
         "A scene's *base* is base_lines(scene), what it plays with no module selected",
         "An ID *differs in a scene* when scene_lines(id, scene) differs from the base",
         "Pass: for every ID, at least 3 story scenes (a C<n>-S<m> or boss id; the ending sequence does not count) "
         "differ from their base",
         "at least one of those differences comes from a module whose keyed_axis() is faction or deleted",
         "for every pair of distinct IDs, at least 2 scenes differ between them, at least one of them a story scene",
         "Seeded defects, each of which must fail the criterion",
         "route data in which every module's keyed_axis() is family",
         "for the pair with the smallest count two raters confirm that its differing lines differ in content",
         "a threshold above 2 is Open Question 13"),
    # Revision 12 (round 12): every arc has a row; a zero-hit scan is NOT ASSESSED.
    # Revision 13 (round 13): arc 08 pushes Faction, so ten arcs.
    15: ("lists every flag the ten 1.0 side arcs that push an axis (01-04, 06-08, 10-12) set in a side_arc_flags table",
         "each of the ten arcs has at least one row",
         "(a scan with zero hits is NOT ASSESSED, never a pass)"),
    16: ("a blind playtest of Chapter 8 with at least 12 testers", "At least 6 play Act 1 themselves",
         "At least 2 testers per invalid row", "two raters who did not run the session",
         # Revision 12 (round 12): the Act-1 subgroup gate, (c)/(d) reported, a fresh re-run of at least 12.
         "(a) of the testers who played Act 1 themselves, at least 70% name an earlier choice behind an argument in at "
         "least 2 of the lock scenes whose lock_arguments() was non-empty for them",
         "the fixture-save testers' rate is reported, not gated",
         "at least 75% of crisis testers name both the refusing faction and the value it refused",
         "Reported measures with no verdict effect:",
         "95% Wilson intervals beside every rate",
         "A run is never stopped early or extended to reach the bar.",
         "Failure action:",
         "the playtest is re-run as a fresh run of this whole criterion (at least 12 new testers, judged alone, never "
         "pooled with a failed run)"),
    # Revision 12 (round 12): lock_arguments() replaces "voices ... lines".
    17: ("for each of the ten 1.0 side arcs that push an axis (01-04, 06-08, 10-12)",
         "Arc 12 is tested for its deleted:CHOOSE push only, arc 08 for its Faction push only.",
         "makes lock_arguments() of the axis the flag pushes contain an argument "
         "whose flag is that flag",
         "gives a lock_arguments() that contains none of that arc's flags"),
}
# Revision 12 (round 12): retired AC wording that must not come back.
AXES_AC_FORBIDDEN: dict[int, tuple[str, ...]] = {
    9: ("which are listed as equivalent mutants", "D7.multi, D17.prefix"),
    14: ("most of the 24 IDs share", "differ from their baseline"),
    16: ("at least 6 new testers", "in at least 2 of the 3 lock scenes"),
    17: ("voices none of those lines",),
}
# Revision 12 (round 12): the story-type paragraph after the "Runtime" heading.
AXES_RUNTIME_KEYS = (
    "ACs 5-14 are Logic (BLOCKING), automated in the project's own SceneTree test harness",
    "with golden vectors exported from the reference model so the GDScript and the model cannot drift",
    "AC15 is Logic (BLOCKING), a data scan; AC16 and AC17 are Integration.",
    "three endings evidence the families, not the 24 ending sequences, which AC14 tests as data.",
)
AXES_DOC_AC_KEYS = (
    "Document-level (document lint, Config/Data, advisory)",
    "it shows the document is internally consistent and unchanged where pinned, not that the state machine is "
    "correct",
    "starting with a non-shipping reference model of the Formulas and a walk of the lifecycle transitions (Open "
    "Question 16)",
    "reachable_1_0 equals the valid rows plus the 1.0 secret rows (none)",
)

# --- storyline-lifecycle.md -----------------------------------------------------------------------------------
TRANSITIONS = {  # id -> (from, event, guard, to, effects), backticks removed. Lifecycle revision 5: T1-T9.
    "T1": ("LEANING", "C8-S13 resolves", "—", "PARTLY_LOCKED", "faction set; lock_negotiated per lock_pass; checkpoint"),
    "T2": ("PARTLY_LOCKED", "C8-S14 resolves", "faction set, authority UNSET", "PARTLY_LOCKED",
           "authority set; kaelen_commitment set when YOU; lock_negotiated per lock_pass; checkpoint"),
    "T3": ("PARTLY_LOCKED", "C8-S16 resolves", "faction and authority set; the row is valid", "VALIDATED",
           "deleted set; lock_negotiated per lock_pass; ID stored; checkpoint"),
    "T4": ("PARTLY_LOCKED", "C8-S16 resolves", "faction and authority set; the row is invalid", "CRISIS",
           "deleted set; lock_negotiated per lock_pass; the refusing faction breaks the coalition; no checkpoint"),
    "T5": ("CRISIS", "a renegotiation is taken", "the offer is in the row's offer set", "VALIDATED",
           "the axis changed; axis_revised, lock_negotiated gain it; retraction recorded; retraction beat played; "
           "kaelen_commitment set when the new Authority is YOU; ID stored; checkpoint"),
    "T6": ("LEANING or PARTLY_LOCKED", "Root of Heaven entry, any path", "—", "unchanged", "TURNED_BACK"),
    "T7": ("VALIDATED", "Root of Heaven entry, any path", "—", "FIXED", "root_phase INSIDE; checkpoint"),
    "T8": ("FIXED or FINAL", "Root of Heaven entry, any path", "—", "unchanged", "open"),
    "T9": ("FIXED", "execution confirmed", "the final authorization scene is playing", "FINAL",
           "root_phase FINAL; checkpoint"),
}
GATE_EVENT = "Root of Heaven entry, any path"
STORED_PHASES = ("VALIDATED", "FIXED", "FINAL")
CHECKPOINT = "checkpoint"
NO_CHECKPOINT = "no checkpoint"
GATE_TABLE = {  # phases cell -> outcome cell, backticks removed (lifecycle revision 6: four rows)
    "LEANING, PARTLY_LOCKED": "TURNED_BACK: the Assembly has not decided",
    "DAMAGED (a live record)": "TURNED_BACK: a data error, no transition; a dev build asserts; the player sees a "
                               "system-voice prompt (not the Assembly line) to reload the last save that passes the "
                               "load check",
    "VALIDATED": "ROOT_OF_HEAVEN; root_phase becomes INSIDE (T7)",
    # round 16: T8 writes only the story position (Scene placement's writer table)
    "FIXED, FINAL": "ROOT_OF_HEAVEN; nothing changes but the story position (T8: ROOT_LEFT → ROOT, "
                    "STORY_PLUS → ROOT_STORY_PLUS, Scene placement)",
}
RED_LINE_VALUES = {"R1": "no one hand compels the deleted back",
                   "R2": "no release that destroys unresolved memory appeals",
                   "R3": "no irreversible release while emergency Root is abolished"}
# Lifecycle revision 5: crisis_offers keeps its domain guard; signpost is HIDDEN for every disabled route; the
# deferral, last-chance and witness-vote formulas are gone.
LIFE_FORMULAS = (
    "crisis_offers(row) = {} if row is not R1, R2 or R3; otherwise",
    '{ "revise:" + axis + ":" + v : axis locked, v ≠ row[axis], not invalid(row with axis = v) }',
    "signpost(T) = HIDDEN while T is disabled (every secret route in 1.0)",
)
LIFE_KEYS = (  # normalized sentences the lifecycle doc must keep
    # Lifecycle revision 11 (review 2026-11-18, item 13): "cannot be saved" is I9's, not PM:7143/7153's.
    "The crisis cannot be left or skipped until an offer is taken (PM:7143, PM:7153), and it cannot be saved "
    "(storyline-axes.md I9).",
    "displays the stored structure, offers no reconsideration, and confirm_execution sets root_phase FINAL (T9); "
    "nothing else changes.",
    "No other transition exists: nothing leads from VALIDATED, FIXED or FINAL to an earlier phase or to CRISIS — not "
    "a knob change, not a flag, not loading.",
    "Loading restores the record, runs the damaged-record check (a DAMAGED record does not load), and derives the "
    "phase; it fires no transition by itself",
    "The story graph never starts C8-S14 before C8-S13 resolves or C8-S16 before C8-S14 resolves",
    "None of its own.",
    "Not knobs: the scene order, the offer sets (derived from invalid), the commit and save rule, the rule that "
    "C8-S16 cannot be left with a crisis open, and the rule that a stored ID never changes.",
    "Every field is saved, so a reload restores the retractions and beats exactly.",
    "never as it demanding its own replacement",
    "NG+ starts a new record, not a transition of this table",
    "There is no runtime catch-up.",
    "Cut order, first cut first. A cut never removes an invariant, a transition, a record field or an id",
    # Scene order guards (the lock-order item of Edge Case 16 relies on them).
    "Plays only with every axis UNSET.", "Plays only with Faction set and Authority UNSET.",
    "Plays with Faction and Authority set.",
    "a speaker other than Kaelen",
    # Revision 5: the secret routes stay closed; this replaces the deferral, invocation and witness-vote pins.
    "play no part in this contract beyond staying closed",
    "No line names a secret route or the institution one needs",
    "The source's line that a secret route \"may create alternative constitutional mechanism later\" (PM:7144) is "
    "not offered in 1.0.",
    # Lifecycle revision 7 (axes round 11): C9-S18 keeps the source's condition.
    "keeps the source's condition: with every FIRSTWAKE offer prerequisite set it plays its decrypted form",
    "otherwise the packet remains noise",
    "C9-S19 and C9-S20 do not play",
    "C10-S13, C10-S14 and C10-S15 play only when the stored ID is their route's, which no 1.0 record holds.",
    "Secret prerequisite flags that content sets are kept and transform nothing, and the journal shows no signpost "
    "for any route",
    # Revision 5: the commit and save rule (I9).
    "commits all of its effects — every field it writes and the id of the beat it plays — together with an autosave, "
    "as one atomic checkpoint before that beat plays.",
    "autosave and manual save are suppressed from the start of C8-S13, C8-S14 and C8-S16 until the commit, and from "
    "the start of the final authorization until T9.",
    "a reload from the checkpoint resumes at the start of the committed beat, and no offer or vote replays.",
    "T4 has no checkpoint of its own: the crisis it opens is part of C8-S16, and its writes are committed with the T5 "
    "that closes it.",
    "So no save ever holds a record that is half of a transition, and no save is positioned inside a lock scene.",
    # The gate.
    "The load path never meets LEANING, PARTLY_LOCKED or DAMAGED",
    # Revision 10 (round 10, F9): T6 never fires in play; it and the DAMAGED row are defence in depth.
    "T6 and the DAMAGED row are therefore defence in depth against a story-graph defect",
    "A VALIDATED save positioned inside Root of Heaven cannot be written by play (T7 is atomic) but loads, and the "
    "load-path gate then runs T7.",
    # Lifecycle revision 7 (axes round 11, Open Question 18).
    "CRISIS never reaches the gate: storyline_phase returns it only for a live record inside C8-S16 before its "
    "commit (live_crisis)",
    "The DAMAGED turn-back repairs nothing",
    "Lint shows the text matches its pins; it is not evidence that the state machine is correct",
    # Lifecycle revision 8 (axes round 12): every checkpoint stores the story position.
    "Every checkpoint also stores the story position it reaches (storyline-axes.md Terms, Story position: the commit "
    "of C8-S13 writes S13_DONE, and so on), and a save made anywhere else stores the last position it has crossed "
    "(Y1-P1-T05).",
    # The gate is one predicate on every scene change into Root of Heaven.
    "the Chapter 10 scene chain and chapter select count as this path",
    "including \"Resume story\" and the free-travel Root of Heaven region",
    # Lifecycle revision 11 (item 3): the load-path checkpoint is stated as an outcome; the mechanism is T05's.
    "The check is one predicate, not a list of callers (design review round 12): it runs before every scene change "
    "whose target is a Root of Heaven scene (the Root of Heaven scene set, Scene placement), whoever requests it; on "
    "load, for a save positioned inside Root of Heaven; and before free travel unlocks the Root of Heaven region, "
    "which stays locked until the predicate passes.",
    "On load the outcome is decided from the saved record and position alone: a load the check refuses or the gate "
    "turns back leaves the game as it was before the load request and writes no save.",
    "A new caller therefore cannot skip it, and setting a chapter-unlock flag alone never opens the gate.",
    # Legacy saves are defaulted before the load check.
    "A save of a schema version before these fields has its whole record block filled with the defaults before the "
    "load check runs (storyline-axes.md Edge Case 8), so the check meets a typed record: at PRE_C8 it loads LEANING, "
    "and past a lock scene D16 refuses it.",
    # Chapter select (the record itself is derived in check_revision12).
    # Revision 9 of the lifecycle (axes round 13): keyed to the entry scene's position, not the chapter number.
    "Chapter select (user decisions 2026-11-17 and 2026-11-19, design review rounds 12 and 13, review 2026-11-18). "
    "Chapter select is player-facing.",
    "It starts a new record, never edits a loaded one, and each entry is keyed to the story position of its entry "
    "scene, not to its chapter number",
    "An entry positioned before C8-S13 starts LEANING with the defaults (position PRE_C8).",
    # Lifecycle revision 11 (items 1 and 3): the record is per row; the checkpoint is an outcome.
    "An entry positioned past C8-S16's commit writes a fixed valid record",
    "axis_revised, retraction_log and beats_played empty, kaelen_commitment UNSET, root_phase OUTSIDE (FINAL for row "
    "13), the matching AXIS* and lock_negotiated_* mirror flags, and the row's story position.",
    "No entry is positioned inside the lock scenes (S13_OPEN to S16_OPEN) or the final authorization "
    "(FINAL_AUTH_OPEN).",
    "every save written after a chapter-select start, from the first, holds the whole record and the row's position",
    "So chapter select never writes a save the load check refuses, its ending is BOUND without sole_dissent, and no "
    "entry reaches a superseded scene.",
    # Lifecycle revision 9: the NG+ reset sets the story position; a legacy position is derived once.
    "story_position → PRE_C8.",
    "Such a save holds no story position, so the defaulting step derives it once, by the order in "
    "storyline-axes.md Terms (Story position)",
    "Changing chapter select is protected story progression: the implementing story needs the user's approval.",
)
# Lifecycle revision 5: the scene-level Observables table's first column, in order.
LIFE_OBSERVABLES = (
    "storyline_phase()", "storyline_id()", "axis(name)", "gate_open()", "enter_root_of_heaven(path)",
    "current_scene()", "current_beat()", "lock_options(axis)", "lock_arguments(axis)", "red_lines_voiced(scene)",
    "offers()", "take(offer)", "record_hash()", "try_save()", "retraction_log()", "beats_played()", "beat_text(id)",
    "beat_speaker(id)", "signpost(route)", "quoted_commitment()", "route_lines()", "ending_modules()",
    "confirm_execution()", "load_errors()", "save_bytes(slot)", "epilogue_lines()", "record_field(name)",
    "flag_set(name)",
    # Lifecycle revision 11 (review 2026-11-18, item 6): the observables the L-ACs used in prose.
    "region_unlocked(id)", "saves_written()", "scenes_played()", "c9s18_form()", "data_errors()",
)
LIFE_AC_COUNT = 19  # lifecycle revision 5: 18; revision 8 (axes round 12): L-AC19, the gate predicate and chapter select
# Key phrases of the L-AC bodies (normalized); {legacy} and {total} are filled in from derived values.
LAC_KEYS: dict[int, tuple[str, ...]] = {
    5: ("with every secret prerequisite flag set and with none",),
    # Lifecycle revision 11 (item 4): L-AC6 runs on the window table.
    6: ("inside its window try_save() is false and no entry of saves_written() holds a position inside it",
        "a quit inside the window and a reload give the record_hash() of the last save before the window",
        "reloading it gives the committed record_hash(), current_beat() the table's resume point at its start, and the "
        "table's never-replays check",
        "For T5 the crisis (T4) is inside the window: try_save() is false throughout."),
    7: ("and the {total} runs yield {total} distinct beat ids",
        "take() of a value not offered (the same value; the other invalid row) is false and record_hash() is "
        "unchanged"),
    8: ("LEANING and PARTLY_LOCKED on the story path → TURNED_BACK",
        "on the load path the load is refused with load_errors() naming D{legacy} and no gate entry",
        "VALIDATED → ROOT_OF_HEAVEN and FIXED; FIXED and FINAL → ROOT_OF_HEAVEN, phase unchanged",
        "they run on a live record that the test injects at the gate, and are reported as synthetic",
        "The same injection with a live DAMAGED record → TURNED_BACK, record_hash() unchanged and data_errors() naming "
        "the gate's DAMAGED row",
        # Lifecycle revision 7 (axes round 11, Open Question 18).
        "A live invalid-row record with nothing stored, injected past C8-S16 (in Chapter 9), reads DAMAGED",
        "not a gate error",
        # Lifecycle revision 11 (item 7): the load × VALIDATED cell is counted and synthetic, here and in the note.
        "The load × VALIDATED cell is a VALIDATED fixture save positioned at ROOT: it loads, and the load-path gate "
        "gives ROOT_OF_HEAVEN and FIXED; play cannot write that save (T7 is atomic), so the cell is synthetic and "
        "counted",
        "Every TURNED_BACK lands where S6's landing table says (current_scene())."),
    9: ("take() of each of the {total} renegotiation offers is false with record_hash() unchanged",
        "after setting every secret prerequisite flag and flipping every knob, storyline_id() and storyline_phase() "
        "are unchanged"),
    10: ("With every secret prerequisite flag set and the default knobs",
         "C9-S19, C9-S20, C10-S13, C10-S14 and C10-S15 never become current_scene()",
         "c9s18_form() is LOGGED (and, on a second record with one FIRSTWAKE prerequisite unset, NOISE)",
         "signpost() is HIDDEN for all three routes"),
    11: ("take() of each renegotiation offer is false with record_hash() unchanged",
         "confirm_execution() gives FINAL with storyline_id() unchanged",
         "confirm_execution() anywhere else is false with record_hash() unchanged."),
    12: ("YOU locked at C8-S14 with each of the three commitments and never revised → STATED, "
         "record_field(kaelen_commitment) the one chosen",
         "Authority never YOU → NONE, with record_field(kaelen_commitment) UNSET",
         "YOU kept through any other R1 renegotiation (Faction or Deleted) → STATED, the C8-S14 commitment",
         "Authority never YOU → NONE"),
    13: ("a save with no axis data positioned before C8-S13 loads LEANING with load_errors() empty",
         "each damaged-record fixture of storyline-axes.md AC9 gives load_errors() exactly its item, the load is "
         "refused (current_scene() stays load_menu), and save_bytes() of its slot is unchanged."),
    14: ("on every 1.0 storyline, and contains none of them with no flag set",),
    # Lifecycle revision 11 (item 11): every stored field and the mirror flags.
    15: ("record_field() of every stored field of the composer record equal to a new game's default",
         "flag_set() false for every AXIS*, axis_revised_* and lock_negotiated_* mirror flag and for every secret "
         "prerequisite and unlock flag"),
    16: ("texts are pairwise distinct except where the cut order shares them",
         # Lifecycle revision 11 (item 9): the answerer is the refusing faction's delegate.
         "for every retract_<rule>_* id beat_speaker(id) is that rule's refusing-faction delegate (R1 Hearth, R2 "
         "Archive, R3 Continuity), so never Kaelen"),
    17: ("on load load_errors() names D{legacy}, current_scene() stays load_menu, and scenes_played() holds no lock "
         "scene.",),
    18: ("one retained live Godot viewport screenshot each (not a headless or dummy-renderer capture) in "
         "production/qa/evidence/, with lead sign-off recorded beside them",
         "the S6 turn-back prompt for a live DAMAGED record"),
    # Lifecycle revision 8 (axes round 12): the gate predicate on every path, and chapter select.
    # Lifecycle revision 11 (items 1 and 12): every chapter-select row, and the landings.
    19: ("For each scene-change request whose target is a Root of Heaven scene, issued from the Chapter 9 end, the "
         "Chapter 10 scene chain, world-map \"Resume story\", free travel and chapter select, with a LEANING or "
         "PARTLY_LOCKED injected live record: enter_root_of_heaven() is TURNED_BACK, current_scene() is not a Root of "
         "Heaven scene but S6's landing for that path, and saves_written() gains nothing",
         "with ch10_unlocked set and no ID stored, region_unlocked(root_of_heaven) is false",
         "For each of the 13 rows of the chapter-select table, started from the main menu",
         "rows 9-12 give enter_root_of_heaven() ROOT_OF_HEAVEN and storyline_phase() FIXED, and row 12 then reaches the "
         "final authorization, where confirm_execution() gives FINAL",
         "row 13 gives storyline_phase() FINAL and enter_root_of_heaven() ROOT_OF_HEAVEN with record_hash() unchanged "
         "(T8)",
         "rows 1-3 start LEANING, and row 3's scenes_played() starts with C8-S13",
         "no row's scenes_played() holds ch8_revolt_crisis or ch10_sovereign_confrontation"),
}
# Assertions that cannot fail (offers() is empty in every non-offer scene): forbidden in the L-ACs (round 2).
NON_FAILING = ("offers() is empty", "offers nothing", "offers() there is empty")
# Legacy storyline flags (lifecycle round 2, D2): each must be listed in the lifecycle Dependencies and occur in the
# code lines that row cites (setter and the game_manager declaration).
LEGACY_FLAGS = ("ch8_revolt_led", "ch8_council_formed", "ch8_witness_network_created", "ending_route_ch8_lead",
                "ending_route_ch8_council", "ending_route_ch8_witness", "ch10_destroy_sovereign",
                "ch10_rewrite_sovereign", "true_ending_seen", "ng_plus_unlocked")
LIFE_REQUIRED_PATHS = 3  # cross-checked against the S6 path list and the Validation note
H_CONTENT = ("content", "count", "plays on")

REQUIRED_HEADINGS = (("Overview",), ("Player Fantasy",), ("Detailed Rules", "Detailed Design"), ("Formulas",),
                     ("Edge Cases",), ("Dependencies",), ("Tuning Knobs",), ("Acceptance Criteria",))
OPTIONAL_HEADINGS = frozenset({"Summary", "Cross-References", "Open Questions"})

# Removed by review revisions 1-2; must not reappear. ("secret_invoked" left this list in revision 4: it is the
# composer set of confirmed invocations again, GDD AC3.) "C8-S17" is the mis-cited final scene in the axes doc;
# the lifecycle doc cites the real C8-S17 Revolution Name (PM:7155-7163), so it is exempt there.
# Revision 12: "PM:7118" was stale as a whole because round 2 cited it for a claim it does not make; round 12 cites
# it correctly (staged verification), so the stale string is now that old claim, and check_revision12 requires every
# PM:7118 citation to be the supported one.
STALE_STRINGS = ("PM:3615", "C8-S17", "ch8_choice_made", "S = T", "Kaelen only executes", "PM:8735",
                 "final authorization, before", "involuntary preservation (PM:7118)", "Kaelen may be one witness",
                 "at the final confrontation, to dismantle", "PM:7062-7070",
                 # revision 6 / lifecycle revision 2
                 "consent_failed_mandate", "failed-mandate", "authorized over dissent", "lock catch-up",
                 "T14 catch-up", "legacy-save catch-up")
STALE_LIFECYCLE_EXEMPT = frozenset({"C8-S17"})
# Revision-3 vocabulary removed by revision 4; allowed only in storyline-axes.md's Open Questions.
STALE_VOCAB = ("storyline_state", "final_reconsidered", "reconsider_targets", "reconsideration_triggers",
               "GATE_CRISIS", "crisis_endured", "renegotiations_valid", "faction_negotiation_allowed",
               "invalid_combinations")
# Revision 9 (user decisions 2026-11-11): the identifiers of the removed Witness deferral, invocation, vote and
# stand-down. Forbidden everywhere in both documents (the Open Questions describe the removed design in prose).
STALE_SECRET_VOCAB = ("witness_deferred", "secret_invoked", "witness_seats", "witness_dissenters", "witness_mandate",
                      "witness_threshold", "LAST_CHANCE", "DEFERRED", "defer:", "invoke:", "last_chance_offers",
                      "gate_retcon", "deferral_", "invoke_witness", "stand_down", "consent_unauthorized",
                      "dissent_named", "decline(", "scene_variants", "ending_sequence")

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
    plus = any((f, target, "+") in SEED_ROWS for f in flags)
    minus = any((f, target, "−") in SEED_ROWS for f in flags)
    return "CLEAN" if plus and not minus else "NEGOTIATED"


NOTHING_STORED = "nothing stored"


def py_phase(a: str, f: str, d: str, sid: str, root: str, invalid: set[tuple[str, ...]], loaded: bool = True,
             in_c8s16: bool = False) -> str:
    """The phase of a record (authority, faction, deleted, stored ID, root_phase): first the Edge Case 16 items
    decidable from these five fields (D1, D8, the lock-order clause of D17, and D9 only when ``loaded``), then
    FINAL > FIXED > VALIDATED (each needing a stored ID) > LEANING > PARTLY_LOCKED > CRISIS."""
    stored = sid != NOTHING_STORED
    is_set = [v != UNSET for v in (f, a, d)]  # in lock order: Faction, Authority, Deleted
    if is_set != sorted(is_set, reverse=True):
        return "DAMAGED"  # D17: the set axes are not a prefix of the lock order
    if stored and (not all(is_set) or (a, f, d) in invalid or sid != f"SL-{a}-{f}-{d}"):
        return "DAMAGED"  # D1
    if not stored and root in ("INSIDE", "FINAL"):
        return "DAMAGED"  # D8
    # Revision 11 (round 11, Open Question 18): D9 is skipped only for live_crisis.
    if not stored and all(is_set) and (loaded or not in_c8s16 or (a, f, d) not in invalid):
        return "DAMAGED"  # D9
    if stored:
        return "FINAL" if root == "FINAL" else "FIXED" if root == "INSIDE" else "VALIDATED"
    if not any(is_set):
        return "LEANING"
    if not all(is_set):
        return "PARTLY_LOCKED"
    return "CRISIS"


def odd_rule(rules: dict[str, tuple[str, ...]]) -> tuple[str, list[str]]:
    """The rule whose renegotiation-offer count differs from the others' (R1: six vs five), and the other rules.

    Revision 9 decouples this from Witness Protocol: R1 is distinguished by its offer count, not by a route."""
    offers = crisis_offers(rules)
    for rule in rules:
        others = [r for r in rules if r != rule]
        if others and len({len(offers[r]) for r in others}) == 1 and len(offers[rule]) != len(offers[others[0]]):
            return rule, others
    first = next(iter(rules), "R1")
    return first, [r for r in rules if r != first]


CTX: dict[str, object] = {}  # values derived by one check and read by a later one


def compress_items(numbers: tuple[int, ...] | list[int]) -> str:
    """Edge Case 16 numbers as the docs write them: (1, 6, 7, 8, 9) -> 'D1, D6-D9'."""
    runs: list[list[int]] = []
    for n in numbers:
        if runs and n == runs[-1][-1] + 1:
            runs[-1].append(n)
        else:
            runs.append([n])
    return ", ".join(", ".join(f"D{n}" for n in r) if len(r) < 3 else f"D{r[0]}-D{r[-1]}" for r in runs)


def join_and(items: list[str]) -> str:
    """'a', 'a and b', 'a, b and c'."""
    return items[0] if len(items) == 1 else f"{', '.join(items[:-1])} and {items[-1]}" if items else ""


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
    CTX["rules"] = rules
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
        if family != want_family:
            probs.add(area, f"{where}: family '{family}', expected '{want_family}' (reserved until the route ships)")
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
    CTX["prerequisites"] = stated
    CTX["unlock_flags"] = [flag for route in SECRET_ROUTES for flag in unlocks.get(route, [])]
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
    # Revision 12: a flag has at most one axis row and at most one non-axis (modifier or timing) row.
    for flag in sorted(set(flags)):
        kinds = [cells[1].partition(":")[0] in AXES for _, cells in rows if cells[0] == flag]
        if kinds.count(True) > 1:
            probs.add(area, f"flag '{flag}' has {kinds.count(True)} axis rows (a flag pushes at most one axis)")
        if kinds.count(False) > 1:
            probs.add(area, f"flag '{flag}' has {kinds.count(False)} modifier or timing rows (at most one)")
    got_rows = {(cells[0], cells[1], cells[2].replace("-", "−")) for _, cells in rows}
    for flag, push, direction in SEED_ROWS:
        if (flag, push, direction) not in got_rows and flag in flags:
            have = [f"{c[1]} {c[2]}" for _, c in rows if c[0] == flag]
            probs.add(area, f"approved row '{flag} | {push} | {direction}' missing (the map has {have})")
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
        if flag in SEED_FLAGS and (flag, pushes, direction.replace("-", "−")) not in SEED_ROWS:
            want = [f"{p} {d}" for f, p, d in SEED_ROWS if f == flag]
            probs.add(area, f"{where}: '{pushes} {direction}' is not an approved row for this flag ({want})")
    intro = f"({SEED_FLAG_COUNT} flags in {len(SEED_ROWS)} rows: a flag may push a modifier and an axis, one row each, " \
            "never two axes)"
    if intro not in norm(" ".join(lines)):
        probs.add(area, f"seed map intro does not state '{intro}'")
    whole = norm(" ".join(lines))
    if "A seed row is matched by its (flag, pushes) pair, so a flag's modifier row never enters the test." not in whole:
        probs.add(area, "Formulas lack 'A seed row is matched by its (flag, pushes) pair, so a flag's modifier row never "
                        "enters the test.'")
    # Revision 12 (round 12): the Authority remap's reasons, including why ch1_knight_spared stays a modifier.
    # Revision 13 (round 13): one stated discriminator, verbatim quotes of PM:636 and PM:7048, PM:1804 cited.
    for key in ("The discriminator, in one sentence: an Authority seed records either Kaelen's first relation to "
                "the Key itself",
                "that \"somebody must be accountable.\" (PM:636)",
                "\"Because someone has to be answerable when this goes wrong.\" (PM:7048)",
                "(\"Flags track explanation separately from action.\", PM:1804)",
                "A player who purges Aldric and makes the first edit therefore reaches a negotiated YOU vote",
                "ch1_knight_spared stays a modifier only: the Purge path sets it too (dialogue/ch1/aldric.dlg:116)"):
        if key not in whole:
            probs.add(area, f"seed map notes lack '{key}'")


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
        want_scope = FEEDS_POST_1_0 if arc in POST_1_0_ARCS else "1.0"
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
    # Revision 9: AC3's own field list names exactly the pinned fields (it lost five Witness fields this round).
    want_names = {name.strip() for key in COMPOSER for name in key.split(",")}
    m = re.search(r"the composer record has exactly the fields (.+?), each with its pinned", norm(" ".join(lines)))
    named = set(re.split(r",\s*|\s+and\s+|/", m[1])) if m else set()
    if named != want_names:
        probs.add(area, f"AC3's field list {sorted(named)} != the composer record {sorted(want_names)}")


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
    phase_line, phase_body = pin_body(lines, f"{PHASE_SIGNATURE}:", STORYLINE_PHASE_BODY, area, probs)
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
        # Revision 9: damaged() also takes the saved flags and the story position, for D15-D17.
        # Revision 10 (round 10, F1): two items are load-only; every other item applies to the live record too.
        # Revision 11 (round 11, Open Question 18): the exemption is live_crisis only.
        for want in (f"{DAMAGED_SIGNATURE} is true when the inputs hold an item of Edge Case 16, with one exemption, "
                     "the live crisis",
                     f"D{EC16_CRISIS} and the before-commit clause of D{EC16_ORDER} are tested on every record except "
                     "a live_crisis one",
                     "Every other item applies to every record",
                     "CRISIS is returned only for live_crisis",
                     "position the record's story_position, passed as its own argument",
                     f"the other fields alone cannot show D{EC16_EXCLUSIVE}-D{EC16_ORDER}, so the check takes them",
                     "FINAL and FIXED need a stored ID"):
            if want not in norm(text):
                probs.add(area, f"storyline_phase paragraph lacks '{want}'")
        invalid = set(rules.values())
        if not any(r == "DAMAGED" for _, r in re.findall(r"\(([^()]*)\) → ([A-Z_]+)", examples.replace("`", ""))):
            probs.add(area, "storyline_phase has no DAMAGED example")
        # Revision 11: each example is followed by its position; "inside C8-S16" is the live-crisis window.
        found = [(fields, stated, "loaded false" not in label, "inside C8-S16" in where)
                 for label, body in labelled
                 for fields, stated, where in re.findall(r"\(([^()]*)\) → ([A-Z_]+)([^;.]*)", body.replace("`", ""))]
        if len(found) < 3:
            probs.add(area, f"storyline_phase has {len(found)} parseable examples, expected at least 3")
        if not any(not is_loaded and stated == "CRISIS" for _, stated, is_loaded, _ in found):
            probs.add(area, "storyline_phase has no in-play (loaded false) CRISIS example")
        for fields, stated, is_loaded, in_c8s16 in found:
            parts = [p.strip() for p in fields.split(",")]
            if len(parts) != 5:
                probs.add(area, f"storyline_phase example '({fields})' does not have 5 fields")
                continue
            a, f, d, sid, root = parts
            got = py_phase(a, f, d, sid, root, invalid, is_loaded, in_c8s16)
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
    # Revision 9: family() maps every secret id to RESERVED and never returns CONSENT (post-1.0).
    found = code_body(lines, "family(id):")
    body = found[1] if found else []
    reserved = [m for line in body for m in [re.match(r"(SL-SECRET-[A-Z, -]+?)\s*→ RESERVED\b", line)] if m]
    ids = sorted(i.strip() for m in reserved for i in m[1].split(","))
    if ids != sorted(f"SL-SECRET-{r}" for r in SECRET_ROUTES):
        probs.add(area, f"family() maps {ids} → RESERVED, expected every secret id once "
                        f"{sorted(f'SL-SECRET-{r}' for r in SECRET_ROUTES)}")
    if any(POST_1_0_FAMILY in line for line in body):
        probs.add(area, f"family() names {POST_1_0_FAMILY}, a post-1.0 family (revision 9)")
    if POST_1_0_FAMILY in COMPOSER["family"][1]:
        probs.add(area, f"the pinned composer family vocabulary holds {POST_1_0_FAMILY}")


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
    keys = {n: [k.replace("{legacy}", str(EC16_LEGACY)) for k in v] for n, v in CORE_RULE_KEYS.items()}
    # Rule 4: each rule's red line is voiced by its faction when its Authority and Faction are locked.
    for rule, (a, f, _) in rules.items():
        keys[4].append(f"{f.capitalize()} when {a} and {f} are locked ({rule}")
    # Rule 5: offer counts derived from invalid() (revision 9: no deferral row).
    first, others = odd_rule(rules)
    if first in offers and others:
        keys[5].append(f"{NUMBER_WORDS[len(offers[first])]} for {first}, "
                       f"{NUMBER_WORDS[len(offers[others[0]])]} for {' or '.join(others)}")
    # Rule 3 (revision 12): the '−' seeds per axis, derived from the seed rows.
    minus = {axis: sorted(f for f, push, d in SEED_ROWS if push.startswith(f"{axis}:") and d == "−") for axis in AXES}
    targets = {axis: sorted({push.split(":")[1] for f, push, d in SEED_ROWS if push.startswith(f"{axis}:")
                             and d == "−"}) for axis in AXES}
    keys[3].append(f"Faction has {NUMBER_WORDS.get(len(minus['faction']), 'no')} − seed "
                   f"({', '.join(minus['faction'])}, against {', '.join(targets['faction'])}) and Authority "
                   f"{NUMBER_WORDS.get(len(minus['authority']), 'no')}, "
                   f"{'both' if len(minus['authority']) == 2 else 'all'} against {', '.join(targets['authority'])} "
                   f"({', '.join(minus['authority'])})")
    keys[3].append("Deleted has none, so a Deleted vote is clean exactly when the one wraith seed backs its value"
                   if not minus["deleted"] else "Deleted has a − seed")
    # Rule 11 (revision 12): the 1.0 companion set, derived.
    keys[11].append(f"The 1.0 companion set is {join_and(list(COMPANION_ORDER))}.")
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
    enable_routes: list[str] = []
    for lineno, cells in rows:
        knob, default = cells[0], cells[1]
        if m := re.match(r"secret_route_enabled\.(\w+)", knob):
            routes = [m[1], *re.findall(r",\s*\.(\w+)", knob)]
            enable_routes += routes
            want = {"true" if scope_of.get(r) == "1.0" else "false" for r in routes}
            if len(want) != 1 or default != want.pop():
                probs.add(area, f"line {lineno} ({knob}): default '{default}' does not follow the secret table scopes")
            # Revision 9: no secret route ships in 1.0, so every enable knob defaults to false and may not be
            # enabled while its family is still reserved (I8).
            if default != "false":
                probs.add(area, f"line {lineno} ({knob}): default '{default}'; every secret route is disabled in 1.0")
            if "never enabled while family would be RESERVED" not in cells[2]:
                probs.add(area, f"line {lineno} ({knob}): safe range lacks 'never enabled while family would be "
                                "RESERVED'")
    if sorted(enable_routes) != sorted(SECRET_ROUTES):
        probs.add(area, f"secret_route_enabled rows cover {sorted(enable_routes)}, expected {sorted(SECRET_ROUTES)}")
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
    # Revision 9: an entry is "- D<n> text" or a retired range "- D<a>-D<b> retired (revision 9): ...".
    found = re.findall(r"- D(\d+)(?:-D(\d+))? (.+?)(?= - D\d+[ -]| D\d+ holds only while|$)", text)
    got = [(int(lo), int(hi or lo), item.strip()) for lo, hi, item in found]
    if [(lo, hi) for lo, hi, _ in got] != [(lo, hi) for lo, hi, _ in EC16_ENTRIES]:
        probs.add(area, f"line {lineno}: Edge Case 16 entries {[(lo, hi) for lo, hi, _ in got]} != the pinned "
                        f"{[(lo, hi) for lo, hi, _ in EC16_ENTRIES]}")
    covered = [n for lo, hi, _ in got for n in range(lo, hi + 1)]
    if covered != list(range(EC16_ENTRIES[0][0], EC16_LAST + 1)):
        probs.add(area, f"line {lineno}: Edge Case 16 numbering {covered} is not D{EC16_ENTRIES[0][0]}-D{EC16_LAST} without gaps")
    for (lo, hi, item), (_, _, want) in zip(got, EC16_ENTRIES):
        label = f"D{lo}" if lo == hi else f"D{lo}-D{hi}"
        if item != want:
            probs.add(area, f"line {lineno}: Edge Case 16 {label} '{item}' differs from the pinned '{want}'")
        if (lo != hi) != item.startswith(EC16_RETIRED_PREFIX):
            probs.add(area, f"line {lineno}: Edge Case 16 {label}: only a range entry may be retired, and it must be")
    for key in EC16_KEYS:
        if key not in text:
            probs.add(area, f"line {lineno}: Edge Case 16 lacks the pinned sentence '{key}'")
    # Cross-references: the items cited by number must be the ones meant, and active.
    if ("exclusive group" not in EC16_TEXT.get(EC16_EXCLUSIVE, "") or "story position (Terms) past"
            not in EC16_TEXT.get(EC16_LEGACY, "") or "nothing stored" not in EC16_TEXT.get(EC16_CRISIS, "")
            or "lock order" not in EC16_TEXT.get(EC16_ORDER, "")):
        probs.add(area, "EC16_EXCLUSIVE / _LEGACY / _CRISIS / _ORDER do not point at their active items")
    # Revision 12 (round 12): D7's clause ids are exactly the active ones; the retired ones are named only as retired.
    d7_ids = re.findall(r"\(D7\.(\w+)[;)]", EC16_TEXT.get(7, ""))
    got_d7 = [m for m in re.findall(r"\(D7\.(\w+)[;)]", next((t for lo, hi, t in got if lo == 7), ""))]
    if got_d7 != d7_ids or d7_ids != list(EC16_D7_CLAUSES):
        probs.add(area, f"Edge Case 16 D7 clause ids {got_d7} != the active clauses {list(EC16_D7_CLAUSES)}")
    ec = {num: t for _, num, _, t in items}
    if f"(Edge Case 16, D{EC16_EXCLUSIVE})" not in ec.get(6, ""):
        probs.add(area, f"Edge Case 6 does not cite '(Edge Case 16, D{EC16_EXCLUSIVE})', the exclusive-group item")
    # Revision 12 (round 12): an older save is defaulted before the check, so D16 (not D0) refuses it past a lock.
    for key in ("has its whole lifecycle block filled with the defaults (UNSET, empty, OUTSIDE) before the load check "
                "runs, so D0 meets no missing field but the position",
                f"positioned past a lock scene (chapters 9 and 10 exist in the code today) it is refused by "
                f"D{EC16_LEGACY} as unsupported",
                "A save of the current schema version with a field missing is D0.",
                # Revision 13 (round 13): keyed to the entry scene's position; the legacy position is derived once.
                "Chapter select writes a valid record before its first save for every entry positioned past C8-S16's "
                "commit, keyed to its entry scene's position, not its chapter number (storyline-lifecycle.md Chapter "
                "select), so it never writes one D16 refuses.",
                "its story position is derived once (Terms, Story position; a Chapter 8 save no story scene places "
                "has none and is D0)"):
        if key not in ec.get(8, ""):
            probs.add(area, f"Edge Case 8 lacks '{key}'")
    if "holds only while no player-facing build has a save past Chapter 8" not in ec.get(8, ""):
        probs.add(area, "Edge Case 8 lost the precondition 'holds only while no player-facing build has a save past "
                        "Chapter 8' (design review round 7)")
    # Revision 12 (round 12): Kaelthas is outside the 1.0 companion set in Edge Case 1 too.
    if "Kaelthas is outside the 1.0 companion set" not in ec.get(1, ""):
        probs.add(area, "Edge Case 1 lacks 'Kaelthas is outside the 1.0 companion set'")
    # Round 6 blocker 3: the over-promise guard on clean/negotiated.
    whole = norm(" ".join(lines))
    for key in NO_OVERPROMISE_KEYS:
        if key not in whole:
            probs.add("over-promise", f"storyline-axes.md lacks '{key}'")
    for bad in OVERPROMISE_STRINGS:
        if bad in whole:
            probs.add("over-promise", f"storyline-axes.md promises more than sole_dissent: '{bad}'")
    # AC9 covers exactly the active items, one fixture per clause for the items with several clauses (derived).
    # Revision 11 (round 11): one fixture per clause id, documentation clauses listed (derived).
    want = f"for each clause of each active Edge Case 16 item ({compress_items(EC16_ACTIVE)})"
    if want not in whole:
        probs.add(area, f"AC9 lacks '{want}' (derived from Edge Case 16)")
    want = f"except the clause listed as documentation ({', '.join(EC16_DOC_CLAUSES)}), which has no fixture"
    if want not in whole:
        probs.add(area, f"AC9 does not say '{want}'")
    playable = [p for p in PHASES if p != "DAMAGED"]
    # Revision 10 (round 10, F2): the CRISIS fixture sits inside C8-S16, so D17 fires with D9.
    for want in (f"for one fixture per phase other than DAMAGED ({', '.join(playable)})",
                 f"load_check() is empty for each of those {NUMBER_WORDS[len(playable)]} fixtures except CRISIS, "
                 f"which sits inside C8-S16 and so reports exactly the items {{D{EC16_CRISIS}, D{EC16_ORDER}}}",
                 "a defect may change the several fields that keep the other items satisfied"):
        if want not in whole:
            probs.add(area, f"AC9 lacks '{want}' (derived)")
    # Edge Cases 2, 13 and 15 (revision 9): the Witness leads change nothing; enabling needs the post-1.0 design.
    rules = CTX.get("rules", {})
    first, _ = odd_rule(rules) if rules else ("R1", [])
    n_first = NUMBER_WORDS.get(len(crisis_offers(rules).get(first, ())), "?") if rules else "six"
    witness_unlock = (CTX.get("unlock_flags") or ["?"])[0]  # SECRET_ROUTES order: WITNESS first
    for num, key in ((2, f"{first} at C8-S16 offers only its {n_first} renegotiations, C9-S19 does not play, "
                         f"{witness_unlock} is never set"),
                     (11, "In 1.0 this changes nothing (all routes reserved)"),
                     (13, "a 1.0 build that enables one fails boot validation (AC12)"),
                     (15, "No save exists there before the commit (I9)")):
        if key not in ec.get(num, ""):
            probs.add(area, f"Edge Case {num} lacks '{key}'")


REVISION7_AXES_KEYS = (  # design review round 7 (2026-11-10): the loaded argument, the cut-order question
    # (round 9 removed the seven-seats guard with the Witness route and replaced AC14's baseline; see AXES_AC_KEYS)
    "P3 baseline and the storyline cut order",
    "`loaded` is true for a record just read from a save and false for the live record in play.".replace("`", ""),
)
REVISION7_AXES_FORBIDDEN = ("(D2)", "D2;", "(D3)")
REVISION7_LIFE_KEYS = (
    "loaded false; after a load that passed the check the value is the same either way",
)
# Design review round 9 (2026-11-11): pinned sentences of axes revision 9 outside the Core Rules and Edge Cases.
REVISION9_AXES_KEYS = (
    "The secret routes are post-1.0, so 1.0 ships the 24 and every contradiction is renegotiated.",
    "are post-1.0 and will be designed together as one mechanism (user decision 2026-11-11)",
    "1.0 shows no hint of a door it does not ship",
    # Revision 14 (round 14): story_position joins the stored fields.
    "of the lifecycle fields the record stores the axes, storyline_id, root_phase, axis_revised, lock_negotiated, "
    "retraction_log, beats_played, kaelen_commitment and story_position",   # revision 15 erratum
    "in 1.0 always false: no route is enabled and the record holds no invocation",
    "with the default knobs it never fires.",
    "With the default knobs no secret route is enabled: reachable_1_0: 24.",
    "1.0 ships the 24 valid storylines in three families, and the three secret storylines follow post-1.0 (Open "
    "Question 14)",
    "false until the post-1.0 secret-route design ships",
    "Reference model (round 9 process decision).",
)


def check_revision7(gdd: list[str], life: list[str], probs: Problems) -> None:
    """Design review round 7 pins that survive round 9: the loaded argument, the D-label cleanup, Open Question 13."""
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


def doc_revision(lines: list[str]) -> str | None:
    """The revision number in the document's '> **Status**: Draft (revision N' header line."""
    for line in lines[:12]:
        if m := re.match(r"> \*\*Status\*\*: Draft \(revision (\d+)", line):
            return m[1]
    return None


def check_revision9(gdd: list[str], life: list[str], valid_rows: int, probs: Problems) -> None:
    """Design review round 9: pinned axes sentences; the invariant range everywhere; each doc's Dependencies row
    names the other's current revision; the lifecycle Inputs equal the fields the axes doc says are stored."""
    area = "revision 9"
    whole, life_whole = norm(" ".join(gdd)), norm(" ".join(life))
    for key in REVISION9_AXES_KEYS:
        key = key.replace("reachable_1_0: 24", f"reachable_1_0: {valid_rows + CTX.get('shipped', 0)}")
        if key not in whole:
            probs.add(area, f"storyline-axes.md lacks '{key}'")
    for doc, text in (("axes", whole), ("lifecycle", life_whole)):
        for m in re.finditer(r"\bI1-I(\d+)\b", text):
            if int(m[1]) != len(INVARIANTS):
                probs.add(area, f"{doc} names 'I1-I{m[1]}', but the invariants table has I1-I{len(INVARIANTS)}")
        if not re.search(rf"\bI1-I{len(INVARIANTS)}\b", text):
            probs.add(area, f"{doc} never names the invariants 'I1-I{len(INVARIANTS)}'")
    # Revision 12: the sentence now goes on "; the Edge Case 16 check reads all of them ..." (pinned in revision 12).
    m = re.search(r"of the lifecycle fields the record stores the axes, (.+?); the Edge Case 16 check reads all of them",
                  whole)
    stored = set(AXES) | set(re.findall(r"\w+", m[1].replace(" and ", ", "))) if m else set()
    bounds = section(life, "### Inputs and outputs")
    fields = re.search(r"\(fields (.+?)\)", " ".join(life[bounds[0]:bounds[1]])) if bounds else None
    inputs = set(re.findall(r"`(\w+)`", fields[1])) if fields else set()
    if stored != inputs:
        probs.add(area, f"lifecycle Inputs fields {sorted(inputs)} != the fields storyline-axes.md says the record "
                        f"stores {sorted(stored)}")
    axes_rev, life_rev = doc_revision(gdd), doc_revision(life)
    if axes_rev is None or life_rev is None:
        probs.add(area, "a document has no '> **Status**: Draft (revision N' line")
        return
    header = ("System", "Direction", "What flows")
    axes_row = [cells for _, cells in get_table(gdd, (*header, "Status of its design doc"), area, probs)
                if cells[0].startswith("Storyline lifecycle")]
    life_row = [cells for _, cells in get_table(life, (*header, "Status"), area, probs)
                if cells[0].startswith("Storyline axes")]
    if not axes_row or not axes_row[0][3].startswith(f"revision {life_rev} "):
        probs.add(area, f"axes Dependencies does not give the lifecycle's revision {life_rev}")
    # Revision 15: the cell may carry a parenthesised note after the number ("revision 15 (erratum: ...)").
    if not life_row or not re.fullmatch(rf"revision {axes_rev}( \(.+\))?", life_row[0][3]):
        probs.add(area, f"lifecycle Dependencies does not give the axes revision {axes_rev}")


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


# --- Design review round 12 (2026-11-17): axes revision 12 / lifecycle revision 8 ---------------------------------
REFERENCE_MODEL = Path(__file__).resolve().parent / "reference_model.py"
REVISION12_AXES_KEYS = (
    # Terms: the story position is stored, compared by list index, and is the model's POSITIONS list.
    "The position is the record field story_position (Composer input record), written by each commit checkpoint and "
    "each story-graph step that crosses into the next id, never derived from the current scene file on load; D16 and "
    "D17 compare it by list index, and every id they compare against precedes CH9.",
    "The list is the reference model's POSITIONS (Open Question 16); finer ids (a boss id, for candidate D18) may be "
    "added inside an id, never across one",
    # Core Rule 1: a pre-lifecycle save is written UNSET, then D16 refuses it past a lock scene.
    "SaveService writes UNSET for a new game, and for a save of a schema version before these fields, which the load "
    "check then refuses if it is positioned past a lock scene: Edge Case 16, D16",
    # The phase depends only on three fields once the Edge Case 16 check passes.
    "the Edge Case 16 check reads all of them with the saved flags, and once it passes the phase depends only on "
    "the axes, storyline_id and root_phase.",
    # Open Questions 10, 17, 19 and 20.
    "ch1_knight_spared was proposed for SHARED and dropped, because the Purge path sets it too",
    "RELEASE needs staged verification (PM:7118), while destroying the wraith loses anyone still recoverable "
    "(dialogue/ch2/underground.dlg:64); the user kept the row (2026-11-17).",
    "(D0; D7.duplicate was folded into D0's one-entry cap in revision 12)",
    "19. Kaelthas as a companion (user decision 2026-11-17, design review round 12).",
    "a GDD revision that restores the Archive waiver and its AC11 rows.",
    "20. Review exit criteria — adopted (user decision 2026-11-18, design review round 14; proposed by the "
    "creative-director in round 12).",
)
# Protected touchpoints: the story-progression row names the round-12 additions.
REVISION12_PROTECTED_KEYS = ("the gate on the story path and on every scene change into Root of Heaven",
                             "chapter select past C8-S16 writing a valid record", "the stored story position")
REVISION12_FORBIDDEN = (  # round 11 wording the round-12 revision replaced (both documents)
    "his presence also needs that trust condition", "The axis can only waive a trust test",
    "Elara, Seraphina, Lyra, Kaelthas",
)
# PM:7118 is "Release policy requires staged verification where possible." Round 2 cited it for a claim it does not
# make ("RELEASE ends involuntary preservation"); round 12 cites it for what it says. Every citation must be the latter.
PM7118_CLAIM = "RELEASE needs staged verification (PM:7118)"
PM7118_TEXT = "staged verification"
LIFE_CHAPTER_SELECT_RE = re.compile(
    r"a fixed valid record: (SL-(\w+)-(\w+)-(\w+)) \((\w+), (\w+), (\w+); (\w+) and (\w+) appear in no invalid row\), "
    r"lock_negotiated = \{([^}]*)\}")


def model_positions() -> tuple[str, ...] | None:
    """The reference model's POSITIONS tuple, read from its source without running it (stdlib ast)."""
    import ast
    try:
        tree = ast.parse(REFERENCE_MODEL.read_text(encoding="utf-8"))
    except (OSError, SyntaxError, UnicodeDecodeError):
        return None
    for node in tree.body:
        if isinstance(node, ast.Assign) and any(isinstance(t, ast.Name) and t.id == "POSITIONS" for t in node.targets):
            try:
                return tuple(ast.literal_eval(node.value))
            except ValueError:
                return None
    return None


def check_revision12(gdd: list[str], life: list[str], rules: dict[str, tuple[str, ...]], src: SourceResolver,
                     probs: Problems) -> None:
    """Design review round 12: the story-position list equals the model's POSITIONS; pinned axes sentences; the
    chapter-select record is a valid row outside every invalid row's Authority and Deleted values, BOUND, with all
    three axes negotiated; PM:7118 cited only for what it says; retired round-11 wording absent."""
    area = "revision 12"
    whole, life_whole = norm(" ".join(gdd)), norm(" ".join(life))
    for key in REVISION12_AXES_KEYS:
        if key not in whole:
            probs.add(area, f"storyline-axes.md lacks '{key}'")
    # Terms, Story position: the ordered id list equals the model's POSITIONS.
    m = re.search(r"Story position: the save's place in the story, one id from this ordered list \(earliest first\): "
                  r"(.+?)\. <scene>_OPEN", whole)
    listed = tuple(re.findall(r"\b([A-Z][A-Z0-9_]+)\b(?: \([^)]*\))?(?:,|$)", m[1])) if m else ()
    positions = model_positions()
    if positions is None:
        probs.add(area, f"cannot read POSITIONS from {REFERENCE_MODEL.name}")
    elif listed != positions:
        probs.add(area, f"Terms story positions {list(listed)} != the reference model's POSITIONS {list(positions)}")
    rows = get_table(gdd, H_PROTECTED, area, probs)
    story = next((cells[1] for _, cells in rows if cells[0] == "story progression"), "")
    for key in REVISION12_PROTECTED_KEYS:
        if key not in story:
            probs.add(area, f"protected touchpoints 'story progression' lacks '{key}'")
    for doc, text in (("axes", whole), ("lifecycle", life_whole)):
        for bad in REVISION12_FORBIDDEN:
            if bad in text:
                probs.add(area, f"{doc} still has the round-11 wording '{bad}'")
    # PM:7118: every citation makes the claim the line supports.
    pm = src.pm() or []
    if len(pm) < 7118 or PM7118_TEXT not in pm[7117]:
        probs.add(area, f"PRODUCTION_MASTER_2.1.md:7118 no longer says '{PM7118_TEXT}'")
    for doc, text in (("axes", whole), ("lifecycle", life_whole)):
        if text.count("PM:7118") != text.count(PM7118_CLAIM):
            probs.add(area, f"{doc} cites PM:7118 other than as '{PM7118_CLAIM}'")
    # Lifecycle Chapter select: the fixed record, derived properties.
    m = LIFE_CHAPTER_SELECT_RE.search(life_whole)
    if m is None:
        probs.add(area, "lifecycle Chapter select names no 'a fixed valid record: SL-A-F-D (A, F, D; X and Y appear in "
                        "no invalid row), lock_negotiated = {...}'")
    else:
        sid, a, f, d, a2, f2, d2, x, y, neg = m.groups()
        invalid = set(rules.values())
        if (a, f, d) != (a2, f2, d2) or a not in AUTHORITY or f not in FACTION or d not in DELETED:
            probs.add(area, f"chapter-select record {sid} does not match its axes ({a2}, {f2}, {d2})")
        if (a, f, d) in invalid:
            probs.add(area, f"chapter-select record {sid} is an invalid row")
        in_invalid = {v for triple in invalid for v in triple}
        if {x, y} != {a, d} or x in in_invalid or y in in_invalid:
            probs.add(area, f"chapter select says {x} and {y} appear in no invalid row; the rules table "
                            f"{sorted(invalid)} disagrees or they are not the record's Authority and Deleted values")
        if {v.strip() for v in neg.split(",")} != set(AXES):
            probs.add(area, f"chapter-select lock_negotiated {{{neg}}} != all three axes (no lock vote was played)")
        fam = FAMILY_BY_AUTHORITY.get(a, "?")
        if f"its ending is {fam} without sole_dissent" not in life_whole:
            probs.add(area, f"chapter select does not say 'its ending is {fam} without sole_dissent' (family of {a})")
        if f"L-AC19" in life_whole and f"storyline_id() {sid}" not in life_whole:
            probs.add(area, f"L-AC19 does not expect storyline_id() {sid}, the chapter-select record")


# --- Design review round 13 (2026-11-17): axes revision 13 / lifecycle revision 9 ---------------------------------
# Side-storyline secondary effects, pinned (revision 13: arc 08's Quest 48 faction effect, PM:3681-3682).
SIDE_SECONDARY = {"06": "faction:HEARTH", "07": "faction:ARCHIVE", "08": "faction:*", "12": "deleted:CHOOSE"}
REVISION13_AXES_KEYS = (
    # Terms: the other position writers, and the one exception to "never derived".
    "The other writers are a new game and the NG+ reset (PRE_C8) and chapter select (the position of its entry scene; "
    "storyline-lifecycle.md Chapter select).",
    "One exception to \"never derived\": a save of a schema version before these fields holds no position, so "
    "SaveService derives it once, while defaulting that save (Edge Case 8), in this order",
    # Tuning Knobs: the one statement of where knobs are read.
    "Knobs are read in exactly two places, and this is the one statement of where",
    "and secret_prerequisites[FIRSTWAKE] at C9-S18, to choose its decrypted or noise form (Core Rule 6), which sets no "
    "field and changes no ID.",
    "Knobs are read only where Tuning Knobs states.",
    # Side storylines: arc 08 pushes Faction in 1.0.
    "Arc 08 feeds Crownless and also pushes Faction in 1.0",
    "P5 (\"side storylines feed the main story\") is to be met in 1.0 by the ten arcs that push an axis",
    # Citations fixed in round 13.
    "AethelgardPrototype/scripts/chapter3/ch3_kaelthas_betrayal.gd:157-161",
    "This GDD uses 3 of the 4 (Elara, Seraphina, Lyra); Kaelthas is reserved",
    "and a pairwise minimum of 2 scenes (rounds 11 and 12)",
    "DAMAGED inside C8-S16 before its commit (D9 and D17: a valid row is not live_crisis).",
)
REVISION13_AXES_FORBIDDEN = (
    "someone must be answerable",   # verbatim at neither PM:636 nor PM:7048
    "This GDD uses the 4",
    "pairwise minimum of 1 scene",
    "Elara's rebuke",
    "(PM:788; Core Rule 11",
    "beats_played sixteen",
    "Knobs are read only at C8-S16 and the gate",
)
REVISION13_LIFE_KEYS = (
    "true exactly when an ID is stored and the phase is not DAMAGED",
    "or a live DAMAGED record (a defect, turned back as a data error, S6)",
    "story_position → PRE_C8. The story position is reset with the record because a new record left at a Story+ "
    "position would be refused by D16",
    "OLD_HOME_MESSAGE is set in the Chapter 3 End ledger (PM:3814), not by arc 09's own quests (PM:3685-3707)",
    # Lifecycle revision 11 (item 11) reworded L-AC15; its NG+ start and the position reset are kept.
    "Starting NG+ from a FINAL record positioned at STORY_PLUS in which every field holds a non-default value",
    "the story position PRE_C8 among them",
)
REVISION13_LIFE_FORBIDDEN = (
    "(arc 09, PM:3814)",
    "Knobs are read only at C8-S16 and the gate",
    "For Chapter 8 or earlier",
)


def check_revision13(gdd: list[str], life: list[str], probs: Problems) -> None:
    """Design review round 13: pinned sentences of axes revision 13 and lifecycle revision 9, retired wording absent,
    and the side-storyline secondary column pinned (arc 08's faction effect)."""
    area = "revision 13"
    whole, life_whole = norm(" ".join(gdd)), norm(" ".join(life))
    for key in REVISION13_AXES_KEYS:
        if key not in whole:
            probs.add(area, f"storyline-axes.md lacks '{key}'")
    for bad in REVISION13_AXES_FORBIDDEN:
        if bad in whole:
            probs.add(area, f"storyline-axes.md still says '{bad}' (retired in revision 13)")
    for key in REVISION13_LIFE_KEYS:
        if key not in life_whole:
            probs.add(area, f"storyline-lifecycle.md lacks '{key}'")
    for bad in REVISION13_LIFE_FORBIDDEN:
        if bad in life_whole:
            probs.add(area, f"storyline-lifecycle.md still says '{bad}' (retired in lifecycle revision 9)")
    for lineno, (arc, _title, _primary, secondary, _scope, _pm) in get_table(gdd, H_SIDE, area, probs):
        want = SIDE_SECONDARY.get(arc)
        if (want is None and not is_dash(secondary)) or (want is not None and secondary != want):
            probs.add(area, f"line {lineno} (arc {arc}): secondary '{secondary}', expected {want or '—'}")


# --- Design review round 14 (2026-11-18): axes revision 14 / lifecycle revision 10 --------------------------------
# Scope frozen to the six round-14 blockers (Open Question 20, adopted) and Open Question 21's class.
REVISION14_AXES_KEYS = (
    # Blocker 1: the purge row rests on its own scene; PM:663 is not cited for it.
    "because Kaelen rewrites Aldric before he can say what it will cost",
    "(dialogue/ch1/aldric.dlg:104-107). PM:663 is not cited for this row: the purge leaves Aldric lucid "
    "(dialogue/ch1/aldric.dlg:119-122)",
    "ch1_root_purge → YOU − rests on dialogue/ch1/aldric.dlg:104-107 (revision 14)",
    # Blocker 2: the legacy derivation order; hubs are not in the map; a Chapter 8 save is refused.
    "free-travel story scene, else its own scene, each through the scene-to-id map, which holds story scenes only and "
    "never a hub",
    "else its chapter number, below 8 → PRE_C8 and 9 or above → CH9. A Chapter 8 save that no mapped story scene "
    "places is left with no position, which D0 refuses (user decision 2026-11-18, design review round 14).",
    "SaveService (Y1-P1-T05) carries the stored position on every save the code writes",
    # Blocker 6: a secret-only flag's push.
    "A flag that feeds only a post-1.0 secret route (Core Rule 6) pushes secret:<route> with direction 0 and no",
    "every one of them has a seed-map row with a pushes target (an axis, a modifier, timing or secret:<route>",
    # Open Question 21: main-story seeds.
    "and so do main-story choices after Act 1 (main-story seeds; the first known is the Chapter 4 Null Court promise",
    "21. Main-story seeds (user decision 2026-11-18, design review round 14).",
    "the seed map and its 26-flag list are unchanged until then.",
    # Open Question 20 adopted.
    "Round 15 runs lean on the revision-14 diff and the model log",
)
REVISION14_AXES_FORBIDDEN = (
    "which PM:663 names as the condition of his support",     # inverts its source (round 14, narrative-director)
    "a rewrite of a person done without his consent",       # not in aldric.dlg:57
    "a rewrite of Aldric without his consent",
    "is resolved by revision 13",
    "a scene the map does not hold leaves the field missing",  # position was not a record field (round 14)
    "except for modules module_keys() keys to a Faction mirror flag",   # contradicts Core Rule 3 and AC14
    "renames its beat to match",                              # yields {D7.new_mismatch, D14.undefined} on Faction
    "proposed, not yet adopted by the user",
)
REVISION14_LIFE_KEYS = (
    "the free-travel story scene, else the save's own scene, through the scene-to-id map, which holds no hub; else "
    "the chapter number. A Chapter 8 save that no story scene places is left with no position, which D0 refuses "
    "(D0.missing).",
)
REVISION14_LIFE_FORBIDDEN = ("a scene the map lacks leaves the field missing",)


def check_revision14(gdd: list[str], life: list[str], probs: Problems) -> None:
    """Design review round 14: pinned sentences of axes revision 14 and lifecycle revision 10, retired wording
    absent."""
    area = "revision 14"
    whole, life_whole = norm(" ".join(gdd)), norm(" ".join(life))
    for key in REVISION14_AXES_KEYS:
        if key not in whole:
            probs.add(area, f"storyline-axes.md lacks '{key}'")
    for bad in REVISION14_AXES_FORBIDDEN:
        if bad in whole:
            probs.add(area, f"storyline-axes.md still says '{bad}' (retired in revision 14)")
    for key in REVISION14_LIFE_KEYS:
        if key not in life_whole:
            probs.add(area, f"storyline-lifecycle.md lacks '{key}'")
    for bad in REVISION14_LIFE_FORBIDDEN:
        if bad in life_whole:
            probs.add(area, f"storyline-lifecycle.md still says '{bad}' (retired in lifecycle revision 10)")


def composer_stored_fields() -> dict[str, tuple[str, frozenset[str] | str]]:
    """The composer record's stored fields (combined keys split), name -> (type, allowed); derived fields dropped."""
    out = {}
    for key, (typ, allowed, writer) in COMPOSER.items():
        if "never stored" in writer:
            continue
        for name in key.split(","):
            out[name.strip()] = (typ, allowed)
    return out


# --- Lifecycle review 2026-11-18: lifecycle revision 11 / axes revision 15 (erratum) ---------------------------------
# Scope frozen to the review's 13 blockers (lifecycle Open Question 7, adopted 2026-11-19).
H_CHAPTER_SELECT = ("#", "entry", "entry scene", "record", "position of the first save", "root_phase at the first save",
                    "then")
H_PLACEMENT = ("scene", "source scenes", "story position", "Root of Heaven scene set", "status")
H_WRITERS = ("position", "written by")
H_WINDOWS = ("#", "window opens", "window closes (the commit)", "the checkpoint holds",
             "a quit inside the window reloads", "a reload of the checkpoint resumes at",
             "never replays after the commit")
H_LANDINGS = ("path", "LEANING, PARTLY_LOCKED", "DAMAGED (a live record)")
SUPERSEDED_SCENES = {"ch8_revolt_crisis": "AethelgardPrototype/scripts/chapter8/ch8_revolt_crisis.gd",
                     "ch10_sovereign_confrontation": "AethelgardPrototype/scripts/chapter10/ch10_sovereign_confrontation.gd"}
NO_CHAPTER_SELECT_POSITIONS = ("S13_OPEN", "S13_DONE", "S14_OPEN", "S14_DONE", "S15", "S16_OPEN", "FINAL_AUTH_OPEN")
LOAD_GATE_SENTENCE = ("A save is positioned inside Root of Heaven when its position is ROOT, FINAL_DONE or "
                      "ROOT_STORY_PLUS (FINAL_AUTH_OPEN is never saved, I9)")
# The positions whose writers the review named as missing (item 2).
NAMED_WRITERS = ("CH9", "ROOT_LEFT", "FINAL_AUTH_OPEN", "STORY_PLUS", "ROOT_STORY_PLUS")
COMMITMENT_QUOTES = {"LISTEN": ("I LISTEN.", 7055), "OVERRIDE_IMMEDIATE_LOSS": ("I OVERRIDE ONLY TO PREVENT "
                                                                              "IMMEDIATE LOSS.", 7056),
                     "CANNOT_PROMISE_NEVER": ("I CANNOT PROMISE NEVER.", 7057)}
# Prose that names an observable without calling it (item 6): pattern -> the observable the L-AC must then call.
PROSE_OBSERVABLES = (
    (r"\bstory position\b", "record_field"),
    (r"\bregion\b[^.;]*\b(?:locked|unlocked)\b", "region_unlocked"),
    (r"\bcheckpoint exists\b|\bevery save written\b|\bfirst save of the new cycle\b", "saves_written"),
    (r"\bC9-S18 plays\b|\bnoise form\b|\bdecrypted form\b", "c9s18_form"),
    (r"\block scene plays\b|\bscenes? played\b", "scenes_played"),
    (r"\bdata error (?:is )?logged\b|\blogs? a data error\b", "data_errors"),
)
REVISION15_LIFE_KEYS = (
    # Item 2: hub revival and the writers.
    "Hub revival. A death in a Root of Heaven scene revives the player in a hub",
    "That is a scene change out of the set: it writes ROOT_LEFT (STORY_PLUS when root_phase is FINAL), changes no other "
    "field and never runs the gate",
    LOAD_GATE_SENTENCE,
    # Item 3: chapter select's checkpoint is an outcome; the mechanism is routed.
    "Nothing is saved from the main menu (the save API refuses there, game_manager.gd:1441); which code writes the "
    "record, and when SaveService first saves it, is Y1-P1-T05's.",
    # Item 5.
    "Because take() goes through the T5 handler, the test fails if the handler takes an offer outside the crisis",
    # Item 8.
    "T2 writes the choice to kaelen_commitment (user decision 2026-11-19), and it is the answer SOVEREIGN quotes "
    "exactly (PM:7059) unless it is later withdrawn.",
    "When a renegotiation withdraws YOU, kaelen_commitment keeps the C8-S14 choice and quoted_commitment() reads "
    "WITHDRAWN.",
    # Item 9.
    "answered by the refusing faction's delegate; Kaelen, whose position it was, never answers his own retraction",
    "and that speaker is the refusing faction's delegate — R1 the Hearth delegate, R2 the Archive delegate, R3 the "
    "Continuity delegate",
    "so the rule holds for any cast",
    # Item 10.
    "It reads the knobs of storyline-axes.md only where that document's Tuning Knobs says, the one statement of where "
    "they are read; this document keeps no list of its own",
    # Item 11.
    "every stored field of the composer record (storyline-axes.md Composer input record) is set to a new game's "
    "default, so the new cycle's record equals a new game's field for field",
    # Item 7: the Validation note agrees with L-AC8.
    "and the load cell of VALIDATED, run from a fixture save) count and are listed as synthetic in the run report; the "
    "live-DAMAGED and live invalid-row checks of L-AC8 are unit-level, outside the 10 counted cells",
    # Item 13: citations.
    "before PM:8206-8207 \"Root of Heaven gate opens\"",
    "the RESTORE hearing's unresolved consent argument, PM:7102-7106, is context for how a Deleted concession is "
    "voiced, not a source for brokering",
    "Kaelen answers for the role (PM:7045-7053) and the player chooses his commitment from the source's three "
    "variants (PM:7054-7058)",
    # Open Question 7: the freeze.
    "7. Review exit criteria — adopted (user decision 2026-11-19, after the lifecycle review of 2026-11-18",
)
REVISION15_LIFE_FORBIDDEN = (
    "answered by the person whose position it was",
    "the delegate or companion whose position is withdrawn",
    "before any loaded state is applied",
    "as one atomic checkpoint before its entry scene loads",
    "only at C8-S16 and the gate",
    "(C8-S16, the gate, and C9-S18's form)",
    "skipped or saved until an offer",
    "VALIDATED-on-load checks of L-AC8 are unit-level",
    "PM:7045-7057",
    "(PM:7102-7106, 7141)",
    "CH9 for Chapter 9 and for every entry into Root of Heaven",
)
REVISION15_AXES_KEYS = (
    "C9-S18 in the form Core Rule 6 states, decrypted and logged with every FIRSTWAKE prerequisite set and noise "
    "otherwise",
    "a YOU record with kaelen_commitment UNSET (D0.enum)",
    "the round-15 approval of revision 14 does not cover these lines",
)
REVISION15_AXES_FORBIDDEN = ("C9-S18 incomplete form",)


def main_menu_entries(root: Path) -> list[tuple[str, str]]:
    """(label, scene basename) of every Chapter 8-10 chapter-select entry in main_menu.gd, in file order."""
    path = root / "AethelgardPrototype/scripts/main_menu.gd"
    try:
        text = path.read_text(encoding="utf-8")
    except OSError:
        return []
    out = []
    for m in re.finditer(r'"label": "(Chapter (?:8|9|10) - [^"]+)",\s*\n\s*"desc": "[^"]*",\s*\n\s*'
                         r'"scene": "res://scenes/[\w/]+/(\w+)\.tscn"', text):
        out.append((m[1], m[2]))
    return out


def check_revision15(gdd: list[str], life: list[str], src: SourceResolver, root: Path, probs: Problems) -> None:
    """Lifecycle review 2026-11-18 (13 blockers): the chapter-select rows against main_menu.gd, the scene placement
    table against the scene files, the position writers against the model's POSITIONS, the window table against the
    checkpoint transitions, the landings per path, the commitment values against the source, the observables lint,
    pinned and retired wording in both documents."""
    area = "revision 15"
    whole, life_whole = norm(" ".join(gdd)), norm(" ".join(life))
    for key in REVISION15_LIFE_KEYS:
        if key not in life_whole:
            probs.add(area, f"storyline-lifecycle.md lacks '{key}'")
    for bad in REVISION15_LIFE_FORBIDDEN:
        if bad in life_whole:
            probs.add(area, f"storyline-lifecycle.md still says '{bad}' (retired in lifecycle revision 11)")
    for key in REVISION15_AXES_KEYS:
        if key not in whole:
            probs.add(area, f"storyline-axes.md lacks '{key}'")
    for bad in REVISION15_AXES_FORBIDDEN:
        if bad in whole:
            probs.add(area, f"storyline-axes.md still says '{bad}' (retired in revision 15)")
    if re.search(r"PM:8206(?!-8207)", life_whole):
        probs.add(area, "lifecycle cites PM:8206 alone; the gate line is PM:8206-8207")
    positions = model_positions() or ()
    # Item 2: the scene placement table covers every Chapter 8-10 scene file; superseded scenes are marked.
    placement = get_table(life, H_PLACEMENT, area, probs)
    by_scene = {}
    for lineno, (scene, _src_scenes, pos, in_root, status) in placement:
        m = re.match(r"chapter(?:8|9|10)/(\w+)\.tscn$", scene)
        if m:
            by_scene[m[1]] = (lineno, pos, in_root, status)
        first = pos.split()[0] if pos and not is_dash(pos) else ""
        if first.startswith(("PRE_", "S1", "CH", "ROOT", "FINAL", "STORY")) and first not in positions:
            probs.add(area, f"line {lineno}: placement position '{first}' is not one of the model's POSITIONS")
        root_pos = first in ("ROOT", "FINAL_AUTH_OPEN", "FINAL_DONE", "ROOT_STORY_PLUS")
        if first and (in_root.startswith("yes") != root_pos):
            probs.add(area, f"line {lineno}: '{scene}' at {first} is {'not ' if root_pos else ''}a Root of Heaven "
                            f"position but its set cell says '{in_root}'")
    for chapter in ("chapter8", "chapter9", "chapter10"):
        for path in sorted((root / "AethelgardPrototype/scenes" / chapter).glob("*.tscn")):
            if path.stem not in by_scene:
                probs.add(area, f"scene placement table lacks {chapter}/{path.name}")
    for stem, script in SUPERSEDED_SCENES.items():
        row = by_scene.get(stem)
        if row is None or not row[3].startswith("superseded") or Path(script).name not in row[3]:
            probs.add(area, f"scene placement does not mark {stem} superseded with its script {Path(script).name}")
        if not (root / script).exists():
            probs.add(area, f"superseded script {script} does not exist")
    # The legacy-flags row already cites ch8_revolt_crisis.gd for its flags, so the scene's retirement is pinned as
    # its own phrase (a bare file-name search passed with the phrase dropped).
    deps = section(life, "## Dependencies")
    want = ("the scenes of " + " and ".join(Path(p).name for p in SUPERSEDED_SCENES.values())
            + ", superseded (Scene placement)")
    if deps is None or want not in norm(" ".join(life[deps[0]:deps[1]])):
        probs.add(area, f"lifecycle Dependencies lacks '{want}'")
    # Item 2: every position has a writer row; the review's five named ones are non-empty.
    writers = get_table(life, H_WRITERS, area, probs)
    named = [p.strip() for _, (cell, _w) in writers for p in cell.split(",")]
    if positions and sorted(named) != sorted(positions):
        probs.add(area, f"position-writer table names {sorted(named)}, expected the model's POSITIONS "
                        f"{sorted(positions)}")
    for _, (cell, writer) in writers:
        if any(p.strip() in NAMED_WRITERS for p in cell.split(",")) and (not writer or is_dash(writer)):
            probs.add(area, f"position '{cell}' has no writer")
    # Item 1: one chapter-select row per main_menu.gd Chapter 8-10 entry, in order.
    entries = main_menu_entries(root)
    rows = get_table(life, H_CHAPTER_SELECT, area, probs)
    if len(entries) != 13:
        probs.add(area, f"main_menu.gd has {len(entries)} Chapter 8-10 entries, expected 13")
    if len(rows) != len(entries):
        probs.add(area, f"chapter-select table has {len(rows)} rows, main_menu.gd {len(entries)} Chapter 8-10 entries")
    for (lineno, (num, entry, scene, record, pos, root_phase, then)), (label, stem) in zip(rows, entries):
        where = f"line {lineno} (row {num})"
        if not entry.startswith(label):
            probs.add(area, f"{where}: entry '{entry}' is not main_menu.gd's '{label}'")
        if stem in SUPERSEDED_SCENES:
            if f"was {stem}, superseded" not in scene:
                probs.add(area, f"{where}: {stem} is superseded, but the row does not reroute it")
        elif not scene.startswith(stem):
            probs.add(area, f"{where}: entry scene '{scene}' is not main_menu.gd's {stem}")
        first = pos.split()[0]
        # The position chapter select writes, when it differs from the first save's: "(chapter select writes X".
        m = re.search(r"chapter select writes (\w+)", pos)
        written = m[1] if m else first
        for p_ in (first, written):
            if positions and p_ not in positions:
                probs.add(area, f"{where}: position '{p_}' is not one of the model's POSITIONS")
        if written in NO_CHAPTER_SELECT_POSITIONS:
            probs.add(area, f"{where}: chapter select may not start at {written}")
        target = scene.split(",")[0].split(" ")[0]
        placed = by_scene.get(target)
        in_root = placed is not None and placed[2].startswith("yes")
        if in_root and "enters through the gate" not in then:
            probs.add(area, f"{where}: {target} is a Root of Heaven scene but the row does not enter through the gate")
        if placed is not None and placed[1].split()[0] != first:
            probs.add(area, f"{where}: first save at {first}, but the placement table puts {target} at "
                            f"{placed[1].split()[0]}")
        want_rp = "FINAL" if first == "FINAL_DONE" else "INSIDE" if first == "ROOT" else "OUTSIDE"
        if root_phase.split()[0] != want_rp:
            probs.add(area, f"{where}: root_phase at the first save '{root_phase}', expected {want_rp} at {first}")
        if written == "PRE_C8" and not record.startswith("defaults"):
            probs.add(area, f"{where}: a PRE_C8 entry must start from the defaults")
        if written != "PRE_C8" and not record.startswith("fixed"):
            probs.add(area, f"{where}: an entry past C8-S16 must write the fixed record")
    # Item 4: the window table has exactly the checkpoint transitions, every cell filled, distinct resume points.
    windows = get_table(life, H_WINDOWS, area, probs)
    ids = [cells[0] for _, cells in windows]
    ckpt = CTX.get("checkpoints", [])
    if ckpt and ids != list(ckpt):
        probs.add(area, f"window table rows {ids} != the checkpoint transitions {list(ckpt)}")
    resumes = [cells[5] for _, cells in windows]
    if len(set(resumes)) != len(resumes):
        probs.add(area, f"window table resume points are not distinct: {resumes}")
    for lineno, cells in windows:
        if any(not c or is_dash(c) for c in cells):
            probs.add(area, f"line {lineno}: window table row {cells[0]} has an empty cell")
    # Item 12: a landing for every path.
    landings = get_table(life, H_LANDINGS, area, probs)
    for path in ("story", "world_map", "load"):
        if not any(cells[0] == path or cells[0].startswith(path + " ") for _, cells in landings):
            probs.add(area, f"landing table has no row for the {path} path")
    for lineno, cells in landings:
        if any(not c or is_dash(c) for c in cells):
            probs.add(area, f"line {lineno}: landing row '{cells[0]}' has an empty cell")
    # Item 5: take() goes through the production T5 handler.
    take = [cells for _, cells in get_table(life, H_LIFE_OBSERVABLES, area, probs) if cells[0] == "take(offer)"]
    if not take or "production T5 handler" not in take[0][1]:
        probs.add(area, "take(offer) does not go through the production T5 handler")
    # Item 8: the commitment values are the composer's and quote the source lines.
    allowed = COMPOSER.get("kaelen_commitment", ("", "", ""))[1]
    pm = src.pm() or []
    for value, (quote, line) in COMMITMENT_QUOTES.items():
        if value not in str(allowed):
            probs.add(area, f"composer kaelen_commitment lacks {value}")
        if f'{value} ("{quote}")' not in life_whole:
            probs.add(area, f"lifecycle S2 does not give {value} with its source line \"{quote}\"")
        if line > len(pm) or pm[line - 1].strip() != quote:
            probs.add(area, f"PRODUCTION_MASTER_2.1.md:{line} is not \"{quote}\"")
    # Item 6: every observable an L-AC uses is in the table, called or named in prose.
    allowed_obs = observables(life, H_LIFE_OBSERVABLES, area, probs)
    bounds = section(life, "## Acceptance Criteria")
    acs: dict[int, list[str]] = {}
    current = None
    for line in life[bounds[0]:bounds[1]] if bounds else []:
        if m := re.match(r"^- \*\*L-AC(\d+) ", line):
            current = int(m[1])
            acs[current] = [line]
        elif current is not None and line.startswith("  "):
            acs[current].append(line)
        else:
            current = None
    for number, body in sorted(acs.items()):
        text = norm(" ".join(body))
        for call in re.findall(r"(?<![\w.-])(\w+)\(", text):
            if call not in allowed_obs:
                probs.add(area, f"L-AC{number} calls '{call}()', which the Observables table does not list")
        for pattern, obs in PROSE_OBSERVABLES:
            if re.search(pattern, text) and f"{obs}(" not in text:
                probs.add(area, f"L-AC{number} names '{re.search(pattern, text)[0]}' without calling {obs}()")


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
    # Revision 9: the Observables table is pinned row by row (first column).
    obs = [cells[0] for _, cells in get_table(lines, H_OBSERVABLES, area, probs)]
    if tuple(obs) != AXES_OBSERVABLES:
        probs.add(area, f"Observables table {obs} != the pinned {list(AXES_OBSERVABLES)}")
    for number, text in sorted(texts.items()):
        if number >= FIRST_RUNTIME_AC:
            # AC5 may name the formula its cases detect, in the one pinned phrase (see AC5_FORMULA_MENTION).
            scan = text.replace(AC5_FORMULA_MENTION, "") if number == 5 else text
            check_blocked_and_calls(f"AC {number}", scan, allowed, area, probs)
            m = re.search(r"\*Blocked by:\*\s*(.+)$", text)
            named = set(STORY_RE.findall(m[1])) if m else set()
            if number in AXES_AC_BLOCKED and named != AXES_AC_BLOCKED[number]:
                probs.add(area, f"AC {number}: blocked by {sorted(named)}, pinned {sorted(AXES_AC_BLOCKED[number])}")
    reach = valid_rows + CTX.get("shipped", 0)
    for number, keys in AXES_AC_KEYS.items():
        for key in keys:
            key = key.replace("{reach}", str(reach))
            if key not in norm(texts.get(number, "")):
                probs.add(area, f"AC {number} lacks '{key}'")
    for number, bads in AXES_AC_FORBIDDEN.items():
        for bad in bads:
            if bad in norm(texts.get(number, "")):
                probs.add(area, f"AC {number} has the retired wording '{bad}' (design review round 12)")
    rt = next((n for n, line in enumerate(lines) if line.startswith("**Runtime — each criterion names")), None)
    runtime = []
    for line in lines[rt:] if rt is not None else []:
        if not line.strip():
            break
        runtime.append(line)
    for key in AXES_RUNTIME_KEYS:
        if key not in norm(" ".join(runtime)):
            probs.add(area, f"the Runtime paragraph lacks '{key}' (story types and gates)")
    route_rule = CTX.get("route_rule", {})
    want = "(" + ", ".join(f"{route} on {rule}" for route, rule in sorted(route_rule.items(), key=lambda x: x[1])) + ")"
    if want not in norm(texts.get(5, "")):
        probs.add(area, f"AC 5 lacks '{want}' (derived from the secret table)")
    bounds = section(lines, "## Acceptance Criteria")
    header = norm(" ".join(lines[bounds[0]:bounds[1]])) if bounds else ""
    for key in AXES_DOC_AC_KEYS:
        if key not in header:
            probs.add(area, f"Acceptance Criteria lack '{key}'")
    for key in (f"the invariants table has rows I1-I{len(INVARIANTS)} as pinned",
                f"the Core Rules are numbered 1-{len(CORE_RULE_TITLES)}",
                f"the Tuning Knobs table has exactly the {NUMBER_WORDS[len(KNOBS)]} pinned knobs"):
        if key not in norm(texts.get(4, "")):
            probs.add(area, f"AC 4 lacks '{key}' (derived)")
    # AC5's case counts, from the axis vocabularies and the table.
    triples = (len(AUTHORITY) + 1) ** 3
    want5 = (f"({triples} triples)", f"({triples * 2} cases)", f"the {valid_rows} valid triples",
             f"the {triples - 27} triples with an UNSET axis", f"the {len(rules)} invalid triples")
    for key in want5:
        if key not in norm(texts.get(5, "")):
            probs.add(area, f"AC 5 lacks '{key}' (derived from the vocabularies and the table)")
    if f"the {SEED_FLAG_COUNT} seed flags" not in norm(texts.get(10, "")):
        probs.add(area, f"AC 10 does not say 'the {SEED_FLAG_COUNT} seed flags'")


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
    stored_fields = composer_stored_fields()
    for field in inputs:
        if field not in stored_fields:
            probs.add(area, f"Inputs field '{field}' is not a stored composer record field")
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
        if field not in stored_fields:
            probs.add(area, f"NG+ reset field '{field}' is not a stored composer record field")
            continue
        typ, allowed = stored_fields[field]
        has_unset = (isinstance(allowed, frozenset) and UNSET in allowed) or (isinstance(allowed, str)
                                                                             and allowed.startswith("UNSET"))
        want = ("UNSET" if has_unset else ROOT_PHASES[0] if field == "root_phase"
                else "PRE_C8" if field == "story_position" else "false" if typ == "bool" else "empty")
        if default != want:
            probs.add(area, f"NG+ reset {field} → '{default}', expected '{want}'")
    # Lifecycle revision 11 (review 2026-11-18, item 11): the reset names every stored field, not only the Inputs.
    if set(stated) != set(stored_fields):
        probs.add(area, f"NG+ reset fields {sorted(stated)} != the composer record's stored fields "
                        f"{sorted(stored_fields)}")


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
    """The crisis offer table equals crisis_offers computed from invalid(); no secret-route offer on any row."""
    area = "crisis offers"
    offers = crisis_offers(rules)
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
        # Revision 9: the secret routes are post-1.0, so no row offers a deferral or an invocation.
        if defers := [o for o in stated if not o.startswith("revise:")]:
            probs.add(area, f"line {lineno} ({rule}): non-renegotiation offers {defers}; 1.0 offers renegotiations only")
        if re.sub(r"`?revise:\w+:\w+`?|,|\s", "", cell):
            probs.add(area, f"line {lineno} ({rule}): offers cell holds more than the renegotiation offers: '{cell}'")
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
    _, others = odd_rule(rules)
    if len(others) == 2:
        shared = len(offers[others[0]] & offers[others[1]])
        want = f"{others[0]} and {others[1]} share {NUMBER_WORDS[shared]} offers"
        if want not in text:
            probs.add(area, f"Retractions do not say '{want}' (derived from invalid())")
    # Revision 5: the content-scope table's counts are derived (beats, red lines, epilogue lines).
    want_counts = {"retraction beats retract_*": str(total), "red lines": str(len(rules)), "sole_dissent": "1",
                   "c9s18_logged": "1",  # revision 11 (round 11): C9-S18's decrypted form
                   "arc epilogue lines": str(len(POST_1_0_ARCS))}
    got_counts = {cells[0]: cells[1] for _, cells in get_table(life, H_CONTENT, area, probs)}
    if got_counts != want_counts:
        probs.add(area, f"content scope table counts {got_counts} != derived {want_counts}")
    if f"one shared text per (axis, new value) behind the {total} ids" not in text:
        probs.add(area, f"cut order does not say 'one shared text per (axis, new value) behind the {total} ids'")


def check_gate_table(life: list[str], gates: dict[str, str], probs: Problems) -> None:
    """Gate outcomes as pinned and derived from the axes phase table; each gated phase once; T refs match."""
    area = "gate"
    rows = get_table(life, H_GATE, area, probs)
    covered: list[str] = []
    for lineno, (phases_cell, outcome) in rows:
        phases = [p.strip().removesuffix(LIVE_QUALIFIER) for p in phases_cell.split(",")]
        covered += phases
        token = re.match(r"[A-Z_]+", outcome)
        for phase in phases:
            if phase not in PHASES:
                probs.add(area, f"line {lineno}: '{phase}' is not a phase of storyline-axes.md")
                continue
            if phase in LIVE_GATED:  # revision 10: only a live record reaches the gate in this phase
                if LIVE_QUALIFIER not in phases_cell or LIVE_GATED[phase] not in gates.get(phase, ""):
                    probs.add(area, f"line {lineno} ({phase}): the gate row needs '{LIVE_QUALIFIER.strip()}' and the "
                                    f"axes phase table gate '{LIVE_GATED[phase]}', got '{gates.get(phase)}'")
                if token is None or token[0] != "TURNED_BACK":
                    probs.add(area, f"line {lineno} ({phase}): a live record at the gate is TURNED_BACK")
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
    if sorted(cells[0] for _, cells in rows) != sorted(GATE_TABLE):
        probs.add(area, f"gate table rows {[cells[0] for _, cells in rows]} != the pinned {list(GATE_TABLE)}")
    gated = [p for p in PHASES if gate_outcome(gates.get(p, "")) is not None or p in LIVE_GATED]
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
            if phase in STORED_PHASES and target == "CRISIS":
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
    for phase in ("CRISIS",):
        if not any(frm == phase and to == "VALIDATED" and "enabled" not in guard for _, frm, to, guard in edges):
            probs.add(area, f"{phase} has no transition to VALIDATED that holds under every knob value (I5)")
    # The gate runs from every phase except the one that exists only inside C8-S16 (I4), once each.
    gated = [p for p in PHASES if p not in UNGATED_PHASES]
    if sorted(entry_from) != sorted(gated):
        probs.add(area, f"'{GATE_EVENT}' transitions start from {entry_from}, expected each of {gated} once")
    # Revision 9 (I9): every record-writing transition states its checkpoint; the checkpoint set is the same in the
    # table, the commit and save rule's list and L-AC6.
    ckpt = []
    for lineno, cells in rows:
        effects = cells[5]
        if effects in ("TURNED_BACK", "open"):
            continue
        if not effects.endswith(CHECKPOINT):
            probs.add(area, f"line {lineno} ({cells[0]}): writes the record but states no checkpoint (I9)")
        elif not effects.endswith(NO_CHECKPOINT):
            ckpt.append(cells[0])
    CTX["checkpoints"] = ckpt
    text = norm(" ".join(life))
    m = re.search(r"Every transition of the table below that ends a scene's open state \(([^)]*)\)", text)
    if m is None or [t.strip() for t in m[1].split(",")] != ckpt:
        probs.add(area, f"the commit and save rule's transition list {m[1] if m else None} != the table's checkpoint "
                        f"transitions {ckpt}")


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
    first, others = odd_rule(rules)
    c1 = len(offers.get(first, ()))
    c2 = len(offers[others[0]]) if others else 0
    total = sum(len(v) for v in offers.values())
    want = (f"|crisis_offers| is {c1} for {first} and {c2} for {' and '.join(others)}, so {total} renegotiation "
            "offers in all; |crisis_offers| is 0 for every valid row.")
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
    witness_rule, _ = odd_rule(rules)
    want = NUMBER_WORDS.get(len(offers.get(witness_rule, ())))
    words = "|".join(NUMBER_WORDS.values())
    for lineno, line in enumerate(lines, 1):
        for m in re.finditer(rf"\bthe ({words}) (?:{witness_rule} )?(?:renegotiations|offers)\b", line):
            if m[1] != want:
                probs.add("counts", f"{doc} line {lineno}: '{m[0]}', but {witness_rule} has {want} offers")


def check_life_acs(life: list[str], valid_rows: int, rules: dict[str, tuple[str, ...]], probs: Problems) -> None:
    """L-AC1-L-AC19 contiguous; Blocked by; only the pinned observables; derived numbers; the Validation note."""
    area = "lifecycle acceptance"
    allowed = observables(life, H_LIFE_OBSERVABLES, area, probs)
    obs = [cells[0] for _, cells in get_table(life, H_LIFE_OBSERVABLES, area, probs)]
    if tuple(obs) != LIFE_OBSERVABLES:
        probs.add(area, f"scene-level Observables {obs} != the pinned {list(LIFE_OBSERVABLES)}")
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
    if order != list(range(1, LIFE_AC_COUNT + 1)):
        probs.add(area, f"L-ACs numbered {order}, expected 1-{LIFE_AC_COUNT}")
    texts = {k: norm(" ".join(v)) for k, v in acs.items()}
    raw = {k: " ".join(v) for k, v in acs.items()}
    for number in order:
        check_blocked_and_calls(f"L-AC{number}", raw[number], allowed, area, probs)
    # Derived numbers and lists.
    offers = crisis_offers(rules)
    pairs = len(AUTHORITY) * len(FACTION)
    total = sum(len(v) for v in offers.values())
    storable = [p for p in PHASES if "never saved" not in PHASE_TABLE[p][0]]
    ckpt = CTX.get("checkpoints", [])
    you_to = [r for r in rules if f"revise:authority:YOU" in offers[r]]
    you_from = [(r, sorted(o for o in offers[r] if o.startswith("revise:authority:"))) for r in rules
                if rules[r][0] == "YOU"]
    families = list(dict.fromkeys(FAMILY_BY_AUTHORITY.values()))
    derived = {3: [f"each of the other {NUMBER_WORDS[pairs - len(rules)]} pairs"],
               4: [f"For each of the {valid_rows} valid rows"],
               6: [f"For each transition of the window table ({', '.join(ckpt)})"],
               7: [f"for each of its offers ({total} runs)"],
               8: [f"each storable phase ({', '.join(storable)})"],
               12: [f"YOU reached by a renegotiation (from {' or '.join(you_to)}) → STATED, the commitment chosen in "
                    "that scene"]
               + [f"YOU withdrawn by a renegotiation from {r} ({', '.join(sorted(o, key=lambda x: AUTHORITY.index(x.split(':')[2])))}) → WITHDRAWN"
                  for r, o in you_from],
               13: [f"A save in each storable phase ({', '.join(storable)})"],
               14: [f"With the completion flags of arcs {join_and(list(POST_1_0_ARCS))} set"],
               16: [f"the {total} retract_*, {', '.join(f'red_line_{r}' for r in rules)}, sole_dissent"],
               18: [f"one ending per family ({', '.join(families)})"]}
    for number, keys in derived.items():
        for key in keys:
            if key not in texts.get(number, ""):
                probs.add(area, f"L-AC{number} lacks '{key}' (derived)")
    for number, keys in LAC_KEYS.items():
        for key in keys:
            key = key.replace("{legacy}", str(EC16_LEGACY)).replace("{total}", str(total))
            if key not in texts.get(number, ""):
                probs.add(area, f"L-AC{number} lacks the pinned phrase '{key}'")
    for number in order:
        for bad in NON_FAILING:
            if bad in texts[number]:
                probs.add(area, f"L-AC{number} asserts '{bad}', which cannot fail; assert take() false and "
                                "record_hash() unchanged")
    # L-AC10 checks exactly the axes doc's unlock flags (derived from the secret_unlock_flag knob).
    unlock = CTX.get("unlock_flags", [])
    m = re.search(r"flag_set\(\) is false for (.+?), and signpost", texts.get(10, ""))
    if m is None or sorted(re.findall(r"[A-Z_]{4,}", m[1])) != sorted(unlock):
        probs.add(area, f"L-AC10's flag_set() list is not the unlock flags {unlock}")
    # L-AC2: the Faction lock-pass fixtures, recomputed over the seed map.
    m = re.search(r"Faction backing (\w+), (\w+) fixtures: (.+?)\. In each", texts.get(2, ""))
    if m is None:
        probs.add(area, "L-AC2 has no 'Faction backing <value>, <n> fixtures: ...' list")
    else:
        clauses = [c for c in m[3].split(";") if "→" in c]
        if NUMBER_WORDS.get(len(clauses)) != m[2]:
            probs.add(area, f"L-AC2 says '{m[2]} fixtures' but lists {len(clauses)}")
        for clause in clauses:
            flags = {f for f in re.findall(r"[a-z0-9_]+", clause.split("→")[0]) if f in SEED_FLAGS}
            want = "NEGOTIATED" if py_lock_pass("faction", m[1], flags) == "NEGOTIATED" else "CLEAN"
            got = "NEGOTIATED" if "contains" in clause.split("→")[1] else "CLEAN"
            if want != got:
                probs.add(area, f"L-AC2 fixture '{clause.strip()}' states {got}, lock_pass gives {want}")
    # The Validation note: (valid rows) + (offers) + counted paths × storable phases.
    text = norm(" ".join(note))
    if not text:
        probs.add(area, "no Validation note")
        return
    s6_start = next((n for n, line in enumerate(life) if line.startswith("**S6")), len(life))
    s6 = []
    for line in life[s6_start:]:
        if not line.strip():
            break
        s6.append(line)
    paths = re.findall(r"`(\w+)` \(", " ".join(s6))
    if len(paths) != LIFE_REQUIRED_PATHS:
        probs.add(area, f"S6 names paths {paths}, expected {LIFE_REQUIRED_PATHS}")
    # Lifecycle revision 2: the protected world_map path is blocked and not counted until its change is approved.
    # Revision 5: no secret-route runs (no route ships in 1.0).
    counted = [p for p in paths if p != "world_map"]
    want_terms = [valid_rows, total, len(counted) * len(storable)]
    terms = [int(t) for t in re.findall(r"\((\d+)\)", text)]
    if terms != want_terms:
        probs.add(area, f"Validation note terms {terms} != derived {want_terms} (valid rows, offers, "
                        f"paths × storable phases)")
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


def check_life_derived(life: list[str], rules: dict[str, tuple[str, ...]], root: Path, probs: Problems) -> None:
    """Lifecycle values derived from the axes doc (unlock flags, Witness leads, D-numbers, offer counts) and the
    legacy-flag citations (lifecycle round 2, kept)."""
    area = "lifecycle derived"
    text = norm(" ".join(life))
    unlock = CTX.get("unlock_flags", [])
    m = re.search(r"no secret unlock flag \(([^)]*)\) is set", text)
    if m is None or sorted(re.findall(r"[A-Z_]{4,}", m[1])) != sorted(unlock):
        probs.add(area, f"S5's unlock flags {m[1] if m else None} != the axes secret_unlock_flag knob {unlock}")
    leads = CTX.get("prerequisites", {}).get("WITNESS", [])
    first, _ = odd_rule(rules)
    n_first = NUMBER_WORDS.get(len(crisis_offers(rules).get(first, ())), "?")
    for key in (f"{join_and(leads)} stay set", f"{first} at C8-S16 offers only its {n_first} renegotiations (S5)",
                f"(storyline-axes.md Edge Case 16, D{EC16_LEGACY})", f"Edge Case 16 D{EC16_LEGACY}-D{EC16_ORDER}"):
        if key not in text:
            probs.add(area, f"lacks '{key}' (derived from storyline-axes.md)")
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
    # Revision 9: the removed secret-route identifiers, everywhere (no exempt section).
    for lineno, line in enumerate(lines, 1):
        for word in STALE_SECRET_VOCAB:
            if word in line.replace("`", ""):
                probs.add("stale", f"{doc} line {lineno}: removed secret-route identifier '{word}' present (revision 9)")


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
    check_revision9(gdd, life, valid_rows, probs)
    check_protected(gdd, args.root, probs)
    check_revision12(gdd, life, rules, src, probs)
    check_revision13(gdd, life, probs)
    check_revision14(gdd, life, probs)
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
    check_life_derived(life, rules, args.root, probs)
    check_revision15(gdd, life, src, args.root, probs)   # after check_transitions: it reads CTX["checkpoints"]
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
