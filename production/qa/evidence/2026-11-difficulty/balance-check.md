## Balance Check: Difficulty Profiles

Run: 2026-11-21, `/balance-check design/gdd/difficulty-profiles.md` (revision 1), story Y1-P0-S06c AC-6.

### Data Sources Analyzed
- `design/gdd/difficulty-profiles.md` (revision 1) — FOUND; the profile table and the Tuning Knobs safe ranges are
  the targets
- `design/registry/entities.yaml` — FOUND, no difficulty entries (no targets from it)
- `assets/data/` — ABSENT (no data files; the profiles are not wired yet)
- `design/balance/` — ABSENT before this report
- `AethelgardPrototype/scripts/game_manager.gd:225` — level-1 player 100 HP (used for hits-to-down only)

### Health Summary: CONCERNS

Two curve concerns a tuning pass can fix; no outliers, no degenerate strategy. Two sections are NOT ASSESSED (below).

### Outliers Detected
| Item/Value | Expected Range | Actual | Issue |
|---|---|---|---|
| — | — | — | none: all 30 numeric profile values (6 rows × 5 profiles) are inside their Tuning Knobs safe ranges and keep their stated order |

### Degenerate Strategies Found
- None of the critical kind (no profile dominates every alternative).
- Loot parity, Beginner vs Easy: both drop `base` loot, and Beginner is easier in every row, so a loot-minded player
  loses nothing by choosing Beginner. Not degenerate (Medium and up add rarer loot), but Easy has no reward of its
  own. The ROADMAP table has the same gap (ROADMAP:474).

### Progression Analysis (step between profiles)
| measure | beginner | easy | medium | hard | hell | step ratios |
|---|---|---|---|---|---|---|
| parry (frames) | 12 | 9 | 6 | 4 | 2 | 0.75, 0.67, 0.67, 0.50 |
| dodge i-frames | 18 | 15 | 12 | 10 | 8 | 0.83, 0.80, 0.83, 0.80 |
| boss telegraph (%) | 150 | 125 | 100 | 85 | 70 | 0.83, 0.80, 0.85, 0.82 |
| 10-dmg hit | 6 | 8 | 10 | 13 | 20 | 1.33, 1.25, 1.30, 1.54 |
| hits to down from 100 HP (level 1) | 17 | 13 | 10 | 8 | 5 | smooth |
| hits absorbed by one rest's healing (casts × 30 ÷ hit) | 25 | 15 | 9 | 4.6 | 1.5 | 0.60, 0.60, 0.51, 0.33 |

### Recommendations
| Priority | Issue | Suggested Fix | Impact |
|---|---|---|---|
| 1 | Healing budget falls hardest at Hell (×0.33): 2× damage and 1 heal, so one rest's healing covers 1.5 hits | Keep (Hell is meant to be harsh) and say so in the GDD; or Hell healing 2 (inside 1-2) for a ×0.66 step | Hell survivability |
| 2 | Easy has no reward over Beginner (loot parity) | Accept as the ROADMAP intends; or one small non-gating reward on Easy | Choosing Easy over Beginner |
| 3 | Parry halves at Hell (4 → 2) | Keep: it is P6's 2-frame window, validated by Y1-P2-T22 | Hell parry |

### Values That Need Attention
- `boss_patterns`, `dda`, `loot` are sets, not numbers: no stated range — not judged.
- Time-to-kill, DPS and per-fight survivability: NOT ASSESSED — NO DATA. No enemy HP or damage tables exist under
  `assets/data/`; they come with Y1-P2's EnemyDef/BossDef data.

### Disposition (user decision 2026-11-21: "Save; note both in GDD")
- Concern 1: kept on purpose; recorded in the GDD (Tuning Knobs, Balance-check notes).
- Concern 2: accepted as the ROADMAP states; recorded in the GDD (Tuning Knobs, Balance-check notes).

Re-run `/balance-check` after fixes to verify.
