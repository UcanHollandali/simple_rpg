# Prompt 09 - Path Surface Canvas And Default Lane

Use this prompt after Prompt 08 lands or confirms the `render_model` masks/slots payload.
This pack makes the canvas draw roads/clearings from `render_model` and may switch the default presentation lane only with evidence.

Checked-in filename note:
- this pack lives at `Docs/Promts/09_path_surface_canvas_and_default_lane.md`

Read first:
- `AGENTS.md`
- `Docs/DOC_PRECEDENCE.md`
- `Docs/MAP_CONTRACT.md`
- `Docs/MAP_COMPOSER_V2_DESIGN.md` (reference-only, especially Fixed-Board Visual System Rules 1-7)
- `Docs/SOURCE_OF_TRUTH.md`
- `Docs/TEST_STRATEGY.md`
- Prompt 08 output
- `Game/UI/map_board_composer_v2.gd`
- `Game/UI/map_board_canvas.gd`
- `Game/UI/map_board_style.gd`
- `Game/UI/map_board_ground_builder.gd`
- `Game/UI/map_board_filler_builder.gd`
- `Game/UI/map_board_backdrop_builder.gd`
- related map canvas/composer tests

Preflight:
- touched owner layer: `Game/UI map canvas/default presentation lane + related Tests`
- authority doc: `Docs/MAP_CONTRACT.md` plus `Docs/SOURCE_OF_TRUTH.md`
- impact: `runtime truth unchanged / save shape unchanged / asset-provenance unchanged`
- minimum validation set: `validate_architecture_guards + targeted map tests + scene isolation + portrait capture + full suite + git diff --check`

## Goal

Make visible roads read as walkable terrain surfaces instead of polyline strokes:
- center-local start roads fan into readable north/south/east/west surfaces
- canvas reads from `render_model.path_surfaces`
- junctions blend route choices and branch throats
- clearings connect to road endpoints
- icon/plate overlays become secondary to the surface read
- exactly one default presentation lane is named if evidence supports the switch

## Required Outcomes

- map canvas consumes `render_model` for path surfaces, junctions, and clearing surfaces
- old stroke/decal roads are no longer the default lane unless the prompt explicitly fails/defers the switch
- if legacy fields such as `visible_edges`, `ground_shapes`, `filler_shapes`, or `forest_shapes` remain, they are labeled `wrapper`, `fallback`, or `retired`
- canvas draw order is documented and justified, including where path surfaces, junctions, clearings, pockets, decals, canopy, and decor draw relative to each other
- default-lane status is backed by fresh screenshot/readback evidence, not test green alone
- screenshot/readback specifically checks that the map does not collapse back into a one-direction ladder
- path-surface and draw-order decisions are reported against Fixed-Board Visual System Rules 1-7 as a reference lens, not as authority
- path-surface read is evaluated without candidate art

## Hard Guardrails

- no gameplay truth in UI
- no runtime/save/flow/source-of-truth change
- no new assets or provenance changes
- no hiding road failure with darkness/alpha
- no broad app UI redesign
- no default-lane switch if screenshot/readback remains structurally short

## Validation

- `py -3 Tools/validate_architecture_guards.py`
- targeted map tests
- `powershell -NoProfile -ExecutionPolicy Bypass -File Tools/run_godot_scene_isolation.ps1 -ScenePath scenes/map_explore.tscn -QuitAfter 2`
- `powershell -NoProfile -ExecutionPolicy Bypass -File Tools/run_portrait_review_capture.ps1 -ScenePaths scenes/map_explore.tscn -ViewportSizes 1080x1920 -TimeoutSeconds 120`
- `powershell -NoProfile -ExecutionPolicy Bypass -File Tools/run_godot_full_suite.ps1`
- `git diff --check`

## Done Criteria

- roads are canvas-rendered from `render_model` or exact blocker is stated
- path surfaces are tested as structure, not only color constants
- fresh screenshots compare road read before/after
- exactly one intended default presentation lane is named, or switch deferral is explicit
- non-default road lanes are labeled `wrapper`, `fallback`, or `retired`

## Copy/Paste Parts

### Part A - Canvas Lane Audit

Apply only Prompt 09 Part A.

Scope:
- audit canvas drawing order, default road lane, center-outward surface read, and `render_model` consumption

Do not:
- patch code in Part A

Validation:
- architecture guard
- targeted map tests

Report:
- findings first
- exact canvas paths still drawing stroke/decal roads
- exact `render_model` fields unused
- exact current draw order and proposed draw-order changes
- exact default/wrapper/fallback/retired lane candidates
- Fixed-Board Visual System Rules 1-7 path-surface gaps
- exact files to change in Part B

### Part B - Path Surface Canvas Patch

Apply only Prompt 09 Part B.

Scope:
- land only UI-only canvas/default-lane fixes that draw roads, junctions, and clearings from `render_model`

Do not:
- change runtime graph/save/flow ownership
- add candidate art
- label a structurally short screenshot as green

Validation:
- full Prompt 09 validation stack

Report:
- files changed
- exact canvas behavior changed
- exact draw order landed and why it preserves pocket/road read
- default lane status with evidence
- Fixed-Board Visual System Rules 1-7 gaps changed or still open
- before/after screenshot paths
- exact remaining path-surface gap

### Part C - Default Lane Recheck

Apply only Prompt 09 Part C.

Scope:
- recheck live and seeded road-surface read and default-lane status across seeds `11`, `29`, `41`, plus at least two additional random seeds unless explicitly deferred with reason

Do not:
- overclaim walker, landmark, terrain, or asset-socket success; later prompts own those

Validation:
- full Prompt 09 validation stack

Report:
- findings first
- whether Prompt 10 can start
- exactly one default lane or explicit switch deferral
- every non-default lane status
- remaining path-surface blockers
- remaining Fixed-Board Visual System Rules 1-7 path-surface gaps
