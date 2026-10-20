## Technical Debt Register
Last updated: 2026-10-20
Total items: 2 | Estimated total effort: S + M

| ID | Category | Description | Files | Effort | Impact | Priority | Status | Added | Sprint |
|----|----------|-------------|-------|--------|--------|----------|--------|-------|--------|
| TD-001 | Code Quality | Saves older than v1.2 load through `ChoiceConsequences.rebuild_from_flags()`, which rebuilds `active_buffs` without applying their mods to `player_stats`; the T07 NG+ subtraction can then remove buffs the stats never had (base attack/defense unfloored). Guard needed in `choice_consequences.gd` plus a pre-v1.2 load → NG+ test; first check whether any pre-v1.2 save exists — from production/epics/y1-p0-stabilize/story-t07-ngplus-buffs.md | AethelgardPrototype/scripts/choice_consequences.gd, AethelgardPrototype/scripts/game_manager.gd | M | Med | — | Open | 2026-10-20 | Backlog |
| TD-002 | Test | No test covers a current-version (v1.2) save → load → NG+ round trip; the T07 fix relies on `active_buffs` and the buffed stats both surviving save/load (protected area). QA-lead: do before Y1-P0-T15 / release — from production/epics/y1-p0-stabilize/story-t07-ngplus-buffs.md | AethelgardPrototype/tests/unit/ngplus/ | S | Med | — | Open | 2026-10-20 | Sprint 001 (before T15) |
