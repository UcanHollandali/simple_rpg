# SIMPLE RPG - Implementation Roadmap

## Purpose

This file defines the practical implementation order after the documentation baseline is frozen.

It is a roadmap, not an authority file.
If a roadmap item changes a rule, update the relevant authoritative doc first.

## Current Principle

Build the game in the same order that reduces refactor risk:
- stabilize runtime
- prove the smallest playable loop
- add save/test hardening
- grow content only after the loop is stable

## Phase 0 - Clean Engine Bootstrap

Goal:
- create a clean engine shell from scratch and verify that the repo can start from a stable baseline

Tasks:
- generate a fresh Godot project shell
- wire the minimum startup scene only
- confirm a clean run before any gameplay code is restored
- lock the baseline project settings
- commit only the new stable shell

Exit condition:
- the repo has a clean engine shell that runs without native crash

## Phase 1 - Prototype Loop Skeleton

Goal:
- make the smallest honest playable loop work end-to-end

Tasks:
- main menu -> start prototype run
- map explore placeholder
- move to node command
- enter one simple combat
- exit combat into one simple reward step
- return to map or end run

Exit condition:
- one full run segment can be played without manual scene hacking

## Phase 2 - First Real Combat Slice

Goal:
- replace placeholder combat flow with the smallest real combat contract implementation

Tasks:
- single enemy encounter state
- first intent reveal
- `Attack`, `Brace`, `Use Item` command handling
- enemy defeat / player defeat checks
- durability reduction
- fallback attack baseline

Exit condition:
- one simple fight resolves according to the documented combat contract

## Phase 3 - Save And Restore Baseline

Goal:
- support safe-state save/load for early playable flow

Tasks:
- snapshot builder finalization
- restore path for `MapExplore`
- restore path for pending safe states
- save invariant checks
- active run reload path

Exit condition:
- safe-state save/load works for the prototype loop

## Phase 4 - Validation And Tests

Goal:
- convert fragile assumptions into repeatable checks

Tasks:
- content validation commands
- state ownership checks
- flow transition checks
- save roundtrip checks
- first combat rule regression tests

Exit condition:
- small patches no longer require blind confidence

## Phase 5 - Minimum Content Set

Goal:
- add enough content to meaningfully test the structure

Tasks:
- initial weapon set
- initial consumables
- initial enemy set
- compact status set
- first reward pool

Exit condition:
- the loop has enough variety to validate decisions, not just wiring

## Phase 6 - Vertical Slice Hardening

Goal:
- prove the architecture survives more real use

Tasks:
- expand map/node variety
- improve reward and level-up handling
- tighten save behavior
- improve UI readability
- confirm AI can add content without special-case branching

Exit condition:
- structure remains understandable after real iteration

## Defer Until After These Phases

- meta progression
- combat save
- deep boss phase systems
- broad weapon family expansion
- advanced event depth
- custom editor tooling
- large-scale balance automation

## Immediate Next Step

Start with `Phase 0 - Clean Engine Bootstrap`.

Do not continue gameplay implementation until the clean shell is proven stable.
