# Prompt 50 - Map Slot Anchor Placement System

Use this prompt only after Prompt 49 is closed green.
This pack replaces the old free-form rescue-heavy placement model with sector slot/anchor placement.

Checked-in filename note:
- this pack lives at `Docs/Promts/50_map_slot_anchor_placement_system.md`

Read first:
- `AGENTS.md`
- `Docs/DOC_PRECEDENCE.md`
- `Docs/MAP_CONTRACT.md`
- `Docs/MAP_COMPOSER_V2_DESIGN.md`
- Prompt `43-49` outputs
- Prompt `47.5` structural metrics outputs
- Prompt `57` baseline harness outputs
- `Game/UI/map_board_composer_v2.gd`
- `Game/UI/map_board_layout_solver.gd`
- `Tests/test_map_board_composer_v2.gd`

Preflight:
- touched owner layer: `Game/UI`
- authority doc: `Docs/MAP_CONTRACT.md` with presentation guidance from `Docs/MAP_COMPOSER_V2_DESIGN.md`
- impact: `runtime truth unchanged / save shape unchanged / asset-provenance unchanged`
- minimum validation set: `validate_architecture_guards + targeted map tests + portrait seed sweep + full suite checkpoint`

## Goal

Stop positioning nodes as free XY points that are later clamped and relaxed into something barely acceptable.

## Required Placement Rules

- sector-local slot anchors
- deterministic seeded anchor choice
- minimum spacing
- depth bias
- anchor jitter
- empty-slot behavior
- sibling spread
- side-by-side replacement:
  - new placement lane first
  - old solver may survive only as wrapper/orchestrator/fallback until green switch
- old clamp/collision-relax may remain as a narrow rescue layer only, not the primary model
- nodes must not default to sector center
- default occupancy should usually read sparse and organic, often `0-2` nodes per sector
- visible symmetry, visible checkerboard, or centered-per-cell read is failure

## Hard Guardrails

- No graph truth move into UI.
- No save-shape change.
- No camera-follow regression.
- Do not fake success by only shrinking node plates or icons.

## Validation

- `py -3 Tools/validate_architecture_guards.py`
- `powershell -NoProfile -ExecutionPolicy Bypass -File Tools/run_godot_tests.ps1 -Tests test_map_board_composer_v2.gd,test_map_board_canvas.gd -TimeoutSeconds 240`
- `powershell -NoProfile -ExecutionPolicy Bypass -File Tools/run_godot_scene_isolation.ps1 -ScenePath scenes/map_explore.tscn -QuitAfter 2`
- `powershell -NoProfile -ExecutionPolicy Bypass -File Tools/run_portrait_review_capture.ps1 -ScenePaths scenes/map_explore.tscn -ViewportSizes 1080x1920 -TimeoutSeconds 120`
- `powershell -NoProfile -ExecutionPolicy Bypass -File Tools/run_godot_full_suite.ps1`
- `git diff --check`

## Done Criteria

- node placement is visibly sector/anchor-driven
- lower-half usage materially improves
- directionality becomes stronger without graph-truth drift
- placement reads like hidden structure with organic scatter, not a dama-tahtasi pattern
- replacement mode is explicit rather than a silent in-place nudge

## Copy/Paste Parts

### Part A - Placement Audit

```text
Apply only Prompt 50 Part A.

Scope:
- Audit the current placement chain and name exactly where free-form rescue behavior still dominates.

Do not:
- patch code in Part A

Validation:
- validate_architecture_guards
- targeted map tests
- portrait capture

Report:
- exact files/functions dominating placement
- exact rescue-only helpers that may remain narrow
- exact surfaces that should become wrapper/orchestrator/fallback only
- current screenshot paths reviewed
```

### Part B - Slot/Anchor Implementation

```text
Apply only Prompt 50 Part B.

Scope:
- Implement sector-local slot/anchor placement as the primary model.

Required outcomes:
- sector slot anchors
- deterministic seeded choice
- min spacing
- sibling spread
- anchor jitter
- lower-half usage improvement

Do not:
- change graph truth ownership
- widen into corridor styling or asset work

Validation:
- validate_architecture_guards
- targeted map tests
- portrait seed sweep
- full suite checkpoint
- git diff --check

Report:
- files changed
- exact placement behavior replaced
- exact old surfaces that remain wrapper/orchestrator/fallback only
- before/after screenshot paths
- checkpoint:
  - whether visible grid/cell-centering risk still remains
  - whether any legacy placement lane still remains live
  - exact next-prompt risks for Prompt `51`
```
