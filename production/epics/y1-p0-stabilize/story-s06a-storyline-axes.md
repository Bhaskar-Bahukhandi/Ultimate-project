# Story S06a: The storyline axes GDD — 27 combinations, four ending families, Act 1 seeds and the composer input

> **Epic**: Y1-P0 Stabilize (Sprint 001)
> **Task ID**: Y1-P0-S06a (`production/plan/_source/Y1-P0.json#Y1-P0-S06`, days 1–2; sprint plan row Y1-P0-S06)
> **Status**: In Progress
> **Layer**: Foundation (design)
> **Type**: Integration
> **Estimate**: 2 days (the plan's S06 days 1–2). Day 1 the 27-row table, the families and the Act 1 seed map; day 2
> the side storylines, the composer input record, the checker and `/design-review`.
> **Manifest Version**: N/A — `docs/architecture/control-manifest.md` does not exist
> **Last Updated**: 2026-11-08

## Context

**GDD**: this story writes `design/gdd/storyline-axes.md` (new). **Source of record**: the plan entry (S06 day 1
"Storyline axes: map the 27 combinations", done "Axis doc with a 27-row table and Act 1 seed mapping"; day 2 "side
storylines and the ending composer inputs", done "Design review PASS or a list of concerns"; edge case "An axis
combination that makes a companion impossible must still have a valid ending"), `ROADMAP_10_YEAR.md` §12.2, and
`AethelgardPrototype/story/STORY_BIBLE.md` §4–5. **Requirement**: N/A — no TR-ID registered.

**ADR Governing Implementation**: N/A — a design document; no architectural decision. The composer input record it
defines is a design contract for later implementation stories, not an implementation.

**Engine**: N/A — no engine API. **Control Manifest Rules**: NOT ASSESSED — no control manifest.

**Performance**: none — documentation only.

**AGENTS.md protected areas**: none touched. No file under `AethelgardPrototype/scripts`, `scenes` or `dialogue`
changes; story progression, flags and endings are described, not changed. The Story Bible gains one dated line
recording the user's decision (AC-6).

### Audit (2026-11-08, read-only; HEAD `2d27572`)

1. **The axes** (Story Bible §5, PM 634–695): Authority (You / Shared / None), Faction (Hearth Compact / Archive
   Covenant / Continuity League), The deleted (Restore / Release / Choose). ROADMAP §12.2: 3 × 3 × 3 = 27, "the
   invalid ones are removed, giving 24 storylines + 3 secret"; secret quests add hidden fourth axis values.
2. **Ending families** (Story Bible §5, marked "Proposed (2026-10-05)"): Sole Authority (Axis 1 You), Bound
   Authority (Shared), No Authority (None), Consent (the secret route *Witness Protocol*). Faction and Deleted are
   modifiers (a boss phase, ally lines, epilogue slides, Story+ cases). The 24 + 3 storyline IDs stay as the
   configurations saves track. *First Wake* and *Crownless* are post-1.0 candidates.
3. **The 12 side storylines** (`story/source/PRODUCTION_MASTER_2.1.md`, each arc's "Axis effect:" line): 01 Baker of
   Oakhaven — Hearth reputation (:1904); 02 Knight's Debt — Root authority (:1953); 03 Glitch-Witch's Price —
   authority and consent (:1981); 04 Iron Owes — faction alignment (:2614); 05 The Flight List — secret FIRST WAKE
   (:2660); 06 Three Auctions and a Funeral — Continuity or Hearth economics (:2695); 07 Things Lyra Forgot — Deleted
   outcome and Archive philosophy (:3619); 08 Kaito's False Sky — secret CROWNLESS (:3663); 09 The Last Error —
   secret FIRST WAKE (:3687); 10 The Names We Keep — Deleted outcome (:4373); 11 The Clerk Who Stayed — shared
   authority (:4423); 12 A Person in Three Places — secret SEVEN WITNESSES (= Witness Protocol) (:4459). Arc 13+
   are "not one of roadmap's 12" (:5837). Arcs 03, 06 and 07 name two effects each.
4. **Act 1 flags that can seed the axes** (Story Bible §5 Chapter 1 and 2 tables; all 22 present in
   `AethelgardPrototype/scripts` or `dialogue`, seven of them only in `.dlg` files): `act1_report_local` /
   `_archive` / `_command`; `ch2_seraphina_truth` / `_cautious` / `_showoff`, `_recruited` / `_stayed` /
   `_rejected`; `ch2_data_wraith_restored` / `_destroyed` / `_absorbed`; `ch1_knight_killed` / `_spared`,
   `ch1_root_purge`; `ch1_root_first_edit` / `ch1_root_discovered_unused`; `ch1_oakhaven_warned_villagers` /
   `_leaders` / `_left_quietly`; `act1_pace_early` / `_on_time` / `_late` (set in `dialogue/ch2/act1_end.dlg`).
5. **Companions** (Story Bible §4): Companion status — Elara Venn (Ch1), Seraphina Vale (Ch2), Lyra Sen (Ch3),
   Kaelthas Marr (Ch3); Proposed — Nema Orr (non-companion, slot decided later), Rook Damar; Backlog — Kaito Aram,
   Unit 734 "Seven".
6. **Design tooling**: `design/gdd/` holds only `game-concept.md`; `design/gdd/systems-index.md` does not exist, and
   `/design-system` stops without it (`.claude/skills/design-system/references/2-gather-context.md:65-66`); only
   `/map-systems` writes that index. The GDD template is `.claude/docs/templates/game-design-document.md`.
   `modes.workflow` is `full`: all 8 GDD sections are required.

### Decisions (user, 2026-11-08)

- **D1 split:** S06 is three stories: S06a storyline axes (this), S06b time model, S06c difficulty profiles.
- **D2 endings:** the GDD adopts the four ending families as decided; the 24 + 3 storyline IDs stay as save and
  configuration identifiers; Witness Protocol is the in-scope secret route; First Wake and Crownless are post-1.0
  candidates (their IDs reserved, not designed here).
- **D3 authoring:** the GDD is written from the template section by section with the user's approval per section,
  not through `/design-system`; no systems index is created here (it waits for a later `/map-systems`), recorded
  as a deviation.

---

## Acceptance Criteria

- [ ] AC-1 **The GDD.** `design/gdd/storyline-axes.md`, written from `.claude/docs/templates/game-design-document.md`,
      has exactly these H2 headings in order: Overview, Player Fantasy, Detailed Rules (or Detailed Design), Formulas,
      Edge Cases, Dependencies, Tuning Knobs, Acceptance Criteria. Each section is shown to the user and approved
      before the next; the evidence README records each section's approval (section, date, the user's words).
- [ ] AC-2 **The 27-row table.** A Markdown table with exactly the columns `id | authority | faction | deleted | status
      | family | rule | source | companions_possible`, over the fixed vocabularies `authority ∈ {YOU, SHARED, NONE}`,
      `faction ∈ {HEARTH, ARCHIVE, CONTINUITY}`, `deleted ∈ {RESTORE, RELEASE, CHOOSE}`; `id` =
      `SL-{authority}-{faction}-{deleted}`; `status ∈ {valid, invalid}`; `family ∈ {SOLE, BOUND, NONE_AUTH, CONSENT}`
      for valid rows, `—` for invalid ones; `rule` = the number of an invalidity rule (invalid rows) or `—`; `source` =
      a `file:line` (Story Bible, ROADMAP or PM) behind the row's status; `companions_possible` = the subset of the four
      Story Bible Companions (Elara, Seraphina, Lyra, Kaelthas) who can still be present (Proposed and Backlog
      characters are out of the table). The GDD lists numbered invalidity rules, each from a source contradiction, and
      states `valid_count: N` on one line. ROADMAP's target is 24; if the analysis gives another N, the user decides the
      count before the GDD is finished, and AC-6 covers the ROADMAP / Story Bible lines that go stale. Every valid row's
      family needs no companion that row marks impossible (the plan's edge case: a valid ending stays reachable). Three
      secret rows follow in a separate table (`id | route | family | scope | source`): `SL-SECRET-WITNESS` (Consent, in
      scope), `SL-SECRET-FIRSTWAKE` and `SL-SECRET-CROWNLESS` (reserved, post-1.0); they add to the 27, they do not
      replace rows.
- [ ] AC-3 **Act 1 seed map.** A table `flag | pushes | direction | overturnable | source` covering every flag in
      Audit 4 (no more, no fewer unless the GDD adds one with a reason): `pushes` = an axis value (e.g.
      `faction:ARCHIVE`), a modifier, or `timing`; `direction` = `+` or `−`; `overturnable` = `yes`, `no` or
      `until:<flag>` (the flag that can override it, which must exist); flag names exact.
- [ ] AC-4 **Side storylines.** A table `arc | title | primary | secondary | scope | pm_line` with all 12 arcs:
      `primary` (required) and `secondary` (optional, for arcs whose PM line names two effects) are each an axis
      value, a modifier, a secret route or `timing`; `scope` = `1.0` or `post-1.0` (05, 08, 09 are post-1.0); `pm_line`
      is the arc's "Axis effect:" line number in `PRODUCTION_MASTER_2.1.md`.
- [ ] AC-5 **Composer input record.** A table `field | type | allowed | writer` with at least: `authority`,
      `faction`, `deleted` (allowed values = the AC-2 vocabularies), `secret_route`, `companions_present`,
      `regions_completed`, `timing_flags`, and the per-act pace field using the existing `act1_pace_early` /
      `_on_time` / `_late` names (later acts' pace names left to S06b, marked so). `writer` is an existing script or
      `.dlg` path, or a named owner story.
- [ ] AC-6 **Records kept in step.** The Story Bible's Endings section gains one dated line: the four-family model
      decided on 2026-11-08 (S06a). If `valid_count` is not 24, the "24 storylines + 3 secret" lines in ROADMAP §12.2
      and the Story Bible are updated with the user's OK. No systems index is created (D3).
- [ ] AC-7 **Checked, reviewed, evidenced.** `production/qa/evidence/2026-11-storyline/check_storyline_axes.py`
      (run with `python -I -B`) parses the GDD and fails unless: the 8 headings are present in order; the AC-2 table's
      `(authority, faction, deleted)` set equals the 3×3×3 product, each `id` matches its axis columns, every cell
      uses its vocabulary, invalid rows cite an existing rule number and valid rows a family, every row has a
      well-formed `source`, and the count of valid rows equals `valid_count`; the 3 secret rows are present; every
      valid row's family needs no companion it marks impossible; the AC-3 map covers exactly the Audit 4 flags, every
      flag and every `until:` flag exists in `AethelgardPrototype/scripts` or `dialogue` (including `.dlg`); the
      AC-4 table has arcs 01–12 with valid cells and `pm_line` values that point at an "Axis effect:" line; the AC-5
      record has the required fields with non-empty cells and axis values equal to the AC-2 vocabularies; the Story
      Bible holds the AC-6 line. Watched failing once per mutation, one per run, transcripts kept: a deleted row, a
      duplicated id, a bogus flag, a dropped arc, a wrong `valid_count`, a missing heading. `/design-review
      design/gdd/storyline-axes.md` returns APPROVED, or its concerns are fixed or accepted by the user; the review is
      kept with a README mapping the ACs. `git diff --name-only 2d27572 -- AethelgardPrototype/scripts
      AethelgardPrototype/scenes AethelgardPrototype/dialogue` is empty; `git diff --check` clean.

---

## Implementation Notes

- Author section by section from the template (D3); show each section before writing the next.
- Invalidity rules come from contradictions in the source, not taste (e.g. a faction whose premise needs an
  authority the Authority value abolishes); each rule quotes its Story Bible or PM line.
- The composer input record stays additive (ROADMAP §12.2 "authored cost is additive"): timing changes scenes and
  slides, never the storyline ID.
- IDs are uppercase and hyphenated so saves and tests can grep them.

---

## Out of Scope

- The time model and the difficulty profiles (S06b, S06c); later acts' pace names (S06b).
- Writing route content, scenes, dialogue or Story+ arcs; designing First Wake and Crownless beyond a reserved ID.
- Any change to flags, scripts, scenes or dialogue (findings are logged, not fixed).
- Act 3 branch content, the composer's implementation, and the systems index (`/map-systems`, later).

---

## QA Test Cases

- **C1 (AC-1)** — the checker finds the 8 headings in order; the README holds one approval entry per section.
- **C2 (AC-2)** — the checker: the axis set equals the 3×3×3 product; ids match their columns; vocabularies; rule
  citations; `valid_count` equals the valid rows; 3 secret rows; no valid row depends on an impossible companion.
- **C3 (AC-3)** — the checker: the map covers exactly the Audit 4 flags; every flag and `until:` flag exists in code
  or dialogue.
- **C4 (AC-4/5)** — the checker: 12 arcs with valid cells and real PM lines; the composer record's fields, types and
  axis vocabularies.
- **C5 (AC-6/7)** — the Story Bible line found by the checker; each named mutation fails the checker (transcripts);
  the `/design-review` verdict kept; the no-change `git diff` empty.

---

## Test Evidence

**Story Type**: Integration
**Required evidence**: `production/qa/evidence/2026-11-storyline/check_storyline_axes.py` (passing, watched failing
on each named mutation), the `/design-review` report, and the evidence README (AC map, per-section approvals).
**Run result**: N/A — a design document; nothing in the game changes.

---

## Dependencies

- Depends on: none.
- Unlocks: Y1-P0-S06b (time model: later acts' pace names and timing flags feed the composer record), Y1-P0-S09
  (side arc 04, Iron Owes, writes into the faction axis).

---

## Completion Notes

(empty until /story-done)
