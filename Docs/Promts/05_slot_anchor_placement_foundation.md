# Prompt 05 - Slot Anchor Placement Foundation

Use this prompt after Prompt 04 closes the runtime topology truth.
This pack makes derived UI placement consume sector-local anchors instead of drifting back to centroid/scatter behavior.

Checked-in filename note:
- this pack lives at `Docs/Promts/05_slot_anchor_placement_foundation.md`

Read first:
- `AGENTS.md`
- `Docs/DOC_PRECEDENCE.md`
- `Docs/MAP_CONTRACT.md`
- `Docs/MAP_COMPOSER_V2_DESIGN.md`
- `Docs/SOURCE_OF_TRUTH.md`
- `Docs/TEST_STRATEGY.md`
- Prompt 04 output
- `Game/UI/map_board_composer_v2.gd`
- `Game/UI/map_board_layout_solver.gd`
- `Game/UI/map_board_slot_anchor_layout.gd` if present
- related map composer tests

Preflight:
- touched owner layer: `Game/UI derived placement + related Tests`
- authority doc: `Docs/MAP_CONTRACT.md` plus `Docs/SOURCE_OF_TRUTH.md`
- impact: `runtime truth unchanged / save shape unchanged / asset-provenance unchanged`
- minimum validation set: `validate_architecture_guards + targeted map composer tests + scene isolation + portrait capture + git diff --check`

## Goal

Make node placement feel like a controlled procedural board:
- center-local start anchor with deterministic outward-emphasis variation
- sector-local slot anchors with deterministic jitter
- no visible grid or centroid stacking
- board portrait area used meaningfully
- each seed has a distinct silhouette while staying readable

## Required Outcomes

- placement is derived from runtime graph truth but does not own gameplay state
- start anchor stays center-local by default; deterministic orientation/emphasis profiles vary outward route shape unless a documented stage-shape exception exists
- first choices spread into distinct sectors/lanes
- upper, lower, and side board areas receive meaningful structure across representative seeds
- slots/anchors remain deterministic from seed, graph signature, and board size
- `BASE_CENTER_FACTOR` is checked against center-local start intent rather than assumed correct
- existing `DEPTH_*_FACTORS` radial/depth placement constants are audited against sector-local anchors so old and new placement systems do not silently become co-live defaults
- anchor payload is testable and does not include save/gameplay truth

## Hard Guardrails

- no runtime graph ownership move
- no save/flow/source-of-truth change
- no asset work
- no hidden visible sector grid
- no broad styling-only rescue

## Validation

- `py -3 Tools/validate_architecture_guards.py`
- `powershell -NoProfile -ExecutionPolicy Bypass -File Tools/run_godot_tests.ps1 -Tests test_map_board_composer_v2.gd,test_map_board_canvas.gd,test_map_review_capture_helper.gd,test_map_quest_log_ui.gd -TimeoutSeconds 240`
- `powershell -NoProfile -ExecutionPolicy Bypass -File Tools/run_godot_scene_isolation.ps1 -ScenePath scenes/map_explore.tscn -QuitAfter 2`
- `powershell -NoProfile -ExecutionPolicy Bypass -File Tools/run_portrait_review_capture.ps1 -ScenePaths scenes/map_explore.tscn -ViewportSizes 1080x1920 -TimeoutSeconds 120`
- `git diff --check`

## Done Criteria

- placement has an explicit slot/anchor foundation
- start and first-choice layout satisfy target evidence or blockers remain explicit
- no runtime/save ownership drift

## Copy/Paste Parts

### Part A - Placement Audit

Apply only Prompt 05 Part A.

Scope:
- audit current placement against sector-local anchor target, `BASE_CENTER_FACTOR`, `DEPTH_*_FACTORS`, and current captures

Do not:
- patch code in Part A

Validation:
- architecture guard
- targeted map composer tests

Report:
- findings first
- exact centroid/scatter/unused-board failures
- exact `BASE_CENTER_FACTOR` read and whether it still counts as center-local
- exact `DEPTH_*_FACTORS` vs sector-anchor co-live risk
- exact files to change in Part B

### Part B - Slot Anchor Patch

Apply only Prompt 05 Part B.

Scope:
- add or tighten the UI-only slot/anchor placement foundation

Do not:
- change runtime graph truth or save shape

Validation:
- full Prompt 05 validation stack

Report:
- files changed
- exact placement fields/behavior added
- screenshot/readback evidence delta
- remaining placement gaps

### Part C - Placement Recheck

Apply only Prompt 05 Part C.

Scope:
- recheck live and seeded placement silhouettes across seeds `11`, `29`, `41`, plus at least two additional random seeds unless explicitly deferred with reason

Do not:
- treat better spread as corridor/path success

Validation:
- full Prompt 05 validation stack

Report:
- findings first
- whether Prompt 06 can start
- remaining slot/anchor blockers
