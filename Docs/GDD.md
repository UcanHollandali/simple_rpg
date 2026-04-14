# SIMPLE RPG - Game Design Document

## Purpose

This document defines the game's identity, design pillars, and red lines.

## Game Identity

Simple RPG is a:
- 2D
- mobile portrait
- preparation-focused
- exploration-focused
- run-based roguelite RPG

The player should win or lose mainly because of:
- exploration route choice
- resource management
- shared inventory pressure
- durability planning
- timing of item use

## Terminology

Preferred terms:
- `Run`: one play attempt from start to fail or finish
- `Stage`: one major chunk inside a run
- `Map`: the exploration graph and node structure of a stage
- `Node`: one content-bearing map point
- `Definition`: static design data
- `Runtime State`: live gameplay truth
- `Stable ID`: permanent technical identifier
- `Display Name`: player-facing label

Important distinctions:
- `Definition` is not `Runtime State`
- `Effect` is not `Trigger`
- `Loot` is not all `Reward`
- `View Data` is not authoritative truth

## What The Game Is Not

This game is not:
- a wide skill-bar combat game
- a card game
- an autobattler
- a reflex or dodge minigame game
- a chaos-driven combat game

## Design Pillars

- preparation over reflex
- hard but fair
- readable combat
- meaningful attrition
- compact shared-bag tension

Inventory pressure uses a small shared carried-inventory pool where weapons, armor, belts, consumables, and passives all compete for the same limited space.
Local consumable hold-vs-use decisions still matter, but they now sit inside that shared-capacity pressure rather than inside separate lane caps.

## Hard Locks

- combat is not the star; it stays the visible decision layer of preparation
- combat stays short, readable, single-target, and intent-visible
- the top-level combat buttons stay `Attack`, `Brace`, `Use Item`; any allowed combat-time equipment swap must route through the shared inventory strip and still spend the turn
- support visits and stage interstitials must remain real runtime-backed non-combat states, not immediate-return placeholders
- content growth should mostly arrive through data, not new special-case code
- if a new idea improves combat depth but weakens preparation pressure or readability, reject it by default

## Locked Run Spine

- the game stays preparation-first, exploration-first, and attrition-driven
- a run contains exactly `3` stages
- target mastered successful clear time is `18-25` minutes
- typical early failed runs target `8-15` minutes
- first clears may be meaningfully longer
- very early collapse may occur, but it is not the target experience
- each stage begins from a central start node inside a bounded exploration graph
- stage visibility uses partial fog rather than full-route certainty
- traversal is adjacency-based between neighboring nodes
- revisit is allowed inside a stage
- movement drains a `20`-point hunger reserve toward `0`
- each stage may contain one optional side-mission contract detour that marks a later combat target and pays out one gear choice on return
- each stage contains exactly one stage-local `key` and one boss gate
- boss access requires the stage key
- clearing the boss ends the stage
- revisit does not create repeat-farm loops; resolved value does not refresh just because the player moved back through the graph
- main pressure axes:
  - `hunger`
  - `durability`
  - `shared gold`
- build shaping stays intentionally compact:
  - base shared inventory: `5`
  - equipped belt bonus: `+2`
  - small linear synergies
  - no combo explosion

## Replayability Model

- replayability should come from:
  - mastery curve
  - route variance
  - build variance
- replayability should not come from making runs arbitrarily longer
- novice failed runs should usually expose the player to at least one reward, one support opportunity, and one meaningful exploration decision before collapse

## Content Growth Rule

- system surface should stabilize early
- most future growth should come from new content data inside the existing grammar
- adding new content should be easier than adding new mechanic surface
- new mechanic surface still requires explicit contract review

## Core Loop

Explore map -> spend resources -> encounter enemy or node -> gain reward -> shape build -> prepare for boss -> clear stage or fail run

## Combat Role

Combat is not the star.
Combat is the visible decision layer of preparation.

## Fairness Rule

The player should usually be able to understand why they lost.
Difficulty should come from decision pressure, not hidden information.

## Locked Combat Identity

- single-target
- turn-based
- intent-visible
- minimal action set
- attrition-aware

## Build and Content Direction

The project wants:
- small but distinct build identities
- small readable status pools
- easy content expansion through data

## Scope Timing

Lock early:
- preparation-first identity
- hard-but-fair principle
- shared inventory pressure as the inventory model
- hunger and durability as real attrition
- minimal combat action set
- visible enemy intent
- data-driven content direction
- definition/runtime separation
- single source of truth
- save-ready architecture
- Godot 4 plus typed GDScript baseline
- JSON canonical content format

Validate in prototype:
- exploration pressure
- hunger pressure
- inventory pressure
- side-mission detour readability and payout value
- combat readability
- intent usefulness
- durability pressure
- support interaction usefulness
- stage transition readability
- reward and level-up flow
- whether the minimum content set creates enough meaningful decisions

Explicitly deferred:
- large enemy variety
- large item pool
- many weapon families
- advanced boss phases
- deep event writing
- meta progression
- combat save
- advanced tooling or simulation

See [DEFERRED_DECISIONS.md](DEFERRED_DECISIONS.md) for the tracked open list.

## Development Stages

Prototype:
- validate the core feeling
- validate the technical baseline

Vertical Slice:
- prove end-to-end flow
- prove the structure can support production

v1:
- deliver a small but coherent product

## Decision Filter

Every new feature should justify itself against these checks:
1. does it strengthen preparation, exploration pressure, or shared inventory pressure
2. does it keep combat readable and compact
3. can it be expressed as content data instead of new special-case code
4. does it stay understandable on a mobile portrait screen
5. is its maintenance cost justified by the gain

Detailed experimental ideas belong in [EXPERIMENT_BANK.md](EXPERIMENT_BANK.md), not here.
