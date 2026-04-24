# Prompt 06 - Local Adjacency And Corridor Routing

Use this prompt after Prompt 05 closes slot/anchor placement.
This pack makes roads follow local sector adjacency and become route corridors instead of rescue curves between nodes.

Checked-in filename note:
- this pack lives at `Docs/Promts/06_local_adjacency_and_corridor_routing.md`

Read first:
- `AGENTS.md`
- `Docs/DOC_PRECEDENCE.md`
- `Docs/MAP_CONTRACT.md`
- `Docs/MAP_COMPOSER_V2_DESIGN.md`
- `Docs/SOURCE_OF_TRUTH.md`
- `Docs/TEST_STRATEGY.md`
- Prompt 05 output
- `Game/UI/map_board_composer_v2.gd`
- `Game/UI/map_board_edge_routing.gd`
- `Game/UI/map_board_history_edge_filter.gd`
- `Game/UI/map_board_geometry.gd`
- related map tests

Preflight:
- touched owner layer: `Game/UI derived corridor routing + related Tests`
- authority doc: `Docs/MAP_CONTRACT.md` plus `Docs/SOURCE_OF_TRUTH.md`
- impact: `runtime truth unchanged / save shape unchanged / asset-provenance unchanged`
- minimum validation set: `validate_architecture_guards + targeted map tests + scene isolation + portrait capture + git diff --check`

## Goal

Make visible roads express local adjacency and route identity:
- center-local first choices open toward readable north/south/east/west route directions
- first choices leave through distinct corridor throats
- primary, branch, history, and reconnect corridors read differently
- no same-corridor conflict for multiple actionable choices
- no global nearest-neighbor or long-span rescue feel
- roads begin/end at clearing edges, not icon centers

## Required Outcomes

- corridor roles are derived presentation data from runtime adjacency and layout
- corridor metadata preserves center-outward/cardinal route identity where derivable
- same-corridor conflict is audited and tested where practical
- reconnects stay local/legible and do not dominate the board
- roads avoid slicing through landmark pocket cores
- route hierarchy is owner-level implementation truth, not only test wording

## Hard Guardrails

- no runtime adjacency owner move
- no save/flow/source-of-truth change
- no asset work
- no road dimming/hiding to fake readability
- no broad UI redesign outside map board routing

## Validation

- `py -3 Tools/validate_architecture_guards.py`
- targeted map tests
- `powershell -NoProfile -ExecutionPolicy Bypass -File Tools/run_godot_scene_isolation.ps1 -ScenePath scenes/map_explore.tscn -QuitAfter 2`
- `powershell -NoProfile -ExecutionPolicy Bypass -File Tools/run_portrait_review_capture.ps1 -ScenePaths scenes/map_explore.tscn -ViewportSizes 1080x1920 -TimeoutSeconds 120`
- `git diff --check`

## Done Criteria

- visible corridors are local and roleful
- first-choice lanes are separable
- remaining corridor failures are explicit before path surfaces

## Copy/Paste Parts

### Part A - Corridor Audit

Apply only Prompt 06 Part A.

Scope:
- audit local adjacency read, center-outward route identity, route roles, same-corridor conflicts, and pocket slicing

Do not:
- patch code in Part A

Validation:
- architecture guard
- targeted map tests
- capture review if current captures are stale

Report:
- findings first
- exact corridor failures
- exact owner files involved
- exact tests needed or existing

### Part B - Corridor Routing Patch

Apply only Prompt 06 Part B.

Scope:
- land only the owner-preserving corridor routing fix justified by Part A

Do not:
- alter runtime graph ownership or save shape

Validation:
- full Prompt 06 validation stack

Report:
- files changed
- exact corridor behavior changed
- evidence delta from captures/tests
- remaining road-read gaps

### Part C - Corridor Recheck

Apply only Prompt 06 Part C.

Scope:
- recheck corridor hierarchy and same-corridor conflict across seeds `11`, `29`, `41`, plus at least two additional random seeds unless explicitly deferred with reason

Do not:
- claim roads are terrain surfaces yet; Prompt 09 owns canvas/default-lane proof

Validation:
- full Prompt 06 validation stack

Report:
- findings first
- whether Prompt 07 can start
- exact remaining corridor blockers
