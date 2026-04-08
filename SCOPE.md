# SIMPLE RPG - Scope Definition

## Purpose

This file defines what must be locked now, what must be validated in prototype, and what is deliberately deferred.

## Main Scope Rule

Lock structure early.
Validate feel in prototype.
Grow content and complexity only after the structure proves itself.

This project should not solve every interesting idea in the first playable build.

## Locked Now

These are not prototype experiments. They are project-direction decisions.

- preparation-first game identity
- hard but fair principle
- shared inventory as a core pressure
- hunger and durability as real attrition
- minimal combat action set: `Attack`, `Brace`, `Use Item`
- visible enemy intent
- data-driven content direction
- definition/runtime separation
- single source of truth
- save-ready architecture
- Godot 4 plus typed GDScript baseline
- JSON canonical content format

## Validate In Prototype

These should be proven by actual play and implementation, not assumed.

- route pressure
- hunger pressure
- inventory pressure
- combat readability
- intent usefulness
- durability pressure
- reward and level-up flow
- whether current minimum content set is enough to create meaningful decisions

## Prototype Must Include

- one runnable flow from main menu into a run
- one basic map exploration loop
- one simple combat entry and exit
- one reward step
- enough content to validate the structure, not to represent full game breadth

## Vertical Slice Focus

Vertical Slice should prove:
- end-to-end play continuity
- the structure survives more than one isolated feature
- the project is still understandable after more real content is added

Vertical Slice is where production confidence starts, not where architecture is first invented.

## Explicitly Not Required In First Playable

- large enemy variety
- large item pool
- many weapon families
- advanced boss phases
- deep event writing
- meta progression
- combat save
- advanced tooling or simulation

## Deliberately Deferred

- new status families
- new weapon families
- event depth
- boss phase depth
- meta progression
- combat save
- advanced tooling and simulation

See [DEFERRED_DECISIONS.md](DEFERRED_DECISIONS.md) for the tracked list.

## Development Stages

### Prototype

Goal:
- validate the core feeling
- validate the technical baseline

### Vertical Slice

Goal:
- prove end-to-end flow
- prove the structure can support production

### v1

Goal:
- deliver a small but coherent product
