# Claude Code Game Studios -- Game Studio Agent Architecture

Indie game development managed through 49 coordinated Claude Code subagents.
Each agent owns a specific domain, enforcing separation of concerns and quality.

## This Project: Aethelgard — The Glitch Sovereign

- The Godot project lives in `AethelgardPrototype/` (open `AethelgardPrototype/project.godot`).
  Game code is in `AethelgardPrototype/scripts/`, scenes in `AethelgardPrototype/scenes/`,
  tests in `AethelgardPrototype/tests/`. **It is not in `src/`.** Do not move it there:
  that would rewrite `res://` paths across every scene and autoload.
- Framework skills that resolve the Godot code root to `src/` will find nothing here.
  Treat a zero-hit code scan as `NOT ASSESSED`, never as a clean result, and point the
  scan at `AethelgardPrototype/scripts/` instead.
- The project's own agent rules are binding and take precedence for gameplay code:

@AethelgardPrototype/AGENTS.md

- Pre-framework design material: `design_archive/`, `AethelgardPrototype/DESIGN_PILLARS.md`,
  `AethelgardPrototype/ROADMAP_10_YEAR.md`, `AethelgardPrototype/docs/`.

## Technology Stack

- **Engine**: Godot 4.6
- **Language**: GDScript
- **Version Control**: Git with trunk-based development
- **Build System**: Godot export (prebuilt 4.6.3 editor + export templates; presets in `AethelgardPrototype/export_presets.cfg`)
- **Asset Pipeline**: Godot Import System + custom resource pipeline

> **Note**: Engine-specialist agents exist for Godot, Unity, and Unreal with
> dedicated sub-specialists. Use the set matching your engine.

## Project Structure

@.claude/docs/directory-structure.md

## Engine Version Reference

<!-- ENGINE-REFERENCE-IMPORT: the line below is engine-specific. /setup-engine
     rewrites it to @docs/engine-reference/<engine>/VERSION.md for the chosen
     engine, so a Unity or Unreal project stops loading the Godot reference every
     session. It defaults to Godot (the template's example engine); skills that
     need the pinned version read docs/engine-reference/<engine>/VERSION.md on
     demand regardless of this import. -->
@docs/engine-reference/godot/VERSION.md


## Technical Preferences

`project.yaml` at the repo root is the primary config store — engine, specialists,
naming, platform, performance, modes. Skills resolve it via `resolve_config`
(see `.claude/docs/config-resolution.md`).

`.claude/docs/technical-preferences.md` is the **legacy fallback**, read on demand
when a key is absent from `project.yaml`. It is no longer imported here: before
`/setup-engine` runs it is almost entirely `[TO BE CONFIGURED]` placeholders, and
after it runs `project.yaml` holds the real values.

## Coordination Rules

- **Spawn `memory: project` agents from the repo root.** Claude Code creates
  `.claude/agent-memory/<agent>/` under the session's current working directory
  at spawn (observed 2026-10-18; the docs are silent on the base). A Bash `cd`
  left in effect, such as into `AethelgardPrototype/`, strands the agent's memory
  in a stray `.claude/` there. `settings.json` sets
  `CLAUDE_BASH_MAINTAIN_PROJECT_WORKING_DIR=1` so the shell returns to the root
  after each command; still never leave a `cd` in effect before spawning.

@.claude/docs/coordination-rules.md

## Collaboration Protocol

**User-driven collaboration, not autonomous execution.**
Every task follows: **Question -> Options -> Decision -> Draft -> Approval**

- Agents MUST ask "May I write this to [filepath]?" before using Write/Edit tools
  (exempt: `active.md` appends, agent memory, a subagent's new file at the path
  its orchestrating skill named; see `.claude/rules/agent-memory.md`)
- Agents MUST show drafts or summaries before requesting approval
- Multi-file changes require explicit approval for the full changeset
- No commits without user instruction
- A skipped or dismissed question is not an answer: act on nothing, re-ask in
  plain text and wait
- Started outside this file's folder? Warn first: hooks, deny rules and the
  ask-first mode load only when Claude Code starts here

See `docs/COLLABORATIVE-DESIGN-PRINCIPLE.md` for full protocol and examples.

> **First session?** If the project has no engine configured and no game concept,
> run `/start` to begin the guided onboarding flow.

## Coding Standards

@.claude/docs/coding-standards.md

## Context Management

Read `.claude/docs/context-management.md` on demand — it is a reference, not
session context. Two of its conventions are load-bearing and cited by name
elsewhere in the repo, so they are restated here rather than lost:

- **`production/session-state/active.md` is the session checkpoint.** The file is
  the memory, not the conversation. Read it first after any compaction, crash, or
  `/clear`.
- **Helpers in `.claude/scripts/` emit observations, never verdicts.** A script
  that scores or judges will eventually contradict a mode or override it cannot
  see. (Cited by `artifact-check.sh` and `adr-dep-graph.sh`.)
