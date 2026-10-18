# Project Stage Analysis Report

**Generated**: 2026-10-16
**Stage**: Production (observed). Configured stage: Concept (stale, set by `/start` before engine setup)
**Stage Confidence**: CONCERNS — the configured stage (Concept) and the observed code (Production) disagree. Code-based checks under the framework's `src/` code root are NOT ASSESSED.
**Analysis Scope**: Full project, rigor: full

---

## Executive Summary

Aethelgard is an existing Godot 4.6 project with substantial code: 132 GDScript files (about 60,500 lines), 74 scenes, 81 dialogue files, and 32 autoload singletons. Its design material (`AethelgardPrototype/DESIGN_PILLARS.md`, `ROADMAP_10_YEAR.md`, `design_archive/`) is real but sits outside the framework's expected locations, so the framework's artifact check reports most design and architecture documents as ABSENT.

The main gaps are a game concept document, a systems index, and recorded architecture decisions. The framework cannot scan the code because it expects Godot code in `src/`, and the project keeps it in `AethelgardPrototype/`. No framework setting overrides this.

**Current Focus**: Chapters 1–2 are playable; combat and world collision have recent fixes in git history.
**Blocking Issues**: No game concept or systems index in framework form, so `/gate-check` cannot advance the stage.
**Estimated Time to Next Stage**: Not estimated.

---

## Completeness Overview

### Design Documentation
- **Status**: Partial. Design intent exists in prose; framework-format documents are absent.
- **Files Found**: `design/` holds only the framework scaffold (`design/registry/entities.yaml`, `design/CLAUDE.md`). Outside it: `DESIGN_PILLARS.md`, `ROADMAP_10_YEAR.md`, 8 files in `design_archive/`, 5 files in `story/`, 81 `.dlg` dialogue files.
  - GDD sections: 0 files in `design/gdd/`
  - Narrative docs: 0 in `design/narrative/` (story and dialogue live outside it)
  - Level designs: 0 in `design/levels/`
- **Key Gaps**:
  - [ ] No game concept document in `design/gdd/game-concept.md`. Pillars and roadmap likely cover it.
  - [ ] No systems index. About ten gameplay areas in code are undecomposed.
  - [ ] No art bible. `docs/art_pipeline/` has many reviews, but no bible.

### Source Code
- **Status**: Substantial. Not assessed by the framework's own scan (see below).
- **Files Found**: 132 `.gd` files (about 60,500 lines) and 74 `.tscn` scenes, all under `AethelgardPrototype/`. The framework's code root is `src/`, which does not exist. Counting `src/` gives zero, which would read as greenfield. That is why this section reports `NOT ASSESSED — code root unresolved` for the framework's own check.
- **Major Systems Identified** (under `AethelgardPrototype/scripts/`):
  - ✅ Combat (`combat/`, 23 files)
  - ✅ UI (`ui/`, 13 files)
  - ✅ Chapter content (`chapter1/` to `chapter10/`, 4–9 files each)
  - ✅ Core, effects, cutscene, regions, resources, exploration, camera (1–6 files each)
  - ✅ 32 autoload singletons registered in `project.godot`
- **Key Gaps**:
  - [ ] No recorded architecture for the autoload set or the combat/overworld split. See Architecture.
  - [ ] Code root mismatch: framework code scans cannot run.

### Architecture Documentation
- **Status**: 0%, by framework location. Decisions exist only in code and in `AethelgardPrototype/AGENTS.md` (project rules, not ADRs).
- **ADRs Found**: 0 in `docs/architecture/`
- **Coverage**:
  - ✅ Project rules documented in `AGENTS.md` (collision, combat, save format and story progression are protected)
  - ⚠️ Autoload architecture: implemented, undocumented
  - ❌ Combat/overworld mode switch: implemented, undocumented
- **Key Gaps**:
  - [ ] Critical ADRs for the autoload architecture and the combat/overworld switch, via `/architecture-decision`

