# Prompt 07 - Render Model Core Payload

Use this prompt after Prompt 06 closes corridor routing.
This pack creates the first UI-only `render_model` core payload.
It does not add masks/slots and does not switch the canvas default lane; Prompt 08 owns masks/slots and Prompt 09 owns canvas/default-lane proof.

Checked-in filename note:
- this pack lives at `Docs/Promts/07_render_model_core_payload.md`

Read first:
- `AGENTS.md`
- `Docs/DOC_PRECEDENCE.md`
- `Docs/MAP_CONTRACT.md`
- `Docs/MAP_COMPOSER_V2_DESIGN.md`
- `Docs/SOURCE_OF_TRUTH.md`
- `Docs/TEST_STRATEGY.md`
- Prompt 06 output
- `Game/UI/map_board_composer_v2.gd`
- `Game/UI/map_board_canvas.gd`
- `Game/UI/map_board_style.gd`
- `Game/UI/map_board_ground_builder.gd`
- related map canvas/composer tests

Preflight:
- touched owner layer: `Game/UI derived presentation/render model + related Tests`
- authority doc: `Docs/MAP_CONTRACT.md` plus `Docs/SOURCE_OF_TRUTH.md`
- impact: `runtime truth unchanged / save shape unchanged / asset-provenance unchanged`
- minimum validation set: `validate_architecture_guards + targeted map tests + scene isolation + portrait capture + git diff --check`

## Goal

Introduce a nested presentation render model core on the composer output.
Current repo truth has no live `render_model`; treat this as a new derived payload, not a polish/formalization pass.

Core fields for this prompt:
- `render_model.schema_version = 1`
- `render_model.orientation_profile_id` or equivalent center-outward emphasis metadata, if available from Prompt 04
- `path_surfaces`
- `junctions`
- `clearing_surfaces`

The payload must be deterministic, derived from existing graph/layout/corridor truth, and ready for Prompt 08 to add masks/slots before Prompt 09 draws roads as walkable dirt/stone surfaces.

## Required Outcomes

- render model is derived from graph/layout/corridor truth
- `render_model.schema_version` is present and equals `1`
- `path_surfaces` carry width, role, endpoints, cardinal/outward route hint, shape/polygon or equivalent surface metadata
- `junctions` blend local choices and branch throats
- `clearing_surfaces` connect to road endpoints
- metadata needed to keep north/south/east/west route reads consistent is derived and non-save
- a legacy field mapping table is written in the report for `layout_edges`, `visible_edges`, `ground_shapes`, `filler_shapes`, and `forest_shapes`
- every legacy field is labeled as current default, wrapper, fallback, or retired candidate; no ambiguous co-live default claim is allowed
- masks/slots are explicitly deferred to Prompt 08
- no default-lane switch is claimed in this prompt

## Hard Guardrails

- no gameplay truth in UI
- no runtime/save/flow/source-of-truth change
- no new assets or provenance changes
- no hiding road failure with darkness/alpha
- no broad app UI redesign
- no canvas default-lane switch without screenshot/readback evidence
- candidate art is never structural proof
- no masks/slots scope creep; Prompt 08 owns that payload slice

## Validation

- `py -3 Tools/validate_architecture_guards.py`
- targeted map tests
- `powershell -NoProfile -ExecutionPolicy Bypass -File Tools/run_godot_scene_isolation.ps1 -ScenePath scenes/map_explore.tscn -QuitAfter 2`
- `powershell -NoProfile -ExecutionPolicy Bypass -File Tools/run_portrait_review_capture.ps1 -ScenePaths scenes/map_explore.tscn -ViewportSizes 1080x1920 -TimeoutSeconds 120`
- `git diff --check`

## Done Criteria

- core render model fields exist or exact blocker is stated
- payload shape is tested as structure, not only color constants
- legacy top-level fields are explicitly listed as still-live, wrapper, fallback, or retired candidates
- masks/slots are explicitly deferred to Prompt 08
- default-lane switch is explicitly deferred to Prompt 09
- no screenshot/readback-short result is labeled green

## Copy/Paste Parts

### Part A - Core Render Model Audit

Apply only Prompt 07 Part A.

Scope:
- audit current composition payload against required core `render_model` fields and legacy payload lanes

Do not:
- patch code in Part A
- switch canvas default lane

Validation:
- architecture guard
- targeted map tests

Report:
- findings first
- exact missing core render-model fields
- exact legacy fields still default/live
- exact fallback/wrapper/retired candidates
- exact legacy field mapping table needed before Prompt 08
- exact files to change in Part B

### Part B - Core Render Model Payload Patch

Apply only Prompt 07 Part B.

Scope:
- add the smallest UI-only core `render_model` payload for roads, junctions, and clearings
- land a legacy field status table in the same patch: for `layout_edges`, `visible_edges`, `ground_shapes`, `filler_shapes`, and `forest_shapes`, label each as current default, wrapper, fallback, or retired candidate

Do not:
- change runtime graph/save/flow ownership
- add candidate art
- switch the canvas default lane
- add canopy masks, landmark slots, or decor slots

Validation:
- full Prompt 07 validation stack

Report:
- files changed
- exact core render-model fields added
- legacy field status table: current default/wrapper/fallback/retired candidate
- before/after screenshot paths
- exact remaining masks/slots blocker for Prompt 08
- exact remaining canvas/default-lane blocker for Prompt 09

### Part C - Render Model Recheck

Apply only Prompt 07 Part C.

Scope:
- recheck core payload shape, legacy lane status, and Prompt 08 readiness

Do not:
- overclaim masks/slots or path-surface visual success; Prompt 08 and Prompt 09 own those

Validation:
- full Prompt 07 validation stack

Report:
- findings first
- whether Prompt 08 can start
- remaining render-model or legacy-lane blockers
