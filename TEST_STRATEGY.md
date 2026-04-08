# SIMPLE RPG - Test Strategy

## Purpose

This file defines how the project protects itself from silent breakage.

## Main Rule

Automate what can be validated cheaply.
Manual checks are for feel, pacing, and fairness.

## Test Families

- pure core rule tests
- validation tests
- state transition tests
- save/load tests
- invariants
- manual design checks
- Godot smoke tests

## Pure Core Tests

Prefer engine-light tests for:
- combat resolution
- turn order
- status timing
- inventory rules
- content validation
- save serialization logic
- command routing rules

## Validation Tests

Validation should cover:
- duplicate IDs
- missing references
- invalid family
- invalid tag
- invalid trigger/effect/target
- file-path and stable-ID mismatch

## Save and State Tests

Save tests should cover:
- safe-state roundtrip
- pending choice restore
- schema/content version handling
- ownership invariants after load

## Godot Smoke Tests

Use Godot-level smoke checks for:
- project opens
- key systems boot
- scene wiring does not explode
- simple integration flows still run

These are integration checks, not a replacement for pure rule tests.

## Manual Design Checks

Manual checks still matter for:
- fairness
- readability
- pacing
- hold-vs-use tension
- whether intent produces real decisions

## Regression Rule

When a meaningful bug is found:
1. identify the rule that broke
2. add a regression test if practical
3. fix the bug
4. keep the test

## Priority Checks

1. turn order
2. action validity
3. status timing
4. ownership invariants
5. save roundtrip basics
6. content schema validation

## Required Invariants

- no duplicate authoritative state owners
- no negative durability
- no negative status duration
- no invalid flow state
- no broken stable ID references
- current node belongs to current map
