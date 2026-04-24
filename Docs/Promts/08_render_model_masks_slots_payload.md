# Prompt 08 - Render Model Masks Slots Payload

Use this prompt after Prompt 07 lands or blocks the core `render_model` payload.
This pack extends the UI-only `render_model` with masks and asset-ready socket metadata.
It does not switch the canvas default lane; Prompt 09 owns canvas/default-lane proof.

Checked-in filename note:
- this pack lives at `Docs/Promts/08_render_model_masks_slots_payload.md`

Read first:
- `AGENTS.md`
- `Docs/DOC_PRECEDENCE.md`
- `Docs/MAP_CONTRACT.md`
- `Docs/MAP_COMPOSER_V2_DESIGN.md` (reference-only, especially Fixed-Board Visual System Rules 1-7)
- `Docs/SOURCE_OF_TRUTH.md`
- `Docs/ASSET_PIPELINE.md`
- `Docs/ASSET_LICENSE_POLICY.md`
- `Docs/TEST_STRATEGY.md`
- Prompt 07 output
- `Game/UI/map_board_composer_v2.gd`
- `Game/UI/map_board_canvas.gd`
- `Game/UI/map_board_ground_builder.gd`
- `Game/UI/map_board_filler_builder.gd`
- `Game/UI/map_board_backdrop_builder.gd`
- related map canvas/composer tests

Preflight:
- touched owner layer: `Game/UI derived presentation/render model + related Tests`
- authority doc: `Docs/MAP_CONTRACT.md` plus `Docs/SOURCE_OF_TRUTH.md`; asset-readiness metadata also defers to `Docs/ASSET_PIPELINE.md` and `Docs/ASSET_LICENSE_POLICY.md`
- impact: `runtime truth unchanged / save shape unchanged / asset-provenance unchanged`
- minimum validation set: `validate_assets + validate_architecture_guards + targeted map tests + scene isolation + portrait capture + git diff --check`

## Goal

Extend `render_model.schema_version = 1` with the non-core payload needed by later terrain, pocket, and asset-socket passes:
- `canopy_masks`
- `landmark_slots`
- `decor_slots`

The payload must stay deterministic and derived from graph/layout/corridor/core render-model truth.
It must make later asset dressing easier without adding assets or using asset metadata as structural proof.

## Required Outcomes

- `canopy_masks` describe where canopy/undergrowth may frame roads and clearings
- `landmark_slots` expose family, role, cardinal/outward route relationship, rotation, scale, and anchor point
- `decor_slots` expose route/clearing/cardinal-side relationship
- masks and slots preserve center-local opening and north/south/east/west route reads
- masks and slots are checked against Fixed-Board Visual System Rules 1-7 as a reference lens, not as authority
- legacy field mapping from Prompt 07 is updated, especially for `ground_shapes`, `filler_shapes`, and `forest_shapes`
- every legacy field remains labeled as current default, wrapper, fallback, or retired candidate
- no canvas default-lane switch is claimed
- no assets or source art are added

## Hard Guardrails

- no gameplay truth in UI
- no runtime/save/flow/source-of-truth change
- no new assets or provenance changes
- no candidate art
- no default-lane switch
- no broad terrain, pocket, or asset hookup implementation

## Validation

- `py -3 Tools/validate_assets.py`
- `py -3 Tools/validate_architecture_guards.py`
- targeted map tests
- `powershell -NoProfile -ExecutionPolicy Bypass -File Tools/run_godot_scene_isolation.ps1 -ScenePath scenes/map_explore.tscn -QuitAfter 2`
- `powershell -NoProfile -ExecutionPolicy Bypass -File Tools/run_portrait_review_capture.ps1 -ScenePaths scenes/map_explore.tscn -ViewportSizes 1080x1920 -TimeoutSeconds 120`
- `git diff --check`

## Done Criteria

- masks and slots exist or exact blocker is stated
- payload shape is tested as structure, not only color constants
- legacy field mapping is explicit and still honest
- Prompt 09 has enough payload to audit canvas/default-lane switching
- no screenshot/readback-short result is labeled green

## Copy/Paste Parts

### Part A - Masks Slots Audit

Apply only Prompt 08 Part A.

Scope:
- audit current composition payload against required mask and slot fields
- audit legacy field mapping from Prompt 07 for `ground_shapes`, `filler_shapes`, and `forest_shapes`

Do not:
- patch code in Part A
- switch canvas default lane
- add assets

Validation:
- `py -3 Tools/validate_assets.py`
- architecture guard
- targeted map tests

Report:
- findings first
- exact missing mask/slot fields
- exact legacy fields still default/live
- exact fallback/wrapper/retired candidates
- Fixed-Board Visual System Rules 1-7 mask/slot gaps
- exact files to change in Part B

### Part B - Masks Slots Payload Patch

Apply only Prompt 08 Part B.

Scope:
- add the smallest UI-only `render_model` payload for canopy masks, landmark slots, and decor slots

Do not:
- change runtime graph/save/flow ownership
- add candidate art
- switch canvas default lane
- implement broad terrain or asset rendering

Validation:
- full Prompt 08 validation stack

Report:
- files changed
- exact mask/slot fields added
- legacy field status: live/wrapper/fallback/retired candidate
- Fixed-Board Visual System Rules 1-7 gaps changed or still open
- before/after screenshot paths
- exact remaining canvas/default-lane blocker for Prompt 09

### Part C - Masks Slots Recheck

Apply only Prompt 08 Part C.

Scope:
- recheck masks/slots payload shape, legacy lane status, and Prompt 09 readiness

Do not:
- overclaim path-surface visual success; Prompt 09 owns canvas/default-lane proof

Validation:
- full Prompt 08 validation stack

Report:
- findings first
- whether Prompt 09 can start
- remaining mask/slot or legacy-lane blockers
- remaining Fixed-Board Visual System Rules 1-7 mask/slot gaps
