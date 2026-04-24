# Prompt 51 - Map Corridor Routing And Road Hierarchy

Use this prompt only after Prompt 50 is closed green.
This pack makes roads the first-read structure again.

Checked-in filename note:
- this pack lives at `Docs/Promts/51_map_corridor_routing_road_hierarchy.md`

Read first:
- `AGENTS.md`
- `Docs/DOC_PRECEDENCE.md`
- `Docs/MAP_CONTRACT.md`
- `Docs/MAP_COMPOSER_V2_DESIGN.md`
- Prompt `43-50` outputs
- Prompt `47.5` structural metrics outputs
- Prompt `57` baseline harness outputs
- `Game/UI/map_board_composer_v2.gd`
- `Game/UI/map_board_canvas.gd`
- `Game/UI/map_route_binding.gd`
- `Game/UI/map_route_layout_helper.gd`
- directly related map tests

Preflight:
- touched owner layer: `Game/UI + scenes`
- authority doc: `Docs/MAP_CONTRACT.md`
- impact: `runtime truth unchanged / save shape unchanged / asset-provenance unchanged`
- minimum validation set: `validate_architecture_guards + targeted map tests + portrait seed sweep + full suite checkpoint`

## Goal

Move roads from "curves that rescue node placement" to "corridor-driven structure that defines the board and creates pockets."

## Required Road Outcomes

- primary actionable corridors
- branch corridors
- reconnect corridors
- actionable lane visually dominant
- history lane visible but secondary
- reconnect lane tertiary
- braid-like overlap is a blocker
- roads must define pockets, not just connect nodes
- roads must preserve strong directional read
- roads must help create landmark pockets instead of slicing through them randomly
- roads cutting directly through landmark space is failure

## Hard Guardrails

- No movement truth in UI.
- No camera-follow reintroduction.
- No fake success by simply dimming or hiding half the roads.

## Validation

- `py -3 Tools/validate_architecture_guards.py`
- `powershell -NoProfile -ExecutionPolicy Bypass -File Tools/run_godot_tests.ps1 -Tests test_map_board_composer_v2.gd,test_map_board_canvas.gd -TimeoutSeconds 240`
- `powershell -NoProfile -ExecutionPolicy Bypass -File Tools/run_godot_scene_isolation.ps1 -ScenePath scenes/map_explore.tscn -QuitAfter 2`
- `powershell -NoProfile -ExecutionPolicy Bypass -File Tools/run_portrait_review_capture.ps1 -ScenePaths scenes/map_explore.tscn -ViewportSizes 1080x1920 -TimeoutSeconds 120`
- `powershell -NoProfile -ExecutionPolicy Bypass -File Tools/run_godot_full_suite.ps1`
- `git diff --check`

## Done Criteria

- roads are the first-read board structure
- major overlaps are gone or clearly non-blocking
- current actionable routes are obvious at a glance
- roads help carve readable pockets instead of only linking node centers

## Copy/Paste Parts

### Part A - Road Audit

```text
Apply only Prompt 51 Part A.

Scope:
- Audit the current road hierarchy and corridor behavior against the new target.

Do not:
- patch code in Part A

Validation:
- validate_architecture_guards
- targeted map tests
- portrait capture

Report:
- exact hierarchy failures
- exact overlap/braid failures
- screenshot paths reviewed
```

### Part B - Corridor And Hierarchy Implementation

```text
Apply only Prompt 51 Part B.

Scope:
- Implement corridor-based routing and stronger road hierarchy.

Required outcomes:
- primary corridors
- branch corridors
- reconnect corridors
- visible dominance order
- reduced overlap/braid ambiguity

Do not:
- move traversal truth into UI
- widen into landmark or asset work except narrow supporting changes

Validation:
- validate_architecture_guards
- targeted map tests
- portrait seed sweep
- full suite checkpoint
- git diff --check

Report:
- files changed
- exact corridor hierarchy landed
- before/after screenshot paths
- checkpoint:
  - whether roads now define pockets clearly enough
  - whether any legacy route lane still remains live
  - exact next-prompt risks for Prompt `52-54`
```
