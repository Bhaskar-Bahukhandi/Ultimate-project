# Review log: storyline-axes.md

## Review — 2026-11-09 — Verdict: NEEDS REVISION
Scope signal: M
Specialists: game-designer, systems-designer, narrative-director, qa-lead, creative-director (synthesis)
Blocking items: 6 | Recommended: 8
Summary: The core holds (three axes, R1-R3, 24 valid, four families, companions independent, timing as modifier).
The defects are lock timing (secret prerequisites land in the Chapter 9 ledger and revision runs before Root of
Heaven), self-contradicting formulas, and a seed map with no Authority seeds and a misread knight row.
Prior verdict resolved: First review
Findings:
- [BLOCKING] Detailed Design / Formulas / Acceptance Criteria: storyline ID fixed at Chapter 8 instead of before Root of Heaven (PM:722, PM:8188-8200)
- [BLOCKING] Formulas: ID formula ignores validity and the enable knob; no UNSET value; NONE token overloaded
- [BLOCKING] Detailed Design (seed map): no Authority seeds; ch1_knight_spared misreads PM:663; until:ch8_choice_made unsound; "−" undefined
- [BLOCKING] Acceptance Criteria: AC 2/3/4/9 not testable; checker misses rules table, R1-R3 exactness, 8/9/7 split, Edge Case 2
- [BLOCKING] Citations: C8-S17 is PM:7155 Revolution Name (Axis validation is PM:7522); PM:3615 local; Story Bible :187/:203 now :190/:206
- [BLOCKING] Detailed Design: Witness/CONSENT vs Bound/SHARED undefined
- [RECOMMENDED] Detailed Design: warning before the third lock
- [RECOMMENDED] Detailed Design (seed map): Data Wraith absorb ≈ CHOOSE, destroy ≈ RELEASE
- [RECOMMENDED] Detailed Design (side storylines): arc 12 also deleted:CHOOSE; arc 03 → Witness unsourced
- [RECOMMENDED] Detailed Design (seed map): Oakhaven flags lack faction mapping
- [RECOMMENDED] Formulas: "27" wording ambiguous (27 combinations vs 24 + 3)
- [RECOMMENDED] Edge Cases: drop the "first in table order" tie-break (data error for FlagRegistry)
- [RECOMMENDED] Story Bible: "loses health bar" belongs to Crownless (PM:11247), not Consent
- [RECOMMENDED] Composer record: truth-strategy module (PM:8739) — owner Y2-PP-T17
Reviewed-Content-Hash: design/gdd/storyline-axes.md d494fa55489384cfc2d178e4c064b25447525e55
Reviewed-Content-Hash: design/registry/entities.yaml 216ffa67ed4d5d24548df37b2ce899fcba892285
