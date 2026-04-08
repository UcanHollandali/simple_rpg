# SIMPLE RPG - Decision Log

## Purpose

This file records important accepted project decisions and links them back to authoritative docs.
It is intentionally narrow.

## Format

- `ID`
- `Status`
- `Decision`
- `Why`
- `Authority`

If a decision is superseded, add a new entry and mark the old one accordingly.

## Scope Rule

Record only accepted project-level decisions here.

Do not use this file for:
- temporary implementation notes
- local bug-fix details
- session status
- speculative ideas
- routine refactors

## Decisions

### D-001

- Status: `Accepted`
- Decision: The game is preparation-first, not reflex-first.
- Why: This keeps design scope tighter and supports readable, AI-manageable systems.
- Authority: `GDD.md`

### D-002

- Status: `Accepted`
- Decision: Combat is not the star; it is the visible decision layer of preparation.
- Why: This protects scope and keeps the project aligned with its design identity.
- Authority: `GDD.md`, `COMBAT_RULE_CONTRACT.md`

### D-003

- Status: `Accepted`
- Decision: The game should feel hard but fair.
- Why: Losses should usually feel attributable to player decisions, not hidden information.
- Authority: `GDD.md`, `COMBAT_INFO_MODEL.md`, `COMBAT_RULE_CONTRACT.md`

### D-004

- Status: `Accepted`
- Decision: The project uses Godot 4 stable with typed GDScript.
- Why: The workflow is friendlier to AI-assisted file-based development and headless checks.
- Authority: `TECH_BASELINE.md`

### D-005

- Status: `Accepted`
- Decision: Gameplay content is canonically stored as JSON definitions under `ContentDefinitions/`.
- Why: This makes content additions repeatable, reviewable, and less dependent on scene-local branching.
- Authority: `TECH_BASELINE.md`, `CONTENT_ARCHITECTURE_SPEC.md`

### D-006

- Status: `Accepted`
- Decision: Definition data and runtime state must stay separate.
- Why: This is required for save safety, validation, extensibility, and low-refactor growth.
- Authority: `ARCHITECTURE.md`, `SOURCE_OF_TRUTH.md`, `CONTENT_ARCHITECTURE_SPEC.md`

### D-007

- Status: `Accepted`
- Decision: Gameplay truth does not live in UI or gameplay autoloads.
- Why: Duplicate ownership is a primary source of long-term project drift.
- Authority: `ARCHITECTURE.md`, `SOURCE_OF_TRUTH.md`, `TECH_BASELINE.md`

### D-008

- Status: `Accepted`
- Decision: The preferred runtime pattern is command -> application -> core -> state update -> domain events -> UI refresh.
- Why: It limits patch scope, improves testing, and reduces hidden coupling.
- Authority: `ARCHITECTURE.md`

### D-009

- Status: `Accepted`
- Decision: Initial combat is limited to `Attack`, `Brace`, and `Use Item`.
- Why: This keeps combat readable and avoids premature complexity.
- Authority: `COMBAT_RULE_CONTRACT.md`

### D-010

- Status: `Accepted`
- Decision: First enemy intent is visible before the first player decision.
- Why: First-turn blindness conflicts with the fairness target.
- Authority: `COMBAT_INFO_MODEL.md`, `COMBAT_RULE_CONTRACT.md`

### D-011

- Status: `Accepted`
- Decision: Save architecture is required early, but initial saves are safe-state only.
- Why: This preserves future save support without taking on early combat-save complexity.
- Authority: `TECH_BASELINE.md`, `SAVE_SCHEMA.md`

### D-012

- Status: `Accepted`
- Decision: RNG uses named deterministic streams: `map_rng`, `combat_rng`, `reward_rng`.
- Why: This reduces coupling and makes deterministic debugging easier.
- Authority: `TECH_BASELINE.md`, `SAVE_SCHEMA.md`

### D-013

- Status: `Accepted`
- Decision: Most new items, armors, weapons, enemies, and statuses should be added by data first.
- Why: The project must remain easy to extend without content-specific branch explosion.
- Authority: `CONTENT_ARCHITECTURE_SPEC.md`, `ARCHITECTURE.md`

### D-014

- Status: `Accepted`
- Decision: Experimental content and speculative ideas must live outside authoritative spec docs.
- Why: The project needs strict specs plus a separate experiment bank.
- Authority: `EXPERIMENT_BANK.md`, `DOC_PRECEDENCE.md`
