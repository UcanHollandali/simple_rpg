# Prompt 14 - Asset Socket Readiness Gate

Use this prompt after Prompt 13 closes map scene shell and adjacent-UI read.
This pack checks whether the map is ready to be dressed with assets later. It does not add assets.

Checked-in filename note:
- this pack lives at `Docs/Promts/14_asset_socket_readiness_gate.md`

Read first:
- `AGENTS.md`
- `Docs/DOC_PRECEDENCE.md`
- `Docs/MAP_CONTRACT.md`
- `Docs/MAP_COMPOSER_V2_DESIGN.md` (reference-only, especially Fixed-Board Visual System Rules 1-7)
- `Docs/SOURCE_OF_TRUTH.md`
- `Docs/ASSET_PIPELINE.md`
- `Docs/ASSET_LICENSE_POLICY.md`
- `Docs/TEST_STRATEGY.md`
- Prompt 13 output
- `AssetManifest/asset_manifest.csv`
- `Game/UI/map_board_composer_v2.gd`
- `Game/UI/map_board_canvas.gd`
- `Game/UI/ui_asset_paths.gd`
- related map tests

Preflight:
- touched owner layer: `Game/UI asset-socket metadata + docs/tests only; no asset files`
- authority doc: `Docs/MAP_CONTRACT.md` plus `Docs/SOURCE_OF_TRUTH.md`; asset readiness/provenance decisions also defer to `Docs/ASSET_PIPELINE.md` and `Docs/ASSET_LICENSE_POLICY.md`
- impact: `runtime truth unchanged / save shape unchanged / asset-provenance unchanged unless manifest wording is corrected`
- minimum validation set: `validate_assets + validate_architecture_guards + targeted map tests + scene isolation + portrait capture + git diff --check`

## Goal

Verify asset dressing will be easy later because the structure already exposes sockets:
- path surfaces can accept path brush/tile art
- landmark slots expose family, role, cardinal/outward route relationship, rotation, scale, and anchor point
- decor slots expose route/clearing/cardinal-side relationship
- canopy masks expose edge/undergrowth placement affordances
- existing candidate assets remain provisional and are not proof

No new image, SVG, PNG, art pack, or source-art file may be added in this prompt.

## Required Outcomes

- sockets/readiness metadata is audited and, if necessary, added as derived presentation data
- sockets can dress center-local and north/south/east/west route reads without inventing structure
- asset-provenance truth stays unchanged unless docs/manifest wording was stale
- candidate assets are explicitly not structural proof
- release-safe art remains future work
- next asset lane requirements are written clearly for later use
- socket readiness is reported against Fixed-Board Visual System Rules 1-7 as a reference lens, not as authority or asset proof

## Hard Guardrails

- no new assets
- no broad asset hookup
- no source-art import
- no license/provenance guesswork
- no runtime/save/flow/source-of-truth change
- no candidate art as green evidence

## Validation

- `py -3 Tools/validate_assets.py`
- `py -3 Tools/validate_architecture_guards.py`
- targeted map tests
- `powershell -NoProfile -ExecutionPolicy Bypass -File Tools/run_godot_scene_isolation.ps1 -ScenePath scenes/map_explore.tscn -QuitAfter 2`
- `powershell -NoProfile -ExecutionPolicy Bypass -File Tools/run_portrait_review_capture.ps1 -ScenePaths scenes/map_explore.tscn -ViewportSizes 1080x1920 -TimeoutSeconds 120`
- `git diff --check`

## Done Criteria

- asset sockets are ready or exact blockers are explicit
- candidate art remains closed and cannot be used as structural proof
- future asset lane can start without inventing structure

## Copy/Paste Parts

### Part A - Socket Readiness Audit

Apply only Prompt 14 Part A.

Scope:
- audit path, landmark, decor, and canopy socket metadata

Do not:
- add or edit art files

Validation:
- `py -3 Tools/validate_assets.py`
- architecture guard
- targeted map tests

Report:
- findings first
- exact socket classes ready
- exact socket classes blocked
- exact provenance risks, if any
- Fixed-Board Visual System Rules 1-7 socket-readiness gaps

### Part B - Socket Metadata Patch

Apply only Prompt 14 Part B.

Scope:
- add only derived socket metadata or doc corrections justified by Part A

Do not:
- add candidate assets or source art
- change runtime/save/flow ownership

Validation:
- full Prompt 14 validation stack

Report:
- files changed
- exact socket metadata landed
- exact asset work still deferred
- provenance truth preserved
- Fixed-Board Visual System Rules 1-7 gaps changed or still open

### Part C - Readiness Recheck

Apply only Prompt 14 Part C.

Scope:
- recheck sockets and future asset lane clarity

Do not:
- declare final art readiness or release safety

Validation:
- full Prompt 14 validation stack

Report:
- findings first
- whether Prompt 15 can start
- exact future asset lane prerequisites
- remaining Fixed-Board Visual System Rules 1-7 socket-readiness gaps
