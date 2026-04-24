# Prompt 12 - Terrain Canopy Negative Space

Use this prompt after Prompt 11 closes landmark pocket truth.
This pack makes terrain, filler, and canopy reinforce roads/pockets instead of rescuing weak structure.

Checked-in filename note:
- this pack lives at `Docs/Promts/12_terrain_canopy_negative_space.md`

Read first:
- `AGENTS.md`
- `Docs/DOC_PRECEDENCE.md`
- `Docs/MAP_CONTRACT.md`
- `Docs/MAP_COMPOSER_V2_DESIGN.md`
- `Docs/SOURCE_OF_TRUTH.md`
- `Docs/TEST_STRATEGY.md`
- Prompt 11 output
- `Game/UI/map_board_ground_builder.gd`
- `Game/UI/map_board_backdrop_builder.gd`
- `Game/UI/map_board_filler_builder.gd`
- `Game/UI/map_board_canvas.gd`
- `Game/UI/map_board_style.gd`
- related map tests

Preflight:
- touched owner layer: `Game/UI terrain/canopy/filler presentation + related Tests`
- authority doc: `Docs/MAP_CONTRACT.md` plus `Docs/SOURCE_OF_TRUTH.md`
- impact: `runtime truth unchanged / save shape unchanged / asset-provenance unchanged`
- minimum validation set: `validate_architecture_guards + targeted map tests + scene isolation + portrait capture + full suite + git diff --check`

## Goal

Make terrain and canopy define negative space around the board:
- canopy/undergrowth frames roads and clearings
- filler never invades path surfaces or pocket cores
- dark blobs and abstract ellipses are removed, replaced, or clearly downgraded as fallback
- empty space separates routes and pockets on purpose
- terrain/canopy keeps all meaningful cardinal route sides readable around the center-local opening
- terrain reads as small-world ground, not a muddy slab

## Required Outcomes

- canopy/filler masks derive from path and clearing surfaces
- road and pocket exclusion zones are explicit
- filler density stays sparse and purposeful
- upper-board, lower-board, and side-board terrain support structure rather than hiding it
- candidate art remains closed

## Hard Guardrails

- no new asset files or provenance changes
- no terrain/filler used to fake missing roads or pockets
- no runtime/save/flow/source-of-truth change
- no broad palette-only pass

## Validation

- `py -3 Tools/validate_architecture_guards.py`
- targeted map tests
- `powershell -NoProfile -ExecutionPolicy Bypass -File Tools/run_godot_scene_isolation.ps1 -ScenePath scenes/map_explore.tscn -QuitAfter 2`
- `powershell -NoProfile -ExecutionPolicy Bypass -File Tools/run_portrait_review_capture.ps1 -ScenePaths scenes/map_explore.tscn -ViewportSizes 1080x1920 -TimeoutSeconds 120`
- `powershell -NoProfile -ExecutionPolicy Bypass -File Tools/run_godot_full_suite.ps1`
- `git diff --check`

## Done Criteria

- terrain/canopy/filler reinforces structure
- black/dark blob failure is honestly resolved or still explicit
- scene-shell and asset-socket work can start only as readiness, not asset proof

## Copy/Paste Parts

### Part A - Terrain And Negative-Space Audit

Apply only Prompt 12 Part A.

Scope:
- audit terrain, canopy, filler, dark blobs, and negative-space behavior

Do not:
- patch code in Part A

Validation:
- architecture guard
- targeted map tests
- capture review

Report:
- findings first
- exact blob/filler/terrain failures
- exact old fallback surfaces
- exact files to change in Part B

### Part B - Terrain Mask Patch

Apply only Prompt 12 Part B.

Scope:
- land only derived terrain/canopy/filler fixes that follow path and pocket structure

Do not:
- add candidate assets
- change runtime graph truth

Validation:
- full Prompt 12 validation stack

Report:
- files changed
- exact mask/exclusion behavior changed
- before/after screenshot paths
- remaining terrain blockers

### Part C - Terrain Recheck

Apply only Prompt 12 Part C.

Scope:
- recheck terrain/canopy/negative-space read across live and seeded captures for seeds `11`, `29`, `41`, plus at least two additional random seeds unless explicitly deferred with reason

Do not:
- overclaim scene-shell or asset readiness if blockers still exist

Validation:
- full Prompt 12 validation stack

Report:
- findings first
- whether Prompt 13 can start
- remaining terrain/filler blockers
