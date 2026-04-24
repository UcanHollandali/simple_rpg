# Prompt 54 - Map Terrain Masks Clearings And Negative Space

Use this prompt only after Prompt 53 is closed green.
This pack makes terrain, clearings, and filler serve the route/landmark structure instead of fighting it.

Checked-in filename note:
- this pack lives at `Docs/Promts/54_map_terrain_masks_clearings_negative_space.md`

Read first:
- `AGENTS.md`
- `Docs/DOC_PRECEDENCE.md`
- `Docs/MAP_CONTRACT.md`
- `Docs/MAP_COMPOSER_V2_DESIGN.md`
- Prompt `43-53` outputs
- Prompt `47.5` structural metrics outputs
- Prompt `57` baseline harness outputs
- `Game/UI/map_board_ground_builder.gd`
- `Game/UI/map_board_filler_builder.gd`
- `Game/UI/map_board_canvas.gd`
- related map tests

Preflight:
- touched owner layer: `Game/UI`
- authority doc: `Docs/MAP_CONTRACT.md`
- impact: `runtime truth unchanged / save shape unchanged / asset-provenance unchanged by default`
- minimum validation set: `validate_architecture_guards + targeted map tests + portrait seed sweep + full suite checkpoint`

## Goal

Make terrain and filler follow the route/landmark structure so the board reads as real pockets instead of one muddy slab plus decor.

## Required Outcomes

- road exclusion masks
- landmark exclusion masks
- clearing masks
- pocket terrain masks
- true negative-space filler zones
- no giant center slab
- no filler invading major route lanes or landmark pockets
- landmark pockets keep a local clearing that roads, filler, and canopy do not pollute

## Hard Guardrails

- No graph-truth change.
- No asset approval change.
- Do not use filler to fake missing structure.
- Asset, terrain, and filler may not rescue weak roads, weak pockets, or weak landmark identity.

## Validation

- `py -3 Tools/validate_architecture_guards.py`
- `powershell -NoProfile -ExecutionPolicy Bypass -File Tools/run_godot_tests.ps1 -Tests test_map_board_composer_v2.gd,test_map_board_canvas.gd -TimeoutSeconds 240`
- `powershell -NoProfile -ExecutionPolicy Bypass -File Tools/run_godot_scene_isolation.ps1 -ScenePath scenes/map_explore.tscn -QuitAfter 2`
- `powershell -NoProfile -ExecutionPolicy Bypass -File Tools/run_portrait_review_capture.ps1 -ScenePaths scenes/map_explore.tscn -ViewportSizes 1080x1920 -TimeoutSeconds 120`
- `powershell -NoProfile -ExecutionPolicy Bypass -File Tools/run_godot_full_suite.ps1`
- `git diff --check`

## Done Criteria

- terrain no longer flattens the board into one central mass
- negative space becomes useful
- filler strengthens structure instead of confusing it

## Copy/Paste Parts

### Part A - Terrain/Filler Audit

```text
Apply only Prompt 54 Part A.

Scope:
- Audit current terrain/clearing/filler behavior against the new mask-driven target.

Do not:
- patch code in Part A

Validation:
- validate_architecture_guards
- targeted map tests
- portrait seed sweep

Report:
- exact ground/filler failures
- exact places where negative space is still being wasted
- screenshot paths reviewed
```

### Part B - Mask And Negative-Space Implementation

```text
Apply only Prompt 54 Part B.

Scope:
- Implement terrain masks, clearing masks, and negative-space filler zones that follow the structure from Prompt 47-53.

Do not:
- change graph truth
- widen into candidate asset approval work

Validation:
- validate_architecture_guards
- targeted map tests
- portrait seed sweep
- full suite checkpoint
- git diff --check

Report:
- files changed
- exact terrain/filler behavior replaced
- before/after screenshot paths
- checkpoint:
  - whether terrain/filler is still rescuing weak structure anywhere
  - whether any legacy ground/filler lane still remains live
  - exact next-prompt risks for Prompt `55-58`
```
