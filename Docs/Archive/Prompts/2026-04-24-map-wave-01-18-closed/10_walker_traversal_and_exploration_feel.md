# Prompt 10 - Walker Traversal And Exploration Feel

Use this prompt after Prompt 09 lands or defers the path-surface canvas/default lane.
This pack makes the player character feel like they walk on the board and makes hunger pressure visible through route choice.

Checked-in filename note:
- this pack lives at `Docs/Promts/10_walker_traversal_and_exploration_feel.md`

Read first:
- `AGENTS.md`
- `Docs/DOC_PRECEDENCE.md`
- `Docs/MAP_CONTRACT.md`
- `Docs/MAP_COMPOSER_V2_DESIGN.md` (reference-only, especially Fixed-Board Visual System Rules 1-7)
- `Docs/SOURCE_OF_TRUTH.md`
- `Docs/TEST_STRATEGY.md`
- Prompt 09 output
- `Game/UI/map_route_binding.gd`
- `Game/UI/map_route_motion_helper.gd`
- `Game/UI/map_board_canvas.gd`
- `scenes/map_explore.gd`
- related map presenter/route tests

Preflight:
- touched owner layer: `Game/UI walker/route presentation + scenes wiring only if needed`
- authority doc: `Docs/MAP_CONTRACT.md` plus `Docs/SOURCE_OF_TRUTH.md`
- impact: `runtime truth unchanged / save shape unchanged / asset-provenance unchanged`
- minimum validation set: `validate_architecture_guards + targeted map tests + scene isolation + portrait capture + git diff --check`

## Goal

Make movement read as board-local traversal:
- walker starts from the center-local pocket and moves outward along the selected cardinal/branch route
- walker follows selected path surface/corridor lane
- walker enters and exits clearing/pocket throats
- route length, branch detours, support access, and boss push visibly support hunger pressure
- no visual off-corridor movement is implied

Hunger mechanics remain unchanged.

## Required Outcomes

- selected-route preview and walker movement use the same presentation path
- route motion respects clearing/pocket surfaces
- movement does not trample landmark identity cores
- north/south/east/west choices feel like different exploration commitments, not one vertical ladder
- support detours and boss/key pushes feel spatially different
- hunger pressure is reported as visual/route-shape evidence, not rule change
- walker/exploration evidence is reported against Fixed-Board Visual System Rules 1-7 as a reference lens, not as authority

## Hard Guardrails

- no hunger-rule change
- no runtime movement owner change
- no save/flow/source-of-truth change
- no candidate art
- no camera/scrolling-board regression

## Validation

- `py -3 Tools/validate_architecture_guards.py`
- targeted map route/presenter tests
- `powershell -NoProfile -ExecutionPolicy Bypass -File Tools/run_godot_scene_isolation.ps1 -ScenePath scenes/map_explore.tscn -QuitAfter 2`
- `powershell -NoProfile -ExecutionPolicy Bypass -File Tools/run_portrait_review_capture.ps1 -ScenePaths scenes/map_explore.tscn -ViewportSizes 1080x1920 -TimeoutSeconds 120`
- `git diff --check`

## Done Criteria

- walker path and route preview are visually coherent
- exploration/hunger feel is assessed honestly
- fixed board remains true

## Copy/Paste Parts

### Part A - Walker And Hunger-Feel Audit

Apply only Prompt 10 Part A.

Scope:
- audit walker pathing, selected-route preview, center-outward exploration feel, and hunger route-shape feel

Do not:
- patch code in Part A

Validation:
- architecture guard
- targeted route tests
- current captures if not stale

Report:
- findings first
- exact walker/path mismatch
- exact hunger-feel misses
- Fixed-Board Visual System Rules 1-7 walker/exploration gaps
- exact owner files for Part B

### Part B - Traversal Presentation Patch

Apply only Prompt 10 Part B.

Scope:
- land only UI/scene presentation fixes that align walker, preview, and path surfaces

Do not:
- change hunger mechanics or runtime movement truth

Validation:
- full Prompt 10 validation stack

Report:
- files changed
- exact walker/preview behavior changed
- evidence delta from capture/playtest
- Fixed-Board Visual System Rules 1-7 gaps changed or still open
- remaining exploration-feel misses

### Part C - Traversal Recheck

Apply only Prompt 10 Part C.

Scope:
- recheck live and seeded walker/exploration feel

Do not:
- claim asset-ready terrain or landmarks yet

Validation:
- full Prompt 10 validation stack

Report:
- findings first
- whether Prompt 11 can start
- remaining walker/hunger-feel blockers
- remaining Fixed-Board Visual System Rules 1-7 walker/exploration gaps
