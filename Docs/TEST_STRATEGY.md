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

## Current Implemented Runner

Current automated tests are headless Godot `SceneTree` scripts under `Tests/`.
Active runnable checks are every `Tests/test_*.gd` file present in the repo; do not re-list them here, because this doc is not an inventory.
Current validator commands:
- Windows: `py -3 Tools/validate_content.py`
- macOS/Linux: `python3 Tools/validate_content.py`
- Windows asset validator: `py -3 Tools/validate_assets.py`
- macOS/Linux asset validator: `python3 Tools/validate_assets.py`
- Windows architecture guard validator: `py -3 Tools/validate_architecture_guards.py`
- macOS/Linux architecture guard validator: `python3 Tools/validate_architecture_guards.py`
  - current guard scope: deprecated `dispatch()` growth, runtime-side `RunState` compatibility creep, test-side inventory compatibility creep, new runtime-side `current_node_index` spread, scene/UI direct gameplay-truth mutation creep, combat inventory slot-id compatibility bridge spread, stale `RunSummaryCard` tree-scan workaround growth, Application/Infrastructure presentation-node coupling, hotspot large-file line-count creep on the current extraction-first slices, stale wrapper regression, implemented command/event catalog drift, `NodeResolve` live generic-fallback contract drift across authority docs and coordinator wiring, typed-owner reflection regression on the current locked low-risk slices, legacy overlay wrapper/dictionary regression outside the shared state-driven contract surface, `AppBootstrap` / `RunSessionCoordinator` public-surface growth, new `/root/AppBootstrap` lookup spread, and retired stage-1 boss surface regressions outside archive/history docs and explicit planning notes
Current bounded-time regression runner:
- Windows: `Tools/run_godot_tests.ps1` or `Tools/run_godot_tests.cmd`
- Default `Tools/run_godot_tests.*` behavior is a bounded subset only when no explicit test list is passed; do not treat that default lane as the full `Tests/test_*.gd` union.
- Current helper runner clears stale local `_godot_profile/logs/*.log` files before each run and treats generic `SCRIPT ERROR:` rows as hidden failures.
Current explicit full-suite Windows command:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File Tools/run_godot_full_suite.ps1
```

`Tools/run_godot_smoke.ps1` and `Tools/run_godot_scene_isolation.ps1` are current smoke helpers, not a separate test framework.
`Tools/run_godot_scene_isolation.ps1` requires an explicit `-ScenePath`, for example:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File Tools/run_godot_scene_isolation.ps1 -ScenePath scenes/map_explore.tscn
```

Current limitation:
- there is no dedicated image-diff regression harness in the repo yet
- Windows portrait screenshot review can now be generated through `powershell -NoProfile -ExecutionPolicy Bypass -File Tools/run_portrait_review_capture.ps1`
- the default portrait review set covers the always-meaningful playtest scenes (`main_menu`, `map_explore`, `combat`, `run_end`) instead of state-empty overlays
- visual screenshot confidence still depends on human review of those captures or live scene/editor/device checks layered on top of the automated suite

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

Current validator baseline should cover:
- duplicate IDs
- file-path and stable-ID mismatch
- invalid family
- missing required top-level fields
- enemy authoring requirements such as `design_intent_question`
- current runtime-backed rule-slice checks
- current reward content checks
- current combat-local status content checks
- rejection of reserved current-content fields such as weighted intents in canonical content

Later validation can expand toward:
- missing references
- controlled tag vocabulary
- broader trigger/effect/target coverage

## Current Exploration Graph Tests

Current exploration-graph coverage includes:
- fog reveal
  - movement reveals intended local neighbors without exposing the whole stage at once
- adjacency movement
  - non-adjacent moves and locked moves are rejected
- key/boss reachability
  - the stage key is reachable from the center-start exploration space
  - boss access remains viable after key resolution
- no repeat-farm
  - revisiting resolved combat, reward, or one-shot support nodes does not regenerate primary value
- merchant persistence
  - revisiting a merchant preserves remaining stock, sold-out state, and prices
- one-shot support persistence
  - revisiting `rest` or `blacksmith` reopens inert local state instead of minting repeat value
- hamlet contract flow
  - accepting a contract marks one combat node and one enemy deterministically
  - defeating that marked enemy completes the contract without changing combat reward cadence
  - returning to the contract node exposes claim offers exactly once

Later graph coverage can expand toward:
- early-run exposure floor
  - opening exploration exposes at least one reward opportunity, one support opportunity, and one meaningful adjacency choice inside the intended early-run window

## Save and State Tests

Save tests should cover:
- safe-state roundtrip
- pending choice restore
- standalone file-backed `save_game` / `load_game` roundtrip
- schema/content version handling
- ownership invariants after load
- hamlet node-state roundtrip inside `RunState` and file-backed save/load

## Godot Smoke Tests

Use Godot-level smoke checks for:
- project opens
- key systems boot
- scene wiring does not explode
- simple integration flows still run

These are integration checks, not a replacement for pure rule tests.

## Future Framework Direction

- `GdUnit4` is still the preferred long-term framework direction.
- Framework migration is deferred.
- Do not assume `Tests/` already runs through `godot --headless --run-tests` today.

## Manual Design Checks

Manual checks still matter for:
- fairness
- readability
- pacing
- local consumable hold-vs-use tension
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

## Future Exploration Graph Invariants

When the exploration-graph slice lands, required invariants expand to include:
- movement targets must be adjacency-valid
- locked boss access must remain unavailable before stage-key resolution
- resolved one-shot nodes must not regenerate primary value on revisit
- generated stage graphs must preserve key reachability and post-key boss viability