### Production Management
- **Status**: Roadmap exists; framework sprint and epic structure absent.
- **Found**:
  - Sprint plans: 0 in `production/sprints/`
  - Milestones: 0 in `production/milestones/`
  - Roadmap: Exists (`AethelgardPrototype/ROADMAP_10_YEAR.md`), outside the framework location
  - Reviews: `CODE_REVIEW_2026-10-04.md`, `AUDIT_AND_FIX_PLAN.md`
- **Key Gaps**:
  - [ ] No sprint or milestone structure in the framework. Acceptable at full only if work is tracked elsewhere; ask the user.

### Testing
- **Status**: Partial. Suites exist and pass for the quick set.
- **Test Files**: 10 `.gd` test scripts in `AethelgardPrototype/tests/`. CI (`.github/workflows/ci.yml`) runs 9 suites.
- **Runner**: `AethelgardPrototype/tests/run_all_tests.ps1` runs all 9 in CI order; `-Quick` skips the two chapter routes and phase0.
- **Coverage by System**: Not estimated. Suites cover dialogue, context stack, input, combat fixes, reachability, chapter routes and load-all.
- **Key Gaps**:
  - [ ] The framework's test-setup check looks for `.github/workflows/tests.yml`. The project uses `ci.yml`, so the check reports it ABSENT. The check is wrong, not the tests.
  - Note, not a gap: tests log "NPC sheet failed to load" for Lyra and Elara. This is probably the expected fallback: `DESIGN_PILLARS.md` says the temporary art was removed on 2026-10-04, pending Pixel Art Engine sprites, and `AGENTS.md` requires fallbacks to keep working. Recheck once PAE sprites are imported; the warning should disappear then.
  - [ ] The full run, including the two chapter-route suites and phase0, has not been confirmed locally.

### Prototypes
- **Active Prototypes**: 0 in `prototypes/` (the framework folder is absent).
- **Note**: `AethelgardPrototype/` is the game itself, not a throwaway prototype.

---

## Stage Classification Rationale

**Why Production (observed)?**
The code root holds 132 source files, which meets the framework's threshold of 10 or more. The game is in active development with playable chapters and recent fix commits.

**Why CONCERNS?**
- The configured stage (Concept) and observed stage (Production) disagree. Concept was set during `/start`, before the engine was configured and before the code was counted.
- The framework's code root (`src/`) cannot see the code, so its source-file count is NOT ASSESSED.

**Indicators for this stage**:
- 132 `.gd` files and 74 scenes under `AethelgardPrototype/`
- 9 CI test suites and a local runner
- Chapter folders 1–10 with dialogue, and a 32-autoload architecture
- Git history with playtest and fix commits

**Next stage requirements** (before `/gate-check` can advance the stage):
- [ ] Game concept document in `design/gdd/game-concept.md`
- [ ] Systems index in `design/gdd/systems-index.md`
- [ ] Critical ADRs in `docs/architecture/`
- [ ] Architecture document and control manifest
- [ ] Decision on the code root (see Gaps)

---

## Gaps Identified (with Clarifying Questions)

### Critical Gaps (block progress)

1. **No game concept document**
   - **Impact**: Without a concept document, the systems index and GDDs have no anchor, and `/gate-check` cannot pass.
   - **Question**: Should the concept be reverse-documented from `DESIGN_PILLARS.md` and `ROADMAP_10_YEAR.md`, or written fresh?
   - **Suggested Action**: `/reverse-document concept`, then review the draft

2. **No systems index**
   - **Impact**: About ten gameplay areas have no design documents, so design and code can drift apart unnoticed.
   - **Question**: Do you already have a list of systems, or should `/map-systems` derive one from the code?
   - **Suggested Action**: `/map-systems` after the concept exists

3. **No recorded architecture decisions**
   - **Impact**: The 32-autoload structure and the combat/overworld switch are not documented, so future changes lack rationale.
   - **Question**: Which decisions should be recorded first?
   - **Suggested Action**: `/architecture-decision` for the autoload architecture and combat/overworld switch

