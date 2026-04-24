# Prompt 04 - Runtime Topology And Hunger Route Shape

Use this prompt after Prompt 03 locks the sector grammar.
This is the only prompt in this wave that may touch runtime graph generation, and only inside existing `MapRuntimeState` ownership.

Checked-in filename note:
- this pack lives at `Docs/Promts/04_runtime_topology_and_hunger_route_shape.md`

Read first:
- `AGENTS.md`
- `Docs/DOC_PRECEDENCE.md`
- `Docs/MAP_CONTRACT.md`
- `Docs/SOURCE_OF_TRUTH.md`
- `Docs/SAVE_SCHEMA.md`
- `Docs/TEST_STRATEGY.md`
- Prompt 03 output
- `Game/RuntimeState/map_runtime_state.gd`
- `Tests/test_map_runtime_state.gd`
- current map capture/readback evidence

Preflight:
- touched owner layer: `Game/RuntimeState/MapRuntimeState + related runtime tests`
- authority doc: `Docs/MAP_CONTRACT.md` plus `Docs/SOURCE_OF_TRUTH.md`
- impact: `runtime truth may change inside existing graph-generation owner / save shape unchanged / asset-provenance unchanged`
- minimum validation set: `validate_architecture_guards + targeted map runtime tests + targeted map UI tests + scene isolation + portrait capture + full suite + git diff --check`

## Goal

Verify or correct runtime topology so each seed can produce a different but readable route world.
The route graph should support:
- local exploration from a center-local start with seed/profile-varied outward route emphasis
- first `2-4` meaningful choices
- branch pockets and local reconnects
- short/long route pressure that makes hunger matter
- key/boss pressure away from the opening shell
- no global scatter or nearest-neighbor feel

Movement hunger cost remains the existing rule. This prompt changes route shape only if needed.

## Required Outcomes

- graph generation is checked against hidden-sector grammar
- seed variation is checked across seeds `11`, `29`, `41`, plus at least two additional random seeds unless explicitly deferred with reason
- hunger pressure is evaluated through route length, detour choices, support access, and boss push shape
- hunger route-shape evidence reports non-mechanic metrics where available: `start_to_boss_shortest_path_steps`, `support_nodes_on_shortest_path`, and `shortest_vs_alternative_route_delta`; exact blockers are stated if the current graph API cannot expose them safely
- runtime changes, if any, preserve save payload shape and owner meaning
- no presentation metadata is stored as gameplay truth

## Owner-Safe Read Interface

Prompt 05 needs layout metadata for sector-local anchors. The required owner-safe interface is:
- `build_layout_graph_snapshots()`

This interface must be read-only, non-save metadata from the `MapRuntimeState` owner.
Allowed fields only:
- `node_id`
- `node_family`
- `node_state`
- `adjacent_node_ids`
- `sector_id`
- `route_role`
- `orientation_profile_id`
- `topology_blueprint_id`

Forbidden:
- save payload shape changes
- presentation-only fields stored as runtime truth
- UI ownership of graph/current/discovery/adjacency truth

## Hard Guardrails

- no save-schema/version change
- no flow-state change
- no UI ownership move
- no gameplay autoload
- no candidate art
- no broad content rebalance

## Validation

- `py -3 Tools/validate_architecture_guards.py`
- targeted runtime/map tests, including `test_map_runtime_state.gd`
- targeted map presentation tests if route shape affects captures
- `powershell -NoProfile -ExecutionPolicy Bypass -File Tools/run_godot_scene_isolation.ps1 -ScenePath scenes/map_explore.tscn -QuitAfter 2`
- `powershell -NoProfile -ExecutionPolicy Bypass -File Tools/run_portrait_review_capture.ps1 -ScenePaths scenes/map_explore.tscn -ViewportSizes 1080x1920 -TimeoutSeconds 120`
- `powershell -NoProfile -ExecutionPolicy Bypass -File Tools/run_godot_full_suite.ps1`
- `git diff --check`

## Done Criteria

- runtime topology either passes the target honestly or exact blockers remain explicit
- hunger route-shape feel is evaluated without changing hunger rules
- save shape remains unchanged

## Copy/Paste Parts

### Part A - Runtime Topology Audit

Apply only Prompt 04 Part A.

Scope:
- inspect runtime graph generation against Prompt 03 grammar and Prompt 02 failures

Do not:
- patch code in Part A

Validation:
- architecture guard
- targeted runtime tests

Report:
- findings first
- confirmed graph owner boundaries
- exact seed variation and hunger-shape failures
- hunger route-shape metrics or exact reason they cannot be measured safely yet
- exact code paths that may change in Part B

### Part B - Owner-Preserving Runtime Patch

Apply only Prompt 04 Part B.

Scope:
- land only the smallest `MapRuntimeState` graph-generation fix justified by Part A
- expose `build_layout_graph_snapshots()` as read-only, non-save layout metadata for Prompt 05 unless Part A proves an equivalent owner-safe interface already exists

Do not:
- alter save shape, flow state, UI truth ownership, or content balance

Validation:
- full Prompt 04 validation stack

Report:
- files changed
- exact topology behavior changed
- exact no-save-shape evidence
- exact hunger route-shape metrics before/after, or explicit deferral reason
- screenshot/readback evidence delta

### Part C - Runtime Recheck

Apply only Prompt 04 Part C.

Scope:
- recheck topology, seed variation, and hunger route pressure

Do not:
- overclaim visual success; UI prompts still own presentation read

Validation:
- full Prompt 04 validation stack

Report:
- findings first
- whether Prompt 05 can start
- hunger route-shape metrics and remaining hunger-feel blockers
- remaining runtime blockers, if any
