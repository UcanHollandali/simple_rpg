# SIMPLE RPG - Save Schema

## Purpose

This file defines what the project saves and what it deliberately does not save.

## Main Rule

Save stores authoritative runtime truth, not presentation data.

## Required Metadata

- `save_schema_version`
- `content_version`
- `created_at`
- `updated_at`
- `save_type`
- optional `game_build_version`

## Versioning Rule

- `save_schema_version` tracks file structure
- `content_version` tracks gameplay content set

These are different concepts and should not be merged.

## Stable ID Rule

Content references in save data use stable technical IDs, not display names.

## Save Scope Baseline

The architecture is save-ready from the start.
The first supported saves are safe-state saves only.

Supported first:
- `MapExplore`
- `Reward`
- `LevelUp`
- `SupportInteraction`
- `StageTransition`
- `RunEnd`

Not supported first:
- `Boot`
- `RunSetup`
- `NodeResolve`
- `Combat`

Combat save is intentionally deferred until the baseline is stable.

## Persisted Runtime Areas

- run state
- map runtime state
- inventory and equipment runtime state
- active flow state
- pending reward state if relevant
- pending level-up state if relevant
- pending support interaction state if relevant
- RNG stream state

## RNG Persistence

Persist named stream state for:
- `map_rng`
- `combat_rng`
- `reward_rng`

## Must Not Be Saved

- tooltip text
- screen formatting
- hover state
- panel state
- duplicate derived summaries
- content definition copies
- display-only convenience strings

## Invariants

Load should not silently accept broken truth.

Required invariants include:
- no duplicate authoritative ownership
- no invalid stable ID references
- no impossible flow state
- no negative durability
- current node belongs to current map
- pending choice state matches current flow state

## Compatibility Rules

- stable IDs are the reference key
- migration is expected as a normal future need
- broken or missing content references should not silently map to random substitutes

## Pending Choice Rule

If a save occurs in a safe pending-choice state, the pending choice must restore as runtime state, not as UI guesswork.