### Important Gaps (affect quality/velocity)

4. **Code root mismatch**
   - **Impact**: Code-based checks (content audit, tech debt, localization, security) report NOT ASSESSED or zero hits. A zero hit reads as a clean result.
   - **Question**: Accept NOT ASSESSED for code scans, or restructure the repository so the Godot project sits at `src/`? Restructuring is not recommended, because `AGENTS.md` discourages broad changes.
   - **Suggested Action**: Accept the limitation for now. Record it in `CLAUDE.md`, which already notes it.

5. **Full test run unconfirmed**
   - **Impact**: The two chapter-route suites and phase0 have not been run locally, so CI status is unknown on this machine.
   - **Question**: Run the full suite now, or after the documentation work?
   - **Suggested Action**: `powershell -File AethelgardPrototype/tests/run_all_tests.ps1`

6. **Sprite fallback warnings in tests** (downgraded: probably expected)
   - **Impact**: Low. Lyra and Elara use the NPC fallback because the temporary art was removed on 2026-10-04 (`DESIGN_PILLARS.md`), pending PAE sprites.
   - **Question**: None for now.
   - **Suggested Action**: After the PAE import, confirm the warning is gone. If it persists, check the asset paths then.

### Nice-to-Have Gaps (polish/best practices)

7. **Art bible**
   - **Impact**: The art pipeline has many review documents but no single visual identity reference.
   - **Question**: Is `docs/art_pipeline/` meant to be the art bible?
   - **Suggested Action**: `/art-bible` later

8. **Test-setup name mismatch**
   - **Impact**: The framework reports the test setup as missing.
   - **Question**: None. The tests exist.
   - **Suggested Action**: Ignore the framework's check, or rename the workflow

---

## Recommended Next Steps

### Immediate Priority (Do First)
1. **Draft the game concept from existing docs**: `DESIGN_PILLARS.md` and `ROADMAP_10_YEAR.md` already state most of it.
   - Suggested skill: `/reverse-document concept`
   - Estimated effort: S

2. **Decompose into systems**: map the code's gameplay areas once the concept exists.
   - Suggested skill: `/map-systems`
   - Estimated effort: M

### Short-Term (This Sprint/Week)
3. **Check whether existing audit docs are usable**: `CODE_REVIEW_2026-10-04.md`, `AUDIT_AND_FIX_PLAN.md`.
   - Suggested skill: `/adopt`
   - Estimated effort: S

4. **Record critical architecture decisions**: autoload architecture and combat/overworld switch.
   - Suggested skill: `/architecture-decision`
   - Estimated effort: M

### Medium-Term (Next Milestone)
5. **Confirm the full test suite locally.** After the PAE sprite import, check that the Lyra and Elara fallback warnings are gone.
6. **Run `/gate-check`** once items 1–4 are done. The stage advances only through it.

---

## Role-Specific Recommendations

Not requested. This is a general analysis.

---

## Follow-Up Skills to Run

- `/reverse-document concept` — game concept, from existing pillars and roadmap
- `/map-systems` — systems index
- `/adopt` — check existing audit docs against framework format
- `/architecture-decision` — autoload architecture and combat/overworld switch
- `/gate-check` — once the above are done

---

## Appendix: File Counts by Directory

```
design/                       scaffold only (0 GDD, 0 narrative, 0 level docs)
design_archive/               8 files (outside framework location)
AethelgardPrototype/
  scripts/                    132 .gd files (about 60,500 lines)
    combat/                   23
    ui/                       13
    chapter1/ … chapter10/    4–9 each
    core/ effects/ cutscene/  3, 6, 2
  scenes/                     74 .tscn files
  dialogue/                   81 .dlg files
  tests/                      10 .gd test files + run_all_tests.ps1
src/                          does not exist (framework code root)

docs/architecture/            0 ADRs
production/sprints/           0
production/milestones/        0
prototypes/                   does not exist
```

---

**End of Report**

*Generated by `/project-stage-detect` skill*
