# SIMPLE RPG - Handoff

## Purpose

This file is the rolling handoff note for the project.

Use it to answer:
- where the project currently stands
- what is already locked
- what is implemented
- what is currently unstable
- what should happen next

This file is intentionally:
- short
- current-state focused
- easy to update at the end of a work session

This file is not:
- the authoritative rule source
- the decision history
- the backlog

For those, use:
- `DOC_PRECEDENCE.md`
- `DECISION_LOG.md`
- `DEFERRED_DECISIONS.md`

## Update Rule

Update this file whenever one of these changes:
- current implementation status
- active blocker
- current recommended next step
- important environment prerequisite

Keep it practical.
Do not turn it into another design spec.
This is the only rolling current-state file in the repo.
Do not create a second status tracker unless the doc structure is explicitly redesigned.

## Current Baseline

- Engine: `Godot 4.6.2 stable`
- Scripting: `typed GDScript`
- Content format: `JSON`
- Content path: `ContentDefinitions/<family>/<stable_id>.json`
- Project root entry docs:
  - `README.md`
  - `AGENTS.md`
  - `CLAUDE.md`
- Authoritative docs live under `Docs/`

## Current Project Status

Completed:
- documentation baseline is in place
- documentation freeze checklist currently passes
- technical baseline is locked
- root doc structure is cleaned up
- repo has been reset to docs-only baseline

Partially complete:
- nothing implementation-side is intentionally kept

Not complete:
- clean engine shell bootstrap
- runtime state model implementation
- command/event implementation
- content definition files
- real combat resolver
- real map generation
- full save restore
- inventory operations
- reward and level-up resolution
- production UI
- automated gameplay tests

## Current Known Issues

- previous implementation attempt was discarded
- crash-isolation artifacts were intentionally removed with the code reset
- current repo is documentation-only by design

## Current Godot Working Rule

- start from a clean Godot-generated project shell
- do not reintroduce old shell files from the discarded attempt
- rebuild runtime gradually from the documented baseline

## Current Godot Stability Tools

- none committed currently
- tooling will be recreated only after the clean shell is stable

## Current Recommended Next Step

1. Create a clean Godot-generated project shell from scratch.
2. Recreate only the minimum startup shell:
   - `project.godot`
   - `icon.svg`
   - `Scenes/Main.tscn`
3. Confirm clean run before reintroducing any gameplay code.
4. After runtime stability is confirmed, rebuild the minimum playable slice:
   - main menu -> prototype run
   - map explore
   - one simple combat entry
   - one simple reward exit
5. Add basic save/load roundtrip for safe states.
6. Add first real validation checks and regression tests.

## If A New Chat Starts

Start with these files in order:
1. `README.md`
2. `Docs/HANDOFF.md`
3. `Docs/TECH_BASELINE.md`
4. `Docs/ARCHITECTURE.md`
5. `Docs/SOURCE_OF_TRUTH.md`
6. `Docs/CONTENT_ARCHITECTURE_SPEC.md`
7. `Docs/DOC_PRECEDENCE.md`

Then read task-specific docs as needed.

## Current Active Risks

- engine shell can drift quickly if rebuilt carelessly
- combat resolver is not implemented yet, only skeleton contracts exist
- save architecture exists, but restore path is not complete
- implementation discipline matters more than speed at this stage

## Session End Checklist

Before ending a work session, update this file if needed:
- current implementation status still accurate
- current blocker still accurate
- next recommended step still accurate
- new environment caveat captured if relevant
